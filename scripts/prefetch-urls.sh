#!/usr/bin/env bash
set -euo pipefail

PREFETCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PREFETCH_DIR/lib/raindrop-api.sh"
load_settings

BLOCKED_DOMAINS_FILE="config/blocked-domains.json"
NEW_BLOCKED=""

log_info "URL 사전 fetch 시작 (Firecrawl → Jina Reader → 차단 등록)"

for batch_file in tmp/batch_*.json; do
  [ -f "$batch_file" ] || continue

  log_info "$(basename "$batch_file") 사전 fetch 중..."

  updated=$(jq -c '.' "$batch_file")
  bookmark_count=$(echo "$updated" | jq '.bookmarks | length')

  for i in $(seq 0 $((bookmark_count - 1))); do
    url=$(echo "$updated" | jq -r ".bookmarks[$i].url")
    title=$(echo "$updated" | jq -r ".bookmarks[$i].title")
    short_title="${title:0:40}"

    # 1차: Firecrawl API (JS 렌더링 + 안티봇 우회)
    if [ -n "${FIRECRAWL_API_KEY:-}" ]; then
      fc_result=$(curl -s --max-time 20 "https://api.firecrawl.dev/v1/scrape" \
        -H "Authorization: Bearer ${FIRECRAWL_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"url\":\"${url}\",\"formats\":[\"markdown\"],\"onlyMainContent\":true}" 2>/dev/null || echo "{}")
      fc_content=$(echo "$fc_result" | jq -r '.data.markdown // empty' 2>/dev/null)

      if [ -n "$fc_content" ] && [ ${#fc_content} -gt 100 ]; then
        log_info "  [Firecrawl] 성공: ${short_title}"
        updated=$(echo "$updated" | jq --argjson i "$i" --arg c "$fc_content" '.bookmarks[$i].prefetched_content = $c')
        continue
      fi
    fi

    # 2차: Jina Reader (무료, threads.com 등 지원)
    content=$(curl -s --max-time 15 "https://r.jina.ai/${url}" -H "Accept: text/markdown" 2>/dev/null || echo "")
    if [ ${#content} -gt 200 ] && ! echo "$content" | head -5 | grep -qi "error\|not found\|403\|401\|blocked"; then
      log_info "  [Jina] 성공: ${short_title}"
      updated=$(echo "$updated" | jq --argjson i "$i" --arg c "$content" '.bookmarks[$i].prefetched_content = $c')
      continue
    fi

    # 모두 실패 → 차단 도메인 후보
    domain=$(echo "$url" | sed -E 's|https?://||;s|/.*||')
    log_warn "  [실패] ${short_title} (${domain})"
    NEW_BLOCKED="${NEW_BLOCKED}${domain}\n"
  done

  echo "$updated" > "$batch_file"
done

# 차단 도메인 업데이트 (실패한 도메인만 추가)
if [ -n "$NEW_BLOCKED" ]; then
  existing=$(jq -r '.domains[]' "$BLOCKED_DOMAINS_FILE" 2>/dev/null || echo "")
  merged=$(printf '%s\n%b' "$existing" "$NEW_BLOCKED" | sort -u | grep -v '^$')
  echo "$merged" | jq -R . | jq -s --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{domains: ., updated_at: $ts}' > "$BLOCKED_DOMAINS_FILE"
  log_info "차단 도메인 업데이트: $(printf '%b' "$NEW_BLOCKED" | sort -u | tr '\n' ', ')"
fi

log_info "URL 사전 fetch 완료"

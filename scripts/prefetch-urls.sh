#!/usr/bin/env bash
set -euo pipefail

PREFETCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PREFETCH_DIR/lib/raindrop-api.sh"
load_settings

log_info "URL 사전 fetch 시작 (Firecrawl → Jina Reader)"
new_blocked=""

for batch_file in tmp/batch_*.json; do
  [ -f "$batch_file" ] || continue
  log_info "$(basename "$batch_file") 사전 fetch 중..."

  mapfile -t urls < <(jq -r '.bookmarks[].url' "$batch_file")
  mapfile -t titles < <(jq -r '.bookmarks[].title' "$batch_file")
  content_dir=$(mktemp -d)

  for i in "${!urls[@]}"; do
    url="${urls[$i]}"
    short="${titles[$i]:0:40}"
    cf="${content_dir}/${i}.md"

    # 1차: Firecrawl
    if [ -n "${FIRECRAWL_API_KEY:-}" ]; then
      fc=$(curl -s --max-time 20 "https://api.firecrawl.dev/v1/scrape" \
        -H "Authorization: Bearer ${FIRECRAWL_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg u "$url" '{"url":$u,"formats":["markdown"],"onlyMainContent":true}')" \
        2>/dev/null | jq -r '.data.markdown // empty' 2>/dev/null)
      if [ -n "$fc" ] && [ ${#fc} -gt 100 ]; then
        log_info "  [Firecrawl] ${short}"; echo "$fc" > "$cf"; continue
      fi
    fi

    # 2차: Jina Reader
    jn=$(curl -s --max-time 15 "https://r.jina.ai/${url}" -H "Accept: text/markdown" 2>/dev/null || echo "")
    if [ ${#jn} -gt 200 ] && ! echo "$jn" | head -5 | grep -qi "error\|not found\|403\|401\|blocked"; then
      log_info "  [Jina] ${short}"; echo "$jn" > "$cf"; continue
    fi

    log_warn "  [실패] ${short} ($(extract_domain "$url"))"
    new_blocked="${new_blocked}$(extract_domain "$url")"$'\n'
  done

  # 콘텐츠를 배치 JSON에 병합
  tmp_batch=$(mktemp)
  cp "$batch_file" "$tmp_batch"
  for i in "${!urls[@]}"; do
    [ -f "${content_dir}/${i}.md" ] && [ -s "${content_dir}/${i}.md" ] || continue
    jq --argjson i "$i" --arg c "$(cat "${content_dir}/${i}.md")" \
      '.bookmarks[$i].prefetched_content = $c' "$tmp_batch" > "${tmp_batch}.new"
    mv "${tmp_batch}.new" "$tmp_batch"
  done
  mv "$tmp_batch" "$batch_file"
  rm -rf "$content_dir"
done

update_blocked_domains "$new_blocked"
[ -n "$new_blocked" ] && log_info "차단 도메인 업데이트: $(echo "$new_blocked" | sort -u | tr '\n' ', ')"
log_info "URL 사전 fetch 완료"

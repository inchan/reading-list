#!/usr/bin/env bash
set -euo pipefail

PREFETCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PREFETCH_DIR/lib/raindrop-api.sh"
load_settings

log_info "URL 사전 fetch 시작"

for batch_file in tmp/batch_*.json; do
  [ -f "$batch_file" ] || continue

  log_info "$(basename "$batch_file") 사전 fetch 중..."

  # 각 북마크 URL을 사전 fetch
  updated=$(jq -c '.' "$batch_file")
  bookmark_count=$(echo "$updated" | jq '.bookmarks | length')

  for i in $(seq 0 $((bookmark_count - 1))); do
    url=$(echo "$updated" | jq -r ".bookmarks[$i].url")
    title=$(echo "$updated" | jq -r ".bookmarks[$i].title")

    # 1차: Jina Reader
    content=$(curl -s --max-time 15 "https://r.jina.ai/${url}" -H "Accept: text/markdown" 2>/dev/null || echo "")
    # Jina 성공 판정: 200자 이상 콘텐츠
    if [ ${#content} -gt 200 ] && ! echo "$content" | head -5 | grep -qi "error\|not found\|403\|401\|blocked"; then
      log_info "  Jina 성공: ${title:0:40}"
      updated=$(echo "$updated" | jq --argjson i "$i" --arg c "$content" '.bookmarks[$i].prefetched_content = $c')
      continue
    fi

    # 2차: Firecrawl API
    if [ -n "${FIRECRAWL_API_KEY:-}" ]; then
      fc_result=$(curl -s --max-time 20 "https://api.firecrawl.dev/v1/scrape" \
        -H "Authorization: Bearer ${FIRECRAWL_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"url\":\"${url}\",\"formats\":[\"markdown\"],\"onlyMainContent\":true}" 2>/dev/null || echo "{}")
      fc_content=$(echo "$fc_result" | jq -r '.data.markdown // empty' 2>/dev/null)

      if [ -n "$fc_content" ] && [ ${#fc_content} -gt 100 ]; then
        log_info "  Firecrawl 성공: ${title:0:40}"
        updated=$(echo "$updated" | jq --argjson i "$i" --arg c "$fc_content" '.bookmarks[$i].prefetched_content = $c')
        continue
      fi
    fi

    log_info "  사전 fetch 실패: ${title:0:40}"
  done

  # 업데이트된 배치 파일 저장
  echo "$updated" > "$batch_file"
done

log_info "URL 사전 fetch 완료"

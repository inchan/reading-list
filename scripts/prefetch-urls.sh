#!/usr/bin/env bash
set -euo pipefail

PREFETCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PREFETCH_DIR/lib/raindrop-api.sh"
load_settings

log_info "URL 사전 fetch 시작 (Firecrawl → Jina Reader → 차단 등록)"

new_blocked=""

for batch_file in tmp/batch_*.json; do
  [ -f "$batch_file" ] || continue
  log_info "$(basename "$batch_file") 사전 fetch 중..."

  # 사전에 url/title 배열 추출 (반복마다 전체 JSON 파싱 방지)
  mapfile -t urls < <(jq -r '.bookmarks[].url' "$batch_file")
  mapfile -t titles < <(jq -r '.bookmarks[].title' "$batch_file")
  bookmark_count=${#urls[@]}

  # 개별 콘텐츠를 임시 파일에 저장
  content_dir=$(mktemp -d)

  for i in $(seq 0 $((bookmark_count - 1))); do
    url="${urls[$i]}"
    short_title="${titles[$i]:0:40}"
    content_file="${content_dir}/${i}.md"

    # 1차: Firecrawl API (jq로 안전한 JSON 구성)
    if [ -n "${FIRECRAWL_API_KEY:-}" ]; then
      fc_payload=$(jq -n --arg url "$url" '{"url":$url,"formats":["markdown"],"onlyMainContent":true}')
      fc_result=$(curl -s --max-time 20 "https://api.firecrawl.dev/v1/scrape" \
        -H "Authorization: Bearer ${FIRECRAWL_API_KEY}" \
        -H "Content-Type: application/json" \
        -d "$fc_payload" 2>/dev/null || echo "{}")
      fc_content=$(echo "$fc_result" | jq -r '.data.markdown // empty' 2>/dev/null)

      if [ -n "$fc_content" ] && [ ${#fc_content} -gt 100 ]; then
        log_info "  [Firecrawl] 성공: ${short_title}"
        echo "$fc_content" > "$content_file"
        continue
      fi
    fi

    # 2차: Jina Reader
    content=$(curl -s --max-time 15 "https://r.jina.ai/${url}" -H "Accept: text/markdown" 2>/dev/null || echo "")
    if [ ${#content} -gt 200 ] && ! echo "$content" | head -5 | grep -qi "error\|not found\|403\|401\|blocked"; then
      log_info "  [Jina] 성공: ${short_title}"
      echo "$content" > "$content_file"
      continue
    fi

    # 모두 실패
    domain=$(extract_domain "$url")
    log_warn "  [실패] ${short_title} (${domain})"
    new_blocked="${new_blocked}${domain}"$'\n'
  done

  # 한 번의 jq로 모든 prefetched_content 병합
  jq --argjson count "$bookmark_count" '
    reduce range($count) as $i (.;
      if (env.CONTENT_DIR + "/" + ($i | tostring) + ".md") as $f |
         ($f | ltrimstr(env.CONTENT_DIR + "/")) then
        .
      else . end
    )
  ' "$batch_file" > /dev/null 2>&1 || true

  # 개별 콘텐츠 파일을 배치 JSON에 병합
  tmp_batch=$(mktemp)
  cp "$batch_file" "$tmp_batch"
  for i in $(seq 0 $((bookmark_count - 1))); do
    content_file="${content_dir}/${i}.md"
    if [ -f "$content_file" ] && [ -s "$content_file" ]; then
      content=$(cat "$content_file")
      jq --argjson i "$i" --arg c "$content" '.bookmarks[$i].prefetched_content = $c' "$tmp_batch" > "${tmp_batch}.new"
      mv "${tmp_batch}.new" "$tmp_batch"
    fi
  done
  mv "$tmp_batch" "$batch_file"

  rm -rf "$content_dir"
done

# 차단 도메인 업데이트
update_blocked_domains "$new_blocked"
if [ -n "$new_blocked" ]; then
  log_info "차단 도메인 업데이트: $(echo "$new_blocked" | sort -u | tr '\n' ', ')"
fi

log_info "URL 사전 fetch 완료"

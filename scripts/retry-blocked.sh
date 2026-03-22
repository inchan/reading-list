#!/usr/bin/env bash
set -euo pipefail

RETRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RETRY_DIR/lib/raindrop-api.sh"
load_settings

log_info "#접근불가 북마크 재시도 확인 시작"

permanent_domains=$(load_blocked_domains)

# Unsorted에서 #접근불가 태그 검색
encoded_tag=$(urlencode "#${TAG_BLOCKED}")
result=$(raindrop_get "/raindrops/-1?search=${encoded_tag}&perpage=50") || { log_error "검색 실패"; exit 1; }
items=$(echo "$result" | jq '.items // []')
count=$(echo "$items" | jq 'length')

if [ "$count" -eq 0 ]; then
  log_info "재시도할 #접근불가 북마크 없음"
  exit 0
fi

log_info "#접근불가 북마크 ${count}건 발견"

retry_count=0
skip_count=0

# process substitution으로 서브셸 방지
while IFS= read -r item; do
  bid=$(echo "$item" | jq -r '._id')
  url=$(echo "$item" | jq -r '.link')
  domain=$(extract_domain "$url")

  if [ -n "$permanent_domains" ] && echo "$url" | grep -qE "$permanent_domains"; then
    log_info "영구 차단 유지: ID=${bid} (${domain})"
    skip_count=$((skip_count + 1))
    continue
  fi

  current_tags=$(echo "$item" | jq -c --arg tag "$TAG_BLOCKED" '[.tags[] | select(. != $tag)]')
  raindrop_put "/raindrop/${bid}" "{\"tags\":${current_tags}}" \
    && log_info "재시도 대상: ID=${bid} → #접근불가 제거" \
    || log_error "태그 제거 실패: ID=${bid}"
  retry_count=$((retry_count + 1))
done < <(echo "$items" | jq -c '.[]')

log_info "#접근불가 재시도 완료: 재시도 ${retry_count}건, 영구 차단 유지 ${skip_count}건"

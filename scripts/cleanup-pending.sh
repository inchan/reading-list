#!/usr/bin/env bash
set -euo pipefail

CP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CP_DIR/lib/raindrop-api.sh"
load_settings

log_info "#대기중 태그 정리 시작"

result=$(raindrop_get "/raindrops/0?search=$(urlencode "#${TAG_PENDING}")&perpage=50") || { log_error "검색 실패"; exit 1; }
items=$(echo "$result" | jq '.items // []')
[ "$(echo "$items" | jq 'length')" -eq 0 ] && { log_info "정리할 #대기중 없음"; exit 0; }

# 컬렉션 이동 완료된 항목만 태그 제거
while IFS= read -r item; do
  bid=$(echo "$item" | jq -r '._id')
  tags=$(echo "$item" | jq -c --arg t "$TAG_PENDING" '[.tags[] | select(. != $t)]')
  raindrop_put "/raindrop/${bid}" "{\"tags\":${tags}}" \
    && log_info "태그 제거: ID=${bid}" || log_error "실패: ID=${bid}"
done < <(echo "$items" | jq -c '.[] | select(.collection._id != -1)')

unsorted=$(echo "$items" | jq '[.[] | select(.collection._id == -1)] | length')
[ "$unsorted" -gt 0 ] && log_info "Unsorted에 #대기중 ${unsorted}건 유지"
log_info "#대기중 태그 정리 완료"

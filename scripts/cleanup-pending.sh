#!/usr/bin/env bash
set -euo pipefail

CLEANUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CLEANUP_DIR/lib/raindrop-api.sh"
load_settings

log_info "#대기중 태그 정리 시작"

# 전체 북마크에서 #대기중 태그 검색 (collection 0 = 전체)
encoded_tag=$(urlencode "#${TAG_PENDING}")
result=$(raindrop_get "/raindrops/0?search=${encoded_tag}&perpage=50") || { log_error "검색 실패"; exit 1; }
items=$(echo "$result" | jq '.items // []')
count=$(echo "$items" | jq 'length')

if [ "$count" -eq 0 ]; then
  log_info "정리할 #대기중 북마크 없음"
  exit 0
fi

# Unsorted(-1)가 아닌 컬렉션에 있는 북마크 = 이미 분류됨 → 태그 제거
echo "$items" | jq -c '.[] | select(.collection._id != -1)' | while IFS= read -r item; do
  bid=$(echo "$item" | jq -r '._id')
  current_tags=$(echo "$item" | jq -c --arg tag "$TAG_PENDING" '[.tags[] | select(. != $tag)]')

  raindrop_put "/raindrop/${bid}" "{\"tags\":${current_tags}}" \
    && log_info "태그 제거: ID=${bid} → #대기중 삭제" \
    || log_error "태그 제거 실패: ID=${bid}"
done

# 아직 Unsorted에 남아있는 #대기중은 그대로 유지 (아직 미분류)
unsorted_count=$(echo "$items" | jq '[.[] | select(.collection._id == -1)] | length')
if [ "$unsorted_count" -gt 0 ]; then
  log_info "Unsorted에 #대기중 ${unsorted_count}건 유지 (미분류)"
fi

log_info "#대기중 태그 정리 완료"

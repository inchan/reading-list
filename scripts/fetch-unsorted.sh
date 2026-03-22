#!/usr/bin/env bash
set -euo pipefail

FETCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$FETCH_DIR/lib/raindrop-api.sh"
load_settings

log_info "Unsorted 북마크 조회 시작"
mkdir -p tmp

collections_raw=$(raindrop_get "/collections") || { log_error "컬렉션 조회 실패"; exit 1; }
collections=$(echo "$collections_raw" | jq '[.items[] | {id: ._id, title: .title, parent_id: .parent_id}]')
echo "$collections" > config/collections.json

bookmarks=$(raindrop_get_all_pages "/raindrops/-1")
log_info "Unsorted 북마크 $(echo "$bookmarks" | jq 'length')개 조회됨"

# 태그 필터 + 형식 변환을 한 번에
bookmarks=$(echo "$bookmarks" | jq --arg tp "$TAG_PENDING" --arg tb "$TAG_BLOCKED" \
  '[.[] | select((.tags | index($tp) | not) and (.tags | index($tb) | not)) |
   {id: ._id, title, url: .link, excerpt: (.excerpt // ""), created, tags, type}]')
bookmark_count=$(echo "$bookmarks" | jq 'length')
log_info "필터 후 ${bookmark_count}개"

jq -n --arg date "$(date +%Y-%m-%d)" --argjson c "$collections" --argjson b "$bookmarks" \
  '{run_date: $date, collections: $c, bookmarks: $b}' > tmp/input.json
log_info "tmp/input.json 저장 완료"

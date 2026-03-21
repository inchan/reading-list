#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

log_info "Unsorted 북마크 조회 시작"

# 컬렉션 목록 조회
collections_raw=$(raindrop_get "/collections") || { log_error "컬렉션 조회 실패"; exit 1; }
collections=$(echo "$collections_raw" | jq '[.items[] | {id: ._id, title: .title, parent_id: .parent_id}]')

# Unsorted 북마크 조회 (collection_id = -1, 페이지네이션)
bookmarks=$(raindrop_get_all_pages "/raindrops/-1")
bookmark_count=$(echo "$bookmarks" | jq 'length')
log_info "Unsorted 북마크 ${bookmark_count}개 조회됨"

if [ "$bookmark_count" -eq 0 ]; then
  log_info "처리할 북마크 없음"
  echo '{"run_date":"'"$(date +%Y-%m-%d)"'","collections":[],"bookmarks":[]}' > tmp/input.json
  exit 0
fi

# #대기중 태그가 붙은 항목 제외 (이전 실행에서 컬렉션 미매칭으로 대기 중인 항목)
bookmarks=$(echo "$bookmarks" | jq '[.[] | select(.tags | index("대기중") | not)]')
bookmark_count=$(echo "$bookmarks" | jq 'length')
log_info "대기중 태그 제외 후 ${bookmark_count}개"

# input.json 형식으로 변환
input=$(jq -n \
  --arg date "$(date +%Y-%m-%d)" \
  --argjson collections "$collections" \
  --argjson bookmarks "$(echo "$bookmarks" | jq '[.[] | {
    id: ._id,
    title: .title,
    url: .link,
    excerpt: (.excerpt // ""),
    created: .created,
    tags: .tags,
    type: .type
  }]')" \
  '{run_date: $date, collections: $collections, bookmarks: $bookmarks}')

mkdir -p tmp
echo "$input" > tmp/input.json
log_info "tmp/input.json 저장 완료 (${bookmark_count}개 북마크)"

# 컬렉션 캐시 갱신
echo "$collections" > config/collections.json
log_info "config/collections.json 갱신"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

log_info "검증실패 컬렉션 정리 시작 (${QUARANTINE_DAYS}일 경과 항목)"

# 검증실패 컬렉션 ID 찾기
collections=$(raindrop_get "/collections") || { log_error "컬렉션 조회 실패"; exit 1; }
quarantine_id=$(echo "$collections" | jq -r --arg name "$QUARANTINE_COLLECTION_NAME" \
  '.items[] | select(.title == $name) | ._id // empty')

if [ -z "$quarantine_id" ]; then
  log_warn "\"$QUARANTINE_COLLECTION_NAME\" 컬렉션 없음. setup.sh 먼저 실행 필요."
  exit 0
fi

# 검증실패 컬렉션의 모든 북마크 조회
bookmarks=$(raindrop_get_all_pages "/raindrops/${quarantine_id}")
total=$(echo "$bookmarks" | jq 'length')
log_info "검증실패 컬렉션: ${total}개 항목"

# 10일 경과 항목 필터
cutoff_date=$(date -u -v-${QUARANTINE_DAYS}d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
  || date -u -d "${QUARANTINE_DAYS} days ago" '+%Y-%m-%dT%H:%M:%SZ')

expired_ids=$(echo "$bookmarks" | jq -r --arg cutoff "$cutoff_date" \
  '[.[] | select(.created < $cutoff) | ._id] | .[]')

expired_count=$(echo "$expired_ids" | grep -c . || true)

if [ "$expired_count" -eq 0 ]; then
  log_info "정리할 항목 없음"
  exit 0
fi

log_info "${expired_count}개 항목 휴지통으로 이동"

# 개별 삭제 (Raindrop API: DELETE = 휴지통 이동)
for id in $expired_ids; do
  raindrop_delete "/raindrop/${id}" || log_warn "삭제 실패: ID=${id}"
done

log_info "정리 완료"

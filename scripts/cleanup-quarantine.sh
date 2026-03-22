#!/usr/bin/env bash
set -euo pipefail

CQ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CQ_DIR/lib/raindrop-api.sh"
load_settings

log_info "검증실패 컬렉션 정리 시작 (${QUARANTINE_DAYS}일 경과 항목)"

quarantine_id=$(get_quarantine_id) || { log_error "컬렉션 조회 실패"; exit 1; }
[ -z "$quarantine_id" ] && { log_warn "\"$QUARANTINE_COLLECTION_NAME\" 컬렉션 없음"; exit 0; }

bookmarks=$(raindrop_get_all_pages "/raindrops/${quarantine_id}")
log_info "검증실패 컬렉션: $(echo "$bookmarks" | jq 'length')개 항목"

cutoff=$(date -u -v-${QUARANTINE_DAYS}d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
  || date -u -d "${QUARANTINE_DAYS} days ago" '+%Y-%m-%dT%H:%M:%SZ')

expired_ids=$(echo "$bookmarks" | jq -r --arg c "$cutoff" '[.[] | select(.created < $c) | ._id] | .[]')
expired_count=$(echo "$expired_ids" | grep -c . || true)
[ "$expired_count" -eq 0 ] && { log_info "정리할 항목 없음"; exit 0; }

log_info "${expired_count}개 항목 휴지통으로 이동"
for id in $expired_ids; do
  raindrop_delete "/raindrop/${id}" || log_warn "삭제 실패: ID=${id}"
done
log_info "정리 완료"

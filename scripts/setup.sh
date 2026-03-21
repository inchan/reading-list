#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

log_info "초기 셋업 시작"

# 검증실패 컬렉션 존재 여부 확인
collections=$(raindrop_get "/collections") || { log_error "컬렉션 목록 조회 실패"; exit 1; }

quarantine_id=$(echo "$collections" | jq -r --arg name "$QUARANTINE_COLLECTION_NAME" \
  '.items[] | select(.title == $name) | ._id // empty')

if [ -z "$quarantine_id" ]; then
  log_info "\"$QUARANTINE_COLLECTION_NAME\" 컬렉션 생성 중..."
  result=$(raindrop_post "/collection" \
    "{\"title\": \"$QUARANTINE_COLLECTION_NAME\"}") || { log_error "컬렉션 생성 실패"; exit 1; }
  quarantine_id=$(echo "$result" | jq -r '.item._id')
  log_info "컬렉션 생성 완료: ID=$quarantine_id"
else
  log_info "\"$QUARANTINE_COLLECTION_NAME\" 컬렉션 이미 존재: ID=$quarantine_id"
fi

log_info "초기 셋업 완료"

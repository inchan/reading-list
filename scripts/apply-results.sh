#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

RESULT_FILE="${1:?사용법: apply-results.sh <result_file>}"

if [ ! -f "$RESULT_FILE" ]; then
  log_error "결과 파일 없음: $RESULT_FILE"
  exit 1
fi

run_date=$(jq -r '.run_date' "$RESULT_FILE")

# 검증실패 컬렉션 ID 조회
quarantine_id=$(get_quarantine_id) || { log_error "컬렉션 조회 실패"; exit 1; }

# 보고서 생성 먼저
bash "$SCRIPT_DIR/generate-reports.sh" "$RESULT_FILE"

# 각 결과 처리
jq -c '.results[]' "$RESULT_FILE" | while IFS= read -r item; do
  bookmark_id=$(echo "$item" | jq -r '.bookmark_id')
  status=$(echo "$item" | jq -r '.verification.status')
  url=$(echo "$item" | jq -r '.url')

  if [ "$status" = "$STATUS_PASSED" ]; then
    collection_id=$(echo "$item" | jq -r '.category.collection_id // empty')
    tags=$(echo "$item" | jq -c '.tags')

    if [ -n "$collection_id" ]; then
      # 컬렉션 이동 + 태그 + 노트 (GitHub Pages URL)
      slug=$(slugify_url "$url")
      note_url="${PAGES_BASE_URL}/reports/${run_date}/${slug}"

      update_data=$(jq -n \
        --argjson collection_id "$collection_id" \
        --argjson tags "$tags" \
        --arg note "$note_url" \
        '{collection: {"$id": $collection_id}, tags: $tags, note: $note}')

      raindrop_put "/raindrop/${bookmark_id}" "$update_data" \
        && log_info "PASSED: ID=${bookmark_id} → 컬렉션 ${collection_id}" \
        || log_error "이동 실패: ID=${bookmark_id}"
    else
      # 컬렉션 미매칭 → Unsorted 유지 + #대기중 태그
      update_data=$(jq -n --argjson tags "[\"$TAG_PENDING\"]" '{tags: $tags}')
      raindrop_put "/raindrop/${bookmark_id}" "$update_data" \
        && log_info "PENDING: ID=${bookmark_id} → 대기중 태그" \
        || log_error "태그 실패: ID=${bookmark_id}"
    fi

  elif [ "$status" = "$STATUS_FAILED" ]; then
    if [ -n "$quarantine_id" ]; then
      update_data=$(jq -n \
        --argjson collection_id "$quarantine_id" \
        --argjson tags "[\"$TAG_QUARANTINE\"]" \
        '{collection: {"$id": $collection_id}, tags: $tags}')

      raindrop_put "/raindrop/${bookmark_id}" "$update_data" \
        && log_info "FAILED: ID=${bookmark_id} → 검증실패 컬렉션" \
        || log_error "이동 실패: ID=${bookmark_id}"
    else
      log_warn "검증실패 컬렉션 없음. ID=${bookmark_id} 스킵."
    fi
  fi
done

# 새 컬렉션 필요 시 GitHub Issue 생성
new_collections=$(jq -c '.new_collections_needed[]?' "$RESULT_FILE")
if [ -n "$new_collections" ]; then
  echo "$new_collections" | while IFS= read -r nc; do
    name=$(echo "$nc" | jq -r '.suggested_name')
    reason=$(echo "$nc" | jq -r '.reason')
    ids=$(echo "$nc" | jq -r '.bookmark_ids | map(tostring) | join(", #")')

    gh issue create \
      --title "[컬렉션 제안] ${name}" \
      --label "$ISSUE_LABELS" \
      --body "$(cat <<ISSUE_BODY
## 제안 컬렉션: ${name}
**사유**: ${reason}
**관련 북마크 ID**: #${ids}
**처리일**: ${run_date}
ISSUE_BODY
)" \
      && log_info "Issue 생성: [컬렉션 제안] ${name}" \
      || log_error "Issue 생성 실패: ${name}"
  done
fi

log_info "결과 적용 완료"

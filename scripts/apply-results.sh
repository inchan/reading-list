#!/usr/bin/env bash
set -euo pipefail

APPLY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$APPLY_DIR/lib/raindrop-api.sh"
source "$APPLY_DIR/lib/note-render.sh"
load_settings

RESULT_FILE="${1:?사용법: apply-results.sh <result_file>}"

if [ ! -f "$RESULT_FILE" ]; then
  log_error "결과 파일 없음: $RESULT_FILE"
  exit 1
fi

run_date=$(jq -r '.run_date' "$RESULT_FILE")

suggested_collection_for() {
  local bookmark_id="$1"
  jq -r --argjson id "$bookmark_id" '
    [.new_collections_needed[]? | select(.bookmark_ids | index($id)) | .suggested_name][0] // "미정"
  ' "$RESULT_FILE"
}

# 검증실패 컬렉션 ID 조회
quarantine_id=$(get_quarantine_id) || { log_error "컬렉션 조회 실패"; exit 1; }

# --- 결과를 카테고리별로 분류 ---
passed_with_collection=$(jq -c '[.results[] | select(.verification.status == "passed" and .category.collection_id != null)]' "$RESULT_FILE")
passed_pending=$(jq -c '[.results[] | select(.verification.status == "passed" and .category.collection_id == null)]' "$RESULT_FILE")
skipped_items=$(jq -c '[.results[] | select(.verification.status == "skipped")]' "$RESULT_FILE")
fetch_failed=$(jq -c '[.results[] | select(.verification.status == "failed" and (.fetch_status == "blocked" or .fetch_status == "error" or .fetch_status == "empty"))]' "$RESULT_FILE")
verify_failed=$(jq -c '[.results[] | select(.verification.status == "failed" and .fetch_status != "blocked" and .fetch_status != "error" and .fetch_status != "empty")]' "$RESULT_FILE")

# --- 1. passed + 컬렉션 매칭: 컬렉션별로 일괄 이동 ---
# 개별 처리 (컬렉션/태그/노트가 북마크마다 다르므로 일괄 불가)
echo "$passed_with_collection" | jq -c '.[]' 2>/dev/null | while IFS= read -r item; do
  bookmark_id=$(echo "$item" | jq -r '.bookmark_id')
  collection_id=$(echo "$item" | jq -r '.category.collection_id')
  collection_title=$(echo "$item" | jq -r '.category.collection_title // "미분류"')
  tags=$(echo "$item" | jq -c '.tags')
  summary=$(echo "$item" | jq -r '.summary // ""')
  insights=$(echo "$item" | jq -r '.insights // ""')
  note_text=$(render_classified_note "$summary" "$insights" "$collection_title" "$tags")

  update_data=$(jq -n \
    --argjson collection_id "$collection_id" \
    --argjson tags "$tags" \
    --arg note "$note_text" \
    '{collection: {"$id": $collection_id}, tags: $tags, note: $note}')

  raindrop_put "/raindrop/${bookmark_id}" "$update_data" \
    && log_info "PASSED: ID=${bookmark_id} → 컬렉션 ${collection_id} + note 갱신" \
    || log_error "이동 실패: ID=${bookmark_id}"
done

# --- 2. passed + 컬렉션 미매칭: #대기중 태그 + 노트 설정 ---
pending_count=$(echo "$passed_pending" | jq 'length')
if [ "$pending_count" -gt 0 ]; then
  echo "$passed_pending" | jq -c '.[]' 2>/dev/null | while IFS= read -r item; do
    bookmark_id=$(echo "$item" | jq -r '.bookmark_id')
    tags=$(echo "$item" | jq -c '.tags // []')
    pending_tags=$(echo "$item" | jq -c --arg pending "$TAG_PENDING" '((.tags // []) + [$pending]) | unique')
    summary=$(echo "$item" | jq -r '.summary // ""')
    insights=$(echo "$item" | jq -r '.insights // ""')
    suggested_collection=$(suggested_collection_for "$bookmark_id")
    note_text=$(render_pending_note "$summary" "$insights" "$tags" "$suggested_collection")

    update_data=$(jq -n \
      --argjson tags "$pending_tags" \
      --arg note "$note_text" \
      '{tags: $tags, note: $note}')

    raindrop_put "/raindrop/${bookmark_id}" "$update_data" \
      && log_info "PENDING: ID=${bookmark_id} → #대기중 + note 갱신" \
      || log_error "업데이트 실패: ID=${bookmark_id}"
  done
fi

# --- 3. skipped + fetch_failed: 일괄 #접근불가 태그 ---
blocked_ids=$(jq -n --argjson s "$skipped_items" --argjson f "$fetch_failed" \
  '[$s[].bookmark_id, $f[].bookmark_id]')
blocked_count=$(echo "$blocked_ids" | jq 'length')
if [ "$blocked_count" -gt 0 ]; then
  update_data=$(jq -n --argjson ids "$blocked_ids" --arg tag "$TAG_BLOCKED" \
    '{ids: $ids, tags: [$tag]}')
  raindrop_put "/raindrops/-1" "$update_data" \
    && log_info "BLOCKED: ${blocked_count}건 일괄 #접근불가 태그" \
    || log_error "일괄 태그 실패: blocked"
fi

# --- 4. 검증 실패: 일괄 검증실패 컬렉션 이동 ---
verify_failed_ids=$(echo "$verify_failed" | jq '[.[].bookmark_id]')
verify_failed_count=$(echo "$verify_failed_ids" | jq 'length')
if [ "$verify_failed_count" -gt 0 ] && [ -n "$quarantine_id" ]; then
  update_data=$(jq -n --argjson ids "$verify_failed_ids" \
    --argjson collection_id "$quarantine_id" \
    --arg tag "$TAG_QUARANTINE" \
    '{ids: $ids, collection: {"$id": $collection_id}, tags: [$tag]}')
  raindrop_put "/raindrops/-1" "$update_data" \
    && log_info "FAILED: ${verify_failed_count}건 일괄 검증실패 컬렉션 이동" \
    || log_error "일괄 이동 실패: quarantine"
fi

# 새 컬렉션 필요 시 GitHub Issue 생성
new_collections=$(jq -c '.new_collections_needed[]?' "$RESULT_FILE")
if [ -n "$new_collections" ]; then
  echo "$new_collections" | while IFS= read -r nc; do
    name=$(echo "$nc" | jq -r '.suggested_name')
    reason=$(echo "$nc" | jq -r '.reason')
    ids_json=$(echo "$nc" | jq -c '.bookmark_ids')

    # 한 번의 jq로 관련 북마크 상세 추출
    bookmark_details=$(jq -r --argjson ids "$ids_json" '
      [.results[] | select(.bookmark_id as $b | $ids | index($b)) |
        "### [\(.url)](\(.url))\n" +
        (if .summary then "**요약**: \(.summary)\n" else "" end) +
        (if .insights then "**인사이트**: \(.insights)\n" else "" end) +
        "**태그**: \(.tags | join(", "))\n"] | join("\n")
    ' "$RESULT_FILE" 2>/dev/null)

    gh issue create \
      --title "[컬렉션 제안] ${name}" \
      --label "$ISSUE_LABELS" \
      --body "$(printf '## 제안 컬렉션: %s\n**사유**: %s\n**처리일**: %s\n\n---\n\n## 관련 북마크\n\n%b' \
        "$name" "$reason" "$run_date" "$bookmark_details")" \
      && log_info "Issue 생성: [컬렉션 제안] ${name}" \
      || log_error "Issue 생성 실패: ${name}"
  done
fi

# 차단 도메인 업데이트
new_domains=$(jq -r '.newly_blocked_domains[]?' "$RESULT_FILE" 2>/dev/null)
if [ -n "$new_domains" ]; then
  update_blocked_domains "$new_domains"
  log_info "차단 도메인 업데이트: $(echo "$new_domains" | tr '\n' ', ')"
fi

log_info "결과 적용 완료"

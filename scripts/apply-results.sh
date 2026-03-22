#!/usr/bin/env bash
set -euo pipefail

APPLY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$APPLY_DIR/lib/raindrop-api.sh"
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
bash "$APPLY_DIR/generate-reports.sh" "$RESULT_FILE"

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
  tags=$(echo "$item" | jq -c '.tags')
  url=$(echo "$item" | jq -r '.url')
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
done

# --- 2. passed + 컬렉션 미매칭: 일괄 #대기중 태그 ---
pending_ids=$(echo "$passed_pending" | jq '[.[].bookmark_id]')
pending_count=$(echo "$pending_ids" | jq 'length')
if [ "$pending_count" -gt 0 ]; then
  update_data=$(jq -n --argjson ids "$pending_ids" --arg tag "$TAG_PENDING" \
    '{ids: $ids, tags: [$tag]}')
  raindrop_put "/raindrops/-1" "$update_data" \
    && log_info "PENDING: ${pending_count}건 일괄 #대기중 태그" \
    || log_error "일괄 태그 실패: pending"
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

# 차단 도메인 업데이트
blocked_file="config/blocked-domains.json"
new_domains=$(jq -r '.newly_blocked_domains[]?' "$RESULT_FILE" 2>/dev/null)
if [ -n "$new_domains" ]; then
  existing=$(jq -r '.domains[]' "$blocked_file" 2>/dev/null || echo "")
  merged=$(printf '%s\n%s' "$existing" "$new_domains" | sort -u | grep -v '^$')
  updated=$(echo "$merged" | jq -R . | jq -s --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '{domains: ., updated_at: $ts}')
  echo "$updated" > "$blocked_file"
  log_info "차단 도메인 업데이트: $(echo "$new_domains" | tr '\n' ', ')"
fi

log_info "결과 적용 완료"

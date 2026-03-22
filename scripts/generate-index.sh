#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

RUN_DATE="${1:-$(date +%Y-%m-%d)}"
REPORT_DIR="reports/${RUN_DATE}"

if [ ! -d "$REPORT_DIR" ]; then
  log_info "보고서 디렉토리 없음: $REPORT_DIR"
  exit 0
fi

# 임시 파일 초기화 (이전 실행 잔재 제거)
rm -f "${REPORT_DIR}/.passed.tmp" "${REPORT_DIR}/.failed.tmp"

# 모든 result 파일에서 통계 수집
# NOTE: while 루프가 파이프 서브셸에서 실행되므로 변수 상태가 유실됨.
#       temp 파일에 누적하여 해결한다.
for result_file in tmp/result_batch_*.json; do
  [ -f "$result_file" ] || continue

  # passed 항목
  jq -c --arg status "$STATUS_PASSED" '.results[] | select(.verification.status == $status)' "$result_file" | while IFS= read -r item; do
    url=$(echo "$item" | jq -r '.url')
    collection=$(echo "$item" | jq -r '.category.collection_title // "미분류"')
    tags=$(echo "$item" | jq -r '.tags | join(", ")')
    slug=$(slugify_url "$url")
    title=$(title_from_url "$url")

    echo "| ${title} | ${collection} | ${tags} | [보기](./${slug}.md) |" >> "${REPORT_DIR}/.passed.tmp"
  done

  # failed 항목
  jq -c --arg status "$STATUS_FAILED" '.results[] | select(.verification.status == $status)' "$result_file" | while IFS= read -r item; do
    url=$(echo "$item" | jq -r '.url')
    reason=$(echo "$item" | jq -r '.verification.reason')
    title=$(title_from_url "$url")

    echo "| ${title} | ${reason} |" >> "${REPORT_DIR}/.failed.tmp"
  done
done

# macOS wc -l은 앞에 공백을 붙이므로 tr로 제거
passed_count=$(wc -l < "${REPORT_DIR}/.passed.tmp" 2>/dev/null | tr -d ' ' || echo 0)
failed_count=$(wc -l < "${REPORT_DIR}/.failed.tmp" 2>/dev/null | tr -d ' ' || echo 0)
total=$((passed_count + failed_count))

cat > "${REPORT_DIR}/index.md" << INDEX
---
date: "${RUN_DATE}"
total: ${total}
passed: ${passed_count}
failed: ${failed_count}
---

# ${RUN_DATE} Reading List Report

## 처리 완료 (${passed_count}건)
| 제목 | 컬렉션 | 태그 | 보고서 |
|------|--------|------|--------|
$(cat "${REPORT_DIR}/.passed.tmp" 2>/dev/null || echo "| (없음) | - | - | - |")

## 검증 실패 (${failed_count}건)
| 제목 | 사유 |
|------|------|
$(cat "${REPORT_DIR}/.failed.tmp" 2>/dev/null || echo "| (없음) | - |")
INDEX

# 임시 파일 정리
rm -f "${REPORT_DIR}/.passed.tmp" "${REPORT_DIR}/.failed.tmp"

log_info "일별 인덱스 생성 완료: ${REPORT_DIR}/index.md (총 ${total}건)"

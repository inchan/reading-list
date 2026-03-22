#!/usr/bin/env bash
set -euo pipefail

INDEX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$INDEX_DIR/lib/raindrop-api.sh"
load_settings

RUN_DATE="${1:-$(date +%Y-%m-%d)}"
REPORT_DIR="reports/${RUN_DATE}"
[ -d "$REPORT_DIR" ] || { log_info "보고서 디렉토리 없음: $REPORT_DIR"; exit 0; }

passed_rows=""
failed_rows=""

for result_file in tmp/result_batch_*.json tmp/result_blocked.json; do
  [ -f "$result_file" ] || continue

  # 한 번의 jq로 passed/failed 행 모두 생성
  while IFS=$'\t' read -r status url reason collection tags; do
    title=$(title_from_url "$url")
    if [ "$status" = "$STATUS_PASSED" ]; then
      slug=$(slugify_url "$url")
      passed_rows="${passed_rows}| ${title} | ${collection} | ${tags} | [보기](./${slug}.md) |"$'\n'
    elif [ "$status" = "$STATUS_FAILED" ]; then
      failed_rows="${failed_rows}| ${title} | ${reason} |"$'\n'
    fi
  done < <(jq -r '.results[] | [
    .verification.status,
    .url,
    (.verification.reason // ""),
    (if .category then (.category.collection_title // "미분류") else "미분류" end),
    (.tags | join(", "))
  ] | @tsv' "$result_file" 2>/dev/null)
done

passed_count=$(echo -n "$passed_rows" | grep -c '^|' || echo 0)
failed_count=$(echo -n "$failed_rows" | grep -c '^|' || echo 0)
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
${passed_rows:-| (없음) | - | - | - |}

## 검증 실패 (${failed_count}건)
| 제목 | 사유 |
|------|------|
${failed_rows:-| (없음) | - |}
INDEX

log_info "일별 인덱스 생성 완료: ${REPORT_DIR}/index.md (총 ${total}건)"

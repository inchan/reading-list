#!/usr/bin/env bash
set -euo pipefail

INDEX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$INDEX_DIR/lib/raindrop-api.sh"
load_settings

RUN_DATE="${1:-$(date +%Y-%m-%d)}"
REPORT_DIR="reports/${RUN_DATE}"

# --- 1. 날짜별 인덱스 생성 ---
if [ -d "$REPORT_DIR" ]; then
  rm -f "${REPORT_DIR}/.passed.tmp" "${REPORT_DIR}/.failed.tmp"

  # result 파일 기반
  for result_file in tmp/result_batch_*.json; do
    [ -f "$result_file" ] || continue
    jq -c --arg s "$STATUS_PASSED" '.results[] | select(.verification.status == $s)' "$result_file" | while IFS= read -r item; do
      url=$(echo "$item" | jq -r '.url')
      slug=$(slugify_url "$url")
      collection=$(echo "$item" | jq -r '.category.collection_title // "미분류"')
      tags=$(echo "$item" | jq -r '.tags | join(", ")')
      echo "| $(title_from_url "$url") | ${collection} | ${tags} | [보기](./${slug}.md) |" >> "${REPORT_DIR}/.passed.tmp"
    done
    jq -c --arg s "$STATUS_FAILED" '.results[] | select(.verification.status == $s)' "$result_file" | while IFS= read -r item; do
      url=$(echo "$item" | jq -r '.url')
      reason=$(echo "$item" | jq -r '.verification.reason')
      echo "| $(title_from_url "$url") | ${reason} |" >> "${REPORT_DIR}/.failed.tmp"
    done
  done

  # result 파일이 없으면 기존 보고서 파일에서 인덱스 복구
  if [ ! -f "${REPORT_DIR}/.passed.tmp" ] && [ ! -f "${REPORT_DIR}/.failed.tmp" ]; then
    for md_file in "${REPORT_DIR}"/*.md; do
      [ -f "$md_file" ] || continue
      [ "$(basename "$md_file")" = "index.md" ] && continue
      title=$(sed -n 's/^title: "\(.*\)"/\1/p' "$md_file" | head -1)
      url=$(sed -n 's/^url: "\(.*\)"/\1/p' "$md_file" | head -1)
      collection=$(sed -n 's/^collection: "\(.*\)"/\1/p' "$md_file" | head -1)
      tags=$(sed -n 's/^tags: \[\(.*\)\]/\1/p' "$md_file" | head -1 | sed 's/"//g')
      slug=$(basename "$md_file" .md)
      echo "| ${title:-$slug} | ${collection:-미분류} | ${tags:-} | [보기](./${slug}.md) |" >> "${REPORT_DIR}/.passed.tmp"
    done
  fi

  passed_count=$(wc -l < "${REPORT_DIR}/.passed.tmp" 2>/dev/null | tr -d ' ' || echo 0)
  failed_count=$(wc -l < "${REPORT_DIR}/.failed.tmp" 2>/dev/null | tr -d ' ' || echo 0)
  total=$((passed_count + failed_count))

  cat > "${REPORT_DIR}/index.md" << INDEX
---
title: "${RUN_DATE} 보고서"
date: "${RUN_DATE}"
total: ${total}
passed: ${passed_count}
failed: ${failed_count}
---

# ${RUN_DATE} Reading List Report

[← 전체 목록](../../)

## 처리 완료 (${passed_count}건)
| 제목 | 컬렉션 | 태그 | 보고서 |
|------|--------|------|--------|
$(cat "${REPORT_DIR}/.passed.tmp" 2>/dev/null || echo "| (없음) | - | - | - |")

## 검증 실패 (${failed_count}건)
| 제목 | 사유 |
|------|------|
$(cat "${REPORT_DIR}/.failed.tmp" 2>/dev/null || echo "| (없음) | - |")
INDEX

  rm -f "${REPORT_DIR}/.passed.tmp" "${REPORT_DIR}/.failed.tmp"
  log_info "날짜별 인덱스: ${REPORT_DIR}/index.md (${total}건)"
fi

# --- 2. 루트 인덱스 생성 (모든 날짜 목록) ---
root_rows=""
for date_dir in reports/*/; do
  [ -d "$date_dir" ] || continue
  date_name=$(basename "$date_dir")
  date_index="${date_dir}index.md"

  if [ -f "$date_index" ]; then
    total=$(sed -n 's/^total: \(.*\)/\1/p' "$date_index" | head -1)
    passed=$(sed -n 's/^passed: \(.*\)/\1/p' "$date_index" | head -1)
    failed=$(sed -n 's/^failed: \(.*\)/\1/p' "$date_index" | head -1)
  else
    report_count=$(find "$date_dir" -name '*.md' ! -name 'index.md' | wc -l | tr -d ' ')
    total="$report_count"; passed="$report_count"; failed="0"
  fi

  root_rows="| [${date_name}](./reports/${date_name}/) | ${total:-0} | ${passed:-0} | ${failed:-0} |
${root_rows}"
done

cat > index.md << ROOT
---
title: Reading List
---

# Reading List

Raindrop 북마크 자동 분석 보고서

## 날짜별 보고서
| 날짜 | 전체 | 통과 | 실패 |
|------|------|------|------|
${root_rows:-| (아직 보고서 없음) | - | - | - |}
ROOT

log_info "루트 인덱스: index.md 갱신"

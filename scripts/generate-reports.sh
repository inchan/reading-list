#!/usr/bin/env bash
set -euo pipefail

REPORTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$REPORTS_DIR/lib/raindrop-api.sh"
load_settings

RESULT_FILE="${1:?사용법: generate-reports.sh <result_file>}"
[ -f "$RESULT_FILE" ] || { log_error "결과 파일 없음: $RESULT_FILE"; exit 1; }

run_date=$(jq -r '.run_date' "$RESULT_FILE")
report_dir="reports/${run_date}"

count=$(jq --arg s "$STATUS_PASSED" '[.results[] | select(.verification.status == $s)] | length' "$RESULT_FILE")
[ "$count" -eq 0 ] && { log_info "보고서 생성할 passed 항목 없음"; exit 0; }

mkdir -p "$report_dir"
log_info "${count}개 보고서 생성 시작"

jq -c --arg s "$STATUS_PASSED" '.results[] | select(.verification.status == $s)' "$RESULT_FILE" | while IFS= read -r item; do
  url=$(echo "$item" | jq -r '.url')
  bookmark_id=$(echo "$item" | jq -r '.bookmark_id')
  title=$(echo "$item" | jq -r '.title // empty')
  [ -z "$title" ] && title=$(title_from_url "$url")

  slug=$(slugify_url "$url")
  slug_file="${report_dir}/${slug}.md"

  collection=$(echo "$item" | jq -r 'if .category then (.category.collection_title // "미분류") else "미분류" end')
  tags=$(echo "$item" | jq -r '.tags | map("\"" + . + "\"") | join(", ")')
  summary=$(echo "$item" | jq -r '.summary // ""')
  insights=$(echo "$item" | jq -r '.insights // ""')

  claims_text=""
  while IFS= read -r claim; do
    [ -z "$claim" ] && continue
    ct=$(echo "$claim" | jq -r '.claim')
    v=$(echo "$claim" | jq -r 'if .verified then "verified" else "not verified" end')
    src=$(echo "$claim" | jq -r '.sources | join(", ")')
    claims_text="${claims_text}- \"${ct}\" -> ${v}${src:+ (출처: ${src})}"$'\n'
  done < <(echo "$item" | jq -c '.verification.claims[]?' 2>/dev/null)

  related=$(echo "$item" | jq -r '.related_links[]?' | sed 's/^/- /')

  cat > "$slug_file" << REPORT
---
title: "${title}"
url: "${url}"
source_url: "${url}"
date: "${run_date}"
collection: "${collection}"
tags: [${tags}]
verification: "passed"
raindrop_id: ${bookmark_id}
---

## 요약
${summary}

## 인사이트
${insights}

## 실체 검증 결과
${claims_text}
## 관련 링크
${related}
REPORT

  log_info "보고서 생성: $(basename "$slug_file")"
done

log_info "보고서 생성 완료"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

RESULT_FILE="${1:?사용법: generate-reports.sh <result_file>}"

if [ ! -f "$RESULT_FILE" ]; then
  log_error "결과 파일 없음: $RESULT_FILE"
  exit 1
fi

run_date=$(jq -r '.run_date' "$RESULT_FILE")
report_dir="reports/${run_date}"

# passed 항목만 보고서 생성
passed_items=$(jq '[.results[] | select(.verification.status == "passed")]' "$RESULT_FILE")
count=$(echo "$passed_items" | jq 'length')

if [ "$count" -eq 0 ]; then
  log_info "보고서 생성할 passed 항목 없음"
  exit 0
fi

mkdir -p "$report_dir"

log_info "${count}개 보고서 생성 시작"

for i in $(seq 0 $((count - 1))); do
  item=$(echo "$passed_items" | jq -c ".[$i]")

  bookmark_id=$(echo "$item" | jq -r '.bookmark_id')
  url=$(echo "$item" | jq -r '.url')
  title=$(echo "$item" | jq -r '.title // empty')

  # title이 없으면 URL에서 추출
  if [ -z "$title" ]; then
    title=$(echo "$url" | sed -E 's|https?://||;s|/| |g;s|[?#].*||')
  fi

  # slug는 URL에서 생성 (프로토콜 제거, /를 -로, 쿼리 제거)
  slug_source=$(echo "$url" | sed -E 's|https?://||;s|/|-|g;s|[?#].*||')
  slug=$(slugify "$slug_source")

  # 중복 slug 처리
  slug_file="${report_dir}/${slug}.md"
  counter=2
  while [ -f "$slug_file" ]; do
    slug_file="${report_dir}/${slug}-${counter}.md"
    counter=$((counter + 1))
  done

  collection=$(echo "$item" | jq -r 'if .category then (.category.collection_title // "미분류") else "미분류" end')
  tags=$(echo "$item" | jq -r '.tags | map("\"" + . + "\"") | join(", ")')
  summary=$(echo "$item" | jq -r '.summary // ""')
  insights=$(echo "$item" | jq -r '.insights // ""')
  raindrop_id=$(echo "$item" | jq -r '.bookmark_id')

  # 검증 결과 포매팅
  claims_text=""
  claims_count=$(echo "$item" | jq '.verification.claims | length')
  if [ "$claims_count" -gt 0 ]; then
    for j in $(seq 0 $((claims_count - 1))); do
      claim=$(echo "$item" | jq -c ".verification.claims[$j]")
      claim_text=$(echo "$claim" | jq -r '.claim')
      verified=$(echo "$claim" | jq -r '.verified')
      sources=$(echo "$claim" | jq -r '.sources | join(", ")')
      if [ "$verified" = "true" ]; then
        claims_text="${claims_text}- \"${claim_text}\" -> verified (출처: ${sources})"$'\n'
      else
        claims_text="${claims_text}- \"${claim_text}\" -> not verified"$'\n'
      fi
    done
  fi

  # 관련 링크
  related=$(echo "$item" | jq -r '.related_links[]?' | sed 's/^/- /')

  cat > "$slug_file" << REPORT
---
title: "${title}"
url: "${url}"
date: "${run_date}"
collection: "${collection}"
tags: [${tags}]
verification: "passed"
raindrop_id: ${raindrop_id}
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

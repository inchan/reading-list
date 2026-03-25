#!/usr/bin/env bash

text_or_placeholder() {
  local text="${1:-}"
  if [ -n "$(printf '%s' "$text" | tr -d '[:space:]')" ]; then
    printf '%s' "$text"
  else
    printf '(없음)'
  fi
}

join_tags() {
  local tags_json="${1:-[]}"
  local joined
  joined=$(printf '%s' "$tags_json" | jq -r 'map(select(length > 0)) | join(", ")')
  if [ -n "$joined" ]; then
    printf '%s' "$joined"
  else
    printf '(없음)'
  fi
}

render_classified_note() {
  local summary="$1"
  local insights="$2"
  local collection_title="$3"
  local tags_json="$4"
  local tags_text
  tags_text=$(join_tags "$tags_json")

  jq -nr \
    --arg summary "$(text_or_placeholder "$summary")" \
    --arg insights "$(text_or_placeholder "$insights")" \
    --arg collection "$collection_title" \
    --arg tags "$tags_text" '
      "핵심 요약\n" +
      $summary + "\n\n" +
      "인사이트\n" +
      $insights + "\n\n" +
      "분류\n" +
      "카테고리: " + $collection + "\n" +
      "태그: " + $tags + "\n" +
      "검증: 통과"
    '
}

render_pending_note() {
  local summary="$1"
  local insights="$2"
  local tags_json="$3"
  local suggested_collection="$4"
  local tags_text
  tags_text=$(join_tags "$tags_json")

  jq -nr \
    --arg summary "$(text_or_placeholder "$summary")" \
    --arg insights "$(text_or_placeholder "$insights")" \
    --arg suggested_collection "$suggested_collection" \
    --arg tags "$tags_text" '
      "핵심 요약\n" +
      $summary + "\n\n" +
      "인사이트\n" +
      $insights + "\n\n" +
      "분류 제안\n" +
      "추천 카테고리: " + $suggested_collection + "\n" +
      "후보 태그: " + $tags + "\n" +
      "상태: #대기중\n" +
      "검증: 통과"
    '
}

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

compact_lines() {
  local text="$1"
  local max_lines="${2:-4}"

  jq -nr \
    --arg text "$(text_or_placeholder "$text")" \
    --argjson max_lines "$max_lines" '
      [
        $text
        | gsub("\r"; "")
        | gsub("\\. "; ".\n")
        | split("\n")[]
        | gsub("^\\s+|\\s+$"; "")
        | select(length > 0)
      ][:$max_lines] | join("\n")
    '
}

compact_note() {
  local summary="$1"
  local memo_prefix="$2"
  local memo_text="$3"
  local tail="$4"
  local compact_summary compact_memo

  compact_summary=$(compact_lines "$summary" 4)
  compact_memo=$(compact_lines "$memo_text" 1)

  jq -nr \
    --arg summary "$compact_summary" \
    --arg memo_prefix "$memo_prefix" \
    --arg memo_text "$compact_memo" \
    --arg tail "$tail" '
      $summary + "\n\n" +
      (if $memo_text == "(없음)" then "" else $memo_prefix + ": " + $memo_text + "\n" end) +
      $tail
    '
}

render_classified_note() {
  local summary="$1"
  local insights="$2"
  local collection_title="$3"
  local tags_json="$4"
  local tags_text
  tags_text=$(join_tags "$tags_json")
  local tail
  tail=$(jq -nr --arg collection "$collection_title" --arg tags "$tags_text" '
    "분류: " + $collection + "\n" +
    "태그: " + $tags
  ')

  compact_note "$summary" "메모" "$insights" "$tail"
}

render_pending_note() {
  local summary="$1"
  local insights="$2"
  local tags_json="$3"
  local suggested_collection="$4"
  local tags_text
  tags_text=$(join_tags "$tags_json")
  local tail
  tail=$(jq -nr --arg suggested_collection "$suggested_collection" --arg tags "$tags_text" '
    "제안: " + $suggested_collection + "\n" +
    "태그: " + $tags + "\n" +
    "상태: #대기중"
  ')

  compact_note "$summary" "메모" "$insights" "$tail"
}

render_recovered_note() {
  local title="$1"
  local excerpt="$2"
  local tags_json="$3"
  local tags_text
  tags_text=$(join_tags "$tags_json")
  local tail
  tail=$(jq -nr --arg title "$(text_or_placeholder "$title")" --arg tags "$tags_text" '
    "원문: " + $title + "\n" +
    "태그: " + $tags + "\n" +
    "상태: 복구노트"
  ')

  compact_note \
    "$excerpt" \
    "메모" \
    "기존 report 본문이 남아 있지 않아 저장 시점 제목, excerpt, 태그를 기준으로 복구한 note입니다. 필요하면 원문 링크를 다시 확인해 주세요." \
    "$tail"
}

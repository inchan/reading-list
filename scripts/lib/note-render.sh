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
  local insight_text="$2"
  local compact_summary compact_insight

  compact_summary=$(compact_lines "$summary" 4)
  compact_insight=$(compact_lines "$insight_text" 1)

  jq -nr \
    --arg summary "$compact_summary" \
    --arg insight "$compact_insight" '
      $summary + "\n\n" +
      "인사이트\n" +
      $insight
    '
}

render_classified_note() {
  local summary="$1"
  local insights="$2"
  compact_note "$summary" "$insights"
}

render_pending_note() {
  local summary="$1"
  local insights="$2"
  compact_note "$summary" "$insights"
}

render_recovered_note() {
  local title="$1"
  local excerpt="$2"
  compact_note \
    "$excerpt" \
    "기존 report 본문이 남아 있지 않아 저장 시점 제목과 excerpt를 기준으로 복구한 note입니다."
}

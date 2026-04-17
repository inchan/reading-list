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

render_classified_note() {
  local summary="$1"
  local insights="$2"
  local collection_title="${3:-미분류}"
  local tags_json="${4:-[]}"
  local joined_tags compact_summary compact_insights

  joined_tags=$(join_tags "$tags_json")
  compact_summary=$(compact_lines "$summary" 4)
  compact_insights=$(compact_lines "$insights" 3)

  jq -nr \
    --arg summary "$compact_summary" \
    --arg insights "$compact_insights" \
    --arg collection "$collection_title" \
    --arg tags "$joined_tags" '
      "핵심 요약\n- " + ($summary | gsub("\n"; "\n- ")) +
      "\n\n인사이트\n- " + ($insights | gsub("\n"; "\n- ")) +
      "\n\n분류\n- 카테고리: " + $collection +
      "\n- 태그: " + $tags +
      "\n검증: 통과"
    '
}

render_pending_note() {
  local summary="$1"
  local insights="$2"
  local tags_json="${3:-[]}"
  local suggested_collection="${4:-미정}"
  local joined_tags compact_summary compact_insights

  joined_tags=$(join_tags "$tags_json")
  compact_summary=$(compact_lines "$summary" 4)
  compact_insights=$(compact_lines "$insights" 3)

  jq -nr \
    --arg summary "$compact_summary" \
    --arg insights "$compact_insights" \
    --arg collection "$suggested_collection" \
    --arg tags "$joined_tags" '
      "핵심 요약\n- " + ($summary | gsub("\n"; "\n- ")) +
      "\n\n인사이트\n- " + ($insights | gsub("\n"; "\n- ")) +
      "\n\n분류 제안\n- 추천 카테고리: " + $collection +
      "\n- 후보 태그: " + $tags +
      "\n- 상태: #대기중\n검증: 통과"
    '
}

render_recovered_note() {
  local title="$1"
  local excerpt="$2"
  local tags_json="${3:-[]}"
  local joined_tags compact_excerpt

  joined_tags=$(join_tags "$tags_json")
  compact_excerpt=$(compact_lines "$excerpt" 4)

  jq -nr \
    --arg title "$title" \
    --arg excerpt "$compact_excerpt" \
    --arg tags "$joined_tags" '
      "핵심 요약\n- " + $title +
      "\n- " + ($excerpt | gsub("\n"; "\n- ")) +
      "\n\n인사이트\n- 기존 report 본문이 남아 있지 않아 저장 시점 제목과 excerpt를 기준으로 복구한 note입니다." +
      (if $tags == "" then "" else "\n\n분류\n- 태그: " + $tags end)
    '
}

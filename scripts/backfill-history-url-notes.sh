#!/usr/bin/env bash
set -euo pipefail

BACKFILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BACKFILL_DIR/lib/raindrop-api.sh"
source "$BACKFILL_DIR/lib/note-render.sh"
load_settings

DRY_RUN=false
BASE_URL="https://inchan.github.io/reading-list/"

usage() {
  cat <<'EOF'
사용법: backfill-history-url-notes.sh [--dry-run]

- --dry-run   실제 Raindrop 업데이트 없이 변환 결과만 출력
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

frontmatter_value() {
  local file="$1"
  local key="$2"
  awk -v key="$key" '
    BEGIN { in_frontmatter = 0 }
    /^---$/ {
      if (in_frontmatter == 0) { in_frontmatter = 1; next }
      if (in_frontmatter == 1) { exit }
    }
    in_frontmatter == 1 && index($0, key ":") == 1 {
      sub("^" key ": ", "", $0)
      print
      exit
    }
  ' "$file"
}

extract_section() {
  local file="$1"
  local heading="$2"
  awk -v heading="$heading" '
    $0 == "## " heading { capture = 1; next }
    /^## / && capture == 1 { exit }
    capture == 1 { print }
  ' "$file" | sed '/^[[:space:]]*$/d'
}

render_note_from_report_file() {
  local file="$1"
  local collection="$2"
  local tags_json="$3"
  local summary="$4"
  local insights="$5"

  if [ -z "$collection" ] || [ "$collection" = "미분류" ]; then
    render_pending_note "$summary" "$insights" "$tags_json" "미정"
  else
    render_classified_note "$summary" "$insights" "$collection" "$tags_json"
  fi
}

query=$(urlencode 'inchan.github.io/reading-list')
items_json=$(raindrop_get "/raindrops/0?search=${query}&perpage=100" | jq -c '.items // []')

processed=0
updated=0
skipped=0

while IFS= read -r item; do
  processed=$((processed + 1))
  raindrop_id=$(echo "$item" | jq -r '._id')
  note_url=$(echo "$item" | jq -r '.note // ""')

  report_path="${note_url#${BASE_URL}}"
  report_path="${report_path%%\?*}"
  report_path="${report_path}.md"

  commit_sha=$(git log --all --format=%H -n 1 -- "$report_path" 2>/dev/null || true)
  if [ -z "$commit_sha" ]; then
    item_detail=$(raindrop_get "/raindrop/${raindrop_id}" | jq '.item')
    title=$(echo "$item_detail" | jq -r '.title // ""')
    excerpt=$(echo "$item_detail" | jq -r '.excerpt // ""')
    tags_json=$(echo "$item_detail" | jq -c '.tags // []')
    note_text=$(render_recovered_note "$title" "$excerpt" "$tags_json")

    if [ "$DRY_RUN" = true ]; then
      printf '=== ID=%s %s (metadata fallback)\n%s\n\n' "$raindrop_id" "$report_path" "$note_text"
      updated=$((updated + 1))
      continue
    fi

    update_data=$(jq -n --arg note "$note_text" '{note: $note}')
    if raindrop_put "/raindrop/${raindrop_id}" "$update_data" >/dev/null; then
      updated=$((updated + 1))
      log_warn "metadata fallback note 적용: ID=${raindrop_id} (${report_path})"
    else
      skipped=$((skipped + 1))
      log_error "metadata fallback 실패: ID=${raindrop_id} (${report_path})"
    fi
    continue
  fi

  tmp_report=$(mktemp)
  git show "${commit_sha}:${report_path}" > "$tmp_report"

  collection=$(frontmatter_value "$tmp_report" "collection" | sed 's/^"//;s/"$//')
  tags_json=$(frontmatter_value "$tmp_report" "tags")
  summary=$(extract_section "$tmp_report" "요약")
  insights=$(extract_section "$tmp_report" "인사이트")
  note_text=$(render_note_from_report_file "$tmp_report" "$collection" "$tags_json" "$summary" "$insights")
  rm -f "$tmp_report"

  if [ "$DRY_RUN" = true ]; then
    printf '=== ID=%s %s\n%s\n\n' "$raindrop_id" "$report_path" "$note_text"
    updated=$((updated + 1))
    continue
  fi

  update_data=$(jq -n --arg note "$note_text" '{note: $note}')
  if raindrop_put "/raindrop/${raindrop_id}" "$update_data" >/dev/null; then
    updated=$((updated + 1))
    log_info "history note 백필 완료: ID=${raindrop_id} (${report_path})"
  else
    skipped=$((skipped + 1))
    log_error "history note 백필 실패: ID=${raindrop_id} (${report_path})"
  fi
done < <(echo "$items_json" | jq -c '.[]')

log_info "history 백필 완료: 처리=${processed}, 갱신=${updated}, 스킵=${skipped}, dry_run=${DRY_RUN}"

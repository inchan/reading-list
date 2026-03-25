#!/usr/bin/env bash
set -euo pipefail

BACKFILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BACKFILL_DIR/lib/raindrop-api.sh"
source "$BACKFILL_DIR/lib/note-render.sh"
load_settings

DRY_RUN=false
REPORT_ROOT="reports"

usage() {
  cat <<'EOF'
사용법: backfill-report-notes.sh [--dry-run] [report_root]

- --dry-run   실제 Raindrop 업데이트 없이 note 미리보기만 출력
- report_root 백필할 보고서 루트 디렉터리 (기본값: reports)
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
      REPORT_ROOT="$1"
      ;;
  esac
  shift
done

[ -d "$REPORT_ROOT" ] || { log_error "보고서 디렉터리 없음: $REPORT_ROOT"; exit 1; }

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

render_note_from_report() {
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

processed=0
updated=0
skipped=0

while IFS= read -r report_file; do
  processed=$((processed + 1))

  raindrop_id=$(frontmatter_value "$report_file" "raindrop_id" | tr -d '"')
  collection=$(frontmatter_value "$report_file" "collection" | sed 's/^"//;s/"$//')
  tags_json=$(frontmatter_value "$report_file" "tags")
  summary=$(extract_section "$report_file" "요약")
  insights=$(extract_section "$report_file" "인사이트")

  if [ -z "$raindrop_id" ] || [ -z "$tags_json" ]; then
    skipped=$((skipped + 1))
    log_warn "스킵: 필수 frontmatter 누락 ($report_file)"
    continue
  fi

  note_text=$(render_note_from_report "$report_file" "$collection" "$tags_json" "$summary" "$insights")

  if [ "$DRY_RUN" = true ]; then
    printf '=== %s (ID=%s)\n%s\n\n' "$report_file" "$raindrop_id" "$note_text"
    updated=$((updated + 1))
    continue
  fi

  update_data=$(jq -n --arg note "$note_text" '{note: $note}')
  if raindrop_put "/raindrop/${raindrop_id}" "$update_data" >/dev/null; then
    updated=$((updated + 1))
    log_info "note 백필 완료: ID=${raindrop_id} ($(basename "$report_file"))"
  else
    skipped=$((skipped + 1))
    log_error "note 백필 실패: ID=${raindrop_id} ($(basename "$report_file"))"
  fi
done < <(find "$REPORT_ROOT" -type f -name '*.md' ! -name 'index.md' | sort)

log_info "백필 완료: 처리=${processed}, 갱신=${updated}, 스킵=${skipped}, dry_run=${DRY_RUN}"

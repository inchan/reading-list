#!/usr/bin/env bash
set -euo pipefail

SYNC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SYNC_DIR/lib/raindrop-api.sh"
load_settings

collection_id="-1"
limit=""
queue_file="tmp/wiki-compile-queue.json"
run_date="$(date +%Y-%m-%d)"
synced_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
run_stamp="$(date -u +%Y%m%dT%H%M%SZ)"

usage() {
  cat <<'EOF'
Usage: scripts/sync-raindrop-raw.sh [--collection ID] [--limit N] [--queue FILE]

Sync Raindrop items into immutable raw snapshots under wiki/raw/raindrop/.

Options:
  --collection ID  Raindrop collection id. Use -1 for Unsorted, 0 for all. Default: -1
  --limit N        Limit items after fetch, useful for sample-first runs.
  --queue FILE     Compile queue output path. Default: tmp/wiki-compile-queue.json
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --collection)
      collection_id="${2:?--collection requires an id}"
      shift 2
      ;;
    --limit)
      limit="${2:?--limit requires a number}"
      shift 2
      ;;
    --queue)
      queue_file="${2:?--queue requires a file path}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

sha256_text() {
  shasum -a 256 | awk '{print $1}'
}

safe_timestamp() {
  local value="$1"
  if [ -z "$value" ] || [ "$value" = "null" ]; then
    printf '%s' "$synced_at"
  else
    printf '%s' "$value"
  fi | sed -E 's/[^0-9A-Za-z]+//g' | cut -c1-16
}

write_markdown_snapshot() {
  local item="$1" json_path="$2" md_path="$3" digest="$4"
  local title url created updated tags excerpt note highlights content

  title=$(printf '%s' "$item" | jq -r '.title // "Untitled"')
  url=$(printf '%s' "$item" | jq -r '.link // .url // ""')
  created=$(printf '%s' "$item" | jq -r '.created // ""')
  updated=$(printf '%s' "$item" | jq -r '.lastUpdate // .created // ""')
  tags=$(printf '%s' "$item" | jq -c '.tags // []')
  excerpt=$(printf '%s' "$item" | jq -r '.excerpt // ""')
  note=$(printf '%s' "$item" | jq -r '.note // ""')
  highlights=$(printf '%s' "$item" | jq -r '
    (.highlights // []) |
    if length == 0 then "" else
      map("- " + ((.text // .title // "") | gsub("\n"; " "))) | join("\n")
    end
  ')
  content=$(printf '%s' "$item" | jq -r '.prefetched_content // ""')

  {
    printf -- '---\n'
    printf 'title: %s\n' "$(printf '%s' "$title" | jq -Rr @json)"
    printf 'source_type: raindrop\n'
    printf 'source_id: %s\n' "$(printf '%s' "$item" | jq -r '._id // .id')"
    printf 'source_url: %s\n' "$(printf '%s' "$url" | jq -Rr @json)"
    printf 'created: %s\n' "$(printf '%s' "$created" | jq -Rr @json)"
    printf 'updated: %s\n' "$(printf '%s' "$updated" | jq -Rr @json)"
    printf 'synced_at: %s\n' "$(printf '%s' "$synced_at" | jq -Rr @json)"
    printf 'content_digest: sha256:%s\n' "$digest"
    printf 'raw_json: %s\n' "$(printf '%s' "$json_path" | jq -Rr @json)"
    printf 'tags: %s\n' "$tags"
    printf -- '---\n\n'
    printf '# %s\n\n' "$title"
    printf -- '- Source URL: %s\n' "$url"
    printf -- '- Raindrop ID: %s\n' "$(printf '%s' "$item" | jq -r '._id // .id')"
    printf -- '- Synced at: %s\n' "$synced_at"
    printf -- '- Content digest: sha256:%s\n\n' "$digest"
    printf '## Excerpt\n\n%s\n\n' "${excerpt:-None}"
    printf '## Note\n\n%s\n\n' "${note:-None}"
    printf '## Highlights\n\n%s\n\n' "${highlights:-None}"
    if [ -n "$content" ]; then
      printf '## Captured Content\n\n%s\n' "$content"
    fi
  } > "$md_path"
}

mkdir -p wiki/raw/raindrop/items wiki/raw/raindrop/manifests tmp "$(dirname "$queue_file")"

log_info "Raindrop raw sync start: collection=${collection_id}"
items=$(raindrop_get_all_pages "/raindrops/${collection_id}")

if [ -n "$limit" ]; then
  items=$(printf '%s' "$items" | jq --argjson limit "$limit" '.[:$limit]')
fi

manifest_lines="$(mktemp)"
queue_lines="$(mktemp)"
trap 'rm -f "$manifest_lines" "$queue_lines"' EXIT

printf '%s' "$items" | jq -c '.[]' | while IFS= read -r item; do
  id=$(printf '%s' "$item" | jq -r '._id // .id')
  updated=$(printf '%s' "$item" | jq -r '.lastUpdate // .created // ""')
  normalized=$(printf '%s' "$item" | jq -S '.')
  digest=$(printf '%s' "$normalized" | sha256_text)
  stamp=$(safe_timestamp "$updated")
  item_dir="wiki/raw/raindrop/items/${id}"
  json_path="${item_dir}/${stamp}.${digest}.json"
  md_path="${item_dir}/${stamp}.${digest}.md"
  status="existing"

  mkdir -p "$item_dir"
  if { [ -f "$json_path" ] && [ ! -f "$md_path" ]; } || { [ ! -f "$json_path" ] && [ -f "$md_path" ]; }; then
    log_error "Raw snapshot pair is incomplete for raindrop:${id}: ${json_path} / ${md_path}"
    exit 1
  fi

  if [ ! -f "$json_path" ] && [ ! -f "$md_path" ]; then
    printf '%s\n' "$normalized" > "$json_path"
    write_markdown_snapshot "$item" "$json_path" "$md_path" "$digest"
    status="new"
    jq -n \
      --arg source_id "raindrop:${id}" \
      --arg title "$(printf '%s' "$item" | jq -r '.title // "Untitled"')" \
      --arg url "$(printf '%s' "$item" | jq -r '.link // .url // ""')" \
      --arg raw_markdown "$md_path" \
      --arg raw_json "$json_path" \
      --arg digest "sha256:${digest}" \
      '{source_id:$source_id,title:$title,url:$url,raw_markdown:$raw_markdown,raw_json:$raw_json,content_digest:$digest}' \
      >> "$queue_lines"
  fi

  jq -n \
    --arg source_id "raindrop:${id}" \
    --arg title "$(printf '%s' "$item" | jq -r '.title // "Untitled"')" \
    --arg url "$(printf '%s' "$item" | jq -r '.link // .url // ""')" \
    --arg status "$status" \
    --arg raw_markdown "$md_path" \
    --arg raw_json "$json_path" \
    --arg digest "sha256:${digest}" \
    '{source_id:$source_id,title:$title,url:$url,status:$status,raw_markdown:$raw_markdown,raw_json:$raw_json,content_digest:$digest}' \
    >> "$manifest_lines"
done

manifest_path="wiki/raw/raindrop/manifests/sync-${run_stamp}.json"
jq -s \
  --arg run_date "$run_date" \
  --arg synced_at "$synced_at" \
  --argjson collection_id "$collection_id" \
  '{run_date:$run_date,synced_at:$synced_at,source_type:"raindrop",collection_id:$collection_id,items:.}' \
  "$manifest_lines" > "$manifest_path"

jq -s \
  --arg run_date "$run_date" \
  --arg manifest "$manifest_path" \
  '{run_date:$run_date,manifest:$manifest,items:.}' \
  "$queue_lines" > "$queue_file"

log_info "Raindrop raw sync complete: manifest=${manifest_path}, queue=${queue_file}, new_items=$(jq '.items | length' "$queue_file")"

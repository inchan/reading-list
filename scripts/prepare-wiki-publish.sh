#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

site_url="${READING_LIST_SITE_URL:-}"
feed_output="wiki/feed.xml"
deploy_output="index.xml"
wiki_dir="wiki"
mode="raw"

usage() {
  cat <<'EOF'
Usage: scripts/prepare-wiki-publish.sh --site-url URL [--feed-output FILE] [--deploy-output FILE] [--wiki-dir DIR] [--mode MODE]

Regenerate the local RSS feed for reading-list publication without touching the
wiki index. By default, deployment uses raw-item RSS (one RSS item per raw source).

Options:
  --site-url URL       Absolute base URL used in RSS links.
  --feed-output FILE   RSS output path. Default: wiki/feed.xml
  --deploy-output FILE Deployment RSS path. Default: index.xml
  --wiki-dir DIR       Wiki directory to scan. Default: wiki
  --mode MODE          RSS mode passed to generate-wiki-rss.py. Default: raw
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --site-url)
      site_url="${2:?--site-url requires a URL}"
      shift 2
      ;;
    --feed-output)
      feed_output="${2:?--feed-output requires a file path}"
      shift 2
      ;;
    --deploy-output)
      deploy_output="${2:?--deploy-output requires a file path}"
      shift 2
      ;;
    --wiki-dir)
      wiki_dir="${2:?--wiki-dir requires a directory}"
      shift 2
      ;;
    --mode)
      mode="${2:?--mode requires a mode}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$site_url" ]; then
  echo "--site-url is required, or set READING_LIST_SITE_URL." >&2
  exit 2
fi

python3 "$SCRIPT_DIR/generate-wiki-rss.py" \
  --wiki-dir "$wiki_dir" \
  --site-url "$site_url" \
  --mode "$mode" \
  --output "$feed_output"

if [ "$deploy_output" != "$feed_output" ]; then
  mkdir -p "$(dirname "$deploy_output")"
  cp "$feed_output" "$deploy_output"
fi

echo "Prepared wiki RSS feed: $feed_output"
echo "Prepared deployment RSS feed: $deploy_output"

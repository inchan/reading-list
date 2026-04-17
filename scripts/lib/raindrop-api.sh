#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../../config/settings.json"

load_settings() {
  eval "$(jq -r '
    @sh "API_BASE=\(.raindrop_api_base)",
    @sh "API_DELAY_MS=\(.raindrop_api_delay_ms)"
  ' "$CONFIG_FILE")"

  API_DELAY_S=$(awk "BEGIN {printf \"%.1f\", ${API_DELAY_MS}/1000}")
  : "${RAINDROP_TEST_TOKEN:?RAINDROP_TEST_TOKEN is not set}"
}

raindrop_auth_header() {
  echo "Authorization: Bearer ${RAINDROP_TEST_TOKEN}"
}

_raindrop_request() {
  local method="$1" endpoint="$2" data="${3:-}"
  sleep "$API_DELAY_S"
  local -a args=(-s -f -H "$(raindrop_auth_header)" -H "Content-Type: application/json")
  [ "$method" != "GET" ] && args+=(-X "$method")
  [ -n "$data" ] && args+=(-d "$data")
  curl "${args[@]}" "${API_BASE}${endpoint}"
}

raindrop_get() { _raindrop_request GET "$1"; }

raindrop_get_all_pages() {
  local endpoint="$1"
  local page=0
  local all_items="[]"

  while true; do
    local response
    response=$(raindrop_get "${endpoint}?page=${page}&perpage=50") || break

    local items
    items=$(echo "$response" | jq '.items // []')
    local count
    count=$(echo "$items" | jq 'length')

    if [ "$count" -eq 0 ]; then
      break
    fi

    all_items=$(echo "$all_items" "$items" | jq -s '.[0] + .[1]')
    page=$((page + 1))
  done

  echo "$all_items"
}

log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
log_warn() { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

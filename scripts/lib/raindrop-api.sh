#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../../config/settings.json"

# --- 설정 로드 ---
load_settings() {
  QUARANTINE_DAYS=$(jq -r '.quarantine_days' "$CONFIG_FILE")
  QUARANTINE_COLLECTION_NAME=$(jq -r '.quarantine_collection_name' "$CONFIG_FILE")
  MAX_PER_BATCH=$(jq -r '.max_bookmarks_per_batch' "$CONFIG_FILE")
  PAGES_BASE_URL=$(jq -r '.pages_base_url' "$CONFIG_FILE")
  API_BASE=$(jq -r '.raindrop_api_base' "$CONFIG_FILE")
  API_DELAY_MS=$(jq -r '.raindrop_api_delay_ms' "$CONFIG_FILE")
  SLUG_MAX_LENGTH=$(jq -r '.slug_max_length' "$CONFIG_FILE")
  ISSUE_LABELS=$(jq -r '.issue_labels | join(",")' "$CONFIG_FILE")
}

# --- 인증 ---
raindrop_auth_header() {
  echo "Authorization: Bearer ${RAINDROP_TEST_TOKEN}"
}

raindrop_api_base() {
  if [ -n "${API_BASE:-}" ]; then
    echo "$API_BASE"
  else
    echo "https://api.raindrop.io/rest/v1"
  fi
}

# --- API 호출 (rate limit 대응) ---
raindrop_get() {
  local endpoint="$1"
  local base
  base=$(raindrop_api_base)
  local delay_s
  delay_s=$(echo "${API_DELAY_MS:-500}" | awk '{printf "%.1f", $1/1000}')

  sleep "$delay_s"
  curl -s -f \
    -H "$(raindrop_auth_header)" \
    -H "Content-Type: application/json" \
    "${base}${endpoint}"
}

raindrop_put() {
  local endpoint="$1"
  local data="$2"
  local base
  base=$(raindrop_api_base)
  local delay_s
  delay_s=$(echo "${API_DELAY_MS:-500}" | awk '{printf "%.1f", $1/1000}')

  sleep "$delay_s"
  curl -s -f -X PUT \
    -H "$(raindrop_auth_header)" \
    -H "Content-Type: application/json" \
    -d "$data" \
    "${base}${endpoint}"
}

raindrop_post() {
  local endpoint="$1"
  local data="$2"
  local base
  base=$(raindrop_api_base)
  local delay_s
  delay_s=$(echo "${API_DELAY_MS:-500}" | awk '{printf "%.1f", $1/1000}')

  sleep "$delay_s"
  curl -s -f -X POST \
    -H "$(raindrop_auth_header)" \
    -H "Content-Type: application/json" \
    -d "$data" \
    "${base}${endpoint}"
}

raindrop_delete() {
  local endpoint="$1"
  local base
  base=$(raindrop_api_base)
  local delay_s
  delay_s=$(echo "${API_DELAY_MS:-500}" | awk '{printf "%.1f", $1/1000}')

  sleep "$delay_s"
  curl -s -f -X DELETE \
    -H "$(raindrop_auth_header)" \
    -H "Content-Type: application/json" \
    "${base}${endpoint}"
}

# --- 페이지네이션 조회 ---
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

# --- Slug 생성 ---
slugify() {
  local title="$1"
  local max_len="${SLUG_MAX_LENGTH:-60}"

  echo "$title" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9가-힣ㄱ-ㅎㅏ-ㅣ ]/-/g' \
    | sed 's/  */-/g' \
    | sed 's/--*/-/g' \
    | sed 's/^-//;s/-$//' \
    | cut -c1-"$max_len" \
    | sed 's/-$//'
}

# --- 로그 ---
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
log_warn() { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

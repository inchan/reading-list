#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../../config/settings.json"

# --- 설정 로드 ---
load_settings() {
  eval "$(jq -r '
    @sh "QUARANTINE_DAYS=\(.quarantine_days)",
    @sh "QUARANTINE_COLLECTION_NAME=\(.quarantine_collection_name)",
    @sh "MAX_PER_BATCH=\(.max_bookmarks_per_batch)",
    @sh "API_BASE=\(.raindrop_api_base)",
    @sh "API_DELAY_MS=\(.raindrop_api_delay_ms)",
    @sh "SLUG_MAX_LENGTH=\(.slug_max_length)",
    @sh "ISSUE_LABELS=\(.issue_labels | join(","))",
    @sh "TAG_PENDING=\(.tag_pending)",
    @sh "TAG_QUARANTINE=\(.tag_quarantine)",
    @sh "TAG_BLOCKED=\(.tag_blocked)",
    @sh "STATUS_PASSED=\(.status_passed)",
    @sh "STATUS_FAILED=\(.status_failed)"
  ' "$CONFIG_FILE")"
  API_DELAY_S=$(awk "BEGIN {printf \"%.1f\", ${API_DELAY_MS}/1000}")
  : "${RAINDROP_TEST_TOKEN:?RAINDROP_TEST_TOKEN is not set}"
}

# --- 인증 ---
raindrop_auth_header() {
  echo "Authorization: Bearer ${RAINDROP_TEST_TOKEN}"
}

# --- API 호출 (rate limit 대응) ---
_raindrop_request() {
  local method="$1" endpoint="$2" data="${3:-}"
  sleep "$API_DELAY_S"
  local -a args=(-s -f -H "$(raindrop_auth_header)" -H "Content-Type: application/json")
  [ "$method" != "GET" ] && args+=(-X "$method")
  [ -n "$data" ] && args+=(-d "$data")
  curl "${args[@]}" "${API_BASE}${endpoint}"
}

raindrop_get() { _raindrop_request GET "$1"; }
raindrop_put() { _raindrop_request PUT "$1" "$2"; }
raindrop_post() { _raindrop_request POST "$1" "$2"; }
raindrop_delete() { _raindrop_request DELETE "$1"; }

# --- 검증실패 컬렉션 ID 조회 ---
get_quarantine_id() {
  local collections
  collections=$(raindrop_get "/collections") || { log_error "컬렉션 조회 실패"; return 1; }
  echo "$collections" | jq -r --arg name "$QUARANTINE_COLLECTION_NAME" \
    '.items[] | select(.title == $name) | ._id // empty'
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
    | LC_ALL=C sed 's/[^a-z0-9 -]/-/g' \
    | sed 's/  */-/g' \
    | sed 's/--*/-/g' \
    | sed 's/^-//;s/-$//' \
    | cut -c1-"$max_len" \
    | sed 's/-$//'
}

# --- URL → Slug ---
slugify_url() {
  local url="$1"
  slugify "$(echo "$url" | sed -E 's|https?://||;s|/|-|g;s|[?#].*||')"
}

# --- URL → 제목 ---
title_from_url() {
  local url="$1" max_len="${2:-50}"
  echo "$url" | sed -E 's|https?://||;s|/| |g;s|[?#].*||' | head -c "$max_len"
}

# --- 프로젝트 루트 ---
PROJECT_ROOT="${SCRIPT_DIR}/../.."
BLOCKED_DOMAINS_FILE="${PROJECT_ROOT}/config/blocked-domains.json"

# --- URL → 도메인 추출 ---
extract_domain() {
  echo "$1" | sed -E 's|https?://||;s|/.*||'
}

# --- URL 인코딩 ---
urlencode() {
  echo "$1" | jq -Rr @uri
}

# --- 차단 도메인 로드 (파이프 구분자) ---
load_blocked_domains() {
  jq -r '.domains[]' "$BLOCKED_DOMAINS_FILE" 2>/dev/null | paste -sd'|' -
}

# --- 차단 도메인 업데이트 (새 도메인 추가) ---
update_blocked_domains() {
  local new_domains="$1"
  [ -z "$new_domains" ] && return
  local existing
  existing=$(jq -r '.domains[]' "$BLOCKED_DOMAINS_FILE" 2>/dev/null || echo "")
  local merged
  merged=$(printf '%s\n%s' "$existing" "$new_domains" | sort -u | grep -v '^$')
  echo "$merged" | jq -R . | jq -s --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{domains: ., updated_at: $ts}' > "$BLOCKED_DOMAINS_FILE"
}

# --- 로그 ---
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
log_warn() { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }

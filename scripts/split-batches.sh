#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

INPUT_FILE="tmp/input.json"

if [ ! -f "$INPUT_FILE" ]; then
  log_error "tmp/input.json 없음. fetch-unsorted.sh 먼저 실행 필요."
  exit 1
fi

run_date=$(jq -r '.run_date' "$INPUT_FILE")
collections=$(jq '.collections' "$INPUT_FILE")

# 중복 URL 제거 (첫 번째만 유지)
bookmarks=$(jq '[.bookmarks | group_by(.url) | .[] | .[0]]' "$INPUT_FILE")
original_count=$(jq '.bookmarks | length' "$INPUT_FILE")
deduped_count=$(echo "$bookmarks" | jq 'length')
skipped=$((original_count - deduped_count))

if [ "$skipped" -gt 0 ]; then
  log_warn "중복 URL ${skipped}개 제거됨"
fi

# 차단 도메인 사전 필터 — Claude에 보내지 않고 바로 결과 생성
BLOCKED_DOMAINS_FILE="config/blocked-domains.json"
if [ -f "$BLOCKED_DOMAINS_FILE" ]; then
  blocked_domains=$(jq -r '.domains[]' "$BLOCKED_DOMAINS_FILE" 2>/dev/null | paste -sd'|' -)
  if [ -n "$blocked_domains" ]; then
    blocked_bookmarks=$(echo "$bookmarks" | jq --arg pat "$blocked_domains" \
      '[.[] | select(.url | test($pat))]')
    blocked_count=$(echo "$blocked_bookmarks" | jq 'length')

    if [ "$blocked_count" -gt 0 ]; then
      # 차단 도메인 북마크 → 즉시 skipped 결과 생성 (Claude 호출 불필요)
      echo "$blocked_bookmarks" | jq --arg date "$run_date" '{
        run_date: $date,
        results: [.[] | {
          bookmark_id: .id,
          url: .url,
          final_url: null,
          fetch_status: "skipped_blocked_domain",
          verification: { status: "skipped", reason: "차단 도메인", claims: [] },
          summary: null,
          insights: null,
          category: null,
          tags: [],
          related_links: []
        }],
        new_collections_needed: [],
        newly_blocked_domains: []
      }' > "tmp/result_blocked.json"
      log_info "차단 도메인 ${blocked_count}개 → tmp/result_blocked.json (Claude 스킵)"

      # 차단 도메인 제외한 북마크만 남김
      bookmarks=$(echo "$bookmarks" | jq --arg pat "$blocked_domains" \
        '[.[] | select(.url | test($pat) | not)]')
      deduped_count=$(echo "$bookmarks" | jq 'length')
    fi
  fi
fi

if [ "$deduped_count" -eq 0 ]; then
  log_info "처리할 북마크 없음"
  exit 0
fi

# 배치 분할
batch_num=1
offset=0

while [ "$offset" -lt "$deduped_count" ]; do
  batch_file=$(printf "tmp/batch_%03d.json" "$batch_num")

  echo "$bookmarks" | jq --arg date "$run_date" --argjson cols "$collections" \
    --argjson offset "$offset" --argjson limit "$MAX_PER_BATCH" \
    '{
      run_date: $date,
      collections: $cols,
      bookmarks: .[$offset:$offset+$limit]
    }' > "$batch_file"

  count=$(jq '.bookmarks | length' "$batch_file")
  log_info "배치 ${batch_num}: ${count}개 북마크 → ${batch_file}"

  batch_num=$((batch_num + 1))
  offset=$((offset + MAX_PER_BATCH))
done

log_info "총 $((batch_num - 1))개 배치 생성 완료"

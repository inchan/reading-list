#!/usr/bin/env bash
set -euo pipefail

RETRY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$RETRY_DIR/lib/raindrop-api.sh"
load_settings

log_info "#접근불가 북마크 재시도 확인 시작"

BLOCKED_DOMAINS_FILE="config/blocked-domains.json"

# 영구 차단 도메인 목록 로드
if [ -f "$BLOCKED_DOMAINS_FILE" ]; then
  permanent_domains=$(jq -r '.domains[]' "$BLOCKED_DOMAINS_FILE" 2>/dev/null | paste -sd'|' -)
else
  permanent_domains=""
fi

# Unsorted에서 #접근불가 태그 검색
encoded_tag=$(python3 -c "import urllib.parse; print(urllib.parse.quote('#${TAG_BLOCKED}'))")
result=$(raindrop_get "/raindrops/-1?search=${encoded_tag}&perpage=50") || { log_error "검색 실패"; exit 1; }
items=$(echo "$result" | jq '.items // []')
count=$(echo "$items" | jq 'length')

if [ "$count" -eq 0 ]; then
  log_info "재시도할 #접근불가 북마크 없음"
  exit 0
fi

log_info "#접근불가 북마크 ${count}건 발견"

# 영구 차단 도메인이 아닌 항목만 태그 제거 → 다음 실행에서 재처리
retry_count=0
skip_count=0

echo "$items" | jq -c '.[]' | while IFS= read -r item; do
  bid=$(echo "$item" | jq -r '._id')
  url=$(echo "$item" | jq -r '.link')

  # 영구 차단 도메인 확인
  if [ -n "$permanent_domains" ] && echo "$url" | grep -qE "$permanent_domains"; then
    log_info "영구 차단 유지: ID=${bid} ($(echo "$url" | sed -E 's|https?://||;s|/.*||'))"
    skip_count=$((skip_count + 1))
    continue
  fi

  # #접근불가 태그 제거 → 다음 실행에서 재처리
  current_tags=$(echo "$item" | jq -c --arg tag "$TAG_BLOCKED" '[.tags[] | select(. != $tag)]')
  raindrop_put "/raindrop/${bid}" "{\"tags\":${current_tags}}" \
    && log_info "재시도 대상: ID=${bid} → #접근불가 제거" \
    || log_error "태그 제거 실패: ID=${bid}"
  retry_count=$((retry_count + 1))
done

log_info "#접근불가 재시도 완료: 재시도 대상 ${retry_count}건, 영구 차단 유지 ${skip_count}건"

#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$PROJECT_ROOT"

  export RAINDROP_TEST_TOKEN="test-token-123"
  export TEST_BIN_DIR="$BATS_TEST_TMPDIR/bin"
  export FAKE_HTTP_DIR="$BATS_TEST_TMPDIR/http"
  export REPORT_ROOT="$BATS_TEST_TMPDIR/reports"
  mkdir -p "$TEST_BIN_DIR" "$FAKE_HTTP_DIR" "$REPORT_ROOT/day"

  export PATH="$TEST_BIN_DIR:$PATH"
  export FAKE_HTTP_DIR

  cat > "$TEST_BIN_DIR/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

method="GET"
data=""
url="${@: -1}"

for ((i=1; i<=$#; i++)); do
  arg="${!i}"
  case "$arg" in
    -X)
      j=$((i + 1))
      method="${!j}"
      ;;
    -d)
      j=$((i + 1))
      data="${!j}"
      ;;
  esac
done

if [[ "$method" == "PUT" && "$url" =~ /raindrop/([0-9]+)$ ]]; then
  id="${BASH_REMATCH[1]}"
  printf '%s' "$data" > "${FAKE_HTTP_DIR}/raindrop_${id}.json"
  printf '{"result":true}\n'
  exit 0
fi

printf '{"items":[]}\n'
EOF
  chmod +x "$TEST_BIN_DIR/curl"
}

make_report() {
  local path="$1"
  local collection="$2"
  local tags="$3"
  local raindrop_id="$4"
  local summary="$5"
  local insights="$6"

  cat > "$path" <<EOF
---
title: "Sample"
url: "https://example.com/article"
source_url: "https://example.com/article"
date: "2026-03-25"
collection: "$collection"
tags: $tags
verification: "passed"
raindrop_id: $raindrop_id
---

## 요약
$summary

## 인사이트
$insights

## 실체 검증 결과
- verified

## 관련 링크
- https://example.com/source
EOF
}

@test "backfills classified report note into Raindrop" {
  make_report \
    "$REPORT_ROOT/day/classified.md" \
    "Frontend" \
    '["react", "server-components"]' \
    "12345" \
    "React 19 서버 컴포넌트 요약" \
    "점진적 마이그레이션이 가능하다."

  run bash scripts/backfill-report-notes.sh "$REPORT_ROOT"

  [ "$status" -eq 0 ]
  [ -f "$FAKE_HTTP_DIR/raindrop_12345.json" ]
  [ "$(jq -r '.note' "$FAKE_HTTP_DIR/raindrop_12345.json")" != "" ]

  note=$(jq -r '.note' "$FAKE_HTTP_DIR/raindrop_12345.json")
  [[ "$note" == *"핵심 요약"* ]]
  [[ "$note" == *"React 19 서버 컴포넌트 요약"* ]]
  [[ "$note" == *"인사이트"* ]]
  [[ "$note" == *"카테고리: Frontend"* ]]
  [[ "$note" == *"태그: react, server-components"* ]]
}

@test "dry-run prints pending-style note for unclassified report without API call" {
  make_report \
    "$REPORT_ROOT/day/unclassified.md" \
    "미분류" \
    '["mlops", "머신러닝"]' \
    "98768" \
    "MLOps 가이드 요약" \
    "새 컬렉션 검토가 필요하다."

  run bash scripts/backfill-report-notes.sh --dry-run "$REPORT_ROOT"

  [ "$status" -eq 0 ]
  [ ! -f "$FAKE_HTTP_DIR/raindrop_98768.json" ]
  [[ "$output" == *"MLOps 가이드 요약"* ]]
  [[ "$output" == *"분류 제안"* ]]
  [[ "$output" == *"추천 카테고리: 미정"* ]]
  [[ "$output" == *"후보 태그: mlops, 머신러닝"* ]]
  [[ "$output" == *"상태: #대기중"* ]]
}

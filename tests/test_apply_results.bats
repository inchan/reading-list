#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$PROJECT_ROOT"

  export RAINDROP_TEST_TOKEN="test-token-123"
  export TEST_BIN_DIR="$BATS_TEST_TMPDIR/bin"
  export FAKE_HTTP_DIR="$BATS_TEST_TMPDIR/http"
  export FAKE_GH_LOG="$BATS_TEST_TMPDIR/gh.log"
  mkdir -p "$TEST_BIN_DIR" "$FAKE_HTTP_DIR"

  export PATH="$TEST_BIN_DIR:$PATH"
  export FAKE_HTTP_DIR
  export FAKE_GH_LOG

  rm -rf reports

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

if [[ "$method" == "GET" && "$url" == *"/collections" ]]; then
  cat <<'JSON'
{"items":[{"_id":68803714,"title":"검증실패"}]}
JSON
  exit 0
fi

if [[ "$method" == "PUT" && "$url" =~ /raindrop/([0-9]+)$ ]]; then
  id="${BASH_REMATCH[1]}"
  printf '%s' "$data" > "${FAKE_HTTP_DIR}/raindrop_${id}.json"
  printf '{"result":true}\n'
  exit 0
fi

if [[ "$method" == "PUT" && "$url" == *"/raindrops/-1" ]]; then
  count=$(find "$FAKE_HTTP_DIR" -maxdepth 1 -name 'bulk_*.json' | wc -l | tr -d ' ')
  index=$((count + 1))
  printf '%s' "$data" > "${FAKE_HTTP_DIR}/bulk_${index}.json"
  printf '{"result":true}\n'
  exit 0
fi

printf '{"items":[]}\n'
EOF
  chmod +x "$TEST_BIN_DIR/curl"

  cat > "$TEST_BIN_DIR/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$FAKE_GH_LOG"
printf 'https://example.com/issues/1\n'
EOF
  chmod +x "$TEST_BIN_DIR/gh"
}

teardown() {
  rm -rf reports
}

@test "stores Korean note content for categorized passed item and skips report generation" {
  run bash scripts/apply-results.sh tests/fixtures/result_passed.json

  [ "$status" -eq 0 ]
  [ -f "$FAKE_HTTP_DIR/raindrop_98765.json" ]
  [ ! -d "reports" ]

  [ "$(jq -r '.collection["$id"]' "$FAKE_HTTP_DIR/raindrop_98765.json")" = "12345" ]
  [ "$(jq -r '.tags | join(", ")' "$FAKE_HTTP_DIR/raindrop_98765.json")" = "react, server-components, 성능최적화" ]

  note=$(jq -r '.note' "$FAKE_HTTP_DIR/raindrop_98765.json")
  [[ "$note" == *"핵심 요약"* ]]
  [[ "$note" == *"React 19의 서버 컴포넌트 지원에 대한 실무 가이드."* ]]
  [[ "$note" == *"인사이트"* ]]
  [[ "$note" == *"카테고리: Frontend"* ]]
  [[ "$note" == *"태그: react, server-components, 성능최적화"* ]]
  [[ "$note" == *"검증: 통과"* ]]
}

@test "stores pending note with suggested category and preserves suggested tags" {
  run bash scripts/apply-results.sh tests/fixtures/result_mixed.json

  [ "$status" -eq 0 ]
  [ -f "$FAKE_HTTP_DIR/raindrop_98768.json" ]

  [ "$(jq -r '.tags | index("대기중") != null' "$FAKE_HTTP_DIR/raindrop_98768.json")" = "true" ]
  [ "$(jq -r '.tags | index("mlops") != null' "$FAKE_HTTP_DIR/raindrop_98768.json")" = "true" ]
  [ "$(jq -r '.tags | index("머신러닝") != null' "$FAKE_HTTP_DIR/raindrop_98768.json")" = "true" ]

  note=$(jq -r '.note' "$FAKE_HTTP_DIR/raindrop_98768.json")
  [[ "$note" == *"핵심 요약"* ]]
  [[ "$note" == *"MLOps 가이드 요약"* ]]
  [[ "$note" == *"인사이트"* ]]
  [[ "$note" == *"MLOps 인사이트"* ]]
  [[ "$note" == *"분류 제안"* ]]
  [[ "$note" == *"추천 카테고리: MLOps"* ]]
  [[ "$note" == *"후보 태그: mlops, 머신러닝"* ]]
  [[ "$note" == *"상태: #대기중"* ]]
  [[ "$note" == *"검증: 통과"* ]]

  [[ "$(cat "$FAKE_GH_LOG")" == *"[컬렉션 제안] MLOps"* ]]
}

@test "keeps failed items out of direct note updates and moves them to quarantine" {
  run bash scripts/apply-results.sh tests/fixtures/result_mixed.json

  [ "$status" -eq 0 ]
  [ ! -f "$FAKE_HTTP_DIR/raindrop_98766.json" ]

  bulk_file="$(find "$FAKE_HTTP_DIR" -maxdepth 1 -name 'bulk_*.json' | head -n 1)"
  [ -n "$bulk_file" ]
  [ "$(jq -r '.collection["$id"]' "$bulk_file")" = "68803714" ]
  [ "$(jq -r '.ids | index(98766) != null' "$bulk_file")" = "true" ]
  [ "$(jq -r '.tags | index("검증실패") != null' "$bulk_file")" = "true" ]
}

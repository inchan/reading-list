#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export TEST_WORKDIR="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TEST_WORKDIR"
  cp -R "$PROJECT_ROOT/scripts" "$PROJECT_ROOT/config" "$PROJECT_ROOT/tests" "$TEST_WORKDIR/"
  mkdir -p "$TEST_WORKDIR/wiki/raw/raindrop" "$TEST_WORKDIR/wiki/raw/sources"
  cd "$TEST_WORKDIR"

  export RAINDROP_TEST_TOKEN="test-token-123"
  export TEST_BIN_DIR="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$TEST_BIN_DIR"
  export PATH="$TEST_BIN_DIR:$PATH"

  cat > "$TEST_BIN_DIR/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
url="${@: -1}"

if [[ "$url" == *"/raindrops/-1?page=0&perpage=50" ]]; then
  cat tests/fixtures/raindrops_page.json
  exit 0
fi

if [[ "$url" == *"/raindrops/-1?page=1&perpage=50" ]]; then
  printf '{"items":[]}\n'
  exit 0
fi

printf '{"items":[]}\n'
EOF
  chmod +x "$TEST_BIN_DIR/curl"
}

@test "syncs Raindrop items into immutable raw snapshots and compile queue" {
  run bash scripts/sync-raindrop-raw.sh --collection -1 --limit 1

  [ "$status" -eq 0 ]
  [ -d wiki/raw/raindrop/items/101 ]
  [ -f tmp/wiki-compile-queue.json ]

  raw_md="$(find wiki/raw/raindrop/items/101 -name '*.md' | head -n 1)"
  raw_json="$(find wiki/raw/raindrop/items/101 -name '*.json' | head -n 1)"
  [ -n "$raw_md" ]
  [ -n "$raw_json" ]

  [[ "$(cat "$raw_md")" == *"Karpathy LLM Wiki"* ]]
  [[ "$(cat "$raw_md")" == *"The wiki compounds over time."* ]]
  [ "$(jq -r '.items[0].source_id' tmp/wiki-compile-queue.json)" = "raindrop:101" ]
  [ "$(jq -r '.items[0].raw_markdown' tmp/wiki-compile-queue.json)" = "$raw_md" ]
}

@test "second sync with same digest does not enqueue duplicate work" {
  run bash scripts/sync-raindrop-raw.sh --collection -1 --limit 1
  [ "$status" -eq 0 ]

  run bash scripts/sync-raindrop-raw.sh --collection -1 --limit 1
  [ "$status" -eq 0 ]

  [ "$(find wiki/raw/raindrop/items/101 -name '*.md' | wc -l | tr -d ' ')" = "1" ]
  [ "$(jq '.items | length' tmp/wiki-compile-queue.json)" = "0" ]
}

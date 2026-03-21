#!/usr/bin/env bats

setup() {
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export RAINDROP_TEST_TOKEN="test-token-123"
  mkdir -p tmp
  # input_sample.json에 3개 북마크 (1개 중복 URL)
  cp tests/fixtures/input_sample.json tmp/input.json
}

teardown() {
  rm -f tmp/batch_*.json tmp/input.json
}

@test "removes duplicate URLs" {
  bash scripts/split-batches.sh
  # 3개 중 1개 중복 → 2개만 남아야 함
  total=$(jq '.bookmarks | length' tmp/batch_001.json)
  [ "$total" -eq 2 ]
}

@test "creates batch files with correct naming" {
  bash scripts/split-batches.sh
  [ -f tmp/batch_001.json ]
}

@test "batch includes collections from input" {
  bash scripts/split-batches.sh
  collections=$(jq '.collections | length' tmp/batch_001.json)
  [ "$collections" -eq 3 ]
}

@test "preserves run_date" {
  bash scripts/split-batches.sh
  date=$(jq -r '.run_date' tmp/batch_001.json)
  [ "$date" = "2026-03-21" ]
}

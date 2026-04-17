#!/usr/bin/env bats

setup() {
  export RAINDROP_TEST_TOKEN="***"
  source scripts/lib/raindrop-api.sh
  load_settings
}

@test "raindrop_auth_header returns correct header" {
  result=$(raindrop_auth_header)
  [ "$result" = "Authorization: Bearer ***" ]
}

@test "load_settings reads live config correctly" {
  [ "$API_BASE" = "https://api.raindrop.io/rest/v1" ]
  [ "$API_DELAY_MS" = "500" ]
  [ "$API_DELAY_S" = "0.5" ]
}

@test "raindrop_get_all_pages joins paginated items" {
  export TEST_BIN_DIR="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$TEST_BIN_DIR"
  export PATH="$TEST_BIN_DIR:$PATH"

  cat > "$TEST_BIN_DIR/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
url="${@: -1}"
if [[ "$url" == *"page=0&perpage=50" ]]; then
  printf '{"items":[{"_id":1},{"_id":2}]}'
  exit 0
fi
if [[ "$url" == *"page=1&perpage=50" ]]; then
  printf '{"items":[{"_id":3}]}'
  exit 0
fi
printf '{"items":[]}'
EOF
  chmod +x "$TEST_BIN_DIR/curl"

  result=$(raindrop_get_all_pages "/raindrops/-1")
  [ "$(printf '%s' "$result" | jq 'length')" = "3" ]
  [ "$(printf '%s' "$result" | jq '.[2]._id')" = "3" ]
}

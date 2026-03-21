#!/usr/bin/env bats

setup() {
  source scripts/lib/raindrop-api.sh
  export RAINDROP_TEST_TOKEN="test-token-123"
}

@test "raindrop_auth_header returns correct header" {
  result=$(raindrop_auth_header)
  [ "$result" = "Authorization: Bearer test-token-123" ]
}

@test "raindrop_api_base returns configured URL" {
  result=$(raindrop_api_base)
  [ "$result" = "https://api.raindrop.io/rest/v1" ]
}

@test "slugify converts title to valid slug" {
  result=$(slugify "React 19: Server Components Guide!")
  [ "$result" = "react-19-server-components-guide" ]
}

@test "slugify truncates to max length" {
  long_title="This is a very long title that should be truncated to sixty characters maximum for slug"
  result=$(slugify "$long_title")
  [ ${#result} -le 60 ]
}

@test "slugify handles Korean characters" {
  result=$(slugify "리액트 19 서버 컴포넌트 가이드")
  [ "$result" = "리액트-19-서버-컴포넌트-가이드" ]
}

@test "load_settings reads config correctly" {
  load_settings
  [ "$QUARANTINE_DAYS" = "10" ]
  [ "$MAX_PER_BATCH" = "20" ]
  [ "$PAGES_BASE_URL" = "https://inchan.github.io/reading-list" ]
}

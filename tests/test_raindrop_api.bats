#!/usr/bin/env bats

setup() {
  export RAINDROP_TEST_TOKEN="test-token-123"
  source scripts/lib/raindrop-api.sh
  load_settings
}

@test "raindrop_auth_header returns correct header" {
  result=$(raindrop_auth_header)
  [ "$result" = "Authorization: Bearer test-token-123" ]
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

@test "slugify strips non-ascii title characters safely" {
  result=$(slugify "리액트 19 서버 컴포넌트 가이드")
  [ "$result" = "19" ]
}

@test "load_settings reads config correctly" {
  [ "$QUARANTINE_DAYS" = "10" ]
  [ "$MAX_PER_BATCH" = "50" ]
  [ "$TAG_PENDING" = "대기중" ]
  [ "$TAG_QUARANTINE" = "검증실패" ]
  [ "$STATUS_PASSED" = "passed" ]
  [ "$STATUS_FAILED" = "failed" ]
}

@test "slugify_url strips protocol and query" {
  result=$(slugify_url "https://example.com/path/to/page?q=1")
  [ "$result" = "example-com-path-to-page" ]
}

@test "slugify_url handles trailing slash" {
  result=$(slugify_url "https://example.com/blog/")
  # trailing slash -> trailing dash -> slugify strips it
  [ "$result" = "example-com-blog" ]
}

@test "title_from_url extracts readable title" {
  result=$(title_from_url "https://example.com/blog/my-post")
  [ "$result" = "example.com blog my-post" ]
}

@test "title_from_url respects max length" {
  result=$(title_from_url "https://example.com/very/long/path/that/keeps/going" 20)
  [ ${#result} -le 20 ]
}

@test "get_quarantine_id requires API (skip in unit test)" {
  skip "requires live Raindrop API"
  result=$(get_quarantine_id)
  [ -n "$result" ]
}

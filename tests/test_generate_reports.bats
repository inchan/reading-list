#!/usr/bin/env bats

setup() {
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export RAINDROP_TEST_TOKEN="test-token-123"
  rm -rf reports/2026-03-21
}

teardown() {
  rm -rf reports/2026-03-21
}

@test "generates markdown report for passed item" {
  bash scripts/generate-reports.sh tests/fixtures/result_passed.json
  [ -f "reports/2026-03-21/example-com-react-19-guide.md" ]
}

@test "report contains correct frontmatter" {
  bash scripts/generate-reports.sh tests/fixtures/result_passed.json
  grep -q 'title: "React 19 Server Components Guide"' reports/2026-03-21/example-com-react-19-guide.md
  grep -q 'collection: "Frontend"' reports/2026-03-21/example-com-react-19-guide.md
  grep -q 'verification: "passed"' reports/2026-03-21/example-com-react-19-guide.md
}

@test "skips report generation for failed items" {
  bash scripts/generate-reports.sh tests/fixtures/result_failed.json
  [ ! -d "reports/2026-03-21" ] || [ $(find reports/2026-03-21 -name "*.md" 2>/dev/null | wc -l) -eq 0 ]
}

@test "handles mixed results" {
  bash scripts/generate-reports.sh tests/fixtures/result_mixed.json
  # passed 2개 → 보고서 2개
  count=$(find reports/2026-03-21 -name "*.md" | wc -l)
  [ "$count" -eq 2 ]
}

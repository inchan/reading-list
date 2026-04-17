#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  cd "$PROJECT_ROOT"
}

@test "workflow and docs describe local Codex compilation instead of Claude Code automation" {
  [ ! -f .github/workflows/claude.yml ]

  paths=(README.md docs prompts .github/workflows)
  if [ -e CLAUDE.md ]; then
    paths+=(CLAUDE.md)
  fi

  run rg -n "Claude Code|claude --print|@anthropic-ai/claude-code|CLAUDE_CODE_OAUTH_TOKEN|anthropics/claude-code-action|@claude" "${paths[@]}"
  [ "$status" -eq 1 ]

  run rg -n "Codex|codex" README.md prompts/actions/wiki-compile.md .github/workflows/process-bookmarks.yml
  [ "$status" -eq 0 ]
}

@test "compile contracts keep wiki summaries Korean-first" {
  run rg -n "한국어|Korean-first|Korean" wiki/SCHEMA.md prompts/ingest-source-into-wiki.md prompts/actions/wiki-compile.md
  [ "$status" -eq 0 ]
}

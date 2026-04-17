# Prompt-only skills

This directory contains skill prompt material that GitHub Actions can pass to an LLM.

These files are not runtime installations. They are versioned prompt inputs for the
reading-list wiki pipeline.

## Vendored prompts

### `karpathy-llm-wiki.upstream.md`

- Upstream: https://github.com/Astro-Han/karpathy-llm-wiki
- Source file: `SKILL.md`
- Commit: `9e8c4f44ce8d8f154494844a860cc6e9e49c8642`
- License: MIT
- License URL: https://github.com/Astro-Han/karpathy-llm-wiki/blob/main/LICENSE

The upstream prompt assumes root-level `raw/` and `wiki/` directories. The
GitHub Actions workflow must pass the project schema and reading-list ingestion
prompt after the upstream skill prompt so this repository's `wiki/raw/...`
layout wins.

# reading-list

reading-list is shifting from a one-pass Raindrop summarizer into a persistent wiki-style knowledge project.

Current direction:
- sync raw data from Raindrop into immutable raw-source files
- treat Raindrop as one source among multiple future source systems
- compile durable wiki pages from raw sources instead of only writing one-off summaries
- make the result readable like an LLM wiki / personal knowledge base

Working layers:
- `wiki/raw/raindrop/` — immutable Raindrop sync snapshots and source material
- `wiki/raw/sources/` — future non-Raindrop sources
- `wiki/entities/`, `wiki/concepts/`, `wiki/comparisons/`, `wiki/queries/` — compiled wiki pages
- `prompts/` — source analysis and wiki-ingestion prompts
- `scripts/` — deterministic sync / batching / apply helpers

Current non-goal:
- do not optimize for the old “read a list and emit a temporary summary” workflow anymore
- instead, optimize for durable source sync and compounding wiki pages

## Current pipeline

The active GitHub Actions path is manual and sample-first:

1. `scripts/sync-raindrop-raw.sh` syncs Raindrop items into immutable files under `wiki/raw/raindrop/`.
2. The workflow passes a prompt-only LLM Wiki skill from `prompts/skills/` plus the project schema to Claude Code.
3. Claude compiles queued raw sources into durable wiki pages and updates `wiki/index.md` / `wiki/log.md`.

The workflow does not install a global skill package and does not write results back to Raindrop.
It defaults to `dry_run=true`, so the first Action run shows pending wiki changes without committing them.

Planned public RSS address:

`https://inchan.github.io/reading-list/index.xml`

RSS clients subscribe to that URL after the `public/index.xml` publishing stage is implemented and GitHub Pages is enabled for the repository.

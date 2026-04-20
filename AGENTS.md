# reading-list — agent guide

Use this repository as a Raindrop raw-sync and wiki-compilation project.

## Live scope

- sync raw source material from Raindrop
- preserve raw snapshots as immutable source files
- queue the full backlog on initial bootstrap, then only unresolved/new/updated raw items on later runs
- compile durable markdown wiki pages from those raw files
- evolve the wiki taxonomy autonomously while keeping it normalized and searchable

## Working rules

- Start from raw-source preservation, not summary generation.
- Treat `wiki/raw/raindrop/` as append-only source storage.
- Treat compiled wiki pages as the durable output.
- Orient first: read `wiki/SCHEMA.md`, `wiki/index.md`, then recent `wiki/log.md` before major wiki work.
- Prefer codebase-backed docs over historical plans.
- Do not resurrect removed report-generation flows unless re-specified.
- When tags/categories need to evolve, use LLM judgment without human approval gates, then clean up aliases/duplicates afterward.
- Keep source-quality states out of topical tags; use `status_tags`.

## Current source-of-truth files

- `.github/workflows/process-bookmarks.yml`
- `scripts/sync-raindrop-raw.sh`
- `scripts/lib/raindrop-api.sh`
- `prompts/actions/wiki-compile.md`
- `prompts/ingest-source-into-wiki.md`
- `wiki/SCHEMA.md`
- `docs/tag-audit/tag-normalization.md`
- `tests/test_raindrop_api.bats`
- `tests/test_sync_raindrop_raw.bats`

## Success criteria

- raw-source sync remains deterministic
- raw snapshots stay immutable once written
- initial bootstrap re-queues every unhandled source until the wiki or `needs-review` log reflects it
- later runs collapse back to incremental additions and updates
- wiki pages preserve provenance
- taxonomy drift is reduced through canonicalization, alias cleanup, and status/topic separation
- output remains readable in a wiki-style browsing workflow

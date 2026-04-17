# reading-list — agent guide

Use this repository as a Raindrop raw-sync and wiki-compilation project.

## Live scope

- sync raw source material from Raindrop
- preserve raw snapshots as immutable source files
- queue newly synced raw items for compilation
- compile durable markdown wiki pages from those raw files

## Working rules

- Start from raw-source preservation, not summary generation.
- Treat `wiki/raw/raindrop/` as append-only source storage.
- Treat compiled wiki pages as the durable output.
- Prefer codebase-backed docs over historical plans.
- Do not resurrect removed report-generation flows unless re-specified.

## Current source-of-truth files

- `.github/workflows/process-bookmarks.yml`
- `scripts/sync-raindrop-raw.sh`
- `scripts/lib/raindrop-api.sh`
- `prompts/actions/wiki-compile.md`
- `prompts/ingest-source-into-wiki.md`
- `wiki/SCHEMA.md`
- `tests/test_raindrop_api.bats`
- `tests/test_sync_raindrop_raw.bats`

## Success criteria

- raw-source sync remains deterministic
- raw snapshots stay immutable once written
- queued work only includes new content digests
- wiki pages preserve provenance
- output remains readable in a wiki-style browsing workflow

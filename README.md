# reading-list

reading-list is a Raindrop-to-wiki pipeline.

The current codebase does one thing well:
- sync raw source material from Raindrop into immutable snapshots under `wiki/raw/raindrop/`
- queue newly seen raw sources for local Codex-assisted compilation
- compile durable markdown wiki pages under `wiki/`
- generate an RSS feed from the compiled wiki pages

It does not currently implement the older bookmark-triage/reporting flow.

## Active architecture

Source of truth is the code, not the old migration notes.

Runtime path:
1. `.github/workflows/process-bookmarks.yml`
2. `scripts/sync-raindrop-raw.sh`
3. `scripts/lib/raindrop-api.sh`
4. prompt-only local Codex compile inputs in `prompts/`
5. compiled wiki output in `wiki/`
6. `scripts/prepare-wiki-publish.sh` and `scripts/generate-wiki-rss.py`

## Active directories

- `config/settings.json` — minimal config used by the live raw-sync code
- `scripts/` — deterministic Raindrop sync helpers
- `prompts/` — prompt contracts used by the local Codex compile step
- `tests/` — Bats tests for the live sync/helper behavior
- `wiki/raw/raindrop/` — immutable synced source snapshots
- `wiki/entities/`, `wiki/concepts/`, `wiki/comparisons/`, `wiki/queries/` — compiled wiki pages
- `wiki/index.md`, `wiki/log.md`, `wiki/SCHEMA.md`, `wiki/feed.xml`, `index.xml` — wiki navigation, schema, internal feed, and deployment RSS
- `docs/codebase-status.md` — codebase-based project status and boundaries

## Current workflow

The GitHub Actions workflow is manual and sample-first. It syncs raw sources,
records the local Codex compile queue, and regenerates RSS from the current
compiled wiki. The synthesis step is intentionally local.

- Trigger: `workflow_dispatch`
- Default collection: `0` (all Raindrop items)
- Default limit: blank (all matched items)
- Default mode: `dry_run=true`

Flow:
1. Sync Raindrop items into immutable raw markdown/json pairs.
2. Build `tmp/wiki-compile-queue.json` for newly seen content digests.
3. Compile queued raw sources locally with Codex using the prompt contracts.
4. Keep compiled summaries, section headings, and explanatory prose Korean-first.
5. Run `scripts/prepare-wiki-publish.sh --site-url "$READING_LIST_SITE_URL"` to regenerate `wiki/feed.xml` and deployment `index.xml`.
6. Commit only wiki changes when `dry_run=false`.

## What is intentionally not in the live code path

These older ideas are not part of the current implementation:
- per-bookmark markdown reports under `reports/`
- GitHub Pages publishing for report pages
- `generate-reports.sh` / `generate-index.sh`
- direct write-back workflow as the primary product surface
- the old "temporary summary" prompt flow

## Current maturity

Implemented:
- deterministic raw sync
- digest-based deduped compile queue
- prompt-only local Codex wiki compile workflow
- initial compiled wiki pages from real synced sources
- local RSS feed generation from compiled wiki pages
- Bats coverage for helper + raw sync behavior

Not yet implemented:
- scheduled production sync cadence
- wiki lint/audit tooling
- public hosting automation for the wiki/RSS output
- non-Raindrop source adapters
- stronger verification of compiled page quality

## Running tests

```bash
bats tests
```

## Repo rule

When docs and code disagree, update docs to match the files currently exercised by:
- `.github/workflows/process-bookmarks.yml`
- `scripts/generate-wiki-rss.py`
- `scripts/prepare-wiki-publish.sh`
- `scripts/sync-raindrop-raw.sh`
- `tests/test_raindrop_api.bats`
- `tests/test_sync_raindrop_raw.bats`

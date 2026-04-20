# reading-list

reading-list is a Raindrop-to-wiki pipeline.

The current codebase does one thing well:
- sync raw source material from Raindrop into immutable snapshots under `wiki/raw/raindrop/`
- queue newly seen raw sources for local Codex-assisted compilation
- compile durable markdown wiki pages under `wiki/`
- generate RSS outputs for local wiki use and public deployment

It does not implement the older bookmark-triage/reporting flow.

## Active architecture

Source of truth is the code, not superseded migration notes.

Runtime path:
1. `.github/workflows/process-bookmarks.yml`
2. `scripts/sync-raindrop-raw.sh`
3. `scripts/lib/raindrop-api.sh`
4. prompt-only local Codex compile inputs in `prompts/`
5. compiled wiki output in `wiki/`
6. `scripts/prepare-wiki-publish.sh` and `scripts/generate-wiki-rss.py`
7. public deployment through repo-root `index.xml` served by GitHub Pages

## Active directories

- `config/settings.json` — minimal config used by the live raw-sync code
- `scripts/` — deterministic Raindrop sync helpers and RSS generation
- `prompts/` — prompt contracts used by the local Codex compile step
- `tests/` — Bats tests for the live sync/helper/RSS behavior
- `wiki/raw/raindrop/` — immutable synced source snapshots
- `wiki/entities/`, `wiki/concepts/`, `wiki/comparisons/`, `wiki/queries/` — compiled wiki pages
- `wiki/index.md`, `wiki/log.md`, `wiki/SCHEMA.md` — wiki navigation and schema
- `wiki/feed.xml` — internal/generated RSS artifact produced during publish prep
- `index.xml` — public deployment RSS served by GitHub Pages
- `docs/codebase-status.md` — codebase-based project status and boundaries
- `docs/tag-audit/` — current taxonomy audit and normalization notes

## Current workflow

The GitHub Actions workflow is manual and sync-first. It syncs raw sources,
records the local Codex compile queue, regenerates RSS artifacts, and relies on
GitHub Pages to serve the committed deployment output.

- Trigger: `workflow_dispatch`
- Default collection: `0` (all Raindrop items)
- Default limit: blank (all matched items)
- Default mode: `dry_run=true`

Flow:
1. Sync Raindrop items into immutable raw markdown/json pairs.
2. Build `tmp/wiki-compile-queue.json` for raw sources that are not yet reflected in compiled wiki pages or `needs-review` log coverage.
3. On the first bootstrap, this means the queue can include the full library backlog; after sources are handled, subsequent runs collapse back to incremental additions and updates.
4. Compile queued raw sources locally with Codex using the prompt contracts.
5. Keep compiled summaries, section headings, and explanatory prose Korean-first.
6. Run `scripts/prepare-wiki-publish.sh --site-url "$READING_LIST_SITE_URL"` to regenerate `wiki/feed.xml` and deployment `index.xml`.
7. Commit/push the updated deployment artifacts, then let GitHub Pages serve `index.xml`.

## What is intentionally not in the live code path

These older ideas are not part of the current implementation:
- per-bookmark markdown reports under `reports/`
- `generate-reports.sh` / `generate-index.sh`
- direct write-back workflow as the primary product surface
- the old temporary-summary prompt flow
- speculative multi-feed expansion docs that are not backed by current code

## Current maturity

Implemented:
- deterministic raw sync
- digest-based deduped compile queue
- prompt-only local Codex wiki compile workflow
- initial compiled wiki pages from real synced sources
- local RSS feed generation plus deployment RSS mirroring to `index.xml`
- GitHub Pages serving the committed deployment feed
- Bats coverage for helper + raw sync + RSS behavior

Not yet implemented:
- scheduled production sync cadence beyond manual dispatch
- wiki lint/audit tooling
- non-Raindrop source adapters
- stronger verification of compiled page quality
- a separately published public `feed.xml` endpoint

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
- `tests/test_generate_wiki_rss.bats`
- `tests/test_prepare_wiki_publish.bats`
- `tests/test_raindrop_api.bats`
- `tests/test_sync_raindrop_raw.bats`

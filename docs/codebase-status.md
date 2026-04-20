# reading-list codebase status

Last reviewed: 2026-04-20

## What the codebase actually does

The live implementation is a narrow MVP for a Raindrop-backed wiki pipeline.

Implemented surfaces:
- `scripts/sync-raindrop-raw.sh`
- `scripts/lib/raindrop-api.sh`
- `.github/workflows/process-bookmarks.yml`
- prompt contracts under `prompts/`
- compiled wiki storage under `wiki/`
- local RSS generation through `scripts/generate-wiki-rss.py`
- local publish prep through `scripts/prepare-wiki-publish.sh`, producing `wiki/feed.xml` and deployment `index.xml`
- GitHub Pages serving committed deployment output from repo-root `index.xml`
- tests for helper loading, raw sync, and RSS behavior

## Current data flow

1. Fetch Raindrop items through `raindrop_get_all_pages`.
2. Normalize each item and compute a SHA-256 content digest.
3. Write immutable raw snapshots under `wiki/raw/raindrop/items/<id>/`.
4. Emit a manifest under `wiki/raw/raindrop/manifests/`.
5. Emit `tmp/wiki-compile-queue.json` for any source that is still not represented in compiled wiki `source_ids` or the `needs-review` log.
6. On the first bootstrap, this queue can contain the full Raindrop backlog; later runs naturally narrow to unresolved/new/updated sources.
7. Compile queued raw sources locally with Codex into Korean-first wiki pages.
8. Generate `wiki/feed.xml` from the current compiled wiki and mirror the deployment feed to `index.xml`.
9. Commit/push the updated deployment artifacts, then let GitHub Pages serve `index.xml`.

## What was removed as non-live legacy

Removed because they were no longer part of the active workflow or documentation contract:
- legacy report artifacts under `reports/`
- old report-oriented scripts and their tests
- speculative docs for feeds or workflows not backed by current code
- backup/tmp artifacts that were accidentally tracked
- stale config files only consumed by removed scripts

## Remaining gaps

- no wiki linter yet
- no recurring scheduler beyond manual dispatch
- no non-Raindrop source adapter yet
- compile quality is only lightly verified compared with raw sync correctness
- no separately published public `feed.xml` endpoint

## Verification baseline

Use this as the mechanical baseline:

```bash
bats tests
```

The repository should be described in terms of this verified path, not older migration or speculative planning documents.

# reading-list — Raindrop-synced wiki project

## Purpose

This repository turns Raindrop bookmarks into immutable raw source snapshots and then compiles selected sources into a persistent markdown wiki.

## Active architecture

1. `scripts/sync-raindrop-raw.sh` fetches Raindrop items and stores immutable `.json` + `.md` raw snapshots under `wiki/raw/raindrop/items/`.
2. The same script emits `tmp/wiki-compile-queue.json` for raw sources that are still unhandled by compiled wiki pages or `needs-review` log coverage.
3. On an initial bootstrap, the queue can include the full Raindrop backlog; once sources are handled, later runs shrink back to incremental additions and updates.
4. Codex runs locally with prompt-only skill material plus local schema/prompt contracts.
5. Codex updates compiled pages in `wiki/`, navigation files in `wiki/index.md` and `wiki/log.md`, then regenerates `wiki/feed.xml` and deployment `index.xml`.
6. GitHub Pages serves the committed deployment artifact at repo-root `index.xml`.

## Boundaries

Keep:
- deterministic sync logic in shell scripts
- source provenance in raw files and frontmatter
- synthesis in compiled wiki pages
- a single public RSS deployment artifact rooted at `index.xml`

Do not assume this repo currently supports:
- report-page generation
- broad write-back automation beyond the raw sync / wiki compile path
- multiple public RSS endpoints beyond the committed deployment feed

## Current priorities

1. keep raw sync stable
2. keep docs aligned with the live code path
3. improve wiki compilation quality and validation
4. add future source adapters without breaking the Raindrop lane

# reading-list RSS Expansion Plan

> **For Hermes:** Use subagent-driven-development or strict TDD if implementing this plan.

**Goal:** Increase RSS coverage so the feed reflects the library more granularly than the current 12 topic pages.

**Architecture:** Keep the current compiled-wiki RSS as the canonical high-quality feed, but reduce over-aggregation in the largest concept pages and add a second feed that exposes ingest/raw-level freshness. This avoids destroying the wiki model while giving users a feed that feels closer to the full Raindrop library.

**Tech Stack:** existing markdown wiki, `scripts/generate-wiki-rss.py`, `scripts/prepare-wiki-publish.sh`, Bats tests, GitHub Pages.

---

## Current facts

- Current compiled wiki page count: **12**
- Current public RSS item count: **12**
- Current raw handled count: **112 / 112**
- Largest aggregated pages:
  - `wiki/concepts/korea-food-and-travel-notes.md` — 24 sources, 5 sections
  - `wiki/concepts/ai-agent-tools-and-infrastructure.md` — 22 sources, 6 sections
  - `wiki/concepts/ai-agent-harness-and-workflows.md` — 21 sources, 5 sections
- Medium aggregation pages:
  - `wiki/concepts/home-cooking-recipe-notes.md` — 9 sources
  - `wiki/concepts/knowledge-graph-rag-and-document-ai.md` — 9 sources
  - `wiki/concepts/ai-content-design-and-creative-automation.md` — 8 sources

## Product decision

Maintain **two feeds**:

1. **Compiled wiki feed** (`index.xml`) — curated, higher quality, topic-level
2. **Ingest feed** (`ingest.xml`) — more granular, freshness-oriented, closer to the raw library

Also reduce over-aggregation in the three largest topic pages.

---

## Split recommendations

### 1. `korea-food-and-travel-notes.md`
Split into:
- `korea-food-and-travel-seoul-metro.md`
- `korea-food-and-travel-gangwon-east-coast.md`
- `korea-food-and-travel-jeju-chungcheong.md`
- `korea-food-and-travel-honam-national.md`

Expected result:
- 1 RSS item becomes 4
- preserves geographic browsing
- reduces mixed-source sprawl

### 2. `ai-agent-tools-and-infrastructure.md`
Split into:
- `ai-agent-cli-and-session-ops.md`
- `ai-agent-orchestration-and-standards.md`
- `ai-agent-remote-control-and-browser-automation.md`
- `ai-agent-research-qa-and-geo-search.md`
- `ai-agent-risky-or-sensitive-tooling-notes.md`

Expected result:
- 1 RSS item becomes 5
- better distinction between tools vs orchestration vs control planes

### 3. `ai-agent-harness-and-workflows.md`
Split into:
- `ai-agent-spec-and-alignment-workflows.md`
- `ai-agent-evaluation-loops.md`
- `ai-agent-skills-and-team-operations.md`
- `ai-agent-review-cost-and-learning.md`

Expected result:
- 1 RSS item becomes 4
- separates operating doctrine from team tactics

If only those three pages are split, the compiled feed can grow from **12 → about 22** items without introducing raw-level noise.

---

## Ingest feed design

### Purpose
Expose recent handled/ingested material at a granularity closer to the raw library, without requiring one compiled wiki page per raw bookmark.

### Feed candidate
- Path: `ingest.xml`
- Source of entries:
  - preferred: `wiki/log.md` ingest entries
  - fallback/extension: latest manifest + queue provenance if needed later

### MVP item shape
Each RSS item should represent one ingest event or one source cluster mentioned in `wiki/log.md`.

Fields:
- title: log heading title
- pubDate: log heading date
- description: compact summary of source ids and affected pages
- link: either `wiki/log.md` anchor-style pseudo-link or the main created/updated page from that log entry

### Why this is the best MVP
- low implementation risk
- no need to invent per-raw article pages
- immediately increases feed freshness visibility
- preserves curated wiki feed as the main public artifact

---

## Implementation order

### Task 1: Freeze current feed behavior with tests
Add tests that assert:
- compiled feed still generates from compiled wiki pages only
- feed item count grows when large pages are split
- a second ingest feed can be generated from `wiki/log.md`

### Task 2: Add ingest-feed generator
Either:
- extend `scripts/generate-wiki-rss.py` with a mode flag, or
- create `scripts/generate-ingest-rss.py`

Recommended: create a separate script first to avoid destabilizing the current compiled feed.

### Task 3: Add publish prep support
Update `scripts/prepare-wiki-publish.sh` to generate:
- `wiki/feed.xml`
- repo root `index.xml`
- repo root `ingest.xml`

### Task 4: Split the three most aggregated pages
Use local Codex or manual editing with strict provenance preservation.
For each new page:
- preserve `sources`
- preserve `source_ids`
- update `wiki/index.md`
- append `wiki/log.md`
- ensure no source ids are dropped

### Task 5: Verify public deployment
After commit/push:
- verify `https://inchan.github.io/reading-list/index.xml`
- verify `https://inchan.github.io/reading-list/ingest.xml`
- compare item counts before/after

---

## Success criteria

- compiled feed item count increases materially from 12
- ingest feed exists and publishes successfully
- all split pages preserve raw provenance
- no handled raw source disappears from wiki coverage
- Pages serves both `index.xml` and `ingest.xml`

---

## Recommended immediate next step

Implement the **ingest feed first**, because it increases visible coverage fastest with the least content churn. Then split the three oversized compiled pages to improve the curated feed quality and item count.

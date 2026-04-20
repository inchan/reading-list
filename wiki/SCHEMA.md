# Wiki Schema

## Domain

Raindrop와 향후 추가될 소스 시스템에서 수집한 AI, 소프트웨어, 도구, 워크플로우, 금융/생활 참고자료를 한국어 중심의 탐색 가능한 LLM 위키로 정리한다.

## Layers

- `wiki/raw/raindrop/` — immutable Raindrop sync exports
- `wiki/raw/sources/` — immutable exports from other future source systems
- `wiki/entities/` — people, companies, tools, products, repos
- `wiki/concepts/` — ideas, methods, workflows, technical topics
- `wiki/comparisons/` — side-by-side comparisons and evaluations
- `wiki/queries/` — reusable synthesis pages

## Session orientation

기존 위키를 다룰 때는 항상 아래 순서로 먼저 읽는다.

1. `wiki/SCHEMA.md`
2. `wiki/index.md`
3. 최근 `wiki/log.md`

이 절차를 건너뛰면 중복 페이지, taxonomy 충돌, cross-link 누락이 생기기 쉽다.

## Core rules

- Raw files are immutable after sync.
- Compiled pages must link back to raw sources.
- Every compiled page must use markdown and be human-readable first.
- 위키 본문, 섹션 제목, 요약, index 항목 요약은 기본적으로 한국어로 작성한다.
- 원문 용어가 중요하면 한국어 설명 뒤에 영어 원문을 병기할 수 있다.
- Add new sources under `wiki/raw/` before compiling them into pages.
- Prefer updating a compiled page over creating duplicate pages.
- Local Codex compile sessions may use prompt-only skill files from `prompts/skills/`, but those skill prompts must obey this schema.
- `wiki/feed.xml` is generated from compiled pages and must use Korean-first item descriptions.
- Do not create root-level `raw/` or unrelated vault directories for this project.
- New or updated compiled pages should include at least 2 outbound cross-links to other wiki pages when relevant pages exist.
- If new information conflicts with existing content, record the conflict with dates/sources instead of silently overwriting it.
- Every substantial wiki action must update `wiki/index.md` and `wiki/log.md` in the same pass.

## Frontmatter

```yaml
---
title: Page Title
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: entity | concept | comparison | query
primary_category: ai
sources: [wiki/raw/raindrop/<file>.md]
source_ids: [raindrop:123]
tags: [tag-a, tag-b]
related_tags: [tag-c]
status_tags: [needs-review]
aliases: [TagA, Tag A]
contradictions: [other-page-name]
---
```

### Frontmatter notes

- `primary_category` is required for compiled pages.
- `tags` are the canonical detailed tags used for search and similarity.
- `related_tags` is optional and captures nearby concepts that help retrieval.
- `status_tags` is optional and must be used for source quality or workflow state.
- `aliases` is optional and records raw or legacy spellings that normalize to the canonical tags.
- `contradictions` is optional and only used when the page intentionally preserves conflicting claims.

## Page thresholds

- **Create a page** when an entity/concept appears in 2+ sources OR is central to one source.
- **Add to an existing page** when a source reinforces or extends a topic already covered.
- **Do not create a page** for passing mentions, sparse bookmarks, or pages with too little evidence.
- **Send to status review instead of inventing facts** when the raw capture is too thin to support a trustworthy synthesis.
- **Split a page** when it grows past roughly 200 lines or becomes hard to scan in 30 seconds.
- **Archive a page** when its content is fully superseded and it no longer deserves a primary slot in `wiki/index.md`.

## Taxonomy model

### Layer A. Primary categories

Primary categories are the main wiki navigation buckets. Each page should have 1 primary category, or at most 2 only when a page is genuinely cross-domain.

Current defaults:
- `ai`
- `finance`
- `food`
- `travel`
- `wellness`
- `reference`
- `culture`

### Layer B. Detail tags

Detail tags are richer and more flexible. They support search, related-page discovery, and RSS/topic grouping.

Examples:
- AI: `ai-agent`, `claude-code`, `codex`, `rag`, `document-ai`, `context-engineering`, `mcp`
- Finance: `market-data`, `trading`, `investing`, `multi-agent`
- Food / Travel: `home-cooking`, `restaurants`, `korea`, `jeju`, `gangwon`, `seoul-metro`
- Reference / Culture: `watchlist`, `reference`, `culture`

### Layer C. Status tags

Status tags are not topical classification. They describe source quality, confidence, or workflow state.

Examples:
- `access-limited`
- `needs-review`
- `bookmark-import`
- `image-heavy`

## Autonomous taxonomy policy

reading-list is an LLM-managed wiki. Human approval is not required before creating categories or tags.

Instead, the agent must keep the taxonomy clean through post-hoc maintenance:

- The agent may create a new `primary_category` when existing categories are repeatedly insufficient.
- The agent may create new detail tags whenever they materially improve retrieval or similarity grouping.
- New canonical tags should prefer lowercase kebab-case English or stable Korean forms.
- Equivalent variants must converge to a canonical form through `aliases` and normalization notes.
- Rare or weak primary categories should be downgraded into detail tags when they do not sustain meaningful navigation value.
- Repeated, high-value detail tags may be promoted into primary categories when they become a stable top-level browsing axis.
- Source-quality labels such as `접근불가` should be mapped into `status_tags`, not topical tags.

## Normalization defaults

- `ClaudeCode` → `claude-code`
- `ai-agents` → `ai-agent`
- `맛집리스트` → `맛집`
- `접근불가` → `access-limited`

## Page writing requirements

### Entity pages
- overview of what it is
- key facts or roles
- links to related entities/concepts
- provenance-backed notes only

### Concept pages
- concise explanation
- durable takeaways or patterns
- related concepts via cross-links
- provenance-backed synthesis only

### Comparison pages
- what is being compared and why
- dimensions of comparison, preferably in a table
- synthesis or verdict
- explicit sources

### Query pages
- only save answers worth reusing
- capture the question, answer, and pages/sources used

## Lint and maintenance loop

The wiki should be periodically checked for:

- orphan pages with no inbound links
- broken wikilinks
- index completeness
- missing required frontmatter fields
- tags that are not canonical or violate the taxonomy model
- overgrown pages that should be split
- stale pages whose source set has materially changed
- contradictions that should be surfaced instead of overwritten
- over-fragmented categories/tags that should be merged, promoted, or downgraded
- log size that should eventually be rotated

## Why this schema differs from the initial reading-list wiki

The repository already had the right bones: raw/compiled separation plus `SCHEMA.md`, `index.md`, and `log.md`.
This schema adds the missing operating system around those bones:

- explicit orientation before work
- a 3-layer taxonomy model
- autonomous category/tag creation with cleanup rules
- stronger cross-link expectations
- page thresholds and contradiction handling
- a reusable lint/maintenance loop

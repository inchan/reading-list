# Wiki Schema

## Domain

Raindrop와 향후 추가될 소스 시스템에서 수집한 AI, 소프트웨어, 도구, 워크플로우, 기술 읽을거리 아카이브.

## Layers

- `wiki/raw/raindrop/` — immutable Raindrop sync exports
- `wiki/raw/sources/` — immutable exports from other future source systems
- `wiki/entities/` — people, companies, tools, products, repos
- `wiki/concepts/` — ideas, methods, workflows, technical topics
- `wiki/comparisons/` — side-by-side comparisons and evaluations
- `wiki/queries/` — reusable synthesis pages

## Rules

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

## Frontmatter

```yaml
---
title: Page Title
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: entity | concept | comparison | query
sources: [wiki/raw/raindrop/<file>.md]
tags: [tag-a, tag-b]
---
```

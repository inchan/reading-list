# Wiki Schema

## Domain

AI, software, tools, workflows, and technical reading material compiled from Raindrop and future source systems.

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
- Add new sources under `wiki/raw/` before compiling them into pages.
- Prefer updating a compiled page over creating duplicate pages.
- GitHub Actions may pass prompt-only skill files from `prompts/skills/` to the LLM, but those skill prompts must obey this schema.
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

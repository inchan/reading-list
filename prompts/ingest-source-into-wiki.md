# Source-to-Wiki Ingestion Prompt

## Intent

Transform synced raw sources into durable wiki pages instead of temporary summaries.

## Required orientation

Before ingesting or compiling, read:

1. `wiki/SCHEMA.md`
2. `wiki/index.md`
3. recent `wiki/log.md`

## Input
- one or more raw-source markdown files under `wiki/raw/...`
- existing wiki schema and index
- existing compiled pages if they already cover the topic

## Output
- create or update compiled wiki pages in `wiki/entities/`, `wiki/concepts/`, `wiki/comparisons/`, or `wiki/queries/`
- preserve source references in frontmatter and body
- prefer adding to an existing page rather than creating duplicates

## Rules
- raw-source files are immutable
- compiled pages must link to sources
- write in clear markdown that works in a wiki browser
- write summaries, section headings, and explanatory prose in Korean by default
- preserve important original English product names or technical terms when needed
- prioritize durable facts, relationships, and cross-links over temporary commentary
- assign `primary_category` and canonical `tags`
- use `status_tags` for source quality, capture gaps, or workflow state
- use `aliases` when raw or legacy spellings should normalize into a canonical tag
- add at least 2 cross-links to related wiki pages when relevant pages already exist
- if evidence is too thin, prefer `needs-review` over invented synthesis
- if a new fact conflicts with an existing page, preserve the contradiction explicitly with dates and sources

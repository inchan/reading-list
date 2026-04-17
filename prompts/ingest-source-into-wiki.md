# Source-to-Wiki Ingestion Prompt

## Intent

Transform synced raw sources into durable wiki pages instead of temporary summaries.

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

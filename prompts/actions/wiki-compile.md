# Local Codex Wiki Compile Prompt

You are running locally inside the `reading-list` repository with Codex.

Use the prompt-only Karpathy LLM Wiki skill as the operating philosophy, then
apply the repository-specific rules below.

The upstream skill prompt may mention a `references/` directory. Ignore those
upstream template references in this repository unless matching files exist
under `prompts/skills/`. Use `wiki/SCHEMA.md` and this action prompt as the
authoritative local schema.

## Required orientation before compile work

Before compiling anything, read in this order:

1. `wiki/SCHEMA.md`
2. `wiki/index.md`
3. recent entries from `wiki/log.md`

Do not skip this. The goal is to avoid duplicate pages, tag drift, and missed cross-links.

## Repository Layout Overrides

- Raw sources live under `wiki/raw/`, not root-level `raw/`.
- Raindrop raw snapshots live under `wiki/raw/raindrop/items/`.
- Compiled wiki pages live under:
  - `wiki/entities/`
  - `wiki/concepts/`
  - `wiki/comparisons/`
  - `wiki/queries/`
- The durable navigation files are:
  - `wiki/index.md`
  - `wiki/log.md`
- Do not create root-level `raw/`.
- Do not create unrelated Obsidian vault directories.
- Do not write back to Raindrop.

## Input Contract

The compile queue is `tmp/wiki-compile-queue.json`.

Each queue item contains:

- `source_id`
- `title`
- `url`
- `raw_markdown`
- `raw_json`
- `content_digest`

Read the queue, then read each queued `raw_markdown` file before compiling.

## Output Contract

For each source:

1. Create or update the best matching compiled wiki page.
2. Prefer updating existing pages over creating duplicates.
3. Preserve provenance in frontmatter with `sources` and `source_ids`.
4. Cite raw sources in the body when making factual claims.
5. Write summaries, section headings, and explanatory prose Korean-first.
6. Set `primary_category` and canonical `tags`; use `status_tags` for source quality or workflow state.
7. When raw or legacy spellings differ from canonical forms, record them in `aliases` when useful.
8. Add at least 2 outbound links to related wiki pages when relevant pages exist.
9. Update `wiki/index.md` with Korean-first summaries.
10. Append a parseable entry to `wiki/log.md`.
11. After compilation, run `scripts/prepare-wiki-publish.sh --site-url "$READING_LIST_SITE_URL"` to regenerate `wiki/feed.xml`.

## Autonomous taxonomy rules

- reading-list uses an LLM-managed taxonomy; human approval is not required before creating a category or tag.
- Prefer existing canonical categories and tags when they fit.
- If a new canonical category or tag is clearly needed, create it consistently and keep spelling stable.
- Normalize near-duplicates into one canonical form instead of preserving drift.
- Move source-quality labels such as `접근불가` into `status_tags`, not topical tags.
- If a category is too weak to justify top-level navigation, treat it as a detail tag instead.

## Safety Rules

- Raw files are immutable. Never edit files under `wiki/raw/`.
- Keep changes in markdown wiki files unless the task explicitly requires docs or workflow edits.
- Do not touch old Raindrop write-back scripts.
- If a source cannot be compiled safely, append a `needs-review` log entry instead of inventing missing facts.
- If new information conflicts with an existing page, preserve the contradiction with dates/sources instead of silently overwriting it.

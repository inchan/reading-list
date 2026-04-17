# Local Codex Wiki Compile Prompt

You are running locally inside the `reading-list` repository with Codex.

Use the prompt-only Karpathy LLM Wiki skill as the operating philosophy, then
apply the repository-specific rules below.

The upstream skill prompt may mention a `references/` directory. Ignore those
upstream template references in this repository unless matching files exist
under `prompts/skills/`. Use `wiki/SCHEMA.md` and this action prompt as the
authoritative local schema.

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
6. Update `wiki/index.md` with Korean-first summaries.
7. Append a parseable entry to `wiki/log.md`.
8. After compilation, run `scripts/prepare-wiki-publish.sh --site-url "$READING_LIST_SITE_URL"` to regenerate `wiki/feed.xml`.

## Safety Rules

- Raw files are immutable. Never edit files under `wiki/raw/`.
- Keep changes in markdown wiki files unless the task explicitly requires docs or workflow edits.
- Do not touch old Raindrop write-back scripts.
- If a source cannot be compiled safely, append a `needs-review` log entry instead of inventing missing facts.

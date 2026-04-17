#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export TEST_WORKDIR="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TEST_WORKDIR"
  cp -R "$PROJECT_ROOT/scripts" "$TEST_WORKDIR/"
  cd "$TEST_WORKDIR"

  mkdir -p wiki/concepts wiki/raw/raindrop/items/101 public
}

write_korean_wiki_fixture() {
  cat > wiki/index.md <<'EOF'
# Wiki Index

Last updated: 2026-04-18

## Concepts

| Article | Summary | Updated |
|---------|---------|---------|
| [한국어 첫 글](concepts/korean-first.md) | 한국어 요약이 RSS 설명으로 들어간다. | 2026-04-18 |
| [두 번째 글](concepts/older.md) | 두 번째 한국어 요약이다. | 2026-04-17 |
EOF

  cat > wiki/concepts/korean-first.md <<'EOF'
---
title: 한국어 첫 글
created: 2026-04-17
updated: 2026-04-18
type: concept
sources:
  - wiki/raw/raindrop/items/101/raw.md
tags: [test]
---

# 한국어 첫 글

이 문서는 RSS 피드에 들어갈 최신 위키 문서다.
EOF

  cat > wiki/concepts/older.md <<'EOF'
---
title: 두 번째 글
created: 2026-04-16
updated: 2026-04-17
type: concept
sources:
  - wiki/raw/raindrop/items/101/raw.md
tags: [test]
---

# 두 번째 글

이 문서는 정렬 순서를 검증하기 위한 이전 위키 문서다.
EOF

  cat > wiki/raw/raindrop/items/101/raw.md <<'EOF'
# Raw Should Not Appear
EOF
}

@test "generates a valid RSS feed from compiled wiki pages with Korean summaries" {
  write_korean_wiki_fixture

  run python3 scripts/generate-wiki-rss.py \
    --site-url "https://example.test/reading-list" \
    --output public/feed.xml

  [ "$status" -eq 0 ]
  [ -f public/feed.xml ]

  python3 - <<'PY'
import re
import xml.etree.ElementTree as ET

tree = ET.parse("public/feed.xml")
channel = tree.getroot().find("channel")
assert channel is not None
assert channel.findtext("title") == "reading-list wiki"

items = channel.findall("item")
assert len(items) == 2
assert [item.findtext("title") for item in items] == ["한국어 첫 글", "두 번째 글"]
assert items[0].findtext("link") == "https://example.test/reading-list/wiki/concepts/korean-first.md"
assert items[0].findtext("description") == "한국어 요약이 RSS 설명으로 들어간다."
assert re.search(r"[가-힣]", items[0].findtext("description"))
assert "Raw Should Not Appear" not in open("public/feed.xml", encoding="utf-8").read()
PY
}

@test "rejects compiled wiki entries without a Korean-first RSS summary" {
  cat > wiki/index.md <<'EOF'
# Wiki Index

| Article | Summary | Updated |
|---------|---------|---------|
| [English Only](concepts/english-only.md) | This summary is not Korean-first. | 2026-04-18 |
EOF

  cat > wiki/concepts/english-only.md <<'EOF'
---
title: English Only
created: 2026-04-17
updated: 2026-04-18
type: concept
sources: []
tags: [test]
---

# English Only

This page has an English-only summary.
EOF

  run python3 scripts/generate-wiki-rss.py \
    --site-url "https://example.test/reading-list" \
    --output public/feed.xml

  [ "$status" -ne 0 ]
  [[ "$output" == *"Korean-first summary required"* ]]
}

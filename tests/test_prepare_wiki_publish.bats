#!/usr/bin/env bats

setup() {
  export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export TEST_WORKDIR="$BATS_TEST_TMPDIR/work"
  mkdir -p "$TEST_WORKDIR"
  cp -R "$PROJECT_ROOT/scripts" "$TEST_WORKDIR/"
  cd "$TEST_WORKDIR"

  mkdir -p wiki/concepts wiki/raw/raindrop/items/101

  cat > wiki/index.md <<'EOF'
# Wiki Index

| Article | Summary | Updated |
|---------|---------|---------|
| [배포 준비 글](concepts/publish-ready.md) | 로컬 배포 준비 과정에서 RSS로 노출될 한국어 요약. | 2026-04-18 |
EOF

  cat > wiki/concepts/publish-ready.md <<'EOF'
---
title: 배포 준비 글
created: 2026-04-17
updated: 2026-04-18
type: concept
sources:
  - wiki/raw/raindrop/items/101/raw.md
tags: [test]
---

# 배포 준비 글

로컬 배포 준비 스크립트가 참조하는 컴파일된 위키 문서다.
EOF

  cat > wiki/raw/raindrop/items/101/raw.md <<'EOF'
---
title: "배포용 원문"
source_type: raindrop
source_id: 101
source_url: "https://example.test/raw"
created: "2026-04-17T01:02:03Z"
updated: "2026-04-18T09:10:11Z"
synced_at: "2026-04-18T09:20:00Z"
content_digest: sha256:abc123
raw_json: "wiki/raw/raindrop/items/101/raw.json"
tags: ["test","deploy"]
---

# 배포용 원문

## Note

배포 준비 스크립트가 raw RSS 설명으로 써야 하는 한국어 메모.
EOF
}

@test "local publish prep regenerates raw-item RSS and deployment index.xml without touching wiki index" {
  run bash scripts/prepare-wiki-publish.sh \
    --site-url "https://example.test/reading-list" \
    --feed-output wiki/feed.xml

  [ "$status" -eq 0 ]
  [ -f wiki/feed.xml ]
  [ -f index.xml ]
  [ ! -d reports ]

  python3 - <<'PY'
import xml.etree.ElementTree as ET

channel = ET.parse("wiki/feed.xml").getroot().find("channel")
assert channel is not None
items = channel.findall("item")
assert len(items) == 1
assert items[0].findtext("title") == "배포용 원문"
assert "배포 준비 스크립트가 raw RSS 설명으로 써야 하는 한국어 메모." in items[0].findtext("description")
assert "[tags] test, deploy" in items[0].findtext("description")

assert '배포 준비 글' in open('wiki/index.md', encoding='utf-8').read()

deploy_channel = ET.parse("index.xml").getroot().find("channel")
assert deploy_channel is not None
deploy_items = deploy_channel.findall("item")
assert len(deploy_items) == 1
assert deploy_items[0].findtext("link") == "https://example.test/raw"
assert deploy_items[0].findtext("guid") == "https://example.test/raw"
assert '[raw] https://example.test/reading-list/wiki/raw/raindrop/items/101/raw.md' in deploy_items[0].findtext('description')
assert '[source] https://example.test/raw' in deploy_items[0].findtext('description')
PY
}

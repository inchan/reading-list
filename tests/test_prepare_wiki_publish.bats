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
}

@test "local publish prep regenerates wiki RSS and deployment index.xml without report artifacts" {
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
assert items[0].findtext("title") == "배포 준비 글"
assert items[0].findtext("description") == "로컬 배포 준비 과정에서 RSS로 노출될 한국어 요약."

deploy_channel = ET.parse("index.xml").getroot().find("channel")
assert deploy_channel is not None
deploy_items = deploy_channel.findall("item")
assert len(deploy_items) == 1
assert deploy_items[0].findtext("link") == "https://example.test/reading-list/wiki/concepts/publish-ready.md"
PY
}

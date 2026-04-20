# Tag Taxonomy Draft

## 2-layer tagging model

### Layer A. Primary wiki categories
위키의 대분류. 페이지당 1개 또는 최대 2개만 허용.

Current draft:
- `ai`
- `finance`
- `food`
- `travel`
- `wellness`
- `reference`
- `culture`

### Layer B. Detail / similar tags
상세 주제, 지역, 도구, 유사 문서 연결용 태그.

Examples:
- AI
  - `ai-agent`
  - `claude-code`
  - `codex`
  - `rag`
  - `document-ai`
  - `context-engineering`
  - `mcp`
- Finance
  - `market-data`
  - `trading`
  - `investing`
  - `multi-agent`
- Food / Travel
  - `home-cooking`
  - `restaurants`
  - `korea`
  - `jeju`
  - `gangwon`
  - `seoul-metro`
- Reference / Culture
  - `watchlist`
  - `reference`
  - `culture`

### Layer C. Status tags (separate axis)
주제와 분리된 보조 상태 태그.

Examples:
- `access-limited`
- `needs-review`
- `bookmark-import`
- `image-heavy`

---

## Recommended page shape

Each wiki page should eventually carry:
- `primary_category`
- `tags` (detail tags)
- optional `status_tags`

Example:
```yaml
primary_category: ai
tags: [ai-agent, claude-code, workflow, codex]
status_tags: [access-limited]
```

---

## Why this structure

- 대분류는 wiki 탐색과 RSS 그룹화에 유리
- 상세 태그는 검색과 유사 문서 탐색에 유리
- 상태 태그를 분리하면 `접근불가` 같은 값이 주제 분류를 오염시키지 않음

---

## Immediate implementation target

Phase 1:
- 문서로 taxonomy 확정
- alias 정의
- 신규 wiki page부터 `primary_category` + `tags` 규칙 적용

Phase 2:
- 기존 wiki page retrofit
- raw tag normalization script 추가
- tag index / category index 생성

# Tag Normalization and Autonomous Taxonomy Policy

## Goal

reading-list 태그를 **Hermes-style LLM wiki 운영 방식**에 맞춰 정리한다.

핵심은 두 가지다.

1. 위키 구조는 `SCHEMA.md / index.md / log.md + raw/compiled separation`을 유지한다.
2. taxonomy는 사람 승인 없이 LLM이 생성하되, 사후 정규화와 유지보수 루프로 품질을 유지한다.

---

## What changed from the earlier draft

이전 초안은 대분류와 상세 태그를 나누는 방향 자체는 맞았지만, 아직 아래가 약했다.

- taxonomy가 wiki schema에 완전히 통합되지 않음
- category/tag 생성 이후 merge/split/downgrade 규칙이 약함
- 상태 태그와 주제 태그 분리가 실무 규칙으로 고정되지 않음
- cross-link, lint, contradiction handling 같은 운영 규칙이 taxonomy와 연결되지 않음

이번 정리는 그 간극을 메우기 위한 운영정책이다.

---

## 3-layer taxonomy model

### Layer A. Primary category
위키 탐색의 큰 축.

기본 원칙:
- 페이지당 1개가 기본
- 최대 2개까지만 허용
- RSS/탐색/섹션 구성에 직접 영향을 줌

Current defaults:
- `ai`
- `finance`
- `food`
- `travel`
- `wellness`
- `reference`
- `culture`

### Layer B. Detail tags
검색, 유사 문서 연결, 세부 분류용 태그.

예:
- `ai-agent`
- `claude-code`
- `codex`
- `rag`
- `document-ai`
- `context-engineering`
- `market-data`
- `home-cooking`
- `jeju`
- `gangwon`
- `seoul-metro`

### Layer C. Status tags
주제가 아니라 상태/품질/처리 상태를 나타내는 축.

예:
- `access-limited`
- `needs-review`
- `bookmark-import`
- `image-heavy`

---

## LLM autonomy rule

reading-list는 **LLM-managed taxonomy**를 사용한다.

즉:
- 새 1차 카테고리 생성 가능
- 새 상세 태그 생성 가능
- 사람 승인 게이트 없음

대신 아래 정리 루프가 필수다.

### 생성은 느슨하게
LLM은 검색성, 연결성, 탐색성을 높이기 위해 category/tag를 만들 수 있다.

### 정리는 엄격하게
LLM은 주기적으로 아래를 수행해야 한다.

- alias canonicalization
- close-tag merge
- rare-category downgrade
- repeated-detail-tag promotion
- status/topic separation
- spelling/style normalization

한 줄 원칙:

> 생성은 자유롭게, 정리는 엄격하게.

---

## Canonicalization rules

### Preferred style
- 영문 canonical tag는 lowercase kebab-case
- 한국어 canonical tag는 이미 널리 쓰는 안정적 표현 유지
- 혼합 표기보다 하나의 canonical form 우선

### Alias handling
다음은 canonical tag로 수렴한다.

- `ClaudeCode` → `claude-code`
- `claude code` → `claude-code`
- `ai-agents` → `ai-agent`
- `접근불가` → `access-limited`
- `맛집리스트` → `맛집`

### Status/topic separation
다음과 같은 값은 topical tag에 두지 않는다.

- 접근 가능 여부
- 본문 부족 여부
- 이미지 중심 여부
- 검토 필요 여부

이런 값은 `status_tags`로 이동한다.

---

## Promotion and downgrade rules

### Promote detail tag → primary category when
- 여러 페이지에 반복 등장하고
- 기존 primary category 안에 계속 넣기 어색하며
- 실제 탐색 축으로 자주 쓰이고
- 앞으로도 늘어날 가능성이 높다

### Downgrade primary category → detail tag when
- 해당 카테고리 문서 수가 장기간 매우 적고
- 탐색 축으로의 가치가 낮고
- 기존 카테고리 안에서 detail tag로 더 자연스럽게 설명 가능하다

---

## Page shape

Compiled wiki pages should converge toward this frontmatter:

```yaml
primary_category: ai
tags: [ai-agent, claude-code, workflow, codex]
related_tags: [multi-agent, harness-engineering]
status_tags: [access-limited]
aliases: [ClaudeCode]
```

설명:
- `primary_category`: 큰 탐색 서랍
- `tags`: canonical 상세 태그
- `related_tags`: 가까운 개념 연결
- `status_tags`: 상태/품질 축
- `aliases`: raw/legacy/variant 형태

---

## Cross-link rule

taxonomy는 태그만의 문제가 아니다.

태그가 좋은데 문서 연결이 없으면 검색성과 재사용성이 약해진다.
그래서 새 문서를 만들거나 크게 갱신할 때는 가능하면 최소 2개의 관련 페이지를 링크한다.

즉 taxonomy maintenance와 page linking은 같이 봐야 한다.

---

## Lint loop

정기적으로 아래를 확인한다.

- orphan page
- broken wikilink
- schema 밖 또는 비정규 tag
- raw/status tag의 topical 오염
- 과도하게 잘게 쪼개진 카테고리
- merge 후보 태그
- 오래된 alias 누락
- index/log 반영 누락

---

## Practical interpretation for reading-list

현재 reading-list는 이미 LLM wiki의 구조를 갖췄다.
부족했던 것은 taxonomy 운영체계였다.

그래서 앞으로의 방향은 **재구축이 아니라 승격**이다.

- 기존 raw/compiled 구조 유지
- 기존 schema/index/log 유지
- taxonomy를 schema와 운영정책에 통합
- LLM이 category/tag를 자율 생성
- 대신 merge/promotion/downgrade/alias 정리를 반복

즉 reading-list는 이제 단순한 wiki 초안이 아니라,
**운영형 LLM wiki**로 진화하는 방향을 기본값으로 삼는다.

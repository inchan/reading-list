# Reading List Note-First Migration Plan

> 상태: completed
> 작성일: 2026-03-25
> 완료일: 2026-03-26

## 실행 결과

- 신규 주기 처리 경로는 note-first로 전환 완료
- 기존 report 기반 note 백필 18건 완료
- `generate-reports.sh`, `generate-index.sh`, GitHub Pages, Jekyll UI, `reports/` 레거시 자산 제거 완료
- 롤백 대비용 note 백업 JSON 생성 완료

## 목표

기존 `정적 보고서 생성 + Raindrop note에 보고서 링크 삽입` 전략을 중단하고, `Raindrop note에 한국어 핵심 요약 + 인사이트를 직접 저장`하는 전략으로 전환한다.

추가로 주기 실행 시에는 다음 원칙으로 동작을 변경한다.

- `passed + category 있음`:
  컬렉션 이동 + 태그 갱신 + note에 핵심 요약/인사이트 저장
- `passed + category 없음`:
  Unsorted 유지 + `#대기중` 태그 부여 + note에 추천 카테고리/핵심 요약/인사이트 저장
- `failed`:
  기존과 동일하게 `검증실패` 컬렉션 이동

## 현재 상태

현재 파이프라인의 핵심 동작은 아래와 같다.

1. `prompts/analyze-bookmarks.md`
   이미 한국어 `summary`, `insights`, `category`, `tags`를 생성한다.
2. `scripts/generate-reports.sh`
   `passed` 항목마다 `reports/YYYY-MM-DD/*.md` 보고서를 생성한다.
3. `scripts/apply-results.sh`
   Raindrop note에는 보고서 본문이 아니라 GitHub Pages 보고서 URL만 저장한다.
4. `scripts/fetch-unsorted.sh`
   Unsorted에서 `#대기중`, `#접근불가` 태그 항목을 제외하고 다음 배치 입력을 만든다.
5. `.github/workflows/process-bookmarks.yml`
   보고서 생성, 인덱스 생성, git 커밋/푸시까지 포함한 정적 사이트 중심 흐름이다.

즉 현재 시스템은 이미 "요약과 인사이트를 생성"하고 있고, 실제로 바꿔야 하는 것은 "어디에 저장하느냐"와 "Unsorted 대기 항목 note를 어떻게 쓰느냐"다.

## 목표 상태

### 1. note를 1차 저장소로 사용

Raindrop note에 아래 형식의 짧은 한국어 텍스트를 저장한다.

```text
핵심 요약
- ...
- ...

인사이트
- ...

분류
- 카테고리: ...
- 태그: ...
```

원칙:

- 길고 서술적인 보고서 대신, 모바일에서 바로 읽히는 짧은 note를 우선한다.
- note는 한국어만 사용한다.
- 링크 모음보다 "왜 읽을 가치가 있는지"가 바로 보이게 한다.

### 2. 보고서는 선택적 아카이브로 격하

정적 보고서는 아래 둘 중 하나로 정리한다.

- `Option A. 완전 중단`:
  `generate-reports.sh`, `generate-index.sh`, Pages 커밋 경로를 제거
- `Option B. 축소 유지`:
  디버깅/감사용 최소 아카이브만 남기고 note를 주 경로로 사용

현재 요구와 운영 복잡도를 고려하면 기본 권장안은 `Option A`다.

### 3. Unsorted도 "읽을 수 있는 상태"로 남김

카테고리 미매칭 항목은 더 이상 "링크만 꽂힌 대기 상태"가 아니라 아래처럼 바뀐다.

- Unsorted에 남아 있어도 note에서 핵심 요약/인사이트를 바로 확인 가능
- note에 추천 카테고리 또는 분류 보류 사유를 함께 기록
- 사람이 나중에 컬렉션만 결정하면 됨

## note 포맷 제안

### A. 분류 완료 항목

```text
핵심 요약
- {summary를 2-4개 bullet로 재구성}

인사이트
- {insights를 1-3개 bullet로 재구성}

분류
- 카테고리: {collection_title}
- 태그: {tag1}, {tag2}, {tag3}
```

### B. Unsorted 유지 항목

```text
핵심 요약
- {summary}

인사이트
- {insights}

분류 제안
- 추천 카테고리: 미정
- 후보 태그: {tag1}, {tag2}
- 상태: #대기중
```

### C. note 작성 규칙

- `summary`, `insights` 원문이 문단형이면 note 단계에서 bullet형으로 정규화한다.
- 너무 길면 잘라내되, 첫 화면에서 다 읽히는 길이를 우선한다.
- note에는 검증 claim 전체나 외부 관련 링크를 기본으로 넣지 않는다.
- 필요하면 마지막 한 줄에 `검증: 통과` 정도만 남긴다.

## 마이그레이션 범위

### 1. Phase 1 출력 계약은 가능한 유지

우선은 `summary`, `insights`, `category`, `tags`를 그대로 사용한다.

이유:

- 프롬프트 계약을 크게 바꾸지 않아도 됨
- 기존 테스트 픽스처 대부분을 재사용 가능
- 변경 위험이 `apply-results.sh`와 후속 산출물로 제한됨

### 2. Phase 2 적용 로직을 note-first로 변경

핵심 변경점:

- `note_url` 생성 제거
- note 본문을 만드는 `render_note_text` 계열 함수 추가
- `passed_with_collection` 처리 시 `collection + tags + rendered note` 저장
- `passed_pending` 처리 시 `#대기중 + rendered note` 저장

### 3. 정적 보고서 단계 축소 또는 제거

변경 대상:

- `scripts/generate-reports.sh`
- `scripts/generate-index.sh`
- `index.md`
- `reports/**`
- `.github/workflows/process-bookmarks.yml`의 commit 대상

## 단계별 실행 계획

## Phase 0. 사전 안전장치

1. note 렌더링 규칙을 문서로 먼저 확정
2. `apply-results.sh` 변경 전 회귀 테스트 추가
3. 샘플 result JSON으로 note 문자열이 기대 형식인지 테스트 고정

권장 테스트:

- `passed + category 있음` → note에 요약/인사이트/카테고리/태그 포함
- `passed + category 없음` → note에 `#대기중` 상태와 분류 제안 포함
- `failed` → note 미작성

## Phase 1. note-first 적용

변경 파일 후보:

- `scripts/apply-results.sh`
- `tests/fixtures/result_passed.json`
- `tests/fixtures/result_mixed.json`
- 신규 테스트 파일 또는 기존 테스트 확장

작업:

1. note 렌더링 헬퍼 추가
2. `note_url` 기반 업데이트 제거
3. `passed` 항목은 보고서 URL 대신 rendered note를 저장
4. `new_collections_needed` 이슈 본문도 note-first 관점에 맞게 정리

완료 기준:

- Raindrop 업데이트 payload에 URL이 아니라 한국어 note 텍스트가 들어감
- `passed_pending`도 note가 채워짐

## Phase 2. 보고서 경로 정리

권장 순서:

1. 워크플로우에서 `generate-reports.sh` 호출 제거
2. `generate-index.sh` 및 Pages용 커밋 범위 제거
3. `reports/`는 읽기 전용 레거시 아카이브로 남기거나 삭제 계획 수립

보수적 운영안:

- 1주일 정도는 `report generation`을 플래그로 남겨 병행 운영
- note가 안정화되면 보고서 생성을 완전히 제거

## Phase 3. 기존 자산 마이그레이션

대상:

- 이미 note에 보고서 링크만 들어간 기존 passed 북마크
- 기존 `reports/YYYY-MM-DD/*.md`

권장 방식:

1. 기존 보고서 마크다운에서 `요약`/`인사이트`만 읽어 note를 역채움
2. note가 성공적으로 채워진 북마크는 링크 note를 새 형식으로 교체
3. 보고서 파일은 즉시 삭제하지 않고 일정 기간 유지

이 단계는 별도 일회성 스크립트로 처리하는 것이 안전하다.

예상 작업:

- 보고서 frontmatter의 `raindrop_id`로 대상 북마크 식별
- `## 요약`, `## 인사이트` 섹션 파싱
- 새 note 템플릿으로 변환 후 Raindrop API 업데이트

## Phase 4. Unsorted 운영 정책 전환

주기 실행에서 Unsorted 관련 정책은 아래처럼 정리한다.

### 입력 단계

현재처럼 아래 항목은 계속 제외한다.

- `#대기중`
- `#접근불가`

이 정책은 유지하는 편이 맞다.

이유:

- 이미 한 번 요약/인사이트가 생성된 대기 항목을 매 실행마다 다시 분석할 필요가 없음
- Unsorted는 "미분류"이지 "미처리 재분석 큐"가 아니어야 함

### 출력 단계

`passed + category 없음`이면:

- Unsorted 유지
- `#대기중` 태그 부여
- note에 핵심 요약/인사이트 저장
- note에 "분류 제안" 블록 추가

이렇게 하면 Unsorted에서도 바로 읽을 수 있고, 사람이 나중에 카테고리만 정하면 된다.

## 구현 우선순위

1. `apply-results.sh` note-first 전환
2. 테스트 추가
3. 기존 보고서 역마이그레이션 스크립트 작성
4. 워크플로우에서 report/pages 단계 제거
5. 레거시 보고서 정리

## 리스크와 대응

### 리스크 1. Raindrop note 길이/줄바꿈 포맷 이슈

대응:

- 실제 API 응답으로 줄바꿈 보존 여부 확인
- 지나치게 긴 summary는 bullet 2-4개로 제한

### 리스크 2. 기존 보고서 자산 손실

대응:

- note 역마이그레이션 완료 전 `reports/` 삭제 금지
- 최소 1회 백필 결과 샘플 검수 후 일괄 실행

### 리스크 3. note 포맷이 너무 장황해지는 문제

대응:

- "핵심 요약 / 인사이트 / 분류" 3블록만 유지
- 검증 세부 내역은 기본적으로 제외

### 리스크 4. category 없는 항목이 쌓이는 문제

대응:

- `#대기중` 유지
- GitHub Issue 생성은 계속 유지
- note에 추천 분류 단서를 넣어 수동 분류 비용 축소

## 검증 계획

### 자동 검증

- bash 테스트에서 note payload 문자열 검증
- 기존 failed/quarantine 동작 회귀 검증

### 수동 검증

샘플 3건으로 실제 API 반영 확인:

1. 분류 완료 passed 1건
2. Unsorted 유지 passed 1건
3. failed 1건

확인 포인트:

- note 줄바꿈
- 한글 가독성
- 태그 유지/대체 여부
- Unsorted 유지 여부

## 권장 결정

이번 변경은 "분석 품질 개선"보다 "적용 전략 전환"이 중심이므로, 아래 순서가 가장 안전하다.

1. note-first 적용
2. 기존 보고서 백필
3. 병행 운영 짧게 수행
4. report/pages 제거

즉시 구현 범위는 `apply-results.sh`와 테스트부터 시작하는 것이 적절하다.

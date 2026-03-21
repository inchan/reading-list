# Reading List Pipeline — 설계 문서

> **상태**: 설계 확정 (스펙 리뷰 반영 v2)
> **날짜**: 2026-03-21
> **저장소**: https://github.com/inchan/reading-list

---

## 1. 개요

GitHub Actions로 AI(Claude Code)가 Raindrop.io의 미분류 북마크를 가져와서 실체 검증(substance verification) → 요약/인사이트 보고서 생성 → git 저장소에 저장하는 자동화 파이프라인.

### 핵심 가치
- **큐레이션**: 쏟아지는 북마크를 AI가 걸러서 읽을 가치 있는 것만 남김
- **지식 아카이브**: 보고서로 핵심을 저장하여 검색 가능한 지식 베이스 구축

---

## 2. 파이프라인 흐름

```
┌─────────────────────────────────────────────────────┐
│ GitHub Actions (cron 매일 09:00 KST / 수동)          │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Phase 0: 사전 준비 [스크립트]                        │
│  ├── Raindrop API: 기존 컬렉션 목록 조회              │
│  ├── Raindrop API: Unsorted 북마크 목록 가져오기       │
│  └── 검증실패 컬렉션에서 10일 경과 항목 → 휴지통       │
│                                                     │
│  Phase 1: AI 분석 [Claude Code]                      │
│  ├── 입력: 배치 JSON (최대 20개/배치)                 │
│  ├── 각 북마크별:                                    │
│  │   ├── URL 접근 + 본문 읽기                        │
│  │   ├── 실체 검증 (웹 검색)                         │
│  │   ├── 요약 + 인사이트 생성                        │
│  │   └── 카테고리(컬렉션) + 태그 결정                 │
│  └── 출력: 판단 결과 JSON                            │
│                                                     │
│  Phase 2: 실행 [스크립트]                            │
│  ├── 판단 결과 JSON 파싱                             │
│  ├── 검증 통과:                                     │
│  │   ├── 개별 보고서 마크다운 생성                    │
│  │   ├── Raindrop: 컬렉션 이동 + 태그 + 노트(URL)    │
│  │   └── 새 컬렉션 필요 시: gh issue create          │
│  ├── 검증 실패:                                     │
│  │   └── Raindrop: 검증실패 컬렉션으로 이동           │
│  ├── 일별 인덱스 생성                                │
│  └── git commit + push                              │
│                                                     │
│  Phase 3: 배포 [GitHub Actions]                      │
│  └── GitHub Pages 자동 배포 (Jekyll 기본)             │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 핵심 원칙
- Phase 0, 2, 3은 결정론적 → bash 스크립트 (Raindrop REST API 직접 호출, MCP 미사용)
- Phase 1만 AI 판단 → Claude Code (웹 검색/URL 접근만 사용, Raindrop MCP 불필요)
- Phase 간 데이터 전달은 JSON 파일

### 배치 분할
- 1배치 = 최대 20개 북마크
- 20개 초과 시 자동으로 배치 분할 후 순차 처리
- `split-batches.sh`에서 중복 URL을 사전 제거 (같은 URL이 여러 북마크에 있으면 첫 번째만 포함)
- 배치별로 Claude Code 호출 → 결과 적용 → 다음 배치

---

## 3. 실체 검증 (Substance Verification)

전통적 팩트체크가 아닌 **"실체가 있는가"** 검증.

### 검증 대상
| 대상 | 방법 |
|------|------|
| 도구/라이브러리/저장소 | GitHub, npm, PyPI 등에서 실제 존재 확인 |
| 방법론/이론 | 원본 논문, 공식 문서, 인용 출처 존재 여부 |
| 구체적 주장 (이름, 날짜, 수치) | 독립적 출처로 교차 검증 |
| AI 생성 허구 | 구체적 주장이 실제와 일치하는지 확인 |

### 판정 기준
- **passed**: 핵심 주장 중 1개 이상이 독립적 출처에서 검증됨 AND 반증된 것 없음
- **failed**: 접근 실패 / 모든 주장 확인 불가 / 명백한 반증 / 페이월로 검증 불충분

### URL 접근 상태
| 상태 | 조건 | 처리 |
|------|------|------|
| `ok` | 정상 접근 | 분석 진행 |
| `redirected` | 리다이렉트 | final_url 기록, 분석 진행 |
| `paywalled` | 페이월/로그인 필요 | 접근 가능 부분으로 시도, 부족하면 failed |
| `blocked` | 401/403/429/봇차단 | 즉시 failed |
| `empty` | 본문 없음, 소프트 404 | 즉시 failed |
| `error` | 404/5xx/타임아웃 | 즉시 failed |

---

## 4. 카테고리 분류

### 구조: 컬렉션(대분류) + 태그(세부 분류)
- **컬렉션**: 기존 Raindrop 컬렉션 목록에서만 선택 (고정 목록)
- **태그**: AI가 2-5개 자동 부여 (영어는 소문자, 한국어는 그대로)
- **새 컬렉션 필요 시**: GitHub Issue로 자동 등록 → 사람 승인 후 추가

### 컬렉션 미매칭 passed 항목 처리 (B4)
- AI가 `category: null` + `new_collections_needed`에 추가한 경우
- Unsorted에 유지 (이동하지 않음) → 다음 실행에서 재처리되지 않도록 `#대기중` 태그 부여
- 보고서는 정상 생성 (frontmatter `collection: "미분류"`)
- GitHub Issue 생성 → 사람이 컬렉션 승인 → 수동으로 이동

### 검증 실패 처리
1. 검증 실패 → `검증실패` 컬렉션으로 이동
2. 10일 경과 → 자동으로 휴지통 이동 (매일 Phase 0에서 실행)
3. 10일 내 사용자가 확인하고 복구 가능

### 초기 셋업 (W9)
- 최초 실행 전 `검증실패` 컬렉션을 Raindrop에 수동 생성 필요
- `scripts/setup.sh`에서 존재 여부 확인 → 없으면 API로 자동 생성

---

## 5. 데이터 구조

### Phase 0 출력 → Phase 1 입력: `tmp/input.json`

```json
{
  "run_date": "2026-03-21",
  "collections": [
    { "id": 12345, "title": "Frontend", "parent_id": null }
  ],
  "bookmarks": [
    {
      "id": 98765,
      "title": "Some Article Title",
      "url": "https://example.com/article",
      "excerpt": "Raindrop이 저장한 요약",
      "created": "2026-03-20T14:30:00Z",
      "tags": [],
      "type": "link"
    }
  ]
}
```

### Phase 1 출력 → Phase 2 입력: `tmp/result_batch_NNN.json`

**필드 계약 — passed 항목:**

```json
{
  "bookmark_id": 98765,
  "url": "https://example.com/article",
  "final_url": null,
  "fetch_status": "ok",
  "verification": {
    "status": "passed",
    "reason": null,
    "claims": [
      {
        "claim": "React 19에서 서버 컴포넌트가 기본 지원됨",
        "verified": true,
        "sources": ["https://react.dev/blog/...", "https://github.com/facebook/react/releases/..."]
      }
    ]
  },
  "summary": "3-5문장 한국어 요약",
  "insights": "한국어 인사이트",
  "category": {
    "collection_id": 12345,
    "collection_title": "Frontend"
  },
  "tags": ["react", "server-components", "성능최적화"],
  "related_links": ["https://..."]
}
```

**필드 계약 — failed 항목:**

```json
{
  "bookmark_id": 98766,
  "url": "https://example.com/fake-tool",
  "final_url": null,
  "fetch_status": "ok",
  "verification": {
    "status": "failed",
    "reason": "주장하는 GitHub 저장소가 존재하지 않음",
    "claims": [
      {
        "claim": "turbo-framework v3.0이 GitHub에 공개됨",
        "verified": false,
        "sources": []
      }
    ]
  },
  "summary": null,
  "insights": null,
  "category": null,
  "tags": ["검증실패"],
  "related_links": []
}
```

**전체 출력:**

```json
{
  "run_date": "YYYY-MM-DD",
  "results": [ ... ],
  "new_collections_needed": [
    {
      "suggested_name": "MLOps",
      "reason": "ML 운영 관련 북마크가 분류할 컬렉션이 없음",
      "bookmark_ids": [98765, 98770]
    }
  ]
}
```

---

## 6. 보고서 형식

### Slug 생성 규칙 (W6)
- URL에서 도메인+경로를 기반으로 생성: `example-com-article-title`
- 한국어는 그대로 유지 (URL 인코딩하지 않음)
- 특수문자 제거, 공백→하이픈, 최대 60자
- 중복 시 `-2`, `-3` 접미사 추가
- `generate-reports.sh`에서 처리

### 개별 보고서: `reports/YYYY-MM-DD/<slug>.md`

```markdown
---
title: "Some Article Title"
url: "https://example.com/article"
date: "2026-03-21"
collection: "Frontend"
tags: ["react", "server-components", "성능최적화"]
verification: "passed"
raindrop_id: 98765
---

## 요약
3-5문장 핵심 요약

## 인사이트
이 글에서 주목할 점, 실무 적용 가능성

## 실체 검증 결과
- "React 19에서 서버 컴포넌트가 기본 지원됨" → ✅ (출처: https://react.dev/blog/...)

## 관련 링크
- https://...
```

### 일별 인덱스: `reports/YYYY-MM-DD/index.md`

```markdown
---
date: 2026-03-21
total: 5
passed: 3
failed: 2
---

# 2026-03-21 Reading List Report

## 처리 완료 (3건)
| 제목 | 컬렉션 | 태그 | 보고서 |
|------|--------|------|--------|
| Some Article | Frontend | react, performance | [보기](./some-article.md) |

## 검증 실패 (2건)
| 제목 | 사유 |
|------|------|
| Fake Article | 주장하는 GitHub 저장소가 존재하지 않음 |
```

### Raindrop 노트에 기록할 URL
```
https://inchan.github.io/reading-list/reports/2026-03-21/some-article
```

---

## 7. 디렉토리 구조

```
reading-list/
├── .github/
│   └── workflows/
│       ├── process-bookmarks.yml    # 메인 워크플로우
│       └── deploy-pages.yml         # GitHub Pages 배포
│
├── scripts/
│   ├── setup.sh                     # 초기 셋업 (검증실패 컬렉션 생성 등)
│   ├── fetch-unsorted.sh            # Phase 0: unsorted 가져오기 (페이지네이션 포함)
│   ├── cleanup-quarantine.sh        # Phase 0: 10일 경과 → 휴지통
│   ├── split-batches.sh             # Phase 0→1: 배치 분할 + 중복 URL 제거
│   ├── apply-results.sh             # Phase 2: Raindrop API 호출
│   ├── generate-reports.sh          # Phase 2: 보고서 마크다운 생성 (slug 생성 포함)
│   ├── generate-index.sh            # Phase 2: 일별 인덱스 생성
│   └── lib/
│       └── raindrop-api.sh          # 공통 Raindrop API 헬퍼 (인증, 페이지네이션, rate limit)
│
├── prompts/
│   └── analyze-bookmarks.md         # Claude Code 프롬프트
│
├── tmp/                             # .gitignore 대상
│   ├── input.json
│   ├── batch_001.json
│   └── result_batch_001.json
│
├── reports/
│   └── YYYY-MM-DD/
│       ├── index.md
│       └── <slug>.md
│
├── config/
│   ├── collections.json             # 컬렉션 매핑 캐시 (Phase 0에서 갱신)
│   └── settings.json                # 아래 설정 명세 참조
│
└── docs/
    └── superpowers/specs/           # 설계 문서
```

### `config/settings.json` 명세 (N6)

```json
{
  "schedule_cron": "0 0 * * *",
  "quarantine_days": 10,
  "quarantine_collection_name": "검증실패",
  "max_bookmarks_per_batch": 20,
  "pages_base_url": "https://inchan.github.io/reading-list",
  "raindrop_api_base": "https://api.raindrop.io/rest/v1",
  "raindrop_api_delay_ms": 500,
  "slug_max_length": 60,
  "issue_labels": ["new-collection", "auto"]
}
```

### GitHub Issue 형식 (N7)

새 컬렉션 제안 시 자동 생성되는 Issue:

```markdown
title: "[컬렉션 제안] MLOps"
labels: new-collection, auto
body:
  ## 제안 컬렉션: MLOps
  **사유**: ML 운영 관련 북마크가 분류할 컬렉션이 없음
  **관련 북마크**: #98765, #98770
  **처리일**: 2026-03-21
```

---

## 8. GitHub Actions 워크플로우

```yaml
name: Process Reading List
on:
  schedule:
    - cron: '0 0 * * *'              # 매일 00:00 UTC (09:00 KST)
  workflow_dispatch:

concurrency:
  group: process-reading-list          # 동시 실행 방지 (N2)
  cancel-in-progress: false

jobs:
  process:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup
        run: sudo apt-get install -y jq

      - name: Setup Claude Code
        uses: anthropics/claude-code-action@v1  # 또는 직접 설치

      # Phase 0
      - name: Cleanup quarantine (10일 경과 → 휴지통)
        run: scripts/cleanup-quarantine.sh

      - name: Fetch unsorted bookmarks
        run: scripts/fetch-unsorted.sh

      - name: Split into batches
        run: scripts/split-batches.sh

      # Phase 1 + 2 배치 루프
      - name: Process batches
        run: |
          for batch in tmp/batch_*.json; do
            [ -f "$batch" ] || continue

            result_file="tmp/result_$(basename $batch)"

            # Phase 1: Claude Code 분석 (B1, B2 수정)
            cat "$batch" | claude --print \
              --system-prompt "$(cat prompts/analyze-bookmarks.md)" \
              --output-format json \
              --dangerously-skip-permissions \
              > "$result_file" || { echo "배치 실패: $batch"; continue; }

            # Phase 2: 결과 적용
            scripts/apply-results.sh "$result_file" || { echo "적용 실패: $result_file"; continue; }
          done

      # Phase 2 마무리
      - name: Generate daily index
        run: scripts/generate-index.sh

      - name: Commit and push reports
        run: |
          git add reports/
          git diff --cached --quiet && echo "변경사항 없음" && exit 0  # (W10)
          git commit -m "report: $(date +%Y-%m-%d) 처리 결과"
          git push

    env:
      RAINDROP_TEST_TOKEN: ${{ secrets.RAINDROP_TEST_TOKEN }}
      ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### Claude Code CLI 호출 상세 (B1, B2)

```bash
# 올바른 호출 방식:
# - 바이너리: claude (claude-code 아님)
# - 입력: stdin pipe (--input 플래그 없음)
# - 출력: stdout > 리다이렉션 (--output 플래그 없음)
# - 시스템 프롬프트: --system-prompt "문자열" (파일 경로 불가, cat으로 읽기)
# - JSON 보장: --output-format json (W2)
# - CI 권한: --dangerously-skip-permissions (인터랙티브 승인 불가하므로 필수)

cat "$batch" | claude --print \
  --system-prompt "$(cat prompts/analyze-bookmarks.md)" \
  --output-format json \
  --dangerously-skip-permissions \
  > "$result_file"
```

### 시크릿
| 이름 | 용도 |
|------|------|
| `RAINDROP_TEST_TOKEN` | Raindrop API 인증 (만료 없음) |
| `ANTHROPIC_API_KEY` | Claude Code 인증 (또는 OAuth) |

---

## 9. AI 런타임

- **Claude Code 우선 구현** — OAuth 구독 플랜으로 CI 실행 가능 (확인됨)
- 파이프라인 로직(스크립트)과 AI 호출(Claude Code)이 분리되어 있으므로, 나중에 다른 런타임으로 교체 가능
- Gemini CLI / Codex CLI는 현재 OAuth/구독 CI 사용 불가 (API key만 공식 지원)

---

## 10. Raindrop 접근 방식 (B3 해결)

### 결정: MCP 미사용, REST API 직접 호출

파이프라인 분석 결과 Claude Code(Phase 1)에서 Raindrop에 접근할 필요가 없음:
- Phase 0: 스크립트가 REST API로 목록 조회 → JSON 파일로 전달
- Phase 1: Claude Code는 웹 검색/URL 접근만 수행 (Raindrop 접근 불필요)
- Phase 2: 스크립트가 REST API로 이동/태그/노트 처리

따라서 **MCP 서버는 이 파이프라인에서 사용하지 않음**. `scripts/lib/raindrop-api.sh`에서 `curl` + `jq`로 Raindrop REST API를 직접 호출.

### Raindrop REST API 사용
- **인증**: `RAINDROP_TEST_TOKEN` 환경변수 (만료 없음)
- **Base URL**: `https://api.raindrop.io/rest/v1`
- **무료 티어 호환**: 모든 필수 오퍼레이션 사용 가능
- **Rate limit**: 120req/분 (요청 간 0.5초 sleep)
- **페이지네이션**: Unsorted 조회 시 페이지당 최대 50개, 전체 순회 필요 (N4)

### 향후 MCP 활용 가능성
로컬 개발/디버깅 시 `adeze/raindrop-mcp`(★135, v2.4.5)를 Claude Code MCP로 연결하여 인터랙티브하게 사용할 수 있음. CI 파이프라인에서는 불필요.

---

## 11. 에러 처리

### 배치 레벨
- 배치 실패 → 해당 배치 스킵, 나머지 계속 처리
- 실패 배치의 북마크는 Unsorted에 남아 다음 실행에서 재처리

### 개별 북마크 레벨
| 상황 | 처리 |
|------|------|
| Raindrop API 호출 실패 | 해당 북마크 스킵, 로그 기록 |
| Claude Code 잘못된 JSON | 배치 전체 스킵 (`--output-format json`으로 위험 최소화) |
| Raindrop rate limit (120req/분) | 요청 간 0.5초 sleep |
| Claude Code rate limit | 배치 간 대기, 실패 시 다음 실행으로 이월 |
| git push 실패 | Actions 실패 알림 |
| 변경사항 없음 | `git diff --cached --quiet`로 확인 후 커밋 스킵 (W10) |

### 중복 URL 처리 (W4, W5)
- `split-batches.sh`에서 중복 URL 사전 제거 (Phase 0)
- 중복된 북마크 중 첫 번째만 배치에 포함, 나머지는 스킵 로그 기록
- 중복 URL을 "검증실패"로 처리하지 않음 (삭제 의도 아님) → Unsorted에 유지

### 멱등성
- Unsorted에 있다 = 미처리
- 처리 완료 즉시 컬렉션 이동 → 중복 처리 방지
- 동시 실행 방지: `concurrency` 설정으로 워크플로우 중복 실행 차단 (N2)

---

## 12. GitHub Pages

- **소스**: GitHub Actions에서 자동 배포
- **트리거**: `reports/` 변경 시
- **렌더링**: Jekyll 기본 (마크다운 → HTML)
- **URL**: `https://inchan.github.io/reading-list/reports/YYYY-MM-DD/<slug>`

---

## 부록: 결정 로그

| # | 질문 | 결정 |
|---|------|------|
| Q1 | 소스 컬렉션 | Unsorted (컬렉션 이동 = 처리 완료 시그널) |
| Q2 | 핵심 가치 | 큐레이션 + 지식 아카이브 |
| Q3 | 검증 기준 | 실체 검증 (substance verification) |
| Q4 | 분류 체계 | 컬렉션(대분류) + 태그(세부) |
| Q5 | 컬렉션 생성 | 고정 목록 + GitHub Issue로 제안 |
| Q6 | 보고서 형식 | 개별 파일 + 일별 인덱스 |
| Q7 | 트리거 | cron + 수동 |
| Q8 | AI 런타임 | Claude Code 기본 + 추상화 레이어 |
| Q9 | MCP 서버 | adeze/raindrop-mcp v2.4.5 |
| Q10 | 검증 실패 처리 | 검증실패 컬렉션 격리 → 10일 후 휴지통 |
| Q11 | 보고서 URL | GitHub Pages |
| Q12 | 스케줄 | 매일 1회 (09:00 KST) |
| Q13 | 보고서 구조 | frontmatter + 요약/인사이트/검증결과/관련링크 |
| Q14 | 접근 방식 | Claude Code 단일 프롬프트 + 스크립트 하이브리드 |
| Q15 | 배치 초과 | 배치 분할 (20개/배치) |
| Q16 | 프롬프트 검증 | Codex(gpt-5.4) 리뷰 → 6가지 지적 반영 완료 |

---

## 부록: 스펙 리뷰 반영 사항

| ID | 등급 | 문제 | 해결 |
|----|------|------|------|
| B1 | BLOCKER | CLI 플래그 오류 | `claude` + stdin pipe + `--output-format json` + stdout 리다이렉션 |
| B2 | BLOCKER | 도구 권한 누락 | `--dangerously-skip-permissions` 추가 |
| B3 | BLOCKER | MCP 역할 불명확 | MCP 미사용으로 결정, REST API 직접 호출 |
| B4 | BLOCKER | 컬렉션 미매칭 처리 미정 | Unsorted 유지 + `#대기중` 태그 + 보고서 생성 + Issue |
| W1 | WARNING | 플레이스홀더 치환 | stdin pipe로 전달, 프롬프트에서 제거 |
| W2 | WARNING | JSON 파싱 불안정 | `--output-format json` 사용 |
| W4 | WARNING | 중복 URL 처리 | 중복은 스킵, 검증실패로 처리하지 않음 |
| W5 | WARNING | 배치 간 중복 | `split-batches.sh`에서 사전 제거 |
| W6 | WARNING | slug 규칙 미정 | URL 기반 생성, 최대 60자, 중복시 접미사 |
| W7 | WARNING | YAML frontmatter | 모든 문자열 값에 따옴표 추가 |
| W9 | WARNING | 검증실패 컬렉션 | `setup.sh`에서 자동 생성 |
| W10 | WARNING | 빈 커밋 실패 | `git diff --cached --quiet` 체크 |
| N2 | NOTE | 동시 실행 | `concurrency` 설정 추가 |
| N3 | NOTE | 주장 없는 글 | passed 처리, claims 빈 배열 |
| N4 | NOTE | 페이지네이션 | `fetch-unsorted.sh`에서 전체 순회 |
| N6 | NOTE | settings.json | 전체 필드 명세 추가 |
| N7 | NOTE | Issue 형식 | 라벨 + 템플릿 정의 |

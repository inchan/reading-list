# Reading List Pipeline — 설계 문서

> **상태**: 설계 확정
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
- Phase 0, 2, 3은 결정론적 → bash 스크립트
- Phase 1만 AI 판단 → Claude Code
- Phase 간 데이터 전달은 JSON 파일

### 배치 분할
- 1배치 = 최대 20개 북마크
- 20개 초과 시 자동으로 배치 분할 후 순차 처리
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

### 검증 실패 처리
1. 검증 실패 → `검증실패` 컬렉션으로 이동
2. 10일 경과 → 자동으로 휴지통 이동 (매일 Phase 0에서 실행)
3. 10일 내 사용자가 확인하고 복구 가능

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

### 개별 보고서: `reports/YYYY-MM-DD/<slug>.md`

```markdown
---
title: Some Article Title
url: https://example.com/article
date: 2026-03-21
collection: Frontend
tags: [react, server-components, 성능최적화]
verification: passed
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
│   ├── fetch-unsorted.sh            # Phase 0: unsorted 가져오기
│   ├── cleanup-quarantine.sh        # Phase 0: 10일 경과 → 휴지통
│   ├── split-batches.sh             # Phase 0→1: 배치 분할
│   ├── apply-results.sh             # Phase 2: Raindrop API 호출
│   ├── generate-reports.sh          # Phase 2: 보고서 마크다운 생성
│   ├── generate-index.sh            # Phase 2: 일별 인덱스 생성
│   └── lib/
│       └── raindrop-api.sh          # 공통 Raindrop API 헬퍼
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
│   ├── collections.json             # 컬렉션 매핑 캐시
│   └── settings.json                # 설정
│
└── docs/
    └── superpowers/specs/           # 설계 문서
```

---

## 8. GitHub Actions 워크플로우

```yaml
name: Process Reading List
on:
  schedule:
    - cron: '0 0 * * *'              # 매일 00:00 UTC (09:00 KST)
  workflow_dispatch:

jobs:
  process:
    runs-on: ubuntu-latest
    steps:
      - checkout
      - setup (jq 등)

      # Phase 0
      - run: scripts/cleanup-quarantine.sh
      - run: scripts/fetch-unsorted.sh
      - run: scripts/split-batches.sh

      # Phase 1 + 2 배치 루프
      - run: |
          for batch in tmp/batch_*.json; do
            claude-code --print \
              --system-prompt prompts/analyze-bookmarks.md \
              --input "$batch" \
              --output "tmp/result_$(basename $batch)"
            scripts/apply-results.sh "tmp/result_$(basename $batch)"
          done

      # Phase 2 마무리
      - run: scripts/generate-index.sh
      - run: |
          git add reports/
          git commit -m "report: $(date +%Y-%m-%d) 처리 결과"
          git push
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

## 10. Raindrop MCP 서버

- **사용**: `adeze/raindrop-mcp` (★135, v2.4.5, MIT)
- **모드**: STDIO만 사용 (HTTP 모드 비사용)
- **버전 고정**: `npx @adeze/raindrop-mcp@2.4.5`
- **인증**: `RAINDROP_TEST_TOKEN` 환경변수
- **무료 티어 호환**: Raindrop 무료 티어 API에서 모든 필수 오퍼레이션 사용 가능
- **참고**: Phase 0/2 스크립트에서는 MCP 없이 Raindrop REST API를 직접 호출할 수도 있음

---

## 11. 에러 처리

### 배치 레벨
- 배치 실패 → 해당 배치 스킵, 나머지 계속 처리
- 실패 배치의 북마크는 Unsorted에 남아 다음 실행에서 재처리

### 개별 북마크 레벨
| 상황 | 처리 |
|------|------|
| Raindrop API 호출 실패 | 해당 북마크 스킵, 로그 기록 |
| Claude Code 잘못된 JSON | 배치 전체 스킵 |
| Rate limit (120req/분) | 요청 간 0.5초 sleep |
| git push 실패 | Actions 실패 알림 |

### 멱등성
- Unsorted에 있다 = 미처리
- 처리 완료 즉시 컬렉션 이동 → 중복 처리 방지

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

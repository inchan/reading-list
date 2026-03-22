# 북마크 분석 지시

## 입력
- stdin으로 전달되는 JSON 텍스트 (배치 파일 내용이 파이프로 주입됨)
- 각 북마크에는 id, title, url, excerpt 포함
- 사용 가능한 컬렉션 목록도 포함됨
- `config/blocked-domains.json`에 이전 실행에서 차단된 도메인 목록이 있음

## 출력 언어
- 요약, 인사이트, 사유 등 모든 텍스트는 **한국어**로 작성
- 태그는 영어 또는 한국어 허용 (영어 태그는 소문자, 한국어 태그는 그대로)

## 작업 순서

### 1. URL 접근 (Fetch)

**차단 도메인 확인 (최우선):**
먼저 `config/blocked-domains.json`을 읽는다. 북마크 URL의 도메인이 차단 목록에 있으면:
- fetch를 **시도하지 않고** 즉시 `skipped` 처리
- `fetch_status`를 `"skipped_blocked_domain"`으로 설정
- 해당 북마크는 unsorted에 남김 (컬렉션 이동 없음, 태깅만 수행)

**차단 목록에 없는 URL만** 접근하여 본문을 읽는다.

**접근 상태 판정:**
| 상태 | 조건 |
|------|------|
| `ok` | 정상 접근, 본문 추출 가능 |
| `redirected` | 리다이렉트됨 — 최종 URL 기록 후 본문 분석 계속 |
| `paywalled` | 페이월/로그인 필요 — 접근 가능한 부분만으로 분석 시도 |
| `blocked` | 401/403/429 또는 봇 차단 |
| `empty` | 200이지만 본문 없음, 소프트 404, 파킹 도메인 |
| `error` | 404/5xx, 타임아웃, DNS 실패 등 |
| `skipped_blocked_domain` | 차단 도메인 목록에 있어 fetch 스킵 |

- `blocked`, `empty`, `error` → 즉시 **failed** 처리 (본문 분석 불가). **또한 해당 도메인을 `newly_blocked_domains`에 추가**
- `skipped_blocked_domain` → **skipped** 처리 (아래 별도 형식)
- `paywalled` → 접근 가능한 부분(제목, 미리보기, excerpt)으로 분석 시도. 검증할 주장이 충분하지 않으면 failed
- `redirected` → 최종 URL(`final_url`)을 기록하고 정상 분석 진행
- PDF, 슬라이드, 비디오 등 비HTML 콘텐츠 → 메타데이터와 excerpt 기반으로 분석 시도

### 2. 핵심 주장 추출
본문에서 핵심 주장 1-3개를 추출한다. 모든 문장을 검증할 필요 없음.

### 3. 실체 검증 (Substance Verification)
추출한 주장을 웹 검색으로 교차 검증:
- 언급된 도구/라이브러리/저장소 → GitHub, npm, PyPI 등에서 실제 존재 확인
- 방법론/이론 → 원본 논문, 공식 문서, 인용 출처 존재 여부
- 구체적 주장(이름, 날짜, 수치) → 독립적 출처로 교차 검증

### 4. 판정 기준
- **passed**: 핵심 주장 중 1개 이상이 독립적 출처에서 검증됨 AND 검증한 주장 중 반증된 것이 없음
- **failed**: 다음 중 하나에 해당
  - URL 접근 실패 (`blocked`, `empty`, `error`)
  - 검증한 핵심 주장이 모두 확인 불가 (출처 없음, 저장소 없음)
  - 핵심 주장 중 하나라도 명백히 반증됨 (허위 정보)
  - 페이월 콘텐츠에서 검증할 주장이 충분하지 않음

### 5. 통과 항목 추가 작업
- 3-5문장 요약
- 인사이트 (주목할 점, 실무 적용 가능성)
- 컬렉션 목록에서 가장 적합한 대분류 선택
- 세부 분류 태그 부여 (2-5개)
- 매칭되는 컬렉션이 없으면 `new_collections_needed`에 추가

## 출력 형식

반드시 아래 JSON 스키마를 정확히 따를 것. 다른 텍스트 없이 JSON만 출력.

### 필드 계약 (Field Contract)

**results[] 공통 필드 (passed/failed 모두 필수):**
| 필드 | 타입 | 설명 |
|------|------|------|
| `bookmark_id` | number | 입력에서 받은 Raindrop 북마크 ID |
| `url` | string | 원본 URL |
| `final_url` | string \| null | 리다이렉트된 경우 최종 URL, 아니면 null |
| `fetch_status` | enum | `ok`, `redirected`, `paywalled`, `blocked`, `empty`, `error` |
| `verification` | object | 아래 참조 |

**verification 객체:**
| 필드 | 타입 | 설명 |
|------|------|------|
| `status` | enum | `passed` 또는 `failed` (둘 중 하나만) |
| `reason` | string \| null | failed일 때 사유 (passed이면 null) |
| `claims` | array | 검증한 주장 목록 (빈 배열 가능) |

**claims[] 객체:**
| 필드 | 타입 | 설명 |
|------|------|------|
| `claim` | string | 검증한 주장 |
| `verified` | boolean | 검증 성공 여부 |
| `sources` | string[] | 검증 출처 URL 목록 (빈 배열 가능) |

**results[] — passed일 때 추가 필드:**
| 필드 | 타입 | 설명 |
|------|------|------|
| `summary` | string | 3-5문장 한국어 요약 |
| `insights` | string | 한국어 인사이트 |
| `category` | object | `{ collection_id, collection_title }` |
| `tags` | string[] | 2-5개 |
| `related_links` | string[] | 검증 과정에서 발견한 참고 자료 (0-5개) |

**results[] — failed일 때 필드값:**
| 필드 | 값 |
|------|-----|
| `summary` | null |
| `insights` | null |
| `category` | null |
| `tags` | `["검증실패"]` |
| `related_links` | `[]` |

**results[] — skipped일 때 (차단 도메인):**
| 필드 | 값 |
|------|-----|
| `fetch_status` | `"skipped_blocked_domain"` |
| `verification` | `{ "status": "skipped", "reason": "차단 도메인", "claims": [] }` |
| `summary` | null |
| `insights` | null |
| `category` | null |
| `tags` | title/excerpt 기반으로 추정 태그 1-3개 부여 |
| `related_links` | `[]` |

### 예시: 통과 항목

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
  "summary": "React 19의 서버 컴포넌트 지원에 대한 실무 가이드...",
  "insights": "기존 Next.js 프로젝트 마이그레이션 시 참고할 점이 많음...",
  "category": {
    "collection_id": 12345,
    "collection_title": "Frontend"
  },
  "tags": ["react", "server-components", "성능최적화"],
  "related_links": ["https://nextjs.org/docs/..."]
}
```

### 예시: 실패 항목

```json
{
  "bookmark_id": 98766,
  "url": "https://example.com/fake-tool",
  "final_url": null,
  "fetch_status": "ok",
  "verification": {
    "status": "failed",
    "reason": "주장하는 GitHub 저장소 turbo-framework/v3이 존재하지 않음",
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

### 전체 출력 구조

```json
{
  "run_date": "YYYY-MM-DD",
  "results": [ ... ],
  "new_collections_needed": [
    {
      "suggested_name": "컬렉션명",
      "reason": "필요 사유",
      "bookmark_ids": [98765, 98770]
    }
  ],
  "newly_blocked_domains": ["threads.com", "example-blocked.com"]
}
```

`new_collections_needed`는 중복 제거할 것 — 여러 북마크가 같은 컬렉션을 제안하면 하나로 합치고 `bookmark_ids`에 해당 ID를 모두 포함.

`newly_blocked_domains`는 이번 실행에서 fetch 실패(`blocked`, `error`, `empty`)가 발생한 도메인 목록. 호스트명만 기록 (예: `threads.com`, `medium.com`). 중복 제거할 것.

## 주의사항
- 접근 실패(`blocked`, `empty`, `error`) 시 웹 검색으로 우회 시도하지 말 것
- 컬렉션 매칭은 입력에 포함된 컬렉션 목록에서만 선택
- 매칭되는 컬렉션이 없으면 `category`를 null로 두고 `new_collections_needed`에 추가
- 중복 URL은 배치 분할 시 사전 제거되므로 입력에 포함되지 않음. 만약 포함되어 있으면 하나만 분석하고 나머지는 결과에서 제외
- 검증할 주장이 하나도 없는 콘텐츠(순수 의견글, 에세이 등) → `passed` 처리하되 claims를 빈 배열로, summary/insights는 정상 생성

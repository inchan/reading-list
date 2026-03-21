# Reading List Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** GitHub Actions + Claude Code + Raindrop REST API로 북마크 자동 큐레이션/지식 아카이브 파이프라인 구현

**Architecture:** bash 스크립트가 Raindrop REST API를 직접 호출하여 데이터 수집/적용(Phase 0, 2)하고, Claude Code가 실체 검증+요약 생성(Phase 1)을 담당하는 하이브리드 파이프라인. JSON 파일로 Phase 간 데이터 전달. GitHub Pages로 보고서 배포.

**Tech Stack:** Bash, jq, curl, GitHub Actions, Claude Code CLI, Jekyll (GitHub Pages)

**Spec:** `docs/superpowers/specs/2026-03-21-reading-list-pipeline-design.md`

---

## File Structure

| 파일 | 책임 | 생성/수정 |
|------|------|-----------|
| `config/settings.json` | 파이프라인 설정값 | Create |
| `.gitignore` | tmp/ 등 무시 패턴 | Create |
| `scripts/lib/raindrop-api.sh` | Raindrop REST API 헬퍼 (인증, 요청, 페이지네이션, rate limit) | Create |
| `scripts/setup.sh` | 초기 셋업 (검증실패 컬렉션 생성) | Create |
| `scripts/fetch-unsorted.sh` | Unsorted 북마크 조회 → tmp/input.json | Create |
| `scripts/cleanup-quarantine.sh` | 10일 경과 검증실패 항목 → 휴지통 | Create |
| `scripts/split-batches.sh` | input.json → batch_NNN.json (중복 URL 제거) | Create |
| `scripts/apply-results.sh` | result JSON → Raindrop API 호출 + 보고서 생성 | Create |
| `scripts/generate-reports.sh` | result JSON → 개별 마크다운 보고서 | Create |
| `scripts/generate-index.sh` | 일별 인덱스 생성 | Create |
| `prompts/analyze-bookmarks.md` | Claude Code 프롬프트 | 이미 존재 |
| `.github/workflows/process-bookmarks.yml` | 메인 워크플로우 | Create |
| `.github/workflows/deploy-pages.yml` | GitHub Pages 배포 | Create |
| `tests/test_raindrop_api.bats` | API 헬퍼 테스트 | Create |
| `tests/test_split_batches.bats` | 배치 분할 테스트 | Create |
| `tests/test_generate_reports.bats` | 보고서 생성 테스트 | Create |
| `tests/fixtures/` | 테스트 픽스처 JSON | Create |

---

## Task 1: 프로젝트 스캐폴딩

**Files:**
- Create: `config/settings.json`
- Create: `.gitignore`
- Create: `tests/fixtures/input_sample.json`
- Create: `tests/fixtures/result_passed.json`
- Create: `tests/fixtures/result_failed.json`
- Create: `tests/fixtures/result_mixed.json`

- [ ] **Step 1: config/settings.json 생성**

```json
{
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

- [ ] **Step 2: .gitignore 생성**

```
tmp/
.env
*.log
node_modules/
.DS_Store
```

- [ ] **Step 3: 테스트 픽스처 생성**

`tests/fixtures/input_sample.json`:
```json
{
  "run_date": "2026-03-21",
  "collections": [
    { "id": 12345, "title": "Frontend", "parent_id": null },
    { "id": 12346, "title": "Backend", "parent_id": null },
    { "id": 12347, "title": "DevOps", "parent_id": null }
  ],
  "bookmarks": [
    {
      "id": 98765,
      "title": "React 19 Server Components Guide",
      "url": "https://example.com/react-19-guide",
      "excerpt": "A comprehensive guide to React 19...",
      "created": "2026-03-20T14:30:00Z",
      "tags": [],
      "type": "link"
    },
    {
      "id": 98766,
      "title": "Fake Framework Release",
      "url": "https://example.com/fake-framework",
      "excerpt": "Introducing turbo-framework v3.0...",
      "created": "2026-03-20T15:00:00Z",
      "tags": [],
      "type": "link"
    },
    {
      "id": 98767,
      "title": "Duplicate Article",
      "url": "https://example.com/react-19-guide",
      "excerpt": "Same URL as first bookmark...",
      "created": "2026-03-20T16:00:00Z",
      "tags": [],
      "type": "link"
    }
  ]
}
```

`tests/fixtures/result_passed.json`:
```json
{
  "run_date": "2026-03-21",
  "results": [
    {
      "bookmark_id": 98765,
      "url": "https://example.com/react-19-guide",
      "final_url": null,
      "fetch_status": "ok",
      "verification": {
        "status": "passed",
        "reason": null,
        "claims": [
          {
            "claim": "React 19에서 서버 컴포넌트가 기본 지원됨",
            "verified": true,
            "sources": ["https://react.dev/blog/react-19"]
          }
        ]
      },
      "summary": "React 19의 서버 컴포넌트 지원에 대한 실무 가이드. RSC가 기본 활성화되며 기존 클라이언트 컴포넌트와의 공존 전략을 설명한다.",
      "insights": "Next.js 프로젝트에서 점진적 마이그레이션이 가능하므로, 신규 페이지부터 서버 컴포넌트를 적용하면 된다.",
      "category": {
        "collection_id": 12345,
        "collection_title": "Frontend"
      },
      "tags": ["react", "server-components", "성능최적화"],
      "related_links": ["https://nextjs.org/docs/app/building-your-application/rendering"]
    }
  ],
  "new_collections_needed": []
}
```

`tests/fixtures/result_failed.json`:
```json
{
  "run_date": "2026-03-21",
  "results": [
    {
      "bookmark_id": 98766,
      "url": "https://example.com/fake-framework",
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
  ],
  "new_collections_needed": []
}
```

`tests/fixtures/result_mixed.json` — passed + failed + new_collection_needed:
```json
{
  "run_date": "2026-03-21",
  "results": [
    {
      "bookmark_id": 98765,
      "url": "https://example.com/react-19-guide",
      "final_url": null,
      "fetch_status": "ok",
      "verification": { "status": "passed", "reason": null, "claims": [] },
      "summary": "React 19 요약",
      "insights": "React 19 인사이트",
      "category": { "collection_id": 12345, "collection_title": "Frontend" },
      "tags": ["react"],
      "related_links": []
    },
    {
      "bookmark_id": 98766,
      "url": "https://example.com/fake-framework",
      "final_url": null,
      "fetch_status": "ok",
      "verification": { "status": "failed", "reason": "저장소 없음", "claims": [] },
      "summary": null,
      "insights": null,
      "category": null,
      "tags": ["검증실패"],
      "related_links": []
    },
    {
      "bookmark_id": 98768,
      "url": "https://example.com/mlops-guide",
      "final_url": null,
      "fetch_status": "ok",
      "verification": { "status": "passed", "reason": null, "claims": [] },
      "summary": "MLOps 가이드 요약",
      "insights": "MLOps 인사이트",
      "category": null,
      "tags": ["mlops", "머신러닝"],
      "related_links": []
    }
  ],
  "new_collections_needed": [
    {
      "suggested_name": "MLOps",
      "reason": "ML 운영 관련 컬렉션 없음",
      "bookmark_ids": [98768]
    }
  ]
}
```

- [ ] **Step 4: 디렉토리 구조 생성**

```bash
mkdir -p scripts/lib tests/fixtures tmp reports .github/workflows
```

- [ ] **Step 5: bats-core 설치 확인**

```bash
# macOS
brew install bats-core
# 또는 GitHub Actions에서
# sudo apt-get install bats
```

- [ ] **Step 6: 커밋**

```bash
git add config/settings.json .gitignore tests/fixtures/
git commit -m "chore: 프로젝트 스캐폴딩 - 설정, gitignore, 테스트 픽스처"
```

---

## Task 2: Raindrop API 헬퍼 라이브러리

**Files:**
- Create: `scripts/lib/raindrop-api.sh`
- Create: `tests/test_raindrop_api.bats`

- [ ] **Step 1: 테스트 작성**

`tests/test_raindrop_api.bats`:
```bash
#!/usr/bin/env bats

setup() {
  source scripts/lib/raindrop-api.sh
  export RAINDROP_TEST_TOKEN="test-token-123"
}

@test "raindrop_auth_header returns correct header" {
  result=$(raindrop_auth_header)
  [ "$result" = "Authorization: Bearer test-token-123" ]
}

@test "raindrop_api_base returns configured URL" {
  result=$(raindrop_api_base)
  [ "$result" = "https://api.raindrop.io/rest/v1" ]
}

@test "slugify converts title to valid slug" {
  result=$(slugify "React 19: Server Components Guide!")
  [ "$result" = "react-19-server-components-guide" ]
}

@test "slugify truncates to max length" {
  long_title="This is a very long title that should be truncated to sixty characters maximum for slug"
  result=$(slugify "$long_title")
  [ ${#result} -le 60 ]
}

@test "slugify handles Korean characters" {
  result=$(slugify "리액트 19 서버 컴포넌트 가이드")
  [ "$result" = "리액트-19-서버-컴포넌트-가이드" ]
}

@test "load_settings reads config correctly" {
  load_settings
  [ "$QUARANTINE_DAYS" = "10" ]
  [ "$MAX_PER_BATCH" = "20" ]
  [ "$PAGES_BASE_URL" = "https://inchan.github.io/reading-list" ]
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
bats tests/test_raindrop_api.bats
```
Expected: FAIL (source 파일 없음)

- [ ] **Step 3: raindrop-api.sh 구현**

`scripts/lib/raindrop-api.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../../config/settings.json"

# --- 설정 로드 ---
load_settings() {
  QUARANTINE_DAYS=$(jq -r '.quarantine_days' "$CONFIG_FILE")
  QUARANTINE_COLLECTION_NAME=$(jq -r '.quarantine_collection_name' "$CONFIG_FILE")
  MAX_PER_BATCH=$(jq -r '.max_bookmarks_per_batch' "$CONFIG_FILE")
  PAGES_BASE_URL=$(jq -r '.pages_base_url' "$CONFIG_FILE")
  API_BASE=$(jq -r '.raindrop_api_base' "$CONFIG_FILE")
  API_DELAY_MS=$(jq -r '.raindrop_api_delay_ms' "$CONFIG_FILE")
  SLUG_MAX_LENGTH=$(jq -r '.slug_max_length' "$CONFIG_FILE")
  ISSUE_LABELS=$(jq -r '.issue_labels | join(",")' "$CONFIG_FILE")
}

# --- 인증 ---
raindrop_auth_header() {
  echo "Authorization: Bearer ${RAINDROP_TEST_TOKEN}"
}

raindrop_api_base() {
  if [ -n "${API_BASE:-}" ]; then
    echo "$API_BASE"
  else
    echo "https://api.raindrop.io/rest/v1"
  fi
}

# --- API 호출 (rate limit 대응) ---
raindrop_get() {
  local endpoint="$1"
  local base
  base=$(raindrop_api_base)
  local delay_s
  delay_s=$(echo "${API_DELAY_MS:-500}" | awk '{printf "%.1f", $1/1000}')

  sleep "$delay_s"
  curl -s -f \
    -H "$(raindrop_auth_header)" \
    -H "Content-Type: application/json" \
    "${base}${endpoint}"
}

raindrop_put() {
  local endpoint="$1"
  local data="$2"
  local base
  base=$(raindrop_api_base)
  local delay_s
  delay_s=$(echo "${API_DELAY_MS:-500}" | awk '{printf "%.1f", $1/1000}')

  sleep "$delay_s"
  curl -s -f -X PUT \
    -H "$(raindrop_auth_header)" \
    -H "Content-Type: application/json" \
    -d "$data" \
    "${base}${endpoint}"
}

raindrop_post() {
  local endpoint="$1"
  local data="$2"
  local base
  base=$(raindrop_api_base)
  local delay_s
  delay_s=$(echo "${API_DELAY_MS:-500}" | awk '{printf "%.1f", $1/1000}')

  sleep "$delay_s"
  curl -s -f -X POST \
    -H "$(raindrop_auth_header)" \
    -H "Content-Type: application/json" \
    -d "$data" \
    "${base}${endpoint}"
}

raindrop_delete() {
  local endpoint="$1"
  local base
  base=$(raindrop_api_base)
  local delay_s
  delay_s=$(echo "${API_DELAY_MS:-500}" | awk '{printf "%.1f", $1/1000}')

  sleep "$delay_s"
  curl -s -f -X DELETE \
    -H "$(raindrop_auth_header)" \
    -H "Content-Type: application/json" \
    "${base}${endpoint}"
}

# --- 페이지네이션 조회 ---
raindrop_get_all_pages() {
  local endpoint="$1"
  local page=0
  local all_items="[]"

  while true; do
    local response
    response=$(raindrop_get "${endpoint}?page=${page}&perpage=50") || break

    local items
    items=$(echo "$response" | jq '.items // []')
    local count
    count=$(echo "$items" | jq 'length')

    if [ "$count" -eq 0 ]; then
      break
    fi

    all_items=$(echo "$all_items" "$items" | jq -s '.[0] + .[1]')
    page=$((page + 1))
  done

  echo "$all_items"
}

# --- Slug 생성 ---
slugify() {
  local title="$1"
  local max_len="${SLUG_MAX_LENGTH:-60}"

  echo "$title" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9가-힣ㄱ-ㅎㅏ-ㅣ ]/-/g' \
    | sed 's/  */-/g' \
    | sed 's/--*/-/g' \
    | sed 's/^-//;s/-$//' \
    | cut -c1-"$max_len" \
    | sed 's/-$//'
}

# --- 로그 ---
log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $*"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
log_warn() { echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }
```

- [ ] **Step 4: 테스트 실행 → 통과 확인**

```bash
bats tests/test_raindrop_api.bats
```
Expected: 6 tests, all passing

- [ ] **Step 5: 커밋**

```bash
git add scripts/lib/raindrop-api.sh tests/test_raindrop_api.bats
git commit -m "feat: Raindrop API 헬퍼 라이브러리 + 테스트"
```

---

## Task 3: setup.sh — 초기 셋업 스크립트

**Files:**
- Create: `scripts/setup.sh`

- [ ] **Step 1: setup.sh 구현**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

log_info "초기 셋업 시작"

# 검증실패 컬렉션 존재 여부 확인
collections=$(raindrop_get "/collections") || { log_error "컬렉션 목록 조회 실패"; exit 1; }

quarantine_id=$(echo "$collections" | jq -r --arg name "$QUARANTINE_COLLECTION_NAME" \
  '.items[] | select(.title == $name) | ._id // empty')

if [ -z "$quarantine_id" ]; then
  log_info "\"$QUARANTINE_COLLECTION_NAME\" 컬렉션 생성 중..."
  result=$(raindrop_post "/collection" \
    "{\"title\": \"$QUARANTINE_COLLECTION_NAME\"}") || { log_error "컬렉션 생성 실패"; exit 1; }
  quarantine_id=$(echo "$result" | jq -r '.item._id')
  log_info "컬렉션 생성 완료: ID=$quarantine_id"
else
  log_info "\"$QUARANTINE_COLLECTION_NAME\" 컬렉션 이미 존재: ID=$quarantine_id"
fi

log_info "초기 셋업 완료"
```

- [ ] **Step 2: 실행 권한 부여**

```bash
chmod +x scripts/setup.sh
```

- [ ] **Step 3: 커밋**

```bash
git add scripts/setup.sh
git commit -m "feat: 초기 셋업 스크립트 (검증실패 컬렉션 자동 생성)"
```

---

## Task 4: fetch-unsorted.sh — Unsorted 북마크 조회

**Files:**
- Create: `scripts/fetch-unsorted.sh`

- [ ] **Step 1: fetch-unsorted.sh 구현**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

log_info "Unsorted 북마크 조회 시작"

# 컬렉션 목록 조회
collections_raw=$(raindrop_get "/collections") || { log_error "컬렉션 조회 실패"; exit 1; }
collections=$(echo "$collections_raw" | jq '[.items[] | {id: ._id, title: .title, parent_id: .parent_id}]')

# Unsorted 북마크 조회 (collection_id = -1, 페이지네이션)
bookmarks=$(raindrop_get_all_pages "/raindrops/-1")
bookmark_count=$(echo "$bookmarks" | jq 'length')
log_info "Unsorted 북마크 ${bookmark_count}개 조회됨"

if [ "$bookmark_count" -eq 0 ]; then
  log_info "처리할 북마크 없음"
  echo '{"run_date":"'"$(date +%Y-%m-%d)"'","collections":[],"bookmarks":[]}' > tmp/input.json
  exit 0
fi

# #대기중 태그가 붙은 항목 제외 (이전 실행에서 컬렉션 미매칭으로 대기 중인 항목)
bookmarks=$(echo "$bookmarks" | jq '[.[] | select(.tags | index("대기중") | not)]')
bookmark_count=$(echo "$bookmarks" | jq 'length')
log_info "대기중 태그 제외 후 ${bookmark_count}개"

# input.json 형식으로 변환
input=$(jq -n \
  --arg date "$(date +%Y-%m-%d)" \
  --argjson collections "$collections" \
  --argjson bookmarks "$(echo "$bookmarks" | jq '[.[] | {
    id: ._id,
    title: .title,
    url: .link,
    excerpt: (.excerpt // ""),
    created: .created,
    tags: .tags,
    type: .type
  }]')" \
  '{run_date: $date, collections: $collections, bookmarks: $bookmarks}')

mkdir -p tmp
echo "$input" > tmp/input.json
log_info "tmp/input.json 저장 완료 (${bookmark_count}개 북마크)"

# 컬렉션 캐시 갱신
echo "$collections" > config/collections.json
log_info "config/collections.json 갱신"
```

- [ ] **Step 2: 실행 권한 부여**

```bash
chmod +x scripts/fetch-unsorted.sh
```

- [ ] **Step 3: 커밋**

```bash
git add scripts/fetch-unsorted.sh
git commit -m "feat: Unsorted 북마크 조회 스크립트 (페이지네이션, 대기중 필터)"
```

---

## Task 5: cleanup-quarantine.sh — 검증실패 10일 경과 정리

**Files:**
- Create: `scripts/cleanup-quarantine.sh`

- [ ] **Step 1: cleanup-quarantine.sh 구현**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

log_info "검증실패 컬렉션 정리 시작 (${QUARANTINE_DAYS}일 경과 항목)"

# 검증실패 컬렉션 ID 찾기
collections=$(raindrop_get "/collections") || { log_error "컬렉션 조회 실패"; exit 1; }
quarantine_id=$(echo "$collections" | jq -r --arg name "$QUARANTINE_COLLECTION_NAME" \
  '.items[] | select(.title == $name) | ._id // empty')

if [ -z "$quarantine_id" ]; then
  log_warn "\"$QUARANTINE_COLLECTION_NAME\" 컬렉션 없음. setup.sh 먼저 실행 필요."
  exit 0
fi

# 검증실패 컬렉션의 모든 북마크 조회
bookmarks=$(raindrop_get_all_pages "/raindrops/${quarantine_id}")
total=$(echo "$bookmarks" | jq 'length')
log_info "검증실패 컬렉션: ${total}개 항목"

# 10일 경과 항목 필터
cutoff_date=$(date -u -v-${QUARANTINE_DAYS}d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
  || date -u -d "${QUARANTINE_DAYS} days ago" '+%Y-%m-%dT%H:%M:%SZ')

expired_ids=$(echo "$bookmarks" | jq -r --arg cutoff "$cutoff_date" \
  '[.[] | select(.created < $cutoff) | ._id] | .[]')

expired_count=$(echo "$expired_ids" | grep -c . || true)

if [ "$expired_count" -eq 0 ]; then
  log_info "정리할 항목 없음"
  exit 0
fi

log_info "${expired_count}개 항목 휴지통으로 이동"

# 개별 삭제 (Raindrop API: DELETE = 휴지통 이동)
for id in $expired_ids; do
  raindrop_delete "/raindrop/${id}" || log_warn "삭제 실패: ID=${id}"
done

log_info "정리 완료"
```

- [ ] **Step 2: 실행 권한 부여**

```bash
chmod +x scripts/cleanup-quarantine.sh
```

- [ ] **Step 3: 커밋**

```bash
git add scripts/cleanup-quarantine.sh
git commit -m "feat: 검증실패 10일 경과 항목 휴지통 이동 스크립트"
```

---

## Task 6: split-batches.sh — 배치 분할 + 중복 URL 제거

**Files:**
- Create: `scripts/split-batches.sh`
- Create: `tests/test_split_batches.bats`

- [ ] **Step 1: 테스트 작성**

`tests/test_split_batches.bats`:
```bash
#!/usr/bin/env bats

setup() {
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  mkdir -p tmp
  # input_sample.json에 3개 북마크 (1개 중복 URL)
  cp tests/fixtures/input_sample.json tmp/input.json
}

teardown() {
  rm -f tmp/batch_*.json tmp/input.json
}

@test "removes duplicate URLs" {
  bash scripts/split-batches.sh
  # 3개 중 1개 중복 → 2개만 남아야 함
  total=$(jq '.bookmarks | length' tmp/batch_001.json)
  [ "$total" -eq 2 ]
}

@test "creates batch files with correct naming" {
  bash scripts/split-batches.sh
  [ -f tmp/batch_001.json ]
}

@test "batch includes collections from input" {
  bash scripts/split-batches.sh
  collections=$(jq '.collections | length' tmp/batch_001.json)
  [ "$collections" -eq 3 ]
}

@test "preserves run_date" {
  bash scripts/split-batches.sh
  date=$(jq -r '.run_date' tmp/batch_001.json)
  [ "$date" = "2026-03-21" ]
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
bats tests/test_split_batches.bats
```

- [ ] **Step 3: split-batches.sh 구현**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

INPUT_FILE="tmp/input.json"

if [ ! -f "$INPUT_FILE" ]; then
  log_error "tmp/input.json 없음. fetch-unsorted.sh 먼저 실행 필요."
  exit 1
fi

run_date=$(jq -r '.run_date' "$INPUT_FILE")
collections=$(jq '.collections' "$INPUT_FILE")

# 중복 URL 제거 (첫 번째만 유지)
bookmarks=$(jq '[.bookmarks | group_by(.url) | .[] | .[0]]' "$INPUT_FILE")
original_count=$(jq '.bookmarks | length' "$INPUT_FILE")
deduped_count=$(echo "$bookmarks" | jq 'length')
skipped=$((original_count - deduped_count))

if [ "$skipped" -gt 0 ]; then
  log_warn "중복 URL ${skipped}개 제거됨"
fi

if [ "$deduped_count" -eq 0 ]; then
  log_info "처리할 북마크 없음"
  exit 0
fi

# 배치 분할
batch_num=1
offset=0

while [ "$offset" -lt "$deduped_count" ]; do
  batch_file=$(printf "tmp/batch_%03d.json" "$batch_num")

  echo "$bookmarks" | jq --arg date "$run_date" --argjson cols "$collections" \
    --argjson offset "$offset" --argjson limit "$MAX_PER_BATCH" \
    '{
      run_date: $date,
      collections: $cols,
      bookmarks: .[$offset:$offset+$limit]
    }' > "$batch_file"

  count=$(jq '.bookmarks | length' "$batch_file")
  log_info "배치 ${batch_num}: ${count}개 북마크 → ${batch_file}"

  batch_num=$((batch_num + 1))
  offset=$((offset + MAX_PER_BATCH))
done

log_info "총 $((batch_num - 1))개 배치 생성 완료"
```

- [ ] **Step 4: 실행 권한 부여**

```bash
chmod +x scripts/split-batches.sh
```

- [ ] **Step 5: 테스트 실행 → 통과 확인**

```bash
bats tests/test_split_batches.bats
```
Expected: 4 tests, all passing

- [ ] **Step 6: 커밋**

```bash
git add scripts/split-batches.sh tests/test_split_batches.bats
git commit -m "feat: 배치 분할 스크립트 (중복 URL 제거) + 테스트"
```

---

## Task 7: generate-reports.sh — 보고서 마크다운 생성

**Files:**
- Create: `scripts/generate-reports.sh`
- Create: `tests/test_generate_reports.bats`

- [ ] **Step 1: 테스트 작성**

`tests/test_generate_reports.bats`:
```bash
#!/usr/bin/env bats

setup() {
  export SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  rm -rf reports/2026-03-21
}

teardown() {
  rm -rf reports/2026-03-21
}

@test "generates markdown report for passed item" {
  bash scripts/generate-reports.sh tests/fixtures/result_passed.json
  [ -f "reports/2026-03-21/example-com-react-19-guide.md" ]
}

@test "report contains correct frontmatter" {
  bash scripts/generate-reports.sh tests/fixtures/result_passed.json
  grep -q 'title: "React 19 Server Components Guide"' reports/2026-03-21/example-com-react-19-guide.md
  grep -q 'collection: "Frontend"' reports/2026-03-21/example-com-react-19-guide.md
  grep -q 'verification: "passed"' reports/2026-03-21/example-com-react-19-guide.md
}

@test "skips report generation for failed items" {
  bash scripts/generate-reports.sh tests/fixtures/result_failed.json
  [ ! -d "reports/2026-03-21" ] || [ $(find reports/2026-03-21 -name "*.md" 2>/dev/null | wc -l) -eq 0 ]
}

@test "handles mixed results" {
  bash scripts/generate-reports.sh tests/fixtures/result_mixed.json
  # passed 2개 → 보고서 2개
  count=$(find reports/2026-03-21 -name "*.md" | wc -l)
  [ "$count" -eq 2 ]
}
```

- [ ] **Step 2: 테스트 실행 → 실패 확인**

```bash
bats tests/test_generate_reports.bats
```

- [ ] **Step 3: generate-reports.sh 구현**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

RESULT_FILE="${1:?사용법: generate-reports.sh <result_file>}"

if [ ! -f "$RESULT_FILE" ]; then
  log_error "결과 파일 없음: $RESULT_FILE"
  exit 1
fi

run_date=$(jq -r '.run_date' "$RESULT_FILE")
report_dir="reports/${run_date}"
mkdir -p "$report_dir"

# passed 항목만 보고서 생성
passed_items=$(jq '[.results[] | select(.verification.status == "passed")]' "$RESULT_FILE")
count=$(echo "$passed_items" | jq 'length')

if [ "$count" -eq 0 ]; then
  log_info "보고서 생성할 passed 항목 없음"
  exit 0
fi

log_info "${count}개 보고서 생성 시작"

echo "$passed_items" | jq -c '.[]' | while IFS= read -r item; do
  bookmark_id=$(echo "$item" | jq -r '.bookmark_id')
  title=$(echo "$item" | jq -r '.url' | sed 's|https\?://||;s|/|-|g;s|[?#].*||')
  slug=$(slugify "$title")

  # 중복 slug 처리
  slug_file="${report_dir}/${slug}.md"
  counter=2
  while [ -f "$slug_file" ]; do
    slug_file="${report_dir}/${slug}-${counter}.md"
    counter=$((counter + 1))
  done

  url=$(echo "$item" | jq -r '.url')
  collection=$(echo "$item" | jq -r '.category.collection_title // "미분류"')
  tags=$(echo "$item" | jq -r '.tags | map("\"" + . + "\"") | join(", ")')
  summary=$(echo "$item" | jq -r '.summary')
  insights=$(echo "$item" | jq -r '.insights')
  raindrop_id=$(echo "$item" | jq -r '.bookmark_id')

  # 검증 결과 포매팅
  claims=""
  echo "$item" | jq -c '.verification.claims[]?' | while IFS= read -r claim; do
    claim_text=$(echo "$claim" | jq -r '.claim')
    verified=$(echo "$claim" | jq -r '.verified')
    sources=$(echo "$claim" | jq -r '.sources | join(", ")')
    if [ "$verified" = "true" ]; then
      claims="${claims}- \"${claim_text}\" → ✅ (출처: ${sources})\n"
    else
      claims="${claims}- \"${claim_text}\" → ❌\n"
    fi
    # claims를 임시 파일에 저장 (subshell 문제 우회)
    echo -e "$claims" > "${slug_file}.claims.tmp"
  done

  claims_text=""
  if [ -f "${slug_file}.claims.tmp" ]; then
    claims_text=$(cat "${slug_file}.claims.tmp")
    rm -f "${slug_file}.claims.tmp"
  fi

  # 관련 링크
  related=$(echo "$item" | jq -r '.related_links[]?' | sed 's/^/- /')

  # 원본 제목 가져오기 (input.json에서)
  original_title=$(echo "$item" | jq -r '.url')  # fallback
  # result에는 title이 없으므로 URL 기반

  cat > "$slug_file" << REPORT
---
title: "$(echo "$item" | jq -r '.url | split("/") | last | gsub("-"; " ")')"
url: "${url}"
date: "${run_date}"
collection: "${collection}"
tags: [${tags}]
verification: "passed"
raindrop_id: ${raindrop_id}
---

## 요약
${summary}

## 인사이트
${insights}

## 실체 검증 결과
${claims_text}
## 관련 링크
${related}
REPORT

  log_info "보고서 생성: $(basename "$slug_file")"
done

log_info "보고서 생성 완료"
```

- [ ] **Step 4: 실행 권한 부여**

```bash
chmod +x scripts/generate-reports.sh
```

- [ ] **Step 5: 테스트 실행 → 통과 확인**

```bash
bats tests/test_generate_reports.bats
```

- [ ] **Step 6: 커밋**

```bash
git add scripts/generate-reports.sh tests/test_generate_reports.bats
git commit -m "feat: 보고서 마크다운 생성 스크립트 + 테스트"
```

---

## Task 8: apply-results.sh — Raindrop API 적용

**Files:**
- Create: `scripts/apply-results.sh`

- [ ] **Step 1: apply-results.sh 구현**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

RESULT_FILE="${1:?사용법: apply-results.sh <result_file>}"

if [ ! -f "$RESULT_FILE" ]; then
  log_error "결과 파일 없음: $RESULT_FILE"
  exit 1
fi

run_date=$(jq -r '.run_date' "$RESULT_FILE")

# 검증실패 컬렉션 ID 조회
collections=$(raindrop_get "/collections") || { log_error "컬렉션 조회 실패"; exit 1; }
quarantine_id=$(echo "$collections" | jq -r --arg name "$QUARANTINE_COLLECTION_NAME" \
  '.items[] | select(.title == $name) | ._id // empty')

# 보고서 생성 먼저
bash "$SCRIPT_DIR/generate-reports.sh" "$RESULT_FILE"

# 각 결과 처리
jq -c '.results[]' "$RESULT_FILE" | while IFS= read -r item; do
  bookmark_id=$(echo "$item" | jq -r '.bookmark_id')
  status=$(echo "$item" | jq -r '.verification.status')
  url=$(echo "$item" | jq -r '.url')

  if [ "$status" = "passed" ]; then
    collection_id=$(echo "$item" | jq -r '.category.collection_id // empty')
    tags=$(echo "$item" | jq -c '.tags')

    if [ -n "$collection_id" ]; then
      # 컬렉션 이동 + 태그 + 노트
      slug=$(slugify "$(echo "$url" | sed 's|https\?://||;s|/|-|g;s|[?#].*||')")
      note_url="${PAGES_BASE_URL}/reports/${run_date}/${slug}"

      update_data=$(jq -n \
        --argjson collection_id "$collection_id" \
        --argjson tags "$tags" \
        --arg note "$note_url" \
        '{collection: {"$id": $collection_id}, tags: $tags, note: $note}')

      raindrop_put "/raindrop/${bookmark_id}" "$update_data" \
        && log_info "PASSED: ID=${bookmark_id} → 컬렉션 ${collection_id}" \
        || log_error "이동 실패: ID=${bookmark_id}"
    else
      # 컬렉션 미매칭 → Unsorted 유지 + #대기중 태그
      update_data=$(jq -n --argjson tags '["대기중"]' '{tags: $tags}')
      raindrop_put "/raindrop/${bookmark_id}" "$update_data" \
        && log_info "PENDING: ID=${bookmark_id} → 대기중 태그" \
        || log_error "태그 실패: ID=${bookmark_id}"
    fi

  elif [ "$status" = "failed" ]; then
    if [ -n "$quarantine_id" ]; then
      update_data=$(jq -n \
        --argjson collection_id "$quarantine_id" \
        --argjson tags '["검증실패"]' \
        '{collection: {"$id": $collection_id}, tags: $tags}')

      raindrop_put "/raindrop/${bookmark_id}" "$update_data" \
        && log_info "FAILED: ID=${bookmark_id} → 검증실패 컬렉션" \
        || log_error "이동 실패: ID=${bookmark_id}"
    else
      log_warn "검증실패 컬렉션 없음. ID=${bookmark_id} 스킵."
    fi
  fi
done

# 새 컬렉션 필요 시 GitHub Issue 생성
new_collections=$(jq -c '.new_collections_needed[]?' "$RESULT_FILE")
if [ -n "$new_collections" ]; then
  echo "$new_collections" | while IFS= read -r nc; do
    name=$(echo "$nc" | jq -r '.suggested_name')
    reason=$(echo "$nc" | jq -r '.reason')
    ids=$(echo "$nc" | jq -r '.bookmark_ids | map(tostring) | join(", #")')

    gh issue create \
      --title "[컬렉션 제안] ${name}" \
      --label "$ISSUE_LABELS" \
      --body "$(cat <<ISSUE_BODY
## 제안 컬렉션: ${name}
**사유**: ${reason}
**관련 북마크 ID**: #${ids}
**처리일**: ${run_date}
ISSUE_BODY
)" \
      && log_info "Issue 생성: [컬렉션 제안] ${name}" \
      || log_error "Issue 생성 실패: ${name}"
  done
fi

log_info "결과 적용 완료"
```

- [ ] **Step 2: 실행 권한 부여**

```bash
chmod +x scripts/apply-results.sh
```

- [ ] **Step 3: 커밋**

```bash
git add scripts/apply-results.sh
git commit -m "feat: 결과 적용 스크립트 (Raindrop 이동/태그/노트 + Issue 생성)"
```

---

## Task 9: generate-index.sh — 일별 인덱스 생성

**Files:**
- Create: `scripts/generate-index.sh`

- [ ] **Step 1: generate-index.sh 구현**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/raindrop-api.sh"
load_settings

RUN_DATE="${1:-$(date +%Y-%m-%d)}"
REPORT_DIR="reports/${RUN_DATE}"

if [ ! -d "$REPORT_DIR" ]; then
  log_info "보고서 디렉토리 없음: $REPORT_DIR"
  exit 0
fi

# 모든 result 파일에서 통계 수집
total_passed=0
total_failed=0
passed_rows=""
failed_rows=""

for result_file in tmp/result_batch_*.json; do
  [ -f "$result_file" ] || continue

  # passed 항목
  jq -c '.results[] | select(.verification.status == "passed")' "$result_file" | while IFS= read -r item; do
    url=$(echo "$item" | jq -r '.url')
    collection=$(echo "$item" | jq -r '.category.collection_title // "미분류"')
    tags=$(echo "$item" | jq -r '.tags | join(", ")')
    slug=$(slugify "$(echo "$url" | sed 's|https\?://||;s|/|-|g;s|[?#].*||')")
    title=$(echo "$url" | sed 's|https\?://||;s|/| |g' | head -c 50)

    echo "| ${title} | ${collection} | ${tags} | [보기](./${slug}.md) |" >> "${REPORT_DIR}/.passed.tmp"
  done

  # failed 항목
  jq -c '.results[] | select(.verification.status == "failed")' "$result_file" | while IFS= read -r item; do
    url=$(echo "$item" | jq -r '.url')
    reason=$(echo "$item" | jq -r '.verification.reason')
    title=$(echo "$url" | sed 's|https\?://||;s|/| |g' | head -c 50)

    echo "| ${title} | ${reason} |" >> "${REPORT_DIR}/.failed.tmp"
  done
done

passed_count=$(wc -l < "${REPORT_DIR}/.passed.tmp" 2>/dev/null || echo 0)
failed_count=$(wc -l < "${REPORT_DIR}/.failed.tmp" 2>/dev/null || echo 0)
total=$((passed_count + failed_count))

cat > "${REPORT_DIR}/index.md" << INDEX
---
date: "${RUN_DATE}"
total: ${total}
passed: ${passed_count}
failed: ${failed_count}
---

# ${RUN_DATE} Reading List Report

## 처리 완료 (${passed_count}건)
| 제목 | 컬렉션 | 태그 | 보고서 |
|------|--------|------|--------|
$(cat "${REPORT_DIR}/.passed.tmp" 2>/dev/null || echo "| (없음) | - | - | - |")

## 검증 실패 (${failed_count}건)
| 제목 | 사유 |
|------|------|
$(cat "${REPORT_DIR}/.failed.tmp" 2>/dev/null || echo "| (없음) | - |")
INDEX

# 임시 파일 정리
rm -f "${REPORT_DIR}/.passed.tmp" "${REPORT_DIR}/.failed.tmp"

log_info "일별 인덱스 생성 완료: ${REPORT_DIR}/index.md (총 ${total}건)"
```

- [ ] **Step 2: 실행 권한 부여**

```bash
chmod +x scripts/generate-index.sh
```

- [ ] **Step 3: 커밋**

```bash
git add scripts/generate-index.sh
git commit -m "feat: 일별 인덱스 생성 스크립트"
```

---

## Task 10: GitHub Actions 워크플로우

**Files:**
- Create: `.github/workflows/process-bookmarks.yml`
- Create: `.github/workflows/deploy-pages.yml`

- [ ] **Step 1: 메인 워크플로우 생성**

`.github/workflows/process-bookmarks.yml`:
```yaml
name: Process Reading List

on:
  schedule:
    - cron: '0 0 * * *'
  workflow_dispatch:

concurrency:
  group: process-reading-list
  cancel-in-progress: false

permissions:
  contents: write
  issues: write

jobs:
  process:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup tools
        run: sudo apt-get install -y jq

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Initial setup (ensure quarantine collection exists)
        run: scripts/setup.sh
        env:
          RAINDROP_TEST_TOKEN: ${{ secrets.RAINDROP_TEST_TOKEN }}

      - name: Cleanup quarantine (10일 경과 → 휴지통)
        run: scripts/cleanup-quarantine.sh
        env:
          RAINDROP_TEST_TOKEN: ${{ secrets.RAINDROP_TEST_TOKEN }}

      - name: Fetch unsorted bookmarks
        run: scripts/fetch-unsorted.sh
        env:
          RAINDROP_TEST_TOKEN: ${{ secrets.RAINDROP_TEST_TOKEN }}

      - name: Split into batches
        run: scripts/split-batches.sh

      - name: Process batches
        run: |
          for batch in tmp/batch_*.json; do
            [ -f "$batch" ] || continue
            result_file="tmp/result_$(basename "$batch")"

            echo "=== 배치 처리: $(basename "$batch") ==="

            cat "$batch" | claude --print \
              --system-prompt "$(cat prompts/analyze-bookmarks.md)" \
              --output-format json \
              --dangerously-skip-permissions \
              > "$result_file" 2>/dev/null || { echo "배치 실패: $batch"; continue; }

            scripts/apply-results.sh "$result_file" || { echo "적용 실패: $result_file"; continue; }
          done
        env:
          RAINDROP_TEST_TOKEN: ${{ secrets.RAINDROP_TEST_TOKEN }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Generate daily index
        run: scripts/generate-index.sh

      - name: Commit and push reports
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add reports/ config/collections.json
          git diff --cached --quiet && echo "변경사항 없음" && exit 0
          git commit -m "report: $(date +%Y-%m-%d) 처리 결과"
          git push
```

- [ ] **Step 2: GitHub Pages 배포 워크플로우**

`.github/workflows/deploy-pages.yml`:
```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
    paths:
      - 'reports/**'

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Build with Jekyll
        uses: actions/jekyll-build-pages@v1
        with:
          source: ./
          destination: ./_site

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

- [ ] **Step 3: 커밋**

```bash
git add .github/workflows/process-bookmarks.yml .github/workflows/deploy-pages.yml
git commit -m "feat: GitHub Actions 워크플로우 (메인 + Pages 배포)"
```

---

## Task 11: 통합 테스트 및 마무리

**Files:**
- Modify: 기존 스크립트 (버그 수정)

- [ ] **Step 1: 모든 스크립트 실행 권한 재확인**

```bash
chmod +x scripts/*.sh scripts/lib/*.sh
```

- [ ] **Step 2: 로컬 dry-run 테스트 (API 토큰 없이)**

```bash
# 배치 분할 테스트 (API 불필요)
cp tests/fixtures/input_sample.json tmp/input.json
bash scripts/split-batches.sh
cat tmp/batch_001.json | jq '.bookmarks | length'
# Expected: 2 (중복 제거)
```

- [ ] **Step 3: 보고서 생성 테스트 (API 불필요)**

```bash
bash scripts/generate-reports.sh tests/fixtures/result_mixed.json
ls reports/2026-03-21/
# Expected: 2개 .md 파일
cat reports/2026-03-21/*.md
```

- [ ] **Step 4: 인덱스 생성 테스트**

```bash
cp tests/fixtures/result_mixed.json tmp/result_batch_001.json
bash scripts/generate-index.sh 2026-03-21
cat reports/2026-03-21/index.md
```

- [ ] **Step 5: bats 전체 테스트 실행**

```bash
bats tests/
```
Expected: 모든 테스트 통과

- [ ] **Step 6: 테스트 결과물 정리 및 최종 커밋**

```bash
rm -rf tmp/* reports/2026-03-21
git add -A
git commit -m "test: 통합 테스트 통과 확인 및 마무리"
git push
```

---

## Task Dependencies

```
Task 1 (스캐폴딩)
  └── Task 2 (API 헬퍼) ─┬── Task 3 (setup)
                          ├── Task 4 (fetch-unsorted)
                          ├── Task 5 (cleanup-quarantine)
                          ├── Task 6 (split-batches)
                          ├── Task 7 (generate-reports)
                          ├── Task 8 (apply-results)
                          └── Task 9 (generate-index)
                                      │
                          Task 10 (workflows) ← depends on all scripts
                                      │
                          Task 11 (통합 테스트)
```

**병렬 실행 가능:** Task 3, 4, 5, 6, 7은 Task 2 완료 후 동시 실행 가능.
**순차 실행 필요:** Task 8은 Task 7에 의존 (generate-reports 호출). Task 9, 10, 11은 순차.

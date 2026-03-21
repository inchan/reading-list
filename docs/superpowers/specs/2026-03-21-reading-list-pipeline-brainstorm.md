# Reading List Pipeline — 브레인스토밍 진행 상황

> **상태**: 브레인스토밍 진행 중 (명확화 질문 단계)
> **날짜**: 2026-03-21
> **다음 단계**: 남은 질문 완료 → 접근 방식 제안 → 설계 확정

---

## 개요

GitHub Actions로 AI가 Raindrop.io의 미분류 북마크를 가져와서 사실검증(실체 검증) → 요약/인사이트 보고서 생성 → git 저장소에 저장하는 자동화 파이프라인.

---

## 확정된 결정 사항

### 1. 소스: Unsorted 컬렉션
- Raindrop.io의 **Unsorted**(미분류, collection ID: -1)에서 가져옴
- AI가 처리하면 카테고리 컬렉션으로 이동 → 이동 자체가 "처리 완료" 시그널
- "사용자 읽음" 추적은 스코프 밖

### 2. 핵심 가치: 큐레이션 + 지식 아카이브
- AI가 걸러서 읽을 가치 있는 것만 남김
- 보고서로 핵심을 저장 → 검색 가능한 지식 베이스

### 3. 실체 검증 (Substance Verification)
- 전통적 팩트체크가 아닌 **"실체가 있는가"** 검증
- 검증 대상:
  - "X 도구/라이브러리를 만들었다" → GitHub/npm/PyPI 등 실제 존재 확인
  - "X 방법론/이론" → 원본 논문, 공식 문서, 인용 출처 존재 여부
  - AI 생성 허구 → 구체적 주장(이름, 날짜, 수치)이 실제와 일치하는지 교차 검증
  - 링크 데드 → URL 자체가 404
- **"실체가 없다"**가 휴지통 기준

### 4. 카테고리 분류: 컬렉션 + 태그 혼합
- **대분류**: 기존 Raindrop 컬렉션 목록에서 선택 (고정 목록)
- **세부 분류**: 태그 자동 부여
- **새 컬렉션 필요 시**: GitHub Issue로 등록 (사람이 승인)

### 5. 보고서 형식: 개별 파일 + 일별 인덱스
- 북마크당 개별 마크다운: `reports/YYYY-MM-DD-<title>.md`
- 일별 요약 인덱스: `reports/YYYY-MM-DD.md`
- 각 보고서에 요약, 인사이트, 검증 결과 포함

### 6. GitHub Actions 트리거: 스케줄 + 수동
- cron 스케줄로 주기적 자동 실행
- workflow_dispatch로 수동 실행도 가능

### 7. AI 런타임: Claude Code 기본 + 추상화 레이어
- **Claude Code 우선 구현** — OAuth 구독 플랜으로 CI에서 실행 가능 (확인됨)
- 파이프라인 로직과 AI 호출 분리 → 나중에 다른 런타임 교체 가능하도록 설계
- Gemini CLI / Codex CLI는 OAuth/구독 플랜 CI 사용 불가 (API key만 공식 지원)

### 8. Raindrop MCP 서버 (미결정)
- **공식 MCP 서버 존재**: `https://api.raindrop.io/rest/v2/ai/mcp` (Pro 플랜 필요, Beta)
  - OAuth 2.1 또는 Bearer Token 인증
  - 노출 tool 목록 미문서화
- **커뮤니티 최선**: `adeze/raindrop-mcp` (★135, v2.4.5, 17개 tool)
  - 필요 기능 전부 커버: unsorted 조회, 컬렉션 이동, 태그 관리, 노트 추가, 휴지통 이동
- **선택지**: 공식 우선 → 부족시 커뮤니티 폴백 / 커뮤니티 바로 사용 / 둘 다 테스트

---

## 남은 질문

- [ ] Raindrop MCP 서버 선택 (공식 vs 커뮤니티)
- [ ] Raindrop Pro 플랜 보유 여부
- [ ] 보고서 개별 파일 상세 구조 (섹션, 메타데이터 등)
- [ ] 스케줄 주기 (매일? 매 N시간?)
- [ ] 사실검증 실패 시 휴지통 이동 전 사용자 확인 필요 여부
- [ ] Raindrop 노트에 넣을 보고서 URL 형식 (GitHub Pages? raw 링크?)
- [ ] git 저장소 구조 (이 저장소 자체를 사용? 별도 저장소?)

---

## 브레인스토밍 대화 과정

### Q1. "읽지 않은 목록"의 정의
- **질문**: Raindrop.io의 "읽지 않은 목록"이 어떤 컬렉션을 의미하는가?
- **선택지**: Unsorted / 특정 컬렉션 필터 / 미처리 항목
- **답변**: Unsorted(1번) + 미처리 항목 추적(3번)도 고민
- **논의**: AI 처리 여부를 태그로 표시할지, 컬렉션 이동 자체가 시그널이 될지 논의
- **결론**: Unsorted → 카테고리 이동 = AI 처리 완료 시그널. 별도 태그 불필요.

### Q2. 시스템의 핵심 가치
- **질문**: 큐레이션 / 독서 관리 / 지식 아카이브 중 무엇이 핵심?
- **답변**: 큐레이션(1번) + 지식 아카이브(3번)
- **결론**: "사용자 읽음" 추적은 스코프 밖. AI가 걸러주고 보고서로 축적.

### Q3. 사실검증의 범위와 기준
- **질문**: URL 유효성+핵심 주장 검증 / 엄격한 팩트체크 / 스팸 필터링?
- **답변**: "AI가 쓴 허구, 저장소가 없는데 만들었다고 주장, 방법론인데 실제 내용 없음" 등
- **결론**: 전통적 팩트체크가 아닌 **실체 검증(substance verification)**. "실체가 없다"가 휴지통 기준.

### Q4. 카테고리 분류 체계
- **질문**: 컬렉션 기반 / 태그 기반 / 혼합?
- **답변**: 3번 (컬렉션 + 태그 혼합)
- **결론**: 대분류=컬렉션 이동, 세부분류=태그 부여

### Q5. 컬렉션 생성 권한
- **질문**: AI가 자유 생성 / 고정 목록만 / 상한 있는 자유 생성?
- **답변**: "추가 필요한 컬렉션이 생기면 깃 이슈로 등록"
- **결론**: 고정 목록 + 새 컬렉션 필요 시 GitHub Issue로 제안. 사람 승인 필요.

### Q6. 보고서 형식
- **질문**: 개별 파일 / 일별 통합 / 둘 다?
- **답변**: 3번 (둘 다)
- **결론**: 개별 마크다운 + 일별 요약 인덱스

### Q7. GitHub Actions 트리거
- **질문**: 스케줄 / 수동 / 둘 다?
- **답변**: 3번 (둘 다)

### Q8. AI 런타임 선택
- **질문**: Claude Code / Gemini CLI / Codex / 추상화 레이어?
- **논의**: OAuth/구독 플랜으로 CI 실행 가능한지 심층 조사 요청
- **조사 결과**:
  - Claude Code: OAuth 가능 (사용자 확인)
  - Gemini CLI: 불가 — headless 환경에서 `FatalAuthenticationError` 발생, `CI=true`/`GITHUB_ACTIONS=true` 감지 시 OAuth 차단
  - Codex CLI: 불가 — 공식 GitHub Action은 API key만, auth.json 복사는 비공식/불안정
- **답변**: 2번 (Claude Code 기본 + 추상화 레이어)
- **결론**: Claude Code 우선, 파이프라인 로직과 AI 호출 분리해서 나중에 교체 가능하게

### Q9. Raindrop MCP 서버 선택 (진행 중)
- **공식 MCP 서버**: `https://api.raindrop.io/rest/v2/ai/mcp` (Pro 플랜 필요, Beta, tool 목록 미문서화)
- **커뮤니티**: `adeze/raindrop-mcp` (★135, 17개 tool, 필요 기능 전부 커버)
- **상태**: 선택 대기 중 — 공식 우선 vs 커뮤니티 vs 둘 다 테스트

---

## 브레인스토밍 남은 단계

1. ~~프로젝트 컨텍스트 탐색~~ ✅
2. **명확화 질문** — 진행 중 (Q9부터 이어서)
3. 2-3개 접근 방식 제안
4. 설계 제시 및 승인
5. 설계 문서 작성 및 커밋
6. 스펙 리뷰 루프
7. 사용자 스펙 리뷰
8. writing-plans 스킬로 구현 계획 전환

---

## 조사 결과 요약

### OAuth 인증 GitHub Actions 지원 현황

| 도구 | OAuth/구독 CI 사용 | 비고 |
|------|-------------------|------|
| Claude Code | **가능** | 확인됨 |
| Gemini CLI | **불가** | headless 감지 시 OAuth 차단. API key만 공식 지원 |
| Codex CLI | **불가** | 공식 GitHub Action은 API key만. auth.json 복사 우회는 비공식/불안정 |

### 참고 링크

- Raindrop 공식 MCP: https://developer.raindrop.io/mcp/mcp
- adeze/raindrop-mcp: https://github.com/adeze/raindrop-mcp
- Gemini CLI: https://github.com/google-gemini/gemini-cli
- Codex CLI: https://github.com/openai/codex

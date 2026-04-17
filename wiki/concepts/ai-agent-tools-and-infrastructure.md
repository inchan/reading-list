---
title: AI 에이전트 도구와 인프라
created: 2026-04-18
updated: 2026-04-18
type: concept
sources:
  - wiki/raw/raindrop/items/1685716649/20260416T1104203.905c88b4f128829fbc211a30dcb90b0c2912ea7450348cb26577aa887b29aa5d.md
  - wiki/raw/raindrop/items/1684404379/20260415T1059313.641078452f0dac92a3161cfef2e36275f38af836871e38accfe5a63362665b45.md
  - wiki/raw/raindrop/items/1684404185/20260415T1059313.6a6b13d12d45667bb30d7d8cbe331b1df81ea2534f48f3184b6b54fe33c0c5a8.md
  - wiki/raw/raindrop/items/1682848671/20260413T1117562.2aa2547ccc5bd9cbfdd9ab56b908ccdca77a1af75d429eb77460352af2edfaa6.md
  - wiki/raw/raindrop/items/1682193672/20260413T1117562.55ea691f434d9706969ada8ccfba827b69337b47549a6c5041b8346ad79a1550.md
  - wiki/raw/raindrop/items/1680903369/20260412T1039031.83b4b55ffe1df3bb33615e8c822afb1067cab1c6f419b504df2416f2eaf3756e.md
  - wiki/raw/raindrop/items/1668361487/20260402T1101247.4fba2735f11f0f83f16ea39a6a69b7c0c052205c4ba36dc139f3dbf34c4a0267.md
  - wiki/raw/raindrop/items/1668244264/20260402T1101274.1a5d387ca327a1808457f3288b4f79782e9492b65d177bfb621ba8219c5d1b31.md
  - wiki/raw/raindrop/items/1667105450/20260331T1055585.dc63aee9b18b6e221ca1c475edd88d7e361440cf095dde9a39300b59a8034315.md
  - wiki/raw/raindrop/items/1656198177/20260326T0019026.76d862bbc5e9cba0ee89d0644635d4b6221d72d61c121c332d8152ae7b82ba40.md
  - wiki/raw/raindrop/items/1656197953/20260326T0019002.2e8e7b58c4ea0981ecc241e43f099678ace4fa1932ed642ca79c1f885a449b84.md
  - wiki/raw/raindrop/items/1655839637/20260326T0018580.335879041f0e13bad6f74547747bfda05b838a72cc3b59d51fc59ae1cd6b8843.md
  - wiki/raw/raindrop/items/1654523534/20260326T0018532.c48c8b377bbc613ab9ae5c865a8ad3cb269fe808fde44dfe269ae47cc767578e.md
  - wiki/raw/raindrop/items/1654301775/20260326T0018509.f25d49696fa97c2a46e12693f92471f3df6cc28cdf69b8f9abe7d7bf8fd62d2f.md
  - wiki/raw/raindrop/items/1653989367/20260326T0018406.421efe175cb0c119310b25fdaca9f3c2055553fe51512e8994f502fb1a7d2b2b.md
  - wiki/raw/raindrop/items/1653037596/20260326T0018292.af0c0a1a515e70ba2e48fab48d5742e6844a8d85931047f9fbecdba088b2acbe.md
  - wiki/raw/raindrop/items/1651703200/20260326T0018212.57ac9a8f69661fb32462c20e6815bf1db2f2c2d1e634d1e9f887b16039fe1c74.md
  - wiki/raw/raindrop/items/1648693361/20260326T0018018.6cb7a5d844fb90d7a90ee12dc947e198e18ef590123fcd9e966b5df3fe234096.md
  - wiki/raw/raindrop/items/1646096066/20260326T0017520.216c26d602565f55bd1f2e358b6da50acb95a5888a7bc9c32d0f0b6bceda41b9.md
  - wiki/raw/raindrop/items/1646095597/20260326T0017498.b5ce257224b4e681dd2e71bc46aeeb30523b49366c620f893efa97c8f7d61a3e.md
  - wiki/raw/raindrop/items/1646078343/20260326T0017473.fea8eb891580d1fdeeb320e20e616ca84f8be916ec19e250ead9aa77c9d432ee.md
  - wiki/raw/raindrop/items/1646000941/20260326T0017398.9b869d4af086053bfdce382ff13e79f4a2e0fecbb01c30c97f8194ac6056ac86.md
source_ids:
  - "raindrop:1685716649"
  - "raindrop:1684404379"
  - "raindrop:1684404185"
  - "raindrop:1682848671"
  - "raindrop:1682193672"
  - "raindrop:1680903369"
  - "raindrop:1668361487"
  - "raindrop:1668244264"
  - "raindrop:1667105450"
  - "raindrop:1656198177"
  - "raindrop:1656197953"
  - "raindrop:1655839637"
  - "raindrop:1654523534"
  - "raindrop:1654301775"
  - "raindrop:1653989367"
  - "raindrop:1653037596"
  - "raindrop:1651703200"
  - "raindrop:1648693361"
  - "raindrop:1646096066"
  - "raindrop:1646095597"
  - "raindrop:1646078343"
  - "raindrop:1646000941"
tags: [ai-agent, developer-tools, mcp, automation, open-source]
---

# AI 에이전트 도구와 인프라

이 페이지는 AI 에이전트를 실행, 원격 제어, 검색, 정리, 표준화, QA, 브라우징하는 주변 도구들을 모은다. 일부 소스는 Threads 소개글이므로 수치와 프로젝트 상태는 원문 주장으로 보존하고, 검증되지 않은 법적/보안성 판단은 확정 사실처럼 다루지 않는다.

## 설치형 CLI와 세션 관리

NomaDamas는 Markr AI가 후원하는 서울 기반 AI 오픈소스 해커하우스로, 한국 특화 스킬 모음 k-skill, 수능 국어 풀이 프로젝트, RAG 연구 자동화, 한국어 LLM 다크패턴 벤치마크 등을 운영하는 조직으로 기록된다. [raw](../raw/raindrop/items/1685716649/20260416T1104203.905c88b4f128829fbc211a30dcb90b0c2912ea7450348cb26577aa887b29aa5d.md)

OpenCLIs 관련 스레드는 Rust 싱글 바이너리 생태계로 monogram, monomento, monofetch, monosurf, vpncli, niia 등을 설치해 코드 검색, 문서 검색, 웹 문서 변환, 브라우저 제어, P2P 연결을 수행한다고 소개한다. zclean 스레드는 Codex나 Claude Code 세션 뒤에 남은 MCP 서버, 서브에이전트, 헤드리스 브라우저, esbuild 같은 고아 프로세스를 정리하는 CLI를 소개한다. [raw](../raw/raindrop/items/1684404379/20260415T1059313.641078452f0dac92a3161cfef2e36275f38af836871e38accfe5a63362665b45.md) [raw](../raw/raindrop/items/1684404185/20260415T1059313.6a6b13d12d45667bb30d7d8cbe331b1df81ea2534f48f3184b6b54fe33c0c5a8.md)

Waza는 코드 없이 마크다운으로 구성된 8개 Claude Code 스킬 묶음으로 소개된다. Port Killer는 포트 충돌 때 PID 탐색과 kill 명령을 대신하는 개발 보조 도구로 기록된다. [raw](../raw/raindrop/items/1682848671/20260413T1117562.2aa2547ccc5bd9cbfdd9ab56b908ccdca77a1af75d429eb77460352af2edfaa6.md) [raw](../raw/raindrop/items/1646078343/20260326T0017473.fea8eb891580d1fdeeb320e20e616ca84f8be916ec19e250ead9aa77c9d432ee.md)

## 에이전트 표준화와 오케스트레이션

GitAgent는 agent.yaml, SOUL.md, DUTIES.md, rules/ 같은 Git 저장소 파일 구조로 에이전트를 정의하고 LangChain, AutoGen, CrewAI, OpenAI Assistants, Claude Code 등으로 내보내려는 표준화 시도다. Ruflo는 Claude Code를 멀티 에이전트 개발 환경으로 확장하는 플랫폼으로, MCP 도구, 전문 에이전트 스웜, 모델 라우팅, 벡터 메모리, 정책 엔진을 포함한다고 정리되어 있다. [raw](../raw/raindrop/items/1656198177/20260326T0019026.76d862bbc5e9cba0ee89d0644635d4b6221d72d61c121c332d8152ae7b82ba40.md) [raw](../raw/raindrop/items/1654301775/20260326T0018509.f25d49696fa97c2a46e12693f92471f3df6cc28cdf69b8f9abe7d7bf8fd62d2f.md)

tofu-at는 기존 스킬, 에이전트, 커맨드를 분석해 Claude Code Agent Teams 구성을 자동 생성하는 오케스트레이션 프레임워크로 기록된다. Cognetivy는 AI 코딩 에이전트 세션을 로컬 .cognetivy/ 워크스페이스의 실행 추적, 이벤트 기록, 컬렉션 관리로 구조화하는 상태 레이어다. [raw](../raw/raindrop/items/1646096066/20260326T0017520.216c26d602565f55bd1f2e358b6da50acb95a5888a7bc9c32d0f0b6bceda41b9.md) [raw](../raw/raindrop/items/1646000941/20260326T0017398.9b869d4af086053bfdce382ff13e79f4a2e0fecbb01c30c97f8194ac6056ac86.md)

claude-peers-mcp는 같은 머신의 여러 Claude Code 세션이 localhost 브로커와 SQLite를 통해 서로 메시지를 주고받게 하는 MCP 서버로, 병렬 개발 세션 간 맥락 공유를 목표로 한다. [raw](../raw/raindrop/items/1653989367/20260326T0018406.421efe175cb0c119310b25fdaca9f3c2055553fe51512e8994f502fb1a7d2b2b.md)

## 원격 제어와 브라우저 자동화

ductor는 Telegram 또는 Matrix에서 Claude Code, Codex CLI, Gemini CLI를 제어하고 실시간 스트리밍, 지속 메모리, 크론, 웹훅, Docker 샌드박싱을 제공하는 도구로 정리되어 있다. Claude Code Channels 관련 스레드는 Anthropic의 Telegram/Discord 원격 조작 프리뷰와 커뮤니티 프로젝트 claude-code-telegram, OpenClaw의 관계를 기록한다. [raw](../raw/raindrop/items/1654523534/20260326T0018532.c48c8b377bbc613ab9ae5c865a8ad3cb269fe808fde44dfe269ae47cc767578e.md) [raw](../raw/raindrop/items/1653037596/20260326T0018292.af0c0a1a515e70ba2e48fab48d5742e6844a8d85931047f9fbecdba088b2acbe.md)

WebMCP 소스는 Chrome 기능을 통해 AI가 브라우저를 사람처럼 조작할 수 있다는 주장과 AWS 콘솔, 앱스토어 등록, Google API 설정 같은 복잡한 웹 작업 자동화를 언급한다. Lightpanda는 Zig로 새로 작성된 헤드리스 브라우저로, Chrome 대비 메모리와 실행 속도 이점을 표방하지만 CDP와 복잡한 로그인 흐름에는 한계가 있다고 정리된다. [raw](../raw/raindrop/items/1651703200/20260326T0018212.57ac9a8f69661fb32462c20e6815bf1db2f2c2d1e634d1e9f887b16039fe1c74.md) [raw](../raw/raindrop/items/1655839637/20260326T0018580.335879041f0e13bad6f74547747bfda05b838a72cc3b59d51fc59ae1cd6b8843.md)

OpenGranola 소스는 macOS용 오픈소스 회의 보조 도구로, 로컬 오디오 처리, 화면 공유 중 비노출, 마크다운 메모 폴더 연결, 회의 맥락 기반 과거 노트 검색을 소개한다. 특정 구독 서비스에 종속되지 않고 로컬 파일과 저렴한 LLM API를 연결하는 개인 비서 흐름의 사례로 남긴다. [raw](../raw/raindrop/items/1648693361/20260326T0018018.6cb7a5d844fb90d7a90ee12dc947e198e18ef590123fcd9e966b5df3fe234096.md)

## 조사, QA, 검색 최적화

last30days-skill은 Reddit, X, YouTube, Hacker News, Polymarket 등 최근 30일 데이터를 수집해 주제별 동향을 합성하는 스킬이다. ai-news-mcp는 에이전트/AI 관련 소스를 주기적으로 스크랩하고 사용자의 관심사 관점에서 리뷰하는 개인 뉴스 수집 워크플로우로 소개된다. [raw](../raw/raindrop/items/1668361487/20260402T1101247.4fba2735f11f0f83f16ea39a6a69b7c0c052205c4ba36dc139f3dbf34c4a0267.md) [raw](../raw/raindrop/items/1682193672/20260413T1117562.55ea691f434d9706969ada8ccfba827b69337b47549a6c5041b8346ad79a1550.md)

Marketrix AI는 Selenium/Playwright 스크립트 대신 사용자 페르소나가 앱을 직접 탐색하는 방식의 QA 자동화 플랫폼으로 소개된다. GEO SEO Claude 스킬은 ChatGPT, Claude, Perplexity, Gemini, Google AI Overviews 같은 생성형 검색 엔진을 대상으로 인용 가능성, AI 크롤러, 브랜드 권위, 스키마 마크업을 점검하는 도구로 기록된다. [raw](../raw/raindrop/items/1667105450/20260331T1055585.dc63aee9b18b6e221ca1c475edd88d7e361440cf095dde9a39300b59a8034315.md) [raw](../raw/raindrop/items/1646095597/20260326T0017498.b5ce257224b4e681dd2e71bc46aeeb30523b49366c620f893efa97c8f7d61a3e.md)

## 주의해서 볼 소스

free-code 스레드는 Claude Code 유출 소스 기반 포크, 텔레메트리 제거, 가드레일 제거, OpenAI OAuth 지원을 소개하지만, 원문 자체가 법적/보안적 민감성이 있는 주장이다. 여기서는 "그렇게 소개되었다"는 사실만 보존한다. Grok CLI도 xAI 공식 제품이 아니라 커뮤니티 빌드라는 원문 주의사항을 함께 남긴다. [raw](../raw/raindrop/items/1668244264/20260402T1101274.1a5d387ca327a1808457f3288b4f79782e9492b65d177bfb621ba8219c5d1b31.md) [raw](../raw/raindrop/items/1656197953/20260326T0019002.2e8e7b58c4ea0981ecc241e43f099678ace4fa1932ed642ca79c1f885a449b84.md)

## 같이 보기

- [AI 에이전트 하네스와 작업 흐름](ai-agent-harness-and-workflows.md)
- [지식 그래프, RAG, 문서 AI 워크플로우](knowledge-graph-rag-and-document-ai.md)
- [AI 콘텐츠, 디자인, 문서 자동화](ai-content-design-and-creative-automation.md)

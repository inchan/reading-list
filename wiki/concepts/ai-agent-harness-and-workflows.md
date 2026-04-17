---
title: AI 에이전트 하네스와 작업 흐름
created: 2026-04-18
updated: 2026-04-18
type: concept
sources:
  - wiki/raw/raindrop/items/1675624540/20260409T1104347.bf8da89ec764e75ce3e67cf3e3ff4938c4a2efe8f4c94f63f9ce2dd4e48ecd83.md
  - wiki/raw/raindrop/items/1675624359/20260409T1104355.1449d7bbb0e001cb60eef79ef42fa8ea914f7de1c20ca62463b21fb1e7312bcc.md
  - wiki/raw/raindrop/items/1671496610/20260404T1040249.13511bd83b70e752653dca8f86a40d59901d52abba392f4436490dd3061b9728.md
  - wiki/raw/raindrop/items/1671496503/20260404T1040257.11acb87231c0a255442f2674b6201d097d706e13cb497e4257b081a333886885.md
  - wiki/raw/raindrop/items/1668754544/20260402T1101239.68552a29168531142d77c23c55c023b32723c6dfc7ac13fb27ac336adcf699e2.md
  - wiki/raw/raindrop/items/1668753417/20260402T1101256.c20f02fc0f5feacd5e48c678a9680c5277d971a39941eb9b3d1953d9a9df1bc6.md
  - wiki/raw/raindrop/items/1668354085/20260402T1101282.80b4cff5c90bfa77455c7bac8c84e67ed8c1d63498f21234886127fd665ce84f.md
  - wiki/raw/raindrop/items/1668040727/20260402T1101290.7f39683865b0bb73173171f95d815fcce72c84973aa9f773aab96e0bb76b6ed4.md
  - wiki/raw/raindrop/items/1657010092/20260325T1542190.808466190b99a69aa9905b65ed981fe376022f091ba11cb09d4bb6edaafcee00.md
  - wiki/raw/raindrop/items/1667707861/20260402T1101264.f150f79473d1ba1cf47cae9d7bff78550528dfda6a61cfc7862aace4f8d7a356.md
  - wiki/raw/raindrop/items/1666015481/20260331T1055575.846fdb6a010f4eaa110ba9d2c285e0fc8788ad5e64e6f6bd472e89ccd28e2d80.md
  - wiki/raw/raindrop/items/1654556507/20260326T0018556.f4f6f0781dc2b3c6a7fac4dd76c8aab1d1a58e40e1048cc5f97af2f4cbf453a0.md
  - wiki/raw/raindrop/items/1649864082/20260326T0018189.8e4734e8be5f27062b5ccfda91fa1cc3975ed0f5d24e6544df9fcc1f72f727a5.md
  - wiki/raw/raindrop/items/1648691394/20260326T0017592.ab4ae4ee09b9defa209db049154443a4150ad097469727f4b20c48c7d013d6dc.md
  - wiki/raw/raindrop/items/1646060220/20260326T0017426.95042bf6af63762bfd3345f5652fc546867f4fee6d578aa64c5128e28bc53612.md
  - wiki/raw/raindrop/items/1653988778/20260326T0018383.dd19ca2f04116421da20ad7c8161e8df98e7c20a8c622bcf8f7571f7d735f07c.md
  - wiki/raw/raindrop/items/1645967186/20260326T0017374.bb0ffbe4e55e708ef7fa763e2f1c16208427fecae3d97fbfbbefb2b890b16603.md
  - wiki/raw/raindrop/items/1675258929/20260409T1104371.ead3e8f9fb118da719a55747b39c64dac55199c717427560a5ea662a3da6d0a5.md
  - wiki/raw/raindrop/items/1653037890/20260326T0750291.d23c71a036cf576de618432de79d679c9f59bdb1dcb11b55f8479f4a5faca1fb.md
  - wiki/raw/raindrop/items/1649200447/20260326T0018093.2a4167087e0b021316eab6a1d1bc4008a6ed6a81c622258755b91c246094d070.md
  - wiki/raw/raindrop/items/1674933040/20260408T1057091.98972e1de014da1e937d4ff2e510a770beaa8fcf097f39c8559b40f0f1c80b7c.md
source_ids:
  - "raindrop:1675624540"
  - "raindrop:1675624359"
  - "raindrop:1671496610"
  - "raindrop:1671496503"
  - "raindrop:1668754544"
  - "raindrop:1668753417"
  - "raindrop:1668354085"
  - "raindrop:1668040727"
  - "raindrop:1657010092"
  - "raindrop:1667707861"
  - "raindrop:1666015481"
  - "raindrop:1654556507"
  - "raindrop:1649864082"
  - "raindrop:1648691394"
  - "raindrop:1646060220"
  - "raindrop:1653988778"
  - "raindrop:1645967186"
  - "raindrop:1675258929"
  - "raindrop:1653037890"
  - "raindrop:1649200447"
  - "raindrop:1674933040"
tags: [ai-agent, harness-engineering, claude-code, codex, ai-workflow]
---

# AI 에이전트 하네스와 작업 흐름

AI 코딩 에이전트 운영의 핵심은 더 많은 명령어를 붙이는 것이 아니라, 의도 정렬, 스펙, 평가자 분리, 반복 검증, 운영 규칙을 하네스 안에 배치하는 것이다. 이 페이지는 Claude Code, Codex, OpenSpec, AlignStack, 에이전트 스킬, 코드 리뷰, 인증/학습 자료를 같은 운영 흐름으로 묶는다.

## 정렬과 스펙

AlignStack은 인간 의도와 AI 구현 사이의 불일치를 Workspace, Task, Action-Space, Action-Set, Coherence, Outcome의 6계층으로 분해한다. 원문 메모는 정렬을 "비교, 측정, 가시성, 명시성"의 문제로 다루며, 바이브 코딩과 완전 자동화 사이의 실용적 중간 지점으로 설명한다. [raw](../raw/raindrop/items/1654556507/20260326T0018556.f4f6f0781dc2b3c6a7fac4dd76c8aab1d1a58e40e1048cc5f97af2f4cbf453a0.md)

OpenSpec 계열 자료는 Proposal, Apply, Archive 흐름으로 AI가 코딩 전에 명세를 만들고 검증하게 하는 스펙 주도 개발 방식을 강조한다. Apply Change 스킬은 활성 변경 사항을 감지하고 구현, 검증, 진행 보고 루프를 자동화하는 보조 장치로 정리된다. [raw](../raw/raindrop/items/1668754544/20260402T1101239.68552a29168531142d77c23c55c023b32723c6dfc7ac13fb27ac336adcf699e2.md) [raw](../raw/raindrop/items/1668753417/20260402T1101256.c20f02fc0f5feacd5e48c678a9680c5277d971a39941eb9b3d1953d9a9df1bc6.md)

OpenSpec 이슈 목록은 스펙 주도 AI 코딩의 실무 마찰도 보여준다. 계층형 워크플로우, 스키마 검증, 실행 로그, 복구 커맨드, 특정 AI 도구와의 시퀀스 준수 문제가 열린 이슈로 남아 있어, 명세만으로 에이전트 비결정성이 사라지는 것은 아니다. [raw](../raw/raindrop/items/1666015481/20260331T1055575.846fdb6a010f4eaa110ba9d2c285e0fc8788ad5e64e6f6bd472e89ccd28e2d80.md)

## 평가 루프

Anthropic 하네스 자료는 자기 평가 편향을 핵심 실패 모드로 본다. 생성 에이전트와 평가 에이전트를 분리하고, Playwright 같은 실제 탐색 기반 평가로 5-15회 반복하는 구조가 소개된다. 같은 주제를 다룬 두 스레드는 모델이 발전하면 Planner, Generator, Evaluator 같은 분해 구조를 다시 단순화해야 한다는 점을 공통으로 기록한다. [raw](../raw/raindrop/items/1668040727/20260402T1101290.7f39683865b0bb73173171f95d815fcce72c84973aa9f773aab96e0bb76b6ed4.md) [raw](../raw/raindrop/items/1657010092/20260325T1542190.808466190b99a69aa9905b65ed981fe376022f091ba11cb09d4bb6edaafcee00.md)

Autoresearch/council 계열 메모는 north star 정의, 평가 세트 설계, 채점관 분리, Claude와 Codex 간 토론, 마지막 인간 sign-off를 하나의 반복 루프로 묶는다. 온라인 멀티플레이 테트리스 구현 사례는 PRD를 단일 진실 원천으로 두고 구현, 테스트, 검증, 수정을 반복한 사례로 남아 있다. [raw](../raw/raindrop/items/1675624540/20260409T1104347.bf8da89ec764e75ce3e67cf3e3ff4938c4a2efe8f4c94f63f9ce2dd4e48ecd83.md) [raw](../raw/raindrop/items/1675624359/20260409T1104355.1449d7bbb0e001cb60eef79ef42fa8ea914f7de1c20ca62463b21fb1e7312bcc.md)

## 스킬과 팀 운영

에이전트 스킬 관련 두 자료는 현재 스킬이 사용자가 직접 호출하는 슬래시 명령어에 가까우며, 컨텍스트 창 상단에 고정되는 텍스트로 동작한다고 설명한다. Skill Chaining은 이 한계를 넘어 스킬을 행동 단위로 연결하려는 방향이다. [raw](../raw/raindrop/items/1671496610/20260404T1040249.13511bd83b70e752653dca8f86a40d59901d52abba392f4436490dd3061b9728.md) [raw](../raw/raindrop/items/1671496503/20260404T1040257.11acb87231c0a255442f2674b6201d097d706e13cb497e4257b081a333886885.md)

Claude Code 팀 사례와 Anthropic의 스킬 운용 글은 워크플로우 오케스트레이션, 서브에이전트 전략, 자기 성장 루프, 완료 전 검증을 반복 가능한 운영 습관으로 다룬다. Claude Code 에이전트 팀 메모는 대량 작업 병렬화와 토큰 절감이 팀 모드의 실질적 장점이라고 요약된다. [raw](../raw/raindrop/items/1649864082/20260326T0018189.8e4734e8be5f27062b5ccfda91fa1cc3975ed0f5d24e6544df9fcc1f72f727a5.md) [raw](../raw/raindrop/items/1648691394/20260326T0017592.ab4ae4ee09b9defa209db049154443a4150ad097469727f4b20c48c7d013d6dc.md) [raw](../raw/raindrop/items/1646060220/20260326T0017426.95042bf6af63762bfd3345f5652fc546867f4fee6d578aa64c5128e28bc53612.md)

## 리뷰, 비용, 학습

AI 코드 리뷰 자료는 맥락 우선, 중요도 기반, 전문가 에이전트, 기여 추적, 수정-재검증 흐름을 2026년형 리뷰 패턴으로 정리한다. 토큰 효율 자료는 CLAUDE.md 규칙으로 서두/맺음말 제거, 응답 압축, 과잉 설계 금지 같은 행동 제어를 시도한다. [raw](../raw/raindrop/items/1668354085/20260402T1101282.80b4cff5c90bfa77455c7bac8c84e67ed8c1d63498f21234886127fd665ce84f.md) [raw](../raw/raindrop/items/1667707861/20260402T1101264.f150f79473d1ba1cf47cae9d7bff78550528dfda6a61cfc7862aace4f8d7a356.md)

Claude Certified Architect 관련 두 소스는 Agentic Architecture, Tool Design & MCP, Claude Code Configuration, Prompt Engineering, Context Management를 엔터프라이즈 AI 역량의 시험 범위로 기록한다. 하나는 공식 출시 정보와 시험 구조를, 다른 하나는 파트너 조직 중심 접근성을 강조한다. [raw](../raw/raindrop/items/1653988778/20260326T0018383.dd19ca2f04116421da20ad7c8161e8df98e7c20a8c622bcf8f7571f7d735f07c.md) [raw](../raw/raindrop/items/1645967186/20260326T0017374.bb0ffbe4e55e708ef7fa763e2f1c16208427fecae3d97fbfbbefb2b890b16603.md)

개발자 설명력 자료, Karpathy/Tao 성향 비교 메모, Claude 공식 활용 컬렉션 추천은 에이전트 운영을 둘러싼 학습 자료로 남긴다. Reddit의 Claude/Codex 사용량 체크 메뉴바 앱 소스는 본문이 거의 없어 원문 확인이 필요하다. [raw](../raw/raindrop/items/1675258929/20260409T1104371.ead3e8f9fb118da719a55747b39c64dac55199c717427560a5ea662a3da6d0a5.md) [raw](../raw/raindrop/items/1653037890/20260326T0750291.d23c71a036cf576de618432de79d679c9f59bdb1dcb11b55f8479f4a5faca1fb.md) [raw](../raw/raindrop/items/1649200447/20260326T0018093.2a4167087e0b021316eab6a1d1bc4008a6ed6a81c622258755b91c246094d070.md) [raw](../raw/raindrop/items/1674933040/20260408T1057091.98972e1de014da1e937d4ff2e510a770beaa8fcf097f39c8559b40f0f1c80b7c.md)

## 같이 보기

- [AI 에이전트 도구와 인프라](ai-agent-tools-and-infrastructure.md)
- [지식 그래프, RAG, 문서 AI 워크플로우](knowledge-graph-rag-and-document-ai.md)
- [LLM 라우팅과 비용 최적화](llm-routing-and-cost-optimization.md)

---
title: AI 금융과 시장 분석 도구
created: 2026-04-18
updated: 2026-04-18
type: concept
sources:
  - wiki/raw/raindrop/items/1684400350/20260415T1059313.4480e5871f78004b2abc20f122be89ba02562dc3602caeeff4b36af828bf68aa.md
  - wiki/raw/raindrop/items/1684388007/20260415T1059313.8531368be11e17794b9ff178254ab03034dc1c287db28638dea70746934ed9b6.md
  - wiki/raw/raindrop/items/1684398815/20260415T1101045.1dc445c26af3c19055ef2a3a455a69d127a7216227b36eb6e2feab43c353731d.md
  - wiki/raw/raindrop/items/1654298965/20260326T0018474.4bdd3f45c78331be97715cba81cb7b5409986a543dbe193274d2ea328cc9a52b.md
  - wiki/raw/raindrop/items/1652862745/20260326T0018245.24d3b2a187b692754e967389c624f194c478bdbab3f46c12e41aa1bfbc040a07.md
  - wiki/raw/raindrop/items/857571198/20260322T1538130.426acec41303b9463199ce26ffc6d95408f810207a2bde7f4bd52f4b43941a85.md
source_ids:
  - "raindrop:1684400350"
  - "raindrop:1684388007"
  - "raindrop:1684398815"
  - "raindrop:1654298965"
  - "raindrop:1652862745"
  - "raindrop:857571198"
tags: [finance, trading, ai-agent, market-data, investing]
---

# AI 금융과 시장 분석 도구

금융 관련 소스는 데이터 수집 라이브러리, 한국 시장 API/MCP, 멀티 에이전트 트레이딩 시뮬레이션, 일반 재테크 학습 자료로 나뉜다. 투자 성과나 수익 주장은 원문 주장으로만 보존하며, 투자 조언으로 해석하지 않는다.

## 시장 데이터 수집

yfinance 스레드는 Python에서 Yahoo Finance 데이터를 가져오는 출발점으로 yfinance를 소개한다. 원문은 개별 종목, 과거 시세, 재무제표, 옵션 데이터, WebSocket 스트리밍을 언급한다. [raw](../raw/raindrop/items/1684400350/20260415T1059313.4480e5871f78004b2abc20f122be89ba02562dc3602caeeff4b36af828bf68aa.md)

한국 주식 도구 스레드는 DART와 KRX 공식 API 기반 korea-stock-mcp, 한국 영업일/개장일 계산 라이브러리 korea-business-day, 시장조치 조건 계산 서비스 kwatch를 함께 소개한다. 한국 공시와 거래소 데이터를 에이전트 질의에 연결하려는 흐름으로 볼 수 있다. [raw](../raw/raindrop/items/1684388007/20260415T1059313.8531368be11e17794b9ff178254ab03034dc1c287db28638dea70746934ed9b6.md)

## 멀티 에이전트 트레이딩

AI Hedge Fund는 유명 투자자 철학을 모방한 투자 에이전트와 Valuation, Sentiment, Fundamentals, Technicals, Risk Manager, Portfolio Manager 같은 분석/관리 에이전트가 협력하는 교육·연구용 프로젝트로 기록된다. [raw](../raw/raindrop/items/1684398815/20260415T1101045.1dc445c26af3c19055ef2a3a455a69d127a7216227b36eb6e2feab43c353731d.md)

TradingAgents는 분석가, 리서처, 트레이더, 리스크 매니저, 펀드 매니저가 단계적으로 의사결정하는 헤지펀드형 멀티 에이전트 프레임워크로 소개된다. 원문은 금융 도메인의 역할 분담 패턴이 법률 분석, 의료 진단처럼 복잡한 의사결정 도메인에도 참고 가능하다고 본다. [raw](../raw/raindrop/items/1654298965/20260326T0018474.4bdd3f45c78331be97715cba81cb7b5409986a543dbe193274d2ea328cc9a52b.md)

MiroFish 관련 소스는 40년치 S&P500 데이터를 바탕으로 뉴스 이벤트 발생 시 주가 움직임을 시뮬레이션하는 퀀트 트레이딩 시스템을 소개한다. 실제 수익, 투자 유치, 블록체인 공개 검증 같은 주장은 원문 주장으로만 남긴다. [raw](../raw/raindrop/items/1652862745/20260326T0018245.24d3b2a187b692754e967389c624f194c478bdbab3f46c12e41aa1bfbc040a07.md)

## 학습 자료

재테크 무료 금융교재 소스는 대학생과 사회초년생 대상 금융감독원 실용금융 교재 같은 무료 학습 자료를 모은 글이다. 본문 추출은 일부만 있으므로, 구체 교재 목록은 원문 확인 후 보강한다. [raw](../raw/raindrop/items/857571198/20260322T1538130.426acec41303b9463199ce26ffc6d95408f810207a2bde7f4bd52f4b43941a85.md)

## 같이 보기

- [LLM 라우팅과 비용 최적화](llm-routing-and-cost-optimization.md)
- [AI 에이전트 하네스와 작업 흐름](ai-agent-harness-and-workflows.md)

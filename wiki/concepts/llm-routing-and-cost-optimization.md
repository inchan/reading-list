---
title: LLM 라우팅과 비용 최적화
created: 2026-04-18
updated: 2026-04-18
type: concept
sources:
  - wiki/raw/raindrop/items/1657197541/20260326T0021277.8aef9fcdab165e8f50d202bb5b7955d892d0f445e92247bc5c85879e536e874f.md
  - wiki/raw/raindrop/items/1656522687/20260326T0750216.c4c78ef840b579cdec636c1afa10b061aa8ebaa5d693efdab266db31074882af.md
source_ids:
  - "raindrop:1657197541"
  - "raindrop:1656522687"
tags: [llm-routing, cost-optimization, inference, ai-infra]
---

# LLM 라우팅과 비용 최적화

LLM 라우팅은 "어떤 모델을 쓸 것인가"를 사용자가 매번 고르는 문제가 아니라, 요청의 난이도, 비용, 지연, 공급자 장애, 추론 필요성을 시스템이 판단하는 인프라 문제로 이동하고 있다.

## ClawRouter

ClawRouter는 앱과 여러 LLM 제공자 사이에서 로컬 프록시로 동작하며, 각 요청을 평가해 충분히 처리 가능한 저비용 모델로 보내는 오픈소스 라우터로 소개된다. 원문 메모는 55개 이상의 제공자, 15개 차원 가중치 스코어, 빠른 라우팅 판단, OpenAI 호환 API, 자동 폴백 체인을 강조한다. [raw](../raw/raindrop/items/1657197541/20260326T0021277.8aef9fcdab165e8f50d202bb5b7955d892d0f445e92247bc5c85879e536e874f.md)

특이점은 단순 API 키 프록시가 아니라 에이전트 네이티브 지불/인증 모델을 표방한다는 점이다. 원문은 지갑 서명 인증과 x402 기반 USDC 마이크로 결제를 언급하므로, 비용 통제와 결제 레이어를 함께 보는 사례로 보존한다. [raw](../raw/raindrop/items/1657197541/20260326T0021277.8aef9fcdab165e8f50d202bb5b7955d892d0f445e92247bc5c85879e536e874f.md)

## vLLM Semantic Router

vLLM Semantic Router는 요청을 의미론적으로 분류하고 Workload, Router, Pool을 함께 최적화하는 WRP 아키텍처로 정리된다. 원문 메모는 단순 질의에서 추론 모드를 생략해 지연과 토큰 사용을 줄이는 연구 결과, vLLM/OpenAI/Anthropic/Azure/Bedrock/Gemini 백엔드 지원, 라우팅을 추론 시스템 전체 최적화 문제로 확장하는 관점을 강조한다. [raw](../raw/raindrop/items/1656522687/20260326T0750216.c4c78ef840b579cdec636c1afa10b061aa8ebaa5d693efdab266db31074882af.md)

## 운영 메모

두 소스 모두 라우팅을 "가장 똑똑한 모델을 항상 쓰지 않는 기술"로 본다. 실무에서는 저렴한 모델 선택, 추론 모드 생략, 공급자 장애 폴백, 비용 관측성을 함께 설계해야 한다. 정교한 하네스 설계와 연결되므로 [AI 에이전트 하네스와 작업 흐름](ai-agent-harness-and-workflows.md)과 같이 읽는다.

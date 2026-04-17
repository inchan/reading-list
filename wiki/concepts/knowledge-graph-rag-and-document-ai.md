---
title: 지식 그래프, RAG, 문서 AI 워크플로우
created: 2026-04-18
updated: 2026-04-18
type: concept
sources:
  - wiki/raw/raindrop/items/1684386034/20260415T1101037.8788d4f700d9fd399ae962b8678c7958189f949c1e8c6542f08ea07333d9c05d.md
  - wiki/raw/raindrop/items/1676288168/20260409T1104332.1fd7e18d7829f4f3728894d584df81ba3bc2f668c0bc6f2e25a3c5334dd319e6.md
  - wiki/raw/raindrop/items/1675994207/20260409T1104340.516a019f9ee6fe8f36758aeaaf8169c7efc564c95188067c90b5a69782af7644.md
  - wiki/raw/raindrop/items/1671496698/20260404T1040241.a904386f258816c1f1847e81492b1f5c7413adb5aca24c966401378a39767106.md
  - wiki/raw/raindrop/items/1665313168/20260330T1105134.cfdb2214148836bd53f94ba160a8daaf96a0f4cb42232ceebe6f99a09f1609fc.md
  - wiki/raw/raindrop/items/1665003970/20260330T1105157.4b7f68cdbd6f4b65ff5d557a0c5bf1c259eef4063b648f17fe01b9acb8ed535c.md
  - wiki/raw/raindrop/items/1653039860/20260326T0018359.6ea1dba1835f735524a6a5db7dd8680e1fa61fdc0ddddf398b9155ed0e2276cd.md
  - wiki/raw/raindrop/items/1682189087/20260413T1117562.d827c0843f37d42a218f1ec7e9a4ffc4b55d3c8268fc0337a14aa2cf0afc2114.md
  - wiki/raw/raindrop/items/1680903676/20260412T1039031.39ff60d7b7e22b73123f9c84cc47b4d9f93ee874c3af9e43e60fa653c1a57bbb.md
source_ids:
  - "raindrop:1684386034"
  - "raindrop:1676288168"
  - "raindrop:1675994207"
  - "raindrop:1671496698"
  - "raindrop:1665313168"
  - "raindrop:1665003970"
  - "raindrop:1653039860"
  - "raindrop:1682189087"
  - "raindrop:1680903676"
tags: [rag, knowledge-graph, document-ai, obsidian, context-engineering]
---

# 지식 그래프, RAG, 문서 AI 워크플로우

이 묶음은 지식 베이스를 벡터 검색만으로 다루지 않고, 마크다운 위키, Obsidian, 지식 그래프, 온톨로지, 도메인 임베딩, 문서 OCR까지 연결해 에이전트가 읽고 재사용할 수 있는 구조로 만드는 자료들이다.

## 코드와 지식의 그래프화

Understand-Anything은 코드베이스나 Karpathy LLM wiki 같은 지식 베이스를 인터랙티브 지식 그래프로 변환하는 멀티플랫폼 플러그인으로 소개된다. 구조 그래프와 비즈니스 도메인 그래프, 퍼지/시맨틱 검색, diff 영향 분석, 가이드 투어를 제공해 대규모 코드베이스 온보딩을 줄이는 것이 핵심이다. [raw](../raw/raindrop/items/1684386034/20260415T1101037.8788d4f700d9fd399ae962b8678c7958189f949c1e8c6542f08ea07333d9c05d.md)

graphify는 Claude Code, Codex, OpenCode, OpenClaw 등에서 `/graphify`로 실행하는 지식 그래프 스킬이다. 원문 메모는 tree-sitter AST, Claude 비전, NetworkX, Leiden 클러스터링, EXTRACTED/INFERRED/AMBIGUOUS 신뢰도 표기를 강조하며, 임베딩 없이 그래프 토폴로지만으로 관계를 활용하는 접근을 차별점으로 본다. [raw](../raw/raindrop/items/1676288168/20260409T1104332.1fd7e18d7829f4f3728894d584df81ba3bc2f668c0bc6f2e25a3c5334dd319e6.md)

온톨로지 적용 메모는 문서 검색 속도를 2-3초에서 10ms로 줄였다는 실무 경험을 소개한다. 핵심은 전통적인 온톨로지 구축 비용을 AI가 관계 정의와 유지보수로 보조하면서, 벡터 검색의 한계를 그래프/관계 검색으로 보완하는 방향이다. [raw](../raw/raindrop/items/1665003970/20260330T1105157.4b7f68cdbd6f4b65ff5d557a0c5bf1c259eef4063b648f17fe01b9acb8ed535c.md)

## 로컬 검색과 개인 지식 베이스

qmd는 마크다운 문서, 회의록, 지식베이스를 로컬에서 인덱싱하는 CLI다. BM25, 벡터 검색, 쿼리 확장, RRF, Qwen3 재랭킹을 결합하고, Claude Code 플러그인, MCP 서버, HTTP 데몬 모드를 제공하는 로컬 우선 검색 도구로 정리된다. [raw](../raw/raindrop/items/1675994207/20260409T1104340.516a019f9ee6fe8f36758aeaaf8169c7efc564c95188067c90b5a69782af7644.md)

Obsidian 개인 지식 베이스 글은 LLM을 코드 보조 도구가 아니라 지식 컴파일러로 보고, 원본 수집, 자동 정리, 질의응답, 산출물 생성, 지속 개선의 5단계 워크플로우를 제시한다. 별도 RAG 없이도 잘 정리된 마크다운 위키와 장문 컨텍스트 모델로 개인 연구 환경을 구성할 수 있다는 점이 실용적이다. [raw](../raw/raindrop/items/1671496698/20260404T1040241.a904386f258816c1f1847e81492b1f5c7413adb5aca24c966401378a39767106.md)

Obsidian skills 소스는 Claude Code, Codex CLI, OpenCode에서 Obsidian 마크다운, Bases, JSON Canvas, 볼트 CLI 조작, 웹페이지 클린 마크다운 추출을 다루는 스킬 묶음으로 기록된다. GBrain 소스는 Gary Tan의 개인 AI 기억 시스템을 오픈소스화했다는 소개로, 개인 데이터 검색과 에이전트 메모리 인프라 관점에서 함께 보존한다. [raw](../raw/raindrop/items/1682189087/20260413T1117562.d827c0843f37d42a218f1ec7e9a4ffc4b55d3c8268fc0337a14aa2cf0afc2114.md) [raw](../raw/raindrop/items/1680903676/20260412T1039031.39ff60d7b7e22b73123f9c84cc47b4d9f93ee874c3af9e43e60fa653c1a57bbb.md)

## 문서 처리와 임베딩

Chandra OCR 2는 이미지와 PDF를 HTML, Markdown, JSON으로 변환하면서 레이아웃을 보존하는 문서 인식 모델로 기록된다. 복잡한 테이블, 수식, 손글씨, 체크박스 폼, 다국어 문서 처리를 RAG 파이프라인의 입력 품질 문제와 연결해 볼 수 있다. [raw](../raw/raindrop/items/1665313168/20260330T1105134.cfdb2214148836bd53f94ba160a8daaf96a0f4cb42232ceebe6f99a09f1609fc.md)

NVIDIA 도메인 특화 임베딩 자료는 합성 데이터 생성, 파인튜닝, 평가, 배포를 하루 안에 수행하는 파이프라인을 설명한다. 원문 메모는 범용 임베딩 모델이 계약서, 제조 로그, 사내 용어 같은 특수 도메인에서 약할 때, 자체 문서 기반 합성 데이터로 검색 품질을 개선하는 접근을 강조한다. [raw](../raw/raindrop/items/1653039860/20260326T0018359.6ea1dba1835f735524a6a5db7dd8680e1fa61fdc0ddddf398b9155ed0e2276cd.md)

## 같이 보기

- [AI 에이전트 도구와 인프라](ai-agent-tools-and-infrastructure.md)
- [LLM 라우팅과 비용 최적화](llm-routing-and-cost-optimization.md)
- [AI 에이전트 하네스와 작업 흐름](ai-agent-harness-and-workflows.md)

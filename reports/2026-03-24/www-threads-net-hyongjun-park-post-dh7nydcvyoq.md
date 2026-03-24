---
title: "www.threads.net @hyongjun.park post DH7nYDCvYOQ"
url: "https://www.threads.net/@hyongjun.park/post/DH7nYDCvYOQ"
source_url: "https://www.threads.net/@hyongjun.park/post/DH7nYDCvYOQ"
date: "2026-03-24"
collection: "아티펙트"
tags: ["academic", "paper-figure", "ai-generation", "mcp", "claude-code"]
verification: "passed"
raindrop_id: 1654197803
---

## 요약
llmsresearch/paperbanana는 Google Research의 학술 논문(arXiv:2601.23265)을 기반으로 한 오픈소스 구현체로, Retriever·Planner·Stylist·Visualizer·Critic 5개 전문 에이전트가 협업하여 출판 수준의 학술 그림과 다이어그램을 자동 생성한다. Matplotlib 실행 코드를 직접 생성하는 방식으로 수치 환각 문제를 원천 차단하며, 색상·타이포그래피·간격 등 심미적 요소도 자동으로 최적화한다. MCP 서버(generate_diagram, generate_plot, evaluate_diagram)와 3개의 Claude Code 스킬로 즉시 통합 가능하다. NeurIPS 2025 논문 292개로 구성된 PaperBananaBench에서 충실성·간결성·가독성·심미성 모든 차원에서 기존 기준선을 능가했다. OpenAI, Azure, Google Gemini 등 다양한 LLM 공급자를 지원한다.

## 인사이트
그림 제작이라는 연구 워크플로우의 병목을 자동화하여 AI 과학자 시스템의 완성도를 높이는 핵심 구성 요소다. `claude mcp add paperbanana` 명령 한 줄로 Claude Code에 통합 가능하므로, 논문 집필 중인 연구자가 즉시 실무에 활용할 수 있는 실질적 가치가 높다.

## 실체 검증 결과
- "GitHub 저장소 llmsresearch/paperbanana가 존재하며, 반복적 비평/정제 루프로 학술 논문 그림을 자동 생성한다" -> verified (출처: https://github.com/llmsresearch/paperbanana, https://huggingface.co/papers/2601.23265)
- "Google Research의 PaperBanana 논문(arXiv:2601.23265)을 기반으로 한 오픈소스 구현체이며 Claude Code 스킬로 통합 가능하다" -> verified (출처: https://github.com/llmsresearch/paperbanana, https://dwzhu-pku.github.io/PaperBanana/, https://skillsllm.com/skill/paperbanana)

## 관련 링크
- https://github.com/llmsresearch/paperbanana
- https://github.com/dwzhu-pku/PaperBanana
- https://huggingface.co/papers/2601.23265
- https://paper-banana.org/

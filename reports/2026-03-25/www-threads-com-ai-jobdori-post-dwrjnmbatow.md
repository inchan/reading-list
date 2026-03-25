---
title: "www.threads.com @ai_jobdori post DWRJnMBATOW"
url: "https://www.threads.com/@ai_jobdori/post/DWRJnMBATOW?xmt=AQF0dpClr679ZzA5GSzDV2h0WoCg7m1ckiCPfpLXouVKc_6ms6XAMggvM7mtsQgwhYPDTpEW&slof=1"
source_url: "https://www.threads.com/@ai_jobdori/post/DWRJnMBATOW?xmt=AQF0dpClr679ZzA5GSzDV2h0WoCg7m1ckiCPfpLXouVKc_6ms6XAMggvM7mtsQgwhYPDTpEW&slof=1"
date: "2026-03-25"
collection: "지식"
tags: ["ai", "ai-agent", "harness-engineering", "ai-dev", "openclaw", "context-engineering"]
verification: "passed"
raindrop_id: 1656198177
---

## 요약
GitAgent는 AI 에이전트 개발의 프레임워크 파편화 문제를 해결하기 위해 2026년 3월 공개된 오픈소스 표준이다. Git 저장소 내 agent.yaml, SOUL.md, DUTIES.md, rules/ 등의 파일로 에이전트를 정의하면, LangChain·AutoGen·CrewAI·OpenAI Assistants·Claude Code 등 5개 주요 프레임워크로 내보내기가 가능하다. Docker가 컨테이너 실행 환경을 표준화했듯, GitAgent는 에이전트 '정의' 자체를 프레임워크에 무관한 공통 포맷으로 표준화한다. Git의 브랜치·PR·diff 기능을 그대로 활용해 에이전트 행동 변화를 코드 리뷰하듯 관리할 수 있으며 롤백도 가능하다. 금융·법률 등 규제 산업을 위한 역할 분리(Segregation of Duties) 컴플라이언스 기능도 내장되어 있다.

## 인사이트
에이전트 정의를 특정 프레임워크에서 분리한다는 발상은 팀이 기술 스택을 변경할 때의 전환 비용을 획기적으로 낮춰준다. SOUL.md/DUTIES.md 같은 파일 기반 에이전트 설계는 harness-engineering의 연장선으로, 프롬프트와 가드레일을 버전 관리하는 실무에 즉시 적용 가능하다. 멀티에이전트 구성과 컴플라이언스 검증을 CLI 하나로 처리한다는 점도 엔터프라이즈 도입 장벽을 낮추는 요인이다.

## 실체 검증 결과
- "GitAgent는 GitHub에 실제 존재하는 오픈소스 프로젝트이다 (github.com/open-gitagent/gitagent)" -> verified (출처: https://github.com/open-gitagent/gitagent, https://www.marktechpost.com/2026/03/22/meet-gitagent-the-docker-for-ai-agents-that-is-finally-solving-the-fragmentation-between-langchain-autogen-and-claude-code/)
- "GitAgent는 agent.yaml, SOUL.md, DUTIES.md, rules/ 구조로 에이전트를 정의하며 LangChain, AutoGen, CrewAI, OpenAI Assistants, Claude Code 등 다수 프레임워크로 내보내기 가능하다" -> verified (출처: https://earezki.com/ai-news/2026-03-22-meet-gitagent-the-docker-for-ai-agents-that-is-finally-solving-the-fragmentation-between-langchain-autogen-and-claude-code/, https://www.junia.ai/blog/gitagent-git-native-ai-agent-standard)

## 관련 링크
- https://github.com/open-gitagent/gitagent
- https://www.marktechpost.com/2026/03/22/meet-gitagent-the-docker-for-ai-agents-that-is-finally-solving-the-fragmentation-between-langchain-autogen-and-claude-code/

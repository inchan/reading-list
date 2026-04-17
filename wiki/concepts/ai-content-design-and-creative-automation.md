---
title: AI 콘텐츠, 디자인, 문서 자동화
created: 2026-04-18
updated: 2026-04-18
type: concept
sources:
  - wiki/raw/raindrop/items/1681636032/20260412T1039031.1e6976bc73f311d175fb559a68f963098790888aa8376991b95679c79b232b49.md
  - wiki/raw/raindrop/items/1678674241/20260410T1055066.85b4e57c7be41d0dcba8f9e4d0c743c7e3a961e38183568e6e1891eb4312c5e0.md
  - wiki/raw/raindrop/items/1656199029/20260326T0750315.d619c856f58f83888672d8220a9b7370f74897916cceb79343f3488227cc9896.md
  - wiki/raw/raindrop/items/1654197803/20260326T0018449.3819b5b79e6eff94d1f8fdf3f67b40ce1130e4c5b821b5a45077d093089f5120.md
  - wiki/raw/raindrop/items/1649221150/20260326T0018154.4ef05e9d7452ea328c928400e2d478db2df67a9bf0d878d30fb752882df7d515.md
  - wiki/raw/raindrop/items/1649220971/20260326T0018127.852aaffd86061ee5595527d1f89fcb44f093676d7db1bb2f5d575b79b84e1464.md
  - wiki/raw/raindrop/items/1649177570/20260326T0018070.b62ea4daef29f2b0268ab74c520f17154b680931c8d47aca3fcab0c7aaed671b.md
  - wiki/raw/raindrop/items/1649177433/20260326T0018045.cd808975934e48ca0b854d84df6495563da910f69c18ee9ec63d961a9c2a5531.md
source_ids:
  - "raindrop:1681636032"
  - "raindrop:1678674241"
  - "raindrop:1656199029"
  - "raindrop:1654197803"
  - "raindrop:1649221150"
  - "raindrop:1649220971"
  - "raindrop:1649177570"
  - "raindrop:1649177433"
tags: [ai-design, content-automation, video, prompt, document-ai]
---

# AI 콘텐츠, 디자인, 문서 자동화

디자인과 콘텐츠 자동화 소스는 "AI에게 감각을 기대하기보다, 디자인 데이터와 평가 루프를 더 명확히 준다"는 방향으로 수렴한다. 디자인 시스템, 픽셀 diff, 3D 공간 시뮬레이션, 학술 그림 생성, 숏폼 영상 자동화, 이미지 프롬프트 자료를 함께 보존한다.

## 디자인 데이터와 검증

Awesome Design MD는 Apple, Spotify, Stripe, IBM, NVIDIA 등 여러 브랜드의 디자인 시스템을 DESIGN.md 형태로 정리해 색상, 폰트, 간격, 버튼, 레이아웃 수치를 AI에게 제공한다는 소개다. 정답이 모호한 디자인 작업을 명시적 스펙으로 바꾸는 접근이다. [raw](../raw/raindrop/items/1681636032/20260412T1039031.1e6976bc73f311d175fb559a68f963098790888aa8376991b95679c79b232b49.md)

Figma 복제 스레드는 정확한 디자인 데이터 전달과 자동 검증 루프를 결합해 원본과 구현 화면의 픽셀 차이를 줄이는 방식을 소개한다. 원문은 Saqoosha 사례를 언급하며 배경 일치율 수치를 제시하지만, 여기서는 픽셀 diff 루프라는 운영 패턴만 핵심으로 남긴다. [raw](../raw/raindrop/items/1678674241/20260410T1055066.85b4e57c7be41d0dcba8f9e4d0c743c7e3a961e38183568e6e1891eb4312c5e0.md)

아키스케치 소스는 주소 검색으로 아파트 3D 도면을 불러오고 실제 판매 가구를 배치하는 프롭테크/인테리어 시뮬레이션 사례다. 원문은 전국 아파트 도면 DB, 오늘의집 3D 인테리어 서비스 적용, 커머스 연결을 강조한다. [raw](../raw/raindrop/items/1656199029/20260326T0750315.d619c856f58f83888672d8220a9b7370f74897916cceb79343f3488227cc9896.md)

## 학술 그림과 문서 시각화

paperbanana는 Retriever, Planner, Stylist, Visualizer, Critic 같은 전문 에이전트가 협력해 논문용 그림과 다이어그램을 생성하는 오픈소스 구현체로 정리된다. Matplotlib 실행 코드를 생성해 수치 환각을 줄이고, MCP 서버와 Claude Code 스킬로 연결할 수 있다는 점이 실무적으로 중요하다. [raw](../raw/raindrop/items/1654197803/20260326T0018449.3819b5b79e6eff94d1f8fdf3f67b40ce1130e4c5b821b5a45077d093089f5120.md)

## 이미지와 영상 프롬프트

Midjourney 사막 인물 프롬프트와 Higgsfield weird angle prompt pack은 창작용 프롬프트 레퍼런스다. 둘 다 원문에서 프롬프트나 외부 첨부를 가리키므로, 상세 프롬프트는 원문 확인 후 보강한다. [raw](../raw/raindrop/items/1649221150/20260326T0018154.4ef05e9d7452ea328c928400e2d478db2df67a9bf0d878d30fb752882df7d515.md) [raw](../raw/raindrop/items/1649220971/20260326T0018127.852aaffd86061ee5595527d1f89fcb44f093676d7db1bb2f5d575b79b84e1464.md)

AI 숏츠 자동화 두 소스는 주제 입력 후 Gemini 기반 대본 생성, TTS 나레이션, 자막, 배경, 음악, 업로드까지 이어지는 숏폼 제작 파이프라인을 소개한다. 하나는 무료 구성 요소(Gemini 무료 티어, edge-tts, ffmpeg)를, 다른 하나는 v2.1.0의 리서치, 비주얼, 보이스오버, 단어별 하이라이트 자막, 자동 음악 볼륨 조절 흐름을 강조한다. [raw](../raw/raindrop/items/1649177570/20260326T0018070.b62ea4daef29f2b0268ab74c520f17154b680931c8d47aca3fcab0c7aaed671b.md) [raw](../raw/raindrop/items/1649177433/20260326T0018045.cd808975934e48ca0b854d84df6495563da910f69c18ee9ec63d961a9c2a5531.md)

## 같이 보기

- [AI 에이전트 하네스와 작업 흐름](ai-agent-harness-and-workflows.md)
- [지식 그래프, RAG, 문서 AI 워크플로우](knowledge-graph-rag-and-document-ai.md)

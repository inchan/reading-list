# Hermes LLM Wiki Alignment Notes

## Purpose

해르메스 LLM 위키 시스템과 현재 reading-list wiki를 비교해,
무엇이 이미 맞고 무엇을 보강해야 하는지 정리한 메모.

---

## What reading-list already had

reading-list는 이미 아래 핵심 뼈대를 갖고 있었다.

- `wiki/SCHEMA.md`
- `wiki/index.md`
- `wiki/log.md`
- `wiki/raw/...` 와 compiled page 분리
- Korean-first wiki writing rule
- raw immutability
- provenance-preserving compiled pages

즉 구조적으로는 Hermes-style LLM wiki와 큰 차이가 없다.

---

## Main gaps found

차이는 구조보다는 운영 성숙도에 있었다.

### 1. Taxonomy governance was still draft-level
- primary/detail/status 축이 문서 초안에만 있었고 schema에 완전히 통합되지 않았음
- canonical tag / alias / promotion / downgrade 규칙이 약했음

### 2. Orientation rule was implicit, not explicit
- 기존 위키를 다루기 전에 `SCHEMA → index → recent log`를 읽는 절차가 약했음

### 3. Cross-link and lint loop were under-specified
- orphan/broken/index/frontmatter/tag audit를 정기 유지보수 규칙으로 충분히 못 박지 않았음

### 4. Contradiction handling and page thresholds were light
- 언제 새 페이지를 만들고, 언제 기존 페이지를 업데이트하고, 언제 review로 보내는지의 기준이 더 필요했음

---

## Applied changes

이번 정리에서 reading-list에 아래를 반영했다.

### A. `wiki/SCHEMA.md` upgraded
추가된 내용:
- session orientation rule
- expanded frontmatter
- 3-layer taxonomy model
- autonomous taxonomy policy
- page thresholds
- contradiction handling
- stronger cross-link requirement
- lint / maintenance loop

### B. Tag normalization policy upgraded
`docs/tag-audit/tag-normalization.md`를 아래 방향으로 재정리했다.
- 사람 승인 없는 LLM-managed taxonomy
- canonicalization rules
- status/topic separation
- category promotion / downgrade rules
- taxonomy와 cross-link/lint의 연결

### C. Comparison note preserved
이 메모 자체를 남겨서, 앞으로 왜 이 운영규칙이 들어왔는지 repo 안에서 다시 추적할 수 있게 했다.

---

## Guiding principle

reading-list의 방향은 **갈아엎기**가 아니다.

> 이미 맞게 만들어진 LLM wiki 초안을
> 운영형 LLM wiki로 승격하는 것

즉:
- 구조는 유지하고
- taxonomy와 maintenance loop를 강화한다.

---

## Expected effects

이 정리가 잘 작동하면 앞으로는:

- 태그 중복과 표기 흔들림이 줄고
- sparse/raw-only 항목이 주제 taxonomy를 오염시키지 않으며
- 새 문서가 고립되지 않고 연결되며
- wiki가 커질수록 오히려 더 탐색 가능해진다.

#!/usr/bin/env bash
# autoresearch 메트릭: 파이프라인 점수 (0-100)
# 구성: 실행시간(40) + 코드품질(30) + 코드크기(30)
set -euo pipefail

MEASURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${MEASURE_DIR}/.."

# --- 1. 실행시간 점수 (40점) ---
# 스크립트 파싱 + dry-run 속도 측정 (API 호출 제외)
start_time=$(python3 -c "import time; print(int(time.time()*1000))")

# bash 문법 검증 (모든 스크립트)
for f in "$MEASURE_DIR"/*.sh "$MEASURE_DIR"/lib/*.sh; do
  bash -n "$f" 2>/dev/null || true
done

# jq 처리 속도 측정 (대표 작업)
if [ -f "$PROJECT_ROOT/config/settings.json" ]; then
  jq '.' "$PROJECT_ROOT/config/settings.json" > /dev/null 2>&1
fi
if [ -f "$PROJECT_ROOT/config/blocked-domains.json" ]; then
  jq '.' "$PROJECT_ROOT/config/blocked-domains.json" > /dev/null 2>&1
fi
if [ -f "$PROJECT_ROOT/config/collections.json" ]; then
  jq 'length' "$PROJECT_ROOT/config/collections.json" > /dev/null 2>&1
fi

end_time=$(python3 -c "import time; print(int(time.time()*1000))")
elapsed_ms=$(( end_time - start_time ))

# 100ms 이하 = 만점, 500ms 이상 = 0점
if [ "$elapsed_ms" -le 100 ]; then
  time_score=40
elif [ "$elapsed_ms" -ge 500 ]; then
  time_score=0
else
  time_score=$(( 40 - (elapsed_ms - 100) * 40 / 400 ))
fi

# --- 2. 코드품질 점수 (30점) ---
# shellcheck 경고 수 (설치되어 있으면)
warning_count=0
if command -v shellcheck &>/dev/null; then
  warning_count=$(shellcheck -S warning "$MEASURE_DIR"/*.sh "$MEASURE_DIR"/lib/*.sh 2>/dev/null | grep -c "^In " || echo 0)
fi

# 경고 0개 = 만점, 10개 이상 = 0점
if [ "$warning_count" -le 0 ]; then
  quality_score=30
elif [ "$warning_count" -ge 10 ]; then
  quality_score=0
else
  quality_score=$(( 30 - warning_count * 3 ))
fi

# --- 3. 코드크기 점수 (30점) ---
# 총 줄 수 (짧을수록 좋음, 중복 제거 효과 측정)
# measure-score.sh 자체는 제외
total_lines=$(find "$MEASURE_DIR" "$MEASURE_DIR/lib" -maxdepth 1 -name '*.sh' ! -name 'measure-score.sh' -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')

# 400줄 이하 = 만점, 700줄 이상 = 0점
if [ "$total_lines" -le 400 ]; then
  size_score=30
elif [ "$total_lines" -ge 700 ]; then
  size_score=0
else
  size_score=$(( 30 - (total_lines - 400) * 30 / 300 ))
fi

# --- 최종 점수 ---
total_score=$((time_score + quality_score + size_score))

echo "time=${elapsed_ms}ms(${time_score}) quality=${warning_count}warns(${quality_score}) size=${total_lines}lines(${size_score}) total=${total_score}"
echo "$total_score"

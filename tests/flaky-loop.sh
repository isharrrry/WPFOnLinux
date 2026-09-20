#!/usr/bin/env bash
# 循环跑测试套件 N 轮，统计失败轮次与失败用例名。
#
# 用法：
#   tests/flaky-loop.sh [轮数] [测试项目路径] [日志目录]
#
# 约束（handoff 并发约定）：
#   * 一律不带 --artifacts-path —— 各测试项目的 RepoLayout 靠 AppContext.BaseDirectory
#     定位仓库根，改路径会造成大面积假失败。
#   * 遇文件锁：dotnet build-server shutdown 后重试 2 次。

set -uo pipefail

ROUNDS="${1:-20}"
PROJ="${2:-tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj}"
LOGDIR="${3:-/tmp/flaky-$(date +%Y%m%d-%H%M%S)}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p "$LOGDIR"

: > "$LOGDIR/failed-tests.txt"
: > "$LOGDIR/summary.txt"

fail_rounds=0

for i in $(seq 1 "$ROUNDS"); do
  log="$LOGDIR/round-$(printf '%02d' $i).log"

  # 单轮：先尝试，失败再考虑文件锁重试（构建失败也重试，dotnet 常见 MSB3021/3027）
  attempt=0
  while :; do
    attempt=$((attempt + 1))
    dotnet test "$PROJ" --nologo -v normal > "$log" 2>&1
    rc=$?
    if [ $rc -eq 0 ] || [ $attempt -ge 3 ]; then break; fi
    if grep -qE "MSB3021|MSB3027|being used by another process|FileNotFoundException.*dll" "$log"; then
      echo "round $i attempt $attempt: 文件锁，build-server shutdown 后重试" >> "$LOGDIR/summary.txt"
      dotnet build-server shutdown > /dev/null 2>&1
      sleep 2
      continue
    fi
    break
  done

  # 解析 "Failed!  - Failed:     2, Passed:   319, ..." 或 "Passed!  - Failed: 0, ..."
  line="$(grep -oE '(Passed|Failed)![[:space:]]*-[[:space:]]*Failed:[[:space:]]*[0-9]+,[[:space:]]*Passed:[[:space:]]*[0-9]+.*' "$log" | tail -1)"

  if [ $rc -ne 0 ] || echo "$line" | grep -q "^Failed!"; then
    fail_rounds=$((fail_rounds + 1))
    # 失败用例名：xunit console 输出形如
    #   "  Failed WpfGfx.Linux.Tests.Commands.X.Y [3 ms]"
    names="$(grep -oE '^\s*(Failed|X) [^ ]+' "$log" | sed -E 's/^\s*(Failed|X) //' | sort -u)"
    {
      echo "=== round $i (rc=$rc) ==="
      echo "$names"
      echo "--- 断言/异常消息 ---"
      grep -E '^\s*(Assert|Actual|Expected|Message|Stack Trace|.*Exception)' "$log" | head -20
      echo
    } >> "$LOGDIR/failed-tests.txt"
    echo "round $(printf '%02d' $i): ❌ 失败  $line"
  else
    echo "round $(printf '%02d' $i): ✅ 通过  $line"
  fi
  echo "round $(printf '%02d' $i) rc=$rc :: $line" >> "$LOGDIR/summary.txt"
done

echo
echo "================ 汇总 ================"
echo "轮数: $ROUNDS   失败轮次: $fail_rounds"
echo "日志目录: $LOGDIR"
if [ -s "$LOGDIR/failed-tests.txt" ]; then
  echo "--- 失败用例出现次数 ---"
  grep -oE '^\s*(Failed|X) [^ ]+' "$LOGDIR"/round-*.log 2>/dev/null \
    | sed -E 's/^.*round-[0-9]+\.log:\s*(Failed|X) //' | sort | uniq -c | sort -rn
else
  echo "20 轮 0 失败。"
fi

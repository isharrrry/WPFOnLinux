#!/usr/bin/env bash
# T2b 的测试封装：**构建成功才允许跑 `--no-build`**（机器强制，不靠纪律）。
#
# 【为什么存在这个脚本】本会话里同一个坑踩了**三次**：
#   改了源码 → 构建**失败**（或改了不该改的、或引用了不存在的成员）→ 却仍然跑 `dotnet test --no-build`
#   → 跑的是**上一次成功构建的陈旧 DLL** → 得到一组**看起来正常**的读数（"137 passed"、"1 failed"），
#   而那组读数与当前源码**毫无关系**。三次都差点被我或别人当成证据写进报告。
#   纪律（"记住先看构建输出"）挡不住它 —— 因为失败时命令**照样返回 0**、输出还很长。
#   ⇒ 改成**工具强制**：构建输出里出现任何错误 ⇒ **立刻退出**（非 0），并把日志尾巴打出来；
#     只有"构建成功 且 错误数为 0"才继续跑测试，且测试**必须**带 `--no-build` 绑到这次构建上。
#
# 【用法】
#   tests/WpfGfx.Linux.Tests/Rendering.Tests/t2b-test.sh                 # 全套件
#   tests/WpfGfx.Linux.Tests/Rendering.Tests/t2b-test.sh MatrixCompositionSpaceTests
#                                                  # 只跑 FullyQualifiedName~<参数> 的用例
#   OUT=/tmp/t2b-build/out tests/.../t2b-test.sh   # 自定义输出目录（缺省就用私有目录）
#
# 【退出码】0 = 构建 0 错且测试全绿；1 = 构建失败；2 = 构建成功但测试有失败。

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PROJ="$REPO/tests/WpfGfx.Linux.Tests/Rendering.Tests/WpfGfx.Linux.Rendering.Tests.csproj"
OUT="${OUT:-/tmp/t2b-build/out}"
FILTER="${1:-}"
LOG="$(mktemp -t t2b-build-XXXXXX.log)"

export PATH="$HOME/.dotnet:$PATH"

# 私有输出目录跑测试需要"仓库根可解析"（RepoLayout 从 AppContext.BaseDirectory 向上找 handoff.md/global.json），
# 否则渲染级用例会以 DirectoryNotFoundException **假红**（本会话踩过：33 条 golden 假红 + 27 跳过）。
if [ "$OUT" = "/tmp/t2b-build/out" ]; then
    mkdir -p /tmp/t2b-build
    : > /tmp/t2b-build/handoff.md
    [ -e /tmp/t2b-build/build ] || ln -sfn "$REPO/build" /tmp/t2b-build/build
    [ -e /tmp/t2b-build/tests ] || ln -sfn "$REPO/tests" /tmp/t2b-build/tests
fi

echo "[t2b-test] 构建（-m:1，输出 $OUT）…"
dotnet build "$PROJ" -o "$OUT" -m:1 -v:m > "$LOG" 2>&1
BUILD_RC=$?
ERRORS="$(grep -cE ' error [A-Z]+[0-9]+' "$LOG")"

if [ "$BUILD_RC" -ne 0 ] || [ "$ERRORS" -ne 0 ]; then
    echo "[t2b-test] ✗ 构建失败（rc=$BUILD_RC，错误数=$ERRORS）——**拒绝**跑 --no-build（那会跑陈旧 DLL 并产出假读数）"
    echo "----------- 构建日志尾部 -----------"
    tail -20 "$LOG"
    echo "------------------------------------"
    exit 1
fi
echo "[t2b-test] ✓ 构建成功、错误 0；现在才允许 --no-build"

if [ -n "$FILTER" ]; then
    echo "[t2b-test] 跑用例：FullyQualifiedName~$FILTER"
    dotnet test "$PROJ" -o "$OUT" --no-build --filter "FullyQualifiedName~$FILTER" 2>&1 | tail -30
    TEST_RC=${PIPESTATUS[0]}
else
    echo "[t2b-test] 跑全套件"
    dotnet test "$PROJ" -o "$OUT" --no-build 2>&1 | tail -30
    TEST_RC=${PIPESTATUS[0]}
fi

if [ "$TEST_RC" -ne 0 ]; then
    echo "[t2b-test] ✗ 测试有失败（绑定的是本次成功构建：$OUT）"
    exit 2
fi
echo "[t2b-test] ✓ 全绿（绑定的是本次成功构建：$OUT）"
exit 0

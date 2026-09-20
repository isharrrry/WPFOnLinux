#!/usr/bin/env bash
#
# 重新生成渲染层的 golden 基准图。
#
#   ./update-golden.sh                 # 全量重建
#   ./update-golden.sh --filter X      # 只重建名字含 X 的用例
#
# ⚠️ 这是**覆盖写**操作：tests/golden/*.png 会被实测图直接替换。
#    跑之前先确认 tests/artifacts/rendering/ 里的实测图是你想要的结果——
#    尤其是当这次改动本就应该改变渲染输出的时候。
#
# 更新完请：git diff --stat tests/golden 逐张看一眼，再提交。

set -euo pipefail

cd "$(dirname "$0")"

FILTER=()
if [[ $# -gt 0 ]]; then
  FILTER=(--filter "$1")
fi

echo "==> 更新 golden 基准图（WPFGOLDEN_UPDATE=1）"
echo "==> 基准图目录：$(cd ../../../golden 2>/dev/null && pwd || echo '../../../golden')"
echo

WPFGOLDEN_UPDATE=1 dotnet test "${FILTER[@]}" --logger "console;verbosity=normal"

echo
echo "==> 完成。请用 git diff 复核 tests/golden/ 后再提交。"

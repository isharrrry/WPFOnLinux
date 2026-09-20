#!/usr/bin/env bash
# T1b · 活窗口复验 + LS 绊线（HelloWpf + :98）—— 主控给的配方，四个坑全部照做
# ============================================================================
#  前置：**主控已重建 PC**（带上 B2）。本脚本会先核一遍"PC 比 shim 新"，不满足就**拒绝跑**
#       （免得拿旧 PC 白跑一轮 —— 那是主控点名的浪费）。
#
#  主控实测踩出来的四个坑（逐条照做）：
#    1. `HLWPF_UI_FONT=$PWD/build/fonts-ui/UI-NoLayout.ttf` **必须设**：不设字体 env 时文字整段
#       不画（`未画种类 1`），LS 根本走不到 ⇒ 测了等于没测。
#    2. `M7C_RUN_DIR` **必须自设**（默认目录会被并发运行互相覆盖）。
#    3. 必须用**同目录快照**跑 `run-hellowpf.sh`（该脚本属于别的 agent 且正在被改）。
#    4. 收尾用 `kill $XPID`，**绝不**用 `pkill -f 'Xvfb :98'`（会匹配到自己的命令行）。
#
#  产物：<outdir>/live-window.txt（含 HLWPF 原始输出尾部 + 计数器汇总行 + LS 绊线统计）
#  用法：bash build/MilBridge/tools/t1b-live-window.sh [outdir] [帧数]
# ============================================================================
set -uo pipefail

ROOT=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
OUT="${1:-/tmp/t1b-live-window}"
FRAMES="${2:-20}"
SHIM="$ROOT/build/shims/PresentationCore.HbTextLine.cs"
PCDLL="$ROOT/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll"
D="$ROOT/tests/WpfGfx.Linux.Tests/Presentation.Tests"

mkdir -p "$OUT"

echo "== T1b · 活窗口复验（HelloWpf）+ LS 绊线 =="
echo "shim : $SHIM  ($(date -r "$SHIM" +%F\ %T), $(wc -l < "$SHIM") 行)"
echo "PC   : $PCDLL  ($(date -r "$PCDLL" +%F\ %T))"

# ---- 前置：PC 必须是**带 B2 重建过**的（PC 比 shim 新）----
if [ ! -f "$PCDLL" ]; then echo "[拒绝跑] 找不到 PC dll：$PCDLL"; exit 3; fi
if [ "$SHIM" -nt "$PCDLL" ]; then
  if [ "${T1B_ALLOW_STALE_PC:-0}" = "1" ]; then
    echo "[前置·警告] PC 比当前 shim **旧**，但 T1B_ALLOW_STALE_PC=1 ⇒ 继续。"
    echo "             仅当'这之后只落过与本次目的无关的改动'时才允许（例如只改了折叠明细）。"
  else
    echo "[拒绝跑] PC 比 shim **旧** ⇒ 主控还没重建 PC（拿旧 PC 跑等于测了旧版，白跑）。"
    echo "         等主控起波重建后再跑；确要跑请显式 T1B_ALLOW_STALE_PC=1。"
    exit 3
  fi
else
  echo "[前置] PC 比 shim 新 ✓（可以跑）"
fi

# LD_DEBUG=symbols 对 .NET 进程是**巨量 I/O**（实测能把 HelloWpf 拖到超时）⇒ 日志放 tmpfs
LDDBG_DIR="${T1B_LDDEBUG_DIR:-/dev/shm/t1b-lddebug}"
mkdir -p "$LDDBG_DIR"

# ---- 快照（坑 3）----
SNAP="$D/.t1b-snapshot.sh"
cp -f "$D/run-hellowpf.sh" "$SNAP"
bash -n "$SNAP" || { echo "[失败] 快照脚本语法错"; rm -f "$SNAP"; exit 4; }
trap 'rm -f "$SNAP"' EXIT

# ---- Xvfb :98（只用 :98）----
setsid Xvfb :98 -screen 0 1280x1024x24 -nolisten tcp >/tmp/xvfb98.log 2>&1 </dev/null &
XPID=$!
sleep 3
trap 'rm -f "$SNAP"; kill $XPID 2>/dev/null' EXIT   # 坑 4：kill $XPID，不用 pkill

# ---- 跑（坑 1 & 2）+ LS 绊线（ld.so 的 LD_DEBUG=symbols）----
export WPF_LINUX_TEXTLINE=1
export WPF_LINUX_TEXTLINE_DUMP="$OUT/hbtextline-dump.txt"
export WPF_LINUX_TEXTLINE_DIAG=1
: > "$WPF_LINUX_TEXTLINE_DUMP"
(
  cd "$ROOT"
  DISPLAY=:98 M7C_RUN_DIR="$OUT/m7c" \
  HLWPF_UI_FONT="$ROOT/build/fonts-ui/UI-NoLayout.ttf" \
  T1B_LDDEBUG_DIR="$LDDBG_DIR" timeout "${T1B_TIMEOUT:-300}" \
    bash "$ROOT/build/MilBridge/tools/t1b-ls-tripwire.sh" "$OUT" -- \
    bash "$SNAP" "$FRAMES" --no-build
) > "$OUT/live-window.txt" 2>&1
RC=$?
echo "HLWPF 退出码 = $RC" | tee -a "$OUT/live-window.txt"

echo
echo "---- 计数器汇总行（每次进程退出追加）----"
cat "$WPF_LINUX_TEXTLINE_DUMP" 2>/dev/null | tail -3

echo
echo "---- LS 绊线（ld.so 日志）----"
sed -n '/LS 家族符号被查找/,/^$/p' "$OUT/ls-tripwire.txt" 2>/dev/null
grep -E "LoAcquireBreakRecord|LoCreateLine|LoCreateContext|LoDisposeBreakRecord" "$OUT/ls-tripwire.txt" 2>/dev/null

echo
echo "---- HelloWpf 尾部 ----"
tail -25 "$OUT/live-window.txt"
echo
echo "产物：$OUT/live-window.txt  $OUT/ls-tripwire.txt  $OUT/hbtextline-dump.txt"
exit $RC

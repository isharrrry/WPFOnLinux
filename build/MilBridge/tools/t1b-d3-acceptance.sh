#!/usr/bin/env bash
# T1b/D3 · 波后验收（一键，带 sha；最小可判据 = T3 给的 --text-volume=N 阈值翻转）
# ============================================================================
#  判据（主控 2026-09-11 定，数字不是感觉）：
#    0) 波确实编进了 D3：PC.dll 里出现 `HbTextFallback`（波 9 时实测 0 命中）
#    1) `text-volume=2/3` **不再 abort**（接线前 3/3 abort，`blocker=lineservices:LoCreateContext`）
#    2) `LoCreateContext` 查找数 **27 → 0**（`N=1` 档接线前就是 0，作为阳性对照）
#    3) HelloWpf 不退步：`未画种类 0` / PNG 字节数与基线一致；`LoAcquireBreakRecord`/`LoCreateLine` 保持 0 查找
#    4) `HB_TEXTLINE` 汇总行的 `fallbackCalls/Handled/Bailed/…/lastBail` 原始读数
#  用法：bash build/MilBridge/tools/t1b-d3-acceptance.sh [outroot]
#  ⚠️ 只在 `.wave-done` 在时跑（否则 PC 还是旧版，白跑 —— 主控点名的浪费）
# ============================================================================
set -uo pipefail

ROOT=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
OUT="${1:-/tmp/t1b-d3-accept}"
SHIM="$ROOT/build/shims/PresentationCore.HbTextLine.cs"
PCDLL="$ROOT/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll"
D="$ROOT/tests/WpfGfx.Linux.Tests/Presentation.Tests"

mkdir -p "$OUT"
echo "== T1b/D3 · 波后验收 =="
[ -f "$ROOT/build/.wave-done" ] || { echo "[拒绝跑] 没有 build/.wave-done ⇒ 波没跑完/没起（PC 是旧版）"; exit 3; }

SHIM_SHA=$(sha256sum "$SHIM" | cut -d' ' -f1)
PC_SHA=$(sha256sum "$PCDLL" | cut -d' ' -f1)
echo "shim : build/shims/PresentationCore.HbTextLine.cs  sha256=$SHIM_SHA  ($(wc -l < "$SHIM") 行)"
echo "PC   : build/PresentationCore.Linux/bin/Debug/PresentationCore.dll  sha256=$PC_SHA  ($(date -r "$PCDLL" +%F\ %T))"
HBF=$(strings "$PCDLL" | grep -c "HbTextFallback" || true)
echo "判据0: PC.dll 里 'HbTextFallback' 命中 = $HBF （波 9 实测 0；≥1 ⇒ D3 真的编进去了）"
[ "$HBF" -ge 1 ] || { echo "[停止] D3 没编进 PC —— 后面的验收无意义"; exit 4; }

# 快照（坑 3：run-wpftextdemo.sh 属于别的 agent 且可能正在被改）
SNAP_TD="$D/.t1b-td-snap.sh"; SNAP_HW="$D/.t1b-hw-snap.sh"
cp -f "$D/run-wpftextdemo.sh" "$SNAP_TD"; cp -f "$D/run-hellowpf.sh" "$SNAP_HW"
bash -n "$SNAP_TD" && bash -n "$SNAP_HW" || { echo "[失败] 快照语法错"; rm -f "$SNAP_TD" "$SNAP_HW"; exit 4; }
trap 'rm -f "$SNAP_TD" "$SNAP_HW"; kill $XPID 2>/dev/null' EXIT

setsid Xvfb :98 -screen 0 1280x1024x24 -nolisten tcp >/tmp/xvfb98-acc.log 2>&1 </dev/null &
XPID=$!
sleep 3

# ---------- 判据 1/2：text-volume 阈值翻转 + LoCreateContext 查找数 ----------
for N in 1 2 3; do
  R="$OUT/vol$N"; mkdir -p "$R"
  echo
  echo "──── text-volume=$N ────"
  T1B_LDDEBUG_DIR="/dev/shm/t1b-ld-vol$N" timeout 300 \
    bash "$ROOT/build/MilBridge/tools/t1b-ls-tripwire.sh" "$R" -- \
    env DISPLAY=:98 M7C_RUN_DIR="$R/m7c" \
    timeout 120 bash "$SNAP_TD" --tier minimal --app-args="--text-volume=$N" > "$R/run.txt" 2>&1
  grep -E "WPTD_TIER=|WPTD_ARTIFACTS" "$R/run.txt" | tail -2
  grep -E "LoCreateContext:|LoAcquireBreakRecord:|LoCreateLine:" "$R/ls-tripwire.txt" 2>/dev/null | sed 's/^/   /'
done

# ---------- 判据 3：HelloWpf 不退步 ----------
echo
echo "──── HelloWpf（不退步判据：未画种类 0 / PNG 字节数 / LS 零查找）────"
RH="$OUT/hellowpf"; mkdir -p "$RH"
echo "HelloWpf" >/dev/null
: > "$OUT/hbtextline-dump.txt"
(
  cd "$ROOT"
  WPF_LINUX_TEXTLINE=1 WPF_LINUX_TEXTLINE_DUMP="$OUT/hbtextline-dump.txt" WPF_LINUX_TEXTLINE_DIAG=1 \
  T1B_LDDEBUG_DIR=/dev/shm/t1b-ld-hw timeout 300 \
  bash "$ROOT/build/MilBridge/tools/t1b-ls-tripwire.sh" "$RH" -- \
    env DISPLAY=:98 M7C_RUN_DIR="$RH/m7c" HLWPF_UI_FONT="$ROOT/build/fonts-ui/UI-NoLayout.ttf" \
    timeout 120 bash "$SNAP_HW" 20 --no-build
) > "$RH/run.txt" 2>&1
grep -E "未画种类|PNG" "$RH/run.txt" | tail -4
grep -E "LoCreateContext:|LoAcquireBreakRecord:|LoCreateLine:" "$RH/ls-tripwire.txt" 2>/dev/null | sed 's/^/   /'

# ---------- 判据 4：HB_TEXTLINE 汇总行 ----------
echo
echo "──── 判据4：HB_TEXTLINE 汇总行（HelloWpf 进程退出时落盘）────"
tail -2 "$OUT/hbtextline-dump.txt" 2>/dev/null || echo "(没有 dump —— HelloWpf 没跑到退出，或有别的问题)"

# ---------- 判据 5：登记差异仍保留红 ----------
echo
echo "──── 判据5：登记差异仍保留红（harness 退出码应有意非 0）────"
timeout 1200 bash "$ROOT/build/MilBridge/run.sh" tline 2>&1 | grep -E "T0\.6|T1\.73|折叠判定|通过 |❌ T2|❌ T3|❌ T2b|❌ T2c" | head -12

echo
echo "== 验收产物：$OUT/（vol1|vol2|vol3|hellowpf 各含 run.txt 与 ls-tripwire.txt）=="
echo "shim_sha=$SHIM_SHA  pc_sha=$PC_SHA  HbTextFallback_hits=$HBF"

#!/usr/bin/env bash
# T1d · R1（run 级字体 + 按码点覆盖回退 + 多字体整形）的**可复现读数装置**
# ============================================================================
# 它跑什么（**不重建 PC、不碰别人的车道**）：
#   驱动 `build/MilBridge/tests/CoverageProbe/`（编的是**真 shim 源**、走**应用路径**
#   `HbTextFallback.TryFormatLine`），在四个档位上各出一份读数 + 逐 run 的面明细。
#
# 四个档位（每一档的**期望**都写在下面；"达不到"的档**如实报红**，不假装可达）：
#   ① default      ：系统字体（`/usr/share/fonts`）⇒ **R1 应当真出 CJK**（id0=0 / nonlatin>0）
#   ② ab-off       ：`WPF_LINUX_MULTIFONT=0` ⇒ **必须与今天逐位相同**（id0>0 / nonlatin=0 / 计数器"无信息"）
#   ③ two-run      ：假 TextSource 有 3 个 run，其中一个自带 CJK 面 ⇒ 走"候选②：其余 run 的面"
#   ④ fonts-ui     ：`WPF_LINUX_FONT_DIR=build/fonts-ui` ⇒ **结构性无解**（该集合 0 个 CJK 码点）
#                    预期 `fallbackFailed=60 / fallbackApplied=0 / id0=60 / nonlatin=0` —— 与今天相同
#
# 用法：
#   bash build/MilBridge/tools/t1d-probe.sh [outdir] [--prefix /path/to/PresentationCore.dll]
# 环境：
#   T1D_PREFIX=<PC dll>  给 CoverageProbe 换一份 PresentationCore（**不写回任何权威产物**）
# ============================================================================
set -uo pipefail

ROOT=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1

OUTDIR="${1:-/tmp/t1d-probe}"
shift || true
PROJ="$ROOT/build/MilBridge/tests/CoverageProbe"
BIN="$PROJ/bin/Release"
SHIM="$ROOT/build/shims/PresentationCore.HbTextLine.cs"
mkdir -p "$OUTDIR"

echo "== [1/3] 构建 CoverageProbe（-m:1 增量；**每次读数都附这次编译状态**）=="
( cd "$PROJ" && dotnet build -c Release -m:1 --nologo ) > "$OUTDIR/build.log" 2>&1
BUILD_RC=$?
ERRS=$(grep -cE ': error ' "$OUTDIR/build.log" || true)
WARNS=$(grep -cE ': warning ' "$OUTDIR/build.log" || true)
echo "   编译状态：**$ERRS 个错误 $WARNS 个警告**（rc=$BUILD_RC）；日志 $OUTDIR/build.log"
[ "$ERRS" -eq 0 ] || { echo "❌ 编译有错 ⇒ 后续读数一律作废（本工程栽过"build 报错、test 仍绿"）"; exit 2; }

echo "== [2/3] 被测文件与产物指纹 =="
{
    echo "== T1d CoverageProbe · $(date -Iseconds)"
    printf 'SHIM      %s sha256=%s lines=%s\n' "$SHIM" "$(sha256sum "$SHIM" | cut -d' ' -f1)" "$(wc -l < "$SHIM")"
    printf 'PROBE     %s sha256=%s\n' "$BIN/PresentationCore.Tests.dll" "$(sha256sum "$BIN/PresentationCore.Tests.dll" | cut -d' ' -f1)"
    printf 'PC        %s sha256=%s\n' "$ROOT/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll" \
        "$(sha256sum "$ROOT/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll" | cut -d' ' -f1)"
    printf 'HB        %s\n' "$(python3 - <<'PY'
import ctypes
hb=ctypes.CDLL("libharfbuzz.so.0"); hb.hb_version_string.restype=ctypes.c_char_p
print(hb.hb_version_string().decode())
PY
)"
} | tee "$OUTDIR/fingerprints.txt"

run_tier() {
    local name="$1"; shift
    echo
    echo "== [3/3] 档位 $name =="
    ( cd "$BIN" && env "$@" timeout 600 dotnet PresentationCore.Tests.dll --scenario single --width 380 ) \
        > "$OUTDIR/$name.log" 2>&1
    local rc=$?
    echo "   rc=$rc（探针自检的退出码；**各档期望见下**）"
    grep -aE '^\[T1D_PROBE\] (multifont|counters|detail)|^  (PASS|FAIL)' "$OUTDIR/$name.log" | sed 's/^/   /'
    grep -aE '^\[T1D_PROBE\]   face文件' "$OUTDIR/$name.log" | sed 's/^/   /'
}

run_tier default  WPF_LINUX_MULTIFONT=1
run_tier ab-off   WPF_LINUX_MULTIFONT=0
run_tier fonts-ui WPF_LINUX_MULTIFONT=1 WPF_LINUX_FONT_DIR="$ROOT/build/fonts-ui"

echo
echo "== [3b] two-run 档（多 run TextSource：候选②「其余 run 的面」）=="
( cd "$BIN" && WPF_LINUX_MULTIFONT=1 timeout 600 dotnet PresentationCore.Tests.dll --scenario two --width 380 ) \
    > "$OUTDIR/two-run.log" 2>&1
echo "   rc=$?"
grep -aE '^   run#|^\[T1D_PROBE\] (multifont|counters)' "$OUTDIR/two-run.log" | sed 's/^/   /'

echo
echo "==================== 期望 vs 实测（**判定留给人看，本脚本不替你判绿**）===================="
cat <<'EOF'
 ① default   期望：id0=0、nonlatin>0、maxid≈63151、chunkedLines>0、P1..P6 全 PASS
              （2026-09-11 实测 id0=0 nonlatin=58 maxid=63151 glyphRuns=18 chunkedLines=5 distinctFaces=2）
 ② ab-off    期望：**与今天逐位相同** ⇒ id0>0、nonlatin=0、计数器整段写"未使用(plan=0) **无信息**"、
              P4/P5 **红**（= 病灶可见）；且 glyph 数与 ① 相同（245）
 ③ two-run   期望：runGt1=1、fromRunFaces>0、fromSystemScan=0（候选②优先于③）
 ④ fonts-ui  期望：**结构性无解** ⇒ candidates=1、fallbackApplied=0、fallbackFailed=60、
              id0=60、nonlatin=0（**不许假装可达**）
 ⇒ 逐 run 的面明细（文件名/面下标/令牌/baseline origin/字符）在各自 log 里，用来核实"**一面一 run**"。
EOF
echo "→ 读数目录 $OUTDIR"

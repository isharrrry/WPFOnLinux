#!/usr/bin/env bash
# `textbox-edit` 近色判据的**突变自测**（"能红的牙"）—— 主控 2026-09-13 要求
#
# 【为什么需要】把 `#F97316` 的**精确色**判据换成**近色（fuzz）+ census GlyphRun** 之后，
#   必须证明这条新判据**仍然能红**，否则它可能只是"永远绿"（第 16/17 个假绿形态那一族）。
#   做法（**只动我自己的样例，改完必定还原**）：
#     ① 备份 `samples/WpfFeatureProbe/FeatureBlocks.cs`
#     ② 把 TextBox 的 `Foreground` 从测试色 `#F97316` 改成**绝不会出现的** `#010203`
#     ③ 重建样例 → 跑 `--only=textbox-edit` ⇒ **像素列必须判 FAIL**（颜色腿咬住）
#     ④ 还原文件 → 重建 → 再跑一次 ⇒ 像素列必须回到 `OK(#F97316=… ) ＋ census GlyphRun×N≥1`
#     ⑤ 任何一步失败 ⇒ 脚本退出码非 0，并把当时的 `blocks.txt` 行打出来
#
# 【纪律】一次只跑一个应用；只按 PID 收尾（Xvfb 自起自灭由 `run-wpfprobe.sh` 负责）；
#   文件还原走 `trap ... EXIT` ⇒ 即使中途 Ctrl-C 也不会把样例留在突变态。
#
# 用法：  run-wpfprobe-mutation.sh [超时秒数=45]
set -u

REPO=${REPO:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)}   # 波 `#77` 旧路径重指向：由仓根现推
TIMEOUT=${1:-45}
RUNNER="$REPO/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh"
SRC="$REPO/samples/WpfFeatureProbe/FeatureBlocks.cs"
PROJ="$REPO/samples/WpfFeatureProbe/WpfFeatureProbe.csproj"
BAK="$SRC.mutationbak"
OUTDIR="${WFP_MUTATION_DIR:-$HOME/wfp-runs/mutation}"
export PATH="$HOME/.dotnet:$PATH"
export WFP_TRIAGE=0          # 单块趟：不逐块分诊（其余 8 块构造上没构建）
export DISPLAY=:97

[ -f "$SRC" ] || { echo "❌ 找不到 $SRC" >&2; exit 2; }
[ -f "$RUNNER" ] || { echo "❌ 找不到 $RUNNER" >&2; exit 2; }
mkdir -p "$OUTDIR"

restored=0
restore() {
    [ "$restored" = "1" ] && return 0
    if [ -f "$BAK" ]; then cp -f "$BAK" "$SRC" && rm -f "$BAK" && restored=1; echo "   （已还原样例源码并存根）"; fi
}
trap restore EXIT INT TERM

echo "== textbox-edit 判据突变自测 =="
echo "   仓库=$REPO  超时=${TIMEOUT}s  loadavg=$(cut -d' ' -f1-3 /proc/loadavg)"
cp -f "$SRC" "$BAK"

echo
echo "── 极性 ①：把 Foreground 改成绝不会出现的 #010203 ⇒ 判据必须红 ──"
# 只替换 TextBox 那一处（`_tb` 的 Foreground = B(TestColor)），别的块一个字节不动
python3 - "$SRC" <<'PY'
import sys
p=sys.argv[1]; s=open(p,encoding='utf-8').read()
old="""                Text = "seed-文本", Width = 240, Height = 24,
                Foreground = B(TestColor),"""
new="""                Text = "seed-文本", Width = 240, Height = 24,
                Foreground = B("010203"),   // ★ 突变自测：绝不会出现在画面里的颜色"""
if old not in s: print("MUTATE_PATTERN_NOT_FOUND", file=sys.stderr); sys.exit(3)
open(p,'w',encoding='utf-8').write(s.replace(old,new,1))
print("   （已把 TextBox Foreground 突变成 #010203）")
PY
[ $? -eq 0 ] || { echo "❌ 突变未生效（模式没匹配上）⇒ 自测作废"; exit 3; }

timeout 600 dotnet build "$PROJ" -m:1 > "$OUTDIR/build-mutated.log" 2>&1 || { echo "❌ 突变后构建失败"; tail -5 "$OUTDIR/build-mutated.log"; exit 3; }
WFP_RUN_DIR="$OUTDIR/mutated" timeout 600 bash "$RUNNER" "$TIMEOUT" --only=textbox-edit > "$OUTDIR/run-mutated.log" 2>&1
row_mut="$(grep -a '^textbox-edit|' "$OUTDIR/mutated/blocks.txt" 2>/dev/null | head -1)"
echo "   行：${row_mut:-（取不到）}"
tooth_bites=0
case "$row_mut" in *"|FAIL("#F97316*) tooth_bites=1 ;; esac
[ "$tooth_bites" = "1" ] && echo "   ✅ 牙咬住了（像素列 FAIL ⇒ 近色判据确实能红）" \
                         || echo "   ❌ 牙没咬住：突变后像素列**没有**判红 ⇒ 这条判据是假绿"

echo
echo "── 极性 ②：还原 ⇒ 判据必须回到 OK（颜色腿 + 字形腿）──"
restore
timeout 600 dotnet build "$PROJ" -m:1 > "$OUTDIR/build-restored.log" 2>&1 || { echo "❌ 还原后构建失败"; tail -5 "$OUTDIR/build-restored.log"; exit 3; }
WFP_RUN_DIR="$OUTDIR/restored" timeout 600 bash "$RUNNER" "$TIMEOUT" --only=textbox-edit > "$OUTDIR/run-restored.log" 2>&1
row_ok="$(grep -a '^textbox-edit|' "$OUTDIR/restored/blocks.txt" 2>/dev/null | head -1)"
echo "   行：${row_ok:-（取不到）}"
tooth_releases=0
case "$row_ok" in *"|OK("#F97316=*) tooth_releases=1 ;; esac
case "$row_ok" in *"census GlyphRun×"*) : ;; *) tooth_releases=0 ;; esac
[ "$tooth_releases" = "1" ] && echo "   ✅ 牙松开了（近色计数回来了，且 census 有 GlyphRun）" \
                            || echo "   ❌ 还原后判据仍未回来 ⇒ 自测不合格"

echo
if [ "$tooth_bites" = "1" ] && [ "$tooth_releases" = "1" ]; then
    echo "WFP_MUTATION_SELFTEST=PASS（极性①红、极性②绿；样例已还原）"
    exit 0
fi
echo "WFP_MUTATION_SELFTEST=FAIL（bites=$tooth_bites releases=$tooth_releases）"
echo "   突变趟：$OUTDIR/run-mutated.log   还原趟：$OUTDIR/run-restored.log"
exit 1

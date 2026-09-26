#!/usr/bin/env bash
# `textbox-edit` **键入腿（像素口径）**的突变自测 —— 主控 2026-09-13 采纳后要求
#
# 【为什么】键入腿原来是 `changes>0`（`TextChanged` 计数）⇒ 实测**假红**：注入后原始分辨率帧里
#   TextBox 明明显示 `AB`，而 `changes=0`。现口径 = **注入前后 `WFP_BOXID` 矩形内"测试色混合线像素"
#   是否变化**（`b-*` 注入前 vs `b3-*` 注入后）。这条腿必须**能红**，所以要有两极性自测。
#
# 两极性（都不需要改产物，只用 runner 自带的开关）：
#   极性① `WFP_BOXID_OVERRIDE=240x24+600+600`（**把矩形挪到空白处**，注入照常）
#          ⇒ 矩形内前后都没有字形 ⇒ 键入腿必须 **FAIL**（牙）
#   极性② 正常            ⇒ 矩形内字形像素变化（且 >MINPX）⇒ 键入腿 **PASS**（块仍会因
#                            "Text DP 陈旧" 记 INCONCLUSIVE，**这是预期**，见 README ⑫）
#   极性③ `WFP_INPUT=0`（注入关掉，**没有注入后帧**）⇒ 必须 **INCONCLUSIVE**（不是 FAIL）
#          —— 防"把仪器没采到判成没键入"的假红（本脚本第一版就踩了这个）
#
# 【判据】极性① 的块行必须含 `键入腿(像素)=FAIL`；极性② 必须含 `键入腿(像素)=PASS`。
#
# 用法：  run-wpfprobe-inputleg-tooth.sh [超时秒数=60]
set -u
REPO=${REPO:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)}   # 波 `#77` 旧路径重指向：由仓根现推
TIMEOUT=${1:-60}
RUNNER="$REPO/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh"
OUTDIR="${WFP_INPUTLEG_DIR:-$HOME/wfp-runs/inputleg-tooth}"
export PATH="$HOME/.dotnet:$PATH"
export WFP_TRIAGE=0
export DISPLAY=:97
mkdir -p "$OUTDIR"

echo "== 键入腿（像素口径）两极性自测 =="
echo "   loadavg=$(cut -d' ' -f1-3 /proc/loadavg)"

run_pole() {   # $1=标签 $2=input 开关 $3=矩形覆盖(可空)
    # ⚠️ `local a="$1" b="$OUTDIR/$a"` 会在**赋值前**就把整行展开 ⇒ `set -u` 下 $a 未绑定
    #   （实测踩到：`tag: 未绑定的变量` 直接让自测假红）。**必须分行声明**。
    local tag="$1" inp="$2" ovr="${3:-}"
    local out="$OUTDIR/$tag"
    WFP_INPUT="$inp" WFP_BOXID_OVERRIDE="$ovr" WFP_RUN_DIR="$out" timeout 900 bash "$RUNNER" "$TIMEOUT" --only=textbox-edit \
        --app-env="WPF_LINUX_INPUT_TRACE=1" > "$out.log" 2>&1
    local row; row="$(grep -a '^textbox-edit|' "$out/blocks.txt" 2>/dev/null | head -1)"
    printf '  [%s] WFP_INPUT=%s 覆盖矩形=%s\n        %s\n' "$tag" "$inp" "${ovr:-无}" "${row:0:230}"
    printf '%s' "$row"
}

row_off="$(run_pole empty-rect 1 240x24+600+600)"
row_on="$(run_pole inject 1)"
row_noinj="$(run_pole no-inject 0)"

bite=0; release=0; noinj_ok=0
case "$row_off"   in *"键入腿(像素)=FAIL"*) bite=1 ;; esac
case "$row_on"    in *"键入腿(像素)=PASS"*) release=1 ;; esac
case "$row_noinj" in *"键入腿(像素)=INCONCLUSIVE"*) noinj_ok=1 ;; esac
[ "$bite" = "1" ]      && echo "  ✅ 牙咬住：矩形挪到空白 ⇒ 键入腿 FAIL" || echo "  ❌ 牙没咬住：空白矩形下仍不是 FAIL ⇒ 这条腿是假的"
[ "$release" = "1" ]   && echo "  ✅ 牙松开：正常注入 ⇒ 键入腿 PASS" || echo "  ❌ 未恢复：正常注入下键入腿没 PASS"
[ "$noinj_ok" = "1" ]  && echo "  ✅ 防假红：关掉注入（无注入后帧）⇒ INCONCLUSIVE（**没有**判成 FAIL）" || echo "  ❌ 关掉注入时没有记 INCONCLUSIVE ⇒ 存在'仪器没采到被判成没键入'的假红"
case "$row_on" in *INCONCLUSIVE*) echo "  ℹ️ 正常极性整体记 INCONCLUSIVE 是**预期**（像素对但 Text DP 陈旧 ⇒ 缺陷，不是通过）" ;; esac

if [ "$bite" = "1" ] && [ "$release" = "1" ] && [ "$noinj_ok" = "1" ]; then
    echo "WFP_INPUTLEG_SELFTEST=PASS（极性①红、极性②绿、极性③ INCONCLUSIVE）"
    exit 0
fi
echo "WFP_INPUTLEG_SELFTEST=FAIL（bites=$bite releases=$release noinj=$noinj_ok）"
exit 1

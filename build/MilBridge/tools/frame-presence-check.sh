#!/usr/bin/env bash
# frame-presence-check —— **时间分辨**的"画面出现过没有"读者（`#34` 波立；纪律 78 的落点）
#
# 【它挡的是什么】同族的三次仪器伪影（`docs/WAVE34-PREREGISTRATION.md` §3m/§3o）：
#   ① 门禁判据③取"**颜色数最多**的一帧" ⇒ 任何"会让颜色数**下降**的变化"被系统性漏掉；
#   ② 采样脚本"跑了 N 秒"被当成"拍了 N 秒" ⇒ 截图窗口短于结论的时间域；
#   ③ `cp -p` 保 mtime ⇒ 构建没重编（靠"产物 sha 变没变"抓）。
#   本读者把判据改成**时间分辨**：在采样窗口内**是否出现过**满足条件的帧，
#   而不是"某张选定帧里有没有"。
#
# 【用法】
#   bash build/MilBridge/tools/frame-presence-check.sh --selftest
#   bash build/MilBridge/tools/frame-presence-check.sh --app-args="--late-content" [--seconds=20] [--min-colors=200]
#   bash build/MilBridge/tools/frame-presence-check.sh --judge-only=<帧目录> [--min-colors=200] [--magenta]
#   加 --magenta 时，额外要求"至少一帧含品红像素"（用于"首帧之后的树变更有没有上屏"这类判据）。
#   ⚠️ `#37` F1：**没给 `--magenta` 时，机读行里的 `magenta_frames` 打 `n/a`（不是 `0`）** ——
#      "**没测**"不许冒充"**测了，结果是 0**"（本工程的老病；现场：同一份帧目录，不给 ⇒ `0`、给 ⇒ `31`）。
#
# 【判据（三态）】
#   FRAMEPRESENCE=PASS  采样窗口内**至少一帧**达到 --min-colors（且若给 --magenta，至少一帧含品红）
#   FRAMEPRESENCE=FAIL  采到帧但**一帧都不达标**
#   FRAMEPRESENCE=NOINFO 一帧都没采到（仪器没跑起来）⇒ 与 FAIL 分开报，不许当红读
set -u
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
GATE="$ROOT/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh"
MODE=""; APP_ARGS=""; SECONDS_RUN=20; MIN_COLORS=200; WANT_MAGENTA=0; JUDGE_DIR=""
for a in "$@"; do
  case "$a" in
    --selftest) MODE=selftest ;;
    --app-args=*) APP_ARGS="${a#--app-args=}"; MODE="run" ;;
    --seconds=*) SECONDS_RUN="${a#--seconds=}" ;;
    --min-colors=*) MIN_COLORS="${a#--min-colors=}" ;;
    --magenta) WANT_MAGENTA=1 ;;
    --judge-only=*) JUDGE_DIR="${a#--judge-only=}"; MODE="judge" ;;
    *) echo "用法: $0 --selftest | --app-args=<应用参数> [--seconds=N] [--min-colors=K] [--magenta] | --judge-only=<目录>" >&2; exit 2 ;;
  esac
done
[ -n "$MODE" ] || { echo "用法: $0 --selftest | --app-args=<…> | --judge-only=<目录>" >&2; exit 2; }

# ── 单帧读数：颜色数 / 是否含品红 ─────────────────────────────────────────────
frame_colors() { identify -format '%k' "$1" 2>/dev/null | head -1; }
frame_has_magenta() {   # 先把手上的白变黑，再把品红变白，再把非白变黑 ⇒ mean>0 即"含品红"
  local m
  m="$(convert "$1" -scale 25% -fill black -opaque white -fuzz 12% -fill white -opaque '#FF00FF' \
        -fill black +opaque white -format '%[fx:mean]' info: 2>/dev/null)"
  awk -v m="${m:-0}" 'BEGIN{exit !(m>0)}'
}

judge_dir() {   # $1=帧目录 → 打印三态 + 读数
  local dir="$1" n=0 maxc=0 mag=0 f c
  for f in "$dir"/*.png; do
    [ -f "$f" ] || continue
    n=$((n+1)); c="$(frame_colors "$f")"; c="${c:-0}"
    [ "$c" -gt "$maxc" ] && maxc="$c"
    if [ "$WANT_MAGENTA" = "1" ] && frame_has_magenta "$f"; then mag=$((mag+1)); fi
  done
  if [ "$n" -eq 0 ]; then
    echo "FRAMEPRESENCE=NOINFO frames=0 reason=一帧都没采到 dir=$dir"; return 2
  fi
  # 判据：给了 --magenta ⇒ **以"标记色出现过"为准**（标记色是专指，不叠加颜色数门槛；
  #       否则"小面积标记 + 纯色底"会被颜色数门槛压成红——自测第 3 例就是这么抓出来的）。
  #       没给 --magenta ⇒ 以"某一帧颜色数 ≥ min_colors"为准。
  local ok=0
  # ⚠️ `#37` F1：只有给了 `--magenta` 才把计数印成数字；否则印 `n/a`（"没测" ≠ "0"）
  local magf="n/a"
  [ "$WANT_MAGENTA" = "1" ] && magf="$mag"
  if [ "$WANT_MAGENTA" = "1" ]; then
    [ "$mag" -ge 1 ] && ok=1
  else
    [ "$maxc" -ge "$MIN_COLORS" ] && ok=1
  fi
  if [ "$ok" = "1" ]; then
    echo "FRAMEPRESENCE=PASS frames=$n max_colors=$maxc magenta_frames=$magf min_colors=$MIN_COLORS dir=$dir"; return 0
  fi
  echo "FRAMEPRESENCE=FAIL frames=$n max_colors=$maxc magenta_frames=$magf min_colors=$MIN_COLORS dir=$dir"; return 1
}

# ── 自测：判据必须**能红能绿**（合成帧，不依赖任何应用）──────────────────────
if [ "$MODE" = "selftest" ]; then
  T="$(mktemp -d)"
  # 【`#75` `TASK-0739` 修法①：**本趟自起的显示位退出即按 PID 收**（并进**既有** trap）】
  #   ⚠️ **不新安第二条 `trap … EXIT`** —— 那会**吃掉**上面这条 `rm -rf "$T"`。
  #   （`#75` 第一版用 `trap -p`＋`sed` 动态串接 ⇒ 引号打架、既有 trap 失效，被三极化腿 C 抓到。）
  XVFB_OWN_PID=""
  trap 'rm -rf "$T"; if [ -n "${XVFB_OWN_PID:-}" ]; then kill "$XVFB_OWN_PID" 2>/dev/null || true; XVFB_OWN_PID=""; fi' EXIT
  mkdir -p "$T/blank" "$T/content" "$T/magenta" "$T/magenta_only_blank"
  convert -size 320x240 xc:'#202020' "$T/blank/f1.png"
  cp "$T/blank/f1.png" "$T/blank/f2.png"
  convert -size 320x240 gradient:red-blue "$T/content/f1.png"; cp "$T/blank/f1.png" "$T/content/f2.png"
  convert -size 320x240 xc:'#202020' -fill '#FF00FF' -draw 'rectangle 10,10,120,70' "$T/magenta/f1.png"
  cp "$T/blank/f1.png" "$T/magenta/f2.png"
  cp "$T/blank/f1.png" "$T/magenta_only_blank/f1.png"
  pass=0; fail=0
  chk() {  # $1=期望态 $2=目录 $3=额外参数
    local got; got="$(WANT_MAGENTA=$WANT_MAGENTA judge_dir "$2" ${3:-} 2>/dev/null | sed 's/FRAMEPRESENCE=\([A-Z]*\).*/\1/')" || true
    if [ "$got" = "$1" ]; then pass=$((pass+1)); printf '  ✅ 期望 %-6s 实得 %-6s  %s\n' "$1" "$got" "$2";
    else fail=$((fail+1)); printf '  ❌ 期望 %-6s 实得 %-6s  %s\n' "$1" "$got" "$2"; fi
  }
  echo "== frame-presence-check --selftest（判据三态）=="
  MIN_COLORS=200 WANT_MAGENTA=0; chk FAIL  "$T/blank"
  MIN_COLORS=200 WANT_MAGENTA=0; chk PASS  "$T/content"
  MIN_COLORS=200 WANT_MAGENTA=1; chk PASS  "$T/magenta"
  MIN_COLORS=200 WANT_MAGENTA=1; chk FAIL  "$T/magenta_only_blank"
  MIN_COLORS=200 WANT_MAGENTA=0; chk NOINFO "$T/empty_dir_not_exist"
  # ── `#37` F1：**"没测"不许印成 0**（本工程反复犯的那一族：没声明/没测量 ≠ 通过，也 ≠ 0）──
  #    判据不是"值是多少"，而是**形态**：没给 `--magenta` ⇒ 机读行里**不许出现数字形态**。
  #    ⚠️ 这一例**在旧件上必须失败** —— 旧件在那两处都印 `$mag`，现场实测打的是 `magenta_frames=0`
  #    （同一份帧目录 `$HOME/w34-framepresence-043414`：不给 ⇒ 0、给 ⇒ 31）。
  raw="$(MIN_COLORS=200 WANT_MAGENTA=0 judge_dir "$T/content" 2>/dev/null)"
  # 【`D-G42` 族修法 · 车道 W113A · 2026-09-22】原为 `printf '%s' "$raw" | grep -qE PAT`。
  #   ⚠️ 口径自认：本件**没有** `set -o pipefail` ⇒ 按 `pipefail-sigpipe-check.sh` 的口径它**不是候选**
  #      （SIGPIPE 不会把 rc 翻转）。本处按 **同族形态预防性对齐**：把喂法换成 here-string，
  #      **判据正则一字未动**；将来若有人给本件加上 `pipefail`，这里已经安全。
  if grep -qE 'magenta_frames=[0-9]+' <<<"$raw"; then
    fail=$((fail+1)); printf '  ❌ 没给 --magenta 却仍打出数字形态：%s\n' "$raw"
  else
    pass=$((pass+1)); printf '  ✅ 没给 --magenta ⇒ 打 n/a（"没测"不冒充 0）\n'
  fi
  # 反极性：给了 `--magenta` 必须回到数字形态（否则上面那一例可能是恒真的空判据）
  raw2="$(MIN_COLORS=200 WANT_MAGENTA=1 judge_dir "$T/magenta" 2>/dev/null)"
  if grep -qE 'magenta_frames=[0-9]+' <<<"$raw2"; then
    pass=$((pass+1)); printf '  ✅ 给了 --magenta ⇒ 数字形态（%s）\n' "${raw2##*magenta_frames=}"
  else
    fail=$((fail+1)); printf '  ❌ 给了 --magenta 却没数字形态：%s\n' "$raw2"
  fi
  echo "SELFTEST=$([ "$fail" -eq 0 ] && echo PASS || echo FAIL) pass=$pass fail=$fail"
  [ "$fail" -eq 0 ] || exit 1
  exit 0
fi

if [ "$MODE" = "judge" ]; then judge_dir "$JUDGE_DIR"; exit $?; fi

# ── 采样模式：调用仓内应用门禁跑 app，同时每 0.5s 抓一帧（窗口树一并记录）────────
OUT="${FRAMEPRESENCE_OUT:-$HOME/w34-framepresence-$(date +%H%M%S)}"
mkdir -p "$OUT"; rm -f "$OUT"/f*.png
DISPLAY_NUM="${WPTD_DISPLAY:-:97}"
if ! xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1; then
  echo "[前置] $DISPLAY_NUM 上没有 X server ⇒ 起一个 Xvfb"
  # 【`#75` `TASK-0739` 修法①（**生产分支**）：本分支原**没有** `EXIT` trap（既有那条 `rm -rf "$T"`
  #   只在 `--selftest` 分支里）⇒ 第一版把收尾并进 selftest 的 trap ⇒ **生产路径漏接**
  #   （`D-G130` 同族："只在排练模式被调"）⇒ 被 gate1 的 `X_CENSUS_LEAK pid=3329426 display=:97` 抓到。
  #   本分支**没有**别的 `EXIT` trap ⇒ 直接安一条（只收本趟自己起的 PID；为空 ⇒ 一个都不杀）。
  XVFB_OWN_PID=""
  trap 'if [ -n "${XVFB_OWN_PID:-}" ]; then kill "$XVFB_OWN_PID" 2>/dev/null || true; XVFB_OWN_PID=""; fi' EXIT
  Xvfb "$DISPLAY_NUM" -screen 0 1280x1024x24 >"$OUT/xvfb.log" 2>&1 &
  XVFB_OWN_PID=$!   # 【`#75`】本趟自起 ⇒ 退出即按 PID 收
  for _ in $(seq 1 10); do sleep 1; xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 && break; done
fi
xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1 || { echo "FRAMEPRESENCE=NOINFO reason=X不可用"; exit 2; }

( WPTD_RUN_DIR="$OUT/run" timeout $((SECONDS_RUN+90)) bash "$GATE" $((SECONDS_RUN+10)) --tier default --no-build \
    --app-args="$APP_ARGS" >"$OUT/gate.log" 2>&1; echo "gate_rc=$?" >>"$OUT/gate.log" ) &
GATE_PID=$!
i=0
while kill -0 "$GATE_PID" 2>/dev/null && [ "$i" -lt $((SECONDS_RUN*2)) ]; do
  i=$((i+1)); printf -v n '%03d' "$i"
  DISPLAY="$DISPLAY_NUM" import -window root "$OUT/f$n.png" 2>/dev/null
  sleep 0.5
done
wait "$GATE_PID" 2>/dev/null
echo "采样 $i 帧 → $OUT（判据：时间分辨；app_args='$APP_ARGS'）"
judge_dir "$OUT"

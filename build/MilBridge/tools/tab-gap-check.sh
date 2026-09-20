#!/usr/bin/env bash
# ============================================================================
# tab-gap-check.sh —— `D-T4` 在**产品入口**上的读数（`#42` 建，`#43` 修仪器三处）
# ============================================================================
#   TABGAP_CHECK=PASS       响应性成立（TABGAP_RESPONSIVE=yes）⇒ D-T4 已治
#   TABGAP_CHECK=KNOWN-RED  复现 D-T4（no）⇒ 登记在册的红，rc=1
#   TABGAP_CHECK=NOINFO     编不出/跑不起来/无判词/没有可用显示 ⇒ 不许当绿也不许当红
# ⚠️ 只读脚本。价值 = 把 D-T4 变成"产品入口上可复算、可判红、修好后可判绿"的一格读数。
#
# ── `#43` 修掉的三处仪器缺陷（都是 `#42` 现场撞到的，且合起来把读数变成了"无 X 读数"）──
#   (a) `:19` 原先硬写 `-c Debug`，而结论行里的 `cfg=` 印的是 `selfbuilt-config.sh` 的**声明档**
#       ⇒ **印出来的 cfg 与实际构建档不符**。今天修成：**构建档 = 声明档**，且结论行印的就是实际值。
#   (b) `:26` 原先用 `bin/*/TabGapProbe.dll` 通配取目录 ⇒ 会取到 `obj/Debug` ⇒
#       `libhostpolicy.so` 找不到 ⇒ **没有判词**（`#42` 的两具日志正是这样死的）。
#       今天修成：**只认 `bin/$声明档/`**，取不到就 `NOINFO`。
#   (c) 原先全程**不自起显示** ⇒ 读数默认落在"无 DISPLAY"档。`#43` 的去混淆实验证明：
#       **无 DISPLAY 时兜底链必抛**（`TypeInitializationException: ... 'System.Windows.Media.Brush'`）
#       ⇒ 那一档下量到的"崩"**不是产品在真实环境里的行为**。
#       今天修成：**没有可用显示就自起 Xvfb（按 PID 收尸，禁 `pkill -f`）**；起不来 ⇒ `NOINFO`。
#   ⚠️ 这三处**只修仪器**，一个判据都没放宽：`EXCEPTION ⇒ FAIL` 一字未动。
# ============================================================================
set -uo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd -- "$HERE/../../.." && pwd)"
PROJ="$REPO/build/MilBridge/tests/TabGapProbe/TabGapProbe.csproj"
export PATH="$HOME/.dotnet:$PATH"
OUT="${TABGAP_OUT:-$(mktemp -d /tmp/tabgap.XXXXXX)}"
mkdir -p "$OUT"
CFG="$(bash "$REPO/build/selfbuilt-config.sh" 2>/dev/null || echo '<未解出>')"

# ── X 前置：**没有可用显示就自起一个**（按 PID 收尾；本仓在册教训：禁用 `pkill -f`）──────────
DISP="${TABGAP_DISPLAY:-:96}"
XPID=""
cleanup() { if [ -n "$XPID" ]; then kill "$XPID" 2>/dev/null; XPID=""; fi; }
trap cleanup EXIT INT TERM
if ! DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1; then
  Xvfb "$DISP" -screen 0 1280x1024x24 > "$OUT/xvfb.log" 2>&1 &
  XPID=$!
  for _ in $(seq 1 40); do DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1 && break; sleep 0.25; done
fi
if ! DISPLAY="$DISP" xdpyinfo >/dev/null 2>&1; then
  echo "TABGAP_CHECK=NOINFO reason=no-usable-display disp=$DISP cfg=$CFG（无显示档下量到的'崩'是环境产物，不许当产品读数）"
  exit 2
fi
DISP_DESC="$(DISPLAY="$DISP" xdpyinfo 2>/dev/null | awk '/dimensions/{print $2}')"
echo "TABGAP DISPLAY=$DISP ready（$DISP_DESC）"

if ! timeout 900 dotnet build "$PROJ" -c "$CFG" -m:1 --nologo -v q > "$OUT/build.log" 2>&1; then
  echo "TABGAP_CHECK=NOINFO reason=build-failed cfg=$CFG log=$OUT/build.log"
  { grep -m3 -E ": error " "$OUT/build.log" || true; } | sed 's/^/  /'
  exit 2
fi

# ── 输出目录：**写死声明档**，不用通配（通配会取到 `obj/Debug` ⇒ 无判词）──────────────────
BIN_DIR="$REPO/build/MilBridge/tests/TabGapProbe/bin/$CFG"
if [ ! -f "$BIN_DIR/TabGapProbe.dll" ]; then
  echo "TABGAP_CHECK=NOINFO reason=declared-config-dll-absent cfg=$CFG path=${BIN_DIR#"$REPO"/}"; exit 2
fi

set +e
( cd "$BIN_DIR" && DISPLAY="$DISP" timeout 300 dotnet TabGapProbe.dll ) > "$OUT/probe.log" 2>&1
rc=$?
set +e
sed 's/^/  /' "$OUT/probe.log" 2>/dev/null

if ! grep -q "^TABGAP_RESPONSIVE=" "$OUT/probe.log" 2>/dev/null; then
  echo "TABGAP_CHECK=NOINFO reason=no-verdict rc=$rc cfg=$CFG display=$DISP log=$OUT/probe.log"; exit 2
fi
verdict="$(grep -m1 '^TABGAP_RESPONSIVE=' "$OUT/probe.log" | cut -d= -f2)"

# ⚠️ `#42` 实测新增的一维：**兜底链接不住时会落到原生 LineServices** ⇒ Linux 上
#   `EntryPointNotFoundException: LoCreateContext` ⇒ **应用直接崩**（不是降级）。
#   崩**永远**不可接受 ⇒ 只要有 EXCEPTION 行就判 FAIL（哪怕响应性成立）。
# ⚠️ `#43` 修：原写法 `n_exc="$(grep -c … || echo 0)"` 在**命中 0 次**时会**打两行**（`grep -c` 印 `0` 且 rc=1 ⇒
#   再补一个 `0`）⇒ `[ "$n_exc" -gt 0 ]` 报 "需要整数表达式"（实测 `:75`）。用 `awk` 数，不靠 `grep` 的 rc。
n_exc="$(awk '/EXCEPTION/{n++} END{print n+0}' "$OUT/probe.log" 2>/dev/null)"; n_exc="${n_exc:-0}"
if [ "${n_exc:-0}" -gt 0 ]; then
  echo "TABGAP_CHECK=FAIL reason=fallback-bailed-to-native-LineServices n_exception=$n_exc（HB 兜底接不住 ⇒ 落到不存在的原生 LS ⇒ 应用崩）cfg=$CFG display=$DISP outdir=$OUT"
  grep -m2 'EXCEPTION' "$OUT/probe.log" | sed 's/^/  /'
  # 兜底链**为什么**交回 LS（`Bail()` 前 3 条无条件打；`WPF_LINUX_TEXTLINE_DIAG=1` 再给 8 条）
  grep -m3 -o '交回 LS（[^）]*）：.*' "$OUT/probe.log" 2>/dev/null | sed 's/^/  bail: /'
  exit 1
fi
# ── `#43` 新增的**细判据**（防"粗判据假绿"）────────────────────────────────────────────────
#   现场（`#43` 去混淆实验实测）：粗判据只看"与 tab=0 基线有没有**任何**不同" ⇒
#   兜底路径**丢了 tab 参数、静默用 `4×emSize`** 时，**窄档三个 tab 值（0/24/48）的宽度会完全一样**
#   （实测都是 `9.805`），而窄档 `tab=4` 是 `32.797`（快路径自己接住）⇒ **粗判据照样打 `yes` ⇒ 假绿**。
#   锚（不依赖外部模型）：**用同一探针的另一个臂当对照** —— **宽档**同三个 tab 值互不相同
#   （实测 `74.156 / 56.797 / 104.797`）⇒ "三个值完全相同"这件事**在本探针内部就是异常**。
w_of() { awk -v tag="$1" -v tv="$2" '$1==tag && $2=="tab="tv {for(i=1;i<=NF;i++) if($i ~ /^widthsum=/) {sub("widthsum=","",$i); print $i; exit}}' "$OUT/probe.log" 2>/dev/null; }
W0="$(w_of TABGAP 0)"; W4="$(w_of TABGAP 4)"; W24="$(w_of TABGAP 24)"; W48="$(w_of TABGAP 48)"
N0="$(w_of TABGAP_NARROW 0)"; N4="$(w_of TABGAP_NARROW 4)"; N24="$(w_of TABGAP_NARROW 24)"; N48="$(w_of TABGAP_NARROW 48)"
echo "TABGAP WIDTHS wide=$W0/$W4/$W24/$W48 narrow=$N0/$N4/$N24/$N48（顺序 tab=0/4/24/48）"
tab_lost="no"
if [ -n "$N0" ] && [ "$N0" = "$N24" ] && [ "$N0" = "$N48" ]; then tab_lost="yes"; fi
echo "TABGAP_FALLBACK_TAB_LOST=$tab_lost（yes = 窄档 0/24/48 三个值宽度完全相同 ⇒ 该路 tab 步长没进几何）"

case "$verdict" in
  yes)
    if [ "$tab_lost" = yes ]; then
      echo "TABGAP_CHECK=KNOWN-RED reason=fallback-ignores-tab（响应性只在宽档成立；窄档 0/24/48 三个值宽度完全相同 ⇒ 兜底路径静默用 4×emSize、未吃 DefaultIncrementalTab）cfg=$CFG display=$DISP outdir=$OUT"
      exit 1
    fi
    echo "TABGAP_CHECK=PASS cfg=$CFG display=$DISP outdir=$OUT" ; exit 0 ;;
  no)  echo "TABGAP_CHECK=KNOWN-RED reason=D-T4-reproduced（tab 值未影响行数/行宽；真机 60/119 会变）cfg=$CFG display=$DISP outdir=$OUT" ; exit 1 ;;
  *)   echo "TABGAP_CHECK=NOINFO reason=unexpected-verdict value=$verdict" ; exit 2 ;;
esac

#!/usr/bin/env bash
# ============================================================================
# tabgap-display-polarity.sh —— `D-G48` 的**显示两极化**读数（`#43` 新建）
# ============================================================================
#
# 【问什么】`#42` 登记的 `D-G48` 说："HB 兜底接不住 ⇒ 落到不存在的原生 LineServices ⇒ 应用崩"，
#   并把触发条件记成 ①`DefaultIncrementalTab = 0`、②**tab 步长 > 容器宽**。
#   而 `#42` 的**全部有效读数都取自"无 DISPLAY"的环境**（`XOpenDisplay` 失败行 ×2 在日志里；
#   副本见 `$HOME/w21-verify/w43-tabgap-logs/`）⇒「tab 值」与「有没有 X」两个因子**完全混杂**
#   ⇒ **触发条件的因果从未被单独测过**。本件就是那个单独的测量。
#
# 【怎么做】两臂，**同一个二进制**（先按**声明档**构建一次，两臂只换环境）：
#   臂 A：有 X（**自起 Xvfb，按 PID 收尸**；禁用 `pkill -f`）｜臂 B：`env -u DISPLAY`（复现 `#42` 原条件）
#   两臂都开 `WPF_LINUX_TEXTLINE_DIAG=1` 与 `WPF_LINUX_TEXTLINE_LINEDIAG=1`
#   ⇒ 兜底链**为什么**交回 LS 会打出来：`LS_FALLBACK 交回 LS（前3条无条件|DIAG）：<真因>`
#     （`build/shims/PresentationCore.HbTextLine.cs:4510,4522-4528`：前 3 条无条件 + `DIAG=1` 再给 8 条预算）。
#
# 【三态判词】（`#43` 开工前写死，防事后解释；与 `docs/WAVE43-PREREGISTRATION.md` §2 表逐字一致）
#   TABGAP_DISPLAY_POLARITY=X-CONFOUNDED       臂 A 无异常 ∧ 臂 B 有异常 ⇒ 真因是"无 DISPLAY 的兜底链"，
#                                              `D-G48` 的"tab 触发"措辞**被推翻**
#   TABGAP_DISPLAY_POLARITY=TAB-GEOMETRY       两臂**同例**都异常 ⇒ 真因在 tab 几何、与显示无关
#   TABGAP_DISPLAY_POLARITY=NOINFO             任一臂无判词 ⇒ **不许当绿**（先修仪器再重测）
#
# ⚠️ 只读脚本（只读仓 + 只写 `$OUT`）。⚠️ 结论字符串里**不许出现嵌套双引号**（本仓在册教训）。
# ============================================================================
set -uo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd -- "$HERE/../../.." && pwd)"
OUT="${TABGAP_POLARITY_OUT:-$HOME/w43-display-polarity-$(date +%m%d-%H%M%S)}"
mkdir -p "$OUT"
export PATH="$HOME/.dotnet:$PATH"

CFG="$(bash "$REPO/build/selfbuilt-config.sh" 2>/dev/null || echo '<未解出>')"
PROJ="$REPO/build/MilBridge/tests/TabGapProbe/TabGapProbe.csproj"
BIN="$REPO/build/MilBridge/tests/TabGapProbe/bin/$CFG"

echo "TABGAP_POLARITY CFG=$CFG"
echo "TABGAP_POLARITY OUT=$OUT"

if ! timeout 900 dotnet build "$PROJ" -c "$CFG" -m:1 --nologo -v q > "$OUT/build.log" 2>&1; then
  echo "TABGAP_DISPLAY_POLARITY=NOINFO reason=build-failed cfg=$CFG log=$OUT/build.log"
  { grep -m3 -E ': error ' "$OUT/build.log" || true; } | sed 's/^/  /'
  exit 2
fi
if [ ! -f "$BIN/TabGapProbe.dll" ]; then
  echo "TABGAP_DISPLAY_POLARITY=NOINFO reason=declared-config-dll-absent path=${BIN#"$REPO"/}（不用通配：通配会取到 obj/Debug ⇒ 无判词）"
  exit 2
fi
echo "TABGAP_POLARITY BUILD=ok declared_config=$CFG（目录写死，不用通配）"

DIAG_ENV=(WPF_LINUX_TEXTLINE_DIAG=1 WPF_LINUX_TEXTLINE_LINEDIAG=1)

# ── 臂 B：无 DISPLAY（`#42` 的原条件）────────────────────────────────────────────────────────
( cd "$BIN" && env -u DISPLAY "${DIAG_ENV[@]}" timeout 300 dotnet TabGapProbe.dll ) \
  > "$OUT/armB-no-display.log" 2>&1
rcB=$?
echo "TABGAP_POLARITY ARM_B(no-display) rc=$rcB log=$OUT/armB-no-display.log"

# ── 臂 A：有 X（自起 Xvfb，按 PID 收尸）──────────────────────────────────────────────────────
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
  echo "TABGAP_DISPLAY_POLARITY=NOINFO reason=armA-no-display disp=$DISP（两极化缺一臂 ⇒ 不许当绿）"
  exit 2
fi
# ⚠️ 本仓在册教训（`#43` 又踩了一次并做成最小复现）：**别把带内层引号的 `$( … )` 嵌在更长的双引号串中间** ——
#   `echo "prefix（$(DISPLAY="$D" cmd)）suffix"` ⇒ **语法错**（`bash -n`：寻找匹配的 `"` 时遇到未预期的 EOF）；
#   两种**合法**写法：① 先把命令替换算进变量（下面这样做）；② 赋值整条右值 `VAR="$(DISPLAY="$D" cmd)"`。
DISP_DESC="$(DISPLAY="$DISP" xdpyinfo 2>/dev/null | awk '/dimensions/{print $2}')"
echo "TABGAP_POLARITY ARM_A(with-display) DISPLAY=$DISP size=$DISP_DESC"

# ⚠️ 这里必须用 `env` 传环境（`DISPLAY=x "${ARR[@]}" cmd` 里那个数组展开**不是赋值前缀** ⇒
#   会被当成命令名 ⇒ 实测 `rc=127 未找到命令`、而且日志里只有一行错 ⇒ 看起来像"应用没跑"）。
( cd "$BIN" && env DISPLAY="$DISP" "${DIAG_ENV[@]}" timeout 300 dotnet TabGapProbe.dll ) \
  > "$OUT/armA-with-display.log" 2>&1
rcA=$?
cleanup
echo "TABGAP_POLARITY ARM_A(with-display) rc=$rcA log=$OUT/armA-with-display.log"

# ── 对账 ────────────────────────────────────────────────────────────────────────────────────
n_exc() { awk '/EXCEPTION/{n++} END{print n+0}' "$1" 2>/dev/null; }
n_verd() { awk '/^TABGAP_RESPONSIVE=/{n++} END{print n+0}' "$1" 2>/dev/null; }
excA="$(n_exc "$OUT/armA-with-display.log")"; excB="$(n_exc "$OUT/armB-no-display.log")"
vA="$(n_verd "$OUT/armA-with-display.log")";    vB="$(n_verd "$OUT/armB-no-display.log")"

echo
echo "---- 逐例对账（左=臂 A 有 X ｜ 右=臂 B 无 DISPLAY）----"
paste -d'|' \
  <(grep -E '^TABGAP' "$OUT/armA-with-display.log" 2>/dev/null | sed 's/ widthlast=[0-9.]*//;s/ widthsum=/ ws=/;s/ width0=/ w0=/') \
  <(grep -E '^TABGAP' "$OUT/armB-no-display.log" 2>/dev/null | sed 's/ widthlast=[0-9.]*//;s/ widthsum=/ ws=/;s/ width0=/ w0=/') \
  | sed 's/^/  /'

echo
echo "TABGAP_POLARITY SUMMARY exc_A=$excA exc_B=$excB verdict_lines_A=$vA verdict_lines_B=$vB"
echo "TABGAP_POLARITY BAILS_A（有 X）："; grep -o '交回 LS（[^）]*）：.*' "$OUT/armA-with-display.log" 2>/dev/null | LC_ALL=C sort -u | awk 'NR<=5 {print "    " $0}'
echo "TABGAP_POLARITY BAILS_B（无 DISPLAY）："; grep -o '交回 LS（[^）]*）：.*' "$OUT/armB-no-display.log" 2>/dev/null | LC_ALL=C sort -u | awk 'NR<=5 {print "    " $0}'

if [ "$vA" = 0 ] || [ "$vB" = 0 ]; then
  echo "TABGAP_DISPLAY_POLARITY=NOINFO reason=arm-without-verdict verdict_lines_A=$vA verdict_lines_B=$vB outdir=$OUT"
  exit 2
fi
if [ "$excA" = 0 ] && [ "$excB" != 0 ]; then
  echo "TABGAP_DISPLAY_POLARITY=X-CONFOUNDED（有 X 全过、无 DISPLAY 才崩 ⇒ D-G48 的 tab 触发措辞被推翻；真因是无 DISPLAY 时兜底链必抛）exc_A=$excA exc_B=$excB outdir=$OUT"
  exit 0
fi
if [ "$excA" != 0 ] && [ "$excB" != 0 ]; then
  echo "TABGAP_DISPLAY_POLARITY=TAB-GEOMETRY（两臂同例都崩 ⇒ D-G48 成立、与显示无关；走产品修）exc_A=$excA exc_B=$excB outdir=$OUT"
  exit 1
fi
echo "TABGAP_DISPLAY_POLARITY=NOINFO reason=unexpected-pattern exc_A=$excA exc_B=$excB（既非只无显示崩、也非两臂都崩 ⇒ 不许当绿，先人工看日志）outdir=$OUT"
exit 2

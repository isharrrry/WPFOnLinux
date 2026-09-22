#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# r-gate-step.sh —— `R-GATE`（`TASK-0702`）的**判据唯一实现** ＋ `verify-all` 第 `[26]` 步
#
# 【它挡的是什么（`docs/ROUTES.md:73` 原话）】
#   「**连续点击只有负向判据、正向判据由仓外临时脚本驱动**」—— 门禁里唯一与"点击"有关的牙是
#   `run-wpfprobe.sh` 的 `EXPECT=… clickprobe:!22D3EE`（**负向式**：只要求"关着时屏上不许有测试色"），
#   它**不证明"点了有反应"**。而用户报的正是"点了没反应"（`D-G49`/`D-G55` 两次真缺陷都在这一族）。
#   ⇒ 本步把 `#47` 车道 W47B 的仓外仪器（`$HOME/w47b-click.sh`）收编进仓，并给它**机器裁决**。
#
# 【三层分工（别把本件读成"又一个 runner"）】
#   · **装置** = `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh`：起私有 Xvfb ＋ 私有 app 目录 ＋
#     `xdotool` 真实节奏点击（`mousedown`→停 150 ms→`mouseup`），只落**证据**（`evidence.txt` 逐步行号区间 ＋ `app.log`）。
#   · **本件** = 判据：逐格读 `app.log` 的**区间切片**（"这一下点击到底引起了什么"），三态 ＋ 机读行。
#   · **接线** = `verify-all.sh` 第 `[26]` 步（步数声明四处同趟：`DECL`／`STEP-NAMES`／口径句／预登记 H1）。
#
# 【判据（**先写死**；逐格继承 `#49` 预登记 `docs/WAVE49-PREREGISTRATION.md` §3 B3，落在 `docs/WAVE50-PREREGISTRATION.md` §1）】
#   ①  点 ListBox item1 ⇒ 该下点击的切片里 `EVT lst.selection=1`            ｜反：点卡片右侧空白 ⇒ 切片里**控件级** EVT = 0（且点击确实到达窗口）
#   ②  点 TextBox ⇒ `EVT tb.focus`                                        ｜反：点**窗口外** ⇒ 无控件级 EVT
#   ③  点后键入 3 字符 ⇒ `EVT tb.text=` 行数 ≥ 3 且长度单调不减、净增 ≥ 3   ｜反：**未点击就键入** ⇒ `tb.focus`/`tb.text` 都不增（**且必须证明键真到了应用**）
#   ④  点 ComboBox ⇒ `EVT combo.opened` = 1 ＋ 新 X 窗口 `Map State: IsViewable` ｜反：下拉开着时点下拉外空白 ⇒ 无 `combo.selection`
#   ⑤  点弹窗 item[1] ⇒ `EVT combo.selection=1` ＋ `EVT combo.closed` = 1
#   ⑥  **每次 mouse-up 之后 `cap=none`**（`D-G55` 机器指纹）：每下点击后指针在卡片内挪 2 px，该 `EVT move` 行必须 `captured=null`
#   ⑦  **承重连续腿**：窗口内连点三下（ListBox item0 → TextBox → ComboBox）⇒ 三下各自的 EVT 都出现
#   ⑧  像素：下拉打开时测试色 `22D3EE` > 0（关着时读数一并记；关着 > 0 时要求"开 > 关"）
#   ＋ **`D-G49` 字段**：`EVT lst.down … state=Pressed` 与 `EVT lst.up … state=Released`（按钮状态不许恒定）
#
# 【三态（铁律：`NOINFO` 既不算绿也不算红，且**在门禁里同样是 ❌**）】
#   rc=0  `R_GATE=PASS`   全部判据格都判到且都过
#   rc=1  `R_GATE=FAIL`   **判据红**（逐格点名 `fails=c01(…),c11c(…)`）
#   rc=2  `R_GATE=NOINFO` **算不出**：装置自报非 OK／缺 X 工具／窗口没出来／缺 `POS`／内存不足／
#                          应用中途死（`STATE` 缺席 ⇒ "没反应"与"进程死了"分不开）／某格证据缺失到无法判
#                          （例：弹窗没出现 ⇒ ⑤ 无处可点 —— 但此时 ④ 必红，所以 `FAIL` 优先于 `NOINFO`）
#   ⚠️ **判序**：只要**有一格判红** ⇒ `FAIL`（哪怕同时有格判不了）；只有"无红但有格判不了"才 `NOINFO`。
#      为什么这样定：`NOINFO` 比 `FAIL` 弱，先用弱结论会**把真红洗成"算不出"**（本工程忌"红数信任被侵蚀"）。
#   ⚠️ **`sabotage`（仪器级反极性）**：装置若被要求挪走窗口（`sabotage=windowmove`）而本件仍 `PASS`
#      ⇒ 判 **`FAIL reason=sabotage-not-caught`**（装置没有判别力 ⇒ 不许当绿）。这条是**成对纪律**的机器落点。
#
# 【成本（实测，见 `build/MilBridge/W84A-report.md` §5）】≈ 30–40 s/趟（起 Xvfb ≈1 s｜应用冷启 ≈6 s｜
#   11 次点击 × ≈1.8 s｜键入 2 腿 ≈2 s｜整屏取色 2 次 ≈3 s）；**不含**样本构建（`[2]` 步已建，缺件时本件**才**补建）。
#
# 【测试钩子（**只服务 `--selftest` 与"复核已落盘证据"**）】
#   `--judge-dir=<dir>`（＝ `R_GATE_EVIDENCE=<dir>`）：**跳过装置**，直接判那一份已落盘的证据。
#   ⚠️ 用了它 ⇒ 机读行里带 `src=external`（**永远可见**，不会静默）；`verify-all` 的生产路径**不传**它。
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
ROOT="$(cd -- "$(dirname -- "$SELF")/../../.." && pwd)"
DEVICE="$ROOT/build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh"
cd "$ROOT" || exit 2
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_gcServer=0

# ── 判据口径（**唯一声明处**；改它们必须同趟说明"为什么这个数变了"）──────────────
EXPECT_CLICKS_MUST=10      # 必须有**真点击**的腿数（L1/L2/L3/L4/L6/L7/L6b/SEQ×3；L8 允许 kind=skipped）
EXPECT_TYPEWORDS=3         # 键入腿的字符数（判据③"键入 3 字符"）
CRIT_TOTAL=13              # 判据格数（c01…c13）；**缩水 = 判定面变小 = 恒绿风险**（与 PRODUCT-ENTRY 同族）
MIN_PX_OPEN=1              # 下拉打开时测试色像素下界

JUDGE_DIR="${R_GATE_EVIDENCE:-}"
SELFTEST=0; KEEP=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --selftest)     SELFTEST=1; shift ;;
    --keep)         KEEP=1; shift ;;
    --judge-dir)    JUDGE_DIR="${2:-}"; shift 2 ;;
    --judge-dir=*)  JUDGE_DIR="${1#*=}"; shift ;;
    -h|--help)      sed -n '2,52p' "$SELF" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "用法：bash $SELF [--selftest] [--judge-dir=<已落盘证据目录>]" >&2; exit 2 ;;
  esac
done

field() { awk -v k="$1" '{for(i=1;i<=NF;i++){n=index($i,"="); if(n>1 && substr($i,1,n-1)==k){print substr($i,n+1); exit}}}'; }

# ═══════════════════════════════════════════════════════════════════════════════
# 判据本体（**纯文本**：只读 evidence.txt 与 app.log ⇒ 可在无 X、无 dotnet 的机器上自测）
#   judge_dir <目录> ⇒ 印逐格口径行 ＋ 机读行；返回 rc 0/1/2
# ═══════════════════════════════════════════════════════════════════════════════
judge_dir() {
  local D="$1"
  local EV="$D/evidence.txt" APP="$D/app.log"
  local -a REDS=(); local SKIPS=(); local OKS=0
  local src="$2"

  er() { grep -a "^EVID $1" "$EV" 2>/dev/null; }
  e1() { er "$1" | tail -1; }
  kvf() { local l; l="$(e1 "$1")"; [ -n "$l" ] && printf '%s' "$l" | field "$2"; }
  sm() {  # step record by id
    local l; l="$(grep -a "^EVID step id=$1 " "$EV" 2>/dev/null | tail -1)"
    [ -n "$l" ] || return 1
    printf '%s' "$l"
  }
  slice() {  # slice <step id>：印 (appline_from, appline_to] 的 app.log 原文
    local l f t
    l="$(sm "$1")" || return 1
    f="$(printf '%s' "$l" | field appline_from)"; t="$(printf '%s' "$l" | field appline_to)"
    case "${f:-}${t:-}" in ''|*[!0-9]*) return 1 ;; esac
    sed -n "$(( f + 1 )),${t}p" "$APP" 2>/dev/null
  }
  red()  { REDS+=("$1"); }
  skip() { SKIPS+=("$1"); }
  crit() { # crit <格号> <0=过 1=红 2=判不了> <说明>
    local id="$1" st="$2" why="$3"
    case "$st" in
      0) OKS=$((OKS + 1)); printf '  ∟ %-5s PASS  %s\n' "$id" "$why" ;;
      1) red "$id($why)";  printf '  ∟ %-5s RED   %s\n' "$id" "$why" ;;
      2) skip "$id($why)"; printf '  ∟ %-5s n/a   %s（判不了 ⇒ 若无红则本步 NOINFO）\n' "$id" "$why" ;;
    esac
  }

  # ── 0. 前置：证据可用性（**任何一条不成立 ⇒ NOINFO**，不是红）──────────────────
  [ -f "$EV" ] || { echo "R_GATE=NOINFO reason=evidence-absent dir=$D"; return 2; }
  local devtok; devtok="$(e1 'device=OK')"
  if [ -z "$devtok" ]; then
    local ntok; ntok="$(e1 'device=NOINFO')"
    echo "R_GATE=NOINFO reason=device-$(printf '%s' "${ntok:-unknown}" | field reason | sed 's/^$/unknown/') detail=${ntok:-<无 device 行 ⇒ 装置可能被 timeout/OOM 杀掉>}"
    [ -f "$APP" ] && tail -6 "$APP" | sed 's/^/      | /'
    return 2
  fi
  [ -f "$APP" ] || { echo "R_GATE=NOINFO reason=applog-absent dir=$D"; return 2; }
  local nclicks=0 l
  while IFS= read -r l; do [ -n "$l" ] && nclicks=$((nclicks + 1)); done < <(er 'step id=' | grep -a 'kind=click')
  local win; win="$(e1 'win id=')"
  local winw winh; winw="$(printf '%s' "$win" | field w)"; winh="$(printf '%s' "$win" | field h)"
  case "${winw:-}${winh:-}" in ''|*[!0-9]*) echo "R_GATE=NOINFO reason=window-geometry-unparsable detail=${win:-<无 win 行>}"; return 2 ;; esac
  for tag in lst tb combo lstitem1; do
    # ⚠️ **必须精确匹配"tag=<名>＋空格"**：`pos tag=combo` 是 `pos tag=comboitem1` 的**前缀**
    #    ⇒ 用宽松前缀匹配 + `tail -1` 时，`combo` 这一格会悄悄读到 **comboitem1 的记录**
    #    （本件第一版实测：`comboitem1` 缺席的那两趟被读成 combo 的 w=空 ⇒ 报 `pos-missing tag=combo`；
    #      而在"comboitem1 存在"的那趟**恰好**读到 comboitem1 的 w=258 ⇒ **假绿**）。
    local pl; pl="$(grep -a "^EVID pos tag=$tag " "$EV" 2>/dev/null | tail -1)"
    local pw; pw="$(printf '%s' "$pl" | field w)"
    case "${pw:-}" in ''|*[!0-9]*) echo "R_GATE=NOINFO reason=pos-missing tag=$tag"; return 2 ;; esac
    [ "$pw" -gt 0 ] || { echo "R_GATE=NOINFO reason=pos-zero-width tag=$tag"; return 2; }
  done
  local stline; stline="$(e1 'state value=')"
  local stval; stval="$(printf '%s' "$stline" | field value)"
  if [ -z "$stval" ] || [ "$stval" = "MISSING" ]; then
    echo "R_GATE=NOINFO reason=app-died-or-no-state detail=块没自报 STATE clickprobe（'没反应'与'进程死了'分不开）"
    tail -6 "$APP" | sed 's/^/      | /'
    return 2
  fi
  if [ "$nclicks" -lt "$EXPECT_CLICKS_MUST" ]; then
    echo "R_GATE=NOINFO reason=clicks-below-floor clicks=$nclicks floor=$EXPECT_CLICKS_MUST（判定面缩水 ⇒ 不许当绿）"
    return 2
  fi

  local mem_mb; mem_mb="$(kvf 'env mem_mb=' mem_mb)"
  local art; art="$(e1 'art probe=')"
  local shim pc pf wb bridge probe
  shim="$(printf '%s' "$art" | field win32shim)"; pc="$(printf '%s' "$art" | field pc)"
  pf="$(printf '%s' "$art" | field pf)";         wb="$(printf '%s' "$art" | field wb)"
  bridge="$(printf '%s' "$art" | field bridge)"; probe="$(printf '%s' "$art" | field probe)"
  local sab; sab="$(kvf 'sabotage kind=' kind)"; sab="${sab:-none}"
  printf 'R_GATE 仪器 件：win32shim=%s pc=%s pf=%s wb=%s bridge=%s probe=%s mem_mb=%s sabotage=%s src=%s\n' \
         "${shim:-?}" "${pc:-?}" "${pf:-?}" "${wb:-?}" "${bridge:-?}" "${probe:-?}" "${mem_mb:-?}" "$sab" "$src"

  # ── 1. 逐格判据 ──────────────────────────────────────────────────────────────
  local S
  # c01 ①正：点 lstitem1 ⇒ lst.selection=1（**只看这一下的切片**）
  S="$(slice L3_lst1)"
  if grep -qE '^EVT lst\.selection=1[[:space:]]*$' <<<"$S"; then crit c01 0 "点 item1 ⇒ EVT lst.selection=1"; else crit c01 1 "点 item1 后该切片里没有 EVT lst.selection=1"; fi
  # c02 ②正：点 tb ⇒ tb.focus
  S="$(slice L4_tb)"
  if grep -qE '^EVT tb\.focus[[:space:]]*$' <<<"$S"; then crit c02 0 "点 TextBox ⇒ EVT tb.focus"; else crit c02 1 "点 TextBox 后没有 EVT tb.focus"; fi
  # c03 ③正：键入 3 字符 ⇒ tb.text= 行数 ≥ 3、长度单调不减、净增 ≥ 3
  local tl; tl="$(sm L5_type_abc)"
  if [ -z "$tl" ]; then
    crit c03 2 "缺 L5 键入腿的记录"
  else
    S="$(slice L5_type_abc)"
    local from_n; from_n="$(printf '%s' "$tl" | field appline_from)"
    local prev; prev="$(sed -n "1,${from_n}p" "$APP" 2>/dev/null | grep -aoE '^EVT tb\.text=[0-9]+' | sed 's/.*=//' | tail -1)"; prev="${prev:-0}"
    local seq_n mono=1 last="$prev" v
    seq_n=0
    for v in $(printf '%s' "$S" | grep -aoE '^EVT tb\.text=[0-9]+' | sed 's/.*=//'); do
      seq_n=$((seq_n + 1)); [ "$v" -ge "$last" ] || mono=0; last="$v"
    done
    if [ "$seq_n" -lt "$EXPECT_TYPEWORDS" ]; then crit c03 1 "键入 ${EXPECT_TYPEWORDS} 字符但 tb.text= 只有 $seq_n 行（< $EXPECT_TYPEWORDS）"
    elif [ "$mono" != 1 ]; then crit c03 1 "tb.text 长度不是单调不减（序列末值=$last）"
    elif [ "$last" -lt "$(( prev + EXPECT_TYPEWORDS ))" ]; then crit c03 1 "文本净增不足：$prev → $last（期望 ≥ $(( prev + EXPECT_TYPEWORDS ))）"
    else crit c03 0 "键入 ${EXPECT_TYPEWORDS} 字符：tb.text= $seq_n 行、长度 $prev → $last（单调不减）"; fi
  fi
  # c04 ④正：combo.opened = 1 ＋ 弹窗窗口 IsViewable
  S="$(slice L6_combo)"
  local nopen; nopen="$(printf '%s' "$S" | grep -acE '^EVT combo\.opened[[:space:]]*$' || true)"; nopen="${nopen:-0}"
  local npop; npop="$(er 'popup id=L6_combo ' | grep -ac 'map=IsViewable' || true)"; npop="${npop:-0}"
  if [ "$nopen" != 1 ]; then crit c04 1 "点 ComboBox ⇒ combo.opened 行数=$nopen（期望 1）"
  elif [ "$npop" -lt 1 ]; then crit c04 1 "combo.opened 有了但**没有**新的 X 窗口处于 IsViewable（WPF 说开着、屏幕上没有）"
  else crit c04 0 "点 ComboBox ⇒ combo.opened=1 ＋ 新 X 窗口 IsViewable（$npop 个）"; fi
  # c05 ⑤正：点弹窗 item1 ⇒ combo.selection=1 ＋ combo.closed
  local l8; l8="$(sm L8_comboitem1)"
  if [ -z "$l8" ]; then
    crit c05 2 "缺 L8 记录"
  elif grep -q 'kind=skipped' <<<"$l8"; then
    crit c05 2 "L8 未落点（reason=$(printf '%s' "$l8" | field reason)）"
  else
    S="$(slice L8_comboitem1)"
    if grep -qE '^EVT combo\.selection=1[[:space:]]*$' <<<"$S" && grep -qE '^EVT combo\.closed[[:space:]]*$' <<<"$S"; then
      crit c05 0 "点弹窗 item1 ⇒ combo.selection=1 ＋ combo.closed"
    else
      local got; got="$(printf '%s' "$S" | grep -aE '^EVT combo\.(selection|closed)' | tr '\n' ' ')"
      crit c05 1 "点弹窗 item1 后切片里缺 combo.selection=1 或 combo.closed（实得：${got:-无）}"
    fi
  fi
  # c06 ⑥：**每次 mouse-up 之后 cap=none**（`D-G55` 指纹）—— 三条口径必须在实现里写清：
  #   ① 读的是该腿切片里**最后一条** `captured=` 读数（＝ **时间上最晚**的那次观测），**不是"切片里出现过"**：
  #      后者会被**点击前**那条 move（那时捕获还没建立）满足 ⇒ **假绿**（本件第一版实测：7/11 而不是 5/11）。
  #      【`#90` `W90A` 加强 · `TASK-0208`】**取数来源从"只认 `EVT move`"放宽到"认所有 `captured=` 读数"**，
  #      但**判据本身一格没松**（仍是"最后一条读数必须 `captured=null`"）。为什么必须换：
  #      原口径**只**认主窗口卡片的 `MouseMove`；而"点弹窗项"那条腿（`L8`）的挪动**正确地**落在
  #      **弹窗窗口**上 ⇒ 修好之后主窗口卡片**一条 move 都读不到** ⇒ 判据回退去读**点击之前**那条
  #      （那时下拉正开着、`ComboBox` 持有捕获**合法**）⇒ **红的是"读不到"，不是"读到了错的值"**
  #      （`build/MilBridge/W88A-report.md` §3.4 已定死；`W90A-report.md` §1 在本件自己的输出目录里复算）。
  #      ⇒ 探针在 `DropDownClosed` 处补一条**同一时刻的 `Mouse.Captured` 直读**
  #      （`samples/WpfFeatureProbe/FeatureBlocks.cs` 的 `EVT capture at=combo.closed captured=`）
  #      ⇒ 那一格从"读不到"变成"**读得对**、而且**看得更晚**"。
  #      ⚠️ **换来源不等于放宽**，两条硬界线（本件成对读数已证）：
  #        (a) 腿里**一条 `captured=` 都没有** ⇒ 仍判**红**（`读不到不许当绿`；旧件在 `L8` 那格正是这种"读不到"）；
  #        (b) 腿里有 `EVT move` 的情形下，旧读数是新读数的**子集**（旧 = 最后一条 move 的 captured；
  #            新 = 时间上更晚或同一条）⇒ **只有"旧件无数据可读"的那一格才可能翻转**，不可能把旧的绿翻红之外放宽。
  #   ② **"下拉还开着"的腿豁免**：WPF 的 `ComboBox` 在**弹窗打开期间**本来就持有捕获（这是语义，不是缺陷）
  #      ⇒ 若一刀切，健康的树也会**恒红**（"假红侵蚀对红数的信任"）。判据 = 该腿切片里
  #      `combo.opened` 多于 `combo.closed` ⇒ 这条腿**豁免**（并在屏上具名印出豁免数）。
  #      豁免**只覆盖"开着"这一档**：下拉**已关**却仍 `captured≠null` ⇒ 照样红（这正是本步抓到的那条真缺陷）。
  #      ⚠️ 豁免规则**一字未动**（本件没给 `L8` 开任何新豁免）。
  #   ③ `stuck` 名单的**文字形状一字未动**（仍 `"<id> "` 空格分隔）⇒ 反极性那趟的 `fails=` 行与基线**逐字相同**。
  local nc=0 ncap=0 nexc=0 stuck="" exc="" nosrc="" reads=""
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    local id; id="$(printf '%s' "$l" | field id)"
    nc=$((nc + 1))
    S="$(slice "$id")"
    local nop ncl
    nop="$(printf '%s' "$S" | grep -acE '^EVT combo\.opened[[:space:]]*$' || true)"; nop="${nop:-0}"
    ncl="$(printf '%s' "$S" | grep -acE '^EVT combo\.closed[[:space:]]*$' || true)"; ncl="${ncl:-0}"
    if [ "$nop" -gt "$ncl" ]; then nexc=$((nexc + 1)); exc="${exc}${id} "; reads="${reads}${id}=<豁免:下拉仍开> "; continue; fi
    local lastcap
    lastcap="$(printf '%s' "$S" | grep -aoE 'captured=[A-Za-z_.]+' | tail -1)"
    reads="${reads}${id}=${lastcap:-<无读数>} "
    if [ -z "$lastcap" ]; then nosrc="${nosrc}${id} "; continue; fi
    if [ "$lastcap" = "captured=null" ]; then ncap=$((ncap + 1)); else stuck="${stuck}${id} "; fi
  done < <(er 'step id=' | grep -a 'kind=click')
  # 逐腿把"判据实际读到的**最后一条** `captured=`"印出来（**新增的可审行**；三态机读行不受它影响）
  printf '  ∟ c06 读数（非豁免腿的最后一条 captured=）：%s\n' "${reads:-<无点击腿>}"
  if [ "$nc" -eq 0 ]; then crit c06 2 "没有点击腿记录"
  elif [ -n "$nosrc" ]; then
    crit c06 1 "该腿切片里**一条 captured= 读数都没有**（读不到 ⇒ **不许当绿**）：$nosrc"
  elif [ -n "$stuck" ]; then
    crit c06 1 "鼠标抬起后捕获没释放的腿：$stuck（下拉**已关**却仍 captured≠null；D-G55 指纹 —— 之后所有点击都会被路由到那个控件）"
  else crit c06 0 "非豁免的 $ncap 下点击：最后一条 captured= 为 null（豁免 $nexc 下 = 下拉仍开着的腿：${exc:-无}）"; fi
  # c07 ①反：点卡片右侧空白 ⇒ 控件级 EVT = 0 且点击确实到达窗口
  local bl; bl="$(sm L2_blank)"
  if [ -z "$bl" ]; then crit c07 2 "缺 L2 空白点击记录"
  else
    S="$(slice L2_blank)"
    local w_evt; w_evt="$(printf '%s' "$S" | grep -acE '^EVT (lst|tb|combo)\.' || true)"; w_evt="${w_evt:-0}"
    local dd; dd="$(printf '%s' "$bl" | field down_delta)"
    if [ "$w_evt" != 0 ]; then crit c07 1 "点卡片空白却出了 $w_evt 行控件级 EVT（点击坐标不可信 ⇒ 判据面被污染）"
    elif [ "${dd:-0}" -lt 1 ]; then crit c07 1 "空白点击没到窗口（WM_LBUTTONDOWN 未增），此格不成立"
    else crit c07 0 "点卡片空白：控件级 EVT = 0（WM_LBUTTONDOWN +$dd，点击确实到达窗口）"; fi
  fi
  # c08 ②反：点窗口外 ⇒ 无控件级 EVT
  local ol; ol="$(sm L1_outside)"
  if [ -z "$ol" ]; then crit c08 2 "缺 L1 窗口外点击记录"
  else
    S="$(slice L1_outside)"
    local w_evt2; w_evt2="$(printf '%s' "$S" | grep -acE '^EVT (lst|tb|combo)\.' || true)"; w_evt2="${w_evt2:-0}"
    if [ "$w_evt2" != 0 ]; then crit c08 1 "点窗口外却出了 $w_evt2 行控件级 EVT"
    else crit c08 0 "点窗口外（inside=0）：控件级 EVT = 0"; fi
  fi
  # c09 ③反：未点击就键入 ⇒ tb.focus / tb.text 不增；**且必须证明键真到了应用**（否则这一格是空的）
  local t0; t0="$(sm L0_type_nofocus)"
  if [ -z "$t0" ]; then crit c09 2 "缺 L0（未点击就键入）记录"
  else
    S="$(slice L0_type_nofocus)"
    local kd cd; kd="$(printf '%s' "$t0" | field keydown_delta)"; cd="$(printf '%s' "$t0" | field char_delta)"
    if [ "${kd:-0}" -lt 1 ] && [ "${cd:-0}" -lt 1 ]; then
      crit c09 2 "键没到应用（keydown_delta=${kd:-0} char_delta=${cd:-0}）⇒ 这一格证明不了任何事"
    else
      local f_evt t_evt
      f_evt="$(printf '%s' "$S" | grep -acE '^EVT tb\.focus[[:space:]]*$' || true)"; f_evt="${f_evt:-0}"
      t_evt="$(printf '%s' "$S" | grep -acE '^EVT tb\.text=' || true)"; t_evt="${t_evt:-0}"
      if [ "$f_evt" != 0 ] || [ "$t_evt" != 0 ]; then crit c09 1 "**没点就键入**却拿到焦点/文本（tb.focus=$f_evt tb.text=$t_evt）⇒ 焦点不是点击给的"
      else crit c09 0 "未点击就键入（keydown +$kd）：tb.focus/tb.text 都不增"; fi
    fi
  fi
  # c10 ④反：下拉开着时点下拉外空白 ⇒ 不得出现 combo.selection
  local l7; l7="$(sm L7_combo_blank)"
  if [ -z "$l7" ]; then crit c10 2 "缺 L7 记录"
  else
    S="$(slice L7_combo_blank)"
    local cs; cs="$(printf '%s' "$S" | grep -acE '^EVT combo\.selection=' || true)"; cs="${cs:-0}"
    if [ "$cs" != 0 ]; then crit c10 1 "点下拉外的空白却出了 $cs 行 combo.selection（下拉命中面溢出）"
    else crit c10 0 "下拉开着时点下拉外空白：combo.selection = 0"; fi
  fi
  # c11 ⑦承重连续腿：窗口内连点三下，各自 EVT 都出
  local seqbad=""
  S="$(slice SEQ_lst0)";  grep -qE '^EVT lst\.selection=0[[:space:]]*$' <<<"$S" || seqbad="${seqbad}seq-lst0 "
  S="$(slice SEQ_tb)";    grep -qE '^EVT tb\.focus[[:space:]]*$'        <<<"$S" || seqbad="${seqbad}seq-tb "
  S="$(slice SEQ_combo)"; grep -qE '^EVT combo\.opened[[:space:]]*$'    <<<"$S" || seqbad="${seqbad}seq-combo "
  if [ -z "$seqbad" ]; then crit c11 0 "连续三下（窗口内、指针不出窗）：三下各自的 EVT 都出现"
  else crit c11 1 "连续腿缺格：$seqbad（**这一格是 D-G55 的判据** —— 单发点击会假绿）"; fi
  # c12 `D-G49` 字段：down=Pressed / up=Released
  S="$(slice L3_lst1)"
  if grep -qE '^EVT lst\.down .*state=Pressed' <<<"$S" && grep -qE '^EVT lst\.up .*state=Released' <<<"$S"; then
    crit c12 0 "点 item1：down 报 state=Pressed、up 报 state=Released（D-G49 字段）"
  else
    local st; st="$(printf '%s' "$S" | grep -aE '^EVT lst\.(down|up)' | tr '\n' ' ')"
    crit c12 1 "按钮状态字段不对（实得：${st:-无}）"
  fi
  # c13 ⑧像素：下拉打开时测试色 > 0
  local pxo pxc
  pxo="$(kvf 'pixels id=open' value)"; pxc="$(kvf 'pixels id=closed_before' value)"
  if [ -z "${pxo:-}" ]; then crit c13 2 "缺 pixels open 读数"
  elif [ "${pxo:-0}" -lt "$MIN_PX_OPEN" ]; then crit c13 1 "下拉打开时测试色 22D3EE 像素 = ${pxo:-0}（屏幕上没有下拉项容器）"
  elif [ -n "${pxc:-}" ] && [ "${pxc:-0}" -gt 0 ] && [ "$pxo" -le "$pxc" ]; then crit c13 1 "开着($pxo) 不大于关着($pxc) ⇒ 测试色不是下拉专指"
  else crit c13 0 "下拉打开时测试色 22D3EE 像素 = $pxo（关着时 ${pxc:-n/a}）"; fi

  # ── 2. 逐下点击"到达窗口"的下界（每一下点击都必须真的进过我们的窗口）────────────
  local notrecv=""
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    local id ins dd
    id="$(printf '%s' "$l" | field id)"; ins="$(printf '%s' "$l" | field inside)"; dd="$(printf '%s' "$l" | field down_delta)"
    [ "$ins" = 1 ] || continue
    [ "${dd:-0}" -ge 1 ] || notrecv="${notrecv}${id} "
  done < <(er 'step id=' | grep -a 'kind=click')
  if [ -n "$notrecv" ]; then red "click-not-received($notrecv)"; printf '  ∟ RED   窗口内点击却没收到 WM_LBUTTONDOWN：%s（输入路径没把点击送到）\n' "$notrecv"
  else printf '  ∟ PASS  下界：窗口内的每一下点击都收到了 WM_LBUTTONDOWN（**不计入判据格**）\n'; fi

  # ── 3. 判定（判序：**有红先红**；无红但有"判不了" ⇒ NOINFO）─────────────────────
  local verdict rc
  if [ "${#REDS[@]}" -gt 0 ]; then
    verdict="FAIL"; rc=1
  elif [ "$sab" != "none" ]; then
    verdict="FAIL"; rc=1; REDS+=("sabotage-not-caught($sab 已设却全格通过 ⇒ 装置没有判别力)")
  elif [ "${#SKIPS[@]}" -gt 0 ]; then
    verdict="NOINFO"; rc=2
  else
    verdict="PASS"; rc=0
  fi
  local crit_line="crit=$OKS/$CRIT_TOTAL"
  case "$verdict" in
    PASS)  echo "R_GATE=PASS $crit_line clicks=$nclicks ok=$OKS red=0 noinfo=0 popup=$npop px_open=${pxo:-?} px_closed=${pxc:-?} sabotage=$sab win=${winw}x${winh} mem_mb=${mem_mb:-?} win32shim=${shim:-?} pc=${pc:-?} src=$src" ;;
    FAIL)  echo "R_GATE=FAIL $crit_line clicks=$nclicks ok=$OKS red=${#REDS[@]} noinfo=${#SKIPS[@]} popup=$npop px_open=${pxo:-?} sabotage=$sab win=${winw}x${winh} src=$src fails=$(printf '%s' "${REDS[*]}" | tr ' ' ',')" ;;
    NOINFO) echo "R_GATE=NOINFO $crit_line clicks=$nclicks ok=$OKS red=0 noinfo=${#SKIPS[@]} src=$src cannot=$(printf '%s' "${SKIPS[*]}" | tr ' ' ',')" ;;
  esac
  return $rc
}

# ═══════════════════════════════════════════════════════════════════════════════
#  --selftest：**反极性**（合成证据；**零 X、零 dotnet**）
#   纪律 68 的落点：**每一条判据都有例**，且夹具只依赖自己写进临时目录的东西（不读冻结基线、
#   不读世代号、不读仓内件）⇒ 前提**自持**（重冻/换代不会把它打掉）。
# ═══════════════════════════════════════════════════════════════════════════════
if [ "$SELFTEST" = 1 ]; then
  if [ -z "${ST_ATTEST_INNER:-}" ]; then
    ST0="$(sha256sum "$SELF" | cut -c1-16)"
    printf 'ST_ATTEST=OPEN self=%s sha16=%s\n' "$SELF" "$ST0"
    ST_OUT="$(ST_ATTEST_INNER=1 bash "$SELF" --selftest 2>&1)"; ST_RC=$?
    printf '%s\n' "$ST_OUT"
    ST1="$(sha256sum "$SELF" | cut -c1-16)"
    if [ "$ST1" != "$ST0" ]; then
      printf 'ST_ATTEST=NOINFO reason=self-rewritten-during-selftest self=%s sha0=%s sha1=%s inner_rc=%s\n' "$SELF" "$ST0" "$ST1" "$ST_RC"
      exit 2
    fi
    printf 'ST_ATTEST=PASS self=%s sha16=%s（自测期间本件未变 ⇒ 读数可归因）\n' "$SELF" "$ST0"
    exit "$ST_RC"
  fi
  T="$(mktemp -d "${TMPDIR:-/tmp}/r-gate-selftest.XXXXXX")"; trap 'rm -rf "$T"' EXIT

  # ── 夹具：造一份"全绿"的证据目录；`MUT` 逐档注入一个缺陷 ────────────────────────
  mkfix() {  # mkfix <dir> <mut>
    local d="$1" mut="${2:-good}" A="$1/app.log" n=0
    mkdir -p "$d"; : > "$A"; : > "$d/evidence.txt"
    em()  { printf '%s\n' "$*" >> "$A"; n=$((n + 1)); }
    # ⚠️ **缺陷一律在"生成日志时"注入，不许事后 `sed` 日志**：日志少一行/多一行都会让
    #   证据里的 `appline_from/to` 整体错位 ⇒ 切片串腿 ⇒ **红的是夹具，不是判据**
    #   （本件第一版就是这样：删 `EVT lst.selection=1` 一行，连带把 c03/c05 打红）。
    emx()  { local s="$1"; shift; [ "$mut" = "$s" ] && return 0; em "$*"; }   # 该档 ⇒ **不**写这一行
    ema()  { local s="$1"; shift; [ "$mut" = "$s" ] || return 0; em "$*"; }   # 该档 ⇒ **额外**写这一行
    emx2() { local a="$1" b="$2"; shift 2; { [ "$mut" = "$a" ] || [ "$mut" = "$b" ]; } && return 0; em "$*"; }
    ev()  { printf 'EVID %s\n' "$*" >> "$d/evidence.txt"; }
    local CAPV="null" CAPV8="null" CAPD="null" L3DOWN="state=Pressed"
    [ "$mut" = "cap-not-released" ] && CAPV="ListBox"
    # `cap-stuck-after-close`＝**真缺陷的形态**：下拉**已关**（`combo.closed` 有了）却仍 `captured=ComboBox`
    #   ⇒ 之后的 SEQ 点击被路由到 ComboBox、拿不到 lst/tb 的 EVT（本件在现役树上实测到的就是这一形态）。
    [ "$mut" = "cap-stuck-after-close" ] && CAPV8="ComboBox"
    # 【`#90` `W90A` 加】`CAPD` = **直读**（`DropDownClosed` 处的 `captured=`）那一档的取值。
    #   它必须跟着同一个档位走：否则 `good` 档会绿得没有牙、`cap-stuck-after-close` 档会红得没来源。
    [ "$mut" = "cap-stuck-after-close" ] && CAPD="ComboBox"
    [ "$mut" = "down-state-wrong" ] && L3DOWN="state=Released"
    ev "env mem_mb=2600 min_mb=1000 load=1.0 nproc=3 kernel=fixture"
    ev "sabotage kind=none"
    ev "art probe=ffffffffffffffff win32shim=3e4390c9ec07f621 pc=56ee75ced8d6aece pf=6375fabf89ac7fef wb=2e4e46e539a72cd7 bridge=feef049e9d0e313a wic=f7b3026c8c019be2"
    ev "win id=0x200005 x=0 y=0 w=1000 h=700"
    ev "pos tag=lst relx=294 rely=40 w=260 h=78";   ev "pos tag=tb relx=294 rely=130 w=260 h=26"
    ev "pos tag=combo relx=294 rely=170 w=260 h=26"; ev "pos tag=lstitem1 relx=2 rely=26 w=256 h=26"
    ev "pos tag=comboitem1 relx=2 rely=26 w=256 h=24"
    ev "blank x=634 y=160"

    # 每个"腿"= from 行号 → 若干 EVT 行 → to 行号；切片 = (from, to]
    leg() {  # leg <id> <kind> <extra...>  ← 之后用 em 写该腿的行，再 leg_end
      LEG_ID="$1"; LEG_KIND="$2"; shift 2; LEG_EXTRA="$*"; LEG_FROM="$n"
    }
    leg_end() { ev "step id=$LEG_ID kind=$LEG_KIND $LEG_EXTRA appline_from=$LEG_FROM appline_to=$n"; }

    leg L0_type_nofocus type "chars=3 keydown_delta=3 char_delta=0"
    ema type-focuses "EVT tb.focus"
    em "msg=0x0100 WM_KEYDOWN"
    leg_end
    leg L1_outside click "x=-60 y=-40 inside=0 down_delta=0 up_delta=0"
    em "EVT move root=340,160 src=Grid directlyover=Grid freshhit=Grid captured=$CAPV"
    leg_end
    leg L2_blank click "x=634 y=160 inside=1 down_delta=1 up_delta=1"
    emx blank-hits-widget "EVT card.down src=Grid state=Pressed clicks=1"
    ema blank-hits-widget "EVT lst.selection=2"
    em "EVT move root=340,160 src=Grid directlyover=Grid freshhit=Grid captured=$CAPV"
    leg_end
    leg L3_lst1 click "x=424 y=93 inside=1 down_delta=1 up_delta=1"
    em "EVT lst.down src=ListBoxItem $L3DOWN clicks=1"
    emx no-lst-selection "EVT lst.selection=1"
    em "EVT lst.up src=ListBoxItem state=Released"
    em "EVT move root=426,93 src=ListBoxItem directlyover=ListBoxItem freshhit=ListBoxItem captured=$CAPV"
    leg_end
    leg L4_tb click "x=424 y=143 inside=1 down_delta=1 up_delta=1"
    em "EVT tb.down src=TextBoxView state=Pressed"
    emx no-tb-focus "EVT tb.focus"
    em "EVT tb.up state=Released"
    em "EVT move root=426,143 src=TextBoxView directlyover=TextBoxView freshhit=TextBoxView captured=$CAPV"
    leg_end
    leg L5_type_abc type "chars=3 keydown_delta=3 char_delta=3"
    emx no-net-growth "EVT tb.text=1 text='a'"
    emx no-net-growth "EVT tb.text=2 text='ab'"
    # 该档：**三行**、长度 1/1/1 ⇒ 行数够（3）但**净增只有 1**（< 3）⇒ 必须走"净增不足"那一支
    ema no-net-growth "EVT tb.text=1 text='a'"
    ema no-net-growth "EVT tb.text=1 text='a'"
    ema no-net-growth "EVT tb.text=1 text='a'"
    emx2 short-type no-net-growth "EVT tb.text=3 text='abc'"
    leg_end
    leg L6_combo click "x=424 y=183 inside=1 down_delta=1 up_delta=1"
    em "EVT combo.down src=ComboBox state=Pressed"
    em "EVT combo.opened"
    em "EVT combo.up state=Released"
    em "EVT move root=426,183 src=ComboBox directlyover=ComboBox freshhit=ComboBox captured=$CAPV"
    leg_end
    ev "popup id=L6_combo win=0x300008 map=IsViewable x=294 y=196 w=271 h=77"
    ev "pixels id=closed_before value=0"
    ev "pixels id=open value=19449"
    leg L7_combo_blank click "x=634 y=183 inside=1 down_delta=1 up_delta=1"
    em "EVT card.down src=Grid state=Pressed clicks=1"
    em "EVT move root=340,183 src=Grid directlyover=Grid freshhit=Grid captured=$CAPV"
    leg_end
    leg L6b_combo_reopen click "x=424 y=183 inside=1 down_delta=1 up_delta=1"
    em "EVT combo.down src=ComboBox state=Pressed"
    em "EVT combo.opened"
    em "EVT combo.up state=Released"
    em "EVT move root=426,183 src=ComboBox directlyover=ComboBox freshhit=ComboBox captured=$CAPV"
    leg_end
    ev "popup id=L6b_combo_reopen win=0x300009 map=IsViewable x=294 y=196 w=271 h=77"
    leg L8_comboitem1 click "x=424 y=208 inside=1 down_delta=1 up_delta=1"
    emx wrong-item "EVT combo.selection=1"
    ema wrong-item "EVT combo.selection=2"
    em "EVT combo.closed"
    # 【`#90` `W90A` 加】**这一腿照现实改**（现役树实测：`L8` 切片里唯一一条 `EVT move` 是**点击之前**那条，
    #   mouse-up 之后**一条都读不到** —— 见 `W90A-report.md` §1）：
    #   · **删掉** `L8` 的 `EVT move` 行（＝修好之后主窗口卡片真的打不出这一行）；
    #   · 改由探针新补的**直读**行（`DropDownClosed` 处的 `captured=`）决定这一格。
    #   ⇒ 这是**加严**而非放宽：旧读法在这一腿**无数据可读**（旧件在此只能判红）；
    #     新读法必须**真的读到 `null`** 才允许绿，读到 `ComboBox` ⇒ 照样红（`S7b` 档）。
    em "EVT capture at=combo.closed captured=$CAPD"
    leg_end
    leg SEQ_lst0 click "x=424 y=52 inside=1 down_delta=1 up_delta=1"
    em "EVT lst.down src=ListBoxItem state=Pressed clicks=1"
    emx cap-stuck-after-close "EVT lst.selection=0"
    em "EVT lst.up src=ListBoxItem state=Released"
    em "EVT move root=426,52 src=ComboBox directlyover=ComboBox freshhit=ListBoxItem captured=$CAPV8"
    leg_end
    leg SEQ_tb click "x=424 y=143 inside=1 down_delta=1 up_delta=1"
    em "EVT tb.down src=TextBoxView state=Pressed"
    emx cap-stuck-after-close "EVT tb.focus"
    em "EVT tb.up state=Released"
    em "EVT move root=426,143 src=ComboBox directlyover=ComboBox freshhit=TextBoxView captured=$CAPV8"
    leg_end
    leg SEQ_combo click "x=424 y=183 inside=1 down_delta=1 up_delta=1"
    em "EVT combo.down src=ComboBox state=Pressed"
    emx seq-combo-missing "EVT combo.opened"
    em "EVT combo.up state=Released"
    em "EVT move root=426,183 src=ComboBox directlyover=ComboBox freshhit=ComboBox captured=$CAPV"
    leg_end
    em "STATE clickprobe lst.sel=-1 tb.len=3 combo.open=true kbd=null win=0,0,1000x700"
    ev "state value=STATE clickprobe lst.sel=-1 tb.len=3 combo.open=true kbd=null win=0,0,1000x700"
    ev "appalive value=yes"
    ev "device=OK out=$d appdir=$d/app display=:88"

    # ── 剩下的缺陷档一律只动 `evidence.txt`（**行号不受影响**）────────────────────────
    case "$mut" in
      good|no-lst-selection|no-tb-focus|short-type|no-net-growth|wrong-item|seq-combo-missing|cap-not-released|cap-stuck-after-close|blank-hits-widget|type-focuses|down-state-wrong) ;;
      no-popup-window)   sed -i 's/^EVID popup id=L6_combo .*map=IsViewable/EVID popup id=L6_combo win=0x300008 map=IsUnmapped x=294 y=196 w=271 h=77/' "$d/evidence.txt" ;;
      keys-not-delivered) sed -i 's/kind=type chars=3 keydown_delta=3 char_delta=0/kind=type chars=3 keydown_delta=0 char_delta=0/' "$d/evidence.txt" ;;
      no-px-open)        sed -i 's/^EVID pixels id=open value=19449/EVID pixels id=open value=0/' "$d/evidence.txt" ;;
      app-died)          sed -i 's/^EVID state value=.*/EVID state value=MISSING/' "$d/evidence.txt" ;;
      no-clicks)         sed -i '/kind=click/d' "$d/evidence.txt" ;;
      sabotage-passthru) sed -i 's/^EVID sabotage kind=none/EVID sabotage kind=windowmove dx=300 dy=250/' "$d/evidence.txt" ;;
      device-noinfo)     sed -i 's/^EVID device=OK .*/EVID device=NOINFO reason=tools-missing 缺 X 工具：xdotool=MISSING/' "$d/evidence.txt" ;;
      pos-combo-missing) sed -i '/^EVID pos tag=combo /d' "$d/evidence.txt" ;;
      click-not-received) sed -i 's/kind=click x=634 y=160 inside=1 down_delta=1/kind=click x=634 y=160 inside=1 down_delta=0/' "$d/evidence.txt" ;;
      *) echo "未知 MUT=$mut" >&2; return 1 ;;
    esac
  }

  np=0; nf=0
  chk() {  # chk <例名> <期望rc> <期望机读行子串> <mut>
    local nm="$1" want="$2" pat="$3" mut="$4" d out rc
    d="$T/$mut"; rm -rf "$d"; mkfix "$d" "$mut" >/dev/null 2>&1
    out="$(judge_dir "$d" fixture 2>&1)"; rc=$?
    if [ "$rc" = "$want" ] && grep -qF "$pat" <<< "$out"; then
      np=$((np + 1)); printf '  %-22s => yes  rc=%s  %s\n' "$nm" "$rc" "$(grep -aE '^R_GATE=' <<< "$out" | head -1)"
      [ "${R_GATE_ST_VERBOSE:-0}" = 1 ] && printf '%s\n' "$out" | grep -aE '^R_GATE=|∟' | sed 's/^/        | /'
    else
      nf=$((nf + 1)); printf '  %-22s => NO   want rc=%s/%s got rc=%s\n' "$nm" "$want" "$pat" "$rc"
      printf '%s\n' "$out" | grep -aE '^R_GATE=|∟.*RED' | head -4 | sed 's/^/        | /'
    fi
  }
  echo "== R-GATE 判据件的 --selftest（**零 X、零 dotnet**；合成证据；前提自持）=="
  chk "S1 正极性（全绿）"       0 "R_GATE=PASS"                 good
  chk "S2 c01 点 item1 无反应"  1 "c01("                        no-lst-selection
  chk "S3 c02 点 TextBox 无焦点" 1 "c02("                       no-tb-focus
  chk "S4 c03 键入只出 2 行"    1 "c03("                        short-type
  chk "S4b c03 3 行但净增不足"  1 "c03("                        no-net-growth
  chk "S5 c04 弹窗没上屏"       1 "c04("                        no-popup-window
  chk "S6 c05 选错项（=2）"     1 "c05("                        wrong-item
  chk "S7 c06 捕获没释放"       1 "c06("                        cap-not-released
  chk "S7b c06 下拉关了仍抓捕获" 1 "c06("                       cap-stuck-after-close
  chk "S8 c07 空白点出控件 EVT" 1 "c07("                        blank-hits-widget
  chk "S9 c09 没点就拿到焦点"   1 "c09("                        type-focuses
  chk "S10 c09 键没到应用"      2 "R_GATE=NOINFO"               keys-not-delivered
  chk "S11 c11 连做缺 seq-combo" 1 "c11("                       seq-combo-missing
  chk "S12 c12 按钮状态反了"    1 "c12("                        down-state-wrong
  chk "S13 c13 下拉没像素"      1 "c13("                        no-px-open
  chk "S14 应用中途死"          2 "R_GATE=NOINFO"               app-died
  chk "S15 点击下限（0 下）"    2 "R_GATE=NOINFO"               no-clicks
  chk "S16 sabotage 未捕获"     1 "sabotage-not-caught"         sabotage-passthru
  chk "S17 装置自报 NOINFO"     2 "R_GATE=NOINFO"               device-noinfo
  chk "S17b combo 坐标缺席（前缀陷阱）" 2 "pos-missing"          pos-combo-missing
  chk "S18 窗口内点击没收到"    1 "click-not-received"          click-not-received
  echo "R_GATE_SELFTEST=$([ "$nf" -eq 0 ] && echo PASS || echo FAIL) cases=$((np + nf)) pass=$np fail=$nf crit_total=$CRIT_TOTAL"
  [ "$nf" -eq 0 ] && exit 0 || exit 1
fi

# ═══════════════════════════════════════════════════════════════════════════════
#  正常模式（= `verify-all.sh` 第 `[26]` 步）
# ═══════════════════════════════════════════════════════════════════════════════
if [ -n "$JUDGE_DIR" ]; then
  judge_dir "$JUDGE_DIR" external
  exit $?
fi

[ -f "$DEVICE" ] || { echo "R_GATE=NOINFO reason=device-absent path=$DEVICE"; exit 2; }
OUT="${R_GATE_OUT:-/tmp/r-gate-step-$$}"
# ⚠️ 必须先建目录：下面那句 `> "$OUT/device.out"` 的**重定向先于**装置执行（装置内部的 `mkdir -p` 来不及）
#    ⇒ 不建的话 `bash: … 没有那个文件或目录` ⇒ rc≠0 ⇒ 被读成"装置异常"（本件第一版实测踩到）。
mkdir -p "$OUT" || { echo "R_GATE=NOINFO reason=out-dir-unwritable out=$OUT"; exit 2; }
echo "R_GATE 仪器 装置=$DEVICE｜证据目录=$OUT｜口径：判据格 $CRIT_TOTAL 格／必须真点击 $EXPECT_CLICKS_MUST 下"
if ! timeout "${R_GATE_DEVICE_TIMEOUT:-240}" bash "$DEVICE" --out "$OUT" ${R_GATE_DEVICE_ARGS:-} > "$OUT/device.out" 2>&1; then
  echo "R_GATE=NOINFO reason=device-exit detail=装置 rc≠0 或被 timeout 杀（见 $OUT/device.out）"
  tail -6 "$OUT/device.out" | sed 's/^/      | /'
  exit 2
fi
sed -n '1,12p' "$OUT/device.out" | sed 's/^/      · /'
judge_dir "$OUT" device
rc=$?
echo "R_GATE 证据目录（复核用）：$OUT（evidence.txt ＋ app.log）"
[ "$KEEP" = 1 ] || :
exit $rc

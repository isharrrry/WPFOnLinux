#!/usr/bin/env bash
# ============================================================================
# column-floor-check.sh —— 「**列级下限值本身**」的外挂读者（`D-G27`；**在册、只读**、零 `dotnet`、零世代成本）
#
# 【它治什么】
#   `D-G14`/`D-G19` 两颗牙都是「**下限式**」牙：门禁把 `known-red.json` 的
#   `generation.column_gate.arms[<臂>].{judged_min,released_min}` 与
#   `generation.column_gate.additional.arms[<臂>].judged_min` 当**权威**读，
#   判「本世代这一列**已经判过多少行**」。
#   ⇒ **把那三个整数改小，门禁就照着新下限比、仍然 `PASS`**。
#   ⇒ 这三个数的**唯一声明处**就是那一份 `known-red.json`（自指：自己声明自己）
#      ⇒ 「改小」曾是**一处编辑、零机器红**（本件的立项证据 = 用真臂日志副本实测，见报告 §A）。
#
# 【判据（逐字，可反驳）】
#   对冻结块声明的**每一个** (臂, 列, 键) 三元组，要求：
#     ① **登记表声明值 == 冻结块声明值**（`known-red.json` ⇔ `ACCEPTANCE-BASELINE.md` 的
#        **最新** `# RE-FROZEN` 块里的 `# COLUMN-FLOOR` 行）；
#     ② **声明值 ≥ 冻结真值语料当场复算出的下界**（`tab-anchor-oracle.json`）；
#     ③ 语料件本身的 sha16 == 冻结块 `# COLUMN-CORPUS` 行声明的 sha16；
#     ④ （附带比对）门禁机读行**自报**的 `judged_min=`/`released_min=` == 冻结块声明值。
#     ⑤ （**可选、附加**）冻结块若声明了 `# ARM-LOG-SHA arm=<名> sha16=<16hex>` 行，则要求
#        `generation.arm_logs[<名>]` 的前 16 位 == 它。**这半正是 `D-G9` 的残差**：
#        `arm_logs` 今天也是"自己声明自己"（失真日志 ＋ 同趟把 `arm_logs` 也改掉 ⇒
#        `ARMLOG_SHA=PASS pass=5 fail=0`，本件报告 §A.3 有实测），它需要的**正是一份别的文件里的**声明。
#        ⚠️ ⑤ **刻意设计成"缺行不判"**（`NOTDECLARED`，**不并入 rc**）：本件的**必做射程**是那三个整数
#        （与重冻 `#30` 同趟只插 3 行）⇒ 若让 ⑤ 缺行变 `NOINFO`，就会**当场挡住 `verify-all` 全绿**
#        （把一件可选加强变成阻塞项）。⇒ 缺行时**大声印**、但不改 rc；要激活它 = 同趟**多插一行**。
#        ⚠️ **如实标注**：因此"`arm_logs` 自指"这条残差**今天仍然活着**，本件只是给它备好了落点。
#   ⚠️ **只有 ③ 回答"这个数该是多少"**：①②④ 都是"两处声明互相印证"，
#      两者可以一起被改；③ 把答案锚在**真值语料**上 —— 语料一变，`615/194/421` 就变。
#
# 【三态（**rc：只有全 PASS 才 0**）】
#   · ① ② ③ 全成立、且 ④ 不 FAIL ⇒ `COLUMN_FLOOR=PASS`、`rc=0`
#   · 任何一条出现**下降/不一致** ⇒ `COLUMN_FLOOR=FAIL`、`rc=1`（点名是哪个键、哪两个数）
#   · **缺声明 / 缺件 / 算不出** ⇒ `COLUMN_FLOOR=NOINFO`、`rc=2`（**缺项不许计入通过**）
#
# 【`judged_min` 的三值（**`#31` W31D 落地** —— `W31B` 把 `additional.arms` 从 1 支臂扩到 3 支臂后必须区分）】
#   `W31B`／`D-G30` 格 (a) 起，`generation.column_gate.additional.arms[<臂>].judged_min` 有**三种**形态：
#     ① **整数** ⇒ 下限（走上面那套阶梯）｜② **显式 `null`** ⇒ 本臂该列**裁定无下限**
#     （`tab-zero`/`tab-rtl` 的 `OVERFLOWED` 整列 `判定行=0` ⇒ 钉整数是恒不可违反的假牙，纪律 47）
#     ｜③ **键缺** ⇒ 未声明（**故障态**）。**三者不许塌成两者** —— 这正是本件 `#31` 那次 `--selftest`
#     回归的根因（修前 `null` 被 Python `%s` 打成 `None`，与"键缺"的哨兵**同字**）。
#   · 判据（冻结块侧同样三态：行里写 `judged_min=none` = **显式无下限**，**不是** `None`）：
#       `decl=none` ＆ `frozen=none` ⇒ **PASS**（两侧都显式无下限 ⇒ 相符；**唯一**把 `none` 判 PASS 的情形）
#       `decl=none` ＆ `frozen=<整数>` ⇒ **FAIL**（**下限静默消失**，与"被下调"同族）
#       `decl=none` ＆ `frozen=<既非整数也非 `none` 的记号>` ⇒ **FAIL**（**形状错必须响亮** ——
#         最要防的就是 Python 的 `None` 又漏进声明行：修前它**与"键缺"同字**、把三态压成两态；
#         本件**不让它静默降级成 `NOINFO`**，`--selftest` 的 `F8-A-MALFORMED-NONE-TOKEN` 把它钉成红）
#       `frozen=none` ＆ `decl=<整数>` ⇒ **NOINFO**（口径不一 ⇒ 逼「重钉 ＋ 重冻」，不制造假绿）
#       `decl=<缺>` ⇒ **NOINFO**（**键缺**，优先级**高于**"口径不一"）｜`frozen=<缺>` ⇒ **NOINFO**
#   · **明示边界**：本件的**迭代集** = 「冻结块声明过的档」∪「登记表侧的**整数**声明」
#     ⇒ 登记表里有 `null` 臂、而**冻结块没声明它**时**不产行**（`--selftest` 的
#     `B4-NULL-ARM-UNFROZEN(边界)` 把这条边界钉成读数）。**消除它的唯一办法**：重冻那一趟把
#     `# COLUMN-FLOOR … judged_min=none` 那几行**同趟插进**最新 `# RE-FROZEN` 块（插了即进迭代集、即受本判据约束）。
#   · ⚠️ **本件不证**「打 `null` 的臂确实没有判定面」（那要读臂日志的 `判定行`）⇒ 那半在门禁的自证里
#     （`GATE_REASON=column-gate-extra-floor-null-but-judged`）；本件这一档只证**两处声明相符**。
#
# 【`decl > frozen`（**合法上调**）为什么判 `NOINFO` 而不是 `FAIL`】
#   上调**不制造假绿**（地板抬高只会更严），把它判 `FAIL` 会诱导人"顺手把冻结块也改掉" ——
#   那正是本条要防的动作。⇒ 判 `NOINFO reason=…`：屏上**不绿也不红**，逼你走「重钉 ＋ 重冻」。
#   ⚠️ 正面回答"合法上调会不会假红"：**不会红**（`rc=2`），但**会挡住 `verify-all` 全绿** ——
#      这是设计：抬高下限 = 读数面变了 = 必须重冻那一趟的基线。
#
# 【`COLUMN_FLOOR_SELFREPORT` 的聚合口径（**逐字说清**）】
#   ④ 那一档**只有 `FAIL` 并入总判决**；它的 `NOINFO` **不并入**（只印、不改 rc）。
#   理由（连代码位置）：门禁的 `GATE_COLUMN=` 行是**无条件**打印的，但 `judged_min=` 只在
#   **该臂有读数**时才出现；而 `tree_gen=advanced` 时三支 tab 臂整臂 NOINFO ⇒ 那一档的
#   `NOINFO` 是**世代状态的函数**，第 `[13]` 步（`BASELINE-SHA`）附近已经报过同一个成因
#   ⇒ 并进来就是**同一成因收两次费**、且本步 rc 被世代状态绑架。
#   ⇒ ④ 的 `FAIL` 才是真信号：**门禁自报的下限 ≠ 冻结声明**（它被指向了另一份登记表 /
#     臂名写死漂移 / 自报的数与它读的数不一致）—— 这是 ①②③ 三档**看不见**的一类。
#
# 【射程（**不许读过头**）】本件证的是「**下限没被改小、也没低于语料**」；
#   **不证**「下限当初钉得对」（那要重取臂 ＋ 独立复算读数，见 W29D 报告 §4）。
#   ⚠️ 已知边界（`decl == frozen` 且 `decl == 语料上界` 时）：三处**同时**改成一致
#   （登记表 ＋ 冻结块 ＋ 语料）不再是"改一处就一起改"的自指，而是**三次协同编辑**，
#   其中一次落在**整份 sha 被机器核对的冻结件**上（`ACCEPTANCE-BASELINE.md` ⇒ 第 `[7]` 步
#   `BASELINE-SHA` 当场红，实测 `BASELINESHA=FAIL`）⇒ 本件的射程止于
#   "**把一次静默编辑变成三次有痕编辑**"。`--selftest` 的 `B3-THREE-WAY` 把这条边界固化成读数。
#
# 【抄了谁（既有范式，不发明）】
#   · `baseline-sha-check.sh`：`set -uo pipefail`｜脚本位置反推仓根｜环境变量覆盖输入件｜
#     一个 `run_check()` 承担全部判定（正常跑与 `--selftest` 共用）｜进函数先把三态置
#     `NOINFO`（默认不绿）｜"全 PASS 才 `return 0`"｜`--selftest` 用 `mktemp -d`。
#   · `arm-log-sha-check.sh`：**每档一行、前缀唯一**（逐臂行 ＋ 一行汇总）⇒ 抽取无歧义；
#     本件照抄成 `COLUMN_FLOOR_<列>_<键>=` 逐档 ＋ `COLUMN_FLOOR=` 汇总。
#     ⚠️ **`#31` W31D 如实更正**：`OVERFLOWED` 一列现在有 **3 支臂**（`additional.arms`）⇒ 这三行的前缀
#     **逐字相同**（`COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=`）⇒ 上面那句"前缀唯一 ⇒ 抽取无歧义"**只对单臂列成立**。
#     **本趟刻意不改行名**（改成 `COLUMN_FLOOR_<臂>_<列>_<键>` 会移动真树读数 = 动射程、动上屏宽度）
#     ⇒ 作为**欠账**交主控裁定（见 W31D 报告 §7）。
#   · 汇总行形态 `KEY=PASS|FAIL|NOINFO <字段…>`（`verify-all.sh` 绿分支
#     `grep -E '^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)' … | head -8`）⇒ **零改动上屏**；
#     本件逐档 ＋ 汇总**恰 6 行**（≤ 8）—— ⚠️ **`#31` W31D 实测：今天已是 7 行**：
#     重冻 `#31` 插了 5 行 `# ARM-LOG-SHA` ⇒ 第 ⑤ 档从 `NOTDECLARED`（只印缩进行）变成
#     `COLUMN_FLOOR_ARMLOG=PASS`（**也匹配那条 `^[A-Z]…=(PASS|FAIL|NOINFO)` 正则**）⇒ 预算从 6 涨到 7。
#     ⚠️ **再涨就顶到 `head -8`**：若主控按 W31B 的语义把两支 `judged_min:null` 臂的
#     `# COLUMN-FLOOR … judged_min=none` 行插进冻结构，则逐档行 3→5 ⇒ 上屏 **9 行**、
#     **总判行 `COLUMN_FLOOR=` 会被 `head -8` 截掉**。⇒ 行名/聚合口径需主控裁定（W31D 报告 §7 欠账 ①）。
#
# 【只读承诺】不构建、不跑 harness、不写仓内任何文件；只有 `--outdir` 下自己的读数。
#   ④ 那一档会**跑一次门禁**（`tline-gate.sh`，纯读者）并把输出留在自己的 `--outdir`。
#
# 用法：
#   bash column-floor-check.sh [--root <repo>] [--registry <表>] [--baseline <冻结基线>]
#                              [--corpus <真值语料>] [--logdir <臂日志目录>] [--quiet]
#   bash column-floor-check.sh --selftest
# 环境覆盖（与 `BSC_*`/`ALSC_*` 同族；**沙箱用，现场不许设**）：
#   CFC_REG / CFC_BASE / CFC_CORPUS / CFC_LOGDIR / CFC_OUTDIR / CFC_ROOT
# === END-OF-HELP ===
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
HERE="$(cd -- "$(dirname -- "$SELF")" && pwd)"
ARG_ROOT=""; SELFTEST=0; QUIET=0
REG=""; BASE=""; CORPUS=""; LOGDIR=""; GATE_REG=""; OUTDIR_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --root)          [ $# -ge 2 ] || { echo "NOINFO --root 缺参数" >&2; exit 3; }; ARG_ROOT="$2"; shift 2 ;;
    --registry)      [ $# -ge 2 ] || { echo "NOINFO --registry 缺参数" >&2; exit 3; }; REG="$2"; shift 2 ;;
    --baseline)      [ $# -ge 2 ] || { echo "NOINFO --baseline 缺参数" >&2; exit 3; }; BASE="$2"; shift 2 ;;
    --corpus)        [ $# -ge 2 ] || { echo "NOINFO --corpus 缺参数" >&2; exit 3; }; CORPUS="$2"; shift 2 ;;
    --logdir)        [ $# -ge 2 ] || { echo "NOINFO --logdir 缺参数" >&2; exit 3; }; LOGDIR="$2"; shift 2 ;;
    --gate-registry) [ $# -ge 2 ] || { echo "NOINFO --gate-registry 缺参数" >&2; exit 3; }; GATE_REG="$2"; shift 2 ;;
    --outdir)        [ $# -ge 2 ] || { echo "NOINFO --outdir 缺参数" >&2; exit 3; }; OUTDIR_ARG="$2"; shift 2 ;;
    --selftest)      SELFTEST=1; shift ;;
    --quiet)         QUIET=1; shift ;;
    -h|--help)       sed -n '2,/^# === END-OF-HELP ===$/p' "$SELF" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数：$1（--help 看用法）" >&2; exit 3 ;;
  esac
done

# 仓根：脚本位置反推 → --root → $PWD（候选必须含 build/MilBridge）
ROOT=""; ROOT_SRC=""
for _c in "$(cd -- "$HERE/../../.." 2>/dev/null && pwd)" "$ARG_ROOT" "$(pwd)" "${CFC_ROOT:-}"; do
  [ -n "$_c" ] || continue
  if [ -d "$_c/build/MilBridge" ]; then ROOT="$(cd -- "$_c" && pwd)"; ROOT_SRC="cand"; break; fi
done
if [ -z "$ROOT" ]; then
  echo "NOINFO 定不出仓库根（脚本不在仓内：$HERE；且 --root/\$PWD 都不是仓库根）" >&2; exit 2
fi

[ -n "$REG" ]    || REG="${CFC_REG:-$ROOT/build/MilBridge/known-red.json}"
[ -n "$BASE" ]   || BASE="${CFC_BASE:-$ROOT/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md}"
[ -n "$CORPUS" ] || CORPUS="${CFC_CORPUS:-$ROOT/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json}"
[ -n "$LOGDIR" ] || LOGDIR="${CFC_LOGDIR:-$ROOT/build/MilBridge/arm-logs}"
GATE="$ROOT/build/MilBridge/tools/tline-gate.sh"

OUTDIR="${OUTDIR_ARG:-${CFC_OUTDIR:-$(mktemp -d "${TMPDIR:-/tmp}/column-floor.XXXXXX")}}"
mkdir -p "$OUTDIR" || { echo "NOINFO 造不出输出目录 $OUTDIR" >&2; exit 2; }
say() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }
sha16() { sha256sum "$1" 2>/dev/null | cut -c1-16; }

# 最新冻结块 = 第一条 `^# RE-FROZEN ` 起、到下一条含 `RE-FROZEN #` 的行为止
#   （历史块写作 `# ⏪ **（历史…）**# RE-FROZEN #23` ⇒ 行首锚**不会**误收它们）
extract_newest_block() {
  awk 'BEGIN{seen=0;p=0} /RE-FROZEN #/{ if(seen==1) exit; if(/^# RE-FROZEN /){seen=1;p=1} } p' "$1"
}

# 语料复算（**唯一实现**，正常跑与 `--selftest` 共用 —— `#28`/`#29` 各有一条血案是"复制函数体导致分叉"）
#   输出：`<总 dip 行> <latin 行> <非 latin 行> <一致性残差>`；残差 ≠0 ⇒ 语料形态变了 ⇒ 调用方判 NOINFO
corpus_bounds() { # $1=corpus
  python3 - "$1" <<'PYEOF' 2>/dev/null
import json,sys
try:
    d=json.load(open(sys.argv[1],encoding="utf-8"))
except Exception:
    raise SystemExit(0)
cs=d.get("cases")
if not isinstance(cs,list) or not cs: raise SystemExit(0)
tot=lat=oth=0
for c in cs:
    n=len(c.get("lines") or [])
    tot+=len(c.get("lineStartOffsetsDip") or [])
    if c.get("script")=="latin": lat+=n
    else:                        oth+=n
print("%d %d %d %d"%(tot,lat,oth,tot-(lat+oth)))
PYEOF
}

# ── 主判定：$1=REG $2=BASE $3=CORPUS $4=GATE_REG $5=LOGDIR $6=OUTDIR $7=ROOT
run_check() {
  local reg="$1" base="$2" corpus="$3" gate_reg="$4" logdir="$5" outdir="$6" root="$7"
  local js blk froz csv csha_decl corpus_verdict selfrep
  local n_fail=0 n_noinfo=0 n_pass=0
  local -a rows=() selfrows=()
  COLUMN_FLOOR=NOINFO; COLUMN_FLOOR_SELFREPORT=NOINFO; COLUMN_FLOOR_REASON=""
  mkdir -p "$outdir" || { echo "COLUMN_FLOOR=NOINFO reason=outdir-unwritable outdir=$outdir"; return 2; }

  [ -f "$reg" ]  || { echo "COLUMN_FLOOR=NOINFO reason=registry-missing reg=$reg"; return 2; }
  [ -f "$base" ] || { echo "COLUMN_FLOOR=NOINFO reason=baseline-missing base=$base"; return 2; }

  # ① 登记表声明（三个整数）
  js="$(python3 - "$reg" <<'PYEOF' 2>/dev/null
import json,sys
try:
    reg=json.load(open(sys.argv[1],encoding="utf-8"))
except Exception:
    raise SystemExit(0)
cg=((reg.get("generation") or {}).get("column_gate") or {})
# **三态**（`W31D` 修）：键**缺** ⇒ 空串（= 这一档没声明）｜**显式 `null`** ⇒ `none`
#   （**与门禁 `GATE_COLUMN_EXTRA=` 的 `judged_min=none` 同字**，也与冻结块 `judged_min=none` 同字）｜否则按字面。
#   ⚠️ 修前对 `null` 直接 `%s` ⇒ 打印出 **Python 的 `None`**，与"键缺"用的哨兵**同字** ⇒ 三态塌成两态。
def cell(d,k):
    if k not in d: return ""
    v=d[k]
    return "none" if v is None else "%s"%v
out=[]
for arm,d in sorted((cg.get("arms") or {}).items()):
    if not isinstance(d,dict): continue
    out.append("%s|%s|judged_min|%s"%(arm,d.get("column"),cell(d,"judged_min")))
    out.append("%s|%s|released_min|%s"%(arm,d.get("column"),cell(d,"released_min")))
for arm,d in sorted(((cg.get("additional") or {}).get("arms") or {}).items()):
    if not isinstance(d,dict): continue
    out.append("%s|%s|judged_min|%s"%(arm,d.get("column"),cell(d,"judged_min")))
print("\n".join(out))
PYEOF
)"
  if [ -z "$js" ]; then
    echo "COLUMN_FLOOR=NOINFO reason=registry-has-no-column_gate-declaration reg=$(sha16 "$reg")"
    return 2
  fi

  # ② 冻结块声明
  blk="$(extract_newest_block "$base")"
  if [ -z "$blk" ]; then
    echo "COLUMN_FLOOR=NOINFO reason=baseline-has-no-RE-FROZEN-block base=$(sha16 "$base")"; return 2
  fi
  froz="$(printf '%s\n' "$blk" | grep -E '^# COLUMN-FLOOR ' || true)"
  if [ -z "$froz" ]; then
    echo "COLUMN_FLOOR=NOINFO reason=frozen-block-has-no-COLUMN-FLOOR-line base=$(sha16 "$base")（缺声明 ⇒ 不许当通过）"
    return 2
  fi
  csha_decl="$(printf '%s\n' "$blk" | grep -m1 -E '^# COLUMN-CORPUS ' | sed -n 's/.*sha16=\([0-9a-f]\{16\}\).*/\1/p')"

  # ③ 语料复算（零 dotnet；纯 JSON 读）
  c_tot=""; c_lat=""; c_oth=""; c_chk=""
  if [ -f "$corpus" ]; then
    csv="$(corpus_bounds "$corpus")"
    if [ -n "$csv" ]; then
      c_tot="${csv%% *}"; rest="${csv#* }"; c_lat="${rest%% *}"; rest="${rest#* }"
      c_oth="${rest%% *}"; c_chk="${rest#* }"
    fi
  fi
  if [ -z "$c_tot" ]; then
    rows+=("COLUMN_FLOOR_CORPUS=NOINFO reason=corpus-unavailable-or-unparsable file=$corpus")
    n_noinfo=$((n_noinfo+1))
  elif [ "$c_chk" != "0" ]; then
    # 语料形态变了（`lineStartOffsetsDip` 行数 ≠ latin+非latin 行数）⇒ 复算口径不再成立 ⇒ NOINFO
    rows+=("COLUMN_FLOOR_CORPUS=NOINFO reason=corpus-shape-unrecognized tot=$c_tot latin=$c_lat other=$c_oth")
    n_noinfo=$((n_noinfo+1)); c_tot=""; c_lat=""; c_oth=""
  fi

  # 逐档判定 —— **迭代集 = 冻结块声明 ∪ 登记表声明**（只按一边迭代会让"另一边新加/删掉"静默通过）
  local flist rlist ulist
  flist="$(printf '%s\n' "$froz" | awk '{
      arm=""; col=""; jm=""; rm="";
      for(i=1;i<=NF;i++){
        if(index($i,"arm=")==1) arm=substr($i,5);
        else if(index($i,"col=")==1) col=substr($i,5);
        else if(index($i,"judged_min=")==1) jm=substr($i,12);
        else if(index($i,"released_min=")==1) rm=substr($i,14);
      }
      if(arm!="" && col!=""){ if(jm!="") print arm"|"col"|judged_min"; if(rm!="") print arm"|"col"|released_min" }
    }' | sort -u)"
  # `rlist` = 登记表侧的**下限声明** = **整数**行。`none`（显式无下限）与空（键缺）**都不构成一条下限声明**
  #   ⇒ 不进迭代集。⚠️ **明示边界**：所以**冻结块没声明**的 `null` 臂**不产行**
  #   （`--selftest` 的 `B4-NULL-ARM-UNFROZEN(边界)` 把这条钉成读数；消除办法 = 重冻同趟插声明行）。
  #   `"$4!=\"None\""` 保留：它是**修前** `null` 的形态，留着以防历史形态复活成一行。
  rlist="$(printf '%s\n' "$js" | awk -F'|' 'NF>=4 && $4!="None" && $4!="none" && $4!="" {print $1"|"$2"|"$3}' | sort -u)"
  ulist="$(printf '%s\n%s\n' "$flist" "$rlist" | grep -v '^$' | sort -u)"
  if [ -z "$ulist" ]; then
    echo "COLUMN_FLOOR=NOINFO reason=no-declaration-on-either-side froz=$(sha16 "$base") reg=$(sha16 "$reg")"
    return 2
  fi
  local arm col key decl fval rval cmin verdict
  while IFS='|' read -r arm col key _v; do
    [ -n "${arm:-}" ] || continue
    decl="$(printf '%s\n' "$js" | awk -F'|' -v a="$arm" -v c="$col" -v k="$key" '$1==a && $2==c && $3==k {print $4; exit}')"
    #   `decl`／`fval` 各是三态：**空串** = 这一档**没声明**（故障）｜**`none`** = **显式无下限**｜**整数** = 下限
    #   （修前"键缺"用哨兵 `None`，它与 `null` 被打出的 `None` **同字** ⇒ 三态塌成两态，本趟分家；
    #    行里现在按 `${decl:-<缺>}` 印 `<缺>`。）
    fval="$(printf '%s\n' "$froz" | awk -v a="$arm" -v c="$col" -v k="$key" '
      { hit=0; for(i=1;i<=NF;i++){ if($i=="arm="a) hit++; if($i=="col="c) hit++ }
        if(hit!=2) next
        for(i=1;i<=NF;i++){ if(index($i,k"=")==1){ v=substr($i,length(k)+2); print v; exit } } }')"
    cmin=""
    case "$col:$key" in
      START:judged_min)      cmin="$c_tot" ;;
      START:released_min)    cmin="$c_oth" ;;
      OVERFLOWED:judged_min) cmin="$c_lat" ;;
    esac
    if [ "$decl" = "none" ] && [ "$fval" = "none" ]; then
      verdict="PASS"                       # ③ 两侧**都**显式无下限 ⇒ 相符（**唯一**把 `none` 判 PASS 的情形）
    elif [ -z "$decl" ]; then
      verdict="NOINFO"                     # **登记表键缺**（故障态；优先级高于"口径不一"，见文件头三态段）
    elif [ -z "$fval" ]; then
      verdict="NOINFO"                     # **冻结块缺声明**（登记表有）
    elif [ "$decl" = "none" ]; then
      verdict="FAIL"                       # ④ **登记表说无下限、冻结块钉了整数** ⇒ 下限**静默消失**（与①同族）
    elif [ "$fval" = "none" ]; then
      verdict="NOINFO"                     # ⑤ 冻结块说无下限、登记表给了整数 ⇒ 口径不一 ⇒ 逼重冻（不制造假绿）
    elif ! grep -qE '^-?[0-9]+$' <<<"$decl"; then
      verdict="NOINFO"
    elif [ -z "$cmin" ]; then
      verdict="NOINFO"
    elif [ "$decl" -lt "$fval" ]; then
      verdict="FAIL"                       # ① 声明被下调（对不上冻结块）
    elif [ "$decl" -lt "$cmin" ]; then
      verdict="FAIL"                       # ② 声明低于语料复算出的下界
    elif [ "$decl" -gt "$fval" ]; then
      verdict="NOINFO"                     # 合法上调、冻结块未重钉 ⇒ 逼重冻
    else
      verdict="PASS"
    fi
    # ④（同一趟循环里顺手核对门禁自报，见下面第二趟）
    case "$verdict" in
      PASS)   n_pass=$((n_pass+1)) ;;
      FAIL)   n_fail=$((n_fail+1)) ;;
      NOINFO) n_noinfo=$((n_noinfo+1)) ;;
    esac
    rows+=("$(printf 'COLUMN_FLOOR_%s_%s=%s arm=%s col=%s key=%s decl=%s frozen=%s corpus_min=%s' \
              "$col" "$(printf '%s' "$key" | tr 'a-z' 'A-Z')" "$verdict" "$arm" "$col" "$key" \
              "${decl:-<缺>}" "${fval:-<缺>}" "${cmin:-<缺>}")")
  done <<< "$ulist"

  # ③ 语料整份 sha
  corpus_verdict="PASS"
  if [ -z "$csha_decl" ] || [ ! -f "$corpus" ]; then
    corpus_verdict="NOINFO"
  elif [ "$(sha16 "$corpus")" != "$csha_decl" ]; then
    corpus_verdict="FAIL"
  fi
  case "$corpus_verdict" in
    FAIL)   n_fail=$((n_fail+1)) ;;
    NOINFO) n_noinfo=$((n_noinfo+1)) ;;
  esac
  rows+=("$(printf 'COLUMN_FLOOR_CORPUS=%s file=%s live=%s decl=%s' \
            "$corpus_verdict" "$corpus" "$(sha16 "$corpus")" "${csha_decl:-<缺>}")")

  # ⑤ `D-G9` 残差：`generation.arm_logs[<臂>]`（**也是自指**）⇔ 冻结块的 `# ARM-LOG-SHA` 行
  #   ⚠️ 缺行 ⇒ `NOTDECLARED`、**不并入 rc**（理由见文件头 ⑤）
  local al_decl al_verdict al_ok al_bad n_al
  al_decl="$(printf '%s\n' "$blk" | grep -E '^# ARM-LOG-SHA ' || true)"
  n_al="$(printf '%s' "$al_decl" | grep -c . || true)"
  al_ok=0; al_bad=""
  if [ "${n_al:-0}" -eq 0 ]; then
    al_verdict="NOTDECLARED"
    rows+=("$(printf '  [COLUMN_FLOOR_ARMLOG] NOTDECLARED reason=frozen-block-has-no-ARM-LOG-SHA-line ⇒ `generation.arm_logs` 仍**自指**（`D-G9` 残差，本件不判；要激活 ⇒ 同趟多插 `# ARM-LOG-SHA arm=<名> sha16=<16hex>` 行）')")
  else
    al_verdict="PASS"
    while IFS='|' read -r a_arm a_sha; do
      [ -n "${a_arm:-}" ] || continue
      a_live="$(python3 - "$reg" "$a_arm" <<'PYEOF' 2>/dev/null
import json,sys
try: d=json.load(open(sys.argv[1],encoding="utf-8"))
except Exception: raise SystemExit(0)
al=((d.get("generation") or {}).get("arm_logs") or {})
v=al.get(sys.argv[2])
if v is None and isinstance(al.get("sha256"),dict): v=al["sha256"].get(sys.argv[2])
print(v or "")
PYEOF
)"
      if [ -z "$a_live" ]; then
        al_verdict="NOINFO"
        rows+=("$(printf '  [COLUMN_FLOOR_ARMLOG] arm=%s NOINFO reason=registry-has-no-arm_logs-entry decl=%s' "$a_arm" "$a_sha")")
      elif [ "${a_live:0:16}" = "$a_sha" ]; then
        al_ok=$((al_ok+1))
        rows+=("$(printf '  [COLUMN_FLOOR_ARMLOG] arm=%s OK decl=%s reg=%s' "$a_arm" "$a_sha" "${a_live:0:16}")")
      else
        al_verdict="FAIL"; al_bad="$al_bad $a_arm"
        rows+=("$(printf '  [COLUMN_FLOOR_ARMLOG] arm=%s **MISMATCH** 冻结块声明=%s 登记表=%s（`arm_logs` 被同趟改过 ⇒ 自指吞掉了 `ARM-LOG-SHA` 那条牙）' "$a_arm" "$a_sha" "${a_live:0:16}")")
      fi
    done < <(printf '%s\n' "$al_decl" | awk '{a="";s="";for(i=1;i<=NF;i++){if(index($i,"arm=")==1)a=substr($i,5);else if(index($i,"sha16=")==1)s=substr($i,7)}if(a!=""&&s!="")print a"|"s}')
    case "$al_verdict" in
      FAIL) n_fail=$((n_fail+1)) ;;
      NOINFO) n_noinfo=$((n_noinfo+1)) ;;
    esac
    rows+=("$(printf 'COLUMN_FLOOR_ARMLOG=%s n_decl=%s n_ok=%s bad=%s' "$al_verdict" "$n_al" "$al_ok" "${al_bad:-无}")")
  fi

  # ④ 门禁自报值 ⇔ 冻结块（只有 FAIL 并入总判决；见文件头）
  if [ -f "$root/build/MilBridge/tools/tline-gate.sh" ]; then
    local gout="$outdir/gate.stdout" gline gval sflag="PASS"
    local -a gargs=(--root "$root" --logdir "$logdir" --quiet --outdir "$outdir/gate-out")
    [ -n "$gate_reg" ] && gargs+=(--registry "$gate_reg")
    bash "$root/build/MilBridge/tools/tline-gate.sh" "${gargs[@]}" > "$gout" 2>&1
    while IFS='|' read -r arm col key _v; do
      [ -n "${arm:-}" ] || continue
      [ -n "$(printf '%s\n' "$flist" | grep -F -x -m1 "$arm|$col|$key")" ] || continue   # 只核对冻结块声明过的档
      gline="$(grep -a -E '^(GATE_COLUMN|GATE_COLUMN_EXTRA)=(PASS|FAIL|NOINFO)( |$)' "$gout" 2>/dev/null \
               | grep -a -m1 "col=$col " || true)"
      if [ -z "$gline" ]; then sflag="NOINFO"; continue; fi
      # ⚠️ **按臂切段**（`#31` W31D 修）：`GATE_COLUMN_EXTRA=` **一行里可以塞多支臂**（现场 3 段、`;` 分隔：
      #   `…arm=tab-oracle-anchor col=OVERFLOWED … judged_min=421; arm=tab-oracle-rtl … judged_min=none; …`）
      #   ⇒ 旧写法（只按 `col=` 取行 ＋ `sed '.*[ ]key='` 贪婪取**最后**一个匹配）在**多臂同列**时会拿**别的臂**
      #   的值来比（`#31` 之前每列恰一臂 ⇒ "恰好没坏"，不是"被看着"）⇒ 先切段、只在本臂段内取值。
      gseg="$(printf '%s' "$gline" | awk -v pat="arm=$arm col=$col " \
        '{n=split($0,s,";"); for(i=1;i<=n;i++){ t=s[i]; sub(/^[ \t]+/,"",t); if(index(t,pat)>0){ print t; exit } } }')"
      if [ -z "$gseg" ]; then
        sflag="NOINFO"
        selfrows+=("$(printf '  [COLUMN_FLOOR_SELFREPORT_ARM] NOINFO reason=gate-line-has-no-arm-segment arm=%s col=%s key=%s（本臂这一段没印 ⇒ 自报值无从核对；**不并入 rc**，与上面那条同族）' "$arm" "$col" "$key")")
        continue
      fi
      # 取值：**整数或 `none` 都算合法形态**（`none` = 该臂显式无下限，与冻结块 `judged_min=none` 同字）
      gval="$(printf '%s' "$gseg" | awk -v k="$key=" '{for(i=1;i<=NF;i++) if(index($i,k)==1){ print substr($i,length(k)+1); exit }}')"
      fval="$(printf '%s\n' "$froz" | awk -v a="$arm" -v c="$col" -v k="$key" '
        { hit=0; for(i=1;i<=NF;i++){ if($i=="arm="a) hit++; if($i=="col="c) hit++ }
          if(hit!=2) next
          for(i=1;i<=NF;i++){ if(index($i,k"=")==1){ v=substr($i,length(k)+2); print v; exit } } }')"
      if [ -z "$gval" ]; then
        sflag="NOINFO"
      elif [ -n "$fval" ] && [ "$gval" != "$fval" ]; then
        sflag="FAIL"
      fi
    done <<< "$ulist"
    COLUMN_FLOOR_SELFREPORT="$sflag"
    if [ "$sflag" = FAIL ]; then n_fail=$((n_fail+1)); fi
    selfrows+=("$(printf 'COLUMN_FLOOR_SELFREPORT=%s gate=%s outdir=%s%s' "$sflag" \
        "$(sha16 "$root/build/MilBridge/tools/tline-gate.sh")" "$outdir" \
        "$([ "$sflag" = NOINFO ] && echo ' （门禁这一趟没有该列的读数 ⇒ 本档无从核对；**不并入 rc**，理由见文件头）' || echo '')")")
  else
    COLUMN_FLOOR_SELFREPORT="NOINFO"
    selfrows+=("COLUMN_FLOOR_SELFREPORT=NOINFO reason=gate-missing gate=$root/build/MilBridge/tools/tline-gate.sh")
  fi

  if [ "$n_fail" -gt 0 ]; then
    COLUMN_FLOOR=FAIL;  COLUMN_FLOOR_REASON="floor-lowered-or-below-corpus-or-gate-selfreport-mismatch"
  elif [ "$n_noinfo" -gt 0 ]; then
    COLUMN_FLOOR=NOINFO; COLUMN_FLOOR_REASON="declaration-gap-or-raised-awaiting-refreeze"
  else
    COLUMN_FLOOR=PASS;  COLUMN_FLOOR_REASON="decl==frozen-and-decl>=corpus"
  fi

  say "==================== 列级下限铁证（D-G27）===================="
  say "仓库根        = $root"
  say "登记表        = $reg（$(sha16 "$reg")）"
  say "冻结基线      = $base（$(sha16 "$base")）"
  say "真值语料      = $corpus（$(sha16 "$corpus")）"
  say "门禁          = $root/build/MilBridge/tools/tline-gate.sh（$(sha16 "$root/build/MilBridge/tools/tline-gate.sh")）"
  say "读数目录      = $outdir"
  say ""
  local r
  for r in "${rows[@]}";     do printf '%s\n' "$r"; done
  for r in "${selfrows[@]}"; do printf '%s\n' "$r"; done
  printf 'COLUMN_FLOOR=%s reason=%s pass=%d fail=%d noinfo=%d selfreport=%s reg=%s base=%s corpus=%s\n' \
    "$COLUMN_FLOOR" "$COLUMN_FLOOR_REASON" "$n_pass" "$n_fail" "$n_noinfo" \
    "$COLUMN_FLOOR_SELFREPORT" "$(sha16 "$reg")" "$(sha16 "$base")" "$(sha16 "$corpus")"
  case "$COLUMN_FLOOR" in
    PASS)   return 0 ;;
    FAIL)   return 1 ;;
    NOINFO) return 2 ;;
  esac
  return 2
}

if [ "$SELFTEST" -eq 0 ]; then
  say "（本件是只读读者：不构建、不跑 harness、不写仓内任何文件）"
  run_check "$REG" "$BASE" "$CORPUS" "$GATE_REG" "$LOGDIR" "$OUTDIR" "$ROOT"; rc=$?
  printf '\n（本趟读数全在 %s）\n' "$OUTDIR"
  exit $rc
fi

# ── 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（`NOINFO`：不许当绿、不许冒充红）──
#   为什么需要（本件**不**重入自己，但同族风险仍在）：bash 对脚本文件是**边读边执行**的，而 `--selftest` 段
#   会派生**真件的副本**、还会按"现件"算期望 ⇒ 本件在窗口内一变，"夹具/期望/判定"三者就可能跨版本。
#   口径：**开头记 sha16、结尾再算一次**；不等 ⇒ `ST_ATTEST=NOINFO` 并点名（含 sha0/sha1 与内层 rc），
#   统一 **rc=2**（`NOINFO` 码，不与 `FAIL` 混）。只加在 `--selftest` 路径；**生产路径一字未动**；
#   不删例、不放宽任何期望（成对读数见 `$HOME/w33b-report.md`）。
if [ -z "${ST_ATTEST_INNER:-}" ]; then
  ST_SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  ST0="$(sha256sum "$ST_SELF" | cut -c1-16)"
  printf 'ST_ATTEST=OPEN self=%s sha16=%s\n' "$ST_SELF" "$ST0"
  if [ "${1:-}" = '--selftest' ]; then ST_IN=("$@"); else ST_IN=(--selftest "$@"); fi
  ST_OUT="$(ST_ATTEST_INNER=1 bash "$ST_SELF" "${ST_IN[@]}" 2>&1)"; ST_RC=$?
  printf '%s\n' "$ST_OUT"
  ST1="$(sha256sum "$ST_SELF" | cut -c1-16)"
  if [ "$ST1" != "$ST0" ]; then
    printf 'ST_ATTEST=NOINFO reason=self-rewritten-during-selftest（本件在自测期间被改写 ⇒ 上面的读数不可归因）self=%s sha0=%s sha1=%s inner_rc=%s\n' \
           "$ST_SELF" "$ST0" "$ST1" "$ST_RC"
    exit 2
  fi
  printf 'ST_ATTEST=PASS self=%s sha16=%s（自测期间本件未变 ⇒ 读数可归因）\n' "$ST_SELF" "$ST0"
  exit "$ST_RC"
fi

# ─────────────────────────────────────────────────────────────────────────────
# --selftest：沙箱 ＋ **现场值全部现算**（纪律 49／`D-G29`：**一个写死值都不许有**）
#   ⚠️ 正极性一档按纪律 63／`D-G29` 应当**对现件跑**；本件落地时那份 `# COLUMN-FLOOR` 声明行
#      尚不存在 ⇒ 正极性档用的是「**现场基线底座 ＋ 只插入声明行**」的**忠实复制品**。
#      **`#31` W31D 更新**：声明行**已经落树**（主控 09:58:23 重冻时插进 `# COLUMN-CORPUS`、5 行
#      `# ARM-LOG-SHA` 与既有 2 行 `# COLUMN-FLOOR`；现场那一趟实测 `COLUMN_FLOOR=PASS rc=0`）——
#      但**仍未插** `W31B` 新增那两支 `judged_min:null` 臂的 `judged_min=none` 行。
#      ⇒ 本件**仍然**用忠实复制品跑正极性档，理由从"声明行还不存在"改成**两条**：
#        ① **用例前提必须自持**（底座 = **裸基线**：剥掉三类会随重冻移动的声明行，见下面 `base-bare.md`）；
#        ② 真树那一趟**本就**逐字读现场冻结件本体 ⇒ 现场一致性由**真树读数**覆盖，不必再往 `--selftest`
#           里塞一个"会随冻结构变红"的档（若主控要那一档，它是一行 `run_and_chk`，值必须写死成当时的读数）。
#      ⇒ 该档的**声明值**是从**现登记表**现算的，插入内容与真实落地时主控要插的行**同源**。
# ─────────────────────────────────────────────────────────────────────────────
T="$(mktemp -d "${TMPDIR:-/tmp}/cfc-selftest.XXXXXX")" || exit 1
trap 'rm -rf "$T"' EXIT
# 纪律 63：沙箱**自带 TMPDIR**（并发车道不共用 /tmp 名空间）
export TMPDIR="$T/tmp"; mkdir -p "$TMPDIR"
np=0; nf=0
chk() { # $1=例名 $2=期望三态 $3=期望 rc
  local got rc ok=no
  got="$(sed -n 's/^COLUMN_FLOOR=\([A-Z]*\).*/\1/p' "$T/last.out" | head -1)"
  [ -s "$T/last.rc" ] && rc="$(cat "$T/last.rc")" || rc="?"
  if [ "$got" = "$2" ] && [ "$rc" = "$3" ]; then ok=yes; fi
  [ "$ok" = yes ] && np=$((np+1)) || nf=$((nf+1))
  printf 'SELFTEST case=%-26s expect=%-7s got=%-7s rc=%s => %s\n' "$1" "$2" "$got" "$rc" "$ok"
}
run_and_chk() { # $1=例名 $2=期望三态 $3=期望 rc $4=REG $5=BASE $6=CORPUS $7=GATE_REG(可空)
  run_check "$4" "$5" "$6" "${7:-}" "$LOGDIR" "$T/out" "$ROOT" > "$T/last.out" 2>&1
  echo "$?" > "$T/last.rc"
  chk "$1" "$2" "$3"
}

# 真复制（cp -p；**绝不用 ln/硬链接** —— 纪律 60）
cp -p "$REG"    "$T/reg.json"
cp -p "$CORPUS" "$T/corpus.json"

# **裸基线**（`#31` W31D 加）：现场冻结件里的**三类外挂声明行**（`# COLUMN-FLOOR` / `# COLUMN-CORPUS` /
#   `# ARM-LOG-SHA`）是**会随重冻移动**的（实测：`#31` 重冻把 `$BASE` 从 `e7d4977c773dd639` 改成
#   `4df3b53d479a537c`，同趟插进了 `# COLUMN-CORPUS` ＋ 5 行 `# ARM-LOG-SHA`）⇒ 若各档直接把 `$BASE`
#   当底座，**用例前提会随冻结构悄悄失效**（实测：旧件在重冻后 `N1-NO-DECLARATION` 前提死 ⇒ 期望 `NOINFO`
#   变 `PASS`、`G3b-ARMLOG-NOTDECLARED-INK` 前提死 ⇒ 不再印 `NOTDECLARED`；纪律 68 同族）。
#   ⇒ **沙箱底座 = 现场基线剥掉这三类行**，每个用例再**按本档前提**注入（注入内容一律现算）。
#   ⚠️ 真树那一趟（不带 `--selftest`）读的仍是**现场冻结件本体**，本行**不动它**。
python3 - "$BASE" "$T/base-bare.md" <<'PYEOF'
import io,re,sys
keep=[l for l in io.open(sys.argv[1],encoding="utf-8").read().split("\n")
      if not re.match(r'^# (COLUMN-FLOOR|COLUMN-CORPUS|ARM-LOG-SHA) ',l)]
io.open(sys.argv[2],"w",encoding="utf-8").write("\n".join(keep))
PYEOF

# 现算现场值（**全部从现件读**）
read -r J_START R_START J_OVF N_NULL <<EOF
$(python3 - "$REG" <<'PYEOF'
import json,sys
cg=((json.load(open(sys.argv[1],encoding="utf-8")).get("generation") or {}).get("column_gate") or {})
a=(cg.get("arms") or {}).get("tab-oracle-anchor") or {}
add=(cg.get("additional") or {}).get("arms") or {}
b=add.get("tab-oracle-anchor") or {}
n_null=sum(1 for v in add.values() if isinstance(v,dict) and "judged_min" in v and v["judged_min"] is None)
print(a.get("judged_min"),a.get("released_min"),b.get("judged_min"),n_null)
PYEOF
)
EOF
read -r C_TOT C_LAT C_OTH C_CHK <<EOF
$(corpus_bounds "$CORPUS")
EOF
printf 'SELFTEST live: J_START=%s R_START=%s J_OVF=%s N_NULL=%s | C_TOT=%s C_LAT=%s C_OTH=%s chk=%s\n' \
  "$J_START" "$R_START" "$J_OVF" "$N_NULL" "$C_TOT" "$C_LAT" "$C_OTH" "$C_CHK"

# **反极性档的扰动值也从现算值导出**（不是字面常量）
LOW_J_START="$J_OVF"                       # 615 → 421 那一档的"形状"（用现件 OVERFLOWED 值当新下限）
[ "$LOW_J_START" -lt "$J_START" ] || LOW_J_START=$((J_START-1))
LOW_J_OVF=$((J_OVF-1))                     # 421 → 420
LOW_R_START=0                              # 194 → 0
# fixture 自检：三档必须**确实是下调**，否则这一档没有信息量 ⇒ 大声红（不静默）
for _n in "START.judged_min:$LOW_J_START:$J_START" "OVERFLOWED.judged_min:$LOW_J_OVF:$J_OVF" "START.released_min:$LOW_R_START:$R_START"; do
  _k="${_n%%:*}"; _r="${_n#*:}"; _lo="${_r%%:*}"; _hi="${_r#*:}"
  if [ "$_lo" -ge "$_hi" ]; then
    nf=$((nf+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => no（fixture 退化：%s 的 %s 不低于现场 %s）\n' \
      "F0-FIXTURE-DEGENERATE" "lowering" "not-lower" "$_k" "$_lo" "$_hi"
  fi
done

# 忠实复制品：现场基线 ＋ 在**最新块**内插入声明行（值从登记表现算、不许写死）
#   $5=corpus_sha16 覆盖（空=现算）；$6=armlog 模式：`none`(默认，不插 ⑤ 的行)
#   |`match`（按现登记表 `arm_logs` 插**相符**的 `# ARM-LOG-SHA` 行）|`mismatch`（插**不符**的）
mkbase() { # $1=reg $2=corpus $3=base $4=out [ $5=corpus_sha16 覆盖 ] [ $6=armlog 模式 ]
          #   [ $7=null 臂模式：emit(默认)|skip-null|**oldgen-none**（故意印修前那种畸形 `judged_min=None`，只给回归牙用）]
  python3 - "$1" "$2" "$3" "$4" "${5:-}" "${6:-none}" "${7:-emit}" <<'PYEOF'
import json,sys,re,hashlib
reg,corpus,base,out=sys.argv[1:5]
ovr=sys.argv[5] if len(sys.argv)>5 else ""
amode=sys.argv[6] if len(sys.argv)>6 else "none"
nmode=sys.argv[7] if len(sys.argv)>7 else "emit"
csha=ovr or hashlib.sha256(open(corpus,'rb').read()).hexdigest()[:16]
D=json.load(open(reg,encoding="utf-8"))
g=(D.get("generation") or {}).get("column_gate") or {}
# **三态**（`W31D` 修）：键**缺** ⇒ 不印该字段｜**显式 `null`** ⇒ 印 `none`
#   （**与门禁 `GATE_COLUMN_EXTRA=` 的 `judged_min=none` 同字**）｜整数 ⇒ 印数。
#   ⚠️ 修前对 `null` 直接 `%s` ⇒ 印出 **`judged_min=None`**（Python 的 `None`）⇒ 生成行**不合形状**、
#   且与"登记表侧键缺"的哨兵同字 ⇒ 三态塌成两态、`--selftest` 各例的沙箱前提集体失真。
nulltok = "None" if nmode=="oldgen-none" else "none"   # `oldgen-none` = 复现修前的畸形记号（回归牙专用）
def tok(d,k):
    if k not in d: return None
    v=d[k]
    return nulltok if v is None else "%s"%v
lines=[]
for arm,d in sorted((g.get("arms") or {}).items()):
    parts=["# COLUMN-FLOOR arm=%s col=%s"%(arm,d.get("column"))]
    for k in ("judged_min","released_min"):
        t=tok(d,k)
        if t is not None: parts.append("%s=%s"%(k,t))
    lines.append(" ".join(parts))
for arm,d in sorted(((g.get("additional") or {}).get("arms") or {}).items()):
    if nmode=="skip-null" and tok(d,"judged_min")=="none": continue
    parts=["# COLUMN-FLOOR arm=%s col=%s"%(arm,d.get("column"))]
    t=tok(d,"judged_min")
    if t is not None: parts.append("judged_min=%s"%t)
    lines.append(" ".join(parts))
lines.append("# COLUMN-CORPUS file=tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json sha16=%s"%csha)
if amode in ("match","mismatch"):
    al=(D.get("generation") or {}).get("arm_logs") or {}
    if isinstance(al.get("sha256"),dict): al=al["sha256"]
    # 取**登记表里真有的**臂；`mismatch` 时把前 16 位改成它的补（保证与现场必然不等）
    for arm,v in sorted(al.items()):
        if not isinstance(v,str) or len(v)<16: continue
        s16=v[:16]
        if amode=="mismatch":
            s16=("%016x"%((int(s16,16)^0xFFFFFFFFFFFFFFFF)))
        lines.append("# ARM-LOG-SHA arm=%s sha16=%s"%(arm,s16))
src=open(base,encoding="utf-8").read().split("\n")
seen=False; o=[]
for ln in src:
    o.append(ln)
    if not seen and re.match(r'^# RE-FROZEN ',ln): o.extend(lines); seen=True
open(out,"w",encoding="utf-8").write("\n".join(o))
PYEOF
}
# JSON 点路径赋值（**不用 exec**；值由调用方现算传入）
pert() { # $1=in $2=out $3..= "a|b|c=值"（值为 __DEL__ 时删除该键）
  python3 - "$@" <<'PYEOF'
import json,sys
inp,out=sys.argv[1],sys.argv[2]
d=json.load(open(inp,encoding="utf-8"))
for a in sys.argv[3:]:
    path,_,val=a.rpartition("=")
    keys=path.split("|"); o=d
    for k in keys[:-1]: o=o[int(k)] if k.isdigit() else o[k]
    last=keys[-1]
    if val=="__DEL__": o.pop(last,None)        # 键**删掉**（= 键缺，故障态）
    elif val=="__NULL__": o[last]=None         # **显式 JSON `null`**（= 裁定无下限；与"键缺"必须分家）
    else: o[last]=int(val)
json.dump(d,open(out,"w",encoding="utf-8"),ensure_ascii=False,indent=2)
PYEOF
}

ARM=tab-oracle-anchor
P_ARMS="generation|column_gate|arms|$ARM"
P_ADD="generation|column_gate|additional|arms|$ARM"
ZERO=tab-oracle-zero
P_ADD_Z="generation|column_gate|additional|arms|$ZERO"

# ── 正极性（现场基线 ＋ 声明行；声明值 = 现登记表值）──────────────────────────
mkbase "$T/reg.json" "$T/corpus.json" "$T/base-bare.md" "$T/base-withdecl.md"
run_and_chk "P1-POSITIVE" PASS 0 "$T/reg.json" "$T/base-withdecl.md" "$T/corpus.json"
# **三态挡（形状本身）**：现登记表 `additional.arms` 有 **3 支臂** —— `tab-oracle-anchor`（整数）
#   ＋ `tab-oracle-zero`/`tab-oracle-rtl`（**显式 `null`**）。P1 的忠实复制品把三支**都**声明进冻结块
#   ⇒ 本档把"**显式 `null` 臂的存在**"钉成**逐字读数**（`decl=none frozen=none` ＋ `=PASS`）。
#   ⚠️ 本档**不看** `SELFTEST live:` 里的 `N_NULL`，只认**行文本** ⇒ 即使哪天登记表调整，本档也会如实红。
if grep -qE '^COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=PASS arm=tab-oracle-zero col=OVERFLOWED key=judged_min decl=none frozen=none' "$T/last.out" \
   && grep -qE '^COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=PASS arm=tab-oracle-rtl col=OVERFLOWED key=judged_min decl=none frozen=none' "$T/last.out"; then
  np=$((np+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => yes\n' "P1b-NULL-ARM-INK(none)" "PASS/none" "PASS/none"
else
  nf=$((nf+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => no\n' "P1b-NULL-ARM-INK(none)" "PASS/none" "$(grep -m1 'arm=tab-oracle-zero' "$T/last.out" | cut -c1-70)"
fi

# ── A 挡（① 声明被下调）：≥3 档必红 ────────────────────────────────────────
pert "$T/reg.json" "$T/reg-f1.json" "$P_ARMS|judged_min=$LOW_J_START"
run_and_chk "F1-A-START-JUDGED-DOWN" FAIL 1 "$T/reg-f1.json" "$T/base-withdecl.md" "$T/corpus.json"
pert "$T/reg.json" "$T/reg-f2.json" "$P_ADD|judged_min=$LOW_J_OVF"
run_and_chk "F2-A-OVER-JUDGED-DOWN" FAIL 1 "$T/reg-f2.json" "$T/base-withdecl.md" "$T/corpus.json"
pert "$T/reg.json" "$T/reg-f3.json" "$P_ARMS|released_min=$LOW_R_START"
run_and_chk "F3-A-START-RELEASED-DOWN" FAIL 1 "$T/reg-f3.json" "$T/base-withdecl.md" "$T/corpus.json"

# ── 三态挡（**反面**）：把一支**有判定面**的臂写成**显式 `null`** ⇒ 冻结块那条下限**静默消失** ⇒ 必红 ──
#   成对：同一份冻结块（`tab-oracle-anchor` 的 `judged_min=421` 由**未扰动**登记表现算）＋ 登记表把该臂改成 `null`
#   ⇒ `decl=none` vs `frozen=421` ⇒ **FAIL**。（与门禁 `GATE_REASON=column-gate-extra-floor-null-but-judged`
#   同族自证；本档**只动声明、不读臂日志**，所以它证的是"两处声明分家"，不是"该臂真有判定面"。）
pert "$T/reg.json" "$T/reg-f7.json" "$P_ADD|judged_min=__NULL__"
run_and_chk "F7-A-NULL-BUT-FROZEN-FLOOR" FAIL 1 "$T/reg-f7.json" "$T/base-withdecl.md" "$T/corpus.json"
# 归因牙：上面那一档的 FAIL 必须**确实来自三态分支**（行文本点名 `decl=none frozen=421`），
#   而不是碰巧来自 ④（门禁那一趟读的是被扰动的登记表 ⇒ 它也会不一致）⇒ 两处证据分开钉。
if grep -qE '^COLUMN_FLOOR_OVERFLOWED_JUDGED_MIN=FAIL arm=tab-oracle-anchor col=OVERFLOWED key=judged_min decl=none frozen=421' "$T/last.out"; then
  np=$((np+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => yes\n' "F7b-NULL-FLOOR-ROW" "decl=none" "decl=none"
else
  nf=$((nf+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => no\n' "F7b-NULL-FLOOR-ROW" "decl=none" "$(grep -m1 'arm=tab-oracle-anchor col=OVERFLOWED' "$T/last.out" | cut -c1-70)"
fi

# ── 三态挡（**回归牙**）：冻结行里出现**畸形记号** `judged_min=None`（修前生成器的形状）⇒ **必红** ──
#   前提（逐字）：登记表那两臂是**显式 `null`**（`decl=none`），冻结块却写 `judged_min=None`
#   ⇒ 走「形状错」那一支 ⇒ **FAIL**（点名行会逐字带上 `frozen=None`）⇒ 这个形状**永远不会被当绿**。
#   成对：同一批输入、只把记号从 `none` 换成 `None`（`P1` 绿 vs 本档红）⇒ 判词唯一归因于记号本身。
mkbase "$T/reg.json" "$T/corpus.json" "$T/base-bare.md" "$T/base-oldgen.md" "" none oldgen-none
run_and_chk "F8-A-MALFORMED-NONE-TOKEN" FAIL 1 "$T/reg.json" "$T/base-oldgen.md" "$T/corpus.json"

# ── C 挡（② 两处同改一致下调 ⇒ 只有语料复算抓得到）─────────────────────────
pert "$T/reg.json" "$T/reg-f4.json" \
     "$P_ARMS|judged_min=$LOW_J_START" "$P_ARMS|released_min=$LOW_R_START" "$P_ADD|judged_min=$LOW_J_OVF"
mkbase "$T/reg-f4.json" "$T/corpus.json" "$T/base-bare.md" "$T/base-f4.md"
run_and_chk "F4-C-TWO-WAY-DOWN" FAIL 1 "$T/reg-f4.json" "$T/base-f4.md" "$T/corpus.json"

# ── C 挡（③ 语料被换、`# COLUMN-CORPUS` 未重钉 ⇒ 整份 sha 不符）─────────────
python3 - "$T/corpus.json" "$T/corpus-f5.json" <<'PYEOF'
import json,sys
d=json.load(open(sys.argv[1],encoding="utf-8"))
d["cases"]=[c for c in d["cases"] if c.get("script")!="arabic"]
json.dump(d,open(sys.argv[2],"w"),ensure_ascii=False)
PYEOF
read -r C2_TOT C2_LAT C2_OTH C2_CHK <<EOF
$(corpus_bounds "$T/corpus-f5.json")
EOF
run_and_chk "F5-C-CORPUS-SWAPPED" FAIL 1 "$T/reg.json" "$T/base-withdecl.md" "$T/corpus-f5.json"

# ── B 挡（④ 门禁被指向另一份下限的登记表）──────────────────────────────────
pert "$T/reg.json" "$T/reg-f6.json" "$P_ADD|judged_min=$LOW_J_OVF"
run_and_chk "F6-B-GATE-OTHER-REGISTRY" FAIL 1 "$T/reg.json" "$T/base-withdecl.md" "$T/corpus.json" "$T/reg-f6.json"
if grep -q '^COLUMN_FLOOR_SELFREPORT=FAIL' "$T/last.out"; then
  np=$((np+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => yes\n' "F6b-SELFREPORT-LINE" "FAIL" "FAIL"
else
  nf=$((nf+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => no\n' "F6b-SELFREPORT-LINE" "FAIL" "$(grep -m1 '^COLUMN_FLOOR_SELFREPORT=' "$T/last.out" | cut -c1-60)"
fi

# ── NOINFO 档（≥4 档）───────────────────────────────────────────────────────
#   前提**自持**：底座 = 剥掉三类声明行的裸基线 ⇒ "冻结块缺 `# COLUMN-FLOOR` 行 ⇒ NOINFO"
#   不再依赖"现场冻结构恰好没插那类行"（`#31` 重冻已经插了 ⇒ 修前本档前提当场失效、变 PASS）。
run_and_chk "N1-NO-DECLARATION" NOINFO 2 "$T/reg.json" "$T/base-bare.md" "$T/corpus.json"
run_and_chk "N2-CORPUS-MISSING" NOINFO 2 "$T/reg.json" "$T/base-withdecl.md" "$T/nonexistent.json"
pert "$T/reg.json" "$T/reg-n3.json" "$P_ARMS=__DEL__" "$P_ADD=__DEL__"
run_and_chk "N3-ARM-UNDECLARED" NOINFO 2 "$T/reg-n3.json" "$T/base-withdecl.md" "$T/corpus.json"
pert "$T/reg.json" "$T/reg-n4.json" "$P_ARMS|judged_min=$((J_START+5))"
run_and_chk "N4-RAISED-LEGAL" NOINFO 2 "$T/reg-n4.json" "$T/base-withdecl.md" "$T/corpus.json"
# ── 三态挡（**第三态：键缺**）：把 `null` 臂的 `judged_min` 键**删掉** ⇒ 与"显式 `null`"**必须分家** ──
#   成对：`null` 臂（P1 ⇒ `decl=none frozen=none` PASS）vs 同一臂**键缺**（本档 ⇒ NOINFO）。
#   单变量隔离：门禁那一路喂回**未扰动**登记表（与冻结块相符）⇒ 判词**唯一**归因于三态分支（否则 ④ 会跟着红）。
pert "$T/reg.json" "$T/reg-n7.json" "$P_ADD_Z|judged_min=__DEL__"
run_and_chk "N7-NULL-ARM-KEY-MISSING" NOINFO 2 "$T/reg-n7.json" "$T/base-withdecl.md" "$T/corpus.json" "$T/reg.json"

# ── 三态挡（**第四格**）：冻结块写 `none`、登记表却给了**整数** ⇒ `NOINFO`（口径不一 ⇒ 逼「重钉＋重冻」）──
#   前提：`base-withdecl.md` 按**未扰动**登记表生成 ⇒ `tab-oracle-zero` 那行是 `judged_min=none`；
#   本档把登记表里**同一臂**改成整数 `1` ⇒ 两侧口径不一。**不允许**判绿（那会让"下限不知何时被钉上"
#   静默通过），也**不判红**（抬高下限不制造假绿，与 `decl > frozen` 同族 ⇒ 逼重冻）。
#   单变量隔离：门禁那一路喂回**未扰动**登记表 ⇒ 判词唯一归因于三态分支。
pert "$T/reg.json" "$T/reg-n8.json" "$P_ADD_Z|judged_min=1"
run_and_chk "N8-NONE-BUT-INT-ON-REG" NOINFO 2 "$T/reg-n8.json" "$T/base-withdecl.md" "$T/corpus.json" "$T/reg.json"

# ── B3 已知边界：**三处同改**（登记表 ＋ 冻结块 ＋ 语料 sha 声明）⇒ 期望 PASS ──
#   值 = **新语料**当场复算出的上界（`C2_*`），不是字面常量
pert "$T/reg.json" "$T/reg-b3.json" \
     "$P_ARMS|judged_min=${C2_TOT:-0}" "$P_ARMS|released_min=${C2_OTH:-0}" "$P_ADD|judged_min=${C2_LAT:-0}"
mkbase "$T/reg-b3.json" "$T/corpus-f5.json" "$T/base-bare.md" "$T/base-b3.md" "$(sha16 "$T/corpus-f5.json")"
run_and_chk "B3-THREE-WAY(边界)" PASS 0 "$T/reg-b3.json" "$T/base-b3.md" "$T/corpus-f5.json" "$T/reg-b3.json"

# ── B4 已知边界：**登记表有显式 `null` 臂、冻结块没声明它** ⇒ 本件**不产行**（静默）──────────
#   理由（逐字）：本件的**迭代集** = 「冻结块声明过的档」∪「登记表侧的**整数**声明」；`null`
#   **不构成一条下限声明** ⇒ 不进 `rlist` ⇒ 冻结块不声明它时那一臂**根本不进判据**。
#   这条边界与 B3 同族：**如实钉成读数**，不假装看不见。⚠️ 重冻那一趟把 `# COLUMN-FLOOR … judged_min=none`
#   几行**同趟插入**最新 `# RE-FROZEN` 块 ⇒ 本边界**当场消失**（那两臂进 `flist` ⇒ 被判、且受三态阶梯约束）。
mkbase "$T/reg.json" "$T/corpus.json" "$T/base-bare.md" "$T/base-nullunfroz.md" "" none skip-null
run_and_chk "B4-NULL-ARM-UNFROZEN(边界)" PASS 0 "$T/reg.json" "$T/base-nullunfroz.md" "$T/corpus.json"
if [ "$(grep -c 'arm=tab-oracle-zero' "$T/last.out")" -eq 0 ]; then
  np=$((np+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => yes\n' "B4b-NULL-ARM-SILENT" "0 rows" "0 rows"
else
  nf=$((nf+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => no\n' "B4b-NULL-ARM-SILENT" "0 rows" "$(grep -c 'arm=tab-oracle-zero' "$T/last.out") rows"
fi

# ── ⑤ `D-G9` 残差那半（`arm_logs` 的**外挂**锚）：声明相符 ⇒ PASS；声明不符 ⇒ FAIL ──────
#   两档只差"冻结块里 `# ARM-LOG-SHA` 行的值"，语料/下限一律不动 ⇒ 判词唯一归因于 ⑤
mkbase "$T/reg.json" "$T/corpus.json" "$T/base-bare.md" "$T/base-al-ok.md"  "" match
run_and_chk "G1-ARMLOG-DECLARED-OK" PASS 0 "$T/reg.json" "$T/base-al-ok.md" "$T/corpus.json"
if grep -q '^COLUMN_FLOOR_ARMLOG=PASS' "$T/last.out"; then
  np=$((np+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => yes\n' "G1b-ARMLOG-LINE" "PASS" "PASS"
else
  nf=$((nf+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => no\n' "G1b-ARMLOG-LINE" "PASS" "$(grep -m1 '^COLUMN_FLOOR_ARMLOG=' "$T/last.out" | cut -c1-60)"
fi
mkbase "$T/reg.json" "$T/corpus.json" "$T/base-bare.md" "$T/base-al-bad.md" "" mismatch
run_and_chk "G2-ARMLOG-DECLARED-BAD" FAIL 1 "$T/reg.json" "$T/base-al-bad.md" "$T/corpus.json"
# G3 ⑤ **缺行不判**：与 P1 同一份输入 ⇒ 仍 PASS（把"可选加强"与"必做射程"分开的机器证）
run_and_chk "G3-ARMLOG-ABSENT-NONBLOCKING" PASS 0 "$T/reg.json" "$T/base-withdecl.md" "$T/corpus.json"
if grep -q 'NOTDECLARED' "$T/last.out"; then
  np=$((np+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => yes\n' "G3b-ARMLOG-NOTDECLARED-INK" "NOTDECLARED" "NOTDECLARED"
else
  nf=$((nf+1)); printf 'SELFTEST case=%-26s expect=%-7s got=%-7s => no\n' "G3b-ARMLOG-NOTDECLARED-INK" "NOTDECLARED" "（缺行时未印残留告示）"
fi

printf 'SELFTEST=%s cases=%d pass=%d fail=%d\n' "$([ $nf -eq 0 ] && echo PASS || echo FAIL)" "$((np+nf))" "$np" "$nf"
[ $nf -eq 0 ] || exit 1
exit 0

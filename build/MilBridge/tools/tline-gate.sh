#!/usr/bin/env bash
# ============================================================================
# T1b3 · 文本 harness「在册红登记制」门禁            （判据口径版本 t1b3-tline-gate/7）
# ⏪ **W31B 把口径由 /6 升到 /7**（`D-G30` 同族三格，见 `$HOME/w31b-report.md`）：
#   (a) `COL2_ARM` 补 `tab-oracle-zero`/`tab-oracle-rtl` ⇒ 那两支臂的 `OVERFLOWED`
#       **逐例对账行三层互校**进了射程；它们的**下限**按 `D-G19` 裁定**不钉**，声明册写
#       **`judged_min: null`**（显式"无下限"），机读行打 `judged_min=none`；
#       **"键缺"仍 `NOINFO`**（既有极性不变）；新增自证「`null` 的臂 `判定行` 必须 `=0`」
#       ⇒ 否则 `NOINFO kind=floor-null-but-judged`（防"给有判定面的臂写 `null` ⇒ 下限静默消失"）。
#   (b) 新增**等式牙** `判定行 == 红 + 绿`（`START` 与 `OVERFLOWED` **各一条**）⇒
#       治「单独把 `判定行` 往上改」那一档（`judged_min` 只判 `<`、三层互校不含这个字段）。
#   (c) **刻意不抓**：三层**协同**谎报（门禁内部任何自洽校验按定义看不见自洽的谎）——
#       责任在下限声明 ＋ `column-floor-check.sh` 的语料复算那条**外挂读者**（见本文件 `:754-757`）。
#   ⚠️ 同趟已推 `known-red.json` 的 4 条 `caliber.judgment_version` `/6 → /7`（该字段**门禁不校验**
#   ⇒ 忘推不会红，属 `D-G25`；本趟照纪律 15/26 同趟推进）。**不重取臂**（只加读取点）。
# ⏪ W29A 把口径由 /4 升到 /5：新增**附加列（`OVERFLOWED`）的「逐例对账行」读数点与三态保护**
#   （见 `REC2_RE` 那一段 · `D-G30`）。**只加严**：既有的 `REC_RE`/`PCC_RE`（`START` 列）一个字节未改。
#   ⚠️ `known-red.json` 的 `entries[*].caliber.judgment_version` 仍是 `/4`（4 条）—— **须主控同趟推 `/5`**；
#   本门禁**不校验它**（`:8` 记着这一点）⇒ 忘推**不会红**（② 无牙），故在此大声记下。
# ⏪ W29E 草稿把口径由 /5 升到 /6：新增**探针身份闸（`D-G26`）**——三支 tab 臂的宿主
#   `CoverageProbe/Program.cs` 原先**不在任何指纹里**（不在 `GEN_KEYS`、不在 `fp_inputs()`、
#   日志不记它）⇒ 改测量代码零机器红。落点是 `probe` 段 + 新机读行 `GATE_PROBE=`。
#   ⚠️ 与之配套：探针须自报 `TAB_LINES_PROBE sha256=`（`ProbeIdentity.targets` 构建时嵌入），
#   且 `generation.probes` 须声明臂→探针源映射；**落地当趟必须重取三支 `tab-*` 臂**
#   （老日志没有那一行 ⇒ 本闸给 NOINFO，这正是"日志出自更早一版"要被看见的地方）。
# ⏪ `#26` W26H 草稿把口径由 /2 升到 /3：新增**列级闸（`D-G14`）的读数点与两条保护**
# ⏪ `#28` W28C 草稿（落地车道 W28D）把口径由 /3 升到 /4：新增**附加列（`OVERFLOWED`）的下限读数点与三态保护**
#   （见 `COL2_ARM` 那一段）。判据口径变了 ⇒ 版本必须跟着变（纪律 15/26），
#   且 `known-red.json` 里每条 `entries[*].caliber.judgment_version` 须**同趟**推进
#   —— ⚠️ **但本门禁并不校验它**（`:476` 的 `entry_gen_bad` 只比 `GEN_KEYS` 三项）
#   ⇒ 忘推进**不会红**（② 无牙）。细节见 W28D 报告。
#   （见 `COL_ARM` 那一段）。判据口径变了 ⇒ 版本必须跟着变（纪律 15/26），
#   且 `known-red.json` 里每条 `entries[*].caliber.judgment_version` 须**同趟**推进。
# ----------------------------------------------------------------------------
# 【要解决的缺口】verify-all.sh 只有 2 个构建 + 7 个测试工程 + 1 个 python 校验，
#   **完全不含** `run.sh tline`（1298 行逐例读数）、CoverageProbe 的三支 tab oracle、
#   TextLineProto。后果有实测：`TextLineProto/Program.cs` 里一段 `[IGR]` 代码落盘后
#   **从未被编译过**（CS1503），**没有任何自动环节因此变红**。
#   ⇒ 判据必须**能被一条命令判绿/判红**，且**在册红必须登记**。
#
# 【本门禁是**读者**，不是跑者】⛔ 它**不跑 harness、不构建、不写别人的产物**。
#   它只读日志（--log / --logdir）。"跑"是波/维护动作，归主控或 T3。
#   为什么删掉跑的能力（主控裁定 ④，事故 L28）：本门禁第一版在只给一个 --log 时会
#   **默认去跑**其余没日志的臂 ⇒ 误触发 `run.sh textline`，**写掉了 `build/MilBridge/gen/
#   textline-proto.png`**（他人写域），而"字节相同"**无法自证**（跑前无备份）。
#   教训：**新装置的默认值必须先回答"它会不会写别人的文件"；默认必须是"什么都不做"。**
#
# 【一条命令】
#   bash build/MilBridge/tools/tline-gate.sh --log <日志> [--log <日志> ...]
#   bash build/MilBridge/tools/tline-gate.sh --logdir <目录>      # 扫 *.log，按内容自动识别臂
#   其它：--registry <表>  --outdir <目录>  --quiet  -h
#   ⚠️ 没有 --log/--logdir ⇒ 本门禁**没有读数** ⇒ 打印 NOINFO 并以 2 退出（它不会自己去跑）。
#
# 【五臂】5 个臂**都要有**读数；缺一个 ⇒ 该臂 NOINFO ⇒ 整门 NOINFO（空集 ≠ 通过）。
#   tline             `run.sh tline` 的 stdout（HbTextLineParity：1298 行记账/Collapse/Extent）
#   tab-oracle-zero   `CoverageProbe --tab-lines-oracle tab-zero-oracle.json` 的 stdout
#   tab-oracle-anchor 同上，tab-anchor-oracle.json
#   tab-oracle-rtl    同上，tab-rtl-oracle.json
#   textlineproto     `run.sh textline` 的 stdout（TextLineProto 契约原型 + [IGR]）
#
# 【世代（generation）而不是"当前树"】登记表绑的是一个**世代**（三项仪器 sha + 标签）。
#   本门禁判读一条日志时，先问：**这条日志属于登记表绑的那个世代吗？**
#     · 日志**自报**了仪器 sha（tline 臂的头行/T0.6 会报被测 shim sha）⇒ 与 generation 逐条比；
#       不符 ⇒ 口径不一致 ⇒ 不许判 PASS ⇒ NOINFO。
#     · 日志**不自报**仪器 sha（tab 臂：CoverageProbe 不打印 shim sha）⇒ 只有在**树本身 ==
#       generation** 时才放行；树已前进 ⇒ NOINFO（无法证明这条日志属于登记世代）。
#   树比 generation 新**本身不是错误**（登记表刻意绑"最后一个有完整读数的世代"）⇒ 只作信息报出。
#
# 【三态判据（外加两条"不许判 PASS"的保护）】
#   ① 未登记的失败      ⇒ FAIL   + 非零（exit 1）
#   ② 登记过且仍失败    ⇒ 点名 `KNOWN_RED`，**不改退出码**
#   ③ 登记过却变绿      ⇒ 显式报告 `KNOWN_RED_GONE`（在册红消失）
#   ④ 缺数据 / 算不出   ⇒ NOINFO + 非零（exit 2）
#   ⑤ 口径不一致 / 无法证明世代 ⇒ 不许判 PASS ⇒ NOINFO
#
#   ⚠️ 本门禁对 ③ 与「读数漂移」取**保守**读法：登记表与现实不符时**绝不给 PASS**。
#      理由：③ 的目的就是"防止登记表悄悄吸收修复、或悄悄过期"；若允许 PASS 与
#      KNOWN_RED_GONE 并存，自动化看到的仍是绿 ⇒"悄悄"就已经发生了。
#      ⇒ 判 FAIL；逐条 marker + `GATE_REASON=registry-stale(gone|drift)` 写清原因是
#        **登记表过期**、**不是**"被测件坏了"。人工更新登记表后重跑即可。
#
# 【红/绿权威 = 判据自己的状态，不是退出码】
#   tline 臂      = harness 的 `❌ <Check id>` / `✅ <Check id>`（+ 结论 `通过 N / 失败 M`）
#   tab 臂        = `TAB_LINES CASE <id> … 结构=PASS|FAIL` + `TAB_LINES 合计 … 结构败=N`
#   textlineproto = TextLineProto 段的 `== 通过 N / 失败 M ==`
#   实测陷阱：$HOME/wfp-runs/or13-dT1-tab-zero-knownred.log 里 **结构败=1 而 `TAB_LINES
#   退出码=0`**（调用方给了探针自带的 known-red.txt，失败在探针层被吸收）⇒ **只看退出码
#   的门禁会假绿**。本门禁不用退出码定红绿。
#
# 【红条件】红 = **该 field 的读数红** 或 **它的归属判据(case_id 前缀)报 FAIL**（主控裁定 B）。
#   例：`T2-记账结构` 的读数在 #13-legA 已是 1298/1298（绿），但 T2 判据仍 ❌（红由
#   宽度超差 34 承载）⇒ 本条仍算在册红，并打 `READING_GREEN_BUT_JUDGE_RED` 标记。
#   理由：登记的对象是**判据(family)**而不是某一行读数 ⇒"子项修好了但 family 仍红"必须留在册，
#   不许报"在册红消失"（否则会静默吸收掉已修复的那部分）。
#   field 未登记过红条件 ⇒ NOINFO（**不许猜**）。
#   特例 field=`判据状态`：读数 = 该判据自己的 ❌/✅（用于登记"判据红但根因未定位"）。
#
# 【carrier = 这条红当前由谁承载】登记条目带 `carrier`，门禁把它印在点名行里 ——
#   读者必须一眼看出"它为什么还红"。
# 【unlocated = 未定位的在册红】条目 `unlocated: true` ⇒ 门禁打 **`KNOWN_RED_UNLOCATED`**
#   （与普通 KNOWN_RED 不同的 marker，逐趟点名）。**登记 ≠ 已理解、更 ≠ 已容忍**
#   —— 它只为让门禁在绑定的世代里可判，不代表任何人已经接受这个失败。
#
# 【被信号杀死的趟不算读数】harness 退出码 >128（=128+信号）⇒ NOINFO，不当红也不当绿。
# 【缺结论行 ⇒ NOINFO】没有"结论/失败数"就没有判定（缺数据 ≠ 通过）。
#
# 【只读承诺】本门禁**不修改任何既有文件、不写任何产物**；只有 --outdir 下自己的读数。
# ============================================================================
set -uo pipefail

# 【W26H 草稿】/2 → /3：本版新增列级闸的读取点与保护（`COL_ARM` 段）。
JUDGE_VER="t1b3-tline-gate/7"
SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
# 【缺陷修复】ROOT **不能**只看脚本自己的位置：把门禁拷到 $HOME 跑（波期间就是这么干的）
# 会算出 ROOT=$HOME ⇒ 所有仪器 sha 变空、tree_gen 假性 advanced，而且**不报错**。
# 现在：脚本位置 → --root → $PWD → $T1B3_REPO_ROOT 逐个试，都定不出就 NOINFO 退出。
ROOT=""; ROOT_SRC=""
# ★ `#39` 阶段 2/3：读**权威件**的路径必须跟随**唯一声明**（`build/SelfBuiltConfig.props`）。
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../../build/selfbuilt-config.sh"
ARG_ROOT=""
REG_DEFAULT=""          # ← 等 ROOT 解析出来才能定（它依赖 $MB）

ARMS=(tline tab-oracle-zero tab-oracle-anchor tab-oracle-rtl textlineproto)

OUTDIR=""; REG=""; QUIET=0; LOGDIR=""
declare -a LOG_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --log)       [ $# -ge 2 ] || { echo "NOINFO --log 缺参数" >&2; exit 3; }; LOG_ARGS+=("$2"); shift 2 ;;
    --logdir)    [ $# -ge 2 ] || { echo "NOINFO --logdir 缺参数" >&2; exit 3; }; LOGDIR="$2"; shift 2 ;;
    --registry)  [ $# -ge 2 ] || { echo "NOINFO --registry 缺参数" >&2; exit 3; }; REG="$2"; shift 2 ;;
    --outdir)    [ $# -ge 2 ] || { echo "NOINFO --outdir 缺参数" >&2; exit 3; }; OUTDIR="$2"; shift 2 ;;
    --root)      [ $# -ge 2 ] || { echo "NOINFO --root 缺参数" >&2; exit 3; }; ARG_ROOT="$2"; shift 2 ;;
    --quiet)     QUIET=1; shift ;;
    -h|--help)   sed -n '2,90p' "$SELF" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数：$1（--help 看用法）" >&2; exit 3 ;;
  esac
done
_is_repo() { [ -n "${1:-}" ] && [ -f "$1/build/MilBridge/run.sh" ] && [ -f "$1/build/MilBridge/tools/tline-gate.sh" -o -f "$1/build/MilBridge/known-red.json" ]; }
for _cand in "$(cd -- "$SELF_DIR/../../.." 2>/dev/null && pwd)" "$ARG_ROOT" "$(pwd)" "${T1B3_REPO_ROOT:-}"; do
  [ -n "$_cand" ] || continue
  if [ -f "$_cand/build/MilBridge/run.sh" ]; then
    ROOT="$(cd -- "$_cand" && pwd)"
    if [ "$_cand" = "$(cd -- "$SELF_DIR/../../.." 2>/dev/null && pwd)" ]; then ROOT_SRC="self"; 
    elif [ "$_cand" = "$ARG_ROOT" ]; then ROOT_SRC="arg";
    elif [ "$_cand" = "$(pwd)" ]; then ROOT_SRC="cwd"; else ROOT_SRC="env"; fi
    break
  fi
done
if [ -z "$ROOT" ]; then
  echo "NOINFO 定不出仓库根：脚本不在仓库里（$(dirname "$SELF")），且 --root/\$PWD/\$T1B3_REPO_ROOT 都不是仓库根。" >&2
  echo "       用法：bash $SELF --root <repo> --log <日志> [--registry <表>]" >&2
  exit 2
fi
MB="$ROOT/build/MilBridge"
REG_DEFAULT="$MB/known-red.json"
[ -n "$REG" ] || REG="$REG_DEFAULT"
case "$REG" in /*) ;; *) REG="$(pwd)/$REG" ;; esac

TS="$(date +%Y%m%d-%H%M%S)"
[ -n "$OUTDIR" ] || OUTDIR="$HOME/wfp-runs/tline-gate-$TS"
mkdir -p "$OUTDIR" || { echo "NOINFO 造不出输出目录 $OUTDIR" >&2; exit 2; }
say() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }

sha64() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1; }
SH_RUN="$MB/run.sh"
SH_PARITY="$MB/tests/HbTextLineParity/Program.cs"
SH_SHIM="$ROOT/build/shims/PresentationCore.HbTextLine.cs"
SH_PC="$ROOT/build/PresentationCore.Linux/bin/$SELFBUILT_CONFIG/PresentationCore.dll"

I_RUN="$(sha64 "$SH_RUN")"; I_PARITY="$(sha64 "$SH_PARITY")"
I_SHIM="$(sha64 "$SH_SHIM")"; I_GATE="$(sha64 "$SELF")"; I_PC="$(sha64 "$SH_PC")"
MT_SHIM="$(stat -c %Y "$SH_SHIM" 2>/dev/null || echo 0)"   # 世代仪器（被测件）的建立时间

say "==================== T1b3 · tline 门禁 ($JUDGE_VER) ===================="
say "模式          = **只读读者**（不跑 harness、不构建、不写产物）"
say "仓库根        = $ROOT   （来源 ROOT_SRC=$ROOT_SRC）"
say "登记表        = $REG"
say "读数目录      = $OUTDIR"
say "树·run.sh     = ${I_RUN:0:16}  ($SH_RUN)"
say "树·Parity     = ${I_PARITY:0:16}  ($SH_PARITY)"
say "树·shim       = ${I_SHIM:0:16}  ($SH_SHIM)"
say "树·PC         = ${I_PC:0:16}  ($SH_PC)"
say "门禁自身      = ${I_GATE:0:16}  ($SELF)"
say "loadavg       = $(cut -d' ' -f1-3 /proc/loadavg)"
say ""

detect_arm() {
  local f="$1"
  [ -f "$f" ] || { echo ""; return; }
  if grep -aq '^TAB_LINES 文件=' "$f" 2>/dev/null; then
    local fn; fn="$(grep -a -m1 -oE '^TAB_LINES 文件=.*' "$f" | sed 's/^TAB_LINES 文件=//' | tr -d '\r')"
    case "$fn" in
      tab-zero-oracle.json)   echo tab-oracle-zero ;;
      tab-anchor-oracle.json) echo tab-oracle-anchor ;;
      tab-rtl-oracle.json)    echo tab-oracle-rtl ;;
      *)                      echo "" ;;
    esac
  elif grep -aq '== 轨道A · TextLine 契约限时原型 ==' "$f" 2>/dev/null; then echo textlineproto
  elif grep -aq 'T1b/B2 · HbTextLine 对拍 harness' "$f" 2>/dev/null; then echo tline
  else echo ""; fi
}

declare -A ARM_LOG=() ARM_SRC=() ARM_WHY=()

for f in ${LOG_ARGS[@]+"${LOG_ARGS[@]}"}; do
  [ -n "$f" ] || continue
  if [ ! -f "$f" ]; then say "⚠️ --log 不存在：$f ⇒ 跳过"; continue; fi
  a="$(detect_arm "$f")"
  if [ -z "$a" ]; then say "⚠️ --log $f 认不出臂（无 TAB_LINES 文件= / 契约限时原型 / 对拍 harness 标志）⇒ 跳过"; continue; fi
  if [ -n "${ARM_LOG[$a]:-}" ]; then say "⚠️ 臂 $a 已有日志，忽略后来的 $f"; continue; fi
  ARM_LOG[$a]="$f"; ARM_SRC[$a]=log
done

if [ -n "$LOGDIR" ]; then
  if [ -d "$LOGDIR" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      a="$(detect_arm "$f")"; [ -z "$a" ] && continue
      [ -n "${ARM_LOG[$a]:-}" ] && continue
      ARM_LOG[$a]="$f"; ARM_SRC[$a]=log
    done < <(find "$LOGDIR" -maxdepth 1 -type f -name '*.log' -printf '%T@ %p\n' 2>/dev/null | sort -rn | cut -d' ' -f2-)
  else
    say "⚠️ --logdir 不是目录：$LOGDIR"
  fi
fi

for a in "${ARMS[@]}"; do
  [ -n "${ARM_LOG[$a]:-}" ] || ARM_WHY[$a]="没有给这个臂任何日志（本门禁是读者，不会自己去跑）⇒ 无读数"
done
say ""

ARMS_TSV="$OUTDIR/arms.tsv"
: > "$ARMS_TSV"
for a in "${ARMS[@]}"; do
  printf '%s\t%s\t%s\t%s\n' "$a" "${ARM_SRC[$a]:-none}" "${ARM_LOG[$a]:-}" "${ARM_WHY[$a]:-}" >> "$ARMS_TSV"
done

python3 - "$OUTDIR" "$REG" "$ARMS_TSV" "$I_RUN" "$I_PARITY" "$I_SHIM" "$I_GATE" "$I_PC" "$JUDGE_VER" "$MT_SHIM" "$ROOT" "${ARMS[@]}" <<'PYEOF'
import sys, os, re, json, hashlib

(outdir, reg_path, arms_tsv, i_run, i_parity, i_shim, i_gate, i_pc, judge_ver, mt_shim,
 repo_root) = sys.argv[1:12]
arms = sys.argv[12:]
mt_shim = int(mt_shim)

FAIL, NOINFO = 1, 2
def emit(s=""): print(s)

# ── 登记表 ────────────────────────────────────────────────────────────────
reg, reg_err, reg_entries, gen = None, None, [], {}
try:
    with open(reg_path, encoding="utf-8") as f:
        reg = json.load(f)
    reg_entries = reg.get("entries", [])
    gen = reg.get("generation", {}) or {}
    if not isinstance(reg_entries, list) or not reg_entries:
        reg_err = "登记表没有 entries（空表 ≠ 通过）"
    if not gen.get("instr_shim"):
        reg_err = reg_err or "登记表没有 generation.instr_shim ⇒ 不知道它绑哪个世代"
except FileNotFoundError:
    reg_err = "登记表不存在：%s" % reg_path
except Exception as e:
    reg_err = "登记表读不出/JSON 坏：%s: %s" % (type(e).__name__, e)

GEN_KEYS = ("instr_run_sh", "instr_program_cs", "instr_shim")
gen_shas = {k: gen.get(k) for k in GEN_KEYS} if gen else {}
tree = {"instr_run_sh": i_run, "instr_program_cs": i_parity, "instr_shim": i_shim}
tree_same_as_gen = bool(gen_shas) and all(gen_shas.get(k) and tree[k] == gen_shas[k] for k in GEN_KEYS)

emit("==================== 世代 / 口径 ====================")
emit("登记表世代    = %s  %s" % (gen.get("id", "<无>"), gen.get("label", "")))
emit("  gen run.sh  = %s" % (gen_shas.get("instr_run_sh") or "<无>")[:16])
emit("  gen Parity  = %s" % (gen_shas.get("instr_program_cs") or "<无>")[:16])
emit("  gen shim    = %s" % (gen_shas.get("instr_shim") or "<无>")[:16])
emit("  gen 证据日志= %s" % gen.get("evidence_log", "<无>"))
emit("树 vs 世代    = %s%s" % ("same（树 == 登记世代）" if tree_same_as_gen else
     "advanced（树比登记世代新 —— 这不是错误，登记表刻意绑『最后一个有完整读数的世代』）",
     "" if tree_same_as_gen else "  树 shim=%s" % i_shim[:16]))
if gen.get("leg_resolution"):
    emit("  腿核清      = %s" % gen["leg_resolution"].get("conclusion", "?"))
emit("")

# ── 臂 → 日志 ─────────────────────────────────────────────────────────────
meta = {}
with open(arms_tsv, encoding="utf-8") as f:
    for ln in f:
        p = ln.rstrip("\n").split("\t")
        if len(p) >= 4: meta[p[0]] = {"source": p[1], "log": p[2], "why": p[3]}

def first(pat, t, flags=re.M):
    m = re.search(pat, t, flags)
    if not m: return None
    return m.group(1) if m.groups() else m.group(0)

def pair_lt(v):
    try:
        a, b = v.split("/"); return int(a) < int(b)
    except Exception: return None
def pos(v):
    try: return int(v) > 0
    except Exception: return None

# field → 红条件（显式登记；未登记过的 field ⇒ NOINFO，不许猜）
RED_BY_FIELD = {
    "逐行记账·结构":   pair_lt,
    "Collapse明细全等": pair_lt,
    "宽度超差行数":     pos,
    "Extent余差条数":   pos,
    "结构败":           pos,
    # 特例：读数是"该判据自己的 ❌/✅"（用于登记"这条判据红，但含义/根因未定位"的情形）
    "判据状态":         lambda v: None if v is None else (v.strip() == "❌"),
    # ── 【W26H 草稿 · 列级闸 `D-G14`】新释放的 `Start` 列 ─────────────────────
    #   why 另起字段名而不是复用 `红`/`判定行`：`field` 是读数四元组的最后一项（纪律 18），
    #   同一支臂上「新释放列的红」与「既有列（结构/位置）的红」在登记表里必须**可分辨**，
    #   否则登记条目会张冠李戴。红条件 = 计数 > 0（与 `结构败` 同族，**只加严**）。
    #   下限/退化检查**不走这里**（`eval_shape` 的语法 `count==N|<N|A/B|子串` 表达不了「≥N」
    #   ⇒ 那两条走 `COL_ARM` 段；理由见该段）。
    "列START·红":       pos,
}

def reading_of(rec, a, cid, field):
    """取读数。`判据状态` 是**特例**：读数 = 该判据(Check) 自己的 ❌/✅。"""
    if field == "判据状态":
        # 【主控 2026-09-15 修：与 `judge_red` 用**同一把尺子**】
        #   tab 臂的 case 只要**有 FAILCASE 行**（结构面**或**位置面）就是红 ⇒ 判据状态必须是 ❌。
        #   否则 `结构=PASS 位置=FAIL` 的 case 会读成 "✅" 而登记形状是 "❌" ⇒ 被判 `KNOWN_RED_DRIFT`
        #   （实测 46 条）。方向：**加强红检测、不放宽任何口径**。
        if a.startswith("tab-oracle-") and cid in rec.get("case_reason", {}):
            return "❌"
        st = rec.get("check_status", {}).get(cid)
        if st is None: return None
        return "❌" if st == "FAIL" else ("✅" if st == "PASS" else st)
    return rec.get("readings", {}).get(field)

def eval_shape(shape, val):
    """expected_shape 是**谓词**：count==N / <N / A/B / 其它=子串包含。A/B 对取分子比 N。"""
    if val is None: return None
    s = shape.strip()
    p = re.fullmatch(r"\s*(\d+)\s*/\s*(\d+)\s*", val)
    if p: num = int(p.group(1))
    else:
        try: num = int(val.strip())
        except Exception: num = None
    m = re.fullmatch(r"count==(-?\d+)", s)
    if m: return None if num is None else (num == int(m.group(1)))
    m = re.fullmatch(r"<(-?\d+)", s)
    if m: return None if num is None else (num < int(m.group(1)))
    m = re.fullmatch(r"(\d+)/(\d+)", s)
    if m: return val.strip() == s
    return s in val

# ── 抽取 ──────────────────────────────────────────────────────────────────
A = {}
for a in arms:
    m = meta.get(a, {"source": "none", "log": "", "why": "无记录"})
    rec = {"arm": a, "source": m["source"], "log": m["log"], "why": m["why"],
           "present": False, "pairing": None, "red": None, "readings": {},
           "check_status": {}, "notes": [], "caliber": None}
    A[a] = rec
    p = m["log"]
    if not p or not os.path.isfile(p):
        rec["why"] = rec["why"] or "无日志"; continue
    rec["present"] = True
    rec["log_mtime"] = int(os.path.getmtime(p))
    try:
        with open(p, "rb") as f: t = f.read().decode("utf-8", "replace")
    except Exception:
        rec["why"] = "日志读不出"; continue
    rec["bytes"] = len(t)

    dec_run  = first(r"^\[TLINE_GATE\] instr run\.sh=([0-9a-f]{64})", t)
    dec_par  = first(r"^\[TLINE_GATE\] instr .*?Parity=([0-9a-f]{64})", t)
    dec_shim = first(r"^\[TLINE_GATE\] instr .*?shim=([0-9a-f]{64})", t)
    hdr_shim = first(r"^\s+sha256=([0-9a-f]{64})", t)
    fx_shim  = first(r"固定=([0-9a-f]{64})", t)
    decl = {}
    if dec_run:  decl["instr_run_sh"] = dec_run
    if dec_par:  decl["instr_program_cs"] = dec_par
    if dec_shim: decl["instr_shim"] = dec_shim
    if hdr_shim: decl.setdefault("instr_shim", hdr_shim); decl["log_header_shim"] = hdr_shim
    if fx_shim:  decl["log_fixed_shim"] = fx_shim; decl.setdefault("instr_shim", fx_shim)
    rec["declared"] = decl
    rec["pairing"] = "strong" if dec_shim or (hdr_shim and fx_shim) else "weak"

    if a == "tline":
        ln = first(r"^.*\[逐行记账·结构\].*$", t)
        if ln:
            mm = re.search(r"全等 (\d+) / (\d+)", ln)
            if mm: rec["readings"]["逐行记账·结构"] = "%s/%s" % (mm.group(1), mm.group(2))
        wn = first(r"^.*\[口径·宽度分桶\].*?>0\.34DIP=(\d+) 行.*$", t)
        wo = first(r"^.*\[宽度绝对值\].*?>0\.34 DIP (\d+) 行.*$", t)
        if wn is not None:
            rec["readings"]["宽度超差行数"] = wn; rec["width_style"] = "口径·宽度分桶(新)"
        elif wo is not None:
            rec["readings"]["宽度超差行数"] = wo; rec["width_style"] = "宽度绝对值(旧)"
        else:
            rec["width_style"] = None
        cl = first(r"^.*折叠判定一致 \d+/\d+；真折叠 \d+ 行，明细全等 \d+/\d+.*$", t)
        if cl:
            mm = re.search(r"折叠判定一致 (\d+)/(\d+)；真折叠 (\d+) 行，明细全等 (\d+)/(\d+)", cl)
            rec["readings"]["Collapse明细全等"] = "%s/%s" % (mm.group(4), mm.group(5))
            rec["readings"]["Collapse判定一致"] = "%s/%s" % (mm.group(1), mm.group(2))
            rec["readings"]["真折叠行数"] = mm.group(3)
        em = first(r"^.*\[② Extent 余差清单\] 共 (\d+) 条.*$", t)
        if em is not None: rec["readings"]["Extent余差条数"] = em
        rcv = first(r"→ harness 退出码 (\d+)", t)
        pf  = first(r"^通过 \d+ / 失败 \d+$", t)
        rec["harness_rc"] = int(rcv) if rcv is not None else None
        if pf:
            mm = re.search(r"^通过 (\d+) / 失败 (\d+)$", pf, re.M)
            rec["pass_n"] = int(mm.group(1)); rec["fail_n"] = int(mm.group(2))
        if rec["harness_rc"] is not None and rec["harness_rc"] > 128:
            rec["killed"] = True
            rec["kill_why"] = ("harness 被信号杀死（退出码 %d = 128+%d）⇒ 本趟读数不成立（NOINFO）"
                               % (rec["harness_rc"], rec["harness_rc"] - 128))
        if pf is None:
            rec["incomplete"] = True
            rec["incomplete_why"] = "日志缺 `通过 N / 失败 M` 结论行 ⇒ 这趟没跑到结论（NOINFO）"
        for i in sorted(set(re.findall(r"^  ❌ ([A-Za-z0-9._-]+) ", t, re.M))): rec["check_status"][i] = "FAIL"
        for i in sorted(set(re.findall(r"^  ✅ ([A-Za-z0-9._-]+) ", t, re.M))): rec["check_status"].setdefault(i, "PASS")
        rec["red"] = None if (rec["harness_rc"] is None and rec.get("fail_n") is None) \
                     else bool((rec["harness_rc"] or 0) != 0 or (rec.get("fail_n") or 0) > 0)

    elif a.startswith("tab-oracle-"):
        f = first(r"^TAB_LINES 文件=(.+)$", t)
        rec["tab_file"] = f.strip() if f else None
        tot = first(r"^TAB_LINES 合计 cases=\d+ 判定过=\d+ 结构败=\d+ 不可比\(缺字形\)=\d+", t)
        if tot:
            mm = re.search(r"^TAB_LINES 合计 cases=(\d+) 判定过=(\d+) 结构败=(\d+) 不可比\(缺字形\)=(\d+)", tot, re.M)
            rec["readings"]["cases"] = mm.group(1); rec["readings"]["判定过"] = mm.group(2)
            rec["readings"]["结构败"] = mm.group(3)
        rcv = first(r"^TAB_LINES 退出码=(\d+)", t)
        ureg = first(r"^TAB_LINES 退出码=\d+（未登记失败 (\d+)", t)
        rec["tab_rc"] = int(rcv) if rcv is not None else None
        rec["tab_unreg_n"] = int(ureg) if ureg is not None else None
        if rcv is None:
            rec["incomplete"] = True
            rec["incomplete_why"] = "日志缺 `TAB_LINES 退出码=` 行 ⇒ 这趟没跑到结论（NOINFO）"
        elif rec["tab_rc"] > 128:
            rec["killed"] = True
            rec["kill_why"] = ("探针被信号杀死（退出码 %d = 128+%d）⇒ 本趟读数不成立（NOINFO）"
                               % (rec["tab_rc"], rec["tab_rc"] - 128))
        rec["unregistered_probe"] = [l.strip() for l in t.splitlines() if l.startswith("TAB_LINES UNREGISTERED ")]
        rec["probe_known_red"]    = [l.strip() for l in t.splitlines() if l.startswith("TAB_LINES KNOWN-RED ")]
        rec["case_reason"] = {}
        for l in t.splitlines():
            mm = re.match(r"^TAB_LINES CASE (\S+) .* 结构=(PASS|FAIL)", l)
            if mm: rec["check_status"][mm.group(1)] = mm.group(2)
            mm2 = re.match(r"^TAB_LINES FAILCASE (\S+) :: (.*)$", l)
            if mm2: rec["case_reason"][mm2.group(1)] = mm2.group(2)
        rec["red"] = None if rec["tab_rc"] is None \
                     else bool(rec["tab_rc"] != 0 or int(rec["readings"].get("结构败", 0)) > 0)

    elif a == "textlineproto":
        idx = t.find("== 轨道A · TextLine 契约限时原型 ==")
        seg = t[idx:] if idx >= 0 else ""
        pf = first(r"^== 通过 \d+ / 失败 \d+ ==$", seg)
        if pf:
            mm = re.search(r"^== 通过 (\d+) / 失败 (\d+) ==$", pf, re.M)
            rec["pass_n"] = int(mm.group(1)); rec["fail_n"] = int(mm.group(2))
        mm = re.search(r"\[IGR\] 共 (\d+) 个 run", seg)
        if mm: rec["readings"]["IGR run 数"] = mm.group(1)
        for st, i in re.findall(r"^  (PASS|FAIL)  ([A-Za-z0-9._-]+)  ", seg, re.M):
            rec["check_status"][i] = st
        mm = re.search(r"^  (PASS|FAIL)  A8  ", seg, re.M)
        if mm: rec["a8"] = mm.group(1)
        cp = first(r"^== 探针：通过 \d+ / 失败 \d+ ==$", t)
        if cp:
            mm = re.search(r"^== 探针：通过 (\d+) / 失败 (\d+) ==$", cp, re.M)
            rec["contractprobe"] = {"pass": int(mm.group(1)), "fail": int(mm.group(2))}
            rec["notes"].append("【范围外·诚实披露】ContractProbe 段：通过 %s / 失败 %s —— 其 P1/P4/P6 是已知宿主侧缺口，"
                                "**未登记在本门禁射程**，本门禁不据此判绿也不据此判红。" % (mm.group(1), mm.group(2)))
        if rec.get("fail_n") is None:
            rec["red"] = None
            rec["incomplete"] = True
            rec["incomplete_why"] = "日志缺 TextLineProto 段的 `== 通过 N / 失败 M ==` ⇒ 这趟没跑到结论（NOINFO）"
        else:
            rec["red"] = bool(rec["fail_n"] > 0)

# ── 口径 / 世代检查（按臂） ────────────────────────────────────────────────
calib = {}
for a in arms:
    r = A[a]
    if not gen_shas:
        calib[a] = ("NOGEN", []); continue
    decl = r.get("declared") or {}
    keys = [k for k in GEN_KEYS if decl.get(k)]
    if keys:
        mism = [(k, decl[k], gen_shas.get(k)) for k in keys if decl[k] != gen_shas.get(k)]
        calib[a] = (("MISMATCH", mism) if mism else ("OK-declared", keys))
    else:
        # 弱配对（日志不自报被测件）：必须**树 == 世代**，且**日志不得早于该世代的被测件**
        # ——「日志不可能早于它应当练过的那个仪器」（#15 实测到的洞：10:36 的 tab 日志
        #    在树前进到 #15 之后会被当成 #15 的读数 ⇒ 必须用 mtime 挡住）。
        if not tree_same_as_gen:
            calib[a] = ("UNVERIFIABLE", [])
        elif r.get("log_mtime") is not None and r["log_mtime"] < mt_shim:
            calib[a] = ("STALE-WEAK", [])
        else:
            calib[a] = ("OK-tree", [])

entry_gen_bad = [e.get("case_id", "?") for e in reg_entries
                 if any(e.get("caliber", {}).get(k) != gen_shas.get(k) for k in GEN_KEYS)]

# ── 逐臂 NOINFO 判定 ──────────────────────────────────────────────────────
arm_noinfo = {}
for a in arms:
    r = A[a]
    if not r["present"]:                 arm_noinfo[a] = r["why"] or "无日志"
    elif r.get("killed"):                arm_noinfo[a] = r["kill_why"]
    elif r.get("incomplete"):            arm_noinfo[a] = r["incomplete_why"]
    elif r["red"] is None:               arm_noinfo[a] = "该臂日志里读不到判定（判据/退出码都没有）"
    elif calib[a][0] == "MISMATCH":
        d = "；".join("%s 登记=%s 实测=%s" % (k, (g or "?")[:16], (v or "?")[:16]) for k, v, g in calib[a][1])
        arm_noinfo[a] = "口径不一致（登记表口径与读数不一致，需人工更新登记表）：%s" % d
    elif calib[a][0] == "UNVERIFIABLE":
        arm_noinfo[a] = ("无法证明该日志属于登记世代 %s：日志**不自报**仪器 sha（弱配对），"
                         "而树已前进（树 shim=%s ≠ 登记 shim=%s）⇒ NOINFO"
                         % (gen.get("id"), i_shim[:16], (gen_shas.get("instr_shim") or "?")[:16]))
    elif calib[a][0] == "STALE-WEAK":
        arm_noinfo[a] = ("日志**不自报**被测件（弱配对），且其 mtime（%s）**早于**该世代被测件的 mtime（%s）"
                         "⇒ 它不可能属于世代 %s（那个被测件当时还不存在）⇒ NOINFO"
                         % (__import__("datetime").datetime.fromtimestamp(r["log_mtime"]).strftime("%F %T"),
                            __import__("datetime").datetime.fromtimestamp(mt_shim).strftime("%F %T"), gen.get("id")))
    elif calib[a][0] == "NOGEN":
        arm_noinfo[a] = "登记表没有 generation ⇒ 不知道该日志属于哪个世代"

# ── 【W26H 草稿 · 列级闸 `D-G14`】新释放列的读数 + 两条保护（**只加严，不放宽**）──
# 【缺口（机械实测；夹具 = 逐字抽出本解析器 + 真 `tab-anchor.log` 的**格式级**变体）】
#   ① 补丁后「放行且全绿」的日志：本门禁 stdout **只有日志路径与 outdir 两行不同**，
#      `readings`/`red`/`check_status`/`unregistered_probe` **逐字段相同** ⇒ 新读数**一个字都读不到**；
#   ② 补丁后「放行了但一行没判」（`字形释放行=0`）的日志：本门禁**仍判 `PASS` + `rc=0`**，
#      与 ① 逐字相同 ⇒ **假绿**（纪律 41 ②「在门里但不看那个字段」比「不在门里」更隐蔽）；
#   ③ 补丁后「释放列真红」的日志：经 `TAB_LINES UNREGISTERED` **已经**判 `FAIL`+`unregistered=1`
#      ⇒ **牙齿已存在**，本段**不重复**它（那条红走 `entries[]`，可登记、可点名、不改 rc）。
# 【为什么下限要**声明**、不写死在门禁里】下限的值是一个**读数**（重取之后才知道），而纪律 53 要求
#   「那个值只许有一处声明」⇒ 声明放 `known-red.json` 的 **`generation.column_gate`**
#   （**与 W26D 的 `generation.arm_logs` 同形态** = 「本世代钉住的一个读数」；本门禁只按
#   `GEN_KEYS` 取 `generation` 的键、不校验 schema ⇒ 加这一键对判定零影响，
#   且**不动顶层块的集合** ⇒ 连 `schema`/`_FIELDTABLE` 都不用动。本件已用夹具机械证过）。
#   为什么**不**放顶层：本表自己的字段表写着「新增了一个顶层块」是升版理由（`_FIELDTABLE` :7）⇒
#   放 `generation` 里可以完全回避这次升版。
#   缺声明 ⇒ `NOINFO`（**不是** PASS、也**不是** FAIL）：纪律 27 ③ / 37 ③「缺项不许计入通过」。
COL_ARM = {"tab-oracle-anchor": "START"}   # 声明哪支臂带哪一列（依据：该语料带 `lineStartOffsetsDip`）
COL_RE = re.compile(r"^TAB_LINES START 红=(\d+) 绿=(\d+) 判定行=(\d+) NOINFO=(\d+)\b[^\n]*?"
                    r"字形释放行=(\d+) 非零真值行判定=(\d+)", re.M)

def _logtext(r):
    p = r.get("log")
    if not p or not os.path.isfile(p): return ""
    try:
        with open(p, "rb") as f: return f.read().decode("utf-8", "replace")
    except Exception: return ""

col_decl = {}
try:
    col_decl = ((gen or {}).get("column_gate") or {}).get("arms") or {}
except Exception:
    col_decl = {}
col_info, col_bad = {}, []
for a in arms:
    want = COL_ARM.get(a)
    if not want or a in arm_noinfo: continue
    r = A[a]
    # ⚠️ 陷阱（实测）：`TAB_LINES START ` 是**逐例行与汇总行的共同前缀** —— 真 `tab-anchor.log` 里
    #   **438 行**以它开头而**只有 1 行**是汇总行，且逐例行**也**含 `红=`/`绿=`
    #   ⇒ 照抄 `pc-line-step.sh:72` 的 `grep -a -m1 '^… START '` **会取到第一条例行**（判据静默失效）。
    #   本段用 `re.M` + 行首 `TAB_LINES START 红=` 锚定，并要求**命中行数恰为 1**（否则 NOINFO）。
    d = col_decl.get(a)
    if not isinstance(d, dict) or d.get("column") != want:
        # **先查声明**：没声明就没有"该看什么"的定义 ⇒ 连读都不该当读数（缺声明 ≠ 通过）
        col_bad.append((a, want, "NOINFO",
                        "登记表没有声明 `column_gate.arms[%s]`（缺声明 ⇒ 不许当通过；"
                        "该块须与**重取臂同趟**写入，值 = 重取实测读数）" % a)); continue
    hits = COL_RE.findall(_logtext(r))
    if len(hits) != 1:
        col_bad.append((a, want, "NOINFO", "列汇总行命中 **%d** 行（要求恰 1 行）" % len(hits))); continue
    cre, cgr, cjudge, cnoinfo, crel, cnz = (int(x) for x in hits[0])
    col_info[a] = {"column": want, "红": cre, "绿": cgr, "判定行": cjudge, "NOINFO": cnoinfo,
                   "字形释放行": crel, "非零真值行判定": cnz,
                   "decl": d if isinstance(d, dict) else None}
    # **注入既有 `readings` 字典**（不改那一行的形状）⇒ ① 逐臂"读数："行自动披露新列；
    #   ② **既有**的 `entries[]` 通道（`reading_of` 走 `rec["readings"]`，:283-295）就能读到
    #   `列START·红` ⇒ 主控可以像登记别的红一样把"已裁定的新列红"登记进来（可点名、不改 rc）。
    for k, v in (("红", cre), ("绿", cgr), ("判定行", cjudge), ("NOINFO", cnoinfo),
                 ("字形释放行", crel), ("非零真值行判定", cnz)):
        r["readings"]["列%s·%s" % (want, k)] = str(v)
    for key, lab, val in (("judged_min", "判定行", cjudge), ("released_min", "字形释放行", crel)):
        floor = d.get(key)
        if not isinstance(floor, int):
            col_bad.append((a, want, "NOINFO", "声明缺整数 `%s`（下限是读数，须在重取之后钉）" % key)); continue
        if val < floor:
            col_bad.append((a, want, "FAIL",
                            "**列级闸退化**：%s=%d < 声明下限 %d ⇒ 有一批行不再被判定。"
                            "⚠️ 两种成因必须人工裁定：① 红检测被放松（有人收回/收窄了放行面）；"
                            "② 该列有一批行改走了 NOINFO（例如 `格式化抛…` / `行数不符`）"
                            "—— 后者是**装置/口径**问题，不是被测件回归（纪律 30）。"
                            % (lab, val, floor)))
# ── 【W28G 草稿 · D-G20】汇总行 ⇔ 探针自带「逐例对账行」的三层一致性（**只加严，不放宽**）──
# 【缺口】探针在逐例循环后**自己**打了一行对账（`CoverageProbe/Program.cs:1817`）：
#   `TAB_LINES START 对账 逐例求和 红=<r> 绿=<g> NOINFO=<n> ⇒ 与汇总一致|**与汇总不一致**`
#   而本门禁对 `对账` 的读取点是 **0** ⇒ 「汇总行与逐例之和不一致」抓不到（W27A 报告 :402 自报的射程缺口）。
# 【射程】**只**对本段已过「声明 + 汇总行命中恰 1 行」两关的臂生效（即 `COL_ARM` 声明过的臂）。
# 【为什么这不引入假红】该臂语料**构造性无此列**（`tab-zero`/`tab-rtl` 的 `lineStartOffsetsDip` 出现 0 次
#   ⇒ `startField=false`）时，汇总行本身就不存在 ⇒ `COL_RE` 命中 ≠1 ⇒ 上面已 `continue` ⇒ 走不到本段。
# ⚠️ **行尾锚与 CRLF（`#28` W28J 独立复核查出、主控当场修）**：
#   ① 探针的逐例绿行是**混合形态** —— `Program.cs:1557`/`:1744` 写作
#      `"行=" + n + " 红=" + r + " 绿=" + g + (ni > 0 ? " NOINFO=" + ni : "")`
#      ⇒ 带 NOINFO 的那种行**不带 `$` 尾锚就匹配不上** ⇒ 会把该行的 红/绿 **漏计** ⇒ **假指控**。
#      （W28J 夹具 X11 实测打出 `逐例求和(0,612,0) ≠ 对账行自报(0,614,1)` 的**假**不一致。）
#   ② 门禁自己在 `:170` 用 `tr -d '\r'` ⇒ 说明作者预期过 CRLF；而本段原正则**没有 `\r?`**
#      ⇒ 一份 CRLF 臂日志会**逐例一行都匹配不上** ⇒ 求和全 0 ⇒ **假红 rc=1**（W28J 夹具 X8 实测）。
#   ⇒ 修法：`NOINFO` 用**同行可选组**取（不再是"另一种行形态"），并给两个正则都加 `\r?`。
REC_RE = re.compile(r"^TAB_LINES START 对账 逐例求和 红=(\d+) 绿=(\d+) NOINFO=(\d+).*?"
                    r"⇒\s*(与汇总一致|\*\*与汇总不一致\*\*)\s*\r?$", re.M)
PCC_RE = re.compile(r"^TAB_LINES START (\S+) 行=(\d+) 红=(\d+) 绿=(\d+)(?: NOINFO=(\d+))?\r?$", re.M)
for a in sorted(col_info.keys()):
    r = A[a]; t = _logtext(r)
    recs = REC_RE.findall(t)
    if len(recs) != 1:
        col_bad.append((a, COL_ARM.get(a), "FAIL",
                        "**对账行缺失/不唯一**：`TAB_LINES START 对账` 命中 **%d** 行（要求恰 1 行）"
                        "⇒ 探针不再打对账行（仪器回退）⇒ 汇总行与逐例之和无法互相校验" % len(recs))); continue
    rr, rg, rn, suf = int(recs[0][0]), int(recs[0][1]), int(recs[0][2]), recs[0][3]
    ci = col_info[a]
    _pm = list(PCC_RE.finditer(t))
    cr = sum(int(m.group(3)) for m in _pm)
    cg = sum(int(m.group(4)) for m in _pm)
    # ⚠️ 逐例 NOINFO **与 红/绿 同行**（探针只在 `ni > 0` 时追加那个字段）⇒ 取可选组，不另设行形态。
    cn = sum(int(m.group(5)) for m in _pm if m.group(5) is not None)
    bad = []
    if (cr, cg, cn) != (rr, rg, rn):
        bad.append("逐例求和(红=%d 绿=%d NOINFO=%d) ≠ 对账行自报(红=%d 绿=%d NOINFO=%d)" % (cr, cg, cn, rr, rg, rn))
    if (rr, rg, rn) != (ci["红"], ci["绿"], ci["NOINFO"]):
        bad.append("对账行自报(红=%d 绿=%d NOINFO=%d) ≠ 汇总行(红=%d 绿=%d NOINFO=%d)" % (rr, rg, rn, ci["红"], ci["绿"], ci["NOINFO"]))
    if suf != "与汇总一致":
        bad.append("对账行自报结论=%s（探针自己说与汇总不一致）" % suf)
    if bad: col_bad.append((a, COL_ARM.get(a), "FAIL", "**汇总/逐例不一致**：" + "；".join(bad)))
    else:   r["readings"]["列%s·对账" % ci["column"]] = "OK 逐例求和=对账行=汇总行"
# ── 【W31B 落地 · `D-G30` 格 (b)】汇总行等式牙 `判定行 == 红 + 绿`（**只加严，不放宽**）────────
# 【缺口（`D-G30` 同族第二格；W30C 方案 §4.1(b) 指出，本件现场复现）】`判定行` 的**上向**谎报
#   今天没有任何读者：`judged_min` 只判 `<`（`:581-587`），而三层互校**不含**这个字段
#   （对账行里根本没有 `判定行`）⇒ 「`判定行` 单独改大」那一档**恒绿**；`#28` 的作者也在
#   `:754-757` 逐字记过这个边界（原文保留，未删）。
# 【为什么这条牙有**定义**支撑（不是新发明口径）】探针是**累加**出来的：
#   `stJudge += gr + gg`（`build/MilBridge/tests/CoverageProbe/Program.cs:1573`／`:1761`）
#   ⇒ `判定行 == 红 + 绿` 是**恒等式**（与语料/口径无关）⇒ 违反只可能是「三个数里单独改了谁」。
#   （`OVERFLOWED` 列同族：`ovJudge += r0 + g0`，`Program.cs:1809` ⇒ 下面 `col2` 段同一条牙。）
# 【判 `FAIL`、不判 `NOINFO`（主控派单裁定；W30C 曾建议按 `:806-811` 判 `NOINFO`）】
#   理由 = 这是**定义等式**而不是"某个字段该是几"的口径：探针不可能**合法**地印出违反它的
#   汇总行 ⇒ 判红**零假红风险**。若将来发现它是口径（本件找不到这种可能）⇒ 换一个字即可。
# 【明示边界（本牙**按定义**抓不到的那一档 → 报告 §G 的边界清单）】`判定行` 与 `红`/`绿`
#   **协同**改（使等式仍成立）⇒ 本牙看不见：其中"对账行/逐例行不动"的一半由三层互校第 2 层
#   抓（`:623-624`），"三层协同"的一半**任何自洽校验都抓不到**（`:754-757` 已明示）。
COL_IDENT = {}
for _a_id in sorted(col_info.keys()):
    _ci_id = col_info[_a_id]
    if _ci_id["判定行"] != _ci_id["红"] + _ci_id["绿"]:
        COL_IDENT[_a_id] = (_ci_id["判定行"], _ci_id["红"], _ci_id["绿"])
        col_bad.append((_a_id, COL_ARM.get(_a_id), "FAIL",
                        "**汇总行自相矛盾（%s）**：`判定行=%d ≠ 红+绿=%d+%d=%d` ⇒ 探针的累加恒等式"
                        "（`CoverageProbe/Program.cs:1573`/`:1761`）被违反 ⇒ 这三个数里**至少有一个是"
                        "伪报**（典型 = 单独把 `判定行` 往上改）。判 `FAIL` 的依据 = 这是**定义等式**、"
                        "不是口径：探针不可能合法地印出它。（协同改 `判定行`＋`红/绿` 使等式成立的那一档"
                        "**本牙按定义抓不到** —— 是明示边界，不是漏判。）"
                        % (COL_ARM.get(_a_id), _ci_id["判定行"], _ci_id["红"], _ci_id["绿"],
                           _ci_id["红"] + _ci_id["绿"])))
col_noinfo = [x for x in col_bad if x[2] == "NOINFO"]
col_fail   = [x for x in col_bad if x[2] == "FAIL"]
# 结论值**必须**是 `PASS|FAIL|NOINFO` 三态之一：本仓的「步自报结论行」约定就是这个形状
#   （`PCLINE_START_STEP=PASS …` / `FRAME_STEP=PASS …` / `BASELINESHA=…`），而 `verify-all.sh`
#   `#26` W26B 刚落地的回显/诊断两条 grep（`:104` 绿分支 `^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)`
#   、`:113` 红分支）**只认这三个值** ⇒ 用三态值 ⇒ **零改动**就能让本行同时上绿屏与红屏；
#   细粒度状态另放 `state=`（`OK|REGRESSED|DECL-GAP|NONE`）。
#   ⚠️ 本行的三态**只**描述「**读数面完整不完整**」，**不是**「该列有没有红」——
#   该列的红走**既有**的 `entries[]`/`UNREGISTERED` 通道（可登记、可点名、不改 rc），
#   其条数就印在同一行的 `红=` 字段里（所以 `GATE_COLUMN=PASS` 与 `TLINE_GATE=FAIL` 可以同时出现：
#   前者 = 面完整，后者 = 面上有一条未登记的红）。
if col_fail:      col_verdict, col_state = "FAIL", "READINGS-REGRESSED"
elif col_noinfo:  col_verdict, col_state = "NOINFO", "DECL-GAP"
elif col_info:    col_verdict, col_state = "PASS", "READINGS-OK"
else:             col_verdict, col_state = "NOINFO", "NONE"

# ── 【W28C 草稿 · `D-G19`：**附加列**（`OVERFLOWED`）的下限】第 2 列起 —— **只加严，不放宽** ──
# 【缺口（机械实测；夹具 = 真 `tab-anchor.log` 的**格式级**最小失真，全部在 `$HOME` 副本上跑）】
#   同一趟日志、同一张登记表、**改前的**门禁，只改"被判定行数"：
#     · `START` 列 `判定行 615→421` + `字形释放行 194→0` ⇒ `FAIL` / `rc=1`（**既有牙齿，已实测**）；
#     · `OVERFLOWED` 列 `判定行 421→400`（`NOINFO 194→215`）⇒ **`PASS` / `rc=0`**，
#       stdout 与未失真那趟**逐字相同** ⇒ **假绿**（纪律 41 ②）；
#     · `OVERFLOWED` 汇总行**整条删除** ⇒ 仍然 **`PASS` / `rc=0`** ⇒ 同族第二形态。
#   ⇒ 本段 = 对**附加列**施同一套「声明 / 下限 / 三态」保护。
# 【为什么另起一段、而不是把 `COL_ARM` 改成通用多列表】
#   ① 既有段（`COL_ARM`/`COL_RE`/`:583-586` 的四条赋值）**一个字节都不改** ⇒ 既有 `GATE_COLUMN=`
#      那一行的**语义**仍然只描述 `START` 列 ⇒ 「START 列读数没变 ⇒ 那一行逐字节没变」是可机检的；
#   ② 既有 `arms` 键是「**每臂恰一列**」的形状（读者 `d.get("column") != want`）⇒ 改形状会位移既有
#      读者；故第 2 列起放进兄弟键 `column_gate.additional`（**形状逐字相同**）⇒ 将来的第 3 列只是加一条。
# 【为什么**不**把附加列的结论并进 `col_bad`/`col_verdict`（这一条是刻意的）】
#   第一版草稿并了进去，实测出**张冠李戴**：`OVERFLOWED` 退化时既有那一行会变成
#   `GATE_COLUMN=FAIL … arm=tab-oracle-anchor col=START 判定行=615 …`（START 自己的读数明明完好）
#   ⇒ 读屏的人会把退化归给 `START`；`GATE_REASON` 也会只吐一个 `column-gate-regressed`（不说哪一列）。
#   ⇒ 修法：两列**各自**三态、`GATE_COLUMN_EXTRA=` 自带 `arm=`/`col=`；原因名也分开
#     （`column-gate-extra-undeclared` / `column-gate-extra-regressed`）。
#     **只**把 `col2_*` 并进"总判决/rc"那两行（`:722`/`:724` 各加一个析取项）⇒ 那两处是**只加严**。
# 【为什么只声明 `judged_min`、不声明 `released_min`】`OVERFLOWED` 汇总行**没有** `字形释放行` 字段
#   （该列今天的"释放面" = 0：`tab-anchor` 的 194 行缺字形行在本列**仍是 NOINFO** —— `hasOverflowed`
#   的判定量是行宽，依赖字形；`D-G14` 只放行了与字形无关的 `Start`，`CoverageProbe/Program.cs:1565`）
#   ⇒ **不许凭空造一个字段**来满足一个对称的读者。
# 【为什么这是"牙"不是"假牙"】下限 = 实测值本身（421），**可被违反**（实测 `FAIL`/`rc=1`）。
#   而"零判别力"的形状本段**不声明**：`tab-zero`（`:205` `判定行=0 NOINFO=138`）与 `tab-rtl`
#   （`:189` `判定行=0 NOINFO=163`）的 `OVERFLOWED` **整列 NOINFO** ⇒ 钉 `judged_min=0` 恒不可违反
#   = 假牙（纪律 47）⇒ 那两支臂的缺口属**另一族**（见 W28C 报告 §5）。
# 【该列的"红"不走这里】未登记红走**既有** `UNREGISTERED` 通道（`CoverageProbe/Program.cs:1837`
#   → `:1847` → 本门禁 `:602-605`）⇒ 本段**不碰** `red`/`readings`/`RED_BY_FIELD`。
# ── 【W31B 落地 · `D-G30` 格 (a)】**`tab-zero`/`tab-rtl` 的 `OVERFLOWED` 也要有读者** ─────────
# 【先把上面那句读准（本件最容易读错的一句话）】`D-G19` 裁定"**刻意不声明**"= 对**下限**
#   （`judged_min`）的裁定：那两支臂该列 `判定行=0`（整列 NOINFO）⇒ 钉 `judged_min=0` 是
#   **恒不可违反的假牙**（纪律 47）。它**不是**"这一列不该进任何判据"的裁定
#   ⇒ 给它们一条**只互校、不下限**的读者是**纯粹的加严**、且**不与那条裁定冲突**：
#   三层互校（逐例求和 ⇔ 对账行 ⇔ 汇总行）审的是"仪器自报的三个数自洽不自洽"，
#   与"该列该判多少行"无关 —— `判定行=0` 只是说它没有**判定面**，不等于没有**自报面**。
# 【落地形状】`COL2_ARM` 补两行（本行）＋ 声明册写 **`judged_min: null`**（显式"无下限"）
#   ⇒ `col2_info` 里就有它们 ⇒ 下面 `:790-` 那一段的互校进射程。
# 【三档语义（**必须同趟区分**，否则 `null` 会变成"静默取消下限"的口子）】
#   · `judged_min` **键缺**       ⇒ `NOINFO`（`column-gate-extra-undeclared`；**既有极性不变**，
#     它是被反极性档 ⑥ 覆盖过的那一条）
#   · `judged_min: null`（显式）  ⇒ **跳过下限**、机读行打 **`judged_min=none`**（本臂按裁定无下限）
#   · `judged_min` 是整数         ⇒ 既有语义（`< floor` ⇒ `FAIL column-gate-extra-regressed`）
#   ⚠️ 另加一条**自证**（W30C 报告 §6.5 自己记下的洞，本件落地）：显式声明 `null` 的臂，
#     其 `判定行` **必须 = 0**；否则 `NOINFO kind=floor-null-but-judged`
#     —— 不然"给一支**有判定面**的臂写 `null`"就能让那条下限**静默消失**而没有机器看得见。
#     判 `NOINFO`（不是 `FAIL`）：那更可能是"该重钉下限了"的**声明陈旧**，不是被测件回归。
COL2_ARM = {"tab-oracle-anchor": "OVERFLOWED",
            # 【W31B】零/双 RTL 两支臂也进射程：它们**只互校三层**（声明册写 `judged_min: null`）
            "tab-oracle-zero":   "OVERFLOWED",
            "tab-oracle-rtl":    "OVERFLOWED"}
COL2_RES = {"OVERFLOWED": re.compile(r"^TAB_LINES OVERFLOWED 红=(\d+) 绿=(\d+) 判定行=(\d+) NOINFO=(\d+)\b", re.M)}

col2_decl = {}
try:
    col2_decl = ((gen or {}).get("column_gate") or {}).get("additional", {}).get("arms") or {}
except Exception:
    col2_decl = {}
col2_info, col2_bad, col2_codes = {}, [], []   # codes 与 bad 一一对应：区分四种机制
col2_floor_none = set()   # 【W31B】(臂, 列)：声明册**显式**写了 `judged_min: null` 的那些臂列
for a in arms:
    want = COL2_ARM.get(a)
    if not want or a in arm_noinfo: continue
    r = A[a]
    d = col2_decl.get(a)
    if not isinstance(d, dict) or d.get("column") != want:
        col2_bad.append((a, want, "NOINFO",
                         "登记表没有声明 `column_gate.additional.arms[%s]`（缺声明 ⇒ 不许当通过；"
                         "该块须与**接线同趟**写入，值 = 实测读数）" % a))
        col2_codes.append("undeclared"); continue
    rx = COL2_RES.get(want)
    hits = rx.findall(_logtext(r)) if rx else []
    if len(hits) != 1:
        col2_bad.append((a, want, "NOINFO",
                         "列汇总行命中 **%d** 行（要求恰 1 行；**0 行 = 该列的读数整列消失**）" % len(hits)))
        col2_codes.append("readings-gone"); continue
    c2re, c2gr, c2judge, c2noinfo = (int(x) for x in hits[0])
    col2_info[(a, want)] = {"column": want, "红": c2re, "绿": c2gr, "判定行": c2judge,
                            "NOINFO": c2noinfo, "decl": d}
    # 【W31B 落地 · `D-G30` 格 (a)】`judged_min` 的三档语义（**"键在但 null" ≠ "键缺"**）
    #   ⚠️ 判"键缺"**必须**用 `in`：`d.get("judged_min")` 对"键缺"与"键=null"**返回同一个值**
    #      ⇒ 用 `.get(...) is None` 判会把本件要区分的那两件事**混成一体**（实测踩过这个形状）。
    if "judged_min" not in d:
        col2_bad.append((a, want, "NOINFO", "声明缺整数 `judged_min`（下限是读数，须在重取之后钉）"))
        col2_codes.append("floor-missing"); continue
    floor = d.get("judged_min")
    if floor is None:
        # 显式 `null` = **本臂该列整列无判定面** ⇒ 按 `D-G19` 裁定**不钉下限**，只互校三层。
        # 自证（W30C §6.5 的洞）：`null` 只对"真的没有判定面"的臂合法 ⇒ `判定行 != 0` ⇒ 声明陈旧 ⇒ 出声。
        if c2judge != 0:
            col2_bad.append((a, want, "NOINFO",
                             "**声明 `judged_min: null` 但该列已判 %d 行** ⇒ 这条声明已**陈旧**："
                             "`null` 的合法前提是「本臂该列整列无判定面（`判定行=0`）」，现在它有判定面 ⇒ "
                             "**必须重钉下限**（否则这条下限**静默消失**、没有任何机器看得见）。"
                             "判 `NOINFO`（不是 `FAIL`）：这是**声明陈旧**，不是被测件回归。" % c2judge))
            col2_codes.append("floor-null-but-judged")
        col2_floor_none.add((a, want))
        continue                      # **跳过下限**、但**不 continue 出射程**（col2_info 上面已建 ⇒ 互校照跑）
    if not isinstance(floor, int):
        col2_bad.append((a, want, "NOINFO", "声明缺整数 `judged_min`（下限是读数，须在重取之后钉）"))
        col2_codes.append("floor-missing"); continue
    if c2judge < floor:
        col2_bad.append((a, want, "FAIL",
                         "**列级闸退化（%s）**：判定行=%d < 声明下限 %d ⇒ 有一批行不再被判定。"
                         "⚠️ 两种成因必须人工裁定：① 红检测被放松（有人收回/收窄了放行面）；"
                         "② 该列有一批行改走了 NOINFO（`对齐非Left` / `面缺字形` / `格式化抛` / `行数不符`）"
                         "—— 后者是**装置/口径**问题，不是被测件回归（纪律 30）。"
                         % (want, c2judge, floor)))
        col2_codes.append("regressed")

# ── 【W29A · `D-G30`】`OVERFLOWED` 列的「逐例对账行」也进判据（**只加严，不放宽**）──────────────
# 【缺口（W28J 独立复核实测，`$HOME/w28j-report.md` 6857ec31d463dcfa）】探针**同时**为 `OVERFLOWED`
#   打一行对账（`CoverageProbe/Program.cs:1832`；真日志 `build/MilBridge/arm-logs/tab-anchor.log:1343`）：
#     `TAB_LINES OVERFLOWED 对账 逐例求和 红=0 绿=421 NOINFO=194 ⇒ 与汇总一致`
#   而上面 `START` 那一段的两个正则（`REC_RE` :592 / `PCC_RE` :594）**都只锚 `START`**
#   ⇒ 该列的对账行**读者 0 个**，两种形态同时存在（改前实测）：
#     · X1 该行**谎报**（绿 421→420）⇒ `rc=0`/`PASS`（**假绿**，纪律 41 ②）；
#     · X3 该行**整条删除** ⇒ `rc=0`/`PASS`（与「删 `START` 对账行 ⇒ `FAIL`」形成尖锐对比）。
#   ⇒ 本段 = 把 `START` 那一段（`:595-617`）**按同一口径泛化**到 `OVERFLOWED`（是泛化，不是新发明）。
# 【为什么必须另写逐例正则，不能把 `PCC_RE` 的列名直接换成 `OVERFLOWED`（本段的承重设计）】
#   ⚠️ **实测**（`$HOME/w29a-run/proto.py`，真 `tab-anchor.log`）：`OVERFLOWED` 的逐例行有
#   **两种形态**，而 `PCC_RE`（`:594`：`行= 红= 绿=[ NOINFO=int]`）**只认第一种**：
#     · 形态①（**判定过**；`Program.cs:1792`）`… <id> 行=3 红=0 绿=3[ NOINFO=k]` —— 真日志 **288 行**；
#     · 形态②③④（**未判**；`Program.cs:1565` 面缺字形 / `:1601` 格式化抛 / `:1755` 对齐非 Left）
#       `… <id> 行=3 NOINFO=面缺字形(本列依赖字形)2` —— **整行没有 `红=`/`绿=` 字段**，真日志 **148 行**。
#   ⇒ 若只认形态①：逐例求和得 `(红=0, 绿=421, NOINFO=0)`，而对账行自报 `(0, 421, 194)`
#     ⇒ **在今天的绿树上打出一条 `FAIL`（假红）**。（同族错法：`#28` W28J 查出的夹具 X11「假指控」
#     —— 那次是 `NOINFO` 可选组、这次是整条行形态。）
#   ⇒ 修法 = 逐例行**按形态解析**（下两个正则），**认不出的行形态逐字点名 + `NOINFO`**
#     （**装置/口径**问题，纪律 30）⇒ 既**不静默丢弃**（丢弃 = 求和偏小 = 假红），也**不误红**。
# 【形态②③④ 的 NOINFO 量为什么取 `行=`】探针在三条未判路径上都是
#   `int n0 = OverTruthCount(c); ovNoinfo += n0; ovSumNoinfo += n0; … " 行=" + n0 + " NOINFO=…"`
#   （`:1563` / `:1600` / `:1754`）⇒ **同一行印的 `行=` 就是加进 `ovSumNoinfo` 的那个量**。
#   ⚠️ 形态② 里 `NOINFO=面缺字形(本列依赖字形)<missing>` 的**尾数是缺字形的字符数**
#   （`:1475-1480` 对 `text` 逐字符计数），**不是行数** ⇒ 拿它当 NOINFO 会差一个数量级
#   （实测：该形态 `行=` 求和 = 194 = 对账行自报值；尾数求和 = 463 ≠）。
# 【自洽不变量】形态①的循环覆盖 `k ∈ [0, 行)`（`Program.cs:1763`），`k < common ⇒ 红/绿`、
#   `k ≥ common ⇒ NOINFO`（`:1765-1766`）⇒ **`红+绿+NOINFO == 行`** 恒成立；形态②③④亦成立
#   （`红=绿=0` ∧ `NOINFO == 行`）。真树三支臂实测 **436/436、86/86、84/84 违反 0**（`proto.py`）。
#   ⇒ 违反 = 该行字段自相矛盾 ⇒ 该行不可信 ⇒ 求和不可信 ⇒ 判 **`NOINFO`**（纪律 30：装置问题）
#     而不是 `FAIL`：若这是口径变化，判红就是**假红**。
# 【X2（该列**汇总行**的 `绿` 谎报）的裁定：**该抓，且本段顺带抓到**】三层比较里**汇总行也是
#   当事人**（`(_rr2,_rg2,_rn2) != (_ci2["红"],_ci2["绿"],_ci2["NOINFO"])`）⇒ 只改 `绿` 421→420
#   会让逐例求和与对账行**同时**与它不一致 ⇒ `FAIL` + 点名。
#   **注意**这不是给 `绿` 加下限：`绿` **不该**有下限 —— 该列 194 行是**依赖字形**的合法 NOINFO
#   （`Program.cs:1562-1565`），语料/口径的合法变化可以让 `绿` 变小 ⇒ 钉 `绿` 下限 = 造一台
#   **假红机器**。有上界的量是 `判定行`（= 该语料可真判的行数）⇒ 只有它进 `D-G19` 的下限声明
#   （`known-red.json` 的 `generation.column_gate.additional.arms[...].judged_min`）。
# 【明示边界（**测过的、本段判不了的那一格**）】三层**协同**谎报（汇总行 + 对账行 + 全部逐例行
#   一起改成同一个错值）**任何自洽校验都抓不到** —— 那是「下限声明」（`D-G19`）的职责，不是本段的；
#   本段只做**互校**。另：`判定行` 的**上向**谎报（421→615）`judged_min` 也抓不到（它只判 `<`），
#   本段**同样抓不到**（`判定行` 不在对账行里）——如实留在此处，未做。
# 【射程】与 `#28` 的 `COL2_*` 段**逐字同一条**：**只**对已过「声明 + 附加列汇总行命中恰 1 行」
#   两关的臂生效（即 `col2_info` 的键）⇒ `tab-zero`/`tab-rtl`（`COL2_ARM` 未声明 ⇒ `col2_info`
#   里根本没有它们）**不受影响**（实测 E/F 格 `PASS` 不变）。
REC2_RE = re.compile(r"^TAB_LINES OVERFLOWED 对账 逐例求和 红=(\d+) 绿=(\d+) NOINFO=(\d+).*?"
                     r"⇒\s*(与汇总一致|\*\*与汇总不一致\*\*)\s*\r?$", re.M)
# 形态①（判定过；`Program.cs:1792`）—— `NOINFO` 是**纯整数**同行可选组（`#28` 修过的坑 ①）
PCC2_JUDGED_RE = re.compile(r"^TAB_LINES OVERFLOWED (\S+) 行=(\d+) 红=(\d+) 绿=(\d+)(?: NOINFO=(\d+))?\r?$", re.M)
# 形态②③④（**未判**；`Program.cs:1565`/`:1601`/`:1755`）—— **无 `红=`/`绿=`**，NOINFO 量 = `行=`
PCC2_UNJUDGED_RE = re.compile(r"^TAB_LINES OVERFLOWED (\S+) 行=(\d+) NOINFO=\S+\r?$", re.M)
# 兜底：**每个逐例行都要被数到**（漏一个 = 求和偏小 = 假红）⇒ 用它验「解析覆盖」
PCC2_ANY_RE = re.compile(r"^TAB_LINES OVERFLOWED (\S+) 行=\d+\b.*?\r?$", re.M)
for _k2 in sorted(col2_info.keys()):
    _a2, _c2 = _k2
    _r2 = A[_a2]; _ci2 = col2_info[_k2]; _t2 = _logtext(_r2)
    _recs2 = REC2_RE.findall(_t2)
    if len(_recs2) != 1:
        col2_bad.append((_a2, _c2, "FAIL",
                         "**对账行缺失/不唯一**：`TAB_LINES OVERFLOWED 对账` 命中 **%d** 行（要求恰 1 行）"
                         "⇒ 探针不再打该列对账行（仪器回退）⇒ 汇总行与逐例之和无法互相校验。"
                         "【为什么判 `FAIL`、与 `START` 那一档是同是异】**同档**：探针在 "
                         "`CoverageProbe/Program.cs:1825` 的**同一个 `if (overField)` 块**里先打汇总行"
                         "（`:1827`）后打对账行（`:1832`），两者之间**没有任何分支** ⇒ 「汇总行在、对账行"
                         "不在」**不可能**由语料/口径变化产生（本段只在汇总行命中恰 1 行之后才走到）"
                         "⇒ 只能是探针被改 ⇒ **零假红风险**，与 `START` 的 `:598-601` 逐字同档。"
                         "**异**在作用域与原因码：本条只在已声明的**附加列**上生效 ⇒ "
                         "`column-gate-extra-recon-gone`。" % len(_recs2)))
        col2_codes.append("recon-gone"); continue
    _rr2, _rg2, _rn2, _suf2 = (int(_recs2[0][0]), int(_recs2[0][1]), int(_recs2[0][2]), _recs2[0][3])
    _mj2 = list(PCC2_JUDGED_RE.finditer(_t2))
    _mu2 = list(PCC2_UNJUDGED_RE.finditer(_t2))
    _sr2 = sum(int(m.group(3)) for m in _mj2)
    _sg2 = sum(int(m.group(4)) for m in _mj2)
    _sn2 = (sum((int(m.group(5)) if m.group(5) is not None else 0) for m in _mj2)
            + sum(int(m.group(2)) for m in _mu2))
    _nany2 = len(PCC2_ANY_RE.findall(_t2))
    _nshape2 = len(_mj2) + len(_mu2)
    _bad2 = []
    # ① 解析覆盖：认不出的行形态 ⇒ **NOINFO**（装置/口径），**绝不静默丢弃**
    if _nshape2 != _nany2:
        _bad2.append("逐例行解析覆盖不全：`TAB_LINES OVERFLOWED <id> 行=N` 命中 %d 行、可解析 %d 行"
                     "（形态① %d + 形态②③④ %d）⇒ **%d 行的字段形态本段认不出** ⇒ 求和不可信。"
                     "判 `NOINFO`（装置/口径，纪律 30）：**静默丢弃会变成假红**（求和偏小）。"
                     % (_nany2, _nshape2, len(_mj2), len(_mu2), _nany2 - _nshape2))
        col2_codes.append("recon-shape")
    # ② 逐例行自洽不变量（形态①）：红+绿+NOINFO == 行
    _invs2 = [m.group(1) for m in _mj2
              if int(m.group(3)) + int(m.group(4)) + (int(m.group(5)) if m.group(5) is not None else 0)
                 != int(m.group(2))]
    if _invs2:
        _bad2.append("逐例行**自相矛盾**（`红+绿+NOINFO ≠ 行`）：**%d** 行，例如 %s ⇒ 该行字段不可信 ⇒ "
                     "求和不可信。判 `NOINFO`（纪律 30）：探针不可能**合法**地印出这种行"
                     "（`Program.cs:1763-1766` 的循环覆盖 `k ∈ [0,行)`）⇒ 只可能是仪器漂移/伪造；"
                     "但**不判 `FAIL`**（若是口径变化，判红就是假红）。" % (len(_invs2), ", ".join(_invs2[:3])))
        col2_codes.append("recon-invariant")
    # ③ 三层互校（**与 `START` 的 `:610-616` 逐条同构**）：逐例求和 ⇔ 对账行自报 ⇔ 汇总行
    # ⚠️ **第 1 层（逐例求和）只在「求和可信」时才比**：若解析覆盖不全或某行自相矛盾，
    #    求和**已知**偏小/不可信 ⇒ 这时若仍然比，就会打出一条**假指控**「汇总/逐例不一致」
    #    —— 那正是 `#28` W28J 夹具 X11 查出的同族错法（**假红/假指控**，即使 rc 恰好还对）。
    #    ⇒ 不可信时**跳过第 1 层**、只判 `NOINFO`（如实说"我不知道"，而不是"你不一致"）。
    #    第 2/3 层**不依赖逐例解析** ⇒ 无论求和可不可信都照比（所以 X1/X3/X2 一个都跑不掉）。
    _sum_ok2 = (_nshape2 == _nany2) and not _invs2
    if _bad2:
        col2_bad.append((_a2, _c2, "NOINFO",
                         "；".join(_bad2) + "【本段的处置】求和**不可信** ⇒ 第 1 层（逐例求和 ⇔ 对账行）"
                         "**本次不比**（比了就是假指控）；第 2/3 层（对账行 ⇔ 汇总行）照比。"))
    _mism = []
    if _sum_ok2 and (_sr2, _sg2, _sn2) != (_rr2, _rg2, _rn2):
        _mism.append("逐例求和(红=%d 绿=%d NOINFO=%d) ≠ 对账行自报(红=%d 绿=%d NOINFO=%d)"
                     % (_sr2, _sg2, _sn2, _rr2, _rg2, _rn2))
    if (_rr2, _rg2, _rn2) != (_ci2["红"], _ci2["绿"], _ci2["NOINFO"]):
        _mism.append("对账行自报(红=%d 绿=%d NOINFO=%d) ≠ 汇总行(红=%d 绿=%d NOINFO=%d)"
                     % (_rr2, _rg2, _rn2, _ci2["红"], _ci2["绿"], _ci2["NOINFO"]))
    if _suf2 != "与汇总一致":
        _mism.append("对账行自报结论=%s（探针自己说与汇总不一致）" % _suf2)
    if _mism:
        col2_bad.append((_a2, _c2, "FAIL", "**汇总/逐例不一致（%s）**：" % _c2 + "；".join(_mism)))
        col2_codes.append("recon-mismatch")
    # ④ 读数（**只在三层全对、且无形态缺口时报 OK**）—— 与 `START` 的 `:617` 同形；
    #    键名带列名 ⇒ 不与 `列START·对账` 撞。第 2 键是**解析覆盖自曝**（本段的承重假设）。
    if not _mism and not _bad2:
        _r2["readings"]["列%s·对账" % _ci2["column"]] = "OK 逐例求和=对账行=汇总行"
        _r2["readings"]["列%s·对账逐例行" % _ci2["column"]] = (
            "%d=形①%d+形②③④%d 求和(红=%d 绿=%d NOINFO=%d)"
            % (_nshape2, len(_mj2), len(_mu2), _sr2, _sg2, _sn2))

# ── 【W31B 落地 · `D-G30` 格 (b)】附加列同一条**等式牙**（`判定行 == 红 + 绿`）──────────────
# 与上面 `START` 段（`COL_IDENT`）那条**逐条同构**；定义依据 = `CoverageProbe/Program.cs:1809`
#   （`ovJudge += r0 + g0`）⇒ 同样是**恒等式**，不是口径。
# ⚠️ 与三层互校**互补、不重复**：互校回答"三处一致不一致"（改一处即被抓），本牙回答
#   "汇总行**自己**自洽不自洽"（三处**一起**改大就绕过互校、但仍违反等式）。
COL2_IDENT = {}
for _k3 in sorted(col2_info.keys()):
    _a3, _c3 = _k3
    _ci3 = col2_info[_k3]
    if _ci3["判定行"] != _ci3["红"] + _ci3["绿"]:
        COL2_IDENT[_k3] = (_ci3["判定行"], _ci3["红"], _ci3["绿"])
        col2_bad.append((_a3, _c3, "FAIL",
                         "**汇总行自相矛盾（%s）**：`判定行=%d ≠ 红+绿=%d+%d=%d` ⇒ 探针的累加恒等式"
                         "（`CoverageProbe/Program.cs:1809`）被违反 ⇒ 判 `FAIL`（**定义等式**，非口径）。"
                         "（协同改 `判定行`＋`红/绿` 的那一档本牙按定义抓不到 —— 明示边界。）"
                         % (_c3, _ci3["判定行"], _ci3["红"], _ci3["绿"], _ci3["红"] + _ci3["绿"])))
        col2_codes.append("identity")

def _floor_repr(_d):
    """【W31B】`judged_min` 的**三档印法**（读者靠它区分"无下限"与"声明缺"这两个完全不同的态）：
       `none` = 声明册**显式**写了 `null`（本臂按 `D-G19` 裁定无下限）；`<缺>` = 声明里没有这个键（故障）。"""
    _d = _d or {}
    if "judged_min" not in _d: return "<缺>"
    _v = _d.get("judged_min")
    return "none" if _v is None else str(_v)

col2_noinfo = [x for x in col2_bad if x[2] == "NOINFO"]
col2_fail   = [x for x in col2_bad if x[2] == "FAIL"]
col2_reasons = ["column-gate-extra-" + c for c in
                ("regressed", "readings-gone", "undeclared", "floor-missing",
                 "recon-gone", "recon-mismatch", "recon-shape", "recon-invariant",
                 # 【W31B】格 (a) 的自证（`null` 的臂有判定面 ⇒ 声明陈旧）与格 (b) 的等式牙
                 "floor-null-but-judged", "identity")
                if c in col2_codes]
if col2_fail:     col2_verdict, col2_state = "FAIL", "READINGS-REGRESSED"
elif "readings-gone" in col2_codes:
                  col2_verdict, col2_state = "NOINFO", "READINGS-GONE"
elif col2_noinfo: col2_verdict, col2_state = "NOINFO", "DECL-GAP"
elif col2_info:   col2_verdict, col2_state = "PASS", "READINGS-OK"
else:             col2_verdict, col2_state = "NOINFO", "NONE"

# ── 逐条判定 ──────────────────────────────────────────────────────────────
unregistered, registered = [], []
for a in arms:
    r = A[a]
    if a in arm_noinfo: continue
    entries_here = [e for e in reg_entries if e.get("arm") == a]
    covered = set(e.get("case_id", "") if a.startswith("tab-oracle-") else e.get("case_id", "").split("-", 1)[0]
                  for e in entries_here)

    if a == "tline":
        for cid, st in sorted(r["check_status"].items()):
            if st == "FAIL" and cid not in covered:
                unregistered.append((a, cid, "harness 判据 ❌ 且登记表里没有 case_id 前缀 == %s 的条目" % cid))
    elif a.startswith("tab-oracle-"):
        for l in r["unregistered_probe"]:
            mm = re.match(r"^TAB_LINES UNREGISTERED (\S+) :: (.*)$", l)
            if mm and mm.group(1) not in covered:
                unregistered.append((a, mm.group(1), "探针报 UNREGISTERED 且登记表没有该 case_id：%s" % mm.group(2)[:120]))
        for cid, st in sorted(r["check_status"].items()):
            if st == "FAIL" and cid not in covered and not any(cid == u[1] for u in unregistered):
                unregistered.append((a, cid, "结构=FAIL 且登记表没有该 case_id"))
        for l in r["probe_known_red"]:
            mm = re.match(r"^TAB_LINES KNOWN-RED (\S+) :: (.*)$", l)
            if mm and mm.group(1) not in covered:
                unregistered.append((a, mm.group(1), "**只在探针自带表里登记**（中心登记表没有）⇒ 视为未登记失败"))
    elif a == "textlineproto":
        for cid, st in sorted(r["check_status"].items()):
            if st == "FAIL" and cid not in covered:
                unregistered.append((a, cid, "TextLineProto 断言 FAIL 且登记表里没有 case_id 前缀 == %s 的条目" % cid))

    for e in entries_here:
        cid = e.get("case_id", "?"); field = e.get("field", "?")
        shape = e.get("expected_shape", "")
        owner = cid.split("-", 1)[0]
        owner_st = r["check_status"].get(owner) if a == "tline" else r["check_status"].get(cid)
        if field not in RED_BY_FIELD:
            registered.append(("NOINFO", e, "field=%s 没有登记红条件（RED_BY_FIELD 里没有）⇒ 不许猜" % field)); continue
        val = reading_of(r, a, cid, field)
        if val is None:
            registered.append(("NOINFO", e, "读数里读不到 field=%s%s" % (field, "（宽度印法=%s）" % r.get("width_style") if a == "tline" else ""))); continue
        reading_red = RED_BY_FIELD[field](val)
        if reading_red is None:
            registered.append(("NOINFO", e, "红条件算不出：field=%s 读数=%r" % (field, val))); continue
        # 【主控 2026-09-15 修：tab 臂的「两面口径不一致」—— 记账】
        #   原实现只在 `owner_st is None`（该 case **没有** CASE 行）时才借 `case_reason` 判红；
        #   而 `结构=PASS 位置=FAIL` 的 case **有** CASE 行 ⇒ `owner_st == "PASS"` ⇒ 它们的 FAILCASE
        #   被漏掉 ⇒ 自相矛盾：**探针报 `UNREGISTERED`（178 条，含位置面）而门禁把这些 case 判成
        #   `KNOWN_RED_GONE`（实测 `gone=46`）** ⇒ 无论怎么登记都到不了 PASS（要么 `unregistered=46`、
        #   要么 `gone=46`）。这正是「同一支臂两把尺子」家族。
        #   ⇒ 修法 = **只要该 case 有 FAILCASE 行（`case_reason` 非空）就判红**。
        #   ⇒ 方向：**加强红检测、不放宽任何口径**（原判红集合 ⊂ 新判红集合）。
        #   ⇒ 实测依据：`tab-anchor` 的 FAILCASE 行 = **178** 条（= 探针自报的「未登记失败 178」），
        #     其中 `结构=FAIL` 132 条、`位置=FAIL` 140 条 ⇒ 修前恰好漏掉 46 条纯位置面失败。
        if a.startswith("tab-oracle-") and owner_st != "FAIL" and cid in r.get("case_reason", {}):
            owner_st = "FAIL"
        judge_red = (owner_st == "FAIL")
        still_red = bool(reading_red) or judge_red
        sok = eval_shape(shape, val)
        if sok is None:
            registered.append(("NOINFO", e, "expected_shape=%r 算不出（读数=%r）" % (shape, val))); continue
        mark = ""
        if not reading_red and judge_red:
            mark = "；READING_GREEN_BUT_JUDGE_RED（读数本身已不红，红由判据 %s 承载）" % owner
        # 未定位的在册红：**登记 ≠ 已理解、更 ≠ 已容忍** ⇒ 用不同的 marker 逐趟点名。
        status_red = "KNOWN_RED_UNLOCATED" if e.get("unlocated") is True else "KNOWN_RED"
        if still_red and sok:
            registered.append((status_red, e, "实得=%r（形状如登记）%s" % (val, mark)))
        elif still_red and not sok:
            registered.append(("KNOWN_RED_DRIFT", e,
                "登记形状=%r 实得=%r（红仍在，但读数漂移 ⇒ 登记表需更新）%s" % (shape, val, mark)))
        else:
            registered.append(("KNOWN_RED_GONE", e,
                "登记形状=%r 实得=%r（该条已不红 ⇒ 在册红消失）" % (shape, val)))

# ── 输出 ──────────────────────────────────────────────────────────────────
emit("==================== 逐臂读数 ====================")
for a in arms:
    r = A[a]
    tag = "NOINFO" if a in arm_noinfo else ("RED" if r["red"] else "GREEN")
    emit("── 臂 %-18s %s  src=%s  pairing=%s  caliber=%s" % (a, tag, r["source"], r["pairing"], calib[a][0]))
    if r["log"]: emit("     日志 = %s" % r["log"])
    if r.get("declared"):
        d = r["declared"]
        emit("     日志自报：shim=%s  run.sh=%s  Parity=%s" % (
            (d.get("instr_shim") or "-")[:16], (d.get("instr_run_sh") or "-")[:16], (d.get("instr_program_cs") or "-")[:16]))
    if a in arm_noinfo: emit("     ⇒ %s" % arm_noinfo[a])
    if a == "tline":
        emit("     harness 退出码=%s  通过=%s 失败=%s  宽度印法=%s" % (r.get("harness_rc"), r.get("pass_n"), r.get("fail_n"), r.get("width_style")))
    if a.startswith("tab-oracle-"):
        emit("     真值文件=%s  TAB_LINES 退出码=%s（**红绿不取它**，红绿取判据状态）" % (r.get("tab_file"), r.get("tab_rc")))
    if r["readings"]:
        emit("     读数：" + "  ".join("%s=%s" % (k, v) for k, v in sorted(r["readings"].items())))
    if r["check_status"]:
        bad = sorted(k for k, v in r["check_status"].items() if v == "FAIL")
        emit("     判据：FAIL %d 条 %s" % (len(bad), bad if bad else ""))
    if r.get("a8"): emit("     A8 = %s" % r["a8"])
    for n in r["notes"]: emit("     " + n)
emit("")

emit("==================== 在册红逐条判定 ====================")
cnt = {}
if reg_err:
    emit("  [NOINFO] 登记表不可用：%s" % reg_err)
for status, e, detail in registered:
    cnt[status] = cnt.get(status, 0) + 1
    emit("  [%-15s] arm=%s case_id=%s  generation=%s" % (status, e.get("arm"), e.get("case_id"), e.get("generation", "?")))
    emit("                    artifact=%s field=%s 登记shape=%s" % (e.get("artifact"), e.get("field"), e.get("expected_shape")))
    emit("                    carrier（这条红当前由谁承载）= %s" % e.get("carrier", "<未登记 carrier>"))
    emit("                    %s" % detail)
emit("")

emit("==================== 未登记失败 ====================")
if not unregistered: emit("  （无）")
for a, cid, why in unregistered:
    emit("  [UNREGISTERED] arm=%s id=%s" % (a, cid))
    emit("                 %s" % why)
emit("")


# ── 【W29E草稿 · `D-G26`】探针身份闸（`probe` 段，与 `COL_ARM`/`COL2_ARM` **同族**）──────
# 【缺口】产生三支 tab 臂读数的探针 `build/MilBridge/tests/CoverageProbe/Program.cs`
#   既不在 `GEN_KEYS`（`:247`）、也不在 `close-wave.sh` 的 `fp_inputs()`
#   （`grep -c CoverageProbe build/close-wave.sh` = **0**）、臂日志里也**不记它的 sha**
#   （三支 tab 日志的首行直接就是 `TAB_LINES CASE …`）⇒ **改测量代码没有任何指纹会动**
#   ⇒ 静默改变**所有读数的含义**（`D-G26`；比 `D-G22` 更重：那条管"判据"，本条管"测量"）。
#   ⚠️ 不是假设：`#26` W26A 真改过它（`dea2a02cf8bab55a → 2477901979795979`），
#      当时只靠**人工记账**跟住、**没有任何机器红**。
# 【判据】日志**自报**的探针源内容 sha == 现场该探针源文件的 sha256（**64 位逐字**）。
#   出处 = `ShimShaReader/Program.cs:12` 的法律「**完整 sha256 逐字相等**才算够
#   （不许只比 16 位前缀：前缀相等不是内容相等）」；以及 `HbTextLineShimSha.targets:7-13`
#   「必须是**内容**而不是 mtime —— mtime 双向都骗过人（纪律 24）」。
# 【三态（铁律：`NOINFO` 不许当绿）】
#   · 该臂**不在** `generation.probes` 里      ⇒ **不判**（同 `COL_ARM` 的射程纪律：刻意不声明的臂放行）
#   · 声明了但日志里**没有**自报行            ⇒ **NOINFO**（老日志 ⇒"探针身份未知" ⇒ 必须重取臂）
#   · 自报行 >1 条且值互相矛盾                  ⇒ **FAIL**（防"打两行、读者只取第一行"）
#   · 声明的探针源**不在盘上**                  ⇒ **NOINFO**
#   · 抽出但 ≠ 现场                            ⇒ **FAIL**（= "日志出自另一版探针" —— 必须被看见）
#   · 抽出且 == 现场（64 位逐字）               ⇒ **PASS**
# 【为什么"自报行"是承重设计，而不是"记进登记表"就够】见 w29e-report.md §2 形状 A/B 对比：
#   登记表里的值只能证明"**表**与现场同版"，证不了"**日志**出自哪一版"；而"事后核对"要求
#   拿一份旧日志就能定它的产出者 ⇒ 身份必须**落在日志里**。
_PROBES = ((gen or {}).get("probes") or {})
PROBE_RE = re.compile(r"^TAB_LINES_PROBE sha256=([0-9a-f]{64}) path=(\S+)\r?$", re.M)
# ⚠️【W30B 落地修正 ③：`probe_codes` 存**裸码**，`probe-` 前缀只在下面拼一次】
#   W29E 草稿在 `append` 时写 `"probe-selfreport-absent"`，又在 `probe_reasons` 里加一次
#   `"probe-" + c` ⇒ 实测打出 `GATE_REASON=probe-probe-selfreport-absent`（双前缀，本车道实测）。
probe_info, probe_bad, probe_codes, probe_seen = {}, [], [], {}
# ⚠️【W30B 落地修正 ①：读 `probes.arms`，与 `column_gate.arms` 同形】
#   `gen["probes"]` 是**带 `why`/`unit`/`note` 的声明块**（与 `column_gate` 同族），臂映射在它的
#   **`arms`** 子键里。W29E 草稿此处写成 `_PROBES.get(_a)`（把臂名当 `probes` 的**直接**子键）
#   ⇒ 与它自己的登记册形状**不一致**；实测后果（本车道当场抓到，证据 = `$HOME/w30b-run/polar/E6-oldlogs.stdout`）：
#   `_PROBES` 非空但**没有任何臂命中** ⇒ `probe_info` 恒空 ⇒ 每支声明过的臂都**静默 `continue`**
#   ⇒ 本闸"上线即哑"（`GATE_PROBE=NOINFO … declared=0`，而 `TLINE_GATE=` **仍 `PASS`**）。
#   `arm_logs` 是**扁平**的（臂名 → sha），`probes` 取"带 why 的声明块"形状 ⇒ 两者不同形，
#   **不能照抄 `arm_logs`**；本行按 `:546` 的 `col_decl` 写法取 `arms`。
if isinstance(_PROBES, dict) and isinstance(_PROBES.get("arms"), dict):
    _PROBES = _PROBES["arms"]
if not isinstance(_PROBES, dict) or not _PROBES:
    probe_absent = True
    probe_codes.append("undeclared")
else:
    probe_absent = False
    # ⚠️ 仓库根**必须**用门禁自己解析出来的 `$ROOT`（四级回退）——**不许**从 `reg_path` 反推：
    #   W29E 的反极性夹具当场抓到，反推在"登记表是别处的副本"时**静默算错**
    #   （`dirname(dirname(reg_path))` = 表所在目录 ⇒ 探针源"不在盘上" ⇒ 全档假 NOINFO）。
    _REPO = repo_root
    for _a in arms:
        _rel = _PROBES.get(_a)
        if not _rel:
            continue                      # 刻意不声明 ⇒ 不判（射程纪律）
        _hits = PROBE_RE.findall(_logtext(A[_a]))
        probe_seen[_a] = (_hits[0][0][:16] if _hits else "-")
        if not _hits:
            probe_info[_a] = "NOINFO"
            probe_bad.append((_a, "NOINFO", "日志里没有 `TAB_LINES_PROBE sha256=` 自报行 ⇒ "
                              "**探针身份未知**（老日志 ⇒ 必须重取本臂）"))
            probe_codes.append("selfreport-absent"); continue
        _vals = sorted({h[0] for h in _hits})
        if len(_vals) != 1:
            probe_info[_a] = "FAIL"
            probe_bad.append((_a, "FAIL", "日志里 %d 条自报行互相矛盾：%s"
                              % (len(_hits), ",".join(v[:16] for v in _vals))))
            probe_codes.append("decl-conflict"); continue
        _abs = _rel if os.path.isabs(_rel) else os.path.join(_REPO, _rel)
        if not os.path.exists(_abs):
            probe_info[_a] = "NOINFO"
            probe_bad.append((_a, "NOINFO", "声明的探针源不在盘上：%s" % _rel))
            probe_codes.append("missing"); continue
        with open(_abs, "rb") as _f:
            _live = hashlib.sha256(_f.read()).hexdigest()
        if _vals[0] != _live:
            probe_info[_a] = "FAIL"
            probe_bad.append((_a, "FAIL", "日志自报探针 sha=%s ≠ 现场 %s=%s ⇒ **日志出自另一版探针**"
                              % (_vals[0][:16], _rel, _live[:16])))
            probe_codes.append("sha-mismatch"); continue
        probe_info[_a] = "PASS"
probe_noinfo = [x for x in probe_bad if x[1] == "NOINFO"]
probe_fail   = [x for x in probe_bad if x[1] == "FAIL"]
if probe_absent:
    probe_verdict, probe_state = "NOINFO", "DECL-GAP"
elif probe_noinfo:
    probe_verdict, probe_state = "NOINFO", "DECL-GAP"
elif probe_fail:
    probe_verdict, probe_state = "FAIL", "REGRESSED"
elif not probe_info:
    # ⚠️【W30B 落地修正 ②：这一档必须**出声**且必须**传导到 `TLINE_GATE=`**】
    #   到达此处的形态 = `probes.arms` 有键，但**没有一个键落在本门禁的五臂名单里**
    #   （例如登记册写的是日志名主干 `tab-zero` 而不是臂名 `tab-oracle-zero`，
    #     或登记册声明了一批本波没有的臂）⇒ 「声明了，却**一行都没判**」。
    #   W29E 草稿只把 `probe_verdict` 置 `NOINFO`，**没把它接进 `TLINE_GATE=` 的判决条件**
    #   （判决条件只写了 `probe_noinfo or probe_absent`，而本档两个列表**都是空**）
    #   ⇒ 实测后果：`GATE_PROBE=NOINFO state=DECL-GAP declared=0` 与
    #     `TLINE_GATE=PASS … GATE_REASON=all-as-registered` **同时出现**（本车道实测，
    #     证据 = `$HOME/w30b-run/polar/E6-oldlogs.stdout`）—— 这正是本仓铁律
    #     「`NOINFO` 不许当绿」被违反的形态，且 `GATE_REASON=all-as-registered` 会**误导读屏的人**。
    probe_verdict, probe_state = "NOINFO", "DECL-GAP"
    probe_codes.append("nothing-judged")
else:
    probe_verdict, probe_state = "PASS", "READINGS-OK"
# 【W30B 修正 ③（续）】**去重且保序**：三支 tab 臂同宿一个探针 ⇒ 同一成因会在三支臂上
#   各追加一次 ⇒ 实测打出 `probe-probe-selfreport-absent` **重复三遍**（读屏的人会以为有三个问题）。
_seen_codes = []
for _c in probe_codes:
    if _c not in _seen_codes: _seen_codes.append(_c)
probe_reasons = ["probe-" + c for c in _seen_codes]

emit("==================== 结论 ====================")
noinfo_arms = sorted(arm_noinfo.keys())
n_drift = cnt.get("KNOWN_RED_DRIFT", 0)
n_gone  = cnt.get("KNOWN_RED_GONE", 0)
n_entry_noinfo = cnt.get("NOINFO", 0)
reasons = []
if reg_err: reasons.append("registry-unusable")
if entry_gen_bad: reasons.append("registry-generation-inconsistent")
if noinfo_arms: reasons.append("noinfo-arms")
if n_entry_noinfo: reasons.append("noinfo-entries")
if unregistered: reasons.append("unregistered-failure")
if n_gone: reasons.append("registry-stale(gone)")
if n_drift: reasons.append("registry-stale(drift)")
if col_noinfo: reasons.append("column-gate-undeclared")
if col_fail:   reasons.append("column-gate-regressed")
# 【W31B 落地 · `D-G30` 格 (b)】等式牙的**原因码**（**只加一行**）：既有那一行的语义零改动
#   —— 等式违反时**两个码同时出现**是刻意的：`column-gate-regressed` 说"这一列的读数面退化了"，
#   `column-gate-identity` 说"退化形态 = 汇总行违反定义等式"（逐条点名行另见 `FAIL(col)`）。
if COL_IDENT:  reasons.append("column-gate-identity")
reasons += col2_reasons
reasons += probe_reasons

# ⚠️【W30B 落地修正 ②（续）】探针档一律走**已算出的三态** `probe_verdict`，**不再**枚举
#   `probe_noinfo or probe_absent`：那两个列表**各自都可能为空**（`probe_absent` 只覆盖
#   "`probes` 整节缺失"，`probe_noinfo` 只覆盖"臂命中且自报行缺失"）⇒ 枚举式会让
#   "声明了但没有一支臂落到射程内"这一档（`not probe_info`）**漏成 `PASS`**。
#   改成 `probe_verdict` 后三态**只有一个真值来源**，不会再分叉（本仓 `#28` 血案同族教训：
#   同一份逻辑存在两处必然分叉）。`probe_fail` 列表仍保留给逐臂点名行用。
if reg_err or entry_gen_bad or noinfo_arms or n_entry_noinfo or col_noinfo or col2_noinfo \
   or probe_verdict == "NOINFO":
    verdict, rc = "NOINFO", NOINFO
elif unregistered or n_gone or n_drift or col_fail or col2_fail or probe_verdict == "FAIL":
    verdict, rc = "FAIL", FAIL
else:
    verdict, rc = "PASS", 0

if entry_gen_bad:
    emit("  ⚠️ 登记表内部世代不自洽：这些条目的 caliber 与 generation 不一致 ⇒ %s" % entry_gen_bad)
if n_gone:
    emit("  ⚠️⚠️ **在册红消失 = 读数变好或口径变了 ⇒ 必须人工裁定，不许自动放行**")
if n_drift:
    emit("  ⚠️ 读数漂移（红仍在，但登记形状不再相等）⇒ 登记表已过期，需人工裁定后更新。")
    emit("     若你手上的日志是另一条腿（例如 `T1B_MODIFIER_META=0` = 腿B），漂移是**预期**的 ——")
    emit("     本表绑的是 %s（%s）；请用对应世代重钉，而不是放宽判据。" % (gen.get("id", "?"), gen.get("label", "")))
emit("")
for status, e, detail in registered:
    emit("  %-18s %s/%s :: %s" % (status, e.get("arm"), e.get("case_id"), detail))
    emit("  %-18s   carrier: %s" % ("", e.get("carrier", "<未登记 carrier>")))
for a, cid, why in unregistered:
    emit("  %-16s %s/%s :: %s" % ("UNREGISTERED", a, cid, why))
for a in noinfo_arms:
    emit("  %-16s %s :: %s" % ("NOINFO(arm)", a, arm_noinfo[a]))
for a, c, v, w in col_bad + col2_bad:
    emit("  %-16s %s/%s :: %s" % ("NOINFO(col)" if v == "NOINFO" else "FAIL(col)", a, c, w))
# 【W30B 落地修正 ⑤：探针档的**逐臂点名行**（W29E 草稿只把原因攒进 `probe_bad`，
#   **从未把它打印出来** ⇒ 实测 stdout 里除 `GATE_PROBE=`/`GATE_REASON=` 外**一个字都没有**，
#   与派单书「每档给逐字点名行」的要求不符，也不是本仓 `col_bad`/`col2_bad` 的惯例）。
#   格式**照抄上面 `col_bad` 那一行**（`NOINFO(probe)`/`FAIL(probe)` + 臂名 + 原因）。
for _a, _v, _w in probe_bad:
    emit("  %-16s %s :: %s" % ("NOINFO(probe)" if _v == "NOINFO" else "FAIL(probe)", _a, _w))
if probe_absent:
    emit("  %-16s %s :: %s" % ("NOINFO(probe)", "<decl>",
         "登记表没有 `generation.probes.arms`（缺声明 ⇒ 缺项必须出声，不许静默绿）"))
if not probe_info and not probe_absent and not probe_bad:
    emit("  %-16s %s :: %s" % ("NOINFO(probe)", "<scope>",
         "`generation.probes.arms` 有声明，但**没有一个键**落在本门禁的五臂名单里 ⇒ 一行都没判"))
emit("")

emit("GATE_COLUMN=%s state=%s %s" % (col_verdict, col_state, "; ".join(
    "arm=%s col=%s 判定行=%d 红=%d 绿=%d NOINFO=%d 字形释放行=%d 非零真值行判定=%d judged_min=%s released_min=%s"
    % (a, v["column"], v["判定行"], v["红"], v["绿"], v["NOINFO"], v["字形释放行"], v["非零真值行判定"],
       (v["decl"] or {}).get("judged_min", "<缺>"), (v["decl"] or {}).get("released_min", "<缺>"))
    for a, v in sorted(col_info.items())) if col_info else "（无声明中的列臂有读数）"))

# 【W28C · `D-G19`】附加列的机读行：**新起一行**（不往 `GATE_COLUMN=` 里塞 —— 那一行的语义是
#   `START` 列，且被多处报告逐字引用 ⇒ 不动）。行首形态 `KEY=三态` 与既有约定一致 ⇒
#   `verify-all.sh:215` 绿分支 grep（`head -8`）与 `:224` 红分支 grep（`head -12`）**零改动**即可回显
#   （实测：加本行后绿分支命中 2→3 ≤ 8、红分支 0→1 ≤ 12）。
emit("GATE_COLUMN_EXTRA=%s state=%s %s" % (col2_verdict, col2_state, "; ".join(
    "arm=%s col=%s 判定行=%d 红=%d 绿=%d NOINFO=%d judged_min=%s"
    % (a, c, v["判定行"], v["红"], v["绿"], v["NOINFO"], _floor_repr(v["decl"]))
    for (a, c), v in sorted(col2_info.items())) if col2_info else
    # ⚠️【W28D 落地时改】原草稿的兜底串只有一句「（无声明中的'附加列'臂有读数）」⇒ 在
    #   「**声明在、但该列汇总行消失/重复**」（`state=READINGS-GONE`）与「声明在、缺
    #   `judged_min`」这两种态下会*说反*（读者会以为"根本没声明"）⇒ 按 `col2_bad` 是否非空分成两句。
    #   这是**读数准确性**修正（本缺陷整族就是"一行看着没事、其实没事是假的"），判定语义零改动。
    ("（附加列**没有有效读数** ⇒ 逐条见下方 `NOINFO(col)` / `FAIL(col)` 行）" if col2_bad
     else "（无声明中的'附加列'臂有读数）")))
emit("TLINE_GATE=%s arms=%d red=%d green=%d noinfo_arm=%d registered=%d unlocated=%d drift=%d gone=%d unregistered=%d "
     "caliber=%s generation=%s tree_gen=%s saved_shim=%s gate=%s judge=%s outdir=%s" % (
     verdict, len(arms),
     sum(1 for a in arms if A[a]["present"] and A[a]["red"] is True and a not in arm_noinfo),
     sum(1 for a in arms if A[a]["present"] and A[a]["red"] is False and a not in arm_noinfo),
     len(noinfo_arms), len(registered), cnt.get("KNOWN_RED_UNLOCATED", 0), n_drift, n_gone, len(unregistered),
     ("OK" if not any(calib[a][0] == "MISMATCH" for a in arms) else "MISMATCH"),
     gen.get("id", "none"), ("same" if tree_same_as_gen else "advanced"),
     i_shim[:16], i_gate[:16], judge_ver, outdir))
# 【W29E草稿 · `D-G26`】探针身份自报行（**新起一行**，不塞进 `GATE_COLUMN=`/`GATE_COLUMN_EXTRA=`：
#   那两行的语义是"列"，本行是"仪器身份" —— 混住会让读屏的人把身份退化归给某一列，同 `D-G19` 的教训）。
# 【W30B 落地修正 ④：三个标签各打**它自己的东西**】
#   W29E 草稿打的 `自报=%s` 填的是 `probe_info[a]`（= **判定** PASS/FAIL/NOINFO），
#   而 `现场=%s` 读的是 `gen["probes"].get(a)`（探针已改成读 `.arms` ⇒ 恒 `-`）
#   ⇒ 实测打出 `tab-oracle-anchor 自报=NOINFO 现场=-`：**标签与内容不符**，
#     读屏的人会把"判定"当成"自报的 sha"，又把 `-` 当成"现场没有探针"。
#   现在：`自报` = 日志里那 64 位的前 16 位（无 ⇒ `-`）；`现场` = **声明**的探针源相对路径；
#   判定另起 `⇒ <verdict>`。`declared=0` 只在**一个臂都没进射程**时出现（且此时已 NOINFO）。
emit("GATE_PROBE=%s state=%s %s" % (probe_verdict, probe_state, "; ".join(
    "%s 自报=%s 现场=%s ⇒ %s" % (a, probe_seen.get(a, "-"), _PROBES.get(a, "-"),
                                  probe_info.get(a, "-"))
    for a in sorted(probe_info)) or "declared=0"))
emit("GATE_REASON=%s" % (",".join(reasons) if reasons else "all-as-registered"))

try:
    with open(os.path.join(outdir, "gate-readings.json"), "w", encoding="utf-8") as f:
        json.dump({"verdict": verdict, "reason": reasons, "judge_version": judge_ver,
                   "generation": gen, "tree": tree, "tree_same_as_generation": tree_same_as_gen,
                   "arm_caliber": {a: {"verdict": calib[a][0], "detail": calib[a][1]} for a in arms},
                   "arms": {a: A[a] for a in arms},
                   "registered": [{"status": s, "case_id": e.get("case_id"), "arm": e.get("arm"),
                                   "generation": e.get("generation"), "field": e.get("field"),
                                   "expected_shape": e.get("expected_shape"),
                                   "carrier": e.get("carrier"), "unlocated": bool(e.get("unlocated")),
                                   "caliber": e.get("caliber"), "detail": d} for s, e, d in registered],
                   "unregistered": [{"arm": a, "id": i, "why": w} for a, i, w in unregistered],
                   "entry_generation_inconsistent": entry_gen_bad,
                   "noinfo_arms": arm_noinfo,
                   "column_gate": {"verdict": col_verdict,
                                   "arms": {a: v for a, v in sorted(col_info.items())},
                                   "problems": [{"arm": a, "column": c, "level": v, "why": w}
                                                for a, c, v, w in col_bad]},
                   "column_gate_extra": {"verdict": col2_verdict,
                                   # 【W31B】**只加不删**：新增 `no_floor`（显式声明 `judged_min: null`
                                   #   的臂列 ⇒ 按 `D_G19` 裁定无下限、只互校三层）＋ `identity_bad`
                                   #   （违反定义等式 `判定行 == 红 + 绿` 的臂列）⇒ 机读读者能区分
                                   #   『无下限』与『声明缺』（后者在 `arms.*.decl` 里表现为键不存在）。
                                   "no_floor": sorted("%s|%s" % k for k in col2_floor_none),
                                   "identity_bad": sorted("%s|%s" % k for k in COL2_IDENT),
                                   "arms": {"%s|%s" % (a, c): v for (a, c), v in sorted(col2_info.items())},
                                   "problems": [{"arm": a, "column": c, "level": v, "why": w}
                                                for a, c, v, w in col2_bad]},
                   # 【W30B 落地：`D-G26` 探针身份也进机读读数】与 `column_gate` 同族
                   #   （`gate-readings.json` 是本门禁**唯一**的机读出口，实测仓内无其它消费者：
                   #    `grep -rn --include='*.sh' -- 'gate-readings' .` 只命中门禁自身 `:1191`）
                   #   ⇒ 探针档只打在 stdout 而不进 JSON 会让"机器读的人"看不见它。
                   #   **只加不删**：既有键一个未动。
                   "probe": {"verdict": probe_verdict, "state": probe_state,
                             "declared": _PROBES if isinstance(_PROBES, dict) else {},
                             "self_reported": probe_seen,
                             "arms": probe_info,
                             "problems": [{"arm": a, "level": v, "why": w}
                                          for a, v, w in probe_bad]}}, f, ensure_ascii=False, indent=1)
except Exception as e:
    emit("⚠️ 机读读数没写成：%s" % e)

sys.exit(rc)
PYEOF
rc=$?
say ""
say "（本门禁是只读读者：不跑 harness、不构建、不写别人的产物；本趟读数全在 $OUTDIR）"
exit $rc

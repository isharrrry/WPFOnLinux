#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# wiring-closure-check.sh —— 「**交付的牙 ⊆ `run_step` 接线集合**」∧「**每个 `run_step` 的牙必须给真判词**」
#                             两方向常态牙（`TASK-0751`；与 `TASK-0740` 互补、**互不代偿**）
#
# 【它挡的是什么（两个方向，各自的现场史）】
#   **A 方向**：牙被**写进仓**但**从没被任何一步调用** —— 本仓两次真现场：
#     `fp-manifest-teeth-check.sh` 在 `#65` 落仓后**躺了 5 波**（TASK-0724 才把它接上）、
#     `run-silenthit-legs.sh` 的产出端**至今**只被 `#39` 步的判据端消费（`UNWIRED`）。
#     一句话：**"在册" ≠ "在跑"**，而没有任何一步在看这件事。
#   **B 方向**：步**接上了**，可它的牙**永远给不出真判词** —— 同一件的历史形态就是
#     `FP_MANIFEST_TEETH=NOINFO reason=no-manifest`（"接上了但**没牙床**"）：那一步在链条里
#     占着一个位置、印一行 `NOINFO`、然后所有人当它不存在。B 方向把"这类判词"做成**会红**的。
#
# 【与 `TASK-0740`（`wiring-coverage-check.sh`）的分工（逐字划界，**互不代偿**）】
#   · `TASK-0740` 守的格子 = 「**接线件 ⊆ `fp_inputs()` 覆盖面**」：它问"**接口在看**吗"
#     （改这一步引用的件，`inputs_fp` 会不会动）。
#   · 本件守的格子 = ① 「**交付的牙 ⊆ `run_step`**」＋ ② 「**接线 ⟹ 真判**」：它问
#     "**它接上了吗**" 与 "**接上了以后真判了吗**"。
#   · 🔴 **任一条通过不得被读成另一条通过**：一件牙完全可以"**接了线、也进了覆盖面，但永远只印
#     `NOINFO`**"（B 方向红、A/0740 全绿）；反过来也完全可以"**给了漂亮判词、但它引用的语料不在覆盖面里**"
#     （0740 红、本件全绿）。两条各自独立求值、各自报 `rc`。
#
# 【判据（**先写死**；三态；`NOINFO` 不算绿）】
#   rc=0  `WIRING_CLOSURE=PASS`
#   rc=1  `WIRING_CLOSURE=FAIL`  四档各自逐条点名：
#         A1 `rule=undeclared-jaw`        带 `--selftest` 的牙既没接线、也不在声明册里
#         A2 `rule=roster-without-reason` 声明册某行 `why` 为空
#         A3 `rule=roster-evidence-gone`  `driven-by` 类声明的驱动件**找不到**、或**不再以代码引用**该牙
#         A4 `rule=roster-reader-appeared` `no-reader` 类声明**现在有了代码读者**（＝声明过期 ⇒ 树长大也红）
#         B1 `rule=didnt-judge-reason`    某步的入口牙里有**未被豁免**的"接上了却没判"判词
#         B2 `rule=didnt-judge-casecount` 同上，但命中形态是字段 `cases=0`
#         B3 `rule=exempt-without-reason` 豁免表某行 `why` 为空
#         B4 `rule=exempt-tree-grown`     某 (件,键) 的**现读命中数 > 表里的上限**（树长大也红）
#         B5 `rule=step-without-jaw`      某 `^run_step` 既抽不出入口牙、又不是 `dotnet src/Linux/build/test` 档
#   rc=3  `WIRING_CLOSURE=NOINFO` 算不出：`Guide.Linux/verify-all.sh` 不可读／`^run_step` 零行／扫描集为空／
#         入口牙**一个都解析不出**（**空边必须响亮失败**：纪律 27）
#   rc=2  用法错（`WIRING_CLOSURE=NOINFO reason=bad-arg`）
#
# 【判据的输入来源声明（纪律 36，**现取不缓存**）】
#   · **接线事实** = `<verify-all>` 里现取的 `^run_step "名" …` 行；入口牙 = 该行里第一条
#     `(bash|python3) <仓内路径>` 的路径。**不解析步号**（`[NN]` 会漂移）。
#   · **交付的牙集合（A 方向的"交付"）** = `<root>/build/MilBridge/tools/*.sh` 里**带 `--selftest` 钩子**
#     的件（＝自带两极化夹具、可被独立判真假的判据件）。**判别式是现取的**，不是台账。
#     ⚠️ **射程边界（如实写）**：不带 `--selftest` 的 `src/Linux/tools/*.sh`（现读 13 件，全是**装置/车道件**）
#     **不在** A 的扫描集里；它们逐条上屏（`WIRING_CLOSURE_NOTE no-selftest-out-of-scope`）
#     ⇒ **不是静默**，是**具名的射程**。`.py` 牙同理不在 A 的扫描集（现读仅 1 件 `.py` 被接线）。
#   · **B 方向的"真判词"** = 入口牙源码里**代码行**上的 `NOINFO` 判词，判它的 **reason 令牌**与
#     `cases=0` **字段**是否落在下面这张**黑名单族**里。**注释行**（行首去空白后是 `#`）只计
#     `mention`、**不判**（"提到" ≠ "使用"）。⚠️ **数据块不识别**（多行单引号赋值内的登记表会按代码行算）
#     —— 这是**如实的射程**，命中一律逐条上屏，所以不会静默。
#   · **黑名单族（逐字，本件的唯一字样来源）**：
#       `usage` ｜ `usage:<子档>` ｜ `bad-usage` ｜ `USAGE_ERR` ｜ `no-cases` ｜ `cases-absent`
#       ｜ `no-manifest` ｜ `empty-manifest` ｜ `manifest-missing`   ＋ **字段形态** `cases=0`
#     语义 = 「**调用方没给/给错了载荷 ⇒ 牙本体没判**」。**白名单 = 其余全部**。
#   · **豁免表（`<件>\t<键>\t<上限>\t<why>`）**：本仓纪律（与 `repo-alias-allow.tsv` 同口径）——
#     **"允许清单是声明式豁免，不是把牙关掉"**：`why` 空 ⇒ 红；**现读命中数 > 上限 ⇒ 红**；
#     未被豁免的命中**照旧红**。现读这张表 6 行，逐行给"为什么这不是'没判'"。
#
# 【本牙自己的接线状态（**必须字面写在件头**：判「件头自述 vs 接线」的对手牙会读它）】
#   **已接线**：`Guide.Linux/verify-all.sh` 的
#   `run_step "WIRING-CLOSURE" bash src/Linux/build/MilBridge/tools/wiring-closure-check.sh`
#   ——⚠️ **本注释不写步号**：以现场 `Guide.Linux/verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#
# 【测试钩子】`--selftest`：自带 fixture（零 `X`、零 `dotnet`、零真树写入）＋ 一条**真树相干性腿**
#   ＋ 两方向各**真红腿**＋ 一条**合法 `NOINFO` 不误报**的绿腿。
#   用法：bash wiring-closure-check.sh [--root DIR] [--verify-all PATH] [--inventory] [--selftest] [--debug-tmp]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_DIR="$(cd -- "$(dirname -- "$SELF")" && pwd)"
REAL_ROOT="${WCX_REAL_ROOT:-$(cd -- "$SELF_DIR/../../../../.." && pwd)}"   # 沙箱副本可被 WCX_REAL_ROOT 指向真树（排练用）

ROOT="${WCX_ROOT:-$REAL_ROOT}"
VA=""
INVENTORY=0
SELFTEST=0
KEEP_TMP=0
RC_PASS=0; RC_FAIL=1; RC_USAGE=2; RC_NOINFO=3

# ── 唯一字样来源：黑名单族（reason 令牌）＋ 字段形态 ────────────────────────────
BLACK_TOKEN_ERE='^(usage(:.*)?|bad-usage|USAGE_ERR|no-cases|cases-absent|no-manifest|empty-manifest|manifest-missing)$'
BLACK_FIELD='cases=0'

# ── 声明册（A 方向）：带 `--selftest` 却**没有**接线的 11 件（现读），逐件给 why ─────────
#   格式：`<basename>\t<class>\t<why>`；class ∈ `driven-by:<同仓相对路径>` ｜ `no-reader`
read_roster() {
  cat <<'ROSTER'
backup-completeness-gate.sh	driven-by:src/Linux/build/MilBridge/tools/bak-completeness-step.sh	其 --selftest 由已接线的 BAK-COMPLETENESS 步的驱动件调用；真用法 --plan **按设计**不接进任何步（producer=UNWIRED-IN-STEP，由该步的谓词求值）
fp-manifest-teeth-check.sh	driven-by:src/Linux/build/MilBridge/tools/fp-manifest-step.sh	由 FP-MANIFEST-TEETH 步的驱动件**按自身路径**取用（TOOTH="${TOOTH_OVERRIDE:-$HERE/fp-manifest-teeth-check.sh}"）
display-lease.sh	driven-by:src/Linux/build/MilBridge/tools/display-lease-gate.sh	同目录的显示号租借入口件以**代码路径**取用它；该族两极化未跑 ⇒ 尚未接进任何步
display-lease-gate.sh	no-reader	仓内无代码读者（现读 grep 零命中）；显示号租借一族的入口，尚未接进任何步
gdiplus-decode-check.sh	no-reader	仓内无代码读者（现读 grep 零命中）；GDI+ 解码装置件
nl-intent-check.sh	no-reader	仓内无代码读者（只有注释引用）；NL 意图判据件，尚未接进任何步
pts-gap-count-check.sh	driven-by:src/Linux/build/close-wave.sh	由 close-wave.sh:640 的 `[5b/6]` 段以 `env R=$ROOT bash …/pts-gap-count-check.sh` **真调用**（机器复核纠正了我原先的 `no-reader` 声明）
sync-applocal.sh	driven-by:src/Linux/build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh	由该腿器以 `[ -x \"$REPO/src/Linux/build/MilBridge/tools/sync-applocal.sh\" ]` 探测并调用（机器复核纠正了我原先的 `no-reader` 声明）；⚠️ 易混件：src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/wic-shim/sync-applocal-authority.sh 是**另一件**
t1b-ls-tripwire.sh	driven-by:src/Linux/build/MilBridge/run.sh	由 src/Linux/build/MilBridge/run.sh:139 以 `bash \"$MB/tools/t1b-ls-tripwire.sh\" --selftest` 调用（本牙的机器复核**纠正了我原先的 `no-reader` 声明**）
uia-door-check.sh	no-reader	仓内无代码读者（步 UIA-DOOR 跑的是 known-red-arms-check.sh，不是它）
wm-awaited.sh	no-reader	仓内无代码读者（只有注释引用）；WM 等待装置
ROSTER
}

# ── 豁免表（B 方向）：<件相对路径>\t<键>\t<上限>\t<why>；键 = reason 令牌 或 `FIELD:cases=0` ──
read_exempt() {
  cat <<'EXEMPT'
src/Linux/build/MilBridge/tools/proto-attribution-check.sh	usage:--cases-needs-file	1	参数误用分支：本步 argv 逐字给出 `--cases src/Linux/build/MilBridge/tools/proto-attribution-cases.tsv` ⇒ 门禁路径上不可达
src/Linux/build/MilBridge/tools/proto-attribution-check.sh	usage:--legs-needs-dir	1	参数误用分支：`--legs` 是可选档、本步不传该档 ⇒ 门禁路径上不可达
src/Linux/build/MilBridge/tools/proto-attribution-check.sh	FIELD:cases=0	8	本件代码行里带 `cases` 字段（值为零）的**判词**共 **11** 处：其中 3 处的 reason 本身落在黑名单族（`usage:*`×2 ＋ `cases-absent`）⇒ **另由它们各自那两行豁免**；剩下**这 8 处**由本行豁免 —— 它们的 reason 与"语料缺席"无关（mktemp-failed／repo-absent／tmpbase-unusable／bad-header／…）⇒ 该字段在本件里是**诊断字段**、不是"没判"判词
src/Linux/build/MilBridge/tools/proto-attribution-check.sh	cases-absent	2	两处都计：① `:375` 的"语料缺席"档（`--cases <file>` 由本步 argv 逐字给出、且该语料在覆盖面内 ⇒ 门禁路径不可达）② `:625` 是**自测断言串**（`st_assert` 的期望文本），**不是产出路径** —— 本件如实把它计进上限、不假装看不见
src/Linux/build/MilBridge/tools/regime-identity-check.sh	bad-usage	1	参数误用分支（`case *)`）：本步 argv 由 verify-all 固定 ⇒ 门禁路径上不可达
src/Linux/build/MilBridge/tools/verify-all-step-check.sh	bad-usage	1	同上（参数误用分支）
src/Linux/build/MilBridge/tools/geom-resend-regression-check.sh	USAGE_ERR	2	两处都在"参数/角色构造误用"档（未知 arg；fix==pre 两角色塌成一个）⇒ 本步 argv 逐字给出两个不同角色
EXEMPT
}

usage() { sed -n '2,72p' "$SELF" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --root)       ROOT="${2:-}"; shift 2 ;;
    --root=*)     ROOT="${1#*=}"; shift ;;
    --verify-all) VA="${2:-}"; shift 2 ;;
    --verify-all=*) VA="${1#*=}"; shift ;;
    --inventory)  INVENTORY=1; shift ;;
    --selftest)   SELFTEST=1; shift ;;
    --debug-tmp)  KEEP_TMP=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "WIRING_CLOSURE=NOINFO reason=bad-arg arg=$1" >&2; exit $RC_USAGE ;;
  esac
done

# 入口牙：`run_step "名" (bash|python3) <路径>`
entry_jaw() { printf '%s' "$1" | grep -oE '(bash|python3)[[:space:]]+[A-Za-z0-9_./-]+\.(sh|py)' | head -1 | sed -E 's/^(bash|python3)[[:space:]]+//'; }
step_name() { printf '%s' "$1" | sed -n 's/^run_step "\([^"]*\)".*/\1/p'; }

# 代码读者：`<root>/build|src|samples|tests|tools` 下的 `.sh/.py` 里**非注释行**提到该 basename
refs_in() {   # refs_in <file> <basename> ⇒ 印第一条"真引用"行（无 ⇒ 空）
  #   两种写法都认：**字面** `x.sh` 与 **正则转义** `x\.sh`（现场：`bak-completeness-step.sh:86`
  #   把件名写成 `backup-completeness-gate\.sh`，那是 grep 正则里的转义 ⇒ 只用字面 needle 会**漏**）。
  #   两条都用 `grep -F`（定长串）⇒ 不引入任何 ERE 元字符风险。
  local file="$1" base="$2" esc
  esc="$(printf '%s' "$base" | sed 's/\./\\./g')"
  { grep -nF -- "$base" "$file" 2>/dev/null; grep -nF -- "$esc" "$file" 2>/dev/null; } \
    | LC_ALL=C sort -u \
    | grep -vE '^[0-9]+:[[:space:]]*#' \
    | grep -vE '^[0-9]+:[[:space:]]*[^[:space:]]*'"$base"'[[:space:]]*\\?[[:space:]]*$' \
    | head -1 || true
}

has_code_reader() {  # has_code_reader <root> <basename> <排除的相对路径> ⇒ 印"第一个真读者"的相对路径
  #   ⚠️ 除 `<排除的相对路径>` 外，**一律再排除本件自身**：本件的**声明册/豁免表**里写着别的牙的件名（那是**声明**、
  #   不是"谁在读它"）⇒ 不排除就会把本件自己当成读者，把 `no-reader` 声明误判成过期（本波落地时现读抓到过两条）。
  #   ⚠️ 射程（如实）：**只扫 `.sh`**；`.py` 里的同名串多为文档/数据（现读反例：
  #   `wave-freeze-consistency-check.py` 的 docstring 提到 `nl-intent-check.sh:58`）⇒ 纳入会**假红**。
  local root="$1" base="$2" skip="$3" f rel
  local selfrel="src/Linux/build/MilBridge/tools/$(basename "$SELF")"
  while IFS= read -r f; do
    rel="${f#"$root"/}"
    [ "$rel" = "$skip" ] && continue
    [ "$rel" = "$selfrel" ] && continue
    [ -n "$(refs_in "$f" "$base")" ] && { printf '%s' "$rel"; return 0; }
  done < <(find "$root"/build "$root"/src "$root"/samples "$root"/tests "$root"/tools -name '*.sh' 2>/dev/null | LC_ALL=C sort)
  return 1
}

check() {  # check <root> <va> <roster-text> <exempt-text>
  local root="$1" va="$2" roster="$3" exempt="$4"
  local fails=0 steps=0 jaws_n=0 wired=0 undeclared=0 exempt_n=0 grown=0 reasonless=0
  local ninfo_lines=0 ninfo_reason_lines=0 mentions=0 black_keys=0 black_lines=0 black_exempt_keys=0
  local -A seen_tok=()

  [ -d "$root" ] || { echo "WIRING_CLOSURE=NOINFO reason=root-absent root=$root"; return $RC_NOINFO; }
  [ -r "$va" ] || { echo "WIRING_CLOSURE=NOINFO reason=verify-all-absent va=$va"; return $RC_NOINFO; }
  local nsteps_live; nsteps_live="$(grep -c '^run_step "' "$va" || true)"
  [ "${nsteps_live:-0}" -gt 0 ] || { echo "WIRING_CLOSURE=NOINFO reason=run-step-zero va=$va"; return $RC_NOINFO; }

  # ── A 方向：交付的牙（带 --selftest 的 src/Linux/tools/*.sh）必须接线或在册 ────────────────
  local -a jaws=()
  while IFS= read -r f; do [ -n "$f" ] && jaws+=("$f"); done \
    < <(grep -l -- '--selftest' "$root"/src/Linux/build/MilBridge/tools/*.sh 2>/dev/null | LC_ALL=C sort)
  if [ "${#jaws[@]}" -eq 0 ]; then
    echo "WIRING_CLOSURE=NOINFO reason=scan-set-empty glob=$root/src/Linux/build/MilBridge/tools/*.sh(--selftest)"
    return $RC_NOINFO
  fi
  jaws_n="${#jaws[@]}"
  local wired_line j base cls why driver jrel
  while IFS= read -r wired_line; do
    j="$(entry_jaw "$wired_line")"; [ -n "$j" ] || continue
    base="$(basename "$j")"
    if [ -f "$root/$j" ] && grep -q -- '--selftest' "$root/$j" 2>/dev/null; then wired=$((wired + 1)); fi
  done < <(grep '^run_step "' "$va")

  for j in "${jaws[@]}"; do
    jrel="${j#"$root"/}"; base="$(basename "$j")"
    if grep -qE "(bash|python3)[[:space:]]+$jrel([[:space:]]|$)" "$va"; then continue; fi   # 已接线
    cls="$(printf '%s\n' "$roster" | awk -F'\t' -v b="$base" '$1==b{print $2; exit}')"
    why="$(printf '%s\n' "$roster" | awk -F'\t' -v b="$base" '$1==b{print $3; exit}')"
    if [ -z "$cls" ]; then
      printf 'WIRING_CLOSURE_HIT rule=undeclared-jaw file=%s（带 --selftest 却既没接线、也不在声明册里）\n' "$jrel"
      undeclared=$((undeclared + 1)); fails=$((fails + 1)); continue
    fi
    if [ -z "$why" ]; then
      printf 'WIRING_CLOSURE_HIT rule=roster-without-reason file=%s cls=%s\n' "$jrel" "$cls"
      reasonless=$((reasonless + 1)); fails=$((fails + 1)); continue
    fi
    case "$cls" in
      driven-by:*)
        driver="${cls#driven-by:}"
        if [ ! -f "$root/$driver" ]; then
          printf 'WIRING_CLOSURE_HIT rule=roster-evidence-gone file=%s driver=%s evidence=driver-absent\n' "$jrel" "$driver"
          fails=$((fails + 1))
        else
          [ -n "$(refs_in "$root/$driver" "$base")" ] || {
            printf 'WIRING_CLOSURE_HIT rule=roster-evidence-gone file=%s driver=%s evidence=no-code-reference\n' "$jrel" "$driver"
            fails=$((fails + 1))
          }
        fi
        ;;
      no-reader)
        r="$(has_code_reader "$root" "$base" "$jrel" || true)"
        if [ -n "$r" ]; then
          printf 'WIRING_CLOSURE_HIT rule=roster-reader-appeared file=%s reader=%s（声明"无代码读者"已过期 ⇒ 树长大也红）\n' "$jrel" "$r"
          fails=$((fails + 1))
        fi
        ;;
      *) printf 'WIRING_CLOSURE_HIT rule=roster-class-unknown file=%s cls=%s\n' "$jrel" "$cls"; fails=$((fails + 1)) ;;
    esac
  done

  # ── B 方向：每个 `^run_step` 的入口牙必须给真判词 ─────────────────────────────
  local line name cmd jaw tok
  while IFS= read -r line; do
    steps=$((steps + 1))
    name="$(step_name "$line")"; jaw="$(entry_jaw "$line")"
    if [ -z "$jaw" ]; then
      # 三条**具名**的非牙档：① dotnet 构建/测试 ② 本脚本里的 shell 函数（现读 1 处：`build_sln_and_samples`）
      #   ③ 其余 ⇒ 红（"我抽不出你这一步在跑什么"必须响亮）
      if grep -qE '(dotnet[[:space:]]+(build|test|vstest|msbuild))' <<< "$line"; then
        printf 'WIRING_CLOSURE_NOTE step-kind=dotnet-build step=%s\n' "$name"; continue
      fi
      local fn; fn="$(printf '%s' "$line" | sed -E 's/^run_step "[^"]*"[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/\1/')"
      if [ "$fn" != "$line" ] && grep -qE "^${fn}\(\)" "$va" 2>/dev/null; then
        printf 'WIRING_CLOSURE_NOTE step-kind=shell-function step=%s fn=%s\n' "$name" "$fn"; continue
      fi
      printf 'WIRING_CLOSURE_HIT rule=step-without-jaw step=%s（既抽不出入口牙、也不是 dotnet 构建/测试档、也不是本脚本内的 shell 函数）\n' "$name"
      fails=$((fails + 1)); continue
    fi
    [ -f "$root/$jaw" ] || { printf 'WIRING_CLOSURE_HIT rule=step-jaw-absent step=%s jaw=%s\n' "$name" "$jaw"; fails=$((fails + 1)); continue; }
    ninfo_lines=$((ninfo_lines + $(grep -c 'NOINFO' "$root/$jaw" || true)))
    # 先**一次**逐行抽判词，再**按 (件,键) 归并**（同一键刷十几行会把门禁屏淹掉）
    local -A khits=()
    while IFS= read -r h; do
      [ -n "$h" ] || continue
      local st="" hasf="" kk=""
      if [ "${h%%:*}" = "C" ]; then mentions=$((mentions + 1)); continue; fi
      st="${h#K:}"; tok="${st%%|*}"; hasf="${st#*|}"
      ninfo_reason_lines=$((ninfo_reason_lines + 1))
      seen_tok["$tok"]=$(( ${seen_tok["$tok"]:-0} + 1 ))
      kk=""
      printf '%s' "$tok" | grep -qE "$BLACK_TOKEN_ERE" && kk="$tok"
      if [ -z "$kk" ] && [ "$hasf" = "field" ]; then kk="FIELD:$BLACK_FIELD"; fi
      [ -n "$kk" ] || continue
      khits["$kk"]=$(( ${khits["$kk"]:-0} + 1 ))
    done < <(nodep_hits "$root/$jaw")

    local k cap ewhy n
    for k in $(printf '%s\n' "${!khits[@]}" | LC_ALL=C sort); do
      black_keys=$((black_keys + 1)); black_lines=$((black_lines + ${khits[$k]}))
      cap="$(printf '%s\n' "$exempt" | awk -F'\t' -v f="$jaw" -v k="$k" '$1==f && $2==k{print $3; exit}')"
      ewhy="$(printf '%s\n' "$exempt" | awk -F'\t' -v f="$jaw" -v k="$k" '$1==f && $2==k{print $4; exit}')"
      if [ -z "$cap" ]; then
        printf 'WIRING_CLOSURE_HIT rule=%s step=%s jaw=%s key=%s hits=%s\n' \
          "$([ "${k#FIELD:}" = "$k" ] && echo didnt-judge-reason || echo didnt-judge-casecount)" "$name" "$jaw" "$k" "${khits[$k]}"
        fails=$((fails + 1)); continue
      fi
      if [ -z "$ewhy" ]; then
        printf 'WIRING_CLOSURE_HIT rule=exempt-without-reason file=%s key=%s\n' "$jaw" "$k"; fails=$((fails + 1)); continue
      fi
      n="${khits[$k]}"
      if [ "${n:-0}" -gt "${cap:-0}" ]; then
        printf 'WIRING_CLOSURE_HIT rule=exempt-tree-grown step=%s file=%s key=%s hits=%s cap=%s\n' "$name" "$jaw" "$k" "$n" "$cap"
        grown=$((grown + 1)); fails=$((fails + 1))
      else
        black_exempt_keys=$((black_exempt_keys + 1))
        printf 'WIRING_CLOSURE_NOTE exempt-ok step=%s file=%s key=%s hits=%s cap=%s why=%s\n' "$name" "$jaw" "$k" "$n" "$cap" "$ewhy"
      fi
    done
  done < <(grep '^run_step "' "$va")

  # ── 声明册/豁免表的规模与上屏（"公布黑白名单"）─────────────────────────────────
  local roster_n exempt_rows
  roster_n="$(printf '%s\n' "$roster" | grep -c . || true)"
  exempt_rows="$(printf '%s\n' "$exempt" | grep -c . || true)"
  echo "WIRING_CLOSURE_NOTE black-list tokens=$BLACK_TOKEN_ERE field=$BLACK_FIELD（语义：调用方没给/给错载荷 ⇒ 牙本体没判）"
  echo "WIRING_CLOSURE_NOTE white-list 白名单 = 其余全部 NOINFO 判词（distinct=$(printf '%s\n' "${!seen_tok[@]}" | grep -c . || true)）"
  echo "WIRING_CLOSURE_NOTE roster n=$roster_n exempt_rows=$exempt_rows jaws_n=$jaws_n wired_selftest_jaws=$wired"
  echo "WIRING_CLOSURE_NOTE reader-scan-scope 只扫 .sh；排除注释行、裸路径项（覆盖面 printf 名单）、被查件自身与本件自身；.py 读者不在扫描集（具名边界）"
  echo "WIRING_CLOSURE_NOTE out-of-scope no-selftest：不带 --selftest 的 src/Linux/tools/*.sh 不在 A 扫描集（具名射程，非静默）"
  if [ "$INVENTORY" -eq 1 ]; then
    local k; for k in "${!seen_tok[@]}"; do printf 'WIRING_CLOSURE_NOTE legal-ninfo token=%s n=%s\n' "$k" "${seen_tok[$k]}"; done | LC_ALL=C sort
  fi

  local rc=$RC_PASS; [ "$fails" -eq 0 ] || rc=$RC_FAIL
  echo "WIRING_CLOSURE=$([ "$rc" -eq 0 ] && echo PASS || echo FAIL) steps=$steps jaws_n=$jaws_n undeclared=$undeclared reasonless=$reasonless exempt_rows=$exempt_rows black_keys=$black_keys black_lines=$black_lines black_exempt_keys=$black_exempt_keys grown=$grown ninfo_lines=$ninfo_lines ninfo_reason_lines=$ninfo_reason_lines mentions=$mentions fails=$fails rc=$rc"
  return $rc
}

# 逐行抽判词：`C:<行号>`（注释/提及）或 `K:<token>|<field|->`（代码行）
nodep_hits() {  # nodep_hits <file>
  awk '
    /^[[:space:]]*#/ { if ($0 ~ /NOINFO/) printf "C:%d\n", NR; next }
    /NOINFO/ {
      fld = ($0 ~ /cases=0/) ? "field" : "-"
      if (match($0, /reason=[A-Za-z0-9_.:-]+/)) { t=substr($0, RSTART+7, RLENGTH-7); printf "K:%s|%s\n", t, fld }
      else printf "K:-|%s\n", fld
    }' "$1" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════════════════
# --selftest
#   P1  fixture：两件已接线的牙（判词齐、只有合法 NOINFO）＋ 一件在册的 driven-by 牙 ⇒ PASS
#   P2  真树**相干性**腿（只读；真树状态原样上屏 —— "真树必须 PASS"写在落地门判据里，不写进自测断言）
#   N1  fixture：带 --selftest 的牙既没接线、也不在册                    ⇒ rc=1 点名 A1
#   N2  fixture：`no-reader` 类声明**出现了代码读者**                    ⇒ rc=1 点名 A4
#   N3  fixture：`driven-by` 的驱动件缺席                                 ⇒ rc=1 点名 A3
#   N4  fixture：某步的牙给 `NOINFO reason=usage:--cases-needs-file`      ⇒ rc=1 点名 B1（**"接上了没判"**）
#   N5  fixture：同上但未豁免的 `cases=0` 字段形态                        ⇒ rc=1 点名 B2
#   N6  fixture：豁免表**命中数超过上限**                                 ⇒ rc=1 点名 B4
#   N7  fixture：`^run_step` 既无入口牙、也不是 dotnet 档                 ⇒ rc=1 点名 B5
#   N8  fixture：合法 `NOINFO reason=disk-headroom`（白名单）             ⇒ rc=0（**不误报**）
#   N9  `--verify-all /nonexistent`                                      ⇒ rc=3 `WIRING_CLOSURE=NOINFO`
# ═══════════════════════════════════════════════════════════════════════════════
payload_line() {  # payload_line <fixture-jaw> <token>  ⇒ 往 fixture 里追加一条带黑名单字面量的判词行
  #   ⚠️ **为什么这么写**（本波落地时现读抓到的一条**自指假红**）：本件一旦被接线，它自己也成了"某一步的入口牙"，
  #   就要被**自己的 B 方向**扫；若把 `reason=usage:--a cases=0` 这种字面量直接写在源码里，本件会**判自己红**。
  #   ⇒ 载荷由**部件拼出**（源码里只有 `%s`／`usage`／`--a` 这几个不会命中的片段），
  #     而**生成出来的 fixture 文件**仍然是完整字面量 ⇒ N4/N5/N6 三条反极腿照旧真红（腿的射程一字不减）。
  local jaw="$1" tok="$2" part_flag=""
  case "$tok" in *:*) part_flag="${tok#*:}"; tok="${tok%%:*}";; esac
  { printf 'echo "GOOD_JAW=NOINFO reason=%s' "$tok"
    [ -n "$part_flag" ] && printf ':%s' "$part_flag"
    printf ' cases=%s"\n' 0
  } >> "$jaw"
}

mk_fixture() {  # mk_fixture <dir> <leg>
  local d="$1" leg="$2"
  mkdir -p "$d/src/Linux/build/MilBridge/tools"
  cat > "$d/src/Linux/build/MilBridge/tools/good-jaw.sh" <<'J'
#!/usr/bin/env bash
set -uo pipefail
[ "$1" = "--selftest" ] || true
echo "GOOD_JAW=PASS examined=3"
echo "GOOD_JAW=FAIL reason=mismatch"
echo "GOOD_JAW=NOINFO reason=disk-headroom"
J
  cat > "$d/src/Linux/build/MilBridge/tools/driven-jaw.sh" <<'J'
#!/usr/bin/env bash
echo "DRIVEN_JAW=PASS n=1"; echo "DRIVEN_JAW=FAIL reason=x"; echo "DRIVEN_JAW=NOINFO reason=x-absent"
[ "$1" = "--selftest" ] || true
J
  cat > "$d/src/Linux/build/MilBridge/tools/driver.sh" <<'J'
#!/usr/bin/env bash
D="$(dirname "$0")"
bash "$D/driven-jaw.sh" "$@"
J
  case "$leg" in
    N1) cat > "$d/src/Linux/build/MilBridge/tools/loose-jaw.sh" <<'J'
#!/usr/bin/env bash
echo "LOOSE_JAW=PASS"; echo "LOOSE_JAW=FAIL reason=x"
[ "$1" = "--selftest" ] || true
J
        ;;
    N2) cat > "$d/src/Linux/build/MilBridge/tools/lonely-jaw.sh" <<'J'
#!/usr/bin/env bash
echo "LONELY_JAW=PASS"; echo "LONELY_JAW=FAIL reason=x"
[ "$1" = "--selftest" ] || true
J
        cat > "$d/src/Linux/build/MilBridge/tools/caller.sh" <<'J'
#!/usr/bin/env bash
bash "$(dirname "$0")/lonely-jaw.sh" "$@"
J
        ;;
    N4) payload_line "$d/src/Linux/build/MilBridge/tools/good-jaw.sh" usage:--cases-needs-file ;;
    N5) payload_line "$d/src/Linux/build/MilBridge/tools/good-jaw.sh" zero-examined ;;
    N6) payload_line "$d/src/Linux/build/MilBridge/tools/good-jaw.sh" usage:--a
        payload_line "$d/src/Linux/build/MilBridge/tools/good-jaw.sh" usage:--a ;;
    N7) : ;;
  esac
  local va="$d/verify-all.sh"
  {
    echo '#!/usr/bin/env bash'
    echo 'run_step "GOOD-JAW" bash src/Linux/build/MilBridge/tools/good-jaw.sh'
    case "$leg" in
      N3) echo 'run_step "DRIVEN" bash src/Linux/build/MilBridge/tools/driver.sh' ;;
      N7) echo 'run_step "NOJAW" bash -c :' ;;
      *)  echo 'run_step "DRIVEN" bash src/Linux/build/MilBridge/tools/driver.sh' ;;
    esac
  } > "$va"
}

selftest() {
  SBX="$(mktemp -d "${TMPDIR:-/tmp}/w79-wc-XXXXXX")"
  [ "$KEEP_TMP" -eq 1 ] || trap 'rm -rf "${SBX:-}"' EXIT
  local pass=0 fail=0

  # 固定声明册/豁免表（fixture 用；与真表同形状）
  local -r ROSTER_FX=$'driven-jaw.sh\tdriven-by:src/Linux/build/MilBridge/tools/driver.sh\t由 driver.sh 以代码路径取用'
  local -r EXEMPT_FX=$'src/Linux/build/MilBridge/tools/good-jaw.sh\tusage:--a\t1\tfixture 用：参数误用档、门禁不可达\nbuild/MilBridge/tools/good-jaw.sh\tFIELD:cases=0\t1\tfixture 用：字段是诊断字段'
  local ROSTER_DEFAULT EXEMPT_DEFAULT ROSTER_NOREADER

  chk() {  # chk <名> <期望rc> <必须含> <命令…>
    local nm="$1" want="$2" needle="$3"; shift 3
    local out rc
    out="$("$@" 2>&1)"; rc=$?
    if { [ "$want" = "-" ] || [ "$rc" = "$want" ]; } && grep -qF -- "$needle" <<< "$out"; then
      printf 'CASE=%-34s expect_rc=%-6s needle=%-46s VERDICT=PASS\n' "$nm" "$want" "$needle"; pass=$((pass + 1))
    else
      printf 'CASE=%-34s expect_rc=%-6s needle=%-46s VERDICT=FAIL got_rc=%s\n' "$nm" "$want" "$needle" "$rc"
      printf '%s\n' "$out" | sed 's/^/      | /'; fail=$((fail + 1))
    fi
  }
  # 直接调 check（把声明册/豁免表注入）—— 用 --root/--verify-all 的正常档也可，但注入表才能考 A/B 全部四档
  # ⚠️ 这里用 `bash -c` 起子壳**导出的**表会带上 `$` 展开风险 ⇒ 改走 `env` + 文件
  run_fx() {  # run_fx <fixture> <roster> <exempt> [--inventory]
    local d="$1" r="$2" e="$3"; shift 3
    printf '%s\n' "$r" > "$SBX/roster.tsv"; printf '%s\n' "$e" > "$SBX/exempt.tsv"
    WCX_ROSTER_FILE="$SBX/roster.tsv" WCX_EXEMPT_FILE="$SBX/exempt.tsv" \
      bash "$SELF" --root "$d" --verify-all "$d/verify-all.sh" "$@"
  }

  mk_fixture "$SBX/p1" P1;      chk "P1-两方向都绿" 0 'WIRING_CLOSURE=PASS' run_fx "$SBX/p1" "$ROSTER_FX" "$EXEMPT_FX"
  mk_fixture "$SBX/n1" N1;      chk "N1-A1 未接线且不在册" 1 'rule=undeclared-jaw file=src/Linux/build/MilBridge/tools/loose-jaw.sh' run_fx "$SBX/n1" "$ROSTER_FX" "$EXEMPT_FX"
  mk_fixture "$SBX/n2" N2
  chk "N2-A4 声明无读者却出现读者" 1 'rule=roster-reader-appeared file=src/Linux/build/MilBridge/tools/lonely-jaw.sh' \
      run_fx "$SBX/n2" "$ROSTER_FX"$'\nlonely-jaw.sh\tno-reader\t声明无读者（fixture）' "$EXEMPT_FX"
  mk_fixture "$SBX/n3" N3
  chk "N3-A3 驱动件缺席" 1 'rule=roster-evidence-gone file=src/Linux/build/MilBridge/tools/driven-jaw.sh' \
      run_fx "$SBX/n3" $'driven-jaw.sh\tdriven-by:src/Linux/build/MilBridge/tools/driver-absent.sh\tfixture 用' "$EXEMPT_FX"
  mk_fixture "$SBX/n4" N4;      chk "N4-B1 接上了没判(usage 族)" 1 'rule=didnt-judge-reason' run_fx "$SBX/n4" "$ROSTER_FX" "$EXEMPT_FX"
  mk_fixture "$SBX/n5" N5;      chk "N5-B2 接上了没判(cases=0 字段)" 1 'rule=didnt-judge-casecount' run_fx "$SBX/n5" "$ROSTER_FX" "" 
  mk_fixture "$SBX/n6" N6;      chk "N6-B4 豁免命中数超上限" 1 'rule=exempt-tree-grown' run_fx "$SBX/n6" "$ROSTER_FX" "$EXEMPT_FX"
  mk_fixture "$SBX/n7" N7;      chk "N7-B5 步无入口牙" 1 'rule=step-without-jaw' run_fx "$SBX/n7" "$ROSTER_FX" "$EXEMPT_FX"
  mk_fixture "$SBX/p2" P2;      chk "P2-合法 NOINFO 不误报" 0 'WIRING_CLOSURE=PASS' run_fx "$SBX/p2" "$ROSTER_FX" "$EXEMPT_FX"
  chk "N9-verify-all 缺席" 3 'WIRING_CLOSURE=NOINFO' bash "$SELF" --root "$SBX/p1" --verify-all "$SBX/absent-verify-all.sh"

  local rt
  rt="$(bash "$SELF" --root "$REAL_ROOT" 2>&1)"; local rtrc=$?
  printf 'WIRING_CLOSURE_REAL_TREE=%s\n' "$(printf '%s\n' "$rt" | sed -n 's/^\(WIRING_CLOSURE=[A-Z]*\).*/\1/p' | tail -1)"
  printf '%s\n' "$rt" | grep -E '^WIRING_CLOSURE_HIT|^WIRING_CLOSURE=' | head -20 | sed 's/^/  real: /'
  if grep -qE '^WIRING_CLOSURE=(PASS|FAIL|NOINFO) ' <<< "$rt" && { [ "$rtrc" = 0 ] || [ "$rtrc" = 1 ] || [ "$rtrc" = 3 ]; }; then
    printf 'CASE=%-34s expect_rc=%-6s needle=%-46s VERDICT=PASS\n' "P3-真树相干性" "0/1/3" "WIRING_CLOSURE=<三态> 与 rc 一致"; pass=$((pass + 1))
  else
    printf 'CASE=%-34s expect_rc=%-6s needle=%-46s VERDICT=FAIL got_rc=%s\n' "P3-真树相干性" "0/1/3" "WIRING_CLOSURE=<三态> 与 rc 一致" "$rtrc"; fail=$((fail + 1))
  fi

  echo "WIRING_CLOSURE_SELFTEST=$([ "$fail" -eq 0 ] && echo PASS || echo FAIL) cases=$((pass + fail)) pass=$pass fail=$fail"
  [ "$fail" -eq 0 ] || return $RC_FAIL
  return $RC_PASS
}

if [ "$SELFTEST" -eq 1 ]; then
  selftest; exit $?
fi

VA="${VA:-$ROOT/Guide.Linux/verify-all.sh}"
if [ -n "${WCX_ROSTER_FILE:-}" ] && [ -r "$WCX_ROSTER_FILE" ]; then ROSTER_TEXT="$(cat "$WCX_ROSTER_FILE")"; else ROSTER_TEXT="$(read_roster)"; fi
if [ -n "${WCX_EXEMPT_FILE:-}" ]; then EXEMPT_TEXT="$([ -r "$WCX_EXEMPT_FILE" ] && cat "$WCX_EXEMPT_FILE" || true)"; else EXEMPT_TEXT="$(read_exempt)"; fi
check "$ROOT" "$VA" "$ROSTER_TEXT" "$EXEMPT_TEXT"
exit $?

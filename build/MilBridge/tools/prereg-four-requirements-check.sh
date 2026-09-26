#!/usr/bin/env bash
# prereg-four-requirements-check.sh —— 「预登记里四要件在不在」的**文档层**牙（`TASK-0705` 的补件；车道 W147A）
#
# 【为什么要这颗牙】既有牙 `build/MilBridge/tools/regression-decision.py` 判的是**给进去的那组计数**
#   满不满足四要件；它**不看预登记文档**。⇒ 本件补上那一半：**新波的预登记必须在「判据节」里
#   真把四要件写死**，而不是在背景里"讨论"过。
#
# 【判据先写（本件自己就是判据物化，不是事后描述）】
#   `PREREG4=PASS`（rc=0） ⟸ 文件在 ∧ 判据节找得到 ∧ 判据节里**同时**有：
#        ① 机器声明行 `PREREG-REGRESSION-FOUR:` 且四键全 `=yes`；
#        ② 四个要件的**标记**（① 两臂同刻／② 成对归因臂／③ 复现性／④ Fisher 双尾）；
#        ③ 判据件路径（`regression-decision.py`）；
#        ④ 三态判词词表（`REGRESSION` 与 `NOINFO` **都在**判据节里）。
#   `PREREG4=FAIL`（rc=1） ⟸ 上列任一缺（**逐格点名**，`PREREG4_MISSING=` 行）。
#        ⚠️ **防伪绿**：四要件**只在判据节之外**出现（即"讨论了但没采纳"）⇒ **判 FAIL**，不判 PASS。
#        （形态与 `D-G42`/`D-G97` 同族：**不许按关键词认对象**。）
#   `PREREG4=NOINFO`（rc=3） ⟸ **查不动**：文件不存在／不可读／找不到任何「判据」节（非预登记形态）。
#        ⚠️ `NOINFO` **既不算绿也不算红**。
#   ★ **`#60` W152A 新增 `PREREG4=NA`（rc=0）** ⟸ **判据节里逐字声明「本波不做任何回归判定」**
#        ∧ **全文无回归判定证据**（`REGRESSION_DECISION=`／`regression-decision-cases.tsv`）
#        ⇒ 四要件**对本波 N/A**。**充要两条**，缺声明 ⇒ 走正常路径（该 FAIL 就 FAIL）；
#        留声明却引用了回归判定证据 ⇒ **仍 FAIL**（声明**不许**当免死金牌）。
#        `N/A` **与 `PASS` 分开计数**（`na=` 独立一格）＋ 逐件点名 `PREREG4_NA …`。
#        （来源：`TASK-0709`；`#59` 现场＝被逼着抄一节，而它自己写着"是这一刻不适用的声明"。）
#
# 【两极化自测（`--selftest`，自带 fixture，不依赖仓内任何波）】
#   正极性：完好预登记 ⇒ `PASS rc=0`；补齐一份缺件 ⇒ **回绿**。
#   负极性：缺 ①／②／③／④ 各一例 ⇒ **必红**；另加「只在背景讨论、判据节没有」一例 ⇒ **必红**；
#           文件不存在 ⇒ `NOINFO rc=3`（**不许**当绿、也**不许**当红）。
#
# 【用法】
#   bash prereg-four-requirements-check.sh docs/WAVE57-PREREGISTRATION.md
#   bash prereg-four-requirements-check.sh --selftest
#   bash prereg-four-requirements-check.sh --glob 'docs/WAVE*-PREREGISTRATION.md'
#
# 【边界（如实写）】本件只判"**要件在不在文档里**"；它**判不了**"那组计数是真的"
#   （"同刻/交替/计划是先写的"仍只能靠调用者断言 ＋ 人来看）。
#   纯静态读、零 `dotnet`、秒级；**未接线**（不进 verify-all，由主控编排）。

set -uo pipefail

SELF="${BASH_SOURCE[0]}"
RC_PASS=0
RC_FAIL=1
RC_NOINFO=3

# ── 四要件的**标记词**（每个要件给一组同义标记，命中任一即算该要件在）
MARK1='两臂同刻'
MARK2='成对归因臂'
MARK3='复现性'
MARK4='Fisher'

# ── 生效波次（**防造假红 ＋ `#59` 生效边界修法**）：本要件**只对 `#58` 及以后的新波生效**
#    （`TASK-0705` 的纪律 = "不许倒填进既有冻结件来美化历史判词"）。
#    现场机械证：不加这道守卫时，`docs/WAVE*-PREREGISTRATION.md` **37 件里 35 件会红**
#    （含当波 `#56`）—— 那是"**拿新规则审判历史件**"，是**造假红**，不是缺陷。
#    ⏪ 上面那句的件数是**当时**的（37）—— **加注不覆盖**，原文留档。**现测（`#59` W151A，2026-09-24）**：
#      `docs/WAVE*-PREREGISTRATION.md` 共 **39 件**；**旧牙（生效代 57）**在全量扫描下 = `PASS 1 / FAIL 1（仅 `WAVE57`，`missing=7`）/ 跳过 37`；**新牙（生效代 58）** = **`pass=1 / fail=0 / skip=38 / noinfo=0`**（`WAVE57` 由"假红"变 `SKIP`）。
#
#    ⚠️ **为什么是 `58`（旧值 `57` 的后果 —— `#59` W151A 就地更正，加注不覆盖，旧值留档如下）**：
#      · 旧值 `REQ_EFFECTIVE_WAVE=57` 会**漏掉一代**：`docs/WAVE57-PREREGISTRATION.md` 落在**射程内**
#        ⇒ 真判 ⇒ 而 `#57` 的预登记**写在本工具存在之前**、且按 `TASK-0705` 的"**只加不改**"**不许倒填**
#        ⇒ 它**必然** `FAIL missing=7`。那是"**拿晚出的规则审判早出的件**"＝**造假红**，
#        与这道守卫**要防的东西是同一个** —— 守卫自己漏了一代。
#      · 而 `#58` 的预登记是**第一份合规件**（现场已 `PASS`）⇒ 必须**真判**、**不许**被 SKIP 掉，
#        否则"跳过"就成了"放低边界换取好过"—— `HANDOFF-NEXT.md` 第 20 条**明令禁止**。
#      ⇒ 这两条**同时**只有 `58` 满足。改这一位**必须**同步改自测的两例
#        （`WAVE57 ⇒ SKIP`、`WAVE58 ⇒ 真判`），否则自测当场抓到你。
#
#    【三态口径（`HANDOFF-NEXT.md` 第 20 条"判据的生效边界必须可见"）】
#      超出射程 ⇒ 打 **`PREREG4=SKIP`**（**独立 token**，与 `PASS`/`FAIL`/`NOINFO` **四态分开计数**）
#      ＋ **逐件点名** `PREREG4_SKIP … reason=pre-effective(…)`；
#      **`SKIP` 既 ≠ 通过、也 ≠ 违规** ⇒ `PREREG4_RC=$RC_NOINFO`（`3`：不是 `0`=绿，也不是 `1`=红）。
#    【`--min-wave` = **仅覆盖口**】只许用来**抬高**射程起点（局部复核用）；
#      **禁止**用它"放低边界换取好过"（handoff 第 20 条原文），也**禁止**据此删件。
REQ_EFFECTIVE_WAVE=58
MIN_WAVE="$REQ_EFFECTIVE_WAVE"

# ── ★ `#60` W152A：**批次门禁形态** `--gate`（`verify-all` 第 `[34]` 步用；**逐件形态一字未动**）────
#   【为什么需要它】`verify-all.sh` 的 `run_step` 把**任何 `rc≠0`** 判 `❌`，而逐件形态下
#     「波次早于生效边界 ⇒ `SKIP` ⇒ `rc=3`」（W151A 定的读法，**本波逐字保留**）。
#     于是 `--glob` 扫全量时**永远** `rc=3` ⇒ 那条步**永远红** ⇒ 门禁**接不上**。
#   【口径】批次形态下，早于生效边界的件**不判**，改为**逐件点名** `PREREG4_OUT-OF-SCOPE` ＋ 计数
#     `out_of_scope=`（**永远可见，绝不静默**）。批次 `rc` 只由**违规**与**查不动**决定：
#         fail>0 ⇒ 1 ｜ noinfo>0 ⇒ 3（`NOINFO` **不算绿**，在 `verify-all` 里必须显形为"未通过"）
#         `na`／`out_of_scope` **不进 `rc`**（它们是"**适用性／射程**"声明，**不是**"我试了算不出来"）
#   【为什么这不是放宽】射程边界 `REQ_EFFECTIVE_WAVE` 是**版本受控的常量**，而 `<#58` 的件按
#     `TASK-0705` 的"**只加不改**"**永远**出射程 ⇒ 这个"不判"的集合**永不增长**、**永不包含当前波**；
#     它与 `NOINFO`（查不动）**不是一回事**。把 `SKIP` 也算进批次 `rc` ⇒ 批次**永不为 0**
#     ⇒ 门禁永远接不上 ⇒ 只会把人推向"**吞掉 rc**"（**真**假绿，比这个洞更坏）。
#   【被否决的备选】只判"当波那一份"（射程 → 1 件，明显更弱）。
GATE_MODE=0

wave_num() {
  # 从 `…/WAVE<NN>-PREREGISTRATION.md` 取 <NN>；取不到 ⇒ 空（非当波件名 ⇒ 不套用守卫）
  local b; b="$(basename "$1")"
  case "$b" in
    WAVE[0-9]*-PREREGISTRATION.md) printf '%s' "$b" | sed -n 's/^WAVE0*\([0-9][0-9]*\)-.*/\1/p' ;;
    *) printf '' ;;
  esac
}

# ── 从文件里抽出**第一个「判据」节**（含标题行；到下一个同级或更高级标题为止）
#    形态兼容 `## §3 判据（…）` / `## 3. 判据` / `### 判据节`。
extract_section() {
  awk '
    function lev(s,   n) { n = 0; while (substr(s, n + 1, 1) == "#") n++; return n }
    {
      ishead = ($0 ~ /^#+[[:space:]]/) ? 1 : 0
      if (!found && ishead && index($0, "判据") > 0) { found = 1; lv = lev($0); print; next }
      if (found) {
        if (ishead && lev($0) <= lv) exit
        print
      }
    }
  ' "$1"
}

# ── ★ `TASK-0734`／`D-G134`：`NA` 必须由**声明形态**触发（旧版是**整节正则 ∨ 令牌出现即算**
#   ⇒ 判据节里一句**散文"提及"**就能把「跳过回归判定四要件」这道门打开 = **假 N/A**）。
#   形态①（**行首锚定声明句**）：把该行**行首装饰**剥掉后必须以 `本波` 起头，且**同一行**含那句话。
#     ⇒ `⚠️ **本波（`#60`）不做任何回归判定** —— …` ✓ ／ `本节只是**讨论**了「本波不做任何回归判定」这句话…` **✗**
#   形态②（**机读行**）：行首**可带下列装饰**（**可接受装饰形态清单，逐项列全**）——
#     ① 行首/行尾**空白** ② `<!--` ③ **成对的行内代码定界符**（整行形如
#     `` `PREREG-NO-REGRESSION-DECISION: <值>` ``）④ 以上③②的**组合**（`` `<!-- PREREG-…: <值> -->` ``）——
#     之后出现 `PREREG-NO-REGRESSION-DECISION:`，且**值**（`:` 之后、去尾部 `-->`）**非空**
#     ∧ **不在否定令牌集**（`none`／`no`／`false`／`0`／`n/a`／`na`／`null`／`-`）⇒ 「写了令牌但值是 `none`」
#     **不算**声明（**值盲匹配**是同族缺陷：`WAVE63` 那行逐字写的就是 `none`）。
#     ⚠️ **`#74` W172A（`w74b`）补的正是这份"形态清单"的缺口**：**行内代码包裹**原先**不在**清单里
#     ⇒ 历史件 `docs/WAVE72-PREREGISTRATION.md:20`（整行**就是**那条机读行、只是被反引号包起来）
#     被判成"**仅提及**" ⇒ `NA → FAIL` ⇒ `verify-all` 第 `[34]` 步 `--gate` 批次 `rc=1`（本波冻不了）。
#     ⚠️ **只认成对包裹**（首尾**同时**是反引号）：**只一端**有反引号 ⇒ **不剥、不算声明**（自测 `NA-17` 钉住）；
#     包裹内的**值检查照旧**（`` `PREREG-…: none` `` 仍 `FAIL`，自测 `NA-18` 钉住）⇒ **不构成"提及即算"**。
#   ⚠️ **残余洞（如实登记）**：**行首即声明句、随后自我否定**的构造仍会被形态① 认作声明。
#      不加否定词黑名单的理由：那会误杀真声明（历史件的声明行多为长句），收益不抵风险；由主控裁定是否要更硬口径。
#   ⚠️ 本块**不消费管道 rc**（`PIPEFAIL-SIGPIPE` 牙那一族）：一律 `case`／`<<<` here-string，**无** `printf|grep -q`。
#   ★ **软／硬分档可见**（主控 `#73`/`#74` 裁定）：`form=anchor-sentence` 是**软形态**（散文声明句 ⇒ 上面的残余洞**在它身上**）
#     ⇒ 必须上屏 `residual=self-negation-not-checked`；**机读行**（`form=machine-line(…)`）是**硬形态**、**不得**出现该令牌。
#     该令牌**不进任何计数、不改 `rc`**（与 `form=` 同族：只是"凭什么判 N/A"的可见性）。
NA_PHRASE='不做任何回归判定'
NA_NEG_VALUES='none|no|false|0|n/a|na|null|-'
na_lstrip_decoration() { LC_ALL=C sed -E 's/^([[:space:]>#*|!-]|⚠️|★|⇒|§|：|[0-9]|\.)+//' ; }
na_decl_forms() {  # 读**判据节**文本（stdin）⇒ 每个"声明形态"命中印一行：`sentence` 或 `machine:<值>`
  local ln s2 v
  while IFS= read -r ln; do
    s2="$(na_lstrip_decoration <<< "$ln")"
    case "$s2" in
      本波*"$NA_PHRASE"*) printf 'sentence\n' ;;      # 形态①（`^` 锚定 ⇒ 句中提及不算）
    esac
    case "$ln" in
      *'PREREG-NO-REGRESSION-DECISION:'*)
        v="$ln"
        v="${v#"${v%%[![:space:]]*}"}"                # 去行首空白（参数展开，不用管道）
        v="${v%"${v##*[![:space:]]}"}"                # 去行尾空白（形态①的一部分）
        case "$v" in '<!--'*) v="${v#<!--}" ;; esac
        #   ★ `#74` W172A（`w74b`）：**行内代码包裹**也是可接受装饰形态之一 —— **只认成对包裹**
        #     （首尾同时是反引号）；**只一端有 ⇒ 不剥、不算声明**。散文那一支与值检查一字未动。
        case "$v" in '`'*'`') v="${v#\`}"; v="${v%\`}" ;; esac
        v="$(na_lstrip_decoration <<< "$v")"
        case "$v" in
          'PREREG-NO-REGRESSION-DECISION:'*)
            v="${v#PREREG-NO-REGRESSION-DECISION:}"; v="${v%%-->*}"
            v="${v#"${v%%[![:space:]]*}"}"; v="${v%"${v##*[![:space:]]}"}"
            v="$(tr 'A-Z' 'a-z' <<< "$v")"
            if [ -n "$v" ]; then
              case "|$NA_NEG_VALUES|" in
                *"|$v|"*) : ;;                        # 否定令牌 ⇒ **不算**声明
                *) printf 'machine:%s\n' "$v" ;;
              esac
            fi ;;
        esac ;;
    esac
  done
}

check_file() {
  local f="$1"
  local -a missing=()
  if [[ ! -f "$f" ]]; then
    echo "PREREG4=NOINFO"; echo "PREREG4_RC=$RC_NOINFO"
    echo "PREREG4_FILE file=$f state=noinfo reason=file-absent"
    echo "PREREG4_NOTE NOINFO 既不算绿也不算红（查不动）"
    return $RC_NOINFO
  fi
  if [[ ! -r "$f" ]]; then
    echo "PREREG4=NOINFO"; echo "PREREG4_RC=$RC_NOINFO"
    echo "PREREG4_FILE file=$f state=noinfo reason=file-unreadable"
    return $RC_NOINFO
  fi

  # ── 防造假红：早于生效波的**冻结历史件**一律跳过（既不判绿也不判红）
  local wn; wn="$(wave_num "$f")"
  if [[ -n "$wn" && "$wn" -lt "$MIN_WAVE" ]]; then
    echo "PREREG4=SKIP"; echo "PREREG4_RC=$RC_NOINFO"
    echo "PREREG4_SKIP file=$f wave=#${wn} reason=pre-effective(本要件对 #${MIN_WAVE} 及以后生效；TASK-0705 = 只加不改 ⇒ 早于生效代的件不许倒填)"
    echo "PREREG4_NOTE SKIP 既不算绿（PASS）也不算红（FAIL）—— **超出射程 ≠ 通过、≠ 违规**；rc=$RC_NOINFO"
    return $RC_NOINFO
  fi

  local sec
  sec="$(extract_section "$f")"
  if [[ -z "$sec" ]]; then
    echo "PREREG4=NOINFO"; echo "PREREG4_RC=$RC_NOINFO"
    echo "PREREG4_FILE file=$f state=noinfo reason=no-criteria-section(非预登记形态)"
    echo "PREREG4_NOTE NOINFO 既不算绿也不算红（找不到「判据」节 ⇒ 本牙判不了）"
    return $RC_NOINFO
  fi

  # ── ★ `#60` W152A／`TASK-0709`：识别「本波不做回归判定」的**显式声明** ⇒ 该要求降级为 `N/A`（**可见**）──
  #   充要两条（**同时**成立才是 NA）：
  #     ① **声明**（★ `TASK-0734`／`D-G134` **收紧为「声明形态」**）：**判据节内**满足下列**任一形态**才作数 ——
  #        · **行首锚定声明句**：剥掉行首装饰后**以 `本波` 起头**且**同一行**含「不做任何回归判定」；
  #      · **机读行** `PREREG-NO-REGRESSION-DECISION:`（行首可带空白／`<!--`／**成对的行内代码定界符**
  #        —— 清单见 `na_decl_forms()` 上方），且值**非空**、**非否定令牌**（`none`／空值不算）。
  #        ⚠️ **散文「提及」不算**（旧版整节正则 ∨ 令牌出现即算 ⇒ 假 N/A）；只提及会印 `PREREG4_NOTE mention-only`。
  #     ② **无证据**：**全文**不含 `REGRESSION_DECISION=`（判定工件机读行），也不含
  #        `regression-decision-cases.tsv`（＝**真的跑过判定**才会产生的台账）。
  #   ⚠️ **格式声明不算证据**：`PREREG-REGRESSION-FOUR:` 那一行只是「格式承诺」，不是「做过」的证据 ——
  #      `docs/WAVE59-PREREGISTRATION.md:47-50` **自己逐字写了**：「**是"这一刻不适用"的声明，
  #      不是"我已经做过"的声明**。**不许**把本节读成本波做过四要件。」
  #      ⇒ 若把那一行算成证据，`#59` 仍会被逼着抄四要件 ＝ **正是 `TASK-0709` 要治的病**。
  #   ⚠️ **声明不是免死金牌**：`声明 ∧ 有证据` ⇒ 四要件**仍必须齐全**，缺一照旧 `FAIL`
  #      （否则任何波都能用一句声明把整节判据关掉 ＝ **放宽**，本波明令禁止）。
  #   ⚠️ 三态口径：`N/A` = **「对，但本波不适用」**（`rc=0`）⇒ 必须与 `PASS` **分开计数**（`na=` 独立一格）、
  #      **逐件点名**；`N/A` **不许**并进 `pass=`。
  local no_rd_decl=0 rd_evidence=0 na_form="" na_seen=""
  #   ⚠️ **不许消费管道 rc**：`printf … | grep -q` 正是 `PIPEFAIL-SIGPIPE` 牙点名的形态
  #      （`HANDOFF-NEXT.md` 第 21 条：该族已咬人三次）⇒ 本处一律改用 `[[ =~ ]]`／`==` 子串匹配。
  #      `=~` 的 `.` **匹配换行**（实测：多行节文本能跨行命中，语义与原来那两处 `printf … | grep` 一致）。
  na_seen="$(na_decl_forms <<< "$sec")"
  case "$na_seen" in *'sentence'*) no_rd_decl=1; na_form='anchor-sentence' ;; esac
  if [[ $no_rd_decl -eq 0 && "$na_seen" == *'machine:'* ]]; then
    no_rd_decl=1
    na_form="machine-line($(sed -n 's/^machine://p' <<< "$na_seen" | head -1))"
  fi
  if [[ $no_rd_decl -eq 0 ]]; then
    # 「**只提及**」——**让它可见**（`D-G134` 的形态）：判据节里出现过那句话/令牌，但**没有任何声明形态**
    if grep -qF -- "$NA_PHRASE" <<< "$sec" || grep -qF -- 'PREREG-NO-REGRESSION-DECISION:' <<< "$sec"; then
      echo "PREREG4_NOTE mention-only file=$f detail=判据节里**出现过**那句话/令牌，但**没有任何声明形态**（行首锚定句 ∨ 机读行非否定值）⇒ **不判 N/A**（D-G134：提及 ≠ 声明）"
    fi
  fi
  if grep -qF -- 'REGRESSION_DECISION=' "$f" \
     || grep -qF -- 'regression-decision-cases.tsv' "$f"; then rd_evidence=1; fi
  if [[ $no_rd_decl -eq 1 && $rd_evidence -eq 0 ]]; then
    echo "PREREG4=NA"; echo "PREREG4_RC=$RC_PASS"
    echo "PREREG4_FILE file=$f state=na reason=no-regression-decision-declared requirements=N/A"
    echo "PREREG4_NA file=$f reason=no-regression-decision-declared（判据节逐字声明「本波不做任何回归判定」∧ 全文无回归判定证据 ⇒ 四要件对本波 N/A；与 PASS 分开计数） form=$na_form"
  if [[ "$na_form" == 'anchor-sentence' ]]; then
    echo "PREREG4_NA_FORM form=anchor-sentence residual=self-negation-not-checked file=$f（TASK-0734：**软形态**——N/A 由**散文声明句**授予，已知残余洞=行首即声明句、随后自我否定的构造**仍算**声明；只报不改 rc）"
  else
    echo "PREREG4_NA_FORM form=$na_form file=$f（TASK-0734：**机读行形态**（硬）⇒ **不得**带残余洞令牌；只报不改 rc）"
  fi
    return $RC_PASS
  fi
  [[ $no_rd_decl -eq 1 && $rd_evidence -eq 1 ]] && missing+=("declared-no-rd-but-has-evidence(声明了「本波不做任何回归判定」却引用了回归判定证据 ⇒ 声明不许当免死金牌，四要件仍必须齐全)")

  # ① 机器声明行，且四键全 =yes
  local decl
  decl="$(printf '%s\n' "$sec" | grep -m1 'PREREG-REGRESSION-FOUR:' || true)"
  if [[ -z "$decl" ]]; then
    missing+=("missing-machine-decl(① 判据节里没有 PREREG-REGRESSION-FOUR: 机器声明行)")
  else
    for k in same-time paired reproducibility fisher-two-tailed; do
      case "$decl" in *"${k}=yes"*) ;; *) missing+=("missing-decl-key(${k}=yes 未声明)") ;; esac
    done
    case "$decl" in *'regression-decision.py'*) ;; *) missing+=("missing-decl-tool(声明行未指名判据件 regression-decision.py)") ;; esac
  fi

  # ② 四个要件标记，**必须在判据节之内**
  [[ -n "$(printf '%s\n' "$sec" | grep -F -- "$MARK1" || true)" ]] || missing+=("missing-requirement-①(两臂同刻 未写进判据节)")
  [[ -n "$(printf '%s\n' "$sec" | grep -F -- "$MARK2" || true)" ]] || missing+=("missing-requirement-②(成对归因臂 未写进判据节)")
  [[ -n "$(printf '%s\n' "$sec" | grep -F -- "$MARK3" || true)" ]] || missing+=("missing-requirement-③(复现性 未写进判据节)")
  [[ -n "$(printf '%s\n' "$sec" | grep -F -- "$MARK4" || true)" ]] || missing+=("missing-requirement-④(Fisher 未写进判据节)")

  # ③ 判据件路径
  [[ -n "$(printf '%s\n' "$sec" | grep -F -- 'regression-decision.py' || true)" ]] || missing+=("missing-judge-ref(判据节未指名 regression-decision.py)")

  # ④ 三态词表（两个词都要在判据节里）
  [[ -n "$(printf '%s\n' "$sec" | grep -F -- 'REGRESSION' || true)" ]] || missing+=("missing-state-word(判据节没有 REGRESSION 这个词)")
  [[ -n "$(printf '%s\n' "$sec" | grep -F -- 'NOINFO' || true)" ]] || missing+=("missing-state-word(判据节没有 NOINFO 这个词)")

  # ★ 防伪绿：四要件**只在判据节之外**出现 ⇒ "讨论了但没采纳" ⇒ 必红
  local g1=0 g2=0 g3=0 g4=0
  for m in "$MARK1" "$MARK2" "$MARK3" "$MARK4"; do :; done
  grep -qF -- "$MARK1" "$f" && g1=1
  grep -qF -- "$MARK2" "$f" && g2=1
  grep -qF -- "$MARK3" "$f" && g3=1
  grep -qF -- "$MARK4" "$f" && g4=1
  local outside=0
  [[ $g1 -eq 1 && -z "$(printf '%s\n' "$sec" | grep -F -- "$MARK1" || true)" ]] && outside=1
  [[ $g2 -eq 1 && -z "$(printf '%s\n' "$sec" | grep -F -- "$MARK2" || true)" ]] && outside=1
  [[ $g3 -eq 1 && -z "$(printf '%s\n' "$sec" | grep -F -- "$MARK3" || true)" ]] && outside=1
  [[ $g4 -eq 1 && -z "$(printf '%s\n' "$sec" | grep -F -- "$MARK4" || true)" ]] && outside=1
  [[ $outside -eq 1 ]] && missing+=("discussion-only(要件只在判据节之外出现 ⇒ 讨论了但没采纳；D-G42/D-G97 同族形态)")

  if [[ ${#missing[@]} -eq 0 ]]; then
    echo "PREREG4=PASS"; echo "PREREG4_RC=$RC_PASS"
    echo "PREREG4_FILE file=$f state=pass requirements=4/4 decl=yes tool_ref=yes states=yes"
    return $RC_PASS
  fi
  echo "PREREG4=FAIL"; echo "PREREG4_RC=$RC_FAIL"
  echo "PREREG4_FILE file=$f state=fail missing=${#missing[@]}"
  for m in "${missing[@]}"; do echo "PREREG4_MISSING $m"; done
  return $RC_FAIL
}

# ─────────────────────────────────────────────────────────────────────────────
# 两极化自测
# ─────────────────────────────────────────────────────────────────────────────
GOOD_SEC='## §3 判据（落地前写死）
### 3.1 回归判定（四要件，缺一即 NOINFO）
<!-- PREREG-REGRESSION-FOUR: same-time=yes paired=yes reproducibility=yes fisher-two-tailed=yes tool=build/MilBridge/tools/regression-decision.py -->
① 两臂同刻：同一装置、同一会话、只换一个件。
② 成对归因臂：同腿旧/新交替，每趟全新进程树。
③ 复现性：旧件也要能复现该红。
④ Fisher 精确检验双尾；分母只算真尝试过的趟。
判词三态：REGRESSION ｜ NOINFO ｜ OK。判据件 = regression-decision.py。
'

# ★ `#60` W152A：`N/A` 三档反极性用的夹具（**声明 ∧ 无证据** / 删声明 / 留声明+加证据）
NA_SEC='## §3 判据（落地前写死）
### 3.1 回归判定（本波不适用）
⚠️ **本波（`#60`）不做任何回归判定** —— 本波是仪器（装置/判据）波，**没有**任何"两臂对拍得出结论"的主张。
⇒ 本条按条件句读：它声明的是「**如果**本波在别处声称做过回归判定，**那么**四件必须同时在位」——
**是"这一刻不适用"的声明，不是"我已经做过"的声明**。
'

selftest() {
  local d tot=0 pass=0 fail=0
  d="$(mktemp -d /tmp/prereg4-st.XXXXXX)" || return 1
  local -a names=(good missing-1 missing-2 missing-3 missing-4 discussion-only file-absent)
  local -a wants=(0 1 1 1 1 1 3)
  local -a newrc=()
  # good
  printf '%s\n' "$GOOD_SEC" > "$d/good.md"
  for n in 1 2 3 4; do
    case $n in
      1) sed 's/① 两臂同刻：同一装置、同一会话、只换一个件。/（本波未写这一条）/; s/same-time=yes/same-time=no/' "$d/good.md" > "$d/missing-$n.md" ;;
      2) sed 's/② 成对归因臂：同腿旧\/新交替，每趟全新进程树。/（本波未写这一条）/; s/paired=yes/paired=no/' "$d/good.md" > "$d/missing-$n.md" ;;
      3) sed 's/③ 复现性：旧件也要能复现该红。/（本波未写这一条）/; s/reproducibility=yes/reproducibility=no/' "$d/good.md" > "$d/missing-$n.md" ;;
      4) sed 's/④ Fisher 精确检验双尾；分母只算真尝试过的趟。/（本波未写这一条）/; s/fisher-two-tailed=yes/fisher-two-tailed=no/' "$d/good.md" > "$d/missing-$n.md" ;;
    esac
  done
  # discussion-only：四要件全在文件里出现，但**判据节里没有**（放在背景节）
  { printf '## §1 背景（讨论）\n本波要谈 ① 两臂同刻 ／ ② 成对归因臂 ／ ③ 复现性 ／ ④ Fisher 双尾 这四件事。\n\n'; printf '%s\n' "$GOOD_SEC" | sed 's/① 两臂同刻[^\n]*/（略）/; s/② 成对归因臂[^\n]*/（略）/; s/③ 复现性[^\n]*/（略）/; s/④ Fisher[^\n]*/（略）/'; } > "$d/discussion-only.md"
  # file-absent：不创建

  local i=0
  for name in "${names[@]}"; do
    local want="${wants[$i]}"
    local out rc
    out="$(check_file "$d/$name.md" 2>&1)"; rc=$?
    newrc+=("$rc")
    tot=$((tot+1))
    if [[ "$rc" -eq "$want" ]]; then
      pass=$((pass+1)); echo "SELFTEST $name want_rc=$want got_rc=$rc = OK"
    else
      fail=$((fail+1)); echo "SELFTEST $name want_rc=$want got_rc=$rc = FAIL"
      printf '%s\n' "$out" | sed 's/^/    /'
    fi
    i=$((i+1))
  done

  # 补齐 ⇒ 回绿（同一条路径的**往返**：把 missing-1 修回去必须 PASS）
  cp -p "$d/good.md" "$d/repair.md"
  local out rc
  out="$(check_file "$d/repair.md" 2>&1)"; rc=$?
  tot=$((tot+1))
  if [[ $rc -eq 0 ]]; then pass=$((pass+1)); echo "SELFTEST repair-back-to-green want_rc=0 got_rc=0 = OK"; else fail=$((fail+1)); echo "SELFTEST repair-back-to-green want_rc=0 got_rc=$rc = FAIL"; fi

  # ★ 防造假红：早于生效波的**冻结历史件**（连内容都缺要件）必须 **SKIP（超出射程）**、**不许判红**
  cp -p "$d/missing-1.md" "$d/WAVE54-PREREGISTRATION.md"
  out="$(check_file "$d/WAVE54-PREREGISTRATION.md" 2>&1)"; rc=$?
  tot=$((tot+1))
  if [[ $rc -eq 3 && "$out" == *'PREREG4=SKIP'* && "$out" == *'reason=pre-effective'* ]]; then
    pass=$((pass+1)); echo "SELFTEST pre-effective-skip(wave54,内容缺件但属冻结历史) want=SKIP/rc=3 got_rc=3 = OK"
  else
    fail=$((fail+1)); echo "SELFTEST pre-effective-skip(wave54) want=SKIP/rc=3 got_rc=$rc = FAIL"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi

  # ★ **`#59` 生效边界修法的主例**：`WAVE57` 正是"旧种子的一代缺口"（旧值 57 会把它真判 ⇒ 造假红）
  #   ⇒ 生效代改 58 后它**必须 SKIP**。这一例就是"今天 `WAVE57` 被判 `FAIL missing=7`"那件事的**反面**。
  cp -p "$d/missing-1.md" "$d/WAVE57-PREREGISTRATION.md"
  out="$(check_file "$d/WAVE57-PREREGISTRATION.md" 2>&1)"; rc=$?
  tot=$((tot+1))
  if [[ $rc -eq 3 && "$out" == *'PREREG4=SKIP'* && "$out" == *'reason=pre-effective'* && "$out" == *'wave=#57'* ]]; then
    pass=$((pass+1)); echo "SELFTEST wave57-now-pre-effective(旧值 57 的真红 ⇒ 改 58 后必须 SKIP) want=SKIP/rc=3 got_rc=3 = OK"
  else
    fail=$((fail+1)); echo "SELFTEST wave57-now-pre-effective want=SKIP/rc=3 got_rc=$rc = FAIL"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi

  # ★ 反向：**当波件**（内容缺件）必须**判红**（守卫不许把当波也放过）—— 且当波随生效代一起移到 `58`
  cp -p "$d/missing-1.md" "$d/WAVE58-PREREGISTRATION.md"
  out="$(check_file "$d/WAVE58-PREREGISTRATION.md" 2>&1)"; rc=$?
  tot=$((tot+1))
  if [[ $rc -eq 1 ]]; then pass=$((pass+1)); echo "SELFTEST current-wave-missing-must-fail(wave58) want_rc=1 got_rc=1 = OK"; else fail=$((fail+1)); echo "SELFTEST current-wave-missing-must-fail(wave58) want_rc=1 got_rc=$rc = FAIL"; fi

  # ★ `--min-wave` **只作覆盖口**：抬高它 ⇒ 连当波件也进 SKIP（**不改变**任何判据文本）
  out="$(MIN_WAVE=99 check_file "$d/WAVE58-PREREGISTRATION.md" 2>&1)"; rc=$?
  tot=$((tot+1))
  if [[ $rc -eq 3 && "$out" == *'reason=pre-effective'* ]]; then
    pass=$((pass+1)); echo "SELFTEST min-wave-override(抬高射程起点 ⇒ 当波也 SKIP) want=SKIP/rc=3 got_rc=3 = OK"
  else
    fail=$((fail+1)); echo "SELFTEST min-wave-override want=SKIP/rc=3 got_rc=$rc = FAIL"
  fi

  # ── ★ `#60` W152A 新增：`N/A` 三档反极性 ＋ 批次门禁形态（**只增不减**）─────────────────
  # 共用一个小工具：跑一次、比 rc、比必须/必须不出现的正则
  try() {  # try <名> <件> <期望rc> <必须出现> [<必须不出现>]
    local nm="$1" ff="$2" want="$3" must="$4" mustnot="${5:-}" o r
    o="$(check_file "$ff" 2>&1)"; r=$?
    tot=$((tot+1))
    if [[ "$r" -eq "$want" && -n "$(printf '%s\n' "$o" | grep -E "$must" || true)" ]] \
       && { [[ -z "$mustnot" ]] || [[ -z "$(printf '%s\n' "$o" | grep -E "$mustnot" || true)" ]]; }; then
      pass=$((pass+1)); echo "SELFTEST $nm want_rc=$want got_rc=$r = OK"
    else
      fail=$((fail+1)); echo "SELFTEST $nm want_rc=$want got_rc=$r must='$must' mustnot='$mustnot' = FAIL"
      printf '%s\n' "$o" | sed 's/^/    /'
    fi
  }
  # ① **不做回归判定 ∧ 显式声明** ⇒ 必须 `NA`（**不许** PASS、**不许** FAIL）
  printf '%s\n' "$NA_SEC" > "$d/no-rd-declared.md"
  try "NA-1-declared-no-rd"        "$d/no-rd-declared.md" 0 '^PREREG4=NA$' '^PREREG4=(PASS|FAIL)$'
  # ② **删掉声明**（其余不动）⇒ 既无声明、又无四要件 ⇒ 必须回到 `FAIL`
  grep -v '不做任何回归判定' "$d/no-rd-declared.md" > "$d/no-rd-nodecl.md"
  try "NA-2-decl-removed-fails"    "$d/no-rd-nodecl.md"   1 '^PREREG4=FAIL$' '^PREREG4=NA$'
  # ③ **留声明 ＋ 加上回归判定引用** ⇒ 仍必须 `FAIL`（声明不许当免死金牌）
  { cat "$d/no-rd-declared.md"; echo '<!-- REGRESSION_DECISION=REGRESSION -->'; } > "$d/no-rd-decl-evidence.md"
  try "NA-3-decl-plus-evidence-fails" "$d/no-rd-decl-evidence.md" 1 '^PREREG4=FAIL$' '^PREREG4=NA$'
  # ④ **`WAVE58` 必须仍 `PASS 4/4`**（W151A 立的口径：第一份合规件不许被降级成 NA／SKIP）
  cp -p "$d/good.md" "$d/WAVE58-PREREGISTRATION.md"
  try "NA-4-wave58-stays-pass"     "$d/WAVE58-PREREGISTRATION.md" 0 '^PREREG4=PASS$' '^PREREG4=NA$'
  # ⑤ **批次门禁形态**：出射程件**不判但点名计数**，批次 `rc` 由 fail/noinfo 决定 ⇒ 这里必须 `rc=0`
  local gout grc
  gout="$( bash "$SELF" --gate --glob "$d/WAVE*-PREREGISTRATION.md" 2>&1  )"; grc=$?
  tot=$((tot+1))
  if [[ "$grc" -eq 0 ]] && [[ -n "$(printf '%s\n' "$gout" | grep -cE '^PREREG4_OUT-OF-SCOPE ' || true)" ]] \
     && [[ -n "$(printf '%s\n' "$gout" | grep -E 'out_of_scope=[1-9]' || true)" ]]; then
    pass=$((pass+1)); echo "SELFTEST NA-5-gate-batch-form rc=0 ＋ 出射程件逐件点名 ＋ out_of_scope 计数 = OK"
  else
    fail=$((fail+1)); echo "SELFTEST NA-5-gate-batch-form want_rc=0 with out-of-scope naming = FAIL（rc=$grc）"
    printf '%s\n' "$gout" | sed 's/^/    /'
  fi
  # ⑥ 成对：同一批次里把当波件弄坏 ⇒ 批次必须 `rc=1`（证明 ⑤ 的 `rc=0` 不是恒绿）
  printf '%s\n' "$NA_SEC" | grep -v '不做任何回归判定' > "$d/WAVE58-PREREGISTRATION.md"
  gout="$( bash "$SELF" --gate --glob "$d/WAVE*-PREREGISTRATION.md" 2>&1  )"; grc=$?
  tot=$((tot+1))
  if [[ "$grc" -eq 1 ]]; then
    pass=$((pass+1)); echo "SELFTEST NA-6-gate-batch-fails-when-broken rc=1 = OK"
  else
    fail=$((fail+1)); echo "SELFTEST NA-6-gate-batch-fails-when-broken want_rc=1 got_rc=$grc = FAIL"
  fi

  # ── ★ `TASK-0734`／`D-G134` 新增：`NA` 的**声明形态**三极化（**只增不减**；上面 `NA-1`…`NA-6` 一字未动）──
  #   ① **仅提及**（四要件一件没有）⇒ **必须不再 `NA`**
  printf '## §3 判据（落地前写死）\n\n本节只是**讨论**了「本波不做任何回归判定」这句话该不该写在这里，**没有**采纳任何东西。\n' > "$d/mention-only.md"
  try "NA-7-mention-only-must-fail" "$d/mention-only.md" 1 '^PREREG4=FAIL$' '^PREREG4=NA$'
  #   ① b **句中提及令牌**（不是行首机读行）⇒ 同样不许 `NA`
  printf '## §3 判据（落地前写死）\n\n本节的写法参照（或机读行 PREREG-NO-REGRESSION-DECISION: xxx 的）历史惯例，**不采纳**。\n' > "$d/mention-token.md"
  try "NA-8-mention-token-midline-must-fail" "$d/mention-token.md" 1 '^PREREG4=FAIL$' '^PREREG4=NA$'
  #   ② **行首锚定声明句**：历史**九形态**逐种各造一份 ⇒ 每种都必须 `NA`
  local -a shapes=( '## §3 判据|### §9 本波不做任何回归判定' '## §3 判据|### 9. 本波不做任何回归判定'
                    '## §3 判据|### 9.9 本波不做任何回归判定' '## §3 判据|**本波不做任何回归判定**'
                    '## §3 判据|- 本波不做任何回归判定' '## §3 判据|> **本波不做任何回归判定**'
                    '## §3 判据|⇒ **本波不做任何回归判定**' '## §3 判据|| 本波不做任何回归判定'
                    '## §3 判据|⚠️ **本波（`#99`）不做任何回归判定**' )
  local sh_ok=0 sh_bad="" ent hd bd
  for ent in "${shapes[@]}"; do
    hd="${ent%%|*}"; bd="${ent#*|}"
    printf '%s\n%s\n' "$hd" "$bd" > "$d/shape.md"
    out="$(check_file "$d/shape.md" 2>&1)"; rc=$?
    if [[ $rc -eq 0 && "$out" == *'PREREG4=NA'* ]]; then sh_ok=$((sh_ok+1)); else sh_bad="$sh_bad[${bd:0:18}]"; fi
  done
  tot=$((tot+1))
  if [[ $sh_ok -eq ${#shapes[@]} ]]; then
    pass=$((pass+1)); echo "SELFTEST NA-9-anchored-shapes($sh_ok/${#shapes[@]}) 九种行首形态都判 NA = OK"
  else
    fail=$((fail+1)); echo "SELFTEST NA-9-anchored-shapes 只有 $sh_ok/${#shapes[@]} 判 NA；未过=$sh_bad = FAIL"
  fi
  #   ② b **节边界（既有语义，本波未改）**：与判据标题**同级**的标题会**终止** `extract_section`
  #       ⇒ 写在那之后的声明句**在节外**、不算 ⇒ 必须 `FAIL`（**这一格把边界变成可判读数**，防将来静默变化）
  printf '## §3 判据（落地前写死）\n\n本文没有声明。\n\n## §9 本波不做任何回归判定\n' > "$d/samelevel.md"
  try "NA-9b-same-level-heading-ends-section" "$d/samelevel.md" 1 '^PREREG4=FAIL$' '^PREREG4=NA$'
  #   ② c **机读行**（正值）⇒ `NA`
  printf '## §3 判据（落地前写死）\n\nPREREG-NO-REGRESSION-DECISION: yes\n' > "$d/mach-yes.md"
  try "NA-10-machine-line-yes" "$d/mach-yes.md" 0 '^PREREG4=NA$' '^PREREG4=(PASS|FAIL)$'
  #   ③ **值盲令牌修正**：值 `none` ／ **空值** ⇒ **不算**声明 ⇒ 回去 `FAIL`
  printf '## §3 判据（落地前写死）\n\n<!-- PREREG-NO-REGRESSION-DECISION: none -->\n' > "$d/mach-none.md"
  try "NA-11-machine-line-none-is-not-decl" "$d/mach-none.md" 1 '^PREREG4=FAIL$' '^PREREG4=NA$'
  printf '## §3 判据（落地前写死）\n\nPREREG-NO-REGRESSION-DECISION:\n' > "$d/mach-empty.md"
  try "NA-12-machine-line-empty-is-not-decl" "$d/mach-empty.md" 1 '^PREREG4=FAIL$' '^PREREG4=NA$'
  #   ③ b **声明 ∧ 证据**（机读行正值那一支）⇒ 仍 `FAIL` 且点名 `declared-no-rd-but-has-evidence`
  { printf '## §3 判据（落地前写死）\n\nPREREG-NO-REGRESSION-DECISION: yes\n'; echo '<!-- REGRESSION_DECISION=REGRESSION -->'; } > "$d/mach-plus-evidence.md"
  try "NA-13-machine-decl-plus-evidence-fails" "$d/mach-plus-evidence.md" 1 'declared-no-rd-but-has-evidence' '^PREREG4=NA$'

  #   ③ c ★ `#74` W172A（`w74b`）：**成对行内代码包裹**的机读行 ⇒ **是声明** ⇒ `NA`
  #      （现场＝`docs/WAVE72-PREREGISTRATION.md:20`；漏剥这对反引号 ⇒ 历史件 `NA→FAIL` ⇒ `[34]` 步批次红）
  printf '## §3 判据（落地前写死）\n\n`PREREG-NO-REGRESSION-DECISION: yes`\n' > "$d/mach-backtick.md"
  try "NA-15-backtick-paired-machine-line-is-decl" "$d/mach-backtick.md" 0 '^PREREG4=NA$' '^PREREG4=(PASS|FAIL)$'
  #   ③ d **反极 1**：反引号包的是**句中提及**（令牌不在行首）⇒ **仍必须 `FAIL`**
  printf '## §3 判据（落地前写死）\n\n参见 `PREREG-NO-REGRESSION-DECISION: yes` 的历史写法，本节不采纳。\n' > "$d/mach-backtick-mention.md"
  try "NA-16-backtick-wrapped-mention-still-fails" "$d/mach-backtick-mention.md" 1 '^PREREG4=FAIL$' '^PREREG4=NA$'
  #   ③ e **反极 2（"成对"这一条本身）**：**只一端**有反引号 ⇒ 不剥 ⇒ **`FAIL`**
  printf '## §3 判据（落地前写死）\n\n`PREREG-NO-REGRESSION-DECISION: yes\n' > "$d/mach-backtick-oneend.md"
  try "NA-17-backtick-one-end-only-is-not-decl" "$d/mach-backtick-oneend.md" 1 '^PREREG4=FAIL$' '^PREREG4=NA$'
  #   ③ f **反极 3（值检查不被包裹绕过）**：`` `PREREG-…: none` `` ⇒ **`FAIL`**
  printf '## §3 判据（落地前写死）\n\n`PREREG-NO-REGRESSION-DECISION: none`\n' > "$d/mach-backtick-none.md"
  try "NA-18-backtick-wrapped-none-still-fails" "$d/mach-backtick-none.md" 1 '^PREREG4=FAIL$' '^PREREG4=NA$'

  #   ④ **软／硬分档可见性**（主控裁定）：锚定句（软）⇒ `residual=self-negation-not-checked` **必在**；机读行（硬）⇒ **必不出现**
  printf '## §3 判据（落地前写死）\n\n⚠️ **本波（`#99`）不做任何回归判定** —— 仪器波。\n' > "$d/soft-form.md"
  local soft_out hard_out s_ok=0 h_ok=0
  soft_out="$(check_file "$d/soft-form.md" 2>&1)"
  hard_out="$(check_file "$d/mach-yes.md" 2>&1)"
  [[ "$soft_out" == *'PREREG4_NA_FORM form=anchor-sentence residual=self-negation-not-checked'* ]] && s_ok=1
  if [[ "$hard_out" == *'PREREG4_NA_FORM'* && "$hard_out" != *'residual=self-negation-not-checked'* ]]; then h_ok=1; fi
  tot=$((tot+1))
  if [[ $s_ok -eq 1 && $h_ok -eq 1 ]]; then
    pass=$((pass+1)); echo "SELFTEST NA-14-soft-vs-hard-form-marking 软=带 residual 令牌 ∧ 硬=不带 = OK"
  else
    fail=$((fail+1)); echo "SELFTEST NA-14-soft-vs-hard-form-marking 软令牌在=$s_ok 硬令牌失=$h_ok = FAIL"
    printf '%s\n' "$soft_out" "$hard_out" | sed 's/^/    /'
  fi

  rm -rf "$d"
  echo "PREREG4_SELFTEST_ROSTER cases=$tot pass=$pass fail=$fail"
  if [[ $fail -eq 0 ]]; then echo "PREREG4_SELFTEST=PASS total=$tot pass=$pass fail=$fail"; return 0; fi
  echo "PREREG4_SELFTEST=FAIL total=$tot pass=$pass fail=$fail"; return 1
}

# ─────────────────────────────────────────────────────────────────────────────
main() {
  local -a files=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --selftest) selftest; return $? ;;
      --min-wave) MIN_WAVE="${2:-$REQ_EFFECTIVE_WAVE}"; shift 2 ;;
      --gate) GATE_MODE=1; shift ;;
      --glob) for g in ${2:-}; do files+=("$g"); done; shift 2 ;;
      -h|--help) echo "用法: bash $SELF <预登记件> [<…>] | --selftest | --glob '<glob>' [--min-wave N] [--gate]"; return $RC_PASS ;;
      *) files+=("$1"); shift ;;
    esac
  done
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "用法: bash $SELF <预登记件> [<…>] | --selftest | --glob '<glob>' [--min-wave N] [--gate]"
    echo "PREREG4=NOINFO"; echo "PREREG4_RC=$RC_NOINFO"
    echo "PREREG4_NOTE 没给件 ⇒ NOINFO（既不算绿也不算红）"
    return $RC_NOINFO
  fi
  local any=0 worst=0 n_pass=0 n_fail=0 n_skip=0 n_noinfo=0 n_na=0 n_oos=0
  # ★ `#63` W152A／`D-G117` 半①：批次形态下**逐件输出先缓冲**，末尾把「批次判词行」印在**最前面**
  #   —— 那一行形如 `PREREG4=<批次判词> files=… pass=… fail=… na=… noinfo=… out_of_scope=…`，
  #   **逐字匹配** `verify-all.sh` 的自报口径抽取正则（`^[A-Z][A-Z0-9_]*=(PASS|FAIL|NOINFO)( |$)`）
  #   ⇒ 屏上立刻带上**四态计数**（修前：只有 `PREREG4=PASS` 上屏，`na=`/`out_of_scope=` 全被吃掉）。
  #   ⚠️ **零语义改动**：判定/`rc` 的口径一字未动，只是把一句已经算得出来的话**搬到能被显示层看见的位置**。
  local buf=""
  for f in "${files[@]}"; do
    # ★ 批次门禁形态：早于生效边界的件**不判**，但**逐件点名 ＋ 计数**（"没判什么"永远可见）
    if [[ $GATE_MODE -eq 1 ]]; then
      local wn0; wn0="$(wave_num "$f")"
      if [[ -n "$wn0" && "$wn0" -lt "$MIN_WAVE" ]]; then
        buf="${buf}PREREG4_OUT-OF-SCOPE file=$f wave=#${wn0} reason=pre-effective(<#${MIN_WAVE})（超出射程 ⇒ 本趟不判；它**不是**违规、也**不是**通过）
"
        n_oos=$((n_oos+1)); continue
      fi
    fi
    local out rc; out="$(check_file "$f" 2>&1)"; rc=$?
    buf="${buf}${out}
"
    # 【`#59` 生效边界修法】四态**分开计数**：`SKIP`（超出射程）**不许**并进 `PASS`、也**不许**并进 `FAIL`
    case "$(printf '%s\n' "$out" | sed -n 's/^PREREG4=\([A-Z]*\)$/\1/p' | head -1)" in
      PASS) n_pass=$((n_pass+1)) ;;
      FAIL) n_fail=$((n_fail+1)) ;;
      SKIP) n_skip=$((n_skip+1)) ;;
      NA)   n_na=$((n_na+1)) ;;            # ★ 显式声明「不做回归判定」⇒ 独立格，**不许**并进 pass
      *)    n_noinfo=$((n_noinfo+1)) ;;
    esac
    [[ $rc -ne 0 ]] && any=1
    [[ $rc -eq 1 ]] && worst=1
  done
  # ★ `D-G114` 现场物（`#60` W152A 修）：旧行在双引号里写了 "反引号 SKIP 反引号" ⇒ bash **真的**做命令替换
  #   ⇒ stderr 每趟多一行 `prereg-four-requirements-check.sh: 行 313: SKIP: 未找到命令`、且汇总行里
  #   "SKIP" 那几个字**消失**（与 quote-trap 牙自己记录的第 ③ 条血案同形）。改用直角引号，语义不变。
  # ★ `D-G117` 半①：批次判词行**先印**（只在批次门禁形态；逐件形态一字不变）
  if [[ $GATE_MODE -eq 1 ]]; then
    local bv="PASS"
    if [[ $n_fail -gt 0 ]]; then bv="FAIL"
    elif [[ $n_noinfo -gt 0 ]]; then bv="NOINFO"; fi
    echo "PREREG4=$bv files=${#files[@]} pass=$n_pass fail=$n_fail na=$n_na skip=$n_skip noinfo=$n_noinfo out_of_scope=$n_oos min_wave=#$MIN_WAVE（**批次门禁形态的判词**：出射程件逐件点名、**不进 rc**；na 与 pass 分开计数）"
  fi
  printf '%s' "$buf"
  echo "PREREG4_SUMMARY files=${#files[@]} pass=$n_pass fail=$n_fail na=$n_na skip=$n_skip noinfo=$n_noinfo out_of_scope=$n_oos min_wave=#$MIN_WAVE（**五态分开计数**：PASS／NA／SKIP／NOINFO／OUT-OF-SCOPE 各自独立——NA = 显式声明「本波不做回归判定」⇒ 该要求对本波不适用，**既不是 PASS 也不是违规**；SKIP = 波次早于生效边界；OUT-OF-SCOPE 只在批次门禁形态出现）"
  if [[ $worst -eq 1 ]]; then return $RC_FAIL; fi
  if [[ $GATE_MODE -eq 1 ]]; then
    # 批次门禁形态：`na`／`out_of_scope` 是"适用性／射程"声明 ⇒ **不进 rc**；`noinfo` **必须**进（不算绿）
    if [[ $n_noinfo -gt 0 ]]; then return $RC_NOINFO; fi
    return $RC_PASS
  fi
  if [[ $any -eq 1 ]]; then return $RC_NOINFO; fi
  return $RC_PASS
}

main "$@"

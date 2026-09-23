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

# ── 生效波次（**防造假红**）：本要件**只对 `#57` 及以后的新波生效**
#    （`TASK-0705` 的纪律 = "不许倒填进既有冻结件来美化历史判词"）。
#    现场机械证：不加这道守卫时，`docs/WAVE*-PREREGISTRATION.md` **37 件里 35 件会红**
#    （含当波 `#56`）—— 那是"**拿新规则审判历史件**"，是**造假红**，不是缺陷。
#    ⇒ 早于生效波的件**一律 `NOINFO reason=history-frozen-before-requirement`**（跳过、逐件可见）。
REQ_EFFECTIVE_WAVE=57
MIN_WAVE="$REQ_EFFECTIVE_WAVE"

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
    echo "PREREG4=NOINFO"; echo "PREREG4_RC=$RC_NOINFO"
    echo "PREREG4_SKIP file=$f wave=#${wn} reason=history-frozen-before-requirement(本要件对 #${MIN_WAVE} 及以后生效；TASK-0705 = 只加不改)"
    echo "PREREG4_NOTE NOINFO 既不算绿也不算红（跳过，不是绿也不是红）"
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

  # ★ 防造假红：早于生效波的**冻结历史件**（连内容都缺要件）必须 **NOINFO（跳过）**、**不许判红**
  cp -p "$d/missing-1.md" "$d/WAVE54-PREREGISTRATION.md"
  out="$(check_file "$d/WAVE54-PREREGISTRATION.md" 2>&1)"; rc=$?
  tot=$((tot+1))
  if [[ $rc -eq 3 && "$out" == *'history-frozen-before-requirement'* ]]; then
    pass=$((pass+1)); echo "SELFTEST history-frozen-skip(内容缺件但属冻结历史) want_rc=3 got_rc=3 = OK"
  else
    fail=$((fail+1)); echo "SELFTEST history-frozen-skip(内容缺件但属冻结历史) want_rc=3 got_rc=$rc = FAIL"
    printf '%s\n' "$out" | sed 's/^/    /'
  fi

  # ★ 反向：**当波件**（内容缺件）必须**判红**（守卫不许把当波也放过）
  cp -p "$d/missing-1.md" "$d/WAVE57-PREREGISTRATION.md"
  out="$(check_file "$d/WAVE57-PREREGISTRATION.md" 2>&1)"; rc=$?
  tot=$((tot+1))
  if [[ $rc -eq 1 ]]; then pass=$((pass+1)); echo "SELFTEST current-wave-missing-must-fail want_rc=1 got_rc=1 = OK"; else fail=$((fail+1)); echo "SELFTEST current-wave-missing-must-fail want_rc=1 got_rc=$rc = FAIL"; fi

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
      --glob) for g in ${2:-}; do files+=("$g"); done; shift 2 ;;
      -h|--help) echo "用法: bash $SELF <预登记件> [<…>] | --selftest | --glob '<glob>' [--min-wave N]"; return $RC_PASS ;;
      *) files+=("$1"); shift ;;
    esac
  done
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "用法: bash $SELF <预登记件> [<…>] | --selftest | --glob '<glob>' [--min-wave N]"
    echo "PREREG4=NOINFO"; echo "PREREG4_RC=$RC_NOINFO"
    echo "PREREG4_NOTE 没给件 ⇒ NOINFO（既不算绿也不算红）"
    return $RC_NOINFO
  fi
  local any=0 worst=0
  for f in "${files[@]}"; do
    local out rc; out="$(check_file "$f" 2>&1)"; rc=$?
    printf '%s\n' "$out"
    [[ $rc -ne 0 ]] && any=1
    [[ $rc -eq 1 ]] && worst=1
  done
  if [[ $worst -eq 1 ]]; then return $RC_FAIL; fi
  if [[ $any -eq 1 ]]; then return $RC_NOINFO; fi
  return $RC_PASS
}

main "$@"

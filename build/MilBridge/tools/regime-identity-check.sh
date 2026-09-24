#!/usr/bin/env bash
# regime-identity-check.sh —— 「**跨臂体制同一性**」的牙（`D-G116` 的落地；波 `#63`／车道 W152A）
#
# ═══════════════════════════════════════════════════════════════════════════════
# 【它防什么】**把"可比性/有效性"当默认，而不是当待证项。** 现场（`D-G116`）：对照臂换了体制
#   （装饰/几何/最大化与否）⇒ 两臂量的是**不同现象**，却照样进同一个 Fisher 表 ⇒ 结论无效。
#
# 【判据（三态）】**0 = PASS**｜**1 = FAIL**｜**2 = NOINFO**（**不是绿**，纪律 21/27/28 同族）。
#   `REGIME_IDENTITY=PASS`   ⟸ 输入可用 ∧ 每个「**≥2 臂**」的 pair 里**全部腿**的**体制四列**
#                              （`BASE`／`MAXGEOM`／`START_MAX`／`m_ok`）**逐项相同** ∧ 无「单格判红」违规。
#   `REGIME_IDENTITY=FAIL`   ⟸ ① 任一多臂 pair 体制不等 ⇒ 标 `INCOMPARABLE` ＋ **逐腿点名**；
#                              ② 任一腿违反「**判红 = 四件合取**」。
#   `REGIME_IDENTITY=NOINFO` ⟸ 语料目录不存在／**空台账**／**任一体制列缺失**／
#                              **没有任何「≥2 臂」的 pair**（无跨臂可比性 ⇒ 判不了，不许当绿）。
#
# 【体制列 = **输入侧四列**；结果侧**不是体制**】★ 本件最容易搞错的一格，逐字写死：
#   体制（**判用**）：`BASE`（T0 基准几何）｜`MAXGEOM`（`AFTER_M1` 的 geom）｜`START_MAX`｜`m_ok`
#   结果（**只作诊断** `REGIME_OUTCOME_DIAG=`，**不进 `rc`**）：`AFTER_R2` 的 geom／`r_ok`／`r_ok2`／
#     `fgeom`（`AFTER_R2_SETTLED` 的 frame 几何）／`frame`／`CFG_HIT`／`GEOWRITE`
#   **为什么**：结果侧与被试项**同向**。实测（现盘 39 腿 / 6 pair）：`fgeom` 与 `r_ok2` **39/39 同向**
#     （修后臂 `800x600@+0+0 ∧ r_ok2=1`；修前臂 `1280x1024@+0+0 ∧ r_ok2=0`）。
#     把结果算进体制 ⇒ **A1／POL2（唯一的两个多臂 pair）全部被判不可比** ⇒
#     这条牙就**用「保护可比性」的名义否掉可比性**，并在现树恒 `FAIL`。
#     ⇒ **口径句**：「**把结果算进体制，等于用『保护可比性』的名义否掉可比性。**」
#   ⚠️ 诊断**不等于不显示**：`REGIME_OUTCOME_DIAG` 逐项照印（差异照样可见），只是**不进 `rc`**。
#
# 【判红 = 四件合取】`RED ⟸ START_MAX=0 ∧ m_ok=1 ∧ r_ok2=0 ∧ APP_ALIVE=yes`
#   单看 `r_ok2=0` 会把「**从没被最大化过**」（`START_MAX=1`）与「**应用已死**」读成红。
#   `APP_ALIVE` 的**声明式派生**（现台账不记录显式存活性）：该腿 `probe.txt` 里
#     `RESULT` 行 ∧ `AFTER_R2_SETTLED` 行 ∧ `DONE` 行 **三条都在** ⇒ `yes`；缺任一 ⇒ `no`。
#   违规（⇒ `FAIL`）⟸ 某腿 `r_ok2=0` 却不满足上列任一条件 ⇒ 逐腿点名 `REGIME_RED_VIOLATION`。
#
# 【射程缺口（如实登记）】`frame-at-base`（**T0 的装饰/框架几何**）现台账**不记录**
#   （实测：`fgeom` 只出现在 `AFTER_R2_SETTLED` 那一行）⇒ 本件打
#   `REGIME_NOT_IN_LEDGER frame-at-base …` ＋ `REGIME_UNCHECKED=1` ⇒ **顶上不冒充"装饰也查过了"**。
#   ⚠️ 「缺列 ⇒ `NOINFO`」那一档**只对体制四列**生效；`frame-at-base` 是**已知射程缺口**
#   （不是畸形输入）⇒ 可见、进计数、**不拉红**。
#
# 【用法】bash regime-identity-check.sh [--corpus=DIR] ｜ --selftest
#   默认语料 = 仓内 `build/MilBridge/geom-corpus`。纯读、零 `dotnet`、秒级。
# ═══════════════════════════════════════════════════════════════════════════════

set -uo pipefail

SELF="${BASH_SOURCE[0]}"
RC_PASS=0; RC_FAIL=1; RC_NOINFO=2
CORPUS=""
SELFTEST=0

while [ $# -gt 0 ]; do
  case "$1" in
    --corpus)   CORPUS="${2:-}"; shift 2 ;;
    --corpus=*) CORPUS="${1#*=}"; shift ;;
    --selftest) SELFTEST=1; shift ;;
    -h|--help)  echo "用法: bash $SELF [--corpus=DIR] | --selftest"; exit 0 ;;
    *) echo "REGIME_IDENTITY=NOINFO reason=bad-usage arg=$1" >&2; exit 2 ;;
  esac
done

# ── 核心（python3；只读；**空集/缺列一律响亮失败** —— 禁静默判等）────────────────────
run_core() {   # run_core <corpus-root>
  local pyf rc
  pyf="$(mktemp "${TMPDIR:-/tmp}/regime-core.XXXXXX.py")" || return 2
  cat > "$pyf" <<'PYCORE'
import os, re, sys, glob

root = sys.argv[1]
IN_COLS = ("BASE", "MAXGEOM", "START_MAX", "m_ok")          # 体制（输入侧）
OUT_COLS = ("r_ok2", "fgeom", "afterR_geom")                # 结果侧（只诊断，不进 rc）

def die(msg, extra=()):
    print("REGIME_IDENTITY=NOINFO reason=%s" % msg)
    for e in extra:
        print("REGIME_DETAIL %s" % e)
    sys.exit(2)

if not os.path.isdir(root):
    die("corpus-absent root=%s" % root)

legs = []
for d in sorted(glob.glob(os.path.join(root, "*"))):
    if not os.path.isdir(d):
        continue
    f = os.path.join(d, "probe.txt")
    if not os.path.isfile(f):
        continue
    tag = os.path.basename(d)
    parts = tag.split("-")
    leg = (parts[-3], parts[-2]) if len(parts) >= 3 else None
    s = open(f, encoding="utf-8", errors="replace").read()
    def g(pat):
        m = re.search(pat, s, re.M)
        return m.group(1) if m else None
    rec = dict(
        tag=tag, pair=(leg[0] if leg else None), arm=(leg[1] if leg else None),
        BASE=g(r"BASE=(\S+)"),
        MAXGEOM=g(r"^AFTER_M1 .*?geom=(\S+)"),
        START_MAX=g(r"START_MAX=(\d+)"),
        m_ok=g(r"m_ok=(\d+)"),
        r_ok2=g(r"r_ok2=(\d+)"),
        fgeom=g(r"^AFTER_R2_SETTLED .*?fgeom=(\S+)"),
        afterR_geom=g(r"^AFTER_R2 .*?geom=(\S+)"),
        has_result=1 if re.search(r"^RESULT ", s, re.M) else 0,
        has_settled=1 if re.search(r"^AFTER_R2_SETTLED ", s, re.M) else 0,
        has_done=1 if re.search(r"^DONE ", s, re.M) else 0,
    )
    rec["APP_ALIVE"] = "yes" if (rec["has_result"] and rec["has_settled"] and rec["has_done"]) else "no"
    legs.append(rec)

if not legs:
    die("empty-ledger root=%s（**空集不许判等**：既不是 PASS 也不是 FAIL）" % root)

missing = sorted({c for c in IN_COLS for r in legs if r[c] is None})
if missing:
    die("column-missing cols=%s（体制列缺 ⇒ 本件判不了；**缺列 != 通过**）" % ",".join(missing),
        ["leg=%s col=%s" % (r["tag"], c) for c in missing for r in legs if r[c] is None][:8])

noleg = [r["tag"] for r in legs if r["pair"] is None or r["arm"] is None]
if noleg:
    die("leg-name-unparsable n=%d sample=%s" % (len(noleg), noleg[0]))

for r in legs:
    print("REGIME_LEG tag=%s pair=%s arm=%s BASE=%s MAXGEOM=%s START_MAX=%s m_ok=%s r_ok2=%s APP_ALIVE=%s"
          % (r["tag"], r["pair"], r["arm"], r["BASE"], r["MAXGEOM"], r["START_MAX"], r["m_ok"], r["r_ok2"], r["APP_ALIVE"]))

by_pair = {}
for r in legs:
    by_pair.setdefault(r["pair"], []).append(r)

fails = []
multi = 0
incomparable = 0
for pair in sorted(by_pair):
    rs = by_pair[pair]
    arms = sorted({r["arm"] for r in rs})
    if len(arms) < 2:
        print("REGIME_PAIR pair=%s arms=%s legs=%d state=SINGLE-ARM（无可比臂 ⇒ 本件对它不判）"
              % (pair, ",".join(arms), len(rs)))
        continue
    multi += 1
    bad = []
    for c in IN_COLS:
        vals = sorted({r[c] for r in rs})
        if len(vals) > 1:
            bad.append((c, vals))
            for r in rs:
                print("REGIME_INCOMPARABLE pair=%s col=%s leg=%s arm=%s value=%s"
                      % (pair, c, r["tag"], r["arm"], r[c]))
    print("REGIME_PAIR pair=%s arms=%s legs=%d state=%s"
          % (pair, ",".join(arms), len(rs), "INCOMPARABLE" if bad else "COMPARABLE"))
    if bad:
        incomparable += 1
        fails.append("incomparable-pair(%s)" % pair)

if multi == 0:
    die("no-multi-arm-pair legs=%d pairs=%d（没有任何 >=2 臂的 pair ⇒ 跨臂可比性判不了，不许当绿）"
        % (len(legs), len(by_pair)))

for c in OUT_COLS:
    for pair in sorted(by_pair):
        rs = by_pair[pair]
        if len({r["arm"] for r in rs}) < 2:
            continue
        vals = sorted({str(r[c]) for r in rs})
        if len(vals) > 1:
            print("REGIME_OUTCOME_DIAG pair=%s col=%s values=%s（结果侧、与被试项同向 ⇒ 不得进体制 ⇒ 不进 rc）"
                  % (pair, c, ",".join(vals)))

print("REGIME_NOT_IN_LEDGER frame-at-base reason=probe-no-T0-decoration-geom（已知射程缺口：本件不判装饰同一性）")
print("REGIME_UNCHECKED=1 frame-at-base")

red = 0
viol = 0
for r in legs:
    is_red = (r["START_MAX"] == "0") and (r["m_ok"] == "1") and (r["r_ok2"] == "0") and (r["APP_ALIVE"] == "yes")
    if is_red:
        red += 1
    if r["r_ok2"] == "0" and not is_red:
        viol += 1
        why = []
        if r["START_MAX"] != "0": why.append("START_MAX=%s" % r["START_MAX"])
        if r["m_ok"] != "1":      why.append("m_ok=%s" % r["m_ok"])
        if r["APP_ALIVE"] != "yes": why.append("APP_ALIVE=no")
        print("REGIME_RED_VIOLATION leg=%s reason=single-cell-red(r_ok2=0 但 %s ⇒ 那是退化/死腿，不是红)"
              % (r["tag"], " and ".join(why)))
        fails.append("single-cell-red(%s)" % r["tag"])
print("REGIME_RED_COUNTS legs=%d red=%d red_violations=%d" % (len(legs), red, viol))

verdict = "FAIL" if fails else "PASS"
print("REGIME_IDENTITY=%s reason=%s legs=%d pairs=%d multi_arm_pairs=%d incomparable=%d red=%d red_violations=%d unchecked=1"
      % (verdict, (";".join(fails) if fails else "ok"), len(legs), len(by_pair), multi, incomparable, red, viol))
sys.exit(1 if fails else 0)
PYCORE
  python3 "$pyf" "$1"
  rc=$?
  rm -f "$pyf"
  return $rc
}

# ─────────────────────────────────────────────────────────────────────────────
# 两极化自测（自带夹具；`$HOME`/`${TMPDIR}` 沙箱，**不碰仓内任何件**）
# ─────────────────────────────────────────────────────────────────────────────
mkleg() {  # mkleg <root> <tag> <BASE> <MAXGEOM> <START_MAX> <m_ok> <r_ok2> <FGEOM> <alive:1|0>
  local root="$1" tag="$2" base="$3" mg="$4" sm="$5" mo="$6" r2="$7" fg="$8" alive="$9"
  mkdir -p "$root/$tag"
  {
    printf 'TAG=%s M=M1 R=R2 LANE=W152A started=2026-09-24 00:00:00\n' "$tag"
    printf 'DISPLAY=:221 SCREEN=1280x1024 WM=xfwm4\n'
    printf 'T0 window=12582916 WARM=6.5s BASE geom=%s state=[_NET_WM_STATE_FOCUSED] START_MAX=%s client=0,0 800x600\n' "$base" "$sm"
    printf 'AFTER_M1 state=[_NET_WM_STATE_MAXIMIZED_HORZ] geom=%s m_ok=%s mapstate=IsViewable\n' "$mg" "$mo"
    printf 'AFTER_R2 state=[_NET_WM_STATE_FOCUSED] geom=%s r_ok=%s (BASE=%s MAX=%s)\n' "$fg" "$r2" "$base" "$mg"
    printf 'AFTER_R2_SETTLED state=[_NET_WM_STATE_FOCUSED] geom=%s r_ok2=%s (BASE=%s) frame=0x200480 fgeom=%s\n' "$fg" "$r2" "$base" "$fg"
    [ "$alive" = "1" ] && { printf 'RESULT tag=%s START_MAX=%s BASE=%s m_ok=%s r_ok2=%s\n' "$tag" "$sm" "$base" "$mo" "$r2"; printf 'DONE 2026-09-24 00:00:10\n'; }
  } > "$root/$tag/probe.txt"
}

run_selftest() {
  local sb; sb="$(mktemp -d "${TMPDIR:-/tmp}/regime-st.XXXXXX")" || return 1
  local tot=0 pass=0 fail=0 rc
  # **逐行** ERE 匹配（`grep -qE` 的等价物，但**不建管道** —— 避开 `PIPEFAIL-SIGPIPE` 那一族）
  line_match() {
    local txt="$1" pat="$2" ln
    while IFS= read -r ln; do [[ "$ln" =~ $pat ]] && return 0; done <<< "$txt"
    return 1
  }
  chk() {  # chk <名> <期望rc> <根> <必须出现正则> [<必须不出现正则>]
    local nm="$1" want="$2" root="$3" must="$4" mustnot="${5:-}" out
    out="$(run_core "$root" 2>&1)"; rc=$?
    tot=$((tot+1))
    local ok=1
    [ "$rc" = "$want" ] || ok=0
    # ⚠️ **不消费管道 rc**（`PIPEFAIL-SIGPIPE` 牙点名的形态：`printf … | grep -q` 在管道左侧被提前
    #   关掉时会拿到 SIGPIPE）⇒ 改用 `line_match`（**逐行** `[[ =~ ]]` ＋ here-string，**零管道**）。
    #   ⚠️ 不许直接 `[[ "$out" =~ $pat ]]`：那是**整串**匹配，`^`/`$` 只在**整串**首尾生效
    #      ⇒ 多行输出里的 `^REGIME_IDENTITY=PASS` 永远匹配不到（本件自测当场抓到 2 例）。
    [ -z "$must" ] || line_match "$out" "$must" || ok=0
    if [ -n "$mustnot" ]; then line_match "$out" "$mustnot" && ok=0; fi
    if [ "$ok" = 1 ]; then pass=$((pass+1)); echo "SELFTEST CASE $nm = PASS rc=$rc";
    else fail=$((fail+1)); echo "SELFTEST CASE $nm = FAIL rc=$rc want=$want must='$must' mustnot='$mustnot'"; printf '%s\n' "$out" | sed 's/^/      | /'; fi
  }

  # ① 同体制（两臂四列逐项相同）⇒ PASS
  local d1="$sb/good"; mkleg "$d1" W1-P1-A-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 1 '800x600@+0+0' 1
  mkleg "$d1" W1-P1-B-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 0 '1280x1024@+0+0' 1
  chk "S1-same-regime-PASS" 0 "$d1" '^REGIME_IDENTITY=PASS' '^REGIME_IDENTITY=(FAIL|NOINFO)'
  # ①b 同一棵树上**结果侧**必不同 ⇒ 必须只作诊断、不许拉红
  chk "S2-outcome-diff-is-diagnostic-only" 0 "$d1" '^REGIME_OUTCOME_DIAG pair=P1 col=fgeom' '^REGIME_IDENTITY=FAIL'
  # ② 换体制（B 臂 m_ok 1→0）⇒ FAIL ＋ 点名 ＋ 标 INCOMPARABLE
  local d2="$sb/regime"; mkleg "$d2" W1-P1-A-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 1 '800x600@+0+0' 1
  mkleg "$d2" W1-P1-B-1 '800x600@+0+0' '1280x1024@+0+0' 0 0 0 '1280x1024@+0+0' 1
  chk "S3-regime-changed-FAIL" 1 "$d2" 'REGIME_INCOMPARABLE pair=P1 col=m_ok' '^REGIME_IDENTITY=PASS'
  chk "S4-incomparable-marked"  1 "$d2" 'REGIME_PAIR pair=P1 .*state=INCOMPARABLE'
  # ③ 单格判红（r_ok2=0 而 START_MAX=1）⇒ FAIL ＋ REGIME_RED_VIOLATION
  local d3="$sb/single"; mkleg "$d3" W1-P1-A-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 1 '800x600@+0+0' 1
  mkleg "$d3" W1-P1-B-1 '800x600@+0+0' '1280x1024@+0+0' 1 1 0 '1280x1024@+0+0' 1
  chk "S5-single-cell-red-FAIL" 1 "$d3" 'REGIME_RED_VIOLATION leg=W1-P1-B-1' '^REGIME_IDENTITY=PASS'
  # ③b 死腿（缺 DONE/RESULT ⇒ APP_ALIVE=no）⇒ 也不许算红
  local d3b="$sb/dead"; mkleg "$d3b" W1-P1-A-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 1 '800x600@+0+0' 1
  mkleg "$d3b" W1-P1-B-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 0 '1280x1024@+0+0' 0
  chk "S6-dead-leg-is-not-red" 1 "$d3b" 'REGIME_RED_VIOLATION leg=W1-P1-B-1 .*APP_ALIVE=no'
  # ④ 缺列 ⇒ NOINFO（**响亮失败**）
  local d4="$sb/colmiss"; mkleg "$d4" W1-P1-A-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 1 '800x600@+0+0' 1
  mkleg "$d4" W1-P1-B-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 0 '1280x1024@+0+0' 1
  sed -i 's/ m_ok=[01]//' "$d4/W1-P1-B-1/probe.txt"
  chk "S7-column-missing-NOINFO" 2 "$d4" 'reason=column-missing cols=m_ok' '^REGIME_IDENTITY=PASS'
  # ⑤ 空台账 ⇒ NOINFO（**空集不许判等**）
  local d5="$sb/empty"; mkdir -p "$d5/leg-without-probe"
  chk "S8-empty-ledger-NOINFO" 2 "$d5" 'reason=empty-ledger'
  # ⑤b 全是单臂 pair ⇒ NOINFO（跨臂可比性判不了）
  local d6="$sb/solo"; mkleg "$d6" W1-P1-A-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 1 '800x600@+0+0' 1
  chk "S9-no-multi-arm-pair-NOINFO" 2 "$d6" 'reason=no-multi-arm-pair'
  # ⑥ 阳性对照：单臂 pair **不**误判（多臂 pair 仍 PASS）
  local d7="$sb/mixed"; mkleg "$d7" W1-P1-A-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 1 '800x600@+0+0' 1
  mkleg "$d7" W1-P1-B-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 0 '1280x1024@+0+0' 1
  mkleg "$d7" W1-P9-A-1 '800x600@+0+0' '1280x1024@+0+0' 0 1 0 '1280x1024@+0+0' 1
  chk "S10-single-arm-not-judged" 0 "$d7" 'REGIME_PAIR pair=P9 .*state=SINGLE-ARM'
  # ⑦ 射程缺口**必须可见**
  chk "S11-unchecked-visible" 0 "$d1" 'REGIME_NOT_IN_LEDGER frame-at-base' ''
  chk "S12-unchecked-counted" 0 "$d1" 'unchecked=1'

  rm -rf "$sb"
  echo "REGIME_IDENTITY_SELFTEST_ROSTER cases=$tot pass=$pass fail=$fail"
  if [ "$fail" -eq 0 ]; then echo "REGIME_IDENTITY_SELFTEST=PASS total=$tot pass=$pass fail=$fail"; return 0; fi
  echo "REGIME_IDENTITY_SELFTEST=FAIL total=$tot pass=$pass fail=$fail"; return 1
}

if [ "$SELFTEST" = 1 ]; then run_selftest; exit $?; fi

if [ -z "$CORPUS" ]; then
  R="$(cd "$(dirname "$SELF")/../../.." && pwd)"
  CORPUS="$R/build/MilBridge/geom-corpus"
fi
run_core "$CORPUS"
exit $?

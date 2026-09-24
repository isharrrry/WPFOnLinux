#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# baseline-rate-gate.sh —— **基线率闸**（`D-G118` 的牙 / `TASK-0717`）
#
#  口径句（入册，逐字）：
#   「条件同一性必须包含『世界的时间稳定性』；凡登记速率都必须带**时间窗**，
#     且用于定 `N` 之前必须在**同窗现取**一道基线率闸 —— 对不上就 `VOID-PREMISE`，
#     不许拿历史速率凑功效。」
#
#  为什么需要它（`D-G118` 现场）：`TASK-0111` 的 `N=40` 是由历史速率 `0.889 → 0.589` 反推的；
#  而三批**世界逐位相同**（`BRIDGE`/`SHIM`/动作坐标/红签名全同）、**只有时间变了**：
#     `09-23 17:25 :221` = `12/12 = 100%`  →  `09-24 09:47–10:48` = `7/28 = 25.0%`
#     （Fisher 双尾 `9.02e-06`；Wilson 上界 `0.4024`/`0.4336` < 闸 `0.70`）
#   ⇒ 基线率**不是常数** ⇒ 反推出来的 `N` 也不成立 ⇒ 该批注定无功效。
#
#  🔺 **两个口径的角色（写死，免得被读成"两处数字打架"）**：
#    · **主判据** = Wilson **单侧** 95% 上界（`ci_upper=`，**闸比较用它**）
#    · **诊断列** = Wilson **双侧** 95%（`ci_upper_2s=`／`ci_lower_2s=`）＋ Clopper–Pearson 单侧（`cp_upper=`）
#    · 🆕 **当两个口径在闸比较上结论不同**（`ci_upper_1s < gate ≤ ci_upper_2s`，或反向的边界情形）
#      ⇒ 判词**必须** `NOINFO` ＋ 具名 `reason=caliber-disagreement`，
#      **禁止**用"对我方有利的那一界"下 `PASS`/`FAIL`（同族：`D-G98` 一格定罪／`D-G118` 拿历史速率凑功效／
#      `#63` 把结果侧算进体制）⇒ **口径之争先于结论，必须显形**。
#
#  三态（**先写死**；`NOINFO` 既不算绿也不算红）：
#    `BASELINERATE=PASS`    能算 ∧ 历史速率**落在**新样本 CI 之内 ∧ `ci_upper ≥ gate`
#                           ∧ `observed ≥ effect`（效应可发生）⇒ 可继续，并给 `required_n=`
#    `BASELINERATE=FAIL`    能算 ∧ 闸判失败；**其中"历史速率落在新样本 CI 之外"这一条必须点名**
#                           （`REASON=DRIFT-...` 或 `REASON=VOID-PREMISE(...)` 并列）
#    `BASELINERATE=NOINFO`  缺时间窗／空样本／`n` 非正／数值不可解析 ⇒ **响亮失败**（具名 reason）
#                           ⚠️ **禁静默判等**（纪律 27：解析任一侧为空必须响亮失败）
#
#  `VOID-PREMISE` 的两条**并列**条件（同时成立就并列打出，不取其一）：
#    ① `ci_upper < gate`     —— 先写的闸门被**排除**（不是"没观测到"）
#    ② `observed < effect`   —— 要排除的效应量**在现世界不可发生**（连重算 `N` 都无意义）
#
#  两极化（`--selftest`，夹具在 `$HOME` 沙箱，**确定性、不依赖任何现场腿读数**）：
#    ⓐ 同窗自洽 ⇒ `PASS`   ⓑ 换上掉出 CI 的样本 ⇒ `FAIL` ＋ **点名**   ⓒ `observed < effect` ⇒ `VOID-PREMISE`
#    ⓓ 空样本／缺时间窗 ⇒ **响亮 `NOINFO`**
#    ＋ 两条**反例对照**（证明闸**不是**恒判 `VOID-PREMISE`）：`22/27` ⇒ 可继续 `N=43`｜`12/12` ⇒ 可继续 `N=21`
#
#  纯读、零 `dotnet`、秒级、无网络、无 `X`；**不改产品件**。
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail
SELF="${BASH_SOURCE[0]}"

python3 - "$@" <<'PY'
# -*- coding: utf-8 -*-
import sys, math, os, re
from math import comb

ALPHA   = 0.05
POWER   = 0.80
Z_1S    = 1.6448536269514722   # 单侧 95%
Z_2S    = 1.959963984540054    # 双侧 95%

# ── 统计核心（与 `~/w157a/bin/baseline-rate-gate.py` 同口径；已逐位复现仓内四个
#    `REQUIRED_N_ALT` 值：7/0.8224、37/0.8010、41/0.8019、131/0.8041）────────────────
def fisher_two_sided(a, b, c, d):
    n = a + b + c + d
    if n == 0: return 1.0
    r1, c1 = a + b, a + c
    if c1 == 0 or c1 == n or r1 == 0 or r1 == n: return 1.0
    def pr(x): return comb(r1, x) * comb(n - r1, c1 - x) / comb(n, c1)
    obs = pr(a)
    lo, hi = max(0, c1 - (n - r1)), min(r1, c1)
    tot = 0.0
    for x in range(lo, hi + 1):
        p = pr(x)
        if p <= obs + 1e-12: tot += p
    return min(1.0, tot)

def power_two_sample(n, p0, p1, alpha=ALPHA):
    b0 = [comb(n, k) * p0**k * (1-p0)**(n-k) for k in range(n+1)]
    b1 = [comb(n, k) * p1**k * (1-p1)**(n-k) for k in range(n+1)]
    tot = 0.0
    for x in range(n+1):
        if b0[x] == 0: continue
        for y in range(n+1):
            if b1[y] == 0: continue
            if fisher_two_sided(x, n-x, y, n-y) <= alpha: tot += b0[x]*b1[y]
    return tot

def required_n(p_base, p_alt, power=POWER, alpha=ALPHA, nmax=400):
    if p_alt is None or p_alt <= 0 or p_alt >= p_base: return None, 0.0
    last = 0.0
    for n in range(2, nmax + 1):
        pw = power_two_sample(n, p_base, p_alt, alpha)
        last = pw
        if pw >= power: return n, pw
    return None, last

def wilson(k, n, z):
    if n <= 0: return (0.0, 1.0)
    ph = k / n; den = 1 + z*z/n
    ctr = (ph + z*z/(2*n)) / den
    half = z * math.sqrt(ph*(1-ph)/n + z*z/(4*n*n)) / den
    return (max(0.0, ctr-half), min(1.0, ctr+half))

def cp_upper(k, n, conf=0.95):
    if n <= 0: return 1.0
    if k >= n: return 1.0
    if k == 0: return 1 - (1-conf)**(1.0/n)
    lo, hi, target = 0.0, 1.0, 1 - conf
    for _ in range(200):
        mid = (lo + hi) / 2
        cdf = sum(comb(n, i) * mid**i * (1-mid)**(n-i) for i in range(k+1))
        if cdf > target: lo = mid
        else: hi = mid
    return (lo + hi) / 2

# ── 解析（**任一侧为空/不可解析 ⇒ 响亮失败**，纪律 27）──────────────────────────
def parse_rn(s):
    """`R/N` ⇒ (r, n)；不可解析 ⇒ None（调用方负责响亮失败）"""
    if s is None: return None
    m = re.fullmatch(r"(\d+)/(\d+)", s.strip())
    if not m: return None
    return int(m.group(1)), int(m.group(2))

def parse_registered(s):
    """`R/N@时间窗` ⇒ (r, n, window)；**缺 `@时间窗` ⇒ window=None**（调用方判 NOINFO）"""
    if s is None: return None
    s = s.strip()
    if "@" in s:
        head, win = s.split("@", 1)
        rn = parse_rn(head); win = win.strip()
        if rn is None: return None
        return rn[0], rn[1], (win if win else None)
    rn = parse_rn(s)
    if rn is None: return None
    return rn[0], rn[1], None

def emit(state, rc, fields, reason):
    print("BASELINERATE=%s" % state)
    print("BASELINERATE_REASON=%s" % reason)
    for k in ("registered", "window", "observed", "observed_rate", "ci_upper", "ci_upper_2s",
              "ci_lower_2s", "cp_upper", "fisher_p", "registered_in_observed_ci",
              "gate", "effect", "required_n", "required_n_power", "voidpremise",
              "voidpremise_reason", "gate_closed", "effect_impossible",
              "caliber_disagreement", "gate_verdict_1s", "gate_verdict_2s"):
        print("%s=%s" % (k, fields.get(k, "-")))
    print("BASELINERATE_RC=%d" % rc)
    return rc

def evaluate(registered_s, observed_s, gate_s, effect_s, quiet=False):
    F = {}
    # ① 解析注册速率
    reg = parse_registered(registered_s)
    if reg is None:
        return emit("NOINFO", 3, F, "NOINFO-PARSE registered不可解析（形态应为 R/N@时间窗）: %r" % registered_s)
    rr, rn, win = reg
    F["registered"] = "%d/%d" % (rr, rn); F["window"] = win if win else "-"
    if win is None:
        return emit("NOINFO", 3, F, "NOINFO-NO-WINDOW 在册速率缺**时间窗**（形态须为 R/N@时间窗）⇒ 不许用它定 N（D-G118）")
    if rn <= 0:
        return emit("NOINFO", 3, F, "NOINFO-N-NONPOS registered n=%d 非正" % rn)
    if rr < 0 or rr > rn:
        return emit("NOINFO", 3, F, "NOINFO-R-RANGE registered r=%d 不在 [0,%d]" % (rr, rn))
    # ② 解析现取样本
    obs = parse_rn(observed_s)
    if obs is None:
        return emit("NOINFO", 3, F, "NOINFO-EMPTY-SAMPLE 现取样本为空/不可解析（形态应为 R/N）: %r" % observed_s)
    ro, no = obs
    if no <= 0:
        return emit("NOINFO", 3, F, "NOINFO-N-NONPOS observed n=%d 非正" % no)
    if ro < 0 or ro > no:
        return emit("NOINFO", 3, F, "NOINFO-R-RANGE observed r=%d 不在 [0,%d]" % (ro, no))
    F["observed"] = "%d/%d" % (ro, no)
    po = ro / no
    F["observed_rate"] = "%.4f" % po
    # ③ 数字闸（gate / effect）
    try:
        gate = float(gate_s)
    except (TypeError, ValueError):
        return emit("NOINFO", 3, F, "NOINFO-PARSE gate不可解析: %r" % gate_s)
    try:
        effect = float(effect_s)
    except (TypeError, ValueError):
        return emit("NOINFO", 3, F, "NOINFO-PARSE effect不可解析: %r" % effect_s)
    if not (0.0 < gate < 1.0):
        return emit("NOINFO", 3, F, "NOINFO-GATE-RANGE gate=%g 不在 (0,1)" % gate)
    if not (0.0 <= effect < 1.0):
        return emit("NOINFO", 3, F, "NOINFO-EFFECT-RANGE effect=%g 不在 [0,1)" % effect)
    F["gate"] = "%.4f" % gate; F["effect"] = "%.4f" % effect
    # ④ 区间与显著性
    lo1, hi1 = wilson(ro, no, Z_1S)
    lo2, hi2 = wilson(ro, no, Z_2S)
    F["ci_upper"]     = "%.4f" % hi1     # **主控指定**：Wilson **单侧** 95% 上界（闸用它）
    F["ci_upper_2s"]  = "%.4f" % hi2     # 诊断列（双侧上界；比单侧更保守）
    F["ci_lower_2s"]  = "%.4f" % lo2
    F["cp_upper"]     = "%.4f" % cp_upper(ro, no)
    fp = fisher_two_sided(ro, no-ro, rr, rn-rr)
    F["fisher_p"] = "%.4g" % fp
    reg_inside = 1 if (lo2 <= (rr/rn) <= hi2) else 0
    F["registered_in_observed_ci"] = str(reg_inside)
    # ⑤′ **口径之争先于结论**（主控 `#64` 加严，不属放宽）：
    #   单侧与双侧在**闸比较**上结论不同（`ci_upper_1s < gate ≤ ci_upper_2s` 或反向的边界情形）
    #   ⇒ 判词必须 `NOINFO` ＋ 具名 `reason=caliber-disagreement`，
    #   **禁止**用"对我方有利的那一界"去下 `PASS`/`FAIL`。
    #   理由（同族教训）：本会话已有一整族"**选口径/挑仪表**"的现场（`D-G98` 一格定罪、
    #   `D-G118` 拿历史速率凑功效、`#63` 把结果侧算进体制）⇒ **口径之争先于结论，必须显形**。
    F["gate_verdict_1s"] = "closed" if hi1 < gate else "open"
    F["gate_verdict_2s"] = "closed" if hi2 < gate else "open"
    if F["gate_verdict_1s"] != F["gate_verdict_2s"]:
        F["caliber_disagreement"] = "1"
        return emit("NOINFO", 3, F,
                    "NOINFO-CALIBER-DISAGREEMENT 口径之争先于结论：单侧 ci_upper=%.4f（%s）与双侧 "
                    "ci_upper_2s=%.4f（%s）对闸 gate=%.4f 结论不同 ⇒ reason=caliber-disagreement；"
                    "**禁止**用对我方有利的那一界下 PASS/FAIL" %
                    (hi1, F["gate_verdict_1s"], hi2, F["gate_verdict_2s"], gate))
    F["caliber_disagreement"] = "0"

    # ⑤ 两条 VOID-PREMISE（**并列**，不取其一）
    reasons = []; vp = 0
    gate_closed = hi1 < gate
    effect_imposs = po < effect
    if gate_closed:
        vp = 1; reasons.append("① ci_upper(%.4f) < gate(%.4f)" % (hi1, gate))
    if effect_imposs:
        vp = 1; reasons.append("② observed(%.4f) < effect(%.4f) ⇒ 该效应在现世界不可发生" % (po, effect))
    F["voidpremise"] = str(vp)
    F["voidpremise_reason"] = ";以".join(reasons) if reasons else "-"
    F["gate_closed"] = "1" if gate_closed else "0"
    F["effect_impossible"] = "1" if effect_imposs else "0"
    # ⑥ 重算 N（用**现取**率）
    n_alt = po - effect
    if n_alt > 0:
        n_req, pw = required_n(po, n_alt)
        F["required_n"] = str(n_req) if n_req else "NONE(>400)"
        F["required_n_power"] = "%.4f" % pw
    else:
        F["required_n"] = "NONE"; F["required_n_power"] = "0.0000"
    # ⑦ 三态
    drift = (reg_inside == 0)
    if vp or drift:
        rs = []
        if drift:
            rs.append("DRIFT 历史速率落在新样本 CI 之外（registered=%d/%d=%.4f ∉ 现取 CI [%.4f,%.4f]）"
                      % (rr, rn, rr/rn, lo2, hi2))
        if vp:
            rs.append("VOID-PREMISE " + (";以".join(reasons) if reasons else ""))
        return emit("FAIL", 1, F, " + ".join(rs))
    return emit("PASS", 0, F, "PASS 同窗自洽（历史速率落在 CI 内 ∧ 闸未排除 ∧ 效应可发生）")

# ── 台账模式（`--cases`）：逐行跑真判词并与**行内声明的期望**比对 ──────────────
COLS = ["name", "registered", "observed", "gate", "effect", "want_state", "want_rc", "want_reason_class"]

def reason_class(reason, state):
    if state == "NOINFO":
        if "caliber-disagreement" in reason: return "caliber-disagreement"
        m = re.match(r"NOINFO-([A-Z-]+)", reason)
        return "NOINFO-" + m.group(1) if m else "NOINFO-?"
    if state == "FAIL":
        if "DRIFT" in reason: return "DRIFT"
        if "VOID-PREMISE" in reason: return "VOID-PREMISE"
        return "FAIL-?"
    return "PASS"

def run_cases(path):
    rows = []
    with open(path, encoding="utf-8") as fh:
        for ln in fh:
            ln = ln.rstrip("\n")
            if not ln.strip() or ln.lstrip().startswith("#"): continue
            parts = ln.split("\t")
            if len(parts) != len(COLS): continue
            rows.append(dict(zip(COLS, parts)))
    if not rows:
        print("BASELINERATE=NOINFO"); print("BASELINERATE_CASES=0")
        print("BASELINERATE_REASON=NOINFO-EMPTY-LEDGER 台账无有效行（禁静默判等）")
        print("BASELINERATE_RC=3"); return 3
    passed = 0; failed = 0; details = []
    for r in rows:
        reg = r["registered"] if r["registered"] != "-" else None
        obs = r["observed"] if r["observed"] != "-" else None
        g   = r["gate"] if r["gate"] != "-" else None
        e   = r["effect"] if r["effect"] != "-" else None
        # 逐行**真跑**（捕获机读行）
        import io, contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = evaluate(reg, obs, g, e, quiet=True)
        out = buf.getvalue()
        st = re.search(r"^BASELINERATE=(\S+)$", out, re.M).group(1)
        rsn = re.search(r"^BASELINERATE_REASON=(.*)$", out, re.M).group(1)
        cls = reason_class(rsn, st)
        ok = (st == r["want_state"]) and (str(rc) == r["want_rc"])
        if r["want_reason_class"] != "-":
            ok = ok and (cls == r["want_reason_class"])
        passed += 1 if ok else 0; failed += 0 if ok else 1
        details.append((r["name"], st, rc, cls, r["want_state"], r["want_rc"], r["want_reason_class"], ok, rsn))
    for (nm, st, rc, cls, ws, wr, wc, ok, rsn) in details:
        print("CASE %-38s got=%s/%d/%-14s want=%s/%s/%-14s %s" %
              (nm, st, rc, cls, ws, wr, wc, "OK" if ok else "**MISMATCH**"))
        if not ok:
            print("     reason=%s" % rsn)
    print("BASELINERATE_CASES=%d passed=%d failed=%d" % (len(rows), passed, failed))
    if failed:
        print("BASELINERATE=FAIL"); print("BASELINERATE_RC=1"); return 1
    print("BASELINERATE=PASS"); print("BASELINERATE_RC=0"); return 0

# ── 两极化自检（夹具建在 `$HOME` 沙箱；**确定性合成**，不依赖现场腿读数）──────
def selftest():
    # ⚠️ 夹具放 **`$HOME` 沙箱**（主控指定；不用 `/tmp` —— 本机 `/tmp` 曾因 ENOSPC 让整趟仪器
    #    报 `rc=2 NOINFO`，见 `#54` 那条方法学），跑完**不删**（留档可比对）。
    import time
    base = os.path.join(os.path.expanduser("~"), "baseline-rate-gate-selftest")
    os.makedirs(base, exist_ok=True)
    sb = os.path.join(base, "run-%s" % time.strftime("%Y%m%d-%H%M%S"))
    os.makedirs(sb, exist_ok=True)
    cases = os.path.join(sb, "cases.tsv")
    body = "\n".join([
        "# 合成用例（**确定性**；不依赖任何现场腿读数）",
        "# " + "\t".join(COLS),   # 表头必须是注释（否则会被当成一行用例 —— 本自检第一版就咬到过）
        # ⓐ 同窗自洽 ⇒ PASS（registered 落在 observed CI 内；闸未排除；效应可发生）
        "a-self-consistent\t24/27@2026-09-23T17:25:50+08:00 :221\t23/27\t0.70\t0.30\tPASS\t0\tPASS",
        # ⓑ 换上掉出 CI 的样本 ⇒ FAIL ＋ 点名（历史 24/27=0.889 vs 现取 7/28=0.25）
        "b-sample-outside-ci\t24/27@2026-09-23T17:25:50+08:00 :221\t7/28\t0.70\t0.30\tFAIL\t1\tDRIFT",
        # ⓒ observed < effect ⇒ VOID-PREMISE（**只让②**成立：registered==observed 无漂移 ∧ ci_upper ≥ gate ⇒ ①不成立）
        "c-effect-impossible\t27/30@2026-01-01T00:00:00+08:00 X\t27/30\t0.70\t0.95\tFAIL\t1\tVOID-PREMISE",
        # ⓓ 空样本 ⇒ 响亮 NOINFO
        "d-empty-sample\t24/27@2026-09-23T17:25:50+08:00 :221\t-\t0.70\t0.30\tNOINFO\t3\tNOINFO-EMPTY-SAMPLE",
        # ⓓ′ 缺时间窗 ⇒ 响亮 NOINFO
        "d2-no-window\t24/27\t22/27\t0.70\t0.30\tNOINFO\t3\tNOINFO-NO-WINDOW",
        # 🆕 口径之争 ⇒ NOINFO/caliber-disagreement（闸取在两个口径的界之间）
        "g-caliber-disagreement\t7/28@2026-09-24T09:47:39+08:00+display=:215\t7/28\t0.42\t0.10\tNOINFO\t3\tcaliber-disagreement",
        # 反例对照 ①（证明闸**不是**恒判 VOID-PREMISE）：22/27 ⇒ 可继续
        "e-counterexample-22-of-27\t24/27@2026-09-23T17:25:50+08:00 :221\t22/27\t0.70\t0.30\tPASS\t0\tPASS",
        # 反例对照 ②：12/12 ⇒ 可继续
        "f-counterexample-12-of-12\t24/27@2026-09-23T17:25:50+08:00 :221\t12/12\t0.70\t0.30\tPASS\t0\tPASS",
        "",
    ])
    with open(cases, "w", encoding="utf-8") as fh: fh.write(body)
    print("SELFTEST_SANDBOX=%s" % sb)
    print("SELFTEST_LEDGER=%s" % cases)
    rc = run_cases(cases)
    # 反证：把 declared 期望改错 ⇒ 必须**红**（证明"比对"这件事真的在比）
    bad = os.path.join(sb, "cases-bad.tsv")
    with open(bad, "w", encoding="utf-8") as fh:
        fh.write(body.replace("a-self-consistent\t24/27@2026-09-23T17:25:50+08:00 :221\t23/27\t0.70\t0.30\tPASS\t0\tPASS",
                              "a-self-consistent\t24/27@2026-09-23T17:25:50+08:00 :221\t23/27\t0.70\t0.30\tFAIL\t1\tDRIFT"))
    import io, contextlib
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf): rcb = run_cases(bad)
    print("SELFTEST_ANTI_POLARITY bad_ledger_rc=%d (期望 !=0)" % rcb)
    neg = (rcb != 0)
    ok = (rc == 0) and neg
    # 两条反例对照的 required_n（证明"可继续"分支真的给出 N）
    for (label, reg, obs) in [("e-counterexample-22-of-27", "24/27@w", "22/27"),
                              ("f-counterexample-12-of-12", "24/27@w", "12/12")]:
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf): evaluate(reg, obs, "0.70", "0.30")
        n = re.search(r"^required_n=(\S+)$", buf.getvalue(), re.M).group(1)
        print("SELFTEST_COUNTEREXAMPLE name=%s required_n=%s" % (label, n))
    print("BASELINERATE_SELFTEST=%s" % ("PASS" if ok else "FAIL"))
    return 0 if ok else 1

# ── 主入口 ────────────────────────────────────────────────────────────────────
def main(argv):
    a = list(argv); kv = {}
    i = 0
    while i < len(a):
        if a[i] in ("--registered", "--observed", "--gate", "--effect", "--cases"):
            if i+1 >= len(a):
                print("BASELINERATE=NOINFO"); print("BASELINERATE_REASON=NOINFO-USAGE 选项 %s 缺参数" % a[i])
                print("BASELINERATE_RC=3"); return 3
            kv[a[i]] = a[i+1]; i += 2; continue
        if a[i] == "--selftest":
            return selftest()
        print("BASELINERATE=NOINFO"); print("BASELINERATE_REASON=NOINFO-USAGE 未知参数 %s" % a[i])
        print("BASELINERATE_RC=3"); return 3
    if "--cases" in kv:
        return run_cases(kv["--cases"])
    need = ["--registered", "--observed", "--gate", "--effect"]
    miss = [k for k in need if k not in kv]
    if miss:
        print("BASELINERATE=NOINFO")
        print("BASELINERATE_REASON=NOINFO-USAGE 缺必填选项 %s" % " ".join(miss))
        print("BASELINERATE_RC=3"); return 3
    return evaluate(kv["--registered"], kv["--observed"], kv["--gate"], kv["--effect"])

sys.exit(main(sys.argv[1:]))
PY

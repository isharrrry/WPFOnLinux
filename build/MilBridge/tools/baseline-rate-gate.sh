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
              "caliber_disagreement", "gate_verdict_1s", "gate_verdict_2s",
              "DECL_UPPER", "decl_upper_checked", "decl_upper_caliber", "decl_upper_expected",
              "decl_upper_correct_cp1s", "decl_upper_gap"):
        print("%s=%s" % (k, fields.get(k, "-")))
    print("BASELINERATE_RC=%d" % rc)
    return rc

def evaluate(registered_s, observed_s, gate_s, effect_s, quiet=False,
             decl_upper=None, decl_formula="-"):
    F = {}
    # 🆕 `AMENDMENT-3`：**承重 token**，本行初始化 ⇒ 任何早退都打 `NOT-EVALUATED`
    F["DECL_UPPER"] = "NOT-EVALUATED"
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
    # ③ 🆕 **申报上界的自洽性**（`D-G121` / `TASK-0719`）
    #    适用域（写死）：`rule-of-three-0hit` = `1-α^(1/n)` **只许用于 `k = 0`**；
    #                    `cp-1s` = Clopper–Pearson 单侧 95% 上界，**任意 `k ≥ 0`**；`k=0` 时两者**逐位相同**。
    #    `k` 取 **registered 的分子**（**不是** `observed` 的）。
    #    比对 = **逐字文本比对**（`%.4f`）⇒ **不设浮点容差、不开可覆盖的 tol 旋钮**；
    #    3-3 的方向比较**必须按数值**（字典序会给出错结论）。
    #    3-1/3-2/3-3 ⇒ `FAIL`（具名）；3-5/3-6 ⇒ 响亮 `NOINFO`；`decl_upper is None` ⇒ 3-7 本格不判。
    if decl_upper is None:
        F["decl_upper_checked"] = "na"          # 3-7：冻结旧行 ⇒ 本格不判（旧 11 行判词逐字不变）
    elif decl_upper == "-":
        F["decl_upper_checked"] = "missing"     # 3-6：表头声明了该列却留 `-`（缺声明 ≠ 通过）
        return emit("NOINFO", 3, F, "NOINFO-DECL-UPPER-MISSING 表头已声明 decl_upper 列而本行留 `-`"
                    "（缺声明 ≠ 通过）⇒ reason=NOINFO-DECL-UPPER-MISSING")
    else:
        t4 = lambda x: "%.4f" % x
        F["decl_upper_caliber"] = decl_formula if decl_formula in ("rule-of-three-0hit", "cp-1s") else "-"
        exp_ro3 = t4(1.0 - (ALPHA ** (1.0 / rn)))
        exp_cp1s = t4(cp_upper(rr, rn))
        F["decl_upper_correct_cp1s"] = exp_cp1s
        if decl_formula not in ("rule-of-three-0hit", "cp-1s", "-"):
            F["decl_upper_checked"] = "formula-unknown"
            return emit("NOINFO", 3, F, "NOINFO-DECL-FORMULA-UNKNOWN decl_formula 取值须为 "
                        "rule-of-three-0hit|cp-1s|-（未知口径**不许**静默当 `-`）: %r"
                        " ⇒ reason=NOINFO-DECL-FORMULA-UNKNOWN" % decl_formula)
        try:
            dv = float(decl_upper)
        except (TypeError, ValueError):
            dv = None
        if dv is None or len(decl_upper.split(".")[-1]) != 4:
            F["decl_upper_checked"] = "format"
            return emit("NOINFO", 3, F, "NOINFO-DECL-UPPER-FORMAT decl_upper 形态须为 `%%.4f` 文本或 `-`: %r"
                        " ⇒ reason=NOINFO-DECL-UPPER-FORMAT" % decl_upper)
        exp = exp_ro3 if decl_formula == "rule-of-three-0hit" else (exp_cp1s if decl_formula == "cp-1s" else None)
        F["decl_upper_expected"] = exp if exp else "-"
        if exp is not None and decl_upper != exp:                        # 3-1
            F["decl_upper_checked"] = "mismatch"
            F["decl_upper_gap"] = t4(cp_upper(rr, rn) - dv)
            return emit("FAIL", 1, F, "DECL-FORMULA-VALUE-MISMATCH 申报公式与申报值不符：decl_formula=%s "
                        "decl_upper=%s 而该公式在 k=%d/n=%d 上应为 %s ⇒ reason=decl-formula-value-mismatch"
                        % (decl_formula, decl_upper, rr, rn, exp))
        if rr > 0 and (decl_formula == "rule-of-three-0hit" or decl_upper == exp_ro3):   # 3-2
            F["decl_upper_checked"] = "zerohit"
            F["decl_upper_gap"] = t4(cp_upper(rr, rn) - dv)
            return emit("FAIL", 1, F, "ZERO-HIT-FORMULA-ON-NONZERO-SAMPLE k=%d>0 却用 k=0 的上界公式"
                        "（1-α^(1/n)）申报：decl_upper=%s（该式值 %s），正确口径 cp-1s = %s ⇒ 上界被低报 %s"
                        " ⇒ reason=zero-hit-formula-on-nonzero-sample"
                        % (rr, decl_upper, exp_ro3, exp_cp1s, F["decl_upper_gap"]))
        cpv = cp_upper(rr, rn)
        if dv < cpv - 0.5e-4:                                            # 3-3（数值比较）
            F["decl_upper_checked"] = "optimistic"
            F["decl_upper_gap"] = t4(cpv - dv)
            return emit("FAIL", 1, F, "DECL-UPPER-OPTIMISTIC 申报上界比正确口径更乐观：decl_upper=%s < "
                        "cp-1s = %s ⇒ 方向危险（上界报低）⇒ reason=decl-upper-optimistic"
                        % (decl_upper, exp_cp1s))
        if decl_upper == exp_cp1s:                                       # 3-4 自洽 ⇒ 继续走 ④…⑦
            F["decl_upper_checked"] = "ok"
            F["DECL_UPPER"] = "EVALUATED"
            F["decl_upper_gap"] = t4(cpv - dv)
        else:                                                            # 3-5 保守但认不出
            F["decl_upper_checked"] = "unmatched"
            F["decl_upper_gap"] = t4(cpv - dv)
            return emit("NOINFO", 3, F, "NOINFO-DECL-UPPER-UNMATCHED 申报上界比正确口径保守但认不出出自哪个"
                        "式子：decl_upper=%s > cp-1s = %s（既不等于 cp-1s 的打印值 %s，也不等于 k=0 式值 %s）"
                        "⇒ 既不算绿也不算红 ⇒ reason=NOINFO-DECL-UPPER-UNMATCHED"
                        % (decl_upper, exp_cp1s, exp_cp1s, exp_ro3))
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
COLS_LEGACY = ["name", "registered", "observed", "gate", "effect", "want_state", "want_rc", "want_reason_class"]
COLS_NEW    = COLS_LEGACY + ["decl_upper", "decl_formula"]   # 新形态 10 列（`D-G121` / `TASK-0719`）
COLS        = COLS_LEGACY                                    # 兼容别名：旧读者仍按 8 列；内部一律用 COLS_LEGACY/COLS_NEW

def reason_class(reason, state):
    if state == "NOINFO":
        if "caliber-disagreement" in reason: return "caliber-disagreement"
        m = re.match(r"NOINFO-([A-Z-]+)", reason)
        return "NOINFO-" + m.group(1) if m else "NOINFO-?"
    if state == "FAIL":
        if "decl-column-required-on-new-row" in reason: return "decl-column-required-on-new-row"
        if "zero-hit-formula-on-nonzero-sample" in reason: return "zero-hit-formula-on-nonzero-sample"
        if "decl-formula-value-mismatch" in reason: return "decl-formula-value-mismatch"
        if "decl-upper-optimistic" in reason: return "decl-upper-optimistic"
        if "DRIFT" in reason: return "DRIFT"
        if "VOID-PREMISE" in reason: return "VOID-PREMISE"
        return "FAIL-?"
    return "PASS"

def run_cases(path):
    rows = []
    comments = []        # 🆕 注释行收集（表头声明 / legacy_rows 的册级自洽检查要用）
    with open(path, encoding="utf-8") as fh:
        for ln in fh:
            raw = ln.rstrip("\n")
            if not raw.strip(): continue
            if raw.lstrip().startswith("#"):                 # 注释行：收起来供**册级自洽检查**用（表头声明 / legacy_rows）
                comments.append(raw); continue
            parts = raw.split("\t")
            if len(parts) not in (8, 10):                    # 🆕 其它宽度 ⇒ **响亮失败**（旧件在此处是静默 `continue`）
                print("BASELINERATE=NOINFO")
                print("BASELINERATE_CASES=%d" % len(rows))
                print("BASELINERATE_REASON=NOINFO-DECL-COLUMN-WIDTH 第 %d 行宽度=%d，既非 8（旧形态）也非 10（新形态）"
                      " ⇒ 响亮失败（禁静默跳过；`D-G104` 同族）⇒ reason=NOINFO-DECL-COLUMN-WIDTH" % (len(rows) + 1, len(parts)))
                print("BASELINERATE_RC=3"); return 3
            if len(parts) == 10:
                rows.append(dict(zip(COLS_NEW, parts)))
            else:
                rows.append(dict(zip(COLS_LEGACY, parts)))
    if not rows:
        print("BASELINERATE=NOINFO"); print("BASELINERATE_CASES=0")
        print("BASELINERATE_REASON=NOINFO-EMPTY-LEDGER 台账无有效行（禁静默判等）")
        print("BASELINERATE_RC=3"); return 3

    # ── 🆕 册级自洽检查（`D-G121` / `TASK-0719`；**先于逐行**，任一不过 ⇒ 整册响亮 NOINFO）──────
    _ctxt = "\n".join(comments)
    _declares = ("decl_upper" in _ctxt) and ("decl_formula" in _ctxt)
    _legacy_m = re.search(r"legacy_rows=(\d+)", _ctxt)
    _w8 = [i for i, r in enumerate(rows) if len(COLS_LEGACY) == len(r)]
    _w10 = [i for i, r in enumerate(rows) if len(COLS_NEW) == len(r)]
    _legacy = None
    if not _declares:
        if _w10:   # 表头没声明却有 10 列行 ⇒ 不许偷偷加列
            _legacy = "NOINFO-DECL-COLUMN-UNDECLARED"
        else:
            _legacy = -1            # -1 = 整册旧形态：以下所有行都不判 ③
    else:
        if _legacy_m is None:
            _legacy = "NOINFO-DECL-COLUMN-LEGACY-MISMATCH"   # 声明了新列就必须钉冻结旧行数
        else:
            _L = int(_legacy_m.group(1))
            if _L > len(rows) or any((len(rows[k]) != len(COLS_LEGACY)) for k in range(_L)):
                _legacy = "NOINFO-DECL-COLUMN-LEGACY-MISMATCH"
            elif not _w10:
                _legacy = "NOINFO-DECL-COLUMN-DECLARED-BUT-UNUSED"
            else:
                _legacy = _L
    if isinstance(_legacy, str):
        print("BASELINERATE=NOINFO"); print("BASELINERATE_CASES=%d" % len(rows))
        print("BASELINERATE_REASON=%s 册级列结构自洽检查不过（表头声明=%s legacy_rows=%s 宽8=%d 宽10=%d）"
              " ⇒ reason=%s" % (_legacy, _declares, (_legacy_m.group(1) if _legacy_m else None), len(_w8), len(_w10), _legacy))
        print("BASELINERATE_RC=3"); return 3
    passed = 0; failed = 0; details = []
    _meta = []                    # 🆕 逐行 (idx, width, DECL_UPPER, decl_upper_checked)，供册级不变量用
    for r in rows:
        reg = r["registered"] if r["registered"] != "-" else None
        obs = r["observed"] if r["observed"] != "-" else None
        g   = r["gate"] if r["gate"] != "-" else None
        e   = r["effect"] if r["effect"] != "-" else None
        # 逐行**真跑**（捕获机读行）
        import io, contextlib
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            # 🆕 ③ 的入口分派（**列结构规则**属册级，故在此判；判据本体在 `evaluate()`）
            _w = len(r); _idx = rows.index(r) + 1
            if _legacy == -1 or (_w == 8 and _legacy is not None and _idx <= _legacy):
                _du = None                      # 3-7：冻结旧行 ⇒ 本格不判
            elif _w == 8:
                rc = 1                          # 3-9：**新行不许退回旧形态** ⇒ FAIL（主控裁定）
                out_forced = ("BASELINERATE=FAIL\n"
                              "BASELINERATE_REASON=FAIL DECL-COLUMN-REQUIRED-ON-NEW-ROW 第 %d 行是 8 列（旧形态）"
                              "而它不在 legacy_rows 前缀内 ⇒ 新行必须用 10 列并填 decl_upper"
                              " ⇒ reason=decl-column-required-on-new-row\n"
                              "DECL_UPPER=NOT-EVALUATED\n"
                              "decl_upper_checked=column-width\n"
                              "BASELINERATE_RC=3\n") % _idx
            else:
                _du = r["decl_upper"]
            if _w == 8 and (_legacy == -1 or (_legacy is not None and _idx <= _legacy)):
                with contextlib.redirect_stdout(buf):
                    rc = evaluate(reg, obs, g, e, quiet=True, decl_upper=None)
            elif _w == 10:
                with contextlib.redirect_stdout(buf):
                    rc = evaluate(reg, obs, g, e, quiet=True, decl_upper=_du, decl_formula=r["decl_formula"])
        out = buf.getvalue()
        if _w == 8 and not (_legacy == -1 or (_legacy is not None and _idx <= _legacy)):
            out = out_forced
        st = re.search(r"^BASELINERATE=(\S+)$", out, re.M).group(1)
        rsn = re.search(r"^BASELINERATE_REASON=(.*)$", out, re.M).group(1)
        cls = reason_class(rsn, st)
        # 🆕 `AMENDMENT-3`：本行必须逐行打印承重 token（单次 grep 可命中）＋细分原因
        def _g(pat, s, d="-"):
            m = re.search(pat, s, re.M); return m.group(1) if m else d
        _du_tok = _g(r"^DECL_UPPER=(\S+)$", out)
        _du_chk = _g(r"^decl_upper_checked=(\S+)$", out)
        ok = (st == r["want_state"]) and (str(rc) == r["want_rc"])
        if r["want_reason_class"] != "-":
            ok = ok and (cls == r["want_reason_class"])
        passed += 1 if ok else 0; failed += 0 if ok else 1
        _meta.append((_idx, _w, _du_tok, _du_chk, cls))
        details.append((r["name"], st, rc, cls, r["want_state"], r["want_rc"], r["want_reason_class"], ok, _du_tok, _du_chk, rsn))
    for (nm, st, rc, cls, ws, wr, wc, ok, _du_tok, _du_chk, rsn) in details:
        print("CASE %-38s got=%s/%d/%-14s want=%s/%s/%-14s %s DECL_UPPER=%-14s checked=%-16s" %
              (nm, st, rc, cls, ws, wr, wc, "OK" if ok else "**MISMATCH**", _du_tok, _du_chk))
        if not ok:
            print("     reason=%s" % rsn)
# ── 🆕 三条**册级不变量**（`AMENDMENT-3` §11.5；主控裁定）：把"良性未评估"与"失败未评估"在册级分开，不必加 token ──
    #   ① `NOT-EVALUATED` 的行，其 `decl_upper_checked` 必须 ∈ {7 值} ∪ {`na`, `-`}（`ok` ⇒ 自相矛盾）
    #   ② `legacy_rows` 前缀内的旧形态行 ⇒ `decl_upper_checked` ∈ {`na`, `-`}（出现 7 值之一 ⇒ 旧行被 ③ 判 ⇒ FAIL）
    #   ③ 前缀**之外**的新形态行**不许**为 `na`（那是"新行没被 ③ 判"）
    #   ⚠️ 允许集里含 `-`（= 更早的前置检查先 return ⇒ ③ 未走到）—— 该格是**保留冻结 11 行**所必需；
    #      与裁定原文（{7 值} ∪ {na}）的差异已在 `REBASE.md §⑤c` 具名上报，请裁定。
    _SEVEN = {"mismatch", "zerohit", "optimistic", "unmatched", "missing", "format", "formula-unknown"}
    _ALLOWED_NOTEVAL = _SEVEN | {"na", "-", "column-width"}
    _viol = []
    _PRECHK = {"NOINFO-NO-WINDOW", "NOINFO-N-NONPOS", "NOINFO-R-RANGE"}   # 仅这三条前置码可配 `-`
    _lg_mode = isinstance(_legacy, int) and _legacy >= 0     # -1 = 整册旧形态（无新行 ⇒ ②③ 不适用）
    for (_ix, _wd, _tk, _ck, _cls) in _meta:
        if _tk == "NOT-EVALUATED" and (_ck not in _ALLOWED_NOTEVAL):
            _viol.append(("decl-upper-pairing-violated", _ix, "DECL_UPPER=NOT-EVALUATED 而 decl_upper_checked=%s（不在**白名单** {7 值}∪{na,-,column-width} 内 ⇒ 新原因一律默认 FAIL，不许自动接纳）" % _ck))
        elif _tk not in ("EVALUATED", "NOT-EVALUATED"):
            _viol.append(("decl-upper-pairing-violated", _ix, "DECL_UPPER=%s 既非 EVALUATED 也非 NOT-EVALUATED（token 必须全函数）" % _tk))
        if _tk == "EVALUATED" and _ck != "ok":
            _viol.append(("decl-upper-pairing-violated", _ix, "DECL_UPPER=EVALUATED 而 decl_upper_checked=%s ≠ ok（token 与细分原因自相矛盾）" % _ck))
        if _ck == "-" and _cls not in _PRECHK:
            _viol.append(("decl-upper-notreached-unpaired", _ix, "decl_upper_checked=- 却出现在判词类 %s 上（`-` 只许配三条前置 NOINFO 码 ⇒ 否则会掩盖一条本该被评估的路径）" % _cls))
        if _lg_mode and _legacy > 0 and _ix <= _legacy and _wd == 8 and _ck not in ("na", "-"):
            _viol.append(("decl-upper-legacy-judged", _ix, "legacy_rows 前缀内的旧形态行 decl_upper_checked=%s（既非 na 也非 -）⇒ 旧行不该被 ③ 判" % _ck))
        if _lg_mode and _ix > _legacy and _ck == "na":
            _viol.append(("decl-upper-newrow-unjudged", _ix, "前缀之外的行 decl_upper_checked=na ⇒ 新行未被 ③ 判"))
    if _viol:
        _names = sorted({v[0] for v in _viol})
        print("BASELINERATE=FAIL")
        print("BASELINERATE_REASON=FAIL %s 册级不变量被违反 %d 处：%s ⇒ reason=%s"
              % (",".join(_names), len(_viol), "; ".join("第%d行 %s" % (v[1], v[2]) for v in _viol[:4]), _names[0]))
        print("BASELINERATE_CASES=%d passed=%d failed=%d" % (len(rows), passed, failed + 1))
        print("BASELINERATE_RC=1"); return 1
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
        "# " + "\t".join(COLS_LEGACY),   # 表头必须是注释；且**刻意只列旧 8 列** ⇒ 该夹具是纯旧形态册（③ 不判，读数不变）
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
    # 🆕 `D-G121` 夹具（**10 列新形态**；表头声明新列 + `legacy_rows` 钉住前面的旧行）
    dg = os.path.join(sb, "cases-dg121.tsv")
    with open(dg, "w", encoding="utf-8") as fh:
        fh.write("\n".join(["# D-G121 夹具（确定性合成）",
                             "# " + "\t".join(COLS_NEW),
                             "# legacy_rows=0"] + [
            "d121-zero-k60-pass	0/60@2026-09-24T09:47:39+08:00+display=:215	0/60	0.04	0.0	PASS	0	PASS	0.0487	rule-of-three-0hit",
            "d121-nonzero-k126-zerohit-formula	1/126@2026-09-22T20:15:00+08:00	1/126	0.03	0.0	FAIL	1	zero-hit-formula-on-nonzero-sample	0.0235	rule-of-three-0hit",
            "d121-nonzero-k126-correct-pass	1/126@2026-09-22T20:15:00+08:00	1/126	0.03	0.0	PASS	0	PASS	0.0371	cp-1s",
            "d121-w98a-formula-value-mismatch	0/60@2026-09-24T09:47:39+08:00+display=:215	0/60	0.04	0.0	FAIL	1	decl-formula-value-mismatch	0.0494	rule-of-three-0hit",
            "d121-declared-cp-but-zerohit-value	1/126@2026-09-22T20:15:00+08:00	1/126	0.03	0.0	FAIL	1	decl-formula-value-mismatch	0.0235	cp-1s",
            "d121-optimistic-unmatched	1/126@2026-09-22T20:15:00+08:00	1/126	0.03	0.0	FAIL	1	decl-upper-optimistic	0.0300	-",
            "d121-conservative-unmatched	1/126@2026-09-22T20:15:00+08:00	1/126	0.03	0.0	NOINFO	3	NOINFO-DECL-UPPER-UNMATCHED	0.0500	-",
            "d121-decl-missing-new-header	24/27@2026-09-23T17:25:50+08:00	23/27	0.70	0.30	NOINFO	3	NOINFO-DECL-UPPER-MISSING	-	-",
            "d121-nonzero-k120-zerohit-formula	1/120@2026-09-22T20:15:00+08:00	1/120	0.03	0.0	FAIL	1	zero-hit-formula-on-nonzero-sample	0.0247	rule-of-three-0hit",
            "d121-newrow-regressed-to-oldform	24/27@2026-09-23T17:25:50+08:00	23/27	0.70	0.30	FAIL	1	decl-column-required-on-new-row",
        ]) + "\n")
    import io as _io, contextlib as _c2
    _b2 = _io.StringIO()
    with _c2.redirect_stdout(_b2): rc121 = run_cases(dg)
    print("SELFTEST_DG121_CASES_rc=%d" % rc121)
    ok = (rc == 0) and neg and (rc121 == 0)
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
        if a[i] in ("--registered", "--observed", "--gate", "--effect", "--cases", "--decl-upper", "--decl-formula"):
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
    return evaluate(kv["--registered"], kv["--observed"], kv["--gate"], kv["--effect"],
                    decl_upper=kv.get("--decl-upper"), decl_formula=kv.get("--decl-formula", "-"))

sys.exit(main(sys.argv[1:]))
PY

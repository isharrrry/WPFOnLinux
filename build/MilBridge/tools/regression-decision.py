#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# build/MilBridge/tools/regression-decision.py —— 「回归判定」的**唯一判据实现**（`TASK-0705` 的牙）
#
# ════════════════════════════════════════════════════════════════════════════════════════════
# 这份工具存在的唯一理由：本仓出过两类**判据级**事故，都是"一条腿一个样本就判回归"造成的。
#
#   ① `D-G99`（判据缺陷 · 样本量与随机性）：规则「`A` 臂红而 `B` 臂同腿绿 ⇒ 判回归」
#      对**间歇**现象**不充分** —— 一条腿一个样本**分不开"件相关"与"随机"** ⇒ 把间歇残留
#      **误判成回归**（方向 = **假红**）。现场：`W105A` 判据 §4 C3 **原文**就是这么写的，
#      实测 A 臂三条红腿在 B 臂同腿全绿，而 **B 臂自己在另一条腿上红了同一形态**；合计
#      **新 `3/36` vs 旧 `2/36` ⇒ Fisher 双尾 `p = 1.000`** ⇒ **判不出差别**。
#   ② `D-G94`（判据缺陷 · 分母口径）：把"**没点**"（`CLICK <name> SKIP dead`）算进分母
#      ⇒ **唯一一次真命中被自己的口径剔除**（方向 = **假绿/漏判**）。
#
# ⇒ 凡"**回归判定**"，**四要件缺一即只能记 `NOINFO`**（`docs/ROUTES.md` §15g 口径句）：
#     ① **两臂同刻**：同一装置、同一会话、**只换一个文件**（两个件都要带 sha16 前置断言）；
#     ② **成对归因臂**：同腿旧/新**交替**，N 对（对间交替先后，每趟全新进程树）；
#     ③ **复现性**：该红须**可复现**；**若在旧件上也能复现同一形态 ⇒ 不得称"本波引入"**；
#     ④ **统计口径**：Fisher 精确检验**双尾**；**分母只算"真尝试过的趟"**（`D-G94`）；
#        且**趟数与功效必须先写**（`D-G99`），本工具按现场速率反算"需要多少趟/臂"。
#
# ── 三态与退出码（**`NOINFO` 既不算绿也不算红**）────────────────────────────────────────────
#   `REGRESSION_DECISION=REGRESSION` ⇒ `rc=0`：四要件齐备 ∧ 差异显著 ∧ 功效达标 ∧ 计划在位。
#   `REGRESSION_DECISION=OK`         ⇒ `rc=0`：**判得出"不是回归"**（两臂皆 0 红；或旧件也复现
#                                        同一形态而两臂速率判不出差别；或新件那点红不显著）。
#   `REGRESSION_DECISION=NOINFO`     ⇒ `rc=3`：**要件缺输入**／**样本不足**（p 不显著而旧件 0 红）
#                                        ／**功效不足**／**计划缺位** ⇒ **不许当绿**。
#   `REGRESSION_DECISION=NOINFO`     ⇒ `rc=2`：**分母口径不合规**（`D-G94`：把没点的趟算进分母、
#                                        或总数与"跳过"对不上）⇒ **读数不可归因**，本工具**拒绝**，
#                                        并打 `REGDEC_REFUSE=<点名>`。⚠️ **不是第四态**：
#                                        `rc=2` 与 `rc=3` 都用 `NOINFO` 这一个词，区别只在**原因码**
#                                        （`rc=2` = 连分母都不可信；`rc=3` = 分母可信但证据不足）。
#
# ── Fisher 双尾的口径（**不是我发明的，是照仓内历史读数**钉出来的）────────────────────────────
#   2×2 表、固定边缘、超几何零分布，**双尾 = 所有"概率 ≤ 观测表概率"的表的概率之和**。
#   本实现被**四条仓内历史读数**逐字反证过（见 `--selftest` 的 `CROSSPATH` 断言）：
#     `D-G98  3/36 vs 2/36 ⇒ 1.000`｜`W112A 0/40 vs 2/16 ⇒ 0.078`｜
#     `W112A  0/40 vs 4/30 ⇒ 0.030`｜`W112A 1/1  vs 0/14 ⇒ 0.067`
#   （容差 = 四舍五入到三位小数后逐字相同）。工具内**两条独立数值路径**互相看住自己：
#     A = `math.lgamma` 对数域求和（主路径，快）｜B = `math.comb` 精确整数比（独立路径，慢）。
#   两者在**每一例**上必须一致，否则 `--selftest` 红（`CROSSPATH=FAIL`）。
#
# ── 所需趟数怎么算的（**先写趟数与功效**）────────────────────────────────────────────────────
#   等臂 N、Fisher 双尾、`alpha`、目标功效 `power`、备择 `(p_old, p_new)`：
#     功效(N) = P(拒绝 | 真速率 (p_old,p_new))  —— **精确枚举**，不用正态近似当答案。
#   先用正态近似定位 `n_approx ≈ (z_{α/2}+z_β)²·(p0(1-p0)+p1(1-p1))/(p1-p0)²`，
#   再在窗口 `[n_approx-40, min(NMAX, n_approx+60)]` 上**逐个精确求值并取最小 N**；
#   `n_approx > NMAX` ⇒ 印 `per_arm=CAP(>NMAX, approx≈…)`（**两臂速率太近 ⇒ 不是靠加趟数能判的**）。
#   ⚠️ 这一步与仓内另一条**独立**口径数（`0/N` 的 95% 单侧上界 `1-0.05^(1/N)`：`0/40 ⇒ 7.2%`、
#      `0/49 ⇒ 5.9%`）**回答的是不同问题**（区间 vs 功效）⇒ 两个数**都要报**，不许互相替代。
#
# ── 边界（**如实写，不许当绿**）──────────────────────────────────────────────────────────────
#   · 本工具**只吃计数**：它判不了"两臂是不是真的同刻"（①）、"是不是真的交替"（②）——
#     那两条只能靠**调用者给的断言**（`--same-time`、`--old-sha16/--new-sha16`、`--pairs`）＋ 人来看。
#     ⇒ 本工具的绿**只**等于"**给进去的那组计数**满足四要件"，**≠**"那组计数本身是真的"。
#   · **判据射程**：本工具判的是"**两臂速率有没有显著差别**"，**不判**"这个差是不是本波引入的"
#     —— 那需要**机制**（逐位可分的确定性判据／`D-G98` 那类外部观测器）⇒ 缺机制时最多到 `REGRESSION`，
#     措辞上**不许**升级成"已归因"。
#   · **`--old-repro=yes` 且显著** ⇒ 判 `REGRESSION` 但 `subkind=rate-aggravated`
#     （该红**本来就存在**、本波把速率**显著加重**）—— 这与"本波**引入**"**不是同一句话**。
#   · `--pairs` 只做**一致性核对**（`both+old_only == old_red` 等）：对不上一律 `NOINFO`。
#   · `--skipped-*`／`--*-total` 只用于**识别 `D-G94` 那个坑**；本工具**不替**记录层改分母。
#
# ── 用法 ────────────────────────────────────────────────────────────────────────────────────
#   regression-decision.py --old R/T --new R/T --pairs N --same-time \
#       --old-sha16 X --new-sha16 Y --old-repro no \
#       --planned-legs N --planned-power 0.80 [--alt-old P --alt-new P] [--json]
#   regression-decision.py --selftest
#   `R/T` 一律 = **红数 / 真尝试过的趟数**（`T` **必须**是真尝试的趟；见 `D-G94`）。
#
# 零 `dotnet`、零构建、纯读、只用 Python 标准库；单趟秒级。
# 建立者：车道 W117A（`TASK-0705`）。报告：`build/MilBridge/W117A-report.md`。
# ════════════════════════════════════════════════════════════════════════════════════════════

import argparse
import hashlib
import json
import math
import os
import subprocess
import sys
import tempfile
from math import comb

SELF = os.path.realpath(__file__)
ALPHA_DEFAULT = 0.05
POWER_DEFAULT = 0.80
NMAX_DEFAULT = 400
TOOLKEY = "REGDEC"

# ─────────────────────────────────────────────────────────────────────────────
# Fisher 精确检验（双尾）
# ─────────────────────────────────────────────────────────────────────────────
def _lchoose(n, k):
    if k < 0 or k > n:
        return float("-inf")
    return math.lgamma(n + 1) - math.lgamma(k + 1) - math.lgamma(n - k + 1)


def fisher_exact_log(a, b, c, d):
    """路径 A：对数域求和（主路径）。表 = [[a, b], [c, d]]。"""
    n = a + b + c + d
    r1 = a + b
    c1 = a + c
    lo = max(0, c1 - (n - r1))
    hi = min(r1, c1)
    if lo > hi:
        return 1.0
    logs = {}
    for x in range(lo, hi + 1):
        logs[x] = _lchoose(r1, x) + _lchoose(n - r1, c1 - x)
    obs = logs[a]
    m = max(logs.values())
    num = 0.0
    den = 0.0
    for v in logs.values():
        e = math.exp(v - m)
        den += e
        if v <= obs + 1e-9:
            num += e
    if den <= 0:
        return 1.0
    p = num / den
    return 1.0 if p > 1.0 else p


def fisher_exact_int(a, b, c, d):
    """路径 B：精确整数比（独立路径，只给 `--selftest` 与 `CROSSPATH` 用）。"""
    n = a + b + c + d
    r1 = a + b
    c1 = a + c
    lo = max(0, c1 - (n - r1))
    hi = min(r1, c1)
    if lo > hi:
        return 1.0
    denom = comb(n, c1)
    obs = comb(r1, a) * comb(n - r1, c1 - a)
    tot = 0
    for x in range(lo, hi + 1):
        v = comb(r1, x) * comb(n - r1, c1 - x)
        if v <= obs:
            tot += v
    return tot / denom


def fisher_2x2(old_red, old_tried, new_red, new_tried):
    return fisher_exact_log(old_red, old_tried - old_red, new_red, new_tried - new_red)


# ─────────────────────────────────────────────────────────────────────────────
# 功效 / 所需趟数
# ─────────────────────────────────────────────────────────────────────────────
def _binom_pmf(n, k, p):
    if p <= 0.0:
        return 1.0 if k == 0 else 0.0
    if p >= 1.0:
        return 1.0 if k == n else 0.0
    return comb(n, k) * (p ** k) * ((1.0 - p) ** (n - k))


def _sig_r1(old_red, n0, n1, alpha):
    """固定旧臂红数：返回新臂红数的**显著集合**（两个区间之并）＝ `(lo, hi)`：
    `[0, lo] ∪ [hi, n1]`；`lo = -1` / `hi = n1+1` 表示该侧空。"""
    lo = -1
    for r1 in range(0, n1 + 1):
        if fisher_exact_log(old_red, n0 - old_red, r1, n1 - r1) <= alpha:
            lo = r1
        else:
            break
    hi = n1 + 1
    for r1 in range(n1, -1, -1):
        if fisher_exact_log(old_red, n0 - old_red, r1, n1 - r1) <= alpha:
            hi = r1
        else:
            break
    return lo, hi


def power_at(p0, p1, n0, n1, alpha):
    """精确功效：P(Fisher 双尾 p ≤ alpha | 真速率 p0(旧臂), p1(新臂))。"""
    w0 = [_binom_pmf(n0, r, p0) for r in range(n0 + 1)]
    w1 = [_binom_pmf(n1, r, p1) for r in range(n1 + 1)]
    tot = 0.0
    for r0 in range(n0 + 1):
        if w0[r0] < 1e-15:
            continue
        lo, hi = _sig_r1(r0, n0, n1, alpha)
        if lo + 1 >= hi:
            s = 1.0
        else:
            s = 0.0
            if lo >= 0:
                s += sum(w1[0:lo + 1])
            if hi <= n1:
                s += sum(w1[hi:n1 + 1])
        tot += w0[r0] * s
    return tot


def _n_approx(p0, p1, alpha, power):
    """正态近似（只用于**定位搜索窗口**，不当答案）。"""
    if p0 == p1:
        return None
    z_a = _z(1.0 - alpha / 2.0)
    z_b = _z(power)
    v = p0 * (1 - p0) + p1 * (1 - p1)
    return (z_a + z_b) ** 2 * v / ((p1 - p0) ** 2)


def _z(q):
    """标准正态分位数（Acklam 有理逼近；够定位窗口用）。"""
    if q <= 0.0 or q >= 1.0:
        return float("nan")
    a = [-3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
         1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00]
    b = [-5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
         6.680131188771972e+01, -1.328068155288572e+01]
    c = [-7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
         -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00]
    d = [7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
         3.754408661907416e+00]
    pl = 0.02425
    if q < pl:
        t = math.sqrt(-2 * math.log(q))
        return (((((c[0] * t + c[1]) * t + c[2]) * t + c[3]) * t + c[4]) * t + c[5]) / \
               ((((d[0] * t + d[1]) * t + d[2]) * t + d[3]) * t + 1)
    if q > 1 - pl:
        t = math.sqrt(-2 * math.log(1 - q))
        return -(((((c[0] * t + c[1]) * t + c[2]) * t + c[3]) * t + c[4]) * t + c[5]) / \
                ((((d[0] * t + d[1]) * t + d[2]) * t + d[3]) * t + 1)
    t = q - 0.5
    r = t * t
    return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * t / \
           (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1)


def required_n(p0, p1, alpha, power, nmax):
    """返回 `(N, 实际功效, 说明)`；`N=None` ⇒ 窗口内没找到（印 CAP + 近似值）。"""
    na = _n_approx(p0, p1, alpha, power)
    if na is None:
        return None, None, "rates-equal"
    if na > nmax:
        return None, None, "approx=%.0f > NMAX=%d" % (na, nmax)
    lo = max(2, int(na) - 40)
    hi = min(nmax, int(na) + 60)
    for n in range(lo, hi + 1):
        pw = power_at(p0, p1, n, n, alpha)
        if pw >= power:
            return n, pw, "exact-window=[%d,%d] approx=%.1f" % (lo, hi, na)
    return None, None, "window-exhausted=[%d,%d] approx=%.1f" % (lo, hi, na)


def _mde(p0, n, alpha, power, grid=30, bisect=14):
    """**最小可检出效应**（MDE）：等臂 `n`、旧臂真速率 `p0`、给定 `alpha`/`power` 时，
    新臂真速率**至少要多大**才算"这个设计本来就能检出"。返回 `(p1, 达成功效)` 或 `(None, None)`。
    ⚠️ 这是"先写功效"那半句的**正确对照物**：观测后功效（`power_at(p0_obs,p1_obs,…)`）是 p 值的
    单调函数，拿它当门 = 偷偷把 `alpha` 改小 ⇒ 本工具**不**拿它当门，只印出来。
    做法 = 粗扫 + 二分（**近似**，报两位小数用）。"""
    if n <= 1:
        return None, None
    prev = None
    for i in range(1, grid + 1):
        x = p0 + (1.0 - p0) * i / float(grid)
        if power_at(p0, x, n, n, alpha) >= power:
            prev = x
            break
    if prev is None:
        return None, None
    lo, hi = max(p0, prev - (1.0 - p0) / grid), prev
    for _ in range(bisect):
        mid = (lo + hi) / 2.0
        if power_at(p0, mid, n, n, alpha) >= power:
            hi = mid
        else:
            lo = mid
    return hi, power_at(p0, hi, n, n, alpha)


def ci_upper_zero(N, conf=0.95):
    """`0/N` 的 95% **单侧**上界（Clopper-Pearson 精确）：`1 - (1-conf)^(1/N)`。"""
    if N <= 0:
        return 1.0
    return 1.0 - (1.0 - conf) ** (1.0 / N)


# ─────────────────────────────────────────────────────────────────────────────
# 输入解析 / 校验
# ─────────────────────────────────────────────────────────────────────────────
class Refuse(Exception):
    def __init__(self, code):
        self.code = code
        super().__init__(code)


def parse_rt(s, what):
    if "/" not in s:
        raise SystemExit("%s：%r 形态必须是 红数/真尝试趟数（例 3/36）" % (what, s))
    a, b = s.split("/", 1)
    try:
        r, t = int(a), int(b)
    except ValueError:
        raise SystemExit("%s：%r 里的数不是整数" % (what, s))
    if t < 0 or r < 0 or r > t:
        raise SystemExit("%s：%r 不自洽（要求 0 ≤ 红数 ≤ 趟数）" % (what, s))
    return r, t


def check_denominator(args):
    """`D-G94` 的守门：分母必须是"**真尝试过的趟**"。不合规 ⇒ **拒绝**（`rc=2`）。"""
    # (a) 显式声明用原始总数当分母 ⇒ 拒绝
    if args.denominator == "total":
        raise Refuse("denominator-not-tried(D-G94:分母只许算真尝试过的趟，原始总数含 SKIP dead 等没点的趟)")
    for arm in ("old", "new"):
        total = getattr(args, "%s_total" % arm)
        skipped = getattr(args, "%s_skipped" % arm)
        rt = getattr(args, arm)
        if total is None and skipped is None:
            continue
        if total is None or skipped is None:
            raise Refuse("denominator-unreconciled(%s臂:--%s-total 与 --%s-skipped 必须同时给 ⇒ 否则分母不可归因)"
                         % (arm, arm, arm))
        r, t = parse_rt(rt, "--%s" % arm)
        if t != total - skipped:
            raise Refuse("denominator-unreconciled(%s臂:%s 的趟数 %d ≠ 总数 %d − 跳过 %d = %d ⇒ D-G94 形态:D-G94:被剔掉的那几趟必须进不了分母)"
                         % (arm, arm, t, total, skipped, total - skipped))
        if skipped > 0 and getattr(args, "%s_repro" % arm) is None:
            pass  # 只记账，不判词


# ─────────────────────────────────────────────────────────────────────────────
# 判词
# ─────────────────────────────────────────────────────────────────────────────
def decision(args):
    """返回 dict：state / rc / reason / 各字段。"""
    old_red, old_tried = parse_rt(args.old, "--old")
    new_red, new_tried = parse_rt(args.new, "--new")
    alpha = args.alpha
    power_target = args.power

    out = {
        "repro_value": args.old_repro,
        "old_red": old_red, "old_tried": old_tried,
        "new_red": new_red, "new_tried": new_tried,
        "alpha": alpha, "power_target": power_target,
        "refuse": None, "gates": {}, "notes": [],
    }

    # ── 分母守门（`D-G94`）：不合规 ⇒ 拒绝
    try:
        check_denominator(args)
    except Refuse as e:
        out.update(state="NOINFO", rc=2, reason=None, refuse=e.code)
        return out

    # ── ③ 的取值必须与**旧臂红数**自洽（`F-B` 修复点）—— 与分母守门**同族**：
    #    要件值与计数**自相矛盾** ⇒ 归因不可信 ⇒ **拒绝**（`rc=2` ＋ 点名），不许换一条支路悄悄给判词。
    #    ⚠️⚠️ **位置 = 分母守门之后（就在上一行的 `except` 之后）**，这是**机械证**不是口味：
    #       台账行 `DG94-denominator-counts-skipped` 是 `old=7/9` ∧ `repro=no` ⇒ **正好命中 F-B2 形态**；
    #       而 `run_cases` **只比 `state`＋`rc`、不比 `reason`**（本件 run_cases 里那句
    #       `ok = (got_state == want_state and got_rc == want_rc)`）⇒ 本守卫若放到分母门**之前**，
    #       该行**仍 PASS**、但 `reason` 被顶成 `repro-inconsistent` ⇒ **静默丢掉「D-G94 分母门」那一格的覆盖**。
    #       （同一约束由 `--selftest` 的两条 `needles` 自动守卫：`denominator-unreconciled`／`denominator-not-tried`。）
    if args.old_repro == "yes" and old_red == 0:
        out.update(state="NOINFO", rc=2, reason=None,
                   refuse="repro-inconsistent(--old-repro yes 却旧臂红数=0/%d ⇒ ③ 的值与计数矛盾："
                          "旧件根本不复现该红，谈何「旧件也红」⇒ 拒绝，不许走 rate-aggravated 那条支路)" % old_tried)
        return out
    if args.old_repro == "no" and old_red > 0:
        out.update(state="NOINFO", rc=2, reason=None,
                   refuse="repro-inconsistent(--old-repro no 却旧臂红数=%d/%d ⇒ ③ 的值与计数矛盾："
                          "旧件也红就不能声明「只在原件红」⇒ 拒绝，否则子类名 deterministic/statistical-new-only 是假分类)"
                          % (old_red, old_tried))
        return out

    # ── 四要件：①②③④ 的**输入**是否在位
    gates = {}
    gates["same_time"] = bool(args.same_time)
    gates["sha16"] = bool(args.old_sha16 and args.new_sha16)
    gates["paired"] = bool(args.pairs and args.pairs > 0)
    gates["repro"] = args.old_repro in ("yes", "no")
    gates["plan"] = bool(args.planned_legs is not None and args.planned_power is not None)
    out["gates"] = dict(gates)

    missing = []
    if not gates["same_time"]:
        missing.append("missing-same-time-attest(①两臂同刻：同装置/同会话/只换一个文件 —— 必须显式断言)")
    if not gates["sha16"]:
        missing.append("missing-sha16-attest(①两个件都要带 sha16 前置断言)")
    if not gates["paired"]:
        missing.append("missing-paired-arm(②成对归因臂：--pairs N，同腿旧/新交替)")
    if not gates["repro"]:
        missing.append("missing-reproducibility(③--old-repro yes|no：该红在旧件上是否也复现)")
    if missing:
        out.update(state="NOINFO", rc=3, reason="+".join(x.split("(")[0] for x in missing),
                   missing=missing)
        return out

    # ── ② 成对臂一致性核对
    if args.pair_both is not None or args.pair_old_only is not None or args.pair_new_only is not None:
        pb = args.pair_both or 0
        po = args.pair_old_only or 0
        pn = args.pair_new_only or 0
        if pb + po != old_red or pb + pn != new_red or pb + po + pn > args.pairs:
            out.update(state="NOINFO", rc=3, reason="pair-inconsistent",
                       missing=["pair-inconsistent(成对数 both=%d old_only=%d new_only=%d 与两臂红数 %d/%d 对不上 ⇒ 读数不可归因)"
                                % (pb, po, pn, old_red, new_red)])
            return out

    # ── ④ Fisher 双尾
    p = fisher_2x2(old_red, old_tried, new_red, new_tried)
    out["fisher_p"] = p
    sig = p <= alpha

    # ── 所需趟数（**先写趟数与功效**）：现场点估计 + 可选备择
    p0_obs = old_red / old_tried if old_tried else 0.0
    p1_obs = new_red / new_tried if new_tried else 0.0
    if p1_obs < p0_obs:
        p0_obs, p1_obs = p1_obs, p0_obs          # 功效只与"速率差"有关 ⇒ 取"变坏"的那一侧
    n_obs, pw_obs, why_obs = required_n(p0_obs, p1_obs, alpha, power_target, args.nmax)
    out["req_n_obs"] = n_obs
    out["req_n_obs_power"] = pw_obs
    out["req_p0"] = p0_obs
    out["req_p1"] = p1_obs
    out["req_n_obs_why"] = why_obs
    out["ci0_old"] = ci_upper_zero(old_tried) if old_red == 0 else None
    out["ci0_new"] = ci_upper_zero(new_tried) if new_red == 0 else None

    if args.alt_old is not None or args.alt_new is not None:
        a0 = args.alt_old if args.alt_old is not None else p0_obs
        a1 = args.alt_new if args.alt_new is not None else p1_obs
        if a1 < a0:
            a0, a1 = a1, a0
        n_alt, pw_alt, why_alt = required_n(a0, a1, alpha, power_target, args.nmax)
        out["alt"] = {"old": a0, "new": a1, "n": n_alt, "power": pw_alt, "why": why_alt}

    # 现场这组计数在这个设计下的功效 —— ⚠️ **只作诊断，不当门**（理由见下）
    pw_now = power_at(p0_obs, p1_obs, old_tried, new_tried, alpha)
    out["power_now"] = pw_now
    # 「最小可检出效应」（MDE）：在**观测到的趟数**下、给定 alpha/power，旧臂速率 p0 时
    # 新臂速率要多大才算"本来就能检出"。它是"先写功效"那半句的**正确对照物**
    # （而不是"观测后功效"—— 后者是 p 值的单调函数，拿它当门 = 偷偷把 alpha 改小）。
    n_eff = args.pairs if args.pairs else min(old_tried, new_tried)
    out["mde"] = _mde(p0_obs, n_eff, alpha, power_target)
    out["mde_n"] = n_eff

    # ── ④ 先写趟数与功效（**设计入口条件**）：**必须在判词分支之前判** —— `F-A` 修复点（#58 / 车道 W150A）
    #    ⚠️ 旧写法把这三格**只放在 `old_repro == "no"` 支路里**（改前 :449-460）⇒ `--old-repro yes`
    #       那条支路（改前 :433-442）**先 return 了**、**永不经过它们** ⇒ 乱写的计划
    #       （`--planned-legs 99` 与现场 `pairs=16` 不符）**仍判 `REGRESSION`／`rc=0`** = **假绿**。
    #    ④ 是"**实验之前**先写死"的东西（`D-G99`）⇒ 它是**设计的入口条件**，不是事后借口；
    #       故：**任何判词（含 `OK`/`REGRESSION`/`not-significant`）都不许在计划不合规时给出**。
    #    位置约束（两条，都有机械证）：
    #      ① **必须晚于"①②③ 在位"那扇门** —— 否则"缺 pairs ∧ 缺计划"会被顶成 `plan-absent`、
    #         把 `missing-paired-arm` 那一格的覆盖丢掉。
    #      ② **必须晚于全部诊断行**（本处）—— 否则既有的三例会**少印 5 行诊断**（实测）。
    #         计划不合规**不等于**"统计不用算"：`p` 与所需趟数照印，供人留档；**只是不许据此下判词**。
    if not gates["plan"]:
        out.update(state="NOINFO", rc=3,
                   reason="plan-absent(④先写趟数与功效：缺 --planned-legs/--planned-power ⇒ 事后挑样本量不许判回归)")
        return out
    if args.planned_legs != args.pairs:
        out.update(state="NOINFO", rc=3,
                   reason="plan-mismatch(planned_legs=%d ≠ 现场成对臂 pairs=%d ⇒ 计划与现场不一致)" % (args.planned_legs, args.pairs))
        return out
    if args.planned_power < power_target:
        out.update(state="NOINFO", rc=3,
                   reason="planned-power-below-target(计划功效 %.2f < 目标 %.2f ⇒ 计划本身功效不足)" % (args.planned_power, power_target))
        return out

    # ── 判词
    if new_red == 0 and old_red == 0:
        out.update(state="OK", rc=0, reason="no-red-either-arm(两臂都 0 红 ⇒ 没有可归因的差异)")
        return out

    if args.old_repro == "yes":
        # ③：该红**在旧件上也复现** ⇒ 是既有现象 ⇒ 不得称"本波引入"
        if not sig:
            out.update(state="OK", rc=0,
                       reason="pre-existing-reproduces-on-old(fisher_p=%.4g>alpha=%.3g；旧件也红同一形态 ⇒ 判不出差别，不是本波引入)" % (p, alpha))
            return out
        out.update(state="REGRESSION", rc=0, subkind="rate-aggravated",
                   reason="rate-aggravated(fisher_p=%.4g≤alpha 且旧件也红 ⇒ 该红**本来就存在**、本波把速率**显著加重**；⚠️这不是「本波引入」)" % p)
        out["notes"].append("subkind=rate-aggravated 与「本波引入」不是同一句话（见本件头注释·边界）")
        return out

    # old_repro == "no"：旧件 0 红
    if not sig:
        out.update(state="NOINFO", rc=3,
                   reason="not-significant(fisher_p=%.4g>alpha=%.3g 且旧件 0 红 ⇒ 分不开「随机」与「件相关」；见 D-G99)" % (p, alpha))
        return out
    # ⚠️ ④ 的三格**已前移**到本函数开头（`F-A` 修复点，见上面的注释块）⇒ 这里**不再重复**；
    #    留此注释是为了让"改前为什么 `--old-repro yes` 能假绿"这件事在源码里可追。
    if new_red == new_tried:
        out.update(state="REGRESSION", rc=0, subkind="deterministic-new-only",
                   reason="deterministic-new-only(fisher_p=%.4g≤alpha；新臂 %d/%d **每腿都红** ⇒ 确定性复现 ∧ 旧件 0/%d)" % (p, new_red, new_tried, old_tried))
        return out
    out.update(state="REGRESSION", rc=0, subkind="statistical-new-only",
               reason="statistical-new-only(fisher_p=%.4g≤alpha ∧ 计划在位(legs=%d,power=%.2f,与现场一致) ⇒ 差异不是随机；⚠️观测后功效=%.4f 只作诊断(它是 p 的单调函数)" % (p, args.planned_legs, args.planned_power, pw_now))
    return out


# ─────────────────────────────────────────────────────────────────────────────
# 输出
# ─────────────────────────────────────────────────────────────────────────────
def emit(d, args):
    st = d["state"]
    print("REGRESSION_DECISION=%s" % st)
    print("REGDEC_RC=%d" % d["rc"])
    print("REGDEC_TABLE old=%d/%d new=%d/%d alpha=%g power_target=%.2f"
          % (d["old_red"], d["old_tried"], d["new_red"], d["new_tried"], d["alpha"], d["power_target"]))
    if d.get("refuse"):
        print("REGDEC_REFUSE=%s" % d["refuse"])
    if d.get("fisher_p") is not None:
        print("REGDEC_FISHER p=%.6f two_tailed=yes method=hypergeometric-le-observed"
              % d["fisher_p"])
        # `F-C`（`#58`）：**危险窗** = `p` 的三位小数落在 `alpha` 上（例 `p=0.050152 ⇒ 0.050`）。
        # 口径句 = "**判定一律用机器行原值，三位小数只作显示**"（册 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2984`）。
        # 下面这行把**两种读法并排**印出来、逐字标注，
        # 从物理上排除"拿 `0.050` 去比 `0.05`"这条读法。**不改判词**：`verdict_input` 就是上面那行 `state`。
        _pr = d["fisher_p"]
        print("REGDEC_ALPHA p_raw=%.6f p_display_only=%.3f alpha=%g decide=raw compare=%s verdict_input=%s"
              % (_pr, _pr, d["alpha"], "le" if _pr <= d["alpha"] else "gt", d["state"]))
    g = d.get("gates") or {}
    if g:
        # ⚠️ `repro_input` 印的是**③那一格的取值**（`yes`/`no`/`absent`），不是"给没给"
        #    —— "给没给"看 `absent` 与否；这两件事在旧写法里被同一个 `yes` 混住了。
        print("REGDEC_GATES same_time=%s sha16=%s paired=%s repro_input=%s plan=%s"
              % ("yes" if g.get("same_time") else "no",
                 "yes" if g.get("sha16") else "no",
                 "yes" if g.get("paired") else "no",
                 d.get("repro_value") or "absent",
                 "yes" if g.get("plan") else "no"))
    if d.get("mde") and d["mde"][0] is not None:
        print("REGDEC_MDE n_per_arm=%d p0=%.4f min_detectable_p1=%.3f power=%.4f（本设计**本来**能检出的最小效应；"
              "观测后功效只作诊断、不当门）"
              % (d.get("mde_n", 0), d.get("req_p0", 0.0), d["mde"][0], d["mde"][1]))
    if d.get("power_now") is not None:
        print("REGDEC_POWER_NOW observed=%.4f target=%.2f" % (d["power_now"], d["power_target"]))
    if d.get("req_n_obs") is not None:
        print("REGDEC_REQUIRED_N_OBS per_arm=%d power=%.4f observed_rates=%.4f-vs-%.4f window=%s"
              % (d["req_n_obs"], d.get("req_n_obs_power", 0.0),
                 d.get("req_p0", 0.0), d.get("req_p1", 0.0), d.get("req_n_obs_why", "")))
    elif d.get("req_n_obs_why"):
        print("REGDEC_REQUIRED_N_OBS per_arm=CAP %s" % d["req_n_obs_why"])
    if d.get("alt"):
        a = d["alt"]
        if a["n"] is not None:
            print("REGDEC_REQUIRED_N_ALT per_arm=%d power=%.4f alt_rates=%.4f-vs-%.4f window=%s"
                  % (a["n"], a["power"], a["old"], a["new"], a["why"]))
        else:
            print("REGDEC_REQUIRED_N_ALT per_arm=CAP alt_rates=%.4f-vs-%.4f %s"
                  % (a["old"], a["new"], a["why"]))
    if d.get("ci0_old") is not None:
        print("REGDEC_CI0_OLD 0/%d 的单侧95%%上界=%.4f" % (d["old_tried"], d["ci0_old"]))
    if d.get("ci0_new") is not None:
        print("REGDEC_CI0_NEW 0/%d 的单侧95%%上界=%.4f" % (d["new_tried"], d["ci0_new"]))
    if d.get("subkind"):
        print("REGDEC_SUBKIND=%s" % d["subkind"])
    for m in d.get("missing", []) or []:
        print("REGDEC_MISSING %s" % m)
    print("REGDEC_REASON reason=%s" % (d.get("reason") or "-"))
    if args.json:
        print("REGDEC_JSON " + json.dumps({k: v for k, v in d.items() if k != "missing"},
                                          sort_keys=True, ensure_ascii=False))
    if not args.quiet:
        print("  ∟ 判词：%s（rc=%d）" % (d.get("reason") or d.get("refuse"), d["rc"]))
        print("  ∟ 铁律：`NOINFO` **既不算绿也不算红**；本工具判的是「两臂速率有没有显著差别」，")
        print("     **不判**「这个差是不是本波引入的」（那要机制，见本件头注释·边界）。")
    return d["rc"]


# ─────────────────────────────────────────────────────────────────────────────
# 台账模式：`--cases FILE`（**接线用**：让这颗牙真咬"当波的真读数"，而不是只自测）
#   目的：凡本波**声称做过回归判定**，它的成对读数就必须进台账，且**判词必须与台账里sound
#   声明的期望一致** ⇒ 换个人来跑、换一代来跑，判词不许变。
#   台账形态（TSV、TAB 分隔、`#` 注释行、空行忽略；**列序固定**，见下表）：
#     name  old  new  pairs  repro  planned_legs  planned_power  alt_old  alt_new  denominator  old_total  old_skipped  want_state  want_rc
#   `-` 表示"该格不给"。`want_state ∈ REGRESSION|NOINFO|OK`；`want_rc ∈ 0|2|3`。
#   ⚠️ **台账不是"判据"**：它只是"**我声明的期望**"；牙判的是"工具给的判词 == 声明的期望"
#      ∧ "每一行都必须显式声明 `want_state`/`want_rc`"（缺声明 ⇒ `NOINFO`，不许当绿）。
COLUMNS = ["name", "old", "new", "pairs", "repro", "planned_legs", "planned_power",
           "alt_old", "alt_new", "denominator", "old_total", "old_skipped",
           "want_state", "want_rc"]


def read_cases(path):
    rows = []
    bad = []
    with open(path, encoding="utf-8") as f:
        for ln, raw in enumerate(f, 1):
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            parts = line.split("\t")
            parts = [x.strip() for x in parts]
            if len(parts) != len(COLUMNS):
                bad.append("line=%d cols=%d（要求 %d）" % (ln, len(parts), len(COLUMNS)))
                continue
            rows.append(dict(zip(COLUMNS, parts)))
    return rows, bad


def _val(row, key):
    v = row.get(key)
    if v is None or v in ("-", ""):
        return None
    return v


def run_cases(path, quiet=False):
    rows, bad = read_cases(path)
    if bad:
        print("REGRESSION_LEDGER=NOINFO reason=malformed file=%s %s" % (path, "; ".join(bad)))
        return 2
    if not rows:
        print("REGRESSION_LEDGER=NOINFO reason=empty file=%s" % path)
        return 2
    npass = nfail = 0
    for row in rows:
        name = row["name"]
        if _val(row, "want_state") is None or _val(row, "want_rc") is None:
            print("LEDGER ROW %-30s = NOINFO reason=missing-declared-expectation" % name)
            print("REGRESSION_LEDGER=NOINFO reason=row-missing-expectation name=%s" % name)
            return 2
        ns = argparse.Namespace()
        ns.old = _val(row, "old")
        ns.new = _val(row, "new")
        ns.pairs = int(_val(row, "pairs")) if _val(row, "pairs") else None
        ns.pair_both = ns.pair_old_only = ns.pair_new_only = None
        ns.same_time = True
        ns.old_sha16 = ns.new_sha16 = "ledger"
        ns.old_repro = _val(row, "repro")
        ns.planned_legs = int(_val(row, "planned_legs")) if _val(row, "planned_legs") else None
        ns.planned_power = float(_val(row, "planned_power")) if _val(row, "planned_power") else None
        ns.alt_old = float(_val(row, "alt_old")) if _val(row, "alt_old") else None
        ns.alt_new = float(_val(row, "alt_new")) if _val(row, "alt_new") else None
        ns.denominator = _val(row, "denominator") or "tried"
        ns.old_total = int(_val(row, "old_total")) if _val(row, "old_total") else None
        ns.new_total = None
        ns.old_skipped = int(_val(row, "old_skipped")) if _val(row, "old_skipped") else None
        ns.new_skipped = None
        ns.alpha = ALPHA_DEFAULT
        ns.power = POWER_DEFAULT
        ns.nmax = NMAX_DEFAULT
        ns.json = False
        ns.quiet = True
        d = decision(ns)
        got_state, got_rc = d["state"], d["rc"]
        want_state, want_rc = _val(row, "want_state"), int(_val(row, "want_rc"))
        ok = (got_state == want_state and got_rc == want_rc)
        if ok:
            npass += 1
        else:
            nfail += 1
        print("LEDGER ROW %-30s = %-4s old=%s new=%s state=%s want=%s rc=%s want_rc=%s reason=%s"
              % (name, "PASS" if ok else "FAIL", row["old"], row["new"],
                 got_state, want_state, got_rc, want_rc, d.get("reason") or d.get("refuse")))
    print("REGRESSION_LEDGER_ROSTER file=%s rows=%d pass=%d fail=%d" % (path, len(rows), npass, nfail))
    if nfail == 0:
        print("REGRESSION_LEDGER=PASS rows=%d pass=%d fail=0" % (len(rows), npass))
        return 0
    print("REGRESSION_LEDGER=FAIL rows=%d pass=%d fail=%d" % (len(rows), npass, nfail))
    return 1


# ─────────────────────────────────────────────────────────────────────────────
# --selftest（**必须两极化**）
# ─────────────────────────────────────────────────────────────────────────────
SHA = "0123456789abcdef"


def _fixture_args(**kw):
    base = dict(old=None, new=None, pairs=None, pair_both=None, pair_old_only=None,
                pair_new_only=None, same_time=False, old_sha16=None, new_sha16=None,
                old_repro=None, planned_legs=None, planned_power=None,
                alpha=ALPHA_DEFAULT, power=POWER_DEFAULT, alt_old=None, alt_new=None,
                old_total=None, new_total=None, old_skipped=None, new_skipped=None,
                denominator="tried", nmax=NMAX_DEFAULT, json=False, quiet=True)
    base.update(kw)
    return argparse.Namespace(**base)


def _ok(args):
    return _fixture_args(
        same_time=True, old_sha16=SHA, new_sha16=SHA,
        planned_legs=(args.pairs if args.pairs else None), planned_power=POWER_DEFAULT,
        **{k: v for k, v in vars(args).items() if k not in ("same_time", "old_sha16", "new_sha16",
                                                            "planned_legs", "planned_power")})


CASES = []


def case(name, args, want_state, want_rc, needles=()):
    CASES.append((name, args, want_state, want_rc, needles))


def build_cases():
    # ① 旧件也红（成对臂）⇒ OK（不是回归）—— `D-G99` 的**假红方向**必须被拦住
    case("repro-on-old-OK", _ok(_fixture_args(old="3/16", new="4/16", pairs=16,
                                             pair_both=3, pair_old_only=0, pair_new_only=1,
                                             old_repro="yes")),
         "OK", 0, ("REGDEC_FISHER p=1.000000",))
    # ② 只在原件红 + 确定性（5/5）+ 计划在位 ⇒ REGRESSION
    case("deterministic-new-only-REGRESSION",
         _ok(_fixture_args(old="0/5", new="5/5", pairs=5, pair_both=0,
                           pair_old_only=0, pair_new_only=5, old_repro="no")),
         "REGRESSION", 0, ("REGDEC_SUBKIND=deterministic-new-only", "p=0.007937"))
    # ③ 现场那组：16 腿 6%（新 1/16 vs 旧 0/16）⇒ NOINFO **并且印出所需趟数**
    case("sixteen-legs-six-percent-NOINFO",
         _ok(_fixture_args(old="0/16", new="1/16", pairs=16, pair_both=0,
                           pair_old_only=0, pair_new_only=1, old_repro="no")),
         "NOINFO", 3, ("REGDEC_REQUIRED_N_OBS per_arm=126",))
    # ③b 同一例 + 备择 6% vs 0%（**本波报告引用的那个数**）
    case("sixteen-legs-alt-6pct-NOINFO",
         _ok(_fixture_args(old="0/16", new="1/16", pairs=16, pair_both=0,
                           pair_old_only=0, pair_new_only=1, old_repro="no",
                           alt_old=0.0, alt_new=0.06)),
         "NOINFO", 3, ("REGDEC_REQUIRED_N_ALT per_arm=131",))
    # ④ 缺成对臂 ⇒ NOINFO
    case("missing-paired-arm-NOINFO",
         _ok(_fixture_args(old="0/5", new="5/5", old_repro="no")),
         "NOINFO", 3, ("REGDEC_MISSING missing-paired-arm(②成对归因臂",))
    # ⑤ 分母把 SKIP 算进去（D-G94 现场形态：9 击里 2 击 SKIP dead ⇒ 真尝试 7）⇒ **拒绝** rc=2
    case("denominator-counts-skipped-REFUSE",
         _ok(_fixture_args(old="7/9", new="4/9", pairs=9, old_repro="no",
                           old_total=9, old_skipped=2)),
         "NOINFO", 2, ("REGDEC_REFUSE=denominator-unreconciled",))
    # ⑤b 直接声明"用原始总数当分母" ⇒ 拒绝
    case("denominator-total-REFUSE",
         _ok(_fixture_args(old="7/9", new="4/9", pairs=9, old_repro="no", denominator="total")),
         "NOINFO", 2, ("REGDEC_REFUSE=denominator-not-tried",))
    # ⑥ 历史重放（`D-G98` 现场）：3/36 vs 2/36 ⇒ p=1.000 ⇒ OK（**不许判回归**）
    case("historical-DG98-OK",
         _ok(_fixture_args(old="2/36", new="3/36", pairs=36, old_repro="yes")),
         "OK", 0, ("REGDEC_FISHER p=1.000000",))
    # ⑦ 两臂全绿 ⇒ OK
    case("both-green-OK", _ok(_fixture_args(old="0/16", new="0/16", pairs=16, old_repro="no")),
         "OK", 0, ("reason=no-red-either-arm",))
    # ⑧ 新件那点红**不显著**（0/16 vs 4/16 ⇒ p=0.101）⇒ NOINFO
    case("new-only-not-significant-NOINFO",
         _ok(_fixture_args(old="0/16", new="4/16", pairs=16, old_repro="no")),
         "NOINFO", 3, ("REGDEC_FISHER p=0.101224", "reason=not-significant"))
    # ⑨ 显著 ∧ 功效够，但**没先写趟数/功效** ⇒ NOINFO（④的"先写"这一半）
    a = _ok(_fixture_args(old="0/5", new="5/5", pairs=5, old_repro="no"))
    a.planned_legs = None
    a.planned_power = None
    case("plan-absent-NOINFO", a, "NOINFO", 3, ("reason=plan-absent",))
    # ⑩ 缺 ① 的同刻断言 ⇒ NOINFO
    b = _ok(_fixture_args(old="0/5", new="5/5", pairs=5, old_repro="no"))
    b.same_time = False
    case("missing-same-time-NOINFO", b, "NOINFO", 3, ("REGDEC_MISSING missing-same-time-attest",))
    # ⑫ 显著 ∧ 计划在位（非确定性、间歇）⇒ REGRESSION（`statistical-new-only`）
    case("significant-intermittent-REGRESSION",
         _ok(_fixture_args(old="0/16", new="5/16", pairs=16, old_repro="no")),
         "REGRESSION", 0, ("REGDEC_SUBKIND=statistical-new-only", "p=0.043382"))
    # ⑬ 显著但**计划功效不足** ⇒ NOINFO（④的"功效"这一半）
    c = _ok(_fixture_args(old="0/5", new="5/5", pairs=5, old_repro="no"))
    c.planned_power = 0.50
    case("planned-power-below-target-NOINFO", c, "NOINFO", 3,
         ("reason=planned-power-below-target",))
    # ⑭ 显著但**计划趟数与现场不符** ⇒ NOINFO
    e = _ok(_fixture_args(old="0/5", new="5/5", pairs=5, old_repro="no"))
    e.planned_legs = 40
    case("plan-mismatch-NOINFO", e, "NOINFO", 3, ("reason=plan-mismatch",))
    # ⑪ 成对臂自相矛盾 ⇒ NOINFO
    case("pair-inconsistent-NOINFO",
         _ok(_fixture_args(old="0/5", new="5/5", pairs=5, pair_both=0, pair_old_only=0,
                           pair_new_only=4, old_repro="no")),
         "NOINFO", 3, ("reason=pair-inconsistent",))
    # ⑮ `F-A` 正极性：`--old-repro yes` ＋ **乱写的计划** ⇒ 必须 `NOINFO/plan-mismatch`（改前是假绿 `REGRESSION`）
    f = _ok(_fixture_args(old="3/16", new="10/16", pairs=16, old_repro="yes"))
    f.planned_legs = 99
    f.planned_power = 0.1
    case("f-a-plan-mismatch-on-repro-yes-NOINFO", f, "NOINFO", 3, ("reason=plan-mismatch",))
    # ⑯ `F-B` 正极性 1：`repro=yes` 却**旧臂 0 红** ⇒ 拒绝（改前判 `REGRESSION/rate-aggravated`，理由自相矛盾）
    case("f-b-repro-yes-but-old-zero-REFUSE",
         _ok(_fixture_args(old="0/5", new="4/5", pairs=5, old_repro="yes")),
         "NOINFO", 2, ("REGDEC_REFUSE=repro-inconsistent",))
    # ⑰ `F-B` 正极性 2：`repro=no` 却**旧臂 >0 红** ⇒ 拒绝（改前给假分类 `statistical-new-only`）
    case("f-b-repro-no-but-old-red-REFUSE",
         _ok(_fixture_args(old="3/16", new="10/16", pairs=16, old_repro="no")),
         "NOINFO", 2, ("REGDEC_REFUSE=repro-inconsistent",))
    # ⑱ `F-C` 危险窗：`0/25 vs 5/25 ⇒ p=0.050152`（三位 = `0.050`）⇒ 机判 `NOINFO`；
    #    新行**并排**印原值与只供显示的三位 ⇒ 从物理上排除"拿 0.050 比 0.05"
    case("f-c-alpha-display-window-NOINFO",
         _ok(_fixture_args(old="0/25", new="5/25", pairs=25, old_repro="no")),
         "NOINFO", 3, ("REGDEC_FISHER p=0.050152", "p_display_only=0.050", "compare=gt",
                       "decide=raw"))


# `CROSSPATH`：两条独立数值路径 + **四条仓内历史读数**（判据 `C2b`）
CROSSPATH = [
    ("D-G98  3/36 vs 2/36", (3, 33, 2, 34), 1.000),
    ("W112A  0/40 vs 2/16", (0, 40, 2, 14), 0.078),
    ("W112A  0/40 vs 4/30", (0, 40, 4, 26), 0.030),
    ("W112A  1/1  vs 0/14", (1, 0, 0, 14), 0.067),
]
# 功效算法的**外部**锚（独立实现 `~/w117a/proto2.py` 的穷举值；值本身来自报告 §3）
POWER_ANCHORS = [(0.0, 0.06, 131), (0.0, 0.0625, 126), (0.0, 0.059, 133),
                 (0.0, 0.125, 62), (0.0, 0.10, 78), (0.0, 0.0625, 126)]
# MDE 的**外部**锚（独立穷举实现 `~/w117a/mde_check.py`；容差 ±0.006 = 一格粗扫）
MDE_ANCHORS = [(0.0, 16, 0.385), (0.0, 36, 0.211), (0.0556, 36, 0.324), (0.0, 126, 0.0625)]


def self_sha16():
    try:
        with open(SELF, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()[:16]
    except OSError:
        return "NOINFO"


def run_selftest():
    """外层自测：每个 fixture 用**真件**（`python3 SELF …`）跑一遍，断言**判词 + rc + 关键字段**。"""
    s0 = self_sha16()
    print("REGDEC_SELFTEST_SELF self=%s sha16=%s" % (SELF, s0))
    build_cases()
    env = dict(os.environ)
    env["REGDEC_ST_INNER"] = "1"
    py = sys.executable or "python3"
    total = passed = failed = 0
    for name, args, want_state, want_rc, needles in CASES:
        total += 1
        argv = fixture_argv(args)
        r = subprocess.run([py, SELF] + argv, capture_output=True, text=True, env=env)
        blob = r.stdout
        got_state = None
        for ln in blob.splitlines():
            if ln.startswith("REGRESSION_DECISION="):
                got_state = ln.split("=", 1)[1].strip()
        miss = [n for n in needles if n not in blob]
        ok = (got_state == want_state and r.returncode == want_rc and not miss)
        if ok:
            passed += 1
        else:
            failed += 1
        print("SELFTEST CASE %-34s = %-4s rc=%s want_rc=%s state=%s want=%s%s"
              % (name, "PASS" if ok else "FAIL", r.returncode, want_rc,
                 got_state, want_state,
                 "" if ok else ("  missing=" + repr(miss) + "  out=" + blob[-500:].replace("\n", " | "))))
    # CROSSPATH：两条独立数值路径 + 四条历史读数
    cp_ok = True
    for label, tab, want in CROSSPATH:
        pa = fisher_exact_log(*tab)
        pb = fisher_exact_int(*tab)
        good = (abs(round(pa, 3) - want) < 1e-9 and abs(round(pb, 3) - want) < 1e-9
                and abs(pa - pb) < 1e-9)
        cp_ok = cp_ok and good
        print("SELFTEST CROSSPATH %-22s A=%.6f B=%.6f want3=%.3f %s"
              % (label, pa, pb, want, "= OK" if good else "= FAIL"))
    # POWER：功效算法与独立穷举实现给出的所需趟数逐个相同
    pw_ok = True
    for p0, p1, want_n in POWER_ANCHORS:
        n, pw, why = required_n(p0, p1, ALPHA_DEFAULT, POWER_DEFAULT, NMAX_DEFAULT)
        good = (n == want_n)
        pw_ok = pw_ok and good
        print("SELFTEST POWER %-18s N=%s want=%d power=%s %s"
              % ("%.3f-vs-%.4f" % (p0, p1), n, want_n,
                 "None" if pw is None else "%.4f" % pw, "= OK" if good else "= FAIL"))
    # MDE：与独立穷举实现给出的值逐个吻合（容差 ±0.006）
    mde_ok = True
    for p0, n, want in MDE_ANCHORS:
        got, pw = _mde(p0, n, ALPHA_DEFAULT, POWER_DEFAULT)
        good = (got is not None and abs(got - want) <= 0.006)
        mde_ok = mde_ok and good
        print("SELFTEST MDE n=%-4d p0=%-7.4f MDE=%s want=%.4f power=%s %s"
              % (n, p0, "None" if got is None else "%.4f" % got, want,
                 "None" if pw is None else "%.4f" % pw, "= OK" if good else "= FAIL"))
    # **互逆核对**：`required_n(0, MDE_N) ≈ N` —— 两条**方向相反**的算法必须咬合
    inv_ok = True
    for p0, n, want in [(0.0, 126, 0.0625), (0.0, 40, 0.1905)]:
        m, _ = _mde(p0, n, ALPHA_DEFAULT, POWER_DEFAULT)
        back, bpw, _ = required_n(p0, m, ALPHA_DEFAULT, POWER_DEFAULT, NMAX_DEFAULT)
        good = (back is not None and abs(back - n) <= 2)
        inv_ok = inv_ok and good
        print("SELFTEST MDE-INVERSE n=%d MDE=%.4f required_n(MDE)=%s %s"
              % (n, m, back, "= OK" if good else "= FAIL"))
    # 台账模式（`--cases`）：正极性（5 行全对 ⇒ PASS）＋ **反极性**（把台账里"声明的期望"
    #   改坏一行 ⇒ 必须 FAIL —— 否则"台账模式"是空转的橡皮图章）
    ledger_ok = ledger_pol = False
    _tb = tempfile.TemporaryDirectory(prefix="regdec-st.")
    try:
        f = os.path.join(_tb.name, "cases.tsv")
        with open(f, "w", encoding="utf-8") as fh:
            fh.write("# fixture（本件自测用；与仓内台账无关）\n" + "\n".join([
                "a\t0/16\t1/16\t16\tno\t16\t0.80\t-\t-\ttried\t-\t-\tNOINFO\t3",
                "b\t0/5\t5/5\t5\tno\t5\t0.80\t-\t-\ttried\t-\t-\tREGRESSION\t0",
                "c\t2/36\t3/36\t36\tyes\t36\t0.80\t-\t-\ttried\t-\t-\tOK\t0",
                "d\t7/9\t4/9\t9\tno\t9\t0.80\t-\t-\ttried\t9\t2\tNOINFO\t2",
                "e\t0/16\t0/16\t16\tno\t16\t0.80\t-\t-\ttried\t-\t-\tOK\t0",
            ]) + "\n")
        rr = subprocess.run([py, SELF, "--cases", f], capture_output=True, text=True, env=env)
        ledger_ok = (rr.returncode == 0 and "REGRESSION_LEDGER=PASS" in rr.stdout
                     and "rows=5" in rr.stdout)
        print("SELFTEST LEDGER --cases rows=5 %s"
              % ("= OK" if ledger_ok else "= FAIL  " + rr.stdout[-300:].replace("\n", " | ")))
        fb = os.path.join(_tb.name, "bad.tsv")
        with open(fb, "w", encoding="utf-8") as fh:
            fh.write("x\t0/16\t1/16\t16\tno\t16\t0.80\t-\t-\ttried\t-\t-\tREGRESSION\t0\n")
        rb = subprocess.run([py, SELF, "--cases", fb], capture_output=True, text=True, env=env)
        ledger_pol = (rb.returncode == 1 and "REGRESSION_LEDGER=FAIL" in rb.stdout)
        print("SELFTEST LEDGER-POLARITY 台账期望被改坏 ⇒ FAIL %s"
              % ("= OK" if ledger_pol else "= FAIL  rc=%d" % rb.returncode))
    finally:
        _tb.cleanup()
    s1 = self_sha16()
    if s0 != s1:
        print("ST_ATTEST=NOINFO reason=self-rewritten-during-selftest self=%s sha0=%s sha1=%s"
              % (SELF, s0, s1))
        failed += 1
        total += 1
    else:
        print("ST_ATTEST=PASS self=%s sha16=%s（自测期间本件未变 ⇒ 上面读数可归因）" % (SELF, s0))
    total += 6
    for flag in (cp_ok, pw_ok, mde_ok, inv_ok, ledger_ok, ledger_pol):
        if flag:
            passed += 1
        else:
            failed += 1
    print("REGDEC_SELFTEST_ROSTER cases=%d pass=%d fail=%d" % (total, passed, failed))
    if failed == 0:
        print("REGDEC_SELFTEST=PASS total=%d pass=%d fail=0" % (total, passed))
        return 0
    print("REGDEC_SELFTEST=FAIL total=%d pass=%d fail=%d" % (total, passed, failed))
    return 1


def fixture_argv(a):
    """把一个 fixture 的 Namespace 翻成命令行（**必须**走真 CLI ⇒ 测的是真解析路径）。"""
    v = []
    for k, flag in [("old", "--old"), ("new", "--new"),
                    ("old_sha16", "--old-sha16"), ("new_sha16", "--new-sha16"),
                    ("old_repro", "--old-repro"), ("pairs", "--pairs"),
                    ("pair_both", "--pair-both"), ("pair_old_only", "--pair-old-only"),
                    ("pair_new_only", "--pair-new-only"), ("planned_legs", "--planned-legs"),
                    ("planned_power", "--planned-power"), ("alt_old", "--alt-old"),
                    ("alt_new", "--alt-new"), ("old_total", "--old-total"),
                    ("new_total", "--new-total"), ("old_skipped", "--old-skipped"),
                    ("new_skipped", "--new-skipped"), ("nmax", "--nmax")]:
        val = getattr(a, k)
        if val is not None:
            v += [flag, str(val)]
    if getattr(a, "same_time", False):
        v += ["--same-time"]
    v += ["--denominator", a.denominator, "--alpha", str(a.alpha), "--power", str(a.power), "--quiet"]
    return v


# ─────────────────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(
        prog="regression-decision.py",
        description="回归判定四要件（TASK-0705）：两臂同刻 + 成对归因臂 + 复现性 + Fisher 双尾；缺一即 NOINFO。")
    ap.add_argument("--old", help="旧件臂 = 红数/真尝试过的趟数（例 3/36）")
    ap.add_argument("--new", help="新件臂 = 红数/真尝试过的趟数")
    ap.add_argument("--pairs", type=int, help="②成对归因臂的对数（同腿旧/新交替）")
    ap.add_argument("--pair-both", type=int, help="成对臂：两臂都红的对数（一致性核对）")
    ap.add_argument("--pair-old-only", type=int, help="成对臂：只旧件红的对数")
    ap.add_argument("--pair-new-only", type=int, help="成对臂：只新件红的对数")
    ap.add_argument("--same-time", action="store_true", help="①断言：两臂同刻（同装置/同会话/只换一个文件）")
    ap.add_argument("--old-sha16", help="①旧件 sha16 前置断言")
    ap.add_argument("--new-sha16", help="①新件 sha16 前置断言")
    ap.add_argument("--old-repro", choices=["yes", "no"],
                    help="③该红在旧件上是否也复现（yes|no）")
    ap.add_argument("--planned-legs", type=int, help="④先写的趟数")
    ap.add_argument("--planned-power", type=float, help="④先写的功效")
    ap.add_argument("--alpha", type=float, default=ALPHA_DEFAULT)
    ap.add_argument("--power", type=float, default=POWER_DEFAULT)
    ap.add_argument("--alt-old", type=float, help="备择旧臂速率（算所需趟数用；默认取现场点估计）")
    ap.add_argument("--alt-new", type=float, help="备择新臂速率")
    ap.add_argument("--old-total", type=int, help="旧臂原始总数（配 --old-skipped 做 D-G94 核对）")
    ap.add_argument("--new-total", type=int)
    ap.add_argument("--old-skipped", type=int, help="旧臂里**没点/跳过**的趟数（D-G94：不进分母）")
    ap.add_argument("--new-skipped", type=int)
    ap.add_argument("--denominator", choices=["tried", "total"], default="tried",
                    help="分母口径；给 total ⇒ 本工具**拒绝**（D-G94）")
    ap.add_argument("--nmax", type=int, default=NMAX_DEFAULT, help="所需趟数搜索上限（超出印 CAP）")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--quiet", action="store_true")
    ap.add_argument("--cases", help="台账 TSV：逐行跑真判词并与行内**声明**的期望比对（接线用）")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()

    if args.selftest:
        if os.environ.get("REGDEC_ST_INNER") == "1":
            # 内层不该再进 selftest（防递归）
            args.selftest = False
        else:
            return run_selftest()
    if args.cases:
        return run_cases(args.cases)
    if not args.old or not args.new:
        ap.error("--old 与 --new 必给（形态 红数/趟数）；只在 --selftest/--cases 时可省")
    d = decision(args)
    rc = emit(d, args)
    return rc


if __name__ == "__main__":
    sys.exit(main())

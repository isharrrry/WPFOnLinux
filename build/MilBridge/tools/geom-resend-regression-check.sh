#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# geom-resend-regression-check —— **桥侧几何重发的确定性回归牙**
#                                 （`TASK-0110` 改题后：**第二块**）
#
# 【它挡的是什么】`D-G98` 那一族的**真成因**：`WM` 已执行"退出最大化的几何还原"之后 **+85 ms**，
#   桥用**裸 `ConfigureWindow`** 把 client 几何**改回屏尺寸**（`WC03` 归因终局；`W134A` 的 `TASK-0210`
#   修在 `src/WpfGfx.Linux/Interop/MilPresentation.cs` 的 `OwnsWindow` 分支：接窗路径**只读尺寸、不写几何**）。
#   本牙把这件事做成**确定性**判据 —— 它**不靠红率**（`D-G98` 家族口径：承重判据不许只靠红率）：
#     修后臂（`4e25e4b27d4d5ae1`）：**每腿** 协议层命中 = 0 **∧ 同腿具名正控 `[GEOWRITE-SUPPRESSED] ≥ 1`**
#     修前臂（`feef049e9d0e313a`）：命中**回升**（先写界 `≥ 0.70`）∧ 正控**回到 0**
#   ⇒ **既有台账足以判死 ⇒ 本牙零重跑、零编译、零 `dotnet`。**
#
# ─────────────────────────────────────────────────────────────────────────────
# 【判据（**先写死**）】
#   `R1` 分组：**一律按趟印的 `BRIDGE=<sha16>` 分组，绝不按腿名分组。**
#      反例现场实证：`W134A-POL-OLD-1/2` 名字带 `OLD`，趟印 `BRIDGE=4e25e4b27d4d5ae1`（**修后件**）
#      ⇒ 牙**主动检测并打印** `NAMETRAP`（检测 ≠ 判红；分组只认 `BRIDGE=`）。
#   每腿四元组 = `(BRIDGE, CFG_HIT, GEOWRITE, r_ok)`：
#      `CFG_HIT`  = `xwrap.log` 里 `PROTO` 行 ∧ **与 `~/w134a/bin/leg.sh:127` 逐字相同的字节模式**
#                   `0c 02 05 00 04 00 c0 00` 的行数（**本牙独立复算**，不信脚本自报）；
#      `GEOWRITE` = `mil.log` 里 `[GEOWRITE-SUPPRESSED]` 的行数（**具名正控**：证明真的到达被测分支）；
#      `r_ok`     = `probe.txt: RESULT` 行的 `r_ok=`。
#      **对账**：独立复算的 `CFG_HIT` 必须 == 同趟 `probe.txt` 打印的 `CFG_1280_1024_HITS=`；
#              不等 ⇒ 该腿 `COUNT_MISMATCH`（**计数不可信 ⇒ 该腿判 NOINFO**，不许静默用自报值）。
#   `R2` 承重（确定性）：修后臂 **100% 腿** `CFG_HIT == 0` ∧ **100% 腿** `GEOWRITE ≥ 1` ∧ **100% 腿** `r_ok == 1`
#      ⇒ 任一违反 = `FAIL`（修后方向**不允许**出现命中，也**不允许**正控缺席）。
#   `R3` 修前臂：**只判"回升＋成对"，禁止判"每腿必命中"**（本族在修前臂上**是间歇的**）。
#      回升界（先写）= `CFG_HIT ≥ 1` 的腿占比 **`≥ 0.70`** ∧ 严格大于修后臂占比（修后 = 0.00）；
#      且修前臂 **100% 腿** `GEOWRITE == 0`。
#      ⚠️ **反例必须单列**：`CFG_HIT == 0 ∧ r_ok == 1` 的修前臂腿打 `COUNTEREXAMPLE`（现场 1/17）
#        ⇒ **不得**据此判 `FAIL`（那是把"间歇"当"不存在"）。
#   `R4` 成对性：全语料 `CFG_HIT ≥ 1 ⟺ r_ok == 0`，**反例逐条列名**。
#   `R5` 腿数：每臂 `n ≥ 3`，否则该臂 `NOINFO`；缺 `probe.txt`/`xwrap.log`/`mil.log` 的腿**不计入分母**
#      并**逐条列名**（不许静默丢弃）。
#   **三态**：`NOINFO` **既不算绿也不算红**。
#
# 【用法】
#   bash build/MilBridge/tools/geom-resend-regression-check.sh --selftest
#   bash build/MilBridge/tools/geom-resend-regression-check.sh --corpus="$HOME/w134a/run" [--verify-arms]
#   `--fix=<sha16>` / `--pre=<sha16>` 可换臂（**真换臂**：这两个值直接进判据的分组与角色判定，不只是打印；相等 ⇒ 拒载 `USAGE_ERR`；传进来的 sha 若不在语料里 ⇒ 该臂无腿 ⇒ 顶层 `NOINFO single-arm`）；  [W153A-#61]
#   `--pattern='0c 02 05 00 04 00 c0 00'` 可换命中模式（默认与 `leg.sh` 逐字相同）。
#   `--verify-arms` 另在**给定目录集合**里现算 `wpfgfx_cor3.so` 的 sha16 与尺寸，确认两臂件都在盘上
#   （缺 ⇒ 该格 `NOINFO` 并点名；**不**影响四元组判词）。
#
# 【机制】纯只读：`python3` ＋ `grep` 级扫描，秒级；**不跑** `dotnet`／不跑应用腿／不改任何产品件、
#   不改 `verify-all.sh`（**接线由主控编排**）。仪器件只读复用：`~/wc03/bin/xwrap.so`
#   `b5c1c1dbc4c0f13d`（协议层 `PROTO` 行，`xwrap.c:337`）。
# ═══════════════════════════════════════════════════════════════════════════════
set -u
exec python3 - "$@" <<'PYEOF'
import os, re, sys, glob, hashlib, tempfile

FIX_SHA = "4e25e4b27d4d5ae1"     # 修后桥件（TASK-0210 已修）
PRE_SHA = "feef049e9d0e313a"     # 修前桥件（同尺寸 5,028,208 B，**同尺寸不同内容**）
DEFAULT_PATTERN = "0c 02 05 00 04 00 c0 00"   # 与 ~/w134a/bin/leg.sh:127 逐字相同
RISEUP_MIN = 0.70                # 修前臂"回升"先写界
MIN_LEGS_PER_ARM = 3
ARM_DIRS = ["~/w89a/app", "~/w134a/app", "~/w114a/app", "~/wc03/app", "~/wc11/app"]

def sha16_file(p):
    h = hashlib.sha256()
    try:
        with open(p, "rb") as f:
            for c in iter(lambda: f.read(1 << 20), b""):
                h.update(c)
    except OSError:
        return None
    return h.hexdigest()[:16]

def read_leg(d, pattern, fix=FIX_SHA, pre=PRE_SHA):
    """→ dict（缺件一律显式记账，不静默丢弃）；[W153A-#61] `fix`/`pre` 决定 `nametrap` 按哪一对臂判"""
    leg = os.path.basename(d.rstrip("/"))
    probe, xw, ml = (os.path.join(d, n) for n in ("probe.txt", "xwrap.log", "mil.log"))
    out = dict(leg=leg, bridge="?", r_ok=None, printed=None, cfg_hit=None, geowrite=None, missing=[])
    for p, n in ((probe, "probe.txt"), (xw, "xwrap.log"), (ml, "mil.log")):
        if not os.path.exists(p):
            out["missing"].append(n)
    if not os.path.exists(probe):
        return out
    txt = open(probe, errors="replace").read()
    res = ""
    for ln in txt.splitlines():
        if ln.startswith("RESULT "):
            res = ln
    m = re.search(r"\bBRIDGE=(\S+)", res)
    if m: out["bridge"] = m.group(1)
    m = re.search(r"\br_ok=(\d)", res)
    if m: out["r_ok"] = m.group(1)
    m = re.search(r"\bCFG_1280_1024_HITS=(\d+)", txt)
    if m: out["printed"] = int(m.group(1))
    if os.path.exists(xw):
        out["cfg_hit"] = sum(1 for ln in open(xw, errors="replace") if "PROTO" in ln and pattern in ln)
    if os.path.exists(ml):
        out["geowrite"] = sum(1 for ln in open(ml, errors="replace") if "GEOWRITE-SUPPRESSED" in ln)
    out["reconcile"] = ("n/a" if (out["cfg_hit"] is None or out["printed"] is None)
                        else ("OK" if out["cfg_hit"] == out["printed"] else "COUNT_MISMATCH"))
    out["nametrap"] = name_trap(leg, out["bridge"], fix, pre)
    return out

def name_trap(leg, bridge, fix=FIX_SHA, pre=PRE_SHA):
    """腿名里的 OLD/NEW **不等于**桥件的旧/新 —— 名字与趟印 BRIDGE 冲突时点名（分组仍只认 BRIDGE）"""
    u = leg.upper()
    if "OLD" in u and bridge == fix: return "name=OLD>bundle=fix"
    if "NEW" in u and bridge == pre: return "name=NEW>bundle=pre"
    return ""

def classify_row(r):
    """→ 该腿的有效四元组（计数对不上或缺件 ⇒ None ⇒ 该腿判 NOINFO、不计入分母）"""
    if r["missing"] or r["bridge"] == "?" or r["cfg_hit"] is None or r["geowrite"] is None or r["r_ok"] is None:
        return None
    if r["reconcile"] == "COUNT_MISMATCH":
        return None
    return (r["bridge"], r["cfg_hit"], r["geowrite"], r["r_ok"])

def judge(rows, fix=FIX_SHA, pre=PRE_SHA):
    """核心判词（供 main 与 --selftest 共用）→ dict(verdict, reason, arms, counters）
    ⚠️ [W153A-#61] `D-G113` 修：`fix`/`pre` **必须**从 `main` 传进来（`--fix=`/`--pre=` 直接决定「谁是修的臂」）—— 修前本函数只认模块级常量 ⇒ 两个开关只改 `NOTE` 打印（假旋钮）。"""
    from collections import defaultdict
    arms = defaultdict(list)
    excluded = []
    for r in rows:
        v = classify_row(r)
        if v is None:
            excluded.append(r["leg"]); continue
        arms[v[0]].append((r["leg"], v[1], v[2], v[3], r["nametrap"]))
    res = dict(arms={}, excluded=excluded, counterexamples=[], nametraps=[],
               pair_violations=[], fixes=[])
    for b, ds in arms.items():
        red = sum(1 for _, h, g, ok, _ in ds if h >= 1)
        grn = sum(1 for _, h, g, ok, _ in ds if h == 0 and ok == "1")
        gw0 = sum(1 for _, h, g, ok, _ in ds if g == 0)
        role = "fix" if b == fix else ("pre" if b == pre else "unknown")
        rate = (red / len(ds)) if ds else 0.0
        if len(ds) < MIN_LEGS_PER_ARM:
            v, why = "NOINFO", "legs<%d（腿数不足）" % MIN_LEGS_PER_ARM
        elif role == "fix":
            bad = []
            if any(h >= 1 for _, h, _, _, _ in ds): bad.append("有腿 CFG_HIT≥1（修后方向必须 0）")
            if any(g < 1 for _, _, g, _, _ in ds): bad.append("有腿 GEOWRITE=0（**正控缺席** ⇒ 没到达被测分支）")
            if any(ok != "1" for _, _, _, ok, _ in ds): bad.append("有腿 r_ok≠1")
            v, why = ("FAIL", "；".join(bad)) if bad else ("PASS", "每腿 CFG_HIT=0 ∧ GEOWRITE≥1 ∧ r_ok=1（确定性）")
        elif role == "pre":
            bad = []
            if rate < RISEUP_MIN: bad.append("回升率 %.2f < 先写界 %.2f" % (rate, RISEUP_MIN))
            fixds = arms.get(fix) or []
            fixrate = (sum(1 for _, h, _, _, _ in fixds if h >= 1) / len(fixds)) if fixds else None
            if fixrate is not None and not (rate > fixrate):
                bad.append("回升率 %.3f 未严格大于修后臂占比 %.3f" % (rate, fixrate))
            if any(g != 0 for _, _, g, _, _ in ds): bad.append("有腿 GEOWRITE≠0")
            v, why = ("FAIL", "；".join(bad)) if bad else (
                "PASS", "回升率 %.2f ≥ %.2f ∧ 正控全 0（**只判回升，不许要求每腿必命中**）" % (rate, RISEUP_MIN))
        else:
            v, why = "NOINFO", "未分类臂（不参与成对判词，如实列出）"
        res["arms"][b] = dict(role=role, n=len(ds), red=red, green=grn, geowrite0=gw0, rate=rate, verdict=v, why=why)
    # R4 成对性 + R3 反例
    for b, ds in arms.items():
        for leg, h, g, ok, nt in ds:
            if (h >= 1) != (ok == "0"):
                res["pair_violations"].append("%s(HIT=%d r_ok=%s)" % (leg, h, ok))
            if b == pre and h == 0 and ok == "1":
                res["counterexamples"].append(leg)
            if nt:
                res["nametraps"].append("%s(%s)" % (leg, nt))
    roles = {v["role"]: (b, v) for b, v in res["arms"].items()}
    if not ("fix" in roles and "pre" in roles):
        res["verdict"], res["reason"] = "NOINFO", "single-arm（成对判词需修前＋修后两臂同场）"
        return res
    fix_b, fix_v = roles["fix"]; pre_b, pre_v = roles["pre"]
    if fix_v["verdict"] == "FAIL":
        res["verdict"], res["reason"] = "FAIL", "fix_arm=%s" % fix_v["why"]
    elif fix_v["verdict"] == "NOINFO":
        res["verdict"], res["reason"] = "NOINFO", "fix_arm=%s" % fix_v["why"]
    elif pre_v["verdict"] == "FAIL":
        res["verdict"], res["reason"] = "FAIL", "pre_arm=%s" % pre_v["why"]
    elif pre_v["verdict"] == "NOINFO":
        res["verdict"], res["reason"] = "NOINFO", "pre_arm=%s" % pre_v["why"]
    else:
        res["verdict"], res["reason"] = "PASS", "fix_arm 确定性成立 ∧ pre_arm 回升成立（成对）"
    return res

def synth_leg(sandbox, name, bridge, cfg_hit, geowrite, r_ok, printed=None, with_files=True):
    d = os.path.join(sandbox, name); os.makedirs(d, exist_ok=True)
    if with_files:
        with open(os.path.join(d, "probe.txt"), "w") as f:
            f.write("RESULT tag=%s M=M1 R=R2 START_MAX=0 BASE=800x600@+0+0 BRIDGE=%s SHIM=x "
                    "r_ok=%s\nMEMAVAIL_END_MB=100 XWRAP_PROTO_LINES=9 CFG_1280_1024_HITS=%d MIL_RESIZE_LINES=0\n"
                    % (name, bridge, r_ok, cfg_hit if printed is None else printed))
        with open(os.path.join(d, "xwrap.log"), "w") as f:
            for _ in range(cfg_hit):
                f.write("T 1790000000000001 rel=1.0 pid=1 tid=1 PROTO fd=9 n=24 op0=12 "
                        "head=0c 02 05 00 04 00 c0 00 0c 00 e0 00  | chain: [hook]\n")
            f.write("T 1790000000000002 rel=2.0 pid=1 tid=1 PROTO fd=9 n=4 op0=133 head=85 00 01 00  | chain: [hook]\n")
        with open(os.path.join(d, "mil.log"), "w") as f:
            for _ in range(geowrite):
                f.write("NOTE [GEOWRITE-SUPPRESSED] HWND 0xc00004 接窗路径不回写 X 几何\n")
    return d

def selftest():
    sb = tempfile.mkdtemp(prefix="geomresend-selftest-")
    cases = []
    # 1) 两臂都合判 ⇒ PASS
    d1 = os.path.join(sb, "case1"); os.makedirs(d1)
    for i in range(3): synth_leg(d1, "L-NEW-%d" % i, FIX_SHA, 0, 1, "1")
    for i in range(3): synth_leg(d1, "L-OLD-%d" % i, PRE_SHA, 1, 0, "0")
    cases.append(("both_arms_ok", d1, "PASS", "两臂各自合判 ⇒ 成对 PASS"))
    # 2) 修后臂 1 腿命中 ⇒ FAIL（确定性被破）
    d2 = os.path.join(sb, "case2"); os.makedirs(d2)
    for i in range(3): synth_leg(d2, "L-NEW-%d" % i, FIX_SHA, 0, 1, "1")
    synth_leg(d2, "L-NEW-9", FIX_SHA, 1, 1, "1")
    for i in range(3): synth_leg(d2, "L-OLD-%d" % i, PRE_SHA, 1, 0, "0")
    cases.append(("fix_hit", d2, "FAIL", "修后臂出现命中 ⇒ FAIL"))
    # 3) 修后臂 1 腿正控缺席 ⇒ FAIL
    d3 = os.path.join(sb, "case3"); os.makedirs(d3)
    for i in range(3): synth_leg(d3, "L-NEW-%d" % i, FIX_SHA, 0, 1, "1")
    synth_leg(d3, "L-NEW-9", FIX_SHA, 0, 0, "1")
    for i in range(3): synth_leg(d3, "L-OLD-%d" % i, PRE_SHA, 1, 0, "0")
    cases.append(("fix_no_geowrite", d3, "FAIL", "修后臂正控缺席 ⇒ FAIL"))
    # 4) 修前臂 3/4 命中（含 1 反例）⇒ 仍 PASS ＋ 必须打 COUNTEREXAMPLE
    d4 = os.path.join(sb, "case4"); os.makedirs(d4)
    for i in range(3): synth_leg(d4, "L-NEW-%d" % i, FIX_SHA, 0, 1, "1")
    for i in range(3): synth_leg(d4, "L-OLD-%d" % i, PRE_SHA, 1, 0, "0")
    synth_leg(d4, "L-OLD-3", PRE_SHA, 0, 0, "1")     # 反例：命中 0 且绿
    cases.append(("pre_counterexample", d4, "PASS", "修前臂 3/4=0.75 ≥ 先写界 ⇒ 回升成立（**不许要求每腿必命中**）＋ 反例单列"))
    # 4b) **先写界的已知性质**：n=3 的小臂上 2/3=0.667 < 0.70 ⇒ FAIL（如实登记，不偷偷放宽阈值）
    d4b = os.path.join(sb, "case4b"); os.makedirs(d4b)
    for i in range(3): synth_leg(d4b, "L-NEW-%d" % i, FIX_SHA, 0, 1, "1")
    synth_leg(d4b, "L-OLD-0", PRE_SHA, 1, 0, "0")
    synth_leg(d4b, "L-OLD-1", PRE_SHA, 1, 0, "0")
    synth_leg(d4b, "L-OLD-2", PRE_SHA, 0, 0, "1")
    cases.append(("pre_small_n", d4b, "FAIL", "**n=3 的小臂上 0.70 界很紧**：2/3<0.70 ⇒ FAIL（先写界的性质，不偷偷放宽）"))
    # 5) 腿数不足 ⇒ NOINFO
    d5 = os.path.join(sb, "case5"); os.makedirs(d5)
    for i in range(2): synth_leg(d5, "L-NEW-%d" % i, FIX_SHA, 0, 1, "1")
    for i in range(3): synth_leg(d5, "L-OLD-%d" % i, PRE_SHA, 1, 0, "0")
    cases.append(("too_few_legs", d5, "NOINFO", "修后臂 2 腿 < 3 ⇒ NOINFO"))
    # 6) 命名陷阱 ⇒ 仍 PASS ＋ 打 NAMETRAP
    d6 = os.path.join(sb, "case6"); os.makedirs(d6)
    for i in range(3): synth_leg(d6, "L-NEW-%d" % i, FIX_SHA, 0, 1, "1")
    for i in range(3): synth_leg(d6, "L-OLD-%d" % i, PRE_SHA, 1, 0, "0")
    synth_leg(d6, "L-POL-OLD-1", FIX_SHA, 0, 1, "1")     # 名字带 OLD，桥件是修后 ⇒ NAMETRAP
    cases.append(("nametrap", d6, "PASS", "腿名 OLD 但 BRIDGE=修后 ⇒ 打 NAMETRAP，分组仍按 BRIDGE"))
    # 7) 计数对不上 ⇒ 该腿 NOINFO（不计入分母）
    d7 = os.path.join(sb, "case7"); os.makedirs(d7)
    for i in range(3): synth_leg(d7, "L-NEW-%d" % i, FIX_SHA, 0, 1, "1")
    synth_leg(d7, "L-NEW-9", FIX_SHA, 1, 1, "0", printed=0)   # 复算 1 ≠ 自报 0 ⇒ COUNT_MISMATCH
    for i in range(3): synth_leg(d7, "L-OLD-%d" % i, PRE_SHA, 1, 0, "0")
    cases.append(("count_mismatch", d7, "PASS", "复算与自报不等 ⇒ 该腿 NOINFO（不计入分母，不许静默用自报值）"))
    ok = 0
    print("== 两极化自测（合成台账；计数/缺件/命名/腿数四类边界各一例）")
    for name, d, want, note in cases:
        rows = [read_leg(os.path.join(d, n), DEFAULT_PATTERN) for n in sorted(os.listdir(d))]
        r = judge(rows)
        good = r["verdict"] == want
        extra = ""
        if name == "pre_counterexample":
            good = good and len(r["counterexamples"]) == 1
            extra = "counterexamples=%s" % r["counterexamples"]
        if name == "nametrap":
            good = good and len(r["nametraps"]) == 1
            extra = "nametraps=%s" % r["nametraps"]
        if name == "count_mismatch":
            good = good and r["excluded"] == ["L-NEW-9"]
            extra = "excluded=%s" % r["excluded"]
        ok += 1 if good else 0
        print("   %-18s want=%-7s got=%-7s %-9s %s %s"
              % (name, want, r["verdict"], "OK" if good else "MISMATCH", extra, note))
        if not good: print("        reason=%s excluded=%s" % (r["reason"], r["excluded"]))
    print("GEOMRESEND_SELFTEST=%d/%d" % (ok, len(cases)))
    return 0 if ok == len(cases) else 1

def main(argv):
    corpus, legs, pattern, verify = [], [], DEFAULT_PATTERN, False
    fix, pre = FIX_SHA, PRE_SHA
    for a in argv:
        if a == "--selftest": return selftest()
        elif a.startswith("--corpus="): corpus.append(os.path.expanduser(a.split("=", 1)[1]))
        elif a.startswith("--leg="): legs.append(os.path.expanduser(a.split("=", 1)[1]))
        elif a.startswith("--pattern="): pattern = a.split("=", 1)[1]
        elif a.startswith("--fix="): fix = a.split("=", 1)[1]
        elif a.startswith("--pre="): pre = a.split("=", 1)[1]
        elif a == "--verify-arms": verify = True
        elif a in ("-h", "--help"): print("见本文件头注释【用法】"); return 0
        else:   # [W153A-#61] 修前**静默忽略**未认参数 —— 打错一个字母就会得到「开关没起作用」的假实验
            print("GEOMRESEND=NOINFO reason=USAGE_ERR unknown-arg=%s（本牙不认这个参数；"
                  "静默忽略参数正是 D-G113 的另一半 ⇒ 现在拒载）" % a)
            print("USAGE_ERR=unknown-arg value=%s rc=2" % a)
            return 2
    if fix == pre:      # [W153A-#61] 两个角色塌成一个 ⇒ 判据无意义（**显式拒**，不许静默）
        print("GEOMRESEND=NOINFO reason=USAGE_ERR fix==pre（%s）：两个角色塌成一个，"
              "「换臂」不可能成立 ⇒ 拒载" % fix)
        print("USAGE_ERR=fix-eq-pre value=%s rc=2" % fix)
        return 2
    if not corpus and not legs:
        corpus = [os.path.expanduser("~/w134a/run")]
    for c in corpus:
        legs += sorted(p for p in glob.glob(os.path.join(c, "*")) if os.path.isdir(p))
    if not legs:
        print("GEOMRESEND=NOINFO reason=no-input（给 --corpus=<root> 或 --leg=<dir>）")
        return 2
    rows = [read_leg(d, pattern, fix, pre) for d in legs]
    for r in rows:
        print("RESEND leg=%-24s bridge=%-18s cfg_hit=%-5s geowrite=%-5s r_ok=%-5s printed=%-5s reconcile=%-15s nametrap=%s"
              % (r["leg"], r["bridge"], r["cfg_hit"], r["geowrite"], r["r_ok"], r["printed"],
                 r["reconcile"], r["nametrap"] or "-"))
    print("NOTE pattern=%s（与 leg.sh:127 逐字相同）fix=%s pre=%s riseup_min=%.2f min_legs=%d"
          % (pattern, fix, pre, RISEUP_MIN, MIN_LEGS_PER_ARM))
    res = judge(rows, fix, pre)   # [W153A-#61] `--fix=`/`--pre=` **真的**进判据
    for b, v in sorted(res["arms"].items()):
        print("ARM bridge=%-18s role=%-8s n=%-3d hit_legs=%-3d rate=%-6.3f geowrite0=%-3d verdict=%-7s why=%s"
              % (b, v["role"], v["n"], v["red"], v["rate"], v["geowrite0"], v["verdict"], v["why"]))
    for c in res["counterexamples"]:
        print("COUNTEREXAMPLE leg=%s（修前臂上 CFG_HIT=0 且 r_ok=1 —— **边界例/反例，如实单列，不得据此判红**）" % c)
    for n in res["nametraps"]:
        print("NAMETRAP leg=%s（腿名与趟印 BRIDGE 冲突 ⇒ **分组只认 BRIDGE=**）" % n)
    for v in res["pair_violations"]:
        print("PAIR_VIOLATION leg=%s（命中≥1 ⟺ r_ok=0 的成对性出现反例 ⇒ 逐条列名）" % v)
    if res["excluded"]:
        print("EXCLUDED legs=%s（缺件或计数对不上 ⇒ **不计入分母**，如实单列）" % ",".join(res["excluded"]))
    if verify:
        for d in ARM_DIRS:
            p = os.path.join(os.path.expanduser(d), "wpfgfx_cor3.so")
            s = sha16_file(p) if os.path.exists(p) else None
            sz = (os.path.getsize(p) if os.path.exists(p) else None)
            tag = "fix" if s == fix else ("pre" if s == pre else "other")
            print("ARMFILE dir=%-18s sha16=%-18s size=%-10s role=%s" % (d, s or "ABSENT", sz or "-", tag))
        found = set()
        for d in ARM_DIRS:
            p = os.path.join(os.path.expanduser(d), "wpfgfx_cor3.so")
            s = sha16_file(p) if os.path.exists(p) else None
            if s in (fix, pre): found.add(s)
        print("ARMVERIFY fix_present=%s pre_present=%s note=%s"
              % ("yes" if fix in found else "NO", "yes" if pre in found else "NO",
                 "两臂件都在盘上 ⇒ 反极性不需重编" if {fix, pre} <= found
                 else "**缺臂件 ⇒ 该格 NOINFO**（点名：见上表 ABSENT）"))
    print("GEOMRESEND=%s reason=%s legs=%d arms=%d excluded=%d counterexamples=%d pair_violations=%d nametraps=%d load_bearing=fix_arm_determinism riseup_min=%.2f"
          % (res["verdict"], res["reason"], len(rows), len(res["arms"]), len(res["excluded"]),
             len(res["counterexamples"]), len(res["pair_violations"]), len(res["nametraps"]), RISEUP_MIN))
    return 0 if res["verdict"] == "PASS" else (1 if res["verdict"] == "FAIL" else 2)

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
PYEOF

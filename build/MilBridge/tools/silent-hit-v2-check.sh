#!/usr/bin/env bash
# ============================================================================
# silent-hit-v2-check.sh —— `SILENT_SEGV_HIT`**第一支（v2 口径）**的仓内牙（**纯读、零 `dotnet`、秒级**）
#
# 【它防什么】`D-G123`：判据第一支 = 「应用输出 0 B」，在**现件代**上**结构性不可达**
#   （应用每趟启动自报 `[HC-UNHANDLED] #N` ⇒ 旧口径恒 `≠0`）⇒ **"零命中"与"没有该现象"不可区分**
#   ⇒ 拿它验 `#55`/`#57` 必然是假绿。本件把修法（v2）做成**会咬的牙**：三条件**合取** ∧ 第三支**具名** ∧
#   **阳性对照是门槛** ∧ 跨件代**禁止合池** ∧ 剔除集**从文件读、行首锚定**、**两个数都印**。
#
# 【三态与 rc】（与 `nul-bytes-check.sh`／`fp-inputs-hygiene-check.sh` 刻意同形）
#   `SILENTHIT=PASS`   rc=0 ：台账每一行都判成它声明的判词 ∧ **阳性对照至少一行真 HIT**
#   `SILENTHIT=FAIL`   rc=1 ：判词与声明不符／**阳性对照不成立（`reason=untriggerable`）**／
#                            台账行数与 `--expect` 不符／产出端机读行**缺字段或陈旧**
#   `SILENTHIT=NOINFO` rc=2 ：**查不动**——台账缺文件／空表／**缺列**／非整数／**零行被检查**
#   `SILENTHIT=FAIL`   rc=3 ：用法错误
#   ⚠️ **零检查必须报红**（纪律 5）：`examined == 0` **一律 `NOINFO rc=2`**，**永不给 `PASS`**；
#      ⚠️ `NOINFO` **既不算绿也不算红**；也**不许**把"没有数"读成 `0`（产出端缺字段 ⇒ `FAIL`，不是 `NOINFO`）。
#
# 【用法（本件的两种主形态 ＋ 三种旁证形态）】
#   silent-hit-v2-check.sh --selftest
#        判据本体的自检（合取／四支具名／退化实现必翻／三态齐备）＋ **两条 NOINFO 两极**。
#   silent-hit-v2-check.sh --cases <台账.tsv> [--expect <N>]      ← **`verify-all` 走这条**
#        `--cases` = **确定性用例台账**（每行「判定输入 → 期望判词」）；`--expect N` = **行数常数**
#        （把"台账被截断/被扩表"变成**响亮 FAIL**，免去"teed 清单"那条会动 `fp_inputs()` 的路）。
#        必填列：`tag/trimmed/stackovf/segv_branch/expect`；可选列：`undeclared/phase/role/gen/provenance`。
#        规则：**至少一行 `role=POSCTL` 且真判 `HIT`**（否则 `FAIL reason=untriggerable`）。
#   silent-hit-v2-check.sh --legs-from <腿表.tsv>
#        **产出端一致性闸**：吃产出端机读行（`APP_TEXT_BYTES`／`APP_TEXT_BYTES_TRIMMED`／`TRIM_GATE`／
#        `SEGV_BRANCH`／`LEG_SHA16`）；**两个字节数都必须在**（缺 ⇒ `FAIL reason=producer-absent-or-stale`）；
#        `TRIM_GATE != ok` ⇒ 该腿 `NOINFO`（**不许当 0**）。**没有产出端时**：文件缺/空 ⇒ `NOINFO rc=2
#        reason=no-producer-lines`，**绝不**静默通过（判据本体的三态仍由 `--cases` 决定，两者**分开计数**）。
#   silent-hit-v2-check.sh --denom <分母表.tsv>
#        跨件代分母硬断言：真件代 ≥2 时**每行都要带 `rate`**；出现【合池】行即违规；`hits > legs` 即违规。
#   silent-hit-v2-check.sh --posctl <腿表.tsv> ／ --polarity <表.tsv> ／ --gate-selftest
#        阳性对照闸（单表形态）／ `D-G128` 两条断言（`INJ_ALIVE`：切断注入物**必须翻转**；
#        `VARIANT_INPLACE`：屏上 `sha16` == 树里 `sha16`）／ 这两种牙的反极性自测。
#
# 【单一实现】本件＝车道 `~/w155a/w68prep/bin/silent-hit-ref.py`（参考实现，判据本体）
#   ＋ 车道 `~/w162a/patches/P02-silent-hit-ref-gates.patch`（门槛/极性/分母加固）**1:1 收编**，
#   **判据本体只有一处**（`judge()`），**没有第二份**。
# ============================================================================
set -uo pipefail
SILENTHIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export SILENTHIT_DIR
exec python3 - "$@" <<'PYEOF'
import sys, os, csv, re

BRANCHES = ("rc139", "fate", "term", "stop-signo11")
RC_PASS, RC_FAIL, RC_NOINFO, RC_USAGE = 0, 1, 2, 3
HEX16 = re.compile(r"^[0-9a-f]{16}$")
DIR = os.environ.get("SILENTHIT_DIR", ".")
DEFAULT_CASES = os.path.join(DIR, "silent-hit-v2-cases.tsv")

USAGE = """用法：
  silent-hit-v2-check.sh --selftest
  silent-hit-v2-check.sh --cases <台账.tsv> [--expect <N>]
  silent-hit-v2-check.sh --legs-from <腿表.tsv>
  silent-hit-v2-check.sh --denom <分母表.tsv>
  silent-hit-v2-check.sh --posctl <腿表.tsv>
  silent-hit-v2-check.sh --polarity <表.tsv>
  silent-hit-v2-check.sh --gate-selftest
rc：0 PASS｜1 FAIL｜2 NOINFO（查不动）｜3 用法错误"""


def out(*a):
    print(*a)


def read_rows(path):
    """⇒ (rows, err)。err ∈ None／file-absent／empty／bad-header"""
    if not path or not os.path.exists(path):
        return [], "file-absent"
    try:
        txt = open(path, encoding="utf-8").read()
    except OSError:
        return [], "file-absent"
    if not txt.strip():
        return [], "empty"
    rows = list(csv.DictReader(txt.splitlines(), delimiter="\t", quoting=csv.QUOTE_NONE))
    rows = [r for r in rows if (r.get("tag") or "").strip() or (r.get("trimmed") or "").strip()]
    return rows, None


# ── 判据本体（**唯一实现**；`criteria.md` §1 ① ② ⑤）────────────────────────────
def judge(leg, degenerate=False):
    """⇒ (verdict, reason)。verdict ∈ HIT／NOT-HIT／NOINFO。"""
    trimmed = leg["trimmed"]; so = leg["stackovf"]; br = leg["segv_branch"]
    und = leg.get("undeclared", 0); ph = leg.get("phase", "nav")
    if und:
        return "NOINFO", "undeclared-instrumentation"
    if ph == "teardown":
        return "NOINFO", "teardown-death-not-a-hit"
    if degenerate:                                    # ⚠️ 只许出现在自检的反极性里
        return ("HIT", "degenerate:only-first-branch") if trimmed == 0 else ("NOT-HIT", "degenerate:trimmed!=0")
    c1 = (trimmed == 0); c2 = (so == 0); c3 = (br in BRANCHES)
    if c1 and c2 and c3:
        return "HIT", "ok(branch=%s)" % br
    why = []
    if not c1:
        why.append("trimmed=%d" % trimmed)
    if not c2:
        why.append("stackovf=%d" % so)
    if not c3:
        why.append("segv_branch=%s(第三支不成立)" % (br or "none"))
    return "NOT-HIT", ";".join(why)


def leg_from_row(r):
    return dict(trimmed=int(r["trimmed"]), stackovf=int(r["stackovf"]),
                segv_branch=(r.get("segv_branch") or "").strip(),
                undeclared=int((r.get("undeclared") or "0") or 0),
                phase=((r.get("phase") or "nav") or "nav").strip())


# ── ① `--cases`（`verify-all` 走这条）──────────────────────────────────────────
def mode_cases(path, expect=None):
    rows, err = read_rows(path)
    if err:
        out("SILENTHIT=NOINFO reason=cases-%s file=%s" % (err, path)); out("SILENTHIT_RC=%d" % RC_NOINFO); return RC_NOINFO
    req = ("tag", "trimmed", "stackovf", "segv_branch", "expect")
    miss = [c for c in req if not rows or c not in rows[0]]
    if miss:
        out("SILENTHIT=NOINFO reason=missing-column:%s file=%s" % (",".join(miss), path))
        out("SILENTHIT_RC=%d" % RC_NOINFO); return RC_NOINFO
    examined = hits = nothit = noinfo = posctl_rows = posctl_hits = 0
    badint, mismatch = [], []
    for r in rows:
        tag = (r.get("tag") or "?").strip()
        try:
            leg = leg_from_row(r)
        except (ValueError, TypeError):
            badint.append(tag); continue
        got, why = judge(leg)
        want = (r.get("expect") or "").strip()
        role = (r.get("role") or "").strip()
        examined += 1
        if got == "HIT": hits += 1
        elif got == "NOT-HIT": nothit += 1
        else: noinfo += 1
        if role == "POSCTL":
            posctl_rows += 1
            if got == "HIT": posctl_hits += 1
        if got != want:
            mismatch.append("%s want=%s got=%s :: %s" % (tag, want, got, why))
    if badint:
        out("SILENTHIT=NOINFO reason=non-integer:%s file=%s" % (",".join(badint), path))
        out("SILENTHIT_RC=%d" % RC_NOINFO); return RC_NOINFO
    if examined == 0:                                  # 🦷 零检查必须报红
        out("SILENTHIT=NOINFO reason=zero-examined file=%s" % path)
        out("SILENTHIT_RC=%d" % RC_NOINFO); return RC_NOINFO
    oke = (expect is None) or (len(rows) == expect)
    bad = (not mismatch) and (posctl_hits > 0) and oke
    out("SILENTHIT_CASES file=%s rows=%d examined=%d hits=%d nothit=%d noinfo=%d mismatch=%d posctl=%d/%d expect=%s"
        % (os.path.basename(path), len(rows), examined, hits, nothit, noinfo, len(mismatch),
           posctl_hits, posctl_rows, ("-" if expect is None else expect)))
    if not oke:
        out("  ❌ ledger-row-count-mismatch actual=%d expect=%d（台账被截断或被扩表）" % (len(rows), expect))
    if posctl_hits == 0:
        out("  ❌ 阳性对照不成立：`role=POSCTL` 的行里**一行真 HIT 都没有** ⇒ reason=untriggerable")
    for m in mismatch:
        out("  ❌ " + m)
    status = "PASS" if bad else "FAIL"
    out("SILENTHIT=%s" % status); out("SILENTHIT_RC=%d" % (RC_PASS if bad else RC_FAIL))
    return RC_PASS if bad else RC_FAIL


# ── ② `--legs-from`（产出端一致性闸；没有产出端时**不许静默通过**）────────────
def mode_legs(path):
    rows, err = read_rows(path)
    if err:
        out("SILENTHIT=NOINFO reason=no-producer-lines file=%s（没有产出端 ⇒ 该闸查不动；判据本体请走 --cases）" % path)
        out("SILENTHIT_RC=%d" % RC_NOINFO); return RC_NOINFO
    if not rows:
        out("SILENTHIT=NOINFO reason=no-producer-lines file=%s（只有表头／零行 ⇒ 查不动）" % path)
        out("SILENTHIT_RC=%d" % RC_NOINFO); return RC_NOINFO
    req = ("tag", "APP_TEXT_BYTES", "APP_TEXT_BYTES_TRIMMED", "TRIM_GATE", "SEGV_BRANCH")
    miss = [c for c in req if c not in rows[0]]
    if miss:
        out("SILENTHIT=FAIL reason=producer-absent-or-stale missing-column:%s file=%s" % (",".join(miss), path))
        out("SILENTHIT_RC=%d" % RC_FAIL); return RC_FAIL
    stale, judged = [], []
    for r in rows:
        tag = (r.get("tag") or "?").strip()
        a = (r.get("APP_TEXT_BYTES") or "").strip(); b = (r.get("APP_TEXT_BYTES_TRIMMED") or "").strip()
        gate = (r.get("TRIM_GATE") or "").strip()
        if a == "" or b == "":
            stale.append("%s（两数不全：APP_TEXT_BYTES=%r TRIMMED=%r）" % (tag, a, b)); continue
        if gate != "ok":
            judged.append((tag, "NOINFO", "trim-gate=%s（该腿不进分母）" % gate)); continue
        try:
            got, _ = judge(dict(trimmed=int(b), stackovf=int((r.get("STACKOVF") or "0") or 0),
                                segv_branch=(r.get("SEGV_BRANCH") or "").strip()))
        except (ValueError, TypeError):
            stale.append("%s（读数非整数：TRIMMED=%r）" % (tag, b)); continue
        judged.append((tag, got, ""))
    if stale:
        for s_ in stale:
            out("  \u274c producer-absent-or-stale " + s_)
        out("SILENTHIT=FAIL reason=producer-absent-or-stale rows=%d" % len(stale))
        out("SILENTHIT_RC=%d" % RC_FAIL); return RC_FAIL
    hits = sum(1 for _, v, _ in judged if v == "HIT")
    out("SILENTHIT_LEGS rows=%d hits=%d" % (len(judged), hits))
    for t, v, w in judged:
        out("  %-10s %-8s %s" % (t, v, w))
    out("SILENTHIT=PASS"); out("SILENTHIT_RC=%d" % RC_PASS); return RC_PASS


# ── ③ `--denom`（跨件代分母；合池即违规）──────────────────────────────────────
def mode_denom(path):
    rows, err = read_rows(path)
    if err:
        out("SILENTHIT=NOINFO reason=denom-%s file=%s" % (err, path)); out("SILENTHIT_RC=%d" % RC_NOINFO); return RC_NOINFO
    real = [r for r in rows if HEX16.match((r.get("shim_sha16") or "").strip())]
    pooled = [r for r in rows if "合池" in (r.get("shim_sha16") or "")]
    errs = []
    if not rows:
        out("SILENTHIT=NOINFO reason=denom-empty file=%s" % path); out("SILENTHIT_RC=%d" % RC_NOINFO); return RC_NOINFO
    for i, r in enumerate(rows, 2):
        sh = (r.get("shim_sha16") or "").strip()
        rate = (r.get("rate") or "").strip()
        if not sh:
            errs.append("行%d: 缺 shim_sha16" % i); continue
        if not HEX16.match(sh) and "合池" not in sh:
            errs.append("行%d: shim_sha16 既不是 16 位十六进制、也没标【合池】⇒ 不许混进分母表" % i)
        if HEX16.match(sh):
            if not rate:
                errs.append("行%d: 真件代行**缺 rate** ⇒ 违规" % i)
            if not (r.get("legs") or "").strip() or (r.get("legs") or "").strip() == "0":
                errs.append("行%d: legs 为空/0" % i)
        try:
            lg, ht = int((r.get("legs") or "0") or 0), int((r.get("hits") or "0") or 0)
        except ValueError:
            errs.append("行%d: legs/hits 不是整数" % i); continue
        if HEX16.match(sh) and ht > lg:
            errs.append("行%d: hits(%d) > legs(%d) ⇒ 率不可能（R4）" % (i, ht, lg))
    if len(real) >= 2 and pooled:
        errs.append("R5: 真件代行 ≥2 却出现【合池】行 ⇒ 合池即违规")
    v = "PASS" if not errs else "FAIL"
    out("SILENTHIT_DENOM=%s rows=%d 真件代=%d 合池行=%d" % (v, len(rows), len(real), len(pooled)))
    for e in errs:
        out("  ❌ " + e)
    out("SILENTHIT=%s" % v); out("SILENTHIT_RC=%d" % (RC_PASS if v == "PASS" else RC_FAIL))
    return RC_PASS if v == "PASS" else RC_FAIL


# ── ④ `--posctl` ／ `--polarity`（门槛与 D-G128 两条断言）──────────────────────
def mode_posctl(path):
    rows, err = read_rows(path)
    if err:
        out("SILENTHIT=FAIL reason=untriggerable rows=0 (%s)" % err); out("SILENTHIT_RC=%d" % RC_FAIL); return RC_FAIL
    hits, bad = 0, []
    for r in rows:
        tag = (r.get("tag") or "?").strip()
        try:
            got, why = judge(leg_from_row(r))
        except (ValueError, TypeError):
            out("SILENTHIT=NOINFO reason=non-integer:%s" % tag); out("SILENTHIT_RC=%d" % RC_NOINFO); return RC_NOINFO
        want = (r.get("expect") or "HIT").strip()
        if got == "HIT":
            hits += 1
        if got != want:
            bad.append("%s want=%s got=%s :: %s" % (tag, want, got, why))
        out("  %s %-10s expect=%-8s got=%-8s :: %s" % ("OK " if got == want else "❌", tag, want, got, why))
    if hits == 0:
        bad.append("无一行 HIT ⇒ 判据在**本件代**上不可触发（阳性对照不成立）")
    v = "PASS" if not bad else "FAIL"
    out("SILENTHIT_POSCTL=%s rows=%d hits=%d" % (v, len(rows), hits))
    for b in bad:
        out("  ❌ " + b)
    out("SILENTHIT=%s" % v); out("SILENTHIT_RC=%d" % (RC_PASS if v == "PASS" else RC_FAIL))
    return RC_PASS if v == "PASS" else RC_FAIL


def mode_polarity(path):
    rows, err = read_rows(path)
    if err or not rows:
        out("SILENTHIT=FAIL rows=0 reason=%s" % (err or "zero-rows")); out("SILENTHIT_RC=%d" % RC_FAIL); return RC_FAIL
    viol = []
    for r in rows:
        tag = (r.get("tag") or "?").strip()
        s = (r.get("screen_sha16") or "").strip(); t = (r.get("tree_sha16") or "").strip()
        fl = (r.get("flipped") or "").strip()
        inplace = (s == t) and bool(HEX16.match(s)); alive = (fl == "1")
        if not inplace:
            viol.append("%s: VARIANT_INPLACE 不成立（屏上 %s != 树里 %s）" % (tag, s or "none", t or "none"))
        if not alive:
            viol.append("%s: INJ_ALIVE 不成立（切断注入物后未翻转 ⇒ 假牙）" % tag)
        out("  %s %-10s screen=%s tree=%s flipped=%s" % ("OK " if (inplace and alive) else "❌",
                                                         tag, s or "none", t or "none", fl or "none"))
    v = "PASS" if not viol else "FAIL"
    out("SILENTHIT_POLARITY=%s rows=%d viol=%d" % (v, len(rows), len(viol)))
    for x in viol:
        out("  ❌ " + x)
    out("SILENTHIT=%s" % v); out("SILENTHIT_RC=%d" % (RC_PASS if v == "PASS" else RC_FAIL))
    return RC_PASS if v == "PASS" else RC_FAIL


# ── ⑤ 自检（含"零检查必须报红"与两条 NOINFO 两极）────────────────────────────
def mode_selftest():
    cases = [
        ("S1", dict(trimmed=0, stackovf=0, segv_branch="rc139", undeclared=0, phase="nav"), "HIT", False,
         "v2 基线：三支齐 ⇒ HIT"),
        ("S2", dict(trimmed=0, stackovf=0, segv_branch="none", undeclared=0, phase="alive-after-recipe"), "NOT-HIT", True,
         "ⓒ 活腿 `T==0` **不是命中**（现场：P1-01／P2-01）"),
        ("S3", dict(trimmed=1, stackovf=0, segv_branch="rc139", undeclared=0, phase="nav"), "NOT-HIT", False,
         "第一支不成立"),
        ("S4", dict(trimmed=0, stackovf=1, segv_branch="rc139", undeclared=0, phase="nav"), "NOT-HIT", False,
         "134 族不许混进来"),
        ("S5", dict(trimmed=0, stackovf=0, segv_branch="rc139", undeclared=3, phase="nav"), "NOINFO", False,
         "完备性闸：UNDECL>0 ⇒ NOINFO（不进分母）"),
        ("S6", dict(trimmed=0, stackovf=0, segv_branch="stop-signo11", undeclared=0, phase="nav"), "HIT", False,
         "第四支（抗收尾截断）也必须被认可"),
        ("S7", dict(trimmed=0, stackovf=0, segv_branch="", undeclared=0, phase="nav"), "NOT-HIT", False,
         "第三支空 ⇒ 不成立（模糊谓词不算）"),
        ("S8", dict(trimmed=0, stackovf=0, segv_branch="term", undeclared=0, phase="teardown"), "NOINFO", False,
         "收进程期死亡不计命中"),
        ("S9", dict(trimmed=0, stackovf=0, segv_branch="fate", undeclared=0, phase="nav"), "HIT", False,
         "第二支 fate 也在四支白名单里"),
    ]
    fail = flips = 0
    seen = {"HIT": 0, "NOT-HIT": 0, "NOINFO": 0}
    for cid, leg, want, flip, note in cases:
        got, why = judge(leg)
        dg, _ = judge(leg, degenerate=True)
        seen[got] = seen.get(got, 0) + 1
        if dg != got:
            flips += 1
        ok = (got == want) and (dg == "HIT" if flip else True)
        if not ok:
            fail += 1
        out("  %s%s want=%-8s got=%-8s :: %s%s" % ("OK " if ok else "❌ ", cid, want, got, why,
                                                    "  [退化实现→%s]" % dg if dg != got else ""))
        out("       " + note)
    if flips < 1:
        out("  ❌ 退化实现没有翻动任何一格 ⇒ 反极性牙是死的"); fail += 1
    if seen["HIT"] == 0 or seen["NOT-HIT"] == 0 or seen["NOINFO"] == 0:
        out("  ❌ 三态没有齐备（%s）⇒ 自检不算绿" % seen); fail += 1
    out("SILENTHIT_SELFTEST=%s cases=%d fail=%d degenerate_flips=%d three_state=%s"
        % ("PASS" if fail == 0 else "FAIL", len(cases), fail, flips,
           "%d/%d/%d" % (seen["HIT"], seen["NOT-HIT"], seen["NOINFO"])))
    out("SILENTHIT=%s" % ("PASS" if fail == 0 else "FAIL"))
    out("SILENTHIT_RC=%d" % (RC_PASS if fail == 0 else RC_FAIL))
    return RC_PASS if fail == 0 else RC_FAIL


def mode_gate_selftest():
    import tempfile, io, contextlib
    d = tempfile.mkdtemp(prefix="silenthit-gate-")

    def w(name, rows):
        p = os.path.join(d, name)
        open(p, "w", encoding="utf-8").write("\n".join(rows) + "\n")
        return p

    H = "tag\trole\ttrimmed\tstackovf\tsegv_branch\tundeclared\tphase\texpect"
    P = "tag\tscreen_sha16\ttree_sha16\tflipped"
    cases = [
        ("CASES-good-must-PASS", lambda: mode_cases(w("c1.tsv", [H, "P-HIT\tPOSCTL\t0\t0\trc139\t0\tnav\tHIT"]), 1), 0),
        ("CASES-no-posctl-must-FAIL",
         lambda: mode_cases(w("c2.tsv", [H, "P\tLIVENEG\t0\t0\tnone\t0\talive-after-recipe\tNOT-HIT"]), 1), 1),
        ("CASES-empty-must-NOINFO", lambda: mode_cases(w("c3.tsv", [H]), 1), 2),
        ("CASES-missing-column-must-NOINFO",
         lambda: mode_cases(w("c4.tsv", ["tag\tstackovf\tsegv_branch\texpect", "P\t0\trc139\tHIT"]), 1), 2),
        ("CASES-non-integer-must-NOINFO",
         lambda: mode_cases(w("c5.tsv", [H, "P\tPOSCTL\txyz\t0\trc139\t0\tnav\tHIT"]), 1), 2),
        ("CASES-rowcount-mismatch-must-FAIL",
         lambda: mode_cases(w("c6.tsv", [H, "P-HIT\tPOSCTL\t0\t0\trc139\t0\tnav\tHIT"]), 99), 1),
        ("LEGS-no-producer-must-NOINFO", lambda: mode_legs(w("l1.tsv", ["tag\tAPP_TEXT_BYTES"])), 2),
        ("LEGS-stale-producer-must-FAIL",
         lambda: mode_legs(w("l2.tsv", ["tag\tAPP_TEXT_BYTES\tAPP_TEXT_BYTES_TRIMMED\tTRIM_GATE\tSEGV_BRANCH",
                                        "P1\t484\t\tok\trc139"])), 1),
        ("POLARITY-cut-variant-must-FAIL",
         lambda: mode_polarity(w("p1.tsv", [P, "N1\t1111111111111111\t2222222222222222\t1"])), 1),
        ("POLARITY-dead-injection-must-FAIL",
         lambda: mode_polarity(w("p2.tsv", [P, "N1\t3333333333333333\t3333333333333333\t0"])), 1),
        ("POLARITY-empty-must-FAIL", lambda: mode_polarity(w("p3.tsv", [P])), 1),
        ("POLARITY-good-must-PASS",
         lambda: mode_polarity(w("p4.tsv", [P, "N1\t4444444444444444\t4444444444444444\t1"])), 0),
    ]
    fail = 0
    for name, fn, want_rc in cases:
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = fn()
        ok = (rc == want_rc)
        if not ok:
            fail += 1
        out("  %s%-38s want_rc=%d got_rc=%d" % ("OK " if ok else "❌ ", name, want_rc, rc))
        if not ok:
            for ln in buf.getvalue().splitlines()[:4]:
                out("        | " + ln)
    out("SILENTHIT_GATESELFTEST=%s cases=%d fail=%d" % ("PASS" if fail == 0 else "FAIL", len(cases), fail))
    out("SILENTHIT=%s" % ("PASS" if fail == 0 else "FAIL"))
    out("SILENTHIT_RC=%d" % (RC_PASS if fail == 0 else RC_FAIL))
    return RC_PASS if fail == 0 else RC_FAIL


def main():
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help"):
        out(USAGE); return RC_USAGE if not a else RC_PASS
    if a[0] == "--selftest":
        return mode_selftest()
    if a[0] == "--gate-selftest":
        return mode_gate_selftest()
    if a[0] == "--cases":
        if len(a) < 2:
            out("SILENTHIT=FAIL reason=usage:--cases 需要文件路径"); return RC_USAGE
        exp = None
        if "--expect" in a:
            try:
                exp = int(a[a.index("--expect") + 1])
            except (IndexError, ValueError):
                out("SILENTHIT=FAIL reason=usage:--expect 需要整数"); return RC_USAGE
        return mode_cases(a[1] if a[1] != "--expect" else DEFAULT_CASES, exp)
    if a[0] in ("--legs-from", "--denom", "--posctl", "--polarity"):
        if len(a) < 2:
            out("SILENTHIT=FAIL reason=usage:%s 需要文件路径" % a[0]); return RC_USAGE
        return {"--legs-from": mode_legs, "--denom": mode_denom,
                "--posctl": mode_posctl, "--polarity": mode_polarity}[a[0]](a[1])
    out("SILENTHIT=FAIL reason=usage:未知参数 %s" % a[0]); out(USAGE); return RC_USAGE


if __name__ == "__main__":
    sys.exit(main())
PYEOF

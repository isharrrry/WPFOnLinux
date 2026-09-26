#!/usr/bin/env bash
# ============================================================================
# appbar-startup-check.sh —— `TASK-0747`（`D-G124` 的 `F-A`）的**仓内牙**（纯读、零 `dotnet`、秒级）
#
# 【它防什么】`D-G124`：本 shim **从未导出** `SHAppBarMessage`，而上游 HandyControl 的
#   `Window.WmGetMinMaxInfo`（`InteropMethods.cs:485-486` 声明 / `Window.cs:340-341` 调用）在
#   "**首次 map 之后**那一拍 `WM_GETMINMAXINFO`"（本 shim 的 `after-map` 交付点）里真的调它
#   ⇒ 每趟启动抛 `EntryPointNotFoundException`，被 demo 自己的 `DispatcherUnhandledException`
#   接住（进程不死、但**每趟启动自报 242 B**）。本件把"**启动期该异常不得出现**"做成**会咬的读数**：
#   判词由**腿台账**（`--legs`）驱动，**阳性对照是门槛**，**空边响亮失败**，`examined==0` **必 NOINFO**。
#
# 【三态与 rc】（与 `silent-hit-v2-check.sh` / `nul-bytes-check.sh` **刻意同形**）
#   `APPBAR_STARTUP=PASS`   rc=0 ：装符号臂每一腿都过 ∧ 反极性（未装）臂真判出异常 ∧ 几何跨臂一致
#   `APPBAR_STARTUP=FAIL`   rc=1 ：装符号臂仍有异常行／几何跨臂不一致／阳性对照不成立
#                                 （`reason=untriggerable`）／`--expect` 与实核行数不符
#   `APPBAR_STARTUP=NOINFO` rc=2 ：**查不动** —— 台账缺文件／空表／缺列／非整数／**零行被检查**
#                                 ／装符号臂的 `[APPBAR_DIAG]` 计数为 0（**仪器无射程**：异常消失
#                                 也可能是"这一拍没走到"，两者不可区分 ⇒ 既不算绿也不算红）
#   `APPBAR_STARTUP=FAIL`   rc=3 ：用法错误
#   ⚠️ **零检查必须报红**（前言 §3.5）：`examined == 0` **一律 NOINFO rc=2**，**永不给 PASS**。
#   ⚠️ `NOINFO` **既不算绿也不算红**；**不许**把"没有数"读成 `0`。
#
# 【必填列】`tag arm shim16 rc hc_unhandled_n entrypoint_notfound_n appbar_diag_n geom`
#   `arm ∈ {absent, ret0}` —— `absent` = 未装符号臂（**反极性**）、`ret0` = 装符号臂（落仓版）。
#   可选列：`note`。
# 【判据本体（三档分明，**没有恒真断言**）】
#   POSCTL（**门槛**）：≥1 行 `arm=absent` ∧ `hc>=1` ∧ `epnf>=1`；否则 `FAIL reason=untriggerable`
#                        （**这条是"这件牙有牙"的证明**：装置抓不到该行 ⇒ 判不了）。
#   R1：每一行 `arm=ret0` ⇒ `hc==0` ∧ `epnf==0` ∧ `rc==124`。
#   R2（**射程**）：每一行 `arm=ret0` ⇒ `appbar_diag_n>=1`；缺 ⇒ 该腿 `NOINFO`（**不许**当 0、也不许当 PASS）。
#   R3（**零回归**）：`geom` 这一列跨**所有**行必须**逐字相同**（"消除异常不得伴随几何位移"）。
#   R4：`--expect N` 给定时，实核行数必须 == N（把"台账被截断/被扩表"变成响亮 FAIL）。
#
# 【与 `#68` `SILENTHIT` 口径／剔除集的关系（逐字写清，不许含糊）】
#   · `D-G123` / `silent-hit-v2-check.sh` 的第一支 ＝「应用输出 **0 B**」。`D-G124` 是该支的
#     **同池生产者**：含 `after-map` 那一拍的件代**每趟启动必被打红 `+242 B`**（历史 **114/114**；
#     W177A 现取：`after-map` 在场 ⟺ 历史命中 **100%**，537 腿 0% vs 112 腿 100%，**零交叠**）
#     ⇒ 任何以"静默／0 字节／启动期零异常"为判据的格，在那些件代上**必须有剔除集或在册声明**，
#     否则**每次都红**。
#   · **本波（`TASK-0747`）把该 `+242 B` 的成因掐掉** ⇒ 对**装符号之后**的件代，该生产者
#     **不再存在**，`D-G124` 从那些格子的剔除集里**可以退场**；对**历史件代**仍需剔除集或在册声明
#     （**不许**拿本波的修法倒推历史读数是绿的）。
#   · 本件**只**判"这个件代、这个装置上，启动期不得出现该异常"，**不**替 `SILENTHIT` 判分母、
#     **不**改任何在册口径句；两者**分开计数**（本件的 `examined=` 不含 `SILENTHIT` 的台账）。
#
# 【本牙自己的接线状态（**必须字面写在件头**：`selfdescription-wiring-check.sh` 判的就是「件头自述 vs 接线」）】
#   **已接线**：`verify-all.sh` 的 `run_step "APPBAR-STARTUP" bash build/MilBridge/tools/appbar-startup-check.sh --all …`
#   —— ⚠️ **本注释不写步号**：以现场 `verify-all.sh` 的**步序**为准（写死步号 = 下一条会漂移的陈旧自述）。
#   ⚠️ 本条与接线**必须同趟落**（否则本牙当场被 `rule=reverse` 判红）⇒ 落仓器 `landing.sh` 把二者放在**同一个事务**里。
#
# 【用法】
#   appbar-startup-check.sh --all --symbols <so> --legs <台账.tsv> --expect-legs <N>   ← **`verify-all` 走这条**
#         ⚠️ 本旗叫 `--expect-legs`（**不是** `--expect`）：`verify-all.sh` 同一段里另有一条 `--expect` 是
#            **覆盖面件数**（`fp-manifest-step.sh`），两个数含义不同 ⇒ **同名会在人眼下混**（本仓对这类
#            "一个词两个意思"极敏感）⇒ 显式区分。
#        两臂**合取**：`--symbols`（活体符号面，判"这一处符号在不在"）∧ `--legs`（录下来的腿表，判"启动期该异常在不在"）。
#        逐臂各印一行机读；**任一臂非 PASS ⇒ 整体非 PASS**（`FAIL` 优先于 `NOINFO`）；两臂**分开计数**。
#   appbar-startup-check.sh --selftest
#   appbar-startup-check.sh --legs <腿台账.tsv> [--expect-legs <N>]
#   appbar-startup-check.sh --symbols <libwpfwin32.so>
#        **活体臂**（`verify-all` 能反复跑的那一支）：直接在**权威件**上读 `.dynsym`
#        ⇒ `SHAppBarMessage` 必须在**导出集**里（`D-G124` 的成因就是它不在 ⇒ 启动期抛异常）。
#        三态：`0=PASS`｜`1=FAIL`（缺符号）｜`2=NOINFO`（**读不动**：文件缺 / `nm` 失败 /
#        **导出集为空** ⇒ **零检查必须报红**，绝不当 PASS）。
#        反极性现场（本车道实测）：`--symbols <未装符号的件>` ⇒ `FAIL`；
#        `--symbols <装符号的件>` ⇒ `PASS`。
#        ⚠️ 本臂**不判**"被调到没有"（那只有跑应用才知道）⇒ 二者**分开计数**，
#          不许拿本臂的 `PASS` 去替 `--legs` 臂说话。
# ============================================================================
set -uo pipefail

SELF="${BASH_SOURCE[0]}"
usage() { echo "用法: $0 --selftest | --legs <台账.tsv> [--expect-legs <N>]" >&2; exit 3; }

run_py() {  # $1 = argv...
  export W181A_TOOTH_SELF="$SELF"
  python3 - "$@" <<'PYEOF'
import sys
import os
SELF = os.environ["W181A_TOOTH_SELF"]

RC_PASS, RC_FAIL, RC_NOINFO, RC_USAGE = 0, 1, 2, 3
out = lambda s: print(s)
REQ = ["tag", "arm", "shim16", "rc", "hc_unhandled_n", "entrypoint_notfound_n",
       "appbar_diag_n", "geom"]
ARMS = ("absent", "ret0")


def verdict(v, **kw):
    extra = " ".join("%s=%s" % (k, w) for k, w in kw.items() if w is not None)
    out("APPBAR_STARTUP=%s%s" % (v, (" " + extra) if extra else ""))
    rc = {"PASS": RC_PASS, "FAIL": RC_FAIL, "NOINFO": RC_NOINFO}[v]
    out("APPBAR_STARTUP_RC=%d" % rc)
    return rc


def judge(rows, expect=None):
    """rows = list[dict]；返回 rc。三档分明；空边一律 NOINFO。"""
    n = len(rows)
    if n == 0:
        return verdict("NOINFO", reason="zero-examined", examined=0)
    if expect is not None and n != expect:
        return verdict("FAIL", reason="row-count-mismatch", examined=n, expect=expect)

    absent = [r for r in rows if r["arm"] == "absent"]
    inst = [r for r in rows if r["arm"] == "ret0"]
    posctl = [r for r in absent if r["hc_unhandled_n"] >= 1 and r["entrypoint_notfound_n"] >= 1]
    if not posctl:
        return verdict("FAIL", reason="untriggerable", examined=n,
                       posctl="0/%d" % len(absent))
    if not inst:
        return verdict("NOINFO", reason="no-installed-arm", examined=n)

    fails, noinfos, passes = [], [], []
    for r in inst:
        if r["hc_unhandled_n"] != 0 or r["entrypoint_notfound_n"] != 0:
            fails.append("%s:R1(exception-still-present hc=%d epnf=%d)"
                         % (r["tag"], r["hc_unhandled_n"], r["entrypoint_notfound_n"]))
            continue
        if r["rc"] != 124:
            noinfos.append("%s:dead-before-readpoint rc=%d" % (r["tag"], r["rc"]))
            continue
        if r["appbar_diag_n"] < 1:
            noinfos.append("%s:R2-no-instrument-range(appbar_diag_n=0)" % r["tag"])
            continue
        passes.append(r["tag"])
    for r in absent:
        if r["rc"] != 124:
            noinfos.append("%s:dead-before-readpoint rc=%d" % (r["tag"], r["rc"]))

    geoms = sorted({r["geom"] for r in rows if r["geom"] and r["geom"] != "none"})
    if len(geoms) > 1:
        fails.append("R3:geometry-drift across-arms=%s" % ",".join(geoms))

    npass, nfail, nnoinfo = len(passes), len(fails), len(noinfos)
    out("APPBAR_STARTUP_CASES examined=%d passed=%d fail=%d noinfo=%d posctl=%d/%d expect=%s"
        % (n, npass, nfail, nnoinfo, len(posctl), len(absent), expect if expect is not None else "-"))
    for f in fails:
        out("APPBAR_STARTUP_FAIL_ROW %s" % f)
    for f in noinfos:
        out("APPBAR_STARTUP_NOINFO_ROW %s" % f)
    out("APPBAR_STARTUP_GEOMS %s" % ("|".join(geoms) if geoms else "-"))

    if nfail:
        return verdict("FAIL", reason="row-judgement", examined=n, fail=nfail)
    if nnoinfo:
        return verdict("NOINFO", reason="instrument-range", examined=n, noinfo=nnoinfo)
    return verdict("PASS", examined=n, passed=npass, posctl="%d/%d" % (len(posctl), len(absent)),
                   geoms=len(geoms))


def load(path, expect=None):
    try:
        with open(path, encoding="utf-8") as f:
            lines = [l.rstrip("\n") for l in f if l.strip() and not l.startswith("#")]
    except FileNotFoundError:
        return None, "missing-file"
    if not lines:
        return None, "empty-table"
    hdr = lines[0].split("\t")
    miss = [c for c in REQ if c not in hdr]
    if miss:
        return None, "missing-column:%s" % ",".join(miss)
    idx = {c: hdr.index(c) for c in REQ}
    rows, badint, badarm = [], [], []
    for ln, l in enumerate(lines[1:], start=2):
        c = l.split("\t")
        if len(c) < len(hdr):
            return None, "short-row:line=%d" % ln
        r = {"tag": c[idx["tag"]], "arm": c[idx["arm"]], "shim16": c[idx["shim16"]],
             "geom": c[idx["geom"]]}
        for k in ("rc", "hc_unhandled_n", "entrypoint_notfound_n", "appbar_diag_n"):
            try:
                r[k] = int(c[idx[k]])
            except ValueError:
                badint.append("%s:%s=%r" % (r["tag"], k, c[idx[k]]))
                r[k] = None
        if r["arm"] not in ARMS:
            badarm.append("%s:%s" % (r["tag"], r["arm"]))
        rows.append(r)
    if badint:
        return None, "non-integer:%s" % ",".join(badint)
    if badarm:
        return None, "unknown-arm:%s" % ",".join(badarm)
    return rows, None


if sys.argv[1] == "--selftest":
    import tempfile
    import os
    bad = 0
    H = "tag\tarm\tshim16\trc\thc_unhandled_n\tentrypoint_notfound_n\tappbar_diag_n\tgeom\n"
    A = "absent-leg\tabsent\tfc60c34d51fd9247\t124\t1\t1\t0\t800x600@+240+212\n"
    G = "ret0-leg\tret0\t%s\t124\t0\t0\t1\t800x600@+240+212\n"
    d = tempfile.mkdtemp(prefix="w181a-check-")
    cases = [
        ("pos+neg-mixed", H + A + G % "aaaa111122223333", 0, "PASS"),
        ("neg-only-no-posctl", H + G % "aaaa111122223333", 1, "FAIL"),
        ("inst-still-throws", H + A + "x\tret0\ts\t124\t1\t1\t1\t800x600@+240+212\n", 1, "FAIL"),
        ("inst-no-instrument", H + A + "x\tret0\ts\t124\t0\t0\t0\t800x600@+240+212\n", 2, "NOINFO"),
        ("geom-drift", H + A + (G % "aaaa111122223333").replace("800x600@+240+212", "801x600@+240+212"), 1, "FAIL"),
        ("inst-dead", H + A + "x\tret0\ts\t134\t0\t0\t1\t800x600@+240+212\n", 2, "NOINFO"),
        ("zero-examined", H, 2, "NOINFO"),
        ("missing-column", "tag\tarm\nx\tret0\n", 2, "NOINFO"),
        ("non-integer", H + A + "x\tret0\ts\t124\tzz\t0\t1\tg\n", 2, "NOINFO"),
        ("unknown-arm", H + A + "x\tbogus\ts\t124\t0\t0\t1\tg\n", 2, "NOINFO"),
    ]
    for name, body, want_rc, want_v in cases:
        p = os.path.join(d, name + ".tsv")
        open(p, "w").write(body)
        import subprocess
        r = subprocess.run(["bash", SELF, "--legs", p], capture_output=True, text=True)
        got_v = ""
        for l in r.stdout.splitlines():
            if l.startswith("APPBAR_STARTUP="):
                got_v = l.split("=", 1)[1].split()[0]
        ok = (r.returncode == want_rc and got_v == want_v)
        print("SELFTEST_CASE=%-22s rc=%d(want %d) verdict=%s(want %s) %s"
              % (name, r.returncode, want_rc, got_v or "-", want_v, "OK" if ok else "**MISMATCH**"))
        if not ok:
            bad += 1
    # 反极性：**用退化的桩实现**必须翻（恒 PASS 的判据在这里就死）
    print("SELFTEST=FAIL degraded=%d" % bad if bad else "SELFTEST=PASS cases=%d" % len(cases))
    sys.exit(1 if bad else 0)

if sys.argv[1] == "--symbols":
    import subprocess
    so = sys.argv[2]
    if not os.path.isfile(so):
        sys.exit(verdict("NOINFO", reason="missing-file", file=so))
    r = subprocess.run(["nm", "-D", "--defined-only", so], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(verdict("NOINFO", reason="nm-failed rc=%d" % r.returncode, file=so))
    names = [l.split()[-1] for l in r.stdout.splitlines() if l.strip()]
    if not names:
        # 零检查必须报红（纪律 5）：导出集为空 ⇒ **不是** "没有该符号"，而是"读不动"
        sys.exit(verdict("NOINFO", reason="zero-symbols", file=so))
    has = names.count("SHAppBarMessage")
    leak = names.count("wpf_appbar_diag")   # 内部仪器**不许**泄进 ABI
    out("APPBAR_SYMBOLS so=%s symbols_n=%d shappbar=%d appbar_diag_leak=%d"
        % (os.path.basename(so), len(names), has, leak))
    if leak:
        sys.exit(verdict("FAIL", reason="internal-helper-exported", symbols_n=len(names)))
    if has != 1:
        sys.exit(verdict("FAIL", reason="shappbar-not-exported" if has == 0 else "shappbar-dup",
                         symbols_n=len(names), shappbar=has))
    sys.exit(verdict("PASS", symbols_n=len(names), shappbar=has))

if sys.argv[1] == "--legs":
    path = sys.argv[2]
    expect = None
    if "--expect-legs" in sys.argv:
        expect = int(sys.argv[sys.argv.index("--expect-legs") + 1])
    rows, err = load(path, expect)
    if err:
        sys.exit(verdict("NOINFO", reason=err, examined=0))
    sys.exit(judge(rows, expect))

usage()
PYEOF
}

case "${1:-}" in
  --selftest) run_py --selftest ;;
  --all)
      # 合取：两臂各跑一次，**任一非 PASS ⇒ 整体非 PASS**；`FAIL` 优先于 `NOINFO`。
      rc_sym=3; rc_leg=3; out_sym=""; out_leg=""
      if [ "$#" -ge 3 ] && [ "$2" = "--symbols" ]; then
          out_sym=$(run_py --symbols "$3" 2>&1); rc_sym=$?
      fi
      if [ "$#" -ge 5 ] && [ "$4" = "--legs" ]; then
          out_leg=$(run_py --legs "$5" ${7:+--expect-legs "$7"} 2>&1); rc_leg=$?
      fi
      printf '%s\n' "$out_sym"
      printf '%s\n' "$out_leg"
      if   [ "$rc_sym" -eq 1 ] || [ "$rc_leg" -eq 1 ]; then V=FAIL; RC=1
      elif [ "$rc_sym" -eq 0 ] && [ "$rc_leg" -eq 0 ]; then V=PASS; RC=0
      else V=NOINFO; RC=2; fi
      echo "APPBAR_STARTUP_ALL=$V symbols_rc=$rc_sym legs_rc=$rc_leg（两臂**分开计数**：本行不合并它们的 examined）"
      exit "$RC" ;;
  --legs)     [ $# -ge 2 ] || usage; run_py "$@" ;;
  --symbols)  [ $# -ge 2 ] || usage; run_py "$@" ;;
  *)          usage ;;
esac

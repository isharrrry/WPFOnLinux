#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""`wave-freeze-consistency-check.py` —— 冻结期的**三档一致性牙**（纯读、零 `dotnet`、秒级；不写任何件）。

【它防什么（三件都是 `#77` 独立复验 `t6` 抓到的真现场；三档各自独立、互不代偿）】
  ① `WFREEZE_ROOTDEFAULT` —— **旧路径重指向的派生式必须在真实自指路径下解析到仓根**。
     现场（`t6`）：`#77` 的 21 件重指向里有 **5 件 `dirname` 层数少一层** ⇒ 解析到 `<仓>/build` 而不是仓根，
     而**它们的第一个消费点拼出来的路径都不存在**，用改前的旧值拼则存在 ⇒ **真回归**。
     `t6` 是**真跑那一行**抓到的（不是看源码）；本档沿用同一方法：`.py` 用 `eval`（`__file__` 注入真实路径）、
     `.sh` 把 `${BASH_SOURCE[0]}` **注入**真实路径后交 `bash` 求值 —— **一次文本 grep 都不做**。
     ⚠️ 为什么必须有这颗牙：这 5 件**既不在 `verify-all` 接线、也不在 `fp_inputs()` 覆盖面** ⇒ 原门禁**看不见**。
  ② `WFREEZE_DECL` —— **预登记文本必须与冻结器 `GENS` 的配置逐字段一致**。
     现场（`t6`）：预登记 FROZEN ⑩/⑥ 写 `allow_changed={'pf'}` ＋ `pf_required=True`，而 `GENS['#77']`
     实为 `allow_changed={pc,pf,windowsbase,provider,dwf}` ＋ `pf_required=False` ⇒ 同一件事在两处**分叉**。
  ③ `WFREEZE_NINEAUTH` —— **同名产物的多条「权威」路径之间必须相等**。
     现场（`t6`）：`DirectWrite.Linux.Provider.dll` 有两个都自称权威的路径（`build/PresentationCore.Linux/bin/<CFG>/…`
     与 `build/DirectWrite.Linux/Provider/bin/<CFG>/…`）；`t6` 重建了后者 ⇒ 前者立刻陈旧，
     `app-local` 判据（走后者）当场 `STALE=52 / DIVERGENT=1`，而**九位/哨兵走前者** ⇒ **谁重建其一都会让两侧分叉**。

【三态】`PASS`（rc 0）／`FAIL`（rc 1，逐条点名）／`NOINFO`（rc 3，**算不出来 ≠ 绿**）。
        任一档 `FAIL` ⇒ 整体 `FAIL`；无 `FAIL` 但有 `NOINFO` ⇒ 整体 `NOINFO`。
【用法】`python3 wave-freeze-consistency-check.py [--root DIR] [--freezer PATH] [--selftest]`
        `--root` 默认由**本件自身位置**现推（`build/MilBridge/tools/` 上溯三层）。
【卫生】只读；不写 `$R`；临时件走 `mktemp -d` ＋ `trap`（不落共享 `/tmp` 的固定名）。
"""
import argparse, ast, glob, json, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SELF_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))   # build/MilBridge/tools → 仓根

# ══ 档 ①：`#77` 实际改过的 21 件 / 22 条派生式（**声明式 roster**，不靠注释标记 —— 标记文本会随波变）══
ROSTER = [  # (相对路径, 行号, 变量名, 消费点后缀 or None)
 ("build/DirectWrite.Linux/wic-shim/frames-gen.py", 33, "REPO", "build/DirectWrite.Linux/wic-shim/fixtures-jfif.jpg"),
 ("build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh", 23, "REPO", None),
 ("build/MilBridge/tests/W81AWindowProbe/w81a-a0-analyze.py", 28, "_ROOT77", "src/WpfGfx.Linux.Native/bin/libwpfwin32.so"),
 ("build/MilBridge/tools/analyze-layout-b34.py", 12, "ROOT", "build/MilBridge/gen/layout-b34-compact.json"),
 ("build/MilBridge/tools/backup-completeness-gate.sh", 49, "BCG_DEFROOT", None),
 ("build/MilBridge/tools/extract-layout-b34.py", 13, "ROOT", "tests/parity/windows/layout-b34/windows-results.json"),
 ("build/MilBridge/tools/nl-intent-check.sh", 58, "cand", None),
 ("build/MilBridge/tools/nl-intent-check.sh", 64, "R", None),
 ("build/MilBridge/tools/proc-pattern-guard.sh", 55, "REPO", None),
 ("build/MilBridge/tools/pts-gap-count-check.sh", 74, "R", None),
 ("build/MilBridge/tools/repo-alias-check.sh", 55, "ALIAS_ROOT", None),
 ("build/MilBridge/tools/retake-arms-w21.sh", 6, "ROOT", None),
 ("build/MilBridge/tools/retake-arms-w23.sh", 6, "ROOT", None),
 ("build/MilBridge/tools/t1b-d3-acceptance.sh", 15, "ROOT", None),
 ("build/MilBridge/tools/t1b-live-window.sh", 19, "ROOT", None),
 ("build/MilBridge/tools/t1c-census.sh", 35, "ROOT", None),
 ("build/MilBridge/tools/t1c-inputtrace-verify.py", 32, "ROOT", "src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py"),
 ("build/MilBridge/tools/t1d-probe.sh", 22, "ROOT", None),
 ("build/MilBridge/tools/t2d-extent-detail.sh", 13, "ROOT", None),
 ("tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-1400rate.sh", 31, "REPO", None),
 ("tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-inputleg-tooth.sh", 20, "REPO", None),
 ("tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-mutation.sh", 19, "REPO", None),
]

# ══ 档 ③：同名产物多「权威」路径（规约权威, 副本）—— 判定见 §F6：**规约 = 工程的产出目录** ══
NINEAUTH = [
  ("build/DirectWrite.Linux/Provider/bin/Release/DirectWrite.Linux.Provider.dll",
   "build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll"),
  ("build/WindowsBase.Linux/bin/Release/WindowsBase.dll",
   "build/WindowsBase.Linux/bin/Debug/WindowsBase.dll"),
]

def sha16(p):
    try:
        import hashlib
        h = hashlib.sha256()
        with open(p, 'rb') as f:
            for b in iter(lambda: f.read(1 << 20), b''): h.update(b)
        return h.hexdigest()[:16]
    except OSError:
        return None

# ── 档 ① ────────────────────────────────────────────────────────────────────────
def sec_rootdefault(root, roster=None):
    roster = ROSTER if roster is None else roster
    rows = []
    for rel, ln, var, suffix in roster:
        p = os.path.join(root, rel)
        if not os.path.exists(p):
            rows.append((rel, ln, var, 'FILE-ABSENT', False, None)); continue
        line = open(p, encoding='utf-8', errors='replace').read().split('\n')[ln - 1] if ln <= len(
            open(p, encoding='utf-8', errors='replace').read().split('\n')) else ''
        if not line.strip() or line.lstrip().startswith('#'):
            rows.append((rel, ln, var, 'LINE-EXPLAIN-FAILED', False, None)); continue
        if 'abspath(__file__)' in line:
            m = re.match(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*(?:#.*)?$', line)
            if not m:
                rows.append((rel, ln, var, 'EXTRACT-FAILED', False, None)); continue
            try:
                got = eval(m.group(2), {'os': os, 'sys': sys, '__file__': p})
            except Exception as e:
                got = 'EVAL-ERROR:%s' % e
        else:
            inj = line.replace('${BASH_SOURCE[0]}', p)
            if re.search(r'for\s+%s\s+in' % re.escape(var), inj):
                sub = inj[inj.index('$('):inj.rindex(')') + 1]
                r = subprocess.run(['bash', '-c', 'echo %s' % sub], capture_output=True, text=True)
                got = r.stdout.strip() if r.returncode == 0 else 'EVAL-RC=%d' % r.returncode
            else:
                r = subprocess.run(['bash', '-c', 'set -u\n%s\necho "${%s}"\n' % (inj, var)],
                                   capture_output=True, text=True)
                got = r.stdout.strip() if r.returncode == 0 else 'EVAL-RC=%d' % r.returncode
        cons = None
        if suffix is not None:
            cons = (os.path.exists(os.path.join(root, suffix)), os.path.exists(os.path.join(root, 'build', suffix)))
        rows.append((rel, ln, var, got, got == root, cons))
    ok = sum(1 for r in rows if r[4]); bad = len(rows) - ok
    cons_rows = [r for r in rows if r[5] is not None]
    cons_ok = sum(1 for r in cons_rows if r[5][0] and not r[5][1])
    for rel, ln, var, got, good, cons in rows:
        if not good:
            print('WFREEZE_ROOTDEFAULT_HIT file=%s line=%d var=%s got=%s want=%s（派生式解析到的**不是仓根**）' % (rel, ln, var, got, root))
        elif cons is not None and not (cons[0] and not cons[1]):
            print('WFREEZE_ROOTDEFAULT_HIT file=%s line=%d var=%s（消费点拼出来的路径不存在：root=%s build=%s）' % (rel, ln, var, cons[0], cons[1]))
    state = 'PASS' if (bad == 0 and cons_ok == len(cons_rows) and rows) else ('NOINFO' if not rows else 'FAIL')
    print('WFREEZE_ROOTDEFAULT=%s exprs=%d ok=%d bad=%d consume=%d consume_ok=%d'
          % (state, len(rows), ok, bad, len(cons_rows), cons_ok))
    return state


def _gens_from_ast(tree):
    """从冻结器源码里**只读**取出 `GENS` 表（条目是 `dict(...)` 调用 ⇒ 不能用 `literal_eval` 一把梭）。"""
    def val(v):
        try: return ast.literal_eval(v)
        except Exception: return None
    for n in tree.body:
        if isinstance(n, ast.Assign) and any(getattr(t, 'id', '') == 'GENS' for t in n.targets):
            outer = n.value
            if not isinstance(outer, ast.Dict): continue
            d = {}
            for k, v in zip(outer.keys, outer.values):
                key = val(k)
                if isinstance(v, ast.Call):
                    d[key] = dict((kw.arg, val(kw.value)) for kw in v.keywords)
                elif isinstance(v, ast.Dict):
                    d[key] = dict((val(kk), val(vv)) for kk, vv in zip(v.keys, v.values))
            return d
    return None


# ── 档 ② ────────────────────────────────────────────────────────────────────────
def sec_decl(root, freezer, decl_override=None):
    if decl_override:
        decls = [decl_override]
    else:
        decls = []
        for f in sorted(glob.glob(os.path.join(root, 'docs', 'WAVE*-PREREGISTRATION.md'))):
            for l in open(f, encoding='utf-8', errors='replace').read().split('\n'):
                m = re.match(r'^\s*WFREEZE-DECL:\s*(.+)$', l)
                if m: decls.append((f, m.group(1).strip()))
    if not decls:
        print('WFREEZE_DECL=NOINFO reason=no-WFREEZE-DECL-line（预登记里没有机读声明行 ⇒ 算不出来，**不算绿**）')
        return 'NOINFO'
    def parse(s):
        d = {}
        for tok in s.split():
            if '=' in tok:
                k, v = tok.split('=', 1); d[k] = v
        return d
    # 取**最大世代号**那条声明（历史声明保留在语料里，不许因为老代没进 GENS 就红）
    best = None
    for item in decls:
        s = item if isinstance(item, str) else item[1]
        d = parse(s)
        g = d.get('gen', '')
        m = re.match(r'^#(\d+)$', g)
        if m and (best is None or int(m.group(1)) > best[0]):
            best = (int(m.group(1)), g, d, (item if isinstance(item, str) else item[0]))
    if best is None:
        print('WFREEZE_DECL=NOINFO reason=gen-unparseable decls=%d' % len(decls))
        return 'NOINFO'
    _, gen, d, src = best
    if not os.path.exists(freezer):
        print('WFREEZE_DECL=NOINFO reason=freezer-absent path=%s（仓外仪器取不到 ⇒ 算不出来）' % freezer)
        return 'NOINFO'
    try:
        tree = ast.parse(open(freezer, encoding='utf-8', errors='replace').read())
        G = _gens_from_ast(tree)
        assert G
    except Exception as e:
        print('WFREEZE_DECL=NOINFO reason=gens-unreadable %s' % e)
        return 'NOINFO'
    if gen not in G:
        print('WFREEZE_DECL=NOINFO reason=gens-has-no-entry gen=%s（声明了本代、冻结器里没有 ⇒ 算不出来）' % gen)
        return 'NOINFO'
    g = G[gen]
    allow_g = ','.join(sorted(g.get('allow_changed', {'pf'})))
    allow_d = ','.join(sorted((d.get('allow_changed') or '').split(','))) if d.get('allow_changed') else None
    pf_g = bool(g.get('pf_required', True))
    pf_d = (d.get('pf_required') == 'True')
    bad = []
    if allow_d is None: bad.append('decl-missing-field allow_changed')
    elif allow_d != allow_g: bad.append('allow_changed decl=%s gens=%s' % (allow_d, allow_g))
    if 'pf_required' not in d: bad.append('decl-missing-field pf_required')
    elif pf_d != pf_g: bad.append('pf_required decl=%s gens=%s' % (pf_d, pf_g))
    for b in bad:
        print('WFREEZE_DECL_HIT %s（源 %s）' % (b, src))
    st = 'FAIL' if bad else 'PASS'
    print('WFREEZE_DECL=%s gen=%s allow_changed_decl=%s allow_changed_gens=%s pf_required_decl=%s pf_required_gens=%s src=%s'
          % (st, gen, allow_d, allow_g, pf_d, pf_g, os.path.basename(src if isinstance(src, str) else str(src))))
    return st

# ── 档 ③ ────────────────────────────────────────────────────────────────────────
def sec_nineauth(root, pairs=None):
    pairs = NINEAUTH if pairs is None else pairs
    bad = 0
    for canon, copy in pairs:
        a, b = sha16(os.path.join(root, canon)), sha16(os.path.join(root, copy))
        if a is None or b is None:
            bad += 1
            print('WFREEZE_NINEAUTH_HIT kind=absent canon=%s(%s) copy=%s(%s)' % (canon, a, copy, b))
        elif a != b:
            bad += 1
            print('WFREEZE_NINEAUTH_HIT kind=diverged canon=%s=%s copy=%s=%s（**同名产物的两条「权威」路径分叉**：谁重建其一都会让判据两侧不一致）' % (canon, a, copy, b))
    st = 'PASS' if bad == 0 else 'FAIL'
    print('WFREEZE_NINEAUTH=%s pairs=%d ok=%d bad=%d' % (st, len(pairs), len(pairs) - bad, bad))
    return st

# ── 自测（真跑；每一档都要有能红的臂）────────────────────────────────────────────
def selftest():
    npass = nfail = 0
    def arm(name, ok, detail):
        nonlocal npass, nfail
        print('SELFTEST %-8s %s :: %s' % (name, 'OK' if ok else '**FAIL**', detail))
        if ok: npass += 1
        else: nfail += 1
    T = tempfile.mkdtemp(prefix='wfreeze-st-')
    try:
        # S1 正极：把 roster 的件按同相路径镜像进沙箱 ⇒ 档① PASS
        for rel, _l, _v, _s in ROSTER:
            d = os.path.join(T, 'good', rel); os.makedirs(os.path.dirname(d), exist_ok=True)
            shutil.copy2(os.path.join(SELF_ROOT, rel), d)
        for _rel, _l, _v, suf in ROSTER:
            if suf:
                # ⚠️ **只**在镜像仓根下造消费点（不在 `<镜像>/build/` 下造）—— 否则"用错根也能拼出存在的路径"
                #    ⇒ 那一档就失去了判别力（本档的两条判据是"根对" ∧ "错根拼出来的**不**存在"）。
                p = os.path.join(T, 'good', suf); os.makedirs(os.path.dirname(p), exist_ok=True)
                open(p, 'w').write('x')
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'good'),
                              '--freezer', '/nonexistent'],
                             capture_output=True, text=True).stdout
        arm('S1', 'WFREEZE_ROOTDEFAULT=PASS' in out, '干净镜像 ⇒ 档① PASS（其余两档 NOINFO，不算绿）')
        # S2 反极：把某一件的 dirname 砍掉一层 ⇒ 档① 必红并点名
        shutil.rmtree(os.path.join(T, 'bad'), ignore_errors=True)
        shutil.copytree(os.path.join(T, 'good'), os.path.join(T, 'bad'))
        p = os.path.join(T, 'bad', 'build/MilBridge/tools/analyze-layout-b34.py')
        s = open(p, encoding='utf-8').read()
        s = s.replace('os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(',
                      'os.path.dirname(os.path.dirname(os.path.dirname(', 1)
        open(p, 'w', encoding='utf-8').write(s)
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'bad'),
                              '--freezer', '/nonexistent'], capture_output=True, text=True).stdout
        arm('S2', 'WFREEZE_ROOTDEFAULT=FAIL' in out and 'file=build/MilBridge/tools/analyze-layout-b34.py' in out,
            '少一层 dirname ⇒ 档① FAIL 并点名该件')
        # S3 反极：声明与 GENS 不符 ⇒ 档② FAIL
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', SELF_ROOT,
                              '--decl-override', 'gen=#77 allow_changed=pf pf_required=True'],
                             capture_output=True, text=True).stdout
        arm('S3', ('WFREEZE_DECL=FAIL' in out) or ('WFREEZE_DECL=NOINFO' in out and 'freezer-absent' in out),
            '声明 `{pf}/True` vs GENS 实测 ⇒ FAIL（或冻结器取不到 ⇒ NOINFO，均非绿）')
        # S4 反极：权威路径分叉 ⇒ 档③ FAIL
        os.makedirs(os.path.join(T, 'na', 'a/p'), exist_ok=True); os.makedirs(os.path.join(T, 'na', 'a/q'), exist_ok=True)
        open(os.path.join(T, 'na', 'a/p/x.dll'), 'w').write('1'); open(os.path.join(T, 'na', 'a/q/x.dll'), 'w').write('2')
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'na'),
                              '--pairs-override', 'a/p/x.dll,a/q/x.dll'], capture_output=True, text=True).stdout
        arm('S4', 'WFREEZE_NINEAUTH=FAIL' in out, '两条「权威」路径内容不同 ⇒ 档③ FAIL')
        # S5 正极：两条相同 ⇒ 档③ PASS
        shutil.copy2(os.path.join(T, 'na', 'a/p/x.dll'), os.path.join(T, 'na', 'a/q/x.dll'))
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'na'),
                              '--pairs-override', 'a/p/x.dll,a/q/x.dll'], capture_output=True, text=True).stdout
        arm('S5', 'WFREEZE_NINEAUTH=PASS' in out, '两条一致 ⇒ 档③ PASS')
    finally:
        shutil.rmtree(T, ignore_errors=True)
    print('WFREEZE_CONSISTENCY_SELFTEST=%s cases=%d pass=%d fail=%d' % ('PASS' if nfail == 0 else 'FAIL', npass + nfail, npass, nfail))
    return 0 if nfail == 0 else 1

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default=SELF_ROOT)
    ap.add_argument('--freezer', default=os.path.expanduser('~/w21-verify/w27-freeze.py'))
    ap.add_argument('--decl-override'); ap.add_argument('--pairs-override')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest: return selftest()
    root = os.path.realpath(a.root)
    s1 = sec_rootdefault(root)
    s2 = sec_decl(root, a.freezer, a.decl_override)
    pairs = None
    if a.pairs_override:
        pairs = [tuple(x.split(',')) for x in a.pairs_override.split(';')]
    s3 = sec_nineauth(root, pairs)
    st = [s1, s2, s3]
    overall = 'FAIL' if 'FAIL' in st else ('NOINFO' if 'NOINFO' in st else 'PASS')
    print('WFREEZE_CONSISTENCY=%s rootdefault=%s decl=%s nineauth=%s' % (overall, s1, s2, s3))
    return {'PASS': 0, 'FAIL': 1, 'NOINFO': 3}[overall]

if __name__ == '__main__':
    sys.exit(main())

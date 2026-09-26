#!/usr/bin/env bash
# ============================================================================
#  backup-completeness-gate.sh  ·  车道 W163A-TEETHGUARD · TASK-0725
#  `D-G126`（发布/回复点缺陷 · 备份集在落地集之外冻结）的**会红的牙**：
#  **落地前**逐件断言『每件都有备份 ∧ 备份 sha16 == 覆盖前现读 sha16』，
#  缺一 ⇒ **FAIL ＋ 点名 ＋ 非零 rc**（**不是警告**）。
#
#  口径句（逐字采纳；见 $R/samples/WpfFeatureProbe/KNOWN-DEFECTS.md 的 D-G126 条目）：
#    "备份/回复点集合必须在读完全部落地目标之后才冻结；且覆盖前必须断言
#     『每件都有备份 ∧ 备份 sha16 == 覆盖前现读 sha16』，缺一即拒落。"
#
#  `TASK-0725` 落仓补丁（`#69`，车道 W167A）已叠加：**去车道名** —— 备份根/selftest 沙箱默认值
#  不再指向 `~/w163a`（改为仓外 `$HOME/.cache/wpf-linux`，仍可由 `WPF_BCG_BACKUP_ROOT`／
#  `WPF_BCG_WORK`／`WPF_BCG_REPO` 覆盖）⇒ 落仓后的牙**不写别的车道目录**。**判定语义零改动**。
#  设计要点（判据见产源车道 W163A 的 `criteria.md` §B）：
#   · **plan 先读全、再逐件核**（集合冻结在读完全部目标之后）；
#   · **备份一律真拷贝**：本牙额外断言备份件 `stat -c %h == 1`（同 inode 的"备份"不是备份）；
#   · 三态：PASS=rc0 ／ FAIL=rc1 ／ NOINFO=rc3 ／ 用法错=rc2；
#   · **零检查报红**：examined==0（空 plan）⇒ FAIL；
#   · 真 rc 直接取自本脚本自身；`--selftest` 三态全部落在 `~/w163a/` 沙箱。
# ============================================================================
set -u

usage() {
  cat <<'USAGE'
backup-completeness-gate.sh — `D-G126` 牙：落地前的备份完备性断言

用法：
  backup-completeness-gate.sh --plan <PLAN.tsv> [--repo <DIR>] [--backup-root <DIR>]
  backup-completeness-gate.sh --selftest

PLAN.tsv 每行：<relpath>\t<mod|new>[\t<备注>]
  mod = 本次要覆盖的既有件（**必须**有备份且备份 sha16 == 覆盖前现读）
  new = 本次新建的件（无需备份；但仍进 examined 计数并逐行报告）
  '#' 开头与空行忽略。

选项：
  --backup-root <DIR>  备份根（默认 $W163A_BACKUP_ROOT 或 ~/w163a/backup/pre-land）
  --repo <DIR>         权威树（默认 $W163A_R 或本工程默认路径）
  --json-no            保留位（本工具不输出 JSON；恒为纯文本）

退出码：0=PASS ／ 1=FAIL ／ 3=NOINFO ／ 2=用法错
机读行：BCG=<PASS|FAIL|NOINFO|USAGE> examined=<n> need_backup=<n> ok=<n> new=<n> missing=<n> mismatch=<n> notreg=<n> rc=<n>
      遇违约另有逐条：BLAME=<rel> kind=<missing|mismatch|not-regular|ambiguous> expect=<sha16|-> actual=<sha16|->
USAGE
}

# 波 `#77` 旧路径重指向：仓根**现推**（`verify-all.sh:192`／`close-wave.sh:31` 同法）
BCG_DEFROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
export WPF_BCG_DEFROOT="$BCG_DEFROOT"
GATE_REPO="${WPF_BCG_REPO:-${W163A_R:-$BCG_DEFROOT}}"
GATE_BK="${WPF_BCG_BACKUP_ROOT:-${W163A_BACKUP_ROOT:-$HOME/.cache/wpf-linux/backup/pre-land}}"
PLAN=""
MODE="check"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)        PLAN="${2:-}"; shift 2 ;;
    --repo)        GATE_REPO="${2:-}"; shift 2 ;;
    --backup-root) GATE_BK="${2:-}"; shift 2 ;;
    --selftest)    MODE="selftest"; shift ;;
    --json-no)     shift ;;
    -h|--help)     usage; exit 2 ;;
    *) echo "backup-completeness-gate.sh: 未知参数 '$1'" >&2; usage >&2; exit 2 ;;
  esac
done
if [[ "$MODE" == "check" && -z "$PLAN" ]]; then
  echo "backup-completeness-gate.sh: 必须给 --plan（或用 --selftest）" >&2; usage >&2; exit 2
fi

python3 - "$MODE" "$GATE_REPO" "$GATE_BK" "$PLAN" <<'PYEOF'
# -*- coding: utf-8 -*-
# 牙的实现；真 rc 由上面的 bash 壳对外（不经管道尾取）。
import os, sys, time, hashlib, shutil, tempfile, stat as statmod

MODE, REPO, BKROOT, PLAN = sys.argv[1:5]
WORK = os.path.expanduser(os.environ.get('WPF_BCG_WORK', '~/.cache/wpf-linux'))
SANDBOX = os.path.join(WORK, 'sandbox-bcg')

def wr(path, text, mode=0o644):
    d = os.path.dirname(path)
    if d: os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d or '.', prefix='.tmp-')
    with os.fdopen(fd, 'w', encoding='utf-8') as f: f.write(text)
    os.chmod(tmp, mode); os.replace(tmp, path)

def sha16(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()[:16]

def read_plan(plan_path):
    """**先把 plan 全部读完**（集合在读完全部落地目标**之后**才冻结），再逐件核。"""
    rows = []
    with open(plan_path, encoding='utf-8') as f:
        for ln, line in enumerate(f, 1):
            s = line.rstrip('\n')
            if not s.strip() or s.lstrip().startswith('#'): continue
            parts = s.split('\t')
            if len(parts) < 2:
                parts = s.split(None, 1)          # 容错：空白分隔
            if len(parts) < 2:
                rows.append({'rel': s.strip(), 'kind': '', 'line': ln, 'bad_shape': True}); continue
            rel, kind = parts[0].strip(), parts[1].strip().lower()
            rows.append({'rel': rel, 'kind': kind, 'line': ln, 'bad_shape': False,
                         'note': parts[2].strip() if len(parts) > 2 else ''})
    return rows

def backup_candidates(rel, bkroot):
    a = os.path.join(bkroot, rel)                          # 原样相对路径
    b = os.path.join(bkroot, rel.replace('/', '-'))        # 扁平命名
    return [a, b]

def check_rows(rows, repo, bkroot, verbose=True):
    """逐件核。返回 (counters, blames)。"""
    c = {'examined': 0, 'need_backup': 0, 'ok': 0, 'new': 0,
         'missing': 0, 'mismatch': 0, 'notreg': 0, 'ambiguous': 0, 'badshape': 0}
    blames = []
    for r in rows:
        c['examined'] += 1
        rel = r['rel']
        tgt = os.path.join(repo, rel)
        if r['bad_shape']:
            c['badshape'] += 1
            blames.append((rel, 'bad-plan-line', '-', '-'))
            if verbose: print("  %-58s **plan 行形状错**（缺 mod/new 列）" % rel)
            continue
        # 目标必须存在 且 是普通文件（否则不是"覆盖既有件"）
        tgt_state, tgt_sha, tgt_h = 'absent', '-', '-'
        if os.path.lexists(tgt):
            st = os.lstat(tgt)
            if not statmod.S_ISREG(st.st_mode):
                c['notreg'] += 1
                blames.append((rel, 'not-regular(target)', '-', '-'))
                if verbose: print("  %-58s **目标不是普通文件**（模式 0%o）" % (rel, statmod.S_IFMT(st.st_mode)))
                continue
            tgt_sha = sha16(tgt); tgt_h = st.st_nlink; tgt_state = 'file'
        if r['kind'] == 'new':
            c['new'] += 1
            if tgt_state == 'file':
                print("  %-58s **plan 说 new，但目标已存在** ⇒ 其实是覆盖，必须有备份" % rel)
                c['new'] -= 1; c['need_backup'] += 1
                # 落到下面按"需备份"重判
            else:
                if verbose: print("  %-58s 新建 ⇒ 无需备份（现读=%s）" % (rel, '(不存在)'))
                c['ok'] += 1
                continue
        if r['kind'] not in ('new', 'mod', ''):
            c['badshape'] += 1
            blames.append((rel, 'bad-plan-line(kind=%s)' % r['kind'], '-', '-'))
            if verbose: print("  %-58s **plan 第二列非法**：'%s'（只允许 mod/new）" % (rel, r['kind']))
            continue

        c['need_backup'] += 1
        cands = [p for p in backup_candidates(rel, bkroot) if os.path.lexists(p)]
        cands = list(dict.fromkeys(cands))
        if not cands:
            c['missing'] += 1
            blames.append((rel, 'missing', tgt_sha, '-'))
            if verbose: print("  %-58s **无备份**（现读=%s）⇒ **拒落**" % (rel, tgt_sha))
            continue
        # 备份件必须是**普通文件**且 **h==1**（同 inode 的"备份"不是备份）
        # 逐行**只归一类**（优先级：missing > notreg > mismatch），计数才不会把同一件数两次
        good = None; seen = []; why = None
        for p in cands:
            st = os.lstat(p)
            if not statmod.S_ISREG(st.st_mode):
                why = 'not-regular(backup=%s)' % os.path.relpath(p, bkroot)
                if verbose: print("  %-58s **备份不是普通文件**：%s ⇒ **拒落**" % (rel, os.path.relpath(p, bkroot)))
                continue
            if st.st_nlink != 1:
                why = 'backup-hardlinked(h=%d)' % st.st_nlink
                if verbose: print("  %-58s **备份件 h=%d（硬链接）** ⇒ 不是备份 ⇒ **拒落**"
                                  % (rel, st.st_nlink))
                continue
            h = sha16(p); seen.append((os.path.relpath(p, bkroot), h))
            if h == tgt_sha: good = (os.path.relpath(p, bkroot), h)
        if good:
            c['ok'] += 1
            if verbose:
                print("  %-58s OK  备份=%s  sha16=%s  h(目标)=%d" % (rel, good[0], good[1], tgt_h))
        elif why:
            c['notreg'] += 1
            blames.append((rel, why, tgt_sha, '-'))
        else:
            c['mismatch'] += 1
            blames.append((rel, 'mismatch', tgt_sha, '/'.join(h for _, h in seen) or '-'))
            if verbose:
                print("  %-58s **备份 ≠ 覆盖前现读**（现读=%s；备份=%s）⇒ **拒落**"
                      % (rel, tgt_sha, '/'.join('%s(%s)' % (n, h) for n, h in seen) or '(无)'))
    return c, blames

def emit(c, blames, extra=None, verbose=True):
    if c['examined'] == 0:
        verdict, reason = 'FAIL', 'zero-examined'
    elif blames:
        verdict, reason = 'FAIL', 'backup-incomplete'
    else:
        verdict, reason = 'PASS', 'all-backed-up-and-matching'
    if verbose:
        print()
        for rel, kind, expect, actual in blames:
            print("BLAME=%s kind=%s expect=%s actual=%s" % (rel, kind, expect, actual))
        print("--- 计数器 ---")
        print("examined（逐件检查过的 plan 行） = %d" % c['examined'])
        print("need_backup（其中需备份的非新建件） = %d" % c['need_backup'])
        print("ok=%d  new=%d  missing=%d  mismatch=%d  notreg=%d  badshape=%d"
              % (c['ok'], c['new'], c['missing'], c['mismatch'], c['notreg'], c['badshape']))
    rc = 0 if verdict == 'PASS' else (3 if verdict == 'NOINFO' else 1)
    print("BCG=%s examined=%d need_backup=%d ok=%d new=%d missing=%d mismatch=%d notreg=%d badshape=%d rc=%d reason=%s"
          % (verdict, c['examined'], c['need_backup'], c['ok'], c['new'],
             c['missing'], c['mismatch'], c['notreg'], c['badshape'], rc, reason))
    return rc

# ------------------------------------------------------------------ selftest
def selftest():
    print("=== backup-completeness-gate.sh --selftest（沙箱 %s；**$R 只读**）===" % SANDBOX)
    shutil.rmtree(SANDBOX, ignore_errors=True)
    repo = os.path.join(SANDBOX, 'repo')
    bk   = os.path.join(SANDBOX, 'backup')
    plan = os.path.join(SANDBOX, 'plan.tsv')
    # 沙箱里的"既有件"（真拷贝，%h==1）
    rels = ['build/close-wave.sh', 'build/MilBridge/tools/shell-quote-trap-check.sh', 'docs/PREREG-TEMPLATE.md']
    srcs = {
        'build/close-wave.sh': '#!/bin/sh\necho close-wave v1\n',
        'build/MilBridge/tools/shell-quote-trap-check.sh': '#!/bin/sh\necho trap-check v1\n',
        'docs/PREREG-TEMPLATE.md': '# 预登记模板 v1\n',
    }
    for rel in rels:
        wr(os.path.join(repo, rel), srcs[rel])
        wr(os.path.join(bk, rel), srcs[rel])            # 备份 = 真拷贝、内容同版
    wr(plan, "".join("%s\tmod\n" % r for r in rels) + "docs/NEW-FILE.md\tnew\n")

    def snap(root):
        """沙箱/权威树的 (rel → (size, mtime_ns, ino, nlink)) 快照（证明没被本牙写过）。"""
        d = {}
        if not os.path.isdir(root): return d
        for dp, dn, fns in os.walk(root):
            for fn in fns:
                p = os.path.join(dp, fn)
                try: s = os.lstat(p)
                except OSError: continue
                d[os.path.relpath(p, root)] = (s.st_size, s.st_mtime_ns, s.st_ino, s.st_nlink)
        return d

    before_repo_sb = snap(repo)          # 沙箱"权威树"起点
    before_repo_sha = {k: sha16(os.path.join(repo, k)) for k in before_repo_sb}
    R_REAL = os.environ.get('WPF_BCG_REPO') or os.environ.get('W163A_R') or os.environ.get('WPF_BCG_DEFROOT') or REPO
    before_R = snap(R_REAL) if os.path.isdir(R_REAL) else {}

    results = []
    def leg_index(rows):
        return {r['rel']: r for r in rows}

    # ---- ① 正例：备份齐备且版本正确 ⇒ 拒落 0
    print("\n① **正例**（plan 齐全 ＋ 备份齐备且版本正确）⇒ 期望 拒落=0 / PASS")
    rows = read_plan(plan)
    c, bl = check_rows(rows, repo, bk)
    rc_pos = emit(c, bl)
    ok_pos = (rc_pos == 0 and not bl and c['examined'] == 4 and c['need_backup'] == 3)
    print("   ⇒ rc=%d 拒落=%d examined=%d（期望 0/0/4）  %s" % (rc_pos, len(bl), c['examined'], 'OK' if ok_pos else '**错**'))
    results.append(('正例', ok_pos))

    # ---- ② 反例 A：备份**缺失**（把某件的备份移开）
    print("\n② **反例 A（备份缺失）**：把 shell-quote-trap-check.sh 的备份移开 ⇒ 期望 拒落≥1 / FAIL")
    bkp = os.path.join(bk, 'build/MilBridge/tools/shell-quote-trap-check.sh')
    stash = bkp + '.stash'
    os.rename(bkp, stash)
    rows = read_plan(plan)
    c, bl = check_rows(rows, repo, bk)
    rc_a = emit(c, bl)
    ok_a = (rc_a == 1 and any(k == 'missing' for _, k, _, _ in bl) and c['missing'] == 1)
    print("   ⇒ rc=%d 拒落=%d missing=%d（期望 1/≥1/1）  %s" % (rc_a, len(bl), c['missing'], 'OK' if ok_a else '**错**'))
    os.rename(stash, bkp)
    results.append(('反例A 备份缺失', ok_a))

    # ---- ③ 反例 B：备份**存在但错版本**（把沙箱里那一件改成别的内容）
    print("\n③ **反例 B（备份错版本）**：把 close-wave.sh 的目标内容改掉（备份仍旧版）⇒ 期望 拒落≥1 / FAIL")
    tp = os.path.join(repo, 'build/close-wave.sh')
    open(tp, 'a').write("# 🧪 注入：目标被改成新内容（模拟「要落地的新版本」）\n")
    rows = read_plan(plan)
    c, bl = check_rows(rows, repo, bk)
    rc_b = emit(c, bl)
    ok_b = (rc_b == 1 and any(k == 'mismatch' for _, k, _, _ in bl) and c['mismatch'] == 1)
    print("   ⇒ rc=%d 拒落=%d mismatch=%d（期望 1/≥1/1）  %s" % (rc_b, len(bl), c['mismatch'], 'OK' if ok_b else '**错**'))
    results.append(('反例B 备份错版本', ok_b))
    wr(tp, srcs['build/close-wave.sh'])                   # 还原（让 ④ 的读数干净、不叠 ③ 的注入）

    # ---- ④ 反例 C：备份与目标**同 inode**（硬链接"备份"不是备份）⇒ 必须拒落
    print("\n④ **反例 C（备份是硬链接）**：把某件的备份换成指向目标的硬链接 ⇒ 期望 拒落≥1 / FAIL")
    tp2 = os.path.join(repo, 'docs/PREREG-TEMPLATE.md')
    bp2 = os.path.join(bk, 'docs/PREREG-TEMPLATE.md')
    os.unlink(bp2); os.link(tp2, bp2)                     # 真硬链接（**只在沙箱里**）
    rows = read_plan(plan)
    c, bl = check_rows(rows, repo, bk)
    rc_c = emit(c, bl)
    ok_c = (rc_c == 1 and any(k.startswith('backup-hardlinked') for _, k, _, _ in bl)
            and c['mismatch'] == 0 and c['missing'] == 0)
    print("   ⇒ rc=%d 拒落=%d notreg=%d（期望 1/1/1，且 mismatch=0）  %s"
          % (rc_c, len(bl), c['notreg'], 'OK' if ok_c else '**错**'))
    os.unlink(bp2); wr(bp2, srcs['docs/PREREG-TEMPLATE.md'])
    results.append(('反例C 备份是硬链接', ok_c))

    # ---- ⑤ 零检查：空 plan ⇒ 必须报红（不得假绿）
    print("\n⑤ **零检查**：空 plan ⇒ 期望 FAIL（**零检查不许假绿**）")
    empty = os.path.join(SANDBOX, 'empty.tsv')
    wr(empty, "# 只有注释\n\n")
    rows = read_plan(empty)
    c, bl = check_rows(rows, repo, bk)
    rc_z = emit(c, bl)
    ok_z = (rc_z != 0 and c['examined'] == 0)
    print("   ⇒ rc=%d examined=%d（期望 rc≠0、examined=0）  %s" % (rc_z, c['examined'], 'OK' if ok_z else '**错**'))
    results.append(('零检查 空plan', ok_z))

    # ---- ⑥ 沙箱卫生：沙箱内不得出现硬链接残留（除反例 C 自己造的那一次，已还原）
    hs = {}
    for dp, dn, fns in os.walk(SANDBOX):
        for fn in fns:
            s = os.lstat(os.path.join(dp, fn))
            hs[s.st_nlink] = hs.get(s.st_nlink, 0) + 1
    print("\n⑥ 沙箱链接数分布（应全为 1；出现 >1 说明反例 C 的链接没还原）：%s"
          % "  ".join("h=%d:%d件" % (k, hs[k]) for k in sorted(hs)))
    ok_h = all(k == 1 for k in hs)
    results.append(('沙箱无硬链接残留', ok_h))

    # ---- ⑦ 本牙**不改读**对象：沙箱"权威树"与真 `$R` 在自己这趟里都必须零字节改动
    after_repo_sb = snap(repo)
    after_R = snap(R_REAL) if os.path.isdir(R_REAL) else {}
    new_in_sb = sorted(set(after_repo_sb) - set(before_repo_sb))
    # 沙箱里唯一允许的变动 = 反例 ③ 的注入（且**已还原**）⇒ 逐**字节**回比（不是只看尺寸）
    changed = [k for k in before_repo_sha
               if k not in after_repo_sb or sha16(os.path.join(repo, k)) != before_repo_sha[k]]
    ok_no_write = not new_in_sb and not changed
    print("\n⑦ 写入自证：沙箱新增件=%s ／ 逐字节回比**不相等的件**=%s  ⇒ %s"
          % (new_in_sb or '(无)', changed or '(无)', 'OK' if ok_no_write else '**本牙写了不该写的东西**'))
    results.append(('沙箱零写入自证（逐字节）', ok_no_write))

    dR = []
    if R_REAL and before_R:
        aR = after_R
        dR = sorted(set(aR) - set(before_R)) + sorted(k for k in set(aR) & set(before_R)
                                                     if aR[k][:2] != before_R[k][:2])
    print("   权威树 $R=%s：selftest 前后件数 %d → %d，差异 %d 条 %s"
          % (R_REAL, len(before_R), len(after_R), len(dR), '⇒ **有差异，必须解释**' if dR else '⇒ 零差异'))
    print("   （注：$R 可能**同时**被别的车道改动 ⇒ 有差异需逐条归因；本牙只做 read 系系统调用）")
    results.append(('$R 只读自证（同趟前后逐位比较）', len(dR) == 0))

    bad = [n for n, g in results if not g]
    verdict = 'PASS' if not bad else 'FAIL'
    print("\nLEGS=" + " ".join("%s=%s" % (n, 'OK' if g else 'BAD') for n, g in results))
    print("BCG-SELFTEST=%s legs=%d bad=%d" % (verdict, len(results), len(bad)))
    return 0 if verdict == 'PASS' else 1

if MODE == 'selftest':
    sys.exit(selftest())

# ------------------------------------------------------------------ check
t0 = time.time()
if not os.path.isdir(REPO):
    print("!! --repo 不是目录：%s" % REPO)
    print("BCG=FAIL examined=0 need_backup=0 ok=0 new=0 missing=0 mismatch=0 notreg=0 badshape=0 rc=1 reason=zero-examined")
    sys.exit(1)
if not os.path.isfile(PLAN):
    print("!! --plan 不存在：%s" % PLAN)
    print("BCG=FAIL examined=0 need_backup=0 ok=0 new=0 missing=0 mismatch=0 notreg=0 badshape=0 rc=1 reason=zero-examined")
    sys.exit(1)
if not os.path.isdir(BKROOT):
    print("!! --backup-root 不是目录：%s ⇒ **每个需要备份的件都会判 missing**（这本身会 FAIL，不是静默放行）" % BKROOT)
print("=== backup-completeness-gate.sh · `D-G126` 牙（落地**前**）===")
print("repo        = %s" % REPO)
print("backup-root = %s" % BKROOT)
print("plan        = %s" % PLAN)
rows = read_plan(PLAN)                                 # ← **plan 先读全**，再逐件核
print("plan 行数（读完才冻结备份集合）= %d  已读 %.2fs" % (len(rows), time.time() - t0))
print()
c, bl = check_rows(rows, REPO, BKROOT)
rc = emit(c, bl)
sys.exit(rc)
PYEOF
rc=$?
exit "$rc"

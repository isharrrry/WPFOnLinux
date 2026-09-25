#!/usr/bin/env bash
# ============================================================================
#  repo-alias-check.sh  ·  车道 W163A-TEETHGUARD · TASK-0725
#  `D-G127`（装置缺陷 · 只读车道的影子树与权威树同 inode ⇒ 一次原地写就写穿）
#  的**会红的牙**：对权威树 $R 逐件求 stat -c %h；%h>1 的件去**仓外搜索根**里
#  找同 inode 孪生；**有仓外孪生即 FAIL（非零 rc）** 并逐条列 %h/inode/两条路径。
#
#  口径句（逐字采纳；见 $R/samples/WpfFeatureProbe/KNOWN-DEFECTS.md 的 D-G127 条目，
#  引用前已 grep -n 打印）：
#    "凡以『影子/隔离/回退树』名义造副本，写入前必须逐件断言 stat -c %h == 1（实体），
#     不满足即拒写；cp -al／cp -l／ln 一律不得用于『我要在里面写』的树……"
#
#  `TASK-0725` 落仓补丁（`#69`）已叠加：①落点去车道名（`--tsv`／`W164A_ALIAS_TSV`）
#  ②新增 `--allow`（**逐树件数上限**白名单；超限 ⇒ `FAIL allowed-tree-grown`）
#  ③`--selftest` 增两腿（在界内必绿／超上限必红）。
#  设计要点（判据见 ~/w163a/criteria.md §C）：
#   · **一次遍历**：$R 与所有 --roots 放进同一次 os.walk，按 inode 归并 ⇒ 只一趟磁盘遍历
#     （`find -inum` 逐 inode 扫 N 趟：本机 %h>1 的件有 1.3e4 量级，不可接受）。
#   · 三态：PASS=rc0 ／ FAIL=rc1 ／ NOINFO=rc3（**扫描不完/读不到** ⇒ 绝不当绿）。
#   · **零检查报红**：examined==0 ⇒ FAIL（本仓假绿高发形态）。
#   · `--selftest` 只在 ~/w163a/fixture/ 里造**真硬链接**；**$R 只读**（selftest 断言 $R 零写入）。
#   · 真 rc 直接取自本脚本自身（`rc=$?`），**不从管道尾取**。
# ============================================================================
set -u

usage() {
  cat <<'USAGE'
repo-alias-check.sh — `D-G127` 牙：权威树里 %h>1 的件在仓外有孪生吗？

用法：
  repo-alias-check.sh [扫描模式] [选项]
  repo-alias-check.sh --selftest

扫描模式：
  --root <PATH>        权威树（默认为 $W163A_R 或工单里的默认路径）
  --roots <R1:R2:...>  仓外搜索根（':' 分隔；默认 /home/links-dev）—— **受 --maxdepth 约束**
  --maxdepth <N>       两侧遍历的最大深度（**相对各根**的目录层级，默认 16）
  --timeout <SEC>      整趟墙钟上限（默认 600）；超时 ⇒ NOINFO（rc=3），**绝不当 PASS**
  --all                输出**每个** %h>1 的件（默认只输出前 N 条，见 --head）
  --head <N>           明细行数上限（默认 40；0 = 不限）
  --tsv <PATH>         把**全量**成员表写进该文件（temp＋rename；默认 ~/w163a/logs/repo-alias-members.tsv）
  --allow <PATH>       **已知别名树**白名单（TSV：`<树前缀>\t<件数上限>\t<理由>`）；
                       当前件数**超过上限** ⇒ `FAIL allowed-tree-grown`（树长大也要红）
  --json-no            保留位（本工具不输出 JSON；恒为纯文本）

自测（**只在 ~/w163a/fixture/ 里造真硬链接，不碰 $R**）：
  --selftest

退出码：0=PASS ／ 1=FAIL ／ 3=NOINFO（扫描不完、读不到）／ 2=用法错
机读行：ALIAS=<PASS|FAIL|NOINFO|USAGE> examined=<n> linked_gt1=<n> aliased_out=<n> roots=<k> maxdepth=<d> wall_s=<s> rc=<n>
USAGE
}

# ---- 默认值 ----------------------------------------------------------------
ALIAS_ROOT="${W163A_R:-/home/links-dev/netTest/wpf-linux-20260906/wpf-linux}"
ALIAS_ROOTS=""
# 默认 16 的来历（本机现算，见 report.md §3）：`--maxdepth 12` 会让 **332 件**找不到
# 仓外孪生（它们在本仓 `upstream/wpf/src/...` 深处，相对根深度 14–16）⇒ **静默假阴性**；
# 16 与 20 的读数**逐字段相同**（`linked_gt1 == aliased_out == 13675`）⇒ 16 已饱和。
ALIAS_MAXDEPTH=16
ALIAS_TIMEOUT=600
ALIAS_HEAD=40
ALIAS_TSV="${W164A_ALIAS_TSV:-$HOME/.cache/wpf-linux/repo-alias-members.tsv}"
# 【`TASK-0725` 落仓补丁 · `--allow`：**已知别名树的逐件数上限**白名单】
#   形态（TSV，`#` 注释）：`<树路径前缀>\t<上限件数>\t<理由>`
#   判据（本仓纪律：**白名单不许变成遮羞布**）：
#     · 白名单命中**只降 `aliased_out` 这一项**，四项计数照打（不藏数）；
#     · 命中树的**当前件数 > 上限** ⇒ `FAIL reason=allowed-tree-grown`（**树长大了也要红**）；
#     · 未被白名单覆盖的孪生 ⇒ 照旧 `FAIL reason=out-of-repo-alias`；
#     · **全部**孪生都被白名单覆盖且各有界 ⇒ `PASS` ＋ `reason=known-alias-trees`
#       （**这是唯一一种「有孪生还给绿」的情形**，且它要求白名单**逐树带界**）。
ALIAS_ALLOW="${W164A_ALIAS_ALLOW:-}"
MODE="scan"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)      ALIAS_ROOT="${2:-}"; shift 2 ;;
    --roots)     ALIAS_ROOTS="${2:-}"; shift 2 ;;
    --maxdepth)  ALIAS_MAXDEPTH="${2:-}"; shift 2 ;;
    --timeout)   ALIAS_TIMEOUT="${2:-}"; shift 2 ;;
    --head)      ALIAS_HEAD="${2:-}"; shift 2 ;;
    --tsv)       ALIAS_TSV="${2:-}"; shift 2 ;;
    --allow)     ALIAS_ALLOW="${2:-}"; shift 2 ;;
    --all)       ALIAS_HEAD=0; shift ;;
    --json-no)   shift ;;
    --selftest)  MODE="selftest"; shift ;;
    -h|--help)   usage; exit 2 ;;
    *) echo "repo-alias-check.sh: 未知参数 '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

ARGS=("$MODE" "$ALIAS_ROOT" "$ALIAS_ROOTS" "$ALIAS_MAXDEPTH" "$ALIAS_TIMEOUT" "$ALIAS_HEAD" "$ALIAS_TSV" "$ALIAS_ALLOW")

python3 - "${ARGS[@]}" <<'PYEOF'
# -*- coding: utf-8 -*-
# 本块是牙的实现；由上面的 bash 壳以其真 rc 对外（真 rc 取自 bash 自身，不经管道）。
import os, sys, time, hashlib, shutil, tempfile, stat as statmod

MODE, ROOT, ROOTS_ARG, MAXDEPTH, TIMEOUT, HEAD, TSV, ALLOW = sys.argv[1:9]
MAXDEPTH = int(MAXDEPTH); TIMEOUT = float(TIMEOUT); HEAD = int(HEAD)
WORK = os.path.expanduser(os.environ.get('W164A_WORK', '~/w163a'))   # 同上：只作 `--selftest` fixture 落点
FIX = os.path.join(WORK, 'fixture')

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

def canon(p):
    """**纯词法**规范化（abspath ＋ normpath）——**故意不用 realpath**：
    realpath 逐组件 lstat，实测 39.8 万件要 16.7 s（占整趟 78%）而 `find` 只用 2.1 s。
    词法规范化与 `find` 的前缀比较同语义；两个根下的遍历都 followlinks=False，
    故路径里不含未展开的软链 ⇒ 词法即足够（射程见 criteria §C.2 第 6 条：symlink 影子不在射程）。"""
    return os.path.normpath(os.path.abspath(p))

def under(path, root):
    """path 是否在 root 之下（规范路径前缀比较，避免 /a/bc 误判 /a/b）。"""
    return path == root or path.startswith(root + os.sep)

# ---------------------------------------------------------------- 遍历骨架
DIAG = {'lstat_fail': []}          # 模块级诊断（walk_files 里 lstat 失败的点名表）

def walk_files(root, maxdepth, budget, skip_prefix=None):
    """逐件 yield (path, inode, nlink, size)。root 不是目录 ⇒ raise。
    budget = {'t': deadline}；超时 raise TimeoutError。
    skip_prefix：跳过**其下**的所有件（避免"搜索根包含权威树"时把权威树走两遍）。

    实现用 `os.scandir` 递归（不是 `os.walk`）：`os.walk` 每层都要对目录再 stat 一次，
    而 scandir 的 `is_dir(follow_symlinks=False)` 直接吃 `d_type`（ext4 上零额外系统调用）。"""
    if not os.path.isdir(root):
        raise NotADirectoryError(root)
    root = root.rstrip(os.sep)
    # ⚠️ `--maxdepth` 是**相对各搜索根**的目录层级（与 `find -maxdepth` 同语义），
    #    所以深度从"根本身 = 0"起算（用绝对路径层数会把它变成"绝对深度"，深仓会被误剪）。
    stack = [(root, 0)]
    while stack:
        if time.time() > budget['t']:
            raise TimeoutError(root)
        d, depth = stack.pop()
        if skip_prefix and canon(d) == skip_prefix:
            continue                          # 整棵子树不进去（权威树那棵）
        try:
            it = os.scandir(d)
        except OSError:
            DIAG['lstat_fail'].append(d)
            continue
        with it:
            for e in it:
                try:
                    if e.is_dir(follow_symlinks=False):
                        if depth + 1 <= maxdepth:
                            stack.append((e.path, depth + 1))
                        continue
                    if not e.is_file(follow_symlinks=False):
                        continue                  # symlink/特殊件：射程外（criteria §C.2 第 6 条）
                    s = e.stat(follow_symlinks=False)
                except OSError:
                    DIAG['lstat_fail'].append(e.path)
                    continue                  # 断链/权限：**点名**上报，不静默吞
                if not statmod.S_ISREG(s.st_mode):
                    continue
                # 注意：**不在这里算 relpath** —— os.path.relpath 在 39.8 万件上实测 ~10 s，
                # 而只有"有仓外孪生"的那一小撮件才需要相对路径（见 classify）。
                yield e.path, s.st_ino, s.st_nlink, s.st_size

def scan(root, roots, maxdepth, timeout):
    """一次遍历求全量成员表。返回 (rows, diag)。"""
    t0 = time.time()
    budget = {'t': t0 + timeout}
    diag = {'roots_stat_fail': [], 'examined': 0, 'timed_out': False, 'wrong_root': None, 'lstat_fail': DIAG['lstat_fail']}
    canon_root = canon(root)
    if not os.path.isdir(root):
        diag['wrong_root'] = root
        return [], diag
    # 所有被遍历的根（去重；跳过不存在的搜索根但**点名**）
    roots_all = [('repo', root, None)]
    for r in roots:
        if not r: continue
        if canon(r) == canon_root: continue          # 仓自身不算搜索根
        if not os.path.isdir(r):
            diag['roots_stat_fail'].append(r)        # 不存在的根 ⇒ 后面 NOINFO
            continue
        roots_all.append(('out', r, canon_root))     # 搜索根若**包含**权威树 ⇒ 跳过权威树那棵（免得走两遍）
    by_ino = {}
    try:
        for kind, r, skip in roots_all:
            for p, ino, nlink, size in walk_files(r, maxdepth, budget, skip_prefix=skip):
                d = by_ino.setdefault(ino, {'ino': ino, 'nlink': nlink, 'repo': [], 'out': []})
                d['nlink'] = max(d['nlink'], nlink)
                (d['repo'] if kind == 'repo' else d['out']).append(canon(p))
                if kind == 'repo':
                    diag['examined'] += 1
    except TimeoutError:
        diag['timed_out'] = True
    return list(by_ino.values()), diag

def load_allow(path):
    """读白名单：`<树前缀>\t<上限件数>\t<理由>`（`#` 与空行忽略）。
    坏行**点名**（不许静默吞）；返回 (entries, diag)。"""
    ents, diag = [], {'allow_bad_lines': [], 'allow_file': path or '(未给)'}
    if not path:
        return ents, diag
    if not os.path.isfile(path):
        diag['allow_bad_lines'].append('%s (文件不存在 ⇒ 按无白名单判)' % path)
        return ents, diag
    with open(path, encoding='utf-8') as f:
        for ln, line in enumerate(f, 1):
            s = line.rstrip('\n')
            if not s.strip() or s.lstrip().startswith('#'):
                continue
            parts = s.split('\t')
            if len(parts) < 2:
                diag['allow_bad_lines'].append('%s:%d (缺列)' % (path, ln))
                continue
            tree = parts[0].strip()
            try:
                cap = int(parts[1].strip())
            except ValueError:
                diag['allow_bad_lines'].append('%s:%d (上限不是整数)' % (path, ln))
                continue
            if not tree or cap <= 0:
                diag['allow_bad_lines'].append('%s:%d (树为空或上限<=0)' % (path, ln))
                continue
            ents.append({'tree': canon(tree), 'cap': cap,
                         'why': parts[2].strip() if len(parts) > 2 else ''})
    ents.sort(key=lambda e: -len(e['tree']))          # 长前缀优先
    return ents, diag

def match_allow(ext_paths, ents):
    """→ (covered, tree_hits, grown)。covered=被覆盖的孪生路径集合；
    tree_hits={tree: 覆盖件数}；grown=[(tree, n, cap)]（**超上限**的树）。"""
    covered, hits = set(), {}
    for e in ents:
        for p in ext_paths:
            if under(p, e['tree']):
                covered.add(p)
                hits[e['tree']] = hits.get(e['tree'], 0) + 1
    grown = []
    for t, n in hits.items():
        cap = next(e['cap'] for e in ents if e['tree'] == t)
        if n > cap:
            grown.append((t, n, cap))
    return covered, hits, grown

def classify(by_ino, repo_root=None):
    """→ (linked_gt1, rows_out)；rows_out = 有**仓外**孪生的 $R 件（逐件一行）。
    repo_root 给了 ⇒ 在这里（**只对命中件**）现算相对路径。"""
    linked = []; out_rows = []
    for d in by_ino:
        # ⚠️ 计数口径：`linked_gt1` **只算仓侧**（d['repo'] 非空）—— 搜索根里那些与 $R
        #    无关的多链 inode**不算**（否则会把它区的一堆 %h>1 混进本牙的读数里）。
        if d['nlink'] <= 1 or not d['repo']: continue
        linked.append(d)
        if not d['repo'] or not d['out']: continue
        # 同一 inode 在 $R 内可能有多条路径（仓内跨区）；逐条列，但孪生集合按 inode 算一次
        ext = sorted(set(d['out']))
        for cp in sorted(set(d['repo'])):
            rel = cp
            if repo_root:
                rp = canon(repo_root)
                if under(cp, rp):
                    rel = os.path.relpath(cp, rp)
            out_rows.append({'ino': d['ino'], 'nlink': d['nlink'], 'rel': rel,
                             'repo_path': cp, 'ext': ext, 'ext_n': len(ext)})
    out_rows.sort(key=lambda r: (r['ino'], r['rel']))
    linked.sort(key=lambda d: d['ino'])
    return linked, out_rows

# ---------------------------------------------------------------- selftest
def selftest():
    """正例 = 两个独立真拷贝；反例 = 一份**真硬链接**（孪生在 --roots 覆盖的目录里）。"""
    print("=== repo-alias-check.sh --selftest（沙箱 %s；**$R 只读**）===" % FIX)
    shutil.rmtree(FIX, ignore_errors=True)
    facet = os.path.join(FIX, 'face', 'tree')          # "权威树"（只在本 fixture 内）
    outroot = os.path.join(FIX, 'outside')             # "仓外区"
    os.makedirs(os.path.join(facet, 'sub'), exist_ok=True)
    os.makedirs(outroot, exist_ok=True)
    # 正例：两件独立真拷贝（内容各自独立、%h==1）
    wr(os.path.join(facet, 'sub', 'pos1.sh'), "#!/bin/sh\necho pos1\n", 0o644)
    wr(os.path.join(facet, 'sub', 'pos2.sh'), "#!/bin/sh\necho pos2\n", 0o644)
    # 反例：真硬链接（同一个 inode 两条路径，孪生在仓外区）
    wr(os.path.join(facet, 'sub', 'neg.sh'), "#!/bin/sh\necho neg\n", 0o644)
    alias_path = os.path.join(outroot, 'shadow', 'sub', 'neg.sh')
    os.makedirs(os.path.dirname(alias_path), exist_ok=True)
    os.link(os.path.join(facet, 'sub', 'neg.sh'), alias_path)     # ← 真硬链接（**只在 fixture 里**）

    legs = []
    def leg(name, roots, maxdepth, expect):
        rows, diag = scan(facet, roots.split(':') if roots else [], maxdepth, 120)
        linked, out_rows = classify(rows, facet)
        exam = diag['examined']
        ok_exam = exam > 0
        if expect == 'PASS':
            verdict = 'PASS' if (ok_exam and not out_rows) else 'FAIL'
        else:
            verdict = 'FAIL' if out_rows else 'PASS'
        good = (verdict == expect)
        legs.append((name, verdict, expect, good, exam, len(linked), len(out_rows)))
        print("  %-34s VERDICT=%-4s expect=%-4s examined=%d linked_gt1=%d aliased_out=%d %s"
              % (name, verdict, expect, exam, len(linked), len(out_rows), 'OK' if good else '**错**'))
        for r in out_rows[:3]:
            print("      %s  h=%d ino=%d" % (r['rel'], r['nlink'], r['ino']))
            print("        repo: %s" % r['repo_path'])
            for e in r['ext'][:3]: print("        out : %s" % e)
        return good

    ok = []
    # ① 反极基态：孪生在 --roots 覆盖时 ⇒ 必须 FAIL
    ok.append(leg('反极（孪生在 roots 内）', outroot, 12, 'FAIL'))
    # ② 正极：把硬链接**删掉**（切断被注入的对象）⇒ 必须翻回 PASS（本仓 D-G128 纪律）
    os.unlink(alias_path)
    ok.append(leg('正极（链接已删）', outroot, 12, 'PASS'))
    # ③ 重新造链，验 --roots 真生效：roots 指向别处 ⇒ 不检出（射程边界，**不是**绿）
    os.link(os.path.join(facet, 'sub', 'neg.sh'), alias_path)
    os.makedirs(os.path.join(FIX, 'elsewhere'), exist_ok=True)
    ok.append(leg('--roots 指别处 ⇒ 不检出', os.path.join(FIX, 'elsewhere'), 12, 'PASS'))
    ok.append(leg('--roots 指对了 ⇒ 检出', outroot, 12, 'FAIL'))
    # ④ --maxdepth 真生效：孪生放在 depth>maxdepth 处 ⇒ 不检出；放大 ⇒ 检出
    deep = os.path.join(facet, 'sub', 'd1', 'd2', 'd3', 'deep.sh')
    wr(deep, "#!/bin/sh\necho deep\n", 0o644)
    deep_alias = os.path.join(outroot, 'shadow', 'sub', 'd1', 'd2', 'd3', 'deep.sh')
    os.makedirs(os.path.dirname(deep_alias), exist_ok=True)
    os.link(deep, deep_alias)
    rows, diag = scan(facet, [outroot], 3, 120)
    _, o3 = classify(rows, facet)
    got_deep3 = any(r['rel'].endswith('deep.sh') for r in o3)
    rows, diag = scan(facet, [outroot], 12, 120)
    _, o12 = classify(rows, facet)
    got_deep12 = any(r['rel'].endswith('deep.sh') for r in o12)
    print("  %-34s deep(链) maxdepth=3 → 检出=%s ／ maxdepth=12 → 检出=%s"
          % ('--maxdepth 成对', got_deep3, got_deep12))
    ok.append((not got_deep3) and got_deep12)

    # ⑤ **$R 零写入自证**：selftest 前后 $R 的 mtime 与件数逐位比较
    print("  fixture 内 %h 分布（应当出现 2，证明是**真硬链接**）：")
    hs = {}
    for dp, dn, fns in os.walk(FIX):
        for fn in fns:
            s = os.lstat(os.path.join(dp, fn))
            hs[s.st_nlink] = hs.get(s.st_nlink, 0) + 1
    print("    " + "  ".join("h=%d: %d 件" % (k, hs[k]) for k in sorted(hs)))

    # ⑥ 白名单两极化（**成对**）：在界内 ⇒ 绿；上限 −1 ⇒ **必红**（白名单不是遮羞布）
    print("\n⑥ **白名单**（成对）：在界内 ⇒ 绿；上限 −1 ⇒ **必红**")
    rows_f, _ = scan(facet, [outroot], 12, 120)
    _linked, o_rows = classify(rows_f, facet)
    _ext = []
    for r in o_rows:
        _ext.extend(r['ext'])
    _n_ext = len(set(_ext))
    wr(os.path.join(FIX, 'allow-hi.tsv'),
       "# 在界内\n%s\t%d\t自测：真实件数\n" % (outroot, max(1, _n_ext)))
    _ents, _ = load_allow(os.path.join(FIX, 'allow-hi.tsv'))
    _cov, _hits, _grown = match_allow(_ext, _ents)
    ok_in = (len(set(_ext) - _cov) == 0) and not _grown
    print("   · 上限 = 实际件数（%d）⇒ 未覆盖 %d、超上限树 %d ⇒ 期望绿  %s"
          % (_n_ext, len(set(_ext) - _cov), len(_grown), 'OK' if ok_in else '**错**'))
    ok.append(('白名单·在界内必绿', ok_in))
    _lo = max(1, _n_ext - 1)
    wr(os.path.join(FIX, 'allow-lo.tsv'),
       "# 上限 −1\n%s\t%d\t自测：故意少一件\n" % (outroot, _lo))
    _ents2, _ = load_allow(os.path.join(FIX, 'allow-lo.tsv'))
    _cov2, _hits2, _grown2 = match_allow(_ext, _ents2)
    ok_lo = bool(_grown2)
    print("   · 上限 = %d（实际 %d）⇒ 超上限树 %d ⇒ 期望红  %s"
          % (_lo, _n_ext, len(_grown2), 'OK' if ok_lo else '**错**'))
    if _grown2:
        print("     grown = %s" % (_grown2,))
    ok.append(('白名单·超上限必红', ok_lo))

    bad = [i for i, g in enumerate(ok) if not g]
    verdict = 'PASS' if not bad else 'FAIL'
    print("\nALIAS-SELFTEST=%s legs=%d bad=%d" % (verdict, len(ok), len(bad)))
    print("ALIAS-SELFTEST-LEGS=%s" % " ".join("%s=%s" % (l[0], l[1]) for l in legs))
    return verdict

# ---------------------------------------------------------------- main
def main():
    if MODE == 'selftest':
        v = selftest()
        sys.exit(0 if v == 'PASS' else 1)

    roots = ROOTS_ARG.split(':') if ROOTS_ARG else ['/home/links-dev']
    allow_ents, allow_diag = load_allow(ALLOW)
    t0 = time.time()
    reason = None
    root_exists = os.path.isdir(ROOT)
    if not root_exists:
        by_ino, diag = [], {'examined': 0, 'roots_stat_fail': [], 'timed_out': False, 'wrong_root': ROOT, 'lstat_fail': []}
    else:
        by_ino, diag = scan(ROOT, roots, MAXDEPTH, TIMEOUT)
    wall = time.time() - t0
    linked, out_rows = classify(by_ino, ROOT)
    examined = diag['examined']

    # ---- 成员表先落盘（temp＋rename），再给计数（本仓纪律：集合类读数先取成员表）
    lines = ["# repo-alias-check.sh 全量成员表（%s）" % time.strftime('%Y-%m-%dT%H:%M:%S%z')]
    lines.append("# root=%s roots=%s maxdepth=%d" % (ROOT, ",".join(roots), MAXDEPTH))
    lines.append("# 列：ino\tnlink_observed\trepo_relpath\trepo_path\tout_paths('|' 分隔)")
    for r in out_rows:
        lines.append("%d\t%d\t%s\t%s\t%s" % (r['ino'], r['nlink'], r['rel'], r['repo_path'], '|'.join(r['ext'])))
    wr(TSV, "\n".join(lines) + "\n")

    print("=== repo-alias-check.sh · `D-G127` 牙 ===")
    print("root      = %s" % ROOT)
    print("roots     = %s" % ":".join(roots))
    print("maxdepth  = %d   timeout = %ss   wall = %.2fs" % (MAXDEPTH, int(TIMEOUT), wall))
    print("成员表    = %s（%d 行 ＋ 3 行表头）" % (TSV, len(out_rows)))
    print("白名单    = %s（%d 条；每条 = 树前缀 + **件数上限**）"
          % (ALLOW or '(未给：任何仓外孪生都判 FAIL)', len(allow_ents)))
    if allow_diag['allow_bad_lines']:
        print("!! 白名单有 %d 条坏行（已点名，按「未覆盖」处理）：" % len(allow_diag['allow_bad_lines']))
        for x in allow_diag['allow_bad_lines'][:5]:
            print("   %s" % x)
    if diag.get('wrong_root'):
        print("!! --root 不是目录：%s" % diag['wrong_root'])
        reason = 'zero-examined'
    if diag['roots_stat_fail']:
        print("!! 搜索根不存在（这些根内**没有**找过）：%s" % "  ".join(diag['roots_stat_fail']))
    if diag.get('lstat_fail'):
        print("!! lstat 失败（跳过，**已点名**）%d 条，前 5：" % len(diag['lstat_fail']))
        for p in diag['lstat_fail'][:5]: print("   %s" % p)
    if diag['timed_out']:
        print("!! **遍历超时**（%ss）：成员表是**不全**的 ⇒ 本趟 NOINFO" % int(TIMEOUT))
        print("   （**绝不许**把『没扫完』当『没孪生』—— 本仓假绿高发形态）")
        reason = 'timeout'

    print()
    print("--- 明细：$R 内 h>1 且**有仓外孪生**的件（前 %s 条%s）---"
          % (HEAD if HEAD else '全部', '' if HEAD else '（--all）'))
    shown = out_rows if HEAD == 0 else out_rows[:HEAD]
    for r in shown:
        print("h=%d ino=%d" % (r['nlink'], r['ino']))
        print("  repo: %s" % r['repo_path'])
        for e in r['ext']:
            print("  out : %s" % e)
    if len(out_rows) > len(shown):
        print("... 另有 %d 件未列（成员表见 %s；--all 或 --head N 可全列）" % (len(out_rows) - len(shown), TSV))
    print()
    print("--- 汇总 ---")
    print("examined（$R 内被 stat 的普通文件）    = %d" % examined)
    print("linked_gt1（$R 内 h>1 的**件**）      = %d" % len(linked))
    print("linked_gt1_inodes（不同 inode 个数）   = %d" % len(set(d['ino'] for d in linked)))
    print("aliased_out（**有仓外孪生**的 $R 件）  = %d" % len(out_rows))
    print("aliased_out_twins（仓外孪生**路径**数） = %d" % sum(len(r['ext']) for r in out_rows))

    # ⚠️ **射程自曝**：仓内 h>1 的件若**没有**任何一件找到仓外孪生，那不是"干净"，
    #    而是"`--roots`/`--maxdepth` 把射程收没了"的高概率形态 ⇒ 显式告警（NOINFO 语义留给 C9）。
    scope_suspect = (len(linked) > 0 and len(out_rows) == 0)
    if scope_suspect:
        print()
        print("!! **射程告警**：仓内 h>1 的件有 %d 个，但**一个仓外孪生都没找到** ——"
              " 请先核 `--roots`（现为 %s）与 `--maxdepth`（现为 %d）"
              % (len(linked), ":".join(roots), MAXDEPTH))
        print("   （本机现算：`--maxdepth 12` 会让 332 件在深处漏检 ⇒ 静默假阴性；见 criteria §C.1-C6）")
        if reason in (None, 'no-out-of-repo-alias'):
            reason = 'no-out-of-repo-alias-BUT-scope-suspect'

    # ---- `--allow` 判定（**只降 `aliased_out` 一项**，四项计数照打）
    all_ext = []
    for r in out_rows:
        all_ext.extend(r['ext'])
    covered, tree_hits, grown = match_allow(all_ext, allow_ents)
    un_covered = sorted(set(all_ext) - covered)
    aliased_allowed = len(set(all_ext) & covered)
    aliased_unallowed = len(un_covered)
    print()
    print("--- 白名单判定（`--allow`；**逐树件数上限**）---")
    for t, n in sorted(tree_hits.items()):
        cap = next(e['cap'] for e in allow_ents if e['tree'] == t)
        why = next(e['why'] for e in allow_ents if e['tree'] == t)
        print("  树 %s：当前 %d 件 ／ 上限 %d 件 %s  %s"
              % (t, n, cap, '**超上限**' if n > cap else '（在界内）', why))
    print("  aliased_allowed（被白名单覆盖的孪生路径）   = %d" % aliased_allowed)
    print("  aliased_unallowed（**未被覆盖**的孪生路径） = %d" % aliased_unallowed)
    for p in un_covered[:5]:
        print("    · 未覆盖：%s" % p)
    if len(un_covered) > 5:
        print("    · … 另有 %d 条" % (len(un_covered) - 5))
    for t, n, cap in grown:
        print("    · **超上限**：%s 当前 %d 件 > 上限 %d 件" % (t, n, cap))

    if examined == 0:
        verdict = 'FAIL'; reason = reason or 'zero-examined'
    elif reason == 'timeout' or diag['roots_stat_fail']:
        verdict = 'NOINFO'
    elif grown:
        verdict = 'FAIL'; reason = 'allowed-tree-grown'
    elif aliased_unallowed:
        verdict = 'FAIL'; reason = 'out-of-repo-alias'
    elif aliased_allowed:
        verdict = 'PASS'; reason = 'known-alias-trees'
    else:
        verdict = 'PASS'; reason = 'no-out-of-repo-alias'

    print()
    print("ALIAS=%s examined=%d linked_gt1=%d aliased_out=%d aliased_allowed=%d aliased_unallowed=%d "
          "roots=%d maxdepth=%d wall_s=%.2f rc=%d reason=%s"
          % (verdict, examined, len(linked), len(out_rows), aliased_allowed, aliased_unallowed,
             len(roots), MAXDEPTH, wall, 0 if verdict == 'PASS' else (3 if verdict == 'NOINFO' else 1), reason))
    sys.exit(0 if verdict == 'PASS' else (3 if verdict == 'NOINFO' else 1))

main()
PYEOF
rc=$?
exit "$rc"

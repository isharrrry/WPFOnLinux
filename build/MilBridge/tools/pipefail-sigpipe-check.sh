#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# pipefail-sigpipe-check.sh —— 「`set -o pipefail` ＋ 管道非末段吃 SIGPIPE ⇒ 判据被翻转」的扫描牙
#
# 【机制（`#32` W32C 取到、主控复现并已修 12 处；本件复核并**实测**了它）】
#   `set -o pipefail` 下，管线的 rc = **最后一个非 0 段的 rc**。若管道的**非末段**在
#   `write(2)` 时读端已关闭 ⇒ `SIGPIPE` ⇒ 该段 `rc=141` ⇒ **整条管线非 0**。
#   最典型形态：`printf '%s' "$多行串" | grep -q PAT`（`grep -q` 命中即退出、关掉读端）。
#
# 【本件实测量到的口径（不是转述）】
#   · bash 的 `printf '%s' "$x"` 对**含换行的串**是**逐行 `write()`**（`strace -f -e trace=write`
#     实测：75 行/1337 B ⇒ 每行一次 `write(1, …, 18)`；末次 `write` 得 `-1 EPIPE`）。
#     同尺寸的**单行**串是**一次** `write()` ⇒ **不可能**吃 SIGPIPE（下称"单行左端安全"）。
#   · 因此危险不取决于"数据大小 > 64 KiB 管道缓冲"这一条，而取决于**写端是否在读者退出之后
#     还在写**：本机实测（`$HOME/w33a-run/exp3.sh`，每档 300 次）
#         多行 1337 B  ⇒ 141 率 **2/300**（≈0.7%）
#         多行 47 KB   ⇒ **3/300**
#         多行 119 KB  ⇒ **220/300**
#         多行 250 KB  ⇒ **300/300**
#         单行 200 KB  ⇒ **0/100**（阴性对照）
#     ⇒ **小串也会偶发**（写端被抢占 ⇒ 读者先读完并退出 ⇒ 后续 `write` 得 EPIPE）；
#       **大串几乎必发**。所以本牙的判据**不靠正则**：对每个候选站点**把那一行抽进沙箱真跑**，
#       用**远超管道缓冲的多行载荷**把窗口放大到可见，实测 rc。
#
# 【四判据（逐条成立才算候选）】
#   ① 件内 `pipefail` 已开（且未被 `set +o pipefail` 关掉）；
#   ② 管线的**非末段**产出**不止一次 `write()`**（`printf/echo` 多行变量、文本过滤器、命令输出）；
#   ③ 末段**会提前退出**（`grep -q` / `grep -m1` / `head` / `sed …q` / `awk …exit`）；
#   ④ 该管线的 **rc 被消费**（在 `if`/`while`/`until`/`!`/`&&`/`||` 里；或件内有 `set -e`）。
#   ①∧②∧③∧④ 之后**还要动态实测**：pp 开 ⇒ rc≠0（≥1 次）、pp 关 ⇒ rc 恒 0。
#     · 实测到 ⇒ `HIT`（有牙的高危站点，进 rc）
#     · 结构成立但抽不出来跑（左端含 `$(…)`/外部命令）⇒ `DIAG`（**只报量级，不进 rc**）
#     · 实测 pp 开也恒 0（例如左端其实是单行字面量）⇒ `SAFE reason=dyn-no-flip`
#
# 【三态 + rc】`PIPEFAIL_SIGPIPE=PASS|FAIL|NOINFO …` ｜ rc 0=PASS｜1=FAIL｜2=NOINFO
#   `NOINFO`（**绝不等于绿**）：金丝雀失明（扫描器/实测引擎坏了 ⇒ 读数不可归因）、件集下限不达标、
#   或**全量站点里一条都没实测到**（"0 命中"与"看不见"必须分得开）。
#
# 【声明的 HIT（DECLARED）】本件内嵌 `DECL` 表。⚠️ 锚是**文件:行号** ⇒ 谁在那个文件靠前处插行，就必须**同趟**把这里一起改（`#39` 实测：`run-wpfprobe.sh:566 → 568`），否则 `decl_stale=1` 且该 HIT 变"未声明" ⇒ 红。**未声明**的 HIT ⇒ FAIL；已声明 ⇒ 计入
#   `declared=`；`DECL` 里列了但现场已不是 HIT ⇒ `decl-stale` ⇒ **FAIL**（声明表必须与现场自洽）。
#   声明只许用于"不在本车道写域/已裁定下一波修"的站点，**且必须写明它防的是哪一次错判**。
#
# 【成本】单趟 ≈ 扫描 0.2 s ＋ 动态实测（每站点 4 轮 × 12 次、单进程循环）≈ 1–3 s；零 `dotnet`、
#   零世代成本（纯读；不动九位/`GEN_KEYS`/`known-red.json`/被测树）。
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
REAL_ROOT="$(cd "$HERE/../../.." && pwd)"

ROOT="${PP_ROOT:-$REAL_ROOT}"
MIN_FILES="${PP_MIN_FILES:-40}"      # 现场 55 件带 pipefail 的 *.sh；低于它 ⇒ 扫描定义失效
MIN_SITES="${PP_MIN_SITES:-20}"      # 现场候选站点数下限（结构候选）
RUNS="${PP_RUNS:-12}"                # 每站点每模式动态迭代次数
BLIND="${PP_TEST_BLIND:-0}"          # 只给 --selftest 用：故意弄瞎动态引擎
KEEP_TMP=0
TMPUSED=''

say() { printf '%s\n' "$*"; }

usage() {
    cat <<'TXT'
用法：
  pipefail-sigpipe-check.sh [--root DIR] [--runs N] [--list] [--debug-tmp]
  pipefail-sigpipe-check.sh --selftest

判据：仓库 `*.sh`（减 upstream/ 与 obj|bin|.artifacts|__pycache__）里，凡「`pipefail` 已开 ∧
      管线非末段会多次 write ∧ 末段提前退出 ∧ rc 被消费」的站点，**必须实测过**：
      动态实测 pp 开 ⇒ rc≠0 且 pp 关 ⇒ rc 恒 0 者为 `HIT`（有牙高危，进 rc）。
      结构成立但抽不出来跑者 `DIAG`（只报量级，不进 rc）。
rc：0 = PASS（无未声明 HIT，且金丝雀活）｜1 = FAIL（未声明 HIT / 声明表不自洽）
    ｜2 = NOINFO（金丝雀失明 / 件集或站点数低于下限 / 一条都没实测到 —— **不是绿**）
环境：PP_ROOT｜PP_MIN_FILES｜PP_MIN_SITES｜PP_RUNS｜PP_TEST_BLIND=1
TXT
}

# ── 内嵌声明表：现场仍是 HIT 但**不由本车道修**的站点 ─────────────────────────
# 口径：`<仓相对路径>:<行号>`，行号会漂 ⇒ 若声明项在现场不再命中 HIT ⇒ `decl-stale` ⇒ FAIL。
read -r -d '' DECL <<'DECLEOF'
# 文件:行 —— 理由（只许写"不在本车道写域"的现场真 HIT，且必须写明它防的是哪一次错判）
tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh:568|写域外(tests/**)；`grep -a '^\[KEY_DIAG\]' "$log" | head -4 | sed` 的 rc 被 `if` 消费：当日志里 KEY_DIAG 行 > 4 行时 head 先退出 ⇒ grep 吃 SIGPIPE ⇒ rc=141 ⇒ **那 4 行诊断被静默丢掉**（不改任何 verdict，只丢诊断）。数据面取决于日志长度 ⇒ 现场不可定 ⇒ 保留声明，建议 tests 车道同法改（`head -4 <<< "$(grep …)"`）
DECLEOF

# ── 主流程（扫描 + 动态实测都在这一段 python3 里；bash 只做三态/金丝雀/汇总） ─────────
run_check() {
    local tmpd="$1"
    TMPUSED="$tmpd"
    python3 - "$ROOT" "$tmpd" "$RUNS" "$BLIND" "$DECL" <<'PYEOF'
import os, re, sys, json, subprocess

ROOT, TMPD, RUNS, BLIND = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4] == '1'
DECL_RAW = sys.argv[5] if len(sys.argv) > 5 else ''
DECL_EXTRA = os.environ.get('PP_DECL_EXTRA', '')
EXCL = ('/obj/', '/bin/', '/.artifacts/', '/upstream/', '/__pycache__/')
OPS = ('&&', '||', ';;', ';', '|', '&')
KEYWORDS = ('if', 'while', 'until', 'elif', 'then', 'do', 'else', '!')
TOK = 'PPSIGPIPE_CANARY_TOKEN'

# ── 切命令（引号内的运算符不算） ────────────────────────────────────────────
def lex_ops(s):
    out, cur, i, n, q = [], '', 0, len(s), None
    while i < n:
        c = s[i]
        if q:
            cur += c
            if c == q: q = None
            i += 1; continue
        if c in '"\'': q = c; cur += c; i += 1; continue
        if c == '\\' and i + 1 < n: cur += s[i:i+2]; i += 2; continue
        m = None
        for op in OPS:
            if s.startswith(op, i): m = op; break
        if m: out.append(cur); out.append(m); cur = ''; i += len(m); continue
        cur += c; i += 1
    out.append(cur)
    return out

def strip_kw(seg):
    s = seg.strip()
    changed = True
    while changed:
        changed = False
        for kw in KEYWORDS:
            if s == kw: return ''
            if s.startswith(kw + ' '): s = s[len(kw):].strip(); changed = True
    return s

def first_tok(seg):
    m = re.match(r'([A-Za-z_][A-Za-z0-9_.-]*)', strip_kw(seg))
    return m.group(1) if m else ''

GREP_EARLY = re.compile(r'(?:^|\s)-[A-Za-z]*q[A-Za-z]*(?=\s|$)|(?:^|\s)-m\s*1(?=\s|$)|(?:^|\s)-m1(?=\s|$)')

def reader_kind(seg):
    s = strip_kw(seg)
    if re.search(r'(?:^|\s|\()grep(?:\s|$)', s) and GREP_EARLY.search(s): return 'grep-q'
    if re.search(r'(?:^|\s|\()head(?:\s|$)', s): return 'head'
    if re.search(r'(?:^|\s|\()sed(?:\s|$)', s) and re.search(r"(?:^|[\s'\"])[0-9,\$\{\};-]*q(?:[\s'\"]|$)", s): return 'sed-q'
    if re.search(r'(?:^|\s|\()awk(?:\s|$)', s) and re.search(r'\bexit\b', s): return 'awk-exit'
    return None

FILTERS = {'cat','grep','sed','awk','sort','uniq','tr','cut','head','tail','wc','nl','column','rev',
           'fold','expand','paste','comm','join','tee','strings','od','xxd','ls','find','printf','echo','seq'}
CONTENT_CMDS = {'printf', 'echo'}
VAR_RE = re.compile(r'\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?(\[@\]|\[\*\])?')

def var_roles(seg):
    """返回 {var: 'content'|'file'}。printf/echo 段里的变量 = 内容；其它段 = 路径。"""
    roles = {}
    if first_tok(seg) in CONTENT_CMDS:
        for m in VAR_RE.finditer(seg): roles[m.group(1)] = 'content'
    else:
        for m in VAR_RE.finditer(seg): roles[m.group(1)] = 'file'
    return roles

SINGLE_HINTS = ('convert', 'sha256sum', 'md5sum', 'date', 'basename', 'dirname', 'hostname', 'pwd',
                'uname', 'tty', 'readlink', 'realpath', 'which', 'id', 'whoami', 'stat -c %s', 'nproc')
MULTI_HINTS = ('2>&1', 'dotnet', 'python3', 'bash ', 'cat ', 'ls ', 'find ', 'nm ', 'grep ', 'sed ',
               'ps ', 'dpkg', 'journalctl', 'sha256sum -c', 'git ')

def all_assignments(txt, var):
    """该变量的**全部**赋值右手（含 `local a=1 b=2`、数组、追加式），按出现顺序。"""
    pat = re.compile(r'(?:^|[\s;(&|])(?:local\s+|declare\s+(?:-a\s+)?|export\s+)?' + re.escape(var) + r'=([^\n;]*)', re.M)
    return [m.group(1) for m in pat.finditer(txt)]

def assignment_of(txt, var):
    rhs = all_assignments(txt, var)
    if not rhs:
        return None
    # 优先取"像数据来源"的那一次：含 $( 或 ( 的优先于纯字面量
    for r in rhs:
        if '$(' in r or r.strip().startswith('('):
            return r
    return rhs[0]

def read_var(txt, var):
    return bool(re.search(r'(?:^|[\s;|])read\s+(?:-[A-Za-z]+\s+)*' + re.escape(var) + r'(?:\s|$)', txt, re.M))

def reach_of(txt, var, is_array):
    if read_var(txt, var) and assignment_of(txt, var) is None:
        return 'capture-single', 'read(逐行读入 ⇒ 单行)'
    rhs = assignment_of(txt, var)
    if rhs is None:
        if is_array: return 'array-unknown', 'n/a'
        if read_var(txt, var): return 'capture-single', 'read(逐行读入 ⇒ 单行)'
        return 'unknown', 'n/a(未在同一件里找到赋值)'
    if rhs.strip().startswith('('):
        items = [x for x in re.split(r'\s+', rhs.strip().strip('()')) if x]
        if len(items) <= 1: return 'array-small', 'elements=%d' % len(items)
        total = sum(len(x.strip('"\'')) + 1 for x in items)
        if total >= 4096: return 'array-large', 'elements=%d bytes>=%d' % (len(items), total)
        return 'array-small', 'elements=%d bytes~%d' % (len(items), total)
    if '$(' in rhs or rhs.strip().startswith('$('):
        body = rhs.strip()
        if re.search(r'\|\s*(?:tail|head)\s+(?:-n\s*)?-?1(?![0-9])', body):
            return 'capture-single', 'capture|head/tail -1(结果只有一行)'
        for h in SINGLE_HINTS:
            if h in body: return 'capture-single', 'cmd=%s' % h
        for h in MULTI_HINTS:
            if h in body: return 'capture-multi', 'hint=%s' % h
        return 'capture-unknown', body[:60]
    if '\\n' in rhs or '\n' in rhs.strip():
        return 'literal-multi', rhs[:40]
    return 'literal-single', rhs[:40]

# ── 载荷与实测引擎 ─────────────────────────────────────────────────────────
NLINES = 6000
def write_payloads():
    with open(os.path.join(TMPD, 'multi.txt'), 'w') as f:
        f.write('\n'.join([TOK] + ['filler-' + 'z' * 28 + '-%05d' % i for i in range(NLINES)]))
    with open(os.path.join(TMPD, 'small.txt'), 'w') as f:
        f.write('\n'.join([TOK] + ['short-%05d-%s' % (i, 'y' * 30) for i in range(40)]))
    return os.path.getsize(os.path.join(TMPD, 'multi.txt')), os.path.getsize(os.path.join(TMPD, 'small.txt'))

def canon_reader(rseg, kind):
    s = rseg
    if kind == 'grep-q':
        flags = [fl for fl in ('-q', '-x', '-F', '-E', '-a', '-i') if re.search(re.escape(fl), s)]
        if '-q' not in flags: flags.insert(0, '-q')
        return 'grep ' + ' '.join(flags) + ' ' + TOK
    if kind == 'head':
        m = re.search(r'-n\s*([0-9]+)', s) or re.search(r'^-([0-9]+)$', s.strip().split()[1] if len(s.strip().split()) > 1 else '')
        return 'head -n ' + (m.group(1) if m else '1')
    if kind == 'sed-q': return "sed -n '1q'"
    if kind == 'awk-exit': return "awk '{print; exit}'"
    return None

def build_repro(pl):
    segs, reader = pl['left_segs'], pl['right']
    canon = canon_reader(reader, pl['kind'])
    if canon is None: return None, 'no-reader-form'
    decls, plan_notes = [], []
    content_vars, file_vars = {}, {}
    for sg in segs:
        for v, role in var_roles(sg).items():
            (content_vars if role == 'content' else file_vars)[v] = True
    seg_text = ' | '.join(segs)
    if not content_vars and not file_vars:
        return None, 'literal-left'
    for v in sorted(content_vars):
        if re.search(r'\$\{?' + re.escape(v) + r'\}?\[[@*]\]', seg_text):
            decls.append('%s=( "$PP_PAY" )' % v)
        else:
            decls.append('%s="$PP_PAY"' % v)
    for v in sorted(file_vars):
        # 该变量在正文里的**整个实参**形态：`"$v"` / `"$v/suffix"` / `$v`
        pat = re.compile(r'"\$' + re.escape(v) + r'(?:\{)?\}?([^"]*)"')
        m = pat.search(seg_text)
        if m is None:
            pat2 = re.compile(r'\$' + re.escape(v) + r'(?:\{)?\}?([A-Za-z0-9_./-]*)')
            m2 = pat2.search(seg_text)
            if m2 is None: return None, 'file-var-unparsed'
            suffix = m2.group(1)
        else:
            suffix = m.group(1)
        if '*' in suffix or '?' in suffix: return None, 'file-var-glob'
        if suffix in ('', '/'):
            decls.append('%s="$PP_TMPD/multi.txt"' % v)
        else:
            rel = suffix.lstrip('/')
            decls.append('%s="$PP_TMPD"' % v)
            plan_notes.append(rel)
    script = ['#!/usr/bin/env bash', '# 沙箱最小复现（引擎自动生成）：只重放**目标管线本体**',
              'PP_MULTI="$(cat "$PP_TMPD/multi.txt")"', 'PP_SMALL="$(cat "$PP_TMPD/small.txt")"']
    for rel in plan_notes:
        d = os.path.dirname(rel)
        if d:
            script.append('mkdir -p "$PP_TMPD/%s" 2>/dev/null' % d)
        script.append('cp -f "$PP_TMPD/multi.txt" "$PP_TMPD/%s" 2>/dev/null' % rel)
    script.append('PP_N="${1:-%d}"; PP_MODE="${2:-on}"; PP_SIZE="${3:-big}"' % RUNS)
    script.append('if [ "$PP_MODE" = on ]; then set -o pipefail; else set +o pipefail; fi')
    script.append('if [ "$PP_SIZE" = big ]; then PP_PAY="$PP_MULTI"; else PP_PAY="$PP_SMALL"; fi')
    script.extend(decls)
    pipe = ' | '.join([strip_kw(x) for x in segs] + [canon])
    script.append('bad=0')
    script.append('for ((i=0;i<PP_N;i++)); do')
    script.append('  %s >/dev/null 2>&1; rc=$?' % pipe)
    script.append('  [ "$rc" -ne 0 ] && bad=$((bad+1))')
    script.append('done')
    script.append('echo "bad=$bad"')
    return '\n'.join(script) + '\n', 'ok'

def repro(script, mode, size):
    p = os.path.join(TMPD, 'repro.sh')
    with open(p, 'w') as f: f.write(script)
    env = dict(os.environ, PP_TMPD=TMPD)
    try:
        r = subprocess.run(['bash', p, str(RUNS), mode, size], capture_output=True, text=True, timeout=180, env=env)
    except subprocess.TimeoutExpired:
        return None
    m = re.search(r'bad=(\d+)', r.stdout)
    return int(m.group(1)) if m else None

# ── 扫描 ───────────────────────────────────────────────────────────────────
def shfiles(root):
    for dp, dn, fn in os.walk(root):
        p = dp + '/'
        if any(x in p for x in EXCL): continue
        dn[:] = [d for d in dn if d not in ('obj', 'bin', '.artifacts', 'upstream', '__pycache__')]
        for f in sorted(fn):
            if f.endswith('.sh'): yield os.path.join(dp, f)

def logical_lines(txt):
    raw, out, i = txt.split('\n'), [], 0
    while i < len(raw):
        st, buf = i, raw[i]
        while re.search(r'(\\|\|)\s*$', buf) and i + 1 < len(raw):
            i += 1; buf = buf.rstrip()
            if buf.endswith('\\'): buf = buf[:-1]
            buf += ' ' + raw[i].strip()
        out.append((st + 1, buf)); i += 1
    return out

def heredoc_spans(txt):
    lines, skip, i = txt.split('\n'), set(), 0
    while i < len(lines):
        for m in re.finditer(r'<<-?\s*["\']?([A-Za-z_][A-Za-z0-9_]*)["\']?', lines[i]):
            delim, j = m.group(1), i + 1
            while j < len(lines) and lines[j].strip() != delim:
                skip.add(j + 1); j += 1
            i = j
        i += 1
    return skip

def in_condition(parts, i):
    """该管线是否落在 `if/while/until/elif …; then/do` 的条件区（含管线自身段；向后找关键字，遇 then/do 即止）。"""
    if re.search(r'\b(if|while|until|elif)\b', parts[i]):
        return True
    j = i - 2
    while j >= 0:
        p = parts[j]
        if re.search(r'\b(if|while|until|elif)\b', p):
            return True
        if re.search(r'\b(then|do|else)\b', p) or ';' in p:
            return False
        j -= 2
    return False

nfiles, plans, seen = 0, [], set()
for path in shfiles(ROOT):
    rel = os.path.relpath(path, ROOT)
    try: txt = open(path, encoding='utf-8', errors='replace').read()
    except Exception: continue
    nfiles += 1
    if not re.search(r'^\s*set\s+[-+a-zA-Z]*o?\s*pipefail|^\s*set\s+-o\s+pipefail', txt, re.M): continue
    set_e = bool(re.search(r'^\s*set\s+(-[a-zA-Z]*e[a-zA-Z]*|-[a-z]*e[a-z]*)\s*$|^\s*set\s+-euo\b|^\s*set\s+-o\s+errexit', txt, re.M))
    hd = heredoc_spans(txt)
    for ln, s in logical_lines(txt):
        if ln in hd: continue
        t = s.strip()
        if not t or t.startswith('#'): continue
        parts = lex_ops(t)
        i = 0
        while i < len(parts):
            if i % 2 == 1: i += 1; continue
            segs, j = [parts[i]], i + 1
            while j < len(parts) and parts[j] == '|':
                segs.append(parts[j + 1]); j += 2
            nxt = parts[j] if j < len(parts) else ''
            if len(segs) >= 2:
                hit = None
                for idx, sg in enumerate(segs):
                    k = reader_kind(sg)
                    if k: hit = (idx, k); break
                if hit and hit[0] > 0:
                    idx, kind = hit
                    left = [x for x in segs[:idx]]
                    if nxt in ('&&', '||'):
                        consumer = 'chain'
                    elif nxt in ('', ';') and in_condition(parts, i):
                        consumer = 'cond'
                    elif set_e: consumer = 'set-e'
                    else: consumer = 'unused'
                    key = (rel, ln, tuple(x.strip() for x in left), segs[idx].strip())
                    if key in seen:
                        pass
                    else:
                        seen.add(key)
                        plans.append(dict(file=rel, line=ln, kind=kind, consumer=consumer,
                                          left_segs=[x.strip() for x in left], right=segs[idx].strip(), text=t))
            i = j + 1

# ── 分类 + 动态实测 ────────────────────────────────────────────────────────
write_payloads()
rows = []
for pl in plans:
    r = dict(pl); r['reach'] = 'n/a'; r['reach_detail'] = ''
    if r['consumer'] == 'unused':
        r['verdict'], r['why'] = 'SAFE', 'rc-unused'
        rows.append(r); continue
    ok, why = True, 'ok'
    for sg in pl['left_segs']:
        s = strip_kw(sg)
        if not s: continue
        if '$(' in s or '`' in s: ok, why = False, 'cmd-subst'; break
        if first_tok(s) not in FILTERS: ok, why = False, 'external:' + (first_tok(s) or '?'); break
    if not ok:
        r['verdict'], r['why'] = 'DIAG', why
        rows.append(r); continue
    script, st = build_repro(pl)
    txt = open(os.path.join(ROOT, pl['file']), encoding='utf-8', errors='replace').read()
    seg_text = ' | '.join(pl['left_segs'])
    cvars = [v for sg in pl['left_segs'] for v, role in var_roles(sg).items() if role == 'content']
    if cvars:
        is_arr = bool(re.search(r'\$\{?' + re.escape(cvars[0]) + r'\}?\[[@*]\]', seg_text))
        rc_class, rc_detail = reach_of(txt, cvars[0], is_arr)
        r['reach'], r['reach_detail'] = rc_class, '%s=%s' % (cvars[0], rc_detail)
    elif re.search(r'\$\{?[A-Za-z_]', seg_text):
        r['reach'], r['reach_detail'] = 'file-unknown', seg_text[:40]
    if script is None:
        if st == 'literal-left':
            r['verdict'], r['why'] = 'LOW', 'literal-left(字面量左端：数据面单行 ⇒ 结构危险但现实够不着)'
        else:
            r['verdict'], r['why'] = 'DIAG', st
        rows.append(r); continue
    if BLIND:
        r['verdict'], r['why'] = 'SAFE', 'blind(自测用)'
        rows.append(r); continue
    on, off, sm = repro(script, 'on', 'big'), repro(script, 'off', 'big'), repro(script, 'on', 'small')
    r['dyn_on'], r['dyn_off'], r['dyn_small'] = on, off, sm
    if on is None or off is None:
        r['verdict'], r['why'] = 'DIAG', 'repro-timeout'
    elif off != 0:
        r['verdict'], r['why'] = 'DIAG', 'repro-unfaithful(pp 关也不为 0 ⇒ 复现不忠实)'
    elif on == 0:
        r['verdict'], r['why'] = 'SAFE', 'dyn-no-flip'
    else:
        if r['reach'] in ('literal-single', 'capture-single', 'array-small'):
            r['verdict'], r['why'] = 'LOW', 'dyn-flip-but-data-single-line(%s)' % r['reach']
        else:
            r['verdict'], r['why'] = 'HIT', 'dyn-flip'
    rows.append(r)

for r in rows:
    extra = ''
    if 'dyn_on' in r:
        extra = ' dyn_big=%s/%s dyn_off=%s/%s dyn_small=%s/%s' % (r.get('dyn_on'), RUNS, r.get('dyn_off'), RUNS, r.get('dyn_small'), RUNS)
    print('SITE verdict=%s file=%s line=%s kind=%s consumer=%s reach=%s left=%s %s%s' % (
        r['verdict'], r['file'], r['line'], r['kind'], r['consumer'], r['reach'],
        json.dumps(' | '.join(r['left_segs'])[:80], ensure_ascii=False), r['why'], extra))

hits = [r for r in rows if r['verdict'] == 'HIT']
hitkeys = sorted(set('%s:%s' % (r['file'], r['line']) for r in hits))
decl = []
for line in (DECL_RAW + '\n' + DECL_EXTRA).split('\n'):
    line = line.strip()
    if not line or line.startswith('#'):
        continue
    decl.append(line.split('|')[0].strip())
decl = sorted(set(decl))
undecl = [k for k in hitkeys if k not in decl]
stale = [k for k in decl if k not in hitkeys]
for k in undecl:
    print('UNDECLARED_HIT %s' % k)
for k in stale:
    print('DECL_STALE %s' % k)
print('SUMMARY files=%d sites=%d hit=%d low=%d diag=%d safe=%d runs=%d blind=%d undecl=%d decl_stale=%d declared_ok=%d' % (
    nfiles, len(rows), len(hits), len([r for r in rows if r['verdict'] == 'LOW']),
    len([r for r in rows if r['verdict'] == 'DIAG']), len([r for r in rows if r['verdict'] == 'SAFE']),
    RUNS, 1 if BLIND else 0, len(undecl), len(stale), len(decl) - len(stale)))
print('HITLIST ' + ','.join(hitkeys))
for r in rows:
    if r['verdict'] == 'LOW':
        print('LOWLIST %s:%s %s %s' % (r['file'], r['line'], r['reach'], r['reach_detail']))
PYEOF
}
# ── 金丝雀（自证扫描器与实测引擎都活着；夹具用 heredoc ⇒ 本件自身扫描时不留假站点） ──
canary_check() {   # canary_check <tmpd> ; 输出 CANARY hits=N sites=M
    local cdir="$1/canary"
    mkdir -p "$cdir"
    cat > "$cdir/fixture.sh" <<'CANARYEOF'
#!/usr/bin/env bash
set -uo pipefail
big="$(cat "$PAYLOAD_MULTI")"
if printf '%s' "$big" | grep -q CANARY_TOK; then echo A; fi
if printf '%s' "CANARY_TOK one-line" | grep -q CANARY_TOK; then echo B; fi
if grep -q CANARY_TOK <<<"$big"; then echo C; fi
printf '%s' "$big" | grep -q CANARY_TOK
CANARYEOF
    python3 - "$cdir" <<'PYC'
import sys, os
d = sys.argv[1]
open(os.path.join(d, 'payload-multi.txt'), 'w').write('CANARY_TOK\n' + '\n'.join('filler-%05d-%s' % (i, 'z'*30) for i in range(6000)))
open(os.path.join(d, 'payload-single.txt'), 'w').write('CANARY_TOK' + 'z'*4000)
PYC
    local out hitn nsite
    # ⚠️ 子调用必须带 PP_SKIP_CANARY=1：否则金丝雀会**递归**（子运行自己也造金丝雀 ⇒ 无限嵌套，实测会挂死）
    out="$(PP_SKIP_CANARY=1 PAYLOAD_MULTI="$cdir/payload-multi.txt" PAYLOAD_SINGLE="$cdir/payload-single.txt" \
           bash "$SELF" --root "$cdir" --runs 4 2>&1)"
    hitn="$(printf '%s\n' "$out" | sed -n 's/^SUMMARY .*hit=\([0-9]*\).*/\1/p')"
    nsite="$(printf '%s\n' "$out" | sed -n 's/^SUMMARY .*sites=\([0-9]*\).*/\1/p')"
    printf 'CANARY hits=%s sites=%s\n' "${hitn:-?}" "${nsite:-?}"
    if [ "${hitn:-0}" = 1 ] && [ "${nsite:-0}" = 3 ] \
       && grep -q 'dyn_off=0/4' <<<"$out"; then
        return 0
    fi
    return 1
}

selftest() {
    local sb total=0 pass=0 fail=0
    sb="$(mktemp -d "${TMPDIR:-/tmp}/pipefail-sigpipe-selftest.XXXXXX")"
    expect() {  # expect <name> <want> <dir>
        local name="$1" want="$2" dir="$3" out got
        out="$(PP_SKIP_CANARY=1 bash "$SELF" --root "$dir" --runs 4 2>&1)"
        got="$(printf '%s\n' "$out" | sed -n 's/^SITE verdict=\([A-Z]*\).*/\1/p' | head -1)"
        total=$((total+1))
        if [ "$got" = "$want" ]; then pass=$((pass+1)); say "SELFTEST CASE $name = PASS want=$want got=$got"
        else fail=$((fail+1)); say "SELFTEST CASE $name = FAIL want=$want got=${got:-<none>}"; printf '%s\n' "$out" | sed 's/^/      | /'; fi
    }
    expect_n() {  # expect_n <name> <field> <want> <dir> [env...]
        local name="$1" field="$2" want="$3" dir="$4" out got
        shift 4
        out="$(env "$@" bash "$SELF" --root "$dir" --runs 4 2>&1)"
        got="$(printf '%s\n' "$out" | sed -n "s/^SUMMARY .*$field=\([0-9]*\).*/\1/p")"
        total=$((total+1))
        if [ "${got:-x}" = "$want" ]; then pass=$((pass+1)); say "SELFTEST CASE $name = PASS $field=$got"
        else fail=$((fail+1)); say "SELFTEST CASE $name = FAIL $field want=$want got=${got:-<none>}"; printf '%s\n' "$out" | sed 's/^/      | /'; fi
    }
    local base="$sb/base"; mkdir -p "$base"
    printf 'PAYLOAD_MULTI\n' >/dev/null
    printf 'CANARY_TOK\n' > "$base/multi.txt"
    for i in $(seq 1 4000); do printf 'filler-%05d-zzzzzzzzzzzzzzzzzzzzzzzzzzzz\n' "$i"; done >> "$base/multi.txt"
    printf 'CANARY_TOKzzzz\nr2\nr3\nr4\n' > "$base/small.txt"
    local d

    # S01 内容左端（多行）+ grep -q 在 if 里 + rc 被消费 ⇒ HIT
    d="$sb/s01"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
big="$(cat "$PP_MULTI_SRC")"
if printf '%s' "$big" | grep -q TOK; then echo yes; fi
SEOF
    expect S01-content-multi-if HIT "$d"
    # S02 件内没有 pipefail ⇒ 站点根本不该被算作候选（sites=0）
    d="$sb/s02"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
big="$(cat "$PP_MULTI_SRC")"
if printf '%s' "$big" | grep -q TOK; then echo yes; fi
SEOF
    expect_n S02-no-pipefail-0sites sites 0 "$d"
    # S03 rc 未被消费（无 set -e）⇒ SAFE
    d="$sb/s03"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
big="$(cat "$PP_MULTI_SRC")"
printf '%s' "$big" | grep -q TOK
echo done
SEOF
    expect S03-rc-unused-safe SAFE "$d"
    # S04 here-string（无管道）⇒ 不是站点
    d="$sb/s04"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
big="$(cat "$PP_MULTI_SRC")"
if grep -q TOK <<<"$big"; then echo yes; fi
SEOF
    expect_n S04-herestring-0sites sites 0 "$d"
    # S05 左端是外部命令（抽不出来跑）⇒ DIAG（不进 rc）
    d="$sb/s05"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
if convert x.png info: | grep -q TOK; then echo yes; fi
SEOF
    expect S05-external-left-diag DIAG "$d"
    # S06 左端是**单行字面量** ⇒ 结构危险但数据面够不着 ⇒ LOW
    d="$sb/s06"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
if printf '%s' "one-line-only" | grep -q one-line-only; then echo yes; fi
SEOF
    expect S06-literal-left-low LOW "$d"
    # S07 head 早退（rc 被消费）⇒ HIT
    d="$sb/s07"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
big="$(cat "$PP_MULTI_SRC")"
if printf '%s' "$big" | head -1; then echo yes; fi
SEOF
    expect S07-head-if HIT "$d"
    # S08 同一行两条管线 ⇒ 两条都被看见（hit=2）
    d="$sb/s08"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
big="$(cat "$PP_MULTI_SRC")"
if printf '%s' "$big" | grep -q AAA && printf '%s' "$big" | grep -q BBB; then echo yes; fi
SEOF
    expect_n S08-two-pipelines hit 2 "$d"
    # S09 heredoc 体里的同形文本 ⇒ 不算站点
    d="$sb/s09"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
cat <<EOT
if printf '%s' "$x" | grep -q TOK; then echo yes; fi
EOT
echo ok
SEOF
    expect_n S09-heredoc-body-skipped sites 0 "$d"
    # S10 续行：站点行号取**起始行**
    d="$sb/s10"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
big="$(cat "$PP_MULTI_SRC")"
if printf '%s' "$big" \
   | grep -q TOK; then echo yes; fi
SEOF
    total=$((total+1))
    local o10 g10
    o10="$(PP_SKIP_CANARY=1 bash "$SELF" --root "$d" --runs 4 2>&1)"
    g10="$(printf '%s\n' "$o10" | sed -n 's/^SITE .*line=\([0-9]*\).*/\1/p' | head -1)"
    if [ "${g10:-x}" = "4" ]; then pass=$((pass+1)); say "SELFTEST CASE S10-continuation-lineno = PASS line=4"
    else fail=$((fail+1)); say "SELFTEST CASE S10-continuation-lineno = FAIL line=${g10:-<none>}"; fi
    # S11 小数组左端（数据面小）⇒ LOW，而不是 HIT
    d="$sb/s11"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
ARR=(alpha beta gamma delta)
if printf '%s\n' "${ARR[@]}" | grep -qx alpha; then echo yes; fi
SEOF
    expect S11-array-small-low LOW "$d"
    # S12 末段不是早退读者（tail）⇒ 无站点
    d="$sb/s12"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
big="$(cat "$PP_MULTI_SRC")"
if printf '%s' "$big" | tail -3 >/dev/null; then echo yes; fi
SEOF
    expect_n S12-no-early-exit-0sites sites 0 "$d"
    # S13 弄瞎动态引擎 ⇒ 必不产生 HIT（与 S01 成对：同一形状，只换开关）
    d="$sb/s13"; mkdir -p "$d"; cat > "$d/case.sh" <<'SEOF'
#!/usr/bin/env bash
set -uo pipefail
big="$(cat "$PP_MULTI_SRC")"
if printf '%s' "$big" | grep -q TOK; then echo yes; fi
SEOF
    expect_n S13-blind-no-hit hit 0 "$d" PP_TEST_BLIND=1
    # S14 成对总闸：真树 + 弄瞎 ⇒ 金丝雀失明 ⇒ NOINFO rc=2（**NOINFO 绝不当绿**）
    total=$((total+1))
    local o14 r14
    o14="$(PP_TEST_BLIND=1 bash "$SELF" --root "$ROOT" --runs 2 2>&1; echo "rc=$?")"
    r14="$(printf '%s\n' "$o14" | sed -n 's/.*rc=\([0-9]*\)$/\1/p')"
    if [ "${r14:-x}" = "2" ] && grep -q 'PIPEFAIL_SIGPIPE=NOINFO' <<<"$o14"; then
        pass=$((pass+1)); say "SELFTEST CASE S14-blind-pair = PASS 弄瞎 ⇒ NOINFO rc=2"
    else
        fail=$((fail+1)); say "SELFTEST CASE S14-blind-pair = FAIL rc=${r14:-?}（应为 2/NOINFO）"
    fi
    # S15 声明表自洽闸：把一条不存在的声明塞进去 ⇒ 必须 decl_stale≥1（且 rc=1）
    total=$((total+1))
    local o15
    o15="$(PP_DECL_EXTRA='no/such/file.sh:1' bash "$SELF" --root "$ROOT" --runs 2 2>&1; echo "rc=$?")"
    if grep -q 'DECL_STALE no/such/file.sh:1' <<<"$o15"; then
        pass=$((pass+1)); say "SELFTEST CASE S15-decl-stale-gate = PASS 假声明被抓"
    else
        fail=$((fail+1)); say "SELFTEST CASE S15-decl-stale-gate = FAIL 假声明没被抓"
    fi
    rm -rf "$sb"
    if [ "$fail" -eq 0 ]; then say "SELFTEST=PASS total=$total pass=$pass fail=$fail"; return 0; fi
    say "SELFTEST=FAIL total=$total pass=$pass fail=$fail"; return 1
}

main_check() {
    local tmpd out summary files sites hit low diag safe undecl stale declared_ok
    tmpd="$(mktemp -d "${TMPDIR:-/tmp}/pipefail-sigpipe.XXXXXX")"
    TMPUSED="$tmpd"
    python3 - "$tmpd" <<'PY'
import sys, os
d = sys.argv[1]
open(os.path.join(d, 'multi.txt'), 'w').write('CANARY_TOK\n' + '\n'.join('filler-%05d-%s' % (i, 'z'*30) for i in range(6000)))
open(os.path.join(d, 'small.txt'), 'w').write('CANARY_TOK\nr2\nr3\nr4\n')
PY
    out="$(run_check "$tmpd")"
    printf '%s\n' "$out"
    summary="$(printf '%s\n' "$out" | sed -n 's/^SUMMARY //p')"
    files="$(printf '%s' "$summary" | sed -n 's/.*files=\([0-9]*\).*/\1/p')"
    sites="$(printf '%s' "$summary" | sed -n 's/.*sites=\([0-9]*\).*/\1/p')"
    hit="$(printf '%s' "$summary" | sed -n 's/.* hit=\([0-9]*\).*/\1/p')"
    low="$(printf '%s' "$summary" | sed -n 's/.* low=\([0-9]*\).*/\1/p')"
    diag="$(printf '%s' "$summary" | sed -n 's/.* diag=\([0-9]*\).*/\1/p')"
    safe="$(printf '%s' "$summary" | sed -n 's/.* safe=\([0-9]*\).*/\1/p')"
    undecl="$(printf '%s' "$summary" | sed -n 's/.* undecl=\([0-9]*\).*/\1/p')"
    declared_ok="$(printf '%s' "$summary" | sed -n 's/.* declared_ok=\([0-9]*\).*/\1/p')"
    stale="$(printf '%s' "$summary" | sed -n 's/.* decl_stale=\([0-9]*\).*/\1/p')"
    files="${files:-0}"; sites="${sites:-0}"; hit="${hit:-0}"; low="${low:-0}"
    diag="${diag:-0}"; safe="${safe:-0}"; undecl="${undecl:-0}"; stale="${stale:-0}"; declared_ok="${declared_ok:-0}"
    local canary_ok=0 canary_line
    if [ "${PP_SKIP_CANARY:-0}" = 1 ]; then
        canary_line='SKIPPED (PP_SKIP_CANARY=1；只有金丝雀自己的子调用会用它)'
        canary_ok=1
    else
        canary_line="$(canary_check "$tmpd")"
    fi
    case "$canary_line" in SKIPPED*) say "CANARY $canary_line" ;; *) say "CANARY $canary_line" ;; esac
    grep -q 'CANARY hits=1 sites=3' <<<"$canary_line" && canary_ok=1
    if [ "$canary_ok" != 1 ]; then
        say "PIPEFAIL_SIGPIPE=NOINFO reason=canary-blind files=$files sites=$sites hit=$hit low=$low diag=$diag safe=$safe"
        rc=2
    elif [ "$ROOT" = "$REAL_ROOT" ] && [ "$files" -lt "$MIN_FILES" ]; then
        say "PIPEFAIL_SIGPIPE=NOINFO reason=too-few-files files=$files min=$MIN_FILES"; rc=2
    elif [ "$ROOT" = "$REAL_ROOT" ] && [ "$sites" -lt "$MIN_SITES" ]; then
        say "PIPEFAIL_SIGPIPE=NOINFO reason=too-few-sites sites=$sites min=$MIN_SITES"; rc=2
    elif [ "$sites" -eq 0 ]; then
        say "PIPEFAIL_SIGPIPE=NOINFO reason=no-site-at-all files=$files"; rc=2
    elif [ "$undecl" -gt 0 ] || [ "$stale" -gt 0 ]; then
        say "PIPEFAIL_SIGPIPE=FAIL undeclared_hit=$undecl decl_stale=$stale files=$files sites=$sites hit=$hit low=$low diag=$diag safe=$safe runs=${RUNS}"
        rc=1
    else
        say "PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 declared=$declared_ok files=$files sites=$sites hit=$hit low=$low diag=$diag safe=$safe runs=${RUNS}"
        rc=0
    fi
    if [ "$KEEP_TMP" = 1 ]; then say "PP_TMP_DIR=$tmpd"; else rm -rf "$tmpd"; fi
    return "$rc"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --root)      ROOT="$2"; shift 2 ;;
        --runs)      RUNS="$2"; shift 2 ;;
        --debug-tmp) KEEP_TMP=1; shift ;;
        --selftest)  selftest; exit $? ;;
        -h|--help)   usage; exit 0 ;;
        *)           say "unknown-arg: $1"; usage; exit 2 ;;
    esac
done

main_check
exit $?

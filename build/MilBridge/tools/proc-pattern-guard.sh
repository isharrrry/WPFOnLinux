#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# proc-pattern-guard.sh —— 牙：**按模式收/数进程** 者必须能证明"排除了自己"
#
# 【本件是`TASK-0714`的牙的**仓外原型**（`~/w154a/tooth/`）；落地时机由主控定】
#
# 判据（**先写**）：`~/w154a/criteria.md`（`§0`–`§6`）。本件只实现它，**不许放宽**。
#
# 【为什么要有这颗牙】本会话「按模式匹配命令行」自匹配咬 **5 次**（全零损害）：
#   ① `pkill -f '<模式>'` 误杀自身本体｜② `pgrep -P "$$" -f <模式>`（`$$` 只作**集合限定**、
#   不构成"排除"，命令替换的子 shell 与脚本 cmdline 同源 ⇒ 仍自匹配）｜③ 收拾看门狗时把
#   **自己那条 shell** `kill -TERM`｜④ 数残留进程**把自己算进去**（假阳性 1）｜
#   ⑤ `--live-selftest` 按**整条 cmdline 子串**判"显示被占" ⇒ 自匹配伪报 `display busy`。
#   ⑤ 的修后形态（`geom-revert-beat-check.sh:141-142`：逐 pid 读 `/proc` ＋ **同时**排除
#   `$$` 与 `${PPID}` ＋ 再按 argv0 基名与整 argv 精确比）**就是本牙承认的"完整证明"样板**。
#
# 【纪律：本件自己遵守自己】本件**内部不使用 `pkill`/`pgrep`**（`--self-check` 会自扫；
#   扫描一律读 `/proc` 并显式排除自身 pid）。**不许**用 `pgrep -f` 实现本牙。
#
# 【三态】`PASS`（rc=0，全部命中带完整证明）｜`FAIL`（rc=1，逐处点名 `file:line`）｜
#   `NOINFO`（rc=2，扫不动／判不了）。**`NOINFO` 既不算绿也不算红**；红优先于 `NOINFO`。
#
# 【用法】（⚠️ **只接受 `--repo=<路径>` 这一种写法** —— 空格分隔的 `--repo .` **不是**合法调用）
#   bash proc-pattern-guard.sh --repo=<仓根> [--min-files=10]     # 扫描
#   bash proc-pattern-guard.sh --selftest                         # 两例两极化自测（含 14 格）
#   bash proc-pattern-guard.sh --self-check                       # 只扫本件自己（牙自己不许用 pkill/pgrep）
#   bash proc-pattern-guard.sh --help
#   · **未知参数一律响亮失败**（`未知参数：<原样回显>（用 --help）`、`rc=2`），**绝不静默忽略** ——
#     实测：`--repo .` ⇒ `未知参数：--repo` rc=2；`--bogus-xyz` ⇒ 同形 rc=2。
#     这条是**有意**的：判据件被喂错参数时"静默按默认仓根扫"会得出**看着像绿**的读数。
#
# 【⚠️ 已知盲点（必须与绿同屏读）】字符串拼接／变量间接／`eval`／非 `.sh`·`.py` 的调用方／
#   交互式命令／**仓外脚本** ⇒ 本件**看不见**；「本件 PASS」**不**等于"这台机器上不再有自匹配事故"。
# ══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

MODE=scan
REPO=""
MIN_FILES=10
for a in "$@"; do
  case "$a" in
    --repo=*)      REPO="${a#--repo=}" ;;
    --min-files=*) MIN_FILES="${a#--min-files=}" ;;
    --selftest)    MODE=selftest ;;
    --self-check)  MODE=selfcheck ;;
    -h|--help)     MODE=help ;;
    *) echo "proc-pattern-guard: 未知参数：$a（用 --help）" >&2; exit 2 ;;
  esac
done

if [ "$MODE" = help ]; then
  sed -n '2,40p' "$0"; exit 0
fi
if [ -z "$REPO" ]; then
  REPO="${PROCGUARD_REPO:-${R:-/home/links-dev/netTest/wpf-linux-20260906/wpf-linux}}"
fi
# ⚠️ 本件自己的路径：**不用 `__file__`**（`#57` 现场教训：`python3 - <<EOF`（stdin）里
#   `__file__` 恒为 `<stdin>`，反推仓根会**静默指到别处**）⇒ 由 bash 侧显式导出。
SELF="$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")"

export PROCGUARD_REPO="$REPO"
export PROCGUARD_MIN_FILES="$MIN_FILES"
export PROCGUARD_MODE="$MODE"
export PROCGUARD_SELF="$SELF"

python3 - <<'PYEOF'
import os, re, sys, io, tokenize, tempfile, shutil, importlib.util

REPO      = os.environ['PROCGUARD_REPO']
MIN_FILES = int(os.environ['PROCGUARD_MIN_FILES'])
MODE      = os.environ['PROCGUARD_MODE']
SELF      = os.environ['PROCGUARD_SELF']

SKIP_DIRS = {'upstream', '.git', '__pycache__', 'bin', 'obj', '.artifacts',
             'geom-corpus', 'artifacts'}

# ── 一、剥注释（承重）：注释里写 `pkill -f` 的纪律说明**不是调用** ─────────────────
def scan_shell_line(ln):
    """返回 `(res, mask)` 两条通道：
       · `res`  = **注释**被抹成空白、**引号与串内容保留** ⇒ 供**证明判定**（`"$$"`／`"${PPID:-0}"`
                  这类判等必须看得见）；也供 heredoc 定界符识别（`<<'PYEOF'`）。
       · `mask` = 在 `res` 之上再抹掉**引号内**文本 ⇒ 供**形态识别**（防 `grep -E '…pkill…-f'`
                  这种**自审行**里的模式串被当成真调用 —— 仓内真有这种行）。
       ⚠️ 两条通道**必须分开**：本件自伤两次 —— ① 只做掩码 ⇒ `<<'PYEOF'` 认不出来 ⇒
          把自己的**文档串**（第 79 行）判成 2 个 `P1`；② 只做剥注释 ⇒ 自审行假红。
       `$(…)`／反引号里**重新回到命令语境**（命令替换内的 `"` 是新的引号域）。"""
    res = list(ln)
    mask = list(ln)
    n = len(ln)
    stack = ['cmd']
    i = 0
    while i < n:
        c = ln[i]
        st = stack[-1]
        if st in ('sq', 'dq'):
            mask[i] = ' '
            if st == 'sq':
                if c == "'":
                    stack.pop()
            else:
                if c == '\\':
                    if i + 1 < n:
                        mask[i + 1] = ' '
                    i += 2
                    continue
                if c == '"':
                    stack.pop()
                elif c == '$' and i + 1 < n and ln[i + 1] == '(':
                    stack.append('cmd')
                elif c == '`':
                    stack.append('cmd')
            i += 1
            continue
        # ── 命令语境 ──
        if c == '#':
            for j in range(i, n):
                res[j] = ' '
                mask[j] = ' '
            break
        if c == "'":
            stack.append('sq'); mask[i] = ' '
        elif c == '"':
            stack.append('dq'); mask[i] = ' '
        elif c == '\\':
            if i + 1 < n:
                mask[i + 1] = ' '
            i += 2
            continue
        elif c == '`':
            stack.append('cmd'); mask[i] = ' '
        elif c == '$' and i + 1 < n and ln[i + 1] == '(':
            stack.append('cmd'); mask[i] = ' '
        elif c == ')' and st == 'cmd' and len(stack) > 1:
            stack.pop()
        i += 1
    return ''.join(res), ''.join(mask)

def strip_comment_sh(ln):
    return scan_shell_line(ln)[0]

def mask_sh(ln):
    return scan_shell_line(ln)[1]

def strip_py_comments(text):
    """用 tokenize 把 COMMENT 抹成等长空白（保住行号）；解析失败 ⇒ 返回 None（⇒ 该件 NOINFO）。"""
    lines = text.splitlines(keepends=True)
    try:
        toks = list(tokenize.generate_tokens(io.StringIO(text).readline))
    except Exception:
        return None
    arr = [list(l) for l in lines]
    for t in toks:
        if t.type == tokenize.COMMENT:
            (r, c0), (_, c1) = t.start, t.end
            if 1 <= r <= len(arr):
                for c in range(c0, min(c1, len(arr[r - 1]))):
                    if arr[r - 1][c] != '\n':
                        arr[r - 1][c] = ' '
    return ''.join(''.join(l) for l in arr)

# ── 二、形态识别（只看 mask；只判 5 种）──────────────────────────────────────────
TOKEN_RE = re.compile(r'(?<![\w./-])(pkill|killall|pgrep|ps|kill|grep|egrep|fgrep)(?![\w-])')
FLAG_F_RE = re.compile(r'(?:^|\s)-{1,2}[A-Za-z]*f[A-Za-z]*(?=\s|$)')

def detect_hits(masked, raw=None, in_enum_loop=False):
    """返回 [(form, cmd), …]；form ∈ {P1,P2,P3,P4,P5,PROC}；空列表 = 本行无命中。
       ⚠️ `masked` 只管**命令名**识别（防 `grep -E …pkill…-f` 这种自审行假红）；
          **PROC 形状**识别改用 `raw`（剥注释、**保留引号**）—— 路径被引号包住时，
          掩码会把 `cmdline` 一并抹掉 ⇒ **漏判**。本件自伤一次：我给自己那 6 处修法
          打补丁后沙箱报 `hits=0`（本该是 4 处已证明的 /proc 命中）⇒ 那是靠**看不见**
          过关的**假绿**，不是已证明。已修，并加两格自测（引号式路径：必红/必绿）钉住。"""
    hits = []
    miter = list(TOKEN_RE.finditer(masked))
    for idx, m in enumerate(miter):
        name = m.group(1)
        rest = masked[m.end():]
        if name in ('pkill', 'killall'):
            if FLAG_F_RE.search(rest) or '--full' in rest:
                hits.append(('P1', name))
        elif name == 'pgrep':
            if FLAG_F_RE.search(rest) or '--full' in rest:
                hits.append(('P2', name))
        elif name == 'ps':
            # `ps … | grep …`：本段之后的第一个 `|` 之后出现 grep 家族
            if re.search(r'\|[^|]*?(?<![\w./-])(grep|egrep|fgrep)(?![\w-])', rest):
                hits.append(('P3', 'ps|grep'))
        elif name == 'kill':
            if rest.lstrip().startswith('$(') or re.match(r'\s*`', rest):
                if re.search(r'(?<![\w./-])(pgrep|ps)(?![\w-])', rest):
                    hits.append(('P4', 'kill $(…)'))
    # `/proc` **枚举他人 pid** 的扫描（R2'：不是 R1 形态，但同源 —— 事故 ⑤ 的根因是
    #   "扫描者自己出现在扫描结果里"，与用 `pgrep` 还是 `for p in /proc/[0-9]*` 无关）。
    #   ⚠️ **只读自己的 cmdline 不算枚举**：`</proc/$$/cmdline`／`</proc/$PPID/cmdline`
    #   （审计日志就这写法）⇒ 不点名。本件自伤一次（把 `integration-wave.sh:53` 的
    #   审计行误报成 `/proc-scan`）。
    probe = raw if raw is not None else masked
    # ⚠️ 枚举的机械特征**只有"枚举源"这一族**（本行自带／或本行在枚举循环体内）：
    #   `/proc/[0-9]*`／`/proc/*`／`ls /proc`／`find /proc`。
    #   **不许**把 `读 /proc/$p/cmdline` 本身当枚举特征 —— `$p` 常见是**函数参数**
    #   （`integration-wave.sh:47` 的 `ppid_cmd()` 读的就是**给定的那一个** pid，默认 `$PPID`）
    #   ⇒ 那样判是**假阳性**（本件第二修：引号假阴性刚修好就暴露了这条）。
    enum_src = (re.search(r'/proc/\s*(\[0-9\]|\*)', probe)
                or 'ls /proc' in probe or 'find /proc' in probe)
    if '/proc' in probe and 'cmdline' in probe and (enum_src or in_enum_loop):
        hits.append(('PROC', '/proc-scan'))
    return hits

# ── 三、函数域 / 循环域 / heredoc（证据域与"数据不算代码"）───────────────────────
FUNC_RE = re.compile(r'^\s*(?:function\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{')
LOOP_RE = re.compile(r'^\s*(?:for|while|until)\b')
HERE_RE = re.compile(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")
SHELL_HEREDOC_CMDS = ('bash', 'sh', 'dash', 'eval', 'source', '.', 'ksh', 'zsh')

def function_ranges(lines):
    rng = {}
    i = 0
    while i < len(lines):
        m = FUNC_RE.match(lines[i])
        if m:
            depth = lines[i].count('{') - lines[i].count('}')
            j = i + 1
            while j < len(lines) and depth > 0:
                depth += lines[j].count('{') - lines[j].count('}')
                j += 1
            rng[m.group(1)] = (i, j)
            i = j
        else:
            i += 1
    return rng

def loop_ranges(lines):
    """`for`/`while`/`until` … `done` 的块区间（供 `/proc` 扫描类命中定证据域）。"""
    rng = []
    stack = []
    for i, ln in enumerate(lines):
        if re.match(r'^\s*done\b', ln):
            if stack:
                a = stack.pop()
                rng.append((a, i + 1))
            continue
        if LOOP_RE.match(ln) and not re.search(r'\bdone\b', ln):
            stack.append(i)
    while stack:
        rng.append((stack.pop(), len(lines)))
    return sorted(rng, key=lambda ab: (ab[0], -ab[1]))

def heredoc_skip(lines):
    """返回"属于 heredoc 体"的行号集合。**承重**：`.sh` 里 `python3 - <<'PYEOF' … PYEOF`
       的体内是**另一种语言的数据/代码**，按 shell 扫会把文档串里的示例误判成调用
       （本件自伤一次：`--self-check` 在**自己的文档串**第 79 行报了 2 个 `P1`）。
       ⇒ 非 shell 解释器的 heredoc 体**不扫**（已知盲点，如实声明）；
          `bash <<EOF` 这类**是** shell 代码 ⇒ 照扫。"""
    skip = set()
    i = 0
    while i < len(lines):
        # ⚠️ **不能用 mask**：为防"grep 的模式串里出现 pkill"而做的掩码会把 `<<'PYEOF'`
        #   的**引号**也抹掉 ⇒ 定界符认不出来（本件自伤一次）。用**剥注释后的原文**。
        raw = strip_comment_sh(lines[i])
        m = HERE_RE.search(raw)
        if m:
            mark = m.group(2)
            head = raw[:m.start()]
            first = head.strip().split()[0] if head.strip() else ''
            is_shell = os.path.basename(first) in SHELL_HEREDOC_CMDS
            j = i + 1
            while j < len(lines) and lines[j].strip() != mark:
                if not is_shell:
                    skip.add(j)
                j += 1
            i = j + 1
            continue
        i += 1
    return skip

# ── 四、证明判定（**判据 §2 R2**）──────────────────────────────────────────────
def proof_of(text):
    """返回 (verdict, code)。verdict ∈ {full, partial}。
       承认的完整证明只有三类（**判据 §2**）：
         `dual-exclude`   ：`$$` 出现在**排除性上下文** ∧ `$PPID` 出现；
         `ancestor-chain` ：读 `/proc/<pid>/stat` 且以 `$$` 为根走父链（或同名样板函数）；
         `argv-identity`  ：argv0 **具名门** ∧ argv **精确相等**（`grep -qx`／`[ "$aN" = "…" ]`／`case`）
                            ⇒ 构造上不可能匹配到"bash 承载的那条链"。
       ⚠️ `-P "$$"`（集合限定）**不构成**排除 —— 事故 ② 的形态 ⇒ 只判 `partial`。"""
    # `$$` 的**排除性**上下文：比较/判等/`grep -v`
    dd = bool(re.search(r'(?:=|!=|-eq|-ne)\s*"?\$\$"?', text)) or \
         bool(re.search(r'grep\s+-v[^\n]*\$\$', text)) or \
         bool(re.search(r'\$\$\s*\)\s*(?:&&|\|\|)?\s*(?:continue|return|break|exit)', text))
    ppid = bool(re.search(r'\$\{?PPID', text))
    if dd and ppid:
        return 'full', 'dual-exclude($$-and-PPID)'
    # 祖先链：读 /proc/<pid>/stat（父链 walk）＋ `$$` 作根
    if '/proc' in text and re.search(r'/proc/[^\s"\']*/stat', text) and '$$' in text:
        return 'full', 'ancestor-chain(/proc/stat-walk)'
    # argv 身份：argv0 具名门 ＋ argv 精确相等
    argv0_gate = bool(re.search(r'\$\{?a0', text)) and ('case ' in text or '##*/' in text)
    argv_exact = bool(re.search(r'grep\s+-qx\b', text)) or \
                 bool(re.search(r'\[\s*-?\s*"\$a[0-9]"\s*=', text))
    if argv0_gate and argv_exact:
        return 'full', 'argv-identity(exact-argv0+exact-argv)'
    if dd or ppid:
        return 'partial', ('missing-PPID' if (dd and not ppid) else 'missing-$$')
    # **事故 ② 的形态**：`$$` 只出现在 `-P "$$"`（**集合限定**）⇒ 不是排除，给专门的理由码
    if re.search(r'-P\s*"?\$\$', text):
        return 'partial', 'missing-PPID($$-only-as--P-set-restriction)'
    if '--exclude-self' in text:
        return 'partial', 'exclude-self-label-without-pid'
    return 'partial', 'missing-any-proof'

def domain_proof(chain, helper_bodies):
    """`chain` = [(label, text), …]，由**最内层证据域**排到最外层（`loop` → `func` → `line`）。
       逐层判"完整证明"，**第一层命中即返回**；一层都没有 ⇒ 再看**一级 helper 展开**
       （域里引用了同文件内的函数，而该函数的体里有完整证明 —— 仓内样板 `close-wave.sh`
       的 `self_chain_pids` 正是这种写法）。**只在 partial 时**才放宽到外层 ⇒ 不会把
       "函数里另一处有守卫"变成"这一处也算了"以外的更多宽松（外层用的是同一族判据）。"""
    last = ('partial', 'missing-any-proof')
    for label, text in chain:
        v, code = proof_of(text)
        if v == 'full':
            return 'full', code + ('' if label == 'line' else ('@' + label))
        last = (v, code + '@' + label) if label != 'line' else (v, code)
    for label, text in chain:
        for name, body in helper_bodies.items():
            if re.search(r'(?<![\w./-])' + re.escape(name) + r'(?![\w(])', text):
                hv, hc = proof_of(body)
                if hv == 'full':
                    return 'full', hc + ' via-helper:' + name
    return last

# ── 五、扫一棵树 ──────────────────────────────────────────────────────────────
def walk(root):
    out = []
    for dp, dns, fns in os.walk(root):
        dns[:] = [d for d in dns if d not in SKIP_DIRS]
        for fn in fns:
            if fn.endswith('.sh') or fn.endswith('.py'):
                out.append(os.path.join(dp, fn))
    return sorted(out)

def analyze_file(path):
    """返回 (hits, na, noinfo_reason)。hits = [(lineno, form, cmd, verdict, code)]"""
    try:
        txt = open(path, encoding='utf-8', errors='replace').read()
    except OSError as e:
        return [], 0, 'unreadable:' + str(e)
    is_py = path.endswith('.py')
    if is_py:
        stripped = strip_py_comments(txt)
        if stripped is None:
            return [], 0, 'tokenize-failed'
    else:
        stripped = txt
    raw_lines = stripped.splitlines()
    masked_lines = ([mask_sh(l) for l in raw_lines] if not is_py
                    else [re.sub(r"['\"].*?['\"]", ' ', l) for l in raw_lines])
    # ⚠️ `scan_lines`：把**非 shell heredoc 体**置空后**专供结构判定**（函数域/循环域/枚举体/证据域）。
    #   heredoc 体是**数据**：`t1c-census.sh` 的 `for d in glob.glob('/proc/[0-9]*')` 是 **Python** 的行，
    #   用全文算循环域会把它当成 shell 的 `for` ⇒ 开出一个永不 `done` 的循环 ⇒ 把后面
    #   "读**某个已知 pid** 的 cmdline"那几行误判成"枚举他人 pid"（**假阳性**，本件第三修）。
    # ⚠️【第四修】`commentless`：**剥注释**（shell 行式；`.py` 已由 tokenize 剥过）。
    #   两个用处：① 主扫描通道（`probe`）必须用它 —— 否则**注释里提到 `/proc/*/cmdline`** 会被当成枚举
    #   （现场 `geom-revert-beat-check.sh:136` 就是一行注释被误判，**假阳性**）；
    #   ② 证据域也必须用它 —— **写在注释里的"排除"不算证明**（`criteria.md` §2 的反向对偶：
    #   注释不算调用 ⇒ 注释也不算证明），否则一行 `# 我已排除 $$ 与 $PPID` 就能把红变绿。
    commentless = ([strip_comment_sh(l) for l in raw_lines] if not is_py else raw_lines)
    skip = heredoc_skip(raw_lines) if not is_py else set()      # ⚠️ **必须先算 `skip`**（下面要用）
    scan_lines = [('' if i in skip else l) for i, l in enumerate(commentless)] \
        if not is_py else commentless
    frng = function_ranges(scan_lines) if not is_py else {}
    lrng = loop_ranges(scan_lines) if not is_py else []
    # 枚举循环体（循环头带 `/proc/[0-9]*`／`/proc/*`／`ls /proc`／`find /proc`）的行号区间
    enum_loops = [(a, b) for (a, b) in lrng
                  if re.search(r'/proc/\s*(\[0-9\]|\*)|ls /proc|find /proc', scan_lines[a])]
    helper_bodies = ({n: '\n'.join(scan_lines[a:b]) for n, (a, b) in frng.items()} if frng else {})
    hits, na = [], 0
    for i, ml in enumerate(masked_lines):
        if i in skip:
            continue
        h = detect_hits(ml, scan_lines[i] if i < len(scan_lines) else None,
                        any(a <= i < b for (a, b) in enum_loops))
        # 名字模式（`pgrep -a Xvfb`／`pkill -x name`）= **不适用**（进程名不可能等于含空格的 cmdline）
        for m in TOKEN_RE.finditer(ml):
            if m.group(1) in ('pgrep', 'pkill', 'killall') and not h:
                na += 1
        if not h:
            continue
        # ── 证据域链：最内层**循环块** → **函数体** → 本命令行（＋续行）
        chain = []
        inner = [ab for ab in lrng if ab[0] < i < ab[1]]
        if inner:
            a, b = sorted(inner, key=lambda ab: ab[1] - ab[0])[0]
            chain.append(('loop', '\n'.join(scan_lines[a:b])))
        for name, (a, b) in frng.items():
            if a < i < b:
                chain.append(('func:' + name, '\n'.join(scan_lines[a:b])))
                break
        j = i
        while j + 1 < len(raw_lines) and raw_lines[j].rstrip().endswith('\\'):
            j += 1
        chain.append(('line', '\n'.join(raw_lines[i:j + 1])))
        for form, cmd in h:
            v, code = domain_proof(chain, helper_bodies)
            if form == 'PROC' and v != 'full':
                code = 'proc-scan-no-self-exclusion'   # 根因同源：扫描者自己出现在结果里
            # ⚠️ 已验证的也**计数**（`full=` 才有读数；否则"只有 `/proc` 命中"的树会掉进零命中分支）
            hits.append((i + 1, form, cmd, v, code))
    return hits, na, None

def analyze_tree(root, min_files=MIN_FILES, label=None):
    res = {'root': root, 'files': 0, 'hits': [], 'na': 0, 'noinfo': [],
           'full': 0, 'partial': 0}
    if not os.path.isdir(root):
        res['result'] = 'NOINFO'; res['reason'] = 'repo-absent:' + root
        return res
    files = walk(root)
    res['files'] = len(files)
    for p in files:
        hits, na, nreason = analyze_file(p)
        res['na'] += na
        if nreason:
            res['noinfo'].append((p, nreason))
            continue
        for (ln, form, cmd, v, code) in hits:
            rel = os.path.relpath(p, root)
            res['hits'].append((rel, ln, form, cmd, v, code))
            if v == 'full':
                res['full'] += 1
            else:
                res['partial'] += 1
    if res['partial'] > 0:
        res['result'] = 'FAIL'; res['reason'] = 'missing-self-exclusion'
    elif res['files'] < min_files:
        res['result'] = 'NOINFO'; res['reason'] = 'too-few-files(%d<%d)' % (res['files'], min_files)
    elif len(res['hits']) == 0 and res['na'] == 0:
        if LIVENESS_BUSY[0]:
            res['result'] = 'PASS'; res['reason'] = 'liveness-probe-inner'
        elif liveness_probe():
            res['result'] = 'PASS'; res['reason'] = 'zero-hits-but-scanner-self-tested'
        else:
            res['result'] = 'NOINFO'; res['reason'] = 'blind-zero-hits-and-zero-na'
    else:
        res['result'] = 'PASS'; res['reason'] = 'all-hits-proved'
    return res

def report(res, show_hits=True):
    print('PROCGUARD_SCOPE files=%d hits=%d na=%d full=%d partial=%d noinfo=%d'
          % (res['files'], len(res['hits']), res['na'], res['full'], res['partial'],
             len(res['noinfo'])))
    if show_hits:
        for (rel, ln, form, cmd, v, code) in res['hits']:
            print('PROCGUARD_HIT %s:%d form=%s cmd=%s verdict=%s proof=%s'
                  % (rel, ln, form, cmd, v, code))
    for (p, r) in res['noinfo']:
        print('PROCGUARD_NOINFO file=%s reason=%s' % (p, r))
    if len(res['hits']) == 0 and res['files'] > 0:   # ⚠️ 没扫成（files=0）时**不许**打这一行：那会说成 clean
        print('PROCGUARD_ZERO=%s' % ('clean(self-tested)' if res['na'] == 0 else 'clean(na-only)'))
    print('PROCGUARD=%s reason=%s' % (res['result'], res.get('reason', '')))
    print('PROCGUARD_BLINDSPOT indirect=invisible eval=invisible non-sh-py=invisible '
          'outside-repo=invisible interactive=invisible')
    return {'PASS': 0, 'FAIL': 1, 'NOINFO': 2}[res['result']]

# ── 五之二、恒 0 守卫的**活性证明**（`#62` 修：原先 `res['hits'] == 0` 拿 list 比 int ⇒ 恒假 ⇒ 该守卫是死代码）──
#   "命中 0"有两个世界：**(a) 全仓真合规**｜**(b) 正则坏了/注释剥光了** —— 屏上一样。
#   原先打算判 `NOINFO`，但那会把"**真清理干净了**"判成 ❌（一次合规的重构反而红）。
#   ⇒ 改成**在带内证明"扫得动"**：临时造一坏一好两例，坏必红、好必绿 ⇒ 零命中 = `clean`；
#   证不出来 ⇒ 仍 `NOINFO`（**不许**猜）。
LIVENESS_BUSY = [False]

def liveness_probe():
    if LIVENESS_BUSY[0]:
        return False
    LIVENESS_BUSY[0] = True
    try:
        tmp = tempfile.mkdtemp(prefix='procguard-live-')
        try:
            d = os.path.join(tmp, 'bad'); os.makedirs(d)
            with open(os.path.join(d, 'a.sh'), 'w') as f:
                f.write('#!/usr/bin/env bash\npkill -f "Xvfb :98"\n')
            rb = analyze_tree(d, min_files=1)['result']
            d2 = os.path.join(tmp, 'good'); os.makedirs(d2)
            with open(os.path.join(d2, 'a.sh'), 'w') as f:
                f.write('#!/usr/bin/env bash\nkill "$XPID" 2>/dev/null || true\n')
            rg = analyze_tree(d2, min_files=1)['result']
            return rb == 'FAIL' and rg == 'PASS'
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
    finally:
        LIVENESS_BUSY[0] = False

# ── 六、模式：扫描 / 自测 / 自检 ───────────────────────────────────────────────
if MODE == 'scan':
    sys.exit(report(analyze_tree(REPO)))

if MODE == 'selfcheck':
    r = analyze_tree(os.path.dirname(SELF), min_files=1)
    # 只关心本件自己
    own = [h for h in r['hits'] if os.path.basename(h[0]) == os.path.basename(SELF)]
    ok = not own
    print('PROCGUARD_SELFCHECK self=%s hits_on_self=%d ⇒ %s'
          % (os.path.basename(SELF), len(own), 'OK' if ok else 'NG'))
    for h in own:
        print('PROCGUARD_SELFHIT %s:%d form=%s' % (h[0], h[1], h[2]))
    sys.exit(0 if ok else 1)

if MODE == 'selftest':
    CASES = []
    CASES.append(('bad-naked-pkill', 'FAIL',
                  '#!/usr/bin/env bash\npkill -f "Xvfb :98"\n'))
    CASES.append(('good-proc-dual-exclude', 'PASS',
                  '#!/usr/bin/env bash\n'
                  'for p in /proc/[0-9]*; do\n'
                  '  p="${p#/proc/}"\n'
                  '  [ "$p" = "$$" ] && continue\n'
                  '  [ "$p" = "${PPID:-0}" ] && continue\n'
                  '  tr "\\0" "\\n" < /proc/$p/cmdline | grep -qx ":227" && OWNER="$p"\n'
                  'done\n'))
    CASES.append(('bad-pgrepP-selfonly', 'FAIL',
                  '#!/usr/bin/env bash\napp_procs() { pgrep -P "$$" -f "dotnet X.dll" 2>/dev/null || true; }\n'))
    CASES.append(('good-pkill-x-name', 'PASS',
                  '#!/usr/bin/env bash\npkill -x Xvfb && echo done\n'))
    CASES.append(('bad-exclude-self-label', 'FAIL',
                  '#!/usr/bin/env bash\npgrep -f "dotnet X.dll" --exclude-self || true\n'))
    CASES.append(('good-comment-only', 'PASS',
                  '#!/usr/bin/env bash\n'
                  '# 收尾用 kill $XPID，绝不 pkill -f "Xvfb :97"（会匹配到自己的命令行）\n'
                  'kill "$XPID" 2>/dev/null || true\n'))
    CASES.append(('bad-ps-grep-count', 'FAIL',
                  '#!/usr/bin/env bash\nleftover="$(ps aux | grep -c "Xvfb :98" || true)"\n'))
    CASES.append(('good-ancestor-chain', 'PASS',
                  '#!/usr/bin/env bash\n'
                  'self_chain_pids() {\n'
                  '  local pid=$$ p\n'
                  '  while [ -n "$pid" ]; do\n'
                  '    printf "%s\\n" "$pid"\n'
                  '    p="$(sed "s/^.*) //" "/proc/$pid/stat" | awk "{print $2}")"\n'
                  '    pid="$p"\n'
                  '  done\n'
                  '}\n'
                  'app_probe_lines() { local excl; excl=" $(self_chain_pids | tr "\\n" " ")"; '
                  'pgrep -af -- "$APP_PROBE_RE"; }\n'))
    CASES.append(('bad-kill-dollar-pgrep', 'FAIL',
                  '#!/usr/bin/env bash\nkill $(pgrep -f "dotnet WpfTextDemo.dll") 2>/dev/null || true\n'))
    CASES.append(('bad-proc-substring-selfmatch', 'FAIL',
                  '#!/usr/bin/env bash\n'
                  'for p in $(ls /proc | grep -E "^[0-9]+$"); do\n'
                  '  tr "\\0" "\\n" < /proc/$p/cmdline | grep -q "Xvfb :227" && OWNER="$p"\n'
                  'done\n'))
    CASES.append(('good-argv-identity', 'PASS',
                  '#!/usr/bin/env bash\n'
                  'for p in /proc/[0-9]*; do\n'
                  '  a0="$(tr "\\0" "\\n" < /proc/$p/cmdline | sed -n 1p)"\n'
                  '  a1="$(tr "\\0" "\\n" < /proc/$p/cmdline | sed -n 2p)"\n'
                  '  case "$a0" in dotnet|*/dotnet) ;; *) continue ;; esac\n'
                  '  [ "$a1" = "WpfTextDemo.dll" ] || continue\n'
                  'done\n'))
    CASES.append(('good-pyheredoc-not-a-shell-loop', 'PASS',
                  '#!/usr/bin/env bash\n'
                  'python3 - <<\'PYEOF\'\n'
                  'import glob\n'
                  'for d in glob.glob(\'/proc/[0-9]*\'):\n'
                  '    pass\n'
                  'PYEOF\n'
                  'XPID=1234\n'
                  '_xcmd="$(tr "\\0" " " <"/proc/$XPID/cmdline" 2>/dev/null || true)"\n'
                  'echo "$_xcmd"\n'))
    CASES.append(('bad-proof-in-comment-only', 'FAIL',
                  '#!/usr/bin/env bash\n'
                  '# 我已经排除了 $$ 与 $PPID，也排了祖先链，请放心：[ "$p" = "$$" ] && continue\n'
                  'pkill -f "Xvfb :98"\n'))
    CASES.append(('good-single-pid-cmdline-read', 'PASS',
                  '#!/usr/bin/env bash\n'
                  'ppid_cmd() {\n'
                  '  local p="${1:-$PPID}" out=""\n'
                  '  out="$(tr "\\0" " " <"/proc/$p/cmdline" 2>/dev/null)"\n'
                  '  printf "%s" "${out:-?}"\n'
                  '}\n'))
    CASES.append(('bad-proc-quoted-substring', 'FAIL',
                  '#!/usr/bin/env bash\n'
                  'for p in /proc/[0-9]*; do\n'
                  '  p="${p#/proc/}"\n'
                  '  [ -r "/proc/$p/cmdline" ] || continue\n'
                  '  tr "\\0" "\\n" < "/proc/$p/cmdline" | grep -q ":227" && OWNER="$p"\n'
                  'done\n'))
    CASES.append(('good-proc-quoted-dual-exclude', 'PASS',
                  '#!/usr/bin/env bash\n'
                  'for p in /proc/[0-9]*; do\n'
                  '  p="${p#/proc/}"\n'
                  '  [ "$p" = "$$" ] && continue\n'
                  '  [ "$p" = "${PPID:-0}" ] && continue\n'
                  '  a0="$(tr "\\0" "\\n" < "/proc/$p/cmdline" | sed -n 1p)"\n'
                  '  case "${a0##*/}" in Xvfb) ;; *) continue ;; esac\n'
                  '  tr "\\0" "\\n" < "/proc/$p/cmdline" | grep -qx ":227" && OWNER="$p"\n'
                  'done\n'))
    CASES.append(('good-zero-hits', 'PASS',
                  '#!/usr/bin/env bash\nXPID=\n'
                  'kill "$XPID" 2>/dev/null || true\n'))
    ok_n = 0
    total = len(CASES) + 2
    tmp = tempfile.mkdtemp(prefix='procguard-selftest-')
    try:
        for name, expect, body in CASES:
            d = os.path.join(tmp, name)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, 'sample.sh'), 'w') as f:
                f.write(body)
            r = analyze_tree(d, min_files=1)
            got = r['result']
            good = (got == expect)
            ok_n += 1 if good else 0
            codes = ','.join(sorted({h[5] for h in r['hits']})) or '-'
            print('CASE=%s expect=%s got=%s codes=%s ⇒ %s'
                  % (name, expect, got, codes, 'OK' if good else 'NG'))
            if not good:
                report(r)
        # ⑨ 恒 0 守卫：空树 ⇒ NOINFO
        d = os.path.join(tmp, 'noinfo-empty-tree')
        os.makedirs(d, exist_ok=True)
        r = analyze_tree(d, min_files=1)
        good = (r['result'] == 'NOINFO')
        ok_n += 1 if good else 0
        print('CASE=noinfo-empty-tree expect=NOINFO got=%s ⇒ %s' % (r['result'], 'OK' if good else 'NG'))
        # ⑩ 牙自己不许用 pkill/pgrep（自扫本件）
        r2 = analyze_tree(os.path.dirname(SELF), min_files=1)
        own = [h for h in r2['hits'] if os.path.basename(h[0]) == os.path.basename(SELF)]
        ok_n += 1 if not own else 0
        print('CASE=selfcheck-no-pkill expect=PASS got=%s ⇒ %s'
              % ('PASS' if not own else 'FAIL', 'OK' if not own else 'NG'))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    print('PROCGUARD_SELFTEST=%d/%d' % (ok_n, total))
    sys.exit(0 if ok_n == total else 1)
PYEOF
rc=$?
exit $rc

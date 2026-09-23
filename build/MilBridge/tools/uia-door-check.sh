#!/usr/bin/env bash
# uia-door-check.sh —— 「UIA 的门在不在、门后有没有断头」的机器牙（**纯读、零 `dotnet`、秒级**）
# ═══════════════════════════════════════════════════════════════════════════════
# 【它防什么】缺陷册 `D-G75`（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2297`）：
#   UIA 的托管/上游实现**真的编进来了**（`UIAutomationProvider` 33 条 `Compile`／31 条上游真源码），
#   但**没有任何生产者把门打开**：`WM_GETOBJECT` 在本移植里**只被消费、从不被生产** ⇒
#   **辅助功能在 Linux 上静默不可用**；而"真要敲门"时门后**还是断的**（9 条 provider P/Invoke
#   指向 `UIAutomationCore.dll`，该名在 `build/shims/` **0 命中**、`nm -D` 里 `Uia*` 符号 **0**）。
#   口径必须以 `docs/CURRENT-STATE.md` 的 `D-U1` 更正行为准：**"无门/断头"，不是"零调用者"**
#   （provider 那 8 条**有活调用点**，只是静态不可达）。
#
# 【它是什么】`D-G75` 的"最小第一步 A"（W72A 报告 §5）里**未落地**的那半：
#   把"无门"做成**会变红的仪器**。⇒ 本件在**现树上必须 `FAIL`** —— **这是设计**
#   （门不存在 ⇒ 红就是红），**不许**把它写成 `NOINFO`（`NOINFO` 只给"真查不动"）。
#   门一旦装上（生产者 ＋ 映射 ＋ **真导出**）⇒ 必须 `PASS`；装上再拆掉 ⇒ **必须回到红**。
#
# 【判据（三态）】**0 = PASS**（五个静态条件全齐）｜**1 = FAIL**（逐条点名缺哪个）｜
#   **2 = NOINFO**（**算不出来 ⇒ 绝不是绿**）。
#   PASS ⟺ `prod≥1 ∧ consume≥1 ∧ core_shim≥1 ∧ uia_syms≥1 ∧ live_calls_own≥1`
#     · `prod`        自有代码里 `WM_GETOBJECT` 的**发送形状**出现数（**门的生产者**）
#     · `consume`     自有代码里 `case … WM_GETOBJECT` 的条数（**应门人**）
#     · `core_shim`   `build/shims/**` 里字面量 `"UIAutomationCore.dll"`（**库有没有被映射**）
#     · `uia_syms`    声明的 shim 库里 `nm -D --defined-only | ' T Uia'`（**库有没有那个导出**）
#     · `live_calls_own` 自有代码里 UIA provider 面的**活调用点**（门后**有没有路**）
#   FAIL 逐条：`no-producer`｜`no-consumer`｜`head-severed:core-shim=0`｜
#     `head-severed:uia-syms=0`｜`no-live-calls`（可多条同时成立，全印）。
#   NOINFO 触发面（逐条在代码里）：解释器缺、根缺、源覆盖面 0 件、`build/shims` 不在、
#     **候选 shim 库一个都找不到**（⇒ 谈不了"有没有导出"）、`nm` 缺、金丝雀失明、
#     扫描器非 0 退/写 stderr、件数或库数低于下限、`UIAD_ANCHORS=strict` 而锚件不在覆盖面、
#     `UIAD_TEST_BLIND=1`（只给自测）。这一族防 `D-R4`/`D-G84`「射程悄悄缩到零而它还是绿的」。
#
# 【正对照（必须同趟出，否则"0"与"grep 写错了"分不开）】
#   · `prod`/`consume` 之外另印 `automation_peer`（现场 **36**）⇒ 同一批扫描有效；
#   · `core_shim=0` 旁边印 `core_control`（同目录 `"user32.dll"`，现场非 0）；
#   · `uia_syms=0` 旁边印 `ctrl_syms`（**同一个库**里 `' T IsWindows10'`，现场 **8**）＋ `ctrl_total`（该库总导出）；
#   · `nm` 本身另用系统 `libc` 的 `' T malloc'` 自证（`nm_alive`）。
#
# 【金丝雀（**生产路径自己跑**，不是只跑在自测里）】每次真跑前在自己的 `TMPDIR` 里造夹具并要求：
#   ① 生产者检测器没瞎（合成 `SendMessage(h, WM_GETOBJECT, 0, 0);` ⇒ `prod≥1`）；
#   ② `case` 形态记 `consume`、`if (msg == WM_GETOBJECT)` 记 `other`（**不许**记成 `prod`）；
#   ③ **`build/MilBridge/**`（判据/报告/夹具的驻地）不参与判**：把同一句生产者放进
#      `build/MilBridge/Canary.Door.cs`（**判据内扩展名**）⇒ **必须不被计**；
#   ④ **`.md` 不参与判**：放进 `build/Canary.Doc.md` ⇒ **不许**被计，且必须在「没判的件」里**可见**；
#      —— ③④ 是本件的**自污染守卫**：不设它们，**本件自己的源与报告就会把读数翻过来**；
#   ⑤ 映射检测器没瞎（合成 `build/shims/` 里放 `"UIAutomationCore.dll"` ⇒ 必须数到）。
#   不符 ⇒ `NOINFO reason=canary-blind`。`UIAD_CANARY_BREAK=1` 只给自测（合成生产者弄干净 ⇒ 必须报失明）。
#
# 【覆盖面（"没查什么"写死）】判：`build/ src/ samples/` 下 `.cs .c .h .py .sh`，
#   **再排除 `build/MilBridge/**`**（③）与目录 `obj bin .artifacts __pycache__ .vs TestResults`；
#   **不判**：`upstream/**` 的**生产面**（vendored 镜像；只当 `live_calls` 的"路"来数）、
#   一切文档/报告（`.md` ⇒ ④）、非源扩展名（分类计数 ＋ `--list-notjudged` 可逐条列出）。
#   ⚠️ **保守面（如实声明）**：`prod` 只认**声明动词形状**（`UIAD_VERBS`）；将来若有人用别的形状造门，
#     该行会落 `other`（`UIA_DOOR_OTHER` 里点名）⇒ **仍红**。宁可红、不许假绿；真遇到时改一处声明。
#   ⚠️ **本件的绿 ≠ "无障碍可用"**：它只判"门/应门人/映射/导出/路"这五个**静态**条件。
#     "AT 真连上来能不能看见控件"要 AT-SPI2 桥 ＋ 外部 AT 进程 ⇒ `NOINFO`（配方在 W72A 报告 §7）。
#
# 【只读】生产路径**只读**；所有负极构造（装门/拆门/弄瞎）只在 `--selftest` 的沙箱里做。
# 【成本】单趟 ≈ 1–3 s、零 `dotnet`、零世代成本（不动九位/`GEN_KEYS`/`known-red.json`/不动被测树）。
#   ⚠️ 本件**不在** `build/close-wave.sh` 的 `fp_inputs()` 覆盖面里（机械核见 W121A 报告 §6）
#      ⇒ **新建本件不动 `inputs_fp`**；接线时若按"判据件必须看得见"的惯例纳入覆盖面，
#      那一改**会**动 `inputs_fp` ⇒ 必须安排在 `IN_FP_0` 采样**之前**。
#
# 用法：
#   uia-door-check.sh [--root DIR] [--list-notjudged] [--list-libs] [--debug-tmp]
#   uia-door-check.sh --selftest
# 环境（自测/沙箱/夹具用；生产不需要设）：
#   UIAD_ROOT / UIAD_PYTHON / UIAD_NM / UIAD_ANCHORS=strict|off / UIAD_MIN_SRC / UIAD_MIN_LIBS
#   UIAD_SO_DIRS / UIAD_SHIM_DIR / UIAD_TEST_BLIND / UIAD_CANARY_BREAK / UIAD_TMPDIR /
#   UIAD_KEEP_TMP / UIAD_CTRL_SO
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ⚠️ 必须**绝对**路径：`--selftest` 会 cd 进沙箱再以 `bash "$SELF"` 拉起子进程（相对路径在那里 rc=127）
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
REAL_ROOT="$(cd "$HERE/../../.." && pwd)"

ROOT="${UIAD_ROOT:-$REAL_ROOT}"
PYBIN="${UIAD_PYTHON:-python3}"
NMBIN="${UIAD_NM:-nm}"
ANCHORS="${UIAD_ANCHORS:-strict}"           # strict | off（off 只给 --selftest 的合成夹具用）
MIN_SRC="${UIAD_MIN_SRC:-240}"              # 被判源件数下限（现场 294 ⇒ 留 ~18% 余量；防"射程悄悄缩水"）
MIN_LIBS="${UIAD_MIN_LIBS:-1}"              # 候选 shim 库数下限
BLIND="${UIAD_TEST_BLIND:-0}"               # 只给 --selftest 用：故意弄瞎
CANARY_BREAK="${UIAD_CANARY_BREAK:-0}"      # 只给 --selftest 用：故意让金丝雀失效
KEEP_TMP="${UIAD_KEEP_TMP:-0}"
TMPBASE="${UIAD_TMPDIR:-${TMPDIR:-/tmp}}"
CTRL_SO="${UIAD_CTRL_SO:-}"
SO_DIRS="${UIAD_SO_DIRS:-src/WpfGfx.Linux.Native/bin}"
SHIM_DIR="${UIAD_SHIM_DIR:-build/shims}"
WANT_NOTJUDGED=0; WANT_LIBS=0

# ── 覆盖面声明（**唯一一份**；改这里 = 改判据 ⇒ 接线时必须安排在 `IN_FP_0` 采样之前）──────
UIAD_SRC_ROOTS='build src samples'
UIAD_SRC_EXTS='.cs .c .h .py .sh'
UIAD_SKIPDIRS='obj bin .artifacts __pycache__ .vs TestResults'
# **自污染守卫**：判据/报告/夹具的驻地整棵不判（见头注 ③）。理由不是"洁癖"：
#   本件自己就是 `.sh`，而它的金丝雀夹具里**逐字含** `SendMessage(h, WM_GETOBJECT, …)`
#   ⇒ 不排除 ⇒ 本件**给自己造了一个生产者** ⇒ `prod` 假 ≥1（这正是本仓"仪器读到自己"那一家族）。
UIAD_SKIP_PREFIXES='build/MilBridge'
# 「路」的覆盖面（只数 live_calls）：编译进来的上游真源码（W72A 报告 §2.1 的三处宿主）
UIAD_PATH_ROOTS='upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore
                 upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework
                 upstream/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider'
UIAD_PATH_EXTS='.cs'
# 生产者形状的**声明动词**（`WM_GETOBJECT` 必须是这些调用的**实参**）
UIAD_VERBS='SendMessage|SendMessageTimeout|SendMessageW|PostMessage|PostMessageW|SendNotifyMessage|push_message|post_message|send_message|push|post|emit|raise|dispatch|notify'
# provider 面的活调用点形状（`live_calls`）
UIAD_LIVE_PAT='AutomationInteropProvider\.[A-Za-z_]+|AutomationProvider\.[A-Za-z_]+\(|UiaReturnRawElementProvider|UiaHostProviderFromHwnd|UiaRaiseAutomationPropertyChangedEvent|UiaRaiseAutomationEvent|UiaRaiseStructureChangedEvent|UiaRaiseAsyncContentLoadedEvent|UiaRaiseNotificationEvent|UiaRaiseActiveTextPositionChangedEvent|UiaClientsAreListening'
# 锚（`strict` 模式要求的**仓内专有**件；别的树用 `UIAD_ANCHORS=off`）
UIAD_ANCHORS_LIST='build/PresentationCore.Linux/HwndTarget.Linux.cs
                   build/shims/Win32ShimResolver.cs
                   upstream/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/MS/Internal/Automation/UiaCoreProviderApi.cs'
# 压成单行（bash 把换行当分隔符；压平后传 argv 更稳、打印也更整齐）
UIAD_PATH_ROOTS="$(printf '%s' "$UIAD_PATH_ROOTS" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"
UIAD_ANCHORS_LIST="$(printf '%s' "$UIAD_ANCHORS_LIST" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"
UIAD_SKIP_PREFIXES="$(printf '%s' "$UIAD_SKIP_PREFIXES" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"

say() { printf '%s\n' "$*"; }
self_sha16() { sha256sum "$SELF" | cut -c1-16; }
first_line_of_file() { sed -n '1p' "$1" 2>/dev/null; }
usage() {
  cat <<'USAGE'
uia-door-check.sh —— 「UIA 的门在不在、门后有没有断头」的机器牙（D-G75）
  uia-door-check.sh [--root DIR] [--list-notjudged] [--list-libs] [--debug-tmp]
  uia-door-check.sh --selftest
三态：rc=0 PASS（门＋应门人＋映射＋导出＋路 五条全齐）／
      rc=1 FAIL（逐条点名缺哪个；**现树上就该是这个**）／rc=2 NOINFO（**不是绿**）
USAGE
}

# ── 扫描器（python3；**只报事实、不定态**：状态与 rc 由 bash 决定）────────────────────
py_scan() {   # $1=root $2=out.tsv $3=py.err
  local root="$1" out="$2" errf="$3"
  : > "$out"; : > "$errf"
  UIAD_NOTJUDGED_OUT="$4" "$PYBIN" - "$root" "$UIAD_SRC_ROOTS" "$UIAD_SRC_EXTS" "$UIAD_SKIPDIRS" \
           "$UIAD_SKIP_PREFIXES" "$UIAD_PATH_ROOTS" "$UIAD_PATH_EXTS" "$UIAD_VERBS" \
           "$UIAD_LIVE_PAT" "$SHIM_DIR" "$UIAD_ANCHORS_LIST" "$BLIND" > "$out" 2> "$errf" <<'PY_UIAD'
import os, re, sys

(root, src_roots, src_exts, skipdirs, skip_prefixes, path_roots, path_exts, verbs,
 live_pat, shim_dir, anchors, blind) = sys.argv[1:13]

src_roots  = [r for r in src_roots.split() if r]
src_exts   = {e.lower() for e in src_exts.split()}
skipdirs   = set(skipdirs.split())
skip_prefixes = [p for p in skip_prefixes.split() if p]
path_roots = [r for r in path_roots.split() if r]
path_exts  = {e.lower() for e in path_exts.split()}
shim_dir   = shim_dir.strip()
anchors    = [a for a in anchors.split() if a]
blind      = blind == '1'

BINEXTS = {'.so', '.dll', '.a', '.o', '.obj', '.pyc', '.png', '.jpg', '.ico', '.gif', '.webp',
           '.ttf', '.otf', '.woff', '.woff2', '.snk', '.nupkg', '.zip', '.gz', '.pdf', '.bin',
           '.dat', '.db', '.wav', '.mp4', '.wasm', '.xwd', '.exe', '.pdb', '.class', '.jar'}

SEND_RE = re.compile(r'\b(?:' + verbs + r')[A-Za-z0-9_]*\s*\(')
CASE_RE = re.compile(r'\bcase\b[^;]*WM_GETOBJECT|WM_GETOBJECT\s*:')
DEF_RE  = re.compile(r'^\s*#\s*define\b.*WM_GETOBJECT|\b(?:const|readonly|static)\b[^;=]*=[^;]*WM_GETOBJECT')
LIVE_RE = re.compile(live_pat)
PEER_RE = re.compile(r'AutomationPeer')

def emit(tag, *rest):
    sys.stdout.write('\t'.join([tag] + [str(x) for x in rest]) + '\n')

NJF = None
_nj = os.environ.get('UIAD_NOTJUDGED_OUT') or ''
if _nj:
    try:
        NJF = open(_nj, 'w')
    except OSError:
        NJF = None

def notjudged(kind, rel):
    emit('NOTJUDGED', kind, rel)
    if NJF:
        NJF.write('%s\t%s\n' % (kind, rel))

def skipped(rel):
    for p in skip_prefixes:
        if rel == p or rel.startswith(p + '/'):
            return True
    return False

def cut_comment(line):
    s = line.lstrip()
    if s.startswith('//') or s.startswith('*') or s.startswith('/*'):
        return ''
    i = line.find('//')
    if i >= 0 and (i == 0 or line[i-1] in ' \t;,)}'):
        return line[:i]
    return line

def classify(line, m):
    """一处 WM_GETOBJECT 出现的分类：comment / consume / prod / define / other。"""
    if not cut_comment(line).strip():
        return 'comment', ''
    if CASE_RE.search(line):
        return 'consume', ''
    eff = cut_comment(line)
    if m.start() >= len(eff):
        return 'comment', ''
    for sm in SEND_RE.finditer(eff):
        if sm.start() < m.start():
            return 'prod', eff[sm.start():sm.start()+40].split('(')[0]
    if DEF_RE.search(line):
        return 'define', ''
    return 'other', ''

n_prod = n_cons = n_def = n_other = n_comm = n_md = 0
n_live = n_live_own = n_peer = 0
files_src = files_path = 0
class_n = {'doc': 0, 'binext': 0, 'noext': 0, 'otherext': 0}
other_ext = {}
skipdirs_n = 0
have = {a: 0 for a in anchors}

def look(path, rel, judged):
    global n_prod, n_cons, n_def, n_other, n_comm, n_md
    try:
        fh = open(path, 'r', encoding='utf-8', errors='replace')
    except OSError as e:
        emit('ERR', rel, str(e))
        return
    with fh:
        for ln, line in enumerate(fh, 1):
            if 'WM_GETOBJECT' not in line:
                continue
            if not judged:
                n_md += 1                     # **只看见、不判**（自污染守卫 ④）
                continue
            for m in re.finditer('WM_GETOBJECT', line):
                k, extra = classify(line, m)
                txt = line.strip()[:150]
                if k == 'prod':
                    n_prod += 1; emit('PROD', rel, ln, extra + ' :: ' + txt)
                elif k == 'consume':
                    n_cons += 1; emit('CONS', rel, ln, txt)
                elif k == 'define':
                    n_def += 1; emit('DEF', rel, ln, txt)
                elif k == 'comment':
                    n_comm += 1
                else:
                    n_other += 1; emit('OTHER', rel, ln, txt)
                break

def walk_src():
    global files_src, skipdirs_n
    for r in src_roots:
        base = os.path.join(root, r)
        if not os.path.isdir(base):
            continue
        for dirpath, dirs, fs in os.walk(base):
            for d in sorted(x for x in dirs if x in skipdirs):
                rel = os.path.relpath(os.path.join(dirpath, d), root)
                if not skipped(rel):
                    emit('SKIPDIR', rel); skipdirs_n += 1
            dirs[:] = sorted(x for x in dirs
                             if x not in skipdirs
                             and not skipped(os.path.relpath(os.path.join(dirpath, x), root)))
            for f in sorted(fs):
                p = os.path.join(dirpath, f)
                rel = os.path.relpath(p, root)
                if rel in have:
                    have[rel] = 1
                ext = os.path.splitext(f)[1].lower()
                if ext in src_exts:
                    files_src += 1
                    if not blind:
                        look(p, rel, True)
                    continue
                # ── 没判的件：**分类计数 ＋ 点名**（`D-G84`：看不见 ≠ 没发生）──
                if ext == '.md':
                    class_n['doc'] += 1; notjudged('doc', rel)
                    if not blind:
                        look(p, rel, False)
                elif ext == '':
                    class_n['noext'] += 1; notjudged('noext', rel)
                elif ext in BINEXTS:
                    class_n['binext'] += 1; notjudged('binext', rel)
                else:
                    class_n['otherext'] += 1; notjudged('otherext', rel)
                    other_ext[ext] = other_ext.get(ext, 0) + 1

walk_src()

# ── `live_calls`：自有代码 ＋ 编译进来的上游源（**只数路**，与门无关）──────────────────
def walk_live():
    global n_live, n_live_own, files_path
    src_set = set(src_roots)
    for r in src_roots + path_roots:
        base = os.path.join(root, r)
        if not os.path.isdir(base):
            continue
        own = r in src_set
        for dirpath, dirs, fs in os.walk(base):
            dirs[:] = sorted(x for x in dirs
                             if x not in skipdirs
                             and not skipped(os.path.relpath(os.path.join(dirpath, x), root)))
            for f in sorted(fs):
                ext = os.path.splitext(f)[1].lower()
                if ext not in (src_exts | path_exts):
                    continue
                rel = os.path.relpath(os.path.join(dirpath, f), root)
                if not own:
                    files_path += 1
                if blind:
                    continue
                try:
                    fh = open(os.path.join(dirpath, f), 'r', encoding='utf-8', errors='replace')
                except OSError:
                    continue
                with fh:
                    for ln, line in enumerate(fh, 1):
                        eff = cut_comment(line)
                        if not eff.strip():
                            continue
                        if not LIVE_RE.search(eff):
                            continue
                        n_live += 1
                        if own:
                            n_live_own += 1
                        if n_live <= 40:
                            emit('LIVE', ('own' if own else 'up'), rel, ln, eff.strip()[:130])

walk_live()

# ── 正对照：同一批件里 `AutomationPeer` 的出现数（证明本扫描器有效）──────────────────
def count_peer():
    global n_peer
    for r in src_roots:
        base = os.path.join(root, r)
        if not os.path.isdir(base):
            continue
        for dirpath, dirs, fs in os.walk(base):
            dirs[:] = sorted(x for x in dirs
                             if x not in skipdirs
                             and not skipped(os.path.relpath(os.path.join(dirpath, x), root)))
            for f in sorted(fs):
                if os.path.splitext(f)[1].lower() not in src_exts:
                    continue
                try:
                    txt = open(os.path.join(dirpath, f), 'r', encoding='utf-8', errors='replace').read()
                except OSError:
                    continue
                n_peer += len(PEER_RE.findall(txt))

count_peer()

# ── `core_shim`：`build/shims/**` 里的库名字面量（**全文件、任何扩展名**）──────────────
core_shim = core_ctrl = core_any = 0
shim_files = 0
sd = os.path.join(root, shim_dir)
if os.path.isdir(sd):
    for dirpath, dirs, fs in os.walk(sd):
        dirs[:] = sorted(x for x in dirs if x not in skipdirs)
        for f in sorted(fs):
            p = os.path.join(dirpath, f)
            try:
                txt = open(p, 'r', encoding='utf-8', errors='replace').read()
            except OSError:
                continue
            shim_files += 1
            c = txt.count('"UIAutomationCore.dll"')
            core_shim += c
            core_any += txt.count('UIAutomationCore')
            core_ctrl += txt.count('"user32.dll"')
            if c:
                emit('SHIMMAP', os.path.relpath(p, root), c)

if blind:
    n_prod = n_cons = n_def = n_other = n_comm = n_live = n_live_own = n_peer = 0
    core_shim = core_ctrl = core_any = n_md = 0

emit('K', 'blind', 1 if blind else 0)
emit('K', 'files_src', files_src)
emit('K', 'files_path', files_path)
emit('K', 'prod', n_prod)
emit('K', 'consume', n_cons)
emit('K', 'define', n_def)
emit('K', 'other', n_other)
emit('K', 'comment', n_comm)
emit('K', 'md_hits', n_md)
emit('K', 'live_calls', n_live)
emit('K', 'live_calls_own', n_live_own)
emit('K', 'core_shim', core_shim)
emit('K', 'core_control', core_ctrl)
emit('K', 'core_any', core_any)
emit('K', 'shim_files', shim_files)
emit('K', 'shim_dir_present', 1 if os.path.isdir(sd) else 0)
emit('K', 'automation_peer', n_peer)
emit('K', 'skipdirs', skipdirs_n)
for k in sorted(class_n):
    emit('NOTJUDGED_N', k, class_n[k])
for k in sorted(other_ext):
    emit('OTHEREXT', k, other_ext[k])
# 锚的在场判定 = **件存在**（锚里有一件在 `upstream/**`，它不在被判根里 ⇒ 不能只靠 roster）
for a in anchors:
    emit('HAVE', a, 1 if os.path.isfile(os.path.join(root, a)) else 0)
if NJF:
    NJF.close()
PY_UIAD
}

# ── 解析 TSV（**while-read 吃文件**，不走管道 ⇒ 不碰 pipefail/SIGPIPE 那族坑）───────────
parse_scan() {
  P_PROD=0; P_CONS=0; P_DEF=0; P_OTHER=0; P_COMM=0; P_MD=0
  P_LIVE=0; P_LIVEOWN=0; P_CORE=0; P_CORECTRL=0; P_COREANY=0; P_SHIMFILES=0; P_SHIMDIR=0
  P_FSRC=0; P_FPATH=0; P_PEER=0; P_BLIND=0; P_SKIPDIRS=0
  P_DOC=0; P_BINEXT=0; P_NOEXT=0; P_OTHEREXT=0; P_OTHEREXTLIST=''
  P_PRODROWS=''; P_CONSROWS=''; P_OTHERROWS=''; P_LIVEROWS=''; P_ERRROWS=''; P_ANCHORS=''
  local tag a b c d
  while IFS=$'\t' read -r tag a b c d; do
    case "$tag" in
      K) case "$a" in
           blind) P_BLIND="$b";; files_src) P_FSRC="$b";; files_path) P_FPATH="$b";;
           prod) P_PROD="$b";; consume) P_CONS="$b";; define) P_DEF="$b";;
           other) P_OTHER="$b";; comment) P_COMM="$b";; md_hits) P_MD="$b";;
           live_calls) P_LIVE="$b";; live_calls_own) P_LIVEOWN="$b";;
           core_shim) P_CORE="$b";; core_control) P_CORECTRL="$b";; core_any) P_COREANY="$b";;
           shim_files) P_SHIMFILES="$b";; shim_dir_present) P_SHIMDIR="$b";;
           automation_peer) P_PEER="$b";; skipdirs) P_SKIPDIRS="$b";;
         esac;;
      NOTJUDGED_N) case "$a" in doc) P_DOC="$b";; binext) P_BINEXT="$b";;
                     noext) P_NOEXT="$b";; otherext) P_OTHEREXT="$b";; esac;;
      OTHEREXT) P_OTHEREXTLIST="${P_OTHEREXTLIST}${a}=${b} ";;
      PROD) P_PRODROWS="${P_PRODROWS}${a}|${b}|${c}"$'\n';;
      CONS) P_CONSROWS="${P_CONSROWS}${a}|${b}|${c}"$'\n';;
      OTHER) P_OTHERROWS="${P_OTHERROWS}${a}|${b}|${c}"$'\n';;
      LIVE) P_LIVEROWS="${P_LIVEROWS}${a}|${b}|${c}|${d}"$'\n';;
      ERR) P_ERRROWS="${P_ERRROWS}${a}|${b}"$'\n';;
      HAVE) P_ANCHORS="${P_ANCHORS}${a}=${b} ";;
    esac
  done < "$1"
}

emit_scope() {
  local n_ext n_skip
  n_ext=$(printf '%s\n' $UIAD_SRC_EXTS | sed -n '$=')
  n_skip=$(printf '%s\n' $UIAD_SKIPDIRS | sed -n '$=')
  say "UIA_DOOR_SCOPE roots=[$UIAD_SRC_ROOTS] exts=$n_ext skipdirs=$n_skip skiplocal=[$UIAD_SKIP_PREFIXES] path_roots=[$UIAD_PATH_ROOTS] so_dirs=[$SO_DIRS] shim_dir=$SHIM_DIR root=$ROOT anchors=$ANCHORS min_src=$MIN_SRC min_libs=$MIN_LIBS"
  say "UIA_DOOR_SCOPE_EXTS $UIAD_SRC_EXTS"
  say "UIA_DOOR_SCOPE_SKIPDIRS $UIAD_SKIPDIRS"
  say "UIA_DOOR_SCOPE_SKIPPREFIX $UIAD_SKIP_PREFIXES（判据/报告/夹具驻地，**不判**：自污染守卫）"
  say "UIA_DOOR_SCOPE_VERBS $UIAD_VERBS"
  say "UIA_DOOR_SCOPE_LIVEPAT $UIAD_LIVE_PAT"
}

# ── 候选 shim 库的符号读数（`nm -D`）─────────────────────────────────────────────
nm_scan() {   # $1=libs 文件（每行一个绝对路径）⇒ 写全局 NM_*
  NM_UIA=0; NM_CTRL=0; NM_TOTAL=0; NM_UIAANY=0; NM_LIBS=0; NM_ROWS=''; NM_ERR=''
  local lib out
  while IFS= read -r lib; do
    [ -n "$lib" ] || continue
    NM_LIBS=$((NM_LIBS + 1))
    if ! out="$("$NMBIN" -D --defined-only "$lib" 2>&1)"; then
      NM_ERR="${NM_ERR}${lib}:nm-rc!=0; "
      continue
    fi
    local u c t a
    u=$(printf '%s\n' "$out" | grep -c ' T Uia' || true)
    c=$(printf '%s\n' "$out" | grep -c ' T IsWindows10' || true)
    t=$(printf '%s\n' "$out" | grep -c ' T ' || true)
    a=$(printf '%s\n' "$out" | grep -c 'Uia' || true)
    NM_UIA=$((NM_UIA + u)); NM_CTRL=$((NM_CTRL + c))
    NM_TOTAL=$((NM_TOTAL + t)); NM_UIAANY=$((NM_UIAANY + a))
    NM_ROWS="${NM_ROWS}${lib}|${u}|${c}|${t}|${a}"$'\n'
  done < "$1"
}

# `nm` 本身的自证：系统 libc 里必须能数到 `' T malloc'`（与"nm 存在"分开证）
nm_alive() {
  local cand="${CTRL_SO:-}" p
  if [ -z "$cand" ]; then
    for p in /lib/x86_64-linux-gnu/libc.so.6 /usr/lib/x86_64-linux-gnu/libc.so.6 \
             /lib64/libc.so.6 /usr/lib64/libc.so.6 /lib/aarch64-linux-gnu/libc.so.6; do
      [ -f "$p" ] && { cand="$p"; break; }
    done
  fi
  NM_ALIVE_SO="$cand"; NM_ALIVE=1; NM_ALIVE_N=0
  if [ -z "$cand" ] || [ ! -f "$cand" ]; then NM_ALIVE=-1; return; fi
  NM_ALIVE_N="$("$NMBIN" -D --defined-only "$cand" 2>/dev/null | grep -c ' T malloc' || true)"
  [ "${NM_ALIVE_N:-0}" -ge 1 ] || NM_ALIVE=0
}

# ── 金丝雀夹具（**生产路径自带**）───────────────────────────────────────────────
build_canary() {   # $1=canary 根
  local c="$1"
  rm -rf "$c"
  mkdir -p "$c/build/shims" "$c/build/PresentationCore.Linux" "$c/build/MilBridge"
  # ① 生产者形状（合格）＋ ② `case`（consume）＋ ② `if (…)`（other，**不许**算 prod）
  if [ "$CANARY_BREAK" = 1 ]; then
    printf '// no producer here\nint door(void) { return 0; }\n' \
      > "$c/build/PresentationCore.Linux/Canary.Door.cs"
  else
    printf 'void door(IntPtr h) {\n    SendMessage(h, WindowMessage.WM_GETOBJECT, IntPtr.Zero, IntPtr.Zero);\n}\n' \
      > "$c/build/PresentationCore.Linux/Canary.Door.cs"
  fi
  printf 'switch (msg) {\n    case WindowMessage.WM_GETOBJECT:\n        return Probe();\n}\n' \
    > "$c/build/PresentationCore.Linux/Canary.Consumer.cs"
  printf 'if (msg == WM_GETOBJECT) { handled = true; }\n' \
    > "$c/build/PresentationCore.Linux/Canary.Other.cs"
  # ③ 自污染守卫 a：判据内扩展名，但住在 `build/MilBridge/` ⇒ **不许**被计
  printf 'void door(IntPtr h) {\n    SendMessage(h, WindowMessage.WM_GETOBJECT, IntPtr.Zero, IntPtr.Zero);\n}\n' \
    > "$c/build/MilBridge/Canary.Door.cs"
  # ③ 自污染守卫 b：`.md`（判据外扩展名）⇒ **不许**被计，但必须**可见**
  printf '# fake report\nSendMessage(h, WM_GETOBJECT, 0, 0);\n' \
    > "$c/build/Canary.Doc.md"
  # ④ 映射检测器（合格）
  printf '        { "UIAutomationCore.dll", new[] { "user32" } },\n        { "user32.dll", null },\n' \
    > "$c/build/shims/Win32ShimResolver.cs"
}

cleanup_tmp() { [ "$KEEP_TMP" = 1 ] || rm -rf "$T"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 生产路径
# ═══════════════════════════════════════════════════════════════════════════════
main_run() {
  emit_scope
  if ! command -v "$PYBIN" >/dev/null 2>&1; then
    say "UIA_DOOR_SELF path=$SELF sha16=$(self_sha16)"
    say "UIA_DOOR=NOINFO reason=python-missing py=$PYBIN"; return 2
  fi
  if [ ! -d "$ROOT" ]; then
    say "UIA_DOOR=NOINFO reason=root-missing root=$ROOT"; return 2
  fi
  T="$(mktemp -d "$TMPBASE/uiad-run.XXXXXX")" || { say 'UIA_DOOR=NOINFO reason=mktemp-failed'; return 2; }
  trap cleanup_tmp EXIT
  say "UIA_DOOR_TMPDIR=$T"

  # ① 金丝雀（先证明检测器没瞎，再信它的 0 读数）
  build_canary "$T/canary"
  py_scan "$T/canary" "$T/can.tsv" "$T/can.err" ''; local can_rc=$?
  parse_scan "$T/can.tsv"
  local CAN_PROD="$P_PROD" CAN_CONS="$P_CONS" CAN_OTHER="$P_OTHER" CAN_MD="$P_MD"
  local CAN_CORE="$P_CORE" CAN_DOC="$P_DOC"
  local can_reason=''
  if [ "$can_rc" != 0 ] || [ -s "$T/can.err" ]; then can_reason="canary-scanner-error rc=$can_rc err=$(first_line_of_file "$T/can.err")"
  elif [ "$CAN_PROD" -ne 1 ]; then can_reason="prod=$CAN_PROD want=1（判据内的那一份必须被数到、且守卫③a 那一份必须**不被**数到）"
  elif [ "$CAN_CONS" -lt 1 ]; then can_reason="consume=$CAN_CONS want>=1（case 形态没认出来）"
  elif [ "$CAN_OTHER" -lt 1 ]; then can_reason="other=$CAN_OTHER want>=1（if 形态没被归到 other）"
  elif [ "$CAN_CORE" -lt 1 ]; then can_reason="core_shim=$CAN_CORE want>=1（映射检测器失明）"
  elif [ "$CAN_MD" -lt 1 ]; then can_reason="md_hits=$CAN_MD want>=1（文档里的同名串**必须看得见**）"
  elif [ "$CAN_DOC" -lt 1 ]; then can_reason="doc=$CAN_DOC want>=1（.md 必须在「没判的件」里可见）"
  fi

  # ② 真扫
  py_scan "$ROOT" "$T/scan.tsv" "$T/py.err" "$T/notjudged.txt"; local py_rc=$?
  parse_scan "$T/scan.tsv"
  local py_err_log=''
  [ -s "$T/py.err" ] && py_err_log="$(first_line_of_file "$T/py.err")"

  # ③ 候选 shim 库 + `nm`
  : > "$T/libs.txt"
  local d
  for d in $SO_DIRS; do
    [ -d "$ROOT/$d" ] && find "$ROOT/$d" -maxdepth 1 -name '*.so' -type f 2>/dev/null >> "$T/libs.txt"
  done
  [ -d "$ROOT/$SHIM_DIR" ] && find "$ROOT/$SHIM_DIR" -maxdepth 1 -name '*.so' -type f 2>/dev/null >> "$T/libs.txt"
  LC_ALL=C sort -u -o "$T/libs.txt" "$T/libs.txt"
  local NLIBS; NLIBS=$(wc -l < "$T/libs.txt")
  local nm_reason=''
  NM_UIA=0; NM_CTRL=0; NM_TOTAL=0; NM_UIAANY=0; NM_LIBS=0; NM_ROWS=''; NM_ERR=''
  NM_ALIVE=1; NM_ALIVE_N=0; NM_ALIVE_SO=''
  if [ "$NLIBS" -gt 0 ]; then
    if ! command -v "$NMBIN" >/dev/null 2>&1; then
      nm_reason="nm-missing nm=$NMBIN"
    else
      nm_scan "$T/libs.txt"
      nm_alive
      # 安全阀：**只在库总导出非 0** 时才用 `ctrl_syms` 判"nm 口径"（空库/合成 stub 不算）
      if [ "$NM_TOTAL" -gt 0 ] && [ "$NM_CTRL" -eq 0 ]; then
        nm_reason="nm-control-zero（库里有 $NM_TOTAL 个导出，但同库正对照 ' T IsWindows10' = 0 ⇒ nm 口径可疑）"
      fi
    fi
  fi

  # ④ 定态（顺序 = 具体的 NOINFO 原因优先；最后才允许 PASS/FAIL）
  local STATE=PASS RC=0 REASON=''
  if [ "$py_rc" != 0 ] || [ -n "$py_err_log" ]; then
    STATE=NOINFO; REASON="scanner-error py_rc=$py_rc py_err=$py_err_log"
  elif [ "$P_BLIND" = 1 ]; then
    STATE=NOINFO; REASON='scanner-blinded（UIAD_TEST_BLIND=1 ⇒ 扫描器不读内容 ⇒ 读数无信息）'
  elif [ -n "$can_reason" ]; then
    STATE=NOINFO; REASON="canary-blind（内置金丝雀不符：$can_reason）"
  elif [ "$P_SHIMDIR" != 1 ]; then
    STATE=NOINFO; REASON="no-shim-dir（$SHIM_DIR 不在 ⇒ 映射面**量不了**）"
  elif [ "$P_FSRC" -eq 0 ]; then
    STATE=NOINFO; REASON='empty-roster（源覆盖面 0 件 ⇒ 不是"没门"，是"没测"）'
  elif [ "$P_FSRC" -lt "$MIN_SRC" ]; then
    STATE=NOINFO; REASON="too-few-files files_src=$P_FSRC min=$MIN_SRC"
  elif [ -n "$nm_reason" ]; then
    STATE=NOINFO; REASON="$nm_reason"
  elif [ "$NLIBS" -eq 0 ]; then
    STATE=NOINFO; REASON="no-shim-lib-found（候选 shim 库一个都没有 ⇒ 谈不了'有没有导出'）dirs=[$SO_DIRS]"
  elif [ "$NLIBS" -lt "$MIN_LIBS" ]; then
    STATE=NOINFO; REASON="too-few-libs libs=$NLIBS min=$MIN_LIBS"
  elif [ "$NM_ALIVE" = 0 ]; then
    STATE=NOINFO; REASON="nm-blind（系统对照 $NM_ALIVE_SO 里 ' T malloc' = 0 ⇒ nm 本路口径可疑）"
  elif [ "$ANCHORS" = strict ]; then
    case "$P_ANCHORS" in
      *'=0'*) STATE=NOINFO; REASON="anchor-missing（射程缩水 ⇒ 不许绿）anchors=[${P_ANCHORS% }]";;
    esac
    if [ "$STATE" = PASS ] && [ "$P_FPATH" -eq 0 ]; then
      STATE=NOINFO; REASON='path-roster-empty（连上游三处"路"都没数到一件 ⇒ 射程缩水）'
    fi
  fi

  # ⑤ 判据本体（五个静态条件；逐条点名）
  local FAILS=''
  if [ "$STATE" = PASS ]; then
    [ "${P_PROD:-0}" -ge 1 ] || FAILS="${FAILS}no-producer "
    [ "${P_CONS:-0}" -ge 1 ] || FAILS="${FAILS}no-consumer "
    [ "${P_CORE:-0}" -ge 1 ] || FAILS="${FAILS}head-severed:core-shim=0 "
    [ "${NM_UIA:-0}" -ge 1 ] || FAILS="${FAILS}head-severed:uia-syms=0 "
    [ "${P_LIVEOWN:-0}" -ge 1 ] || FAILS="${FAILS}no-live-calls "
    [ -n "$FAILS" ] && STATE=FAIL
  fi

  # ⑥ 机读行 + 逐条依据
  say "UIA_DOOR_ROSTER files_src=$P_FSRC files_path=$P_FPATH docs=$P_DOC binext=$P_BINEXT noext=$P_NOEXT otherext=$P_OTHEREXT skipdirs=$P_SKIPDIRS shim_files=$P_SHIMFILES"
  say "UIA_DOOR_OTHEREXT ${P_OTHEREXTLIST% }"
  say "UIA_DOOR_CTRL automation_peer=$P_PEER core_control=\"user32.dll\"=$P_CORECTRL core_any=$P_COREANY md_hits=$P_MD nm_alive=${NM_ALIVE}/${NM_ALIVE_N} ctrl_total=$NM_TOTAL"
  if [ -z "$can_reason" ]; then
    say "UIA_DOOR_CANARY=ok prod=$CAN_PROD consume=$CAN_CONS other=$CAN_OTHER md_hits=$CAN_MD core_shim=$CAN_CORE doc=$CAN_DOC"
  else
    say "UIA_DOOR_CANARY=BLIND reason=$can_reason"
  fi
  local row rest rest2 p ln tx site
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    p="${row%%|*}"; rest="${row#*|}"; ln="${rest%%|*}"; tx="${rest#*|}"
    say "UIA_DOOR_PROD path=$p line=$ln detail=${tx//|/ }"
  done <<< "$P_PRODROWS"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    p="${row%%|*}"; rest="${row#*|}"; ln="${rest%%|*}"; tx="${rest#*|}"
    say "UIA_DOOR_CONSUME path=$p line=$ln detail=${tx//|/ }"
  done <<< "$P_CONSROWS"
  local n_show=0
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    n_show=$((n_show + 1))
    [ "$n_show" -le 12 ] || continue
    p="${row%%|*}"; rest="${row#*|}"; ln="${rest%%|*}"; tx="${rest#*|}"
    say "UIA_DOOR_OTHER path=$p line=$ln detail=${tx//|/ }"
  done <<< "$P_OTHERROWS"
  [ "$P_OTHER" -gt 12 ] && say "UIA_DOOR_OTHER_TRUNCATED printed=12 rest=$((P_OTHER - 12))"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    site="${row%%|*}"; rest="${row#*|}"; p="${rest%%|*}"; rest2="${rest#*|}"
    ln="${rest2%%|*}"; tx="${rest2#*|}"
    say "UIA_DOOR_LIVE site=$site path=$p line=$ln detail=${tx//|/ }"
  done <<< "$P_LIVEROWS"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    p="${row%%|*}"; rest="${row#*|}"; u="${rest%%|*}"; rest="${rest#*|}"
    c="${rest%%|*}"; rest="${rest#*|}"; t="${rest%%|*}"; a="${rest#*|}"
    say "UIA_DOOR_LIB path=$p uia_syms=$u ctrl_syms=$c ctrl_total=$t uia_any=$a"
  done <<< "$NM_ROWS"
  [ -n "$NM_ERR" ] && say "UIA_DOOR_NMERR $NM_ERR"
  local e
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    say "UIA_DOOR_SCANERR path=${e%%|*} reason=${e#*|}"
  done <<< "$P_ERRROWS"

  case "$STATE" in
    PASS) RC=0
      say "UIA_DOOR=PASS prod=$P_PROD consume=$P_CONS core_shim=$P_CORE uia_syms=$NM_UIA ctrl_syms=$NM_CTRL live_calls=$P_LIVEOWN (all=$P_LIVE) libs=$NLIBS";;
    FAIL) RC=1
      say "UIA_DOOR=FAIL prod=$P_PROD consume=$P_CONS core_shim=$P_CORE uia_syms=$NM_UIA ctrl_syms=$NM_CTRL live_calls=$P_LIVEOWN (all=$P_LIVE) libs=$NLIBS reason=[${FAILS% }]"
      say "UIA_DOOR_VERDICT=门不存在或缺件 ⇒ **辅助功能静默不可用**（D-G75）；**这是设计内的红**：接进门禁前必须先登记为在册红（见 W121A 报告 §5）";;
    *) RC=2
      say "UIA_DOOR=NOINFO reason=$REASON prod=$P_PROD consume=$P_CONS core_shim=$P_CORE uia_syms=$NM_UIA libs=$NLIBS";;
  esac
  say "UIA_DOOR_SELF path=$SELF sha16=$(self_sha16)"
  if [ "$WANT_NOTJUDGED" = 1 ]; then
    say "UIA_DOOR_NOTJUDGED_LIST_BEGIN n=$( [ -f "$T/notjudged.txt" ] && wc -l < "$T/notjudged.txt" || echo 0 )"
    cat "$T/notjudged.txt" 2>/dev/null
    say "UIA_DOOR_NOTJUDGED_LIST_END"
  fi
  if [ "$WANT_LIBS" = 1 ]; then
    say "UIA_DOOR_LIBS_LIST_BEGIN"
    cat "$T/libs.txt" 2>/dev/null
    say "UIA_DOOR_LIBS_LIST_END"
  fi
  return "$RC"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 自测（两极化；自带 TMPDIR；含「装门 ⇒ 绿」「拆门 ⇒ 回红」「弄瞎 ⇒ NOINFO」的成对读数）
# ═══════════════════════════════════════════════════════════════════════════════
run_selftest() {
  local inner="${UIAD_ST_INNER:-0}"
  if [ "$inner" != 1 ]; then
    # 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（NOINFO 收尾）
    local s0 s1 out rc
    s0="$(self_sha16)"
    say "ST_ATTEST=OPEN self=$SELF sha16=$s0"
    out="$(UIAD_ST_INNER=1 bash "$SELF" --selftest 2>&1)"; rc=$?
    printf '%s\n' "$out"
    s1="$(self_sha16)"
    if [ "$s1" != "$s0" ]; then
      say "ST_ATTEST=NOINFO reason=self-rewritten-during-selftest self=$SELF sha0=$s0 sha1=$s1 inner_rc=$rc"
      return 2
    fi
    say "ST_ATTEST=PASS self=$SELF sha16=$s0（自测期间本件未变 ⇒ 读数可归因）"
    return "$rc"
  fi
  if ! command -v "$PYBIN" >/dev/null 2>&1; then
    say "UIA_DOOR_SELFTEST=NOINFO reason=premise-unmet:python-missing py=$PYBIN"; return 2
  fi
  local SB
  SB="$(mktemp -d "$TMPBASE/uiad-selftest.XXXXXX")" || { say 'UIA_DOOR_SELFTEST=FAIL reason=mktemp-failed'; return 1; }
  mkdir -p "$SB/tmp"
  local pass=0 fail=0 total=0 nae=0
  local CUR_OUT='' CUR_RC='' CUR_STATE='' CUR_WANT=''

  run_case() {   # $1=id $2=want(0|1|2|LIVE) $3=tree [额外 env 赋值...]
    local id="$1" want="$2" tree="$3"; shift 3
    local -a envs=("UIAD_TMPDIR=$SB/tmp" "$@")
    CUR_WANT="$want"
    CUR_OUT="$(env "${envs[@]}" bash "$SELF" --root "$tree" 2>&1)"; CUR_RC=$?
    CUR_STATE="$(printf '%s\n' "$CUR_OUT" | sed -n 's/^UIA_DOOR=\([A-Z]*\) .*/\1/p' | sed -n '1p')"
    local ok='no' why=''
    if [ "$want" = LIVE ]; then
      case "$CUR_RC" in
        0) case "$CUR_OUT" in *'UIA_DOOR=PASS'*) ok=yes;; *) why='rc=0 但状态行不是 PASS';; esac;;
        # ⚠️ 现树**按设计是红的**：`LIVE` 例只要求"合法状态 ∧ 非 NOINFO ∧ 红时点名"
        1) case "$CUR_STATE" in FAIL) ok=yes;; *) why="rc=1 但 state=$CUR_STATE";; esac;;
        *) why="rc=$CUR_RC（生产路径不许异常/NOINFO）";;
      esac
      case "$CUR_OUT" in *'UIA_DOOR_CANARY=ok'*) ;; *) ok=no; why="$why canary!=ok";; esac
    else
      [ "$CUR_RC" = "$want" ] && ok=yes || why="rc=$CUR_RC want=$want"
    fi
    total=$((total + 1))
    if [ "$ok" = yes ]; then pass=$((pass + 1)); else
      fail=$((fail + 1))
      if [ "$want" != LIVE ] && [ "$CUR_RC" != "$want" ]; then nae=$((nae + 1)); fi
    fi
    printf 'SELFTEST CASE %-26s = %s rc=%s want=%s state=%s %s\n' \
           "$id" "$( [ "$ok" = yes ] && echo PASS || echo FAIL )" "$CUR_RC" "$want" \
           "${CUR_STATE:-none}" "$why"
  }
  has() { case "$CUR_OUT" in *"$1"*) HAS=1;; *) HAS=0;; esac; }
  assert() {
    total=$((total + 1))
    if [ "$2" = 1 ]; then pass=$((pass + 1)); printf 'SELFTEST ASSERT %-56s = PASS\n' "$1"
    else fail=$((fail + 1)); printf 'SELFTEST ASSERT %-56s = FAIL\n' "$1"; fi
  }

  # 夹具的「假 `Uia*` 导出」：**3 行 C stub**，`gcc -shared -fPIC`（**只在自测沙箱里**、仓外）
  build_stub() {   # $1=目标 .so $2=with_uia|no_uia
    local out="$1" kind="$2"
    if [ "$kind" = with_uia ]; then
      printf '%s\n' \
        'int UiaReturnRawElementProvider(void){return 0;}' \
        'int UiaClientsAreListening(void){return 0;}' \
        'int IsWindows10OrGreater(void){return 0;}' \
        | gcc -shared -fPIC -x c - -o "$out" 2>"$SB/gcc.err" && return 0
    else
      printf '%s\n' \
        'int NotAUiaSymbol(void){return 0;}' \
        'int IsWindows10OrGreater(void){return 0;}' \
        | gcc -shared -fPIC -x c - -o "$out" 2>"$SB/gcc.err" && return 0
    fi
    return 1
  }
  mk_tree() {   # $1=dir $2=生产者形状(src|milbridge|md|none) $3=有消费(1|0) $4=库(uia|nouia|none)
               # $5=有映射(1|0)
    local d="$1" where="$2" cons="$3" libk="$4" map="${5:-1}"
    rm -rf "$d"
    mkdir -p "$d/build/shims" "$d/build/PresentationCore.Linux" "$d/build/MilBridge" \
             "$d/src/WpfGfx.Linux.Native/bin"
    if [ "$map" = 1 ]; then
      printf '        { "UIAutomationCore.dll", new[] { "user32" } },\n        { "user32.dll", null },\n' \
        > "$d/build/shims/Win32ShimResolver.cs"
    else
      printf '        { "user32.dll", null },\n        { "gdi32.dll", null },\n' \
        > "$d/build/shims/Win32ShimResolver.cs"
    fi
    if [ "$cons" = 1 ]; then
      printf 'switch (msg) {\n    case WindowMessage.WM_GETOBJECT:\n        return AutomationInteropProvider.ReturnRawElementProvider(h, w, l, el);\n}\n' \
        > "$d/build/PresentationCore.Linux/HwndTarget.Linux.cs"
    else
      printf 'int nothing(void) { return 0; }\n' \
        > "$d/build/PresentationCore.Linux/HwndTarget.Linux.cs"
    fi
    case "$where" in
      src) printf 'void door(IntPtr h) {\n    SendMessage(h, WindowMessage.WM_GETOBJECT, IntPtr.Zero, IntPtr.Zero);\n}\n' \
             > "$d/build/PresentationCore.Linux/Door.Linux.cs";;
      milbridge) printf 'void door(IntPtr h) {\n    SendMessage(h, WindowMessage.WM_GETOBJECT, IntPtr.Zero, IntPtr.Zero);\n}\n' \
             > "$d/build/MilBridge/Canary.Door.cs";;
      md)  printf '# report\nSendMessage(h, WM_GETOBJECT, 0, 0);\n' \
             > "$d/build/FAKE-DOOR-report.md";;
      none) : ;;
    esac
    case "$libk" in
      uia)   build_stub "$d/src/WpfGfx.Linux.Native/bin/libwpfwin32.so" with_uia;;
      nouia) build_stub "$d/src/WpfGfx.Linux.Native/bin/libwpfwin32.so" no_uia;;
    esac
  }

  local DOOR="$SB/door" NOPROD="$SB/noprod" NOCONS="$SB/nocons" MDONLY="$SB/mdonly" \
        MBONLY="$SB/mbonly" NOUIA="$SB/nouia" NOMAP="$SB/nomap" NOLIB="$SB/nolib" EMPTY="$SB/empty"
  if ! command -v gcc >/dev/null 2>&1; then
    say "UIA_DOOR_SELFTEST=NOINFO reason=premise-unmet:gcc-missing（夹具的『假 Uia* 导出』需要一个 3 行 C stub；生产路径**不需要** gcc）"
    return 2
  fi
  mk_tree "$DOOR"    src       1 uia   1
  mk_tree "$NOPROD"  none      1 uia   1
  mk_tree "$NOCONS"  src       0 uia   1
  mk_tree "$MDONLY"  md        1 uia   1
  mk_tree "$MBONLY"  milbridge 1 uia   1
  mk_tree "$NOUIA"   src       1 nouia 1
  mk_tree "$NOMAP"   src       1 uia   0
  mk_tree "$NOLIB"   src       1 none  1
  mkdir -p "$EMPTY"
  FIXENV="UIAD_ANCHORS=off UIAD_MIN_SRC=0 UIAD_MIN_LIBS=0"
  NOLIBDIR="UIAD_SO_DIRS=nonexistent-dir"

  # S01 装门 ⇒ **绿**（门 ＋ 应门人 ＋ 映射 ＋ 假导出 ＋ 路 五条全齐）
  run_case S01-door-installed 0 "$DOOR" $FIXENV
  has 'UIA_DOOR=PASS'; assert 'S01 装门 ⇒ PASS' "$HAS"
  has 'prod=1'; assert 'S01 生产者被数到（prod=1）' "$HAS"
  has 'uia_syms=2'; assert 'S01 夹具 stub 的 2 个 Uia* 导出都被数到（uia_syms=2）' "$HAS"
  has 'ctrl_syms=1'; assert 'S01 同库正对照 IsWindows10* 也在（ctrl_syms=1）' "$HAS"

  # S02 **反极性：拆掉生产者 ⇒ 回到红**（与 S01 成对）
  run_case S02-producer-removed 1 "$NOPROD" $FIXENV
  has 'reason=[no-producer'; assert 'S02 拆生产者 ⇒ FAIL 且点名 no-producer' "$HAS"

  # S03 **反极性：只加映射、不加导出** ⇒ 仍断头（`D-U1` 里那条"未来错误"的形态）
  run_case S03-no-uia-exports 1 "$NOUIA" $FIXENV
  has 'reason=[head-severed:uia-syms=0'; assert 'S03 库无 Uia 导出 ⇒ 点名 head-severed:uia-syms=0' "$HAS"

  # S03b **反极性：库不映射** ⇒ 断头（同树、只拆映射）
  run_case S03b-no-mapping 1 "$NOMAP" $FIXENV
  has 'reason=[head-severed:core-shim=0'; assert 'S03b 未映射 UIAutomationCore.dll ⇒ 点名 head-severed:core-shim=0' "$HAS"

  # S04 **反极性：拆掉应门人** ⇒ 回到红
  run_case S04-consumer-removed 1 "$NOCONS" $FIXENV
  has 'reason=[no-consumer'; assert 'S04 拆应门人 ⇒ 点名 no-consumer' "$HAS"

  # S05 **自污染守卫 a**：生产者只写在 `build/MilBridge/**`（判据内扩展名）⇒ 不许算 prod
  run_case S05-producer-in-milbridge 1 "$MBONLY" $FIXENV
  has 'reason=[no-producer'; assert 'S05 build/MilBridge 里的"生产者" ⇒ 仍红（不自污染）' "$HAS"

  # S05b **自污染守卫 b**：生产者只写在 `.md` 里 ⇒ 不许算 prod，但必须可见
  run_case S05b-producer-only-in-md 1 "$MDONLY" $FIXENV
  has 'reason=[no-producer'; assert 'S05b 只写在 .md 里的"生产者" ⇒ 仍红' "$HAS"
  has 'docs=1'; assert 'S05b 那份 .md 在覆盖面里可见（docs=1）' "$HAS"

  # S06 库目录存在但一个 `.so` 都没有 ⇒ NOINFO（"谈不了导出"，不是"没门"）
  run_case S06-no-lib-found 2 "$NOLIB" $FIXENV $NOLIBDIR
  has 'reason=no-shim-lib-found'; assert 'S06 候选库一个都没有 ⇒ NOINFO reason=no-shim-lib-found' "$HAS"

  # S07 空树 ⇒ NOINFO（**不是绿**）
  run_case S07-empty-roster 2 "$EMPTY" UIAD_ANCHORS=off UIAD_MIN_SRC=0
  has 'reason=no-shim-dir'; assert 'S07 空树 ⇒ NOINFO（先报 no-shim-dir）' "$HAS"

  # S08 件数下限 ⇒ NOINFO
  run_case S08-too-few-files 2 "$DOOR" UIAD_ANCHORS=off UIAD_MIN_SRC=999999
  has 'reason=too-few-files'; assert 'S08 件数低于下限 ⇒ NOINFO reason=too-few-files' "$HAS"

  # S09 `nm` 缺 ⇒ NOINFO
  run_case S09-nm-missing 2 "$DOOR" $FIXENV UIAD_NM=/nonexistent/nm
  has 'reason=nm-missing'; assert 'S09 nm 缺 ⇒ NOINFO reason=nm-missing' "$HAS"

  # S10 解释器缺 ⇒ NOINFO
  run_case S10-python-missing 2 "$DOOR" $FIXENV UIAD_PYTHON=/nonexistent/python3
  has 'reason=python-missing'; assert 'S10 解释器缺 ⇒ NOINFO reason=python-missing' "$HAS"

  # S11 **弄瞎**（树里真有门）⇒ 必须 NOINFO（既不绿、也不冒充红）
  run_case S11-blinded 2 "$DOOR" $FIXENV UIAD_TEST_BLIND=1
  has 'reason=scanner-blinded'; assert 'S11 弄瞎 ⇒ NOINFO（不绿、不冒充红）' "$HAS"

  # S12 金丝雀被故意弄坏 ⇒ 必须 NOINFO（证明这条断言是活的）
  run_case S12-canary-broken 2 "$DOOR" $FIXENV UIAD_CANARY_BREAK=1
  has 'reason=canary-blind'; assert 'S12 金丝雀弄坏 ⇒ NOINFO reason=canary-blind' "$HAS"

  # S13 锚断（合成树里没有那三件）⇒ NOINFO
  run_case S13-anchor-broken 2 "$DOOR" UIAD_ANCHORS=strict UIAD_MIN_SRC=0
  has 'reason=anchor-missing'; assert 'S13 锚断 ⇒ NOINFO reason=anchor-missing' "$HAS"

  # S14 临时目录隔离
  run_case S14-tmp-isolated 0 "$DOOR" $FIXENV
  has "UIA_DOOR_TMPDIR=$SB/tmp/"; assert "S14 临时目录落在 \$TMPDIR=$SB/tmp 之下" "$HAS"

  # S15 生产路径（**真树**）：不许 NOINFO；金丝雀 ok；三态自洽（现树按设计 = FAIL）
  run_case S15-live-tree LIVE "$REAL_ROOT" UIAD_ANCHORS=strict

  # S16 共享 /tmp 不许因**生产路径**留下垃圾
  local leak
  leak="$(find /tmp -maxdepth 1 -name 'uiad-run.*' 2>/dev/null | sed -n '$=')"
  assert 'S16 共享 /tmp 上 uiad-run.* 残留 = 0' "$( [ "${leak:-0}" = 0 ] && echo 1 || echo 0 )"

  say "UIA_DOOR_SELFTEST_SELF self=$SELF sha16=$(self_sha16)"
  say "UIA_DOOR_SELFTEST_ROSTER sandbox=$SB cases=$total pass=$pass fail=$fail not-as-expected=$nae tmpbase=$SB/tmp"
  if [ "$fail" -ne 0 ]; then
    say "UIA_DOOR_SELFTEST_SANDBOX=$SB（保留供诊断；rm -rf 自行清理）"
    say "UIA_DOOR_SELFTEST=FAIL total=$total pass=$pass fail=$fail"
    return 1
  fi
  rm -rf "$SB"
  say "UIA_DOOR_SELFTEST=PASS total=$total pass=$pass fail=0"
  return 0
}

# ── 入口 ─────────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2;;
    --list-notjudged) WANT_NOTJUDGED=1; shift;;
    --list-libs) WANT_LIBS=1; shift;;
    --debug-tmp) KEEP_TMP=1; shift;;
    --selftest) run_selftest; exit $?;;
    -h|--help) usage; exit 0;;
    *) say "UIA_DOOR=NOINFO reason=bad-arg arg=$1"; exit 2;;
  esac
done
main_run
exit $?

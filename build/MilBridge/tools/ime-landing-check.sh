#!/usr/bin/env bash
# ime-landing-check.sh —— 「IME 落点 ＋ 那道『巧合关闭的门』有没有在册声明」的机器牙
#   （**纯读、零 `dotnet`、秒级**）
# ═══════════════════════════════════════════════════════════════════════════════
# 【它防什么】缺陷册 `D-G76`（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2303`）：
#   ① 输入法（IME）这条路在**原生侧零落点**：`ImmGetContext`/`ImmAssociateContext`/`WM_IME_*`（作**实现**）
#      全 0；`"imm32.dll"` 在 `build/shims/` **0 命中**；`nm -D … ' T Imm'` = 0；
#      `XOpenIM`/`XCreateIC`/`XFilterEvent` 全 0 —— 按键只经 `XLookupString(..., NULL)`
#      （**XIC 传 NULL ⇒ 不经任何输入法引擎**）。
#   ② **更要紧的那一条**：托管侧那道门（`_immEnabled = GetSystemMetrics(SM_IMMENABLED=82) != 0`）
#      今天是被 shim 的 `default: return 0` **巧合**关着的 —— **没有任何代码或文档"决定"过它**。
#      `D-G76` 的处置原文要求：**必须在册登记为"有意降级"**；否则将来有人"把它补成 1"，
#      就会打开一条指向**未映射 `imm32.dll`** 的路（本仓"静默 no-op/半通"那一家族）。
#
# 【它是什么】把那句"必须在册登记"变成**会变红的仪器**：
#   · **没声明** ⇒ `FAIL door-not-declared`（**现树上就该是这个**，这是设计）；
#   · **有人把门补成非 0 而 `imm32` 仍未映射** ⇒ `FAIL imm32-unmapped-while-door-open`
#     —— 这条正是 `D-G76` 预言的**未来错误**，从此**会红并点名**；
#   · **有人真造了落点却没更新登记** ⇒ `FAIL declaration-stale` / `landing-without-mapping`；
#   · **补上在册声明**（夹具）⇒ `PASS`；**再拆掉声明** ⇒ **回到红**（两极化，见 `--selftest`）。
#   ⚠️ **`NOINFO` 只在真查不动时用**：函数体抽不到 / 登记面 0 件 / 库找不到 / 解释器缺 / 金丝雀失明。
#   ⚠️ **"要求登记" ≠ "已登记"**：缺陷册 `D-G76` 自己那一行、以及 W72A 报告的建议行，
#      **都含**「有意降级」字样 —— 它们是**提案**，不是**声明**。本件必须把两者分开，
#      否则**引用缺陷册自己那行就会假绿**（这是本件最容易踩的坑，已在金丝雀②里钉住）。
#
# 【判据（三态）】**0 = PASS**｜**1 = FAIL**（逐条点名）｜**2 = NOINFO**（**算不出来 ⇒ 绝不是绿**）。
#   PASS ⟺ `declared=yes` ∧ 世界与声明一致（三条"不一致"全不成立）：
#     · `sm82_nonzero ≥ 1 ∧ shim_map = 0` ⇒ `imm32-unmapped-while-door-open`
#     · `landings ≥ 1 ∧ shim_map = 0 ∧ so_syms = 0` ⇒ `landing-without-mapping`
#     · 声明自陈"零落点/一处都没有" ∧ `landings ≥ 1` ⇒ `declaration-stale`
#   FAIL 逐条：`door-not-declared`（今天的红）｜上面三条。
#   NOINFO 触发面：解释器缺、根缺、**`GetSystemMetrics` 函数体抽不到**（门的开合**量不了**）、
#     寄存器面 0 件可读、候选 shim 库一个都找不到、件数下限、锚断、金丝雀失明、`IMEL_TEST_BLIND=1`。
#
# 【正对照（必须同趟出）】`sm_ctrl`＝同一函数体里 `SM_CXSCREEN|SM_CYSCREEN` 的 `case` 数
#   （≥1 ⇒ 证明函数体**真抽到了**）；`shim_ctrl`＝`build/shims/**` 里 `"user32.dll"` 的出现数
#   （⇒ `"imm32.dll"` 的 0 是真 0）；`nm_alive`＝系统 libc 的 `' T malloc'`（⇒ nm 本路口径有效）。
#
# 【金丝雀（**生产路径自己跑**）】每次真跑前在 `TMPDIR` 里造夹具并要求：
#   ① 声明检测器没瞎（合成 `docs/` 里放一行**合格声明** ⇒ `decl_hits≥1`）；
#   ② **提案 vs 声明分得开**（合成 `要求：必须登记为"有意降级"` ⇒ **不许**进 `decl_hits`，
#      必须在 `IME_DECL_PROPOSAL` 里**可见**）；
#   ③ **报告不自污染**：合格声明放进 `build/MilBridge/*.md`（**报告形状**）⇒ **不许**被计，
#      必须在 `IME_DECL_SKIP` 里**可见**（本件自己的报告就住在那里）；
#   ④ **门检测器没瞎**（合成 `GetSystemMetrics` 里放 `case SM_IMMENABLED: return 1;`
#      ⇒ `sm82_nonzero≥1`；同夹具另有 `case SM_CXSCREEN` ⇒ `sm_ctrl≥1`）；
#   ⑤ **落点检测器没瞎**（合成原生源里放 `ImmGetContext(h)` ⇒ `landings≥1`）。
#   不符 ⇒ `NOINFO reason=canary-blind`。`IMEL_CANARY_BREAK=1` 只给自测（把合成声明弄干净 ⇒ 必须报失明）。
#
# 【覆盖面（"没查什么"写死）】判：原生源 `<root>/src/WpfGfx.Linux.Native/src/**` 的 `.c/.h`；
#   `build/shims/**`（任何扩展名，数库名字面量）；**登记面** = `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`
#   ＋ `docs/**/*.md` ＋ `build/MilBridge/tools/*.tsv` —— **排除 `build/MilBridge/*.md`（报告）**（见金丝雀③）。
#   **不判**：运行期真实表现（按组合键会不会出预编辑窗）＝ `NOINFO`（需跑应用，本件禁跑）；
#   `upstream/**` 的 `imm32` P/Invoke **声明**（只作 `imm_decls` 读数）；XIM 能否在真会话里装上（需原生探针）。
#   ⚠️ **本件的绿 ≠ "中文能打"**：它只判"**在册的有意降级与世界一致**"。
#
# 【只读】生产路径**只读**；所有负极构造（补声明/拆声明/把门补成 1/加落点/弄瞎）只在 `--selftest` 沙箱里做。
# 【成本】单趟 ≈ 1 s、零 `dotnet`、零世代成本（不动九位/`GEN_KEYS`/`known-red.json`/不动被测树）。
#   ⚠️ 本件**不在** `build/close-wave.sh` 的 `fp_inputs()` 覆盖面里（机械核见 W121A 报告 §6）
#      ⇒ **新建本件不动 `inputs_fp`**；接线时若纳入覆盖面 ⇒ 那一改**会**动 `inputs_fp`
#      ⇒ 必须安排在 `IN_FP_0` 采样**之前**。
#
# 用法：
#   ime-landing-check.sh [--root DIR] [--list-register] [--list-libs] [--debug-tmp]
#   ime-landing-check.sh --selftest
# 环境（自测/沙箱/夹具用；生产不需要设）：
#   IMEL_ROOT / IMEL_PYTHON / IMEL_NM / IMEL_ANCHORS=strict|off / IMEL_MIN_SRC / IMEL_MIN_LIBS
#   IMEL_SO_DIRS / IMEL_SHIM_DIR / IMEL_SHIM_SRC / IMEL_REG_DIRS / IMEL_TEST_BLIND /
#   IMEL_CANARY_BREAK / IMEL_TMPDIR / IMEL_KEEP_TMP / IMEL_CTRL_SO
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"     # 必须**绝对**：`--selftest` 会在沙箱里以绝对路径拉起
REAL_ROOT="$(cd "$HERE/../../.." && pwd)"

ROOT="${IMEL_ROOT:-$REAL_ROOT}"
PYBIN="${IMEL_PYTHON:-python3}"
NMBIN="${IMEL_NM:-nm}"
ANCHORS="${IMEL_ANCHORS:-strict}"
MIN_SRC="${IMEL_MIN_SRC:-8}"          # 原生源件数下限（现场见读数）
MIN_LIBS="${IMEL_MIN_LIBS:-1}"
BLIND="${IMEL_TEST_BLIND:-0}"
CANARY_BREAK="${IMEL_CANARY_BREAK:-0}"
KEEP_TMP="${IMEL_KEEP_TMP:-0}"
TMPBASE="${IMEL_TMPDIR:-${TMPDIR:-/tmp}}"
CTRL_SO="${IMEL_CTRL_SO:-}"
SO_DIRS="${IMEL_SO_DIRS:-src/WpfGfx.Linux.Native/bin}"
SHIM_DIR="${IMEL_SHIM_DIR:-build/shims}"
SHIM_SRC="${IMEL_SHIM_SRC:-src/WpfGfx.Linux.Native/src/win32_core.c}"
REG_DIRS="${IMEL_REG_DIRS:-docs}"     # 另两处登记件写死在声明里（见下）
WANT_REG=0; WANT_LIBS=0

# ── 覆盖面声明（**唯一一份**）──────────────────────────────────────────────────
IMEL_NATIVE_DIR='src/WpfGfx.Linux.Native/src'
IMEL_NATIVE_EXTS='.c .h'
REG_FILES="${IMEL_REG_FILES:-samples/WpfFeatureProbe/KNOWN-DEFECTS.md}"   # 缺陷册（在册登记的主面）
IMEL_REG_TSV_GLOB='build/MilBridge/tools/*.tsv'
IMEL_REPORT_SKIP='build/MilBridge'        # **报告驻地 ⇒ 不参与判**（自污染守卫③；只**看见**）
# 落点形状（五类）
IMEL_PAT_IMM='\bImm[A-Z][A-Za-z0-9_]*\s*\('
IMEL_PAT_XIM='\bXOpenIM\b|\bXCreateIC\b|\bXSetICFocus\b|\bXSetICValues\b|\bXFilterEvent\b|\bXutf8LookupString\b'
IMEL_PAT_WMIME='\bWM_IME_[A-Z_]+'
IMEL_PAT_BEAUTY='return\s*"WM_IME|case\s+0x011F\b'
IMEL_IMMLIB='"imm32.dll"'
IMEL_CTRLLIB='"user32.dll"'
# 声明检测器的四组词（**必须同时命中前三组、且一个第四组都不许有**）
IMEL_DECL_TRIGGER='IMMENABLED|GetSystemMetrics\s*\(\s*82\s*\)|\bimm32\b'
IMEL_DECL_DECISION='有意降级|有意保留'
IMEL_DECL_REG='已登记|已在册|在册裁定|已裁|裁定|✅'
IMEL_DECL_PROPOSAL='必须|要求|建议|应当|需要登记|需在册|未落地|只登记|要登记|待登记'
IMEL_DECL_ZEROLAND='零落点|一处都没有|无落点|落点都没有'
# `imm32` 断头规模（**读数，不判**）
IMEL_IMMDECL_FILE='upstream/wpf/src/Microsoft.DotNet.Wpf/src/Shared/MS/Win32/UnsafeNativeMethodsCLR.cs'
IMEL_IMMDECL_PAT='ExternDll\.Imm32'
# TSF 门（**读数，不判**）：门 1 的两处守卫（显式关闭，有理由 ⇒ 与门 2 的"巧合"刻意分开）
IMEL_TSF_FILE='build/WindowsBase.Linux/TextServicesLoader.Linux.cs'
IMEL_TSF_PAT='OperatingSystem\.IsWindows|hklm == null'
# 锚（`strict`）
IMEL_ANCHORS_LIST='src/WpfGfx.Linux.Native/src/win32_core.c
                   samples/WpfFeatureProbe/KNOWN-DEFECTS.md
                   build/shims/Win32ShimResolver.cs
                   src/WpfGfx.Linux.Native/bin/libwpfwin32.so'
IMEL_ANCHORS_LIST="$(printf '%s' "$IMEL_ANCHORS_LIST" | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//')"

say() { printf '%s\n' "$*"; }
self_sha16() { sha256sum "$SELF" | cut -c1-16; }
first_line_of_file() { sed -n '1p' "$1" 2>/dev/null; }
usage() {
  cat <<'USAGE'
ime-landing-check.sh —— 「IME 落点 ＋ 那道门的在册声明」的机器牙（D-G76）
  ime-landing-check.sh [--root DIR] [--list-register] [--list-libs] [--debug-tmp]
  ime-landing-check.sh --selftest
三态：rc=0 PASS（在册声明存在 ∧ 世界与声明一致）／
      rc=1 FAIL（逐条点名；**现树上就该是 door-not-declared**）／rc=2 NOINFO（**不是绿**）
USAGE
}

# ── 扫描器（python3；**只报事实、不定态**）────────────────────────────────────────
py_scan() {   # $1=root $2=out.tsv $3=py.err $4=register-list.out
  local root="$1" out="$2" errf="$3"
  : > "$out"; : > "$errf"
  IMEL_REGISTER_OUT="$4" "$PYBIN" - "$root" "$IMEL_NATIVE_DIR" "$IMEL_NATIVE_EXTS" \
    "$REG_FILES" "$REG_DIRS" "$IMEL_REG_TSV_GLOB" "$IMEL_REPORT_SKIP" \
    "$IMEL_PAT_IMM" "$IMEL_PAT_XIM" "$IMEL_PAT_WMIME" "$IMEL_PAT_BEAUTY" \
    "$IMEL_IMMLIB" "$IMEL_CTRLLIB" \
    "$IMEL_DECL_TRIGGER" "$IMEL_DECL_DECISION" "$IMEL_DECL_REG" "$IMEL_DECL_PROPOSAL" \
    "$IMEL_DECL_ZEROLAND" "$IMEL_IMMDECL_FILE" "$IMEL_IMMDECL_PAT" \
    "$IMEL_TSF_FILE" "$IMEL_TSF_PAT" "$SHIM_DIR" "$SHIM_SRC" "$IMEL_ANCHORS_LIST" \
    "$BLIND" > "$out" 2> "$errf" <<'PY_IMEL'
import fnmatch, glob, os, re, sys

(root, native_dir, native_exts, reg_files, reg_dirs, reg_tsv_glob, report_skip,
 p_imm, p_xim, p_wmime, p_beauty, immlib, ctrllib,
 d_trigger, d_decision, d_reg, d_proposal, d_zeroland,
 immdecl_file, immdecl_pat, tsf_file, tsf_pat, shim_dir, shim_src, anchors, blind) = sys.argv[1:28]

native_exts = {e.lower() for e in native_exts.split()}
reg_files   = [x for x in reg_files.split() if x]
reg_dirs    = [x for x in reg_dirs.split() if x]
report_skip = report_skip.strip()
anchors     = [a for a in anchors.split() if a]
blind       = blind == '1'

RE_IMM    = re.compile(p_imm)
RE_XIM    = re.compile(p_xim)
RE_WMIME  = re.compile(p_wmime)
RE_BEAUTY = re.compile(p_beauty)
RE_DTRIG  = re.compile(d_trigger)
RE_DDEC   = re.compile(d_decision)
RE_DREG   = re.compile(d_reg)
RE_DPROP  = re.compile(d_proposal)
RE_DZERO  = re.compile(d_zeroland)
RE_IMMDECL = re.compile(immdecl_pat)
RE_TSF    = re.compile(tsf_pat)
RE_CASELAB = re.compile(r'^\s*case\s+(.*?):')

def emit(tag, *rest):
    sys.stdout.write('\t'.join([tag] + [str(x) for x in rest]) + '\n')

REGF = None
_r = os.environ.get('IMEL_REGISTER_OUT') or ''
if _r:
    try:
        REGF = open(_r, 'w')
    except OSError:
        REGF = None

n_imm = n_xim = n_wmime = n_beauty = 0
n_shimmap = n_shimctrl = 0
shim_files = 0
files_native = 0
n_decl = n_prop = n_skip = 0
zero_land_decl = 0
decl_rows = []; prop_rows = []; skip_rows = []
land_rows = []

def readtext(p):
    try:
        return open(p, 'r', encoding='utf-8', errors='replace').read()
    except OSError:
        return None

# ── A) 原生落点（三类）─────────────────────────────────────────────────────────
nd = os.path.join(root, native_dir)
if os.path.isdir(nd):
    for dp, dirs, fs in os.walk(nd):
        dirs[:] = sorted(dirs)
        for f in sorted(fs):
            if os.path.splitext(f)[1].lower() not in native_exts:
                continue
            files_native += 1
            rel = os.path.relpath(os.path.join(dp, f), root)
            txt = readtext(os.path.join(dp, f))
            if txt is None:
                emit('ERR', rel, 'unreadable'); continue
            for ln, line in enumerate(txt.splitlines(), 1):
                if blind:
                    continue
                for m in RE_IMM.finditer(line):
                    n_imm += 1; land_rows.append(('native_imm', rel, ln, line.strip()[:130]))
                for m in RE_XIM.finditer(line):
                    n_xim += 1; land_rows.append(('native_xim', rel, ln, line.strip()[:130]))
                if RE_WMIME.search(line):
                    if RE_BEAUTY.search(line):
                        n_beauty += 1          # **名字不是实现**：只登记、不计落点
                    else:
                        n_wmime += 1; land_rows.append(('native_wmime', rel, ln, line.strip()[:130]))

# ── B) `build/shims/**` 里的库名字面量 ─────────────────────────────────────────
sd = os.path.join(root, shim_dir)
shim_dir_present = os.path.isdir(sd)
if shim_dir_present:
    for dp, dirs, fs in os.walk(sd):
        dirs[:] = sorted(dirs)
        for f in sorted(fs):
            txt = readtext(os.path.join(dp, f))
            if txt is None:
                continue
            shim_files += 1
            n_shimmap += txt.count(immlib)
            n_shimctrl += txt.count(ctrllib)
if blind:
    n_imm = n_xim = n_wmime = n_shimmap = 0

# ── C) 那道门：`GetSystemMetrics` 函数体里有没有"82 / SM_IMMENABLED"这一格 ───────────
sm82_case = sm82_nonzero = sm_ctrl = 0
sm_body_lines = 0
sm_body_found = 0
sm_path = os.path.join(root, shim_src)
smtxt = readtext(sm_path)
if smtxt is not None and not blind:
    lines = smtxt.splitlines()
    start = None
    for i, l in enumerate(lines):
        if re.search(r'\bGetSystemMetrics\s*\(', l) and not l.strip().startswith('//'):
            # 只要**函数定义**（不是调用）：形如 `<type> GetSystemMetrics(` 且行尾不是 `;`
            if ';' not in l:
                start = i
                break
    if start is not None:
        body = []
        for l in lines[start:]:
            body.append(l)
            if l.startswith('}') and len(body) > 1:
                break
        sm_body_lines = len(body)
        sm_body_found = 1
        # 逐 `case` 标签：标签文本 → 到下一个 case 之间的片段里找 `return <expr>;`
        idx = [i for i, l in enumerate(body) if RE_CASELAB.match(l)]
        for k, i in enumerate(idx):
            labels = RE_CASELAB.match(body[i]).group(1)
            seg_end = idx[k+1] if k + 1 < len(idx) else len(body)
            seg = '\n'.join(body[i:seg_end])
            toks = [t.strip() for t in labels.split(':') if t.strip()]
            hit82 = any(re.search(r'(^|\W)82(\W|$)', t) or 'SM_IMMENABLED' in t for t in toks)
            hitctrl = any(('SM_CXSCREEN' in t) or ('SM_CYSCREEN' in t) or
                          re.search(r'(^|\W)(0|1)(\W|$)', t) for t in toks)
            if hit82:
                sm82_case += 1
                r = re.search(r'return\s+([^;]+);', seg)
                if r and r.group(1).strip() != '0':
                    sm82_nonzero += 1
            if hitctrl:
                sm_ctrl += 1

# ── D) 在册声明（**提案 vs 声明**必须分开）─────────────────────────────────────
reg_paths = []
for f in reg_files:
    p = os.path.join(root, f)
    if os.path.isfile(p):
        reg_paths.append(p)
for d in reg_dirs:
    for dp, dirs, fs in os.walk(os.path.join(root, d)):
        dirs[:] = sorted(dirs)
        for f in sorted(fs):
            if f.endswith('.md'):
                reg_paths.append(os.path.join(dp, f))
for p in sorted(glob.glob(os.path.join(root, reg_tsv_glob))):
    reg_paths.append(p)
reg_paths = sorted(set(reg_paths))
# **报告面**：`build/MilBridge/*.md` **读**、但只**看得见**（命中的行进 `DECLSKIP`，不计入声明）
skip_paths = [p for p in sorted(glob.glob(os.path.join(root, report_skip, '*.md')))
              if os.path.isfile(p)] if report_skip else []

def consider(path, parts, skipped_file):
    """一行是否算**声明**；返回 None（无关）/ 'decl' / 'prop'。"""
    global n_decl, n_prop, n_skip, zero_land_decl
    line = parts[2]
    if not RE_DTRIG.search(line):
        return None
    if not RE_DDEC.search(line):
        return None
    if skipped_file:
        n_skip += 1; skip_rows.append((parts[0], parts[1], line.strip()[:130])); return None
    if RE_DPROP.search(line):
        n_prop += 1; prop_rows.append((parts[0], parts[1], line.strip()[:130])); return None
    if not RE_DREG.search(line):
        n_prop += 1; prop_rows.append((parts[0], parts[1], '(缺登记形状) ' + line.strip()[:110])); return None
    n_decl += 1
    if RE_DZERO.search(line):
        zero_land_decl = 1
    decl_rows.append((parts[0], parts[1], line.strip()[:130]))
    return 'decl'

for p, skipped_file in ([(x, False) for x in reg_paths] + [(x, True) for x in skip_paths]):
    rel = os.path.relpath(p, root)
    txt = readtext(p)
    if txt is None:
        continue
    for ln, line in enumerate(txt.splitlines(), 1):
        consider(p, (rel, ln, line), skipped_file)

# ── E) 读数（不判）：`imm32` 断头规模 ＋ TSF 门守卫 ─────────────────────────────
imm_decl_lines = []
imm_names = set()
p = os.path.join(root, immdecl_file)
txt = readtext(p)
if txt is not None:
    ls = txt.splitlines()
    hits = [i for i, l in enumerate(ls) if RE_IMMDECL.search(l)]
    imm_decl_lines = hits
    if hits:
        lo, hi = max(0, hits[0] - 1), min(len(ls), hits[-1] + 3)
        for l in ls[lo:hi]:
            for m in re.finditer(r'\b(Imm[A-Z][A-Za-z0-9_]*)\s*\(', l):
                imm_names.add(m.group(1))
tsf_guard = 0
txt = readtext(os.path.join(root, tsf_file))
if txt is not None:
    tsf_guard = len(RE_TSF.findall(txt))
imm_chain = 0
for p in glob.glob(os.path.join(root, 'upstream/wpf/src/**/*.cs'), recursive=True):
    t = readtext(p)
    if t:
        imm_chain += t.count('IMMENABLED')

if blind:
    n_decl = 0; decl_rows = []

for r in land_rows[:60]:
    emit('LAND', r[0], r[1], r[2], r[3])
for r in decl_rows[:20]:
    emit('DECL', r[0], r[1], r[2])
for r in prop_rows[:20]:
    emit('DECLPROP', r[0], r[1], r[2])
for r in skip_rows[:20]:
    emit('DECLSKIP', r[0], r[1], r[2])

emit('K', 'blind', 1 if blind else 0)
emit('K', 'files_native', files_native)
emit('K', 'native_imm', n_imm)
emit('K', 'native_xim', n_xim)
emit('K', 'native_wmime', n_wmime)
emit('K', 'wmime_beauty', n_beauty)
emit('K', 'shim_map', n_shimmap)
emit('K', 'shim_ctrl', n_shimctrl)
emit('K', 'shim_files', shim_files)
emit('K', 'shim_dir_present', 1 if shim_dir_present else 0)
emit('K', 'sm_body_found', sm_body_found)
emit('K', 'sm_body_lines', sm_body_lines)
emit('K', 'sm82_case', sm82_case)
emit('K', 'sm82_nonzero', sm82_nonzero)
emit('K', 'sm_ctrl', sm_ctrl)
emit('K', 'reg_files', len(reg_paths))
emit('K', 'decl_hits', n_decl)
emit('K', 'decl_proposal', n_prop)
emit('K', 'decl_skip', n_skip)
emit('K', 'decl_zero_land', zero_land_decl)
emit('K', 'imm_decls', len(imm_decl_lines))
emit('K', 'imm_names', len(imm_names))
emit('K', 'imm_chain', imm_chain)
emit('K', 'tsf_guard', tsf_guard)
for a in anchors:
    emit('HAVE', a, 1 if os.path.isfile(os.path.join(root, a)) else 0)
if REGF:
    for p in reg_paths:
        REGF.write(os.path.relpath(p, root) + '\n')
    REGF.close()
PY_IMEL
}

# ── 解析 TSV ─────────────────────────────────────────────────────────────────
parse_scan() {
  P_BLIND=0; P_FNATIVE=0; P_IMM=0; P_XIM=0; P_WMIME=0; P_BEAUTY=0
  P_SHIM=0; P_SHIMCTRL=0; P_SHIMFILES=0; P_SHIMDIR=0
  P_BODYFOUND=0; P_BODYLINES=0; P_SM82CASE=0; P_SM82NZ=0; P_SMCTRL=0
  P_REGFILES=0; P_DECL=0; P_PROP=0; P_SKIP=0; P_ZEROLAND=0
  P_IMMDECLS=0; P_IMMNAMES=0; P_IMMCHAIN=0; P_TSF=0
  P_DECLROWS=''; P_PROPWROWS=''; P_SKIPROWS=''; P_LANDROWS=''; P_ERRROWS=''; P_ANCHORS=''
  local tag a b c d
  while IFS=$'\t' read -r tag a b c d; do
    case "$tag" in
      K) case "$a" in
           blind) P_BLIND="$b";; files_native) P_FNATIVE="$b";; native_imm) P_IMM="$b";;
           native_xim) P_XIM="$b";; native_wmime) P_WMIME="$b";; wmime_beauty) P_BEAUTY="$b";;
           shim_map) P_SHIM="$b";; shim_ctrl) P_SHIMCTRL="$b";; shim_files) P_SHIMFILES="$b";;
           shim_dir_present) P_SHIMDIR="$b";; sm_body_found) P_BODYFOUND="$b";;
           sm_body_lines) P_BODYLINES="$b";; sm82_case) P_SM82CASE="$b";;
           sm82_nonzero) P_SM82NZ="$b";; sm_ctrl) P_SMCTRL="$b";; reg_files) P_REGFILES="$b";;
           decl_hits) P_DECL="$b";; decl_proposal) P_PROP="$b";; decl_skip) P_SKIP="$b";;
           decl_zero_land) P_ZEROLAND="$b";; imm_decls) P_IMMDECLS="$b";;
           imm_names) P_IMMNAMES="$b";; imm_chain) P_IMMCHAIN="$b";; tsf_guard) P_TSF="$b";;
         esac;;
      DECL) P_DECLROWS="${P_DECLROWS}${a}|${b}|${c}"$'\n';;
      DECLPROP) P_PROPWROWS="${P_PROPWROWS}${a}|${b}|${c}"$'\n';;
      DECLSKIP) P_SKIPROWS="${P_SKIPROWS}${a}|${b}|${c}"$'\n';;
      LAND) P_LANDROWS="${P_LANDROWS}${a}|${b}|${c}|${d}"$'\n';;
      ERR) P_ERRROWS="${P_ERRROWS}${a}|${b}"$'\n';;
      HAVE) P_ANCHORS="${P_ANCHORS}${a}=${b} ";;
    esac
  done < "$1"
}

emit_scope() {
  say "IME_LANDING_SCOPE root=$ROOT native_dir=$IMEL_NATIVE_DIR exts=[$IMEL_NATIVE_EXTS] shim_dir=$SHIM_DIR shim_src=$SHIM_SRC reg_files=[$REG_FILES] reg_dirs=[$REG_DIRS] reg_tsv=[$IMEL_REG_TSV_GLOB] report_skip=$IMEL_REPORT_SKIP so_dirs=[$SO_DIRS] anchors=$ANCHORS min_src=$MIN_SRC min_libs=$MIN_LIBS"
  say "IME_LANDING_SCOPE_DECL trigger=[$IMEL_DECL_TRIGGER] decision=[$IMEL_DECL_DECISION] reg=[$IMEL_DECL_REG] proposal_veto=[$IMEL_DECL_PROPOSAL] zeroland=[$IMEL_DECL_ZEROLAND]"
  say "IME_LANDING_SCOPE_PAT imm=[$IMEL_PAT_IMM] xim=[$IMEL_PAT_XIM] wmime=[$IMEL_PAT_WMIME] beauty=[$IMEL_PAT_BEAUTY]"
}

nm_scan() {   # $1=libs 文件 ⇒ 写全局 NM_*
  NM_IMM=0; NM_TOTAL=0; NM_CTRL=0; NM_LIBS=0; NM_ROWS=''; NM_ERR=''
  local lib out
  while IFS= read -r lib; do
    [ -n "$lib" ] || continue
    NM_LIBS=$((NM_LIBS + 1))
    if ! out="$("$NMBIN" -D --defined-only "$lib" 2>&1)"; then
      NM_ERR="${NM_ERR}${lib}:nm-rc!=0; "; continue
    fi
    local i t c
    i=$(printf '%s\n' "$out" | grep -c ' T Imm' || true)
    t=$(printf '%s\n' "$out" | grep -c ' T ' || true)
    c=$(printf '%s\n' "$out" | grep -c ' T XOpenIM\| T XCreateIC\| T XFilterEvent' || true)
    NM_IMM=$((NM_IMM + i)); NM_TOTAL=$((NM_TOTAL + t)); NM_CTRL=$((NM_CTRL + c))
    NM_ROWS="${NM_ROWS}${lib}|${i}|${t}|${c}"$'\n'
  done < "$1"
}
nm_alive() {
  local cand="${CTRL_SO:-}" p
  if [ -z "$cand" ]; then
    for p in /lib/x86_64-linux-gnu/libc.so.6 /usr/lib/x86_64-linux-gnu/libc.so.6 \
             /lib64/libc.so.6 /usr/lib64/libc.so.6 /lib/aarch64-linux-gnu/libc.so.6; do
      [ -f "$p" ] && { cand="$p"; break; }
    done
  fi
  NM_ALIVE_SO="$cand"; NM_ALIVE=1; NM_ALIVE_N=0
  [ -n "$cand" ] && [ -f "$cand" ] || { NM_ALIVE=-1; return; }
  NM_ALIVE_N="$("$NMBIN" -D --defined-only "$cand" 2>/dev/null | grep -c ' T malloc' || true)"
  [ "${NM_ALIVE_N:-0}" -ge 1 ] || NM_ALIVE=0
}

# ── 金丝雀（**生产路径自带**）───────────────────────────────────────────────────
build_canary() {   # $1=canary 根
  # ⚠️ 金丝雀必须把夹具放在**当前配置声明的相对路径**下（否则 `IMEL_REG_DIRS=…` 一改，
  #    金丝雀自己就找不到自己的声明 ⇒ 每次都被误判成 canary-blind；这一条是自测 S10 逼出来的）
  local c="$1" regdir regfile
  regdir="${REG_DIRS%% *}"; regdir="${regdir:-docs}"
  regfile="${REG_FILES%% *}"; regfile="${regfile:-samples/WpfFeatureProbe/KNOWN-DEFECTS.md}"
  rm -rf "$c"
  mkdir -p "$c/$regdir" "$c/$(dirname "$regfile")" "$c/$IMEL_REPORT_SKIP" "$c/$SHIM_DIR" \
           "$c/$IMEL_NATIVE_DIR" "$c/$(dirname "$SHIM_SRC")"
  if [ "$CANARY_BREAK" = 1 ]; then
    printf '# canary\n（这里**故意**没有合格声明）\n' > "$c/$regdir/CANARY-DECL.md"
  else
    printf '# canary\n| `D-G76` | ✅ **已在册裁定 = 有意降级**：shim 的 `GetSystemMetrics(SM_IMMENABLED=82)` 走 `default: return 0`（imm32 未映射，**禁止**补成 1） |\n' \
      > "$c/$regdir/CANARY-DECL.md"
  fi
  # ② 提案行：**必须**被认出并排除（`要求…必须登记`、`未落地`）
  printf '# canary\n- 要求：那一重**必须在册登记为"有意降级"**（`default: return 0`，`imm32`，`IMMENABLED=82`）——**未落地**。\n' \
    > "$c/$regdir/CANARY-PROPOSAL.md"
  # ③ 报告形状 ⇒ **不许**被计（但必须**可见**）
  printf '# fake report\n| `D-G76` | ✅ **已在册裁定 = 有意降级**：`GetSystemMetrics(SM_IMMENABLED=82)` 走 `default: return 0`，`imm32` 未映射 |\n' \
    > "$c/$IMEL_REPORT_SKIP/FAKE-report.md"
  # ④ 门检测器（合成 shim：`case SM_IMMENABLED: return 1;` 正是"未来错误"的形状）
  printf 'int GetSystemMetrics(int nIndex)\n{\n    switch (nIndex) {\n        case SM_CXSCREEN: return 1280;\n        case SM_CYSCREEN: return 1024;\n        case SM_IMMENABLED: return 1;\n        default: return 0;\n    }\n}\n' \
    > "$c/$SHIM_SRC"
  # ⑤ 落点检测器（合成原生源：一处 `ImmGetContext`）
  printf '#include <imm.h>\nHIMC probe(HWND h) { return ImmGetContext(h); }\n' \
    > "$c/$IMEL_NATIVE_DIR/win32_canary.c"
  printf '        { "user32.dll", null },\n' > "$c/$SHIM_DIR/Win32ShimResolver.cs"
}

cleanup_tmp() { [ "$KEEP_TMP" = 1 ] || rm -rf "$T"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 生产路径
# ═══════════════════════════════════════════════════════════════════════════════
main_run() {
  emit_scope
  if ! command -v "$PYBIN" >/dev/null 2>&1; then
    say "IME_LANDING_SELF path=$SELF sha16=$(self_sha16)"
    say "IME_LANDING=NOINFO reason=python-missing py=$PYBIN"; return 2
  fi
  if [ ! -d "$ROOT" ]; then
    say "IME_LANDING=NOINFO reason=root-missing root=$ROOT"; return 2
  fi
  T="$(mktemp -d "$TMPBASE/imel-run.XXXXXX")" || { say 'IME_LANDING=NOINFO reason=mktemp-failed'; return 2; }
  trap cleanup_tmp EXIT
  say "IME_LANDING_TMPDIR=$T"

  # ① 金丝雀
  build_canary "$T/canary"
  py_scan "$T/canary" "$T/can.tsv" "$T/can.err" "$T/can.reg"; local can_rc=$?
  parse_scan "$T/can.tsv"
  local CAN_DECL="$P_DECL" CAN_PROP="$P_PROP" CAN_SKIP="$P_SKIP" CAN_SM82="$P_SM82NZ"
  local CAN_SMCTRL="$P_SMCTRL" CAN_IMM="$P_IMM"
  local can_reason=''
  if [ "$can_rc" != 0 ] || [ -s "$T/can.err" ]; then can_reason="canary-scanner-error rc=$can_rc err=$(first_line_of_file "$T/can.err")"
  elif [ "${CAN_DECL:-0}" -lt 1 ]; then can_reason="decl_hits=$CAN_DECL want>=1（声明检测器失明）"
  elif [ "${CAN_PROP:-0}" -lt 1 ]; then can_reason="decl_proposal=$CAN_PROP want>=1（提案行**必须**被认出并排除）"
  elif [ "${CAN_SKIP:-0}" -lt 1 ]; then can_reason="decl_skip=$CAN_SKIP want>=1（报告形状里的声明**必须**可见且不计）"
  elif [ "${CAN_SM82:-0}" -lt 1 ]; then can_reason="sm82_nonzero=$CAN_SM82 want>=1（'把门补成 1'这条路**必须**被看见）"
  elif [ "${CAN_SMCTRL:-0}" -lt 1 ]; then can_reason="sm_ctrl=$CAN_SMCTRL want>=1（函数体抽取的正对照没数到）"
  elif [ "${CAN_IMM:-0}" -lt 1 ]; then can_reason="native_imm=$CAN_IMM want>=1（落点检测器失明）"
  fi

  # ② 真扫
  py_scan "$ROOT" "$T/scan.tsv" "$T/py.err" "$T/register.txt"; local py_rc=$?
  parse_scan "$T/scan.tsv"
  local py_err_log=''
  [ -s "$T/py.err" ] && py_err_log="$(first_line_of_file "$T/py.err")"

  # ③ 库 + `nm`
  : > "$T/libs.txt"
  local d
  for d in $SO_DIRS; do
    [ -d "$ROOT/$d" ] && find "$ROOT/$d" -maxdepth 1 -name '*.so' -type f 2>/dev/null >> "$T/libs.txt"
  done
  [ -d "$ROOT/$SHIM_DIR" ] && find "$ROOT/$SHIM_DIR" -maxdepth 1 -name '*.so' -type f 2>/dev/null >> "$T/libs.txt"
  LC_ALL=C sort -u -o "$T/libs.txt" "$T/libs.txt"
  local NLIBS; NLIBS=$(wc -l < "$T/libs.txt")
  local nm_reason=''
  NM_IMM=0; NM_TOTAL=0; NM_CTRL=0; NM_LIBS=0; NM_ROWS=''; NM_ERR=''
  NM_ALIVE=1; NM_ALIVE_N=0; NM_ALIVE_SO=''
  if [ "$NLIBS" -gt 0 ]; then
    if ! command -v "$NMBIN" >/dev/null 2>&1; then
      nm_reason="nm-missing nm=$NMBIN"
    else
      nm_scan "$T/libs.txt"; nm_alive
    fi
  fi

  # ④ 定态
  local LANDINGS=$((P_IMM + P_XIM + P_WMIME + P_SHIM + NM_IMM))
  local STATE=PASS RC=0 REASON=''
  if [ "$py_rc" != 0 ] || [ -n "$py_err_log" ]; then
    STATE=NOINFO; REASON="scanner-error py_rc=$py_rc py_err=$py_err_log"
  elif [ "$P_BLIND" = 1 ]; then
    STATE=NOINFO; REASON='scanner-blinded（IMEL_TEST_BLIND=1 ⇒ 读数无信息）'
  elif [ -n "$can_reason" ]; then
    STATE=NOINFO; REASON="canary-blind（内置金丝雀不符：$can_reason）"
  elif [ "$P_SHIMDIR" != 1 ]; then
    STATE=NOINFO; REASON="no-shim-dir（$SHIM_DIR 不在 ⇒ 库名映射面**量不了**）"
  elif [ "$P_BODYFOUND" != 1 ]; then
    STATE=NOINFO; REASON="sm-body-not-found（$SHIM_SRC 里抽不到 GetSystemMetrics 函数体 ⇒ **门的开合量不了**）"
  elif [ "$P_SMCTRL" -eq 0 ]; then
    STATE=NOINFO; REASON="sm-body-control-zero（函数体里连 SM_CXSCREEN/SM_CYSCREEN 的 case 都没有 ⇒ 抽取口径可疑）"
  elif [ "$P_REGFILES" -eq 0 ]; then
    STATE=NOINFO; REASON='no-register-surface（登记面 0 件可读 ⇒ **在册声明量不了**，不是"没登记"）'
  elif [ "$P_FNATIVE" -lt "$MIN_SRC" ]; then
    STATE=NOINFO; REASON="too-few-files files_native=$P_FNATIVE min=$MIN_SRC"
  elif [ -n "$nm_reason" ]; then
    STATE=NOINFO; REASON="$nm_reason"
  elif [ "$NLIBS" -eq 0 ]; then
    STATE=NOINFO; REASON="no-shim-lib-found（候选 shim 库一个都没有 ⇒ 数不了 Imm 导出）dirs=[$SO_DIRS]"
  elif [ "$NLIBS" -lt "$MIN_LIBS" ]; then
    STATE=NOINFO; REASON="too-few-libs libs=$NLIBS min=$MIN_LIBS"
  elif [ "$NM_ALIVE" = 0 ]; then
    STATE=NOINFO; REASON="nm-blind（系统对照 $NM_ALIVE_SO 里 ' T malloc' = 0）"
  elif [ "$ANCHORS" = strict ]; then
    case "$P_ANCHORS" in
      *'=0'*) STATE=NOINFO; REASON="anchor-missing（射程缩水 ⇒ 不许绿）anchors=[${P_ANCHORS% }]";;
    esac
  fi

  # ⑤ 判据本体
  local FAILS=''
  if [ "$STATE" = PASS ]; then
    [ "$P_DECL" -ge 1 ] || FAILS="${FAILS}door-not-declared "
    if [ "$P_SM82NZ" -ge 1 ] && [ "$P_SHIM" -eq 0 ]; then
      FAILS="${FAILS}imm32-unmapped-while-door-open "
    fi
    if [ "$LANDINGS" -ge 1 ] && [ "$P_SHIM" -eq 0 ] && [ "$NM_IMM" -eq 0 ]; then
      FAILS="${FAILS}landing-without-mapping "
    fi
    if [ "$P_ZEROLAND" -eq 1 ] && [ "$LANDINGS" -ge 1 ]; then
      FAILS="${FAILS}declaration-stale "
    fi
    [ -n "$FAILS" ] && STATE=FAIL
  fi

  # ⑥ 机读行 + 逐条依据
  say "IME_LANDING_LANDINGS landings=$LANDINGS native_imm=$P_IMM native_xim=$P_XIM native_wmime=$P_WMIME wmime_beauty=$P_BEAUTY shim_map=$P_SHIM so_syms=$NM_IMM files_native=$P_FNATIVE shim_files=$P_SHIMFILES"
  say "IME_LANDING_CTRL shim_control=\"user32.dll\"=$P_SHIMCTRL sm_ctrl=$P_SMCTRL nm_alive=${NM_ALIVE}/${NM_ALIVE_N} ctrl_total=$NM_TOTAL libs=$NLIBS"
  say "IME_LANDING_DOOR sm_body_found=$P_BODYFOUND sm_body_lines=$P_BODYLINES sm82_case=$P_SM82CASE sm82_nonzero=$P_SM82NZ door=GetSystemMetrics82 today=makes_immEnabled_false"
  say "IME_LANDING_REGISTER reg_files=$P_REGFILES decl_hits=$P_DECL decl_proposal=$P_PROP decl_skip=$P_SKIP decl_zero_land=$P_ZEROLAND"
  say "IME_LANDING_CTX imm_decls=$P_IMMDECLS imm_names=$P_IMMNAMES imm_chain_IMMENABLED=$P_IMMCHAIN tsf_guard=$P_TSF"
  if [ -z "$can_reason" ]; then
    say "IME_LANDING_CANARY=ok decl_hits=$CAN_DECL decl_proposal=$CAN_PROP decl_skip=$CAN_SKIP sm82_nonzero=$CAN_SM82 sm_ctrl=$CAN_SMCTRL native_imm=$CAN_IMM"
  else
    say "IME_LANDING_CANARY=BLIND reason=$can_reason"
  fi
  local row rest rest2 p ln tx cat
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    cat="${row%%|*}"; rest="${row#*|}"; p="${rest%%|*}"; rest2="${rest#*|}"
    ln="${rest2%%|*}"; tx="${rest2#*|}"
    say "IME_LANDING_SITE kind=$cat path=$p line=$ln detail=${tx//|/ }"
  done <<< "$P_LANDROWS"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    p="${row%%|*}"; rest="${row#*|}"; ln="${rest%%|*}"; tx="${rest#*|}"
    say "IME_DECL_HIT path=$p line=$ln detail=${tx//|/ }"
  done <<< "$P_DECLROWS"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    p="${row%%|*}"; rest="${row#*|}"; ln="${rest%%|*}"; tx="${rest#*|}"
    say "IME_DECL_PROPOSAL path=$p line=$ln detail=${tx//|/ }（**提案，不是声明**：含否决词 ⇒ 不计）"
  done <<< "$P_PROPWROWS"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    p="${row%%|*}"; rest="${row#*|}"; ln="${rest%%|*}"; tx="${rest#*|}"
    say "IME_DECL_SKIP path=$p line=$ln detail=${tx//|/ }（报告驻地 ⇒ **看得见、不计**：自污染守卫）"
  done <<< "$P_SKIPROWS"
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    p="${row%%|*}"; rest="${row#*|}"; i="${rest%%|*}"; rest="${rest#*|}"
    t="${rest%%|*}"; c="${rest#*|}"
    say "IME_LANDING_LIB path=$p imm_syms=$i ctrl_total=$t xim_syms=$c"
  done <<< "$NM_ROWS"
  [ -n "$NM_ERR" ] && say "IME_LANDING_NMERR $NM_ERR"
  local e
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    say "IME_LANDING_SCANERR path=${e%%|*} reason=${e#*|}"
  done <<< "$P_ERRROWS"

  case "$STATE" in
    PASS) RC=0
      say "IME_LANDING=PASS landings=$LANDINGS declared=yes ctrl=$P_SHIMCTRL sm82_nonzero=$P_SM82NZ shim_map=$P_SHIM so_syms=$NM_IMM decl_hits=$P_DECL"
      say "IME_LANDING_VERDICT=世界与在册声明一致（那道'巧合关闭的门'已在册登记为有意降级）";;
    FAIL) RC=1
      say "IME_LANDING=FAIL landings=$LANDINGS declared=$([ "$P_DECL" -ge 1 ] && echo yes || echo no) ctrl=$P_SHIMCTRL sm82_nonzero=$P_SM82NZ shim_map=$P_SHIM so_syms=$NM_IMM decl_hits=$P_DECL reason=[${FAILS% }]"
      say "IME_LANDING_VERDICT=那道门**没人登记过**／或世界已与声明不一致 ⇒ 组合输入不可用且**没有人在册决定过**（D-G76）；**这是设计内的红**：接进门禁前必须先登记为在册红（见 W121A 报告 §5）";;
    *) RC=2
      say "IME_LANDING=NOINFO reason=$REASON landings=$LANDINGS declared=$([ "$P_DECL" -ge 1 ] && echo yes || echo no) sm82_nonzero=$P_SM82NZ reg_files=$P_REGFILES";;
  esac
  say "IME_LANDING_SELF path=$SELF sha16=$(self_sha16)"
  if [ "$WANT_REG" = 1 ]; then
    say "IME_LANDING_REGISTER_LIST_BEGIN n=$( [ -f "$T/register.txt" ] && wc -l < "$T/register.txt" || echo 0 )"
    cat "$T/register.txt" 2>/dev/null
    say "IME_LANDING_REGISTER_LIST_END"
  fi
  if [ "$WANT_LIBS" = 1 ]; then
    say "IME_LANDING_LIBS_LIST_BEGIN"; cat "$T/libs.txt" 2>/dev/null; say "IME_LANDING_LIBS_LIST_END"
  fi
  return "$RC"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 自测（两极化；自带 TMPDIR）
# ═══════════════════════════════════════════════════════════════════════════════
run_selftest() {
  local inner="${IMEL_ST_INNER:-0}"
  if [ "$inner" != 1 ]; then
    local s0 s1 out rc
    s0="$(self_sha16)"
    say "ST_ATTEST=OPEN self=$SELF sha16=$s0"
    out="$(IMEL_ST_INNER=1 bash "$SELF" --selftest 2>&1)"; rc=$?
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
    say "IME_LANDING_SELFTEST=NOINFO reason=premise-unmet:python-missing py=$PYBIN"; return 2
  fi
  local SB
  SB="$(mktemp -d "$TMPBASE/imel-selftest.XXXXXX")" || { say 'IME_LANDING_SELFTEST=FAIL reason=mktemp-failed'; return 1; }
  mkdir -p "$SB/tmp"
  local pass=0 fail=0 total=0 nae=0
  local CUR_OUT='' CUR_RC='' CUR_STATE='' CUR_WANT=''

  run_case() {
    local id="$1" want="$2" tree="$3"; shift 3
    local -a envs=("IMEL_TMPDIR=$SB/tmp" "$@")
    CUR_WANT="$want"
    CUR_OUT="$(env "${envs[@]}" bash "$SELF" --root "$tree" 2>&1)"; CUR_RC=$?
    CUR_STATE="$(printf '%s\n' "$CUR_OUT" | sed -n 's/^IME_LANDING=\([A-Z]*\) .*/\1/p' | sed -n '1p')"
    local ok='no' why=''
    if [ "$want" = LIVE ]; then
      case "$CUR_RC" in
        0) case "$CUR_OUT" in *'IME_LANDING=PASS'*) ok=yes;; *) why='rc=0 但状态行不是 PASS';; esac;;
        1) case "$CUR_STATE" in FAIL) ok=yes;; *) why="rc=1 但 state=$CUR_STATE";; esac;;
        *) why="rc=$CUR_RC（生产路径不许异常/NOINFO）";;
      esac
      case "$CUR_OUT" in *'IME_LANDING_CANARY=ok'*) ;; *) ok=no; why="$why canary!=ok";; esac
    else
      [ "$CUR_RC" = "$want" ] && ok=yes || why="rc=$CUR_RC want=$want"
    fi
    total=$((total + 1))
    if [ "$ok" = yes ]; then pass=$((pass + 1)); else
      fail=$((fail + 1))
      if [ "$want" != LIVE ] && [ "$CUR_RC" != "$want" ]; then nae=$((nae + 1)); fi
    fi
    printf 'SELFTEST CASE %-28s = %s rc=%s want=%s state=%s %s\n' \
           "$id" "$( [ "$ok" = yes ] && echo PASS || echo FAIL )" "$CUR_RC" "$want" \
           "${CUR_STATE:-none}" "$why"
  }
  has() { case "$CUR_OUT" in *"$1"*) HAS=1;; *) HAS=0;; esac; }
  assert() {
    total=$((total + 1))
    if [ "$2" = 1 ]; then pass=$((pass + 1)); printf 'SELFTEST ASSERT %-58s = PASS\n' "$1"
    else fail=$((fail + 1)); printf 'SELFTEST ASSERT %-58s = FAIL\n' "$1"; fi
  }

  # ── 夹具：`mk_tree <dir> <声明(decl|prop|report|none)> <门(closed|open)> <落点(none|imm)>`
  #    ＋ 每个夹具带一份**真实的** shim 库副本（`cp`：真复制，**不用** `ln`）
  mk_tree() {
    local d="$1" decl="$2" door="$3" land="$4"
    rm -rf "$d"
    mkdir -p "$d/docs" "$d/build/MilBridge" "$d/build/shims" \
             "$d/samples/WpfFeatureProbe" "$d/src/WpfGfx.Linux.Native/src" \
             "$d/src/WpfGfx.Linux.Native/bin"
    printf '# fixture register\n' > "$d/samples/WpfFeatureProbe/KNOWN-DEFECTS.md"
    printf '        { "user32.dll", null },\n' > "$d/build/shims/Win32ShimResolver.cs"
    if [ -f "$REAL_ROOT/$SO_DIRS/libwpfwin32.so" ]; then
      cp -p "$REAL_ROOT/$SO_DIRS/libwpfwin32.so" "$d/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"
    fi
    case "$decl" in
      decl) printf '# fixture docs\n| `D-G76` | ✅ **已在册裁定 = 有意降级**：shim 的 `GetSystemMetrics(SM_IMMENABLED=82)` 走 `default: return 0`，`imm32` 未映射、**禁止**补成 1；本移植 IME **零落点** |\n' \
              > "$d/docs/DECL.md";;
      prop) printf '# fixture docs\n- 要求：那一重**必须在册登记为"有意降级"**（`default: return 0`、`imm32`、`IMMENABLED=82`）——**未落地**。\n' \
              > "$d/docs/PROP.md";;
      report) printf '# fake report\n| `D-G76` | ✅ **已在册裁定 = 有意降级**：`GetSystemMetrics(SM_IMMENABLED=82)` 走 `default: return 0`，`imm32` 未映射 |\n' \
              > "$d/build/MilBridge/FAKE-report.md";;
    esac
    case "$door" in
      closed) printf 'int GetSystemMetrics(int nIndex)\n{\n    switch (nIndex) {\n        case SM_CXSCREEN: return 1280;\n        case SM_CYSCREEN: return 1024;\n        default: return 0;\n    }\n}\n' \
                > "$d/src/WpfGfx.Linux.Native/src/win32_core.c";;
      open)   printf 'int GetSystemMetrics(int nIndex)\n{\n    switch (nIndex) {\n        case SM_CXSCREEN: return 1280;\n        case SM_CYSCREEN: return 1024;\n        case SM_IMMENABLED: return 1;\n        default: return 0;\n    }\n}\n' \
                > "$d/src/WpfGfx.Linux.Native/src/win32_core.c";;
      nofunc) printf 'int NotGetSystemMetrics(void) { return 0; }\n' \
                > "$d/src/WpfGfx.Linux.Native/src/win32_core.c";;
    esac
    printf 'int probe(void) { return 0; }\n' > "$d/src/WpfGfx.Linux.Native/src/win32_other.c"
    [ "$land" = imm ] && printf 'HIMC p(HWND h) { return ImmGetContext(h); }\n' \
      > "$d/src/WpfGfx.Linux.Native/src/win32_ime.c"
  }

  local PLAIN="$SB/plain" DECL="$SB/decl" OPEN="$SB/open" OPENDECL="$SB/opendecl" \
        LAND="$SB/land" REPORT="$SB/report" PROP="$SB/prop" NOFUNC="$SB/nofunc" \
        NOANCH="$SB/noanch" EMPTY="$SB/empty"
  mk_tree "$PLAIN"  none   closed none      # = 现树形态（门巧合关着、没人登记）
  mk_tree "$DECL"   decl   closed none      # 夹具：补上声明 ⇒ 回绿
  mk_tree "$OPEN"   none   open   none      # 夹具：把门补成 1（**未来错误**）
  mk_tree "$OPENDECL" decl open   none      # 夹具：声明在、但门被补成 1 ⇒ **仍红**
  mk_tree "$LAND"   decl   closed imm       # 夹具：有落点却没映射 ⇒ 红 + 声明过期
  mk_tree "$REPORT" report closed none      # 声明只写在**报告**里 ⇒ 不许算
  mk_tree "$PROP"   prop   closed none      # 只有**提案** ⇒ 不许算
  mk_tree "$NOFUNC" decl   nofunc none      # 函数体抽不到 ⇒ NOINFO
  mk_tree "$NOANCH" decl   closed none      # 锚缺一件（缺陷册被移除）⇒ NOINFO
  rm -f "$NOANCH/samples/WpfFeatureProbe/KNOWN-DEFECTS.md"
  mkdir -p "$EMPTY"
  FIXENV="IMEL_ANCHORS=off IMEL_MIN_SRC=0 IMEL_MIN_LIBS=0"
  NOREG="IMEL_REG_DIRS=empty-regdir IMEL_REG_FILES=empty-regdir/none.md"

  # S01 现树形态（门巧合关着、零声明）⇒ **FAIL door-not-declared**（今天的红）
  run_case S01-no-declaration 1 "$PLAIN" $FIXENV
  has 'reason=[door-not-declared'; assert 'S01 没声明 ⇒ FAIL 且点名 door-not-declared' "$HAS"
  has 'landings=0'; assert 'S01 落点=0（原生侧一处都没有）' "$HAS"
  has 'sm82_nonzero=0'; assert 'S01 门今天确实是关的（sm82_nonzero=0）' "$HAS"

  # S02 **夹具：补上在册声明 ⇒ 回绿**
  run_case S02-declaration-added 0 "$DECL" $FIXENV
  has 'IME_LANDING=PASS'; assert 'S02 补声明 ⇒ PASS' "$HAS"
  has 'decl_hits=1'; assert 'S02 合格声明被数到（decl_hits=1）' "$HAS"

  # S03 **反极性：拆掉声明 ⇒ 回到红**（与 S02 成对：同一棵树、只动那一行）
  printf '# fixture docs\n（声明被拆掉）\n' > "$DECL/docs/DECL.md"
  run_case S03-declaration-removed 1 "$DECL" $FIXENV
  has 'reason=[door-not-declared'; assert 'S03 拆声明 ⇒ 回到 door-not-declared' "$HAS"

  # S04 **未来错误**：把门补成 1（`case SM_IMMENABLED: return 1;`）而 imm32 未映射 ⇒ 必须红并点名
  run_case S04-door-opened 1 "$OPEN" $FIXENV
  has 'reason=[door-not-declared imm32-unmapped-while-door-open'; assert 'S04 门被补成 1 ⇒ 点名 imm32-unmapped-while-door-open' "$HAS"
  has 'sm82_nonzero=1'; assert 'S04 门检测器看见"补成 1"（sm82_nonzero=1）' "$HAS"

  # S05 声明**在**、门却被补成 1 ⇒ **仍红**（声明不许给坏世界背书）
  run_case S05-declared-but-door-open 1 "$OPENDECL" $FIXENV
  has 'reason=[imm32-unmapped-while-door-open'; assert 'S05 有声明也不放过"门被补成 1"' "$HAS"

  # S06 有落点却没映射 ⇒ 红，且**声明过期**被点名
  run_case S06-landing-without-mapping 1 "$LAND" $FIXENV
  has 'reason=[landing-without-mapping'; assert 'S06 落点无落地库 ⇒ 点名 landing-without-mapping' "$HAS"
  has 'declaration-stale'; assert 'S06 声明自陈"零落点"而现场有落点 ⇒ 点名 declaration-stale' "$HAS"

  # S07 **自污染守卫**：声明只写在报告里 ⇒ 不许算（且必须可见）
  run_case S07-decl-only-in-report 1 "$REPORT" $FIXENV
  has 'reason=[door-not-declared'; assert 'S07 只写在报告里的声明 ⇒ 仍红（不自污染）' "$HAS"
  has 'IME_DECL_SKIP path=build/MilBridge/FAKE-report.md'; assert 'S07 报告里那行在 IME_DECL_SKIP 里可见' "$HAS"

  # S08 **提案 ≠ 声明**：只有"要求…必须登记为有意降级" ⇒ 不许算（且必须可见）
  run_case S08-proposal-not-declaration 1 "$PROP" $FIXENV
  has 'reason=[door-not-declared'; assert 'S08 只有提案 ⇒ 仍红' "$HAS"
  has 'IME_DECL_PROPOSAL path=docs/PROP.md'; assert 'S08 提案行在 IME_DECL_PROPOSAL 里可见' "$HAS"

  # S09 函数体抽不到 ⇒ NOINFO（门的开合**量不了**）
  run_case S09-sm-body-missing 2 "$NOFUNC" $FIXENV
  has 'reason=sm-body-not-found'; assert 'S09 抽不到函数体 ⇒ NOINFO reason=sm-body-not-found' "$HAS"

  # S10 登记面 0 件 ⇒ NOINFO（夹具树里那个目录**不存在**；金丝雀按同一配置在自己的沙箱里建得出声明）
  run_case S10-no-register-surface 2 "$PLAIN" $FIXENV $NOREG
  has 'reason=no-register-surface'; assert 'S10 登记面 0 件 ⇒ NOINFO reason=no-register-surface' "$HAS"

  # S11 库找不到 ⇒ NOINFO
  run_case S11-no-lib-found 2 "$DECL" $FIXENV IMEL_SO_DIRS=nonexistent-dir
  has 'reason=no-shim-lib-found'; assert 'S11 候选库一个都没有 ⇒ NOINFO reason=no-shim-lib-found' "$HAS"

  # S12 件数下限 ⇒ NOINFO
  run_case S12-too-few-files 2 "$DECL" IMEL_ANCHORS=off IMEL_MIN_SRC=9999
  has 'reason=too-few-files'; assert 'S12 件数低于下限 ⇒ NOINFO reason=too-few-files' "$HAS"

  # S13 `nm` 缺 ⇒ NOINFO
  run_case S13-nm-missing 2 "$DECL" $FIXENV IMEL_NM=/nonexistent/nm
  has 'reason=nm-missing'; assert 'S13 nm 缺 ⇒ NOINFO reason=nm-missing' "$HAS"

  # S14 解释器缺 ⇒ NOINFO
  run_case S14-python-missing 2 "$DECL" $FIXENV IMEL_PYTHON=/nonexistent/python3
  has 'reason=python-missing'; assert 'S14 解释器缺 ⇒ NOINFO reason=python-missing' "$HAS"

  # S15 **弄瞎**（有声明、门关着）⇒ 必须 NOINFO
  run_case S15-blinded 2 "$DECL" $FIXENV IMEL_TEST_BLIND=1
  has 'reason=scanner-blinded'; assert 'S15 弄瞎 ⇒ NOINFO（不绿、不冒充红）' "$HAS"

  # S16 金丝雀弄坏 ⇒ 必须 NOINFO
  run_case S16-canary-broken 2 "$DECL" $FIXENV IMEL_CANARY_BREAK=1
  has 'reason=canary-blind'; assert 'S16 金丝雀弄坏 ⇒ NOINFO reason=canary-blind' "$HAS"

  # S17 锚断（夹具树里缺 `KNOWN-DEFECTS.md`）⇒ NOINFO
  run_case S17-anchor-broken 2 "$NOANCH" IMEL_ANCHORS=strict IMEL_MIN_SRC=0
  has 'reason=anchor-missing'; assert 'S17 锚断 ⇒ NOINFO reason=anchor-missing' "$HAS"

  # S18 临时目录隔离（⚠️ `$DECL` 在 S03 里被拆过 ⇒ 先把那行**放回去**；顺带再证"装回 ⇒ 回绿"）
  printf '# fixture docs\n| `D-G76` | ✅ **已在册裁定 = 有意降级**：shim 的 `GetSystemMetrics(SM_IMMENABLED=82)` 走 `default: return 0`，`imm32` 未映射；本移植 IME **零落点** |\n' \
    > "$DECL/docs/DECL.md"
  run_case S18-tmp-isolated 0 "$DECL" $FIXENV
  has "IME_LANDING_TMPDIR=$SB/tmp/"; assert "S18 临时目录落在 \$TMPDIR=$SB/tmp 之下" "$HAS"

  # S19 生产路径（**真树**）：不许 NOINFO；金丝雀 ok；现树按设计 = FAIL door-not-declared
  run_case S19-live-tree LIVE "$REAL_ROOT" IMEL_ANCHORS=strict

  # S20 共享 /tmp 不许因**生产路径**留下垃圾
  local leak
  leak="$(find /tmp -maxdepth 1 -name 'imel-run.*' 2>/dev/null | sed -n '$=')"
  assert 'S20 共享 /tmp 上 imel-run.* 残留 = 0' "$( [ "${leak:-0}" = 0 ] && echo 1 || echo 0 )"

  say "IME_LANDING_SELFTEST_SELF self=$SELF sha16=$(self_sha16)"
  say "IME_LANDING_SELFTEST_ROSTER sandbox=$SB cases=$total pass=$pass fail=$fail not-as-expected=$nae tmpbase=$SB/tmp"
  if [ "$fail" -ne 0 ]; then
    say "IME_LANDING_SELFTEST_SANDBOX=$SB（保留供诊断；rm -rf 自行清理）"
    say "IME_LANDING_SELFTEST=FAIL total=$total pass=$pass fail=$fail"
    return 1
  fi
  rm -rf "$SB"
  say "IME_LANDING_SELFTEST=PASS total=$total pass=$pass fail=0"
  return 0
}

# ── 入口 ─────────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2;;
    --list-register) WANT_REG=1; shift;;
    --list-libs) WANT_LIBS=1; shift;;
    --debug-tmp) KEEP_TMP=1; shift;;
    --selftest) run_selftest; exit $?;;
    -h|--help) usage; exit 0;;
    *) say "IME_LANDING=NOINFO reason=bad-arg arg=$1"; exit 2;;
  esac
done
main_run
exit $?

#!/usr/bin/env bash
# nul-bytes-check.sh —— 「**被判二进制、本意是文本**的源件」的机器牙（**纯读、零 `dotnet`、秒级**）
#
# ═══════════════════════════════════════════════════════════════════════════════
# 【它防什么】缺陷册 `D-G82`（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2340`）：
#   源件里出现**真 NUL 字节** ⇒ `file` 判 `data`；`grep -n` **rc=0 但 stdout 恰好 0 字节**
#   （只往 stderr 吐一句「匹配到二进制文件」）⇒ **行号静默消失**。
#   本仓的**一切判据都建在「文件:行」上**（缺陷册、派单书、车道的判定点）⇒ 一个静默变成
#   「二进制」的源件会让**后续所有按行引用失效**，而且失效形态**不是报错、是少给信息**
#   （`#50` W83A 实测：`grep -c` 照样给计数、`grep -q` 照样"命中"、`grep -rlI` 干脆看不见它）。
#
#   现场：`build/DirectWrite.Linux/wic-shim/wic_proxy.c:289` 的注释把 `\0` 敲成了**实字节**（3 个），
#   已由 `#50` W83A 修掉（`f0d3d1501aebcd8c → 8dc634b9254295f4`，报告
#   `build/MilBridge/W83A-report.md` `9c90ef1d928863b5`）。**本件就是那颗"再有人敲进去就会响"的牙**：
#   `D-G82` 当时是"修了一次、没有牙"——任何人再敲进一个 NUL 进入源件，今天**没有任何东西会响**。
#
# 【判据（三态）】**0 = PASS**（白名单覆盖面里 0 件含 NUL）｜**1 = FAIL**（≥1 件 ⇒ **逐件点名**
#   路径 ＋ **首个 NUL 偏移** ＋ **所在行号** ＋ 计数）｜**2 = NOINFO**（**算不出来 ⇒ 绝不是绿**）。
#   ⚠️ `NOINFO` 一律 `rc=2`（与 `fp-inputs-hygiene-check.sh`／`shell-quote-trap-check.sh`／
#      `pipefail-sigpipe-check.sh` 的三态**刻意同形**）；`verify-all.sh` 对任何非 0 都判 ❌
#      ⇒ 「没声明」/「算不出」**永远不许当绿**（纪律 21/27/28）。
#   ⚠️ `NOINFO` 的**触发面**（逐条都在代码里，不是修辞）：解释器缺失、根目录缺失、`mktemp` 失败、
#      扫描器非 0 退出或写 stderr、**内置金丝雀失明**、`NULB_TEST_BLIND=1`（只给自测用）、
#      覆盖面为空、**一个字节都没读**、**锚断**（`verify-all.sh`／`wic_proxy.c` 不在覆盖面里，
#      或 `build/MilBridge/tools/*.sh` 件数 / 覆盖面总件数低于下限）—— 这一族的用意正是
#      `D-R4` 那族「**射程悄悄缩到零而它还是绿的**」。
#
# ─────────────────────────────────────────────────────────────────────────────
# 【覆盖面怎么写死的】声明**只有一份**：下面五个变量（`NULB_EXTS`/`NULB_NAMES`/`NULB_GLOBS`/
#   `NULB_SKIPDIRS`/`NULB_BINEXTS`）；python 侧**不另写一份**，由 bash 当 argv 传进去。
#   · **判**（进 `rc`）：扩展名 ∈ `NULB_EXTS`、或**基名** ∈ `NULB_NAMES`、或基名匹配 `NULB_GLOBS`。
#   · **不扫**（各自**分类计数 ＋ 可逐条列出**）：目录名 ∈ `NULB_SKIPDIRS` 的整棵子树；
#     扩展名 ∈ `NULB_BINEXTS`（按定义就是二进制）；**无扩展名**件；**其余未认领扩展名**件。
#     ⚠️ **判据外**的件里含 NUL 的（无扩展名件 ＋ 未认领扩展名件），本件**只点名不判红**
#        （`NULBYTES_DIAG` ＋ 机读行里的 `diag_noext_nonelf=`（无扩展名且**不是** ELF 头的那类）／`diag_otherext_nul=`）—— 理由如实写：
#        判它会把"真的二进制（无扩展名 ELF / 未认领的二进制扩展名）"误伤成红；**但不许看不见**
#        （`D-G84` 同族：「看不见 ≠ 没发生」）。这条**边界是明的**：本件的绿**只**等于
#        「声明覆盖面里 0 件含 NUL」，**不等于**"全仓 0 件含 NUL"；`binext` 类按定义就是二进制，
#        不列（列出来是噪音）。主控若要把这一格也判红，改这一处即可（一行）。
#   · ⚠️ `.log` 的取舍**写死在声明里、且纳入**（`#50` W83A 把它留成 `NOINFO`）：现场 14 件 `.log`、
#     NUL **全为 0**（本件实测）⇒ 纳入后这一格**有读数**，不再是空白。代价如实记在文件里：
#     将来若某条车道产出**含 NUL 的日志**，本步会红。**本件不静默豁免** —— 那时该判"真出了
#     二进制日志"（红是对的）还是"把 `.log` 移出白名单"（改声明）**由主控裁定**。
#   · ⚠️ `upstream/**` **不扫**（vendored 的 dotnet/wpf 镜像 ⇒ 不是本仓自有代码；`D-G82` 的
#     定义域是"本仓自有代码的源卫生"）⇒ 该域**未测**，如实登记在报告 §7。
#
# 【覆盖面必须能被复核，所以本件打印它】`NULBYTES_SCOPE`（声明件数＋根）／`_EXTS`／`_NAMES`／
#   `_GLOBS`／`_SKIPDIRS`／`_BINEXTS`（**逐字清单**）／`NULBYTES_ROSTER`（判了多少件、多少字节）／
#   `NULBYTES_SCANEXT`（判的件按扩展名分布）／`NULBYTES_NOTSCANNED`（**没扫什么**：三类件数 ＋
#   未认领扩展名分布）／`NULBYTES_SKIPDIRNAME`（被排除的目录按名字分组）。
#   要看**逐条**清单（可复算）：`--list`（覆盖面每一件）／`--list-notscanned`（没扫的每一件）／
#   `--list-skipped-dirs`（被排除的每一个目录）。
#
# 【内置金丝雀（**生产路径自己跑**，不是只跑在自测里）】每次真跑之前，本件在**自己的 `TMPDIR`** 下
#   造 4 个夹具并**要求**扫描器给出 `hits=1 ∧ path=ctrl_nul.c ∧ off=17 ∧ line=3 ∧ scanned≥2`：
#   `ctrl_nul.c`（含 1 个 NUL：偏移 17、第 3 行）／`ctrl_clean.c`（干净）／`ctrl_nul.png`（含同一
#   NUL，但扩展名不在白名单）／`obj/ctrl_nul.c`（含同一 NUL，但在排除目录里）。
#   ⇒ 一次钉三件事：①扫描器**没瞎**（含 NUL 的件真能命中）；②偏移/行号**算得对**；
#   ③**声明真按声明走**（`.png` 那份与 `obj/` 那份**必须不被判**）。
#   金丝雀不符 ⇒ **`NOINFO reason=canary-blind`**（不绿、也不冒充红）。`NULB_CANARY_BREAK=1`
#   只给自测用：把 NUL 放进白名单外的夹具 ⇒ 金丝雀**必须**报失明（证明这条断言是活的）。
#
# 【只读】生产路径**只读**：`open(...,'rb')` 分块读（1 MiB/块，**无大小上限**），不写、不删、
#   不改 mtime、不碰被测树；所有负极构造（注入/还原）只在 `--selftest` 的沙箱里做。
#
# 【成本】单趟 ≈ 0.3–1 s（现场 1167 件 / 249.8 MB）、零 `dotnet`、零世代成本
#   （不动九位/`GEN_KEYS`/`known-red.json`/不动被测树）。
#   ⚠️ 本件**不在** `build/close-wave.sh` 的 `fp_inputs()` 覆盖面里（机械核：覆盖面 147 件、
#      本件 0 命中）⇒ **新建本件不动 `inputs_fp`**；**接线**时若按仓内惯例把判据件纳入覆盖面
#      （纪律「改判据必须看得见」），那一改**会**动 `inputs_fp` ⇒ 必须安排在 `IN_FP_0` 采样之前。
#      见 `build/MilBridge/W97A-report.md` §5/§6。
#
# 用法：
#   nul-bytes-check.sh [--root DIR] [--list] [--list-notscanned] [--list-skipped-dirs] [--debug-tmp]
#   nul-bytes-check.sh --selftest
# 环境（自测/沙箱用；生产不需要设）：
#   NULB_ROOT / NULB_PYTHON / NULB_ANCHORS=strict|off / NULB_MIN_FILES / NULB_MIN_TOOLS /
#   NULB_TEST_BLIND / NULB_CANARY_BREAK / NULB_TMPDIR / NULB_KEEP_TMP
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ⚠️ 必须**绝对**路径：`--selftest` 会 `cd` 进沙箱再以 `bash "$SELF"` 拉起子进程（相对路径在那里 rc=127）
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
REAL_ROOT="$(cd "$HERE/../../.." && pwd)"

ROOT="${NULB_ROOT:-$REAL_ROOT}"
PYBIN="${NULB_PYTHON:-python3}"
ANCHORS="${NULB_ANCHORS:-strict}"          # strict | off（off 只给 --selftest 的合成夹具用）
MIN_FILES="${NULB_MIN_FILES:-800}"         # 覆盖面总件数下限（现场 1167）
MIN_TOOLS="${NULB_MIN_TOOLS:-15}"          # build/MilBridge/tools/*.sh 件数下限（现场 29）
BLIND="${NULB_TEST_BLIND:-0}"              # 只给 --selftest 用：故意弄瞎扫描器
CANARY_BREAK="${NULB_CANARY_BREAK:-0}"     # 只给 --selftest 用：故意让金丝雀失效
KEEP_TMP="${NULB_KEEP_TMP:-0}"
TMPBASE="${NULB_TMPDIR:-${TMPDIR:-/tmp}}"
WANT_LIST=0; WANT_NOTSCAN=0; WANT_SKIPDIRS=0; DEBUG_TMP=0

# ── 覆盖面声明（**唯一一份**；改这里 = 改判据 ⇒ 必须安排在 `IN_FP_0` 采样之前）──────────
NULB_EXTS_ML='.c .h .cs .sh .py .md .props .targets .tsv .csproj .sln .txt .xaml .xml .json
              .yml .yaml .config .cmake .inc .def .rc .manifest .in .patch .diff .log
              .editorconfig .tpl .template .mk .mak .ps1 .s .reference'
NULB_BINEXTS_ML='.png .jpg .jpeg .gif .webp .bmp .ico .tif .tiff .ttf .otf .woff .woff2
                 .so .dll .a .o .obj .pyc .snk .nupkg .zip .gz .xz .bz2 .pdf .bin .stream
                 .dat .db .sqlite .exe .pdb .class .jar .wasm .xwd .wav .mp3 .mp4 .webm'
NULB_NAMES='.gitignore .gitattributes Makefile SHA256SUMS .wave-done'
NULB_GLOBS='*.bak-*'
NULB_SKIPDIRS='upstream .git node_modules .artifacts obj bin __pycache__ .vs TestResults'
# 压成单行（bash 把换行当分隔符；压平后传 argv 更稳、打印也更整齐）
NULB_EXTS="$(printf '%s' "$NULB_EXTS_ML" | tr -s '[:space:]' ' ')"
NULB_BINEXTS="$(printf '%s' "$NULB_BINEXTS_ML" | tr -s '[:space:]' ' ')"

say() { printf '%s\n' "$*"; }
self_sha16() { sha256sum "$SELF" | cut -c1-16; }
usage() {
  cat <<'USAGE'
nul-bytes-check.sh —— 「被判二进制、本意是文本」的源件牙（D-G82）
  nul-bytes-check.sh [--root DIR] [--list] [--list-notscanned] [--list-skipped-dirs] [--debug-tmp]
  nul-bytes-check.sh --selftest
三态：rc=0 PASS ／ rc=1 FAIL（逐件点名）／ rc=2 NOINFO（**不是绿**）
USAGE
}

# ── 扫描器（python3；**只报事实、不定态**：状态与 rc 由 bash 决定）────────────────────
# 产出 TSV：`K<TAB>key<TAB>value` ／ `HIT<TAB>path<TAB>off<TAB>line<TAB>n<TAB>bytes`
#          ／ `SCANEXT|OTHEREXT|BINEXT|SKIPDIRNAME<TAB>key<TAB>n`
#          ／ `DIAG<TAB>kind<TAB>path<TAB>detail` ／ `SKIPDIR<TAB>path` ／ `NOTSCAN<TAB>kind<TAB>path<TAB>ext`
#          ／ `ERR<TAB>path<TAB>reason`
py_scan() {   # $1=root $2=out.tsv $3=py.err ; 返回 python 的 rc
  local root="$1" out="$2" errf="$3"
  : > "$out"; : > "$errf"
  "$PYBIN" - "$root" "$NULB_EXTS" "$NULB_NAMES" "$NULB_GLOBS" "$NULB_SKIPDIRS" \
           "$NULB_BINEXTS" "$BLIND" > "$out" 2> "$errf" <<'PY_NULB'
import fnmatch, os, sys

root   = sys.argv[1]
exts   = {e.lower() for e in sys.argv[2].split()}
names  = set(sys.argv[3].split())
globs  = sys.argv[4].split()
skipts = set(sys.argv[5].split())
binext = {e.lower() for e in sys.argv[6].split()}
blind  = sys.argv[7] == '1'
CH = 1 << 20
roster_out  = os.environ.get('NULB_ROSTER_OUT') or ''
notscan_out = os.environ.get('NULB_NOTSCAN_OUT') or ''
skipdir_out = os.environ.get('NULB_SKIPDIR_OUT') or ''
rf = open(roster_out, 'w') if roster_out else None
nf = open(notscan_out, 'w') if notscan_out else None
sf = open(skipdir_out, 'w') if skipdir_out else None

def emit(tag, *rest):
    sys.stdout.write('\t'.join([tag] + [str(x) for x in rest]) + '\n')

def nul_info(path):
    # 分块读，返回 (nul 数, 首个 NUL 偏移(-1=无), 读到的字节数)；无大小上限
    n = 0; first = -1; pos = 0
    with open(path, 'rb') as fh:
        while True:
            b = fh.read(CH)
            if not b:
                break
            c = b.count(0)
            if c:
                n += c
                if first < 0:
                    first = pos + b.index(0)
            pos += len(b)
    return n, first, pos

def line_of(path, off):
    # 首个 NUL 所在行号（1-based）：只重读它之前那一段（命中件极少，便宜）
    nl = 1; left = off
    with open(path, 'rb') as fh:
        while left > 0:
            b = fh.read(min(CH, left))
            if not b:
                break
            nl += b.count(10)
            left -= len(b)
    return nl

def classify(name):
    ext = os.path.splitext(name)[1].lower()
    if name in names or (ext and ext in exts) or any(fnmatch.fnmatch(name, g) for g in globs):
        return 'scan', ext
    if ext == '':
        return 'noext', ext
    if ext in binext:
        return 'binext', ext
    return 'otherext', ext

files = 0; total = 0; hits = 0; skipdirs_n = 0; errors = 0
diag_nonelf = 0; diag_otherext = 0; tools_sh = 0
class_n = {'binext': 0, 'otherext': 0, 'noext': 0}
other_n = {}; bin_n = {}; scanext_n = {}; skipname_n = {}
have = {'verify-all.sh': 0, 'build/DirectWrite.Linux/wic-shim/wic_proxy.c': 0}

for r, dirs, fs in os.walk(root):
    for d in sorted(d for d in dirs if d in skipts):
        p = os.path.join(r, d)
        skipdirs_n += 1
        skipname_n[d] = skipname_n.get(d, 0) + 1
        if sf:
            sf.write(os.path.relpath(p, root) + '\n')
    dirs[:] = sorted(d for d in dirs if d not in skipts)
    for f in sorted(fs):
        p = os.path.join(r, f)
        rel = os.path.relpath(p, root)
        kind, ext = classify(f)
        if rel in have:
            have[rel] = 1
        if rel.startswith('build/MilBridge/tools/') and f.endswith('.sh'):
            tools_sh += 1
        if kind == 'scan':
            files += 1
            if rf:
                rf.write(rel + '\n')
            if blind:            # 弄瞎：只登记件数，不读内容（bash 侧据此判 NOINFO）
                continue
            try:
                n, first, size = nul_info(p)
            except OSError as e:
                errors += 1
                emit('ERR', rel, str(e))
                continue
            total += size
            key = ext if ext else '(by-name)'
            scanext_n[key] = scanext_n.get(key, 0) + 1
            if n:
                hits += 1
                emit('HIT', rel, first, line_of(p, first), n, size)
                if nf:
                    nf.write(rel + '\n')
        else:
            class_n[kind] += 1
            if nf:
                nf.write(rel + '\n')
            emit('NOTSCAN', kind, rel, ext)
            if kind == 'otherext':
                other_n[ext] = other_n.get(ext, 0) + 1
            elif kind == 'binext':
                bin_n[ext] = bin_n.get(ext, 0) + 1
            # DIAG（**只报不判**）：判据外的件（无扩展名 / 未认领扩展名）里也有 NUL ⇒
            #   **必须看得见**（`D-G84` 同族：「看不见 ≠ 没发生」）。`binext` 不列（按定义就是二进制，
            #   列出来是噪音）。判红会把真二进制误伤 ⇒ 本件只点名、不进 rc（边界写在报告里）。
            if kind in ('noext', 'otherext') and not blind:
                try:
                    n, first, size = nul_info(p)
                except OSError:
                    n, first = 0, -1
                if n:
                    elf = False
                    if kind == 'noext':
                        try:
                            with open(p, 'rb') as fh:
                                elf = fh.read(4) == b'\x7fELF'
                        except OSError:
                            elf = False
                        if not elf:
                            diag_nonelf += 1
                    else:
                        diag_otherext += 1
                    emit('DIAG', kind + '-nul', rel,
                         'n=%d first_off=%d elf_head=%d' % (n, first, 1 if elf else 0))

emit('K', 'blind', 1 if blind else 0)
emit('K', 'files', files)
emit('K', 'bytes', total)
emit('K', 'hits', hits)
emit('K', 'errors', errors)
emit('K', 'skipdir_dirs', skipdirs_n)
emit('K', 'noext', class_n['noext'])
emit('K', 'otherext', class_n['otherext'])
emit('K', 'binext', class_n['binext'])
emit('K', 'diag_nonelf', diag_nonelf)
emit('K', 'diag_otherext', diag_otherext)
emit('K', 'tools_sh', tools_sh)
emit('K', 'have_verify_all', have['verify-all.sh'])
emit('K', 'have_wic_proxy', have['build/DirectWrite.Linux/wic-shim/wic_proxy.c'])
for k in sorted(scanext_n):
    emit('SCANEXT', k, scanext_n[k])
for k in sorted(other_n):
    emit('OTHEREXT', k, other_n[k])
for k in sorted(bin_n):
    emit('BINEXT', k, bin_n[k])
for k in sorted(skipname_n):
    emit('SKIPDIRNAME', k, skipname_n[k])
for fh in (rf, nf, sf):
    if fh:
        fh.close()
PY_NULB
}

# ── 解析 TSV（**while-read 吃文件**，不走管道 ⇒ 不碰 pipefail/SIGPIPE 那族坑）─────────
parse_scan() {   # $1=tsv ; 结果写进全局 P_*
  P_FILES=0; P_BYTES=0; P_HITS=0; P_ERRORS=0; P_SKIPDIRS=0; P_NOEXT=0; P_OTHEREXT=0
  P_BINEXT=0; P_DIAGNONELF=0; P_DIAGOTHER=0; P_TOOLSSH=0; P_HAVEVA=0; P_HAVEWP=0; P_BLIND=0
  P_HITROWS=''; P_DIAGROWS=''; P_ERROWS=''; P_OTHERLIST=''; P_BINLIST=''
  P_SCANEXT=''; P_SKIPNAMES=''
  local tag a b c d e
  while IFS=$'\t' read -r tag a b c d e; do
    case "$tag" in
      K) case "$a" in
           files) P_FILES="$b";; bytes) P_BYTES="$b";; hits) P_HITS="$b";;
           errors) P_ERRORS="$b";; skipdir_dirs) P_SKIPDIRS="$b";;
           noext) P_NOEXT="$b";; otherext) P_OTHEREXT="$b";; binext) P_BINEXT="$b";;
           diag_nonelf) P_DIAGNONELF="$b";; diag_otherext) P_DIAGOTHER="$b";;
           tools_sh) P_TOOLSSH="$b";; have_verify_all) P_HAVEVA="$b";;
           have_wic_proxy) P_HAVEWP="$b";; blind) P_BLIND="$b";;
         esac;;
      HIT) P_HITROWS="${P_HITROWS}${a}|${b}|${c}|${d}|${e}"$'\n';;
      DIAG) P_DIAGROWS="${P_DIAGROWS}${a}|${b}|${c}"$'\n';;
      ERR) P_ERROWS="${P_ERROWS}${a}|${b}"$'\n';;
      OTHEREXT) P_OTHERLIST="${P_OTHERLIST}${a}=${b} ";;
      BINEXT) P_BINLIST="${P_BINLIST}${a}=${b} ";;
      SCANEXT) P_SCANEXT="${P_SCANEXT}${a}=${b} ";;
      SKIPDIRNAME) P_SKIPNAMES="${P_SKIPNAMES}${a}:${b} ";;
    esac
  done < "$1"
}

emit_scope() {
  local n_ext n_names n_globs n_skip n_bin
  n_ext=$(printf '%s\n' $NULB_EXTS | sed -n '$=')
  n_names=$(printf '%s\n' $NULB_NAMES | sed -n '$=')
  n_globs=$(printf '%s\n' $NULB_GLOBS | sed -n '$=')
  n_skip=$(printf '%s\n' $NULB_SKIPDIRS | sed -n '$=')
  n_bin=$(printf '%s\n' $NULB_BINEXTS | sed -n '$=')
  say "NULBYTES_SCOPE exts=$n_ext names=$n_names globs=$n_globs skipdirs=$n_skip binexts=$n_bin root=$ROOT anchors=$ANCHORS min_files=$MIN_FILES min_tools=$MIN_TOOLS"
  say "NULBYTES_SCOPE_EXTS $NULB_EXTS"
  say "NULBYTES_SCOPE_NAMES $NULB_NAMES"
  say "NULBYTES_SCOPE_GLOBS $NULB_GLOBS"
  say "NULBYTES_SCOPE_SKIPDIRS $NULB_SKIPDIRS"
  say "NULBYTES_SCOPE_BINEXTS $NULB_BINEXTS"
}

# 造金丝雀夹具（生产路径自带；`NULB_CANARY_BREAK=1` 时故意把 NUL 只放进白名单外的夹具）
build_canary() {   # $1=canary 根
  # 四个夹具（含 NUL 那份是 `line1\nline2\nline3<0x00>tail\n` ⇒ 偏移 17、第 3 行）
  local c="$1"
  rm -rf "$c"; mkdir -p "$c/obj"
  printf 'line1\nline2\nline3\0tail\n' > "$c/ctrl_nul.png"      # 白名单外扩展名 ⇒ 必须**不被判**
  printf 'line1\nline2\nline3\0tail\n' > "$c/obj/ctrl_nul.c"    # 排除目录里 ⇒ 必须**不被判**
  printf 'line1\nline2\nline3\nclean\n' > "$c/ctrl_clean.c"     # 干净件
  if [ "$CANARY_BREAK" = 1 ]; then
    printf 'line1\nline2\nline3\nclean\n' > "$c/ctrl_nul.c"     # 只给自测：白名单内那份**故意干净**
  else
    printf 'line1\nline2\nline3\0tail\n' > "$c/ctrl_nul.c"      # 判据内那份：含 1 个 NUL
  fi
}

cleanup_tmp() { [ "$KEEP_TMP" = 1 ] || rm -rf "$T"; }

# ═══════════════════════════════════════════════════════════════════════════════
# 生产路径
# ═══════════════════════════════════════════════════════════════════════════════
main_run() {
  emit_scope
  if ! command -v "$PYBIN" >/dev/null 2>&1; then
    say "NULBYTES_SELF path=$SELF sha16=$(self_sha16)"
    say "NULBYTES=NOINFO reason=python-missing py=$PYBIN"; return 2
  fi
  if [ ! -d "$ROOT" ]; then
    say "NULBYTES=NOINFO reason=root-missing root=$ROOT"; return 2
  fi
  T="$(mktemp -d "$TMPBASE/nulb-run.XXXXXX")" || { say 'NULBYTES=NOINFO reason=mktemp-failed'; return 2; }
  trap cleanup_tmp EXIT
  say "NULBYTES_TMPDIR=$T"

  # ① 金丝雀（先证明扫描器没瞎，再信它的 0 命中）
  build_canary "$T/canary"
  py_scan "$T/canary" "$T/can.tsv" "$T/can.err"; local can_rc=$?
  parse_scan "$T/can.tsv"
  local CAN_HITS="$P_HITS" CAN_FILES="$P_FILES" CAN_PATH='' CAN_OFF='' CAN_LINE=''
  local row
  row="${P_HITROWS%%$'\n'*}"
  if [ -n "$row" ]; then
    CAN_PATH="${row%%|*}"; local r2="${row#*|}"; CAN_OFF="${r2%%|*}"
    r2="${r2#*|}"; CAN_LINE="${r2%%|*}"
  fi
  local can_reason=''
  if [ "$can_rc" != 0 ] || [ -s "$T/can.err" ]; then can_reason="canary-scanner-error rc=$can_rc"
  elif [ "$CAN_HITS" != 1 ]; then can_reason="hits=$CAN_HITS want=1"
  elif [ "$CAN_PATH" != 'ctrl_nul.c' ]; then can_reason="path=$CAN_PATH want=ctrl_nul.c"
  elif [ "$CAN_OFF" != 17 ]; then can_reason="off=$CAN_OFF want=17"
  elif [ "$CAN_LINE" != 3 ]; then can_reason="line=$CAN_LINE want=3"
  elif [ "$CAN_FILES" -lt 2 ]; then can_reason="scanned=$CAN_FILES want>=2"
  fi

  # ② 真扫（覆盖面清单/未扫清单按需落盘）
  local ro='' no='' so=''
  [ "$WANT_LIST" = 1 ] && ro="$T/roster.txt"
  [ "$WANT_NOTSCAN" = 1 ] && no="$T/notscan.txt"
  [ "$WANT_SKIPDIRS" = 1 ] && so="$T/skipdirs.txt"
  NULB_ROSTER_OUT="$ro" NULB_NOTSCAN_OUT="$no" NULB_SKIPDIR_OUT="$so" \
    py_scan "$ROOT" "$T/scan.tsv" "$T/py.err"
  local py_rc=$?
  parse_scan "$T/scan.tsv"
  local py_err_log=''
  [ -s "$T/py.err" ] && py_err_log="$(first_line_of_file "$T/py.err")"

  # ③ 定态（顺序 = 具体的 NOINFO 原因优先；最后才允许 PASS/FAIL）
  local STATE=PASS RC=0 REASON=''
  if [ "$py_rc" != 0 ] || [ -n "$py_err_log" ]; then
    STATE=NOINFO; REASON="scanner-error py_rc=$py_rc py_err=$py_err_log"
  elif [ "$P_BLIND" = 1 ]; then
    STATE=NOINFO; REASON='scanner-blinded（NULB_TEST_BLIND=1 ⇒ 扫描器不读内容 ⇒ 读数无信息）'
  elif [ -n "$can_reason" ]; then
    STATE=NOINFO; REASON="canary-blind（内置金丝雀不符：$can_reason ⇒ 扫描器失明或声明没被遵守）"
  elif [ "$P_ERRORS" != 0 ]; then
    STATE=NOINFO; REASON="scan-errors n=$P_ERRORS"
  elif [ "$P_FILES" -eq 0 ]; then
    STATE=NOINFO; REASON='empty-roster（覆盖面 0 件 ⇒ 不是"干净"，是"没测"）'
  elif [ "$P_BYTES" -eq 0 ]; then
    STATE=NOINFO; REASON='zero-bytes-read（覆盖面非空但一个字节都没读 ⇒ 读数无信息）'
  elif [ "$P_FILES" -lt "$MIN_FILES" ]; then
    # 件数下限：**与锚无关**的防缩水守卫（合成夹具靠 `NULB_MIN_FILES=0` 关掉它）
    STATE=NOINFO; REASON="too-few-files files=$P_FILES min=$MIN_FILES"
  elif [ "$ANCHORS" = strict ]; then
    # 仓内锚（**本仓专有**；别的树用 `NULB_ANCHORS=off`）
    if [ "$P_HAVEVA" != 1 ]; then STATE=NOINFO; REASON='anchor-missing:verify-all.sh（射程缩水 ⇒ 不许绿）'
    elif [ "$P_HAVEWP" != 1 ]; then STATE=NOINFO; REASON='anchor-missing:build/DirectWrite.Linux/wic-shim/wic_proxy.c（D-G82 的宿主件不在覆盖面 ⇒ 射程缩水）'
    elif [ "$P_TOOLSSH" -lt "$MIN_TOOLS" ]; then STATE=NOINFO; REASON="too-few-tools n=$P_TOOLSSH min=$MIN_TOOLS"
    fi
  fi
  if [ "$STATE" = PASS ] && [ "$P_HITS" -gt 0 ]; then STATE=FAIL; REASON=''; fi

  # ④ 机读行 + 逐件点名
  say "NULBYTES_ROSTER files=$P_FILES bytes=$P_BYTES tools_sh=$P_TOOLSSH skipdir_dirs=$P_SKIPDIRS"
  say "NULBYTES_SCANEXT ${P_SCANEXT% }"
  say "NULBYTES_NOTSCANNED binext=$P_BINEXT otherext=$P_OTHEREXT noext=$P_NOEXT diag_noext_nonelf=$P_DIAGNONELF diag_otherext_nul=$P_DIAGOTHER binext_all=${P_BINLIST% } otherext_all=${P_OTHERLIST% }"
  say "NULBYTES_SKIPDIRNAME ${P_SKIPNAMES% }"
  if [ -z "$can_reason" ]; then
    say "NULBYTES_CANARY=ok hits=$CAN_HITS path=$CAN_PATH off=$CAN_OFF line=$CAN_LINE scanned=$CAN_FILES"
  else
    say "NULBYTES_CANARY=BLIND reason=$can_reason"
  fi
  local dg n_show=0 dk dp dd
  while IFS= read -r dg; do
    [ -n "$dg" ] || continue
    n_show=$((n_show + 1))
    if [ "$n_show" -le 40 ]; then
      dk="${dg%%|*}"; dg="${dg#*|}"; dp="${dg%%|*}"; dd="${dg#*|}"
      say "NULBYTES_DIAG kind=$dk path=$dp detail=${dd//|/ }"
    fi
  done <<< "$P_DIAGROWS"
  [ "$n_show" -gt 40 ] && say "NULBYTES_DIAG_TRUNCATED printed=40 rest=$((n_show - 40))"
  local h p off ln cnt by
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    p="${h%%|*}"; h="${h#*|}"; off="${h%%|*}"; h="${h#*|}"
    ln="${h%%|*}"; h="${h#*|}"; cnt="${h%%|*}"; by="${h##*|}"
    say "NULBYTES_HIT path=$p offset=$off line=$ln n=$cnt bytes=$by"
  done <<< "$P_HITROWS"
  local e
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    say "NULBYTES_SCANERR path=${e%%|*} reason=${e#*|}"
  done <<< "$P_ERROWS"

  case "$STATE" in
    PASS) RC=0; say "NULBYTES=PASS files=$P_FILES hits=0 bytes=$P_BYTES skipdir_dirs=$P_SKIPDIRS binext=$P_BINEXT otherext=$P_OTHEREXT noext=$P_NOEXT diag_noext_nonelf=$P_DIAGNONELF diag_otherext_nul=$P_DIAGOTHER canary=ok";;
    FAIL) RC=1; say "NULBYTES=FAIL hits=$P_HITS files=$P_FILES bytes=$P_BYTES（逐件点名见上面 NULBYTES_HIT 行）";;
    *)    RC=2; say "NULBYTES=NOINFO reason=$REASON files=$P_FILES hits=$P_HITS";;
  esac
  say "NULBYTES_SELF path=$SELF sha16=$(self_sha16)"
  if [ "$WANT_LIST" = 1 ]; then
    say "NULBYTES_LIST_BEGIN files=$( [ -f "$T/roster.txt" ] && wc -l < "$T/roster.txt" || echo 0 )"
    cat "$T/roster.txt" 2>/dev/null
    say "NULBYTES_LIST_END"
  fi
  if [ "$WANT_NOTSCAN" = 1 ]; then
    say "NULBYTES_NOTSCAN_LIST_BEGIN"
    cat "$T/notscan.txt" 2>/dev/null
    say "NULBYTES_NOTSCAN_LIST_END"
  fi
  if [ "$WANT_SKIPDIRS" = 1 ]; then
    say "NULBYTES_SKIPDIRS_LIST_BEGIN"
    cat "$T/skipdirs.txt" 2>/dev/null
    say "NULBYTES_SKIPDIRS_LIST_END"
  fi
  return "$RC"
}

first_line_of_file() { sed -n '1p' "$1" 2>/dev/null; }

# ═══════════════════════════════════════════════════════════════════════════════
# 自测（两极化；自带 TMPDIR；含「注入 1 个 NUL ⇒ 必红」与「还原 ⇒ 回绿」的成对读数）
# ═══════════════════════════════════════════════════════════════════════════════
run_selftest() {
  local inner="${NULB_ST_INNER:-0}"
  if [ "$inner" != 1 ]; then
    # 【`D-G41` 判据件自证】本件在**自测期间**被改写 ⇒ 本趟读数**不可归因**（NOINFO，rc=2 收尾）
    local s0 s1 out rc
    s0="$(self_sha16)"
    say "ST_ATTEST=OPEN self=$SELF sha16=$s0"
    out="$(NULB_ST_INNER=1 bash "$SELF" --selftest 2>&1)"; rc=$?
    printf '%s\n' "$out"
    s1="$(self_sha16)"
    if [ "$s1" != "$s0" ]; then
      say "ST_ATTEST=NOINFO reason=self-rewritten-during-selftest（本件在自测期间被改写 ⇒ 上面的读数不可归因）self=$SELF sha0=$s0 sha1=$s1 inner_rc=$rc"
      return 2
    fi
    say "ST_ATTEST=PASS self=$SELF sha16=$s0（自测期间本件未变 ⇒ 读数可归因）"
    return "$rc"
  fi
  if ! command -v "$PYBIN" >/dev/null 2>&1; then
    say "NULBYTES_SELFTEST=NOINFO reason=premise-unmet:python-missing py=$PYBIN（自测的仪器前提不成立）"
    return 2
  fi
  local SB
  SB="$(mktemp -d "$TMPBASE/nulb-selftest.XXXXXX")" || { say 'NULBYTES_SELFTEST=FAIL reason=mktemp-failed'; return 1; }
  mkdir -p "$SB/tmp"
  local pass=0 fail=0 total=0 nae=0
  local CUR_OUT='' CUR_RC='' CUR_STATE='' CUR_HITS='' CUR_WANT=''

  run_case() {   # $1=id $2=want(0|1|2|LIVE) $3=tree [额外 env 赋值...]；可选 `RC_FLAGS=…` 传旗标
    local id="$1" want="$2" tree="$3"; shift 3
    local -a envs=("NULB_TMPDIR=$SB/tmp" "$@")
    local -a args=(--root "$tree")
    local fl="${RC_FLAGS:-}"; RC_FLAGS=''      # 读一次就清（免得泄漏到下一例）
    [ -n "$fl" ] && args+=($fl)
    CUR_WANT="$want"
    CUR_OUT="$(env "${envs[@]}" bash "$SELF" "${args[@]}" 2>&1)"; CUR_RC=$?
    CUR_STATE="$(printf '%s\n' "$CUR_OUT" | sed -n 's/^NULBYTES=\([A-Z]*\) .*/\1/p' | sed -n '1p')"
    # ⚠️ `hits=` 在 PASS 行里不紧跟状态词（`PASS files=… hits=0`）⇒ 必须**就地取**，
    #    不能写成 `^NULBYTES=[A-Z]* hits=`（那样只有 FAIL 行匹配 ⇒ `hits` 恒空，S15 曾因此假红）
    CUR_HITS="$(printf '%s\n' "$CUR_OUT" | sed -n 's/^NULBYTES=[A-Z]* .*hits=\([0-9]*\).*/\1/p' | sed -n '1p')"
    local ok='no' why=''
    if [ "$want" = LIVE ]; then
      # 生产路径趟：不许 NOINFO；**状态与 rc 必须自洽**（rc=0 ⇒ hits=0；rc=1 ⇒ hits>0）；金丝雀须 ok
      case "$CUR_RC" in
        0) if [ "${CUR_HITS:-x}" = 0 ]; then ok=yes; else why="rc=0 但 hits=${CUR_HITS:-?}"; fi;;
        1) case "${CUR_HITS:-0}" in 0) why='rc=1 但 hits=0';; *) ok=yes;; esac;;
        *) why="rc=$CUR_RC（生产路径不许 NOINFO/异常）";;
      esac
      case "$CUR_OUT" in *'NULBYTES_CANARY=ok'*) ;; *) ok=no; why="$why canary!=ok";; esac
    else
      [ "$CUR_RC" = "$want" ] && ok=yes || why="rc=$CUR_RC want=$want"
    fi
    total=$((total + 1))
    if [ "$ok" = yes ]; then pass=$((pass + 1)); else
      fail=$((fail + 1))
      if [ "$want" != LIVE ] && [ "$CUR_RC" != "$want" ]; then nae=$((nae + 1)); fi
    fi
    printf 'SELFTEST CASE %-24s = %s rc=%s want=%s state=%s hits=%s %s\n' \
           "$id" "$( [ "$ok" = yes ] && echo PASS || echo FAIL )" "$CUR_RC" "$want" \
           "${CUR_STATE:-none}" "${CUR_HITS:-none}" "$why"
  }
  has() {   # $1=子串 ⇒ HAS=1/0（不用管道进 if ⇒ 不碰 SIGPIPE 那族坑）
    case "$CUR_OUT" in *"$1"*) HAS=1;; *) HAS=0;; esac
  }
  assert() {   # $1=描述 $2=1/0
    total=$((total + 1))
    if [ "$2" = 1 ]; then pass=$((pass + 1)); printf 'SELFTEST ASSERT %-52s = PASS\n' "$1"
    else fail=$((fail + 1)); printf 'SELFTEST ASSERT %-52s = FAIL\n' "$1"; fi
  }

  # ── 夹具树（合成）：白名单 4 件 ＋ 白名单外扩展名 1 件 ＋ 未认领扩展名 1 件 ＋ 无扩展名 1 件
  #    ＋ 排除目录 `obj/` 里 1 件 ⇒ 覆盖面**应为 4 件**（定点读数：声明真按声明走）──
  mk_tree() {   # $1=dir
    mkdir -p "$1/obj" "$1/sub"
    printf 'alpha\nbeta\ngamma\n'   > "$1/a.c"
    printf '/* header */\nint x;\n' > "$1/b.h"
    printf '# title\n'              > "$1/c.md"
    printf 'print(1)\n'             > "$1/sub/e.py"
    printf 'PNGDATA-not-text\n'     > "$1/a.png"
    printf 'unknown-ext\n'          > "$1/a.zzz"
    printf 'no-extension\n'         > "$1/blob"
    printf 'obj-copy\n'             > "$1/obj/a.c"
  }
  # 注入物：`line1\nline2\nline3<0x00>tail\n` ⇒ 首个 NUL 在**偏移 17**、第 **3** 行（手算，独立于扫描器）
  inj() { printf 'line1\nline2\nline3\0tail\n' > "$1"; }
  local T1="$SB/clean" T2="$SB/inj" T3="$SB/other" T4="$SB/objin" T5="$SB/empty" T6="$SB/big"
  mk_tree "$T1"; mk_tree "$T2"; mk_tree "$T3"; mk_tree "$T4"
  mkdir -p "$T5" "$T6"
  python3 - "$T6/big.txt" <<'PYBIG'
import sys
with open(sys.argv[1], 'wb') as fh:
    fh.write(b'a' * (9 * 1024 * 1024))
    fh.write(b'\n')
    fh.write(b'b\x00c\n')
PYBIG

  # S01 干净树 ⇒ PASS/hits=0；覆盖面**恰 4 件**；三类「没扫」都点了名
  run_case S01-clean 0 "$T1" NULB_ANCHORS=off NULB_MIN_FILES=0
  has 'NULBYTES_ROSTER files=4 '; assert 'S01 覆盖面恰 4 件（a.png/a.zzz/blob/obj 都不判）' "$HAS"
  has 'NULBYTES_NOTSCANNED binext=1 otherext=1 noext=1'; assert 'S01 「没扫什么」三类都点了名' "$HAS"

  # S02 **注入 1 个 NUL ⇒ 必红**，且点名 path/偏移/行号/计数
  inj "$T2/a.c"
  run_case S02-inject-1-nul 1 "$T2" NULB_ANCHORS=off NULB_MIN_FILES=0
  has 'NULBYTES_HIT path=a.c offset=17 line=3 n=1'; assert 'S02 点名 a.c ＋ offset=17 ＋ line=3 ＋ n=1' "$HAS"

  # S03 **还原 ⇒ 回绿**（与 S02 成对）
  printf 'alpha\nbeta\ngamma\n' > "$T2/a.c"
  run_case S03-restore 0 "$T2" NULB_ANCHORS=off NULB_MIN_FILES=0

  # S04 反极性：同一 NUL 放进**白名单外扩展名**（.png）⇒ 按声明**不算命中**，但必须**可见**
  #    （可见性用 `--list-notscanned` 的**逐条清单**证：那份 .png 在里面）
  inj "$T3/a.png"
  RC_FLAGS=--list-notscanned run_case S04-nul-in-png 0 "$T3" NULB_ANCHORS=off NULB_MIN_FILES=0
  has 'NULBYTES_NOTSCAN_LIST_BEGIN'; assert 'S04 「没扫」清单可逐条列出（不是静默跳过）' "$HAS"
  has 'a.png'; assert 'S04 带 NUL 的那份 .png 出现在「没扫」清单里' "$HAS"

  # S05 反极性：同一 NUL 放进**排除目录** `obj/` ⇒ 不算命中，且被排除目录被点名
  inj "$T4/obj/a.c"
  run_case S05-nul-in-obj 0 "$T4" NULB_ANCHORS=off NULB_MIN_FILES=0
  has 'NULBYTES_SKIPDIRNAME obj:1'; assert 'S05 排除目录被点名（skipdir_dirs=1/obj:1）' "$HAS"

  # S06 空覆盖面 ⇒ NOINFO（**不是绿**）
  run_case S06-empty-roster 2 "$T5" NULB_ANCHORS=off NULB_MIN_FILES=0
  has 'reason=empty-roster'; assert 'S06 空覆盖面 ⇒ NOINFO reason=empty-roster' "$HAS"

  # S07 锚断（合成树里没有 verify-all.sh / wic_proxy.c）⇒ NOINFO
  run_case S07-anchor-broken 2 "$T1" NULB_ANCHORS=strict NULB_MIN_FILES=0
  has 'reason=anchor-missing'; assert 'S07 锚断 ⇒ NOINFO reason=anchor-missing' "$HAS"

  # S08 件数下限没达到 ⇒ NOINFO
  run_case S08-too-few-files 2 "$T1" NULB_ANCHORS=off NULB_MIN_FILES=999999
  has 'reason=too-few-files'; assert 'S08 件数低于下限 ⇒ NOINFO reason=too-few-files' "$HAS"

  # S09 解释器缺失 ⇒ NOINFO
  run_case S09-python-missing 2 "$T1" NULB_ANCHORS=off NULB_MIN_FILES=0 NULB_PYTHON=/nonexistent/python3
  has 'reason=python-missing'; assert 'S09 解释器缺失 ⇒ NOINFO reason=python-missing' "$HAS"

  # S10 弄瞎扫描器（树里**真有** NUL）⇒ 必须 NOINFO（既不绿、也不冒充红）
  inj "$T2/a.c"
  run_case S10-blinded 2 "$T2" NULB_ANCHORS=off NULB_MIN_FILES=0 NULB_TEST_BLIND=1
  has 'reason=scanner-blinded'; assert 'S10 弄瞎 ⇒ NOINFO（不绿、不冒充红）' "$HAS"
  printf 'alpha\nbeta\ngamma\n' > "$T2/a.c"

  # S11 金丝雀被故意弄坏 ⇒ 必须 NOINFO（证明这条断言是活的，不是"永远 ok"）
  run_case S11-canary-broken 2 "$T1" NULB_ANCHORS=off NULB_MIN_FILES=0 NULB_CANARY_BREAK=1
  has 'reason=canary-blind'; assert 'S11 金丝雀弄坏 ⇒ NOINFO reason=canary-blind' "$HAS"

  # S12 大件尾部的 NUL（9 MiB ＋ 1 ＋ NUL 在 9437186、第 2 行）⇒ 必红（分块读不许漏尾）
  run_case S12-big-tail-nul 1 "$T6" NULB_ANCHORS=off NULB_MIN_FILES=0
  has 'NULBYTES_HIT path=big.txt offset=9437186 line=2 n=1'; assert 'S12 9 MiB 尾部 NUL：offset/line 定点命中' "$HAS"

  # S13 临时目录隔离：沙箱必须落在**我们给的** TMPDIR 之下
  run_case S13-tmp-isolated 0 "$T1" NULB_ANCHORS=off NULB_MIN_FILES=0
  has "NULBYTES_TMPDIR=$SB/tmp/"; assert "S13 临时目录落在 \$TMPDIR=$SB/tmp 之下" "$HAS"

  # S14 未认领扩展名里的 NUL ⇒ 不判红，但**必须可见**（DIAG 逐条点名）
  inj "$T3/a.zzz"
  run_case S14-unknown-ext 0 "$T3" NULB_ANCHORS=off NULB_MIN_FILES=0
  has 'NULBYTES_DIAG kind=otherext-nul path=a.zzz'; assert 'S14 未认领扩展名的 NUL 进了 DIAG（可见）' "$HAS"

  # S15 生产路径（**真树**）：不许 NOINFO，状态与 rc 自洽，金丝雀 ok
  run_case S15-live-tree LIVE "$REAL_ROOT" NULB_ANCHORS=strict

  # S16 共享 /tmp 不许因**生产路径**留下垃圾（只看生产临时目录前缀 `nulb-run.`；自测沙箱自己
  #    以 `nulb-selftest.` 起名、且结尾会自删 ⇒ 不混在这一格里）
  local leak
  leak="$(find /tmp -maxdepth 1 -name 'nulb-run.*' 2>/dev/null | sed -n '$=')"
  assert 'S16 共享 /tmp 上 nulb-run.* 残留 = 0' "$( [ "${leak:-0}" = 0 ] && echo 1 || echo 0 )"

  say "NULBYTES_SELFTEST_SELF self=$SELF sha16=$(self_sha16)"
  say "NULBYTES_SELFTEST_ROSTER sandbox=$SB cases=$total pass=$pass fail=$fail not-as-expected=$nae tmpbase=$SB/tmp"
  if [ "$fail" -ne 0 ]; then
    say "NULBYTES_SELFTEST_SANDBOX=$SB（保留供诊断；rm -rf 自行清理）"
    say "NULBYTES_SELFTEST=FAIL total=$total pass=$pass fail=$fail"
    return 1
  fi
  rm -rf "$SB"
  say "NULBYTES_SELFTEST=PASS total=$total pass=$pass fail=0"
  return 0
}

# ── 入口 ─────────────────────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2;;
    --list) WANT_LIST=1; shift;;
    --list-notscanned) WANT_NOTSCAN=1; shift;;
    --list-skipped-dirs) WANT_SKIPDIRS=1; shift;;
    --debug-tmp) DEBUG_TMP=1; KEEP_TMP=1; shift;;
    --selftest) run_selftest; exit $?;;
    -h|--help) usage; exit 0;;
    *) say "NULBYTES=NOINFO reason=bad-arg arg=$1"; exit 2;;
  esac
done
main_run
exit $?

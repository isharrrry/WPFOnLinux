#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""`wave-freeze-consistency-check.py` —— 冻结期的**四档一致性牙**（纯读、零 `dotnet`、秒级；不写任何件）。

【它防什么（四档各自独立、**互不代偿**）】
  ① `WFREEZE_ROOTDEFAULT` —— **旧路径重指向的派生式必须在真实自指路径下解析到仓根**。
     现场（`t6`）：`#77` 的 21 件重指向里有 **5 件 `dirname` 层数少一层** ⇒ 解析到 `<仓>/build` 而不是仓根，
     而**它们的第一个消费点拼出来的路径都不存在**，用改前的旧值拼则存在 ⇒ **真回归**。
     ⚠️ **`t19` 扩面（`D-G149` 同族的"只钉 22 条"缺口）**：`t6` 的 `ROSTER` 是**手列 22 条**；`t18` 现取
     188 件 `*.sh/*.py` 里 **147 条 dirname 派生式**、解析到仓根的有 **34** 条 ⇒ **12 条根变量站点
     （`Guide.Linux/verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／`frame-step.sh` …）今天全对但无牙看着**。
     ⇒ 本档改为**派生式 roster**：按**谓词现扫**（`dirname` ∧（`${BASH_SOURCE[0]}` ∨ `abspath(__file__)`）），
     与声明件 `src/Linux/build/MilBridge/wfreeze-root-sites.tsv`（`--emit-roster` 生成）**集合相等**，
     并对**解析到仓根**的每一条**逐个真跑判值**。`t17` 那 22 条**原样保留**为 `T17_ROSTER` 子集断言。
  ② `WFREEZE_DECL` —— **预登记文本必须与冻结器 `GENS` 的配置逐字段一致**。
     现场（`t6`）：预登记写 `allow_changed={'pf'}` ＋ `pf_required=True`，而 `GENS['#77']`
     实为 `allow_changed={pc,pf,windowsbase,provider,dwf}` ＋ `pf_required=False` ⇒ 同一件事在两处**分叉**。
  ③ `WFREEZE_NINEAUTH` —— **同名产物的多条「权威」路径之间必须相等**。
     现场（`t6`）：`DirectWrite.Linux.Provider.dll` 有两个都自称权威的路径；`t6` 重建了后者 ⇒ 前者立刻陈旧，
     `app-local` 判据当场 `STALE=52 / DIVERGENT=1`，而**九位/哨兵走前者** ⇒ **谁重建其一都会让两侧分叉**。
  ④ 🆕 `WFREEZE_BLOCKVALUES`（`t19` 加，`D-G166`）—— **冻结记录里的「值」必须等于落地后的现取值**，
     且**记录的两个授权来源之间不许互相矛盾**。三方对拍 = `# RE-FROZEN` 块的**九位行** ∧ 同块
     **`BASELINE tier=` 机读行** ∧ **现取 `sha256sum`**。
     现场（`t19` 现取，`#78` 块）：九位行写 `provider` `609192a419d125f2`，而**同块** 6 条
     `BASELINE tier=` 机读行与**盘上两条权威路径**都是 `a00895e8158189b9`
     ⇒ **同块两个授权来源互相矛盾** ＋ 与现取不符（`D-G149` 在 `#78` 的**第二代复发**）。
     根因（**主控现取、本件只引用不重写**）：`~/w186a/w78/w78freeze/w78-record.txt:67` 的九位行把
     `provider`／`wic_shim` 写成**硬编码字面量**，而 `~/w21-verify/w27-freeze.py:1530-1537` 的 `fmt` 字典
     **没有这两个占位符** ⇒ `fill()` 的断言只抓"用了没定义的占位符"、**结构上抓不到"写死了本应现取的值"**。
     ⚠️ 本档**不代偿** ①②③：② 管预登记↔`GENS` 的**配置字段**、③ 管**两条路径彼此相等**、
     ① 管**派生式解析到哪** —— 三者都不看"块里的值 vs 现值"。反过来 ④ 也**不代偿**它们。
     ⚠️ **具名声明**：不等**允许放行**，但必须逐键在 `src/Linux/build/MilBridge/blockvalues-shift.tsv` 里声明
     （`key / block9 / tier / live / registered / why`）——**声明把 `live=` 钉住** ⇒ 现取值再漂一次
     仍会红（"上限＝现读值 ⇒ 树长大也红"同形）。声明行**逐条上屏**，**不许静默**。
     ⚠️ 🆕 **`live` 不可判的键（无字节不动点）**（`TASK-收尾-冻结口径` 加；`D-G92`／`D-G176③`）：
       本档判「`live` == 记录值」的前提是**该产物的字节是当前树的确定函数**。`pf` **不是** ——
       `PF⇄ReachFramework` **真互引**（`…/src/PresentationFramework/ARTIFACT-SRC-FP.txt` 维度 B 件头逐字自述
       「该对无字节不动点、`pf` 每波必变」），`D-G92` 四趟**逐字相同**的整波重建给出**四个不同 sha**
       ⇒ 记录（`# RE-FROZEN` 块 ＋ 本表 `live=`）**写死在冻结那一刻**，而 `close-wave` 的 `[1/6]`
       **每趟都重建它** ⇒ 同一趟里「重钉」与「`[5c/6]` 通过」**结构上不可兼得**（`D-G176③`）。
       ⇒ 处置 **沿用本档既有体例**（同 `WFREEZE_BLOCKVALUES_TIER_NA`：某来源**按设计**不可用 ⇒
       **只核可得的那几格**、其余**逐条上屏但不判**）：对这些键**只核块内两个授权来源 `block9`↔`tier` 自洽**，
       `live` **逐条上屏、不判**，并逐键印 `WFREEZE_BLOCKVALUES_NOFIXPT`（**放行必须可见**）。
       ⚠️ **不是把牙关掉**：两个来源**互相矛盾** ⇒ 照旧红（见 `--selftest` 的 `S6nfp` 反极腿）；
       ⚠️ 声明集**按"无字节不动点"的定义现取**（同树、同命令、**连续两趟重建** ⇒ 字节变），**不是按"谁红了"**：
       本波现取（`h1`→`h2`）九位里**只有 `pf`** 变（`a38d6aa0→6b2c8fba`），而 `pc`／`windowsbase`／`provider`／`dwf`
       在**同一棵树、同一条命令**下**逐位稳定**（另四位 `bridge`／`win32shim`／`wic_shim`／`hbtextline` 本就未重建）
       ⇒ 声明集**恰为 `{'pf'}`**（表 = `NO_FIXED_POINT`）。

【第四档的"模板面"（只读、可选）】`--template <path>`：扫记录模板里的**裸 16 位 hex 字面量**
   （白名单外即红）。**不给 `--template` ⇒ 本面 `skipped(no-template-given)`，不进总体状态、不算绿**。
   ⚠️ `~/w186a/w78/w78freeze/w78-record.txt` 是"缺陷如何发生"的**原件证据** ⇒ **只读引用，不许改**；
   新代模板由波内另一件负责。本件**不替它做**。

【三态】`PASS`（rc 0）／`FAIL`（rc 1，逐条点名）／`NOINFO`（rc 3，**算不出来 ≠ 绿**）。
        任一档 `FAIL` ⇒ 整体 `FAIL`；无 `FAIL` 但有 `NOINFO` ⇒ 整体 `NOINFO`。
【用法】`python3 wave-freeze-consistency-check.py [--root DIR] [--freezer PATH]
                                                   [--sites PATH] [--shifts PATH] [--template PATH|auto]
                                                   [--emit-roster PATH] [--selftest]`
         `--root` 默认由**本件自身位置**现推（`src/Linux/build/MilBridge/tools/` 上溯三层）。
【`cwd` 硬化（`t19`／`E①`，`D-G130` 同族）】本件的**每一次求值**都走**显式 `cwd=` 的 `subprocess`**，
   并把仓根替成**绝对路径**（`os.path.isabs` 断言失败 ⇒ 直接点名红，不再"看调用者的 `cwd` 办事"）；
   **根站点另在第二个 `cwd` 下再求一次**，两次不等 ⇒ `WFREEZE_CWD_DEP`（本档自证"判定不是 `cwd` 的函数"）。
【`checked=` 口径（`t19`／`E②`，**写在件头，免得两个读数被当成打架**）】冻结器里有**两个**核函数：
   · `check_prev_values`（**生产线**：`~/w21-verify/w27-freeze.py:1223`，在 `:1299`／`:1336` 打印）
     ⇒ `checked=` = **`prev_*` 键数**（现读 `keys=7 checked=7 skipped=0`）——**这是 `#78` 收尾链上看到的那一个**。
   · `check_record_forms`（**退回到归档里的那个**：`~/w21-verify/versions/w27-freeze.py.w77e-0745-installed-f9fb7bcac0353a61:1229`，
     活件现读 `check_record_forms=0`）⇒ 同一块同表曾给 `checked=2`。
   ⇒ **同一个 `checked=` 字样、两个函数、两个读数**：引用它**必须**同时写函数名（或写"生产线＝`check_prev_values`"）。
   本件**不读**这两个函数（那是主控写域），只把口径写在件头。
【卫生】只读；不写 `$R`（`--emit-roster` 除外）；临时件走 `mktemp -d` ＋ `trap`。
"""
import argparse, ast, glob, hashlib, json, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SELF_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(HERE)))))   # src/Linux/build/MilBridge/tools → 仓根

# ══ 档 ① 的**谓词**（派生式扫描域；`t19` 加）═════════════════════════════════════════
SCAN_ROOTS = ['.', 'build', 'tests', 'src']   # `.` = 仓根**顶层**（非递归）—— `Guide.Linux/verify-all.sh` 就在那儿
SCAN_EXTS = ('.sh', '.py')
SCAN_SKIP_PARTS = ('bin', 'obj', '.artifacts', 'gen', '__pycache__', 'upstream', 'node_modules', '.git')
DIRNAME_HINTS = ('${BASH_SOURCE[0]}', '$BASH_SOURCE', 'abspath(__file__)')

# ══ 档 ①：`t17` 实际改过的 21 件 / 22 条派生式（**子集断言**，保留原 roster 不减）══════════
T17_ROSTER = [  # (相对路径, 行号, 变量名, 消费点后缀 or None)
 ("src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/wic-shim/frames-gen.py", 33, "REPO", "src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/wic-shim/fixtures-jfif.jpg"),
 ("src/Linux/build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh", 23, "REPO", None),
 ("src/Linux/build/MilBridge/tests/W81AWindowProbe/w81a-a0-analyze.py", 28, "_ROOT77", "src/WpfGfx.Linux.Native/bin/libwpfwin32.so"),
 ("src/Linux/build/MilBridge/tools/analyze-layout-b34.py", 12, "ROOT", "src/Linux/build/MilBridge/gen/layout-b34-compact.json"),
 ("src/Linux/build/MilBridge/tools/backup-completeness-gate.sh", 49, "BCG_DEFROOT", None),
 ("src/Linux/build/MilBridge/tools/extract-layout-b34.py", 13, "ROOT", "src/Linux/tests/parity/windows/layout-b34/windows-results.json"),
 ("src/Linux/build/MilBridge/tools/nl-intent-check.sh", 58, "cand", None),
 ("src/Linux/build/MilBridge/tools/nl-intent-check.sh", 64, "R", None),
 ("src/Linux/build/MilBridge/tools/proc-pattern-guard.sh", 55, "REPO", None),
 ("src/Linux/build/MilBridge/tools/pts-gap-count-check.sh", 74, "R", None),
 ("src/Linux/build/MilBridge/tools/repo-alias-check.sh", 55, "ALIAS_ROOT", None),
 ("src/Linux/build/MilBridge/tools/retake-arms-w21.sh", 6, "ROOT", None),
 ("src/Linux/build/MilBridge/tools/retake-arms-w23.sh", 6, "ROOT", None),
 ("src/Linux/build/MilBridge/tools/t1b-d3-acceptance.sh", 15, "ROOT", None),
 ("src/Linux/build/MilBridge/tools/t1b-live-window.sh", 19, "ROOT", None),
 ("src/Linux/build/MilBridge/tools/t1c-census.sh", 35, "ROOT", None),
 ("src/Linux/build/MilBridge/tools/t1c-inputtrace-verify.py", 32, "ROOT", "src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py"),
 ("src/Linux/build/MilBridge/tools/t1d-probe.sh", 22, "ROOT", None),
 ("src/Linux/build/MilBridge/tools/t2d-extent-detail.sh", 13, "ROOT", None),
 ("src/Linux/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-1400rate.sh", 31, "REPO", None),
 ("src/Linux/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-inputleg-tooth.sh", 20, "REPO", None),
 ("src/Linux/tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe-mutation.sh", 19, "REPO", None),
]
ROSTER = T17_ROSTER   # 兼容旧调用名（外件若 `from … import ROSTER`）

# ══ 档 ③：同名产物多「权威」路径（规约权威, 副本）—— 判定见 §F6：**规约 = 工程的产出目录** ══
NINEAUTH = [
  ("src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/Provider/bin/Release/DirectWrite.Linux.Provider.dll",
   "src/Microsoft.DotNet.Wpf.Linux/src/PresentationCore/bin/Release/DirectWrite.Linux.Provider.dll"),
]

# ══ 档 ④：九位的**权威路径表**（与 `~/w21-verify/w27-freeze.py` 的 `NINE` 逐字同源；本条是**仓内声明**）══
NINE_PATHS = [
    ('bridge', 'src/Linux/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so'),
    ('pc', 'src/Microsoft.DotNet.Wpf.Linux/src/PresentationCore/bin/{CFG}/PresentationCore.dll'),
    ('pf', 'src/Microsoft.DotNet.Wpf.Linux/src/PresentationFramework/bin/{CFG}/PresentationFramework.dll'),
    ('windowsbase', 'src/Microsoft.DotNet.Wpf.Linux/src/WindowsBase/bin/{CFG}/WindowsBase.dll'),
    ('provider', 'src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/Provider/bin/{CFG}/DirectWrite.Linux.Provider.dll'),
    ('win32shim', 'src/WpfGfx.Linux.Native/bin/libwpfwin32.so'),
    ('wic_shim', 'src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/wic-shim/libwpfwic.so'),
    ('hbtextline', 'src/Microsoft.DotNet.Wpf.Linux/src/shims/PresentationCore.HbTextLine.cs'),
    ('dwf', 'src/Microsoft.DotNet.Wpf.Linux/src/DirectWriteForwarder/bin/{CFG}/DirectWriteForwarder.dll'),
]
SITES_TSV = 'src/Linux/build/MilBridge/wfreeze-root-sites.tsv'
SHIFTS_TSV = 'src/Linux/build/MilBridge/blockvalues-shift.tsv'

# ══ 档 ④：**`live` 不可判的键** = 产物**无字节不动点**（`TASK-收尾-冻结口径` 加；`D-G92`／`D-G176③`）══
#   定义（先说死，免得被当成"新开的口子"）：该产物的字节**不是当前树的确定函数** ——
#     **同一棵树、同一条命令、连续两趟重建**给出**不同**字节。
#   现场（在册现取，只引用不重写 ＋ 本波复算）：
#     · `pf`：`PF⇄ReachFramework` **真互引** ⇒ Roslyn 把被引件字节纳入输入哈希
#       （`src/Microsoft.DotNet.Wpf.Linux/src/PresentationFramework/ARTIFACT-SRC-FP.txt` 维度 B 件头**逐字自述**
#        「…该对无字节不动点、`pf` 每波必变」）；`D-G92` 四趟**逐字相同**的整波重建 ⇒ **四个不同 sha**；
#        本波复算（`~/w-freeze-fix/exp.sh`，两趟 `integration-wave.sh`，树静止）：九位里**只有 `pf`** 位移
#        （`a38d6aa0e35845b1 → 6b2c8fba61641c86`），另八位**逐位相同**。
#   ⚠️ **为什么必须与"提交号载体"分开**（不许把声明集读宽）：`provider` 内嵌 `AssemblyInformationalVersion`
#      的 `1.0.0+<HEAD>`（本波现取：`1.0.0+57840fbe9c4e…`），`pc`／`dwf` 经 `peer=`／`ProjectReference` 随它位移
#      —— 但那是**提交**的函数，**不是**"同一棵树两趟重建"的函数：本波复算里 `pc`／`windowsbase`／`provider`／`dwf`
#      在 `h1→h2` **逐位稳定**。⇒ 它们的 `live` **照旧判**（有牙、且可满足），只是**冻结后不得再新增提交**
#      （那是一条**流程约束**，不是判据口径；见报告 §残余）。
#   ⇒ 本表**只**列"无字节不动点"的键；每项 `(mechanism, registered)`：`mechanism` 进上屏行、
#      `registered` 必须是**已入册**缺陷号（与 `blockvalues-shift.tsv` 的 `registered` 同域）。
#   ⚠️ 硬约束（与 `TIER_NA` 同）：① **放行必须可见**（逐键印 `WFREEZE_BLOCKVALUES_NOFIXPT`）；
#      ② **不是"把牙关掉"**（`block9 != tier` ⇒ 照旧红并点名，见 `--selftest S6nfp`）；
#      ③ **不许**用环境开关把整档关掉、**不许**把 `NOINFO` 当绿、**不许**改 `--expect` 之类来凑。
NO_FIXED_POINT = {
    'pf': ('ring', 'D-G92'),   # `PF⇄ReachFramework` 互引 ⇒ 该对无字节不动点（同上文件件头自述）
}


def sha16(p):
    try:
        h = hashlib.sha256()
        with open(p, 'rb') as f:
            for b in iter(lambda: f.read(1 << 20), b''): h.update(b)
        return h.hexdigest()[:16]
    except OSError:
        return None


def linehash(l):
    """**内容锚** = 该行**规范化文本**的 sha16（`strip()` 后取 sha256 前 16）。
    ⚠️ 为什么不用行号锚（本仓教训「内容锚、禁行号」）：`t20` 给 `Guide.Linux/verify-all.sh` 加两行 ⇒ 行号全漂 ⇒
       行号锚的 roster 当场报 `roster-site-lost`／`root-site-undeclared`（`t27` 现场 `bad=3`），
       而那三处**代码一个字没改** —— 行号漂移**不是**缺陷，不该红。内容锚下：**同一行内容移到别处 ⇒ 仍绿**；
       **该行内容被改** ⇒ key 变 ⇒ 红（必须重发 roster）。"""
    return hashlib.sha256(l.strip().encode('utf-8')).hexdigest()[:16]


def read_lines(p):
    try:
        return open(p, encoding='utf-8', errors='replace').read().split('\n')
    except OSError:
        return []


# ── 派生式扫描与求值（档 ①）─────────────────────────────────────────────────────
def candidatum_var(line):
    """从一行里取**被赋值的变量名**。⚠️ 必须区分 `for X in …` 与 `X=…`：
    `^\s*([A-Za-z_]\w*)\s*=` 的朴素写法会把 `for cand in "$(…)"; do` 里的 **`for`** 当变量名
    ⇒ 求值分支错、把一条**根站点**误判成 `err`（本件首版现场：`nl-intent-check.sh:58` 的 `cand`）。"""
    m = re.match(r'^\s*for\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\b', line)
    if m:
        return m.group(1)
    m = re.match(r'^\s*(?:local\s+|export\s+|declare\s+|readonly\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=', line)
    return m.group(1) if m else ''


def scan_candidates(root):
    """按**谓词**现扫：`dirname` ∧（`${BASH_SOURCE[0]}` ∨ `abspath(__file__)`）。返回 [(rel, ln, var, line)]。"""
    out = []
    for R in SCAN_ROOTS:
        base = os.path.join(root, R)
        if not os.path.isdir(base):
            continue
        if R == '.':
            walk = [(base, [], sorted(os.listdir(base)))]
        else:
            walk = os.walk(base)
        for dp, dn, fn in walk:
            if R != '.':
                dn[:] = [d for d in dn if d not in SCAN_SKIP_PARTS]
            for f in sorted(fn):
                if not f.endswith(SCAN_EXTS):
                    continue
                p = os.path.join(dp, f)
                if not os.path.isfile(p):
                    continue
                rel = os.path.relpath(p, root)
                if any(x in rel.split('/') for x in SCAN_SKIP_PARTS):
                    continue
                for i, l in enumerate(read_lines(p), 1):
                    if 'dirname' not in l:
                        continue
                    if not any(h in l for h in DIRNAME_HINTS):
                        continue
                    s = l.strip()
                    if s.startswith('#'):
                        continue
                    out.append((rel, i, candidatum_var(l), l))
    return out


def _eval_sh(line, var, path, cwd):
    inj = line.replace('${BASH_SOURCE[0]}', path)
    try:
        if re.search(r'for\s+%s\s+in' % re.escape(var), inj):
            sub = inj[inj.index('$('):inj.rindex(')') + 1]
            r = subprocess.run(['bash', '-c', 'echo %s' % sub], capture_output=True, text=True,
                               cwd=cwd, timeout=30)
            return r.stdout.strip() if r.returncode == 0 else 'EVAL-RC=%d' % r.returncode
        r = subprocess.run(['bash', '-c', 'set -u\n%s\necho "${%s}"\n' % (inj, var)],
                           capture_output=True, text=True, cwd=cwd, timeout=30)
        return r.stdout.strip() if r.returncode == 0 else 'EVAL-RC=%d' % r.returncode
    except Exception as e:                                   # noqa: BLE001
        return 'EVAL-ERROR:%s' % type(e).__name__


def _eval_py(line, var, path, cwd):
    m = re.match(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*(?:#.*)?$', line)
    if not m:
        return 'EXTRACT-FAILED'
    code = ('import os,sys\n__file__=%r\nprint(eval(%r,{"os":os,"sys":sys,"__file__":__file__}))'
            % (path, m.group(2)))
    try:
        r = subprocess.run(['python3', '-c', code], capture_output=True, text=True, cwd=cwd, timeout=30)
        return r.stdout.strip() if r.returncode == 0 else 'EVAL-RC=%d' % r.returncode
    except Exception as e:                                   # noqa: BLE001
        return 'EVAL-ERROR:%s' % type(e).__name__


def eval_candidate(root, rel, ln, var, line, cwd=None):
    """**显式 `cwd`** 求值（`cwd=None` ⇒ `/`）；仓根必为绝对路径（否则由调用者判红）。"""
    p = os.path.join(root, rel)
    if not os.path.isabs(p):
        return 'NONABS-INPUT'
    cwd = cwd or '/'
    if rel.endswith('.py'):
        return _eval_py(line, var, p, cwd)
    return _eval_sh(line, var, p, cwd)


def load_sites(root, sites_path):
    """读派生式 roster（`--emit-roster` 生成）；返回 (decl_total, decl_files, {(rel,ln,var): state})。"""
    p = sites_path if os.path.isabs(sites_path) else os.path.join(root, sites_path)
    if not os.path.exists(p):
        return None, None, None
    total = files = None
    sites = {}
    for l in read_lines(p):
        m = re.match(r'^#\s*WFROOT-SITES-TOTAL\s+derived=(\d+)\s+files=(\d+)\s*$', l)
        if m:
            total, files = int(m.group(1)), int(m.group(2)); continue
        if not l or l.startswith('#'):
            continue
        f = l.split('\t')
        if len(f) == 6 and f[0] == 'site':           # site<TAB>rel<TAB>var<TAB>linehash16<TAB>idx<TAB>state
            sites[(f[1], f[2], f[3], int(f[4]))] = f[5]
        elif len(f) == 5 and f[0] == 'site':         # ⏪ 旧形态（行号锚）⇒ 响亮 NOINFO，不许当绿
            return 'LEGACY-LINEANCHOR', None, None
    return total, files, sites


def emit_roster(root, out_path):
    cands = scan_candidates(root)
    nfiles = len({c[0] for c in cands})
    rows = []
    seen = {}
    for rel, ln, var, line in cands:
        got = eval_candidate(root, rel, ln, var, line)
        st = 'root' if got == root else ('err' if str(got).startswith('EVAL') or got in ('EXTRACT-FAILED',) else 'benign')
        h = linehash(line)
        key0 = (rel, var, h)
        idx = seen.get(key0, 0); seen[key0] = idx + 1          # 同件同 var 同文本的行用 idx 区分
        rows.append((rel, var, h, idx, st))
    body = ['# wfreeze-root-sites.tsv —— 档 ① 的**派生式 roster**（`wave-freeze-consistency-check.py --emit-roster` 生成）',
            '#   谓词：`dirname` ∧（`${BASH_SOURCE[0]}` ∨ `abspath(__file__)`）；域：src/Linux/build/ src/Linux/tests/ src/ 下的 *.sh/*.py',
            '#   ⚠️ **锚是内容锚，不是行号**（本仓教训「内容锚、禁行号」）：`rel<TAB>var<TAB>linehash16<TAB>idx`，',
            '#      `linehash` = 该行 `strip()` 后 sha256 前 16 ⇒ **行号漂移不红**（同一行搬到别处仍绿），',
            '#      **该行内容被改** ⇒ key 变 ⇒ 红（必须重发本表）。',
            '#   state=root ⇒ **逐条真跑判值必须 == 仓根**；state=benign/err ⇒ 只钉**集合与状态**（不钉值）。',
            '#   ⚠️ 本表**由牙自己重算**：任何新增/删除/改状态 ⇒ 红，必须重发本表（"逼后来者显式声明"）。',
            '# WFROOT-SITES-TOTAL derived=%d files=%d' % (len(rows), nfiles)]
    for rel, var, h, idx, st in sorted(rows):
        body.append('site\t%s\t%s\t%s\t%d\t%s' % (rel, var, h, idx, st))
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(body) + '\n')
    return len(rows), nfiles, sum(1 for r in rows if r[4] == 'root')


# ── 档 ① ────────────────────────────────────────────────────────────────────────
def sec_rootdefault(root, sites_path=None):
    if not os.path.isabs(root):
        print('WFREEZE_ROOTDEFAULT_HIT kind=root-not-absolute root=%s（判定不许是 cwd 的函数）' % root)
        print('WFREEZE_ROOTDEFAULT=FAIL exprs=0 ok=0 bad=1 consume=0 consume_ok=0 cwd=ABS-REQUIRED')
        return 'FAIL'
    decl_total, decl_files, decl_sites = load_sites(root, sites_path or SITES_TSV)
    if decl_total == 'LEGACY-LINEANCHOR':
        print('WFREEZE_ROOTDEFAULT=NOINFO reason=roster-legacy-lineanchor path=%s（声明表还是**行号锚**旧形态 ⇒ 必须重发 `--emit-roster`；行号锚已被 `t20` 的落地证明会假红）' % (sites_path or SITES_TSV))
        return 'NOINFO'
    if decl_total is None:
        print('WFREEZE_ROOTDEFAULT=NOINFO reason=roster-absent path=%s（没有声明表 ⇒ 算不出来，**不算绿**）' % (sites_path or SITES_TSV))
        return 'NOINFO'
    cands = scan_candidates(root)
    # **内容锚**：key = (rel, var, linehash16, idx)；`ln` 只作**诊断列**（行号漂移不进判据）
    key_of, live, live_line, seen = {}, {}, {}, {}
    for rel, ln, var, line in cands:
        h = linehash(line)
        k0 = (rel, var, h)
        idx = seen.get(k0, 0); seen[k0] = idx + 1
        key = (rel, var, h, idx)
        key_of[key] = (rel, ln, var, line)
        live[key] = ln
        live_line[key] = line
    rows, bad = [], 0
    root_n = ok = 0
    cwd_dep = 0
    for key, (rel, ln, var, line) in key_of.items():
        got = eval_candidate(root, rel, ln, var, line)
        if got == root:
            root_n += 1
            # 根站点：**第二个 cwd** 下再求一次（自证"判定不是 cwd 的函数"）
            got2 = eval_candidate(root, rel, ln, var, line, cwd=os.path.dirname(os.path.join(root, rel)))
            if got2 != got:
                cwd_dep += 1
                print('WFREEZE_CWD_DEP file=%s line=%d var=%s cwd1=%s cwd2=%s（同一条派生式在两个 cwd 下不同 ⇒ 判定取决于调用者）'
                      % (rel, ln, var, got, got2))
            if key in decl_sites:
                ok += 1
            else:
                bad += 1
                print('WFREEZE_ROOTDEFAULT_HIT kind=root-site-undeclared file=%s line=%d var=%s anchor=%s got=%s（解析到仓根但**不在声明表里** ⇒ 重发 `--emit-roster`）'
                      % (rel, ln, var, linehash(line), got))
        else:
            rows.append((rel, ln, var, got))
    # 声明表里**消失**或**不再解析到仓根**的站点（内容锚：内容被改 ⇒ key 不在 ⇒ 这里点名）
    for key in sorted(decl_sites):
        r, v, h, idx = key
        if key not in live:
            bad += 1
            print('WFREEZE_ROOTDEFAULT_HIT kind=roster-site-lost file=%s var=%s anchor=%s idx=%d（声明在册、现扫不到 ⇒ 该行**内容被改**或整条被删 ⇒ 重发 `--emit-roster`）'
                  % (r, v, h, idx))
        elif decl_sites[key] == 'root':
            got = eval_candidate(root, r, live[key], v, live_line[key])
            if got != root:
                bad += 1
                print('WFREEZE_ROOTDEFAULT_HIT file=%s line=%d var=%s anchor=%s got=%s want=%s（派生式解析到的**不是仓根**）'
                      % (r, live[key], v, h, got, root))
    if len(cands) != decl_total:
        bad += 1
        print('WFREEZE_ROOTDEFAULT_HIT kind=derived-total-mismatch live=%d declared=%d（派生式集合变过 ⇒ 重发 `--emit-roster`）'
              % (len(cands), decl_total))
    # `t17` 的 22 条**子集断言**（按 `(rel, var)` 匹配 —— **内容锚化后不再用行号**）＋ 原语义判值 ＋ 消费点判据
    t17_lost, cons_rows, cons_ok, t17_val_bad = 0, 0, 0, 0
    by_rel_var = {}
    for key, (rel, ln, var, line) in key_of.items():
        by_rel_var.setdefault((rel, var), []).append((key, ln, line))
    for rel, ln_t17, var, suffix in T17_ROSTER:
        hits = by_rel_var.get((rel, var), [])
        if not hits:
            t17_lost += 1
            print('WFREEZE_ROOTDEFAULT_HIT kind=t17-roster-site-lost file=%s var=%s（`t17` 原 roster 这一条要求解析到仓根）' % (rel, var))
        else:
            key, ln, line = hits[0]
            got = eval_candidate(root, rel, ln, var, line)
            if got != root:
                t17_val_bad += 1
                print('WFREEZE_ROOTDEFAULT_HIT kind=t17-value file=%s line=%d var=%s got=%s want=%s（`t17` 原 roster 这一条要求解析到仓根）'
                      % (rel, ln, var, got, root))
        if suffix is not None:
            cons_rows += 1
            a = os.path.exists(os.path.join(root, suffix))
            b = os.path.exists(os.path.join(root, 'src', 'Linux', 'build', suffix))
            if a and not b:
                cons_ok += 1
            else:
                print('WFREEZE_ROOTDEFAULT_HIT file=%s var=%s（消费点拼出来的路径不存在：root=%s build=%s）'
                      % (rel, var, a, b))
    bad += t17_lost + t17_val_bad
    state = 'PASS' if (bad == 0 and cands and cons_ok == cons_rows and cwd_dep == 0) else 'FAIL'
    print('WFREEZE_ROOTDEFAULT=%s exprs=%d files=%d ok=%d bad=%d root_n=%d benign=%d consume=%d consume_ok=%d t17=%d t17_lost=%d t17_val_bad=%d cwd_dep=%d anchor=content'
          % (state, len(cands), len({c[0] for c in cands}), ok, bad, root_n, len(rows), cons_rows, cons_ok,
             len(T17_ROSTER), t17_lost, t17_val_bad, cwd_dep))
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
            for l in read_lines(f):
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
    except Exception as e:                                   # noqa: BLE001
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
            print('WFREEZE_NINEAUTH_HIT kind=diverged canon=%s=%s copy=%s=%s（**同名产物的两条「权威」路径分叉**）'
                  % (canon, a, copy, b))
    st = 'PASS' if bad == 0 else 'FAIL'
    print('WFREEZE_NINEAUTH=%s pairs=%d ok=%d bad=%d' % (st, len(pairs), len(pairs) - bad, bad))
    return st


# ── 档 ④（`t19` 新加；`D-G166`）──────────────────────────────────────────────────
def _cfg_of(root):
    p = os.path.join(root, 'src', 'Linux', 'build', 'SelfBuiltConfig.props')
    for l in read_lines(p):
        m = re.search(r'>(Release|Debug)<', l)
        if m: return m.group(1)
    return 'Release'


def parse_nine_line(line):
    """九位行：`` `name` `<16hex>` `` 逐键取；另容忍尾部句号/全角标点。"""
    out = {}
    for m in re.finditer(r'`([A-Za-z_][A-Za-z0-9_]*)`\s*`([0-9a-f]{16})`', line):
        out[m.group(1)] = m.group(2)
    return out


def parse_tier_lines(lines):
    """同块 `BASELINE tier=` 机读行 ⇒ {name: value}；多行不一致 ⇒ 记 `CONFLICT`。
    ⚠️ 键名映射（本件首版现场）：机读行里写的是 **`hbtextline_shim`**，而九位行写 **`hbtextline`**；
       另 `windowsbase`／`dwf` **按设计不在** `config=` 里（`tier` 只覆盖 7 键）⇒ 缺键是 `na`，**不是** `source-missing`。"""
    seen, conflict = {}, set()
    for l in lines:
        m = re.match(r'^BASELINE tier=(\S+)\s+rep=(\d+)\s+config=([^ ]+)', l)
        if not m: continue
        for kv in m.group(3).split(','):
            if ':' not in kv: continue
            k, v = kv.split(':', 1)
            if not re.fullmatch(r'[0-9a-f]{16}', v): continue
            k = {'hbtextline_shim': 'hbtextline'}.get(k, k)
            if k in seen and seen[k] != v: conflict.add(k)
            seen[k] = v
    for k in conflict: seen[k] = 'CONFLICT'
    return seen


def load_shifts(root, shifts_path):
    p = shifts_path if os.path.isabs(shifts_path) else os.path.join(root, shifts_path)
    rows = {}
    if not os.path.exists(p):
        return rows
    for l in read_lines(p):
        if not l or l.startswith('#') or l.startswith('key\t'):
            continue
        f = l.split('\t')
        if len(f) < 5:
            continue
        # 【`t34` 修：`tier` 列的"缺"**必须可满足**】缺 → 归一到 Python `None`。
        #   现场：机读行按设计只覆盖 7 键 ⇒ `windowsbase`/`dwf`/`hbtextline` 在机读行里**本来就没有**；
        #   旧比较是 `sh['tier'] == bt`（`bt is None`）⇒ **字符串永远不等于 `None`** ⇒ 这两格的具名声明
        #   **结构上不可满足**（主控先后写 `-`／`None` 都被拒）。缺的统一写法：**`none|-|n/a|空`**（都归一）。
        _t = (f[2] or '').strip()
        _t = None if _t in ('', '-', 'None', 'none', 'n/a', 'NA', 'null') else _t
        rows[f[0]] = {'block9': f[1], 'tier': _t, 'live': f[3], 'registered': f[4],
                      'why': (f[5] if len(f) > 5 else '')}
    return rows


def declared_ids(root):
    """读 `defect-registry-declared.tsv` 的 ID 集（`None` = 取不到 ⇒ 该守卫不判，免得把取数失败当红）。"""
    p = os.path.join(root, 'src', 'Linux', 'build', 'MilBridge', 'tools', 'defect-registry-declared.tsv')
    if not os.path.exists(p):
        return None
    ids = set()
    for l in read_lines(p):
        if l.startswith('ID\t'):
            f = l.split('\t')
            if len(f) > 1:
                ids.add(f[1])
    return ids or None


def template_line_kind(line):
    """模板行分类（`t34`）：**承载现取值的行** vs 其余。
      · `nine`          —— 九位行（`**九位（Release 权威件）**`）：本应全是 `{…}` 占位符
      · `inputs_fp`     —— `inputs_fp` 行
      · `bridge_src_fp` —— `BRIDGE_SRC_FP` 行
      · `other`         —— 其余（`# ARM-LOG-SHA`／`# COLUMN-CORPUS`／散文／散落裸 hex）⇒ **只列不判**
    判定只用**内容锚**（与行号无关）。"""
    if '九位（Release 权威件）' in line:
        return 'nine'
    if re.search(r'`?inputs_fp`?\s*=', line):
        return 'inputs_fp'
    if re.search(r'`?BRIDGE_SRC_FP`?\s*=', line):
        return 'bridge_src_fp'
    return 'other'


def _freezer_record_txt(freezer):
    """从冻结器 `GENS` **现取**「最新声明世代」的 `TXT`（= 本代记录模板路径）。取不到 ⇒ `None`。"""
    try:
        tree = ast.parse(open(freezer, encoding='utf-8', errors='replace').read())
        G = _gens_from_ast(tree)
        if not G:
            return None
        best = None
        for g in G:
            m = re.match(r'^#(\d+)$', str(g))
            if not m:
                continue
            n = int(m.group(1))
            if best is None or n > best[0]:
                best = (n, g)
        if best is None:
            return None
        return (G.get(best[1]) or {}).get('TXT')
    except Exception:
        return None


def sec_blockvalues(root, shifts_path=None, template=None, freezer=None):
    base = os.path.join(root, 'src', 'Linux', 'samples', 'WpfTextDemo', 'ACCEPTANCE-BASELINE.md')
    blines = read_lines(base)
    if not blines:
        print('WFREEZE_BLOCKVALUES=NOINFO reason=baseline-absent path=%s' % base)
        return 'NOINFO'
    hdr = re.compile(r'^# RE-FROZEN #(\d+)')
    anyhdr = re.compile(r'RE-FROZEN #\d+')          # ⚠️ **search**（历史块前缀 `# ⏪ **（历史，已被 #NN 取代）**# RE-FROZEN #MM`）
    start = gen = None
    for i, l in enumerate(blines):
        m = hdr.match(l)
        if m: start, gen = i, m.group(1); break
    if start is None:
        print('WFREEZE_BLOCKVALUES=NOINFO reason=no-RE-FROZEN-header')
        return 'NOINFO'
    end = len(blines)
    for j in range(start + 1, len(blines)):
        if anyhdr.search(blines[j]) or blines[j].startswith('# ⏪'):
            end = j; break
    blk = blines[start:end]
    nine_lines = [l for l in blk if re.match(r'^#\s+\*\*九位（Release 权威件）\*\*', l)]
    if not nine_lines:
        print('WFREEZE_BLOCKVALUES=NOINFO reason=no-nine-line gen=#%s block=lines[%d,%d)' % (gen, start + 1, end + 1))
        return 'NOINFO'
    book9 = parse_nine_line(nine_lines[0])
    tier = parse_tier_lines(blk)
    cfg = _cfg_of(root)
    shifts = load_shifts(root, shifts_path or SHIFTS_TSV)
    bad = 0; noinfo = 0; declared = 0; nofixpt = 0; tier_na = []
    for name, rel in NINE_PATHS:
        rel = rel.replace('{CFG}', cfg)
        live = sha16(os.path.join(root, rel))
        b9 = book9.get(name); bt = tier.get(name)
        if live is None:
            noinfo += 1
            print('WFREEZE_BLOCKVALUES_HIT kind=live-absent key=%s path=%s（现取件不在 ⇒ 算不出来）' % (name, rel))
            continue
        if b9 is None:
            noinfo += 1
            print('WFREEZE_BLOCKVALUES_HIT kind=source-missing key=%s nine=%s（**九位行是权威记录**：缺该键 ⇒ 算不出来）'
                  % (name, b9))
            continue
        # ── 【`TASK-收尾-冻结口径`】**无字节不动点的键**：只核块内两个授权来源自洽；`live` 逐条上屏、不判 ──
        #   依据／定义／硬约束见件头 ④ 段 ＋ `NO_FIXED_POINT` 表（`D-G92`／`D-G176③`）。
        _nfp = NO_FIXED_POINT.get(name)
        if _nfp:
            _mech, _reg = _nfp
            _why = (shifts.get(name) or {}).get('why', '')
            if bt is None:
                # 两个记录来源里**只剩一个**（该键按设计不在 `BASELINE tier=` 机读行）⇒ **没有可核的对**
                # ⇒ 算不出来，**不算绿**（方向安全：宁可 NOINFO，也不把"没得核"印成 PASS）。
                noinfo += 1
                print('WFREEZE_BLOCKVALUES_NOFIXPT key=%s mechanism=%s registered=%s block9=%s tier=absent live=%s'
                      '（**无字节不动点** ∧ 该键按设计不在机读行 ⇒ 两个记录来源只剩一个 ⇒ 算不出来，**不算绿**）'
                      % (name, _mech, _reg, b9, live))
            elif bt == 'CONFLICT' or bt != b9:
                bad += 1
                print('WFREEZE_BLOCKVALUES_HIT key=%s probs=block-selfcontradiction block9=%s tier=%s live=%s'
                      '（**这一层没有被放行**：块内两个授权来源互相矛盾 —— 九位行与 `BASELINE tier=` 机读行给出**不同**值）'
                      % (name, b9, bt, live))
            else:
                nofixpt += 1
                print('WFREEZE_BLOCKVALUES_NOFIXPT key=%s mechanism=%s registered=%s block9=%s tier=%s live=%s'
                      '（该产物**无字节不动点** ⇒ 沿用 `TIER_NA` 体例：只核块内两来源自洽，`live` **逐条上屏、不判**；'
                      '`shifts_why=%s`）'
                      % (name, _mech, _reg, b9, bt, live, (_why[:60] + '…') if len(_why) > 60 else (_why or '-')))
            continue
        probs = []
        if b9 != live: probs.append('nine-vs-live')
        if bt is not None:
            if bt == 'CONFLICT': probs.append('tier-self-contradiction')
            elif bt != live: probs.append('tier-vs-live')
            if bt != b9 and bt != 'CONFLICT': probs.append('block-selfcontradiction')
        if not probs:
            continue
        sh = shifts.get(name)
        reg_ok = True
        if sh:
            decl_ids = declared_ids(root)
            reg_ok = (sh['registered'] in decl_ids) if decl_ids is not None else True
        # 【`t34` 修】`bt is None`（该键**按设计**不在 `BASELINE tier=` 机读行里）⇒ **只核 `block9` 与 `live`**，
        #   `tier` 格跳过并上屏 `tier=absent-skipped`；且声明侧也必须写"缺"（写了真值反而不匹配 ⇒ 更严）。
        #   `bt` 非缺时**照旧**逐格核（不放宽）。
        tier_ok = True; tier_note = ''
        if sh:
            if bt is None:
                tier_ok = (sh['tier'] is None)
                tier_note = ' tier=absent-skipped（该键按设计不在机读行里 ⇒ 只核 block9 与 live）'
            else:
                tier_ok = (sh['tier'] == bt)
        if sh and reg_ok and sh['block9'] == b9 and tier_ok and sh['live'] == live:
            declared += 1
            print('WFREEZE_BLOCKVALUES_SHIFT key=%s probs=%s block9=%s tier=%s live=%s registered=%s why=%s%s（**具名声明**：逐条上屏，不进红；`live=` 被钉住 ⇒ 再漂一次仍红）'
                  % (name, ','.join(probs), b9, bt, live, sh['registered'], sh['why'][:60], tier_note))
        elif sh and not reg_ok:
            bad += 1
            print('WFREEZE_BLOCKVALUES_HIT kind=declaration-unregistered key=%s registered=%s（声明必须挂在一个**已入册**的缺陷号上：`defect-registry-declared.tsv` 里没有它）'
                  % (name, sh['registered']))
        else:
            bad += 1
            print('WFREEZE_BLOCKVALUES_HIT key=%s probs=%s block9=%s tier=%s live=%s（块里的值与现取不符／块内两个授权来源互相矛盾）'
                  % (name, ','.join(probs), b9, bt, live))
    for name, _r in NINE_PATHS:
        if name not in tier:
            tier_na.append(name)
    if tier_na:
        print('WFREEZE_BLOCKVALUES_TIER_NA keys=%s（机读行**按设计**只覆盖 7 键 ⇒ 这些键只由九位行授权，不判）'
              % ','.join(tier_na))
    # 模板面（**`t34` 口径 ② 收窄**：只对「**承载现取值的行**」判 —— 九位行 ∧ `inputs_fp` ∧ `BRIDGE_SRC_FP`）
    #   ⚠️ 为什么收窄：`D-G166` 的机制**恰恰只在这三处**（把**本应现取的值**写成字面量）；而
    #      `^# ARM-LOG-SHA …`／`^# COLUMN-CORPUS …`／散文声明行的裸 hex **各有活牙守着**
    #      （`arm-log-sha-check.sh`／`column-floor-check.sh`）⇒ 本面不再判它们，**只列不判**
    #      （避免"拿一条牙的射程换另一条"）。
    tstate = 'skipped(no-template-given)'
    if template == 'auto':
        # 【`t34`】`--template auto`：由**冻结器 `GENS`** 现取本代记录模板 ⇒ 仓内**不写死**任何世代/车道路径。
        _t = _freezer_record_txt(freezer) if freezer else None
        if _t:
            template = _t
            print('WFREEZE_TEMPLATE_AUTO src=freezer-GENS path=%s' % template)
        else:
            template = None
            tstate = 'NOINFO(template-auto-undecidable)'
            noinfo += 1
            print('WFREEZE_TEMPLATE=NOINFO reason=template-auto-undecidable freezer=%s（取不到本代记录模板 ⇒ **不算绿**）'
                  % (freezer or '<none>'))
    if template:
        if not os.path.exists(template):
            tstate = 'NOINFO(template-absent)'
            noinfo += 1     # 【`t34`】缺模板 ⇒ 进总体状态（`NOINFO` 不算绿；此前只打印、总体仍 PASS 是个洞）
            print('WFREEZE_TEMPLATE=NOINFO reason=template-absent path=%s（**缺模板 ⇒ 本面算不出来 ⇒ 不许当绿**）' % template)
        else:
            judged = []; notes = 0
            for i, l in enumerate(read_lines(template), 1):
                if not re.search(r'(?<![0-9a-f])[0-9a-f]{16}(?![0-9a-f])', l):
                    continue
                kind = template_line_kind(l)
                if kind == 'other':
                    notes += 1
                    print('WFREEZE_TEMPLATE_NOTE kind=other line=%d text=%s（**只列不判**：该行的值另有活牙守着 —— `arm-log-sha-check.sh`／`column-floor-check.sh`／散文）'
                          % (i, l.strip()[:110]))
                else:
                    judged.append((kind, i, l.strip()))
            if judged:
                bad += 1
                tstate = 'FAIL'
                for kind, i, txt in judged:
                    print('WFREEZE_TEMPLATE_HIT kind=%s line=%d text=%s（**承载现取值的行**里不许出现 16 位 hex 裸字面量 ⇒ 用 `{…}` 占位符）'
                          % (kind, i, txt[:120]))
            else:
                tstate = 'PASS'
            print('WFREEZE_TEMPLATE=%s path=%s hits=%d notes=%d' % (tstate, template, len(judged), notes))
    else:
        print('WFREEZE_TEMPLATE=%s（本面不在总体状态里、**不算绿**；要对模板判值须显式给 `--template`）' % tstate)
    st = 'FAIL' if bad else ('NOINFO' if noinfo else 'PASS')
    print('WFREEZE_BLOCKVALUES=%s gen=#%s keys=%d declared_shifts=%d nofixpt=%d bad=%d noinfo=%d cfg=%s'
          % (st, gen, len(NINE_PATHS), declared, nofixpt, bad, noinfo, cfg))
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
        # S1 正极：把 scan 域镜像进沙箱（含 roster 表）⇒ 档① PASS
        cands = scan_candidates(SELF_ROOT)
        for rel, _l, _v, _ln in cands:
            d = os.path.join(T, 'good', rel); os.makedirs(os.path.dirname(d), exist_ok=True)
            shutil.copy2(os.path.join(SELF_ROOT, rel), d)
        for _rel, _l, _v, suf in T17_ROSTER:
            if suf:
                p = os.path.join(T, 'good', suf); os.makedirs(os.path.dirname(p), exist_ok=True)
                open(p, 'w').write('x')
        sites = os.path.join(T, 'good', SITES_TSV)
        os.makedirs(os.path.dirname(sites), exist_ok=True)
        nt, nf, nr = emit_roster(os.path.join(T, 'good'), sites)
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'good'),
                              '--freezer', '/nonexistent'], capture_output=True, text=True).stdout
        arm('S1', 'WFREEZE_ROOTDEFAULT=PASS' in out, '干净镜像 ⇒ 档① PASS（%d 条派生式 / %d 个根站点；其余档 NOINFO）' % (nt, nr))
        # S2 反极：把某一条根站点的 dirname 砍掉一层 ⇒ 档① 必红并点名
        shutil.rmtree(os.path.join(T, 'bad'), ignore_errors=True)
        shutil.copytree(os.path.join(T, 'good'), os.path.join(T, 'bad'))
        p = os.path.join(T, 'bad', 'src/Linux/build/MilBridge/tools/analyze-layout-b34.py')
        s = open(p, encoding='utf-8').read()
        s = s.replace('os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(',
                      'os.path.dirname(os.path.dirname(os.path.dirname(', 1)
        open(p, 'w', encoding='utf-8').write(s)
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'bad'),
                              '--freezer', '/nonexistent'], capture_output=True, text=True).stdout
        arm('S2', 'WFREEZE_ROOTDEFAULT=FAIL' in out and 'file=src/Linux/build/MilBridge/tools/analyze-layout-b34.py' in out,
            '少一层 dirname ⇒ 档① FAIL 并点名该件')
        # S2b 反极（`t19` 扩面）：**不在 t17 roster 里**的根站点被砍一层 ⇒ 也必须红（这正是"12 条无牙"那一格）
        #   ⚠️ 构造：`src/Linux/build/close-wave.sh` 的根站点那行**逐字随落点变**（结构上游化把仓根深了一层：
        #      旧 `…")/.."` ⇒ 现 `…")/../../..""`）⇒ 首版写死 `)/.."` 的 arm **在落点变后 `hit=0` 自己假红**
        #      （本波实测：S2b 红）。⇒ 夹具改成**按形态现取**（`)/..…"` 的 n 层形态），并保留 `hit == 1` 断言
        #      —— **判据一字未动**（该行内容被改 ⇒ 档① 必红并点名），改的只是**夹具怎么找到那一行**。
        shutil.rmtree(os.path.join(T, 'bad2'), ignore_errors=True)
        shutil.copytree(os.path.join(T, 'good'), os.path.join(T, 'bad2'))
        p = os.path.join(T, 'bad2', 'src/Linux/build/close-wave.sh')
        s = open(p, encoding='utf-8').read().split('\n')
        hit = 0
        for i, l in enumerate(s):
            if 'dirname' in l and 'BASH_SOURCE[0]' in l and re.search(r'\)(?:/\.\.)+/?"', l):
                s[i] = re.sub(r'(\)(?:/\.\.)+/?)(\")', r'\1/..\2', l, count=1); hit += 1; break
        open(p, 'w', encoding='utf-8').write('\n'.join(s))
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'bad2'),
                              '--freezer', '/nonexistent'], capture_output=True, text=True).stdout
        arm('S2b', hit == 1 and 'WFREEZE_ROOTDEFAULT=FAIL' in out and 'src/Linux/build/close-wave.sh' in out,
            '`close-wave.sh`（t17 roster 之外）**多一层** dirname ⇒ 档① FAIL 并点名（扩面有效；hit=%d）' % hit)
        # S2c 反极：声明表缺失 ⇒ NOINFO（不算绿）
        shutil.rmtree(os.path.join(T, 'nosites'), ignore_errors=True)
        shutil.copytree(os.path.join(T, 'good'), os.path.join(T, 'nosites'))
        os.remove(os.path.join(T, 'nosites', SITES_TSV))
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'nosites'),
                              '--freezer', '/nonexistent'], capture_output=True, text=True).stdout
        arm('S2c', 'WFREEZE_ROOTDEFAULT=NOINFO' in out, '无声明表 ⇒ 档① NOINFO（空边响亮失败）')
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
        # S6/S7/S8 档④：合成冻结块（块内值与现取的三方关系）
        for tag, b9, bt, want, detail in [
            ('ok', 'live', 'live', 'PASS', '九位行 == 机读行 == 现取 ⇒ 档④ PASS'),
            ('stale', 'old', 'live', 'FAIL', '九位行写上一代值 ⇒ FAIL 并点名该键'),
            ('selfx', 'live', 'old', 'FAIL', '九位行与机读行互相矛盾 ⇒ FAIL（块内两个授权来源）'),
        ]:
            d = os.path.join(T, 'bv-' + tag)
            os.makedirs(os.path.join(d, 'src/Linux/samples/WpfTextDemo'), exist_ok=True)
            os.makedirs(os.path.join(d, 'src/Linux/build/SelfBuiltConfig.props').rsplit('/', 1)[0], exist_ok=True)
            open(os.path.join(d, 'src/Linux/build/SelfBuiltConfig.props'), 'w').write('<Configuration>Release</Configuration>\n')
            live = {}
            for n, rel in NINE_PATHS:
                q = os.path.join(d, rel.replace('{CFG}', 'Release'))
                os.makedirs(os.path.dirname(q), exist_ok=True)
                open(q, 'w').write('content-' + n)          # 每键**内容不同** ⇒ 真 sha16 不同
                live[n] = sha16(q)
            nine = ' '.join('`%s` `%s`' % (n, (live[n] if b9 == 'live' else 'b' * 16)) for n, _ in NINE_PATHS)
            row = ','.join('%s:%s' % (n, (live[n] if bt == 'live' else 'c' * 16)) for n, _ in NINE_PATHS)
            open(os.path.join(d, 'src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md'), 'w', encoding='utf-8').write(
                '# RE-FROZEN #99 —— 合成\n#   **九位（Release 权威件）**：%s\n'
                'BASELINE tier=default rep=1 config=%s result=PASS\n' % (nine, row))
            out = subprocess.run(['python3', os.path.abspath(__file__), '--root', d, '--freezer', '/nonexistent',
                                  '--sites', os.path.join(d, SITES_TSV)], capture_output=True, text=True).stdout
            arm('S6' + ('' if tag == 'ok' else tag[0]), ('WFREEZE_BLOCKVALUES=' + want) in out, detail)
        # S6nfp0／S6nfp（**`TASK-收尾-冻结口径` 加**，对应步②硬要求 2）：**无字节不动点的键**两极化。
        #   构造：九位行／机读行／现取三方，除"声明为无字节不动点"的那一键外**逐位相等**（⇒ 其余键不进判定）；
        #   该键的 `live` **与两个记录来源都不同**（复现现场："整波重建后记录一出生就过期"）。
        #     · S6nfp0 正极：`block9 == tier`（块内两来源自洽）⇒ 档 **PASS** ＋ 逐条上屏 `WFREEZE_BLOCKVALUES_NOFIXPT`
        #     · S6nfp  反极：`block9 != tier`（两来源互相矛盾）⇒ **必红并点名 `key=<该键>`**
        for tag, tier_mut, want, detail in (
                ('0', False, 'PASS', '`block9 == tier`（自洽）＋ `live` 漂了 ⇒ 档 **PASS** ＋ 逐条上屏 `WFREEZE_BLOCKVALUES_NOFIXPT`'),
                ('', True, 'FAIL', '把该键的 `block9` 与 `tier` 改成**不相等** ⇒ **必红并点名**（该层没有被放行）')):
            nfpname = sorted(NO_FIXED_POINT)[0]
            d = os.path.join(T, 'bv-nfp' + (tag or 'x'))
            os.makedirs(os.path.join(d, 'src/Linux/samples/WpfTextDemo'), exist_ok=True)
            os.makedirs(os.path.join(d, 'src/Linux/build'), exist_ok=True)
            open(os.path.join(d, 'src/Linux/build/SelfBuiltConfig.props'), 'w').write('<Configuration>Release</Configuration>\n')
            live = {}
            for n, rel in NINE_PATHS:
                q = os.path.join(d, rel.replace('{CFG}', 'Release'))
                os.makedirs(os.path.dirname(q), exist_ok=True)
                open(q, 'w').write('content-' + n)
                live[n] = sha16(q)
            nine = ' '.join('`%s` `%s`' % (n, ('b' * 16 if n == nfpname else live[n])) for n, _ in NINE_PATHS)
            row = ','.join('%s:%s' % (n, ('c' * 16) if (n == nfpname and tier_mut)
                                      else ('b' * 16) if n == nfpname else live[n]) for n, _ in NINE_PATHS)
            open(os.path.join(d, 'src/Linux/samples/WpfTextDemo/ACCEPTANCE-BASELINE.md'), 'w', encoding='utf-8').write(
                '# RE-FROZEN #99 —— 合成\n#   **九位（Release 权威件）**：%s\n'
                'BASELINE tier=default rep=1 config=%s result=PASS\n' % (nine, row))
            out = subprocess.run(['python3', os.path.abspath(__file__), '--root', d, '--freezer', '/nonexistent',
                                  '--sites', os.path.join(d, SITES_TSV)], capture_output=True, text=True).stdout
            arm('S6nfp' + tag,
                ('WFREEZE_BLOCKVALUES=' + want) in out
                and (('WFREEZE_BLOCKVALUES_NOFIXPT key=%s' % nfpname) in out) == (want == 'PASS')
                and (('WFREEZE_BLOCKVALUES_HIT key=%s' % nfpname) in out) == (want == 'FAIL'),
                detail)
        # S9 反极：模板里塞回裸 hex ⇒ 档④ 红（**牙对模板**）
        # S9：口径收窄后，裸 hex 必须塞在**承载现取值的行**（九位行 / `inputs_fp` / `BRIDGE_SRC_FP`）才会红 ——
        #   夹具同步改成九位行带裸 hex（**不是放宽**：判据仍是"模板里塞回裸 hex ⇒ 必红"，只是位置按新域）。
        tpl = os.path.join(T, 'rec.txt')
        open(tpl, 'w').write('# template\n#   **九位（Release 权威件）**：`bridge` `4e25e4b27d4d5ae1`／`pc` `{PC}`\n')
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', SELF_ROOT, '--freezer', '/nonexistent',
                              '--template', tpl], capture_output=True, text=True).stdout
        arm('S9', 'WFREEZE_TEMPLATE=FAIL' in out and 'WFREEZE_TEMPLATE_HIT' in out and 'kind=nine' in out,
            '九位行里塞裸 16 位 hex ⇒ 模板面 FAIL 并点名 `kind=nine`')
        # S9b（新）：裸 hex **只**出现在 `ARM-LOG-SHA`（非承载行）⇒ **只列不判**：PASS ＋ 有 NOTE（这是口径②的边界）
        tpl2 = os.path.join(T, 'rec2.txt')
        open(tpl2, 'w').write('# template\n# ARM-LOG-SHA arm=tab-anchor sha16=2e62d68ed5edd5e7\n'
                              '#   **`inputs_fp` = `{INFP}`**（占位符，不是裸值）\n')
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', SELF_ROOT, '--freezer', '/nonexistent',
                              '--template', tpl2], capture_output=True, text=True).stdout
        arm('S9b', 'WFREEZE_TEMPLATE=PASS' in out and 'WFREEZE_TEMPLATE_NOTE' in out and 'WFREEZE_TEMPLATE_HIT' not in out,
            '裸 hex 只在 `ARM-LOG-SHA`（非承载行）⇒ PASS ＋ 出 NOTE（**只列不判**的边界）')
        # S12 正极（**内容锚的两极化**）：把某站点**整体下移 N 行**（纯插空行/注释）⇒ **档① 仍 PASS**。
        #   这一格正是 `t20` 落地暴露的病：行号锚下"加两行"会假红（`t27` 现场 bad=3），内容锚下不该红。
        shutil.rmtree(os.path.join(T, 'shift'), ignore_errors=True)
        shutil.copytree(os.path.join(T, 'good'), os.path.join(T, 'shift'))
        for rel, pad in (('Guide.Linux/verify-all.sh', 5), ('src/Linux/build/close-wave.sh', 3), ('src/Linux/build/MilBridge/tools/analyze-layout-b34.py', 7)):
            q = os.path.join(T, 'shift', rel)
            if not os.path.exists(q):
                continue
            body = open(q, encoding='utf-8').read().split('\n')
            open(q, 'w', encoding='utf-8').write('\n'.join(['# shift-pad %d' % i for i in range(pad)] + body))
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'shift'),
                              '--freezer', '/nonexistent'], capture_output=True, text=True).stdout
        arm('S12', 'WFREEZE_ROOTDEFAULT=PASS' in out,
            '三个站点各整体下移 5/3/7 行 ⇒ 档① **仍 PASS**（内容锚：行号漂移不判红）')
        # S13 反极：把某站点的**那一行内容**改掉（改根层数）⇒ 内容锚下 key 变 ⇒ 必红并点名
        shutil.rmtree(os.path.join(T, 'bad3'), ignore_errors=True)
        shutil.copytree(os.path.join(T, 'good'), os.path.join(T, 'bad3'))
        q = os.path.join(T, 'bad3', 'src/Microsoft.DotNet.Wpf.Linux/src/DirectWrite/wic-shim/frames-gen.py')
        b = open(q, encoding='utf-8').read()
        b2 = re.sub(r"dirname\(os\.path\.dirname\(os\.path\.dirname\(os\.path\.dirname\(", "dirname(os.path.dirname(os.path.dirname(", b, count=1)
        open(q, 'w', encoding='utf-8').write(b2)
        out = subprocess.run(['python3', os.path.abspath(__file__), '--root', os.path.join(T, 'bad3'),
                              '--freezer', '/nonexistent'], capture_output=True, text=True).stdout
        arm('S13', ('WFREEZE_ROOTDEFAULT=FAIL' in out) and ('frames-gen.py' in out),
            '某站点行内容被改（多一层）⇒ 内容锚下 key 变 ⇒ **FAIL 并点名**（必须重发 roster）')
        # S10 cwd 硬化（`E①`）：**同一条命令、两个不同 cwd** ⇒ 档① 判词行必须**逐字相同**
        #   （"判定不是 cwd 的函数"这句话必须**有读数**，不能只写在件头）
        #   ⚠️ 第二个 `cwd` **必须是一个真存在的目录**：结构上游化把 `build/` 挪成 `src/Linux/build/` 之后，
        #      原写 `SELF_ROOT/build` ⇒ `FileNotFoundError` **整个 `--selftest` 崩在 S10**（本波实测：
        #      HEAD 版与改后版都在此崩；⇒ 本波顺手按**现落点**修，判据（两个 cwd 判词逐字相同）一字未动）。
        r1 = subprocess.run(['python3', os.path.abspath(__file__), '--root', SELF_ROOT, '--freezer', '/nonexistent'],
                            capture_output=True, text=True, cwd='/')
        r2 = subprocess.run(['python3', os.path.abspath(__file__), '--root', SELF_ROOT, '--freezer', '/nonexistent'],
                            capture_output=True, text=True, cwd=os.path.join(SELF_ROOT, 'src', 'Linux', 'build'))
        l1 = [l for l in r1.stdout.split('\n') if l.startswith('WFREEZE_ROOTDEFAULT=')]
        l2 = [l for l in r2.stdout.split('\n') if l.startswith('WFREEZE_ROOTDEFAULT=')]
        arm('S10', bool(l1) and l1 == l2,
            '两个 cwd（`/` 与 `<仓>/src/Linux/build`）下档① 判词行**逐字相同** ⇒ 判定不是 cwd 的函数｜cwd=/ ⇒ %s｜cwd=<仓>/src/Linux/build ⇒ %s'
            % (l1[0][:90] if l1 else 'NO-LINE', l2[0][:90] if l2 else 'NO-LINE'))
        # S11 反极：相对 root ⇒ 档① **不当绿**（不可判／红）
        r3 = subprocess.run(['python3', os.path.abspath(__file__), '--root', 'rel-root', '--freezer', '/nonexistent'],
                            capture_output=True, text=True, cwd='/tmp')
        arm('S11', 'WFREEZE_ROOTDEFAULT=NOINFO' in r3.stdout or 'WFREEZE_ROOTDEFAULT=FAIL' in r3.stdout,
            '相对 root（`rel-root`）⇒ 档① 判 NOINFO/FAIL（**不许当绿**）')
    finally:
        shutil.rmtree(T, ignore_errors=True)
    print('WFREEZE_CONSISTENCY_SELFTEST=%s cases=%d pass=%d fail=%d' % ('PASS' if nfail == 0 else 'FAIL', npass + nfail, npass, nfail))
    return 0 if nfail == 0 else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default=SELF_ROOT)
    ap.add_argument('--freezer', default=os.path.expanduser('~/w21-verify/w27-freeze.py'))
    ap.add_argument('--decl-override'); ap.add_argument('--pairs-override')
    ap.add_argument('--sites', default=SITES_TSV)
    ap.add_argument('--shifts', default=SHIFTS_TSV)
    ap.add_argument('--template')
    ap.add_argument('--emit-roster')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest: return selftest()
    root = os.path.realpath(a.root)
    if a.emit_roster:
        out = a.emit_roster if os.path.isabs(a.emit_roster) else os.path.join(root, a.emit_roster)
        n, nf, nr = emit_roster(root, out)
        print('WFREEZE_EMIT_ROSTER=%s path=%s derived=%d files=%d root_sites=%d' % ('OK', out, n, nf, nr))
        return 0
    s1 = sec_rootdefault(root, a.sites)
    s2 = sec_decl(root, a.freezer, a.decl_override)
    pairs = None
    if a.pairs_override:
        pairs = [tuple(x.split(',')) for x in a.pairs_override.split(';')]
    s3 = sec_nineauth(root, pairs)
    s4 = sec_blockvalues(root, a.shifts, a.template, a.freezer)
    st = [s1, s2, s3, s4]
    overall = 'FAIL' if 'FAIL' in st else ('NOINFO' if 'NOINFO' in st else 'PASS')
    print('WFREEZE_CONSISTENCY=%s rootdefault=%s decl=%s nineauth=%s blockvalues=%s（四档互不代偿）'
          % (overall, s1, s2, s3, s4))
    return {'PASS': 0, 'FAIL': 1, 'NOINFO': 3}[overall]


if __name__ == '__main__':
    sys.exit(main())

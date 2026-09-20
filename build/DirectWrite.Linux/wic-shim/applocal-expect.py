#!/usr/bin/env python3
"""app-local **期望集合**枚举器（T2，2026-09-14）—— 只读，不改任何文件。

【为什么要它】校验器原先"拿**现存**副本去比权威" ⇒ **副本被删掉 ⇒ 它不在集合里 ⇒ 静默 PASS**。
本脚本把"**期望存在的副本集合**"从"现存文件"解耦出来：期望只由**仓库里的声明式来源**算出来：
  · `<Reference Include="X">`（含 `<HintPath>` 与 `<Private>`）—— 引用名、解析目录、是否随包拷（`Private=false` 不期望副本）
  · `<ProjectReference Include="…">` —— 工程到工程的边
  · 工程自己的输出目录（`AppendTargetFrameworkToOutputPath` + `TargetFramework` ⇒ `bin/<Cfg>[/<TFM>]`）
  · ITEMS 表里的权威路径（权威件本身就是"期望存在"的一条）
**关键性质**：期望集合的**基数不依赖现场文件是否存在**（删掉任何一份副本，本脚本的输出逐字不变）。
【覆盖边界（主控 2026-09-14 任务 5 要求如实报）】原生件（`libwpf*.so` / `wpfgfx_cor3.so`）的拷贝点是
  **shell `cp`**（实测 `build/MilBridge/run.sh:95`、`:228`）与发布脚本 ⇒ **没有声明式来源** ⇒ 本脚本对它们
  输出 `#UNKNOWN`（"这一条期望算不出来"），并列出"需要什么才能算"，**不**退回"只查现存副本"。

输出（stdout，`|` 分隔）：
  #REFDIR|<dir>                          被任何 HintPath 指向的输出目录（解析源）
  #EXPECT|<dir>|<item 文件名>|<来源链>    期望在该目录存在的副本
  #UNKNOWN|<item>|<原因>                 算不出期望的件（如实报，不静默）
  #INVISIBLE|<kind>|<file:line>|<原文>   **主扫**（`build/**/*.sh`）里的拷贝点（TAPPS 2026-09-15 增补说明）
        kind ∈ {write, read}；**注意：主扫有两条自带的边界，都由此处的输出显式承认**：
        ① **每文件最多印 3 条只读行**（计数是全量）⇒ 被截掉的条数印在
           `#INVISIBLE-CAPPED|read|<file>|<省略条数>|<该文件全量条数>`
        ② 主扫**只扫 `build/**/*.sh`** ⇒ 它看不见 (a) `build/**` 之外的 `.sh`
           （实测：`tests/**/run-wpftextdemo.sh` 里有 `wpfgfx_cor3.so` 的写点）
           与 (b) 任何 **MSBuild 拷贝**（`Directory.Build.targets` 的 `<Copy>`，实测 2 处）
           ⇒ 这些由 `#INVISIBLE-EXT|kind|file:line|原文` 补报（**补扫**，与主扫不重叠）。
  #SUMMARY|refdirs=N|expect=M|projects=P|unknown=K|unresolved_hintpath=U|
           invisible_copysites=W+R|invisible_write=W|invisible_read=R|
           invisible_capped=C|invisible_ext_write=XW|invisible_ext_read=XR
        （**新增的三个字段一律追加在末尾** ⇒ 旧消费者按位置读前 8 个字段不受影响）
用法：applocal-expect.py <REPO> [HINTPATH_ROOTS]
"""
import os
import re
import sys
import collections

REPO = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")

def _decl_candidates():
    """配置声明件的**候选路径**（按顺序；`#49` §10 裁定 ③ 定死的两条，不许加第三条）。

    ⚠️【`#49` `C1b`（W52C2 2026-09-20）】**顺序就是语义**：
      ① `<argv[1]>/build/SelfBuiltConfig.props` —— 被扫描/被比较的**那棵树自己的**声明
         （沙箱/合成权威根必须能自己声明配置：自检 P 段就靠这一条）。
      ② **脚本相对** `<本文件>/../../../build/SelfBuiltConfig.props` —— 与 `check-applocal-sync.sh:150`
         （`. "$(dirname "$0")/../../../build/selfbuilt-config.sh"`）读的**同一处**；
         用它兜住"调用方树的声明件缺失、但工具本身在一个完好 checkout 里"的情形。
      ③ 两者都没有（或都解析不出合法值）⇒ **不返回默认值** ⇒ 调用方 `NOINFO` + 非 0（见下）。
    """
    here = os.path.dirname(os.path.abspath(__file__))
    return [os.path.join(REPO, "build", "SelfBuiltConfig.props"),
            os.path.normpath(os.path.join(here, "..", "..", "..", "build", "SelfBuiltConfig.props"))]


def _selfbuilt_config():
    """读**唯一声明**（`build/SelfBuiltConfig.props`）里的自产件配置；**读不到 ⇒ None**。

    ⚠️【`#39` 阶段 2/3】本文件原先在若干处把**自产件配置写死为 Debug**（即拼出「bin 下的 Debug 目录」）⇒ 切 Release 后
    它会去比对**错的权威**（而且**不报错**）。这里与 `build/selfbuilt-config.sh`、`port-lib.py`
    读的是**同一份声明**（import 与读取都不算"第二处逻辑"，写死值才算）。

    ⚠️⚠️【`#49` `C1b`（W52C2 2026-09-20），主控 §10 裁定 ③：**静默回退 `Debug` 必须消失**】
    改前：`except OSError: return "Debug"` / `return … if mm else "Debug"` ⇒ **权威路径会被静默地
    按 Debug 拼出来**，而调用方（`check-applocal-sync.sh`）用的是**真声明**（现场 `Release`）⇒
    两张 ITEMS 表在**合成权威根**里各说各话（W52C 实测：自检 P 段 `MISSING=5` 假红，根因就是这里）。
    **本函数现在没有任何默认值**：两条候选都拿不到合法值 ⇒ 返回 `None` ⇒ 模块级 `NOINFO` + `exit 2`。
    """
    import re as _re
    for decl in _decl_candidates():
        try:
            txt = open(decl, encoding="utf-8").read()
        except OSError:
            continue
        mm = _re.search(r"<WpfLinuxSelfBuiltConfiguration[^>]*>([^<]*)<", txt)
        v = mm.group(1).strip() if mm else ""
        if v in ("Debug", "Release"):            # 合法值只此两个（与 selfbuilt-config.sh 同口径）
            return v
    return None


CFG = _selfbuilt_config()
if CFG is None:
    # 【`NOINFO` 不许当绿（本仓铁律）】**非 0 退出**是这里的判据本体：调用方 `check-applocal-sync.sh`
    #   的 `EXPECT_OK` 只在"命令成功"时为 1 ⇒ 本支路会让它印 `APPSYNC=NOINFO` + `exit 3`（不是 PASS）。
    _cand = " ｜ ".join(_decl_candidates())
    sys.stderr.write("applocal-expect.py: NOINFO 读不到配置声明（候选：%s）⇒ 不猜默认值（改前会静默回退 Debug）；"
                     "把声明件放回其中一处即可\n" % _cand)
    print("#NOINFO|config-decl|%s|读不到配置声明 ⇒ 不猜默认值（改前静默回退 Debug）" % _cand)
    sys.exit(2)

HP_ROOTS = os.path.abspath(sys.argv[2] if len(sys.argv) > 2 else REPO)

# 权威表（与 check-applocal-sync.sh 的 ITEMS 保持一致；改一处要同步另一处 —— 由 check 的 --list-items 校验）
ITEMS = [
    ("libwpfwic.so", REPO + "/build/DirectWrite.Linux/wic-shim/libwpfwic.so"),
    ("libwpfwin32.so", REPO + "/src/WpfGfx.Linux.Native/bin/libwpfwin32.so"),
    ("DirectWrite.Linux.Provider.dll", REPO + "/build/DirectWrite.Linux/Provider/bin/" + CFG + "/DirectWrite.Linux.Provider.dll"),
    ("WpfGfx.Linux.dll", REPO + "/src/WpfGfx.Linux/bin/" + CFG + "/net10.0/WpfGfx.Linux.dll"),
    ("ReachFramework.dll", REPO + "/build/ReachFramework.Linux/bin/" + CFG + "/ReachFramework.dll"),
    # 【W23C / `D-A2`，2026-09-16】PC 原先**两张 ITEMS 表里都没有** ⇒ 它既没有逐份判据（check 侧），
    #   也没有声明式期望（本侧）⇒ **删掉任何一份 PC 副本连 `MISSING` 都不会报**（那是另一半洞）。
    #   补在这里（**声明式来源那一路**：权威路径 + 各 csproj 的 Reference/HintPath/ProjectReference 闭包），
    #   **不手写任何副本清单**。权威 = check-applocal-sync.sh 的 ITEMS 同一路径（两处必须一致）。
    ("PresentationCore.dll", REPO + "/build/PresentationCore.Linux/bin/" + CFG + "/PresentationCore.dll"),
    # 【`#49` `C1`（车道 W52C，2026-09-20）】PF/WB 原先**两张 ITEMS 表里都没有** ⇒ 它们既没有逐份判据
    #   （check 侧），也没有声明式期望（本侧）⇒ **删掉任何一份 PF/WB 副本连 `MISSING` 都不报**
    #   （`D-A2` 同族）。补在这里：权威路径 + 各 csproj 的 Reference/HintPath/ProjectReference 闭包，
    #   **不手写任何副本清单**。权威路径与 check-applocal-sync.sh 的 `ITEMS` 逐字相同
    #   （**两处必须一致** —— 由 check 的 `--list-items` 逐项校验）。
    ("PresentationFramework.dll", REPO + "/build/PresentationFramework.Linux/bin/" + CFG + "/PresentationFramework.dll"),
    ("WindowsBase.dll", REPO + "/build/WindowsBase.Linux/bin/" + CFG + "/WindowsBase.dll"),
    ("wpfgfx_cor3.so", ""),                      # 无单一权威 ⇒ 不覆盖（见文件头）
]
PROPS = {
    "MSBuildThisFileDirectory": None,            # 逐工程填
    "WpfLinuxRoot": REPO + "/",
    "RepoRoot": REPO + "/",
    "WpfLinuxBinDir": REPO + "/build",
    "DwRoot": REPO + "/build/DirectWrite.Linux",
    # 【`#49` §10.5 裁定，新项 `C1e`（车道 W52C3，2026-09-20）】**必须跟随声明，不许写字面量。**
    #   本行原来是 `"Debug"` —— 于是"读声明"（`_selfbuilt_config()`，本文件 `:40-78`）与"替换字面量"
    #   **在同一条数据链上分叉**：`ITEMS` 用声明值（现场 `Release`），而 csproj 里的
    #   `$(WpfLinuxSelfBuiltConfiguration)` 被替换成 `Debug` ⇒ `REFDIR`（"被 HintPath 引用 ⇒ 解析源"
    #   那张表）**按另一个配置拼出来** ⇒ 拿它去决定"哪些非宿主目录要判"（`is_refdir()`）＝ 用错的尺子。
    #   实测（W52C2 量化）：只改这一行，`#REFDIR` 14 → 23、且**只在现清单里的目录恰好 1 个**、
    #   **只在跟随声明清单里的 10 个**。`CFG` 就是 `_selfbuilt_config()` 读出来的那个值（无默认值：
    #   读不到时模块级已 `NOINFO` + `exit 2`，见 `:58-68`）⇒ 本行**不是**"换个新字面量"。
    "WpfLinuxSelfBuiltConfiguration": CFG,
    "RootNamespace": "",
}
UNRESOLVED = []


def project_files():
    for dp, dn, fn in os.walk(HP_ROOTS):
        if "/upstream/" in dp + "/" or "/obj/" in dp + "/" or "/.artifacts" in dp:
            continue
        for f in fn:
            if f.endswith(".csproj"):
                yield os.path.join(dp, f)


def subst(text, projdir):
    out = text
    for k, v in PROPS.items():
        val = projdir + "/" if k == "MSBuildThisFileDirectory" else (v or "")
        out = out.replace("$(%s)" % k, val)
    return out



def project_refs(p, text):
    """<ProjectReference> 的目标工程（**路径也要做属性替换** —— 实测 DWF 写的是 $(WpfLinuxRoot)…）"""
    out = []
    for r in re.findall(r'<ProjectReference\s+Include="([^"]+)"', text):
        q = subst(r, os.path.dirname(p))
        if "$(" in q:
            UNRESOLVED.append((os.path.relpath(p, REPO), r))
            continue
        q = q if os.path.isabs(q) else os.path.join(os.path.dirname(p), q)
        q = os.path.realpath(q)
        if os.path.exists(q):
            out.append(q)
    return out


def refs_of(text):
    """⇒ list[(name, private:bool, hintdir|None)]（逐 <Reference> 块解析）"""
    out = []
    for blk in re.findall(r"<Reference\b[^>]*>.*?</Reference>|<Reference\b[^>]*/>", text, re.S):
        m = re.search(r'Include="([^"]+)"', blk)
        if not m:
            continue
        name = m.group(1).split(",")[0].strip()
        priv = not re.search(r"<Private>\s*false\s*</Private>", blk, re.I)
        out.append((name, priv, None))
    return out


def outdirs(projdir, text, cfg):
    m = re.search(r"<TargetFramework>([^<]+)</TargetFramework>", text)
    tfm = m.group(1).strip() if m else ""
    append = not re.search(r"<AppendTargetFrameworkToOutputPath>\s*false\s*</AppendTargetFrameworkToOutputPath>", text, re.I)
    cand = [os.path.join(projdir, "bin", cfg) + ("/" + tfm if (append and tfm) else "")]
    return [os.path.normpath(c) for c in cand if os.path.isdir(c)]



def invisible_copy_sites():
    """脚本里**会创建/删除副本**的拷贝点（= 本枚举器看不见的那些路径）。只报事实，不改任何脚本。

    判据（每条都过筛，避免把注释/打印当拷贝点）：
      · 只看 `build/**/*.sh`（排除 upstream/artifacts 与**本仪器自身** `wic-shim/**`）
      · 排除注释行（`#` 开头）与纯打印行（echo/printf）
      · 提到某个 ITEM 文件名
      · 含 `cp|install|mv|rm` 或输出重定向 ⇒ **写点**（会改变副本集合）
      · 其余（find / 赋值 / nm / sha / 条件判断）⇒ **只读**（只读或枚举，不产生副本）
    ⇒ 返回值 [(kind, "file:line", 该行原文)]，kind ∈ {write, read}

    ⚠️ **这个函数的覆盖边界本身也要"主动承认"**（TAPPS 2026-09-15）——它**不是**全仓拷贝点清单：
      ① 每文件最多印 3 条只读行（见 main 的 capping）⇒ 截掉的条数由 `#INVISIBLE-CAPPED` 报出；
      ② 只扫 `build/**/*.sh` ⇒ 别处的 `.sh`（`tests/**` 实测有 `wpfgfx_cor3.so` 写点）与
         **MSBuild `<Copy>`**（`*.csproj/*.targets/*.props` 实测 2 处）**完全不在这份清单里**
         ⇒ 由 `invisible_copy_sites_ext()` 补扫。
    """
    names = [os.path.basename(n) for n, _ in ITEMS]
    writes, reads = [], []
    for dp, dn, fn in os.walk(os.path.join(REPO, "build")):
        if "/upstream/" in dp + "/" or "/.artifacts" in dp or dp.endswith("/wic-shim"):
            continue
        for f in sorted(fn):
            if not f.endswith(".sh"):
                continue
            fp = os.path.join(dp, f)
            try:
                lines = open(fp, encoding="utf-8", errors="replace").read().splitlines()
            except OSError:
                continue
            for i, ln in enumerate(lines, 1):
                t = ln.strip()
                if not t or t.startswith("#"):
                    continue
                if re.match(r"(echo|printf|say)\b", t):
                    continue
                if not any(n in ln for n in names):
                    continue
                where = "%s:%d" % (os.path.relpath(fp, REPO), i)
                if re.search(r"(^|[;&|(]\s*)(cp|install|mv|rm)\s|>>?\s*\S*%s" % re.escape(names[0]), t) or \
                   re.search(r"(^|[;&|(]\s*)(cp|install|mv|rm)\s", t):
                    writes.append(("write", where, t[:160]))
                else:
                    reads.append(("read", where, t[:160]))
    return writes + reads


def invisible_copy_sites_indirect():
    """补扫 ②：**源路径藏在变量里**的拷贝点（TAPPS 2026-09-15 新增）—— 只报写点。

    为什么必须有它（主扫的**第三条**自带边界：它只认"字面提到 ITEM 文件名的行"）：
      `cp -f "$NATIVE_AUTH" "$c"` 这种行**一个字面 ITEM 名字都没有** ⇒ 主扫既不算写点也不算只读，
      它**完全不存在于任何清单里**。实测（都是本仓里真在跑的写点）：
        · `build/close-wave.sh:130` —— `NATIVE_AUTH="…/libwpfwin32.so"`（:99 定义）⇒ 拷贝到各副本
        · `build/MilBridge/run.sh:210` —— `refresh_applocal` 的 `cp -f "$f" "$d/$base"`
          （**REPORT §24.8 提到的"现有检测器漏报"就是它**）
        · `tests/…/run-wpfprobe.sh:210/:213/:214`、`run-wpftextdemo.sh:563`、`run-hellowpf.sh:197`
          —— 把 `libwpfwin32.so` **以 4–5 个 Windows DLL 别名**（uxtheme/wtsapi32/shell32/
          PresentationNative_cor3）拷进 app 目录（部署期止损；**陈旧别名同样没人判**）
    判据（"轻量数据流"：不做完全程分析，**只在本文件内**把"赋值/数组元素里含 ITEM 权威路径特征
      （字面 ITEM 名 **或** 以 `/bin/` 或 `/.artifacts/` 结尾的路径）"的变量名记下来，再看后续
      `cp|install|mv|rm <含该变量的参数>` 行；变量在拷贝行**之前**出现才算）：
      · 只在 `.sh` 里找；排除注释/纯打印；文件级排除同主扫
      · **与主扫及补扫①去重**由调用方完成（这里把主扫能抓到的行也返回，调用方过滤）
    ⇒ 返回值 [(kind, "file:line", 该行原文)]（含"经变量 $X"的说明）
    """
    names = [os.path.basename(n) for n, _ in ITEMS]
    writes = []
    for dp, dn, fn in os.walk(REPO):
        if "/upstream/" in dp + "/" or "/.artifacts" in dp or "/obj/" in dp + "/" \
           or dp.endswith("/wic-shim"):
            continue
        for f in sorted(fn):
            if not f.endswith(".sh"):
                continue
            fp = os.path.join(dp, f)
            try:
                lines = open(fp, encoding="utf-8", errors="replace").read().splitlines()
            except OSError:
                continue
            taint = {}          # 变量名 → 证据（一行原文的片段）
            arrtaint = {}       # 数组名 → 证据（供 `for x in "${arr[@]}"` 传播）
            in_arr = None       # 多行数组字面量：`pairs=(` 之后到 `)` 之前（实测 run.sh:192-197 就是这种）
            for i, ln in enumerate(lines, 1):
                t = ln.strip()
                if not t or t.startswith("#"):
                    continue
                # ---- 多行数组字面量：`NAME=(` … 元素 … `)` ----
                if in_arr is None:
                    m0 = re.search(r"(?:^|[;&|(]\s*)(?:local\s+|declare\s+(?:-a\s+)?)?([A-Za-z_][A-Za-z0-9_]*)=\(\s*$", t)
                    if m0:
                        in_arr = m0.group(1)
                        if any(n in ln for n in names):
                            arrtaint[in_arr] = ln.strip()[:70]
                        continue
                else:
                    if any(n in ln for n in names):
                        arrtaint.setdefault(in_arr, ln.strip()[:70])
                    if re.match(r"^\s*\)\s*;?\s*$", ln):
                        in_arr = None
                    continue
                # 变量绑定：字面 ITEM 名，或**权威产物路径特征**（`/bin/<cfg>/`、`…/bin/<file>`、
                #   `/.artifacts/`），或引用了**已认定权威**的另一个变量（逐行前向传播）。
                #   ⚠️ 刻意**不**认"随便一个赋值含 ITEM 名"以外的长路径 —— 否则 `SRC_BAK="$BAK_DIR/…"`
                #   这类**备份路径**会被误当权威源（第一版就是这么误报的，见报告 §3 的自纠）。
                m = re.match(r'(?:local\s+|declare\s+(?:-a\s+)?)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$', t)
                if m:
                    var, val = m.group(1), m.group(2)
                    # ⚠️ 一行可能有**多个赋值**（`A="…"; B="…"`）⇒ 只看**第一处**的值当证据，
                    #   否则同一行后半段的别的变量会把前半段"染"上（第一版就是这么误报 `SRC_BAK` 的）。
                    code = val.split(";")[0].split("#")[0]
                    looks_auth = (any(n in code for n in names)
                                  # "产物路径"特征：以 `/bin/<cfg>` 结尾（目录）
                                  or re.search(r"/bin/(?:debug|release)[^/\s\"']*$", code) is not None
                                  or "/.artifacts/" in code
                                  or any(re.search(r"\$\{?%s\b" % re.escape(tv), code) for tv in taint))
                    if looks_auth:
                        taint[var] = code.strip()[:70]
                    continue
                # `for x in "${arr[@]}"` ⇒ 把数组的证据传给循环变量（`for f in "${pairs[@]}"`）
                man = re.search(r"\bfor\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+\"?\$\{?([A-Za-z_][A-Za-z0-9_]*)", t)
                if man and man.group(2) in arrtaint:
                    taint[man.group(1)] = "数组 $%s：%s" % (man.group(2), arrtaint[man.group(2)])
                # `for x in <含 ITEM 名的字面量>` ⇒ 直接染
                m2 = re.search(r"\bfor\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+(.*)$", t)
                if m2 and any(n in m2.group(2) for n in names):
                    taint[m2.group(1)] = m2.group(2).strip()[:70]
                if re.match(r"(echo|printf|say)\b", t):
                    continue
                if not re.search(r"(^|[;&|(]\s*)(cp|install|mv|rm)\s", t):
                    continue
                used = [v for v in taint if re.search(r"\$\{?%s\b" % re.escape(v), t)]
                if used:
                    where = "%s:%d" % (os.path.relpath(fp, REPO), i)
                    ev = "；".join("$%s←%s" % (v, taint[v]) for v in sorted(used))
                    writes.append(("write", where, (t[:110] + "　（经变量 %s）" % ev)))
    return writes


def invisible_copy_sites_ext():
    """补扫 ①：`invisible_copy_sites()` **明确看不见的写点**（TAPPS 2026-09-15 新增）—— 只报写点。

    为什么必须有它：主扫只扫 `build/**/*.sh`，于是这些**会创建/覆盖副本**的行两边都漏：
      · `tests/**/run-wpftextdemo.sh:179/:191` —— `cp` 存/还原 `.artifacts/publish/…/wpfgfx_cor3.so`
        （**发布目录 = 该 `.so` 的唯一真身**，而 `.artifacts` 不在 SCAN_ROOTS 里）
      · **MSBuild `<Copy>`**：`build/{DirectWrite.Linux,MilBridge/tests}/Directory.Build.targets`
        的 `SyncProviderAuthority`（两处；它们正是"陈旧副本"的机制级修法，却不在任何清单里）
    判据（**故意收窄，只报"写"**；把 `HintPath`/注释/`<Message>` 这类**声明式或纯打印**行排除，
    否则清单会被 80+ 条非拷贝行淹掉 ⇒ 又是"清单看起来全、其实没人读"的那类假保证）：
      · 文件后缀 ∈ {.sh,.csproj,.targets,.props,.ps1}；排除 `upstream/`/`.artifacts`/`obj/`/`.git`/本仪器目录
      · 排除注释（`#`/`//`/`<!--`）与纯打印（`echo|printf|say|Message`）
      · 判为写点 = ① `sh` 形态：行首/分隔符后是 `cp|install|mv|rm` **且**该行提到 ITEM 文件名；
                   ② **MSBuild `<Copy>`**：行里有 `<Copy\b` 或 `DestinationFolder=`/`DestinationFiles=`，
                      且**本文件内**存在把该行引用的属性绑到某个 ITEM 文件名的行
                      （实测两处都是 `<Copy SourceFiles="$(ProviderAuthorityPath)" …>` ⇒ 靠
                       `$(ProviderAuthorityPath)` 的**定义行**建立关联）。
    ⇒ 返回值 [(kind, "file:line", 该行原文)]，kind 恒为 {"write"}（**不与主扫重叠**）
    """
    names = [os.path.basename(n) for n, _ in ITEMS]
    exts = (".sh", ".csproj", ".targets", ".props", ".ps1")
    writes = []
    for dp, dn, fn in os.walk(REPO):
        if "/upstream/" in dp + "/" or "/.artifacts" in dp or "/obj/" in dp + "/" \
           or "/.git" in dp + "/" or dp.endswith("/wic-shim"):
            continue
        for f in sorted(fn):
            if not f.endswith(exts):
                continue
            fp = os.path.join(dp, f)
            try:
                lines = open(fp, encoding="utf-8", errors="replace").read().splitlines()
            except OSError:
                continue
            # 本文件内"哪些 MSBuild 属性绑定到了某个 ITEM 文件名"（供 <Copy> 关联用）
            prop2name = {}
            for ln in lines:
                for m in re.finditer(r"\$\(([A-Za-z_][A-Za-z0-9_]*)\)", ln):
                    for nm in names:
                        if nm in ln:
                            prop2name.setdefault(m.group(1), nm)
            for i, ln in enumerate(lines, 1):
                t = ln.strip()
                if not t or t.startswith("#") or t.startswith("//") or t.startswith("<!--"):
                    continue
                if re.match(r"(echo|printf|say|Message)\b", t):
                    continue
                where = "%s:%d" % (os.path.relpath(fp, REPO), i)
                hits_name = any(n in ln for n in names)
                if re.search(r"(^|[;&|(]\s*)(cp|install|mv|rm)\s", t):
                    if hits_name:
                        writes.append(("write", where, t[:160]))
                    continue
                if re.search(r"<Copy\b|DestinationFolder=|DestinationFiles=", t):
                    props = set(re.findall(r"\$\(([A-Za-z_][A-Za-z0-9_]*)\)", t))
                    via = sorted(props & set(prop2name))
                    if hits_name or via:
                        tail = ("　（写点经属性 %s ⇒ %s）" % (",".join("$(%s)" % p for p in via),
                                                              prop2name[via[0]])) if via else ""
                        writes.append(("write", where, (t[:140] + tail)))
    return writes


def main():
    projs = {}
    for p in project_files():
        try:
            text = open(p, encoding="utf-8-sig", errors="replace").read()
        except OSError:
            continue
        m = re.search(r"<AssemblyName>([^<]+)</AssemblyName>", text)
        if m:
            asm = m.group(1).strip()
        else:
            base = os.path.basename(p)[:-len(".csproj")]
            asm = base[:-len(".Linux")] if base.endswith(".Linux") else base
        projs[p] = dict(dir=os.path.dirname(p), text=text, asm=asm,
                        refs=[r for r in refs_of(text) if r[1]],          # Private=false ⇒ 不期望副本
                        pref=project_refs(p, text),
                        dirs={c: outdirs(os.path.dirname(p), text, c) for c in ("Debug", "Release")})
    byasm = collections.defaultdict(list)
    for p, d in projs.items():
        byasm[d["asm"]].append(p)
    dir2proj = {}
    for p, d in projs.items():
        for c, ds in d["dirs"].items():
            for o in ds:
                dir2proj.setdefault(o, p)

    # 解析源目录（HintPath 指向的目录）——与 check-applocal-sync.sh 的 REFDIR 同源
    refdirs = set()
    for p, d in projs.items():
        for hp in re.findall(r"<HintPath>([^<]+)</HintPath>", d["text"]):
            r = subst(hp, d["dir"])
            if "$(" in r:
                UNRESOLVED.append((os.path.relpath(p, REPO), hp))
                continue
            if not os.path.isabs(r):
                r = os.path.join(d["dir"], r)
            refdirs.add(os.path.dirname(os.path.realpath(r)))

    # 权威目录也算"解析/生产源"：任何工程 HintPath 指向某件的权威目录 ⇒ 该件在期望集里
    auth_dir_item = {}
    for name, auth in ITEMS:
        if auth:
            auth_dir_item.setdefault(os.path.dirname(os.path.realpath(auth)), set()).add(name)

    stem2item = {n[:-len(".dll")] if n.endswith(".dll") else n: n for n, _ in ITEMS}
    memo = {}

    def E(p, stack=frozenset()):
        """⇒ {item: 来源链}（只从**声明式来源**算：Reference/HintPath/ProjectReference/自身产出）"""
        if p in memo:
            return memo[p]
        if p in stack:
            return {}
        d = projs[p]
        rel = os.path.relpath(p, REPO)
        out = {}
        own = stem2item.get(d["asm"])
        if own:
            out[own] = "%s **产出的程序集本身**" % rel
        for name, priv, _ in d["refs"]:                       # <Reference Include> 且 Private≠false
            it = stem2item.get(name)
            if it:
                out[it] = '%s 的 <Reference Include="%s">' % (rel, name)
            for q in byasm.get(name, []):                     # 引用的是**工程产物** ⇒ 连带它的闭包
                if "/CycleStub." in q:                        # 循环桩只用于断环 ⇒ 不把它的依赖当传递依赖
                    continue
                for it2, why2 in E(q, stack | {p}).items():
                    out.setdefault(it2, "%s →(引用 %s)→ %s" % (rel, name, why2))
        for q in d["pref"]:
            qrel = os.path.relpath(q, REPO)
            for it2, why2 in E(q, stack | {p}).items():
                out.setdefault(it2, "%s →(ProjectReference)→ %s" % (rel, why2))
            qa = projs.get(q, {}).get("asm")
            qi = stem2item.get(qa)
            if qi:
                out.setdefault(qi, "%s →(ProjectReference)→ %s **产出的程序集**" % (rel, qrel))
        for hp in re.findall(r"<HintPath>([^<]+)</HintPath>", d["text"]):
            r = subst(hp, d["dir"])
            if "$(" in r:
                continue
            r = r if os.path.isabs(r) else os.path.join(d["dir"], r)
            rd = os.path.dirname(os.path.realpath(r))
            for it2 in auth_dir_item.get(rd, ()):             # 指向某件的**权威目录**
                out.setdefault(it2, "%s 的 <HintPath> → %s（权威目录）" % (rel, os.path.relpath(rd, REPO)))
            q = dir2proj.get(rd)
            if q and q != p and "/CycleStub." not in q:       # HintPath 指向别的工程输出 ⇒ 取它的闭包
                for it2, why2 in E(q, stack | {p}).items():
                    out.setdefault(it2, "%s 的 <HintPath> → %s" % (rel, why2))
        memo[p] = out
        return out

    # 期望：每个工程（非循环桩）的每个**已存在**输出目录 × 它的引用闭包
    exp = {}
    for p, d in projs.items():
        if "/CycleStub." in p:                                   # 循环桩：按构造不是普通 app-local
            continue
        e = E(p)
        if not e:
            continue
        for cfg, ds in d["dirs"].items():
            for o in ds:
                for it in sorted(e):
                    exp[(o, it)] = e[it]
    # 权威件本身也必须存在（权威枚举的一部分）
    for name, auth in ITEMS:
        if auth:
            exp[(os.path.dirname(os.path.realpath(auth)), name)] = "权威件本身的目录（权威枚举）"

    dbg = os.environ.get("APEXPECT_DEBUG", "")
    if dbg:
        for (o, it), why in sorted(exp.items()):
            if dbg in o:
                sys.stderr.write("DEBUG %s/%s  ← %s\n" % (o, it, why))
    for rd in sorted(refdirs):
        print("#REFDIR|%s" % rd)
    for (o, it), why in sorted(exp.items()):
        print("#EXPECT|%s|%s|%s" % (o, it, why))
    covered = {it for (_o, it) in exp}
    for name, auth in ITEMS:
        if name in covered:
            continue
        if not auth:
            print("#UNKNOWN|%s|无单一权威（跨波重建/发布脚本产物）⇒ 期望算不出；需要 owner 声明期望表" % name)
        else:
            print("#UNKNOWN|%s|所有引用点都无声明式来源（原生件由 shell cp 拷贝：见 build/MilBridge/run.sh:95/:228）⇒ 需要 owner 声明期望表" % name)
    all_sites = invisible_copy_sites()
    nw_all = len([1 for k, _w, _l in all_sites if k == "write"])
    nr_all = len(all_sites) - nw_all
    sites = all_sites
    nw = nw_all
    seen = {}
    capped = []
    for k, where, ln in sites:                      # 只读类：每文件最多留 3 条（计数仍按全量）
        f = where.split(":")[0]
        if k == "read":
            seen[f] = seen.get(f, 0) + 1
            if seen[f] > 3:
                continue
        capped.append((k, where, ln))
    sites = capped
    # 【TAPPS 2026-09-15】截断**不许静默**：主扫的 `invisible_read` 是**全量**计数，而打印出来的只读行
    #   比它少（实测 17 vs 15）⇒ 旧输出里这个差额**没有任何字样**。现在逐文件印 `#INVISIBLE-CAPPED`。
    n_capped = 0
    kept = {}
    for k, where, _ln in sites:
        if k == "read":
            f = where.split(":")[0]
            kept[f] = kept.get(f, 0) + 1
    for f in sorted(seen):
        drop = seen[f] - kept.get(f, 0)
        if drop > 0:
            n_capped += drop
            print("#INVISIBLE-CAPPED|read|%s|%d|%d" % (f, drop, seen[f]))
    for k, where, ln in sites:
        print("#INVISIBLE|%s|%s|%s" % (k, where, ln))
    # 【TAPPS 2026-09-15】补扫：主扫明确的盲区（`build/**` 之外的 .sh + MSBuild `<Copy>`）—— **只报写点**
    #   去重：主扫已报过的 `file:line` 不再出现在补扫里（否则"20 + 4"会被读成 24 个不同的拷贝点）
    main_where = {w for _k, w, _l in all_sites}
    ext_w = [s for s in invisible_copy_sites_ext() if s[1] not in main_where]
    for k, where, ln in ext_w:
        print("#INVISIBLE-EXT|%s|%s|%s" % (k, where, ln))
    # 【TAPPS 2026-09-15】补扫 ②：**源路径藏在变量里**的写点（主扫一条都抓不到：它只认字面文件名）
    ind_w = [s for s in invisible_copy_sites_indirect()
             if s[1] not in main_where and s[1] not in {w for _k, w, _l in ext_w}]
    for k, where, ln in ind_w:
        print("#INVISIBLE-INDIRECT|%s|%s|%s" % (k, where, ln))
    print("#SUMMARY|refdirs=%d|expect=%d|projects=%d|unknown=%d|unresolved_hintpath=%d|invisible_copysites=%d|invisible_write=%d|invisible_read=%d|invisible_capped=%d|invisible_ext_write=%d|invisible_ext_read=%d|invisible_indirect_write=%d"
          % (len(refdirs), len(exp), len(projs), len([n for n, _ in ITEMS if n not in covered]), len(UNRESOLVED),
             nw_all + nr_all, nw_all, nr_all, n_capped, len(ext_w), 0, len(ind_w)))
    for rel, hp in UNRESOLVED[:10]:
        print("#UNRESOLVED|%s|%s" % (rel, hp))


if __name__ == "__main__":
    main()

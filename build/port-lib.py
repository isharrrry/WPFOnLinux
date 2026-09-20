#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
通用 WPF 库项目 Linux 化移植器。

把上游 (dotnet/wpf) 的 csproj 转成可在 Linux / net10.0 上编译的 csproj：
  1. 切断 Arcade 继承（Directory.Build.props/targets）
  2. 展开 WpfSourceDir / WpfSharedDir / WpfCommonDir / WpfCodeGenDir 等 Arcade 注入变量
  3. 路径分隔符 \ -> /
  4. 移除 ProjectReference / vcxproj / 私有 WinForms 引用
  5. 移除 Perl / T4 / AvTrace 代码生成目标
  6. PackageReference 版本去变量化
  7. 输出改动清单

用法：
    python3 build/port-lib.py WindowsBase [PresentationCore ...]
产物：
    build/<Name>.Linux/<Name>.Linux.csproj
    build/<Name>.Linux/PORT-CHANGES.md
"""
import os
import re
import sys
import glob as globmod
import subprocess
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
OUTROOT = os.path.dirname(HERE)


def _upstream_repo():
    """上游 dotnet/wpf 仓库根：优先环境变量，缺省为本仓库 upstream/wpf 只读副本。"""
    env = os.environ.get("UPSTREAM_WPF_ROOT") or os.environ.get("UpstreamWpfRoot")
    if env:
        return os.path.normpath(env)
    return os.path.join(OUTROOT, "upstream", "wpf")


def upstream_nowarn(proj_dir):
    """收集上游最近若干层 Directory.Build.props/Props 里的 NoWarn。

    上游把 `CA1420;WPF0001` 放在 src/Microsoft.DotNet.Wpf/Directory.Build.Props ——
    其中 WPF0001 是 **error 级**诊断，不搬就会把可编过的工程判死。"""
    toks = []
    repo = os.path.normpath(_upstream_repo())
    d = os.path.normpath(proj_dir)
    while True:
        for fn in ("Directory.Build.props", "Directory.Build.Props"):
            f = os.path.join(d, fn)
            if os.path.exists(f):
                txt = open(f, encoding="utf-8-sig", errors="ignore").read()
                for m in re.findall(r"<NoWarn>([^<]+)</NoWarn>", txt):
                    for tok in re.split(r"[;,]", m):
                        tok = tok.strip()
                        if tok and not tok.startswith("$") and tok not in toks:
                            toks.append(tok)
        if d == repo or os.path.dirname(d) == d:
            break
        d = os.path.dirname(d)
    return toks


UPSTREAM = os.path.join(_upstream_repo(), "src", "Microsoft.DotNet.Wpf", "src")

# Arcade / 上游注入的目录变量
VARS = {
    "WpfSourceDir": UPSTREAM + "/",
    "WpfSharedDir": UPSTREAM + "/Shared/",
    "WpfCommonDir": UPSTREAM + "/Common/",
    "WpfCodeGenDir": UPSTREAM + "/Common/src/CodeGen/",
    "WpfArcadeDir": "/nonexistent-arcade/",
    "RepoRoot": _upstream_repo() + "/",
    "WpfRepoRoot": _upstream_repo() + "/",
}

# 已知包版本（本机 SDK 10.0.111 / net10.0 可解析的稳定版）
PKG_VERSIONS = {
    "System.Diagnostics.EventLog": "9.0.0",
    "System.Windows.Extensions": "9.0.0",
    "System.Security.Cryptography.Xml": "9.0.0",
    "System.Configuration.ConfigurationManager": "9.0.0",
    "System.Security.Permissions": "9.0.0",
    "System.IO.Packaging": "9.0.0",
    "System.Formats.Nrbf": "9.0.0",
    "Microsoft.Build.Framework": "15.9.20",
    "Microsoft.Build.Utilities.Core": "15.9.20",
    "Microsoft.Build.Tasks.Core": "15.9.20",
    "System.CodeDom": "9.0.0",
    "System.Reflection.MetadataLoadContext": "9.0.0",
    "System.Text.Encodings.Web": "9.0.0",
    "System.Runtime.CompilerServices.Unsafe": "6.1.0",
    "System.Threading.Tasks.Extensions": "4.6.3",
    "System.Memory": "4.6.3",
}

# 包名变量 -> 实际包名（上游 Directory.Build.props 由 Arcade 注入）
PKG_NAMES = {
    "SystemIOPackagingPackage": "System.IO.Packaging",
}

# 需要整段删除的 ItemGroup 元素
DROP_ITEMS = {
    "ProjectReference",
    "MicrosoftPrivateWinFormsReference",
    "Reference",
    "Service",
}
# 需要整段删除的 Target（代码生成 / 平台特定）
DROP_TARGETS = {
    "GenerateSources",
    "GenerateAvTrace",
    "GenerateAvMessages",
    "TransformAll",
    "GenerateReferenceSource",
    "CreateGeneratedAssemblyInfo",
}
# 需要整段删除的 Import（Arcade / 代码生成）
DROP_IMPORT_KEYWORDS = (
    "Arcade",
    "AvTrace",
    "DesignTimeTextTemplating",
    "CodeGen",
    "Microsoft.TextTemplating",
    "Directory.Build",
)


def expand(text, proj_dir):
    """展开 MSBuild 变量并规范化路径。"""
    for k, v in VARS.items():
        text = text.replace("$(" + k + ")", v)
    # MSBuild 会 trim 属性值空白，这里必须对齐，否则带尾空格的路径全部解析失败
    text = text.strip()
    text = text.replace("\\", "/")
    return text


def abs_if_exists(path, proj_dir):
    if os.path.isabs(path):
        return path
    return os.path.normpath(os.path.join(proj_dir, path))


def _declared_config():
    """读**唯一声明**（`build/SelfBuiltConfig.props`）里的自产件配置。

    ⚠️【`#39` 阶段 2/3】生成器**也不许自己猜配置**：原先 `find_built_dll` 用 glob 取
    `hits[-1]`（排序最后一个），而 Debug 与 Release 同时在盘上时那等于**由字典序**决定
    引用指向哪个配置 —— 正是"同一语义多处 ⇒ 必然分叉"那一族。现在以声明为准。"""
    decl = os.path.join(OUTROOT, "build", "SelfBuiltConfig.props")
    try:
        txt = open(decl, encoding="utf-8").read()
    except OSError:
        return None
    m = re.search(r"<WpfLinuxSelfBuiltConfiguration[^>]*>([^<]*)<", txt)
    return m.group(1).strip() if m else None


def find_built_dll(proj_name):
    """在本工程 build/<Name>.Linux/bin/<声明配置>/ 下找已编译出的同名 DLL。"""
    cfg = _declared_config()
    if cfg:
        want = os.path.join(OUTROOT, "build", proj_name + ".Linux", "bin", cfg, proj_name + ".dll")
        if os.path.exists(want):
            return want
        print(f"[{proj_name}] ⚠️ 声明配置 {cfg} 下没有构建物（{want}）⇒ 回退 glob 兜底（**如实报出**，不许静默）")
    pat = os.path.join(OUTROOT, "build", proj_name + ".Linux", "bin", "**", proj_name + ".dll")
    hits = [p for p in sorted(globmod.glob(pat, recursive=True))
            if "/ref/" not in p and "/obj/" not in p]
    return hits[-1] if hits else None


def find_csproj(name):
    """上游 csproj 定位：先试 UPSTREAM/<name>/<name>.csproj，再递归搜索嵌套目录。

    M3 的三个小项目全部嵌套（UIAutomation/UIAutomationTypes.csproj、
    System.Windows.Input.Manipulations/...、System.Windows.Primitives/...），
    旧写法 UPSTREAM/<name>/<name>.csproj 对它们全部落空。"""
    direct = os.path.join(UPSTREAM, name, name + ".csproj")
    if os.path.exists(direct):
        return direct
    hits = [p for p in sorted(globmod.glob(
        os.path.join(UPSTREAM, "**", name + ".csproj"), recursive=True))
        if "/ref/" not in p.replace(os.sep, "/")]
    return hits[0] if hits else None


def port(name):
    src_csproj = find_csproj(name)
    if not src_csproj:
        print(f"[跳过] 找不到 {name}.csproj（UPSTREAM 下任何层级）")
        return None
    proj_dir = os.path.dirname(src_csproj)
    raw = open(src_csproj, encoding="utf-8-sig", errors="ignore").read()

    changes = []
    outdir = os.path.join(OUTROOT, "build", name + ".Linux")
    os.makedirs(outdir, exist_ok=True)

    # ---------- 1. 收集 Compile 项 ----------
    # 必须用 XML 解析器：正则无法正确处理
    #   <Compile Include="A.cs"><Link>x</Link></Compile>
    #   <Compile Include="B.cs" />
    # 的边界，非贪婪匹配会跨条目吞掉后续 Include（曾导致 Grant.cs 丢失）。
    items = []       # [(原始 Include 串, 属性字典)]
    removes = set()  # <Compile Remove="..." />
    wild_count = 0
    try:
        root = ET.fromstring(raw)
        for elem in root.iter():
            tag = elem.tag.split("}")[-1]  # 去掉可能的 XML 命名空间
            if tag == "Compile":
                inc = elem.get("Include")
                rem = elem.get("Remove")
                if rem:
                    rp = os.path.normpath(abs_if_exists(expand(rem, proj_dir), proj_dir))
                    removes.add(rp)
                    if "*" in rp:
                        removes.update(os.path.normpath(x)
                                       for x in globmod.glob(rp, recursive=True))
                elif inc:
                    items.append((inc, dict(elem.attrib)))
    except ET.ParseError as e:
        print(f"[{name}] XML 解析失败，回退正则：{e}")
        items = [(m, {}) for m in re.findall(r"<Compile\s+Include=\"([^\"]+)\"", raw)]

    compiles, missing = [], []
    seen = set()
    for inc, _attrs in items:
        p = expand(inc, proj_dir)
        ap = abs_if_exists(p, proj_dir)
        # 通配符展开
        if ("*" in p) or ("?" in p):
            matched = sorted(globmod.glob(ap, recursive=True))
            wild_count += len(matched)
            for m in matched:
                m = os.path.normpath(m)
                if m in seen or m in removes:
                    continue
                seen.add(m)
                compiles.append(m)
            continue
        if ap in seen:
            continue
        seen.add(ap)
        if os.path.exists(ap):
            compiles.append(ap)
        else:
            missing.append((inc, ap))
    # 应用 Remove
    compiles = [c for c in compiles if os.path.normpath(c) not in removes]

    # 按项目排除 Windows-only 源文件（build/excludes/<Name>.txt，每行一个路径片段）。
    # ⚠ 过滤必须放在**最后**（默认 glob 与大小写找回都可能加回文件）——见本函数末尾调用。
    excl_file = os.path.join(HERE, "excludes", name + ".txt")
    excluded = []

    def apply_excludes(items):
        """对最终编译清单应用 excludes 过滤；返回 (保留清单, 剔除清单)。"""
        if not os.path.exists(excl_file):
            return items, []
        pats = [l.strip().replace("\\", "/") for l in open(excl_file, encoding="utf-8")
                if l.strip() and not l.strip().startswith("#")]
        kept, drop = [], []
        for c in items:
            norm = os.path.normpath(c).replace("\\", "/")
            if any(p in norm for p in pats):
                drop.append(os.path.relpath(norm, proj_dir))
            else:
                kept.append(c)
        return kept, drop

    # 上游未禁用 SDK 默认 glob 时（如 System.Xaml），默认项会吞掉目录下全部 .cs。
    # 这里显式等价展开，排除 bin/obj/ref。
    # 注意：上游禁用默认项有两种写法——`EnableDefaultCompileItems=false` 与
    # `EnableDefaultItems=false`（PresentationCore 用后者）。只认前者会误纳 9 个
    # 上游本就没编的文件（见 build/excludes/PresentationCore.txt 的 A 类）。
    default_glob_off = bool(re.search(r"<EnableDefaultCompileItems>\s*false", raw, re.I)) \
        or bool(re.search(r"<EnableDefaultItems>\s*false", raw, re.I))
    default_added = 0
    if not default_glob_off:
        skip_dirs = ("bin", "obj", "ref", "Generated")
        for f in sorted(globmod.glob(os.path.join(proj_dir, "**", "*.cs"), recursive=True)):
            f = os.path.normpath(f)
            rel = os.path.relpath(f, proj_dir)
            if any(rel.split(os.sep)[0] == d for d in skip_dirs):
                continue
            if f in seen or os.path.normpath(f) in removes:
                continue
            seen.add(f)
            compiles.append(f)
            default_added += 1

    # 上游相对路径解析不到的：先按「大小写不敏感精确路径」找回，再按 basename 兜底。
    #
    # Linux 文件系统区分大小写，而上游 csproj 的 Compile Include 大小写与磁盘不符
    # （PresentationCore 有 212 条，如 MS\Internal\... vs MS/internal/...）。旧找回循环
    # 只搜 Common/Shared，项目自身目录的大小写错配全部漏掉。现改为：一次性建项目目录的
    # 小写索引，精确路径命中且唯一时直接采用；不唯一或未命中再走 basename 兜底。
    recovered = 0
    ci_index = {}
    for dirpath, _dn, fn in os.walk(proj_dir):
        for f in fn:
            ci_index.setdefault(
                os.path.normpath(os.path.join(dirpath, f)).lower(), []).append(
                os.path.join(dirpath, f))

    still_missing = []
    for inc, ap in missing:
        hits = ci_index.get(os.path.normpath(ap).lower())
        found = hits[0] if hits and len(hits) == 1 else None
        if found is None:
            base = os.path.basename(ap)
            for root in (os.path.join(UPSTREAM, "Common"), os.path.join(UPSTREAM, "Shared"),
                         os.path.join(UPSTREAM, "Common", "src")):
                for dirpath, _dn, fn in os.walk(root):
                    if base in fn:
                        found = os.path.join(dirpath, base)
                        break
                if found:
                    break
        if found:
            if os.path.normpath(found) not in seen:
                seen.add(os.path.normpath(found))
                compiles.append(found)
            recovered += 1
        else:
            still_missing.append((inc, ap))

    # ★ excludes 过滤放在最后：此时 compiles 已包含「csproj 显式 Include + 默认 glob 展开
    #   + 大小写/basename 找回」三类来源，excludes 才能对全部来源生效（旧版在默认 glob
    #   之前过滤，glob 加回的文件无法剔除——PresentationCore 因此多纳了 9 个文件）。
    compiles, excluded = apply_excludes(compiles)

    # ---------- 2. 收集 EmbeddedResource / WPF Resource ----------
    # 必须用 XML 解析：资源项常带**多行元数据**（GenerateSource/Type/ManifestResourceName），
    # 其中 ManifestResourceName 决定运行期资源名——丢了它资源就找不回来（如 split.cur /
    # splitopen.cur 的 SplitCursor / SplitOpenCursor）。旧正则只搬第一个、且元数据全丢。
    #
    # ⚠ 两类资源语义不同，必须分开处理（2026-09-10 实测，代价是运行期文本渲染全废）：
    #   · <EmbeddedResource> → 程序集清单资源，但 **清单名必须显式给**：本脚本把
    #     RootNamespace 统一写成 MS.Internal，靠 SDK 推导会得到 `MS.Internal.<文件名>.resources`，
    #     与 gen-sr.py 生成的 `new ResourceManager("<AssemblyName>.Resources.Strings")` 必然不一致
    #     （表现为资源表静默失效、靠 catch(MissingManifestResourceException) 回落内联串）。
    #   · <Resource>（WPF 资源）→ 必须打成 `$(AssemblyName).g.resources` 流；若降级成
    #     EmbeddedResource 会**双重失效**：既不进 .g.resources，又因缺
    #     `Type=Non-Resx`+`WithCulture=false` 被 SDK 静默丢弃（PresentationCore 的 4 个
    #     复合字体就是这样一个都没进程序集，运行期字体族/文本必炸）。
    embedded = []        # [(绝对路径, [(元数据标签, 值)], 原始 Include 串)]
    wpf_resources = []   # 同上，但来自 <Resource>
    try:
        res_root = ET.fromstring(raw)
        for elem in res_root.iter():
            tag = elem.tag.split("}")[-1]
            if tag not in ("EmbeddedResource", "Resource"):
                continue
            inc = elem.get("Include")
            if not inc:
                continue
            ap = abs_if_exists(expand(inc, proj_dir), proj_dir)
            meta = []
            for child in elem:
                ctag = child.tag.split("}")[-1]
                meta.append((ctag, (child.text or "").strip()))
            bucket = wpf_resources if tag == "Resource" else embedded
            if ("*" in ap) or ("?" in ap):
                # 通配符资源（如 PresentationCore 的 Fonts/*.CompositeFont）：必须展开，
                # 复合字体资源缺了会直接影响运行期字形回退。元数据按 MSBuild 语义套用到每个匹配项。
                for hit in sorted(globmod.glob(ap, recursive=True)):
                    if os.path.isfile(hit):
                        bucket.append((os.path.normpath(hit), list(meta), inc))
                continue
            if os.path.exists(ap):
                bucket.append((ap, meta, inc))
    except ET.ParseError:
        for inc in re.findall(r"<EmbeddedResource\s+Include=\"([^\"]+)\"", raw):
            ap = abs_if_exists(expand(inc, proj_dir), proj_dir)
            if os.path.exists(ap):
                embedded.append((ap, [], inc))

    # ---------- 2b. 上游未禁用默认资源项时，SDK 会 glob `**/*.resx` ----------
    # 本脚本无条件写 `EnableDefaultEmbeddedResourceItems=false`，于是 WindowsBase /
    # System.Xaml 这类**没有显式 resx 项**的工程实测 0 个清单资源（它们的 SR 表整体失效）。
    # 这里等价补上：上游没禁用默认项就自行 glob，并同样显式命名。
    default_res_off = bool(re.search(r"<EnableDefaultEmbeddedResourceItems>\s*false", raw, re.I)) \
        or bool(re.search(r"<EnableDefaultItems>\s*false", raw, re.I))
    if not default_res_off:
        known = {os.path.normpath(p) for p, _m, _i in embedded}
        for f in sorted(globmod.glob(os.path.join(proj_dir, "**", "*.resx"), recursive=True)):
            rel = os.path.relpath(f, proj_dir)
            if any(part in ("bin", "obj", "ref") for part in rel.split(os.sep)):
                continue
            if os.path.normpath(f) not in known:
                embedded.append((os.path.normpath(f), [], rel))

    def manifest_name(abs_path, meta, inc):
        """清单资源名：优先上游显式值 → Link → 相对项目路径；一律以 AssemblyName 打头。

        规则来源：gen-sr.py 用 `--basename "<Name>.Resources.Strings"` 生成 SR.g.cs，
        运行期是 `new ResourceManager("<Name>.Resources.Strings", asm)`，清单名必须逐字对齐。"""
        for k, v in meta:
            if k == "ManifestResourceName" and v:
                return v, True
        rel = None
        for k, v in meta:
            if k == "Link" and v:
                rel = v.replace("\\", "/")
                break
        if rel is None:
            rel = os.path.relpath(abs_path, proj_dir).replace(os.sep, "/")
            if rel.startswith("../"):
                rel = os.path.basename(abs_path)
        rel = re.sub(r"\.[^./]+$", "", rel)          # 去扩展名
        return "%s.%s" % (name, rel.replace("/", ".")), False

    # ---------- 3. 统计被丢弃的东西 ----------
    pr_count = len(re.findall(r"<ProjectReference\b", raw))
    vc_count = len(re.findall(r"\.vcxproj", raw))
    priv_count = len(re.findall(r"<MicrosoftPrivateWinFormsReference\b", raw))
    tgt_dropped = [t for t in DROP_TARGETS if re.search(r'<Target[^>]*Name="%s"' % t, raw)]
    imp_dropped = sum(1 for line in raw.splitlines()
                      if "<Import" in line and any(k in line for k in DROP_IMPORT_KEYWORDS))

    # ---------- 4. 生成新 csproj ----------
    defines = ";".join(re.findall(r"<DefineConstants>([^<]+)</DefineConstants>", raw))
    defines = re.sub(r"\$\([^)]+\)", "", defines).strip(";")
    # 去掉平台/Assembly 相关杂项；拼接时先清理空段，避免生成 `;WINDOWS_BASE_OR_PC` 这种前导分号
    if name != "WindowsBase":
        defines = ";".join(x for x in (defines, "WINDOWS_BASE_OR_PC") if x)

    def relocatable(p):
        """绝对路径 → $(UpstreamWpfRoot)/$(WpfLinuxRoot) 变量形式，保证生成物可搬迁。

        两个变量的值约定**以斜杠结尾**（Directory.Upstream.props 里 EnsureTrailingSlash
        保证）。注意：本脚本的 UPSTREAM 指向 <上游仓库>/src/Microsoft.DotNet.Wpf/src，
        而变量 $(UpstreamWpfRoot) 指向 <上游仓库> 根——拼回时要补上中间两段。"""
        rp = os.path.normpath(p).replace(os.sep, "/")
        up = os.path.normpath(UPSTREAM).replace(os.sep, "/")
        repo = os.path.normpath(OUTROOT).replace(os.sep, "/")
        if rp.startswith(up + "/"):
            return "$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/" + rp[len(up) + 1:]
        if rp.startswith(repo + "/"):
            rel = rp[len(repo) + 1:]
            # ⚠️【`#39` 阶段 2/3】仓库内的自产件路径**不许写死配置**：
            #   `build/<X>.Linux/bin/Debug/<X>.dll` ⇒ `build/<X>.Linux/bin/$(Configuration)/<X>.dll`，
            #   否则"切 Release"必须逐个重生成 + 逐个 sed（本仓已登记同族教训）。
            rel = re.sub(r"(?<=/bin/)(?:Debug|Release)(?=/)", "$(Configuration)", rel, count=1)
            return "$(WpfLinuxRoot)" + rel
        return rp

    out = []
    out.append("<Project>")
    out.append("  <Import Project=\"Sdk.props\" Sdk=\"Microsoft.NET.Sdk\" />")
    out.append("  <Import Project=\"$(MSBuildThisFileDirectory)../Directory.Upstream.props\" />")
    out.append("  <PropertyGroup>")
    out.append("    <TargetFramework>net10.0</TargetFramework>")
    out.append("    <AssemblyName>%s</AssemblyName>" % name)
    out.append("    <RootNamespace>%s</RootNamespace>" % ("System.Windows" if name.startswith("Windows") else "MS.Internal"))
    out.append("    <AllowUnsafeBlocks>true</AllowUnsafeBlocks>")
    out.append("    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>")
    out.append("    <EnableDefaultEmbeddedResourceItems>false</EnableDefaultEmbeddedResourceItems>")
    # CA1416 = 平台兼容分析器对 Windows-only API 的噪声（移植工程的本底预期），压制以对齐"0 警"门禁。
    # 同时**搬运上游 csproj 自己的 NoWarn**（如 PresentationCore 的 SYSLIB5005）——
    # 旧版硬编码会把它们丢掉，白白多出十几条警告。
    base_nowarn = ["0618", "CS3016", "CS0067", "CS0169", "CS0414", "CS0649", "CS1591",
                   "CS8632", "CS0219", "CS8981", "CA1416"]
    up_nowarn = []
    for m in re.findall(r"<NoWarn>([^<]+)</NoWarn>", raw):
        for tok in re.split(r"[;,]", m):
            tok = tok.strip()
            if tok and not tok.startswith("$") and tok not in up_nowarn:
                up_nowarn.append(tok)
    for tok in upstream_nowarn(proj_dir):
        if tok not in up_nowarn:
            up_nowarn.append(tok)
    nowarn = base_nowarn + [t for t in up_nowarn if t not in base_nowarn]
    out.append("    <NoWarn>$(NoWarn);%s</NoWarn>" % ";".join(nowarn))
    out.append("    <DefineConstants>%s</DefineConstants>" % defines)
    out.append("    <LangVersion>latest</LangVersion>")
    out.append("    <Nullable>disable</Nullable>")
    out.append("    <ImplicitUsings>disable</ImplicitUsings>")
    out.append("    <GenerateAssemblyInfo>false</GenerateAssemblyInfo>")
    out.append("    <GenerateDocumentationFile>false</GenerateDocumentationFile>")
    out.append("    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>")
    out.append("    <EnablePInvokeAnalyzer>false</EnablePInvokeAnalyzer>")
    out.append("    <ProduceReferenceAssembly>false</ProduceReferenceAssembly>")
    # 搬运上游的 GenerateDependencyFile=false：不搬会让下游在 .deps.json 生成阶段炸
    # （实测：PF pass2 报 `MSB4018 ArgumentException: An item with the same key has already
    #  been added. Key: ReachFramework`，上游 RF:9 / PF:12 / SP-ref:9 都有这一条）。
    if re.search(r"<GenerateDependencyFile>\s*false\s*</GenerateDependencyFile>", raw, re.I):
        out.append("    <GenerateDependencyFile>false</GenerateDependencyFile>")
    # 统一公开签名（只含公钥的 snk，非机密）：上游 WindowsBase/PresentationCore/PresentationFramework
    # 用 `InternalsVisibleTo("X, PublicKey=<WCP>")` 授权友元，未签名的消费方会被 CS0281 全量拒绝
    # （实测 PF 不签名 → CS0281×720）。.NET Core 不校验强名称，公开签名即可满足 IVT 匹配。
    # 统一在此声明可让所有移植工程一致签名，并消掉「被引用方未签名」的 CS8002 噪声。
    key = os.path.join(HERE, "keys", "WcpPublicKey.snk")
    if os.path.exists(key):
        out.append("    <SignAssembly>true</SignAssembly>")
        out.append("    <PublicSign>true</PublicSign>")
        out.append("    <AssemblyOriginatorKeyFile>%s</AssemblyOriginatorKeyFile>" % relocatable(key))
    else:
        print(f"[{name}] ⚠ 缺少 {key}：不启用公开签名，消费方会因 IVT(PublicKey=WCP) 报 CS0281")
    out.append("  </PropertyGroup>")

    # 包引用
    pkgs = {}
    for pid, ver in re.findall(r"<PackageReference\s+Include=\"([^\"]+)\"\s+Version=\"([^\"]+)\"", raw):
        # 包名本身也可能是变量，例如 $(SystemIOPackagingPackage)
        if pid.startswith("$("):
            pid = PKG_NAMES.get(pid.strip("$()"), pid.strip("$()"))
        # 版本变量 -> 已知稳定版，未知则回退 9.0.0
        if ver.startswith("$("):
            ver = PKG_VERSIONS.get(pid) or PKG_VERSIONS.get(ver.strip("$()")) or "9.0.0"
        pkgs[pid] = ver
    if pkgs:
        out.append("  <ItemGroup>")
        for pid, ver in sorted(pkgs.items()):
            if ver:
                out.append("    <PackageReference Include=\"%s\" Version=\"%s\" />" % (pid, ver))
        out.append("  </ItemGroup>")

    # 上游 ProjectReference -> 本工程内已编译通过的本地 DLL
    # （上游依赖链由 Arcade 串起，这里改为按名字在本工程 build/ 下查找产物）
    local_refs, unresolved_refs = [], []
    for pr in re.findall(r"<ProjectReference\s+Include=\"([^\"]+)\"", raw):
        # 必须先统一分隔符再取 basename：Linux 下 os.path.basename 不认反斜杠
        base = os.path.basename(pr.replace("\\", "/"))
        if not base.endswith(".csproj"):
            continue
        proj_name = base[:-len(".csproj")]
        if proj_name.endswith("-ref"):
            # `-ref` 项目通常是「引用程序集」项目（ReferenceOutputAssembly=false），跳过是对的。
            # ⚠ 但有个反例：`System.Printing-ref.csproj` 是 System.Printing 的**唯一托管面**
            # （实现是 C++），跳过后就再也接不上——那种情况需要手工建工程（M5 期实测遇到过）。
            print(f"[{name}] 提示：跳过 -ref 引用 {proj_name}（若是某某组件的唯一托管面，需手工建工程）")
            continue
        dll = find_built_dll(proj_name)
        if dll:
            local_refs.append(dll)
        else:
            unresolved_refs.append(proj_name)
    if local_refs:
        out.append("  <ItemGroup>")
        for d in local_refs:
            out.append("    <Reference Include=\"%s\"><HintPath>%s</HintPath>"
                       "<Private>true</Private></Reference>"
                       % (os.path.splitext(os.path.basename(d))[0], relocatable(d)))
        out.append("  </ItemGroup>")

    # ---------- 4b. SR.g.cs：替代 Arcade 的 GenerateCommonSRSource ----------
    # 命名空间必须与 Common/src/System/SR.cs 中本项目 DefineConstants 命中的分支一致
    SR_NS = [
        ("WINDOWS_BASE", "MS.Internal.WindowsBase"),
        ("PRESENTATION_CORE", "MS.Internal.PresentationCore"),
        ("PBTCOMPILER", "MS.Utility"),
        ("AUTOMATION", "MS.Internal.Automation"),
        ("REACHFRAMEWORK", "System.Windows.Xps"),
        ("PRESENTATIONFRAMEWORK", "System.Windows"),
        ("PRESENTATIONUI", "System.Windows.TrustUI"),
    ]
    ns = "System"
    for sym, n in SR_NS:
        if sym in defines.split(";"):
            ns = n
            break

    sr_files = []
    resx_paths = []
    for cand in (os.path.join(proj_dir, "Resources", "Strings.resx"),
                 os.path.join(UPSTREAM, "Common", "src", "Resources", "Strings.resx"),
                 os.path.join(proj_dir, "Resources", "SR.resx")):
        if os.path.exists(cand):
            resx_paths.append(cand)
    for idx, resx in enumerate(resx_paths):
        dst_sr = os.path.join(outdir, "SR.g.cs" if idx == 0 else "SR%d.g.cs" % idx)
        r = subprocess.run([sys.executable, os.path.join(HERE, "gen-sr.py"),
                            "--resx", resx, "--out", dst_sr,
                            "--ns", ns,
                            "--basename", "%s.Resources.Strings" % name],
                           capture_output=True, text=True)
        if r.returncode == 0 and os.path.exists(dst_sr):
            sr_files.append(dst_sr)
    if sr_files:
        changes.append("SR.g.cs: 命名空间 `%s`，resx %d 个" % (ns, len(sr_files)))

    out.append("  <ItemGroup>")
    for c in compiles:
        out.append("    <Compile Include=\"%s\" />" % relocatable(c))
    for s in sr_files:
        out.append("    <Compile Include=\"%s\" />" % relocatable(s))
    out.append("  </ItemGroup>")

    # ---------- 4c. shim：build/shims 下的兼容层源文件 ----------
    # 逐项目清单：build/shims/<Name>.shims.txt 每行一个相对仓库根的路径
    # （如 WindowsBase 的 WindowsWin32.Shim.cs + Accessibility.Shim.cs）。
    # 全仓共享的 WindowsWin32.Shim.cs 不自动注入——各项目在清单里显式列出，
    # 避免给不需要的项目（如 System.Xaml）平添编译面。
    shims = []
    shim_list = os.path.join(HERE, "shims", name + ".shims.txt")
    if os.path.exists(shim_list):
        for line in open(shim_list, encoding="utf-8"):
            line = line.strip()
            if line and not line.startswith("#"):
                shims.append(os.path.normpath(os.path.join(OUTROOT, line)))
    if shims:
        out.append("  <!-- WPF-on-Linux 兼容层：build/shims 下手写的等价类型（上游零改动） -->")
        out.append("  <ItemGroup>")
        for s in shims:
            out.append("    <Compile Include=\"%s\" />" % relocatable(s))
        out.append("  </ItemGroup>")
        changes.append("shim: %d 个文件" % len(shims))

    # ---------- 4d. 自产程序集身份版本（每个移植工程必带） ----------
    # 不注入它，自产程序集 AssemblyVersion 会是 0.0.0.0，被 net10.0 框架里同名门面
    # （Microsoft.NETCore.App/.../WindowsBase.dll，4.0.0.0）在编译期与运行期双重遮蔽。
    # 详见 build/shims/LinuxAssemblyIdentity.cs 的文件头注释。
    identity = os.path.join(HERE, "shims", "LinuxAssemblyIdentity.cs")
    if os.path.exists(identity):
        out.append("  <!-- 自产程序集身份：AssemblyVersion 4.0.0.1，必须 > 框架门面的 4.0.0.0 -->")
        out.append("  <ItemGroup>")
        out.append("    <Compile Include=\"%s\" />" % relocatable(identity))
        out.append("  </ItemGroup>")
    else:
        print(f"[{name}] ⚠ 缺少 {identity}：自产程序集将退回 0.0.0.0，"
              f"会被框架同名门面遮蔽（编译期 CS0234 / 运行期 TypeLoadException）")

    if embedded:
        out.append("  <!-- 程序集清单资源：ManifestResourceName 必须显式（RootNamespace 被本脚本统一为")
        out.append("       MS.Internal，靠 SDK 推导会与 gen-sr.py 的 SR 基名不一致 → 资源表静默失效） -->")
        out.append("  <ItemGroup>")
        for r, meta, inc in embedded:
            mname, _explicit = manifest_name(r, meta, inc)
            others = [(k, v) for k, v in meta if k != "ManifestResourceName"]
            out.append("    <EmbeddedResource Include=\"%s\">" % relocatable(r))
            out.append("      <ManifestResourceName>%s</ManifestResourceName>" % mname)
            for tag, val in others:
                out.append("      <%s>%s</%s>" % (tag, val, tag))
            out.append("    </EmbeddedResource>")
        out.append("  </ItemGroup>")
        changes.append("清单资源 %d 个（显式 ManifestResourceName）" % len(embedded))

    if wpf_resources:
        # WPF <Resource>：必须打包成 $(AssemblyName).g.resources 流，运行期走
        # `new ResourceManager("<asm>.g", asm).GetStream("<相对路径小写>")`。
        # 值必须是 **Stream**（byte[] 会抛 InvalidOperationException）。
        out.append("  <!-- WPF <Resource> 项（非 EmbeddedResource！降级会导致双重失效：既不进 .g.resources，")
        out.append("       又因缺 Type=Non-Resx+WithCulture=false 被 SDK 静默丢弃） -->")
        out.append("  <ItemGroup>")
        for r, meta, inc in wpf_resources:
            rel = os.path.relpath(r, proj_dir).replace(os.sep, "/")
            if rel.startswith("../"):
                rel = os.path.basename(r)
            out.append("    <WpfLinuxResourceSource Include=\"%s\">" % relocatable(r))
            out.append("      <WpfLinuxKey>%s</WpfLinuxKey>" % rel.lower())
            out.append("    </WpfLinuxResourceSource>")
        out.append("  </ItemGroup>")
        out.append("""
  <UsingTask TaskName="WpfLinuxGenerateGResources" TaskFactory="RoslynCodeTaskFactory"
             AssemblyFile="$(MSBuildToolsPath)/Microsoft.Build.Tasks.Core.dll">
    <ParameterGroup>
      <Sources ParameterType="Microsoft.Build.Framework.ITaskItem[]" Required="true" />
      <OutputFile ParameterType="System.String" Required="true" />
    </ParameterGroup>
    <Task>
      <Using Namespace="System" />
      <Using Namespace="System.IO" />
      <Using Namespace="System.Resources" />
      <Code Type="Fragment" Language="cs"><![CDATA[
        Directory.CreateDirectory(Path.GetDirectoryName(OutputFile));
        using (var fs = File.Create(OutputFile))
        using (var writer = new ResourceWriter(fs))
        {
            foreach (var item in Sources)
            {
                // 必须以 Stream 形式写入：运行期走 ResourceManager.GetStream(...)，
                // 条目若是 byte[] 会抛 InvalidOperationException。
                writer.AddResource(item.GetMetadata("WpfLinuxKey"),
                    new MemoryStream(File.ReadAllBytes(item.ItemSpec), writable: false));
            }
        }
      ]]></Code>
    </Task>
  </UsingTask>

  <Target Name="WpfLinux_GenerateGResources" BeforeTargets="CreateManifestResourceNames;PrepareResources">
    <!-- IntermediateOutputPath 由 Sdk.targets 定义，只能在 Target 内取 -->
    <PropertyGroup>
      <WpfGResourcesFile>$(IntermediateOutputPath)$(AssemblyName).g.resources</WpfGResourcesFile>
    </PropertyGroup>
    <WpfLinuxGenerateGResources Sources="@(WpfLinuxResourceSource)" OutputFile="$(WpfGResourcesFile)" />
    <ItemGroup>
      <EmbeddedResource Remove="@(WpfLinuxResourceSource)" />
      <EmbeddedResource Include="$(WpfGResourcesFile)" LogicalName="$(AssemblyName).g.resources"
                        Type="Non-Resx" WithCulture="false" />
    </ItemGroup>
    <Message Importance="high"
             Text="WPF-on-Linux: 生成 $(WpfGResourcesFile)（@(WpfLinuxResourceSource->Count()) 个 WPF Resource → .g.resources）" />
  </Target>""")
        changes.append("WPF Resource %d 个（.g.resources 流）" % len(wpf_resources))

    out.append("  <Import Project=\"Sdk.targets\" Sdk=\"Microsoft.NET.Sdk\" />")
    out.append("</Project>")

    dst = os.path.join(outdir, name + ".Linux.csproj")
    open(dst, "w", encoding="utf-8").write("\n".join(out) + "\n")

    # ---------- 5. 改动清单 ----------
    ch = []
    ch.append("# %s → Linux 移植改动清单" % name)
    ch.append("")
    ch.append("> 由 `build/port-lib.py` 从上游自动生成，上游仓库零改动。")
    ch.append("")
    ch.append("| 项 | 数值 |")
    ch.append("|---|---|")
    ch.append("| 上游源文件 | %d |" % len(items))
    ch.append("| 解析成功 | %d |" % len(compiles))
    ch.append("| 按 basename/大小写找回 | %d |" % recovered)
    ch.append("| 仍缺失 | %d |" % len(still_missing))
    ch.append("| 剔除（build/excludes/%s.txt） | %d |" % (name, len(excluded)))
    ch.append("| shim（build/shims/%s.shims.txt + 身份文件） | %d |" % (name, len(shims) + 1))
    ch.append("| 丢弃 ProjectReference | %d（含 vcxproj %d） |" % (pr_count, vc_count))
    ch.append("| 未解析的本地引用（需先构建对应工程） | %d %s |" % (len(unresolved_refs), unresolved_refs))
    ch.append("| 丢弃私有 WinForms 引用 | %d |" % priv_count)
    ch.append("| 丢弃代码生成 Target | %d %s |" % (len(tgt_dropped), tgt_dropped))
    ch.append("| 丢弃 Arcade/CodeGen Import | %d |" % imp_dropped)
    ch.append("| DefineConstants | `%s` |" % defines)
    ch.append("")
    if excluded:
        ch.append("## 剔除的源文件（build/excludes/%s.txt）" % name)
        ch.append("")
        ch.append("```")
        ch.append("\n".join("  " + e for e in sorted(set(excluded))))
        ch.append("```")
        ch.append("")
    if still_missing:
        ch.append("## 仍缺失的源文件（前 30）")
        ch.append("")
        ch.append("| 原始 Include | 解析路径 |")
        ch.append("|---|---|")
        for inc, ap in still_missing[:30]:
            ch.append("| `%s` | `%s` |" % (inc, ap))
        ch.append("")
    open(os.path.join(outdir, "PORT-CHANGES.md"), "w", encoding="utf-8").write("\n".join(ch) + "\n")

    print(f"[{name}] 源文件 {len(compiles)}（找回 {recovered}）/ 缺失 {len(still_missing)}"
          f" | 丢弃 PR {pr_count}(vcx {vc_count}) 私有 {priv_count} Target {len(tgt_dropped)} Import {imp_dropped}")
    print(f"          → {dst}")
    if unresolved_refs:
        print(f"          ⚠ 未解析的本地引用：{unresolved_refs}"
              f" —— 请先构建 build/<Name>.Linux 产出 DLL 后重跑本脚本")
    if still_missing:
        for inc, ap in still_missing[:8]:
            print(f"          缺失: {inc}  ->  {ap}")
    return dst


if __name__ == "__main__":
    names = sys.argv[1:] or ["WindowsBase"]
    for n in names:
        port(n)

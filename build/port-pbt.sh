#!/usr/bin/env bash
#
# T1 · 把上游 PresentationBuildTasks.csproj 移植成 Linux 可编译工程。
#
# 原则：**绝不修改上游源码**。上游仓库只读，本脚本读取上游 csproj，
# 做文本变换后输出到 build/PresentationBuildTasks.Linux/。
# 这样上游一升级，重跑本脚本即可重新生成，改动全部可审计。
#
# 用法：bash build/port-pbt.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly UPSTREAM_ROOT="${UPSTREAM_WPF_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)/upstream/wpf}"
readonly UPSTREAM_CSPROJ="${UPSTREAM_ROOT}/src/Microsoft.DotNet.Wpf/src/PresentationBuildTasks/PresentationBuildTasks.csproj"
readonly OUT_DIR="${SCRIPT_DIR}/PresentationBuildTasks.Linux"
readonly OUT_CSPROJ="${OUT_DIR}/PresentationBuildTasks.Linux.csproj"

# 目标框架：锁 net10.0，与 T0 锁定的 SDK 10.0.111 对齐
readonly TARGET_TFM="${TARGET_TFM:-net10.0}"

[[ -f "${UPSTREAM_CSPROJ}" ]] || { echo "找不到上游 csproj: ${UPSTREAM_CSPROJ}" >&2; exit 1; }

mkdir -p "${OUT_DIR}"

# 建立一个「改动日志」，逐条记录对上游 csproj 做的每一处修改
readonly CHANGES="${OUT_DIR}/PORT-CHANGES.md"
: > "${CHANGES}"

{
  echo "# 相对上游 PresentationBuildTasks.csproj 的改动清单"
  echo
  echo "> 由 \`build/port-pbt.sh\` 自动生成，请勿手改。上游仓库保持只读。"
  echo "> 上游文件：\`${UPSTREAM_CSPROJ}\`"
  echo "> 生成时间：$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "> 上游文件 SHA256：\`$(sha256sum "${UPSTREAM_CSPROJ}" | cut -d' ' -f1)\`"
  echo
  echo "## 改动项"
  echo
} >> "${CHANGES}"

note() { printf '%s\n\n' "$1" >> "${CHANGES}"; }

note "**1. TargetFramework**：\`\$(BundledNETCoreAppTargetFramework);\$(NetFrameworkToolCurrent)\`（含 .NETFramework 双目标）→ 单目标 \`${TARGET_TFM}\`。
原因：Linux 无 .NETFramework 参考程序集，且 \`NetFrameworkToolCurrent\` 等变量由上游 Arcade SDK 提供，此处拿不到。"

note "**2. 路径分隔符**：上游全部 Compile Include 用 Windows 反斜杠（如 \`\$(WpfSourceDir)PresentationFramework\\System\\...\`）。
Linux 的 MSBuild **不会**把反斜杠当分隔符，会当成文件名的一部分导致文件找不到。已全部转为正斜杠。"

note "**3. 路径变量**：\`WpfSourceDir\` / \`WpfSharedDir\` / \`WpfCommonDir\` 在上游由 Arcade 的 \`eng/WpfArcadeSdk/tools/FolderPaths.props\` 注入。
此处改为在本 csproj 内显式定义，指向上游只读目录 \`${UPSTREAM_ROOT}\` 并用正斜杠结尾。"

note "**6. 资源文件路径**：\`&lt;EmbeddedResource Include=\"Resources/Strings.resx\" /&gt;\` 是相对「上游项目目录」的路径。
本工程换了目录后该相对路径失效，报 \`error MSB3552: Resource file \"Resources/Strings.resx\" cannot be found.\`
已改为用 \`\$(UpstreamWpfRoot)\` 绝对定位，并保留 \`Link\` 与 \`LogicalName\`（SR.cs 依赖资源名的完整命名空间）。"

note "**8. 生成 SR 资源类**：上游 WPF 用 Arcade 的 \`GenerateCommonSRSource\` 目标，在编译期把
\`Resources/Strings.resx\` 翻译成 \`SR.common.cs\`（含 \`ResourceManager\` 属性 + 每条字符串一个
\`internal static string Foo => GetResourceString(\"Foo\")\`）。手工写的 \`SR.cs\` 与
\`Common/src/System/SR.cs\` 只是另一半 partial class，缺了它就会刷 688 个
\`error CS0117: 'SR' does not contain a definition for 'Xxx'\`。
本工程不引入 Arcade，改用 \`build/gen-sr.py\` 从**同一个 resx**生成等价的 \`SR.g.cs\`（239 条），
并显式加入编译（因 \`EnableDefaultItems=false\`）。"

note "**9. ReflectionHelper.cs 换本地副本 ＋ 新增 NameFallbackResolver.cs**：上游 \`Shared/System/Windows/Markup/ReflectionHelper.cs\` 的
\`Initialize()\` 用 \`new MetadataLoadContext(new PathAssemblyResolver(assemblyPaths), …)\` 解析程序集；\`PathAssemblyResolver\` 的规矩是
**名字同 且 公钥 token 完全一致**（版本允许 找到的 ≥ 请求的）。
第三方 WPF NuGet 包的 windows 资产按官方 WindowsDesktop 身份请求（\`System.Xaml 5.0.0.0/b77a…\`、\`PresentationFramework 5.0.0.0/31bf…\`），
与自产件（\`4.0.0.1/31bf…\`；System.Xaml 的 token 本身不同）对不上 ⇒ MarkupCompilePass1 抛
\`MC1000: Could not find assembly 'System.Xaml, Version=5.0.0.0, …'\`，逼着调用方去造"身份改版件"骗编译器 ——
而改版件在运行期与自产件内部写死的身份对不上 ⇒ 应用全黑。
本工程把该文件复制一份到 \`build/PresentationBuildTasks.Linux/ReflectionHelper.cs\`（只改那一行：换成 \`NameFallbackResolver\`），
并新增 \`NameFallbackResolver.cs\`（先按官方规矩解析，解析不到再退回"只按简单名找"，见该文件头注释）。
csproj 的 \`Compile\` 项由 \`\$(WpfSharedDir)/…/ReflectionHelper.cs\` 改为本工程的 \`ReflectionHelper.cs\`，并追加 \`NameFallbackResolver.cs\`。
上游 snapshot 一个字节不改。详见 \`RT/Links-License-Mgr/PortWpfLinux/TASK-治全黑.md\`。"

note "**7. 自身源文件路径**：\`MS/Internal/**\`、\`Microsoft/Build/Tasks/Windows/**\`、\`SR.cs\`、\`System/AppContextDefaultValues.cs\` 等 29 条
是相对「上游项目目录」的路径（改动 2 只修了分隔符、没修根目录）。本工程换了目录后全部报
\`error CS2001: Source file '...' could not be found.\`
已统一加 \`\$(UpstreamPbtDir)\` 前缀。注意本工程**不复制任何源码**，直接编译上游只读文件。"

note "**5. 包版本号**：\`\$(MicrosoftBuildFrameworkPackageVersion)\` 等由 Arcade 注入，此处写死。
\`Microsoft.Build.Framework\` / \`Microsoft.Build.Utilities.Core\` 沿用上游的 \`15.9.20\`（IncludeAssets=compile，运行时由 MSBuild 宿主提供，故低于宿主版本是安全的）。
\`System.Reflection.MetadataLoadContext\` 与 \`System.CodeDom\` 上游用的是 \`11.0.0-rc.1.26411.119\`（预览版，镜像源上不一定有），改用稳定版 \`9.0.0\`。"

note "**4. 移除 Arcade 依赖**：上游 csproj 继承仓库根 \`Directory.Build.props\`（引入 Microsoft.DotNet.Arcade.Sdk）与 WpfArcadeSdk。
本工程位于 \`${SCRIPT_DIR}/..\` 下，通过自带 \`Directory.Build.props\` / \`.targets\` 切断继承，改为自包含。"
note "  受影响的 Arcade 专属性质（\`BinPlaceRuntime\`、\`PackagingContent\`、\`PackagingAssemblyContent\`、\`EnablePInvokeAnalyzer\`）在无 Arcade 时为空操作，保留不删以便与上游 diff。"

# ---------------------------------------------------------------------------
# 生成目标 csproj：逐行变换上游内容
# ---------------------------------------------------------------------------
python3 - "${UPSTREAM_CSPROJ}" "${OUT_CSPROJ}" "${TARGET_TFM}" <<'PY'
import re, sys

src_path, dst_path, tfm = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(src_path, encoding='utf-8-sig').read()

# --- 改动 1：TargetFrameworks 行 → 单目标 ---
text = re.sub(
    r'<TargetFrameworks>\$\(BundledNETCoreAppTargetFramework\);\$\(NetFrameworkToolCurrent\)</TargetFrameworks>\s*<TargetFramework />',
    '<TargetFramework>%s</TargetFramework>' % tfm,
    text)
if '<TargetFramework>%s</TargetFramework>' % tfm not in text:
    sys.exit("改动1失败：未匹配到 TargetFrameworks 行，上游 csproj 结构可能已变化")

# --- 改动 2：路径反斜杠 → 正斜杠（只处理 Compile/EmbeddedResource 的 Include） ---
# 注意：正则里 r'\\\\' 匹配「两个」字面反斜杠，而上游路径只有「一个」，
# 所以必须写成 r'\\'（正则语义 = 一个字面反斜杠）。
def fix_include(m):
    return '%s Include="%s"' % (m.group(1), m.group(2).replace('\\', '/'))
before = text
text = re.sub(r'(Compile|EmbeddedResource|None|Content) Include="([^"]*\\[^"]*)"', fix_include, text)
n_fixed = len(re.findall(r'Include="[^"]*\\[^"]*"', before)) - len(re.findall(r'Include="[^"]*\\[^"]*"', text))
if n_fixed <= 0:
    sys.exit("改动2失败：未转换任何反斜杠路径，上游 csproj 结构可能已变化")
print("改动2：转换 %d 条含反斜杠的 Include 路径" % n_fixed)

# --- 改动 7：PBT 自身的相对源文件路径 → 上游绝对路径 ---
# 形如 <Compile Include="MS/Internal/Tasks/Shared.cs" />、SR.cs、System/... 等
# 都是相对「上游 PresentationBuildTasks 目录」的，本工程换了目录后全部报
# error CS2001: Source file ... could not be found.
# 统一加 $(UpstreamPbtDir) 前缀；已含 $ 的（走 WpfSourceDir/WpfSharedDir 等）不动。
def prefix_pbt(m):
    path, closing = m.group(1), m.group(2)   # 只有 2 个捕获组：路径 + 结尾( /> 或 > )
    if path.startswith('$'):
        return m.group(0)
    return '<Compile Include="$(UpstreamPbtDir)%s"%s' % (path, closing)
n_rel = len(re.findall(r'<Compile Include="(?!\$)([^"]+)"', text))
text = re.sub(r'<Compile Include="([^"]+)"( */>|>)', prefix_pbt, text)
print("改动7：%d 条相对路径源文件已改指向上游目录" % n_rel)

# --- 改动 6：资源文件相对路径 → 上游绝对路径 ---
# 上游 <EmbeddedResource Include="Resources/Strings.resx" /> 是相对 *上游* 项目目录的，
# 本工程换了目录后该相对路径失效，报 MSB3552。改为用 $(UpstreamWpfRoot) 绝对定位。
text = text.replace(
    '<EmbeddedResource Include="Resources/Strings.resx" />',
    '<EmbeddedResource Include="$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/PresentationBuildTasks/Resources/Strings.resx">'
    '<Link>Resources/Strings.resx</Link>'
    '<LogicalName>PresentationBuildTasks.Resources.Strings.resources</LogicalName>'
    '</EmbeddedResource>')
if 'PresentationBuildTasks/Resources/Strings.resx' not in text:
    sys.exit("改动6失败：未匹配到 Resources/Strings.resx，上游 csproj 结构可能已变化")
print("改动6：EmbeddedResource 已改为上游绝对路径")

# --- 改动 9：ReflectionHelper.cs 改用本工程内的副本；并追加 NameFallbackResolver.cs ---
# 上游那份 ReflectionHelper.Initialize() 用 PathAssemblyResolver（名字 + 公钥 token 必须一致）
# ⇒ 第三方 WPF 包请求的官方身份（System.Xaml 5.0.0.0/b77a…）与自产件（4.0.0.1/31bf…）对不上 ⇒ MC1000。
# 本工程编译"上游文件的本地副本"（只换那一行解析器）+ NameFallbackResolver.cs（按名回退）。
rh_include = r'<Compile Include="\$\(WpfSharedDir\)/System/Windows/Markup/ReflectionHelper\.cs">'
if not re.search(rh_include, text):
    sys.exit("改动9失败：未匹配到 $(WpfSharedDir)/System/Windows/Markup/ReflectionHelper.cs 的 Compile 项")
text = re.sub(
    rh_include,
    '<!-- 改动9：ReflectionHelper.cs 改编译本工程内的副本（只把 Initialize 里的 PathAssemblyResolver\n'
    '         换成 NameFallbackResolver），上游 snapshot 保持一个字节不改。 -->\n'
    '    <Compile Include="ReflectionHelper.cs">',
    text, count=1)
rh_marker = '<Compile Include="ReflectionHelper.cs">'
rh_end = text.index('</Compile>', text.index(rh_marker)) + len('</Compile>')
text = text[:rh_end] + '\n    <Compile Include="NameFallbackResolver.cs" />' + text[rh_end:]
print("改动9：ReflectionHelper.cs 改指本地副本，并加入 NameFallbackResolver.cs")

# --- 改动 3：注入路径变量（放在第一个 PropertyGroup 之后） ---
props = """
  <!-- 改动3：Arcade 注入的路径变量，此处显式定义（正斜杠，指向上游只读源码） -->
  <PropertyGroup>
    <WpfSourceDir>$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/</WpfSourceDir>
    <WpfSharedDir>$(WpfSourceDir)Shared/</WpfSharedDir>
    <WpfCommonDir>$(WpfSourceDir)Common/</WpfCommonDir>
    <UpstreamWpfRoot Condition="'$(UpstreamWpfRoot)'==''">$(MSBuildThisFileDirectory)../../upstream/wpf/</UpstreamWpfRoot>
    <!-- 改动7：上游 PresentationBuildTasks 源文件目录（本工程不含源码副本，全部从上游编译） -->
    <UpstreamPbtDir>$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/PresentationBuildTasks/</UpstreamPbtDir>
    <!-- 改动5：Arcade 注入的包版本号，此处写死，避免版本漂移 -->
    <MicrosoftBuildFrameworkPackageVersion>15.9.20</MicrosoftBuildFrameworkPackageVersion>
    <MicrosoftBuildUtilitiesCorePackageVersion>15.9.20</MicrosoftBuildUtilitiesCorePackageVersion>
    <SystemReflectionMetadataLoadContextVersion>9.0.0</SystemReflectionMetadataLoadContextVersion>
    <SystemCodeDomPackageVersion>9.0.0</SystemCodeDomPackageVersion>
  </PropertyGroup>
"""
text = text.replace('</Project>', props + '\n</Project>', 1)

open(dst_path, 'w', encoding='utf-8').write(text)
print("已生成 %s" % dst_path)
PY

# ---------------------------------------------------------------------------
# 改动 4：切断上游 Arcade 继承
# ---------------------------------------------------------------------------
cat > "${OUT_DIR}/Directory.Build.props" <<'EOF'
<Project>
  <!-- 改动4：切断对上游 Arcade SDK 的继承，使本工程自包含 -->
  <PropertyGroup>
    <UpstreamWpfRoot Condition="'$(UpstreamWpfRoot)' == '' and '$(UPSTREAM_WPF_ROOT)' != ''">$(UPSTREAM_WPF_ROOT)</UpstreamWpfRoot>
    <UpstreamWpfRoot Condition="'$(UpstreamWpfRoot)' == ''">$([System.IO.Path]::GetFullPath('$(MSBuildThisFileDirectory)../../upstream/wpf'))/</UpstreamWpfRoot>
    <!-- 关掉会干扰的 SDK 默认行为 -->
    <Nullable>disable</Nullable>
    <ImplicitUsings>disable</ImplicitUsings>
    <LangVersion>latest</LangVersion>
    <NoWarn>$(NoWarn);CS0618;CS0067;CS0169;CS0414;CS1591;CS8632;NU1701;MSB3277</NoWarn>
    <!-- 上游代码大量使用未标注可为 null 的 API，不做 nullable 检查 -->
    <TreatWarningsAsErrors>false</TreatWarningsAsErrors>
    <GenerateDocumentationFile>false</GenerateDocumentationFile>
    <Deterministic>true</Deterministic>
  </PropertyGroup>
</Project>
EOF

cat > "${OUT_DIR}/Directory.Build.targets" <<'EOF'
<Project>
  <!-- 改动4（续）：不再向上查找 Directory.Build.props/targets -->
</Project>
EOF

echo "已生成 ${OUT_DIR}/Directory.Build.props / .targets"

# ---------------------------------------------------------------------------
# 改动 8：生成 SR.g.cs，替代 Arcade 的 GenerateCommonSRSource
# ---------------------------------------------------------------------------
UPSTREAM_RESX="${UPSTREAM_ROOT}/src/Microsoft.DotNet.Wpf/src/PresentationBuildTasks/Resources/Strings.resx"
[[ -f "${UPSTREAM_RESX}" ]] || { echo "找不到上游 resx: ${UPSTREAM_RESX}" >&2; exit 1; }
python3 "${SCRIPT_DIR}/gen-sr.py" \
    --resx "${UPSTREAM_RESX}" \
    --out "${OUT_DIR}/SR.g.cs" \
    --basename "PresentationBuildTasks.Resources.Strings" \
    || { echo "SR.g.cs 生成失败" >&2; exit 1; }

# EnableDefaultItems=false，生成文件必须显式加入编译
python3 - "${OUT_CSPROJ}" <<'PY'
import sys
p = sys.argv[1]
t = open(p, encoding='utf-8').read()
if 'SR.g.cs' not in t:
    t = t.replace('</Project>',
        '\n  <!-- 改动8：Arcade 生成的 SR 资源类，本工程由 build/gen-sr.py 生成 -->\n'
        '  <ItemGroup>\n    <Compile Include="SR.g.cs" />\n  </ItemGroup>\n\n</Project>', 1)
    open(p, 'w', encoding='utf-8').write(t)
    print("改动8：SR.g.cs 已加入编译")
PY

# ---------------------------------------------------------------------------
# 改动 9：生成 ReflectionHelper.cs 的本地副本（只换那一行解析器）＋ NameFallbackResolver.cs
# ---------------------------------------------------------------------------
readonly UPSTREAM_REFHELPER="${UPSTREAM_ROOT}/src/Microsoft.DotNet.Wpf/src/Shared/System/Windows/Markup/ReflectionHelper.cs"
[[ -f "${UPSTREAM_REFHELPER}" ]] || { echo "找不到上游 ReflectionHelper.cs: ${UPSTREAM_REFHELPER}" >&2; exit 1; }

python3 - "${UPSTREAM_REFHELPER}" "${OUT_DIR}/ReflectionHelper.cs" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, encoding='utf-8').read()
old = 'new MetadataLoadContext(new PathAssemblyResolver(assemblyPaths), MscorlibReflectionAssemblyName)'
new = 'new MetadataLoadContext(new NameFallbackResolver(assemblyPaths), MscorlibReflectionAssemblyName)'
if old not in text:
    sys.exit("改动9失败：上游 ReflectionHelper.cs 里未找到 new PathAssemblyResolver(assemblyPaths) 那一行")
open(dst, 'w', encoding='utf-8').write(text.replace(old, new, 1))
print("改动9：已生成 %s（复制上游 + 换解析器 1 行）" % dst)
PY

cat > "${OUT_DIR}/NameFallbackResolver.cs" <<'EOF'
// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

#nullable disable

// 改动9：PBT 的程序集解析器。
//
// 官方 PathAssemblyResolver 的规矩是"名字同 且 公钥 token 完全同"（版本允许 找到的 >= 请求的）。
// 第三方 WPF NuGet 包的 windows 资产按官方 WindowsDesktop 身份请求:
//     System.Xaml            5.0.0.0 / b77a5c561934e089
//     PresentationFramework  5.0.0.0 / 31bf3856ad364e35
// 而本仓自产件是 4.0.0.1 / 31bf3856ad364e35（System.Xaml 的 token 都不同）
// ⇒ PathAssemblyResolver 一律拒绝 ⇒ MarkupCompilePass1 抛
//    MC1000: Could not find assembly 'System.Xaml, Version=5.0.0.0, ...'
//
// 本类先按官方规矩解析；解析不到时退回"只按简单名找"（同名多份时优先公钥 token 相符、
// 其次版本最近的候选）。这样 XAML 编译器可以**直接认自产真件**，
// 不需要"身份改版件"（那会把编译期与运行期的身份劈成两套，运行期全黑）。

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;

namespace MS.Internal.Markup
{
    internal sealed class NameFallbackResolver : MetadataAssemblyResolver
    {
        private sealed class Candidate
        {
            internal string Path;
            internal Version Version;
            internal string PublicKeyToken;   // 小写十六进制；无签名件为 null
        }

        private readonly PathAssemblyResolver _strict;
        private readonly Dictionary<string, List<Candidate>> _bySimpleName =
            new Dictionary<string, List<Candidate>>(StringComparer.OrdinalIgnoreCase);

        internal NameFallbackResolver(IEnumerable<string> assemblyPaths)
        {
            if (assemblyPaths == null)
            {
                throw new ArgumentNullException(nameof(assemblyPaths));
            }

            List<string> paths = new List<string>();
            foreach (string p in assemblyPaths)
            {
                if (string.IsNullOrEmpty(p))
                {
                    continue;
                }

                paths.Add(p);

                string simpleName = System.IO.Path.GetFileNameWithoutExtension(p);
                if (string.IsNullOrEmpty(simpleName))
                {
                    continue;
                }

                Candidate candidate = new Candidate { Path = p };
                try
                {
                    AssemblyName an = AssemblyName.GetAssemblyName(p);
                    candidate.Version = an.Version;
                    byte[] token = an.GetPublicKeyToken();
                    if (token != null && token.Length > 0)
                    {
                        candidate.PublicKeyToken = ToHex(token);
                    }
                }
                catch (Exception)
                {
                    // 读不出身份的文件（不是托管程序集等）仍按简单名登记，但不参与 token 优先选择
                }

                List<Candidate> list;
                if (!_bySimpleName.TryGetValue(simpleName, out list))
                {
                    list = new List<Candidate>();
                    _bySimpleName[simpleName] = list;
                }

                list.Add(candidate);
            }

            _strict = new PathAssemblyResolver(paths);
        }

        public override Assembly Resolve(MetadataLoadContext context, AssemblyName assemblyName)
        {
            if (assemblyName == null)
            {
                throw new ArgumentNullException(nameof(assemblyName));
            }

            Assembly resolved = null;
            try
            {
                resolved = _strict.Resolve(context, assemblyName);
            }
            catch (FileNotFoundException)
            {
                resolved = null;
            }

            if (resolved != null || assemblyName.Name == null)
            {
                return resolved;
            }

            List<Candidate> candidates;
            if (!_bySimpleName.TryGetValue(assemblyName.Name, out candidates) || candidates.Count == 0)
            {
                return null;
            }

            Candidate pick = null;
            byte[] wantToken = assemblyName.GetPublicKeyToken();
            if (wantToken != null && wantToken.Length > 0)
            {
                string want = ToHex(wantToken);
                foreach (Candidate c in candidates)
                {
                    if (string.Equals(c.PublicKeyToken, want, StringComparison.OrdinalIgnoreCase))
                    {
                        pick = c;
                        break;
                    }
                }
            }

            if (pick == null && assemblyName.Version != null)
            {
                foreach (Candidate c in candidates)
                {
                    if (c.Version != null && c.Version >= assemblyName.Version &&
                        (pick == null || c.Version < pick.Version))
                    {
                        pick = c;
                    }
                }
            }

            if (pick == null)
            {
                pick = candidates[0];
            }

            return context.LoadFromAssemblyPath(pick.Path);
        }

        private static string ToHex(byte[] bytes)
        {
            StringBuilder sb = new StringBuilder(bytes.Length * 2);
            foreach (byte b in bytes)
            {
                sb.Append(b.ToString("x2", System.Globalization.CultureInfo.InvariantCulture));
            }

            return sb.ToString();
        }
    }
}
EOF

echo "改动9：已生成 ${OUT_DIR}/NameFallbackResolver.cs"

echo
echo "改动清单已写入 ${CHANGES}"

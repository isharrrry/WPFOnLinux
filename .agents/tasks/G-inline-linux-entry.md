# 任务 G：把 Linux 入口并入原 csproj（OS 条件），归档额外的 `.Linux.csproj`

## ① 任务目标

用户不要额外的 `<原工程>/<Name>.Linux.csproj`。改成：在**链上的 7 个 WPF 原 csproj** 里加 **OS 条件**，使
- **Linux**：`dotnet build ICDStudio.csproj`（不带任何 `-p:`）自动走自产栈（`net10.0-windows` + `UseWPF=false` + `WpfLinux.Sdk`）；
- **Windows**：**逐字回到原行为**（`net6.0-windows` + `UseWPF=true` + 微软 WPF）。

完成后，所有 `<Name>.Linux.csproj` **归档**（移动，不删除）。

### 已验证事实（主控实测，直接采信）

- **在原 csproj 中部**加条件覆盖**有效**：最小工程（`<Project Sdk="Microsoft.NET.Sdk">` + 原样 `net6.0-windows`/`UseWPF=true`，其后加 `<PropertyGroup Condition="'$(OS)' != 'Windows_NT'">` 覆盖 `TargetFramework`→`net10.0-windows`、`UseWPF`→`false`）：
  编译 **0 错误**；`dotnet msbuild -getProperty:TargetFramework,UseWPF` 求值 = `net10.0-windows` / `false`。
  ⚠️ 这是本任务的技术前提，**不要**改成"分离式 Sdk.props/targets 写法"（那是原 `.Linux.csproj` 的做法，用户不想要）。
- 现有的 `<Name>.Linux.csproj` 就是**参考清单**（各自的 `WpfLinuxSrcTree`、`WpfLinuxSrcTreeExclude`、`WpfLinuxOfficialBorrows`、资源/源码排除、`ProjectReference`、`NoWarn`、`ApplicationIcon` 等）——**照它的语义**搬进原 csproj 的条件段。
- 7 个原 csproj 及其目录（`readlink -f` 实测）：
  | 工程 | 原 csproj |
  |---|---|
  | ICDStudio | `RT/Links-ICD-Kit/ICDStudio/ICDStudio.csproj` |
  | ICDLite | `RT/Links-ICD-Kit/ICDLite/ICDLite.csproj` |
  | AgentRT | `RT/Links-ICD-Kit/AgentRT/AgentRT.csproj` |
  | APPGuarder | `RT/Links-Common-Library/Guarder/APPGuarder.csproj` |
  | Config | `RT/Links-Common-Library/Config/Config.csproj` |
  | Common.Resources | `RT/Links-Common-Library/Common.Resources/Common.Resources.csproj` |
  | LicenseManagerGUI | `RT/Links-License-Mgr/LicenseManager/LicenseManagerGUI.csproj` |
- `WpfLinuxRoot`：`/home/links-dev/netTest/GitProj/WPFOnLinux`；包在 `$WpfLinuxRoot/src/Linux/build/third-party/pkg/out`。
- **两个仓库都没有 git** ⇒ 改原 csproj 前**必须**先逐文件备份（`/tmp/taskG-backup/`），并在报告里给回退命令。

## ② 落地内容（每个链上原 csproj 追加，示意；具体照 `.Linux.csproj` 语义）

```xml
  <!-- WPF-on-Linux：仅非 Windows 生效；Windows 侧行为逐字不变 -->
  <PropertyGroup Condition="'$(OS)' != 'Windows_NT'">
    <TargetFramework>net10.0-windows</TargetFramework>
    <UseWPF>false</UseWPF>
    <WpfLinuxSrcTree>$(MSBuildProjectDirectory)</WpfLinuxSrcTree>
    <!-- 该工程特有的排除/开关照 .Linux.csproj 搬 -->
    <BaseIntermediateOutputPath>obj/Linux/</BaseIntermediateOutputPath>
    <BaseOutputPath>bin/Linux/</BaseOutputPath>
    <RestoreAdditionalProjectSources>$(WpfLinuxRoot)/src/Linux/build/third-party/pkg/out</RestoreAdditionalProjectSources>
  </PropertyGroup>
  <ItemGroup Condition="'$(OS)' != 'Windows_NT'">
    <PackageReference Include="WpfLinux.Sdk" Version="1.0.0" />
  </ItemGroup>
```

要点：
- 覆盖段必须放在**原 `PropertyGroup` 之后**（后设胜）。
- 原 csproj 的 Windows 风格清单（`Asset\*.png`、`C:\Users\hhl\...` 的 `<Content Update>` 等）在 Linux 下若报错/产生噪音，**用条件排除**处理，不要删原项。
- `ProjectReference` **不用改**（仍指原 csproj；对方也加了条件 ⇒ 整链在 Linux 上一致）。

## ③ 边界条款

- **允许改**：上面 7 个原 csproj。
- **允许移动**：7 个 `<Name>.Linux.csproj`（+ 同目录 `PortRuntimeBinding.cs`/`PortShotHook.cs` 若已并入原工程则保留，否则随入口归档）→ `RT/.archive/PortWpfLinux-G-YYYYMMDD/`。
- **禁止改**：业务源码（`*.cs`/`*.xaml`）、非链上工程、`WPFOnLinux/**`。
- 备份先做；同一问题最多 2~3 种方案。

## ④ 验收标准（可计算）

1. **Linux 编译**：7 个原 csproj 各自 `env -u PortWpfRefsMode dotnet build <原 csproj> -v:m` ⇒ `0 个错误`（**不带任何 `-p:`**）。逐个记录警告数。
2. **Windows 侧不可测**，须给出：① 逐字 diff（每个原 csproj 的"新增行"）；② 论证"新增内容全部处于 `'$(OS)' != 'Windows_NT'` 条件下 ⇒ Windows 求值时这些项不存在"。
3. **能跑**：`dotnet build` 后 ICDStudio 跑到主界面（root 截图 OCR 读出业务词、色数 ≥1000）。
4. **无残留**：`find RT -maxdepth 3 -name "*.Linux.csproj"` 活树 = 空；归档可逆（给还原命令）。
5. **回退命令**：给出"恢复 7 个原 csproj + 还原 `.Linux.csproj`"的一条命令。

## ⑤ 失败报告格式

- 每种方案 + 命令原文 + 原始输出；怀疑原因；上报即停止。

## ⑥ 完成报告格式

- 验收证据（可复跑命令 + 原始读数）；验收项 → 证据映射；未覆盖项如实列明。
- 逐字 diff（7 个原 csproj）。
- **主动披露**：Windows 侧无法实测这一事实、以及任何"条件段可能改变 Windows 行为"的疑点。
- 自包含结论。

## ⑦ 环境

- `export PATH="$HOME/.dotnet:$PATH"`；Xvfb/xfwm4/xdotool/import/identify + `rapidocr_onnxruntime`（`python3 /tmp/ocr.py <png>`）齐全。
- `api.nuget.org` 不可达。

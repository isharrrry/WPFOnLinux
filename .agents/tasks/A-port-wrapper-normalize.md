# 任务 A：Port WPF wrapper 公共配方归一（行为零漂移）

## ① 任务目标

两棵 wrapper 树里的 **7 个 WPF wrapper** 存在**逐字重复**的 MSBuild 配方。把它们**公共、逐字相同**的部分抽成共享文件，wrapper 只保留自身特有清单，从而把"公共配方"从 7 处收敛为 1 处。

**为什么有价值**：现在改公共配方要改 7 处，且已出现分叉——`PortWpfRefsMode` 默认值在 ICD-Kit 侧是 `selfbuilt`、在 License-Mgr 侧未显式声明（走 `PortXamlRefs.props` 的默认 `repack`）。收敛后这类漂移只可能发生在唯一处。

**本任务的第一约束是"行为零漂移"**：这是一次纯结构重构，**不允许**改变任何一个 wrapper 的编译结果或运行行为。

### 已在事实（不必重复调研，直接采信）

- 自产 WPF 栈仓根：`/home/links-dev/netTest/GitProj/WPFOnLinux`（= `$(WpfLinuxRoot)`），其自产件 Debug/Release **均已构建**（如 `src/Microsoft.DotNet.Wpf.Linux/src/PresentationCore/bin/Release/PresentationCore.dll` 存在）。
- 构建器：`/home/links-dev/.dotnet/dotnet`（10.0.111），PATH 里已有。
- 改前基线（主控已实测）：`Links-ICD-Kit/PortWpfLinux/ICDStudio` 用
  `dotnet build ICDStudio.Port.csproj -p:PortWpfRefsMode=selfbuilt` = **0 错误 / 937 警告**。
- wrapper 采用"分离式 Sdk"写法：`<Import Sdk.props>`（最先）→ 自身属性 → `<Import Sdk.targets>`（其后）→ 尾部接线。共享文件必须尊重这个顺序约束。

### 在范围的 7 个 wrapper（绝对路径）

1. `/home/links-dev/netTest/GitProj/RT/Links-License-Mgr/PortWpfLinux/Common.Resources/Common.Resources.Port.csproj`
2. `/home/links-dev/netTest/GitProj/RT/Links-License-Mgr/PortWpfLinux/LicenseManagerGUI/LicenseManagerGUI.Port.csproj`
3. `/home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/ICDStudio/ICDStudio.Port.csproj`
4. `/home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/ICDLite/ICDLite.Port.csproj`
5. `/home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/APPGuarder/APPGuarder.Port.csproj`
6. `/home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/Config/Config.Port.csproj`
7. `/home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/AgentRT/AgentRT.Port.csproj`

**明确不在范围**（不要动）：
- `CommonExt/CommonExt.Port.csproj`、`Common.AbsResource/Common.AbsResource.Port.csproj`（netstandard2.1，无 WPF 接线）
- `LicenseManagerCore/LicenseManagerCore.Port.csproj`（net10.0 非 WPF）
- `probe/`、`probe-mini/`

### 已识别出的公共片段（供参考，以逐字比对为准）

- 头部：`<Import Project="Sdk.props" Sdk="Microsoft.NET.Sdk" />`；`WpfLinuxRoot` 默认值；`<Import .../WpfLinux.props />`；`TargetFramework=net10.0-windows`；`OutputType=WinExe`；`GenerateAssemblyInfo=false`；`EnableDefaultCompileItems/EnableDefaultPageItems/EnableDefaultApplicationDefinitionItems=false`；`DisableTransitiveFrameworkReferences=true`。
- 尾部：`<Import Project="Sdk.targets" Sdk="Microsoft.NET.Sdk" />`；`_PortWinFX` 定义 + 条件 import；`BeforeTargets="PrepareResources"` 的 PortCheck `Target`（两处 `Error` 断言文案逐字相同，仅 Target 名不同）。

### 已知的"必须保留在 wrapper 内"的差异（不得强行归一）

- `NoWarn` 内容各不同（如 ICDStudio 含 `CS0108;CS0114;CS0436;SYSLIB0011;SYSLIB0003`，LicenseManagerGUI 不含）
- `PortWpfRefsMode` 默认值：ICD-Kit 侧显式 `selfbuilt`，License-Mgr 侧不声明
- `AssemblyName` / `RootNamespace` / `ApplicationIcon` / `ImplicitUsings` / `Nullable`
- `CR`（= `$(MSBuildProjectDirectory)srctree`）、`Compile`/`Page`/`ApplicationDefinition`/`Resource`/`Content` 清单
- `ProjectReference` / `PackageReference` 清单
- `_PortWinDesktopRefDir` + WinForms 系 `<Reference>`（只有 ICDLite/Common.Resources 等需要）
- `<Import .../PortRuntimeRefs.props />`（只有 WinExe 需要；库 wrapper 没有）
- `<Import .../PortXamlRefs.props />` 的相对路径在两棵树里不同（License-Mgr 侧是 `../`，ICD-Kit 侧是 `../../../Links-License-Mgr/...`）

> ⚠️ **`CR` 的写法坑**：共享文件里的 `$(MSBuildThisFileDirectory)` 指向共享文件自身目录，**不是** wrapper 目录。凡需要 wrapper 目录处，共享文件里必须用 `$(MSBuildProjectDirectory)`。

## ② 边界条款

- **只允许修改**：上面 7 个 wrapper；**新增**共享文件（建议 2 份：`PortWpf.Wrapper.props` + `PortWpf.Wrapper.targets`，放在 `/home/links-dev/netTest/GitProj/RT/Links-License-Mgr/PortWpfLinux/` 下，两棵树共用；名称可自定）。
- **禁止改动**（黑名单）：`WPFOnLinux/**`、`Links-Common-Library/**`、`Links-ICD-Kit/**`（除 `PortWpfLinux/`）、`Links-License-Mgr/**`（除 `PortWpfLinux/`）。
- 同一问题最多试 2~3 种方案；仍失败则如实上报并停止。

## ③ 验收标准（只写可计算判据）

1. **编译**：7 个 wrapper 各自 `dotnet build <wrapper> -v:m` ⇒ `0 个错误`。逐个记录"警告数"。
2. **属性等价**：对 7 个 wrapper 各取改前/改后属性快照并逐项比对，必须**全等**：
   ```
   dotnet msbuild <wrapper> -getProperty:TargetFramework,OutputType,UseWPF,PortWpfRefsMode,NoWarn,AssemblyName,RootNamespace,DisableTransitiveFrameworkReferences,EnableDefaultCompileItems
   ```
   （`PortWpfRefsMode` 对 License-Mgr 侧 wrapper 以 `-p:PortWpfRefsMode=selfbuilt` 与不传两种各取一次。）
3. **产物等价**：改前/改后，各 wrapper 输出的 `bin/**/<AssemblyName>.dll` 与 `*.deps.json` 的 sha256 一致。若 dll 因时间戳/MVID 无法逐字节，则必须给出 `*.deps.json` 的引用集合 diff = **空**，并明示 dll 差异仅为非确定字段（附证据）。
4. **归一有效性**：`grep` 计数证明共享文件被 7 个 wrapper 各 import 至少 1 次。

## ④ 失败报告格式

- 每种已尝试的方案（命令原文）。
- 原始报错/输出片段（引用原文，不得转述）。
- 当前怀疑原因。
- 上报即停止，等待决策；"确认失败"是合法终点。

## ⑤ 完成报告格式

- **验收证据**：可复跑命令 + 原始结果（含 7 个 wrapper 的改前/改后属性快照与产物 sha）。
- **验收项 → 证据映射**：逐条对应，未覆盖项如实列明。
- **差异记账**：列出所有"有意未归一、保留在 wrapper 内"的项及原因。
- **自包含结论**：背景、改了什么、验证了什么、遗留什么。
- **主动披露**：规格与事实不符 / 任务书与源码矛盾 / 发现跨块重复等异常。

## ⑥ 工具与环境

- `export PATH="$HOME/.dotnet:$PATH"`。
- 编译命令示例：
  ```
  cd /home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/ICDStudio
  dotnet build ICDStudio.Port.csproj -p:PortWpfRefsMode=selfbuilt -v:m --nologo
  ```
- NuGet 源已由各 `PortWpfLinux/NuGet.config` 指定（huaweicloud 镜像 + 本地 `RT/build`），不要改。

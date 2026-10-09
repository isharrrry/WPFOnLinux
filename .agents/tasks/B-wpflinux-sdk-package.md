# 任务 B：把自产 WPF 栈包化成 NuGet 包 + MSBuild SDK（MVP：改几行即可编译）

## ① 任务目标

**现状**：消费方（`RT/Links-*` 仓库）每个 WPF 工程都要写一份 `.Port.csproj` wrapper，内含约 30 行"接线"：`<Reference HintPath=...>` 指向**现场构建**的自产件、一批 OOB BCL 包、PBT 路径、以及"引用件身份替换"。12 个 wrapper 各写一遍。

**目标**：做一个 NuGet 包（+ `buildTransitive` props/targets），消费方只写**几行**即可在 Linux 上编译。

**本任务 = MVP，只做两件事**：
- **MVP-1（必达）**：让一个**最小 WPF 工程**只靠"包引用 + 几行"编译 **0 错误**。
- **MVP-2（若 MVP-1 通过再做）**：用同一个包让 `Links-ICD-Kit/PortWpfLinux/ICDStudio/ICDStudio.Port.csproj` 的**等价最小接入**编译 **0 错误**（不要求替换现有 wrapper，见边界）。

### 已在事实（直接采信，不必重复调研）

- 自产件（Release）**完整一套已构建**，就在聚合目录：
  `$(WpfLinuxRoot)/src/Microsoft.DotNet.Wpf.Linux/src/CycleStub.PresentationFramework/bin/Release/`
  → `WindowsBase.dll`、`System.Xaml.dll`、`PresentationCore.dll`、`PresentationFramework.dll`、`DirectWriteForwarder.dll`、`UIAutomationTypes.dll`、`UIAutomationProvider.dll`、`System.Windows.Input.Manipulations.dll`、`System.Windows.Extensions.dll`、`DirectWrite.Linux.Provider.dll`（共 10 个）
- PBT：`$(WpfLinuxRoot)/src/Microsoft.DotNet.Wpf.Linux/src/PresentationBuildTasks/bin/Release/net10.0/PresentationBuildTasks.dll`
- 原生库：`libwpfwin32.so`、`libwpfwic.so`、`libSkiaSharp.so`、`wpfgfx_cor3.so`（用 `find $(WpfLinuxRoot) -name "*.so" | grep -v obj` 定位）
- 现有接线范本（**要移植成包内容**，不要调用它们）：
  - `$(WpfLinuxRoot)/src/Linux/build/third-party/WpfLinux.props` —— 自产件 `<Reference>` 清单 + OOB 包 + SkiaSharp
  - `RT/Links-License-Mgr/PortWpfLinux/PortXamlRefs.props` —— **身份替换**（`xamlrefs/` 改版件，Version=10.0.0.0）
  - `RT/Links-License-Mgr/PortWpfLinux/PortRuntimeRefs.props` —— selfbuilt 模式的运行期借用件
  - `RT/Links-License-Mgr/PortWpfLinux/PortWpf.Wrapper.props` / `.targets` —— 任务 A 刚抽出的公共配方
  - `RT/Links-License-Mgr/PortWpfLinux/xamlrefs/` —— 身份改版件（编译期必需）
- **XAML 编译**靠 `<Import Project="$(MSBuildSDKsPath)/Microsoft.NET.Sdk.WindowsDesktop/targets/Microsoft.WinFX.targets" Condition="Exists(...)">` + `_PresentationBuildTasksAssembly`（自产 PBT）。
- 构建器：`/home/links-dev/.dotnet/dotnet`（10.0.111），PATH 里已有。

### 关键技术判断（已由主控分析，作为设计起点，允许实测推翻）

1. **包化能顺带修掉一个既有缺陷**：`PortWpfRefsMode` 现在设在 wrapper 内（普通属性），**不会传给 SDK 生成的 `*_wpftmp.csproj` 临时工程**，导致 wpftmp 走 `repack` 默认、与主工程 `selfbuilt` 身份不一致 → `CS0012`（ICDStudio 不带 `-p:PortWpfRefsMode=selfbuilt` 时必失败）。
   **机制**：NuGet 的 `buildTransitive/*.props` 会被写进 `obj/*.nuget.g.props`，而 wpftmp 与主工程同目录、会 import 同目录的 `nuget.g.props` ⇒ **包里的属性对 wpftmp 生效**。这是本任务要**实测验证**的第一件事。
2. **身份策略**：优先让包内 lib 就是 `xamlrefs/` 那套改版件（Version=10.0.0.0、System.Xaml 用官方公钥），这样对第三方 WPF 包（AvalonDock 等）天然兼容，且 PBT 的类型解析不会撞身份。若实测不可行，退回 selfbuilt 真件 + PBT 按名回退 + 运行期绑定，并**如实记录**。
3. **原生库**：`.so` 应作为 RID native assets（`runtimes/linux-x64/native/`）随包，使消费方**无需手工拷 .so**。若实测 native assets 部署不到输出目录，退化为包内 targets 里的 `<Copy>` 步骤，并如实记录。

## ② 边界条款

- **只允许新增**：在 `$(WpfLinuxRoot)/src/Linux/build/third-party/pkg/`（包工程，名称自定）与 `$(WpfLinuxRoot)/src/Linux/samples/WpfLinuxSdkProbe/`（MVP-1 样板）下新增文件。
- **禁止改动**（黑名单，一个字节都不许动）：
  - `$(WpfLinuxRoot)` 下**既有**文件（可新增，不可改）
  - `RT/Links-ICD-Kit/**`、`RT/Links-Common-Library/**`、`RT/Links-License-Mgr/**` 的**既有文件**（MVP-2 允许在该目录树**新增**一个验证用工程，但不得修改现有 wrapper）
- **明确不做**：不删除、不替换任何现有 wrapper（`PortWpfLinux/**` 保持可用；是否切换由用户后续决定）。
- 同一问题最多试 2~3 种方案；仍失败则如实上报并停止。

## ③ 验收标准（只写可计算判据）

**MVP-1**
1. 包文件存在：`*.nupkg` 落盘（记录大小与路径）。
2. 样板工程 `.csproj` 的**接入行数** ≤ 8 行（不含注释），且**不含**任何指向 `WpfLinuxRoot` 的绝对 `HintPath`。
3. `dotnet build <样板> -v:m` ⇒ **0 个错误**（记录警告数）。
4. 产物 `bin/**/<name>.dll` 存在，且 `deps.json` 中 WPF 件（WindowsBase/PresentationCore/PresentationFramework/System.Xaml）**来自包的版本**（记录身份：Version/PublicKeyToken）。
5. **修缺陷验证**：样板工程**不带任何 `-p:`** 做 `dotnet build -t:Rebuild` ⇒ 仍 0 错误（即 wpftmp 不再身份不一致）。

**MVP-2**（可选）
6. 用包的接入方式让 ICDStudio 等价工程编译 0 错误（不带 `-p:`）。
7. `dotnet <ICDStudio 产物>.dll` 能启动到出现窗口（进程存活 ≥10s）——只验"能起"，不验界面完整。

## ④ 失败报告格式

- 每种已尝试方案的命令原文 + 原始输出片段（引用原文，不得转述）。
- 当前怀疑原因。
- 上报即停止，等待决策；"确认失败"是合法终点，禁止伪造通过。

## ⑤ 完成报告格式

- 验收证据：可复跑命令 + 原始结果。
- 验收项 → 证据映射：逐条对应，未覆盖项如实列明。
- **主动披露**：规格与事实不符、任务书与源码矛盾、包化引入的新问题（尤其"包化后仍做不到的事"）。
- 自包含结论：背景、做了什么、验证了什么、遗留什么。

## ⑥ 工具与环境

- `export PATH="$HOME/.dotnet:$PATH"`。
- NuGet 源：`RT/Links-License-Mgr/PortWpfLinux/NuGet.config` 与 `RT/Links-ICD-Kit/PortWpfLinux/NuGet.config`（huaweicloud + 本地 `RT/build`）；打包后可放到本地目录做源，或用 `-p:RestoreAdditionalProjectSources=`。
- ⚠️ 本环境 `api.nuget.org` 不可达，只用镜像。

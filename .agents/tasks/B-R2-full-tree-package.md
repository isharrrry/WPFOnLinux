# 任务 B-R2：包化覆盖依赖链 —— 让真实工程"零外部设置"即可编译

## ① 任务目标

**现状（主控已独立复验，直接采信）**：
- B 的 MVP-1（单工程）**已成立**：`WpfLinuxSdkProbe` 只用 8 行 csproj + 一行 `<PackageReference Include="WpfLinux.Sdk" />`，干净环境**无 `-p:`、无环境变量**下 `dotnet build` 与 `-t:Rebuild` 均 **0 错误 0 警告**。
- B 的 MVP-2（真实工程）**未成立**：`ICDStudioSdkProbe` 在**不设环境变量**时 ⇒ `CS0012`（要求 `System.Xaml, Version=10.0.0.0, …b77a…`）**生成失败**；只有 `export PortWpfRefsMode=selfbuilt` 后才 0 错误。

**根因（B 已查明）**：`ICDStudioSdkProbe` 依赖的 4 个 WPF 工程（`APPGuarder`、`ICDLite`、`LicenseManagerGUI`、`Common.Resources`）仍是"仓内配方 wrapper"，它们靠 `PortWpfRefsMode` 选引用身份；该属性**无法经包传播**（`ProjectReference.AdditionalProperties` 不递归到孙子工程 ⇒ 878 个 `CS0103`）。

**本任务目标**：把这条依赖链上的 WPF 工程也改成"**包化接入**"，使得
**`ICDStudioSdkProbe` 在不设任何环境变量、不带任何 `-p:` 的情况下编译 0 错误**。

### 已知事实与坑（来自 B 的报告，不必重复踩）

1. 包与包源：`$(WpfLinuxRepoRoot)=/home/links-dev/netTest/GitProj/WPFOnLinux`；包工程 `$WpfLinuxRepoRoot/src/Linux/build/third-party/pkg/WpfLinux.Sdk.csproj`，产物 `pkg/out/WpfLinux.Sdk.1.0.0.nupkg`。包版本写死 `1.0.0` ⇒ 重打包后必须 `rm -rf ~/.nuget/packages/wpflinux.sdk`（或 bump 版本）。
2. 包化**库工程**的写法（见现有 `ICDStudioSdkProbe`）：`EnableDefaultWpfLinuxItems=false` + 自己列 `Compile`/`Page`/`ApplicationDefinition` 清单。**本任务建议更进一步**：若可行，让包支持"源码树模式"（例如 `<WpfLinuxSrcTree>../MyLib</WpfLinuxSrcTree>` 时自动收集 `srctree/**/*.cs` 与 `*.xaml`），使库工程接入也能压到 ≤ 10 行。**做不做这个扩展由你判断**，但必须在报告里说明你的选择与理由。
3. **官方借用件**（Ribbon / WinForms 系 7 件，现在靠 `RT/Links-License-Mgr/PortWpfLinux/refruntime/` 手工 `HintPath`）：业务用到才需要；`ICDStudio` 需要（`ICDStudioSdkProbe` 现有写法引了 `refruntime`）。**是否也进包**由你判断；若进包，建议同一包或并行包，并记录。
4. **SWE 传递坑**：依赖工程里的 `PackageReference System.Windows.Extensions ExcludeAssets="compile;runtime"` **只在它自己工程内生效**，作为依赖流到入口就不再排除 ⇒ 官方 SWE 盖掉包内的自产替身 ⇒ 运行期 `PlatformNotSupportedException`。现在靠入口再排除一次（老配方残留）。**理想是让包解决它**。
5. `wpftmp`（XAML 临时工程）会复用主工程 RAR 的 `ReferencePath`，所以"身份一致"靠的是整图引用身份统一，而不是单点属性。

## ② 边界条款

- **允许新增**：包化版依赖工程（建议：
  - `RT/Links-ICD-Kit/PortWpfLinux/APPGuarder/APPGuarder.Sdk.csproj`
  - `RT/Links-ICD-Kit/PortWpfLinux/ICDLite/ICDLite.Sdk.csproj`
  - `RT/Links-License-Mgr/PortWpfLinux/LicenseManagerGUI/LicenseManagerGUI.Sdk.csproj`
  - `RT/Links-License-Mgr/PortWpfLinux/Common.Resources/Common.Resources.Sdk.csproj`
  - 以及传递依赖的其它需包化的 WPF 工程，按实际依赖链补齐）
- **允许修改**：`pkg/`（包源码与 `buildTransitive`）、`ICDStudioSdkProbe/`（改引用目标为包化版）。
- **禁止改动**（黑名单）：`WPFOnLinux` 既有文件（可新增、可改 `pkg/`）；`RT/Links-*` 的**现有** wrapper（`*.Port.csproj`）与任何业务源码。
- **明确不做**：不删除、不替换现有 `*.Port.csproj`（它们要保持可用）。
- 同一问题最多试 2~3 种方案；仍失败则如实上报并停止。

## ③ 验收标准（只写可计算判据）

1. **零外部设置编译**（核心判据）：
   ```
   cd RT/Links-ICD-Kit/PortWpfLinux/ICDStudioSdkProbe
   unset PortWpfRefsMode ; rm -rf obj bin
   dotnet build ICDStudioSdkProbe.Port.csproj -v:m
   ```
   ⇒ **`0 个错误`**（记录警告数）。**命令里不得出现 `-p:`，环境里不得有 `PortWpfRefsMode`**。
2. **同命令 `-t:Rebuild`** 也 0 错误（防止 wpftmp 缓存掩盖）。
3. **接入行数**：`ICDStudioSdkProbe` 与每个新增的 `*.Sdk.csproj` 的接入行数（非注释、非特有清单）逐项记录；`ICDStudioSdkProbe` 自身 ≤ 12 行。
4. **无绝对 `HintPath`**：新增工程里指向 `WpfLinuxRepoRoot` 的绝对 `HintPath` 计数 = 0（借用件若必须 HintPath，需说明为何不能进包）。
5. **运行**（若时间允许）：`dotnet ICDStudioSdkProbe.dll` 启动到出现窗口（存活 ≥10s、非全黑），证明包化没破坏运行期。

## ④ 失败报告格式

- 每种已尝试方案的命令原文 + 原始输出片段（引用原文）。
- 当前怀疑原因；上报即停止；"确认失败"是合法终点。

## ⑤ 完成报告格式

- 验收证据：可复跑命令 + 原始结果（尤其判据 1/2 的原始输出）。
- 验收项 → 证据映射：逐条对应，未覆盖项如实列明。
- **主动披露**：包化后仍做不到的事、以及每条残留的成因。
- 自包含结论：背景、做了什么、验证了什么、遗留什么。

## ⑥ 工具与环境

- `export PATH="$HOME/.dotnet:$PATH"`；NuGet 源用各目录现有 `nuget.config`（含 `pkg/out` 与镜像）。
- 本环境 `api.nuget.org` 不可达。

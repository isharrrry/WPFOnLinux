# 任务 D：清理 PortWpfLinux 旧 wrapper 体系（归档，可逆）

## ① 任务目标

任务 B 把 Linux 接入压到了每个工程 6 行（薄 `*.Sdk.csproj` + 一行 `PackageReference WpfLinux.Sdk`）。但 `PortWpfLinux/` 下**仍并存**旧的 `*.Port.csproj` wrapper（每个约 50~80 行、靠仓内 props 接线）以及**仅它们使用**的辅助 props。

**本任务**：把旧体系**整体归档**（移到 `.archive-legacy-wrappers/`，**不要删除**——该仓库无 git，删除不可逆），使 `PortWpfLinux/` 只剩包化接入所需。

**附加**：为 ICDStudio 补一个**正式的包化入口** `ICDStudio/ICDStudio.Sdk.csproj`（`AssemblyName=ICDStudio`），因为现有的 `ICDStudioSdkProbe/ICDStudioSdkProbe.Port.csproj` 是"等价验证工程"（程序集名不同），不是正式入口。

### 已核实事实（直接采信）

- 两个仓库**都无 git**（`git rev-parse` 报 `不是 git 仓库`）⇒ **移动而非删除**。
- 所有 `*.Sdk.csproj` 已**不依赖**旧 props（实测：唯一命中是 `APPGuarder.Sdk.csproj:4` 的**注释文字**，非引用）。
- 两棵树的路径：
  - `/home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/`
  - `/home/links-dev/netTest/GitProj/RT/Links-License-Mgr/PortWpfLinux/`
- 包源与包：`$WpfLinuxRepoRoot=/home/links-dev/netTest/GitProj/WPFOnLinux`；包在 `$WpfLinuxRepoRoot/src/Linux/build/third-party/pkg/out/`。
- 复跑基线（任务 B-R2 已验）：`ICDStudioSdkProbe` 在 `env -u PortWpfRefsMode`、无 `-p:` 下 `dotnet build` = **0 错误**。

## ② 边界条款

- **只允许**在两棵 `PortWpfLinux/` 树内移动/新增文件。禁止修改 `WPFOnLinux/**`、各仓库的业务源码、以及任何 `*.Sdk.csproj` 的**语义**（可整份复制以派生新工程）。
- **禁止删除**任何文件（一律移动到归档目录）。
- 移走前必须**逐个**确认目标文件不被任何 `*.Sdk.csproj` 引用；被引用者**不得移动**并须报告。

### 归档清单（移到 `<该树>/.archive-legacy-wrappers/<原相对路径>`）

- 所有 `*.Port.csproj`（ICD-Kit：5 个 + `ICDStudioSdkProbe/ICDStudioSdkProbe.Port.csproj` 保留原位不动，见下）
- `WpfLinux.props`、`Directory.Build.props`（两树各自）
- `PortPpf.Wrapper.props`、`PortPpf.Wrapper.targets`（License-Mgr 侧）
- `PortXamlRefs.props`、`PortRuntimeRefs.props`（License-Mgr 侧）
- `xamlrefs/`、`refruntime/`（License-Mgr 侧）
- 其它**仅被 `*.Port.csproj` 引用**的辅助件（逐个 grep 判定后处理）

> ⚠️ `ICDStudioSdkProbe/ICDStudioSdkProbe.Port.csproj` **保留原位**（它是任务 B/C 的验证工程，仍要用）。

### 保留原位（不可移动）

`*.Sdk.csproj`、`srctree` 符号链接、`PortRuntimeBinding.cs`、`PortShotHook.cs`、`NuGet.config`、`FodyWeavers.xml/.xsd`、所有 `*.md`、`shots/`、`evidence/`、`logs/`、`tools/`、`probe*`（若 Sdk 工程用不到也归档，但需先证明）。

### 新增

`/home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/ICDStudio/ICDStudio.Sdk.csproj`
—— 以 `ICDStudioSdkProbe.Port.csproj` 为模板，改 `AssemblyName=ICDStudio`；`srctree` 用同目录既有 `ICDStudio/srctree`；`PortRuntimeBinding.cs` / `PortShotHook.cs` 直接引用同目录文件。

## ③ 验收标准（可计算）

1. **移动前证据**：对每个待归档文件，`grep -rl "<文件名>" --include="*.Sdk.csproj"` 计数 = 0（把命令与读数写进报告）。
2. **全部包化工程仍可编译**：逐个 `dotnet build <工程> -v:m` ⇒ `0 个错误`：
   - ICD-Kit：`AgentRT.Sdk`、`APPGuarder.Sdk`、`Config.Sdk`、`ICDLite.Sdk`、`ICDStudio.Sdk`（新增）
   - License-Mgr：`Common.Resources.Sdk`、`LicenseManagerGUI.Sdk`
   - 且 **不带任何 `-p:`、环境无 `PortWpfRefsMode`**。
3. **归档清单**：逐文件列出（源路径 → 归档路径）。
4. **不回归**：`ICDStudioSdkProbe` 仍 `0 个错误`；`PortWpfLinux/` 根下残留的"唯一入口"只剩 `*.Sdk.csproj` 与保留项。
5. `ICDStudio.Sdk.csproj` 编译出的 `ICDStudio.dll` 存在（记录路径）。

## ④ 失败报告格式

- 每种已尝试方案 + 原始输出；当前怀疑原因；上报即停止。

## ⑤ 完成报告格式

- 验收证据（可复跑命令 + 原始读数）。
- 验收项 → 证据映射；未覆盖项如实列明。
- **归档清单**（逐文件）+ **保留清单**。
- **主动披露**：哪些文件你判断"不敢动"及原因；包化后仍显得多余的项。
- 自包含结论。

## ⑥ 环境

- `export PATH="$HOME/.dotnet:$PATH"`；`env -u PortWpfRefsMode` 保证无该环境变量。
- 本环境 `api.nuget.org` 不可达，NuGet 源用各目录现有配置。

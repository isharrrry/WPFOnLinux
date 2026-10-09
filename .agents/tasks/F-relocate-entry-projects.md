# 任务 F：让 PortWpfLinux 目录消失 —— Linux 入口工程"就近化"

## ① 任务目标

用户**不接受** `RT/Links-ICD-Kit/PortWpfLinux/` 与 `RT/Links-License-Mgr/PortWpfLinux/` 这两个**目录本身**存在（已多轮追问"portwpflinux 怎么还在"）。

**本任务**：把 7 个已包化的 Linux 入口工程（`*.Sdk.csproj`）**就近迁到各自原工程处**，使 `PortWpfLinux/` 两棵树可**整体归档**（移动，不删除——仓库无 git）。

### 已核实事实（直接采信）

- 入口工程现在的家：`RT/Links-ICD-Kit/PortWpfLinux/<Name>/<Name>.Sdk.csproj`、`RT/Links-License-Mgr/PortWpfLinux/<Name>/<Name>.Sdk.csproj`。
- 每个入口的 `srctree` 软链**指向的原工程目录**（实测 `readlink -f`）：
  | 入口 | 原工程目录 |
  |---|---|
  | ICDStudio | `RT/Links-ICD-Kit/ICDStudio/` |
  | ICDLite | `RT/Links-ICD-Kit/ICDLite/` |
  | AgentRT | `RT/Links-ICD-Kit/AgentRT/` |
  | APPGuarder | `RT/Links-Common-Library/Guarder/` |
  | Config | `RT/Links-Common-Library/Config/` |
  | Common.Resources | `RT/Links-Common-Library/Common.Resources/` |
  | LicenseManagerGUI | `RT/Links-License-Mgr/LicenseManager/` |
- 基线：这 7 个 + `ICDStudioSdkProbe` 在 `env -u PortWpfRefsMode`、无 `-p:` 下目前**全 0 错误**。
- 包：`WpfLinux.Sdk`，源 `$(WpfLinuxRoot)/src/Linux/build/third-party/pkg/out`（`WpfLinuxRoot` 由各树 `Directory.Build.props` 提供；**迁移后可能没有 Directory.Build.props 了，见 §2**）。

## ② 形式（主控定，允许按实测调整并在报告说明）

- 每个入口 → **`<原工程目录>/<Name>.Linux.csproj`**（与原 csproj 同目录）。
  - 若同目录实测不可行（例如源码收集会把 `obj/` 卷进来），退化为 `<原工程目录>/wpf-linux/<Name>.Linux.csproj` + `srctree -> ..`，并**说明为什么**。
- `WpfLinuxSrcTree` 设成**同目录**（`$(MSBuildProjectDirectory)`）；**不要**再引入 srctree 软链（除非证明必须）。
- **obj/bin 隔离**（同目录两个工程不能共用）：`BaseIntermediateOutputPath=obj/Linux/`、`BaseOutputPath=bin/Linux/`。
- `PortRuntimeBinding.cs` / `PortShotHook.cs`（ICDStudio 的运行期新增件）**随入口放同目录**。
- `ProjectReference`：指向其它入口的**新位置**；非 WPF 工程（`DbcParserLib`/`ICDConverter`/`Lib*`/`Ason`/`ICDLiteCore` 等）仍引用**原 csproj**（它们在 Linux 上可原样编）。
- **`WpfLinuxRoot` 的来源**：迁移后各树 `PortWpfLinux/Directory.Build.props` 会随目录归档。解决方式二选一（自行判断并在报告说明）：
  - 在入口 csproj 里直接写 `$(WpfLinuxRoot)` 的兜底（`Condition="'$(WpfLinuxRoot)'==''"`）；或
  - 在原工程树根新增一个**只含 `WpfLinuxRoot`** 的 `Directory.Build.props`（须确认不与既有 `Directory.Build.props` 冲突）。
- `NuGet.config`：入口需要能 restore 到仓内包（`pkg/out`）。沿用现有的 `RestoreAdditionalProjectSources` 逐工程追加方式即可。

## ③ 验收标准（可计算）

1. **7 个新入口全部编译 0 错误**：逐个 `dotnet build <新路径>.Linux.csproj -v:m`（**不带任何 `-p:`、`env -u PortWpfRefsMode`**）。
2. **`PortWpfLinux/` 两棵树整体归档**：活树不再存在该目录；归档可逆（给出还原命令）。
3. **原工程 csproj 一个字节不改**（只**新增** `.Linux.csproj`）：给出 mtime/内容比对证据。
4. **能跑**：ICDStudio 入口启动到主界面（Xvfb+xfwm4；root 截图 OCR 能读出菜单/工作空间等业务词；色数 ≥1000）。
5. **接入行数**：逐个记录新入口的"接入行数"（包引用 + 源码树开关等）。

## ④ 失败报告格式

- 每种方案 + 命令原文 + 原始输出片段；当前怀疑原因；上报即停止。

## ⑤ 完成报告格式

- 验收证据（可复跑命令 + 原始读数）；验收项 → 证据映射；未覆盖项如实列明。
- 迁移清单（旧路径 → 新路径）+ 归档清单。
- **主动披露**：同目录方案的实际代价（如 `dotnet build` 无参会歧义）、未覆盖项、下一步阻塞。
- 自包含结论。

## ⑥ 环境

- `export PATH="$HOME/.dotnet:$PATH"`；Xvfb/xfwm4/xdotool/xwininfo/import/identify + `rapidocr_onnxruntime`（`python3 /tmp/ocr.py <png>`）齐全。
- 驱动坑：`xdotool mousemove` 与 `click` 必须分开并留延迟。
- `api.nuget.org` 不可达。

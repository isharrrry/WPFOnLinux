# 上游布局对照（一个上游工程一行）

[English](layout.md) | **中文** | [Español](layout.es.md)

> 本文属于 **docs.Linux** —— 回 [移植侧文档总线](../README.zh-CN.md)（[English](../README.md) · [Español](../README.es.md) · [中文](../README.zh-CN.md)）。

**这一页回答一个问题**：上游 `dotnet/wpf` 的某个工程，**在我们仓里落到了哪里**（谁在编译、谁在覆盖）。

- **上游快照**：`upstream/wpf/`（**只读**、构建的输入；基点 `1cfc37f708f91ff4556bd25af414546c446f3a16`，判据见 [`docs/UPSTREAM-PROVENANCE.md`](../../docs/UPSTREAM-PROVENANCE.md)）。
- **本仓的构建是"生成式"**：`build/port-lib.py` 从 `upstream/wpf/**` **读源**、**整体重写** `build/<工程>.Linux/<工程>.Linux.csproj` ——
  所以"上游一件"在仓里通常对应**三处**：`upstream/wpf/**`（只读源）＋ `build/<工程>.Linux/**`（生成的构建工程）＋ 覆盖层（`src/WpfGfx.Linux*/**`、`build/shims/**`、应用器 `patch-*.py`）。
- **口径**：本表按 `ls upstream/wpf/src/Microsoft.DotNet.Wpf/src/` 的**工程子树目录**逐行列；**不含**该目录下那个 `Directory.Build.Props` 文件（它由 `port-lib.py` 的 `upstream_nowarn()` 逐层读取）。

| 上游工程（`upstream/wpf/src/Microsoft.DotNet.Wpf/src/…`） | 本仓现状数据流 | Linux 覆盖 / 替换 |
|---|---|---|
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Common/` | `port-lib.py` 按 `$(WpfCommonDir)`／`$(WpfCodeGenDir)` 解析；`build/gen-sr.py`、`build/port-pbt.sh` 读它 | 无对位件；资源/代码生成改为仓内生成（各 `build/*.Linux/SR.g.cs`） |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/DirectWriteForwarder/` | `build/DirectWriteForwarder.Linux/`（**手写工程**，不参与 `port-lib.py` 重生成） | `build/DirectWriteForwarder.Linux/{ProviderAdapters,ManagedSurface,NativeMirrors,AssemblyAttrs}.cs` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Extensions/` | `build/System.Windows.Extensions.Linux/`（**手写工程**；产物按 `HintPath` 被 XAML/WB/PC/PF 取用） | `System.Windows.Extensions.Linux.cs` —— 原生替身；接线状态见 `build/System.Windows.Extensions.Linux/PORT-CHANGES.md` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PenImc/` | **未进本仓托管构建**（`build/` 下无对位工程；`port-lib.py` 不处理） | 无；触笔面缺口走在册缺陷册 |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationBuildTasks/` | `build/port-pbt.sh` **读上游 csproj ＋ 文本变换** → `build/PresentationBuildTasks.Linux/` | 单目标 `net10.0`、路径分隔符、SR 生成（逐条见 `build/PresentationBuildTasks.Linux/PORT-CHANGES.md`） |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/` | `port-lib.py PresentationCore` **整体重写** `build/PresentationCore.Linux/PresentationCore.Linux.csproj`；剔除清单 `build/excludes/PresentationCore.txt` | `build/PresentationCore.Linux/*.Linux.cs`（`HwndSource`／`HwndTarget`／`InputManager`／`SimpleTextLine`…）＋ `build/shims/PresentationCore.*.cs`（含 `HbTextLine` shim）＋ `src/WpfGfx.Linux/{Text,Windowing,Rendering,Commands,Interop}/**` ＋ 应用器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-*.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/` | `port-lib.py PresentationFramework` **整体重写** `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj`；另有 `.Classic` 变体 `build/PresentationFramework.Classic.Linux/` | `build/PresentationFramework.Linux/*.Linux.cs`（`FlowDocument*`／`DocumentPage*`／`PtsHelper`／`PtsCache`…）＋ `build/shims/PresentationFramework.*.cs` ＋ 应用器 `patch-presentationframework-*.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/` | `build/CycleStub.PresentationUI.Linux/`（**循环桩**：`ApiSubset.cs`／`FindToolBar.ApiSubset.cs`／`ThemeInfo.Linux.cs`） | 主题字典补齐属 hc demo 修复链（`T-B16`…`T-B19`，见 [`../../docs/ROUTES.md`](../../docs/ROUTES.md)） |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/ReachFramework/` | `port-lib.py ReachFramework` → `build/ReachFramework.Linux/`；与 PF **真互引** ⇒ 用 `build/CycleStub.ReachFramework.Linux/` 断环 | `build/CycleStub.ReachFramework.Linux/ApiSubset.cs`、`SR.g.cs`、`reapply-patches.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Shared/` | 被各 `*.Linux.csproj` 以 `$(WpfSharedDir)` 引入（同一份源进多个工程） | 应用器 `patch-shared-hwndwrapper-diag.py`、`patch-shared-invariant-failfast.py`（改**接线与生成物**，不改上游源） |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Printing/` | `build/System.Printing.Linux/`（**手写工程**） | `PORT-CHANGES.md`；`printcontext.cs` 等被剔出 PC（见 `build/excludes/PresentationCore.txt`） |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Controls.Ribbon/` | **未进本仓托管构建** | 无 |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Input.Manipulations/` | `port-lib.py System.Windows.Input.Manipulations` → `build/System.Windows.Input.Manipulations.Linux/` | `SR.g.cs` ＋ `PORT-CHANGES.md` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Presentation/` | **无独立 Linux 工程**（其类型面由 PC/PF 共同提供） | 无 |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Primitives/` | **未进本仓托管构建** | 无 |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/` | `port-lib.py System.Xaml` → `build/System.Xaml.Linux/` | `SR.g.cs` ＋ `PORT-CHANGES.md` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Themes/` | **无独立 Linux 工程**：主题字典随 PF／PresentationUI 桩进产物 | `build/CycleStub.PresentationUI.Linux/Themes/Generic.xaml` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/` | 只落**两个**子工程：`build/UIAutomationTypes.Linux/` 与 `build/UIAutomationProvider.Linux/`（`UIAutomationClient` **未编**） | `build/shims/Accessibility.Shim.cs`、`build/shims/Win32ShimResolver.cs`、`build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs`、预应用器 `wire-uiautomation-resolver.py`（**先于 port-lib**）＋ `patch-uiautomationtypes-reservedvalue.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/` | `port-lib.py WindowsBase` **整体重写** `build/WindowsBase.Linux/WindowsBase.Linux.csproj`；剔除清单 `build/excludes/WindowsBase.txt` | `build/WindowsBase.Linux/*.Linux.cs`（`DependencyObject`／`Dispatcher`／`HwndWrapper`／`Invariant`／`SecurityHelper`／`TextServicesLoader`…）＋ `build/shims/{WindowsWin32,WindowsBase.EventTrace}.Shim.cs`（逐件清单见 `build/shims/WindowsBase.shims.txt`）＋ 应用器 `patch-windowsbase-*.py` |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/WindowsFormsIntegration/` | **未进本仓托管构建** | PF 侧用 `build/shims/PresentationFramework.NrbfFrameworkObjects.Shim.cs` 顶替其私有包依赖 |
| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/WpfGfx/` | **不进托管构建**（上游是 VC++ 原生渲染核） | 由 `wpfgfx_cor3.so`（AOT 的 milcore）＋ 原生 shim **替换实现** ⇒ 见 [`linux-overlay.zh-CN.md`](linux-overlay.zh-CN.md) |

---

## 复算（本表口径可逐条自证）

```bash
# ① 工程子树目录数（本表的"工程行数"）：期望 21
ls -d upstream/wpf/src/Microsoft.DotNet.Wpf/src/*/ | wc -l
# ② 该目录下**条目**数（＝工程子树 ＋ 1 个 Directory.Build.Props）：期望 22
ls upstream/wpf/src/Microsoft.DotNet.Wpf/src/ | wc -l
# ③ 本表的行数：期望 21
grep -c '^| `upstream/wpf/src/Microsoft.DotNet.Wpf/src/' docs.Linux/upstream/layout.zh-CN.md
```

⚠️ **如实划界**：`ls … | wc -l` 读数是 **22**，因为该目录下除 21 个工程子树外还有 **1 个文件** `Directory.Build.Props`（136 B）。
本表列的是 **21 个工程子树** ⇒ `①` 与 `③` 逐数相符，与 `②` 差 1（差的正是那个 props 文件）。
`build/port-lib.py` 的 `upstream_nowarn()` 会**逐层**读它（`Directory.Build.props`／`Directory.Build.Props` 两种拼写都认）。

---

## 边界与"谁不在这张表上"

- **`build/*.Linux/` 是生成物**：`port-lib.py` 会**整体重写** csproj ⇒ 手工改接线会被抹掉；接线必须落在**应用器**（`src/WpfGfx.Linux.Native/tools/patch-*.py`）。
- **手写工程**（不参与 `port-lib.py` 重生成）：`DirectWriteForwarder.Linux`、`System.Printing.Linux`、`System.Windows.Extensions.Linux`、`CycleStub.*`、`build/DirectWrite.Linux/Provider/`、`src/WpfGfx.Linux/`。依据见 `build/integration-wave.sh:106-107`。
- **上游 `src/Microsoft.DotNet.Wpf/src/` 下还有 `Common/`**（代码生成器与 `SR` 模板）——它不是一个可编译工程，但被 `$(WpfCommonDir)`／`$(WpfCodeGenDir)` 引用，故照列。
- **根上不再有第二份 Windows 源**：fork 根曾自带的那棵 dotnet/wpf 树已在 `7027be06e`（P0 结构性去重）移出 19 条路径；理由与复算见 [`../../docs/UPSTREAM-PROVENANCE.md`](../../docs/UPSTREAM-PROVENANCE.md) 与 `build/MilBridge/P0-migrate-report.md`。

---

[English](layout.md) | **中文** | [Español](layout.es.md) · [移植侧文档总线](../README.zh-CN.md) · [Linux 覆盖层专章](linux-overlay.zh-CN.md)

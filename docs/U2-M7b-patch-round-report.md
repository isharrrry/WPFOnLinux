# M7b-补丁轮报告 · 两个"挡一切 WPF 窗口"的运行期拦路虎

**结论：任务书的两条全部修完并实测通过；另外独立发现并定位了第 3 条同级拦路虎（不在本里程碑可写边界内，已交付一键应用器）。**

| 门禁 | 结果 |
|---|---|
| `build/WindowsBase.Linux` 构建 | **0 错 0 警** |
| `build/PresentationCore.Linux` 构建 | **0 错 0 警** |
| `dotnet test tests/.../ManagedLayer.Tests`（Xvfb :99） | **28 / 28 全绿**（原 19 条 + 新增 9 条） |
| 同上，**无 X server** | **20 通过 / 8 发现期跳过 / 0 失败** |

---

## 1. 拦路虎 ① · WindowsBase `AvTrace` 注册表 NRE —— 已修（补丁 G）

### 1.1 改前（T3 实测 + 本轮独立复核）

```
TypeInitializationException: The type initializer for 'System.Windows.PresentationSource' threw an exception.
 └ TypeInitializationException: The type initializer for 'MS.Internal.TraceDependencyProperty' threw an exception.
    └ NullReferenceException
       at MS.Internal.WindowsBase.SecurityHelper.ReadRegistryValue(RegistryKey baseRegistryKey, String keyName, String valueName)
            …/Shared/MS/Internal/SecurityHelper.cs:line 215
       at MS.Internal.AvTrace.IsWpfTracingEnabledInRegistry()   …/WindowsBase/MS/Internal/AvTrace.cs:line 213
       at MS.Internal.AvTrace.ShouldCreateTraceSources()        …/WindowsBase/MS/Internal/AvTrace.cs:line 188
       at MS.Internal.AvTrace..ctor(...)                        …/WindowsBase/MS/Internal/AvTrace.cs:line 43
       at MS.Internal.TraceDependencyProperty..cctor()          …/MS/Internal/Generated/AvTraceMessages.cs:line 11
```

根因（**可证伪的断言**，不是推断）：

```console
$ dotnet test … --filter Registry_IsUnusable_OnLinux
Environment.OSVersion            : Unix 6.8.0.138
RuntimeInformation.OSDescription : Ubuntu 22.04.5 LTS
Registry.CurrentUser             : null          ← SecurityHelper.cs:215 的 OpenSubKey 就是在这里 NRE
```

Unix 上 `Microsoft.Win32.Registry.CurrentUser` 返回 **null**（不是抛异常），而
`SecurityHelper.ReadRegistryValue` 只判了 `OpenSubKey` 的返回值，没判 `baseRegistryKey` 本身。

### 1.2 处置：补丁 G（**生成式**，1 行改动）

新增在 `build/WindowsBase.Linux/reapply-patches.py` 里：

* 从上游**逐字读入** `Shared/MS/Internal/SecurityHelper.cs`；
* 在锚点 `RegistryKey key = baseRegistryKey.OpenSubKey(keyName);` 前插入
  `if (baseRegistryKey is null) { return null; }`（+6 行说明注释）；
* 写到 `build/WindowsBase.Linux/SecurityHelper.Linux.cs`（与本目录既有的生成物 `SR.g.cs` 同性质）；
* csproj 侧 `<Compile Remove>` 上游 + `<Compile Include>` 生成物；
* **锚点找不到 → 报错退出**，不静默产出一个没打补丁的副本。

实测 diff（生成物 vs 上游）：

```console
$ diff <(tail -n +22 build/WindowsBase.Linux/SecurityHelper.Linux.cs) \
       upstream/wpf/.../Shared/MS/Internal/SecurityHelper.cs
213,219d214
<             // ── WPF-on-Linux 补丁 G（由 build/WindowsBase.Linux/reapply-patches.py 插入）──
<             // Unix 上 Microsoft.Win32.Registry.CurrentUser 返回 **null**（不是抛异常），
<             // 而上游只判了 OpenSubKey 的返回值 → 这里会 NRE。实测链路：…
<             if (baseRegistryKey is null) { return null; }
```

**改动面 = 1 行代码**（其余 6 行是注释）。

### 1.3 语义论证（为什么这不是"放水"）

Linux 上**不存在** Windows 注册表 ⇒「读不到 = 未配置」是**真话**；调用方拿到 `null` 后走的
正是"WPF managed tracing 未启用"分支。**不丢日志**——因为 Linux 上根本不存在 managed tracing
的配置源（补充论证同补丁 F 的 ETW：无配置源 ≡ 上游在 Windows 上"没人配置过"的默认路径）。

**为什么用"生成"而不是"抄一份 229 行的 shim"**：抄一份的那一刻就与上游分叉了，上游改别的成员
我们不会知道；生成则在每次 `reapply-patches.py` 时从上游重读，锚点消失就直接报错。

### 1.4 改后（实测）

`HwndSource` 已经**越过了**这一条：`System.Windows.PresentationSource` 静态构造不再失败，
栈从 `TypeInitializationException` 直接推进到下一节的 `InputManager`（详见 §3）。
`dotnet test --filter HwndSource` 的证据文件里，异常链的第 1 层已经不是 `TypeInitializationException`。

---

## 2. 拦路虎 ② · `SystemParametersInfoW` 出参不填 —— 已修

### 2.1 改前

```c
// src/WpfGfx.Linux.Native/src/win32_misc.c（首版）
BOOL SystemParametersInfoW(UINT action, UINT param, void *data, UINT winIni)
{
    (void)action; (void)param; (void)winIni;
    if (data) { /* 调用方按自己的结构体解释；我们不写脏数据 */ }   // ← 空块
    return 1;
}
```

两处错：
1. 注释说"给系统默认值"，但**连清零都没做**——出参保持 `new NONCLIENTMETRICS()` 的全 0；
2. "0 是合理默认"对一部分 action 是**假话**：
   `lfMessageFont.lfWeight == 0` → `SystemFonts.MessageFontWeight`
   → `FontWeight.FromOpenTypeWeight(0)` → **`ArgumentOutOfRangeException`**；
   `SPI_GETWHEELSCROLLLINES == 0` → 滚轮每格滚 0 行。

### 2.2 改后：按 action 分派

新增结构体（`win32_abi.h`，全部 `_Static_assert` 逐字段钉死）：

| 结构体 | sizeof | 说明 |
|---|---|---|
| `LOGFONT` | **92** | `lfFaceName` 是 `[MarshalAs(ByValTStr, SizeConst=32)]` + **CharSet.Unicode** ⇒ 32 个 **UTF-16** 单元 = 64 B。lfHeight@0 / **lfWeight@16** / lfFaceName@28 |
| `NONCLIENTMETRICS` | **500** | lfCaptionFont@24 / lfSmCaptionFont@124 / lfMenuFont@224 / lfStatusFont@316 / **lfMessageFont@408** |
| `ICONMETRICS` | **108** | lfFont@16 |
| `HIGHCONTRAST_I` | 16 | |
| `ANIMATIONINFO` | 8 | |

> ⚠️ 同一个工程里 `LOGFONT.lfFaceName`（ByValTStr + Unicode → 64 B）与
> `MONITORINFOEX.szDevice`（ByValArray + Auto → Unix 上 32 B）**编码规则不同**，
> 只能逐个核对，不能类推。两条都已用跨边界断言钉住。

实现要点（`win32_misc.c`）：四条设计原则，逐条可检验——

| 原则 | 落地 |
|---|---|
| **A. 能不写就不写** | 未枚举的 action → 返回 TRUE 但**不碰出参**（不写脏数据） |
| **B. 必须写的写对** | WPF 真的会读的 action 全部显式列出（来源：`SystemParameters.cs` 的调用点，共 50+ 个） |
| **C. 值要么是真话、要么是自洽默认** | 见下表 |
| **D. 可覆盖** | `WPF_LINUX_UI_FONT`（默认 `DejaVu Sans`）/ `WPF_LINUX_UI_FONT_SIZE`（默认 12） |

写入的值（实测输出，逐条可见）：

```console
lfMessageFont: lfHeight=-12 lfWeight=400 lfFaceName="DejaVu Sans"
ICONMETRICS.lfFont: lfHeight=-12 lfWeight=400 face="DejaVu Sans"
WorkArea = (0,0)-(1280,1024)          ← Xvfb :99，无 WM ⇒ 工作区 == 整屏（真话）
WheelScrollLines   action=0x0068 → 3   ← ★ 0 会让滚轮滚不动
MouseHoverTime     action=0x0066 → 400
FocusBorderWidth   action=0x200e → 1
FocusBorderHeight  action=0x2010 → 1
CaretWidth         action=0x2006 → 1
FontSmoothing      action=0x004a → 1
KeyboardCues       action=0x100a → 1   ← ★ 无障碍开关，给 TRUE
```

**自洽性论证**（哪一类给 0、哪一类给非 0）：

| 类别 | 值 | 理由 |
|---|---|---|
| `UIEffects` 及全部"特效"子开关（菜单动画/淡入/阴影/热点跟踪/光标阴影…共 17 个） | **FALSE** | X11 无合成器、本后端不实现这些视觉特效 ⇒ `FALSE` 是**真话**；且与总闸 `UIEffects=FALSE` **自洽** |
| `KeyboardCues` | **TRUE** | 这是**无障碍**设置而不是"特效"：FALSE = 只有按 Alt 才显示快捷键下划线，属于可观察的功能退化 |
| `DragFullWindows` | TRUE | 非特效，Windows 常规默认 |
| 尺寸/数量类（边框/插入符/悬停/滚动行数/闪烁次数） | 1 / 3 / 4 / 400 / 31 | 这些位置上的 0 没有意义（0 像素边框、0 行滚动…） |
| 字体平滑组 | TRUE / 2(清晰类型) / 1200 | 我们的字体引擎是 M1 的 Skia 栈，走亚像素抗锯齿 |
| 未枚举 action | 不写出参、返回 TRUE | 与首版行为一致（**不引入新风险**） |

### 2.3 一个刻意"返回失败"的例外

`SPI_GETICONTITLELOGFONT` 返回 **FALSE**。理由：上游 `UnsafeNativeMethods` 里**没有**任何
`ref LOGFONT` 重载（实测 grep：只有 `ref RECT` / `ref int` / `ref bool` / `ref HIGHCONTRAST_I` /
`[In,Out] NONCLIENTMETRICS` / `ANIMATIONINFO` / `ICONMETRICS`），所以这个 action 目前**不可达**；
它也没有 `cbSize` 可以夹住写入长度。万一将来有人补上重载再调它，我们要的是**响亮的
`Win32Exception`**，而不是"写 92 字节进一个不知道多大的缓冲"或者"悄悄留一堆 0"。

### 2.4 边界保护

结构化 action 一律**按调用方给的 `cbSize` 夹住写入长度**，不够就返回失败：

```csharp
[Fact] GetNonClientMetrics_RejectsTooSmallBuffer   // cbSize=64 → 返回 FALSE，且出参未被写脏
```

---

## 3. ★ 独立发现的第 3 条拦路虎 · `InputManager` 的硬 STA 检查（**不在可写边界内**）

修完 ① 之后 `HwndSource` 并**没有**通——它推进到了更深的一层，撞上一条**同级**的
"Linux 上恒真"的 Windows 假设。这一条任务书没提，是本轮实测挖出来的。

### 3.1 根因（三段，全部实测）

**段 1：Linux 上没有任何线程能报告 STA。**

```
主线程 GetApartmentState()          = Unknown
SetApartmentState(STA) 是否被接受    = False（抛 PlatformNotSupportedException）
新建线程 GetApartmentState()        = Unknown
```

（断言在 `ApartmentState_NeverReportsSTA_OnLinux`，证据落盘 `artifacts/m7b-apartment-state.txt`。
这条断言是**可证伪**的：哪天运行时支持了 STA，它会红，提醒换修法。）

**段 2：`InputManager` 硬检查，无开关可绕。**

`PresentationCore/System/Windows/Input/InputManager.cs:144`（私有构造函数）：
```csharp
if(Thread.CurrentThread.GetApartmentState() != ApartmentState.STA)
    throw new InvalidOperationException(SR.RequiresSTA);
```

**段 3：`HwndSource` 无条件走到它。**

`HwndSource.Initialize`（`HwndSource.cs:212/213`）**无条件**创建两个输入提供器：
```csharp
_mouse    = new HwndMouseInputProvider(this);     // 构造函数第一句：InputManager.Current (HwndMouseInputProvider.cs:21)
_keyboard = new HwndKeyboardInputProvider(this);  // 构造函数第一句：InputManager.Current (HwndKeyboardInputProvider.cs:18)
```

⇒ **`HwndSource` 在 Linux 上永远构造不出来。** 实测栈（`artifacts/m7b-hwndsource.txt`）：

```
InvalidOperationException: The calling thread must be STA, because many UI components require this.
  at System.Windows.Input.InputManager..ctor()               InputManager.cs:144
  at System.Windows.Input.InputManager.GetCurrentInputManagerImpl()  InputManager.cs:128
  at System.Windows.Input.InputManager.get_Current()          InputManager.cs:35
  at System.Windows.Interop.HwndMouseInputProvider..ctor(HwndSource source)  HwndMouseInputProvider.cs:21
  at System.Windows.Interop.HwndSource.Initialize(HwndSourceParameters parameters)  HwndSource.cs:212
  at System.Windows.Interop.HwndSource..ctor(HwndSourceParameters parameters)       HwndSource.cs:203
```

### 3.2 修法：1 行

```diff
- if(Thread.CurrentThread.GetApartmentState() != ApartmentState.STA)
+ if(OperatingSystem.IsWindows() &&
+    Thread.CurrentThread.GetApartmentState() != ApartmentState.STA)
      throw new InvalidOperationException(SR.RequiresSTA);
```

**语义论证**：这条检查的**理由写在它自己的注释里**——
> "Avalon doesn't necessarily require STA, but many components do.
>  Examples include Cicero, OLE, COM, etc."

TSF/Cicero、OLE、COM apartment 这三样在 Linux 上**都不存在**：
TSF 走 `TextServicesLoader` 的"无 TSF"分支（本工程已按此处理）、OLE 剪贴板/DnD 已被 M4
裁决为 `PlatformNotSupportedException` 的最小诚实 stub、COM 在 Linux 上没有 apartment 概念。
所以在非 Windows 上跳过它**不是放水**，而是"这条前置条件在这里没有对象"。
`OperatingSystem.IsWindows()` 在 Linux 上恒 `false` ⇒ **完全不影响 Windows 语义**。

### 3.3 为什么我没有直接改 PresentationCore

任务书写的是「边界不变：可写 `build/WindowsBase.*`、`build/shims/WindowsBase.*`、
`src/WpfGfx.Linux.Native/`、`tests/.../ManagedLayer.Tests/`」，
`build/PresentationCore.Linux/` **不在可写清单里**（上一轮它在"不要碰"清单上，这轮"边界不变"）。
所以我**没有**动 PC 的 csproj，而是交付了**一键应用器**（用的就是补丁 G 那套生成式机制）：

```bash
# 只检查（不写任何文件）
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py --check
#   [检查] build/PresentationCore.Linux/InputManager.Linux.cs：缺失/与上游不同步（需要重新生成）
#   [接线] csproj **未接线** —— 需要运行一次不带 --check 的本脚本

# 应用（幂等；锚点找不到会报错退出，不静默降级）
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1
```

脚本做两件事：
1. 从上游**逐字读入** `InputManager.cs`，插入 `OperatingSystem.IsWindows() &&`，
   写到 `build/PresentationCore.Linux/InputManager.Linux.cs`（与 `SR.g.cs` 同性质的生成物）；
2. 在 PC 的 csproj 里注入 **2 行**（`<Compile Remove>` 上游 + `<Compile Include>` 生成物），
   带 `<!-- 补丁 H -->` 标记，便于识别与回滚。

**幂等 / 回滚**：重复运行 0 改动；回滚 = 删掉那 3 行并删除生成物（或重跑
`port-lib.py PresentationCore` 后不再跑本脚本）。
`port-lib.py` 重生成 csproj 之后需要**重跑本脚本**恢复（与补丁 F/G 的约定一致）。

### 3.4 应用后的预期（已把测试写成"自动切换"）

`HwndSource_Characterization_OnLinux` 现有两个分支：
* **构造失败** → 断言失败原因**恰好是已登记的那一条**（STA 检查，或原生面缺失）；
  换成别的异常（例如又一次 `NullReferenceException`）用例会红。
* **构造成功** → 断言真实 X11 窗口（`xwininfo` 的 Width/Height/Name/IsViewable）。
  ⇒ 应用补丁 H 之后**同一条用例自动升级**成强断言，不需要改测试。

---

## 4. `SystemParametersInfo` 同类问题清单（任务书要求"顺带检查"）

### 4.1 同一个 `SystemParametersInfo` 入口里，还有没有"出参不填"？

**有，已一并修掉。** 全量清点：

| 类别 | 条数 | 修前 | 修后 |
|---|---|---|---|
| 结构化查询（NONCLIENTMETRICS / ICONMETRICS / WORKAREA / HIGHCONTRAST / ANIMATIONINFO） | 5 | **全不填**（`lfWeight=0` 致命） | 全部填写 + `cbSize` 夹取 |
| 标量查询（FocusBorder / Caret / KeyboardSpeed/Delay / MouseHover* / MouseSpeed / MenuShowDelay / **WheelScrollLines** / FlashCount / Border / DefaultInputLang） | 14 | 全不填（0） | 全部给合理值（0 无意义的那批 ≥1） |
| 布尔查询（17 个特效开关 + KeyboardCues + DragFullWindows + 4 个杂项） | 23 | 全不填（0） | 全部显式写入（特效类 0、无障碍类 1） |
| 字体平滑（3 个） | 3 | 全不填（0） | 1 / 2(清晰类型) / 1200 |
| `SPI_GETICONTITLELOGFONT` | 1 | 不填 | **返回 FALSE**（无对应重载、无可夹的长度；宁可响亮失败） |
| 写入类（`SPI_SET*`）与未枚举 action | — | 返回 TRUE、无副作用 | **不变**（返回 TRUE、无副作用） |

### 4.2 `GetSystemMetrics` 有没有同样的问题？

**没有"出参不填"的问题**——它按值返回。逐条核对了 WPF 真的会读的那些：

| SM_ | 我的返回值 | 判定 |
|---|---|---|
| `CXSCREEN/CYSCREEN/CXVIRTUALSCREEN/CYVIRTUALSCREEN` | 真读 `DisplayWidth/Height`（1280×1024） | ✅ 真值 |
| `XVIRTUALSCREEN/YVIRTUALSCREEN` | 0 | ✅ 真值（虚拟屏原点） |
| `CXICON/CYICON` (11/12) | 32 | ✅ |
| `CXSMICON/CYSMICON` (49/50) | 16 | ✅ |
| `CXDRAG/CYDRAG` (68/69) | 4 | ✅ |
| `MOUSEWHEELPRESENT` (75) | 1 | ✅ |
| `CMONITORS` (80) | 1 | ✅ |
| `CXSIZEFRAME/CYSIZEFRAME` (32/33) | 0 | ✅ **真话**：X11 下无 WM 装饰 ⇒ 调整边框真的是 0（与 `SM_CXPADDEDBORDER=0` 自洽） |
| `CYCAPTION` (4) | 0 | ✅ 真话：无 WM 标题栏 |
| `IMMENABLED` (82) / `TABLETPC` (86) / `SHOWSOUNDS` (70) / `PENWINDOWS` (41) / `REMOTECONTROL` (0x2001) / `SLOWMACHINE` (73) / `REMOTESESSION` (0x1000) / `SWAPBUTTON` (23) | 0 | ✅ 真话：这些能力在 Linux 上确实不存在/未启用 |

⇒ `GetSystemMetrics` **无需改动**，逐条登记在案。

---

## 5. ManagedLayer.Tests 数字

```console
$ export DISPLAY=:99        # Xvfb :99 1280x1024x24
$ dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj --no-build
已通过! - 失败: 0，通过: 28，已跳过: 0，总计: 28，持续时间: 1 s

$ (unset DISPLAY; dotnet test … --no-build)
已通过! - 失败: 0，通过: 20，已跳过: 8，总计: 28，持续时间: 173 ms
```

**19 → 28**，新增 9 条：

| 用例 | 断言 |
|---|---|
| `SpiStructLayout_Native_Matches_Managed` (Theory ×3) | `LOGFONT`/`NONCLIENTMETRICS`/`ICONMETRICS` 逐字段 offset：原生 vs `Marshal.OffsetOf` 全等 + sizeof 全等 |
| `GetNonClientMetrics_FillsMessageFont_WeightIsValid` | ★ **`lfWeight ∈ [100,999]` 且 ≠0**；`lfHeight ≠0` 且 ∈[6,72]；`lfFaceName` 非空且无替换字符；**5 个 LOGFONT 全部检查**；`cbSize` 回写正确 |
| `GetIconMetrics_FillsIconFont` | 同上（`SystemFonts.IconFontWeight` 走同一条 `FromOpenTypeWeight`） |
| `GetNonClientMetrics_RejectsTooSmallBuffer` | `cbSize=64` → 返回 FALSE 且**出参未被写脏**（不越界） |
| `ScalarQueries_ReturnUsableValues` | `WheelScrollLines≥1`、`MouseHoverTime≥1`、`FocusBorderWidth/Height≥1`、`CaretWidth≥1`、`FontSmoothing==1`、`KeyboardCues==1` |
| `GetWorkArea_ReturnsRealScreenSize` | 工作区 ≥ 320×240，实测 `(0,0)-(1280,1024)` |
| `ApartmentState_NeverReportsSTA_OnLinux` | ★ 根因断言：主线程/新线程都不是 STA，且 `SetApartmentState(STA)` 不被接受 |

既有 19 条**全部保持通过**（`HwndWrapper` 建真实 X11 窗口 + xdotool 注入事件那条也仍然绿）。

---

## 6. 本轮改动的文件

**新增**
```
src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py   拦路虎 ③ 的一键应用器（幂等，--check 只读）
tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/SystemParametersInfoTests.cs   （8 条用例）
docs/U2-M7b-patch-round-report.md                                    本报告
```

**修改**
```
build/WindowsBase.Linux/reapply-patches.py         + 补丁 G（生成器 + csproj 注入）
build/WindowsBase.Linux/SecurityHelper.Linux.cs    生成物（256 行 = 上游 + 1 行守卫）
build/WindowsBase.Linux/WindowsBase.Linux.csproj   + 补丁 G 块（Remove + Include）
build/shims/Win32ShimResolver.cs                   T1 的 MilCore 钩子加 #if PRESENTATION_CORE 守卫
src/WpfGfx.Linux.Native/src/win32_abi.h            + LOGFONT/NONCLIENTMETRICS/ICONMETRICS/HIGHCONTRAST/ANIMATIONINFO + 断言
src/WpfGfx.Linux.Native/src/win32_internal.h       + SPI_* 常量表（48 个，取自上游 enum）
src/WpfGfx.Linux.Native/src/win32_misc.c           SystemParametersInfoW 真实现（按 action 分派）
src/WpfGfx.Linux.Native/src/win32_exports.c        ABI 探针 + LOGFONT/NONCLIENTMETRICS/ICONMETRICS
src/WpfGfx.Linux.Native/tests/abi_layout.c         + 上述结构体的逐字段打印
tests/.../ManagedLayer.Tests/LinuxEnvironmentDiagnosticsTests.cs  + ApartmentState 根因探针
tests/.../ManagedLayer.Tests/ManagedWindowTests.cs   HwndSource 特征化测试：断言"恰好是已登记的那条"
```

### 6.1 ⚠️ 顺手修掉的一个**跨 agent 集成缺陷**（T1 的钩子会让 WindowsBase 编译不过）

`Win32ShimResolver.cs` 是**一个源文件编进两个程序集**。T1 往里面加了：
```csharp
if (WpfGfx.Linux.Bridge.MilCoreDllImportResolver.TryResolve(libraryName, out nint milCore))
    return milCore;
```
但实测：**WindowsBase 的编译集合里 `[DllImport(DllImport.MilCore)]` 是 0 条**（104 条全在
PresentationCore），且 WindowsBase 没有引用 `WpfGfx.Linux.dll`（`MilBridge.Resolver` 只加进了
`PresentationCore.shims.txt`）⇒ WindowsBase 直接 **`CS0103: 当前上下文中不存在名称"WpfGfx"`**。

处置：给这段加 `#if PRESENTATION_CORE` 守卫（并在 `#else` 里写清理由）。
**这是"一个源文件编进两个程序集"这个设计要付的税**——共享的部分必须对两个程序集都成立；
只对其中一个成立的部分要么用 `DefineConstants` 隔开，要么就得拆文件。
修复后两个工程都 **0 错 0 警**。

---

## 7. 剩余缺口（按"挡不挡 HelloWpf"排序）

| # | 缺口 | 挡什么 | 量级 | 位置 / 谁来做 |
|---|---|---|---|---|
| 1 | **`InputManager` 硬 STA 检查** | 挡 **`HwndSource` 的一切**（⇒ 任何 WPF 窗口） | **1 行**，应用器已就绪 | `PresentationCore/…/Input/InputManager.cs:144`；`tools/patch-presentationcore-apartment.py`（**边界外，待授权**） |
| 2 | MIL 原生符号面（108 导出） | 挡一切**绘制** | 中 | T1 已桥接、主控已接 PC 侧；本轮未验证渲染 |
| 3 | WIC（109 条）→ Skia 映射 | 挡图像解码/编码 | 中 | M7c+ |
| 4 | LineServices（`Lo*`） | 挡最优段落排版 | 大 | M1 Skia 文本栈 |
| 5 | `PresentationNative_cor3.dll` 非 Wrapper 入口 | 同 #4 | — | 同 #4 |
| 6 | `MessageBox` 降级（不阻塞、直接返回 IDOK） | 不挡功能；只影响错误对话框的交互 | — | 已登记（M7b） |
| 7 | 多 UI 线程 / 跨线程 `SendMessage` | 单 UI 线程的 HelloWpf 不受影响 | 小 | `win32_msg.c` |

**建议的下一步**：授权我把补丁 H 应用到 PresentationCore（一条命令 + 一次 PC 增量构建 ≈ 1 分钟），
然后让 T3 重跑 HelloWpf —— 届时的拦路虎应该只剩 MIL 渲染接线（#2）。

---

## 8. 复现命令

```bash
cd <repo>; export PATH="$HOME/.dotnet:$PATH"
tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh start
export DISPLAY=:99

# 补丁 G（WindowsBase）
python3 build/WindowsBase.Linux/reapply-patches.py
dotnet build build/WindowsBase.Linux/WindowsBase.Linux.csproj -m:1          # 0 错 0 警

# 原生 shim（拦路虎 ②）
src/WpfGfx.Linux.Native/build-shim.sh --abi
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1 # 0 错 0 警

# 门禁
dotnet build tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj -m:1
dotnet test  tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj --no-build
cat tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/bin/Debug/net10.0/artifacts/*.txt

# 拦路虎 ③（可选，会改 build/PresentationCore.Linux/ —— 本轮**未应用**）
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py --check
```

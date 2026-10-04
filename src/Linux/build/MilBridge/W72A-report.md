# W72A 侦察报告（`TASK-0601` / 路线 R6「辅助功能与输入法」）

lane=W72A ｜ 性质=**只读侦察**（零 `dotnet`、零应用、零重活；对文件系统的写**只有本报告一处**）｜
对象 = 本仓 `UIAutomationTypes` / `UIAutomationProvider` 两个工程壳、UIA 的入口链、IME 的原生侧落点。

**一句话结论**：主控的"有壳无路"倾向**既不是被简单证实、也不是被推翻，而是被细化成两条更准确、可下结论的命题** ——
①**有路无门**（provider 树是**上游真实现的逐字编译**，但本仓**没有任何生产者**会发出 `WM_GETOBJECT` ⇒ 整棵树**静态不可达**）；
②**门后是断头**（真要有门，9 条 provider `[DllImport("UIAutomationCore.dll")]` 会抛 `DllNotFoundException`）。
IME 侧：**原生侧一处落点都没有**，托管侧被**三重独立门**关掉，其中只有两重是"决定"，第三重是 shim 的 `default: return 0` 巧合。

---

## §0 判据（**先写**）

> 本件是纯静态侦察：**没有**运行时读数（禁 `dotnet`、禁跑应用）。因此每条判定都显式标注
> **静态**或 **NOINFO**。**静态不可达 ≠ 实测不可达**，本报告一律不把前者写成后者。

- **C1「真实现 / 空壳 / 转发」三态判定**
  **真实现** ⟺ 该类型由本仓 `build/<X>.Linux/<X>.Linux.csproj` 以 `<Compile Include="$(UpstreamWpfRoot)…">` 直接编入，
  **且**跨平台那道缝（P/Invoke）在仓内能指名到具体 `[DllImport]` 行。**转发** ⟺ 类型名由 `TypeForwardedTo`
  或另一工程的 `Compile Include` 提供。**空壳** ⟺ 类型体存在但成员表为空 / 方法体不含语义（必须给空体原文 file:line）。
  *边界*：「上游源码本字未改地编进来」记**真实现**，即使它调的缝在 Linux 上断了——「断头」是 C2 的结论，不是 C1 的。
- **C2「路通不通」两把独立的锁**
  算**通** ⟺ (a) **有门**：存在一个**仓内可达的生产者**会触发它（UIA：会发 `WM_GETOBJECT` 的代码；IME：会把按键交给输入法引擎的代码）；
  **且** (b) **没断头**：该路径上全部 `[DllImport]` 的库名在 `build/shims/Win32ShimResolver.cs` 的
  `MappedLibraries`/`WicMappedLibraries` 里，或该库在系统上可解析。
  缺 (a) ⇒ **无门**；缺 (b) ⇒ **断头**；两者都缺 ⇒ **有壳无路（双重）**。
- **C3「不可达」判定**
  一条 `[DllImport]` 算**静态不可达** ⟺ **全部**调用点都落在一个静态恒假谓词内，或调用者本身不可达；
  恒假谓词必须给**取值链**（例：`GetSystemMetrics(82)` → shim `default: return 0`）。
- **C4 正对照**：任何「N 命中」附同一条 grep 在必有命中的靶上非零；任何「0 命中」附一个非零的同类对照。
- **C5 NOINFO**：必须跑应用才能判的 ⇒ `NOINFO ＋ 复算配方`。
- **C6 只读边界**：除本文件外不改任何文件；不碰四个路由件与 `build/MilBridge/tools/defect-registry-declared.tsv`；不 `pkill -f`。
- **C7 结论格式**：`artifact ＋ 字段 ＋ sha16`；sha 现场算、不手抄。

---

## §1 问题一：**谁来问**？

### 1.1 上游 WPF 自身 —— 四道门，全部要"外部先说话"

| # | 门 | 生产者（谁来发） | 关键 file:line（本仓可编译集） | 今天的状态 |
|---|---|---|---|---|
| A | `WM_GETOBJECT` → 顶层 peer | **Windows 的 UIA 核心 / MSAA 客户端**（跨进程 `SendMessage`） | `build/PresentationCore.Linux/HwndTarget.Linux.cs:1138` `case WindowMessage.WM_GETOBJECT:` → `:1139` `CriticalHandleWMGetobject` → `:1484` `AutomationInteropProvider.ReturnRawElementProvider(...)`；`HwndHost.cs:605-607` → `:623-632` | **无门**（见 1.1.1） |
| B | `AutomationPeer.ListenerExists(...)` 静态门 | **框架自己**（控件状态变化时） | 45 处（PC+PF，`--include='*.cs'`，排除 `ref/` 与定义行）。样例：`Button.cs:249-252`、`RepeatButton.cs:195-199`、`ListBox.cs:291-296`、`MenuBase.cs:300-303`、`DataGridColumnHeader.cs:745-748` | **关着**：`ListenerExists` = `EventMap.HasRegisteredEvent`（`AutomationPeer.cs:295-298`），表空时恒 `false` |
| C | 焦点变化 | `KeyboardDevice.cs:491` **无条件**调 `AutomationPeer.RaiseFocusChangedEventHelper` | `AutomationPeer.cs:390` `if (EventMap.HasRegisteredEvent(AutomationEvents.AutomationFocusChanged))` | **关着**（同 B） |
| D | 顶层 peer 挂到 LayoutManager | 根视觉变化 | `upstream/…/InterOp/HwndSource.cs:628-634` `… && MS.Internal.Automation.EventMap.HasListeners)`（= `build/PresentationCore.Linux/HwndSource.Linux.cs:1031-1042`） | **关着**：`HasListeners` ⟺ `_eventsTable != null`（`EventMap.cs:206-209`） |

**这张表的总开关是 `EventMap`。** 它的**唯一**填充口是
`ElementProxy.AdviseEventAdded`（`ElementProxy.cs:225-228` `EventMap.AddEvent(eventID);`），
而 `ElementProxy` 实现的是 `IRawElementProviderAdviseEvents`（`ElementProxy.cs:28`）——
**由 UIA 核心在客户端订阅事件时回调**（`EventMap.cs:220` 的注释自陈："…uiacore registers for automation events, calling EventMap.AddEvent"）。
Linux 上没有 UIA 核心 ⇒ `EventMap` 永远是空表 ⇒ B/C/D 三道门**静态恒关**，
`AutomationPeer.RaisePropertyChangedEvent`（`AutomationPeer.cs:334-339`，其第一句 `if (AutomationInteropProvider.ClientsAreListening)` 就是一条 P/Invoke）**不可达**。

peer 实例只能由 `CreatePeerForElement` 造出；**可编译集里共 75 处**（PC+PF，`--include='*.cs'`，排除 `ref/` 与三个 `public static … CreatePeerForElement` 定义行）。
其中：
- **根级调用点 20 处**（= 75 − 55）：其中 **3 处**在 `AutomationPeer.AutomationPeerFromInputElement` 内（`AutomationPeer.cs:412,419,426`，唯一调用者是 `RaiseFocusChangedEventHelper` ⇒ 门 C），
  其余 17 处是 `HwndTarget.cs:1410` 与 `HwndHost.cs:627`（门 A）、
  `RepeatButton.cs:197`／`DataGridColumnHeader.cs:747`／`MenuBase.cs:302`／`Button.cs:251`／`ToolTip.cs:168,541`／`GridViewColumnHeader.cs:795`／`ComboBox.cs:567`／`TabControl.cs:367`／`MenuItem.cs:1381`／`ListBox.cs:296`／`TreeView.cs:248,255`／`Hyperlink.cs:682`／`Popup.cs:3429`（门 B，已逐条读到 `ListenerExists` 块内或下面的门 E）。
- **其余 55 处都在 peer 类内部**（`UIElementAutomationPeer.GetChildrenCore`、`DataGridCellItemAutomationPeer`、`TextContainerHelper.GetEnclosingAutomationPeer`（`TextContainerHelper.cs:326`，其唯一调用者是 `TextRangeAdaptor.cs:1380` ⇒ 只在 provider 内）…）⇒ **只有"先有一个 peer"才可能到达**。

⚠️ **门 E（我单独列出，因为它不是 `ListenerExists`）**：`Popup.ForceMsaaToUiaBridge`（`Popup.cs:3425`，调用点 `:1555`）
被 `UnsafeNativeMethods.IsWinEventHookInstalled(EVENT_OBJECT_FOCUS|EVENT_OBJECT_STATECHANGE)` 门住（`Popup.cs:3427`），
而 shim 里这条是 `src/WpfGfx.Linux.Native/src/win32_misc.c:477` `BOOL IsWinEventHookInstalled(DWORD ev) { (void)ev; return 0; }` ⇒ **恒 false ⇒ 关着**。
同一处的 `SetWinEventHook` 是 `win32_misc.c:474-476`（`wpf_set_last_error(50); return NULL;`），注释在 `:469-473` 明说"**不伪造 hook**"。

#### 1.1.1 `WM_GETOBJECT` 有没有生产者？—— **没有**（这条是"无门"的硬证据）

```
$ grep -rn 'WM_GETOBJECT' build src --include='*.cs' --include='*.c' --include='*.h' --include='*.py' | grep -v /obj/ | grep -v /bin/
build/PresentationCore.Linux/HwndTarget.Linux.cs:1138:                case WindowMessage.WM_GETOBJECT:
```
⇒ 自有代码里 `WM_GETOBJECT` **只有 1 处**，是**消费者**（`case` 标签）。
**正对照**：同一批文件里 `AutomationPeer` = 36 命中（见 §1.3），说明 grep 本身有效。
**旁证**：native 侧合成的消息清单里没有它。
精确口径（可复算）：`win32_x11.c` 里出现的 `WM_*` **唯一名字共 40 个**，减去 **6 个 X11 原子**
（`WM_HINTS`/`WM_NAME`/`WM_CLASS`/`WM_DELETE_WINDOW`/`WM_NORMAL_HINTS`/`WM_PROTOCOLS`）与
**3 个 shim 内部标记**（`WM_SIZECODE_MAXIMIZED`/`_MINIMIZED`/`_RESTORED`）
⇒ **净 Win32 消息 31 条**，**不含 `WM_GETOBJECT`，也不含任何 `WM_IME_*`**。
命令：`grep -ohE '\bWM_[A-Z_0-9]+' src/WpfGfx.Linux.Native/src/win32_x11.c | sort -u | wc -l` = 40。
X11 的等价物（`ClientMessage`）没有"向他人查询无障碍对象"这个语义，所以**外部 AT 也没有别的路**递进来。

### 1.2 `hc-linux`（仓外 `/home/links-dev/hc-linux`）里有没有消费者？

| 探针 | 读数 | 命令 |
|---|---|---|
| 两个 UIA 程序集被**引用** | **有** | `WpfLinux.props:47` `<Reference Include="UIAutomationTypes">`、`:51` `<Reference Include="UIAutomationProvider">` |
| `AutomationProperties.AutomationId`（**设置侧**） | **24 处**，落 3 个 XAML | `src/Shared/HandyControl_Shared/Themes/Theme.xaml`(8)、`…/Styles/Base/ScrollViewerBaseStyle.xaml`(8)、`src/Net_40/HandyControl_Net_40/Themes/Theme.xaml`(8) |
| `AutomationPeer` / `OnCreateAutomationPeer`（**提供侧**） | **0** | `grep -rn --include='*.cs' -E 'AutomationPeer\|OnCreateAutomationPeer' src/Shared src/Net_40 \| wc -l` = 0 |
| 非 `obj/` 的 `using System.Windows.Automation` | **0** | 同口径；`obj/` 下 138（**生成**的 `*.g.cs`，由上面 24 处 XAML 派生） |
| `HwndHost` / `WindowsFormsHost` / `WebBrowser` | **0** | 这三者本是门 A 的宿主 |
| `InputMethod` / `ImeMode`（WPF 侧） | **0** | `grep -rnE '\bInputMethod\b\|\bImeMode\b' --include='*.cs' --include='*.xaml' src/Shared src/Net_40 \| wc -l` = 0 |

**正对照**：`using System.Windows` 389 文件、`TextBox` 30 文件 ⇒ hc 的 WPF 面确实被 grep 到了。
⇒ **结论：本仓无法从应用侧证伪/证实。** hc **只"设置"UIA 附属属性**（`AutomationId` 是 PresentationCore 里一个真 DP），
**从不"提供" provider**（无 `OnCreateAutomationPeer` 覆写、无 peer 用法），**也不消费 client**（不引 `UIAutomationClient`、无 `AutomationElement`）。
所以"AT 能不能看到 hc 的控件"这件事，**在 hc 里根本没有可观测的断言点**；能观测它的只有"外部 AT 进程连上来"。

### 1.3 仓内样本

| 样本 | `.cs` 命中 | 说明 |
|---|---|---|
| `samples/WpfFeatureProbe` / `HelloWpf` / `ThirdPartyMini` / `HelloMil` | **0** | 复算主控的起点读数 |
| `samples/WpfTextDemo` | **4**，全是**注释/文档** | `MainWindow.xaml.cs:101,379,402-406`（陈述 D1/D2 缺陷史）＋ `:414-419` 的 `catch`（大声登记而不是吞）**没有** `AutomationPeer` 的调用代码 |

**正对照**：`grep -rn --include='*.cs' AutomationPeer --exclude-dir=upstream --exclude-dir=obj --exclude-dir=bin .` = **36**（分布：`build/PresentationFramework.Linux/SR.g.cs` 12、`build/PresentationCore.Linux/HwndTarget.Linux.cs` 8、`samples/WpfTextDemo/MainWindow.xaml.cs` 4、`build/PresentationFramework.Linux/TextBox.Linux.cs` 4、…）。
⇒ **仓内（应用侧）没有 UIA 消费者**；仅有的 1 处**生产性**接线是 `build/PresentationCore.Linux/HwndSource.Linux.cs:1041 _hwndTarget.EnsureAutomationPeer(value);`，它在 `EventMap.HasListeners` 门内（见 1.1 门 D）。

---

## §2 问题二：**路通不通**（真实现 / 转发 / 空壳 / 断头）

### 2.1 编译面：**不是空壳**，是"上游真源码 + 极少量本仓替换件"

| 工程 | `Compile Include` 总数 | 其中指向上游 | `Compile Remove` | 本仓自有 `.cs` |
|---|---|---|---|---|
| `UIAutomationTypes.Linux` | 66 | 63 | **1**（把上游 `UiaCoreTypesApi.cs` 换掉） | `SR.g.cs`(61 行) + `UiaCoreTypesApi.Linux.cs`(143 行)；另编入 `build/shims/Win32ShimResolver.cs`、`build/shims/Accessibility.Shim.cs`、`build/shims/LinuxAssemblyIdentity.cs` |
| `UIAutomationProvider.Linux` | 33 | 31 | 0 | `SR.g.cs`(22 行)；另编入 `Win32ShimResolver.cs`、`LinuxAssemblyIdentity.cs` |

`Compile Remove` 的那一行就是全部"改写面"：`UIAutomationTypes.Linux.csproj:111-112`
```xml
<Compile Remove="$(UpstreamWpfRoot)…/MS/Internal/Automation/UiaCoreTypesApi.cs" />
<Compile Include="$(WpfLinuxRoot)build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs" />
```
`UiaCoreTypesApi.Linux.cs` 自陈（`:3-12`）：内容 = 上游**逐字复制** + **D2** 的**两处短路**
（`UiaGetReservedNotSupportedValue` / `UiaGetReservedMixedAttributeValue` → 进程内哨兵），
理由 = `[MarshalAs(UnmanagedType.IUnknown)]` out 参数**在 Linux 上不可封送**（实测 `MarshalDirectiveException`）；
文件自己写了 **"⚠️ 这是降级、不是对齐：跨进程/跨 COM 的身份语义不存在。"**（`:11`）。

### 2.2 产物面（元数据存在性；`grep -a` 子串口径）

| 名字 | `UIAutomationProvider.dll` | `UIAutomationTypes.dll` | `PresentationCore.dll` | `PresentationFramework.dll` |
|---|---|---|---|---|
| `UiaReturnRawElementProvider` | **1** | 0 | 0 | 0 |
| `UiaClientsAreListening` | **1** | 0 | 0 | 0 |
| `UiaRaiseAutomationEvent` | **1** | 0 | 0 | 0 |
| `AutomationIdentifierConstants` | 0 | **1** | 0 | 0 |
| `TextPatternIdentifiers` | 0 | **1** | 1 | 1 |
| `IRawElementProviderSimple` | **1** | **1** | 1 | 1 |
| `AutomationInteropProvider` | **1** | 0 | **1** | **1** |
| `ImmComposition` | 0 | 0 | 0 | **1** |
| **正对照（必须 0）** `ZzzNotATypeUIA` | 0 | 0 | 0 | 0 |
| **反面对照（必须非 0）** `ImmGetContext` | 0 | 0 | **1** | **1** |

产物 sha16：`UIAutomationProvider.dll` = **`76c3e977594876c9`**（43,520 B，2026-09-19 11:11:02）、
`UIAutomationTypes.dll` = **`2654da315acd2046`**（229,888 B，2026-09-19 11:10:54）。
⇒ **类型与 P/Invoke 入口名都在产物里**，不是空类型。

### 2.3 唯一的"转发"和唯一的"空壳"

- **转发（无害、有意的）**：`upstream/…/UIAutomationProvider/Forwards.cs:11-13` 三条 `[assembly: TypeForwardedTo(typeof(...))]`
  把 `IRawElementProviderSimple` / `ITextRangeProvider` / `ProviderOptions` **转发到 `UIAutomationTypes`**（真实现所在）。
  这是 .NET 的**类型身份**机制，**不是**"转到别人的头上当替身"。**除这 3 条外，两个工程里没有别的前转。**
- **空壳（真的空壳，只有一处）**：`build/shims/Accessibility.Shim.cs:17-27`
  ```csharp
  [ComImport] [Guid("618736E0-3C3D-11CF-810C-00AA00389B71")] [InterfaceType(InterfaceIsDual)]
  internal interface IAccessible
  {
  }
  ```
  **成员表为空**。文件自陈（`:8-14`）：只为"编译可见 + COM 标识正确"，"在真正调用任何 MSAA 方法之前，必须按 MSAA IDL 补齐成员表与 `[DispId]`"。

### 2.4 **断头**：9 条 provider P/Invoke 全部指向未映射的 `UIAutomationCore.dll`

`upstream/…/UIAutomationProvider/MS/Internal/Automation/UiaCoreProviderApi.cs`（全 148 行）里，`#region Raw API methods` 共 **9** 条：

| 行 | 导出 |
|---|---|
| `:112` | `UiaReturnRawElementProvider` |
| `:119` | `UiaHostProviderFromHwnd` |
| `:124` | `UiaRaiseAutomationPropertyChangedEvent` |
| `:127` | `UiaRaiseAutomationEvent` |
| `:130` | `UiaRaiseStructureChangedEvent` |
| `:133` | `UiaRaiseAsyncContentLoadedEvent` |
| `:136` | `UiaRaiseNotificationEvent` |
| `:140` | `UiaRaiseActiveTextPositionChangedEvent` |
| `:143` | `UiaClientsAreListening` |

四点读数（判据 C2(b)）：
1. 库名 = `UIAutomationCore.dll`（映射表在 `src/WpfGfx.Linux.Native/tools/extract-win32-inventory.py:49` `"DllImport.UIAutomationCore": "UIAutomationCore.dll"`）。
2. **不在映射表**：`grep -rn '"UIAutomationCore.dll"' build/shims/` = **0**。
   **正对照**（同一条 grep、同一目录）：`"user32.dll"` = 非 0（`Win32ShimResolver.cs:89`）；
   **同类 0**（说明不是我 grep 写错）：`"imm32.dll"` 也 = 0。
   `MappedLibraries` 全表（`Win32ShimResolver.cs:87-115`）只 11 个名字：`user32/gdi32/kernel32/PresentationNative_cor3/uxtheme/wtsapi32/shell32/ntdll/gdiplus/msimg32/dwmapi`；`WicMappedLibraries`（`:125-142`）2 个：`WindowsCodecs.dll/ole32.dll`。
3. **shim 里没有导出**：`nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | grep -c ' T Uia'` = **0**
   （`libwpfwin32.so` sha16 `c493639d15678803`，322,056 B，2026-09-21 12:31:05，总导出 **535**）。
   **正对照**：`grep -c ' T IsWindows10'` = **8**、`grep -c ' T IsWinEventHookInstalled'` = **1** ⇒ nm 口径有效。
4. **UIAutomationTypes 侧剩 1 条**：`UiaCoreTypesApi.Linux.cs:124` 的 `RawUiaLookupId`
   （另两条 `IUnknown` out 参数已在 `:127-133` 注释掉并保留原文备核）。
   我**复算**了既有的"零调用者"不变量：全仓（排除 `obj/bin`）`UiaLookupId` 的命中只有**定义处 4 行**（`UiaCoreTypesApi.Linux.cs:69,71,124,125`）+ 上游同名定义 + 检查器/测试/文档；
   **正对照**：`UiaGetReservedNotSupportedValue` = **26** 命中 ⇒ "0" 是真 0。

⇒ **"有壳无路"这个倾向的处置**：
它**不能**按字面成立（"壳"是假的——**类型是上游真实现**），也不宜笼统说"有路无门"。
本件的判词是**两条独立成立的结论**：
- **①有路无门**（静态）：provider 树完整、peer 可造、`ListenerExists` 门都在，但**没有任何生产者发 `WM_GETOBJECT`** ⇒ 门 A 永不触发；B/C/D/E 四道门又各自被 `EventMap` 空表/`IsWinEventHookInstalled=0` 关死 ⇒ **今天 AT 连不上、框架也不会自己去碰 UIA 核心**。
- **②门后是断头**（静态）：`AutomationInteropProvider` 的 9 条 P/Invoke **不是"零调用者"**——
  `UiaReturnRawElementProvider` 有 `HwndTarget.Linux.cs:1484`／`HwndHost.cs:632`／`Popup.cs:3435` 三个调用点，
  `UiaClientsAreListening` 有 `AutomationPeer.cs:335`。它们只是**静态不可达**。
  ⚠️ **这纠正了一处口径**：`docs/CURRENT-STATE.md:510` 的 `D-U1` 裁决建立在 **"零调用者 + 不可达"两条不变量**上，
  而那个"零调用者"**只对 `UiaLookupId` 成立**（我复算了，成立）；**对 provider 那 8 条同库导出不成立**。
  即：`UIAutomationCore.dll` 的"不加映射"这个决定，其**论据**在 provider 组上换成的是**"无门"**，不是"无调用者"。

---

## §3 问题三：**IME 面 —— 原生侧有没有落点？**

### 3.1 原生侧：**一处都没有**（命令 + 命中数）

| 探针 | 命中 | 正/反对照 |
|---|---|---|
| `grep -rnE '\bImmGetContext\b\|\bImmAssociateContext\b\|\bImmNotifyIME\b' src/WpfGfx.Linux.Native/src/` | **0** | — |
| `grep -rnoE '\bWM_IME_[A-Z_]*' src/WpfGfx.Linux.Native/src/*.c` | **1**，且是**名字不是实现** | `win32_msg.c:477 case 0x011F: return "WM_IME_SETCONTEXT";` —— 这是**消息名美化器**的 `switch`，全仓**没有**任何生产者会 push 这条消息 |
| `grep -rnE '\bXOpenIM\b\|\bXCreateIC\b\|\bXSetICFocus\b\|XFilterEvent\|Xutf8LookupString' src/WpfGfx.Linux.Native/src/` | **0** | 同一命令把 `XLookupString` 放进去 = **1**（`win32_x11.c:928`）⇒ grep 有效 |
| `grep -rn '"imm32.dll"' build/shims/` | **0** | 正对照 `"user32.dll"` 非 0 |
| `nm -D --defined-only libwpfwin32.so \| grep -c ' T Imm'` | **0** | 正对照 `IsWindows10*` = 8、总导出 535 |

**按键链的实际形态**（`src/WpfGfx.Linux.Native/src/win32_x11.c:918-975`）：
`XLookupKeysym(&ev.xkey,0)` → `keysym_to_vk()` → `WM_KEYDOWN`；
`XLookupString(&ev.xkey, chbuf, sizeof(chbuf), &ksChar, NULL)` → `WM_CHAR`（`:928`，`:970` push）。
`XLookupString` **第 5 个参数（XIC）传的是 `NULL`** ⇒ 它只做**核心协议**的死键合成，**不咨询任何输入法引擎**。
⇒ 组合串、候选窗、预编辑（preedit）**在本移植里没有任何落点**；能拿到的只有 keysym 直译出的单字符。
代码里的自陈口径是（`:954-958`）：`"用 XLookupString 而不是裸 keysym（旧版丢 Shift）"`、`"XLookupString 未给出单字符（死键/组合/非打印键）"` ⇒ 明确把"组合"归到**不产字符**那一支。

### 3.2 托管侧：**三重门，逐条给取值链**

**门 1 —— TSF/CTF（Cicero）显式关闭**（`build/WindowsBase.Linux/TextServicesLoader.Linux.cs`，sha16 `92c2ab584b4e48a0`）
- `:127-130`：`if (!System.OperatingSystem.IsWindows()) { return null; }`（注释自陈：Linux 无 `msctf`/`TF_CreateThreadMgr`，且**上游那条 STA 断言在 .NET on Unix 上不可满足** ⇒ 不关就是 `FailFast exit=134`）。
- `:247-251`：`RegistryKey hklm = Registry.LocalMachine; if (hklm == null) { return false; }`（补丁 M）。
⇒ `ServicesInstalled`（`:164-176` → `TIPsWantToRun()` `:223-256`）**恒 false**。
下游自动全关：`TextServicesManager.PreProcessInput`（`TextServicesManager.cs:118`）、`TextEditorTyping.Linux.cs:957`、`TextServicesCompartmentContext.cs:71-73`（`Current` 返回 `null`）。

**门 2 —— legacy IMM32 静态恒假**（取值链完整）
```
InputMethod.cs:1781   private static bool _immEnabled = SafeSystemMetrics.IsImmEnabled;
TextEditor.cs:2008    private static bool _immEnabled = SafeSystemMetrics.IsImmEnabled;
Shared/MS/Win32/SafeSystemMetrics.cs:99-106  →  UnsafeNativeMethods.GetSystemMetrics(SM.IMMENABLED) != 0
WindowsBase/MS/Internal/Interop/NativeValues.cs:521   IMMENABLED = 82
src/WpfGfx.Linux.Native/src/win32_core.c:1655-1683   int GetSystemMetrics(int nIndex) { … default: return 0; }
```
`82` 不在任何 `case` 里 ⇒ **返回 0 ⇒ `_immEnabled == false`** ⇒
`InputMethod.IsImm32ImeCurrent()`（`InputMethod.cs:1261-1269`：`if (!_immEnabled) return false;`）恒 false，
且**所有** `ImmGetContext` 调用点都在 `if (_immEnabled)` 里：
`InputMethod.cs:569, 817, 832, 907`；`ImmComposition.cs:189, 398, 565, 747, 1724`（PF 侧由 `TextEditor.cs:1682 if (_immEnabled)` 造出 `ImmComposition` 对象，`:1599/:1737` 另两处同理）。
⇒ **`imm32.dll` 的 18 条声明（`Shared/MS/Win32/UnsafeNativeMethodsCLR.cs:386-441`，覆盖 **14** 个唯一方法名：
`ImmGetContext`/`ImmReleaseContext`/`ImmAssociateContext`/`ImmSetConversionStatus`/`ImmGetConversionStatus`/
`ImmSetOpenStatus`/`ImmGetOpenStatus`/`ImmNotifyIME`/`ImmGetProperty`/`ImmGetCompositionString`(×4 重载)/
`ImmConfigureIME`(×2 重载)/`ImmSetCompositionWindow`/`ImmSetCandidateWindow`/`ImmGetDefaultIMEWnd`）今天全部静态不可达。**
（顺带：`SafeSystemMetrics.cs` 由 `PresentationCore.Linux.csproj:116` 编入 PC —— 也就是说**这一个 `default: return 0` 同时关掉了 PC 的 `InputMethod` 和 PF 的 `TextEditor`/`ImmComposition` 两侧。**）

**门 3 —— TSF 分支的兜底也返回 null**：`TextServicesCompartmentContext.cs:71-73`
（`if (!TextServicesLoader.ServicesInstalled || TextServicesContext.DispatcherCurrent == null) return null;`）
⇒ 即使有人硬设 `InputMethod.ImeState`（`InputMethod.cs:517-538` 走 TSF 分支），拿到的也是 `null` 分区 ⇒ **静默 no-op**。

### 3.3 IME 的判词

> **"键盘输入法"这条路在本移植里没有任何落点**：原生侧 0 实现、0 映射、0 导出；
> 托管侧被三重门关死，其中**门 1 是明确决定**（有理由、有文件、有注释）、
> **门 2 是 shim 的 `default: return 0` 巧合**（**没有任何代码或文档"决定"过它**，见 §4 空缺表第 7 行）、
> 门 3 是上游本来就有的 null 兜底。
> 后果：中日韩/越南语等**组合输入不可用**；能输入的只有 X11 能直译成单字符的键。
> ⚠️ 这是**静态**结论；"真按一个组合键会发生什么"需要跑应用 ⇒ `NOINFO`（§5）。

---

## §4 空缺表（12 条）

| # | 能力 | 现状 | 证据（file:line ＋ 读数） | 影响面（hc 里哪些控件会走它） |
|---|---|---|---|---|
| **1** | **UIA provider 的入口**（`WM_GETOBJECT` 生产者） | **无落点** | 自有代码 `WM_GETOBJECT` 只有 1 处且是消费者（`HwndTarget.Linux.cs:1138`）；native 合成消息 37 个 `WM_*` 里没有它；X11 无对应语义 | **全部**：hc 的任何控件都对 AT 不可见——但"不可见"在 hc 里**没有断言点**（§1.2） |
| **2** | **UIA 事件广播**（`SetWinEventHook`/`NotifyWinEvent`） | **空壳/no-op（已登记，非本件新发现）** | `win32_misc.c:469-477`：`NotifyWinEvent` 空体、`SetWinEventHook` 置 error 50 返 NULL、`IsWinEventHookInstalled` 恒 0；已登记于 `docs/U2-M7b-win32-inventory.md:415`、`docs/U2-M7b-report.md:468`、`extract-win32-inventory.py:423` | ScrollViewer/ScrollBar/ListBox/TabControl 等的"滚动到/选择变化"事件；hc 的 `ScrollViewer`、`TabControl`、`ListBox` 全走 |
| **3** | **9 条 provider P/Invoke 落点**（`UiaReturnRawElementProvider` 等） | **断头**（有调用者、库未映射、无导出） | `UiaCoreProviderApi.cs:112,119,124,127,130,133,136,140,143`；`"UIAutomationCore.dll"` 在 `build/shims/` 0 命中；`nm -D… ' T Uia'` = 0 | 门 A（`HwndTarget`/`HwndHost`/`Popup` 三条）**一旦**有门就命中；今天不可达 |
| **4** | **UIA client 侧**（`AutomationElement` 等） | **无落点** | `build/*.Linux` 无 `UIAutomationClient`（上游 `upstream/…/UIAutomation/UIAutomationClient/` 存在但无本仓工程）；`wpf-linux.sln` 8 个工程**一个 UIA 都没有**（`grep -cE '^Project\('` = 8） | hc 不用 client（0 命中）⇒ 影响面 = 将来任何"应用内自省/自动化测试" |
| **5** | **AT-SPI2 / D-Bus 桥**（Linux 无障碍的正路） | **无落点** | 仓内自有代码 `atspi\|dbus` 命中 = 0；只有两处**注释**说"Linux 上的等价物是 AT-SPI2 over D-Bus，属于独立里程碑"（`win32_misc.c:469-470`、`extract-win32-inventory.py:423`） | **全部控件**：Orca/Accerciser 等 Linux AT 只能通过 AT-SPI2 看应用 ⇒ 今天的可见性 = 0 |
| **6** | **X11 输入法（XIM）** | **无落点** | `XOpenIM/XCreateIC/XSetICFocus/XFilterEvent/Xutf8LookupString` = 0 命中；`XLookupString` 的 XIC 参数传 `NULL`（`win32_x11.c:928`） | hc 的 `TextBox`/`ComboBox`/`NumericUpDown`…（30 个文件含 `TextBox`）：**组合输入全不可用** |
| **7** | **legacy IMM32（`imm32.dll`）** | **断头 ＋ 静态不可达（双重门）** | **18** 条 `[DllImport(ExternDll.Imm32)]` / **14** 个唯一方法名，`UnsafeNativeMethodsCLR.cs:386-441`；`"imm32.dll"` 在 `build/shims/` 0 命中；`_immEnabled=false` 取值链见 §3.2 门 2 | 同上；⚠️**门 2 是巧合不是决定**（本表唯一的"没人决定过"的缺口） |
| **8** | **TSF / CTF（Cicero）** | **空壳（显式关闭，有理由）** | `TextServicesLoader.Linux.cs:127-130, 247-251`；`ServicesInstalled` 恒 false | 同上；`TextEditor` 的 overtype/TSF 路径（`TextEditorTyping.Linux.cs:957`） |
| **9** | **`WM_IME_*` 消息** | **无生产者** | 唯一命中是消息名美化器 `win32_msg.c:477` | 不适用（无消费者在跑） |
| **10** | **`InputMethod.PreferredImeState` / `ImeConversionMode` 等应用级 API** | **静默 no-op** | 分支走 TSF（`InputMethod.cs:517-528`）→ `TextServicesCompartmentContext.Current` 返回 `null`（`:71-73`） | hc 的 0 处使用（§1.2）⇒ 今天无影响；将来任何设 `InputMethod.PreferredImeState` 的应用会**以为设上了** |
| **11** | **MSAA `IAccessible`** | **空壳（成员表为空）** | `build/shims/Accessibility.Shim.cs:24-26` 空接口；只用于 `ObjectFromLresult` 的不透明声明 | 门 A 的 MSAA→UIA 桥（`Popup.cs:3425-3445`）——今天被门 E 关着 |
| **12** | **`UiaGetReserved*` 两个保留值** | **已降级落地（D2），不是空缺** | `UiaCoreTypesApi.Linux.cs:74-87` 短路成进程内哨兵；文件自陈"**降级不是对齐**"（`:11`） | 全局：`AutomationPeer..cctor`、`TextPatternIdentifiers..cctor`（WpfTextDemo 的 `exit 134` 史就是这里） |

**空缺表计数**：**12 条**，其中 **新发现 10 条**（#1、#3、#4、#5、#6、#7、#8、#9、#10、#11 —— #2/#12 已在册）。
**"无落点" 5 条**（#1、#4、#5、#6、#9）、**"空壳" 3 条**（#2、#8、#11）、**"断头" 2 条**（#3、#7）、**"静默 no-op" 1 条**（#10）、**"已降级" 1 条**（#12）。

---

## §5 要把它做成能用，**最小第一步**是什么（只写方案，不落地）

**先说不该做什么**：不要先落 `UIAutomationCore.dll` 的 9 条导出。理由：门 A 没有生产者，落了也没人调（且会把今天"诚实的 `DllNotFoundException`"糟蹋成"看得见却连着假数据"——这正是 `D1` 应用器注释里已经写下的那条判词）。

**建议的第一步（按成本升序，A 先做）**：

- **A. 把"无门"这件事变成**会变红**的仪器（~1 人日，零产品改动）**
  新增一个只读检查：断言"自有代码里 `WM_GETOBJECT` 的出现次数 == 1 且那一处是 `case` 标签"，
  **反极性牙** = 在 `src/` 或 `build/` 里造一处 `SendMessage(..., WM_GETOBJECT, ...)` 的突变副本 ⇒ 必须红并**点名**。
  同趟把 §3.2 门 2 的取值链也钉住：断言 `GetSystemMetrics(82) == 0`（用现成的 `Win32ShimResolver` 覆盖通道做两极化）。
  ⇒ 这一步的价值：今天"AT 看不见"是**没人量过的**，量了之后**任何一方**（新增门 / 误改 shim）都会立刻现形。
- **B. 决定门 2 的去留（半天，写文档即可）**
  `GetSystemMetrics` 的 `default: return 0` 同时关掉 `ImeState`/`ImmComposition` 两侧，**没有任何人在册决定过它**。
  建议**明确登记为"有意降级"**并写进 `docs/CURRENT-STATE.md`（而不是留成巧合）——因为将来任何"把 `SM_IMMENABLED` 补成 1"的善意改动，都会**同时**打开一条指向未映射 `imm32.dll` 的路。
- **C. AT 可见性的真路 = AT-SPI2 桥（~1 波，独立里程碑，需先立预登记）**
  最小可验证闭环：`HwndTarget` 侧把 `EnsureAutomationPeer`/`AutomationPeer` 树的**只读快照**（角色/名/边界/父子）导出给一个 **D-Bus 服务**，用 `dbus-send`/`accerciser` 从**外部进程**读一次。
  判据：外部读得到 hc 某个具名控件（例如 `AutomationId="VerticalScrollBar"`，hc 的 XAML 里现成 24 个）；反极性 = 把服务停掉 ⇒ 读不到。
  ⚠️ 这一步**不能**靠"补 `UIAutomationCore.dll` 导出"替代：UIA 是 COM/跨进程契约，AT-SPI2 是 D-Bus 契约，两者的客户端不通用。
- **D. IME 的最小可验证闭环（~1 波）**
  原生侧引入 `XOpenIM`/`XCreateIC`/`XFilterEvent`（XIM 协议），把 `XFilterEvent` 命中时的**预编辑串**作为一条新消息交给托管侧；判据 = 打一个组合键，能在 TextBox 里看到预编辑串 + 提交后成字。**今天连"把按键交给引擎"这一步都不存在**，所以 A/B 是 D 的前置。

---

## §6 读数表（纪律 32）

| 项 | 值 |
|---|---|
| lane | **W72A** |
| 开工时刻 | **2026-09-21 13:38:38 +0800** |
| 判定性读数时刻 | **2026-09-21 13:44:44 +0800** |
| `loadavg` | 0.53 / 0.53 / 0.33 →（判定 pass）**4.03 / 1.59 / 0.78** |
| `MemAvailable` | 3,290,236 kB → **3,397,736 kB**（MemTotal 8,113,356 kB） |
| kernel | `6.8.0-138-generic` |
| 本报告 sha16 | 见收尾消息（写完再算，不用手抄） |

| 被引用件 | sha16 | size | mtime |
|---|---|---|---|
| `build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs` | `23240b70aaddc2c9` | 6,204 B | 2026-09-11 16:54:45 |
| `build/UIAutomationTypes.Linux/UIAutomationTypes.Linux.csproj` | `cba4d8e076a19e9a` | 12,411 B | 2026-09-20 00:12:06 |
| `build/UIAutomationProvider.Linux/UIAutomationProvider.Linux.csproj` | `9f7a4c820328058c` | 7,734 B | 2026-09-20 00:12:05 |
| `build/UIAutomationTypes.Linux/bin/Debug/UIAutomationTypes.dll` | `2654da315acd2046` | 229,888 B | 2026-09-19 11:10:54 |
| `build/UIAutomationProvider.Linux/bin/Debug/UIAutomationProvider.dll` | `76c3e977594876c9` | 43,520 B | 2026-09-19 11:11:02 |
| `build/shims/Win32ShimResolver.cs` | `670d4e37592c3a64` | 35,815 B | 2026-09-19 01:52:25 |
| `build/shims/Accessibility.Shim.cs` | `28fb0e85318f343e` | 1,400 B | 2026-09-06 16:57:19 |
| `build/PresentationCore.Linux/HwndTarget.Linux.cs` | `309c5280207061e0` | 117,790 B | 2026-09-19 20:03:36 |
| `build/WindowsBase.Linux/TextServicesLoader.Linux.cs` | `92c2ab584b4e48a0` | 17,820 B | 2026-09-12 23:55:52 |
| `src/WpfGfx.Linux.Native/src/win32_misc.c` | `b09058febe5954e4` | 79,361 B | 2026-09-18 19:11:01 |
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `ba1d9ba959da163c` | 107,426 B | 2026-09-21 12:30:44 |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `050f349638bbf87e` | 91,594 B | 2026-09-21 00:23:21 |
| `src/WpfGfx.Linux.Native/src/win32_msg.c` | `cff3189eff6c87eb` | 54,315 B | 2026-09-14 18:36:59 |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `c493639d15678803` | 322,056 B | 2026-09-21 12:31:05 |
| `build/PresentationCore.Linux/PresentationCore.Linux.csproj` | `98d7cddb1eaa8f38` | 208,819 B | 2026-09-20 00:12:06 |
| `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` | `2c8e93b14561efcf` | 204,314 B | 2026-09-20 00:12:06 |

**本件对文件系统的写**：仓内只有 `build/MilBridge/W72A-report.md` 一个文件（先写 §0 判据，后补 §1–§7）。
仓外另有 **1 个 `/tmp` 中间文件** `/tmp/wm_all.txt`（数 `win32_x11.c` 的 `WM_*` 唯一名用），如实登记、不隐藏。
`git status`/`find -newermt` 未用于归属（本仓无 `.git`）；读者可用上表的 mtime 自行核对被引用件**全部早于**本报告 mtime。
**未跑**：`dotnet`（0 次）、任何应用/探针/harness、`verify-all.sh`、`close-wave.sh`、`tline-gate.sh`、`pkill`。

---

## §7 `NOINFO` 清单

1. **"AT 真连上来会怎样"** —— 必须有一个外部 UIA/AT 客户端 + 一条门 ⇒ 本件禁跑应用。
   *复算配方*：在 Windows 语义下这是 `WM_GETOBJECT`；Linux 上要复算得先造门（见 §5 C），或直接反射调 `UIAutomationProvider` 的 9 条入口之一（会得 `DllNotFoundException`——但那是 `D4` 牙的射程，不是"端到端"）。
2. **75 处 `CreatePeerForElement` 未逐条核完** —— 我逐条读了 20 处根级调用点里 5 个代表（`Button`/`RepeatButton`/`ListBox`/`MenuBase`/`DataGridColumnHeader`）+ 3 条 WM_GETOBJECT 驱动 + `Popup` 门 E，其余按"peer 内部 55 处"归类。
   *复算配方*：`grep -rn 'CreatePeerForElement' …/PresentationCore …/PresentationFramework --include='*.cs' | grep -v ref/ | grep -v 'public static AutomationPeer CreatePeerForElement' | nl` → 75 行；逐行向上读 `ListenerExists`。
   **若其中任何一处不在门内，结论 ①的要害不变（门 A 仍无生产者），但"框架自己不会碰 UIA 核心"这句就要收窄。**
3. **`EventMap` 是否有第三条填充路径** —— 我核到的 `AddEvent` 调用点只有 `ElementProxy.cs:227` 一处（`--include='*.cs'` 全上游）。
   *复算配方*：`grep -rn 'EventMap.AddEvent' upstream/wpf/src --include='*.cs'`。**未做**：反射式字符串用法（`GetMethod("AddEvent")`）搜索——按 `UiaLookupId` 的先例应做，本件未做。
4. **IME 的运行时行为**（按组合键的真实表现、`InputMethod.Current` 首访是否抛）—— 需跑应用。
   *复算配方*：跑 hc 或 `samples/WpfTextDemo`，用 `WPF_LINUX_KEY_DIAG`/`WPF_LINUX_INPUT_TRACE` 看 `DROP WM_CHAR 原因` 行（`win32_x11.c:958` 那支）会不会被"死键/组合键"打到。
5. **X11 XIM 是否真能装上**（`XOpenIM` 返 NULL 还是可用）—— 需跑一个 X 会话下的原生探针；本件是纯读。
6. **AT-SPI2 的可行性/成本** —— 本件只做"无落点"判定；真要估工需读 `at-spi2-core` 的 D-Bus IDL，超出本件范围。

---

## §8 大白话小结（≤6 行）

1. UIA 那两个工程**不是空壳**：里面装的是**上游 WPF 的自动化代码原样编进来**，只有 2 个保留值被本仓短路过。
2. 但**没人来敲门**——WPF 在 Windows 上靠系统发 `WM_GETOBJECT` 把无障碍树递出去，本移植**一行发这条消息的代码都没有**：37 种合成消息里没有它。
3. 门后面**还是断的**：真要敲门，会撞上 9 条指向 `UIAutomationCore.dll` 的调用，那个库在本仓**既没映射也没导出**（`nm` 里 Uia 符号 0 个）。
4. Linux 上看应用的无障碍正路本来是 **AT-SPI2 over D-Bus**，本仓**一处都没有**（只有两条注释提到它）。
5. 输入法更彻底：**原生侧一处落点都没有**（`XOpenIM`/`imm32`/`WM_IME_*` 全是 0），按键只经 `XLookupString` 直译成单字符，**打不了中文**。
6. 最该先做的一件事不是补实现，而是**先把"无门"这件事变成会变红的仪器**——今天"看不见"是没人量过的，量了才不会有人一不小心把它改成"看得见的假数据"。

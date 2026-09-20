# PresentationCore 编译可行性扫描报告（U2 决策数据包）

> 扫描对象：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore`（下称 SRC/PresentationCore）与 `SRC/Shared`。
> 上游目录全程只读，本报告是唯一产出物。所有数字可按下文「扫描方法与统计口径」复核。

## 一句话结论

**编译可行性高**：PresentationCore（1294 个 .cs、约 17.7 万行）的编译期障碍非常集中——`Windows.Win32` 缺口仅 3 个文件约 7–9 个类型（其中 4 个已由现有 263 行 shim 覆盖），骨架级三件套（HwndWrapper/HwndSubclass/ManagedWndProcTracker，共 1223 行、284 条 DllImport 声明）**已随 WindowsBase 里程碑 0 错误编译通过**，因此「shim 保编译」预计是**天~周级**工作（1–3 周，最大不确定项是 OLE 剪贴板栈 8 个文件的取舍）。真正的战场在**运行期**：消息泵/子类化语义、95 个缺失的 MIL 原生导出、WIC/OLE/DWrite 后端替换，属于**月级**（1–3 月）。两条路线的编译成本没有本质差别，差别在于运行期窗口架构何时被替换、以及是否接受「编译通过但行为错误」的中间态。

---

## 0. 扫描方法与统计口径

| 口径 | 命令 / 说明 |
|---|---|
| 文件数 | `find SRC/PresentationCore -name '*.cs' \| wc -l` → 1294（含 1 个 ref 文件，不含 obj/bin） |
| 总行数 | `find ... -name '*.cs' -not -path '*/ref/*' \| xargs wc -l` → **177,017 行** |
| Windows.Win32 使用 | `grep -rl 'Windows.Win32'`（SRC/PresentationCore + SRC/Shared），再逐文件 `grep -noE 'Windows\.Win32\.[A-Za-z0-9_.]+' \| sort \| uniq -c` 做成员级计数 |
| MS.Win32 引用 | `grep -rl 'MS\.Win32'`；类级分布用 `grep -rhoE 'MS\.Win32\.[A-Za-z0-9_]+' \| sort \| uniq -c`（出现次数）与 `grep -rl`（文件数）两种口径，本报告两者都给出 |
| DllImport 计数 | 「属性条数」口径：`grep -cE '^\s*\[DllImport'` 逐文件求和 = 267（in-tree）+ 41（Common/Graphics）= **308 条属性**（附注：`grep -rl 'DllImport'` 命中 18 文件，其中 3 个只是文本命中——GlobalUsings.cs 的 `global using DllImport = ...`、DWriteLoader.cs 的 `NativeLibrary.Load("dwrite.dll", ..., DllImportSearchPath.System32)`、NativeRecognizer.cs 的注释——真实属性在 15 个文件里）；Common/Graphics 的 41 条用 Python 正则跨行解析属性块得到 |
| DLL 归类 | `grep -rhoE '\[DllImport\([^,)]*' \| sed ... \| sort \| uniq -c`，常量定义查 `Shared/MS/Win32/ExternDll.cs` 与 `Shared/RefAssemblyAttrs.cs`（`MS.Internal.PresentationCore.DllImport` 类） |
| MIL 导出缺口 | 托管侧需求集 = 全部 `DllImport(DllImport.MilCore)` 的 `EntryPoint=` 名 ∪ extern 方法名（Python 正则跨行解析，去重）；M1 实现集 = `grep -rhoE 'public static ... Mil[A-Za-z0-9_]+' src/WpfGfx.Linux --include='*.cs'`；两者求交/差 |
| HWND 角色判定 | `grep -rl 'DUCE\.'`、`grep -rl 'UnsafeNativeMethods\.(SetWindowPos\|MoveWindow\|ShowWindow\|...)` 等按 API 名逐条统计引用文件数 |
| csproj 解析 | Python 解析 `<Compile Include>`（1357 条）、`ProjectReference`（8）、`PackageReference`（4）、`Compile Remove`（0）；编译列表与实际文件用 `casefold()` 归一后比对 |

所有 `wc`/`grep` 均为 2026-09 上游副本快照；关键命令索引见文末附录。

---

## 清单 1：`Windows.Win32.*` 缺口（成员级）

### 1.1 总览

| 项 | 数值 |
|---|---|
| SRC/PresentationCore 中引用 `Windows.Win32` 的文件 | **3**（见下表） |
| SRC/Shared 中引用 `Windows.Win32` 的文件 | **0** |
| 上游 CsWin32 生成面（全仓唯一宿主 `System.Windows.Primitives`） | `NativeMethods.txt` **23 行 API 面**（WIC 工厂、窗口注册/创建、DWM、图元文件、分层窗口等） |
| 现有 shim `build/shims/WindowsWin32.Shim.cs` | 263 行：`Foundation`{BOOL/HRESULT/HANDLE/HWND/HINSTANCE/HMENU/LRESULT/WPARAM/LPARAM} + `Graphics.Gdi`{HDC/HBITMAP/HENHMETAFILE/BLENDFUNCTION} + `PInvoke.DwmIsCompositionEnabled` |

### 1.2 逐文件成员缺口

| 文件（行数） | 用到的 Windows.Win32 成员 | shim 现状 | 新增形状 |
|---|---|---|---|
| `System/Windows/Ole/WpfOleServices.cs`（191） | `Foundation.HRESULT`（含 `S_OK`、**`DV_E_TYMED`**）、`Graphics.Gdi.HENHMETAFILE`、`Graphics.Gdi.HBITMAP`（含 **`.CreateCompatibleBitmap()` 扩展方法**）、**`PInvoke.SetEnhMetaFileBits()`**、`System.Ole` 命名空间（`FORMATETC*`/`STGMEDIUM*` 指针参数）、`System.Com.IDataObject` | HRESULT/HENHMETAFILE/HBITMAP 已覆盖；`DV_E_TYMED` 常量、2 个 PInvoke/扩展 API **缺失**；`System.Ole`/`System.Com` 类型**全缺** | 常量+句柄 = 易（各 1 行）；`FORMATETC`（6 字段结构体）/`STGMEDIUM`（union 结构体）= 中（blittable 可手写）；`IDataObject` = **COM 接口，难**（见下） |
| `System/Windows/dataobject.cs`（655） | `Foundation.HRESULT`、`Foundation.BOOL`、`System.Com.IDataObject`（**9 槽显式接口实现** + `Composition.Create()` 包装）、`Com.IManagedWrapper<Com.IDataObject>`、`Com.FORMATETC*`、`Com.STGMEDIUM*`、`Com.IAdviseSink*`、`Com.IEnumSTATDATA**`、`Com.IEnumFORMATETC**` | HRESULT/BOOL 已覆盖；**7 个 Com 类型全缺** | COM 接口组：`IDataObject` 9 方法 + IUnknown 3 槽 = 12 槽；`IAdviseSink`、两个 `IEnum*` 再各约 4 槽 → **合计约 20–25 个 vtbl 槽**，需 `[Guid]` 与 wincodec 式逐槽对齐。`IManagedWrapper<T>` 是 CsWin32 的 ComWrappers 标记接口（带 `unmanaged` 语义），SplashScreen 先例已证明其真实形态不可凭记忆推断 |
| `MS/internal/SystemDrawingHelper.cs`（72） | `Graphics.Gdi.HENHMETAFILE`、`Graphics.Gdi.HBITMAP`（仅句柄传递与 `IsNull`/`Null` 判定） | **全部已覆盖**（此文件 0 新增） | — |

### 1.3 缺口统计

| 分类 | 数量 | 明细 |
|---|---|---|
| 已覆盖类型 | 4 | HRESULT、BOOL、HBITMAP、HENHMETAFILE |
| 需新增类型 | **7–9** | `System.Com`：IDataObject、IManagedWrapper\<T\>、IAdviseSink、IEnumSTATDATA、IEnumFORMATETC、FORMATETC、STGMEDIUM；`System.Ole`：命名空间级引用（主要 type-forward 到同批结构体，另可能含 DVASPECT/CLIPFORMAT 枚举） |
| 需新增成员 | 3 | `HRESULT.DV_E_TYMED` 常量、`PInvoke.SetEnhMetaFileBits`、`HBITMAP.CreateCompatibleBitmap` 扩展方法 |
| 预计新增 shim 行数量级 | **150–300 行**（Windows.Win32 部分）；难点是 20–25 个 COM vtbl 槽的语义正确性，不是行数 | 句柄包 nint 的形态在现有 shim 里已有 10 个先例可复制 |

### 1.4 同源但更大的缺口：`System.Private.Windows.*`（WinForms 私有包）

`Windows.Win32` 之外，这 3 个文件所在的**整个 OLE 剪贴板/DragDrop 栈**还深度依赖 WinForms 私有包 `System.Private.Windows.Core`（csproj 里的 `MicrosoftPrivateWinFormsReference`，port-lib 会丢弃）。8 个文件共 **1880 行**（另加 `GlobalUsings.cs` 的 4 个泛型别名）：

| 文件 | 行数 | 依赖形态 |
|---|---|---|
| `System/Windows/dataobject.cs` | 655 | `IDataObjectInternal<,>` + `Composition.Create()`（`System.Private.Windows.Ole` 泛型宿主） |
| `System/Windows/clipboard.cs` | 503 | `ClipboardCore<WpfOleServices>`（GlobalUsings 泛型别名） |
| `System/Windows/OleServicesContext.cs` | 202 | `OleServicesContext` |
| `System/Windows/Ole/WpfOleServices.cs` | 191 | `IOleServices` 接口（`IDataObject*` 指针签名）+ `PInvokeCore.OleGet/Set/FlushClipboard` |
| `System/Windows/DataFormats.cs` | 190 | `DataFormatsCore<DataFormat>` |
| `System/Windows/Ole/DataObjectAdapter.cs` | 47 | `IDataObjectInternal` 适配 |
| `System/Windows/DataFormat.cs` | 40 | `DataFormat` 宿主类型参数 |
| `System/Windows/Nrbf/WpfNrbfSerializer.cs`(52) + `GlobalUsings.cs` | 52 | `Composition<WpfOleServices, WpfNrbfSerializer, DataFormat>` 泛型参数 |

若走 shim：需重写 `DataFormatsCore<T>/DragDropHelper<T>/ClipboardCore<T>/Composition<T>` 四个泛型宿主 + `IOleServices` + `PInvokeCore` 的等价面，量级 **500–1000 行**，且其行为（OLE 剪贴板/DnD 协议）在 Linux 上必须换成 X11 selection / Xdnd，属「编译 shim 可行、运行期仍需重实现」的典型。这是路线甲在 PresentationCore 里的**第一大不确定项**（详见 §5、§6）。

---

## 清单 2：`MS.Win32` 依赖

### 2.1 引用广度（133 文件）

- 目录分布：`System/` 下 **109** 文件，`MS/` 下 **24** 文件。
- 按被引用类的出现次数：`MS.Win32.Penimc` 56、`MS.Win32.Recognizer` 52、`MS.Win32.PresentationCore` 52、`MS.Win32.NativeMethods` 25、`MS.Win32.UnsafeNativeMethods` 23、`MS.Win32.Pointer` 9、`MS.Win32.SafeSystemMetrics` 2、`MS.Win32.WinInet` 1。
- 按引用文件数：`PresentationCore` 49、`UnsafeNativeMethods` 11、`NativeMethods` 10、`Penimc` 9、`Pointer` 9、`Recognizer` 2、`SafeSystemMetrics` 1、`WinInet` 1（同一文件可引用多个类）。
- 其中 `Penimc/Recognizer/PresentationCore/Pointer` 四个命名空间是 **PresentationCore 自带的本地类**（`MS/Win32/UnsafeNativeMethodsPenimc.cs` 680 行、`UnsafeNativeMethodsPointer.cs` 650 行、`UnsafeNativeMethodsTablet.cs` 342 行，共 1672 行），零外部依赖。
- `MS.Win32.NativeMethods/UnsafeNativeMethods`（POINT/RECT/MSG 等）全部定义在 `Shared/MS/Win32/` 里，而 **Shared/MS/Win32 的 16 个文件已随 WindowsBase.Linux 编译通过**（见 2.3）。

### 2.2 DllImport 全景（18 文件命中 / 15 文件有真实属性 / 308 条属性）

按 DLL 统计（编译集合 = SRC/PresentationCore + 上游 csproj 引入的 Common/Graphics 9 个文件）：

| DLL（常量 → 实际文件名） | 属性条数 | 主要文件 |
|---|---|---|
| `DllImport.WindowsCodecs` → **WindowsCodecs.dll（WIC）** | **109** | `System/Windows/Media/UnsafeNativeMethodsMilCoreApi.cs`（1158 行；`WICCreateImagingFactory_Proxy`/`WICConvertBitmapSource`/`IWICStream_*_Proxy` 等，句柄以 `IntPtr/SafeMILHandle` 不透明传递） |
| `DllImport.MilCore` → **wpfgfx_cor3.dll** | **104**（in-tree 63 + Common/Graphics 41） | in-tree：`UnsafeNativeMethodsMilCoreApi.cs`、`Composition.cs`(8)、`SafeNativeMethodsMilCoreApi.cs`(3)、`MediaContextNotificationWindow.cs`(2)、`HwndTarget.cs`(2)、`MILUtilities.cs`(2)、`StreamAsIStream.cs`(1)、`EventProxy.cs`(1)；Common/Graphics：`exports.cs`、`wgx_exports.cs`（DUCE 通道） |
| `DllImport.PresentationNative` → **PresentationNative_cor3.dll** | 28 | `MS/internal/TextFormatting/LineServices.cs`(27，`LoCreateContext`/`LoCreateLine` 等行排版引擎) + `MS/internal/Classification.cs`(1) |
| `ExternDll.Penimc` → **PenIMC_cor3.dll** | 16 | `MS/Win32/UnsafeNativeMethodsPenimc.cs`（触笔/手写 COM） |
| `ExternDll.Mshwgst` → **mshwgst.dll** | 14 | `MS/Win32/UnsafeNativeMethodsTablet.cs`（手写识别） |
| `DllImport.User32` + 明文 → **user32.dll** | 11 | `MS/Win32/UnsafeNativeMethodsPointer.cs`(10，`GetPointerInfo`/`GetRawPointerDeviceData` 等) + `ModuleInitializer.cs`(1，`SetProcessDPIAware`) |
| `DllImport.Mscms` → **mscms.dll** | 9 | `UnsafeNativeMethodsMilCoreApi.cs`（色彩管理） |
| `DllImport.NInput` → **ninput.dll** | 7 | `MS/Win32/UnsafeNativeMethodsPointer.cs` |
| `ExternDll.Ole32`/明文 → **ole32.dll** | 3 | `UnsafeNativeMethodsMilCoreApi.cs`(2) + `UnsafeNativeMethodsPenimc.cs`(1) |
| `DllImport.WindowsCodecsExt` → **WindowsCodecsExt.dll** | 2 | `UnsafeNativeMethodsMilCoreApi.cs` |
| `DllImport.ApiSetWinRT( String)` → **api-ms-win-core-winrt-\*** | 4 | `MS/internal/WindowsRuntime/Windows/UI/ViewManagement/NativeMethods.cs`（InputPane/UISettings RCW） |
| `ExternDll.Kernel32` → **kernel32.dll** | 1 | `UnsafeNativeMethodsPenimc.cs` |

> 与 handoff 的「150+ 处 Win32 P/Invoke」直觉不同，PresentationCore 的 P/Invoke **大头是 WIC（109 条）与自有 MIL 原生通道（110 条）**，user32/kernel32 仅 12 条。WIC/MIL 恰好都有本工程已有的承接面：M1 的位图解码栈（Skia）与 DUCE 通道。

### 2.3 关键结构体/句柄类型（PresentationCore 直接依赖）

| 类型 | 定义位置（已随 WindowsBase.Linux 编译） | 说明 |
|---|---|---|
| `POINT` / `POINTF` / `RECT` / `MSG` / `WNDCLASSEX_D` / `PAINTSTRUCT` / `RAWINPUTDEVICELIST` / `WICImagingFactory` / `ITfSource` / `IPropertyBag2` 等 | `Shared/MS/Win32/NativeMethodsCLR.cs`(3085 行)、`NativeMethodsOther.cs`(1606 行)、`UnsafeNativeMethodsTextServices.cs`(2912 行) | **纯类型声明缺口 ≈ 0**：这些定义已在 WindowsBase.Linux 里编译通过，PresentationCore 经 ProjectReference(WindowsBase) + InternalsVisibleTo 直接消费 |
| `MSG`（公开版） | `SRC/WindowsBase/System/Windows/Interop/MSG.cs` | 已编译 |
| PresentationCore 本地新增 | `MS/Win32/` 3 文件 + `System/Windows/Media/NativeMethodsMilCoreApi.cs` | 纯托管，无缺口 |
| PresentationCore 从 Shared 单独编译的 4 个文件 | `SafeSystemMetrics.cs`(109)、`LoadLibraryHelper.cs`(96)、`WinInet.cs`(50，InternetGetCookie)、`UnsafeNativeMethodsCompiler.cs`(45，2 条 DllImport) | 无缺口 |

**结论：MS.Win32 的「纯类型声明缺口」≈ 0（shim 不需要新增任何东西）**。全部 308 条 DllImport 在 Linux 上编译期只需「声明存在」即可——WindowsBase 里程碑已实证 284 条同类声明 0 错误编译。风险全部在运行期语义（§5）。

### 2.4 骨架级耦合专项：HwndWrapper / HwndSubclass / HwndWrapperHook

先给最重要的一个事实：**这三个文件 + ManagedWndProcTracker + MessageOnlyHwndWrapper 已全部编入 WindowsBase.Linux 并通过 0 错误编译**（`build/WindowsBase.Linux/WindowsBase.Linux.csproj` 包含 Shared/MS/Win32 20 个文件中的 16 个，合计 **284 条 DllImport 属性**；剩余 4 个由 PresentationCore 自身编译，见 §2.3）。PresentationCore 本身不重复编译它们，而是从 WindowsBase.dll 消费；引用它们的 PresentationCore 文件只有 **3 个**：`MediaContextNotificationWindow.cs`、`HwndTarget.cs`、`HwndSource.cs`。即「骨架」在编译层面已经过关，问题 100% 在运行期。

逐文件依赖与 Linux 替代：

| 文件（行数） | 依赖的 Windows API | Linux 替代（本工程已有能力） | 编译期 shim 能否保过 | 运行期是否可能正确 |
|---|---|---|---|---|
| `Shared/MS/Win32/HwndWrapper.cs`（372） | RegisterWindowMessage、GetStockObject(NULL_BRUSH)、GetModuleHandle、RegisterClassEx(WNDCLASSEX_D)、CreateWindowEx、DestroyWindow、UnregisterClass；另依赖 Dispatcher.BeginInvoke/DispatcherObject | 窗口注册类/atom 语义 → X11 无需类注册（X11Window ctor 直接建窗）；CreateWindowEx → `XCreateSimpleWindow`（X11Native.cs:71，已有）；DestroyWindow → `XDestroyWindow`（已有）；RegisterWindowMessage → 私有消息 ID 改用进程内静态计数器或 X11 ClientMessage | **能**（全为 DllImport 声明 + 纯托管结构，WindowsBase 已实证） | **不能**——HWND≠XWindow，类名/GUID 类注册、WM_NCDESTROY 生命周期语义在 X11 不存在，必须重实现 |
| `Shared/MS/Win32/HwndSubclass.cs`（606） | RegisterWindowMessage、GetModuleHandle(user32)+GetProcAddress("DefWindowProcW")、SendMessage、GetWindowLongPtr/SetWindowLong(GWL_WNDPROC)、CallWindowProc；ManagedWndProcTracker 登记；Dispatcher.Invoke(Send) | WNDPROC 链/子类化 → X11 无此概念：改为 X11Window 内部 hook 委托链（`HwndWrapperHook` 是纯委托，7 行零依赖，可直接复用）；DefWindowProc → 默认 XEvent 处理器；SendMessage 同步派发 → 直接调用 hook 链 | **能**（同上） | **不能**——WndProc 链语义需重实现为事件分发表；`Dispatcher.Invoke(Send)` 的同步重入语义需要 Dispatcher 循环先落地 |
| `Shared/MS/Win32/HwndWrapperHook.cs`（7） | 无（纯 delegate `IntPtr HwndWrapperHook(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)`） | 直接复用 | 能 | **能**（本来就正确） |
| `Shared/MS/Win32/ManagedWndProcTracker.cs`（245，随 HwndSubclass 联动） | GetWindowLong/SetWindowLong/PostMessage/SendMessage/IsWindowUnicode/GetProcAddress + ShutDownListener | 进程退出清理 → 直接遍历活动 X11Window 销毁 | 能 | 不能（同上，但逻辑简单，重写约 100 行） |

X11 层现有能力对照（`src/WpfGfx.Linux/Windowing/`，5 文件 1196 行）：`X11Window`{Map/Unmap/SetTitle/Resize/Present/HasPendingEvents/TryNextEvent/RequestClose/Flush/Sync}、`X11PresentationTarget`{`NativeHandle`(nint，可直接当 HWND 身份值)/WindowId/Resize/Present}、`X11Native`{XOpenDisplay/XCreateSimpleWindow/XMapWindow/XSelectInput/XPending/XNextEvent/XSendEvent/XDestroyWindow/XInternAtom/XFlush/XSync}。缺的只是「HWND→XWindow 注册表 + WndProc hook 链 → XEvent 路由」这一层胶水（几百行量级）。

**小结（清单 2 判定）**：`编译期 shim 能否保过` → **能**（0 新增类型）；`运行期是否正确` → 三件套 **必须重实现**，但其替换面收敛在 3 个 PresentationCore 文件 + 1 个 WindowsBase 消费点（Dispatcher），X11 骨架已具备 90% 原材料。

---

## 清单 3：Dispatcher / System.Windows.Interop / 呈现目标骨架

### 3.1 WindowsBase Dispatcher 的消息循环用什么 Windows API

`SRC/WindowsBase/System/Windows/Threading/Dispatcher.cs`（2876 行，已随 WindowsBase.Linux 编译通过）：

| 用途 | API | 行号（采样） |
|---|---|---|
| 主消息循环（PushFrame 内） | `GetMessageW`（经 `ITfMessagePump`，无 TSF 时直连）、`TranslateMessage`、`DispatchMessage` | 2064–2067、2104–2120、2195–2204 |
| 后台优先级调度 | `MsgWaitForMultipleObjectsEx`、`SetTimer/KillTimer`（TIMERID_BACKGROUND）、`PeekMessage(PM_REMOVE)`、`GetMessageExtraInfo/SetMessageExtraInfo`、`TryPostMessage` | 2308、2344–2391、2415、2652–2668 |
| 队列唤醒 | `RegisterWindowMessage("DispatcherProcessQueue")`（静态 ctor） | 24 |
| 退出 | `PostQuitMessage`（当前被注释，见 1793） | — |

编译期零成本（DllImport 声明随 WindowsBase.Linux 已过）。**运行期替换方案**：`GetMessage/PeekMessage` ↔ `XPending/XNextEvent`（X11Native 已有）+ 自建优先级队列唤醒（XSendEvent/eventfd）；`SetTimer` ↔ POSIX timer 或 X11 定时器；`ITfMessagePump`（Cicero TSF）在 Linux 直接走无 TSF 分支。消息泵是 U2 运行时第一块必须替换的基石，但它已经在编译产物里，路线甲不需要为它多写一行 shim。

### 3.2 System.Windows.Interop 全套（文件清单与行数）

共 **17 个文件、10,513 行**（`System/Windows/InterOp/`）：

| 文件 | 行数 | 角色 | HWND 依赖强度 |
|---|---|---|---|
| HwndSource.cs | 2843 | 窗口源：创建 HwndWrapper + HwndTarget + 输入提供器 | **高**（直接 SetWindowPos×1、GetFocus×1、CriticalSetWindowTheme、RegisterDropTarget） |
| HwndTarget.cs | 2650 | 呈现目标：MilVisualTarget_AttachToHwnd/DetachFromHwnd(2 条 DllImport)；RegisterWindowMessage×3、GetParent/GetWindow/GetWindowThreadProcessId/IsWindow、WTS 会话通知、InvalidateRect×8、BeginPaint/GetWindowLong/GetLayeredWindowAttributes | **高** |
| HwndMouseInputProvider.cs | 1513 | 鼠标输入（WM_MOUSEMOVE 等消息 → WPF 事件） | 中（消息转译层） |
| D3DImage.cs | 957 | D3D11 互操作（InteropDeviceBitmap 等） | 低（纯 Windows 专属，Linux 需剔除或空实现） |
| HwndKeyboardInputProvider.cs | 866 | 键盘输入 + IME（ITf*/Imm* 消息） | 中 |
| HwndPointerInputProvider.cs | 466 | 指针输入（GetPointerInfo 家族） | 中 |
| HwndSourceParameters.cs | 428 | 建窗参数 | 低 |
| HwndStylusInputProvider.cs | 166 | 触笔 | 中 |
| HwndPanningFeedback.cs | 128 | 平移反馈 | 低 |
| HwndAppCommandInputProvider.cs | 115 | AppCommand | 低 |
| Imaging.cs | 113 | 位图句柄转换 | 低 |
| HwndSourceKeyboardInputSite.cs | 90 | IME 站点 | 低 |
| CursorInteropHelper.cs | 70 | 光标句柄 | 低 |
| OperatingSystemVersionCheck.cs | 54 | 版本检查（RtlGetVersion） | 低 |
| IStylusInputProvider.cs / IWin32Window.cs / HwndSourceHook.cs | 24/20/10 | 纯接口/委托 | 无 |

> 注：`WindowInteropHelper` 不在 PresentationCore，而在 `SRC/PresentationFramework/System/Windows/Interop/WindowInteropHelper.cs`（U2 下一站才涉及）。

### 3.3 HWND 的角色：身份标识 vs 窗口管理（路线之争的核心证据）

**HWND 主要作为「窗口身份标识」使用，窗口管理 API 的调用面收敛且稀疏：**

| 指标 | 数值 |
|---|---|
| 引用 `DUCE.` 的文件 | **128**；其中引用 `DUCE.Channel` 的 **121**；`using System.Windows.Media.Composition` 的 242 |
| `CompositionTarget.cs` 中 HWND 出现次数 | **0**（全 DUCE 通道，`DUCE.ChannelSet/Channel` + `MultiChannelResource`） |
| `MediaContext.cs`（2893 行）中 hwnd 出现次数 | **4**（全为注释与 HwndTarget 转型，无 HWND 调用） |
| 字面 `hwnd` 出现的文件 | 43 |
| 直接窗口管理 API（按引用文件数） | GetParent 27、ScreenToClient 10、ClientToScreen 9、SetFocus 6、WindowFromPoint 4、SetParent 4、GetWindowLong 4、GetFocus 4、GetClientRect 4、GetWindowRect 3、**SetWindowPos 2**、GetCapture 2、SetWindowLong/SetForegroundWindow/SetCapture/ReleaseCapture/InvalidateRect 各 1 |
| HWND→原生呈现的通道 | `MilVisualTarget_AttachToHwnd/DetachFromHwnd`（HwndTarget.cs:565/571）+ `MilContent_AttachToHwnd/DetachFromHwnd`（MediaContextNotificationWindow.cs:75/85/143，媒体上下文隐藏通知窗口）+ DUCE `TYPE_HWNDRENDERTARGET` 命令 |

**判定**：HWND 在绝大多数文件里是「不透明身份值」——经由 DUCE 命令流或 `Mil*_AttachToHwnd` 传给原生层，原生层（Windows 上 wpfgfx_cor3.dll，本工程里是 WpfGfx.Linux）负责把它绑定到真实窗口/呈现表面。**shim 保编译 + 运行时把 HWND 映射为 X11 窗口 id（或本工程 MilChannelRegistry 式的进程内句柄）是可行的**：`X11PresentationTarget.NativeHandle` 已经是 nint 形态。需要重实现的是上文 3.2 表里「高」强度的 2 个文件 + 消息泵，而不是整个 1294 文件面。

### 3.4 DUCE 通道原生面缺口（M1 对照，运行时指标）

| 项 | 数值 |
|---|---|
| 托管侧 `DllImport.MilCore` 属性总数 | **104**（in-tree 63 + Common/Graphics 41） |
| 去重后的导出名 | **102** |
| M1 `WpfGfx.Linux` 已实现的 Mil* 导出 | **15** |
| 交集 | **7** |
| **运行时缺口** | **94 个导出名**（⚠️ 本行原写 95，2026-09-10 由 M7a 实测更正：属性 110 条 / 去重导出名 108 / 方法名 106，缺口 = 108 − 14 既有 = **94**；M7a 已全部补齐），代表组：`MilVisualTarget_AttachToHwnd/DetachFromHwnd`、`MilContent_AttachToHwnd/DetachFromHwnd`（窗口绑定）、`MilComposition_PeekNextMessage/SyncFlush/WaitForNextMessage`（渲染线程同步）、`MilUtility_*` 几何（ArcToBezier/PathGeometryFlatten/Widen/Combine/HitTest 等）、`MilGlyphRun_*`（字形）、`MILSwDoubleBufferedBitmap*`、`MILRenderTargetBitmap*`、`WgxConnection_*`、`MILMedia*`（媒体，U3 已定暂缓）、`MILCreateFactory/MILVersionCheck/MILAddRef/MILRelease`、锁函数 `MilCompositionEngine_*` |
| M1 已覆盖的 15 个 | `MilChannel_BeginCommand/AppendCommandData/EndCommand/GetMarshalType/SetNotificationWindow`、`MilConnection_CreateChannel/CommitChannel/CloseBatch/DestroyChannel`、`MilResource_CreateOrAddRefOnChannel/DuplicateHandle/ReleaseOnChannel/SendCommand/SendCommandBitmapSource/SendCommandMedia` |

编译期 0 成本（全是 DllImport 声明）；运行时按 .NET 的 Linux DllImport 名称映射（`wpfgfx_cor3.dll` → `libWpfGfx_cor3.so`），需要一份导出上述 **108** 名的 .so。缺口 94 个里（M7a 已补齐，见 handoff U2 专节）相当一部分可直接复用 M1 现有能力面（Skia 几何/位图/字形），另有约 10–15 个是「窗口绑定/连接/同步」类，属于路线乙的必经之路。`docs/duce-commands.txt` 已有命令面文档可对照。

---

## 清单 4：工程依赖清单

### 4.1 ProjectReference（8 条，port-lib 按规则丢弃后需手工重接）

| 上游引用 | 状态 / 处置 | 规模 |
|---|---|---|
| `WindowsBase\WindowsBase.csproj` | ✅ **已移植**（build/WindowsBase.Linux，1.1MB，0 错）→ port-lib 自动以本地 DLL 重接 | — |
| `System.Xaml\System.Xaml.csproj` | ✅ **已移植**（build/System.Xaml.Linux 存在产物）→ 同上 | 189 .cs |
| `DirectWriteForwarder\DirectWriteForwarder.vcxproj` | ❌ C++/CLI 项目 → 丢弃；其职责（DWrite 转发表）由 M1 字体/文本栈替代；托管侧 DWriteLoader.cs 用 `NativeLibrary.Load("dwrite.dll")` 动态装载，Linux 需改为加载本工程 DWrite 替代物 | — |
| `System.Windows.Input.Manipulations.csproj` | ⚠️ **未移植**（先决依赖，需先跑 port-lib） | 24 .cs |
| `System.Windows.Primitives.csproj` | ⚠️ **未移植，且是关键**：全仓唯一 CsWin32 宿主（仅 1 个 AssemblyInfo.cs + NativeMethods.txt 23 行 + json）。port-lib 可产出空壳，但 `Windows.Win32` 类型必须由本工程 shim 提供（WindowsBase 里程碑的做法：以 `build/shims/WindowsWin32.Shim.cs` 编入消费方项目替代） | 1 .cs |
| `UIAutomation\UIAutomationTypes.csproj` | ⚠️ 未移植（先决依赖） | 51 .cs |
| `UIAutomation\UIAutomationProvider.csproj` | ⚠️ 未移植（先决依赖） | 29 .cs |
| `PresentationCore\ref\PresentationCore-ref.csproj` | 引用程序集项目（`ReferenceOutputAssembly=false`）→ port-lib 已跳过 `-ref` | — |

**依赖链结论**：PresentationCore 之前需要先移植 **3 个托管小项目**（Manipulations 24 + UIAutomationTypes 51 + UIAutomationProvider 29 = **104 个 .cs**，量级均远小于 WindowsBase 的 313），其中 UIAutomationTypes/Provider 的 UI 自动化接口定义部分可能与 `Accessibility.IAccessible` 一样需要小 shim（WindowsBase 里程碑已有 2 行先例）。

### 4.2 PackageReference（4 条）

| 包 | 版本变量 | port-lib 版本表 | 备注 |
|---|---|---|---|
| System.Configuration.ConfigurationManager | $(SystemConfiguration…) | ✅ 已有 9.0.0 | |
| System.Windows.Extensions | $(…) | ✅ 已有 9.0.0 | |
| $(SystemIOPackagingPackage) → System.IO.Packaging | $(SystemIOPackagingVersion) | ✅ 已有 9.0.0（PKG_NAMES 映射已备） | |
| **System.Formats.Nrbf** | $(SystemFormatsNrbfVersion) | ❌ **PKG_VERSIONS 无此项 → 回退 9.0.0，需核实可用性**（上游 NoWarn 里已见 SYSLIB5005，是实验性 API） | Nrbf 序列化（WpfNrbfSerializer，OLE 栈一部分） |

### 4.3 私有 WinForms 引用 / CsWin32 / Arcade 代码生成（对照 port-lib 的 WindowsBase 处理）

| 项 | 上游情况 | WindowsBase 先例 | PresentationCore 差异 |
|---|---|---|---|
| `MicrosoftPrivateWinFormsReference`（System.Private.Windows.Core） | 1 条 | 丢弃 + 以 `Accessibility.Shim.cs` 补 2 个类型 | **差距大**：8 文件 1880 行深度消费 `System.Private.Windows.Ole` 泛型宿主（§1.4），是 SplashScreen 之外的新增毒点群 |
| CsWin32 | 全仓唯一宿主 System.Windows.Primitives（CsWin32 包 + winmd 元数据，离线不可得） | 手写 `WindowsWin32.Shim.cs` 263 行等效类型 | 沿用同一 shim 文件，仅需追加 §1.3 的 7–9 类型 + 3 成员 |
| SR 资源 | `PresentationCore/Resources/Strings.resx`（115 KB）→ Arcade `GenerateCommonSRSource` | port-lib `gen-sr.py` 生成 `SR.g.cs`；`SR_NS` 映射表**已含** `PRESENTATION_CORE → MS.Internal.PresentationCore` | 0 改动即可用 |
| 代码生成 Target/Import | `GenerateSources`/`GenerateAvTrace`/`TransformAll` + `GenAvMessages.targets`/`DesignTimeTextTemplating` import | port-lib DROP_TARGETS/DROP_IMPORT_KEYWORDS 已覆盖 | 关键产物均已 checked-in：`MS/Internal/Generated/AvTraceMessages.cs`、`Common/Graphics/Generated/wgx_commands.cs`(1111 行)、`exports.cs`(2537)/`wgx_exports.cs`(344)——**mcg 生成器无需运行** |
| Compile 列表 | 1357 条 Include（本地 1235 + Common 62 + Shared 60） | 313 条全命中 | **212 条 Include 路径与 Linux 实际大小写不符**（如 `MS\Internal\...` vs `MS/internal/...`）；本地按 basename 100% 可找回，但 port-lib.py 的找回循环只搜 Common/Shared → **需扩展为也搜项目目录**（约半天改动）。另有 9 个本地文件未列入编译（FontCache 5 个、`System/Windows/Media/Generated/ColorCollectionConverter.cs`、`GlyphCache.cs`、`printcontext.cs`、ref），与上游行为一致 |

### 4.4 「SplashScreen 式毒点文件」点名（单个文件深度依赖 Windows COM/WIC 的候选）

SplashScreen 先例 = 单文件需要 7 个 WIC COM 接口约 70 个 vtbl 槽，被剔除出编译列表。PresentationCore 的对应候选（**注意：均无 SplashScreen 那么极端**，COM 部分被 P/Invoke + 不透明句柄吸收了大半）：

| 文件（行数） | 毒点形态 | 建议 |
|---|---|---|
| `System/Windows/Ole/WpfOleServices.cs`(191) + `dataobject.cs`(655) + 同栈 6 文件 | **OLE 剪贴板/DnD 栈**：`IDataObject` 9 槽 + IUnknown、`IAdviseSink/IEnum*`、`FORMATETC/STGMEDIUM` 结构体 + WinForms 私有包泛型宿主。公开 API `System.Windows.DataObject/Clipboard` 不可整栈剔除（会破 API 面），故这是路线甲唯一「非 shim 不可或必须重写」的编译期硬点 | ① shim COM 接口 + 泛型宿主（约 150–300 + 500–1000 行，vtbl 语义需严格对齐）；② 剔除后以 Linux 实现重建公开 API（X11 selection/Xdnd，路线乙风格）。**本清单的 fork 点** |
| `System/Windows/Media/Imaging/BitmapSource.cs`(1961) + `BitmapMetadata.cs`(1538) + `UnsafeNativeMethodsMilCoreApi.cs`(1158) | **WIC 成像栈**：109 条 WIC P/Invoke（`_Proxy` 入口）+ 2 个小型 COM 接口（`IWICBitmapSource` 5 槽、`IWICMetadataBlockReader/Writer` 约 7 槽）。比 SplashScreen 温和：接口少、大部分是 IntPtr 不透明句柄 | 编译期可 shim（约 12 个 vtbl 槽）；运行期位图解码已由 M1 Skia 栈承接，WIC 语义需映射 |
| `System/Windows/InterOp/D3DImage.cs`(957) | D3D11 纹理共享（`InteropDeviceBitmap_*`、D3D COM） | Windows 专属，Linux 上建议整体空实现/剔除（公开类型保留 stub） |
| `MS/internal/TextFormatting/LineServices.cs`(27 条 P/Invoke) | PresentationNative 行排版引擎 | 编译无碍；运行期需 M1 文本栈（Skia text）或纯托管 fallback |
| `MS/internal/Ink/GestureRecognizer/NativeRecognizer.cs` | mshwgst.dll 手写识别 | 运行期无替代 → 功能降级（识别器恒空） |

---

## 5. 分类汇总：「shim 可保编译」vs「必须重实现」

| 组件 | 编译期（shim 能否保过） | 运行期（能否正确） | 工作量信号 |
|---|---|---|---|
| Windows.Win32 句柄/常量/结构体（HRESULT/BOOL/HBITMAP/…） | ✅ 已覆盖 4 型；FORMATETC/STGMEDIUM 可 shim | ⚠️ 结构体语义可，OLE 协议不可 | 天级 |
| Windows.Win32 COM 接口（IDataObject 组，20–25 槽） | ⚠️ 可 shim，但 vtbl 语义有 SplashScreen「能编译但语义错」先例风险 | ❌ Linux 无 OLE | 天~周级，需测试保真 |
| System.Private.Windows.Ole 泛型宿主（8 文件 1880 行） | ⚠️ shim 500–1000 行，或剔除+重写 | ❌ 需 X11 selection/Xdnd 重实现 | 周级（路线甲最大不确定项） |
| Shared/MS/Win32 全部类型 + 284 条 DllImport（含 HwndWrapper 三件套） | ✅ **已随 WindowsBase.Linux 编译通过（0 新增）** | ❌ 消息泵/子类化/窗口类注册语义须重实现 | 编译 0；运行时替换面 = HwndSource/HwndTarget/MediaContextNotificationWindow + Dispatcher 循环 |
| PresentationCore 内 267 条 DllImport | ✅ 声明即编译（M1 先例：WindowsBase 284 条已过） | ⚠️ 分三类：① MilCore 110 条 → 94 导出缺口（**M7a 已补齐**：48 真实现 / 9 身份映射 / 11 纯状态 / 26 E_NOTIMPL）；② WIC 109 条 → Skia 映射（已有能力面）；③ PresentationNative/PenIMC/mshwgst/ninput → 功能降级或替代 | 运行时月级 |
| DUCE 通道（托管侧） | ✅ 全 checked-in 源码，无代码生成 | ✅ M1 通道 15 导出 + **M7a 补齐 94 个缺口**（`MilNative.ExportManifest` 108 条留档） | 运行时月级（路线乙主场） |
| Dispatcher 消息循环（WindowsBase） | ✅ 已编译 | ❌ GetMessage/PeekMessage/SetTimer → XPending/XNextEvent/定时器 | 周级 |
| 工程侧（csproj/port-lib） | ⚠️ 需 3 个小项目先移植（104 .cs）+ 212 条大小写找回 + Nrbf 包版本核实 | — | 天~周级 |
| D3DImage / 手写识别 / 媒体 | ✅ 声明可过 | ❌ 功能降级（stub） | 天级（按 U3 口径） |

**总账**：编译期新增 shim 量 ≈ **300–1500 行**（取决于 OLE 栈决策），加工程脚本改动，**天~周级**；运行期 = 94 个 MIL 导出（M7a 已补齐 ✅）+ 消息泵/子类化替换 + OLE/WIC 映射，剩 **月级**。

---

## 6. 路线证据（只列事实与推论，不做决策）

### 6.1 支持「路线甲：继续 shim」的证据

1. **编译成本已被 WindowsBase 实证压到最低**：骨架三件套 + 284 条 DllImport 声明在 WindowsBase.Linux 以 0 错误通过；PresentationCore 的 308 条 DllImport 与 133 文件 MS.Win32 引用在编译期**不新增任何类型缺口**（结构体全部定义在已编译的 Shared 里）。
2. **Windows.Win32 缺口极小且集中**：仅 3 文件、7–9 类型、3 成员，其中 4 类型已覆盖；新增 shim 量级 150–300 行，10 个句柄形态先例可直接复制。
3. **HWND 主要是身份标识**：128 文件走 DUCE 通道（CompositionTarget 0 处 HWND），直接窗口管理 API 最宽也只有 GetParent 27 文件、其余 ≤10 文件且多为查询类；`X11PresentationTarget.NativeHandle`（nint）已证明「HWND=进程内句柄+映射表」可行。
4. **编译器是廉价 oracle**：shim 到 0 错误后，可用全量编译暴露剩余缺口（比逐文件读码便宜一个量级），且上游代码零改动（本项目纪律：上游绝对只读）。
5. 代价面收敛：唯一无法纯 shim 的编译期硬点是 OLE 栈 8 文件（§1.4），其余毒点文件（WIC/D3D/LineServices）编译无碍。

**推论**：路线甲可预期在 1–3 周内拿到 PresentationCore.dll（含全部公开 API），但该 DLL 中消息泵、子类化、OLE、WIC 在 Linux 上必然行为错误——需要一个「编译通过但运行不可用」的中间态预期管理，以及 shim COM vtbl 的语义保真测试（SplashScreen 教训）。

### 6.2 支持「路线乙：先建 X11 窗口后端骨架」的证据

1. **骨架替换面高度收敛**：HwndWrapper/HwndSubclass/ManagedWndProcTracker 在 PresentationCore 只有 3 个消费者（MediaContextNotificationWindow/HwndTarget/HwndSource），加上 WindowsBase 的 Dispatcher 循环与 MessageOnlyHwndWrapper——窗口模型改造不是「1294 文件全改」，而是 4–6 个文件的接口级替换。
2. **X11 原材料已就位**：`src/WpfGfx.Linux/Windowing/`（1196 行）已有窗口生命周期（Create/Map/Unmap/Resize/Destroy/SetTitle）、事件循环（XPending/XNextEvent/TryNextEvent/HasPendingEvents）、呈现（Present(SKImage)）与 `NativeHandle` 身份位；缺的只是 HWND↔XWindow 注册表 + hook 链路由胶水。
3. **94 个 MIL 导出缺口正好是 M1 的自然延伸**（M7a 已补齐）：DUCE 通道 15 个导出已实现（MilConnection_*/MilChannel_*/MilResource_*），窗口绑定类（MilVisualTarget_AttachToHwnd/MilContent_AttachToHwnd/WgxConnection_*）是路线乙第一步的必做项——**无论哪条路线，这 94 个导出早晚都要补**，先做可避免「给最终要替换的窗口模型打补丁」（handoff 原话）。
4. 消息泵映射关系清晰：GetMessage/PeekMessage ↔ XPending/XNextEvent、SendMessage 同步派发 ↔ 直接调用、SetTimer ↔ POSIX timer，Dispatcher.cs 的替换点集中（§3.1 列出的 10 余处）。

**推论**：路线乙把「运行期正确」前置，窗口语义一步到位；代价是必须动上层代码（放弃 shim 的不改上游纪律）、且 HelloWpf 出图还依赖 PresentationFramework（超出本次扫描范围），见效周期 > 路线甲的编译里程碑。

### 6.3 支持「混合」的证据（事实层面）

1. 编译与运行的风险分布是正交的：编译期风险集中在 OLE 栈 8 文件与 3 个小项目移植；运行期风险集中在消息泵/子类化与 95 个 MIL 导出。**两者可以并行、可以错序**。
2. 有自然的分界点：① 编译里程碑（shim 到 0 错误，天~周级）→ ② 窗口身份映射（HWND=句柄表，复用 M1 MilChannelRegistry 模式，天级）→ ③ Dispatcher/消息泵替换（周级）→ ④ DUCE 导出补齐（周~月级）→ ⑤ OLE/WIC 语义替换（最后，可降级）。
3. 成本可复用：路线甲的 shim 产物（Windows.Win32 句柄类型）在任何路线下都是公共基础设施（WindowsBase 与 PresentationCore 已共用同一 shim 文件）；路线乙的 X11 窗口层在任何路线下都是最终归宿。**两者没有排他性，只有顺序差。**

---

## 附录：关键命令索引（复现用）

```bash
SRC=<repo>/upstream/wpf/src/Microsoft.DotNet.Wpf/src

# 清单1
grep -rl 'Windows.Win32' $SRC/PresentationCore        # 3 文件
grep -noE 'Windows\.Win32\.[A-Za-z0-9_.]+' $SRC/PresentationCore/System/Windows/Ole/WpfOleServices.cs | sort | uniq -c
grep -rln 'System.Private.Windows' $SRC/PresentationCore --include='*.cs'   # 8 文件（OLE 栈）

# 清单2
grep -rl 'MS\.Win32' $SRC/PresentationCore | wc -l     # 133
grep -rhoE 'MS\.Win32\.[A-Za-z0-9_]+' $SRC/PresentationCore --include='*.cs' | sort | uniq -c
grep -rcE '^\s*\[DllImport' $SRC/PresentationCore --include='*.cs' | awk -F: '{s+=$2} END{print s}'   # 267
grep -rhoE '\[DllImport\([^,)]*' $SRC/PresentationCore --include='*.cs' | sort | uniq -c | sort -rn   # 按 DLL 常量
# Common/Graphics 41 条与 MilCore 102 导出名：Python 跨行正则（见 §0 口径）

# 清单3
grep -nE 'MSG|GetMessage|PeekMessage|TranslateMessage|DispatchMessage|MsgWaitForMultipleObjectsEx|SetTimer' $SRC/WindowsBase/System/Windows/Threading/Dispatcher.cs
grep -rl 'DUCE\.' $SRC/PresentationCore --include='*.cs' | wc -l           # 128
grep -rln 'UnsafeNativeMethods\.(GetParent|SetWindowPos|...)(' $SRC/PresentationCore --include='*.cs'  # 按 API 统计

# 清单4
grep -n 'ProjectReference\|PackageReference\|MicrosoftPrivateWinFormsReference' $SRC/PresentationCore/PresentationCore.csproj
python3 build/port-lib.py PresentationCore   # 生成 build/PresentationCore.Linux/PORT-CHANGES.md 后核对（本报告未执行，仅静态对照）
```

**本次扫描未改动任何工程文件；上游仓库零写入。**

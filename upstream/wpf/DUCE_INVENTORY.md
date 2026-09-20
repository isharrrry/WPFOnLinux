# DUCE 边界接口盘点（T1 Spike · dotnet/wpf 托管层静态分析）

> 分析范围：`/workspace/wpf2web/upstream-wpf/src/Microsoft.DotNet.Wpf/src/`（仅托管 `src` 层，MIT，经 gh-proxy 克隆）
> 方法：纯 Linux 静态分析（grep/Read），**未编译**（dotnet/wpf 构建链需 Windows+MSVC 编译 WpfGfx，Linux 不可行）
> 目标：fork 托管层（PresentationFramework/PresentationCore/WindowsBase/System.Xaml/PresentationBuildTasks 等），仅替换最底层的非托管渲染（WpfGfx/MilCore），上层全保留，让 WPF 程序编译到 Linux 并以 Web 呈现。

---

## 0. 总览结论（TL;DR）

- **DUCE 边界 = 托管/非托管分界**，集中表现为 `DllImport.MilCore`（实际指向 `wpfgfx*.dll`，见 `Shared/RefAssemblyAttrs.cs:71`）。
- 全仓 `DllImport.MilCore` 共 **157** 处；其中**托管侧调用方 110 处**（Common/Graphics 47 + PresentationCore 63），WpfGfx/include 下 47 处为原生镜像（不计）。
- MILCMD 渲染指令枚举 **143** 个成员（`Common/Graphics/wgx_core_types.cs:600`），其中 RenderData 指令段（MilDraw*/MilPush*/MilPop）**25** 条。
- **R1（WindowsBase 侧）真实 Win32 互操作表面不在 WindowsBase 程序集本体**（仅 69 处，多为 RightsManagement/宿主 shim），而在 `Shared/MS/Win32/`（**288** 处），被链接进 WindowsBase。合计 **357** 条 P/Invoke 进入 WindowsBase 编译单元（详见 `winbase_pinvoke.json`）。

---

## 1. DUCE 边界清点（PresentationCore / Common 内）

### 1.1 DUCE 边界核心类型与职责

`DUCE` 是一个 `partial class`，定义分散在 `Common/Graphics/`（codegen 产物，托管层与非托管层共用同一份类型定义）与 `PresentationCore/` 中：

| 类型 | 文件 | 行号(约) | 职责 |
|---|---|---|---|
| `DUCE`（partial 主类：通道/句柄/资源接口） | `Common/Graphics/exports.cs` | 81 | DUCE 边界主入口；含 `ChannelSet`、`Channel`、`ResourceHandle`、`IResource` |
| `DUCE.ChannelSet`（struct） | `Common/Graphics/exports.cs` | 303 | 一组 Channel（含 OutOfBand 通道） |
| `DUCE.Channel`（sealed partial class） | `Common/Graphics/exports.cs` | 320 | **命令通道**：`Commit/CloseBatch/SyncFlush/Present/SendCommand/BeginCommand/AppendCommandData` + 资源句柄管理 |
| `DUCE.ResourceHandle`（struct） | `Common/Graphics/exports.cs` | 969 | 指向非托管 MilCore 资源的句柄 |
| `DUCE.IResource`（interface） | `Common/Graphics/exports.cs` | 2508 | 所有可上屏 WPF 对象实现此接口（`UpdateResource(DUCE.Channel)`、`AddRefOnChannel`、`ReleaseOnChannel`、`GetHandle`） |
| `DUCE`（命令包装 partial） | `Common/Graphics/Generated/wgx_commands.cs` | 20 | codegen 出的各 MILCMD 发送包装方法 |
| `DUCE`（类型/枚举 partial：MILCMD 等） | `Common/Graphics/wgx_core_types.cs` | 783, 892 | 渲染指令枚举、数据包结构 |
| `DUCE.Message`（struct） | `Common/Graphics/exports.cs` | 288 | 通道通知消息结构（非 Win32 MSG） |
| `MilCoreApi`（Unsafe P/Invoke 分组） | `PresentationCore/System/Windows/Media/UnsafeNativeMethodsMilCoreApi.cs` | 14 | `DllImport.MilCore` 主入口（44 处） |
| `MilCoreApi`（Safe P/Invoke 分组） | `PresentationCore/System/Windows/Media/SafeNativeMethodsMilCoreApi.cs` | — | 安全包装（3 处） |
| `Composition`（DUCE 资源创建/销毁封装） | `PresentationCore/System/Windows/Media/Composition.cs` | — | 通过 Channel 创建/删除 MilCore 资源（8 处 P/Invoke） |
| `MediaContext` | `PresentationCore/System/Windows/Media/MediaContext.cs` | — | 每 Dispatcher 一个，驱动渲染循环、收集脏区、分发到 Channel |
| `ChannelManager` | `PresentationCore/System/Windows/Media/ChannelManager.cs` | — | 管理与非托管端的连接（Connection/Transport） |
| `CompositionTarget` / `ICompositionTarget` | `PresentationCore/System/Windows/Media/CompositionTarget.cs`、`ICompositionTarget.cs` | — | 渲染目标抽象（Hwnd 目标 / 离屏目标） |
| `HwndTarget` | `PresentationCore/System/Windows/InterOp/HwndTarget.cs` | — | 绑定一个 Win32 HWND 作为渲染表面（2 处 MilCore P/Invoke） |
| `MILUtilities` | `PresentationCore/System/Windows/Media/MILUtilities.cs` | — | 工具（2 处） |
| `MediaContextNotificationWindow` | `PresentationCore/System/Windows/Media/MediaContextNotificationWindow.cs` | — | 用隐藏 HWND 接收 MilCore 通知（2 处） |
| `EventProxy` / `StreamAsIStream` | `PresentationCore/System/Windows/Media/EventProxy.cs`、`StreamAsIStream.cs` | — | 事件回调代理 / 流桥接（各 1 处） |

### 1.2 托管层向 MilCore 暴露的 P/Invoke 入口

`DllImport.MilCore` 常量定义：`Shared/RefAssemblyAttrs.cs:71`
```csharp
internal const string MilCore = $"wpfgfx{BuildInfo.WCP_VERSION_SUFFIX}.dll";
```
（即 `wpfgfx_v0XXXX.dll`；原生侧另有 `WpfGfx/include/wgx_core_dllname.cs:19` 指向 `WpfGfx_v0400.dll`，二者是同一后端的两份命名。）

**全仓 `DllImport.MilCore` 统计：157 处**，按文件：

| 文件 | MilCore P/Invoke 数 | 性质 |
|---|---|---|
| `Common/Graphics/exports.cs` | 19 | 托管侧（DUCE 通道原语） |
| `Common/Graphics/wgx_exports.cs` | 28 | 托管侧（Wgx 连接层：WgxConnection_* 等） |
| `PresentationCore/.../UnsafeNativeMethodsMilCoreApi.cs` | 44 | 托管侧（MilCompositionEngine_*、MILCreateStream*、WgxConnection_* 等） |
| `PresentationCore/.../Composition.cs` | 8 | 托管侧（资源创建/销毁） |
| `PresentationCore/.../SafeNativeMethodsMilCoreApi.cs` | 3 | 托管侧（安全包装） |
| `PresentationCore/.../MILUtilities.cs` | 2 | 托管侧 |
| `PresentationCore/.../MediaContextNotificationWindow.cs` | 2 | 托管侧 |
| `PresentationCore/System/Windows/InterOp/HwndTarget.cs` | 2 | 托管侧 |
| `PresentationCore/.../StreamAsIStream.cs` | 1 | 托管侧 |
| `PresentationCore/.../EventProxy.cs` | 1 | 托管侧 |
| `WpfGfx/include/exports.cs` | 19 | **原生镜像（C++ 头，不计为托管调用方）** |
| `WpfGfx/include/wgx_exports.cs` | 28 | **原生镜像（不计）** |

⇒ **托管侧真实 MilCore P/Invoke = 110 处**（Common/Graphics 47 + PresentationCore 63）。
这 110 处 + 143 个 MILCMD 命令，即我们要 stub 掉的"最小渲染后端接口面"（见 `T1_SCOPE.md`）。

### 1.3 渲染指令流形态

- **指令容器：`RenderData`**
  - `PresentationCore/System/Windows/Media/RenderData.cs`（532 行）：注释明确"contains a data stream which is a byte array containing renderdata instructions"。字段 `_buffer`（`byte[]`，行 514）即**序列化后的渲染指令字节流**；另有 `RenderDataDrawingContext.cs` 负责把 DrawingContext 调用编码进该字节流。
  - codegen 镜像：`PresentationCore/System/Windows/Media/Generated/RenderData.cs`、`Generated/RenderDataDrawingContext.cs`。
- **指令枚举：`MILCMD`**
  - 定义：`Common/Graphics/wgx_core_types.cs:600`，**共 143 个成员**（行 600–781）。
  - 结构三段：
    1. Media Integration Layer 命令（0x01–0x3d）：通道/分区/资源/Visual/Target 管理；
    2. **Render Data 命令（0x3e–0x56）：25 条绘制原语** —— `MilDrawLine/MilDrawRectangle/MilDrawRoundedRectangle/MilDrawEllipse/MilDrawGeometry/MilDrawImage/MilDrawGlyphRun/MilDrawDrawing/MilDrawVideo`（+ Animate 变体）、`MilPushClip/MilPushOpacityMask/MilPushOpacity/MilPushTransform/MilPushGuidelineSet/MilPushEffect`、`MilPop`；
    3. MIL 资源定义命令（0x57–0x8e）：各类 Brush/Pen/Geometry/Drawing/GuidelineSet/BitmapCache 等。
- **指令发送路径**：每个 WPF 可视对象实现 `DUCE.IResource.UpdateResource(DUCE.Channel)`，在 `Channel` 上 `BeginCommand(MILCMD.xxx)` + `AppendCommandData(...)` + `Commit()`，经 `SendCommand` 写入通道字节流，由非托管 MilCore 消费。这正是替换点——我们把"通道字节流"拦截并转译为 Web 渲染指令 JSON。

> 其他相关非 MilCore 的 PresentationCore P/Invoke（非 DUCE 边界，但同属替换范围）：`WindowsCodecs`（WIC 图像解码，`DllImport.WindowsCodecs`，约 30+ 处）、`PenIMC`（`ExternDll.Penimc`，手写笔，约 16 处）、`mshwgst`（手写，约 14 处）、`ApiSetWinRT*`（WinRT 字符串，2 处）、`ole32.dll`（2 处）。

---

## 2. WindowsBase 风险量化（R1）

### 2.1 重要架构发现（纠正常见误解）

在 dotnet/wpf 当代源码中，**`WindowsBase` 程序集本体几乎没有 user32/kernel32/gdi32 P/Invoke**：

- `WindowsBase/` 下 `DllImport` 仅 **69** 处，绝大多数是：
  - `ExternDll.MsDrm`（49 处，`MS/Internal/Security/RightsManagement/PrivateUnsafeNativeMethods.cs`）—— 版权管理，与渲染/窗口无关；
  - `ExternDll.PresentationHostDll`（14 处）—— 浏览器宿主 shim；
  - `ole32.dll`（5+1 处）—— COM。
- **真正的 Win32 互操作表面在 `Shared/MS/Win32/`**（288 处），该目录被**链接进 WindowsBase 及多个程序集**，是 `HwndWrapper`/`HwndSubclass`/消息循环/输入/文本服务的实际所在地。

因此 R1 的工作量主体 = `Shared/MS/Win32/` 的 Win32 P/Invoke（进入 WindowsBase 编译单元）。

### 2.2 R1 关键类型路径

| 类型 | 路径 | 说明 |
|---|---|---|
| `Dispatcher` | `WindowsBase/System/Windows/Threading/Dispatcher.cs:20` | 消息循环/优先级队列核心（`public sealed class Dispatcher`） |
| `DispatcherSynchronizationContext` | `WindowsBase/System/Windows/Threading/DispatcherSynchronizationContext.cs:11` | SynchronizationContext 桥接 |
| `ComponentDispatcher` | `WindowsBase/System/Windows/Interop/ComponentDispatcher.cs:25` | 静态类，向 WPF 分派 Win32 消息钩子 |
| `HwndWrapper` | `Shared/MS/Win32/HwndWrapper.cs:13` | `internal class HwndWrapper : DispatcherObject` —— 创建/管理 HWND（**链接进 WindowsBase**） |
| `HwndSubclass` | `Shared/MS/Win32/HwndSubclass.cs:33` | HWND 子类化（窗口过程 WndProc 转发） |
| `MS.Win32.Message` / Win32 MSG | `Shared/MS/Win32/NativeMethods*.cs`（及 `Common/Graphics/exports.cs:288` 的 DUCE.Message 为通道消息，非 Win32 MSG） | Win32 消息结构 |
| Win32 P/Invoke 主体 | `Shared/MS/Win32/UnsafeNativeMethodsCLR.cs`(118)、`UnsafeNativeMethodsOther.cs`(55)、`SafeNativeMethodsCLR.cs`(39)、`NativeMethodsSetLastError.cs`(39)、`SafeNativeMethodsOther.cs`(10)、`NativeMethodsOther.cs`(9) … | user32/kernel32/gdi32/imm32 等 |

### 2.3 R1 P/Invoke 按目标 DLL 分组（进入 WindowsBase 编译单元，共 357 条）

> 完整逐条清单见 `winbase_pinvoke.json`。下表为按 DLL 聚合（已合并大小写/前缀变体）。

| 目标 DLL | 数量 | 性质 | Linux 替代方向 |
|---|---|---|---|
| `user32.dll` | 128 | 窗口/消息循环/输入/菜单 | 自建 X11/Wayland + 自有消息泵（R1 主体） |
| `msdrm.dll` | 49 | 版权管理（RightsManagement） | 可整体裁掉/桩占位（非 UI 必需） |
| `PresentationNative.dll` | 39 | CLR 原生支撑（MsgWaitForMultipleObjects 等 Dispatcher 等待原语） | 用 epoll/托管等待替换 |
| `kernel32.dll` | 34 | 线程/内存/文件/模块 | 大多 .NET BCL 已覆盖，少量需桩 |
| `gdi32.dll` | 18 | GDI 兼容绘制（部分文本度量） | Skia/HarfBuzz 替代 |
| `imm32.dll` | 18 | IME 输入法 | IBus/GTK IM 替代 |
| `PresentationHost.dll` | 14 | 浏览器宿主 | 可裁掉 |
| `ole32.dll` | 11 | COM | 自管 COM 轻量替代或桩 |
| `advapi32.dll` | 8 | 注册表/安全 | 桩/忽略 |
| `uxtheme.dll` | 7 | 主题 | 自有主题（默认样式） |
| `wtsapi32.dll` | 4 | 远程桌面会话 | 桩占位 |
| `urlmon.dll` | 4 | URL 下载 | BCL/HTTP 替代 |
| `msctf.dll` | 4 | 文本服务框架（TSF） | IBus 替代 |
| `oleaut32.dll` | 3 | COM 自动化 | 桩 |
| `shell32.dll` | 3 | Shell | 桩 |
| `wininet.dll` | 3 | WinInet | BCL/HTTP 替代 |
| `ntdll.dll` | 2 | 底层 | 桩 |
| `winspool.drv` | 2 | 打印 | 非 Web 必需，桩 |
| `shcore.dll` | 2 | DPI/Shell | DPI 自管 |
| `oleacc.dll` | 1 | 无障碍 | 桩 |
| `shfolder.dll` | 1 | 特殊文件夹 | 桩 |
| `winmm.dll` | 1 | 多媒体定时器 | 托管定时器 |
| `psapi.dll` | 1 | 进程/模块 | 桩 |

**按类别聚合（启发式，基于 DLL+函数名）**：
`window` 125 · `hosting_security` 111（=msdrm49+PresentationHost14+PresentationNative39，多非 R1 核心）· `os_runtime` 42 · `input_text` 32（imm32/msctf/oleacc）· `input` 22 · `com` 13 · `other` 12。

⇒ **真正构成 R1 工作量主体的"窗口/消息/输入"Win32 P/Invoke ≈ user32(128) + kernel32(34) + gdi32(18) + imm32(18) + uxtheme(7) + ole32(11) + advapi32(8) + msctf(4) + 其余少量 ≈ 230+ 条**。其中 `hosting_security` 102 条与 UI 渲染无关，可裁剪/桩，不计入核心工作量。

### 2.4 文本排版相关（Linux 替代方向）

| 类型/模块 | 路径 | 调用机制 | Linux 替代 |
|---|---|---|---|
| `DirectWriteForwarder`（原生 C++ shim） | `DirectWriteForwarder/main.cpp`（无 .cs） | 托管侧经 **COM `IDWriteFactory`** 调用，非经典 DllImport | 用 **HarfBuzz**（整形）+ **FreeType**（字形）替代 DirectWrite |
| `DWriteFactory` | `PresentationCore/MS/internal/FontCache/DWriteFactory.cs` | COM interop（`ComImport`/`IDWriteFactory`） | 同上 |
| FontCache 体系 | `PresentationCore/MS/internal/FontCache/*`（BufferCache/CachedFontFace/CachedTypeface/FontCacheLogic/FontFaceLayoutInfo…） | 调用 DWriteFactory | 字体缓存层可保留逻辑，底层换 FreeType/HarfBuzz |
| `TextFormatter` / `TextFormatterImp` | `PresentationCore/System/Windows/Media/textformatting/TextFormatter.cs`、`MS/internal/TextFormatting/TextFormatterImp.cs` | 经 DWriteFactory 排版 | **Pango** 或 **HarfBuzz + FreeType** 排版后端 |
| `GlyphRun` | `PresentationCore/System/Windows/Media/GlyphRun.cs` | ① 排版走 DirectWrite；② 上屏走 DUCE `MilCmdGlyphRunCreate`(MILCMD 0x3a) | 排版换 HarfBuzz；光栅化换 Skia（与 DUCE 后端统一） |

**结论**：文本在 WPF 中走"双路径"——**排版**（DirectWrite COM，纯 Windows，须 HarfBuzz/Pango 替代）与**光栅化/上屏**（DUCE `MilCmdGlyphRunCreate`，属渲染后端，可随 DUCE 一并换 Skia）。两部分都需在 Linux 自建等价物。

---

## 3. 可替换性判断

### 3.1 可"干净替换为 Skia 后端"的 P/Invoke（DUCE / MilCore 侧，~110 条）

全部 `DllImport.MilCore`（110 处托管）+ 渲染相关 codegen（`DUCE.Channel` 命令发送、`Composition` 资源创建、`MILCMD` 解释）。
**替换策略**：不调用 wpfgfx，而是在托管侧实现一个 **DUCE 兼容后端**——把 `Channel` 字节流（RenderData / MILCMD）拦截并翻译成 Web 渲染指令（Canvas 2D / Skia 指令）。这些调用**语义单一、边界清晰**，是替换收益最高、风险最低的部分。

### 3.2 必须"自建 Linux 等价物"的 P/Invoke（WindowsBase / Shared 侧，~230+ 条）

- **窗口/消息循环/输入**：`user32`(128)、`kernel32` 线程等待(部分)、`imm32`(18)、`msctf`(4)、`uxtheme`(7) —— `HwndWrapper`/`HwndSubclass`/`Dispatcher`/`ComponentDispatcher` 依赖之。须自建：Linux 窗口系统（X11/Wayland 或纯离屏 surface）+ 自有消息泵 + IBus 输入。
- **COM 支撑**：`ole32`(11)、`oleaut32`(3)、`PresentationNative`(39，消息等待原语) —— Dispatcher 的消息等待依赖 PresentationNative 的 `MsgWaitForMultipleObjects` 类原语，须用 `epoll`/`Task` 等待替换。
- **可裁剪/桩占位（非 UI 必需）**：`msdrm`(49)、`PresentationHost`(14)、`winspool`(2)、`urlmon`/`wininet`(7)、`shell32`/`shfolder`(4)、`wtsapi32`(4)、`oleacc`(1)、`ntdll`/`psapi`/`shcore`/`winmm` 少量 —— 直接返回占位或删除功能。

### 3.3 Web 输出映射可行性（初步）

DUCE 指令流是**序列化的、声明式绘制命令**（字节流 + 句柄引用资源树），天然可 1:1 映射为：
- 2D 原语（Line/Rect/Ellipse/Geometry/Image/GlyphRun/Clip/Opacity/Transform/Push/Pop）→ Canvas 2D / SVG / Skia；
- Visual 树 + Target → DOM 分层或单 Canvas 合成。
⇒ **可行**。难点不在"指令翻译"，而在"通道/资源生命周期/脏区重绘"的语义保真，以及 R1 窗口/输入在 Linux 的等价实现。

---

## 4. 关键路径速查（供后续 fork 直接跳转）

- DUCE 边界主类：`Common/Graphics/exports.cs:81`（`DUCE` partial，含 `Channel`/`ResourceHandle`/`IResource`）
- MilCore P/Invoke 主入口：`PresentationCore/System/Windows/Media/UnsafeNativeMethodsMilCoreApi.cs:14`
- 渲染指令枚举：`Common/Graphics/wgx_core_types.cs:600`（`MILCMD`，143 成员）
- 指令流容器：`PresentationCore/System/Windows/Media/RenderData.cs:514`（`_buffer` byte[]）
- 渲染循环：`PresentationCore/System/Windows/Media/MediaContext.cs`、`ChannelManager.cs`、`CompositionTarget.cs`、`HwndTarget.cs`
- R1 Win32 表面：`Shared/MS/Win32/`（288 处，链接进 WindowsBase）
- R1 关键类型：`WindowsBase/System/Windows/Threading/Dispatcher.cs:20`、`Shared/MS/Win32/HwndWrapper.cs:13`、`Shared/MS/Win32/HwndSubclass.cs:33`、`WindowsBase/System/Windows/Interop/ComponentDispatcher.cs:25`
- 文本：`PresentationCore/MS/internal/FontCache/DWriteFactory.cs`、`textformatting/TextFormatterImp.cs`、`Media/GlyphRun.cs`；原生 shim `DirectWriteForwarder/main.cpp`

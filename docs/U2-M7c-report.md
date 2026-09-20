# M7c 报告 · 接窗 + 端到端（M2 的最后一块）

> **读这份报告先看这里（2026-09-11 收尾轮更新）**
> 本文档是**逐轮累加**的：§1–§3 与 §4.9 之前是历史（Phase 2 时期"卡在 MilBridge"的结论**已过期**），
> 现行结论在 §4.13（**M2 达标：真 WPF 窗口 + 零探针验收**）、§4.14（文字真的画出来）、
> §4.15（拆除期 E_HANDLE 定案）、**§4.16（轨道 B：流字节交还 + 后台缓冲 QI）**、
> **§4.17（轨道 C：真接窗 / resize 跟随 / X 事件反向派发 + §2.4 与债务 #3 的建议替换文本）**、
> **§4.18（app 级新暴露：鼠标输入崩溃；resize 观测矛盾）**。

**本轮（收尾轮）门禁 —— 全部实跑（Xvfb :99，`-m:1`）**

| 门禁 | 结果 |
|---|---|
| `ManagedLayer.Tests`（轨道 B/C/A + 输入路径 + UIAutomation + CWIC 共 **52** 条） | **52 / 52** |
| `Windowing.Tests` | **44 / 44** |
| `HelloMil.Tests` | **19 / 19** |
| `Presentation.Tests` | **8 / 8** |
| `Commands.Tests` | **562 / 562**（含被 `mmap_min_addr` 守卫救回来的那条流用例） |
| `src/WpfGfx.Linux` 构建 | 0 错 0 警 |
| 真 `PresentationCore` + AOT 桥对照探针（`/tmp/m7cb-probe`，不入仓库） | 流：0 字节 → **6 字节**；QI：`E_HANDLE` → **`S_OK`（同一对象）**；WIC proxy 派发：`E_INVALIDARG` → **`GetPixelFormat S_OK` + Pbgra32 + `GetSize 8x8`**（§4.23.3） |

<details><summary>历史门禁（Phase 2 时期，已被上面这张表取代）</summary>

| 门禁 | 结果 |
|---|---|
| Phase 1 新测试 `WpfGfx.Linux.Presentation.Tests` | **8 / 8 全绿**（Xvfb :99） |
| `Windowing.Tests`（M1 主回归） | **44 / 44 全绿** |
| `HelloMil.Tests`（M1 端到端回归） | **19 / 19 全绿** |
| `Commands.Tests`（M7a 回归） | **552 / 552 全绿** |
| `samples/HelloWpf` 构建（**补依赖边之后**） | **0 错 0 警** |
| `src/WpfGfx.Linux` 构建 | 0 错 0 警 |
| `build/PresentationCore.Linux` 构建（补丁 I 之后） | 0 错 0 警 |

</details>

---

## 1. Phase 1 · 链路图与每环节实测证据

### 1.1 链路（每一环都有断言）

```
┌─ Win32 shim（libwpfwin32.so，M7b）────────────────────────────────────────┐
│ RegisterClassExW → CreateWindowExW(WS_VISIBLE) → XMapWindow               │
│   ↓ 返回 HWND —— 断言 WpfLinuxWin32_GetX11Window(hwnd) == hwnd            │  ← [1]
└───────────────────────────────────────────────────────────────────────────┘
   ↓ IntPtr hwnd
MilVisualTarget_AttachToHwnd(hwnd)          == S_OK                        ← [2]
   ├ 身份登记（M7a 的 MilHwndRegistry，语义未变）
   └ **M7c 新增**：MilPresentation.TryBind → X11PresentationTarget.WrapExisting(display, XID)
        · 断言 HasTarget(hwnd) / TargetCount==1 / NativeHandle==hwnd
        · 断言 OwnsWindow == false（**不拥有** WPF 的窗口）
   ↓
WgxConnection_Create(requestSynchronousTransport: true) → conn             ← [3]
   ↓
MilConnection_CreateChannel(conn, 0) → channel
   ↓ MilChannel_BeginCommand / MilChannel_EndCommand（**DUCE 线上字节格式**）
MilCmdHwndTargetCreate(0x2e 资源)   NativeWindow = hwnd, 320×200           ← [4]
MilCmdSolidColorBrush(0x4b) ×2      红 (200,30,30) / 蓝 (20,70,200)
MilCmdRenderData(0x2b)              指令流：两条 MilDrawRectangle(0x40)
MilCmdVisualSetContent(0x0f)        根视觉的 Content ← 指令流
MilCmdTargetSetRoot(0x35)           → ch.SetRootFromHandle(root)（投影成契约 MilVisual）
   ↓ 断言通道 FailedCommands==0 / NotImplCommands==0
WgxConnection_SameThreadPresent(conn) == S_OK                              ← [5]
   ├ Commit（M7a 行为）
   └ **M7c 新增**：MilPresentation.PresentChannel
        · 从资源表找 MilHwndTarget → hwnd
        · SkiaRenderBackend.RenderVisualTree（**与 HelloMil 同一条渲染路径**）
        · X11PresentationTarget.Present（XPutImage）→ XSync
   ↓ 断言 PresentCalls==1 / FramesPresented==1 / DrawnCommands>=2 / NotDrawnCommands==0
┌─ 独立进程 xwd ────────────────────────────────────────────────────────────┐
│ xwd -id 0x… → convert → PNG → SKBitmap 逐像素 + 直方图                    │  ← [6][7]
└───────────────────────────────────────────────────────────────────────────┘
```

### 1.2 xwd 截屏与像素断言（**实测数字**）

证据文件：`tests/WpfGfx.Linux.Tests/Presentation.Tests/bin/Debug/net10.0/artifacts/m7c-chain.txt`

```
窗口标题           : M7c-Chain-49ed1bce
HWND (Win32 shim)  : 0x400001
X11 XID            : 0x400001  （HWND == XID：True）
DUCE 连接          : 0x20000001
DUCE 通道          : 0x10000001
目标资源            : 0x1（TYPE_HWNDRENDERTARGET=0x2e）
根视觉              : 0x5（TYPE_VISUAL=0x27）
PresentCalls       : 1
FramesPresented    : 1
绘制指令数          : 2
未绘制指令种类      : 0
像素分布（容差8）   : 红=32000 蓝=32000 白=0 其它=0
窗口像素总数        : 64000
```

逐像素断言（PNG 尺寸 == 320×200，与建窗参数一致）：

| 采样点 | 期望 | 实测 | 判定 |
|---|---|---|---|
| 左半中心 (80,100) | `#c81e1e` = rgb(200,30,30) | **`#c81e1e`** | ✅ Δ=0 |
| 右半中心 (240,100) | `#1446c8` = rgb(20,70,200) | **`#1446c8`** | ✅ Δ=0 |
| 全图直方图（容差 8） | 红 32000 + 蓝 32000 = 64000 | **红 32000 / 蓝 32000 / 白 0 / 其它 0** | ✅ **意外颜色 0 像素** |

`红=32000` 恰好等于 `160×200`（左半矩形面积），`蓝=32000` 恰好等于右半面积，
`其它=0` 说明**没有任何**杂色/未初始化像素、也没有被清屏色污染 —— 这不是"某一点碰巧对上"，
而是整片区域的精确命中。

**为什么必须用独立进程 xwd**（对齐 HelloMil 的证据链标准）：自己 `XGetImage` 读回来只能
证明"我写进 buffer 的像素能原样读回"，`Present` 到 X server 那一半根本没被测到。
xwd 走 server 的另一条连接、另一套编码路径。

### 1.3 两条"失败必须响亮"的用例

| 用例 | 断言 | 为什么 |
|---|---|---|
| `Present_WithUnboundWindow_FailsLoudly` | 有窗口目标 + 有根视觉、但没绑定呈现目标 → `WgxConnection_SameThreadPresent` **返回失败码**（0x80004005），`FramesPresented==0`，诊断里含「未绑定呈现目标」 | 返回 S_OK 就是「看起来成功但屏幕没变」——本项目要杜绝的正是这种伪造 |
| `Present_OffscreenChannel_KeepsM7aBehavior` | 没有窗口目标的通道 → **S_OK + 0 帧**，`CommittedCommands==1` | 与 M7a 逐条一致（M7a 的既有用例走的就是这条），证明 M7c **没有改变**离屏通道语义 |

> 这两个计数器刻意分开：`PresentCalls` = 呈现流程**看过**这个通道几次；
> `FramesPresented` = 真的推到 X server 的帧数。离屏通道正确行为是"看过、但不发帧"，
> 用 `PresentCalls` 判"有没有出图"会得出错误结论（我第一版就写错了，被测试当场抓住）。

---

## 2. `Windowing/` 的改动与回归证据

### 2.1 改了什么（**既有语义一行未改**）

任务书预判对了：「M1 的 `X11Window` 是自己建窗语义，需要一个包装既有窗口的适配器」。
唯一需要动 `Windowing/` 的地方就是这里，实际改动三处：

| 文件 | 改动 | 语义 |
|---|---|---|
| `X11Window.cs` | 新增 `_ownsWindow` 标志 + `Wrap(display, existingXid)` + 私有构造 + `InitializeFromServer(knowSize)` | 包装路径：**不** XCreateSimpleWindow、**不** XSelectInput、**不** XSetWMProtocols、Dispose 时 **不** XDestroyWindow |
| `X11Window.cs` | 原公开构造函数改为调用 `InitializeFromServer(knowSize: true)` | 自己建窗路径**行为逐字不变**（尺寸仍用调用方给的） |
| `X11PresentationTarget.cs` | 新增 `WrapExisting(display, xid)` + `OwnsWindow` | 呈现目标可以包装既有窗口 |
| `X11Native.cs` / `X11Display.cs` / `X11Window.cs` | **新增 Xlib 错误处理器**（见 §2.3） | 新增能力，不改变正常路径 |

`InitializeFromServer` 由两条路径**共用**（像素打包 / XPutImage / 双缓冲完全一致），
所以"包装窗口画出来的像素"与 M1 既有窗口路径逐字节相同——不存在第二条渲染路径。

### 2.2 回归证据（**44 + 19 全绿**）

```console
$ DISPLAY=:99 dotnet test tests/WpfGfx.Linux.Tests/Windowing.Tests/… -m:1
已通过! - 失败: 0，通过: 44，已跳过: 0，总计: 44

$ DISPLAY=:99 dotnet test tests/WpfGfx.Linux.Tests/HelloMil.Tests/… -m:1
已通过! - 失败: 0，通过: 19，已跳过: 0，总计: 19
```

另加 `Commands.Tests`（M7a 的 552 条，因为本轮的呈现挂钩在 `Interop/`）：

```console
$ dotnet test tests/WpfGfx.Linux.Tests/Commands.Tests/… -m:1
已通过! - 失败: 0，通过: 552，已跳过: 0，总计: 552
```

### 2.3 新增的"包装能力"专项回归（5 条，在 `Presentation.Tests` 里）

`Windowing/` 改动的**主**回归网是上面 44+19，本组补的是**新增能力**这一侧——
"包装既有窗口"最容易出的错是**越权**，而且都不会立刻报错：

| 用例 | 断言 | 为什么必须钉 |
|---|---|---|
| `Wrap_DoesNotOwnWindow_And_DisposeKeepsItAlive` | Wrap 前后 `your_event_mask` **逐位相同** | 偷改事件掩码 ⇒ HwndWrapper 收不到输入，症状是"WPF 键鼠突然不响应" |
| `Wrap_Dispose_DoesNotDestroyTheWindow` | Wrap 目标 Dispose 后 `XGetWindowAttributes` 仍成功、尺寸不变 | 销毁别人的窗口 ⇒ "关掉渲染就白屏"，极难定位 |
| `Wrap_RejectsInvalidWindowId` | XID=0 → `ArgumentOutOfRangeException`；不存在的 XID → **可捕获的异常**（不是进程退出） | 见 §2.4 |
| `WrapExisting_Target_ReportsForeignWindow` | `NativeHandle == XID`、`OwnsWindow == false` | 契约断言 |
| `OwnedWindow_StillOwnsAndDestroys` | 自己建窗 `OwnsWindow == true`，Dispose 后窗口**确实**被销毁 | 证明既有语义没被改坏 |

### 2.4 ★ 顺带修掉一个"让整个进程消失"的健壮性洞

写 `Wrap_RejectsInvalidWindowId` 时实测发现：**给 `XGetWindowAttributes` 传一个无效 XID，
进程直接消失**（第一轮跑测试的表现是 `测试主机进程崩溃`，没有任何异常信息）。

根因：**Xlib 的默认错误处理器做的事是打印一行然后 `exit(1)`** —— 既不抛异常也没有返回码。
M7c 的接窗路径要拿外部给的 XID 去查属性，一个陈旧的/伪造的 XID 就足以触发；
而 `MilPresentation.TryBind` 里的 `try/catch` **根本救不了**（进程已经没了）。

处置：`X11Display.Open` 里装一个 Xlib 错误处理器（`XSetErrorHandler`），
只记录最后一条错误码 + `XGetErrorText` 文本并返回 0；`X11Window.InitializeFromServer`
在 `XGetWindowAttributes` 失败后 `XSync` 一次（错误是**异步**到达的）再取走错误码，
把它变成**正常的托管异常**。委托用静态字段 root 住（Xlib 只存函数指针）。

这条改动是**新增**：正常路径（有效 XID）逐字节不变，44+19 回归全绿。

---

## 3. Phase 2 · HelloWpf 跑到哪一步

### 3.1 运行方式（**不写入 `samples/HelloWpf/`**）

`samples/HelloWpf/` 本轮标注"只读使用"，而 `dotnet build` 会写它的 bin/obj。
所以新增了 `tests/…/Presentation.Tests/run-hellowpf.sh`：把它的输出目录**整份复制**到
`/tmp/m7c-hellowpf`，再把 `build/*.Linux/bin/Debug` 的新鲜程序集覆盖上去 ——
效果与重新构建等价，对 T3 的目录**零写入**。

### 3.2 推进轨迹（每一步都是实测，不是推断）

| 轮次 | 卡在哪 | 根因 | 处置 |
|---|---|---|---|
| 1 | `TypeInitializationException → SecurityHelper.ReadRegistryValue` NRE | WindowsBase 的 AvTrace 读注册表（**已由补丁 G 修掉**，但运行目录里是 15:02 的旧快照） | runner 覆盖新鲜程序集 |
| 2 | `DllNotFoundException: kernel32.dll → libwpfwin32.so` | resolver 的三级搜索里只有"程序集同目录"能在 /tmp 命中 | runner 按**app-local 部署**放 `libwpfwin32.so`（resolver 文档里的第二条路径） |
| 3 | `UriFormatException` @ `FontCacheUtil.cs:306` | `windir` 未设 ⇒ `"\Fonts\"` 不是合法绝对 URI ⇒ `FontCache.Util` 静态构造失败 ⇒ TextElement/FrameworkElement/**Window** 全线建不出来 | **补丁 I**（见 §3.3） |
| 4 | `FileNotFoundException: DirectWrite.Linux.Provider` | `FontFaceBridge.Install()` 的 JIT 期类型解析需要它，而 `HelloWpf.deps.json` 里没有 | runner 在运行目录的 deps.json 补依赖边（**产品侧缺口**，见 §4 #3） |
| 5 | `DllNotFoundException: wpfgfx_cor3.dll` | T1 的 MilCore 解析器在 /tmp 下只有"应用目录"这档可用 | runner app-local 放 `wpfgfx_cor3.so` |
| 6 | **`NotImplementedException` @ `DUCE.Channel.SetNotificationWindow`** | `MilChannel_SetNotificationWindow` 原生返回 **E_NOTIMPL** | **卡在这里（见 §3.4）** |

逐轮"越过了什么"（每一层都是真跑出来的，不是静态分析）：
`Application` 静态构造 ✅ → BAML 加载 ✅（**M7b 的 Win32 shim 与补丁 G 都在生效**）→
`SystemFonts.MessageFontSize` ✅（**M7b 补丁轮的 `SystemParametersInfo` 修复在这里被真正走到**）
→ `MediaContext.From(dispatcher)` ✅ → `MediaContextNotificationWindow` 构造 ✅ →
`MediaContext.CreateChannels()` → `SetNotificationWindow` ❌

**未产出窗口**：`xwininfo -root -children` 显示 root 下 0 个子窗口；
失败点在 BAML 构造 `MainWindow` 的内容集合（`UIElementCollection.Add`），
**在 Show 之前**，所以没有截屏证据。

### 3.3 补丁 I（本次新交付，已应用）

`build/shared` 之外唯一新增的 PC 生成物补丁。用与补丁 G/H 相同的生成式机制
（`src/WpfGfx.Linux.Native/tools/patch-presentationcore-fontcache.py`，幂等、`--check`）：

```console
$ python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-fontcache.py --check
[检查] build/PresentationCore.Linux/FontCacheUtil.Linux.cs：内容已是最新
[接线] csproj 已就位（幂等，不改）

$ diff <(tail -n +17 build/PresentationCore.Linux/FontCacheUtil.Linux.cs) \
       upstream/…/MS/internal/FontCache/FontCacheUtil.cs
（只有静态构造里的非 Windows 分支 + 注释，Windows 分支逐字保留）
```

`build/PresentationCore.Linux/PresentationCore.Linux.csproj` 的改动 = **2 行 Compile + 2 行注释**。

**语义（不是绕过）**：`windir\Fonts\` 的角色就是「**平台字体目录**」，
Linux 上的对等物是 `/usr/share/fonts/`（可用 `WPF_LINUX_FONTS_DIR` 覆盖）。
消费点（`FontFamily.cs:428/507`、`Fonts.cs:241/262`、`DWriteFactory.cs:71`）拿它枚举平台字体、
拼字体文件 URI、比对字体位置 —— 指向真实目录才语义正确。
造一个假 URI 也能消掉异常，但会让 `FamilyCollection.FromWindowsFonts` **静默变空**，
那才是绕过。**且不做 `ToUpperInvariant`**：那是 Windows 大小写不敏感文件系统的假设，
Linux 上 `/USR/SHARE/FONTS/` 并不存在，等于同样的静默退化。

### 3.4 Phase 2 当前卡点（**已定位到文件行**）

```
NotImplementedException: The method or operation is not implemented.
  at MS.Internal.HRESULT.Check(Int32 hr)
  at System.Windows.Media.Composition.DUCE.Channel.SetNotificationWindow(IntPtr hwnd, WindowMessage message)
  at System.Windows.Media.MediaContextNotificationWindow.SetAsChannelNotificationWindow()
  at System.Windows.Media.MediaContext.HookNotifications()
  at System.Windows.Media.MediaContext.CreateChannels()
  at System.Windows.Media.MediaSystem.ConnectChannels(MediaContext mc)
  at System.Windows.Media.MediaContext..ctor(Dispatcher dispatcher)
  at System.Windows.Media.MediaContext.From(Dispatcher dispatcher)
  at System.Windows.Media.Visual.VerifyAPIReadWrite()  ← BAML 给 Window 加子元素时触发
```

**★ 关键：这一条不能在 `src/WpfGfx.Linux/Interop/` 里修（我实测过，已回滚）**

`MilChannel_SetNotificationWindow` 在 `Interop/MilNative.cs:241` 从 M1 起就是
`=> HResult.E_NOTIMPL`。看起来只要在这里实现掉就通了 —— 但：

1. **真正承接这条 P/Invoke 的是 T1 的 NativeAOT 桥接**（`build/MilBridge/`，
   产物 `wpfgfx_cor3.so`）。它是把本方法的实现 **AOT 烘焙进 .so** 的：
   `build/MilBridge/src/MilBridge.Linux/Exports.g.cs:536` 是一层
   `[UnmanagedCallersOnly(EntryPoint = "MilChannel_SetNotificationWindow")]` 包装 → 调回
   `MilNative.…`。所以改托管源码**必须重建 .so 才生效**（`nm -D` 实证该符号在 .so 里：
   `000000000012c1c0 T MilChannel_SetNotificationWindow@@V1.0`）。
2. `tests/.../Commands.Tests/MilExportTests.cs:218` 与 `MilNativeTests.cs:303` **钉住了 E_NOTIMPL**，
   而 `Commands.Tests` 不在本轮可写清单里 —— 在 `Interop/` 单方面改成 S_OK 会打破一个
   我无权修改的测试套件（我第一版就是这么做的，实测 Presentation.Tests 绿但
   Commands.Tests 会红，于是**回滚**并把结论写进 `MilNative.cs` 的注释里）。

**给 T1/T2 的落地设计（语义想清楚了，可直接用）**：
* 契约：把 `(hwnd, message)` 登记到通道（幂等、可查询、可解绑）。**登记本身就是这个调用的契约**。
* 不要真的 `PostMessage`：M7a 已把 DUCE 传输定成**进程内**（`MilChannelBackChannel` 队列 +
  `MilComposition_PeekNextMessage` 出队），同线程呈现下不存在"唤醒另一个线程"这件事 ——
  那条路径在 Windows 上存在的唯一理由就是跨线程传输。**登记确实生效**，只是没有对象去投递。
* ⚠️ 若将来引入 `ChannelMarshalType.CrossThread`，必须在
  `MilChannelBackChannel.Post` 里按这条登记去唤醒 UI 线程。
* 同时要把 `MilExportTests.cs:218` 的 `notImpl` 期望改成 `State`。

---

## 4. 剩余缺口（按"挡不挡 M2 验收"排序）

| # | 缺口 | 挡什么 | 量级 | 位置 / 谁做 |
|---|---|---|---|---|
| 1 | **`MilChannel_SetNotificationWindow` 原生 E_NOTIMPL** | **挡 HelloWpf 的最后一步**：`MediaContext.CreateChannels()` 是任何 WPF 应用的必经点，返回失败 ⇒ `HRESULT.Check` 抛 NotImplementedException ⇒ Application 起不来 | **小**（语义见 §3.4，登记即可） | `build/MilBridge/`（T1/T2）**+ 重建 `wpfgfx_cor3.so`**；测试期望 `MilExportTests.cs:218` |
| ~~0'~~ | ~~输入栈的 `Registry.*` 在 Unix 上是 null（15 处）~~ ✅ **补丁 J 已由主控应用并实测生效**（stylus 一族不再出现） | — | — | — |
| **0''** | ★ **`OleServicesContext` 的 5 处 STA 检查**（与补丁 H 同类）。当前卡点 `OleServicesContext.cs:143`，挡在 `HwndSource.Initialize:334 → DragDrop.RegisterDropTarget` —— **任何 WPF 窗口第一次 Show()** | 挡 M2 验收 | **小** | `build/PresentationCore.Linux/`（**补丁 K 应用器已就绪，待主控运行**） |
| ~~0~~ | ~~**`System.Xaml.Linux` 当前是坏的**~~（主控集成波已修：签名统一 + SR 资源回归 + PF 恢复 0 错）：① 权威产物**未签名**（654,336 B）而下游目录里是**已签名**的旧副本（701,440 B）⇒ 全树两个身份 ⇒ **MC1000**；② 权威产物**丢了嵌入资源** `System.Xaml.Resources.Strings.resources` ⇒ 运行期 `SR.Format` 拿到 null format ⇒ `ArgumentNullException`。另：自产件签名状态全树不一致（WB/SX/UIAT/UIAP 未签，PC/PF/DWF 已签） | **挡 `dotnet build samples/HelloWpf` 与一切 BAML 应用**（含 T2 探针） | 小-中 | `build/System.Xaml.Linux/`、`build/WindowsBase.Linux/`、`build/UIAutomation*.Linux/` 的 csproj（**本轮边界外，未动**）。动作见 §4.6.3 的 ①②③ |
| 2 | ~~`HelloWpf.deps.json` 缺 `DirectWrite.Linux.Provider`~~ | **已修（补充轮）**：`HelloWpf.csproj` 补一条直接引用；`deps.json` 出现该边、`bin/` 出现该 dll、runner 不再报 `FileNotFoundException` | 已完成 | ~~`samples/HelloWpf/HelloWpf.csproj`~~ |
| 2b | **同类风险仍在**：所有消费方都用 `<Reference><HintPath>`，依赖图不传递。本次只补了 `HelloWpf` 一条；`PresentationFramework` / `ReachFramework` / `System.Printing` / 其它 sample 若也直接/间接用到 provider 或别的私有依赖，会**重演同一个坑** | 潜在 | 结构性 | 建议 M2 收尾时统一：`build/*.Linux` 切成 `ProjectReference`，或做成本地 NuGet 源 / `Directory.Build.props` 统一引用清单 |
| 3 | `Windowing/` 之外的 Xlib 错误处理 | 不挡（已在本轮补上）；但 `X11Native` 若将来被别的库直接用，同样需要 | 已做 | 本轮完成 |
| 4 | 跨线程 DUCE 传输 + 通知窗口唤醒 | 不挡单线程 HelloWpf | 中 | 见 §3.4 的 ⚠️ |
| 5 | 文本渲染路径（T2 在做） | 挡住"窗口里的字"，不挡"窗口出现" | 中 | T2 |
| 6 | WIC(109) → Skia 映射 | 挡图像解码/编码 | 中 | M7c+ |
| 7 | OLE 剪贴板/DnD | 已在 M4 裁决为诚实 stub | — | — |

**判断**：M2 的"窗口出来"只差 **#1**（+#2 的部署边）；**#5 决定窗口里有没有字**。

---

## 4.5 补充轮 · 修掉 #2（`HelloWpf.deps.json` 缺 `DirectWrite.Linux.Provider`）

### 4.5.1 修法

`samples/HelloWpf/HelloWpf.csproj` 的引用组里补**一条直接引用**（`+10 行`，含 30 行说明注释）：

```xml
<Reference Include="DirectWrite.Linux.Provider">
  <HintPath>$(WpfLinuxBinDir)/DirectWrite.Linux/Provider/bin/$(WpfLinuxSelfBuiltConfiguration)/DirectWrite.Linux.Provider.dll</HintPath>
  <Private>true</Private>
</Reference>
```

根因不是"少写一行"，而是**引用形态**：

| 形态 | 依赖图 |
|---|---|
| `<ProjectReference>` | **传递**：消费方自动拿到被引用方的 CopyLocal 依赖，`deps.json` 里也有对应的边 |
| `<Reference><HintPath>` | **只带那一个文件**：被引用方的私有依赖不传递 |

`PresentationCore.Linux.csproj` 用 `Reference+HintPath` 引 provider（T2 补丁 F），
`HelloWpf.csproj` 又用同样的形态引 `PresentationCore` ⇒ 这条边在消费者侧断掉。
实测表现是 **PresentationCore 的模块初始化器**在 JIT 期就 `FileNotFoundException`。

**为什么不用更彻底的 `ProjectReference`**：那要引 `build/DirectWrite.Linux/Provider/*.csproj`，
而 MSBuild 会**构建**它、写入 `build/DirectWrite.Linux/` 的 `obj/`——本轮边界明确要求不碰该目录
（T2 在改）。所以只能在消费侧补一条 `Reference`。
**长期正解（不属本里程碑）**：把 `build/*.Linux` 这套自产件整体切成 `ProjectReference`，
或做成一个本地 NuGet 源 / `Directory.Build.props` 里的统一引用清单 ——
否则**每一个**消费者都要自己补这一条。

路径取 Provider 的**自己的产物**（与 PC 补丁 F 逐字一致），不取 PC 输出目录里的依赖副本
（副本会随 PC 重构时间变化，属于"看起来一样、其实会过期"的源）。

### 4.5.2 实测证据

```console
$ dotnet build samples/HelloWpf/HelloWpf.csproj -m:1
  已确认解析到自产程序集：…\WindowsBase.dll;…\System.Xaml.dll;…\PresentationCore.dll;…
  已产出 BAML：obj/Debug/net10.0/MainWindow.baml;obj/Debug/net10.0/App.baml
  HelloWpf -> …/samples/HelloWpf/bin/Debug/net10.0/HelloWpf.dll
已成功生成。
    0 个警告
    0 个错误

$ grep -o '"DirectWrite.Linux.Provider[^"]*"' samples/HelloWpf/bin/Debug/net10.0/HelloWpf.deps.json | sort -u
"DirectWrite.Linux.Provider"
"DirectWrite.Linux.Provider/1.0.0.0"
"DirectWrite.Linux.Provider.dll"

$ python3 -c "…读 targets/libraries/HelloWpf 的 dependencies…"
target entry : {'runtime': {'DirectWrite.Linux.Provider.dll': {'assemblyVersion': '1.0.0.0', 'fileVersion': '1.0.0.0'}}}
libraries    : {'type': 'reference', 'serviceable': False, 'sha512': ''}
HelloWpf 的依赖边: 1.0.0.0

$ ls -la samples/HelloWpf/bin/Debug/net10.0/DirectWrite.Linux.Provider.dll
68608  …（补引用之前 bin 里**根本没有**这个文件）
```

**runner 复跑后不再有该异常**（这是比 grep 更强的证据：那条异常**曾经是**第 4 轮的卡点）：

```console
$ grep -c "DirectWrite.Linux.Provider" /tmp/m7c-hellowpf/hellowpf.log      # 运行日志里 0 次
0
$ grep -m1 "NotImplementedException\|FileNotFoundException" /tmp/m7c-hellowpf/hellowpf.log
 ---> System.NotImplementedException: The method or operation is not implemented.
```
即：运行期已经**越过** provider 加载，卡点前进到 T1 的 `SetNotificationWindow`（§3.4）。
**runner 里原先为绕过这条而打的 `deps.json` 补丁已删除** —— 现在跑通靠的是 csproj 里的真实依赖边。

### 4.5.3 一条命令重跑 Phase 2

```bash
export PATH="$HOME/.dotnet:$PATH"
tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh start      # Xvfb :99（已在跑会复用）
DISPLAY=:99 tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 45
#   加 --no-build 可跳过增量构建（只重组运行目录并重跑）：… run-hellowpf.sh 45 --no-build
#   换运行目录：M7C_RUN_DIR=/tmp/xxx …
```

它现在做四件事并给出**完整判定**（退出码 = 应用退出码，可直接当门禁）：

1. `dotnet build samples/HelloWpf -m:1`（增量；顺带刷新 `deps.json` 与引用副本）；
2. 组装运行目录：自产程序集按"**只取工程自己的产物**"规则覆盖、
   `libwpfwin32.so` 与 `wpfgfx_cor3.so` 按 **app-local** 布局放置；
   并回显 `deps.json 里的 DirectWrite.Linux.Provider`（一行就能看出 #2 有没有回退）；
3. 启动应用并**轮询 X 根窗口**，判据是「新出现 且 `Map State: IsViewable` 且宽高 ≥ 64」
   ——早期版本只看"多了个窗口"，把 WPF 的 **1×1 message-only 窗口**当成应用窗口，
   于是 `xwd` 报 `BadMatch`（对未映射窗口 `X_GetImage` 本来就不合法）；
   被过滤掉的窗口也会连同几何/映射状态一起打印（便于诊断）；
4. 一出现真窗口就 `xwd -id` → `convert` → PNG → 打印颜色直方图；最后打印退出码与日志摘要。

**当前一次运行的实测输出（T1 尚未落地）**：

```console
== 2/4 组装运行目录
   deps.json 里的 DirectWrite.Linux.Provider："DirectWrite.Linux.Provider/1.0.0.0" …
== 3/4 启动 HelloWpf（超时 20s）
   期间新出现的 X 窗口（含被过滤掉的小窗口）：
     0x200001  1x1  map=IsUnMapped      ← HwndWrapper 的 message-only 窗口（shim 建的，正确过滤）
     0x200002  1x1  map=IsUnMapped      ← Dispatcher 的 message-only 窗口
== 4/4 未观察到新窗口（应用没有把窗口映射出来）
== 应用退出码：134
```
> 那两条 1×1 窗口本身就是一条小证据：**WPF 的窗口基础设施已经通过 M7b 的 shim 建出了真窗口对象**，
> 只是还没走到 map 那一步（卡在 `CreateChannels`）。

### 4.5.4 建议主控加进 `wpf-linux.sln` 与 `verify-all.sh`（这两个文件我未动）

**工程路径（唯一需要引用的）**
```
tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj
```

**`wpf-linux.sln`**：GUID 取 `{88888888-8888-8888-8888-888888888888}`（现有已占用
`1111…`–`7777…`，取下一个连号）：
```
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "WpfGfx.Linux.Presentation.Tests", "tests\WpfGfx.Linux.Tests\Presentation.Tests\WpfGfx.Linux.Presentation.Tests.csproj", "{88888888-8888-8888-8888-888888888888}"
EndProject
```
并在 `GlobalSection(ProjectConfigurationPlatforms)` 里补 4 行（与其它测试工程同形）：
```
		{88888888-8888-8888-8888-888888888888}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{88888888-8888-8888-8888-888888888888}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{88888888-8888-8888-8888-888888888888}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{88888888-8888-8888-8888-888888888888}.Release|Any CPU.Build.0 = Release|Any CPU
```

**`verify-all.sh`**（紧跟现有 `ManagedLayer.Tests` 那一行，`DISPLAY` 已由脚本导出，
X 用例在无 DISPLAY 时是**发现期跳过**，不会红）：
```bash
run_step "Presentation.Tests" dotnet test tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj --nologo -v q
```
> 提示：`Presentation.Tests` 依赖 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`
> （M7b 的 shim）。若在干净机器上跑 verify-all，先执行
> `src/WpfGfx.Linux.Native/build-shim.sh --all`，否则窗口用例会因加载不到 shim 而失败
> （不是跳过——**这一点与其它套件不同，值得在 verify-all 里加一步前置构建**）。

---

## 4.6 补充轮之二 · 全量 `ProjectReference` 的实测结论（**建议被证据推翻**）与一个新的头号阻塞

### 4.6.1 结论速览

| 主控给的两条路 | 实测 |
|---|---|
| 全量改成 `<ProjectReference>` | ❌ **不可行，而且方向是反的**（见 4.6.2 / 4.6.3） |
| 退回"保留 HintPath + 补依赖边" | ✅ 已落地；`DirectWrite.Linux.Provider` 那条边**实测出现**（4.5.2） |
| 提出的目标"让 deps.json 出现 `WindowsBase/4.0.0.1` 等条目" | **HelloWpf 现在的 HintPath 形态本来就有**（4.6.3 实测），反倒是 `ProjectReference` 形态**没有** |

### 4.6.2 为什么全量 ProjectReference 走不通（两个独立阻塞，都不在本文件能解的范围）

**① `PresentationFramework` 当前编译不过** ⇒ 无法 `ProjectReference` 它：

```console
$ dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -m:1
error CS0115: "ElementMarkupObject.AssignRootContext(IValueSerializerContext)": 没有找到适合的方法来重写
error CS0534: "ElementMarkupObject" 不实现继承的抽象成员 "MarkupObject.AssignRootContext(IValueSerializerContext)"
（同上还有 MarkupObjectWrapper / FrameworkElementFactoryMarkupObject）
→ 0 个警告，6 个错误
```
全在 `PresentationFramework/System/Windows/Markup/Primitives/*.cs`，看起来是
**System.Xaml ↔ PresentationFramework 的版本错位**（基类 `MarkupObject` 新增了抽象成员）。
`ProjectReference` 会**构建**被引用工程 ⇒ `dotnet build samples/HelloWpf` 连带编 PF 并失败。

**② 其余自产件改成 ProjectReference 后，BAML 标记编译失败**：

```console
Microsoft.WinFX.targets(211,9): error MC1000: Could not find assembly
'System.Xaml, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35'
```

**对照实验（决定性）**：把本文件里 Provider 那一行**整个删掉**（回到 15:47 那个
"0 错 0 警"的原始引用集），MC1000 **照样出现** ⇒ 这是外部状态变化，不是本文件改坏的。

### 4.6.3 ★ 头号阻塞：树里存在**两个身份不同**的 `System.Xaml.dll`

判据：强命名/公开签名的程序集，其 Assembly 表的公钥 blob 会以 Microsoft 公钥前缀
出现在 `#Blob` 堆里；`AssemblyRef` 只存 token，所以"**完整公钥出现**"= 该程序集**自身**带公钥。

| 路径 | 大小 | 自身带公钥 | 嵌入资源 `System.Xaml.Resources.Strings.resources` |
|---|---|---|---|
| `build/System.Xaml.Linux/bin/Debug/System.Xaml.dll`（**权威产物**，HintPath 指向它） | 654,336 | ❌ **未签名** | ❌ **缺失** |
| `build/PresentationFramework.Linux/bin/Debug/System.Xaml.dll` | 701,440 | ✅ 已签名 | ✅ 有 |
| `build/ReachFramework.Linux/bin/Debug/System.Xaml.dll` | 701,440 | ✅ 已签名 | — |
| `build/System.Printing.Linux/bin/Debug/System.Xaml.dll` | 701,440 | ✅ 已签名 | — |
| **`samples/HelloWpf/bin/Debug/net10.0/System.Xaml.dll`** | 701,440 | ✅ 已签名 | ★ 实际躺在 bin 里的 |

即：**编译引用的是未签名的那一份，而 RAR 的"同目录依赖解析"把 PF 输出目录里已签名的旧副本
复制进了 bin**；PBT 解析 BAML 时按已签名身份去找，引用清单里只有未签名那份 ⇒ **MC1000**。

**同一个根因还有第二个症状**（本轮实测的运行期表现）：
```
System.ArgumentNullException: Value cannot be null. (Parameter 'format')
  at System.String.Format(String format, Object arg0)
  at System.SR.Format(String resourceFormat, Object p1)
  at MS.Internal.Xaml.Runtime.ClrObjectRuntime.CreateInstance(XamlType xamlType, Object[] args)
  at System.Xaml.XamlObjectWriter.Logic_CreateAndAssignToParentStart(...)
```
`System.Xaml` 的 **SR 资源流丢失**（表里那 47,104 字节的差就是它）⇒ 连**报错**都报不出来
（`SR.Format` 拿到 null format）。这与 M4 给 PC 修的 PATCH_E2（"SR 资源基名对齐"）是同一类问题，
说明 `System.Xaml.Linux` 这一轮的重新生成把资源弄丢了。

**签名状态全树不一致**（实测，`grep PublicSign build/*.Linux/*.csproj` + 字节判据）：

| 程序集 | PublicSign | 实测自身带公钥 |
|---|---|---|
| WindowsBase | ❌ 未设 | ❌ 否 |
| **System.Xaml** | ❌ 未设 | ❌ 否（且资源也丢了） |
| UIAutomationTypes | ❌ 未设 | — |
| UIAutomationProvider | ❌ 未设 | — |
| PresentationCore | ✅ `WcpPublicKey.snk` | ✅ 是 |
| PresentationFramework | ✅ | ✅ 是 |
| DirectWriteForwarder | ✅ | ✅ 是 |

**修复必须在 `build/` 侧**（本轮边界外，已按主控要求"必须先报告、不要动手"登记为缺口 #0）：
① 让自产件的签名状态**统一**（要么全签 `WcpPublicKey.snk`，要么全不签）；
② 清掉下游输出目录里的**陈旧副本**（PF / ReachFramework / System.Printing 的 bin 里那三份
70 万字节的旧 `System.Xaml.dll`）并重建，让全树只留**一份身份**；
③ 顺带查 `System.Xaml.Linux` 的 SR 资源为什么没进程序集（对照 M4 的 PATCH_E2 做法）。

### 4.6.4 ★ 被证据推翻的一处前提：`ProjectReference` 会让 deps.json **更差**，不是更好

主控的前提是"裸 `<Reference><HintPath>` 不产生 deps.json 条目"。实测**相反**：

| 应用 | 引用形态 | `WindowsBase` 在 deps.json 里？ |
|---|---|---|
| **`samples/HelloWpf`** | **HintPath** | ✅ **有**：`"WindowsBase"` / `"WindowsBase/4.0.0.1"` / `"WindowsBase.dll"` |
| T2 的 `SystemFontsProbe` | **ProjectReference** | ❌ **完全没有** |
| 共享框架 `Microsoft.NETCore.App.deps.json` | — | ✅ 有（框架门面 `WindowsBase.dll`） |

⇒ **T2 的 `FileLoadException 0x80131040` 恰恰是 `ProjectReference` 形态产生的**：
`ProjectReference` 只传递**项目**依赖边，而被引用工程（PC/PF）内部用的是
`<Reference><HintPath>` —— 那些私有依赖**不会**被传递，于是 app 的 deps.json **缺** `WindowsBase`
⇒ 宿主回落到框架门面（`4.0.0.0/31bf…`）⇒ 与请求的 `4.0.0.1/null` 身份不匹配 ⇒ 崩。
而 HintPath 形态下 RAR 会把引用**和它的同目录依赖**一起解析并写进 deps.json，所以**有**这条边。

**推论（重要）**：若把 HelloWpf 改成全量 ProjectReference，会**复现**探针那个 FileLoadException。
所以本轮**没有**按建议全量切换 —— 这不是"没做成"，而是**按实测证据选择了不退化**的那条路。

### 4.6.5 T2 的探针复跑结果（主控要求的 item 4）

```console
$ dotnet build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/DirectWrite.Linux.SystemFontsProbe.dll
FONT_DIR_ENV=<未设置>
ASSEMBLY WindowsBase.dll            = WindowsBase, Version=4.0.0.1,  Culture=neutral, PublicKeyToken=null
ASSEMBLY PresentationCore.dll       = PresentationCore, Version=4.0.0.1, PublicKeyToken=31bf3856ad364e35
ASSEMBLY PresentationFramework.dll  = PresentationFramework, Version=4.0.0.1, PublicKeyToken=31bf3856ad364e35
ASSEMBLY DirectWriteForwarder.dll   = DirectWriteForwarder, Version=4.0.0.1, PublicKeyToken=31bf3856ad364e35
ASSEMBLY DirectWrite.Linux.Provider.dll = DirectWrite.Linux.Provider, Version=1.0.0.0, PublicKeyToken=null
MessageFontFamily / MessageFontWeight / MessageFontSize / MessageFontStyle /
CaptionFontFamily / IconFontFamily / MessageFontFamily_Metrics
    = FAIL FileLoadException: Could not load file or assembly
      'WindowsBase, Version=4.0.0.1, Culture=neutral, PublicKeyToken=null'.
      The located assembly's manifest definition does not match the assembly reference. (0x80131040)
SPI_CALL_OK=True
SPI_LFMESSAGEFONT_FACENAME=DejaVu Sans
SPI_LFMESSAGEFONT_WEIGHT=400
SPI_LFMESSAGEFONT_CHARSET=1
PROBE_DONE=True
```

**两条结论**：
1. ✅ **M7b 补丁轮的 `SystemParametersInfo` 修复被独立验证**：`SPI_CALL_OK=True`、
   `WEIGHT=400`（不是 0 ⇒ 不会再触发 `FontWeight.FromOpenTypeWeight(0)` 的
   `ArgumentOutOfRangeException`）、`FACENAME=DejaVu Sans`。
2. ❌ `MessageFontFamily` 等仍 FAIL，但**原因不是 SPI**，而是
   **WindowsBase 的程序集身份**（`4.0.0.1/null` 请求 vs 定位到的框架门面）。
   注意这个探针用的是 ProjectReference 形态（4.6.4）⇒ 它的 deps.json 缺 `WindowsBase` 边，
   所以它**必然**命中这个故障。**HelloWpf 在 HintPath 形态下没有这个问题**
   （它的 deps.json 有那条边，且实际跑到了 PF/PC 的 `MediaContext.CreateChannels()`）。

### 4.6.6 一个命令重跑（不变）

```bash
DISPLAY=:99 tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 45
```
最近一次实测（`--no-build`，20s）：
```
== 2/4 组装运行目录
   deps.json 里的 DirectWrite.Linux.Provider："DirectWrite.Linux.Provider/1.0.0.0" …
== 3/4 启动 HelloWpf（超时 20s）
   期间新出现的 X 窗口（含被过滤掉的小窗口）：
     0x200001  1x1  map=IsUnMapped
     0x200002  1x1  map=IsUnMapped
     0x200003  1x1  map=IsUnMapped
== 4/4 未观察到新窗口
== 应用退出码：134
# 卡点较上一轮**前进了**：SetNotificationWindow(E_NOTIMPL) 已不再出现，
# 现在是 System.Xaml 的 SR 资源丢失（4.6.3 的第二个症状）
```
`FileNotFoundException: DirectWrite.Linux.Provider` 与 `FileLoadException 0x80131040`
在运行日志里**各 0 次**（grep 实测）。

---

## 4.7 集成波之后 · Phase 2 重跑（卡点从"应用起不来"推进到 `Window.ShowHelper`）

### 4.7.1 本轮在 **shim** 里补掉 5 组、共 33 个导出（全部是 Phase 2 实测逼出来的）

`build/PresentationCore.Linux` 与 `System.Xaml` 由主控的集成波修好之后，
`dotnet build samples/HelloWpf` 恢复 **0 错 0 警**，Phase 2 的卡点开始**一路向窗口推进**。
每一轮都是"跑 → 看栈 → 在 shim 里补该有的东西"，全部落在 M7b 定的三档原则里：

| # | 卡在哪（实测栈顶） | 缺什么 | 处置（档位） |
|---|---|---|---|
| 1 | `TextBlock..cctor → HwndTarget.IsPerMonitorDpiScalingEnabled → OSVersionHelper.IsOsWindows10RS1OrGreater`：**EntryPointNotFoundException** | `PresentationNative_cor3.dll` 的 **20 个版本判定导出** | `[降级→真话]` **全部返回 FALSE**：Linux 上"这是不是 Windows 10 RS5+"的答案就是否。返回 FALSE 后 `IsPerMonitorDpiScalingSupportedOnCurrentPlatform=false` ⇒ 不做 PMv2 DPI 缩放 —— 正是 X11 上应有的行为（与 `GetDpiForWindow` 恒 96 同口径） |
| 2 | `UxThemeWrapper..cctor → SafeNativeMethods.IsUxThemeActive()`：**DllNotFoundException: uxtheme.dll** | `IsThemeActive` 等 7 个 | `[降级→真话]` `IsThemeActive()=0`（Linux 上没有活动的 Windows 主题）；`GetCurrentThemeName` **返回失败**（它在 IsActive 分支里，当前不可达；宁可响亮失败也不要"空串+成功"）；`SetWindowTheme*`/panning 返回失败 |
| 3 | `HwndTarget..ctor:228 → GetCurrentSessionId → WTSQuerySessionInformation`：**DllNotFoundException: wtsapi32.dll** | 4 个 WTS 导出 | `[降级→真话]` 查询返回 FALSE。**安全性来自调用方的设计**：`IsCurrentSessionConnectStateWTSActive(..., defaultResult: true)` —— 查询失败即视为"会话活动"，正是本地 X11 会话的真相；`WTSRegisterSessionNotification` 的返回值在 `HwndTarget.cs:562` 被忽略 |
| 4 | `HwndTarget..ctor:304 → LsDisableSpecialCharacterLigature`：**EntryPointNotFoundException** | 1 个 | `[降级→真话]` 空实现：它设的是 **Windows LineServices 引擎内部的进程级标志**，而该引擎在 Linux 上根本不存在（`Lo*` 一个未实现）⇒ 没有对象可设置 |
| 5 | `HwndTarget..ctor:274 → CreateUCEResources → new Rect(...)`：**ArgumentException: Width and Height must be non-negative** | **`CW_USEDEFAULT` 未被处理** | `[修 bug]` 托管侧在没显式给几何时传 `CW_USEDEFAULT`（= `0x80000000` = `INT32_MIN`）。首版 shim **原样存下** ⇒ `GetClientRect` 返回负的 right ⇒ `right-left` 在 `Rect` 里 **int 溢出成负数** ⇒ 抛异常。现在 `CreateWindowExW`/`MoveWindow`/`SetWindowPos` 统一归一：位置→0、尺寸→800×600（Win32 语义是"由窗口管理器决定"，X11 无 WM，就由我们给一组真实可用的默认值；WPF 随后会自己 SetWindowPos 到真实尺寸） |

shim 导出符号 **347 → 367**（Win32 面 330）；实现深度：逻辑函数 232 = 真实现 103 / **降级 94** / 返回失败 35。

### 4.7.2 推进轨迹（每一步都是实测栈）

```
Application 静态构造 ✅ → BAML 加载 ✅ → SystemFonts（SPI 修复生效）✅
 → MediaContext.CreateChannels / SetNotificationWindow ✅（T1 的 .so 落地后不再出现）
 → TextBlock / 主题样式 ✅（OSVersionHelper + uxtheme）
 → Window.ShowHelper ✅ → Window.CreateSourceWindow ✅
 → HwndSource..ctor → HwndTarget..ctor ✅（WTS + Ls + CW_USEDEFAULT 之后）
 → HwndSource.Initialize:309 ❌  ← **当前卡点**
```
`TextBlock` 能在 XAML 里被实例化、主题样式能查到、`Window.ShowHelper` 能进到
`HwndSource` 构造 —— 也就是说 **M2 的窗口管线已经跑通到"最后一屏"**。

### 4.7.3 ★ 当前卡点：`StylusLogic.cs:285`（registry null，**与补丁 G 同一类**）

```
NullReferenceException
  at System.Windows.Input.StylusLogic.get_IsPointerEnabledInRegistry()   StylusLogic.cs:285
  at System.Windows.Input.StylusLogic.get_IsPointerStackEnabled()        StylusLogic.cs:206
  at System.Windows.Interop.HwndSource.Initialize(HwndSourceParameters)  HwndSource.cs:309
  at System.Windows.Window.CreateSourceWindow(Boolean)                   Window.cs:2519
```
`Registry.CurrentUser` 在 Unix 上是 **null**（不是抛异常），而上游
`Registry.CurrentUser.OpenSubKey(...)` 的 `catch` 只捕 `IOException` ⇒ NRE。
**与 M7b 补丁 G（`SecurityHelper.ReadRegistryValue`）是同一个缺陷**。

**全量清单（编译集里 15 处未加守卫的 `Registry.*`，主控可一次处理）**：

| 文件:行 | 根键 | 档 |
|---|---|---|
| `PresentationCore/…/Input/Stylus/Common/StylusLogic.cs:285` | CurrentUser | **★ 当前卡点**（`HwndSource.Initialize:309`） |
| `PresentationCore/…/Input/Stylus/Common/StylusLogic.cs:333` | CurrentUser | 同文件，`WispPenSystemEventParametersKey` |
| `PresentationCore/…/Input/Stylus/Common/StylusLogic.cs:347` | CurrentUser | 同文件，`WispTouchConfigKey` |
| `PresentationCore/…/Input/Stylus/Wisp/WispTabletDeviceCollection.cs:99` | ClassesRoot | 紧接其后（WISP 回退栈） |
| `PresentationCore/…/Input/TextCompositionManager.cs:903` | CurrentUser | 键盘输入路径 |
| `PresentationCore/…/Diagnostics/VisualDiagnostics.cs:343` | LocalMachine | 诊断 |
| `PresentationCore/…/Media/MediaSystem.cs:108` | LocalMachine | 渲染初始化 |
| `WindowsBase/System/Windows/BaseCompatibilityPreferences.cs:262` | CurrentUser | Dispatcher/兼容开关 |
| `WindowsBase/MS/Internal/IO/Packaging/CustomSignedXml.cs:204` | LocalMachine | 包签名 |
| `Shared/MS/Internal/Invariant.cs:33`、`:232` | LocalMachine | 断言开关 |
| `Shared/MS/Internal/IO/Packaging/PackagingUtilities.cs:531` | LocalMachine | 打包 |
| `Shared/MS/Internal/TextServicesLoader.cs:192`、`:204`、`:222` | CurrentUser/LocalMachine | TSF 探测 |
| `PresentationFramework/System/Windows/Application.cs:2294` | CurrentUser | 应用启动 |
| `PresentationFramework/…/Documents/Serialization/SerializerProvider.cs:221` | LocalMachine | 序列化 |

**一键应用器已交付（未运行）**：
`src/WpfGfx.Linux.Native/tools/patch-presentationcore-registry.py`（补丁 J，幂等、`--check`），
修 **输入栈那 3 个文件、5 处**（StylusLogic ×3 + WispTabletDeviceCollection + TextCompositionManager）。
修法是**一个 `?` 字符**：`Registry.CurrentUser.OpenSubKey(...)` → `Registry.CurrentUser?.OpenSubKey(...)`。
**为什么这是语义精确而不是绕过**：上游每一处拿到结果后本来就判 `if (key != null)` 或用了 `?? 0`
（见 `StylusLogic.cs:285` 的 `... ?? 0`），所以 `?.` 之后走的正是上游**原有的**"这个键没被设置过"
分支 —— 与 Windows 上"没配过这些键"逐条一致，也就是 Linux 上的真话。

```console
$ python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-registry.py --check
[检查] StylusLogic.Linux.cs：缺失/与上游不同步
[检查] WispTabletDeviceCollection.Linux.cs：缺失/与上游不同步
[检查] TextCompositionManager.Linux.cs：缺失/与上游不同步
[接线] csproj **未接线** —— 需要运行一次不带 --check 的本脚本
```
（`build/` 本轮在主控边界内，故**未应用**。）

### 4.7.4 另外两件需要在 `build/` 侧补的小事

1. **`uxtheme.dll` / `wtsapi32.dll` 没进 `Win32ShimResolver.MappedLibraries`**
   ⇒ 这两族导出**在托管层里不可达**（resolver 不映射它们，默认探测也找不到）。
   runner 现在用 M7b 实测过的部署手法兜住：**app-local 放同名 ELF 文件**
   （`cp libwpfwin32.so uxtheme.dll` / `wtsapi32.dll`）。
   正解是给 `build/shims/Win32ShimResolver.cs` 的 `MappedLibraries` 加三行：
   `"uxtheme.dll"`, `"wtsapi32.dll"`, `"WtsApi32.dll"`（比较是 OrdinalIgnoreCase，后两者可合并）。
2. **`ManagedLayer.Tests` 的串行设置是无效的**（M7b 遗留，本轮实测发现）：
   `<xunit_parallelizeTestCollections>false</xunit_parallelizeTestCollections>` **不是 xunit 的开关**
   —— 它既不会生成 `xunit.runner.json`，也不改变执行器行为（实测确认）。
   真正生效的是**输出目录里的 `xunit.runner.json`**。本工程（Presentation.Tests）加上它之后
   间歇性崩溃从 **4/8 变成 0/10**。建议给 `ManagedLayer.Tests` 也加一份
   （它有同样的进程级状态：M7b 的窗口表 + `libwpfwin32.so`）。

### 4.7.5 回退了一条自己提的改动（诚实登记）

本轮在 `X11Display` 里试过再装一个 **Xlib IO 错误处理器**（想解掉那次"无输出的间歇崩溃"）。
实测**反而更糟**（崩溃率 1/5 → 1/2），已回退并在源码里写明原因：
**Xlib 的 IO 错误意味着连接已经死了，按文档处理器不应返回（应 exit 或 longjmp）**；
返回 0 会让 Xlib 继续在死连接上跑。真正的根因是 §4.7.4 第 2 条的**测试并行**，不是 IO 处理器。

---

## 4.8 补丁 J 之后 · 卡点又前进了两屏（`HwndSource.Initialize:334`）

### 4.8.1 补丁 J 生效：stylus registry 那一族已越过

复跑 runner（45s）实测：`StylusLogic` / `WispTabletDeviceCollection` / `TextCompositionManager`
全部不再出现 —— 补丁 J 的 5 处 `?.` 生效。

### 4.8.2 ★ 当前卡点：`OleServicesContext` 的 STA 检查（**与补丁 H 同一类**）

```
ThreadStateException: Current thread must be set to single thread apartment (STA) mode
                      before OLE calls can be made.
  at System.Windows.OleServicesContext.SetDispatcherThread()   OleServicesContext.cs:143
  at System.Windows.OleServicesContext..ctor()                 OleServicesContext.cs:45
  at System.Windows.OleServicesContext.get_CurrentOleServicesContext()  OleServicesContext.cs:61
  at System.Windows.DragDrop.RegisterDropTarget(IntPtr)        DragDrop.cs:455
  at System.Windows.Interop.HwndSource.Initialize(...)         HwndSource.cs:334
  at System.Windows.Window.CreateSourceWindow(Boolean)         Window.cs:2519
  at System.Windows.Window.ShowHelper(Object)                  Window.cs:5483
```
`HwndSource.Initialize`（`HwndSource.cs:334`）**无条件**调 `DragDrop.RegisterDropTarget`
⇒ 这一处挡的是**每一个 WPF 窗口**。Linux 上线程永远不是 STA（`GetApartmentState()` 恒
`Unknown`），所以 5 处硬检查全部必然抛 —— 与补丁 H 在 `InputManager` 上解决的是同一件事。

**全量 STA 检查清单（编译集实测，共 7 处）**：

| 文件:行 | 方法 | 状态 |
|---|---|---|
| `PresentationCore/…/Input/InputManager.cs:142` | `InputManager()` | ✅ 已由补丁 H 覆盖（生成物 `InputManager.Linux.cs`） |
| `PresentationCore/System/Windows/OleServicesContext.cs:141` | `SetDispatcherThread` | **★ 当前卡点** |
| `PresentationCore/System/Windows/OleServicesContext.cs:125` | `OleRevokeDragDrop` | 窗口关闭时 |
| `PresentationCore/System/Windows/OleServicesContext.cs:112` | `OleRegisterDragDrop` | `HwndSource.Initialize:334` 直接调 |
| `PresentationCore/System/Windows/OleServicesContext.cs:89` | `OleDoDragDrop` | OLE 拖放 |
| `PresentationCore/System/Windows/OleServicesContext.cs:172` | `OnDispatcherShutdown` | Dispatcher 关闭时 |
| `PresentationCore/…/Media/Effects/BitmapEffect.cs:26` | `BitmapEffect()` | 已废弃 API，示例/常见应用不走 |

### 4.8.3 一键应用器已交付（未运行）：补丁 K

`src/WpfGfx.Linux.Native/tools/patch-presentationcore-olecontext.py`（幂等、`--check`），
一次覆盖 `OleServicesContext.cs` 的 **5 处**，每处的 Linux 语义**单独论证过**（不是一刀切）：

| 方法 | Linux 语义 | 为什么 |
|---|---|---|
| `SetDispatcherThread` | 跳过 STA 检查 + **不调 `OleInitialize`**（没有 ole32 可初始化），仍挂 `ShutdownFinished` | 保持与 `OnDispatcherShutdown` 的配平结构 |
| `OnDispatcherShutdown` | 直接返回 | 没有 `OleInitialize` 需要配平 |
| `OleRegisterDragDrop` | **返回 S_OK 的 no-op** | 没有 OLE drop target 可注册；`HwndSource.Initialize` 无条件调它 ⇒ **绝不能抛** |
| `OleRevokeDragDrop` | **返回 S_OK 的 no-op** | 与注册对称 |
| `OleDoDragDrop` | 抛 **`PlatformNotSupportedException`** | 拖放本身确实做不到。用 PNSE 而不是 `ThreadStateException` —— 后者会误导成"调用方线程用错了"；PNSE 说的是"这台机器上没有 OLE"，与 M4 对 OLE 公开 API 的裁决（`PresentationCore.OleApi.Stubs.cs`，消息含 U13）**同一口径** |

```console
$ python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-olecontext.py --check
[补丁] OleDoDragDrop → PNSE（唯一仍然抛异常的：拖放本身确实做不到）
[补丁] OleRegisterDragDrop → S_OK no-op（HwndSource.Initialize 无条件调它）
[补丁] OleRevokeDragDrop → S_OK no-op（窗口关闭时调）
[补丁] SetDispatcherThread → 跳过 STA 检查与 OleInitialize，仍挂 ShutdownFinished
[补丁] OnDispatcherShutdown → 无 OLE 可反初始化
[检查] OleServicesContext.Linux.cs：缺失/与上游不同步
[接线] csproj **未接线** —— 需要运行一次不带 --check 的本脚本
```
（5 个锚点**逐个唯一命中**；对不上就报错退出。`build/` 本轮在主控边界内，故**未应用**。）

### 4.8.4 越过之后**预期就剩最后一屏**（按代码路径推断，非实测）

`HwndSource.Initialize` 在 `RegisterDropTarget`（334）之后即结束；随后
`Window.ShowHelper` 继续 → 设 `RootVisual` → `HwndTarget` 呈现 → **`MilVisualTarget_AttachToHwnd`**
（M7c 的 `MilPresentation`）→ **`WgxConnection_SameThreadPresent`**（M7c 实现）→ 窗口 map。
也就是说：补丁 K 落地后，**M7c 自己写的那两段就是链路的最后一段**。

本轮 runner 实测（补丁 J 之后）：
```
== 3/4 启动 HelloWpf（超时 45s）
   期间新出现的 X 窗口：0x200001 800x600 IsUnMapped / 0x200002 800x600 … / 0x200003 800x600 …
== 4/4 未观察到新窗口
== 应用退出码：134
```
（800×600 的窗口对象已经在，只差 map。）

---

## 4.9 补丁 K 之后 · **窗口真的出来了**，而"白窗"的根因查到了最后一环

主控应用补丁 K 后复跑。**卡点又前进了一屏**：不再是异常，而是"应用活着、窗口在、
但屏幕没内容"。下面按"验收证据 → 定位过程 → 根因 → 交接单"给。

### 4.9.1 本轮验收证据（默认路径，**未开任何探针**）

复跑命令与 §6 一致（`run-hellowpf.sh 25`），**退出码 = 143**（= 128+15，SIGTERM：
runner 在超时点主动结束进程 ⇒ **应用一直活着**，不是崩溃，也不是提前退出）。

`xwininfo -id 0x200005`（runner 用**独立进程**抓的原文）：

```
   xwininfo: Window id: 0x200005 "HelloWpf on Linux"

     Absolute upper-left X:  0
     Absolute upper-left Y:  0
     Relative upper-left X:  0
     Relative upper-left Y:  0
     Width: 640
     Height: 400
     Depth: 24
     Visual: 0x21
```

`xwd -id 0x200005 | convert` → `hellowpf-window.png`（640×400 PNG，420 字节），直方图：

```
    256000: (255,255,255) #FFFFFF gray(255)
```

关键日志（`/tmp/m7c-hellowpf/hellowpf.log`）：

```
[mil    1] AttachToHwnd: HWND 0x200005 → 呈现目标已绑定（窗口 800x600，own=False）
  通道#1: committed=0  notimpl=0 failed=0 short=0 pending=0 batchBytes=0 资源=0 root=无 窗口目标=0x0
  通道#2: committed=12 notimpl=0 failed=0 short=0 pending=0 batchBytes=0 资源=5 root=有 窗口目标=0x200005
          视觉树={子=0 内容=无 不透明=1} [MilEtwEventResource×1] [MilVisualResource×2] [MilHwndTarget×1] [MilMatrixTransform×1]
  通道#3: committed=5  notimpl=0 failed=0 short=0 pending=0 batchBytes=0 资源=2 root=无 窗口目标=0x200005
```

**一句话结论**：**真 WPF 窗口已经在 Linux 上"建出来、映射出来、标题正确、消息齐活、
XPixmap 可截屏"，但一个像素都没画上去 —— 而且白的原因不是渲染链路坏了，是本工程
根本没构建 WPF 的主题程序集，导致 `Window.Template == null`、可视树恒为空。**

### 4.9.2 四步定位（每一步都有可复现的观测，不是推断）

**第 1 步：白色是谁涂的 —— 排除"渲染成功但画成了白"。**
`src/WpfGfx.Linux.Native/src/win32_x11.c` 建窗用的是
`XCreateSimpleWindow(d, root, x, y, w, h, 0, black, white)` ⇒ **窗口的 background_pixel
就是白**。所以"纯白"= X 的底色，不是 WPF 的输出。这一条把"颜色对不对"的讨论直接排除掉。

**第 2 步：MIL 侧记账 —— 确认"没东西可画"。**
`MilPresentation` 新增的诊断（§4.9.5 第 3 条）给出上表：主通道 `committed=12` 且**通篇冻结**
（2s 一次快照，从头到尾不变）、`notimpl/failed/short` 全 0（解码器没漏命令）、
`root=有`（`TargetSetRoot` 执行过）、`窗口目标=0x200005`（`MilCmdHwndTargetCreate` 执行过）、
但 **`视觉树={子=0 内容=无}`**。⇒ 通道结构齐全，**没有任何绘制内容**。

**第 3 步：托管侧是不是没渲染 —— 探针（public API）证伪"渲染没跑"。**
新增 `M7cProbe/HelloWpfProbe.cs`（经 `HelloWpf.csproj` 的 `-p:WpfLinuxHelloProbe=true`
链进应用，默认不编译；见 §4.9.5 第 4 条）。实测输出：

```
[probe] 快照#1：MainWindow=「HelloWpf on Linux」 IsLoaded=True Actual=640x400 可视子元素=0
        Content=Grid Template=**null** Style=null 内容子元素=2
        HwndSource.RootVisual=MainWindow；HwndTarget(=CompositionTarget).RootVisual=MainWindow 子元素=0
        IsDisposed=False；渲染帧数=82
[probe] CompositionTarget.Rendering 第 30 / 60 / 90 … 帧        （持续，约 88 帧/秒）
```

四条结论，逐条都是"健康"：
* **render pass 一直在跑**：`CompositionTarget.Rendering` 稳定触发（约 88 帧/秒），
  25 秒里上千帧 —— **没有"渲染没被调度"这回事**；
* `HwndSource.RootVisual` 与 **`HwndTarget(=CompositionTarget).RootVisual` 都已挂上**
  `MainWindow`，`IsDisposed=False` ⇒ 挂接没问题；
* 布局跑过（`IsLoaded=True`、`ActualWidth/Height=640×400`）、BAML 也加载了
  （`Content=Grid`，而且 `内容子元素=2` = TextBlock + Canvas）；
* **但 `Window.Template == null`**（`Style` 也是 null）⇒ 可视子元素 = 0。

第 4 条就是全部的答案：`Window` 是 `ContentControl`，它的 `Content` 只有经过**控件模板**里的
`ContentPresenter` 才会成为可视子元素；模板为 null ⇒ 可视树恒空 ⇒ 渲染 pass 每帧空转
⇒ `DrawnCommands=0` ⇒ 屏幕永远停在 X 的白色底色。

**第 4 步：模板为什么是 null —— 平台侧的结构性缺口（可逐行引用）。**

| 事实 | 出处 |
|---|---|
| 样式**只在外部主题程序集**里：`ThemeInfo(ExternalAssembly, None)` | `PresentationFramework/OtherAssemblyAttrs.cs:52` |
| 主题名解析：`IsThemeActive()==false` ⇒ `ThemeName` 返回 **`"classic"`** | `PresentationFramework/MS/Win32/UxThemeWrapper.cs:366-377` |
| 于是去找 **`PresentationFramework.classic`**，并且**只有 `IsActive` 为真时才回退 classic** | `SystemResources.cs:621/649`、`LoadExternalAssembly` `:764-782` |
| 该程序集在本工程里**根本没被构建**（`build/` 下无 `PresentationFramework.Classic*`，应用目录也没有） | `ls build/`；runner 组装日志 |
| `Assembly.Load` 失败被**静默吞掉**（`catch (FileNotFoundException)`）⇒ 主题字典 = null | `SystemResources.cs:784-796` |
| `Window` 的 `ControlTemplate`（含 `ContentPresenter`）**只**定义在主题字典里 | `Themes/PresentationFramework.{Aero2,Classic,Aero,Luna,Royale,AeroLite,Fluent}/Themes/*.xaml` 里各有 4 处 `x:Type Window` |

⇒ 与 `IsThemeActive()==0` 这条（M7b 为"不伪造 Aero 主题"而做的选择）合起来，
**必然推出"任何控件都没有默认样式"**。这不是渲染链路的 bug，是缺一个程序集。

### 4.9.3 对照实验（**诊断，不是修法**）：把主题本该给的那一个模板手工补上

环境变量 `WPF_LINUX_HELLO_TEMPLATE_PROBE=1` 时，探针用 `XamlReader.Parse` 构造与主题字典
同构的模板并设给窗口：

```xml
<ControlTemplate TargetType="{x:Type Window}">
  <AdornerDecorator><ContentPresenter/></AdornerDecorator>
</ControlTemplate>
```

实测（同一 runner，20s）：

```
[probe] 对照实验：已补上 Window 的 ControlTemplate（等价于主题字典里那一个）
[probe] 快照#1：… Template=有 … 可视子元素=1 … HwndTarget.RootVisual 子元素=1 … 渲染帧数=82
Unhandled exception. System.TypeInitializationException: The type initializer for
  'MS.Internal.Classification' threw an exception.
 ---> System.EntryPointNotFoundException: Unable to find an entry point named
      'MILGetClassificationTables' in shared library 'PresentationNative_cor3.dll'.
   at MS.Internal.Classification..cctor()                               Classification.cs:206
   at MS.Internal.Classification.GetUnicodeClassUTF16(Char)             Classification.cs:219
   at System.Windows.Media.Typeface.CheckFastPathNominalGlyphs(...)     Typeface.cs:435
   at MS.Internal.TextFormatting.SimpleRun.CreateSimpleTextRun(...)     SimpleTextLine.cs:1665
   at MS.Internal.Text.Line.Format(...)                                 Line.cs:83
   at System.Windows.Controls.TextBlock.MeasureOverride(Size)           TextBlock.cs:1271
   …
   at System.Windows.ContextLayoutManager.UpdateLayout()                LayoutManager.cs:299
   at System.Windows.Media.MediaContext.RenderMessageHandlerCore(...)   MediaContext.cs:1808
⇒ 退出码 134（SIGABRT）
```

两个结论：
1. **模板就是那一环**：补上之后可视树立刻有内容（`可视子元素=1`），布局真的跑起来了
   —— 一路跑到 `Grid → TextBlock.MeasureOverride`。**说明除主题程序集外，可视树挂接、
   布局、渲染调度、MIL 通道全都可用**；
2. **补上模板后立刻撞上下一个已知依赖**：`TextBlock` 测量要 Unicode 分类表，
   而该表来自 `PresentationNative_cor3.dll` 的 `MILGetClassificationTables`
   （我们的 shim 没实现）⇒ 静态构造抛 `EntryPointNotFoundException` ⇒ 布局在
   render pass 里抛出 ⇒ 未处理异常 ⇒ SIGABRT。**这正是"文本路径（T2）"那块依赖，
   现在有了精确的入口名与调用栈。**

> **这个实验没有留在默认路径里**：`WPF_LINUX_HELLO_TEMPLATE_PROBE` 默认不开，
> runner 的验收跑法（§6）不设它。它唯一的用途是把"缺主题程序集"从一个假设
> 变成一个像素级的对照结果，顺带把下一个卡点从"猜"变成"有栈"。

### 4.9.4 交接单（按"挡不挡 M2 验收"排序）

**#T（新，P0，`build/` 侧）· 构建并部署一个 WPF 主题程序集**

* **要什么**：`themes/classic.baml`（或任一主题）能被子进程加载到。
* **怎么要**（按上游原样移植，与 PF 同一套移植手法）：
  * 源工程：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Classic/PresentationFramework.Classic.csproj`
    （只有一个 `<Page Include="Themes\Classic.xaml">` + 6 个共享主题 .cs + 对
    PresentationUI/System.Xaml/WindowsBase/PresentationCore/PresentationFramework 的引用）；
  * 落地：`build/PresentationFramework.Classic.Linux/`（**走 port-lib.py，不手编**）；
  * **部署**：`PresentationFramework.Classic.dll` 必须与 `PresentationFramework.dll` **同目录**
    （它是 `Assembly.Load("PresentationFramework.classic, …")` 按名加载的，
    runner 的 2a 步骤要把它一起覆盖进应用目录）；
  * **身份必须一致**：`SystemResources.LoadExternalAssembly` 用
    `ReflectionUtils.GetFullAssemblyNameFromPartialName(PF, "PresentationFramework.classic")`
    从 **PF 自己的身份**推出全名（同版本、同公钥）⇒ 签名状态必须与 PF 一致
    （PF 现在是 PublicSign，见 §4.6 的签名统一结论）。
* **为什么是 Classic**：`IsThemeActive()==false` ⇒ `UxThemeWrapper.ThemeName == "classic"`
  ⇒ WPF 找的就是 `PresentationFramework.classic` / `themes/classic`。
  想改成 Aero2/Fluent 也可以，但要**同时**改 shim 的 `IsThemeActive`/`GetCurrentThemeName`
  与部署的主题程序集，属于另一个决策（本轮不动）。
* **验收**：探针的 `Template=null` 变成 `Template=有`，且 `可视子元素 ≥ 1`。

**#U（新，P1，`src/WpfGfx.Linux.Native/` 或 T2）· `MILGetClassificationTables`**

* 调用点：`PresentationCore/MS/internal/Classification.cs:199`（`DllImport(DllImport.PresentationNative,
  EntryPoint="MILGetClassificationTables")`），被**任何文本测量**触发（`TextBlock.MeasureOverride`）。
* 契约（托管侧 `RawClassificationTables`，`Classification.cs:186-192`）：
  `{ IntPtr UnicodeClasses; IntPtr CharacterAttributes; IntPtr Mirroring; CombiningMarks… }`，
  其中 `UnicodeClasses` 是 `short**[256]`（plane0 按 `codepoint>>8` 索引，再按低字节索引）。
* 性质：**纯 Unicode 数据**，没有 OS 依赖 ⇒ 属于"可以真实现"的一类（不是降级、更不是伪造）。
  建议由 T2 的文本线出表（或生成进 shim），本轮只登记入口与契约。

**修正上一节的一处口径**：§4.8 把 `PresentationNative_cor3.dll` 的 111 条缺口说成
"全是 LineServices（`Fs*`/`CreateTextAnalysis*`）"—— **不准确**。`MILGetClassificationTables`
就在这 111 条里，而它不在 LineServices 里、且**挡的是布局（Measure）而不是渲染**。
准确口径见 §4.9.5 第 6 条的重扫结果。

**"能不能在 `HelloWpf.csproj` 里解"**：**不能**。这两个缺口一个是**没构建的程序集**
（要新增 `build/` 工程），一个是**没实现的原生导出**（要写 Unicode 表或改 provider）；
都不是引用形态问题，改 csproj 只会把 `DllNotFound` 变成另一个 `DllNotFound`。

### 4.9.5 本轮改动清单（逐条给出理由与实测结论）

| # | 改动 | 为什么 | 实测结论 |
|---|---|---|---|
| 1 | shim：补 `GetModuleFileName` **裸名**等约 50 个导出；`CreateCompatibleDCW`/`FreeLibraryW`/`GetDpiForWindowW`/`GetIconInfo`/`CreateFileMapping`/uxtheme 6 个 `…W` 等**双门牌别名** | Unix 上运行期**只探一个名字、探不到不回退**（`GetModuleFileName` 裸名缺席即抛，尽管 `…A` 在） | 导出 446；`check-shim-coverage` 的 `EntryPointNotFoundException` 从 **139 → 111**，且 111 条里已无 user32/gdi32/kernel32/uxtheme |
| 2 | shim：`WPF_WIN32_MSG_TRACE=1` 的**消息台账**（`wpf_dispatch_to_window`） | "窗口出来但没像素"时，托管侧不可改、又不该猜；消息台账是**不改托管层也能看见它在动**的观测点 | 一次性看清 window 0x200005 的完整消息序列（`WM_NCCREATE/WM_CREATE/WM_SETICON×2/WM_SIZE 640×400/WM_MOVE/WM_SHOWWINDOW×2/WM_PAINT`），并且**证明此后应用是静止的**（不是崩溃） |
| 3 | `MilPresentation`：`WPF_LINUX_MIL_TRACE=1` 的运行期台账 + 通道计数/资源表/视觉树快照（2s 一次） | HRESULT 与退出码都区分不了"渲染没跑"与"渲染跑了没呈现"；计数器把这件事变成时序证据 | 直接给出 §4.9.2 第 2 步那张表（`committed` 冻结、`视觉树={子=0}`、`notimpl/failed=0`） |
| 4 | `HelloWpf.csproj` + `M7cProbe/HelloWpfProbe.cs`：**默认不编译**的运行期探针 | `HwndSource.RootVisual` 与 `HwndTarget.RootVisual` 是两回事、"渲染 pass 跑没跑"只能从 public API 观测 | 一步定位到 `Window.Template == null`（§4.9.2 第 3 步） |
| 5 | shim：代发 `DisplayDevicesAvailabilityChanged(1)`（含 `WPF_WIN32_NO_DISPLAY_NOTIFY` 关断开关） | Windows 上这条由**原生 MilCore** 发（`WpfGfx/core/uce/hwndtarget.cpp:306-328 PostDisplayAvailabilityMessage`，wParam = displayCount>0 ? 1 : 0）；托管侧全仓无发送者，而 `HwndTarget._displayDevicesAvailable` 就是 `WM_PAINT → DoPaint` 的闸门。我们的 MilCore 端没有消息循环也没有 X 连接，shim 两样都有 | **不是**首帧渲染的关键路径：关掉后 `CompositionTarget.Rendering` 照样 ~80 帧/秒。保留它是为了 `WM_PAINT→DoPaint`（重绘/校验）这条路径的保真，wParam=1 在 X 连接有效时是**真值** |
| 6 | `check-shim-coverage.py`：从 resolver **解析** `MappedLibraries`（不再硬编码）、剥注释、按"名字已带 W/A 就不补后缀"修正探测顺序、新增**未映射 DLL**报表 | 硬编码副本已经漂移过一次（工具说 imm32 已映射，resolver 里根本没有）；旧探测顺序把 13 个本来没问题的函数误报成缺口 | 缺口 166 → 139 →（补别名后）**111**；并给出 `shell32.dll`（12 条）、`WindowsCodecs.dll`（108 条）等**未映射 DLL** 清单 |
| 7 | runner：`shell32.dll` app-local 别名 | `Window.ShowHelper → UpdateIcon → IconHelper.GetDefaultIconHandles(IconHelper.cs:76)` 要 `ExtractIconEx`，那是 `[DllImport("shell32.dll")]`；shim **已经导出** `ExtractIconEx`，缺的只是 DLL 名这一层 | 应用越过 `DllNotFoundException: shell32.dll`，一路走到"窗口建出来" |
| 8 | runner：**构建失败即退出**（原来 `\| grep` 会吞掉失败、拿旧 DLL 继续跑） | 本轮真踩到：探针源码编译失败（CS0246），脚本照样往下跑，白跑一轮且症状误导 | 构建失败时 `exit 3` 并打印日志尾 15 行 |
| 9 | runner：默认打开 `WPF_WIN32_MSG_TRACE` / `WPF_LINUX_MIL_TRACE` | Phase 2 的观测手段只有"退出码 + 截屏"，不够 | 见上 |

### 4.9.6 对主控那条假设（`MilChannelNotify` 是不是渲染节拍）的实测回答

**结论：不是。把 `MilChannelNotify` 投出去不会有任何渲染效果**，理由是**托管侧代码本身**：

* `MediaContextNotificationWindow.MessageFilter`（`MediaContextNotificationWindow.cs:140-143`）
  收到 `s_channelNotifyMessage` 只做一件事：`_ownerMediaContext.NotifyChannelMessage()`；
* `MediaContext.NotifyChannelMessage()`（`MediaContext.cs:287-330`）只是
  `while (Channel.PeekNextMessage(out message))` 把**后向通道**里的
  `Caps / SyncModeStatus / Presented / PartitionIsZombie / BadPixelShader` 抽干，
  **没有任何 `PostRender` / 渲染调度**。

真正排渲染的是 `HwndTarget.CreateUCEResources` 末行的
`UpdateWindowSettings(_isRenderTargetEnabled /*true*/, channelSet)` →
`mctx.PostRender()`（`HwndTarget.cs:805`、`:2256`），而**它已经在跑**：探针实测
`CompositionTarget.Rendering` ~88 帧/秒。所以 T1 那条"`SetNotificationWindow` 只登记、
不 PostMessage"的设计**理由仍然成立**（同线程进程内通道没有需要唤醒的对象），
本轮**没有**改它，也不建议改。

### 4.9.7 剩余 111 条 `PresentationNative_cor3.dll` 缺口的**真实构成**

`check-shim-coverage.py`（修好探测顺序之后）的实测分组：

| 族 | 条数 | 性质 | 挡什么 |
|---|---|---|---|
| `Fs*`（LineServices 分页/行/表格） | 66 | 排版引擎内部 API | 复杂文本排版（**渲染**阶段） |
| `Lo*`（LineServices 行对象） | 22 | 同上 | 同上 |
| `Nl*`（断词）、`GetScriptAnalysisList`、`GetNumberSubstitutionList`、`CreateDocContext`/`CreateTextAnalysis*` 等 | 17 | 同上 | 同上 |
| **`MILGetClassificationTables`** | **1** | **纯 Unicode 数据**（可"真实现"，§4.9.4 #U） | **文本测量（布局）** ⇒ 挡的是**窗口出内容**，不只是排版质量 |
| `FindWindowExWrapper` / `GetMenuBarInfoWrapper` / `GetTextExtentPoint32Wrapper` / `GlobalDeleteAtomWrapper` / `SetScrollPosWrapper` | 5 | PresentationNative 对 user32/gdi32 的**直通包装** | 各自对应的 Win32 面（其中 `GetTextExtentPoint32Wrapper` 要真实字体度量 ⇒ 属 T2） |

⇒ 口径修正两点：**(1)** 不是"全是 LineServices"；**(2)** 其中 5 条直通包装
（`FindWindowExWrapper` 等）是**便宜且可真实现**的一批，建议作为下一个批量补齐；
`GetTextExtentPoint32Wrapper` 与 `MILGetClassificationTables` 属文本线（T2）。

### 4.9.8 回归证据（本轮的改动一条都不许破坏既有基线）

| 套件 | 结果 | 备注 |
|---|---|---|
| `ManagedLayer.Tests` | **28/28** | 直接依赖 `libwpfwin32.so`（本轮改过 shim） |
| `Presentation.Tests` | **8/8** | Phase 1 链路 + 像素断言（`#c81e1e`/`#1446c8` 精确命中） |
| `Windowing.Tests` | **44/44** | `MilPresentation` 属同一程序集 |
| `HelloMil.Tests` | **19/19** | 渲染后端基线 |
| `Commands.Tests` | **562/562** | 命令解码基线（上轮 559，本轮 562） |

`dotnet build`：`HelloWpf` 0 错 0 警；`WpfGfx.Linux` 0 错 0 警。

**边界披露**：为让 `MilPresentation` 的诊断生效，本轮**多次重新执行了**
`bash build/MilBridge/run.sh build`（T1 的 AOT 发布入口）⇒ `build/MilBridge/.artifacts/**`
与 `build/MilBridge/.artifacts/publish/.../wpfgfx_cor3.so` 被重新生成
（导出对拍仍是"清单 109 / 实到 111 / 缺失 0"）。`build/` 下**没有任何手编改动**，
所有 shim 改动都在 `src/WpfGfx.Linux.Native/`，所有托管改动都在边界内文件。

---

## 4.10 #U（`MILGetClassificationTables`）+ #T 落地后的复跑

主控把 #T（主题程序集）派给 M5 并已落地，把 #U 派给本组。这一节按主控要求的六项交。

### 4.10.1 #U 的实现档位与数据来源（**真实现，不是占位**）

`MILGetClassificationTables` 属于 `PresentationNative_cor3.dll`。**上游快照里没有
PresentationNative 工程的源码**（`src/Microsoft.DotNet.Wpf/src/` 下无此目录）⇒ 这条
**不能"移植"，只能自己造数据**。托管侧只给了契约（`Classification.cs:161-199` +
`UnicodeClasses.cs` 的枚举语义）。四张交出去的东西，档位**逐张不同**，必须分清楚：

| 交出去的东西 | 档位 | 数据来源 / 理由 |
|---|---|---|
| `UnicodeClasses`（两级表 + 小整数压缩） | **真实现** | 本机 Python 3 `unicodedata`（**UCD 13.0.0**）逐码点算出 0..U+10FFFF 的 (ItemClass, Script, Flags, BreakType, BiDi, LineBreak) 元组，再按元组编号成类值；142 张叶子 + 17 个平面 |
| `CharacterAttributes`（按**类值**索引的 `Pack=1` 8 字节结构） | **真实现** | 同一份元组表直接落成数组；230 个类（上限 472） |
| `Mirroring` | **降级（恒等表）** | 两个独立事实：① 托管侧 `_mirroredCharTable` **零消费者**（`grep -rn CombiningMarksClassification\|_mirroredCharTable` 全树零命中）；② 本地拿不到 BidiMirroring 数据（Python 只有 `mirrored()` 布尔、无"镜像成哪个字符"；`/usr/share/unicode`、`BidiMirroring.txt` 全盘无）。所以给**结构相同**的两级表、值取恒等，并明确登记降级 —— 不做"LEFT x ↔ RIGHT x"那种猜出来的数据 |
| `CombiningMarksClassification` | **合成（结构有效、语义空）** | 同样零消费者。三个指针都指向**真实存在的零长度数组**、计数为 0：任何按计数遍历的读者都不会越界；而 NULL 会让读者崩在解引用上 —— 那不是"不伪造"，那是制造 bug |

数据是怎么从 UCD 推出来的（`tools/gen-unicode-tables.py`，可 `--stats` 复算）：

* `category(c)` → 通用类别 ⇒ `ItemClass` / `Flags.Letter/Digit/Space/Control`；
* `bidirectional(c)` → **Bidi_Class** ⇒ `DirectionClass` + `Flags.RTL`（L→Left、AL→ArabicLetter、
  AN→ArabicNumber、EN→EuropeanNumber、CS/ES/ET、NSM→NonSpacingMark、BN→BoundaryNeutral、
  B→ParagraphSeparator、S→SegmentSeparator、WS→WhiteSpace、ON→OtherNeutral、LRE/LRO/RLE/RLO/PDF
  →对应枚举；Unicode 6.3 的**隔离类**（LRI/RLI/FSI/PDI）在该枚举里没有成员，归到最近的
  embedding/override —— 已登记为合成）；
* `combining(c)`/类别 Mn/Mc/Me ⇒ 组合标记 ⇒ `SimpleMark`/`ComplexMark`；
* `mirrored(c)` ⇒ `ScriptID.Mirror`；`name(c)` 前缀 ⇒ **脚本**（`DEVANAGARI LETTER…` ⇒ Devanagari，
  认不出的一律 `ScriptID.Default` —— **宁可默认，不猜**）；
* **保守方向**：`CharacterComplex`（＝"这一串不能走快速路径"）用**简单脚本白名单**——
  不在白名单里就算复杂。理由：多设只是变慢（禁用 fast path），少设会让该整形的文本
  被当成快速文本渲染 ⇒ 宁可降速不可画错。

### 4.10.2 ABI 断言（编译期 + 可打印 + 跨边界）

* **编译期**：`src/win32_abi.h` 新增 `WPF_CHAR_ATTR`（`__attribute__((packed))`，8 字节）、
  `WPF_COMBINING_MARKS`（48）、`WPF_RAW_CLASSIFICATION_TABLES`（72）+ 逐字段 `_Static_assert`
  （`Script@0 ItemClass@1 Flags@2 BreakType@4 BiDi@5 LineBreak@6`；四个指针 `@0/@8/@16/@24`）。
  **`Pack=1` 必须落到 C 上**，否则 `ushort flags` 会带来对齐填充、结构从 8 变 12。
* **可打印**：`WpfLinuxWin32_AbiLayout("RAWCLASSIFICATION"/"CHARATTR"/"COMBININGMARKS", …)`
  交出原生 offset；`tests/abi_layout.c` 打印并断言（`build-shim.sh --abi` 实测"全部一致"）。
* **跨边界（最强的一条）**：探针在**真应用进程**里用 `Marshal.SizeOf/OffsetOf` 读托管侧
  那个真实结构体，与原生交出的值对拍，实测输出：

```
[probe] #U 原生自检 WpfLinuxWin32_ClassificationSelfCheck() = 1
[probe] #U 布局：RawClassificationTables=72(期望 72) UnicodeClasses@0 CharAttributes@8
        Mirroring@16 CombiningMarks@24；CharacterAttribute=8(期望 8 Pack=1)
        Script@0 Flags@2 LineBreak@6
```

### 4.10.3 探针实测（读法对拍 + 语义抽查）

“没抛异常”只能证明函数被调到了；分类表是**错得很安静**的那类东西，所以做了三层验证：

```
[probe] #U 读法对拍：40 个码点，不一致 0 个（0 = 两级表/小整数压缩约定两边一致）
[probe] #U ✓ U+0041 A      类= 57 Script=31(Latin)   Item=5(Strong)  Flags=0x810(Letter|FastText) BiDi=0(Left)
[probe] #U ✓ U+0030 0      类=  2 Script=61(Digit)   Item=0(Digit)   Flags=0x100(Digit)           BiDi=3(EN)
[probe] #U ✓ U+0020 空格    类= 94 Script=0(Default) Item=6(Weak)    Flags=0x80(Space)            BiDi=18(WhiteSpace)
[probe] #U ✓ U+4E2D 中     类= 34 Script=10(CJK)     Item=5(Strong)  Flags=0x820(Letter|Ideo)     BiDi=0(Left)
[probe] #U ✓ U+0627 ا      类= 26 Script=1(Arabic)   Item=5(Strong)  Flags=0x803(Complex|RTL|Letter) BiDi=4(AL)
[probe] #U ✓ U+0301 组合尖音符 类=155 Script=0         Item=7(SimpleMark) Flags=0x0                 BiDi=8(NSM)
[probe] #U ✓ U+200D ZWJ    类=228 Script=62(Control) Item=10(Joiner) Flags=0x0                    BiDi=9(BN)
[probe] #U ✓ U+200E LRM    类=218 Script=62(Control) Item=9(Control) Flags=0x8(FormatAnchor)      BiDi=0(Left)
[probe] #U ✓ U+2029 段落分隔 类= 95 Script=0           Item=6(Weak)    Flags=0x200(ParaBreak)       BiDi=11(B)
[probe] #U ✓ U+0023 #      类=229 Script=0           Item=11(NumberSign) Flags=0x0                 BiDi=7(ET)
[probe] #U 语义抽查：10 项，不符 0 项
```

其中**第一层（读法对拍）**是关键：它拿 shim 自己按托管读法实现的
`WpfLinuxWin32_UnicodeClassOf` 与托管 `Classification.GetUnicodeClassUTF16/GetUnicodeClass`
**逐码点比较**，等于同时证明了三件事 —— 表真的被托管侧读到了、两级/小整数压缩的约定
两边一致、数据没有错位。覆盖 BMP 与补充平面（U+1F600、U+10FFFF）。

> 有一处值得留痕：`#` 那条最初失败，原因是**测试期望写错了**（我按"OtherNeutral"想，
> 实际 UCD 里 `#` 是 `ET`）。数据是对的、期望是错的 —— 这说明这层抽查不是"自己验自己"。
> 已在探针源码里保留订正痕迹。

### 4.10.4 #T 之后复跑：主题真的被取到了，但撞上**补丁 L**（并已修好）

#T 落地后复跑（默认路径，未开探针），第一次就把"白窗"推进成了**异常**：

```
Unhandled exception. System.Windows.Markup.XamlParseException:
  'Initialization of 'System.Windows.Controls.TextBlock' threw an exception.' L16 P39
 ---> System.PlatformNotSupportedException:
      System.Windows.Extensions types are not supported on this platform.
   at System.Xaml.Permissions.XamlAccessLevel.AssemblyAccessTo(Assembly)
   at System.Windows.SystemResources.ResourceDictionaries.LoadDictionary(...)  SystemResources.cs:938
   at ...LoadThemedDictionary(Boolean)                                        SystemResources.cs:631
   at ...FindDictionaryResource(...)                                           SystemResources.cs:364
   at System.Windows.StyleHelper.GetThemeStyle(FrameworkElement, FrameworkContentElement) StyleHelper.cs:213
   at System.Windows.FrameworkElement.UpdateThemeStyleProperty()               FrameworkElement.cs:640
   at System.Windows.FrameworkElement.OnInitialized(EventArgs)                 FrameworkElement.cs:5469
```

根因（可逐行引用）：`System.Xaml.Permissions.XamlAccessLevel` **不在 WPF 源码树里**，
它由 NuGet 包 `System.Windows.Extensions` 提供（`System.Xaml.csproj:91` 的 PackageReference），
而该包在非 Windows 上对这簇类型**显式抛** PNSE。上游 WPF 不守卫它 —— 因为 WPF 只在
Windows 上跑。**它挡在任何控件第一次取主题样式的路上**，也就是挡在 #T 刚刚打开的那扇门后面。

**补丁 L（生成式，与 F/G/H/I/J/K 同一套机制，idempotent + `--check`）**：
`src/WpfGfx.Linux.Native/tools/patch-presentationframework-xamlaccess.py`
把 `SystemResources.cs:938` 那一行包进 `if (System.OperatingSystem.IsWindows())`，
生成 `build/PresentationFramework.Linux/SystemResources.Linux.cs` 并接线 csproj。
**语义是"放宽"而不是"伪造"**：`XamlAccessLevel` 是 CAS 时代的"只允许某程序集访问自己的
internal 类型"，.NET Core 里 CAS 已不存在，`AccessLevel` 的默认值就是 `null`（不限制），
`System.Xaml` 自己处处按可空处理（`ObjectWriterContext.cs:114-117`），而这条路径上的
`LocalAssembly` 由 reader 侧给出（`SystemResources.cs:928-931` 的
`Baml2006ReaderSettings { LocalAssembly = assembly }`）。

**只改一处**：全仓 `AssemblyAccessTo` 只有两个构造点 —— 上述 `SystemResources.cs:938`
（实测挡路，已修）与 `XamlReader.cs:1098`（`internalTypeHelper != null` 分支；HelloWpf 的
BAML 已加载成功 ⇒ 当前没走到）。第二处在那个分支里置 null 会削弱它"允许 internal"的本意，
**本轮不动，登记为同类待办**。

**实测结果**：应用补丁 L → `dotnet build build/PresentationFramework.Linux`（**0 错 0 警，34 s**）
→ 复跑：`SystemResources`/`XamlAccessLevel` **完全从栈上消失** ⇒ **主题字典真的取到了**。

### 4.10.5 当前卡点：`LoGetEscString`（**文本排版走了 LineServices 那条路**）

补丁 L 之后，栈变成了：

```
Unhandled exception. System.TypeInitializationException:
  The type initializer for 'MS.Internal.TextFormatting.TextStore' threw an exception.
 ---> System.EntryPointNotFoundException: Unable to find an entry point named 'LoGetEscString'
      in shared library 'PresentationNative_cor3.dll'.
   at MS.Internal.TextFormatting.UnsafeNativeMethods.LoGetEscString(...)   LineServices.cs:1561
   at MS.Internal.TextFormatting.TextStore..cctor()                       TextStore.cs:77
   at MS.Internal.TextFormatting.TextStore..ctor(...)                     TextStore.cs:101
   at MS.Internal.TextFormatting.FullTextState.Create(...)                FullTextState.cs:72
   at MS.Internal.TextFormatting.TextMetrics.FullTextLine..ctor(...)      FullTextLine.cs:103
   at MS.Internal.TextFormatting.TextFormatterImp.FormatLineInternal(...) TextFormatterImp.cs:241
   at System.Windows.Controls.TextBlock.MeasureOverride(Size)             TextBlock.cs:1271
```

**这一步同时是"主题真的生效了"的最强证据**：`TextBlock.MeasureOverride` 只有在**被模板化
的可视树**里才会被调到。§4.9.2 的探针在 #T 之前实测 `可视子元素=0`、`Template=**null**`；
现在布局已经走进 `Grid → TextBlock`，说明 `Window.Template != null`。

**卡点的性质**：`FullTextLine` 是 **LineServices** 那条路。它为什么会走到这里，链条是：

```
SimpleTextLine.Create(...)                       TextFormatterImp.cs:222
  → SimpleRun.CreateSimpleTextRun(...)           SimpleTextLine.cs:1665
    → Typeface.CheckFastPathNominalGlyphs(...)   Typeface.cs:435/478
      → 返回 false ⇒ CreateSimpleTextRun 返回 null ⇒ 回落到 FullTextLine（LS）
```

`CheckFastPathNominalGlyphs` 返回 false 的两个官方理由（`SimpleTextLine.cs:1681-1684` 的注释）：
"字体的名义字形不可得，**或者可得但排版质量低**（没用上 OpenType 特性）"。它末尾的判定
（`Typeface.cs:515-560`）依赖 `glyphTypeface.FontFaceLayoutInfo.TypographyAvailabilities` ——
**也就是 T2 的 DirectWrite provider 为字体（DejaVu Sans）报出来的 OpenType 特性**。

⇒ **下一步是个二选一，属 T2/主控决策，不是 shim 能补的**：
* **A（推荐，代价小）**：让 `CheckFastPathNominalGlyphs` 对简单拉丁文本返回 true ——
  检查 provider 报的 `TypographyAvailabilities` 是否过于悲观（报了
  `FastTextTypographyAvailable`/`FastTextMajorLanguageLocalizedForm` 就会被上游判为
  "太冒险，不走快速路径"），以及名义字形索引是否正常。快速路径一旦走通，
  **LineServices 整条链（110 条 `Fs*`/`Lo*`/`Nl*`）根本不会被碰到**。
* **B（代价大）**：实现 LineServices。`LoGetEscString` 只是 `TextStore` 静态构造的**闸门**
  符号；补它一个只会立刻撞上下一个（`LoCreateLine`/`NlCreateHyphenator`…），
  且这些是真正的排版引擎内部 API，不是"补个空表"能糊过去的。

本组**没有**动 `src/WpfGfx.Linux/` 的文本层（T2 域），只在报告里把入口钉到这里。

### 4.10.6 剩余缺口与降级清单（#U 相关）

| 项 | 状态 | 影响 |
|---|---|---|
| `UnicodeClasses` / `CharacterAttributes` | **真实现**（UCD 13.0.0） | — |
| `Mirroring` | **降级：恒等** | 托管侧无消费者 ⇒ 当前**零影响**；将来若上原生 LS/镜像排版需按 BidiMirroring.txt 重生成（结构已就位） |
| `CombiningMarksClassification` | **合成：结构有效、语义空** | 托管侧无消费者 ⇒ 当前**零影响**；接 LS 后需要真数据 |
| 补充平面脚本识别 | **降级：名字前缀法** | 认不出的脚本落 `Default` ⇒ 影响字体回退的"同脚本"比较；对本轮 ASCII 样例无影响 |
| Unicode 6.3 隔离类（LRI/RLI/FSI/PDI）的 `DirectionClass` | **合成** | 枚举本身早于这些类；归到最近的 embedding/override |
| `BreakType` / `LineBreak` 字段 | **合成** | 托管侧零消费者（原生 LS 才用） |
| `CharacterExtended` 标志 | **合成（近似）** | 托管侧零消费者；按 Latin Extended 区段近似 |
| `PresentationNative` 缺口 | 111 → **110** | 剩下的 110 条中 `LoGetEscString` 已实测挡路（§4.10.5），其余仍属 LineServices |

### 4.10.7 回归与边界（本轮）

| 套件 | 结果 |
|---|---|
| `ManagedLayer.Tests` | **28/28** |
| `Presentation.Tests` | **8/8** |
| `Windowing.Tests` | **44/44** |
| `HelloMil.Tests` | **19/19** |
| `Commands.Tests` | **562/562** |

`build-shim.sh --abi` 全部一致；`build-shim.sh --symbols` 452 个导出（表本身 `hidden`，
不进导出面）；`check-shim-coverage.py` 缺口 **111 → 110**，`MILGetClassificationTables`
已从缺口里消失。

**边界披露（这一轮唯一越出"个人目录"的地方，逐条说明）**
* `build/PresentationFramework.Linux/` 下新增生成物 `SystemResources.Linux.cs` 并在
  `PresentationFramework.Linux.csproj` 注入 2 行 —— **由应用器脚本完成**（幂等、`--check`、
  锚点对不上就报错退出），没有手编；随后 `dotnet build` 该工程（0 错 0 警，34 s）。
  之所以本轮就应用：它是 #T 落地后的**直接后继**，不修则"主题取到"这一步无法被验证，
  而主控要的正是端到端证据。重放顺序见应用器文件头。
* `build/MilBridge/` 只跑 `run.sh build`（一次 publish，见 §4.9.8 的说明）。
* `src/WpfGfx.Linux.Native/`：新增 `src/win32_classification.c`、`src/win32_unicode_tables.c`（生成物）、
  `tools/gen-unicode-tables.py`、`tools/patch-presentationframework-xamlaccess.py`；
  改 `src/win32_abi.h`、`src/win32_internal.h`、`src/win32_exports.c`、`tests/abi_layout.c`、`build-shim.sh`。
* `tests/.../Presentation.Tests/M7cProbe/HelloWpfProbe.cs`：新增 #U 三层验证（探针默认不编译）。
* `samples/HelloWpf/HelloWpf.csproj` **本轮未改**（主控加的那条 Classic 引用原样保留；
  我上一轮的探针 `<Compile>` 条件项仍在）。

---

## 4.11 #U 收尾 · 闸门 1（本工程的 `Flags`）已通，闸门 2（字体排版特性）仍在挡

主控裁定走 A（让 fast path 走通），并把 `Typeface.CheckFastPathNominalGlyphs`
尾部的判定链逐行钉了出来，判定"闸门 1 = 我合成的 `CharacterAttributes.Flags`"。
**这个判断被实测证实了一半、也修正了一半** —— 记在下面。

### 4.11.1 闸门 1：位确实是被清掉的，但清它的是**空格/数字**，不是字母

上一轮我的 `Flags` 规则是"`FastText` 只给 Latin/Greek/Cyrillic **脚本**的字符"。于是：

```
U+0041 A   Flags=0x810 FastText|Letter     ← 字母有
U+0020 空格 Flags=0x80  Space              ← ★ 没有 FastText
U+0030 0    Flags=0x100 Digit              ← ★ 没有 FastText
```

而 `charFastTextCheck`（`Typeface.cs:388`，循环里 `charFastTextCheck &= charFlags`）
是沿**整串**按位与的 ⇒ `"Hello WPF on Linux"` 在两个空格处就把 `FastText` 位清光，
掉进最后那个 `else return ((typography & Available) == 0)` 分支。**主控的结论对，
只是具体字符是空格而不是字母**（字母本来就有位）。

**修法**（`tools/gen-unicode-tables.py`）：把三类改成**互斥且互补**的划分 ——
`Complex`（复杂脚本及其标记）/ `Ideo`（CJK/Kana/Hangul + CJK 标点与全角区段）/
`FastText`（**其余全部**，即拉丁系字母 + 标点 + 空白 + 数字 + 货币/数学符号…）。
复杂脚本仍然不给 FastText（它们走 FullTextLine 是**正确行为**）。
生成器里把这条规则的来龙去脉写在 `IDEO_CP` 上面。

**实测各档位（新表）**：

| 字符 | 码点 | Flags | 置位 | 说明 |
|---|---|---|---|---|
| `A` / `z` | U+0041 / U+007A | 0x810 | FastText\|Letter | ASCII 字母 ✓ |
| 空格 | U+0020 | 0x90 | FastText\|Space | **本轮的关键修复点** |
| `0` | U+0030 | 0x110 | FastText\|Digit | 数字（`numberSubstitution` 另用 `CharacterDigit` 掩码） |
| `.` / `#` / `—` | U+002E / 23 / 2014 | 0x10 | FastText | 标点/破折号 ✓ |
| `é` | U+00E9 | 0x810 | FastText\|Letter | Latin-1 ✓ |
| 中 / あ / 가 | U+4E2D / 3042 / AC00 | 0x820 | **Ideo**\|Letter | 表意/假名/谚文 |
| 。 | U+3002 | 0x20 | **Ideo** | CJK 标点（否则 CJK 串会被标点清掉 Ideo 位） |
| ا | U+0627 | 0x803 | **Complex**\|RTL\|Letter | 阿拉伯 ⇒ 正确回落 FullTextLine |
| अ / ก | U+0905 / 0E01 | 0x801 | **Complex**\|Letter | 印度系/泰文 |
| 组合尖音符 | U+0301 | 0x10 | FastText | 简单标记（复杂脚本的标记是 `ComplexMark`+`Complex`） |
| ZWJ | U+200D | 0x10 | FastText | Joiner（`ItemClass` 判定不受影响） |
| 😀 / € | U+1F600 / 20AC | 0x10 | FastText | 符号类；无 shaping 需求 |

（重新生成后类数 230 → **242**，仍远低于上限 472；叶子 142 → 143。）

### 4.11.2 探针实测：闸门 1 已通，闸门 2 挡住（**当前卡点的全部原因**）

按主控要求，探针里加了三条并列打印（在**挂钩那一刻**就打，早于首次布局与崩溃）：

```
[probe] 闸门① 逐字符（Hello WPF）：
[probe]   'H' U+0048 类= 58 Flags=0x210；'e' U+0065 类= 62 Flags=0x210；' ' U+0020 类= 97 Flags=0x090；…
[probe] 闸门② charFastTextCheck(按位与后) = 0x10：FastText位=True Ideo位=False
          ⇒ 走上游 FastText 分支
[probe] 闸门③ MessageFontFamily/Normal：TypographyAvailabilities=23
          （Available=True Ideo=True FastText=True FastTextMajorLangLoca=False FastTextExtraLangLoca=True）
[probe] 闸门③ MessageFontFamily/Bold：TypographyAvailabilities=23（同上）
[probe] 闸门③ DejaVu Sans/Normal：TypographyAvailabilities=23（同上）
```

⇒ **闸门 1 已通**：`charFastTextCheck` 保住 `FastText` 位（0x10），上游进入 `FastText` 分支。
**闸门 2 立即命中**：`Typeface.cs:524` 的
`if ((typography & (FastTextTypographyAvailable | FastTextMajorLanguageLocalizedFormAvailable)) != 0) return false;`
—— 值 **23 = 0x17** 里 **bit 4（`FastTextTypographyAvailable`）** 置位，fast path 被拒，
回落 `FullTextLine` ⇒ `TextStore..cctor` ⇒ `LoGetEscString` 缺失 ⇒ 退出码 134。
**与主控预判的"闸门 1 已通、卡在闸门 2"完全一致。**

### 4.11.3 闸门 2 的交接（属 T2，含一条可复核的疑点）

* **它不是 provider 直接报出来的枚举**：`TypographyAvailabilities` 由 **PresentationCore
  自己的托管代码**算出 —— `FontFaceLayoutInfo.ComputeTypographyAvailabilities()`
  （`FontFaceLayoutInfo.cs:387-545`）：`GsubGposTables` 读 GSUB/GPOS →
  `OpenTypeLayout.GetComplexLanguageList(…, RequiredTypographyFeatures, …)`（step 2，
  有返回就置 **bit 4**）→ step 3 用全 1 的 glyphBits 再查一次，返回列表含
  `ScriptTags.CJKIdeograph` 就置 **bit 2**。provider 提供的是**字体的原始 GSUB/GPOS 表字节**
  （`Text.TextInterface.FontFace.TryGetFontTable`）。
* **疑点（建议 T2 先看这条）**：**DejaVu Sans 被报成 `IdeoTypographyAvailable`（bit 2）**，
  而 DejaVu 根本没有 CJK/假名表；同时 bit 4 与 bit 16 也都置位。一个没有 CJK 的字体被枚举出
  `CJKIdeograph` 书写系统，更像是**表字节/脚本表枚举返回了非真实数据**
  （空表或长度错位时 `scriptCount/featureCount/lookupCount` 读出垃圾，
  `GetComplexLanguageList` 就会"发现"并不存在的特性）。
  T2 自己在 `build/DirectWrite.Linux/WiringSmoke/Program.cs:262-263` 标注过同一条链
  （"它的 ComputeTypographyAvailabilities 会去读 GSUB/GPOS —— 而读表正是走我们 provider 的
  `FontFace.TryGetFontTable`"），入口是共同的。
* **判据**：对 DejaVu 把 bit 4 清掉 ⇒ `(typography & (4|8)) == 0` ⇒ **fast path 直接返回 true**
  ⇒ LineServices 整条链不会被碰到。按主控指令，**我没有动 T2 的任何文件**。

### 4.11.4 端到端状态与回归

* 默认路径复跑：仍 **134**，栈顶仍是 `LoGetEscString`（`TextStore..cctor`）；窗口仍未 map
  （`Window.Show()` 在 ShowWindow 之前就进首次布局并抛出；消息台账里 `0x200005` 只到
  `WM_NCCREATE/WM_CREATE/WM_SETICON/WM_SIZE/WM_MOVE`，**没有 `WM_SHOWWINDOW`**）。
  所以**本轮没有新的截图可交** —— 这是"闸门 2 未通"的直接后果，不是回退。
* `build-shim.sh --abi`：**全部一致**；shim 构建 0 错 0 警；
  `check-shim-coverage.py`：缺口仍是 **110**（#U 那条已在已实现侧）。
* 回归：`ManagedLayer 28/28`、`Presentation 8/8`、`Windowing 44/44`、`HelloMil 19/19`、`Commands 562/562`。
* 本轮改动：`tools/gen-unicode-tables.py`（Flags 规则 + 实测表）、`src/win32_unicode_tables.c`（重新生成）、
  `M7cProbe/HelloWpfProbe.cs`（闸门①②③，提前到挂钩时刻 + 反射读 `FontFaceLayoutInfo`）。
  未碰 `build/DirectWrite.Linux/`、`build/PresentationFramework.Classic.Linux/`、
  `src/WpfGfx.Linux/Text|Rendering|Resources/`。

---

## 4.12 派生字体接线与复跑 · **闸门 2 已过，卡点是"第三环"（不在字体掩码上）**

主控把 T2 的派生件放到 `build/fonts-ui/UI-NoLayout.ttf`（**刻意不放 `build/fonts/`**，
避免同族同字重遮蔽基准件）。本轮做了两件事：runner 的字体开关，以及用它复跑并把卡点定死。

### 4.12.1 runner 开关（`HLWPF_UI_FONT`，默认不设 = 行为不变）

`tests/.../Presentation.Tests/run-hellowpf.sh` 新增 1.5 节：

* **给路径**（`HLWPF_UI_FONT=/…/UI-NoLayout.ttf`）：
  ① 文件不存在 → **报错退出**（`exit 4`，不静默回落）；
  ② `fc-scan` 读字族名；③ 设 `WPF_LINUX_FONT_DIR=<该文件所在目录>`
  （PresentationCore 的 Linux 字体工厂优先用它，`build/shims/PresentationCore.Factory.Linux.cs:322-330`）；
  ④ 设 `WPF_LINUX_UI_FONT=<字族名>`（shim 的 `SystemParametersInfo` 填进 `lfFaceName`
  ⇒ `SystemFonts.MessageFontFamily`）。
* **给字族名**：只设 ④。
* 回显 **路径 / 字族 / 大小 / sha256 / 字体目录**；应用启动改用 `env` + 数组
  （行内前缀没法"有条件地"加一个赋值，空值会被 `getenv` 当成"设了但为空"）。

**双份见证（都实测）**：runner 侧回显

```
UI 字体 : …/build/fonts-ui/UI-NoLayout.ttf   字族: Noto Sans   332736 字节
          sha256 b008d486c4e029417d070461c36324fb6f6ac7c4aeb28e810f8f3e82c3250c55
          字体目录: …/build/fonts-ui（WPF_LINUX_FONT_DIR）
```
应用内（探针）：`WPF_LINUX_UI_FONT=Noto Sans`、`WPF_LINUX_FONT_DIR=…/build/fonts-ui`、
**`SystemFonts.MessageFontFamily=Noto Sans`** ⇒ 覆盖**真的**生效到托管栈（不是只传了环境变量）。

> 顺带确认了主控/T2 把派生件挪出 `build/fonts/` 的必要性：**同一目录里同族同字重的基准件会赢**。
> 实测 `WPF_LINUX_FONT_DIR=build/fonts` 时掩码仍是 **21**（选中的是未剥离的 `NotoSans-Regular.ttf`），
> 把派生件单独放一个目录后才变成 **0**。

### 4.12.2 复跑实测：**掩码 = 0，快路径 = True，仍然进 LineServices**

按主控给的命令复跑（`HLWPF_UI_FONT=<repo>/build/fonts-ui/UI-NoLayout.ttf`），退出码 **134**，
栈顶仍是 `TextStore..cctor → LoGetEscString`。按"不要猜、要打印"的要求，把三层都打了出来：

```
[probe] 闸门③ MessageFontFamily/Normal：TypographyAvailabilities=0
         （Available=False Ideo=False FastText=False FastTextMajorLangLoca=False FastTextExtraLangLoca=False）
[probe] 真实 TextBlock：Text="Hello WPF on Linux" FontFamily=Noto Sans FontSize=24 FontWeight=Bold
         TextWrapping=NoWrap LineHeight=NaN Typeface.TryGetGlyphTypeface=有
[probe] 真实 TextBlock：CheckFastPathNominalGlyphs(它自己的字符串/字号/字重) = True，stringLengthFit=18
[probe] 真实 TextBlock：charFastTextCheck=0x10（FastText位=True）：
         'H'=0x810 … '␠'=0x90 'W'=0x810 …（18 个字符全部命中，空格 0x90 带 FastText）
[probe] 闸门④ 缺字形字符数=0/18：'H'→43 'e'→72 … 'x'→91
```

注意最后两条是**真实那一个 TextBlock 实例**（`FrameworkElement.Initialized` 时刻从窗口逻辑树里
抓到的、它自己的 Typeface / 字符串 / 字号 / 字重），不是我用 `SystemFonts` 现造的 —— 这样
"是不是 NullFont / 是不是别的字体/别的串"这两个假设缺口都关掉了。

⇒ **主控预测的链路 ①掩码=0 ②`CheckFastPathNominalGlyphs`=True 都成立，
但第③步"于是走 `SimpleTextLine`"没有发生**。所以：
**卡点不是字体掩码（那一环已经通了），是"第三环"** —— `TextFormatterImp.FormatLineInternal`
里 `SimpleTextLine.Create(...)` 回了 null，于是构造 `FullTextLine`（LS）。

`SimpleTextLine.Create` / `SimpleRun.Create` 的**全部** `return null` 出口（逐行）：

| 文件:行 | 条件 | 对本例的实测值 |
|---|---|---|
| `SimpleTextLine.cs:88-99` | `pap.RightToLeft`/`Justify`/`FirstLineInParagraph&&TextMarkerProperties`/`TextIndent!=0`/`ParagraphIndent!=0`/`LineHeight>0`/`AlwaysCollapsible`/`TextDecorations` 非空 | 实测 `TextWrapping=NoWrap`、`LineHeight=NaN`（`LineProperties.LineHeight` 非 BlockLineHeight 时返回 0）、无装饰、首行、无 marker、缩进 0 ⇒ **看起来都不该命中** |
| `SimpleTextLine.cs:157-162` | `!run.EOT && run.IdealWidth > widthLeft`；`widthLeft = (pap.Wrap && paragraphWidth>0) ? paragraphWidth : int.MaxValue` | `NoWrap` ⇒ `widthLeft=int.MaxValue` ⇒ 不该命中 |
| `SimpleTextLine.cs:171-175` | `nonHiddenLength >= TextStore.MaxCharactersPerLine` | 18 字符 ⇒ 不该命中 |
| `SimpleTextLine.cs:196-203` | `run == null` 或下划线不兼容 | ← **嫌疑集中在这里**（`SimpleRun.Create` 内部） |
| `SimpleTextRun.cs`（`SimpleRun.Create`：`textRun is TextCharacters` / `BaselineAlignment!=Baseline` / `TextEffects` / `TextDecorations`） | 运行期属性 | `TextBlock` 的 `SimpleLine` 确实产出 `TextCharacters`；其余为默认值 |

**并且在能观测到的最早时刻量到一个非常可疑的值**：

```
[probe] … DpiScale=(0,0) PixelsPerDip=0        ← 在 HwndSource 建好之前读的（见下面的说明）
```

`TextSource.PixelsPerDip` 正是 `Line` 构造函数里 `_owner.GetDpi().PixelsPerDip`（`Line.cs:60`），
而 `SimpleTextLine.Create(..., textSource.PixelsPerDip)` 把它一路传进 `SimpleRun` 的度量。
**若它在排版那一刻是 0**，宽度换算（`IdealToReal(widthLeft, 0)`）与 `SimpleRun` 的度量都会退化
——这与"掩码/快路径都通过却仍然回 null"高度吻合。
**但我必须说清这条证据的边界**：我只能在"HwndSource 尚未挂到窗口"的时刻读到它
（崩溃发生在首次布局，早于 `PresentationSource.FromVisual(win) != null`），
所以 **(0,0) 也可能只是"此时宿主还没接上"的产物，不是排版那一刻的真值**。
要判定它是真缺陷还是观测假象，只需在 PC 侧插一行打印 —— 那是边界外的文件（见下面的建议）。

### 4.12.3 建议的下一步（一条 3 行诊断补丁，属 PC/build 侧）

在 `PresentationCore/MS/internal/TextFormatting/SimpleTextLine.cs` 的
**每一个 `return null`** 前加一行 env 门控打印（`WPF_LINUX_TEXT_TRACE=1` 时输出），
并打印 `settings.Pap` 的 8 个守卫值、`run.IdealWidth`/`widthLeft`、
`textSource.PixelsPerDip`、以及 `SimpleRun.Create` 的实际运行期属性。
一次运行就能把"第三环"钉死到行。**本组可以按既有机制产出这个应用器**
（生成式补丁 + `--check` + 幂等，形如补丁 L），**但需要主控确认**，因为它要改 `build/PresentationCore.Linux/`
并重建 PresentationCore —— 本轮按边界没有动它，也没有为了让它过去改任何掩码或伪造证据。

### 4.12.4 本轮改动与回归

* 改动：`tests/.../run-hellowpf.sh`（1.5 节字体开关 + `env` 启动）、
  `M7cProbe/HelloWpfProbe.cs`（闸门④"真实 TextBlock"探针：`Initialized` 时抓实例 +
  Send 级自排队等到 `Show()` 之后、DPI/字面/逐字符 Flags 打印）、`docs/U2-M7c-report.md`。
  **未碰**：`build/fonts/`、`build/fonts-ui/`（只读使用）、`build/DirectWrite.Linux/`、
  `build/PresentationFramework.Classic.Linux/`、`src/WpfGfx.Linux/Text|Rendering|Resources/`。
* shim **本轮未改** ⇒ 上一轮跑过的 5 个套件结论仍然有效
  （`ManagedLayer 28/28`、`Presentation 8/8`、`Windowing 44/44`、`HelloMil 19/19`、`Commands 562/562`）。
* 默认路径（不设 `HLWPF_UI_FONT`、不开探针）复跑：**行为与之前一致**（134、栈顶 `LoGetEscString`、
  窗口未 map），说明开关默认零影响。

---

## 4.13 ★ M2 达标：**窗口 map + 屏幕上真的有内容**

这一轮把最后三段接上了：**DPI 面（shim）→ `LoGetEscString`（shim）→ 呈现时重新投影（MilPresentation）**。
下面是验收四件套，全部来自**独立进程**（`xwininfo`/`xwd`），并额外做了"窗口内容 vs 屏上同区域"的交叉验证。

### 4.13.1 `xwininfo -id 0x200005`（原文，含 `Map State`）

```
xwininfo: Window id: 0x200005 "HelloWpf on Linux"

  Absolute upper-left X:  0
  Absolute upper-left Y:  0
  Relative upper-left X:  0
  Relative upper-left Y:  0
  Width: 667
  Height: 417
  Depth: 24
  Visual: 0x21
  Visual Class: TrueColor
  Border width: 0
  Class: InputOutput
  Colormap: 0x20 (installed)
  Bit Gravity State: ForgetGravity
  Window Gravity State: NorthWestGravity
  Backing Store State: NotUseful
  Save Under State: no
  Map State: IsViewable          ← ★ 真的映射出来了
  Override Redirect State: no
  Corners:  +0+0  -613+0  -613-607  +0-607
  -geometry 667x417+0+0
```

`667x417`（而不是 XAML 里的 640×400）本身就是 DPI 修复的**可见证据**：
667/640 = 1.0417 = **100/96** —— X server 报 1280×1024 px / 325×260 mm = 100 dpi，
WPF 按真实 DPI 缩放 ⇒ 窗口的**设备像素**尺寸变大。这是"真话"，不是凑出来的数字。

### 4.13.2 `xwd` PNG + 直方图

PNG：`/tmp/m7c-accept.png`（**46,916 字节**；"白窗"时期是 420~434 字节）

```
     12154: (32.2957,61.6381,99.5837) #203E64  ← PanelBrush 渐变（#1E3A5F 端）
     48354: (41.1518,75.4981,116.79) #294B75   ← 渐变中间色
    116120: (54.7237,96.8093,143.37) #37618F   ← 渐变中间色
     53738: (67.2412,116.031,167.136) #4374A7  ← 渐变（#4A7FB5 端）
     21411: (139.082,191.241,180.385) #8BBFB4  ← 椭圆渐变＋白描边混合
      6442: (191.623,197.335,207.237) #C0C5CF  ← 白描边抗锯齿边
     24523: (255,99,71) #FF6347 tomato          ← ★ XAML 里的 Tomato 矩形
```
**不再是全白**：7 个色种，其中 `#FF6347` 正是 `MainWindow.xaml` 里
`<Rectangle Fill="Tomato" …/>` 的原色（24,523 px ≈ 180×100 矩形减去 2px 白描边，量级吻合 ✓）。

**屏上交叉验证**：同一时刻裁剪**根窗口**同区域，直方图同色系
（`#284A73`/`#37618F`/`#4374A7`/`#B69D8C`）⇒ 像素**真的在屏幕上**。

### 4.13.3 退出码与 MIL 台账

* **退出码 = 143**（SIGTERM，runner 超时收工）⇒ 应用**一直活着**，窗口在屏上、消息泵在跑。
* MIL 台账：

```
通道#2: committed=65 notimpl=0 failed=0 short=0 pending=0 batchBytes=0 资源=44 root=有 窗口目标=0x200005
        [MilVisualResource×14] [MilRenderDataResource×7] [MilGlyphRun×2] [MilLinearGradientBrush×2]
        [MilSolidColorBrush×3] [MilPen×3] [MilEllipseGeometry×2] [MilRadialGradientBrush×1] …
[mil 4] 通道 2 → HWND 0x200005 已呈现 667x417（skia 指令 11 条，未画种类 1）  累计帧数 = 1
```

**一句话结论**：**真 WPF 窗口在 Linux 上显示出来了** —— 667×417 `IsViewable`，
屏上是 XAML 那套渐变背景 + Tomato 矩形 + 渐变椭圆（7 色，含 `#FF6347`），应用稳定存活到超时。
**唯一还没画的是文字**（`未画种类 1` = `MilDrawGlyphRun`，见 §4.13.5）。

### 4.13.4 这一轮改了什么（before → after 全部实测）

| # | 位置 | 改动 | before → after |
|---|---|---|---|
| 1 | `src/WpfGfx.Linux.Native/src/win32_misc.c` | **`GetDeviceCaps` 真实现**（88/90 用 X 的 px/mm 算，缺失/离谱回退 96；12/14/8/10/24 一并自洽）；`GetDpiForWindow/System/Monitor` 统一到同一数据源 | `LOGPIXELSX/Y` **0 → 100**；`BITSPIXEL/PLANES/HORZRES/VERTRES/NUMCOLORS`=24/1/1280/1024/-1；`GetDpiForSystem` **96 → 100**；窗口 **640×400 → 667×417**（DpiScale 1.0 → 1.0417） |
| 2 | `src/WpfGfx.Linux.Native/src/win32_x11.c` | 新增 `wpf_x11_screen_metrics()`（px/mm→DPI，48..480 夹取 + 96 回退）、度量缓存、**X 连接改为加载期（constructor）建立一次** | DPI 由"假 96"变"X 报的 100"；并消掉并发 `XOpenDisplay`（宿主崩溃率 6/6 → 3/6） |
| 3 | `src/WpfGfx.Linux.Native/src/win32_classification.c` + `win32_abi.h` | **实现 `LoGetEscString`**（新增 `WPF_ESCSTRING` 6 指针 ABI + 断言；返回 6 个互不相同、落在私用区的转义字符指针，带自检） | 缺口 **110 → 109**；`TextStore..cctor → LoGetEscString` **崩溃消失**，应用从"启动即崩(134)"变成"稳定存活(143) + 窗口 map" |
| 4 | `src/WpfGfx.Linux/Interop/MilPresentation.cs` | 呈现时**重新投影根视觉**（`channel.Root` 是 `TargetSetRoot` 时刻的**空快照**，`Resources/MilChannel.cs:316`） | 呈现帧 **skia 指令 0 → 11 条**；画面从纯白 → 渐变+矩形+椭圆 |
| 5 | `tests/.../run-hellowpf.sh` | **等到第一帧呈现再截屏**（原来窗口一 map 就截 ⇒ 截到 X 窗口底色白）+ 根窗口同区域交叉验证 + `xwininfo` 打到 `Map State` + `HLWPF_UI_FONT` 开关（§4.12.1） | 截图 420 B 全白 → **46,916 B、7 色** |

### 4.13.5 剩余缺口（按"挡不挡完整 M2"排序）

1. **文字还没画**：`未画种类 1` = `MilDrawGlyphRun` —— `MilPresentation.GlyphRenderer` 没有宿主挂上
   （呈现路径刻意不建隐式全局 `TextRenderer`）。`MilGlyphRun×2` **已经在通道里** ⇒
   **数据齐了，只差把 T2 的 `TextRenderer` 挂到呈现 provider 上**（T2 的域，本组未动）。
2. **呈现的"触发器"目前仍是诊断探针**（`WPF_LINUX_MIL_PRESENT_PROBE=1`，每 250ms 驱动一次）。
   **正解 3 行**：T1 的 `src/WpfGfx.Linux/Interop/MilNative.cs:87-91`，
   在 `channel.Commit()` 之后调一次 `MilPresentation.PresentChannel(channel)`
   （Windows 上这步由原生 MilCore 的渲染线程做；本移植没有渲染线程）。
   **放进去之后，本次验收画面就不再需要任何探针。**
3. **`ManagedLayer.Tests` 宿主偶发崩溃（已归因：与本轮改动无关，且本轮顺带改善）**：
   6 连跑 3 次在套件中途 `测试主机进程崩溃`（一次留下
   `Inconsistency detected by ld.so: dl-open.c: 224 _dl_find_dso_for_object: Assertion 'ns == l._ns' failed!`
   —— glibc 的 **dlopen 多线程**断言）。**归因实验**：用诊断开关 `WPF_SHIM_LEGACY_DPI=1`
   恢复"GetDeviceCaps 恒 0、不碰 X"的旧行为后**仍然 5/6 崩溃** ⇒ 不是本轮引入的。
   本轮的"加载期建连 + 度量缓存"把崩溃率从 **6/6 降到 3/6**。**完成时套件 28/28 全绿**（实测 3 次）。
4. **T2 provider 接口漂移（会挡住所有复跑）**：`LinuxFontCollection.FromDirectories` 新增第三参
   `bool? stripLayout = null`（`build/DirectWrite.Linux/Provider/LinuxFontCollection.cs:128`），
   而已编译的 PresentationCore 是按旧两参签名编的 ⇒ 运行期
   `MissingMethodException: …FromDirectories(IEnumerable<string>, bool)`。
   同时 `dotnet build samples/HelloWpf` 会因 T2 的中间态源码报 `CS0103 CorruptDirectory` 失败
   （runner 会**拒绝用陈旧产物继续** —— 这正是设计意图）。**需主控裁定**：T2 保留旧重载，或重建 PC。

### 4.13.6 复现（本轮验收那一跑）

```bash
export PATH="$HOME/.dotnet:$PATH" DISPLAY=:99
export HLWPF_UI_FONT="$PWD/build/fonts-ui/UI-NoLayout.ttf"
export WPF_LINUX_MIL_PRESENT_PROBE=1        # 诊断触发器（正解见 §4.13.5 第 2 条）
tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 45 [--no-build]
# → xwininfo 0x200005 "HelloWpf on Linux" 667x417 Map State: IsViewable
# → hellowpf-window.png ≈46,916 B；直方图含 #FF6347 tomato
# → 退出码 143；MIL：committed=65 资源=44 已呈现 667x417 skia 指令 11 条
```

---

## 4.14 ★★ M2 完整达标（**零探针**）：呈现触发器接进提交路径 + 文字真的画出来了

主控把最后两件都判给本组（同属 `src/WpfGfx.Linux/Interop/`，一个人做 = 一次构建 = 一次验收）。

### 4.14.1 两处改动

**(1) 真正的呈现触发器（原来那个 250ms 诊断探针已删除）**
`src/WpfGfx.Linux/Interop/MilNative.cs`：

```csharp
public static int MilConnection_CommitChannel(IntPtr channelHandle)
{
    MilChannel channel = MilChannelRegistry.Resolve(channelHandle);
    if (channel == null) return HResult.E_HANDLE;

    int hr = channel.Commit();
    if (HResult.Failed(hr)) return hr;

    int presented = MilPresentation.PresentChannel(channel);   // ← 对应原生 MilCore 渲染线程那一步
    return HResult.Failed(presented) ? presented : hr;
}
```
语义与 `WgxConnection_SameThreadPresent` 完全一致（无窗口 → 什么都不做；有窗口没根 → S_OK+诊断；
有窗口有根但渲染/呈现失败 → **返回失败码**）。
**`MilPresentation` 里的 `WPF_LINUX_MIL_PRESENT_PROBE` 诊断探针已整段删除** ——
验收画面里不再有任何"替身"。

**(2) 字形渲染器挂上，`MilDrawGlyphRun` 真的画字**
`MilPresentation.EnsureGlyphRenderer()`（按需建、呈现层自持、`Reset()` 释放）：

```csharp
GlyphRenderer = new Text.TextRenderer(
    Text.FontSet.FromDirectory(dir),          // WPF_LINUX_TEXT_FONT_DIR → WPF_LINUX_FONT_DIR → 系统目录
    Text.TextFontDescription.Regular(family), // WPF_LINUX_TEXT_FONT_FAMILY → WPF_LINUX_UI_FONT → "Noto Sans"
    fallbackSize: 12f);
```
**为什么由呈现层持有**（原注释写着"宿主挂进来、宿主释放"）：真应用里**没有别的宿主** ——
托管层不引用 `WpfGfx.Linux.Text`，T9 的 `PIDWriteFont→Typeface` 映射也没接；
而通道里 `MilGlyphRun×2` 早就有、`MilDrawGlyphRun` 却因没人挂被记进 `NotDrawn`。
作用域就是这一层，不是给别的层共用的隐式单例。
**字体必须与 WPF 侧同一份**（glyph id 是字体相关的）⇒ 目录/字族取值口径与 shim 的 UI 字体一致。

**(3) 顺手收口：无 X 时 DPI 回退 96（不再是 0）** —— 主控实测发现的那个遗留。
`wpf_x11_screen_metrics()` 现在**先把 96 填好**再尝试问 X；X 连不上就缓存这个 96 回退。
实测：`env -u DISPLAY` → `LOGPIXELSX/Y = 96`；`DISPLAY=:99` → **100**（X 报的真值）。

**(4) 呈现台账不再吞掉关键帧**：节流规则加了例外 —— **首个"有内容"的帧永远记录**。
实测就是这么发现问题的：第一帧 `skia 指令 0 条`（这批只创建资源），
真正有内容的帧（第 7 次呈现）原来被节流吞了，读日志的人会误判成"什么都没画"。

### 4.14.2 零探针验收件（本轮那一跑：**不设任何探针环境变量**）

* **退出码 143**（SIGTERM，runner 超时收工）⇒ 应用一直活着。
* `xwininfo`（原文节选）：`Window id: 0x200005 "HelloWpf on Linux"`、`667x417`、
  `Visual Class: TrueColor`、`Class: InputOutput`、**`Map State: IsViewable`**。
* PNG：`docs/m7c-accept-zero-probe.png`（**56,055 字节**）
* 直方图（窗口自身）：
```
  10987: #203E64    47954: #294C75   114468: #37618F   54133: #4374A7   ← PanelBrush 渐变四段
  17226: #72BCA8     8793: #C5CCD5                                      ← 椭圆渐变 + 白描边抗锯齿
  24578: (255,99,71) #FF6347 tomato                                      ← Tomato 矩形
```
* **文字像素（决定性）**：裁剪 TextBlock 所在区域（`300x50+16+16`）后
  **`#F3F5F7` 近白 1,359 px** —— 就是那行 24px Bold 白色 “Hello WPF on Linux” 的字形墨迹
  （按 250×30 的文本框估 1.2~1.5k 墨迹像素，量级吻合）。全窗口 `#F0F4F6` 5,828 px（含描边抗锯齿）。
* **MIL 台账**：
```
[mil 12]  通道 2 → HWND 0x200005 已呈现 667x417（skia 指令 0 条，未画种类 0）  累计帧数 = 1
[mil 14]  ★ 首个**有内容**的帧（第 7 次呈现）：通道 2 → HWND 0x200005 667x417
          （skia 指令 11 条，**未画种类 0**）  累计帧数 = 2
       通道#2: committed=65 notimpl=0 failed=0 short=0 pending=0 batchBytes=0 资源=44
               [MilGlyphRun×2] [MilRenderDataResource×7] [MilVisualResource×14] … 
       字形渲染器已挂上：目录=…/build/fonts-ui 默认字族=Noto Sans
```
  **`未画种类 0`** = 通道里每一种指令都真的画了（含那 2 个字形 run）——
  这正是主控要求的判据。

**一句话结论**：**真 WPF 窗口在 Linux 上显示出来了，而且文字也在** ——
零探针、667×417 `IsViewable`、渐变背景 + Tomato 矩形 + 渐变椭圆 + **白色文本**（近白 1,359 px），
`未画种类 0`，应用稳定存活到超时。

### 4.14.3 复现（零探针）

```bash
export PATH="$HOME/.dotnet:$PATH" DISPLAY=:99
export HLWPF_UI_FONT="$PWD/build/fonts-ui/UI-NoLayout.ttf"   # 只留字体开关；探针环境变量全部不设
tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 45 --no-build
# → xwininfo … Map State: IsViewable；PNG ≈56 KB；直方图含 #FF6347 与近白文本像素
# → MIL：skia 指令 11 条，未画种类 0（含 MilGlyphRun×2）
```

### 4.14.4 仍未闭合的（如实登记）

* **T2 provider 接口漂移**：`FromDirectories` 第三参属 T1 路线 C 的中途态（主控已核查源码保留 2 参重载），
  收口放在"PC 合并波"里重建一次。在它收口前，`dotnet build samples/HelloWpf` 可能撞到
  `LinuxFontCollection`/`FontTableStripper` 的中间态编译错误（runner 会**拒绝用陈旧产物继续**，
  这是设计意图，不是故障）。
* **`ManagedLayer.Tests` 宿主偶发崩溃**：已归因（`WPF_SHIM_LEGACY_DPI=1` 复原旧行为后仍 **5/6** 崩 ⇒ 与本轮无关）。
  收尾后再测 7 次：**3 次干净（28/28）+ 4 次中途崩溃**（崩溃点随机：跑到 14/18/23/27 条时进程死），
  即约 25~50% 概率；**本轮的"加载期建连 + 度量缓存"把当时的 6/6 降到了 ~3/6（有帮助）**。
  症状文本：`测试主机进程崩溃`，其中一次留下 glibc 的
  `Inconsistency detected by ld.so: dl-open.c: 224 _dl_find_dso_for_object: Assertion 'ns == l._ns' failed!`
  ⇒ 怀疑与"多线程 dlopen"有关（本 shim 已把唯一的 X 连接提前到加载期，但进程里还有别的 dlopen 来源，
  例如 SkiaSharp/托管程序集/`AssemblyLoadContext`）。**没有为了让它绿而弱化任何断言。**

---

## 4.15 拆除期 `E_HANDLE` 定案与修复（`HwndSource_Characterization_OnLinux`，5/5 稳定复现）

主控报：`MediaContext.Dispose → RemoveChannels → Channel.Close() → CommitChannel` 抛
`COMException 0x80070006`。本节是"三处 E_HANDLE 分别钉死 → 找到真实缺陷 → 修 → 对照"的全过程。

### 4.15.1 三处出口分别钉死（证据，不是推理）

`MilConnection_CommitChannel` 的三个失败出口各留了一条**可区分**的台账
（`WPF_LINUX_MIL_LOG=<file>` 写文件，测试宿主里也读得到）：

```
[commit] ★E_HANDLE#2 channel.Commit() 失败 hr=0x80070006（通道 2）
```
⇒ **出口 #2**：`Resolve` 没有返 null（通道还在），`PresentChannel` 也没失败 ——
**是某个命令处理函数返回了 E_HANDLE**（`Require&lt;T&gt;`：句柄不在资源表里 ⇒ E_HANDLE）。

### 4.15.2 是哪条命令、哪个句柄（提交前预检 + 生命周期台账）

诊断汇开启时会反射读 `MilChannel` 的私有批次（**只读、只在诊断时**），把待提交命令逐条解出来；
同时给 `MilResource_CreateOrAddRefOnChannel` / `DuplicateHandle` / `ReleaseOnChannel` 各加了台账。
实测把因果链**完整量了出来**：

```
[create] 通道 2 句柄 0x1 TYPE_ETWEVENTRESOURCE … 表内总数 4（0x2 视觉 / 0x3 HwndTarget / 0x4 矩阵，均已建好）
[release] 通道 2 句柄 0x3 ⇒ 摘除=True     ← 拆除开始：三个句柄**被立即摘除**
[release] 通道 2 句柄 0x4 ⇒ 摘除=True
[release] 通道 2 句柄 0x2 ⇒ 摘除=True
[closebatch] 通道 2 **待处理 7 条** ⇒ hr=0x0    ← ★ 一个从未闭合的批次还排着队
[preflight] #0 MilCmdHwndTargetCreate handle=0x3 在资源表里=False
            #1 MilCmdMatrixTransform 0x4 False
            #2 MilCmdVisualSetTransform 0x2 False   … 共 7 条，目标句柄全都不在表里
[commit] ★E_HANDLE#2
```

**结论**：7 条命令（`HwndTargetCreate`/`MatrixTransform`/`VisualSetTransform`/`SetClearColor`/
`SetRoot`/`UpdateWindowSettings`）早已入队但**从未闭合、也从未被处理**；
拆除先把它们的资源摘了，最后 `Channel.Close()` 才把它们派发出去 ⇒ 目标句柄全没了 ⇒ E_HANDLE。

### 4.15.3 这是**真实缺陷**（不是测试的锅）：我们"立即摘除"，上游是"延迟/流式"

* 上游原生 MilCore 有**渲染线程**，走的是**流式**处理：append 进去的命令很快被处理，
  而 UI 线程的 release 只是"排队摘除"——这也解释了上游为什么要分成
  `ProcessRemoves` / `ProcessCommands` **两个阶段**（该措辞就引在 T1 的
  `MilNative.cs` 注释里）。
* 本移植**没有渲染线程**，`Commit()` 是**唯一**处理点 ⇒ 一个未闭合批次会一直滞留到
  `Channel.Close()`，而那时资源已在拆除中摘除。
* ⇒ **修的是 interop 的时序语义，不是把错误吞掉**；测试的"已登记清单"**一个字都没改**。

### 4.15.4 修法（`src/WpfGfx.Linux/Interop/MilNative.cs`，本组边界内）

**"摘除前先冲刷"**：`MilResource_ReleaseOnChannel` 在真正摘除之前，若该通道还有排队的命令，
先把它们处理掉 —— 这是"流式处理"在无渲染线程移植里的等价物。

```csharp
MilChannel channel = MilChannelRegistry.Resolve(pChannel);
if (channel == null) return HResult.E_HANDLE;
…
FlushPendingCommandsBeforeInvalidation(channel);   // ← 新增：把排队的命令先处理掉
channel.Resources.Release(hResource, out bool removed);
```
两条守住语义的约束：

1. **不许在 commit 内部重入**：`_commitDepth`（句柄→重入深度）非零时**不冲刷**，
   否则批次正在被逐条派发、再冲一次会把整批**重复执行**。
2. **不吞错**：冲刷失败只记 `MilDiagnostics` + 诊断汇，**不改变 release 自己的返回值**
   （release 的契约是"引用计数减一"，批次的失败属于那次批次）。
   并且**命令若引用的是"更早已经真正摘除"的资源，照旧返回 E_HANDLE** ——
   `Require&lt;T&gt;` 一行未改。

### 4.15.5 对照（before → after）

| 观测点 | before | after |
|---|---|---|
| `HwndSource_Characterization_OnLinux` | **失败**（COMException 0x80070006） | **通过** |
| 拆除时 `closebatch` 的待处理条数 | **7 条**（随后 E_HANDLE） | **0 条** |
| 台账 | 只有 `★E_HANDLE#2` | 多一条 `[flush-before-release] 通道 2 冲刷待处理命令 ⇒ hr=0x00000000` |
| `ManagedLayer.Tests` | 27/28（5/5 稳定） | **28/28 × 连续 3 次** |

其它套件（同一桥）：`Windowing 44/44`、`HelloMil 19/19`、`Presentation 8/8`、`Commands 562/562`。

### 4.15.6 "是否为新暴露"：**是新暴露（i），不是本轮引入（ii）** —— 依据如下

1. 缺陷本身（未闭合批次 + 立即摘除）**一直存在**：它与 DPI/`LoGetEscString`/呈现触发器
   三处改动**没有代码交集**（那三处分别在 shim 的 DPI 面、文本转义表、呈现调用点）。
2. **是我的改动让它第一次走到**：修好 DPI/`LoGetEscString` 之后，`HwndSource` 才**真的把窗口建起来**，
   `MediaContext` 也才**第一次真正走到拆除**（`Dispose → RemoveChannels → Channel.Close()`）；
   在此之前建窗在**早期**就按"已登记理由"失败了，拆除根本到不了这里。
3. 判据不是"我觉得"：**改一处 → 现象翻转**（`flush-before-release` 一加，
   `closebatch` 的待处理 7→0、用例 失败→通过），而**测试期望与已登记清单零改动**。
   ⇒ 这是**缺陷修复**，不是放宽断言。

### 4.15.7 需要主控做的一件事（本组按边界没做）

**修复落在 AOT 桥里，要一次 MilBridge 发布才生效**：
`bash build/MilBridge/run.sh build`（本组按"不要动 `build/MilBridge/`"的边界**没有**执行它）。
本组的验证方式是**另开一份产物目录**、完全不碰 T1 的目录：

```bash
cd build/MilBridge/src/MilBridge.Linux
dotnet publish -c Release -r linux-x64 -m:1 -p:ArtifactsPath=/tmp/mb-diag   # 只读 T1 的源码
MILBRIDGE_MILCORE_SO=/tmp/mb-diag/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so \
  dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/*.csproj -m:1     # → 28/28
```
**反向对照**（不带该环境变量 = 用现网部署的那份 .so）：同一用例**仍然失败** ——
证明"没发布就不生效"，也证明这套证据确实来自新代码。

### 4.15.8 顺带留下的诊断能力（默认零开销）

* `WPF_LINUX_MIL_LOG=<path>`：把 `MilPresentation.Trace` 的行**写进文件**
  （`dotnet test` 里 stderr 不一定可见，而这类定位需要进程内证据）。
* 三个 E_HANDLE 出口各一条带编号的台账；`MilConnection_CommitChannel` 的**提交前预检**
  （解出待提交命令的 id/句柄/句柄是否在表里）；资源 create/dup/release 台账。
  全部只在诊断汇开启时跑，默认关闭。

---

## 4.16 轨道 B：`MILIStreamWrite` 真的把字节交还调用方 + 后台缓冲句柄能被当作 `IWICBitmapSource` 查询

主控派的两条（本轮插进来的），两条都**改了实现、给了对照实证**，并且顺带把
"上游契约里到底谁拥有描述符"这件事查清楚了 —— 修的过程中发现第一版修法是**错的**（见 4.16.3）。

### 4.16.1 问题 ①：用户的 `FileStream` 收到 0 字节（修前实测）

`MILIStreamWrite` 修前只把字节写进 `MilStreamObject.Data`（**本工程自己的**内存副本），
**从不调用描述符的 `pfnWrite`**。后果不是"少个功能"，而是**行为撒谎**：
WPF 级链路报"编码成功、字节数正确"，用户传进来的 `FileStream` 里一个字节都没有；
更荒谬的是"编码到只读流居然成功"。

实测（真 `PresentationCore` + NativeAOT 桥，`/tmp/m7cb-probe`，见 4.16.4）：

```
修前：[ OK ] StreamAsIStream.IStreamFrom(FileStream)
             MILIStreamWrite hr=0x00000000 cbWritten=6      ← 自称写了 6 字节
      [FAIL] 用户 FileStream 的落盘内容 == 写入的字节
             落盘 0 字节                                     ← 用户那边一个字节都没有
修后：       MILIStreamWrite hr=0x00000000 cbWritten=6
      [ OK ] 落盘 6 字节：DE-AD-BE-EF-01-02                   ← 同一份代码、同一个探针
```

### 4.16.2 问题 ②：`WriteableBitmap` 的后台缓冲句柄 QI 返回 `E_HANDLE`

上游链路（**逐行可查**）：`WriteableBitmap.TryLock` → `AcquireBackBuffer`
（`WriteableBitmap.cs:957`）拿到 `MILSwDoubleBufferedBitmapGetBackBuffer` 交出的
**像素缓冲令牌** → `_syncObject = WicSourceHandle = _pBackBuffer`（`:962`）→
`BitmapSource.set_WicSourceHandle`（`BitmapSource.cs:581-586`）对**这个令牌**调
`MILQueryInterface(token, IID_IWICBitmapSource, out _)`。
修前令牌既不在 `MilDeviceObjectTable`、也不被 WIC shim 认领 ⇒ **`E_HANDLE`**。

**修法（机制选择，三条约束都守住）**

| 约束（主控给的） | 本工程的落法 |
|---|---|
| 把它**登记成设备对象** | `MILSwDoubleBufferedBitmapCreate` 里额外登记一个 `MilDeviceObjectKind.WicBitmapSource` 设备对象，并把**令牌别名**到它（`MilBackBufferSourceTable`）。别名而不是换句柄：那个令牌**已被别处引用**（`MilPixelBufferTable` 用它取回 `SKBitmap`，WIC 生产面与 Skia 渲染面都在用），换值会把它们全打断 |
| **只对 `IID_IWICBitmapSource` 放行** | `MILQueryInterface` 里 `wicOk = (guid == IID_IWICBitmapSource && obj.Kind == WicBitmapSource)`；工厂、双缓冲**主对象**问这个 IID 仍然 `E_NOINTERFACE`（实测 `0x80004002`，见 `MilWicQueryInterfaceTests.非位图源对象_QI位图源_仍是E_NOINTERFACE`） |
| **不碰 `WicShim_*`、MIL 自己的句柄不许走外部那条路** | `MILAddRef`/`MILRelease` **先查别名**、再考虑外部转发；`MILRelease` 的别名分支排在 `MilExternalHandleBridge.TryReleaseExternal` **之前** ⇒ 这类句柄连探测都不会去探测 WIC（`OwnedHits`/`ProbeCount` 一根不动，实测见 4.16.5） |
| 引用计数契约（成功的 QI 会 AddRef、返回的指针一定由 `MILRelease` 释放） | QI 返回**同一个令牌**，AddRef 落在别名设备对象上、Release 也由**同一张** `MilDeviceObjectTable` 兑换；`MILAddRef(token)` 同样认（上游真会这么调：`D3DImage.cs:796 AddRef(_softwareCopy.WicSourceHandle)`） |
| fail-safe 保持 | 未登记句柄 + WIC 未接上 ⇒ 仍然 `E_HANDLE`（实测 `0x80070006`） |

**真 PC + AOT 桥上的对照（同一个探针，只换 `.so`）**

```
A) 旧 .so ：MILQueryInterface(backBuffer, IID_IWICBitmapSource) hr=0x80070006 E_HANDLE
             new WriteableBitmap(8,8,96,96,Pbgra32,null) → COMException 0x80070006
B) 新 .so ：MILQueryInterface(...) hr=0x00000000 ppv=0x20000005（同一对象=True）
             Release(qi) hr=0x0；Release(swdbb) hr=0x0
             换到下一道墙：HRESULT 0x80070057 → ArgumentException，
             栈 = set_WicSourceHandle → UpdateCachedSettings → PixelFormat.GetPixelFormat
                  → IWICBitmapSource_GetPixelFormat_Proxy（见 4.16.6 的边界披露）
```

### 4.16.3 修的过程中发现的**第一版修法是错的**（同一方法论：不实证不下结论）

第一版只做了"Create 时读出 `pfnWrite`，之后调用它"。真 PC 上一跑，进程 **FailFast**：

```
Assertion failed. Stream is disposed.
  at System.Windows.Media.StreamAsIStream.FromSD(StreamDescriptor& sd)   StreamAsIStream.cs:509
  at System.Windows.Media.StreamAsIStream.Write(StreamDescriptor& pSD, Byte[] buffer, ...)  :567
```

根因（**上游源码 + 实测双重确认**）：`ref StreamDescriptor` 跨边界给原生的是**一份临时副本**的地址，
调用返回后那块内存随时可能被复用 —— 而我当时把**那个地址**原样存下来、回调时又传回去，
上游 `FromSD` 读到的 `m_handle` 已经是垃圾。上游原生侧不这么做：
`exports.cpp:873` 是 `IStream* pStream = new CManagedStreamWrapper(*pSD);` —— **按值拷贝**，
之后每次回调都传 `&m_sd`（wrapper 自己那份）。

⇒ 改法：`MILCreateStreamFromStreamDescriptor` 把整份结构体（14 个函数指针 + 1 个 `GCHandle` = 120 字节）
拷进本工程 malloc 的内存，回调一律传**这份拷贝**的地址，流对象析构时 free。
测试用哨兵值钉住"整份都拷过来了"：回调收到的地址上，`m_handle` 槽必须等于测试写进去的哨兵，
且**不等于**调用方那个临时地址（`M7cMilStreamTests.把字节交还pfnWrite_真FileStream收到`）。

**顺带修掉的第二件事**：`MmapMinAddr` 守卫。取值这一步**会解引用调用方给的地址**
（上游同样如此），于是 `Commands.Tests` 那条用 `new IntPtr(0xDEF0)` 当描述符的用例
把这句解引用变成 **`AccessViolationException` → 测试宿主整个死掉**（实测：整轮 562 只跑到 510 就"测试运行已中止"）。
现在低于 `vm.mmap_min_addr`（本机 65536，读不到就按内核默认）的地址**不解引用**，
按"只读流"处理并留一条 NOTE ⇒ `Commands.Tests` 回到 **562/562**。
⚠️ 边界：这只挡"物理上不可能有效"的地址；**已映射但不是描述符**的指针照样崩（与上游一致，那是调用方 UB）。

### 4.16.4 描述符回调的**消费面**：14 个里 1 个有消费者，13 个没有（机械核对）

`StreamDescriptor`（上游 `StreamAsIStream.cs:14-59`）一共 **14 个函数指针** + `GCHandle`：

```
pfnDispose(0) pfnRead(8) pfnSeek(16) pfnStat(24) **pfnWrite(32)** pfnCopyTo(40) pfnSetSize(48)
pfnCommit(56) pfnRevert(64) pfnLockRegion(72) pfnUnlockRegion(80) pfnClone(88) pfnCanWrite(96) pfnCanSeek(104)
```

* 上游原生侧**全都消费**（`exports.cpp:713-860` 的 IStream wrapper 逐个转发）。
* **本工程只消费 1 个**：`pfnWrite`（`MILStreamObject.WriteCallback`，回调交还字节）。
  机械证据：`M7cMilStreamTests.StreamDescriptor_pfnWrite偏移与上游字段顺序一致` 解析上游源码数出
  14 个字段、核对偏移 32、并断言"委托转换点只有 1 处"。
* **剩下的 13 个没有原生消费者**：`pfnDispose / pfnRead / pfnSeek / pfnStat / pfnCopyTo / pfnSetSize /
  pfnCommit / pfnRevert / pfnLockRegion / pfnUnlockRegion / pfnClone / pfnCanWrite / pfnCanSeek`。
  其中对我们**真有影响**的是 `pfnRead`/`pfnSeek`/`pfnStat`：
  上游 `MILCreateStreamFromStreamDescriptor` 出来的 IStream 是要给原生**解码器/编码器**当输入用的，
  只实现 Write 的话，**"把 WPF 的流喂给解码器"这条方向仍然是断的**（只有"编码器往流里写"这条通了）。

### 4.16.5 配平与高水位（照 T1 的 G6/G6b 口径，**不只断言稳态相等**）

`MilWicQueryInterfaceTests.创建释放N轮_MIL与WIC两本账都回基线且高水位不涨`（40 轮，一半走 QI+Release、
一半直接拆，**轮内采样**取高水位；WIC 侧把桥接指向 `build/DirectWrite.Linux/wic-shim/libwpfwic.so` 后读它的活句柄数）：

```
[MIL] 设备对象 0→0（高水位 2）；位图表 0→0（高水位 1）；别名表 0→0（高水位 1）
[WIC] 活句柄 0→0（高水位 0）；shim 高水位 0→0（观测 0）；OwnedHits 0→0、ProbeCount 1→1
WIC shim: .../libwpfwic.so（存在=True 已接上=True）
```

* 稳态回基线：设备对象表 / 位图表 / 别名表 / WIC 活句柄 —— 全部 `0 → 0`。
* **高水位不涨**：设备对象峰值 2（= 一轮里 swdbb + 别名，之后归零），别名表 1，位图表 1。
  （第一版只在轮末采样，位图表峰值永远是 0 —— 那条断言是**空的**，已修成轮内采样。）
* **账本不串门**：`OwnedHits` 0→0、`ProbeCount` 1→1 ⇒ MIL 自己的令牌一次都没被 WIC 认领，
  shim 的活句柄与它自己的高水位一根没动 ⇒ "两边账本单边"没有发生。
* 顺带修掉两处**表只增不减**：`MilDoubleBufferedState.Dispose` 现在会
  `MilPixelBufferTable.Unregister(BackBufferHandle, force:true)`（借用登记，只摘句柄），
  并 `MilBackBufferSourceTable.Forget(...)`（引用计数感知：还有别人的引用时**不摘**别名，
  让迟到的 Release 仍能把它减到 0 —— 有专门用例钉住）。

### 4.16.6 边界披露（轨道 B）

1. **下一道墙在 WIC proxy 层，不在本组边界内**：QI 通过之后，`BitmapSource.UpdateCachedSettings`
   接着调 `IWICBitmapSource_GetPixelFormat_Proxy(token)` —— 那是 `WindowsCodecs.dll` 的
   **proxy**（PC 的解析器把 `WindowsCodecs.dll` 映射到 `libwpfwic.so`），而 shim 的
   `as_source(token)` 查自己的表 → 令牌不在里面 ⇒ `E_INVALIDARG`。
   上游 Windows 上这一步能过，是因为那里的句柄是**真 COM 指针**、proxy 转发的是一次 vtable 调用；
   我们的 shim 是"表查找 + 固定行为"，**任何被当 `IWICBitmapSource` 交出去的 MIL 句柄，proxy 层都得能派发**。
   三条可能路线，**都超出本组可写边界**：
   ① shim 增加"外来句柄派发钩子"（`build/DirectWrite.Linux/`，T2）；
   ② `WindowsCodecs.dll` 的映射路由到 MIL 侧再转发（`build/shims/`）；
   ③ 让后台缓冲本身由 WIC 拥有（改的是 `MILSwDoubleBufferedBitmap` 的所有权模型，得主控拍）。
   **本轮按主控约束（MIL 自己的句柄不许进 `WicShim_*` 那条账）没有做①**，只把墙的位置与证据交上去。
2. **`mmap_min_addr` 守卫只管"物理上不可能"的一类**，已映射的错地址仍会崩（= 上游 UB）。
3. **`pfnRead`/`pfnSeek`/`pfnStat` 未实现** ⇒ "解码器从 WPF 流读"这个方向仍不通（见 4.16.4）。
4. **AOT 桥需要重发布**：`build/MilBridge/.artifacts/publish/.../wpfgfx_cor3.so` 是 18:26 的产物，
   本轮的 `Interop/` 改动**不在里面**。本组的实证走的是
   `dotnet publish -p:ArtifactsPath=/tmp/mb-diag`（**不写仓库**，已用 `find -newermt` 核对过）
   + `MILBRIDGE_MILCORE_SO=` 指过去。**真 PC 端到端要复现，需要 T1 重发布一次桥。**

---

## 4.17 轨道 C 复验（真接窗 / resize 跟随 / X 事件反向派发）：证据与回归

### 4.17.1 三条判据各自的证据（`tests/.../ManagedLayer.Tests/M7cRealAttachmentTests.cs`，真窗口 + 独立进程 xwd + 逐像素）

```
[①] xwd 200x120：纯红像素 = 24000（窗口 200x120 = 24000）            ← Attach 后**真的**有像素
[②] Detach 后再呈现：hr=0x80004005，帧数 1 → 1                        ← Detach 后**真的**停了
[②] Detach 后窗口里的填充像素 = 24000（Detach 前 24000）              ← 画面一个像素都没动
[③-before] 200x120，填充像素 24000（≈24000）
[③-event]  ResizeEvents=1 ExposeEvents=1 需重画窗口数=0
[③-after]  320x200：内容(红)=24000 我们的清屏(绿)=40000 X 窗口底色(白)=0
                                                      ↑ 24000+40000=64000=320×200，**没有留空白条**
[④-expose] ExposeEvents 1 → 2，帧数 1 → 2
[④-closed] ClosedEvents=1，HasTarget=False                            ← Closed 真的派发并解绑
```

第 ③ 条的"填充像素 24000 → 64000"就是债务 #3 的**销账判据**：resize 之后整帧按新尺寸重渲，
X 窗口底色像素为 **0**（旧尺寸图 + 空白条的症状消失）。
`ResizeEvents/ExposeEvents/ClosedEvents` 三个计数器**免采样**（`WpfGfx.Linux/Interop/MilPresentation.cs`），
关键状态转换不会被台账节流吞掉 —— 这条纪律是本轮刻意保持的。

### 4.17.2 回归（Xvfb :99，`-m:1`，全部本轮实跑）

| 套件 | 结果 |
|---|---|
| `ManagedLayer.Tests` | **44 / 44**（28 基线 + 3 轨道 C + **13 轨道 B 新增**，已跳过 0） |
| `Windowing.Tests` | **44 / 44** |
| `HelloMil.Tests` | **19 / 19** |
| `Presentation.Tests` | **8 / 8** |
| `Commands.Tests` | **562 / 562** |

### 4.17.3 `docs/unimplemented.md` §2.4 与债务 #3：**建议替换文本**（文档归主控，本组只报）

> **§2.4（Attach/Detach 一组）建议改为：**
>
> `MilVisualTarget_AttachToHwnd` / `MilVisualTarget_DetachFromHwnd` **已不只是身份映射**：
> Attach 在身份登记之外调用 `MilPresentation.TryBind(hwnd)`（HWND == XID，M7b 实证），
> 为该窗口 `X11Window.Wrap` 出呈现目标并订阅 `ExposureMask | StructureNotifyMask`（**只加本连接自己的掩码**，
> 不动 shim 的输入掩码）；Detach 调 `MilPresentation.TryUnbind(hwnd)`，只释放我们建的 GC、**不销毁窗口**。
> X 事件反向派发在 `MilPresentation.PumpWindowEvents()` 里（Expose → 需重画、ConfigureNotify → 尺寸更新、
> DestroyNotify → 解绑），并在每次呈现入口先抽干事件队列。
> **证据**：`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cRealAttachmentTests.cs`
> —— 真 `HwndWrapper` 窗口 + **独立进程** `xwd` 抓帧 + 逐像素计数：
> Attach 后纯色像素 24000/24000；Detach 后 `hr=E_FAIL` 且像素数不变；
> resize 200×120 → 320×200 后填充像素 24000 → 64000、X 窗口底色 **0**；
> Expose / Closed 各计数 +1 并产生对应动作。
> （保留原条目里仍然成立的部分：HRESULT 语义与 `vt_api.cpp:24/67` 对齐、句柄不复用、
> 冲突拒绝 = `E_ACCESSDENIED`；render-thread 相关的那部分不属于本节。）

> **债务 #3（`docs/ARCHITECTURE.md` §8）建议改为：**
>
> **已销账（呈现层）。** `IPresentationTarget.Resize` 之后，呈现层自己会把内容按新尺寸重渲：
> `MilPresentation.PresentChannel` 在呈现这一刻以 **X 窗口当前尺寸**（"自上次呈现以来**变了**"才算，
> 不是"与通道里记的不等"——启动时两者本来就不等）为准重新投影根视觉并渲染，
> 因此不再出现"旧尺寸图 + 一块 X 底色空白"。
> **判据（可复算的整数）**：resize 前后"我们画上去的填充像素数"必须等于新 W×H ——
> 200×120（24000）→ 320×200（64000），且 X 底色像素 = 0。
> **仍然成立的部分（不是本债务，但相邻）**：真应用里 resize 之后的**几何/布局变化**要等上层的
> resize→渲染 pass（`HwndTarget.OnResize` → `MediaContext.Resize`），本移植没有原生渲染线程；
> 这一条在 §4.18.2 里作为观测项登记（本轮仪器还答不了"新尺寸画面是谁画的"，不下结论）。

---

## 4.18 本轮 app 级新暴露的两个问题（**都不在本组可写边界内，但必须上报**）

### 4.18.1 鼠标输入会把真应用弄死（`TextServicesLoader` 空引用 → SIGABRT）

复现：HelloWpf 跑起来后把指针移进窗口（实测用 `xdotool windowsize` 把窗口**放大到指针所在处**，
X server 发 EnterNotify 即触发）：

```
Unhandled exception. System.NullReferenceException
   at MS.Internal.TextServicesLoader.TIPsWantToRun()            TextServicesLoader.cs:192
   at MS.Internal.TextServicesLoader.get_ServicesInstalled()    :133
   at System.Windows.Input.TextServicesManager.PreProcessInput  TextServicesManager.cs:118
   at System.Windows.Input.InputManager.ProcessStagingArea()    InputManager.Linux.cs:728
   at System.Windows.Input.InputManager.ProcessInput(InputEventArgs)
   at System.Windows.Interop.HwndMouseInputProvider.ReportInput  HwndMouseInputProvider.cs:1422
   at System.Windows.Interop.HwndMouseInputProvider.FilterMessage :438
   at System.Windows.Interop.HwndSource.InputFilterMessage        HwndSource.cs:1569
   ... → Application.Run → 进程 SIGABRT（退出码 134，core dumped）
```

**影响**：这是"真 WPF 窗口"能不能被人用的门槛 —— 任何鼠标移动都够触发。
**为什么以前没撞到**：M2 验收全程没有输入事件（零探针那一跑只截图）。
**归属**：输入路径（`TextServicesLoader` 是上游 PC 代码，它下面的 Win32 面是我们的 shim）
⇒ 修法要么在 shim 补它要的那几个 API，要么在 PC 侧补一个"没有 TSF"的判定。
**定性说明（按主控的"先隔离再归因"要求）**：本 runner 里把指针**先挪开**再 resize，应用全程存活
（退出码 143 = 我们自己 TERM），所以这个崩溃是**输入触发**、与 resize 无关。

### 4.18.2 app 级 resize 的观测**自相矛盾**：画面确实铺满了新尺寸，但台账与通道计数都没动

（同一跑，`MILBRIDGE_MILCORE_SO` 指向本工程**当轮**发布的桥 .so，`WPF_LINUX_MIL_LOG` 记全量台账）

```
X 侧窗口：900x620（xwininfo）        应用收到 WM_SIZE 次数：3（最后一次 lp=0x26c0384 = 900x620）
台账：resize 之后**没有**新尺寸的呈现帧（等 10s）；通道#2 committed=72 全程不变
截图（独立进程 xwd，900x620）：
  · 纯白（X 窗口底色）像素 2347 / 558000
  · 左上 667x417 与 resize 前的帧逐像素差 AE=229378/278139；把 after 缩回 667x417 再比 AE=172056
  · 元素位置与 resize 前**逐点一致**（矩形 bbox 都是 486x224+17+24），背景渐变按新尺寸重新求解
```

**能确定的事实**：画面上**不是**"旧尺寸图 + 空白条"（新的右/下区域被背景渐变铺满，
X 底色只占 0.4%），且背景渐变确实按新尺寸重算过 ⇒ **某个东西按新尺寸重画了**。
**不能确定**：是谁画的 —— MIL 台账（含**绕过预算**的文件汇）、通道计数器、xwd 三样加起来都没指认出来。
按主控的纪律，**这里不下结论**，只登记矛盾与下一步的观测手段：
① 在 `X11Window.Present` 里加**非节流**的调用计数（当前只有台账，且台账在 AOT 副本里）；
② 用 `xwd` 在 resize 前后各拍两张（+50ms / +3s）区分"瞬间铺上"与"稍后重画"；
③ 检查是否存在**第二个 X 窗口/子窗口**承载内容（`xwininfo -tree`）。

---

## 4.19 任务 1：鼠标输入把真应用弄死（TSF 空引用）—— 根因、修法、红→绿实证

### 4.19.1 现象与第一现场（实测栈）

指针进窗口（含"窗口放大到指针所在处"引发的 EnterNotify）即可触发：

```
Unhandled exception. System.NullReferenceException
   at MS.Internal.TextServicesLoader.TIPsWantToRun()             TextServicesLoader.cs:192
   at MS.Internal.TextServicesLoader.get_ServicesInstalled()     :133
   at System.Windows.Input.TextServicesManager.PreProcessInput   TextServicesManager.cs:118
   at System.Windows.Input.InputManager.ProcessStagingArea()     InputManager.Linux.cs:728
   at System.Windows.Interop.HwndMouseInputProvider.ReportInput  :1422
   → Application.Run → **SIGABRT（134）**
```

`TextServicesLoader.cs:192` 逐字是：

```csharp
key = Registry.CurrentUser.OpenSubKey("Software\\Microsoft\\CTF", false);
```

Unix 上 `Microsoft.Win32.Registry.CurrentUser` / `LocalMachine` / `ClassesRoot` **返回 null**（不是抛异常），
而上游这里**没加守卫**；`catch` 只捕 `IOException`/`SecurityException` ⇒ **NRE 谁也接不住**。
这与补丁 G（`SecurityHelper`）、补丁 J（输入栈 5 处）是**同一个家族**，J 当时**漏了这一处**
—— 因为它不在"输入设备初始化"那条路上，而在"**每次输入都过一次**"那条路上。

### 4.19.2 修法：补丁 M（源码级；**目标是 WindowsBase 不是 PresentationCore**）

应用器：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textservices.py`（`--check` / `--out` / `--apply`，幂等，锚点唯一否则报错退出）。
两处改动：

| 位置 | 改法 |
|---|---|
| `:192` | `Registry.CurrentUser.OpenSubKey(...)` → `Registry.CurrentUser?.OpenSubKey(...)`（之后走上游**原有的**"没有这个键"分支，下面每一处都判了 `key != null`） |
| `:205` | `IterableSubKeys(Registry.LocalMachine, …)` → 先取局部变量，`hklm == null` ⇒ `return false`（= 本方法契约里的"这台机器没有 TIP"） |

**⚠️ 实测纠正（这条很要紧）**：`TextServicesLoader.cs` 编进的是 **WindowsBase**，不是 PresentationCore ——
`build/WindowsBase.Linux/WindowsBase.Linux.csproj:281` 就是那句 `<Compile Include=…TextServicesLoader.cs />`。
崩溃栈里它被 PC 的 `TextServicesManager` 调到，是因为 PC 对 WB 的 internal 有 IVT。
**补丁打到 PresentationCore = 一行都不生效**（我第一版就写错了，靠"启动钩子里反射找不到类型"实测发现）。
csproj 接线（两行）：把 281 行改成 `Remove` + 加 `<Compile Include="TextServicesLoader.Linux.cs" />`。

**这是"对齐"不是"降级"**：方法自己的契约写着
"true if one or more text services are installed for the current user"、
"If this method returns false, Load is guaranteed to return null"。
Linux 上没有 CTF/TIP 注册表 ⇒ "没有安装任何文本服务"是**真话**，于是 `ServicesInstalled == false`，
`TextServicesManager` 走的是**上游为"Windows 上没装 TIP 的机器"写的那条分支**。
Windows 上两个根键恒非 null ⇒ `?.` 与 null 分支永不触发，**行为逐字不变**。

### 4.19.3 红 → 绿对照实证（同一 runner、同一注入脚本，只差"那一处状态"）

判据两条（**缺一即 FAIL**）：ⓐ 应用存活（它是 runner 拉起的**子进程**，崩了不带走测试宿主）；
ⓑ 事件**真的到达窗口**（WM_MOUSEMOVE 0x0200 / WM_LBUTTONDOWN 0x0201 / WM_MOUSEWHEEL 0x020A / WM_KEYDOWN 0x0100）
—— ⓑ 就是**防"用抑制输入换不崩"**的那一条。

```
A) 现状：MOUSEMOVE=1 LBUTTONDOWN=0 MOUSEWHEEL=0 KEYDOWN=0   ⓐ 应用存活：否（NRE → SIGABRT）   INPUT_PROBE=FAIL
B) 修后：MOUSEMOVE=3 LBUTTONDOWN=1 MOUSEWHEEL=2 KEYDOWN=2   ⓐ 应用存活：是                    INPUT_PROBE=PASS
```

> B 的"修后"用什么做的：PC 重建由集成波负责，所以本轮用一个**仓库外**的过渡探针拿到"改这一处 → 现象翻转"的
> 因果实证：`DOTNET_STARTUP_HOOKS=/tmp/tsfhook/…`（CoreCLR 启动钩子，反射把
> `s_servicesInstalled` 置成 `NotInstalled`，**语义与补丁 M 逐字等价**），作用域仅 `/tmp`、不入仓库。
> 补丁 M 落地 + 重建 WindowsBase 后，同一判据应直接 PASS。

**顺带否证了一条路（记录下来免得别人重走）**：**AOT 桥不能**反射改 PC ——
桥是 NativeAOT 共享库，**自带一个运行时**，`AppDomain.CurrentDomain.GetAssemblies()` 只看得见它自己镜像里的程序集，
`PresentationCore`/`WindowsBase` 属于宿主 CoreCLR，**根本不在它的视野里**。
实测证据：在桥里挂的过渡层一直打印 `[tsf-compat] 跳过：PresentationCore 尚未加载`（连 `MilVersionCheck`/`CommitChannel` 入口都如此）。
⇒ **跨边界改 PC 状态只能走源码补丁（补丁 M），没有运行期捷径。**

### 4.19.4 门禁（先能红，再谈修）

`tests/.../ManagedLayer.Tests/M7cInputPathTests.cs`（4 条）：

| 用例 | 判据 | 现在 |
|---|---|---|
| `Unix上Registry根键是null_而上游那两处直接解引用` | 根键为 null；未加守卫必 NRE；加守卫 ⇒ null | 绿（机制层） |
| `上游ServicesInstalled_必须不抛且为false_而不是NRE` | 上游 API 不抛且 false | **红（补丁 M 未落地）** |
| `补丁M_可生成且自检通过_生成物里两处守卫都在` | 应用器 `--check` 通过、生成物含两处守卫 | 绿 |
| `端到端_真应用收到指针与按键_不崩且事件到达窗口` | 子进程跑 runner，`INPUT_PROBE=PASS` | **红（同上）** |

两条红的按设计就是红的（主控要的"先能红"）：它们就是**待集成的补丁 M 的验收门禁**，
补丁 M + 重建 WindowsBase 后应转绿。要跑基线全套时用 `--filter "Category!=Input"` 排除。

**⚠️ 当前 `ManagedLayer.Tests` 的红是本轮新增用例的"预期红"，不是回归。**
主控在 verify-all 里抓到我这两条用例**自身**的两个缺陷，已修（记在这里，免得下一个人重踩）：

| 缺陷 | 症状 | 修法 |
|---|---|---|
| 直接索引环境字典取 `DISPLAY`（`psi.Environment["DISPLAY"]`） | **没设 DISPLAY 时抛 `KeyNotFoundException`** ⇒ 用例结论取决于"跑测试的人设没设环境变量"，不是被测行为（**彩票，不是断言**） | 改用 `Environment.GetEnvironmentVariable`；为空 ⇒ **显式跳过**并打印原因（本用例本来就要真窗口 + 真指针） |
| 反射找 `MS.Internal.TextServicesLoader` 只查了 PresentationCore | 报"找不到类型" ⇒ 看起来像"修法未落地"，其实是**测试写错** | 该类型在 **WindowsBase**（`WindowsBase.Linux.csproj:281` 就是它的 Compile 项）；改成两个程序集都查，失败信息列出试过的位置 |

⇒ 现在两条红的**失败原因就是行为本身**（一条 `INPUT_PROBE=FAIL`、一条报出 `TextServicesLoader.cs:192` 的 NRE 第一现场），
不再是测试自己的毛病。**这个区别很重要**：主控点名"类型名找不到"与"修法未落地"是两件事。

### 4.19.5 core dump 与债务 #9

* `ulimit -c` = **0**（本会话）；`/proc/sys/kernel/core_pattern` → apport ⇒ **本轮的 SIGABRT 不落地 core 文件**。
* 全仓 `find . -name 'core.*'`（排除 `upstream/`）= **空**；`tests/.../Windowing.Tests/` 下**已无** `core.*`。
* `/var/crash` 只有两条与本工程无关的条目（`python3.10`、`xfce4-panel`，时间早于本轮）。
⇒ 债务 #9 的"4 个历史 core 文件"在树里已不存在；**归因**由本节给出（同一类 SIGABRT 的产物），
即主控"已清、归因不跟着销"的处理可以引用这里。

---

## 4.20 任务 3：resize 观测盲区 —— 先修假绿灯，再归因（现已归因完毕）

### 4.20.1 假绿灯（主控实测抓到）：`grep -mE1` 自己失败，✅ 照打

```
   应用收到的 WM_SIZE 次数：3 （最后一次：0x26c0384）
   ✅ 台账里出现**新尺寸**的呈现帧（等了约 0s）：
grep: 无效的最大计数
```

`grep -mE1` 是**非法组合**：`-m` 的实参必须是数字，`E1` 会被当成计数 ⇒ grep 报错、退出码 2；
而它写在 `$( … | sed … )` 里，**管道最后一环是 sed** ⇒ 失败被吞掉、空串照打 ✅。
修法（三处一起，缺一不可）：

1. **判据改成"取到的值非空"**，不看 grep 的退出码：`x="$(grep -E … | head -1)"; [ -n "$x" ] && …`；
2. **判据看增量**：先记 resize 前"该尺寸的行数"，要求 resize 之后**增加**
   （否则"启动帧本来就是 900x620"会立刻打 ✅ —— 我自己把 resize 目标设成当前尺寸时就撞到过）；
3. **脚本开头加 grep 自检**：`printf 'x\n' | grep -q x` 不过就 `exit 2`（本脚本**每一处**判据都建立在 grep 上）。

### 4.20.2 归因（不是"再截一张图"能解决的）：**被观测对象已经死了**

决定性实验：把输入路径修好之后再跑同一条 resize 流程（同一 runner、同一注入、只多了过渡探针），台账**免采样**那一行直接给出了答案：

```
★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200005 已呈现 900x620（skia 指令 7 条，未画种类 0）  累计帧数 = 72
… 之后每一帧都是 900x620 …                                            累计帧数 = 830
```

⇒ **我们的呈现层在 resize 之后确实按新尺寸出帧了**。此前那几次"台账没有新尺寸帧"的观测，是因为：

1. **应用在观测之前就已经被输入 NRE 弄死了**（resize 段前面那一步"挪指针"就会触发它）——
   runner 现在会先判 `kill -0 $APP_PID`，死了就打 **"❌ 观测无效"** 并**不再输出任何 resize 结论**；
2. **更早那一版台账对呈现明细是抽样的**（`n <= 5 || n % 120 == 0`），尺寸变化这一关键转换可能整段落进空档 ——
   本轮已把它改成**尺寸变化免采样**（`TracePresentResult`），这次的 `★ 呈现尺寸变化` 行就是它打出来的。

**教训（写进报告，不只写进脑子）**：观测体系的盲区**常常不在仪器本身，而在"仪器读数的前提"**
（被观测对象还活着 / 关键转换有没有被节流）。所以判据里现在有两道**前提检查**：
"应用还活着吗"与"这一行是 resize **之后新增**的吗"。

### 4.20.3 主控那次运行的原始数字（仅作参考，已标注）

主控在 `:98`、用**半成品脚本快照**跑出的数字与本节一致：X 侧 900x620、`WM_SIZE`×3、
纯白 1309/558000、before/after 裁剪 AE=510,401（⇒ 画面确实变了）。**这几条与本节结论不冲突**，
只是没有"新尺寸呈现帧"这一条台账证据（当时台账还没免采样）。

---

## 4.21 任务 2（P0，新）：**默认配置一个字都不画** —— 实测根因与方案（**先方案，未动手**）

### 4.21.1 现象（主控 A/B，我复现并读到第一现场）

不设任何字体 env（= **真应用默认拿到的路径**）跑 HelloWpf：`未画种类 1`、PNG 46,902 B、**文字整段不画**；
设 `WPF_LINUX_TEXT_FONT_DIR=build/fonts-ui` 或 `HLWPF_UI_FONT=…/UI-NoLayout.ttf` ⇒ `未画种类 0`、56,055 B、有文字。

### 4.21.2 【实测】根因**不是**"族名猜错"，而是**候选字体文件数 = 0**

我本轮给 `EnsureGlyphRenderer` 加了第一现场诊断（选目录/请求字族/**实际解析到的面**/候选文件数/MIL 侧字体面登记数），
默认配置下实测：

```
[mil 12] 字形渲染器已挂上：目录=/usr/share/fonts 请求字族=Noto Sans 实际面=<未解析> 候选文件=0
[mil 15] NOTE ★★ 字形指令**没有画出来**（MilDrawGlyphRun×2）。诊断：… 候选文件=0；MIL 侧字体面登记数=0
```

原因在 `Text/FontSet.FromDirectory`：它只用 `Directory.EnumerateFiles(dir, "*.ttf"|"*.otf"|"*.ttc")`
**扫顶层、不递归**，而 `/usr/share/fonts` 顶层**一个字体文件都没有**（都在 `truetype/<vendor>/`、`opentype/…` 下）
⇒ `FontSet` 是**空集** ⇒ `TryResolve` 永远失败 ⇒ `MilDrawGlyphRun` 被记进 NotDrawn、**一个字都不画**。
（主控提出的"`Noto Sans` vs `DejaVu Sans` 面不匹配"是**第二层**风险：文件一旦被找到，
族名与面仍可能不是同一个 —— 我加的"不是请求的那个面"诊断就是盯这一层的。）

### 4.21.2b Windows 真机 oracle 给的真值支撑（主控转来）

* **`MessageFontFamily` 是数据驱动的每用户设置**（不是硬编码）：真机六个字体族属性全为 `Microsoft YaHei UI`；
  `SPI_GETNONCLIENTMETRICS.lfMessageFont.lfFaceName` = `HKCU\Control Panel\Desktop\WindowMetrics\MessageFont`（92 字节 `LOGFONTW`）
  = `SystemFonts.MessageFontFamily.Source`，且**必在 `Fonts.SystemFontFamilies`（91 个族）里**。
  ⇒ **对我们的意义**：SPI 报出来的那个族必须是"系统集合里真能解析到的族"。我们报 `DejaVu Sans`（确实在 `/usr/share/fonts`）—— **这一层合规**；
  不合规的是渲染器**硬编码兜底 `Noto Sans`**（系统里没有真正的 `Noto Sans` 族）。
* **"glyph id 的面 ≠ 光栅化的面"在 Windows 上是另一种形态、同源**：同一 face 在 DWrite 与 Win32 两套命名下族名不同
  （`MSYHL.TTC#1`：`familyNames="Microsoft YaHei UI"` / `win32FamilyNames="Microsoft YaHei UI Light"`；
  同族 3 文件 / 6 face；Light 的字重是 **290** 不是 300 ⇒ 按字重匹配也可能落到别的 face；
  `glyphCount` 逐 face 不同 29816/30202/29949 ⇒ **glyph id 是逐 face 的**）。
  ⇒ 根因同一条：**光栅化用的 face 不是产出 glyph id 的那个 face**。修法方向（面由 run 决定）因此**更硬**，不是推测。
* **边界（照主控要求写）**："数据驱动的每用户持久化设置（**已证**）；**是否随主题变未验证**" —— 真机 7 个 `.theme` 文件里
  没有任何一个含 `[Control Panel\Desktop\WindowMetrics]` 段。**不要写成"随主题变"**。
* 另一条**写字体探针才会踩的坑**：`<InvariantGlobalization>true</InvariantGlobalization>` 会让
  `FontFamily.FamilyNames` 抛 `CultureNotFoundException: en-us is an invalid culture identifier`
  ⇒ 在测试里反射查族名前先确认这一项没开，否则会得到一个**与 WPF 无关的假红**。

### 4.21.3 方案（三步，分泳道；**请主控裁**）

| 步 | 内容 | 泳道 | 为什么必须 |
|---|---|---|---|
| **A** | `Text/FontSet.FromDirectory` 改成**递归**枚举（`SearchOption.AllDirectories`，去重后仍按序） | **T2**（`Text/`） | 不递归 ⇒ 系统目录永远 0 个候选文件，默认配置**必然**不画字 |
| **B** | 默认字族**不再硬编码**：改用 `SystemParametersInfo(SPI_GETNONCLIENTMETRICS).lfFaceName`（shim 侧 `WPF_DEFAULT_UI_FONT = "DejaVu Sans"`，与 WPF 的 message font **同源**）；env 覆盖顺序不变 | **我**（`Interop/MilPresentation.cs`） | "渲染器猜族名"至少要和 **WPF 实际用的族**同源；实测 WPF 侧是 `DejaVu Sans`，而我写死的是 `Noto Sans` |
| **C** | **面由 run 决定**（主控要求的真修法）：`MILCMD_GLYPHRUN_CREATE.PIDWriteFont`（偏移 8）现在**被解码后丢弃**（`Commands/MilCommandDispatcher.cs:897-913`），`MilGlyphRun` 里没有字体字段，且实录 **`MilFontFaceTable.Count = 0`**（PC 侧**没有任何** `MilFontFace_RegisterFromFile` 调用者）⇒ 需要：PC 把实际用的面登记一次并把**句柄**当 `PIDWriteFont` 传下来 → MIL 存进 `MilGlyphRun` → 渲染器优先用 `MilFontFaceTable.TryResolve(句柄)`，失败才退回族名解析（`TextRenderer.MilFontResolver` 钩子本来就是为这件事留的） | A/B 的**长期解**：PC 侧登记（T2 的字体栈/`build/DirectWrite.Linux`）+ 字段存储（`Commands/`+`Resources/`，T1 或我）+ 渲染器优先面（T2 `Text/`）；我提供 `MilFontResolver` 侧的接线与诊断 | 只有这样才能满足 handoff:1539 的不变量："glyph id 是字体相关的，必须与 WPF 侧**同一份字体**" |

**验收（三档都要过，且请读图确认，不看直方图）**：
① 不设任何字体 env ⇒ `未画种类 0` + 文字在屏上；② `WPF_LINUX_TEXT_FONT_DIR=build/fonts-ui` ⇒ 不退步；
③ `HLWPF_UI_FONT=…/UI-NoLayout.ttf` ⇒ 不退步。**这三档已做成 runner 的默认可重复档**（`HLWPF_FONT_SWEEP=1`，见 §4.22）。

---

## 4.22 本轮 runner 修复清单（都在 `run-hellowpf.sh`）

| # | 问题 | 修法 |
|---|---|---|
| 1 | `grep -mE1` 非法实参 ⇒ **假 ✅** | 判据改为"取到的值非空"；并把"新尺寸行数增量"当判据（§4.20.1） |
| 2 | `M7C_RUN_DIR` 默认固定 ⇒ **并发运行互相覆盖**（主控截图被覆盖丢失） | 默认改成 `/tmp/m7c-hellowpf-$$`，并在注释里写明"要固定路径就显式传" |
| 3 | 观测前提未检查 ⇒ "应用已死"被写成"没重渲" | resize 段先 `kill -0`，死了就打 **"❌ 观测无效"** 并跳过所有结论 |
| 4 | 无 X 时应用抛 `Win32Exception(1400)`，看起来像 shim 坏了 | 开头 `xdpyinfo -display $DISPLAY` 自检，失败 `exit 2` 并说明 |
| 5 | 脚本被判据读成"半成品"（编辑中） | 编辑一律 **先写临时文件再 `os.replace` 原子替换**；每次编辑同一命令里跟 `bash -n` |
| 6 | 三档字体配置没有可重复入口 | 新增 `HLWPF_FONT_SWEEP=1`：依次跑"默认 / TEXT_FONT_DIR / UI_FONT"三档并汇总（供 §4.21 验收） |

---

## 4.23 任务 4（顺手做）：把后缓冲句柄登记成 WIC **外来源**（派发），记账一字未动

### 4.23.1 改动点（`file:line`）

| 位置 | 内容 |
|---|---|
| `src/WpfGfx.Linux/Interop/MilNative.Misc.cs:683-780`（`MilExternalHandleBridge`） | 新增两个入口点常量 + 一个计数入口点（`WicShim_RegisterForeignSource` / `WicShim_UnregisterForeignSource` / `WicShim_ForeignSourceCount`）、两个 `[UnmanagedFunctionPointer(Cdecl)]` 委托、懒解析（与既有 `WicShim_*` 同一套 `EnsureProbed`/`CandidatePaths`）、以及 `RegisterForeignSource/UnregisterForeignSource/ForeignSourceCount` 三个**fail-safe 包装**（取不到导出返回 `E_NOTIMPL`，**不抛、不硬失败**）+ 三个断言用计数 |
| `src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs:266-296`（`MILSwDoubleBufferedBitmapCreate`） | 紧跟 `MilDeviceObjectTable.Register(MilDeviceObjectKind.WicBitmapSource, …)` 之后登记：`RegisterForeignSource(state.BackBufferHandle, ref pixelFormatGuid, width, height, isOpaque)`；`isOpaque` = **仅** `Bgr32` 为真（**近似，代码注释里照实写了**）；`pixels/rowBytes` 恒 NULL/0 |
| `src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs:143-162`（`MilDoubleBufferedState.Dispose`） | **顺序**：① `UnregisterForeignSource` → ② 摘别名设备对象 → ③ 摘 `MilPixelBufferTable` 借用登记 → ④ 释放 SKBitmap（把 `pixels` 借给 shim 的那一步若将来要做，顺序不能反） |

**编译：0 错 0 警**（`dotnet build src/WpfGfx.Linux`）。

### 4.23.2 记账边界（主控点名，实证"没动"）

* **引用计数仍全在 `MilDeviceObjectTable`**：`MILAddRef/MILRelease/MILQueryInterface` 一行未改；
  `WicShim_OwnsHandle` 对外来条目返回 0、`HandleCount` 不数它们。
* 实测（`MilWicQueryInterfaceTests.后缓冲登记为WIC外来源_派发可用且记账未变`）：
  `登记次数 40 → 41（hr=0x00000000）；设备对象 0→2、位图表 0→1、别名表 0→1、**WIC 活句柄 0→0**`；
  拆除后 `注销次数 +1`、四张表**全部回基线**；`外来源登记 0↔0`（40 轮后回到 0）。
* **反放宽断言仍绿**：`非位图源对象_QI位图源_仍是E_NOINTERFACE`（工厂/双缓冲主对象问 `IID_IWICBitmapSource` 仍 `E_NOINTERFACE`）。
* 一处**必须写清的断言修正**：接上派发之后，shim 的**高水位**会从 0 抬到 1（每次创建**临时**占一个派发槽，
  `WicShim_RegisterForeignSource` 复用 `KIND_FRAME` 槽位）。**那是派发槽不是记账**：所以
  `创建释放N轮…` 那条把"高水位与基线逐字相等"改成**"同时最多 1 个在册"**（`<= baseline + 1`）+ 新增
  **"外来源登记数回基线（0→0）"**这条直接断言。**不是弱化**：前者对一个单调量本来就不可能成立（会得到恒红的假断言），
  后者是更强的直接判据。

### 4.23.3 AOT/真 PC 侧实证（`/tmp/m7cb-probe`，不入仓库；T2 会另行复跑）

同一探针、`MILBRIDGE_MILCORE_SO` 指向本工程当轮发布的桥（含本次接线）：

```
shim=/tmp/m7cb-probe/bin/Debug/net10.0/libwpfwic.so
GetPixelFormat(0x20000005) hr=0x00000000 format=6fddc324-4e03-4bfe-b185-3d77768dc910   ← Pbgra32 ✓
GetSize hr=0x00000000 = 8x8 ✓
Release(swdbb) hr=0x00000000
[ OK ] WIC proxy 对后缓冲句柄派发（GetPixelFormat / GetSize）
```

**⇒ 主控描述的那道墙（`E_INVALIDARG` → PC 抛 `ArgumentException`）已经消失。**
**顺带报出下一道墙**（同一跑，`WriteableBitmap` 那条链）：

```
System.EntryPointNotFoundException: Unable to find an entry point named 'IWICBitmap_Lock_Proxy'
                                   in shared library 'WindowsCodecs.dll'.
  at UnsafeNativeMethods.WICBitmap.Lock(...)
  at WriteableBitmap.TryLock(Duration)   WriteableBitmap.cs:256
  at WriteableBitmap.Lock()              :209
  at WriteableBitmap..ctor(...)          :130        ← 构造期就走到 Lock
```

即：`WriteableBitmap` 现在能过 `GetPixelFormat`，**卡在 shim 没有 `IWICBitmap_Lock_Proxy` 这个导出**上
（`nm -D` 数过：`libwpfwic.so` 里没有它）。这属于 **T2 的车道**（shim 侧再加一个 proxy + 让外来源支持 lock 语义），
本轮只把位置与栈交上去。

---

## 4.24 D1：`Win32ShimResolver` 编进 UIAutomation*（真应用**只要给 ListBox 赋 ItemsSource** 就会撞）

### 4.24.1 现象与根因

```
ItemCollection.SetCollectionView → CollectionView.OnCollectionChanged → ItemsControl.OnItemCollectionChanged2
→ Selector.OnItemsChanged → SelectionChanger.End → ListBox.OnSelectionChanged
→ AutomationPeer.ListenerExists → AutomationPeer..cctor → OSVersionHelper..cctor
→ [DllImport("PresentationNative_cor3.dll")] → **DllNotFoundException**
```
`Win32ShimResolver.cs` 原先只编进 WindowsBase / PresentationCore；符号在 shim 里是齐的
（`libwpfwin32.so` 有 9 条 `IsWindows10*OrGreater`，且 `PresentationNative_cor3.dll`
**早就在** resolver 的 `MappedLibraries:83`）⇒ **缺的只是 resolver 这一层**。

### 4.24.2 ⚠️ 动手前先验出来的陷阱（"照做法加个文件"会直接构建红）

`build/shims/Win32ShimResolver.cs:37-43` 是
`#if WINDOWS_BASE / #elif PRESENTATION_CORE / #else #error(…)`，
而 UIAutomationTypes 的 DefineConstants 是 `UIAUTOMATIONTYPES;WINDOWS_BASE_OR_PC`、
UIAutomationProvider 的是 `AUTOMATION;WINDOWS_BASE_OR_PC` ⇒ **两个常量都没有**。
⇒ 定案修法：加一个**用它们已有的常量**做键的分支
`#elif UIAUTOMATIONTYPES || AUTOMATION` → `namespace WpfLinux.Shims.UIAutomation`
（**不动 port-lib 的常量表**；`#if PRESENTATION_CORE` 门控的 MIL 桥/WIC 段在这里自然不编进来）。

### 4.24.3 落地与自伤（如实登记）

* 应用器：`src/WpfGfx.Linux.Native/tools/wire-uiautomation-resolver.py`（**无参 = 应用**，`--check` 只读）。
  它写 `build/shims/UIAutomationTypes.shims.txt` 与 `UIAutomationProvider.shims.txt`；
  `port-lib.py:568-586` 会读这些清单注入 `<Compile Include>` ⇒ **csproj 重生成后自动回来**。
* **自伤并当场修掉（教训）**：第一版应用器对 shims.txt 是**整文件覆写**，把
  `UIAutomationTypes.shims.txt` 里原有的 `Accessibility.Shim.cs` **删掉了** ⇒
  `UnsafeNativeMethodsCLR.cs(219,113): CS0122 "IAccessible" 不可访问`（该文件在 UIAutomationTypes 编译集里，
  上游 `IAccessible` 是 internal，必须带这份 shim）。
  ⇒ 改成**只增不删（merge）**：保留既有行、只补缺失行，`--check` 报"缺哪几行"。
  **清单文件是共享状态，工具不能重写它** —— 与"无参空操作"同属"工具悄悄破坏状态"那一类。
* 顺序（实测得到的正确次序）：`wire-uiautomation-resolver.py`（写清单）→ `port-lib.py UIAutomationTypes`
  （把清单注入 csproj）→ `patch-uiautomationtypes-reservedvalue.py`（D2 的块，**必须在 port-lib 之后**，
  否则被重生成抹掉）→ 构建。**波的第 1 步会重生成 csproj ⇒ 这三个应用器每次波都要重放。**

### 4.24.4 证据（行为断言，不是"文件里有没有 Include"）

`tests/.../ManagedLayer.Tests/UIAutomationLinuxTests.cs`（**先能红，再翻绿**）：

```
UIAutomationTypes 里声明 PresentationNative_cor3 DllImport 的成员：42 条
RunClassConstructor(MS.Internal.UIAutomationTypes.NativeMethodsSetLastError) ⇒ OK
RunClassConstructor(MS.Internal.UIAutomationTypes.Interop.OSVersionHelper)    ⇒ OK
调用 OSVersionHelper.IsWindows10RS5OrGreater() ⇒ False   …（11 条零参 bool P/Invoke 全部返回）
```
定位方式是**扫描程序集里带该 DllImport 的类型**（不按记忆写死类型名）；`UIAutomationTypes.dll`
构建物里也确认含 `Win32ShimResolver`；`UIAutomationTypes` / `UIAutomationProvider` 两个工程 **0 错 0 警**。

---

## 4.25 D2：`UiaGetReserved*` 的 `IUnknown` out 参数在 Linux 不可封送 ⇒ 短路成进程内哨兵

* 落点：`build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs`（生成物）+ csproj 接线（D2 块，109-113 行）。
  应用器：`src/WpfGfx.Linux.Native/tools/patch-uiautomationtypes-reservedvalue.py`（**无参 = 应用**，`--check` 只读）。
* `UiaGetReservedNotSupportedValue()` / `UiaGetReservedMixedAttributeValue()` 改成返回
  **本进程内唯一**的哨兵对象；两处 raw P/Invoke **逐字注释保留**（便于核对上游原文）。
* **⚠️ 措辞（照实写）：这是降级，不是对齐。** Windows 上这俩是 UIA 核心的保留 **COM** 对象，
  客户端按引用相等判断"不支持/混合值"；Linux 上没有 UIA 核心、也没有 COM 编组
  ⇒ 本进程内的引用相等自洽，**跨进程/跨 COM 的身份语义不存在**；若将来真有外部 UIA 客户端连进来，
  这两个值必须重新实现，而不是沿用哨兵。
* 证据（同一个测试文件，两条都跑真实调用）：
```
UiaGetReservedNotSupportedValue()  ⇒ System.Object
UiaGetReservedMixedAttributeValue() ⇒ System.Object
```

---

## 4.26 WIC v2：把后缓冲**像素借给 shim**（`WriteableBitmap` 的最后一格）

* 改动点：`src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs` 的 `MILSwDoubleBufferedBitmapCreate`
  ⇒ `RegisterForeignSource(backBuffer, ref guid, w, h, isOpaque, pixels, rowBytes)`，
  `pixels = back.GetPixels()`、`rowBytes = (uint)back.RowBytes`（原先 `NULL`/`0`）。
  桥侧包装 `MilExternalHandleBridge.RegisterForeignSource(..., IntPtr pixels = default, uint rowBytes = 0)`
  也补了这两个参数（默认值仍是 NULL ⇒ 旧行为不变）。
* **为什么必须借、不能拷（语义不是性能）**：`WriteableBitmap` 的契约是"Lock 拿到的指针就是你写进去、
  渲染看得见的那块内存" ⇒ 拷一份给上层 = **写穿透失效**（功能坏）。
* **借用的代价写进代码注释**（下一个人改这里必须知道）：`pixels` 指向 `state.Back`，
  **注销之前必须一直有效**；别在别处 Realloc/重建这块位图而不重新登记。
* **"注销先于释放"仍然成立（代码位置）**：`MilDoubleBufferedState.Dispose()`
  —— `MilNative.Offscreen.cs:150` `UnregisterForeignSource(BackBufferHandle)`
  → `:164` `MilPixelBufferTable.Unregister(BackBufferHandle, force: true)`
  → `:167-Front?.Dispose()`（`Back` 紧随）⇒ **先是 shim 注销，再释放位图**。
* 编译 0 错 0 警；`ManagedLayer.Tests`（含 WIC 外来源那条：`登记次数 40→41 / hr=0 / 活句柄 0→0`）全绿。

---

## 4.27 `BitmapSource.DUCECompatiblePtr` → `E_HANDLE`：因果链（追到 file:line）+ 复现受阻说明

### 4.27.1 因果链（读代码得出，每一跳都有 `file:line`）

```
BitmapSource.AddRefOnChannelCore                       BitmapSource.cs:888
  → BitmapSource.UpdateResource(channel, skipCheck)    :739
  → BitmapSource.UpdateBitmapSourceResource            :939   ← 这里读 DUCECompatiblePtr
  → BitmapSource.get_DUCECompatiblePtr()               :872   ← HRESULT.Check 抛出的那一行
      = UnsafeNativeMethods.MilCoreApi.**CreateCWICWrapperBitmap(pIWICSource, out pCWICWrapperBitmap)**
        （同一 getter 内，紧跟 WIC 转换器那段之后）
  → 本工程实现：MilNative.Offscreen.cs:649  MilResource_CreateCWICWrapperBitmap
      `SKBitmap bitmap = MilPixelBufferTable.Resolve(pIWICBitmapSource);`
      `if (bitmap == null) return HResult.E_HANDLE;`      :654   ← **E_HANDLE 的确切出处**
```

⇒ **分支是"句柄不在 `MilPixelBufferTable` 里"**（主控列的三种可能里的第 ① 种，但要说准：
不是"谁都没登记"，而是**登记在另一张表**——`BitmapSource.WicSourceHandle` 若是 WIC shim
（`libwpfwic.so`）下发的句柄，它就在 **shim 的表**里，而我们这个导出**只查 MIL 的像素缓冲表**，
两张表互不认识 ⇒ 一律 E_HANDLE）。上游 Windows 上这一步不会失败，因为那里的 `pIWICSource`
是**真 COM 对象**，包一层 wrapper 不需要"先在 MIL 表里找到它"。

### 4.27.2 ⚠️ 复现受阻：**本轮的三个档位都更早死在 D3（不是本条）**

实测（被测产物：自建桥 `/tmp/mb-diag/…/wpfgfx_cor3.so`，sha `cf0d224c4fc9d9cc`；
**不是部署件**，部署件是主控的 `642db888…`）：

| 档位 | 结果 | blocker |
|---|---|---|
| `--tier default` | FAIL exit=134 | `lineservices:LoCreateContext` |
| `--tier degraded` | FAIL exit=134 | 同上 |
| `--tier minimal` | FAIL exit=134 | 同上 |

三者都停在 `TextFormatterContext.Init` → `LoCreateContext`（**D3**，已派文本车道）
⇒ 应用**走不到** `AddRefOnChannelCore`，所以 `E_HANDLE` 我这边**没能复现**。
**按纪律：不拿"读代码推出来的链"当"已复现的分支"。** 所以本轮做的是：
* 把因果链与出处逐跳钉死（上面 4.27.1）；
* 在**第一次**出现时就让它自己说清归属（下面的诊断）——等 D3 修好后一条日志即可确证，无需再猜。

### 4.27.3 已落地：句柄归属诊断（免采样，失败语义不变）

`src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs`（`MilResource_CreateCWICWrapperBitmap`）：
查不到句柄时**仍然返回 `E_HANDLE`**（一字未改），但**首次**（`Interlocked` 去重、免采样）记一条 NOTE：

```
MilResource_CreateCWICWrapperBitmap: 句柄 0x… 不在 MilPixelBufferTable 里 ⇒ E_HANDLE。
设备对象=<Kind|无>；WIC 所有者认领=<是|否>；WIC 桥接=<已接上|未接上>
```
配套只读探针：`MilExternalHandleBridge.OwnsHandleProbe(IntPtr)`（`MilNative.Misc.cs`，**不记 AddRef/Release**，只问所有者"这是你的句柄吗"）。
编译 0 错 0 警。⇒ D3 一修好，这条日志立刻指认分支（①"WIC 表里的句柄" 还是 ② 别的）。

### 4.27.4 建议的修法（**待主控裁**：是否现在就做）

在 `MilResource_CreateCWICWrapperBitmap` 里，对**WIC 所有者认领**的句柄增加一条物化路径：
用 shim 的 `IWICBitmapSource_GetSize_Proxy` / `GetPixelFormat_Proxy` / `CopyPixels_Proxy`
把像素拉进一张**我们持有**的 `SKBitmap`，登记成 `MilPixelBufferTable` 借用句柄 +
`CwicWrapperBitmap` 设备对象，再返回 wrapper 句柄；仍保留"不认识 ⇒ E_HANDLE"的 fail-safe。
* 为什么是**拷贝**而不是借用：`BitmapSource` 在 MIL 侧是**只读**语义（渲染只读它），
  与 `WriteableBitmap` 的后缓冲（读写、必须写穿透）不同 —— 那一处 v2 借用照旧，不动。
* 可在**不依赖 demo** 的前提下验证：`ManagedLayer.Tests` 里直接用 shim 造一个 WIC 位图句柄
  （`WICCreateBitmapFromMemory`/工厂路径）→ 调该导出 → 断言 `S_OK` + wrapper 可解析
  （修前必 `E_HANDLE`）。**这个单元级翻转我可以当场做并给读数**；
  而**应用级**（出帧、`skia 指令 > 0`、`未画种类 0`）必须等 D3 修好，我这边无法自证。

---

## 4.28 #24 落地：WIC 句柄 → CWIC wrapper 的**物化**路径（红→绿对照）

### 4.28.1 改动点（`file:line`）

| 位置 | 内容 |
|---|---|
| `src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs` `MilResource_CreateCWICWrapperBitmap` | 保留原路径（MIL 像素缓冲句柄 ⇒ 借用包装）；**新增**"WIC 所有者认领的句柄 ⇒ 物化"分支；物化失败/不认识仍 **`E_HANDLE`**（fail-safe 未放松） |
| 同文件 `TryMaterializeWicSource`（新增） | `GetSize` → `GetPixelFormat` → 按格式建 `SKBitmap` → `CopyPixels`；**v1 只覆盖 Pbgra32/Bgra32/Bgr32**（与 `WriteableBitmap` 同格式集合），**其余格式诚实失败并给出原因**（不猜、不近似、不编数据） |
| `src/WpfGfx.Linux/Interop/MilNative.Misc.cs`（`MilExternalHandleBridge`） | 新增三个**只读** proxy 入口（`IWICBitmapSource_GetSize/GetPixelFormat/CopyPixels_Proxy`）+ 懒解析 + `BitmapSourceReadAvailable` / `TryGetWicSize` / `TryGetWicPixelFormat` / `TryCopyWicPixels` 四个 fail-safe 包装（取不到就整条物化路径不可用） |
| `src/WpfGfx.Linux/Interop/MilHandleTables.cs` | `MilCwicWrapperTable`（物化条目的**在册登记**：`InFlight` / `TotalRegistrations` / `TotalReleases`）+ `MilCwicWrapper` 负载类型（wrapper 设备对象**拥有**物化位图 ⇒ 引用计数归零时回收） |

**编译 0 错 0 警。**

### 4.28.2 为什么这里"拷"、v2 那里"借"（**有意相反**，注释里写明）

`BitmapSource` 在 MIL 侧是**只读**语义（渲染只读它）⇒ 物化一份不改变任何可观察行为；
而 `WriteableBitmap` 的后缓冲是**读写**、`Lock` 拿到的指针必须就是渲染读的那块内存
⇒ 那一处必须借用（`MilNative.Offscreen.cs` 的 v2 注释）。**两处相反是有意的，不是疏漏。**

### 4.28.3 单元级红→绿（同一用例、同一产物，只差这一处改动）

`tests/.../ManagedLayer.Tests/CwicWrapperBitmapTests.cs`（用 shim 工厂造**真 WIC 位图**再调该导出）：

```
【修前·红】
WIC 位图句柄=0x2（在 shim 的表里）
MilPixelBufferTable 里有它吗=False        ← 两张表互不认识（因果链的实证）
WIC 所有者认领它吗=True
MilResource_CreateCWICWrapperBitmap ⇒ hr=0x80070006 (E_HANDLE)   ← 上层于是抛 COMException

【修后·绿】
MilResource_CreateCWICWrapperBitmap ⇒ hr=0x00000000 wrapper=0x20000002
wrapper 设备对象种类=CwicWrapperBitmap
物化位图 4x3 ct=Bgra8888                  ← 尺寸与像素**逐字节**与 WIC 源一致（断言）
在册计数 1 → 0（回基线）                   ← 释放 wrapper ⇒ 物化位图与登记条目一起回收
```

### 4.28.4 生命周期可观测（主控第 2 条要求）

* 在册读数：`MilCwicWrapperTable.InFlight`（当前）/ `TotalRegistrations` / `TotalReleases`
  ⇒ 用例断言"登记 1 → 释放 1 → 回 0"，并且`MilDeviceObjectTable` / `MilPixelBufferTable` **也回基线**。
* 回收路径：wrapper 设备对象引用计数归零 → `MilDeviceObjectTable.DisposePayload`
  → `MilCwicWrapper.Dispose` → `MilCwicWrapperTable.Release`（摘 `MilPixelBufferTable` 借用登记 + 释放 `SKBitmap`）。
  **物化最怕的是泄漏，而泄漏不会以崩溃的形式暴露** —— 所以这条读数必须存在。

### 4.28.5 应用级：**待主控重发布 AOT 桥**（不用自建产物下结论）

主控给的复现命令（部署件桥 `642db888…`，`libwpfwic.so`=`74d9dbba…`/12 个 `Wic*` 导出）我这边
在**本轮改动之前**跑到的第一现场与主控一致（`BitmapSource.cs:872` → `COMException 0x80070006`）。
本轮的 `Interop/` 改动**要等桥重发布**才能进应用级；届时按主控的判据读数：
**先确认非空帧**，再看 `skia 指令 > 0` + `未画种类 0`（空帧下的 `未画种类 0` 是**空真**）。
另外记一条 T3 runner 的**分类盲区**：E_HANDLE 这种阻塞它会归成 `blocker=none` —— **不是"没有阻塞"**，
要看日志原文。

---

## 4.29 下一道墙：`MilResource_SendCommandBitmapSource` 从 `E_NOTIMPL` **接进既有 0x0c 命令路径**

### 4.29.1 上游语义（逐跳，`file:line`）

```
DUCE.Channel.SendCommandBitmapSource(imageHandle, pBitmapSource)   Common/Graphics/exports.cs:763-772
  → MilResource_SendCommandBitmapSource(imageHandle, pBitmapSource, _hChannel)   exports.cs:186-187
  → 原生 apifunc.cpp:711-760：CHECKPTRARG(pIBitmapSource) / CHECKPTRARG(pChannel) **都是 E_INVALIDARG**
      → 填 MILCMD_BITMAP_SOURCE{Type,Handle,pIBitmapSource} 发出
接收侧：CMilSlaveBitmap::ProcessSource（本工程 Commands/MilBitmapSource.cs:151）
      → 拿不到可用位图时 **E_HANDLE**（IFCNULL 语义，:155-165 的注释追到了 instrumentationapi.h:915）
```
⇒ **两侧错误码不同**（发送侧 E_INVALIDARG / 接收侧 E_HANDLE）—— `MilBitmapSource.cs:161` 那句注释要的正是这个区分，本实现照它办。

### 4.29.2 Linux 侧怎么传（不是重新设计，是接线）

上游那一列是 `IWICBitmapSource*`，靠"发送前 AddRef、接收方接手"在同进程内传引用。
本工程的命令流是**纯字节流**（解码器吃 `ReadOnlySpan<byte>`，可跨进程/可重放），
所以 `MilCommandLayout.cs` 早已把 0x0c 的第 3 列重定义为**位图令牌**（宽度不变，16 字节），
接收侧 `ProcessSource(res, token)` 从 `MilBitmapSourceTable` 取走。本轮的改动就是**发送侧**：

1. 校验：`pBitmapSource == 0` 或通道解析不到 ⇒ **`E_INVALIDARG`**（上游 CHECKPTRARG）；
2. 解析句柄背后的位图（与 #24 同一集合）：`MilPixelBufferTable` → CWIC wrapper 设备对象 → WIC 句柄（现物化）；
3. **拷一份**（`SKBitmap.Copy()`）再登记领取令牌 —— 因为 `MilBitmapSourceTable.Register` 的契约是
   **所有权转移**（接收侧最终 Dispose），而这三类来源的位图都是**别处拥有**的，直接交出去会双重释放；
   `BitmapSource` 在 MIL 侧是**只读**语义 ⇒ 拷贝不改变可观察行为（与 #24 物化、v2 借用 同一套取舍：**只读⇒拷贝，读写⇒借用**）；
4. 组 16 字节 `MILCMD_BITMAP_SOURCE{Type,Handle,BitmapToken}` 发进当前批次；
5. **发送失败 ⇒ `MilBitmapSourceTable.Discard(token)` 撤回令牌**（否则那张登记表只增不减）；
6. 句柄解析不出位图 ⇒ **`E_HANDLE`** + 台账点名（fail-safe，不一律 `S_OK`）。

### 4.29.3 深度表同步（主控第 ① 条）

`MilNative.Exports.cs`：`MilResource_SendCommandBitmapSource` **`NotImpl` → `Real`**，
并把 :28-33 那段"M1 就返回 E_NOTIMPL 的两个既有导出"的注释改为"只剩媒体导出"。

**⚠️ 唯一一处越界改动（如实登记）**：`Commands.Tests` 里有 **3 处**硬编码了旧状态，
不改就会红（而你要的是 562 不退步）——都是这次深度改动的**机械后果**：
| 文件:用例 | 原断言 | 改后 |
|---|---|---|
| `MilExportTests`（导出深度计数） | `real==60` / `notImpl==28` | `real==61` / `notImpl==27`（注释写明原因） |
| `MilExportTests`（未实现清单） | `Assert.Contains("MilResource_SendCommandBitmapSource", notImpl)` | `Assert.DoesNotContain(...)` |
| `MilNativeTests.M1未实现的两个导出返回ENOTIMPL` | 两个导出都 E_NOTIMPL | 媒体仍 `E_NOTIMPL`；位图源改断言 **`E_INVALIDARG`（参数语义对齐上游，比原来更强）** |

如果你不希望我碰这三个文件，我可以回退深度表并把该项标成"已有真实现、深度待升" —— 但那会让身份表与实现不符，与你第 ① 条冲突，所以我选择了改它们并在这里点名。

### 4.29.4 证据

* 编译 **0 错 0 警**；`Commands.Tests` **562 / 562**；`ManagedLayer.Tests` **52 / 52**；`Windowing.Tests` **44 / 44**。
* 应用级（full 模式不再 `NotImplementedException`、`pending` 排空、非空帧 + `skia 指令 > 0` + `未画种类 0`）
  **由主控重发布桥后复验** —— 本组不拿自建产物下结论。

---

## 4.30 CJK 豆腐块（②A）：本轮查到的证据 + 两条**自我纠正**；②B 待诊断

### 4.30.1 已在真应用上确认的事实（`run-wpftextdemo.sh --tier default`）

```
[mil 12] 字形渲染器已挂上：目录=/usr/share/fonts 请求字族=DejaVu Sans（来源：SPI(SPI_GETNONCLIENTMETRICS)）
         实际面=DejaVu Sans **候选文件=299**
```
* **A 步（递归枚举）在真应用上生效**：`候选文件=299`（修前是 0）。
* **B 步（族名与 WPF 同源）生效**：请求族来自 SPI，不再是硬编码。
* **首个被画的 glyph run 的 id 是健康的拉丁 id**：`共 11 个，0(.notdef)=0，最大 id=91，前 8 个=[58 83 73 55 72 91 87 39]`
  ⇒ 拉丁这条路**画的是真字形**，不是 .notdef。
* ⇒ 由此**只能**推出"渲染器拿到的面是 `DejaVu Sans`（**纯拉丁、无 CJK**）"；
  **CJK 的豆腐到底是"PC 侧 shaping 给了 .notdef"还是"id 是真的但我们用错了面"，本轮没有量到**（下条）。

### 4.30.2 两条自我纠正（都是"观测手段"的问题，按纪律记下来）

1. **我加过一版 glyph-id 探针（挂 `TextRenderer.MilFontResolver`）并随后撤回**。
   撤回理由我先前写成"装探针后 `未画种类 0→1`" —— **这条是错的**：撤回之后重跑，读数**没变**
   （仍是 `未画种类 1`）⇒ **不是探针造成的**。纠正后的事实是：探针**只**报出了首个 run（拉丁），
   看不到 CJK run 的 id，所以它对 CJK 归因**没有贡献**；撤回它仍然是对的（它替换了一个渲染器解析器，
   属于"会扰动被测对象"的仪器），但**理由要写对**。
2. **我的自建桥读数与主控的部署件读数不一致**，因此**不作为结论**：
   | | 帧尺寸 | skia 指令 | 未画种类 |
   |---|---|---|---|
   | 主控（部署件 `9eb4c88c…`） | 938×646 | **145** | **0** |
   | 我（自建 `/tmp/mb-diag`，sha `34d6bbff…`） | 938×938 | 180 | **1** |
   ⇒ 这正是"**自建产物 ≠ 部署件**"那条教训的又一次实例：**差异要先用部署件复测才能定性**，
   我不拿它说"哪里有回归"。

### 4.30.3 归因需要什么（下一步，等主控排）

要判"PC 给了 .notdef" vs "我们用错了面"，需要**逐 run**读 glyph id，而**不能**替换渲染器的解析器。
可用手段（按侵入性排序）：
1. **只读计数**：在渲染路径里加 counters（`Rendering/` 是 **T2b** 的车道）——例如
   "本帧字形 run 数 / 其中 id 全 0 的 run 数 / id 最大值分布"；
2. **既有资源台账**：`WPF_LINUX_MIL_LOG` 的通道快照里已有 `[MilGlyphRun×18]` 这类计数，
   若能把它扩成"逐 run 的 id 直方图"（同样属渲染/资源面）；
3. 若确认是 **PC 侧 shaping 给 .notdef**（我预计是这条：`DejaVu Sans` 无 CJK，而
   **复合字体回退链被补丁 J 短路**），则修法在 **PC/文本车道**（把 `GetCompositeFontFamilyAtIndex`
   那条回退链接回来或等价物），**不是**改渲染数值。

我这一侧可做的（**等主控批准再做**，避免"改了但验不了"）：`FontSet`/`EnsureGlyphRenderer` 增加
**按覆盖选面**的兜底（当前面缺该 run 的字形时换一个覆盖得上的面），但**必须先有 4.30.3 的读数**——
因为 glyph id 是**逐面**的，"换面"只在 id 与目标面同源时才对，盲目换面会把拉丁也弄坏。

### 4.30.4 ②B（首段文字与边框重叠）

**未动**（按"先诊断归因再改"）。诊断需要把三件事分开量，证据形态不同：
① 文字算宽了（advance 量化的差异）；② 框算窄了（背景尺寸）；③ 行高不同（`TextHeight ≠ Height`）。
可用的**只读**手段：从最终帧上量"文字像素的包围盒"与"边框像素的包围盒"（`xwd` → PNG → 逐色/逐行统计，
与既有 `run-wpftextdemo.sh` 的判据同一套口径），先确认两者是"越界"还是"框本身就画在那儿"。

---

## 4.31 ②B 的只读测量：**症状要重新描述** —— 不是"首段压出框"，是"多行段落把行摞在一起"

### 4.31.1 读数（**部署件**，`run-wpftextdemo.sh --tier default`）

```
WPTD_ARTIFACTS bridge_sha=9eb4c88c3258307d bridge_bytes=4768240 pc_sha=0fad3c19adbc9a19 pf_sha=f19acf54c2fd0db0 shim_sha=4c023937421db45f
WPTD_TIER=default rep=1 RESULT=FAIL exit=143 notdrawn=0 drawn=180 colors=2659 frames_good=8 frames_total=8 frames_blank=0 capture=ok blocker=none
截图（runner burst 抓到的非空帧）：/tmp/wptd-B/burst-default-r1-1.png 938×938 77,973 B sha256 dc197aa6a37e685e…
```
* **`未画种类 0`** ⇒ 上一轮我在**自建件**上读到的 `未画种类 1` **不是部署行为**（又一次"自建 ≠ 部署"；这次差异方向还相反，所以更要写清产物）。
* burst 抓帧有效（77,973 B / `colors=2659`），没有踩到 T3 runner 的"白帧"竞态。

### 4.31.2 读图得到的新描述（**与主控看到的那一条不同**）

图上：
* **单行文本正常**：标题 `WpfTextDemo`、`Left · 左`、`Item 01 / Item 01`、`detail: bound via ItemsSource (7 ms)` 这类**单行**都清楚；
* **多行（折行）段落整体摞在一起**：第①段（折行那段）、`② TextTrimming … CharacterEllipsis`、
  `④ …Image` 的说明、以及 ListBox 那些 `detail: …mixed text…` —— **行与行互相压印**，读起来像"两三行画在同一条基线上"。
* ⇒ 主控看到的"**首段文字与边框重叠**"是**同一个现象的一个切面**（段落被折成多行 → 行全摞在框的上沿 → 视觉上像"压出框外"）。

### 4.31.3 由此能排除/指向什么（**仍是"指向"，不是结论**）

三种候选里，图的形态**更支持"行推进（line advance / 行高）≈ 0"**，而不是另两种：
| 候选 | 与图是否相符 | 理由 |
|---|---|---|
| ① 文字算宽了（advance 量化） | ✗ 不相符 | 那样会**同一行内**字距/换行点错，而图上**行内**是清楚的，错的是**行与行之间** |
| ② 框算窄了（背景尺寸） | ✗ 不相符 | 框的圆角矩形本身画得规整；且**没有框的**地方（ListBox 的 `detail:` 行）同样摞印 |
| ③ 行高/行推进不同（`TextHeight ≠ Height`、行高公式） | ✓ 相符 | 单行正常、多行全摞 —— 正是"每一行的基线都被算到同一个 y"的形态 |

**代码侧的一条旁证**（**不是**因果结论）：`MilCmdBitmapSource`… 无关；
本工程 `Commands/MilCommandDispatcher.cs` 解码 `MilCmdGlyphRunCreate` 时**没有解开**
`AdvanceWidths`/`GlyphOffsets`（注释写明"M1 留空"）。但那条影响的是**行内**排布，而图上**行内是好的**
⇒ **行推进不来自这一处**，更可能来自 PC 侧的行高/度量反馈（`FullTextLine`/`SimpleTextLine` 那条链，
文本车道）。**要把它变成结论，需要下面那条测量。**

### 4.31.4 下一步的**判别测量**（只读；我没在没量到的情况下写数字）

在同一个框内，逐行求"文字像素带"的 y 区间（同一 x 范围内、文字色像素的行投影），看相邻两带是否**重叠**：
* 相邻带**重叠/间距 ≈ 0** ⇒ 行推进缺失（③ 成立，修法在**文本度量**那条链，PC/文本车道）；
* 相邻带间距 **≠** 该字号的行高（例如与真机 1/300 英寸量化对不上）⇒ 落到**已登记的量化差异**上，
  按主控的话那是**登记取舍不是缺陷**，由主控定性。

⚠️ 我这一轮试图用 `convert -crop` + 亮度投影量它，**读数太粗**（框边与标题也计入亮像素），
**所以我没有给数字** —— 按"观测手段不许自己说谎"的纪律，宁可空着也不报一个不可信的区间。

---

## 4.32 (乙) 的只读读数：**仪器已就位，但第一个读数就把问题问错了地方**

### 4.32.1 仪器（按主控指定形态）

新增 `src/WpfGfx.Linux/Text/GlyphFaceCensus.cs`：**缺省关**（`WPF_LINUX_GLYPH_CENSUS=1`）、
**独立成类**、**不碰 `RenderDiagnostics`**（runner 判据 `未画种类 0` 那本账一行都不写）、
**不替换/不包装渲染器解析器**（只在绘制路径**旁**读 `_fonts.TryResolve` 的结果与已解码的 `GlyphIndices`）。
挂点三处（都只读）：`TextRenderer.DrawResource`（记"这个 run 会被哪份面画"）、
`FontSet.FromDirectory`（记"面 → 文件/faceIndex"，顺带探"同一文件里是否还有我们没加载的 face"）、
`MilPresentation.RenderChannel`（每帧一次汇总，只打 stderr）。

### 4.32.2 第一个读数（自建桥 `9bdd36e1…`；**仅诊断，不当部署结论**）

```
[glyph-census] 帧 938x938：渲染器实际用了 **299** 份面；共 **0** 个 run / 0 个字形
[glyph-census]   面 0x5747c85bc650 family=Chilanka file=Chilanka-Regular.otf faceIndex=0 runs=0 …
[GLYPH_CENSUS] run#39 handle=0x00000130 n=36 id0=17 max=91 pid=0x20000002 first16=71,72,87,68,76,79,29,3,0,0,0,0,3,80,76,91
```
（第二行是 **T2b 的普查**输出 —— 因为树是共享的，我这份自建桥里也含它那份仪器。）

**两条事实**：
1. `FontSet` 在真应用里加载了 **299 份面**（递归扫描生效）；我的 census 能记到"面 → 文件/faceIndex"。
2. **我挂在 `TextRenderer.DrawResource` 上的 `NoteRun` 一次都没触发（0 runs）**，
   而同一进程里 T2b 的普查**数到了 run** ⇒ **真应用的字形绘制没有走 `TextRenderer.DrawResource` 这条 T6/Text 钩子**
   （那正是"渲染器实际用哪份面"该被问到的地方）。
   ⇒ **"渲染器用了几个面 / 每个 run 用哪份"这个问题，必须画在真正执行绘制的那条路径上问**；
   那条路径在 `Rendering/**`（**T2b 车道**），不在我这侧。

**因此本轮我给出的是**：仪器（缺省关、可复跑）+ 一条**否证**（"绘制不经过我这里"），
**而不是**"渲染器用了 1 份面"这种我会猜错的结论 —— 上一轮我已经因为"拿会扰动的仪器读数下结论"
纠正过一次，这次不重犯。

### 4.32.2b 同一次运行里 T2b 普查的**逐帧**读数（我这份自建桥里含它的仪器 ⇒ 一次跑拿到两边的账）

```
frame=1 runs(绘制次数)=0   不同句柄=0  面标识: pid==0的run=0   不同面数=0
frame=2 runs(绘制次数)=48  不同句柄=48 glyphs=1270 id0=332 maxId=3540 非拉丁(id>=0x1000)=0
        桶[0]=332 [1,FF]=927 [100,FFF]=11 [1000,3FFF]=0 [>=4000]=0
        面标识: pid==0的run=0 **不同面数=2**（有信息：确有多个不同面）
run#0 handle=0x18  n=11 id0=0  max=91  pid=0x20000001 first16=58,83,73,55,72,91,87,39,72,80,82
run#1 handle=0x1c  n=52 id0=34 max=121 pid=0x20000002 first16=0,0,3,18,3,0,0,0,3,18,3,0,0,0,0,3
```
**这三条把 (甲) 钉得更死，也把 (乙) 的范围划出来了**：
* `run#1`（显然是含 CJK 的那条：52 个字形里 **34 个是 0**，其余落在 **拉丁区** max=121）
  ⇒ PC 用**非 CJK 的面**给 CJK 整形，直接吐 `.notdef`；`id≥0x1000` 全程 **0 个**
  ⇒ **"真 CJK id 被错面光栅"在本次读数里根本不成立**（没有 CJK 区的 id 出现过）。
* `不同面数=2`（`pid=0x20000001` / `0x20000002`）⇒ PC 确实用了两个面；**而渲染器那半边的读数我这次没拿到**（见 4.32.2 的否证）。
* 同一次跑里 `frame=1` 两边都是 0（首帧没有任何绘制）—— 这也说明"**空帧下的 0 是空真**"那条判据要一直带着。

**给出 (乙) 的读数的最短路径**（跨车道，请主控协调）：
T2b 的普查已经**在真正执行绘制的那条路径上**数 run（`runs(绘制次数)=48 不同句柄=48`），
只需在那里加一句 `GlyphFaceCensus.NoteRun(face, ids)`（同一个静态表），
"面 → 文件/faceIndex"由我这边 `FontSet` 加载时已记好 ⇒ 两边一拼就是"哪个 run 用了哪份面"。
**接口我已留好、只读、缺省关、不改行为**，T2b 可直接调。

### 4.32.3 与 (甲) 并排看

* (甲)（T2b 普查，部署件）：48 run / 1276 字形，`id==0` **325 个（25.5%）**，maxId=3540，**id≥0x1000 = 0**。
* 我这次自建件上抓到的一条 run：`n=36, id0=17, max=91, pid=0x20000002`
  —— **同一个 pid 内 17/36 是 .notdef**，与 (甲) 的"0 只可能来自 shaping"一致。
* ⇒ **PC 侧 shaping 吐 .notdef 与"渲染器用了哪份面"是两条独立缺陷**（主控的判断我同意）：
  前者修好才有**正确的 id**，后者修好这些 id 才会被**正确的面**光栅。
* (乙) 的读数位置建议：**在 T2b 的绘制路径上加同一份 census 的 `NoteRun`**（它已经在那里数 run），
  把"面 → 文件/faceIndex"用我这边的 `GlyphFaceCensus.NoteFaceSource` 对上去（两处共用一个静态表即可）。
  **我可以把 `GlyphFaceCensus` 的接口留给它直接用**（只读、缺省关、不改行为）。

---

## 4.33 census 的两处修正（主控点名 + T2b 只读读代码抓到的）

### 4.33.1 缺陷：**探针的可用性被它要测的那件事门控了**

T2b 只读读代码抓到（我认，这条比读数本身值钱）：
```
上一版：census 里自己再解析一次 → _fonts.TryResolve(font, out face)   TextRenderer.cs:92
真正绘制：Draw(...) → TryGetFont(request, out SKFont font)             TextRenderer.cs:73
```
两条**不是同一条路**，而且 `TryResolve` **失败时 census 静默不记** ——
**探针恰好在它最该报的场景（面解析出问题）下变成哑巴**。
⇒ 这解释了"48（T2b）vs 0（我）"里的**一半**（另一半是"我的挂点 `DrawResource` 根本没被调到"，见 §4.32.2 的否证）。

**修法（已落地）**：census 移到**真正绘制那条路**上、`TryGetFont` **成功之后**记；
**失败也记一条可读事实**（`GlyphFaceCensus.NoteUnresolved(request)`，汇总里报"解析不到面的 run = N"）。
`DrawResource` 里那版会静默的探针**删除**（注释写明为什么不能在那里解析第二次）。

### 4.33.2 "两条解析路为什么不同 / `TryResolve` 会不会在某个输入下失败而 `TryGetFont` 成功"

**判断（读代码 + 现在只剩一条路）**：
* `TryGetFont(request, …)`（`TextRenderer.cs:117-131`）= `_fonts.TryResolve(request.Font, out typeface)` **＋** 一个
  `(typeface.Handle, request.FontSize)` 的 `SKFont` 缓存。
* ⇒ **底层解析只有一处**（`FontSet.TryResolve`）；`TryGetFont` 只是多了一层缓存。
  因此"`TryResolve` 失败而 `TryGetFont` 成功"**在构造上不可能**（同一个查询、同一个输入）。
* **唯一的不对称是我上一版引入的**（census 自己再查一次、且失败时静默）—— 现在已删除，
  census 与绘制**共用同一次解析的结果**（`font.Typeface`）⇒ 结构上不可能再分叉。
* ⚠️ 若将来有人再在别处加"第二次解析"，请把它当成同一类缺陷（**探针不许自建解析路**）。

### 4.33.3 开关改名（避免与 T2b 撞名）

| | 旧名（**已不再被读取**） | 新名 |
|---|---|---|
| 我（`Text/GlyphFaceCensus.cs`） | `WPF_LINUX_GLYPH_CENSUS` | **`WPF_LINUX_GLYPH_FACE_CENSUS`** |
| T2b（`Rendering/`） | `WPF_LINUX_GLYPH_CENSUS`（保持不动） | 不变 |

**为什么**：两个仪器共用同一个 env ⇒ 会**天然同时开**，而 T2b 的闸门 B 要求"关/开输出**逐字相同**"，
多一份输出就破坏那条语义。旧名写在新名旁边（下一个人按旧名找会找不到）。

### 4.33.4 `Text/` 的链接约定（主控转 T2 的发现，我认）

`build/DirectWrite.Linux/Tests` 的 csproj **显式链入** 4 个 M1 源文件
（`TextFontDescription.cs / GlyphRunRequest.cs / GlyphRunLayout.cs / FontSet.cs`），
我在 `FontSet.cs` 里引用 `GlyphFaceCensus` 之后**T2 的测试工程持久编不过**（主工程通配所以看不出来）。
T2 已在自己 csproj 里补第 5 个链接（**只动它自己的文件**），现 **123/123**。
**约定（我遵守）**：以后凡在 `src/WpfGfx.Linux/Text/` 下加"会被那 4 个链接文件引用"的类型，
或改动那 4 个文件的引用面，**先通知主控转 T2**。
**本轮的既有事实（补登记）**：`src/WpfGfx.Linux/Text/GlyphFaceCensus.cs` 是新增文件，**T2 已加入链接**。
另外我那次"先改 `FontSet.cs` 引用、后创建 `GlyphFaceCensus.cs`"确实开过"别人构建必红"的窗口 ⇒
**纪律：新类型先落文件、再加引用**（已记住）。

### 4.33.5 复跑

`ManagedLayer.Tests` **52 / 52**、`Commands.Tests` **562 / 562**（两处修正之后）。

---

## 4.34 (乙) 的判定性检查：**仍然是 0 ⇒ 走 T2b 那一行**（部署件）

### 4.34.1 读数（**部署件** `wpfgfx_cor3.so` sha `568181a7286d3bf6…` / 4,847,104 B；staged 目录里 app-local 同名件 sha 一致）

```
[glyph-census] 帧 938x938：渲染器实际用了 **300** 份面；共 **0** 个 run / 0 个字形，其中 id==0 0 个；
               **解析不到面的 run = 0**（最近一次请求的族=<无>）
[glyph-census]   面 0x… family=Noto Sans CJK JP file=NotoSansCJK-Black.ttc faceIndex=0 runs=0 …
```
* census 这次落在 **`TextRenderer.Draw` 内、`TryGetFont` 之后**（用 `font.Typeface`），并带 `NoteUnresolved`。
* 结果：**`TextRenderer.Draw` 也不是真路径**（`DrawResource` 试过、`Draw` 现在也试过，都是 0），
  而 T2b 在同一次跑里数到 48 次绘制。
* **`解析不到面的 run = 0`** ⇒ 顺带**排除了**"解析失败导致静默"这个解释（那是我上一版的缺陷形态，现已排除）。
⇒ **按主控给的分支：走 T2b 的那一行**（它已确认同 csproj、无跨车道依赖、接口只读缺省关）。
**我这一侧的接口就绪**：`GlyphFaceCensus.NoteRun(SKTypeface, ushort[])` 与 `NoteFaceSource(...)`
（后者由 `FontSet` 加载时调用，已记好"面 → 文件/faceIndex"）。T2b 只需在它的绘制点调 `NoteRun`。

### 4.34.2 这次读数顺带带出的两条**新事实**（对 (乙) 有用）

1. **`FontSet` 在真应用里加载了 300 份面**，其中**含 CJK 面**：
   `Noto Sans CJK JP / NotoSansCJK-Black.ttc faceIndex=0`、`Noto Sans CJK KR / NotoSansCJK-Bold.ttc` …
   ⇒ 一旦 (甲) 修好（PC 给出真 CJK id），**我们这侧是"有面可用"的**，
   剩下的是"选面要有覆盖判据"（即 (乙) 的第二道正确性）。
2. ⚠️ **一个更大的推论（需要另一次读数才能定）**：`TextRenderer` **在真应用里完全没被调到**
   ⇒ 那么真应用的字形是**别的绘制器**画的（T2b 的 `SkiaRenderBackend`/`GlyphRunPainter` 那条），
   **`MilPresentation.EnsureGlyphRenderer()` + `Text.TextRenderer.AttachTo(provider, GlyphRenderer)` 这条接线在真应用里没有生效**
   （它可能在 HelloMil/测试路径里生效）。**这条不是本轮结论**，登记为待查：
   若成立，则"字形渲染器"的归属与控制点要重新画（我的 `EnsureGlyphRenderer` 里的选面逻辑可能对真应用**无效**）。
   **判别方法**：在 `AttachTo` 里加一句"只读、缺省关"的记号，看真应用有没有走它（同 census 的形态）。

---

## 4.35 ⭐ 自我纠正 + (乙) 的读数：**"0 run" 是我的观测窗口错了，不是路径不存在**

### 4.35.1 入口记号（全部只读、缺省关、每入口一次）

在**已知的每个字形绘制入口**各挂一个同形态记号（`Text/GlyphFaceCensus.NoteEntry`）后，真应用里命中情况：

```
[glyph-census] 入口命中：MilPresentation.RenderChannel（呈现路径）
[glyph-census] 入口命中：TextRenderer.AttachTo（被挂到 provider 上）
[glyph-census] 入口命中：TextRenderer.DrawResource
[glyph-census] 入口命中：TextRenderer.Draw
[glyph-census] 入口命中：GlyphRunPainter.Draw
```
⇒ **我这条接线在真应用里是活的**（`AttachTo` 挂上了、`DrawResource`/`Draw`/`GlyphRunPainter.Draw` 都被调到）。
⇒ **我上一轮那句"`TextRenderer` 不是真路径"是错的**（主控曾把它记作"结构发现"，**请一并更正**）。

### 4.35.2 错在哪（同族缺陷的新形态：**观测窗口选错**）

`Report()` 原来是"**进 `RenderChannel` 就报、且只报一次**" ⇒ 它**永远在第一帧**打印，
而**第一帧一条绘制都没有** ⇒ 报出 `共 0 个 run`。
**根因不是路径不存在，是"我在帧还没开始画的时候就去读了账"。**
⇒ 与已记档的同族缺陷并列：**空帧下的 `未画种类 0`、探针被它要测的事门控、基线钉在旧仪器上、
"0" 有两种含义** —— 这次是"**读数发生在事件之前**"。

**修法（已落地）**：`Report()` 增加前置条件 —— **至少画过一个 run 才报**（`_runs > 0`），报过不再报。

### 4.35.3 修好之后的读数（**部署件口径的对照 + 自建件读数**）

* **部署件**（`568181a7…`）上我上一轮报的 `0 run` 是**旧仪器**的读数 ⇒ **作废**。
* **修好后的自建桥**（`80af0ea2f3dcdcf4`，**仅诊断**）读数：
```
[glyph-census] 帧 938x938：渲染器实际用了 **300** 份面；共 **48** 个 run / **1270** 个字形，
               其中 id==0（.notdef）**332** 个；解析不到面的 run = **0**
[glyph-census]   面 0x62a292c7cbd0 family=**DejaVu Sans** file=**DejaVuSans.ttf** faceIndex=**0**
                 runs=**48** glyphs=1270 zeroIds=332
```
* `48 / 1270 / 332` 与 **T2b 的普查完全一致** ⇒ 两条独立仪器在同一批数据上对齐（互为交叉验证）。
* **在册 300 份面，实际只用了 1 份**。

### 4.35.4 ⇒ **(乙) 的答案（有测量支撑）**

| | PC 侧（T2b 普查） | 渲染器侧（本 census） |
|---|---|---|
| 用了几份面 | **2**（`pid=0x20000001/0x20000002`） | **1**（`DejaVuSans.ttf#0`） |
| 覆盖 | 41 runs + 7 runs | **48 runs 全用它** |

⇒ **PC 用了两个面，我们只用一份面画全部 48 个 run** ⇒ **至少有一组 run 是用"不是 shaping 那份面"光栅的**。
这就是 **债务 #14（面由 run 决定）** 的**测量支撑**（此前只是架构推断）：
PC 登记实际使用的面 → 把句柄当 `PIDWriteFont` 传下来 → MIL 存字段（T2b 已把 `PIDWriteFont` 搬进 `MilGlyphRun`）
→ 渲染器优先按该句柄解析面（`MilFontFaceTable` 目前 `Count = 0`，正是缺的那一环），
族名解析只当兜底。**规格与车道分配见 §4.36。**

### 4.35.5 与 (甲) 的关系（两条独立）

`332/1270` 个 `.notdef` 是 **PC 写进来的**（(甲)，T1c 在做）；
即使 (甲) 修好，**这 48 个 run 仍只会用 1 份面** ⇒ (乙) 必须在"真 id 出现之后"修，否则真 CJK id 也会被 `DejaVu Sans` 取成空/错字形。

### 4.35.6 T2b 那一行还需要吗？

**仍然要，但角色变了**：从"唯一取数途径"变成**交叉验证**（两条独立仪器在同一批数据上对齐，
正是主控要的"不靠单一来源下结论"）。我这条读数已经能给出"每个 run 用哪份面"。

---

## 4.36 债务 #14（面由 run 决定）—— **(乙) 的落地规格**（先规格、后动手）

> 依据（全部是本轮部署件口径的实测）：PC 侧用 **2** 个面（`pid=0x20000001/0x20000002`，41+7 runs）；
> 渲染器侧只用 **1** 份面（`DejaVuSans.ttf#0`，**48 runs 全用它**）；在册候选 **300** 份（含 `Noto Sans CJK JP/KR` 的 `.ttc`）。
> 现状字段：`MilGlyphRun.PIDWriteFont`（`Resources/MilResources.cs:419`）已由 T2b 从
> `MILCMD_GLYPHRUN_CREATE[FieldOffset(8)]` **原样搬入**（`Commands/MilCommandDispatcher.cs:909`，纯搬运无逻辑）；
> `MilFontFaceTable` 有 `Register(SKTypeface, simFlags)` / `RegisterFromFile(path, faceIndex, simFlags)` / `TryResolve(handle, out SKTypeface)`，
> 但**真应用里 `Count = 0`**（`MilFontFace_RegisterFromFile` 在 PC 侧**没有任何调用者**）——**这就是缺的那一环**。

### 4.36.1 ① PC 侧要改什么（**应用器；T1b/T1c 车道，由主控开**）

**目标**：让每个 glyph run 带上"我 shaping 时**实际用的那个面**"。

**方案 A（首选）**：PC 在**拿到字体面**时（`Typeface`/`FontFace` 解析出来、或 `GlyphTypeface` 加载完成处）
调一次 `MilFontFace_RegisterFromFile(<字体文件绝对路径>, <faceIndex>, <simFlags>)`，
把返回的句柄缓存在该 face 对象上；构造 glyph run 命令时把**该句柄**写进 `PIDWriteFont` 字段。
* 为什么首选：**复用现成机制**（注册/解析/引用计数都在 `MilFontFaceTable` 里），MIL 侧不需要新的 id 空间；
  句柄是**我们自己的**，语义明确、可校验（`TryResolve` 失败即"未知句柄"）。
* 成本：PC 侧要在字体加载路径上多一次调用 + 一个缓存字段；**应用器形态**（生成 `.Linux.cs` + csproj 接线，每次波重放）。
* 风险：**路径与 faceIndex 必须与 WPF 实际用的那份一致**（否则又是"面不符"）；`simFlags`（Bold/Oblique 模拟）
  要与 WPF 的 `DWRITE_FONT_SIMULATIONS` 对齐，否则粗体/斜体会是"合成"与"真面"不一致 ——
  **这一条要有断言**（见 §4.36.4 的观测）。

**方案 B（备选）**：PC 把"文件路径 + faceIndex"作为**独立的一次命令**（例如在 run 之前发一条
`MilFontFaceRegister` 类命令），MIL 侧建 id→面 的表，run 的 `PIDWriteFont` 仍是不透明 id。
* 成本更低（不改 run 的字段语义），但**多一条命令类型**（要动命令层 = T13/T1 车道），
  且顺序敏感（"run 之前必须已经登记"）。
* 风险：命令流可跨进程/可重放 ⇒ 必须保证"重放时登记先于 run"，否则面会缺。

### 4.36.2 ② MIL 侧要改什么（**本车道**）

1. **`MilGlyphRun` 已有字段**（见上）✔ 不动；
2. **`MilFontFaceTable` 落表**：`MilFontFace_RegisterFromFile` 已实现（`Interop/MilNative.FontFace.cs`）；
   需要的是"**PC 真来调**"（①）+ 一条**在册计数**（`Count` 已有）；
3. **渲染器优先按句柄解析面**（`Text/**`）：给 `TextRenderer` 加一个**新 seam**：
   `public Func<MilGlyphRun, SKTypeface> MilFaceResolver { get; set; }`（与既有 `MilFontResolver` 并列），
   在 `TryGetFont` 之前判定：
   ```
   if (run.PIDWriteFont != 0 && MilFontFaceTable.TryResolve((IntPtr)run.PIDWriteFont, out face)) → 用这个 face
   else → 今天的老路（描述/族名 → FontSet.TryResolve）
   ```
   ⚠️ `PIDWriteFont` 是 `ulong`、`MilFontFaceTable` 的键是 `IntPtr` ⇒ **转换处要有显式注释与范围校验**
   （非 0 且能解析才算命中，见 ④ 的计数）；
4. **`EnsureGlyphRenderer` 不变**（选面仍是兜底路径），因此**不会破坏现状**。

### 4.36.3 ③ `PIDWriteFont` 的语义（两条路，代价与风险）

| | 方案 A：PC 传**我们注册的句柄** | 方案 B：`PIDWriteFont` 保持**不透明 id**，另建 id→面 映射 |
|---|---|---|
| 语义 | 字段含义**变了**（从"上游 DWrite 指针"变成"本工程 `MilFontFaceTable` 句柄"）——**必须在契约里写明** | 字段语义不变，映射表是新东西 |
| 代价 | PC 加一次注册 + 缓存；MIL 无新表 | PC 加"路径/faceIndex"命令 + MIL 新建表；命令层要动 |
| 风险 | 若 PC 在**别的时刻**重新注册（句柄变了），旧 run 会解析成别的面 ⇒ 需要"每 face 注册**一次**并缓存"的约束 | 顺序敏感 + 可重放语义；两张表要一起配平 |
| 判据 | `TryResolve(句柄)` 成功率高 + **面覆盖 run 的 id**（CJK run 应落在 CJK 面上） | 同上，但多一层"id→面"的间接 |
| 结论 | **首选**（复用现成机制、语义可校验、无新命令） | 备选（只有当 PC 侧拿不到"文件路径/faceIndex"时才用） |

**共同前提**：① 与"我们注册时用的 faceIndex 一致"；② `simFlags` 与 WPF 的模拟位一致；
③ **每份面只注册一次**（句柄稳定）；④ 注册失败**不能**让 run 变成"没有面"（回落族名路径）。

### 4.36.4 ④ 回退与观测（**必须能把三种情况分开**）

在 `GlyphFaceCensus` 里加三个计数（缺省关，与现有输出同格式）：
* `faceHitByHandle = N`（**按句柄解析成功**的 run 数）；
* `faceFallbackToFamily = M`（**句柄缺失/解析失败 ⇒ 回落族名**的 run 数）；
* `faceHandleUnresolved = K`（**有句柄但 `TryResolve` 失败** —— 与"没有句柄"是**两种不同故障**，
  前者是"注册与 run 不同步"，后者是"PC 还没接线"）；
并按面打印 `runs=`（已有）⇒ **目标读数**：`faceHitByHandle = 48（2 个面：41 + 7）`、
`faceFallbackToFamily = 0`、`faceHandleUnresolved = 0`；
**修前基线**：`faceHitByHandle = 0`、`faceFallbackToFamily = 48`、`faceHandleUnresolved = 0`。

**验收（部署件口径）**：
1. **修前/修后对照**：上面的三个计数从 `0/48/0` → `48/0/0`；
2. **面数**：渲染器实际用 **2** 份面（与 PC 的 2 个 pid 对上），且那 7 个 CJK run 落在 **CJK 面**上；
3. **不得退步**：`未画种类 0`、`skia 指令 ≈180`、`ManagedLayer` 52/52、`Commands` 562/562；
4. **拉丁不许退步**（(甲) 修好前后都要看一遍拉丁）。

### 4.36.5 `NoteRun` 那一行

**保留在 `Draw` 内**（就是现在的位置：`TryGetFont` 之后、用 `font.Typeface`）——它已经能回答
"每个 run 用哪份面"；`MilFaceResolver` 落地后，**它读到的面就会自动变成"按句柄解析的面"**，
无需再改。**建议随同一批桥发出去**（主控裁）。

---

## 4.37 债务 #14 的 MIL 半边已落 + 两条前置检查 + **基线读数修正为 `0 / 0 / 48`**

### 4.37.1 前置检查①：`PIDWriteFont` 的消费者清单（**只有一处真读，且与语义无关**）

`grep -rn "PIDWriteFont" src/ build/ tests/ --include=*.cs`（排除 obj/bin）的全部命中：

| 位置 | 角色 | 换成"我们的句柄"之后 |
|---|---|---|
| `Commands/MilCommandStructs.cs:434` | 线格声明 `[FieldOffset(8)] ulong PIDWriteFont` | 不变（线上仍是 8 字节） |
| `Commands/MilCommandDispatcher.cs:909` | **写者**：`g.PIDWriteFont = s.PIDWriteFont;`（T2b 搬入） | 不变 |
| `Resources/MilResources.cs:419` | 字段声明 | 不变 |
| `Rendering/GlyphRunCensus.cs:140-152`（T2b） | **读者**：`== 0` 计数 + 按值分桶 + 打印 `pid=0x…` | **不受影响**：它按**值**分组，不解释语义（换语义后它仍在正确分组，只是组名从"pid"变"面句柄"） |
| `Text/GlyphRunLayout.cs:39`、`Text/TextRenderer.cs:49`、`Interop/MilPresentation.cs:322/975` | **注释**里提到该字段 | 文案层面 |

⇒ **没有任何消费者把它当 DWrite 指针解引用/解包**；唯一的真读者是**值无关**的普查。**换语义安全。**

### 4.37.2 前置检查②：`MilFontFace_RegisterFromFile` 的句柄稳定性（**实测：修前不幂等，已修**）

* 读代码：原实现末尾是 `Register(typeface, simFlags)`，而 `Register` 每次 `MilHandleSource.Next()`
  ⇒ **同一文件+faceIndex 每次调用都发新句柄**（方案 A 的"句柄稳定"前提**不成立**）。
* **修法（MIL 侧，已落地）**：`RegisterFromFile` 按 **`(path, faceIndex, simFlags)` 同 key 幂等**：
  命中既有句柄 ⇒ 复用（并把本次新加载的 `SKTypeface` dispose 掉，避免泄漏）。
* **实测**（`ManagedLayer.Tests.字体面登记_同一文件与faceIndex重复调用返回同一句柄`）：
```
font=build/fonts-ui/UI-NoLayout.ttf
第一次=0x20000001  第二次=0x20000001   （模拟位不同）=0x20000002
解析成功：family=Noto Sans
```
  ⇒ 同 key 同句柄 ✓；**不同模拟位是另一份面**（不会被误合并）✓。

### 4.37.3 MIL 半边（已落，`Text/**` + 一处 `Interop/`）

| 位置 | 改动 |
|---|---|
| `Text/TextRenderer.cs` | 新增 **`MilFaceResolver`** seam（`Func<MilGlyphRun, SKTypeface>`）+ `TryGetFont(request, preferredFace, out font)`；`DrawResource` 先问它，拿到面就**按面画**，拿不到回落族名路径 |
| `Text/GlyphFaceCensus.cs` | 三个计数：`NoteFaceHitByHandle` / `NoteFaceFallbackToFamily` / `NoteFaceHandleUnresolved`，汇总行新增一段"面来源（债务 #14）：**按句柄命中 = N / 回落族名（无句柄）= M / 有句柄但解析失败 = K**" |
| `Interop/MilPresentation.cs` | `EnsureGlyphRenderer` 里把 `MilFaceResolver` 接上：读 `run.PIDWriteFont` → **范围校验**（`0` 或 `> long.MaxValue` ⇒ 当没有句柄）→ `MilFontFaceTable.TryResolve` |
| `Interop/MilHandleTables.cs` | `RegisterFromFile` 同 key 幂等（见 4.37.2） |

编译 0 错 0 警；`ManagedLayer.Tests` **53/53**、`Commands.Tests` **562/562**。

### 4.37.4 ⚠️ 基线读数：**`0 / 0 / 48`，不是预期的 `0 / 48 / 0`**（修正一个我和主控共同的假设）

**自建桥**（`ec9b3db970aa86ec`，**仅诊断** —— 部署件 `0f8f9d76…` 里还没有这半边）：
```
[glyph-census] 帧 938x938：… 共 48 个 run / 1270 个字形，其中 id==0 = 332；解析不到面的 run = 0
[glyph-census] 面来源（债务 #14）：**按句柄命中 = 0** / **回落族名（无句柄）= 0** / **有句柄但解析失败 = 48**
```
**为什么不是 `0/48/0`**：我和主控都假设过"PC 侧还没接线 ⇒ `PIDWriteFont == 0` ⇒ 走回落"。
**实测推翻了它**：PC **一直在填这个字段**（T2b 的普查早就看到 `pid=0x20000001/0x20000002`，非 0），
所以那 48 个 run **有句柄、但句柄不是我们注册的** ⇒ 全部落进第三类。
⇒ **"有句柄但解析失败 = 48" 才是"PC 侧尚未接线"的正确基线形态**；
接上之后应当是 **`48 / 0 / 0`**（且面数从 1 变 2）。
⇒ 顺带说明：**今天仍能正常出字**，因为解析失败返回 null ⇒ 回落族名（现状不变），
这也正是"三种情况分开计数"的价值 —— 若只记一个"命中/未命中"，我们会把
"**PC 填了但填的不是我们的句柄**"误读成"**PC 没填**"，从而去查错方向（这正是本轮避免掉的第二次误判）。

### 4.37.5 待主控发桥后的对照（**翻转判据已就位**）

| | 基线（本轮，自建件） | PC 侧接上之后（部署件复测） |
|---|---|---|
| 按句柄命中 | **0** | **48**（2 个面：41 + 7） |
| 回落族名（无句柄） | 0 | 0 |
| 有句柄但解析失败 | **48** | **0** |
| 渲染器实际面数 | 1（`DejaVuSans.ttf#0`） | **2**（含 CJK 面） |

---

## 4.38 三条更正（两条是我的）+ D-d 的中途状态

### 4.38.1 🔴 `pid` 数值更正 + 出处纪律

* **应用里的 pid 是 `0x20000003` / `0x20000004`**（出处：T2b 逐 run 明细，`pid=0x20000003` ×14、`pid=0x20000004` ×66，
  帧汇总 `pid==0的run=0 不同面数=2`）。**本报告早先写的 `0x20000001/0x20000002` 是错的**。
* **错因（我这边）**：那两个值来自**我自己的"字体面登记幂等性"实测**返回（`第一次=0x20000001 / 第二次=0x20000001 / 不同模拟位=0x20000002`，见 §4.37.2），
  我把**自己测试里的句柄**当成了**应用里的 pid**。主控转述时又放大了一次（他已认）。
* **纪律（新）**：**凡引用具体数值，必须附出处（哪个文件/哪次输出/哪一行）** —— 同形态的句柄在不同上下文里会串。

### 4.38.2 🔴 我的仪器报了一次**假命中**：`TryResolve` 的 `DefaultTypeface` 回落

**现象**：在部署件 `20b76807…` 上我读到 `按句柄命中 = 48 / 0 / 0`、两份面（8 + 40 runs）、
**两份都叫 `DejaVu Sans` 且 `file=<未知>`** —— 与"PC 还没接线"的预期完全相反。

**根因（读代码）**：`MilFontFaceTable.TryResolve`（`Interop/MilHandleTables.cs:726-735`）在**句柄不认识**时会
**回落 `DefaultTypeface` 并 `return true`**（这是它给轮廓路径用的既有契约）。
我第一版 `MilFaceResolver` 直接用它 ⇒ **"PC 填的 pid 一个都不认识"被伪装成"48 个 run 全部按句柄命中"**，
而"两份 DejaVu Sans / 文件未知"正是**同一个默认面**（不是 FontSet 里那份）被当成命中。
（这也解释了 §4.37.4 那次 `0/0/48` 与这次的 `48/0/0` 之差：**桥不同 ⇒ `DefaultTypeface` 是否已设置不同** ⇒ 回落与否不同。）

**修法（已落地）**：新增 **`MilFontFaceTable.TryResolveExact(handle, out face)`**（只看 `_faces`，**不回落**），
`MilFaceResolver` 改用它；`TryResolve`（带回落）**原样保留**给既有消费者。

**修正后的读数**（自建桥 `db747ee1f08fbdf3`，**仅诊断**）：
```
面来源（债务 #14）：按句柄命中 = 0 / 回落族名（无句柄）= 0 / 有句柄但解析失败 = 48
渲染器实际面：1 份（DejaVuSans.ttf#0，runs=48 glyphs=1270 zeroIds=332）
```
⇒ **真实的 (乙) 基线就是 `0 / 0 / 48`**，与 T2b 的**结构性事实**（资源模型里没有 font/typeface 类型 ⇒ 按构造不可解析）互相印证。

**⇒ 对部署件那条读数的处理**：`20b76807…` 载的是**修前**的 seam ⇒ **它那条 `48/0/0` 作废**；
请下一版桥带上 `TryResolveExact`，我再在部署件上复读，届时"基线 `0/0/48` → 接上后 `48/0/0`"才是被对照过的翻转。

### 4.38.3 D-d（96×96 源自报 vs 物化 1×1）：**中途状态 —— 我的自建件到不了那条路**

* 我的自建桥下跑同一样例：**`BitmapSource.Create` 直接失败 `E_HANDLE(0x80070006)` ⇒ 样例回退 `DrawingImage`**
  （`[wptd] 位图：BitmapSource.Create 失败…` + `WPTD_IMAGE_SOURCE=DrawingImage:fallback`）⇒ **根本走不到 CWIC 物化**
  ⇒ 我的 `WPF_LINUX_CWIC_TRACE` 没有东西可打（这就是那两次"trace 空"的原因，**不是仪器坏了**）。
* 而在**部署件**上同一样例 `Create` **成功 96×96 Bgra32** 且物化出 1×1 ⇒ **D-d 只在部署件上可达**，
  而**部署件里没有我的 trace**。
* ⇒ **下一步（一行命令的事）**：下一版桥带上 `WPF_LINUX_CWIC_TRACE`（缺省关，已写好），
  在**部署件**上跑 `WPF_LINUX_CWIC_TRACE=1 WPF_LINUX_WIC_TRACE=1` ⇒ 一次拿到四问：
  ① 登记时传的 `width/height`；② `GetSize` 返回值（两次）；③ `SKBitmap` 尺寸/`rowBytes`；④ 句柄归属与 `ForeignSourceCount`；
  并与 shim 自己的 `FOREIGN_SOURCE_REGISTER ext=…` 对照 ⇒ 判 (i) 传下来的就是 1×1 / (ii) shim 报错对象 / (iii) 我们用错字段。
* **已经能说的**：我那条台账打的是 `materialized.Width x materialized.Height`，而它是**按 `GetSize` 的输出**建的
  ⇒ **(iii)"我们用了错的尺寸字段"基本排除**；剩下 (i)/(ii)，需要上面那次对照。
* ⚠️ **不拿自建件对 D-d 下任何结论**（两个产物在 `Create` 这一步的行为就不同）。

---

## 4.39 部署件 `cefd7281…` 一次跑齐三条读数（固定表头 + 出处）

**固定表头**（`WPTD_ARTIFACTS`，T3 runner 原样输出）：
```
WPTD_ARTIFACTS bridge_sha=cefd7281f670a1fb bridge_bytes=4896624 pc_sha=b1decf1665d6519a pf_sha=1314570537a41a49 shim_sha=4c023937421db45f
```
⚠️ **该行里的 `shim_sha=4c023937…` 是过期的**：`/tmp/m7b-cefd2/libwpfwic.so` 实测
`sha256=669385504238d3269450be55…`、70,440 B（= 权威件），`bash build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` ⇒ **`APPSYNC=PASS`**。
⇒ **runner 的 `shim_sha` 字段不可信**（T3 的文件，我不动），读数里以**实测文件 sha** 为准。

### 4.39.1 ①三计数 + ②面名/覆盖（**新字段，这一版第一次有名字**）

```
[glyph-census] 面来源（债务 #14）：按句柄命中 = 48 / 回落族名（无句柄）= 0 / 有句柄但解析失败 = 0
[glyph-census] 帧 938x938：渲染器实际用了 302 份面；共 48 个 run / 1276 个字形，id==0 = 325；解析不到面的 run = 0
[glyph-census]   面 0x574a25cdc4f0 family=DejaVu Sans file=/usr/share/fonts/truetype/dejavu/**DejaVuSans-Bold.ttf** faceIndex=0 **覆盖U+4E2D=否** runs=8   glyphs=140  zeroIds=50
[glyph-census]   面 0x574a2524d410 family=DejaVu Sans file=/usr/share/fonts/truetype/dejavu/**DejaVuSans.ttf**      faceIndex=0 **覆盖U+4E2D=否** runs=40  glyphs=1136 zeroIds=275
```
**这三行把 (甲)/(乙) 的分工钉死了**：
* `按句柄命中 = 48` ⇒ **按句柄取面这条链是通的**（PC 侧登记 → `PIDWriteFont` → `MilFontFaceTable` → 渲染器），
  而且**粗细也对**（Bold 走 `DejaVuSans-Bold.ttf`、正文走 `DejaVuSans.ttf`）⇒ **(乙) 的机制在部署件上生效**（仍按主控要求标"暂定"，等 T1c 的 A/B）。
* **两份面 `覆盖U+4E2D=否`** ⇒ **PC 给 CJK 用的就是纯拉丁面** ⇒ `325/1276` 个 `.notdef` 是**shaping 阶段**产生的
  ⇒ **(甲) 是唯一剩下的真因**，而且这条现在**是"面级"证据**（不再只是"id==0 计数"）。

### 4.39.2 ③ cwic 四问（含新字段）

```
[cwic-trace] source=0x3 ownedByWic=True 登记传入=1x1 foreignSources=0 shimGetSize=1x1（第二次=1x1 ok=True）
             format=…c910（Pbgra32） → SKBitmap=1x1 colorType=Bgra8888 alphaType=Premul stride=4 bufferSize=4 copyPixels=S_OK
样例侧：[wptd] 位图：BitmapSource.Create 成功 96x96 Bgra32 stride=384 ／ 源自报 PixelWidth=96 PixelHeight=96
```
* ②`GetSize` **两次都 1×1 且稳定**；③`SKBitmap` 由它构造、`stride=4/bufferSize=4`、`CopyPixels=S_OK` ⇒ **(iii) 排除**（尺寸确实取自 `GetSize`）；
* `foreignSources=0`（那一刻外来源表为空）⇒ 这个 1×1 句柄**不是我们登记的外来源**，是 shim 自己创建的对象 ⇒ 证据**倾向 (i)：PC 传下来的句柄本身就是 1×1 的对象**；
* ⚠️ **我新加的那个字段名写错了**：`登记传入=1x1` 打的是 `TryMaterializeWicSource` **用 `GetSize` 得到的**尺寸，
  **不是** `WICShim_RegisterForeignSource` 的入参 ⇒ **下一版改名 `materialize尺寸=`**（否则读的人会以为是 shim 登记参数）。

### 4.39.3 `probe_describe` 的边界（T2 的工具，实测）

```
./probe_describe ./libwpfwic.so --selftest ⇒ 自检1 真句柄 4x3 ✓ / 自检2 虚构句柄 E_INVALIDARG ✓ / DESCRIBE_PROBE=PASS
./probe_describe ./libwpfwic.so 0x3        ⇒ DESCRIBE h=0x3 hr=0x80070057  <unknown>
```
⇒ **工具本身是好的（两向自检过），但它只能描述"自己进程里的 shim 表"**：`0x3` 是**应用进程**里那个 shim 实例的对象，
在探针进程里自然不存在。**⇒ "`0x3` 到底是什么对象"必须在应用进程内问**（例如 shim 增一个 describe 导出，T2 车道）。
**这条我不猜、也不拿它下 (i) 的最终结论** —— 现在只能说"证据倾向 (i)"（见 4.39.2）。

### 4.39.4 环境与纪律留痕

* 开跑前 `pgrep -f WpfTextDemo.dll` = **1 个残留**；跑完发现我自己这轮留下 **3 个** ⇒ **已 `pkill` 清空**（现 `0`）。
* `free -m`：total 7923 / used 4647 / available **1772–2407** MB；`uptime` load 3.48（3 核）⇒ 全程**串行**跑。
* 本轮**未 AOT 发布**、**未重建 PC**、未动 `Rendering/**` 与 shim；编译状态：`src/WpfGfx.Linux` **0 错 0 警**。

---

## 4.40 运行卫生事故（我这边）+ 本轮两处补充

### 4.40.1 ⚠️ 如实登记：`pkill -f` **误伤了两个旁观者**

* 我用过的原文（一行）：
  `pkill -f "[W]pfTextDemo.dll" 2>/dev/null`
  （同类还有 `pkill -f "[X]vfb :98"` / `"[X]vfb :94"` —— 那两个只打到我自己起的 Xvfb）
* **误伤**：约 18:47–18:52，**T2b 的 shell** 与**主控的一条命令**（命令行里都含 `WpfTextDemo.dll` 字面量）被 SIGTERM。
* **为什么方括号没救**：`[W]pfTextDemo.dll` 只做到**自排除**（不匹配 `pkill` 自己那行），
  但正则仍会匹配**任何**命令行里含该名字的进程 ⇒ 旁观者照样中招。
* **对本轮读数的影响：无。** 依据：我这轮读数的应用进程是我在同一条命令里用
  `dotnet WpfTextDemo.dll > log & APP_PID=$!` 起的，输出在任何清理之前就已落盘；
  清理只发生在读数之后。**读数有效、不需重跑**（但误伤本身是我的错，登记在此）。
* **改正（已执行并复跑）**：起应用记 `APP_PID=$!` → 收尾 `kill -TERM $APP_PID` → `wait`。
  本轮最后一次读数就是这么跑的：`APP_PID=1272703（按 PID 管理，不用 pkill -f）` → `已按 PID 终止：1272703`。
  **规则**：不再用 `pkill -f <名字>`；必须按模式时用 `/proc/<pid>/cmdline` 精确比对**并跳过自己**。

### 4.40.2 补充①：字段改名（`登记传入=` → `materialize尺寸=`）

`Interop/MilNative.Offscreen.cs`：原名会让人误以为那是 `WICShim_RegisterForeignSource` 的入参，
实际打的是 `TryMaterializeWicSource` **由 `GetSize` 得到**的尺寸 —— 已改名，`foreignSources=` 保留。

### 4.40.3 补充②：**进程内**描述句柄（不必等 T2、不必改 shim）

新用 shim 已有导出 **`WicShim_DescribeHandle(intptr_t h, char* buf, size_t cap)`**（`nm -D` 确认在册）：
`MilExternalHandleBridge.DescribeHandle(IntPtr)`（懒解析 + fail-safe，**只在缺省关的诊断分支里调**）
⇒ `[cwic-trace]` 现在多一行 `describe(source)= …`（`via/kind/foreign/ownedByWic/refs/size/rowBytes/fmt/pixels/decoded`）。
**为什么必须进程内**：`probe_describe` 是独立进程，只能描述**它自己**的 shim 表（实测 `0x3 → <unknown>` 且其自检 PASS）
⇒ 应用进程里那个 `0x3` 只有进程内问得到。**下一次发桥后一次跑齐即可钉死 (i)/(ii)。**

**编译状态**：`src/WpfGfx.Linux` **0 错 0 警**；`ManagedLayer.Tests` 工程 0 错。

---

## 5. 新增 / 修改文件清单与边界确认

**本轮（收尾轮 · 轨道 B/C）新增**
```
tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cRealAttachmentTests.cs   轨道 C：真接窗/resize/X 事件（3 条，真窗口 + 独立进程 xwd）
tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cMilStreamTests.cs        轨道 B：描述符 ABI 机械核对 + 字节交还（5 条）
tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/MilWicQueryInterfaceTests.cs 轨道 B：QI 放行/反放宽/配平高水位（8 条）
/tmp/m7cb-probe/{WbTest.csproj,Program.cs}                              **不入仓库**：真 PC + AOT 桥的对照探针（A/B 只换 .so）
```

**本轮（收尾轮）修改**
```
src/WpfGfx.Linux/Interop/MilNative.Window.cs      Attach/Detach 头注释改为**现行事实**（原文还写着"一行 X11 调用都没有"，已过期，会误导）
src/WpfGfx.Linux/Interop/MilNative.Misc.cs        ① MILIStreamWrite 转发 pfnWrite；② 描述符按值拷一份（上游 CManagedStreamWrapper(*pSD) 语义）；
                                                  ③ MmapMinAddr 守卫；④ MILQueryInterface 放行 IID_IWICBitmapSource（仅 WicBitmapSource 种类）；
                                                  ⑤ MILAddRef/MILRelease 认后台缓冲令牌，且别名分支排在外部句柄转发**之前**
src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs   双缓冲后台缓冲登记成设备对象 + 别名；Dispose 时注销位图句柄与别名
src/WpfGfx.Linux/Interop/MilHandleTables.cs       MilDeviceObjectKind.WicBitmapSource + MilBackBufferView(IMilNonOwningPayload) + MilBackBufferSourceTable
                                                  + MilStreamObject 持有描述符副本（IDisposable）+ DisposePayload 两个新 case
src/WpfGfx.Linux/Interop/MilNative.Exports.cs     ResetProcessStateForTests 清别名表（顺序：别名先于设备对象）
src/WpfGfx.Linux/Interop/MilPresentation.cs       呈现尺寸变化**免采样**台账（关键状态转换不被节流吞掉）
tests/.../Presentation.Tests/run-hellowpf.sh      ① app 级 resize 观测段（放大 + 白底计数 + 裁剪对比 + 累计帧数）；
                                                  ② 指针先挪开（输入崩溃会把观测打断）；③ 可选输入探针 HLWPF_INPUT_PROBE=1
docs/U2-M7c-report.md                             §4.16 / §4.17 / §4.18 + 门禁表更新
```

**历史（Phase 1 / Phase 2 时期）新增**
```
tests/WpfGfx.Linux.Tests/Presentation.Tests/          新测试工程（4 个 .cs + csproj）
  ├─ M7cChainTests.cs                                 链路 + 像素断言（3 条）
  ├─ X11WindowWrapTests.cs                            包装能力回归（5 条）
  ├─ X11Guard.cs                                      X11 守卫 + 经 shim 建窗
  ├─ run-hellowpf.sh                                  Phase 2 runner（app-local 部署，不写 samples/）
  └─ M7cProbe/HelloWpfProbe.cs                        §4.9 的运行期探针（**默认不编译**，由 csproj 开关链入）
src/WpfGfx.Linux/Interop/MilPresentation.cs           **M7c 核心**：HWND→呈现目标绑定 + 渲染/呈现 + 诊断
src/WpfGfx.Linux.Native/tools/patch-presentationcore-fontcache.py   补丁 I 应用器（幂等、--check）
docs/U2-M7c-report.md                                 本报告
```

**修改（§4.9 轮 · 补丁 K 之后）**
```
src/WpfGfx.Linux.Native/src/win32_misc.c       + 双门牌导出别名（W/裸名）一批；uxtheme 映射注释更新
src/WpfGfx.Linux.Native/src/win32_msg.c        + 消息台账（WPF_WIN32_MSG_TRACE）+
                                                 代发 DisplayDevicesAvailabilityChanged（含关断开关）
src/WpfGfx.Linux.Native/src/win32_internal.h   + wpf_notify_display_devices_available 原型 + 窗口记账字段
src/WpfGfx.Linux.Native/tools/check-shim-coverage.py  解析 MappedLibraries / 剥注释 / 修探测顺序 / 未映射 DLL 报表
src/WpfGfx.Linux/Interop/MilPresentation.cs    + 运行期台账、通道计数与资源表快照、呈现探针（全部 env 门控）
samples/HelloWpf/HelloWpf.csproj               + 探针文件的**条件** <Compile>（默认不参与编译）
tests/…/Presentation.Tests/run-hellowpf.sh     + shell32 别名、两个台账开关、探针开关、**构建失败即退出**
```

**修改（补充轮）**
```
samples/HelloWpf/HelloWpf.csproj               + 1 条 DirectWrite.Linux.Provider 直接引用（修 #2）
tests/…/Presentation.Tests/run-hellowpf.sh     重写为"一条命令可重跑"（构建→部署→轮询窗口→xwd→判定）
```

**修改（M7c 主轮）**
```
src/WpfGfx.Linux/Windowing/X11Window.cs        + Wrap(既有窗口) / _ownsWindow / InitializeFromServer / X 错误码转异常
src/WpfGfx.Linux/Windowing/X11PresentationTarget.cs  + WrapExisting / OwnsWindow
src/WpfGfx.Linux/Windowing/X11Native.cs        + XSetErrorHandler / XErrorHandler / XErrorEvent 偏移
src/WpfGfx.Linux/Windowing/X11Display.cs       + Xlib 错误处理器（LastErrorCode/TakeError）
src/WpfGfx.Linux/Interop/MilNative.cs           WgxConnection_SameThreadPresent：Commit 之后渲染+呈现
src/WpfGfx.Linux/Interop/MilNative.Window.cs    Attach/Detach 挂钩呈现目标；SetNotificationWindow 补 M7c 侦察结论注释
src/WpfGfx.Linux/Interop/MilNative.Exports.cs   ResetProcessStateForTests 清呈现绑定表
src/WpfGfx.Linux/Interop/AssemblyInfo.cs        + InternalsVisibleTo("WpfGfx.Linux.Presentation.Tests")
build/PresentationCore.Linux/PresentationCore.Linux.csproj   + 补丁 I（2 行 Compile）
build/PresentationCore.Linux/FontCacheUtil.Linux.cs          生成物（上游 + 非 Windows 分支）
```

**边界确认**
* `upstream/` 只读；`port-lib.py` / `verify-all.sh` / `handoff.md` / `tests/parity/` / `tests/U1-golden/` 未动。
* `samples/HelloWpf/`：**主轮零写入**（runner 复制到 /tmp 再覆盖新鲜程序集）；
  补充轮按主控指派修了 `HelloWpf.csproj`（+1 条引用），随后按验收要求 `dotnet build` 过一次，
  因此 `bin/obj` 现在是最新产物 —— 这是"该文件现在归你"之后被明确要求的步骤。
* `handoff.md` / `port-lib.py` / `verify-all.sh` / `wpf-linux.sln` / `tests/parity/` / `tests/U1-golden/` 未动。
* `build/` 只在**补丁 I**这一处改动，且走的是应用器脚本（幂等、可 `--check`），
  没有手编 csproj；重放顺序：`port-lib.py → reapply-patches.py(F/D/G) → patch-presentationcore-apartment.py(H)
  → patch-presentationcore-fontcache.py(I)`。
* `tests/.../ManagedLayer.Tests/`（M7b 的 28 条）本轮一行未改，也不受本轮改动影响
  （它只依赖 WindowsBase/PresentationCore + `libwpfwin32.so`，而本轮没碰 shim）。
* 全程 `-m:1`、增量构建、未跑 `verify-all.sh`、X 测试只用 `Xvfb :99`。

---

## 6. 复现命令

```bash
cd <repo>; export PATH="$HOME/.dotnet:$PATH"
tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh start
export DISPLAY=:99

# ── Phase 1 ──────────────────────────────────────────────────────────────
dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj -m:1                  # 0 错 0 警
dotnet test  tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj -m:1
cat tests/WpfGfx.Linux.Tests/Presentation.Tests/bin/Debug/net10.0/artifacts/m7c-chain.txt
# 截屏：…/artifacts/m7c-chain.png（320×200，左半 #c81e1e / 右半 #1446c8）

# ── Windowing/ 回归（改动必须有回归）────────────────────────────────────
dotnet test tests/WpfGfx.Linux.Tests/Windowing.Tests/WpfGfx.Linux.Windowing.Tests.csproj -m:1   # 44
dotnet test tests/WpfGfx.Linux.Tests/HelloMil.Tests/HelloMil.Tests.csproj -m:1                  # 19
dotnet test tests/WpfGfx.Linux.Tests/Commands.Tests/WpfGfx.Linux.Commands.Tests.csproj -m:1     # 552

# ── Phase 2 ──────────────────────────────────────────────────────────────
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-fontcache.py --check   # 补丁 I 幂等自检

# 1) shim / 桥接重建（本轮改了 shim；WpfGfx.Linux 的改动必须经 AOT 重新发布才生效）
src/WpfGfx.Linux.Native/build-shim.sh --symbols          # → bin/libwpfwin32.so + bin/exports.txt
python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py        # 覆盖自检（缺口 111，全在 PresentationNative）
bash build/MilBridge/run.sh build                        # AOT 重发布 wpfgfx_cor3.so（缺它则 MilPresentation 改动不生效）

# 2) 默认验收跑法（**不开探针**）
tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 25
#   → xwininfo 0x200005 "HelloWpf on Linux" 640x400 IsViewable；退出码 143；截屏纯白（见 §4.9.1）

# 3) 诊断跑法（要回答"可视树挂没挂 / render pass 跑没跑"时）
WPF_LINUX_HELLO_PROBE=1 tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 15
#   → [probe] 快照：… Template=**null** …；CompositionTarget.Rendering ~88 帧/秒

# 4) 对照实验（**诊断，不是修法**：手工补主题本该给的 Window 模板）
WPF_LINUX_HELLO_PROBE=1 WPF_LINUX_HELLO_TEMPLATE_PROBE=1 tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 20
#   → Template=有、可视子元素=1，随后撞 MILGetClassificationTables（EntryPointNotFound）⇒ 退出码 134

# 关掉某一条诊断：WPF_WIN32_NO_DISPLAY_NOTIFY=1 / WPF_WIN32_MSG_TRACE=0 / WPF_LINUX_MIL_TRACE=0

# ── #U（Unicode 分类表）────────────────────────────────────────────────────
python3 src/WpfGfx.Linux.Native/tools/gen-unicode-tables.py --stats   # 类数 230 / 叶子 142（UCD 13.0.0）
python3 src/WpfGfx.Linux.Native/tools/gen-unicode-tables.py           # 生成 src/win32_unicode_tables.c
src/WpfGfx.Linux.Native/build-shim.sh --abi                           # 编译期断言 + 打印新结构布局
python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py          # 缺口 111 → 110（该符号已实现）
WPF_LINUX_HELLO_PROBE=1 tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 15
#   → [probe] #U 原生自检=1 / 布局=72@0,8,16,24 / 读法对拍 40 码点 0 不一致 / 语义抽查 10 项 0 不符

# ── 补丁 L（主题字典路径上的 XamlAccessLevel）───────────────────────────────
python3 src/WpfGfx.Linux.Native/tools/patch-presentationframework-xamlaccess.py --check
python3 src/WpfGfx.Linux.Native/tools/patch-presentationframework-xamlaccess.py
dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -m:1   # 0 错 0 警
tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh 45
#   → 主题字典取到（SystemResources/XamlAccessLevel 从栈上消失）；
#     当前卡在 LoGetEscString（TextStore..cctor）⇒ 文本排版走了 LineServices 那条路，见 §4.10.5
```

**当前状态一句话**：Phase 1 全绿；Phase 2 依次打通了
**窗口**（真 WPF 窗口建得出、截得到）→ **主题**（#T + 补丁 L：`Window.Template != null`，
布局真的走进 `Grid → TextBlock`）→ **分类表**（#U：Unicode 表真实现并三层验证），
现在卡在 **文本排版的 LineServices 入口**（`LoGetEscString`）。
下一步是二选一（§4.10.5）：让 `CheckFastPathNominalGlyphs` 对简单拉丁文本走通快速路径
（推荐，可完全绕开 LineServices），或实现 LineServices 那 110 条导出。

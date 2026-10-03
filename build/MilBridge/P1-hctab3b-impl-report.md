# `P1-hctab3b` 报告 —— `T-B17` ①「宿主接出之后到上屏」的**逐跳现取** ＋ ② `E_HANDLE` **具名**（`FirstChanceException` 机器证）＋ ③ **三个成对候选全被帧面否证** ⇒ 具名前置 ＋ 可实施替代

> 任务：`build/MilBridge/tasks-tail2/T-B17.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T08:4x–09:5x+0800`（各格另注；**所有数值现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，**`HEAD=7129bff3cc8d6e5a571a611ec75462e25a1873ef`**（现取；＝ `T-B16` 后）。
> **开工件（现取，本席实测；⚠️ 与 `T-B16` 报告在册值不同，见 §0 末行）**：
> `libwpfwin32.so=5f9ed647c68197ae`｜`wpfgfx_cor3.so=a7a0f884b704ca96`｜`PresentationCore.dll=eb3f61e282265518`｜
> `PresentationFramework.dll=80da8f39989424ad`｜`WindowsBase.dll=05bdde9b5527bfde`｜`PresentationUI.dll=69136eecc84aa9f5`（＝**闸缺省关**的 Release 替身）。
> 装置：私有 `Xvfb :239 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §8）；
>   应用 ＝ 仓外 hc demo（`$APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，`DOTNET` 走 `$HOME/.dotnet`）。
> **重活全走槽**：`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 600..900`（本席 **41 趟腿**，全部 `HEAVYSLOT=ACQUIRED … RELEASED rc=0`）。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**；`upstream/**` 的行号与**生成件**行号（生成器会在前面多加若干行）**分别标注**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① 逐跳**（宿主接出→上屏） | 现取 4 跳（§1.1）：`FlowDocumentReader.SwitchViewingModeCore` `_contentHost.Child = feViewer`（`FlowDocumentReader.cs:938`）→ `DocumentPageView.ArrangeOverride` `this.AddVisualChild(_pageHost)`（`DocumentPageView.cs:356`）→ `DocumentPageHost.PageVisual` setter `AddVisualChild(pageVisualHost)` ＋ `pageVisualHost.Children.Add(_pageVisual)`（`DocumentPageHost.cs:95-97`）→ 两个 `GetVisualChild` 出口（`DocumentPageView.cs:489+/DocumentPageHost.cs:126`）→ **milcore 投影**（`MilCmdVisualCreate/SetContent/InsertChildAt`，`MilCommandDispatcher.cs:145/228/261`；`VisualProjection.cs:29-70`）。 |
| **①′ 这一跳**没断**（本席新证）** | ① `WPFGFX_ROOTDIAG=1`：`从根可达=415 孤立=1` ⇒ 页视觉**确实**在 milcore 的渲染树里（不是"没挂上"）；② 新探针 `WPF_PAGEVIEW_TYPES=1`（§1.3）：`FDV`（**画得出**）与 `DPH`（**画不出**）两条链的**托管子树同构**且**逐层的"有没有绘制"也相同**（`T0:PageVisual,draw=DrawingGroup`；`T3:ParagraphVisual,draw=DrawingGroup`）⇒ **断点不在托管视觉树**（不是"造不出/搬空/没有 Drawing"）。 |
| **② `E_HANDLE` 是什么（本轮主收获）** | **已具名**（`FirstChanceException` 机器证，§2）：**抛点** `MS.Internal.HRESULT.Check`；**调用点** `BitmapSource.set_WicSourceHandle` 里那句 `HRESULT.Check(UnsafeNativeMethods.MILUnknown.QueryInterface(value, IID_IWICBitmapSource, out wicSource))`（`BitmapSource.cs:584`）；由 `RenderTargetBitmap.FinalizeCreation()`（`RenderTargetBitmap.cs:256`）触发。**触发链**：`SinglePageViewer.HandleAllBreakRecordsInvalidated`（`SinglePageViewer.cs:1000`）→ `DocumentPageView.DuplicateVisual()`（`:626`）→ `DuplicatePageVisual()`（`:942`，`new RenderTargetBitmap` `:961`）。**根因**＝本移植 `MILQueryInterface`（`src/WpfGfx.Linux/Interop/MilNative.Misc.cs:175`，经 `:211` `MilExternalHandleBridge.QueryInterface`）对 **RTB 的位图源句柄**答 `E_HANDLE`（＝**WIC 离屏渲染目标**面缺口）。 |
| **③ 修（三个候选）** | (a) `DPH` 直挂（`WPF_PAGEVIEW_ONSCREEN=1`，现取 `mode=direct`）：帧**不变**；(b) 撤 `DPV` 的 `ClipToBounds` 覆盖（`WPF_DPV_CLIPTOBOUNDS=0`）：帧**不变**；(c) **`RTB` 降级**（`WPF_DPV_RTB_FALLBACK`）：**消除** `E_HANDLE`（症状成对 `1→0`，伴随 `[DPV] site=RtbFallback` 大声记账）—— 但**帧面判据不成立**（§4.3）。 |
| **③′ 为什么 (c) 不算修好（关键读法）** | 开腿 `tab3` 帧 **＝同腿 `tab1` 帧**（1,2,3 序 `c22457cf663453dd` 逐字节同；3,2,1 序 `d7126edbe1baa112` 逐字节同），且**关腿那个"页边框"（780 px）在开腿整个消失**；而关腿 `tab2`／`tab3` **各自有自己的帧**（3,2,1 序 `6f3d3ad1c42953a8`）⇒ 读作"**宿主进场后不再排帧**"（＝上一 tab 的帧），**不是**"页真的上屏"。⇒ **不记成修好**，本增量按 `T-B11`/`T-B13`/`T-B16` 体例做**缺省关**。 |
| **④ 门禁（现取）** | `nm==exports`（**846==846**，`diff -q` 空）｜`PTSGAP=PASS … so16=5f9ed647c68197ae exports=846`｜`PTS_GUARD=PASS legs=2/2`｜`PTS_COLORANCHOR=PASS k=24 … hits=3`｜`DEFREG=PASS declared=225 route_ids=225`｜`REPORTID=PASS files=364 ids=2266 declared=225`。§5 |
| **⑤ 症状门（成对）** | 缺省腿：`0x80070006 (E_HANDLE)=1`／`RtbFallback=0`；开腿：`0`／`1`。`magenta=0`／`Unrecoverable=0`／`alive=yes`／`app_rc=143`／`PTS_GAP entry=0`／`FORMATLINE-LINE=156`（各腿同）。§6 |
| **⑥ 边界（未违）** | 仓内只改 `build/PresentationFramework.Linux/**`（生成器 ＋ 生成件 ＋ csproj）；**未碰** `upstream/**`（只读）／仓外 hc 工程／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（只调不改）；**未跑**整趟 `verify-all`；app-local **六件与仓内权威件逐件一致**；显示位与进程**按 PID 收净**。§8 |
| **⚠️ 与 `T-B16` 在册值的差异（如实记）** | 开工时 `PresentationFramework.dll=80da8f39989424ad`，而 `T-B16` §7.3 在册的是 `1ddedabb2b033b9f` ⇒ **本代树上的"现值"与 `T-B16` 的读数不可直接比**（题面亦写"以开工件现值为准，别抄旧值"）。本席**只用自己的现取**做不回归判据。 |

**一句话**：`E_HANDLE` 本席**用机器证钉死了**（`BitmapSource.set_WicSourceHandle` 里那句 `MILUnknown.QueryInterface(…IID_IWICBitmapSource…)`，由 `RenderTargetBitmap.FinalizeCreation` 触发，源头是本移植没有 WIC 离屏渲染目标）；把它**降级**能消掉症状，却让 `tab3` 帧**退回上一 tab**（＝**宿主进场后没有渲染趟被排**，关腿那点可见重绘其实是那条**无关未处理异常**的副产物）⇒ **真断点**上移并具名到 **`PRECOND-TAB3-PAGE-RENDER`（宿主已接出并 Arrange，但没有渲染趟被排）** ＋ 新立 **`PRECOND-WIC-RTB`**；三个候选全部**帧面否证**，本轮**如实划界**，不假成功。

---

## §1 ① 逐跳现取：从「宿主接出」到「上屏」

### 1.1 四跳（件:行 ＋ 内容锚原文）

| 跳 | 件:行（现取） | 内容锚原文（或读数） | 谁在这一跳做事 |
|---|---|---|---|
| **甲** | `upstream/…/System/Windows/Controls/FlowDocumentReader.cs:938` | `_contentHost.Child = feViewer;` | 把**内部 `ReaderPageViewer`** 挂进 `PART_ContentHost`（`Decorator`）；上一句 `GetViewerFromMode` `:1150-1156` `_pageViewer.SetResourceReference(StyleProperty, PageViewStyleKey);` |
| **乙** | `upstream/…/Controls/Primitives/DocumentPageView.cs:356` | `this.AddVisualChild(_pageHost);`（同段 `:355` `_pageHost = new DocumentPageHost();`） | `DocumentPageView`（**样式模板里的那个页宿主**）把 `DocumentPageHost` 接进自己的视觉树 |
| **丙** | `upstream/…/MS/Internal/documents/DocumentPageHost.cs:95-97` | `pageVisualHost = new ContainerVisual(); this.AddVisualChild(pageVisualHost); pageVisualHost.Children.Add(_pageVisual);` | `DocumentPageHost` 把**页视觉**装进一个**新建 `ContainerVisual` 包壳**，再把包壳接上（`:436` `_pageHost.Arrange(new Rect(_pageHost.CachedOffset, _documentPage.Size));` 是它的排版） |
| **丁** | `DocumentPageView.cs:489+` `GetVisualChild`→`return _pageHost;` ／ `DocumentPageHost.cs:126` `return VisualTreeHelper.GetParent(_pageVisual) as Visual;` | 两个出口都在（现取 `[PAGEVIEW] site=DPV.GetVisualChild`／`DPH.GetVisualChild` 各 **200** 次） | 托管侧视觉枚举出口 |
| **戊** | `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs:145/228/261`（`MilCmdVisualCreate`／`MilCmdVisualSetContent`／`MilCmdVisualInsertChildAt`，后者 `v.Visual.Children.Insert(index, s.HChild)`）＋ `src/WpfGfx.Linux/Resources/VisualProjection.cs:29-70`（`Project`） | 命令流把句柄图投影成 `MilVisual` 树 | **milcore 侧**（本移植的「谁把子视觉挂进渲染树」就是这里） |

### 1.2 现取：**这一跳是通的**（`WPFGFX_ROOTDIAG=1`，件:行 ＋ 原文）

`WPFGFX_ROOTDIAG=1` ＋ `WPF_LINUX_MIL_LOG=/tmp/mil17b.log`（`T-B17` 现取，闸开腿）：

```
ROOTDIAG 通道2 target.Root=0x2 快照子=0 活投影子=1 镜像visual=415 从根可达=415 孤立=1 资源=1325
```

（`src/WpfGfx.Linux/Interop/MilPresentation.cs:865-868` 是该行的生产者；语义见 `:828-831`。

⇒ **"页宿主/页视觉到底在不在渲染树里"这一问，本轮有了正面读数：`孤立=1`（且那 1 个与页无关）、`从根可达=415`**。⇒ **甲～戊四跳都真的发生了**，断点**不在这里**。

### 1.3 现取：**托管子树同构**（新探针 `WPF_PAGEVIEW_TYPES=1`，只读、缺省关）

`Sub()` 只打 `k`（子数）／`b`（包围盒）／`c`（内容包围盒），而 `VisualTreeHelper.GetContentBounds` 对 `ContainerVisual` 返回的是**子树并集** ⇒ "空壳容器"与"真有绘制的叶子"在 `Sub` 里**长得一样**。本席补一格 `TYPES=`（层号／类型名／是否 `DrawingVisual` 且 `Drawing` 非空），挂在 `[FDV]`（**画得出**）与 `[DPH]`（**画不出**）两条链上（`[FDV]` 见 `DocumentPageView.cs:250` 那条 `ReportFdv`；`[DPH]` 见 `DocumentPageHost.cs:141/149`）：

```
[FDV] … TYPES=T0:PageVisual@0x2a6fa61,k=1,draw=DrawingGroup | T1:ContainerVisual@0xf4c6b9,k=2,draw=- | T2:ContainerVisual@0x9afc82,k=1,draw=- | T3:ContainerVisual@0x3a96b69,k=1,draw=- | T4:ParagraphVisual@0x3decd6c,k=3,draw=none | … | T2:ContainerVisual@0x172e097,k=2,draw=- | T3:ParagraphVisual@0x109e54f,k=2,draw=DrawingGroup | T4:ContainerVisual@0x1590fcd,k=1,draw=- | T5:ContainerVisual@0x361f531,k=1,draw=- | …
[DPH] … TYPES=T0:PageVisual@0x202fcb2,k=1,draw=DrawingGroup | T1:ContainerVisual@0x3886ada,k=2,draw=- | T2:ContainerVisual@0x3cbc1ae,k=1,draw=- | T3:ContainerVisual@0x22b9a18,k=1,draw=- | T4:ParagraphVisual@0x21ae249,k=3,draw=none | … | T2:ContainerVisual@0x229cf26,k=2,draw=- | T3:ParagraphVisual@0x378485a,k=2,draw=DrawingGroup | T4:ContainerVisual@0x33a8b2a,k=1,draw=- | T5:ContainerVisual@0x24030fe,k=1,draw=- | …
```

**两条链逐层同构、连"哪一层有绘制（`draw=DrawingGroup`）"都一样**（`T0:PageVisual` 的 `DrawingGroup` ＝ `PageVisual.DrawBackground`；`T3:ParagraphVisual` 的 `DrawingGroup` ＝ 段落内容）。⇒ **"页视觉里没有内容/没有绘制"这一族假设，本轮**机器排除。
（⚠️ 该探针**缺省关**：它会**枚举**视觉树深层；现取开/关两腿 `tab1`／`tab2`／`tab3` 帧**逐字节相同**（`c22457cf663453dd`／`c22457cf663453dd`／`71a93980be1f49a6`）⇒ **本形态下测得**不扰动，缺省关仍是**保守选择**。）

### 1.4 现取：**这条链"每一步都做到了、却仍不上屏"**（与前两轮的差）

`T-B11`（挂载／定位）／`T-B12`（页视觉被搬走）／`T-B13`（页宿主是谁）／`T-B16`（主题字典）都在**甲～丁**这一段上找过。本轮把**这一段的"通"做成读数**（§1.2 可达、§1.3 同构），于是断点只能落在**戊之后**（milcore → 像素）或**"何时排帧"**上 —— 这就是 §2／§4 的靶。

---

## §2 ① 现取：`E_HANDLE` **是什么**（件:行 ＋ 原文；本轮主收获）

### 2.1 方法：`FirstChanceException` 只读捕获器（新生成件）

`T-B16` 拿到的只有**抛点**（`MS.Internal.HRESULT.Check`），"谁把 `hr=0x80070006` 交给它"**没有直读面**。本席新建生成件 `build/PresentationFramework.Linux/WpfLinuxEHandleProbe.Linux.cs`（生成器 `EHANDLE_PROBE_TEXT`，`P8`／`temp+rename`）：
`AppDomain.CurrentDomain.FirstChanceException`（**首次异常**，比 `DispatcherUnhandledException` 早、**不改变**异常是否被处理）＋ 只对 `COMException` 且 `HResult==0x80070006` 记账 ＋ **有界**（≤8 条 × 栈 ≤28 层）＋ **缺省全关**（`WPF_EHANDLE_PROBE=1` 才装钩子）。

### 2.2 现取栈（`ehandle17` 腿，`app.log:16691-16700` —— **原文**）

```
[EHANDLE] #1 msg=The handle is invalid.
 (0x80070006 (E_HANDLE))
[EHANDLE]   at MS.Internal.HRESULT.Check(Int32 hr)
[EHANDLE] #2 msg=The handle is invalid.
 (0x80070006 (E_HANDLE))
[EHANDLE]   at MS.Internal.HRESULT.Check(Int32 hr)
[EHANDLE]   at System.Windows.Media.Imaging.BitmapSource.set_WicSourceHandle(BitmapSourceSafeMILHandle value)
[EHANDLE]   at System.Windows.Media.Imaging.RenderTargetBitmap.FinalizeCreation()
[HC-UNHANDLED] #528 COMException: The handle is invalid.
 (0x80070006 (E_HANDLE)) ｜ 首帧 at MS.Internal.HRESULT.Check(Int32 hr)
```

> `#1` 只有抛点一帧（**如实记**：首次异常的 `StackTrace` 在那一趟只捕到一层）；`#2` 给出了**调用点链**，且紧接的 `[HC-UNHANDLED]` 就是同一条异常冒到 `Dispatcher`。

### 2.3 逐跳（件:行 ＋ 原文）

| 跳 | 件:行（现取） | 内容锚原文 | 说明 |
|---|---|---|---|
| 己 | `upstream/…/PresentationCore/System/Windows/Media/Imaging/BitmapSource.cs:584` | `HRESULT.Check(UnsafeNativeMethods.MILUnknown.QueryInterface(`<br>`    value, ref _uuidWicBitmapSource, out wicSource));` | **调用点**（`WicSourceHandle` 的 **setter**，属性定义 `:563`）；`_uuidWicBitmapSource = MILGuidData.IID_IWICBitmapSource` |
| 庚 | `upstream/…/Imaging/RenderTargetBitmap.cs:256` | `WicSourceHandle = bitmapSource;` | 由 `FinalizeCreation()`（`:227`）执行；上游 `:234` 先 `MILFactory2.CreateBitmapRenderTarget`、`:247` `MILRenderTargetBitmap.GetBitmap` |
| 辛 | `upstream/…/Controls/SinglePageViewer.cs:1000` | `pageViews[index].DuplicateVisual();` | 由 `HandleAllBreakRecordsInvalidated`（`:995`，`BreakRecordTableInvalidated` 事件处理器，订阅点 `:516`）逐个页宿主调用 |
| 壬 | `upstream/…/Controls/Primitives/DocumentPageView.cs:626/942/961` | `internal void DuplicateVisual()` ／ `private DrawingVisual DuplicatePageVisual()` ／ `RenderTargetBitmap renderTargetBitmap = new RenderTargetBitmap(…, PixelFormats.Pbgra32);` | **`RenderTargetBitmap` 就是在这里造的**；同块只有 `catch(System.OverflowException)`（注释：`render target creation not possible under current memory conditions`） |
| 癸 | `src/WpfGfx.Linux/Interop/MilNative.Misc.cs:175`（`MILQueryInterface`）→ `:211` `return MilExternalHandleBridge.QueryInterface(pIUnknown, ref guid, out ppvObject);` | 本移植的 QI 出口 | 对 **RTB 的位图源句柄** 答不到 `IID_IWICBitmapSource` ⇒ `E_HANDLE`。同族缺口在 `src/WpfGfx.Linux/Interop/MilNative.Offscreen.cs:651-702`（`MilResource_CreateCWICWrapperBitmap` 的 `未登记句柄 → E_HANDLE`）有**逐字**台账 |

### 2.4 已排除的候选（都真跑过）

| 候选 | 现取反证 |
|---|---|
| `MilConnection_CommitChannel` 的 `★E_HANDLE#1`（`MilNative.cs:161-164`） | `WPF_LINUX_MIL_LOG` 全汇（8981 行）里 **0 条** `★` |
| `MilConnection_CloseBatch`／`MilResource_SendCommand` 的 `★E_HANDLE`（`:126/:355`） | 同上，**0 条** |
| 字体面令牌反查（`MilNative.Glyph.cs:111`，`GlyphTypeface.cs:1263`） | `WPF_LINUX_FACE_HANDOFF_DIAG=1` 现取：`status=NativeAotExport … registerExport=找到(MilFontFace_RegisterFromFile) nativeAllocations=4` ⇒ **已跨运行时接通**，不是它 |
| CWIC 包壳未登记（`MilNative.Offscreen.cs:701`） | 本条的栈**不是**它的调用点（上面 §2.2 是 `set_WicSourceHandle`），且那支有独立台账 |

---

## §3 ② 修：三个候选（都 `P8`、都可撤、都真跑）

| 候选 | 落点（件:行） | 闸 | 结果 |
|---|---|---|---|
| **(a) `DPH` 直挂** | 既有（`T-B11` 的 `WPF_PAGEVIEW_ONSCREEN`）：`DocumentPageHost.PageVisual` setter 改 `AddVisualChild(_pageVisual)` ＋ `GetVisualChild` 返 `_pageVisual` | `WPF_PAGEVIEW_ONSCREEN=1` | 现取 `[DPH] site=Attach … mode=direct`（**接线确实进了**）；`tab3` 帧 **`71a93980be1f49a6`** ⇒ **与关腿逐字节同** ⇒ 否证 |
| **(b) 撤 `DPV` 的 `ClipToBounds` 覆盖**（本轮新加） | `build/PresentationFramework.Linux/DocumentPageView.Linux.cs`（生成器 `DPV_CLIP_*`）：上游静态构造里 `ClipToBoundsProperty.OverrideMetadata(typeof(DocumentPageView), new PropertyMetadata(BooleanBoxes.TrueBox));` | `WPF_DPV_CLIPTOBOUNDS=0` | `tab3` 帧 **`71a93980be1f49a6`** ⇒ 否证 |
| **(c) `RTB` 降级**（本轮新加，**症状消除但帧面否证**） | `DocumentPageView.Linux.cs` 的 `DuplicatePageVisual()` 尾部（生成器 `DPV_RTB_*`）：在既有 `catch(System.OverflowException)` **之后**补 `catch(COMException)`，`WPF_DPV_RTB_FALLBACK=1` 时**降级为"显示实时页视觉"** 并**大声**打 `[DPV] site=RtbFallback …`；缺省**不生效**（`throw;` 照旧＝上游） | `WPF_DPV_RTB_FALLBACK=1` | **症状**：`0x80070006 (E_HANDLE)` **1→0**、`[HC-UNHANDLED]…COMException` **1→0**、`[DPV] site=RtbFallback` **0→1**；**帧面**：`tab3` 帧由 `71a93980be1f49a6` 变成 **`c22457cf663453dd`**，但该帧 **＝ 同腿 `tab1` 帧（逐字节）**，且**关腿的"页边框"（780 px）整个消失** ⇒ **不记成修好**（§4.3） |

**上游同源口径（为什么 (c) 不是"随手吞异常"）**：上游**同一块**早已把"渲染目标建不出来"当**可降级** —— 紧邻那句 `catch(System.OverflowException)` 的注释**逐字**是 `render target creation not possible under current memory conditions`。本移植的 WIC 离屏渲染目标**不存在**（§2.3 癸），属**同一语义**的第二种"建不出来"。即便如此，**帧面判据不成立 ⇒ 缺省关**（可复现：`WPF_DPV_RTB_FALLBACK=1`）。

**幂等（`P8`）**：生成器重跑 == 现盘（现取）。

```
$ for f in reapply-patches.py DocumentPageView.Linux.cs DocumentPageHost.Linux.cs WpfLinuxEHandleProbe.Linux.cs PresentationFramework.Linux.csproj; do sha256sum "$f"; done > /tmp/g1.txt
$ python3 build/PresentationFramework.Linux/reapply-patches.py ; … > /tmp/g2.txt
$ diff /tmp/g1.txt /tmp/g2.txt   ⇒  空        # IDEMPOTENT=OK
```

现取关键件 `sha16`：`reapply-patches.py=8ecc49dfad77f782`｜`DocumentPageView.Linux.cs=36e6fc82803767f1`｜`DocumentPageHost.Linux.cs=c38aa683ad96a207`｜`WpfLinuxEHandleProbe.Linux.cs=b3a35fe5e6d40d9f`｜`PresentationFramework.Linux.csproj=213832e05e149175`｜`bin/Release/PresentationFramework.dll=c7732cc5b97a78ea`（**0 警告 0 错误**）。

---

## §4 ③ 真跑：成对读数 ＋ 反极性

### 4.1 腿表（现取；装置 `:239`；`sha16` ＝ 整屏 `import -window root`）

| 腿 | `PresentationFramework.dll` | `PresentationUI.dll` | 主题闸 | 序 | `tab1` | `tab2` | **`tab3`** | `tab3` 文档区色数 | `tab3` 具名色 | `E_HANDLE`（`0x80070006 (E_HANDLE)`） | `RtbFallback` |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `base17`／`rtbOffTheme17` | `80da8f39989424ad` | `69136eecc84aa9f5` | 关 | `1,2,3` | `c22457cf` | `c22457cf` | **`0c51d1ad`** | 148 | `0/0/0/0` | 0 | 0 |
| `themeon17` | `80da8f39` | `a901772b7589382a` | 开 | `1,2,3` | `c22457cf` | `c22457cf` | **`71a93980`** | 148 | `0/0/0/0` | 1 | 0 |
| `rep1`／`rep2` | **`c7732cc5b97a78ea`**（本轮产物） | `a901772b` | 开 | `1,2,3` | `c22457cf` | `c22457cf` | **`71a93980`** | 148 | `0/0/0/0` | 1 | 0 |
| **`finalRtbOn17`** | `c7732cc5` | `a901772b` | 开 | `1,2,3` | `c22457cf` | `c22457cf` | **`c22457cf`** | **724** | **`9831/910/44/5830`** | **0** | **1** |
| `base321b` | `80da8f39` | `69136ee` | 关 | `3,2,1` | `c22457cf` | `fae93ea5` | **`0c51d1ad`** | 148 | `0/0/0/0` | 0 | 0 |
| `defOn321` | `c7732cc5` | `a901772b` | 开 | `3,2,1` | `d7126edb` | `6f3d3ad1` | **`6f3d3ad1`** | 148 | `0/0/0/0` | 1 | 0 |
| **`rtbOn321c`** | `c7732cc5` | `a901772b` | 开 | `3,2,1` | `d7126edb` | `d7126edb` | **`d7126edb`** | **724** | **`9831/910/44/5830`** | **0** | **1** |
| `fixOff321b`（主题关） | `0e40dce5679a43a3` | `69136ee` | 关 | `3,2,1` | `c22457cf` | `fae93ea5` | **`0c51d1ad`** | 148 | `0/0/0/0` | 0 | 0 |
| **`rtbRev17`（反极性）** | `0e40dce5` | `a901772b` | 开 | `1,2,3` | `c22457cf` | `c22457cf` | **`71a93980`** | 148 | `0/0/0/0` | **1** | 0 |
| `inval17b`（＋`WPF_DPV_INVALIDATE=1`） | `ec72e7d68eb384b8` | `a901772b` | 开 | `1,2,3` | `c22457cf` | `c22457cf` | `c22457cf` | — | — | 0 | 1 |
| `clipoff17`（`WPF_DPV_CLIPTOBOUNDS=0`） | `da117867f0ba1050` | `a901772b` | 开 | `1,2,3` | `c22457cf` | `c22457cf` | **`71a93980`** | 148 | `0/0/0/0` | 1 | — |
| `themeonDirect`（`WPF_PAGEVIEW_ONSCREEN=1`） | `80da8f39` | `a901772b` | 开 | `1,2,3` | `c22457cf` | `c22457cf` | **`71a93980`** | 148 | `0/0/0/0` | 1 | — |

### 4.2 **成对（同一产物 `c7732cc5`，只差一个 env；两个序各一次）**

| 面 | 缺省（闸关） | **`WPF_DPV_RTB_FALLBACK=1`** | 判 |
|---|---|---|---|
| `tab3` 帧（`1,2,3`） | `71a93980be1f49a6`（562 色／文档区 148／具名 `0/0/0/0`） | **`c22457cf663453dd`**（1039／**724**／**`9831/910/44/5830`**） | 变了 |
| `tab3` 帧（`3,2,1`） | `6f3d3ad1c42953a8`（570／148／`0/0/0/0`） | **`d7126edbe1baa112`**（1047／**724**／**`9831/910/44/5830`**） | 变了 |
| `0x80070006 (E_HANDLE)` | **1** | **0** | **症状消除** |
| `[HC-UNHANDLED] … COMException` | **1** | **0** | **症状消除** |
| `[DPV] site=RtbFallback` | 0 | **1**（`hr=0x80070006`，点名调用点） | 大声记账 |
| `tab1`／`tab2`（同序、同产物） | `c22457cf`／`c22457cf` | `c22457cf`／`c22457cf` | **逐字节零变化** |

**反极性**（`WPF_DPV_RTB_FALLBACK=0`，`rtbRev17`）：`tab3` 帧 **逐字节回** `71a93980be1f49a6`、`E_HANDLE` 回 **1** ⇒ **成立**。

### 4.3 ⚠️ **为什么开腿的"回升"不能记成"页上屏"**（本席的判法与证据）

1. 开腿 `tab3` 帧**与同腿 `tab1` 帧逐字节相同**（两个序都是）；而**关腿**的 `tab3` 帧与 `tab1` **不同**（差 **780 px** 的"页边框"，`1,2,3` 序现取 `imgdiff`：`BBOX (303,146,798,520)`）。
2. ⇒ 开腿**少了**关腿那个"页边框"，**多了**的只是"上一 tab 的帧"（关腿 `tab2`／`tab3` 各有自己的帧：`3,2,1` 序 `6f3d3ad1c42953a8`；开腿三个都退化成同一个 `d7126edb`）。
3. 归因（**现取可证伪**）：开腿**移除了**那条未处理异常 ⇒ 那条异常路径**本来就是**读者页区域那一次重绘的**唯一触发者** ⇒ 移除它＝**没有渲染趟被排**。旁证：本席另把"宿主接上后**主动排一帧**"做成闸（`WPF_DPV_INVALIDATE=1`，`ArrangeOverride` 末尾 `InvalidateVisual()`；**第二版**改走 `Dispatcher.BeginInvoke(DispatcherPriority.Render, InvalidateVisual)`）——**两版帧都仍＝`c22457cf663453dd`**（＝不排帧），即**排帧本身**没把它们变成"页边框在场"的形态。
4. ⇒ **`PRECOND-TAB3-PAGE-RENDER` 仍在**：宿主已接出、已 `Arrange`、渲染树可达、托管子树有绘制 —— **但读者页区域没有渲染趟被排**。**本增量不改判据**。

---

## §5 ④ 门禁（逐条现取；本席跑的）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| awk '{print $3}' \| sort` vs `src/WpfGfx.Linux.Native/bin/exports.txt` | **`846 == 846`**，`diff -q` 空 ⇒ `NM_EQ_EXPORTS=PASS` |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5f9ed647c68197ae exports=846`**；`PTSGAP_CITED=PASS refs=1 strict=1`；rc=0 |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- direction=in-file phase=realized`**；`PTS_N1_GATE=PASS`；`PTS_ENFE=PASS total=0` |
| `PTS_COLORANCHOR` | 同上（`k=24`） | **`PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 min=200 base=全部0`**（**未回退**）；`k=23` `NOINFO(no-anchor-registered-for-k23)` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0`，rc=0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=364 ids=2266 declared=225`**，rc=0（本载体落地**前**现取；落地后 ＋1） |

**未跑**：整趟 `verify-all`（照派单 ②）；`static-jaws-check.sh`。

---

## §6 ⑤ 症状门（成对）

| 症状门 | 缺省（`c7732cc5`，主题开） | `WPF_DPV_RTB_FALLBACK=1` | `WPF_DPV_RTB_FALLBACK=0`（反极性） | 主题**关**（`fixOff321b`） |
|---|---|---|---|---|
| `magenta` | 0 | 0 | 0 | 0 |
| `Unrecoverable system error` | 0 | 0 | 0 | 0 |
| `PTS_GAP entry=` | 0 | 0 | 0 | 0 |
| `[FORMATLINE-LINE]` | 156 | 156 | 156 | 156 |
| `FailFast` | 84／60（两次） | 169 | 75 | 94 |
| `[HC-UNHANDLED]` | 516／360 | 1009 | 442 | 553 |
| 其中 **`COMException`＋`0x80070006 (E_HANDLE)`** | **1** | **0** | **1** | **0** |
| `alive`／`app_rc` | yes／143 | yes／143 | yes／143 | yes／143（均**本席按 PID 收**） |
| `colors`（整屏；`tab3`） | 562 | 1039 | 562 | 562 |

---

## §7 断点归属 · 具名前置 · 可实施替代 · `NOINFO`

### 7.1 本轮**已逐条排除**（都真跑过）

| 假设 | 现取反证 |
|---|---|
| 「页宿主**没挂进渲染树**」 | `WPFGFX_ROOTDIAG=1`：`从根可达=415 孤立=1`（§1.2） |
| 「页视觉里**没有绘制内容**／被搬空」 | `WPF_PAGEVIEW_TYPES=1`：两条链**逐层同构**，`T0:PageVisual`／`T3:ParagraphVisual` **都有** `draw=DrawingGroup`（§1.3）；`[PAGEVIS]` 全趟 `oldParent=null`、`Redrive` **0 行** ⇒ `T-B12` 的修按条件正确未动手 |
| 「`ContainerVisual` 包壳（`DocumentPageHost` 那条）是元凶」 | `WPF_PAGEVIEW_ONSCREEN=1` 现取 `mode=direct`，帧**逐字节不变**（§3(a)） |
| 「`DPV` 的 `ClipToBounds=true` 把子树裁了」 | `WPF_DPV_CLIPTOBOUNDS=0`，帧**逐字节不变**（§3(b)） |
| 「`E_HANDLE` 是"页画不出来"的直接原因」（`T-B16` §5 的合理推断） | **证伪**：把 `E_HANDLE` **降级掉**（症状 1→0）之后，`tab3` 帧**反而不动**（＝上一 tab 的帧）⇒ 那条异常路径是**可见重绘的触发者**，不是"阻断者"（§4.3） |

### 7.2 具名前置（具名 ＋ 可实施替代）

- **`PRECOND-TAB3-PAGE-RENDER`（承 `T-B13`/`T-B16`，本轮**上移并收窄**）**：
  页宿主已接出（`[DVBI] selfType=ReaderPageViewer n=1`）、已 `Arrange`（`hostRender=638.4x362.88`）、在 milcore 渲染树里（`从根可达=415`）、页视觉子树有绘制（`draw=DrawingGroup`）—— **但读者页区域没有渲染趟被排**：现取把那条**无关**未处理异常移除后帧完全不动，且 `ArrangeOverride` 内／`Dispatcher.BeginInvoke(Render)` 的 `InvalidateVisual()` 都**不产生重绘**。
  - **可实施替代（下一步，按序）**：
    - **(i)** 在本移植的**失效汇聚点**（`MediaContext` → `HwndTarget.Linux.cs` 的 render pass → `MilConnection_CommitChannel`）给"某子树失效但**没有排帧**"加**只读**读数（现取 `WPF_LINUX_MIL_LOG` 可见 `WgxConnection_SameThreadPresent` 的台账，但没有"失效请求"侧）。**判据可证伪**：若失效请求在、排帧不在 ⇒ 断点在本移植的**排帧调度**；若失效请求本身**没发** ⇒ 断点在 `DocumentPageView`/`ReaderPageViewer` 的失效源。
    - **(ii)** 与 `T-B12` 的 keep/redrive 对拍（现取：本腿该修**零动作**）：给"页宿主读到页视觉"那一刻加**只读逐层**（现取 `[DPH]` 的 `SUB` 只到 `L3`；`TYPES` 已补到 `T5`）。
    - **(iii)** 把"页宿主接上后**必须排一帧**"做成**可撤**接线（本席已建 `WPF_DPV_INVALIDATE` 闸并被**两版**否证 ⇒ 说明"直接失效"这一支不够，`(i)` 才能定出正确的落点）。
- **`PRECOND-WIC-RTB`（本席新立，已具名到件:行）**：本移植**没有 WIC 离屏渲染目标** ⇒ `MILUnknown.QueryInterface(handle, IID_IWICBitmapSource)` 对 `RenderTargetBitmap` 的位图源句柄答 `E_HANDLE` ⇒ `DocumentPageView.DuplicateVisual()` 抛 `COMException`（上游只 `catch(System.OverflowException)`）。
  - **可实施替代**：在 `src/WpfGfx.Linux/Interop/MilNative.Misc.cs:175`（`MILQueryInterface`）让 `MilExternalHandleBridge.QueryInterface` 认 **`MILRenderTargetBitmap.GetBitmap` 出来的那个句柄**。**⚠️ 该件不在本任务写域 ⇒ 本条只作具名前置，不实施。**

### 7.3 `NOINFO`（具名）

- **`NOINFO-TB17-INVALIDATE-POINT`**：`ArrangeOverride` 末尾的 `InvalidateVisual()` 与 `Dispatcher.BeginInvoke(Render, InvalidateVisual)` **都不产生重绘**；本侧仍无直读面判"失效请求有没有真的发出去"（⇒ `7.2(i)`）。
- **`NOINFO-TB17-DEMO-VARIANCE`**：hc demo 的帧**不是** `(产物, env, 序)` 的纯函数 —— 现取同一产物同一 env 的 `1,2,3` 序里，**2/3 趟** `tab1=c22457cf663453dd`、**1 趟** `tab1=d7126edbe1baa112`（`colors 1039↔1047`，只差一处悬停/选中态）。⇒ **不回归判据只采"同腿对照"**（同腿 `tab1` vs 同腿 `tab3`），**不**跨趟比 `sha16` 绝对值。
- **`NOINFO-TB17-EHANDLE#1-STACK`**：`FirstChanceException` 的**第 1 次**命中在那一趟只捕到抛点一帧（`#2` 才有调用点链）；原因是首次异常的 `StackTrace` 在该时机尚未铺满（**如实记**，未做进一步归因）。
- **`NOINFO-TB16-TAB2-FORM`（承接，本席未解）**：`T-B15` 就记过"题面点名的 `tab2=ee13c717…` 在本代树上复现不出"。本席现取 `tab2` 的**开工现值**＝**主题关 3,2,1 序 `fae93ea5ed7a2f30`**（`colors=551`／文档区 121／具名 `0/0/0/0`），本轮**未改**它（`fixOff321b` 与 `base321b` 逐字节同）。

---

## §8 边界 · 收净 · 自证

1. **写域（现取 `git status --porcelain`）**：
   ```
    M build/PresentationFramework.Linux/reapply-patches.py        ← 生成器（新增 3 块：TYPES／DPV_CLIP／DPV_RTB／DPV_INVALIDATE／EHANDLE_PROBE）
    M build/PresentationFramework.Linux/DocumentPageView.Linux.cs ← 生成件
    M build/PresentationFramework.Linux/DocumentPageHost.Linux.cs ← 生成件
    M build/PresentationFramework.Linux/PresentationFramework.Linux.csproj ← 生成件（注入补丁 A/B/C）
   ?? build/PresentationFramework.Linux/WpfLinuxEHandleProbe.Linux.cs    ← 生成件（新文件）
   ```
   **无** `upstream/**`、**无** `src/**`、**无** `build/MilBridge/tools/**`、**无** `verify-all.sh`／`build/close-wave.sh`。（`ARTIFACT-SRC-FP.txt`／`.applocal-selftest.log`／`wave-audit.log` 的 `M` 是**开工前就在**的状态。）
2. **副本先行／写前备份**（`cp -p`，取在**任何写之前**）：`~/tb17-work/bak/{reapply-patches.py.orig(199e56cd80ce1aae), DocumentPageHost.Linux.cs.orig(36fa131ef4aef134), PresentationFramework.Linux.csproj.orig(c356bf87bd492c38)}`。
3. **app-local**：**六件与仓内权威件逐件一致**（现取 `libwpfwin32.so=5f9ed647c68197ae`／`wpfgfx_cor3.so=a7a0f884b704ca96`／`PresentationCore.dll=eb3f61e282265518`／`PresentationFramework.dll=c7732cc5b97a78ea`／`WindowsBase.dll=05bdde9b5527bfde`／`PresentationUI.dll=69136eecc84aa9f5`）；`PresentationFramework.dll` 的权威位＝**本轮产物**（`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`）。腿内覆盖由 `trap` 在腿末**还原**为仓内权威位。
4. **进程／显示位按 PID 收净**：`:239` 的 `Xvfb`／`xfwm4` **两代**都按 PID 收净（第一代 `3531395/3531399`；末两趟腿重启的 `3555829/3555833` 亦收；现取 `ps` **无任何 `Xvfb`**、`/tmp/.X11-unix/X239` 已消失）；41 趟腿的 `HandyControlDemo` 全部按 PID 收（`APP_RC=143`＝本席 `kill`；现取 `HandyControlDemo` 进程 **0**）。另有一个 `xfwm4(2617727)` **不是本席**（开工前已在），**未动**。
5. **构建**：`dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -c Release -m:1`（**0 警告 0 错误**，`held≈20–25 s`；**四次**构建，末次产物 `c7732cc5b97a78ea`）。
6. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑**整趟 `verify-all`。**未** `git add/commit/push`。
7. **纪律自证**：重活走槽（41 趟，全部 `ACQUIRED…RELEASED rc=0`）；显示位只用空闲 `:239`；`temp+rename`（生成器 `_write_atomic`，本载体亦如此落盘）；**报数一律现取**（纪律 40）；**接线可撤**（三个候选各一个 env：`WPF_PAGEVIEW_ONSCREEN`／`WPF_DPV_CLIPTOBOUNDS`／`WPF_DPV_RTB_FALLBACK`，另两个只读闸 `WPF_PAGEVIEW_TYPES`／`WPF_EHANDLE_PROBE`）；**仪器不扰动**（现取开/关两腿帧逐字节同）；**未伪造几何／台账**；**未假成功**（判据不成立即记不成立，并给具名前置 ＋ 可实施替代）。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hctab3b-impl-report.md | sha256sum | cut -c1-16`）＝ **`4ff76b78a592f29c`**（本行下方无内容，取该行之前全文的哈希）。

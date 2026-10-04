# P1-hcflowdoc6 报告 —— `T-B13` · `PRECOND-TAB3-PAGE-HOST`（tab3「查看器」空白）—— **定出页宿主 ＋ 接线（`P8`）＋ 判据不成立（如实划界 ＋ 具名前置）**

> 任务：`build/MilBridge/tasks-tail2/T-B13.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T02:4x–03:0x+0800`（各格另注；**所有数值现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=b5110383a95c99b1c086dbcd3dbd9a2687e05ec5`（现取）。
> **未改** `src/WpfGfx.Linux.Native/**`（现取 `git status` 无 native 项）；**未碰** `upstream/**`（只读）。
> 权威件（现取）：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`5e0d7b807c2fc220`**（＝`T-B12` 在册值）、`exports=846`；
>   开工时仓内（`HEAD` 侧）托管件 `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` = **`05bba02601526380`**（现取）。
> 托管件（**本轮新产物**）：`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` = **`1ddedabb2b033b9f`**（现取）。
> 装置：私有 `Xvfb :239 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §8）；应用 ＝ 仓外 hc demo
>   （`$APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，`DOTNET` 走 `$HOME/.dotnet`）。
>   **未占** `:10`／`:231`／`:236`／`:237`／`:238`；所有腿只在空闲 `:239` 上、**只按 PID 收净**。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① tab3 的页宿主「是哪一个／哪条路径」（现取）** | `tab3` ＝ hc demo 的**「流文档查看器」** ＝ `FlowDocumentReader`。它的内容宿主＝内部 **`ReaderPageViewer`**（`MS/Internal/documents/IFlowDocumentViewer.cs:452`：`internal class ReaderPageViewer : FlowDocumentPageViewer`），由 `FlowDocumentReader.GetViewerFromMode` 创建（`System/Windows/Controls/FlowDocumentReader.cs:1150-1156`）；而它**唯一**的**页宿主**＝**该查看器样式模板里的 `DocumentPageView`**，其样式 ＝ `ComponentResourceKey(typeof(PresentationUIStyleResources), "PUIPageViewStyleKey")`（键定义 `FlowDocumentReader.cs:2043-2052`），**唯一**出处＝ PresentationUI 的主题字典（`upstream/wpf/.../PresentationUI/Themes/Generic.xaml:8675-8699`，模板锚 `<DocumentPageView x:Uid="DocumentPageView_2" PageNumber="0" DocumentViewerBase.IsMasterPage="True" ClipToBounds="True"/>`）。 |
| **①′ 真断点（现取）** | 本移植的 PresentationUI 是**替身**（`build/CycleStub.PresentationUI.Linux`，**无** `Themes/`，`find … -iname '*.xaml' -o -iname Themes` **空**）⇒ `PUIPageViewStyleKey` **解析为空**；而 `Style` 已被**本地设值**（`SetResourceReference`）⇒ 连类型隐式样式也被绕过 ⇒ `ReaderPageViewer` **没有 `ControlTemplate`** ⇒ 它**从不构造 `DocumentPageView`** ⇒ 分页出来的 `DocumentPage.Visual` **没有宿主**去读 ⇒「查看器」区**空白**。**现取**：基线腿 `[DPV] site=Ctor` 全趟 **1 次**（tab2 那个）；`[DVBI]` **只有** `selfType=FlowDocumentPageViewer n=1`，**没有** `ReaderPageViewer` 的任何一行。 |
| **② 修（`P8`，生成件 `temp+rename`）** | 把那一行换成 `MS.Internal.Documents.WpfLinuxReaderPageHost.ApplyPageViewerStyle(_pageViewer, PageViewStyleKey)`：**先只读查该键**（查到⇒照旧设资源引用＝逐字回上游；查不到⇒②本控件类型的**隐式样式**；再无⇒③补一份与上游**等价**的模板）。闸 `WPF_READER_PAGEHOST`（**缺省关**，`=1` 才开；理由见下）。生成器重跑 == 现盘（§2.3 幂等）。 |
| **②′ 接线**确实把页宿主**接出来了**（现取）** | `[READERHOST] site=ApplyViewerStyle viewerType=ReaderPageViewer key=PUIPageViewStyleKey found=0 fallback=implicit` ／ `[READERHOST] site=Attach viewerType=ReaderPageViewer contentHostType=Border` ／ `[DPV] site=Ctor id=0x2fd77ef`（**多出第二个** `DocumentPageView`）／ `[DVBI] site=GetPageViews selfType=ReaderPageViewer n=1` ／ `[DPH] site=Attach host=0x11464f pv=0x1abfc89 … pvContent=0,0,636.48,329.28`。 |
| **③ 判据（帧面）** | **不成立**：同一产物 `1ddedabb2b033b9f`，只差一个 env：`tab3` 帧 **`0c51d1ad6fa46543`（562 色／文档区 148／具名色 0）→ `d760eaaf48c7fd60`（562 色／文档区 **154**／**具名色 0**）**；**反极性**（撤修＝闸缺省关）**逐字节回 `0c51d1ad6fa46543`／148／0**。⇒ **色数没回升、具名色没出现**。**另**：闸开腿**新增一条** `[HC-UNHANDLED] COMException … E_HANDLE`（基线腿无）⇒ 接线**不是终点**。 |
| **③′ 关键排除（现取）** | **不是"模板形状"的问题**：**第一版**（键→**等价模板**，产物 `4cc831c4b80e28cf`）给 `tab3` 帧 `71a93980be1f49a6`；**末版**（键→**隐式样式**，产物 `1ddedabb2b033b9f`）给 `d760eaaf48c7fd60` —— **两份不同的模板都改了帧、都不出内容**；且闸开腿**渲染遍历确已走到**该页宿主（`[PAGEVIEW] site=DPV.GetVisualChild self=0x2fd77ef selfRender=636.48x325.44 selfVis=1`）⇒ 页宿主**已在渲染树里**、**页视觉有真内容**（`L3:0xc41b5,k=2,b=106.983,6.983,126.033,36.033,c=106.983,6.983,126.033,36.033`）**却仍未上屏**。 |
| **④ 门禁（现取）** | `nm==exports`（**846==846**，`diff` 空）｜`PTSGAP=PASS so16=5e0d7b807c2fc220 exports=846`｜`PTS_GUARD=PASS legs=2/2`｜`PTS_COLORANCHOR=PASS k=24 hits=3`（**未回退**）｜`DEFREG=PASS declared=225 route_ids=225`｜`REPORTID=PASS files=360 ids=2265 declared=225`（§5） |
| **⑤ 症状门（成对）** | `magenta=0`／`Unrecoverable system error=0`／`FORMATLINE-LINE=114`／`alive=yes`／`app_rc=143`；`[HC-UNHANDLED]`：缺省关 **3** ／ 闸开 **4**（新增＝`E_HANDLE`，§6） |
| **⑥ 边界（未违）** | **仓内只改** `build/PresentationFramework.Linux/**`（生成器 ＋ 生成件 ＋ csproj ＋ 新建件）；**未碰** `upstream/**`／仓外 hc 工程／`verify-all.sh`／`close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）；**未跑整趟 `verify-all`**；**未改 native 任何件**；显示位与进程**按 PID 收净**；app-local 五件已 `cp -p` 复原（`PresentationFramework.dll=05bba02601526380` ＝ 开工时仓内权威件） |

**一句话**：`tab3`（「流文档查看器」）的**页宿主**是**内部 `ReaderPageViewer`（`FlowDocumentPageViewer` 子类）样式模板里的 `DocumentPageView`**，而这份样式在本移植里**指向一个不存在的资源**（`PUIPageViewStyleKey` 只在 PresentationUI 主题字典里，本侧 PresentationUI 是替身）⇒ **页宿主从不被构造**；本席按 `T-B12` 同范式补了"先查资源、缺则补隐式样式／等价模板"的接线，**现取它真的把页宿主接出来了**（`[DVBI] selfType=ReaderPageViewer n=0→1`），**但帧面不绿**（`tab3` 562／文档区 148→154／具名色 0）且**新增一条 `E_HANDLE`** ⇒ **本条接线不是终点**，如实划界为 `PRECOND-TAB3-PAGE-RENDER`（页宿主到位后页面仍不上屏），接线**默认关**（`=1` 才开，反极性逐字节可回）。

---

## §1 ① tab3 的页宿主**是哪一个类型／哪条路径**（件:行 ＋ 现取）

### 1.1 被侦察的现场（现取，两个"干净 3 形态"腿：`t13def5`＝缺省关；`t13pg4`＝闸开）

```
（缺省关）[DPV] site=Ctor id=0x1fc799f                       ← 全趟**只有 1 个** DocumentPageView（tab2 那个）
          [DVBI] site=GetPageViews self=0x1e0469d selfType=FlowDocumentPageViewer n=1
          （**没有任何** ReaderPageViewer 行）
（闸开）  [READERHOST] site=ApplyViewerStyle viewerType=ReaderPageViewer key=PUIPageViewStyleKey found=0 fallback=implicit
          [READERHOST] site=Attach viewerType=ReaderPageViewer viewer=0x640ced contentHostType=Border
          [DPV] site=Ctor id=0x2fd77ef                      ← **第二个** DocumentPageView（tab3 的页宿主）
          [DVBI] site=GetPageViews self=0x640ced selfType=ReaderPageViewer n=1
          [DPH] site=Attach host=0x11464f pv=0x1abfc89 mode=container pvContent=0,0,636.48,329.28 pvKids=1 …
```

### 1.2 页宿主的**唯一**路径（件:行 ＋ 内容锚）

| 跳 | 件:行（现取） | 内容锚原文 | 作用 |
|---|---|---|---|
| 甲 | `upstream/wpf/.../System/Windows/Controls/FlowDocumentReader.cs:82-102` | `_contentHost = GetTemplateChild(_contentHostTemplateName) as Decorator;` … `SwitchViewingModeCore(ViewingMode);` | 套用模板后**只有** `PART_ContentHost` 非空才去建内容查看器 |
| 乙 | `…/FlowDocumentReader.cs:933-939` | `viewer = GetViewerFromMode(viewingMode);` … `_contentHost.Child = feViewer;` | 把查看器**挂进** `PART_ContentHost`（hc 模板里该件是 `Border`——`Decorator` 子类，现取 `contentHostType=Border`） |
| 丙 | `…/FlowDocumentReader.cs:1150-1156` | `_pageViewer = new ReaderPageViewer();` ／ `_pageViewer.SetResourceReference(StyleProperty, PageViewStyleKey);` ／ `_pageViewer.Name = "PageViewer";` | 「查看器」模式的内容宿主＝**`ReaderPageViewer`**，且**显式**给它一个 `Style`（**这就是断点**） |
| 丁 | `…/MS/Internal/documents/IFlowDocumentViewer.cs:452` | `internal class ReaderPageViewer : FlowDocumentPageViewer, IFlowDocumentViewer` | 它**就是** `FlowDocumentPageViewer` 子类（tab2 那个控件是它的公开兄弟） |
| 戊 | `…/FlowDocumentReader.cs:2043-2052` | `_pageViewStyleKey = new ComponentResourceKey(typeof(PresentationUIStyleResources), "PUIPageViewStyleKey");` | 该 `Style` 的键——**跨程序集**（`PresentationUIStyleResources` ∈ PresentationUI） |
| 己 | `upstream/wpf/.../PresentationUI/Themes/Generic.xaml:8675-8699` | `<Style x:Key="{ComponentResourceKey TypeInTargetAssembly={x:Type ui:PresentationUIStyleResources}, ResourceId=PUIPageViewStyleKey}">` … `<DocumentPageView x:Uid="DocumentPageView_2" PageNumber="0" DocumentViewerBase.IsMasterPage="True" ClipToBounds="True"/>` | **本移植里该件的唯一页宿主出处**（模板里那一个 `DocumentPageView`） |
| 庚 | `…/Controls/Primitives/DocumentViewerBase.cs:420-443`（＋`FindDocumentPageViews` `:892-927`） | `FindDocumentPageViews(this, pageViewList);` … `if (fe.TemplatedParent != null) { if (fe is DocumentPageView) { pageViews.Add(fe as DocumentPageView); } …` | 页宿主**只能**从"模板实例"里被找到 ⇒ **没有模板就是 0 个页宿主** |

### 1.3 为什么本移植里页宿主**从不被构造**（现取，非推测）

- **替身侧**：`build/CycleStub.PresentationUI.Linux/` 的目录清单＝`bin/`／`CycleStub.PresentationUI.Linux.csproj`／`FindToolBar.ApiSubset.cs`／`obj/` —— **没有** `Themes/`、**没有**任何 `.xaml`（现取 `find … -iname '*.xaml' -o -iname Themes` **空**）。
- 该替身 .csproj 自述（内容锚）：`本替身**就是**当前运行期的 PresentationUI（未移植真件）`。
- ⇒ 键 `PUIPageViewStyleKey` **解析为空**；`SetResourceReference` 把 `Style` **本地设值**（即便解析为空也占住"本地值"）⇒ 类型隐式样式被绕过 ⇒ `ReaderPageViewer` **无 `ControlTemplate`** ⇒ `DocumentViewerBase.OnApplyTemplate→GetPageViewsCollection` **不会被走到**（现取：缺省关腿上 `[DVBI]` **完全没有** `ReaderPageViewer` 那一行）⇒ 页宿主 **0 个**。
- **同趟对照（同一份文档、同一 `.so`）**：tab2（hc 的**显式** `FlowDocumentPageViewer`）走**隐式样式**（app 提供，模板里含 `DocumentPageView`）⇒ 有页宿主（`[DVBI] … selfType=FlowDocumentPageViewer n=1`）⇒ 帧面**有内容**（`GhostWhite=1334 Beige=99 DarkGreen=3 LightGoldenrodYellow=667`）。**差不在"查看器"这个控件，只在"谁给它模板"**。

---

## §2 ② 修（`P8`）：把页宿主**接出来** ＋ 幂等 ＋ 闸（缺省关）

### 2.1 生成器（`build/PresentationFramework.Linux/reapply-patches.py`）新增补丁族 `T-B13`

| 件:行（生成器内，现取） | 产物 | 作用 |
|---|---|---|
| `FDR_UP`／`FDR_EDITS`（`E1`＋`E2`） | **新建** `FlowDocumentReader.Linux.cs` | `E1`＝把丙那一行换成"先查资源"；`E2`＝在乙之后加一行**只读台账** |
| `DVBI_UP`／`DVBI_EDITS`（`E1`） | **新建** `DocumentViewerBase.Linux.cs` | 在 `GetPageViewsCollection` 出参前加**只读** `[DVBI]`（判决"这个查看器到底收到几个页宿主"） |
| `READERPAGE_PROBE_FILE`／`READERPAGE_PROBE_TEXT` | **新建** `WpfLinuxReaderPageHost.Linux.cs` | 闸 `WpfLinuxReaderPageHost.Enabled` ＋ 三级回退 ＋ 等价模板 ＋ `[READERHOST]` 台账 |
| `DPH_TAIL_REPL`（`T-B13` 增量） | `DocumentPageHost.Linux.cs` | 渲染遍历读数**按元素各记一份**（不再吃 `TraceMax` 的共享额度 —— 否则后面的页宿主读数会被吞，**本轮第一次现取即栽在这里**）；并新增 `ReportPageViews`／`TypeName` |
| `PATCH_C`（`ItemGroup` 内） | `PresentationFramework.Linux.csproj` | `Remove` 上游 `FlowDocumentReader.cs`／`DocumentViewerBase.cs`，`Include` 三个新建件 |

### 2.2 生成件逐条（件:行 ＋ 内容锚，现取）

```
FlowDocumentReader.Linux.cs:1169-1172（`E1`）
        _pageViewer = new ReaderPageViewer();
        // `T-B13`（`PRECOND-TAB3-PAGE-HOST`）：本移植的 PresentationUI 是替身（无 Themes/Generic.xaml）
        //   ⇒ `PUIPageViewStyleKey` 解析为空 ⇒ 页宿主（模板里的 `DocumentPageView`）**从不存在**。
        //   改为「先只读查资源：查到＝照旧；查不到＝补等价模板」。见 `WpfLinuxReaderPageHost` 头注。
        MS.Internal.Documents.WpfLinuxReaderPageHost.ApplyPageViewerStyle(_pageViewer, PageViewStyleKey);

FlowDocumentReader.Linux.cs:952-955（`E2`）
        _contentHost.Child = feViewer;
        AttachViewer(viewer);
        // `T-B13`：只读台账 —— 已接上／内容宿主类型（判"查看器到底有没有接上内容宿主"）
        MS.Internal.Documents.WpfLinuxReaderPageHost.ReportAttached(feViewer, _contentHost);

DocumentViewerBase.Linux.cs:454-456（`E1`）
        // `T-B13`：只读台账 —— 这个查看器到底收到几个页宿主（判决 tab3「页宿主是谁」）
        MS.Internal.Documents.WpfLinuxPageViewProbe.ReportPageViews(this, pageViewList.Count);
        changed = true;
```

`WpfLinuxReaderPageHost.Linux.cs`（新建，现取）三级回退逐条：

```
internal static void ApplyPageViewerStyle(FrameworkElement viewer, ResourceKey key)
{
    if (!Enabled) { viewer.SetResourceReference(FrameworkElement.StyleProperty, key); return; }   // 逐字回上游
    object found = viewer.TryFindResource(key);                 // ① 只读查「上游那个键」
    if (found is Style) { viewer.SetResourceReference(…, key); return; }                        //  查到 ⇒ 逐字回上游
    Style implicitStyle = viewer.TryFindResource(typeof(FlowDocumentPageViewer)) as Style;      // ② 隐式样式（app 提供）
    if (implicitStyle != null) { viewer.Style = implicitStyle; return; }                        //    ＝"不给本地值"的等价物
    viewer.Style = Fallback;                                                                    // ③ 与上游等价的模板
}
```

- **③ 等价模板**：`AdornerDecorator(ClipToBounds)` → `Border` → `DocumentPageView(ClipToBounds, IsMasterPage=True)` —— 与己处上游模板**同形**（件:行现取 `WpfLinuxReaderPageHost.Linux.cs` 内 `FrameworkElementFactory dpv = new FrameworkElementFactory(typeof(DocumentPageView));`）。
- **零动作条件**：闸关 ⇒ **整块不发生**（那一行逐字回上游 `SetResourceReference`）。
- **同源**：只动"给不给 `Style`"，**不复制视觉、不改几何、不碰 native、不删／不放宽任何 `Invariant.Assert`**。

### 2.3 幂等（生成器重跑 == 现盘）

```
$ for f in *.Linux.cs PresentationFramework.Linux.csproj reapply-patches.py; do sha256sum "$f"; done > g5
$ python3 build/PresentationFramework.Linux/reapply-patches.py ; … > g6
$ diff g5 g6  ⇒  空
IDEMPOTENT=OK
```

现取关键件 `sha16`：`reapply-patches.py=e98a615ff5c376bc`／`FlowDocumentReader.Linux.cs=ba6ac9596b58f4df`／`DocumentViewerBase.Linux.cs=70e395afa5348418`／`WpfLinuxReaderPageHost.Linux.cs=64fd9a7d67dcb22f`／`DocumentPageHost.Linux.cs=36fa131ef4aef134`／`PresentationFramework.Linux.csproj=1b537b65f3e25401`／`bin/Release/PresentationFramework.dll=1ddedabb2b033b9f`。
`FlowDocumentReader.Linux.cs` 与上游 `diff` ⇒ **恰 2 个 hunk**；`DocumentViewerBase.Linux.cs` ⇒ **恰 1 个 hunk**。

### 2.4 ⚠️ 闸**缺省关**（如实记）

本条接线**已现取**它把页宿主**接出来了**，但 **`tab3` 帧面不绿**（§3.4）且**新增一条 `E_HANDLE`**（§6）⇒ **不默认启用**，不把"接出来了却仍不上屏"当成"修好了"。与 `T-B11`（`WPF_PAGEVIEW_ONSCREEN` 被证伪后改成默认关）同一处置。`WPF_READER_PAGEHOST=1` 即开（可复现）。

---

## §3 ③ 真跑：成对读数 ＋ 反极性

### 3.1 腿表（现取；同一装置 `:239`）

| 腿 | 托管件 `sha16` | `WPF_READER_PAGEHOST` | `tab1` 帧 | `tab2` 帧 | **`tab3` 帧** | `[HC-UNHANDLED]` |
|---|---|---|---|---|---|---|
| `t13base` | `05bba02601526380`（开工时仓内权威件） | —（无该接线） | `b440033da8b2a9e6` | `ee13c71712d2777c` | **`0c51d1ad6fa46543`** | 3 |
| **`t13def5`** | **`1ddedabb2b033b9f`** | **缺省（关）** | `b440033da8b2a9e6` | `ee13c71712d2777c` | **`0c51d1ad6fa46543`** | 3 |
| **`t13pg4`** | **`1ddedabb2b033b9f`** | **`=1`（开）** | `b440033da8b2a9e6` | `ee13c71712d2777c` | **`d760eaaf48c7fd60`** | **4** |
| （同源复现）`t13def2`／`t13pg1` | `71924f69d6f6f102`（与末版仅探针预算不同） | 缺省／`=1` | `b440033d…` | `ee13c717…` | **`0c51d1ad…`／`d760eaaf…`** | 3／4 |
| （**第一版**）`t13on2` | `4cc831c4b80e28cf`（键→**等价模板**） | 缺省（当时默认开） | `b440033d…` | `ee13c717…` | **`71a93980be1f49a6`** | 4 |
| （**跑次形态**）`t13def3`／`t13off` | `1ddedabb2b033b9f` | 缺省 | **`ec40be7a64c60d03`** | **`5860e83f8557905d`** | **`40dbbd1703f3e360`** | 3 |

### 3.2 **成对读数**（`docink.py`：文档区 `x∈[250,800] ∧ y∈[100,600]`；整屏色数）

| 帧 | `t13def5`（缺省＝关） | **`t13pg4`（开）** |
|---|---|---|
| `tab1` | 整屏 `colors=1078`；文档区 `763`；`GhostWhite=9813 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 LightGray=3712` | **同（逐格同）** |
| `tab2` | `colors=841`；文档区 `503`；`GhostWhite=1334 Beige=99 DarkGreen=3 LightGoldenrodYellow=667 LightGray=449` | **同（逐格同）** |
| **`tab3`** | `colors=562`；文档区 **`148`**；**具名色 0/0/0/0** | `colors=562`；文档区 **`154`**；**具名色 0/0/0/0** |

### 3.3 **反极性**（同一产物 `1ddedabb2b033b9f`，只差一个 env）

| 面 | `t13pg4`（`WPF_READER_PAGEHOST=1`） | `t13def5`（缺省＝关） | 判 |
|---|---|---|---|
| `[READERHOST]`／`[DVBI]` | **3 行**：`ApplyViewerStyle … found=0 fallback=implicit`／`Attach … contentHostType=Border`／`GetPageViews selfType=ReaderPageViewer n=1` | **0 行**（整块不发生） | **接线真进了两形态** |
| `[DPV] site=Ctor` | **2 次**（`0x1fc799f` tab2 ＋ `0x2fd77ef` **tab3**） | **1 次**（`0x1fc799f`） | **页宿主 0→1** |
| **`tab3` 帧 `sha16`** | **`d760eaaf48c7fd60`** | **`0c51d1ad6fa46543`** | **帧面变／回** |
| `tab3` 文档区色数 | `154` | `148` | 只差"页面边框 1–2px 抗锯齿"（`imgdiff` 现取：差异 **1992 px**，全落在 `x∈[303,797] ∧ y∈[146,519]`，且**全是灰白过渡**，`GhostWhite/Beige/DarkGreen/LightGoldenrodYellow` **全 0**） |
| `tab1`／`tab2` 帧 | `b440033da8b2a9e6`／`ee13c71712d2777c` | **逐字节相同** | **零回退** |

### 3.4 **判据裁定（不成立，如实记）**

- 判据要的是"**色数回升 ＋ 具名色出现 ＋ 帧 `sha16` 变**"。现取：帧 `sha16` **变了**；**色数没回升**（562→562）；**具名色没出现**（0→0）。⇒ **①③ 不成立**，**不得**记成修好。
- **反极性成立**（撤修 ⇒ `tab3` **逐字节回** `0c51d1ad6fa46543`／148／具名色 0）。
- **闸开腿的新现场（现取，判决用）**：
  ```
  [DPV] site=HostArranged view=0x2fd77ef host=0x11464f hostRender=636.48x329.28 hostAt=3.84,0 hostXf=295.68,141.12,0.988,0.988 hostKids=1 page=0x3bdc6b9
  [DPH] site=Attach host=0x11464f pv=0x1abfc89 mode=container pvContent=0,0,636.48,329.28 pvBound=-1.621,0,638.101,329.28 hostPS=0x28c5f3 pvPS=0x28c5f3 pvDepth=35
        SUB=L0:0x1abfc89,k=1,b=-1.621,0,638.101,329.28,c=0,0,636.48,329.28
          | L1:0x1eeb5f,k=2,b=-1.621,1.021,601.443,279.043,c=empty
          | L2:0x1164657,k=1,… | L3:0x158c4d1,k=1,…
          | L2:0x1c87914,k=2,b=106.983,6.983,371.033,86.033,c=empty
          | L3:0xc41b5,k=2,b=106.983,6.983,126.033,36.033,c=106.983,6.983,126.033,36.033   ← **真绘制内容**
          | L3:0x2e71f3c,k=2,b=206.983,6.983,271.033,86.033,c=206.983,6.983,271.033,86.033  ← **真绘制内容**
  [PAGEVIEW] site=DPV.GetVisualChild self=0x2fd77ef idx=0 selfRender=636.48x325.44 selfVis=1 child=0x11464f childRender=636.48x329.28   ×N
  ```
  ⇒ 页宿主**已在渲染遍历里**（`selfVis=1`）、**尺寸／父子链正确**、**接到呈现源**（`pvPS=0x28c5f3`）、**页视觉有真内容**（`c=106.983,…`）—— **却不上屏**。

> **可比性（纪律 31/32）**：`tab` 帧**跑次相关**。现取两种形态：**A 形态**（`tab1=b440033da8b2a9e6`，`tab2` 有内容 `ee13c71712d2777c`）与 **B 形态**（`tab1=ec40be7a64c60d03`／`tab2=5860e83f8557905d`／`tab3=40dbbd1703f3e360`），另加"风暴形态"（`[HC-UNHANDLED] ∈ {460,486}`，§6）。**本报告全部成对读数取自 A 形态**（`t13base`／`t13def2`／`t13def4`／`t13def5`／`t13pg1`／`t13pg2`／`t13pg3`／`t13pg4` 全为 A 形态；ON 态 `tab3=d760eaaf48c7fd60` **三次独立复现**）；B 形态**只用于记形态本身**（`NOINFO-TB13-MODE`）。

---

## §4 ④ 断点归属 · `T-B13` 的**合法终点** · 具名前置 · 可实施替代

### 4.1 本轮**已逐条排除**的（都真跑过，见 §3）

| 假设 | 现取反证 |
|---|---|
| "查看器**没造**内容宿主" | 现取 `[READERHOST] site=Attach … contentHostType=Border` ⇒ `PART_ContentHost` 在、查看器**已挂上** |
| "页宿主**造不出来**" | **接线后可造**：`[DPV] site=Ctor id=0x2fd77ef` ＋ `[DVBI] selfType=ReaderPageViewer n=1` |
| "模板**形状**不对（少了/多了什么）" | **两种模板**（上游等价件／app 隐式件）**都**把帧改了（`71a93980`／`d760eaaf`），**都**不出内容 ⇒ 不是形状问题 |
| "页宿主**不在渲染树**" | `[PAGEVIEW] DPV.GetVisualChild self=0x2fd77ef selfVis=1 selfRender=636.48x325.44` |
| "页视觉**是空的**" | `pvContent=0,0,636.48,329.28`，且叶子 `c=106.983,…` ⇒ **有真绘制内容** |
| "位置／尺寸**摆错**" | `hostXf=295.68,141.12,0.988,0.988` ⇒ 页落在窗口 `(295,141)` 起、`628x325` ⇒ **可见**（窗口 `≈800x576`） |

### 4.2 剩下的（**如实划界**）

- **真断点（本席现取，上移一格）＝ `PRECOND-TAB3-PAGE-RENDER`**：**页宿主到位、页视觉有内容、且在渲染树里，页面内容仍不上屏**；并且**同刻新增一条 `COMException … E_HANDLE`**（基线腿无）。
  - 现取首发：`[HC-UNHANDLED] #3 COMException: The handle is invalid.` ／ `(0x80070006 (E_HANDLE)) ｜ 首帧 at MS.Internal.HRESULT.Check(Int32 hr)`（`t13pg4:9477`，位置紧贴该页宿主的 `HostArranged`），**在缺省关腿上不存在**。
  - ⇒ 与 `T-B12` 的 `PRECOND-PAGE-SCOPED-PARA-CLIENT`（native 侧跨页复用同一 `BaseParaClient.Visual`）**同族但不同格**：这里是"**页宿主已存在**之后"才暴露的一格。
- **不许**把它记成"修好了"：判据三条**两条不满足**，且**引入新异常**。

### 4.3 具名前置（本席新立，供后手）

- **`PRECOND-TAB3-PAGE-RENDER`**：使**已接上的** `ReaderPageViewer` 页宿主**真的把分页页内容画上屏**（现取：宿主在、内容有、渲染遍历到、**不上屏**，且伴 `E_HANDLE`）。
  *可实施替代（下一步，低成本，按序）*：
  - **(i) 先给 `E_HANDLE` 具名出处**：把 `[HC-UNHANDLED]` 的"首帧"从 `MS.Internal.HRESULT.Check` **推深一层**（在 `PresentationCore`/`WindowsBase` 侧给 `HRESULT.Check` 的**调用点**打一条**只读**行：谁在什么入口、`hr` 多少）——即可判"是**渲染合成**抛的"还是"**聚焦/选区**抛的"（现取：异常紧贴 `mouseUp` 与 `HostArranged`，两者都可能）。**判据可证伪**：若出处＝绘制合成 ⇒ 断点在渲染面；若出处＝TextEditor/选区 ⇒ 断点在输入面（而页面是被"上一步抛异常"打断的）。
  - **(ii) 与 `T-B12` 的 keep/redrive 对拍**：现取该页 `trackVisual`（`L3:0x158c4d1,k=1`）**非空** ⇒ `T-B12` 的 `RedrivePageVisualsForDisplay` **按其零动作条件正确地没动手**（全趟 `[PAGEVIS] site=PTSP.RedrivePageVisuals` 只 1 行＝tab2 那个）。**下一步**：给"页宿主读到页视觉"那一刻再加一条**只读**行，报 `trackVisual` 子树的**逐层**（现取只到 `L3`，是探针深度所限，**不是**"L4 为空"的结论）。
- **`PRECOND-TAB3-OWN-VIEWER-STYLE`**（承本席 ①）：本移植若要根治，**正解是补 PresentationUI 的 `Themes/Generic.xaml`**（把 `PUIPageViewStyleKey`／`PUITwoPageViewStyleKey`／`PUIScrollViewStyleKey` 三条资源补进**真** PresentationUI），而不是在 PF 侧绕——后者是**可实施替代**（本席已给），前者才叫"把缺件补上"。

### 4.4 未做／需往前一层（如实点名）

- **未改** `build/CycleStub.PresentationUI.Linux/**`（**不在本任务写域**）——那才是"补上缺件"的正解位置。
- **未改** `src/WpfGfx.Linux.Native/**` 一字。
- **未**把接线默认打开（§2.4）。

---

## §5 ⑤ 门禁（逐条现取；本席跑的）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| awk '{print $3}' \| sort` vs `src/WpfGfx.Linux.Native/bin/exports.txt` | **846 == 846**，`diff -q` 空 ⇒ `NM_EQ_EXPORTS=PASS` |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5e0d7b807c2fc220 exports=846`**；`PTSGAP_CITED=PASS refs=1 strict=1`；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`；rc=0 |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- direction=in-file phase=realized`**；`PTS_G10_NAME=PASS`；`PTS_N1_GATE=PASS`；`PTS_ENFE=PASS total=0` |
| `PTS_COLORANCHOR` | 同上（`k=24`） | **`PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 min=200 base=全部0`**（**未回退**）；`k=23` `NOINFO(no-anchor-registered-for-k23)` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0`，rc=0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=360 ids=2265 declared=225`**，rc=0（本载体落地**前**现取；落地后 ＋1） |

**未跑**：整趟 `verify-all`（照 `T-B13` ②）；`static-jaws-check.sh`。

---

## §6 ④/⑤ 症状门（成对）

| 症状门 | `t13base`（权威件） | `t13def5`（缺省＝关） | **`t13pg4`（开）** |
|---|---|---|---|
| `magenta` | 0 | 0 | 0 |
| `Unrecoverable system error` | 0 | 0 | 0 |
| `[FORMATLINE-LINE]` | 114 | 114 | 114 |
| `[HC-UNHANDLED]` | 3 | **3** | **4** |
| 其中 `E_HANDLE` | 0 | **0** | **1**（`t13pg4:9477`） |
| `alive`／`app_rc` | yes／143 | yes／143 | yes／143（均**本席按 PID 收**） |
| `LOG_BYTES` | 2 142 029 | 2 113 542 | 2 173 957 |

⚠️ **同族跑次形态（承 `T-B12` `NOINFO-1`／`NOINFO-TB12-MODE`，本席复现）**：另有 `[HC-UNHANDLED] ∈ {460, 486}` 的**风暴形态**（现取 `t13on`=460／`t13def`=486／`t13def3` 的 B 形态），其首发恒为
`PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'`
⇒ **与接线无关**（缺省关腿也会落进该形态：`t13def`=486）；本报告的**开/关对拍全部取自 A 形态的腿**（§3.1）。

---

## §7 具名 `NOINFO`

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-TB13-RENDER` | 页宿主到位、页视觉有内容、渲染遍历到、**仍不上屏** | `t13pg4`：`[PAGEVIEW] selfVis=1`；`pvContent=0,0,636.48,329.28`；`L3:0xc41b5,k=2,…,c=106.983,…`；帧面文档区仍 154／具名色 0 | §4.3(i)：给 `E_HANDLE` 的**调用点**具名出处 |
| `NOINFO-TB13-EHANDLE` | `E_HANDLE` 的**抛出点**（只拿到"首帧 ＝ `HRESULT.Check`"） | `t13pg4:9477`；两版接线（隐式／等价模板）**都**出现 ⇒ 与"模板形状"无关 | 同上 |
| `NOINFO-TB13-MODE` | `tab` 帧**跑次不可复现**（A 形态／B 形态／风暴形态） | 同产物多跑：`tab1 ∈ {b440033d, ec40be7a}`；`tab2 ∈ {ee13c717, 5860e83f, b440033d}`；`[HC-UNHANDLED] ∈ {3,4,460,486}` | 找发射侧非确定性源并固化（本席**只报抽取**） |
| `NOINFO-TB13-DEPTH` | 该页 `trackVisual`（`L3:0x158c4d1,k=1`）**之下**是什么 | 探针 `Sub(...,3)` **只到 L3** | 把页宿主那一份 `SUB` 深度加到 5 的一条**只读**行 |

---

## §8 边界 · 收净 · 自证

1. **写域**：**仓内只改** `build/PresentationFramework.Linux/**`。现取 `git status --porcelain`（本席相关项）：
   ```
    M build/PresentationFramework.Linux/DocumentPageHost.Linux.cs            ← T-B13 探针增量（生成器产）
    M build/PresentationFramework.Linux/PresentationFramework.Linux.csproj   ← T-B13 接线（生成器产）
    M build/PresentationFramework.Linux/reapply-patches.py                   ← T-B13 补丁族
   ?? build/PresentationFramework.Linux/FlowDocumentReader.Linux.cs          ← T-B13 新建（生成器产）
   ?? build/PresentationFramework.Linux/DocumentViewerBase.Linux.cs          ← T-B13 新建（生成器产）
   ?? build/PresentationFramework.Linux/WpfLinuxReaderPageHost.Linux.cs      ← T-B13 新建（生成器产）
   ```
   **无** `src/**`、**无** `upstream/**`、**无** `build/MilBridge/tools/**` 改动。⚠️ **开工时即已存在**的旁生件（**非本席**）：`build/.applocal-selftest.log`／`build/MilBridge/HANDOFF-NEXT.md`／`build/Presentation{Core,Framework}.Linux/ARTIFACT-SRC-FP.txt`／`build/WindowsBase.Linux/ARTIFACT-SRC-FP.txt`／`build/wave-audit.log`（`HEAD=b511038`，**未动**）。
2. **副本先行／写前备份**（`cp -p`，取在**任何腿之前**）：`~/tb13-work/bak/reapply-patches.py.orig`／`PresentationFramework.Linux.csproj.orig`／`PresentationFramework.dll.prebuild`（＝`05bba02601526380`）／`PresentationFramework.dll.applocal.orig`。
3. **仓外私有件（不在仓内）**：`~/tb13-work/{leg.sh,tabs.py,docink.py,imgdiff.py,grid.py,bak/,logs/}`；`leg.sh` 由 `~/tb12-work/leg.sh` **逐字节复制**后**仅改两行**（`tb12-work`→`tb13-work`；`:238`→`:239`，`diff` 现取**仅此两处**）。
4. **重活走槽／收净**：全部腿与全部构建都在 `~/heavy-slot.sh --min-avail 1500 --max-hold 1200…1500` 内（`HEAVYSLOT=ACQUIRED … RELEASED rc=0`）；显示位只用空闲 `:239`（`~/tb13-work/{xvfb,wm}.pid`，**按 PID 收净**，并**同时清掉 `:239` 专属 lock/socket** —— 坑见 `T-B12` §8.6）。现取 `pgrep -af 'Xvfb :239'` 无输出、`pgrep -af HandyControlDemo` 无输出、`/tmp/.X239-lock` 与 `/tmp/.X11-unix/X239` **不存在**。（注：现存的 `xfwm4` PID `2617727` **非本席** —— 属别的显示位，**未动**。）
5. **构建**：`dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -c Release -p:BuildProjectReferences=false -m:1`（**0 警告 0 错误**，`held≈21s`）；产物 `bin/Release/PresentationFramework.dll=1ddedabb2b033b9f`。
6. **app-local 逐件复原（任务点名的硬边界）**：全部腿用 `TB8_PF_SRC` 刷过 app-local 的 `PresentationFramework.dll`，已 `cp -p` **复原** ⇒ 现取五件：`libwpfwin32.so=5e0d7b807c2fc220`／`wpfgfx_cor3.so=a7a0f884b704ca96`／`PresentationCore.dll=8e0234c89b452487`／`PresentationFramework.dll=05bba02601526380`／`WindowsBase.dll=0b54a1e3f9d37ab1`，其中 `PresentationFramework.dll` ＝**开工时仓内（`HEAD` 侧）权威件现读值**。⚠️ 本轮新产物（`1ddedabb…`）**只**留在仓内 `build/…/bin/Release/`（本任务写域），**未**让 app-local 侧与 `HEAD` 侧权威件脱钩。
7. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑整趟 `verify-all`**。**未** `git add/commit/push`。
8. **纪律自证**：重活走槽；显示位只用空闲 `:239`；`temp+rename`（生成器 `_write_atomic`，本载体亦如此落盘）；**报数一律现取**（纪律 40）；**接线可撤**（缺省关；本席已真跑反极性证明缺省态 `tab3` **逐字节回** `0c51d1ad6fa46543`）；`upstream/**` 一字未动；**未伪造几何／台账**；**未假成功**（判据不成立即记不成立，并给出具名前置＋可实施替代）。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hcflowdoc6-impl-report.md | sha256sum | cut -c1-16`）＝ **`f0f16fd6cb63b7b6`**（本行下方无内容，取该行之前全文的哈希）。

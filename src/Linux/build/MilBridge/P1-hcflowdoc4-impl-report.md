# P1-hcflowdoc4 报告 —— `T-B11` 照 `FlowDocumentView` 范式给 `DocumentPageView`／`DocumentPageHost` 补「上屏」接线 —— **实现（判：接线已建并真跑，**被现取证伪**；真断点上移一层＝「分页页视觉**壳内为空**」）**

> 任务：`build/MilBridge/tasks-tail2/T-B11.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T01:2x–02:0x+0800`（各格另注；**所有数值现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=330f9b7`（现取）。
> 权威件：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`5e0d7b807c2fc220`**（现取；＝ `T-B10` 在册值）；`exports=846`。
> 托管件（**本轮新产物**）：`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` = **`4bec142cae144da6`**（现取）；
>   **未改** `src/WpfGfx.Linux.Native/src/win32_pts.c`（现取 **`edaf0bf17ede9bb9`** ＝ `HEAD` 侧值）。
> 装置：私有 `Xvfb :237 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §8）；应用 ＝ 仓外 hc demo
>   （`$APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，`DOTNET` 走 `$HOME/.dotnet`）。
>   **未占 `:10`／`:231`／`:236`**；所有腿只在空闲 `:237` 上、**只按 PID 收净**。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① `FlowDocumentView` 那条**可用**接线（现取）** | **不是**生成器那 10 处编辑，而是**上游原件里**三条同源机制：**(甲) 挂载** `FlowDocumentView.Linux.cs:247-248` `_pageVisual = (PageVisual)_formatter.DocumentPage.Visual; AddVisualChild(_pageVisual);`；**(乙) 显式定位** `:254-256` `_pageVisual.Offset = new Vector(-…HorizontalOffset, -…VerticalOffset);`；**(丙) 同源枚举** `:301-310 GetVisualChild`→`return _pageVisual;` ／ `:367-374 VisualChildrenCount`→`_pageVisual == null ? 0 : 1`。**生成器 10 处编辑（`E1..E10`）里唯一与"内容能不能建出来"相关的是 `E9`（`T-A41` 视口驱动）**；`E2..E8` 是 `PtsUnavailable` 的**降级占位**，与"上屏"无关（§1）。 |
| **② 新接线（`P8`，生成件 `temp+rename`）** | 照 (甲)(丙) 给 `DocumentPageHost` 建**等价挂载**（`DocumentPageHost.Linux.cs:138-142`：`AddVisualChild(_pageVisual)`；`:182-184`：`GetVisualChild`→`return _pageVisual;`），并配 `DisconnectPageVisual` 的同形识别（`:72-77`）。**闸 `WPF_PAGEVIEW_ONSCREEN`（默认关，只有显式 `=1` 才开）**。另加 `[DPV]`／`[DPH]`／`[FDV]` **只读台账**。生成器重跑 == 现盘（§2 幂等）。 |
| **③ 成对读数 ＋ 反极性** | **反极性成对（同一件 `4bec142cae144da6`，只差一个 env）**：`WPF_PAGEVIEW_ONSCREEN=1`（`mode=direct`）vs 默认关（`mode=container`）⇒ **`tab1`／`tab2`／`tab3` 三帧逐字节相同**（`b440033da8b2a9e6`／`1fb95eab89966441`／`0c51d1ad6fa46543`）、文档区色数逐格相同（`tab1=17135/764`、`tab2=1662/125`、`tab3=1679/149`）、具名色 `tab2` 仍 **0/0/0/0**（§3、§5）。⇒ **该绿不绿**：本条接线**不是**断点。 |
| **④ **真断点**（本席现取，上移一层）** | **不是 `DocumentPageView`／`DocumentPageHost` 的挂载线**：现取证明 ① 渲染遍历**确已**走到 `DPV → DPH → 页视觉`（`[PAGEVIEW] site=DPV.GetVisualChild` ＝ `DPH.GetVisualChild`，逐腿 191–212 次，`selfVis=1`、尺寸全对）；② 宿主变换**把页放到可见处**（`[DPV] hostXf=435.84,107.52,0.347,0.347`，页 816×1056×0.347 ≈ 283×367，落在文档区）；③ **身份对拍**：在屏 `DPV` 收到的页视觉 `pv=0x361f531` ＝ `FDG.UpdateVisual pageId=0x3ee7093 pvId=0x361f531` ⇒ **就是被格式化的那一页**。⇒ 真断点 ＝ **那一页视觉的**壳之内为空**：`[DPH] … SUB=L0:0x361f531,k=1,b=0,0,816,1056,c=0,0,816,1056 \| L1:…k=2,b=empty,c=empty \| L2:…k=1,b=empty \| L3:…k=0,b=empty` —— PTS 内容轨**一个叶子视觉都没有**；而同帧 `[FDV] … SUB` 的叶子有真内容（`L3:0x3574d54,k=2,b=106.983,6.983,126.033,36.033,c=106.983,6.983,126.033,36.033`）（§4）。 |
| **⑤ 门禁（现取）** | `nm==exports`（**846==846**，`diff` 空）｜`PTSGAP=PASS`（`so16=5e0d7b807c2fc220 exports=846 tool=54 dead=11 artifact=1 ops=42 impl=42`）｜`PTS_GUARD=PASS legs=2/2`｜`PTS_COLORANCHOR=PASS k=24 hits=3`（**未回退**）｜`DEFREG=PASS declared=225 route_ids=225`｜`REPORTID=PASS files=358 ids=2265 declared=225`（§6） |
| **⑥ 症状门（成对）** | 二十九腿 `alive=yes`／`app_rc=143`（均**本席按 PID 收**）／`magenta=0`／`Unrecoverable system error=0`；`[HC-UNHANDLED]` ∈ {`3`，「≈180–212」形态}（**跑次相关**，见 `NOINFO-1`）；`[FORMATLINE-LINE]` 恒 `114`（§7） |
| **⑦ 边界（未违）** | **仓内只改** `build/PresentationFramework.Linux/**`（生成器 ＋ 生成件 ＋ csproj）；**未碰** `upstream/**`／仓外 hc 工程／`verify-all.sh`／`close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）；**未跑整趟 `verify-all`**；**未改 native 任何件**；显示位与进程**按 PID 收净**；app-local 五件已复原（`PresentationFramework.dll=48daaeb326c4aa8b` ＝ 权威件现读值） |

**一句话**：按 `FlowDocumentView` 的**上游三条**（页视觉对象直接 `AddVisualChild` ＋ 显式定位 ＋ `GetVisualChild`／`VisualChildrenCount` **同源**）给 `DocumentPageHost` 建了等价接线并真跑 ⇒ **帧逐字节不变**（`tab2` 仍 `1fb95eab89966441`／`colors=551`／具名色 0）⇒ **接线被证伪**；本席随即把断点**上移一层并取实**：在屏 `DocumentPageView` 收到的页视觉**壳内为空**（PTS 内容轨 0 叶子视觉），而 `FlowDocumentView` 那一页的叶子有真内容 ⇒ **合法终点（失败）＋ 具名前置 ＋ 可实施替代**，不假成功。

---

## §1 ① `FlowDocumentView` 那条**可用**接线的**逐条现取**（件:行 ＋ 编辑名 ＋ 为何能上屏）

### 1.1 它**实际**靠什么上屏（现取：生成件 vs 上游的 `diff` 逐处）

现取 `diff -u upstream/…/documents/FlowDocumentView.cs`（去掉生成件头 18 行）⇒ **恰 10 个 hunk**，与生成件头部「`E1 ／ … ／ E10`」一致。**"视觉挂载／定位／枚举"三条并不在其中** ⇒ 它们是**上游原件**（现取 `grep -n` 于生成件＝上游同址）：

| # | 件:行（现取） | 内容锚原文 | 它做什么 | 是谁 |
|---|---|---|---|---|
| 甲 | `build/PresentationFramework.Linux/FlowDocumentView.Linux.cs:247-248` | `_pageVisual = (PageVisual)_formatter.DocumentPage.Visual;` ／ `AddVisualChild(_pageVisual);` | 把**页视觉对象本身**接进本控件自己的视觉树（不经内层元素的隐式 `Measure/Arrange`） | **上游原件** |
| 乙 | `…FlowDocumentView.Linux.cs:251-256` | `if (_scrollData != null) { _pageVisual.Offset = new Vector(-_scrollData.HorizontalOffset, -_scrollData.VerticalOffset); }` | 给它**显式定位**（滚动偏移） | **上游原件** |
| 丙 | `…FlowDocumentView.Linux.cs:301-310` ／ `:367-374` | `protected override Visual GetVisualChild(int index) … return _pageVisual;` ／ `protected override int VisualChildrenCount … return _pageVisual == null ? 0 : 1;` | 枚举与甲**同源**（返回**同一个**被 `AddVisualChild` 的对象） | **上游原件** |
| 丁 | `…FlowDocumentView.Linux.cs:262-269` | `else { if (_pageVisual != null) { _textView?.OnPageDisconnected(); RemoveVisualChild(_pageVisual); _pageVisual = null; } … }` | 反向摘除（成对） | **上游原件** |

⇒ **可复用最小集 ＝ 甲＋乙＋丙**（丁是它的成对拆除）。三者的**共同点**：**宿主自己做挂载与定位，且枚举与挂载同源**——**不把"上屏"寄托在内层元素的隐式测量上**。

### 1.2 生成器的 10 处编辑（编辑名 → 作用，**逐条**）

| 编辑名 | 件:行（现取） | 内容锚 | 作用 | 与"上屏"关系 |
|---|---|---|---|---|
| `E1` | `:36-38` | `using System.Globalization;` | 占位文字用 | 无关 |
| `E2` | `:110-141` | `catch (PtsUnavailableException ptsGap)` | `MeasureOverride` 降级占位 | 无关 |
| `E3` | `:195-203` | `if (_ptsUnavailable != null) { return arrangeSize; }` | 降级早退 | 无关 |
| `E4` | `:289-341` | `OnRender` 洋红占位 | 降级可见化 | 无关 |
| `E5` | `:425-431` | `private PtsUnavailableException _ptsUnavailable;` | 视图级闩 | 无关 |
| `E6` | `:449-471` | `internal FlowDocumentPage DocumentPage` 的 try/catch | 第三入口同接 | 无关 |
| `E7` | `:509-521` | `try { EnsureFormatter(); }` | `ArrangeOverride` 同跳 | 无关 |
| `E8` | `:57-58` | `private static readonly Size PtsGapPlaceholderSize = new Size(440.0, 132.0);` | 占位尺寸 | 无关 |
| **`E9`** | `:214-237` | `Rect fsviewViewport = WpfLinuxFsViewDrive.Effective(viewport, safeArrangeSize, _formatter, _pageVisual);` … `_formatter.Arrange(safeArrangeSize, fsviewViewport);` | **`T-A41` 视口驱动**（只动"交给 formatter 的那一个视口"） | **唯一相关：它决定"内容视觉建不建得起来"（`[FSQLL] cLines=1` 由 0 → 非 0）** |
| `E10` | `:826-1001` | `internal static class WpfLinuxFsViewDrive` | `E9` 的载体＋`[FSVIEW]` 台账 | 同上 |
| `E11`（**本轮新加**） | `:250` | `WpfLinuxPageViewProbe.ReportFdv(this, _pageVisual);` | **只读**同位对照（§4 用） | 不改语义（`tab1` 帧逐腿不变，§3） |

### 1.3 现取：`tab1` 的页视觉**在屏**（同帧对照，§4 会与 `tab2` 逐格比）

```
[FDV] site=Attach view=0x18f39c pv=0x2a6fa61 pvParent=0x18f39c viewPS=0x28c5f3 pvPS=0x28c5f3 pvDepth=32
      pvContent=0,0,638.4,2000 pvKids=1 pvXf=257.28,47.04,1,1
      pvChild=c=0xe0907f,kids=2,bounds=-1.621,1.021,601.443,279.043,content=empty
      SUB=L0:0x2a6fa61,k=1,b=-1.621,0,640.021,2000,c=0,0,638.4,2000
        | L1:0xe0907f,k=2,b=-1.621,1.021,601.443,279.043,c=empty
        | L2:0x3e51479,k=1,b=-1.621,1.021,601.443,279.043,c=empty
        | L3:0x30db843,k=1,b=-1.621,1.021,601.443,279.043,c=empty
        | L2:0x37b7a5e,k=2,b=106.983,6.983,371.033,86.033,c=empty
        | L3:0x3574d54,k=2,b=106.983,6.983,126.033,36.033,c=106.983,6.983,126.033,36.033
        | L3:0x211b7f4,k=2,b=206.983,6.983,271.033,86.033,c=206.983,6.983,271.033,86.033
```
⇒ 叶子 `L3` **有真绘制内容**（`c=106.983,…`／`c=206.983,…`）⇒ 上屏帧 `tab1=17135 ink／764 colors／具名色齐`（§3）。

---

## §2 ② 新接线（`P8`）逐条 ＋ 幂等

### 2.1 生成器（`build/PresentationFramework.Linux/reapply-patches.py`）

- **新增补丁族 `T-B11`**（现取）：`DPV_EDITS`（4 处）／`DPH_EDITS`（4 处）／`DPV_UP`／`DPH_UP`；`materialize_derived()` 内新增两行产出（走既有 `_apply_edits` ⇒ **`temp+rename`** 由 `_write_atomic` 保证，见该函数 `os.replace`）；
- **csproj 接线（`PATCH_C` 的 `ItemGroup` 内新增，现取 `:151-156`）**：
  `Remove … System/Windows/Controls/Primitives/DocumentPageView.cs` ＋ `Include …/DocumentPageView.Linux.cs`；
  `Remove … MS/Internal/documents/DocumentPageHost.cs` ＋ `Include …/DocumentPageHost.Linux.cs`；
- **新增只读对照**：`FDV_E11`（在 `FlowDocumentView` 的挂载点加一行 `ReportFdv`）；`FlowDocumentPage.Linux.cs` 的既有 `FDG.UpdateVisual` 台账**追加** `pageId=`／`pvId=`（§4 身份对拍用）。

### 2.2 生成件逐条（件:行 ＋ 内容锚）

**`build/PresentationFramework.Linux/DocumentPageHost.Linux.cs`**（＝上游 `DocumentPageHost.cs` 逐字复制 ＋ 4 处）：

| # | 件:行 | 内容锚 | 作用 |
|---|---|---|---|
| `E1` | `:66-78` | `DocumentPageHost directHost = currentParent as DocumentPageHost; if (directHost != null) { directHost.PageVisual = null; return; }` | **直接挂载形态**下认父（否则下游会**响亮抛错**＝新缺陷） |
| `E2` | `:136-150` | `if (WpfLinuxPageViewProbe.Enabled) { this.AddVisualChild(_pageVisual); … } else { pageVisualHost = new ContainerVisual(); … }` | **甲**：页视觉对象**直接**挂宿主（同 `FlowDocumentView`）；关闸 ⇒ 逐字回上游包壳 |
| `E3` | `:169-186` | `if (WpfLinuxPageViewProbe.Enabled) { return _pageVisual; } return VisualTreeHelper.GetParent(_pageVisual) as Visual;` | **丙**：枚举与挂载**同源** |
| `E4` | `:209-601` | `internal static class WpfLinuxPageViewProbe` | `[DPV]`／`[DPH]`／`[FDV]` 台账 ＋ 闸（`Enabled` 读 `WPF_PAGEVIEW_ONSCREEN`；**默认关**） |

**`build/PresentationFramework.Linux/DocumentPageView.Linux.cs`**（＝上游 `DocumentPageView.cs` 逐字复制 ＋ 5 处，**全部只读**）：

| # | 件:行 | 内容锚 |
|---|---|---|
| `E1` | `:242` | `WpfLinuxPageViewProbe.ReportMeasure(this, availableSize, _documentPaginator, _documentPage);` |
| `E2` | `:376` | `WpfLinuxPageViewProbe.ReportArrange(this, finalSize, _documentPage, pageVisual, _pageHost);` |
| `E3` | `:453` | `WpfLinuxPageViewProbe.ReportArranged(this, _pageHost, _documentPage);` |
| `E4` | `:478-480` | `Size dpvArrangeResult = base.ArrangeOverride(finalSize); … return dpvArrangeResult;` |
| `E5` | `:489` | `WpfLinuxPageViewProbe.ReportVisit("DPV.GetVisualChild", this, _pageHost, index);` |

> ⚠️ **本席刻意**没改 `DVP` 的 `ArrangeOverride` 排版（**乙**）：现取 `[DPV] hostXf=435.84,107.52,0.347,0.347` 证明上游那套 `CachedOffset`＋`RenderTransform` **已把页放到文档区**（§4），照抄 `Offset` 只会**双重位移** ⇒ 不改，如实记在 §8-4。

### 2.3 幂等（生成器重跑 == 现盘）

```
$ for f in build/PresentationFramework.Linux/*.Linux.cs …/PresentationFramework.Linux.csproj; do sha256sum "$f"; done > before
$ python3 build/PresentationFramework.Linux/reapply-patches.py
$ … > after ; diff before after  ⇒  空
IDEMPOTENT=OK
```
现取关键件 sha16：`DocumentPageView.Linux.cs=792a1ebdcee56aff`／`DocumentPageHost.Linux.cs=f943a1b0bc221be6`／`FlowDocumentView.Linux.cs=87c24a24095e6362`／`PresentationFramework.Linux.csproj=78473a32189b1e3f`／`reapply-patches.py=f6ea9df6f0febebc`。

---

## §3 ③ 本增量**真跑**（二十九腿；同一装置 `:237`）

### 3.1 腿表（现取）

| 腿 | PF 件 | 接线 | `tab1` | `tab2` | `tab3` | `[HC-UNHANDLED]` |
|---|---|---|---|---|---|---|
| `b11base` | `48daaeb326c4aa8b`（**权威件**） | — | `ec40be7a64c60d03` | `b22e87cc86bd8114` | `40dbbd1703f3e360` | 3 |
| `b11probe`／`b11visit` | `193f8c…`／`1994ec…` | 只读探针 | `b440033da8b2a9e6` | `1fb95eab89966441` | `0c51d1ad6fa46543` | 3 |
| `b11drive` | `302bc3f681db3525` | **开** | `b440033da8b2a9e6` | `b440033da8b2a9e6` | `0c51d1ad6fa46543` | **210**（212 形态） |
| `b11drive2`／`3`／`ps2`／`xf1..3`／`ci1..3`／`id2`／`on1..3`／`sub1` | `302bc…`／`743bfb…`／`d78a25c9f152bd5d` | **开** | `b440033da8b2a9e6` | **`1fb95eab89966441`** | `0c51d1ad6fa46543` | 3 |
| `b11off`／`of2` | `302bc…`／`d78a25c9…` | **关** | `b440033da8b2a9e6` | **`1fb95eab89966441`** | `0c51d1ad6fa46543` | 3 |
| `b11of1`（`d78a25c9…`，**关**，212 形态） | `d78a25c9f152bd5d` | 关 | `ec40be7a64c60d03` | `ec40be7a64c60d03` | `40dbbd1703f3e360` | **183** |
| `b11of3`（`d78a25c9…`，**关**，3 形态） | `d78a25c9f152bd5d` | 关 | `ec40be7a64c60d03` | `b22e87cc86bd8114` | `40dbbd1703f3e360` | 3 |
| `b11pol_on2`（`4bec142…`，**开**，3 形态） | `4bec142cae144da6` | 开 | `ec40be7a64c60d03` | `b22e87cc86bd8114` | `40dbbd1703f3e360` | 3 |
| `b11pol_off2`（`4bec142…`，**关**，212 形态） | `4bec142cae144da6` | 关 | `b440033da8b2a9e6` | `b440033da8b2a9e6` | `0c51d1ad6fa46543` | **190** |
| **`b11pol_on1`** | **`4bec142cae144da6`（最终件）** | **`=1`（`mode=direct`）** | `b440033da8b2a9e6` | **`1fb95eab89966441`** | `0c51d1ad6fa46543` | 3 |
| **`b11pol_off1`** | **`4bec142cae144da6`** | **默认关（`mode=container`）** | `b440033da8b2a9e6` | **`1fb95eab89966441`** | `0c51d1ad6fa46543` | 3 |

### 3.2 反极性（**成对**：同一权威件 `4bec142cae144da6`，只差一个 env）

| 面 | `b11pol_on1`（`WPF_PAGEVIEW_ONSCREEN=1`） | `b11pol_off1`（默认关） | 判 |
|---|---|---|---|
| `[DPH] … mode=` | **`direct`**（`[DPH] site=Attach … pv=0x361f531 mode=direct`） | **`container`**（`[DPH] site=Attach … pv=0x361f531 mode=container`） | **接线真进了两形态** |
| `DPH.GetVisualChild` 次数 | 198 | 210 | 渲染遍历两形态都到 |
| `tab1` 帧 | `b440033da8b2a9e6` | `b440033da8b2a9e6` | **逐字节相同** |
| **`tab2` 帧** | **`1fb95eab89966441`** | **`1fb95eab89966441`** | **逐字节相同** |
| `tab3` 帧 | `0c51d1ad6fa46543` | `0c51d1ad6fa46543` | **逐字节相同** |
| `[HC-UNHANDLED]` | 3 | 3 | 同 |

### 3.3 文档区成对读数（`docink.py`，`x∈[250,800] ∧ y∈[100,600]`，容差 ±3）

| 帧 | `b11base` | `b11pol_on1`（**开**） | `b11pol_off1`（**关**） |
|---|---|---|---|
| `tab1` | `ink=17135 colors=764` `GhostWhite=10084 Beige=924 DarkGreen=49 LGY=5884 LightGray=4077` | 同 | 同 |
| **`tab2`** | `ink=1662 colors=125` `0/0/0/0/7` | **`ink=1662 colors=125` `0/0/0/0/7`** | **`ink=1662 colors=125` `0/0/0/0/7`** |
| `tab3` | `ink=1679 colors=149` `2/0/0/0/12` | 同 | 同 |

⇒ **判据③字面不成立**：`tab2`／`tab3` **色数没回升、具名色没出现、帧 `sha16` 没变**；反极性腿给出的是 **"该绿不绿"**（开／关两腿逐字节相同）⇒ **本条接线不是断点**。

> **可比性（纪律 31/32）**：`tab2` 帧**跑次相关**（现取四形态：`1fb95eab89966441`／`b22e87cc86bd8114`／`b440033da8b2a9e6`／`ec40be7a64c60d03`），另有**"212 形态"**（`[HC-UNHANDLED]` ≈180–212）与 **"3 形态"**（＝3）。**两条**都出现在**开**腿与**关**腿里（开：`b11drive` 210 ／ 关：`b11of1` 183、`b11pol_off2` 190）⇒ **本接线既不是"空白"也不是"风暴"的成因**。唯一可用作反极性的成对是 **§3.2**（同件同形态两条都是 3 形态）。

---

## §4 ④ **真断点**上移一层（现取：身份对拍 ＋ 两条链**同口径**）

### 4.1 渲染遍历**确已**走到 `DPV → DPH → 页视觉`，且**位置/尺寸全对**（`b11pol_on1` 现取）

```
[DPV] site=ArrangeOverride id=0x100e300 final=638.4x366.72 page=0x3ee7093 pv=0x361f531
      pvKids=1 pvBounds=0,0,816,1056 host=0x2766936 hostKids=0 viewPS=0x28c5f3 pvPS=null
[DPH] site=Attach host=0x2766936 pv=0x361f531 mode=direct pvParent=0x2766936 pvContent=0,0,816,1056
      pvKids=1 pvBound=0,0,816,1056 hostPS=0x28c5f3 pvPS=0x28c5f3 pvDepth=31
[DPV] site=HostArranged view=0x100e300 host=0x2766936 hostRender=816x1056 hostAt=177.6,0
      hostOff=177.6,0 hostXf=435.84,107.52,0.347,0.347 hostKids=1 page=0x3ee7093
[PAGEVIEW] site=DPV.GetVisualChild self=0x100e300 idx=0 selfRender=638.4x366.72 selfVis=1 child=0x2766936 childRender=816x1056   ×（同形行逐腿 191–212 条）
[PAGEVIEW] site=DPH.GetVisualChild self=0x2766936 idx=0 selfRender=816x1056 selfVis=1 child=0x361f531 childRender=vis            ×同数
```
⇒ **两者都在渲染遍历里、都 `Visible`、尺寸/父子链正确**；`hostXf=435.84,107.52,0.347,0.347` ＋ `pvContent=816×1056` ⇒ 页被映射到文档区 **≈283×367 @ (435.8,107.5)**（**可见**）⇒ **"被裁掉"／"被摆到界外"都不成立**。

### 4.2 **身份对拍**（消 `T-B10` §8-5 的 `PRECOND-PAGE-VISUAL-IDENTITY`）

```
[DPV] … page=0x3ee7093 pv=0x361f531                       ← 在屏 DPV 收到的那一页
[CHAIN] … FDG.UpdateVisual needsUpdate=1 pageId=0x3ee7093 pvId=0x361f531   ← 被格式化的那一页
[FDV] … pv=0x2a6fa61                                       ← tab1 那一页
[CHAIN] … FDG.UpdateVisual needsUpdate=1 pageId=0x12eff60 pvId=0x2a6fa61
```
⇒ **两侧身份相等**：在屏 `DocumentPageView` 收到的页视觉**就是**被格式化（`needsUpdate=1`）的那一页 ⇒ **断点不在"谁在被分页"**，而在这页**视觉里有没有内容**（下条）。

### 4.3 **决定性读数**：`DPV` 那一页**壳内为空**，`FDV` 那一页**叶子有真内容**（同帧、同 `.so`、同口径）

```
[DPH] site=Attach … pvChild=c=0x229b2e9,kids=2,bounds=empty,content=empty
      SUB=L0:0x361f531,k=1,b=0,0,816,1056,c=0,0,816,1056
        | L1:0x229b2e9,k=2,b=empty,c=empty
        | L2:0x3774a34,k=1,b=empty,c=empty
        | L3:0x3319bd8,k=0,b=empty,c=empty          ← PTS 内容轨：**0 个叶子视觉**
        | L2:0xbe7a9f,k=0,b=empty,c=empty            ← 浮层轨：**0**

[FDV] site=Attach … pvChild=c=0xe0907f,kids=2,bounds=-1.621,1.021,601.443,279.043,content=empty
      SUB=… | L2:0x37b7a5e,k=2,b=106.983,6.983,371.033,86.033,c=empty
             | L3:0x3574d54,k=2,b=106.983,6.983,126.033,36.033,c=106.983,6.983,126.033,36.033   ← **真内容**
             | L3:0x211b7f4,k=2,b=206.983,6.983,271.033,86.033,c=206.983,6.983,271.033,86.033   ← **真内容**
```
结构对照（内容锚）：两页的 `_visual` 都**正常**建出 2 个 `ContainerVisual`（＝上游 `PtsPage.UpdatePageVisuals` 的 `pageContentVisual`／`floatingElementsVisual`，现取 `upstream/…/PtsHost/PtsPage.cs:1005-1013` 内容锚 `_visual.Children.Add(new ContainerVisual());`），**但 `tab2` 那一页的两个轨里一个叶子视觉都没有** —— 不是"壳没建"，而是 **"壳里没内容"**。

### 4.4 断点归属（**如实划界**）

⇒ 真断点 ＝ **`PRECOND-PAGINATED-PAGE-CONTENT-VISUALS`**：**分页器造的那一页**（`FlowDocumentPage.PageVisual`）的 PTS 内容轨/浮层轨**没有叶子视觉**；而**同帧** `FlowDocumentView`（滚动，`T-A41` 视口驱动）那一页**有**。§4.1–4.3 把"挂载线／定位／枚举／身份／裁剪"**逐条排除**，**断点不在** `DocumentPageView`／`DocumentPageHost`（本轮的写域），而在**其上游**。

> ⚠️ **本席未读穿的一格**（不猜）：全帧现取 `[CHAIN] site=PH.UpdateParaListVisuals n=1 ×264`、`n=3 ×8`、`PH.UpdateViewportParaList ×34`、`PTSP.UpdateViewport ×1` ⇒ **"那 264 次造段视觉"归谁**（在屏滚动那一页？后台预分页？还是本页？）本侧**仍无直读面** ⇒ 记为 `NOINFO-3`（承 `T-B10`）。这正是"叶子为空"的下一步靶。

---

## §5 ③ 成对 ＋ 反极性（汇总）

| 单变量 | 腿 A | 腿 B | 帧 | 判 |
|---|---|---|---|---|
| `WPF_PAGEVIEW_ONSCREEN=1/未设`（**最终件 `4bec142cae144da6`**） | `b11pol_on1`（`direct`） | `b11pol_off1`（`container`） | `tab1/tab2/tab3` **三帧逐字节相同** | **该绿不绿**（接线无可见效果 ⇒ 证伪） |
| 同件多跑（形态） | `b11drive2/3`（开，3 形态） | `b11off/of2`（关，3 形态） | `tab2=1fb95eab89966441` 同 | 跑次相关，不相减 |
| 权威件 vs 本轮件（**未开**） | `b11base`（`48daaeb326c4aa8b`） | `b11probe`（只读探针） | `tab2` 逐格**同**（`1662/125`，具名色 0） | **零回归** |

**反极性（可给者）**：(a) `vis_built` 极性（承 `T-B10` §5.2-a）不重跑；(b) **本接线极性** ⇒ **帧逐字节不变**（"该绿不绿"）；(c) **页几何极性**（承 `T-B10` §5.2-b）不重跑。

---

## §6 ⑤ 门禁（逐条现取；本席跑的）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| awk '{print $3}' \| sort` vs `src/WpfGfx.Linux.Native/bin/exports.txt` | **846 == 846**，`diff -q` 空 |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5e0d7b807c2fc220 exports=846`**；`PTSGAP_CITED=PASS refs=1 strict=1`；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`；rc=0 |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- direction=in-file phase=realized`**；`PTS_G10_NAME=PASS`；`PTS_N1_GATE=PASS`；`PTS_ENFE=PASS total=0`；rc=0 |
| `PTS_COLORANCHOR` | 同上（`k=24`） | **`PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 min=200 base=全部0`**（**未回退**）；`k=23` `NOINFO(no-anchor-registered-for-k23)` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0`，rc=0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=358 ids=2265 declared=225`**，rc=0（本载体落地**前**现取；落地后 ＋1 ＝本件） |

**未跑**：整趟 `verify-all`（照 `T-B11` ②）；`static-jaws-check.sh`。

---

## §7 ④/⑤ 症状门（成对）＋ 具名 `NOINFO`

### 7.1 症状门

| 症状门 | `b11base` | `b11pol_on1`（开） | `b11pol_off1`（关） |
|---|---|---|---|
| `alive`／`app_rc` | yes／143 | yes／143 | yes／143（均**本席按 PID 收**） |
| `magenta` | 0 | 0 | 0 |
| `Unrecoverable system error` | 0 | 0 | 0 |
| `[HC-UNHANDLED]` | 3 | 3 | 3 |
| `[FORMATLINE-LINE]` | 114 | 114 | 114 |
| `colors`（全屏：boot／tab1／tab2／tab3） | 386／1086／559／570 | 386／1078／551／562 | 386／1078／551／562 |

⚠️ **口径**：本报告**不**用"`FailFast` 字样计数"当症状门（守护接住的异常栈帧也数得进去）；**唯一可信的"没死"读数是 `Unrecoverable=0 ∧ alive=yes`**（二十九腿全成立）。

### 7.2 具名 `NOINFO`（逐条给"消掉需要什么"）

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-1` | **两只形态（"3"／"212"）跑次不可复现** | 同一件两跑：`b11on1` `3`／`b11of1` `183`；**开**腿有 `210`、**关**腿有 `190` ⇒ 与接线无关 | 找出发射侧非确定性源（线程／GC／分页时序）并固化；本席**只报抽取** |
| `NOINFO-2` | **`tab2` 四种帧形态机制** | 现取 `1fb95eab89966441`（自己的空态）／`b22e87cc86bd8114`（第三种空态）／`b440033da8b2a9e6`、`ec40be7a64c60d03`（＝`tab1` 两种画面） | 需一帧"旧子树是否已从树摘除"的只读见证 |
| `NOINFO-3` | **`PH.UpdateParaListVisuals n=1 ×264` 归谁** | 全帧现取（§4.4 引）；`PTSP.UpdateViewport` 仅 `×1` | 加一条"`FlowDocumentPaginator` 实例 ＝ 在屏 `DocumentPageView` 那一份"的只读身份行（**本席已把页身份打通**，剩"谁在造段视觉"） |
| `NOINFO-4` | **`PTSP.UpdatePageVisuals size=2.56x1.92` 的语义** | 现取恒 `2.56x1.92`（×8）；承 `T-B10` §4.1（改 `FIN_DU/DV` 到 `816x1056` 帧不变） | 给出该 `arrangeSize` 的生产者定义 |
| `NOINFO-5` | **本增量无"撤修回退"腿**（＝"修好了再撤"的那条） | 接线**未产生**可见效果 ⇒ 无"回退"可言（§3.2 是 ON/OFF 同帧） | 端点在于先解 `NOINFO-3`／`PRECOND-PAGINATED-PAGE-CONTENT-VISUALS` |

---

## §8 ⑤ 边界 · 具名前置 · 收净 · 自证

1. **写域**：**仓内只改** `build/PresentationFramework.Linux/**`。`git status --porcelain` 现取：
   ```
    M build/PresentationFramework.Linux/FlowDocumentPage.Linux.cs
    M build/PresentationFramework.Linux/FlowDocumentView.Linux.cs
    M build/PresentationFramework.Linux/PresentationFramework.Linux.csproj
    M build/PresentationFramework.Linux/reapply-patches.py
   ?? build/PresentationFramework.Linux/DocumentPageHost.Linux.cs
   ?? build/PresentationFramework.Linux/DocumentPageView.Linux.cs
   ?? build/MilBridge/P1-hcflowdoc-impl-report.md   （T-B8 载体，非本席所建）
   ?? build/MilBridge/P1-hcflowdoc2-impl-report.md  （T-B9 载体，非本席所建）
   ?? build/MilBridge/P1-hcflowdoc3-impl-report.md  （T-B10 载体，非本席所建）
   ?? build/MilBridge/tasks-tail2/T-B8.md / T-B9.md / T-B10.md / T-B11.md   （主控派单件）
   ```
   `git diff --stat` 现取：`FlowDocumentPage.Linux.cs 4 ±`／`FlowDocumentView.Linux.cs 6 ±`／`csproj 5 +`／`reapply-patches.py 620 ±`。
2. **副本先行／写前备份**：`~/tb11-work/bak/PresentationFramework.dll.orig.applocal`（`cp -p`，取在**任何腿之前**，＝`48daaeb326c4aa8b`）。实验件只在**仓外 scratch**。
3. **仓外私有件（不在仓内）**：`~/tb11-work/{leg.sh,tabs.py,order.py,docink.py,analyze.py,logs/,bak/}`；`leg.sh` 由 `~/tb10-work/leg.sh` **逐字节复制**（`cp -p`）后**仅改两行**（`W=$HOME/tb10-work`→`tb11-work`；`TB9_DISPLAY:-:236`→`:237`，`diff` 现取**仅此两处**）。
4. **未做／需往前一层**（如实点名）：**未改** `DocumentPageView.ArrangeOverride` 的 `CachedOffset`＋`RenderTransform`（**乙**）—— 现取 `hostXf=435.84,107.52,0.347,0.347` 证明定位**已对**，照抄 `Offset` 只会**双重位移**（那是**伪造几何**）。
5. **重活走槽／收净**：二十九趟腿全在 `~/heavy-slot.sh --min-avail 1500 --max-hold 400 --wait 900` 内（`HEAVYSLOT=ACQUIRED … RELEASED rc=0`）；显示位只用空闲 `:237`（`~/tb11-work/{xvfb,wm}.pid`，**按 PID 收净**）；`ps -eo pid,comm | grep -i handy` 现取无输出。
6. **具名前置**：
   - **`PRECOND-PAGINATED-PAGE-CONTENT-VISUALS`**（本席新立，＝ §4.3 的真断点）：使**分页器造的那一页**的 PTS 内容轨/浮层轨里**真的建出叶子视觉**（同帧 `FlowDocumentView` 那一页已有 ⇒ 这是**分页路径与滚动路径的差**，不是"分页页视觉不存在"）。
   - **`PRECOND-PAGINATOR-OWNER`**（消 `NOINFO-3`）：一条"`FlowDocumentPaginator` 实例／`FlowDocumentPage` 实例 ＝ 在屏 `DocumentPageView` 那一份 ＋ 当前 `UpdateParaListVisuals` 归谁"的只读身份行。（**本席已给**页↔页视觉的对拍，`§4.2`；剩下的是"谁在造段视觉"。）
7. **可实施替代（下一步，按序）**：
   - **(i) 先加"分页页造段视觉"的只读面**（低成本）：在 `PtsPage.UpdatePageVisuals` 的 `pageDetails.fskupd`／`fSimple`／`pageContentVisual.Children.Count`（件:行 `upstream/…/PtsHost/PtsPage.cs:989-1013`）与 `PtsHelper.UpdateParaListVisuals` 的 `arrayParaDesc.Length`／目标 `VisualCollection` **身份**并打一行 ⇒ 直接回答"到底是**没查回段落**还是**段视觉进了别的容器**"。**判据可证伪**：若目标容器身份 ≠ `§4.3` 的 `L2/L3`，断点在"挂错容器"；若相等且 `n>0` 却仍 0 子，断点在"`CheckDisconnected`/`ValidateVisual` 没落地"。
   - **(ii) 照 `T-A41` 的**视口驱动**范式给分页路径补等价驱动**（`P8`：在生成器里加补丁，产出对应 `.Linux.cs`），使**在屏 `DPV` 那一页**也进 `UpdateViewportParaList`／`RenderSimpleLines`（现取 `PTSP.UpdateViewport` 全帧**仅 1 次**＝只有滚动页被驱动过）。**同趟**给反极性腿（关驱动 ⇒ 帧回退）。
   - ⚠️ **不要**再走"页几何／句柄收严／挂载线"三条（前两条 `T-B10` 已各真跑一次，第三条本席已真跑，**均逐字节不变**）。
8. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑整趟 `verify-all`**。
9. **app-local 逐件复原（任务点名的硬边界）**：二十九腿用 `TB8_PF_SRC` 刷过 app-local 的 `PresentationFramework.dll`，已 `cp -p` **复原** ⇒ 现取五件：`libwpfwin32.so=5e0d7b807c2fc220`／`wpfgfx_cor3.so=a7a0f884b704ca96`／`PresentationCore.dll=1bcc64cfe83ff77b`／`PresentationFramework.dll=48daaeb326c4aa8b`／`WindowsBase.dll=a4ef8af0ccccb247`，其中 `PresentationFramework.dll` **＝仓内权威件(`HEAD` 侧)现读值**。
10. **纪律自证**：重活走槽；显示位只用空闲 `:237`；`temp+rename`（本载体 ＋ 生成件由 `_write_atomic` 保证）；**报数一律现取**（纪律 40）；**接线默认关**（未设 env ⇒ 运行期行为**逐字**回上游，本席已真跑反极性证明二者同帧）；`upstream/**` 一字未动。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hcflowdoc4-impl-report.md | sha256sum | cut -c1-16`）＝ **`32f9ffbed4c5779b`**（本行下方无内容，取该行之前全文的哈希）。

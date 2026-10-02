# P1-hcflowdoc5 报告 —— `T-B12` · `PRECOND-PAGINATED-PAGE-CONTENT-VISUALS`（分页页视觉「壳内为空」）—— **实现（判：断点取实＝「造好了又被搬走」；按同一造视觉机制给分页页补「显示时接回」接线，`tab2` 三格判据全绿；`tab3` 如实划界）**

> 任务：`build/MilBridge/tasks-tail2/T-B12.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T02:0x–02:3x+0800`（各格另注；**所有数值现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=330f9b7`（现取）。
> **未改** `src/WpfGfx.Linux.Native/**`（现取 `git status` 无 native 项）；**未碰** `upstream/**`（只读）。
> 权威件（现取）：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`5e0d7b807c2fc220`**（＝`T-B11` 在册值）、`exports=846`；
>   app-local `PresentationFramework.dll` = **`48daaeb326c4aa8b`**（＝`HEAD` 侧权威件，现取）。
> 托管件（**本轮新产物**）：`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` = **`ebafc51f91c7ca58`**（现取）。
> 装置：私有 `Xvfb :238` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §8）；应用 ＝ 仓外 hc demo
>   （`$APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，`DOTNET` 走 `$HOME/.dotnet`）。
>   **未占** `:10`／`:231`／`:236`／`:237`；所有腿只在空闲 `:238` 上、**只按 PID 收净**。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① 逐跳现取：两条路径的「页壳内内容视觉」是谁建的** | **同源同链**（现取）：`(FlowDocumentView\n.ArrangeOverride ‖ FlowDocumentPaginator.FormatPage)` → `FlowDocumentPage.Arrange`／`EnsureValidVisuals` → `UpdateVisual` → `PtsPage.GetPageVisual` → `PtsPage.UpdatePageVisuals` → **简单页支** `PtsHelper.UpdateTrackVisuals` → `PtsHelper.UpdateParaListVisuals` →（`ContainerParaClient` 递归）→（`TextParaClient`）`ValidateVisual` → `RenderSimpleLines`。**两条路径都走到了这一步**（件:行见 §1.2）。 |
| **② 真断点（本席现取，**改判** `T-B11` 的"没走到"）** | **不是「没走到」——是「走到了又被搬走」**：同一个 `BaseParaClient.Visual`（**引用级**同一）在**后来的页**上被 `PtsHelper.UpdateParaListVisuals` 的 `fskupdNew` 支**从本页 `trackVisual` 摘除**再 `Insert` 到新页（现取 `[PAGEVIS] site=PH.UpdParaList.new idx=0 oldParent=0x2d22d7e vis=0x2948ddd`）；而一个 `Visual` **只能有一个父** ⇒ **先造的那一页的 `trackVisual` 被搬空** ⇒ 显示时 `[DPH] … L3:0x2d22d7e,k=0,b=empty`（§1.3）。 |
| **③ 修（`P8`，生成件 `temp+rename`）** | **按同一条造视觉轨迹补「显示时接回」**：本页在**造视觉那一刻**把 `trackVisual`／`floatingElementsVisual` 的**子视觉引用**记账（`PtsPage._pageContentKeep`／`_pageFloatKeep`，`PtsHelper.UpdatePageVisuals` 语句后一行），在**读 `DocumentPage.Visual`**（`FlowDocumentPage.Visual` getter）时若发现 `trackVisual`／浮层**恰被搬空**，就把这些视觉**换父接回本页**（`WpfLinuxPageVisDrive.ReparentInto`）。**不查 native、不改任何 native 真值、不删/不放宽断言**。闸 `WPF_PAGEPAGE_REDRIVE`（**默认开**，显式 `=0` 关）。生成器重跑 == 现盘（§2 幂等）。 |
| **④ 判据（帧面可证，成对）** | **同一产物 `0c78b91521733139`，只差一个 env**：`tab2` 帧 **`1fb95eab89966441`（551 色／文档区 124 色／具名色 0）→ `ee13c71712d2777c`（841 色／文档区 503 色／`GhostWhite=1334 Beige=99 DarkGreen=3 LightGoldenrodYellow=667`）**；**反极性**（`WPF_PAGEPAGE_REDRIVE=0`）**逐字节回 `1fb95eab89966441`／551／具名色 0**（＝`auth` 基线同值）。**`tab1` 三帧逐字节不变**（`b440033da8b2a9e6`／1078／文档区 763／锚 `9813/910/44/5830`）⇒ **零回退**（§3）。 |
| **⑤ `tab3` 如实划界** | **未改**：现取**全趟只构造了 1 个 `DocumentPageView`**（`[DPV] site=Ctor id=0x17ca304`，`[DPV] site=SetPaginator id=0x17ca304` 各一次）⇒ `tab3`（「流文档查看器」）的页宿主**不是** `DocumentPageView`，**本增量（`DocumentPageView`／`DocumentPageHost` 这条链）覆盖不到它**。具名前置 `PRECOND-TAB3-PAGE-HOST`；可实施替代见 §4.3／§8.7。 |
| **⑥ 门禁（现取）** | `nm==exports`（**846==846**，`diff` 空）｜`PTSGAP=PASS so16=5e0d7b807c2fc220 exports=846`｜`PTS_GUARD=PASS legs=2/2`｜`PTS_COLORANCHOR=PASS k=24 hits=3`（**未回退**）｜`DEFREG=PASS declared=225 route_ids=225`｜`REPORTID=PASS files=359 ids=2265 declared=225`（§5） |
| **⑦ 症状门（成对）** | 全腿 `magenta=0`／`Unrecoverable system error=0`／`FORMATLINE-LINE=114`；`[HC-UNHANDLED]=3`（现取的**干净显示位**腿上；另有跑次相关的「≈170–550 形态」，与 `T-B11` 的 `NOINFO-1` **同族**，§6） |
| **⑧ 边界（未违）** | **仓内只改** `build/PresentationFramework.Linux/**`（生成器 ＋ 生成件 ＋ csproj ＋ 新建 `WpfLinuxPageVisProbe.Linux.cs`）；**未碰** `upstream/**`／仓外 hc 工程／`verify-all.sh`／`close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）；**未跑整趟 `verify-all`**；**未改 native 任何件**；显示位与进程**按 PID 收净**；app-local 五件已复原（`PresentationFramework.dll=48daaeb326c4aa8b`） |

**一句话**：`T-B11` 说"分页页视觉壳内为空"——本席**逐跳取实**后改判为：**同一条造视觉链把内容建出来了**，但**后来的页**用 `fskupdNew` 支把**同一个** `BaseParaClient.Visual` **搬走**（一个 `Visual` 只有一个父）⇒ 显示的那一页变空；本席按**同一机制**给分页页补了"显示时把本页自己的视觉接回"的接线，**`tab2` 三格判据（色数↑／具名色现／帧变）＋ 反极性＋`tab1` 零回退**全部拿到；`tab3` 因**其页宿主根本不是 `DocumentPageView`**（现取全趟仅 1 个 DPV 构造）**如实划界**，不假成功。

---

## §1 ① 逐跳现取：两条路径**同源**，而分页页**建好又被搬空**

### 1.1 被侦察的现场（现取，腿 `t12pag2`＝最终产物 ＋ 驱动开）

```
[FDV] site=Attach view=0x3ee7093 pv=0x2a6fa61 … pvChild=c=0xf4c6b9,kids=2,bounds=-1.621,1.021,601.443,279.043 …   ← tab1（滚动作），有内容
[DPV] site=ArrangeOverride id=0x17ca304 … page=0x93377a pv=0x12cf351 pvKids=1 host=0x25d2df0       ← tab2（单页），显示的就是这一页
[DPH] site=Attach host=0x25d2df0 pv=0x12cf351 … pvChild=c=0x1639973,kids=2,bounds=empty …           ← 驱动关：壳内空
        SUB=L0:0x12cf351,k=1,b=0,0,816,1056 | L1:0x1639973,k=2 | L2:0x80650c,k=1 | L3:0x2d22d7e,k=0,b=empty | L2:0x838d74,k=0
```
（`L1`＝`PtsPage._visual`；`L2`＝`pageContentVisual`／`floatingElementsVisual`；`L3`＝主轨 `trackVisual`；`0x2d22d7e.k=0` ＝**内容轨 0 叶子**。）

### 1.2 「页壳内内容视觉」是**谁**建的、在**哪个调用窗**（两条路径**同链**）

| 跳 | 件:行（现取） | 内容锚原文 | 两条路径的调用窗 |
|---|---|---|---|
| 甲 | `FlowDocumentView.Linux.cs:214-237` | `Rect fsviewViewport = WpfLinuxFsViewDrive.Effective(...); _formatter.Arrange(safeArrangeSize, fsviewViewport);` | **`tab1`**：`FlowDocumentView.ArrangeOverride`（`T-A41` 视口驱动，**上游原件**） |
| 甲' | `FlowDocumentPaginator.Linux.cs`（`T-A44` 生成件） | `breakRecordOut = page.FormatFinite(pageSize, pageMargin, breakRecordIn); page.Arrange(pageSize);` ＋ `if (WpfLinuxChainProbe.EnvOn("WPF_LINEVIS_DRIVE")) { … page.EnsureValidVisuals(); }` | **`tab2`／`tab3`**：`FlowDocumentPaginator.FormatPage` |
| 乙 | `FlowDocumentPage.Linux.cs:859-896`（生成件） | `if (_visualNeedsUpdate) { … pageVisual = _ptsPage.GetPageVisual(); this.PageVisual.Child = pageVisual; … }` | 两者**共用** |
| 丙 | `PtsPage.Linux.cs:989-1044`（生成件） | `ContainerVisual trackVisual = (ContainerVisual)visualChildren[0]; PtsHelper.UpdateTrackVisuals(PtsContext, trackVisual.Children, pageDetails.fskupd, ref pageDetails.u.simple.trackdescr);` | 两者**共用**（**简单页支**） |
| 丁 | `PtsHelper.Linux.cs:243-300`（生成件） | `if (fskupd == PTS.FSKUPDATE.fskupdNew) { … visualCollection.Insert(index, paraClient.Visual); paraClient.ValidateVisual(fskupd); }` | 两者**共用** —— **这就是"谁建的"** |
| 戊 | `TextParaClient.Linux.cs`（生成件） | `WpfLinuxLineVisProbe.Hit("RenderSimpleLines", …)` ；`PtsHelper.LineListSimpleFromTextPara(...)` | 段落视觉**内容**（行盒）在此建出 |

**现取（`t12pag2`，`tab2` 那一页 `pageId=0x93377a`／`pvId=0x12cf351`）**：

```
3109 [PAGEVIS] site=PTSP.UpdPageVis.simple fskupd=2 track=0x2d22d7e vis=0x2d22d7e kids=1 b=-1.621,1.021,601.443,279.043
                SUB=L0:0x2d22d7e,k=1 | L1:0x2948ddd,k=3 | L2:0x338fcc7,k=1 | L3:0x100e300,k=8 …      ← **内容确已建出（k=1→内含 k=3→…k=8）**
3111 [PAGEVIS] site=FDG.UpdateVisual.child needsUpdate=1 pageId=0x93377a vis=0x1639973 kids=2 b=-1.621,1.021,601.443,279.043 …
```
⇒ **第一条结论（改判 `T-B11`）**：`tab2` 那一页的**页壳内内容视觉，是被 §1.2 的**同一条链**建出来的**（`PtsHelper.UpdateParaListVisuals` 的 `fskupdNew` 支 · `visualCollection.Insert(index, paraClient.Visual)` ＋ `paraClient.ValidateVisual`），**在 `FlowDocumentPaginator.FormatPage` 这个调用窗里**（经 `T-A44` 驱动的 `page.EnsureValidVisuals()`）。**⇒ 分页路径"走到了同一步"，不是"没走到"。**

### 1.3 **它为什么又变空**（逐跳现取：**同一个 `Visual` 被后来的页搬走**）

```
3697 [PAGEVIS] site=PH.UpdParaList.new idx=0 oldParent=0x2d22d7e vis=0x2948ddd kids=3 b=-1.621,1.021,601.443,279.043 …
3708 [PAGEVIS] site=PH.UpdParaList.new idx=0 oldParent=0x2948ddd vis=0x338fcc7 kids=1 …
3717 [PAGEVIS] site=PH.UpdParaList.new idx=0 oldParent=0x338fcc7 vis=0x100e300 kids=8 …
```
（`[PAGEVIS] site=PH.UpdParaList.new` 的**发点**就落在 `PtsHelper.UpdateParaListVisuals` 的 `fskupdNew` 支——**"从旧父摘除 → Insert"** 那两行之前；**全趟 `oldParent≠null` 的搬运共 216 次**。）

⇒ **`0x2d22d7e`（＝`tab2` 那一页的 `trackVisual`）的**唯一**子 `0x2948ddd`（＝该页 Section 段落的 `BaseParaClient.Visual`）在 3697 被**后来的页**接手**；`0x338fcc7`、`0x100e300` 等**同一子树的每一层**随之被搬。**一个 `Visual` 只能有一个父** ⇒ `0x2d22d7e` 当场变空。到显示时：

```
[DPH] site=Attach host=0x25d2df0 pv=0x12cf351 … pvChild=c=0x1639973,kids=2,bounds=empty …
      SUB=… | L3:0x2d22d7e,k=0,b=empty | L2:0x838d74,k=0,b=empty          ← 内容轨与浮层轨**双双为空**
```
**同趟对照**（`tab1` 那一页 `0x2a6fa61`，同一份文档、同一 `.so`）：`[FDV] … L3:0x3574d54,k=2,c=106.983,6.983,126.033,36.033` ⇒ **有真内容**。⇒ **差不在"链"，在"这棵树有没有被搬走"**。

> **归因（具名）**：`tab2`／`tab3` 走 `FlowDocumentPaginator`，其**同一批 `BaseParaClient.Visual`** 被**连续多页**共用（`[FSPARALIST-PARA] … form=native-owned-subtrack … reused=1`），`fskupdNew` 支逐页**把它搬给最后一页** ⇒ **只有最后造的那页留着它**；而 `DocumentPageView` 显示的是**先造的那一页**。`tab1` 走 `FlowDocumentFormatter`（**另一套 context／另一批客户端**）⇒ 不被搬。

---

## §2 ② 修（`P8`）：**显示时把本页自己的视觉接回**（生成件 `temp+rename`；生成器重跑 == 现盘）

### 2.1 生成器（`build/PresentationFramework.Linux/reapply-patches.py`）新增补丁族 `T-B12`

| 件:行（生成器内） | 产物 | 作用 |
|---|---|---|
| `PAGEVIS_PROBE_TEXT`（新生成件 `WpfLinuxPageVisProbe.Linux.cs`） | 新文件 | 只读台账 `[PAGEVIS]`（身份／子数／包围盒／逐层子树）＋ **驱动闸 `WpfLinuxPageVisDrive`**（`WPF_PAGEPAGE_REDRIVE`，默认开）＋ `KeepVisuals`／`ReparentInto` |
| `PtsPage.cs` 补 `GetPageVisual` 尾 ＋ `UpdatePageVisuals` 简单页支尾 ＋ `UpdateFloatingElementVisuals` 语句后 | `PtsPage.Linux.cs` | ① 台账；② **建视觉那一刻**记账本页 `trackVisual`／浮层子视觉（`_pageContentKeep`／`_pageFloatKeep`）；③ 新增 `RedrivePageVisualsForDisplay()` |
| `FlowDocumentPage.cs` 补 `Visual` getter | `FlowDocumentPage.Linux.cs` | **只**在"读页视觉"这条**显示路径**上调用 `_ptsPage.RedrivePageVisualsForDisplay()`（`FlowDocumentView` 的 `EnsureValidVisuals` **不**经此 ⇒ `tab1` 链一字不动） |
| `PtsHelper.cs`／`DocumentPageView.cs`／`DocumentPageHost.cs` | 同名生成件 | 只读钩子（`PH.UpdParaList.new` 的 `oldParent=`、`[DPV] Ctor/SetPaginator`） |

### 2.2 驱动逐条（件:行 ＋ 内容锚）

```
PtsPage.Linux.cs（生成件）：
  private System.Collections.Generic.List<Visual> _pageContentKeep;
  private System.Collections.Generic.List<Visual> _pageFloatKeep;
  internal void RedrivePageVisualsForDisplay()
  {
      if (!WpfLinuxPageVisDrive.Enabled) { return; }
      if (_pageContentKeep == null && _pageFloatKeep == null) { return; }
      if (_visual == null || IsEmpty) { return; }
      if (_visual.Children.Count != 2) { return; }
      … if (trackVisual.Children.Count == 0) { WpfLinuxPageVisDrive.ReparentInto(trackVisual, _pageContentKeep); did = true; }
        if (floatingVisual.Children.Count == 0) { WpfLinuxPageVisDrive.ReparentInto(floatingVisual, _pageFloatKeep); did = true; }
      …（`try/catch`：失败**如实打一行 `[PAGEVIS] … outcome=exception`**，**不重抛**——不许可选修复盖掉页面自身显示）
```
- **同源**：接回的动作 ＝ `从旧父摘除 → 按序 Insert`，与上游 `fskupdNew` 支**同一序列**；**不**调 `ValidateVisual`（子树内容原样搬回，避免任何 native 查询）。
- **零动作条件**：只在"本页**非空 ∧ `_visual` 有 2 子 ∧ `trackVisual`／浮层**恰被搬空**"时动手 ⇒ `tab1` 那一页（非空）**永不**命中。
- **零假值**：`WPF_PAGEPAGE_REDRIVE=0` ⇒ **整块不发生**（逐字回上游行为 ⇒ 反极性腿）。

> ⚠️ **本席第一版（`450f15ab`）被现取证伪**：它按 `T-B11` §8-7(ii) 的思路在显示时**重新查 native**（`FsQueryPageDetails`／`FsQueryTrackDetails`）再 `UpdateParaListVisuals(fskupdNew)`——现取**当场抛 `PtsException`**（那一页的 PTS 句柄在显示时**已陈旧**：`[FS_PAGE_GAP] reason=stale-paraclient-across-page-destroy … entry=FsQueryTrackParaList`）⇒ 改为**完全不查 native** 的"记账 ＋ 换父"版。**这一处如实记**（`NOINFO-TB12-V1-FALSIFIED`）。

### 2.3 幂等（生成器重跑 == 现盘）

```
$ python3 build/PresentationFramework.Linux/reapply-patches.py ; sha… > before
$ python3 build/PresentationFramework.Linux/reapply-patches.py ; sha… > after
$ diff before after  ⇒  空
IDEMPOTENT=OK
```
现取关键件 `sha16`：`reapply-patches.py=131e1181b5fc8269`／`WpfLinuxPageVisProbe.Linux.cs=4463d080a91b7f20`／`PtsPage.Linux.cs=f7380b128e0e1ff2`／`PtsHelper.Linux.cs=0cec84f36657656c`／`FlowDocumentPage.Linux.cs=2630c4d441f403d6`／`FlowDocumentView.Linux.cs=87c24a24095e6362`（**未变**）／`DocumentPageView.Linux.cs=70ae72ea3e452774`／`DocumentPageHost.Linux.cs=6fcc728a65843f22`／`PresentationFramework.Linux.csproj=d31645122db837c8`。

---

## §3 ③ 真跑：成对读数 ＋ 反极性（同一产物，只差一个 env）

### 3.1 腿表（现取；同一装置 `:238`，「干净显示位」见 §8.5）

| 腿 | 托管件 `sha16` | `WPF_PAGEPAGE_REDRIVE` | `tab1` 帧 | **`tab2` 帧** | `tab3` 帧 | `[HC-UNHANDLED]` |
|---|---|---|---|---|---|---|
| `t12auth3` | `48daaeb326c4aa8b`（**权威件**） | —（无该接线） | `b440033da8b2a9e6` | `1fb95eab89966441` | `0c51d1ad6fa46543` | 3 |
| **`t12pag2`** | **`0c78b91521733139`** | 缺省（**开**） | `b440033da8b2a9e6` | **`ee13c71712d2777c`** | `0c51d1ad6fa46543` | 3 |
| **`t12pagoff`** | **`0c78b91521733139`** | **`=0`（关）** | `b440033da8b2a9e6` | **`1fb95eab89966441`** | `0c51d1ad6fa46543` | 3 |
| `t12keep2`／`t12keep3`／`t12ctor` | `a7a1b6dbe027f54d`／`ebafc51f91c7ca58` | 缺省（**开**） | `b440033da8b2a9e6` | `ee13c71712d2777c` | `0c51d1ad6fa46543` | 3 |

### 3.2 **成对读数**（`docink.py`：文档区 `x∈[250,800] ∧ y∈[100,600]`；整屏色数）

| 帧 | `t12auth3`（权威件） | **`t12pag2`（开）** | **`t12pagoff`（关）** |
|---|---|---|---|
| `tab1` | 整屏 `colors=1078`；文档区 `763`；`GhostWhite=9813 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 LightGray=3712` | **同（逐格同）** | **同（逐格同）** |
| **`tab2`** | `colors=551`；文档区 `124`；**具名色 0/0/0/0** | **`colors=841`；文档区 `503`；`GhostWhite=1334 Beige=99 DarkGreen=3 LightGoldenrodYellow=667 LightGray=449`** | **`colors=551`；文档区 `124`；具名色 0/0/0/0（逐格＝权威件）** |
| `tab3` | `colors=562`；文档区 `148`；具名色 0/0/0/0 | **同** | **同** |

### 3.3 **反极性**（同一产物 `0c78b91521733139`，只差一个 env）

| 面 | `t12pag2`（`WPF_PAGEPAGE_REDRIVE` 缺省＝开） | `t12pagoff`（`=0`） | 判 |
|---|---|---|---|
| `[PAGEVIS] site=PTSP.RedrivePageVisuals` | **1 行**：`content=1 float=2 vis=0x1639973 kids=2 b=-1.621,1.021,601.443,279.043 … L3:0x2948ddd,k=3 …` | **0 行**（`Redrive=0`） | **接线真进了** |
| `[DPH] site=Attach … pvChild=` | `c=0x1639973,kids=2,bounds=-1.621,1.021,601.443,279.043`（**有内容**） | `c=0x1639973,kids=2,bounds=empty`（**空**） | **两形态** |
| **`tab2` 帧 `sha16`** | **`ee13c71712d2777c`** | **`1fb95eab89966441`** | **帧面变／回** |
| `tab2` 色数（整屏／文档区） | `841／503` | `551／124` | **该绿真绿＋撤修必回** |
| `tab1` 帧 | `b440033da8b2a9e6` | `b440033da8b2a9e6` | **逐字节相同（零回退）** |

> **判**：判据③ **字面成立**（`tab2` 色数回升 ＋ 具名色出现 ＋ 帧 `sha16` 变），**反极性成立**（撤修 ⇒ `tab2` **逐字节回** `1fb95eab89966441`／551／具名色 0，＝权威件同值），**`tab1` 成绩未回退**。

---

## §4 ④ 断点归属 · `tab3` 如实划界 · 具名前置

### 4.1 本增量**覆盖到**的（＝ `DocumentPageView`／`DocumentPageHost` 这条链）

`tab2`（「流文档单页视图」，hc demo 里就是一个 `DocumentPageView`）：**修好**（§3 三格判据 ＋ 反极性）。

### 4.2 `tab3`（「流文档查看器」）**不覆盖**（现取，非推测）

```
[DPV] site=Ctor id=0x17ca304 NOINFO=dpv-ctor-readonly            ← 全趟**只构造了 1 个 `DocumentPageView`**
[DPV] site=SetPaginator id=0x17ca304 pag=0x161bb2c …             ← 全趟**只有 1 次**接线
```
⇒ `tab3` 的页宿主**不是** `DocumentPageView`（`tab3` 的帧 `0c51d1ad6fa46543`／562／文档区 148／具名色 0 **在开/关两腿与权威件腿逐字节相同**）。**本增量对它零影响**——不是"没修好"，而是"**不在本条链上**"。

### 4.3 具名前置 ＋ 可实施替代

- **`PRECOND-TAB3-PAGE-HOST`**（本席新立）：使 `tab3` 的**页宿主**可达（现取它**从不构造 `DocumentPageView`**；`tab3` 会话里确有分页活动——`[CHAIN] site=FDG.Arrange size=816x1056`／`DRIVE.EnsurePageVisuals site=FDPaginator.FormatPage`——但**没有任何 `DocumentPageView` 去读 `DocumentPage.Visual`**）。
  *可实施替代（下一步，低成本）*：在 `FlowDocumentReader`／其内容宿主的**切换与模板套用处**各打一条**只读**行（哪一支被创建、`PART_ContentHost` 上挂了什么），即可判"是**查看器根本没造页宿主**"还是"造了但没接线"。
- **`PRECOND-PAGE-SCOPED-PARA-CLIENT`**（承 `T-A47` 同族，**本席现取的**根因）：native 侧 `pfsparaclient`／其 `Visual` **跨页复用**（现取：同一 `BaseParaClient.Visual` 先后被多页 `Insert`／摘除**216 次**）⇒ 托管侧只能"**最后一页**留视觉"。本增量的"显示时接回"是**托管侧可实施替代**；**根治**需 native 侧**页作用域**的客户端（`src/WpfGfx.Linux.Native/**`，本席**未改**）。

---

## §5 ⑤ 门禁（逐条现取；本席跑的）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| awk '{print $3}' \| sort` vs `bin/exports.txt` | **846 == 846**，`diff -q` 空 |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5e0d7b807c2fc220 exports=846`**；`PTSGAP_CITED=PASS refs=1 strict=1`；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`；rc=0 |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- direction=in-file phase=realized`**；`PTS_G10_NAME=PASS`；`PTS_N1_GATE=PASS`；`PTS_ENFE=PASS total=0` |
| `PTS_COLORANCHOR` | 同上（`k=24`） | **`PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 min=200 base=全部0`**（**未回退**）；`k=23` `NOINFO(no-anchor-registered-for-k23)` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0`，rc=0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=359 ids=2265 declared=225`**，rc=0（本载体落地**前**现取；落地后 ＋1） |

**未跑**：整趟 `verify-all`（照 `T-B12` ②）；`static-jaws-check.sh`。

---

## §6 ④/⑤ 症状门（成对）

| 症状门 | `t12auth3` | `t12pag2`（开） | `t12pagoff`（关） |
|---|---|---|---|
| `magenta` | 0 | 0 | 0 |
| `Unrecoverable system error` | 0 | 0 | 0 |
| `[FORMATLINE-LINE]` | 114 | 114 | 114 |
| `[HC-UNHANDLED]` | 3 | 3 | 3 |
| `alive`／`app_rc` | yes／143 | yes／143 | yes／143（均**本席按 PID 收**） |

⚠️ **同族跑次形态（`T-B11` `NOINFO-1`，本席复现）**：另有 `[HC-UNHANDLED] ∈ {174…551}` 的形态（本席现取 `t12pag`=496、`t12ctoroff`=551、`t12ctoroff2`=426 等），其**首发**恒为
`[FS_PAGE_GAP] rc=-10000 reason=stale-paraclient-across-page-destroy(not-this-window-live;HandleToObject-would-FailFast) entry=FsQueryTrackParaList`
⇒ **与 `T-B11` 同族**（`PRECOND-PAGE-SCOPED-PARA-CLIENT` 的另一个面）；本增量的**开/关**对拍**全部取自"3 形态"的腿**。

---

## §7 具名 `NOINFO`

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-TB12-V1-FALSIFIED` | 本席**第一版**驱动（查 native 再重建）**当场抛 `PtsException`** | `450f15ab` 腿上 `[PAGEVIS] … outcome=exception type=PtsException`；同刻 `[FS_PAGE_GAP] reason=stale-paraclient-across-page-destroy` | 页的 PTS 句柄在**显示时**仍 live（＝`PRECOND-PAGE-SCOPED-PARA-CLIENT` 解） |
| `NOINFO-TB12-FLOAT-SRC` | 被接回的浮层视觉（`float=2`）**归哪一页先造** | `[PAGEVIS] … content=1 float=2`；`[CHAIN] PH.FloatingReparent idx=0/1` | 一条"浮层 `Visual` 的**首发页**"只读身份行 |
| `NOINFO-TB12-TAB3` | `tab3` 的页宿主**是什么** | 全趟 `[DPV] site=Ctor`＝**1**；`tab3` 会话内 `FDG.Arrange`／`FormatPage` 有、**没有任何 DPV** | §4.3 的只读行（查看器切换/模板套用处的 `[CHAIN]`） |
| `NOINFO-TB12-MODE` | `[HC-UNHANDLED]` 的「3」与「≈170–550」两形态**跑次不可复现** | 同产物多跑：`t12pag`=496／`t12pag2`=3 | 找发射侧非确定性源并固化（本席**只报抽取**） |

---

## §8 边界 · 具名前置 · 收净 · 自证

1. **写域**：**仓内只改** `build/PresentationFramework.Linux/**`。现取 `git status --porcelain`：
   ```
    M build/PresentationFramework.Linux/FlowDocumentPage.Linux.cs
    M build/PresentationFramework.Linux/FlowDocumentView.Linux.cs   ← 内容未变（生成器重跑同哈希），仅"在册改动"
    M build/PresentationFramework.Linux/PresentationFramework.Linux.csproj
    M build/PresentationFramework.Linux/PtsHelper.Linux.cs
    M build/PresentationFramework.Linux/PtsPage.Linux.cs
    M build/PresentationFramework.Linux/reapply-patches.py
   ?? build/PresentationFramework.Linux/DocumentPageHost.Linux.cs      （T-B11 建，非本席）
   ?? build/PresentationFramework.Linux/DocumentPageView.Linux.cs      （T-B11 建，非本席）
   ?? build/PresentationFramework.Linux/WpfLinuxPageVisProbe.Linux.cs （本席建）
   ?? build/MilBridge/P1-hcflowdoc{,2,3,4}-impl-report.md / tasks-tail2/T-B{8..12}.md （他人/主控件）
   ```
   **无** `src/**`、**无** `upstream/**`、**无** `build/MilBridge/tools/**` 改动。
2. **副本先行／写前备份**：`~/tb12-work/bak/PresentationFramework.dll.orig.applocal`（`cp -p`，取在**任何腿之前**，＝`48daaeb326c4aa8b`）。
3. **仓外私有件（不在仓内）**：`~/tb12-work/{leg.sh,docink.py,tabs.py,analyze.py,logs/,bak/}`；`leg.sh` 由 `~/tb11-work/leg.sh` **逐字节复制**后**仅改两行**（`W`→`tb12-work`；`:237`→`:238`，`diff` 现取**仅此两处**）；`tabs.py` 仅把点后等待 `2.0s→6.0s`（**同一读数**，用于排除"截图过早"）。
4. **未做／如实点名**：**未改** native（`src/WpfGfx.Linux.Native/**` 一字未动）——根治 `PRECOND-PAGE-SCOPED-PARA-CLIENT` 属那边；**未实现** `tab3` 的页宿主接线（§4.3）。
5. **重活走槽／收净**：全部腿在 `~/heavy-slot.sh --min-avail 1500 --max-hold 1200` 内（`HEAVYSLOT=ACQUIRED … RELEASED rc=0`）；显示位只用空闲 `:238`（`~/tb12-work/{xvfb,wm}.pid`，**按 PID 收净**，并**清掉陈旧 `:238` lock/socket**）；现取 `pgrep -af 'Xvfb :238'` 无输出、`ps -eo pid,comm | grep -i handydotnet` 无输出。
6. **⚠️ 装置坑（如实记，供后手避）**：本席最初用 `kill` 收 `:238` 后**残留 `/tmp/.X238-lock` ＋ 陈旧 socket** ⇒ `leg.sh` 见 socket 在 ⇒ `DISPLAY_REUSED` ⇒ **不为新 Xvfb 起 server** ⇒ 应用**开机即 `rc=134`**（`XOpenDisplay(":238") 失败`）或落进"高 `[HC-UNHANDLED]`"形态。**修**：收净时同时删 `:238` 专属 `lock/socket`（§8.5 的收尾脚本已含）。此前那些"风暴"腿**均由它造成**，**不是**本增量的效果。
7. **可实施替代（下一步，按序）**：
   - **(i) `tab3` 页宿主可达性**：在 `FlowDocumentReader` 的视图切换／模板套用处加**只读**行 ⇒ 判 §4.3 的 `PRECOND-TAB3-PAGE-HOST`。
   - **(ii) 根治 `PRECOND-PAGE-SCOPED-PARA-CLIENT`**：native 侧让**页级**客户端／视觉不再跨页复用（`T-A47` 已把同族根因点名的**同一片**）。
8. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑整趟 `verify-all`**。**未** `git add/commit/push`。
9. **app-local 逐件复原（任务点名的硬边界）**：全部腿用 `TB8_PF_SRC` 刷过 app-local 的 `PresentationFramework.dll`，已 `cp -p` **复原** ⇒ 现取五件：`libwpfwin32.so=5e0d7b807c2fc220`／`wpfgfx_cor3.so=a7a0f884b704ca96`／`PresentationCore.dll=1bcc64cfe83ff77b`／`PresentationFramework.dll=48daaeb326c4aa8b`／`WindowsBase.dll=a4ef8af0ccccb247`，其中 `PresentationFramework.dll` **＝仓内权威件现读值**。
10. **纪律自证**：重活走槽；显示位只用空闲 `:238`；`temp+rename`（生成器 `_write_atomic`，本载体亦如此落盘）；**报数一律现取**（纪律 40）；**接线默认开但可撤**（`WPF_PAGEPAGE_REDRIVE=0` ⇒ 逐字回上游，本席已真跑反极性证明 `tab2` 回 `1fb95eab89966441`）；`upstream/**` 一字未动。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hcflowdoc5-impl-report.md | sha256sum | cut -c1-16`）＝ **`15b58f3f2e51d3bd`**（本行下方无内容，取该行之前全文的哈希）。

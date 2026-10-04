# `P1-hctab3c` 报告 —— `T-B19` ①「tab3 宿主上为什么没排渲染趟」的逐跳现取（**否证 `T-B17` 的判词**：渲染趟**排了**）＋ ②**真修**（把 `T-B12` 的"在屏页被搬空"修复挪到**渲染遍历入口**）＋ ③**帧面三项判据全部成立**（`tab3` 文档区 `148→731`、具名色 `0/0/0/0→9449/842/16/5861`、帧 `71a93980→5e7d5279` 且 ≠`tab1` 帧）＋ 反极性成立

> 任务：`build/MilBridge/tasks-tail2/T-B19.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T09:5x–10:2x+0800`（各格另注；**所有数值现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，**`HEAD=fc48fca66a2e715729a2bd0bf8fa2044ffbc1842`**（现取；＝ `T-B18` 收口后）。
> **开工件（现取，本席实测）**：`libwpfwin32.so=5f9ed647c68197ae`｜`wpfgfx_cor3.so=3faac21668b4b921`｜`PresentationCore.dll=eb3f61e282265518`｜
> `PresentationFramework.dll=c7732cc5b97a78ea`｜`WindowsBase.dll=05bdde9b5527bfde`｜`PresentationUI.dll=69136eecc84aa9f5`（＝**闸缺省关**的 Release 替身）。
> **本轮产物（现取）**：`wpfgfx_cor3.so=e88f82233f53d1ea`（只读探针）｜**`PresentationFramework.dll=788ebcdbf9d2b241`**（**真修** ＋ 只读探针）。
> 装置：私有 `Xvfb :239 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §8）；
>   应用 ＝ 仓外 hc demo（`$APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，`DOTNET` 走 `$HOME/.dotnet`）。
> **重活全走槽**：`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 600..900`（本席 **14 趟腿 ＋ 5 次构建/发布**，全部 `HEAVYSLOT=ACQUIRED … RELEASED rc=0`）。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① 现取（**否证 `T-B17` 判词**）** | **「宿主进场后没有渲染趟被排」在本代树上不成立**：整趟（90 s）**共 47–48 次呈现**，其中 **`tab3` 占 6–7 次**；切到 `tab3` 帧由 `c22457cf663453dd` 变到 `71a93980be1f49a6`。⇒ 那条判词是对「**旧 `.so` ＋ `WPF_DPV_RTB_FALLBACK=1`**」那一形态的读数；`T-B18` 修掉 WIC-RTB 之后**形态已变**。§1 |
| **①′ 真断点（本轮钉死）** | **`tab3` 稳态呈现里，分页页宿主的"页子树"已经被搬空**：同口径现取 `docContent` **`tab1`=46 ↔ `tab3`=6`**；`ROOTDIAG 从根可达` 654 → **538**；**悬空子句柄 = 0**（树是**自洽**的 ⇒ 不是"资源被提前释放"）；逐节点 diff 现取：页视觉链上的两个内容容器 **`0xe5`（浮动）与 `0x3cb`（轨道）`k=2/k=1 → k=0`**（**子被摘走、没接回来**）。§2 |
| **①″ 真因（逐跳现取）** | `PtsHelper.UpdateParaListVisuals` 的 `fskupdNew` 支**先"从旧父摘除"再 `Insert`**（`PtsHelper.Linux.cs:302-316`）；而一个 `Visual` **只能有一个父** ⇒ **本页的内容视觉被后来的页沿用、本页容器被搬空**（＝`T-B12` 已具名的机制）。`T-B12` 的修复体**本身在**（`PtsPage.Linux.cs:660 RedrivePageVisualsForDisplay`），但它的**挂钩点**（`FlowDocumentPage.Visual` 的 getter，`FlowDocumentPage.Linux.cs:113-116`）**挂在"读 `Visual`"那一刻（＝ `Arrange` 期）** ⇒ 搬空发生在**布局之后、成帧之前** ⇒ **11 趟腿里 `[PAGEVIS] site=PTSP.RedrivePageVisuals` 一次都没触发**（现取 `grep -c` = **0**）。§2.3 |
| **② 修（`P8`／可撤）** | **把同一条修复挪到"渲染遍历入口"**：`DocumentPageView.GetVisualChild`（渲染/命中遍历枚举页宿主的**唯一出口**）里调 `WpfLinuxPageViewProbe.RedrivePageVisuals(_documentPage)`（`DocumentPageView.Linux.cs:511`）→ `FlowDocumentPage.RedrivePageVisualsOnly()`（`FlowDocumentPage.Linux.cs:247`）→ `PtsPage.RedrivePageVisualsForDisplay()`（**`T-B12` 原修复体，一字未改**）。**零新增几何/native 真值**；闸沿用 `WPF_PAGEPAGE_REDRIVE`（缺省开）。§3 |
| **③ 帧面（三项判据全成立）** | `tab3` 文档区色数 **`148 → 731`**；具名色 **`0/0/0/0 → GhostWhite=9449 Beige=842 DarkGreen=16 LightGoldenrodYellow=5861`**；帧 **`71a93980be1f49a6 → 5e7d5279f9b7e4e3`**（**≠** 同腿 `tab1` 的 `c22457cf663453dd`）。`tab1`/`tab2` 帧**逐字节零变化**。**反极性**（`WPF_PAGEPAGE_REDRIVE=0`）⇒ `tab3` **逐字节回** `71a93980be1f49a6`（doc 148、具名色 0）。**两次独立腿逐字节复现**。§4 |
| **④ 门禁（现取）** | `NM_EQ_EXPORTS=PASS`（**846==846**，`diff -q` 空）｜`PTSGAP=PASS … so16=5f9ed647c68197ae exports=846`｜`PTS_GUARD=PASS legs=2/2`｜`PTS_COLORANCHOR=PASS k=24 … hits=3`（**未回退**）｜`DEFREG=PASS declared=225 route_ids=225`｜`REPORTID=PASS files=367 ids=2266 declared=225`。§5 |
| **⑤ 症状门（成对）** | `magenta=0`／`Unrecoverable=0`／`PTS_GAP entry=0`／`FORMATLINE-LINE=156`／`alive=yes`／`app_rc=143`（各腿同；**按 PID 收**）｜`0x80070006 (E_HANDLE)=0`（承 `T-B18`，**未回退**）｜`[HC-UNHANDLED]` 413–571、`FailFast` 70–95（**逐腿波动，与本增量无单调关系**）。§6 |
| **⑥ 边界（未违）** | 仓内**只改** `src/WpfGfx.Linux/Interop/**`（两件）＋ `build/PresentationFramework.Linux/**`（生成器与生成件）；**未碰** `upstream/**`（只读）／仓外 hc 工程／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（只调不改）；**未跑**整趟 `verify-all`；app-local **六件与仓内权威件逐件一致**；显示位与进程**按 PID 收净**。**方案数 = 3**（≤3）。§8 |

**一句话**：`T-B17` 的判词**被现取否证**（渲染趟**排了**，`tab3` 也画出了自己的帧）；真断点是**分页页宿主的页子树在成帧前被后来的页"搬走"**（`T-B12` 已具名），而 `T-B12` 的修复**挂晚了**（挂在 `Arrange` 期，搬空发生在 `Arrange` 之后）—— 本席把**同一条修复体**挪到**渲染遍历入口**（`DocumentPageView.GetVisualChild`），`tab3` 页**真上屏**（`148→731`＋具名色成片出现＋帧变且≠`tab1`），反极性成立，`tab1`/`tab2` 与全部门禁**零回归**。

---

## §1 ① 现取：**渲染趟被排了**（否证 `T-B17` 判词）

### 1.1 新只读探针（`src/WpfGfx.Linux/Interop/MilPresentProbe.cs`，缺省关）

在 `MilPresentation.PresentTarget` 的**渲染之后**挂一格只读读数（`MilPresentation.cs:1163` 新增一行调用）：

```
frame = RenderChannel(channel, root, width, height, target.ClearColor);
drawn = DrawnCommands; notDrawn = NotDrawnCommands; notDrawnSummary = NotDrawnSummary;
MilPresentProbe.OnPresent(callNo, hwnd, width, height, drawn, notDrawn, root, channel);   // ← 本轮新增（只读）
```

`OnPresent` 现取**活投影根树**（＝`VisualProjection.Project(channel, target.Root)` 那棵，`MilPresentation.cs:996`）的：节点数 `nodes`、带内容节点数 `withContent`、指令总数 `instr`，以及**累加偏移**落在**文档区** `x∈[240,910] ∧ y∈[90,480]` 的 `docNodes/docContent/docInstr`；另有一格**悬空子句柄**读数（§2.2）。env 闸：`WPF_LINUX_MIL_PRESENT_ALL`／`WPF_LINUX_MIL_ROOTGEO`／`WPF_LINUX_MIL_ROOTFULL`／`WPF_LINUX_MIL_DANGLING`（**全缺省关**）。**只读、零开销**。

**不扰动（现取，成对）**：开/关各闸的腿 `tab1/tab2/tab3` 帧**逐字节同**（`c22457cf663453dd`／`c22457cf663453dd`／`71a93980be1f49a6`）。

### 1.2 现取：**整趟 47–48 次呈现**（`WPF_LINUX_MIL_PRESENT_ALL=1`；`doc19` 现取）

```
[PVA] seq=1  call=5  hwnd=0x400004 800x600 drawn=0   … nodes=1   withContent=0   instr=0    docNodes=0   docContent=0  docInstr=0
[PVA] seq=9  call=19 hwnd=0x400004 800x600 drawn=218 … nodes=405 withContent=146 instr=223  docNodes=6   docContent=3  docInstr=7
[PVA] seq=35 call=45 hwnd=0x400004 800x600 drawn=309 … nodes=624 withContent=230 instr=320  docNodes=133 docContent=46 docInstr=49   ← tab1（滚动视图）
[PVA] seq=41 call=51 hwnd=0x400004 800x600 drawn=303 … nodes=623 withContent=229 instr=319  docNodes=135 docContent=46 docInstr=50
[PVA] seq=42 call=52 hwnd=0x400004 800x600 drawn=322 … nodes=654 withContent=240 instr=333  docNodes=136 docContent=47 docInstr=52   ← 切到 tab3 的第 1 次
[PVA] seq=43 call=53 hwnd=0x400004 800x600 drawn=322 … nodes=654 withContent=240 instr=333  docNodes=136 docContent=47 docInstr=52   ← 第 2 次
[PVA] seq=44 call=54 hwnd=0x400004 800x600 drawn=278 … nodes=538 withContent=198 instr=289  docNodes=21  docContent=6  docInstr=9    ← 第 3 次起：页子树已空
…（`seq=45..47`（`full19` 到 48）与 `seq=44` 逐项相同）
```

每类 `nodes` 出现次数（`doc19` 现取 `uniq -c`）：`1(×1),34(×5),124(×2),405(×2),410(×1),415(×23),624(×6),623(×1),654(×1),538(×5)` —— **总计 47 次呈现**（`full19` 为 `654(×2)`，总计 **48**）。

**判读**：
- 「切到 tab3 ⇒ **没有渲染趟被排**」**不成立**：`tab3` 稳态有 **5 次**呈现（`seq=44..48`），切换瞬间另有 **2 次**（`seq=42/43`）。
- 「`tab3` 帧＝同腿 `tab1` 帧（＝上一 tab 的残留）」**不成立**：`imgdiff` 差异 `66791` px、`BBOX (268,90,783,538)`，**全在文档区**；`tab1/tab2`（1039／724／具名色）与 `tab3`（562／148／`0/0/0/0`）**不同**。
- `tab2`（单页视图）那一格：**点击 `tab2` 不产生任何呈现**（`rev19` 序 `3,2,1,3` 现取：`s2_tab2_t1/t6` 与 `s1_tab3_t1` **逐字节同**）⇒ `tab1≡tab2` 帧是「**没排帧 ⇒ 屏上是上一帧**」，不是"两个视图长得一样"。
- `T-B17` §4.3 那条「开腿 `tab3` 帧逐字节＝`tab1` 帧」是 **旧 `.so`（`a7a0f884`）＋ `WPF_DPV_RTB_FALLBACK=1`** 的形态；`T-B18` 把 `E_HANDLE` 归零之后，**缺省腿上 `tab3` 帧就不再等于 `tab1` 帧**（`T-B18` §3.4 已记，本席独立复现）。

---

## §2 ①′ 现取：真断点 ＝ **页子树在成帧前被"搬空"**

### 2.1 托管侧：页视觉被接出、有内容、且**只被 set 一次**

新增**只读** `[DPHSET]` 探针（生成器内 `DPH_SET_REPL` 首行插入 `WpfLinuxPageViewProbe.ReportHostSetSeq(this, _pageVisual, value);`；env `WPF_DPH_SET_PROBE=1`）：

```
[DPHSET] seq=1 host=0x2a39255 old=null new=0x6386b same=0 oldParent=null oldKids=-1 oldBounds=null
                newKids=1 newBounds=-1.621,0,640.021,363.885 oldPS=null newPS=null NOINFO=dphsetseq-readonly
```

**整趟只有 1 次**（`set19` 腿现取），出现在 `tab3` 激活那一瞬间（该行 `L15623`；`tab3 sel=True` 首现 `L15700`；前一次呈现 `seq=40` 在 `L6800`）⇒ `DocumentPageHost.PageVisual` **没有被"清掉再挂"**。

同腿托管读数（`[DPV]/[DPH]`，`ProbeOn` 缺省开）：

```
[DPV] site=HostArranged view=0x… host=0x… hostRender=638.4x362.88 hostAt=0,0 hostOff=0,0 hostXf=258.24,107.52,1,1 hostKids=1
[DPH] site=Attach host=0x… pv=0x… mode=container pvParent=0x… pvContent=0,0,638.4,362.88 pvKids=1
      pvBound=-1.621,0,640.021,363.885 hostPS=0x28c5f3 pvPS=0x28c5f3 pvDepth=34
      SUB=L0:…,k=1,b=-1.621,0,640.021,363.885,c=0,0,638.4,362.88 | L1:…,k=2,b=-1.621,1.391,601.443,362.494 …
```

⇒ 页宿主在**文档区**（世界原点 `258.24,107.52`、尺寸 `638.4x362.88`）、页视觉**连到呈现源**、**有内容**；与「画得出的那条链」（`tab1` 的 `[FDV] site=Attach … pvXf=257.28,47.04,1,1 … L1:k=2,b=-1.621,1.391,601.443,362.494`）**结构同构**。

### 2.2 milcore 侧：树是**自洽**的（悬空子句柄 = 0），是**被摘走**

`WPFGFX_ROOTDIAG=1`（现有只读闸，`MilPresentation.cs:836`；本轮**追加**孤立子树规模读数）：

```
ROOTDIAG 通道2 target.Root=0x2 快照子=0 活投影子=1 镜像visual=627 从根可达=624 孤立=4
         [孤立 h=0x1 子树=1 带内容=0] [孤立 h=0x452 子树=1 带内容=1] [孤立 h=0x453 子树=2 带内容=1] [孤立 h=0x455 子树=3 带内容=2]
```

序列（`uniq -c`，`mil19_mut.log`，共 **48** 次）：`1(×1),34(×5),124(×2),405(×2),410(×1),415(×23),624(×6),623(×1),654(×2),538(×5)`。
**孤立恒为 4、最大子树只有 3 个节点** ⇒ 页视觉**不是"挂丢了"**。

**新读数（`WPF_LINUX_MIL_DANGLING=1`，`dang19b` 腿）**：`dangling=0`（全部 48 次呈现）—— 即"父的 `Children` 里列出的句柄在资源表里都还在" ⇒ **树是自洽的**，不是"资源被提前释放造成悬空"。

**逐节点 diff（`ROOTFULL`，`full19` 腿；`seq=42` vs `seq=43`）** —— 页视觉链（**句柄完全相同**）：

```
seq42: … d34 h=0x3e6(k=1) → d35 h=0x3e4(k=2) → { d36 h=0x3cc(k=1) → d37 h=0x3cb(k=1) → d38 h=0x3ca(k=3) → … d40 h=0x37e(k=14) → d41 h=0x37d(instr=1)
                                                  d36 h=0xe5(k=2)  → d37 h=0x44b(instr=1,k=2), h=0xe4(instr=1,k=2) }
seq43: … d34 h=0x3e6(k=1) → d35 h=0x3e4(k=2) → { d36 h=0x3cc(k=1) → d37 h=0x3cb(k=0)      ← 空
                                                  d36 h=0xe5(k=0)                            ← 空   }
```

⇒ **两个内容容器 `0xe5`（浮动元素）与 `0x3cb`（轨道）的子被摘走、且没接回来**；其余（左导航、tab 条、`tab3` 自身 chrome）**逐字节不变**。

同刻命令流（`mil19_mut.log` 现取）：
```
[preflight] 通道 2 待提交 #0: id=0x25 (MilCmdVisualRemoveChild) len=12 handle=0x000000e5 在资源表里=True
[preflight] 通道 2 待提交 #1: id=0x22 (MilCmdVisualSetContent) len=12 handle=0x000000e4 …
…
[preflight] 通道 2 待提交 #0: id=0x25 (MilCmdVisualRemoveChild) len=12 handle=0x000000e5 在资源表里=True
[preflight] 通道 2 待提交 #1: id=0x22 (MilCmdVisualSetContent) len=12 handle=0x0000044b …
```
⇒ 是**显式 `RemoveChild`**（不是释放），而且**没有对应的 `InsertChildAt` 接回**。

### 2.3 真因逐跳（件:行 ＋ 内容锚）

| 跳 | 件:行（现取） | 内容锚原文 | 说明 |
|---|---|---|---|
| 甲 | `PtsHelper.Linux.cs:302-316`（上游同源） | `Visual currentParent = VisualTreeHelper.GetParent(paraClient.Visual) as Visual; if(currentParent != null){ … parent.Children.Remove(paraClient.Visual); } … visualCollection.Insert(index, paraClient.Visual);` | **`fskupdNew` 支＝先"从旧父摘除"再 `Insert`**；跨页/跨容器沿用**同一个** `BaseParaClient.Visual` ⇒ **一个 `Visual` 只能有一个父** ⇒ **先造的那一页/那个容器被搬空** |
| 乙 | `PtsPage.Linux.cs:1066 UpdatePageVisuals` → `:1121 PtsHelper.UpdateTrackVisuals(PtsContext, trackVisual.Children, …)` ／ `:1168 UpdateFloatingElementVisuals(floatingElementsVisual, …)` | 页视觉 = `_visual.Children[0]`（`pageContentVisual`）＋ `[1]`（`floatingElementsVisual`）；轨道＝`pageContentVisual.Children[0]` | 被搬空的正是这两个容器（现取 `0x3cb`／`0xe5`） |
| 丙 | `PtsPage.Linux.cs:660 RedrivePageVisualsForDisplay()`（**`T-B12` 的修复体，本轮一字未改**） | `if (trackVisual != null && trackVisual.Children.Count == 0) { WpfLinuxPageVisDrive.ReparentInto(trackVisual, _pageContentKeep); }` ／ `if (floatingVisual != null && floatingVisual.Children.Count == 0) { ReparentInto(floatingVisual, _pageFloatKeep); }` | 修复体**在场且正确** |
| 丁 | `FlowDocumentPage.Linux.cs:101-118`（`T-B12` 的**挂钩**） | `public override Visual Visual { get { … UpdateVisual(); if (_ptsPage != null) { _ptsPage.RedrivePageVisualsForDisplay(); } return base.Visual; } }` | **挂钩点是"读 `Visual`"那一刻**（＝`DocumentPageView.ArrangeOverride` 里 `pageVisual = _documentPage?.Visual`）⇒ 此时容器**还没被搬空**（搬空发生在**布局之后、成帧之前**） |
| 戊 | **现取（关键反证）** | `grep -c "PTSP.RedrivePageVisuals" logs/*/app.log` ＝ **0**（11 趟腿、全部 env 组合） | ⇒ `T-B12` 的修复**在本形态下一次都没动手**（`did == false`） |
| 己 | `DocumentPageView.Linux.cs:496-504 GetVisualChild` | `protected override Visual GetVisualChild(int index) { … return _pageHost; }` | **渲染/命中遍历枚举页宿主的唯一出口**（现取 `[PAGEVIEW] site=DPV.GetVisualChild` 每趟数百次） |

**⇒ 断点归属**：不在 `T-B13/T-B16/T-B17` 找过的那一段（挂载、主题字典、视觉树可达、`E_HANDLE`），而在 **`T-B12` 修复的"挂钩时机"**：修复体挂早了一步。

---

## §3 ② 修：把同一条修复挪到**渲染遍历入口**（`P8`／可撤）

### 3.1 落点（件:行；只改 `build/PresentationFramework.Linux/**`）

| 件 | 改动 | 内容锚 |
|---|---|---|
| `reapply-patches.py` → `DPV_VISIT_REPL` | `DocumentPageView.GetVisualChild` 首部插一行（**调用点**） | `WpfLinuxPageViewProbe.RedrivePageVisuals(_documentPage);` |
| `reapply-patches.py` → 探针类块（`ReportHostSetSeq` 之后） | 新增 `internal static void RedrivePageVisuals(object page)`（拿 `MS.Internal.PtsHost.FlowDocumentPage`，转调轻量入口；**任何失败不重抛**） | 见生成件 `DocumentPageHost.Linux.cs:651` |
| `reapply-patches.py` → `FlowDocumentPage` 编辑表**首位** | 新增 `internal void RedrivePageVisualsOnly()`（**只跑修复体**；不读 native、不 `UpdateVisual`） | 见生成件 `FlowDocumentPage.Linux.cs:247` |

**核体（生成件现取）：**
```
DocumentPageView.Linux.cs:511      WpfLinuxPageViewProbe.RedrivePageVisuals(_documentPage);        // 渲染遍历入口
DocumentPageHost.Linux.cs:651      internal static void RedrivePageVisuals(object page) { … fdp.RedrivePageVisualsOnly(); }
FlowDocumentPage.Linux.cs:247      internal void RedrivePageVisualsOnly() { if (_ptsPage != null) { _ptsPage.RedrivePageVisualsForDisplay(); } }
```

**为什么是"挪"而不是"新造"**：`T-B12` 的修复体（`PtsPage.RedrivePageVisualsForDisplay` ＋ `WpfLinuxPageVisDrive.ReparentInto`）**语义正确、判据正确、闸正确**（只在容器**确已空**时动手）—— 唯一的问题是**它挂在了 `Arrange` 期**，而"搬空"发生在它**之后**。把它挪到**成帧遍历的入口**，等于让同一个修复体在**正确的时刻**跑。

**安全性（现取）**：
- `ReparentInto` 只改**更深两层**的容器（`trackVisual`／`floatingElementsVisual` 的 `Children`），**不动** `DPV`/`DPH` 的子数 ⇒ 枚举 `DPV.GetVisualChild` 期间不会改本层结构；
- 只在"**容器确已空**"时动手，否则**零动作**（幂等）；
- 闸沿用 `WPF_PAGEPAGE_REDRIVE`（**缺省开**；`=0` 即反极性回上游行为）；
- **不**改任何几何／native 真值；**不**删／**不**放宽任何 `Invariant.Assert`；**不**改 `T-B12` 原有挂钩（`FlowDocumentPage.Visual` getter 那一行**逐字保留**）。

### 3.2 幂等（`P8`，现取）

```
$ for f in reapply-patches.py DocumentPageHost.Linux.cs DocumentPageView.Linux.cs FlowDocumentReader.Linux.cs PresentationFramework.Linux.csproj; do sha256sum "build/PresentationFramework.Linux/$f"; done > /tmp/pf1.txt
$ python3 build/PresentationFramework.Linux/reapply-patches.py ; … > /tmp/pf2.txt
$ diff /tmp/pf1.txt /tmp/pf2.txt   ⇒  空        # IDEMPOTENT=OK
```

现取关键件 `sha16`：`reapply-patches.py=0e6f00d6b7015899`｜`DocumentPageView.Linux.cs=c86a1aaadc2c5092`｜`FlowDocumentPage.Linux.cs=ed8448cb9d408488`｜`DocumentPageHost.Linux.cs=f2ab652e1fc8fb8a`｜`MilPresentation.cs=8f4976ad60f5c7a1`｜`MilPresentProbe.cs=048532edda4cc784`｜**`bin/Release/PresentationFramework.dll=788ebcdbf9d2b241`（0 警告 0 错误）**｜`wpfgfx_cor3.so=e88f82233f53d1ea`。

---

## §4 ③ 真跑：成对读数 ＋ 反极性 ＋ 复现

### 4.1 腿表（现取；装置 `:239`；`sha16` ＝ 整屏 `import -window root`；`PUI` 恒 `a901772b7589382a`＝主题开）

| 腿 | `PresentationFramework.dll` | env／序 | `tab1` | `tab2` | **`tab3`** | `tab3` 文档区色数 | `tab3` 具名色 | `E_HANDLE` |
|---|---|---|---|---|---|---|---|---|
| `base19` | `c7732cc5` | 只读 ROOTDIAG+MIL_LOG | `c22457cf` | `c22457cf` | `71a93980` | 148 | `0/0/0/0` | 0 |
| `probe19` | `c7732cc5` | `PRESENT_ALL+ROOTGEO` | `c22457cf` | `c22457cf` | `71a93980` | 148 | `0/0/0/0` | 0 |
| `doc19`／`mut19`／`onscreen19`／`full19` | `c7732cc5` | ＋`ROOTDIAG`／`MIL_LOG`／`PAGEVIEW_ONSCREEN=1`／`ROOTFULL` | `c22457cf` | `c22457cf` | `71a93980` | 148 | `0/0/0/0` | 0 |
| `redoff19`（旧 PF，无新钩） | `c7732cc5` | `WPF_PAGEPAGE_REDRIVE=0` | `c22457cf` | `c22457cf` | `71a93980` | 148 | `0/0/0/0` | 0 |
| `set19` | `d5db329f` | `WPF_DPH_SET_PROBE=1` | `c22457cf` | `c22457cf` | `71a93980` | 148 | `0/0/0/0` | 0 |
| `dang19b` | `c7732cc5`（＋`.so=e88f8223`） | `PRESENT_ALL+DANGLING` | `c22457cf` | `c22457cf` | `71a93980` | 148 | `0/0/0/0` | 0 |
| **`fixa19`** | **`7f394ce7`（修）** | 序 `1,2,3` | `c22457cf` | `c22457cf` | **`5e7d5279`** | **731** | **`9449/842/16/5861`** | **0** |
| **`fixb19`** | `7f394ce7`（修） | 序 `1,2,3`（**复现**） | `c22457cf` | `c22457cf` | **`5e7d5279`** | **731** | **`9449/842/16/5861`** | **0** |
| **`fixc19`** | **`788ebcdb`（本席终态产物）** | 序 `1,2,3` | `c22457cf` | `c22457cf` | **`5e7d5279`** | **731** | **`9449/842/16/5861`** | **0** |
| **`pol19`（反极性）** | `7f394ce7`（修）＋**闸关** | `WPF_PAGEPAGE_REDRIVE=0` | `c22457cf` | `c22457cf` | **`71a93980`** | **148** | **`0/0/0/0`** | **0** |
| **`fixord19`** | `7f394ce7`（修） | 序 **`3,2,1`** | `o1=c22457cf` | — | **`o3=5e7d5279`** | — | — | 0 |

### 4.2 判据（三项全成立）

| 判据 | 修前（`c7732cc5`） | **修后（`788ebcdb`）** | 判 |
|---|---|---|---|
| `tab3` 内容区**色数回升** | 文档区 **148** 色（整屏 562） | **文档区 731 色（整屏 1043）** | **成立** |
| `tab3` **具名色出现** | `GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0` | **`GhostWhite=9449 Beige=842 DarkGreen=16 LightGoldenrodYellow=5861`** | **成立** |
| `tab3` 帧 `sha16` **变** ∧ **≠ `tab1` 帧** | `71a93980be1f49a6`（≠`c22457cf`） | **`5e7d5279f9b7e4e3`**（≠`c22457cf663453dd`） | **成立** |
| **不得回退 `tab1`** | `c22457cf`／724／`9831/910/44/5830` | **逐字节同**（`c22457cf663453dd`／724／同） | **零回归** |
| **不得回退 `tab2`** | `c22457cf`／724／同 | **逐字节同** | **零回归** |
| `docContent`（milcore 同口径） | **6**（tab1 为 46） | **47**（＝tab1 量级） | **成立** |
| `[PAGEVIS] site=PTSP.RedrivePageVisuals` | **0 次**（11 趟腿） | **8 次**（`fixa19`） | 修复体**真跑** |

### 4.3 反极性 ＋ 复现（现取）

- **反极性**：`WPF_PAGEPAGE_REDRIVE=0`（修后产物）⇒ `tab3` 帧 **逐字节回** `71a93980be1f49a6`、文档区回 **148**、具名色回 **`0/0/0/0`**（`pol19`）⇒ **成立**。
- **复现**：`fixa19`／`fixb19`／`fixc19` 三腿（两个不同产物）`tab3` 帧 **逐字节同** `5e7d5279f9b7e4e3` ⇒ 稳定。
- **序对照**：`fixord19`（`3,2,1`）先点 `tab3` ⇒ `o3_t6=5e7d5279f9b7e4e3`（页**真上屏**），随后点 `tab1` ⇒ `o1_t6=c22457cf663453dd`（**未回退**）。对照 `T-B18` §3.1 同序（旧形态）：`o3=71a93980`（空白）⇒ **同一序下 `tab3` 由"空白"变"有内容"**。

---

## §5 ④ 门禁（逐条现取；本席跑的）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| awk '{print $3}' \| sort` vs `src/WpfGfx.Linux.Native/bin/exports.txt` | **`846 == 846`**，`diff -q` 空 ⇒ `NM_EQ_EXPORTS=PASS` |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5f9ed647c68197ae exports=846`**；`PTSGAP_CITED=PASS refs=1 strict=1`；rc=0 |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- direction=in-file phase=realized`**；`PTS_N1_GATE=PASS`；`PTS_ENFE=PASS total=0` |
| `PTS_COLORANCHOR` | 同上（`k=24`） | **`PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 min=200 base=全部0`**（**未回退**）；`k=23` `NOINFO(no-anchor-registered-for-k23)` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0`，rc=0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=367 ids=2266 declared=225`**，rc=0 |

**未跑**：整趟 `verify-all`（照派单 ②）；`static-jaws-check.sh`。

---

## §6 ⑤ 症状门（成对）

| 症状门 | `base19`（修前） | `fixa19`（修后） | `fixb19` | `fixc19`（终态） | `pol19`（反极性） | `fixord19` |
|---|---|---|---|---|---|---|
| `magenta` | 0 | 0 | 0 | 0 | 0 | 0 |
| `Unrecoverable system error` | 0 | 0 | 0 | 0 | 0 | 0 |
| `PTS_GAP entry=` | 0 | 0 | 0 | 0 | 0 | 0 |
| `[FORMATLINE-LINE]` | 156 | 156 | 156 | 156 | 156 | 156 |
| `[HC-UNHANDLED]` | 566 | 449 | 543 | 459 | 434 | 505 |
| 其中 **`COMException`＋`0x80070006 (E_HANDLE)`** | **0** | **0** | **0** | **0** | **0** | **0** |
| `FailFast` | 95 | 74 | 91 | 78 | 72 | 85 |
| `alive`／`app_rc` | yes／143 | yes／143 | yes／143 | yes／143 | yes／143 | yes／143（均**本席按 PID 收**） |
| `colors`（整屏；`tab3`） | 562 | **1043** | **1043** | **1043** | 562 | **1043** |

> `[HC-UNHANDLED]`／`FailFast` **逐腿波动**（413–571／70–95），与"修／不修"**无单调关系** ⇒ 如实划界，不归因（＝`T-B18` §6.4 同一形态）。

---

## §7 断点归属 · 本轮更正 · `NOINFO`

### 7.1 本轮**已逐条排除/更正**（都真跑过）

| 假设 | 现取结论 |
|---|---|
| 「`tab3` 宿主进场后**没有渲染趟被排**」（`T-B17` §7.2 判词） | **否证**：47–48 次呈现，`tab3` 占 6–7 次；帧由 `c22457cf` 变到 `71a93980`。§1 |
| 「`tab3` 帧＝同腿 `tab1` 帧（上一 tab 残留）」 | **否证**：差异 `66791` px、全在文档区；`tab1/tab2` 与 `tab3` 帧不同。§1.2 |
| 「页视觉**没挂进渲染树**」 | **否证**：`ROOTDIAG 孤立=4`（最大子树 3 节点，页视觉不在孤立集里）；`[DVBI] ReaderPageViewer n=1`。§2 |
| 「页视觉**没有内容**」 | **否证**：`[DPH] pvContent=0,0,638.4,362.88`；与画得出的 `[FDV]` 链**结构同构**。§2.1 |
| 「`PageVisual` setter 把页视觉"清掉再挂"」 | **否证**：`[DPHSET]` 整趟**只 1 次**（`old=null → new=0x6386b`），此后未再被调。§2.1 |
| 「资源被提前释放 ⇒ 子句柄悬空」 | **否证**：新读数 **`dangling=0`**（全部 48 次呈现）；树**自洽**。§2.2 |
| 「`T-B12` 的修复体本身不对」 | **否证**：修复体**一字未改**，只是**挂钩时机**不对；挪到成帧入口即生效。§3 |
| 「`E_HANDLE` 是阻断者」 | **再证伪**（承 `T-B17`/`T-B18`）：本增量全部腿 `E_HANDLE=0`。§6 |

### 7.2 具名前置（**本轮已解除**）

- **`PRECOND-TAB3-PAGE-RENDER`：本轮已解除**。
  - **原状**：分页页宿主（`DocumentPageView`/`DocumentPageHost`）在 `tab3` 上"宿主已接出、已 `Arrange`、渲染树可达、托管子树有绘制，但**成帧前页子树被搬空**（容器 `k=0`）" ⇒ 文档区只剩 chrome。
  - **现取（解除判据）**：文档区 `148 → 731`、具名色 `0/0/0/0 → 9449/842/16/5861`、帧 `71a93980 → 5e7d5279` 且 ≠`tab1`；`docContent 6 → 47`；`[PAGEVIS] site=PTSP.RedrivePageVisuals` **0 → 8 次**。
  - **反极性**：`WPF_PAGEPAGE_REDRIVE=0` ⇒ 逐字节回 `71a93980`／148／`0/0/0/0`。
- **`PRECOND-WIC-RTB`（`T-B18` 已解除）**：`E_HANDLE=0`（本增量 6 趟腿），**未回退**。

### 7.3 `NOINFO`（具名）

- **`NOINFO-TB19-DEMO-VARIANCE`（承接 `T-B17`/`T-B18`）**：hc demo 的帧**不是** `(产物, env, 序)` 的纯函数（同一产物同一 env 会给出两种 `tab1` 变体）。⇒ **不回归判据只采"同腿/同序对照"**，**不**跨趟比 `sha16` 绝对值。
- **`NOINFO-TB19-TAB2-NOPRESENT`**：点击 `tab2`（单页视图）**不产生任何呈现**（`rev19` 实测：点后 1 s／6 s 两帧都与前一张**逐字节同**）。**未做进一步归因**（不影响 `tab3` 判据：`tab3` 有独立呈现，且修后 `tab2` 帧**仍逐字节未变**）。
- **`NOINFO-TB19-REDRIVE-HOOK-COST`**：新挂钩落在 `DocumentViewBase` 的渲染/命中遍历出口上，**每趟遍历每页 1 次**；本席**只做"容器确已空才动手"的早退**，未做逐次计时（如实划界）。
- **`NOINFO-TB19-PAGEFRAME-LEDGER`**：`[QPD] … vis_built=0` 全趟 1755/1756 为 0（只 1 次 `=1`）；该位语义（`src/WpfGfx.Linux.Native/src/win32_pts.c:9346` `pg->qpd_vis_built = 1;`）与"页视觉到没到通道"的关系**本轮未定** ⇒ 不拿它下判。

---

## §8 边界 · 收净 · 自证

1. **写域（现取 `git status --porcelain`）**：
   ```
    M build/PresentationFramework.Linux/reapply-patches.py          ← 生成器（[DPHSET] 只读块 ＋ 新钩 ＋ FlowDocumentPage 轻量入口）
    M build/PresentationFramework.Linux/DocumentPageView.Linux.cs   ← 生成件（GetVisualChild 调新钩）
    M build/PresentationFramework.Linux/FlowDocumentPage.Linux.cs   ← 生成件（RedrivePageVisualsOnly）
    M build/PresentationFramework.Linux/DocumentPageHost.Linux.cs   ← 生成件（RedrivePageVisuals）
    M src/WpfGfx.Linux/Interop/MilPresentation.cs                   ← 1 行只读调用 ＋ DumpRootDiag 追加孤立子树读数
    ?? src/WpfGfx.Linux/Interop/MilPresentProbe.cs                  ← 新只读探针（缺省关）
    ?? build/MilBridge/P1-hctab3c-impl-report.md                    ← 本载体
    ?? build/MilBridge/tasks-tail2/T-B19.md                         ← 任务件（开工前就在，未跟踪）
   ```
   **无** `upstream/**`、**无** `src/WpfGfx.Linux.Native/**`、**无** `build/MilBridge/tools/**`、**无** `verify-all.sh`／`build/close-wave.sh`。
2. **副本先行／写前备份**：`src/WpfGfx.Linux/Interop/MilPresentation.cs` 的 `cp -p` **取在任何写之前**（`~/tb19-work/bak/MilPresentation.cs.orig=5b9913e812ee0474`）。其余改动件**全部是 git 跟踪件**，开工基线可逐件取回（现取）：
   `reapply-patches.py=8ecc49dfad77f782`｜`DocumentPageView.Linux.cs=36e6fc82803767f1`｜`FlowDocumentPage.Linux.cs=2630c4d441f403d6`｜`DocumentPageHost.Linux.cs=c38aa683ad96a207`（`reapply-patches.py` 与 `DocumentPageHost.Linux.cs` 与其在 `T-B17` §3 的在册值一致）。落地后副本另存 `~/tb19-work/bak/*.fix`。
3. **app-local（现取，收净后）＝ 仓内权威件逐件一致**：
   `libwpfwin32.so=5f9ed647c68197ae`（未动）｜**`wpfgfx_cor3.so=e88f82233f53d1ea`**（＝本轮 publish 产物）｜`PresentationCore.dll=eb3f61e282265518`（未动）｜**`PresentationFramework.dll=788ebcdbf9d2b241`**（＝本轮构建产物）｜`WindowsBase.dll=05bdde9b5527bfde`（未动）｜`PresentationUI.dll=69136eecc84aa9f5`（收净回缺省关位）。
4. **进程／显示位按 PID 收净**：`:239` 的 `Xvfb`／`xfwm4` 自起自收（末代 PID `3673056`／`3673060` 已收）；14 趟腿的 `HandyControlDemo` 全部按 PID 收（`APP_RC=143`＝本席 `kill`）。现取 `ps` **无任何 `Xvfb`／`HandyControlDemo`**、`/tmp/.X11-unix/` 只剩非本席的 `X0`／`X1`／`X11`。另有一个 `xfwm4(2617727)` **不是本席**（10-02 起，开工前已在），**未动**。
5. **构建**：`dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -c Release -m:1`（**0 警告 0 错误**，`held≈21 s`，产物 `788ebcdbf9d2b241`）→ `bash build/publish-milbridge.sh`（AOT publish，产物 `e88f82233f53d1ea`）。
6. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑**整趟 `verify-all`。**未** `git add/commit/push`。
7. **纪律自证**：重活走槽（14 趟腿 ＋ 5 次构建/发布，全部 `ACQUIRED…RELEASED rc=0`）；显示位只用空闲 `:239`；`temp+rename`（生成器 `_write_atomic`，本载体亦如此落盘）；**报数一律现取**（纪律 40）；**接线可撤**（**行为**改动的闸＝`WPF_PAGEPAGE_REDRIVE`（缺省开，`=0` 即反极性）；只读仪器 **4 个 env，全缺省关**）；**仪器不扰动**（同 env 两腿帧**逐字节同**）；**未伪造几何／台账**；**未假成功**（先如实记"三项判据不成立"，改到成立后才改写判词，并给出反极性与两次逐字节复现）；**方案数 = 3**（≤3：`PAGEVIEW_ONSCREEN` 直挂／`REDRIVE=0` 撤旧驱动／**把修复挪到成帧入口**）。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hctab3c-impl-report.md | sha256sum | cut -c1-16`）＝ **`fb5429c5a030fe22`**（本行下方无内容，取该行之前全文的哈希）。

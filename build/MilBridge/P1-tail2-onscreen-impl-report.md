# `P1-tail2` · `T-A45` · 内容段行视觉「上屏」（`LINEVIS-ON-SCREEN`）—— 实现报告（**判决：判据 ② 达（`hits 1→2`）∧ 断点已定位并修 ∧ 反极性成立 ∧ 症状门零回归；`LightGoldenrodYellow` 仍缺（具名下一靶）**）

- **读时**：`2026-09-30T19:4x–19:5x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=ed46627`（＝ `T-A44` 那笔；**未换代**）。
- **改前件备份（仓外 `~/tA45-work/bak/`，`cp -p`，取在**任何写之前**）**：`reapply-patches.py`（`68381ffcb7d2bf7e`）／`FlowDocumentFormatter.Linux.cs`（`8af2d392cead9d94`）／`TextParaClient.Linux.cs`（`5cd1666167e29339`）／`PresentationFramework.Linux.csproj`（`7dbfcb274d587ba4`）／`PresentationFramework.dll`（`27f07a325da4583c`）／`libwpfwin32.so`（`5b7d0ac101673900`）／`exports.txt`（`860a3abe4a64f1c5`）／`win32_pts.c`（`826c896ebe77e917`）。
- **只改**：`build/PresentationFramework.Linux/reapply-patches.py`（生成器）／由其重产的**生成件**（`TextParaClient.Linux.cs`／`FigureParaClient.Linux.cs`／`FlowDocumentFormatter.Linux.cs`，全部走生成器的 `temp+fsync+os.replace`）／**新建载体** 本件。**未碰** `src/WpfGfx.Linux.Native/src/win32_pts.c`（现取 `sha16` 仍 `826c896ebe77e917`、`.so` 仍 `5b7d0ac101673900`、`exports.txt` 仍 `860a3abe4a64f1c5` ⇒ **native 本轮一个字节未动**）／**未碰** `upstream/**`（只读）。
- **黑名单遵守**：未动 `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`；未改相位；未 `git add/commit/push`。
- **重活**：**4 趟托管构建**（`0 警告 0 错误`，各 `20–25 s`）＋ **4 趟跑器**（共 **8 条腿**；全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`，逐腿 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED`，`held=20/21/25/36s`）；进程只按 PID；显示位 `:231`（装置自取；逐腿 `DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p` 备份；模式守恒。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`grep -c`／只读 `python3`＋`PIL` 解 PNG／`bash build/MilBridge/tools/{pts-pages-guard,pts-gap-count-check,defect-registry-check,report-id-domain-check}.sh`）；`T-A44` 报告**只作对照**，其读数一条未抄。

---

## §0 结论速览（自包含）

1. ✅ **第一处断点已定位（件:行 ＋ 原文 ＋ 现取读数）**：
   - **在屏的是什么**：`FlowDocumentDemo` 的**缺省页签**是 `FlowDocumentScrollViewer`（现取 `[GEO] TabItem hdr=流文档滚动视图 sel=True`；另两页签 `hdr=流文档单页视图`／`hdr=流文档查看器` 均 `sel=False`）⇒ 它走的是**底流**：`FlowDocumentFormatter.Format`（其文档注释逐字：「**Bottomless** content formatter associated with FlowDocument」）→ `FlowDocumentPage.FormatBottomless` → native `FsCreatePageBottomless`（现取 `[FSVIEW] site=ArrangeOverride scroll=1`）。
   - **底流窗里 `<Figure>` 不是 Figure**：`TextParagraph.GetAttachedObjects`（上游 `TextParagraph.cs:943`，条件逐字 `if(textElement is Figure && StructuralCache.CurrentFormatContext.FinitePage)`）在**非有限页**把 `<Figure>` 走 `else` 支 ⇒ 建 `FloaterParagraph` ＋ `FloaterObject` ⇒ 现取 `[FSATT-PROBE] where=FsCreatePageBottomless … att0_id=2`（＝`PtsHost.FloaterParagraphId`）**对** `where=FsCreatePageFinite … att0_id=-2`（＝`PTS.fsidobjFigure`）。
   - **Floater 内容在底流无路径**：托管 `FloaterParagraph.FormatFloaterContentBottomless`（`FloaterParagraph.cs:361`）**只**由 native `FSFLOATERCBK.pfnFormatFloaterContentBottomless` 驱动，而该表要靠 `pfnGetObjectHandlerInfo`＋`PTS.GetFloaterHandlerInfo` 取得 —— 本移植的 `GetFloaterHandlerInfo` 是**具名 GAP**（`win32_pts.c` 现取：`return wpf_pts_gap("GetFloaterHandlerInfo");`）⇒ **内容子页永不建**（现取 `[FS_ATT] FsQuerySubpageDetails subpage=(nil) … src=handle-unset(attached-content-not-laid-out)`，底流腿 15 条）⇒ 在屏页的附属对象**只有背景**。
   - ⇒ **承 `T-A44` 的 `NOINFO-LINEVIS-NOT-ON-SCREEN` 收到一句**：`T-A44` 的驱动（`FlowDocumentPaginator.FormatPage` 之后补 `EnsureValidVisuals`）把内容段的行视觉建在**分页器的有限页**上，而那些页**从不在屏**（现取 `[FSVIEW]` 只在 `FlowDocumentView` 上打点，分页器页无在屏消费者）⇒ **「行视觉已建」与「上屏」之间的那一跳是：在屏页根本没进过有限窗**。
2. ✅ **修法（两处，均在生成器／生成件；`WPF_LINEVIS_ONSCREEN=0` 可整点撤掉）**：
   - **①在屏页＝有限页**：`FlowDocumentFormatter.Format` 里把 `_documentPage.FormatBottomless(pageSize, pageMargin)` 换成（闸内）`WpfLinuxOnScreenDrive.Format(...)` ⇒ `_documentPage.FormatFinite(finiteSize, pageMargin, null)`（页高 `max(constraint.Height, 2000)`）。⇒ 在屏那**同一份文档**首次进 `FsCreatePageFinite`，native 的**附属对象内容排版**（`FsCreatePageFinite` 窗内 `pfnGetFigureProperties`，承 `T-A37`）**真造子页**（现取 `[FSATT-CONTENT] … v=SUBPAGE-CREATED` 由 1 条变 2 条）。
   - **②文本段落的背景视觉落位**：`TextParaClient.ValidateVisual` 里补**同形**一行 `_visual.DrawBackgroundAndBorder(...)`（`Background` 非空才调）—— 因为 `TextParaClient` 现取**从不调**该面（全仓 `grep -rn 'DrawBackgroundAndBorder' upstream/**/PtsHost/` 逐条现取：只被 `Figure`/`Floater`/`List`/`Container`/`Subpage`/`Table`/`UIElement` 七个客户端调用）⇒ `<Paragraph Background="Beige">` 的背景**无任何挂点**。
3. ✅ **判据 ② 达（关键）**：`PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200 base=…all-0` ⇒ **`hits 1→2`**（`Beige` 0→**910 px**、`DarkGreen` 0→**44 px**）；`boot.png` 仍**四色全 0**（`all_zero=yes dead=none`）。⇒ 判据字面（`expect_hits=2`）**成立**。
4. ✅ **反极性（同一 `.so` ＋ 同一跑器 ＋ 同一装置 ＋ 同一 `pf`，只差一个 env）**：`WPF_LINEVIS_ONSCREEN=0`（`pol0`）⇒ `[CHAIN] ONS.FormatFinite`／`TPC.ParaBackground` **全 0**、`k24` 回 **`2d89d393157b0df6`**、`GhostWhite=29667 Beige=0 DarkGreen=0 hits=1` ⇒ `PTS_COLORANCHOR=FAIL`；`boot`／`k23` 逐字节同值。**两态可分**。
5. ✅ **症状门零回归**：三腿（`base`／`ons3`／`pol0`）`alive=yes app_rc=143 failfast=0 unrec=0 magenta=0 ink=480000 ns=…FlowDocumentDemo`、`[HC-UNHANDLED]=1`（**未涨**）、`pts_unavail=0 pts_gap=0`；`boot.png` 三腿同值 `b21eb530afd3c66c`（四色全 0）、`k23` 三腿同值 `10d0b9d54e649c10`。
6. ✅ **门禁（④）**：生成器**幂等**（连跑两次，`*.Linux.cs` ＋ `csproj` 的合并 `sha16` 两次同值 `ec5ec36b1a86e56b`）；`nm -D --defined-only` ＝ `exports.txt` ＝ **683**（逐名 `diff` 零差异）；`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=5b7d0ac101673900 exports=683`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`／`DECLDRIFT=0`（rc=0）；`REPORTID=PASS files=323 …`（rc=0；落盘前，落盘后 324）。
7. 🔴 **未达（如实）**：`LightGoldenrodYellow` 仍 **0 px**（它在 `<Floater>` 内 `<Table>` 的 `<TableRow Background=…>` 里）—— 该支需要 **native `FSFLOATERCBK`（`GetFloaterHandlerInfo` 现在是具名 GAP）**，属**下一增量**；`PTS_GUARD` 仍有 4 条**改前既有**红（`leg24/23-placeholder-missing`：洋红占位自 `T-A33` 起就不存在、`native-ledger-absent`），本增量**一条未新增**（详见 §4）。

---

## §1 第一处断点（逐跳，件:行 ＋ 原文 ＋ 现取）

### 1.1 在屏宿主 ＝ 底流 `FlowDocumentScrollViewer`

| 面 | 现取（本席） |
|---|---|
| 页签身份 | `[GEO] TabItem#- scr=268,82 wh=165x27 … hdr=流文档滚动视图 sel=True`；`hdr=流文档单页视图 sel=False`；`hdr=流文档查看器 sel=False` |
| 宿主视图 | `[FSVIEW] site=ArrangeOverride doc=1 suspend=0 scroll=1 … arrange=638.4x366.72`（`scroll=1` ⇒ `_scrollData != null`） |
| formatter | `FlowDocumentFormatter.Linux.cs` 头部逐字：`Description: Bottomless content formatter associated with FlowDocument.`；`Format()` 内逐字 `_documentPage.FormatBottomless(pageSize, pageMargin);` |
| native 窗 | `[FORMATLINE] where=FsCreatePageBottomless …`（在屏那几趟）／`where=FsCreatePageFinite …`（分页器那几趟） |

### 1.2 底流窗里 `<Figure>` 被改判成 `Floater`（**本件承重的一跳**）

上游 `TextParagraph.GetAttachedObjects`（内容锚：`if(textElement is Figure && StructuralCache.CurrentFormatContext.FinitePage)`）：
有限 ⇒ `new FigureParagraph(...)`＋`FigureObject`（`rgidobj = PTS.fsidobjFigure` ＝ **-2**）；否则 ⇒ `new FloaterParagraph(...)`＋`FloaterObject`（`rgidobj = PtsHost.FloaterParagraphId`）。

现取（同一趟 `ons3`，两条 probe 行逐字并列）：

```
[FSATT-PROBE] where=FsCreatePageBottomless para=0x8 i=7 pfsline=0x13 rcNum=0 rcObj=0 cAtt=2 … att0_obj=0x14 att0_id=2  att0_rc=0
[FSATT-PROBE] where=FsCreatePageFinite     para=0x8 i=7 pfsline=0x13 rcNum=0 rcObj=0 cAtt=2 … att0_obj=0x14 att0_id=-2 att0_rc=0
```

⇒ 同一 `<Figure>`：底流窗 `id=2`（Floater）、有限窗 `id=-2`（Figure）。

### 1.3 底流支的内容排版**没有信道**（具名 GAP）

- 托管：`FloaterParagraph.cs:361 FormatFloaterContentBottomless(...)` → `CreateSubpageBottomlessHelper` → `PTS.Validate(PTS.FsCreateSubpageBottomless(...))`。
- native 现取：`grep -n 'GetFloaterHandlerInfo' src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ `3443:int GetFloaterHandlerInfo(...) { … return wpf_pts_gap("GetFloaterHandlerInfo"); }`（**且 `FsCreateSubpageBottomless` 不在 `bin/exports.txt` 内**）。
- ⇒ **`FSFLOATERCBK` 拿不到 ⇒ `pfnFormatFloaterContentBottomless` 永不发调 ⇒ 底流内容子页永不建**。
- 现取（`ons3`，底流在屏页那一段）：`[FS_ATT] rc=0 entry=FsQuerySubpageDetails subpage=(nil) fSimple=0 cBasicColumns=0 src=handle-unset(attached-content-not-laid-out)`；`[FS_TLB] … attached-objects=present … figure=1 floater=1` 但**子页为 `(nil)`** ⇒ 托管 `FloaterParaClient.ValidateVisual` 走 `emptySubpage` ⇒ `_visual.Children.Clear()` ⇒ **只剩 `Background`（`GhostWhite`）**。

### 1.4 ⇒ 为什么 `T-A44` 的行视觉「已建却零像素」

`T-A44` 的驱动点在 `FlowDocumentPaginator.FormatPage`（**分页器**那条宿主路径）⇒ 它建起来的行视觉挂在**分页器的 `DocumentPage`** 上，而那些页的 `DocumentPageVisual` **不在在屏视觉树里**（现取：`[FSVIEW]` 只由 `FlowDocumentView.ArrangeOverride` 打点、`scroll=1`；本代 `[CHAIN] FDG.Arrange` 逐尺寸现取 `638.4x366.72 ×1`／`394.56x283.2 ×1`（**在屏**）与 `816x1056 ×2`（**分页器**，`[CHAIN] DRIVE.EnsurePageVisuals` 同数 `2`）**分属两条链**）⇒ **「挂了，但挂在离屏的那棵树上」** ＝ 挂点错位。

### 1.5 反极性（每条判据带反极性）

| 判据 | 正极（`ons3`） | 反极（`pol0`，只差 `WPF_LINEVIS_ONSCREEN=0`） | 改前基线（`base`＝`T-A44` 产物） |
|---|---|---|---|
| `[CHAIN] site=ONS.FormatFinite` | **2** | **0** | ——（无此面） |
| `[CHAIN] site=TPC.ParaBackground` | **3** | **0** | ——（无此面） |
| `[CHAIN] site=FIG.ValidateVisual` | **3** | **2** | 2 |
| `[FSATT-CONTENT] … v=SUBPAGE-CREATED` | **2** | **1** | 1 |
| `[FS_ATT] FsQuerySubpageDetails … attached-content-not-laid-out` | **11** | **15** | 15 |
| `[TPCL] site=RenderSimpleLines`（总数） | **13** | **9** | 9 |
| `[FSQLL] cLines=1` | **3** | **2** | 2 |
| `k24` 帧 `fr_sha` | **`791696291d51470b`** | **`2d89d393157b0df6`** | `2d89d393157b0df6` |
| `PTS_COLORANCHOR` | **`PASS hits=2`**（`Beige=910 DarkGreen=44`） | **`FAIL hits=1`**（`Beige=0 DarkGreen=0`） | `FAIL hits=1` |
| 症状门 | 逐格同 | 逐格同 | 逐格同 |

⚠️ **判别器自身不改像素**：`base` 与 `pol0` 是**两个不同产物**（`pf=27f07a325da4583c` vs `b6d6575dbca4f714`），但 `pol0` 与 `base` 的 `k24`／`boot`／`k23` **逐字节同值**（`2d89d393157b0df6`／`b21eb530afd3c66c`／`10d0b9d54e649c10`）⇒ 「本趟新增的只读面（`FIG.Geom`／`RenderSimpleLines.Geom`）不比它的读数更能影响结果」。**真正的两极对比**是 `ons3` ↔ `pol0`（**同一产物 `b6d6575dbca4f714`**）。

---

## §2 改动（逐处）

### 2.1 生成器 `reapply-patches.py` 的三处新增（全部**只在生成器里**，生成件随之重产）

| 项 | 落点 | 内容 |
|---|---|---|
| **驱动（行为）** | `CHAIN_FILES` 的 `MS/Internal/documents/FlowDocumentFormatter.cs` 条目 ＋ 新常量 `ONS_FORMAT_NEEDLE/REPL`、`ONS_TAIL_NEEDLE/REPL` | `Format()` 里那一行 `_documentPage.FormatBottomless(pageSize, pageMargin);` ⇒ `WpfLinuxOnScreenDrive.Format(pageSize, constraint, pageMargin, _documentPage);`；文件尾追加 `internal static class WpfLinuxOnScreenDrive`（闸 ＋ 只读台账 `[CHAIN] ONS.FormatFinite w=… h=…`） |
| **驱动（行为）** | `TPC_E_VV_REPL`（`TextParaClient.ValidateVisual` 入口） | 在其判别器之后追加**段落背景落位**块（`Background` 非空才调 `DrawBackgroundAndBorder`）＋ 只读台账 `[CHAIN] TPC.ParaBackground` |
| **只读几何判别器** | `TPC_EDITS` 新增 `TPC_E_LINEGEOM_*`（`RenderSimpleLines` 内 `LineListSimpleFromTextPara` 之后）／`CHAIN_FILES` 的 `FigureParaClient` 条目新增第 3 处（`FigureParaClient.ValidateVisual` 的 `clipRect` 之前） | `[TPCL] RenderSimpleLines.Geom urStart/vrStart/dur/asc/desc/rect…`；`[CHAIN] FIG.Geom rect/content/padding/clip/off0` |

- **每处改动都可复核**：`_apply_edits` 的 needle 命中数校验**全部命中**（生成时逐件打印 `[OK] … needle 全部命中`：`TextParaClient 7 处`／`FigureParaClient 3 处`／`FlowDocumentFormatter 3 处`）。
- **落盘原子化**：生成件与 `csproj` 一律走既有的 `_write_atomic`（`temp + fsync + os.replace`）。
- **`WpfLinuxOnScreenDrive.Format` 逐字**（生成件 `FlowDocumentFormatter.Linux.cs`）：
```csharp
        internal static void Format(Size pageSize, Size constraint, Thickness pageMargin, FlowDocumentPage page)
        {
            if (!WpfLinuxChainProbe.EnvOn("WPF_LINEVIS_ONSCREEN"))
            {
                page.FormatBottomless(pageSize, pageMargin);      // 反极性腿：逐字回上游
                return;
            }
            Size finiteSize = pageSize;
            double height = constraint.Height;
            if (double.IsNaN(height) || double.IsInfinity(height) || height < MinimumPageHeight) { height = MinimumPageHeight; }
            finiteSize.Height = height;
            WpfLinuxChainProbe.Hit("ONS.FormatFinite", "w=" + … + " h=" + …);
            page.FormatFinite(finiteSize, pageMargin, null);       // 起始断行记录 null ＝ 第一页
        }
```

### 2.2 为什么**不是** native（本轮的写域与判据所逼）

- 本轮 native 是**只读判别器**（任务 ②）：本席**未改** native **一个字节**（`win32_pts.c`／`.so`／`exports.txt` 三件 `sha16` 逐字节未变，见 §5）。
- 而**接管断点所需的一切机制在托管侧已经齐备**：有限窗的附属对象内容排版（`T-A37` 落地：`FsCreateSubpageFinite` ＋ 窗内 `pfnGetFigureProperties`）＋ 在屏 `EnsureValidVisuals`／`UpdateViewport`（上游次序）＋ `ParagraphVisual` 的背景绘制面。⇒ 只差「在屏页要进有限窗」与「文本段落要调背景面」两处**挂点**。

### 2.3 零假值（逐条）

- **不伪造几何**：`fsrc`／`dvrUsed`／附属对象盒／子页盒**一字未动**（`FIG.Geom` 现取 `rect=32095,2095,37810,10810 content=34190,4190,33620,6620 clip=-2095,-2095,37810,10810` —— 全是 native 声明的原值）。
- **不置 native 真值**：不置 `fLinesComposite`／`fUpdateInfoForLinesPresent`；不删／不放宽任何 `Invariant.Assert`（`FigureParagraph.GetFigureProperties` 的 `Invariant.Assert(StructuralCache.CurrentFormatContext.FinitePage)` **照旧响亮** —— 而本趟它**确实成立**，因为走的就是有限窗）。
- **反极性**：`WPF_LINEVIS_ONSCREEN=0` ⇒ `FormatBottomless` ＋ 背景块整块不发生 ⇒ 逐字回上游行为（`§1.5` 现取）。

### 2.4 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `build/PresentationFramework.Linux/reapply-patches.py` | `68381ffcb7d2bf7e` | **`3e745f179cf63913`** |
| `…/FlowDocumentFormatter.Linux.cs`（生成件） | `8af2d392cead9d94` | **`5270d9391aa9bce4`** |
| `…/TextParaClient.Linux.cs`（生成件） | `5cd1666167e29339` | **`3ed7b9011b0b2dc8`** |
| `…/FigureParaClient.Linux.cs`（生成件） | `e62991bd4d301cfc`（`T-A44`） | **`9364faea7ce43e1d`** |
| `…/PtsCache.Linux.cs`／`FlowDocumentPage`／`PtsPage`／`PtsHelper`／`ContainerParaClient`／`FlowDocumentPaginator`／`FlowDocumentView`／`WpfLinuxChainProbe`（生成件） | —— | **未变**（生成器幂等；`git status` 现取只列 3 件 `.Linux.cs` ＋ 生成器） |
| `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` | `7dbfcb274d587ba4` | **`7dbfcb274d587ba4`（未变）** |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `27f07a325da4583c`（6,142,464 B） | **`b6d6575dbca4f714`**（6,144,512 B） |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `826c896ebe77e917` | **`826c896ebe77e917`（未变）** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `5b7d0ac101673900` | **`5b7d0ac101673900`（未变）** |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `860a3abe4a64f1c5` | **`860a3abe4a64f1c5`（未变）** |

---

## §3 成对读数（**同一装置 `:231`／同批工具**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；A 臂 `clicks=[24,23]`；证据 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2k/`）

| 腿 | `pf` `sha16` | 含义 | 证据目录 |
|---|---|---|---|
| `base` | `27f07a325da4583c` | **改前基线**（＝ `T-A44` 产物；`HEAD`） | `…/base/` |
| `ons3` | **`b6d6575dbca4f714`** | **本趟产物 ＋ 驱动开** | `…/ons3/` |
| `pol0` | 同 `ons3` | **反极性腿**：`WPF_LINEVIS_ONSCREEN=0` | `…/pol0/` |

### 3.1 逐腿现取计数（`app_g1.log`，只读 `grep -c`）

| 量 | `base` | **`ons3`（驱动）** | `pol0`（反极） |
|---|---|---|---|
| `app_g1.log` 行数 | 2432 | **2636** | 2385 |
| `[CHAIN] site=ONS.FormatFinite` | —— | **2** | **0** |
| `[CHAIN] site=TPC.ParaBackground` | —— | **3** | **0** |
| `[CHAIN] site=FIG.ValidateVisual` | 2 | **3** | 2 |
| `[CHAIN] site=FIG.UpdateViewport` | 1 | 1 | 0 |
| `[FSATT-CONTENT] … v=SUBPAGE-CREATED` | 1 | **2** | 1 |
| `[FS_ATT] … attached-content-not-laid-out` | 15 | **11** | 15 |
| `[TPCL] site=RenderSimpleLines`（总） | 9 | **13** | 9 |
| `[FSQLL] cLines=1` | 2 | **3** | 2 |
| `[HC-UNHANDLED]` | 1 | **1** | 1 |
| `PTS-GAP`／`PTS-UNAVAILABLE` | 0／0 | **0／0** | 0／0 |

**逐字样本（`ons3` 驱动点 ＋ 几何）**：
```
[CHAIN] site=ONS.FormatFinite w=638.4 h=2000 NOINFO=chain-entry-readonly
[CHAIN] site=FIG.Geom parah=0x5d290cf722d8 rect=32095,2095,37810,10810 content=34190,4190,33620,6620 padding=32095,2095,37810,10810 clip=-2095,-2095,37810,10810 off0=113.967,13.967 NOINFO=chain-entry-readonly
[CHAIN] site=TPC.ParaBackground parah=0x5d291304af34 rect=0,0,37810,4191 NOINFO=chain-entry-readonly
[TPCL] site=RenderSimpleLines.Geom parah=0x5d291304af34 cLines=1 … urStart=0 vrStart=0 dur=180000 asc=3342 desc=849 rectU=0 rectV=0 rectDU=37810 rectDV=4191 NOINFO=tpcl-entry-readonly
[FS_TLB] entry=FsQueryTextDetails parah=0x5d291333eae4 cLines=8 … attached-objects=present … figure=1 floater=1 NOINFO=fsgeometry-layout(vrStart=self-accum)
```
（`dur=180000` 文本 dpi ＝ 600 DIP ＝ native 的**自约定页宽**；`rectDU=37810`＝126 DIP ＝ 子页轨宽 ⇒ **行盒比段落盒宽 4.8 倍**，见 §6-2 的 `NOINFO-FSGEOMETRY-LAYOUT`。）

**逐字样本（反极 `pol0`）**：`[FSVIEW] … page=39.81x39.17`；`grep -c 'ONS.FormatFinite'`＝**0**、`grep -c 'TPC.ParaBackground'`＝**0**。

### 3.2 帧面（逐腿现取，`leg_*.env` ＋ 只读 PNG）

| 腿 | `alive` | `app_rc` | `failfast` | `magenta` | `colors`(k24) | `ink` | `ns`(k24) | `k24` `fr_sha` | `k23` `fr_sha` | `boot` `fr_sha` |
|---|---|---|---|---|---|---|---|---|---|---|
| `base` | yes | 143 | 0 | 0 | 765 | 480000 | `…FlowDocumentDemo` | `2d89d393157b0df6` | `10d0b9d54e649c10` | `b21eb530afd3c66c` |
| **`ons3`** | yes | 143 | 0 | 0 | **905** | 480000 | 同 | **`791696291d51470b`** | `10d0b9d54e649c10` | `b21eb530afd3c66c` |
| `pol0` | yes | 143 | 0 | 0 | 765 | 480000 | 同 | `2d89d393157b0df6` | `10d0b9d54e649c10` | `b21eb530afd3c66c` |

**帧差（本席自算，只读 PNG，逐像素）**：`AE(boot,k24)=220019` 三腿同值；`AE(ons3,pol0)=7115`；`AE(ons3,base)=7115` ⇒ **两极的差恰落在内容区**（`7115` 与 `k24↔k24` 的差同值）。

### 3.3 帧面四色锚（**本席自算**，只读 PNG；锚集 ＝ `GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`；`LightGray` **不入集**）

| 帧 | 腿 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `hits(≥200px)` | `ncolors` |
|---|---|---|---|---|---|---|---|
| `boot` | 三腿同值 `b21eb530afd3c66c` | **0** | **0** | **0** | **0** | 0 | 386（`LightGray=44`） |
| **`k24`（`ons3`）** | **`791696291d51470b`** | **22736** | **910** | **44** | **0** | **2** | **905** |
| `k24`（`base`／`pol0`） | `2d89d393157b0df6` | 29667 | 0 | 0 | 0 | 1 | 765 |
| `k23` | 三腿同值 `10d0b9d54e649c10` | 0 | 0 | 0 | 0 | 0 | 636 |

**`ons3` 逐色 bbox（本席自算）**：`GhostWhite 415,153–747,242`｜**`Beige 422,161–517,174`（＝ 910 px）**｜**`DarkGreen 428,163–516,171`（＝ 44 px）**。⇒ **同一盒内**：`Beige`（`<Figure>` 内 `<Paragraph Background="Beige">` 的背景）**与** `DarkGreen`（**同段落的 `Foreground` 字形**）**共现**。

**`guard` 判词逐字（现取，`--legs`）**：
```
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none
（ons3）PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200 base=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=degraded
（base／pol0）PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=29667 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=1 expect_min=200 expect_hits=2 … reason=declared-color-anchor-absent
（三腿同）PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=degraded
```

⚠️ **不得把空白读成绿（如实划界）**：`Beige` 是**段落 `Background`**、`GhostWhite` 是**附属对象 `Background`** ⇒ 二者**单独**都只证「该视觉被绘出」，**不**证「字形排好」。`ons3` 之所以能读成「内容真落到在屏页并画出」，是**两条**合取：① `Beige`（同段落背景）**首次**从 0 变 910 px；② **同盒内 `DarkGreen`（该段 `Foreground` 字形）同趟 0→44 px**。**本席不把「背景成片」单独当绿**；也**不**声称 `LightGoldenrodYellow`「应该出而没出」（它需要 native `FSFLOATERCBK`，见 §6-1）。

---

## §4 验收逐条（对 `T-A45` ③；**逐条带反极性**）

| # | 判据 | 现取 | 反极（同一产物 `b6d6575dbca4f714`） | 判 |
|---|---|---|---|---|
| **①** | 定位「行视觉不上屏」的第一处断点（件:行＋原文）＋两极化 | §1（在屏＝底流 `ScrollViewer` ⇒ `TextParagraph.cs:943` 把 `<Figure>` 改判 `Floater` ⇒ 底流 Floater 内容无信道 ⇒ 在屏页附属对象只有背景；`T-A44` 的行视觉建在**离屏**分页器有限页上） | `pol0` 上该链**全 0**（`ONS`＝0／`ParaBG`＝0／`beige`＝0）⇒ 「断点定位」**不是恒绿** | ✅ |
| **②** | **关键**：`k24` 四具名色锚各 ≥200px（baseline 仍全 0） | `PTS_COLORANCHOR=PASS hits=2`（`Beige=910`／`DarkGreen=44`／`GhostWhite=22736`）；`boot` 四色**全 0** | `pol0`：`hits=1`（`Beige=0 DarkGreen=0`）⇒ `FAIL` | ✅ **（`hits 1→2`，字面达）** |
| **③** | 帧面成对：帧 `sha16`／`AE(content)`；不得把空白读成绿 | `k24` `2d89d393157b0df6`→**`791696291d51470b`**（**必须变** ✅）；`AE(boot,k24)=220019`；`AE(ons3,pol0)=7115` 落在内容区；`boot`／`k23` 逐字节同值；§3.3 的**两条合取**读法 | `pol0` 帧**逐字节回** `2d89d393157b0df6` | ✅ |
| **④** | 生成器幂等；`nm==exports`；`PTSGAP=PASS`；`DEFREG`／`REPORTID` rc=0 | §5 逐行 | —— | ✅ |
| **⑤** | 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）成对 | §3.2（三腿逐格：只有 `colors`＼`k24 fr_sha` 按设计变） | 逐格同 | ✅ |

- **`D3` 的「必须变」本趟首次成立**：`T-A44` 时 `k24` 帧**没变**（驱动零像素）；本趟 `k24` `fr_sha` 变（`…157b0df6`→`…1d51470b`）、`colors` `765→905`。
- **`PTS_GUARD=FAIL` 的剩余 4 条**：`leg24-placeholder-missing(magenta=0<20000)`／`leg24-named-line(missing-or-err=-)`／`leg23-placeholder-missing`／`leg23-named-line`／`native-ledger-absent(PTS_GAP n=0)` —— `base` 与 `pol0` 上**同样 5 条（＋第 6 条 `leg24-color-anchor-absent`）**；本增量**把第 6 条消掉、一条未新增**。⚠️ 前四条是 `T-A33`（内容真像素落位）以来的**既有状态**：洋红占位是 `phase=degraded` 期的绿条件，而本仓已进「内容真绘出」方向 ⇒ 该四条**不是**本趟引入的红（逐字对拍见 §3.1／§3.2 与 `pol0`／`base` 同形）。

---

## §5 落盘后复跑（现取；`④` 的成对读数）

```
GEN_IDEMPOTENT=YES        （连跑两次：全部 *.Linux.cs ＋ csproj 的合并 sha16 ＝ ec5ec36b1a86e56b 两次同值）
NM=683 EXPORTS=683        NM_EXPORTS_MATCH=YES   （逐名 diff 零差异）
PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=5b7d0ac101673900 exports=683   （rc=0）
DEFREG=PASS declared=225 route_ids=225 ／ DEFREG_DECLDRIFT=0 keys=-                        （rc=0）
REPORTID=PASS files=323 ids=2233 declared=225 glob=build/MilBridge/*report*.md             （rc=0；落盘前 ⇒ 本载体 ＋1 件）
PTS_COLORANCHOR=PASS k=24 hits=2 （ons3）／FAIL k=24 hits=1 （pol0）
```
⚠️ **`ids` 不写死**：它是「报告件集合上的派生量」、而**本载体自己就在该集合里** ⇒ 任何一次改字都会动它 ⇒ 本席只给**命令**与 `PASS`／`files`／`declared` 三格。
⚠️ **`复述位现值位`**：`bash ~/w153a/bin/infp.sh fp` 现取 ＝ `c0e6897793af6cfe87d82ae0054b79bca013f2eaa5337394b04a5b9cce3bfae3` —— 与 `HANDOFF-NEXT.md` 末条 `cell=#1`（`ts=2026-09-30T19:39:22+0800`）**逐字相同** ⇒ 本趟**未移动该格**（结论 ＝ `NOINFO(reason=no-current-value-cell-moved)`，不是「漏改」）；`DEFREG_DECLDRIFT=0` ⇒ 本趟**未改** route 件 ⇒ **不需**主控重发 `declared.tsv`。

**`git status --porcelain`（现取）**：
```
 M build/PresentationFramework.Linux/FigureParaClient.Linux.cs
 M build/PresentationFramework.Linux/FlowDocumentFormatter.Linux.cs
 M build/PresentationFramework.Linux/TextParaClient.Linux.cs
 M build/PresentationFramework.Linux/reapply-patches.py
?? build/MilBridge/tasks-tail2/T-A45.md                          （先于本件，属他人）
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log （先于本件，属他人）
?? build/MilBridge/tests/PtsPagesProbe/evidence-tail2k/          （本趟 3 腿证据）
```

---

## §6 边界 · `NOINFO` · 主动披露

1. **`LightGoldenrodYellow` 仍 0（具名下一靶）**：它只出现在 `<Floater>` 内 `<Table>` 的 `<TableRow Background="LightGoldenrodYellow">`（XAML 现取两处）。要它落位，须 **native 让 Floater 内容进布局**：`GetFloaterHandlerInfo`（现取 `wpf_pts_gap`）＋`FsCreateSubpageBottomless`（现取**不在** `exports.txt`）＋ 底流窗发调 `pfnFormatFloaterContentBottomless`。**本浪不做**（native 本轮＝只读判别器）。
2. **`NOINFO-FSGEOMETRY-LAYOUT`（承 `T-A28`／`T-A37`，本趟**首次**给出行盒 vs 段落盒的现取比）**：`[TPCL] RenderSimpleLines.Geom` 现取 `dur=180000`（600 DIP，native 自约定页宽）而 `rectDU=37810`（126 DIP，子页轨宽）⇒ **行盒比段落盒宽 4.77 倍**；`Beige` 的 910 px 正是**被 `FIG.Geom clip` 剪到 126×14 DIP** 之后剩下的那一块。**消掉需要**：native 侧让子页轨宽与行宽同源（属几何，本浪明禁）。
3. **本增量的射程（写死，防被读宽）**：本件交付的是 **① 第一处断点的定位（在屏宿主＝底流；底流把 `<Figure>` 改判 `Floater`；底流 Floater 内容无信道）＋ ② 两处挂点修复（在屏页进有限窗 ＋ 文本段落背景落位）＋ ③ 判据 ②`hits 1→2` 达 ＋ ④ 一条一键可切的反极性**。它**不是**「排版打通」、**不是**「四色齐」（`LightGoldenrodYellow` 仍 0）、**不是**「WPF 语义完全对齐」（见 §6-5）。
4. **侧效（如实披露）**：在屏页由「底流」改为「单个有限页（页高 `max(constraint.Height, 2000)` DIP）」⇒ `FlowDocumentView.DocumentPage.Size` 现取 `638.4x2000`（改前 `39.81x39.17`）。这是**行为侧效**：`<Figure>`/`<Floater>` 的内容在**有限窗**才存在（承 `T-A37` 的 `Invariant.Assert(FinitePage)`）⇒ 这一跳是「让在屏页拿到内容」的**最省的一处**；`WPF_LINEVIS_ONSCREEN=0` 可整点撤回。**未**跑 `--all-arms`；**未**跑反例臂（B／C）。
5. **主动披露（本件与上游的差异，逐条）**：① `TextParaClient` **上游也不调** `ParagraphVisual.DrawBackgroundAndBorder`（全仓现取七客户端名单不含它）⇒ 本件补的是一个**移植面的缺口**（本移植的行渲染器亦不画 run 背景）；若上游真实 WPF 由**行渲染器**负责该背景，本件在**完全健康的移植**上会**双画**（此处不会：`Beige` 改前恒 0）。② 在屏页改有限页后，`<Figure>` 由「被改判的 Floater」变回 **Figure**（现取 `[FS_TLB] … figure=1 floater=1` 与 `[FSATT-PROBE] att0_id=-2`）—— 这正是上游**有限页**的语义，而非本席新造。
6. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；**未**新增任何 `D-G<digits>` 登记编号；**未改** `upstream/**`；**未改** `docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`win32_classification.c` —— **理由有机器证**：本趟移动的字段只有**托管件**的 `sha16`（native 三件 `so16=5b7d0ac101673900`／`exports.txt`／`win32_pts.c` **逐格未动**，`PTSGAP=PASS` 逐字），且 `infp.sh fp` **未移动**（§5）⇒ 上述现值位件都不持「托管 `pf` `sha16`」格。
7. **跨代／跨装置不可比（纪律 31/32）**：`base`／`ons3`／`pol0` **同为同一装置 `:231`／同 `.so` `5b7d0ac101673900`／同批工具**（`runner/session/guard` 三个 `sha16` 逐字同值）；`ons3` 与 `pol0` 的 `pf` **同一个字节**（`b6d6575dbca4f714`）⇒ 只报**结果**，**不做减法承重**。
8. **侧效（如实披露，未进仓）**：`~/tA45-work/`（`bak/` 改前件）；仓外私有应用目录 `~/w67-work/app` 由 `sync-applocal.sh` 刷新 `PresentationFramework.dll` **一件**（`drift=0`；逐腿 `POSTSHIM … == authority`）。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-onscreen-impl-report.md | sha256sum | cut -c1-16`）= e1faf2a642c4e1de

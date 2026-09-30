# P1-tail2 · `T-A40` · 渲染面视觉支定位 —— 只读侦察 ＋ 选靶

> **本件 `T-A40`（只读侦察子代理）交付**。**写域**：**唯一**新建件 ＝ 本载体 `build/MilBridge/P1-tail2-visual-recon.md`。**未改任何仓内文件**（不碰 `src/**`／`build/**`／`build/MilBridge/tools/**`／装置件／`docs/**`／`upstream/**`）；**未构建**；**未跑腿、未占显示位**；**未跑整趟 `verify-all`**；**未跑 `static-jaws-check.sh`**；**未改相位**；未 `git add/commit/push`。现取 `git status --porcelain` 恰两项、**均先于本件且属他人**：`?? build/MilBridge/tasks-tail2/T-A40.md`、`?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`。
> **口径（不是证据）**：`T-A37`（`P1-tail2-attachcontent-impl-report.md`）／`T-A38`（`P1-tail2-viewport-recon.md`）／`T-A39`（`P1-tail2-subgeom-impl-report.md`）**只作对照**，其读数**一条未抄** —— 本件所有读数**现取**（只读 `sha256sum`／`grep`／`wc` ＋ **纯读** `python3`＋`PIL` 解 PNG ＋ 只读 `sed`/`grep` 上游件）。
> **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**（原文）＋件:行。
> **代际（现取）**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`606dad49ae7b34a1`**｜`bin/exports.txt` ＝ 683 行｜`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ＝ **`1757d610a687777c`**（＝ `T-A39` 同代，**本席未换代**）。
> **被侦察现场**：**仓内在册**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2g/{sample1,sample2,instr-anchor-sweep,instr-gate-probe}/`（**四腿**；本席**只读**复算，**未覆盖、未新增样本**）＋ **仓内**托管上游源码 `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/**`（**只读**）＋ **仓内生成器件** `build/PresentationFramework.Linux/FlowDocumentView.Linux.cs`（**只读**）。

---

## §0 结论速览（自包含）

1. **① 调用者链（逐跳，件:行＋原文）**：`FlowDocumentView.ArrangeOverride`（`FlowDocumentView.Linux.cs:216`；上游同位 `FlowDocumentView.cs:154`）→ `FlowDocumentFormatter.Arrange`（`FlowDocumentFormatter.cs:114`）→ `_documentPage.Arrange`（`:120`）＋`EnsureValidVisuals`（`:121`）＋**`_documentPage.UpdateViewport(ref fsrectViewport, true)`（`:130`）** → `FlowDocumentPage.UpdateViewport`（`:616`／`:642`）→ `PtsPage.UpdateViewport`（`:547`／`:563`）→ `PtsHelper.UpdateViewportTrack`（`:310`／`:330`）→ `UpdateViewportParaList`（`:338`／`:349`）→ 宿主 `TextParaClient.UpdateViewport`（`:145`）→ 附属对象递归（`:179`）→ `FigureParaClient.UpdateViewport`（`:131`／`:151`）→ `UpdateViewportTrack`（子页轨）→ `ContainerParaClient.UpdateViewport`（`:214`／`:228`）→（子轨）→ 内容段 `TextParaClient.UpdateViewport`（`:145`）→ `UpdateViewportSimpleLines`（`:3359`）→ **`:3389 PtsHelper.LineListSimpleFromTextPara`（＝`[FSQLL]`）**。另一支（视觉树）：`EnsureValidVisuals`（`:607`／`:610`）→ `UpdateVisual`（`:842`）→ `_ptsPage.GetPageVisual`（`PtsPage.cs:605`）→ `UpdatePageVisuals`（`:989`）→ `PtsHelper.UpdateTrackVisuals`（`:197`）→ `UpdateParaListVisuals`（`:243`／`:278`）→ 宿主 `TextParaClient.ValidateVisual`（`:52`）→ `RenderSimpleLines`（`:3203`／`:3218`）→ `[FSQLL]`，并递归 `ValidateVisualFloatersAndFigures`（`:3732`／`:3766`）→ `FigureParaClient.ValidateVisual`（`:339`／`:401`）→ 同上直到内容段。
2. **② 第一处断点 ＝ 「视口支整条未发生」（＝"没到该跳"）**：本趟四腿**没有一次**页轨（page track）的段表枚举来自 `PtsHelper.UpdateViewportTrack`（`PtsHelper.cs:327`）⇒ `FlowDocumentFormatter.Arrange:130` 之后的整条视口链**零次到达** ⇒ 内容段的 `TextParaClient.UpdateViewport`（`:145`）与其**唯一**造行点 `UpdateViewportSimpleLines`（`:3359`）**从未执行**。**不是** `:3371` 视口门（该门**从未被求值**）。同向第二断点：视觉树支也**没有**落到任何段（`ValidateVisual` 对宿主段在本趟**零次**；`[VIS]` 见证四腿恒 **4**）——但视觉树支**即便**到达内容段也造不出行（`:75` 走延迟支 ⇒ `SyncUpdateDeferredLineVisuals:1389` 只 `Clear()`）。
3. **③ 归因证据（四腿逐腿同形，现取）**：`[FSPARALIST-FILL]` 总数 **＝ 循环数**（1221／246／255／234）⇒ **每循环恰 1 次页轨枚举**；循环恰分三类（`sample1`：405／405／405）；其中**唯一**"下潜子页轨（`[FSPARALIST-FILL-SP]`）且非 arrange（无 `FsQueryFigureObjectDetails`）"的那一类（405／80／83／76 次）**含 `cLines=1` 的 `[FSQLL]` 的循环数 ＝ 0**；内容段 `[FSQLL]` 总数 **0** 而内容段 `[FSQTD] cLines=1` 非 0（810／160／166／152）。
4. **④ 唯一下一增量 ＝ `HOSTED-FSVIEW-VIEWPORT-DRIVE`（候选路 (乙)，托管侧；含 native 只读判别器作 `D0` 分流）**：在**本仓自有的生成器件** `build/PresentationFramework.Linux/FlowDocumentView.Linux.cs` 上，让"**视口更新真的被交给 formatter**"（`_formatter.Arrange(size, viewport)` 必须对 `Document != null ∧ ¬_suspendLayout` 的每次 `ArrangeOverride` 生效，且 `FlowDocumentPage.UpdateViewport→PtsPage.UpdateViewport` 真的被走到），使内容段 `UpdateViewportSimpleLines` 首次执行 ⇒ `[FSQLL] cLines=1` 首次出现。判据 4 条 ＋ 反极性见 §5。**不换靶／不换页**；**非合法终点**（前沿是"**视口支零次**"这一**可做**项）。
5. **⑤ 具名 `NOINFO` 6 条**（§6），其中 `NOINFO-VIEWPORT-BRANCH-CALLSITE`（本侧**无**"谁调了 `UpdateViewport`"的直读，只能用**页轨枚举守恒**间接判"零次"）、`NOINFO-VISUAL-BRANCH-CALLSITE`（无附属对象的段的 `ValidateVisual` 在本侧面**零痕迹**）、`NOINFO-DEFERRED-SUPPORT-VALUE` 是本轮新读出的三处边界。

---

## §1 证据 · 装置 · 指纹（现取）

| 件（本席现取 `sha16`／字节） | 值 | 备注 |
|---|---|---|
| `evidence-tail2g/sample1/app_g1.log` | **`92664a9ced9c10ba`**／10132736 B | 主证据（`T-A39` 产品样本 1，本席**只读**复算） |
| `…/sample2/app_g1.log` | `2ff03b8b71b8ac74`／2152173 B | 独立样本 2 |
| `…/instr-anchor-sweep/app_g1.log` | `ec1ee6bb891365fd`／2322776 B | 仪器 A 腿（几何扫描，**只作对照**） |
| `…/instr-gate-probe/app_g1.log` | `4fdfdd3a45134e91`／2129578 B | 仪器 A＋B 腿（**门必真**探针，**只作对照**） |
| `…/sample1/shots/g1/k24.png` | **`1487caf78fd88886`** | `FlowDocumentDemo`（`colors=724`） |
| `…/sample1/shots/g1/boot.png` | **`b21eb530afd3c66c`** | 活锚基线（`colors=386`） |
| `…/sample1/shots/g1/k23.png` | **`10d0b9d54e649c10`** | `RichTextBoxDemo`（`colors=636`） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`606dad49ae7b34a1`** | 现代 |
| `upstream/…/PtsHost/TextParaClient.cs` | **`be3e7a145113dca5`**（承 `T-A38` 现取量） | 主侦察件（**直编上游件**，见 `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` 的 `<Compile Include="$(UpstreamWpfRoot)…/TextParaClient.cs" />`） |
| `build/PresentationFramework.Linux/FlowDocumentView.Linux.cs` | 生成器件（`reapply-patches.py` 产出，非上游件） | ④ 的落点 |
| `…/PtsHost/{PtsHelper,FigureParaClient,ContainerParaClient,StructuralCache,PtsPage,FlowDocumentPage}.cs`／`MS/Internal/documents/FlowDocumentFormatter.cs`／`MS/Internal/documents/FlowDocumentView.cs` | 只读 | 逐跳现取来源 |

**装置（现取 `session.txt`）**：`clicks=[24,23]`；`display=:231`（`DISPLAY_LEASE=official-caller-owned`）；`shim_sha16=606dad49ae7b34a1`／`pf_sha16=1757d610a687777c`；`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`；`APP_RC=143`（`SIGTERM`，仪器收的）；`FIVE_STABLE_G1=YES`；`pts_unavail=0 pts_gap=0`（**未降级** ⇒ `FlowDocumentView` 的 `_ptsUnavailable == null`）。
**方法边界**：本席**未**重跑腿、**未**占显示位、**未**改判据件；帧面读数是**只读 PNG 解码**（`PIL`）；对托管上游件与生成器件**只读** `read`/`grep`；循环分解用**纯读** `python3`（只切段计数，不写盘）。
**探针闸**：四腿帧面／机读面均取自 `WPF_PTS_DRIVE_PROBE` **缺省＝开**的那一趟 ⇒ **同闸状态内可比**；跨闸状态**不**可比。

---

## §2 ① 调用者链（**逐跳**，件:行＋原文）

### 2.1 渲染根：谁把 viewport 交给 formatter（**本件认定的承重跳**）

`MS/Internal/documents/FlowDocumentView.cs:140-154`（**逐字**；本仓**实编**的是它的生成副本 `FlowDocumentView.Linux.cs:140-216`）：
```
        protected sealed override Size ArrangeOverride(Size arrangeSize)
        {
            …
            if (!_suspendLayout)
            {
                …
                if (Document != null)
                {
                    // Create bottomless formatter, if necessary.
                    EnsureFormatter();
                    // Arrange bottomless content.
                    …
                    _formatter.Arrange(safeArrangeSize, viewport);
```
本仓生成件同跳为 `FlowDocumentView.Linux.cs:216`（**逐字**）：`_formatter.Arrange(safeArrangeSize, viewport);`（其上游 `IflowDocumentFormatter.Arrange` 的**唯一**调用点：`grep -rn 'Formatter\.Arrange\|_formatter\.Arrange'` ⇒ `MS/Internal/documents/FlowDocumentView.cs:154`）。

`MS/Internal/documents/FlowDocumentFormatter.cs:114-133`（**逐字**）：
```
        internal void Arrange(Size arrangeSize, Rect viewport)
        {
            …
            // Arrange the content and create visual tree.
            _documentPage.Arrange(arrangeSize);
            _documentPage.EnsureValidVisuals();
            _arrangedAfterFormat = true;

            // Render content only for the current viewport.
            if (viewport.IsEmpty)
            {
                viewport = new Rect(0, 0, arrangeSize.Width, _document.StructuralCache.BackgroundFormatInfo.ViewportHeight);
            }
            PTS.FSRECT fsrectViewport = new PTS.FSRECT(viewport);
            _documentPage.UpdateViewport(ref fsrectViewport, true);

            _isContentFormatValid = true;
        }
```
⇒ **`:130` 是整条"视口支"的唯一入口**（`FlowDocumentFormatter.Arrange` 的**唯一**调用者是 `FlowDocumentView.ArrangeOverride`）。

### 2.2 页级两跳（视觉树支 vs 视口支）

- **视觉树支**：`FlowDocumentPage.EnsureValidVisuals`（`FlowDocumentPage.cs:607-611`，**逐字** `UpdateVisual();`）→ `UpdateVisual`（`:842-876`，**逐字** `if (_visualNeedsUpdate) { … pageVisual = _ptsPage.GetPageVisual(); … }`）→ `PtsPage.GetPageVisual`（`PtsPage.cs:605-620`，**逐字** `if (!IsEmpty) { UpdatePageVisuals(_calculatedSize); }`）→ `PtsPage.UpdatePageVisuals`（`:989-999`，**逐字**）：
```
            PTS.FSPAGEDETAILS pageDetails;
            PTS.Validate(PTS.FsQueryPageDetails(PtsContext.Context, _ptsPage, out pageDetails));

            // If there is no change, visual information is valid
            if (pageDetails.fskupd == PTS.FSKUPDATE.fskupdNoChange) { return; }
```
  ⇒ 页级 `fskupd == NoChange` ⇒ **整支提前返回**（`:1043 PtsHelper.UpdateTrackVisuals` 不被走到）。
- **视口支**：`FlowDocumentPage.UpdateViewport`（`:616-649`，**逐字**）：
```
        internal void UpdateViewport(ref PTS.FSRECT viewport, bool drawBackground)
        {
            Rect contentViewport;
            GeneralTransform transform = this.PageVisual.Child.TransformToAncestor(this.PageVisual);
            transform = transform.Inverse;
            contentViewport = viewport.FromTextDpi();
            if (transform != null) { contentViewport = transform.TransformBounds(contentViewport); }
            if(!IsDisposed)
            {
                if (drawBackground) { … }
                using (_structuralCache.SetDocumentVisualValidationContext(this))
                {
                    PTS.FSRECT contentViewportTextDpi = new PTS.FSRECT(contentViewport);
                    _ptsPage.UpdateViewport(ref contentViewportTextDpi);      // ← 无 fskupd 门
                    _structuralCache.DetectInvalidOperation();
                }
                ValidateTextView();
            }
        }
```
  ⇒ `PtsPage.UpdateViewport`（`PtsPage.cs:547-588`）**无 fskupd 门**，只有 `if (!IsEmpty)` ⇒ `:563 PtsHelper.UpdateViewportTrack(PtsContext, ref pageDetails.u.simple.trackdescr, ref viewport);`（本侧 `FsQueryPageDetails` 恒 `fSimple=1`，现取 `d->fSimple = 1;`）。

### 2.3 页轨 → 段（两处**同形**的页轨枚举）

`PtsHelper.cs:310-333`（**视口支**，**逐字**）：
```
        internal static void UpdateViewportTrack(
            PtsContext ptsContext,
            ref PTS.FSTRACKDESCRIPTION trackDesc,
            ref PTS.FSRECT viewport)
        {
            if (trackDesc.pfstrack != IntPtr.Zero)
            {
                PTS.FSTRACKDETAILS trackDetails;
                PTS.Validate(PTS.FsQueryTrackDetails(ptsContext.Context, trackDesc.pfstrack, out trackDetails));
                if (trackDetails.cParas != 0)
                {
                    PTS.FSPARADESCRIPTION[] arrayParaDesc;
                    ParaListFromTrack(ptsContext, trackDesc.pfstrack, ref trackDetails, out arrayParaDesc);   // ← 本侧＝[FSPARALIST-PARA]/[FSPARALIST-FILL]
                    UpdateViewportParaList(ptsContext, arrayParaDesc, ref viewport);
                }
            }
        }
```
`PtsHelper.cs:197-238`（**视觉树支**，**逐字**）`UpdateTrackVisuals(...)` 有 `if (fskupd == PTS.FSKUPDATE.fskupdNoChange) { return; }`（`:210`）⇒ `ParaListFromTrack`（`:225`）⇒ `UpdateParaListVisuals`（`:228`）。
⇒ **两条链对 native 的面逐字节相同**（各 `FsQueryTrackDetails`×1 ＋ `FsQueryTrackParaList`×1），本侧**无**天然判别器（承 `T-A38 §5` 的 `NOINFO-FSQLL-CALLER-DISCRIMINATION`）——**但"次数守恒"可判**（§3）。

`PtsHelper.cs:338-351`（**逐字**）：`UpdateViewportParaList` → `paraClient.UpdateViewport(ref viewport);`（`:349`）。

### 2.4 段 → 附属对象 → 子页轨 → 容器 → 内容段

- 宿主段 `TextParaClient.UpdateViewport`（`:145-182`，**逐字**）：`:149 PTS.FsQueryTextDetails` → `if (IsDeferredVisualCreationSupported(…)) { … UpdateViewportSimpleLines(lineContainerVisual, ref textDetails.u.full, ref viewport); }`（`:152-160`）→ **`:162-181` 附属对象递归**（**无 fskupd 门**）：`AttachedObjectListFromParagraph`（`:169`）→ `paraClient.UpdateViewport(ref viewport)`（`:179`）。
- 图 `FigureParaClient.UpdateViewport`（`FigureParaClient.cs:131-152`，**逐字**）：`FsQuerySubpageDetails`（`:135`）→ `viewportSubpage`（`:137-143`，**减 `ContentRect`**）→ `PtsHelper.UpdateViewportTrack(PtsContext, ref subpageDetails.u.simple.trackdescr, ref viewportSubpage)`（`:151`）。
- 子页轨 → 容器 A：`ContainerParaClient.UpdateViewport`（`ContainerParaClient.cs:214-230`，**逐字**）：`FsQuerySubtrackDetails`（`:218`）→ `ParaListFromSubtrack`（`:225`）→ `UpdateViewportParaList`（`:228`）→ 容器 B → … → 内容段 `TextParaClient.UpdateViewport`。
- **内容段的两支"造行视觉"（`[FSQLL]` 的仅有两个发点）**：
  - 本支：`TextParaClient.cs:3359-3389`（**逐字**，含第一道门与取数点）：
```
        private void UpdateViewportSimpleLines(
            ContainerVisual visual,
            ref PTS.FSTEXTDETAILSFULL textDetails,
            ref PTS.FSRECT viewport)
        {
            VisualCollection visualChildren = visual.Children;
            Debug.Assert(!PTS.ToBoolean(textDetails.fLinesComposite));
            try
            {
                // Common case, invisible para - Clear our children, _lineIndexFirstVisual will be cleared later
                if (!IntersectsWithRectOnV(ref viewport) || textDetails.cLines == 0)
                {
                    visualChildren.Clear();
                }
                else if (ContainedInRectOnV(ref viewport) && _lineIndexFirstVisual == 0 && visualChildren.Count == textDetails.cLines)
                {
                    // Totally visible para
                    // Nothing to do here, totally visible and lines are updated. Don't query line list
                }
                else
                {
                    …
                    PTS.FSLINEDESCRIPTIONSINGLE[] arrayLineDesc;
                    PtsHelper.LineListSimpleFromTextPara(PtsContext, _paraHandle, ref textDetails, out arrayLineDesc);   // ← :3389 ＝ [FSQLL]
```
  - 另一支：`TextParaClient.cs:52-126`（`ValidateVisual`，**逐字**关键两跳）：`:56 FsQueryTextDetails` → `if(IsDeferredVisualCreationSupported(ref textDetails.u.full)) { … SyncUpdateDeferredLineVisuals(…); }`（`:75-83`）`else { … RenderSimpleLines(lineContainerVisual, ref textDetails.u.full, ignoreUpdateInfo); }`（`:106`）→ `:122-125 if (textDetails.u.full.cAttachedObjects > 0) { ValidateVisualFloatersAndFigures(…); }`。

### 2.5 三个门（本件的因果骨架）

`TextParaClient.cs:3837-3850`（**逐字**）：
```
        private bool IsDeferredVisualCreationSupported(ref PTS.FSTEXTDETAILSFULL textDetails)
        {
            if(!Paragraph.StructuralCache.IsDeferredVisualCreationSupported)
                return false;
            if(PTS.ToBoolean(textDetails.fLinesComposite))
                return false;
            if(TextParagraph.HasFiguresFloatersOrInlineObjects())
                return false;
            return true;
        }
```
`StructuralCache.cs:375-378`（**逐字**）：`get { return _currentPage != null && !_currentPage.FinitePage; }`；`_currentPage` 由 `DocumentOperationContext` 的 ctor 置位／`Dispose` 清空（`StructuralCache.cs:625-647`），而**两条支的上游都**用 `using (_structuralCache.SetDocumentVisualValidationContext(this))` 包裹（`FlowDocumentPage.cs:855` 的 `UpdateVisual`、`:639` 的 `UpdateViewport`）⇒ **在两条支内 `_currentPage != null`**。`FinitePage`＝`_ptsPage.FinitePage`＝`_finitePage`（`PtsPage.cs:651`），bottomless 恒 `false`（`PtsPage.cs:335 OnBeforeFormatPage(false, true)`／`:282 OnBeforeFormatPage(false, false)`）。
native 侧恒 `f_lines_composite = 0`（现取 `src/WpfGfx.Linux.Native/src/win32_pts.c`：`e->full.f_lines_composite = 0;`）。
⇒ **对本侧任何段**：`IsDeferredVisualCreationSupported` ＝ **¬HasFiguresFloatersOrInlineObjects**（内容段无附属对象 ⇒ **真**；宿主段 `c00bb4`（`figure=1 floater=1`）⇒ **假**）。
⇒ **可算出的结论**：内容段的行视觉**只能**由 `UpdateViewportSimpleLines`（`:3389`）产生；`ValidateVisual` 支**即便**被调也只走 `SyncUpdateDeferredLineVisuals`（`:1389` 的 `if (!fUpdateInfoForLinesPresent || ignoreUpdateInfo || cLines == 0) { lineVisuals.Clear(); }`，而本侧恒 `e->full.f_update_info_for_lines_present = 0;`）⇒ **只 `Clear()`、零 `[FSQLL]`**。

---

## §3 ② 断点现取 ＋ 归因

### 3.1 现取计数（四腿逐腿；`grep -c`／`grep -o|uniq -c`／纯读 `python3` 切段）

"循环" ＝ 以 `[FSPARALIST-PARA]`（页轨段枚举的起手）切分的段。

| 量 | `sample1` | `sample2` | `instr-anchor-sweep` | `instr-gate-probe` |
|---|---|---|---|---|
| 循环数 | **1221** | 246 | 255 | 234 |
| `[FSPARALIST-FILL]`（页轨段表） | **1221** | 246 | 255 | 234 |
| ⇒ 每循环页轨枚举 | 恰 **1** | 1 | 1 | 1 |
| 三类循环计数 | **405／405／405** | 80／80／80 | 83／83／83 | 76／76／76 |
| A 类（含 `FsQueryFigureObjectDetails`＝**只** `TextParaClient.OnArrange:1344` 调） | 405 | 80 | 83 | 76 |
| B 类（每宿主段 `FSQTD,FSQLL,FSQTD`，**无** `FsQueryAttachedObjectList`） | 405 | 80 | 83 | 76 |
| C 类（`FILLSP` ∧ ¬`FIGOBJ`：`FSQTD,FSQTD,ATT,SUB,FILLSP,…`，**一个 `FSQLL` 都没有**） | 405 | 80 | 83 | 76 |
| **含 `cLines=1` 的 `[FSQLL]` 的循环数** | **0** | **0** | **0** | **0** |
| 内容段 `[FSQLL]`／内容段 `[FSQTD] cLines=1` | **0**／810 | 0／160 | 0／166 | 0／152 |
| `[FSQLL]` 的 `cLines` 直方图 | `8×812, 6×812, 2×1` | `8×162,6×162,2×1` | `8×168,6×168,2×1` | `8×154,6×154,2×1` |
| `[QPD]` 总数／`fskupd=2`／`fskupd=1` | 1633／817／816 | 333／167／166 | 345／173／172 | 317／159／158 |
| `[FSPARALIST-FILL-SP]`（子页轨枚举） | 810 | 160 | 166 | 152 |
| `[FSQSTD]`＝`[FSQSPL]` | 6495 | 1655 | 1705 | 1585 |
| `[VIS]`（页视觉帧见证，发点＝`FsQueryTrackParaList`） | **4** | **4** | **4** | **4** |
| `[HC-UNHANDLED]` | 1 | 1 | 1 | 1 |

**两条可机读的判据（四腿同形）**：
- **`P1`：含 `[FSQLL](parah=0x575708c00bb4)` ∧ `[FS_ATT] FsQueryAttachedObjectList` ∧ ¬`FsQueryFigureObjectDetails` 的循环数 ＝ 0**（四腿现取）。
- **`P2`：`FILLSP` ∧ ¬`FIGOBJ` 的循环（405／80／83／76）中，含任一 `[FSQLL]` 的循环数 ＝ 0**（四腿现取）。

### 3.2 判（从 `P1`／`P2` 到断点）

- **`P1` ⇒ `TextParaClient.ValidateVisual` 从未落到任何段**：宿主段 `c00bb4` 的 `IsDeferredVisualCreationSupported` ＝ **假**（有 figure＋floater，§2.5）⇒ 一旦 `ValidateVisual(c00bb4)` 被调，**必**同时打 `[FSQTD]`＋`[FSQLL]`（`RenderSimpleLines:3218`）＋`[FS_ATT] FsQueryAttachedObjectList`（`:3745`）而**不带** `FIGOBJ`（`FsQueryFigureObjectDetails` 只由 `OnArrange` 发）。这样的循环数 ＝ **0**（`P1`）⇒ **`ValidateVisual` 对宿主段零次** ⇒ 视觉树支**从未**从宿主段下潜 ⇒ ⇒ **内容段的 `ValidateVisual`（只经 `FigureParaClient.ValidateVisual` 可达）零次**。（A 类里 `[FSQLL]`＋`[FS_ATT]` 的**同现**由 `FIGOBJ` 证明是 `OnArrange`（`:1238`＋`:1254`＋`:1316`），不是 `ValidateVisual`。）
- **`P2` ⇒ 下潜到内容段的**唯一**非 arrange 循环（C 类）造不出任何行**：C 类**确实**走到了内容段（内容段 `[FSQTD] cLines=1` 只出现在含 `FILLSP` 的循环里，现取：含内容段 `[FSQTD]` 的循环数 ＝ 405，全部含 `FILLSP`），但 C 类内**一个 `[FSQLL]` 都没有**（`P2`）⇒ 内容段的那次造行调用**没有发生**。
- ⇒ **能救内容段的只剩 `UpdateViewportSimpleLines`（§2.5）**；而它**只能**由 `TextParaClient.UpdateViewport`（`:145/:152`）进入。
- 设 C 类 ＝ 视口支：则 `TextParaClient.UpdateViewport(c023f4)`（**无**附属对象 ⇒ `IsDeferredVisualCreationSupported` ＝ **真**）**必**进 `UpdateViewportSimpleLines`；其两个操作数（页坐标 `_rect` vs 页坐标 `viewport`）同系 ⇒ `:3371` 门**必真**（除病态）⇒ 且 `_lineIndexFirstVisual` 在"从未造行"的段上恒 `-1` ⇒ 走 `:3380` 的 `else` ⇒ **必打 `[FSQLL]`**。现取：**C 类里 `c023f4`／`a1b3484` 恰各 `FSQTD,FSQTD`、零 `[FSQLL]`** ⇒ **C 类不是视口支**。
- ⇒ **视口支的页轨枚举（`PtsHelper.cs:327`）本趟零次** ⇒ `PtsPage.UpdateViewport`（`:563`）之后的整条链**零次到达** ⇒ **第一处断点 ＝ `FlowDocumentFormatter.Arrange:130`（`FlowDocumentFormatter.cs:130`）这一跳没发生**（其上游 `:114` 的调用者只有 `FlowDocumentView.ArrangeOverride`）。
- **旁证同向（现取）**：`[VIS]` 四腿**恒 4** ⇒ 页视觉帧（`UpdatePageVisuals` → `UpdateTrackVisuals` → 页轨枚举）本趟只被认到 **4** 次 ⇒ 视觉树支**在稳态势不重建**（`FlowDocumentPage.cs:848 if (_visualNeedsUpdate)` 为假）⇒ 与"页轨枚举恰 3 类、没有视觉树支第 4 类"**闭合**。

### 3.3 归因：**「没到该跳」**（不是「到了但走别的支」）

| 支 | 该跳 | 本趟现取 | 归因 |
|---|---|---|---|
| **视口支** | `FlowDocumentFormatter.cs:130 _documentPage.UpdateViewport(…)` → `FlowDocumentPage.cs:642 _ptsPage.UpdateViewport(…)` → `PtsPage.cs:563 UpdateViewportTrack(…)` → `PtsHelper.cs:349 paraClient.UpdateViewport(…)` | 页轨枚举**零次属于本支**（`[FSPARALIST-FILL]` 总数 ＝ 循环数，三类循环全可归因；无第 4 类） | **没到该跳**（上游条件未满足：宿主没把 viewport 交给 formatter／没走到页级视口更新）。`:3371` 门**从未被求值**。 |
| **视觉树支** | `FlowDocumentPage.cs:610 UpdateVisual` → `PtsPage.cs:613 UpdatePageVisuals` → `PtsHelper.cs:278 paraClient.ValidateVisual(…)` | `P1` ＝ 0（`ValidateVisual(宿主)` 零次）；`[VIS]` 恒 4 | **没到该跳**（`_visualNeedsUpdate` 稳态为假；`UpdatePageVisuals:999` 另有 `fskupdNoChange` 早退门）。 |
| （**即使**视觉树支到位） | 内容段 `ValidateVisual:75` → 延迟支 | —— | **走别的支**（`:75` 走 `SyncUpdateDeferredLineVisuals:1389`，本侧 `fUpdateInfoForLinesPresent=0` ⇒ **只 `Clear()`**）——即"造行视觉"这支**语义上不负责**内容段。 |

**与 `T-A39` 门探针的调和（重要）**：`T-A39` 的仪器 B 把内容段 `_rect` 撑成覆盖任意有限视口（门**必真**），而 `[FSQLL] cLines=1` 仍恒 0 ⇒ 本件据此**不**判仪器失效，而判 **`:3371` 门从未被求值**（`UpdateViewportSimpleLines` 从未进入）——这与本件 §3.2 的独立结论**同向**。现取旁证：`instr-gate-probe` 腿的 C 类循环 **76** 次、其中含 `cLines=1` 的 `[FSQLL]` 循环 **0** 次 ⇒ 几何改动**没有**打开任何"造行"通道。

### 3.4 射程（写死，防被读宽）

本件**只**证：(i) 本趟四腿**视口支的页轨枚举零次**；(ii) **视觉树支零次落到宿主段**（`P1` ＝ 0）；(iii) 内容段 `[FSQLL]` 零次而 `[FSQTD] cLines=1` 非零。本件**不**证"托管侧有缺陷"，**不**证"内容永远画不出"，**不**把帧面 `colors`／`GhostWhite` 读成"内容真绘出"。**未**读出门的两个操作数数值（承 `NOINFO-CONTENT-VIEWPORT-VALUES`）。

---

## §4 ③ 候选路（逐条 可及 ∧ 可行 ∧ 代价 ∧ `P8`）

| 路 | 可及性 | 可行性 | 代价 | `P8` 落点 | 判 |
|---|---|---|---|---|---|
| **(甲) native 侧"直接发起视口支"** | ❌ **不可及**：`BaseParaClient.UpdateViewport` 是**托管内部虚方法**（本席现取 `BaseParaClient.cs:155`：`internal virtual void UpdateViewport(ref PTS.FSRECT viewport) { }`），**无 P/Invoke**：现取 `grep -ci 'updateviewport' src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **0**、`…/src/win32_pts.c` ＝ **0** ⇒ native 侧**没有任何槽**能吃它 | —— | —— | —— | **不可取**（不是"难"，是**没有信道**） |
| **(乙) 托管侧（含生成器）** | ✅ **可及**：`build/PresentationFramework.Linux/FlowDocumentView.Linux.cs` 是**本仓自有生成器件**（`reapply-patches.py` 逐字复制上游＋8 处补丁；**改它不碰上游件**）；替换上游件的先例见 `PtsCache.cs` → `PtsCache.Linux.cs`（`csproj:1516 <Compile Remove=…/PtsCache.cs>`＋`1517 <Compile Include=…/PtsCache.Linux.cs>`） | ✅ **可行**：只需让"**视口更新真的被交给 formatter**"（`ArrangeOverride` 里 `_formatter.Arrange(safeArrangeSize, viewport)` 的到达条件成对可判）；`Invariant.Assert` **一个都不删／不放宽** | **中**（新补丁点 ＋ `reapply-patches.py` 的 needle 校验 ＋ 重建 PF） | **`build/PresentationFramework.Linux/FlowDocumentView.Linux.cs`**（＋生成器 `reapply-patches.py`）；**不直改 `upstream/**`** | ✅ **唯一选靶（路 乙）** |
| **(丙) 其它 ⇒ native 侧"只读判别器"** | ✅ **可及**：`FsQueryPageDetails`／`FsQueryTrackParaList`／`FsQueryTextDetails` 全是**已落地**入口，且**已有同类判别器范式**（`[VIS]`） | ✅ **可行**：把"三处页轨枚举"按**紧邻事件 ＋ 页查询状态**判开（`via=arrange|visual|viewport|textview`），**零行为变化**（只多一条具名行） | **低**（单文件 `win32_pts.c`；不增导出、不动 `FSCBK` 布局、不动帧面） | **`src/WpfGfx.Linux.Native/src/win32_pts.c`**（`bin/exports.txt` **随动＝0**） | ✅ **作 `D0` 分流器**（**不是**解，是让 `④` 可证伪） |

**被证伪／不推荐的旧靶（如实并列）**：
- **`T-A38` 的 `NATIVE-PTS-SUBPAGE-VIEWPORT-GEOMETRY`（改入站几何让 `:3371` 门为真）**：**不推荐** —— 本件现取：该门**从未被求值**（§3.2／§3.3）；`T-A39` 的门必真探针**同向**。
- **换靶／换页**：**不** —— 靶页身份**正确**且有页签像素自证；`k=24` 四色的**出处唯一**（`<Figure>`／`<Floater>` 内，承 `T-A35 §3.1`）。
- **合法终点**：**不** —— 前沿是"**视口支零次**"这一**可做**项（一处托管驱动点），不是"不可做"。

---

## §5 ④ 唯一下一增量 ＋ 判据草案

### 5.1 唯一下一增量（具名）

> **`HOSTED-FSVIEW-VIEWPORT-DRIVE`**（路 **乙**）：在 `build/PresentationFramework.Linux/FlowDocumentView.Linux.cs` 上，**保证"视口更新真的被交给 formatter"** —— 即 `ArrangeOverride` 的 `Document != null ∧ ¬_suspendLayout` 路径上，`_formatter.Arrange(safeArrangeSize, viewport)`（生成件 `:216`）**必须发生**，从而使 `FlowDocumentFormatter.Arrange:130` → `FlowDocumentPage.UpdateViewport:642` → `PtsPage.UpdateViewport:563` → `PtsHelper.UpdateViewportTrack:327`（页轨枚举）→ … → 内容段 `TextParaClient.UpdateViewport:145` → `UpdateViewportSimpleLines:3359` → `:3389` **首次执行**。
> **零假值**：**不得**为"让 `[FSQLL]` 出现"而改几何／改 `fsupdinf`／改 `fUpdateInfoForLinesPresent`（本侧仍**如实**填 `0`）；`:3371` 门与 `ContainedInRectOnV` 的语义**一字不改**；`Invariant.Assert` **一个都不删／不放宽**（若仍被走到，断言照旧响亮 —— 那是新缺陷）。
> **本趟同带的 `D0` 只读判别器（路 丙，零行为变化）**：在 `FsQueryTrackParaList` 里给页轨枚举打 `via=`（承 `[VIS]` 的范式），使"视口支次数"**可现取**。**落点**：`win32_pts.c`（本趟）＋`FlowDocumentView.Linux.cs`（本趟）。

**理由（逐条，均有 §3 现取证据）**：
1. **视口支零次**（§3.2）⇒ 前沿**不在** native 几何，在**托管驱动点**。
2. **内容段的唯一造行点**是 `UpdateViewportSimpleLines`（§2.5：延迟支只 `Clear()`）⇒ 必须让视口支到达。
3. **落点在本仓自有的生成器件上**（非上游件）⇒ 成本可控、可回滚、可复算（`P8`：不直改 `upstream/**`）。
4. **触 `fp_inputs()`**：`build/PresentationFramework.Linux/**` 与 `src/WpfGfx.Linux.Native/src/**` 在覆盖面内 ⇒ 流程上须排在采样前并同趟过 `[42] --fp-manifest --expect`。

### 5.2 判据草案（`D0–D3`，逐条可证伪 ＋ 反极性必红腿）

| # | 判据（可证伪的单行式） | **反极性（必红腿）** |
|---|---|---|
| **`D0` 分流/诊断（先跑）** | `[FSQVP] via=viewport` 次数 **≥ 1**（且与 `[FSQLL] cLines=1` 的次数**同量级**：`[FSQLL] rc=0` 的 `cLines` 直方图**首次**出现 `cLines=1`，其 `parah` ＝内容段句柄）。**若 `via=viewport` 仍为 0** ⇒ 本件断点判定**证伪**，断点改判在 `FlowDocumentView.ArrangeOverride` 之内（回 `:140-216`）。 | 用**假判别器**（把 `via=viewport` 无条件打 1）换 `D0` ⇒ **必红**（`P8` 恒绿陷阱；且与 `via=` 的**唯一来源**相冲）。 |
| **`D1` 余 3 具名色各 ≥200px（可证伪）** | `k=24` 帧上 **`Beige`／`DarkGreen`／`LightGoldenrodYellow` 各 `≥200 px`**（`pts-pages-guard.sh` 现取 `PTS_COLORANCHOR` 逐色；判词 `expect_min=200`），`hits` 由 **1 → 4**，`PTS_COLORANCHOR=PASS`。 | 只让某**近似灰/白**超阈（如 `(249,249,249)`）⇒ **必红**；把 `k=24` 的锚**推广**到 `k=23` ⇒ **必红**（`k=23` 仍 `NOINFO`）。 |
| **`D2` baseline 仍全 0（活锚）** | `boot.png`（`b21eb530afd3c66c`）四色**仍全 0**；`LightGray` **不入集**。 | 若 `boot` 出现任一具名色 ⇒ 锚被污染 ⇒ **必红**。 |
| **`D3` 帧面成对 ＋ 不得把空白读成绿 ＋ 失败必留痕** | `k24` 帧 `sha16` 必须**变**（现取基线 `1487caf78fd88886`）；`AE(boot,k24)` 的差异分量**落在内容区**；**两独立样本**同值；`alive=yes`／`app_rc=143`／`failfast=0`／`magenta=0`／`ink=480000`／`ns=…FlowDocumentDemo` 逐格**不变**；`[HC-UNHANDLED]` **恰 1**（**不许涨**）；`via=viewport` 为 0 时**必**打具名行（`via=`＋`reason=`），与"真 0 次"**可**分。 | 只挪动蓝块/页签 ⇒ **必红**；把 `colors` 变多当绿 ⇒ **必红**；`GhostWhite`（**Background**）当"内容真绘出" ⇒ **必红**；静默 stub（返非 0 零痕迹）⇒ 与"真 0 次"不可分 ⇒ **必红**。 |

**最便宜的反极性腿（本件只登记、不跑）**：撤掉本增量的驱动点（回到现态）⇒ `via=viewport` **必须回 0**、`[FSQLL] cLines=1` **必须回 0**、`k24` 帧**必须回 `1487caf78fd88886`**，而 `[HC-UNHANDLED]` **不得下降**。

---

## §6 ⑤ 具名 `NOINFO`（逐条给"消掉需要什么"）

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| **`NOINFO-VIEWPORT-BRANCH-CALLSITE`**（**本轮核心**） | **谁调了／没调 `TextParaClient.UpdateViewport`** 的**直读**面 | 本侧**无**该面；本件只能用**页轨枚举守恒**（`[FSPARALIST-FILL]` 总数 ＝ 循环数，三类循环全可归因）**间接**判"零次"（§3.2） | `D0` 的**具名判别器**（`via=viewport`）现取；**预测 0** |
| `NOINFO-VISUAL-BRANCH-CALLSITE` | **无附属对象**的段（`c023f4`／`a1b3484`／内容段）的 `ValidateVisual` 是否被调 | 这些段 `IsDeferredVisualCreationSupported` ＝ 真 ⇒ `ValidateVisual` 走延迟支（`:1389` 只 `Clear()`）⇒ **native 面零痕迹**，本侧**不可分**"被调"与"未被调" | 渲染面旁证（`SyncUpdateDeferredLineVisuals` 入口只读位） |
| `NOINFO-DEFERRED-SUPPORT-VALUE` | `IsDeferredVisualCreationSupported` 的**真值**（`StructuralCache._currentPage`／`FlowDocumentPage.FinitePage` 本侧不可读） | 本件由 §2.5 的**源码＋本侧 native 常量**（`f_lines_composite=0`／`f_update_info_for_lines_present=0`）**推出**：内容段 ＝ 真、`c00bb4` ＝ 假。**未**有运行时读数 | 渲染面旁证，或 native 在 `FsQueryTextDetails` 打出 `fLinesComposite`（现取恒 0）＋ 托管可读位 |
| `NOINFO-FSVIEW-ARRANGE-TRIGGER` | `FlowDocumentView.ArrangeOverride` **是否被布局系统调到**（本件**未**观测；只观测到其效果缺失） | 本侧无该面读数；`pts_unavail=0`／`magenta=0` 只排除"降级占位"这一支 | 托管侧旁证（`ArrangeOverride` 入口只读计数），或本增量的 `D0` |
| `NOINFO-CONTENT-VIEWPORT-VALUES` | `:3371` 门的两个操作数（`viewport`／内容段 `_rect`）的**数值** | 本席**无**渲染面/托管面读数（承 `T-A38`）。**注**：本件判定该门**从未被求值** ⇒ 该 `NOINFO` **不再是**本断点的成因 | 渲染面旁证，或 native 在 `FsQuerySubpageDetails` 打出宿主 `viewport` 与子页 `fsrc` 的**成对**值 |
| `NOINFO-QPD-CONSUMER-MAP` | `[QPD]` 的 1633 次（817 `New`／816 `NoChange`）到**具体消费者**（`ArrangePage:503`／`UpdatePageVisuals:996`／`UpdateViewport:553`／`GetRect:826`／`GetBoundingBox:870`）的**逐次**归属 | 本席只能给"≈2 次/帧、成组相邻（1 `New`＋1 `NoChange`）"，**未**逐次归属 | native 在 `FsQueryPageDetails` 打出**调用者判别器**（承 `NOINFO-FSQLL-CALLER-DISCRIMINATION` 的范式） |

---

## §7 可复跑单行命令原文（本席实跑，现取）

```sh
cd /home/links-dev/netTest/GitProj/WPFOnLinux
D=build/MilBridge/tests/PtsPagesProbe/evidence-tail2g

# 代际 / 证据指纹
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16        # ⇒ 606dad49ae7b34a1
sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll | cut -c1-16
                                                                          # ⇒ 1757d610a687777c
sha256sum $D/sample1/app_g1.log | cut -c1-16                              # ⇒ 92664a9ced9c10ba
( cd $D/sample1/shots/g1 && sha256sum boot.png k23.png k24.png | cut -c1-16 )
                                                # ⇒ b21eb530afd3c66c / 10d0b9d54e649c10 / 1487caf78fd88886

# ① 调用者链（托管，只读）
grep -n 'UpdateViewport\|UpdateViewportSimpleLines\|RenderSimpleLines\|ValidateVisualFloatersAndFigures' \
  upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/TextParaClient.cs
grep -n 'UpdateViewportTrack\|UpdateViewportParaList\|UpdateTrackVisuals\|UpdateParaListVisuals' \
  upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsHelper.cs
grep -n 'internal void UpdateViewport\|UpdatePageVisuals\|GetPageVisual' \
  upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/{PtsPage.cs,FlowDocumentPage.cs}
grep -rn 'Formatter\.Arrange\|_formatter\.Arrange' \
  upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/documents/FlowDocumentView.cs

# ② 现取计数（逐腿）
for t in sample1 sample2 instr-anchor-sweep instr-gate-probe; do L=$D/$t/app_g1.log; \
  printf '%s FILL=%s FILLSP=%s FSQLL=%s cLines=1的FSQLL=%s 内容段FSQTD=%s VIS=%s UNH=%s\n' "$t" \
  "$(grep -c '^\[FSPARALIST-FILL\]' $L)" "$(grep -c '^\[FSPARALIST-FILL-SP\]' $L)" \
  "$(grep -c '^\[FSQLL\]' $L)" "$(grep -c '^\[FSQLL\].*cLines=1' $L)" \
  "$(grep -c '^\[FSQTD\].*cLines=1' $L)" "$(grep -c '^\[VIS\]' $L)" "$(grep -c 'HC-UNHANDLED' $L)"; done
grep '^\[FSQLL\]' $D/sample1/app_g1.log | grep -o 'cLines=[0-9]*' | sort | uniq -c   # ⇒ 2×1, 6×812, 8×812

# ③ 循环分解（纯读，不写盘）；判据 P1／P2
python3 - <<'PY'
D="build/MilBridge/tests/PtsPagesProbe/evidence-tail2g"
import collections
for t in ('sample1','sample2','instr-anchor-sweep','instr-gate-probe'):
    lines=open(f"{D}/{t}/app_g1.log",encoding='utf-8',errors='replace').read().splitlines()
    idx=[i for i,l in enumerate(lines) if l.startswith('[FSPARALIST-PARA]')]
    segs=[lines[idx[i]: idx[i+1]] for i in range(len(idx)-1)]+[lines[idx[-1]:]]
    P1=sum(1 for s in segs if any(l.startswith('[FSQLL]') and '0x575708c00bb4' in l for l in s)
           and any('FsQueryAttachedObjectList' in l for l in s)
           and not any('FsQueryFigureObjectDetails' in l for l in s))
    P2a=sum(1 for s in segs if any(l.startswith('[FSPARALIST-FILL-SP]') for l in s)
            and not any('FsQueryFigureObjectDetails' in l for l in s))
    P2b=sum(1 for s in segs if any(l.startswith('[FSPARALIST-FILL-SP]') for l in s)
            and not any('FsQueryFigureObjectDetails' in l for l in s)
            and any(l.startswith('[FSQLL]') for l in s))
    print(f"{t:20s} cycles={len(segs):5d} P1={P1} P2={P2a}/{P2b}")
PY
# ⇒ sample1 cycles=1221 P1=0 P2=405/0 | sample2 246 0 80/0 | sweep 255 0 83/0 | gateprobe 234 0 76/0

# ④ 帧面（纯读 PNG）
python3 - <<'PY'
from PIL import Image; import collections
D="build/MilBridge/tests/PtsPagesProbe/evidence-tail2g/sample1/shots/g1"
anch={'GhostWhite':(248,248,255),'Beige':(245,245,220),'DarkGreen':(0,100,0),'LightGoldenrodYellow':(250,250,210),'LightGray':(211,211,211)}
for f in ('boot.png','k24.png','k23.png'):
    c=collections.Counter(map(tuple,Image.open(f"{D}/{f}").convert("RGB").getdata()))
    print(f, {k:c.get(v,0) for k,v in anch.items()}, 'ncolors=',len(c))
PY
# ⇒ boot 全 0/LightGray=44/ncolors=386｜k24 GhostWhite=29637 余三色 0/LightGray=118/ncolors=724｜k23 全 0/LightGray=59/ncolors=636
```

---

## §8 边界 · 纪律 · 主动披露

1. **写域**：**唯一**新增件 ＝ 本载体（交付前现取 `ls` **不存在**）。**未覆盖**在册 `evidence-tail2g/**` 与他代证据目录；**未碰** `src/**`／`build/shape`／`build/MilBridge/tools/**`／`docs/**`／`upstream/**`（**只读**）。**未** `git add/commit/push`。
2. **只读**：本件命令为 `sha256sum`／`grep`／`sed`／`head`／`wc`／`ls`／`git status` ＋ **纯读** `python3`（切段计数／只解 PNG 像素）＋ 对托管上游件与生成器件的**只读** `read`／`grep`。**零构建、零跑腿、零显示位、零整趟门禁、零 `static-jaws-check.sh`、零 `git` 写、零相位改。**
3. **不引他人读数当证据**：`T-A35`／`T-A37`／`T-A38`／`T-A39` 只在 §0／§2／§3／§4 的理由里作**对照引用**（并逐处标注）；本件所有数值（`sha16`／`grep -c`／`grep -o|uniq -c`／切段计数／帧像素 `Counter`）**均为本席现取**。**唯一**承他人的是"`BaseParaClient.UpdateViewport` 无 P/Invoke／无导出"（§4 甲，**已标** `T-A38` 且**本席未重取**）。
4. **跨代／跨装置不可比（纪律 31/32）**：本件四腿取自**同一趟装置**（`:231`）＋**同批工具**（`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`）；`sample1` 与 `sample3`（`T-A38` 现场）**同为 `.so` 代** `606dad49ae7b34a1` ⇒ 只报**结果**，**不做减法**承重。
5. **口径纪律**：`[FSQTD] rc=0` **≠** 内容已画；`[FSQLL] rc=0` 是"**行表取数**"入口 —— 它**既**由"造行视觉"发**也**由行结果查询发（本件 B 类即后者）；因此本件**不**用"`[FSQLL]` 次数"当"造行次数"，而用**循环分解 ＋ 同现判据**（`P1`／`P2`）。`[FS_TLB]` 的 `attached-objects=present` 是**本侧自报**；`[VIS]` 是 **native 侧自记**判别器（`NOINFO=fspagedetails-page-change-tracking`），**不是**托管读数。
6. **未做（防被读宽）**：未实现任何增量（本件**只侦察＋归因＋选靶**）；未改相位；未动判据件/牙；未新增任何 `D-G<digits>` 登记编号；**未**跑反极性腿；**未**新增/覆盖任何证据目录；**未**量化 `NOINFO-CONTENT-VIEWPORT-VALUES`；**未**逐次归属 `[QPD]` 消费者（记 `NOINFO-QPD-CONSUMER-MAP`）。
7. **装置未就绪的重试披露**：本件**未跑腿** ⇒ 无重试；一切读数取自 `T-A39` 已落地的**在册**四腿现场，并由本席**逐格复算**。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-visual-recon.md | sha256sum | cut -c1-16`）= a72942494702c54a

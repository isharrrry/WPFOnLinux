# P1-tail2 · `T-A38` · 延迟视觉路径（`UpdateViewport`）驱动 ＋ 余 3 色锚 —— 只读侦察 ＋ 选靶

> **本件 `T-A38`（只读侦察子代理）交付**。**写域**：**唯一**新建件 ＝ 本载体 `build/MilBridge/P1-tail2-viewport-recon.md`。**未改任何仓内文件**（不碰 `src/**`／`build/**`／`build/MilBridge/tools/**`／装置件／`docs/**`）；**未构建**；**未跑腿、未占显示位**；**未跑整趟 `verify-all`**；**未跑 `static-jaws-check.sh`**；**未改相位**；未 `git add/commit/push`。现取 `git status --porcelain` 恰两项、**均先于本件且属他人**：`?? build/MilBridge/tasks-tail2/T-A38.md`、`?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`。
> **口径（不是证据）**：`T-A35`（`P1-tail2-coloranchor-recon.md`）／`T-A36`（`P1-tail2-attach-impl-report.md`）／`T-A37`（`P1-tail2-attachcontent-impl-report.md`）**只作对照**，其读数**一条未抄** —— 本件所有读数**现取**（只读 `sha256sum`／`grep`／`wc` ＋ **纯读** `PIL` 解 PNG ＋ 只读 `read`/`grep` 托管上游件）。
> **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**（原文）。
> **代际（现取）**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`606dad49ae7b34a1`**｜`bin/exports.txt` ＝ **683** 行｜`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ＝ `1757d610a687777c`（＝ `T-A37` 同代，**本席未换代**）。
> **被侦察现场**：**仓内在册**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2f/sample3/`（`app_g1.log` `sha16=015ed9f4c32908c2`／8754347 B；本席**只读**复算，**未覆盖、未新增样本**）＋ **仓内**托管上游源码 `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/**`（**只读**）。

---

## §0 结论速览（自包含）

1. **① `[FSQLL]` 的「行盒入口」在托管侧只有两个"造行视觉"的调用支**（§2.1，件:行＋原文）：`TextParaClient.cs:3389`（`UpdateViewportSimpleLines`，**唯一**调用点 `TextParaClient.cs:159`，只在 `UpdateViewport` 的**延迟支**里）与 `TextParaClient.cs:3218`（`RenderSimpleLines`，**唯一**调用点 `TextParaClient.cs:106`，只在 `ValidateVisual` 的**非延迟支**里）；其余 14 处调用点（`GetRectangles`／`InputHitTest`／`GetTextContentRange`／`GetFirstTextLineBaseline`…）都**不**创建行视觉。
2. **② 内容段（`parah=0x5d278403c034`，`cLines=1`、`attached-objects=not-present`）的 `[FSQLL]` 恒 `0`**（现取：全趟 `[FSQLL]` 直方图 `cLines=6×700`／`cLines=8×700`／`cLines=2×1`，**`cLines=1` 缺席**）⇒ 内容段的**行视觉从未被创建**。其 `ValidateVisual` **必**走**延迟支**（`TextParaClient.cs:75` → `SyncUpdateDeferredLineVisuals:1383`，在 `fUpdateInfoForLinesPresent=0` 时**只 `Clear()`**）⇒ **能救它的只剩 `UpdateViewportSimpleLines`**。
3. **③ 第一处断点 ＝ `TextParaClient.cs:3371`（`UpdateViewportSimpleLines` 的**第一道门**）**：`if (!IntersectsWithRectOnV(ref viewport) || textDetails.cLines == 0) { visualChildren.Clear(); }` —— 对内容段**恒**走"不相交"支 ⇒ 只 `Clear()`、**永不**到达 `:3389` 的 `ListSimpleFromTextPara`（＝`[FSQLL]`）。**这不是"没驱"**：现取计数证明 `UpdateViewport` 链**确实**下到了内容段（§3.3 的 349/698/701 三数闭合）。**断点的成因是视口几何**：内容段收到的是 `FigureParaClient.UpdateViewport`（`FigureParaClient.cs:137-143`）算出的 `viewport - ContentRect`，而内容段的 `_rect` 由 `PtsHelper.ArrangeParaList`（`:175-177`）从**子页轨自己的 `fsrc`** 推出 —— 两套坐标系（**页坐标的 `ContentRect`** vs **子页局部坐标的 `_rect`**）**在本侧入站几何下不可保证相交**。
4. **④ 唯一下一增量 ＝ `NATIVE-PTS-SUBPAGE-VIEWPORT-GEOMETRY`（native 侧入站几何自洽，＝ 候选路 (丙)）**：让 `FsQuerySubpageDetails` 的**子页轨 `fsrc`**／`FsQuerySubtrackDetails` 的 `fsrc`／`FsQueryFigureObjectDetails.fsrcFlowAround`／`ContentRect` 这一族几何**同源且与宿主 viewport 自洽**，使 `:3371` 的相交门**对内容段成立**。判据 4 条 ＋ 反极性见 §4。**不换靶／不换页**；**非合法终点**（链已通到内容段，前沿是**几何一致性**）。
5. **⑤ 具名 `NOINFO` 6 条**（§5），其中 `NOINFO-FSQLL-CALLER-DISCRIMINATION`（本侧**无法**在 native 面区分 `UpdatePortTrack` 与 `UpdateTrackVisuals`，承 `T-A37 §6.10`）、`NOINFO-CONTENT-VIEWPORT-VALUES`（相交门的两个操作数**无入站读数**）、`NOINFO-FIGURE-ONARRANGE-HANDLE`（`FsQueryFigureObjectDetails`=349 与 `subpage=(nil)`=704 的**配平**只是**推断**）是本轮新读出的三处边界。

---

## §1 证据 · 装置 · 指纹（现取）

| 件（本席现取 `sha16`／字节） | 值 | 备注 |
|---|---|---|
| `evidence-tail2f/sample3/app_g1.log` | **`015ed9f4c32908c2`**／`8754347` B | 主证据（`T-A37` 第二独立样本，本席**只读**复算） |
| `…/sample3/shots/g1/k24.png` | **`1487caf78fd88886`**／`1310720` px | `FlowDocumentDemo` |
| `…/sample3/shots/g1/boot.png` | **`b21eb530afd3c66c`** | 活锚基线 |
| `…/sample3/shots/g1/k23.png` | **`10d0b9d54e649c10`** | `RichTextBoxDemo` |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`606dad49ae7b34a1`** | 现代 |
| `upstream/…/PtsHost/TextParaClient.cs` | **`be3e7a145113dca5`** | 主侦察件（直编上游件） |
| `upstream/…/PtsHost/FigureParaClient.cs` | **`24b19f09144306cd`** |  |
| `upstream/…/PtsHost/ContainerParaClient.cs` | **`0d2e6aa79fdc035a`** |  |
| `upstream/…/PtsHost/PtsHelper.cs` | **`f2ed9552e983fed1`** |  |
| `upstream/…/PtsHost/StructuralCache.cs` | **`1ecca9f7d0b6cce9`** |  |
| `upstream/…/PtsHost/PtsPage.cs` | **`70be7828e8f9650d`** |  |
| `upstream/…/PtsHost/FlowDocumentPage.cs` | **`cd4d1c09c3edef3f`** |  |
| `upstream/…/documents/FlowDocumentFormatter.cs` | **`3eea1ec3ec50c3b4`** |  |
| `upstream/…/Documents/TextFlow.cs` | **`307318507c29cf3d`** |  |

**装置（现取 `session.txt`）**：`clicks=[24,23]`；`display=:235`（`DISPLAY_LEASE=official-caller-owned`）；`shim_sha16=606dad49ae7b34a1`／`pf_sha16=1757d610a687777c`；`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`；`APP_RC=143`（`SIGTERM`，仪器收的）；`FIVE_STABLE_G1=YES`。
**方法边界**：本席**未**重跑腿、**未**占显示位、**未**改判据件；帧面读数是**只读 PNG 解码**（`PIL`）；对托管上游件**只读** `read`/`grep`。
**探针闸**：本件帧面／机读面均取自 `WPF_PTS_DRIVE_PROBE` **缺省＝开**的那一趟（`T-A37` 现场）⇒ **同闸状态内可比**；跨闸状态**不**可比（见 `NOINFO-6`）。

---

## §2 ① 调用链现取：`[FSQLL]` 从哪来、凭什么被调

### 2.1 `FsQueryLineListSingle` 的**唯一** native 调用点（件:行＋原文）

`Pts.cs:3755-3761`（声明，**逐字**）：
```
        [DllImport(DllImport.PresentationNative)]
        internal static extern unsafe int FsQueryLineListSingle(
            IntPtr pfsContext,                  // IN:  ptr to FS context
            IntPtr pPara,                       // IN:  ptr to text para
            int cLines,                         // IN:  size of array of line descriptions
            FSLINEDESCRIPTIONSINGLE* rgLineDesc,// OUT: array of line descriptions
            out int cLineDesc);                 // OUT: actual number of lines
```
`PtsHelper.cs:642-656`（**唯一**调用点，**逐字**）：
```
        internal static unsafe void LineListSimpleFromTextPara(
            PtsContext ptsContext,
            IntPtr para,
            ref PTS.FSTEXTDETAILSFULL textDetails,
            out PTS.FSLINEDESCRIPTIONSINGLE [] arrayLineDesc)
        {
            arrayLineDesc = new PTS.FSLINEDESCRIPTIONSINGLE [textDetails.cLines];
            int lineCount;
            fixed (PTS.FSLINEDESCRIPTIONSINGLE* rgLineDesc = arrayLineDesc)
            {
                PTS.Validate(PTS.FsQueryLineListSingle(ptsContext.Context, para, textDetails.cLines,
                    rgLineDesc, out lineCount));
            }
            ErrorHandler.Assert(textDetails.cLines == lineCount, ErrorHandler.PTSObjectsCountMismatch);
        }
```

### 2.2 `LineListSimpleFromTextPara` 的 16 个托管调用点，**只有 2 个**造行视觉（`grep -n` 现取）

| # | 件:行 | 所属 body | 造行视觉？ |
|---|---|---|---|
| **1** | `TextParaClient.cs:3389` | `UpdateViewportSimpleLines` | **是**（**唯一**调用点 `:159`，在 `UpdateViewport` 的延迟支内） |
| **2** | `TextParaClient.cs:3218` | `RenderSimpleLines` | **是**（**唯一**调用点 `:106`，在 `ValidateVisual` 的**非**延迟支内） |
| 3-16 | `TextParaClient.cs:536／995／1254／1398／1523／1644／1827／2374／2592／2882／3101／3218…` | `GetRectangles`／`InputHitTest`／`GetTextContentRange`／`GetFirstTextLineBaseline`／`GetTightBounding…` 等 | **否**（几何/命中/范围查询；其中 `:1398` 在 `SyncUpdateDeferredLineVisuals` 内，**需** `fUpdateInfoForLinesPresent=1 ∧ _lineIndexFirstVisual != -1`，本侧**如实**填 `0` ⇒ 不可达） |

### 2.3 两条"造行视觉"支的**入口条件**（件:行＋原文）

`TextParaClient.cs:52-84`（`ValidateVisual` 的头，**逐字**）：
```
            if (textDetails.fsktd == PTS.FSKTEXTDETAILS.fsktdFull)
            {
                …
                if(IsDeferredVisualCreationSupported(ref textDetails.u.full))
                {
                    // Transition to from no deferred visuals to deferred visuals -- Ignore update info
                    if(_lineIndexFirstVisual == -1 && lineContainerVisual.Children.Count > 0)
                    {
                        ignoreUpdateInfo = true;
                    }

                    SyncUpdateDeferredLineVisuals(lineContainerVisual.Children, ref textDetails.u.full, ignoreUpdateInfo);
                }
                else
                {
                    …
                    // Add visuals for all lines.
                    if (textDetails.u.full.cLines > 0)
                    {
                        if (!PTS.ToBoolean(textDetails.u.full.fLinesComposite))
                        {
                            // (a) full with simple lines
                            RenderSimpleLines(lineContainerVisual, ref textDetails.u.full, ignoreUpdateInfo);
```
`TextParaClient.cs:145-160`（`UpdateViewport` 的头，**逐字**）：
```
        internal override void UpdateViewport(ref PTS.FSRECT viewport)
        {
            // Here's where the magic happens.
            PTS.FSTEXTDETAILS textDetails;
            PTS.Validate(PTS.FsQueryTextDetails(PtsContext.Context, _paraHandle, out textDetails));
            Invariant.Assert(textDetails.fsktd == PTS.FSKTEXTDETAILS.fsktdFull, "Only 'full' text paragraph type is expected.");

            if (IsDeferredVisualCreationSupported(ref textDetails.u.full))
            {
                // Query paragraph details and render its content
                ContainerVisual lineContainerVisual = _visual;

                Debug.Assert(!((TextParagraph) Paragraph).HasFiguresFloatersOrInlineObjects());

                UpdateViewportSimpleLines(lineContainerVisual, ref textDetails.u.full, ref viewport);
            }
```
`TextParaClient.cs:3837-3850`（延迟判据，**逐字**）：
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
`StructuralCache.cs:375-378`（**逐字**）：
```
        internal bool IsDeferredVisualCreationSupported
        {
            get { return _currentPage != null && !_currentPage.FinitePage; }
        }
```
`TextParagraph.cs:1352-1360`（**逐字**）：
```
        internal bool HasFiguresFloatersOrInlineObjects()
        {
            if(HasFiguresOrFloaters() || (_inlineObjects != null && _inlineObjects.Count > 0))
            {
                return true;
            }

            return false;
        }
```

### 2.4 **第一道门**（件:行＋原文）—— 本件的断点所在

`TextParaClient.cs:3359-3389`（**逐字**，含原文门与唯一的取数点）：
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
                    // Index of first visible line
                    int lineIndexFirstVisible = -1;
                    …
                    PTS.FSLINEDESCRIPTIONSINGLE[] arrayLineDesc;
                    PtsHelper.LineListSimpleFromTextPara(PtsContext, _paraHandle, ref textDetails, out arrayLineDesc);   // ← :3389 ＝ [FSQLL]
```
`TextParaClient.cs:3314-3318`（相交谓词，**逐字**——**它只读 `_rect`**）：
```
        private bool IntersectsWithRectOnV(ref PTS.FSRECT rect)
        {
            return ((_rect.v) <= (rect.v + rect.dv)) &&
                   ((_rect.v + _rect.dv) >= rect.v);
        }
```

### 2.5 上游：谁把 `viewport` 交给内容段（件:行＋原文）

`FigureParaClient.cs:131-152`（**逐字**）：
```
        internal override void UpdateViewport(ref PTS.FSRECT viewport)
        {
            // Query subpage details
            PTS.FSSUBPAGEDETAILS subpageDetails;
            PTS.Validate(PTS.FsQuerySubpageDetails(PtsContext.Context, _paraHandle, out subpageDetails));

            PTS.FSRECT viewportSubpage = new PTS.FSRECT
            {
                u = viewport.u - ContentRect.u,
                v = viewport.v - ContentRect.v,
                du = viewport.du,
                dv = viewport.dv
            };
            …
            if (PTS.ToBoolean(subpageDetails.fSimple))
            {
                PtsHelper.UpdateViewportTrack(PtsContext, ref subpageDetails.u.simple.trackdescr, ref viewportSubpage);
```
`PtsHelper.cs:310-351`（**逐字**，`UpdateViewportTrack`／`UpdateViewportParaList`）：
```
        internal static void UpdateViewportTrack(
            PtsContext ptsContext,
            ref PTS.FSTRACKDESCRIPTION trackDesc,
            ref PTS.FSRECT viewport)
        {
            // There is possibility to get empty track. (example: large figures)
            if (trackDesc.pfstrack != IntPtr.Zero)
            {
                // Get track details
                PTS.FSTRACKDETAILS trackDetails;
                PTS.Validate(PTS.FsQueryTrackDetails(ptsContext.Context, trackDesc.pfstrack, out trackDetails));

                // There is possibility to get empty track.
                if (trackDetails.cParas != 0)
                {
                    // Get list of paragraphs
                    PTS.FSPARADESCRIPTION[] arrayParaDesc;
                    ParaListFromTrack(ptsContext, trackDesc.pfstrack, ref trackDetails, out arrayParaDesc);

                    // Arrange paragraphs
                    UpdateViewportParaList(ptsContext, arrayParaDesc, ref viewport);
                }
            }
        }
        …
                paraClient.UpdateViewport(ref viewport);
```
`ContainerParaClient.cs:214-230`（**逐字**）：
```
        internal override void UpdateViewport(ref PTS.FSRECT viewport)
        {
            // Query paragraph details
            PTS.FSSUBTRACKDETAILS subtrackDetails;
            PTS.Validate(PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails));

            // There might be possibility to get empty sub-track, skip the sub-track in such case.
            if (subtrackDetails.cParas != 0)
            {
                // Get list of paragraphs
                PTS.FSPARADESCRIPTION [] arrayParaDesc;
                PtsHelper.ParaListFromSubtrack(PtsContext, _paraHandle, ref subtrackDetails, out arrayParaDesc);

                // Render list of paragraphs
                PtsHelper.UpdateViewportParaList(PtsContext, arrayParaDesc, ref viewport);
            }
        }
```
`TextParaClient.cs:165-181`（宿主段落 `UpdateViewport` 的**附属对象递归**，**逐字**）：
```
            int attachedObjectCount = textDetails.u.full.cAttachedObjects;

            // Recurse into figures and floaters
            if (attachedObjectCount > 0)
            {
                // Get list of attached objects
                PTS.FSATTACHEDOBJECTDESCRIPTION [] arrayAttachedObjectDesc;
                PtsHelper.AttachedObjectListFromParagraph(PtsContext, _paraHandle, attachedObjectCount, out arrayAttachedObjectDesc);

                // Arrange attached objects
                for (int index = 0; index < arrayAttachedObjectDesc.Length; index++)
                {
                    PTS.FSATTACHEDOBJECTDESCRIPTION attachedObjectDesc = arrayAttachedObjectDesc[index];

                    BaseParaClient paraClient = PtsContext.HandleToObject(attachedObjectDesc.pfsparaclient) as BaseParaClient;
                    PTS.ValidateHandle(paraClient);

                    paraClient.UpdateViewport(ref viewport);
                }
            }
```
**页级起点**（`UpdateViewport` 链的入口，**逐字**）：
- `FlowDocumentFormatter.cs:114-130`：`internal void Arrange(Size arrangeSize, Rect viewport)` → `… _documentPage.UpdateViewport(ref fsrectViewport, true);`
- `FlowDocumentPage.cs:616`：`internal void UpdateViewport(ref PTS.FSRECT viewport, bool drawBackground)` → `:642 _ptsPage.UpdateViewport(ref contentViewportTextDpi);`
- `PtsPage.cs:547`：`internal void UpdateViewport(ref PTS.FSRECT viewport)` → `:563 PtsHelper.UpdateViewportTrack(PtsContext, ref pageDetails.u.simple.trackdescr, ref viewport);`
- `TextFlow.cs:796`：`_documentPage.UpdateViewport(ref _viewport, false);`

### 2.6 内容段的**几何从哪来**（关键：两套坐标系）

- 内容段 `_rect` ← `PtsHelper.ArrangeParaList`（`PtsHelper.cs:145-181`，**逐字**）：
```
                int dvrTopSpace = arrayParaDesc[index].dvrTopSpace;
                PTS.FSRECT rcPara = rcTrackContent;
                rcPara.v += dvrPara + dvrTopSpace;
                rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;

                paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);
```
  其 `rcTrackContent` 来自 `trackDesc.fsrc`（`ArrangeTrack`）或 `subtrackDetails.fsrc`（`ContainerParaClient.OnArrange:72`）；**都是子页/子轨的局部 `fsrc`**（现取 `[FSQSTD-SRC] … du=768 dv=576 … src=declared-geometry`）。
- `viewportSubpage` ← `FigureParaClient.UpdateViewport:137-143`，减的是 **`ContentRect`（页坐标）**；`ContentRect` 在 `FigureParaClient.OnArrange:73-81` 由 `_rect`（＝ `fsrcFlowAround`，现取 `(30000,20000,42000,15000)`）推出。
- ⇒ **两个操作数来自两套坐标系**（页坐标 vs 子页局部坐标），`:3371` 的相交门**在本侧入站几何下不可保证成立**（§3.3 现取：它**确实**不成立）。

---

## §3 ② 现取：`UpdateViewport` 链**确实**下到了内容段（计数闭合）

> 承 `T-A37 §6.10` 的未决问题（"本侧只能观测到 `[FSPARALIST-FILL-SP]` 698 次，无法分辨其中多少来自 `UpdateViewportTrack` 而非 `UpdateTrackVisuals`"）。**本件用三处独立计数的配平把它判开**。

### 3.1 现取计数（同一趟，`grep -c`／`grep -o | uniq -c`）

| 量 | 值 |
|---|---|
| `[FSQLL]` 总行数 | **1401** |
| `[FSQLL]` 的 `cLines` 直方图 | **`cLines=6 ×700`｜`cLines=8 ×700`｜`cLines=2 ×1`** ⇒ **`cLines=1` 恒缺席** |
| `[FSQLL]` 逐 `parah`（去双计后） | 宿主 `0x…31054`＝**698**｜`0x…340d4`＝**349**｜`0x…32894`＝**349**｜其余小量 |
| `[FSQTD]` 逐 `parah` | 宿主 `0x…31054`＝**1745**｜`0x…340d4`＝**1396**｜`0x…32894`＝**1396`｜**内容段 `0x…3c034`＝698** |
| 宿主 `[FS_TLB]` 的 `attached-objects` | **`present ×1745`**（100%，`figure=1 floater=1`） |
| 内容段 `[FS_TLB]` 的 `attached-objects` | **`not-present(true-queried) ×698`** |
| `[FS_ATT] entry=FsQueryAttachedObjectList` | 总 **701**；`para=0x…31054`（宿主）＝**698** |
| `[FS_ATT] entry=FsQueryFigureObjectDetails` | **349**（**唯一**调用点 `TextParaClient.cs:1344`，在 `TextParaClient.OnArrange` 内） |
| `[FS_ATT] entry=FsQuerySubpageDetails subpage=0x5d278413e068`（图） | **698** |
| `[FS_ATT] entry=FsQuerySubpageDetails subpage=(nil)` | **704** |
| `[FSPARALIST-FILL-SP]` | 总 **698**，`track` **唯一**＝`0x5d278413e068` |
| `[FSQSTD]`／`[FSQSPL]` 逐 `psub` | `0x5d278416a2f4`／`0x5d278403cc54`／`0x5d27840334b4`／`0x5d2784031c74`＝各 **1047**；**`0x5d277e1075f4`／`0x5d278403b414`＝各 698**（后两个＝图内容树的两级容器） |
| `[HC-UNHANDLED]`／`[FS_PAGE_GAP]` | **1**／**1** |
| `[VIS]`（页视觉帧，native 发点＝`FsQueryTrackParaList` 的判别器） | **4** |

### 3.2 一个"轮"的现取形态（`sed -n '1105,1120p'`，逐行）

```
[FS_TLB]  entry=FsQueryTextDetails parah=0x5d2784031054 cLines=8 … attached-objects=present queried=8 figure=1 floater=1
[FS_ATT]  rc=0 entry=FsQueryAttachedObjectList para=0x5d2784031054 cAttachedObjects=2 out=WRITTEN bytes=144 src=ledger:fl_att[]
[FS_ATT]  rc=0 entry=FsQuerySubpageDetails subpage=0x5d278413e068 fSimple=1 cParas=1 track=0x5d278413e068 fsrc=(0,0,37810,10810) src=owned-subpage
[WINDOW-SPLIT] where=FsQueryTrackParaList window=out action=summarize-only src=in-window-subenum …
[FSPARALIST-FILL-SP] rc=0 reason=ok entry=FsQueryTrackParaList track=0x5d278413e068 cParas=1 pfspara=0x5d277e1075f4 client=0x1a src=owned-subpage(cont_obj+managed-176)
[FSQSTD] psub=0x5d277e1075f4 cParas=1 …            ← A（Figure 的 _mainTextSegment 容器）
[FSQSPL] psub=0x5d277e1075f4 cParas=1 made=1 …
[FSQSTD] psub=0x5d278403b414 cParas=1 …            ← B（Figure 内 <Paragraph> 容器）
[FSQSPL] psub=0x5d278403b414 cParas=1 made=1 …
[FSQTD]  parah=0x5d278403c034 cLines=1 dcpFirst=0 dcpLim=41 …   ← 内容段（第 1 次）
[FS_TLB] …
[FSQTD]  parah=0x5d278403c034 cLines=1 …                        ← 内容段（第 2 次，紧邻）
[FS_TLB] …
[FS_ATT] rc=0 entry=FsQuerySubpageDetails subpage=(nil) …       ← FloaterParaClient 的
```

### 3.3 判（三数闭合 ⇒ `UpdateViewport` 链**已到内容段**）

设一个"轮"＝**一次 `ValidateVisual` + 一次 `UpdateViewport`**（同轮成对），共 **R** 轮（现取 `R = 349`，由 `FsQueryFigureObjectDetails`＝349 定标，本席**未**独立观测它；见 `NOINFO-FIGURE-ONARRANGE-HANDLE`）。

| 入口 | 每轮次数 | 乘 R=349 | 实测 | 判 |
|---|---|---|---|---|
| 图 `FsQuerySubpageDetails`（`ValidateVisual:346` ＋ `UpdateViewport:135`） | 2 | 698 | **698** | ✅ |
| `[FSPARALIST-FILL-SP]`（`UpdateTrackVisuals:218/225` ＋ `UpdateViewportTrack:320/327`） | 2 | 698 | **698** | ✅ |
| A 子轨 `[FSQSTD]/[FSQSPL]`（`ContainerParaClient.ValidateVisual:177` ＋ `UpdateViewport:218`） | 2 | 698 | **698** | ✅ |
| B 子轨 `[FSQSTD]/[FSQSPL]`（同形） | 2 | 698 | **698** | ✅ |
| 内容段 `[FSQTD]`（`C.ValidateVisual:56` ＋ `C.UpdateViewport:149`） | **2** | **698** | **698** | ✅ |
| 宿主 `[FS_ATT] FsQueryAttachedObjectList`（`A_rr:1316`×349 ＋ `ValidateVisualFloatersAndFigures:3745`×R₁ ＋ `UpdateViewport:169`×R₂，R₁+R₂=R=349） | —— | 349+349=**698** | **701**（＋3 来自几何/范围查询） | ✅ |

⇒ **可算出的结论**：**`FigureParaClient.UpdateViewport`（`FigureParaClient.cs:131`）与 `ContainerParaClient.UpdateViewport`（`ContainerParaClient.cs:214`）与内容段 `TextParaClient.UpdateViewport`（`TextParaClient.cs:145`）在本趟**都跑到了**（每轮各一次）；内容段每轮被 `UpdateViewport` 与 `ValidateVisual` **各问一次**（＝ `[FSQTD] 698 = 2×349` 的**唯一**自洽解释）。
⇒ **因此断点不在"没驱 `UpdateViewport`"，而在 `UpdateViewport` 之内**：`:3371` 的相交门对内容段**恒真** ⇒ `visualChildren.Clear()` ⇒ **`[FSQLL]` 恒 0**。
⇒ 旁证同向：`[VIS]`（＝`ValidateVisual` 系页视觉帧，native 判别器）**只有 4** ⇒ 视觉支是少数；**`UpdateViewport` 支是多数**。

**射程（写死，防被读宽）**：本件**只证**「`UpdateViewport` 链已到内容段、`:3371` 门恒真」；**未**读出门的两个操作数（`viewport`／`_rect`）的数值 ⇒ 成因归属记 `NOINFO-CONTENT-VIEWPORT-VALUES`。本件**不**据此断言"色锚必转绿"（帧面绿永不单独支撑排版结论）。

---

## §4 ③ 候选路（逐条 可及 ∧ 可行 ∧ 代价 ∧ `P8`）＋ 唯一选靶 ＋ 判据草案

### 4.1 甲／乙／丙

| 路 | 可及性 | 可行性 | 代价 | `P8` 落点 | 判 |
|---|---|---|---|---|---|
| **(甲) native 侧"直接发起" `UpdateViewport`** | ❌ **不可及**：`BaseParaClient.UpdateViewport` 是**托管内部虚方法**（`BaseParaClient.cs:155` `internal virtual void UpdateViewport(ref PTS.FSRECT viewport) { }`），**无 P/Invoke、无导出**；native 侧**没有任何槽**能吃它（现取 `FSCBK` 全表：`cbkgen`／`cbktxt`／`cbkobj`／`cbkfig`／`cbkwrd`，**零** `UpdateViewport` 类槽） | —— | —— | —— | **不可取**（不是"难"，是**没有信道**） |
| **(乙) 托管侧（含生成器）** | ✅ **可及**：`upstream/wpf/**` 是**直编上游件**（`csproj` 直引，见 `P1-tail2-hostface-recon.md §3.4` 的范式）；本仓**已**有"生成器注入托管改动"的先例（`build/PresentationFramework.Linux/reapply-patches.py` ＋ `PtsCache.Linux.cs`） | ⚠️ **可行但重**：要改 `TextParaClient.UpdateViewport`／`FigureParaClient.UpdateViewport`／`ContainerParaClient.UpdateViewport` 一族，须**新增一个 `PresentationFramework` 生成器**（现只有 `PtsCache.cs` 被 `Remove`/替换），且 `Invariant.Assert` 一个都不许删／放宽 | **高**（新生成器 ＋ 上游件漂移面 ＋ 每趟波重建 PF 环成员） | **`build/shims/**` ＋ 新生成器**（`P8`：不直改上游件） | **可做，但代价最高，且**不是**本断点的必要解** |
| **(丙) 其它 ⇒ native 侧"入站几何自洽"** | ✅ **可及**：全部是**已落地**的 native 入口 —— `FsQuerySubpageDetails`（子页轨 `trackdescr.fsrc`）／`FsQuerySubtrackDetails`（`fsrc`／`du`／`dv`）／`FsQueryFigureObjectDetails`（`fsrcFlowAround`）／`FsQueryTextDetails`（`fsupdinf`） | ✅ **可行**：本侧是这些**几何的唯一作者**（现取 `[FSQSTD-SRC] … src=declared-geometry` ⇒ 现在是**声明值**，不是自洽值）；把"子页局部几何"与"页坐标 `ContentRect`"改成**同源可换算**即可 | **中低**（单文件 `win32_pts.c`；不增导出、不动 `FSCBK` 布局、不动帧面外任何东西） | **`src/WpfGfx.Linux.Native/src/win32_pts.c`**（不涉生成件；`bin/exports.txt` **随动＝0**） | ✅ **唯一选靶** |

### 4.2 唯一下一增量（具名）

> **`NATIVE-PTS-SUBPAGE-VIEWPORT-GEOMETRY`**：在 `src/WpfGfx.Linux.Native/src/win32_pts.c` 上，让**内容段的视口/矩形一族几何同源自洽** —— 即 `FsQuerySubpageDetails`（子页轨）／`FsQuerySubtrackDetails`（A／B 子轨）／`FsQueryFigureObjectDetails`（`fsrcFlowAround`）给出的 `fsrc`，与 `FigureParaClient.UpdateViewport` 里被减掉的 `ContentRect`（由 `fsrcFlowAround` 推出）**换算一致**，使 `TextParaClient.IntersectsWithRectOnV`（`TextParaClient.cs:3314`）对内容段为**真** ⇒ `UpdateViewportSimpleLines` 走到 `:3389` ⇒ `[FSQLL] cLines=1` **首次出现** ⇒ 行视觉被创建。
> **零假值**：几何必须来自**同一条**入站链的同一份声明（`declared-geometry`），**不**允许为了"让相交为真"而造一个**假的** `fsrc`／`dvrUsed`；`fsupdinf` 仍**如实**填（`fUpdateInfoForLinesPresent=0` **不许**为了触发 `:1398` 而置 1 —— 那语义是假：本段无更新信息）。
> **未驱动／无几何源 ⇒ 仍拒（出参一字不写）**；`P8`。**落点**：`win32_pts.c`。

**理由（逐条，均有 §3 现取证据）**：
1. **链已通到内容段**（§3.3 三数闭合）⇒ 前沿**不在**"接线"，在**几何**。
2. **`[FSQLL]` 的唯一可救支**是 `UpdateViewportSimpleLines`（§2.2／2.3），其门 `:3371` 是**相交**；`cLines==0` 不成立（现取内容段 `cLines=1` 恒 698 行）。
3. **门的两个操作数分属两套坐标系**（§2.6）：`viewportSubpage` 由**页坐标**的 `ContentRect` 平移得到，内容段 `_rect` 来自**子页局部**的 `fsrc` ⇒ 现取不成立（否则 `[FSQLL] ≥ 1`）。
4. **本侧是该几何的唯一作者**（现取自陈 `src=declared-geometry`）⇒ 该路**不**需要新增任何导出、不破 `FSCBK` 布局（`甲` 的死因）、也不动托管件（`乙` 的代价）。
5. **触 `fp_inputs()`**：`src/WpfGfx.Linux.Native/src/**` 在覆盖面内 ⇒ 流程上须排在采样前并同趟过 `[42] --fp-manifest --expect`。

### 4.3 判据草案（4 条可证伪 ＋ 反极性必红腿）

| # | 判据（可证伪的单行式） | **反极性（必红腿）** |
|---|---|---|
| **D0 分流/诊断（先跑）** | `[FSQLL] rc=0` 的 `cLines` 直方图**首次**出现 `cLines=1`（且 `parah` ＝内容段句柄，与 `[FSQTD] … cLines=1` 的 698 次**对得上**）。⇒ 断点属"`:3371` 门"（`丙` 生效）。**若 `cLines=1` 仍为 0** ⇒ 断点改判为"`FigureParaClient.UpdateViewport` 未进入"，`(丙)` **判负**、转 `(乙)`。 | 用**假几何**（把 `fsrc` 写成让相交为真的常量）换 `cLines=1` ⇒ **必红**（`P8` 恒绿陷阱；且与 `[FSQSTD-SRC] src=declared-geometry` 的**唯一来源**相冲）。 |
| **D1 余 3 具名色各 ≥200px（可证伪）** | `k=24` 帧上 **`Beige`／`DarkGreen`／`LightGoldenrodYellow` 各 `≥200 px`**（`pts-pages-guard.sh` 现取 `PTS_COLORANCHOR` 逐色；判词 `expect_min=200`），`hits` 由 **1 → 4**，`PTS_COLORANCHOR=PASS`。 | 只让某**近似灰/白**超阈（如 `(249,249,249)`）⇒ **必红**；把 `k=24` 的锚**推广**到 `k=23` ⇒ **必红**（`k=23` 仍 `NOINFO`）。 |
| **D2 baseline 仍全 0（活锚）** | `boot.png`（`b21eb530afd3c66c`）四色**仍全 0**；`LightGray` **不入集**。 | 若 `boot` 出现任一具名色 ⇒ 锚被污染 ⇒ **必红**。 |
| **D3 帧面成对 ＋ 不得把空白读成绿** | `k24` 帧 `sha16` 与 `T-A37` 的 `1487caf78fd88886` **必须变**（＝真有像素差）；`AE(boot,k24)` 的差异分量**落在内容区**（不是仅蓝块/页签位移）；**两独立样本**同值。 | 只挪动蓝块/页签 ⇒ **必红**；把 `colors` 变多当绿 ⇒ **必红**；`GhostWhite`（**Background**）当"内容真绘出" ⇒ **必红**。 |
| **D4 症状门无回归 ＋ 失败必留痕** | `alive=yes`／`app_rc=143`／`failfast=0`／`magenta=0`／`ink=480000`／`ns=…FlowDocumentDemo` 逐格**不变**；`[HC-UNHANDLED]` **恰 1**（**不许涨**）；几何不成立时**必**打具名行（`entry=`＋`reason=`），与"真 0 次"可**分**。 | 静默 stub（返非 0 零痕迹）⇒ 与"真 0 次调用"不可分 ⇒ **必红**。 |

**最便宜的反极性腿（本件只登记、不跑）**：置空／撤掉"子页视口几何自洽"（回到 `declared-geometry`）⇒ **余 3 色必须回 0**、`[FSQLL] cLines=1` 必须**回 0**，而 `[HC-UNHANDLED]` **不得下降**。

### 4.4 另两个选项（**不推荐**，如实并列）

- **换靶／换页**：**不** —— 靶页身份**正确**且有页签像素自证（`T-A35 §2.2`）；`k=24` 四色的**出处唯一**（`T-A35 §3.1`：全在 `<Figure>`／`<Floater>` 内）。
- **合法终点**：**不** —— `UpdateViewport` 链**已通到内容段**（§3.3 三数闭合 698/698/698）⇒ 前沿是**几何一致性**这一**可做项**，不是"不可做"。

---

## §5 ④ 具名 `NOINFO`（逐条给"消掉需要什么"）

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-CONTENT-VIEWPORT-VALUES` | `:3371` 门的**两个操作数**（`viewport.v/.dv` 与内容段 `_rect.v/.dv`）的**数值** | 本席**无**渲染面/托管面读数；只能从"`[FSQLL] cLines=1` 恒 0"**反推**门恒真 | 在渲染面（`UpdateViewportSimpleLines` 入口）加**只读**旁证，或 native 在 `FsQuerySubpageDetails` 打出宿主 `viewport` 与子页 `fsrc` 的**成对**值 |
| `NOINFO-FSQLL-CALLER-DISCRIMINATION` | **native 面**区分 `UpdateViewportTrack` 与 `UpdateTrackVisuals` 的面（承 `T-A37 §6.10`） | 两条链对 native 的面**逐字节相同**（各 1×`FsQueryTrackDetails` ＋ 1×`FsQueryTrackParaList`）；本件**只**能用**计数守恒**（§3.3）**间接**判开 | native 在 `FsQueryTrackParaList` 里加**具名**调用者判别器（承 `[VIS]` 的判别器范式） |
| `NOINFO-FIGURE-ONARRANGE-HANDLE` | `FsQueryFigureObjectDetails`＝**349** 与 `subpage=(nil)`＝**704** 的**配平归属**（本席**推断**：349 次 `OnArrange` 走的是"`SubpageHandle` 未设的那一代 `FigureParaClient`"，故返回空子页） | 349／704 两数现取；**无**逐次归属读数；本席**未**验证 | native 在 `FsQuerySubpageDetails` 打出调用者的**对象代**（或按 `pfsparaclient` 分桶） |
| `NOINFO-SUBPAGE-GEOMETRY-SEMANTICS` | 子页/子轨 `fsrc` 的**真机语义**（现取全 `declared-geometry`；`FigureParaClient.ContentRect` 与 `fsrc` 的**换算关系**本侧自定） | `[FSQSTD-SRC] … NOINFO=fsupdinf(no-source),fsrc(declared-geometry)` | 真机对拍，或驱动点直插几何入站源（承 `T-A36` `NOINFO-subpage-geometry-declared`） |
| `NOINFO-K23-ANCHOR` | `k=23` 色锚 | 守卫现取 `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（`RichTextBoxDemo.xaml` 无具名色） | 为 `k=23` 另立**活锚**（**严禁**用 `k=24` 的锚推广） |
| `NOINFO-PROBE-GATE-OFF` | **探针闸关闭**下的帧面 | 本件帧面均取自 `WPF_PTS_DRIVE_PROBE` **缺省＝开**的一趟 | 以 `WPF_PTS_DRIVE_PROBE=0` 跑一趟反极性腿取帧面（**本任务未要求**） |

---

## §6 可复跑单行命令原文（本席实跑，现取）

```sh
cd /home/links-dev/netTest/GitProj/WPFOnLinux
D=build/MilBridge/tests/PtsPagesProbe/evidence-tail2f/sample3

# 代际 / 证据指纹
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16        # ⇒ 606dad49ae7b34a1
sha256sum $D/app_g1.log | cut -c1-16                                      # ⇒ 015ed9f4c32908c2
sha256sum $D/shots/g1/{boot,k23,k24}.png | cut -c1-16                     # ⇒ b21eb530afd3c66c / 10d0b9d54e649c10 / 1487caf78fd88886

# ① 行盒入口的调用链（托管，只读）
grep -n 'LineListSimpleFromTextPara\|FsQueryLineListSingle' \
  upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/{Pts.cs,PtsHelper.cs,TextParaClient.cs}
grep -n 'void UpdateViewport\|UpdateViewportSimpleLines\|IntersectsWithRectOnV' \
  upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/TextParaClient.cs

# ② 现取计数（本趟）
grep -c '\[FSQLL\]' $D/app_g1.log                                          # ⇒ 1401
grep '\[FSQLL\]' $D/app_g1.log | grep -o 'cLines=[0-9]*' | sort | uniq -c  # ⇒ 2×1, 6×700, 8×700（无 1）
grep '\[FSQLL\]' $D/app_g1.log | grep -o 'parah=0x[0-9a-f]*' | sort | uniq -c | sort -rn | head
grep '\[FSQTD\]' $D/app_g1.log | grep -o 'parah=0x[0-9a-f]*' | sort | uniq -c | sort -rn | head
grep -c '\[FSPARALIST-FILL-SP\]' $D/app_g1.log                             # ⇒ 698
grep '\[FSPARALIST-FILL-SP\]' $D/app_g1.log | grep -o 'track=0x[0-9a-f]*' | sort | uniq -c   # ⇒ 698 track=0x5d278413e068
grep -c 'entry=FsQueryFigureObjectDetails' $D/app_g1.log                   # ⇒ 349
grep -c 'entry=FsQuerySubpageDetails subpage=0x5d278413e068' $D/app_g1.log # ⇒ 698
grep -c 'entry=FsQuerySubpageDetails subpage=(nil)' $D/app_g1.log          # ⇒ 704
grep '\[FSQSTD\] rc=0' $D/app_g1.log | grep -o 'psub=0x[0-9a-f]*' | sort | uniq -c | sort -rn   # ⇒ 1047×4, 698×2, 3×5
grep -c 'entry=FsQueryAttachedObjectList' $D/app_g1.log                    # ⇒ 701
grep -c '^\[VIS\]' $D/app_g1.log                                           # ⇒ 4
grep -c 'HC-UNHANDLED' $D/app_g1.log; grep -c 'FS_PAGE_GAP' $D/app_g1.log  # ⇒ 1 / 1

# ③ 帧面（纯读 PNG）
python3 - <<'PY'
from PIL import Image; import collections
D="build/MilBridge/tests/PtsPagesProbe/evidence-tail2f/sample3/shots/g1"
anch={'GhostWhite':(248,248,255),'Beige':(245,245,220),'DarkGreen':(0,100,0),'LightGoldenrodYellow':(250,250,210)}
for f in ('boot.png','k24.png','k23.png'):
    c=collections.Counter(map(tuple,Image.open(f"{D}/{f}").convert("RGB").getdata()))
    print(f, {k:c.get(v,0) for k,v in anch.items()}, 'ncolors=',len(c))
PY
# ⇒ boot 全 0/ncolors=386｜k24 GhostWhite=29637 余三色 0/ncolors=724｜k23 全 0/ncolors=636
```

---

## §7 边界 · 纪律 · 主动披露

1. **写域**：**唯一**新增件 ＝ 本载体（交付前现取 `ls` **不存在**）。**未覆盖**在册 `evidence-tail2f/**` 与他代证据目录；**未碰** `src/**`／`build/shape`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`／`upstream/**`（**只读**）。**未** `git add/commit/push`。
2. **只读**：本件命令为 `sha256sum`／`grep`／`sed`／`head`／`wc`／`ls`／`git status` ＋ **纯读** `python3`（只解 PNG 像素）＋ 对托管上游件的**只读** `read`／`grep`。**零构建、零跑腿、零显示位、零整趟门禁、零 `static-jaws-check.sh`、零 `git` 写、零相位改。**
3. **不引他人读数当证据**：`T-A35`／`T-A36`／`T-A37` 只在 §0／§2／§3／§4 的理由里作**对照引用**（并逐处标注）；本件所有数值（`sha16`／`grep -c`／`grep -o|uniq -c`／帧像素 `Counter`）**均为本席现取**。`§3.3` 的行/段归属（宿主／内容段／A／B 的句柄→角色）是**本席**由 `[FS_TLB] attached-objects=` 与相邻探针**推定**的，**非**他人读数。
4. **跨代／跨装置不可比（纪律 31/32）**：本件只用**一趟**（`sample3`）＋ `T-A37` 同代指纹；**不做减法**承重。
5. **口径纪律**：`[FSQTD] rc=0`／`rc=0 reason=ok` **≠** 内容已画；`[FS_TBL]` 的 `attached-objects=present` 是**本侧自报**（写者自证，作**指向**不作**裁定**）；`[VIS]` 是 **native 侧自记**判别器（`NOINFO=fspagedetails-page-change-tracking`），**不是**托管读数。
6. **未做（防被读宽）**：未实现任何增量（本件**只侦察＋归因＋选靶**）；未改相位；未动判据件/牙；未新增任何 `D-G<digits>` 登记编号；**未**跑反极性腿；**未**新增/覆盖任何证据目录；**未**量化 `NOINFO-CONTENT-VIEWPORT-VALUES`（无渲染面读数）。
7. **装置未就绪的重试披露**：本件**未跑腿** ⇒ 无重试；一切读数取自 `T-A37` 已落地的**在册**现场（`evidence-tail2f/sample3/`），并由本席**逐格复算**。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-viewport-recon.md | sha256sum | cut -c1-16`）= 43e836064f759e18

# P1-tail2 · `T-A43` · 内容段 `UpdateViewport` 到达性 ＋ 视觉子树 —— 只读侦察 ＋ 选靶

> **本件 `T-A43`（只读侦察子代理）交付**。**写域**：**唯一**新建件 ＝ 本载体 `build/MilBridge/P1-tail2-contentvis-recon.md`。**未改任何仓内文件**（不碰 `src/**`／`build/**`／`build/MilBridge/tools/**`／装置件／`docs/**`／`upstream/**`）；**未构建**；**未跑腿、未占显示位**；**未跑整趟 `verify-all`**；**未跑 `static-jaws-check.sh`**；**未改相位**；未 `git add/commit/push`。现取 `git status --porcelain` 恰两项、**均先于本件且属他人**：`?? build/MilBridge/tasks-tail2/T-A43.md`、`?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`。
> **口径（不是证据）**：`T-A38`（`P1-tail2-viewport-recon.md`）／`T-A39`（`P1-tail2-subgeom-impl-report.md`）／`T-A40`（`P1-tail2-visual-recon.md`）／`T-A41`（`P1-tail2-fsview-impl-report.md`）／`T-A42`（`P1-tail2-vgeom-impl-report.md`）**只作对照**，其读数**一条未抄** —— 本件所有读数**现取**（只读 `sha256sum`／`grep`／`wc`／`stat` ＋ **纯读** `python3`＋`PIL` 解 PNG ＋ 只读 `read`/`grep` 上游件）。
> **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**（原文）＋件:行。
> **代际（现取）**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`5b7d0ac101673900`**｜`bin/exports.txt` ＝ **683** 行｜`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` ＝ **`52cf1b0012667dd0`**（＝ `T-A42` 同代，**本席未换代**）｜`HEAD=ba0533a12af1c86068efab2139b8ed82dcab2629`。
> **被侦察现场**：**仓内在册**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2i/{legA,legB,legC}/`（`T-A42` 三腿；本席**只读**复算，**未覆盖、未新增样本**）＋ **仓内**托管上游源码 `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/**`（**只读**）＋ **仓内** native 写域 `src/WpfGfx.Linux.Native/src/win32_pts.c`（**只读**）。

---

## §0 结论速览（自包含）

1. **① 到达性（现取，三腿同形）**：**内容段（`parah=0x58fa867e5a24`，`cLines=1`）的 `[FSQTD]` 非零（166／336／170）而 `[FSQLL]` 恒 `0`**；**宿主段（`parah=0x58fa867dfce4`，`cLines=8`，`figure=1 floater=1`）的 `[FSQTD]`＝415 且 `[FSQLL]`＝166**。两条"造行视觉"的**唯一**入口（`RenderSimpleLines`←`ValidateVisual`；`UpdateViewportSimpleLines`←`UpdateViewport`）**都没在内容段上跑过**（否则必发 `[FSQLL]`）。
2. **② 内容段落的"轮类"是唯一的**：把一趟按 `[FSQVP]` 切段（轮 ＝ 一次页轨枚举到下一次），**内容段 `[FSQTD]` 只出现在 `via=viewport` 类轮里**（2/轮；`arrange`／`visual` 类轮**各 0**）；而**该轮类里 `[FSQLL]` 对全部段恰为 0**（宿主／`1524`／`2d64`／内容段都只 `[FSQTD]`、不发 `[FSQLL]`）⇒ **本代产物上"视口类的页轨/子页轨下潜"整条都不落"造行视觉"**。
3. **② 视觉子树**：native **没有** `visualChildren` 面；`[VIS]`（唯一"页视觉帧"见证）**结构上只认页轨**（`pTrack == &pg->c_paras`，见 `win32_pts.c` 的 `[VIS]` 发点）⇒ **对子页轨内的内容段天然无面**。故"内容段是否建了视觉子树"只能由 `[FSQLL]≡0` **间接**判：**行盒视觉未建**。
4. **③ 归因 ＝（乙）「被访问但走了复杂支」**：内容段**被访问**（`[FSQTD]`>0，且只随"含子页轨枚举 `[FSPARALIST-FILL-SP]`＋图 `FsQuerySubpageDetails`"的 `via=viewport` 类轮出现 ⇒ 递归**确已下潜**到内容段）——`(甲)` **排除**；而内容段**从未**发 `[FSQLL]` ⇒ 两支造行视觉都**未运行**、**未建行盒视觉**——`(丙)` **排除**。证据见 §4。
5. **④ 唯一下一增量 ＝ `CONTENT-LINEVIS-BRANCH-REACH`（渲染面；承 `T-A40`/`T-A41` 的"本仓自有生成件"范式）**：让内容段落进**会发 `[FSQLL]` 的那一支**（＝ `ValidateVisual`→`RenderSimpleLines` **或** `UpdateViewport`→`UpdateViewportSimpleLines`），先落**只读判别器**分辨「延迟门（`IsDeferredVisualCreationSupported`）」与「未进 `UpdateViewport`」两因，再据结果择一驱动。判据 `D0–D3` ＋ 反极性见 §5。**不改 native 几何**（`T-A42` 已证伪门）、**不改上游件**。**非合法终点**（前沿是"造行支的到达"这一可做项）。
6. **⑤ 具名 `NOINFO` 8 条**（§6），其中 **`NOINFO-VIS-PAGE-TRACK-ONLY`**（`[VIS]` 天然无子页面）、**`NOINFO-VISUAL-CHILDREN-FACE`**（native 无 `visualChildren` 面）、**`NOINFO-DEFERRED-SUPPORT-VALUE`**（"视口类轮 `[FSQLL]`≡0" 的两因不可分）、**`NOINFO-CONTENT-FSQTD-DOUBLING`**（内容段每轮 `[FSQTD]`=2 归因未定）为本轮**新读出**。

---

## §1 现场 · 装置 · 指纹（现取）

| 件（本席现取 `sha16`／字节） | 值 | 备注 |
|---|---|---|
| `evidence-tail2i/legA/app_g1.log` | **`0e385c0236dc590a`**／2281923 B | 主证据（`T-A42` 腿 A：`WPF_PTS_ATT_VSELF` unset） |
| `…/legB/app_g1.log` | **`74923c2711311694`**／4424432 B | 腿 B（`WPF_PTS_ATT_VSELF=0`，原值态） |
| `…/legC/app_g1.log` | **`a7c6b5b4d21d9b57`**／2332466 B | 腿 C（`WPF_PTS_ATT_VSELF=f`，远锚态） |
| `…/legA/shots/g1/{boot,k23,k24}.png` | `b21eb530afd3c66c`／`10d0b9d54e649c10`／**`2d89d393157b0df6`** | 腿 A 帧 |
| `…/legB/shots/g1/k24.png` | **`1487caf78fd88886`** | ＝改前基线（`T-A36`／`T-A37`／`T-A39`／`T-A41` 在册同值） |
| `…/legC/shots/g1/k24.png` | **`fa7df9222ebb199f`** | 远锚态 |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`5b7d0ac101673900`** | 现代（`T-A42` 产物） |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | **`52cf1b0012667dd0`** |  |
| `upstream/…/PtsHost/{TextParaClient,PtsHelper,FigureParaClient,ContainerParaClient,StructuralCache,PtsPage,FlowDocumentPage}.cs` | 只读 | 逐跳现取来源（行号仅本次有效） |

**装置（现取 `legA/session.txt`）**：`clicks=[24,23]`；`display=:231`（`DISPLAY_LEASE=official-caller-owned`）；`shim_sha16=5b7d0ac101673900`／`pf_sha16=52cf1b0012667dd0`；`APP_RC=143`（`SIGTERM`，仪器收的）。
**方法边界**：本席**未**重跑腿、**未**占显示位、**未**改判据件；帧面读数是**只读 PNG 解码**（`PIL`）；对上游件与 native 写域件**只读** `read`/`grep`；**切段计数**用**纯读** `python3`（只切 `[FSQVP]` 段并计数，**不写盘**）。

**语义面（现取 `win32_pts.c`，仅钉本件用到的 4 个探针）**：
- `[FSQVP] via=…`（`wpf_pts_qvp_end:540-556`）：**轮** ＝ 一次**页轨枚举成功**（`FsQueryTrackParaList` 的页轨支，`begin:533`／`end:6387`）起，到**下一次页轨枚举**或**下一次 `FsQueryPageDetails`**（`end:4707`）为止；标签由**下游签名**贴：`figobj→arrange`｜`else fsqll→visual`｜`else att→viewport`｜`else unknown`（`544-547`）——**是推断，行尾已具名 `NOINFO`**。
- `[FSQTD] … parah=…`（`FsQueryTextDetails` 成功，`5360`）：**本入口被多个消费者共用**（上游 20 处调用点，`grep -n 'FsQueryTextDetails' TextParaClient.cs`）⇒ **单看它不是"谁调了"**。
- `[FSQLL] … parah=… cLines=…`（`FsQueryLineListSingle` 成功，`5512`）：托管侧唯一调用点 `PtsHelper.LineListSimpleFromTextPara`；其 16 个调用点里**只有 2 个造行视觉**（`TextParaClient.cs:3218 RenderSimpleLines`／`:3389 UpdateViewportSimpleLines`，承 `T-A38 §2.2`，本席复取 `grep -n` 一致）。
- `[VIS] children=1 page=… basis=…`（唯一发点 `win32_pts.c:6085`）：**只在** `pTrack == &pg->c_paras`（**页轨**）且 `qpd_new_pending ∧ qpd_fstd_since==1` 时发（`6075-6090`）⇒ **页轨专属**。

---

## §2 ① 到达性：内容段 vs 宿主段（现取对照）

### 2.1 段身份（现取，逐字锚）

```
[FS_TLB] entry=FsQueryTextDetails parah=0x58fa867dfce4 cLines=8 dcpFirst=0 dcpLim=956 fl_calls=8 fl_ok=1 complete=1 truncated=0 attached-objects=present queried=8 gap=0 capped=0 figure=1 floater=1 NOINFO=fsgeometry-layout(vrStart=self-accum)
[FS_ATT] rc=0 entry=FsQueryAttachedObjectList para=0x58fa867dfce4 cAttachedObjects=2 out=WRITTEN bytes=144 src=ledger:fl_att[]
[FS_TLB] entry=FsQueryTextDetails parah=0x58fa867e5a24 cLines=1 dcpFirst=0 dcpLim=41 fl_calls=1 fl_ok=1 complete=1 truncated=0 attached-objects=not-present(true-queried) queried=1 gap=0 capped=0 figure=0 floater=0 NOINFO=fsgeometry-layout(vrStart=self-accum)
[FSPARALIST-FILL-SP] rc=0 reason=ok entry=FsQueryTrackParaList track=0x58fa867dfc98 cParas=1 pfspara=0x58fa864d55e4 client=0x1a src=owned-subpage(cont_obj+managed-176) ok=2 gap=0
[FS_ATT] rc=0 entry=FsQuerySubpageDetails subpage=0x58fa867dfc98 fSimple=1 cParas=1 track=0x58fa867dfc98 fsrc=(0,0,37810,10810) src=owned-subpage NOINFO=subpage-geometry-declared(lWidth/lHeight)
```
⇒ **宿主段** `= 0x58fa867dfce4`（`cLines=8`、`figure=1 floater=1`）；**内容段** `= 0x58fa867e5a24`（`cLines=1`、`attached-objects=not-present(true-queried)`）；内容段**在子页轨** `track=0x58fa867dfc98` 之下（`FsQueryTrackParaList` **页轨/子页轨** 由 `track=` 与 `src=` 区分）。

### 2.2 一趟按 `[FSQVP]` 切段后的**逐轮类**分解（`legA`，现取）

| 轮类(`via=`) | 轮数 | host(`fce4`) `[FSQTD]` | `1524` `[FSQTD]` | `2d64` `[FSQTD]` | **内容段 `[FSQTD]`** | **`[FSQLL]`（全段）** | `[FSPARALIST-FILL]` | `[FSPARALIST-FILL-SP]` | `[FS_ATT] FsQueryAttachedObjectList` | `[FS_ATT] FsQuerySubpageDetails` | `[FS_ATT] FsQueryFigureObjectDetails` | `[FSQSTD]` |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `arrange` | **83** | 83 | 0 | 0 | **0** | **83** | 83 | 83 | 83 | 166 | 83 | 498 |
| `visual` | **86** | 166 | 166 | 166 | **0** | **253** | 86 | **0** | 3 | 6 | 0 | 344 |
| `viewport` | **83** | 166 | 166 | 166 | **166** | **0** | 83 | 83 | 83 | 166 | 0 | 498 |
| `unknown` | **2** | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 0 | 2 |

（`legB`／`legC` 的**逐轮类同形**：`legB` 轮数 `arrange 168／visual 171／viewport 168`，`viewport` 类 `[FSQLL]`≡**0**、内容段 `[FSQTD]`＝**336**（＝2×168）；`legC` 轮数 `85／88／85`，`[FSQLL]`≡**0**、内容段 `[FSQTD]`＝**170**（＝2×85）。见 §7 复跑命令。）
（⚠️ **切段口径**：段 ＝ 每条 `[FSQVP]` 行**之前**的窗口（`end()` 在**下一**次页轨枚举处打印，故一行 `[FSQVP] round=N` 之前的行属轮 N）。末轮（最后一次页轨枚举之后的收尾）**无** `[FSQVP]` 行 ⇒ 不入表；故各行 `[FSPARALIST-FILL]` 之和 = 254，比全趟 `255` **少 1**（那 1 次属未收口末轮）。）

### 2.3 逐段 × 轮类的 `[FSQLL]`／`[FSQTD]`（`legA`，现取）

| 段 | `[FSQLL]` @arrange | @visual | **@viewport** | `[FSQLL]` 合计 | `[FSQTD]` @arrange | @visual | @viewport | `[FSQTD]` 合计 |
|---|---|---|---|---|---|---|---|---|
| **宿主段** `fce4` | 83 | 83 | **0** | **166** | 83 | 166 | 166 | **415** |
| `1524`（页内无附属） | 0 | 83 | **0** | 83 | 0 | 166 | 166 | 332 |
| `2d64`（页内无附属） | 0 | 83 | **0** | 83 | 0 | 166 | 166 | 332 |
| **内容段** `5a24` | 0 | **0** | **0** | **`0`** | 0 | **0** | **166** | **166** |

**逐字锚（`legA`）**：
```
[FSQVP] via=viewport round=6 page=0x58fa86a3acc0 closed_by=next-qpd fsqll=0 att=1 figobj=0 n_arrange=1 n_visual=4 n_viewport=1 n_unknown=0 NOINFO=viewport-branch-callsite(inference:adjacent-events+page-query-state)
```
⇒ 第 6 轮的窗口内的**逐行**（原文顺序）：
```
[FSPARALIST-FILL] (页轨,cParas=1)
[FSQSTD] psub=…e6644 cParas=3 → [FSQSPL]
[FSQSTD] psub=…d9074 cParas=1 → [FSQSPL]
[FSQTD] parah=0x58fa867dfce4 cLines=8 → [FSQTD] 同段   ← 宿主段（2 次）
[FS_ATT] FsQueryAttachedObjectList para=0x58fa867dfce4 cAttachedObjects=2
[FS_ATT] FsQuerySubpageDetails subpage=0x58fa867dfc98 fSimple=1 cParas=1 track=0x58fa867dfc98 fsrc=(0,0,37810,10810)
[WINDOW-SPLIT] where=FsQueryTrackParaList window=out action=summarize-only src=in-window-subenum …
[FSPARALIST-FILL-SP] track=0x58fa867dfc98 cParas=1 pfspara=0x58fa864d55e4 client=0x1a
[FSQSTD] psub=0x58fa864d55e4 cParas=1 → [FSQSPL]
[FSQSTD] psub=0x58fa867e4e04 cParas=1 → [FSQSPL]
[FSQTD] parah=0x58fa867e5a24 cLines=1 → [FSQTD] 同段          ← 内容段（2 次）
[FS_ATT] FsQuerySubpageDetails subpage=(nil) fSimple=0 …       ← Floater 的
[FSQSTD] psub=0x58fa867e1524… → [FSQSPL] → [FSQTD] 1524 ×2
[FSQSTD] … → [FSQSPL] → [FSQTD] 2d64 ×2
（本窗口内 **[FSQLL] 一行都没有**）
```

### 2.4 判（三腿一致）

- **宿主段**：三类轮**都到**（`[FSQTD]`＝415＝83＋166＋166）；`via=viewport` 类轮里带 `[FS_ATT] FsQueryAttachedObjectList`（1/轮）＝**附属对象递归**（`TextParaClient.UpdateViewport` 的 `:169`／`ValidateVisualFloatersAndFigures` 的 `:3745` 都会走到它）⇒ **宿主的"视口/视觉"链确实在跑**。
- **内容段**：**只**在 `via=viewport` 类轮到（`[FSQTD]`＝166＝2×83；`arrange`／`visual` 类轮**各 0**），且同窗口内同时有 `[FSPARALIST-FILL-SP]`（＝子页轨枚举）与 `[FS_ATT] FsQuerySubpageDetails`（＝图子页）⇒ **递归（宿主→图→子页轨→容器→内容段）确已下潜到内容段**。
- **但**：`via=viewport` 类轮里 **`[FSQLL]`≡0（对全部段）** ⇒ 内容段的**两支"造行视觉"都没跑**。内容段 `[FSQLL] cLines=1` **三腿恒 `0`**。
- **一条可机读的同形量**：`[FSPARALIST-FILL-SP]`（子页轨枚举）与内容段 `[FSQTD]` **逐趟 1:1**（`legA 166:166`／`legB 336:336`／`legC 170:170`），而**轮数:内容段 `[FSQTD]` ＝ 1:2**（`83:166`／`168:336`／`85:170`）⇒ **每视口类轮恰 1 次子页轨枚举、内容段恰 2 次 `[FSQTD]`**（见 `NOINFO-CONTENT-FSQTD-DOUBLING`）。

**射程（写死，防被读宽）**：本件**只**证「内容段 `[FSQTD]`>0 而 `[FSQLL]`≡0」＋「内容段只在 `via=viewport` 类轮被触达」＋「那一类轮对全段都不发 `[FSQLL]`」。**不**证"托管有缺陷"、**不**证"内容永远画不出"、**不**据此断言"色锚必转绿"。

---

## §3 ② 视觉子树 与 `[VIS]` 面（现取）

### 3.1 `[VIS]` 面：宿主段 vs 内容段 —— **结构性不成对**

- **发点（现取 `win32_pts.c:6075-6090`）**：`[VIS]` **只在** `pTrack == &pg->c_paras`（**页轨句柄**，指针值比较）且 `qpd_new_pending ∧ qpd_fstd_since==1` 时打一行（`children=1`）。
- **现取（三腿）**：`[VIS]`＝**4／4／4**；逐字样本：
```
[VIS] children=1 page=0x58fa87537170 page_qpd=4 fstd_since_qpd=1 vis_n=1 seq=12 basis=fmtrackparalist-after-qpdnew-with-1-trackdetails NOINFO=fspagedetails-page-change-tracking
```
- ⇒ **`[VIS]` 是"页轨页视觉帧"的见证**，其**射程 = 页轨**。内容段在**子页轨**（`sp->c_paras`，另一次 `FsQueryTrackParaList`）之下 ⇒ **`[VIS]` 对内容段天然无面**。
- ⇒ **"宿主段 vs 内容段 `[VIS]` 对照"的现取结论**：**页级 `[VIS]`＝4（且 4 次全在稳态前）**；**内容段 ＝ 结构性 0（不是"没建视觉"，而是"这个面不覆盖子页轨"）**。列为 `NOINFO-VIS-PAGE-TRACK-ONLY`。

### 3.2 `visualChildren` 面：native **没有**

- 现取 `grep -n 'visualChildren' src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **唯一命中在注释里**（`6072` 的说明文字）；`grep -c 'Children' …` ＝ **2**（均注释）⇒ native **不观测**托管 `visualChildren`；本侧**唯一**能间接反射它的量是 `[FSQLL]`（`LineListSimpleFromTextPara`）。
- 内容段 `[FSQLL]`≡0 ⇒ **`lineContainerVisual.Children` 从未被 `LineVisual` 填过** ⇒ **行盒视觉未建**。（`RenderSimpleLines`／`UpdateViewportSimpleLines` 是两个造 `LineVisual` 的地方，见 §2.1 语义面。）
- ⚠️ **不得读宽**：`[FSQLL]≡0` 只否证"**行盒**视觉"，**不**否证"段自身的 `ContainerVisual`（`_visual`）存在"——后者由 `BaseParaClient` 构造，native **无面**（`NOINFO-VISUAL-CHILDREN-FACE`）。

### 3.3 `cLines=1` 却无行盒视觉的机制（现取＋承件的两个**唯一**入口）

| 入口 | 进入条件 | 是否发 `[FSQLL]` | 内容段现取 |
|---|---|---|---|
| `ValidateVisual`→`RenderSimpleLines`（`TextParaClient.cs:106`→`:3218`） | `fsktdFull` ∧ **¬deferred** | **是** | **未到内容段**（`visual` 类轮内容段 `[FSQTD]`＝0） |
| `UpdateViewport`→`UpdateViewportSimpleLines`（`:159`→`:3389`） | `fsktdFull` ∧ **deferred** | **是**（`3371` 门为假 ⇒ 只 `Clear()`，不发） | `via=viewport` 类轮到内容段，但**同轮全段 `[FSQLL]`≡0** |

`IsDeferredVisualCreationSupported`（现取，`TextParaClient.cs:3837-3850` ∧ `StructuralCache.cs:375-378`）＝ `Paragraph.StructuralCache.IsDeferredVisualCreationSupported ∧ ¬fLinesComposite ∧ ¬HasFiguresFloatersOrInlineObjects`；其后项 `= _currentPage != null && !_currentPage.FinitePage`。
**现取的可判部分**：`fLinesComposite` native 恒 `0`（`e->full.f_lines_composite = 0;`）⇒ 该门只余 `_currentPage`／`FinitePage`／`HasFiguresFloatersOrInlineObjects` 三项——**后两项本侧无运行时读数** ⇒ `NOINFO-DEFERRED-SUPPORT-VALUE`。

---

## §4 ③ 归因：三选一（逐条证据）

| 候选 | 断言 | 现取证据 | 判 |
|---|---|---|---|
| **(甲) 没被访问**（递归未下潜） | 内容段的 `UpdateViewport` 根本没被调 | 内容段 `[FSQTD]` ＝ **166／336／170（≠0）**，且**只**随"含 `[FSPARALIST-FILL-SP]`（子页轨枚举）＋图 `FsQuerySubpageDetails`"的 `via=viewport` 类轮出现（§2.2）⇒ 宿主→图→子页轨→容器→内容段的递归**确已下潜到内容段** | ❌ **排除** |
| **(乙) 被访问但走了复杂支** | 内容段被访问，但落的支不产生行视觉 | ① 内容段被访问（上格）；② 内容段 `[FSQLL]`≡**0**（三腿）⇒ 两支造行视觉**都未运行**；③ 唯一触达内容段的轮类（`via=viewport`）**对全部段** `[FSQLL]`≡0 ⇒ 该轮类的下潜**整条不落造行支**；④ 唯一实际发 `[FSQLL]` 的轮类（`visual`，253/86 轮）**不下潜到子页轨/内容段**（`[FSPARALIST-FILL-SP]`＝**0**、图 `FsQuerySubpageDetails`≈**0**） | ✅ **判定** |
| **(丙) 建了视觉但没画** | 行视觉已建、只是没落像素 | 内容段 `[FSQLL]`≡**0** ⇒ `LineVisual` 从未被创建（§3.2）⇒ **不是"画不出"，是"没建"** | ❌ **排除** |

**归因（具名）**：**（乙）被访问但走了复杂支** —— 内容段**被访问**（只经"视口类"下潜），但该下潜在本代产物上**不落任何造行视觉支**；能造行视觉的支（`visual` 类，`RenderSimpleLines` 所在）**从不下潜到子页轨/内容段**。两因**未可分辨**（`NOINFO-DEFERRED-SUPPORT-VALUE`）：
- **因 A**：`IsDeferredVisualCreationSupported` 对内容段（乃至全段）为**假** ⇒ `UpdateViewportSimpleLines` 未被进入（数值面证据：`via=viewport` 类轮**全段** `[FSQLL]`≡0）；
- **因 B**：内容段在 `via=viewport` 类轮里的两次 `[FSQTD]` **不来自** `UpdateViewport`（而来自共用 `FsQueryTextDetails` 的兄弟消费者；`[FSQTD]` 单看不辨调用者，见 §1 语义面 ⇒ `NOINFO-FSQLL-CALLER-DISCRIMINATION`）。

⇒ 无论因 A 或因 B，**后果同一**：内容段的行盒视觉**永不发生**。

---

## §5 ④ 唯一下一增量 ＋ 判据草案

### 5.1 唯一下一增量（具名）

> **`CONTENT-LINEVIS-BRANCH-REACH`**：让**内容段落进"会发 `[FSQLL]` 的那一支"** —— 即内容段首次执行 `RenderSimpleLines`（`ValidateVisual` 支）**或** `UpdateViewportSimpleLines`（`UpdateViewport` 支），使 `lineContainerVisual.Children` 首次被 `LineVisual` 填充 ⇒ `[FSQLL] cLines=1` 首次出现。
> **落点（择一，先只读）**：本仓自有**生成件**面 —— 承 `T-A40 §5.1`／`T-A41 §1.2` 的范式（`build/PresentationFramework.Linux/reapply-patches.py` → 生成件；**不直改生成件、不碰 `upstream/**`**）：
> (a) **只读判别器先行**（分辨因 A／因 B）：在内容段的"视觉支/视口支"入口各打**一条具名行**（托管侧只读台账，形态承 `T-A41` 的 `[FSVIEW]`），使"谁到了内容段、`IsDeferredVisualCreationSupported` 取何值"**首次可现取**；
> (b) 据 (a) 的读数，**择一**驱动：(b1) 若因 A ⇒ 使内容段（或全局）`IsDeferredVisualCreationSupported` 为真；(b2) 若因 B ⇒ 让图/子页的**视觉子树**下潜到内容段（`FigureParaClient.ValidateVisual`→`UpdateTrackVisuals`）。
> **零假值**：**不得**为"让 `[FSQLL]` 出现"而置 `fLinesComposite=1`／`f_update_info_for_lines_present=1`／伪造 `fsrc`／`dvrUsed`；`:3371` 门与 `ContainedInRectOnV` 语义**一字不改**；`Invariant.Assert` **一个都不删／不放宽**。
> **明确不做**：**不改 native 几何**（`T-A42` 已证"门不是断点"）、**不改上游 `upstream/**`**。

**理由（逐条，均有 §2/§3/§4 现取证据）**：
1. 两支造行视觉是**唯一**发 `[FSQLL]` 的入口（§2.1），而内容段 `[FSQLL]`≡0（三腿）。
2. 内容段**已被访问**、递归**已下潜**（§2.4）⇒ 前沿**不在**"接线"，在"**落到造行支**"。
3. 唯一触达内容段的轮类（`via=viewport`）**整条不落造行支**（全段 `[FSQLL]`≡0）；唯一落造行支的轮类（`visual`）**不触达内容段**（`[FSPARALIST-FILL-SP]`＝0）⇒ 两因可**同趟分辨**（`(a)`）。
4. **触 `fp_inputs()`**：`build/PresentationFramework.Linux/**` 在覆盖面内 ⇒ 流程上须排在采样前并同趟过 `[42] --fp-manifest --expect`。

### 5.2 判据草案（`D0–D3`，逐条可伪证 ＋ **反极性该红必红**）

| # | 判据（可伪证的单行式） | **反极性（必红腿）** |
|---|---|---|
| **`D0` 分流/诊断（先跑）** | `[FSQLL] rc=0` 的 `cLines` 直方图**首次**出现 `cLines=1`，其 `parah` ＝内容段句柄（与内容段 `[FSQTD] … cLines=1` 的 166／336／170 **对得上**）；且陪跑的**具名**只读行给出"到了内容段的是 `ValidateVisual` 还是 `UpdateViewport`"＋`IsDeferredVisualCreationSupported` 取值。**若 `cLines=1` 仍为 0** ⇒ 本件断点判定（乙）**证伪**，断点改判在"内容段的**造行支入口之前**"。 | 用**假判别器**（无条件打 1／无差别贴标签）⇒ **必红**（`P8` 恒绿陷阱）；把 `fLinesComposite` 或 `f_update_info_for_lines_present` 置 1 换 `[FSQLL]` ⇒ **必红**（语义是假：该段无合成行／无更新信息）。 |
| **`D1` 余 3 具名色各 ≥200px（可伪证）** | `k=24` 帧上 **`Beige`／`DarkGreen`／`LightGoldenrodYellow` 各 `≥200 px`**（`pts-pages-guard.sh` 现取 `PTS_COLORANCHOR` 逐色；判词 `expect_min=200`），`hits` 由 **1 → 4**，`PTS_COLORANCHOR=PASS`。 | 只让某**近似灰/白**超阈（如 `(249,249,249)`）⇒ **必红**；把 `k=24` 的锚**推广**到 `k=23` ⇒ **必红**（`k=23` 仍 `NOINFO`）。 |
| **`D2` baseline 仍全 0（活锚）** | `boot.png`（`b21eb530afd3c66c`）四色**仍全 0**（三腿现取：`GhostWhite/Beige/DarkGreen/LightGoldenrodYellow` 全 `0`）；`LightGray` **不入集**（现取 `44`）。 | 若 `boot` 出现任一具名色 ⇒ 锚被污染 ⇒ **必红**。 |
| **`D3` 帧面成对 ＋ 不得把空白读成绿 ＋ 失败必留痕** | `k24` 帧 `sha16` **必须变**（现取基线 `1487caf78fd88886`＝`legB`）；`AE(boot,k24)` 的差异分量**落在内容区**；**两独立样本**同值；`alive=yes`／`app_rc=143`／`failfast=0`／`magenta=0`／`ink=480000`／`ns=…FlowDocumentDemo` 逐格**不变**；`[HC-UNHANDLED]` **恰 1**（**不许涨**）；"没落到造行支"时**必**打具名行（`reason=`），与"真 0 次"**可**分。 | 只挪动蓝块/页签 ⇒ **必红**；把 `colors` 变多当绿 ⇒ **必红**；`GhostWhite`（**Background**）当"内容真绘出" ⇒ **必红**；静默 stub（返非 0 零痕迹）⇒ 与"真 0 次"不可分 ⇒ **必红**。 |

**最便宜的反极性腿（本件只登记、不跑）**：撤回本增量的驱动/落点（回到现态）⇒ `[FSQLL] cLines=1` **必须回 0**、`k24` 帧**必须回 `1487caf78fd88886`**、余 3 色**必须回 0**，而 `[HC-UNHANDLED]` **不得下降**、`boot.png` 四色**不得变**。

### 5.3 其它选项（如实并列）

- **换靶／换页**：**不** —— 靶页身份**正确**且有页签像素自证（`T-A35 §2.2`）；`k=24` 四色**出处唯一**（`<Figure>`／`<Floater>` 内）。
- **合法终点**：**不** —— 前沿是"**内容段落进造行支**"这一**可做项**（且本件已把"落到哪支"的两因**做成可分辨**）。
- **回退 `T-A42` 的 native 几何靶**：**不** —— `T-A42` 现取"门真（×2）↔ 门假（×1）"三态同值（内容像素恒 0）⇒ **门不是断点**；本件同向（§2.4：触达内容段的轮类整条不落造行支）。

---

## §6 ④ 具名 `NOINFO`（逐条给"消掉需要什么"）

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| **`NOINFO-VIS-PAGE-TRACK-ONLY`**（**本轮新读出**） | 内容段（子页轨内）的"页视觉帧"见证 | `[VIS]` 发点恒以 `pTrack == &pg->c_paras`（**页轨**）为条件（`win32_pts.c:6079`）；三腿 `[VIS]`＝4／4／4 | 为**子页轨**另立一个同形见证（或把 `[VIS]` 的判据改成"轨身份分类"） |
| **`NOINFO-VISUAL-CHILDREN-FACE`**（**本轮新读出**） | 内容段是否**建了视觉子树**（`visualChildren`／段自身 `_visual`） | native **无**该面（现取 `grep`）；只能由 `[FSQLL]`≡0 **间接**判"**行盒**视觉未建" | 渲染面只读旁证（托管侧 `visualChildren.Count` 只读台账） |
| **`NOINFO-DEFERRED-SUPPORT-VALUE`**（承 `T-A40`，**本轮加强**） | `IsDeferredVisualCreationSupported` 的**真值**（`StructuralCache._currentPage`／`FlowDocumentPage.FinitePage`） | 由"`via=viewport` 类轮**全段** `[FSQLL]`≡0"＋"`fLinesComposite` native 恒 0" ⇒ **或因 A（deferred=假）或因 B（该轮 `[FSQTD]` 不来自 `UpdateViewport`）**，两者本侧**不可分** | 渲染面只读行（承 §5.1(a)）：内容段入口打 `IsDeferredVisualCreationSupported` 与调用者名 |
| **`NOINFO-CONTENT-FSQTD-DOUBLING`**（**本轮新读出**） | 内容段**每视口类轮 `[FSQTD]`＝2**（`166:83`／`336:168`／`170:85`）的归因 | 无逐次"调用者"面；`FsQueryTextDetails` 有 20 处托管调用点（现取 `grep`） | native/托管在 `FsQueryTextDetails` 打**调用者判别器**（承 `NOINFO-FSQLL-CALLER-DISCRIMINATION` 范式） |
| **`NOINFO-FSQLL-CALLER-DISCRIMINATION`**（承 `T-A38`/`T-A41`） | `[FSQLL]` 的 16 个托管调用点里**这次是谁** | native 只见同一入口；本件 `via=` 仍是**下游签名推断**（行尾已具名） | 渲染面旁证（只读调用计数） |
| **`NOINFO-VISUAL-BRANCH-CALLSITE`**（承 `T-A40`） | **无附属对象**段（`1524`／`2d64`／内容段）的 `ValidateVisual` 是否被调 | 这些段 `IsDeferredVisualCreationSupported` 若为真则走延迟支（native 面零痕迹）⇒ 本侧不可分"被调"与"未被调" | 渲染面旁证（`SyncUpdateDeferredLineVisuals` 入口只读位） |
| **`NOINFO-CONTENT-VIEWPORT-VALUES`**（承 `T-A38`/`A39`/`A42`） | `:3371` 门的两个操作数（内容段 `_rect.v/dv` 与入站 `viewport.v/dv`）**数值** | 无渲染面/托管面读数；`T-A42` 已给**算得的**三取值（`0`／`-20000`／`-200000` 文本）与门值 | 渲染面旁证，或 native 打宿主 `viewport` 与子页 `fsrc` 的**成对**值（native **看不到**托管视口 ⇒ 结构性缺信道） |
| **`NOINFO-QPD-CONSUMER-MAP`**（承 `T-A40`） | `[QPD]` 逐次到具体消费者（`ArrangePage`／`UpdatePageVisuals`／`UpdateViewport`／`GetRect`／`GetBoundingBox`）的归属 | 只能给"≈2 次/帧、成组相邻" | native 在 `FsQueryPageDetails` 打调用者判别器 |

---

## §7 可复跑单行命令原文（本席实跑，现取）

```sh
cd /home/links-dev/netTest/GitProj/WPFOnLinux
D=build/MilBridge/tests/PtsPagesProbe/evidence-tail2i

# 代际 / 证据指纹
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16        # ⇒ 5b7d0ac101673900
sha256sum build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll | cut -c1-16
                                                                          # ⇒ 52cf1b0012667dd0
for t in legA legB legC; do sha256sum $D/$t/app_g1.log | cut -c1-16; done  # ⇒ 0e385c02… / 74923c27… / a7c6b5b4…
(cd $D/legA/shots/g1 && sha256sum boot.png k23.png k24.png | cut -c1-16)   # ⇒ b21eb530… / 10d0b9d5… / 2d89d393…

# ① 关键：内容段 FSQLL 恒 0（三腿）
for t in legA legB legC; do L=$D/$t/app_g1.log; \
  printf '%s FSQLL=%s FSQLL(cLines=1)=%s FSQTD(cLines=1)=%s FILL=%s FILLSP=%s VIS=%s UNH=%s\n' "$t" \
  "$(grep -c '^\[FSQLL\]' $L)" "$(grep -c '^\[FSQLL\].*cLines=1' $L)" "$(grep -c '^\[FSQTD\].*cLines=1' $L)" \
  "$(grep -c '^\[FSPARALIST-FILL\]' $L)" "$(grep -c '^\[FSPARALIST-FILL-SP\]' $L)" \
  "$(grep -c '^\[VIS\]' $L)" "$(grep -c 'HC-UNHANDLED' $L)"; done
# ⇒ legA FSQLL=337 0 166 FILL=255 FILLSP=166 VIS=4 UNH=1
# ⇒ legB FSQLL=677 0 336 FILL=510 FILLSP=336 VIS=4 UNH=1
# ⇒ legC FSQLL=345 0 170 FILL=261 FILLSP=170 VIS=4 UNH=1

# ② 逐段 × 轮类分解（纯读，不写盘）
python3 - <<'PY'
import re,collections
for leg in ('legA','legB','legC'):
    L=open(f"build/MilBridge/tests/PtsPagesProbe/evidence-tail2i/{leg}/app_g1.log",
           encoding='utf-8',errors='replace').read().splitlines()
    segs=[];cur=[]
    for l in L:
        m=re.match(r'\[FSQVP\] via=(\w+) round=(\d+)',l)
        if m: segs.append((m.group(1),cur));cur=[]
        else: cur.append(l)
    print('=====',leg,'rounds',collections.Counter(v for v,_ in segs))
    for via in ('arrange','visual','viewport'):
        qtd=collections.Counter(); qll=collections.Counter(); fsp=0; att=0
        for v,lines in segs:
            if v!=via: continue
            fsp+=sum(1 for l in lines if l.startswith('[FSPARALIST-FILL-SP]'))
            att+=sum(1 for l in lines if l.startswith('[FS_ATT]') and 'FsQueryAttachedObjectList' in l)
            for l in lines:
                if l.startswith('[FSQTD]'):
                    mm=re.search(r'parah=(0x[0-9a-f]+)',l)
                    if mm and 'cLines=1' in l: qtd['CONTENT']+=1
                    elif mm: qtd[mm.group(1)]+=1
                if l.startswith('[FSQLL]'):
                    qll['all']+=1
                    if 'cLines=1' in l: qll['cLines=1']+=1
        print('  ',via,'FSQTD',dict(qtd),'FSQLL',dict(qll),'FILLSP',fsp,'ATT',att)
PY
# ⇒ legA arrange  FSQTD{fce4:83}                         FSQLL{all:83}  FILLSP 83 ATT 83
# ⇒ legA visual   FSQTD{fce4:166,1524:166,2d64:166,+小量他页段} FSQLL{all:253} FILLSP 0  ATT 3
# ⇒ legA viewport FSQTD{fce4:166,CONTENT:166,1524:166,2d64:166} FSQLL{}     FILLSP 83 ATT 83
#   （`legB`/`legC` 同形：`viewport` 类 FSQLL 恒 `{}`；CONTENT ＝ 336／170）

# ③ 句柄身份（逐字锚）
grep -m1 '^\[FS_TLB\].*parah=0x58fa867dfce4' $D/legA/app_g1.log   # 宿主：cLines=8 … figure=1 floater=1
grep -m1 '^\[FS_TLB\].*parah=0x58fa867e5a24' $D/legA/app_g1.log   # 内容：cLines=1 … attached-objects=not-present(true-queried)
grep -m1 '^\[FSPARALIST-FILL-SP\]' $D/legA/app_g1.log             # 子页轨：track=0x58fa867dfc98 pfspara=0x58fa864d55e4 client=0x1a

# ④ 帧面（纯读 PNG）
python3 - <<'PY'
from PIL import Image; import collections
anch={'GhostWhite':(248,248,255),'Beige':(245,245,220),'DarkGreen':(0,100,0),'LightGoldenrodYellow':(250,250,210),'LightGray':(211,211,211)}
D="build/MilBridge/tests/PtsPagesProbe/evidence-tail2i"
for leg in ('legA','legB','legC'):
    for f in ('boot.png','k24.png','k23.png'):
        c=collections.Counter(map(tuple,Image.open(f"{D}/{leg}/shots/g1/{f}").convert("RGB").getdata()))
        print(leg,f,{k:c.get(v,0) for k,v in anch.items()},'ncolors=',len(c))
PY
# ⇒ boot 三腿全 0/LightGray=44/ncolors=386
# ⇒ k24 legA GhostWhite=29667 余三色 0/ncolors=765｜legB GhostWhite=29637 余三色 0/ncolors=724｜legC 全 0/ncolors=654
# ⇒ k23 三腿全 0/ncolors=636
```

---

## §8 边界 · 纪律 · 主动披露

1. **写域**：**唯一**新增件 ＝ 本载体（交付前现取 `ls` **不存在**）。**未覆盖**在册 `evidence-tail2i/**` 与他代证据目录；**未碰** `src/**`／`build/**`／`build/shape`／`build/MilBridge/tools/**`／`docs/**`／`upstream/**`（**只读**）。**未** `git add/commit/push`。
2. **只读**：本件命令为 `sha256sum`／`grep`（含 `-c`／`-m1`／`-o|sort|uniq -c`）／`head`／`tail`／`wc`／`stat`／`ls`／`git status` ＋ **纯读** `python3`（切 `[FSQVP]` 段计数／只解 PNG 像素）＋ 对上游件与 native 写域件的**只读** `read`／`grep`。**零构建、零跑腿、零显示位、零整趟门禁、零 `static-jaws-check.sh`、零 `git` 写、零相位改。**（大文件只用 `wc`/`head`/`tail`/`grep`；未 `cat`／未整文件 `sed`。）
3. **不引他人读数当证据**：`T-A35`／`T-A37`／`T-A38`／`T-A39`／`T-A40`／`T-A41`／`T-A42` 只在 §0／§2／§3／§4／§5 的理由里作**对照引用**（并逐处标注）；本件所有数值（`sha16`／`grep -c`／`grep -o|uniq -c`／切段计数／帧像素 `Counter`）**均为本席现取**。
4. **跨代／跨装置不可比（纪律 31/32）**：本件**只**用 `evidence-tail2i/` 三腿（**同一装置 `:231`／同一产物 `5b7d0ac101673900`／同一 `pf=52cf1b0012667dd0`**）＋ 同一批在册帧指纹；"改前基线"（`1487caf78fd88886`）取自 `T-A36`/`A37`/`A39`/`A41` 的**在册同代**读数 ⇒ **只报结果，不做减法承重**。
5. **口径纪律**：`[FSQTD] rc=0` **≠** 内容已画；`[FSQLL] rc=0` 是"**行表取数**"入口 —— 它**既**由"造行视觉"发**也**由行结果查询发（承 `T-A38`）⇒ 本件**不**用"`[FSQLL]` 次数"当"造行次数"，而用**两支唯二入口 ＋ 门条件**（§3.3）与**逐轮类分解**（§2.2）。`[VIS]` 是 **native 侧自记**判别器（`NOINFO=fspagedetails-page-change-tracking`），**不是**托管读数；`[FSQVP] via=` 是**下游签名推断**（行尾已具名）。
6. **未做（防被读宽）**：未实现任何增量（本件**只侦察＋归因＋选靶**）；未改相位；未动判据件/牙；**未**新增任何 `D-G<digits>` 登记编号；**未**跑反极性腿；**未**新增/覆盖任何证据目录；**未**量化 `NOINFO-CONTENT-VIEWPORT-VALUES`；**未**判"色锚必转绿"。
7. **装置未就绪的重试披露**：本件**未跑腿** ⇒ 无重试；一切读数取自 `T-A42` 已落地的**在册**三腿现场，并由本席**逐格复算**。
8. **主动披露（承件读数的两处"本件与之不同"）**：
   - `T-A38 §3.3` 由"内容段 `[FSQTD]`＝2×349"**推**"内容段 `UpdateViewport` 与 `ValidateVisual` 各到一次"。本件现取**不支持把它读成"视口支到了内容段且造了行"**：内容段 `[FSQLL]`≡0，且其 `[FSQTD]` 落在**整条不发 `[FSQLL]`** 的 `via=viewport` 类轮里（§2.2/§2.3）。
   - `T-A42 §0.7` 的"查询支到、造行支不到"与本件**同向**；本件**新增**的是"**造行支只在 `visual` 类轮落，而该类轮 `[FSPARALIST-FILL-SP]`＝0（不触达内容段）**"这一定位。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-contentvis-recon.md | sha256sum | cut -c1-16`）= 5ea14b2179d67e4e

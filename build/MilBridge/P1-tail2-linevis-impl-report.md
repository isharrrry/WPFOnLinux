# `P1-tail2` · `T-A44` · 内容段造行视觉支到达（`CONTENT-LINEVIS-BRANCH-REACH`）—— 实现报告（**判决：判别器已落 ∧ 「因 B」判定 ∧ 驱动使「造行支到达」0→>0 ∧ 判据 ② 未达**）

- **读时**：`2026-09-30T19:2x–19:3x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=bbf47cace4a54c7213b57027b0cd045746d9dcc6`（现取，**未换代**）。
- **改前件备份（仓外 `~/tA44-work/bak/`，`cp -p`，取在**任何写之前**）**：`reapply-patches.py`（`9a9a523f79823228`）／`PresentationFramework.Linux.csproj`（`e22a7457dc4a8010`）／`PtsCache.Linux.cs`（`e5b399fdb8742092`）／`FlowDocumentView.Linux.cs`（`7b32ca403752c703`）／`PresentationFramework.dll`（`52cf1b0012667dd0`）／`libwpfwin32.so`（`5b7d0ac101673900`）／`exports.txt`（`860a3abe4a64f1c5`）。
- **只改**：`build/PresentationFramework.Linux/reapply-patches.py`（生成器）／由它重产的**生成件**（`temp+rename`）／**新建载体** `build/MilBridge/P1-tail2-linevis-impl-report.md`。**未碰** `src/WpfGfx.Linux.Native/src/win32_pts.c`（本轮**不需要** native 侧判别器 —— native 结构性看不到托管调用者，见 §1.2；其 `sha16` 现取仍 `826c896ebe77e917`、`.so` 仍 `5b7d0ac101673900`）／**未碰** `upstream/**`（只读）。
- **黑名单遵守**：未动 `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`；未改相位；未 `git add/commit/push`。
- **重活**：**3 趟托管构建**（`0 警告 0 错误`，各 `~20–24 s`）＋ **4 趟跑器**（共 **8 条腿**，逐腿 `HEAVYSLOT=ACQUIRED/MEMOK/RELEASED`；`held=36/35/36/37s`）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`；进程只按 PID；显示位 `:231`（装置自取；逐腿 `DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p` 备份；模式守恒。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm`／`grep -c`／只读 `python3`＋`PIL` 解 PNG／`bash build/MilBridge/tools/{pts-pages-guard,pts-gap-count-check,defect-registry-check,report-id-domain-check}.sh`）；`P1-tail2-contentvis-recon.md`（`T-A43`）／`T-A41`／`T-A42` 报告**只作对照**，其读数**一条未抄**。

---

## §0 结论速览（自包含）

1. ✅ **只读判别器已落（两层，均在托管侧生成件；零行为变化）**：
   - **`[TPCL]`**（`TextParaClient.Linux.cs`）：在内容段的**两支入口**（`ValidateVisual`／`UpdateViewport`）与**三个造行支**（`RenderSimpleLines`／`UpdateViewportSimpleLines`／`SyncUpdateDeferredLineVisuals`）各打**一行**，带 `parah`／`cLines`／`composite`／`att`／`deferred`（＝`IsDeferredVisualCreationSupported` 的**真值**）＋ 该点的门操作数。
   - **`[CHAIN]`**（`WpfLinuxChainProbe.Linux.cs` ＋ 6 个宿主生成件）：在**视觉/视口链的每一跳入口**打一行（`FDF.Arrange`／`FDG.Arrange`／`FDG.EnsureValidVisuals`／`FDG.UpdateVisual`／`PTSP.GetPageVisual`／`PTSP.UpdatePageVisuals`／`PTSP.UpdateViewport`／`PH.UpdateTrackVisuals`／`PH.UpdateParaListVisuals`／`PH.UpdateViewportTrack`／`PH.UpdateViewportParaList`／`FIG.*`／`CON.*`）。
2. 🔴 **两因判定 ＝「因 B」（`T-A43 §5.1(a)` 要分辨的那一极）**：`FlowDocumentDemo` 阶段（`[NS] loaded` 到下一次 `[NS] loaded`）里，**内容段（`cLines=1`、`attached-objects=not-present`）的两支入口 + 三造行支一次都没被调**（`[TPCL]` ＝ **0** 行；四腿一致）。
   - 同时 **`deferred` 取值可现取**：`T-A43` 猜的"因 A（`deferred=假` ⇒ `UpdateViewportSimpleLines` 未进）"**不是**断点 —— 判别器现取 `deferred` **有真有假**（`att=2` 的宿主段 `deferred=0`；无附属段 `deferred=1` 且**确实进了** `UpdateViewportSimpleLines`，见 §2.1 `PracticalDemo` 段）。
3. 🔴 **断点逐跳收到一跳（`[CHAIN]` 现取）**：`FlowDocumentFormatter.Arrange`（**唯一**把"页视觉帧 ＋ 视口更新"跑起来的宿主入口：`_documentPage.Arrange` → `EnsureValidVisuals` → `UpdateViewport`）整趟**只被调 2 次**（`638.4x366.72`／`394.56x283.2`），而 `FlowDocumentPage.Arrange` 被调 **242 次**（`816x1056` ＝ Letter）——后者来自 **`FlowDocumentPaginator.FormatPage`**（`page.FormatFinite` → `page.Arrange(pageSize)`），该路径**不调 `EnsureValidVisuals`**；且 `FlowDocumentPage.UpdateVisual` 现取多数为 **`needsUpdate=0`（空转）**；`FigureParaClient.ValidateVisual` ＝ **0 次**。
   ⇒ 具名断点 ＝ **「`FlowDocumentDemo` 那份 FlowDocument 走的是分页器宿主路径，而该路径缺 `Arrange → EnsureValidVisuals` 这一跳 ⇒ 页视觉帧不建 ⇒ 两支造行视觉都到不了内容段」**。**不是** `deferred` 门、**不是** native 几何（承 `T-A42`）。
4. ⚠️ **驱动已落（方案 3）且「造行支到达」0→>0 成立**：在生成件 `FlowDocumentPaginator.FormatPage` 的 `page.Arrange(pageSize)` 之后补 **`page.EnsureValidVisuals()`**（与上游 `FlowDocumentFormatter.Arrange` 的次序同形；`WPF_LINEVIS_DRIVE=0` ⇒ 逐字回上游）。现取：`FIG.ValidateVisual` **0→2**、内容段 `RenderSimpleLines` **0→1**、**`[FSQLL] cLines=1` 0→2**（且其 `parah` 与内容段 `[FSQTD] cLines=1`／`[FS_TLB] … cLines=1` 的句柄**逐字相同**）。
5. 🔴 **判据 ② 未达（如实）**：`k24` 帧四具名色现取 **`GhostWhite=29667`／`Beige=0`／`DarkGreen=0`／`LightGoldenrodYellow=0`**（`PTS_COLORANCHOR=FAIL hits=1 expect_min=200 expect_hits=2`）——**四腿（含驱动态）逐字节同值**；余 3 色**一斤没落**。⇒ **"行盒视觉对象已建" ≠ "内容画到在屏帧"**：本趟的行视觉**零像素**（`NOINFO-LINEVIS-NOT-ON-SCREEN`，§5）。
6. ✅ **症状门零回归 ＋ 帧面成对（但驱动零像素）**：四腿 `alive=yes app_rc=143 failfast=0 unrec=0 magenta=0 colors=765 ink=480000 ns=…FlowDocumentDemo`、`[HC-UNHANDLED]=1`（**未涨**）；`boot.png` 四腿同值 `b21eb530afd3c66c`（四色全 0）、`k24` 四腿同值 `2d89d393157b0df6`、`k23` 四腿同值 `10d0b9d54e649c10`。⚠️ **`k24` 帧未变**（判据 `D3` 的"必须变"**不成立**，如实记）。
7. ✅ **门禁（④）**：生成器**幂等**（连跑两次，全部生成件 ＋ `csproj` 的合并 `sha16` 同值 `f3bf28476cd209e0`）；`nm -D --defined-only` ＝ `exports.txt` ＝ **683**（逐名 `diff` 零差异）；`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=5b7d0ac101673900 exports=683`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`／`DECLDRIFT=0`（rc=0）；`REPORTID=PASS files=323 …`（rc=0）。

---

## §1 改动（逐处）

### 1.1 生成器（`reapply-patches.py`）新增 **两处** 编辑表 ＋ 一个新建件

| 项 | 内容 |
|---|---|
| `TPC_EDITS`（6 处 → `TextParaClient.Linux.cs`） | `UpdateViewport`／`ValidateVisual` 两支入口各 ＋1 行判别器；`RenderSimpleLines`／`UpdateViewportSimpleLines`／`SyncUpdateDeferredLineVisuals` 三个造行支各 ＋1 行；文件尾 ＋ `WpfLinuxLineVisProbe` 类 |
| `CHAIN_FILES`（7 个上游件 → 7 个生成件） | `FlowDocumentPage`（4 处）／`PtsPage`（3）／`PtsHelper`（4）／`FigureParaClient`（2）／`ContainerParaClient`（2）／`FlowDocumentFormatter`（1）／`FlowDocumentPaginator`（**1 ＝ 驱动**） |
| `WpfLinuxChainProbe.Linux.cs` | **新建件**（非派生）：`[CHAIN]` 类本体 ＋ `EnvOn(name)`（缺省开、显式 `"0"` 关） |
| `PATCH_C` | 新增对应 `<Compile Remove=上游件/>` ＋ `<Compile Include=生成件/>`（共 7 组 ＋ 新建件 1） |

**每处改动都只 ＋1 行（或一个方法级包裹），逐处可复核**；`_apply_edits` 的 needle 命中数校验**全部命中**（生成时逐件打印 `[OK] … needle 全部命中`）。

**落盘原子化（`P8` 同类纪律）**：所有生成件（含新建件）与 `csproj` 一律走已有的 `_write_atomic`（`temp + fsync + os.replace`）。

### 1.2 为什么判别器落在**托管侧**（不是 native）

`T-A43 §2.1` 已证：native 侧 `[FSQTD]` 是**多消费者共用入口**，`FsQueryTextDetails` 的 20 个托管调用点里**单看 native 不辨"谁调的"**；`BaseParaClient.UpdateViewport`／`ValidateVisual` 是**托管内部虚方法、无 P/Invoke**（`exports.txt` 里 `updateviewport` 命中 0）。⇒ **"谁到了内容段"与"`IsDeferredVisualCreationSupported` 取何值"只能在托管侧落**。native 面现有 `[FSQVP]`／`[FSQTD]`／`[FSQLL]`／`[VIS]`／`[QPD]` 已够作**对照**，本轮**未改 native**（`.so`／`exports.txt` 逐字节未变 —— 这也是 `nm==exports` 与 `PTSGAP so16` 未动的机器证）。

### 1.3 驱动（方案 3，唯一那处**行为**改动）

**落点**：生成件 `FlowDocumentPaginator.Linux.cs` 的 `FormatPage`：

```csharp
            breakRecordOut = page.FormatFinite(pageSize, pageMargin, breakRecordIn);
            page.Arrange(pageSize);

            // ── T-A44 驱动：补上"页视觉帧"缺的那一跳 ──
            if (WpfLinuxChainProbe.EnvOn("WPF_LINEVIS_DRIVE"))
            {
                WpfLinuxChainProbe.Hit("DRIVE.EnsurePageVisuals", "site=FDPaginator.FormatPage page=" + page.GetHashCode());
                page.EnsureValidVisuals();
            }
```

**为什么是这一跳（三件现取证据）**：
1. 上游 **另一条** 宿主路径 `FlowDocumentFormatter.Arrange` 的次序是 `_documentPage.Arrange(...)` → **`_documentPage.EnsureValidVisuals()`** → `_documentPage.UpdateViewport(...)`；分页器这条路（`FormatPage`）**只调 `Arrange`**。
2. `[CHAIN]` 现取：`FDG.EnsureValidVisuals` ＝ 2（只在 `FDF.Arrange` 那两趟），`PTSP.GetPageVisual` ＝ 2，而 `FDG.Arrange` ＝ 242 ⇒ 分页器那 240 趟**从未**建页视觉。
3. `[CHAIN]` 现取：`FDG.UpdateVisual` 6 次里 **4 次 `needsUpdate=0`**（`FlowDocumentPage.Visual` 的 getter 打点），说明"视觉帧没建"不是"没人问"，而是"`_visualNeedsUpdate` 已假而 `EnsureValidVisuals` 从没被叫"。

**零假值**：不伪造任何几何（`fsrc`／`dvrUsed`／附属对象盒一字未动）；不置 `fLinesComposite`／`fUpdateInfoForLinesPresent`；**不删／不放宽任何 `Invariant.Assert`**（`EnsureValidVisuals` 自带的 `Invariant.Assert(!IsDisposed)` 照旧响亮）；`WPF_LINEVIS_DRIVE=0` ⇒ **逐字回上游**（反极性腿可在**同一产物**上把驱动整个摘掉）。

### 1.4 逐件 sha16（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `build/PresentationFramework.Linux/reapply-patches.py` | `9a9a523f79823228` | **`68381ffcb7d2bf7e`** |
| `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` | `e22a7457dc4a8010` | **`7dbfcb274d587ba4`** |
| `…/TextParaClient.Linux.cs`（生成件，新） | —— | **`5cd1666167e29339`** |
| `…/WpfLinuxChainProbe.Linux.cs`（生成件，新） | —— | **`856d68514ff328d5`** |
| `…/FlowDocumentPage.Linux.cs`（生成件，新） | —— | **`d138d81d6be29186`** |
| `…/PtsPage.Linux.cs`（生成件，新） | —— | **`dc1e3c654cfe8208`** |
| `…/PtsHelper.Linux.cs`（生成件，新） | —— | **`1f72e29e7c1389d9`** |
| `…/FigureParaClient.Linux.cs`（生成件，新） | —— | **`e62991bd4d301cfc`** |
| `…/ContainerParaClient.Linux.cs`（生成件，新） | —— | **`7dfa5450402095f3`** |
| `…/FlowDocumentFormatter.Linux.cs`（生成件，新） | —— | **`8af2d392cead9d94`** |
| `…/FlowDocumentPaginator.Linux.cs`（生成件，新） | —— | **`5b6035354f0f1a72`** |
| `…/PtsCache.Linux.cs`（生成件） | `e5b399fdb8742092` | **`e5b399fdb8742092`（未变 ⇒ 幂等）** |
| `…/FlowDocumentView.Linux.cs`（生成件） | `7b32ca403752c703` | **`7b32ca403752c703`（未变 ⇒ 幂等）** |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `52cf1b0012667dd0` | **`27f07a325da4583c`**（6137344→6142464 B） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `5b7d0ac101673900` | **`5b7d0ac101673900`（未变）** |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `860a3abe4a64f1c5` | **`860a3abe4a64f1c5`（未变）** |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `826c896ebe77e917` | **`826c896ebe77e917`（未变）** |

**黑名单副作用如实记**：跑生成器会**重排** `PresentationFramework.Linux.csproj` 里其它车道注入的块 ⇒ 本席现取 **`sort` 后 `diff` 零差异（只多本趟新增的 16 行）**，未做还原（本趟 `csproj` 本就在写域内）。

---

## §2 成对读数（**同一装置 `:231`／同批工具**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；A 臂 `clicks=[24,23]`；证据 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2j/`）

| 腿 | 判别器／驱动 | `pf` `sha16` | 证据目录 |
|---|---|---|---|
| `disc1` | `[TPCL]` 开（**加 `[CHAIN]` 之前**） | `33f6530d34b12e0c` | `…/disc1/` |
| `chain1` | `[TPCL]`＋`[CHAIN]` 开（无驱动） | `47d7e48da21b08ea` | `…/chain1/` |
| `drive0` | **反极性腿**：`WPF_LINEVIS_DRIVE=0` | `27f07a325da4583c` | `…/drive0/` |
| `drive1` | **驱动态**：`WPF_LINEVIS_DRIVE=1` | 同 | `…/drive1/` |

### 2.1 逐腿现取计数（`app_g1.log`，只读 `grep -c`）

| 量 | `disc1` | `chain1` | `drive0`（反极） | **`drive1`（驱动）** |
|---|---|---|---|---|
| `app_g1.log` 行数 | 31180 | 11532 | 29687 | **2431** |
| **`[FSQLL] … cLines=1`** | **0** | **0** | **0** | **2** |
| `[TPCL] site=RenderSimpleLines` | 1 | 1 | 1 | **9** |
| `[TPCL] site=ValidateVisual` | 4 | 4 | 4 | **12** |
| `[TPCL] site=UpdateViewport` | 4 | 4 | 4 | **4** |
| `[TPCL] site=UpdateViewportSimpleLines` | 3 | 3 | 3 | **3** |
| `[TPCL] site=SyncUpdateDeferredLineVisuals` | 3 | 3 | 3 | **3** |
| **`[CHAIN] site=FIG.ValidateVisual`** | —— | **0** | **0** | **2** |
| `[CHAIN] site=FDF.Arrange` | —— | 2 | 2 | **2** |
| `[CHAIN] site=FDG.Arrange` | —— | 84 | 242 | **4** |
| `[CHAIN] site=DRIVE.EnsurePageVisuals` | —— | —— | **0** | **2** |
| `[FSQVP]` 轮数 | 764 | 248 | 722 | **11** |

**`[TPCL]` 逐字样本（`drive1`，内容段 `cLines=1`）**：
```
[TPCL] site=ValidateVisual parah=0x643ddbd60774 cLines=1 composite=0 att=0 deferred=0 fsktd=1 NOINFO=tpcl-entry-readonly
[TPCL] site=RenderSimpleLines parah=0x643ddbd60774 cLines=1 composite=0 att=0 deferred=-1 updateInfo=0 NOINFO=tpcl-entry-readonly
[FSQLL] rc=0 reason=ok entry=FsQueryLineListSingle ctx=0x643ddbd57110 parah=0x643ddbd60774 cLines=1 calls=15 ok=15 gap=0 nomodel=0 fl_ok=1 out=WRITTEN bytes=72 src=ledger:fl_line[]←pfnFormatLine
[FS_TLB] entry=FsQueryLineListSingle parah=0x643ddbd60774 lines=1 dcpFirst=0 dcpLim=41 NOINFO=fsgeometry-layout(vrStart=self-accum,urStart=urBBox,dur=self-page-width)
```
⇒ 该 `parah` **同时**出现在 `[FSQTD] … cLines=1` 与 `[FS_TLB] entry=FsQueryTextDetails … cLines=1 … attached-objects=not-present(true-queried)` ⇒ **与 `T-A43` 的"内容段"同形**（`dcpLim=41`）。

**`[CHAIN]` 逐字样本（`drive1`，那一跳）**：
```
[CHAIN] site=DRIVE.EnsurePageVisuals site=FDPaginator.FormatPage page=25927028 NOINFO=chain-entry-readonly
[CHAIN] site=FDG.EnsureValidVisuals needsUpdate=1 NOINFO=chain-entry-readonly
[CHAIN] site=FDG.UpdateVisual needsUpdate=1 NOINFO=chain-entry-readonly
[CHAIN] site=PTSP.GetPageVisual empty=0 visual=0 NOINFO=chain-entry-readonly
[CHAIN] site=FIG.ValidateVisual parah=0x643de1a60c38 inh=2 NOINFO=chain-entry-readonly
```
**`[CHAIN]` 逐字样本（反极性腿 `drive0`，同一跳）**：
```
[CHAIN] site=FDG.Arrange size=816x1056 NOINFO=chain-entry-readonly      ← 分页器：A2. 只有 Arrange，没有 EnsureValidVisuals
[CHAIN] site=FDG.UpdateVisual needsUpdate=0 NOINFO=chain-entry-readonly ← `_visualNeedsUpdate` 已假 ⇒ UpdateVisual 空转
（全程 0 行 `site=DRIVE.EnsurePageVisuals`；0 行 `site=FIG.ValidateVisual`）
```

⚠️ **计数不可当"稳定量"**：`FDG.Arrange` 现取 `84/242` 两态差 158 次、`[FSQVP]` `248/722`，**逐趟时长/节拍不同**（本件**不作减法**，也不把次数当"机制"证据）；**唯一稳定读数 ＝「内容段 `[TPCL]` 在 `FlowDocumentDemo` 阶段恒 0 行（反极/无驱动）」∧「内容段 `[FSQLL] cLines=1` 恒 0」∧「四腿 `k24` 帧逐字节同值」**。

### 2.2 症状门 ＋ 帧面（逐腿现取，`leg_*.env` ＋ 只读 PNG）

| 腿 | `alive` | `app_rc` | `failfast` | `unrec` | `magenta` | `colors`(k24) | `ink` | `ns`(k24) | `[HC-UNHANDLED]` | `k24` `fr_sha` | `fr_ae_boot` | `k23` `fr_sha` | `boot` `fr_sha` |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `disc1` | yes | 143 | 0 | 0 | 0 | 765 | 480000 | `…FlowDocumentDemo` | 1 | `2d89d393157b0df6` | 220019 | `10d0b9d54e649c10` | `b21eb530afd3c66c` |
| `chain1` | yes | 143 | 0 | 0 | 0 | 765 | 480000 | 同 | 1 | 同 | 220019 | 同 | 同 |
| `drive0` | yes | 143 | 0 | 0 | 0 | 765 | 480000 | 同 | 1 | 同 | 220019 | 同 | 同 |
| `drive1` | yes | 143 | 0 | 0 | 0 | 765 | 480000 | 同 | 1 | 同 | 220019 | 同 | 同 |

### 2.3 帧面四色锚（本席自算，只读 PNG；锚集 ＝ `GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`；`LightGray` **不入集**）

| 帧 | 四腿 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `hits(≥200px)` | `ncolors` |
|---|---|---|---|---|---|---|---|
| `boot` | 同值 `b21eb530afd3c66c` | **0** | **0** | **0** | **0** | 0 | 386（`LightGray=44`） |
| **`k24`** | 同值 `2d89d393157b0df6` | **29667** | **0** | **0** | **0** | **1** | 765 |
| `k23` | 同值 `10d0b9d54e649c10` | 0 | 0 | 0 | 0 | 0 | 636 |

⚠️ **不得把空白读成绿**：`GhostWhite` 是 `Figure`/`Floater` 的 **`Background`**（`DrawBackgroundAndBorder` 所绘），**不是**"内容真绘出"；三内容色**四腿恒 0**（**含驱动态**）。

**`guard` 判词逐字（现取，`--legs`，四腿同形）**：
```
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=29667 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=1 expect_min=200 expect_hits=2 baseline=… phase=degraded reason=declared-color-anchor-absent
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=degraded
PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),leg24-color-anchor-absent(hits=1<2,…),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=765,leg23-colors-out-of-band=636 direction=in-file phase=degraded
```
（`PTS_GUARD=FAIL` 的六项**全部为改前既有状态**，本增量**不新增**任何一项；四腿 `guard rc=1`。）

---

## §3 验收逐条（对 `T-A44` ③；**逐条带反极性**）

| # | 判据 | 现取 | 判 |
|---|---|---|---|
| **①** | `A43` 的 `D0–D3` 逐条现取 ＋ 每条带反极性 | 见下四行 | **`D0` 成立；`D1` 未达；`D2` 成立；`D3`（成对部分）成立** |
| **②** | **关键**：`k24` 四具名色各 ≥200px（baseline 仍全 0）；**内容段造行视觉到达计数 0→>0** | 四色 `29667/0/0/0`（`hits=1`）；`[FSQLL] cLines=1` **`0`（反极/无驱动）→ `2`（驱动）** | ⚠️ **半达**：到达计数**0→>0 成立**；**四色 未达** |
| **③** | 帧面成对（帧 `sha16`／`AE(content)`；不得把空白读成绿） | 四腿 `boot`／`k24`／`k23` **逐字节同值**；`boot` 四色全 0；`AE(boot,k24)=220019` 四腿同 | ✅（**成对成立**）；⚠️ **`k24` 帧"必须变"未成立**（驱动**零像素**） |
| **④** | 生成器幂等；`nm==exports`；`PTSGAP=PASS`；`DEFREG`／`REPORTID` rc=0 | §6 逐行 | ✅ |
| **⑤** | 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）成对 | §2.2（四腿逐格同） | ✅ |

- **`D0`（分流/诊断）**：判据要求「`[FSQLL] rc=0` 的 `cLines` 直方图**首次**出现 `cLines=1`，其 `parah` ＝内容段句柄；**且**陪跑的**具名**只读行给出"到了内容段的是 `ValidateVisual` 还是 `UpdateViewport`"＋`IsDeferredVisualCreationSupported` 取值」。
  **现取**：`[TPCL]` 逐条给出 `site=`／`deferred=`（`D0` 的那一问**首次可现取**）；`[FSQLL] cLines=1` 在驱动腿**首次**出现 **2 次**，`parah=0x643ddbd60774` 与内容段 `[FSQTD]/[FS_TLB] … cLines=1` 句柄**逐字相同**；**到达的那一支是 `ValidateVisual`→`RenderSimpleLines`**（非 `UpdateViewport`；后者在内容段上**仍 0 次**）。
  **反极性（必红腿）**：① **撤驱动**（`drive0`）⇒ `[FSQLL] cLines=1` **回 0**、`[TPCL] site=RenderSimpleLines` 只剩 `PracticalDemo` 那 1 次（内容段 0）⇒ 「驱动一动就到达」**不是恒绿**（`P8` 恒绿陷阱不在本件上）；② **关掉判别器**（`WPF_TPCL_PROBE=0`／`WPF_CHAIN_PROBE=0`）⇒ 逐字回上游行为（`disc1` 与 `chain1` 的**帧面逐字节同值**即其机器证：判别器**不比**它的读数更能影响结果）。⚠️ **本件的"假判别器必红"只到上面两条**：本席**未**造"无条件打印"的合成假判别器腿（如实记，列 `NOINFO`）。
- **`D1`（余 3 具名色各 ≥200px）**：❌ **未达**（`hits=1`，**四腿同**）。**反极性**：驱动态与撤回态**同值**（`hits=1`）⇒ 「到达造行支 ⇒ 色就齐」**不成立**；且 `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（**严禁**把 `k=24` 的锚推广到 `k=23`）。
- **`D2`（baseline 仍全 0／活锚）**：✅ `boot.png` 四色**四腿全 0**（`all_zero=yes dead=none`、`LightGray=44` **不入集**）。
- **`D3`（帧面成对 ＋ 不得把空白读成绿 ＋ 失败必留痕）**：✅ **成对**（四腿三帧逐字节同值；`k24≠k23≠boot`）；`[HC-UNHANDLED]` **恰 1（未涨）**；"没落到造行支"有具名行（`[CHAIN] FDG.UpdateVisual needsUpdate=0`／`[TPCL]` 缺行）⇒ **与"真 0 次"可分辨**。⚠️ **未成立的部分**：`k24` 帧**没变**（驱动**零像素**，如实记，见 §5-2）。

---

## §4 反极性（**同一 `.so` ＋ 同一跑器 ＋ 同一装置 ＋ 同一 `pf`**，只差**一个 env**：`WPF_LINEVIS_DRIVE`）

| 判据 | **驱动态**（`drive1`） | **显式 `=0`（撤回）**（`drive0`） | 加 `[CHAIN]` 之前（`disc1`） |
|---|---|---|---|
| `[CHAIN] site=DRIVE.EnsurePageVisuals` | `2` | **`0`** | ——（无此面） |
| `[CHAIN] site=FIG.ValidateVisual` | **2** | **0** | ——（无此面） |
| `[TPCL] site=RenderSimpleLines`（内容段） | **1**（另 8 次属 `PracticalDemo`） | **0** | **0** |
| **`[FSQLL] cLines=1`** | **2** | **0** | **0** |
| `k24` 帧／`colors`／`hits` | `2d89d393157b0df6`／765／1 | **同** | **同** |
| 症状门 | 逐格同 | **逐格同** | 逐格同 |

✅ **本件的第一条反极性是"真跑"的那一极**：`WPF_LINEVIS_DRIVE=0` ⇒ `DRIVE.EnsurePageVisuals` 行**整个消失**、`FIG.ValidateVisual` **回 0**、`[FSQLL] cLines=1` **回 0** ⇒ **驱动 ↔ 撤回 两态在"到达"这一面上可分**。
🔴 **如实披露（本件的反极性**在像素面上是退化的）**：`drive0`／`drive1` 的 `boot`／`k24`／`k23` 三帧**逐字节相同** ⇒ **本件不能声称"驱动一动像素就变"**；本页上"驱动"这一极**只**在**台账面**（`[CHAIN]`／`[TPCL]`／`[FSQLL]`）可分。⇒ 按 `T-A41` 的先例形态，本件的反极性**由"到达面"承担，"像素面"如实记为零效果。
**最便宜的下一条真反极性腿（本件只登记、不跑）**：把内容段所在**子页盒**（native `FsQuerySubpageDetails` 的 `fsrc`）临时改成覆盖任意有限视口 ⇒ 若"行视觉已建却零像素"**仍**为真，则 `NOINFO-LINEVIS-NOT-ON-SCREEN` 的成因不在几何；**本浪不做**（`A43 §5.1` 明禁改几何换绿，且本浪方案数已尽）。

---

## §5 边界 · `NOINFO` · 主动披露

1. **`NOINFO`（逐条给"消掉需要什么"）**：
   - **`NOINFO-LINEVIS-NOT-ON-SCREEN`（本件新读出，本件**最要**的一条）**：驱动后内容段**确已** `ValidateVisual`→`RenderSimpleLines`→`[FSQLL] cLines=1`（行视觉对象**已建**），但 `k24` 帧**逐字节不变** ⇒ **"建了行视觉"与"画到在屏帧"之间还有断点**。本件**只**证"到达"（判据字面），**不**证"那份文档就是在屏的那一份"。**消掉需要**：一条"在屏文档身份"的只读面（例如把 `FlowDocumentPage`／`DocumentPageView` 的实例身份与 `RenderSize` 打进台账），或对"行视觉的 `Offset`／所属 `ContainerVisual` 是否悬挂在在屏树"给一条只读见证。
   - `NOINFO-FSVIEW-ARRANGE-TRIGGER`（承 `T-A41`）—— **本轮扩展**：不只 `FlowDocumentView.ArrangeOverride`（＝2 次），`FlowDocumentFormatter.Arrange` 本身 **2 次**、`FlowDocumentPage.Arrange` **242 次**（分页器）、`FlowDocumentPage.EnsureValidVisuals` **2 次**。⇒ "哪条宿主路径在跑"**已直读**。
   - `NOINFO-CHAIND-OWNER-OF-PAGINATOR`（**本件新读出**）：那 240+ 次 `FlowDocumentPaginator.FormatPage` **归谁**（`FlowDocumentReader`？`FlowDocumentPageViewer`？还是**后台预分页**对**非在屏**文档做的？）本侧**不可判**（无"文档身份"面）。**消掉需要**：`FlowDocumentPaginator` 实例与 `_document` 的只读身份行。
   - `NOINFO-FAKE-DISCRIMINATOR-POLARITY`（**本件新读出**）：判据 `D0` 要求"用假判别器 ⇒ 必红"，本席**未**造合成假判别器腿。**消掉需要**：一条"无条件打印"的判别器腿 ＋ 其自洽性反例。
   - `NOINFO-DEFERRED-SUPPORT-VALUE`（承 `T-A43`）—— **本轮消掉"取值"这一半**：`deferred` **已可逐点现取**（有真有假）；**仍未消**的是"内容段的 `deferred` 为什么是那个值"（`_currentPage`／`FinitePage` 无直读）。
   - `NOINFO-FSQLL-CALLER-DISCRIMINATION`（承 `T-A38`/`A41`）：`[FSQLL]` 的调用者在内容段上**本轮已定为 `RenderSimpleLines`**（`[TPCL]` 现取）；**仍未消**的是"内容段以外的那些 `[FSQLL]` 是谁"。
   - `NOINFO-CONTENT-VIEWPORT-VALUES`（承 `T-A38`/`A39`/`A42`）：内容段两支门的操作数**数值**仍无托管直读；本件 `[TPCL] UpdateViewport` 只给到**其它段**的 `rectV/rectDV/vpV/vpDV`（内容段**根本没进** `UpdateViewport`）。
2. **本增量的射程（写死，防被读宽）**：本件交付的是 **① 两层只读判别器（`[TPCL]`／`[CHAIN]`，均可整体关掉、判别器开关不改任何像素）＋ ② 一次对 `T-A43` 两因的判定（**因 B**）＋ ③ 把断点从"两因不可分"收到**一跳**（`FormatPage` 缺 `EnsureValidVisuals`）＋ ④ 一处**可切两极**的驱动（到达 0→>0）**。它**不是**"排版打通"、**不是**"内容真绘出"、**不是**"色锚转绿"。
3. **方案数 ＝ 3＋1 条反极性腿**（在 ② "最多 3 种方案" 内）：**方案 1** ＝ `[TPCL]` 判别器；**方案 2** ＝ `[CHAIN]` 逐跳判别器；**方案 3** ＝ `FormatPage` 上补 `EnsureValidVisuals`。⇒ 按 ②"**失败即如实报停止（允许判合法终点）**"收口：**判据 ② 的"余 3 色"未达** ⇒ 本件的合法产出是**具名的下一靶**（§5-1 `NOINFO-LINEVIS-NOT-ON-SCREEN`）＋**可复算的 8 腿成对基线**＋**两层只读面**。
4. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；**未**新增任何 `D-G<digits>` 登记编号；未跑 `--all-arms`；**未改** `upstream/**`；**未改** `docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`win32_classification.c` —— **理由有机器证**：本趟**移动的字段只有托管件的 `sha16`**（native 的 `so16=5b7d0ac101673900`／`tool/dead/artifact/ops/impl/exports` **逐格未动**，现取 `PTSGAP=PASS` 逐字），上述**现值位件**都不持"托管 `pf` `sha16`"格 ⇒ 结论 ＝ `NOINFO(reason=no-current-value-cell-moved)`，**不是"漏改"**（若主控要求把 `pf` 现值位一并刷新，请同趟下发指令）。
5. **跨代／跨装置不可比（纪律 31/32）**：加 `[CHAIN]` 之前的 `disc1` 与加之后的 `chain1`／`drive0`／`drive1` **同为同一装置 `:231`／同 `.so` `5b7d0ac101673900`**；`k24` 帧 `2d89d393157b0df6` 与 `T-A42` 的 `legA`／`T-A43` 的在册值**逐字节相同** ⇒ 只报**结果**，**不做减法承重**。
6. **主动披露（两处"本件与承件不同"）**：
   - `T-A43 §2.2/§2.4` 用 `[FSQVP] via=` 把内容段的 `[FSQTD]` 归到 `via=viewport` 类轮，并推"视口支到了内容段"。本件**现取不支持**它：内容段的 `UpdateViewport` **一次都没被调**（`[TPCL]` 0 行）；那些 `[FSQTD]` **不来自** `UpdateViewport`（`FsQueryTextDetails` 的其它 18 个托管调用点）。⇒ `T-A43` 的"因 B"**成立**，但其"视口支到了内容段"的措辞**宜改**为"内容段被**非视口支**的消费者反复查询"。
   - `T-A41 §0.3` 的"驱动零效果（`handed == viewport`）"与本件**同向**；本件**新增**的是"**另一条宿主路径（分页器）缺 `EnsureValidVisuals`**"这一定位，以及"补上后**到达**成立但**像素仍零**"这一**更前沿的断点**。
7. **侧效（如实披露，未进仓）**：`~/tA44-work/`（`bak/` 改前件 ＋ `an.py`／`an2.py`／`chk.py`／`gates.sh`／`tab.sh`）；仓内应用安装由 `sync-applocal.sh` 刷 `PresentationFramework.dll` **一件**（`drift=1 → 0`；四腿逐腿 `POSTSHIM … == authority`）。

---

## §6 落盘后复跑（现取；`④` 的成对读数）

```
GEN_IDEMPOTENT=YES        （连跑两次：全部 *.Linux.cs ＋ csproj 的合并 sha16 ＝ f3bf28476cd209e0 两次同值）
NM=683 EXPORTS=683        NM_EXPORTS_MATCH=YES   （逐名 diff 零差异）
PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=5b7d0ac101673900 exports=683   （rc=0）
DEFREG=PASS declared=225 route_ids=225 ／ DEFREG_DECLDRIFT=0 keys=-                        （rc=0）
REPORTID=PASS files=323 ids=2233 declared=225 glob=build/MilBridge/*report*.md              （rc=0；落盘前 files=322 ⇒ 本载体 ＋1 件）
PTS_COLORANCHOR=FAIL k=24 hits=1 expect_min=200 expect_hits=2 （四腿同形，`--legs`）
```
⚠️ **`ids` 不写死**：它是"报告件集合上的派生量"、而**本载体自己就在该集合里** ⇒ 任何一次改字都会动它 ⇒ 本席只给**命令**与 `PASS`／`files`／`declared` 三格。
⚠️ **`DEFREG_DECLDRIFT=0`** ⇒ 本趟**未改** route 件 ⇒ **不需**主控重发 `declared.tsv`（与 `T-A41` 不同）。

**`git status --porcelain`（现取）**：
```
 M build/PresentationFramework.Linux/PresentationFramework.Linux.csproj
 M build/PresentationFramework.Linux/reapply-patches.py
?? build/MilBridge/tasks-tail2/T-A44.md                       （先于本件，属他人）
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log （先于本件，属他人）
?? build/MilBridge/tests/PtsPagesProbe/evidence-tail2j/       （本趟 4 腿证据）
?? build/PresentationFramework.Linux/{ContainerParaClient,FigureParaClient,FlowDocumentFormatter,FlowDocumentPage,FlowDocumentPaginator,PtsHelper,PtsPage,TextParaClient,WpfLinuxChainProbe}.Linux.cs
```

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-linevis-impl-report.md | sha256sum | cut -c1-16`）= b79216e0795b0082

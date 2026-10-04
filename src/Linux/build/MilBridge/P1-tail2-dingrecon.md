# P1-tail2 · T-A67 · 丁类 16 条（「内容层那一波」）可及性侦察 —— 只读

> **只读**：除本载体外**未改任何仓内文件**；**未构建**；**未跑整趟 `verify-all`**；**未占显示位**；进程只按 PID；**禁 `sleep` 轮询**；大件只用 `wc`／`head`／`tail`／`grep`；**未 `git add/commit/push`**。行号一律整行取（`grep -n`），只本次有效（内容锚原文一并给出）。

---

## §0 在飞件与代际（现取）

- **载体**：`build/MilBridge/P1-tail2-dingrecon.md`（**新建**，`mode 644`）。读取时刻：**2026-10-01 20:3x–20:5x+0800**；`HEAD=ec63954`（`P1 尾波2 (#82)：T-A66 补头件（wpf_window.scroll_pos[2]，SetScrollPosWrapper 状态）`）。
- **现取件代**（`sha256` 前 16 位，本席现取）：
  - `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`3118bd1ce7d9604c`**
  - `src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **`d925266b9acd9847`**／**727 行**
  - `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`11a3f6ba49f3f22c`**／**9538 行**
  - `upstream/…/TextFormatting/LineServices.cs` ＝ **`8b2bc2167f5c0bd3`**／**1620 行**（＝ `T-A65` 在册同代）
- **在册声明行（现取，`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt:34`）**：`# PTSGAP-DECL: tool=54 dead=11 artifact=1 ops=42 impl=42 so16=3118bd1ce7d9604c exports=727 w66pre16=bf6b683d94549087`。
- **判据来源**（本席只读，**未独立复算其内部读数**）：`build/MilBridge/P1-tail2-gapgrade-recon.md`（`T-A65`）、`build/MilBridge/P1-ls-provenance-contract.md`（`t193`）、`build/MilBridge/P1-ls-provenance-recon.md`（`t190`）、`build/MilBridge/P1-layout-content-criteria.md`（`t185`）、`build/MilBridge/P1-ls-callback-face-recon.md`（`t186`）、`build/MilBridge/P1-ls-family-recon.md`、`build/MilBridge/P1-tail2-hostline-recon.md`（`T-A27`）、`build/MilBridge/P1-tail2-gapbatch2-impl-report.md`（`T-A62`）、`build/MilBridge/P1-tail2-t0307-recon.md`、`docs/ROUTES.md`。

---

## §1 取数口径（可复跑）：丁类 16 条＝`Lo*` 12 ＋ 文本分析 4

```bash
python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier all > /tmp/tA67_raw.txt
awk '$1=="PresentationNative_cor3.dll"{print $2}' /tmp/tA67_raw.txt | LC_ALL=C sort > /tmp/tA67_gap.txt
```

- **现取**：`[PresentationNative_cor3.dll]` 段 **`tool=54`**（本席 `wc -l /tmp/tA67_gap.txt` ＝ 54），与在册 DECL 逐值相符。
- **族分解（现取，可复算）**：`Fs*` **29** ＋ `Lo*` **12** ＋ `Nl*` **6** ＋ 文本分析 **4** ＋ `*Wrapper` **3** ＝ **54**（`T-A65` 的 47 ＝ `59−11−1`；本趟为 `54−11−1＝42`，差额 5 ＝ `T-A66`／`gapbatch3` 已实施的甲类 5 条，**与 `Lo*`／文本分析无关** ⇒ **丁类 16 条一条未动**）。
- **丁类 16 条现取名单**（`/tmp/tA67_gap.txt`）：
  - `Lo*` 12：`LoAcquireBreakRecord`／`LoCloneBreakRecord`／`LoCreateBreaks`／`LoCreateLine`／`LoDisplayLine`／`LoDisposeBreakRecord`／`LoDisposeLine`／`LoEnumLine`／`LoQueryLineCpPpoint`／`LoQueryLinePointPcp`／`LoRelievePenaltyResource`／`LocbkGetObjectHandlerInfo`。
  - 文本分析 4：`CreateTextAnalysisSink`／`CreateTextAnalysisSource`／`GetNumberSubstitutionList`／`GetScriptAnalysisList`。

---

## §2 丁类 16 条逐条（名／声明件:行／签名与出参形态／调用点／根对象或依赖）

> **签名与出参形态**一律现取自 `LineServices.cs`（整行）；**调用点**＝`UnsafeNativeMethods.<名>` 的静态文本命中（本席 `grep -rn` 现取，`sed` 去前缀，仅本次有效）。

### 2-A `Lo*` 12 条（声明件 `LineServices.cs`）

| # | 名 | 声明 件:行 | 签名与出参形态 | 调用点（现取，本移植落点） |
|---|---|---|---|---|
| 01 | `LoAcquireBreakRecord` | `:1440-1444` | `LsErr (IntPtr ploline, out IntPtr pbreakrec)` —— **出参＝断行记录句柄** | `PresentationCore/MS/internal/TextFormatting/TextMetrics.cs:291` |
| 02 | `LoCloneBreakRecord` | `:1453-1457` | `LsErr (IntPtr pBreakRec, out IntPtr pBreakRecClone)` —— 出参＝记录副本 | `PresentationCore/System/Windows/Media/textformatting/TextLineBreak.cs:73` |
| 03 | `LoCreateBreaks` | `:1522-1531` | `LsErr (IntPtr ploc, int cpFirst, IntPtr previousBreakRecord, IntPtr ploparabreak, IntPtr ptslinevariantRestriction, ref LsBreaks lsbreaks, out int bestFitIndex)` —— **出参＝断点集 `LsBreaks` ＋ 最佳索引** | `PresentationCore/System/Windows/Media/textformatting/TextFormatterContext.cs:314` |
| 04 | `LoCreateLine` | `:1419-1431` | `LsErr (IntPtr ploc, int cp, int ccpLim, int durColumn, uint dwLineFlags, IntPtr pInputBreakRec, out LsLInfo plslinfo, out IntPtr pploline, out int maxDepth, out LsLineWidths lineWidths)` —— **出参＝`LsLInfo`（22 字段度量）＋行句柄＋深度＋宽度集** | `…/textformatting/TextFormatterContext.cs:288` |
| 05 | `LoDisplayLine` | `:1486-1492` | `LsErr (IntPtr ploline, ref LSPOINT pt, uint displayMode, ref LSRECT clipRect)` —— **无出参**；入参 `ploline` | `PresentationCore/MS/internal/TextFormatting/FullTextLine.cs:602` |
| 06 | `LoDisposeBreakRecord` | `:1446-1451` | `LsErr (IntPtr pBreakRec, bool finalizing)` —— **无出参**；入参 `pBreakRec` | `…/textformatting/TextLineBreak.cs:94` |
| 07 | `LoDisposeLine` | `:1433-1438` | `LsErr (IntPtr ploline, bool finalizing)` —— **无出参**；入参 `ploline` | `…/TextFormatting/FullTextLine.cs:145`；`FullTextBreakpoint.cs:197` |
| 08 | `LoEnumLine` | `:1494-1500` | `LsErr (IntPtr ploline, bool reverseOder, bool fGeometryneeded, ref LSPOINT pt)` —— **无出参**；入参 `ploline` | `…/TextFormatting/FullTextLine.cs:2131` |
| 09 | `LoQueryLineCpPpoint` | `:1502-1510` | `LsErr (IntPtr ploline, int lscpQuery, int depthQueryMax, IntPtr pSubLineInfo, out int actualDepthQuery, out LsTextCell lsTextCell)` —— **出参＝深度＋字盒** | `…/TextFormatting/FullTextLine.cs:2507` |
| 10 | `LoQueryLinePointPcp` | `:1512-1520` | `LsErr (IntPtr ploline, ref LSPOINT ptQuery, int depthQueryMax, IntPtr pSubLineInfo, out int actualDepthQuery, out LsTextCell lsTextCell)` —— **出参＝深度＋字盒** | `…/TextFormatting/FullTextLine.cs:2450` |
| 11 | `LoRelievePenaltyResource` | `:1459-1462` | `LsErr (IntPtr ploline)` —— **无出参**；入参 `ploline` | `…/TextFormatting/FullTextBreakpoint.cs:238` |
| 12 | `LocbkGetObjectHandlerInfo` | `:1551-1556` | `LsErr (IntPtr ploc, uint objectId, void* objectInfo)` —— **出参＝对象处理器信息（`objectInfo` 缓冲）** | `…/TextFormatting/LineServicesCallbacks.cs:2294` |

### 2-B 文本分析 4 条（声明件同件 `LineServices.cs`，`:1586-1618` 同段）

| # | 名 | 声明 件:行 | 签名与出参形态 | 调用点（现取） |
|---|---|---|---|---|
| 13 | `CreateTextAnalysisSink` | `:1589-1590` | `unsafe void* CreateTextAnalysisSink()` —— **返回值＝`IDWriteTextAnalysisSink*`** | `PresentationCore/MS/internal/Shaping/TypefaceMap.cs:120`（**方法组**传入 `TextAnalyzer.Itemize`） |
| 14 | `CreateTextAnalysisSource` | `:1609-1618` | `int (char* text, uint length, char* culture, void* factory, bool isRightToLeft, char* numberCulture, bool ignoreUserOverride, uint numberSubstitutionMethod, void** ppTextAnalysisSource)` —— **入参直接是字符文本**；出参＝分析源 | 同件 `:123` |
| 15 | `GetScriptAnalysisList` | `:1596-1597` | `unsafe void* (void* textAnalysisSink)` —— 出参＝脚本分析列表 | 同件 `:121` |
| 16 | `GetNumberSubstitutionList` | `:1603-1604` | `unsafe void* (void* textAnalysisSink)` —— 出参＝数字替换列表 | 同件 `:122` |

**现取佐证（本侧 0 实现）**：16 条在本侧**全为缺口** —— `exports.txt` 命名逐条 `grep -cx` ＝ **0**；`win32_pts.c` 里 `Lo*` 12 条的 `grep -c` ＝ **1**（**唯一命中是 `T-A62` 的排除注释**，`:4590-4595`），文本分析 4 条 `grep -c` ＝ **0**。

---

## §3 「内容层那一波」到底指什么（件:行定义 ＋ 可判据化）

### 3.1 在册出处（谁把它定成前置；逐行整行取）

| 角色 | 件:行 | 现取原文（要点） |
|---|---|---|
| **丁类判定行** | `build/MilBridge/P1-tail2-gapgrade-recon.md:41` | 「**丁**＝依赖内容层那一波（`TASK-0307` 的 `C2`/`C4` 等）」 |
| 丁类共同判据 | `P1-tail2-gapgrade-recon.md:157` | 「`T-A63` 现取判词：……**今天不存在、须"内容层那一波"新立**（本侧**不得**自算 `dcp`/`plsrun`）…… 须**先有 LS 会话 ＋ 文本段落进链**」 |
| 契约草案（用途＝当验收面） | `build/MilBridge/P1-ls-provenance-contract.md:3` | 「用途＝供将来"内容层那一波"**直接当验收面**」 |
| 契约 C2（LS 会话标识） | `P1-ls-provenance-contract.md:70` | 「C2｜LS 会话标识（`plsrun` 起点 或 `LoCreateContext` 的 `ploc`）｜❌ **不存在于我们的链上**……**须新立**」 |
| 契约 C4（`cp↔dcp` 偏移） | `P1-ls-provenance-contract.md:72` | 「C4｜`cp ↔ dcp` 偏移｜❌ **不存在**：全仓无填点 ⇒ **须新立**」 |
| 两条必红反腿（标"随那一波"） | `P1-ls-provenance-contract.md:80-81` | 「❌ **不能**（无 LS 会话、本侧无 `dcp` 值）⇒ 标**"随内容层那一波"**」 |
| 立名来源件 | `build/MilBridge/P1-ls-provenance-recon.md:99` | 「`plsrun`/`lscp` ↔ `nmp`/`dcp` 的**运行期对应关系与责任方**在仓内**不存在**，须由"内容层那一波"**新立**」 |
| 内容层本体判据（四条前置） | `build/MilBridge/P1-layout-content-criteria.md:110-114` | 「`PRECOND-NEW-CALLBACK-FACE`……`PRECOND-NO-TEXT-SOURCE`……`PRECOND-NO-LINE-BREAKER`……`PRECOND-NO-TEXT-PARA-IN-CHAIN`」 |
| 内容层本体判「本波不做」 | `P1-layout-content-criteria.md:128` | 「⇒ 判词：本波**不做** `S-2b`（**合法终点**）」 |
| 重入口径前置 | `build/MilBridge/P1-ls-callback-face-recon.md:85` | 「⇒ 新增具名前置：**`PRECOND-LS-SESSION-DRIVER`**……本侧要成为**重入方**（托管→我们→托管）」 |
| `T-A63` 判词 | `build/MilBridge/P1-tail2-lsprov-impl-report.md:48`／`:224` | 「**C2/C4 在 native 写域内结构性不存在**（须"内容层那一波"先有 LS 会话 ＋ 文本段落进链）」 |
| 路线图锚 | `docs/ROUTES.md:314-315` | 「`TASK-0307` …… 目标：解 `PRECOND-PARADESC-SOURCE-MISSING（scope=subtrack-path）` 与 `PRECOND-LS-PROVENANCE-BRIDGE`」 |

### 3.2 可判据化定义（写死）

> **「内容层那一波」不是一件在册器件，而是一条尚未开工的增量集合**；其**准入 ＝ 下列六条合取全部为真**（每条都有具名前置／件:行）：
> 1. **LS 会话进链**：`LoCreateContext` 的 `ploc` 与文本段落 `nmp` 在本侧同一窗内可观测 —— `PRECOND-LS-SESSION-DRIVER`（`P1-ls-callback-face-recon.md:85`）＋契约 `C2`（`P1-ls-provenance-contract.md:70`）；
> 2. **内容源入站**（字符序列）—— `PRECOND-NO-TEXT-SOURCE`（`P1-layout-content-criteria.md:112`）；
> 3. **行断器** —— `PRECOND-NO-LINE-BREAKER`（同上 `:113`）；
> 4. **文本段落进链** —— `PRECOND-NO-TEXT-PARA-IN-CHAIN`（同上 `:114`）；
> 5. **`cp↔dcp` 偏移由宿主给定**（本侧**只校不算**）—— 契约 `C4`（`P1-ls-provenance-contract.md:72`）；
> 6. **第二条回调面**（LS 28 槽／最小集 9 槽）—— `PRECOND-NEW-CALLBACK-FACE`（`P1-layout-content-criteria.md:111`）。
>
> **⇒ 判据化**：设集合 `W` ＝ {C2, C4, PRECOND-NEW-CALLBACK-FACE, PRECOND-NO-TEXT-SOURCE, PRECOND-NO-LINE-BREAKER, PRECOND-NO-TEXT-PARA-IN-CHAIN, PRECOND-LS-SESSION-DRIVER}（**7 项**；上列第 1 条＝{C2, LS-SESSION-DRIVER} 两项归并）。**当且仅当** `W` 每项在同一趟腿上有**可现取的真读数／具名留痕**（`P10`）时，"内容层那一波"＝**已落地**；否则**未开工**（今天：**7／7 项全部为"未解除"**，`T-A63` 在册）。
> **粒度**：单段落（承 `P1-ls-provenance-contract.md:100`）；**不得**由它宣布跨页/整页结论。

### 3.3 🔴 本件现取的两处**修正**（对 `T-A65` 的"等"字）

1. **`C2` 的 `ploc` 一半，本侧**已有**。** 现取：`LoCreateContext`／`LoDestroyContext` **本侧已真实现并已导出**（`win32_pts.c:4238`／`:4259`；`exports.txt` 现取含两名）⇒ 契约 C2 写的"不存在于我们的链上"**只对 `plsrun` 那一半成立**，`ploc` 那一半**是本侧自持对象**（`T-A62` 体例的自持对象）。⚠️ 但"托管在现移植里**是否真调用**本侧 `LoCreateContext`"**未测**（见 §7 `NOINFO-C2-PLOC-ON-CHAIN`）。
2. **文本分析 4 条**的真前置**不在** `W` 里。现取：这 4 条是**方法组**传入 `TextAnalyzer.Itemize`（`TypefaceMap.cs:120-123`），而 `Itemize` 在本移植＝ **`[PNSE · D 档]`**（`build/DirectWriteForwarder.Linux/ManagedSurface.cs:1116` / `:1128` `NotSupported.Throw<IList<Span>>(nameof(Itemize))`）⇒ 它依赖的是 **DWrite 脚本分段（`AnalyzeScript`）**，**不落** `W` 任意一条 ⇒ 本件为它**新立**具名前置 `PRECOND-DWRITE-SCRIPT-ANALYSIS`（§7）。

---

## §4 逐条可及性判定 ＋ 证据

> **判定口径**：**「只依赖本侧已有事实」＝ ∃ 本侧自持对象（上下文／会话／页／子轨／窗口状态…）使该入口**不需要**任何 `W` 成员即可诚实实现**（正极有真值 ∧ 反极必拒）。**凡成立则记 ✅**；否则记 ❌ 并给**真依赖**的**根对象／源**（附件:行）。

### 4.1 `Lo*` 12 条

| # | 名 | 只依赖本侧已有事实？ | 真依赖（件:行） | 证据 |
|---|---|---|---|---|
| 01 | `LoAcquireBreakRecord` | ❌ **否** | **根对象＝行**（入参 `ploline`）：唯一创造者 `LoCreateLine`（`:1419`）**本侧无源** | 现取 `win32_pts.c:4593`（`T-A62` 排除注释逐字含本条）；`P1-tail2-gapbatch2-impl-report.md:149`「其生命周期对端……**无根对象**」 |
| 02 | `LoCloneBreakRecord` | ❌ **否** | **根对象＝断行记录**（入参 `pBreakRec`）：本侧**不存在**该实体（`&p->c_paras` 那类是 PTS 页断页记录，**非** LS 记录） | `win32_pts.c:4593`（同注释）；`gapbatch2:159`「`pBreakRec` 对自有对象不存在」 |
| 03 | `LoCreateBreaks` | ❌ **否** | **断行器＋内容**：出参 `LsBreaks`（断点集＋逐断点 `LsLInfo`）＝**排版产物** | `win32_pts.c:4591-4592`；`P1-layout-content-criteria.md:113`（`PRECOND-NO-LINE-BREAKER`） |
| 04 | `LoCreateLine` | ❌ **否** | **真度量源**：出参 `LsLInfo`（22 字段全度量）＋`LsLineWidths`（7 字段）＋`maxDepth` | `win32_pts.c:4590-4591`「本侧**无测量源**，返回 0 即造「静默半通」」；`P1-layout-content-criteria.md:112`（`PRECOND-NO-TEXT-SOURCE`） |
| 05 | `LoDisplayLine` | ❌ **否** | **根对象＝行**（入参 `ploline`） | `win32_pts.c:4592` |
| 06 | `LoDisposeBreakRecord` | ❌ **否** | **根对象＝断行记录**（入参 `pBreakRec`） | `win32_pts.c:4593`；`gapbatch2:159` |
| 07 | `LoDisposeLine` | ❌ **否** | **根对象＝行**（入参 `ploline`）；其创造者 `LoCreateLine` 无源 | `win32_pts.c:4593`；`gapbatch2:158`「在册语义**以内联对象为对象**（对自有对象语义不成立）」 |
| 08 | `LoEnumLine` | ❌ **否** | **根对象＝行 ＋ 行内容/字形** | `win32_pts.c:4592`；`gapbatch2:157`「需**行内容＋字形**（`ploline` 本侧不存在）」 |
| 09 | `LoQueryLineCpPpoint` | ❌ **否** | **根对象＝行**；出参 `LsTextCell` 需**行内容** | 同上 |
| 10 | `LoQueryLinePointPcp` | ❌ **否** | **根对象＝行**；出参 `LsTextCell` 需**行内容** | 同上 |
| 11 | `LoRelievePenaltyResource` | ❌ **否** | **根对象＝行**（入参 `ploline`） | `win32_pts.c:4593`；`gapbatch2:158` |
| 12 | `LocbkGetObjectHandlerInfo` | ❌ **否** | **native 对象处理器**：`objectId < TextStore.ObjectId.MaxNative`＝`1`（`TextStore.cs:2404` 现取）⇒ 只走 native 对象 0；本侧**无 native 对象处理器** | `win32_pts.c:4594`「（native 对象处理器信息）」；`gapbatch2:160`「本侧**无 native 对象处理器**」；`TextStore.cs:2401-2404`（`enum ObjectId : ushort`…`MaxNative = 1`） |

### 4.2 文本分析 4 条

| # | 名 | 只依赖本侧已有事实？ | 真依赖（件:行） | 证据 |
|---|---|---|---|---|
| 13 | `CreateTextAnalysisSink` | ❌ **否** | **DWrite 脚本分段**：返回值＝`IDWriteTextAnalysisSink*`，须在 native 侧实现该接口供 LS 分析脚本 | `TypefaceMap.cs:120`；`ManagedSurface.cs:1116`/`:1128`（`Itemize` ＝ `[PNSE · D 档]`） |
| 14 | `CreateTextAnalysisSource` | ❌ **否** | **字符源入站**：签名**入参直接是 `char* text`＋`length`** ⇒ 必须先把内容源接进链 | `LineServices.cs:1610-1611`（现取签名）；`P1-layout-content-criteria.md:112`（`PRECOND-NO-TEXT-SOURCE`） |
| 15 | `GetScriptAnalysisList` | ❌ **否** | **DWrite 脚本分段**（同上，须先有 `CreateTextAnalysisSink` 的实体） | `TypefaceMap.cs:121`；`ManagedSurface.cs:1128` |
| 16 | `GetNumberSubstitutionList` | ❌ **否** | **DWrite 数字替换**（同上，须 sink 实体 ＋ 数字文化源 `numberCulture`） | `TypefaceMap.cs:122`；`LineServices.cs:1603-1604` |

### 4.3 计数核对（现取）

- **「只依赖本侧已有事实」** ＝ ✅ **0 条**；❌ **真依赖** ＝ **16 条**。
- **真依赖的**根/源**归并（两族，互不重叠）**：
  - **`L1`＝native LS 行引擎（含 28 槽回调面／度量源／断行器）** —— 12 条 `Lo*`（**超集**于 `W`：LS 引擎 ≫ 内容层）；
  - **`L2`＝DWrite 脚本分段 ＋ 内容源入站** —— 4 条文本分析（**不落** `W` 任意一条）。
- ⇒ **本件判词（对 `T-A65` 的丁类口径的收紧）**：丁类 16 条**没有一条真依赖 `C2`/`C4` 本身** —— ① `C2` 的 `ploc` 一半本侧**已有**（§3.3-1）；② 4 条文本分析的真依赖是 `L2`（**新立** `PRECOND-DWRITE-SCRIPT-ANALYSIS`）。丁类写作「依赖内容层那一波（`C2`/`C4` **等**）」的那个「等」**就是** `L1`／`L2`；本件把它**点名并分流**（对 `T-A65` 是**收紧**、非推翻）。
- **边界（`P9`）**：本件**不**判"内容没有源"—— `P1-layout-content-criteria.md:146` 在册「**源在宿主侧**」；本件只判"**取它要 `L1`／`L2`**"。

---

## §5 选靶：**唯一合法终点**（无诚实增量）＋ 判据草案

### 5.1 判词（写死）

> **唯一选靶 ＝ 合法终点：本波**不实施丁类 16 条中的任何一条**（`T-A62` 的"诚实拒绝优于假成功"硬边界）。** 三条理由（逐条可证伪）：
> 1. **`L1` 无源**：12 条 `Lo*` 的根对象（行／断行记录）**没有诚实创造者** —— 唯一创造者 `LoCreateLine`（`:1419`）的出参含**真几何**，本侧无测量源（§4.1）；在册已判 native LS「**不必要 ∧ 代价极高**」（`P1-tail2-hostline-recon.md` §3-乙）。
> 2. **`L2` 无源**：4 条文本分析落在 `Itemize` ＝ `[PNSE · D 档]` 之后（`ManagedSurface.cs:1128`），须 DWrite 脚本分段。
> 3. **降为"诚实拒绝 stub"不构成诚实增量**：LS 入口的错误码域是 `LsErr`（`LineServices.cs:561` 起；非 `None` 即抛，`TextFormatterContext.cs:388-395` 现取）；`-10000` **不在** `LsErr` 枚举（`P1-ls-family-recon.md:212`）⇒ 用 PTS 域的 `-10000` 冒充 LS 拒绝＝**假错误码**；且 `T-A62` 在册已判「这 11 条**保持缺口**」（`win32_pts.c:4594`）。⇒ **不导出、不 stub**。
>
> **若队长要再推进一格**：唯一候选 ＝ **把 `L1`／`L2` 写成本波可判的具名前置并登记**（体例同 `P1-layout-content-criteria.md:134` 的"合法且真实的推进"）；**非** native 写域可做（须队长裁定另开波）。
> **"不算推进"清单（写死）**：① 用 `-10000`／常量把 12 `Lo*` 导成 stub；② 用"零值填充"让 `LoCreateLine`／`LoCreateBreaks` 返 0；③ 用"两样本一致"证 `LoEnumLine`／`LoQueryLine*` 可及（`P8` 恒真族）；④ 把 `C2` 的 `ploc` 已有**外推**成"LS 会话已在链上"。

### 5.2 判据草案（**若**某波实施其中 k 条，用这 5 条当契约；含「`ops` 下降须与实施条数一致」）

| # | 判据（可证伪） | 反极性（必红腿） |
|---|---|---|
| **D1 台账守恒（`ops` 下降须与实施条数一致）** | 设实施 k 条（0≤k≤16）⇒ `tool` 下降**恰 k** ∧ `ops` 下降**恰 k**（`ops = tool − dead − artifact`，`dead`／`artifact` 不动）∧ `impl` 变化**恰 k**（无新 stub）∧ `exports.txt` 行数**增恰 k**（每名一条，逐名 `diff`）∧ `nm==exports`。`PTSGAP` 逐字段现算。 | 实施 k 条但 `ops` 只掉 ≥1 而 ≠k（或 `exports` 行数与 `tool` 差 ≠k）⇒ **必红**（台账与实施面脱钩）。 |
| **D2 根对象诚实性（12 `Lo*` 的前置）** | "生命周期/查询"类（01/02/05/06/07/08/09/10/11）**只有**在其入参根对象由本侧**诚实创造者**产出且可**身份认领**时才得实现；**正极**：`LoCreateLine` 回 `pploline≠NULL` 且该值可认领（同 `wpf_pts_lsps_find` 体例）；**反极**：`NULL`／外来 `ploline`／已失效值 ⇒ 返 **`LsErr` 非 `None`** 且**出参一字不写**。 | 对未知/外来 `ploline` 返 `LsErr.None`（伪成功）或返 `-10000`（域外码）⇒ **必红**。 |
| **D3 几何真值禁冒充（04/03 的前置）** | `LoCreateLine` 的 `LsLInfo`／`LsLineWidths`／`maxDepth` 与 `LoCreateBreaks` 的 `LsBreaks`／`bestFitIndex` 必须来自**本侧真度量 ∧ 真断行**；**正极**：逐字段可现取 ∧ **≥2 独立样本非空且同判**；**反极**：任一字段为常量或零值填充 ⇒ **必红**（"静默半通"，红 `P3`）。 | `rc=0` ＋ 常量/估算值 ⇒ **必红**（`P1-layout-content-criteria.md:124` 伪造风险）。 |
| **D4 错误码域守恒** | 任何 `Lo*` 拒绝必须落在 **`LsErr` 枚举**（`LineServices.cs:561` 起）；`-10000`（`tserrNotImplemented`，PTS 域）**不得**用于 LS 入口。 | 用 `-10000` 冒充 LS 拒绝 ⇒ **必红**（假错误码，会让 `ThrowExceptionFromLsError` 走错分支）。 |
| **D5 文本分析 4 条的前置（`L2`）** | `CreateTextAnalysisSource` 的**入参 `char* text` 须真来自内容源入站**；`GetScriptAnalysisList`／`GetNumberSubstitutionList` 的**出参须由真 `sink` 实体产出**；**正极**：`Itemize` 不再走 `[PNSE · D 档]`（`ManagedSurface.cs:1128` 现取不再命中）；**反极**：不接内容源而直接返回 sink/source 指针 ⇒ **必红**（假句柄，`D-G76` 同形）。 | 返 `IntPtr` 非空但内容源为零/常量 ⇒ **必红**。 |
| **反极性统一（承 `T-A63`）** | 每条实入口配「**拆接线反腿闸**」（缺省**开**）；闸关 ⇒ 具名 `reason=…(reverse-leg)`＋出参一字不写＋对应门**必红**（`PTS_GUARD=FAIL`／`PTS_COLORANCHOR=FAIL`）。 | 闸关后门仍 `PASS` ⇒ **必红**（该来源不承重 ⇒ 实现无意义）。 |

---

## §6 与 `T-A62` 边界的关系（收紧/沿用，非推翻）

- **沿用**：`T-A62` 的"诚实准入铁律"＝只收**自持对象**（上下文／段断行会话／罚分模块）的**生命周期与状态搬运**；本件现取复核其排除注释 `win32_pts.c:4585-4595` **逐条相符**（11 条保持缺口 ＝ 本件 §4.1 的 12 条去掉 `LoCreateBreaks`，后者在 `T-A62` 表内亦被列）。
- **收紧**：`T-A65` 把丁类记作"依赖内容层那一波（`TASK-0307` 的 `C2`/`C4` 等）"；本件**点名**那个"等"＝ `L1`（native LS 行引擎）／`L2`（DWrite 脚本分段），并**分流**（12 vs 4），逐条给根对象/源。
- **不推翻**：丁类仍是 16 条、仍**全部保持缺口**；本件**不**授权任何判据放宽。

---

## §7 具名 `NOINFO`（逐条给"消掉条件"）

1. **`NOINFO-DING-DEP-SCOPE`** —— 「内容层那一波」**不是一件在册器件**（`grep -rn '内容层那一波'` 现取：只落在 `P1-ls-provenance-contract.md:3/80/81`、`P1-ls-provenance-recon.md:99`、`P1-layout-content-criteria.md`（本体）、`P1-tail2-gapgrade-recon.md:41/157/185`、`P1-tail2-t0307-recon.md`、`docs/ROUTES.md:356` 等**叙述行**里），本席**未**在现盘取到"那一波"的**器件/判据本体**（因其未开工）。**消掉条件**：那一波开工并落一件可现取的载体。
2. **`NOINFO-LO-LINE-ROOT-CREATOR`** —— 本席只核了 `LoCreateLine`／`LoCreateBreaks` 两条**真机**行/断点创造者；**未**穷举全仓（native ＋ 托管）是否存在**第 3 条**本侧可持的行/断行记录创造路径。**消掉条件**：全仓 ＋ native 侧给出另一条行对象创造者（含其度量源）。
3. **`NOINFO-TEXTANALYSIS-PRECOND-NAME`** —— 4 条文本分析的具名前置由**本件新立** `PRECOND-DWRITE-SCRIPT-ANALYSIS`，但**未**在裁定/缺口册登记（本件只读，**不改册**）。**消掉条件**：队长出裁定并登记入册。
4. **`NOINFO-DING-CALLSITE-REACHABILITY`** —— §2 的"调用点"是**静态文本命中**；本移植里 LS 链已被 shim 取代（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:692/723`，引自 `P1-tail2-hostline-recon.md` §1.4，**未独立复算**）⇒ 这 16 条在**现产品路径**上"是否必不被走到"**本席未实测**。**消掉条件**：一条真装置腿 ＋ 逐入口 `entry=` 留痕。
5. **`NOINFO-C2-PLOC-ON-CHAIN`** —— 本侧**已有** `ploc`（`LoCreateContext` 真实现／已导出，`win32_pts.c:4238`），但**未**现取"托管 `TextFormatterContext.cs:113` 在现移植里**是否真调用**本侧 `LoCreateContext`"（`P1-ls-family-recon.md` §2.3 判链在 `LoSetDoc` 掐断；`T-A62`／`T-A66` 后是否推进**未测**）。**消掉条件**：一条腿的 `[LS…]` 计数。

---

## §8 纪律与验收

- 🔴 **只读**：唯一写入 ＝ 本件；`src/**`／`build/**`（除本件）／`build/MilBridge/tools/**`／`upstream/**` **一律未改**；**未构建**；**未跑整趟 `verify-all`**；进程只按 PID；**禁 `sleep` 轮询**；大件只用 `wc`/`head`/`tail`/`grep`。
- 🔴 **`P9`**：不把"本侧某面找不到源"读成"内容没有源" —— 源在**宿主侧**（`P1-layout-content-criteria.md:146` 在册）；本件只判"取它要 `L1`／`L2`"。
- 🔴 **`P10`**：每条否定附**射程**（件＋行号＋现取命令）；本件 16 条来自**一条可复跑命令**（`check-shim-coverage.py --tier all`）＋ `grep` 逐名核对。
- 🔴 **恒真断言族**：本件读数**全部来自读取**（`grep`/`awk`/`wc`/`sha256sum`/`check-shim-coverage.py`），**未**使用"两样本一致"类证据。
- **验收**：新件、`mode 644`、首记号 `# P1-tail2 · T-A67 `、末行自证并当场复算 MATCH。

`P1-tail2-dingrecon 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 2bb9287879f20f61（末行＝本行）`

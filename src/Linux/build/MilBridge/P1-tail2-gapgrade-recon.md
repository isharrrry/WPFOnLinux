# P1-tail2 · T-A65 · `ops=47` 缺口可实施性分级（只读侦察）—— `TASK-0302`

> **只读**：除本件外**未改任何仓内文件**；**未构建**；**未跑整趟 `verify-all`**；**未占显示位**；进程只按 PID；**禁 `sleep` 轮询**；大件只用 `wc`／`head`／`tail`／`grep`；**未 `git add/commit/push`**。行号一律整行取（`sed -n`／`grep -n`），只本次有效（内容锚原文一并给出）。

---

## §0 在飞件与代际

- **载体**：`build/MilBridge/P1-tail2-gapgrade-recon.md`（**新建**，`temp+rename`，`mode 644`）。读取时刻：**2026-10-01 20:0x–20:1x+0800**；`HEAD=a433cdd`。
- **现取件代**（`sha256` 前 16 位，本席现取）：
  - `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`969536ee1549ef39`**／**490296 B**（＝在册声明件 `pts-gap-decl.txt` 的 `so16`，逐位相符）
  - `src/WpfGfx.Linux.Native/bin/exports.txt` ＝ **`20b6d9aa3125bbc4`**／**718 行**（＝声明件 `exports=718`）
  - `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`c80a03e9633641a7`**／9097 行
  - `upstream/…/PtsHost/Pts.cs` ＝ **`1a8575a18767a956`**／3913 行
  - `upstream/…/TextFormatting/LineServices.cs` ＝ **`8b2bc2167f5c0bd3`**／1620 行
  - `upstream/…/Shared/MS/Win32/NativeMethodsSetLastError.cs` ＝ **`ddaaa53b535492f0`**／163 行
- **在册声明行（现取，`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt:34`）**：`# PTSGAP-DECL: tool=59 dead=11 artifact=1 ops=47 impl=47 so16=969536ee1549ef39 exports=718 w66pre16=bf6b683d94549087`。
- **判据来源**（本席只读，**未独立复算其内部读数**）：`build/MilBridge/P1-tail2-gapbatch1-impl-report.md`（`T-A61` 的「诚实准入铁律」）、`P1-tail2-gapbatch2-impl-report.md`（`T-A62` 的 `Lo*`/`Nl*` 划界）、`P1-tail2-lsprov-impl-report.md`（`T-A63` 的 `C2`/`C4`）、`P1-ls-family-recon.md`、`P1-tail2-hostline-recon.md`、`build/MilBridge/tools/nl-intent-check.sh`、`docs/unimplemented.md` §2.7。

---

## §1 取数口径：47 条的**来源**（可复跑）

```bash
python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier all > /tmp/raw.txt
awk '$1=="PresentationNative_cor3.dll"{print $2}' /tmp/raw.txt | LC_ALL=C sort > /tmp/gap.txt   # ⇒ 59
```

- **现取**：`[PresentationNative_cor3.dll]` 段 **`tool=59`**（本席 `wc -l /tmp/gap.txt` ＝ 59）。
- **`dead=11`**（本席**用判据件 `pts-gap-count-check.sh:131-142` 的同一段 `python3` 现算**）：`FsDuplicatePageBreakRecord`／`FsGetEmptySpaces`／`FsGetMaxNumberEmptySpaces`／`FsGetNextTick`／`FsQueryDcpLineVariantsFromCachedTextPara`／`FsQueryHeightDefinedColumnSpanAreaList`／`FsQuerySegmentDefinedColumnSpanAreaList`／`FsQuerySubpageHeightDefinedColumnSpanAreaList`／`FsQuerySubpageSegmentDefinedColumnSpanAreaList`／`FsRegisterFloatObstacle`／`FsSetDebugFlags`（＝`Pts.cs` 的 `#if NEVER` 区间成员 ∩ 缺口名，计数现取 **11**）。
- **`artifact=1`**：`*Wrapper` 尾名 ∧ 其 `EntryPoint` 逐字已在 `exports.txt` ⇒ 现取 **`FindWindowExWrapper`**（`exports.txt:98` 有该名；其探测首候选 `FindWindowExWrapperW` 缺席 ⇒ 工具计入缺口，判据件判为误报）。
- ⇒ **`ops = 59 − 11 − 1 = 47`**，与派单所写 `ops=47` **逐值相符**。
- ⚠️ **口径不符一处（如实记）**：派单括注「`70` 原始 − 11 死 − 1 误报 − 已实现 11」中的 **`70`** 与现取 `tool=59` **不是同一代**（现取工具口径就是 59）；见 §7 `NOINFO-GAPGRADE-CALIBER`。**本件的 47 条一律按现取 `tool=59 − dead=11 − artifact=1` 得出**，不按 `70` 反推。

**族分解（现取，可复算）**：`Fs*` **21** ＋ `Lo*` **12** ＋ `Nl*` **6** ＋ 文本分析 **4** ＋ `*Wrapper` **4** ＝ **47**（与 `P1-tail2-gapbatch1-impl-report.md` §6 的族名逐字相符）。

---

## §2 47 条逐条分级（名／声明件:行／出参形态／本侧测量源／判定／一句理由）

> **判定口径（照派单逐字）**：**甲**＝可诚实实施（明确语义 ∧ 出参可由本侧既有事实推出 ∧ 无外部源依赖）；**乙**＝需原生源（出参含真几何/真测量，本侧无源）；**丙**＝在册有意降级；**丁**＝依赖内容层那一波（`TASK-0307` 的 `C2`/`C4` 等）。**本侧测量源**一律现取（`win32_pts.c` 件:行）。

| # | 名 | 声明 件:行 | 出参形态 | 本侧测量源 | 判定 | 一句理由 |
|---|---|---|---|---|---|---|
| 01 | `CreateTextAnalysisSink` | `LineServices.cs:1589` | 返回 `IDWriteTextAnalysisSink*` | 无 | **丁** | LS/文本分析族（`TextAnalyzer.Itemize` 4 委托之一）；须内容层那一波 |
| 02 | `CreateTextAnalysisSource` | `LineServices.cs:1609` | `int` ＋ `void** ppTextAnalysisSource` | 无 | **丁** | 同上（脚本分析源） |
| 03 | `FsCreateSubpageBottomless` | `Pts.cs:3201` | `out FSFMTRBL`／`ppSubPage`／`dvrUsed`／`FSBBOX`／`topSpace` | 无 | **乙** | 出参含真几何（`dvrUsed`/`bbox`/`topSpace`） |
| 04 | `FsDestroyPageBreakRecord` | `Pts.cs:3159` | **无出参** | **有**：断页记录句柄＝本侧页对象字段地址（`win32_pts.c:7267`） | **甲** | 无出参；句柄可按对象身份认领后失效 |
| 05 | `FsDestroySubpageBreakRecord` | `Pts.cs:3278` | **无出参** | **无**：本侧子页不出断页记录（`win32_pts.c:6670` `*ppBRSubPageOut=NULL`） | **乙** | 无根对象（本侧不产子页断页记录） |
| 06 | `FsDestroySubtrackBreakRecord` | `Pts.cs:3422` | **无出参** | **无**：本侧无子轨断行记录（`FsFormatSubtrack*` 未实现） | **乙** | 同上（无根对象） |
| 07 | `FsDuplicateSubpageBreakRecord` | `Pts.cs:3272` | `out ppBreakRecSubPageOut` | 无 | **乙** | 需复制**真断页记录内容**（本侧只有字段地址） |
| 08 | `FsDuplicateSubtrackBreakRecord` | `Pts.cs:3416` | `out ppfsBRSubtrackOut` | 无 | **乙** | 同上 |
| 09 | `FsFormatSubtrackBottomless` | `Pts.cs:3343` | `out FSFMTRBL`／`ppfsSubtrack`／`dvrUsed`／`FSBBOX`／`topSpace` | 无 | **乙** | 真几何＋造型（排版）语义 |
| 10 | `FsFormatSubtrackFinite` | `Pts.cs:3317` | `out FSFMTR`／`ppfsSubtrack`／`brk`／`dvrUsed`／`FSBBOX`／`topSpace` | 无 | **乙** | 同上 |
| 11 | `FsGetNumberSubpageFootnotes` | `Pts.cs:3292` | `out int cFootnotes` | **无**（本侧无脚注模型；`FSIMETHODS` 槽 13 **不 deref**，`win32_pts.c:2106`/`:3603`） | **乙** | 计数须**真脚注模型**（返 0 对含脚注文档＝静默假值） |
| 12 | `FsGetNumberSubtrackFootnotes` | `Pts.cs:3436` | `out int cFootnotes` | **无**（同上） | **乙** | 同上 |
| 13 | `FsGetSubpageColumnBalancingInfo` | `Pts.cs:3283` | `out uint fswdir`／`lLineNumber`／`lLineHeights`／`lMinimumLineHeight` | **有**：本侧**真行台账** `fl_line[]`（`T-A28`，`pfnFormatLine` 真返回值入账） | **甲** | 出参可由**内容子树行台账递归汇总**（`T-A61` 载体 §6 指名） |
| 14 | `FsGetSubpageFootnoteInfo` | `Pts.cs:3298` | `out uint fswdir`／`FSFTNINFO[]`／`indexLim` | 无 | **乙** | `FSFTNINFO{nmftn,vrAccept,vrReject}` ＝脚注**位置**（真几何） |
| 15 | `FsQueryPageSectionList` | `Pts.cs:3619` | `out FSSECTIONDESCRIPTION[]`／`cActualSize` | 无 | **乙** | 数组含 `fsrc`／`fsbbox` |
| 16 | `FsQuerySectionBasicColumnList` | `Pts.cs:3633` | `out FSTRACKDESCRIPTION[]`／`cActualSize` | 无 | **乙** | `FSTRACKDESCRIPTION` 含 `fsrc`／`fsbbox`／`pfstrack` |
| 17 | `FsQuerySectionDetails` | `Pts.cs:3627` | `out FSSECTIONDETAILS` | 无 | **乙** | 含 `fsrcSectionBody`／`fsbboxSectionBody`（真几何） |
| 18 | `FsQuerySubpageBasicColumnList` | `Pts.cs:3709` | `out FSTRACKDESCRIPTION[]`／`cActualSize` | 无 | **乙** | 同 16 |
| 19 | `FsTransformBbox` | `Pts.cs:3894` | `out FSBBOX bboxOut` | 无（变换约定无上游参考实现） | **乙** | 真几何输出；`fswdir` 变换语义**无源** |
| 20 | `FsTransformRectangle` | `Pts.cs:3886` | `out FSRECT rectOut` | 无（同上） | **乙** | 同上 |
| 21 | `FsUpdateBottomlessSubpage` | `Pts.cs:3228` | `out FSFMTRBL`／`dvrUsed`／`FSBBOX`／`topSpace`／`fPageBecomesUninterruptible` | 无 | **乙** | 真几何 |
| 22 | `FsUpdateBottomlessSubtrack` | `Pts.cs:3366` | `out FSFMTRBL`／`dvrUsed`／`FSBBOX`／`topSpace`／`fCanBeInterruptedOut` | 无 | **乙** | 真几何 |
| 23 | `FsUpdateFinitePage` | `Pts.cs:3118` | `out FSFMTR`／`ppfsBRPageOut` | **有**：本侧页对象 `wpf_pts_fsp` ＋字段地址（`win32_pts.c:7266-7267`） | **甲** | 无真几何；承 `FsUpdateBottomlessPage`（`T-A19`）同形先例 |
| 24 | `GetMenuBarInfoWrapper` | `NativeMethodsSetLastError.cs:51` | `out MENUBARINFO mbi` | 无 | **乙** | 真菜单栏几何；⚠️ **非编译分支**（见 §4-W） |
| 25 | `GetNumberSubstitutionList` | `LineServices.cs:1603` | 返回列表对象 | 无 | **丁** | LS/文本分析族 |
| 26 | `GetScriptAnalysisList` | `LineServices.cs:1596` | 返回列表对象 | 无 | **丁** | 同上 |
| 27 | `GetTextExtentPoint32Wrapper` | `NativeMethodsSetLastError.cs:74` | `out SIZE lpSize` | 无 | **乙** | 真文本测量；⚠️ 非编译分支 |
| 28 | `GlobalDeleteAtomWrapper` | `NativeMethodsSetLastError.cs:46` | 返回 `short`（atom） | 无常量源（本侧类原子表语义实体不同，`win32_core.c:341`） | **甲** | 纯**原子表状态**操作（无几何/测量）；⚠️ 非编译分支 |
| 29 | `NlCreateHyphenator` | `NaturalLanguageHyphenator.cs:208` | 返回句柄 | 无 | **丙** | 在册**有意降级** |
| 30 | `NlDestroyHyphenator` | `NaturalLanguageHyphenator.cs:211` | 无出参 | 无 | **丙** | 同上 |
| 31 | `NlGetClassObject` | `NLGSpellerInterop.cs:1064` | 返回对象 | 无 | **丙** | 同上 |
| 32 | `NlHyphenate` | `NaturalLanguageHyphenator.cs:214` | 返回码 | 无 | **丙** | 同上 |
| 33 | `NlLoad` | `NLGSpellerInterop.cs:1058` | 返回码 | 无 | **丙** | 同上 |
| 34 | `NlUnload` | `NLGSpellerInterop.cs:1061` | 无出参 | 无 | **丙** | 同上 |
| 35 | `LoAcquireBreakRecord` | `LineServices.cs:1440` | `out pbreakrec` | 无 | **丁** | LS 族（须 LS 会话 `C2`） |
| 36 | `LoCloneBreakRecord` | `LineServices.cs:1453` | `out pBreakRecClone` | 无 | **丁** | 同上 |
| 37 | `LoCreateBreaks` | `LineServices.cs:1522` | `out bestFitIndex`（＋`ref LsBreaks`） | 无 | **丁** | 同上（需行断器） |
| 38 | `LoCreateLine` | `LineServices.cs:1419` | `out LsLInfo`／`pploline`／`maxDepth`／`LsLineWidths` | 无 | **丁** | 同上（真几何＋行内容） |
| 39 | `LoDisplayLine` | `LineServices.cs:1486` | 返回码 | 无 | **丁** | 同上 |
| 40 | `LoDisposeBreakRecord` | `LineServices.cs:1446` | 无出参 | 无 | **丁** | 同上（无根对象） |
| 41 | `LoDisposeLine` | `LineServices.cs:1433` | 无出参 | 无 | **丁** | 同上 |
| 42 | `LoEnumLine` | `LineServices.cs:1494` | 返回码 | 无 | **丁** | 同上（需行内容＋字形） |
| 43 | `LoQueryLineCpPpoint` | `LineServices.cs:1502` | `out actualDepthQuery`／`LsTextCell` | 无 | **丁** | 同上 |
| 44 | `LoQueryLinePointPcp` | `LineServices.cs:1512` | `out actualDepthQuery`／`LsTextCell` | 无 | **丁** | 同上 |
| 45 | `LoRelievePenaltyResource` | `LineServices.cs:1459` | 返回码 | 无 | **丁** | 同上 |
| 46 | `LocbkGetObjectHandlerInfo` | `LineServices.cs:1551` | `void* objectInfo` | 无 | **丁** | 同上（本侧无 native 对象处理器） |
| 47 | `SetScrollPosWrapper` | `NativeMethodsSetLastError.cs:89` | 返回旧位置 `int` | **有**：本侧窗口模型（可持滚动位） | **甲** | 纯**状态存取**（无几何/测量）；⚠️ 非编译分支 |

**计数核对（现取）**：甲 **5**（`FsDestroyPageBreakRecord`／`FsGetSubpageColumnBalancingInfo`／`FsUpdateFinitePage`／`GlobalDeleteAtomWrapper`／`SetScrollPosWrapper`）｜乙 **20**｜丙 **6**｜丁 **16**（`Lo*` 12 ＋ 文本分析 4）⇒ **合计 47** ✔

---

## §3 甲类清单（**按实施代价排序**：低 → 中）＋ 语义出处与判据草案

> **准入铁律（逐字承 `T-A61`）**：本侧**只**是**自持对象**（页／子页／子轨／窗口状态）的作者；只收**无真几何出参**、或出参**可由本侧真台账/自持状态推出**者。**凡出参含真几何而无源者一律不冒充**（`win32_pts.c:8334-8336` 在册）。

### 甲-1 `FsDestroyPageBreakRecord`（**代价：低**）
- **语义出处**：声明 `Pts.cs:3159-3162`（`(IntPtr pfscontext, IntPtr pfsbreakrec)`，**无出参**）；唯一调用点 **`PtsContext.cs:85`**（`PTS.Validate(PTS.FsDestroyPageBreakRecord(_ptsHost.Context, (IntPtr)_pageBreakRecords[index]))`）／**`PtsContext.cs:524`**。
- **本侧既有事实**：断页记录句柄 ＝ 本侧页对象**字段地址**（`win32_pts.c:7267` `*ppfsBRPageOut = (void *)&p->c_paras;`，**已导出**的 `FsCreatePageFinite` 产出）⇒ 可按**指针等值于在册对象的该字段地址**认领（同族先例：`wpf_pts_sub_claim`／`wpf_pts_sp_claim_track`）。
- **判据草案**：① **正极**：`FsCreatePageFinite` 后取回 `brk` ⇒ `FsDestroyPageBreakRecord(ctx, brk)==0` ⇒ 该值**不再可认领**（二次调用必拒）；② **反极必红**：`NULL`／`0xDEAD`／外来页对象字段址 ⇒ 返 `-10000` ＋ 具名 `[FS_PAGE_GAP] reason=null-breakrec/unknown-breakrec` ＋ **出参无**（本入口无出参 ⇒ 纪律落在"状态真被失效"可现取）；③ **不冒充**：**不**声称"释放了真断页记录内存"（本侧无该实体）。

### 甲-2 `SetScrollPosWrapper`（**代价：低**）
- **语义出处**：声明 `NativeMethodsSetLastError.cs:89-90`（`EntryPoint="SetScrollPosWrapper"`，`(IntPtr hWnd,int nBar,int nPos,bool bRedraw)`，**返回旧位置**）。⚠️ 该声明在**非编译分支**（见 §4-W）。
- **本侧既有事实**：本侧**有窗口模型**（`win32_core.c`）；Wrapper 族在本仓**既有实现范式**＝`XxxWrapper` 调裸名 `Xxx` ＋ `wpf_set_last_error(0)`（`win32_core.c:1461-1464`／`:1582-1585` 现取）。
- **判据草案**：① **正极**：同一 `hwnd` 连调两次，第二次**返回第一次设的值**（旧位置可现取）；`bRedraw` 本侧无重绘面 ⇒ 具名 `NOINFO-WRAPPER-REDRAW`；② **反极必红**：未知 `hwnd` ⇒ 返 0 并 `SetLastError` 非零（**不**静默成功）；③ **边界**：只主张"位置状态存取"，**不**主张滚动条视觉。

### 甲-3 `GlobalDeleteAtomWrapper`（**代价：低-中**）
- **语义出处**：声明 `NativeMethodsSetLastError.cs:46-47`（`ExactSpelling=true`，`(short atom)→short`）。⚠️ 非编译分支。
- **本侧既有事实**：本侧**有原子表实体**但语义不同（`win32_core.c:341 wpf_class_find_atom` ＝**窗口类原子**，`ATOM` 从 `0xC000` 起，`win32_core.c:62`）⇒ ❌ **不得**把类原子表当 Win32 全局原子表映射（否则是假映射）。
- **判据草案**：① 需**新立**一张**进程内全局原子表**（语义明确、无外部源依赖）；② **正极**：`GlobalAddAtom`（若同批补）后的 atom ⇒ `GlobalDeleteAtom` 返该 atom ∧ 再删 ⇒ 0；③ **反极必红**：不存在/非法 atom ⇒ 返 0 ∧ `SetLastError=ERROR_INVALID_HANDLE`（**不**静默成功）；④ **划界**：**不**与类原子表共用命名空间（具名 `NOINFO-ATOM-NAMESPACE`）。

### 甲-4 `FsUpdateFinitePage`（**代价：低-中**）
- **语义出处**：声明 `Pts.cs:3118-3125`（`out FSFMTR pfsfmtrOut` ＋ `out IntPtr ppfsBRPageOut`）；唯一调用点 **`PtsPage.cs:457`**（`PTS.FsUpdateFinitePage(PtsContext.Context, _ptsPage, brIn, …)`）。
- **本侧既有事实**：本侧页对象 `wpf_pts_fsp`（真造／可认领）＋ `p->result` 自持位；`FSFMTR` ＝ `{kstop,fContainsItemThatStoppedBeforeFootnote,fForcedProgress}`（`Pts.cs:1141-1146`，**无几何**）；断页记录＝页字段址（同甲-1）。
- **判据草案**：① **正极**：认领在册页 ⇒ `rc=0` ∧ `pfsfmtrOut` 取本页自持 `result`（失败面先写"未达成"）∧ `ppfsBRPageOut` ＝本页字段址（**非 NULL、可身份校验**，与 `FsCreatePageFinite` 同源）；② **反极必红**：未知页/未知 ctx/NULL 出参 ⇒ 返 `-10000` ＋ `[FS_PAGE_GAP]` ＋ **出参一字不写**；③ **不冒充**：**不**声称"页被重新排版"（本侧无排版引擎）；④ **零回归**：与 `T-A19` 同口径（缺省路径两页帧逐字节不变）。

### 甲-5 `FsGetSubpageColumnBalancingInfo`（**代价：中**）
- **语义出处**：声明 `Pts.cs:3283-3290`（`out uint fswdir`／`out int lLineNumber`／`out int lLineHeights`／`out int lMinimumLineHeight`）；调用点 **`PtsHost.cs:2521`**（Float 内容）／**`PtsHost.cs:3213`**（Subpage）。
- **本侧既有事实**：本侧**真行台账** `fl_line[]`（`T-A28`，`pfnFormatLine` **真返回值**入账）；**同族已实现** `FsGetSubtrackColumnBalancingInfo`（`T-A61` ①，出参＝`fl_nlines`／`Σ(dvrAscent+dvrDescent)`／`min(…)`）⇒ 子页支＝**对内容子树递归汇总**（`T-A61` §6 逐字指名）。
- **判据草案**：① **正极**：`nlines`／`dvrSumHeight`／`dvrMinHeight` 由内容子树行台账**真汇总**且 `fswdir` 取自本侧页方向位；② **反极必红**：无台账（`wpf_pts_fl_usable` 不成立）⇒ **拒**（出参**先清 0**）；未知/`NULL` 对象 ⇒ `-10000`；`NULL` 出参 ⇒ `-10000`；③ **与既有件对账**：与 `FsGetSubtrackColumnBalancingInfo` **同谓词**（台账可用性判据一字不改）；④ **零假值**：**不**用模型常量（`seg_h=16` 类）冒充行高。

---

## §4 乙类理由（逐条）—— 20 条

### 4-A `Fs*` 真几何/无根对象（18 条）
- **03 `FsCreateSubpageBottomless`**（`Pts.cs:3201`，调用点 `SubpageParagraph.cs:376`／`FloaterParagraph.cs:750`）：出参 `dvrUsed`／`FSBBOX`／`topSpace`／`fPageBecomesUninterruptible` ⇒ **真几何**（本侧无布局引擎，`docs/unimplemented.md` §2.7：「没有可移植的源」）。
- **05 `FsDestroySubpageBreakRecord`**／**06 `FsDestroySubtrackBreakRecord`**：**无根对象** —— 本侧 `FsCreateSubpageFinite` 的 `*ppBRSubPageOut` **恒 NULL**（`win32_pts.c:6670`），`FsFormatSubtrack*` 未实现 ⇒ 本侧**不存在**子页/子轨断页记录实体（**区别于**甲-1 的页断页记录，后者＝页字段址且**真被返回**）。
- **07/08 `FsDuplicate*BreakRecord`**（`Pts.cs:3272`/`:3416`）：出参是**断页记录的副本** ⇒ 需真记录**内容**；本侧"记录"只是字段地址，复制它＝伪造。
- **09/10 `FsFormatSubtrack*`**（`Pts.cs:3343`/`:3317`）：出参含 `dvrUsed`／`FSBBOX`／`topSpace` ＋**造型（排版）语义** ⇒ 本侧无造型源。
- **11/12 `FsGetNumber*Footnotes`**（`Pts.cs:3292`/`:3436`）：出参虽是 `int`，但**脚注计数须真脚注模型**；本侧无脚注模型，且 `FSIMETHODS` 槽 13 `pfnGetNumberFootnotes`（`win32_pts.c:2106`）本侧**从不 deref**（`:3603` 具名 `NOINFO-FSIMETHODS-ABI`）⇒ **返 0 对含脚注文档＝静默假值**（本仓最忌形态）⇒ 不冒充。
- **14 `FsGetSubpageFootnoteInfo`**（`Pts.cs:3298`）：`FSFTNINFO{nmftn,vrAccept,vrReject}` ＝脚注**位置** ⇒ 真几何。
- **15/16/17/18 `FsQuery*List`／`FsQuerySectionDetails`**：出参结构体含 `fsrc`／`fsbbox`（`FSSECTIONDESCRIPTION`／`FSTRACKDESCRIPTION`／`FSSECTIONDETAILS`，`Pts.cs:1626-1650` 现取）⇒ 真几何。
- **19/20 `FsTransform*`**（`Pts.cs:3894`/`:3886`）：出参是真几何；且本仓现取「**这些符号没有上游 C++ 实现**」（`docs/unimplemented.md:558-560`）⇒ `fswdir` 变换**语义无源**，不能诚实复现。
- **21/22 `FsUpdateBottomless*`**（`Pts.cs:3228`/`:3366`）：同上（真几何）。

### 4-W `*Wrapper` 真测量（2 条）＋**重大结构发现**
- **24 `GetMenuBarInfoWrapper`**（`:51`，出参 `MENUBARINFO` 含菜单栏矩形）／**27 `GetTextExtentPoint32Wrapper`**（`:74`，出参 `SIZE` 文本范围）⇒ **真几何/真测量**，本侧无源 ⇒ **乙**。
- 🔴 **重大结构发现（本件核心之一）**：这 4 条 `*Wrapper` **全部**落在 `NativeMethodsSetLastError.cs` 的 **`#elif UIAUTOMATIONCLIENT || UIAUTOMATIONCLIENTSIDEPROVIDERS`** 分支内（分支界：`:38`／`:93`；逐条位：`GlobalDeleteAtomWrapper:46`／`GetMenuBarInfoWrapper:51`／`GetTextExtentPoint32Wrapper:74`／`SetScrollPosWrapper:89`）。而**本仓只汇 `WindowsBase`／`PresentationCore`／`PresentationFramework` 三个程序集**，这三个 csproj **均未定义** `UIAUTOMATIONCLIENT`（本席现取：`grep -rln UIAUTOMATIONCLIENT build/ upstream/…/src/` ⇒ 仅 `UIAutomation/**` 四个 csproj ＋ 本声明件；`DefineConstants` 含 `WINDOWSFORMSINTEGRATION` 的只有 `WindowsFormsIntegration.csproj`）⇒ 该分支**永不编译**。**后果**：`check-shim-coverage.py` 不求值预处理（件头自述）⇒ 这 4 条被当成"活缺口"计入 `tool`，**但托管侧没有任何调用方**。**具名** `NOINFO-WRAPPER-UNCOMPILED`（§7）。

---

## §5 丙类理由（逐条）—— 6 条

- **29 `NlCreateHyphenator`**（`NaturalLanguageHyphenator.cs:208`）／**30 `NlDestroyHyphenator`**（`:211`）／**32 `NlHyphenate`**（`:214`）／**31 `NlGetClassObject`**（`NLGSpellerInterop.cs:1064`）／**33 `NlLoad`**（`:1058`）／**34 `NlUnload`**（`:1061`）：**在册有意降级**。
- **判据（在册，逐字）**：`build/MilBridge/tools/nl-intent-check.sh:12-15` 段①「6 个 `Nl*` … 在 `.so` 里**一个都不许有**。今天为真（能力 = 0）；若哪天有人导出/实现它们 ⇒ 本段**必红**」；`:264-265` `NL_INTENT_RESULT=FAIL reason=implemented`。另有 `D-G76`：`NlCreateHyphenator` 返 `IntPtr`，返 `-10000`＝**假句柄** ⇒ 守卫当场失效（`P1-tail2-gapbatch2-impl-report.md` §5-5 现取）。
- ⇒ **本侧不得实现**（`Nl*` 6 名**不许导出**）；若要翻，须**同趟**重测行为 ＋ 更新在册声明 ＋ 处置 `nl-intent-check.sh` 段①（该件在实现任务黑名单内）。

---

## §6 丁类理由（逐条）—— 16 条（`Lo*` 12 ＋ 文本分析 4）

**共同判据（在册，逐字）**：`build/MilBridge/P1-ls-provenance-contract.md` §责任方表 `C2`＝**LS 会话标识**（`plsrun` 起点或 `LoCreateContext` 的 `ploc`）「❌ **不存在于我们的链上**……**须新立**」／`C4`＝**`cp↔dcp` 偏移**「❌ 不存在…**须新立**」；`T-A63` 现取判词：「`PRECOND-LS-PROVENANCE-BRIDGE` 的 C2（LS 会话标识）／C4（`cp↔dcp` 偏移）**今天不存在、须"内容层那一波"新立**（本侧**不得**自算 `dcp`/`plsrun`）」。⇒ **这 16 条全部落在 LS 会话/内容层那条链上**，须**先有 LS 会话 ＋ 文本段落进链**（`P1-layout-content-criteria.md`：四条具名前置 `PRECOND-NEW-CALLBACK-FACE`／`PRECOND-NO-TEXT-SOURCE`／`PRECOND-NO-LINE-BREAKER`／`PRECOND-NO-TEXT-PARA-IN-CHAIN`）。

- **35–46 `Lo*` 12 条**（`LoAcquireBreakRecord` `LineServices.cs:1440`／`LoCloneBreakRecord` `:1453`／`LoCreateBreaks` `:1522`／`LoCreateLine` `:1419`／`LoDisplayLine` `:1486`／`LoDisposeBreakRecord` `:1446`／`LoDisposeLine` `:1433`／`LoEnumLine` `:1494`／`LoQueryLineCpPpoint` `:1502`／`LoQueryLinePointPcp` `:1512`／`LoRelievePenaltyResource` `:1459`／`LocbkGetObjectHandlerInfo` `:1551`）：**native LineServices 行引擎**族。现取边界：① **无上游 C++ 实现**（`docs/unimplemented.md:558-575`：「它等于…从零写一个行布局引擎」）；② **本移植已由托管 `pfnFormatLine` 链取代**（`P1-tail2-hostline-recon.md` §1.4／§3-乙：判 native LS「**不必要** ∧ 代价极高」）；③ 若要做，native 须成「**被托管调用、再回调托管**」的**重入方** ⇒ 新立 `PRECOND-LS-SESSION-DRIVER`（`P1-ls-callback-face-recon.md`）。
- **01/02/25/26 文本分析 4 条**（`CreateTextAnalysisSink` `LineServices.cs:1589`／`CreateTextAnalysisSource` `:1609`／`GetScriptAnalysisList` `:1596`／`GetNumberSubstitutionList` `:1603`；调用点 `Shaping/TypefaceMap.cs:120-123`）：属**同一 LS 族**（声明件同件）；本移植路径上 `TextAnalyzer.Itemize` 已判 **`[PNSE · D 档]`**（`build/DirectWriteForwarder.Linux/ManagedSurface.cs:1115-1128` 现取：`NotSupported.Throw<IList<Span>>(nameof(Itemize))`），需 **DWrite 脚本分段**（`AnalyzeScript`）—— 与 `C2`（LS 会话）同属"内容层那一波"未备料面。

---

## §7 具名 `NOINFO`（逐条给"消掉条件"）

1. **`NOINFO-GAPGRADE-CALIBER`** —— 派单括注的「`70` 原始 − 11 死 − 1 误报 − 已实现 11」与**现取 `tool=59`** 不是同一代（现取 → `59 − 11 − 1 = 47`）；`70` 一数本席**未在现盘复现**（也不在 `pts-gap-decl.txt` 的历史追注里取到）。**消掉条件**：给出 `tool=70` 那一代的 `so16`／`exports` 与取得该数的命令原文。
2. **`NOINFO-WRAPPER-UNCOMPILED`** —— 4 条 `*Wrapper`（`NativeMethodsSetLastError.cs:46/51/74/89`）在**非编译分支** `#elif UIAUTOMATIONCLIENT`（界 `:38`／`:93`），本仓所汇三程序集**均未定义**该符号 ⇒ **无调用方**；`check-shim-coverage.py` 不求值预处理故仍计入 `tool`（`artifact` 只扣 `FindWindowExWrapper` 一条）。**消掉条件**：要么在判据件里把"非编译分支"做成第二条 `dead` 口径（**判据件 = 黑名单，须队长批**），要么给出"这三个程序集确实编过该分支"的反证。
3. **`NOINFO-GAPGRADE-FOOTNOTE-SOURCE`** —— `FsGetNumberSubpageFootnotes`／`FsGetNumberSubtrackFootnotes` 判 **乙** 的依据是"本侧无脚注模型 ∧ `FSIMETHODS` 槽 13 从不 deref"；本席**未**穷举全仓是否存在**其它**脚注计数源（只核了 `win32_pts.c`）。**消掉条件**：全仓 `grep` 脚注实体 ＋ 给出该槽真被调用的运行期读数。
4. **`NOINFO-GAPGRADE-FSTRANSFORM-SEMANTICS`** —— `FsTransformBbox`／`FsTransformRectangle` 的 `fswdir` 变换约定**无上游参考实现**（`docs/unimplemented.md:558-575`），本席**未**从 `LineServices`/`Pts` 声明面推出其确切算式。**消掉条件**：找到真机对拍（Windows `PresentationNative` 行为）或上游 `fstransform` 约定文档。
5. **`NOINFO-GAPGRADE-CALLSITE-REACHABILITY`** —— §2 表的"调用点"（本件在 §3–§6 引用的 `PtsHost.cs`／`PtsPage.cs`／`PtsContext.cs` 等）是**静态文本命中**，**不等于"运行期必经"**；本件**未跑腿**。**消掉条件**：一条真装置腿 ＋ 逐入口 `entry=` 留痕（同 `P1-ls-family-recon.md` §1.3 的射程边界）。
6. **`NOINFO-GAPGRADE-PTS-NEVER-BOUNDARY`** —— `dead=11` 由判据件内嵌 `python3` 现算（本席**照同一段复跑**得 11），但**未用第二独立方法**再推一遍 `#if NEVER` 区间边界。**消掉条件**：第二口径（如 `cpp -D` 预处理求值）复算同一集合。

---

## §8 纪律与验收

- 🔴 **只读**：唯一写入 ＝ 本件；`src/**`／`build/**`（除本件）／`build/MilBridge/tools/**`／`upstream/**` **一律未改**；**未构建**；**未跑整趟 `verify-all`**；进程只按 PID；**禁 `sleep` 轮询**；大件只用 `wc`/`head`/`tail`/`grep`。
- 🔴 **`P9`**：不把"本侧某面找不到源"读成"没有源" —— 本件对 `Lo*` 明确写"**源在宿主侧**（托管 `TextFormatter`），只判'取它要内容层那一波'"，**不**判"内容无源"。
- 🔴 **`P10`**：每条否定附**射程**（件＋行号＋现取命令）；§1 的 47 条来自**一条可复跑命令** ＋ 判据件现算的两处扣减。
- 🔴 **恒真断言族**：本件读数**全部来自读取**（`grep`/`awk`/`wc`/`sha256sum`/`check-shim-coverage.py`），**未**使用"两样本一致"类证据。
- **验收**：新件、`mode 644`、首记号 `# P1-tail2 · T-A65 `、末行自证并当场复算 MATCH、`temp+rename`。

---

**判词（本席）**：① 现取 `ops=47`（`tool=59 − dead=11 − artifact=1`，与派单逐值相符），族分解 ＝ `Fs*`21 ＋ `Lo*`12 ＋ `Nl*`6 ＋ 文本分析 4 ＋ `*Wrapper`4。② **甲（可诚实实施）5 条**（按代价：`FsDestroyPageBreakRecord`／`SetScrollPosWrapper`／`GlobalDeleteAtomWrapper`／`FsUpdateFinitePage`／`FsGetSubpageColumnBalancingInfo`）—— 判据 ＝「无真几何出参 ∧ 出参可由本侧自持台账/状态推出」，逐条已给语义出处与判据草案。③ **乙 20 条**：`Fs*` 真几何（含*造型/变换*）＋ 无根对象（子页/子轨断页记录本侧不产）＋ `Wrapper` 真测量。④ **丙 6 条** ＝ `Nl*` 在册有意降级（`nl-intent-check.sh` 段①：不许导出）。⑤ **丁 16 条** ＝ LS 族（`Lo*` 12 ＋ 文本分析 4），须"内容层那一波"（`TASK-0307` 的 `C2`/`C4`）。⑥ **结构发现**：4 条 `*Wrapper` 全在**非编译分支** ⇒ 工具口径里的"活缺口"无调用方（`NOINFO-WRAPPER-UNCOMPILED`）。⑦ **具名 `NOINFO` 6 条**（§7），各附消掉条件。

`P1-tail2-gapgrade-recon 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 83beabeca627580e（末行＝本行）`

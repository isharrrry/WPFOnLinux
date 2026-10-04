# P1-W83 `FSIMETHODS` 17 槽逐槽可用性侦察 —— 为 `cParas` 找源

本件是**只读侦察件**（`work` 类）：唯一目标是回答「**哪一槽（或哪几槽的组合）能给出子轨数／段落数**」。**本件不实现、不跑腿、不构建、不占显示位、不改任何代码。**
本件**不含**任何运行期腿读数；凡引他人读数一律标「引自 X，本席未独立复算」并带代际。

---

## §0 身份、边界与使用方式

- 载体：`build/MilBridge/P1-fsimethods-recon.md`（**新建**）。写者＝`scout`（只读侦察＋判据先写）。
- 写入面：**仅本件**；`$N` 内其余件（含 `src/WpfGfx.Linux.Native/**`）本席**一件未改**。
- 本件结论**只许收紧**：后续件想改本件任一条，只能改窄/加严/加证据；放宽须队长出裁定并在册。
- ⚠️ **在飞件警告（本件最重要的一条元信息）**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 在**本件侦察期间被改过**——本席 18:14:27 读到 `sha16=c90a78af8bc9499c`，18:15:33 已变成 **`58c7725b32598728`**（mtime 18:15:26）⇒ 该件的**行号只在本代有效**；本件对他的每一条引用都带代际，实现/复核者开工前**必须重取**。

---

## §1 现取台账（读取时刻＝2026-09-29 18:14–18:17，本席本地，仅本次有效）

主树 HEAD＝`10f8311`（`docs(#81): t161 FsQuerySubtrackDetails 判据 …`，读于 18:14）。

| 件 | sha16 | 用途 |
|---|---|---|
| `PtsHost/Pts.cs` | `1a8575a18767a956` | `FSIMETHODS` 17 槽定义、17 个 `Obj*` 委托签名、`FsFormatSubtrackFinite` 声明、`FsQuerySubtrack*` 声明 |
| `PtsHost/PtsHost.cs` | `d1976dcc8362c8f9` | 16 个 `Subtrack*` 实现位、`_objectContextOffset` |
| `PtsHost/PtsCache.cs` | `25a3e0b6c50c2461` | `InitInstalledObjectsInfo` 装配位（**逐字**） |
| `PtsHost/ContainerParagraph.cs` | `1d0128592496706d` | 宿主侧造型入口向引擎回调（`FsFormatSubtrackFinite` 调用点） |
| `PtsHost/PtsHelper.cs` | `f2ed9552e983fed1` | `ParaListFromSubtrack`（`cParas` 的消费面） |
| `PtsHost/ContainerParaClient.cs` | `0d2e6aa79fdc035a` | `FsQuerySubtrackDetails` 的 9 处调用点 |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | **`58c7725b32598728`**（mtime 18:15:26，**在飞**；本席本件较早读数为 `c90a78af8bc9499c`） | `subtrack_methods` 的存与用、`Fs*` 真实现清单、`c_paras` 先例 |
| `build/MilBridge/P1-subtrack-criteria.md`（`t161`） | 全 sha256 `01b00c39ad6f1e8494bac8295b6098c6d21f0f63d95e5daa31ef0bcf21024f67`／326 行；末行自证 `7dcd11d7f0afa065`（**本席当场复算 MATCH=yes**，其**内部读数**未复算） | 本件的来源件（`PRECOND-NO-CPARAS-SOURCE` 的提出处） |

---

## §2 `FSIMETHODS` 17 槽全表（每格带 `文件:行`）

**表定义**：`Pts.cs:1204-1223`（`internal struct FSIMETHODS`，`[StructLayout]` 顺序 17 字段，字段行 `:1206-1222`）。
**装配位**：`PtsHost/PtsCache.cs:603-619`（`InitInstalledObjectsInfo` 的 subtrack 段，`PtsCache.cs:600` 起为该私有方法）。
**native 侧状态（**统一结论**）**：`win32_pts.c:484 t->subtrack_methods = fssubtrackparamethods; /* 原样存，不 deref */`（字段声明 `:103`）⇒ **17 槽整表被原样存下、一个字节都没被读、没有任何一槽被调用过**（`grep -n 'subtrack_methods'` 全代仅 `:103` 与 `:484` 两处命中）。故下表「native 状态」列**逐格同值**：**存而未用**。
**参数性质**列图例：`H`=托管句柄（`HandleToObject` 吃得下）；`E`=**引擎自有对象指针**；`S`=结构/几何指针（只读或读写出参）；`I`=普通整数/枚举；`P`=**伪指针**（由整数导出，非分配对象）。

| # | 字段（`Pts.cs:1206`…） | 委托（`Pts.cs`） | 签名（入参／出参，`Pts.cs` 原注释） | 装配（`PtsCache.cs`） | 实现（`PtsHost.cs`） | 参数性质 | **能否给"段数"** |
|---|---|---|---|---|---|---|---|
| 1 | `pfnCreateContext` `:1206` | `ObjCreateContext` `:2699` | `(pfsclient, pfsc, pfscbkobj, uint ffi, int idobj, out pfssobjc)` | `:603` | `SubtrackCreateContext` `:2644` | 前三 `S/H`；`ffi/idobj` `I`；**`pfssobjc` `P`** | **不能**（出参是对象上下文，不是条数） |
| 2 | `pfnDestroyContext` `:1207` | `ObjDestroyContext` `:2706` | `(pfssobjc)` | `:604` | `SubtrackDestroyContext` `:2654` | `P` | **不能** |
| 3 | `pfnFormatParaFinite` `:1208` | `ObjFormatParaFinite` `:2708` | `(pfssobjc, pfsparaclient, pfsobjbrk, fBreakRecordFromPreviousPage, nmp, iArea, pftnrej, pfsgeom, fEmptyOk, fSuppressTopSpace, uint fswdir, ref FSRECT fsrcToFill, pmcsclientIn, FSKCLEAR, FSKSUPPRESS…, fBreakInside, out FSFMTR, **out pfspara**, out pbrkrecpara, out dvrUsed, out FSBBOX, out pmcsclientOut, out FSKCLEAR, out dvrTopSpace, out fBreakInsidePossible)` | `:605` | `SubtrackFormatParaFinite` `:2662` | `H`(pfsparaclient/nmp/pmcsclient*)、`E`(**out `pfspara`**)、`S`、`I` | ⚠️ **本槽不给"条数"，但它一次＝一个段落** ⇒ **计数入口**（见 §3.2）；出参 `pfspara` 是引擎自有对象 ⇒ t161 §4(a) 的那个对象 |
| 4 | `pfnFormatParaBottomless` `:1209` | `ObjFormatParaBottomless` `:2736` | 同上但 `(…, int urTrack, int durTrack, int vrTrack, …, out FSFMTRBL, **out pfspara**, out dvrUsed, out FSBBOX, out pmcsclientOut, out FSKCLEAR, out dvrTopSpace, out fPageBecomesUninterruptable)` | `:606` | `SubtrackFormatParaBottomless` `:2726` | 同上 | ⚠️ 同上（**第二个计数入口**） |
| 5 | `pfnUpdateBottomlessPara` `:1210` | `ObjUpdateBottomlessPara` `:2758` | `(pfspara, pfsparaclient, nmp, iArea, pfsgeom, fSuppressTopSpace, fswdir, urTrack, durTrack, vrTrack, pmcsclientIn, FSKCLEAR, fInterruptable, out FSFMTRBL, out dvrUsed, out FSBBOX, out pmcsclientOut, out FSKCLEAR, out dvrTopSpace, out fPageBecomesUninterruptable)` | `:607` | `SubtrackUpdateBottomlessPara` `:2784` | `E`+`H`+`I` | **不能**（更新既有段落，不增条数；出参里无计数） |
| 6 | `pfnSynchronizeBottomlessPara` `:1211` | `ObjSynchronizeBottomlessPara` `:2779` | `(pfspara, pfsparaclient, pfsgeom, uint fswdir, int dvrShift)` | `:608` | `:2842` ⇒ **回调引擎** `PTS.FsSynchronizeBottomlessSubtrack(Context, pfspara, …)` | `E`+`H`+`I` | **不能**（无出参） |
| 7 | `pfnComparePara` `:1212` | `ObjComparePara` `:2785` | `(pfsparaclientOld, pfsparaOld, pfsparaclientNew, pfsparaNew, uint fswdir, out FSCOMPRESULT, out int dvrShifted)` | `:609` | `:2869` ⇒ 引擎 `PTS.FsCompareSubtrack(...)` | `H`×2＋`E`×2 | **不能**（比较结果与位移，不是条数） |
| 8 | `pfnClearUpdateInfoInPara` `:1213` | `ObjClearUpdateInfoInPara` `:2793` | `(pfspara)` | `:610` | `:2881` ⇒ 引擎 `PTS.FsClearUpdateInfoInSubtrack(Context, pfspara)` | `E` | **不能** |
| 9 | `pfnDestroyPara` `:1214` | `ObjDestroyPara` `:2795` | `(pfspara)` | `:611` | `:2887` ⇒ 引擎 `PTS.FsDestroySubtrack(Context, pfspara)` | `E` | **不能** |
| 10 | `pfnDuplicateBreakRecord` `:1215` | `ObjDuplicateBreakRecord` `:2797` | `(pfssobjc, pfsbrkrecparaOrig, out pfsbrkrecparaDup)` | `:612` | `:2893` ⇒ 引擎 `PTS.FsDuplicateSubtrackBreakRecord(...)` | `P`+`H` | **不能** |
| 11 | `pfnDestroyBreakRecord` `:1216` | `ObjDestroyBreakRecord` `:2801` | `(pfssobjc, pfsobjbrk)` | `:613` | `:2901` ⇒ 引擎 `PTS.FsDestroySubtrackBreakRecord(...)` | `P`+`H` | **不能** |
| 12 | `pfnGetColumnBalancingInfo` `:1217` | `ObjGetColumnBalancingInfo` `:2804` | `(pfspara, uint fswdir, **out int nlines**, out int dvrSumHeight, out int dvrMinHeight)` | `:614` | `:2908` ⇒ 引擎 `PTS.FsGetSubtrackColumnBalancingInfo(...)` | `E`+`I` | ⚠️ **有计数，但数的是"文本行"（`nlines`）不是"段落"⇒ 量种不同，不能充当 `cParas`** |
| 13 | `pfnGetNumberFootnotes` `:1218` | `ObjGetNumberFootnotes` `:2810` | `(pfspara, **out int nftn**)` | `:615` | `:2919` ⇒ 引擎 `PTS.FsGetNumberSubtrackFootnotes(...)` | `E`+`I` | ⚠️ 同上：数的是**脚注** |
| 14 | `pfnGetFootnoteInfo` `:1219` | `ObjGetFootnoteInfo` `:2813` | `(pfspara, uint fswdir, int nftn, int iftnFirst, FSFTNINFO* pfsftninf, out int iftnLim)` | `:616` | `:2925` ⇒ **`Debug.Fail("PTS.ObjGetFootnoteInfo is not implemented.")`（`:2933`）＋ `return PTS.fserrNotImplemented`（`:2935`）** | `E`+`S`+`I` | **不能**（且本槽**自陈未实现**） |
| 15 | `pfnGetFootnoteInfoWord` `:1220` | （**无**：`Pts.cs:2820` 起整块被注释掉） | — | **`:617 = IntPtr.Zero`**（**唯一未被装配的槽**） | **无** | — | **不能**（**空槽**） |
| 16 | `pfnShiftVertical` `:1221` | `ObjShiftVertical` `:2827` | `(pfspara, pfsparaclient, pfsshift, uint fswdir, out FSBBOX)` | `:618` | `:2937`：**`Debug.Assert(false)`（`:2943`）＋ 空 `FSBBOX`（`:2944`）＋ `return PTS.fserrNone`（`:2945`）** | `E`+`H`+`S` | **不能**；🔴 且本槽是**恒绿判别器**（见 §6-P5） |
| 17 | `pfnTransferDisplayInfoPara` `:1222` | `ObjTransferDisplayInfoPara` `:2833` | `(pfsparaOld, pfsparaNew)` | `:619` | `:2948` ⇒ 引擎 `PTS.FsTransferDisplayInfoSubtrack(...)` | `E`×2 | **不能** |

**副发现（同批现取，供实现者避坑）**：subpage 表（`PtsCache.cs:622-637`）**没有** 第 15 槽那一行（即 `subpageParaInfo.pfnGetFootnoteInfoWord` **未显式清空**），而 subtrack 表在 `:617` 显式置 `IntPtr.Zero` ⇒ **两表装配不对称**；若实现者要靠逐槽指针是否为 0 判"有无实现"，此差异会造成**误判**。

---

## §3 为 `cParas` 找源（**本件核心产出**）

### §3.1 回调面判词：**17 槽里没有一槽能给"段落数"**

逐槽判据（据 §2 表）：
- **唯一的两个"计数"出参**是 12 槽 `nlines`（**文本行数**）与 13 槽 `nftn`（**脚注数**）⇒ **量种不同**，拿它们当 `cParas` 即 **P-类捏造**（`PtsHelper.cs:636` 还有 `ErrorHandler.Assert(cParas == paraCount)` 兜底 ⇒ 会当场炸）。
- 其余槽的出参是：对象上下文（`pfssobjc`）／段落实例（`pfspara`）／断页记录／几何与垂直量（`dvrUsed`/`FSBBOX`/`dvrTopSpace`）／比较结果（`FSCOMPRESULT`）／脚注信息数组 ⇒ **均非"条数"**。
- 14 槽**自陈未实现**（`PtsHost.cs:2931-2932`），15 槽**空装配**（`PtsCache.cs:617`），16 槽是**恒绿桩**（`PtsHost.cs:2943`）。
⇒ **回调面（`FSIMETHODS`）无源。** 这一条是本件**可给读者当结论用**的否定判定。

### §3.2 但 `cParas` **不需要**回调槽：它是**引擎自有簿记**（本件**修正** t161 的一处口径）

**推导链（全部本席现取）**：
1. `PtsHost.cs:2662` `SubtrackFormatParaFinite` 的**出参**里有 `out IntPtr pfspara`（`Pts.cs:2708` 声明原文注释：`// OUT: pointer to the para data`）。
2. 该出参由**引擎侧入口**填写：`ContainerParagraph.cs:526` `PTS.Validate(PTS.FsFormatSubtrackFinite(PtsContext.Context, …, out fsfmtr, **out pfspara**, out pbrkrecOut, …))`；声明在 `Pts.cs:3318-3342`，其中该出参**名字就叫 `ppfsSubtrack`**（`Pts.cs:3337 // OUT: ptr to the subtrack`）。
3. 而这条链的**发起者**是宿主回调 `ObjFormatParaFinite`（**第 3 槽**），即：**引擎驱动（`Fs*` 驱动入口）⇒ 调宿主槽 3 ⇒ 宿主回调进引擎 `FsFormatSubtrackFinite` ⇒ 引擎给出 `ppfsSubtrack`（＝`pfspara`）**。
4. ⇒ **`pfspara` 语义上就是"子轨对象"，且是引擎造的**；而 `BaseParaClient._paraHandle = pfspara`（`BaseParaClient.cs:65`）⇒ `FsQuerySubtrackDetails(ctx, _paraHandle, …)` 的形参名 `pSubTrack` **是对的**。
5. ⇒ **这条子轨有多少段，是引擎在造型过程中自己记下来的**（每成功造型一段 ⇒ 一次 `FsFormatSubtrackFinite`/`FsFormatSubtrackBottomless`）⇒ **引擎数自己的调用即得 `cParas`**；**不需要任何回调槽提供它**。

**在册先例（同一模式的既有落地，可复用其判据形状）**：`win32_pts.c`（代际 `58c7725b32598728`）现取——
- `:292 int c_paras; /* 这条 track 的段数（按**对象**给，非全局常量） */`；
- `:348 p->c_paras = 1;`（建对象时记账）；
- `:2697 d->td_pfstrack = (void *)&pg->c_paras; /* 轨句柄 ＝ **本对象内**该字段的地址 */`；
- `:2794`（`wpf_pts_track_owned`：**指针值比较，不 deref**）、`:2816-2817`（`FsQueryTrackDetails` **按对象**答段数）；
- `:3286-3290` 夹具：改一个对象的 `c_paras` ⇒ **只有它变**（反"全局常量"）。
⇒ 即：**句柄＝本对象内字段地址 → 身份可指针直比 → 按对象答数 → 反腿一对（NULL 与"看似真实则伪"）**。这正是 `FsQuerySubtrackDetails.cParas` 应当照搬的形状。

### §3.3 结论对 `PRECOND-NO-CPARAS-SOURCE` 的影响（**本件收紧 t161 的用法**）

- `t161` 写的「`cParas` 的**唯一诚实来源是回调面**」⇒ 本件**修正**为：**回调面（`FSIMETHODS`）无源（§3.1 成立）**，但**诚实源在引擎侧、且有在册先例（§3.2）**。
- ⇒ `PRECOND-NO-CPARAS-SOURCE` **不作为本跳的终点成立**；它只应保留为**局部结论**：「回调面无源」。**不许**用 §3.1 去宣称"`cParas` 做不到"——那是把"回调面没源"偷换成"没有源"。
- ⇒ **真正的阻塞**是另一件事：**承载 `cParas` 的引擎侧入口今天一条都没实现**。现取 `win32_pts.c`（`58c7725b32598728`）的真实现 `Fs*` 入口**共 6 条**：`FsCreatePageBottomless:318`、`FsQueryPageDetails:2679`、`FsDestroyPage:2714`、`FsQueryTrackDetails:2806`、`FsCreatePageFinite:2840`、`FsQueryTrackParaList:2894` ⇒ **`FsFormatSubtrack*`／`FsQuerySubtrack*` 一条都不在其中**。而托管侧的子轨引擎面共 **16 条**（`Pts.cs` 内 `Fs*Subtrack*` 唯一名去重现取）：`FsClearUpdateInfoInSubtrack`／`FsCompareSubtrack`／`FsDestroySubtrack`／`FsDestroySubtrackBreakRecord`／`FsDuplicateSubtrackBreakRecord`／**`FsFormatSubtrackFinite`**／**`FsFormatSubtrackBottomless`**／`FsGetNumberSubtrackFootnotes`／`FsGetSubtrackColumnBalancingInfo`／`FsGetSubtrackFootnoteInfo`／`FsQuerySubtrackDetails`／`FsQuerySubtrackParaList`／`FsShiftSubtrackVertical`／`FsSynchronizeBottomlessSubtrack`／`FsTransferDisplayInfoSubtrack`／`FsUpdateBottomlessSubtrack`。

---

## §4 交叉核对：哪些参数是句柄、哪些是整数/结构指针

| 类别 | 成员（现取） | 判定依据 | 对"间接数出子轨"的意义 |
|---|---|---|---|
| **`H` 托管句柄** | `pfsparaclient`、`nmp`、`pmcsclientIn/Out`、`pfsobjbrk`、`pfsbrkrecparaOrig/Dup`、`nmsSection`（`PtsHost.cs:414`）、`nms`（`:596`） | `PtsHost.cs` 内 `HandleToObject(...) as …` 现取（如 `:2695` `HandleToObject(nmp) as ContainerParagraph`、`:2697` `HandleToObject(pfsparaclient) as ContainerParaClient`；同形另见 `:2752`/`:2754`、`:2809`/`:2811`、`:2852`） | **可作身份键**（但见 `t160` ABA 教训：`rc`/数值都不能辨身份 ⇒ 必须来源证据） |
| **`E` 引擎自有对象** | `pfspara`（＝子轨 `ppfsSubtrack`）、`pfsshift` | `Pts.cs:3337` 出参名与 `ContainerParagraph.cs:526` 调用点 | **这是 `cParas` 的载体**（§3.2） |
| **`P` 伪指针** | `pfssobjc`（subtrack：`idobj + 10`，`PtsHost.cs:93/:2652`；subpage：`idobj + 11`，`:2967`） | `PtsHost.cs:93` 注释原文「Since ObjectContext is not really created by our PTS host, it is good enough for now.」 | 🔴 **不可作身份键**：由 `idobj` 导出的整数，**可碰撞**；`ObjDestroyContext` 是 `// Do nothing`（`:2655-2658`） |
| **`S` 结构/几何指针** | `pfsc`、`pfscbkobj`、`pfsgeom`、`pfsftninf`（`FSFTNINFO*`） | 无 `HandleToObject`；注释标 "pointer to geometry"/"array of footnote info" | 不可作身份键；`pfsftninf` 还是 **IN/OUT 数组** |
| **`I` 真整数/枚举** | `ffi`、`idobj`、`iArea`、`fEmptyOk`、`fSuppressTopSpace`、`fswdir`、`dvrUsed`、`dvrTopSpace`、`fBreakInsidePossible`、`fPageBecomesUninterruptable`、`nlines`、`dvrSumHeight`、`dvrMinHeight`、`nftn`、`iftnFirst`、`iftnLim` | 注释与类型 | 计数类只有 `nlines`/`nftn`（§3.1） |

**⇒ 交叉核对的结论**：这 17 槽**没有任何一槽回传"子轨数/段落数"**；能回传计数的两槽**量的种类不同**；而**伪指针 `pfssobjc` 连身份键都当不了**，所以"用一个槽的调用次数去间接数出子轨"这条路**在回调面上不成立**（计数只能发生在**引擎侧**，见 §3.2 第 5 条）。

---

## §5 诚实边界与 `NOINFO` 面

1. **不声称任何槽"可用"**：本件的结论是一条**否定判定**（回调面无源）＋ 一条**方向判定**（源在引擎侧）。后者**尚未有读数** ⇒ 它的可证伪设计见 §6。
2. **`win32_pts.c:484` 「原样存，不 deref」必须原样保留在本件里**：这是**"未使用"**的现取事实，**不等于"不可用"**。任何后续件**不许**把它读成"回调面无源"的证据——两者是不同命题（前者讲 native 现状，后者讲 ABI 形状）。
3. **具名 `NOINFO`（取不到的，如实记）**：
   - `NOINFO-FSIMETHODS-ABI`：17 槽的**权威 ABI 布局/槽位偏移**取不到——托管侧是 `[StructLayout(Sequential)]` ＋ 17 个委托字段，**native 侧没有镜像结构**（`win32_pts.c` 内无 `FSIMETHODS` 镜像、无 `offsetof` 断言）⇒ 槽序**只能按托管声明推断**，**偏移未实测**。按 `t127`／`t160` 前例：**选槽前必须先实测**（否则就是拿算出来的偏移当依据）。
   - `NOINFO-FSFORMATSUBTACK-SEMANTICS`：`FsFormatSubtrackFinite`／`FsFormatSubtrackBottomless` 的**真实现语义**取不到——上游是闭源 native，仓内只有托管声明（`Pts.cs:3318`/`:3344`）与调用点（`ContainerParagraph.cs:526`/`:664`）⇒ 「一次成功造型＝一个段落」这一条是**据签名与调用形态的判定**，**须由实现件的读数复核后才可升级**。
   - `NOINFO-SLOT-INVOCATION`：**17 槽今天一次都没被调过**（`win32_pts.c` 全代仅 `:103`/`:484` 命中）⇒ 「调用形态」只能给**设计**，不能给**读数**。
4. **禁**：把 §3.2 的**方向判定**写成"已可用"；把 §3.1 的**回调面无源**写成"无源"；用槽位指针是否为 0 判"有无实现"（§2 副发现：两表装配不对称）。

---

## §6 假进度必红（本件新增/沿用）

- **P1** 用 12 槽 `nlines` 或 13 槽 `nftn` 当 `cParas`（**量种不同** ⇒ 捏造；`PtsHelper.cs:636` 的 `ErrorAssert` 会当场炸）。
- **P2** 用**常量**（含 `1`）冒充 `cParas`（`t127` 反腿同族：必须**按对象**变；先例 `win32_pts.c:3286-3290`）。
- **P3** 把 `pfssobjc`（`idobj+10` 的**伪指针**）当句柄/身份键用（**可碰撞**）。
- **P4** 用 15 槽（**空装配**）或 14 槽（**自陈未实现**）当可用槽。
- **P5** 🔴 **用 16 槽 `pfnShiftVertical` 当判别器**：`PtsHost.cs:2937-2946` 体内 `Debug.Assert(false)`（`:2943`）＋ 空 `FSBBOX` ＋ **`return PTS.fserrNone`** ⇒ **不读任何字段就返成功**＝**恒绿**（与 `+200`／`+56` 同族，**禁用**）。
- **P6** 用「`subtrack_methods` 非空」当「回调面可用」（存下 ≠ 能用；见 §5-2）。
- **P7** 用**推断的槽序**而不实测偏移就去选槽（`t127` 前例：偏移算错 8 B ⇒ 1129× 自伤）。
- **P8** 单样本／跨代相减／`NOINFO` 充绿（沿用 t158/t161 红榜）。
- **P9** 把"回调面无源"（§3.1）偷换成"`cParas` 做不到"从而**提前收工**（本件 §3.3 明禁）。

---

## §7 排期含义

**1) 是不是 W8 主线的下一跳？** —— **是，但靶心要改判一格。**
`t161` 把下一跳定成「(a) `pfspara` 真对象 ＋ (b) `FsQuerySubtrackDetails` 作答」。本件侦察后**收紧为**：
- **(a) 与 (b) 的公共入口是同一族引擎侧入口**：`FsFormatSubtrackFinite`（`Pts.cs:3318`）／`FsFormatSubtrackBottomless`（`:3344`）——**它们既造出 `ppfsSubtrack`（＝`pfspara`），又是"一段落一次"的记账点**。⇒ **下一跳的最小承重格应定在「引擎侧子轨造型入口」**，而不是先做 `FsQuerySubtrackDetails` 的答复（后者没有对象可答）。
- 现场佐证：`win32_pts.c` 的**在飞代**（`58c7725b32598728`）已经在往 `FSPARADESCRIPTION.pfspara` 里填值（`:3017 rg[i].pfspara = (void *)para_val;`，同批 `:3018/:3019` 填 `pfsparaclient`/`nmp`，并接 `+168 GetParaProperties` 作下游接受）⇒ **(a) 正在被别人做**；本件据此把"下一跳"进一步推到 **(a) 的**上游：**`pfspara` 的值从哪来**（`para_val` 的来源）——若它也是从托管侧回调取得，则需回答「宿主回调里哪一个给出 subtrack 对象」。

**2) 若判"某槽可用" ⇒ 最小可证伪实验（三步，全部只读设计、由实现件跑）**：
- **E1 槽序实测**：在 native 侧加 `FSIMETHODS` **镜像结构 ＋ `offsetof` 断言**（照 `win32_pts.c:933-938` 的 6 条 `_Static_assert` 体例，代际 `58c7725b32598728`），把 17 槽逐个钉死；**先测后用**。
- **E2 调用形态实测（唯一可证伪的"可用"证据）**：引擎驱动一次第 3 槽（`pfnFormatParaFinite`）并**在调用前把 out 参数显式置毒值**，然后断言：① `rc=0`；② `pfspara` 被改写且**身份可认领**（指针等于本侧某对象内字段地址，照 `:2794` 的 `wpf_pts_track_owned` 体例）；③ **同一次调用只增加一个条数**。⇒ 「一次＝一段」由此**现取判定**（**不许**沿用任何前跳结论，`t154` 教训）。
- **E3 反腿一对**：a) 交 `NULL`；b) 交"**看似真实则伪**"的句柄（例如**栈上局部变量地址**）⇒ 两条都必须**被拒且留痕**（照 `win32_pts.c:3286-3305` 的现成体例）。

**3) 若判"不可用/无源"** ⇒ 本件已如实给出：**回调面无源（§3.1）**、**引擎侧有源但有 16 条入口全未实现（§3.3）**。此时 `(b)` 的正确形态是：**不**去别处找源（那是 P9），而是**把 `cParas` 的诚实性重新判在"引擎侧按对象记账"上**（§3.2），并要求记账点**必须**是"引擎自己驱动的造型调用"（否则就是 P2 常量捏造）。

---

## §8 本件自身的验收

1. 新件；末行＝自证行（`head -n -1 <本件> | sha256sum | cut -c1-16`）；`mode 644`；首记号 ＝ `# P1-W83 `。
2. 复核者须**独立重取** §1 表内至少 5 件的 sha16 与引用行（`sed -n` 打原文）并比对；`win32_pts.c` **必须重取**（在飞）；不一致处**只增不改**地追加。
3. 本件**未**授权任何判据放宽；实现件与本件冲突 ⇒ 冲突进裁定。
4. 本件不含腿读数；他人读数均标「引自 …，本席未独立复算」；`t161` 末行自证本席**当场复算过**（MATCH=yes）——属代际核对，不构成对其内部读数的复算。

---

## §9 附录：现取原文摘录（仅本次有效）

`Pts.cs:1204-1223`（sha16 `1a8575a18767a956`）——17 槽字段（节录首尾）：
```
        internal struct FSIMETHODS
        {
             internal ObjCreateContext pfnCreateContext;              // :1206
             internal ObjDestroyContext pfnDestroyContext;            // :1207
             internal ObjFormatParaFinite pfnFormatParaFinite;        // :1208
             …
             internal IntPtr pfnGetFootnoteInfoWord;                  // :1220
             internal ObjShiftVertical pfnShiftVertical;              // :1221
             internal ObjTransferDisplayInfoPara pfnTransferDisplayInfoPara; // :1222
        }
```
`PtsCache.cs:603-619`（sha16 `25a3e0b6c50c2461`，逐字节录 subtrack 段）：
```
            subtrackParaInfo.pfnCreateContext = new PTS.ObjCreateContext(ptsHost.SubtrackCreateContext);
            subtrackParaInfo.pfnDestroyContext = new PTS.ObjDestroyContext(ptsHost.SubtrackDestroyContext);
            subtrackParaInfo.pfnFormatParaFinite = new PTS.ObjFormatParaFinite(ptsHost.SubtrackFormatParaFinite);
            subtrackParaInfo.pfnFormatParaBottomless = new PTS.ObjFormatParaBottomless(ptsHost.SubtrackFormatParaBottomless);
            subtrackParaInfo.pfnUpdateBottomlessPara = new PTS.ObjUpdateBottomlessPara(ptsHost.SubtrackUpdateBottomlessPara);
            subtrackParaInfo.pfnSynchronizeBottomlessPara = new PTS.ObjSynchronizeBottomlessPara(ptsHost.SubtrackSynchronizeBottomlessPara);
            subtrackParaInfo.pfnComparePara = new PTS.ObjComparePara(ptsHost.SubtrackComparePara);
            subtrackParaInfo.pfnClearUpdateInfoInPara = new PTS.ObjClearUpdateInfoInPara(ptsHost.SubtrackClearUpdateInfoInPara);
            subtrackParaInfo.pfnDestroyPara = new PTS.ObjDestroyPara(ptsHost.SubtrackDestroyPara);
            subtrackParaInfo.pfnDuplicateBreakRecord = new PTS.ObjDuplicateBreakRecord(ptsHost.SubtrackDuplicateBreakRecord);
            subtrackParaInfo.pfnDestroyBreakRecord = new PTS.ObjDestroyBreakRecord(ptsHost.SubtrackDestroyBreakRecord);
            subtrackParaInfo.pfnGetColumnBalancingInfo = new PTS.ObjGetColumnBalancingInfo(ptsHost.SubtrackGetColumnBalancingInfo);
            subtrackParaInfo.pfnGetNumberFootnotes = new PTS.ObjGetNumberFootnotes(ptsHost.SubtrackGetNumberFootnotes);
            subtrackParaInfo.pfnGetFootnoteInfo = new PTS.ObjGetFootnoteInfo(ptsHost.SubtrackGetFootnoteInfo);
            subtrackParaInfo.pfnGetFootnoteInfoWord = IntPtr.Zero;
            subtrackParaInfo.pfnShiftVertical = new PTS.ObjShiftVertical(ptsHost.SubtrackShiftVertical);
            subtrackParaInfo.pfnTransferDisplayInfoPara = new PTS.ObjTransferDisplayInfoPara(ptsHost.SubtrackTransferDisplayInfoPara);
```
`PtsHost.cs`（sha16 `d1976dcc8362c8f9`）：
```
  :93   private static int _objectContextOffset = 10;
:2652   pfssobjc = (IntPtr)(idobj + _objectContextOffset);
:2654   internal int SubtrackDestroyContext(
:2657             // Do nothing
:2658             return PTS.fserrNone;
:2695                 ContainerParagraph para = PtsContext.HandleToObject(nmp) as ContainerParagraph;
:2697                 ContainerParaClient paraClient = PtsContext.HandleToObject(pfsparaclient) as ContainerParaClient;
:2933   Debug.Fail("PTS.ObjGetFootnoteInfo is not implemented.");
:2935   return PTS.fserrNotImplemented;
:2943   Debug.Assert(false);
:2945   return PTS.fserrNone;
```
`ContainerParagraph.cs:526-531`（sha16 `1d0128592496706d`）：
```
                PTS.Validate(PTS.FsFormatSubtrackFinite(PtsContext.Context, pbrkrecIn, fBRFromPreviousPage, this.Handle,
                    footnoteRejector, geometry, fEmptyOk, fSuppressTopSpace, fswdirSubtrack, ref fsrcToFillSubtrack,
                    (mcsContainer != null) ? mcsContainer.Handle : IntPtr.Zero, fskclearIn,
                    fsksuppresshardbreakbeforefirstparaIn,
                    out fsfmtr, out pfspara, out pbrkrecOut, out dvrUsed, out fsbbox, out pmcsclientOut, out fskclearOut
                    out dvrSubTrackTopSpace), PtsContext);
```
`win32_pts.c`（代际 **`58c7725b32598728`**，mtime 18:15:26，**在飞**）：
```
:103    const void  *subtrack_methods;       /* 托管传进来的指针，**原样存** */
:484    t->subtrack_methods = fssubtrackparamethods;        /* 原样存，不 deref */
:292            int          c_paras;               /* 这条 track 的段数（按**对象**给，非全局常量） */
:2697           d->td_pfstrack = (void *)&pg->c_paras;   /* 轨句柄 ＝ **本对象内**该字段的地址 */
:2794       if ((const void *)&g_pts_fsp_live[i]->c_paras == track) return 1;   /* **指针值比较**，不 deref */
:2816-2817      if ((const void *)&g_pts_fsp_live[i]->c_paras != pTrack) continue;
                *(int *)pTrackDetails = g_pts_fsp_live[i]->c_paras;   /* **按对象**回答段数 */
:3017       rg[i].pfspara       = (void *)para_val;   /* ⚠️ 在飞代**已开始填 pfspara** */
```

---

**判词（本席）**：① `FSIMETHODS` **17 槽里没有一槽能给"段落数"**——两个计数类出参 `nlines`（12 槽）与 `nftn`（13 槽）**量种不同**，其余槽不产条数，14 槽自陈未实现、15 槽空装配、16 槽恒绿 ⇒ **回调面无源**；② **但 `cParas` 不需要回调槽**：`FSPARADESCRIPTION.pfspara` 语义上就是**子轨对象**（`Pts.cs:3337` 出参名 `ppfsSubtrack` ＋ `ContainerParagraph.cs:526` 调用点），由引擎在 `FsFormatSubtrackFinite`/`FsFormatSubtrackBottomless` 内造出 ⇒ **"一段落一次"的调用计数即 `cParas`**，且在册先例（`FsQueryTrackDetails` ＋ `wpf_pts_fsp.c_paras`，句柄＝本对象内字段地址、按对象答数、反腿一对）已把形状给全；③ ⇒ **`PRECOND-NO-CPARAS-SOURCE` 不成立**，只保留为局部结论「回调面无源」，**真阻塞**是 **16 条 `Fs*Subtrack*` 引擎入口全未实现**；④ **下一跳改判**：靶心应定在**引擎侧子轨造型入口**（既有 (a) 又有 (b) 的公共入口），并以 §7-E1/E2/E3 三步现取判定；⑤ 本件另留两条实现前必办的实测：`FSIMETHODS` **槽序偏移只许实测**（`NOINFO-FSIMETHODS-ABI`）、`pfnShiftVertical` **禁用**（恒绿）。
`P1-fsimethods-recon 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 9105d8ff204e7b3b（末行＝本行）`

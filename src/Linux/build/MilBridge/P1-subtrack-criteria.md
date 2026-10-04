# P1-W81 判据（先写）：`FsQuerySubtrackDetails` —— 先判「钥匙 vs 其后」

本件是**判据先写**件（`work` 类）：先给「下一格的靶心」定性（是钥匙还是其后）、先给签名语义与诚实边界、先立红榜与「做不到」的具名前置。**本件不实现、不跑腿、不构建、不占显示位、不改任何代码。**
本件**不含**任何运行期腿读数；凡引他人读数一律标「引自 X，本席未独立复算」并带代际。

---

## §0 身份、使用方式与硬边界

- 载体：`build/MilBridge/P1-subtrack-criteria.md`（**新建**）。写者＝`scout`（只读侦察＋判据先写）。
- 写入面：**仅本件**。`$N` 内其余件（含 `src/WpfGfx.Linux.Native/**`、`build/MilBridge/tools/**`、`build/MilBridge/tests/**`、任何 `.cs`）本席**一件未改**。
- 判据**只许收紧**：后续件想改本件某条，只能改窄/加严/加证据；放宽须队长出裁定并在册。
- 本件不是实现件、不是复核件：实现另起件；对实现的独立复核另起 `review` 件。

---

## §1 现取台账（读取时刻＝2026-09-29 18:11–18:14，本席本地，仅本次有效）

主树 HEAD＝`76884d5`（`docs(#81): 裁定四十七 —— 段落列表接线七条合取全中；ABA 反腿证 rc 无法辨身份⇒身份类判据禁依赖 rc；下一跳靶心 FsQuerySubtrackDetails；认可过程自陈`，读于 18:11）。

| 件 | sha16 | 行 | 本席读到的字段/事实 |
|---|---|---|---|
| `PtsHost/Pts.cs` | `1a8575a18767a956` | `:3736-3740` | **本轮靶心的托管声明**：`[DllImport(DllImport.PresentationNative)] internal static extern int FsQuerySubtrackDetails(IntPtr pfsContext, IntPtr pSubTrack, out FSSUBTRACKDETAILS pSubTrackDetails);` |
| 同上 | 同上 | `:3742-3747` | **紧随其后**：`FsQuerySubtrackParaList(IntPtr pfsContext, IntPtr pSubTrack, int cParas, FSPARADESCRIPTION* rgParaDesc, out int cParaDesc)` |
| 同上 | 同上 | `:1527-1533` | `FSSUBTRACKDETAILS { FSUPDATEINFO fsupdinf; IntPtr nms; FSRECT fsrc; int cParas; }` |
| 同上 | 同上 | `:1512-1515` | `FSTRACKDETAILS { int cParas; }`（对照：**track 面只有一个计数**，subtrack 面**多三个字段**） |
| 同上 | 同上 | `:1204-1223` | `FSIMETHODS`（**17 槽**：`pfnCreateContext`/`pfnDestroyContext`/`pfnFormatParaFinite`/`pfnFormatParaBottomless`/`pfnUpdateBottomlessPara`/`pfnSynchronizeBottomlessPara`/`pfnComparePara`/`pfnClearUpdateInfoInPara`/`pfnDestroyPara`/`pfnDuplicateBreakRecord`/`pfnDestroyBreakRecord`/`pfnGetColumnBalancingInfo`/`pfnGetNumberFootnotes`/`pfnGetFootnoteInfo`/`pfnGetFootnoteInfoWord`/`pfnShiftVertical`/`pfnTransferDisplayInfoPara`） |
| 同上 | 同上 | `:3077-3083` | `CreateInstalledObjectsInfo(ref FSIMETHODS fssubtrackparamethods, ref FSIMETHODS fssubpageparamethods, out IntPtr pInstalledObjects, out int cInstalledObjects)` ⇒ **subtrack 的段落回调表按 `FSIMETHODS` 形状经此入口交给 native** |
| 同上 | 同上 | `:1500-1510` | `FSPARADESCRIPTION { fsupdinf; pfspara; pfsparaclient; nmp; idobj; dvrUsed; fsbbox; dvrTopSpace; }` |
| 同上 | 同上 | `:1934-1941`,`:1943-1947` | `FSKUPDATGE : int`；`FSUPDATEINFO { FSKUPDATE fskupd; int dvrShifted; }` |
| `PtsHost/PtsHost.cs` | `d1976dcc8362c8f9` | `:408-415` | `GetMainTextSegment(IntPtr pfsclient, IntPtr nmsSection, out IntPtr nmSegment)` ⇒ 体内 `Section section = PtsContext.HandleToObject(nmsSection) as Section;` ⇒ **该入参是托管句柄，不是裸指针** |
| 同上 | 同上 | `:586-598` | `GetFirstPara(IntPtr pfsclient, IntPtr nms, out int fSuccessful, out IntPtr nmp)` ⇒ 体内 `ISegment segment = PtsContext.HandleToObject(nms) as ISegment;` ⇒ 同上 |
| 同上 | 同上 | `:724-749`,`:734` | `CreateParaclient(...)` ⇒ `para.CreateParaclient(out pfsparaclient);` |
| 同上 | 同上 | `:776-798`,`:785` | `DestroyParaclient(...)` ⇒ `paraClient.Dispose();`（t158 §2.3 已判：**这是句柄的唯一回收触发点**） |
| `PtsHost/PtsHelper.cs` | `f2ed9552e983fed1` | `:145-181` | `ArrangeParaList(...)`：`:158` `HandleToObject(arrayParaDesc[index].pfsparaclient) as BaseParaClient`；`:174` `int dvrTopSpace = arrayParaDesc[index].dvrTopSpace;`；`:177` `rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;`；**`:179` `paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);`**；`:180` `dvrPara += arrayParaDesc[index].dvrUsed;` |
| 同上 | 同上 | `:623-637` | `ParaListFromSubtrack(PtsContext, IntPtr subtrack, ref FSSUBTRACKDETAILS subtrackDetails, out FSPARADESCRIPTION[] arrayParaDesc)` ⇒ `:629` 用 `subtrackDetails.cParas` **开数组**，`:633` 调 `FsQuerySubtrackParaList(..., subtrackDetails.cParas, rgParaDesc, out paraCount)`，`:636` `ErrorHandler.Assert(subtrackDetails.cParas == paraCount, PTSObjectsCountMismatch)` |
| `PtsHost/ContainerParaClient.cs` | `0d2e6aa79fdc035a` | `:47`/`:70`、`:89`/`:99`、`:142`/`:151`、`:177`/`:197`、`:218`/`:225`、`:240`/`:247`、**`:271`/`:283`/`:289`**、`:325`/`:337`、`:375` | 9 处「`FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails)` ⇒ 之后 `ParaListFromSubtrack(PtsContext, _paraHandle, ref subtrackDetails, out arrayParaDesc)`」成对；`:289` 为 `HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient` |
| 同上 | 同上 | `:260-296` | `GetTextContentRange()` 全身：**`:271` 是该 body 里 Assert 之后的第一个实招**；`:278` `if (subtrackDetails.cParas == 0 \|\| (_isFirstChunk && _isLastChunk))` 走**叶子分支**（不递归）；`else` 才 `:283` → `:289` → `:294` 递归 |
| `PtsHost/FlowDocumentPage.cs` | `cd4d1c09c3edef3f` | `:541`,`:547`,`:549` | `ParaListFromTrack(...)` ⇒ 循环内 `:547 paraClient = …HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient;` ⇒ **`:549 textContentRange.Merge(paraClient.GetTextContentRange());`** |
| `PtsHost/ListParaClient.cs` | `d3de181c357a9458` | `:46`,`:82` | 同为 `FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails)` ⇒ `:82` `HandleToObject(arrayParaDesc[index].pfsparaclient)` |
| `PtsHost/BaseParaClient.cs` | `e48fc11de3f65d09` | `:61-66`,`:252` | `Arrange(IntPtr pfspara, …)` ⇒ `:64 Debug.Assert(_paraHandle == IntPtr.Zero \|\| _paraHandle == pfspara);` **`:65 _paraHandle = pfspara;`**；字段声明 `:252 protected IntPtr _paraHandle;` |
| `PtsHost/PtsCache.cs` | `25a3e0b6c50c2461` | `:600-603`,`:433-437` | `InitInstalledObjectsInfo(ptsHost, ref SubtrackParaInfo, ref SubpageParaInfo, out installedObjects, …)` ⇒ `subtrackParaInfo.pfnCreateContext = new PTS.ObjCreateContext(ptsHost.SubtrackCreateContext);`（**托管侧真给出 subtrack 回调表**） |
| `build/PresentationFramework.Linux/PtsCache.Linux.cs`（我方） | `48cf0d8d7d1a90dd` | `:523` | `InitGenericInfo(ptsHost, (IntPtr)(index + 1), installedObjects, installedObjectsCount, …)` ⇒ **`pfsclient` ＝ 池下标＋1**（小整数是**真值**形态） |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `c90a78af8bc9499c`（**在飞**，本席读取时刻；更早今日为 `6d967d8843bd902b`） | `:457-475` | `CreateInstalledObjectsInfo(const void *fssubtrackparamethods, const void *fssubpageparamethods, …)` ⇒ `:469 t->subtrack_methods = fssubtrackparamethods; /* 原样存，不 deref */`、`:471 t->entries = 2; /* subtrack + subpage 两槽（真值）*/`、返回 0 并给真实表指针＋表长 |
| 同上 | 同上 | `:905-920` | `wpf_pts_fsparadesc` 镜像 ＋ **6 条 `_Static_assert`**（`pfspara==8`、`pfsparaclient==16`、`nmp==24`、`sizeof==64`、`FSUPDATEINFO==8`、`FSBBOX==20`） |
| 同上 | 同上 | `:2957-2964` | 填充体：`memset((void*)&rg[i], 0, sizeof(rg[i]));` 后**只写** `rg[i].pfsparaclient` 与 `rg[i].nmp` ⇒ **`pfspara` 保持 0** |
| 同上 | 同上 | `:984` | 纪律行：真腿内出现哨兵值 ⇒ 该读数作废；**本件从不造句柄值** |
| 同上 | 同上 | `:1109-1113`,`:1198-1206` | `WPF_PTS_DRIVE_PROBE_FAKE_NMS==-2` ⇒ T3 模式（**第一调仍用真 `nms`**）；第三跳 `nmp176 = nmp1`（T3 分支改成 `sect`，注释原文「★真错类型 live 句柄：`Section` 非 `BaseParagraph`」） |
| 同上 | 同上 | `:1281-1292` | `[DRIVE-PROBE3] … h1=%p rc176b=%d h2=%p … keep=%p keeprc=%d`（`keep` ＝ **故意不回收**以留给消费者的一枚句柄） |
| `build/MilBridge/P1-paralist-wire-report.md`（`t160`） | 全 sha16 `a3ca7725e9935eef`／174 行；末行自证 `b7ce3e86e3545091`（**本席当场复算 MATCH=yes**，读数本身未复算） | §8 | ENFE `1085／1113／403` 条**全同名 `FsQuerySubtrackDetails`**、**与本腿填充数逐值相等**（**引自 `t160`，本席未独立复算**） |
| 同上 | 同上 | `:90` | 「其余字节 0＝本件显式 `memset` 后只写这两格＋**`pfspara` 留 0**」（**引自 `t160`，本席未独立复算**；与 §1 `win32_pts.c:2957-2964` 现取**互证**） |
| 同上 | 同上 | `:161` | 「`FsQuerySubtrackDetails` 之后的链＝`NOINFO`（本跳到达即止）」（引自 `t160`） |

⚠️ `win32_pts.c` 是**在飞件**（今日已换两代）⇒ 实现者开工前须重取 sha16；若已变，本件对应条目按 §11 走追加（只增不改）。

### §1.1 `FSSUBTRACKDETAILS` 的偏移：**只许实测**

按 `Pts.cs:1527-1533` 字段序 ＋ `FSUPDATEINFO`＝8 B（`Pts.cs:1943-1947` ＋ `:1934-1941`）＋ 64 位 `IntPtr`＝8 B ＋ `FSRECT`＝4×`int`＝16 B，**计算值**：`fsupdinf @ +0`、`nms @ +8`、`fsrc @ +16`、`cParas @ +32`、`sizeof = 40`。
**这只是预期，不许当依据**（`t127` 前例：偏移算错 8 B ⇒ 1129× `unknown-track-or-not-ours` 自伤；`t160` 的 `+16` 之所以算数，是因为它有**6 条 `_Static_assert` ＋ 字节级读回 ＋ 消费者行为**三形态实测）。实现件须给出同强度的实测读数，并与上式比对；不一致以实测为准。

---

## §2 靶心判词：**钥匙**（它是同一条路径上消费者的第一件东西），不是「其后」

**判词（本席，据 §1 现取）**：`FsQuerySubtrackDetails` 处在 `t160` 那条路径的**正下游第一格**：消费者一拿到可用段落列表、反查出 `BaseParaClient`，**第一件事**就是问它的 subtrack 详情；而 `t160` 点名的第二处（`ContainerParaClient.cs:289`）在控制流上**排在它之后**（由它的 `cParas` 门控）。

**逐跳链（全部本席现取，`文件:行`）**：

1. `PtsHelper.cs:134`（`ArrangeTrack`）或 `:225`（`UpdateTrackVisuals`）⇒ `ParaListFromTrack(...)` ⇒ `FsQueryTrackParaList`（**`t160` 打通的正是这一格**）。
2. `PtsHelper.cs:158` `HandleToObject(arrayParaDesc[index].pfsparaclient) as BaseParaClient`（t160 的第一处消费者位所在函数 `ArrangeParaList`）。
3. `PtsHelper.cs:179` `paraClient.Arrange(arrayParaDesc[index].pfspara, …)` ⇒ `BaseParaClient.cs:65 _paraHandle = pfspara;`（**`_paraHandle` 的来源就在同一张表里**，见 §4）。
4. `FlowDocumentPage.cs:547` `HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient`（**`t160` 点名的第一处消费者位**）⇒ `:549 paraClient.GetTextContentRange()`。
5. `ContainerParaClient.cs:260 GetTextContentRange()` ⇒ **`:271` `PTS.Validate(PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails));`** ← **本格靶心；body 内 Assert 之后的第一个实招**。
6. `:278` `if (subtrackDetails.cParas == 0 || (_isFirstChunk && _isLastChunk))` ⇒ **叶子分支**（`GetTextContentRangeForTextElement`，**不递归**）；否则 `:283 ParaListFromSubtrack(PtsContext, _paraHandle, ref subtrackDetails, out arrayParaDesc)`。
7. `PtsHelper.cs:633` `FsQuerySubtrackParaList(..., subtrackDetails.cParas, rgParaDesc, out paraCount)` ⇒ `:636 ErrorHandler.Assert(cParas == paraCount)`。
8. `ContainerParaClient.cs:289` `HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient`（**`t160` 点名的第二处消费者位**）⇒ `:294` 递归回 `GetTextContentRange()`。

**三条独立指示（合计判为钥匙）**：
- **控制流**：第 5 步在第 8 步**之前**，且第 8 步**被第 5 步的出参 `cParas` 门控**（`:278`）⇒ 无第 5 步则第 8 步不可达。
- **同名对**：`:271` 与 `:283` 是**成对**的两个入口（`FsQuerySubtrackDetails` 给元数据、`FsQuerySubtrackParaList` 给列表），与 track 面的 `FsQueryTrackDetails`/`FsQueryTrackParaList` 同构（`Pts.cs:3690-3700`）⇒ 本格是**这一对的头**。
- **计数 1:1**：`t160` 的 ENFE 条数与填充数**逐值相等**（引自 `t160`，本席未独立复算）⇒ 每填一次列表就换一次该入口的失败，**没有中间环节**。

**反面（「其后」候选，本席判为不成立）**：`FsQuerySubtrackParaList`（`:3742`）、`FsQuerySubtrackDetails` 的兄弟族（`FsQuerySubpageDetails` 等）都**在其后**：前者被 `cParas` 门控，后者属于别的支路（subpage/floater/table）。

⚠️ **定性边界（不许越读）**：本判词说的是「在 `t160` 这条路径上它是钥匙」。它与「它是不是**全站**下一跳」不是同一命题 ⇒ 后者见 §10。

---

## §3 签名与语义

### §3.1 native 侧现状：**符号不存在**（既非 `#if NEVER`、也非 stub）

本席现取：`grep -rn 'FsQuerySubtrackDetails' src/WpfGfx.Linux.Native/src/*.c` ⇒ **0 命中**；全 `src/WpfGfx.Linux.Native/`、`build/shims/`、`src/WpfGfx.Linux/` 内 subtrack 相关命中只有 §1 表末那条 `subtrack_methods`（原样存）。⇒ 今天该名的失败形态是 **CLR `EntryPointNotFoundException`（ENFE）**，与 `t160` 观测到的「`Unable to find an entry point named 'FsQuerySubtrackDetails'`」**同一形态**（读数引自 `t160`）。
⇒ **口径**：这不是「诚实 stub 返 `-10000`」，而是**缺符号**。两者在证据面**完全不同**：缺符号 ⇒ `Pts.cs` 的 `[DllImport]` 在**封送阶段**就抛，`PTS.Validate(...)` **根本不执行**（同族已由 `P1-ptsname-result.md` 在册：`t121` 的两种失败形态 (a)/(b)）⇒ 因此**不得**用「`rc=-10000` 的缺席」证明「链已通」，也不得用「ENFE 归零」单独当成功（那是 `N2` 面，不是内容面）。

### §3.2 形状与真实类型（逐字段）

| 项 | 声明（`Pts.cs:3736-3740` 现取） | 本席性质判定 | 依据 |
|---|---|---|---|
| `pfsContext` | `IntPtr` | **本侧 doc 上下文**（`wpf_pts_doc`） | `:3077` 族同形；`t151`–`t160` 链在册 |
| `pSubTrack` | `IntPtr` | ⚠️ **托管侧传的是 `BaseParaClient._paraHandle`**，而 `_paraHandle = FSPARADESCRIPTION.pfspara`（`BaseParaClient.cs:65` ＋ `PtsHelper.cs:179`）⇒ **语义上它是"段落实例"而不是"轨道"**（形参名与实参来源**不一致**，必须在实现里写明） | `ContainerParaClient.cs:271` 全部 9 处传 `_paraHandle` |
| `pSubTrackDetails`（out） | `FSSUBTRACKDETAILS` | 4 字段：`fsupdinf`(8B)／`nms`(句柄！见下)／`fsrc`(矩形)／`cParas`(**段落数**) | `Pts.cs:1527-1533` |
| `fsupdinf.fskupd` | `FSKUPDATGE : int` | **枚举**（`fskupdInherited=0/NoChange=1/New=2/ChangeInside=3/Shifted=4`） | `Pts.cs:1934-1941` |
| `nms` | `IntPtr` | **托管句柄**（"main text segment" 名），**不是裸指针** | `PtsHost.cs:414/:596` 两处 `HandleToObject(...)` 证明该族的"名"参数是句柄 |

---

## §4 诚实边界：**只靠上一跳的产出不够** —— 缺一个**新的上游对象**

**问题**：它能否只靠 `t160` 那条路径的产出（`+16` 区的 `pfsparaclient`／`nmp`）满足？

**判词：不能。** 三条现取：

1. **入参来源**：本入口唯一可能的实参是 `_paraHandle`（§3.2），而 `_paraHandle` **只**由 `BaseParaClient.Arrange(IntPtr pfspara, …)`（`BaseParaClient.cs:61-66`）赋值，实参是 `FSPARADESCRIPTION.pfspara`（`PtsHelper.cs:179`）。
2. **该字段今天恒 0**：`win32_pts.c:2957-2962` 现取：填充体 `memset` 之后**只写** `pfsparaclient` 与 `nmp` ⇒ **`pfspara` = 0**（与 `t160` 报告中「`pfspara` 留 0」的**同代互证**，该句引自 `t160`，本席未独立复算）。
3. ⇒ **即使把符号补上**，本入口在真腿上收到的 `pSubTrack` 也是 **NULL** ⇒ 诚实实现只能拒绝（`null-subtrack`）。
   ⚠️ 反过来说：`t160` 那句「消费者侧零新异常类」**不能**推出「subtrack 面已通」——今天它必然走到 `pSubTrack = 0`，只是**符号先缺失**，封送阶段就抛了，**没走到我们都读到的这一步**。

**⇒ 结论（本件最重要的排期判词）**：真正的下一跳是**一对**，缺一不可：
- **(a) 让 `pfspara` 成为本侧真对象**：native 必须自己拥有/分配一个"段落"对象，把它填进 `FSPARADESCRIPTION.pfspara`（`+8`，`_Static_assert` 已就位），并保证 `BaseParaClient.Arrange` 拿到的它**在下一次查询时仍活着**（持有期口径＝对象生存期；`t158` §2.1 在册）。
- **(b) `FsQuerySubtrackDetails` 对 (a) 的对象作答**：给 `fsupdinf`／`nms`／`fsrc`／`cParas`。
- **(b) 的 `cParas` 从哪来（诚实性问题）**：它必须等于**托管侧真实的孩子数**。native 今天**没有**这个事实 ⇒ 只能经**回调面**取得。而回调面**已经在手**：`FSIMETHODS`（17 槽，`Pts.cs:1204-1223`）由托管侧在 `PtsCache.cs:600-603` 填好，经 `CreateInstalledObjectsInfo` 交给 native，native 现取**原样存于** `win32_pts.c:469`（`t->subtrack_methods`，**一个字节都不 deref**）。
  ⇒ 因此 (b) 的**可满足路径**存在，但**代价**是：本侧必须真去**用**那张 17 槽表（今天只存不用），且要选准哪一槽能给出 `cParas`（`FSIMETHODS` 里**没有**名为 "get para count" 的槽 ⇒ 这一步是**新的设计缺口**，须由实现件先出**实测**的可用槽清单，或落下面的 `PRECOND-*`）。

**允许判「做不到」，但必须具名（命中任一即成立，须带现取证据）**：
- `PRECOND-NO-PARA-OBJECT`：若 (a) 无法在不越写域/不引入**不可回收泄露**的前提下给出 `pfspara` 真对象（例如本波写域内没有分配点、或对象一旦分配就没有在册的销毁口径）⇒ 判「做不到」。
- `PRECOND-NO-CPARAS-SOURCE`：若实现件**实测**无法从 `FSIMETHODS`（17 槽）中的任何槽、任何已有快照字段（`+16` 区／`wpf_pts_doc` 字段）取得**与托管孩子数一致**的 `cParas` ⇒ 判「做不到」，并把**候选槽清单与各槽实测形态**附上（★这是最可能出现的终点，**是合法终点**）。
- `PRECOND-NMS-UNOWNED`：若 `nms` 必须是一个**托管句柄**（§3.2）而 native 无法合法获得/持有它 ⇒ 判「做不到」。
- `PRECOND-NO-WINDOW-LEG`：若窗内外两腿只能跑一腿（§8 W-3）⇒ 该格 `NOINFO`。

---

## §5 判据（按 `N1–N4` ＋ 字段级诚实性）

### §5.1 成功语义（`fserr` 值域，禁双向滑移）

| 值 | 名 | 本件口径 |
|---|---|---|
| `0` | `fserrNone` | **成功**（仍须过 §5.2–§5.5；`rc=0` 本身**不是**内容证据） |
| `-100002` | `fserrCallbackException` | 托管回调内抛异常 ⇒ **必须留 `PtsContext.CallbackException` 文本**；⚠️ 至少两因（错型/未持有）⇒ 须成对对照 |
| `-10000` | `tserrNotImplemented` | **诚实未实现**。⚠️ **不得**把它当成今天的现状口径（今天是**缺符号**，§3.1） |
| 其它 | 未在册 | **非成功且未分类** ⇒ 具名单列，不许归入上三类 |

### §5.2 出参非零（**零值不是中性默认**）

- `cParas`：`0` 是一个**语义断言**（"此容器无子段"），`ContainerParaClient.cs:278` 会因它**改走叶子分支、不再递归** ⇒ **`cParas=0` 不是安全缺省，而是一次会改变控制流的声明**。
  ⇒ 判据：`cParas=0` **只在容器确实为空时有据可立**；本轮的真腿（`nmp`／`h0` 链已证容器存在嵌套关系）出现 `cParas=0` ⇒ 直接判红（**P8**）。**绝不许**用 `cParas=0` 让 `rc=0` 好看。
- `fsrc`：不得为零矩形而同时声称有内容（与 `cParas>0` 矛盾 ⇒ 判红）。
- `nms`：**句柄**；`0` ⇒ 视为未持有/未填（**不是**"零号句柄"），见 P2。

### §5.3 **连调是否幂等 —— 必须现取判定，禁沿用前几跳**

`t154` 的教训在册：`+176 CreateParaclient` **不幂等**（10 处 override 各 `new *ParaClient(this)`）；`t151` 的 `+80 GetMainTextSegment` 则是**懒建**。⇒ **本格不得沿用任何前跳结论**，必须用**双调实验**现取：

```
rc_a = FsQuerySubtrackDetails(ctx, pSubTrack, &d_a)
rc_b = FsQuerySubtrackDetails(ctx, pSubTrack, &d_b)
判据：idem = (rc_a == rc_b) ∧ (d_a.cParas == d_b.cParas) ∧ (d_a.nms == d_b.nms) ∧ (memcmp(&d_a.fsrc,&d_b.fsrc)==0)
```
`idem=1` ⇒ 判「幂等」；`idem=0` ⇒ 判「非幂等」，并**具名到哪一字段变了**；**两读都要在册**（禁只报一个）。⚠️ 幂等**不是**成功条件（非幂等也可以是正确实现），但**必须**有一句现取判词。

### §5.4 身份可检（承 `t130` ／ 裁定二十七 ／ `t160` 的 ABA 教训）

- **禁令（写死）**：**身份类判据不许依赖 `rc`，也不许依赖数值大小**。`t160` 的 ABA 反腿已证 `rc` 无法区分对象身份（读数引自 `t160`：`released_between=1 stale=0x5 fresh=0x5 same_value=1 rc=0`，本席未独立复算）。
- **判别只能靠「来源证据」**：同一 run 内「本入口收到的 `pSubTrack`」必须与「产出它的那一行」**同值**（例：`[DRIVE-PROBE3] … keep=<h>` 与后续 `pSubTrack=<h>` 同值；或 `[FSPARALIST-FILL] h0=<h>` 与 `paraClient.Arrange` 传入的 `pfspara` 同值）。
- **身份可检的最小形态**：`pSubTrack` 必须能被本文档 §4(a) 的对象台账**唯一**认领；认领失败（未知/已回收/被复用）⇒ 判红（P4）。

### §5.5 下游接受用哪个槽/哪个消费者

- **第一接受者（必选）**：`ContainerParaClient.GetTextContentRange()` 的 `:271`（**9 处**同族任一皆可，但须具名是哪一处：`文件:行`）。
- **第二接受者（必选）**：`PtsHelper.cs:283`→`:633` 那一对（`FsQuerySubtrackParaList`）——**本轮不要求它返 0**，但要求**证据上能看出控制流是否走到它**（例：该入口的调用计数/留痕），因为它是 `:289` 递归的**唯一入口**，决定「subtrack 面是否已真正推开一格」。
- **依据**：§2 的 §1–§8 逐跳链（`PtsHelper.cs:179` → `BaseParaClient.cs:65` → `ContainerParaClient.cs:271` → `:278` 门控 → `:283` → `:289`）。
- **不计入接受的**：`+200 FInterruptFormattingAfterPara`（stub，不读字段 ⇒ 恒绿，**禁用**）、`+56 GetNextSection`（by-design ⇒ 恒绿，**禁用**）。

---

## §6 假进度必红 `P1..P12`

- **P1** `fserr` 非零被读成成功（含把 `-10000`/`-100002` 记成"通过"）。
- **P2** 零句柄当活：把 `nms=0`／`pSubTrack=0` 当"有效零号句柄"（本仓的"名"参数是**句柄不变量 0<h<len**，0 非法）。
- **P3** **native 自造**：给 `nms`／`pfspara` 填本侧凭空造的指针/小整数而不持有其对象（`t127`／`t158`-P3 前科）。
- **P4** **回收后／复用后继续用**：`t160` 已证 `rc` 与数值**都无法**区分身份 ⇒ 必须靠**来源证据**；`pSubTrack` 在两次调用之间被回收（或索引被复用）而继续用 ⇒ 一票红。
- **P5** 「槽被调用」当「链已通」（用调用计数/ENFE 归零冒充实通；`N2` 面 ≠ 内容面）。
- **P6** 伪值代替 T3（把 T3 腿／夹具形态当主链读数；详见 §7）。
- **P7** 主链 `FailFast`（`Invariant.Assert` 不可捕获 ⇒ 进程死；`t160` 的 `SELFRECYCLE` 反腿 `app_rc=134` 在册）。
- **P8** **`cParas=0` 恒绿陷阱**（§5.2：返回 0 让 `rc=0` 好看而把嵌套内容整体静默丢掉的形态）。
- **P9** 单样本当机制（裁定三十八：机制级断言 ≥2 独立样本，判定须相同）。
- **P10** 恒定绿判别器（`+200`、`+56` 前科；以及"只跑一腿就宣布窗口无关"，见 §8 W-3）。
- **P11** 跨代相减／搬上一代列印（纪律三十：读数无当次三格即无效）。
- **P12** 把 `NOINFO` 写成绿，或用 `PRECOND-*` 替代**本可跑却没跑**的腿。

---

## §7 T3 口径（**本席现取更正**）与零假值铁律

### §7.1 更正：`0x1..0x5` 是**真句柄/索引**，不是假值

任务书给的哨兵表是 `sect=0x1`／`nms(nmSegment)=0x2`／`nmp=0x3`／`h1=0x4`／`h2=0x5`。本席现取三处，判其**性质**为：**这些是同一 run 内按创建次序得到的托管"名"（句柄）的小整数值，是真值，不是伪造值**：

- `PtsCache.Linux.cs:523`（我方，sha16 `48cf0d8d7d1a90dd`）：`InitGenericInfo(ptsHost, (IntPtr)(index + 1), …)` ⇒ `pfsclient` ＝ 池下标＋1 ⇒ **小整数是合法真值**。
- `PtsHost.cs:414`／`:596`：`HandleToObject(nmsSection) as Section`／`HandleToObject(nms) as ISegment` ⇒ 该族的"名"参数**就是托管句柄**。
- `PtsHost.cs:785`＋`t158` §2.1 在册：句柄是**表下标**，`HandleToObject` 断言 `0 < h < _unmanagedHandles.Length`。

⇒ **口径收紧（替换掉"数值命中即作废"的写法）**：
1. **不许**用「值等于 `0x1..0x5`」判定真腿/假腿——合法真腿完全可能出现这些值（尤其表小时）。
2. **判别一律靠来源**：该句柄必须能与**同一 run 内的一行产出证据**（`[DRIVE-PROBE3] … keep=`／`h1=`／`h2=`，或 `[FSPARALIST-FILL] h0=`）**同值对上**；对不上 ⇒ 该读数作废（具名）。
3. **禁**把哨兵当作"我们见过的旧值"来比对（跨代无意义，纪律三十）。

### §7.2 T3 腿在**本跳**的正确用法

现取 `win32_pts.c:1109-1113`／`:1198-1206`：T3 模式（`WPF_PTS_DRIVE_PROBE_FAKE_NMS=-2`）今天做的是**用真但错类型的 live 句柄**去触发可捕获的 `-100002`。⇒ 对本跳：
- **T3 腿可以做的**：用「真但错类型」的句柄当 `pSubTrack`（例如把某个 `Section` 句柄喂进来），**验证拒绝面**（必须 `rc≠0` 且**留痕**，不得 `FailFast`）。这一条是**本跳 T3 才有意义**的用法。
- **T3 腿不许做的**：充当"填充成功"的证据；其内容面一律 `NOINFO`（沿用 `t158` §6）。
- **主链（真腿）内出现任何**「真但错类型」形态 ⇒ 该读数作废。

### §7.3 零假值铁律（本跳版）

- 任何被写入 `FSSUBTRACKDETAILS` 的 `nms`／`fsrc` 必须**指向/来自本侧真持有的对象或真读到的托管快照**；不得为了"非零"而写常量。
- 假值（若有反腿）只许注入到**不经过** `HandleToObject` 的路径（凡到达即 `Invariant.Assert` ⇒ `FailFast` 不可捕获）。
- `cParas` 必须等于**托管真值**；**不许**用常量（含 `1`）作"可运行性"证明。

---

## §8 绿的正确读法（逐字写死）

实现件必须让装置**逐字**打印下面这族行（token 顺序固定、`=` 两侧无空格；允许行尾追加新 token，**不许**删改名；确需改名先由队长改本件）：

**成功行**
```
[FSQSTD] rc=0 reason=ok entry=FsQuerySubtrackDetails ctx=<hex> psub=<hex> src=<来源标记> cParas=<n> nms=<hex> fskupd=<k> dvrShifted=<d> fsrc=<u>,<v>,<du>,<dv> idem=<0|1> win=<in|out> run=<标记> calls=<n>
```
**拒绝行（失败专用，只在拒时出现）**
```
[FSQSTD] rc=<int> reason=<具名> entry=FsQuerySubtrackDetails ctx=<hex> psub=<hex> calls=<n>
```
**来源行（身份证据，必需）**
```
[FSQSTD-SRC] psub=<hex> from=<DRIVE-PROBE3.keep|FSPARALIST-FILL.h0|...> same_value=<0|1> run=<标记>
```
**「绿」＝同时满足全部 8 条**（缺一即不绿）：
1. `rc=0`；
2. `psub != 0` **且** `[FSQSTD-SRC] same_value=1`（**来源证据**，§5.4）；
3. `cParas` 与该容器在托管侧的真值一致（**须由消费者行为或托管侧读数佐证**；容器有嵌套时 `cParas>0`）；
4. `nms != 0` 且其来源可认领（§7.3）；`fsrc` 非零矩形；
5. 控制流证据：**能看出**消费者走到了 `:278` 之后（即 `ParaListFromSubtrack`／`FsQuerySubtrackParaList` 的调用面出现）——**或**明确记 `NOINFO`（不许默绿）；
6. 本腿 `failfast=0`、`wrong-object=0`、未分类 `rc=0` 条数 0；
7. **≥2 独立样本**（不同 PID/启动时刻）判定**相同**；不同 ⇒ 判"不稳定" ⇒ 降 `NOINFO` 并在册；
8. 每条读数带齐**纪律三十三格** ＋**探针闸状态**（`WPF_PTS_DRIVE_PROBE=`／`_N=`／`_FAKE_NMS=`／`WPF_PTS_DRIVE_PROBE3_T3=`）。

**窗内外两腿（W-1／W-2）**：`win=in` 与 `win=out` 两腿都要给（沿用 `t151` 在册的 OOW 装置）；**W-3：只能跑一腿 ⇒ 该格 `NOINFO`**，禁宣布"窗口无关"。两腿结论不一致 ⇒ 判「窗口敏感」并具名到 reason。

**纪律三十三格（每条读数必附）**：①进程新鲜度（PID＋启动时刻＋完整命令行）；②所依赖计数器（`calls=`／该入口计数／ENFE 计数**按名**）；③`rc`·`diag` **原文**（不转述，含 `reason=` 与 `CallbackException` 文本若有）。

---

## §9 `NOINFO` 面

`NOINFO` 既不算绿也不算红。本跳的典型 `NOINFO` 面：
- 闸关（`[DRIVE-PROBE-SKIP] reason=gate-off`）⇒ 全部格 `NOINFO`（**不得**用该行的缺席反推"跑过"）。
- 只跑一腿（W-3）；单样本；消费者未到达（须以**成功行/计数**证，不得以失败专用行的缺席证）。
- `FsQuerySubtrackParaList` 之后的内容面（`t160` §:161 在册 `NOINFO`，本跳**不撤销**该结论）。

---

## §10 排期含义：**是 W8 主线的下一跳**，但靶心是**一对**，不是单独一格

- **是下一跳**（依据：§2 三条独立指示 ＋ `t160` 的 1:1 计数 ＋ HEAD `76884d5` 的裁定四十七明写「下一跳靶心 `FsQuerySubtrackDetails`」）。
- **「做成什么才算推进一格」**（本席口径，按 §4 拆开）：
  1. **先做 (a)**：`FSPARADESCRIPTION.pfspara` 在真腿上**非零且可认领**（有本侧对象台账，且能在下一次消费者帧里被 §5.4 的来源证据认领）。**没有 (a)，(b) 必然只能拒绝。**
  2. **再做 (b)**：`FsQuerySubtrackDetails` 对 (a) 的对象作答，且 `cParas` 与托管真值一致、`nms` 为非零**托管句柄**、`fsrc` 非零矩形、`rc=0` 有 §8 八条全中。
  3. **两者合起来才把 `ContainerParaClient.cs:271` 这一格推开**；`:283`／`:289`（`FsQuerySubtrackParaList` 及其后的递归）**是下一格**，本跳只需给出**控制流证据**或 `NOINFO`。
  4. **代价必须先估清**：`nms` 是**托管句柄**（§3.2）⇒ 若本侧无法合法取得/持有它 ⇒ 立刻走 `PRECOND-NMS-UNOWNED`，**不许**拿本侧对象冒充句柄。
- **若判定「不是下一跳」的替代**：本席现取**没有**支持该替代的证据；若实现件实测出 §4 的 `PRECOND-NO-CPARAS-SOURCE`（`FSIMETHODS` 无可用槽），则下一跳应改判为**「按 `FSIMETHODS` 17 槽做一次可用性实测」**（轻量侦察格），**先立靶再实现** —— 这也是本件允许的合法终点。

---

## §11 本件自身的验收（本件如何被复核）

1. 新件；末行＝自证行（`head -n -1 <本件> | sha256sum | cut -c1-16`）；mode `644`；首 token ＝ `# P1-W81 `。
2. 复核者须**独立重取** §1 表内至少 6 件的 sha16 与引用行（`sed -n` 打原文）并比对；不一致处**只增不改**地追加。
3. 本件**未**授权任何判据放宽；实现件与本件冲突 ⇒ 冲突进裁定，不许就地解释。
4. 本件不含腿读数；所有他人读数均标「引自 …，本席未独立复算」；`t160` 的**末行自证**本席**当场复算过**（MATCH=yes）——这属代际核对，不构成对其内部读数的复算。

---

## §12 附录：现取原文摘录（仅本次有效，读取时刻 2026-09-29 18:11–18:14）

`Pts.cs:3736-3747`（sha16 `1a8575a18767a956`）：
```
        [DllImport(DllImport.PresentationNative)]
        internal static extern int FsQuerySubtrackDetails(
            IntPtr pfsContext,                  // IN:  ptr to FS context
            IntPtr pSubTrack,                   // IN:  ptr to subtrack
            out FSSUBTRACKDETAILS pSubTrackDetails);// OUT: subpage details

        [DllImport(DllImport.PresentationNative)]
        internal static extern unsafe int FsQuerySubtrackParaList(
            IntPtr pfsContext,                  // IN:  ptr to FS context
            IntPtr pSubTrack,                   // IN:  ptr to subtrack
            int cParas,                         // IN:  size of array of para descriptions
            FSPARADESCRIPTION* rgParaDesc,      // OUT: array of para descriptions
            out int cParaDesc);                 // OUT: actual number of paragraphs
```
`Pts.cs:1527-1533`（同件）：`FSSUBTRACKDETAILS { FSUPDATEINFO fsupdinf; IntPtr nms; FSRECT fsrc; int cParas; }`
`ContainerParaClient.cs:271-283`（sha16 `0d2e6aa79fdc035a`）：
```
            PTS.Validate(PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails));
            …
            if (subtrackDetails.cParas == 0 || (_isFirstChunk && _isLastChunk))
            {
                textContentRange = TextContainerHelper.GetTextContentRangeForTextElement(elementOwner);
            }
            else
            {
                PtsHelper.ParaListFromSubtrack(PtsContext, _paraHandle, ref subtrackDetails, out arrayParaDesc);
```
`PtsHelper.cs:623-636`（sha16 `f2ed9552e983fed1`）：`ParaListFromSubtrack` 用 `subtrackDetails.cParas` 开数组 ⇒ `FsQuerySubtrackParaList(..., subtrackDetails.cParas, rgParaDesc, out paraCount)` ⇒ `ErrorHandler.Assert(subtrackDetails.cParas == paraCount, ErrorHandler.PTSObjectsCountMismatch);`
`BaseParaClient.cs:61-65`（sha16 `e48fc11de3f65d09`）：`internal void Arrange(IntPtr pfspara, …)` ⇒ `Debug.Assert(_paraHandle == IntPtr.Zero || _paraHandle == pfspara); _paraHandle = pfspara;`
`PtsHelper.cs:179`（同件）：`paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);`
`win32_pts.c:2957-2964`（sha16 `c90a78af8bc9499c`，**在飞**）：`memset((void *)&rg[i], 0, sizeof(rg[i])); rg[i].pfsparaclient = (void *)dp->fsp_pl_cur; rg[i].nmp = (void *)dp->drive_nmp;` ⇒ **`pfspara` 未写，保持 0**
`win32_pts.c:469-471`（同件）：`t->subtrack_methods = fssubtrackparamethods; /* 原样存，不 deref */`、`t->entries = 2; /* subtrack + subpage 两槽（真值） */`

---

**判词（本席）**：① `FsQuerySubtrackDetails` 判为 `t160` 路径上的**钥匙**（三条独立指示，§2）；② 现状＝**符号不存在**（缺符号面，非 stub，§3.1），故「`rc=-10000` 的缺席」不构成任何证据；③ 诚实边界判为**只靠上一跳产出不够**——`pSubTrack` 只可能来自 `FSPARADESCRIPTION.pfspara`，而该字段今天**恒 0**（§4）⇒ 真正的下一跳是 **(a) `pfspara` 真对象 ＋ (b) 本入口作答** 这一对，其中 (b) 的 `cParas` 需经 `FSIMETHODS`（native 已原样持有）取得，**若无可用槽即为合法终点**（`PRECOND-NO-CPARAS-SOURCE`）。④ 身份判别**只许靠来源证据**（`t160` 的 ABA 反腿已证 `rc` 与数值都无判别力），且 **`cParas=0` 是语义断言而非安全缺省**（会改变控制流，§5.2）。本席**不主张**本跳已成绿：本件只负责把「绿」定义到能被独立复核的程度。
`P1-subtrack-criteria 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 7dcd11d7f0afa065（末行＝本行）`

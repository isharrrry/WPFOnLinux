# P1-W89 判据（先写）：`FsFormatSubtrackFinite` 一族入参契约 ＋ 最小可行子集

本件是**只读侦察／判据先写**件（`work` 类）：给「族」的边界、逐入参的**作者性判定**、以及**最小可行子集**与它的成功/失败判据。
**本件只读，不实现、不跑腿、不构建、不占显示位、不改任何代码**；无运行期腿读数；引他人读数一律带代际并标「引自 X，本席未独立复算」。

---

## §0 身份、边界与在飞件

- 载体：`build/MilBridge/P1-fsformatsubtrack-recon.md`（**新建**）。写者＝`scout`；写入面**仅本件**，`$N` 内其余件**一件未改**。
- 结论**只许收紧**；放宽须队长出裁定并在册。
- ⚠️ **在飞件**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 开工现取 **`sha16=6d6f753105224f78`／319005 B**（mtime 18:59:08；与 `t168` 交出的 `2ba175a41ff7855b` **不同** ⇒ 已换代）⇒ 本件对他的引用**行号只在该代有效**；实现/复核者开工前**必须重取**。

---

## §1 现取台账（读取时刻＝2026-09-29 19:03–19:10，本席本地，仅本次有效）

| 件 | sha16 | 用途 |
|---|---|---|
| `PtsHost/Pts.cs` | `1a8575a18767a956` | 本族声明（`:3318`／`:3344`／`:3367`…）、`FSFMTR`(`:1141-1146`)／`FSFMTRKSTOP`(`:1121-1140`)／`FSFMTRBL`(`:1147-1152`) |
| `PtsHost/ContainerParagraph.cs` | `1d0128592496706d` | **三个造型入口的调用点与出参用法**（`:526-531`／`:664-668`／`:788-792`；出参读取 `:550-596`） |
| `PtsHost/PtsHost.cs` | `d1976dcc8362c8f9` | 槽 3 的托管实现 `SubtrackFormatParaFinite`（`:2662` 起）与 `catch → fserrCallbackException` |
| `PtsHost/PtsContext.cs` | `c91e3f94d1188ece` | `:405 internal Exception CallbackException`（**异常类型可读**） |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `6d6f753105224f78`（319005 B） | 本族 native 现状、`wpf_pts_sub_handle`(`:1207`)／`wpf_pts_sub_claim`(`:1212`)、家族码（`:1452-1459`）、`FSPARADESCRIPTION.pfspara` 的现取来源（`:3496`） |
| `build/MilBridge/P1-pfspara-report.md`（`t162`） | 155 行；末行自证 `e311486fee8fdb2e`（**本席当场复算 MATCH=yes**；内部读数未复算） | `(a)` 已落：`pfspara` ＝ 本侧自有、可认领对象 |
| `build/MilBridge/P1-fsimethods-drive-report.md`（`t168`） | 107 行；末行自证 `a6d7a4bc641f3e80`（**本席当场复算 MATCH=yes**；内部读数未复算） | `D2=SLOT-ORDER-OK`／`D3` 槽 1 `rc=0 sobjc=0x1b63=idobj(7001)+10`／槽 3 `rc=-100002`／`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` |
| `build/MilBridge/P1-format-frame-recon.md`（`t164`，本席前件） | 241 行；自证 `9440f52aaecb1304` | 准入铁律「准入＝本侧是该值的作者」 |
| `build/MilBridge/P1-fsimethods-abi-recon.md`（`t166`，本席前件） | 208 行；自证 `35041d7b492824b0` | 表/缓冲/槽序结论（D1/D2/D3 设计） |

---

## §2 「族」的边界

### §2.1 全族 16 名（`Pts.cs` 内 `Fs*Subtrack*` 唯一名去重现取，`t163` 给定 ＋ 本件复核声明位）

**造型类（3 条，本件靶心）**

| 成员 | 声明位 | native 现状（现取） | 托管调用点（逐字） |
|---|---|---|---|
| `FsFormatSubtrackFinite` | `Pts.cs:3318-3342` | ❌ **未实现**（`grep -n 'FsFormatSubtrack' src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **仅 `:1152` 一条注释**；native 内 `Subtrack` 全代命中 **3** 处，无实现） | `ContainerParagraph.cs:526-531`（`FormatParaFinite` 内） |
| `FsFormatSubtrackBottomless` | `Pts.cs:3344-3366` | ❌ 同（未实现） | `ContainerParagraph.cs:664-668`（`FormatParaBottomless` 内） |
| `FsUpdateBottomlessSubtrack` | `Pts.cs:3367-3389` | ❌ 同（未实现） | `ContainerParagraph.cs:788-792`（`UpdateBottomlessPara` 内） |

**其余 13 名（非造型，属"其后"）**：`FsSynchronizeBottomlessSubtrack`(`Pts.cs:3390`)、`FsCompareSubtrack`(`:3398`)、`FsClearUpdateInfoInSubtrack`(`:3407`)、`FsDestroySubtrack`(`:3412`)、`FsDuplicateSubtrackBreakRecord`、`FsDestroySubtrackBreakRecord`、`FsGetSubtrackColumnBalancingInfo`、`FsGetNumberSubtrackFootnotes`、`FsGetSubtrackFootnoteInfo`、`FsShiftSubtrackVertical`、`FsTransferDisplayInfoSubtrack`(`:3469`)、`FsQuerySubtrackDetails`(`:3736`)、`FsQuerySubtrackParaList`(`:3742`)。
⇒ 现取判定：**native 侧对这 16 名一条都没实现**（同一 `grep` 全族 0 命中实现体）。

### §2.2 三个造型入口的**实参逐字**（本件亲自 `awk` 行级现取）

- **`FsFormatSubtrackFinite`**（`ContainerParagraph.cs:526-531`）：
  `(PtsContext.Context, pbrkrecIn, fBRFromPreviousPage, this.Handle, iArea, footnoteRejector, geometry, fEmptyOk, fSuppressTopSpace, fswdirSubtrack, ref fsrcToFillSubtrack, (mcsContainer?.Handle ?? IntPtr.Zero), fskclearIn, fsksuppresshardbreakbeforefirstparaIn, out fsfmtr, out pfspara, out pbrkrecOut, out dvrUsed, out fsbbox, out pmcsclientOut, out fskclearOut, out dvrSubTrackTopSpace)`
- **`FsFormatSubtrackBottomless`**（`:664-668`）：
  `(PtsContext.Context, this.Handle, iArea, geometry, fSuppressTopSpace, fswdirSubtrack, urSubtrack, durSubtrack, vrSubtrack, (mcsContainer?.Handle ?? IntPtr.Zero), fskclearIn, fInterruptable, out fsfmtrbl, out pfspara, out dvrUsed, out fsbbox, out pmcsclientOut, out fskclearOut, out dvrSubTrackTopSpace, out fPageBecomesUninterruptable)`
- **`FsUpdateBottomlessSubtrack`**（`:788-792`）：
  `(PtsContext.Context, pfspara, this.Handle, iArea, pfsgeom, fSuppressTopSpace, fswdirSubtrack, urSubtrack, durSubtrack, vrSubtrack, (mcsContainer?.Handle ?? IntPtr.Zero), fskclearIn, fInterruptable, out fsfmtrbl, out dvrUsed, out fsbbox, out pmcsclientOut, out fskclearOut, out dvrSubTrackTopSpace, out fPageBecomesUninterruptable)`

⚠️ **过程自陈（同时是本件要传下去的一条纪律）**：本席**首读** `:526-531` 时用了 `cut -c1-120` ⇒ 把行尾的 `, iArea,` 截掉，一度读成"实参与声明错位"。⇒ **引"调用点实参表"这类跨行结构，必须整行取**（`awk` 行级），**不许截列**；本件后续引用一律整行。

---

## §3 入参契约 ＋ 逐项作者性判定（裁定五十一 (b) 铁律：**准入 ＝ 本侧是该值的作者**）

以 `FsFormatSubtrackFinite` 为准（另两成员为该表的**真子集/超集**：`Bottomless` 无断页记录入参、`Update` 多一个 `pfsSubtrack` 入参、出参类型 `FSFMTRBL`）。

| # | 入参（声明原文语义） | 托管侧实参 | 类别 | **本侧能否作为作者** | 判定依据 |
|---|---|---|---|---|---|
| 1 | `pfsContext` FS 上下文 | `PtsContext.Context` | 本侧对象 | ✅ **能**（本侧是自己上下文的作者） | `t151`–`t168` 全链在册；`wpf_pts_doc_find` 家族谓词 |
| 2 | `pfsBRSubtackIn` 断页记录（"if pointer to break rec is NULL" 时改用下一条） | `pbrkrecIn` ← 槽 3 的 `pfsobjbrk`（`Pts.cs:2711`「**use if !NULL**」）⇒ **首调可为 NULL** | 本侧对象/0 | ✅ **能（可选）**：首调合法用 `NULL`；本侧若给值，须是**本侧可认领**的断页记录 | §4 |
| 3 | `fFromPreviousPage` 断页记录来自上一页 | `fBRFromPreviousPage` | 布尔 | ✅ **能**（本侧自选，与 #2 一致即可） | `t165` 之作者性声明体例 |
| 4 | `fsnmSegment` 起始段之名 | **`this.Handle`**（`ContainerParagraph` 的**托管句柄**） | **宿主句柄** | ⚠️ **不是本侧产出**：它是**入站给的**，本侧只"消费" | `ContainerParagraph.cs:526` 现取；`PtsHost.cs:2695-2697` 对同族 `nmp`/`pfsparaclient` 做 `HandleToObject` |
| 5 | `iArea` 列跨度区索引 | `iArea` | 整数 | ✅ **能**（本侧自选） | 同上 |
| 6 | `pfsFtnRej` | `footnoteRejector` | 宿主对象 | ⚠️ **入站给的**（本侧不必是作者；**能否为 NULL 仓内未见依据** ⇒ `NOINFO-FTNREJ-NULLABILITY`） | `t165` 对同项已记"只做实验、不断言" |
| 7 | `pfsGeom` 几何 | `geometry` | **本侧自有对象** | ✅ **能**（`t164` §3 已判：宿主只中转不解引用 ⇒ 引擎即作者） | `t164` 载体 §2.1／§3 |
| 8 | `fEmptyOk` | `fEmptyOk` | 布尔 | ✅ **能** | `t165` |
| 9 | `fSuppressTopSpace` | `fSuppressTopSpace` | 布尔 | ✅ **能** | `t165` |
| 10 | `fswdir` 方向 | `fswdirSubtrack` | 位域 | ✅ **能** | `t165` |
| 11 | `fsRectToFill` 待填矩形（`[In] ref`） | `ref fsrcToFillSubtrack`（＝`FSRECT`） | 本侧矩形 | ✅ **能**（本侧页几何 `win32_pts.c:290`/`:352`/`:3052` ＝ 768×576） | `t164` |
| 12 | `pfsMcsClientIn` 入边距塌陷状态 | `(mcsContainer?.Handle ?? IntPtr.Zero)` | **宿主句柄或 0** | ⚠️ **入站给的**；**0 是托管侧显式允许**（`?: IntPtr.Zero`） | `ContainerParagraph.cs:528` 现取 |
| 13 | `fsKClearIn` | `fskclearIn` | 枚举 | ✅ **能**（本侧自选） | `t165` |
| 14 | `fsksuppresshardbreakbeforefirstpara` | 同名 | 标志 | ✅ **能** | `t165` |

**出参（6 个）**：`pfsfmtr`（为什么停）、`ppfsSubtrack`（**子轨指针**）、`pfsBRSubtrackOut`（子轨断页记录）、`pdvrUsed`、`pfsBBox`、`ppfsMcsClientOut`、`pfsKClearOut`、`pTopSpace`。

**🔴 关键问题的正面回答（任务 §2 特别问）**：**`pfspara` 出参 ＝ 本侧要填的那个出参，且与 `FSPARADESCRIPTION.pfspara` 是同一对象种类**：
- `FsFormatSubtrackBottomless` 的 `out pfspara`（`:667`）与 `FsUpdateBottomlessSubtrack` 的 **`pfspara` 入参**（`:788`）是同一个名字 ⇒ 引擎交出的子轨对象会被**回传**给引擎；
- `FSPARADESCRIPTION.pfspara` 今天由本侧填（`win32_pts.c:3496 para_val = wpf_pts_sub_handle(dp->sub);`，`t162` 的代际）⇒ 同一对象；
- ⇒ 本族的 `ppfsSubtrack` **就是** `t162` 已落地的那枚"本侧自有、可认领"的对象 ⇒ **不需要新对象种类**，只需要**新入口**把它正确地"交出去"。

---

## §4 **断页记录是否要求承载内容？**（任务 §2 的关键问）

**判词：在本族现取的消费面上，断页记录只需要"可为 0 或本侧可认领的值"，不要求承载内容；但一旦要"承接下一页"，内容就必须真承载。**

依据（**逐条现取**）：
1. **入参侧**：首调契约允许 `NULL`（`Pts.cs:2711`「use if !NULL」；`:3322`「if pointer to break rec is NULL」改用 `fsnmSegment`）⇒ **首调不需要任何断页记录**。
2. **出参侧（finite 路径）**：`ContainerParagraph.cs:596` 只做**零比较** —— `paraClient.SetChunkInfo(pbrkrecIn == IntPtr.Zero, pbrkrecOut == IntPtr.Zero);` ⇒ **本路径不解引用其内容**。
3. **页级先例**：`t165`/`t164` 现取——本侧 `*ppfsBRPageOut = (void *)&p->c_paras;`（**字段地址别名、不承载内容**）已被 `FsQueryPageDetails`/`FsCreatePageFinite` 链接受 ⇒ **同族做法在册**。
4. ⚠️ **但代价具名**：那条别名**不承载"断页状态"**（`c_paras` 的语义是"段数"）⇒ 一旦本侧要**跨页续排**（把 out 值当下一调的 in 值使用并据此决定"从哪继续"），**内容诚实性立刻变成硬要求**。⇒ 记为 **`NOINFO-BREAKREC-CONTENT`**（今天既无内容字段，也无消费点）。

---

## §5 最小可行子集（本件核心产出）

### §5.1 靶心定义：**只做 `FsFormatSubtrackFinite` 一条**，且只做到 **`M1：诚实无进展`**

**为什么是它**：`t168` 的 `D3` 走的是**槽 3**（`ObjFormatParaFinite`）⇒ 托管链 `PtsHost.SubtrackFormatParaFinite`（`:2662`）→ `ContainerParagraph.FormatParaFinite`（`:438`）→ **`Pts.Host` 回头调 `FsFormatSubtrackFinite`（`:526`）** ⇒ **链上唯一缺的 native 入口就是它**。
（`FsFormatSubtrackBottomless` 属**另一条链**（槽 4 / `FormatBottomless`），`FsUpdateBottomlessSubtrack` 属**更新链**（槽 5）⇒ 都**不在** E2 的最小集内。）

**`M1` 的最小内容（逐项可判）**：
1. **入参校验（保守）**：`pfsContext` 在册（`wpf_pts_doc_find`）；`fsnmSegment`／`pfsFtnRej`／`pfsMcsClientIn` 一律**当不透明入站值、只记不判**（⚠️ 见 §5.3 的能力缺口）。
2. **出参（逐项"不许沉默"）**：
   - `pfsfmtr` **必须显式写**：`kstop = fmtrNoProgressOutOfSpace`(=8) 或同族 no-progress 值，`fContainsItemThatStoppedBeforeFootnote = 0`，`fForcedProgress = 0`；
     🔴 **依据**：`FSFMTRKSTOP.fmtrGoalReached = 0`（`Pts.cs:1123`）⇒ **零填充的 `FSFMTR` 会被宿主读成"这一段排完了"**（`ContainerParagraph.cs:565` `if (fsfmtr.kstop == fmtrGoalReached) { …CollapseBottomMargin…; dvrUsed += marginBottom + mbp.BPBottom; }`）⇒ **留 0 不是"中性缺省"，而是一句假话**。
   - `ppfsSubtrack` ＝ 本侧自有对象（`wpf_pts_sub_handle(dp->sub)`，家族码 `'E'`，认领谓词 `wpf_pts_sub_claim`，`win32_pts.c:1207`/`:1212`/`:1458`）。
   - `pdvrUsed = 0`（与 no-progress 自洽）；`pfsBBox` ＝ **平/空**且与本侧矩形记账一致（**不得**声称内容）；`pTopSpace = 0`（且 `< PTS.dvBottomUndefined / 2`，见 `ContainerParagraph.cs:540` 的 workaround）。
   - `ppfsMcsClientOut = 0`：🔴 **必须 0** —— 非 0 会被宿主 `HandleToObject(pmcsclientOut) as MarginCollapsingState`（`:558-561`）解引用 ⇒ 非托管句柄 ⇒ 不可捕获 `FailFast` 风险。
   - `pfsBRSubtrackOut = 0`（"未继续"＝真话；契约只做零比较，见 §4）。
   - `pfsKClearOut` ＝ 保守透传（**不许**自造枚举值）。
3. **失败面**：任何拒绝 ⇒ **返非 0 ＋ 具名留痕**（沿用本仓纪律：不许静默 stub）。
4. **留痕必须具名"我们没造型"**：例如 `[FSFORMATSUBT-CALL] … kstop=8 reason=no-layout-model …`，**不许**只打 `rc=0`。

### §5.2 成功／失败判据（可证伪；**判断词与"造型成功"严格分开**）

- **S-1 契约成功（`M1` 的判词）**：槽 3 链**不再返 `-100002`**，且驱动格读数满足：
  ① `rc=0`；② `ppfsSubtrack` **被改写且可认领**（`wpf_pts_sub_claim` 为真）；③ `fsfmtr.kstop` ∈ no-progress 族（**非 0**）；④ `dvrUsed=0`；⑤ `mcsOut=0`；⑥ 留痕行含具名 reason；⑦ **≥2 独立样本判词相同**（裁定三十八）。
  ⇒ 判词写法：**"`M1` 契约占位成立（honest no-progress）"**。
- **S-2 造型成功（本波**不**冒犯的判词）**：`pfspara` 含**内容**、`FsQuerySubtrackParaList` 能答出 `cParas ≥ 1` 且与托管真值一致 ⇒ **本波做不到**（无内容模型）⇒ 记 **`NOINFO-LAYOUT-CONTENT`**。
- **F-1 必红**：`rc=0` 但 `kstop=0`（假"排完"）；`mcsOut≠0`；`dvrUsed>0` 而 `pfsBBox` 空；把 S-1 写成"S-2 成立"；单样本当机制。

### §5.3 前置（哪些已满足、哪些没有）

| 前置 | 状态 | 依据 |
|---|---|---|
| 槽序未错位 | ✅ 已满足 | `t168` `D2=SLOT-ORDER-OK`（**引自 t168，未独立复算**） |
| 副本内 thunk 可调 | ✅ 已满足 | `t168` `D3` 槽 1 `rc=0 sobjc=0x1b63=idobj(7001)+10`（引自 `t168`） |
| `pfspara`/子轨对象自有可认领 | ✅ 已满足 | `t162` `(a)`；`win32_pts.c:3496` 现取 |
| 本侧几何/矩形 | ✅ 已满足 | `win32_pts.c:290`/`:352`/`:3052`（768×576） |
| **本入口本身** | ❌ 缺 | §2.1 现取（native 全族 0 实现） |
| **"无内容"必须是真话的证据** | ❌ 缺 | 本侧今天**没有内容源**（`NOINFO-LAYOUT-CONTENT`）⇒ 须在留痕里具名 |
| **输入侧句柄校验能力** | ⚠️ **缺**（具名 `NOINFO-HANDLE-VERIFY-AT-ENGINE`） | 家族码 `'H'` 今天只认 `fsp_pl_src_in/out` 两个具体值（`win32_pts.c:1457`），而本族收到的是 `this.Handle`（另一枚托管句柄）⇒ **native 无法验证"它是不是真句柄"**（拿不到表长）⇒ 只能不校验 |

---

## §6 诚实边界

1. **不许把"实现它就能通"当已验因果**：`t168` 的 `-100002` 是**被 `catch` 的托管异常**（`PtsHost.cs` 槽 3 内的 `catch (Exception e) { PtsContext.CallbackException = e; fserr = fserrCallbackException; }`），**具体异常类型仍是 `NOINFO`**（`NOINFO-EXC-TYPE`）。
   ⇒ **免费判别（建议下一件顺手做）**：托管侧 `PtsContext.cs:405 internal Exception CallbackException` **已经持有该异常对象** ⇒ 驱动格调用后**打印 `CallbackException.GetType().FullName` 与 `Message`**：若为 `EntryPointNotFoundException` ⇒ "缺符号"**由判定升为读数**；若为别的（NRE／InvalidOperation／…）⇒ **"缺入口"这一归因被推翻**，必须改判。**在这条读数到手之前**，`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 只能算**现有证据下最一致的假设**。
2. 具名 `NOINFO`／`PRECOND-*` 汇总：
   - `NOINFO-EXC-TYPE`（上文 1）；
   - `NOINFO-HANDLE-VERIFY-AT-ENGINE`（§5.3：引擎侧无法验证托管句柄）；
   - `NOINFO-FTNREJ-NULLABILITY`（`pfsFtnRej` 能否 NULL：仓内无依据）；
   - `NOINFO-BREAKREC-CONTENT`（§4-4）；
   - `NOINFO-LAYOUT-CONTENT`（本波无内容模型）；
   - `NOINFO-FSGEOM-LAYOUT`（沿用 `t164`：几何形状不在仓内 ⇒ 自定、与上游 ABI 不可比）；
   - `PRECOND-NO-LAYOUT-MODEL`（**若**队长要求"必须真造型才算推进"⇒ 本波**做不到**，这是**合法终点**）。
3. 🔴 **`P9`**：**不许**把"本族 native 侧 0 实现"推广成"造型面没有路"——本件已给出**同一把钥匙**（`ppfsSubtrack`＝`t162` 的对象）；也**不许**把"`M1` 只做占位"读成"`M1` 没价值"。
4. 🔴 **`P10`**：本件每条**负面结论**都附前置——"说缺入口"先要 `CallbackException` 的类型读数；"说有内容"先要有内容源；"说槽序对"以 `t168` 的零槽指纹为准。
5. **本件不含腿读数**；`t162`/`t168` 的末行自证本席当场复算过（MATCH=yes），**属代际核对，不构成对其内部读数的复算**。

---

## §7 排期含义：下一件做什么、算推进一格、代价与风险

- **下一件（建议）**：**`t170`：`M1`（`FsFormatSubtrackFinite` 的诚实无进展实现）＋ 顺手取 `CallbackException` 类型读数**，全部限定在**副本**（`#if` 缺省 0，主链产物逐字节不变，照 `WPF_PTS_FSP_PL_ENGINE_DRIVE` 先例）。
- **"推进一格"的判据（不放水）**：
  1. `S-1` 全中（含 `kstop` 非 0、`mcsOut=0`、两独立样本同判）⇒ 记为 **"槽 3 链的 native 缺环已补上（契约层）"**；
  2. **`CallbackException` 类型读数**到手 ⇒ `PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 由"假设"升为"读数"（或推翻）；
  3. `S-2` **仍须 `NOINFO`**（不许因为 `rc=0` 就说造型通了）。
- **代价与风险**（必须写进下一件的判据）：
  - 🔴 **假绿风险最高的一条**：`rc=0` 会让宿主**继续往下走**（`SetChunkInfo`、margin collapsing、`dvrUsed` 参与几何）⇒ 可能把"崩"变成"**静默空排**"。⇒ 因此 `M1` **只许待在副本**，且**判据面必须把 `kstop=no-progress` 与"排版成功"分成两个判词**。
  - **涉及 `t132` 三级链**：本入口是**托管按槽 3 驱动 → 引擎回头**的那一环 ⇒ 它的"输入"里混着**宿主句柄**（`this.Handle`／`mcsContainer.Handle`／可能的 `pfsFtnRej`）⇒ 本侧**没有**验证它们的能力（§5.3）⇒ 一旦沿用（而非拒绝）这些值，必须写明"**不校验，按不透明处理**"。
  - **涉及 `t141` 快照纪律**：本入口**没有回调表**可快照（不经过 `FSCBK`/`FSIMETHODS`）⇒ 不触发缓冲寿命问题；**但它有"引擎自有对象生命周期"问题**：`ppfsSubtrack` 必须在**后续**调用里仍可认领（持有期＝对象生存期，`t158` §2.1 在册）。
- **不建议**在本波实现 `Bottomless`／`Update` 两条：它们**不在** `t168` 的 E2 链上（那是槽 4/槽 5 的路），做了也**不推进**该格。

---

## §8 本件自身的验收

1. 新件；末行＝自证行（`head -n -1 <本件> | sha256sum | cut -c1-16`）；`mode 644`；首记号 ＝ `# P1-W89 `。
2. 复核者须**独立重取** §1 表内至少 4 件的 sha16 与引用行（`sed -n`/`awk` 整行打原文）；`win32_pts.c` **必须重取**（在飞）；不一致处**只增不改**地追加。
3. 本件**未**授权任何判据放宽；对 `t168` 的处置是**加前置**（`NOINFO-EXC-TYPE`），不是收窄其读数。

---

## §9 附录：现取原文摘录（仅本次有效）

`Pts.cs:3318-3342`（sha16 `1a8575a18767a956`，逐参数节录）：
```
        internal static extern int FsFormatSubtrackFinite(
            IntPtr pfsContext, IntPtr pfsBRSubtackIn, int fFromPreviousPage,
            IntPtr fsnmSegment, int iArea, IntPtr pfsFtnRej, IntPtr pfsGeom,
            int fEmptyOk, int fSuppressTopSpace, uint fswdir, [In] ref FSRECT fsRectToFill,
            IntPtr pfsMcsClientIn, FSKCLEAR fsKClearIn, FSKSUPPRESSHARDBREAKBEFOREFIRSTPARA fsksuppresshardbreakbeforefirstpara,
            out FSFMTR pfsfmtr, out IntPtr ppfsSubtrack, out IntPtr pfsBRSubtrackOut, out int pdvrUsed,
            out FSBBOX pfsBBox, out IntPtr ppfsMcsClientOut, out FSKCLEAR pfsKClearOut, out int pTopSpace);
```
`Pts.cs:1121-1146`（同件）：
```
        internal enum FSFMTRKSTOP : int { fmtrGoalReached = 0, fmtrBrokenOutOfSpace = 1, … fmtrNoProgressOutOfSpace = 8, … }
        internal struct FSFMTR { internal FSFMTRKSTOP kstop; internal int fContainsItemThatStoppedBeforeFootnote; internal int fForcedProgress; }
```
`ContainerParagraph.cs:526-531`（sha16 `1d0128592496706d`，**整行取**）：
```
                PTS.Validate(PTS.FsFormatSubtrackFinite(PtsContext.Context, pbrkrecIn, fBRFromPreviousPage, this.Handle, iArea, 
                    footnoteRejector, geometry, fEmptyOk, fSuppressTopSpace, fswdirSubtrack, ref fsrcToFillSubtrack, 
                    (mcsContainer != null) ? mcsContainer.Handle : IntPtr.Zero, fskclearIn, 
                    fsksuppresshardbreakbeforefirstparaIn, 
                    out fsfmtr, out pfspara, out pbrkrecOut, out dvrUsed, out fsbbox, out pmcsclientOut, out fskclearOut, 
                    out dvrSubTrackTopSpace), PtsContext);
```
`ContainerParagraph.cs:550-596`（同件，**出参怎么被读**）：
```
:551            if (fsfmtr.kstop >= PTS.FSFMTRKSTOP.fmtrNoProgressOutOfSpace) { dvrUsed = 0; }
:565            if (fsfmtr.kstop == PTS.FSFMTRKSTOP.fmtrGoalReached) { …CollapseBottomMargin…; dvrUsed += marginBottom + mbp.BPBottom; }
:558            if (pmcsclientOut != IntPtr.Zero) { mcsContainer = PtsContext.HandleToObject(pmcsclientOut) as MarginCollapsingState; … }
:596            paraClient.SetChunkInfo(pbrkrecIn == IntPtr.Zero, pbrkrecOut == IntPtr.Zero);
```
`win32_pts.c`（代际 **`6d6f753105224f78`**）：
```
:1207   static const void *wpf_pts_sub_handle(const wpf_pts_subtrack *o)
:1212   static int wpf_pts_sub_claim(const void *p, wpf_pts_subtrack **out)
:1457       || p == (const void *)d->fsp_pl_src_in || p == (const void *)d->fsp_pl_src_out) return 'H';
:1458   if (wpf_pts_sub_claim(p, NULL)) return 'E';
:3496           const void *para_val = wpf_pts_sub_handle(dp->sub);
```

---

**判词（本席）**：① 族的边界＝**16 名全未实现**，其中**造型类 3 条**（`FsFormatSubtrackFinite` `Pts.cs:3318`／`Bottomless` `:3344`／`UpdateBottomlessSubtrack` `:3367`），**E2 链上唯一缺的只有 `FsFormatSubtrackFinite`**（槽 3 → `ContainerParagraph.cs:526`）；② 逐入参作者性：**本侧能当作者的是** `pfsContext`／`pfsGeom`／`fsRectToFill`／布尔与枚举若干，**入站给的不可当作者的是** `fsnmSegment`(=`this.Handle`)／`pfsFtnRej`／`pfsMcsClientIn`（且 native **无能力校验**托管句柄 ⇒ `NOINFO-HANDLE-VERIFY-AT-ENGINE`）；**`ppfsSubtrack` 就是 `t162` 已落地的那枚本侧自有对象**（与 `FSPARADESCRIPTION.pfspara` 同种，`win32_pts.c:3496` 现取）⇒ **不需要新对象种类**；③ **断页记录不要求承载内容**（首调可 NULL、finite 路径只做零比较 `:596`、字段地址别名同族已受），**除非**要跨页续排 ⇒ `NOINFO-BREAKREC-CONTENT`；④ **最小可行子集＝只做 `FsFormatSubtrackFinite` 的 `M1：诚实无进展`**：显式写 `kstop=no-progress`（**零填充的 `FSFMTR` 会被读成"排完了"**，`Pts.cs:1123`＋`ContainerParagraph.cs:565`）、`mcsOut=0`（非 0 会被解引用）、`dvrUsed=0`、`bbox` 平空、`brSubtrackOut=0`、留痕具名；**它的判词是"契约占位成立"，不是"造型成功"**（`S-2` 维持 `NOINFO`）；⑤ **红榜 `P9`／`P10` 已落实**：不把"全族未实现"推广成"造型面没路"，且**`PRECOND-NATIVE-FORMAT-ENTRY-MISSING` 在拿到 `CallbackException` 类型读数前只算假设**（`NOINFO-EXC-TYPE`，判别办法已给：托管 `PtsContext.cs:405` 已持有该异常对象）。
`P1-fsformatsubtrack-recon 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ b7b10d873d559c65（末行＝本行）`

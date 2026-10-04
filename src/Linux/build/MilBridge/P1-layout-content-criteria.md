# P1-W102 判据（先写）：`S-2b`（排版「内容层」）—— 它是什么、本侧今天有什么、本波该不该做

本件是**判据先写**件（`work` 类）：给 `S-2b` 下定义、盘点本侧资产、判"最小可辩护形态是否存在"，并**在本波不该做时如实判不做**（合法终点）。
**本件只读，不实现、不跑腿、不构建、不占显示位、不改任何代码**；无运行期腿读数；引他人读数一律带代际并标「引自 X，本席未独立复算」；**所有行号一律 `awk`／`grep` 整行现取，不用 `cut` 截列**（`t169` 教训）。

---

## §0 身份、边界与在飞件

- 载体：`build/MilBridge/P1-layout-content-criteria.md`（**新建**）。写者＝`scout`；写入面**仅本件**，`$N` 内其余件**一件未改**。
- 结论**只许收紧**；放宽须队长出裁定并在册。
- ⚠️ **在飞件**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 开工现取 **`sha16=02d4c89fa432d4d2`／330477 B**（mtime 19:36:39，与 `t181` 交出**同代**）⇒ 本件对他的引用**行号只在该代有效**。HEAD＝`0bf1bbd`。

---

## §1 台账（读取时刻＝2026-09-29 19:40–19:47，本席本地，仅本次有效）

| 件 | sha16 | 用途 |
|---|---|---|
| `PtsHost/Pts.cs` | `1a8575a18767a956` | 内容层结构：`FSTEXTDETAILSFULL`(`:1445-1461`)、`FSTEXTDETAILSCACHED`(`:1467-1478`)、`FSTEXTDETAILS`(`:1486-1498`)；内容层引擎入口声明 `:3750`／`:3756`／`:3764`／`:3772`／`:3780` |
| `PtsHost/TextParaClient.cs` | `be3e7a145113dca5` | **内容层消费者**：`FsQueryTextDetails` 调用点 `:56`／`:149`／`:194`／`:253`／`:345`／`:386` 等 |
| `PtsHost/PtsHelper.cs` | `f2ed9552e983fed1` | 行列消费：`:652` `FsQueryLineListSingle`／`:671` `FsQueryLineListComposite` |
| `PresentationCore/…/TextFormatting/LineServices.cs` | `8b2bc2167f5c0bd3`（1620 行） | **LS 面**：`[DllImport]` **27** 条；**回调 `delegate` 30 条**（`FetchPap`/`FetchLineProps`/`FetchRunRedefined`/`GetRunTextMetrics`/`GetRunCharWidths`/`DurMaxExpandRagged`/`DrawTextRun`…） |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `02d4c89fa432d4d2` | 本侧现状：内容入口 **0 命中**（见 §3.3） |
| `build/MilBridge/P1-ls-family-recon.md`（LS 族取证） | 379 行；末行自证 `7472106ad52be662`（**本席当场复算 MATCH=yes**；内部读数未复算） | LS 族口径来源（`LineServices.cs` 27／缺口 22／已导出 5；本 DLL 总缺口 **99**） |
| `build/MilBridge/P1-layout-model-criteria.md`（`t179`，本席前件） | 226 行；自证 `03460258dfa88ae2`（MATCH） | `S-2` 一分为二、四张消费面、`I-6` 零托管依赖 |
| `build/MilBridge/P1-layout-model-report.md`（`t181`） | 78 行；自证 `1b0bb252b3ad0bfb`（MATCH） | `LM-1` 落地：`cParas=1`／`dvrUsed=16`／`fits=1`／`S-2a-PARTIAL(7/8)`；`S-2b` 维持 `NOINFO` |
| `build/MilBridge/P1-native-para-model-report.md` | — | `:64` 载：`PRECOND-MANAGED-PARACLIENT-LIVE`（`t130` 立、`t131` 归位为效果）——**引自该件，本席未独立复核** |
| `build/MilBridge/P1-managed-handle-report.md`（`t131`） | — | 判词首行：「**不能在本件写域内被诚实满足**」（三段具名前置）——引自该件 |

---

## §2 `S-2b` 到底是什么（任务 §1）

**判词：`S-2b` ＝ 「行盒 ＋ 字符位置」层**：**行数**、**字符区间（`dcp`）**、**每行盒**。消费者是**文本段落的 para client**（`TextParaClient`），**不是**容器族。

### §2.1 数据结构（现取 `Pts.cs`）
- `FSTEXTDETAILSFULL`（`:1445-1461`）：`fswdir`／`fsklines`(FSKTEXTLINES: Word/Optimal/Normal)／`fLinesComposite`／**`cLines`**／`cAttachedObjects`／**`dcpFirst`**／**`dcpLim`**／`fDropCapPresent`／`fsupdinfDropCap`／`dcdetails`／`fSuppressTopLineSpacing`／`fUpdateInfoForLinesPresent`／`cLinesBeforeChange`／`dvrShiftBeforeChange`／`cLinesChanged`
- `FSTEXTDETAILSCACHED`（`:1467-1478`）：`fswdir`／`fsklines`／`fsrcPara`／`fSuppressTopLineSpacing`／**`dcpFirst`／`dcpLim`／`cLines`**／`fClearOnLeft`／`fClearOnRight`
- `FSTEXTDETAILS`（`:1486-1498`）＝ `{ FSKTEXTDETAILS fsktd; nested_u u{ FULL full | CACHED cached } }`（**联合体**）
⇒ **内容层的"量"＝ `cLines` 与 `dcpFirst/dcpLim`**（行数与字符区间）＋ 行盒（`FsQueryLineListSingle/Composite`）。

### §2.2 消费者（逐跳，整行现取）
- `TextParaClient.cs:56`／`:149`／`:194`／`:253`／`:345`／`:386`（**六处以上**）：`PTS.Validate(PTS.FsQueryTextDetails(PtsContext.Context, _paraHandle, out textDetails));`
- `PtsHelper.cs:652` `PTS.Validate(PTS.FsQueryLineListSingle(ptsContext.Context, para, textDetails.cLines, …));`
- `PtsHelper.cs:671` `PTS.Validate(PTS.FsQueryLineListComposite(ptsContext.Context, para, textDetails.cLines, …));`
- 声明位：`Pts.cs:3750`（`FsQueryTextDetails`）／`:3756`／`:3764`／`:3772`／`:3780`（`FsQueryDcpLineVariantsFromCachedTextPara`）。

### §2.3 🔴 特别回答（任务要求）：`t179` 的面 A／面 B／面 C 里**有没有"内容"字段**？

| 面 | 字段（现取） | **有没有内容字段** |
|---|---|---|
| **面 A** `ContainerParagraph.cs:551/:558/:565/:585-592/:596` | `fsfmtr.kstop`／`dvrUsed`／`fsbbox`／`pmcsclientOut`／`pbrkrecOut` | ❌ **没有**（全是"停因/垂直量/盒/托管句柄/断页记录"） |
| **面 B** `PtsHelper.cs:174-180` | `dvrTopSpace`／`dvrUsed`／`fsrc` | ❌ **没有** |
| **面 C** `ContainerParaClient.cs:271/:278` | `cParas`（**计数**）／`pfsparaclient` | ❌ **没有**（`cParas` 是"有几段"，不是"段里有什么字"） |
⇒ **判词：`LM-1` 的三张消费面一个内容字段都没有** ⇒ **`S-2b` 与 `LM-1` 是两条不同的消费链**：前者的入口是 `FsQueryTextDetails`、消费者是 `TextParaClient`；后者的入口是 `FsFormatSubtrackFinite`/`FsQueryTrackParaList`、消费者是 `ContainerParaClient`／`PtsHelper.ArrangeParaList`。

---

## §3 本侧今天有什么（任务 §2：通路 vs 缺口）

### §3.1 通路（已通，可复用）
| 资产 | 现取 | 对本件的意义 |
|---|---|---|
| **同一身份模型** | `TextParaClient.cs:56` 用的也是 **`_paraHandle`**；而 `_paraHandle = FSPARADESCRIPTION.pfspara`（`t158`/`t169` 在册） | ⇒ **内容层的"键"与 `LM-1` 是同一枚引擎自有对象** ⇒ **不需要新对象** |
| **回调表值化机制** | `t166`/`t168`：`FSIMETHODS` **在调用期内值拷贝**即可调用（D3 已把 `THUNK-LIVENESS` 升为读数） | ⇒ 若将来要开第二条回调面，**方法学已备** |
| **快照纪律** | `win32_pts.c` 的 `fscbk` 103 字窗内 `memcpy`（`t141`／`t166`） | 同上 |
| **几何/计数层** | `t181` `LM-1`：`cParas=1`／`dvrUsed=16`／`fits=1`，`S-2a-PARTIAL(7/8)` | 内容层的"容器侧邻居"已就位 |

### §3.2 `t130`／`t131` 的判词（任务点名要盘）
- `t130` 立 **`PRECOND-MANAGED-PARACLIENT-LIVE`**；`t131` 把它**归位为"效果"**（出处 `build/MilBridge/P1-native-para-model-report.md:64`，**引自该件，本席未独立复核**）。
- `t131` 自身判词首行：「**不能在本件写域内被诚实满足**」＋三段具名前置（`build/MilBridge/P1-managed-handle-report.md`，引自该件）。
⇒ 对本件的意义：**"注册段落客户端句柄"这一族早已被判"要真排版链"**；而内容层比它更靠后 ⇒ **同族前置仍适用**。

### §3.3 缺口（三处，量级现取）
1. **引擎侧内容入口：0 实现**。现取 `grep -c 'FsQueryTextDetails\|FsQueryLineList\|FsQueryDcpLine' src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **0**；`grep -rn` 全 `src/WpfGfx.Linux.Native/`、`build/shims/` ⇒ **无命中**。
2. **LS 族**：`LineServices.cs`（`8b2bc2167f5c0bd3`，1620 行）**27 条 `[DllImport]`**；按 `P1-ls-family-recon.md`（引自该件）**22 条在缺口集、5 条已导出**；本 DLL（`PresentationNative_cor3.dll`）总缺口 **99** 条。
   ⚠️ **口径存疑（如实记）**：任务书写的「LS 面导出 8 vs 托管侧引用 23 ⇒ 缺口 ≈13」与本席现取到的 **27／22／5** 口径**不同**（前者引自任务书，本席**未独立复算**）⇒ 两个口径**不得混用**；本件一律用**可复算的后者**（件名＋行号＋`DllImport` 计数已给）。
3. **LS 回调面：30 槽**（`LineServices.cs` 现取 `delegate` **30** 条：`FetchPap`／`FetchLineProps`／`FetchRunRedefined`／`GetRunTextMetrics`／`GetRunCharWidths`／`DurMaxExpandRagged`／`DrawTextRun`…）⇒ 这是一张**与 `FSCBK`（103 字）／`FSIMETHODS`（17 槽）都不同**的**第二条回调面**，本侧今天**一个槽都没接**。

---

## §4 最小可辩护形态：**不存在（本波）** —— 判「本波不该做」

### §4.1 为什么不存在（作者性逐字段，裁定五十一 (b)：**准入 ＝ 本侧是该值的作者**）

| 字段 | 本侧能否是作者 | 依据 |
|---|---|---|
| **`cLines`**（行数） | ❌ **不能** | 它＝"本侧真的断出了几行"的结果；本侧今天**没有行断器**（LS 族 0 实现，§3.3-2）⇒ 填任何数都是**自造** |
| **`dcpFirst`／`dcpLim`**（字符区间） | ❌ **不能** | 需要**字符内容源**（`dcp`↔字符映射）；内容在**宿主侧**（托管 `TextContainer`/`TextFormatter`），本侧**没有任何入站通道**拿到它（§3.3-3 的第二回调面未接） |
| **行盒**（`FSLINEDESCRIPTIONSINGLE/COMPOSITE`） | ❌ **不能** | 同上，且还需**度量（字宽/字体）**：托管侧对应的是 `GetRunCharWidths`／`FetchRunRedefined` 等 **LS 回调**（30 槽之一），本侧**一个都没接** |
| `fswdir`／`fsklines`／`fLinesComposite` 等**枚举/标志** | ⚠️ **形式上是**，但**无意义** | 单填它们而 `cLines` 无源 ⇒ 就是"给空壳填标志"，属 **native 自造**（红） |
| `fsrcPara`（段落矩形） | ✅ **是** | 本侧页几何（`win32_pts.c` 现取代：`pg_w/pg_h`）—— **这是唯一本侧可作者的内容层字段**，且它**不属于"内容"**（`LM-1` 已含） |

⇒ **判词：`S-2b` 在本波**没有**像 `LM-1` 那样的"本侧自持、按对象回答"的最小集 ⇒ `PRECOND-NO-LAYOUT-CONTENT-MODEL` **维持成立**；**若强行实现 `FsQueryTextDetails` 而不做行断，产物必然是伪造**（红榜 `P3`／`P8` 家族）。**

### §4.2 可证伪判据草案（**若**队长另开一波，用它当契约；本波不执行）

- **`objective`**：在**副本**内让 `TextParaClient.cs:56` 起那条链，从**引擎侧入口**取到**自洽**的 `FSTEXTDETAILS`：`cLines ≥ 0`、`dcpFirst/dcpLim` 与行盒**逐行自洽**、且**每一行的行盒由本侧真实度量得到**。
- **`acceptance`（六条合取）**：① `rc=0 ∧ calls>0`（`P10`）；② `cLines`＝本侧**行断计数**（逐值可核，非常量）；③ `dcpFirst/dcpLim` 与**真实字符源**一致（须给"字符源"的**入站证明**）；④ 行盒与矩形/方向自洽（`fsrcPara` 与 `Σ` 行高一致）；⑤ **≥2 样本非空且同判**（🔴 **恒真断言族**：先证 `cLines` 被真读、样本次数 `>0`，否则"没有读数"与"读数相同"不可分）；⑥ 每条带纪律三十三格＋探针闸状态。
- **`verify`**：`<leg> >out 2>err; echo $?`；`grep -c` 出**具名行**计数；两样本逐格比对。
- **前置（三条，缺一不可）**：**(i)** 内容源入站通道（见 §5 的越级）；**(ii)** 行断器（LS 族 22 缺口 或 等价物）；**(iii)** 链上真的出现**文本段落**（今天跑的是 `ContainerParagraph`）。

---

## §5 与 `LM-1` 的关系（任务 §4）：**同身份模型、不同消费链；但要取源必须"越级"**

- **对象层**：内容层的键就是 **`_paraHandle`（＝`FSPARADESCRIPTION.pfspara`）**（`TextParaClient.cs:56` 现取）⇒ **同一枚引擎自有对象** ⇒ **不需要新对象**（这点与 `LM-1` 一致）。
- **通道层**：内容源的取得**只能**经**新的入站回调面**（LS 的 **30 槽**：`FetchPap`／`FetchRunRedefined`／`GetRunCharWidths`…）或**新的引擎入口族**（27 条 LS `[DllImport]`）⇒ **这正好落在 `t179` 的 `I-6`（零托管依赖）之外** ⇒ **判「越级」**。
- **⇒ 具名前置**：
  - **`PRECOND-NEW-CALLBACK-FACE`**（越级本体）：要接**第二条回调面（30 槽）** ⇒ 须队长裁定另开一波（含其 ABI／寿命／快照口径）。
  - **`PRECOND-NO-TEXT-SOURCE`**：本侧无字符/`dcp` 内容源。
  - **`PRECOND-NO-LINE-BREAKER`**：本侧无行断器（LS 族 0 实现）。
  - **`PRECOND-NO-TEXT-PARA-IN-CHAIN`**：现链上是容器段落，`TextParaClient` 是**另一族**。
  ⇒ **四个前置全部具名，且互不重叠**（源／断行器／通道／链上对象）。

---

## §6 代价与风险（任务 §5）：**判「本波不该做」**

- **代价量级**：不是"补几个符号"，而是**再开一条与 LineServices 同规模的链**：**27 条引擎入口**（现取 22 缺／5 已导出）＋**30 槽回调面**＋**内容源**＋**文本段落进链**；对照：我们为**几何/计数层**花了 `t151`→`t181`（十余件）才到 `S-2a-PARTIAL(7/8)`。
- **依赖链**：`LM-1`（几何/计数，已部分落地）→ **`LM-2`（内容）** → `FsQuerySubtrackDetails`/`FsQuerySubtrackParaList` 的**内容侧** → 页内容面（`N1–N4` 的内容判据）。
- **风险（四条）**：
  1. 🔴 **伪造风险**：无行断而答 `cLines/dcp` ⇒ **native 自造**（红 `P3`／`P8`）。
  2. 🔴 **假绿风险**：若用 `cLines=0` 让查询"成功"，`TextParaClient` 走空行分支 ⇒ **"没有读数"与"读数相同"不可分**（`t180` `F-1` 恒真族）⇒ 判据必须**先证样本非空**。
  3. **波纹风险**：LS 回调面 30 槽与 `FSCBK`/`FSIMETHODS` **机制不同**（LS 是**引擎调宿主**取内容，方向与外层相反）⇒ 值化/寿命口径要**重新立**，不能照抄 `t166` 的结论。
  4. **排期风险**：本波目标是"3 条未绿 `[MVP]`"，内容层**不是最短路径**（`LM-1` 的第 4 条宿主侧消费证据仍由 `t184` 在跑）。
- **⇒ 判词：本波**不做** `S-2b`**（**合法终点**）；`S-2b` 维持 `NOINFO`，并把 `PRECOND-NO-LAYOUT-CONTENT-MODEL` 的**射程写明**：它挡的是**内容层**，**不挡** `LM-1` 的几何/计数层（`t179` 已把 `S-2` 一分为二）。

---

## §7 排期：下一件做什么、什么算"推进一格"

- **本波内可做（建议，低成本、纯只读/判据）**：**`S-2b` 的"可判化"**——即把 `S-2b` 从"无定义"推进到"**有边界、有四条具名前置、可判的 `NOINFO`**"（**本件即完成这一步**）。这是**合法且真实**的推进（把"不知道缺什么"变成"知道缺哪四样、各自的量级"）。
- **若队长要再推进一格（另开一波）**：先做**"内容源边界侦察"**（只读）：在 LS 的 **30 槽回调**里逐槽判"**必须由引擎驱动**"与"**托管内部自足**"，产出**最小入站面清单**＋越级裁定申请。⇒ 在此之前**不许**动 `FsQueryTextDetails` 的实现。
- **"不算推进"清单（写死）**：
  1. 实现 `FsQueryTextDetails` 而**无行断**（伪造）；
  2. 用 `cLines=0`／空行表让查询"成功"（`P8` 恒真）；
  3. 用"两样本一致"证明内容层（**样本可能为空** —— 恒真断言族）；
  4. 把 `LM-1` 的 `S-2a` 绿**外推**到内容层（`t179` 明禁）。

---

## §8 纪律落地与具名 `NOINFO`

- 🔴 **`P9`**：**不许**把"LS 族 0 实现"推广成"内容没有源"——**源在宿主侧**（托管 `TextContainer`/`TextFormatter`，本席据 `LineServices.cs` 的 30 条回调委托现取判定），本件只判"**取它要开新面**"。
- 🔴 **`P10`**：本件所有负面结论都附前置 —— "说缺行断器"以 `grep` **0 命中**＋`LineServices.cs` **27/22/5** 为据；"说缺源"以**无入站回调面**为据；"说链上不是文本段"以 `t181`/`t173` 的驱动链落在 `ContainerParagraph` 为据。
- 🔴 **恒真断言族**：凡本件引"两样本一致"类证据，**必须先证样本非空**；`S-2b` 尤其危险（"没读数"＝"读数相同"）。
- 具名 `NOINFO`：`NOINFO-CONTENT-SOURCE-INBOUND`（内容源入站通道不存在）／`NOINFO-LS-CALLBACK-FACE`（30 槽未接、方向与外层相反）／`NOINFO-LS-GAP-CALIBER`（任务书 8/23/≈13 与本席 27/22/5 **两个口径不得混用**，前者未复算）／`NOINFO-TEXT-PARA-IN-CHAIN`（无文本段落进链）。

---

## §9 本件自身的验收

1. 新件；末行＝自证行（`head -n -1 <本件> | sha256sum | cut -c1-16`）；`mode 644`；首记号 ＝ `# P1-W102 `。
2. 复核者须**独立重取** §1 表内至少 4 件的 sha16 与引用行（`awk`／`grep` **整行**打原文）；`win32_pts.c` **必须重取**（在飞）；不一致处**只增不改**地追加。
3. 本件**未**授权任何判据放宽；对 `t179` 的处置是**沿用并加射程**，对任务书 LS 口径的态度是**不混用、标未复算**。

---

## §10 附录：现取原文摘录（仅本次有效，全部整行取）

`Pts.cs:1445-1461`（sha16 `1a8575a18767a956`，节录）：
```
        internal struct FSTEXTDETAILSFULL
        {
            internal uint fswdir;                   // writing direction in text paragraph
            internal FSKTEXTLINES fsklines;         // kind of text lines: Word, Optimal, Normal
            internal int fLinesComposite;           // if lines are composite
            internal int cLines;                    // number of lines
            internal int cAttachedObjects;          // number of floaters
            internal int dcpFirst;                  // dcp of the first line, only if  cLines > 0
            internal int dcpLim;                    // dcpLim of the last line, only if  cLines > 0
```
`TextParaClient.cs:56`（sha16 `be3e7a145113dca5`）：
```
            PTS.Validate(PTS.FsQueryTextDetails(PtsContext.Context, _paraHandle, out textDetails));
```
`PtsHelper.cs:652`（sha16 `f2ed9552e983fed1`）：
```
                PTS.Validate(PTS.FsQueryLineListSingle(ptsContext.Context, para, textDetails.cLines,
```
`LineServices.cs:19` 起（sha16 `8b2bc2167f5c0bd3`，1620 行／`DllImport` 27／`delegate` 30）：
```
    //  Line Services application callback delegates
    internal delegate LsErr FetchPap(
    internal delegate LsErr FetchLineProps(
    internal unsafe delegate LsErr FetchRunRedefined(
    internal delegate LsErr GetRunTextMetrics (
    internal unsafe delegate LsErr GetRunCharWidths(
    internal delegate LsErr GetDurMaxExpandRagged(
    internal unsafe delegate LsErr DrawTextRun(
```
本侧现状（`grep` 现取）：`FsQueryTextDetails`／`FsQueryLineList`／`FsQueryDcpLine` 在 `src/WpfGfx.Linux.Native/src/win32_pts.c` 内命中 **0**。

---

**判词（本席）**：① **`S-2b` ＝「行盒 ＋ 字符位置」层**（`cLines`／`dcpFirst`／`dcpLim`／行盒），消费者是**文本段落的 para client**（`TextParaClient.cs:56` 等六处＋`PtsHelper.cs:652/:671`）；**`t179` 的面 A／B／C 里一个内容字段都没有** ⇒ 它与 `LM-1` 是**两条不同的消费链**（虽然共用同一枚 `_paraHandle` 身份）。② **本侧今天**：通路＝同一身份模型＋已备的回调值化/快照方法学＋`LM-1` 几何层；**缺口三处**＝引擎内容入口 **0 实现**、LS 族 **27 条中 22 缺**、LS **回调面 30 槽一个未接**（＋任务书的 8/23/≈13 为**另一口径、未复算，不混用**）。③ **最小可辩护形态不存在**：`cLines`／`dcp*`／行盒**只能来自"本侧真的断了行"**，本侧**既无字符源也无行断器** ⇒ 强行实现即**伪造**（`P3`）；**判本波不做**（合法终点）。④ **与 `LM-1` 的关系**：**同身份、不同链**；但取源要**新开第二条回调面（30 槽）** ⇒ 触 `t179` 的 `I-6` ⇒ **判越级**，具名 `PRECOND-NEW-CALLBACK-FACE`／`NO-TEXT-SOURCE`／`NO-LINE-BREAKER`／`NO-TEXT-PARA-IN-CHAIN`。⑤ **排期**：本波只做**"`S-2b` 可判化"**（本件）；**不算推进**的四条已写死；若要再推进 ⇒ 先做**30 槽"必须引擎驱动"的最小入站面侦察**并**先申请越级裁定**。⑥ 三条纪律已落地（`P9`：源在宿主侧、只是取它要开新面；`P10`：负面结论全部附前置；恒真断言族：凡引两样本先证非空）。
`P1-layout-content-criteria 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ a8acdf6e78dbb5a9（末行＝本行）`

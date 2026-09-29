# P1-W103 只读侦察：`LineServices` 回调面 30 槽逐槽边界侦察 —— 判「必须由引擎驱动」vs「托管内部自足」

本件是**纯只读预派备料**（`work` 类）：**不越级、不动实现、不跑腿、不构建**；产出**最小入站面清单**，为将来"内容层那一波"备料。
无运行期腿读数；引他人读数一律带代际并标「引自 X，本席未独立复算」；**所有行号一律 `awk`／`grep` 整行取，不用 `cut` 截列**（模板 §A-14）。

---

## §0 身份、边界与在飞件

- 载体：`build/MilBridge/P1-ls-callback-face-recon.md`（**新建**）。写者＝`scout`；写入面**仅本件**，`$N` 内其余件**一件未改**；未 `git add/commit/push`。
- 通用硬约束见 `build/MilBridge/P1-TASK-TEMPLATE.md` §A（本件读于 19:55，15 条）。
- ⚠️ **在飞件**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 开工现取 **`sha16=02d4c89fa432d4d2`**（与 `t181` 交出同代）。本件靶心在**托管侧**（`upstream/**`，本席未改），故 native 换代**不影响**本件引用；但**实现者开工前仍须重取**。

---

## §1 台账（读取时刻＝2026-09-29 19:55–20:05，本席本地，仅本次有效）

| 件 | sha16 | 用途 |
|---|---|---|
| `PresentationCore/…/TextFormatting/LineServices.cs` | `8b2bc2167f5c0bd3`（1620 行） | **28 个回调 `delegate` 声明**（`:36-375`）；`LoCreateContext` 声明（`:1407-1412`）；`LoCreateLine`(`:1420`)／`LoSetDoc`(`:1471`)；27 条 `[DllImport]` |
| `PresentationCore/…/TextFormatting/LineServicesCallbacks.cs` | `612c19e675b7ad30`（3503 行） | **28 槽的托管实现与装配**：赋值 `:3268-3293`；接线 `lscbkRedef` `:3298-3300`、`contextInfo` `:3301-3324`；`InlineFormat`/`InlineDraw` 惰性属性 `:3358-3379` |
| `PresentationCore/System/Windows/Media/textformatting/TextFormatterContext.cs` | `00023d954dd580fd`（496 行） | **谁驱动 LS 会话**：`:113 LoCreateContext`／`:288 LoCreateLine`／`:354 LoSetDoc` |
| `build/MilBridge/P1-layout-content-criteria.md`（`t185`，本席前件） | 199 行；自证 `a8acdf6e78dbb5a9`（MATCH） | 判据来源（四条前置／四条 `NOINFO`／LS 口径 27-22-5） |
| `build/MilBridge/P1-ls-family-recon.md`（LS 族取证） | 379 行；自证 `7472106ad52be662`（MATCH） | LS **入口**面口径（27 `DllImport`／22 缺／5 已导出） |

---

## §2 🔴 先更正两处口径（`t185` 的自陈）

1. **槽数：`t185` 写的"回调 `delegate` 30 条"应更正为 `28` 槽。** 依据：`grep -n 'delegate' LineServices.cs` 命中 **30 行**，其中 `:19 //  Line Services application callback delegates` 与 `:347 //  Line Services object handler callback delegates` **是注释**；真正的 `internal…delegate` 声明 **28** 条（`awk` 逐块范围现取：`:36-40` … `:369-375`）。
2. **值化/寿命：`t185` 写的"必须重新立，不能照抄 `t166`"应更正为「机制可迁移、时序须重立」。** 依据：LS 回调面也是**"委托结构体 + `ref`"**在**一次调用内**交接（`LoCreateContext(ref LsContextInfo, ref LscbkRedefined, out IntPtr ploc)`，`LineServices.cs:1407-1412`）⇒ 与 `FSCBK`（`FSCONTEXTINFO` 成员）／`FSIMETHODS`（独立 `ref` 形参）**同形** ⇒ **窗内值拷贝的方法学可迁移**；**必须重立的是"谁在什么时候被调"**（见 §4）。

---

## §3 28 槽全表（逐槽：签名／宿主语义／判定／依据）

**判定图例**：**A**＝**必须由引擎驱动**（进最小入站面）；**A−**＝**取决于是否要字形级精度**（本件如实标）；**B**＝**仅渲染需要**（不进断行决策）；**C**＝**功能门控／可缺省**（须实现层再核，见 `NOINFO-LS-FEATURE-FLAGS`）。

| # | 槽（声明位 `LineServices.cs`） | 签名（整行取，节录为单行） | 宿主语义（引擎调它取什么） | 判定 | 依据（可证伪） |
|---|---|---|---|---|---|
| 1 | `FetchPap` `:36-40` | `(IntPtr pols, int lscpFetch, ref LsPap lspap)` | 取**段落属性**（断行规则、对齐、制表位…） | **A** | 入参 `lscp`（宿主 `cp` 空间）＋出参 `LsPap` 是断行规则唯一来源 ⇒ 不由宿主给则**无法决定断点** |
| 2 | `FetchLineProps` `:42-47` | `(IntPtr pols, int lscpFetch, int firstLineInPara, ref LsLineProps)` | 取**行属性** | **A** | 同上；且该槽被**同时**接入 `lscbkRedef:3300` 与 `contextInfo:3301` ⇒ 两处都要它 |
| 3 | `FetchRunRedefined` `:49-62` | `(IntPtr pols, int lscpFetch, int fIsStyle, IntPtr pstyle, char* pwchTextBuffer, int cchTextBuffer, ref int fIsBufferUsed, out char* pwchText, ref int cchText, ref int fIsHidden, ref LsChp lschp, ref IntPtr lsplsrun)` | **取文本**（字符序列）＋字符属性 | **A** | **行盒的字符区间（`dcp`）与文本本身只能由宿主给**；本侧无内容源（`t185` 已立 `PRECOND-NO-TEXT-SOURCE`） |
| 4 | `GetRunTextMetrics` `:64-70` | `(IntPtr pols, Plsrun plsrun, LsDevice lsDevice, LsTFlow lstFlow, ref LsTxM lstTextMetrics)` | 取**字体度量**（行高/基线/上下沿） | **A** | 行盒的**垂直量**（`dvrUsed` 的同层对应物）来自它 |
| 5 | `GetRunCharWidths` `:72-83` | `(IntPtr pols, Plsrun, LsDevice, char* runText, int cchRun, int maxWidth, LsTFlow, int* charWidths, ref int totalWidth, ref int cchProcessed)` | 取**逐字符宽度** | **A** | **断行**核心（`cchProcessed` 决定断在哪里） |
| 6 | `GetDurMaxExpandRagged` `:85-90` | `(IntPtr pols, Plsrun, LsTFlow, ref int maxExpandRagged)` | 两端对齐时**最大可扩张量** | **C** | 只在 ragged/justify 需要；不影响"行数/字符区间"本身 |
| 7 | `DrawTextRun` `:92-105` | `(…, char* runText, int* charWidths, int cchText, LsTFlow, uint displayMode, ref LSPOINT ptText, ref LSPOINT ptRun, ref LsHeights, int dupRun, ref LSRECT clipRect)` | **绘制**文本 run | **B** | 出参无、入参全为像素/裁剪 ⇒ 不进入断行决策 |
| 8 | `FInterruptShaping` `:107-113` | `(IntPtr pols, LsTFlow, Plsrun firstPlsrun, Plsrun secondPlsrun, ref int fIsInterruptOk)` | 询问**能否在此中断整形** | **C** | 只影响"整形可否被打断"；缺省可当作"可中断" |
| 9 | `GetRunUnderlineInfo` `:116-122` | `(IntPtr pols, Plsrun, ref LsHeights, LsTFlow, ref LsULInfo ulInfo)` | 下划线信息 | **C** | 只影响装饰，不影响断行 |
| 10 | `GetRunStrikethroughInfo` `:124-130` | 同上形（`ref LsStInfo stInfo`） | 删除线信息 | **C** | 同上 |
| 11 | `Hyphenate` `:132-142` | `(IntPtr pols, int fLastHyphenationFound, int lscpLastHyphenation, ref LsHyph lastHyphenation, int lscpBeginWord, int lscpExceed, ref int fHyphenFound, ref int lscpHyphen, ref LsHyph plsHyph)` | 连字（hyphenation）断点 | **C** | 只在宿主声明需要连字时用；但**是否无条件调用须实测** |
| 12 | `GetNextHyphenOpp` `:144-151` | `(IntPtr pols, int lscpStartSearch, int lsdcpSearch, ref int fHyphenFound, ref int lscpHyphen, ref LsHyph)` | 下一连字机会 | **C** | 同上 |
| 13 | `GetPrevHyphenOpp` `:153-160` | 同上形（Prev） | 上一连字机会 | **C** | 同上 |
| 14 | `GetAutoNumberInfo` `:162-173` | `(IntPtr pols, ref LsKAlign, ref LsChp, ref IntPtr lsplsrun, ref ushort addedChar, ref LsChp, ref IntPtr, ref int fWord95Model, ref int offset, ref int width)` | 自动编号信息 | **C** | 仅列表段落需要 |
| 15 | `DrawUnderline` `:175-185` | `(IntPtr pols, Plsrun, uint ulType, ref LSPOINT ptOrigin, int ulLength, int ulThickness, LsTFlow, uint displayMode, ref LSRECT clipRect)` | 绘制下划线 | **B** | 纯渲染 |
| 16 | `DrawStrikethrough` `:187-197` | 同上形（stType/stLength/stThickness） | 绘制删除线 | **B** | 纯渲染 |
| 17 | `GetGlyphsRedefined` `:199-215` | `(IntPtr pols, IntPtr* plsplsruns, int* pcchPlsrun, int plsrunCount, char* pwchText, int cchText, LsTFlow, ushort* puGlyphsBuffer, uint* piGlyphPropsBuffer, int cgiGlyphBuffers, ref int fIsGlyphBuffersUsed, ushort* puClusterMap, ushort* puCharProperties, int* pfCanGlyphAlone, ref int glyphCount)` | 取**字形映射**（字符→字形、簇） | **A−** | **A 的理由**：字形 advance 决定行盒宽度；**A− 的理由**：若只求"简单行盒"可退化为 `GetRunCharWidths`（本件不擅断，如实标） |
| 18 | `GetGlyphPositions` `:217-233` | `(IntPtr pols, IntPtr* plsplsruns, int* pcchPlsrun, int plsrunCount, LsDevice, char* pwchText, ushort* puClusterMap, ushort* puCharProperties, int cchText, ushort* puGlyphs, uint* piGlyphProperties, int glyphCount, LsTFlow, int* piGlyphAdvances, GlyphOffset* piiGlyphOffsets)` | 取**字形位置与 advance** | **A−** | 同上 |
| 19 | `DrawGlyphs` `:235-255` | `(…, uint displayMode, ref LSPOINT origin, ref LsHeights, int runWidth, ref LSRECT clippingRect)` | 绘制字形 | **B** | 纯渲染（入参含 `displayMode`/`clippingRect`） |
| 20 | `EnumText` `:257-279` | `(IntPtr pols, Plsrun, int cpFirst, int dcp, char* pwchText, int cchText, LsTFlow, int fReverseOrder, int fGeometryProvided, ref LSPOINT pptStart, ref LsHeights pheights, int dupRun, int glyphBaseRun, int* charWidths, ushort* pClusterMap, …)` | **按显示序枚举文本**（供绘制） | **B** | 语义是"枚举给绘制用"；断行不需要它 |
| 21 | `EnumTab` `:281-293` | `(IntPtr pols, Plsrun, int cpFirst, char* pwchText, char tabLeader, LsTFlow, int fReverseOrder, int fGeometryProvided, ref LSPOINT pptStart, ref LsHeights heights, int dupRun)` | 枚举**制表符**（制表位占位） | **A** | tab 的宽度/位置直接影响**断点**与行盒宽度；且本侧无 tab 语义来源 |
| 22 | `GetCharCompressionInfoFullMixed` `:295-305` | `(IntPtr pols, LsDevice, LsTFlow, LsCharRunInfo* plscharrunInfo, LsNeighborInfo* left, LsNeighborInfo* right, int maxPriorityLevel, int** left, int** right)` | 字符压缩信息 | **C** | 高级排版（CJK 压缩）；缺省应可关 |
| 23 | `GetCharExpansionInfoFullMixed` `:307-317` | 同上形（expansion） | 字符扩张信息 | **C** | 同上 |
| 24 | `GetGlyphCompressionInfoFullMixed` `:319-329` | `(…, LsGlyphRunInfo* plsglyphrunInfo, …)` | 字形压缩信息 | **C** | 同上 |
| 25 | `GetGlyphExpansionInfoFullMixed` `:331-343` | `(…, LsExpType* plsexptype, int* pduMinInk)` | 字形扩张信息 | **C** | 同上 |
| 26 | `GetObjectHandlerInfo` `:350-354` | `(IntPtr pols, uint objectId, void* objectInfo)` | 取**内联对象处理器**信息（floater/table 等） | **C** | 仅当段落含内联对象时；与 `InlineFormat` 配套 |
| 27 | `InlineFormat` `:356-367` | `(IntPtr pols, Plsrun, int lscpInline, int currentPosition, int rightMargin, ref ObjDim pobjDim, out int fFirstRealOnLine, out int fPenPositionUsed, out LsBrkCond breakBefore, out LsBrkCond breakAfter)` | **内联对象的尺寸与断行条件** | **A** | 出参**直接就是断行条件**（`breakBefore`/`breakAfter`/`fFirstRealOnLine`）⇒ 含内联对象的段落**必须**有它 |
| 28 | `InlineDraw` `:369-375` | `(IntPtr pols, Plsrun, ref LSPOINT runOrigin, LsTFlow, int runWidth)` | 绘制内联对象 | **B** | 纯渲染 |

**装配面（现取，`LineServicesCallbacks.cs`）**：28 槽**全部**被赋值（`:3268-3293`）并接线——`lscbkRedef` 3 槽（`:3298 pfnFetchRunRedefined`／`:3299 pfnGetGlyphsRedefined`／`:3300 pfnFetchLineProps`）、`contextInfo` **24 槽**（`:3301-3324`，其中 `pfnFetchLineProps`（`:3301`）与 `lscbkRedef`(`:3300`) **重复接线**）、其余 2 槽（`InlineFormat`／`InlineDraw`）以**惰性属性**提供（`:3358-3379`）⇒ **去重后恰好计满 28**。
⇒ **判词：托管侧**无条件**提供全部 28 槽（没有"装配为 null"的槽）** ⇒ **"可缺省"不能靠"托管没装配"来判定**，只能靠在实现层核对 **LS 会不会无条件调用**（⇒ 具名 `NOINFO-LS-FEATURE-FLAGS`）。

---

## §4 与既有两条回调面的结构对比（本件 §4）

| 维度 | `FSCBK`（103 字） | `FSIMETHODS`（17 槽） | **LS 回调面（28 槽）** | 能否迁移 |
|---|---|---|---|---|
| **交接位置** | `FSCONTEXTINFO` 的**成员** | **独立 `ref` 形参** | **两个 `ref` 结构**：`LsContextInfo` ＋ `LscbkRedefined`（`LineServices.cs:1407-1412`） | ✅ 同形 |
| **交接机制** | 委托数组 + `ref`（封送缓冲只在调用期内） | 同 | **同** | ✅ **`t166` 的"窗内值拷贝"方法学可迁移** |
| **运行期调用方向** | native → managed（我们的驱动格调） | 同 | native → managed（**LS 内部算法调**） | ✅ 同向 |
| 🔴 **发起者/时序** | **我们的驱动格**（自选点） | 我们的驱动格 | **LS 的断行过程**；而**LS 会话本身由托管驱动**（`TextFormatterContext.cs:113/:288/:354` 调 `LoCreateContext/LoCreateLine/LoSetDoc`） | ❌ **必须重立**：本侧将成为"**被托管调用、再回调托管**"的**重入方** |
| **结论可迁移性** | `THUNK-LIVENESS`/`D2` 射程等（`t166`/`t170`） | 同 | **值化/寿命机制可援引；重入与寿命口径不可援引** | 见 §2-2 的自我更正 |

⇒ **新增具名前置**：**`PRECOND-LS-SESSION-DRIVER`** —— 一旦实现 LS，本侧要成为**重入方**（托管→我们→托管），其寿命/重入口径**不在 `t166` 的射程内**。

---

## §5 最小入站面清单（本件核心产出）与越级量化

### §5.1 `LS-CB-M1`（**最小入站面 = 9 槽**，不含字形精度）

| # | 槽 | 要什么 | **本侧今天能否作为作者产出**（准入铁律 §A-5） | 代价量级 |
|---|---|---|---|---|
| 1 | `FetchPap` | 段落属性 | ❌ **不是作者**：属性在**宿主**（托管 `TextContainer`/`TextParagraph`） | 一次调用（引擎→宿主） |
| 2 | `FetchLineProps` | 行属性 | ❌ 同上 | 同上 |
| 3 | `FetchRunRedefined` | **文本/字符属性** | ❌ **不是作者**（`PRECOND-NO-TEXT-SOURCE` 已在册） | 同上 |
| 4 | `GetRunTextMetrics` | 字体度量 | ❌ 不是作者（度量在宿主/字体层） | 同上 |
| 5 | `GetRunCharWidths` | **逐字符宽度** | ❌ 不是作者（宽度由字体/字形决定） | 同上 |
| 6 | `EnumTab` | 制表位 | ❌ 不是作者（tab 语义在宿主） | 同上 |
| 7 | `InlineFormat` | 内联对象尺寸与**断行条件** | ❌ 不是作者（对象在宿主） | 同上 |
| 8 | `GetGlyphsRedefined` | 字形映射 | ❌ 不是作者 | 同上（**A−**：可延后） |
| 9 | `GetGlyphPositions` | 字形位置/advance | ❌ 不是作者 | 同上（**A−**：可延后） |

⇒ 🔴 **铁律结论**：`LS-CB-M1` 的 **9 槽没有一槽本侧能作为作者产出** —— 它们**全部是"向宿主取"**。⇒ 本条面**不是**"本侧自持的账"（与 `LM-1` **性质不同**），而是**入站面**：本侧只能**调用**它们、**保管**返回值，**不能发明**它们。
⇒ 若本侧要"自造"这些量（无宿主提供）⇒ 即 **native 自造**（红 `P3`），与 `t185` 的结论一致。

### §5.2 越级量化（将来若接）

- **回调面**：28 槽（最小集 9 槽）。
- **入口面**：LS `[DllImport]` **27 条、22 缺**（`P1-ls-family-recon.md`，引自该件）⇒ **本侧 0 实现**；本侧连 `LoCreateContext` 这一会话入口都没有。
- **内容源＋链上对象**：`PRECOND-NO-TEXT-SOURCE`／`PRECOND-NO-TEXT-PARA-IN-CHAIN`（`t185` 在册）。
- **对照**：几何/计数层 `t151`→`t181`（**十余件**）才到 `S-2a-PARTIAL(7/8)` ⇒ LS 面还多出"22 入口 ＋ 28 回调 ＋ 重入口径" ⇒ **量级判断：≥2 波**（本件不精确估算，只给量级）。
- **`PRECOND-NEW-CALLBACK-FACE` 现在可量化**：**28 槽全表 ＋ 9 槽最小集**（这是本件对将来裁定的实际贡献）。

---

## §6 判「得/不得」与下一步

- **得（备料成功）**：① 28 槽**全表**（签名／语义／判定／依据）；② **`LS-CB-M1`＝9 槽最小入站面**，且**逐槽判定"本侧不是作者"**；③ **结构对比**给出"哪些可迁移、哪些须重立"（§4）；④ **两处口径更正**（30→28 槽；"值化须重立"→"机制可迁移、时序须重立"）。
- **不得（本波不做）**：`S-2b` 实现**仍不做**；`PRECOND-NEW-CALLBACK-FACE`（越级本体）**维持**，且现在**带上了量化依据**。
- **新增具名**：
  - **`PRECOND-LS-SESSION-DRIVER`**：本侧要成为**重入方**（托管驱动 `Lo*` → 本侧 → 回调托管）⇒ 新寿命/重入口径，`t166` 不覆盖。
  - **`NOINFO-LS-FEATURE-FLAGS`**：C 类 13 槽中**哪些会被 LS 无条件调用**，仓内无法判定（托管侧 28 槽**全部已装配**，不能用"没装配"证明可选）⇒ 须在实现层实测。
  - **`NOINFO-LS-INBOUND-PROVENANCE`**：LS 的 `plsrun`／`lscp` 命名空间与 PTS 的 `nmp`／`dcp` 如何对应，仓内未见映射件 ⇒ 将来必须单独立件（**这是"内容层"与"容器层"之间真正缺的那张表**）。
- **下一步（推进一格）**：**不要**接实现；建议下一件只做**两问之一**：**(a)** `plsrun`／`lscp` ↔ `nmp`／`dcp` 的**映射件侦察**（它决定"内容层"能否挂到我们已有的对象身份上）；**(b)** C 类 13 槽的**无条件调用性**在实现层的实测方案设计（含反腿）。二者皆**只读/判据**，不越级。

---

## §7 纪律落地

- 🔴 **`P9`**：本件**不**把"本侧 0 实现 LS"推广成"内容层没有源"——**源在宿主**（`LineServicesCallbacks.cs` 28 槽全部实现并装配，现取）；本件只判"**取它要开面且本侧必须重入**"。
- 🔴 **`P10`**：每条**负面/存在性**判定都附前置 —— "托管全装配"以 `:3268-3293`／`:3298-3324` 现取为据；"本侧 0 实现"以 native `grep`（`t185` 现取 0 命中）为据；"LS 会话由托管驱动"以 `TextFormatterContext.cs:113/:288/:354` 现取为据。
- 🔴 **恒真断言族（§A-7）**：本件全部结论来自**读文件**（不是回显）；**不**使用"两样本一致"类证据；凡"托管都装配了"这类**全集断言**，已给**具体行范围**可复核。
- **模板 §A 其余**：`§A-2` 判词带粒度（本件为**静态结构判定**粒度，并已在 §3 逐槽标注 A/A−/B/C 的可证伪条件）；`§A-3` **不**宣布任何入口"可用"（本件无解除）；`§A-12` 先落最小载体再深挖已在流程中遵守；`§A-13` 交件消息瘦身。

---

## §8 本件自身的验收

1. 新件；末行＝自证行（`head -n -1 <本件> | sha256sum | cut -c1-16`）；`mode 644`；首记号 ＝ `# P1-W103 `。
2. 复核者须**独立重取** §1 表内至少 3 件的 sha16 与引用行（`awk`／`grep` **整行**打原文）；不一致处**只增不改**地追加。
3. 本件**未**授权任何判据放宽；对 `t185` 的处置是**两处口径更正**（§2），对 `P1-ls-family-recon.md` 的引用一律标「引自该件，本席未独立复算」。

---

## §9 附录：现取原文摘录（仅本次有效，整行取）

`LineServices.cs:36-47`（sha16 `8b2bc2167f5c0bd3`）：
```
    internal delegate LsErr FetchPap(
        IntPtr pols,
        int     lscpFetch,
        ref LsPap lspap);

    internal delegate LsErr FetchLineProps(
        IntPtr pols,
        int    lscpFetch,
        int    firstLineInPara,
        ref LsLineProps lsLineProps);
```
`LineServices.cs:1407-1412`（同件）：
```
        [DllImport(DllImport.PresentationNative, EntryPoint="LoCreateContext")]
        internal static extern LsErr LoCreateContext(
            ref LsContextInfo               contextInfo,      // const
            ref LscbkRedefined              lscbkRedef,
            out IntPtr                      ploc
            );
```
`LineServicesCallbacks.cs:3268-3272`／`:3298-3302`（sha16 `612c19e675b7ad30`）：
```
             _pfnFetchRunRedefined                   = new FetchRunRedefined(this.FetchRunRedefined);
             _pfnFetchLineProps                      = new FetchLineProps(this.FetchLineProps);
             _pfnFetchPap                            = new FetchPap(this.FetchPap);
             _pfnGetRunTextMetrics                   = new GetRunTextMetrics(this.GetRunTextMetrics);
             _pfnGetRunCharWidths                    = new GetRunCharWidths(this.GetRunCharWidths);
             lscbkRedef.pfnFetchRunRedefined         = _pfnFetchRunRedefined;
             lscbkRedef.pfnGetGlyphsRedefined        = _pfnGetGlyphsRedefined;
             lscbkRedef.pfnFetchLineProps            = _pfnFetchLineProps;
             contextInfo.pfnFetchLineProps           = _pfnFetchLineProps;
             contextInfo.pfnFetchPap                 = _pfnFetchPap;
```
`TextFormatterContext.cs:113`／`:288`／`:354`（sha16 `00023d954dd580fd`）：`UnsafeNativeMethods.LoCreateContext(`／`UnsafeNativeMethods.LoCreateLine(`／`UnsafeNativeMethods.LoSetDoc(`

---

**判词（本席）**：① **槽数更正为 28**（`t185` 的"30"是含 2 行注释的 `grep -c` 口径），并给出 28 槽**全表**（签名／宿主语义／判定／可证伪依据）；② **判定分三类**：**A（必须由引擎驱动，9 槽＝`LS-CB-M1`）**＝`FetchPap`／`FetchLineProps`／`FetchRunRedefined`／`GetRunTextMetrics`／`GetRunCharWidths`／`EnumTab`／`InlineFormat`（＋**A−** 的字形两槽 `GetGlyphsRedefined`／`GetGlyphPositions`，取决于是否要字形级精度）；**B（仅渲染，6 槽）**；**C（功能门控/可缺省，13 槽，须实测）**；③ 🔴 **`LS-CB-M1` 的 9 槽没有一槽本侧能作为作者产出** ⇒ 这条面是**入站面**，本侧只能**调用并保管**，**自造即红 `P3`** ⇒ **本波不做**（与 `t185` 一致，**合法终点**）；④ **结构对比**：LS 面与 `FSCBK`/`FSIMETHODS` **交接机制同形**（`ref` 结构 + 短命封送缓冲）⇒ **`t166` 的窗内值化方法学可迁移**（**更正** `t185` 的"须重新立"）；**须重立的是"发起者/时序"** ⇒ 新增 **`PRECOND-LS-SESSION-DRIVER`**（本侧将成为**重入方**，`TextFormatterContext.cs:113/:288/:354` 现取托管驱动 LS）；⑤ **`PRECOND-NEW-CALLBACK-FACE` 现已量化**（28 槽全表 ＋ 9 槽最小集 ＋ 27 入口 22 缺），越级量级判断 **≥2 波**；⑥ **新增两条 `NOINFO`**：`LS-FEATURE-FLAGS`（C 类哪些被无条件调用，仓内不可判——托管**全部已装配**，不能用"没装配"证明可选）与 `LS-INBOUND-PROVENANCE`（`plsrun`/`lscp` ↔ `nmp`/`dcp` 的映射件缺失）；⑦ **下一步只许做两问之一**（映射件侦察／C 类无条件调用性实测方案设计），**皆只读**，**不接实现**。
`P1-ls-callback-face-recon 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 8796763b3ae3cb15（末行＝本行）`

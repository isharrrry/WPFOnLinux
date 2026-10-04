# P1-W96 判据（先写）：排版模型（`PRECOND-NO-LAYOUT-MODEL`）—— 宿主在期待什么、最小可辩护形态、谁能产出它

本件是**判据先写**件（`work` 类）：给"排版模型"下定义、给**最小可辩护形态**与**可证伪判据草案**、逐字段给**作者性**、并判它与三级链／消费者路径的关系。
**本件只读，不实现、不跑腿、不构建、不占显示位、不改任何代码**；无运行期腿读数；引他人读数一律带代际并标「引自 X，本席未独立复算」。

---

## §0 身份、边界与在飞件

- 载体：`build/MilBridge/P1-layout-model-criteria.md`（**新建**）。写者＝`scout`；写入面**仅本件**，`$N` 内其余件**一件未改**。
- 结论**只许收紧**；放宽须队长出裁定并在册。
- ⚠️ **在飞件**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 开工现取 **`sha16=d8d784304ff735bf`／326923 B**（mtime 19:13:50）—— **与 `t173` 交出的 `e41df5d4c77610ac` 不同（已换代）** ⇒ 本件对他的引用**行号只在该代有效**；实现/复核者开工前**必须重取**。HEAD＝`d4d2176`。

---

## §1 台账（读取时刻＝2026-09-29 19:34–19:40，本席本地，仅本次有效）

| 件 | sha16 | 用途 |
|---|---|---|
| `PtsHost/ContainerParagraph.cs` | `1d0128592496706d` | **消费面 A**：`:550-596` 读 `fsfmtr.kstop`／`pmcsclientOut`／`fsbbox`／`pbrkrecOut`；`:526-531` 调用点 |
| `PtsHost/PtsHelper.cs` | `f2ed9552e983fed1` | **消费面 B**：`:150-181` `ArrangeParaList` 读段落描述里的 `dvrUsed`／`dvrTopSpace` 并算每段矩形 |
| `PtsHost/BaseParaClient.cs` | `e48fc11de3f65d09` | `:61-83` `Arrange` 落 `_rect`/`_dvrTopSpace`；`:90` 基线；`:139` 转布局 DPI；`:210` `Rect` 暴露 |
| `PtsHost/PtsHost.cs` | `d1976dcc8362c8f9` | 槽 3 实现 `:2662-2725`（`fBreakInsidePossible = PTS.False` 硬写 `:2692`） |
| `PtsHost/PtsContext.cs` | `c91e3f94d1188ece` | `:405 CallbackException`（异常类型可读，见 §9） |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `d8d784304ff735bf`（326923 B） | 本侧现状（页几何 `pg_w/pg_h`、子轨对象 `dp->sub`、`kstop` 留痕等） |
| `build/MilBridge/P1-fsformatsubtrack-report.md`（`t173`） | 105 行；末行自证 `89b5ddc5e7716846`（**本席当场复算 MATCH=yes**；内部读数未复算） | `M1` 六形态全中、`S-1` 成立、`S-2` 维持 `NOINFO`、硬阻塞转 `PRECOND-NO-LAYOUT-MODEL` |
| `build/MilBridge/P1-fsimethods-verify.md`（`t170` 复核） | 152 行；末行自证 `21ea356bacc7faca`（**本席当场复算 MATCH=yes**；内部读数未复算） | 🔴 **推翻项**：`SLOT-ORDER-OK` 推理**不充分**（F-1 high）；`calls=1/2` 与 `calls=0` **不是同一把标尺**；`D2` 只授权**否定**、不授权**解除** |
| `build/MilBridge/P1-fsimethods-abi-recon.md`（`t166`，本席前件） | 208 行；自证 `35041d7b492824b0` | D1/D2/D3 三条判别的唯一出处（本件**据 `t170` 收窄其 D2 的射程**，见 §9） |
| `build/MilBridge/P1-fsformatsubtrack-recon.md`（`t169`，本席前件） | 230 行；自证 `b7b10d873d559c65` | `M1` 的逐项口径与该族族边界（本件直接沿用，不重做） |

---

## §2 「排版模型」在这里到底指什么（消费面逐跳）

**判词：排版模型 ＝ 一组「本侧自持、可按对象回答」的事实**（不是"文字/内容"，那是 LineServices 面）：
**(i) 每个容器的子段数 `cParas`；(ii) 每个子段的垂直占位与矩形（`dvrUsed`／`dvrTopSpace`／`fsrc`／`fsbbox`）；(iii) 在该待填矩形内"放得下/放不下"（决定 `kstop` 与是否续排 `brkOut`）。**

### §2.1 消费面 A：宿主在 `FormatParaFinite` 内部怎么读引擎的出参（`ContainerParagraph.cs`）

| 出参 | 读点（现取） | 怎么消费 | **填 0／留空会走哪条分支（`P8`）** |
|---|---|---|---|
| `fsfmtr.kstop` | `:551`、`:565` | `:551 ≥ fmtrNoProgressOutOfSpace(8)` ⇒ `dvrUsed = 0`；`:565 == fmtrGoalReached(0)` ⇒ **做下边距塌陷**并 `dvrUsed += marginBottom + mbp.BPBottom` | **`kstop=0` ＝"这一段排完了"**（不是"无信息"）⇒ `t173` 的 `kstop=1` 正是防这条 |
| `dvrUsed` | `:548`（`dvrUsed += (fsrcToFillSubtrack.v - fsrcToFill.v)`）、`:551`、`:575-576`、`:580` | 参与本段垂直占位，并**向上交给引擎**（槽 3 的 `out dvrUsed`） | 0 ⇒ 本段占位 0（见 §2.2 的连带后果） |
| `fsbbox` | `:585-592` | 按 MBP 调整；若 `fswdirSubtrack != fswdir` 还要 `FsTransformBbox` | 空/未定义 ⇒ 页几何里该段无盒 |
| `pmcsclientOut` | `:558-561` | **非零就 `HandleToObject(pmcsclientOut) as MarginCollapsingState`** ⇒ `ValidateHandle` | **非零 = 声称有一个托管 MCS 对象** ⇒ 必须是**宿主自己的句柄**（本侧造不出）⇒ 只能 0 |
| `pbrkrecOut` | `:596` | `paraClient.SetChunkInfo(pbrkrecIn == IntPtr.Zero, pbrkrecOut == IntPtr.Zero)` | `brkOut=nil` ⇒ `_isLastChunk=true` ⇒ 见 §2.3 |
| `pfspara`（=`ppfsSubtrack`） | `:526` 出参 → 上游（槽 3 `out pfspara`） | 供**引擎自己**后续查询（`FsQuerySubtrackDetails`/`FsUpdateBottomlessSubtrack`） | `nil` ⇒ 后续查询无对象可答（`t161` 的钥匙无源） |

### §2.2 消费面 B：**段落描述里的垂直量**（`PtsHelper.cs:150-181`，第二张面，容易被漏）

```
:154            int dvrPara = 0;
:174                int dvrTopSpace = arrayParaDesc[index].dvrTopSpace;
:175                PTS.FSRECT rcPara = rcTrackContent;
:176                rcPara.v += dvrPara + dvrTopSpace;
:177                rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;
:179                paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);
:180                dvrPara += arrayParaDesc[index].dvrUsed;
```
⇒ `BaseParaClient.Arrange` 把它落成几何：`BaseParaClient.cs:68 _rect = rcPara;`／`:72 _dvrTopSpace = dvrTopSpace;`，再经 `:90 GetFirstTextLineBaseline() => _rect.v + _rect.dv`、`:139 rect = TextDpi.FromTextRect(_rect)`、`:210 internal PTS.FSRECT Rect { get { return _rect; } }` 暴露给页/结果面。
🔴 **P8 判词（本件新增）**：`FSPARADESCRIPTION.dvrUsed = 0`（**本侧今天正是 0**：`t160`/`t162` 的填充只写 `pfspara`/`pfsparaclient`/`nmp`）⇒ `rcPara.dv = 0 - dvrTopSpace` ⇒ **零或负高矩形**，且 `dvrPara` 永远不增长 ⇒ **每段都叠在同一个 v 上**。⇒ **"排版模型"必须同时供给 `FSPARADESCRIPTION` 的垂直量**，否则不是"没有排版"，而是"**声称每段高 0**"——一句会被下游当真话消费的假话。

### §2.3 消费面 C：`_isLastChunk` → 嵌套内容是否被递归（`ContainerParaClient.cs:278`）

`ContainerParaClient.GetTextContentRange()`（`:260`）**第一件实招**是 `FsQuerySubtrackDetails`（`:271`），随后 `:278`：
`if (subtrackDetails.cParas == 0 || (_isFirstChunk && _isLastChunk)) { 叶子分支，不递归 }`
⇒ 而 `_isLastChunk` 由 `pbrkrecOut == IntPtr.Zero` 决定（`:596`）⇒ **`cParas=0` 与 `brkOut=nil` 都会让宿主走叶子分支、把整棵嵌套内容静默丢掉**。⇒ **`cParas` 与 `brkOut` 都不是"缺省值"，而是会改变控制流的断言**（`P8`）。

### §2.4 消费面 D：**引擎侧（我们自己）** —— 今天 `NOINFO`

`dvrUsed`／`fsbbox`／`pbrkrecpara`／`fsfclearOut` 经槽 3 回到**调用者**（引擎）。今天本侧**没有**造型驱动入口，因此"引擎怎么用它"**无读数**（`NOINFO-ENGINE-SIDE-CONSUMER`）——这正是 `t173` 把阻塞记为"无排版模型"的实质。

---

## §3 最小可辩护形态（`LM-1`）＋判据草案

### §3.1 形态定义

**`LM-1` ＝「本侧自持的段账」**：本侧以**自己驱动的调用**为单位记账，产出
① 每容器**子段数** `cParas`；② 每子段**垂直占位**（`dvrUsed`／`dvrTopSpace`）与**矩形**（`fsrc`／`fsbbox`）；③ **放得下/放不下**的判定（`kstop`／`brkOut`）。
**它明确不包含**：文字/字形/行盒（LineServices 面）、内容身份（`N1–N4` 的内容侧）、可见墨迹。

**不变量（可证伪，逐条）**
- I-1 `cParas ≥ 0`；**`cParas = 0` 只能在该容器确无子段时给出**（真腿已证存在嵌套关系 ⇒ 不得为 0）。
- I-2 `dvrUsed ≥ 0`，且 **`dvrUsed ≥ dvrTopSpace`**（否则 `:177` 的 `rcPara.dv < 0`）。
- I-3 Σ(子段 `dvrUsed`) ≤ 容器可用高度（`fsrcToFill.dv`）；越界**必须**报 no-progress/out-of-space，**不许**静默截断。
- I-4 `fsbbox.fsrc` 与 `fsrc` 自洽（同向、包含或相等），且 `fDefined` 如实。
- I-5 **跨调用稳定**：同输入两次调用，`cParas` 与几何**一致或具名不同**（幂等性**现取判定**，禁沿用前跳结论）。
- I-6 **零托管依赖**：`LM-1` 不得要求任何新的托管对象/句柄（否则就越成 §5 的"新身份级"）。

### §3.2 判据草案（照契约三件套写）

- **`objective`**：在**副本**驱动格内，让 `ContainerParagraph`／`PtsHelper.ArrangeParaList` 这条消费链拿到**自洽的段账**：`cParas`＝本侧驱动次数、每段 `dvrUsed/dvrTopSpace/fsrc/fsbbox` 满足 I-1..I-6，且宿主可据此算出**非零**的 `rcPara.dv`。
- **`acceptance`（八条合取，缺一不绿）**：
  1. `rc=0` 且本入口**被真调**（`calls>0`；`calls=0` 只说"没发出去"——`P10`）；
  2. `cParas` **非零**且＝本侧驱动计数（逐值可核）；
  3. 每个子段 `dvrUsed>0`、`dvrUsed ≥ dvrTopSpace`（I-2）；
  4. 宿主侧**出现**消费证据：`ArrangeParaList` 走过至少一次且 `rcPara.dv > 0`（可用 `_rect`／`GetFirstTextLineBaseline` 的读回证明）；
  5. `kstop` ∈ {goalReached, out-of-space 族} **且与实际是否放得下自洽**（不得恒 `no-progress`）；
  6. `brkOut` 的零/非零**与"是否续排"自洽**（放不下却给 `nil` ⇒ 红）；
  7. `bbox` 非空且与 `fsrc` 自洽（I-4）；
  8. **≥2 独立样本判词相同**（裁定三十八）；且**每条读数带纪律三十三格＋探针闸状态**。
- **`verify`**：`<leg> >out 2>err; echo $?`（**不许从管道尾巴取 `rc`**）；`grep -c` 出具名行计数；两样本逐格比对；`FsQueryPageDetails` 的 `trackdescr.fsrc` 非空作**页面**旁证。
- **粒度（`t173` 教训）**：以上**每一条都绑定粒度** —— 1–4 是**单次调用/单段**粒度；**"整腿"**还需：调用发生在**真实页构造窗**（`FsCreatePage*`）内、消费者侧有计数、页面几何非空。**判据里必须写明它成立在哪个粒度**，禁止把"单次对了"写成"整腿绿"。

### §3.3 `S-2` 的细分（本件最重要的收紧）

`t173` 维持 `S-2`＝`NOINFO`。本件**把它拆开**：
- **`S-2a`（几何/计数层，**本波可判**）**：上表 §3.2 的八条 ⇒ 若全中，判词＝**"排版模型（几何/计数层）成立"**；
- **`S-2b`（内容层，**本波不可判**）**：内容身份／行盒／墨迹 ⇒ 维持 **`NOINFO-LAYOUT-CONTENT`**（`t164`/`t166` 已在册）。
⇒ **禁止**用 `S-2a` 的绿去宣布 `S-2b` 或整页"排版成功"。

---

## §4 准入铁律：逐字段判作者性（裁定五十一 (b)：**准入 ＝ 本侧是该值的作者**）

| 字段 | 本侧是不是作者 | 依据／代价 |
|---|---|---|
| `cParas`（子段数） | ✅ **是**（**本侧驱动的调用计数**） | `t163` §3.2：引擎"一次成功造型＝一个段落"⇒ 数自己的驱动即得；先例 `FsQueryTrackDetails`＋`wpf_pts_fsp.c_paras`（按对象答数、反腿一对） |
| 子段 `dvrUsed`／`dvrTopSpace`／`fsrc`／`fsbbox` | ✅ **是**（**本侧矩形与占位的算术**） | 本侧已持页几何（`win32_pts.c` 现取代：`pg_w/pg_h`）；`t164` 的作者性铁律 |
| `kstop`（放得下与否） | ✅ **是**（**本侧判定的结果**） | 但必须**与实际几何自洽**（§3.2-5），不得恒填一个值 |
| `brkOut`（是否续排） | ✅ **是**（本侧自有断页记录或 `nil`） | `t169` §4：本族只做零比较 ⇒ `nil` 合法；**但语义必须与放得下与否自洽** |
| `ppfsSubtrack`／`pfspara` | ✅ **是**（`t162`/`t169` 已落地） | 本侧自查找表＋认领谓词 |
| `pmcsclientOut` | ⛔ **不是**（MCS 是**宿主**对象） | 只能 0（`:558` 会 `HandleToObject`）⇒ 具名 **`PRECOND-MCS-OWNER-HOST`**（本侧永不产出非零值） |
| `pfsbrkrec` 的**内容** | ⚠️ **本侧是作者，但今天没有内容** | `NOINFO-BREAKREC-CONTENT`（跨页续排才需要） |
| 子段**真实文本/字形** | ⛔ **不是**（LineServices 面） | 越本波写域 ⇒ `NOINFO-LAYOUT-CONTENT` |
| 任何**托管句柄/对象**（`nmp`／`pfsparaclient`／`fsnmSegment`／`MCS`） | ⛔ **不是**（入站给的） | 声称存在 = 伪造 ⇒ 红（`t164` §3） |

**⇒ "谁能产出它"的判词**：**只有本侧（引擎）能产出 `LM-1` 的六类字段**；其中**五类本侧本就是作者**，一类（`pmcsclientOut`）**本侧永远不能是作者**（⇒ 固定 0＋具名前置）。**不存在**"某个托管回调会把排版模型送下来"这条路（`FSIMETHODS` 17 槽现取：槽 3/4 只**吃** `pfsgeom` 并**产** `pfspara`/断页记录，**不产**段账）。

---

## §5 它与三级链的关系（第 4 级？还是平行支？）

**判词：都不是——它是同一支上的"收尾账"，不是新的身份级。**

依据（逐条可核）：
- **三级链是什么**：`nms`(`t151`，`+80` 产出) → `nmp`(`t155`/`t156`，`+136` 产出) → `pfsparaclient`(`t156`，`+176` 产出) —— **三级全部是"托管交给本侧的句柄"**（身份由**托管**产生）。
- **`LM-1` 是什么**：它的字段**全部由本侧算术/计数得到**（§4 表），**不引入任何新的托管句柄**；它的**输入**正是三级链的产出（用 `nmp` 定位容器、用 `pfsparaclient` 定位消费者）。
- ⇒ 判据（可证伪）：**I-6「零托管依赖」** —— 若某实现为了取段账而**新增一个托管回调/新槽/新句柄**，那它就**越成"第四级身份"** ⇒ **判红并转队长裁定**（因为那会引入新的 ABI 与寿命面，等于另开一跳）。
- **与"驱动方向"的关系**：三级链是**入站**（宿主→引擎交身份）；`LM-1` 是**出站**（引擎→宿主回答量与几何）。⇒ 表述上：**"三级链＝三枚身份；排版模型＝那三枚身份之上的第一笔账"**。

---

## §6 它与消费者路径的关系（`FsQuerySubtrackDetails`／`FsQuerySubtrackParaList`）

**判词：`LM-1` 是 `FsQuerySubtrackDetails` 的**唯一上游源**；`FsQuerySubtrackDetails` 是**钥匙**（`t161` 在册），而**它的源就是本件靶心**。**

- `ContainerParaClient.cs:271` 调 `FsQuerySubtrackDetails(ctx, _paraHandle, …)`；`:278` **用 `cParas` 分流**；`:283` 才 `ParaListFromSubtrack` → `PtsHelper.cs:629` **用 `cParas` 开数组** → `:633` `FsQuerySubtrackParaList` → `:289`/`:294` 递归。
- ⇒ 顺序：**`LM-1`（段账） → `FsQuerySubtrackDetails`（答 `cParas`） → `FsQuerySubtrackParaList`（答列表） → 消费者**。
- ⇒ 所以 `t161` 立的那把"钥匙"**本身无源**（`t161` §3.3 已判"真阻塞"）；**本件把那个"源"定义清楚了**：源不是某个回调槽，而是**本侧的段账**。
- 🔴 `P9`：**不得**因为"17 槽无段数源"就断言"段数没有源"（`t163` 已判回调面无源、引擎侧有源）。

---

## §7 红榜 `P8` 逐格总表（凡"填 0／留空"必须回答宿主走哪条分支）

| 填 0／留空处 | 宿主分支（现取行） | 判词 |
|---|---|---|
| `fsfmtr.kstop = 0` | `ContainerParagraph.cs:565` ⇒ 走"排完了"⇒ 做 margin collapsing、`dvrUsed += …` | **红**（假"排完"） |
| `pmcsclientOut = 0` | `:558` 不进入 ⇒ 不解析 | **必须 0**（非 0 即声称宿主对象存在） |
| `pbrkrecOut = nil` | `:596` ⇒ `_isLastChunk=true` ⇒ `:278` 叶子分支 | **看语义**：确无边距续排则合法；**有嵌套却给 nil** ⇒ 红 |
| `cParas = 0` | `:278` 叶子分支 ⇒ **不递归** | **红**（真腿已证有嵌套） |
| `dvrUsed = 0`（段落描述内） | `PtsHelper.cs:177` ⇒ `rcPara.dv = -dvrTopSpace` ⇒ 零/负高 | **红**（"每段高 0"是被下游当真的断言） |
| `fsbbox` 空 | `ContainerParagraph.cs:585-592` ⇒ 调整后仍空 ⇒ 页几何无盒 | 红（若同时声称有内容） |
| `dvrTopSpace > dvrUsed` | `:177` 负高；`:540` 另有 `> dvBottomUndefined/2` 的 workaround | 红（违反 I-2） |

---

## §8 粒度（`t173` 的 `S-1` 教训落地）

- `M1` 的成立粒度＝**单次调用**（`calls=1` 级别的契约正确）。**它不证明**：整页链通、消费者被走到、页几何非空。
- `LM-1` 的判据**必须逐条标注粒度**：§3.2 的 1–4 是"单段/单次"；**"整腿"** 需三样齐备：① 调用发生在**真实页构造窗**内且 `calls>0`；② 消费者侧有**计数证据**（`ArrangeParaList`／`GetTextContentRange` 被走过）；③ **页面**几何非空（`FsQueryPageDetails` 的 `trackdescr.fsrc`）。缺任一 ⇒ 只写"单段粒度成立"，**不许**写"整腿绿"。

---

## §9 与 `t170` 复核的关系（前置纪律，必须带在身上）

- `t170`（复核件 `build/MilBridge/P1-fsimethods-verify.md`，152 行／自证 `21ea356bacc7faca`，**引自该件、内部读数未独立复算**）判：**`SLOT-ORDER-OK` 的推理不充分**（F-1 high）——"唯一零位在第 15 槽"是**托管表自身的自洽性**，**对 ABI 语义盲**；`D2` 只授权**否定**，不授权**解除** `NOINFO-FSIMETHODS-ABI`；且 `calls=1/2` 与 `calls=0` **不是同一把标尺**。
- ⇒ **本件据此收紧自己的前件**：`t166` 的 `D2` **射程仅限"否证"**（零位不吻合 ⇒ 可判错位）；**不得**用它逆推"槽序正确"。
- ⇒ **对 `LM-1` 的约束**：① 本件**不依赖** ABI 结论；② 若下一件要把 ABI 结论动一格，须用**只差一变量的成对实验**（裁定五十八的正向解法）＋**行为证据**（`t173` 的六形态是**行为证据**，强于零位指纹，但仍**不覆盖 ABI 语义**）；③ 谈 `calls` 必须**同尺**（同一探针、同一窗）。
- 🔴 `P10`：本件所有负面判词都附前置 —— "说缺段账"要先证**调用真的发出**（`calls>0`）；"说消费者没走"要以**消费者侧计数**证，不许以失败专用行的缺席证。

---

## §10 排期含义（下一件、推进一格、代价与风险；允许判"做不到"）

- **下一件（建议）**：**`LM-1` 的最小实现（副本内）＋ §3.2 八条读数 ＋ 粒度标注**；顺手把 `t169` §6 的**免费判别**做掉（读 `PtsContext.CallbackException.GetType().FullName`，`PtsContext.cs:405` 已持有该对象）——它能把"缺入口"从假设升成读数（或推翻）。
- **"推进一格"的判据**：`S-2a` **从 `NOINFO` 变为可判且被判**（八条合取）∧ 每格带粒度 ∧ `S-2b` 与页内容面**仍 `NOINFO`**。
- **代价与风险**：
  1. 🔴 **假绿风险（最高）**：`dvrUsed>0` 会让宿主**真的排布**（`PtsHelper.cs:174-180` → `_rect` → 页结果）⇒ 可能把"空排"变成"看似有几何的空页"⇒ **只许副本先行 ＋ 必须给"主链产物逐字节不变"的成对证据**。
  2. **涉 `t132` 三级链**：`LM-1` 的输入全是入站句柄（`nmp`／`pfsparaclient`／`fsnmSegment`），而 native **无能力校验托管句柄**（`t169` §5.3）⇒ 只能"不校验、按不透明处理"，必须写在留痕里。
  3. **涉 `t141` 快照纪律**：本入口**无回调表**可快照（不经 `FSCBK`/`FSIMETHODS`）⇒ 不触发缓冲寿命问题；**但有对象生存期**问题（`ppfsSubtrack` 必须在后续调用仍可认领）。
  4. **粒度风险**：`M1` 的教训 ⇒ 八条里凡不能同时给"整腿三样"的，**只能记单段粒度**。
- **允许判"本波不该做／做不到"（合法终点）**：若队长口径要求"**必须有内容/行盒才算排版**"，则 `LM-1`（几何/计数层）**不足以**满足 ⇒ 应落 **`PRECOND-NO-LAYOUT-CONTENT-MODEL`** 并把下一跳改判到 **LineServices 面**（本侧今天无字形/行盒模型）——**这是本件明确授权的终点**，且**不得**被读成"`LM-1` 没价值"（`P9`）。

---

## §11 本件自身的验收

1. 新件；末行＝自证行（`head -n -1 <本件> | sha256sum | cut -c1-16`）；`mode 644`；首记号 ＝ `# P1-W96 `。
2. 复核者须**独立重取** §1 表内至少 4 件的 sha16 与引用行（`sed -n`/`awk` **整行**打原文）；`win32_pts.c` **必须重取**（在飞）；不一致处**只增不改**地追加。
3. 本件**未**授权任何判据放宽；对 `t166` 的处置是**收窄 `D2` 射程**（§9），对 `t173` 的处置是**细分 `S-2`**（§3.3）。

---

## §12 附录：现取原文摘录（仅本次有效）

`PtsHelper.cs:154-180`（sha16 `f2ed9552e983fed1`，**整行取**）：
```
:154            int dvrPara = 0;
:174                int dvrTopSpace = arrayParaDesc[index].dvrTopSpace;
:175                PTS.FSRECT rcPara = rcTrackContent;
:176                rcPara.v += dvrPara + dvrTopSpace;
:177                rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;
:179                paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);
:180                dvrPara += arrayParaDesc[index].dvrUsed;
```
`BaseParaClient.cs:61-72`（sha16 `e48fc11de3f65d09`）：`Arrange(IntPtr pfspara, PTS.FSRECT rcPara, int dvrTopSpace, uint fswdirParent)` ⇒ `:65 _paraHandle = pfspara;`、`:68 _rect = rcPara;`、`:72 _dvrTopSpace = dvrTopSpace;`
`ContainerParagraph.cs`（sha16 `1d0128592496706d`）：`:551` `if (fsfmtr.kstop >= …fmtrNoProgressOutOfSpace) { dvrUsed = 0; }`；`:558` `if (pmcsclientOut != IntPtr.Zero) { …HandleToObject(pmcsclientOut) as MarginCollapsingState… }`；`:565` `if (fsfmtr.kstop == …fmtrGoalReached) { …CollapseBottomMargin… }`；`:596` `paraClient.SetChunkInfo(pbrkrecIn == IntPtr.Zero, pbrkrecOut == IntPtr.Zero);`
`ContainerParaClient.cs`（sha16 `0d2e6aa79fdc035a`）：`:271` `PTS.Validate(PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails));`；`:278` `if (subtrackDetails.cParas == 0 || (_isFirstChunk && _isLastChunk))`

---

**判词（本席）**：① **"排版模型"＝一组本侧自持、可按对象回答的事实（子段数／每段垂直占位与矩形／放得下与否）**，**不是**文字与行盒；② 宿主在两张面上消费它——`ContainerParagraph.cs:550-596`（`kstop`／`dvrUsed`／`fsbbox`／`mcsOut`／`brkOut`）与 `PtsHelper.cs:174-180`（**段落描述里的 `dvrUsed`/`dvrTopSpace`** → `BaseParaClient._rect` → 页几何）；③ **最小可辩护形态 `LM-1`＝本侧段账**，八条合取判据 ＋ 六条不变量已给出，并**把 `S-2` 细分为 `S-2a`（几何/计数层，本波可判）与 `S-2b`（内容层，维持 `NOINFO`）**；④ **准入铁律**：六类字段里**五类本侧本就是作者**（计数/几何/放得下判定/自有对象），**`pmcsclientOut` 本侧永远不能是作者**（固定 0＋`PRECOND-MCS-OWNER-HOST`），**凡声称托管对象/句柄存在即伪造**；⑤ **与三级链的关系**：**不是第四级身份，也不是平行支**，而是"三枚身份之上的第一笔账"（判据 `I-6` 零托管依赖：若实现引入新托管句柄 ⇒ 越级 ⇒ 判红转裁定）；⑥ **`LM-1` 正是 `FsQuerySubtrackDetails`（`t161` 的钥匙）的上游唯一源**，因此顺序是 **段账 → `cParas` → 列表 → 消费者**；⑦ **`P8` 已逐格落地**（尤其 `dvrUsed=0` ⇒ `rcPara.dv` 零/负 ⇒ "每段高 0"会被下游当真话消费），**粒度**（单段 vs 整腿三样）已写死在判据里；⑧ **前置纪律**：本件**不依赖** `t170` 已判"不充分"的 `SLOT-ORDER-OK`，并把 `t166` 的 `D2` 射程**收窄为仅可否证**。
`P1-layout-model-criteria 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 03460258dfa88ae2（末行＝本行）`

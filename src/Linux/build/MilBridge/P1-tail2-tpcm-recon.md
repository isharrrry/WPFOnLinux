# P1-tail2 `T-A29` · `PRECOND-TEXTPARA-CONTENT-MODEL` 可得性 —— 只读侦察

- **读时**：`2026-09-30T15:3x+0800`（本席现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=55ad709cbbb85c3a3e7f80becc4df10b715bd06b`（现取；**已从 `T-A28` 的 `74a444cf…` 换代**）。
- **现件代**（`sha256` 前 16 位，现取）：`src/WpfGfx.Linux.Native/src/win32_pts.c`＝**`bcd6a00bce9f67a2`**（461075 B，**与 `T-A28` 交出同代、未漂移**）｜`build/shims/PresentationCore.HbTextLine.cs`＝`921ba9c65e9fb3be`（293165 B）｜`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`＝`fa058b134c64e068`（69432 B，**生成件**）｜`build/PresentationFramework.Linux/PtsCache.Linux.cs`＝`e5b399fdb8742092`（生成件）｜`upstream/…/PtsHost/LineBase.cs`＝`e94c062f2124dbeb`（15418 B）｜`Line.cs`＝`f4b62971e881d247`｜`TextParagraph.cs`＝`332b782b842e307e`｜`ContainerParagraph.cs`＝`1d0128592496706d`｜`Pts.cs`＝`1a8575a18767a956`。
- **边界（照 `T-A29` ②）**：**只读**；除本载体外**未改任何仓内文件**；**未构建**；**未改** `src/**`／`build/**`；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`；进程只按 PID；**未占任何显示位**；**未 `sleep` 轮询**；大件只用 `wc`／`head`／`tail`／`grep`；未 `git add/commit/push`。
- **引他处读数**：运行期证据取自 `T-A28` 车道产物 `~/tA28-work/legs-d/app_g1.log`（**仓外**；本席**只读**其 `grep -n`／行取输出，**未复跑腿**）；`nmp=_firstChild` 引自 `build/MilBridge/P1-nmp-type-report.md`（**未独立复算**）；`LoCreateLine` 未导出引自 `build/MilBridge/P1-tail2-hostline-recon.md` §1.1（**未独立复算**）。
- **行号纪律**：本件行号**仅本次有效**（内容锚原文一并给出）。

---

## §0 结论速览（自包含）

1. **判据原文**（`upstream/…/PtsHost/LineBase.cs:137`）：`Invariant.Assert(!(element is Block), "We do not expect any Blocks inside Paragraphs");`
   —— **触发条件**：在 **ElementStart 边**上，`position.GetAdjacentElement(Forward)` 转 `TextElement` 后**`is Block` 为真**（§1.1）。
2. **内容面现取（我方实例）**：叶 `0x8/0x9/0xa` 是 **`TextParagraph`**（日志 `[NMP-TYPE]` 现取）；其**直接内容装 Inline**（文档里 `Paragraph` ＝ 文本 ＋ `Bold`(Span) ＋ `Figure`/`Floater`(AnchoredBlock **: Inline**)）。`ContainerParagraph`（`0x2/0x3/0x4/0x6/0x7`）**装 Block**（`Section`／`Paragraph`）—— **设计如此**（§1.3）。**Blocks 只出现在 `Figure`/`Floater` 子树内部**（`<Paragraph>`／`<Table>`），落在 `TextParagraph` 的 text-container **跨度内**，契约上只能以**不透明 `FloatingRun`** 整体消费（§1.3）。
3. 🔴 **"内容面"不是真前置**：该 `TextParagraph` 的直接内容**本来就是 Inline-only**（上游语义，**无缺陷**）。断言能被触到，只可能是**驱动的探测偏移**落到了某个 `Block` 的 ElementStart 上 ⇒ 真前置是「**行模型给出的下一行起点不是元素安全位**」（§2）。
4. **来源归因**：段落树**不是 native 造的** —— `+136`／`+144` 向托管 PtsHost 取（`nmp` ＝ 托管 `_firstChild`）；native 的 `rgParaDesc`／子段对象**只装不透明句柄**，**从不装 Block/Inline**。⇒ **不是"我方填错"**；Blocks 是**文档的真内容**（`FlowDocumentDemo.xaml` 现取）。见 §2。
5. **候选路**：**(甲)** native 修内容面 —— **语义上做不到**（native 不拥有内容）；唯一 native 杠杆＝改"驱动"，那只是**回避**，且 native **无从判段内有无 `Figure`/`Floater`** ⇒ 零产品价值。**(乙)** 托管侧（shim ＋ 生成器）—— **可及 ∧ 可行 ∧ 代价中高**，`P8` 落点＝`build/shims/**` ＋ 生成器。**(丙)** 其它 —— 合法终点（§3）。
6. **结论 ＝ 不可行（在 `T-A28` 的 native 写域内）**：具名前置 **`PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS`**（**承重**）＋ `PRECOND-TEXTPARA-CONTENT-MODEL` **归位为"不成立／误名"**；合法终点 ＝ `WPF_PTS_FL_DRIVE` **缺省保持关**（§4）。**若另开"行模型写域"**，§A 给设计草案 ＋ 4 条判据 ＋ 反极性。
7. **本件自带两条反腿**：① **不**把"`TextParagraph` 直接内容 ＝ Inline"读成"驱动它一定安全"（探测偏移可以落在**嵌套 Block** 上）；② **不**把"断言由 Block 触发"读成"内容面坏了"（同一现场也可由**跨过段尾**的探测产生，本件**未**分辨，见 §5 `NOINFO-BLOCK-SITE-OFFSET`）。

---

## §1 ① 判据原文 ＋ `TextParagraph` 内容面现取

### 1.1 `FailFast` 判据（逐字，件:行）

| 面 | 件:行 | 原文 |
|---|---|---|
| **断言（判据）** | `upstream/wpf/…/PtsHost/LineBase.cs:137` | `            Invariant.Assert(!(element is Block), "We do not expect any Blocks inside Paragraphs");` |
| 同函数首断言（上下文） | `LineBase.cs:130` | `            Invariant.Assert(position.GetPointerContext(LogicalDirection.Forward) == TextPointerContext.ElementStart, "TextPointer does not point to element start edge.");` |
| 取"被撞的元素" | `LineBase.cs:134` | `            TextElement element = (TextElement)position.GetAdjacentElement(LogicalDirection.Forward);` |
| 调用者（ElementStart 支） | `Line.cs:146-148` | `                case TextPointerContext.ElementStart:` ／ `                    run = HandleElementStartEdge(position);` |
| **探测位置怎么来** | `Line.cs:138` | `            StaticTextPointer position = textContainer.CreateStaticPointerAtOffset(_cpPara + dcp);` |

⇒ **判据（写死）**：`HandleElementStartEdge` 在 **ElementStart 边**上取到的元素（`GetAdjacentElement(Forward)`）**`is Block` 为真**即失败。`Figure`/`Floater` **不是** Block（`AnchoredBlock : Inline`，§1.3(c)）⇒ 它们**不**触发本断言（走 `LineBase.cs:139-154` 的 `FloatingRun` 分支）。`Invariant.FailFast` **不可捕获** ⇒ 进程终止（`T-A28` 现取：`app_rc=134`／`failfast=4`）。

**`Block` 族（判据所指的是谁）**：`Block` 是抽象基类（`Block.cs:23` `public abstract class Block : TextElement`）；`Section`／`Paragraph`／`Table`／`List`／`BlockUIContainer` 都是它（§1.3(c)）。

### 1.2 触发路径（谁、在哪个偏移上调它）

**运行期栈（外部证据，`~/tA28-work/legs-d/app_g1.log:691-713` 逐字，本席只读现取）**：

```
Unrecoverable system error.: We do not expect any Blocks inside Paragraphs
   at MS.Internal.PtsHost.LineBase.HandleElementStartEdge(System.Windows.Documents.StaticTextPointer)
   at MS.Internal.PtsHost.Line.GetTextRun(Int32)
   at MS.Internal.PtsHost.TextFormatterHost.GetTextRun(Int32)
   at WpfLinux.Shims.PresentationCore.HbTextFallback.TryCollect(…)
   at WpfLinux.Shims.PresentationCore.HbTextFallback.TryBuildPlan(…)
   at WpfLinux.Shims.PresentationCore.HbTextFallback.TryFormatLine(…)
   at MS.Internal.TextFormatting.TextFormatterImp.FormatLineInternal(…)
   at MS.Internal.PtsHost.Line.Format(…)
   at MS.Internal.PtsHost.TextParagraph.FormatLineCore(…)
   at MS.Internal.PtsHost.TextParagraph.FormatLine(…)
   at MS.Internal.PtsHost.PtsHost.FormatLine(…)
   at …PTS.FsCreatePageBottomless(…)          ← native 驱动窗内
```

⇒ **谁在调**：native 窗内驱动格 `wpf_pts_format_one_para`（`win32_pts.c:2097-2174`）；它把**上一行返回的 `dcpLine` 累加**后当**下一行的起点偏移**回喂（`win32_pts.c:2152` 逐字 `dcp += dcpLine;`），下一跳经 `TextParagraph.FormatLine` → `Line.Format` →（本移植被 patch 接的）**shim** 去**再探** `GetTextRun(_cpPara + dcp)`。

**断点处的驱动读数（同上日志 `:681-690` 逐字）**：`para=0x8` 连出 **8** 行 `rc=0`，`dcpLine` ＝ `88,98,98,102,103,99,93,275`（**`Σ=956`**），**每行 `fsflres=0`（＝`fsflrOutOfSpace`）**；第 8 行 `i=7 dcp=681 dcpLine=275` 之后**立即** abort —— **没有** `i=8` 的 `[FORMATLINE-LINE]`，也**没有**该段的 `[FORMATLINE] … nlines=` 汇总行。
⇒ 即：**abort 发生在第 9 次调用的第一跳**（`TryCollect` 的**第一次** `GetTextRun(dcp=956)`）—— 该偏移的前向指针上下文**已经是 `Block` 的 ElementStart**。

🔴 **`fsflres` 这一格是全条的钥匙**：`Line.FormattingResult`（`Line.cs:916-939`）**只**在末 run 是 `ParagraphBreakRun`／`LineBreakRun` 时才给"段末"（`Pts.cs:1096` `fsflrEndOfParagraph = 2`）；而 shim 的行末是 `TextEndOfParagraph`（shim `:3106` `spans.Add(new TextSpan<TextRun>(1, new TextEndOfParagraph(1)));`）⇒ **本移植的 shim 行拿不到 `fsflrEndOfParagraph`**。⇒ 驱动**只能**靠"探到**本段自己的** ElementEnd 时 `HandleElementEndEdge` 返回的真 `ParagraphBreakRun`"（`LineBase.cs:248-252` 逐字 `run = new ParagraphBreakRun(_syntheticCharacterLength, PTS.FSFLRES.fsflrEndOfParagraph);`）来收束。⇒ **本片段没在 `dcp=956` 处收束 ⇒ 那个偏移不是本段的 ElementEnd**（要么在本段**内部**的嵌套 Block 上，要么**过了段尾**）。

### 1.3 内容面现取（Blocks vs Inlines）

**(a) 我方实例的类型（现取，日志）** —— `~/tA28-work/legs-d/app_g1.log:657-675`（`[NMP-TYPE]`，本席只读）：

```
:657  … GetFirstPara nms=0x2 TYPE=ContainerParagraph nmp=0x3 TYPE=ContainerParagraph …
:663  … GetFirstPara nms=0x3 TYPE=ContainerParagraph nmp=0x4 TYPE=ContainerParagraph …
:664  … GetNextPara  nms=0x3 … nmp=0x6 TYPE=ContainerParagraph …
:665  … GetNextPara  nms=0x3 … nmp=0x7 TYPE=ContainerParagraph …
:667  … GetFirstPara nms=0x4 … nmp=0x8 TYPE=MS.Internal.PtsHost.TextParagraph nmp_isISegment=0 …
:670  … GetFirstPara nms=0x6 … nmp=0x9 TYPE=MS.Internal.PtsHost.TextParagraph …
:673  … GetFirstPara nms=0x7 … nmp=0xa TYPE=MS.Internal.PtsHost.TextParagraph …
:669  … GetFirstPara nms=0x8 TYPE=TextParagraph fserr=-100002 …   （叶：+136 不成立）
```

⇒ **树（现取）**：`0x2 ├ 0x3 ├ {0x4→0x8, 0x6→0x9, 0x7→0xa}`；**叶 `0x8/0x9/0xa` ＝ `TextParagraph`**；`0x2/0x3/0x4/0x6/0x7` ＝ `ContainerParagraph`。

**(b) 判型规则（上游，逐字）** —— `TextParagraph` 只在 **Inline/Text** 处诞生，`Block` 一律 `ContainerParagraph`（`ContainerParagraph.cs:993-1006` 与 `:1019-1050`）：

```
 993:                case TextPointerContext.Text:
1005:                    paragraph = new TextParagraph(Element, StructuralCache);
----
1019:                case TextPointerContext.ElementStart:
1037:                    else if (element is Block || element is ListItem)
1039:                        paragraph = new ContainerParagraph(element, StructuralCache);
1041:                    else if (element is Inline) // Note this includes AnchoredBlocks - intentionally
1043:                        paragraph = new TextParagraph(Element, StructuralCache);
```

**(c) 类型层级（逐字）**：

| 件:行 | 原文 |
|---|---|
| `…/System/Windows/Documents/Block.cs:23` | `    public abstract class Block : TextElement` |
| `…/System/Windows/Documents/Inline.cs:16` | `    public abstract class Inline : TextElement` |
| `…/System/Windows/Documents/AnchoredBlock.cs:25` | `    public abstract class AnchoredBlock : Inline` |
| `…/System/Windows/Documents/Figure.cs:16` | `    public class Figure : AnchoredBlock` |
| `…/System/Windows/Documents/Floater.cs:16` | `    public class Floater : AnchoredBlock` |
| `…/System/Windows/Documents/Paragraph.cs:19` | `    public class Paragraph : Block` |
| `…/System/Windows/Documents/Section.cs:17` | `    public class Section : Block` |
| `…/System/Windows/Documents/Table.cs:17` | `    public class Table : Block, IAddChild, IAcceptInsertion` |

**(d) 文档的真内容（现取；`/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Styles/FlowDocumentDemo.xaml`，**仓外**只读）**：

```
 9:        <FlowDocument x:Key="FlowDocumentDemo" x:Shared="False" ColumnWidth="400" …>
10:            <Section FontSize="12">
11:                <Paragraph>                        ← ① 正文 ≈692 字符 ＋ <Bold>Neptune</Bold>（Span）
21:                    <Figure Width="140" …>          ← AnchoredBlock（**Inline**）
22:                        <Paragraph …>Neptune has 72 times Earth's volume…</Paragraph>   ← **Block 在 Figure 内**
25:                    </Figure>
26:                    <Floater Background="GhostWhite" Width="285" …>   ← AnchoredBlock（**Inline**）
27:                        <Table CellSpacing="5">                        ← **Block 在 Floater 内**
35:                                        <Paragraph>Neptune Stats</Paragraph>   ← **Block 在 TableCell 内**
…
73:                    </Floater>
74:                </Paragraph>
75:                <Paragraph> …（纯文本）</Paragraph>
84:                <Paragraph><Figure …><Paragraph…>…</Paragraph></Figure> …（纯文本）</Paragraph>
98:            </Section>
```

⇒ **判词（内容面）**：
- **`ContainerParagraph`（`0x2/0x3/0x4/0x6/0x7`）：装 `Block`**（`Section`／`Paragraph`）—— 设计如此（§1.3(b) 的 Block 支）。这条**不是**缺陷。
- **`TextParagraph`（`0x8/0x9/0xa`）：直接内容装 `Inline`**（文本 ＋ `Bold`(Span) ＋ `Figure`/`Floater`(AnchoredBlock)）；**`Block` 只出现在它的 text-container 跨度内的 `Figure`/`Floater` 子树里**。
- 而 `Figure`/`Floater` 在字符源里**只能**被当作**不透明**对象整体交出去：

| 件:行 | 原文 |
|---|---|
| `LineBase.cs:140-145` | `            if (element is Figure || element is Floater)` ／ `                int cch = TextContainerHelper.GetElementLength(_paraClient.Paragraph.StructuralCache.TextContainer, element);` ／ `                run = new FloatingRun(cch, element is Figure);` |
| `…/MS/Internal/documents/TextContainerHelper.cs:562-565` | `            if (element is TextElement)` ／ `                length = ((TextElement)element).SymbolCount;` |
| `…/PtsHost/RunClient.cs:188` | `    internal sealed class FloatingRun : TextHidden` |

⇒ **该段（`0x8`）内容面：直接内容 ＝ Inline（无缺陷）；其跨度里含嵌套 Block，但它们的内点偏移是字符源契约禁止探测的位**。

---

## §2 ② 来源归因："Blocks"从哪来

**逐跳（现取）**：

| 跳 | 论断 | 件:行 / 证据 |
|---|---|---|
| **G1** | 段落树**不是 native 造的** —— native 只经 `+136 pfnGetFirstPara`／`+144 pfnGetNextPara` **问**托管 PtsHost | `win32_pts.c:1901-1923`／`:1949-1979`（`wpf_pts_sub_enum_into`／`wpf_pts_sub_enum`：计数只来自回调真返回） |
| **G2** | 拿到的 `nmp` 是**托管对象句柄** | `nmp` ＝ 托管 `ContainerParagraph._firstChild`（`P1-nmp-type-report.md` §3/§6，**引自该件未独立复算**）＋ 本件现取 `[NMP-TYPE] … TYPE=MS.Internal.PtsHost.TextParagraph` |
| **G3** | native 自有的"子段对象"**只装句柄** | `wpf_pts_subtrack` 的字段＝`nmp`／`children[]`／计数（`win32_pts.c:1886-1936`）；**没有** Block/Inline 之分 |
| **G4** | native 的 `rgParaDesc` **与内容无关** | `FsQueryTrackParaList`（`win32_pts.c:4832`）只写**不透明句柄**（填 `+176` 现造的 `pfsparaclient`，见 `:4990-5008`）；**不写、不读**任何内容字段 |
| **G5** | Blocks 是**文档的真内容** | `FlowDocumentDemo.xaml:22/27/35/…`（§1.3(d)） |

⇒ **判词（三选一，取第三）**：
- ❌ **不是"我方填错"** —— native **从不构造内容**（G1–G4）；`rgParaDesc`／子段对象只是句柄。
- ❌ **也不是"上游段落语义坏了"** —— `TextParagraph` 的直接内容**确实**是 Inline-only（§1.3），上游判型规则（§1.3(b)）**被遵守**。
- ✅ **真正的来源 ＝「探测偏移」＋「行模型」**：断言只在**探测偏移**落到 `Block` 的 ElementStart 上时才被触发。段内**直接**没有 Block ⇒ 该偏移**只能**落在 **(i) `Figure`/`Floater` 子树内部**（嵌套 Block）**或 (ii) 过了本段段尾**（下一个兄弟 `Paragraph` 的 ElementStart）。**两者都是字符源契约禁止探测的偏移**。而"下一行从哪儿开始"**完全由行模型给的 `dcpLine` 决定**（`win32_pts.c:2152`）；本移植的行模型 ＝ 托管 **shim**（`build/shims/PresentationCore.HbTextLine.cs` ＋ 生成件 `TextFormatterImp.Linux.cs`）—— 它把整段**平铺成一个串**再机械断行（`CollectLenient`：`cp += run.Length;` 见 `TextFormatterImp.Linux.cs:259`；隐行按 `new string(GhostChar, run.Length)` 占位，见 `:134`）⇒ **不按元素边界保护行起点**。

⇒ **承重前置具名 ＝ `PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS`**（"行模型给出的每一行起点必须是**元素安全位**"）。

### 2.1 为什么真机不会撞（对照，说明缺什么）

| 面 | 真机 | 本移植 |
|---|---|---|
| 谁做行排版 | **native LineServices**（`LineServices.cs:1419` 声明 `LoCreateLine`；`T-A27` §1.1 现取：本侧 `exports.txt` **无** `LoCreateLine`，**引自该件未独立复算**） | 托管 shim（`build/shims/**`）；native 侧 `Lo*` 只有 8 条骨架 |
| `Figure`/`Floater` 怎么消费 | LS 把 `FloatingRun` 当**原子隐行**，**不会**把行起点放进它的内点 | shim 平铺成串后按宽度机械断行 ⇒ **可以**把行起点放进内点（承 §1.2 的偏移） |
| 段末信号 | 驱动收 `fsflres=fsflrEndOfParagraph` | `Line.FormattingResult` **只认 `ParagraphBreakRun`**，shim 产 `TextEndOfParagraph` ⇒ 收不到（§1.2 钥匙格） |

⇒ 缺的**正是** LS 的那条"元素边界约束"；这与既有具名 `PRECOND-NO-LAYOUT-CONTENT-MODEL`（内容/行盒层）**同族**。

---

## §3 ③ 候选路（甲/乙/丙）：可及 ∧ 可行 ∧ 代价 ∧ `P8` 落点

### （甲）native 侧"修正内容面"

| 维度 | 现取判词 |
|---|---|
| **可及性** | **可及**（`src/WpfGfx.Linux.Native/**` 是 `T-A28` 写域）。 |
| **可行性** | 🔴 **语义上做不到** —— native **不拥有**内容（§2 G1–G4）。唯一能动的是**驱动方式**：**a)** 不再驱动（＝回现状，零进展）；**b)** 只驱动"不含 `Figure`/`Floater`"的段 —— 但 native **无从判断**（句柄不透明，内容全在托管侧）；**c)** 自己钳制 `dcp` 到"安全位" —— 同样**无从判断**。⇒ 三支全是**回避**，且**零产品价值**。 |
| **代价** | 低（但收益 0）。 |
| **`P8` 落点** | `src/WpfGfx.Linux.Native/src/win32_pts.c`（**本写域内**）。 |
| **判定** | **不成立**（不是"不可及"，是"**病因不在这一层**"）。 |

### （乙）托管侧（含生成器）修正 —— **真正的落点**

| 维度 | 现取判词 |
|---|---|
| **可及性** | **可及** —— 行模型两处真身都在仓内：`build/shims/PresentationCore.HbTextLine.cs`（`921ba9c65e9fb3be`，**非生成件**）＋ `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（`fa058b134c64e068`，**生成件** ⇒ **只许改生成器**，遵 `P8`）。 |
| **可行性** | **可行** —— 行起点 ＝ 行模型给的 `dcpLine` 累加（§1.2）。只要让行模型**不产出**"下一行起点落在某元素 interior"的行（等价于：断行**尊重元素边界**，`Figure`/`Floater`/`Span` 的内点不作行起点），断言就**无从**被触到。 |
| **代价** | **中—高** —— 动的是**已过 parity 验证**的断行层（`HbBreakEngine` ＋ `HbTextLineFactory.FormatParagraph`）；必须给"现有点线算法**逐字不变**"的成对证据（承本仓 `D-T5`／`W1xA` 一族的教训）。 |
| **`P8` 落点** | `build/shims/**`（shim 本体）＋ **生成器**（`build/PresentationCore.Linux/**` 属生成件，**不许直改**）。**不涉** native。 |
| **判定** | **可行，但不在 `T-A28` 的 native 写域内**（须另开写域授权；见 §4 与 §A）。 |

### （丙）其它

| 变体 | 现取判词 |
|---|---|
| **丙-1** 放宽上游断言（`LineBase.cs:137`）：把 Block 当隐行返回 | **不可取** —— 该断言是**上游契约的守卫**（Block 进字符源 ＝ **真缺陷**信号）；放宽它 ＝ **掩盖**"行模型越界"，且 `upstream/**` 非本移植写域。 |
| **丙-2** 只在 `Line.cs`／`TextParagraph.cs` 侧钳制 `dcpLine`（不让行尾越过元素边界） | 技术可行，但**同样属托管上游件**，且与丙-1 同病（改公共排版语义）。 |
| **丙-3** 合法终点 | **保持**现状（闸缺省关；`no-text-line-model` 诚实拒绝）—— **本件主判**（§4）。 |

---

## §4 ④ 结论

> **判词**：`PRECOND-TEXTPARA-CONTENT-MODEL` **在 `T-A28` 的 native 写域内不可解除**。
> ① 该前置**名不符实**：`TextParagraph` 的直接内容**本来就是 Inline-only**（§1.3），**没有**"内容面坏了"这回事 ⇒ **应归位为"不成立／误名"**。
> ② 真正的承重前置 ＝ **`PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS`**：**行模型给出的每一行起点必须是元素安全位**（承 §1.2、§2）。
> ③ 它**可由本仓改造**（路 `(乙)`：`build/shims/**` ＋ 生成器），但**不在 native 写域** ⇒ **需另开"行模型写域"的单一写者**。
> **合法终点（本波）**：`WPF_PTS_FL_DRIVE` **缺省保持关**（`win32_pts.c:2069-2071` 现取 `#define WPF_PTS_FL_DEFAULT 0`）；缺省路径产品行为**逐字不变**（`T-A28` §3 现取）；**不得**为消断言而放宽上游 `LineBase.cs:137`，**不得**在 native 侧伪造"安全位"。

**具名前置清单（落库用）**

| # | 具名前置 | 谁给／何处可解 | 承重 | 可核证据（三格） |
|---|---|---|---|---|
| 1 | **`PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS`** | 行模型层（shim ＋ 生成器，路 `(乙)`） | **承重** | 驱动计数（`calls`）／末行 `fsflres ∈ {2,3,4,5}` 的行数／`failfast==0` |
| 2 | `PRECOND-TEXTPARA-CONTENT-MODEL` | — | **不成立（误名）** | 本件 §1.3（判型规则 ＋ 文档 ＋ 类型层级） |
| 3 | `PRECOND-NO-LS-EQUIVALENT`（本件新增，说明为何缺第 1 条） | 本移植未接 LineServices（`LoCreateLine` 未导出） | 说明性 | `bin/exports.txt` 无 `LoCreateLine`（承 `T-A27` §1.1，**引自该件未独立复算**） |

---

## §A 附：下一跳设计草案（**仅当**获"行模型写域"授权；本件**不做**）

**目标（可证伪）**：窗内驱动 `pfnFormatLine` 时，**任何**一次 `GetTextRun(_cpPara+dcp)` 的前向上下文**不得**是 `Block` 的 ElementStart。

**草案（3 步，一步一判）**
1. **行起点安全集（shim 侧）**：让 `CollectLenient` 的平铺串**带上 run 边界表**（既有 `CollectedRun{Start,Length}` 形制可扩），`FormatParagraph` 把"元素 interior"（`Figure`/`Floater` 的隐行内部、`Span` 边界内点）标为**硬断点禁区** ⇒ 行起点**只能**落在 run 边界上。
2. **末行收束**：让段末行能被 `Line.FormattingResult` 认成段末（现取：shim 产 `TextEndOfParagraph`，而 `Line.cs:929` **只认 `ParagraphBreakRun`** ⇒ 驱动**永远**拿不到 `fsflrEndOfParagraph`）—— **要么**在 `Line`／`TextParagraph` 侧补认，**要么**让驱动不再依赖它（承 §1.2 的钥匙格）。
3. **有界 ＋ 成对**：撞"禁区" ⇒ **具名留痕 ＋ 计数**；**不**静默。

**判据草案（4 条可证伪 ＋ 反极性必红腿）**

| # | 判据（可证伪） | 反极性（必红腿） |
|---|---|---|
| **D1 元素安全** | 驱动的**每一行起点偏移**，其前向上下文 ∈ {Text, Inline 的 ElementStart/End, 本段 ElementEnd}；**0** 次 `HandleElementStartEdge` 撞 `Block`。 | 若靠"把 Block 当隐行"蒙过（丙-1）⇒ **必红**（掩盖真越界）。 |
| **D2 账守恒** | `ΣdcpLine == 该段 SymbolCount` ∧ 末行 `fsflres ∈ {2,3,4,5}`。 | 只让"不 abort"却 `ΣdcpLine ≠ SymbolCount` ⇒ **必红**（假成功）。 |
| **D3 零假值／零回归** | 缺省路径（闸关）产品读数**逐字节不变**；既有断行 parity 语料**逐字不变**。 | 用"断行变了"换"不 abort" ⇒ **必红**。 |
| **D4 ≥2 独立样本 ＋ 反腿** | ≥2 独立样本同判；反腿（`WPF_PTS_FL_DRIVE=1` ＋ **未修件**）**必须**红（`app_rc=134`／`failfast>0`）。 | 单样本当机制／反腿不红 ⇒ **必红**。 |

---

## §5 ⑤ 具名 `NOINFO`（逐条给消掉条件）

1. **`NOINFO-BLOCK-SITE-OFFSET`**：触发偏移（`dcp=956`）究竟落在 **(i) `Figure`/`Floater` 子树内的嵌套 Block** 还是 **(ii) 本段段尾之后的兄弟 Block** —— 本件**未**分辨（需该段 `SymbolCount` 与偏移的**同趟**读数）。**消掉需要**：在驱动点打印该段 `Paragraph.SymbolCount`（托管侧只读插桩），或 `[FORMATLINE-LINE]` 增一格"该行起点的指针上下文"。
2. **`NOINFO-TEXTPARA-CHILD-ELEMENT-TYPES`**：`0x8` 的**直接子元素**类型列表（本件只有：文档 ＋ 判型规则 ＋ 类型层级的**静态**证据，**无**运行期 dump）。**消掉需要**：对 `0x8` 的 `TextContainer` 跨度做一次只读枚举打印。
3. **`NOINFO-SHIM-LINEBOUNDARY-VS-SYMBOL`**：shim 的 `dcpLine` 是否**逐行**与符号偏移同尺（`ExtractRun:134` 的 `new string(GhostChar, run.Length)` **使字符计数守恒**，但**断行落点**本身不可只读观测）。**消掉需要**：一次 `WPF_LINUX_TEXTLINE_LINEDIAG=1` 的行诊断腿。
4. **`NOINFO-FSFLRES-ENDPARA-FROM-SHIM`**：shim 是否**能**产出 `fsflrEndOfParagraph`（现取判词：`Line.cs:928-936` 只认 `ParagraphBreakRun`／`LineBreakRun`，shim 产 `TextEndOfParagraph` ⇒ **不能**）。**消掉需要**：一次真实腿统计 `fsflres` 分布。
5. **`NOINFO-EXACT-TEXT-LEN`**：`Paragraph1` 正文的**精确**字符数（本件用只读脚本估 **692**，未计 XAML 归一化边界）。**消掉需要**：运行期 `TextContainer.SymbolCount`。

---

## §6 边界 · 主动披露

1. **未改任何仓内文件（除本载体）**；`git status --porcelain` 收尾现取：`?? build/MilBridge/tasks-tail2/T-A29.md`／`?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`（**两者先于本件**）＋ **本件**（untracked）。**未构建**／**未跑腿**／**未占显示位**／**未跑整趟门禁**／**未 `sleep` 轮询**／未 `git add/commit/push`。
2. **引他处读数（标"未独立复算"）**：§1.1／§1.2 的栈与 8 行台账取自 `~/tA28-work/legs-d/app_g1.log`（**仓外**，`T-A28` 车道产物；本席**只读**其 `grep -n`／行取输出，**未复跑腿**）；§1.3(a) 的 `[NMP-TYPE]` 同源；§2 G2 的结构结论引自 `P1-nmp-type-report.md`；§2.1 的 `LoCreateLine` 未导出引自 `P1-tail2-hostline-recon.md` §1.1。
3. **代际**：`win32_pts.c`＝`bcd6a00bce9f67a2`（461075 B，与 `T-A28` 交出**同代、未漂移**）；`PresentationCore.HbTextLine.cs`＝`921ba9c65e9fb3be`；`TextFormatterImp.Linux.cs`＝`fa058b134c64e068`；`PtsCache.Linux.cs`＝`e5b399fdb8742092`；`LineBase.cs`＝`e94c062f2124dbeb`；`HEAD=55ad709cbbb85c3a3e7f80becc4df10b715bd06b`。
4. **本件自带的两条反腿**：见 §0-7。另：**不**把"三源在托管侧"（承 `T-A27`）读成"行模型已等价于 LineServices"（§2.1）。
5. **本件未做的**（防被读宽）：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；**未**改任何复述位件（`docs/**`／`HANDOFF-NEXT.md`／`samples/**`）。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-tpcm-recon.md | sha256sum | cut -c1-16`）= `dee0c0677473b788`

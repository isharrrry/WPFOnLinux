# W21C 报告 —— 任务 A（盲复核 `TextLine.Start` 的法律）／任务 B（`D-T6-b` 静态归因）／任务 C（`PI≠0` 逐行真值裁定）

- **lane = W21C**
- **date-time = 2026-09-16 18:27:15 → 18:5x +0800**（本件为**纯静态阅读 + `python3` 重算**，无一处运行期读数；每个读数自带其取数时刻）
- **loadavg = 2.70 1.61 0.68**｜**mem_available = 3757416 kB**｜**kernel = 6.8.0-138-generic**
- 硬约束遵守声明：本件**没有**执行 `dotnet build / run / restore / msbuild` 中的任何一条（另一条车道 W21A 在做重构建，3 核机器）；**没有**修改仓库里任何既有文件；临时脚本在 `$HOME/w21c-scratch/`；**没有** `pkill -f`。

## 0. 本件的现场（件 sha16 一览）

| 件 | sha16 | 字节 | mtime |
|---|---|---|---|
| `tests/parity/windows/tab-anchor/out/tab-anchor-raw.json`（**任务 A 的唯一实测真值**） | `88559d670f1bb955` | 1196289 | 2026-09-14 19:32:35 |
| `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json` | `a31a813114256faf` | 1251441 | 2026-09-14 19:33:26 |
| `tests/parity/windows/tab-anchor/src/Program.cs`（真机臂源） | `e6651272200f7fb6` | 40998 | 2026-09-14 19:26:52 |
| `build/shims/PresentationCore.HbTextLine.cs`（**任务 B 现场**） | `fe1b7ed8fa3ed231` | 278692 | 2026-09-16 15:30:15 |
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（生成物；宽松档在这里） | `799e0366b312ec65` | 55223 | 2026-09-16 15:31:51 |
| `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`（应用器） | `daa1fe2a32d454cf` | 52168 | 2026-09-16 15:31:55 |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（冻结基线表头） | `f5d8a6f1cdf49635` | 173415 | 2026-09-16 15:55:50 |
| `docs/WAVE21-PREREGISTRATION.md` —— **任务 A 完成前我读到的？没有**。任务 A 完成后第一次读 = `9d1e2dddda5b24e8`(14390 B) | **`127be0d931d97adf`** | **20376** | 2026-09-16 18:25:24 |
| `build/MilBridge/tests/PcLineOracle/Program.cs` —— **另一条车道正在改**（见 §C.0） | `866d92c8a9f36bf7` | 94413+ | 2026-09-16 18:2x–18:3x |

> **⚠️ 两处件在会话中被改**（如实记）：
> ① `docs/WAVE21-PREREGISTRATION.md`：我**做完任务 A 之后**才第一次读它，当时 sha16 `9d1e2dddda5b24e8` / 14390 B；随后（18:25:24）主控把它扩到 **20376 B / `127be0d931d97adf`**。§A.7 的"一致/不一致"裁定**对两个版本都成立**（§1 的结论句未变，只增补了腿②③与 §1.4 判据）。
> ② `build/MilBridge/tests/PcLineOracle/Program.cs`：我在 18:2x 依次读到 `7364f25cda440d05` → `1b7894b92326245e` → `2a4b878d2388d805` → `866d92c8a9f36bf7`（**W21A 正在落任务 A 的判据列**）。§C 引用的行号一律标注"在 `866d92c8a9f36bf7` 这一版"。
>
> **盲复核声明**：任务 A 的全部计算（`$HOME/w21c-scratch/taskA.py…taskA5.py`）在**我读 `docs/WAVE21-PREREGISTRATION.md` 之前**完成并落盘；`docs/WAVE21-PREREGISTRATION.md` 在我做完 A 之前**一次都没被 read/grep**（第一个动作是 `ls`/`sha256sum`/`python3` 读语料与上游源）。

---

# A. 任务 A —— 真机 `TextLine.Start` 的法律（盲复核）

## A.1 真机臂里 `lineStartOffsetsDip` 是**怎么产生的**（产生它的那行源码）

`tests/parity/windows/tab-anchor/src/Program.cs:436-449`（真机臂的主循环，逐行 `FormatLine` 后落盘）：

```csharp
436:            var lineIndents = new List<double>();
...
441:            while (index < text.Length && guard++ < 64)
442:            {
443:                TextLine line = formatter.FormatLine(source, index, width, para, brk);
444:                lines.Add(DescribeLine(line, text, flow, index, lines.Count));
445:                lineIndents.Add(R(line.Start));
446:                brk = line.GetTextLineBreak();
447:                if (line.Length <= 0) { stoppedEarly = true; break; }
448:                index += line.Length;
449:            }
```

**产生它的那一行 = `:445` `lineIndents.Add(R(line.Start));`**，落盘处 `:476`：

```csharp
476:                ["lineStartOffsetsDip"] = lineIndents,
```

- 取的 API 成员 = **`System.Windows.Media.TextFormatting.TextLine.Start`**（public，double）。
- **注意口径**：落盘前先过 `R`（`:583`）：`private static double R(double v) => double.IsNaN(v) ? v : Math.Round(v, 6, MidpointRounding.AwayFromZero);` ⇒ 语料里的值是 **6 位小数的舍入值**，不是 bit 原值。
- 同一读数**第二处落盘**：`:555` `["paragraphStartOffsetDip"] = R(line.Start),`。我逐行比过两处：**615/615 一致、0 处矛盾** ⇒ 语料自洽，且证明这两处确实是同一物理量（也排除了"数组错位"这类仪器事故）。
- 臂源 `:503-504` 自带警示，与我这里读到的语义一致：
  `// NOTE: TextLine.Start is a DOUBLE distance ("distance from paragraph start to line start", in DIPs),`
  `// NOT a character index - casting it to int silently yields 0 and slices the wrong text.`
- 语料头（`tab-anchor-raw.json`）：`os = "Microsoft Windows NT 10.0.22631.0"`、`clr = ".NET 10.0.7"`、`presentationCore = "10.0.0.0"`、`generatedUtc = "2026-09-14T11:32:21.0123313Z"`、`measurement = "TextFormatter.Create().FormatLine(...) looped over TextLine.GetTextLineBreak() so every line is recorded"`。

## A.2 我独立得出的**法律原文**

> **`TextLine.Start`（真机语义）= 「从段落起点到本行行起点」的距离（DIP）= `IdealToReal(_paragraphToText − _textStart)`。在 `TextAlignment.Left`（本语料 436/436 全部）下，`_paragraphToText = pap.ParagraphIndent + _textStart`（`TextMetrics.cs:263`）⇒ `_textStart` **精确相消** ⇒**
>
> ```
> TextLine.Start  ≡  TextParagraphProperties.ParagraphIndent        （TextAlignment = Left）
> ```
>
> **与 `TextParagraphProperties.Indent` 无关、与 `_textStart` 是否非零（首行缩进/行首制表符/前导空白）无关、与行内容/行宽/行号无关、与流方向无关。段内每一行的 `Start` 恒为同一个值。**

上游出处（`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/`）：

| 出处 | 原文 |
|---|---|
| `TextMetrics.cs:352-358` | `/// Client to get distance from paragraph start to line start` / `public double Start { get { return _formatter.IdealToReal(_paragraphToText - _textStart, _pixelsPerDip); } }` |
| `TextMetrics.cs:255-263`（`switch(pap.Align)` 的 `default:` 分支 = Left/Justify） | `// alignment rule:` / `//   "Paragraph start to line start is paragraph indent"` / `//        PTL = PI` / `//        PTT - LTT = PI` / `// (thus) PTT = PI + LTT` / `_paragraphToText = pap.ParagraphIndent + _textStart;` |
| `TextMetrics.cs:37-46`（类头说明，语义定义） | `/// The application may specify "Indent" - the distance from the beginning of the line to the beginning of the text in that line. … It may also specify "Paragraph Indent" - the distance from the beginning of the paragraph to the beginning of the line [TextParagraphProperties.ParagraphIndent].` |
| `TextMetrics.cs:119-131` | `_textStart = lineWidths.upStartMainText;`（"distance from LS origin to text start" = **Indent 进入的那个量**） |
| `LineServicesCallbacks.cs:376` | `lsLineProps.durLeft = settings.TextIndent;`（Indent 作为 `durLeft` 进入 LS ⇒ 只影响 `_textStart` ⇒ **相消**） |
| `TextProperties.cs:39-40` | `_indent = TextFormatterImp.RealToIdeal(paragraphProperties.Indent);` / `_paragraphIndent = TextFormatterImp.RealToIdeal(paragraphProperties.ParagraphIndent);` |
| `FullTextLine.cs:2249-2252` | `public override double Start { get { return _metrics.Start; } }`（**转发，无二次加工**） |
| `SimpleTextLine.cs:1030-1033` | `public override double Start { get { return _offset; } }`（**另一条实现**；见 A.5 的路径分析 —— 它只能取 0） |

## A.3 命中率表（**全部 436 例 / 615 行**，不抽样）

重算脚本 `$HOME/w21c-scratch/taskA5.py`；比较口径与语料同 `R`（6 位小数）。

| 候选驱动量 | 命中 | 反例 | 命中率 | max\|Δ\| | mean\|Δ\| |
|---|---|---|---|---|---|
| **`Start == ParagraphIndent`** | **615 / 615** | **0** | **100.000 %** | 0.000000 | 0.000000 |
| `Start == ParagraphIndent + Indent` | 384 / 615 | 231 | 62.439 % | 24.000000 | 9.014634 |
| `Start == Indent if firstLine else 0` | 378 / 615 | 237 | 61.463 % | 48.000000 | 10.653659 |
| `Start == Indent` | 337 / 615 | 278 | 54.797 % | 48.000000 | 12.253659 |
| `Start == 0`（常量） | 444 / 615 | 171 | 72.195 % | 48.000000 | 8.234146 |
| `Start == PI + (Indent if firstLine)` | 425 / 615 | 190 | 69.106 % | 24.000000 | 7.414634 |
| `Start == PI + 对齐偏移(Left ⇒ 0)` | 615 / 615 | 0 | 100.000 % | 0.000000 | 0.000000 |

**"对齐偏移"这一候选的正确读法**：本语料 **436/436 都是 `TextAlignment=Left`**（臂 `:651` `public override TextAlignment TextAlignment => TextAlignment.Left;`；语料头 `paragraphProperties.fixed` 也钉死 `"TextAlignment=Left, TextWrapping=Wrap, LineHeight=0 (natural), Tabs=null, TextDecorations=null, TextMarkerProperties=null, AlwaysCollapsible=false"`）。Left 的"段起点→行起点"对齐项 = 0，所以它与 `Start == PI` **在数学上不可分**（同一列、同一命中率）。要分开必须换 `TextAlignment` 另录真机语料 ⇒ **本语料 NOINFO**。上游给出的两种非 Left 公式（**只能作源码依据，不是本语料的实测**）：
- `TextMetrics.cs:233-242`（Right）：`_paragraphToText = paragraphWidth - _textWidthAtTrailing;` ⇒ `Start = PW − 该行 textWidthAtTrailing`（**逐行不同**）
- `TextMetrics.cs:244-253`（Center）：`_paragraphToText = (int)Math.Round((paragraphWidth + _textStart - _textWidthAtTrailing) * 0.5);` ⇒ `Start ≈ ½(PW − textWidthAtTrailing − …)`（**逐行不同**）

## A.4 反例：**0 条**（逐条列出的地方就该是空的）

```
TOTAL LINES = 615    CASES = 436
Start == ParagraphIndent           hit=   615/615  miss=0  rate=100.000%
```

按子群体无一例外（**这就是正控**：同一个搜索在有反例的假设上都非零）：

| 子群体 | 行数 | `Start==PI` 命中 | 反例 |
|---|---|---|---|
| `flow=LeftToRight` | 459 | 459 | 0 |
| `flow=RightToLeft` | 156 | 156 | 0 |
| `group=A-anchor` | 108 | 108 | 0 |
| `group=A-contrast` | 36 | 36 | 0 |
| `group=B-indent` | 202 | 202 | 0 |
| `group=B-indent-extra` | 127 | 127 | 0 |
| `group=C-rtl-indent` | 45 | 45 | 0 |
| `group=D-paraindent` | 85 | 85 | 0 |
| `group=P-probe` | 12 | 12 | 0 |
| `firstLineInParagraph=True` | 574 | 574 | 0 |
| `firstLineInParagraph=False` | 41 | 41 | 0 |

**反例（对 `Start==Indent` 这一被否假设）** 前 12 条（共 278 条），证明"`Start` 里看不到 `Indent`"：

```
  B-indent/lead-tab-a@w40@LTR@i24@default     line#0  Start=   0  Indent= 24  PI=  0  first=True
  B-indent/lead-tab-a@w40@LTR@i24@default     line#1  Start=   0  Indent= 24  PI=  0  first=True
  B-indent/lead-tab-a@w40@LTR@i24@tab0        line#0  Start=   0  Indent= 24  PI=  0  first=True
  B-indent/lead-tab-a@w80@LTR@i24@default     line#0  Start=   0  Indent= 24  PI=  0  first=True
  B-indent/lead-tab-a@w80@LTR@i24@default     line#1  Start=   0  Indent= 24  PI=  0  first=True
  B-indent/lead-tab-a@w96@LTR@i24@default     line#0  Start=   0  Indent= 24  PI=  0  first=True
  B-indent/lead-tab-a@w96@LTR@i24@default     line#1  Start=   0  Indent= 24  PI=  0  first=True
  B-indent/lead-tab-a@w100@LTR@i24@default    line#0  Start=   0  Indent= 24  PI=  0  first=True
  B-indent/lead-tab-a@w100@LTR@i24@default    line#1  Start=   0  Indent= 24  PI=  0  first=True
  ...
```

**见证表（`(Indent, PI, firstLine) → Start`，语料里出现的全部组合，无一冲突）**：

| Indent | ParagraphIndent | firstLineInParagraph | 实测 `Start` 取值集合 | 例数 |
|---|---|---|---|---|
| 0 | 0 | True | {0} | — |
| 0 | 24 | True | {24} | — |
| 0 | 48 | True | {48} | — |
| 24 | 0 | True | **{0}** | 88（`i24`） |
| 24 | 0 | **False** | **{0}** | 24（`i24nl`） |
| 24 | 24 | True | {24} | 36（`i24p24`） |
| 24 | 48 | True | {48} | 4（`i24p48`） |

⇒ 第 4/5 行是**决定性见证**：`Indent=24` 且 `PI=0` 时 `Start=0`，**首行与否也不影响**（`i24` 与 `i24nl` 同值）。
⇒ **段内 `Start` 是常量**：`cases with non-constant Start across lines: 0`（436/436 例每例内部 `Start` 全相同）。

## A.5 独立判据：取值域与一一对应

```
lineStartOffsetsDip 取值域 = [0, 24, 48]      直方图 {0: 444, 24: 131, 48: 40}   （行级）
paragraphIndentDip  取值域 = [0, 24, 48]      例数   {0: 324, 24: 84,  48: 28 }    （例级，436 例）
indentDip           取值域 = [0, 24]          例数   {0: 324, 24: 112}
firstLineInParagraph取值域 = {False, True}
⇒ 两域相等 = True
crosstab (PI,Start) -> n : {(0,0): 444, (24,24): 131, (48,48): 40}
PI=0 而 Start≠0 的行 = 0        PI≠0 而 Start==0 的行 = 0        off-diagonal = 0
```

⇒ **`Start` 的取值域与 `ParagraphIndent` 的取值域逐值一一对应，且 `PI → Start` 是双射**：每个 `PI` 只对应唯一一个 `Start`，没有第三种可能；反方向也无多对一。这**独立于**"逐行相等"这一条 —— 它排除的是"两者碰巧在多数行上相等"的可能性（若存在任何一行 `Start` 取了 `PI` 域外的值，或 `PI` 域内有值在 `Start` 里缺席，本判据就会红）。

**"精确相等"这个口径能被这个舍入过的字段支撑吗？——能，且给出下界论证**：`R` 只舍到 1e-6 DIP，而真机内部全部距离是**理想整数**（`RealToIdeal` = ×300 ⇒ 1 理想单位 = 1/300 DIP = 0.003333…）。`ParagraphIndent = 24` 到达 `TextProperties` 时恰为理想整数 7200，`IdealToReal(7200) = 24.0` **精确**。因此要把 `Start` 与 `PI` 分开，差值至少是一个理想单位（0.0033）≫ `R` 的 1e-6 ⇒ **`R` 藏不住任何真实差异**。这是"精确相等"这话在本语料上站得住的理由，而不是偏好。

## A.6 覆盖边界与成立条件（**覆盖不到的地方一律 NOINFO**）

| 条件 | 本语料覆盖 | 我的裁定 |
|---|---|---|
| `TextAlignment.Left` | **436/436** | **法律在此成立，615/615 实测** |
| `FlowDirection` = LTR / RTL | 318 / 118 例（459 / 156 行） | **两个方向都覆盖、都 0 反例** ⇒ 法律**与流方向无关**（RTL 下仍只是 `PI`；`Start` 不是"段内几何偏移"） |
| `Indent ≠ 0` | 112 例（`i24`88 + `i24nl`24） | 覆盖；**`Start` 不受其影响** |
| `PI ≠ 0` | 112 例（`i0p24`48 + `i24p24`36 + `i0p48`24 + `i24p48`4） | 覆盖；`Start` = 24 或 48 |
| `PI` 与其他值（非 0/24/48） | **零覆盖** | **NOINFO** —— 法律公式层面允许任意值；语料只证到 {0,24,48} |
| `TextAlignment.Right` / `Center` / `Justify` | **零覆盖**（全语料 Left） | **NOINFO**。**不许发明公式**：上游给的是 `Start = PW − textWidthAtTrailing`（Right）/ ½ 式（Center）（`TextMetrics.cs:241`/`:252`），**本语料没有一行能验证它们** |
| `TextWrapping = NoWrap` / `WrapWithOverflow` | **零覆盖**（436/436 `Wrap`） | **NOINFO**（`TextWrapping` 不影响 `TextMetrics` 的对齐分支，但这是**源码推理**，不是实测） |
| 自定义 `Tabs`（非 null 停靠位数组） | **零覆盖**（语料头自述 `Tabs = null`） | **NOINFO** |
| `TextMarkerProperties ≠ null`（项目符号/自动编号） | **零覆盖** | **NOINFO**。上游 `TextMetrics.cs:95-98` 说 marker 的偏移**不进** `Start`（"TextFormatter does not retain that distance"），但这**未经本语料验证** |
| 硬断（`\r\n`）跨行 | 语料包含多行例，但 `HardBreak` 是否影响 `Start` | 本法律**不含 `HardBreak` 项**⇒ 不适用；**本件未测**（无对应真值列） |
| 多段落（同一 `FormatLine` 序列跨段） | 每例单段 | **NOINFO**：`Start` 是**段内**量，跨段语义本件未测 |

**两条实现路径的统一（这是"法律为什么这么干净"的机制，且是源码级证据不是推测）**：

1. **LS 完整路径** `TextMetrics.FullTextLine`（`TextFormatterImp.cs:241` `new TextMetrics.FullTextLine(...)`）：`Start = IdealToReal(_paragraphToText − _textStart)`，Left 下 `_paragraphToText = pap.ParagraphIndent + _textStart`（`:263`）⇒ **恒等式 `Start = PI`**。`Indent` 走 `durLeft`（`LineServicesCallbacks.cs:376`）只改 `_textStart` ⇒ **相消**。
2. **快路径** `SimpleTextLine`（`TextFormatterImp.cs:230` `SimpleTextLine.Create(...)` **先前置尝试**）：`SimpleTextLine.cs:87-100` 的闸门在 `settings.TextIndent != 0`（`:91`）**或** `pap.ParagraphIndent != 0`（`:92`）时 `return null` ⇒ **快路径只在 `Indent == 0 且 PI == 0` 时可达**；而该版 `_offset` 只在 `Align != Left` 时被赋值（`:350-364`），Left 下 `_offset` 保持默认 **0** ⇒ **`Start = 0 = PI`**。⇒ **两条路径给出同一法律，不留缝**。

   ⚠️ 这也解释了语料里一个乍看奇怪的事实：`i24`（Indent=24）的例**必然**走 LS 完整路径（快路径在 `:91` 就 null 掉了），所以 `Indent` 的效应**不可能**通过 `Start` 漏出来。

## A.7 与主控登记（`docs/WAVE21-PREREGISTRATION.md` §1）的一致/不一致裁定

**裁定：一致 —— 逐项、逐数字都一致，我没有推翻主控的任何一条。**

| 主控登记 | 我独立重算 | 是否一致 |
|---|---|---|
| `Start ≡ IdealToReal(ParagraphIndent)`，`_textStart` 精确相消，只等于 `ParagraphIndent` | 同一结论（A.2） | ✅ |
| 公式腿：`TextMetrics.cs:355-358` + `:255-263` 的 `default:` 分支 | 我读的是同一处（`:355-358` / `:263`） | ✅ |
| `Start == ParagraphIndent` **615 / 615（错 0）** | **615/615，0 反例** | ✅ **逐位相同** |
| `Start == Indent` **337 / 615** | **337/615** | ✅ **逐位相同** |
| 互斥互覆盖：`PI=0 而 Start≠0` = 0；`PI≠0 而 Start==0` = 0 | 0 / 0 | ✅ |
| 取值域 `{0: 444, 24: 131, 48: 40}` | `{0: 444, 24: 131, 48: 40}` | ✅ **逐位相同** |
| 例数 `324/84/28` | `{0: 324, 24: 84, 48: 28}` | ✅ |
| `PI → Start` 是双射 | `{0:[0], 24:[24], 48:[48]}` | ✅（A.5） |
| 语料自洽：`paragraphStartOffsetDip` 与 `lineStartOffsetsDip[k]` 615/615 | 615/615、0 矛盾 | ✅ |
| 腿③ `SimpleTextLine.Linux.cs:1158-1161` 不硬编码 0 | 我读到 `public override double Start { get { return _offset; } }`（当前件 `5f729e403fc6c7b1`，`:1158-1161`） | ✅ |
| 只对 `TextAlignment=Left` 断言；Right/Center = NOINFO | 同（A.3/A.6） | ✅ |
| LTR 318 例 / RTL 118 例；171 非零行里 LTR 138 / RTL 33 | 318 / 118；138 / 33 = 171 | ✅ **逐位相同** |
| 现件 `PresentationCore.HbTextLine.cs:3390` `Start => 0` 注释"3222/3222"是伪证 | 我读到 `:3390` `public override double Start => 0;          // 真机实测恒为 0（3222/3222），不是段落内偏移`，全文件**只有这一处** `override double Start` | ✅ |
| 语料含 `lineStartOffsetsDip`（615 值）⇒ "不可从语料推出"那条口径被推翻 | 同（见 §C） | ✅ |

**我额外加固、主控未写的一条**：`Start` 的**舍入口径下界论证**（A.5 末段：`R` 只舍 1e-6 而理想单位是 1/300 ⇒ `R` 藏不住真实差异）—— 它把"精确相等"从偏好升级为可证。以及**快路径闸门**（A.6 第 2 条：`SimpleTextLine.cs:91-92`）—— 它证明法律在两条实现上**同时**成立，不留缝；主控的腿③只说"不是硬编码 0"，没指出"快路径在 `Indent≠0` 或 `PI≠0` 时结构性不可达"。

---

# B. 任务 B —— `D-T6-b` 的静态归因（精确到文件:行号）

## B.0 先纠正任务书里那条定位（**推翻**，附证据）

任务书写：「现场在 `build/shims/PresentationCore.HbTextLine.cs` 的宽松回退路径（`HbTextFallback.TryFormatLine` 及其调用者，约 `:4496` 起，以及 `:3851` 起那个 `...FormatLine(...)` 入口）。线索：它"从 `cpFirst` **重新起段**"然后 `return lines[0]`。」

**三处都不准，逐条给证据**：

1. **`HbTextFallback` 不是宽松档，是「严格档」**。`build/shims/PresentationCore.HbTextLine.cs:3972` `internal static class HbTextFallback`；它的调用点在**生成物** `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:565`（`WpfLinux.Shims.PresentationCore.HbTextFallback.TryFormatLine(`），而宽松档在 `:596`（`WpfLinuxLenientTextFallback.TryFormatLine(`），两者在 `:560` / `:590` 两个 `if (textLine == null)` 里**串联**：先严格、后宽松。这与 `#19`/W19A/W19B 的在册口径完全一致（严格档 = `HbTextFallback`）。
2. **宽松档的实现类根本不在 shim 里**：`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:37` `internal static class WpfLinuxLenientTextFallback`，其源模板在 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py:195`。**shim 里没有 `WpfLinuxLenientTextFallback` 这个字符串**（`grep -rn WpfLinuxLenientTextFallback build/shims/` ⇒ 只命中 `:4550` 的一条**注释**）。
3. **`return lines[0]` 不在 shim 里**。`grep -n "lines\[0\]" build/shims/PresentationCore.HbTextLine.cs` ⇒ **`(none)`**。真正的 `return lines[0];` 在 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:264`（源模板 `patch-presentationcore-textline-fallback.py:422`）。严格档对应位置写的是 `HbTextLine first = s_cache.LineAt(cpFirst);` + `return first;`（shim `:4555`/`:4590`）。
4. `:3851` 不是"`...FormatLine(...)` 入口" —— 它是 `HbTextLineFactory.FormatParagraph` 形参表里的 `double indentDip = 0,`（`:3836` 起的那张表）。shim 里的 `FormatLine` 入口是 `:2819`（`internal static HbTextLine FormatLine(`），它的**调用者**是 `:3937`。

⇒ 结论：**`D-T6-b` 的现场主战场在生成物 PC 文件（+ 其应用器），shim 里是「工厂把行帧写成什么」的那一段**。下面的定位按这个更正后的地图给。

## B.1 ① 逐行帧（frame）在真机语义里是什么、由谁产生

**定义**：帧 = **本行自己的第一个字符索引，坐标系 = 调用方传给 `TextFormatter.FormatLine` 的那个 `firstCharIndex` 所处的坐标系**。

- 上游字段即定义：`upstream/wpf/.../TextFormatting/FullTextLine.cs:32`
  `private int _cpFirst;                       // character index to the first charcter of the line`
  （赋值 `:373 _cpFirst = cpFirst;`，由 `TextFormatterImp.cs:241-247` 把宿主传进来的 `firstCharIndex` 原样递下去。）
- 帧**由它产生/被它消费**：`FullTextLine.cs:1495-1504` 是 `GetTextBounds` 的**入口夹取**：
  ```
  1495:                if(firstTextSourceCharacterIndex < _cpFirst)
  1496:                {
  1497:                    textLength += (firstTextSourceCharacterIndex - _cpFirst);
  1498:                    firstTextSourceCharacterIndex = _cpFirst;
  1499:                }
  1501:                if(firstTextSourceCharacterIndex > _cpFirst + _metrics._cchLength - textLength)
  1503:                    textLength = (_cpFirst + _metrics._cchLength - firstTextSourceCharacterIndex);
  ```
  ⇒ **真机 `TextLine.GetTextBounds(int, int)` 的第一个参数是"行自己那一帧"里的索引**（"段落系"= 宿主口径），行对象用 `_cpFirst` 把它换算成行内偏移。`SimpleTextLine` 同构。
- **真机宿主自己就是这么用的**（这就是"帧"的实测锚点）：`tests/parity/windows/tab-anchor/src/Program.cs:510-514`
  ```
  510:            for (int i = 0; i < textLen; i++)
  511:            {
  512:                int gi = lineStart + i;
  513:                if (gi >= text.Length) break;
  514:                IList<TextBounds> b = line.GetTextBounds(gi, 1);
  ```
  其中 `lineStart` = 主循环的 `index`（`:443` 传进 `FormatLine` 的那个值、`:448 index += line.Length;` 累加）⇒ **真机把"行起点 + 行内偏移"喂给 `GetTextBounds`，并且 615 行 × 每字符全部取到了 `TextRunBounds`**（语料 `perChar` 无一个 null；我核过 615 行、292 个 `PI≠0` 行内条目、0 个 null）⇒ **真机的帧是"行自己的起点"，且这就是它的调用约定。**

- 我方对应物：`build/shims/PresentationCore.HbTextLine.cs:2628`
  `private readonly int _lineStart;            // 行起始（段落系）`，赋值 `:2723 _lineStart = lineStart;`。
  它由 `HbTextLineFactory.FormatParagraph`（`:3836`）算出：`:3937-3941` 把 `HbBreakEngine.LayoutText(text, …)` 交回的 `HbLineRange r` 传给 `HbTextLine.FormatLine(text, r, …)`；`r.Start` 的定义（`:1552-1556`）是 `public int Start;                // 段落系（源文本下标）`。
  **关键**：`r.Start` 的坐标系 = **`text` 这个字符串**的坐标系，而 `text` 是**调用方**递给 `FormatParagraph` 的（`:3837` 第一个形参）。
- 我方 `GetTextBounds` 用同一约定：`:3020-3023`
  ```
  3020:            // ⭐ 真机口径（oracle `indexFrames.GetTextBounds_firstArg`）：第一个参数是**段落系**索引，
  3021:            //    不是行内偏移 —— 原型版本按行内偏移算，那是错的（传 0 时只有行起点=0 的行有结果）。
  3022:            int localFirst = firstTextSourceCharacterIndex - _lineStart;
  3023:            if (localFirst < 0 || localFirst > _visibleLength) return new List<TextBounds>();  // 与本行不相交
  ```
  ⇒ **帧（frame）= `_lineStart`，可由静态阅读证明**：臂的 `FrameScan`（`:1101-1106`，我读到的那版）找的是"最小的 `a` 使 `GetTextBounds(a,1)` 拿得到 `TextRunBounds`"，而按 `:3022-3023`，能取到的 `a` 恰是 `_lineStart ≤ a ≤ _lineStart + _visibleLength`，最小值**就是 `_lineStart`**。所以 **帧读数 ≡ `_lineStart`**，与 `--guard` 用哪个索引口径无关（口径决定"取到什么"，不决定"最小值是谁"）。

## B.2 ② 宽松档为什么只能交回第一帧

**机制三步，全部有行号**：

**第一步 —— 宽松档**把它要排的文本重基到 `cpFirst`。
`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:117` `int cp = cpFirst;`，循环从那里往 `sb` 追加（`:159 if (s.Length > 0) sb.Append(s);`、`:169 cp += run.Length;`），`:179 text = sb.ToString();`
⇒ **`text` = 从 `cpFirst` 起的段落余下部分**（不是整段）。
它自己**明说了这个串是重基过的**：`:155-158`
```
155:                // ── T1c/#13：在**平铺之外**多记两个位置（run 序列上、重基到收集串）──
156:            if (run is TextModifier) { modifierOpenIndex = cp - cpFirst; }   // ① 开
157:            if (modifierOpenIndex >= 0 && modifierCloseIndex < 0 && run is TextEndOfSegment)
158:            { modifierCloseIndex = cp - cpFirst; }                            // ② 关（R1）
```
⇒ **modifier 下标被显式 `− cpFirst` 重基**；**但行帧没有做任何重基**。这就是缺口的形状：重基做了一半。

**第二步 —— 工厂按这个重基串算 `r.Start`。**
`TextFormatterImp.Linux.cs:253-258` 调 `HbTextLineFactory.FormatParagraph(text, …)`；工厂内 `:3911-3913` `List<HbLineRange> ranges = HbBreakEngine.LayoutText(text, …)`，`:1823 lines.Add(new HbLineRange { Start = start + pos, … })`，`start` 从 `paraStart = 0` 起（`:1841`）⇒ **第一行的 `r.Start == 0`**。`:3937-3941` 把它交给 `HbTextLine.FormatLine(text, r, …)` ⇒ `:2723 _lineStart = 0`。

**第三步 —— 宽松档无条件把"刚排好的这一段的**第一行**"交出去。**
`TextFormatterImp.Linux.cs:260-264`
```
260:                if (lines == null || lines.Count == 0) { ++s_failed; s_lastFail = "工厂返回 0 行"; return null; }
262:                ++s_handled;
263:                Diag("接手（宽松）：段落起点=" + cpFirst + " 行数=" + lines.Count + " 文本长=" + text.Length);
264:                return lines[0];
```
**宽松档没有段落缓存**（整个 `WpfLinuxLenientTextFallback` 只有 `s_calls/s_handled/s_failed/…` 这些计数器，没有任何 `cache` 字段）⇒ **每次 `FormatLine` 都重新 `CollectLenient(cpFirst)` 并重新排版整段**，然后**只取 `lines[0]`**。

⇒ **合起来**：无论宿主问的是段落第几行，宽松档交回的行对象**永远是"某个以 `cpFirst` 为原点新起的那一段的第一行"** ⇒ `_lineStart ≡ 0` ⇒ **帧恒为 0**。宿主问第 2 行（`cpFirst=2`）时，交回的行把自己的帧报成 **0**，而真机报 **2**。

**严格档为什么（通常）对**：它**有**段落缓存（`shim:3980-3999 class ParaCache`，键 = `(Source, Start)`），`:4531-4536` 命中就直接返回缓存里**那一段**的对应行：
```
4531:                ParaCache c = s_cache;
4532:                if (c != null && ReferenceEquals(c.Source, textSource) && c.Contains(cpFirst))
4534:                    HbTextLine hit = c.LineAt(cpFirst);
4535:                    if (hit != null) { ++Handled; return hit; }
```
`LineAt`（`:3991-3996`）按**累加 `Length`** 定位 ⇒ 返回的是"当初那一段里的第 k 行"，它的 `_lineStart` = 那段里的偏移 = **0,1,2**。缓存是在 `cpFirst=0` 那次建的（`:4554 s_cache = new ParaCache { Source = textSource, Start = cpFirst, Lines = lines };`）⇒ 那些偏移**恰好等于**绝对段落索引 ⇒ 帧看起来是对的。

**⚠️ 由此得到一条在册文档没有的推论（本件的实质发现，且是可检验的预测）**：
> **严格档的帧正确性完全寄生在 `ParaCache` 命中上，而它只在"该段第一次被排时的原点恰好是坐标系原点（`cpFirst=0`）"时才对**。缓存**未命中**时（`:4554` 重新以 `Start = cpFirst` 建缓存），`LineAt(cpFirst)` 在 `LineAt` 的第一次迭代就 `pos == Start == cpFirst` 命中 ⇒ 返回 `Lines[0]` ⇒ **`_lineStart = 0`，与宽松档一模一样**。

**这条推论已被 W20A 的一条实测间接证实**（我静态推出来的形状与它逐字吻合，不需要新读数）：`docs/CURRENT-STATE.md` 里 W20A 的缓存专项原文 ——「缓存专项（`--fresh-source`）实测帧 `0,1,2 → 0,0,0`、失配词消失 ⇒ 缓存相关，**但缓存是"保持正确帧"的一方**」。`--fresh-source` 让 `ReferenceEquals(c.Source, textSource)` 必然为假 ⇒ 每次都走 `:4554` 重建缓存 ⇒ 帧变 `0,0,0`。**这正是本节的推论，且它把 W20A 的"缓存是保持正确帧的一方"升级为机制**：缓存不是"保护帧"，**它是帧的唯一来源**。

⇒ **所以 `D-T6-b` 的准确定性应收紧为**：不是"宽松档独有的缺陷"，而是
> **两个档共有的结构性性质：行帧的原点是"该段落最近一次被重新收集的那个 `cpFirst`"，不是段落起点。宽松档因为完全没有缓存，原点恒等于当前 `cpFirst` ⇒ 帧恒 0；严格档只在缓存未命中时退化成同一形状。**

## B.3 ③ 严格档与宽松档的**分叉点**

**（a）进程/调用层的分叉 —— 在生成物里，不在 shim 里**：

| | 站点 | 原文 |
|---|---|---|
| 严格档 | `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:560-565` | `if (textLine == null)` / `{` / `// WPF-on-Linux（T1b/D3）：先试**托管完整路径**…` / `textLine = WpfLinux.Shims.PresentationCore.HbTextFallback.TryFormatLine(` |
| 宽松档 | 同文件 `:590-596` | `if (textLine == null)` / `{` / `// ── T1c/RTL：**宽松托管兜底**（跳过不支持的 run 类型，而不是 bail）──` / `textLine = WpfLinuxLenientTextFallback.TryFormatLine(` |

⇒ 分叉条件 = **严格档是否返回 `null`**（`:588 }` 结束后 `:590` 再判一次）。上游对应结构是 `TextFormatterImp.cs:224-248`（`SimpleTextLine.Create` 返回 null ⇒ `new TextMetrics.FullTextLine(...)`），移植时把"LS"那一层换成了这条两级托管链。

**（b）机制层的分叉（帧这件事上真正的分岔线）** —— **同在 shim 一份源里的两个"原点"**：

| 角色 | 文件:行 | 它把什么当原点 |
|---|---|---|
| 严格档收集 | `build/shims/PresentationCore.HbTextLine.cs:4442` `int cp = cpFirst;`（`TryCollect`，`:4437`） | **当前 `cpFirst`**（与宽松档同病） |
| 严格档补救 | 同文件 `:4531-4536` + `:4554`（`ParaCache`） | **第一次排版时的 `Start`** ⇒ 正常协议下 = 段落原点 |
| 宽松档收集 | 生成物 `:117` `int cp = cpFirst;`（`CollectLenient`） | **当前 `cpFirst`** |
| 宽松档补救 | **无** | —— |
| 帧落盘点（两档共用） | shim `:2723` `_lineStart = lineStart;`，值来自 `:3937-3941` 传的 `r.Start`（`:1553` `// 段落系（源文本下标）`） | `text` 串的原点 |

⇒ **一句话**：`D-T6-b` 的分叉点不是"哪一行代码分了叉"，而是**"有没有一个以段落原点为键的缓存"** —— 严格档有（`:4531`），宽松档没有（生成物 `:264` 之前的整个类里没有任何 cache 字段）。**两档的 `CollectXxx` 都从 `cpFirst` 起（shim `:4442` / 生成物 `:117`），所以缺口的根在同一处语义假设上：`HbLineRange.Start` 的注释写作"段落系"，但它其实只是"`text` 串系"。**

**⚠️ 顺带一条在册文档没写的**：`build/shims/PresentationCore.HbTextLine.cs:1552-1556` 的注释
`public int Start;                // 段落系（源文本下标）` 与 `:2628` 的 `// 行起始（段落系）`
**在这个调用姿势下是不成立的**（它只在 `text` 恰好从段落原点起时才成立）⇒ 这是 `D-T6-b` 的**文档侧伪证**，与 `#19` 的 item A（`HasOverflowed` 过期注释）同族。

## B.4 ④ 可观测后果（**逐成员说，不一概而论**）

我把 `build/shims/PresentationCore.HbTextLine.cs` 的 `HbTextLine`（`:2622`）里**全部 21 处** `_lineStart` 使用逐处归位（`grep -n "_lineStart"` 21 条，全部列在 §0 的重算输出里）：

| 成员 | 是否受 `_lineStart` 影响 | 证据 | 后果 |
|---|---|---|---|
| **`GetTextBounds(int,int)`** | **是** | `:3022-3023` | 传"行自己那一帧"的索引时：第 k 行（k>0）`localFirst = arg − 0 = arg > _visibleLength` ⇒ **返回空表** `new List<TextBounds>()`（`:3023`）。**这是主后果**。真机在此处是"夹取"（`FullTextLine.cs:1495-1504`）而**不是返回空**。 |
| **`Collapse(...)` / `GetTextCollapsedRanges()`** | **是** | `:3567`、`:3576`（`_collapsedRange = CreateCollapsedRange(_lineStart + visibleLen, …)` 注释写"段落系索引"）、`:3600`、`:3607`、`:3610` | 折后行的 `TextCollapsedRange.TextSourceCharacterIndex` 报 **`0 + visibleLen`** 而不是"行起点 + visibleLen" ⇒ 宿主按字符位置查折叠区间会**指到别的行**。 |
| **`BuildCollapsedLine(...)`** | **是（且更重）** | `:3625` 用 `new HbTextLine(run, shaped, …, collapsedText, 0, …)` —— **帧硬写 0** | `Collapse()` 交回的行**无条件**帧 0（与档位无关）⇒ 对折后行再调 `GetTextBounds` 的调用者全错。 |
| **`GetIndexedGlyphRuns()`** | **是** | `:2793 starts.Add(lineStart + ch.CharStart)`；`:2801 _glyphRunCharStart = … new List<int> { lineStart }`；`:3682 lineEnd = _lineStart + _visibleLength`、`:3685 startChar = … _lineStart` | `IndexedGlyphRun.TextSourceCharacterIndex` 报 **0 起**的索引 ⇒ 按字符索引取字形（如逐字符着色/命中测试的字体回退查询）会错位。 |
| `Start` | **否**（另一条缺陷） | `:3390 public override double Start => 0;` —— 常量，**不读 `_lineStart`** | 与 `D-T6-b` **无关**；这是 `D-T6-c`（任务 A 的修法对象）。**两件事不要混。** |
| `Length` | **否** | `:2736 _length = length;`（= `visibleLen + range.HardBreakLen + eop`，`:2823-2826` 计算） | 不受影响 |
| `Width` / `WidthIncludingTrailingWhitespace` | **否** | `:2739-2740`，来自 `shaped` | 不受影响 |
| `NewlineLength` / `TrailingWhitespaceLength` | **否** | `:2737-2738` 构造参数 | 不受影响 |
| `Height` / `Baseline` / `TextHeight` | **否** | 无 `_lineStart` 出现 | 不受影响 |
| `HasOverflowed` | **否** | 无 `_lineStart` 出现 | 不受影响 |
| `GetTextRunSpans()` | **否** | `:3013` 附近；`_lineStart` 只出现在 `_dumpSeq != 0` 门控的 `NoteSpanQueryOnLine`（`:3009-3010`） | 判据面不受影响（只影响 dump 插桩） |
| `Draw(...)` / `DrawCore(...)` | **否（几何上）** | `:3155/3156/3166/3167/3168` 全是 `HbLineTrace.Site*` 调用 | 屏幕几何不受影响；只影响 `WPF_LINUX_TEXTLINE_TRACE` 的插桩输出 |
| `GetTextLineBreak()` | **否** | `:3465` 只在 `NoteZeroBreakRecordIssued` 的**诊断字符串**里 | 不受影响 |
| `LineStartForDiag` / `FaceDiag` | 诊断，不算判据 | `:3261`、`:3276`、`:3291-3293` | 不受影响 |

**哪种调用者会读错/读空（真机源头，逐个文件:行）**：
- `upstream/.../PresentationFramework/MS/Internal/Text/Line.cs:167` `textBounds = line.GetTextBounds(cp, cch);` 前面紧跟 `:171 Invariant.Assert(textBounds.Count > 0);` ⇒ **我方宽松档交回的第 2..n 行会让真机宿主的不变量直接炸**。
- `upstream/.../MS/Internal/documents/TextBoxLine.cs:259` `IList<TextBounds> textBounds = _line.GetTextBounds(cp, cch);`（`:496` 同）
- `upstream/.../MS/Internal/PtsHost/Line.cs:501`、`:505`、`:995`、`:999`（同形）
- `upstream/.../System/Windows/Controls/TextBlock.cs:2314` `line.GetRangeBounds(dcpStart, dcpEnd - dcpStart, …)` —— `dcpStart = Math.Max(dcpLineStart, dcpPositionStart)`（`:2310`）是**段落系**索引（同一份源码里 `dcpLineStart` 正是喂给 `Format(...)` 的 `firstCharIndex`）⇒ **文本选择高亮框会落到错误的行/位置**（返回空表时 `aryTextBounds.Count > 0` 为假 ⇒ 高亮整块丢失）。
- `upstream/.../MS/Internal/PtsHost/TextParaClient.cs:2114`、`:2224`、`:3940`、`:4139`（同形）
- ⚠️ **本项是否在本移植的构建面内：本件未测**（我只做静态阅读，没有查 `PresentationFramework` 在本工程是否参与构建/被桥消费）。

## B.5 ⑤ `D-T6-b` 是否也影响 `Start`/`Length`/`Width`

**逐成员答（不要一概而论）**：
- **不影响**：`Length`、`Width`、`WidthIncludingTrailingWhitespace`、`NewlineLength`、`TrailingWhitespaceLength`、`Height`、`Baseline`、`TextHeight`、`HasOverflowed`、`GetTextRunSpans`、`Draw` 的屏幕几何。（证据见 B.4 表：这些成员的计算链里**没有** `_lineStart`。）
- **影响**：`GetTextBounds`、`GetIndexedGlyphRuns`、`Collapse`/`GetTextCollapsedRanges`（以及 `Collapse` 交回的行本身）。
- **`Start` 是另一个缺陷**：`:3390` 是常量 0，**与帧无关**。⇒ **`D-T6-b` 与 `D-T6-c` 是两条独立的偏差**，修 `Start` 不会顺带修好帧，反之亦然（这一点很值钱：如果下一波把两者当一件事做，会做出一个只修一半的修法）。

## B.6 判据草案（下一波可直接用）

**判据名（建议）：`D-T6-b` 帧恒等式 —— `R(帧读数) == 真机 lineStart`**

1. **取数（怎么取）**：`PcLineOracle` 已经在印 `行帧（逐行扫描：最小的、能取到边界的段落系下标）=[…]`（`Program.cs` 的 `PCLINE 层级` 行区域）。把该扫描值**逐行**与真值比：`frame[k] == 真值[k]`，**精确相等**（整数，无容差问题）。
   ⚠️ **不要**用 `GetTextBounds(j,1)`（行内口径）取帧 —— W20A 已证明那是另一种装置限制；帧扫描本身与索引口径无关（B.1 末段已给出证明），**但判据行的**其它列必须继续用 `cpFirst + j`。
2. **期望值从哪来（真值来源）**：`tests/parity/windows/tab-anchor/out/tab-anchor-raw.json`
   → `cases[].lines[].startChar`。
   它是真机臂主循环 `index` 的落盘（`tests/parity/windows/tab-anchor/src/Program.cs:556 ["startChar"] = lineStart,`，`lineStart` = `:443` 传给 `FormatLine` 的那个值、`:448` 累加）—— **它就是"本行的帧"的真机真值**，与 `perChar[].i`（`:522 ["i"] = gi`）互为佐证。
   （同一份真值也在 `tab-anchor-oracle.json` 的 `cases[].lines[].startChar` 里；两文件都行，选 `raw.json` 因为它是"原始机器输出"。）
   **替代/加强真值**：`out/tab-anchor-oracle.json` 的 `indexFrames.GetTextBounds_firstArg`（若该字段存在）——**本件未核实该键是否存在**，故主判据用 `startChar`。
3. **反极性（现状必须红、红在哪）**：
   - **红点 = 宽松档腿的每一行 `startChar > 0`**（以及严格档腿在 `--fresh-source` / 缓存未命中时的每一行 `startChar > 0`）：帧读数 = `0`，真值 = `1,2,…`。语料里 `lineStartOffsetsDip` 有 171 行非零 ⇒ **可红的行数至少 171**（跨两档乘法另算）。
   - **必须同时有绿面作正控**：`startChar == 0` 的行（每例第 1 行）**必须绿** ⇒ 若它们也红，说明判据/仪器坏了（纪律 27）。
   - **反极性必须"翻转"而不是"消失"**：严格档腿（缓存命中）应**全绿**，宽松档腿应**红**；若两档同色 ⇒ 判据没有分辨力，不许当成立。
4. **判定**：`rc=0` 需 **615 行帧读数 == 真值**；任何一行不等 ⇒ `rc≠0` 并逐行印 `PCLINE FRAME <id> 行#k 我方=… 真值=… Δ=…`。缺语料/缺 shim/取不到帧 ⇒ `NOINFO rc=2`（不许绿）。
5. **是否需要动 `build/shims/**` = 是否付世代成本**：
   - **要动 shim 的修法（推荐、也最诚实）**：给 `HbTextLineFactory.FormatParagraph`（`:3836`）加一个**带默认值**的"段落原点"形参（如 `int paragraphOrigin = 0`），落到 `_lineStart = range.Start + paragraphOrigin`（`:3937-3941` 透传），并同步到 `_glyphRunCharStart`（`:2793`/`:2801`）。两个档各传自己的原点。
     ⇒ **shim 一改 ⇒ 世代绑定三项之一变 ⇒ `tree_gen=advanced` ⇒ 五臂重取 + `known-red.json` 重钉 + 门禁两极化重做 = 付世代成本。**
     （依据：`docs/CURRENT-STATE.md` 纪律 31/34 与 `#19` 的现场 —— 世代绑定**只绑三项**：`run.sh` / `HbTextLineParity/Program.cs` / **shim**；「`build/MilBridge/run.sh` 只加一段帮助注释 ⇒ 门禁立刻 `TLINE_GATE=NOINFO tree_gen=advanced … rc=2`」。）
   - **只动 PC 生成物的修法（可省世代成本，但只修一半）**：在 `WpfLinuxLenientTextFallback` 里**照抄严格档的段落缓存**（键 `(TextSource, 段落原点)`，从段落原点收集一次，按累加 `Length` 定位要交回的那一行 —— 只用 public 的 `HbTextLine.Length` 即可，**不需要 shim 新成员**）。
     ⇒ PC/应用器不在世代绑定三项内 ⇒ **不用重取五臂**；但**它只把"原点恰好是 0"的正常协议修好**，原点≠0 时两个档仍同病。⇒ 我**不建议**把它当终态，建议当"低成本的现场止血 + 让判据能变红"。
   - **不建议**：只改 `CollectLenient` 的起点（从 0 收集）而不管严格档 —— 会让两档行为进一步分叉，且 `modifierOpenIndex`（生成物 `:156-158`）的重基口径要一起改，容易引入新偏差。
6. **与 `D-T6-c` 严格分离**：本判据**不涉及** `Start`（`:3390`）。下一波若把 `D-T6-c` 的 `Start` 列（W21A 正在落）与本判据合并读，必须分列印，否则"帧绿 + Start 红"会被读成"一半修好了"。

## B.7 本件未测（需运行期）

以下**只有静态推理，没有读数**，如实标：
1. 「宽松档帧恒 0」的**逐行读数**——本件没运行（硬约束），W20A 的 `0,0,0` 是同 pc 上的既有读数，我引它但不冒充本件读数。
2. 「严格档在缓存未命中时也退化成帧 0」——**由静态代码路径推出**（`:4531-4536` 命中判据 + `:4554` 重建 + `LineAt` 首轮命中），并有 W20A 的 `--fresh-source`（帧 `0,1,2→0,0,0`）作为**形状吻合**的间接证据；但"以 `cpFirst=k≠0` 为首调（即**不**用 `--fresh-source`，而是让宿主从段中段起排）时严格档帧 = 0"这一条**没有被任何既有读数覆盖** ⇒ **本件未测（需运行期）**，且它是 B.6 判据草案里"严格档腿在非 0 原点"那一格的前提，下一波必须补测。
3. `PresentationFramework` 的那些消费者（`Line.cs:171` 的 `Invariant.Assert` 等）**在本移植里是否真的会被跑到** ⇒ **本件未测**。
4. 生成物 `TextFormatterImp.Linux.cs` 与源模板 `patch-presentationcore-textline-fallback.py` 的一致性（`--check`）⇒ **本件未测**（另一条车道在做重构建，我不跑任何 dotnet）。
5. 产品默认路径下（不强制档）**有多少例真的落到宽松档** ⇒ **本件未测**；静态上宽松档只在严格档 `return null` 时可及（生成物 `:560`/`:590`、shim `:4527-4528`/`:4541-4542`/`:4556`/`:4594-4595`），而 `WpfLinuxLenientTextFallback` 的立项理由正是 RTL/bidi 那类严格档 `bail` 的输入（生成物 `:592-595`）⇒ **推论：`D-T6-b` 的实际暴露面以 bidi/RTL 及"严格档拒绝的 run 类型"为主**，但这是**推论不是读数**。

---

# C. 任务 C —— "88 条 `PI≠0` 的逐行精算值不可从语料推出"的独立裁定

## C.0 被核的那句话（原文 + 取数时件 sha）

`build/MilBridge/tests/PcLineOracle/Program.cs`，在 **`866d92c8a9f36bf7` 这一版**里位于 `:65-66` 与 `:506`（W21A 正在插"任务 A 的判据列"，行号从我最初读到的 `:44`/`:462` 整体下移；**这句话本身一字未改**）：

```
:65 //   · 88 条 `PI≠0` 例的**逐行数值**不可从语料静态推出（`300·PI` = 7200/14400 会改写断点划分）
:66 //     ⇒ 本臂只**量**它们、不预言论它们（纪律 22：量不出来就报 `NA(source=…)`）。
:506                              + "② 88 条 PI≠0 的**逐行精算值**不可从语料推出（只量不预言）；"
```

## C.1 逐字段核：语料里到底有没有可用的逐行真值字段

**有。而且是全套。** 我逐例逐行逐字段统计（脚本 `$HOME/w21c-scratch/taskC.py`，数据 = `tab-anchor-oracle.json` `a31a813114256faf`，与 `tab-anchor-raw.json` `88559d670f1bb955` 同批同形）：

**`PI≠0` 的行 = 171 行**（`paragraphIndentDip != 0` 的 112 例：`i0p24`48 + `i24p24`36 + `i0p48`24 + `i24p48`4），**16 个逐行字段在 171/171 行上全部存在且非 null**：

| 字段 | 在 `PI≠0` 行的覆盖 | 本臂**是否已用它当判据** |
|---|---|---|
| `width` | 171/171 | **是**（`Program.cs:732` 附近 `double eW = E.GetProperty("width").GetDouble();`） |
| `trailingWhitespaceLength` | 171/171 | **是** |
| `newlineLength` | 171/171 | **是** |
| `lineText` | 171/171 | **是** |
| `perChar[].xFromLeftDip` | **292/292 条非 null** | **是**（`double xfl = pc.GetProperty("xFromLeftDip").GetDouble();`） |
| `perChar[].x` / `.width` / `.codePoint` / `.flowDirection` | 292/292 | 部分（`x` 记录了但判据用 `xFromLeftDip`） |
| `startChar` / `endCharExclusive` | 171/171 | 间接（`lineText` 等价） |
| `paragraphStartOffsetDip` | 171/171 | **否**（从未比较 —— 见 C.3） |
| `widthIncludingTrailingWhitespace` | 171/171 | **否** |
| `height` / `baseline` | 171/171 | **否** |
| `hasOverflowed` | 171/171 | **否** |
| `inkRightDip` | 171/171 | **否** |
| `lengthWithNewline` / `dependentLength` | 171/171 | **否** |
| （例级）`lineStartOffsetsDip` | 112 例全有（615 值） | **否**（从未比较） |

⇒ **`88` 这个数字本身是对的**：`PI≠0` 例共 **112**（56 `@default` + 56 `@tab0`），其中 `script == "latin"` 的 **恰好 88**（其余 24 是 `hebrew`，因面缺字形被覆盖闸跳过）⇒ 88 = **可比集**大小。我独立重算：`Counter({'latin': 88, 'hebrew': 24})` ⇒ **与登记吻合**。

## C.2 裁定：**半对（half-right）**，且这个"半"很危险，因为它读起来像"全对"

| 那句话的成分 | 我的裁定 | 依据 |
|---|---|---|
| "88 条 `PI≠0` 例" | **对** | 112 例中 88 例 latin ⇒ 可比集 88（C.1） |
| "逐行数值…**不可从语料推出**" | **错**（作为"真值不可得"来读） | 语料**完整携带** `PI≠0` 的逐行真值（C.1：16 字段 × 171 行 + 292 条逐字符，0 缺失、0 null）；本臂**实际就在用它们**（`width`/`trailingWhitespaceLength`/`newlineLength`/`lineText`/`xFromLeftDip` 五列比较）⇒ "推出"不需要，**事实就在语料里** |
| "（只量不预言）" | **对**（但理由与它写的不完全一样） | `PI≠0` 的例**结构性地没有 `@i0` 孪生**（我独立核过：把 id 里的 arm 换成 `i0` 后**没有一个** `PI≠0` 例的孪生 id 存在于语料中 ⇒ `0` 例）。所以"预言"（孪生恒等式，本臂 `PCLINE TWIN` 机制）对它**不可用** ⇒ 只能直接对真值"量"。**这一条是本臂已有机制的正确边界，不是说真值缺失。** |
| "纪律 22：量不出来就报 `NA(source=…)`" | **未落地、也不需要** | `grep -n "NA(source="` 在该臂里**只命中 `:66` 注释自身**；实际路径没有一处因 `PI≠0` 而报 `NA`。⇒ 这句是**声明与代码不一致**（不是错，但会误导读者以为 `PI≠0` 的数值没被判定过）。 |
| "（`300·PI` = 7200/14400 会改写断点划分）" | **对**（作为一个机制陈述） | `TextProperties.cs:39-40` `RealToIdeal` ⇒ `PI=24 → 7200`、`PI=48 → 14400`；`FormatSettings.cs:169` `formatWidth -= _pap.ParagraphIndent;` ⇒ 格式化宽度被 `PI` 改写 ⇒ 断点划分确实会被改写。这是"孪生恒等式不能用于 `PI≠0`"的**正确理由**，但它是"不能拿 PI=0 的孪生当真值"，**不是"语料没有真值"**。 |

**结论一句话**：那句话把**两件事**混成一件 —— ①「没有**独立预言**（孪生）」是真的；②「没有**真值字段**」是假的。语料有完整的逐行真值，本臂也一直在用。建议下一波把 `:65-66` 与 `:506` 改成：
> `② 88 条 PI≠0 例**没有 `@i0` 孪生**（`PI→Start` 不是唯一差别，且 300·PI 会改写断点划分）⇒ 对它们**只对真值直比、不做孪生预言**；真值列齐全（`width`/`twl`/`nl`/`lineText`/`perChar[].xFromLeftDip`）。`

## C.3 顺带核出的两处**在册陈述**被原始数据否掉（这才是本任务的额外价值）

**（i）本臂从未比较的列里，有一列正是任务 A 的真值。**
`paragraphStartOffsetDip`（逐行）与 `lineStartOffsetsDip`（例级）**在 171 行上非零、在 444 行上为 0**，而**该臂一次都没比过它们**。主控已据此把任务 A 的判据列排进 `W21A`（我在臂里读到 `:32`、`:378` 的 `StartCol` / `PCLINE START`）。⇒ 这条"从未被比较过"是真的（不是"不可推出"）。

**（ii）语料自己的元数据里有一句被自己的数据否掉的话。**
`tab-anchor-oracle.json` 的 `unavailableOrUntested` 数组最后一条原文：
> `"TextLine.Start is reported but is 0 for every line here; it is not used by any answer."`

**错。** 同一文件同一批数据里：`lineStartOffsetsDip` 有 **171 行** 是 `24`/`48`（`{0: 444, 24: 131, 48: 40}`）⇒ "is 0 for every line here" 被**它自己的数据**否掉。
这条与 `build/shims/PresentationCore.HbTextLine.cs:3390` 的注释
> `public override double Start => 0;          // 真机实测恒为 0（3222/3222），不是段落内偏移`

是**同一条伪证的两次落盘**（`3222` 出自 `layout-b34` 语料，那份语料 `ParagraphIndent` 恒 0 ⇒ 真机在那份语料上**必然**全给 0 —— "0 是语料性质，不是实现性质"）。⇒ 任务 A 的修法除了改代码，**还要改这两处注释**（`:3390` 与 oracle 的 `unavailableOrUntested`），否则同一条伪证会第三次被引用。

---

# D. 读数表（纪律 32）

| 项 | 值 |
|---|---|
| lane | **W21C** |
| date-time | **2026-09-16 18:27:15 +0800**（现场取件）→ 报告落盘 ~18:5x +0800 |
| loadavg | **2.70 1.61 0.68** |
| mem_available | **3757416 kB**（`/proc/meminfo`） |
| kernel | **6.8.0-138-generic** |
| 运行期读数 | **0 条**（硬约束：本件全程未执行任何 `dotnet` 命令；无 `rc` 可报） |
| `pc` sha16 前/后 | **未取、也未变**（本件不写任何 `build/*.Linux/**` 产物）；冻结基线表头 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = `f5d8a6f1cdf49635` |
| `hbtextline` shim sha16 | `fe1b7ed8fa3ed231`（278692 B，2026-09-16 15:30:15） |
| 生成物 PC sha16 | `799e0366b312ec65`（55223 B，2026-09-16 15:31:51） |
| 应用器 sha16 | `daa1fe2a32d454cf`（52168 B，2026-09-16 15:31:55） |
| 真机语料 raw sha16 | `88559d670f1bb955`（1196289 B） |
| 真机语料 oracle sha16 | `a31a813114256faf`（1251441 B） |
| 真机臂源 sha16 | `e6651272200f7fb6`（40998 B） |
| W21 预登记 sha16 | 读时 `9d1e2dddda5b24e8`(14390 B) → 现场 `127be0d931d97adf`(20376 B) |
| 臂 `Program.cs` sha16 | 会话内 `7364f25cda440d05` → `1b7894b92326245e` → `2a4b878d2388d805` → **`866d92c8a9f36bf7`**（W21A 并发编辑中） |
| 重算脚本 | `$HOME/w21c-scratch/taskA.py`、`taskA2.py`、`taskA3.py`、`taskA4.py`、`taskA5.py`、`taskC.py`、`taskC2.py` |
| 本报告 | `build/MilBridge/W21C-report.md` |

---

# E. 我推翻/纠正的既有陈述（汇总）

1. **任务书的定位不准（三条）**：`HbTextFallback`（shim `:3972`）是**严格档**不是宽松档；宽松档 `WpfLinuxLenientTextFallback` 在**生成物**（`TextFormatterImp.Linux.cs:37`）+ 应用器（`:195`），**不在 shim 里**；`return lines[0]` 在生成物 `:264`，**shim 里没有 `lines[0]`**（`grep` ⇒ none）。`shim:3851` 是形参表里的 `double indentDip = 0,` 而不是 `...FormatLine(...)` 入口（`FormatLine` 入口是 `:2819`）。
2. **`D-T6-b` 的定性应收紧**：不是"宽松档独有"，而是**两档共有的"帧原点 = 最近一次重新收集的 `cpFirst`"**；宽松档因**没有缓存**而恒 0，严格档在**缓存未命中**时退化成同一形状。⇒ W20A 那条"缓存是保持正确帧的一方"被**升级为机制**（缓存是帧的**唯一**来源），并可预测：以 `cpFirst=k≠0` 为首调时严格档也会帧 0（**本件未测，需运行期** —— B.7 第 2 条）。
3. **`D-T6-b` 与 `D-T6-c` 必须分开**：帧（`_lineStart`）与 `Start`（`:3390` 常量 0）**互不影响**（B.4 表逐成员证据）；修一个不会修好另一个。
4. **`PcLineOracle/Program.cs:65-66`、`:506` 的"88 条 `PI≠0` 逐行精算值不可从语料推出"** —— **半对**（C.2）：无孪生是真，无真值是假；语料 16 个逐行字段在 171 行上**全部非 null**，且本臂**一直在用**其中 5 列。`grep "NA(source="` 在该臂里只命中这句注释自身 ⇒ 声明与代码不一致。
5. **`tab-anchor-oracle.json` 的 `unavailableOrUntested` 末条 "TextLine.Start is reported but is 0 for every line here"** —— **假**，被同一文件的数据否掉（171 行 = 24/48）。与 shim `:3390` 的 `3222/3222` 是同一条伪证。
6. **shim 里两处注释 "段落系" 在这个调用姿势下不成立**：`:1553 public int Start; // 段落系（源文本下标）`、`:2628 // 行起始（段落系）` —— 它们只在 `text` 恰好从段落原点起时才真。这是 `D-T6-b` 的文档侧伪证（与 `#19` item A 同族）。

**我没有推翻主控在 `docs/WAVE21-PREREGISTRATION.md` §1 里的任何一条**：§A.7 的对照表逐项一致，且四个关键数字（`615/615`、`337/615`、`{0:444,24:131,48:40}`、`LTR 138/RTL 33`）我独立重算后**逐位相同**。

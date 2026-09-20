# R17A recon —— ① 新臂（驱动 PC 的 `TextFormatter`，为 `WAVE17-PREREGISTRATION.md` §1 P2 造红证）② `D-T2` 真身（min/max `TextModifier` 作用域实参）

> **lane = R17A**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **时刻（开头）**：`2026-09-15 23:20:48 +0800`｜`uname -r = 6.8.0-138-generic`｜`/proc/loadavg = 0.49 0.31 0.17`｜`free -m` ⇒ `mem_available = 4088 MB`（total 7923 / used 3440 / free 1432 / buff-cache 3049 / swap used 866）。
> **时刻（收尾）**：`2026-09-15 23:28:13 +0800`｜`loadavg = 0.66 1.00 0.63`｜`mem_available = 3687 MB`（used 3752 / free 181 / buff-cache 3989 / swap used 938）。
> **本报告是只读 recon**：写域 = `build/MilBridge/R17A-recon.md`（本文件）+ `$HOME/wfp-runs/w17-laneR17A/`；**未运行 `dotnet build` / `dotnet test` / `dotnet run` / 任何编译器**，**未启动任何长驻进程**，**未改动** `docs/**`、`build/shims/**`、`src/**`、`samples/**`、`verify-all.sh`、`build/MilBridge/known-red.json`、`build/MilBridge/tools/tline-gate.sh`、`build/*.Linux/**`。
> 全部命令是 `read` / `grep` / `sha256sum` / `stat` / `python3`（只读 JSON）。**权威产物 `pc` 前后一致 = `c0763fc10173e7ff`**（⇒ 机器上那份独占静树实验**没有被本条车道扰动**；本报告不含任何性能类结论）。
> 引用行号**一律现场重读**（纪律 4；§1.5 列出全部锚点）。凡"某读数 = 某值"连 **件 sha + 仪器 sha + 判据口径 + artifact/字段名** 一起写（纪律 15/18/26）。

---

## 0. 三行判决（先给结论）

| 问 | 判决 | 一句话 |
|---|---|---|
| **(a) 用现有 IVT/签名手法，能不能造一支「驱动 PC 的 `TextFormatter`」的臂？** | **能（constructible）——但必须"定向驱动"，且必须显式声明驱动到了哪一层** | 入口**根本不需要 IVT**：`TextFormatter.Create()` 与 `FormatLine`/`FormatMinMaxParagraphWidth` 都是 **public**（`TextFormatter.cs:56/:41`、PC override `TextFormatterImp.Linux.cs:412/:443/:605/:629`；`MinMaxParagraphWidth.MinWidth/MaxWidth` public）。IVT（`OtherAssemblyAttrs.cs:19` → `PresentationCore.Tests` + `WcpPublicKey.snk`，**正对照：`grep -a -c 'PresentationCore.Tests' pc.dll = 1`**）**另加**了"读 PC 内部计数器"的能力（`WpfLinuxLenientTextFallback.Diagnostics`），正是红证需要的**正控**。**但**：默认配置下 PC 会**先**走严格 `HbTextFallback.TryFormatLine`（生成物 `:553`），**它连一个缩进入参都没有**（shim `:4496-4497`）⇒ 臂必须显式把 PC 赶到宽松那一层（`WPF_LINUX_TEXTLINE_FALLBACK=0`），否则它量到的不是 P2 要修的那段代码。 |
| **(b) `Pap.Indent` / `Pap.ParagraphIndent` 能不能从宿主表达出来？** | **能（public API 足够）**，两条都能 | `TextParagraphProperties.Indent` 是 **`public abstract`**（`:95`），`ParagraphIndent` 是 **`public virtual`（默认 0）**（`:102-105`）⇒ 宿主**自己实现一个子类**即可；oracle 侧已有现成模板（`tests/parity/windows/tab-anchor/src/Program.cs:642` `class Para`，`:655` `Indent`、`:656` `ParagraphIndent`）。**反向发现（重要）**：**不能**用 `FormattedText` 这条更"高"的路 —— 它内部把 indentation 硬编码成 0（`FormattedText.cs:235` `0 // indentation not specified`）并自带 `Debug.Assert(_defaultParaProps.Indent == 0.0, …)`（`:1705`），而 `GenericTextParagraphProperties` **连 `ParagraphIndent` 这个 override 都没有** ⇒ **PI 恒 0、`Indent` 恒 0** ⇒ 对 436 例语料**完全不可用**。 |
| **(c) min/max 的 modifier 实参不对称，是否 confirmed？** | **CONFIRMED（代码级，逐字）**，但**"修 min 一处就让两探针用同一把尺子"不成立** | 生成物 `:305`（max）**传** `modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2`；`:311`（min）**一个都不传**（到 `);` 结束）⇒ 声称**成立**。**但**：两探针**都没传 `modifierScopeEnd`**，而 shim 自己在 `:3855-3858` 把 `scopeEnd = -1`（"到段末"）标成**实测错的跨度**（`w=43.59` vs 真值 `156.9167`）⇒ 修完 min **只让两边"同样错"，不是"同样对"**。见 §2.2 的建议与 for/against。 |

**另外一条（不在两问之内，但对 P2 是硬信号，必须让主控先看到）**：
> **`:575` 现在递下去的不是 DIP，是 ideal（×300）。** `settings.Pap.ParagraphIndent` 的类型是 **`int`，单位 = ideal**（`TextProperties.cs:40` `_paragraphIndent = TextFormatterImp.RealToIdeal(paragraphProperties.ParagraphIndent)`；`:87` `internal int ParagraphIndent`），而 `RealToIdeal` 的因子 = **`28800.0/96 = 300`**（`LineServices.cs:1290` `public const double DefaultRealToIdeal = 28800.0 / 96;`；`TextFormatterImp.Linux.cs:1062-1071`）。
> ⇒ `ParagraphIndent = 24 DIP` 时递进 `indentDip` 槽的是 **7200**。`WAVE17-PREREGISTRATION.md:34` 写的修法（`indentDip: settings.Pap.Indent, paragraphIndentDip: settings.Pap.ParagraphIndent`）**同样会 ×300**（`Pap.Indent` 也是 ideal int，`TextProperties.cs:39`/`:82`）。
> **干净修法（锚点已核）**：`FormatLineInternal` 的形参里**就有宿主的 `TextParagraphProperties paragraphProperties`**（生成物 `:512`）⇒ 直接传 **`paragraphProperties.Indent` / `paragraphProperties.ParagraphIndent`**（原始 DIP double，**零换算、零舍入**）。详见 §1.2 发现 F2。

---

## 1. D-1 —— 让"驱动 PC 的 `TextFormatter`"的新臂可造、可判红

### 1.1 入口点：宿主**实际能调**什么（visibility 逐条）

**结论：用 public 的 `TextFormatter`，不用 `internal` 的 `TextFormatterImp`。**

| 类型 / 成员 | 声明处（逐字） | 可见性 | 宿主能否直调 |
|---|---|---|---|
| `TextFormatter` | `upstream/…/textformatting/TextFormatter.cs:33` `public abstract class TextFormatter : IDisposable` | **public** | ✅ |
| `TextFormatter.Create()` | 同上 `:56` `public static TextFormatter Create()`（实现 = `:63` `return new TextFormatterImp();`） | **public static** | ✅（内部 `new TextFormatterImp()` 与宿主无关） |
| `TextFormatter.Create(TextFormattingMode)` | 同上 `:41` | public static | ✅ |
| `TextFormatter.FormatLine(...)` ×2 | 抽象 `:178`/`:200`；**PC 侧 override**：生成物 `:412` / `:443` `public override TextLine FormatLine(` | **public override** | ✅ **首选入口** |
| `TextFormatter.FormatMinMaxParagraphWidth(...)` ×2 | 抽象 `:272`/`:288`；**PC 侧 override**：生成物 `:605` / `:629` `public override MinMaxParagraphWidth FormatMinMaxParagraphWidth(` | **public override** | ✅（D-2 那半的入口） |
| `MinMaxParagraphWidth.MinWidth/MaxWidth` | `MinMaxParagraphWidth.cs:20` `public struct MinMaxParagraphWidth`；`:35` `public double MinWidth`；`:44` `public double MaxWidth` | public | ✅ |
| `TextParagraphProperties` | `TextParagraphProperties.cs:19` `public abstract class TextParagraphProperties` | public | ✅（宿主自己派生） |
| `TextSource` / `TextRunProperties` / `TextLine` | 同为 `System.Windows.Media.TextFormatting` 公开类型 | public | ✅ |
| `TextFormatterImp` | 生成物 `:326` `internal sealed class TextFormatterImp : TextFormatter` | **internal** | ❌ 直调不行；**经 IVT 可以**（一般不需要） |
| `WpfLinuxLenientTextFallback`（宽松兜底，**P2 要修的那一段**） | 生成物 `:37` `internal static class WpfLinuxLenientTextFallback`；`:53` `internal static string Diagnostics` | **internal** | ❌ 直调不行；**经 IVT 可以** ← **红证的正控就靠它** |
| `WpfLinux.Shims.PresentationCore.HbTextLineFactory` | shim `:3777` `internal static class HbTextLineFactory` | internal，且 **只在 `TEXTLINE_SHIM_DIRECT` 下编进 PC**（shim `:3943` `#if TEXTLINE_SHIM_DIRECT`…`:4614` `#endif`；PC csproj `:1611` 定义了该常量） | 经 IVT 可（臂不需要） |
| `FormattedText` | `FormattedText.cs` public | public | ⚠️ **对本语料不可用**，见下 |

**IVT 手法（逐字核实，与派单描述一致）**：
- 授予方：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/OtherAssemblyAttrs.cs:19`
  `[assembly: InternalsVisibleTo($"PresentationCore.Tests, PublicKey={BuildInfo.WCP_PUBLIC_KEY_STRING}")]`
- 借用方：`build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj:25` `<AssemblyName>PresentationCore.Tests</AssemblyName>`、`:34-36` `<SignAssembly>true</SignAssembly>` / `<PublicSign>true</PublicSign>` / `<AssemblyOriginatorKeyFile>…/build/keys/WcpPublicKey.snk`；注释 `:18-19` 自述"程序集名 = `PresentationCore.Tests` + 与 PC 同一把公钥公开签名 ⇒ 借用 PC 的 IVT 名额"。
- **正对照（我自己跑的，纪律 25）**：`grep -a -c 'PresentationCore.Tests' build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` ⇒ **`1`**（该 IVT 名额**真的在产物里**，不是只在源码里）。
⇒ **它同时授予 `WpfLinuxLenientTextFallback`**（同一个程序集的 internal 类型）⇒ 臂可 `Console.WriteLine(WpfLinuxLenientTextFallback.Diagnostics)` 读到 `relaxedCalls/relaxedHandled/…`：**"被测代码真的被走到"的机器可判正控**。

**`FormattedText` 为什么不能用（这是 finding，不是省略）**：逐字 ——
```
FormattedText.cs:227:            _defaultParaProps = new GenericTextParagraphProperties(
FormattedText.cs:228:                flowDirection,
FormattedText.cs:229:                TextAlignment.Left,
FormattedText.cs:230:                false,
FormattedText.cs:231:                false,
FormattedText.cs:232:                runProps,
FormattedText.cs:233:                TextWrapping.WrapWithOverflow,
FormattedText.cs:234:                0, // line height not specified
FormattedText.cs:235:                0 // indentation not specified
FormattedText.cs:236:                );
```
（构造器末参 = `indent`，见 `GenericTextProperties.cs:236-245` 的形参表 `… double indent`。）＋ `FormattedText.cs:1705`
`Debug.Assert(_defaultParaProps.Indent == 0.0, "FormattedText was assumed to always have 0 indent. This assumption has changed and thus the calculation of Width and Overhangs should be revised.");`
＋ `GenericTextParagraphProperties`（`GenericTextProperties.cs:221`）**只有** `:351 public override double Indent`，**没有** `ParagraphIndent` override ⇒ 继承基类 `:102-105` 的 `get { return 0; }`。
⇒ **`FormattedText` 既不能表达 `Indent ≠ 0`，也不能表达 `ParagraphIndent ≠ 0`** ⇒ 对 436 例里 224 条非 0 缩进用例**结构性不可用**。（它的 `MinWidth` 确实会走 `FormatMinMaxParagraphWidth`：`:1520`，但那是**零缩进**路径。）

### 1.2 `Indent` / `ParagraphIndent` 怎么到达 `:575`（以及三条必须知道的接线事实）

**宿主侧（public，两条都能设）**：`TextParagraphProperties.cs`
```
95:        public abstract double Indent
96:        { get; }
...
102:        public virtual double ParagraphIndent
103:        {
104:            get { return 0; }
105:        }
```
模板（oracle 宿主，逐字）：`tests/parity/windows/tab-anchor/src/Program.cs:642` `internal sealed class Para : TextParagraphProperties`、`:655` `public override double Indent => _indent;`、`:656` `public override double ParagraphIndent => _paraIndent;`（同一类里还覆盖了 `FirstLineInParagraph` / `TextWrapping => TextWrapping.Wrap` / `DefaultIncrementalTab` / `FlowDirection`）⇒ **臂照抄这个类即可，不需要 IVT、不需要 shim。**

**进入 `settings` 的链条（逐字）**：
```
生成物:785:                new ParaProp(this, paragraphProperties, useOptimalBreak),      ← 宿主对象被包进 ParaProp
TextProperties.cs:39:            _indent = TextFormatterImp.RealToIdeal(paragraphProperties.Indent);
TextProperties.cs:40:            _paragraphIndent = TextFormatterImp.RealToIdeal(paragraphProperties.ParagraphIndent);
TextProperties.cs:82:        internal int Indent            { get { return _indent; } }
TextProperties.cs:87:        internal int ParagraphIndent   { get { return _paragraphIndent; } }
FormatSettings.cs:110:        internal ParaProp Pap           { get { return _pap; } }
```
⇒ `settings.Pap.Indent` / `settings.Pap.ParagraphIndent` **就是宿主那两条属性**，但**已经被换算成 ideal int**。

真正用到它们的地方（上游）：`FormatSettings.cs:139` `_textIndent = _pap.Indent;`（首行）／`:144` `_textIndent = 0;`（非首行）／`:169` `formatWidth -= _pap.ParagraphIndent;` ⇒ 上游**把 `Indent` 与 `ParagraphIndent` 当两个不同的量**（一个移内容起点，一个缩排版宽）——这正是 P2 的语义依据。

---

#### 发现 F1（新，代码级 proven）：**默认配置下，PC 先走严格层，而严格层根本没有缩进入参**

生成物 `:548-577`（逐字，含上下文）：
```
553:                textLine = WpfLinux.Shims.PresentationCore.HbTextFallback.TryFormatLine(
554:                    textSource,
555:                    firstCharIndex,
556:                    paragraphWidth,
557:                    textSource.PixelsPerDip,
558:                    settings.Pap.AlwaysCollapsible,
559:                    settings.Pap.LineHeight      // 0 = 未设 ⇒ 托管侧用字体自然行高（真机口径）
560:                    ) as TextLine;
...
569:                textLine = WpfLinuxLenientTextFallback.TryFormatLine(
570:                    textSource,
571:                    firstCharIndex,
572:                    paragraphWidth,
573:                    textSource.PixelsPerDip,
574:                    settings.Pap.AlwaysCollapsible,
575:                    settings.Pap.LineHeight, paragraphIndent: settings.Pap.ParagraphIndent
576:                    ) as TextLine;
```
shim 侧严格层的签名与调用（逐字）：
```
shim:4496:        internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth,
shim:4497:                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight)
...
shim:4517:                int consumed;
shim:4518:                List<HbTextLine> lines = HbTextLineFactory.FormatParagraph(
shim:4519:                    text, primaryRun.FontPath, emSize, paragraphWidth, primaryRun.Typeface, (float)pixelsPerDip,
shim:4520:                    primaryProps, alwaysCollapsible, false, lineHeight, out consumed,
shim:4521:                    plan, faces, runProps);
```
⇒ **`HbTextFallback.TryFormatLine` 的形参表里没有 indent，任何一处**；`:4518-4521` 的具名实参只到 `plan, faces, runProps` ⇒ 落到 `FormatParagraph` 的 `indentDip = 0`、`paragraphIndentDip = 0`（shim `:3843`/`:3860` 默认值）。**`Pap.Indent` 与 `Pap.ParagraphIndent` 在这一层被整条丢弃**，而它对**纯 `TextCharacters` 段落**是**先被调用、且会成功**的那一层（严格收集器 `shim:4429-4463`：`TextCharacters` 收、`TextEndOfLine` 停、**其余 `Bail`**）。

**"严格层是应用真正用的那一层"的一手读数（历史，但逐字）**：`handoff.md:1923`
```
HB_TEXTLINE … lines=1 paragraphs=1  fallbackCalls=1 fallbackHandled=1 fallbackBailed=0  minmaxCalls=0  lastBail="-"
```
（`fallbackCalls/fallbackHandled/fallbackBailed` = `HbTextFallback` 的计数器，`shim:4374-4375`；该读数出自 `WPF_LINUX_TEXTLINE_LINEDIAG` + `--minimal --text-volume=2`，属 T1b 时代、**小样本**，但它证明"接手的正是严格层"。）⇒ 该行同时给出 **`minmaxCalls=0`**：应用路径**今天不调 min/max**（与 §2.3 一致）。

**后果（对 P2 是判定性的）**：`WAVE17-PREREGISTRATION.md:32-34` 的修法只动**宽松**那一层（`:230` 加参 + `:256` 透传 + `:575` 传值）⇒ **修完对严格层毫无影响**。所以：
- 如果新臂让 PC 走**默认**配置 ⇒ **修前红、修后仍红**（严格层永远递 0）⇒ **两极性不成立**；
- 新臂必须**显式把 PC 赶到宽松层**（见 §3 的 `WPF_LINUX_TEXTLINE_FALLBACK=0`）；
- 并且应**另外登记**一条：**"`Pap.Indent`/`Pap.ParagraphIndent` 在严格层被丢弃"**（我建议记 `D-T2-d`），它的修法落在 **shim 写域**（给 `TryFormatLine` 加缩进入参）+ 生成物 `:553-560` 调用点 ⇒ **是跨车道的一件**，主控须决定是并进 P2 还是另立一件（`WAVE17-PREREGISTRATION.md::44` 的"同件里不许顺手改两处"约束着的是 P3，但同类风险适用）。

#### 发现 F2（新，代码级 proven）：**递进 `indentDip` 槽的是 ideal 单位，不是 DIP（×300）**

`WAVE17-PREREGISTRATION.md::33` 与 TDT2 §3.4 记的链条（我现场逐字复核，行号一致）：
```
生成物:231:                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight, double paragraphIndent = 0)
生成物:256:                            modifierOpenIndex: modOpen, modifierCloseIndex: modClose, indentDip: paragraphIndent);
生成物:575:                    settings.Pap.LineHeight, paragraphIndent: settings.Pap.ParagraphIndent
```
单位证据：
```
LineServices.cs:1290:        public const double DefaultRealToIdeal = 28800.0 / 96;      ⇒ = 300.0
生成物:1062:        internal static int RealToIdeal(double i)
生成物:1064:            int value = (int)Math.Round(i * ToIdeal);
生成物:1097:        internal static double ToIdeal   { get { return Constants.DefaultRealToIdeal; } }
TextProperties.cs:40:            _paragraphIndent = TextFormatterImp.RealToIdeal(paragraphProperties.ParagraphIndent);
TextProperties.cs:87:        internal int ParagraphIndent   { get { return _paragraphIndent; } }
```
⇒ `PI = 24 DIP` ⇒ `settings.Pap.ParagraphIndent = 7200`；`Indent = 24 DIP` ⇒ `settings.Pap.Indent = 7200`。

shim 侧的 `indentDip` **是 DIP 语义**（逐字）：`shim:3843` `double indentDip = 0,  // 真机 TextParagraphProperties.Indent（只作用首行）`；消费点 `shim:1765` `double lineContentStart = indentDip + paragraphIndentDip;`、`shim:2866` `double witw = shaped.TotalWidthPx + indentDip;`；而**三支 tab 臂自己喂的是 oracle 的 DIP 值**（`CoverageProbe/Program.cs:1355` `indentDip: indentDipCase, paragraphIndentDip: paraIndentCase`，两个值直接来自 oracle JSON 的 `indentDip`/`paragraphIndentDip`）。⇒ **DIP 是唯一自洽的单位。**

**干净修法（锚点已核）**：`FormatLineInternal` 的形参里就有宿主的对象 ——
```
生成物:507:        private TextLine FormatLineInternal(
生成物:508:            TextSource                  textSource,
...
生成物:512:            TextParagraphProperties     paragraphProperties,
```
⇒ `:575` 应写成 `indentDip: paragraphProperties.Indent, paragraphIndentDip: paragraphProperties.ParagraphIndent`（**原始 DIP，零换算**），而不是 `settings.Pap.*`。若坚持用 `settings.Pap.*`，则必须显式 `IdealToReal(…, textSource.PixelsPerDip)`（生成物 `:1042`，注意它含 Display 模式的 `RoundDipForDisplayMode` 与 `Math.Max(value, Constants.DefaultIdealToReal)` 下限；`24 → 7200 → 24.0` 对这些语料值往返精确）。
**同族顺带登记（不改）**：`:559`/`:575` 传的 `settings.Pap.LineHeight` 也是 **ideal int**，而 shim 的 `lineHeight` 是 DIP（`shim:3838` `double lineHeight, // 0 = 未设`；`shim:2751` `_height = lineHeight;`）⇒ **同一个 ×300 家族**；今天不可见只因为语料/应用的 `LineHeight = 0`。**这不是我这条车道的判决**，登记备查（若 P2 动这一行，同一问题会一起爆）。

#### 发现 F3（新，代码级 proven）：**非 0 缩进本身就把段落踢出 `SimpleTextLine` 快路径** —— 对新臂是好消息

`build/PresentationCore.Linux/SimpleTextLine.Linux.cs:203-216`（逐字）：
```
203:            if(    pap.RightToLeft
204:                || pap.Justify
205:                || (   pap.FirstLineInParagraph
206:                    && pap.TextMarkerProperties != null)
207:                || settings.TextIndent != 0
208:                || pap.ParagraphIndent != 0
209:                || pap.LineHeight > 0
210:                || pap.AlwaysCollapsible
211:                || (pap.TextDecorations != null && pap.TextDecorations.Count != 0)
212:                )
213:            {
214:                // unsupported paragraph properties
215:                return null;
216:            }
```
（调用点：生成物 `:534-546`，条件 `!settings.Pap.AlwaysCollapsible && previousLineBreak == null && lineLength <= 0`。）
`settings.TextIndent` = `_textIndent` = 首行的 `_pap.Indent`（`FormatSettings.cs:139`）。
⇒ **凡 `Indent ≠ 0`（首行）或 `ParagraphIndent ≠ 0` 的段落，快路径一律 `return null`** ⇒ PC **必然**落到 `:553`/`:569` 两条托管层。**副产品**：上游自己把两者当**两个不同属性**用（`:207` vs `:208`），这是 P2 语义的**第二条**独立旁证。
⇒ **对新臂的含义**：(i) 224 条非 0 缩进用例**天然**走托管层（红证的射程成立）；(ii) 但 **212 条零缩进用例的首行会被 `SimpleTextLine` 接走**（上游快路径），所以"零缩进对照"**不是同一层的对照** —— 见 §3 的双腿设计。

### 1.3 真值源：`tab-anchor-oracle.json` 的键位表 + 非 0 缩进计数（**224**，不是 208）

**文件**：`tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`（`a31a813114256faf`，1,251,441 B，2026-09-14 19:33:26）—— 顶层键 `[format, derivedFrom, machine, fonts, paragraphProperties, intervalMeasurement, model, answers, unavailableOrUntested, cases]`，`cases` = **436**。

**逐例键（436/436 全部存在，逐键计数见下）**：

| 键 | 位置 | 类型 | 承载什么 | 用途 |
|---|---|---|---|---|
| `id` / `group` / `textId` / `note` | `cases[i]` | str | 例名、族名 | 逐族计数、known-red 配对 |
| **`indentDip`** | `cases[i]` | int，取值 **{0, 24}**（0:284 / 24:152） | **`TextParagraphProperties.Indent`**（DIP） | ✅ 臂喂 `pap.Indent` |
| **`paragraphIndentDip`** | `cases[i]` | int，取值 **{0,24,48}**（0:324 / 24:84 / 48:28） | **`TextParagraphProperties.ParagraphIndent`**（DIP） | ✅ 臂喂 `pap.ParagraphIndent` |
| `indentArm` | `cases[i]` | str ∈ {`i0`,`i24`,`i0p24`,`i24p24`,`i24nl`,`i0p48`,`i24p48`} | 臂标签（`nl` = `FirstLineInParagraph=false`） | 族内分组 |
| **`paragraphWidthDip`** | `cases[i]` | int ∈ {40,80,96,100,140,160,192,200,220,260,1000} | **输入**容器宽 | ✅ 臂的 `paragraphWidth` 实参 |
| **`textWrapping`** | `cases[i]` | str，**436/436 全 = `"Wrap"`** | 输入换行口径 | ✅ 臂的 `pap.TextWrapping` |
| `emSizeDip` / `dpi` / `fontFamily` / `fontUri` / `fontSha256` / `script` / `flowDirection` / `firstLineInParagraph` / `incrementalTabArm` | `cases[i]` | — | 其余输入（`script` ∈ {latin 288, hebrew 116, arabic 32}） | 覆盖闸、bidi 闸 |
| `lineCount` / `tabCount` / `stoppedEarlyBecauseLineLengthWasZero` / **`lineStartOffsetsDip`** | `cases[i]` | — | 逐例汇总 | 结构量 |
| **`lines[]`** | `cases[i].lines` | list | **逐行真值** | ✅ 结构判据 |
| ├ `index` / `startChar` / `endCharExclusive` / `lengthWithNewline` / `dependentLength` / `newlineLength` / `trailingWhitespaceLength` / `lineText` / `breakCause` / `breakCauseNote` / `hasOverflowed` / `inkRightDip` / **`paragraphStartOffsetDip`** | 每行 | — | 行级 | 行数 / 尾部空白 / 换行长 |
| ├ **`width`** | 每行 | double | **行宽（不含尾随空白）** | ✅ **宽度判据的字段** |
| └ `widthIncludingTrailingWhitespace` / `height` / `baseline` | 每行 | double | — | 备查 |
| **`perChar[]`** | 每行 | list | **逐字符真值位置** | ✅ **位置判据的字段** |
| └ `i` / `char` / `codePoint` / **`x`** / **`xFromLeftDip`** / `width` / `flowDirection` | 每字符 | — | `xFromLeftDip` = 本行**视觉左**（`CoverageProbe:1426-1427` 已实测复核：真值 `x` 是它的镜像） | ✅ 臂用 `GetTextBounds(i,1)[0].TextRunBounds[0].Rectangle.X` 直接比它（`CoverageProbe:1428-1430`，容差 **0.05**） |

**非 0 缩进计数 —— 我现场数出来了，**真实总数 = **224**（不是 208）：**

```bash
python3 -c "
import json,collections
d=json.load(open('tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json'))
cs=d['cases']
nz=lambda c: c['indentDip']!=0 or c['paragraphIndentDip']!=0
print(len(cs), sum(1 for c in cs if nz(c)))
print(collections.Counter(c['group'] for c in cs if nz(c)))
print(collections.Counter(c['group'] for c in cs))"
```
逐字结果：`436` ｜ **`224`** ｜ `Counter({'B-indent': 72, 'B-indent-extra': 72, 'D-paraindent': 64, 'C-rtl-indent': 16})`。

| 族 | **非 0 缩进 / 全族** | 缩进臂 | 备注 |
|---|---|---|---|
| `A-anchor` | **0 / 84** | i0 | 锚点族，纯对照 |
| `A-contrast` | **0 / 28** | i0 | |
| `B-indent` | **72 / 144** | i24 | 只有一半是 `Indent=24` |
| `B-indent-extra` | **72 / 72** | i0p24 24 / i24nl 24 / i24p24 24 | |
| `C-rtl-indent` | **16 / 32** | i24 | **RTL** |
| `D-paraindent` | **64 / 64** | i0p24 24 / i0p48 24 / i24p24 12 / i24p48 4 | |
| `P-probe` | **0 / 12** | i0 | |
| **合计** | **224 / 436** | — | `indentDip≠0` = **152**；`paragraphIndentDip≠0` = **112**；并集 **224** |

**对"208"这条旧读数的处置（不是静默覆盖）**：`CoverageProbe/Program.cs:1307-1312` 的注释逐字写着
> `【主控 2026-09-15 修：**本臂从未把 oracle 的缩进喂下去** ⇒ 208 例结构性不可比】… oracle 的 indentDip/paragraphIndentDip 非 0 的用例 = B-indent 144 + B-indent-extra 72 + D-paraindent 64 中的 208 条`

⇒ 该 208 的可复算口径应当是 `B-indent 的 i24 一半 72 + B-indent-extra 72 + D-paraindent 64 = 208`（注释把"B-indent 144"写成了全族数而非非 0 数）。**它漏了 `C-rtl-indent` 的 16 条 i24** ⇒ 正确总数 **224**。这是**加一条族**的更正，不改任何既有读数（那批用例当时确实结构性不可比）。**`224` 这个数我第一次给出来，来源 = 上面那条可复算命令。**
（旁证：`script == latin` 的例数 = **288**，与 `tab-anchor` 臂自报的 `不可比(缺字形)=148`（= hebrew 116 + arabic 32）**逐位吻合** ⇒ 我的分类口径与臂的覆盖闸是同一把尺子。）

**"对照/对照集"的划分（后面红证要用）**：
- 可比（`script=latin`）= **288**；不可比（hebrew/arabic）= **148**。
- 可比里：**非 0 缩进 = 184**（`B-indent` 72 + `B-indent-extra` 72 + `D-paraindent` 拉丁 40）；**零缩进 = 104**（`B-indent` i0 72 + `A-anchor` 28 + `P-probe` 4）。
- 184 里：`ParagraphIndent == 0 && Indent != 0` = **96**（B-indent 72 + B-indent-extra 的 `i24nl` 24）；`ParagraphIndent != 0` = **88**。

### 1.4 红证设计：**具体可测的预言**

**被测代码（必须钉死）**：`WpfLinuxLenientTextFallback.TryFormatLine` 的 **`:231` 形参 → `:256` 透传 → shim `FormatParagraph.indentDip` → `shim:1765/1771/2866`**。臂必须证明它走到了这里（§3 的正控）。

**今天这条链的实际取值（两态，都必须写清，否则预言有歧义）**：

| 层 | `indentDip` | `paragraphIndentDip` | 什么时候是它 |
|---|---|---|---|
| **L（宽松 = P2 要修的那层）** | `settings.Pap.ParagraphIndent` = **`RealToIdeal(PI)` = 300·PI** | **0**（从不传） | 臂设 `WPF_LINUX_TEXTLINE_FALLBACK=0` 时**必然** |
| **S（严格 = 应用默认走的那层）** | **0** | **0** | 默认配置 + 纯 `TextCharacters` 段落 |

**shim 的语义（真值口径，逐字）**：
```
shim:1765:                double lineContentStart = indentDip + paragraphIndentDip;      ← 内容起点 x
shim:1771:                                                  indentDip, out tabClamped);   ← 件 1a：网格锚 = indentDip
shim:2866:            double witw = shaped.TotalWidthPx + indentDip;                      ← 行宽 = 内容宽 + Indent
```
真值（oracle 自证）：内容起点 = **`Indent + PI`**、网格锚 = **`Indent`**、行宽 = **内容宽 + `Indent`（不含 PI）** —— 例：`i0p24` 的行宽与 `i0` **完全相同**（26.693333），而每字符 `x` = 24。

⇒ **L 层闭式预言（今天）**：`Δwidth = 300·PI − Indent`，`Δx_first = 300·PI − (Indent + PI)`。
⇒ **S 层闭式预言（今天）**：`Δwidth = −Indent`，`Δx_first = −(Indent + PI)`。

#### 两个"由 oracle 自己的测量值推出、不需要模型"的命名例（**PI = 0，闭式与孪生例一致 ⇒ 精确可算**）

**孪生法**：`B-indent/*@i24@*` 与 `B-indent/*@i0@*` 只差 `Indent`（我逐字段核过：除 `id`/`indentArm`/`indentDip`/`lineStartOffsetsDip`/`lines` 外**其余键逐一相同**）⇒ `PI = 0` 时 L/S 两层喂进去的缩进**全是 0** ⇒ **我方读数必须逐位等于 `i0` 孪生例（已实测的真值）**。这不是估算，是"同一份输入、同一份代码"的恒等式。

**例 A（宽度字段判红）** `B-indent/notab-control@w80@LTR@i24@default`（`text='ab'`、em 24、w 80、`Indent=24`、`PI=0`、LTR、`default` 停靠）：
| 量 | 真值（oracle 实测） | 我方**预言**（= `…@i0@default` 孪生例实测值） | **Δ** |
|---|---|---|---|
| 行数 | 1 | 1 | 0 |
| `lines[0].width` | **50.693333** | **26.693333** | **−24.000000** |
| `perChar[0].xFromLeftDip`（'a'） | **24.000000** | **0.000000** | **−24.000000** |
| `perChar[1].xFromLeftDip`（'b'） | **37.346667** | **13.346667** | **−24.000000** |
⇒ 容差 0.05 ⇒ **必红**（15 倍于臂的既有 `worst` 量级阈值）。修后应**逐位等于真值**。

**例 B（宽度字段**不**判红，只有 tab 网格锚判红）** `B-indent/lead-tab-a@w140@LTR@i24@default`（`text='\ta'`、em 24、w 140、`Indent=24`、`PI=0`）：
| 量 | 真值 | 我方预言（`i0` 孪生） | Δ |
|---|---|---|---|
| 行数 | 1 | 1 | 0 |
| `lines[0].width` | **109.346667** | **109.346667** | **0.000000（绿）** |
| `perChar[0]`（`\t`）`xFromLeftDip` | **24.000000** | **0.000000** | **−24.000000（红）** |
| `perChar[1]`（'a'）`xFromLeftDip` | **96.000000** | **96.000000** | **0.000000（绿）** |
⇒ **这条比"宽度差 24"值钱得多**：它把红**唯一地**钉在**网格锚（`indentDip`）**上，而不是"整体右移"或"行宽少加一项"。⇒ 与 P2 断言的机制（"网格锚用了 `PI` 而不是 `Indent`"）**一一对应**；若这条**修前不红** ⇒ 按 `WAVE17-PREREGISTRATION.md::40` 的"红则停"，**P2 的机制判断被否掉**。

**例 C（多行 + 第二行也吃 `Indent`）** `B-indent/lead-tab-a@w100@LTR@i24@default`：真值 2 行（`\t` 行宽 96.000000；`a` 行宽 **37.346667**）；我方预言 = `i0` 孪生（96.000000；**13.346667**）⇒ 第 2 行 `Δwidth = −24.000000`、两行的字符 `x` 各 `−24.000000`。

#### 那 88 条 `PI ≠ 0` 的：**predicted 但不可从语料精确算出**（照实写）

在这 88 条上（`i0p24` 48 / `i0p48` 28 / `i24p24` 36 / `i24p48` 4 中的拉丁部分），L 层递下去的是 **7200 / 14400**：
- 方向确定：`Δwidth = 300·PI − Indent` ⇒ `i0p24` 约 **+7200**、`i0p48` 约 **+14400**、`i24p24` 约 **+7176**；
- **但"每一行"的宽度/行划分算不出来**：`shim:1774` `if (wb + paragraphIndentDip > width + 1e-9) break;` 与 `shim:1804` `if (w + lineContentStart + ae > width + 1e-9) break;` 里 `lineContentStart = 7200` ⇒ **断行决定被这个量级彻底改写**（`'ab'` 在 w=80 下会变成逐字断行 / 触发 `:1791-1809` 的强制断 fallback），行级数字依赖后续控制流 ⇒ **不可从语料静态推出**。
⇒ **处置**：这 88 条只写"**predicted RED，方向 = 内容起点与行宽都向右/变宽一个 `300·PI` 量级**"，**不写具体数**；具体数由新臂跑出来（这正是需要新臂的理由）。**不拿模型数冒充读数**（纪律 22 同族）。
（S 层那半边**精确可算**：`i0p24` ⇒ `Δwidth = 0`（绿）、`Δx = −24`（红）；`i24p24` ⇒ `Δwidth = −24`、`Δx = −48`。⇒ **S 层与 L 层的红法不同**，这也是必须显式声明"驱动到哪一层"的第二个理由。）

#### 两极性（判据形态，含自带阴性对照）

| 时刻 | 预期读数（新臂，可比 288 例） | 依据 |
|---|---|---|
| **修前（今天）** | `判定过 ≈ 104`（零缩进拉丁）、**`败 ≈ 184`**、`不可比=148`；其中 96 条具**精确**Δ（例 A/B/C），88 条为"predicted、量级 300·PI" | §1.3 划分 + 上面的闭式 |
| **修后（P2 落地且 DIP 正确）** | 284/288+（± 已登记保留红）⇒ 至少 **184 条从红转绿**，且**零缩进的 104 条逐位不动** | 真值口径 = 修法目标 |
| **坏修法（P2 按 `settings.Pap.*` 直传）** | 184 条**仍红**（`i0p24` 那类 Δ≈+7200） ⇒ **新臂能把 F2 抓住** | §1.2 F2 |
| **阴性对照（必须绿）** | 104 条零缩进拉丁例**今天就必须 PASS**；若它们今天也红 ⇒ **臂本身坏了**（口径错/字体不可比/层选错）⇒ 按纪律 27（空集/假绿）处理，**不算达成** | `A-anchor` 84 + `P-probe` 12 的 i0 部分 |

### 1.5 现场锚点（**行号全部刚刚重读**，逐字；纪律 4）

生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（`f86198dfdd349332`，51,594 B）：
```
229:        /// <summary>宽松版 `TryFormatLine`：接不了返回 null（调用方**原样**回落 LS，不假装成功）。</summary>
230:        internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth,
231:                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight, double paragraphIndent = 0)
...
256:                            modifierOpenIndex: modOpen, modifierCloseIndex: modClose, indentDip: paragraphIndent);
...
273:        /// <summary>宽松版 `TryMinMaxParagraphWidth`：与 shim 同构（宽=∞ 取 Max，宽=0 取 Min）。</summary>
274:        internal static bool TryMinMaxParagraphWidth(TextSource textSource, double pixelsPerDip,
275:                                                     out double minWidth, out double maxWidth)
...
569:                textLine = WpfLinuxLenientTextFallback.TryFormatLine(
...
575:                    settings.Pap.LineHeight, paragraphIndent: settings.Pap.ParagraphIndent
```
| 要什么 | 锚点 | 逐字 |
|---|---|---|
| **唯一一份 `TryFormatLine` 声明**（生成物内） | **`:230`**（签名延续 `:231`） | `internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth,` / `double pixelsPerDip, bool alwaysCollapsible, double lineHeight, double paragraphIndent = 0)` |
| **`:575`-区（含 `settings.Pap.ParagraphIndent`）** | **`:575`** | `settings.Pap.LineHeight, paragraphIndent: settings.Pap.ParagraphIndent` |
| `indentDip:` 调用点 | **`:256`**（**全文件唯一一处**；正对照：同文件 `modifierOpenIndex` = 6 处） | `modifierOpenIndex: modOpen, modifierCloseIndex: modClose, indentDip: paragraphIndent);` |
| **包裹方法名** | `WpfLinuxLenientTextFallback.TryFormatLine`（`:230`）｜**调用它的方法** = `TextFormatterImp.FormatLineInternal`（`:507`）｜`:575` 位于 `FormatLineInternal` 的宽松兜底块 `:563-577` 内 | — |
| **`:575` 外层方法** | `TextFormatterImp.FormatLineInternal`（`:507`），宿主对象形参 = `:512 `TextParagraphProperties     paragraphProperties,` | 见 §1.2 F2 |
| 上游同名（**不同类**，`:553` 的严格层） | shim `:4496-4497` | `internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth,` / `double pixelsPerDip, bool alwaysCollapsible, double lineHeight)` |
| `FormatParagraph` 全签名（**`:3777` 那个类**） | 类 `shim:3777` `internal static class HbTextLineFactory`；方法 `shim:3828` | `internal static List<HbTextLine> FormatParagraph(` … `shim:3843: double indentDip = 0,  // 真机 TextParagraphProperties.Indent（只作用首行）` … `shim:3860: double paragraphIndentDip = 0)   // D-T2/(C)：尾随可选，默认 0 ⇒ 既有调用点零改动` |
| `startPenX` / `lineContentStartX` / `_startPenX` | `shim:392`/`:394`（`ApplyTabStops` 形参）、`:625`/`:627`（`Shape` 形参）、`:644`/`:653`（`segPen` 消费）、`:2708`/`:2712`（`HbTextLine` ctor → `_startPenX`）、`:2633`（字段注释）、`:3328`（`AdvanceBefore` 用）、`:3421`（`HasOverflowed` 用）、`:2834-2836`/`:2840-2842`（`FormatLine` 里的两处传参） | `shim:2633: private readonly double _startPenX;         // 内容起点（container 系）= **`Indent + ParagraphIndent`**`；`shim:2836: indentDip + paragraphIndentDip)   // 件2b：笔位自段落原点(=0)；内容起点 = I + PI` |
| 应用器（点对点映射，**生成物 L ↔ 应用器 L−143** 由 TDT2 证，我复核了三处） | `:373-374` ≡ 生成物 `:230-231`；`:399` ≡ `:256`；`:490` ≡ `:575` | `:399: modifierOpenIndex: modOpen, modifierCloseIndex: modClose, indentDip: paragraphIndent);`；`:490: settings.Pap.LineHeight, paragraphIndent: settings.Pap.ParagraphIndent` |
| oracle 宿主 `Para` 模板 | `tests/parity/windows/tab-anchor/src/Program.cs:642` / `:655` / `:656` | `internal sealed class Para : TextParagraphProperties` / `public override double Indent => _indent;` / `public override double ParagraphIndent => _paraIndent;` |
| `SimpleTextLine` 快路径闸门 | `SimpleTextLine.Linux.cs:203-216`（`:207` `settings.TextIndent != 0`、`:208` `pap.ParagraphIndent != 0`） | 见 §1.2 F3 |

> ⚠️ **一处与派单/预登记措辞的口径差（必须点名）**：派单说"`TryFormatLine` **只有一份**"要按**文件**限定 —— 生成物里 `TryFormatLine` 的**声明**确实只有 1 份（`:230`），但**同名方法在 shim 里还有一份**（`:4496`，**不同类、不同形参表**，且是应用默认路径那一份）。`#16` 波 `T1c` 就是撞在这上面（`docs/CURRENT-STATE.md:278`：`TextFormatterImp.Linux.cs(559,46) error CS1739` = 改 `:230` 签名却撞到**另一个类**的同名方法）。**本报告一律写"生成物 `:230`"或"shim `:4496`"，不写裸 `TryFormatLine`。**

---

## 2. D-2 —— 真身：min vs max 探针的 `TextModifier` 作用域实参

### 2.1 两个探针并排（生成物 `:300-312`，逐字，含上下文）

`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（`f86198dfdd349332`），方法 = `WpfLinuxLenientTextFallback.TryMinMaxParagraphWidth`（声明 `:274-275`，`:273` 注释"宽松版 `TryMinMaxParagraphWidth`：与 shim 同构（宽=∞ 取 Max，宽=0 取 Min）"）：
```
300:                int c1, c2;
301:                System.Collections.Generic.List<WpfLinux.Shims.PresentationCore.HbTextLine> wide =
302:                    WpfLinux.Shims.PresentationCore.HbTextLineFactory.FormatParagraph(
303:                        text, fontPath, props.FontRenderingEmSize, double.MaxValue, gt, (float)pixelsPerDip,
304:                        props, false, false, 0, out c1,
305:                            modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2);
306:                for (int i = 0; i < wide.Count; ++i) if (wide[i].Width > maxWidth) maxWidth = wide[i].Width;
307:
308:                System.Collections.Generic.List<WpfLinux.Shims.PresentationCore.HbTextLine> narrow =
309:                    WpfLinux.Shims.PresentationCore.HbTextLineFactory.FormatParagraph(
310:                        text, fontPath, props.FontRenderingEmSize, 0.0, gt, (float)pixelsPerDip,
311:                        props, false, false, 0, out c2);
312:                for (int i = 0; i < narrow.Count; ++i) if (narrow[i].Width > minWidth) minWidth = narrow[i].Width;
```
应用器同段（`patch-presentationcore-textline-fallback.py`，`sha16 07dc7627f609e031`，37,625 B）：`:445-448` = 生成物 `:302-305`、`:452-454` = 生成物 `:309-311`（偏移 **−143**，TDT2 §2.3 已给字节级证明；我复核了行数对应）。

**逐项判决（对"max 传 `modifierOpenIndex/CloseIndex`、min 一个都不传"）：**

| 量 | max 分支 `:302-305` | min 分支 `:309-311` | 判决 |
|---|---|---|---|
| 宽度实参 | `double.MaxValue`（`:303`） | `0.0`（`:310`） | 口径本身，**有意** |
| `modifierOpenIndex` | **传了** `modOpen2`（`:305`） | **不传** | **不对称（CONFIRMED）** |
| `modifierCloseIndex` | **传了** `modClose2`（`:305`） | **不传** | **不对称（CONFIRMED）** |
| `modifierScopeEnd` | **不传**（默认 `-1`） | **不传** | **两边都缺**（见 §2.2） |
| `indentDip` | 不传（默认 0） | 不传（默认 0） | 对称（`WAVE16` 那条"indent 不对称"确已作废，TDT2 判对） |
| `paragraphIndentDip` | 不传（默认 0） | 不传（默认 0） | 对称 |
⇒ **声称成立**（`CONFIRMED`），且**是本文件里唯一一处 min/max 具名实参差**。

**另一条精度补充（TDT2 没写，但影响"同一把尺子"的含义）**：严格层那份 min/max **是对称的**（shim `:4587-4593`，两个探针的具名实参**都只有** `plan, faces`）：
```
4587:                List<HbTextLine> wide = HbTextLineFactory.FormatParagraph(text, primaryRun.FontPath, emSize,
4588:                    double.MaxValue, primaryRun.Typeface, (float)pixelsPerDip, primaryProps, false, false, 0, out c1,
4589:                    plan, faces);
4591:                List<HbTextLine> narrow = HbTextLineFactory.FormatParagraph(text, primaryRun.FontPath, emSize,
4592:                    0.0, primaryRun.Typeface, (float)pixelsPerDip, primaryProps, false, false, 0, out c2,
4593:                    plan, faces);
```
⇒ **这处不对称只存在于宽松层**（`:302/:309`），不存在于严格层。**"min 与 max 不同源"是宽松层特有的形态。**

### 2.2 max 那条 `scopeEnd = -1` 是不是也被 shim 自标为错？修 min 一处够不够？

**shim 的两处原文（我现场重读，行号与 TDT2 引用一致）：**
```
1729:            if (modifierOpenIndex >= 0)
1730:            {
1731:                int kl = Math.Max(0, modifierOpenIndex - start);
1732:                int kh = (modifierScopeEnd < 0 ? len : Math.Min(modifierScopeEnd - start, len));
1733:                for (int i = kl; i < kh && i < adv.Length; ++i) adv[i] = 0;
1734:            }
```
（上下文 `:1726-1728`：`// #13：**零宽必须同时落在测量侧**…跨度只认客户端覆盖终点 modifierScopeEnd（<0 ⇒ 到段末），**与 closeIndex 无关**。`）

```
3854:            //   ⚠️ **零宽跨度另有一个来源**（2026-09-15 自验档实测纠正）：客户端覆盖的**字符范围终点**
3855:            //      `modifierScopeEnd`（半开；`-1` ⇒ 到段末）。它**不等于** `closeIndex`：
3856:            //      b34 语料 `open=6, close=-1, 覆盖终点=45`（`cases.json` 的 `modifierEnd=45`），
3857:            //      若拿 `close<0` 当"到段末"，会把 [6,63) 全零宽 ⇒ 实测 `w=43.59`，而真值 `156.9167`
3858:            //      （= 可见 `[0,6)+[45,63)` 共 24 字符）⇒ **跨度只认 `modifierScopeEnd`**，`closeIndex` **只**管 `lbNull`。
```
（`:3859` `int modifierOpenIndex = -1, int modifierScopeEnd = -1, int modifierCloseIndex = -1,`；`:3860` `double paragraphIndentDip = 0)`。）

**判定：**
1. **`scopeEnd = -1`（"到段末"）确实被 shim 自己标成"实测错的跨度"，而且 max 探针正是这一支**：max 传了 `open`/`close` 但**没传 `scopeEnd`** ⇒ `:1732` 取 `len` ⇒ 零宽跨度 = **`[open, 段末)`** —— 与 `:3857` 描述的那条错法**同一条**（shim 在那条上实测 `w=43.59`，真值 `156.9167`）。
2. **`closeIndex` 不参与零宽跨度**（`:3858` 明文"`closeIndex` **只**管 `lbNull`"；代码证据：`FormatParagraph` 只把 `modifierCloseIndex` 用于 `lineHasModifier` 判定（shim `:3925-3928`），而把 `modifierOpenIndex/modifierScopeEnd` 透传给 `LayoutText`（`:3903-3905`）与 `HbTextLine.FormatLine`（`:3929-3933`））⇒ **max 传了 close 并不"修正"它的跨度**，只影响 `lbNull`/`modifierLines`。
3. ⇒ **修 min 一处 ⇒ 两探针"参数形态一致"，但"尺子本身仍是错的那把"**：修完 min 后会得到 **min 与 max 都是 `[open, 段末)` 零宽** —— 即 TDT2 §2.5 表里 max 那一行（`maxWidth = 0.00`）会成为**两边共同的值**，"`min > max`"这条契约违反**会被消掉**（这正是 P3 §1 的红证设计要的两极性），**但两边一起错**。

**⚠️ 关键补充（TDT2 §2.5 那张表要收窄）**：`[open, 段末)` **只在"客户端覆盖终点 < 段末"时才错**。若客户端的 scope 真的覆盖到段末（`modifierScopeEnd` 语义上 = 段末），`-1 ⇒ 到段末` 就是**正确**的。而**宽松层的 `CollectLenient` 根本不收集"覆盖终点"** —— 生成物 `:101-103` 的形参表逐字：
```
101:        private static bool CollectLenient(TextSource src, int cpFirst,
102:                                           out string text, out TextRunProperties props,
103:                                           out int modifierOpenIndex, out int modifierCloseIndex)
```
（`:156-158` 只记 `modifierOpenIndex`（`run is TextModifier`）与 `modifierCloseIndex`（配对 `TextEndOfSegment`，且注释 `:107-112` 自述这是"**未验证的选择**"R1））
⇒ **PC 这条路上"覆盖终点"这个量今天取不到** ⇒ 想真正修好 max（和修完的 min），必须**先让 `CollectLenient` 收集覆盖终点**（它只能从 `TextSource` 的 run 序列里推，而"覆盖终点"与"close run 下标"是两个不同的量，`:3855-3856` 明写）—— 这是**第二处改动**。

#### 我的建议（**明确标注为 recommendation**）

> **建议 R1（P3 按登记原文落，只改一处）**：给 min 探针补齐 `modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2`（与应用器 `:452-454` 同处一并改）。理由（for）：① 与 max **参数同源**，是本件登记的唯一目标；② 两侧都取 `[open, 段末)` ⇒ `min > max` 消失 ⇒ P3 §1 的两极性判据可判（修前必现 `min > max`）；③ 一处改动、可归因（纪律"同件里不许顺手改两处"）。
> **建议 R2（另立登记，不在 P3 里做）**：**新登记 `D-T2-c`：PC 宽松层的两个探针都用了"已知错"的零宽跨度**（`scopeEnd` 缺项；根因 = `CollectLenient` 不收集覆盖终点，生成物 `:101-103`）。修法 = 给它加 `out int modifierScopeEnd` + 两个探针都传；**这一条会同时改 max 与 min，不能与 R1 同波同件**（否则归因作废）。
>
> **for R1（支持）**：代码事实清楚（`:305` vs `:311`）；shim 侧语义与真值口径已在 `#13` 被钉死过（`docs/CURRENT-STATE.md:53`：`M_modifier_winf 行#0 439.1360 → 156.9280`，真值 `156.9167`）⇒ 行路径用"零宽"，min/max 没有理由不用同一口径。
> **against R1 / 对"必须动 max"的反证**：① **`[open, 段末)` 并不总是错** —— 当客户端的 scope 真到段末时它就是对的；`WAVE17-PREREGISTRATION.md::44` 让 recon 判"max 那条要不要也改"，**在"我们取不到覆盖终点"的今天，改 max 无处可改**（只能把 `scopeEnd` 填成别的猜测值 ⇒ 那是**编造**，同纪律 22 "缺列不许补列"）。② **`closeIndex` 的配对规则本身是"未验证的选择"**（生成物 `:107-112`）⇒ 让 min 也吃它，会把一条**未验证规则**扩散到第二个站点。③ 该不对称在**今天所有臂读数上不可观测**（TDT2 Claim 2 已证五臂都不消费 `minWidth`；我另加：`handoff.md:1923` 的活体读数 `minmaxCalls=0`）⇒ 改动**无回归风险也无收益**，只能靠新造用例判。
> **⇒ 一句话建议**：**按 R1 落（改一处）＋登记 R2（`D-T2-c`：两探针共用一把已知错的尺子）**。"max 也要改"**在能取到覆盖终点之前不可落地**，因此今天应写成**在册项**而不是本件修法。

### 2.3 `TryMinMaxParagraphWidth` 从应用路径到底可不可达（精确表述）

三层入口都**存在且 public**：`TextFormatter.FormatMinMaxParagraphWidth`（生成物 `:605`/`:629`，`public override`）。链（逐字）：
```
636:            // prepare formatting settings
637:            FormatSettings settings = PrepareFormatSettings(
...
649:            // WPF-on-Linux（T1b/D3）：先试**托管路径**（宽=∞ 取最长行 ⇒ MaxWidth；宽=0 强制断 ⇒ MinWidth）。
651:            double hbMinWidth, hbMaxWidth;
652:            if (WpfLinux.Shims.PresentationCore.HbTextFallback.TryMinMaxParagraphWidth(
653:                    textSource,
654:                    textSource.PixelsPerDip,
655:                    out hbMinWidth,
656:                    out hbMaxWidth
657:                    ))
...
663:            double lenientMin, lenientMax;
664:            if (WpfLinuxLenientTextFallback.TryMinMaxParagraphWidth(textSource, textSource.PixelsPerDip,
665:                    out lenientMin, out lenientMax))
...
671:            TextMetrics.FullTextLine line = new TextMetrics.FullTextLine(
```
**精确可达性（四条，缺一不可）**：
1. **必须有调用者**。本仓唯一的 in-repo 消费者 = `FormattedText.MinWidth`（上游 `FormattedText.cs:1510-1526`，`:1520` 调 `FormatMinMaxParagraphWidth`）；`TextBlock`/`PresentationFramework` 不消费（TDT2 §3.2⑤）。**活体读数**：`handoff.md:1923` `minmaxCalls=0` ⇒ **应用今天不调**。⇒ **"可达"是 API 面的事实，"被走到"今天为否。**
2. **tier 判定**：先 `:652` 严格 shim，**它只接受 `TextCharacters` + `TextEndOfLine`**（`shim:4442-4456`：`:4455 Bail(ref BailRunType, "run 类型 " + run.GetType().Name + " 不支持")`）⇒ 段落里含 `TextModifier`（或任何非 `TextCharacters` run）**必然 bail** ⇒ 控制流落到 **`:664` 宽松层** ⇒ **`:309` 那处不对称是活代码**。
3. **反例（不可达分支）**：`WPF_LINUX_TEXTLINE=0` 或 `…_FALLBACK=0` ⇒ 严格层 `shim:4577` 直接 `return false` ⇒ 同样落到 `:664`。**⇒ 关掉严格层不会关掉这条链，只会让它更靠近 `:309`。**
4. **落到 `:671` 的后果（量级说明，不是本节判决）**：Linux 上无 LS ⇒ 那条路是 `abort(134)` 家族（生成物头注 `:7-9`）。
⇒ **可达性判决**：`:309` 的不对称在"**有调用者 ∧ 段落含非 `TextCharacters` run（或严格开关被关）**"时可达；第二个条件今天**无法由任何既有臂产生**（TDT2 已证 13 宿主 0 命中，我用同一 pattern + 正对照复核，见 §4 注），所以它今天**不可观测**，但**不是死代码**。

---

## 3. 新臂：可落地规格（**不落地**，供 P2 车道照做）

### 3.1 放哪、叫什么

| 项 | 规格 |
|---|---|
| **形式** | **在既有 `CoverageProbe` 里加一个新模式**（`--pc-lines-oracle <json>`），**不新开工程**。理由：IVT 身份（`AssemblyName=PresentationCore.Tests` + `WcpPublicKey.snk`）已就位 ⇒ **可直接读 PC 内部计数器做正控**；`--known-red` 的 rc 纪律、oracle 读取、字体设置（`CoverageProbe.csproj`/`Program.cs:1282-1285`：`/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf` + `MakeTypeface("Liberation Sans")`）全部现成。 |
| 探针文件 | `build/MilBridge/tests/CoverageProbe/Program.cs`（`a8727a5bed6bf049`）——**新增一个 `RunPcLinesOracle(string path, string knownRedPath)` + 两条 CLI 分支**（`Program.cs:114-142` 的解析/分发模式照抄；新分支插在 `:140` 附近）。**不许改任何既有模式**（纪律 34 的越界即停）。 |
| CLI | `--pc-lines-oracle <json>`（与 `:127` 的 `--tab-lines-oracle` 平行）、复用 `--known-red`（`:128`）。 |
| 纪律 34 附带义务 | 改探针 ⇒ **必须重取三支 tab 臂 + 重钉 `known-red.json` 的 `generation`**，并在 `changelog` 记探针新 sha（README `:22-27`）。 |
| 不做的事 | **不改 shim、不改 pc、不动五臂既有分支**；新臂**不进五臂门禁**（P2 只要求它可判红，门禁接线属另一件）。 |

### 3.2 臂里要写什么（逐件，含"为什么"）

1. **两个宿主子类**（都能用 public API，不需要 IVT）：
   - `TextParagraphProperties` 子类：**照抄** `tests/parity/windows/tab-anchor/src/Program.cs:642-663` 的 `Para`，喂 oracle 的 `indentDip`（→ `Indent`）、`paragraphIndentDip`（→ `ParagraphIndent`）、`firstLineInParagraph`、`flowDirection`、`TextWrapping.Wrap`（oracle **436/436** 都是 `"Wrap"`）、`LineHeight = 0`、`DefaultIncrementalTab = arm0 ? 0 : base.DefaultIncrementalTab`（`arm0` 判据照 `:1306`）。
   - `TextSource` 子类：照 `CoverageProbe` 现有 `MockTextSource` 的姿势（`Program.cs:43-79`），run 序列 = `new TextCharacters(text, 0, text.Length, runProps)` → `new TextEndOfParagraph(1)`。
2. **驱动（严格按客户端姿势）**：`TextFormatter tf = TextFormatter.Create();`（public）→ 循环 `tf.FormatLine(source, cp, paragraphWidthDip, pap, previousLineBreak)`，`previousLineBreak = line.GetTextLineBreak()`，`cp += line.Length`，直到覆盖段落（**行数也要比**：`lines.Count` vs `oracle.lines` 数组长）。第二行起传非 null 的 `previousLineBreak`（这一点同时**顺带**让后续行必走托管层）。
3. **两条腿（必须都记录，且分别标注口径）**：
   - **腿 A（保真，`AlwaysCollapsible = false`，与 oracle 一致）**：非 0 缩进例必然走托管层（`SimpleTextLine.Linux.cs:207-208` 闸门）；**零缩进例的首行会被 `SimpleTextLine` 接走** ⇒ 腿 A 的对照半边**不是同层对照**，必须在输出里点名（纪律 18/22：口径写清）。
   - **腿 B（同层对照，`AlwaysCollapsible = true`）**：`:210 pap.AlwaysCollapsible` ⇒ 快路径必 `return null` ⇒ **全部 436 例都走托管层** ⇒ **104 条零缩进例成为真正的同层阴性对照**。**必须显式印"本腿偏离 oracle 的 `AlwaysCollapsible=false`"**（不假装同口径）。
4. **必须显式把被测代码赶到 P2 要修的那一层**（§1.2 F1）：臂**自己**在进程内 `Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE_FALLBACK", "0")` **并**在输出头行逐字打印该开关的值与理由。**不许**默认配置下就宣称"在测 P2 那段"。
5. **正控（防假绿，纪律 3/27）**：每例或每 N 例读一次 `WpfLinuxLenientTextFallback.Diagnostics`（IVT），断言 **`relaxedCalls > 0` ∧ `relaxedHandled > 0`**；若为 0 ⇒ **`NOINFO` + rc=2**（"被测代码没被走到" ≠ "通过"）。腿 A 里抓到的 `SimpleTextLine` 首行也**计数并打印**（"多少例的首行没进托管层"）。
6. **比什么（与 `RunTabLinesOracle` 同一把尺子，容差 0.05）**：行数（`lines.Count`）、逐行 `Width`（vs `lines[].width`）、逐行 `TrailingWhitespaceLength`/`NewlineLength`（vs 同名键）、逐字符 `line.GetTextBounds(i,1)[0].TextRunBounds[0].Rectangle.X`（vs `perChar[].xFromLeftDip`，`CoverageProbe:1422-1430` 已实测该口径）、且 **bidi 重排例跳过位置面只比结构面**（`:1332-1346` 的现成判据）。**覆盖闸**照旧：`script ∈ {hebrew, arabic}` ⇒ `跳过=面缺字形`（预计 **148** 例）。
7. **rc 纪律**：`未登记失败 ⇒ rc=1`；登记过的仍红 ⇒ 只点名不改 rc；**缺数据 ⇒ NOINFO 非 0**。照 `:1481-1493` 的既有实现。
8. **不做 min/max**（那是 P3 的牙；本臂只管 `FormatLine`）。

### 3.3 精确命令与两极性期望

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 1) 先建（纪律 33：改"会被编进产物"的源必须编译验证；探针是仪器，也要 0 错）
dotnet build -c Release build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj      # 期望 error CS = 0
# 2) 跑（腿 A 用默认 AlwaysCollapsible=false；腿 B 由臂内的 --always-collapsible 开关切）
( cd build/MilBridge/tests/CoverageProbe/bin/Release && \
  dotnet PresentationCore.Tests.dll --pc-lines-oracle \
    /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json \
    --known-red /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/known-red.json; echo "rc=$?" )
```

| 极性 | 期望（腿 B 口径；腿 A 只差"零缩进首行进不进托管层"的计数） |
|---|---|
| **修前（今天 `pc c0763fc10173e7ff`）** | `判定过 ≈ 104`、**`败 ≈ 184`**、`不可比(缺字形)=148`、**`rc=1`**；例 A/B/C 的差**逐位 = §1.4 预测**；`relaxedHandled > 0`（正控过） |
| **修后（P2 落地 + DIP 转换，见 §1.2 F2）** | 184 条转绿、**104 条零缩进例逐位不动**、`rc=0`（± 已登记保留红） |
| **坏修法（P2 直传 `settings.Pap.*`）** | 184 条**仍红**，`i0p24` 那类差 ≈ **+7200** ⇒ **这条臂能把 F2 抓成红** |
| **臂坏了的形态（必须区分）** | 零缩进 104 条也红 ⇒ **臂/字体/层选错**，按纪律 27 判 `NOINFO`，**不许当达成** |

---

## 4. 读数表（lane=R17A，全部现场 `sha256sum` + `stat`）

**环境**：`uname -r = 6.8.0-138-generic`｜入口 `2026-09-15 23:20:48 +0800`，`loadavg = 0.49 0.31 0.17`，`mem_available = 4088 MB`（`free -m`：total 7923 / used 3440 / free 1432 / swap used 866）｜收尾 `2026-09-15 23:28:13 +0800`，`loadavg = 0.66 1.00 0.63`，`mem_available = 3687 MB`（used 3752 / free 181）。**两趟之间本条车道没有跑任何仪器/构建**（只有 `read`/`grep`/`sha256sum`/`stat`/`python3` 读 JSON）⇒ 本报告**不含任何性能/并发类结论**（纪律 2/8）。

| 文件 | `sha256` 前 16 | 字节 | mtime |
|---|---|---|---|
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（**主对象**：宽松两层 + min/max 探针） | `f86198dfdd349332` | 51,594 | 2026-09-15 17:10:55 |
| `build/shims/PresentationCore.HbTextLine.cs`（`FormatParagraph` / `BreakParagraph` / 严格层 / 计数器） | `bc04c05ab6d8d82a` | 275,765 | 2026-09-15 18:25:25 |
| `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`（应用器；生成物 L ↔ 应用器 L−143） | `07dc7627f609e031` | 37,625 | 2026-09-15 17:10:55 |
| `build/PresentationCore.Linux/PresentationCore.Linux.csproj`（`:1611` 定义 `TEXTLINE_SHIM_DIRECT`） | `e2558faa0cc6b5d1` | 205,471 | 2026-09-15 18:37:23 |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`（**权威 `pc`**；跑前跑后各读一次，逐位相同） | `c0763fc10173e7ff` | 4,194,816 | 2026-09-15 18:38:14 |
| `build/PresentationCore.Linux/SimpleTextLine.Linux.cs`（快路径闸门 `:203-216`） | `5f729e403fc6c7b1` | 82,727 | 2026-09-11 19:28:54 |
| `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`（**真值源**，436 例） | `a31a813114256faf` | 1,251,441 | 2026-09-14 19:33:26 |
| `tests/parity/windows/tab-anchor/src/Program.cs`（oracle 宿主；`Para` `:642-663`） | `e6651272200f7fb6` | 40,998 | 2026-09-14 19:26:52 |
| `build/MilBridge/tests/CoverageProbe/Program.cs`（三支 tab 臂仪器；`:1258-1527` `RunTabLinesOracle`） | `a8727a5bed6bf049` | 108,127 | 2026-09-15 17:24:40 |
| `build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj`（IVT 身份 + 内联 shim 源；`:25`/`:34-36`/`:42`/`:47`） | `ca59c52fb12a050c` | 4,574 | 2026-09-11 18:55:31 |
| `build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll`（探针产物，**未运行**） | `a31f551c834b10d9` | 137,728 | 2026-09-15 18:46:53 |
| `build/MilBridge/arm-logs/tab-anchor.log`（`#16` 全绿那趟；`判定过 288/288`、`不可比 148`） | `99d72b385fe23a90` | 43,563 | 2026-09-15 18:49:12 |
| `build/MilBridge/arm-logs/tline.log`（**注意 `#16` 重取后 sha 已变**，TDT2 表里是 `ad07ead4022539d2`） | `89ad10ac614b4d3b` | 21,501 | 2026-09-15 18:52:42 |
| `build/MilBridge/arm-logs/README.md`（五臂配方 / 硬链接约定 / 纪律 34 义务） | `6924605fab87660e` | 6,880 | 2026-09-15 16:52:15 |
| `build/MilBridge/known-red.json`（`generation=#16`、entries 4） | `f9843bde351029dc` | 28,734 | 2026-09-15 18:53:40 |
| `build/MilBridge/tools/tline-gate.sh` | `b37a5c9f55ae71a4` | 40,181 | 2026-09-15 16:44:01 |
| `verify-all.sh` | `a68823631e8f8919` | 9,847 | 2026-09-15 16:44:49 |
| `handoff.md`（`:1923` 活体 `fallbackCalls=1 fallbackHandled=1 … minmaxCalls=0`） | `91513fd82f28f7f7` | 885,691 | 2026-09-15 19:22:12 |
| `docs/CURRENT-STATE.md`（§4 缺陷表、§5 纪律 37 条） | `5f098102a7e239ce` | 144,199 | 2026-09-15 23:19:48 |
| `docs/WAVE17-PREREGISTRATION.md`（**本波预登记**） | `8c36cedb891a263d` | 13,522 | 2026-09-15 23:20:22 |
| `build/MilBridge/TDT2-boundary-report.md`（上一车道；sha16 与派单一致） | `6388461b4ecd0de7` | 53,018 | 2026-09-15 18:51:22 |
| **真机 reference（上游，只读）** | | | |
| `upstream/…/MS/internal/TextFormatting/TextProperties.cs`（`ParaProp`；`:39-40`/`:82`/`:87`） | `b0b0fbfa9b0a6747` | 12,436 | 2026-08-31 09:35:23 |
| `upstream/…/MS/internal/TextFormatting/LineServices.cs`（`Constants.DefaultRealToIdeal = 28800.0/96`） | `8b2bc2167f5c0bd3` | 67,936 | 2026-08-31 09:35:23 |
| `upstream/…/textformatting/TextParagraphProperties.cs`（`:95` `Indent` abstract、`:102-105` `ParagraphIndent` virtual=0） | `d8553b9face9860b` | 3,794 | 2026-08-31 09:35:23 |
| `upstream/…/textformatting/TextFormatter.cs`（`:33`/`:41`/`:56`/`:178`/`:200`/`:272`/`:288`） | `d958522532c01e48` | 14,874 | 2026-08-31 09:35:23 |
| `upstream/…/Media/FormattedText.cs`（`:227-236` indent=0；`:1705` `Debug.Assert`；`:1520` `MinWidth` 消费者） | `424f02137f498441` | 82,853 | 2026-08-31 09:35:23 |
| `upstream/…/MS/internal/TextFormatting/GenericTextProperties.cs`（`:221` 类；`:236-245` 构造器末参 `indent`；无 `ParagraphIndent` override） | `3b22a453946510c1` | 13,549 | 2026-08-31 09:35:23 |
| `upstream/…/MS/internal/TextFormatting/FormatSettings.cs`（`:110` `Pap`；`:139`/`:144`/`:169`） | `7f158048978f82b7` | 9,461 | 2026-08-31 09:35:23 |
| `upstream/…/PresentationCore/OtherAssemblyAttrs.cs`（**`:19` IVT → `PresentationCore.Tests`**） | `47ce32266710f648` | 7,249 | 2026-08-31 09:35:23 |
| `build/keys/WcpPublicKey.snk`（IVT 借用的公钥） | `6fe03f0bbe162b4b` | 160 | 2026-09-10 14:09:03 |

**注 1（纪律 25 正对照：我的"0 命中"都要有同 pattern 的非 0）**
- 生成物 `indentDip` = **1**（`:256`）｜**同文件同 pattern 家族 `modifierOpenIndex` = 6** ⇒ "只此一处"是真 0 邻域，不是坏 pattern。
- **13 支臂宿主**（`find build/MilBridge/tests -maxdepth 2 -name Program.cs`）对 pattern `TextFormatter\.Create|FormatMinMaxParagraphWidth|TryMinMaxParagraphWidth` = **全 0**；**同一批文件**对 pattern `FormatParagraph` = `CoverageProbe 9 / HbTextLineParity 5 / T2eLineHeight 1 / TextLineProto 2`（其余 0）⇒ **"没有任何臂驱动 PC 的 `TextFormatter`"是实测的 0，不是 pattern 失灵**（TDT2 Claim 2 复核成立）。
- `grep -a -c 'PresentationCore.Tests' build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` = **1** ⇒ IVT 真的在产物里。
- `script == latin` 计数 = **288**，与 `tab-anchor.log` 自报 `不可比(缺字形)=148`（436−148=288）**逐位吻合** ⇒ 我的键位口径与臂的覆盖闸同源。

**注 2（我改了/没改什么）**：只新建本文件（**自指 sha 不可能自洽 ⇒ 本文件不写自身 sha16**；最终值 `934da24ad2d5ca38`/66,348 B 记在交付消息与 `$HOME/wfp-runs/w17-laneR17A/README.md` 里，落盘后未再改）；scratch 目录 `$HOME/wfp-runs/w17-laneR17A/`：`README.md 4f6b0a99a36bd2c2`、`count-indent.py 8b06618de86e9b2c`、`twin-delta.py 1ecb71a49a02c7d9`、`closed-form.py 6ed2dc220089e714`（三个脚本我都**跑过**，输出与本报告的数字一致；只读 oracle JSON）。**未运行**任何构建/仪器/门禁；`pc c0763fc10173e7ff`、生成物 `f86198dfdd349332`、应用器 `07dc7627f609e031`、shim `bc04c05ab6d8d82a` 前后逐位相同。

---

## 5. 我**没能**判定的，以及什么仪器能定它

| # | 判不了的东西 | 为什么今天判不了 | 需要什么 |
|---|---|---|---|
| 1 | **新臂修前的逐例实际读数**（例 A/B/C 的 `26.693333`/`0.0` 是**推导值**，不是实测） | 铁律：本机在跑独占静树实验 ⇒ 我不许构建/运行；且新臂**今天还不存在** | 新臂落地后跑一次（§3.3 命令）；**这是把"孪生恒等式"从推理升格为读数的唯一途径** |
| 2 | **88 条 `PI ≠ 0` 例的逐行数值** | L 层递下去的是 `300·PI`（7200/14400）⇒ 断行决定被改写，行划分是控制流结果，静态算不出 | 同上（跑臂）；**不许**用模型数顶替 |
| 3 | **`min > max` 修前是否真出现**（TDT2 §2.5 / P3 红证） | 需要真跑 `FormatMinMaxParagraphWidth` 且构造"`TextModifier` 在段首 + 无 `TextEndOfSegment`"的 `TextSource`；本机不许跑 | P3 的两极牙（`min/max` 臂）＋牙 B（删 `:305` 的两个实参 ⇒ 构造例必须从 `min>max` 变 `min=max`） |
| 4 | **`[open, 段末)` 在 PC 这条路上到底错多少** | 需要"覆盖终点 ≠ 段末"的 `TextSource`，而 PC 的 `CollectLenient`（`:101-103`）**今天收不到这个量** ⇒ **连输入都表达不出来** | 先给 `CollectLenient` 加 `modifierScopeEnd`（shim/生成物两侧），再按 `cases.json` 的 `modifierEnd` 造例 |
| 5 | **`settings.Pap.LineHeight` 的 ×300 是否已在某条读数上现形**（§1.2 F2 的同族） | 语料/应用 `LineHeight = 0` ⇒ 惰性；要现形得构造 `LineHeight > 0` 的用例 | 一条 `LineHeight=30 DIP` 的最小用例 + 新臂（或 `T2eLineHeight` 探针） |
| 6 | **严格层丢掉 Indent/PI 的应用可见后果**（§1.2 F1） | 需要"应用真的设了 `Indent`/`ParagraphIndent`"的用例 —— `WpfTextDemo` 是否设**我没测**（`WAVE17-PREREGISTRATION.md::36` 也把这条列为"前提必须先实测"） | `WpfTextDemo` 的 `TextBlock`/段落属性 dump（一次构建+跑，属 P2 车道的前置） |

**总口径（不许读成绿）**：本报告里 **proven（代码级，逐字可复算）** = §1.1 入口/可见性、§1.2 三条发现（F1/F2/F3）、§1.3 计数与键位、§2.1/2.2/2.3 的全部代码事实。**predicted（未测）** = §1.4 的所有数值、§3.3 的所有期望读数。**not measurable with what we have** = 本表 1–6。

// W17A · **PC `TextFormatter` 路径的逐行 oracle 臂**
// =====================================================================================
//   dotnet PresentationCore.Tests.dll --pc-lines-oracle <oracle.json> [--known-red <json>]
//                                    [--leg a|b|both] [--case <id>] [--tier auto|strict|lenient]…
//                                    [--guard off|label|enforce] [--guard-conv abs|line]
//
// 【W20A（`#20` 波 §1 = `D-T6` 定性）加了什么】**只加**一条**能变红的守卫** + 一个诊断开关，
//   既有判据行（`PCLINE CASE/NAMED/TWIN/合计/分桶/最大差/EXIT`）**一个字节不动**：
//   · `--guard label`（**缺省**）= 对每一例失配词含「取不到字符边界」的用例，用**真机 oracle 宿主同款**
//     索引口径（`GetTextBounds(cpFirst+j, 1)`，`tests/parity/windows/tab-anchor/src/Program.cs:512-514`）
//     **只读重读**，逐例印 `PCLINE GUARD …`（贴「装置限制（读法口径）」标签）；
//     腿尾印一行 `装置限制(读法口径) 判定=…`。**rc 口径不变**（该腿原来 rc=1 仍 rc=1）。
//   · `--guard off` = 连这些新行都不印 ⇒ 输出**逐字节**等于 W20A 之前的基线（本波已实测）。
//   · `--guard enforce` = 再加机器强制：标签前提不成立（重读仍取不到边界 / |Δ|>容差 / 拿不到行对象）
//     ⇒ `PCLINE_EXIT=GUARD_FAIL rc=3`；**一例家族例都没有** ⇒ `NOINFO rc=2`（没输入 ≠ 通过）。
//   · `--guard-conv line` = **故意用错的口径**：守卫的红极性控制（必须失败）。
//   ⇒ 归类依据与机制见 `GuardCase` 的文档注释；完整证据见 `build/MilBridge/W20A-report.md`。
//
// 【W19B（`#19` 波 §0.1 B）加了什么】**只加** tier 选择器 + **层级来源自证**，一个既有判据都没动：
//   · `--tier lenient` = 今天的行为（进程内把 `WPF_LINUX_TEXTLINE_FALLBACK` 置 0 ⇒ 必落宽松档）；
//   · `--tier strict`  = 把该 env **清掉** ⇒ PC 先走**严格档** `HbTextFallback.TryFormatLine`
//                        （生成物 `TextFormatterImp.Linux.cs:565`）—— 这才是**产品默认**那一层；
//   · `--tier auto`（**缺省**）= 尊重调用方环境；环境里没给 ⇒ 沿用今天的行为（宽松档）。
//   ⇒ 本臂**自己**会把 env 置 0，所以"把 env 去掉"在旧版臂上做不到；严格档腿**必须**用 `--tier strict`。
//   · 层级来源 = 印**严格档**的 `HbTextFallback` 计数（IVT：`Calls/Handled/Bailed/BailNoSwitch/…/LastBail`）
//     **与**宽松档的 `WpfLinuxLenientTextFallback.Diagnostics`，并**逐例**归因"这一例是谁接手的"。
//   · 正控随之改为**档位感知**：某例两档 `Handled` 增量**都为 0** ⇒ `NOINFO rc=2`（不许报绿）；
//     `--tier strict` 而**严格档一例都没接住** ⇒ `NOINFO rc=2`（"这条路对我不可观测"，不是绿）。
//
// 【W21A（`#21` 波 §1 P1 = `D-T6-c`）加了什么】**只新增一列比较**，既有任何列/分桶/汇总的口径
//   **一个字节不动**（本波只许加强红判据，不许放松）：
//   · **新列 = 逐行 `R(我方 line.Start)` vs 语料 `lineStartOffsetsDip[k]`**，`R(v) = Math.Round(v, 6,
//     MidpointRounding.AwayFromZero)`（口径出处 `tests/parity/windows/tab-anchor/src/Program.cs:583`）。
//     被测法律（`#21` §1.1 三条独立腿）= **`TextLine.Start == TextParagraphProperties.ParagraphIndent`**（DIP）。
//   · **断言边界**：**只对 `TextAlignment=Left` 断言**。本语料**头**把对齐**钉死**
//     （`paragraphProperties.fixed` = "TextAlignment=Left, …"，**不是逐例变量**）⇒ 该串解析不出 `TextAlignment=Left`
//     ⇒ **整列 `NOINFO`**（`rc=2`），**绝不发明** `Right`/`Center` 的公式（本语料零覆盖 = 无真值）。
//     逐例若出现 `textAlignment` 字段且非 Left ⇒ 该例 `NOINFO`（只排除该例，不算红也不算绿）。
//   · **覆盖方向**：`flowDirection` 是**逐例变量**（LTR 318 / RTL 118）⇒ 本列**两个方向都断言**。
//     ⚠️ 与既有「逐字符 x」列**不同**：那一列对 bidi 重排例跳过（`reordered`），而 `Start` 是
//     **段落帧**量、与行内字符重排无关 ⇒ 本列**不跳 bidi 例**。这是有意的口径差异，不是遗漏。
//   · **判据 = 精确相等**（`R(我方) == 真值`）。理由：两边是**同一个物理量的同一个取整口径**，
//     且真法律是**恒等式**（不是近似）⇒ 用 `Tol=0.05` 会让"差 0.04"读成绿。另印最大 |Δ| 供人核。
//   · **逐例可归因**：每一处失配印 `PCLINE START <id> 行#k 我方=… 真值=… Δ=…`。
//   · **线级记账**（本波的头条读数）：`615 行 = 红 171 + 绿 444`（修前）⇒ 单开一行 `PCLINE LEG=… Start 逐行`。
//     为什么必须有线级：修前那些 `PI≠0` 的例**多数已经因为别的列红了** ⇒ 只看用例级分桶，
//     一个**零判别力**的新判据会**完全隐形**。线级计数就是这条判据的红证读数。
//   · **已知会让一条旧契约失效**：W20A 的"`--guard off` ⇒ 输出与 W20A 之前逐字节相同"**不再成立**
//     （本列与 `--guard` **无关**、无条件打印）。这是加列的必然代价，**如实记在报告里**，不改 `--guard` 语义。
//
// 【它回答的问题（`WAVE17-PREREGISTRATION.md` §1 P2 的红证）】
//   PC 的**宽松兜底**把 `settings.Pap.ParagraphIndent`（= `RealToIdeal(PI)` = **300·PI**）
//   递进了 `indentDip` 槽，而 `Pap.Indent` **从不被传**（生成物 `TextFormatterImp.Linux.cs:575`
//   → `:230` 形参 → `:256` 透传）⇒ 凡非 0 缩进用例，行宽/网格锚与 oracle 真值必然对不上。
//
// 【为什么必须**新臂**】今天没有任何臂驱动 PC 的 `TextFormatter`：三支已注册 tab 臂直接调
//   `HbTextLineFactory.FormatParagraph`（**工厂**）；而 P2 要修的接线点**在 PC 与工厂之间**。
//
// 【它**不**回答什么（诚实清单）】——**(W19B 更正)**：第 ① 条原写"严格档不在本臂射程内"，
//   那是 **W17A 当时**的事实（旧版臂把 `WPF_LINUX_TEXTLINE_FALLBACK` **写死**置 0）
//   ⇒ **W17A/W17B 的读数对严格档零射程**这句仍然成立；**但本臂现在有严格档腿**（`--tier strict`，W19B 加）。
//   · 严格档（`HbTextFallback.TryFormatLine`，`#19` 修前 shim `:4496-4497`）**根本没有缩进入参** ⇒ `Indent`/`PI`
//     在**产品默认**路径上被整条丢掉（`R17A-recon.md` §1.2 F1）。`--tier strict` 量的正是这一层；
//     宽松档腿（`--tier lenient` = W17A 的行为）量的只是 `#17` P2 修过的那一层。
//   · 88 条 `PI≠0` 例的**逐行数值**不可从语料静态推出（`300·PI` = 7200/14400 会改写断点划分）
//     ⇒ 本臂只**量**它们、不预言论它们（纪律 22：量不出来就报 `NA(source=…)`）。
//   · 本臂**不**是五臂门禁成员，**不**进 `verify-all`（P2 只要求它可判红）。
//
// 【仪器会不会撒谎（自检）】
//   · **正控（W19B 起档位感知）**：某例必须由**某一档**接住 —— 驱动前后该档 `Handled` 增量 > 0；
//     两档增量都为 0 ⇒ `NOINFO` + `rc=2`（"哪一层接手的不可判定" ≠ "通过"）。
//     `--tier strict` 而严格档**一例都没接住** ⇒ `NOINFO` + `rc=2`（这条路不可观测，不许报绿）。
//   · **层级自证**：印 `WPF_LINUX_TEXTLINE_FALLBACK` 的**实际值**、产品侧开关 `HbTextFallback.Enabled`、
//     以及**逐例归因**（严格档接手 N 例 / 宽松档接手 M 例 / 非生效档接手 K 例，K>0 逐条点名）。
//   · **零缩进阴性对照**：`Indent=0 ∧ PI=0` 的拉丁例今天**必须 PASS**；若它们今天也红
//     ⇒ 臂/字体/层选错 ⇒ 按纪律 27 判 `NOINFO`，**不许当达成**。
//   · **孪生恒等式**：`PI=0` 时两层喂下去的缩进全为 0 ⇒ 我方读数**必须等于 oracle 自己的
//     `@i0` 孪生例实测值**。本臂对每个有 `@i0` 孪生的例打印 `TWIN` 行，把"预言"降级为**读数**。
// =====================================================================================

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace MilBridge.PcLineOracle
{
    /// <summary>假 TextSource：单 run `TextCharacters` → `TextEndOfParagraph`（照 oracle 宿主 `StringSource`）。</summary>
    internal sealed class MockTextSource : TextSource
    {
        private readonly TextRunProperties _props;
        internal MockTextSource(string text, TextRunProperties props) { Text = text; _props = props; }
        internal string Text { get; }
        /// <summary>⚠️ **每次调用都新建** `TextCharacters(Text, cp, Text.Length - cp, props)`
        /// —— 与 oracle 宿主 `StringSource`（`tab-anchor/src/Program.cs:614`）逐字同形。
        /// 第一版**复用**一个 `TextCharacters(text, 0, text.Length, props)` 实例：
        /// 于是 `GetTextRun(cp)` 返回的 run 覆盖 `[cp, cp+len)`，而 `CharacterBufferReference.OffsetToFirstChar`
        /// 恒为 0 ⇒ `ExtractRun` 读到的仍是**段落剩下的全部字符**（不是本行的字符）
        /// ⇒ 第二行起 `Length` 恒 1、`Width` 恒 = 段落宽（实测：4 次调用全 `len=1 w=80.00`）。
        /// 这条是**仪器缺陷**，不是产品缺陷；它污染的是"多行例"，单行例不受影响。</summary>
        public override TextRun GetTextRun(int cp)
            => (cp >= 0 && cp < Text.Length)
                 ? (TextRun)new TextCharacters(Text, cp, Text.Length - cp, _props)
                 : new TextEndOfParagraph(1);
        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
            => new TextSpan<CultureSpecificCharacterBufferRange>(0,
                   new CultureSpecificCharacterBufferRange(CultureInfo.InvariantCulture, CharacterBufferRange.Empty));
        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
    }

    /// <summary>`TextRunProperties` 最小实现（本工程独立，不借 shim 的 internal 类型）。</summary>
    internal sealed class OraRunProperties : TextRunProperties
    {
        private readonly Typeface _tf; private readonly double _em;
        internal OraRunProperties(Typeface tf, double em) { _tf = tf; _em = em; }
        public override Typeface Typeface => _tf;
        public override double FontRenderingEmSize => _em;
        public override double FontHintingEmSize => _em;
        public override CultureInfo CultureInfo => CultureInfo.InvariantCulture;
        /// <summary>⚠️ **必须是 `null`，不能是 `Brushes.Black`**（实测踩到）：
        /// `System.Windows.Media.Brush` 的静态构造要建一个 HwndWrapper ⇒ 无 X 时抛
        /// `TypeInitializationException` ⇒ 整个 `TryFormatLine` 抛 ⇒ 正控看到 `relaxedHandled=0`。
        /// 本臂**只量几何**（行宽 / 逐字符 x），而 shim 的度量面把 foreground 当不透明值搬运、
        /// 从不 deref（shim `:2444` `Brush fallback = _run.Props != null ? _run.Props.ForegroundBrush : null;`
        /// ⇒ `null` 是被显式支持的取值）⇒ 取 `null` 既不改变几何、也不引入 X 依赖。
        /// 因此本臂**不需要 `DISPLAY`**（与三支 tab 臂一致）。</summary>
        public override Brush ForegroundBrush => null;
        public override Brush BackgroundBrush => null;
        public override TextDecorationCollection TextDecorations => null;
        public override TextEffectCollection TextEffects => null;
    }

    /// <summary>oracle 宿主 `Para`（`tests/parity/windows/tab-anchor/src/Program.cs:642-663`）的**同形**副本。
    /// ⚠️ **唯一**偏离 = `AlwaysCollapsible` 由腿决定（腿 B 刻意置 true 以打开同层阴性对照）。</summary>
    internal sealed class OraPara : TextParagraphProperties
    {
        private readonly bool _tabZero, _firstLine, _alwaysCollapsible;
        private readonly double _indent, _paraIndent;
        private readonly FlowDirection _flow;
        private readonly TextRunProperties _props;
        internal OraPara(TextRunProperties props, FlowDirection flow, bool tabZero,
                         double indent, double paraIndent, bool firstLine, bool alwaysCollapsible)
        {
            _props = props; _flow = flow; _tabZero = tabZero;
            _indent = indent; _paraIndent = paraIndent; _firstLine = firstLine;
            _alwaysCollapsible = alwaysCollapsible;
        }
        public override TextRunProperties DefaultTextRunProperties => _props;
        public override FlowDirection FlowDirection => _flow;
        public override TextAlignment TextAlignment => TextAlignment.Left;
        public override TextWrapping TextWrapping => TextWrapping.Wrap;
        public override double LineHeight => 0;
        public override bool FirstLineInParagraph => _firstLine;
        public override double Indent => _indent;
        public override double ParagraphIndent => _paraIndent;
        public override bool AlwaysCollapsible => _alwaysCollapsible;
        public override TextDecorationCollection TextDecorations => null;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override IList<TextTabProperties> Tabs => null;
        public override double DefaultIncrementalTab => _tabZero ? 0 : base.DefaultIncrementalTab;
    }

    internal static class Program
    {
        private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";
        private const string FallbackEnvVar = "WPF_LINUX_TEXTLINE_FALLBACK";
        private const double Tol = 0.05;

        private const string FontPath = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf";
        private const string FontFamilyName = "Liberation Sans";

        // 预登记 §1 P2 点名的两个判别例（**必须**按名报告）
        private static readonly string[] Named =
        {
            "B-indent/lead-tab-a@w140@LTR@i24@default",
            "B-indent/notab-control@w80@LTR@i24@default",
        };

        private static int s_fail;
        private static int s_red, s_green, s_skipCov, s_bidi, s_noInfo;
        private static string s_twinHits = "", s_twinMiss = "";
        private static string s_twinRows = "", s_namedRows = "", s_structRows = "";
        private static double s_twinWorst; private static string s_twinWorstWhy = "";
        private static int s_twinViol;
        private static readonly SortedDictionary<string, int[]> FamNew = new SortedDictionary<string, int[]>(); // [总,过]
        private static readonly SortedDictionary<string, int[]> FamNz = new SortedDictionary<string, int[]>();  // 非0缩进: [总,过]
        private static int s_nzTotal, s_nzRed, s_nzGreen;
        private static int s_zTotal, s_zRed, s_zGreen;
        private static int s_piNz, s_piNzRed;
        private static double s_worst; private static string s_worstWhy = "";

        // ---- W21A · `#21` §1 P1：`TextLine.Start` 法律（`Start == ParagraphIndent`）的**新增一列** ----
        //  线级（本次判据的头条读数）：判定 = 真的比过的行数；NOINFO = 因为"对齐不是 Left / 真值字段缺"而没比的行数。
        private static int s_stLines, s_stRed, s_stGreen, s_stNoInfo;
        private static int s_stCaseRed, s_stOnlyRed, s_stMissLines, s_stUnreg;
        private static double s_stWorst; private static string s_stWorstWhy = "";
        private static string s_stRows = "";
        private static string s_stCaseRows = "";
        private static string s_stNoInfoRows = "";
        /// <summary>本语料的对齐是否可断言为 `Left`（由语料**头** `paragraphProperties.fixed` 解析）。
        /// false ⇒ 本列**整列 NOINFO**（`rc=2`），绝不发明 `Right`/`Center` 的公式。</summary>
        private static bool s_alignAssertable;
        private static string s_alignWhy = "";

        private static string F(double v) => v.ToString("F6", CultureInfo.InvariantCulture);
        private static string F4(double v) => v.ToString("F4", CultureInfo.InvariantCulture);
        /// <summary>W21A · `#21` §1 P1 的取整口径 —— 逐字照抄真机宿主
        /// `tests/parity/windows/tab-anchor/src/Program.cs:583`（真值侧就是用这个口径落盘的
        /// ⇒ 我方也用它，才是**同一把尺子**）。</summary>
        private static double R6(double v) => Math.Round(v, 6, MidpointRounding.AwayFromZero);

        private static int Main(string[] argv)
        {
            try { Console.OutputEncoding = Encoding.UTF8; } catch (Exception) { }

            string oracle = null, knownRed = null, leg = "both", caseFilter = null, tier = "auto";
            string guard = "label", guardConv = "abs";
            bool noCache = false, dumpRaw = false;
            for (int i = 0; i < argv.Length; ++i)
            {
                if (argv[i] == "--pc-lines-oracle" && i + 1 < argv.Length) oracle = argv[++i];
                else if (argv[i] == "--known-red" && i + 1 < argv.Length) knownRed = argv[++i];
                else if (argv[i] == "--leg" && i + 1 < argv.Length) leg = argv[++i];
                else if (argv[i] == "--case" && i + 1 < argv.Length) caseFilter = argv[++i];
                else if (argv[i] == "--tier" && i + 1 < argv.Length) tier = argv[++i];
                else if (argv[i] == "--guard" && i + 1 < argv.Length) guard = argv[++i];
                else if (argv[i] == "--guard-conv" && i + 1 < argv.Length) guardConv = argv[++i];
                else if (argv[i] == "--no-cache") noCache = true;
                else if (argv[i] == "--dump") dumpRaw = true;
            }
            if (tier != "auto" && tier != "strict" && tier != "lenient")
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=--tier 取值非法：" + tier + "（只接受 auto|strict|lenient）");
                return 2;
            }
            if (guard != "off" && guard != "label" && guard != "enforce")
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=--guard 取值非法：" + guard + "（只接受 off|label|enforce）");
                return 2;
            }
            if (guardConv != "abs" && guardConv != "line")
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=--guard-conv 取值非法：" + guardConv + "（只接受 abs|line）");
                return 2;
            }
            s_tierRequested = tier;
            s_guard = guard;
            s_guardConv = guardConv;
            s_noCache = noCache;
            s_dumpRaw = dumpRaw;

            Console.WriteLine("==================== W17A · PcLineOracle（驱动 PC 的 TextFormatter）====================");
            Console.WriteLine("lane        = W17A（建臂者）");
            Console.WriteLine("lane(edits) = W19B（`#19` 波 §0.1 B：加 `--tier` + 层级来源自证；判据口径未动）");
            // ⚠️ `--guard off` 时**这一行也不印**：目的是让 `--guard off` 的输出与 W20A 之前**逐字节相同**
            //    （已实测：`--guard off` 两腿各自复现 `a4cd321f5699cefc` / `005f07dfeffd11bf`）——
            //    "既有判据行一个字节没动"这句话因此有机器证明，而不是靠人眼比 diff。
            if (s_guard != "off")
                Console.WriteLine("lane(edits) = W20A（`#20` 波 §1 `D-T6`：加 `--guard`（缺省 label）+ `--guard-conv`；"
                                  + "**只加行**，既有判据行口径未动；`--guard off` 可退回 W20A 之前的逐字节基线）");
            //  ⚠️ W21A 这一行**不**随 `--guard off` 消失：本波加的是**判据**（不是守卫），无条件生效 ⇒
            //     W20A 的"`--guard off` ⇒ 与 W20A 之前逐字节相同"这条旧契约**自本波起失效**（如实记录）。
            Console.WriteLine("lane(edits) = W21A（`#21` 波 §1 P1 `D-T6-c`：**只新增一列**比较 = 逐行 `R(line.Start)` vs "
                              + "语料 `lineStartOffsetsDip[k]`；既有任何列/分桶/汇总的口径**一个字节未动**）");
            Console.WriteLine("entrypoint  = System.Windows.Media.TextFormatting.TextFormatter.Create() + FormatLine  (public)");
            Console.WriteLine("被测接线点  = 严格档 生成物 TextFormatterImp.Linux.cs:565（产品默认先走这一层）");
            Console.WriteLine("              宽松档 生成物 TextFormatterImp.Linux.cs:575 → WpfLinuxLenientTextFallback.TryFormatLine");

            // ---------- 0) tier 选择：**在拿任何读数之前**先钉死，并**读回产品自己的开关**自证 ----------
            string ambient = Environment.GetEnvironmentVariable(FallbackEnvVar);
            Console.WriteLine("TierSelect  : --tier " + tier + "（缺省 auto = 尊重调用方环境；环境没给 ⇒ 沿用今天的行为=宽松档）");
            Console.WriteLine("TierSelect  : 臂动作**之前**环境里的 " + FallbackEnvVar + " = " + (ambient ?? "<null>"));
            if (tier == "lenient")
            {
                Environment.SetEnvironmentVariable(FallbackEnvVar, "0");
                Console.WriteLine("TierSelect  : 动作 = 置 " + FallbackEnvVar + "=0（**与建臂以来逐字相同**的行为）");
            }
            else if (tier == "strict")
            {
                Environment.SetEnvironmentVariable(FallbackEnvVar, null);
                Console.WriteLine("TierSelect  : 动作 = **清掉** " + FallbackEnvVar
                                  + " ⇒ PC 先走严格档 `HbTextFallback.TryFormatLine`（产品默认那一层）");
            }
            else // auto
            {
                if (ambient == null)
                {
                    Environment.SetEnvironmentVariable(FallbackEnvVar, "0");
                    Console.WriteLine("TierSelect  : 动作 = 环境没给 ⇒ 沿用今天的行为：置 " + FallbackEnvVar + "=0（宽松档）");
                }
                else
                {
                    Console.WriteLine("TierSelect  : 动作 = 不覆盖（按调用方给的值走）");
                }
            }
            string fb = Environment.GetEnvironmentVariable(FallbackEnvVar);
            Console.WriteLine("TierSteer   : 读回 " + FallbackEnvVar + "=" + (fb ?? "<null>"));

            // 档位的**权威判据不是 env**，而是产品自己的开关（IVT 读 internal `HbTextFallback.Enabled`）
            bool strictEnabled; string strictWhy;
            if (!TryStrictEnabled(out strictEnabled, out strictWhy))
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=读不到产品自己的层级开关（IVT: HbTextFallback.Enabled）：" + strictWhy);
                return 2;
            }
            s_effectiveTier = strictEnabled ? "strict" : "lenient";
            Console.WriteLine("TierSteer   : 产品侧 `HbTextFallback.Enabled` = " + (strictEnabled ? "true" : "false")
                              + " ⇒ **生效档 = " + (strictEnabled ? "严格档" : "宽松档") + "**");
            if (tier == "strict" && !strictEnabled)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=要严格档腿，但产品侧开关读出 false ⇒ 转向未生效（不许报绿）");
                return 2;
            }
            if (tier == "lenient" && strictEnabled)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=要宽松档腿，但产品侧开关读出 true ⇒ 转向未生效（不许报绿）");
                return 2;
            }
            Console.WriteLine("TierSteer   : 严格档的缺口（**本波 §0.1 B 的被测件**）= shim `HbTextFallback.TryFormatLine`"
                              + "（`#19` 修前 `:4496-4497`）的形参表里没有 indent ⇒ `Indent`/`ParagraphIndent` 整条丢掉");
            if (s_effectiveTier == "strict")
                Console.WriteLine("TierSteer   : ⚠️ 本趟 = **严格档腿**：下面每腿那行「正控 …」的 relaxedHandled=0 是**预期值、不是失败**；"
                                  + "本腿的有效正控 = 紧随其后的「层级来源」行（严格档 Handled 增量 > 0）");
            else
                Console.WriteLine("TierSteer   : 本趟 = **宽松档腿**（今天的口径）：放宽档诊断即正控；"
                                  + "严格档那条缺口**不在本趟射程**（严格档腿请用 --tier strict）");

            // ---------- 0b) W20A · `D-T6` 守卫（**只加行**；既有判据行一个字节不动） ----------
            //  它管的是一族**读法口径**的红：失配词 = `行#N i=0 取不到字符边界`（严格档腿 67 条非 tab0 + 19 条零缩进）。
            if (s_guard != "off")
            {
            Console.WriteLine("GuardSelect : --guard " + guard + "（缺省 label）+ --guard-conv " + guardConv + "（缺省 abs）");
            Console.WriteLine("GuardSelect : 判据 = 用**真机 oracle 宿主同款读法** `GetTextBounds(cpFirst+j, 1)`"
                              + "（`tests/parity/windows/tab-anchor/src/Program.cs:512-514` 的 `int gi = lineStart + i;`）"
                              + "重读该例：每一行每一个字都要**取到**字符边界、且与真值 |Δ| ≤ " + F(Tol)
                              + " ⇒ 才把这一族标成「装置限制（读法口径）」；否则印 `PCLINE GUARD FAIL`"
                              + "（`--guard enforce` 时 rc=3）。**不改**任何既有 `PCLINE CASE/NAMED/TWIN/合计/分桶/EXIT` 行的口径。");
            }

            if (oracle == null)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=未给 --pc-lines-oracle <json>");
                return 2;
            }
            if (!File.Exists(oracle))
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=语料不存在：" + oracle);
                return 2;
            }

            byte[] raw;
            try { raw = File.ReadAllBytes(oracle); }
            catch (Exception e)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=语料读不出：" + e.GetType().Name + ": " + e.Message);
                return 2;
            }
            string oracleSha;
            using (var sha = SHA256.Create()) oracleSha = Hex(sha.ComputeHash(raw)).Substring(0, 16);
            var fi = new FileInfo(oracle);
            Console.WriteLine("corpus      = " + oracle);
            Console.WriteLine("corpus sha16= " + oracleSha + "  bytes=" + raw.Length
                              + "  mtime=" + fi.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture));

            var kr = KnownRed.Load(knownRed);

            JsonDocument doc;
            try { doc = JsonDocument.Parse(raw); }
            catch (Exception e)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=语料不是合法 JSON：" + e.GetType().Name + ": " + e.Message);
                return 2;
            }

            // ---------- 0c) W21A · `#21` §1 P1：**先把 Start 列能不能断言钉死**（在拿任何读数之前） ----------
            //  真法律 `Start == ParagraphIndent` 只在 `TextAlignment=Left` 下成立（`#21` §1.1 腿① 的 `default:` 分支）。
            //  ⇒ 只有语料**自己声明**了 Left 才断言；声明了 Right/Center 或压根解析不出 ⇒ **NOINFO，不许发明公式**。
            ResolveAlignment(doc.RootElement, out s_alignAssertable, out s_alignWhy);
            Console.WriteLine("StartCol    : 判据 = 逐行 `R(line.Start)` vs 语料 `lineStartOffsetsDip[k]`"
                              + "（`R(v)=Round(v,6,AwayFromZero)`，口径出处 `tests/parity/windows/tab-anchor/src/Program.cs:583`）");
            Console.WriteLine("StartCol    : 断言边界 = **只对 TextAlignment=Left** ｜ 语料声明 = " + s_alignWhy
                              + " ⇒ 本趟" + (s_alignAssertable ? "**可断言**" : "**整列 NOINFO**（rc=2，不许当绿）"));

            // ---------- 1) 字体（**只用 public API**：走 PC 的 FontFamily → TryGetGlyphTypeface） ----------
            Typeface tf = MakeTypeface(FontFamilyName);
            GlyphTypeface gt = null;
            if (tf != null) { try { tf.TryGetGlyphTypeface(out gt); } catch (Exception) { } }
            if (gt == null)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=字体面解析失败（family=" + FontFamilyName
                                  + "，file=" + FontPath + "）⇒ 无被测输入");
                return 2;
            }
            string gtPath = gt.FontUri != null && gt.FontUri.IsFile ? gt.FontUri.LocalPath : "<non-file>";
            IDictionary<int, ushort> cmap = null;
            try { cmap = gt.CharacterToGlyphMap; } catch (Exception) { }
            if (cmap == null || cmap.Count == 0)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=取不到已解析 GlyphTypeface 的 CharacterToGlyphMap"
                                  + "（cmap=" + (cmap == null ? "<null>" : "count=" + cmap.Count + "") + "）"
                                  + " ⇒ 覆盖闸无法判定 ⇒ 不许猜（first version 的 -1 被当成'有字形'，已抓掉）");
                return 2;
            }
            s_cmap = cmap;
            Console.WriteLine("覆盖闸来源  = 已解析面自己的 CharacterToGlyphMap（count=" + cmap.Count + "）"
                              + "；**不用** new GlyphTypeface(new Uri(...)) —— 后者在本机对 .ttf 抛 FileFormatException（实测），"
                              + "第一版把它的 -1 当'有字形' ⇒ 148 例不可比被当成可比（已抓掉）");
            Console.WriteLine("font        = family=" + FontFamilyName + " → " + gtPath + "#" + gt.FaceIndex
                              + "  ⇒ 与三支 tab 臂**同一把尺子**（CoverageProbe `--tab-lines-oracle` 用的是它就是与 Arial 真值 288/288 全绿的那把）");
            if (!File.Exists(gtPath))
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=GlyphTypeface 的 FontUri 不是本机文件：" + gtPath);
                return 2;
            }

            // ---------- 2) 建"孪生"索引：`@i24` 例 ↔ 其 `@i0` 孪生（除 Indent 外逐字段相同） ----------
            var cases = new List<JsonElement>();
            foreach (JsonElement c in doc.RootElement.GetProperty("cases").EnumerateArray()) cases.Add(c);
            var twinOf = new Dictionary<string, JsonElement>(StringComparer.Ordinal);
            var byId = new Dictionary<string, JsonElement>(StringComparer.Ordinal);
            foreach (JsonElement c in cases)
            {
                string id = c.GetProperty("id").GetString();
                if (!byId.ContainsKey(id)) byId[id] = c;
            }
            foreach (JsonElement c in cases)
            {
                string id = c.GetProperty("id").GetString();
                string t = MakeTwinId(id);
                if (t != null && byId.TryGetValue(t, out JsonElement tw)) twinOf[id] = tw;
            }

            // ---------- 3) 计数（**先报分母**，再跑） ----------
            int total = cases.Count, nz = 0, piNz = 0, indentNz = 0, latin = 0;
            var grpNz = new SortedDictionary<string, int>();
            foreach (JsonElement c in cases)
            {
                double ind = c.GetProperty("indentDip").GetDouble();
                double pi = c.GetProperty("paragraphIndentDip").GetDouble();
                if (ind != 0 || pi != 0) { ++nz; string g = c.GetProperty("group").GetString(); grpNz[g] = (grpNz.TryGetValue(g, out int v) ? v : 0) + 1; }
                if (pi != 0) ++piNz;
                if (ind != 0) ++indentNz;
                if (c.GetProperty("script").GetString() == "latin") ++latin;
            }
            Console.WriteLine("corpus 形状 : cases=" + total + "  非0缩进=" + nz + "（indentDip≠0=" + indentNz
                              + "，paragraphIndentDip≠0=" + piNz + "，并集=" + nz + "）");
            var sb = new StringBuilder("corpus 形状 : 非0缩进逐族 ");
            foreach (var kv in grpNz) sb.Append(kv.Key).Append("=").Append(kv.Value).Append(" ");
            Console.WriteLine(sb.ToString());
            Console.WriteLine("corpus 形状 : script=latin=" + latin + "（= 覆盖闸口径；其余 " + (total - latin)
                              + " = hebrew/arabic ⇒ 面缺字形跳过）");

            // ---------- 4) 两条腿 ----------
            var legs = new List<string>();
            if (leg == "both" || leg == "b") legs.Add("B");
            if (leg == "both" || leg == "a") legs.Add("A");

            foreach (string L in legs)
            {
                Console.WriteLine();
                Console.WriteLine("--------------------------------------------------------------");
                if (L == "B")
                {
                    // 腿 B 先跑 ⇒ 所有汇总计数器在此清零，保证"汇总 == 腿 B 一条腿"
                    s_red = 0; s_green = 0; s_skipCov = 0; s_bidi = 0; s_noInfo = 0;
                    s_nzTotal = 0; s_nzRed = 0; s_nzGreen = 0;
                    s_zTotal = 0; s_zRed = 0; s_zGreen = 0; s_piNz = 0; s_piNzRed = 0;
                    s_twinRows = ""; s_namedRows = ""; s_structRows = ""; s_fail = 0; s_worst = 0; s_worstWhy = "";
                    s_twinWorst = 0; s_twinWorstWhy = ""; s_twinViol = 0;
                    s_stLines = 0; s_stRed = 0; s_stGreen = 0; s_stNoInfo = 0;
                    s_stCaseRed = 0; s_stOnlyRed = 0; s_stMissLines = 0; s_stUnreg = 0;
                    s_stWorst = 0; s_stWorstWhy = ""; s_stRows = ""; s_stNoInfoRows = ""; s_stCaseRows = "";
                }
                if (L == "A")
                {
                    Console.WriteLine("LEG=A  保真腿：AlwaysCollapsible=false（与 oracle 同口径）");
                    Console.WriteLine("LEG=A  ⚠️ 口径偏离已在册：零缩进例的**首行**会被上游 `SimpleTextLine` 快路径接走"
                                      + "（SimpleTextLine.Linux.cs:203-216 的闸门：`settings.TextIndent!=0 || pap.ParagraphIndent!=0` 才 return null）"
                                      + "⇒ 本腿的零缩进半边**不是同层对照**。");
                }
                else
                {
                    Console.WriteLine("LEG=B  同层对照腿：AlwaysCollapsible=**true**");
                    Console.WriteLine("LEG=B  ⚠️ **本腿偏离 oracle 的 `AlwaysCollapsible=false`**（不假装同口径）；"
                                      + "换来的东西 = `SimpleTextLine.Linux.cs:210` 的闸门 ⇒ 436 例**不在上游快路径被接走**"
                                      + "（宽松档腿 ⇒ 全部落宽松档；`--tier strict` 腿 ⇒ 先由严格档接手，见「层级来源」行）"
                                      + "⇒ 零缩进例成为真同层阴性对照。");
                }
                bool ac = (L == "B");
                int r = RunLeg(cases, twinOf, kr, tf, gt, ac, L, caseFilter);
                if (r != 0) return r;
            }

            // ---------- 5) 汇总 ----------
            Console.WriteLine();
            Console.WriteLine("==================== PCLINE 汇总 ====================");
            Console.WriteLine("PCLINE 合计 判定红=" + s_red + " 判定绿=" + s_green + " 不可比(缺字形)=" + s_skipCov
                              + " 其中 bidi 重排例=" + s_bidi + " NOINFO例=" + s_noInfo);
            Console.WriteLine("PCLINE 分桶 非0缩进: 红=" + s_nzRed + " 绿=" + s_nzGreen + " /" + s_nzTotal
                              + "；零缩进: 红=" + s_zRed + " 绿=" + s_zGreen + " /" + s_zTotal
                              + "；其中 PI≠0: 红=" + s_piNzRed + " /" + s_piNz);
            // ---- W21A · `#21` §1 P1：`Start` 法律（新列）的**线级**汇总 —— 本波头条（`key=value` 可 grep）----
            Console.WriteLine("PCLINE START 腿=汇总(B) 红=" + s_stRed + " 绿=" + s_stGreen
                              + " 判定行=" + s_stLines + " NOINFO=" + s_stNoInfo
                              + " 红例=" + s_stCaseRed + " Start-only红例=" + s_stOnlyRed
                              + " 未比真值行=" + s_stMissLines
                              + " 未登记失败=" + s_fail + " 其中点名Start列=" + s_stUnreg
                              + " 最大Δ=" + F(s_stWorst) + " @" + (s_stWorst > 0 ? s_stWorstWhy : "-"));
            Console.WriteLine("PCLINE Start列 被测法律 = `TextLine.Start == TextParagraphProperties.ParagraphIndent`（DIP，"
                              + "`TextAlignment=Left`）｜ 真值 = 语料 `lineStartOffsetsDip[k]`＝真机宿主 "
                              + "`tab-anchor/src/Program.cs:445` 的 `R(line.Start)`｜ 断言边界 = **只对 Left**"
                              + "（语料头 `paragraphProperties.fixed` 钉死；Right/Center 本语料零覆盖 ⇒ NOINFO）；"
                              + "`Right`/`Center` 公式**本臂不发明**");
            Console.WriteLine("PCLINE 孪生 有 @i0 孪生的例=" + s_twinHits + "（无孪生=" + s_twinMiss + "）"
                              + "；孪生恒等式违反=" + s_twinViol
                              + "；孪生最大差=" + F4(s_twinWorst) + " @" + s_twinWorstWhy);
            Console.WriteLine("PCLINE 最大差=" + F4(s_worst) + " @" + s_worstWhy);
            Console.WriteLine("PCLINE 正控 **档位感知**（W19B 起）：每例必须由**某一档**接住（驱动前后 `Handled` 增量 > 0）"
                              + "且**逐例归因**（见每腿「层级来源」行）；两档皆 0 ⇒ rc=2 已返回，不会到这里");
            Console.WriteLine("PCLINE 未测清单 : ① 严格档的 indent 缺口**只在本趟生效档 = 严格档时**被量到"
                              + "（宽松档腿上它不在射程；严格档腿 = `--tier strict`）；"
                              + "② 88 条 PI≠0 的**逐行精算值**不可从语料推出（只量不预言）；"
                              + "③ 本臂不是五臂门禁成员、不进 verify-all。");
            // ---- W21A：上面 ② 这条口径**已被 `#21` 推翻**（纪律 22 的反面：这里**有**真值可读）----
            //  该条写于 W17A，当时臂**从未读过**语料的 `lineStartOffsetsDip`（615 个真值）。
            //  **不删旧行**（"只新增"承诺）⇒ 新加一行明确取代它，避免读者按旧口径理解新列。
            Console.WriteLine("PCLINE 未测清单 : ②**已被 `#21` 取代** —— 语料**含** `lineStartOffsetsDip`（逐行真机 "
                              + "`line.Start`，615 个值）⇒ PI≠0 的逐行真值**可从语料读出**，本波新增的 `Start` 列"
                              + "就是在比它（旧口径「不可推出」只在「不读那个字段」的意义上成立）。");

            // ---------- 6) 按名报告的判别例 ----------
            Console.WriteLine();
            Console.WriteLine("==================== 判别例（预登记 §1 P2 点名） ====================");
            if (s_namedRows.Length == 0) Console.WriteLine("PCLINE 判别例 未找到（语料里没有这两个 id）⇒ NOINFO");
            else Console.Write(s_namedRows);
            if (s_structRows.Length != 0)
            {
                Console.WriteLine("---- 其中结构面(行数/行宽/尾部空白/换行长)的差 ----");
                Console.Write(s_structRows);
            }

            // ---------- 7) 孪生逐行（把"预言"降级为"读数"） ----------
            Console.WriteLine();
            Console.WriteLine("==================== 孪生恒等式（PI=0 ⇒ 我方读数必须 == oracle 的 @i0 孪生） ====================");
            if (s_twinRows.Length == 0) Console.WriteLine("PCLINE 孪生 无行");
            else Console.Write(s_twinRows);

            // ---------- 7b) W21A · `#21` §1 P1：`Start` 列的**逐行**失配台账（逐例可归因）+ 未断言例 ----------
            Console.WriteLine();
            Console.WriteLine("==================== `Start` 法律（`#21` §1 P1 新列）逐行 ====================");
            Console.WriteLine("判据 = R(我方 `TextLine.Start`) == 语料 `lineStartOffsetsDip[k]`（R(v)=Round(v,6,AwayFromZero)）"
                              + "；逐例卷起行 `PCLINE START-CASE` 的 红行 数 = 上面 `PCLINE START` 行数（可对账）");
            if (s_stRows.Length == 0) Console.WriteLine("PCLINE START 无失配行（本腿）");
            else Console.Write(s_stRows);
            if (s_stNoInfoRows.Length != 0) Console.Write(s_stNoInfoRows);
            if (s_stCaseRows.Length != 0) Console.Write(s_stCaseRows);

            // ---------- 8) rc ----------
            int unregistered = 0;
            Console.WriteLine();
            Console.WriteLine("PCLINE 登记表=" + (knownRed ?? "<未给>") + " ⇒ 已登记 " + kr.Count + " 条");
            Console.WriteLine("PCLINE 未登记失败=" + s_fail);
            if (knownRed == null)
                Console.WriteLine("PCLINE 未给 --known-red ⇒ 任何失败都算**未登记**（rc=1）");
            unregistered = s_fail;
            int rc = unregistered == 0 ? 0 : 1;
            // ---- W20A · `D-T6` 守卫的机器强制（**只在 `--guard enforce` 时**改写 rc；缺省 `label` 不动） ----
            if (s_guard == "enforce" && s_guardFailed > 0)
            {
                Console.WriteLine("PCLINE_EXIT=GUARD_FAIL rc=3 原因=「取不到字符边界」这一族的**装置限制标签前提不成立**："
                                  + s_guardFailed + " / " + s_guardEvaluated + " 例（用真机同款口径 `GetTextBounds(cpFirst+j,1)` 重读"
                                  + "仍取不到边界 / |Δ|>容差 / 拿不到行对象）⇒ 这些例**不许**读成装置限制，"
                                  + "它们仍是产品红（详见 `PCLINE GUARD FAIL` 行）");
                return 3;
            }
            // ---- W21A · `#21` §1 P1：`Start` 列的**结构性 NOINFO**（规则 21/27/28：缺读数 ⇒ rc≠0，**绝不当绿**）----
            //  ① 一行都没比过 ⇒ 这条判据**没有输入**（对齐不可断言 / 真值字段缺 / 全例被覆盖闸跳过）。
            //  ② 有例**没被断言** ⇒ 判据覆盖面不完整（将来语料真出现 Right/Center 时会走这里，
            //     而不是被静默当成绿）—— 按"宁红不假绿"取 rc=2。
            if (s_stLines == 0)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=`Start` 列**一行都没比过**（判定=0 行）⇒ 这条判据**没有输入**，"
                                  + "不是通过；对齐声明=" + s_alignWhy + "；未断言例=" + s_stNoInfo);
                return 2;
            }
            if (s_stNoInfo > 0)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=`Start` 列有 " + s_stNoInfo + " 例**没被断言**"
                                  + "（对齐非 Left / 真值字段缺 / 真值长度与行数不符）⇒ 覆盖面不完整 ⇒ 不许当绿"
                                  + "（逐例原因见 `PCLINE START-NOINFO` 行）");
                return 2;
            }
            // ---- W21A · `#21` §1 P1：`Start` 列的**未登记红必须进出口码**（主控硬要求 ③）----
            //  口径：本列的失配已经**并进用例级判定**（`oneCase … && startOk`）⇒ 该例进 `failIds`
            //   ⇒ 走既有 `--known-red` 裁定 ⇒ 未登记 ⇒ `s_fail>0` ⇒ 下面这条把它**显式**写出来。
            //  ⚠️ 登记表是 `known-red.txt`（136 条全是 `@tab0` 结构族）—— **本车道无权改它**；
            //     若 `Start` 红需要新的在册条目 ⇒ **如实报"需要主控重钉"**，绝不把未登记红压成 rc=0。
            if (s_stUnreg > 0)
            {
                Console.WriteLine("PCLINE START-RC 汇总 点名Start列的**未登记**红=" + s_stUnreg
                                  + " ⇒ rc 必须非 0（本趟 rc=" + rc + "）；登记表=" + (knownRed ?? "<未给>")
                                  + "，**本车道未改登记表**（重钉归主控）");
                if (rc == 0) rc = 1;
            }
            if (s_stRed > 0 && rc == 0)
            {
                Console.WriteLine("PCLINE START-RC 汇总 本列红=" + s_stRed + " 行且**全部已在册** ⇒ rc 保持 0"
                                  + "（在册机制，不是「洗绿」）");
            }
            Console.WriteLine("PCLINE_EXIT rc=" + rc + "（未登记失败 " + unregistered
                              + " / 红 " + s_red + " / 绿 " + s_green + " / 不可比 " + s_skipCov + "）");
            return rc;
        }

        // ================================================================================
        //  一条腿
        // ================================================================================
        /// <summary>W21A · `#21` §1 P1：这个语料能不能对 `TextLine.Start` 断言？
        /// 真法律 `Start == ParagraphIndent` 只在 `TextAlignment=Left` 下成立
        /// （`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/MS/internal/TextFormatting/TextMetrics.cs:255-263`
        /// 的 `default:`(=Left) 分支 `_paragraphToText = pap.ParagraphIndent + _textStart` ⇒ `Start ≡ IdealToReal(ParagraphIndent)`；
        /// `Right` = `paragraphWidth − _textWidthAtTrailing`、`Center` = `(paragraphWidth + _textStart − _textWidthAtTrailing)/2`
        /// —— 本语料**零覆盖** ⇒ **不许发明**）。
        /// 本语料把对齐**钉死在语料头**（`paragraphProperties.fixed` = "TextAlignment=Left, …"，**不是逐例变量**）
        /// ⇒ 只有那串里明确写着 `TextAlignment=Left` 才断言。
        /// 【两极化】声明 Right/Center ⇒ `ok=false`；头里**没有**该字段、或值解析不出 ⇒ 同样 `ok=false`
        ///   —— **"缺声明" ≠ "是 Left"**（这正是本项目反复栽的"缺读数被当绿"）。</summary>
        private static void ResolveAlignment(JsonElement root, out bool ok, out string why)
        {
            ok = false;
            string fixedDecl = null;
            if (root.ValueKind == JsonValueKind.Object &&
                root.TryGetProperty("paragraphProperties", out JsonElement pp) && pp.ValueKind == JsonValueKind.Object &&
                pp.TryGetProperty("fixed", out JsonElement fx) && fx.ValueKind == JsonValueKind.String)
                fixedDecl = fx.GetString();
            if (fixedDecl == null)
            {
                why = "语料头 `paragraphProperties.fixed` **缺失或不是字符串** ⇒ 对齐不可判定";
                return;
            }
            string d = fixedDecl.Replace(" ", "");
            why = "`paragraphProperties.fixed` = \"" + fixedDecl + "\"";
            if (d.IndexOf("TextAlignment=Left", StringComparison.Ordinal) >= 0) { ok = true; return; }
            if (d.IndexOf("TextAlignment=Right", StringComparison.Ordinal) >= 0 ||
                d.IndexOf("TextAlignment=Center", StringComparison.Ordinal) >= 0)
                why += " ⇒ **非 Left** ⇒ 本列 NOINFO（Right/Center 的公式本语料零覆盖）";
            else
                why += " ⇒ 里面**没有** TextAlignment ⇒ **不可判定**（缺声明 ≠ 是 Left）";
        }

        /// <summary>W21A：逐例对齐覆盖（将来语料可能把对齐变成逐例变量）。语料无该字段 ⇒ 沿用头声明。</summary>
        private static bool CaseAlignmentOk(JsonElement c)
        {
            if (!c.TryGetProperty("textAlignment", out JsonElement ta)) return true;
            if (ta.ValueKind != JsonValueKind.String) return false;
            return string.Equals(ta.GetString(), "Left", StringComparison.Ordinal);
        }

        private static int RunLeg(List<JsonElement> cases, Dictionary<string, JsonElement> twinOf,
                                  KnownRed kr, Typeface tf, GlyphTypeface gt, bool alwaysCollapsible,
                                  string legName, string caseFilter)
        {
            const double em = 24.0;
            var props = new OraRunProperties(tf, em);

            TextFormatter formatter;
            try { formatter = TextFormatter.Create(); }
            catch (Exception e)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=TextFormatter.Create() 抛 " + e.GetType().Name + ": " + e.Message);
                return 2;
            }
            if (formatter == null)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=TextFormatter.Create() 返回 null");
                return 2;
            }

            int total = 0, pass = 0, skipCov = 0, bidiCases = 0, skipNz = 0, skipZ = 0;
            int nzTotal = 0, nzRed = 0, nzGreen = 0;
            int zTotal = 0, zRed = 0, zGreen = 0;
            int piNz = 0, piNzRed = 0;
            int twinHits = 0, twinMiss = 0, twinViol = 0, twinNa = 0;
            double twinWorst = 0; string twinWorstWhy = "";
            var fam = new SortedDictionary<string, int[]>();
            var miss = new Dictionary<char, int>();
            var failIds = new List<string[]>();
            string twinRows = "", namedRows = "", structRows = "";
            // ---- W21A · `#21` §1 P1：`Start` 列的逐行失配台账（只累加，腿尾进全局）----
            string stRows = "";
            string stCaseRows = "";
            int stLines = 0, stRed = 0, stGreen = 0, stCaseNoInfo = 0, stOnlyRed = 0, stMissLines = 0, stCaseRed = 0;
            double stWorst = 0; string stWorstWhy = "";
            int callsBefore = DiagCalls();
            long strictHandledBefore = StrictHandled(), strictCallsBefore = StrictCalls();
            // ---- W19B：层级来源（**逐例**归因）----
            int tStrict = 0, tLenient = 0, tCached = 0, tOffTier = 0, tNone = 0;
            int nzStrictRed = 0, nzStrictGreen = 0, nzLenientRed = 0, nzLenientGreen = 0;
            int zStrictRed = 0, zStrictGreen = 0, zLenientRed = 0, zLenientGreen = 0;
            int piStrictTot = 0, piStrictRed = 0, piLenientTot = 0, piLenientRed = 0;
            string offTierRows = "";
            // ---- W20A · `D-T6` 守卫计数（**只加行**）----
            int gLabeled = 0, gNoBounds = 0, gDelta = 0, gNothing = 0;

            foreach (JsonElement c in cases)
            {
                string id = c.GetProperty("id").GetString();
                if (caseFilter != null && id.IndexOf(caseFilter, StringComparison.Ordinal) < 0) continue;
                ++total;

                string group = c.GetProperty("group").GetString();
                if (!fam.TryGetValue(group, out int[] cnt)) { cnt = new int[2]; fam[group] = cnt; }
                ++cnt[0];

                string text = c.GetProperty("text").GetString();
                double pw = c.GetProperty("paragraphWidthDip").GetDouble();
                bool rtl = c.GetProperty("flowDirection").GetString() == "RightToLeft";
                bool wrap = c.GetProperty("textWrapping").GetString() != "NoWrap";
                bool tabZero = c.GetProperty("incrementalTabArm").GetString() == "DefaultIncrementalTab=0";
                bool firstLine = c.GetProperty("firstLineInParagraph").GetBoolean();
                double ind = c.GetProperty("indentDip").GetDouble();
                double pi = c.GetProperty("paragraphIndentDip").GetDouble();
                bool isNz = (ind != 0 || pi != 0);

                if (isNz) ++nzTotal; else ++zTotal;
                if (pi != 0) ++piNz;

                // 覆盖闸（与三支 tab 臂同口径）：面缺字形 ⇒ 逐字符不可比
                int missing = 0;
                foreach (char ch in text)
                {
                    if (ch == '\t' || ch == '\n' || ch == '\r') continue;
                    if (!miss.TryGetValue(ch, out int g)) { g = NominalGlyph(ch); miss[ch] = g; }
                    if (g == 0) ++missing;
                }
                if (missing > 0)
                {
                    ++skipCov;
                    if (isNz) ++skipNz; else ++skipZ;
                    Console.WriteLine("PCLINE CASE [" + legName + "] " + id + " 臂=" + (rtl ? "RTL" : "LTR") + " 跳过=面缺字形" + missing);
                    continue;
                }

                JsonElement exp = c.GetProperty("lines");
                bool reordered = IsReordered(exp);
                if (reordered) ++bidiCases;

                // ---- 驱动 PC 的 TextFormatter（客户端姿势：previousLineBreak 串起来，与 oracle 宿主同一个循环形状） ----
                //  ⚠️ 测量缓存（**只按输入键**）：语料里同一串文本在多个宽度/臂下重复出现，
                //     而排版结果是这 7 个输入的**纯函数**（`TextFormatter` 无跨调用状态：
                //     `s_calls/s_handled` 只是计数器；`SimpleTextLine` 走不到因为 AlwaysCollapsible=true）。
                //     `--no-cache` 可关掉它，用于"缓存不改变读数"的实测对照。
                string ckey = string.Join("|", text, ind.ToString("R"), pi.ToString("R"), pw.ToString("R"),
                                          (rtl ? "R" : "L"), (wrap ? "W" : "N"), (tabZero ? "Z" : "D"),
                                          (firstLine ? "F" : "N"), (alwaysCollapsible ? "T" : "f"));
                List<OurLine> our;
                string driveErr = null;
                string prov;                       // "strict" | "lenient" | "cached:strict" | "cached:lenient" | "none"
                long sH0 = StrictHandled(), lH0 = DiagHandled();
                if (!s_noCache && s_measCache.TryGetValue(ckey, out CachedMeasure cached))
                {
                    our = Clone(cached.Lines);
                    prov = "cached:" + cached.Tier;
                }
                else
                {
                var src = new MockTextSource(text, props);
                var para = new OraPara(props, rtl ? FlowDirection.RightToLeft : FlowDirection.LeftToRight,
                                       tabZero, ind, pi, firstLine, alwaysCollapsible);
                our = new List<OurLine>();
                sH0 = StrictHandled(); lH0 = DiagHandled();     // ← W19B：**驱动前后**各取一次，逐例归因
                int index = 0, guard = 0;
                TextLineBreak brk = null;
                while (index < text.Length && guard++ < 64)
                {
                    TextLine line;
                    try { line = formatter.FormatLine(src, index, pw, para, brk); }
                    catch (Exception e) { driveErr = "FormatLine 抛 " + e.GetType().Name + ": " + e.Message; break; }
                    if (line == null) { driveErr = "FormatLine 返回 null"; break; }
                    int len = (int)line.Length;
                    if (len <= 0) { driveErr = "FormatLine 返回 0 长行（会死循环）⇒ 停"; break; }
                    int nl = (int)line.NewlineLength;
                    int vis = len - nl; if (index + vis > text.Length) vis = Math.Max(text.Length - index, 0);
                    if (s_dumpRaw)
                    {
                        string rt = ""; int rlen = 0;
                        try { TextRun r0 = src.GetTextRun(index); rlen = r0.Length; rt = r0.GetType().Name; } catch (Exception e) { rt = "EX " + e.GetType().Name; }
                        var tbs = new StringBuilder();
                        for (int q = 0; q < Math.Min(3, (int)line.Length); ++q)
                        {
                            try
                            {
                                IList<TextBounds> b0 = line.GetTextBounds(q, 1);
                                if (b0 != null && b0.Count > 0 && b0[0].TextRunBounds != null && b0[0].TextRunBounds.Count > 0)
                                    tbs.Append(" [i=").Append(q).Append(" X=").Append(F(b0[0].TextRunBounds[0].Rectangle.X))
                                       .Append(" W=").Append(F(b0[0].TextRunBounds[0].Rectangle.Width)).Append("]");
                                else tbs.Append(" [i=").Append(q).Append(" <nobounds>]");
                            }
                            catch (Exception e) { tbs.Append(" [i=").Append(q).Append(" EX ").Append(e.GetType().Name).Append("]"); }
                        }
                        Console.WriteLine("PCLINE RAW srcRun=" + rt + " srcRunLen=" + rlen + " Start=" + F(line.Start) + " bounds=" + tbs);
                        Console.WriteLine("PCLINE RAW " + id + " call#" + our.Count + " cpFirst=" + index
                                          + " type=" + line.GetType().FullName
                                          + " len=" + line.Length + " nl=" + line.NewlineLength
                                          + " tws=" + line.TrailingWhitespaceLength
                                          + " w=" + F(line.Width) + " witw=" + F(line.WidthIncludingTrailingWhitespace)
                                          + " ovf=" + line.HasOverflowed
                                          + " vis=[" + Show((index + Math.Max(len - nl, 0) <= text.Length) ? text.Substring(index, Math.Max(len - nl, 0)) : "?") + "]"
                                          + "  diag=" + Diag());
                    }
                    var o = new OurLine();
                    o.Width = line.Width;
                    o.Start = line.Start;        // W21A：`#21` §1 P1 的新列（只读，不驱动任何额外的东西）
                    o.Tws = (int)line.TrailingWhitespaceLength;
                    o.Nl = nl;
                    o.Text = (index + vis <= text.Length) ? text.Substring(index, vis) : "";
                    o.CpFirst = index;          // W20A：本行在**段落系**里的起点（= 客户端累加值，真机宿主同一口径）
                    o.LineRef = line;           // W20A：守卫要拿**行对象本身**重读（只读，不再驱动）
                    int li = our.Count;
                    int pcCount = -1, k = 0;
                    foreach (JsonElement E in exp.EnumerateArray())
                    {
                        if (k++ != li) continue;
                        pcCount = 0;
                        foreach (JsonElement pc in E.GetProperty("perChar").EnumerateArray()) ++pcCount;
                        break;
                    }
                    for (int i = 0; i < (pcCount < 0 ? 0 : pcCount); ++i)
                    {
                        IList<TextBounds> tb = null;
                        try { tb = line.GetTextBounds(i, 1); } catch (Exception) { }
                        if (tb == null || tb.Count == 0 || tb[0].TextRunBounds == null || tb[0].TextRunBounds.Count == 0)
                        { o.X.Add(double.NaN); continue; }
                        o.X.Add(tb[0].TextRunBounds[0].Rectangle.X);
                    }
                    our.Add(o);
                    brk = line.GetTextLineBreak();
                    index += len;
                }
                long dS = StrictHandled() - sH0, dL = DiagHandled() - lH0;
                if (dS < 0 || dL < 0) prov = "none";                       // IVT 读不到 ⇒ 不许当 0
                else if (dS > 0) prov = "strict";                          // 严格档接手（增量>0）
                else if (dL > 0) prov = "lenient";                         // 严格档没接住 ⇒ 宽松档接手
                else prov = "none";
                if (s_dumpRaw)
                    Console.WriteLine("PCLINE RAW " + id + " 层级 dStrictHandled=" + dS + " dRelaxedHandled=" + dL
                                      + " ⇒ 接手=" + prov + "；严格档=" + StrictDiag());
                if (prov != "none" && !s_noCache) s_measCache[ckey] = new CachedMeasure { Lines = Clone(our), Tier = prov };
                if (prov == "none" && !s_noCache) s_measCache.Remove(ckey);
                }

                // ---- 正控（**档位感知**；纪律 3/21/27：判据必须能变红，"没跑"不许当绿） ----
                //  旧版写死 `DiagHandled() <= 0 ⇒ NOINFO`（= 只认宽松档）。严格档腿上那**必然**触发
                //  ⇒ 旧版**结构性地**无法做严格档腿（这正是 W19B 要改的东西）。
                //  新版判据 = **本例的接管计数必须来自某一档**（驱动前后增量 > 0），并**逐例归因是哪一档**；
                //  两档都为 0 ⇒ 仍然 `rc=2 NOINFO`（不许报绿）。
                string provTier = prov.StartsWith("cached:", StringComparison.Ordinal) ? prov.Substring(7) : prov;
                if (provTier == "none")
                {
                    Console.WriteLine("PCLINE CASE [" + legName + "] " + id + " NOINFO: 两档接管计数增量都为 0"
                                      + "（严格档 Handled 增量=" + (StrictHandled() - sH0) + "、宽松档 relaxedHandled 增量="
                                      + (DiagHandled() - lH0) + "）⇒ **哪一层接手的不可判定**");
                    Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=本例两档接管计数增量都为 0（正控失败，不许报绿）"
                                      + "；严格档=" + StrictDiag() + "；宽松档=" + Diag());
                    return 2;
                }
                if (prov.StartsWith("cached:", StringComparison.Ordinal)) ++tCached; else if (provTier == "strict") ++tStrict; else ++tLenient;
                if (provTier != s_effectiveTier)
                {
                    ++tOffTier;
                    if (offTierRows.Length < 2000)
                        offTierRows += "PCLINE TIER " + id + " 接手档=" + provTier + " ≠ 本腿生效档=" + s_effectiveTier
                                     + "（严格档没接住这一例：lastBail=\"" + WpfLinux.Shims.PresentationCore.HbTextFallback.LastBail + "\"）\n";
                }

                // ---- W21A · `#21` §1 P1：**新列**的真值（逐行，与 `exp` 平行）与"能不能断言" ----
                //  真值来源 = 语料 `lineStartOffsetsDip[k]`，即真机宿主
                //  `tests/parity/windows/tab-anchor/src/Program.cs:445` 的 `lineIndents.Add(R(line.Start));`
                //  （同一读数在 `:555` 以 `paragraphStartOffsetDip` **第二处落盘**；主控实测 615/615 一致，
                //   本臂**只用** `lineStartOffsetsDip`）。缺字段 ⇒ 本列 NOINFO，**不发明真值**。
                JsonElement starts;
                bool haveStarts = c.TryGetProperty("lineStartOffsetsDip", out starts)
                                  && starts.ValueKind == JsonValueKind.Array;
                bool stAssert = s_alignAssertable && haveStarts && CaseAlignmentOk(c)
                                && haveStarts && starts.GetArrayLength() == exp.GetArrayLength();
                if (!stAssert)
                {
                    ++stCaseNoInfo;
                    if (s_stNoInfoRows.Length < 4000)
                        s_stNoInfoRows += "PCLINE START-NOINFO " + id + " 原因="
                                        + (!s_alignAssertable ? "本语料对齐不可断言为 Left（见 StartCol 行）"
                                           : !haveStarts ? "语料缺 `lineStartOffsetsDip` 字段"
                                           : !CaseAlignmentOk(c) ? "本例 `textAlignment` ≠ Left"
                                           : "`lineStartOffsetsDip` 长度=" + (haveStarts ? starts.GetArrayLength() : -1)
                                             + " ≠ 真值行数=" + exp.GetArrayLength())
                                        + " ⇒ 本列对该例**既不算红也不算绿**\n";
                }

                bool structOk = (driveErr == null) && our.Count == exp.GetArrayLength();
                bool posOk = true;
                bool startOk = true;                     // W21A：新列 —— 本例该列是否全绿（未断言 ⇒ 保持 true ⇒ 不影响判定）
                string why = null;
                if (driveErr != null)
                {
                    why = driveErr;
                    structRows_Add(ref structRows, id, "驱动失败 " + driveErr);
                }
                else if (!structOk) why = "行数 期望=" + exp.GetArrayLength() + " 实得=" + our.Count;

                if (structOk)
                {
                    int li = 0;
                    foreach (JsonElement E in exp.EnumerateArray())
                    {
                        OurLine o = our[li];
                        double eW = E.GetProperty("width").GetDouble();
                        if (Math.Abs(o.Width - eW) > Tol)
                        {
                            structOk = false;
                            string s = "行#" + li + " width 期望=" + F(eW) + " 实得=" + F(o.Width) + " Δ=" + F(o.Width - eW);
                            structRows_Add(ref structRows, id, s);
                            if (why == null) why = s;
                            if (Math.Abs(o.Width - eW) > s_worst) { s_worst = Math.Abs(o.Width - eW); s_worstWhy = id + " 行#" + li + " width"; }
                        }
                        int eTw = E.GetProperty("trailingWhitespaceLength").GetInt32();
                        if (o.Tws != eTw)
                        {
                            structOk = false;
                            string s = "行#" + li + " 尾部空白 期望=" + eTw + " 实得=" + o.Tws;
                            structRows_Add(ref structRows, id, s);
                            if (why == null) why = s;
                        }
                        int eNl = E.GetProperty("newlineLength").GetInt32();
                        if (o.Nl != eNl)
                        {
                            structOk = false;
                            string s = "行#" + li + " 换行长 期望=" + eNl + " 实得=" + o.Nl;
                            structRows_Add(ref structRows, id, s);
                            if (why == null) why = s;
                        }
                        string eTxt = E.GetProperty("lineText").GetString();
                        if (!string.Equals(o.Text, eTxt, StringComparison.Ordinal))
                        {
                            structOk = false;
                            string s = "行#" + li + " lineText 期望=[" + Show(eTxt) + "] 实得=[" + Show(o.Text) + "]";
                            structRows_Add(ref structRows, id, s);
                            if (why == null) why = s;
                        }
                        // 逐字符位置（bidi 重排例跳过位置面，与三支 tab 臂同一把尺子；tab 不跳过 —— 判别例 B 的红就在 tab 的网格锚上）
                        int j = 0;
                        foreach (JsonElement pc in E.GetProperty("perChar").EnumerateArray())
                        {
                            if (reordered) { ++j; continue; }
                            bool isTab = pc.GetProperty("char").GetString() == "\t";
                            double xfl = pc.GetProperty("xFromLeftDip").GetDouble();
                            double mx = (j < o.X.Count) ? o.X[j] : double.NaN;
                            if (double.IsNaN(mx))
                            {
                                posOk = false;
                                if (why == null) why = "行#" + li + " i=" + j + " 取不到字符边界";
                                ++j; continue;
                            }
                            double d = Math.Abs(mx - xfl);
                            if (d > Tol)
                            {
                                posOk = false;
                                string tag = isTab ? "行#" + li + " TAB网格锚" : "行#" + li + " i=" + j + " xFromLeft";
                                if (why == null) why = tag + " 期望=" + F(xfl) + " 实得=" + F(mx) + " Δ=" + F(mx - xfl);
                                if (d > s_worst) { s_worst = d; s_worstWhy = id + " " + tag; }
                            }
                            ++j;
                        }
                        ++li;
                    }
                }

                // ---- W21A · `#21` §1 P1：**新列** = 逐行 `R(我方 Start)` vs 语料真值 ----
                //  ⚠️ 三条**有意**的口径决定（都有理由，不是遗漏）：
                //   ① **独立于 `structOk`**：本列**不**放在上面那个 `if (structOk)` 里。原因是实测出来的：
                //      放进去只有 **355/615** 行被比过（行划分不一致的例整例不进那个块）——
                //      而 `Start` 是**段落级常量**（`= ParagraphIndent`，**每一行都相同**），
                //      与"我们怎么切行"**无关** ⇒ 只要我方交回了第 k 行，第 k 行的 `Start` 就可比。
                //   ② **不跳 bidi 重排例**：既有「逐字符 x」列要跳（行内下标与真值对应关系被重排破坏），
                //      而 `Start` 是**段落帧**量 ⇒ 两个方向都断言。
                //   ③ 真值行数 > 我方行数时，多出来的真值行**取不到行对象** ⇒ 记 `stMissLines`（**如实计数**，
                //      不许静默消失）；那些例的结构面本来就已经是红（`结构=FAIL`），本列只是"说不出话"。
                if (stAssert)
                {
                    int nCmp = Math.Min(our.Count, starts.GetArrayLength());
                    int caseRed = 0;
                    for (int k = 0; k < nCmp; ++k)
                    {
                        double truthS = starts[k].GetDouble();
                        double gotS = R6(our[k].Start);
                        ++stLines;
                        double dS = Math.Abs(gotS - truthS);
                        if (dS > 0)
                        {
                            ++stRed; ++caseRed;
                            startOk = false;
                            string s = "行#" + k + " Start 我方=" + F(gotS) + " 真值=" + F(truthS)
                                     + " Δ=" + F(gotS - truthS);
                            if (stRows.Length < 200000) stRows += "PCLINE START " + id + " " + s + "\n";
                            if (dS > stWorst) { stWorst = dS; stWorstWhy = id + " 行#" + k; }
                            // 归因：本列**先于**下面那条兜底串登记 why —— 否则"只错这一列"的例会
                            // 被打上「位置量不一致」的**假标签**（那一列其实全过）。
                            if (why == null) why = s;
                        }
                        else ++stGreen;
                    }
                    // 逐例卷起（**与上面的逐行点名行能对账**：本行的 红行 数 == 该 id 的 `PCLINE START` 行数）
                    if (stCaseRows.Length < 200000)
                        stCaseRows += "PCLINE START-CASE " + id + " 本列=" + (caseRed == 0 ? "PASS" : "FAIL")
                                    + " 比过=" + nCmp + " 行 红行=" + caseRed + " 绿行=" + (nCmp - caseRed)
                                    + " 真值行数=" + starts.GetArrayLength() + (caseRed > 0 ? " ⇒ 本列**判决该例为红**" : "") + "\n";
                    if (caseRed > 0) ++stCaseRed;
                    if (starts.GetArrayLength() > our.Count) stMissLines += starts.GetArrayLength() - our.Count;
                }
                // `Start`-only 红：结构面与位置面**都过**、**只**因本列而红 ⇒ 证明"本列真的有判决权"
                if (!startOk && structOk && (reordered || posOk)) ++stOnlyRed;

                bool oneCase = structOk && (reordered || posOk) && startOk;   // W21A：新列并进既有用例级红/绿判定
                if (structOk) ++cnt[1];
                // ---- W19B：**按接手档**分桶（否则严格档腿里"某几例其实是宽松档接的"会被混读）----
                if (provTier == "strict")
                {
                    if (isNz) { if (oneCase) ++nzStrictGreen; else ++nzStrictRed; }
                    else { if (oneCase) ++zStrictGreen; else ++zStrictRed; }
                    if (pi != 0) { ++piStrictTot; if (!oneCase) ++piStrictRed; }
                }
                else
                {
                    if (isNz) { if (oneCase) ++nzLenientGreen; else ++nzLenientRed; }
                    else { if (oneCase) ++zLenientGreen; else ++zLenientRed; }
                    if (pi != 0) { ++piLenientTot; if (!oneCase) ++piLenientRed; }
                }
                if (oneCase) { ++pass; if (isNz) ++nzGreen; else ++zGreen; }
                else
                {
                    ++s_red;
                    if (isNz) ++nzRed; else ++zRed;
                    if (pi != 0) ++piNzRed;
                    failIds.Add(new[] { id, why ?? (structOk ? "位置量不一致" : "结构量不一致") });
                }
                Console.WriteLine("PCLINE CASE [" + legName + "] " + id + " 臂=" + (rtl ? "RTL" : "LTR")
                                  + " wrap=" + (wrap ? 1 : 0) + " I=" + ind.ToString("0") + " PI=" + pi.ToString("0")
                                  + " 非0缩进=" + (isNz ? 1 : 0) + " 结构=" + (structOk ? "PASS" : "FAIL")
                                  + " 位置=" + (reordered ? "跳过(bidi 重排)" : (posOk ? "PASS" : "FAIL"))
                                  + (oneCase ? "" : " :: " + (why ?? "位置量不一致")));

                // ---- W20A · `D-T6` 守卫：把「取不到字符边界」这一族**逐例**定性 ----
                //  判据（两极化，见 GuardCase 文档）：换**真机宿主同款**索引口径重读 ⇒
                //    · 全字取到且 |Δ| ≤ 容差 ⇒ 这一例的红是**读法**造成的（装置限制），逐例贴标签；
                //    · 否则 ⇒ **不许贴标签**，印 `PCLINE GUARD FAIL`（`--guard enforce` ⇒ rc=3）。
                if (s_guard != "off" && why != null && why.IndexOf("取不到字符边界", StringComparison.Ordinal) >= 0)
                    GuardCase(id, why, exp, our, ref gLabeled, ref gNoBounds, ref gDelta, ref gNothing);

                // ---- 孪生行（PI≠0 的例没有 @i0 孪生；PI=0 的例把"预言"降级为读数） ----
                if (twinOf.TryGetValue(id, out JsonElement tw))
                {
                    ++twinHits;
                    // 孪生恒等式的**适用条件**（真值侧已实测）：`tab0` 臂没有网格
                    //   ⇒ `DefaultIncrementalTab=0` 时 tab 的 advance 由拟合决定 ⇒
                    //   "只有网格锚平移 24"这条恒等式**不成立** ⇒ 只记读数、不计违反。
                    bool twinApplicable = !tabZero;
                    if (!twinApplicable) ++twinNa;
                    twinRows += TwinRows(id, tw, our, twinApplicable, ref twinViol, ref twinWorst, ref twinWorstWhy);
                }
                else ++twinMiss;

                // ---- 判别例按名报告 ----
                foreach (string nm in Named)
                    if (id == nm) namedRows += NamedRows(id, exp, our, ind, pi, text);
            }

            // ---- 腿收尾 ----
            Console.WriteLine("PCLINE LEG=" + legName + " 合计 cases=" + total + " 判定过=" + pass
                              + " 判定红=" + (total - skipCov - pass)
                              + " 不可比(缺字形)=" + skipCov + "（其中非0缩进 " + skipNz + "、零缩进 " + skipZ + "）"
                              + " 其中 bidi 重排例=" + bidiCases);
            foreach (var kv in fam)
                Console.WriteLine("PCLINE LEG=" + legName + "   " + kv.Key.PadRight(18) + " 结构 " + kv.Value[1] + "/" + kv.Value[0]);
            Console.WriteLine("PCLINE LEG=" + legName + " 非0缩进: 红=" + nzRed + " 绿=" + nzGreen + " /" + nzTotal
                              + "；零缩进: 红=" + zRed + " 绿=" + zGreen + " /" + zTotal + "；PI≠0: 红=" + piNzRed + " /" + piNz);
            // ---- W21A · `#21` §1 P1：**新列**（`Start` 法律）的**线级**读数 —— 本波的头条判据 ----
            //  为什么必须线级：修前那些 `PI≠0` 的例**多数已经因为别的列红了** ⇒ 只看用例级分桶，
            //  一条**零判别力**的新判据会完全隐形。线级计数就是这条判据的红证读数。
            //  格式：`key=value`（空格分隔）⇒ **可被机器 grep**（主控的核对脚本就按这个形状抓）。
            Console.WriteLine("PCLINE START 腿=" + legName + " 红=" + stRed + " 绿=" + stGreen
                              + " 判定行=" + stLines + " NOINFO=" + stCaseNoInfo
                              + " 红例=" + stCaseRed + " Start-only红例=" + stOnlyRed
                              + " 未比真值行=" + stMissLines
                              + " 最大Δ=" + F(stWorst) + " @" + (stWorst > 0 ? stWorstWhy : "-"));
            Console.WriteLine("PCLINE LEG=" + legName + " Start 口径 断言=**只对 TextAlignment=Left**（本语料头钉死）"
                              + " ｜ 真值=语料 `lineStartOffsetsDip[k]`"
                              + " ｜ R(v)=Round(v,6,AwayFromZero) ｜ 判据=**精确相等**（真法律是恒等式，不是近似）"
                              + " ｜ 比较**独立于 `structOk`**（`Start` 是段落级常量 ⇒ 与我方怎么切行无关）"
                              + " ｜ bidi 例**不跳**（`Start` 是段落帧量）");
            // ---- W19B · 层级来源（**这一行是本腿红/绿能不能归因的唯一机器证据**）----
            Console.WriteLine("PCLINE LEG=" + legName + " 层级来源 请求档=" + s_tierRequested
                              + " 生效档=" + (s_effectiveTier == "strict" ? "严格档(HbTextFallback)" : "宽松档(WpfLinuxLenientTextFallback)")
                              + " ｜ 严格档接手=" + tStrict + " 例、宽松档接手=" + tLenient + " 例、"
                              + "缓存复用=" + tCached + " 例（层级沿用同输入键的首趟）、非生效档接手=" + tOffTier + " 例、两档皆0=" + tNone + " 例");
            Console.WriteLine("PCLINE LEG=" + legName + " 严格档计数 " + StrictDiag()
                              + "（本腿 fallbackCalls 增量=" + (StrictCalls() - strictCallsBefore)
                              + "、fallbackHandled 增量=" + (StrictHandled() - strictHandledBefore) + "）");
            Console.WriteLine("PCLINE LEG=" + legName + " 宽松档计数 " + Diag() + "（本腿 relaxedCalls 增量=" + (DiagCalls() - callsBefore) + "）");
            Console.WriteLine("PCLINE LEG=" + legName + " 层级分桶 严格档接手(可比): 非0缩进 红=" + nzStrictRed + " 绿=" + nzStrictGreen
                              + "；零缩进 红=" + zStrictRed + " 绿=" + zStrictGreen + "；PI≠0 红=" + piStrictRed + " /" + piStrictTot
                              + " ｜ 宽松档接手(可比): 非0缩进 红=" + nzLenientRed + " 绿=" + nzLenientGreen
                              + "；零缩进 红=" + zLenientRed + " 绿=" + zLenientGreen + "；PI≠0 红=" + piLenientRed + " /" + piLenientTot);
            if (offTierRows.Length != 0) Console.Write(offTierRows);
            Console.WriteLine("PCLINE LEG=" + legName + " 正控 " + Diag() + "（本腿 relaxedCalls 增量=" + (DiagCalls() - callsBefore) + "）");
            // 严格档腿的**有效正控**：严格档必须真的接住过（一例都没有 ⇒ 这条路对本臂不可观测 ⇒ rc=2，不许报绿）
            if (s_effectiveTier == "strict" && tStrict == 0)
            {
                Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=--tier strict 生效，但**严格档一例都没接住**"
                                  + "（严格档接手=0 例、宽松档接手=" + tLenient + " 例）⇒ 这条路径对本臂**不可观测**，不是绿；"
                                  + "严格档计数=" + StrictDiag());
                return 2;
            }
            if (zRed > 0)
                Console.WriteLine("PCLINE LEG=" + legName + " ⚠️ 零缩进例红了 " + zRed + " 条 ⇒ 按 R17A-recon.md §3.3 的「臂坏了的形态」，"
                                  + "这属于**臂/字体/层选错**，不是 P2 的红 ⇒ 读之前先查这一条（纪律 27 同族）");

            // 逐条裁定
            int unregistered = 0;
            int unregStart = 0;                 // W21A：**未登记**失败里"失配词点名 Start 列"的那部分
            foreach (string[] f in failIds)
            {
                bool reg = kr.Matches(f[0], f[1]);
                Console.WriteLine("PCLINE [" + legName + "] " + (reg ? "KNOWN-RED " : "UNREGISTERED ") + f[0] + " :: " + f[1]);
                if (!reg) { ++unregistered; if (f[1] != null && f[1].IndexOf("Start ", StringComparison.Ordinal) >= 0) ++unregStart; }
            }
            Console.WriteLine("PCLINE START-RC 腿=" + legName + " 未登记失败=" + unregistered
                              + " 其中点名Start列=" + unregStart
                              + " ⇒ " + (unregistered > 0 ? "rc≠0（本列有未登记红，**不许压成 0**）" : "本列没有未登记红"));
            // ---- W20A · `D-T6` 守卫：腿级汇总 + 守卫自己的红/绿（**只加行**）----
            if (s_guard != "off")
            {
                int gTotal = gLabeled + gNoBounds + gDelta + gNothing;
                Console.WriteLine("PCLINE LEG=" + legName + " 装置限制(读法口径) 判定=" + gTotal + " 例"
                                  + " ｜贴标签（重读全字取到且 |Δ|≤" + F(Tol) + "）=" + gLabeled + " 例"
                                  + "；重读仍取不到字符边界=" + gNoBounds + " 例"
                                  + "；重读 |Δ|>容差=" + gDelta + " 例"
                                  + "；拿不到行对象=" + gNothing + " 例"
                                  + " ｜模式=" + s_guard + " 读法=" + s_guardConv
                                  + " ｜判据=真机宿主同款 `GetTextBounds(cpFirst+j,1)`"
                                  + "（`tests/parity/windows/tab-anchor/src/Program.cs:512-514`）");
                // 守卫自己的**正控**：贴过标签 ⇒ 必须真的量过（0 例 ⇒ 没输入 ≠ 通过）
                if (s_guard == "enforce" && gTotal == 0)
                {
                    Console.WriteLine("PCLINE_EXIT=NOINFO rc=2 原因=--guard enforce 但本腿**没有任何**「取不到字符边界」例"
                                      + "（判定=0）⇒ 守卫**没有输入**，不是通过（纪律 21/27）");
                    return 2;
                }
            }
            // 守卫失败 ⇒ 由 Main 把 rc 改写成 3（**只**在 --guard enforce 时；缺省 label 只印标签、rc 口径不动）
            s_guardEvaluated += gLabeled + gNoBounds + gDelta + gNothing;
            s_guardFailed += gNoBounds + gDelta + gNothing;
            if (legName == "B")   // 汇总只取**同层对照腿 B**（腿 A 的零缩进半边不是同层，会被上游快路径接走 ⇒ 不混算）
            {
                s_fail += unregistered;
                s_green += pass; s_skipCov += skipCov; s_bidi += bidiCases;
                s_nzTotal += nzTotal; s_nzRed += nzRed; s_nzGreen += nzGreen;
                s_zTotal += zTotal; s_zRed += zRed; s_zGreen += zGreen;
                s_piNz += piNz; s_piNzRed += piNzRed;
                s_twinHits = twinHits.ToString() + "（其中 tab0 臂=恒等式不适用 " + twinNa + "）";
                s_twinMiss = twinMiss.ToString();
                s_twinViol = twinViol; s_twinWorst = twinWorst; s_twinWorstWhy = twinWorstWhy;
                s_twinRows += twinRows; s_namedRows += namedRows; s_structRows += structRows;
                // ---- W21A · `#21` §1 P1：`Start` 列的腿 B 汇总（与上面各列同一取舍：汇总 == 腿 B 一条腿）----
                s_stLines += stLines; s_stRed += stRed; s_stGreen += stGreen; s_stNoInfo += stCaseNoInfo;
                s_stCaseRed += stCaseRed; s_stOnlyRed += stOnlyRed; s_stMissLines += stMissLines;
                s_stUnreg += unregStart;
                if (stWorst > s_stWorst) { s_stWorst = stWorst; s_stWorstWhy = stWorstWhy; }
                s_stRows += stRows; s_stCaseRows += stCaseRows;
            }
            return 0;
        }

        /// <summary>一行我们自己的读数。</summary>
        private sealed class OurLine
        {
            internal double Width;
            /// <summary>W21A · `#21` §1 P1：`TextLine.Start`（DIP，**段落帧**量 —— 与逐字符 x 不同，bidi 重排不影响它）。</summary>
            internal double Start;
            internal int Tws, Nl;
            internal string Text;
            internal readonly List<double> X = new List<double>();
            /// <summary>W20A：这一行的**段落系起点**（客户端按 `Length` 累加得到的值 —— 真机 oracle 宿主
            /// `tab-anchor/src/Program.cs:512-514` 就是这么得到 `gi = lineStart + i` 的）。</summary>
            internal int CpFirst;
            /// <summary>W20A：`FormatLine` 交回来的**行对象本身**（守卫用它做**只读重读**：
            /// 换索引口径再问一次 `GetTextBounds`，不重新驱动、不碰任何计数）。</summary>
            internal TextLine LineRef;
        }

        private static void structRows_Add(ref string rows, string id, string s) { rows += "PCLINE STRUCT " + id + " " + s + "\n"; }

        // ================================================================================
        //  W20A · `D-T6` 守卫：**「取不到字符边界」这一族到底是臂/装置还是产品**
        // ================================================================================
        //
        //  【这一族的形态（`#19` 实测）】严格档腿 `位置=FAIL 121 = 54 @tab0 + 67 非 tab0`，
        //    其中 67 条的失配词**完全相同**：`行#1 i=0 取不到字符边界`（另加 19 条零缩进同形）。
        //
        //  【机制（W20A 用 `StrictTierProbe` 逐行 dump 定下的，不是读代码猜的）】
        //    `PcLineOracle` 读逐字 x 用的是 `line.GetTextBounds(i, 1)`，其中 `i` 是**行内**下标；
        //    而 `GetTextBounds` 的第一个参数是**段落系**下标：
        //      · 真机 oracle 宿主自己就是**段落系**读法 —— `tests/parity/windows/tab-anchor/src/Program.cs:512-514`
        //        `int gi = lineStart + i; … line.GetTextBounds(gi, 1)`（`lineStart` = 客户端按 `Length` 累加）；
        //      · 真机注解：`tests/parity/windows/layout-b34/src/LayoutOracle/Runner.cs:96`
        //        `"GetTextBounds_firstArg": "段落系索引；传 0 只有行起点=0 的行有结果"`，
        //        以及同文件 `:395` 的现场注释"第一版传 0，于是只有'行起点=0'的行拿得到 run 范围"；
        //      · 严格档交回的行**带段落系帧**（`HbTextLine._lineStart` = 段落系起点）⇒ 行内下标 `i=0`
        //        到了第 2 行就是 `localFirst = 0 - _lineStart < 0` ⇒ `GetTextBounds` 返回空
        //        ⇒ 臂记 `NaN` ⇒ 失配词；**行起点=0 的第 1 行**照样能读到（这就是"只有 `行#1 i=0`"的形状）。
        //      · 宽松档把每行**重新起段**（`WpfLinuxLenientTextFallback.TryFormatLine` 从 `cpFirst`
        //        重新收集并 `return lines[0]`）⇒ 交回的行 `_lineStart` 恒 0 ⇒ 行内读法**恰好**能读
        //        ⇒ 跨档反极性。**这正是这族红只在严格档腿出现的原因。**
        //    ⇒ 结论 = **臂/装置（读法口径）**。守卫就是把这个结论**机器化**：
        //      换真机同款口径重读，若不成立就**拒绝贴标签**。
        //
        //  【为什么守卫能变红】判据是"换口径重读 ⇒ 每行每字都取到边界**且**与真值 |Δ| ≤ 容差"。
        //    · `--guard-conv line`（故意用错口径）⇒ 家族例全部读不到 ⇒ `PCLINE GUARD FAIL` + `rc=3`；
        //    · `--guard enforce` 而一例家族例都没有（例如宽松档腿）⇒ `NOINFO rc=2`（没输入 ≠ 通过）。
        //    两趟都实测在册（见 `W20A-report.md` §7）。
        private static void GuardCase(string id, string why, JsonElement exp, List<OurLine> our,
                                      ref int labeled, ref int noBounds, ref int delta, ref int nothing)
        {
            var frames = new List<string>();
            int chars = 0, miss = 0, over = 0, linesMissing = 0;
            double worst = 0; string worstWhy = "-";
            bool anyLine = false;

            int li = 0;
            foreach (JsonElement E in exp.EnumerateArray())
            {
                if (li >= our.Count) break;
                OurLine o = our[li];
                if (o.LineRef == null)
                {
                    frames.Add("NA"); ++linesMissing;
                }
                else
                {
                    anyLine = true;
                    int f = FrameScan(o.LineRef, o.CpFirst);
                    frames.Add(f < 0 ? "无" : f.ToString());
                    int j = 0;
                    foreach (JsonElement pc in E.GetProperty("perChar").EnumerateArray())
                    {
                        int arg = (s_guardConv == "abs") ? (o.CpFirst + j) : j;
                        IList<TextBounds> b = GuardProbe(o.LineRef, arg);
                        ++chars;
                        if (!GuardHasTrb(b)) ++miss;
                        else
                        {
                            double truth = pc.GetProperty("xFromLeftDip").GetDouble();
                            double d = Math.Abs(b[0].Rectangle.X - truth);
                            if (d > worst) { worst = d; worstWhy = "行#" + li + " i=" + j; }
                            if (d > Tol) ++over;
                        }
                        ++j;
                    }
                }
                ++li;
            }

            string head = "PCLINE GUARD " + id + " 装置限制=字符边界读法口径（**不是产品红**）｜失配词=" + why
                        + "｜行帧（逐行扫描：最小的、能取到边界的段落系下标）=[" + string.Join(",", frames) + "]"
                        + "｜旧读法（行内 j，本臂既有口径）=" + why + " ⇒ 空"
                        + "｜新读法（段落系 cpFirst+j）=" + (s_guardConv == "abs" ? "真机同款" : "**故意错的口径**")
                        + "｜重读字数=" + chars + " 取不到=" + miss + " |Δ|>容差=" + over
                        + " Δmax=" + F(worst) + "@" + worstWhy;

            if (!anyLine || linesMissing > 0)
            {
                ++nothing;
                Console.WriteLine("PCLINE GUARD FAIL " + id + " 装置限制这个标签的前提**不成立**："
                                  + "拿不到已交回的行对象（linesMissing=" + linesMissing
                                  + "）⇒ 无法用真机同款口径重读 ⇒ **不许**把它读成装置限制。");
                return;
            }
            if (miss > 0)
            {
                ++noBounds;
                Console.WriteLine("PCLINE GUARD FAIL " + id + " 装置限制这个标签的前提**不成立**："
                                  + "用「" + s_guardConv + "」口径重读**仍然取不到**字符边界（" + miss + "/" + chars + " 字）"
                                  + " ⇒ 这一族**不能**只归因到读法 ⇒ 保持产品红。｜" + head);
                return;
            }
            if (over > 0)
            {
                ++delta;
                Console.WriteLine("PCLINE GUARD FAIL " + id + " 装置限制这个标签的前提**不成立**："
                                  + "重读取到了边界，但与真值 |Δ|>容差 的字=" + over + "（Δmax=" + F(worst) + "@" + worstWhy + "）"
                                  + " ⇒ 几何**真的**不对 ⇒ 保持产品红。｜" + head);
                return;
            }
            ++labeled;
            Console.WriteLine(head + "｜重读全字取到且 |Δ|≤" + F(Tol) + " ⇒ **本例的红是读法造成的**，"
                              + "不是严格档的几何红；判据见 `Program.cs` 的 GuardCase 注释与 `W20A-report.md`。");
        }

        /// <summary>本行自己的**帧原点** = 最小的 `a`，使 `GetTextBounds(a, 1)` 拿得到 `TextRunBounds`。
        /// **不依赖任何约定/私有字段**（探针另有 `_lineStart` 反射交叉验证）。返回 −1 = 扫不到。</summary>
        private static int FrameScan(TextLine line, int cpFirst)
        {
            int hi = cpFirst + 4;
            for (int a = 0; a <= hi; ++a) if (GuardHasTrb(GuardProbe(line, a))) return a;
            return -1;
        }
        private static IList<TextBounds> GuardProbe(TextLine line, int arg)
        {
            try { return line.GetTextBounds(arg, 1); } catch (Exception) { return null; }
        }
        /// <summary>与既有判据**同一条件**：拿不到 `TextRunBounds` ⇒ 臂记 `NaN`（既有 CASE 行就是这么红的）。</summary>
        private static bool GuardHasTrb(IList<TextBounds> b)
            => b != null && b.Count > 0 && b[0].TextRunBounds != null && b[0].TextRunBounds.Count > 0;

        // ================================================================================
        //  孪生 / 判别例 行
        // ================================================================================
        private static string MakeTwinId(string id)
        {
            int a = id.LastIndexOf("@i", StringComparison.Ordinal);
            if (a < 0) return null;
            int b = id.IndexOf('@', a + 1);
            if (b < 0) return null;
            // ⚠️ `a` = `@` 的下标（`LastIndexOf("@i")` 返回 `@` 的位置）⇒ 臂名（**含 `i` 前缀**）
            //    从 `a+1` 起，到下一个 `@`（`b`）止。第一版写成 `a+2` ⇒ 得到 "24" ⇒ 恒不匹配
            //    ⇒ 孪生表结构性为空（已在两个读数之前抓掉：`grep -c 'PCLINE TWIN '` = 0）。
            string arm = id.Substring(a + 1, b - a - 1);   // `i0` / `i24` / `i24nl` / `i24p24` / `i0p48` / …
            if (arm == "i24" || arm == "i24p24" || arm == "i24p48") return id.Substring(0, a) + "@i0" + id.Substring(b);
            return null;
        }

        private static string TwinRows(string id, JsonElement twin, List<OurLine> our, bool applicable,
                                       ref int viol, ref double worst, ref string worstWhy)
        {
            var sb = new StringBuilder();
            var exp = twin.GetProperty("lines");
            int n = exp.GetArrayLength();
            sb.Append("PCLINE TWIN ").Append(id).Append(" vs ").Append(twin.GetProperty("id").GetString())
              .Append("  行数 我方=").Append(our.Count).Append(" 孪生=").Append(n);
            if (our.Count != n) sb.Append("  ⚠️行数不等");
            sb.Append('\n');
            int li = 0;
            foreach (JsonElement E in exp.EnumerateArray())
            {
                if (li >= our.Count) break;
                double tw = E.GetProperty("width").GetDouble();
                sb.Append("PCLINE TWIN   ").Append(id).Append(" 行#").Append(li)
                  .Append(" width 我方=").Append(F(our[li].Width)).Append(" 孪生真值=").Append(F(tw))
                  .Append(" Δ=").Append(F(our[li].Width - tw)).Append('\n');
                TwinAcc(id + " 行#" + li + " width", Math.Abs(our[li].Width - tw), applicable, ref viol, ref worst, ref worstWhy);
                int j = 0;
                foreach (JsonElement pc in E.GetProperty("perChar").EnumerateArray())
                {
                    double x0 = pc.GetProperty("xFromLeftDip").GetDouble();
                    double mx = (j < our[li].X.Count) ? our[li].X[j] : double.NaN;
                    sb.Append("PCLINE TWIN   ").Append(id).Append(" 行#").Append(li).Append(" i=").Append(j)
                      .Append(" char=[").Append(pc.GetProperty("char").GetString()).Append("]")
                      .Append(" x 我方=").Append(double.IsNaN(mx) ? "NA" : F(mx))
                      .Append(" 孪生真值=").Append(F(x0))
                      .Append(" Δ=").Append(double.IsNaN(mx) ? "NA" : F(mx - x0)).Append('\n');
                    if (!double.IsNaN(mx)) TwinAcc(id + " 行#" + li + " i=" + j, Math.Abs(mx - x0), applicable, ref viol, ref worst, ref worstWhy);
                    ++j;
                }
                ++li;
            }
            return sb.ToString();
        }

        /// <summary>孪生恒等式 = "同一份输入、同一份代码"的恒等 ⇒ 差只应来自**字体度量**的 FUnit 量化
        /// （Liberation 与 Arial 的 'a' advance 差 0.000989 DIP ⇒ 两字符 0.001978），
        /// 所以容差与真值判据同一把尺子（0.05）；超过即**记录违反数**，不许静默。</summary>
        private static void TwinAcc(string what, double d, bool applicable, ref int viol, ref double worst, ref string worstWhy)
        {
            if (!applicable) return;                       // tab0 臂：恒等式本身不适用（在册）
            if (d > worst) { worst = d; worstWhy = what + " Δ=" + F(d); }
            if (d > Tol) ++viol;
        }

        /// <summary>W19B：缓存条目 = 读数 **+ 首趟的层级归因**。
        /// 为什么必须带上层级：命中缓存时**不再驱动** ⇒ 计数不增 ⇒ 若不带层级，逐例归因会变成"两档皆 0"的假 NOINFO。</summary>
        private sealed class CachedMeasure
        {
            internal List<OurLine> Lines;
            internal string Tier;         // "strict" | "lenient"
        }
        private static readonly Dictionary<string, CachedMeasure> s_measCache = new Dictionary<string, CachedMeasure>(StringComparer.Ordinal);
        private static List<OurLine> Clone(List<OurLine> src)
        {
            var r = new List<OurLine>(src.Count);
            foreach (OurLine o in src)
            {
                var n = new OurLine();
                n.Width = o.Width; n.Tws = o.Tws; n.Nl = o.Nl; n.Text = o.Text;
                n.Start = o.Start;                              // W21A：新列 —— 缓存命中时也必须带回来
                n.CpFirst = o.CpFirst; n.LineRef = o.LineRef;   // W20A：守卫要用（缓存命中时不再驱动，行对象照旧有效）
                n.X.AddRange(o.X);
                r.Add(n);
            }
            return r;
        }

        private static string NamedRows(string id, JsonElement exp, List<OurLine> our,
                                        double ind, double pi, string text)
        {
            var sb = new StringBuilder();
            sb.Append("---- 判别例 ").Append(id).Append("  文本=[").Append(Show(text))
              .Append("] Indent=").Append(ind.ToString("0")).Append(" ParagraphIndent=").Append(pi.ToString("0"))
              .Append(" 我方行数=").Append(our.Count).Append(" 真值行数=").Append(exp.GetArrayLength()).Append('\n');
            int li = 0;
            foreach (JsonElement E in exp.EnumerateArray())
            {
                if (li >= our.Count)
                {
                    sb.Append("PCLINE NAMED   ").Append(id).Append(" 行#").Append(li).Append(" 真值 w=")
                      .Append(F(E.GetProperty("width").GetDouble())).Append(" 我方=<缺行>\n");
                    ++li; continue;
                }
                OurLine o = our[li];
                double eW = E.GetProperty("width").GetDouble();
                sb.Append("PCLINE NAMED   ").Append(id).Append(" 行#").Append(li)
                  .Append(" width 我方=").Append(F(o.Width)).Append(" 真值=").Append(F(eW))
                  .Append(" Δ=").Append(F(o.Width - eW))
                  .Append("  尾部空白 我方=").Append(o.Tws).Append(" 真值=").Append(E.GetProperty("trailingWhitespaceLength").GetInt32())
                  .Append("  换行长 我方=").Append(o.Nl).Append(" 真值=").Append(E.GetProperty("newlineLength").GetInt32())
                  .Append("  lineText 我方=[").Append(Show(o.Text))
                  .Append("] 真值=[").Append(Show(E.GetProperty("lineText").GetString())).Append("]\n");
                int j = 0;
                foreach (JsonElement pc in E.GetProperty("perChar").EnumerateArray())
                {
                    double x0 = pc.GetProperty("xFromLeftDip").GetDouble();
                    double mx = (j < o.X.Count) ? o.X[j] : double.NaN;
                    sb.Append("PCLINE NAMED   ").Append(id).Append(" 行#").Append(li).Append(" i=").Append(j)
                      .Append(" char=[").Append(pc.GetProperty("char").GetString()).Append("]")
                      .Append(" xFromLeft 我方=").Append(double.IsNaN(mx) ? "NA" : F(mx))
                      .Append(" 真值=").Append(F(x0))
                      .Append(" Δ=").Append(double.IsNaN(mx) ? "NA" : F(mx - x0)).Append('\n');
                    ++j;
                }
                ++li;
            }
            return sb.ToString();
        }

        // ================================================================================
        //  小工具
        // ================================================================================
        private static bool IsReordered(JsonElement lines)
        {
            foreach (JsonElement E in lines.EnumerateArray())
            {
                double prev = double.NegativeInfinity;
                foreach (JsonElement pc in E.GetProperty("perChar").EnumerateArray())
                {
                    double xf = pc.GetProperty("xFromLeftDip").GetDouble();
                    if (xf + Tol < prev) return true;
                    prev = xf;
                }
            }
            return false;
        }

        private static string Show(string s)
        {
            if (s == null) return "<null>";
            var sb = new StringBuilder();
            foreach (char c in s) { if (c == '\t') sb.Append("\\t"); else if (c == '\n') sb.Append("\\n"); else if (c == '\r') sb.Append("\\r"); else sb.Append(c); }
            return sb.ToString();
        }

        private static string Hex(byte[] b)
        {
            var sb = new StringBuilder(b.Length * 2);
            foreach (byte x in b) sb.Append(x.ToString("x2"));
            return sb.ToString();
        }

        private static Typeface MakeTypeface(string family)
        {
            try { return new Typeface(new FontFamily(family), FontStyles.Normal, FontWeights.Normal, FontStretches.Normal); }
            catch (Exception) { return null; }
        }

        private static string Describe(Typeface tf)
        {
            if (tf == null) return "<null>";
            string src = tf.FontFamily != null ? tf.FontFamily.Source : "?";
            try
            {
                GlyphTypeface g;
                if (tf.TryGetGlyphTypeface(out g) && g != null)
                    return "family=" + src + " → " + g.FontUri.LocalPath + "#" + g.FaceIndex;
                return "family=" + src + " → TryGetGlyphTypeface=false";
            }
            catch (Exception e) { return "family=" + src + " → 异常 " + e.GetType().Name; }
        }

        /// <summary>覆盖闸：该码点在**已解析面**里有没有字形（0 = 无 ⇒ 真机会用回退面，我们没有 ⇒ 不可比）。
        /// 口径 = 已解析 `GlyphTypeface.CharacterToGlyphMap`（`Main` 里解析成功并落进 `s_cmap`）。
        /// ⚠️ **第一版的仪器缺陷（已抓掉，留档）**：它写 `new GlyphTypeface(new Uri("file://"+path))`，
        ///    而该构造器在本机对 `.ttf` **抛 `FileFormatException`**（实测：`GlyphTypeface.cs:145`），
        ///    于是函数返回 **-1**，而调用点写的是 `if (g == 0) ++missing;` ⇒ **-1 被读成"有字形"**
        ///    ⇒ 148 例（hebrew 116 + arabic 32）**没有被跳过**，整支臂对着缺字形的面量了 148 个假红。
        ///    这就是纪律 21/27 家族"仪器说 0 而其实是没跑"的现场。现在：取不到 cmap ⇒ `rc=2 NOINFO`。</summary>
        private static int NominalGlyph(char ch)
            => s_cmap.TryGetValue(ch, out ushort g) ? g : 0;
        private static IDictionary<int, ushort> s_cmap;
        private static bool s_noCache;
        private static bool s_dumpRaw;

        // ---- IVT：读 PC 的 internal 计数器（正控 + 层级自证） ----
        //  ⚠️ 类的**完全限定名** = `MS.Internal.TextFormatting.WpfLinuxLenientTextFallback`
        //     （生成物 `TextFormatterImp.Linux.cs:37` 的命名空间是 `MS.Internal.TextFormatting`，
        //      **不是** `System.Windows.Media.TextFormatting` —— 后者只是它 `using` 的那一层）。
        private static string DiagStatic()
        {
            try { return MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics; }
            catch (Exception e) { return "<IVT 读不到: " + e.GetType().Name + ": " + e.Message + ">"; }
        }
        private static string Diag() => DiagStatic();
        private static int DiagCalls() => ParseCounter("relaxedCalls=");
        private static int DiagHandled() => ParseCounter("relaxedHandled=");

        // ---- W19B：**严格档**（`HbTextFallback`）的计数与开关，同一个 IVT 名额 ----
        //  命名空间 = `WpfLinux.Shims.PresentationCore`（shim `:60`），**不是** `MS.Internal.…`
        //  （这与宽松档那条正好相反 —— 两处都必须现场读，不能照抄）。
        private static string s_tierRequested = "auto";
        private static string s_effectiveTier = "?";

        // ---- W20A · `D-T6` 守卫的开关与全局计数（缺省 `label`：**只加行、不动 rc 口径**） ----
        /// <summary>`off` = 老行为（连行都不加）；`label`（缺省）= 加标签行、rc 口径不变；
        /// `enforce` = 再加机器强制（守卫前提不成立 ⇒ `rc=3`；一例家族例都没有 ⇒ `NOINFO rc=2`）。</summary>
        private static string s_guard = "label";
        /// <summary>`abs`（缺省，真机宿主同款 `GetTextBounds(cpFirst+j,1)`）/ `line`（**故意用错的口径**，守卫的红极性控制用）。</summary>
        private static string s_guardConv = "abs";
        private static int s_guardEvaluated, s_guardFailed;
        /// <summary>产品自己的层级开关（`internal static bool Enabled`，只读 env，无副作用）。</summary>
        private static bool TryStrictEnabled(out bool enabled, out string why)
        {
            enabled = false; why = "-";
            try { enabled = WpfLinux.Shims.PresentationCore.HbTextFallback.Enabled; return true; }
            catch (Exception e) { why = e.GetType().Name + ": " + e.Message; return false; }
        }
        private static long StrictCalls() { try { return WpfLinux.Shims.PresentationCore.HbTextFallback.Calls; } catch (Exception) { return -1; } }
        private static long StrictHandled() { try { return WpfLinux.Shims.PresentationCore.HbTextFallback.Handled; } catch (Exception) { return -1; } }
        /// <summary>严格档计数行（逐字给出"谁接手了、为什么没接"）。
        /// **直接字段访问**（不反射）：这些 `internal static` 字段**在编译期**被 Roslyn 解析到 PC 里
        /// ⇒ "它们在不在"这件事本身就是**编译期证据**（改了名/删了 ⇒ `error CS`，不是运行期悄悄 NA）。</summary>
        private static string StrictDiag()
        {
            try
            {
                return "fallbackCalls=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Calls
                     + " fallbackHandled=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Handled
                     + " fallbackBailed=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Bailed
                     + " bailNoSwitch=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailNoSwitch
                     + " bailRunType=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailRunType
                     + " bailFont=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailFont
                     + " bailEmpty=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailEmpty
                     + " bailLong=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailLong
                     + " bailException=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailException
                     + " minmaxCalls=" + WpfLinux.Shims.PresentationCore.HbTextFallback.MinMaxCalls
                     + " minmaxHandled=" + WpfLinux.Shims.PresentationCore.HbTextFallback.MinMaxHandled
                     + " minmaxBailed=" + WpfLinux.Shims.PresentationCore.HbTextFallback.MinMaxBailed
                     + " lastBail=\"" + WpfLinux.Shims.PresentationCore.HbTextFallback.LastBail + "\"";
            }
            catch (Exception e) { return "<IVT 读不到: " + e.GetType().Name + ": " + e.Message + ">"; }
        }
        private static int ParseCounter(string key)
        {
            string d = DiagStatic();
            int i = d.IndexOf(key, StringComparison.Ordinal);
            if (i < 0) return -1;
            i += key.Length;
            int j = i; while (j < d.Length && char.IsDigit(d[j])) ++j;
            return int.TryParse(d.Substring(i, j - i), out int v) ? v : -1;
        }


        /// <summary>`#12(d)` 已登记保留红表（格式与三支 tab 臂同一实现：`<id>` 或 `<id>::<判据片段>`）。</summary>
        private sealed class KnownRed
        {
            private readonly List<string[]> _rows = new List<string[]>();
            internal int Count => _rows.Count;
            internal static KnownRed Load(string path)
            {
                var k = new KnownRed();
                if (path == null) return k;
                if (!File.Exists(path)) { Console.WriteLine("PCLINE ⚠️ --known-red 文件不存在：" + path + "（⇒ 视作空表，任何失败都算未登记）"); return k; }
                foreach (string rawLine in File.ReadAllLines(path))
                {
                    string line = rawLine.Trim();
                    if (line.Length == 0 || line[0] == '#') continue;
                    int hash = line.IndexOf(" #", StringComparison.Ordinal);
                    if (hash >= 0) line = line.Substring(0, hash).Trim();
                    int i = line.IndexOf("::", StringComparison.Ordinal);
                    k._rows.Add(i < 0 ? new[] { line, null } : new[] { line.Substring(0, i).Trim(), line.Substring(i + 2).Trim() });
                }
                return k;
            }
            internal bool Matches(string id, string reason)
            {
                foreach (string[] r in _rows)
                {
                    if (!string.Equals(r[0], id, StringComparison.Ordinal)) continue;
                    if (r[1] == null || (reason != null && reason.IndexOf(r[1], StringComparison.Ordinal) >= 0)) return true;
                }
                return false;
            }
        }
    }
}

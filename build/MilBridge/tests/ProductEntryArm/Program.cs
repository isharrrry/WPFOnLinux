// W31A · **走产品入口的 M_modifier 臂**（`build/MilBridge/tests/ProductEntryArm/`）
//
// ═══════════════════════════════════════════════════════════════════════════════
//  这个臂存在的唯一理由
// ═══════════════════════════════════════════════════════════════════════════════
//  本仓连续五波（`#26`–`#30`）的结论里都写着"零产品位移"，但**产品路径本身从未进回归**：
//    · `tline` 臂（`tests/TextLineProto`）、三支 tab 臂、`CoverageProbe --modifier-check`
//      （`CoverageProbe/Program.cs:1241`）**全部直接调** `HbTextLineFactory.FormatParagraph`
//      —— 语料 meta 由臂自己喂进工厂，**PC 一层整个绕过**；
//    · `PcLineOracle` 走产品入口，但它的语料是 `tab-anchor`（`modifier` 命中 **0**）。
//  ⇒ 产品侧"接线有没有把参数传下去"这件事，在回归里**天然看不见**（纪律 67）。
//
//  本臂 = 产品入口（`TextFormatter.Create()` + `FormatLine`，**public**）＋ 真机 `M_modifier_*` 语料。
//
// ═══════════════════════════════════════════════════════════════════════════════
//  被测链路（每一跳都给 file:line，便于归因时逐跳核对）
// ═══════════════════════════════════════════════════════════════════════════════
//   本臂 `formatter.FormatLine(src, i, W, pprops, brk, cache)`
//     → `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:553`（public `FormatLine` 重载）
//     → 同文件 `:617 FormatLineInternal`
//     → `:644` 起点：`AlwaysCollapsible == true`（b34 M 例逐字为 `true`）⇒ **SimpleTextLine 分支被跳过**
//     → `:663` 严格档 `HbTextFallback.TryFormatLine`  ← shim 的 `TryCollect:4575`
//          `Bail(ref BailRunType, "run 类型 " + run.GetType().Name + " 不支持")`
//          ⇒ `TextModifier` 不是 `TextCharacters` ⇒ **严格档必 bail**
//     → `:694` 宽松档 `WpfLinuxLenientTextFallback.TryFormatLine`
//     → `:329 CollectLenient(...)`　← ★ **被测接线点**（**`#32` 之前**的形态）：它**收了** `modifierOpenIndex`（`:226`）
//                                    却**没有** `modifierScopeEnd`（形参表 `:170-173` 里没有这个名字）
//     → `:342` `FormatParagraph(..., modifierOpenIndex: modOpen, modifierCloseIndex: modClose)`
//          ⚠️ **没传 `modifierScopeEnd`** ⇒ shim 取默认 `-1` ⇒ 跨度被当成"到段末"
//     → shim `PresentationCore.HbTextLine.cs:3974` 形参 `modifierScopeEnd = -1`
//     → shim `:2916` `kh = (modifierScopeEnd < 0 ? visibleLen : …)` ⇒ **零宽范围被放大到行末**
//
//  ⏪ **`#32` 更正（纪律 61「加注不覆盖」：上面那 4 行原文一字未动）**：上面描述的是**修前**的形态。
//     `#32` W32A 已落地 `D-T2-c`：`CollectLenient` **新增 `out int modifierScopeEnd`**，见到
//     `TextModifier` 那个 run 时按**它自己的字符范围**记终点（`= (cp-cpFirst) + run.Length`），
//     并在收集循环之后加一行"**`TextEndOfSegment` 显式终点优先**"；**三个** `FormatParagraph`
//     站点**全部**把该实参传下去。⇒ 本臂从"**按设计是红的**"变成**一支普通的绿臂**，
//     并已在 `#32` 接进 `verify-all` 的**第 `[16]` 步**（`build/MilBridge/tools/product-entry-step.sh`）。
//     依据不是论证而是**真机真值自己印出来的**：`layout-b34-compact.json` 的
//     `M_modifier_w200.lines[0].runs = [[0,6,0,45.9667],[45,17,45.9667,110.95]]`、`w=156.9167`
//     ⇒ 零宽跨度 == `TextModifier` run 自己的字符范围（`[6,45)`），不是"到段末"。实测成对读数：
//     `PEA_SUM … lines_judged=133 ok=117 red=18 noinfo=0`（rc=1）→ **`… lines_judged=147 ok=147 red=0 noinfo=0`（rc=0）**。
//
//  正控（证明"真的走到了被测代码"）：IVT 读 `WpfLinuxLenientTextFallback.Diagnostics`
//    —— `relaxedHandled` 必须**真的涨**；否则本趟 `NOINFO rc=2`（纪律 21/27/28：不许把没跑到当绿）。
//
// ═══════════════════════════════════════════════════════════════════════════════
//  判据口径（**不许发明真值**）
// ═══════════════════════════════════════════════════════════════════════════════
//  · 真值 = `build/MilBridge/gen/layout-b34-compact.json` 的 `cases[].lines[]`（**Windows 真机**录的）；
//  · 段落属性（`flowDirection`/`alwaysCollapsible`/`indent`/…九项）**不猜** —— 逐字来自
//    `inputs.json`（由 `extract-inputs.py` 从 `windows-results.json` 抽出，携带源 sha256）；
//  · 字体 = `build/fonts/NotoSans-Regular.ttf`（**逐位同一份**：真值 `fontProof` 记
//    `version=2.015 / glyphCount=3884`，本仓该文件实测同为 `2.015 / 3884`）；
//  · 判**七列**：`len`/`nl`/`ws`（整数，精确相等）、`w`/`witw`/`ext`（实数，容差内）、`lbNull`（布尔）；
//  · 语料没有的字段 ⇒ 打 `NOJUDGE`，**绝不填空**（纪律 22）。

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace MilBridge.ProductEntryArm
{
    // ─────────────────────────────────────────────────────────────────────────
    //  客户端四件套（形态**逐字**照 `tests/parity/windows/layout-b34/src/LayoutOracle/TextModel.cs`）
    //  —— 必须是同一个形态，否则量的不是同一件事。
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>`TextModel.cs:56-66` 的逐字镜像。`Length` = 覆盖剩余长度（首次调用即整段跨度）。</summary>
    internal sealed class ArmModifier : TextModifier
    {
        private readonly int _length;
        private readonly TextRunProperties _props;
        public ArmModifier(int length, TextRunProperties props) { _length = length; _props = props; }
        public override int Length => _length;
        public override TextRunProperties Properties => _props;
        public override TextRunProperties ModifyProperties(TextRunProperties properties) => properties;
        public override bool HasDirectionalEmbedding => false;
        public override FlowDirection FlowDirection => FlowDirection.LeftToRight;
    }

    /// <summary>`TextModel.cs:19-99` 的镜像：无 modifier 的源 + 带 modifier 的源。
    /// `modStart &lt; 0` ⇒ 与真机 oracle 的同一条"无 modifier"支（`Runner.cs:160`）。</summary>
    internal sealed class ArmTextSource : TextSource
    {
        private readonly string _text;
        private readonly TextRunProperties _props;
        private readonly int _modStart;
        private readonly int _modEnd;

        public ArmTextSource(string text, TextRunProperties props, int modStart, int modEnd)
        {
            _text = text; _props = props; _modStart = modStart; _modEnd = modEnd;
        }

        /// <summary>本臂**只**在这一个方法里碰产品面 —— 也是"产品入口"这句话的落点。</summary>
        public override TextRun GetTextRun(int textSourceCharacterIndex)
        {
            if (textSourceCharacterIndex < 0) throw new ArgumentOutOfRangeException(nameof(textSourceCharacterIndex));
            if (textSourceCharacterIndex >= _text.Length) return new TextEndOfParagraph(1);
            if (_modStart < 0)
                return new TextCharacters(_text, textSourceCharacterIndex,
                                          _text.Length - textSourceCharacterIndex, _props);
            if (textSourceCharacterIndex < _modStart)
                return new TextCharacters(_text, textSourceCharacterIndex,
                                          _modStart - textSourceCharacterIndex, _props);
            if (textSourceCharacterIndex < _modEnd)
                return new ArmModifier(_modEnd - textSourceCharacterIndex, _props);
            return new TextCharacters(_text, textSourceCharacterIndex,
                                      _text.Length - textSourceCharacterIndex, _props);
        }

        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;

        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int textSourceCharacterIndexLimit)
        {
            var ccr = new CultureSpecificCharacterBufferRange(CultureInfo.CurrentCulture, new CharacterBufferRange());
            return new TextSpan<CultureSpecificCharacterBufferRange>(0, ccr);
        }
    }

    /// <summary>`TextModel.cs:101-126` 的镜像。</summary>
    internal sealed class ArmRunProperties : TextRunProperties
    {
        private readonly Typeface _typeface;
        private readonly double _emSize;
        private readonly CultureInfo _culture;

        public ArmRunProperties(Typeface typeface, double emSize, CultureInfo culture, double pixelsPerDip)
        {
            _typeface = typeface; _emSize = emSize; _culture = culture;
            PixelsPerDip = pixelsPerDip;
        }

        public override Typeface Typeface => _typeface;
        public override double FontRenderingEmSize => _emSize;
        public override double FontHintingEmSize => _emSize;
        /// <summary>⚠️ **必须是 `null`，不能是 `Brushes.Black`**（本臂第一版照抄 `TextModel.cs:118`
        /// 写 `Brushes.Black` ⇒ **实测踩到**：`System.Windows.Media.Brush` 的静态构造要建 HwndWrapper
        /// ⇒ 本机无 X/DISPLAY ⇒ `TypeInitializationException` ⇒ 宽松档 `TryFormatLine` 每次抛
        /// ⇒ 8 个用例全 `NOINFO`、`rc=2`（原始读数见报告 §3.1）。仓内既有教训**逐字同一条**：
        /// `PcLineOracle/Program.cs:126-133`、`FrameProbe:88`、`MinMaxProbe:64`、`D5CbrProbe:576`。
        /// 本臂**只量几何**，而 shim 把 foreground 当不透明值搬运、从不 deref
        /// （shim `:2444` `… ? _run.Props.ForegroundBrush : null;` ⇒ `null` 是被显式支持的取值）
        /// ⇒ 取 `null` 不改变几何、也不引入 X 依赖。**因此本臂不需要 `DISPLAY`。**</summary>
        public override Brush ForegroundBrush => null;
        public override Brush BackgroundBrush => null;
        public override CultureInfo CultureInfo => _culture;
        public override TextDecorationCollection TextDecorations => null;
        public override TextEffectCollection TextEffects => null;
        public override BaselineAlignment BaselineAlignment => BaselineAlignment.Baseline;
        public override NumberSubstitution NumberSubstitution => null;
        public override TextRunTypographyProperties TypographyProperties => null;
    }

    /// <summary>`TextModel.cs:128-168` 的镜像，**取值全部来自 `inputs.json`**（不设默认、不猜）。</summary>
    internal sealed class ArmParagraphProperties : TextParagraphProperties
    {
        private readonly TextRunProperties _defaults;
        private readonly FlowDirection _flow;
        private readonly TextAlignment _align;
        private readonly TextWrapping _wrap;
        private readonly double _lineHeight;
        private readonly bool _firstLine;
        private readonly double _indent;
        private readonly double _paraIndent;
        private readonly bool _alwaysCollapsible;

        public ArmParagraphProperties(TextRunProperties defaults, FlowDirection flow, TextAlignment align,
            TextWrapping wrap, double lineHeight, bool firstLine, double indent, double paraIndent,
            bool alwaysCollapsible)
        {
            _defaults = defaults; _flow = flow; _align = align; _wrap = wrap;
            _lineHeight = lineHeight; _firstLine = firstLine;
            _indent = indent; _paraIndent = paraIndent; _alwaysCollapsible = alwaysCollapsible;
        }

        public override TextRunProperties DefaultTextRunProperties => _defaults;
        public override FlowDirection FlowDirection => _flow;
        public override TextAlignment TextAlignment => _align;
        public override TextWrapping TextWrapping => _wrap;
        public override double LineHeight => _lineHeight;
        public override bool FirstLineInParagraph => _firstLine;
        public override double Indent => _indent;
        public override double ParagraphIndent => _paraIndent;
        public override bool AlwaysCollapsible => _alwaysCollapsible;
        public override TextDecorationCollection TextDecorations => null;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override IList<TextTabProperties> Tabs => null;
        // ⚠️ **不重写** `DefaultIncrementalTab`：真机 oracle（`TextModel.cs`）也没重写
        //    ⇒ 两边都吃基类默认值，才是同一把尺子。M 例文本无制表符，该值不参与任何计算。
    }

    // ─────────────────────────────────────────────────────────────────────────

    internal static class Program
    {
        private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";
        private const string FallbackEnvVar = "WPF_LINUX_TEXTLINE_FALLBACK";
        private const string CorpusRel = "/build/MilBridge/gen/layout-b34-compact.json";
        private const string InputsRel = "/build/MilBridge/tests/ProductEntryArm/inputs.json";
        private const string FontRel = "/build/fonts/NotoSans-Regular.ttf";

        /// <summary>被测例（判据对象）。</summary>
        private static readonly string[] Judge = { "M_modifier_w80", "M_modifier_w120", "M_modifier_w200", "M_modifier_w320", "M_modifier_winf" };

        /// <summary>阴性对照：同档位（AC=true ⇒ 不走 SimpleTextLine）、同字体、无 modifier ⇒ 必须**绿**。</summary>
        private static readonly string[] Control = { "F_lat_words_winf", "F_lat_words_w200", "F_lat_words_w80" };

        private static int s_ok, s_red, s_noinfo, s_judgedLines;
        private static string s_tierRequested = "auto", s_effectiveTier = "?";
        private static double s_tol = 0.05;
        private static string s_tamperCase = null, s_tamperField = "w";
        private static double s_tamperDelta;
        private static bool s_noModVariant;
        private static readonly StringBuilder Rows = new StringBuilder();

        private static string F6(double v) => v.ToString("F6", CultureInfo.InvariantCulture);

        private static int Main(string[] argv)
        {
            try { Console.OutputEncoding = Encoding.UTF8; } catch (Exception) { }

            for (int i = 0; i < argv.Length; ++i)
            {
                if (argv[i] == "--tier" && i + 1 < argv.Length) s_tierRequested = argv[++i];
                else if (argv[i] == "--tolerance" && i + 1 < argv.Length) s_tol = double.Parse(argv[++i], CultureInfo.InvariantCulture);
                else if (argv[i] == "--tamper" && i + 1 < argv.Length)   // <case>:<field>:<delta>  ⇒ **反极性**用
                {
                    string[] p = argv[++i].Split(':');
                    if (p.Length != 3) { Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=--tamper 要 <case>:<field>:<delta>"); return 2; }
                    s_tamperCase = p[0]; s_tamperField = p[1];
                    s_tamperDelta = double.Parse(p[2], CultureInfo.InvariantCulture);
                }
                else if (argv[i] == "--no-mod-variant") s_noModVariant = true;
                else if (argv[i] == "--help")
                {
                    Console.WriteLine("用法: ProductEntryArm [--tier auto|strict|lenient] [--tolerance DIP] "
                                      + "[--tamper <case>:<field>:<delta>] [--no-mod-variant]");
                    return 0;
                }
            }
            if (s_tierRequested != "auto" && s_tierRequested != "strict" && s_tierRequested != "lenient")
            { Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=--tier 取值非法：" + s_tierRequested); return 2; }

            Console.WriteLine("################ W31A · ProductEntryArm（走产品入口的 M_modifier 臂）################");
            Console.WriteLine("PEA_LANE=lane=W31A(instrument)");
            Console.WriteLine("PEA_ENTRY=System.Windows.Media.TextFormatting.TextFormatter.Create() + FormatLine  (public)");
            Console.WriteLine("PEA_WIRING=build/PresentationCore.Linux/TextFormatterImp.Linux.cs:694 -> "
                              + "WpfLinuxLenientTextFallback.TryFormatLine :329 CollectLenient -> :342 FormatParagraph");
            Console.WriteLine("PEA_SHIM  =build/shims/PresentationCore.HbTextLine.cs:2913（零宽拦位）/ :2916（kh 取值）"
                              + " / :3974（modifierScopeEnd 形参，缺省 -1）");
            Console.WriteLine("PEA_NOT-INSTRUMENT=本臂**不**调 HbTextLineFactory.FormatParagraph ⇒ 与 "
                              + "CoverageProbe --modifier-check 的路径**不同**（那条绕过 PC）");

            // ---------- 0) 档位转向（在拿任何读数之前钉死，并读回产品自己的开关自证） ----------
            string ambient = Environment.GetEnvironmentVariable(FallbackEnvVar);
            Console.WriteLine("PEA_TIERSEL env_before=" + (ambient ?? "<null>") + " requested=" + s_tierRequested);
            if (s_tierRequested == "lenient") Environment.SetEnvironmentVariable(FallbackEnvVar, "0");
            else if (s_tierRequested == "strict") Environment.SetEnvironmentVariable(FallbackEnvVar, null);
            Console.WriteLine("PEA_TIERSEL env_after=" + (Environment.GetEnvironmentVariable(FallbackEnvVar) ?? "<null>"));

            bool strictEnabled;
            try { strictEnabled = WpfLinux.Shims.PresentationCore.HbTextFallback.Enabled; }
            catch (Exception e)
            {
                Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=IVT 读不到产品层级开关 HbTextFallback.Enabled：" + e.GetType().Name);
                return 2;
            }
            s_effectiveTier = strictEnabled ? "strict" : "lenient";
            Console.WriteLine("PEA_TIER  product_switch_HbTextFallback.Enabled=" + (strictEnabled ? "true" : "false")
                              + " effective=" + s_effectiveTier);
            if (s_tierRequested == "strict" && !strictEnabled)
            { Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=要严格档但产品开关读 false ⇒ 转向未生效"); return 2; }
            if (s_tierRequested == "lenient" && strictEnabled)
            { Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=要宽松档但产品开关读 true ⇒ 转向未生效"); return 2; }

            // ---------- 1) 字体：**文件式** FontFamily，且必须解析到本仓那一份 ----------
            string fontPath = Path.GetFullPath(Root + FontRel);
            if (!File.Exists(fontPath))
            { Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=字体文件不存在：" + fontPath); return 2; }
            if (!TryFileFont(fontPath, out Typeface tf, out GlyphTypeface gt, out string fontWhy))
            { Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=文件式字体解析失败：" + fontWhy); return 2; }
            string gtPath = gt.FontUri != null && gt.FontUri.IsFile ? gt.FontUri.LocalPath : "<non-file>";
            Console.WriteLine("PEA_FONT  family_source=" + (tf.FontFamily != null ? tf.FontFamily.Source : "?")
                              + " resolved=" + gtPath + "#" + gt.FaceIndex);
            Console.WriteLine("PEA_FONT  font_file=" + fontPath + " sha16=" + Sha16(fontPath));
            if (!string.Equals(Path.GetFullPath(gtPath), fontPath, StringComparison.Ordinal))
            {
                Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=解析出来的面不是本仓那一份（got " + gtPath + "）"
                                  + " ⇒ 尺子不同，读数不可比（纪律 22）");
                return 2;
            }
            IDictionary<int, ushort> cmap = null;
            try { cmap = gt.CharacterToGlyphMap; } catch (Exception) { }
            if (cmap == null || cmap.Count == 0)
            { Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=取不到已解析面的 CharacterToGlyphMap ⇒ 覆盖闸无从判定"); return 2; }

            // ---------- 2) 语料 + 段落属性（两侧都读，**不猜**） ----------
            string corpusPath = Root + CorpusRel;
            if (!File.Exists(corpusPath)) { Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=语料不存在：" + corpusPath); return 2; }
            string inputsPath = Root + InputsRel;
            if (!File.Exists(inputsPath)) { Console.WriteLine("PEA_EXIT=NOINFO rc=2 原因=段落属性文件不存在：" + inputsPath); return 2; }
            Console.WriteLine("PEA_CORPUS=" + corpusPath + " sha16=" + Sha16(corpusPath));
            Console.WriteLine("PEA_INPUTS=" + inputsPath + " sha16=" + Sha16(inputsPath));

            JsonDocument corpus = JsonDocument.Parse(File.ReadAllText(corpusPath));
            JsonDocument inputs = JsonDocument.Parse(File.ReadAllText(inputsPath));
            Console.WriteLine("PEA_TRUTH_SRC=" + inputs.RootElement.GetProperty("source").GetString()
                              + " sha256=" + inputs.RootElement.GetProperty("sourceSha256").GetString());
            var truth = new Dictionary<string, JsonElement>(StringComparer.Ordinal);
            foreach (JsonElement c in corpus.RootElement.GetProperty("cases").EnumerateArray())
                truth[c.GetProperty("id").GetString()] = c;
            var pin = new Dictionary<string, JsonElement>(StringComparer.Ordinal);
            foreach (JsonProperty p in inputs.RootElement.GetProperty("inputs").EnumerateObject())
                pin[p.Name] = p.Value;

            // ---------- 3) 判据对象：5 个 M 例 ----------
            Console.WriteLine();
            Console.WriteLine("──── 判据对象（真值 = 真机 oracle，逐行对拍；容差 = " + F6(s_tol) + " DIP）────");
            foreach (string id in Judge) JudgeCase(id, truth, pin, tf, gt, cmap);

            // ---------- 4) 阴性对照：同档位路径、同字体、**无 modifier** ⇒ 必须绿 ----------
            Console.WriteLine();
            Console.WriteLine("──── 阴性对照（同档位 AC=true、同字体、无 modifier ⇒ 必须绿）────");
            foreach (string id in Control) JudgeCase(id, truth, pin, tf, gt, cmap);

            // ---------- 5) 装置内对照：**同一文本、同段落属性、只把 modifier 摘掉** ----------
            //   它不是真值判据（语料里没有"无 modifier"的同文本例 ⇒ 没有真值可比）
            //   ⇒ 只作**诊断**：证明"红的成因是 modifier 接线，而不是文本/字体/档位"。
            if (s_noModVariant)
            {
                Console.WriteLine();
                Console.WriteLine("──── 装置内诊断（**NOJUDGE**：无真值可比，只证明 modifier 是变量）────");
                foreach (string id in Judge) NoModVariant(id, truth, pin, tf, gt, cmap);
            }

            // ---------- 6) 汇总 ----------
            Console.WriteLine();
            Console.WriteLine("PEA_SUM cases=" + (Judge.Length + Control.Length)
                              + " lines_judged=" + s_judgedLines + " ok=" + s_ok + " red=" + s_red + " noinfo=" + s_noinfo);
            Console.WriteLine(Rows.ToString().TrimEnd('\n'));
            if (s_tamperCase != null)
                Console.WriteLine("PEA_TAMPER case~" + s_tamperCase + " field=" + s_tamperField
                                  + " delta=" + F6(s_tamperDelta) + "（**故意改真值** ⇒ 判据必须变红）");

            int rc;
            string verdict;
            if (s_noinfo > 0) { rc = 2; verdict = "NOINFO"; }
            else if (s_red > 0) { rc = 1; verdict = "RED"; }
            else { rc = 0; verdict = "OK"; }
            Console.WriteLine("PEA_EXIT=" + verdict + " rc=" + rc
                              + "（RED = 未登记红；NOINFO = 判不了，**绝不当绿** —— 纪律 21/27/28）");
            return rc;
        }

        // ─────────────────────────────────────────────────────────────────────

        private static void JudgeCase(string id, Dictionary<string, JsonElement> truth,
            Dictionary<string, JsonElement> pin, Typeface tf, GlyphTypeface gt, IDictionary<int, ushort> cmap)
        {
            if (!truth.TryGetValue(id, out JsonElement C))
            { Console.WriteLine("PEA_CASE case=" + id + " verdict=NOINFO why=语料里没有这个 id"); ++s_noinfo; return; }
            if (!pin.TryGetValue(id, out JsonElement P))
            { Console.WriteLine("PEA_CASE case=" + id + " verdict=NOINFO why=inputs.json 里没有这个 id"); ++s_noinfo; return; }

            string text = C.GetProperty("text").GetString();
            double em = C.GetProperty("fontSize").GetDouble();
            double maxW = P.GetProperty("maxWidth").GetDouble();
            int mS = C.TryGetProperty("modifierStart", out JsonElement e1) && e1.ValueKind != JsonValueKind.Null ? e1.GetInt32() : -1;
            int mE = C.TryGetProperty("modifierEnd", out JsonElement e2) && e2.ValueKind != JsonValueKind.Null ? e2.GetInt32() : -1;

            // 覆盖闸（与 PcLineOracle 同口径）：文本里有没有已解析面缺的字形？缺 ⇒ 真机会回退到别的面
            // ⇒ 我们这边不可比 ⇒ NOINFO（绝不发明真值）
            int missing = text.Count(ch => !cmap.ContainsKey(ch));
            if (missing > 0)
            {
                Console.WriteLine("PEA_CASE case=" + id + " verdict=NOINFO why=已解析面缺 " + missing
                                  + " 个字形 ⇒ 真机会走回退面，不可比");
                ++s_noinfo; return;
            }

            var pprops = MakePprops(P, tf, em);
            // ★ 正控取初值：证明"这一例真的走到了被测代码"，而不是"没跑到所以没红"（纪律 21/27/28）
            string diagBefore = LenientDiag();
            long strictHandledBefore = StrictHandled(), strictBailedBefore = StrictBailed();
            List<LineRow> lines; int consumed; string err;
            if (!Drive(text, em, maxW, mS, mE, pprops, gt, out lines, out consumed, out err))
            {
                Console.WriteLine("PEA_CASE case=" + id + " verdict=NOINFO why=FormatLine 驱动失败：" + err);
                Console.WriteLine("PEA_POSCTL case=" + id + " verdict=NOT-REACHED lenient=" + LenientDiag()
                                  + " ｜ 严格档 Handled 增量=" + (StrictHandled() - strictHandledBefore)
                                  + " Bailed 增量=" + (StrictBailed() - strictBailedBefore)
                                  + " LastBail=" + StrictLastBail());
                ++s_noinfo; return;
            }
            long dCall = Counter(LenientDiag(), "relaxedCalls=") - Counter(diagBefore, "relaxedCalls=");
            long dHandled = Counter(LenientDiag(), "relaxedHandled=") - Counter(diagBefore, "relaxedHandled=");
            long dStrict = StrictHandled() - strictHandledBefore;
            long dBail = StrictBailed() - strictBailedBefore;
            // ★ 正控口径 = "**某一档真的接手了**"（不是"必须是宽松档"）：
            //   · 带 modifier 的例：严格档 `TryCollect:4575` 必 bail（`TextModifier` 不是 `TextCharacters`）
            //     ⇒ **只有宽松档**能接手 ⇒ 正控 = `relaxedHandled` 涨；
            //   · 无 modifier 的对照例：严格档**正常接手** ⇒ `relaxedHandled` **本来就不该涨**
            //     （第一版把"必须是宽松档"当正控 ⇒ 三个对照例全被误判 `NOT-REACHED`/`NOINFO`；
            //      原始读数见报告 §3.2 —— 这是**仪器缺陷**，不是被测件的结论）。
            //   两档都不涨 ⇒ 说明读数来自 LineServices 那条路（Linux 上没有）⇒ 诚实 `NOINFO`。
            bool reached = dHandled > 0 || dStrict > 0;
            Console.WriteLine("PEA_POSCTL case=" + id + " lenient_calls+" + dCall + " lenient_handled+" + dHandled
                              + " strict_handled+" + dStrict + " strict_bailed+" + dBail
                              + " verdict=" + (reached ? (dHandled > 0 ? "REACHED(lenient)" : "REACHED(strict)") : "NOT-REACHED"));
            if (!reached)
            {
                Console.WriteLine("PEA_CASE case=" + id + " verdict=NOINFO why=正控未过（严格档与宽松档的 Handled 都没涨）"
                                  + " LastBail=" + StrictLastBail()
                                  + " ⇒ 本例**没有**走到被测代码 ⇒ 不许报绿/红（纪律 21/27/28）");
                ++s_noinfo; return;
            }

            JsonElement TL = C.GetProperty("lines");
            int truthLines = TL.GetArrayLength();
            Console.WriteLine("PEA_CASE case=" + id + " text_len=" + text.Length + " maxWidth=" + F6(maxW)
                              + " mod=[" + mS + "," + mE + ") truthLines=" + truthLines + " ourLines=" + lines.Count
                              + " truthConsumed=" + C.GetProperty("consumed").GetInt32() + " ourConsumed=" + consumed
                              + (truthLines != lines.Count || C.GetProperty("consumed").GetInt32() != consumed
                                 ? "  ⚠️ 行数/消费长度不符" : ""));

            int li = 0;
            foreach (JsonElement E in TL.EnumerateArray())
            {
                if (li >= lines.Count) break;
                LineRow L = lines[li];
                // ★ 反极性：`--tamper` **改的是真值**（不是我们的读数）⇒ 判据必须变红
                double tW = E.GetProperty("w").GetDouble();
                double tWitw = E.GetProperty("witw").GetDouble();
                double tExt = E.GetProperty("ext").GetDouble();
                if (s_tamperCase != null && id.IndexOf(s_tamperCase, StringComparison.Ordinal) >= 0)
                {
                    if (s_tamperField == "w") tW += s_tamperDelta;
                    else if (s_tamperField == "witw") tWitw += s_tamperDelta;
                    else if (s_tamperField == "ext") tExt += s_tamperDelta;
                }
                JudgeInt(id, li, "len", L.Length, E.GetProperty("len").GetInt32());
                JudgeInt(id, li, "nl", L.NewlineLength, E.GetProperty("nl").GetInt32());
                JudgeInt(id, li, "ws", L.TrailingWhitespaceLength, E.GetProperty("ws").GetInt32());
                JudgeReal(id, li, "w", L.Width, tW);
                JudgeReal(id, li, "witw", L.WidthIncludingTrailingWhitespace, tWitw);
                JudgeReal(id, li, "ext", L.Extent, tExt);
                bool ourLb = L.LineBreakIsNull;
                bool tLb = E.GetProperty("lbNull").GetBoolean();
                ++s_judgedLines;
                if (ourLb == tLb) { ++s_ok; Console.WriteLine(Row(id, li, "lbNull", ourLb.ToString(), tLb.ToString(), "-", "OK")); }
                else
                {
                    ++s_red;
                    Console.WriteLine(Row(id, li, "lbNull", ourLb.ToString(), tLb.ToString(), "-", "RED"));
                }
                // 语料有、但我们不判的列 ⇒ 明确标 NOJUDGE（纪律 22：不发明真值）
                Console.WriteLine("PEA_LINE case=" + id + " k=" + li + " field=dep ours=" + L.DependentLength
                                  + " truth=" + E.GetProperty("dep").GetInt32() + " verdict=NOJUDGE(本轮不判)");
                ++li;
            }
            if (li < lines.Count)
            {
                ++s_red;
                Console.WriteLine("PEA_CASE case=" + id + " verdict=RED why=我方多出 " + (lines.Count - li)
                                  + " 行（真值只有 " + truthLines + " 行）");
            }
            else if (lines.Count < truthLines)
            {
                // ⚠️ **反方向也要点名**（第一版只查了"多出"）：我方行数**少于**真值 ⇒ 有真值行
                //    根本没被排出来（本臂第一趟就是这样：零宽把整段吞成一行）。
                int missingLines = truthLines - lines.Count;
                s_red += missingLines;
                Console.WriteLine("PEA_CASE case=" + id + " verdict=RED why=我方**少** " + missingLines
                                  + " 行（真值 " + truthLines + " 行、我方 " + lines.Count + " 行）"
                                  + " ⇒ 有真值行没被排出来");
                for (int k = lines.Count; k < truthLines; ++k)
                    Console.WriteLine("PEA_LINE case=" + id + " k=" + k + " field=<ALL> ours=<无此行使> truth=<真值第"
                                      + k + "行> delta=- verdict=RED(缺行)");
            }
        }

        /// <summary>同一文本、同段落属性，**只把 modifier 摘掉** ⇒ 打印（不判）。</summary>
        private static void NoModVariant(string id, Dictionary<string, JsonElement> truth,
            Dictionary<string, JsonElement> pin, Typeface tf, GlyphTypeface gt, IDictionary<int, ushort> cmap)
        {
            if (!truth.TryGetValue(id, out JsonElement C) || !pin.TryGetValue(id, out JsonElement P)) return;
            string text = C.GetProperty("text").GetString();
            double em = C.GetProperty("fontSize").GetDouble();
            double maxW = P.GetProperty("maxWidth").GetDouble();
            var pprops = MakePprops(P, tf, em);
            List<LineRow> lines; int consumed; string err;
            if (!Drive(text, em, maxW, -1, -1, pprops, gt, out lines, out consumed, out err))
            { Console.WriteLine("PEA_NOMOD case=" + id + " verdict=NOINFO why=" + err); return; }
            Console.WriteLine("PEA_NOMOD case=" + id + " lines=" + lines.Count
                              + " totalWidth=" + F6(lines.Sum(l => l.Width))
                              + " ｜ 带 modifier 真值 totalWidth="
                              + F6(truth[id].GetProperty("lines").EnumerateArray().Sum(l => l.GetProperty("w").GetDouble()))
                              + "  verdict=NOJUDGE(无真值)");
        }

        private static TextParagraphProperties MakePprops(JsonElement P, Typeface tf, double em)
        {
            string culture = P.GetProperty("culture").GetString();
            var props = new ArmRunProperties(tf, em, CultureInfo.GetCultureInfo(culture), 1.0);
            return new ArmParagraphProperties(
                props,
                (FlowDirection)Enum.Parse(typeof(FlowDirection), P.GetProperty("flowDirection").GetString()),
                (TextAlignment)Enum.Parse(typeof(TextAlignment), P.GetProperty("textAlignment").GetString()),
                (TextWrapping)Enum.Parse(typeof(TextWrapping), P.GetProperty("textWrapping").GetString()),
                P.GetProperty("lineHeight").ValueKind == JsonValueKind.Null ? 0.0 : P.GetProperty("lineHeight").GetDouble(),
                P.GetProperty("firstLineInParagraph").GetBoolean(),
                P.GetProperty("indent").GetDouble(),
                P.GetProperty("paragraphIndent").GetDouble(),
                P.GetProperty("alwaysCollapsible").GetBoolean());
        }

        // ─────────────────────────────────────────────────────────────────────
        //  ★ **产品入口**：这一段是"不走仪器路径"这句话的全部内容。
        //    调用序列逐字照真机宿主 `Runner.cs:176-212`（WPF TextBlock 的标准姿势）：
        //      cache = new TextRunCache(); brk = null;
        //      line = formatter.FormatLine(src, index, W, pprops, brk, cache);
        //      brk  = line.GetTextLineBreak();   // 逐行串接（不串 ⇒ TextLineBreak 恒 null）
        // ─────────────────────────────────────────────────────────────────────
        private static bool Drive(string text, double em, double maxW, int mS, int mE,
            TextParagraphProperties pprops, GlyphTypeface gt,
            out List<LineRow> lines, out int consumed, out string err)
        {
            lines = new List<LineRow>(); consumed = 0; err = null;
            Typeface tf = pprops.DefaultTextRunProperties.Typeface;
            var rp = new ArmRunProperties(tf, em, pprops.DefaultTextRunProperties.CultureInfo, 1.0);
            var source = new ArmTextSource(text, rp, mS, mE);
            TextFormatter formatter;
            try { formatter = TextFormatter.Create(TextFormattingMode.Ideal); }
            catch (Exception e) { err = "TextFormatter.Create 抛 " + e.GetType().Name + ": " + e.Message; return false; }
            if (formatter == null) { err = "TextFormatter.Create 返回 null"; return false; }

            var cache = new TextRunCache();
            TextLineBreak brk = null;
            int index = 0, guard = 0;
            while (index < text.Length)
            {
                if (++guard > text.Length + 8) { err = "断行不收敛 index=" + index; return false; }
                TextLine line;
                try { line = formatter.FormatLine(source, index, maxW, pprops, brk, cache); }
                catch (Exception e) { err = "FormatLine 抛 " + e.GetType().Name + ": " + e.Message; return false; }
                if (line == null) { err = "FormatLine 返回 null（index=" + index + "）"; return false; }
                if (line.Length <= 0) { err = "零长度行（index=" + index + "）⇒ 会死循环"; return false; }
                lines.Add(new LineRow
                {
                    Length = line.Length,
                    Width = line.Width,
                    WidthIncludingTrailingWhitespace = line.WidthIncludingTrailingWhitespace,
                    Extent = line.Extent,
                    NewlineLength = line.NewlineLength,
                    TrailingWhitespaceLength = line.TrailingWhitespaceLength,
                    DependentLength = line.DependentLength,
                    LineBreakIsNull = line.GetTextLineBreak() == null,
                });
                index += line.Length;
                consumed = index;
                brk = line.GetTextLineBreak();
            }
            return true;
        }

        private sealed class LineRow
        {
            public int Length, NewlineLength, TrailingWhitespaceLength, DependentLength;
            public double Width, WidthIncludingTrailingWhitespace, Extent;
            public bool LineBreakIsNull;
        }

        // ── 判据：整数精确相等 ──
        private static void JudgeInt(string id, int k, string field, int ours, int truth)
        {
            ++s_judgedLines;
            bool ok = ours == truth;
            if (ok) ++s_ok; else ++s_red;
            Console.WriteLine(Row(id, k, field, ours.ToString(CultureInfo.InvariantCulture),
                                  truth.ToString(CultureInfo.InvariantCulture),
                                  (ours - truth).ToString(CultureInfo.InvariantCulture), ok ? "OK" : "RED"));
        }

        // ── 判据：实数容差内 ──
        private static void JudgeReal(string id, int k, string field, double ours, double truth)
        {
            ++s_judgedLines;
            double d = ours - truth;
            bool ok = Math.Abs(d) <= s_tol;
            if (ok) ++s_ok; else ++s_red;
            Console.WriteLine(Row(id, k, field, F6(ours), F6(truth), F6(d), ok ? "OK" : "RED"));
        }

        private static string Row(string id, int k, string field, string ours, string truth, string delta, string verdict)
        {
            string s = "PEA_LINE case=" + id + " k=" + k + " field=" + field + " ours=" + ours
                       + " truth=" + truth + " delta=" + delta + " verdict=" + verdict;
            if (verdict == "RED") Rows.AppendLine("PEA_REDROW " + s.Substring(9));
            return s;
        }

        // ── 文件式字体：`new FontFamily(baseUri, "./<file>#<family>")`（仓内先例
        //    `CompositeFontProbe/Program.cs:262`）。**绝不**退回"随便找个装了同名的族"
        //    —— 那会换掉尺子（真值用的是这一份 ttf）。 ──
        private static bool TryFileFont(string fontPath, out Typeface tf, out GlyphTypeface gt, out string why)
        {
            tf = null; gt = null; why = "-";
            try
            {
                string dir = Path.GetDirectoryName(fontPath) + "/";
                var baseUri = new Uri("file://" + dir);
                var family = new FontFamily(baseUri, "./" + Path.GetFileName(fontPath) + "#Noto Sans");
                tf = new Typeface(family, FontStyles.Normal, FontWeights.Normal, FontStretches.Normal);
                if (!tf.TryGetGlyphTypeface(out gt) || gt == null) { why = "TryGetGlyphTypeface=false（baseUri=" + baseUri + "）"; return false; }
                return true;
            }
            catch (Exception e) { why = e.GetType().Name + ": " + e.Message; return false; }
        }

        // ── 正控：IVT 读产品自己的计数器（**直接字段访问**：改了名 ⇒ 编译期 `error CS`，
        //    不是运行期悄悄 NA ⇒ "它们还在不在"这件事本身是编译期证据） ──
        private static string LenientDiag()
        {
            try { return MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics; }
            catch (Exception e) { return "<IVT 读不到: " + e.GetType().Name + ">"; }
        }
        private static long StrictHandled() { try { return WpfLinux.Shims.PresentationCore.HbTextFallback.Handled; } catch (Exception) { return -1; } }
        private static long StrictBailed() { try { return WpfLinux.Shims.PresentationCore.HbTextFallback.Bailed; } catch (Exception) { return -1; } }
        private static string StrictLastBail()
        {
            try { return WpfLinux.Shims.PresentationCore.HbTextFallback.LastBail; } catch (Exception) { return "-"; }
        }
        /// <summary>从 `key=value` 串里取整数（取不到 ⇒ -1 ⇒ 调用点会打成 NOT-REACHED，绝不静默当 0）。</summary>
        private static long Counter(string diag, string key)
        {
            if (string.IsNullOrEmpty(diag)) return -1;
            int i = diag.IndexOf(key, StringComparison.Ordinal);
            if (i < 0) return -1;
            int j = i + key.Length, k = j;
            while (k < diag.Length && char.IsDigit(diag[k])) ++k;
            if (k == j) return -1;
            long v; return long.TryParse(diag.Substring(j, k - j), out v) ? v : -1;
        }

        private static string Sha16(string path)
        {
            try
            {
                using (var sha = System.Security.Cryptography.SHA256.Create())
                using (FileStream fs = File.OpenRead(path))
                {
                    byte[] h = sha.ComputeHash(fs);
                    var sb = new StringBuilder();
                    for (int i = 0; i < 8; ++i) sb.Append(h[i].ToString("x2"));
                    return sb.ToString();
                }
            }
            catch (Exception e) { return "<" + e.GetType().Name + ">"; }
        }
    }
}

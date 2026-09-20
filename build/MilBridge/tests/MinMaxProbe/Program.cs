// W17D · **PC 公开 min/max 入口的判据臂**（`WAVE17-PREREGISTRATION.md` §1 P3 的红证仪器）
// =====================================================================================
//   dotnet PresentationCore.Tests.dll --case <id> --phase <prefix|postfix>
//     case  ∈ control | mod0 | mod1   （mod1 = TDT2 §2.5 设计的形态）
//     phase ∈ prefix（修前）| postfix（修后）
//
// 【它回答的问题（P3）】
//   生成物 `TextFormatterImp.Linux.cs` 的宽松层 `TryMinMaxParagraphWidth` 里，
//   **max 探针**传了 `modifierOpenIndex/modifierCloseIndex`（`:307`），**min 探针一个都不传**（`:313`）
//   ⇒ 两个探针不是同一把尺子。本臂构造一个 `modifierOpenIndex >= 0` 的段落，
//   读出修前的 `min`/`max`，判据 = **`min > max`（真机契约不允许）**；修后应 **`min == max`**。
//
// 【为什么必须这么构造（本臂的关键发明，逐条有代码依据）】
//   · 宽松层的 `CollectLenient`（生成物 `:101-103`）**只**在 `run is TextModifier` 时记 `modifierOpenIndex`；
//   · 但它先调 `ExtractRun(run)`（生成物 `:81-91`），而 `TextModifier.CharacterBufferReference` 是
//     **`sealed override` 返回 `default`**（上游 `TextModifier.cs:25-28`）⇒ `CharacterBuffer == null`
//     ⇒ `ExtractRun` 返回 **null** ⇒ `CollectLenient` **直接 return false**（生成物 `:148-152`）。
//   · 唯一不走 null 分支的形态 = `run.Length <= 0`（`ExtractRun` 的**第一行**就 `return string.Empty`）
//     ⇒ 本臂的 `ZeroLenModifier`（`Length => 0`）。
//   · 零长 run 不推进 `cp`（`cp += run.Length`）⇒ **文本源必须在同一个 `cp` 上第二次给出正文**
//     （真实契约允许：run 是"该下标的 run"，零宽标记不消费字符）。
//   · 严格层**不会**先把它吃掉：`WPF_LINUX_TEXTLINE_FALLBACK=0` ⇒ `HbTextFallback.Enabled == false`
//     （shim `:4009-4016`）⇒ `HbTextFallback.TryMinMaxParagraphWidth` 在**碰文本源之前**就 `return false`
//     （shim `:4577`）⇒ `GetTextRun` 的**第一次调用**只可能来自宽松层。**本臂印调用序自证这一点。**
//
// 【它**不**回答什么（诚实清单）】
//   · 真机 `MinWidth`/`MaxWidth` 的**数值真值不存在**（`tests/parity/windows/**/*.json` 30 份无 min/max 字段，
//     TDT2 §3.2③）⇒ 本臂**不比对真值**，只判"两个探针是否同一把尺子"这一条**内部一致性**契约；
//   · 修好之后两边**都**是 `[open, 段末)` 的零宽跨度（R17A §2.2 判定：尺子本身仍错）⇒ 本臂**不**宣称
//     "对齐真机"，`D-T2-c` 另立登记；
//   · 本臂**不是**五臂门禁成员，**不进** `verify-all`（P3 只要求它可判红）。
//
// 【rc 语义（不许报绿）】
//   0 = 请求的用例都测到，且与 `--phase` 声明的**期望形态**一致；
//   1 = 测到但与期望形态**不一致**（判据红）；
//   2 = `NOINFO`（tier 转向未生效 / 字体面解析失败 / 抛异常 / 正控说"被测代码没被走到"）。
//   ⚠️ 进程被 **abort**（非 0 的 128+n，如 134=SIGABRT）**不是**本臂的判据 —— 那是"交回 LS"的现场，
//      由外壳按"哪一类"分类（纪律：非 0 退出码先分类）。
// =====================================================================================

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Text;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace MilBridge.MinMaxProbe
{
    /// <summary>`TextRunProperties` 最小实现。⚠️ `ForegroundBrush` **必须 null**：
    /// `Brushes.Black` 的静态构造要建 HwndWrapper ⇒ 无 X 时抛（PcLineOracle 实测踩到）。</summary>
    internal sealed class MmRunProperties : TextRunProperties
    {
        private readonly Typeface _tf; private readonly double _em;
        internal MmRunProperties(Typeface tf, double em) { _tf = tf; _em = em; }
        public override Typeface Typeface => _tf;
        public override double FontRenderingEmSize => _em;
        public override double FontHintingEmSize => _em;
        public override CultureInfo CultureInfo => CultureInfo.InvariantCulture;
        public override Brush ForegroundBrush => null;
        public override Brush BackgroundBrush => null;
        public override TextDecorationCollection TextDecorations => null;
        public override TextEffectCollection TextEffects => null;
    }

    /// <summary>`TextParagraphProperties` 最小实现（缩进全 0 ⇒ 不引入 P2 的位移）。</summary>
    internal sealed class MmPara : TextParagraphProperties
    {
        private readonly TextRunProperties _props;
        internal MmPara(TextRunProperties props) { _props = props; }
        public override TextRunProperties DefaultTextRunProperties => _props;
        public override FlowDirection FlowDirection => FlowDirection.LeftToRight;
        public override TextAlignment TextAlignment => TextAlignment.Left;
        public override TextWrapping TextWrapping => TextWrapping.Wrap;
        public override double LineHeight => 0;
        public override bool FirstLineInParagraph => true;
        public override double Indent => 0;
        public override double ParagraphIndent => 0;
        public override bool AlwaysCollapsible => true;
        public override TextDecorationCollection TextDecorations => null;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override IList<TextTabProperties> Tabs => null;
    }

    /// <summary>**零长** `TextModifier`：唯一能被 `CollectLenient` 收下的 modifier 形态（见文件头推演）。</summary>
    internal sealed class ZeroLenModifier : TextModifier
    {
        private readonly TextRunProperties _props;
        internal ZeroLenModifier(TextRunProperties props) { _props = props; }
        public override int Length => 0;
        public override TextRunProperties Properties => _props;
        public override TextRunProperties ModifyProperties(TextRunProperties p) => p;
        public override bool HasDirectionalEmbedding => false;
        public override FlowDirection FlowDirection => FlowDirection.LeftToRight;
    }

    /// <summary>TDT2 §2.5 设计的形态（`Length = 1`）—— 用来**实测**它到底能不能到被测代码。</summary>
    internal sealed class LenOneModifier : TextModifier
    {
        private readonly TextRunProperties _props;
        internal LenOneModifier(TextRunProperties props) { _props = props; }
        public override int Length => 1;
        public override TextRunProperties Properties => _props;
        public override TextRunProperties ModifyProperties(TextRunProperties p) => p;
        public override bool HasDirectionalEmbedding => false;
        public override FlowDirection FlowDirection => FlowDirection.LeftToRight;
    }

    /// <summary>带 modifier 的文本源。`GetTextRun` 的**每一次调用都进 trace**（可复算）。</summary>
    internal sealed class ModSource : TextSource
    {
        private readonly string _text; private readonly TextRunProperties _props;
        private readonly bool _zeroLen; private readonly int _modAtCp;
        private bool _modEmitted;
        internal readonly List<string> Trace = new List<string>();
        internal int CharsRuns, ModRuns, EopRuns, NullRuns;

        internal ModSource(string text, TextRunProperties props, int modAtCp, bool zeroLen)
        {
            _text = text; _props = props; _modAtCp = modAtCp; _zeroLen = zeroLen;
            PixelsPerDip = 1.0;
        }

        public override TextRun GetTextRun(int cp)
        {
            if (cp < 0)
            {
                ++NullRuns; Trace.Add("cp=" + cp + "->null");
                return null;
            }
            if (cp >= _text.Length)
            {
                ++EopRuns; Trace.Add("cp=" + cp + "->TextEndOfParagraph(1)");
                return new TextEndOfParagraph(1);
            }
            if (cp == _modAtCp && !_modEmitted)
            {
                _modEmitted = true; ++ModRuns;
                int len = _zeroLen ? 0 : 1;
                Trace.Add("cp=" + cp + "->" + (_zeroLen ? "ZeroLenModifier" : "LenOneModifier")
                           + "(Length=" + len + ")");
                return _zeroLen ? (TextRun)new ZeroLenModifier(_props) : new LenOneModifier(_props);
            }
            ++CharsRuns;
            Trace.Add("cp=" + cp + "->TextCharacters(\"" + _text.Substring(cp) + "\"," + cp + ","
                       + (_text.Length - cp) + ")");
            return new TextCharacters(_text, cp, _text.Length - cp, _props);
        }

        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
            => new TextSpan<CultureSpecificCharacterBufferRange>(0,
                   new CultureSpecificCharacterBufferRange(CultureInfo.InvariantCulture, CharacterBufferRange.Empty));
        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
    }

    internal static class Program
    {
        private const string FallbackEnvVar = "WPF_LINUX_TEXTLINE_FALLBACK";
        private const string FontFamilyName = "Liberation Sans";
        private const string Text = "WWWW";

        private static string F(double v) => v.ToString("F6", CultureInfo.InvariantCulture);

        private static int Main(string[] argv)
        {
            try { Console.OutputEncoding = Encoding.UTF8; } catch (Exception) { }

            string kase = null, phase = null;
            for (int i = 0; i < argv.Length; ++i)
            {
                if (argv[i] == "--case" && i + 1 < argv.Length) kase = argv[++i];
                else if (argv[i] == "--phase" && i + 1 < argv.Length) phase = argv[++i];
            }

            Console.WriteLine("==================== W17D · MinMaxProbe（驱动 PC 的 FormatMinMaxParagraphWidth）====================");
            Console.WriteLine("lane        = W17D");
            Console.WriteLine("entrypoint  = System.Windows.Media.TextFormatting.TextFormatter.Create() + FormatMinMaxParagraphWidth  (public)");
            Console.WriteLine("被测接线点  = build/PresentationCore.Linux/TextFormatterImp.Linux.cs 的 WpfLinuxLenientTextFallback.TryMinMaxParagraphWidth");
            Console.WriteLine("time        = " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture) + " " + TimeZoneInfo.Local.Id);
            Console.WriteLine("kernel      = " + SafeRead("/proc/sys/kernel/osrelease").Trim());
            Console.WriteLine("loadavg     = " + SafeRead("/proc/loadavg").Trim());
            Console.WriteLine("MemAvailable= " + MemAvailableKb() + " kB");
            Console.WriteLine("文本        = \"" + Text + "\"  em=24  font=" + FontFamilyName + "（与三支 tab 臂/ W17A 臂同一把尺子）");
            Console.WriteLine("case        = " + (kase ?? "<未给>") + "   phase = " + (phase ?? "<未给>"));
            Console.WriteLine("PREDICT mod0/prefix : min≈(W 的 advance @em24) > max=0.000000  ⇒ rel=gt");
            Console.WriteLine("PREDICT mod0/postfix: min=0.000000 = max=0.000000            ⇒ rel=eq");
            Console.WriteLine("PREDICT control（两相）: min ≤ max（无 modifier ⇒ 两个探针参数等价）⇒ rel=lt");

            if (kase == null || phase == null)
            {
                Console.WriteLine("MINMAX_EXIT=NOINFO rc=2 原因=必须给 --case <control|mod0|mod1> 与 --phase <prefix|postfix>");
                return 2;
            }

            // ---------- 0) tier 转向：**在拿任何读数之前**，并自证生效 ----------
            Environment.SetEnvironmentVariable(FallbackEnvVar, "0");
            string fb = Environment.GetEnvironmentVariable(FallbackEnvVar);
            Console.WriteLine("TierSteer   : 设 " + FallbackEnvVar + "=0 ；读回=" + (fb ?? "<null>")
                              + " ⇒ " + (fb == "0" ? "OK（`HbTextFallback.Enabled==false` ⇒ 严格层在碰文本源之前就 return false）"
                                                   : "**未生效** ⇒ NOINFO，不许报绿"));
            if (fb != "0")
            {
                Console.WriteLine("MINMAX_EXIT=NOINFO rc=2 原因=tier 转向未生效");
                return 2;
            }

            // ---------- 1) 归属：印**已加载**那一份 pc 的 sha16 ----------
            string pcPath = null, pcSha = null; long pcBytes = 0;
            try
            {
                pcPath = Assembly.GetAssembly(typeof(TextFormatter)).Location;
                var fi = new FileInfo(pcPath);
                pcBytes = fi.Length;
                using (var sha = System.Security.Cryptography.SHA256.Create())
                using (var fs = File.OpenRead(pcPath))
                    pcSha = BitConverter.ToString(sha.ComputeHash(fs)).Replace("-", "").Substring(0, 16).ToLowerInvariant();
            }
            catch (Exception e) { Console.WriteLine("pc          : <读不到: " + e.GetType().Name + ">"); }
            Console.WriteLine("pc(已加载)  = " + pcPath + "  sha16=" + pcSha + "  bytes=" + pcBytes);

            // ---------- 2) 字体 ----------
            Typeface tf = null;
            try { tf = new Typeface(new FontFamily(FontFamilyName), FontStyles.Normal, FontWeights.Normal, FontStretches.Normal); }
            catch (Exception e) { Console.WriteLine("font        : Typeface 构造抛 " + e.GetType().Name + ": " + e.Message); }
            GlyphTypeface gt = null;
            if (tf != null) { try { tf.TryGetGlyphTypeface(out gt); } catch (Exception) { } }
            if (gt == null)
            {
                Console.WriteLine("MINMAX_EXIT=NOINFO rc=2 原因=字体面解析失败（family=" + FontFamilyName + "）");
                return 2;
            }
            Console.WriteLine("font        = " + FontFamilyName + " → " + (gt.FontUri != null && gt.FontUri.IsFile ? gt.FontUri.LocalPath : "<non-file>")
                              + "#" + gt.FaceIndex);

            var props = new MmRunProperties(tf, 24.0);
            var para = new MmPara(props);

            TextFormatter formatter;
            try { formatter = TextFormatter.Create(); }
            catch (Exception e)
            {
                Console.WriteLine("MINMAX_EXIT=NOINFO rc=2 原因=TextFormatter.Create() 抛 " + e.GetType().Name + ": " + e.Message);
                return 2;
            }
            if (formatter == null)
            {
                Console.WriteLine("MINMAX_EXIT=NOINFO rc=2 原因=TextFormatter.Create() 返回 null");
                return 2;
            }

            int modAt = 0; bool zeroLen = true;
            if (kase == "control") { modAt = -1; }          // ⚠️ 阴性对照必须**真的没有** modifier（modAt=-1 永不命中）
            else if (kase == "mod0") { modAt = 0; zeroLen = true; }
            else if (kase == "mod1") { modAt = 0; zeroLen = false; }
            else
            {
                Console.WriteLine("MINMAX_EXIT=NOINFO rc=2 原因=未知 --case " + kase);
                return 2;
            }

            var src = new ModSource(Text, props, modAt, zeroLen);
            string diagBefore = Diag();
            Console.WriteLine("DIAG before = " + diagBefore);

            MinMaxParagraphWidth mm = default(MinMaxParagraphWidth);
            bool got = false;
            string exc = null;
            var sw = Stopwatch.StartNew();
            try { mm = formatter.FormatMinMaxParagraphWidth(src, 0, para); got = true; }
            catch (Exception e) { exc = e.GetType().Name + ": " + e.Message; }
            sw.Stop();

            string diagAfter = Diag();
            Console.WriteLine("DIAG after  = " + diagAfter);
            Console.WriteLine("GETTEXTRUN 调用序（" + src.Trace.Count + " 次；chars=" + src.CharsRuns
                              + " mod=" + src.ModRuns + " eop=" + src.EopRuns + " null=" + src.NullRuns + "）：");
            for (int i = 0; i < src.Trace.Count && i < 24; ++i) Console.WriteLine("   #" + i + " " + src.Trace[i]);
            if (src.Trace.Count > 24) Console.WriteLine("   …（截断，共 " + src.Trace.Count + " 次）");
            Console.WriteLine("elapsed_ms  = " + sw.ElapsedMilliseconds);

            if (exc != null || !got)
            {
                Console.WriteLine("MINMAX CASE " + kase + " EXCEPTION " + exc);
                Console.WriteLine("MINMAX CASE " + kase + " RESULT min=NA max=NA rel=NA verdict=NOINFO（异常 ⇒ 未测到）");
                Console.WriteLine("MINMAX_EXIT=NOINFO rc=2 原因=FormatMinMaxParagraphWidth 抛异常（见上）");
                return 2;
            }

            double min = mm.MinWidth, max = mm.MaxWidth;
            string rel = min > max + 1e-9 ? "gt" : (Math.Abs(min - max) <= 1e-9 ? "eq" : "lt");
            Console.WriteLine("MINMAX CASE " + kase + " RESULT min=" + F(min) + " max=" + F(max) + " rel=" + rel
                              + " min_minus_max=" + F(min - max));

            // ---------- 3) 正控：宽松层的 minmax 真的被走到了？ ----------
            int dc = DiagCounter(diagAfter, "relaxedCalls=") - DiagCounter(diagBefore, "relaxedCalls=");
            int dh = DiagCounter(diagAfter, "relaxedHandled=") - DiagCounter(diagBefore, "relaxedHandled=");
            int ds = DiagCounter(diagAfter, "relaxedSkippedRuns=") - DiagCounter(diagBefore, "relaxedSkippedRuns=");
            Console.WriteLine("正控 增量   = relaxedCalls+" + dc + " relaxedHandled+" + dh + " relaxedSkippedRuns+" + ds);
            if (!(dc >= 1 && dh >= 1))
            {
                Console.WriteLine("MINMAX_EXIT=NOINFO rc=2 原因=正控失败（宽松层 minmax 未被走到：calls+" + dc + " handled+" + dh + "）");
                return 2;
            }

            // ---------- 4) 判据 ----------
            string expect = (kase == "control") ? "lt" : (phase == "prefix" ? "gt" : "eq");
            string verdict = (rel == expect) ? "GREEN" : "RED";
            Console.WriteLine("MINMAX CASE " + kase + " 判据 phase=" + phase + " expect rel=" + expect
                              + " measured=" + rel + " ⇒ " + verdict);
            if (kase == "mod1")
            {
                // mod1（Length=1）是 TDT2 设计的形态：它的命运本身就是一条读数（见报告 §6），不参与 rc
                Console.WriteLine("MINMAX CASE mod1 注：Length=1 的 `TextModifier` 的 `CharacterBufferReference` 是 sealed default"
                                  + " ⇒ `ExtractRun` 返回 null ⇒ `CollectLenient` return false（生成物 :148-152）"
                                  + " ⇒ 本形态**到不了**被测代码（trace 与 DIAG 增量即证据）");
            }
            Console.WriteLine("MINMAX_EXIT rc=" + (verdict == "GREEN" ? 0 : 1)
                              + "（case=" + kase + " phase=" + phase + " measured=" + rel + " expect=" + expect + "）");
            return verdict == "GREEN" ? 0 : 1;
        }

        private static string Diag()
        {
            try { return MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics; }
            catch (Exception e) { return "<IVT 读不到: " + e.GetType().Name + ": " + e.Message + ">"; }
        }

        private static int DiagCounter(string diag, string key)
        {
            int i = diag.IndexOf(key, StringComparison.Ordinal);
            if (i < 0) return int.MinValue / 2;
            i += key.Length; int j = i;
            while (j < diag.Length && diag[j] >= '0' && diag[j] <= '9') ++j;
            int v; return int.TryParse(diag.Substring(i, j - i), out v) ? v : int.MinValue / 2;
        }

        private static string SafeRead(string p)
        { try { return File.ReadAllText(p); } catch (Exception) { return "<读不到>"; } }

        private static string MemAvailableKb()
        {
            try
            {
                foreach (string l in File.ReadAllLines("/proc/meminfo"))
                    if (l.StartsWith("MemAvailable:", StringComparison.Ordinal))
                        return l.Substring(13).Replace("kB", "").Trim();
            }
            catch (Exception) { }
            return "<读不到>";
        }
    }
}

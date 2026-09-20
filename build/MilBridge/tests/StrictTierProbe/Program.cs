// W20A · **`D-T6` 定性探针**（`docs/WAVE20-PREREGISTRATION.md` §1 的「决定性实验」仪器）
// =====================================================================================
//   dotnet PresentationCore.Tests.dll --corpus <tab-anchor-oracle.json> --case <id>
//                                    [--tier strict|lenient] [--fresh-source]
//
// 它做什么（逐个返回行 dump，而不是判分）：
//   1. 用 PC 的 `TextFormatter.Create()+FormatLine` 驱动**同一条用例**（客户端按 `Length` 累加，
//      与 oracle 宿主 `tab-anchor/src/Program.cs` 同一个循环形状）；
//   2. 每个返回行打印：`Length` / `Start` / `Width` / `NewlineLength` / `TrailingWhitespaceLength` /
//      `HasOverflowed` / 可见文本 / `GetTextRunSpans()` / `GetIndexedGlyphRuns()` 的段落系起点 /
//      `GetCharacterHitFromDistance(0)`；
//   3. **两种索引口径同时读** `GetTextBounds`，逐字打印：
//        · 「行内读法」= `GetTextBounds(j, 1)`（`PcLineOracle` 今天用的那一种）；
//        · 「段落系读法」= `GetTextBounds(cpFirst+j, 1)`（真机 oracle 宿主用的那一种，
//          `tests/parity/windows/tab-anchor/src/Program.cs:512-514`：`int gi = lineStart + i;`）；
//   4. **帧扫描**（不依赖任何约定）：在 `0..text.Length` 上找**最小的** `a`，使
//      `GetTextBounds(a,1)` 给出非空 `TextRunBounds` —— 那就是本行自己的**帧原点**；
//   5. `--fresh-source`：**每次 `FormatLine` 都新建 `TextSource`** ⇒ 严格档的 `ParaCache`
//      （键 = `ReferenceEquals(Source, textSource) && Contains(cpFirst)`，shim `:4531-4536`）**必不命中**
//      —— 这是预登记 §1 实验 2「缓存专项」不碰 shim 的实现方式。
//
// 它**不**判分、**不**写任何判据表：定性结论由 `PcLineOracle` 的守卫与 `W20A-report.md` 给。
// =====================================================================================

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace MilBridge.StrictTierProbe
{
    internal sealed class MockTextSource : TextSource
    {
        private readonly TextRunProperties _props;
        internal MockTextSource(string text, TextRunProperties props) { Text = text; _props = props; }
        internal string Text { get; }
        public override TextRun GetTextRun(int cp)
            => (cp >= 0 && cp < Text.Length)
                 ? (TextRun)new TextCharacters(Text, cp, Text.Length - cp, _props)
                 : new TextEndOfParagraph(1);
        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
            => new TextSpan<CultureSpecificCharacterBufferRange>(0,
                   new CultureSpecificCharacterBufferRange(CultureInfo.InvariantCulture, CharacterBufferRange.Empty));
        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
    }

    internal sealed class ProbeRunProperties : TextRunProperties
    {
        private readonly Typeface _tf; private readonly double _em;
        internal ProbeRunProperties(Typeface tf, double em) { _tf = tf; _em = em; }
        public override Typeface Typeface => _tf;
        public override double FontRenderingEmSize => _em;
        public override double FontHintingEmSize => _em;
        public override CultureInfo CultureInfo => CultureInfo.InvariantCulture;
        public override Brush ForegroundBrush => null;          // 见 PcLineOracle 的注释：Brush 静态构造要 X
        public override Brush BackgroundBrush => null;
        public override TextDecorationCollection TextDecorations => null;
        public override TextEffectCollection TextEffects => null;
    }

    internal sealed class ProbePara : TextParagraphProperties
    {
        private readonly bool _tabZero, _firstLine, _alwaysCollapsible;
        private readonly double _indent, _paraIndent;
        private readonly FlowDirection _flow;
        private readonly TextRunProperties _props;
        internal ProbePara(TextRunProperties props, FlowDirection flow, bool tabZero,
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
        private const string FallbackEnvVar = "WPF_LINUX_TEXTLINE_FALLBACK";
        private const string FontFamilyName = "Arial";
        private const double Tol = 0.05;

        private static string F(double v) => v.ToString("F6", CultureInfo.InvariantCulture);
        private static string Show(string s)
        {
            if (s == null) return "<null>";
            var sb = new StringBuilder();
            foreach (char c in s)
            {
                if (c == '\t') sb.Append("\\t");
                else if (c == '\n') sb.Append("\\n");
                else if (c == '\r') sb.Append("\\r");
                else sb.Append(c);
            }
            return sb.ToString();
        }
        private static string Hex(byte[] b)
        {
            var sb = new StringBuilder(b.Length * 2);
            foreach (byte x in b) sb.Append(x.ToString("x2"));
            return sb.ToString();
        }

        private static string StrictEnabled()
        {
            try { return WpfLinux.Shims.PresentationCore.HbTextFallback.Enabled ? "true" : "false"; }
            catch (Exception e) { return "<IVT 读不到 " + e.GetType().Name + ">"; }
        }
        private static string StrictCounters()
        {
            try
            {
                return "fallbackCalls=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Calls
                     + " fallbackHandled=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Handled
                     + " fallbackBailed=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Bailed
                     + " lastBail=\"" + WpfLinux.Shims.PresentationCore.HbTextFallback.LastBail + "\"";
            }
            catch (Exception e) { return "<IVT 读不到 " + e.GetType().Name + ">"; }
        }
        private static string StrictCacheInfo()
        {
            try { return WpfLinux.Shims.PresentationCore.HbTextFallback.CacheInfo(); }
            catch (Exception e) { return "<IVT 读不到 " + e.GetType().Name + ">"; }
        }
        private static string RelaxedDiag()
        {
            try { return MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics; }
            catch (Exception e) { return "<IVT 读不到 " + e.GetType().Name + ">"; }
        }

        private static int Main(string[] argv)
        {
            try { Console.OutputEncoding = Encoding.UTF8; } catch (Exception) { }

            string corpus = null, caseId = null, tier = "strict";
            bool freshSource = false;
            for (int i = 0; i < argv.Length; ++i)
            {
                if (argv[i] == "--corpus" && i + 1 < argv.Length) corpus = argv[++i];
                else if (argv[i] == "--case" && i + 1 < argv.Length) caseId = argv[++i];
                else if (argv[i] == "--tier" && i + 1 < argv.Length) tier = argv[++i];
                else if (argv[i] == "--fresh-source") freshSource = true;
            }
            if (tier != "strict" && tier != "lenient")
            {
                Console.WriteLine("PROBE_EXIT=NOINFO rc=2 原因=--tier 取值非法：" + tier);
                return 2;
            }
            if (corpus == null || !File.Exists(corpus))
            {
                Console.WriteLine("PROBE_EXIT=NOINFO rc=2 原因=语料不存在：" + (corpus ?? "<未给>"));
                return 2;
            }
            if (caseId == null)
            {
                Console.WriteLine("PROBE_EXIT=NOINFO rc=2 原因=未给 --case <id>");
                return 2;
            }

            // ---- 档位转向：**在拿任何读数之前** ----
            if (tier == "strict") Environment.SetEnvironmentVariable(FallbackEnvVar, null);
            else Environment.SetEnvironmentVariable(FallbackEnvVar, "0");
            Console.WriteLine("PROBE lane = W20A（D-T6 定性探针）  tier=" + tier
                              + "  " + FallbackEnvVar + "=" + (Environment.GetEnvironmentVariable(FallbackEnvVar) ?? "<null>")
                              + "  freshSource=" + (freshSource ? 1 : 0));
            Console.WriteLine("PROBE TierSteer 产品侧 HbTextFallback.Enabled = " + StrictEnabled()
                              + "  ⇒ 生效档 = " + (StrictEnabled() == "true" ? "严格档" : "宽松档"));

            byte[] raw = File.ReadAllBytes(corpus);
            string sha;
            using (var s = SHA256.Create()) sha = Hex(s.ComputeHash(raw)).Substring(0, 16);
            Console.WriteLine("PROBE corpus=" + corpus + " sha16=" + sha + " bytes=" + raw.Length);

            JsonDocument doc = JsonDocument.Parse(raw);
            JsonElement? found = null;
            foreach (JsonElement c in doc.RootElement.GetProperty("cases").EnumerateArray())
                if (c.GetProperty("id").GetString() == caseId) { found = c; break; }
            if (found == null)
            {
                Console.WriteLine("PROBE_EXIT=NOINFO rc=2 原因=语料里没有这条用例：" + caseId);
                return 2;
            }
            JsonElement C = found.Value;

            string text = C.GetProperty("text").GetString();
            double pw = C.GetProperty("paragraphWidthDip").GetDouble();
            double em = C.GetProperty("emSizeDip").GetDouble();
            bool rtl = C.GetProperty("flowDirection").GetString() == "RightToLeft";
            bool tabZero = C.GetProperty("incrementalTabArm").GetString() == "DefaultIncrementalTab=0";
            bool firstLine = C.GetProperty("firstLineInParagraph").GetBoolean();
            double ind = C.GetProperty("indentDip").GetDouble();
            double pi = C.GetProperty("paragraphIndentDip").GetDouble();
            JsonElement exp = C.GetProperty("lines");

            Console.WriteLine("PROBE CASE " + caseId + " text=[" + Show(text) + "] pw=" + F(pw) + " em=" + F(em)
                              + " rtl=" + (rtl ? 1 : 0) + " tab0=" + (tabZero ? 1 : 0)
                              + " I=" + F(ind) + " PI=" + F(pi) + " 真值行数=" + exp.GetArrayLength());
            Console.WriteLine("PROBE 覆盖闸（本探针不跳过任何例；缺字形与否由 PcLineOracle 管）");

            var tf = new Typeface(new FontFamily(FontFamilyName), FontStyles.Normal, FontWeights.Normal, FontStretches.Normal);
            GlyphTypeface gt = null;
            try { tf.TryGetGlyphTypeface(out gt); } catch (Exception) { }
            if (gt == null)
            {
                Console.WriteLine("PROBE_EXIT=NOINFO rc=2 原因=字体面解析失败");
                return 2;
            }
            var props = new ProbeRunProperties(tf, em);
            var para = new ProbePara(props, rtl ? FlowDirection.RightToLeft : FlowDirection.LeftToRight,
                                     tabZero, ind, pi, firstLine, true /* AlwaysCollapsible=true = 腿 B 同层对照 */);

            TextFormatter fmt;
            try { fmt = TextFormatter.Create(); }
            catch (Exception e)
            {
                Console.WriteLine("PROBE_EXIT=NOINFO rc=2 原因=TextFormatter.Create() 抛 " + e.GetType().Name + ": " + e.Message);
                return 2;
            }

            // 每次驱动都新建 source 时，`GetTextRun(cp)` 仍按**绝对 cp** 取字符 —— 与 oracle 宿主同形。
            TextSource src = new MockTextSource(text, props);

            int index = 0, guard = 0, li = 0;
            TextLineBreak brk = null;
            int lineLocalNoBounds = 0, paraFrameNoBounds = 0, totalChars = 0, mismatched = 0;
            double worst = 0; string worstWhy = "-";
            var fingerprint = new StringBuilder();
            var frames = new List<string>();
            var classNames = new List<string>();

            while (index < text.Length && guard++ < 64)
            {
                TextLine line;
                try
                {
                    if (freshSource) src = new MockTextSource(text, props);      // ★ 缓存专项：必不命中
                    line = fmt.FormatLine(src, index, pw, para, brk);
                }
                catch (Exception e)
                {
                    Console.WriteLine("PROBE DRIVE_FAIL cpFirst=" + index + " " + e.GetType().Name + ": " + e.Message);
                    break;
                }
                if (line == null) { Console.WriteLine("PROBE DRIVE_FAIL cpFirst=" + index + " FormatLine 返回 null"); break; }
                int len = (int)line.Length;
                if (len <= 0) { Console.WriteLine("PROBE DRIVE_FAIL cpFirst=" + index + " 0 长行（防死循环）"); break; }
                int nl = (int)line.NewlineLength;
                int vis = len - nl; if (index + vis > text.Length) vis = Math.Max(text.Length - index, 0);
                string visText = (index + vis <= text.Length) ? text.Substring(index, vis) : "?";

                Console.WriteLine();
                Console.WriteLine("PROBE LINE li=" + li + " cpFirst=" + index + " type=" + line.GetType().FullName
                                  + " Length=" + line.Length + " NewlineLength=" + nl
                                  + " TrailingWs=" + line.TrailingWhitespaceLength
                                  + " Start=" + F(line.Start) + " Width=" + F(line.Width)
                                  + " Witw=" + F(line.WidthIncludingTrailingWhitespace)
                                  + " HasOverflowed=" + line.HasOverflowed
                                  + " vis=[" + Show(visText) + "]");
                fingerprint.Append(li).Append(':').Append(line.Length).Append(':').Append(F(line.Width))
                           .Append(':').Append(Show(visText)).Append('|');

                // ---- 行对象自己的帧原点（**不依赖任何约定**：在 0..text.Length 上找最小可用 arg） ----
                int frame = -1; string frameWhy = "-";
                for (int a = 0; a <= text.Length; ++a)
                {
                    var bl = ProbeBounds(line, a, 1);
                    if (HasTrb(bl)) { frame = a; break; }
                }
                if (frame < 0) frameWhy = "扫描 0.." + text.Length + " 全无 TextRunBounds";
                frames.Add(frame.ToString());
                try { frameWhy = "shim 私有字段 _lineStart=" + Reflect(line, "_lineStart"); }
                catch (Exception e) { frameWhy = "反射 _lineStart 失败 " + e.GetType().Name; }
                Console.WriteLine("PROBE FRAME li=" + li + " 帧原点(扫描)=" + (frame < 0 ? "无" : frame.ToString())
                                  + "（" + frameWhy + "）"
                                  + " ｜行内读法(0,1)=" + OneBounds(line, 0)
                                  + " ｜段落系读法(cpFirst,1)=" + OneBounds(line, index));

                // ---- 公共观测面（真机同族 API） ----
                var spans = new StringBuilder();
                try
                {
                    foreach (TextSpan<TextRun> sp in line.GetTextRunSpans())
                        spans.Append('[').Append(sp.Length).Append(' ').Append(sp.Value == null ? "<null>" : sp.Value.GetType().Name).Append(']');
                }
                catch (Exception e) { spans.Append("<EX ").Append(e.GetType().Name).Append('>'); }
                var igr = new StringBuilder();
                try
                {
                    foreach (IndexedGlyphRun g in line.GetIndexedGlyphRuns())
                        igr.Append('[').Append(g.TextSourceCharacterIndex).Append('+').Append(g.TextSourceLength).Append(']');
                }
                catch (Exception e) { igr.Append("<EX ").Append(e.GetType().Name).Append('>'); }
                string hit;
                try
                {
                    CharacterHit ch = line.GetCharacterHitFromDistance(0);
                    hit = "FirstCharacterIndex=" + ch.FirstCharacterIndex + " TrailingLength=" + ch.TrailingLength;
                }
                catch (Exception e) { hit = "<EX " + e.GetType().Name + ">"; }
                Console.WriteLine("PROBE API li=" + li + " runSpans=" + spans + " indexedGlyphRuns(段落系)=" + igr
                                  + " GetCharacterHitFromDistance(0)=" + hit
                                  + " ｜HbTextLineScaffold.HitCount(GetCharacterHitFromDistance)="
                                  + HitCountSafe("GetCharacterHitFromDistance"));
                classNames.Add(line.GetType().FullName);

                // ---- 逐字两种读法 + 与真值比 ----
                for (int j = 0; j < vis; ++j)
                {
                    string ch = (j < visText.Length) ? visText[j].ToString() : "?";
                    var bLocal = ProbeBounds(line, j, 1);
                    var bPara = ProbeBounds(line, index + j, 1);
                    bool okLocal = HasTrb(bLocal);
                    bool okPara = HasTrb(bPara);
                    ++totalChars;
                    if (!okLocal) ++lineLocalNoBounds;
                    if (!okPara) ++paraFrameNoBounds;

                    double truth = double.NaN;
                    int k = 0;
                    foreach (JsonElement E in exp.EnumerateArray())
                    {
                        if (k++ != li) continue;
                        int m = 0;
                        foreach (JsonElement p in E.GetProperty("perChar").EnumerateArray())
                        {
                            if (m++ == j) truth = p.GetProperty("xFromLeftDip").GetDouble();
                        }
                        break;
                    }
                    string dPara = "NA";
                    if (!double.IsNaN(truth) && bPara != null && bPara.Count > 0)
                    {
                        double d = bPara[0].Rectangle.X - truth;
                        dPara = F(d);
                        if (Math.Abs(d) > worst) { worst = Math.Abs(d); worstWhy = "li=" + li + " j=" + j; }
                        if (Math.Abs(d) > Tol) ++mismatched;
                    }
                    Console.WriteLine("PROBE CHAR li=" + li + " j=" + j + " char=[" + Show(ch) + "]"
                                      + " 行内读法(j)=" + OneBounds(line, j)
                                      + " 段落系读法(cpFirst+j=" + (index + j) + ")=" + OneBounds(line, index + j)
                                      + " 真值x=" + (double.IsNaN(truth) ? "NA" : F(truth)) + " Δ段落系=" + dPara);
                }

                brk = line.GetTextLineBreak();
                index += len;
                ++li;
            }

            Console.WriteLine();
            Console.WriteLine("PROBE SUMMARY " + caseId + " tier=" + tier + " freshSource=" + (freshSource ? 1 : 0)
                              + " 我方行数=" + li + " 真值行数=" + exp.GetArrayLength());
            Console.WriteLine("PROBE SUMMARY 行指纹(li:Length:Width:vis)=" + fingerprint);
            Console.WriteLine("PROBE SUMMARY 行类型=" + string.Join(",", classNames.Distinct()));
            Console.WriteLine("PROBE SUMMARY 帧原点(扫描)=" + string.Join(",", frames));
            Console.WriteLine("PROBE SUMMARY 逐字: 总字=" + totalChars + " 行内读法取不到=" + lineLocalNoBounds
                              + " 段落系读法取不到=" + paraFrameNoBounds
                              + " 段落系 vs 真值 |Δ|>0.05 的字=" + mismatched + " Δmax=" + F(worst) + " @" + worstWhy);
            Console.WriteLine("PROBE SUMMARY 严格档计数 " + StrictCounters());
            Console.WriteLine("PROBE SUMMARY 严格档内部整段行表 " + StrictCacheInfo());
            Console.WriteLine("PROBE SUMMARY 宽松档计数 " + RelaxedDiag());
            Console.WriteLine("PROBE_EXIT rc=0（本探针**不判分**：定性由 W20A-report.md 给）");
            return 0;
        }

        private static string HitCountSafe(string member)
        {
            try { return WpfLinux.Shims.PresentationCore.HbTextLineScaffold.HitCount(member).ToString(); }
            catch (Exception e) { return "<" + e.GetType().Name + ">"; }
        }

        private static string Reflect(TextLine line, string field)
        {
            try
            {
                FieldInfo fi = line.GetType().GetField(field, BindingFlags.Instance | BindingFlags.NonPublic);
                if (fi == null) return "<无此字段>";
                object v = fi.GetValue(line);
                return v == null ? "<null>" : v.ToString();
            }
            catch (Exception e) { return "<EX " + e.GetType().Name + ">"; }
        }

        /// <summary>真机 oracle 宿主读法：`GetTextBounds(gi, 1)` 的**原样**调用，异常折成 null。</summary>
        private static IList<TextBounds> ProbeBounds(TextLine line, int arg, int len)
        {
            try { return line.GetTextBounds(arg, len); }
            catch (Exception) { return null; }
        }

        /// <summary>"这一次读**拿到了字符边界**吗" —— 与 `PcLineOracle` 的 `NaN` 判据同一条件。</summary>
        private static bool HasTrb(IList<TextBounds> b)
            => b != null && b.Count > 0 && b[0].TextRunBounds != null && b[0].TextRunBounds.Count > 0;

        private static string OneBounds(TextLine line, int arg)
        {
            IList<TextBounds> b = ProbeBounds(line, arg, 1);
            if (b == null) return "EX/空引用";
            if (b.Count == 0) return "count=0";
            string trb;
            if (b[0].TextRunBounds == null) trb = "TextRunBounds=null";
            else if (b[0].TextRunBounds.Count == 0) trb = "TextRunBounds=空";
            else trb = "trb[0]=" + b[0].TextRunBounds[0].TextSourceCharacterIndex + ".."
                       + (b[0].TextRunBounds[0].TextSourceCharacterIndex + b[0].TextRunBounds[0].Length);
            return "count=" + b.Count + " X=" + F(b[0].Rectangle.X) + " W=" + F(b[0].Rectangle.Width) + " " + trb;
        }
    }
}

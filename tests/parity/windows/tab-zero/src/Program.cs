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

namespace TabZeroOracle
{
    /// <summary>
    /// U1 real-machine oracle: DefaultIncrementalTab = 0 arm.
    ///
    /// Mirrors T1d's layout-b34 TextModel settings (TextAlignment.Left, TextWrapping.Wrap,
    /// LineHeight 0 = natural, FirstLineInParagraph true, Indent 0, ParagraphIndent 0,
    /// AlwaysCollapsible false, Tabs null) and changes exactly ONE input:
    ///     DefaultIncrementalTab = 0   vs   the WPF default
    /// Both arms are emitted so they can be compared side by side.
    ///
    /// Full paragraph layout: FormatLine is called repeatedly with the TextLineBreak returned by the
    /// previous line, so every line (and therefore every break point) is recorded, not just the first.
    /// </summary>
    public static class Program
    {
        private const string B34_TAB_TEXT = "a\tb\t\tc\td";   // the exact text T1d's 'tabs' case uses
        private static readonly double[] Widths = { 40.0, 80.0, 160.0, 320.0 };
        private static readonly string[] FontCandidates = { "Arial", "Segoe UI", "Tahoma", "Times New Roman" };

        private static readonly (string Id, string Text, string Note)[] Corpus =
        {
            ("notab-control", "abc def",        "CONTROL: no tab, same settings as the tab cases"),
            ("tab-single",    "a\tb",           "single tab in the middle"),
            ("tab-head",      "\ta",            "tab at line start"),
            ("tab-tail",      "a\t",            "tab at line end"),
            ("tab-adjacent",  "a\t\tb",         "two adjacent tabs"),
            ("tab-only",      "\t\t",           "tabs only"),
            ("b34-tabs",      B34_TAB_TEXT,     "EXACTLY the text of T1d's layout-b34 'tabs' case (a\\tb\\t\\tc\\td)"),
        };

        public static int Main(string[] args)
        {
            string fontDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\fonts";
            string outDir = args.Length > 1 ? args[1] : @"C:\u1-shaping\out-tabzero";
            Directory.CreateDirectory(outDir);

            var cps = new SortedSet<int>();
            foreach (var c in Corpus) foreach (char ch in c.Text) if (ch != '\t') cps.Add(ch);
            string chosen = null, fontUri = null, fontSha = null;
            var coverage = new List<object>();
            foreach (string fam in FontCandidates)
            {
                var tf = new Typeface(fam);
                if (!tf.TryGetGlyphTypeface(out GlyphTypeface gt)) { coverage.Add(new Dictionary<string, object> { ["family"] = fam, ["usable"] = false }); continue; }
                var missing = new List<object>();
                foreach (int cp in cps) if (!gt.CharacterToGlyphMap.ContainsKey(cp)) missing.Add("U+" + cp.ToString("X4"));
                coverage.Add(new Dictionary<string, object> { ["family"] = fam, ["usable"] = missing.Count == 0, ["missing"] = missing, ["fontUri"] = gt.FontUri.ToString() });
                if (missing.Count == 0 && chosen == null)
                {
                    chosen = fam; fontUri = gt.FontUri.ToString();
                    if (gt.FontUri.IsFile) fontSha = Sha256(gt.FontUri.LocalPath);
                }
            }
            if (chosen == null) { Console.Error.WriteLine("no font covers the corpus"); return 3; }
            Console.WriteLine($"font: {chosen} sha256={fontSha}");

            var formatter = TextFormatter.Create();
            var cases = new List<object>();
            var human = new StringBuilder();
            human.AppendLine("WPF tab oracle, DefaultIncrementalTab = 0 arm (human readable)");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine($"font: {chosen} ({fontUri})   Dpi=96   TextWrapping=Wrap   TextAlignment=Left   LineHeight=0(natural)");
            human.AppendLine("arms: incrementalTab=0 (DefaultIncrementalTab overridden to 0)  |  default (member not overridden)");
            human.AppendLine();

            // ---- arm 1: DefaultIncrementalTab = 0, full matrix -------------------
            foreach (var c in Corpus)
                foreach (double w in Widths)
                    foreach (var flow in new[] { FlowDirection.LeftToRight, FlowDirection.RightToLeft })
                        cases.Add(Measure(formatter, c, w, flow, chosen, fontSha, 24.0, tabZero: true, human: human));

            // ---- emSize sweep for the tab interval under tab=0 -------------------
            foreach (var c in new[] { Corpus[1], Corpus[4], Corpus[6] })
                foreach (double em in new[] { 12.0, 48.0 })
                    foreach (var flow in new[] { FlowDirection.LeftToRight, FlowDirection.RightToLeft })
                        cases.Add(Measure(formatter, c, 160.0, flow, chosen, fontSha, em, tabZero: true, human: human));

            // ---- arm 2: default incremental tab, for side-by-side ----------------
            foreach (var c in new[] { Corpus[1], Corpus[5], Corpus[6] })
                foreach (double w in new[] { 40.0, 80.0, 160.0 })
                    foreach (var flow in new[] { FlowDirection.LeftToRight, FlowDirection.RightToLeft })
                        cases.Add(Measure(formatter, c, w, flow, chosen, fontSha, 24.0, tabZero: false, human: human));

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-tab-zero-oracle/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["os"] = Environment.OSVersion.VersionString,
                ["clr"] = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
                ["presentationCore"] = typeof(TextFormatter).Assembly.GetName().Version.ToString(),
                ["measurement"] = "TextFormatter.Create().FormatLine(...) looped over TextLine.GetTextLineBreak() so every line is recorded",
                ["dpi"] = 96,
                ["units"] = "DIP (1/96 inch)",
                ["settingUnderTest"] = new Dictionary<string, object>
                {
                    ["DefaultIncrementalTab"] = "arm 'tab0' overrides TextParagraphProperties.DefaultIncrementalTab to 0; arm 'default' leaves it unoverridden",
                    ["otherParagraphProperties"] = "TextAlignment=Left, TextWrapping=Wrap, LineHeight=0 (natural), FirstLineInParagraph=true, " +
                                                   "Indent=0, ParagraphIndent=0, AlwaysCollapsible=false, Tabs=null, TextDecorations=null, TextMarkerProperties=null",
                    ["mirrors"] = "tests/parity/windows/layout-b34/src/LayoutOracle/TextModel.cs (only DefaultIncrementalTab changes)",
                },
                ["fontFamily"] = chosen, ["fontUri"] = fontUri, ["fontSha256"] = fontSha,
                ["fontSelection"] = "first candidate whose CharacterToGlyphMap covers every printable code point (tab U+0009 excluded: control char, no glyph)",
                ["fontCoverageTable"] = coverage,
                ["xNote"] = "per-char xFromLeftDip = distance from the LINE's left edge (raw TextBounds.X origin is the RIGHT edge for RightToLeft paragraphs)",
                ["breakReasonApi"] = "NOT AVAILABLE: WPF's TextFormatter/TextLine expose no 'why did it break here' information. " +
                                     "lineStart/lineEnd + the line text are the only truth; breakCause in each line is DERIVED by inspecting the " +
                                     "character before/at the break (see breakCauseNote).",
                ["trimmingApi"] = "NOT AVAILABLE in TextFormatter: upstream PresentationCore TextParagraphProperties has NO Trimming member " +
                                  "(members: FlowDirection, TextAlignment, LineHeight, FirstLineInParagraph, AlwaysCollapsible, " +
                                  "DefaultTextRunProperties, TextDecorations, TextWrapping, TextMarkerProperties, Indent, ParagraphIndent, " +
                                  "DefaultIncrementalTab, Tabs, Hyphenator). Trimming is a framework-level (TextBlock) decision driven by " +
                                  "TextLine.HasOverflowed, which this oracle reports per line.",
                ["cases"] = cases,
            };
            File.WriteAllText(Path.Combine(outDir, "tab-zero-oracle.json"),
                JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "tab-zero-oracle.txt"), human.ToString(), new UTF8Encoding(false));
            Console.WriteLine("cases: " + cases.Count);
            return 0;
        }

        private static Dictionary<string, object> Measure(TextFormatter formatter, (string Id, string Text, string Note) c,
            double width, FlowDirection flow, string font, string fontSha, double emSize, bool tabZero, StringBuilder human)
        {
            var props = new Props(new Typeface(font), emSize);
            var para = new Para(props, flow, tabZero);
            var source = new StringSource(c.Text, props);

            var lines = new List<object>();
            int index = 0;
            TextLineBreak brk = null;
            int guard = 0;
            while (index < c.Text.Length && guard++ < 64)
            {
                TextLine line = formatter.FormatLine(source, index, width, para, brk);
                lines.Add(DescribeLine(line, c.Text, flow, index, lines.Count));
                brk = line.GetTextLineBreak();
                if (line.Length <= 0) break;
                index += line.Length;
            }

            string id = c.Id + "@w" + width.ToString("0", CultureInfo.InvariantCulture) + "@em" + emSize.ToString("0", CultureInfo.InvariantCulture) +
                        "@" + (flow == FlowDirection.RightToLeft ? "RTL" : "LTR") + "@" + (tabZero ? "tab0" : "default");
            var rec = new Dictionary<string, object>
            {
                ["id"] = id,
                ["text"] = c.Text,
                ["note"] = c.Note,
                ["paragraphWidthDip"] = width,
                ["emSizeDip"] = emSize,
                ["flowDirection"] = flow == FlowDirection.RightToLeft ? "RightToLeft" : "LeftToRight",
                ["incrementalTabArm"] = tabZero ? "DefaultIncrementalTab=0" : "DefaultIncrementalTab=default",
                ["fontFamily"] = font, ["fontSha256"] = fontSha, ["dpi"] = 96,
                ["textWrapping"] = "Wrap",
                ["lineCount"] = lines.Count,
                ["tabCount"] = CountTabs(c.Text),
                ["lines"] = lines,
            };
            if (human != null)
            {
                human.AppendLine($"== [{id}] \"{Esc(c.Text)}\"");
                foreach (var o in lines)
                {
                    var L = (Dictionary<string, object>)o;
                    human.AppendLine($"   line {L["index"]}: [{L["startChar"]},{L["endCharExclusive"]}) nl={L["newlineLength"]} " +
                                     $"trailWs={L["trailingWhitespaceLength"]} w={F((double)L["width"])} witw={F((double)L["widthIncludingTrailingWhitespace"])} " +
                                     $"ovf={L["hasOverflowed"]} cause={L["breakCause"]}  \"{Esc((string)L["lineText"])}\"");
                }
            }
            return rec;
        }

        private static Dictionary<string, object> DescribeLine(TextLine line, string text, FlowDirection flow, int lineStart, int lineIndex)
        {
            // NOTE: TextLine.Start is a DOUBLE distance ("distance from paragraph start to line start", in DIPs),
            // NOT a character index - casting it to int silently yields 0 and slices the wrong text.
            // The authoritative character index is the one we passed to FormatLine, i.e. lineStart here.
            int len = (int)line.Length;
            int textLen = len - (int)line.NewlineLength;
            if (lineStart + textLen > text.Length) textLen = Math.Max(text.Length - lineStart, 0);

            var perChar = new List<object>();
            for (int i = 0; i < textLen; i++)
            {
                int gi = lineStart + i;
                if (gi >= text.Length) break;
                IList<TextBounds> b = line.GetTextBounds(gi, 1);
                if (b == null || b.Count == 0)
                {
                    perChar.Add(new Dictionary<string, object> { ["i"] = gi, ["char"] = text[gi].ToString(), ["xFromLeftDip"] = null, ["width"] = null });
                    continue;
                }
                perChar.Add(new Dictionary<string, object>
                {
                    ["i"] = gi,
                    ["char"] = text[gi].ToString(),
                    ["codePoint"] = "U+" + ((int)text[gi]).ToString("X4"),
                    ["x"] = R(b[0].Rectangle.X),
                    ["width"] = R(b[0].Rectangle.Width),
                    ["flowDirection"] = b[0].FlowDirection.ToString(),
                });
            }
            double inkRight = 0;
            foreach (var o in perChar) { var d = (Dictionary<string, object>)o; if (d["x"] != null) { double r = (double)d["x"] + (double)d["width"]; if (r > inkRight) inkRight = r; } }
            foreach (var o in perChar)
            {
                var d = (Dictionary<string, object>)o;
                if (d["x"] == null) continue;
                double raw = (double)d["x"], w = (double)d["width"];
                d["xFromLeftDip"] = R(flow == FlowDirection.RightToLeft ? inkRight - (raw + w) : raw);
            }

            // DERIVED break cause (WPF exposes none): look at the last character kept and the first dropped.
            int lastKept = lineStart + textLen - 1;
            int firstDropped = lineStart + textLen;
            string cause;
            if (firstDropped >= text.Length) cause = "end-of-text";
            else if (textLen == 0) cause = "empty-line";
            else if (text[firstDropped] == '\n') cause = "explicit-newline";
            else if (lastKept >= 0 && text[lastKept] == '\t') cause = "after-tab";
            else if (text[firstDropped] == '\t') cause = "before-tab";
            else if (lastKept >= 0 && text[lastKept] == ' ') cause = "at-space";
            else cause = "mid-token";

            return new Dictionary<string, object>
            {
                ["index"] = lineIndex,
                ["paragraphStartOffsetDip"] = R(line.Start),   // TextLine.Start: distance from paragraph start to line start (DIPs)
                ["startChar"] = lineStart,
                ["endCharExclusive"] = lineStart + textLen,
                ["lengthWithNewline"] = len,
                ["dependentLength"] = (int)line.DependentLength,
                ["newlineLength"] = (int)line.NewlineLength,
                ["trailingWhitespaceLength"] = (int)line.TrailingWhitespaceLength,
                ["width"] = R(line.Width),
                ["widthIncludingTrailingWhitespace"] = R(line.WidthIncludingTrailingWhitespace),
                ["height"] = R(line.Height),
                ["baseline"] = R(line.Baseline),
                ["hasOverflowed"] = line.HasOverflowed,
                ["lineText"] = SafeSlice(text, lineStart, textLen),
                ["breakCause"] = cause,
                ["breakCauseNote"] = "DERIVED from the characters around the break, not reported by WPF",
                ["perChar"] = perChar,
            };
        }

        private static int CountTabs(string s) { int n = 0; foreach (char c in s) if (c == '\t') n++; return n; }
        private static string SafeSlice(string s, int start, int len)
        {
            if (start < 0 || start > s.Length || len <= 0) return "";
            if (start + len > s.Length) len = s.Length - start;
            return s.Substring(start, len);
        }
        private static string Esc(string s) => s == null ? "" : s.Replace("\t", "\\t").Replace("\n", "\\n");
        private static double R(double v) => double.IsNaN(v) ? v : Math.Round(v, 6, MidpointRounding.AwayFromZero);
        private static string F(double v) => double.IsNaN(v) ? "n/a" : v.ToString("0.######", CultureInfo.InvariantCulture);

        private static string Sha256(string path)
        {
            try
            {
                using var sha = SHA256.Create();
                using var fs = File.OpenRead(path);
                byte[] h = sha.ComputeHash(fs);
                var sb = new StringBuilder(h.Length * 2);
                foreach (byte b in h) sb.Append(b.ToString("x2", CultureInfo.InvariantCulture));
                return sb.ToString();
            }
            catch (Exception e) { return "ERR " + e.Message; }
        }
    }

    internal sealed class StringSource : TextSource
    {
        private readonly string _text;
        private readonly TextRunProperties _props;
        public StringSource(string text, TextRunProperties props) { _text = text; _props = props; }
        public override TextRun GetTextRun(int index)
            => index < _text.Length ? (TextRun)new TextCharacters(_text, index, _text.Length - index, _props) : new TextEndOfParagraph(1);
        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
        {
            int len = Math.Min(Math.Max(limit, 0), _text.Length);
            return new TextSpan<CultureSpecificCharacterBufferRange>(len,
                new CultureSpecificCharacterBufferRange(CultureInfo.CurrentCulture, new CharacterBufferRange(_text, 0, len)));
        }
        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
    }

    internal sealed class Props : TextRunProperties
    {
        public Props(Typeface tf, double size) { Typeface = tf; FontRenderingEmSize = size; }
        public override Typeface Typeface { get; }
        public override double FontRenderingEmSize { get; }
        public override double FontHintingEmSize => FontRenderingEmSize;
        public override Brush ForegroundBrush => Brushes.Black;
        public override Brush BackgroundBrush => null;
        public override CultureInfo CultureInfo => CultureInfo.GetCultureInfo("en-us");
        public override TextDecorationCollection TextDecorations => null;
        public override TextEffectCollection TextEffects => null;
        public override BaselineAlignment BaselineAlignment => BaselineAlignment.Baseline;
        public override NumberSubstitution NumberSubstitution => null;
        public override TextRunTypographyProperties TypographyProperties => null;
    }

    /// <summary>Mirrors layout-b34's TextModel; the ONLY difference between arms is DefaultIncrementalTab.</summary>
    internal sealed class Para : TextParagraphProperties
    {
        private readonly bool _tabZero;
        public Para(TextRunProperties props, FlowDirection flow, bool tabZero)
        { DefaultTextRunProperties = props; FlowDirection = flow; _tabZero = tabZero; }
        public override TextRunProperties DefaultTextRunProperties { get; }
        public override FlowDirection FlowDirection { get; }
        public override TextAlignment TextAlignment => TextAlignment.Left;
        public override TextWrapping TextWrapping => TextWrapping.Wrap;
        public override double LineHeight => 0;            // 0 = natural, as in layout-b34
        public override bool FirstLineInParagraph => true;
        public override double Indent => 0;
        public override double ParagraphIndent => 0;
        public override bool AlwaysCollapsible => false;
        public override TextDecorationCollection TextDecorations => null;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override IList<TextTabProperties> Tabs => null;
        public override double DefaultIncrementalTab => _tabZero ? 0 : base.DefaultIncrementalTab;
    }
}

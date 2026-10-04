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

namespace TabOracle
{
    /// <summary>
    /// U1 (Windows real-machine lane): tab metrics oracle.
    ///
    /// Same apparatus as the bidi oracle: TextFormatter.Create().FormatLine(...) -> TextLine,
    /// TextLine.GetTextBounds(i,1) for per-character x/width, GetTextBounds(0,Length) for the whole line.
    /// Everything is reported with the normalised xFromLeftDip (the raw x origin is the RIGHT edge for
    /// a RightToLeft paragraph, which is how the earlier bidi oracle got mis-read).
    /// </summary>
    public static class Program
    {
        private const double EmSize = 24.0;
        private static readonly double[] Widths = { 40.0, 80.0, 160.0, 320.0, 10000.0 };
        private static readonly string[] FontCandidates = { "Arial", "Segoe UI", "Tahoma", "Times New Roman" };

        // (id, text, note)
        private static readonly (string Id, string Text, string Note)[] Corpus =
        {
            ("no-tab",        "abc def",   "CONTROL: no tab at all"),
            ("no-tab-short",  "ab",        "CONTROL: no tab, 2 chars"),
            ("tab-mid",       "a\tb",      "single tab in the middle"),
            ("tab-head",      "\ta",       "single tab at line start"),
            ("tab-tail",      "a\t",       "single tab at line end"),
            ("tab-only",      "\t",        "tab is the whole line"),
            ("tab-two-mid",   "a\tb\tc",   "two tabs with text between"),
            ("tab-two-only",  "\t\t",      "two tabs in a row"),
            ("tab-double-mid","a\t\tb",    "two adjacent tabs with text on both sides"),
        };

        public static int Main(string[] args)
        {
            string outDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\out-tab";
            Directory.CreateDirectory(outDir);

            // coverage check: every PRINTABLE code point of the corpus must be in the font's cmap
            // (tab U+0009 has no glyph by design and is excluded)
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
            human.AppendLine("WPF tab metrics oracle (human readable)");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine($"font: {chosen} ({fontUri})   emSize={EmSize} DIP   Dpi=96");
            human.AppendLine();

            foreach (var c in Corpus)
            {
                foreach (double width in Widths)
                {
                    foreach (var flow in new[] { FlowDirection.LeftToRight, FlowDirection.RightToLeft })
                    {
                        var rec = Measure(formatter, c.Id, c.Text, c.Note, width, flow, 0.0, chosen, fontSha);
                        cases.Add(rec);
                        var d = (Dictionary<string, object>)rec;
                        human.AppendLine($"== [{c.Id}] \"{Esc(c.Text)}\" w={width:0} {d["flowDirection"]}");
                        human.AppendLine($"   overflowed={d["hasOverflowed"]} trailingWsLen={d["trailingWhitespaceLength"]}");
                        human.AppendLine($"   line: length={d["lineLength"]} newline={d["newlineLength"]} width={F((double)d["width"])} " +
                                         $"widthInclTrailingWs={F((double)d["widthIncludingTrailingWhitespace"])} height={F((double)d["lineHeight"])} baseline={F((double)d["baseline"])}");
                        var sb = new StringBuilder("   per-char xFromLeft/width:");
                        foreach (var o in (List<object>)d["perChar"])
                        {
                            var p = (Dictionary<string, object>)o;
                            sb.Append($" {Esc((string)p["char"])}@{F((double)p["xFromLeftDip"])}/{F((double)p["width"])}");
                        }
                        human.AppendLine(sb.ToString());
                        if ((int)d["tabCount"] > 0)
                            human.AppendLine("   tabs: " + TabsText((List<object>)d["tabs"]));
                    }
                }
            }

            // emSize sweep: is the default tab interval a multiple of the em size (4x) or a fixed DIP value?
            foreach (double em in new[] { 12.0, 48.0 })
                foreach (var txt in new[] { "\t", "a\tb", "a\tb\tc" })
                    foreach (var flow in new[] { FlowDirection.LeftToRight, FlowDirection.RightToLeft })
                    {
                        var rec = Measure(formatter, "em" + em + "-" + txt.Replace("\t", "T"), txt, "emSize sweep", 10000.0, flow, 0.0, chosen, fontSha, em);
                        cases.Add(rec);
                        var d = (Dictionary<string, object>)rec;
                        human.AppendLine($"== [emSize={em}] \"{Esc(txt)}\" {d["flowDirection"]}  lineWidth={F((double)d["width"])}  " + TabsText((List<object>)d["tabs"]));
                    }

            // indent variants: does Indent change relative tab placement?
            foreach (double indent in new[] { 24.0, 48.0 })
                foreach (var txt in new[] { "a\tb", "\ta", "a\tb\tc" })
                    foreach (var flow in new[] { FlowDirection.LeftToRight, FlowDirection.RightToLeft })
                    {
                        var rec = Measure(formatter, "indent" + indent + "-" + txt.Replace("\t", "T"), txt, "Indent set on TextParagraphProperties", 10000.0, flow, indent, chosen, fontSha);
                        cases.Add(rec);
                        var d = (Dictionary<string, object>)rec;
                        human.AppendLine($"== [indent={indent}] \"{Esc(txt)}\" {d["flowDirection"]}");
                        human.AppendLine($"   line width={F((double)d["width"])}  tabs: " + TabsText((List<object>)d["tabs"]));
                    }

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-tab-oracle/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["os"] = Environment.OSVersion.VersionString,
                ["clr"] = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
                ["presentationCore"] = typeof(TextFormatter).Assembly.GetName().Version.ToString(),
                ["measurement"] = "System.Windows.Media.TextFormatting.TextFormatter.FormatLine -> TextLine.GetTextBounds(i,1) / GetTextBounds(0,Length)",
                ["dpi"] = 96,
                ["units"] = "DIP (1/96 inch); TextFormatter is resolution independent",
                ["emSizeDip"] = EmSize,
                ["paragraphWidthsDip"] = Widths,
                ["fontFamily"] = chosen, ["fontUri"] = fontUri, ["fontSha256"] = fontSha,
                ["fontSelection"] = "first candidate whose GlyphTypeface.CharacterToGlyphMap covers every PRINTABLE code point of the corpus " +
                                    "(tab U+0009 excluded: control characters have no glyph), so font fallback cannot perturb the measurement",
                ["fontCoverageTable"] = coverage,
                ["xNote"] = "perChar[].xFromLeftDip is the character's left edge measured from the LINE's left edge. The raw TextBounds.X " +
                            "origin is the RIGHT edge for a RightToLeft paragraph, so always use xFromLeftDip when comparing directions.",
                ["tabWidthDerivation"] = "tabs[].advanceDip is the tab's measured advance: TextBounds.Rectangle.Width from GetTextBounds(tabIndex,1). " +
                                         "tabs[].reachedStopDip is the xFromLeftDip of the stop the tab advanced to: the tab's RIGHT edge for LeftToRight " +
                                         "and its LEFT edge for RightToLeft, because tabs advance along the flow direction. " +
                                         "tabs[].derivedAdvanceDip is an independent cross-check (next logical char x - tab x) and is only emitted when the " +
                                         "next logical character is physically to the right - in a RightToLeft paragraph it is not, so it is null and flagged.",
                ["tabStopsApi"] = "WPF exposes NO public API for custom tab stops: TextParagraphProperties has no tab-properties member " +
                                  "(members are Alignment/DefaultTextRunProperties/FirstLineInParagraph/FlowDirection/Indent/LineHeight/" +
                                  "ParagraphIndent/TextAlignment/TextDecorations/TextMarkerProperties/TextWrapping). The default tab width is therefore " +
                                  "whatever TextFormatter uses internally, and this oracle MEASURES it instead of assuming it.",
                ["cases"] = cases,
            };
            File.WriteAllText(Path.Combine(outDir, "tab-oracle.json"),
                JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "tab-oracle.txt"), human.ToString(), new UTF8Encoding(false));
            Console.WriteLine("cases: " + cases.Count);
            return 0;
        }

        private static string TabsText(List<object> tabs)
        {
            var sb = new StringBuilder();
            foreach (var o in tabs)
            {
                var t = (Dictionary<string, object>)o;
                sb.Append($" [i={t["i"]} x={F((double)t["xFromLeftDip"])} advance={F((double)t["advanceDip"])} reachedStop={F((double)t["reachedStopDip"])}]");
            }
            return sb.ToString();
        }

        private static Dictionary<string, object> Measure(TextFormatter formatter, string id, string text, string note,
            double paragraphWidth, FlowDirection flow, double indent, string font, string fontSha, double emSize = EmSize)
        {
            var props = new Props(new Typeface(font), emSize);
            var para = new ParaProps(flow, props, indent);
            var source = new StringSource(text, props);
            TextLine line = formatter.FormatLine(source, 0, paragraphWidth, para, null);

            var perChar = new List<object>();
            int charCount = Math.Min(line.Length, text.Length);
            for (int i = 0; i < charCount; i++)
            {
                IList<TextBounds> b = line.GetTextBounds(i, 1);
                if (b == null || b.Count == 0)
                {
                    perChar.Add(new Dictionary<string, object> { ["i"] = i, ["char"] = text[i].ToString(), ["x"] = null, ["width"] = null, ["xFromLeftDip"] = null, ["flowDirection"] = null });
                    continue;
                }
                perChar.Add(new Dictionary<string, object>
                {
                    ["i"] = i,
                    ["char"] = text[i].ToString(),
                    ["codePoint"] = "U+" + ((int)text[i]).ToString("X4"),
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

            var tabs = new List<object>();
            int tabCount = 0;
            for (int i = 0; i < charCount; i++)
            {
                if (text[i] != '\t') continue;
                tabCount++;
                var d = (Dictionary<string, object>)perChar[i];
                if (d["xFromLeftDip"] == null) { tabs.Add(new Dictionary<string, object> { ["i"] = i, ["note"] = "no bounds reported" }); continue; }
                double x = (double)d["xFromLeftDip"];
                double w = (double)d["width"];
                object nextXObj = null;
                if (i + 1 < charCount)
                {
                    var nxt = (Dictionary<string, object>)perChar[i + 1];
                    if (nxt["xFromLeftDip"] != null) nextXObj = nxt["xFromLeftDip"];
                }
                // The measured advance IS TextBounds width.  A "next character x minus tab x" derivation only
                // holds when the next logical character is physically to the right of the tab, which is NOT
                // true in a RightToLeft paragraph - so only emit it when that precondition holds and say so.
                double? derived = null;
                if (nextXObj != null && (double)nextXObj > x) derived = (double)nextXObj - x;
                tabs.Add(new Dictionary<string, object>
                {
                    ["i"] = i,
                    ["xFromLeftDip"] = R(x),
                    ["advanceDip"] = R(w),                       // primary: measured tab advance
                    ["advanceSource"] = "TextBounds.Rectangle.Width from GetTextBounds(tabIndex,1)",
                    // the stop the tab actually reached: tabs advance along the flow direction, so for
                    // RightToLeft that is the tab's LEFT edge and for LeftToRight its RIGHT edge
                    ["reachedStopDip"] = R(flow == FlowDirection.RightToLeft ? x : x + w),
                    ["tabSpanDip"] = new Dictionary<string, object> { ["left"] = R(x), ["right"] = R(x + w) },
                    ["nextLogicalCharXFromLeftDip"] = nextXObj == null ? null : R((double)nextXObj),
                    ["derivedAdvanceDip"] = derived == null ? null : R(derived.Value),
                    ["derivedAdvanceNote"] = derived == null
                        ? "not emitted: the next logical character is not to the right of the tab (RightToLeft paragraphs reorder it), so only advanceDip is valid"
                        : "cross-check: next logical character x minus tab x (equals advanceDip)",
                    ["isLastChar"] = i == charCount - 1,
                });
            }

            object whole = null;
            var wb = line.GetTextBounds(0, line.Length);
            if (wb != null && wb.Count > 0)
                whole = new Dictionary<string, object>
                {
                    ["x"] = R(wb[0].Rectangle.X), ["y"] = R(wb[0].Rectangle.Y),
                    ["width"] = R(wb[0].Rectangle.Width), ["height"] = R(wb[0].Rectangle.Height),
                    ["fragments"] = wb.Count,
                };

            var spans = new List<object>();
            int cum = (int)line.Start;
            foreach (TextSpan<TextRun> span in line.GetTextRunSpans())
            {
                spans.Add(new Dictionary<string, object> { ["start"] = cum, ["length"] = span.Length, ["type"] = span.Value.GetType().Name });
                cum += span.Length;
            }

            return new Dictionary<string, object>
            {
                ["id"] = id + "@w" + paragraphWidth.ToString("0", CultureInfo.InvariantCulture) + "@" + (flow == FlowDirection.RightToLeft ? "RTL" : "LTR"),
                ["text"] = text,
                ["note"] = note,
                ["paragraphWidthDip"] = paragraphWidth,
                ["indentDip"] = indent,
                ["flowDirection"] = flow == FlowDirection.RightToLeft ? "RightToLeft" : "LeftToRight",
                ["fontFamily"] = font, ["fontSha256"] = fontSha, ["emSizeDip"] = emSize, ["dpi"] = 96,
                ["lineLength"] = (int)line.Length,
                ["newlineLength"] = (int)line.NewlineLength,
                ["width"] = R(line.Width),
                ["widthIncludingTrailingWhitespace"] = R(line.WidthIncludingTrailingWhitespace),
                ["lineHeight"] = R(line.Height),
                ["baseline"] = R(line.Baseline),
                ["extent"] = R(SafeExtent(line)),
                ["textHeight"] = R(SafeTextHeight(line)),
                ["trailingWhitespaceLength"] = (int)line.TrailingWhitespaceLength,
                ["hasOverflowed"] = line.HasOverflowed,
                ["tabCount"] = tabCount,
                ["tabs"] = tabs,
                ["wholeLineBounds"] = whole,
                ["perChar"] = perChar,
                ["runSpans"] = spans,
            };
        }

        // Extent/TextHeight are on TextLine but are easy to get wrong across runtimes; probe defensively.
        private static double SafeExtent(TextLine line)
        {
            try { var pi = typeof(TextLine).GetProperty("Extent"); if (pi != null) return (double)pi.GetValue(line); } catch { }
            return double.NaN;
        }
        private static double SafeTextHeight(TextLine line)
        {
            try { var pi = typeof(TextLine).GetProperty("TextHeight"); if (pi != null) return (double)pi.GetValue(line); } catch { }
            return double.NaN;
        }

        private static string Esc(string s) => s.Replace("\t", "\\t");
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

    internal sealed class ParaProps : TextParagraphProperties
    {
        public ParaProps(FlowDirection flow, TextRunProperties props, double indent)
        { FlowDirection = flow; DefaultTextRunProperties = props; Indent = indent; }
        public override FlowDirection FlowDirection { get; }
        public override TextAlignment TextAlignment => TextAlignment.Left;
        public override double LineHeight => double.NaN;
        public override bool FirstLineInParagraph => true;
        public override TextRunProperties DefaultTextRunProperties { get; }
        public override TextWrapping TextWrapping => TextWrapping.NoWrap;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override double Indent { get; }
        public override double ParagraphIndent => 0;
    }
}

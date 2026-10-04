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

namespace BidiOracle
{
    /// <summary>
    /// U1 (Windows real-machine lane): mixed-direction text oracle.
    ///
    /// Measures with the same layer WPF itself uses for text lines:
    ///   TextFormatter.Create().FormatLine(...)  ->  TextLine
    ///   TextLine.GetTextBounds(i, 1)            ->  per-character x/width
    ///   TextLine.GetTextBounds(0, Length)       ->  whole-line bounds
    ///   TextLine.GetTextRunSpans()              ->  run boundaries and TextEndOfParagraph positions
    ///
    /// The font is chosen so that it covers EVERY code point in the corpus (verified through
    /// GlyphTypeface.CharacterToGlyphMap), so no font fallback can perturb the segmentation.
    /// </summary>
    public static class Program
    {
        private const double EmSize = 24.0;
        private const double ParagraphWidth = 10000.0;   // wide enough that nothing wraps

        private static readonly string[] FontCandidates = { "Arial", "Segoe UI", "Tahoma", "Times New Roman", "David" };

        // the exact corpus requested (plus the two controls, which are the first two)
        private static readonly (string Id, string Text, string Note)[] Corpus =
        {
            ("he-pure",        "שלום עולם",         "CONTROL: pure RTL (Hebrew + space)"),
            ("ltr-pure",       "abc 123",           "CONTROL: pure LTR (Latin + digits)"),
            ("ltr-digits",     "123 abc",           "LTR start with digits"),
            ("he-period",      "שלום.",             "RTL + neutral period at the end"),
            ("he-123",         "שלום 123",          "RTL + European digits (the reported failure case)"),
            ("he-123-he",      "שלום 123 עולם",     "RTL + digits + RTL"),
            ("he-latin",       "שלום abc",          "RTL + Latin word"),
            ("latin-he",       "abc שלום",          "LTR + Hebrew word"),
            ("mixed-long",     "abc שלום 123 def",  "LTR + RTL + digits + LTR"),
        };

        public static int Main(string[] args)
        {
            string outDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\out-bidi";
            Directory.CreateDirectory(outDir);

            // ---- pick a font that covers the whole corpus, and prove it ----
            var allCodePoints = new SortedSet<int>();
            foreach (var c in Corpus) foreach (char ch in c.Text) allCodePoints.Add(ch);

            string chosen = null, fontUri = null, fontSha = null;
            var coverageRows = new List<object>();
            foreach (string fam in FontCandidates)
            {
                var tf = new Typeface(fam);
                if (!tf.TryGetGlyphTypeface(out GlyphTypeface gt)) { coverageRows.Add(new Dictionary<string, object> { ["family"] = fam, ["usable"] = false, ["reason"] = "TryGetGlyphTypeface failed" }); continue; }
                var missing = new List<string>();
                foreach (int cp in allCodePoints) if (!gt.CharacterToGlyphMap.ContainsKey(cp)) missing.Add("U+" + cp.ToString("X4"));
                coverageRows.Add(new Dictionary<string, object>
                {
                    ["family"] = fam, ["usable"] = missing.Count == 0, ["missingCodePoints"] = missing,
                    ["fontUri"] = gt.FontUri.ToString(),
                });
                if (missing.Count == 0 && chosen == null)
                {
                    chosen = fam; fontUri = gt.FontUri.ToString(); 
                    if (gt.FontUri.IsFile) fontSha = Sha256(gt.FontUri.LocalPath);
                }
            }
            if (chosen == null) { Console.Error.WriteLine("no candidate font covers the whole corpus; see coverage table"); return 3; }
            Console.WriteLine($"font: {chosen}  uri={fontUri}  sha256={fontSha}");

            var props = new Props(new Typeface(chosen), EmSize);
            var formatter = TextFormatter.Create();
            var cases = new List<object>();
            var human = new StringBuilder();
            human.AppendLine("WPF mixed-direction text oracle (human readable)");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine("font: " + chosen + "  (" + fontUri + ")");
            human.AppendLine("emSize: 24 DIP, paragraphWidth: 10000 DIP, units: DIP @96dpi");
            human.AppendLine();

            foreach (var c in Corpus)
            {
                foreach (var flow in new[] { FlowDirection.LeftToRight, FlowDirection.RightToLeft })
                {
                    var para = new ParaProps(flow, props);
                    var source = new StringSource(c.Text, props);
                    TextLine line = formatter.FormatLine(source, 0, ParagraphWidth, para, null);

                    var perChar = new List<object>();
                    // line.Length counts the TextEndOfParagraph mark, so clamp to the real text length
                    int charCount = Math.Min(line.Length, c.Text.Length);
                    for (int i = 0; i < charCount; i++)
                    {
                        IList<TextBounds> bounds = line.GetTextBounds(i, 1);
                        if (bounds == null || bounds.Count == 0) { perChar.Add(new Dictionary<string, object> { ["i"] = i, ["char"] = c.Text[i].ToString(), ["codePoint"] = "U+" + ((int)c.Text[i]).ToString("X4"), ["x"] = null, ["width"] = null }); continue; }
                        TextBounds b = bounds[0];
                        var entry = new Dictionary<string, object>
                        {
                            ["i"] = i,
                            ["char"] = c.Text[i].ToString(),
                            ["codePoint"] = "U+" + ((int)c.Text[i]).ToString("X4"),
                            ["x"] = R(b.Rectangle.X), ["width"] = R(b.Rectangle.Width),
                            ["flowDirection"] = b.FlowDirection.ToString(),
                            ["boundsFragments"] = bounds.Count,
                        };
                        if (b.TextRunBounds != null && b.TextRunBounds.Count > 0)
                        {
                            // reflect instead of guessing member names: the emitted JSON then documents
                            // exactly which fields WPF's TextRunBounds exposes on this runtime
                            var frags = new List<object>();
                            foreach (var trb in b.TextRunBounds)
                            {
                                var fd = new Dictionary<string, object>();
                                foreach (var pi in trb.GetType().GetProperties())
                                {
                                    object v;
                                    try { v = pi.GetValue(trb); } catch { continue; }
                                    if (v is Rect r2) fd[pi.Name] = new Dictionary<string, object> { ["x"] = R(r2.X), ["y"] = R(r2.Y), ["width"] = R(r2.Width), ["height"] = R(r2.Height) };
                                    else if (v is double dv) fd[pi.Name] = R(dv);
                                    else fd[pi.Name] = v == null ? null : v.ToString();
                                }
                                frags.Add(fd);
                            }
                            entry["textRunBounds"] = frags;
                        }
                        perChar.Add(entry);
                    }

                    // TextBounds.X is measured from the LINE ORIGIN, and for an RTL paragraph that origin
                    // is the right edge - so raw x increases leftwards there.  Normalise to a left-edge
                    // based coordinate so both directions can be read (and compared) the same way.
                    double inkRight = 0;
                    foreach (var o in perChar)
                    {
                        var d = (Dictionary<string, object>)o;
                        if (d["x"] != null) { double r = (double)d["x"] + (double)d["width"]; if (r > inkRight) inkRight = r; }
                    }
                    foreach (var o in perChar)
                    {
                        var d = (Dictionary<string, object>)o;
                        if (d["x"] == null) continue;
                        double raw = (double)d["x"], w = (double)d["width"];
                        d["xFromLeftDip"] = R(flow == FlowDirection.RightToLeft ? inkRight - (raw + w) : raw);
                    }

                    // whole-line bounds
                    object whole = null;
                    var wb = line.GetTextBounds(0, line.Length);
                    if (wb != null && wb.Count > 0)
                        whole = new Dictionary<string, object>
                        {
                            ["x"] = R(wb[0].Rectangle.X), ["y"] = R(wb[0].Rectangle.Y),
                            ["width"] = R(wb[0].Rectangle.Width), ["height"] = R(wb[0].Rectangle.Height),
                            ["fragments"] = wb.Count,
                        };

                    // run spans
                    var spans = new List<object>();
                    int cum = (int)line.Start;
                    foreach (TextSpan<TextRun> span in line.GetTextRunSpans())
                    {
                        var run = span.Value;
                        spans.Add(new Dictionary<string, object>
                        {
                            ["start"] = cum,
                            ["length"] = span.Length,
                            ["type"] = run.GetType().Name,
                            ["propertiesTypeface"] = (run.Properties != null && run.Properties.Typeface != null)
                                ? run.Properties.Typeface.FontFamily.Source : null,
                        });
                        cum += span.Length;
                    }

                    // visual order = characters sorted by their x position
                    var visual = new List<object>();
                    var ordered = new List<(double X, int I)>();
                    foreach (var o in perChar)
                    {
                        var d = (Dictionary<string, object>)o;
                        if (d["xFromLeftDip"] != null) ordered.Add(((double)d["xFromLeftDip"], (int)d["i"]));
                    }
                    ordered.Sort((a, b) => a.X.CompareTo(b.X));
                    for (int v = 0; v < ordered.Count; v++)
                        visual.Add(new Dictionary<string, object>
                        {
                            ["visualPos"] = v, ["logicalIndex"] = ordered[v].I,
                            ["char"] = c.Text[ordered[v].I].ToString(),
                            ["codePoint"] = "U+" + ((int)c.Text[ordered[v].I]).ToString("X4"),
                        });

                    string flowName = flow == FlowDirection.RightToLeft ? "RightToLeft" : "LeftToRight";
                    cases.Add(new Dictionary<string, object>
                    {
                        ["id"] = c.Id + "@" + flowName,
                        ["baseId"] = c.Id,
                        ["text"] = c.Text,
                        ["note"] = c.Note,
                        ["flowDirection"] = flowName,
                        ["fontFamily"] = chosen,
                        ["fontSha256"] = fontSha,
                        ["emSizeDip"] = EmSize,
                        ["dpi"] = 96,
                        ["line"] = new Dictionary<string, object>
                        {
                            ["start"] = line.Start, ["length"] = line.Length,
                            ["newlineLength"] = line.NewlineLength,
                            ["width"] = R(line.Width),
                            ["widthIncludingTrailingWhitespace"] = R(line.WidthIncludingTrailingWhitespace),
                            ["height"] = R(line.Height), ["baseline"] = R(line.Baseline),
                            ["hasOverflowed"] = line.HasOverflowed,
                            ["textLineCount"] = 1,
                        },
                        ["wholeLineBounds"] = whole,
                        ["perChar"] = perChar,
                        ["visualOrder"] = visual,
                        ["visualString"] = VisualString(c.Text, ordered),
                        ["runSpans"] = spans,
                    });

                    human.AppendLine($"== [{c.Id}] {flowName}  \"{c.Text}\"");
                    human.AppendLine($"   line: length={line.Length} newline={line.NewlineLength} width={F(line.Width)} height={F(line.Height)} baseline={F(line.Baseline)}");
                    var sb = new StringBuilder("   per-char x/width:");
                    foreach (var o in perChar) { var d = (Dictionary<string, object>)o; sb.Append($" {d["char"]}@{d["x"]}"); }
                    human.AppendLine(sb.ToString());
                    human.AppendLine("   visual(左→右): " + VisualString(c.Text, ordered));
                    var sb2 = new StringBuilder("   runSpans:");
                    foreach (var o in spans) { var d = (Dictionary<string, object>)o; sb2.Append($" [{d["start"]},{d["type"]}]"); }
                    human.AppendLine(sb2.ToString());
                }
            }

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-bidi-oracle/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["os"] = Environment.OSVersion.VersionString,
                ["clr"] = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
                ["presentationCore"] = typeof(TextFormatter).Assembly.GetName().Version.ToString(),
                ["measurement"] = "System.Windows.Media.TextFormatting.TextFormatter.FormatLine -> TextLine.GetTextBounds(i,1) / GetTextBounds(0,Length) / GetTextRunSpans",
                ["dpi"] = 96,
                ["units"] = "DIP (1/96 inch). TextFormatter is resolution independent; x/width are DIPs and do not depend on the monitor DPI",
                ["emSizeDip"] = EmSize,
                ["paragraphWidthDip"] = ParagraphWidth,
                ["fontFamily"] = chosen,
                ["fontUri"] = fontUri,
                ["fontSha256"] = fontSha,
                ["fontSelection"] = "first candidate whose GlyphTypeface.CharacterToGlyphMap covers every code point in the corpus, so WPF font fallback cannot split the runs",
                ["fontCoverageTable"] = coverageRows,
                ["corpusCodePoints"] = CodePointList(allCodePoints),
                ["noteOnXCoordinates"] = "perChar[].x/width are the RAW TextBounds.Rectangle values. Their origin is the line origin, " +
                                 "which for a RightToLeft paragraph is the RIGHT edge, so raw x grows leftwards there. " +
                                 "perChar[].xFromLeftDip is the normalised value (distance of the character's left edge from the " +
                                 "line's left edge) and is directly comparable across both flow directions.",
        ["noteOnVisualOrder"] = "visualOrder is derived from xFromLeftDip sorted ascending, i.e. what you see when scanning the line left to right",
                ["cases"] = cases,
            };
            File.WriteAllText(Path.Combine(outDir, "bidi-oracle.json"),
                JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "bidi-oracle.txt"), human.ToString(), new UTF8Encoding(false));
            Console.WriteLine("cases: " + cases.Count);
            return 0;
        }

        private static List<object> CodePointList(SortedSet<int> cps)
        {
            var list = new List<object>();
            foreach (int cp in cps) list.Add("U+" + cp.ToString("X4"));
            return list;
        }

        private static string VisualString(string text, List<(double X, int I)> ordered)
        {
            var sb = new StringBuilder();
            foreach (var (x, i) in ordered) sb.Append(text[i]);
            return sb.ToString();
        }

        private static double R(double v) => Math.Round(v, 6, MidpointRounding.AwayFromZero);
        private static string F(double v) => v.ToString("0.######", CultureInfo.InvariantCulture);

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
        public override TextRun GetTextRun(int textSourceCharacterIndex)
        {
            if (textSourceCharacterIndex < _text.Length)
                return new TextCharacters(_text, textSourceCharacterIndex, _text.Length - textSourceCharacterIndex, _props);
            return new TextEndOfParagraph(1);
        }
        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int textSourceCharacterIndexLimit)
        {
            int len = Math.Min(Math.Max(textSourceCharacterIndexLimit, 0), _text.Length);
            var range = new CharacterBufferRange(_text, 0, len);
            return new TextSpan<CultureSpecificCharacterBufferRange>(len,
                new CultureSpecificCharacterBufferRange(CultureInfo.CurrentCulture, range));
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
        public ParaProps(FlowDirection flow, TextRunProperties props) { FlowDirection = flow; DefaultTextRunProperties = props; }
        public override FlowDirection FlowDirection { get; }
        public override TextAlignment TextAlignment => TextAlignment.Left;
        public override double LineHeight => double.NaN;
        public override bool FirstLineInParagraph => true;
        public override TextRunProperties DefaultTextRunProperties { get; }
        public override TextWrapping TextWrapping => TextWrapping.NoWrap;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override double Indent => 0;
        public override double ParagraphIndent => 0;
    }
}

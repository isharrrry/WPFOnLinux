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

namespace ModifierCloseOracle
{
    /// <summary>
    /// ONE question: when a NON-LAST line's last character is exactly the position where the client returns
    /// TextEndOfSegment, is GetTextLineBreak() null (=> the close marker is NOT part of the scope,
    /// i.e. `closeMarker` is the right symbol) or non-null (=> the close marker is still inside the scope,
    /// and the pop happens when the NEXT run is fetched, i.e. `closeMarker + 1`)?
    ///
    /// Self-calibrating: the paragraph is measured once at a huge width to find P = the box position where the
    /// close marker sits (it has zero width), and the widths under test are P-2 .. P+24 so the break lands
    /// just before, exactly at, and just after that point.
    /// </summary>
    public static class Program
    {
        private const double EmSize = 24.0;
        private const double Dpi = 96.0;
        private const char OPEN = '\uE000';
        private const char CLOSE = '\uE001';

        // 10 x 'c' = exactly 120.000000 DIP, then the scope "abc", then the close marker, then 12 x 'c'
        private static readonly string Buffer = "cccccccccc" + OPEN + "abc" + CLOSE + "cccccccccccc";
        private const int OpenIndex = 10;
        private const int CloseIndex = 14;

        public static int Main(string[] args)
        {
            string outDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\out-modifierclose";
            Directory.CreateDirectory(outDir);

            string font = "Arial";
            var face = new Typeface(font);
            string fontSha = null, fontUri = null;
            if (face.TryGetGlyphTypeface(out GlyphTypeface gt)) { fontUri = gt.FontUri.ToString(); if (gt.FontUri.IsFile) fontSha = Sha256(gt.FontUri.LocalPath); }

            var formatter = TextFormatter.Create();
            var human = new StringBuilder();
            human.AppendLine("WPF oracle - is the TextEndOfSegment position inside or outside the scope? (RAW machine output)");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine("machine: " + Environment.OSVersion.VersionString + " | " +
                             System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription +
                             " | PresentationCore " + typeof(TextFormatter).Assembly.GetName().Version);
            human.AppendLine("font: " + font + " sha256=" + fontSha);
            human.AppendLine($"Dpi={Dpi} emSize={EmSize}");
            human.AppendLine($"buffer=\"{Esc(Buffer)}\"  openIndex={OpenIndex} closeIndex={CloseIndex} bufferLength={Buffer.Length}");
            human.AppendLine();

            // ---- calibration pass at a huge width: locate the close marker's box position ----
            double pClose = double.NaN, pBeforeClose = double.NaN;
            {
                var (lines, _) = Run(formatter, font, 4000.0);
                foreach (var Lo in lines)
                {
                    var L0 = (Dictionary<string, object>)Lo;
                    foreach (var p in (List<object>)L0["perChar"])
                    {
                        var d = (Dictionary<string, object>)p;
                        if ((int)d["i"] == CloseIndex && d["rawX"] != null) pClose = (double)d["rawX"];
                        if ((int)d["i"] == CloseIndex - 1 && d["rawX"] != null) pBeforeClose = (double)d["rawX"] + (double)d["width"];
                    }
                }
            }
            human.AppendLine($"calibration: the close marker (zero width) sits at box position {pClose.ToString("0.######", CultureInfo.InvariantCulture)}; " +
                             $"the character before it ends at {pBeforeClose.ToString("0.######", CultureInfo.InvariantCulture)}");
            human.AppendLine();

            var widths = new List<double>();
            if (!double.IsNaN(pClose))
            {
                widths.Add(pClose - 30.0);   // break well before the scope
                widths.Add(pClose - 2.0);
                widths.Add(pClose - 1.0);
                widths.Add(pClose - 0.001);
                widths.Add(pClose);          // exactly at the close marker
                widths.Add(pClose + 0.001);
                widths.Add(pClose + 1.0);
                widths.Add(pClose + 11.999);
                widths.Add(pClose + 12.0);   // exactly after one more 'c'
                widths.Add(pClose + 12.001);
                widths.Add(pClose + 24.0);
            }
            widths.Add(4000.0);

            var cases = new List<object>();
            foreach (double w in widths)
            {
                var (lines, breaks) = Run(formatter, font, w);
                var rec = new Dictionary<string, object>
                {
                    ["id"] = "modifier-close/w" + w.ToString("0.###", CultureInfo.InvariantCulture),
                    ["group"] = "close-marker-boundary",
                    ["paragraphWidthDip"] = w,
                    ["calibratedCloseMarkerPositionDip"] = Absent(pClose),
                    ["openIndex"] = OpenIndex,
                    ["closeIndex"] = CloseIndex,
                    ["bufferLength"] = Buffer.Length,
                    ["bufferWithMarkers"] = Esc(Buffer),
                    ["fontFamily"] = font, ["fontUri"] = fontUri, ["fontSha256"] = fontSha,
                    ["dpi"] = Dpi, ["emSizeDip"] = EmSize,
                    ["lineCount"] = lines.Count,
                    ["lines"] = lines,
                    ["lineBreaks"] = breaks,
                };
                cases.Add(rec);
                var l0 = lines.Count > 0 ? (Dictionary<string, object>)lines[0] : null;
                human.AppendLine($"== [w={w.ToString("0.###", CultureInfo.InvariantCulture)}] lines={lines.Count} " +
                                 (l0 == null ? "" : $"line0=[{l0["startChar"]},{l0["endCharExclusive"]}) text=\"{Esc((string)l0["lineText"])}\" " +
                                  $"endVsClose={(int)l0["endCharExclusive"] - CloseIndex} breakIsNull={((Dictionary<string, object>)breaks[0])["isNull"]}"));
            }

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-modifier-close-raw/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["os"] = Environment.OSVersion.VersionString,
                ["clr"] = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
                ["presentationCore"] = typeof(TextFormatter).Assembly.GetName().Version.ToString(),
                ["measurement"] = "TextFormatter.Create().FormatLine(...) looped over TextLine.GetTextLineBreak(); every line's " +
                                  "character range and the break's null-ness are recorded",
                ["dpi"] = Dpi, ["units"] = "DIP (1/96 inch)", ["emSizeDip"] = EmSize,
                ["fontFamily"] = font, ["fontUri"] = fontUri, ["fontSha256"] = fontSha,
                ["markers"] = "U+E000 = the index where the TextSource returns a TextModifier run (length 1, zero width); " +
                              "U+E001 = the index where it returns TextEndOfSegment(1). Neither is ever returned as text.",
                ["paragraphProperties"] = "TextAlignment=Left, TextWrapping=Wrap, LineHeight=0, Tabs=null, Indent=0, " +
                                          "ParagraphIndent=0, DefaultIncrementalTab not overridden",
                ["calibration"] = new Dictionary<string, object>
                { ["closeMarkerBoxPositionDip"] = Absent(pClose), ["charBeforeCloseEndsAtDip"] = Absent(pBeforeClose) },
                ["cases"] = cases,
            };

            var seen = new HashSet<string>();
            foreach (var o in cases) { var d = (Dictionary<string, object>)o; if (!seen.Add((string)d["id"])) { Console.Error.WriteLine("DUPLICATE CASE ID: " + d["id"]); return 4; } }

            File.WriteAllText(Path.Combine(outDir, "modifier-close-raw.json"),
                JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "modifier-close-raw.txt"), human.ToString(), new UTF8Encoding(false));
            Console.WriteLine("cases: " + cases.Count + "  calibratedCloseMarkerDip=" + pClose.ToString("0.######", CultureInfo.InvariantCulture));
            foreach (var o in cases)
            {
                var c = (Dictionary<string, object>)o;
                var ls = (List<object>)c["lines"];
                var bs = (List<object>)c["lineBreaks"];
                var sb = new StringBuilder();
                for (int i = 0; i < ls.Count; i++)
                {
                    var L = (Dictionary<string, object>)ls[i];
                    sb.Append("[[" + L["startChar"] + "," + L["endCharExclusive"] + ") " +
                              (((Dictionary<string, object>)bs[i])["isNull"] == null ? "?" :
                              ((bool)((Dictionary<string, object>)bs[i])["isNull"] ? "NULL" : "nonNull")) + "] ");
                }
                Console.WriteLine("W " + c["id"] + " w=" + ((double)c["paragraphWidthDip"]).ToString("0.###", CultureInfo.InvariantCulture) +
                                  "  endVsClose(line0)=" + (ls.Count > 0 ? (((int)((Dictionary<string, object>)ls[0])["endCharExclusive"]) - CloseIndex).ToString() : "n/a") +
                                  "  " + sb);
            }
            return 0;
        }

        private static object Absent(double v) => (double.IsNaN(v) || double.IsInfinity(v)) ? null : (object)Math.Round(v, 6);

        private static (List<object>, List<object>) Run(TextFormatter formatter, string font, double width)
        {
            var props = new Props(new Typeface(font), EmSize);
            var para = new Para(props, FlowDirection.LeftToRight);
            var src = new Source(props, width);
            var lines = new List<object>();
            var breaks = new List<object>();
            int index = 0, guard = 0;
            TextLineBreak brk = null;
            while (index < Buffer.Length && guard++ < 64)
            {
                TextLine line = formatter.FormatLine(src, index, width, para, brk);
                TextLineBreak tb = null;
                string err = null;
                try { tb = line.GetTextLineBreak(); } catch (Exception e) { err = e.GetType().Name; }
                int len = (int)line.Length;
                int textLen = len - (int)line.NewlineLength;
                if (index + textLen > Buffer.Length) textLen = Math.Max(Buffer.Length - index, 0);
                var per = new List<object>();
                for (int i = 0; i < textLen; i++)
                {
                    int gi = index + i;
                    if (gi >= Buffer.Length) break;
                    IList<TextBounds> b = null;
                    try { b = line.GetTextBounds(gi, 1); } catch { }
                    per.Add(new Dictionary<string, object>
                    {
                        ["i"] = gi, ["char"] = Buffer[gi].ToString(),
                        ["kind"] = gi == OpenIndex ? "OPEN-MARKER" : gi == CloseIndex ? "CLOSE-MARKER" : "char",
                        ["rawX"] = b != null && b.Count > 0 ? Absent(b[0].Rectangle.X) : null,
                        ["width"] = b != null && b.Count > 0 ? Absent(b[0].Rectangle.Width) : null,
                    });
                }
                lines.Add(new Dictionary<string, object>
                {
                    ["index"] = lines.Count, ["startChar"] = index, ["endCharExclusive"] = index + textLen,
                    ["lineText"] = Buffer.Substring(index, Math.Min(textLen, Buffer.Length - index)),
                    ["width"] = Absent(line.Width), ["hasOverflowed"] = line.HasOverflowed,
                    ["containsCloseMarker"] = CloseIndex >= index && CloseIndex < index + textLen,
                    ["endMinusCloseIndex"] = (index + textLen) - CloseIndex,
                    ["perChar"] = per,
                });
                breaks.Add(new Dictionary<string, object>
                {
                    ["lineIndex"] = lines.Count - 1,
                    ["isNull"] = err == null ? (object)(tb == null) : null,
                    ["error"] = err,
                });
                if (brk != null) brk.Dispose();
                brk = tb;
                if (len <= 0) break;
                index += len;
            }
            if (brk != null) brk.Dispose();
            return (lines, breaks);
        }

        private static string Esc(string s) => s == null ? "" : s.Replace("\t", "\\t")
            .Replace(OPEN.ToString(), "<OPEN>").Replace(CLOSE.ToString(), "<CLOSE>");

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

    internal sealed class Source : TextSource
    {
        private readonly string _text;
        private readonly TextRunProperties _props;
        public Source(TextRunProperties props, double width) { _props = props; _text = "cccccccccc\uE000abc\uE001cccccccccccc"; }
        public override TextRun GetTextRun(int index)
        {
            if (index >= _text.Length) return new TextEndOfParagraph(1);
            if (index == 10) return new Marker(1, _props);
            if (index == 14) return new TextEndOfSegment(1);
            int next = _text.Length;
            if (10 > index) next = Math.Min(next, 10);
            if (14 > index) next = Math.Min(next, 14);
            return new TextCharacters(_text, index, next - index, _props);
        }
        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
        {
            int len = Math.Min(Math.Max(limit, 0), _text.Length);
            return new TextSpan<CultureSpecificCharacterBufferRange>(len,
                new CultureSpecificCharacterBufferRange(CultureInfo.CurrentCulture, new CharacterBufferRange(_text, 0, len)));
        }
        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
    }

    internal sealed class Marker : TextModifier
    {
        private readonly TextRunProperties _props;
        public Marker(int length, TextRunProperties props) { Length = length; _props = props; }
        public override int Length { get; }
        public override TextRunProperties Properties => null;
        public override bool HasDirectionalEmbedding => false;
        public override FlowDirection FlowDirection => FlowDirection.LeftToRight;
        public override TextRunProperties ModifyProperties(TextRunProperties properties) => properties;
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

    internal sealed class Para : TextParagraphProperties
    {
        public Para(TextRunProperties props, FlowDirection flow) { DefaultTextRunProperties = props; FlowDirection = flow; }
        public override TextRunProperties DefaultTextRunProperties { get; }
        public override FlowDirection FlowDirection { get; }
        public override TextAlignment TextAlignment => TextAlignment.Left;
        public override TextWrapping TextWrapping => TextWrapping.Wrap;
        public override double LineHeight => 0;
        public override bool FirstLineInParagraph => true;
        public override double Indent => 0;
        public override double ParagraphIndent => 0;
        public override bool AlwaysCollapsible => false;
        public override TextDecorationCollection TextDecorations => null;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override IList<TextTabProperties> Tabs => null;
    }
}

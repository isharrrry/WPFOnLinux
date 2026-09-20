using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace FontFallbackOracle
{
    /// <summary>One code point to probe.</summary>
    internal sealed class CpInfo
    {
        public int CodePoint; public string Name, Note;
        public CpInfo(int cp, string name, string note) { CodePoint = cp; Name = name; Note = note; }
        public string Text { get { return char.ConvertFromUtf32(CodePoint); } }
        public string Tag { get { return "U+" + CodePoint.ToString("X4"); } }
    }

    /// <summary>One paragraph under test (used by the directional-embedding group).</summary>
    internal sealed class Doc
    {
        public string Group, Id, Note, Buffer;
        public int OpenIndex = -1, CloseIndex = -1;
        public string EmbMode = "none";     // none | identity | ltr-embed | rtl-embed
        public Doc(string group, string id, string note, string buffer) { Group = group; Id = id; Note = note; Buffer = buffer; }
        public Doc WithMarkers(int open, int close) { OpenIndex = open; CloseIndex = close; return this; }
        public string VisibleText
        {
            get
            {
                var sb = new StringBuilder();
                foreach (char c in Buffer) if (c != Model.OpenMarker && c != Model.CloseMarker) sb.Append(c);
                return sb.ToString();
            }
        }
    }

    internal static class Model
    {
        public const char OpenMarker = '\uE000';
        public const char CloseMarker = '\uE001';
    }

    internal sealed class FontSetting
    {
        public string Id, Kind, Spec, Note;
        public Typeface Typeface;
        public GlyphTypeface Gt;                // resolved primary glyph face (null if unresolvable)
        public string ResolveError;
        public bool Covers;                     // does Gt cover the code point under test
        public int GlyphIndex = -1;
        public double GlyphAdvanceEm = double.NaN;
        public double NotdefAdvanceEm = double.NaN;
        public int FamilyCount;
    }

    public static class Program
    {
        internal const double EmSize = 24.0;
        private const double Width = 400.0;
        private const double Dpi = 96.0;
        private const string NotoDir = @"C:\u1-shaping\fonts";
        private const string NotoFile = @"C:\u1-shaping\fonts\NotoSans-Regular.ttf";

        private static readonly string[] Candidates =
        {
            "Microsoft YaHei", "SimSun", "Microsoft JhengHei", "Segoe UI Symbol", "Cambria Math",
            "Segoe UI", "Tahoma", "Times New Roman", "Arial", "MS Gothic", "Malgun Gothic", "Yu Gothic", "Meiryo",
        };

        public static int Main(string[] args)
        {
            string outDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\out-fontfallback";
            Directory.CreateDirectory(outDir);

            var cps = new[]
            {
                new CpInfo(0x4E0E, "CJK 'and/with'", "the code point of the project's field case D-F1"),
                new CpInfo(0x6C49, "CJK 'Han'",      "a second CJK code point"),
                new CpInfo(0x05D0, "HEBREW ALEF",    "Hebrew: covered by Arial, so it doubles as an 'present' control"),
                new CpInfo(0x0627, "ARABIC ALEF",    "Arabic: covered by Arial as well"),
                new CpInfo(0x2192, "RIGHTWARDS ARROW", "usually present only in symbol fonts / math fonts"),
                new CpInfo(0xE000, "PRIVATE USE (BMP)", "BMP private use area: expected in no font"),
                new CpInfo(0x10FFFD, "PRIVATE USE (plane 16)", "supplementary private use area: expected in no font, and it needs a surrogate pair"),
            };

            var formatter = TextFormatter.Create();
            var cases = new List<object>();
            var human = new StringBuilder();
            human.AppendLine("WPF oracle - missing-glyph advance / font fallback (RAW machine output)");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine("machine: " + Environment.OSVersion.VersionString + " | " +
                             System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription +
                             " | PresentationCore " + typeof(TextFormatter).Assembly.GetName().Version);
            human.AppendLine($"Dpi={Dpi} emSize={EmSize} paragraphWidth={Width} TextWrapping=Wrap TextAlignment=Left");
            human.AppendLine("observed font/glyph come from the PUBLIC API TextLine.GetIndexedGlyphRuns() -> GlyphRun.GlyphTypeface / .GlyphIndices");
            human.AppendLine();

            // ---------------- how many INSTALLED fonts cover each code point ----------------
            // This turns "no font on this machine has it" from an assumption into a measured count.
            var systemCoverage = new Dictionary<string, object>();
            foreach (var cp in cps)
            {
                int families = 0, faces = 0, coveringFamilies = 0, coveringFaces = 0;
                var examples = new List<object>();
                foreach (FontFamily fam in Fonts.SystemFontFamilies)
                {
                    families++;
                    bool famCovers = false;
                    foreach (Typeface tf in fam.GetTypefaces())
                    {
                        faces++;
                        if (!tf.TryGetGlyphTypeface(out GlyphTypeface g)) continue;
                        if (g.CharacterToGlyphMap.ContainsKey(cp.CodePoint))
                        {
                            coveringFaces++;
                            famCovers = true;
                            if (examples.Count < 6)
                                examples.Add(new Dictionary<string, object>
                                {
                                    ["family"] = fam.Source ?? (fam.FamilyNames.Count > 0 ? FirstName(fam) : null),
                                    ["fontUri"] = g.FontUri.ToString(),
                                    ["glyphIndex"] = (int)g.CharacterToGlyphMap[cp.CodePoint],
                                    ["advanceEm"] = g.AdvanceWidths.ContainsKey(g.CharacterToGlyphMap[cp.CodePoint])
                                                    ? (object)Math.Round(g.AdvanceWidths[g.CharacterToGlyphMap[cp.CodePoint]], 6) : null,
                                });
                        }
                    }
                    if (famCovers) coveringFamilies++;
                }
                systemCoverage[cp.Tag] = new Dictionary<string, object>
                {
                    ["codePoint"] = cp.Tag, ["char"] = cp.Text,
                    ["installedFamilies"] = families, ["installedFacesChecked"] = faces,
                    ["familiesCovering"] = coveringFamilies, ["facesCovering"] = coveringFaces,
                    ["examples"] = examples,
                };
                human.AppendLine($"system font coverage {cp.Tag}: {coveringFamilies}/{families} families, {coveringFaces}/{faces} faces cover it");
            }
            human.AppendLine();

            // ---------------- item 1: missing-glyph advance / fallback ----------------
            foreach (var cp in cps)
            {
                foreach (var fs in BuildSettings(cp))
                {
                    cases.Add(MeasureCodePoint(formatter, cp, fs, human));
                }
            }

            // ---------------- item 2: TextModifier with directional embedding ----------------
            char O = Model.OpenMarker, C = Model.CloseMarker;
            var embDocs = new List<Doc>
            {
                new Doc("I-directional-embedding", "latin-scope-ltr-para",
                    "LTR paragraph, the modifier scope covers the Latin run 'abc' followed by Hebrew", "" + O + "abc" + C + "\u05D0\u05D1\u05D2"),
                new Doc("I-directional-embedding", "hebrew-scope-ltr-para",
                    "LTR paragraph, the modifier scope covers the Hebrew run followed by Latin", "" + O + "\u05D0\u05D1\u05D2" + C + "abc"),
                new Doc("I-directional-embedding", "hebrew-scope-rtl-para",
                    "RTL paragraph, the modifier scope covers the Hebrew run followed by Latin", "" + O + "\u05D0\u05D1\u05D2" + C + "abc"),
            };
            foreach (var d in embDocs)
                d.WithMarkers(0, 4);
            var modes = new[] { "identity", "ltr-embed", "rtl-embed" };
            // Two widths on purpose: at 40 DIP the text wraps into several lines, so GetTextLineBreak()
            // becomes informative (at 140 it fits on one line and every break is null by definition).
            var embWidths = new[] { 40.0, 140.0 };
            foreach (var d in embDocs)
            {
                foreach (double w in embWidths)
                {
                    foreach (string m in modes)
                    {
                        var doc = new Doc(d.Group, d.Id, d.Note, d.Buffer).WithMarkers(0, 4);
                        doc.EmbMode = m;
                        var flow = d.Id.EndsWith("rtl-para") ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
                        cases.Add(MeasureDoc(formatter, doc, flow, w, human));
                    }
                }
            }

            var seen = new HashSet<string>();
            foreach (var o in cases)
            {
                var d = (Dictionary<string, object>)o;
                if (!seen.Add((string)d["id"])) { Console.Error.WriteLine("DUPLICATE CASE ID: " + d["id"]); return 4; }
            }

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-font-fallback-raw/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["os"] = Environment.OSVersion.VersionString,
                ["clr"] = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
                ["presentationCore"] = typeof(TextFormatter).Assembly.GetName().Version.ToString(),
                ["measurement"] = "TextFormatter.Create().FormatLine(...); per-character advance from TextLine.GetTextBounds; " +
                                  "the ACTUAL font and glyph used from the public TextLine.GetIndexedGlyphRuns()",
                ["dpi"] = Dpi, ["units"] = "DIP (1/96 inch)", ["emSizeDip"] = EmSize, ["paragraphWidthDip"] = Width,
                ["notoFile"] = NotoFile,
                ["candidatesForExplicitCoveringFont"] = Candidates,
                ["installedFontCoveragePerCodePoint"] = systemCoverage,
                ["apiNotes"] = new Dictionary<string, object>
                {
                    ["howTheActualFontIsObserved"] = "TextLine.GetIndexedGlyphRuns() (PUBLIC) yields IndexedGlyphRun { TextSourceCharacterIndex, " +
                                                     "TextSourceLength, GlyphRun }; GlyphRun exposes GlyphTypeface (-> FontUri, FamilyNames), " +
                                                     "GlyphIndices, AdvanceWidths, BidiLevel and FontRenderingEmSize. No reflection was needed " +
                                                     "for any value in this oracle.",
                    ["glyphTypefaceAdvanceWidths"] = "GlyphTypeface.AdvanceWidths maps glyph index -> advance as a FRACTION OF EM; " +
                                                     "multiplying by emSize gives DIP. Glyph index 0 is .notdef.",
                    ["glyphRunAdvanceWidths"] = "GlyphRun.AdvanceWidths is reported as WPF returns it, next to the measured DIP advance, " +
                                                "so its unit can be read off the data instead of assumed.",
                },
                ["cases"] = cases,
            };

            File.WriteAllText(Path.Combine(outDir, "font-fallback-raw.json"),
                JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "font-fallback-raw.txt"), human.ToString(), new UTF8Encoding(false));

            Console.WriteLine("cases: " + cases.Count);
            foreach (var o in cases)
            {
                var c = (Dictionary<string, object>)o;
                if (!c.ContainsKey("codePoint")) continue;
                Console.WriteLine(string.Format(CultureInfo.InvariantCulture,
                    "CP {0,-9} {1,-34} specifiedCovers={2,-5} adv={3,10} 1em={4,-5} notdef={5,10} observedFont={6,-38} glyph={7,-6} notdefGlyph={8,-5} fallback={9}",
                    c["codePoint"], c["fontSettingId"], c["specifiedFontCoversCodePoint"],
                    F(c["measuredAdvanceDip"]), c["advanceEqualsOneEm"], F(c["specifiedFontNotdefAdvanceDip"]),
                    Short(c["observedFontUri"]), c["observedGlyphIndex"], c["observedGlyphIsNotdef"], c["fallbackToADifferentFont"]));
            }
            return 0;
        }

        // ============================ font settings ============================

        private static List<FontSetting> BuildSettings(CpInfo cp)
        {
            var list = new List<FontSetting>();

            list.Add(Resolve(new FontSetting
            {
                Id = "single-Arial", Kind = "single font family",
                Spec = "Typeface(\"Arial\")", Note = "one Latin family, no fallback declared",
                Typeface = new Typeface("Arial"),
            }, cp));

            list.Add(Resolve(new FontSetting
            {
                Id = "single-TimesNewRoman", Kind = "single font family",
                Spec = "Typeface(\"Times New Roman\")", Note = "a second Latin family, so the result does not hang on Arial alone",
                Typeface = new Typeface("Times New Roman"),
            }, cp));

            list.Add(Resolve(new FontSetting
            {
                Id = "file-NotoSans-Regular", Kind = "FILE font family",
                Spec = "FontFamily(new Uri(\"file:///C:/u1-shaping/fonts/\"), \"./#\" + <family name read from the ttf>)",
                Note = "the project's own situation: a font loaded from a file, not installed",
                Typeface = FileNotoTypeface(out _, out _, out _),
            }, cp));

            list.Add(Resolve(new FontSetting
            {
                Id = "list-Arial-SegoeUISymbol", Kind = "font family LIST",
                Spec = "FontFamily(\"Arial, Segoe UI Symbol\")", Note = "WPF FontFamily fallback list",
                Typeface = new Typeface(new FontFamily("Arial, Segoe UI Symbol"), FontStyles.Normal, FontWeights.Normal, FontStretches.Normal),
            }, cp));

            list.Add(Resolve(new FontSetting
            {
                Id = "typeface-declared-fallback-YaHei", Kind = "Typeface with a declared fallbackFontFamily",
                Spec = "Typeface(FontFamily(\"Arial\"), Normal, Normal, Normal, fallbackFontFamily: FontFamily(\"Microsoft YaHei\"))",
                Note = "WPF's explicit fallback constructor argument",
                Typeface = new Typeface(new FontFamily("Arial"), FontStyles.Normal, FontWeights.Normal, FontStretches.Normal,
                                        new FontFamily("Microsoft YaHei")),
            }, cp));

            // explicit family that really covers this code point (chosen at run time from the candidate list)
            string covering = null;
            GlyphTypeface coveringGt = null;
            foreach (string fam in Candidates)
            {
                if (new Typeface(fam).TryGetGlyphTypeface(out GlyphTypeface g) && g.CharacterToGlyphMap.ContainsKey(cp.CodePoint))
                { covering = fam; coveringGt = g; break; }
            }
            list.Add(Resolve(new FontSetting
            {
                Id = covering == null ? "explicit-covering-NONE-FOUND" : "explicit-covering-" + covering,
                Kind = "explicit family that DOES cover the code point",
                Spec = covering == null ? "no candidate family covers this code point" : "Typeface(\"" + covering + "\")",
                Note = covering == null ? "no covering family was found on this machine" : "positive control",
                Typeface = covering == null ? null : new Typeface(covering),
            }, cp));

            return list;
        }

        private static Typeface FileNotoTypeface(out string spec, out string err, out FontFamily fam)
        {
            fam = null; spec = null; err = null;
            try
            {
                var gt = new GlyphTypeface(new Uri("file:///" + NotoFile.Replace('\\', '/')));
                string name = null;
                foreach (var kv in gt.FamilyNames) { name = kv.Value; break; }
                if (name == null) { err = "no family name in the ttf"; return null; }
                fam = new FontFamily(new Uri("file:///" + NotoDir.Replace('\\', '/') + "/"), "./#" + name);
                spec = "FontFamily(file dir, \"./#" + name + "\")";
                return new Typeface(fam, FontStyles.Normal, FontWeights.Normal, FontStretches.Normal);
            }
            catch (Exception e) { err = e.GetType().Name + ": " + e.Message; return null; }
        }

        private static FontSetting Resolve(FontSetting s, CpInfo cp)
        {
            try
            {
                if (s.Typeface != null && s.Typeface.TryGetGlyphTypeface(out GlyphTypeface gt))
                {
                    s.Gt = gt;
                    s.FamilyCount = s.Typeface.FontFamily.FamilyNames.Count;
                    if (gt.AdvanceWidths.ContainsKey(0)) s.NotdefAdvanceEm = gt.AdvanceWidths[0];
                    s.Covers = gt.CharacterToGlyphMap.ContainsKey(cp.CodePoint);
                    if (s.Covers)
                    {
                        s.GlyphIndex = gt.CharacterToGlyphMap[cp.CodePoint];
                        if (gt.AdvanceWidths.ContainsKey((ushort)s.GlyphIndex)) s.GlyphAdvanceEm = gt.AdvanceWidths[(ushort)s.GlyphIndex];
                    }
                }
                else s.ResolveError = s.Typeface == null ? "no Typeface was constructed" : "TryGetGlyphTypeface failed";
            }
            catch (Exception e) { s.ResolveError = e.GetType().Name + ": " + e.Message; }
            return s;
        }

        // ============================ item 1 measurement ============================

        private static Dictionary<string, object> MeasureCodePoint(TextFormatter formatter, CpInfo cp, FontSetting fs, StringBuilder human)
        {
            string text = cp.Text;
            var props = new Props(fs.Typeface ?? new Typeface("Arial"), EmSize);
            var para = new Para(props, FlowDirection.LeftToRight);
            var src = new StringSource(text, props, null, -1, -1);

            double adv = double.NaN, lineW = double.NaN;
            bool ovf = false;
            string err = null;
            var runs = new List<object>();
            int observedGlyph = -1;
            string observedUri = null, observedFamilies = null;
            double observedRunAdvance = double.NaN;
            int observedBidi = -1;
            try
            {
                TextLine line = formatter.FormatLine(src, 0, Width, para, null);
                lineW = line.Width; ovf = line.HasOverflowed;
                IList<TextBounds> b = line.GetTextBounds(0, text.Length);
                if (b != null && b.Count > 0) adv = b[0].Rectangle.Width;
                foreach (IndexedGlyphRun igr in line.GetIndexedGlyphRuns())
                {
                    GlyphRun gr = igr.GlyphRun;
                    var row = new Dictionary<string, object>
                    {
                        ["textSourceCharacterIndex"] = igr.TextSourceCharacterIndex,
                        ["textSourceLength"] = igr.TextSourceLength,
                        ["glyphTypefaceFontUri"] = gr.GlyphTypeface == null ? null : gr.GlyphTypeface.FontUri.ToString(),
                        ["familyNames"] = FamilyNamesOf(gr.GlyphTypeface),
                        ["fontRenderingEmSize"] = RN(gr.FontRenderingEmSize),
                        ["bidiLevel"] = gr.BidiLevel,
                        ["glyphIndices"] = ToList(gr.GlyphIndices),
                        ["advanceWidthsAsReported"] = ToDoubleList(gr.AdvanceWidths),
                        ["characters"] = gr.Characters == null ? null : new string(ToCharArray(gr.Characters)),
                    };
                    runs.Add(row);
                    if (igr.TextSourceCharacterIndex <= 0 && 0 < igr.TextSourceCharacterIndex + igr.TextSourceLength)
                    {
                        observedUri = gr.GlyphTypeface == null ? null : gr.GlyphTypeface.FontUri.ToString();
                        observedFamilies = FamilyNamesOf(gr.GlyphTypeface);
                        observedBidi = gr.BidiLevel;
                        if (gr.GlyphIndices != null && gr.GlyphIndices.Count > 0) observedGlyph = gr.GlyphIndices[0];
                        if (gr.AdvanceWidths != null && gr.AdvanceWidths.Count > 0) observedRunAdvance = gr.AdvanceWidths[0];
                    }
                }
            }
            catch (Exception e) { err = e.GetType().Name + ": " + e.Message; }

            string specUri = fs.Gt == null ? null : fs.Gt.FontUri.ToString();
            bool fallback = observedUri != null && specUri != null && !string.Equals(observedUri, specUri, StringComparison.OrdinalIgnoreCase);
            double notdefDip = double.IsNaN(fs.NotdefAdvanceEm) ? double.NaN : fs.NotdefAdvanceEm * EmSize;

            var rec = new Dictionary<string, object>
            {
                ["id"] = "A-missing-glyph/" + cp.Tag + "@" + fs.Id,
                ["group"] = "A-missing-glyph",
                ["codePoint"] = cp.Tag,
                ["char"] = text,
                ["codePointName"] = cp.Name,
                ["codePointNote"] = cp.Note,
                ["textUtf16Length"] = text.Length,
                ["fontSettingId"] = fs.Id,
                ["fontSettingKind"] = fs.Kind,
                ["fontSettingSpec"] = fs.Spec,
                ["fontSettingNote"] = fs.Note,
                ["fontFamilyNameCount"] = fs.FamilyCount,
                ["specifiedFontResolved"] = fs.Gt != null,
                ["specifiedFontResolveError"] = fs.ResolveError,
                ["specifiedFontUri"] = specUri,
                ["specifiedFontFamilyNames"] = FamilyNamesOf(fs.Gt),
                ["specifiedFontCoversCodePoint"] = fs.Gt == null ? (object)null : fs.Covers,
                ["specifiedFontGlyphIndex"] = fs.Covers ? (object)fs.GlyphIndex : null,
                ["specifiedFontGlyphAdvanceEm"] = RN(fs.GlyphAdvanceEm),
                ["specifiedFontGlyphAdvanceDip"] = double.IsNaN(fs.GlyphAdvanceEm) ? null : (object)R(fs.GlyphAdvanceEm * EmSize),
                ["specifiedFontNotdefAdvanceEm"] = RN(fs.NotdefAdvanceEm),
                ["specifiedFontNotdefAdvanceDip"] = RN(notdefDip),
                ["measuredAdvanceDip"] = RN(adv),
                ["measuredLineWidthDip"] = RN(lineW),
                ["hasOverflowed"] = ovf,
                ["measureError"] = err,
                ["advanceEqualsOneEm"] = Math.Abs(adv - EmSize) < 1e-6,
                ["advanceOverEmSize"] = double.IsNaN(adv) ? (object)null : (object)R(adv / EmSize),
                ["advanceEqualsSpecifiedNotdefAdvance"] = !double.IsNaN(adv) && !double.IsNaN(notdefDip) && Math.Abs(adv - notdefDip) < 1e-6,
                ["advanceEqualsSpecifiedOwnGlyphAdvance"] = !double.IsNaN(adv) && !double.IsNaN(fs.GlyphAdvanceEm) &&
                                                            Math.Abs(adv - fs.GlyphAdvanceEm * EmSize) < 1e-6,
                ["observedFontUri"] = observedUri,
                ["observedFontFamilyNames"] = observedFamilies,
                ["observedGlyphIndex"] = observedGlyph,
                ["observedGlyphIsNotdef"] = observedGlyph == 0,
                ["observedRunAdvanceAsReported"] = RN(observedRunAdvance),
                ["observedBidiLevel"] = observedBidi,
                ["fallbackToADifferentFont"] = fallback,
                ["observedFontEqualsSpecifiedFont"] = observedUri != null && specUri != null &&
                                                      string.Equals(observedUri, specUri, StringComparison.OrdinalIgnoreCase),
                ["observedGlyphRuns"] = runs,
            };
            if (human != null)
            {
                human.AppendLine($"== [{rec["id"]}] char='{text}' len={text.Length}");
                human.AppendLine($"   setting: {fs.Id} ({fs.Kind}) spec={fs.Spec}");
                human.AppendLine($"   specified font: resolved={fs.Gt != null} uri={specUri} covers={fs.Covers} glyph={fs.GlyphIndex} " +
                                 $"glyphAdvEm={F(fs.GlyphAdvanceEm)} notdefAdvEm={F(fs.NotdefAdvanceEm)} notdefAdvDip={F(notdefDip)}");
                human.AppendLine($"   measured: advance={F(adv)} lineWidth={F(lineW)} oneEm={rec["advanceEqualsOneEm"]} " +
                                 $"equalsNotdef={rec["advanceEqualsSpecifiedNotdefAdvance"]} equalsOwnGlyph={rec["advanceEqualsSpecifiedOwnGlyphAdvance"]}");
                human.AppendLine($"   observed: font={observedUri} families={observedFamilies} glyph={observedGlyph} " +
                                 $"isNotdef={rec["observedGlyphIsNotdef"]} fallback={fallback} bidi={observedBidi}");
                foreach (var o in runs)
                {
                    var r = (Dictionary<string, object>)o;
                    human.AppendLine($"      glyphRun @{r["textSourceCharacterIndex"]}+{r["textSourceLength"]} font={r["glyphTypefaceFontUri"]} " +
                                     $"glyphs=[{string.Join(",", (List<object>)r["glyphIndices"])}] adv={string.Join(",", (List<object>)r["advanceWidthsAsReported"])} " +
                                     $"emSize={r["fontRenderingEmSize"]} bidi={r["bidiLevel"]}");
                }
            }
            return rec;
        }

        // ============================ item 2 measurement ============================

        private static Dictionary<string, object> MeasureDoc(TextFormatter formatter, Doc doc, FlowDirection flow, double width, StringBuilder human)
        {
            var props = new Props(new Typeface("Arial"), EmSize);
            var para = new Para(props, flow);
            var src = new StringSource(doc.Buffer, props, doc, doc.OpenIndex, doc.CloseIndex);
            var lines = new List<object>();
            var breaks = new List<object>();
            int index = 0; TextLineBreak brk = null; int guard = 0;
            while (index < doc.Buffer.Length && guard++ < 64)
            {
                TextLine line = formatter.FormatLine(src, index, width, para, brk);
                var b = new Dictionary<string, object>();
                try { b["isNull"] = line.GetTextLineBreak() == null; } catch (Exception e) { b["error"] = e.GetType().Name; b["isNull"] = null; }
                b["lineIndex"] = lines.Count;
                breaks.Add(b);
                var per = new List<object>();
                for (int i = 0; i < (int)line.Length; i++)
                {
                    int gi = index + i;
                    if (gi >= doc.Buffer.Length) break;
                    string ch = doc.Buffer[gi].ToString();
                    IList<TextBounds> tb = null;
                    try { tb = line.GetTextBounds(gi, 1); } catch { }
                    per.Add(new Dictionary<string, object>
                    {
                        ["i"] = gi, ["char"] = ch,
                        ["kind"] = gi == doc.OpenIndex ? "OPEN" : gi == doc.CloseIndex ? "CLOSE" : "char",
                        ["rawX"] = tb != null && tb.Count > 0 ? RN(tb[0].Rectangle.X) : null,
                        ["width"] = tb != null && tb.Count > 0 ? RN(tb[0].Rectangle.Width) : null,
                        ["runFlow"] = tb != null && tb.Count > 0 ? tb[0].FlowDirection.ToString() : null,
                    });
                }
                int bidi = -1;
                try { foreach (IndexedGlyphRun igr in line.GetIndexedGlyphRuns()) { bidi = igr.GlyphRun.BidiLevel; break; } } catch { }
                lines.Add(new Dictionary<string, object>
                {
                    ["index"] = lines.Count, ["startChar"] = index, ["endCharExclusive"] = index + (int)line.Length,
                    ["lineText"] = doc.Buffer.Substring(index, Math.Min((int)line.Length, doc.Buffer.Length - index)),
                    ["width"] = RN(line.Width), ["hasOverflowed"] = line.HasOverflowed,
                    ["firstGlyphRunBidiLevel"] = bidi, ["perChar"] = per,
                });
                if (line.Length <= 0) break;
                index += line.Length;
            }

            string id = doc.Group + "/" + doc.Id + "@w" + width.ToString("0", CultureInfo.InvariantCulture) + "@" + doc.EmbMode;
            var rec = new Dictionary<string, object>
            {
                ["id"] = id, ["group"] = doc.Group, ["docId"] = doc.Id, ["note"] = doc.Note,
                ["embeddingMode"] = doc.EmbMode,
                ["paragraphWidthDip"] = width,
                ["modifierHasDirectionalEmbedding"] = doc.EmbMode == "ltr-embed" || doc.EmbMode == "rtl-embed",
                ["modifierFlowDirection"] = doc.EmbMode == "rtl-embed" ? "RightToLeft"
                                          : doc.EmbMode == "ltr-embed" ? "LeftToRight" : "n/a (identity modifier)",
                ["flowDirection"] = flow == FlowDirection.RightToLeft ? "RightToLeft" : "LeftToRight",
                ["visibleText"] = doc.VisibleText, ["bufferWithMarkers"] = Esc(doc.Buffer),
                ["lineCount"] = lines.Count, ["lineBreakIsNull"] = breaks, ["lines"] = lines,
            };
            if (human != null)
            {
                human.AppendLine($"== [{id}] visible=\"{Esc(doc.VisibleText)}\" mode={doc.EmbMode}");
                foreach (var o in lines)
                {
                    var L = (Dictionary<string, object>)o;
                    human.AppendLine($"   line {L["index"]}: [{L["startChar"]},{L["endCharExclusive"]}) text=\"{Esc((string)L["lineText"])}\" " +
                                     $"w={F((double)L["width"])} bidi={L["firstGlyphRunBidiLevel"]} breakIsNull=" +
                                     ((Dictionary<string, object>)breaks[(int)L["index"]])["isNull"] + "  " +
                                     string.Join(" ", ((List<object>)L["perChar"]).ConvertAll(x =>
                                     {
                                         var p = (Dictionary<string, object>)x;
                                         return p["kind"] + "@" + (p["rawX"] == null ? "n/a" : F((double)p["rawX"]));
                                     })));
                }
            }
            return rec;
        }

        // ============================ helpers ============================

        private static string FirstName(FontFamily f)
        {
            foreach (var kv in f.FamilyNames) return kv.Value;
            return null;
        }

        private static string FamilyNamesOf(GlyphTypeface gt)
        {
            if (gt == null) return null;
            try { foreach (var kv in gt.FamilyNames) return kv.Value; } catch { }
            return null;
        }

        private static List<object> ToList(IList<ushort> l)
        {
            var r = new List<object>();
            if (l != null) foreach (ushort v in l) r.Add((int)v);
            return r;
        }
        private static List<object> ToDoubleList(IList<double> l)
        {
            var r = new List<object>();
            if (l != null) foreach (double v in l) r.Add(RN(v));
            return r;
        }
        private static char[] ToCharArray(IList<char> l)
        {
            var r = new List<char>();
            if (l != null) foreach (char c in l) r.Add(c);
            return r.ToArray();
        }
        private static string Short(object uri)
        {
            string s = uri as string;
            if (s == null) return "n/a";
            int i = s.LastIndexOf('/');
            return i >= 0 ? s.Substring(i + 1) : s;
        }
        private static string Esc(string s) => s == null ? "" : s.Replace("\t", "\\t").Replace("\n", "\\n")
            .Replace(Model.OpenMarker.ToString(), "<OPEN>").Replace(Model.CloseMarker.ToString(), "<CLOSE>");
        private static double R(double v) => double.IsNaN(v) ? v : Math.Round(v, 6, MidpointRounding.AwayFromZero);
        /// <summary>JSON-safe number: NaN / +-Infinity become null (System.Text.Json cannot write them).</summary>
        private static object RN(double v) =>
            (double.IsNaN(v) || double.IsInfinity(v)) ? null : (object)Math.Round(v, 6, MidpointRounding.AwayFromZero);
        private static string F(object v)
        {
            if (v == null) return "n/a";
            try
            {
                double d = Convert.ToDouble(v, CultureInfo.InvariantCulture);
                return (double.IsNaN(d) || double.IsInfinity(d)) ? "n/a" : d.ToString("0.######", CultureInfo.InvariantCulture);
            }
            catch { return "n/a"; }
        }
    }

    // ============================ text model ============================

    internal sealed class StringSource : TextSource
    {
        private readonly string _text;
        private readonly TextRunProperties _props;
        private readonly Doc _doc;
        private readonly int _openIndex, _closeIndex;

        public StringSource(string text, TextRunProperties props, Doc doc, int openIndex, int closeIndex)
        { _text = text; _props = props; _doc = doc; _openIndex = openIndex; _closeIndex = closeIndex; }

        public override TextRun GetTextRun(int index)
        {
            if (index >= _text.Length) return new TextEndOfParagraph(1);
            if (index == _openIndex) return new Modifier(1, _doc, _props);
            if (index == _closeIndex) return new TextEndOfSegment(1);
            int next = _text.Length;
            if (_openIndex > index) next = Math.Min(next, _openIndex);
            if (_closeIndex > index) next = Math.Min(next, _closeIndex);
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

    internal sealed class Modifier : TextModifier
    {
        private readonly Doc _doc;
        private readonly TextRunProperties _props;
        public Modifier(int length, Doc doc, TextRunProperties props) { Length = length; _doc = doc; _props = props; }
        public override int Length { get; }
        public override TextRunProperties Properties => null;
        public override bool HasDirectionalEmbedding => _doc != null && (_doc.EmbMode == "ltr-embed" || _doc.EmbMode == "rtl-embed");
        public override FlowDirection FlowDirection =>
            _doc != null && _doc.EmbMode == "rtl-embed" ? FlowDirection.RightToLeft : FlowDirection.LeftToRight;
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

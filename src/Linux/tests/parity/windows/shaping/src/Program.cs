using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace ShapingOracle
{
    /// <summary>
    /// U1 track D: DirectWrite shaping ground truth for the WPF-on-Linux parity work.
    ///
    /// API sequence per (font, size, text):
    ///   DWriteCreateFactory(SHARED, IID_IDWriteFactory)
    ///   IDWriteFactory::CreateFontFileReference(path)      -- our own TTF, never a system font
    ///   IDWriteFactory::CreateFontFace(TRUETYPE, 1, {file}, 0, NONE)
    ///   IDWriteFontFace::GetMetrics / GetGlyphCount
    ///   IDWriteFactory::CreateTextAnalyzer
    ///   IDWriteTextAnalyzer::GetGlyphs          (shaping / GSUB)
    ///   IDWriteTextAnalyzer::GetGlyphPlacements (positioning / GPOS, i.e. kerning)
    /// </summary>
    public static class Program
    {
        private static readonly double[] Sizes = { 24.0, 11.0 };

        private static readonly ValueTuple<string, string, string>[] Corpus =
        {
            ValueTuple.Create("ascii-basic",  "Hello WPF on Linux",        "plain ASCII with spaces (the string used in the existing width measurements)"),
            ValueTuple.Create("kerning",      "AV Ta To r. P.",            "classic kerning pairs: AV, Ta, To, r., P."),
            ValueTuple.Create("kerning-wide", "AVATAR To Yo Wa LT",        "more kern pairs incl. Yo/Wa/LT"),
            ValueTuple.Create("ligatures",    "ffi fi fl office affluent", "standard ligatures ffi/fi/fl, twice mid-word"),
            ValueTuple.Create("mixed-cjk",    "WPF 在 Linux 上渲染文本",    "Latin + CJK + spaces (script boundary)"),
            ValueTuple.Create("punct-digits", "Test, 123.45; (a-b) [c]!",  "punctuation, digits, brackets, hyphen"),
            ValueTuple.Create("pangram",      "The quick brown fox jumps over the lazy dog", "general Latin coverage"),
        };

        private static readonly string[] FontFiles =
        {
            "NotoSans-Regular.ttf",
            "NotoSans-Bold.ttf",
            "NotoSans-Italic.ttf",
            "NotoSans-BoldItalic.ttf",
        };

        public static int Main(string[] args)
        {
            string fontDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\fonts";
            string outDir = args.Length > 1 ? args[1] : @"C:\u1-shaping\out";
            Directory.CreateDirectory(outDir);

            var dw = new DWrite();
            Console.WriteLine("factory=0x" + dw.Factory.ToString("x") + " analyzer=0x" + dw.Analyzer.ToString("x"));


            var cases = new List<object>();
            var human = new StringBuilder();
            human.AppendLine("DirectWrite shaping oracle - human readable dump");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine();

            foreach (string fontFile in FontFiles)
            {
                string path = Path.Combine(fontDir, fontFile);
                if (!File.Exists(path)) { Console.Error.WriteLine("missing font: " + path); continue; }

                string sha = Sha256(path);
                IntPtr file = dw.CreateFontFileReference(path);
                IntPtr face = dw.CreateFontFace(file);

                DWRITE_FONT_METRICS fm;
                int glyphCount, faceType;
                try
                {
                    fm = DWrite.FaceMetrics(face);
                    glyphCount = DWrite.GlyphCount(face);
                    faceType = DWrite.FaceType(face);
                }
                catch (Exception ex)
                {
                    Console.Error.WriteLine("face setup failed for " + fontFile + ": " + ex.Message);
                    continue;
                }

                human.AppendLine("==================================================================");
                human.AppendLine("font file : " + fontFile);
                human.AppendLine("sha256    : " + sha);
                human.AppendLine("faceType  : " + faceType + " (1=TrueType)   glyphs in font: " + glyphCount);
                human.AppendLine("upem=" + fm.designUnitsPerEm + " ascent=" + fm.ascent + " descent=" + fm.descent +
                                 " lineGap=" + fm.lineGap + " capHeight=" + fm.capHeight + " xHeight=" + fm.xHeight +
                                 " underline=(" + fm.underlinePosition + "," + fm.underlineThickness + ")" +
                                 " strike=(" + fm.strikethroughPosition + "," + fm.strikethroughThickness + ")");

                foreach (double size in Sizes)
                {
                    string sizeTag = size.ToString("0.##", CultureInfo.InvariantCulture);
                    human.AppendLine();
                    human.AppendLine("--- emSize " + sizeTag + " DIP -------------------------------------------------");

                    for (int ci = 0; ci < Corpus.Length; ci++)
                    {
                        string id = Corpus[ci].Item1, text = Corpus[ci].Item2, note = Corpus[ci].Item3;
                        Dictionary<string, object> d;
                        try { d = ShapeCase(dw, face, fm, fontFile, sha, size, id, text, note); }
                        catch (Exception ex)
                        {
                            Console.Error.WriteLine("case " + id + " @" + sizeTag + " failed: " + ex.Message);
                            continue;
                        }
                        cases.Add(d);

                        human.AppendLine("[" + id + "] \"" + text + "\"");
                        human.AppendLine("    glyphs   : " + Join(d["glyphIds"]));
                        human.AppendLine("    advances : " + Join(d["advancesDip"]));
                        human.AppendLine("    text->glyph : " + Join(d["textToGlyphMap"]));
                        human.AppendLine("    total    : " + Fmt((double)d["totalAdvanceDip"]) + " DIP   (" +
                                         Fmt((double)d["totalAdvanceDesignUnits"]) + " design units)");
                        human.AppendLine("    line     : height " + Fmt((double)d["lineHeightDip"]) + " DIP  baseline " +
                                         Fmt((double)d["ascentDip"]) + "  descent " + Fmt((double)d["descentDip"]) +
                                         "  lineGap " + Fmt((double)d["lineGapDip"]));
                        human.AppendLine("    note     : " + d["note"]);
                    }
                }
            }

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-shaping-oracle/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["engine"] = "DirectWrite, IDWriteTextAnalyzer::GetGlyphs + GetGlyphPlacements (shaper behind WPF)",
                ["apiSequence"] = new[]
                {
                    "DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, IID_IDWriteFactory)",
                    "IDWriteFactory::CreateFontFileReference(<path to our own ttf>)",
                    "IDWriteFactory::CreateFontFace(DWRITE_FONT_FACE_TYPE_TRUETYPE, 1, {file}, 0, DWRITE_FONT_SIMULATIONS_NONE)",
                    "IDWriteFontFace::GetMetrics / GetGlyphCount",
                    "IDWriteFactory::CreateTextAnalyzer",
                    "IDWriteTextAnalyzer::GetGlyphs(text, len, face, isSideways=0, isRTL=0, scriptAnalysis={0,DEFAULT}, \"en-us\", typography=NULL, features=NULL, featureRanges=0, maxGlyphCount, clusterMap, textProps, glyphIndices, glyphProps, &actualGlyphCount)",
                    "IDWriteTextAnalyzer::GetGlyphPlacements(text, clusterMap, textProps, len, glyphIndices, glyphProps, glyphCount, face, 0, 0, {0,DEFAULT}, \"en-us\", NULL, NULL, NULL, 0, glyphAdvances, glyphOffsets)",
                },
                ["dwriteDllVersion"] = FileVersion(Path.Combine(Environment.SystemDirectory, "dwrite.dll")),
                ["os"] = RuntimeInformation.OSDescription,
                ["clr"] = RuntimeInformation.FrameworkDescription,
                ["emSizesDip"] = Sizes,
                ["scriptAnalysis"] = "DWRITE_SCRIPT_ANALYSIS { script = 0, shapes = DWRITE_SCRIPT_SHAPES_DEFAULT } for every case; locale \"en-us\"; " +
                                     "no DWRITE_TYPOGRAPHIC_FEATURES array, so the font's default features apply (kern/liga/clig on, matching HarfBuzz defaults).",
                ["units"] = "advancesDip/offsetsDip are DIPs (= px at 96 dpi) as returned by GetGlyphPlacements at the requested emSize. " +
                            "totalAdvanceDesignUnits is the same total scaled by upem/emSize, i.e. the HarfBuzz-comparable number.",
                ["lineHeightNote"] = "lineHeightDip is DERIVED from IDWriteFontFace::GetMetrics as (ascent+descent+lineGap)*emSize/upem. " +
                                     "It is not read from an IDWriteTextLayout, because a layout needs an IDWriteTextFormat, which needs the font to be " +
                                     "resolvable through a font collection - and the font is deliberately NOT installed (see PROVENANCE.md).",
                ["cases"] = cases,
            };

            string json = JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(Path.Combine(outDir, "dwrite-shaping-oracle.json"), json, new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "dwrite-shaping-oracle.txt"), human.ToString(), new UTF8Encoding(false));
            Console.WriteLine("cases: " + cases.Count);
            return 0;
        }


        /// <summary>
        /// DWRITE_SCRIPT_ANALYSIS.script is an index into DirectWrite's private script table.
        /// GetGlyphs rejects out-of-range values with E_INVALIDARG, so the valid ids can be
        /// discovered safely by enumeration; a valid id is then confirmed by checking that the
        /// text shapes the way the font's default features say it should.
        /// </summary>

        /// <summary>
        /// One factory slot per process (a wrong slot corrupts the stack and kills the process,
        /// so they cannot be probed in a loop). Reports the HRESULT and whether the returned
        /// object answers QueryInterface for IID_IDWriteTextAnalyzer.
        /// </summary>
        private static unsafe Dictionary<string, object> ShapeCase(DWrite dw, IntPtr face, DWRITE_FONT_METRICS fm,
            string fontFile, string sha, double size, string id, string text, string note)
        {
            int len = text.Length;
            uint maxGlyphs = (uint)(len * 4 + 16);
            var clusterMap = new ushort[maxGlyphs];
            var textProps = new DWRITE_SHAPING_TEXT_PROPERTIES[maxGlyphs];
            var glyphIndices = new ushort[maxGlyphs];
            var glyphProps = new DWRITE_SHAPING_GLYPH_PROPERTIES[maxGlyphs];
            var advances = new float[maxGlyphs];
            var offsets = new DWRITE_GLYPH_OFFSET[maxGlyphs];

            DWRITE_SCRIPT_ANALYSIS sa;
            sa.script = 0;
            sa.shapes = 0;

            uint actual;
            fixed (ushort* pCluster = clusterMap)
            fixed (DWRITE_SHAPING_TEXT_PROPERTIES* pTextProps = textProps)
            fixed (ushort* pGlyphs = glyphIndices)
            fixed (DWRITE_SHAPING_GLYPH_PROPERTIES* pGlyphProps = glyphProps)
            fixed (float* pAdv = advances)
            fixed (DWRITE_GLYPH_OFFSET* pOff = offsets)
            {
                dw.GetGlyphs(face, text, &sa, pCluster, pTextProps, pGlyphs, pGlyphProps, maxGlyphs, out actual);
                if (actual == 0) throw new Exception("GetGlyphs produced 0 glyphs for " + id);
                dw.GetGlyphPlacements(face, text, (float)size, &sa, pCluster, pTextProps, pGlyphs, pGlyphProps, actual, pAdv, pOff);
            }

            int n = (int)actual;
            var glyphIds = new List<object>();
            var advList = new List<object>();
            var offList = new List<object>();
            double total = 0;
            for (int i = 0; i < n; i++)
            {
                glyphIds.Add((int)glyphIndices[i]);
                advList.Add(R6(advances[i]));
                offList.Add(new Dictionary<string, object> { ["x"] = R6(offsets[i].advanceOffset), ["y"] = R6(offsets[i].ascenderOffset) });
                total += advances[i];
            }

            // DWrite's GetGlyphs clusterMap is indexed by TEXT position and yields the GLYPH index
            // (it is documented as _Out_writes_(textLength)).  HarfBuzz reports the opposite
            // direction, so both are emitted: textToGlyphMap verbatim and glyphToClusterMap inverted.
            var textToGlyph = new List<object>();
            for (int i = 0; i < len; i++) textToGlyph.Add((int)clusterMap[i]);
            var glyphToCluster = new List<object>();
            for (int g = 0; g < n; g++)
            {
                int first = -1;
                for (int i = 0; i < len; i++) if (clusterMap[i] == g) { first = i; break; }
                glyphToCluster.Add(first);
            }

            int notdef = 0;
            for (int i = 0; i < n; i++) if (glyphIndices[i] == 0) notdef++;

            // a glyph that more than one character maps to is a ligature / composition
            var perGlyph = new int[n];
            for (int i = 0; i < len; i++) { int g = clusterMap[i]; if (g < n) perGlyph[g]++; }
            int ligatureGlyphs = 0, mergedChars = 0;
            for (int g = 0; g < n; g++) if (perGlyph[g] > 1) { ligatureGlyphs++; mergedChars += perGlyph[g]; }

            string noteOut = note + (ligatureGlyphs > 0
                    ? " | " + ligatureGlyphs + " glyph(s) cover " + mergedChars + " characters => ligature/composition applied"
                    : " | no ligature: every glyph maps to exactly one character")
                + (notdef > 0 ? " | " + notdef + " glyph(s) are .notdef (0): the font has no cmap entry for those characters" : "");

            double upem = fm.designUnitsPerEm;
            double scale = size / upem;
            return new Dictionary<string, object>
            {
                ["id"] = id,
                ["font"] = fontFile,
                ["fontSha256"] = sha,
                ["emSizeDip"] = size,
                ["text"] = text,
                ["utf16Length"] = len,
                ["glyphCount"] = n,
                ["notdefGlyphs"] = notdef,
                ["glyphIds"] = glyphIds,
                ["advancesDip"] = advList,
                ["offsetsDip"] = offList,
                ["textToGlyphMap"] = textToGlyph,
                ["glyphToClusterMap"] = glyphToCluster,
                ["totalAdvanceDip"] = R6(total),
                ["totalAdvanceDesignUnits"] = R6(total / scale),
                ["upem"] = (int)upem,
                ["ascentDip"] = R6(fm.ascent * scale),
                ["descentDip"] = R6(fm.descent * scale),
                ["lineGapDip"] = R6(fm.lineGap * scale),
                ["lineHeightDip"] = R6((fm.ascent + fm.descent + fm.lineGap) * scale),
                ["note"] = noteOut,
            };
        }

        private static double R6(double v) => Math.Round(v, 6, MidpointRounding.AwayFromZero);

        private static string Fmt(double v) => v.ToString("0.######", CultureInfo.InvariantCulture);

        private static string Join(object o)
        {
            var list = (List<object>)o;
            var sb = new StringBuilder();
            foreach (var x in list)
            {
                if (sb.Length > 0) sb.Append(' ');
                sb.Append(x is double d ? Fmt(d) : x.ToString());
            }
            return sb.ToString();
        }

        private static string Sha256(string path)
        {
            using var sha = SHA256.Create();
            using var fs = File.OpenRead(path);
            byte[] h = sha.ComputeHash(fs);
            var sb = new StringBuilder(h.Length * 2);
            foreach (byte b in h) sb.Append(b.ToString("x2", CultureInfo.InvariantCulture));
            return sb.ToString();
        }

        private static string FileVersion(string path)
        {
            try { return System.Diagnostics.FileVersionInfo.GetVersionInfo(path).FileVersion; }
            catch (Exception e) { return "ERR " + e.Message; }
        }
    }
}

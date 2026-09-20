using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace CjkOracle
{
    /// <summary>
    /// U1 track D task 2: CJK shaping ground truth.
    ///
    /// Same shape as dwrite-shaping-oracle (same fields, same layout of the output), but the font is
    /// NotoSansCJK-Regular.ttc - a font *collection*, so GetFaceType/CreateFontFace take a face index:
    ///   0 = Noto Sans CJK JP, 1 = KR, 2 = SC, 3 = TC, 4 = HK
    /// That also lets the same code points be shaped through different faces, which measures the
    /// `locl` (localized form) feature - one of the features this project does NOT implement.
    /// </summary>
    public static class Program
    {
        private const string TtcFile = "NotoSansCJK-Regular.ttc";
        private const int FACE_JP = 0, FACE_KR = 1, FACE_SC = 2, FACE_TC = 3, FACE_HK = 4;

        private static readonly double[] Sizes = { 24.0, 11.0 };

        // (id, text, note)
        private static readonly (string Id, string Text, string Note)[] Corpus =
        {
            ("han-simplified", "汉字排版测试：这是一段需要换行的中文文本。", "simplified Chinese Han + fullwidth colon/period"),
            ("han-mixed-script", "日本語の漢字とかな、한글 조판, 简体汉字。", "Han + kana + hangul in one run (real script boundaries)"),
            ("kana", "ひらがなとカタカナのテストです。", "hiragana + katakana + ideographic full stop"),
            ("hangul", "한글 조판 테스트입니다.", "hangul syllables + space"),
            ("fullwidth-punct", "全角标点：，。！？；：「」（）【】", "fullwidth punctuation only"),
            ("mixed-latin-cjk", "WPF 在 Linux 上渲染文本 with Latin 123", "Latin + CJK + digits (the string that was .notdef before)"),
            ("latin-only-in-cjk-font", "Hello WPF", "Latin served by the CJK font itself (no fallback)"),
        };

        // same code points through different faces -> isolates `locl`
        private static readonly (string Id, string Text, string Note)[] LoclCorpus =
        {
            ("locl-han-forms", "直画骨角写门今令", "characters whose SC/TC/JP forms commonly differ"),
            ("locl-han-2", "汉字字体说明", "plain Han, expect identical glyphs across faces"),
        };

        public static int Main(string[] args)
        {
            string fontDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\fonts";
            string outDir = args.Length > 1 ? args[1] : @"C:\u1-shaping\out-cjk";
            Directory.CreateDirectory(outDir);

            string ttcPath = Path.Combine(fontDir, TtcFile);
            if (!File.Exists(ttcPath)) { Console.Error.WriteLine("missing " + ttcPath); return 2; }
            string sha = Sha256(ttcPath);

            var dw = new DWrite();
            IntPtr file = dw.CreateFontFileReference(ttcPath);
            var cases = new List<object>();
            var human = new StringBuilder();
            human.AppendLine("DirectWrite CJK shaping oracle - human readable dump");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine("font: " + TtcFile + "  sha256 " + sha);
            human.AppendLine();

            foreach (int faceIndex in new[] { FACE_SC })
            {
                IntPtr face = dw.CreateFontFace(file, (uint)faceIndex, collection: true);
                DWRITE_FONT_METRICS fm = DWrite.FaceMetrics(face);
                int glyphCount = DWrite.GlyphCount(face);
                human.AppendLine($"=== face {faceIndex} ({FaceName(faceIndex)})  glyphs={glyphCount} upem={fm.designUnitsPerEm} " +
                                 $"ascent={fm.ascent} descent={fm.descent} lineGap={fm.lineGap}");
                foreach (double size in Sizes)
                {
                    foreach (var c in Corpus)
                        cases.Add(ShapeOne(dw, face, fm, ttcPath, sha, faceIndex, size, c.Id, c.Text, c.Note, cases, human));
                }
            }

            // locl: identical text, different faces
            var loclFaces = new[] { FACE_JP, FACE_SC, FACE_TC };
            foreach (var c in LoclCorpus)
            {
                var perFace = new Dictionary<string, object>();
                var glyphsPerFace = new List<int[]>();
                foreach (int fi in loclFaces)
                {
                    IntPtr f = dw.CreateFontFace(file, (uint)fi, collection: true);
                    DWRITE_FONT_METRICS fmx = DWrite.FaceMetrics(f);
                    var d = ShapeCase(dw, f, fmx, ttcPath, sha, fi, 24.0, c.Id + "-" + FaceName(fi), c.Text, c.Note);
                    var ids = new List<int>();
                    foreach (var g in (List<object>)d["glyphIds"]) ids.Add((int)g);
                    glyphsPerFace.Add(ids.ToArray());
                    perFace[FaceName(fi)] = d;
                    cases.Add(d);
                }
                bool allSame = true;
                for (int i = 1; i < glyphsPerFace.Count; i++)
                    if (!SameSeq(glyphsPerFace[0], glyphsPerFace[i])) allSame = false;
                human.AppendLine($"[{c.Id}] \"{c.Text}\"  locl: glyph sequences identical across JP/SC/TC = {allSame}");
                for (int i = 0; i < loclFaces.Length; i++)
                    human.AppendLine($"    {FaceName(loclFaces[i])}: {string.Join(" ", glyphsPerFace[i])}");
            }

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-shaping-oracle/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["engine"] = "DirectWrite, IDWriteTextAnalyzer::GetGlyphs + GetGlyphPlacements (same as dwrite-shaping-oracle.json)",
                ["apiSequence"] = new[]
                {
                    "DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, IID_IDWriteFactory)",
                    "IDWriteFactory::CreateFontFileReference(<NotoSansCJK-Regular.ttc>)",
                    "IDWriteFactory::CreateFontFace(DWRITE_FONT_FACE_TYPE_TRUETYPE, 1, {file}, faceIndex, NONE)   <-- faceIndex selects JP/KR/SC/TC/HK",
                    "IDWriteFontFace::GetMetrics / GetGlyphCount",
                    "IDWriteFactory::CreateTextAnalyzer",
                    "IDWriteTextAnalyzer::GetGlyphs / GetGlyphPlacements  (script=0, locale=\"en-us\", no features)",
                },
                ["font"] = TtcFile,
                ["fontSha256"] = sha,
                ["fontIsCollection"] = true,
                ["faceIndexMeaning"] = "0=Noto Sans CJK JP, 1=KR, 2=SC, 3=TC, 4=HK",
                ["dwiteDllVersion"] = FileVersion(Path.Combine(Environment.SystemDirectory, "dwrite.dll")),
                ["os"] = RuntimeInformation.OSDescription,
                ["clr"] = RuntimeInformation.FrameworkDescription,
                ["emSizesDip"] = Sizes,
                ["cases"] = cases,
            };
            File.WriteAllText(Path.Combine(outDir, "dwrite-cjk-shaping-oracle.json"),
                JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "dwrite-cjk-shaping-oracle.txt"), human.ToString(), new UTF8Encoding(false));
            Console.WriteLine("cases: " + cases.Count);
            return 0;
        }

        private static bool SameSeq(int[] a, int[] b)
        {
            if (a.Length != b.Length) return false;
            for (int i = 0; i < a.Length; i++) if (a[i] != b[i]) return false;
            return true;
        }

        private static string FaceName(int i) => i switch
        {
            0 => "JP", 1 => "KR", 2 => "SC", 3 => "TC", 4 => "HK", _ => "face" + i,
        };

        private static object ShapeOne(DWrite dw, IntPtr face, DWRITE_FONT_METRICS fm, string path, string sha,
            int faceIndex, double size, string id, string text, string note, List<object> cases, StringBuilder human)
        {
            var d = ShapeCase(dw, face, fm, path, sha, faceIndex, size, id, text, note);
            cases.Add(d);
            human.AppendLine($"[{id}] \"{text}\"  ({size:0.##} DIP, face {FaceName(faceIndex)})");
            human.AppendLine("    glyphs   : " + Join(d["glyphIds"]));
            human.AppendLine("    advances : " + Join(d["advancesDip"]));
            human.AppendLine("    total    : " + F((double)d["totalAdvanceDip"]) + " DIP");
            human.AppendLine("    note     : " + d["note"]);
            return d;
        }

        private static unsafe Dictionary<string, object> ShapeCase(DWrite dw, IntPtr face, DWRITE_FONT_METRICS fm,
            string path, string sha, int faceIndex, double size, string id, string text, string note)
        {
            int len = text.Length;
            uint maxGlyphs = (uint)(len * 4 + 16);
            var clusterMap = new ushort[maxGlyphs];
            var textProps = new DWRITE_SHAPING_TEXT_PROPERTIES[maxGlyphs];
            var glyphIndices = new ushort[maxGlyphs];
            var glyphProps = new DWRITE_SHAPING_GLYPH_PROPERTIES[maxGlyphs];
            var advances = new float[maxGlyphs];
            var offsets = new DWRITE_GLYPH_OFFSET[maxGlyphs];

            DWRITE_SCRIPT_ANALYSIS sa; sa.script = 0; sa.shapes = 0;
            uint actual;
            fixed (ushort* pc = clusterMap)
            fixed (DWRITE_SHAPING_TEXT_PROPERTIES* pt = textProps)
            fixed (ushort* pg = glyphIndices)
            fixed (DWRITE_SHAPING_GLYPH_PROPERTIES* pp = glyphProps)
            fixed (float* pa = advances)
            fixed (DWRITE_GLYPH_OFFSET* po = offsets)
            {
                dw.GetGlyphs(face, text, &sa, pc, pt, pg, pp, maxGlyphs, out actual);
                if (actual == 0) throw new Exception("GetGlyphs produced 0 glyphs for " + id);
                dw.GetGlyphPlacements(face, text, (float)size, &sa, pc, pt, pg, pp, actual, pa, po);
            }

            int n = (int)actual;
            var glyphIds = new List<object>();
            var advList = new List<object>();
            var offList = new List<object>();
            var t2g = new List<object>();
            double total = 0;
            for (int i = 0; i < n; i++)
            {
                glyphIds.Add((int)glyphIndices[i]);
                advList.Add(R6(advances[i]));
                offList.Add(new Dictionary<string, object> { ["x"] = R6(offsets[i].advanceOffset), ["y"] = R6(offsets[i].ascenderOffset) });
                total += advances[i];
            }
            for (int i = 0; i < len; i++) t2g.Add((int)clusterMap[i]);
            var g2c = new List<object>();
            for (int g = 0; g < n; g++)
            {
                int first = -1;
                for (int i = 0; i < len; i++) if (clusterMap[i] == g) { first = i; break; }
                g2c.Add(first);
            }
            int notdef = 0;
            for (int i = 0; i < n; i++) if (glyphIndices[i] == 0) notdef++;
            var perGlyph = new int[n];
            for (int i = 0; i < len; i++) { int g = clusterMap[i]; if (g < n) perGlyph[g]++; }
            int ligGlyphs = 0, merged = 0;
            for (int g = 0; g < n; g++) if (perGlyph[g] > 1) { ligGlyphs++; merged += perGlyph[g]; }

            double upem = fm.designUnitsPerEm, scale = size / upem;
            return new Dictionary<string, object>
            {
                ["id"] = id,
                ["font"] = Path.GetFileName(path),
                ["fontSha256"] = sha,
                ["ttcFaceIndex"] = faceIndex,
                ["ttcFace"] = FaceName(faceIndex),
                ["emSizeDip"] = size,
                ["text"] = text,
                ["utf16Length"] = len,
                ["glyphCount"] = n,
                ["notdefGlyphs"] = notdef,
                ["glyphIds"] = glyphIds,
                ["advancesDip"] = advList,
                ["offsetsDip"] = offList,
                ["textToGlyphMap"] = t2g,
                ["glyphToClusterMap"] = g2c,
                ["totalAdvanceDip"] = R6(total),
                ["totalAdvanceDesignUnits"] = R6(total / scale),
                ["upem"] = (int)upem,
                ["ascentDip"] = R6(fm.ascent * scale),
                ["descentDip"] = R6(fm.descent * scale),
                ["lineGapDip"] = R6(fm.lineGap * scale),
                ["lineHeightDip"] = R6((fm.ascent + fm.descent + fm.lineGap) * scale),
                ["note"] = note + (ligGlyphs > 0 ? " | " + ligGlyphs + " glyph(s) cover " + merged + " characters" : "")
                          + (notdef > 0 ? " | " + notdef + " .notdef glyph(s)" : ""),
            };
        }

        private static double R6(double v) => Math.Round(v, 6, MidpointRounding.AwayFromZero);
        private static string F(double v) => v.ToString("0.######", CultureInfo.InvariantCulture);

        private static string Join(object o)
        {
            var list = (List<object>)o;
            var sb = new StringBuilder();
            foreach (var x in list) { if (sb.Length > 0) sb.Append(' '); sb.Append(x is double d ? F(d) : x.ToString()); }
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

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace LayoutOracle
{
    /// <summary>
    /// U1 track D task 1: layout-level ground truth (line breaking + line metrics) from DirectWrite.
    ///
    /// The fonts are NOT installed.  A minimal IDWriteFontCollectionLoader (+ IDWriteFontFileLoader,
    /// IDWriteFontFileEnumerator, IDWriteFontFileStream implemented in Com.cs) serves the TTFs out of
    /// pinned managed byte arrays, which lets IDWriteTextFormat / IDWriteTextLayout be used on them.
    /// </summary>
    public static class Program
    {
        private static readonly string[] LatinFonts =
        {
            "NotoSans-Regular.ttf", "NotoSans-Bold.ttf", "NotoSans-Italic.ttf", "NotoSans-BoldItalic.ttf",
        };

        private const int WEIGHT_NORMAL = 400, WEIGHT_BOLD = 700;
        private const int STYLE_NORMAL = 0, STYLE_ITALIC = 2;
        private const int STRETCH_NORMAL = 5;
        private const int WORD_WRAPPING_WRAP = 0;

        // (id, text, containerWidthDip, weight, style, note)
        private static readonly (string Id, string Text, float Width, int Weight, int Style, string Note)[] Corpus =
        {
            ("en-long",    "The quick brown fox jumps over the lazy dog and keeps on running until the line has to wrap somewhere.", 200f, WEIGHT_NORMAL, STYLE_NORMAL, "single long English sentence, must wrap"),
            ("en-words",   "one two three four five six seven eight nine ten eleven twelve thirteen", 150f, WEIGHT_NORMAL, STYLE_NORMAL, "many short words"),
            ("en-hyphen",  "well-known state-of-the-art self-contained hyphen-separated compound words", 160f, WEIGHT_NORMAL, STYLE_NORMAL, "hyphenated compounds: break opportunities differ from plain spaces"),
            ("en-narrow",  "The quick brown fox jumps over the lazy dog", 90f, WEIGHT_NORMAL, STYLE_NORMAL, "very narrow container -> many lines"),
            ("en-newline", "first line\nsecond line\n\nfourth line after an empty one", 300f, WEIGHT_NORMAL, STYLE_NORMAL, "explicit newlines incl. an empty line"),
            ("en-oneword", "supercalifragilisticexpialidociousandthensomemorelettershere", 100f, WEIGHT_NORMAL, STYLE_NORMAL, "one word longer than the container -> emergency/character break"),
            ("mixed",      "WPF on Linux renders text 中英混排换行测试 with Latin and CJK together", 200f, WEIGHT_NORMAL, STYLE_NORMAL, "Latin + CJK mixed; NOTE: NotoSans-*.ttf has no CJK glyphs, so CJK advances are .notdef (see cjkCoverage)"),
            ("cjk-only",   "中文排版测试：这是一段需要换行的中文文本，标点符号也要正确处理。", 180f, WEIGHT_NORMAL, STYLE_NORMAL, "CJK only; same .notdef caveat as mixed"),
            ("bold-wrap",  "The quick brown fox jumps over the lazy dog and keeps on running", 180f, WEIGHT_BOLD, STYLE_NORMAL, "bold face, wrapping"),
            ("italic-wrap","The quick brown fox jumps over the lazy dog and keeps on running", 180f, WEIGHT_NORMAL, STYLE_ITALIC, "italic face, wrapping"),
        };

        public static int Main(string[] args)
        {
            string fontDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\fonts";
            string outDir = args.Length > 1 ? args[1] : @"C:\u1-shaping\out-layout";
            Directory.CreateDirectory(outDir);

            Dw.Init();

            // 1. register the font bytes (pinned for the process lifetime)
            var sha = new List<string>();
            foreach (string f in LatinFonts)
            {
                string p = Path.Combine(fontDir, f);
                if (!File.Exists(p)) { Console.Error.WriteLine("missing " + p); return 2; }
                FontStore.Add(p);
                sha.Add(Sha256(p));
            }

            // 2. one collection holding all four faces of "Noto Sans"
            int collId = CollectionTable.Add(new[] { 0, 1, 2, 3 });
            ServerHandles.CollLoader = CollectionTable.CreateLoaderObject();
            ServerHandles.FileLoader = Com.New(Servers.FileLoaderVtbl, Com.KindFileLoader);
            Dw.RegisterLoaders(ServerHandles.CollLoader, ServerHandles.FileLoader);
            IntPtr coll = Dw.CreateCustomFontCollection(ServerHandles.CollLoader, collId);

            Console.WriteLine($"callbacks: QI={Servers.N_QI} AddRef={Servers.N_AddRef} Release={Servers.N_Release} " +
                              $"CreateEnum={Servers.N_CreateEnum} MoveNext={Servers.N_MoveNext} GetCurrent={Servers.N_GetCurrent} " +
                              $"CreateStream={Servers.N_CreateStream} ReadFrag={Servers.N_ReadFragment} GetSize={Servers.N_GetFileSize} RelFrag={Servers.N_ReleaseFragment}");
            int familyCount = Dw.FontFamilyCount(coll);
            bool found = Dw.FindFamilyName(coll, "Noto Sans", out int familyIndex);
            Console.WriteLine($"collection: {familyCount} families; FindFamilyName(\"Noto Sans\") exists={found} index={familyIndex}");
            if (!found)
            {
                Console.Error.WriteLine("family name not found in the custom collection - aborting rather than guessing");
                Console.Error.WriteLine($"callbacks after query: CreateEnum={Servers.N_CreateEnum} MoveNext={Servers.N_MoveNext} " +
                                        $"GetCurrent={Servers.N_GetCurrent} CreateStream={Servers.N_CreateStream} ReadFrag={Servers.N_ReadFragment} " +
                                        $"GetSize={Servers.N_GetFileSize} RelFrag={Servers.N_ReleaseFragment} QI={Servers.N_QI} Rel={Servers.N_Release}");
                return 3;
            }

            var cases = new List<object>();
            var human = new StringBuilder();
            human.AppendLine("DirectWrite LAYOUT oracle (line breaking + line metrics) - human readable");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine();

            foreach (var c in Corpus)
            {
                IntPtr format;
                try { format = Dw.CreateTextFormat(coll, "Noto Sans", c.Weight, c.Style, STRETCH_NORMAL, 24f, "en-us"); }
                catch (Exception ex) { Console.Error.WriteLine($"format failed for {c.Id}: {ex.Message}"); continue; }
                Dw.SetWordWrapping(format, WORD_WRAPPING_WRAP);

                IntPtr layout;
                try { layout = Dw.CreateTextLayout(c.Text, format, c.Width, 10000f); }
                catch (Exception ex) { Console.Error.WriteLine($"layout failed for {c.Id}: {ex.Message}"); continue; }

                DWRITE_TEXT_METRICS tm = Dw.LayoutMetrics(layout);
                DWRITE_LINE_METRICS[] lm = Dw.LineMetrics(layout);

                var lines = new List<object>();
                int start = 0;
                human.AppendLine($"== [{c.Id}] \"{c.Text.Replace("\n", "\\n")}\"");
                human.AppendLine($"   container {c.Width} DIP, weight {c.Weight}, style {c.Style}");
                human.AppendLine($"   textMetrics: width={F(tm.width)} height={F(tm.height)} lines={tm.lineCount} maxBidi={tm.maxBidiReorderingDepth}");
                for (int i = 0; i < lm.Length; i++)
                {
                    int len = (int)lm[i].length;
                    int textLen = len - (int)lm[i].newlineLength;      // characters belonging to the line itself
                    var runs = Dw.HitTestTextRange(layout, (uint)start, (uint)Math.Max(textLen, 0));
                    float minL = float.MaxValue, maxR = float.MinValue;
                    foreach (var r in runs) { if (r.left < minL) minL = r.left; if (r.left + r.width > maxR) maxR = r.left + r.width; }
                    float advance = runs.Length > 0 ? maxR - minL : 0f;
                    Dw.HitTestTextPosition(layout, (uint)start, 0, out float cx, out float cy, out var hm);
                    lines.Add(new Dictionary<string, object>
                    {
                        ["index"] = i,
                        ["startChar"] = start,
                        ["endCharExclusive"] = start + textLen,
                        ["lengthWithNewline"] = len,
                        ["newlineLength"] = (int)lm[i].newlineLength,
                        ["trailingWhitespaceLength"] = (int)lm[i].trailingWhitespaceLength,
                        ["heightDip"] = R(lm[i].height),
                        ["baselineDip"] = R(lm[i].baseline),
                        ["isTrimmed"] = lm[i].isTrimmed != 0,
                        ["advanceWidthDip"] = R(advance),
                        ["runCount"] = runs.Length,
                        ["caretXDip"] = R(cx),
                        ["caretYDip"] = R(cy),
                        ["lineText"] = SafeSlice(c.Text, start, textLen),
                    });
                    human.AppendLine($"   line {i}: chars [{start},{start + textLen})  len={len} nl={lm[i].newlineLength} " +
                                     $"trailWs={lm[i].trailingWhitespaceLength}  h={F(lm[i].height)} base={F(lm[i].baseline)} " +
                                     $"adv={F(advance)} caret=({F(cx)},{F(cy)})  \"{SafeSlice(c.Text, start, textLen).Replace("\n", "\\n")}\"");
                    start += len;
                }
                if (start != c.Text.Length)
                    human.AppendLine($"   !! line lengths sum to {start}, text length is {c.Text.Length}");

                cases.Add(new Dictionary<string, object>
                {
                    ["id"] = c.Id,
                    ["text"] = c.Text,
                    ["containerWidthDip"] = c.Width,
                    ["fontFamily"] = "Noto Sans",
                    ["fontFilesSha256"] = sha,
                    ["emSizeDip"] = 24.0,
                    ["weight"] = c.Weight,
                    ["style"] = c.Style,
                    ["stretch"] = STRETCH_NORMAL,
                    ["wordWrapping"] = "WRAP",
                    ["note"] = c.Note,
                    ["cjkCoverage"] = !(c.Id == "mixed" || c.Id == "cjk-only"),
                    ["textMetrics"] = new Dictionary<string, object>
                    {
                        ["left"] = R(tm.left), ["top"] = R(tm.top), ["width"] = R(tm.width),
                        ["widthIncludingTrailingWhitespace"] = R(tm.widthIncludingTrailingWhitespace),
                        ["height"] = R(tm.height), ["layoutWidth"] = R(tm.layoutWidth),
                        ["layoutHeight"] = R(tm.layoutHeight),
                        ["maxBidiReorderingDepth"] = (int)tm.maxBidiReorderingDepth,
                        ["lineCount"] = (int)tm.lineCount,
                    },
                    ["lines"] = lines,
                });
            }

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-layout-oracle/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["engine"] = "DirectWrite IDWriteTextLayout::GetMetrics + GetLineMetrics (+ HitTestTextRange/Position)",
                ["dwriteDllVersion"] = FileVersion(Path.Combine(Environment.SystemDirectory, "dwrite.dll")),
                ["os"] = RuntimeInformation.OSDescription,
                ["clr"] = RuntimeInformation.FrameworkDescription,
                ["fontLoading"] = "fonts are NOT installed: a minimal IDWriteFontCollectionLoader + IDWriteFontFileLoader + " +
                                  "IDWriteFontFileEnumerator + IDWriteFontFileStream (implemented in Com.cs, bytes served from pinned " +
                                  "managed arrays) put the TTFs into a private font collection",
                ["familyNameVerified"] = "FindFamilyName(\"Noto Sans\") returned exists=" + (found ? "true" : "false"),
                ["units"] = "all DIP (= px at 96 dpi); containerWidthDip is the layout maxWidth passed to CreateTextLayout",
                ["lineSemantics"] = "one entry per laid-out line; startChar/endCharExclusive are UTF-16 code unit indices into the " +
                                    "original string; lengthWithNewline includes the newline characters, so startChar of the next line " +
                                    "is startChar+lengthWithNewline. advanceWidthDip is measured with HitTestTextRange over the line's own " +
                                    "characters (max right edge - min left edge), caretXDip/caretYDip come from HitTestTextPosition(lineStart,0).",
                ["cases"] = cases,
            };

            File.WriteAllText(Path.Combine(outDir, "dwrite-layout-oracle.json"),
                JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "dwrite-layout-oracle.txt"), human.ToString(), new UTF8Encoding(false));
            Console.WriteLine("cases: " + cases.Count);
            return 0;
        }

        private static string SafeSlice(string s, int start, int len)
        {
            if (start < 0 || start > s.Length || len <= 0) return "";
            if (start + len > s.Length) len = s.Length - start;
            return s.Substring(start, len);
        }

        private static double R(double v) => Math.Round(v, 6, MidpointRounding.AwayFromZero);
        private static string F(double v) => v.ToString("0.######", CultureInfo.InvariantCulture);

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

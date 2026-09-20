// T1d · **R1 覆盖回退探针** —— 用"多 run 的假 TextSource"驱动**真 shim 源**的应用路径
// =====================================================================================
//   dotnet PresentationCore.Tests.dll [--scenario single|two] [--width DIP]
//
// 【它回答的问题（主控派单 R1 的四条验收里，能在无 PC 重建下量的部分）】
//   1. **按码点覆盖回退真的发生了吗**：`id==0`（.notdef）从"整段中文"降到 ~0？出现 `id>=0x1000`？
//   2. **一个字体子段一张 `GlyphRun`**（"一面一 run"）是不是真的：逐 run 打出
//      `(face 文件, 面下标, 令牌, glyphCount, baseline origin, 字符)` 与"本行吐了几张 run"。
//   3. **六个计数器**的原文（`CoverageProbe / CacheHit / FallbackApplied / FallbackTarget /
//      RunCount>1 / FallbackFailed`），且"**无信息**"与"0"分开报。
//   4. **A/B**：`WPF_LINUX_MULTIFONT=0` ⇒ 与今天逐位相同（id 逐项相等）；`=1` ⇒ 上面的读数。
//
// 【它**不**回答什么（诚实清单）】
//   · 应用级普查（`T1C_CENSUS_SUMMARY` 的 `id0/nonlatin/maxid`）需要**含本 shim 的 PC**：
//     本探针量的是"shim 交给渲染器的那批 glyph id"，**没有过 MIL 往返、没有光栅化**。
//   · 像素：这里不读图（读图要在起波后用 `t1c-census.sh` 抓帧）。
//
// 【仪器会不会撒谎（自检）】
//   · `ids` 一律从 **`GlyphRun.GlyphIndices`** 读 —— 与上游 `GlyphRun.cs:1876` 塞进
//     `MILCMD_GLYPHRUN_CREATE` 的是同一份数据（不是另算一份）；
//   · **独立校验**：每张 `GlyphRun` 的**自带面**必须把它的字符映射成它自己的 glyph id
//     （`GlyphTypeface.CharacterToGlyphMap[cp] == GlyphIndices[i]`）—— 这条是"整形面 == 渲染面"
//     的独立证据（不依赖 shim 内部的任何断言）；
//   · **渲染器能不能加载这份面**：用 Skia 的 `SKTypeface.FromFile(path, faceIndex)`（= 渲染器
//     那条链）真的加载一次，并核对族名 —— 直接怼 T1c 报的"派生化 / 无路径面 ⇒ MIL 解析不到"。
// =====================================================================================

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text.Json;
using System.IO;
using System.Text;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;
using SkiaSharp;
using WpfLinux.Shims.PresentationCore;

namespace MilBridge.CoverageProbe
{
    /// <summary>假 TextSource：按预置的 run 边界逐 run 交出 `TextCharacters`（各自带自己的 props）。</summary>
    internal sealed class MockTextSource : TextSource
    {
        private readonly string _text;
        private readonly List<(int Start, int Length, TextCharacters Run)> _runs =
            new List<(int, int, TextCharacters)>();

        internal MockTextSource(string text, IList<TextRunProperties> runProps, IList<int> runLengths)
        {
            _text = text;
            int pos = 0;
            for (int i = 0; i < runLengths.Count; ++i)
            {
                int len = runLengths[i];
                if (pos + len > text.Length) len = text.Length - pos;
                if (len <= 0) break;
                var tc = new TextCharacters(text.Substring(pos, len), runProps[i]);
                _runs.Add((pos, len, tc));
                pos += len;
            }
            if (pos < text.Length)      // 尾巴并进最后一个 run（不让"没覆盖到的尾巴"制造假象）
            {
                int tail = text.Length - pos;
                var tc = new TextCharacters(text.Substring(pos, tail), runProps[runProps.Count - 1]);
                _runs.Add((pos, tail, tc));
            }
        }

        internal string Text => _text;
        internal int RunCount => _runs.Count;

        public override TextRun GetTextRun(int cp)
        {
            foreach ((int s, int len, TextCharacters tc) in _runs)
                if (cp >= s && cp < s + len) return tc;
            return new TextEndOfParagraph(1);       // EOL/EOP（TryCollect 在这里停）
        }

        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
            => new TextSpan<CultureSpecificCharacterBufferRange>(0, new CultureSpecificCharacterBufferRange(CultureInfo.InvariantCulture, CharacterBufferRange.Empty));

        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
    }

    internal static class Program
    {
        private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";

        /// <summary>与 `samples/WpfTextDemo/MainWindow.xaml` 的 ① 号文本块**同一串**（中英混排）。</summary>
        private const string DemoText =
            "这是一段用于验证自动折行的中英混排文字：WPF on Linux renders wrapped text by measuring each line " +
            "and breaking at word boundaries，同时也要保证 CJK 字符之间可以正常断行、标点不会跑到行首。" +
            "The quick brown fox jumps over the lazy dog 以便观察英文断词；mixed 中英 mixed 混排 should look natural on every line.";

        private static int s_fail;
        private static readonly List<string> Fails = new List<string>();

        private static void Check(string id, string what, bool ok, string detail)
        {
            Console.WriteLine((ok ? "  PASS  " : "  FAIL  ") + id + " " + what
                              + (string.IsNullOrEmpty(detail) ? "" : "\n         " + detail));
            if (!ok) { ++s_fail; Fails.Add(id + " " + what + " :: " + detail); }
        }

        private static int Main(string[] argv)
        {
            string scenario = "single";
            double width = 380.0;
            string textOverride = null; double emOverride = 16.0, lhOverride = 0.0;
            string familyOverride = null; bool inkDiag = false; bool invertDiag = false; bool runPropsDiag = false;
            string tabOracle = null; bool tabDiag = false; string tabLines = null;
            string shapeFont = null, shapeText = null; string knownRed = null; bool modCheck = false; string armB = null; string ruleChk = null; bool fbChk = false;
            for (int i = 0; i < argv.Length; ++i)
            {
                if (argv[i] == "--scenario" && i + 1 < argv.Length) scenario = argv[++i];
                else if (argv[i] == "--width" && i + 1 < argv.Length) double.TryParse(argv[++i], NumberStyles.Float, CultureInfo.InvariantCulture, out width);
                else if (argv[i] == "--text" && i + 1 < argv.Length) textOverride = argv[++i];
                else if (argv[i] == "--em" && i + 1 < argv.Length) double.TryParse(argv[++i], NumberStyles.Float, CultureInfo.InvariantCulture, out emOverride);
                else if (argv[i] == "--lh" && i + 1 < argv.Length) double.TryParse(argv[++i], NumberStyles.Float, CultureInfo.InvariantCulture, out lhOverride);
                else if (argv[i] == "--family" && i + 1 < argv.Length) familyOverride = argv[++i];
                else if (argv[i] == "--inkdiag") inkDiag = true;
                else if (argv[i] == "--invert") invertDiag = true;
                else if (argv[i] == "--runprops") runPropsDiag = true;
                else if (argv[i] == "--tab-oracle" && i + 1 < argv.Length) tabOracle = argv[++i];
                else if (argv[i] == "--tab-diag") tabDiag = true;
                else if (argv[i] == "--tab-lines-oracle" && i + 1 < argv.Length) tabLines = argv[++i];
                else if (argv[i] == "--known-red" && i + 1 < argv.Length) knownRed = argv[++i];
                else if (argv[i] == "--modifier-check") modCheck = true;
                else if (argv[i] == "--modifier-armB" && i + 1 < argv.Length) armB = argv[++i];
                else if (argv[i] == "--modifier-rule-check" && i + 1 < argv.Length) ruleChk = argv[++i];
                else if (argv[i] == "--fallback-check") fbChk = true;
                else if (argv[i] == "--shape" && i + 2 < argv.Length) { shapeFont = argv[++i]; shapeText = argv[++i]; }
            }
            if (fbChk) return RunFallbackCheck();
            if (ruleChk != null) return RunModifierRuleCheck(ruleChk);
            if (armB != null) return RunModifierArmB(armB);
            if (modCheck) return RunModifierCheck();
            if (shapeFont != null) return RunShapeProbe(shapeFont, shapeText);
            if (tabLines != null) return RunTabLinesOracle(tabLines, knownRed);
            if (tabDiag) return RunTabDiag();
            if (tabOracle != null) return RunTabOracle(tabOracle);

            bool multi = HbTextFallback.MultiFontEnabled;
            Console.WriteLine("==================== T1d · CoverageProbe（真 shim 源 · 应用路径）====================");
            Console.WriteLine("shim tag       = " + HbShimSource.Tag);
            Console.WriteLine("scenario       = " + scenario + "（段落宽 " + width.ToString("F1") + " DIP）");
            Console.WriteLine("WPF_LINUX_MULTIFONT = " + (multi ? "<未设或缺省开>" : "显式关") + " ⇒ MultiFontEnabled=" + multi);
            Console.WriteLine("WPF_LINUX_FONT_DIR  = " + (Environment.GetEnvironmentVariable("WPF_LINUX_FONT_DIR") ?? "<未设>"));
            Console.WriteLine("WPF_LINUX_TEXTLINE_FALLBACK = " + (Environment.GetEnvironmentVariable("WPF_LINUX_TEXTLINE_FALLBACK") ?? "<未设>"));
            Console.WriteLine("回退接线开关 Enabled = " + HbTextFallback.Enabled);

            // ---- 仪器自检：HB 的 name 表读取（族名）在这台机器上到底能不能读 ----
            foreach (string fp in new[] {
                "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
                Root + "/build/fonts/NotoSans-Regular.ttf" })
            {
                Console.WriteLine("[T1D_PROBE] HB 族名探测 " + fp + " ⇒ " + (HbFaceCache.FamilyOf(fp, 0) ?? "<null>")
                                  + " / 面数=" + HbFaceCache.FaceCountOf(fp));
            }

            // ---- 面的准备：UI 面 = 拉丁面（模拟应用现状：默认 UI 族没有 CJK 字形）----
            Typeface uiFace = MakeTypeface(familyOverride ?? "Noto Sans");
            Typeface cjkFace = MakeTypeface("Noto Sans CJK JP");
            Console.WriteLine("UI 面   = " + Describe(uiFace));
            Console.WriteLine("CJK 面  = " + Describe(cjkFace));

            List<int> lens;
            List<TextRunProperties> props;
            if (scenario == "two")
            {
                // 两 run：第二个 run **自带 CJK 面** ⇒ 走"候选面②：其余 run 的面"
                // ⚠️ 边界必须**有序**（第一版取了两段的反向差 ⇒ 负数长度、run 被并掉）
                string cjkPart = "中英混排";
                int cut2 = DemoText.LastIndexOf(cjkPart, StringComparison.Ordinal);
                if (cut2 <= 0) cut2 = DemoText.Length / 2;
                lens = new List<int> { cut2, cjkPart.Length, DemoText.Length - (cut2 + cjkPart.Length) };
                props = new List<TextRunProperties>
                {
                    new HbRunProperties(uiFace, 16.0, null),
                    new HbRunProperties(cjkFace, 16.0, null),
                    new HbRunProperties(uiFace, 16.0, null),
                };
            }
            else
            {
                lens = new List<int> { DemoText.Length };
                props = new List<TextRunProperties> { new HbRunProperties(uiFace, 16.0, null) };
            }

            string effText = textOverride ?? DemoText;
            if (textOverride != null) { lens = new List<int> { effText.Length }; }
            if (emOverride != 16.0)
                for (int i = 0; i < props.Count; ++i)
                    props[i] = new HbRunProperties(props[i].Typeface, emOverride, null);
            var src = new MockTextSource(effText, props, lens);
            Console.WriteLine("假 TextSource：文本 " + DemoText.Length + " 字 / **run 数 = " + src.RunCount + "**");
            for (int i = 0; i < lens.Count; ++i)
                Console.WriteLine("   run#" + i + " len=" + lens[i] + " typeface=" + Describe(props[i].Typeface));
            Console.WriteLine();

            // ---- 驱动真应用路径 ----
            TextLine tl;
            try
            {
                tl = HbTextFallback.TryFormatLine(src, 0, width, 1.0, false, lhOverride);
            }
            catch (Exception e)
            {
                Console.WriteLine("  ❌ TryFormatLine 抛 " + e);
                return 2;
            }

            Check("P1", "TryFormatLine 接下了这一段（不是交回 LS）", tl != null,
                  tl == null ? "返回 null ⇒ 会回落到 LS（本档不可达）" : "ok：" + HbTextFallback.CacheInfo());

            // ================= P0 线索：逐张 GlyphRun 的 foreground（run 属性有没有跟着子段走） =================
            if (runPropsDiag)
            {
                Console.WriteLine();
                Console.WriteLine("     —— 逐张 GlyphRun 的 foreground（run 属性是否跟着子段走）——");
                Func<Typeface, Brush, TextRunProperties> mk = (tf, br) => new HbRunProperties(tf, 16.0, br);

                // C1：**单 run**（橙色）中英混排 ⇒ R1 会按码点切面（拉丁一段 + CJK 一段）
                var p1 = new List<TextRunProperties> { mk(uiFace, new SolidColorBrush(Colors.Orange)) };
                var c1 = new MockTextSource("seed-文本", p1, new List<int> { 7 });
                var l1 = HbTextFallback.TryFormatLine(c1, 0, 380.0, 1.0, false, 0) as HbTextLine;
                var r1 = ReadRunBrushes(l1);
                foreach (var r in r1)
                    Console.WriteLine("[T1D_RUNPROPS] C1(单run·橙) brush=" + r.Brush + " face=" + Path.GetFileName(r.Face)
                                      + " glyphs=" + r.Glyphs + " chars=\"" + r.Chars + "\"");
                bool c1one = r1.Count >= 2;
                for (int i = 1; i < r1.Count; ++i) if (r1[i].Brush != r1[0].Brush) c1one = false;
                Check("P12", "**单 run** 的混排行：R1 切出的每张子段 GlyphRun 都带**同一个** foreground（= 行级画刷，分段不产生两色）",
                      c1one && r1.Count > 0, "子段数=" + r1.Count + "；画刷=" + string.Join(",", r1.ConvertAll(x => x.Brush)));

                // C2：**两个 run，画刷不同**（run0 橙 'seed-' / run1 蓝 '文本'）⇒ 看第二个 run 的 foreground 有没有活下来
                var p2 = new List<TextRunProperties> {
                    mk(uiFace,  new SolidColorBrush(Colors.Orange)),
                    mk(cjkFace, new SolidColorBrush(Colors.Blue)) };
                var c2 = new MockTextSource("seed-文本", p2, new List<int> { 5, 2 });
                var l2 = HbTextFallback.TryFormatLine(c2, 0, 380.0, 1.0, false, 0) as HbTextLine;
                var r2 = ReadRunBrushes(l2);
                foreach (var r in r2)
                    Console.WriteLine("[T1D_RUNPROPS] C2(两run·橙+蓝) brush=" + r.Brush + " face=" + Path.GetFileName(r.Face)
                                      + " glyphs=" + r.Glyphs + " chars=\"" + r.Chars + "\"");
                bool anyBlue = r2.Exists(x => x.Brush.Contains("FF0000FF") || x.Brush == "#FF0000FF");
                Check("P13", "**【字段丢·#26 同族】**两个源 run 画刷不同（橙/蓝）时，第二段仍应是**它自己 run 的蓝**（否则就是被压成第一个 run 的）",
                      anyBlue, "子段数=" + r2.Count + "；画刷=" + string.Join(",", r2.ConvertAll(x => x.Brush))
                      + " ⇒ " + (anyBlue ? "第二个 run 的 foreground 活着" : "**第二个 run 的 foreground 被丢（全画成第一个 run 的）**"));
            }

            int totalGlyphs = 0, id0 = 0, nonLatin = 0, maxId = 0;
            int lines = 0, glyphRuns = 0, chunkedLines = 0;
            int cmapChecked = 0, cmapMismatch = 0, noCmap = 0, tokenZero = 0, skiaFail = 0;
            int substituted = 0, drawnNotdef = 0, idOverGlyphCount = 0;
            var faceFiles = new HashSet<string>(StringComparer.Ordinal);
            var allIds = new List<ushort>();
            var cmapSamples = new List<string>();
            var skiaSamples = new List<string>();

            if (tl != null)
            {
                // 逐行走完整段（TryFormatLine 只交第一行；其余按 Length 递进 —— 与调用方累加口径一致）
                int cpFirst = 0;
                double simHostY = 0;                 // 探针**自选**的模拟宿主 origin.y（逐行累加行高）
                while (tl != null && lines < 64)
                {
                    ++lines;
                    var hb = tl as HbTextLine;
                    if (hb == null) { Console.WriteLine("  ⚠ 交出来的不是 HbTextLine：" + tl.GetType().Name); break; }

                    Console.WriteLine("  行#" + (lines - 1) + " [cp " + cpFirst + ".." + (cpFirst + hb.Length) + ") Length=" + hb.Length
                                      + " Width=" + hb.Width.ToString("F3") + " Height=" + hb.Height.ToString("F3")
                                      + " Baseline=" + hb.Baseline.ToString("F3")
                                      + " TextHeight=" + hb.TextHeight.ToString("F4")
                                      + " **Extent=" + hb.Extent.ToString("F4") + "**"
                                      + " ws=" + hb.TrailingWhitespaceLength
                                      + " witw=" + hb.WidthIncludingTrailingWhitespace.ToString("F4")
                                      + " NewlineLength=" + hb.NewlineLength);
                    Console.WriteLine("     " + hb.FaceDiag(withToken: true));
                    if (hb.GlyphRunsForRasterization.Count > 1) ++chunkedLines;

                    // ---- 墨迹盒诊断（--inkdiag）：`ComputeInkBoundingBox` 到底给了什么 ----
                    if (inkDiag)
                    {
                        int ri = 0;
                        foreach (GlyphRun g0 in hb.GlyphRunsForRasterization)
                        {
                            Rect ink = g0.ComputeInkBoundingBox();
                            var sb2 = new StringBuilder();
                            sb2.Append("     [inkdiag r").Append(ri++).Append("] glyphs=").Append(g0.GlyphIndices.Count)
                               .Append(" inkBox=").Append(ink.IsEmpty ? "<Empty>" :
                                   "(" + ink.Left.ToString("F3") + "," + ink.Top.ToString("F3") + ")-(" +
                                   ink.Right.ToString("F3") + "," + ink.Bottom.ToString("F3") + ") h=" + (ink.Bottom - ink.Top).ToString("F3"))
                               .Append(" face=").Append(g0.GlyphTypeface.FontUri.LocalPath)
                               .Append('#').Append(g0.GlyphTypeface.FaceIndex)
                               .Append(" designEm=").Append(g0.GlyphTypeface.DesignEmHeight);
                            // **逐行 glyph id 全序列**（T1d P0 线索用；`--inkdiag` 开关）
                            {
                                var idl = new StringBuilder();
                                for (int gi = 0; gi < g0.GlyphIndices.Count; ++gi)
                                {
                                    idl.Append(g0.GlyphIndices[gi]);
                                    if (gi + 1 < g0.GlyphIndices.Count) idl.Append(',');
                                }
                                sb2.Append(" | glyphIds=[").Append(idl).Append(']');
                                var idChars = new StringBuilder();
                                if (g0.Characters != null)
                                    foreach (char c in g0.Characters)
                                        idChars.Append(c < ' ' || c == '\u00a0' || c == '\u200b'
                                            ? "U+" + ((int)c).ToString("X4") + " " : c.ToString());
                                sb2.Append(" chars=").Append(idChars);
                                // 运行时读 **ClusterMap**（T1d 修法①的验收牙齿：RTL 段应单调不减且覆盖每个字形）
                                if (g0.ClusterMap != null)
                                {
                                    var cm = new StringBuilder();
                                    for (int ci = 0; ci < g0.ClusterMap.Count; ++ci)
                                    {
                                        cm.Append(g0.ClusterMap[ci]);
                                        if (ci + 1 < g0.ClusterMap.Count) cm.Append(',');
                                    }
                                    sb2.Append(" clusterMap=[").Append(cm).Append(']');
                                }
                                sb2.Append(" bidiLevel=").Append(g0.BidiLevel);
                            }
                            for (int gi = 0; gi < Math.Min(4, g0.GlyphIndices.Count); ++gi)
                            {
                                double aw, ah, lsb, rsb, tsb, bsb, bl;
                                g0.GlyphTypeface.GetGlyphMetrics(g0.GlyphIndices[gi], g0.FontRenderingEmSize, 1.0,
                                    (float)g0.PixelsPerDip, TextFormattingMode.Ideal, false,
                                    out aw, out ah, out lsb, out rsb, out tsb, out bsb, out bl);
                                sb2.Append(" | g").Append(g0.GlyphIndices[gi]).Append(": aw=").Append(aw.ToString("F3"))
                                   .Append(" lsb=").Append(lsb.ToString("F3")).Append(" rsb=").Append(rsb.ToString("F3"))
                                   .Append(" tsb=").Append(tsb.ToString("F3")).Append(" bsb=").Append(bsb.ToString("F3"));
                            }
                            Console.WriteLine(sb2.ToString());
                        }
                    }

                    // ---- P0:InvertAxes（RTL）检查 ----
                    if (invertDiag)
                    {
                        CheckInversion(hb, width, hb.LineStartForDiag, familyOverride ?? "Noto Sans");
                    }

                    // ---- 站点 B（HBLINE B）：真的调一次 `Draw` ----
                    //   ⚠️ 这里的 origin 是**探针自选的**（模拟"宿主逐行给递增 y"），
                    //      它不是"真宿主给的数"；真宿主的值要跑应用（`WPF_LINUX_HBLINE_TRACE=1`）。
                    try
                    {
                        var dv = new DrawingVisual();
                        using (DrawingContext dc = dv.RenderOpen())
                            hb.Draw(dc, new Point(0, simHostY), InvertAxes.None);
                        simHostY += hb.Height;
                    }
                    catch (Exception e) { Console.WriteLine("     ⚠ Draw 调用失败：" + e.GetType().Name + ": " + e.Message); }

                    foreach (GlyphRun gr in hb.GlyphRunsForRasterization)
                    {
                        ++glyphRuns;
                        if (gr.GlyphTypeface != null) faceFiles.Add(gr.GlyphTypeface.FontUri.LocalPath);
                        if (gr.GlyphTypeface != null && gr.GlyphTypeface.GetDWriteFontAddRef == IntPtr.Zero) ++tokenZero;

                        // 渲染器那条链能不能加载这份面（T1c 的硬约束：必须"文件路径 + faceIndex"）
                        if (gr.GlyphTypeface != null)
                        {
                            string fp = gr.GlyphTypeface.FontUri.LocalPath;
                            int fi = gr.GlyphTypeface.FaceIndex;
                            try
                            {
                                using (SKTypeface sk = SKTypeface.FromFile(fp, fi))
                                {
                                    if (sk == null)
                                    {
                                        ++skiaFail;
                                        if (skiaSamples.Count < 4) skiaSamples.Add(fp + "#" + fi + " ⇒ SKTypeface.FromFile = null");
                                    }
                                }
                            }
                            catch (Exception e)
                            {
                                ++skiaFail;
                                if (skiaSamples.Count < 4) skiaSamples.Add(fp + "#" + fi + " ⇒ " + e.GetType().Name);
                            }
                        }

                        // ---- 普查（与 T2b 的 GlyphRunCensus 同一量：已解码的 glyph id）----
                        ushort[] ids = new ushort[gr.GlyphIndices.Count];
                        for (int i = 0; i < ids.Length; ++i) ids[i] = gr.GlyphIndices[i];
                        totalGlyphs += ids.Length;
                        allIds.AddRange(ids);
                        int glyphCountOfFace = gr.GlyphTypeface != null ? gr.GlyphTypeface.GlyphCount : 0;
                        foreach (ushort id in ids)
                        {
                            if (id == 0) ++id0;
                            if (id >= 0x1000) ++nonLatin;
                            if (id > maxId) maxId = id;
                            // 强校验：这份 id 必须**存在于它所挂的那份面**里（否则就是"id 与面不是一套"）
                            if (glyphCountOfFace > 0 && id >= glyphCountOfFace) ++idOverGlyphCount;
                        }

                        // ---- 独立校验：这张 run 自带的面必须把它的字符映射成它的 glyph id ----
                        var chars = new char[gr.Characters.Count];
                        for (int i = 0; i < chars.Length; ++i) chars[i] = gr.Characters[i];
                        string rt = new string(chars);
                        if (gr.GlyphTypeface != null)
                        {
                            IDictionary<int, ushort> map = gr.GlyphTypeface.CharacterToGlyphMap;
                            for (int g = 0; g < ids.Length; ++g)
                            {
                                if (g > 0 && gr.ClusterMap[g] == gr.ClusterMap[g - 1]) continue;   // 非簇首（连字分量）跳过
                                int ci = gr.ClusterMap[g];
                                if (ci < 0 || ci >= rt.Length) continue;
                                int cp = char.ConvertToUtf32(rt, ci);
                                ++cmapChecked;
                                ushort want;
                                if (map == null || !map.TryGetValue(cp, out want)) { ++noCmap; continue; }
                                // 「整形面 == 渲染面」的**正确判据**：渲染面的 cmap 必须与 **HarfBuzz 对同一份面**
                                //   给出的 nominal glyph 一致（面下标错 ⇒ 这里就炸）。
                                // ⚠️ **不能**拿"实际画出来的 id"去比 cmap：GSUB（CJK 的 `locl`）本来就会把它换成
                                //   另一个 id（实测 U+6BB5：cmap=22783、zh-cn 下 locl⇒22784）—— 那是**正确的整形**，
                                //   第一版把它当"不符"（21 个）是**仪器在撒谎**，已改成下面的口径。
                                int hbNominal = HbShaper.NominalGlyph(gr.GlyphTypeface.FontUri.LocalPath,
                                                                     gr.GlyphTypeface.FaceIndex, cp);
                                if (hbNominal != want)
                                {
                                    ++cmapMismatch;
                                    if (cmapSamples.Count < 4)
                                        cmapSamples.Add("U+" + cp.ToString("X4") + " 面=" + gr.GlyphTypeface.FontUri.LocalPath
                                                        + "#" + gr.GlyphTypeface.FaceIndex + " PC-cmap=" + want + " HB-nominal=" + hbNominal);
                                }
                                if (ids[g] != want) ++substituted;        // 被 GSUB 换过（信息项，不是失败）
                                if (ids[g] == 0) ++drawnNotdef;          // 这份面画不出该字符（= 就是病灶）
                            }
                        }
                    }

                    cpFirst += hb.Length;
                    if (cpFirst >= src.Text.Length + 1) break;
                    tl = HbTextFallback.TryFormatLine(src, cpFirst, width, 1.0, false, lhOverride);
                }
            }

            // ---- A/B 的"逐位"证据：MULTIFONT=0 时，把本路径的 id 序列与
            //      **单字体入口 `HbTextLineFactory.FormatParagraph`**（= 改前应用走的那一段、
            //      本工程从未改过）逐项比。两条必须**完全相等**。
            string idsJoined = JoinIds(allIds);
            bool abCompared = false, abSame = false; string abDetail = "（仅在 MULTIFONT=0 档比较）";
            if (!multi && glyphRuns > 0)
            {
                try
                {
                    GlyphTypeface uiGt; Typeface uiTf = MakeTypeface("Noto Sans");
                    if (uiTf != null && uiTf.TryGetGlyphTypeface(out uiGt) && uiGt != null)
                    {
                        var refIds = new List<ushort>();
                        int c0;
                        List<HbTextLine> refLines = HbTextLineFactory.FormatParagraph(
                            DemoText, uiGt.FontUri.LocalPath, 16.0, width, uiGt, 1.0f,
                            new HbRunProperties(uiTf, 16.0, null), false, false, 0, out c0);
                        foreach (HbTextLine L in refLines)
                            foreach (GlyphRun g2 in L.GlyphRunsForRasterization)
                                for (int i = 0; i < g2.GlyphIndices.Count; ++i) refIds.Add(g2.GlyphIndices[i]);
                        abCompared = true;
                        abSame = JoinIds(refIds) == idsJoined;
                        abDetail = "本条路径 " + allIds.Count + " 个 id vs 单字体入口（改前那段代码）"
                                   + refIds.Count + " 个 id ⇒ " + (abSame ? "**逐项相等**" : "**不等**");
                    }
                }
                catch (Exception e) { abDetail = "比较抛 " + e.GetType().Name + ": " + e.Message; }
            }

            Console.WriteLine();
            Console.WriteLine("========== 读数（原文） ==========");
            Console.WriteLine("[T1D_PROBE] multifont=" + (multi ? 1 : 0) + " scenario=" + scenario
                              + " runCount=" + src.RunCount
                              + " lines=" + lines + " glyphRuns=" + glyphRuns + " chunkedLines=" + chunkedLines
                              + " glyphs=" + totalGlyphs + " id0=" + id0 + " nonlatin=" + nonLatin + " maxid=" + maxId
                              + " distinctFaces=" + faceFiles.Count);
            foreach (string f in faceFiles) Console.WriteLine("[T1D_PROBE]   face文件=" + f);
            Console.WriteLine("[T1D_PROBE] ab(逐位): compared=" + abCompared + " same=" + abSame + " " + abDetail);
            Console.WriteLine("[T1D_PROBE] ids=" + idsJoined);
            Console.WriteLine("[T1D_PROBE] counters: " + HbFallbackDiag.SummaryFragment());
            Console.WriteLine("[T1D_PROBE] detail:   " + HbFallbackDiag.DetailFragment());
            Console.WriteLine("[T1D_PROBE] shim:     " + HbTextLineScaffold.SummaryLine());
            Console.WriteLine();

            // ---- 自检（仪器不许撒谎）----
            // ⚠️ **"没有数据"不许冒充"通过"**：下面四条都先要求 glyphRuns > 0，
            //    否则报"无信息（0 张 run）"并**判失败** —— 本项目栽过"空帧下的 0 也是绿"。
            bool hasData = glyphRuns > 0;
            Check("P2", "每张 GlyphRun 的面都能被**渲染器那条链**加载（SKTypeface.FromFile(path, faceIndex)）",
                  hasData && skiaFail == 0,
                  !hasData ? "**无信息**：0 张 GlyphRun（不是\"都可加载\"）"
                           : (skiaFail == 0 ? glyphRuns + " 张 run 全部可加载" : string.Join(" | ", skiaSamples)));
            Check("P3", "每张 GlyphRun 的面令牌非 0（MIL 能反查到面）", hasData && tokenZero == 0,
                  !hasData ? "**无信息**：0 张 GlyphRun" : (tokenZero == 0 ? "全部非 0" : tokenZero + " 张 run 的令牌 = 0"));
            Check("P6", "独立校验（强）：**画出来的 glyph id 必须存在于它所挂的那份面里**（id < 该面字形数）",
                  hasData && idOverGlyphCount == 0,
                  !hasData ? "**无信息**：0 张 GlyphRun"
                           : idOverGlyphCount + " 个 id 超出所在面的字形数（这会把『id 与面不是一套』抓出来）"
                             + "；被 GSUB 换过的簇首 " + substituted + " 个；画成 .notdef 的簇首 " + drawnNotdef + " 个");
            Check("P4", "独立校验：**整形面 == 渲染面**（渲染面的 cmap == HB 对**同一份面**给的 nominal glyph；逐簇首）",
                  hasData && cmapChecked > 0 && cmapMismatch == 0 && noCmap == 0,
                  !hasData ? "**无信息**：0 张 GlyphRun"
                           : "检查 " + cmapChecked + " 个簇首；不符 " + cmapMismatch + "；cmap 缺项 " + noCmap
                             + (cmapSamples.Count > 0 ? "\n         " + string.Join("\n         ", cmapSamples) : ""));
            // ⚠️ 判据与**标签**必须一致：第一版标签写"真的拆过（chunkedLines>0）"，条件却没查它
            //    ⇒ 在"根本没拆"的档里也报 PASS（仪器在撒谎）。现在条件里就是它。
            Check("P5", "**一面一 run**：真的拆过（chunkedLines>0）+ 张数不少于行数",
                  hasData && chunkedLines > 0 && glyphRuns >= lines,
                  "lines=" + lines + " glyphRuns=" + glyphRuns + " chunkedLines=" + chunkedLines);

            Console.WriteLine();
            Console.WriteLine(s_fail == 0 ? "== 探针自检全过 ==" : "== 探针自检失败 " + s_fail + " 条 ==");
            foreach (string f in Fails) Console.WriteLine("  ❌ " + f);
            return s_fail == 0 ? 0 : 1;
        }

        /// <summary>把一次 `Draw` 产生的绘制树走一遍：收集 push 过的矩阵 + 每张 GlyphRun 的基线原点。</summary>
        private static void WalkDrawing(Drawing d, List<string> matrices, List<(double X, double Y, int N)> runs,
                                        List<string> kinds = null)
        {
            if (kinds != null && d != null) kinds.Add(d.GetType().Name);
            if (d is DrawingGroup g)
            {
                if (g.Transform != null)
                {
                    Matrix m = g.Transform.Value;
                    matrices.Add($"M11={m.M11} M22={m.M22} OffsetX={m.OffsetX} OffsetY={m.OffsetY}");
                }
                foreach (Drawing c in g.Children) WalkDrawing(c, matrices, runs, kinds);
            }
            else if (d is GlyphRunDrawing grd && grd.GlyphRun != null)
            {
                runs.Add((grd.GlyphRun.BaselineOrigin.X, grd.GlyphRun.BaselineOrigin.Y, grd.GlyphRun.GlyphIndices.Count));
            }
        }

        private static (List<string> matrices, List<(double X, double Y, int N)> runs, string err, List<string> kinds)
            DrawAndInspect(TextLine line, InvertAxes inv)
        {
            var matrices = new List<string>();
            var runs = new List<(double, double, int)>();
            var kinds = new List<string>();
            try
            {
                var dv = new DrawingVisual();
                using (DrawingContext dc = dv.RenderOpen())
                    line.Draw(dc, new Point(0, 0), inv);      // 契约入口就是它（origin=(0,0)）
                string treeInfo = dv.Drawing == null ? "Drawing=null"
                    : "Drawing=" + dv.Drawing.GetType().Name + " children=" + dv.Drawing.Children.Count
                      + " transform=" + (dv.Drawing.Transform == null ? "null" : "有");
                kinds.Add(treeInfo);
                WalkDrawing(dv.Drawing, matrices, runs, kinds);
                return (matrices, runs, null, kinds);
            }
            catch (Exception e) { return (matrices, runs, e.GetType().Name + ": " + e.Message, kinds); }
        }

        /// <summary>本行内容是否是 RTL 文字（希伯来/阿拉伯……）—— 用于 P8/P10 的**分支判据**（修法②）。</summary>
        private static bool HasRtlScript(string s)
        {
            if (string.IsNullOrEmpty(s)) return false;
            foreach (char c in s)
                if ((c >= 0x0590 && c <= 0x05FF) || (c >= 0x0600 && c <= 0x06FF)
                    || (c >= 0x0700 && c <= 0x074F) || (c >= 0x0750 && c <= 0x077F)
                    || (c >= 0xFB1D && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF))
                    return true;
            return false;
        }

        private static void CheckInversion(HbTextLine hb, double pw, int lineStart, string uiFamily)
        {
            // ⭐ 修法②（T1d §13）：本行内容若是 RTL（我们输出**逻辑序**）⇒ **不再推水平反演**（宿主的元素镜像
            //   就是产生视觉序的那一次）；LTR 内容仍按上游口径推。P8/P10 因此改成**分支判据**。
            bool contentRtl = HasRtlScript(hb.LineTextForDiag);
            Console.WriteLine("     —— InvertAxes/RTL 检查（本行段落宽=" + pw.ToString("F1") + "，由 FormatLine 传入；"
                              + "内容=" + (contentRtl ? "RTL 文字" : "非 RTL") + "）——");

            var none = DrawAndInspect(hb, InvertAxes.None);
            var horiz = DrawAndInspect(hb, InvertAxes.Horizontal);
            Check("P7", "`Draw(InvertAxes.Horizontal)` **不抛**（宿主的 RTL 路径；改前这里抛 NotSupportedException）",
                  horiz.err == null, horiz.err == null ? "ok" : horiz.err);
            bool hasXMirror = horiz.matrices.Exists(m => m.Contains("M11=-1") && m.Contains("OffsetX="));
            if (contentRtl)
                Check("P8", "**RTL 内容**：Horizontal 时**不推**水平反演（修法② ⇒ 宿主镜像负责产出视觉序；推了就是双重反转）",
                      !hasXMirror,
                      "绘制树里的矩阵：" + (horiz.matrices.Count == 0 ? "(无)" : string.Join(" | ", horiz.matrices)));
            else
                Check("P8", "**非 RTL 内容**：Horizontal 时**仍推**镜像矩阵（M11=−1、OffsetX=段落宽）",
                      hasXMirror && horiz.matrices.Exists(m => m.Contains("OffsetX=" + ((long)pw).ToString())),
                      "绘制树里的矩阵：" + (horiz.matrices.Count == 0 ? "(无)" : string.Join(" | ", horiz.matrices)));
            // P9：**Draw 不许改行状态**。`DrawingVisual.Drawing` 在本环境里只有"push 过变换"时才非 null
            //     （实测：None 时 `Drawing=null`）⇒ 拿不到绘制树里的 run，**改用"行自身状态"这个可观测量**：
            //     镜像只能来自变换，而 run 的原点/字形数在 Draw 前后必须逐位不变（否则就是"偷偷改位置"）。
            var runsBefore = new List<(double X, double Y, int N)>();
            foreach (GlyphRun g0 in hb.GlyphRunsForRasterization)
                runsBefore.Add((g0.BaselineOrigin.X, g0.BaselineOrigin.Y, g0.GlyphIndices.Count));
            DrawAndInspect(hb, InvertAxes.Horizontal);
            var runsAfter = new List<(double X, double Y, int N)>();
            foreach (GlyphRun g0 in hb.GlyphRunsForRasterization)
                runsAfter.Add((g0.BaselineOrigin.X, g0.BaselineOrigin.Y, g0.GlyphIndices.Count));
            bool unchanged = runsBefore.Count > 0 && runsBefore.Count == runsAfter.Count;
            if (unchanged)
                for (int i = 0; i < runsBefore.Count; ++i)
                    if (runsBefore[i].X != runsAfter[i].X || runsBefore[i].Y != runsAfter[i].Y
                        || runsBefore[i].N != runsAfter[i].N)
                    { unchanged = false; break; }
            Check("P9", "Draw 前后**行内 run 原点/字形数逐位不变**（⇒ 镜像只能来自变换，没偷偷改位置）",
                  unchanged,
                  "run 数=" + runsBefore.Count + "；"
                  + string.Join(",", runsBefore.ConvertAll(r => $"({r.X:F3},{r.Y:F3})x{r.N}"))
                  + "；绘制树读数=" + (none.kinds.Count == 0 ? "(无)" : string.Join(" ", none.kinds)));

            var vert = DrawAndInspect(hb, InvertAxes.Vertical);
            var both = DrawAndInspect(hb, InvertAxes.Both);
            // ⭐ 修法② 后：RTL 内容在 Both 下只应剩垂直分量（M22=−1）；非 RTL 内容两者都在。
            bool bothOk = both.err == null && both.matrices.Exists(m => m.Contains("M22=-1"))
                          && (contentRtl ? !both.matrices.Exists(m => m.Contains("M11=-1"))
                                         : both.matrices.Exists(m => m.Contains("M11=-1")));
            Check("P10", contentRtl
                        ? "Vertical / Both 的矩阵正确（RTL 内容：Both 只留 M22=−1、OffsetY=行高 —— 水平分量已被修法② 摘掉）"
                        : "Vertical / Both 的矩阵正确（M22=−1、OffsetY=行高；Both 两者都有）",
                  vert.err == null && vert.matrices.Exists(m => m.Contains("M22=-1")) && bothOk,
                  "Vertical: " + (vert.matrices.Count == 0 ? "(无)" : string.Join(" | ", vert.matrices))
                  + "  Both: " + (both.matrices.Count == 0 ? "(无)" : string.Join(" | ", both.matrices)));

            // P11：段落宽未知的那一行（真的用 width=0 排一行出来）⇒ 必须"不抛 + 降级可见"
            long nwBefore = HbTextLineScaffold.InvertedNoWidth;
            string p11err = null; int p11matrices = 0;
            try
            {
                GlyphTypeface gt0; Typeface tf0 = MakeTypeface(uiFamily);
                if (tf0 != null && tf0.TryGetGlyphTypeface(out gt0) && gt0 != null)
                {
                    int c0;
                    List<HbTextLine> zeroWide = HbTextLineFactory.FormatParagraph(
                        "abc", gt0.FontUri.LocalPath, 16.0, 0.0, gt0, 1.0f,
                        new HbRunProperties(tf0, 16.0, null), false, false, 0, out c0);
                    var ins = DrawAndInspect(zeroWide[0], InvertAxes.Horizontal);
                    p11err = ins.err; p11matrices = ins.matrices.Count;
                }
            }
            catch (Exception e) { p11err = e.GetType().Name + ": " + e.Message; }
            Check("P11", "段落宽未知(0)+Horizontal ⇒ **不抛**、**不镜像**、并计入 `invertedNoWidth`（诚实降级可见）",
                  p11err == null && HbTextLineScaffold.InvertedNoWidth > nwBefore,
                  p11err == null
                      ? "invertedNoWidth " + nwBefore + " → " + HbTextLineScaffold.InvertedNoWidth
                        + "；矩阵数=" + p11matrices + "（0 = 没镜像）"
                      : p11err);
            Console.WriteLine("     [读数] invertedLines=" + HbTextLineScaffold.InvertedLines
                              + " invertedNoWidth=" + HbTextLineScaffold.InvertedNoWidth
                              + " antiMatrixMismatch=" + HbTextLineScaffold.AntiMatrixMismatch);
        }

        /// <summary>把一张 Drawing 树摊平（`DrawingGroup.Children` 递归）。</summary>
        private static void Flatten(Drawing d, List<Drawing> outList)
        {
            if (d == null) return;
            if (d is DrawingGroup g) { foreach (Drawing c in g.Children) Flatten(c, outList); }
            else outList.Add(d);
        }

        /// <summary>
        /// **逐张 GlyphRun 读它带的 foreground 画刷**（`GlyphRunDrawing.ForegroundBrush` 是 public）。
        /// 用 `DrawingGroup.Open()` 而不是 `DrawingVisual.Drawing`：后者在"没 push 过变换"时是 null（实测踩过）。
        /// </summary>
        private static List<(string Brush, string Face, int Glyphs, string Chars)> ReadRunBrushes(TextLine line)
        {
            var res = new List<(string, string, int, string)>();
            var dg = new DrawingGroup();
            using (DrawingContext dc = dg.Open()) line.Draw(dc, new Point(0, 0), InvertAxes.None);
            var flat = new List<Drawing>();
            Flatten(dg, flat);
            foreach (Drawing d in flat)
            {
                if (!(d is GlyphRunDrawing grd) || grd.GlyphRun == null) continue;
                Brush b = grd.ForegroundBrush;
                string col;
                if (b == null) col = "<null：等于不画>";
                else if (b is SolidColorBrush scb) col = scb.Color.ToString();
                else col = b.GetType().Name;
                var cs = new StringBuilder();
                if (grd.GlyphRun.Characters != null)
                    foreach (char c in grd.GlyphRun.Characters) cs.Append(c);
                res.Add((col, grd.GlyphRun.GlyphTypeface != null ? grd.GlyphRun.GlyphTypeface.FontUri.LocalPath : "?", 
                         grd.GlyphRun.GlyphIndices.Count, cs.ToString()));
            }
            return res;
        }

        private static string JoinIds(List<ushort> ids)
        {
            var sb = new StringBuilder(ids.Count * 5);
            foreach (ushort id in ids) sb.Append(id.ToString("x")).Append(',');
            return sb.ToString();
        }

        /// <summary>
        /// **U1 Tab oracle 逐例对拍**（`tests/parity/windows/tab/out/tab-oracle.json`，114 例）：
        ///   · 字体用 **Liberation Sans**（Arial 的度量兼容替身；oracle 固定 Arial）；
        ///   · 逐字比 `xFromLeftDip` —— **RTL 用归一化量**：`xFromLeft = 行宽 − 内部右缘`（U1 在 bidi 那轮的教训）；
        ///   · 另比 行宽 / 每个 `\t` 的 advance；容差 0.01 DIP；
        ///   · `defaultIncrementalTab` 传 **NaN** ⇒ 框架默认 `4 × em`（= 这批 oracle 的配置）。
        /// 装置自证用；**不是应用读数**。
        /// </summary>
        private static int RunTabOracle(string path)
        {
            const string fontPath = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf";
            GlyphTypeface gt = null;
            Typeface tf = MakeTypeface("Liberation Sans");
            if (tf != null) tf.TryGetGlyphTypeface(out gt);
            if (gt == null) { try { gt = new GlyphTypeface(new Uri("file://" + fontPath)); } catch (Exception) { } }
            Console.WriteLine("TAB_ORACLE 字体解析: family=Liberation Sans ⇒ " + (gt != null ? gt.FontUri.LocalPath : "<失败>"));
            if (gt == null) return 2;
            JsonDocument doc;
            try { doc = JsonDocument.Parse(File.ReadAllText(path)); }
            catch (Exception e)
            {
                // ⚠️ 2026-09-14：读档失败**不许崩**（旧行为 = 未捕获异常 ⇒ 进程异常终止 / core dump；
                //   T3 踩过同族、我 22:1x 用不存在的路径也踩到一次 rc=134）。
                Console.WriteLine("TAB_ORACLE 读档失败：" + e.GetType().Name + ": " + e.Message + "（路径=" + path + "）");
                Console.WriteLine("TAB_ORACLE 用法：--tab-oracle <**逐例 perChar** 的 JSON，如 tests/parity/windows/tab/out/tab-oracle.json>");
                return 2;
            }
            if (!doc.RootElement.TryGetProperty("cases", out JsonElement casesProbe) || casesProbe.ValueKind != JsonValueKind.Array)
            {
                Console.WriteLine("TAB_ORACLE 形状不符：缺 cases 数组");
                return 2;
            }
            bool anyPerCase = false;
            foreach (JsonElement cc in casesProbe.EnumerateArray()) if (cc.TryGetProperty("perChar", out _)) { anyPerCase = true; break; }
            if (!anyPerCase)
            {
                Console.WriteLine("TAB_ORACLE 形状不符：需要**逐例 perChar** 结构（cases[].perChar[]）；"
                                  + "逐行 perChar 结构请用 `--tab-lines-oracle`");
                return 2;
            }
            var cases = doc.RootElement.GetProperty("cases");
            int total = 0, pass = 0, shown = 0; double worstAll = 0; string worstCase = "";
            int NoBoundsTotal = 0, NoBoundsTab = 0, BidiSkipped = 0;
            // ══════════ `#26` W26A · `D-G12`：把真值 `perChar[].width` **接进比较** ══════════
            // 【缺口】`:789-791` 一直把 `pc.GetProperty("width")` 读进 tuple 的第 4 项 `w`，
            //   而 `:815` 起的比较循环**只用 `xfl`** ⇒ 356 条真值**读了不用**（`w` 未用是唯一痕迹）。
            // 【为什么让它参与 `ok`】`ok` 今天 = 「整例 `width`(0.01) ∧ 逐字 `xFromLeftDip`(0.01)」——
            //   「行宽」本身 = 所有字宽之和 ⇒ 用 0.05 读行宽、却对**逐字宽**零引用，口径自相矛盾。
            //   本件把逐字宽按**与 `xFromLeftDip` 同一个** 0.05 口径接进 `ok`（**只加严**，不放宽任何既有条件）。
            // 【为什么必须分开报数】`D-G12` 的红**不被任何门禁读**（`--tab-oracle` 不在 `#26` 的臂集合里；
            //   `grep -n -- '--tab-oracle' run.sh verify-all.sh tools/*.sh` = 0 命中）⇒ 必须把
            //   「只宽红」「只位置红」「两者都红」分开印，否则无法归因新红。
            int posRedX = 0, posRedW = 0, posRedBoth = 0, posRedTot = 0; double worstW = 0; string worstWWhy = "";
            int wTruthCh = 0;   // 真值 `width > 0.05` 的 `perChar` 条数（= **本件真正接上的判别面**）
            int wNoise05 = 0, wNoise01 = 0, wNoise005 = 0, wNoise002 = 0;   // 字宽噪声分位（诊断，不入判据）
            int posRedCases = 0;            // 逐字红（宽或位置）出现的**例数**（诊断，不入判据）
            // 【W26A 反极性用的替换量】**默认不生效**（环境变量缺省即跳过）：把"我方字宽"按外部因子缩放。
            //   用途 = 证明 `D-G12` 的逐字宽比较**有判别力**（否则"读了不用"只是换个地方不用）。
            //   `W26A_WSCALE` 未设 ⇒ 与"不写这一段"逐位相同（用默认趟与 `=1.0` 趟逐字节相同实证）。
            //   ⚠️ **判据与归因必须共用同一个量**（本件第一版就在这里踩过：判据用缩放后的、归因用未缩放的
            //   ⇒ 归因行印不出红字符；靠 `D-G12-CH` 逐字符读数才定位到）。
            double wScale = 1.0;
            if (Environment.GetEnvironmentVariable("W26A_WSCALE") is string wsc0
                && double.TryParse(wsc0, System.Globalization.NumberStyles.Float,
                                   System.Globalization.CultureInfo.InvariantCulture, out double wf0))
                wScale = wf0;
            double OurW(double rawW) => rawW * wScale;
            int posRedCmp = 0;              // **真比较**范围内的红（宽或位置）—— 只有它进 `ok`
            int posRedNonCmp = 0;           // 不可判字宽（tab / 我方零宽 / 无 bounds）**但位置**红
            int wSkip = 0, wSkipTab = 0, wSkipZero = 0;   // 字宽不可判的字符数（tab / 我方零宽）
            foreach (JsonElement c in cases.EnumerateArray())
            {
                ++total;
                string id = c.GetProperty("id").GetString();
                string text = c.GetProperty("text").GetString();
                double pw = c.GetProperty("paragraphWidthDip").GetDouble();
                double indent = c.GetProperty("indentDip").GetDouble();
                double em = c.GetProperty("emSizeDip").GetDouble();
                bool rtl = string.Equals(c.GetProperty("flowDirection").GetString(), "RightToLeft", StringComparison.Ordinal);
                bool textHasRtl = false;
                foreach (char ch0 in text) if (ch0 >= 0x0590 && ch0 <= 0x08FF) { textHasRtl = true; break; }
                if (rtl && !textHasRtl) { ++BidiSkipped; continue; }   // 纯拉丁内容 + RTL 段落 ⇒ 依赖 bidi（§8.7 射程外）
                double expW = c.GetProperty("width").GetDouble();
                List<HbTextLine> lines; int consumed;
                try
                {
                    // 【主控 2026-09-15 修：**仪器建模错误** —— 旧代码把 oracle 的宽度约束丢掉了】
                    //   ⛔ 旧注释称"oracle 的段落是 NoWrap" —— **该前提对该 oracle 的 436/436 例全部为假**：
                    //     每个 case 都明写 `textWrapping: "Wrap"`（实测分布 `{'Wrap': 436}`），并带
                    //     `paragraphWidthDip`（40/80/96/100/…/1e6）；`paragraphProperties.fixed` 亦逐字写
                    //     `TextAlignment=Left, TextWrapping=Wrap, LineHeight=0, Tabs=null`。
                    //   旧代码喂 `1e6` + `wrap: false` ⇒ **两侧在不同配置下比**：
                    //     · `wrap:false` ⇒ `TabClampWidthFor(false, …) = +∞` ⇒ `EffectiveWidthTab` 里那两处
                    //       `if (!double.IsInfinity(clampWidth))` 全不成立 ⇒ **钳位/`lineContentStart` 整条管线被绕过**
                    //       （所以 `(A)`/`(B)`/`(C)` 在该臂上**按构造惰性** —— 实测 `(B)+(C)` 落地后本臂日志**逐字节未变**）；
                    //     · `width=1e6` ⇒ 任何候选都"放得下" ⇒ **永远不折行** ⇒ `lineCount>=2` 的 107 例**必然**对不上。
                    //   ⇒ 实测后果：`结构败=132` / `探针层未登记失败 178` —— **是仪器artifact，不是 shim 缺陷**。
                    //   修法 = **按 oracle 的原值喂**：`paragraphWidthDip` + `wrap: true`（tab 间隔仍由
                    //   `incrementalTabArm` 决定：`DefaultIncrementalTab=default` ⇒ `NaN` ⇒ 框架默认 4×emSize；
                    //   `=0` ⇒ `0.0` ⇒ 显式无停靠位）。
                    lines = HbTextLineFactory.FormatParagraph(text, fontPath, em, pw, gt, 1.0f,
                                new HbRunProperties(tf, em, null), false, false, 0, out consumed,
                                indentDip: indent, defaultIncrementalTab: double.NaN, wrap: true);
                }
                catch (Exception e)
                {
                    if (shown++ < 6) Console.WriteLine("  ❌ " + id + " 排版抛 " + e.GetType().Name + ": " + e.Message);
                    continue;
                }
                if (lines.Count == 0) { if (shown++ < 6) Console.WriteLine("  ❌ " + id + " 0 行"); continue; }
                HbTextLine line = lines[0];
                double P = line.Width;
                double worst = 0; string why = "";
                var exp = new List<(int i, string ch, double xfl, double w)>();
                foreach (JsonElement pc in c.GetProperty("perChar").EnumerateArray())
                    exp.Add((pc.GetProperty("i").GetInt32(), pc.GetProperty("char").GetString(),
                             pc.GetProperty("xFromLeftDip").GetDouble(), pc.GetProperty("width").GetDouble()));
                // 我们的逐字区间：`GetTextBounds(i,1)`；**tab 这类控制字符可能没有 run-bounds** ⇒ 显式计数并用邻居插值
                var ours = new double[exp.Count, 2];
                var have = new bool[exp.Count];
                int noBounds = 0, noBoundsTab = 0;
                for (int k = 0; k < exp.Count; ++k)
                {
                    IList<TextBounds> tb = null;
                    try { tb = line.GetTextBounds(exp[k].i, 1); } catch (Exception) { }
                    if (tb != null && tb.Count > 0 && tb[0].TextRunBounds != null && tb[0].TextRunBounds.Count > 0)
                    {
                        ours[k, 0] = tb[0].TextRunBounds[0].Rectangle.X;
                        ours[k, 1] = tb[0].TextRunBounds[0].Rectangle.Width;
                        have[k] = true;
                    }
                    else { ++noBounds; if (exp[k].ch == "\t") ++noBoundsTab; }
                }
                for (int k = 0; k < exp.Count; ++k)
                    if (!have[k])
                    {
                        // 插值：x = 前一字的 x+width（或 0/Indent），width = 下一字的 x − 本字 x
                        double x0 = k > 0 && have[k - 1] ? ours[k - 1, 0] + ours[k - 1, 1] : 0;
                        double x1 = k + 1 < exp.Count && have[k + 1] ? ours[k + 1, 0] : x0;
                        ours[k, 0] = x0; ours[k, 1] = x1 - x0;
                    }
                int posRedWAtCaseStart = posRedW;   // 例级快照：用于判断"本例是否因**宽**出红"
                for (int k = 0; k < exp.Count; ++k)
                {
                    double xfl = exp[k].xfl;
                    double wTruth = exp[k].w;             // `D-G12`：这一项以前读了不用
                    double ourXfl = rtl ? P - (ours[k, 0] + ours[k, 1]) : ours[k, 0];
                    double ourW = OurW(ours[k, 1]);
                    double d = Math.Abs(ourXfl - xfl);
                    // `D-G12` 的接线边界（**必须写清，否则会假红** —— 本件第一版就踩了，读数留档在报告里）：
                    //   · `char == "\t"` 已在上面 `continue` ⇒ **不参与**：真值里 tab 的 `width` 是
                    //     **网格推进量**（`tab-two-mid@w40@LTR` 实测 `\t` 宽 = 82.653333 = 96 − 13.346667），
                    //     **不是字形宽** ⇒ 拿它跟我们的 tab 区间比是**语义错配**（实测 19/22 条红全出在这）。
                    //   · `ourW == 0`（且 `have[k]`）⇒ 我们侧**根本没量到**（退化/零宽区间）⇒ 不是"测量值"，
                    //     按**不可判（NOINFO）**处理，**不报红也不报绿**（否则就是拿"没量到"当"量到 0"）。
                    //   · `k >= 我方行字符数` ⇒ 该真值字符**在我们侧不存在**（我方这一行**被截短**）
                    //     ⇒ 同上，计 `posTrunc`，**不误红**。
                    //   ⇒ 只有「非 tab ∧ `have[k]` ∧ 我方宽 ≠ 0 ∧ 该字符在我方行内」四个条件同时成立的字宽，
                    //     才是**真比较**，才进 `ok` 与 `posRedW`。
                    if (have[k])
                    {
                        bool ju = exp[k].ch != "\t" && ourW != 0.0;
                        if (ju)
                        {
                            if (Math.Abs(wTruth) > 0.05) ++wTruthCh;
                            double dW = Math.Abs(ourW - wTruth);
                            // 逐字宽用**与 `xFromLeftDip` 同一个** 0.05 容差（不是新发明的口径）
                            if (dW > 0.05)
                            {
                                ++posRedW; if (d > 0.05) ++posRedBoth;
                                if (dW > worstW) { worstW = dW; worstWWhy = "i=" + exp[k].i + " 字符[" + exp[k].ch + "] 字宽 期望=" + wTruth.ToString("F4") + " 实得=" + ourW.ToString("F4"); }
                            }
                            else if (d > 0.05) ++posRedX;
                            if (d > 0.05 || dW > 0.05) { ++posRedCmp; ++posRedTot; }
                            // 诊断分位（**不参与判据**）：字宽差到底是"几何缺陷"还是"字体度量舍入"
                            if (dW > 0.5) ++wNoise05; else if (dW > 0.1) ++wNoise01; else if (dW > 0.05) ++wNoise005; else if (dW > 0.02) ++wNoise002;
                        }
                        else
                        {
                            // 不可判的字宽（tab / 我方零宽）——**只计数、只诊断，不进红绿**
                            ++wSkip;
                            if (exp[k].ch == "\t") ++wSkipTab; else ++wSkipZero;
                            if (d > 0.05) { ++posRedNonCmp; ++posRedTot; }
                        }
                    }
                    else if (d > 0.05) { ++posRedNonCmp; ++posRedTot; }
                    if (d > worst) { worst = d; why = "i=" + exp[k].i + " 字符[" + exp[k].ch + "] 期望=" + xfl.ToString("F4") + " 实得=" + ourXfl.ToString("F4"); }
                }
                if (noBounds > 0) { NoBoundsTotal += noBounds; NoBoundsTab += noBoundsTab; }
                // 归因报告的触发条件：本件判据出红（`posRedW`）**或** 位置面出红（`worst > 0.05`，非本件造的红）
                if (posRedW > posRedWAtCaseStart || worst > 0.05)
                {
                    ++posRedCases;
                    // 【归因用】把**红字符所在的 k / i / 字符 / 真值宽 / 我方宽 / 是否可判**全部印出来
                    //   （**诊断，不入判据**）。`可判=` 是这一行能不能进 `ok` 的关键：
                    //   `tab` ⇒ 真值宽是网格推进量；`零宽` ⇒ 我们根本没量到；`无bounds` ⇒ 无测量；`可判` ⇒ 真比。
                    for (int q = 0; q < exp.Count; ++q)
                    {
                        double dq = have[q] ? Math.Abs((rtl ? P - (ours[q, 0] + ours[q, 1]) : ours[q, 0]) - exp[q].xfl) : double.NaN;
                        double dwq = have[q] ? Math.Abs(OurW(ours[q, 1]) - exp[q].w) : double.NaN;
                        string ju = !have[q] ? "无bounds"
                                  : exp[q].ch == "\t" ? "tab" : ours[q, 1] == 0.0 ? "零宽" : "可判";
                        // **与本件判据同一把尺子**：只有 `可判` 才可能因**宽**报红；
                        //   `tab`/`零宽`/`无bounds` 的宽**一律 NOINFO**，只有**位置**面能红（那是既有判据）。
                        bool redW = ju == "可判" && dwq > 0.05;
                        bool redX = dq > 0.05;
                        if (!redW && !redX) continue;
                        Console.WriteLine("  D-G12-RED " + id + " k=" + q + " i=" + exp[q].i
                                          + " 字符[" + exp[q].ch + "] 真值宽=" + exp[q].w.ToString("F6")
                                          + " 我方宽=" + OurW(ours[q, 1]).ToString("F6") + " Δ宽=" + dwq.ToString("F6")
                                          + " 位置Δ=" + dq.ToString("F6") + " 可判=" + ju
                                          + " 红面=" + (redW ? (redX ? "宽+位置" : "宽") : "位置(非本件)")
                                          + (q == exp.Count - 1 ? " 【末字符】" : ""));
                    }
                }
                if (worst > worstAll) { worstAll = worst; worstCase = id + " " + why; }
                bool ok = Math.Abs(P - expW) <= 0.01 && worst <= 0.01 && posRedCmp == 0;
                if (ok) ++pass;
                else if (shown++ < 8)
                    Console.WriteLine("  ❌ " + id + " 行宽 期望=" + expW.ToString("F4") + " 实得=" + P.ToString("F4")
                                      + "；最大逐字差=" + worst.ToString("F4") + "（" + why + "）"
                                      + (posRedTot > 0 ? "；`D-G12` 逐字宽红=" + posRedW + " 逐字位置红=" + posRedX + " 共红字符=" + posRedTot : ""));
            }
            int judgeable = total - BidiSkipped;           // 可判例数（**跳过的 57 例不算判据**）
            int fail = judgeable - pass;
            Console.WriteLine("TAB_ORACLE: cases=" + total + " pass=" + pass + " fail=" + fail
                              + "  跳过(bidi 依赖，纯拉丁+RTL 段落)=" + BidiSkipped
                              + "  无 GetTextBounds 的字符=" + NoBoundsTotal + "（其中 tab=" + NoBoundsTab + "，用邻居插值参与对拍）"
                              + "  最大逐字差=" + worstAll.ToString("F4") + " @" + worstCase);
            // ────── `#26` W26A · `D-G12` 的可归因读数（**只加不删**；上面那行的前缀逐字节未动）──────
            Console.WriteLine("TAB_ORACLE D-G12 逐字宽已接线 可判字宽字符(非tab且我方非零宽) 真值宽>0.05者=" + wTruthCh
                              + " 逐字宽红字符=" + posRedW + " 逐字位置红字符=" + posRedX + " 宽与位置都红=" + posRedBoth
                              + " 可判并集红字符=" + posRedCmp + " 不可判侧位置红字符=" + posRedNonCmp
                              + " 字宽不可判字符=" + wSkip + "（tab=" + wSkipTab + " 我方零宽=" + wSkipZero + "） 出红例数=" + posRedCases
                              + " 最大字宽差=" + worstW.ToString("F4") + " @" + worstWWhy
                              + " 字宽差分位(>0.5)=" + wNoise05 + " (>0.1)=" + wNoise01 + " (>0.05)=" + wNoise005 + " (>0.02)=" + wNoise002
                              + " 容差=0.05(与 xFromLeftDip 同口径) 口径=ok 追加 `posRedCmp==0`；不可判字宽一律 NOINFO 不计红绿");
            // ⚠️ 2026-09-14 修（T3 查出的仪器缺陷）：旧式 `pass == total ? 0 : 1` 里 `total` 含**按设计跳过**的
            //   57 例 ⇒ `57 != 114` ⇒ **构造性恒 rc=1**（内容其实是 pass=57/fail=0）。
            //   口径：**只有"可判例里的失败"才算红** ⇒ `fail == 0 ⇒ 0`；跳过的例不进判据（但仍在上面点名）。
            Console.WriteLine("TAB_ORACLE 退出码=" + (fail == 0 ? 0 : 1) + "（可判 " + judgeable + " = pass " + pass + " + fail " + fail
                              + "；跳过 " + BidiSkipped + " 不计）");
            return fail == 0 ? 0 : 1;
        }

        /// <summary>
        /// **只读诊断**：把"填宽实际用的 `adv[]`"与"`FormatLine` 交出去的 run advances"各打一行（同一串、同一配置）。
        /// 用途 = 判定"段落级 tab 间隔没透到测量侧"还是"透到了又被别处覆盖"。**不改 shim**（探针编译了 shim 源码 ⇒ 可直接调内部 API）。
        /// </summary>
        private static int RunTabDiag()
        {
            const string fontPath = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf";
            const string text = "a\tb\t\tc\td";        // layout-b34 的 tab 例句（逐字符一致）
            const double em = 16.0;                        // 该语料 fontSize=16 ⇒ 4×em = 64
            GlyphTypeface gt = null;
            Typeface tf = MakeTypeface("Liberation Sans");
            if (tf != null) tf.TryGetGlyphTypeface(out gt);
            Console.WriteLine("TAB_DIAG font=" + (gt != null ? gt.FontUri.LocalPath : "<失败>") + " em=" + em
                              + "  4×em=" + (4 * em));
            // ① 填宽来源：`LayoutText` 里 `MeasureChars(para, fontPath, emSize)` = HbShaper.Shape(...).CharAdvances()
            HbShapedRun r1 = HbShaper.Shape(fontPath, text, em);
            double[] fillAdv = r1.CharAdvances();
            Console.WriteLine("TAB_DIAG ① fill adv[]（HbShaper.Shape 直出，未再过任何 tab 处理）= ["
                              + string.Join(", ", Array.ConvertAll(fillAdv, v => v.ToString("F4"))) + "]");
            // ② 若按 0 配置重算（= 我们期望填宽看到的数组）
            HbShapedRun r2 = HbShaper.Shape(fontPath, text, em);
            HbShaper.ApplyTabStops(r2, text, IntPtr.Zero, 0, 0.0);
            double[] zeroAdv = r2.CharAdvances();
            Console.WriteLine("TAB_DIAG ② 若 tabInterval=0 重算 = ["
                              + string.Join(", ", Array.ConvertAll(zeroAdv, v => v.ToString("F4"))) + "]");
            Console.WriteLine("TAB_DIAG ③ 两者是否相同 = " + (string.Join(",", Array.ConvertAll(fillAdv, v => v.ToString("F4")))
                              == string.Join(",", Array.ConvertAll(zeroAdv, v => v.ToString("F4"))))
                              + "；①里 tab 那几格（下标 1/3/4/6）= " + fillAdv[1].ToString("F4") + " / " + fillAdv[3].ToString("F4")
                              + " / " + fillAdv[4].ToString("F4") + " / " + fillAdv[6].ToString("F4"));
            // ④ FormatLine 交出去的 run advances（= 真正画/记账用的那份），逐宽度
            foreach (double w in new double[] { 20, 40, 80, 150, 200 })
            {
                List<HbTextLine> lines; int consumed;
                try
                {
                    lines = HbTextLineFactory.FormatParagraph(text, fontPath, em, w, gt, 1.0f,
                                new HbRunProperties(tf, em, null), false, false, 0, out consumed,
                                defaultIncrementalTab: 0.0);
                }
                catch (Exception e) { Console.WriteLine("TAB_DIAG w=" + w + " 抛 " + e.GetType().Name); continue; }
                var sb = new StringBuilder();
                sb.Append("TAB_DIAG ④ w=").Append(w).Append(" 行数=").Append(lines.Count);
                for (int i = 0; i < lines.Count && i < 3; ++i)
                {
                    HbTextLine L = lines[i];
                    sb.Append(" | 行#").Append(i).Append(" Len=").Append(L.Length).Append(" w=").Append(L.Width.ToString("F4"));
                    foreach (GlyphRun g in L.GlyphRunsForRasterization)
                    {
                        sb.Append(" adv=[");
                        for (int k = 0; k < g.AdvanceWidths.Count; ++k)
                            sb.Append(k > 0 ? "," : "").Append(g.AdvanceWidths[k].ToString("F3"));
                        sb.Append(']');
                    }
                }
                Console.WriteLine(sb.ToString());
            }
            return 0;
        }

        /// <summary>
        /// **U1 `tab-zero` / `tab-rtl` 逐行对拍**（两套 JSON 结构相同：`lines[].perChar` + `incrementalTabArm` + `textWrapping`）。
        /// 比：行数 / 逐行 `Width`(0.05) / `TrailingWhitespaceLength` / `NewlineLength` / 逐字 `xFromLeftDip`(0.05，RTL 归一化 `P−右缘`)；
        /// 另报两问：**Q3** = "被钳满的 tab 是否铺满整行"（`lineText=="\t"` 且真值 `width==段落宽`）的命中数；
        /// **Q2** = RTL 下"到达的停靠位"是否为 tab 的**左边缘**（即 `P − 右缘` 落在网格上，U1 的 Q1 判据）。
        /// 装置自证用；**不是应用读数**。
        /// </summary>
        /// <summary>
        /// `--fallback-check`（`D-F1` 自验档）：单面路径排 `与`(U+4E0E，file 字体无覆盖 ⇒ 旧行为落 `.notdef` 9.6)
        /// 与零覆盖对照 `U+10FFFD`（两边都应落 `.notdef`）。打印：行宽 / 逐字 advance / `GetIndexedGlyphRuns()`
        /// 的（面 `FontUri`、`GlyphIndices`、`AdvanceWidths`）。判据：`与` ⇒ **Gid≠0 且 advance=16.0**（1 em）；
        /// `U+10FFFD` ⇒ 两边都 `.notdef`（完全可比档）。退出码：任一不符 ⇒ 1。
        /// </summary>
        private static string AdvList(IList<double> a)
        {
            var sb = new StringBuilder();
            for (int i = 0; i < a.Count; ++i) sb.Append(i > 0 ? "," : "").Append(a[i].ToString("F3"));
            return sb.ToString();
        }

        private static int RunFallbackCheck()
        {
            const string root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";
            const string fontPath = root + "/build/fonts/NotoSans-Regular.ttf";
            const double em = 16.0;
            GlyphTypeface gt = null; Typeface tf = MakeTypeface("Noto Sans");
            if (tf != null) tf.TryGetGlyphTypeface(out gt);
            if (gt == null) { try { gt = new GlyphTypeface(new Uri("file://" + fontPath)); } catch (Exception) { } }
            if (gt == null) { Console.WriteLine("FBCHK 字体解析失败"); return 2; }
            int bad = 0;
            // 反射 API 面自检：**非 DIRECT 分支**（`#else`）用的就是这两条反射调用 ⇒ 在这里证明它们在运行期可用。
            {
                var pi = typeof(GlyphTypeface).GetProperty("FaceIndex");
                int fi = (pi != null && pi.PropertyType == typeof(int) && gt != null) ? (int)pi.GetValue(gt) : -1;
                object made = null;
                try
                {
                    made = Activator.CreateInstance(typeof(IndexedGlyphRun),
                        System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.Public
                        | System.Reflection.BindingFlags.NonPublic, null,
                        new object[] { 0, 1, (object)null }, null);
                }
                catch (Exception e) { made = e.GetType().Name; }
                Console.WriteLine("FBCHK 反射面（非 DIRECT 分支用）：FaceIndex 属性=" + (pi != null ? pi.PropertyType.Name : "<无>")
                                  + " 取到 " + fi + "；IndexedGlyphRun 3 参构造反射=" + (made == null ? "null" : made.GetType().Name));
            }
            foreach (var probe in new[] { new object[] { "与 ", "U+4E0E", 16.0 }, new object[] { "\uDBFF\uDFFD ", "U+10FFFD", null } })
            {
                string text = (string)probe[0]; string tag = (string)probe[1]; double? want = (double?)probe[2];
                List<HbTextLine> lines; int consumed;
                try
                {
                    lines = HbTextLineFactory.FormatParagraph(text, fontPath, em, 1000.0, gt, 1.0f,
                                new HbRunProperties(tf, em, null), false, false, 0, out consumed);
                }
                catch (Exception e) { Console.WriteLine("FBCHK " + tag + " 抛 " + e.GetType().Name + "：" + e.Message); ++bad; continue; }
                HbTextLine L = lines[0];
                var sb = new StringBuilder();
                sb.Append("FBCHK ").Append(tag).Append(" 行宽=").Append(L.Width.ToString("F4"));
                IList<TextBounds> tb = null;
                try { tb = L.GetTextBounds(0, 1); } catch (Exception) { }
                double adv0 = (tb != null && tb.Count > 0 && tb[0].TextRunBounds.Count > 0) ? tb[0].TextRunBounds[0].Rectangle.Width : double.NaN;
                sb.Append(" 首字advance=").Append(adv0.ToString("F4"));
                var runs = new List<string>();
                foreach (IndexedGlyphRun igr in L.GetIndexedGlyphRuns())
                {
                    GlyphRun gr = igr.GlyphRun;
                    runs.Add("{" + igr.TextSourceCharacterIndex + "+" + igr.TextSourceLength + " face="
                             + (gr.GlyphTypeface != null ? System.IO.Path.GetFileName(gr.GlyphTypeface.FontUri.LocalPath) : "?")
                             + " gids=[" + string.Join(",", gr.GlyphIndices) + "] adv=["
                             + AdvList(gr.AdvanceWidths) + "]}");
                }
                sb.Append(" runs=").Append(runs.Count).Append(" ").Append(string.Join(" ", runs));
                Console.WriteLine(sb.ToString());
                if (want.HasValue)
                {
                    bool ok = !double.IsNaN(adv0) && Math.Abs(adv0 - want.Value) <= 0.05
                              && runs.Count > 0 && !runs[0].Contains("gids=[0");
                    Console.WriteLine("FBCHK " + tag + " 判据（Gid≠0 且 advance≈" + want.Value.ToString("F2") + "）⇒ " + (ok ? "PASS" : "FAIL"));
                    if (!ok) ++bad;
                }
            }
            Console.WriteLine("FBCHK 退出码=" + (bad == 0 ? 0 : 1) + "（不符 " + bad + "）");
            return bad == 0 ? 0 : 1;
        }

        /// <summary>
        /// `--modifier-rule-check <modifier-scope-oracle.json>`：**纯数据核验**（不排版、不依赖字体）——
        /// 把 U1 的判据拿**真值自己的三字段**算一遍，与用例级 `lineBreaks[].isNull` 逐行对拍：
        ///   `nonNull = !isLastLine && open ≥ 0 && open < endCharExclusive && (close < 0 || close ≥ endCharExclusive)`
        /// **为什么需要这一档**：臂 B 的真值面是 **Arial**（`fontSha256 baa25152…`，本机没有该字节）⇒ 它的
        /// 行宽/断行在本机**不可比**（§9.4(B) 同因）；**规则本身与字体无关**，可以纯数据核验 ✓。
        /// 退出码：`fail == 0 ⇒ 0`。
        /// </summary>
        private static int RunModifierRuleCheck(string path)
        {
            JsonDocument doc;
            try { doc = JsonDocument.Parse(File.ReadAllText(path)); }
            catch (Exception e) { Console.WriteLine("MODRULE 读档失败：" + e.GetType().Name + " " + e.Message); return 2; }
            if (!doc.RootElement.TryGetProperty("cases", out JsonElement casesEl) || casesEl.ValueKind != JsonValueKind.Array)
            { Console.WriteLine("MODRULE 形状不符：缺 cases 数组"); return 2; }
            var fam = new SortedDictionary<string, int[]>();
            int cases = 0, lines = 0, hit = 0, miss = 0, noLb = 0;
            foreach (JsonElement c in casesEl.EnumerateArray())
            {
                if (!c.TryGetProperty("lineBreaks", out JsonElement lbs) || lbs.ValueKind != JsonValueKind.Array) { ++noLb; continue; }
                ++cases;
                string group = c.TryGetProperty("group", out JsonElement ge) ? ge.GetString() : "?";
                if (!fam.TryGetValue(group, out int[] cnt)) { cnt = new int[2]; fam[group] = cnt; }
                int open = c.GetProperty("modifierOpenIndex").GetInt32();
                int close = c.GetProperty("modifierCloseIndex").GetInt32();
                var LB = new List<bool>();
                foreach (JsonElement b in lbs.EnumerateArray()) LB.Add(b.GetProperty("isNull").GetBoolean());
                int li = 0;
                foreach (JsonElement L in c.GetProperty("lines").EnumerateArray())
                {
                    if (li >= LB.Count) break;
                    int nx = L.GetProperty("endCharExclusive").GetInt32();
                    bool isLast = L.GetProperty("isLastLine").GetBoolean();
                    bool predNonNull = !isLast && open >= 0 && open < nx && (close < 0 || close >= nx);
                    bool truthNonNull = !LB[li];
                    ++lines; ++cnt[0];
                    if (predNonNull == truthNonNull) { ++hit; ++cnt[1]; }
                    else
                    {
                        ++miss;
                        if (miss <= 6)
                            Console.WriteLine("      ❌ " + c.GetProperty("id").GetString() + " 行#" + li
                                              + " 区间=[" + L.GetProperty("startChar").GetInt32() + "," + nx + ") isLast=" + isLast
                                              + " open=" + open + " close=" + close
                                              + " ⇒ 预测" + (predNonNull ? "非null" : "null") + "，真值" + (truthNonNull ? "非null" : "null"));
                    }
                    ++li;
                }
            }
            Console.WriteLine("MODRULE 用例=" + cases + "（无可核 lineBreaks 的 " + noLb + "）行=" + lines
                              + "｜判据吻合 " + hit + "/" + lines + "（不符 " + miss + "）");
            foreach (var kv in fam) Console.WriteLine("MODRULE   " + kv.Key.PadRight(20) + kv.Value[1] + "/" + kv.Value[0]);
            int fail = miss;
            Console.WriteLine("MODRULE 退出码=" + (fail == 0 ? 0 : 1) + "（不符 " + fail + "/" + lines + "）");
            return fail == 0 ? 0 : 1;
        }

        /// <summary>
        /// `--modifier-armB <modifier-scope-oracle.json>`：臂 B（U1 的 53 例）。
        /// **下标映射**（由 oracle 自身推出，不猜）：buffer 里 **两个标记**（`modifierOpenIndex` / `modifierCloseIndex`）
        /// 各占一个字符下标但**无字形无 advance**（`markers` 字段原文）⇒ 映射到可见文本：
        ///   `v(i) = i − #{m ∈ {open, close} : m ≥ 0 ∧ m < i}`；`modifierScopeCharRange` 同在 buffer 坐标 ⇒ 右端同样映射。
        /// 对拍：行数 + 逐行 `width` + 逐行 `isNull`（用例级 `lineBreaks[].isNull`）+ `trailingWhitespaceLength`/`newlineLength`。
        /// 装置自证用；**不改 shim 行为**。退出码：`fail == 0 ⇒ 0`。
        /// </summary>
        private static int RunModifierArmB(string path)
        {
            const string root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";
            const string fontPath = root + "/build/fonts/NotoSans-Regular.ttf";
            GlyphTypeface gt = null; Typeface tf = MakeTypeface("Noto Sans");
            if (tf != null) tf.TryGetGlyphTypeface(out gt);
            if (gt == null) { Console.WriteLine("MODB 字体解析失败"); return 2; }
            JsonDocument doc;
            try { doc = JsonDocument.Parse(File.ReadAllText(path)); }
            catch (Exception e) { Console.WriteLine("MODB 读档失败：" + e.GetType().Name + " " + e.Message + "（" + path + "）"); return 2; }
            if (!doc.RootElement.TryGetProperty("cases", out JsonElement casesEl) || casesEl.ValueKind != JsonValueKind.Array)
            { Console.WriteLine("MODB 形状不符：缺 cases 数组"); return 2; }
            var fam = new SortedDictionary<string, int[]>();
            int total = 0, okCase = 0, nLine = 0, okW = 0, okLb = 0, okWs = 0, okNl = 0;
            foreach (JsonElement c in casesEl.EnumerateArray())
            {
                if (!c.TryGetProperty("modifierScopeCharRange", out JsonElement scr) || scr.ValueKind != JsonValueKind.Array) continue;
                ++total;
                string id = c.GetProperty("id").GetString(), group = c.GetProperty("group").GetString();
                if (!fam.TryGetValue(group, out int[] cnt)) { cnt = new int[2]; fam[group] = cnt; }
                ++cnt[0];
                string text = c.GetProperty("visibleText").GetString();
                double em = c.GetProperty("emSizeDip").GetDouble(), w = c.GetProperty("paragraphWidthDip").GetDouble();
                double indent = c.TryGetProperty("indentDip", out JsonElement ie) ? ie.GetDouble() : 0.0;
                int open = c.GetProperty("modifierOpenIndex").GetInt32();
                int close = c.GetProperty("modifierCloseIndex").GetInt32();
                int sEndBuf = scr[1].GetInt32();
                int Map(int i) { if (i < 0) return -1; int n = 0; if (open >= 0 && open < i) ++n; if (close >= 0 && close < i) ++n; return i - n; }
                int openV = Map(open), endV = (scr[1].GetInt32() < 0 ? -1 : Map(sEndBuf)), closeV = Map(close);
                List<HbTextLine> lines; int consumed;
                try
                {
                    lines = HbTextLineFactory.FormatParagraph(text, fontPath, em, w, gt, 1.0f,
                                new HbRunProperties(tf, em, null), false, openV >= 0, 0, out consumed,
                                defaultIncrementalTab: 0.0, indentDip: indent,
                                modifierOpenIndex: openV, modifierScopeEnd: endV, modifierCloseIndex: closeV);
                }
                catch (Exception e) { Console.WriteLine("MODB " + id + " 抛 " + e.GetType().Name); continue; }
                JsonElement TL = c.GetProperty("lines");
                var lb = new List<bool>();
                if (c.TryGetProperty("lineBreaks", out JsonElement lbs) && lbs.ValueKind == JsonValueKind.Array)
                    foreach (JsonElement b in lbs.EnumerateArray()) lb.Add(b.GetProperty("isNull").GetBoolean());
                bool caseOk = lines.Count == TL.GetArrayLength();
                int li = 0;
                foreach (JsonElement E in TL.EnumerateArray())
                {
                    ++nLine;
                    double eW = E.GetProperty("width").GetDouble();
                    int eWs = E.GetProperty("trailingWhitespaceLength").GetInt32(), eNl = E.GetProperty("newlineLength").GetInt32();
                    bool eNull = li < lb.Count ? lb[li] : true;
                    if (li < lines.Count)
                    {
                        HbTextLine L = lines[li];
                        bool wOk = Math.Abs(L.Width - eW) <= 0.34, lbOk = (L.GetTextLineBreak() != null) == !eNull;
                        if (wOk) ++okW; if (lbOk) ++okLb;
                        if (L.TrailingWhitespaceLength == eWs) ++okWs;
                        if (L.NewlineLength == eNl) ++okNl;
                        if (!(wOk && lbOk)) caseOk = false;
                        if (caseOk == false && li < 2)
                            Console.WriteLine("      ❌ " + id + " 行#" + li + " 期望 w=" + eW.ToString("F4") + " isNull=" + eNull
                                              + " ｜ 实得 w=" + L.Width.ToString("F4") + " lineBreakNonnull=" + (L.GetTextLineBreak() != null));
                    }
                    ++li;
                }
                if (caseOk) { ++okCase; ++cnt[1]; }
            }
            Console.WriteLine("MODB 合计 用例=" + okCase + "/" + total + " 行=" + nLine
                              + "｜行宽≤0.34 " + okW + "/" + nLine + "｜lbNull " + okLb + "/" + nLine
                              + "｜ws " + okWs + "/" + nLine + "｜nl " + okNl + "/" + nLine);
            foreach (var kv in fam) Console.WriteLine("MODB   " + kv.Key.PadRight(20) + kv.Value[1] + "/" + kv.Value[0]);
            int fail = total - okCase;
            Console.WriteLine("MODB 退出码=" + (fail == 0 ? 0 : 1) + "（用例失败 " + fail + "/" + total + "）");
            return fail == 0 ? 0 : 1;
        }

        /// <summary>
        /// `--modifier-check`（#13 自验档）：读 `gen/layout-b34-compact.json` 的 `M_modifier_*` 用例，
        /// **显式传** `modifierOpenIndex`（b34 从不发 `TextEndOfSegment` ⇒ `modifierCloseIndex = -1`）与
        /// **不传**（= 旧行为）各排一遍，逐行对拍 `len/w/ws/witw/ext` 与 `lbNull`（= `GetTextLineBreak() != null`）。
        /// 装置自证用；**不改 shim 行为**。
        /// </summary>
        private static int RunModifierCheck()
        {
            const string root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";
            // ⚠️ 字体必须与真值/harness 一致（`Root + "/build/fonts"` Regular）：第一版我用 Liberation Sans
            //    ⇒ 行宽只剩 ~93%、Extent 16.91 vs 18.00 —— 那是**字体差**不是修法差（仪器口径错，已纠）。
            const string fontPath = root + "/build/fonts/NotoSans-Regular.ttf";
            GlyphTypeface gt = null; Typeface tf = MakeTypeface("Noto Sans");
            if (tf != null) tf.TryGetGlyphTypeface(out gt);
            if (gt == null) { Console.WriteLine("MODCHK 字体解析失败"); return 2; }
            JsonDocument cases, comp;
            try
            {
                cases = JsonDocument.Parse(File.ReadAllText(root + "/tests/parity/windows/layout-b34/cases.json"));
                comp = JsonDocument.Parse(File.ReadAllText(root + "/build/MilBridge/gen/layout-b34-compact.json"));
            }
            catch (Exception e) { Console.WriteLine("MODCHK 读档失败：" + e.GetType().Name + " " + e.Message); return 2; }
            var truth = new Dictionary<string, JsonElement>();
            foreach (JsonElement c in comp.RootElement.GetProperty("cases").EnumerateArray())
                truth[c.GetProperty("id").GetString()] = c;
            int nCase = 0, nLine = 0, okW = 0, okLen = 0, okWs = 0, okExt = 0, okLb = 0;
            var sum = new List<string>();
            foreach (JsonElement c in cases.RootElement.GetProperty("cases").EnumerateArray())
            {
                string id = c.GetProperty("id").GetString();
                if (!id.StartsWith("M_modifier", StringComparison.Ordinal)) continue;
                if (!truth.TryGetValue(id, out JsonElement T)) continue;
                ++nCase;
                string text = c.GetProperty("text").GetString();
                double em = c.GetProperty("fontSize").GetDouble(), w = c.GetProperty("maxWidth").GetDouble();
                bool hasMod = c.TryGetProperty("modifierStart", out JsonElement msEl) && msEl.ValueKind != JsonValueKind.Null;
                int ms = hasMod ? msEl.GetInt32() : -1;
                int me = (hasMod && c.TryGetProperty("modifierEnd", out JsonElement meEl) && meEl.ValueKind != JsonValueKind.Null)
                         ? meEl.GetInt32() : -1;
                foreach (bool useInterval in new[] { false, true })
                {
                    List<HbTextLine> lines; int consumed;
                    try
                    {
                        lines = HbTextLineFactory.FormatParagraph(text, fontPath, em, w, gt, 1.0f,
                                    new HbRunProperties(tf, em, null), false, hasMod, 0, out consumed,
                                    defaultIncrementalTab: 0.0,
                                    modifierOpenIndex: useInterval ? ms : -1,
                                    modifierScopeEnd: useInterval ? me : -1,      // b34：覆盖终点 = cases.json 的 modifierEnd（45）
                                    modifierCloseIndex: -1);                       // b34 从不发 TextEndOfSegment ⇒ -1
                    }
                    catch (Exception e) { Console.WriteLine("MODCHK " + id + " 抛 " + e.GetType().Name); continue; }
                    JsonElement TL = T.GetProperty("lines");
                    var sb = new StringBuilder();
                    sb.Append("MODCHK ").Append(id).Append(useInterval ? "  [传区间 open=" + ms + ",scopeEnd=" + me + ",close=-1]" : "  [不传区间=旧行为]")
                      .Append(" 行数 期望=").Append(TL.GetArrayLength()).Append(" 实得=").Append(lines.Count);
                    int li = 0;
                    foreach (JsonElement E in TL.EnumerateArray())
                    {
                        if (li >= lines.Count) break;
                        HbTextLine L = lines[li];
                        double eW = E.GetProperty("w").GetDouble(), eWi = E.GetProperty("witw").GetDouble();
                        int eLen = E.GetProperty("len").GetInt32(), eWs = E.GetProperty("ws").GetInt32();
                        double eExt = E.GetProperty("ext").GetDouble();
                        bool eLbNull = E.GetProperty("lbNull").GetBoolean();
                        bool ourLb = L.GetTextLineBreak() != null;
                        if (useInterval)
                        {
                            ++nLine;
                            if (Math.Abs(L.Width - eW) <= 0.34) ++okW;
                            if (L.Length == eLen) ++okLen;
                            if (L.TrailingWhitespaceLength == eWs) ++okWs;
                            if (Math.Abs(L.Extent - eExt) <= 0.34) ++okExt;
                            if (ourLb == !eLbNull) ++okLb;   // ⚠️ 首版写反过：`!=` ⇒ 计数的是"不匹配"数
                            if (li < 3)
                                sum.Add("     行#" + li + " 期望 len=" + eLen + " w=" + eW.ToString("F4") + " ws=" + eWs
                                        + " ext=" + eExt.ToString("F2") + " lbNull=" + eLbNull
                                        + " ｜ 实得 len=" + L.Length + " w=" + L.Width.ToString("F4") + " ws=" + L.TrailingWhitespaceLength
                                        + " ext=" + L.Extent.ToString("F2") + " lbNull=" + !ourLb);
                        }
                        else if (li == 0)
                            sb.Append(" ｜ 行#0 旧: w=").Append(L.Width.ToString("F4")).Append("（真值 ").Append(eW.ToString("F4")).Append("）");
                        ++li;
                    }
                    if (!useInterval) Console.WriteLine(sb.ToString());
                }
            }
            Console.WriteLine("MODCHK 合计 用例=" + nCase + " 行=" + nLine
                              + "｜行宽≤0.34 " + okW + "/" + nLine + "｜len " + okLen + "/" + nLine
                              + "｜ws " + okWs + "/" + nLine + "｜Extent " + okExt + "/" + nLine
                              + "｜lbNull " + okLb + "/" + nLine);
            foreach (string l in sum) Console.WriteLine(l);
            int failA = nLine - Math.Min(Math.Min(okW, okLen), Math.Min(okWs, okLb));   // 任一列不过 ⇒ 该行算失败
            Console.WriteLine("MODCHK 退出码=" + (failA == 0 ? 0 : 1) + "（行失败 " + failA + "/" + nLine + "）");
            return failA == 0 ? 0 : 1;
        }

        /// <summary>
        /// `--shape &lt;字体路径&gt; &lt;文本&gt;`：把该文本交给**这份 shim 自己的** `HbShaper.Shape`，逐码元打印
        /// advance + 该面的 **nominal glyph**（`HbShaper.NominalGlyph`，= cmap 直读，不带 GSUB）。
        /// 用途 = 判断"真值用的面"在我们这边**有没有字形**、advance 差多少（= 字体口径差异的证据，而不是猜）。
        /// 装置自证用；**不改 shim、不改行为**。
        /// </summary>
        private static int RunShapeProbe(string fontPath, string text)
        {
            double em = 24.0;
            Console.WriteLine("SHAPE 文件=" + fontPath + " em=" + em.ToString("F1"));
            Console.WriteLine("SHAPE 文本=" + string.Join(" ", Array.ConvertAll(text.ToCharArray(),
                              ch => "U+" + ((int)ch).ToString("X4"))));
            var sb = new StringBuilder("SHAPE nominal glyph（cmap 直读，0=缺字形）:");
            for (int k = 0; k < text.Length; ++k)
            {
                int g = HbShaper.NominalGlyph(fontPath, 0, text[k]);
                sb.Append(" [").Append(k).Append("]U+").Append(((int)text[k]).ToString("X4")).Append("→").Append(g);
            }
            Console.WriteLine(sb.ToString());
            double[] adv;
            try { adv = HbShaper.Shape(fontPath, text, em).CharAdvances(); }
            catch (Exception e) { Console.WriteLine("SHAPE 整形抛 " + e.GetType().Name + ": " + e.Message); return 2; }
            var sa = new StringBuilder("SHAPE adv[]=");
            for (int k = 0; k < adv.Length; ++k) sa.Append(k > 0 ? ", " : "").Append("U+")
                .Append(k < text.Length ? ((int)text[k]).ToString("X4") : "??").Append(":").Append(adv[k].ToString("F6"));
            Console.WriteLine(sa.ToString());
            double sum = 0; foreach (double v in adv) sum += v;
            Console.WriteLine("SHAPE 合计宽=" + sum.ToString("F6") + "（" + adv.Length + " 格）");
            return 0;
        }


        /// <summary>
        /// 【W29E草稿 · `D-G26`】读构建时嵌入的「本二进制所编译的那份 `Program.cs` 的内容 sha256」。
        /// 取不到 ⇒ 返回字面量 `NOINFO`（**不许**回退到"读现场源文件" —— 那会让旧 dll 冒充新源，
        /// 是**假绿**；理由见 `HbTextLineShimSha.targets:11-13`：判据必须与 mtime/现场状态无关）。
        /// </summary>
        private static string ProbeSourceSha()
        {
            try
            {
                foreach (object o in typeof(Program).Assembly.GetCustomAttributes(
                             typeof(System.Reflection.AssemblyMetadataAttribute), false))
                {
                    var m = (System.Reflection.AssemblyMetadataAttribute)o;
                    if (m.Key == "CoverageProbeSourceSha") return m.Value;
                }
            }
            catch (Exception) { }
            return "NOINFO";
        }

        private static int RunTabLinesOracle(string path, string knownRedPath)
        {
            // 【W29E草稿 · `D-G26`】**自报本探针的身份**（见 `ProbeIdentity.targets`）。
            //   打在**最前面**（早于形状自检/读档失败）⇒ 自检失败的那一档也认得出是谁打的。
            Console.WriteLine("TAB_LINES_PROBE sha256=" + ProbeSourceSha()
                              + " path=build/MilBridge/tests/CoverageProbe/Program.cs");
            // #12(d)：**形状自检**（本档只吃"逐行 perChar"结构：tab-zero / tab-rtl / tab-anchor）。
            //   喂 `tab` 臂的逐例结构会在取 `lines` 时抛 KeyNotFoundException，未捕获 ⇒ 进程异常终止（T3 亲测 core）。
            //   ⇒ 先校验形状、缺哪个键就报哪个键，并给"该用哪个档"的提示，**不崩**。
            try
            {
                using JsonDocument probeDoc = JsonDocument.Parse(File.ReadAllText(path));
                string shapeErr = TabLinesShapeError(probeDoc);
                if (shapeErr != null)
                {
                    Console.WriteLine("TAB_LINES 形状不符：" + shapeErr);
                    Console.WriteLine("TAB_LINES 本档只吃**逐行 perChar** 结构（cases[].lines[].perChar[]，如 tests/parity/windows/tab-zero/out/*.json）；"
                                      + "`tab` 臂那种**逐例 perChar** 结构请用 `--tab-oracle <json>`。");
                    return 2;
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("TAB_LINES 读档失败：" + e.GetType().Name + ": " + e.Message + "（路径=" + path + "）");
                return 2;
            }
            var kr = LoadKnownRed(knownRedPath);
            var failures = new List<string[]>();     // [id, 原因]
            const string fontPath = "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf";
            GlyphTypeface gt = null; Typeface tf = MakeTypeface("Liberation Sans");
            if (tf != null) tf.TryGetGlyphTypeface(out gt);
            if (gt == null) { try { gt = new GlyphTypeface(new Uri("file://" + fontPath)); } catch (Exception) { } }
            if (gt == null) { Console.WriteLine("TAB_LINES 字体解析失败"); return 2; }
            var doc = JsonDocument.Parse(File.ReadAllText(path));
            var fam = new SortedDictionary<string, int[]>();      // [总例, 结构过]
            var famPos = new SortedDictionary<string, int[]>();   // [位置可比, 位置过]
            int total = 0, pass = 0, skipCov = 0, bidiCases = 0;
            int clampHit = 0, clampTot = 0, q2TruthHit = 0, q2TruthTot = 0, q2OurHit = 0, q2OurTot = 0;
            var miss = new Dictionary<int, int>();
            double worst = 0; string worstWhy = "";
            // ══════════ `#22` P2 / `D-G1`：把 `TextLine.Start` 接进本臂（**只新增一列**）══════════
            // 【为什么】`D-T6-c`（`Start => 0`，与真机法律相反）能长期存活的**结构性原因**是：
            //   本臂（= 门禁三支 tab 臂的宿主）对 `lineStartOffsetsDip` / `TextLine.Start` **零引用**
            //   ⇒ 语料里 615 个真值（171 行非零）从来没进过门禁的射程。
            // 【口径】真机法律（`#21` 三条独立证据）= **`Start ≡ ParagraphIndent`**（`TextAlignment=Left`）。
            //   本列：逐行 `R(我方 line.Start)` vs 语料 `case.lineStartOffsetsDip[k]`，**精确相等**；
            //   `R(v) = Math.Round(v, 6, MidpointRounding.AwayFromZero)`，口径出处 =
            //   `tests/parity/windows/tab-anchor/src/Program.cs:583`（真机臂 `:445` 的 `lineIndents.Add(R(line.Start))`
            //   就是本字段的产地）。
            // 【只许加强】既有列/分桶/汇总**一个字节未动**；本列**能决定红**（差 ⇒ 计入 `failures` ⇒ 影响 rc）。
            // 【覆盖边界】**只对 `TextAlignment=Left` 断言**（语料头 `paragraphProperties.fixed` 钉死）；
            //   其他对齐 ⇒ 逐行 **NOINFO**，**不发明公式**。
            // 【不印的条件】语料里**根本没有** `lineStartOffsetsDip` 的档（tab-zero / tab-rtl）⇒ **一行都不印**
            //   ⇒ 它们在本仪器上的日志**逐字节不变**（本波硬要求）。
            string startAlign = StartAlignmentOf(doc.RootElement);
            bool startField = false;
            foreach (JsonElement cs0 in doc.RootElement.GetProperty("cases").EnumerateArray())
                if (StartTruthCount(cs0) > 0) { startField = true; break; }
            bool startAssert = startField && startAlign == "Left";
            int stRed = 0, stGreen = 0, stJudge = 0, stNoinfo = 0, stRedCases = 0;
            // 【W25I 列级闸·新增】stGlyphReleased = 被缺字形闸放行、且真的判过的真值行数；
            //   stNzJudge = 该列里真值非零且被真正判过的行数（既有 latin 路径 + 新增释放路径两处累加）。
            //   本列没有「因字形 NOINFO」这种东西（构造性）⇒ 汇总行把它写死成 0，不用计数器。
            int stGlyphReleased = 0, stNzJudge = 0;
            int stSumRed = 0, stSumGreen = 0, stSumNoinfo = 0, stNoinfoCases = 0;
            var stRedDetails = new List<string[]>();
            string stNoinfoWhy = startAssert ? null : ("对齐非Left(" + startAlign + ")");
            // ══════════ `#24` P3：把 `TextLine.HasOverflowed` 接进本臂（**只新增一列**，照 `#22` P2 的 `Start` 列形态）══════════
            // 【为什么】`D-O1`（`#16`）刚把 `HasOverflowed` 从"恒假"改成**三分支真实现**，而**本臂对它零引用**
            //   —— 语料 `tab-anchor-oracle.json` 里 **615/615 行有真值**，其中 **22 行为 `true`（8 例）**，
            //   **全部落在 `script==latin` 的可判定集内**（`B-indent-extra` × `i24p24` × `w40`）。
            // 【口径】逐行 `我方 line.HasOverflowed` vs 语料 `cases[].lines[].hasOverflowed`，**布尔全等**（**无容差**）。
            //   实现（`build/shims/PresentationCore.HbTextLine.cs` 的 `public override bool HasOverflowed`）= 三分支：
            //     ① `!(_paragraphWidth > 0)` ⇒ `false`（旧调用点，无段落宽）；② `_startPenX >= _paragraphWidth` ⇒ `true`；
            //     ③ **严格** `_boxOriginX + _width > _paragraphWidth + 1e-9` ⇒ `true`（**恰好到达边缘 ⇒ `false`**）。
            //   ⇒ 本列**只断言等值**，**不许**在臂侧另发明容差；**"严格 `>`"的语义在此写死**：
            //     把 ③ 改成 `>=` ⇒ 语料里"恰好到达边缘、余量恰为 0"的**发丝边界行**会翻面（真值说 `false`）。
            //     ⚠️ 那个风险带**不由本列判定**，只由下面的 `诊断发丝边界行=` **计数**（诊断值不参与任何红/绿）。
            // 【只许加强】既有列/分桶/汇总**一个字节未动**；本列**能决定红**（不等 ⇒ 计入 `failures` ⇒ 影响 rc）。
            // 【覆盖边界】**只对 `TextAlignment=Left` 断言**（语料头 `paragraphProperties.fixed` 钉死）；
            //   取不到对齐 / 其他对齐 ⇒ 逐行 **NOINFO**，**不发明公式**（`tab-zero`/`tab-rtl` 两份语料**没有**
            //   `paragraphProperties` 段 ⇒ 它们会印出一族 `NOINFO=对齐非Left(NOINFO)`，**那不是绿**）。
            // 【分母（纪律 39）】可判定集 = `script==latin` 的 **288 例 / 421 行**（全域是 436 例 / 615 行）；
            //   二者的差 = 既有覆盖闸（面缺字形）挡下的 148 例，与本列口径无关、**一个字节未动**。
            string overAlign = StartAlignmentOf(doc.RootElement);   // 同一条对齐法律（`TextAlignment`），非新口径
            bool overField = false;
            foreach (JsonElement cs1 in doc.RootElement.GetProperty("cases").EnumerateArray())
                if (OverTruthCount(cs1) > 0) { overField = true; break; }
            bool overAssert = overField && overAlign == "Left";
            int ovRed = 0, ovGreen = 0, ovJudge = 0, ovNoinfo = 0, ovRedCases = 0, ovNoinfoCases = 0, ovTrue = 0, ovEdge = 0;
            // 【W25I 列级闸·新增】本列依赖字形 ⇒ 它在缺字形例上的 NOINFO 必须能与「字形以外」分开数。
            int ovNoinfoGlyph = 0;
            int ovSumRed = 0, ovSumGreen = 0, ovSumNoinfo = 0;
            var ovRedDetails = new List<string[]>();
            string ovNoinfoWhy = overAssert ? null : ("对齐非Left(" + overAlign + ")");
            foreach (JsonElement c in doc.RootElement.GetProperty("cases").EnumerateArray())
            {
                ++total;
                string id = c.GetProperty("id").GetString();
                string family = id.Split('@')[0];
                if (!fam.TryGetValue(family, out int[] cnt)) { cnt = new int[2]; fam[family] = cnt; }
                ++cnt[0];
                string text = c.GetProperty("text").GetString();
                double pw = c.GetProperty("paragraphWidthDip").GetDouble();
                double em = c.GetProperty("emSizeDip").GetDouble();
                bool rtl = string.Equals(c.GetProperty("flowDirection").GetString(), "RightToLeft", StringComparison.Ordinal);
                bool wrap = !string.Equals(c.GetProperty("textWrapping").GetString(), "NoWrap", StringComparison.Ordinal);
                bool arm0 = c.GetProperty("incrementalTabArm").GetString().IndexOf("=0", StringComparison.Ordinal) >= 0;
                // 【主控 2026-09-15 修：**本臂从未把 oracle 的缩进喂下去** ⇒ 208 例结构性不可比】
                //   实测：oracle 的 `indentDip`/`paragraphIndentDip` 非 0 的用例 = B-indent 144 + B-indent-extra 72
                //   + D-paraindent 64 中的 208 条；而本方法（`--tab-lines-oracle` = 门禁的三支 tab 臂）
                //   **整段 `:1296–1347` 一次 `indent` 都没有**（`grep -c 'indent'` = 0）⇒ 恒取默认 0
                //   ⇒ 真值"每行 x=24 / 行宽=24+内容宽"与我们"x=0 / 行宽=内容宽"**必然**对不上 ⇒
                //   **任何 shim 改动都改不绿这 208 条**（已知红 174 条是它的子集）。
                //   ⇒ 修法 = 按 oracle 原值喂（与 `RunTabOracle` 里 `indentDip: indent` 同法）。
                double indentDipCase = c.TryGetProperty("indentDip", out JsonElement ide) ? ide.GetDouble() : 0.0;
                double paraIndentCase = c.TryGetProperty("paragraphIndentDip", out JsonElement pie) ? pie.GetDouble() : 0.0;
                // ⚠️ 覆盖闸：真值的面 = Arial（sha baa2515…，覆盖希伯来/阿拉伯），本机**没有那份字节**；
                //   缺字形时 HarfBuzz 拿 `.notdef` 顶上（实测 8.765625@em24）⇒ 与真值逐字符不可比。
                int missing = 0;
                foreach (char ch in text)
                {
                    if (ch == '\t' || ch == '\n' || ch == '\r') continue;   // 真值口径：tab 是控制字符，不算覆盖
                    if (!miss.TryGetValue(ch, out int g)) { g = HbShaper.NominalGlyph(fontPath, 0, ch); miss[ch] = g; }
                    if (g == 0) ++missing;
                }
                JsonElement exp = c.GetProperty("lines");
                if (missing > 0)
                {
                    ++skipCov;
                    // 【W25I 列级闸】本行**逐字未动**（`skipCov` 计数、日志字节、`合计` 行全不变）。
                    //   语义澄清：它现在说的是「**结构列 / 位置列**跳过」，**不是**「整例一个字段都不判」；
                    //   与字形无关的列（`Start`）在本块内单独判（见下）。
                    Console.WriteLine("TAB_LINES CASE " + id + " 臂=" + (rtl ? "RTL" : "LTR") + " 跳过=面缺字形" + missing);
                    // ══════ W25I · 列级闸：`Start` 列**与字形无关** ⇒ 该例照样判 ══════
                    // 【三条独立证据（可复算；详见 $HOME/w25i/report.md §3）】
                    //   ① 真值侧：`lineStartOffsetsDip[k] == R6(paragraphIndentDip)` 在本语料 **615/615 行**上成立
                    //      （**含本闸挡下的全部 194 行**；反例 0）⇒ 真值里**没有字形量**。
                    //   ② 我方侧：`TextLine.Start`（shim `PresentationCore.HbTextLine.cs:3484`
                    //      `public override double Start => _paragraphIndentDip;`）只读本文件 `:1410` 传下去的
                    //      `paragraphIndentDip: paraIndentCase`（`:1364`，语料原值）⇒ **也不经字形**。
                    //   ③ 集合不相交：本闸命中 148 例，`script ∈ {hebrew 116, arabic 32}`，**latin 288 例 0 命中**
                    //      ⇒ 本块新建的判定与既有 421 行判定**没有一行交集**（"只许加严"的结构性保证）。
                    // 【为什么必须真格式化一次】不格式化、直接拿 `paragraphIndentDip` 自比 = **同义反复 = 假判据**
                    //   （它永远抓不到 `Start` 接线错，例如 `D-T6-c` 那个 `Start => 0`）⇒ 本块**真调**
                    //   `FormatParagraph`、真读 `line.Start`；**取不到读数就 NOINFO，绝不绿**。
                    // 【仍然 NOINFO 的】`HasOverflowed`（我方量经 `_width` ⇒ 依赖字形）、结构列、位置列。
                    if (startField)
                    {
                        int nT = StartTruthCount(c);
                        if (!startAssert)
                        {   // 对齐非 Left ⇒ 不发明公式：整列 NOINFO（**本语料不触发**：`fixed` 钉死 Left）
                            stNoinfo += nT; stSumNoinfo += nT; ++stNoinfoCases;
                            Console.WriteLine("TAB_LINES START " + id + " 行=" + nT + " NOINFO=" + stNoinfoWhy);
                        }
                        else
                        {
                            List<HbTextLine> gl = null; string gwhy = null;
                            try
                            {
                                int gconsumed;
                                gl = HbTextLineFactory.FormatParagraph(text, fontPath, em, pw, gt, 1.0f,
                                        new HbRunProperties(tf, em, null), false, false, 0, out gconsumed,
                                        defaultIncrementalTab: arm0 ? 0.0 : double.NaN, wrap: wrap,
                                        indentDip: indentDipCase, paragraphIndentDip: paraIndentCase);
                            }
                            catch (Exception ge) { gwhy = "格式化抛" + ge.GetType().Name; }
                            if (gl == null)
                            {   // 真格式化了但没拿到行 ⇒ NOINFO（**不是绿**）
                                stNoinfo += nT; stSumNoinfo += nT; ++stNoinfoCases;
                                Console.WriteLine("TAB_LINES START " + id + " 行=" + nT + " NOINFO=" + gwhy);
                            }
                            else
                            {
                                JsonElement lsd = c.GetProperty("lineStartOffsetsDip");
                                int gcommon = Math.Min(gl.Count, nT);
                                int gr = 0, gg = 0, gni = 0;
                                var gdet = new List<string>();
                                for (int k = 0; k < nT; ++k)
                                {
                                    // 行数不符 = 字形**以外**的原因 ⇒ NOINFO，**绝不误红**
                                    if (k >= gcommon)
                                    { ++gni; gdet.Add("行#" + k + " NOINFO=行数不符(真值行=" + nT + " 我方行=" + gl.Count + ")"); continue; }
                                    double gtruth = lsd[k].GetDouble();
                                    double gours = R6(gl[k].Start);
                                    if (gours != gtruth)
                                    { ++gr; gdet.Add("行#" + k + " Start 期望=" + gtruth.ToString("F6", CultureInfo.InvariantCulture)
                                                     + " 实得=" + gours.ToString("F6", CultureInfo.InvariantCulture)
                                                     + " Δ=" + (gours - gtruth).ToString("F6", CultureInfo.InvariantCulture)); }
                                    else ++gg;
                                    if (gtruth != 0) ++stNzJudge;
                                }
                                stRed += gr; stGreen += gg; stJudge += gr + gg; stNoinfo += gni;
                                stSumRed += gr; stSumGreen += gg; stSumNoinfo += gni;
                                stGlyphReleased += gr + gg;
                                if (gr > 0)
                                {
                                    ++stRedCases;
                                    foreach (string t in gdet) Console.WriteLine("TAB_LINES START-RED " + id + " " + t);
                                    stRedDetails.Add(new[] { id, string.Join("；", gdet) });
                                }
                                Console.WriteLine("TAB_LINES START " + id + " 行=" + nT + " 红=" + gr + " 绿=" + gg
                                                  + (gni > 0 ? " NOINFO=" + gni : ""));
                            }
                        }
                    }
                    if (overField)   // `#24` P3：本列**依赖字形**（我方量经 `_width`）⇒ 继续 NOINFO，**不许当绿**
                    { int n0 = OverTruthCount(c); ovNoinfo += n0; ovSumNoinfo += n0; ++ovNoinfoCases;
                      ovNoinfoGlyph += n0;   // W25I：显式标出"这一份 NOINFO 是**字形**造成的"
                      Console.WriteLine("TAB_LINES OVERFLOWED " + id + " 行=" + n0 + " NOINFO=面缺字形(本列依赖字形)" + missing); }
                    continue;
                }
                // bidi 判据：真值 `xFromLeftDip` 随 i **单调不减** ⇒ 视觉序 == 逻辑序（UBA 未重排），位置可比；
                //   否则真值把整行按 UBA 重排（ICU 复核：`a\tb` 段落 RTL ⇒ 级别 [2,1,2]、视觉序 [2,1,0]），
                //   而我们是**单 run LTR**（§8.7 已登记）⇒ 位置量不可比，只比结构量。
                bool reordered = false;
                foreach (JsonElement E0 in exp.EnumerateArray())
                {
                    double prev = double.NegativeInfinity;
                    foreach (JsonElement pc0 in E0.GetProperty("perChar").EnumerateArray())
                    {
                        double xf = pc0.GetProperty("xFromLeftDip").GetDouble();
                        if (xf + 0.05 < prev) reordered = true;
                        prev = xf;
                    }
                }
                if (reordered) ++bidiCases;
                if (!famPos.TryGetValue(family, out int[] pc2)) { pc2 = new int[2]; famPos[family] = pc2; }
                if (!reordered) ++pc2[0];
                List<HbTextLine> lines; int consumed;
                try
                {
                    lines = HbTextLineFactory.FormatParagraph(text, fontPath, em, pw, gt, 1.0f,
                                new HbRunProperties(tf, em, null), false, false, 0, out consumed,
                                defaultIncrementalTab: arm0 ? 0.0 : double.NaN, wrap: wrap,
                                indentDip: indentDipCase, paragraphIndentDip: paraIndentCase);
                }
                catch (Exception e)
                {
                    Console.WriteLine("TAB_LINES CASE " + id + " 抛 " + e.GetType().Name);
                    if (startField)   // `#22` P2：抛了 ⇒ 真值行**未判**（NOINFO），不许当绿
                    { int n0 = StartTruthCount(c); stNoinfo += n0; stSumNoinfo += n0; ++stNoinfoCases;
                      Console.WriteLine("TAB_LINES START " + id + " 行=" + n0 + " NOINFO=格式化抛" + e.GetType().Name); }
                    if (overField)   // `#24` P3：抛了 ⇒ 真值行**未判**（NOINFO），不许当绿
                    { int n0 = OverTruthCount(c); ovNoinfo += n0; ovSumNoinfo += n0; ++ovNoinfoCases;
                      Console.WriteLine("TAB_LINES OVERFLOWED " + id + " 行=" + n0 + " NOINFO=格式化抛" + e.GetType().Name); }
                    continue;
                }
                bool structOk = lines.Count == exp.GetArrayLength(), posOk = true;
                string why = structOk ? null : ("行数 期望=" + exp.GetArrayLength() + " 实得=" + lines.Count);
                bool dumped = false;
                if (structOk)
                {
                    int li = 0;
                    foreach (JsonElement E in exp.EnumerateArray())
                    {
                        HbTextLine L = lines[li++];
                        double eW = E.GetProperty("width").GetDouble();
                        double dW = Math.Abs(L.Width - eW);
                        if (dW > 0.05) { structOk = false; if (why == null) why = "行#" + (li - 1) + " 行宽 期望=" + eW.ToString("F4") + " 实得=" + L.Width.ToString("F4"); if (dW > worst) { worst = dW; worstWhy = id + " 行#" + (li - 1) + " 行宽 期望=" + eW.ToString("F4") + " 实得=" + L.Width.ToString("F4"); } }
                        if (L.TrailingWhitespaceLength != E.GetProperty("trailingWhitespaceLength").GetInt32())
                        { structOk = false; if (why == null) why = "行#" + (li - 1) + " 尾部空白 期望=" + E.GetProperty("trailingWhitespaceLength").GetInt32() + " 实得=" + L.TrailingWhitespaceLength; }
                        if (L.NewlineLength != E.GetProperty("newlineLength").GetInt32())
                        { structOk = false; if (why == null) why = "行#" + (li - 1) + " 换行长 期望=" + E.GetProperty("newlineLength").GetInt32() + " 实得=" + L.NewlineLength; }
                        double P = L.Width;
                        foreach (JsonElement pc in E.GetProperty("perChar").EnumerateArray())
                        {
                            int i = pc.GetProperty("i").GetInt32();
                            double xfl = pc.GetProperty("xFromLeftDip").GetDouble();
                            string chs = pc.GetProperty("char").GetString();
                            if (chs == "\t")
                            {
                                // Q3：真值里"被钳满"的 tab = 该行唯一字符且行宽 == 段落宽
                                if (E.GetProperty("lineText").GetString() == "\t" && Math.Abs(eW - pw) <= 0.05)
                                {
                                    ++clampTot;
                                    if (!reordered)
                                    {
                                        try { IList<TextBounds> t3 = L.GetTextBounds(i, 1); if (t3 != null && t3.Count > 0 && t3[0].TextRunBounds.Count > 0 && Math.Abs(t3[0].TextRunBounds[0].Rectangle.Width - pw) <= 0.05) ++clampHit; }
                                        catch (Exception) { }
                                    }
                                    else ++clampHit;      // 重排例的位置量不可比，但"行宽 == 段落宽"已在结构量里比过
                                }
                                // Q2/Q1（U1）：RTL 下到达的停靠位 = tab 的**左缘**，自**本行右缘**量应落在网格倍数上；
                                //   真值侧用真值自己的 xFromLeftDip（不依赖我们），我方侧用我们的视觉左。
                                if (rtl && !arm0)
                                {
                                    double interval = 4 * em;
                                    ++q2TruthTot;
                                    double q2q = (P - xfl) / interval;
                                    Console.WriteLine("TAB_LINES Q2 " + id + " 行#" + (li - 1) + " 行宽=" + P.ToString("F4")
                                                      + " tab左xfl=" + xfl.ToString("F4") + " P-xfl=" + (P - xfl).ToString("F4")
                                                      + " 间隔=" + interval.ToString("F1") + " 商=" + q2q.ToString("F6"));
                                    if (Math.Abs(q2q - Math.Round(q2q)) < 1e-3) ++q2TruthHit;
                                    if (!reordered)
                                    {
                                        try
                                        {
                                            IList<TextBounds> t2 = L.GetTextBounds(i, 1);
                                            if (t2 != null && t2.Count > 0 && t2[0].TextRunBounds.Count > 0)
                                            {
                                                double myLeft = t2[0].TextRunBounds[0].Rectangle.X;
                                                ++q2OurTot;
                                                if (Math.Abs((L.Width - myLeft) / interval - Math.Round((L.Width - myLeft) / interval)) < 1e-3) ++q2OurHit;
                                            }
                                        }
                                        catch (Exception) { }
                                    }
                                }
                                continue;
                            }
                            if (reordered) continue;
                            IList<TextBounds> tb = null;
                            try { tb = L.GetTextBounds(i, 1); } catch (Exception) { }
                            if (tb == null || tb.Count == 0 || tb[0].TextRunBounds == null || tb[0].TextRunBounds.Count == 0)
                            { posOk = false; if (why == null) why = "行#" + (li - 1) + " i=" + i + " 取不到字符边界"; continue; }
                            // 口径（2026-09-14 实测复核）：真值 `xFromLeftDip` = **本行视觉左**，`x` 是它的镜像
                            //   （`x = L − xfl − w`，四例逐字符验证）；我们 `Rectangle.X` 也是视觉左 ⇒ 直接比。
                            double ourXfl = tb[0].TextRunBounds[0].Rectangle.X;
                            double d = Math.Abs(ourXfl - xfl);
                            if (d > 0.05) { posOk = false; if (why == null) why = "行#" + (li - 1) + " i=" + i + " xFromLeft 期望=" + xfl.ToString("F4") + " 实得=" + ourXfl.ToString("F4"); if (d > worst) { worst = d; worstWhy = id + " 行#" + (li - 1) + " i=" + i + " xFromLeft 期望=" + xfl.ToString("F4") + " 实得=" + ourXfl.ToString("F4"); } }
                        }
                    }
                }
                else
                {
                    var sb = new StringBuilder("行数 期望=" + exp.GetArrayLength() + " 实得=" + lines.Count + "；真值行=");
                    int k = 0;
                    foreach (JsonElement E in exp.EnumerateArray())
                        sb.Append(k++ > 0 ? " | " : "").Append("[").Append(E.GetProperty("lineText").GetString())
                          .Append("]w=").Append(E.GetProperty("width").GetDouble().ToString("F2"));
                    sb.Append("；我方行=");
                    for (int q = 0; q < lines.Count; ++q)
                        sb.Append(q > 0 ? " | " : "").Append("[len=").Append(lines[q].Length).Append(",tws=")
                          .Append(lines[q].TrailingWhitespaceLength).Append(",nl=").Append(lines[q].NewlineLength)
                          .Append("]w=").Append(lines[q].Width.ToString("F2"));
                    Console.WriteLine("TAB_LINES FAILCASE " + id + " :: " + sb.ToString());
                    dumped = true;
                }
                bool oneCase = structOk && (reordered || posOk);
                if (structOk) ++cnt[1];
                if (!reordered && posOk && structOk) ++pc2[1];
                if (oneCase) ++pass;
                Console.WriteLine("TAB_LINES CASE " + id + " 臂=" + (rtl ? "RTL" : "LTR") + " wrap=" + (wrap ? 1 : 0)
                                  + " 结构=" + (structOk ? "PASS" : "FAIL")
                                  + " 位置=" + (reordered ? "跳过(bidi 重排)" : (posOk ? "PASS" : "FAIL")));
                if (!oneCase)
                {
                    string reason = why ?? (structOk ? "位置量不一致" : "结构量不一致");
                    failures.Add(new[] { id, reason });
                    if (!dumped) Console.WriteLine("TAB_LINES FAILCASE " + id + " :: " + reason);
                }
                // ────── `#22` P2：`Start` 列（新增；只在语料带 `lineStartOffsetsDip` 时印）──────
                if (startField)
                {
                    int nT = StartTruthCount(c);
                    if (!startAssert)
                    {
                        stNoinfo += nT; stSumNoinfo += nT; ++stNoinfoCases;
                        Console.WriteLine("TAB_LINES START " + id + " 行=" + nT + " NOINFO=" + stNoinfoWhy);
                    }
                    else
                    {
                        JsonElement lsd = c.GetProperty("lineStartOffsetsDip");
                        int common = Math.Min(lines.Count, nT);
                        int r0 = 0, g0 = 0, ni0 = 0;
                        var det = new List<string>();
                        for (int k = 0; k < nT; ++k)
                        {
                            if (k >= common)   // 真值有、我方没有（行数不符）⇒ 该行**未判**；结构列已单独点过名
                            { ++ni0; det.Add("行#" + k + " NOINFO=行数不符(真值行=" + nT + " 我方行=" + lines.Count + ")"); continue; }
                            double truth = lsd[k].GetDouble();
                            if (truth != 0) ++stNzJudge;   // W25I 新增：非零真值行里被真正判过的行数（验收数载体；不参与红/绿）
                            double ours = R6(lines[k].Start);
                            if (ours != truth)
                            { ++r0; det.Add("行#" + k + " Start 期望=" + truth.ToString("F6", CultureInfo.InvariantCulture)
                                            + " 实得=" + ours.ToString("F6", CultureInfo.InvariantCulture)
                                            + " Δ=" + (ours - truth).ToString("F6", CultureInfo.InvariantCulture)); }
                            else ++g0;
                        }
                        stRed += r0; stGreen += g0; stJudge += r0 + g0; stNoinfo += ni0;
                        stSumRed += r0; stSumGreen += g0; stSumNoinfo += ni0;
                        if (r0 > 0)
                        {
                            ++stRedCases;
                            foreach (string t in det) Console.WriteLine("TAB_LINES START-RED " + id + " " + t);
                            stRedDetails.Add(new[] { id, string.Join("；", det) });
                        }
                        Console.WriteLine("TAB_LINES START " + id + " 行=" + nT + " 红=" + r0 + " 绿=" + g0
                                          + (ni0 > 0 ? " NOINFO=" + ni0 : ""));
                    }
                }
                // ────── `#24` P3：`HasOverflowed` 列（新增；只在语料带 `hasOverflowed` 时印）──────
                if (overField)
                {
                    int nT = OverTruthCount(c);
                    if (!overAssert)
                    {
                        ovNoinfo += nT; ovSumNoinfo += nT; ++ovNoinfoCases;
                        Console.WriteLine("TAB_LINES OVERFLOWED " + id + " 行=" + nT + " NOINFO=" + ovNoinfoWhy);
                    }
                    else
                    {
                        JsonElement tl = c.GetProperty("lines");
                        int common = Math.Min(lines.Count, nT);
                        int r0 = 0, g0 = 0, ni0 = 0;
                        var det = new List<string>();
                        for (int k = 0; k < nT; ++k)
                        {
                            if (k >= common)   // 真值有、我方没有（行数不符）⇒ 该行**未判**；结构列已单独点过名
                            { ++ni0; det.Add("行#" + k + " NOINFO=行数不符(真值行=" + nT + " 我方行=" + lines.Count + ")"); continue; }
                            JsonElement ln = tl[k];
                            if (!ln.TryGetProperty("hasOverflowed", out JsonElement hE)
                                || (hE.ValueKind != JsonValueKind.True && hE.ValueKind != JsonValueKind.False))
                            { ++ni0; det.Add("行#" + k + " NOINFO=真值缺 hasOverflowed"); continue; }
                            bool truth = hE.GetBoolean();
                            bool ours = lines[k].HasOverflowed;
                            if (truth) ++ovTrue;
                            // 诊断（**不参与红/绿**）：真值侧"恰好到达边缘"（余量 ≤ 1e-6）的行 ⇒ 本列因
                            //   我方 `width` 有 0.05 级容差而翻面的**风险带**（详见上方注释的严格 `>` 语义）。
                            if (ln.TryGetProperty("paragraphStartOffsetDip", out JsonElement pso)
                                && ln.TryGetProperty("width", out JsonElement wT)
                                && Math.Abs(pso.GetDouble() + wT.GetDouble() - pw) <= 1e-6) ++ovEdge;
                            if (ours != truth)
                            { ++r0; det.Add("行#" + k + " hasOverflowed 期望=" + (truth ? "true" : "false")
                                            + " 实得=" + (ours ? "true" : "false")); }
                            else ++g0;
                        }
                        ovRed += r0; ovGreen += g0; ovJudge += r0 + g0; ovNoinfo += ni0;
                        ovSumRed += r0; ovSumGreen += g0; ovSumNoinfo += ni0;
                        if (r0 > 0)
                        {
                            ++ovRedCases;
                            foreach (string t in det) Console.WriteLine("TAB_LINES OVERFLOWED-RED " + id + " " + t);
                            ovRedDetails.Add(new[] { id, string.Join("；", det) });
                        }
                        Console.WriteLine("TAB_LINES OVERFLOWED " + id + " 行=" + nT + " 红=" + r0 + " 绿=" + g0
                                          + (ni0 > 0 ? " NOINFO=" + ni0 : ""));
                    }
                }
            }
            Console.WriteLine("TAB_LINES 文件=" + System.IO.Path.GetFileName(path));
            foreach (var kv in fam)
            {
                famPos.TryGetValue(kv.Key, out int[] pp);
                Console.WriteLine("TAB_LINES   " + kv.Key.PadRight(22) + "结构 " + kv.Value[1] + "/" + kv.Value[0]
                                  + "；位置可比 " + (pp == null ? 0 : pp[0]) + " 其中过 " + (pp == null ? 0 : pp[1]));
            }
            int structPass = 0; foreach (var kv in fam) structPass += kv.Value[1];
            Console.WriteLine("TAB_LINES 合计 cases=" + total + " 判定过=" + pass + " 结构败=" + (total - skipCov - structPass)
                              + " 不可比(缺字形)=" + skipCov + " 其中 bidi 重排例=" + bidiCases
                              + "；Q3 clamp 铺满整行 " + clampHit + "/" + clampTot
                              + "；Q2 真值侧 tab 左缘自右缘量=网格倍数 " + q2TruthHit + "/" + q2TruthTot
                              + "，我方侧 " + q2OurHit + "/" + q2OurTot);
            Console.WriteLine("TAB_LINES 最大差=" + worst.ToString("F4") + " @" + worstWhy);
            // ────── `#22` P2：`Start` 列的可点名计数器 + 对账 + 喂给退出码 ──────
            if (startField)
            {
                Console.WriteLine("TAB_LINES START 红=" + stRed + " 绿=" + stGreen + " 判定行=" + stJudge + " NOINFO=" + stNoinfo + " NOINFO字形=0(构造性:本列不经字形)" + " 字形释放行=" + stGlyphReleased + " 非零真值行判定=" + stNzJudge
                                  + " 红例=" + stRedCases + " NOINFO例=" + stNoinfoCases + " 对齐=" + startAlign
                                  + " 量=R(我方 line.Start) 真值=lineStartOffsetsDip[k] R(v)=Round(v,6,AwayFromZero) 口径=Start≡ParagraphIndent");
                Console.WriteLine("TAB_LINES START 对账 逐例求和 红=" + stSumRed + " 绿=" + stSumGreen + " NOINFO=" + stSumNoinfo
                                  + " ⇒ " + ((stSumRed == stRed && stSumGreen == stGreen && stSumNoinfo == stNoinfo) ? "与汇总一致" : "**与汇总不一致**"));
                // 【退出码】未登记的 `Start` 红 ⇒ **必须**让 rc≠0；走**同一张**登记表、**同一个** `failures` 通道
                //   （故 `TAB_LINES UNREGISTERED/KNOWN-RED` 与既有 `退出码=` 行**无需**第二套口径；本列全绿时
                //    既有 `退出码=` 行**逐字节不变**）。**不许**把未登记红压成 0。
                foreach (string[] t in stRedDetails) failures.Add(t);
            }
            // ────── `#24` P3：`HasOverflowed` 列的可点名计数器 + 对账 + 喂给退出码 ──────
            if (overField)
            {
                Console.WriteLine("TAB_LINES OVERFLOWED 红=" + ovRed + " 绿=" + ovGreen + " 判定行=" + ovJudge + " NOINFO=" + ovNoinfo
                                  + " 红例=" + ovRedCases + " NOINFO例=" + ovNoinfoCases + " 对齐=" + overAlign
                                  + " NOINFO字形=" + ovNoinfoGlyph + " NOINFO字形外=" + (ovNoinfo - ovNoinfoGlyph) + " 真值True=" + ovTrue + " 诊断发丝边界行=" + ovEdge
                                  + " 量=我方 line.HasOverflowed 真值=lines[k].hasOverflowed"
                                  + " 口径=盒原点+行宽 > 段落宽（**严格 >**，相等⇒false；无容差；布尔全等）");
                Console.WriteLine("TAB_LINES OVERFLOWED 对账 逐例求和 红=" + ovSumRed + " 绿=" + ovSumGreen + " NOINFO=" + ovSumNoinfo
                                  + " ⇒ " + ((ovSumRed == ovRed && ovSumGreen == ovGreen && ovSumNoinfo == ovNoinfo) ? "与汇总一致" : "**与汇总不一致**"));
                // 【退出码】未登记的 `HasOverflowed` 红 ⇒ **必须**让 rc≠0；走**同一张**登记表、**同一个** `failures` 通道
                //   （故 `TAB_LINES UNREGISTERED/KNOWN-RED` 与既有 `退出码=` 行**无需**第二套口径；本列全绿时
                //    既有 `退出码=` 行**逐字节不变**）。**不许**把未登记红压成 0。
                foreach (string[] t in ovRedDetails) failures.Add(t);
            }
            // ---------------------------- #12(d)：退出码承载判定 ----------------------------
            // 口径：**未登记**的失败 ⇒ rc≠0；**已登记**的失败 ⇒ 只点名、不改 rc；全绿 ⇒ rc=0。
            //   ⚠️ 未给 `--known-red` ⇒ 任何失败都算"未登记"（rc=1）—— 这会改变本档旧行为（旧行为恒 rc=0），
            //      故此处大声打印；调用方（门禁）要带表。
            int unregistered = 0;
            foreach (string[] f in failures)
            {
                bool reg = kr.Matches(f[0], f[1]);
                Console.WriteLine("TAB_LINES " + (reg ? "KNOWN-RED " : "UNREGISTERED ") + f[0] + " :: " + f[1]
                                  + (reg ? "（已登记，不改退出码）" : ""));
                if (!reg) ++unregistered;
            }
            if (knownRedPath == null)
                Console.WriteLine("TAB_LINES 未给 --known-red ⇒ 任何失败都算**未登记**（rc=1）；本档旧行为是恒 rc=0，已改。");
            Console.WriteLine("TAB_LINES 退出码=" + (unregistered == 0 ? 0 : 1) + "（未登记失败 " + unregistered
                              + " / 失败共 " + failures.Count + " / 登记表 " + (knownRedPath ?? "<未给>") + "）");
            return unregistered == 0 ? 0 : 1;
        }

        /// <summary>`#22` P2：与真机臂同一取整口径（出处 `tests/parity/windows/tab-anchor/src/Program.cs:583`）。</summary>
        private static double R6(double v) => double.IsNaN(v) ? v : Math.Round(v, 6, MidpointRounding.AwayFromZero);

        /// <summary>`#22` P2：某例 `lineStartOffsetsDip` 的真值行数（无该字段 ⇒ 0 ⇒ 本行不判）。</summary>
        private static int StartTruthCount(JsonElement c)
            => c.TryGetProperty("lineStartOffsetsDip", out JsonElement a) && a.ValueKind == JsonValueKind.Array
               ? a.GetArrayLength() : 0;

        /// <summary>
        /// `#24` P3：某例**带 `hasOverflowed` 真值的行数**（无该字段 / 不是布尔 ⇒ 不计 ⇒ 该例不判）。
        /// 与 `StartTruthCount` 同形：**没有真值就不许判**（`NOINFO`，**不是绿**）。
        /// </summary>
        private static int OverTruthCount(JsonElement c)
        {
            if (!c.TryGetProperty("lines", out JsonElement a) || a.ValueKind != JsonValueKind.Array) return 0;
            int n = 0;
            foreach (JsonElement l in a.EnumerateArray())
                if (l.TryGetProperty("hasOverflowed", out JsonElement h)
                    && (h.ValueKind == JsonValueKind.True || h.ValueKind == JsonValueKind.False)) ++n;
            return n;
        }

        /// <summary>
        /// `#22` P2：从语料头 `paragraphProperties.fixed` 里取出 `TextAlignment=` 的值。
        /// **只对 `Left` 断言**；取不到 / 其他值 ⇒ 调用方逐行报 **NOINFO**（**不许发明公式**）。
        /// </summary>
        private static string StartAlignmentOf(JsonElement root)
        {
            if (!root.TryGetProperty("paragraphProperties", out JsonElement pp)) return "NOINFO";
            if (!pp.TryGetProperty("fixed", out JsonElement fx) || fx.ValueKind != JsonValueKind.String) return "NOINFO";
            string s = fx.GetString() ?? "";
            int i = s.IndexOf("TextAlignment=", StringComparison.Ordinal);
            if (i < 0) return "NOINFO";
            i += "TextAlignment=".Length;
            int j = s.IndexOf(',', i);
            return (j < 0 ? s.Substring(i) : s.Substring(i, j - i)).Trim();
        }

        /// <summary>#12(d)：已登记保留红表。行格式 `<用例 id>` 或 `<用例 id>::<判据片段>`；`#` 注释、空行忽略。</summary>
        private sealed class KnownRed
        {
            private readonly List<string[]> _rows = new List<string[]>();
            public static KnownRed Load(string path)
            {
                var k = new KnownRed();
                if (path == null) return k;
                if (!File.Exists(path)) { Console.WriteLine("TAB_LINES ⚠️ --known-red 文件不存在：" + path + "（⇒ 视作空表，任何失败都算未登记）"); return k; }
                foreach (string raw in File.ReadAllLines(path))
                {
                    string line = raw.Trim();
                    if (line.Length == 0 || line[0] == '#') continue;
                    int hash = line.IndexOf(" #", StringComparison.Ordinal);   // 行内注释：` #…` 起
                    if (hash >= 0) line = line.Substring(0, hash).Trim();
                    int i = line.IndexOf("::", StringComparison.Ordinal);
                    k._rows.Add(i < 0 ? new[] { line, null } : new[] { line.Substring(0, i).Trim(), line.Substring(i + 2).Trim() });
                }
                Console.WriteLine("TAB_LINES 登记表=" + path + " ⇒ 已登记 " + k._rows.Count + " 条");
                return k;
            }
            public bool Matches(string id, string reason)
            {
                foreach (string[] r in _rows)
                {
                    if (!string.Equals(r[0], id, StringComparison.Ordinal)) continue;
                    if (r[1] == null || (reason != null && reason.IndexOf(r[1], StringComparison.Ordinal) >= 0)) return true;
                }
                return false;
            }
        }

        private static KnownRed LoadKnownRed(string path) => KnownRed.Load(path);

        /// <summary>#12(d)：形状自检 ⇒ 返回 null = 形状对；否则返回"缺哪个键"的人类可读串。</summary>
        private static string TabLinesShapeError(JsonDocument doc)
        {
            if (doc.RootElement.ValueKind != JsonValueKind.Object) return "根不是对象";
            if (!doc.RootElement.TryGetProperty("cases", out JsonElement cases) || cases.ValueKind != JsonValueKind.Array)
                return "缺 cases 数组";
            int ci = 0;
            foreach (JsonElement c in cases.EnumerateArray())
            {
                foreach (string k in new[] { "id", "text", "paragraphWidthDip", "emSizeDip", "flowDirection", "textWrapping", "incrementalTabArm" })
                    if (!c.TryGetProperty(k, out _)) return "cases[" + ci + "] 缺 " + k;
                if (!c.TryGetProperty("lines", out JsonElement lines) || lines.ValueKind != JsonValueKind.Array)
                    return "cases[" + ci + "]（id=" + (c.TryGetProperty("id", out JsonElement idi) ? idi.GetString() : "?") + "）缺 lines 数组 ⇒ 这像是逐例结构";
                int li = 0;
                foreach (JsonElement L in lines.EnumerateArray())
                {
                    foreach (string k in new[] { "width", "trailingWhitespaceLength", "newlineLength", "lineText", "perChar" })
                        if (!L.TryGetProperty(k, out _)) return "cases[" + ci + "].lines[" + li + "] 缺 " + k;
                    if (L.GetProperty("perChar").ValueKind != JsonValueKind.Array) return "cases[" + ci + "].lines[" + li + "].perChar 不是数组";
                    int pi = 0;
                    foreach (JsonElement pc in L.GetProperty("perChar").EnumerateArray())
                    {
                        foreach (string k in new[] { "i", "char", "xFromLeftDip" })
                            if (!pc.TryGetProperty(k, out _)) return "cases[" + ci + "].lines[" + li + "].perChar[" + pi + "] 缺 " + k;
                        ++pi;
                    }
                    ++li;
                }
                ++ci;
            }
            return null;
        }

        private static Typeface MakeTypeface(string family)
        {
            try { return new Typeface(new FontFamily(family), FontStyles.Normal, FontWeights.Normal, FontStretches.Normal); }
            catch (Exception) { return null; }
        }

        private static string Describe(Typeface tf)
        {
            if (tf == null) return "<null>";
            string src = tf.FontFamily != null ? tf.FontFamily.Source : "?";
            try
            {
                GlyphTypeface gt;
                if (tf.TryGetGlyphTypeface(out gt) && gt != null)
                    return "family=" + src + " → " + gt.FontUri.LocalPath + "#" + gt.FaceIndex;
                return "family=" + src + " → TryGetGlyphTypeface=false";
            }
            catch (Exception e) { return "family=" + src + " → 异常 " + e.GetType().Name; }
        }
    }
}

// 轨道A 原型 · 驱动 + 取证。
//
// 回答四件事：
//   ① 代码量：净增行数（分文件）+ 欠多少个 override
//   ② 连锁：哪些契约假设在托管侧不成立（探针 P1–P6 的栈）
//   ③ 字形真的画出来了吗：把 `TextLine` 产出的 `GlyphRun` 交给 Skia 光栅化 → 非白像素 + PNG
//   ④ 与 HarfBuzz 直算一致吗：同一串文本，经 `TextLine` 出来的 advance 与 HB 直算**逐项相等**
//      并与"现行快路径"（cmap+hmtx 名义字形）对照（复用 M7c4 的基线：HB 37 字形 vs 快路径 41）

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;
using SkiaSharp;
using WpfLinux.Shims.PresentationCore;

namespace MilBridge.TextLineProto
{
    internal static class Program
    {
        private const string Text = "Hello WPF on Linux — AVATAR To office ffi";
        private const double EmSize = 24.0;
        private const float PixelsPerDip = 1.0f;

        private static int s_pass, s_fail;

        private static int Main()
        {
            string root = FindRepoRoot();
            string fontPath = Path.Combine(root, "build", "fonts", "NotoSans-Bold.ttf");
            Environment.SetEnvironmentVariable("WPF_LINUX_FONTS_DIR", Path.Combine(root, "build", "fonts"));

            Console.WriteLine("== 轨道A · TextLine 契约限时原型 ==");
            Console.WriteLine($"libharfbuzz = {HbShaper.Version}");
            Console.WriteLine($"font        = {fontPath}");
            Console.WriteLine($"text        = \"{Text}\"  emSize={EmSize}  ppd={PixelsPerDip}");
            Console.WriteLine();

            // ---------------- 1) HarfBuzz 直算 ----------------
            HbShapedRun hb = HbShaper.Shape(fontPath, Text, EmSize);
            Console.WriteLine($"[HB 直算]  字形 {hb.Glyphs.Length} 个，总宽 {hb.TotalWidthPx:F4}px，upem={hb.Upem}");
            Console.WriteLine($"           glyphs = [{string.Join(" ", Array.ConvertAll(hb.Glyphs, g => g.ToString()))}]");
            Console.WriteLine();

            // ---------------- 2) 拿真 GlyphTypeface（探针 P5 的路线）----------------
            GlyphTypeface gt = GetGlyphTypeface(root);
            Check("A1", "拿到真 GlyphTypeface（DWF Font → 内部 ctor）",
                gt != null && gt.GlyphCount > 0,
                gt == null ? "拿不到" : $"GlyphCount={gt.GlyphCount} Version={gt.Version} Baseline={gt.Baseline:F4}");

            // ---------------- 3) 建我的 TextLine ----------------
            var props = new HbRunProperties(null, EmSize, null);
            var run = new HbTextRun(Text, 0, Text.Length, props);
            TextLine line = new HbTextLine(run, hb, gt, PixelsPerDip);
            Console.WriteLine($"[HbTextLine] Width={line.Width:F4}  Height={line.Height:F4}  " +
                              $"Baseline={line.Baseline:F4}  Length={line.Length}");
            Console.WriteLine();

            // ---------------- 4) 三个 override ----------------
            // 4a GetTextRunSpans
            IList<TextSpan<TextRun>> spans = line.GetTextRunSpans();
            Check("A2", "GetTextRunSpans() 返回 1 个 span 且长度正确",
                spans.Count == 1 && spans[0].Length == Text.Length,
                $"spans={spans.Count} length={spans[0].Length}");

            // 4b GetTextBounds（走反射构造 TextBounds/TextRunBounds）
            IList<TextBounds> bounds = line.GetTextBounds(0, Text.Length);
            bool boundsOk = bounds.Count == 1 && bounds[0].TextRunBounds.Count == 1;
            Check("A3", "GetTextBounds() 返回真 TextBounds（反射构造 internal ctor）",
                boundsOk,
                boundsOk ? $"矩形={bounds[0].Rectangle}（宽 {bounds[0].Rectangle.Width:F4} vs TextLine.Width {line.Width:F4}）；" +
                           $"TextRunBounds={bounds[0].TextRunBounds.Count} 个"
                         : $"bounds={bounds.Count}");

            // 4c Draw —— 只验证参数校验路径（真驱动需要活窗口，见 P4）
            bool drawGuards = false;
            string drawDetail;
            try { line.Draw(null, new Point(0, 0), InvertAxes.None); drawDetail = "未抛（不应该）"; }
            catch (ArgumentNullException) { drawGuards = true; drawDetail = "null DrawingContext → ArgumentNullException ✓"; }
            catch (Exception e) { drawDetail = e.GetType().Name + ": " + e.Message; }
            // 第二个守卫（InvertAxes≠None）需要非 null 的 DrawingContext 才走得到；
            // 无头环境下拿不到 DrawingContext（见 P4），所以这里**如实标注为未覆盖**。
            drawDetail += "；InvertAxes≠None 守卫未能覆盖（无头环境拿不到 DrawingContext）";
            Check("A4", "Draw() 的 null 守卫正确（本体一行；真驱动需活窗口）", drawGuards, drawDetail);

            // ---------------- 5) ⭐ 字形真的画出来了吗 ----------------
            GlyphRun gr = ((HbTextLine)line).GlyphRunForRasterization;
            Check("A5", "GlyphRun 构造成功且逐项与 HarfBuzz 直算一致",
                GlyphsMatch(gr, hb) && AdvancesMatch(gr, hb),
                $"GlyphRun.GlyphIndices={gr.GlyphIndices.Count} 个，AdvanceWidths[0..2]=" +
                $"[{gr.AdvanceWidths[0]:F4} {gr.AdvanceWidths[1]:F4} {gr.AdvanceWidths[2]:F4}]；" +
                $"与 HB 直算逐项相等 = {GlyphsMatch(gr, hb) && AdvancesMatch(gr, hb)}");

            byte[] png;
            int nonWhite;
            RasterizeViaGlyphRun(gr, fontPath, out nonWhite, out png);
            int total = 640 * 80;
            Check("A6", "把 GlyphRun 光栅化到 SKSurface → 真的有字形像素",
                nonWhite > 500,
                $"非白像素 = {nonWhite} / {total}（{100.0 * nonWhite / total:F2}%）；PNG = {png.Length} 字节");

            // ---------------- 5b) ⭐ 9 个欠账：安全回退（不抛）+ 计数 ----------------
            {
                HbTextLineScaffold.ResetCounters();
                var fallbacks = new List<string>();
                int threw = 0;

                void Try(string name, Func<object> f)
                {
                    try { object v = f(); fallbacks.Add($"{name}→{(v == null ? "null" : v.GetType().Name)}"); }
                    catch (Exception e) { threw++; fallbacks.Add($"{name}→**抛 {e.GetType().Name}**"); }
                }

                Try(nameof(TextLine.GetTextLineBreak), () => line.GetTextLineBreak());
                Try(nameof(TextLine.GetTextCollapsedRanges), () => line.GetTextCollapsedRanges());
                Try(nameof(TextLine.Collapse), () => line.Collapse(new TextCollapsingProperties[0]));
                // 【T1b 2026-09-15 主控派工】`GetIndexedGlyphRuns` 的**值级**打印（只加输出，**不动任何判据**）。
                //   为什么只有这里能印：PC(DIRECT) 面能访问 internal，但**非 DIRECT 宿主**（本工程）才是
                //   "外部消费者视角"；值级三项必须是真值而不是 0/空/null —— 这是"回退真的发生了"的判据。
                Try(nameof(TextLine.GetIndexedGlyphRuns), () =>
                {
                    IEnumerable<IndexedGlyphRun> runs = line.GetIndexedGlyphRuns();
                    int n = 0;
                    foreach (IndexedGlyphRun r in runs)
                    {
                        GlyphRun g = r.GlyphRun;
                        Console.WriteLine($"      [IGR] run#{n} cp=[{r.TextSourceCharacterIndex},{r.TextSourceCharacterIndex + r.TextSourceLength})"
                            + $" FontUri={g.GlyphTypeface?.FontUri}"
                            + $" GlyphIndices=[{string.Join(",", g.GlyphIndices ?? new ushort[0])}]"
                            + $" AdvanceWidths=[{string.Join(",", g.AdvanceWidths ?? new double[0])}]"
                            // ⚠️ T1b2 2026-09-15 修编译错：PC 侧 `GlyphRun.GlyphIndices` 是
                            //   **`IList<ushort>`**（不是 `ushort[]`）⇒ `Array.IndexOf(Array, …)` 报
                            //   `CS1503 参数 1: 无法从 IList<ushort> 转换为 System.Array`。
                            //   改用 `IList<T>.IndexOf`（接口自带）⇒ 逐字等价、只修编译。
                            + $" (notdef={(g.GlyphIndices == null ? -1 : g.GlyphIndices.IndexOf((ushort)0))})");
                        ++n;
                    }
                    Console.WriteLine($"      [IGR] 共 {n} 个 run");
                    return runs;
                });
                // 【T1b2 2026-09-15 · 主控派的**回退对照**】文本含 **U+4E0E(`与`，Latin 面没有)**，
                //   走 `FormatParagraph`（D-F1 之后 `plan == null` 分支也会建 plan + `allowFallback:true`）。
                //   判据：回退真的换了面 ⇒ 这个 run 的 `FontUri` 必须与上面主 run 的**不同**；
                //   **若相同 ⇒ 那是值级真缺陷**（"回退没发生/换了面但 URI 没跟上"），报主控。
                Try(nameof(TextLine.GetIndexedGlyphRuns) + "(回退对照:含U+4E0E)", () =>
                {
                    List<HbTextLine> fl = HbTextLineFactory.FormatParagraph("AB\u4E0ECD", fontPath, EmSize, 1000.0,
                                                                            gt, PixelsPerDip, props, false, false, 0, out int _c);
                    int m = 0;
                    foreach (HbTextLine L2 in fl)
                        foreach (IndexedGlyphRun r in L2.GetIndexedGlyphRuns())
                        {
                            GlyphRun g = r.GlyphRun;
                            Console.WriteLine($"      [IGR-FB] run#{m} cp=[{r.TextSourceCharacterIndex},{r.TextSourceCharacterIndex + r.TextSourceLength})"
                                + $" FontUri={g.GlyphTypeface?.FontUri}"
                                + $" GlyphIndices=[{string.Join(",", g.GlyphIndices ?? new ushort[0])}]"
                                + $" (notdef={(g.GlyphIndices == null ? -1 : g.GlyphIndices.IndexOf((ushort)0))})");
                            ++m;
                        }
                    Console.WriteLine($"      [IGR-FB] 行 {fl.Count} 行，共 {m} 个 run");
                    return m;
                });
                Try(nameof(TextLine.GetCharacterHitFromDistance), () => line.GetCharacterHitFromDistance(10.0));
                Try(nameof(TextLine.GetDistanceFromCharacterHit), () => line.GetDistanceFromCharacterHit(new CharacterHit(0, 0)));
                Try(nameof(TextLine.GetNextCaretCharacterHit), () => line.GetNextCaretCharacterHit(new CharacterHit(0, 0)));
                Try(nameof(TextLine.GetPreviousCaretCharacterHit), () => line.GetPreviousCaretCharacterHit(new CharacterHit(0, 0)));
                Try(nameof(TextLine.GetBackspaceCaretCharacterHit), () => line.GetBackspaceCaretCharacterHit(new CharacterHit(0, 0)));

                // ⭐ B2 之后欠账从 9 个降到 6 个：Collapse / GetTextCollapsedRanges / GetTextLineBreak
                //    已是**真实现**（它们的欠账计数必须恒 0）。仍在欠账的 6 个（B3 + 零调用点的
                //    GetIndexedGlyphRuns）必须**恰好各记一次**且一个都没抛。
                bool allCounted = true; string counts = "";
                foreach (string m in HbTextLineScaffold.OwedMembers)
                {
                    long n = HbTextLineScaffold.HitCount(m);
                    counts += $"{m}={n} ";
                    bool implemented = Array.IndexOf(HbTextLineScaffold.StillOwedMembers, m) < 0;
                    if (implemented ? n != 0 : n != 1) allCounted = false;
                }
                // D-F1（2026-09-15）：`GetIndexedGlyphRuns` 已**真实现** ⇒ 仍欠账从 6 降到 **5**（它移出了
                //   `StillOwedMembers`，命中数须恒 0，由数据驱动的 `implemented` 分支自动校验）。
                // 【T1b 2026-09-15 接手复核（原改动出自 T1d，主控裁定保留并由本车道 owner 接手）】
                //   · 语义保持原样、**未被改宽**：遍历 OwedMembers，按 StillOwedMembers 把每个成员分成
                //     "仍欠账（必须安全回退且**恰好命中 1 次**）"与"真实现（命中恒 0）"，并断言**一个都没抛**；
                //   · 唯一改动 = **不把数字写死**：期望值由 `StillOwedMembers.Length` **导出**（当前 = 5：
                //     GetBackspaceCaretCharacterHit / GetCharacterHitFromDistance / GetDistanceFromCharacterHit /
                //     GetNextCaretCharacterHit / GetPreviousCaretCharacterHit；`GetIndexedGlyphRuns` 已由 D-F1
                //     真实现并移出名单）⇒ 名单一变，期望自动跟着变，不会再出现"名单 5、断言 6"这类漂移。
                int owedCount = HbTextLineScaffold.StillOwedMembers.Length;
                Check("A7", $"{owedCount} 个仍未欠账成员安全回退且各命中 1；其余真实现成员命中恒 0（一个都没抛）",
                    threw == 0 && allCounted && HbTextLineScaffold.TotalFallbackHits == owedCount,
                    $"抛出 {threw} 个；总计 {HbTextLineScaffold.TotalFallbackHits}/{owedCount}；{counts.Trim()}");
                Console.WriteLine($"        返回值：{string.Join("，", fallbacks)}");

                // B2 三个成员的真机口径（不是"回退"，是**真语义**）
                bool b2Semantics =
                    line.GetTextLineBreak() == null                                   // 普通文本 ⇒ null（真机 3220/3222）
                    && line.GetTextCollapsedRanges() == null                          // 未折叠 ⇒ null（真机 3222/3222）
                    && ReferenceEquals(line.Collapse(new TextCollapsingProperties[0]), line)  // 非可折叠行 ⇒ 原样返回
                    && HbTextLineScaffold.BreakZeroRecordIssued == 0;                 // 普通行**不发**零记录
                Check("A7b", "B2 三个成员的真机口径：普通文本 GetTextLineBreak()==null、未折叠 GetTextCollapsedRanges()==null、"
                             + "非可折叠行 Collapse(空参)==this、且**不发零记录**",
                    b2Semantics,
                    $"breakNull={HbTextLineScaffold.BreakNullReturned} 零记录={HbTextLineScaffold.BreakZeroRecordIssued} "
                    + $"折叠不可行={HbTextLineScaffold.CollapseEarlyReturnIneligible} 未折叠返回null={HbTextLineScaffold.CollapsedRangesNull}");

                // 严格模式：**仍欠账的**必须抛（名单 = `HbTextLineScaffold.StillOwedMembers`，现为 **5** 个）；
                //   已真实现的**不该抛**（定位用）。
                // ⚠️ T1b2 2026-09-15 口径更正：旧版拿 **`GetIndexedGlyphRuns`** 当"仍欠账"探针，而
                //   **D-F1（2026-09-15）把它真实现了、移出了 `StillOwedMembers`** ⇒ 它**本来就不该抛**
                //   ⇒ 旧断言 `strictThrows` 必然为 false ⇒ **A8 假红**（不是 STRICT 没生效）。
                //   改用**仍在册**的 `GetCharacterHitFromDistance` 作探针；`GetIndexedGlyphRuns` 移到
                //   "已实现**不该抛**"那一组 —— 这样两组的**口径都与 `StillOwedMembers` 对齐**。
                Environment.SetEnvironmentVariable(HbTextLineScaffold.StrictEnvVar, "1");
                bool strictThrows = false, implementedThrows = false;
                try { line.GetCharacterHitFromDistance(10.0); } catch (NotSupportedException) { strictThrows = true; }
                try { line.GetIndexedGlyphRuns(); line.GetTextLineBreak(); line.GetTextCollapsedRanges(); line.Collapse(new TextCollapsingProperties[0]); }
                catch (NotSupportedException) { implementedThrows = true; }
                Environment.SetEnvironmentVariable(HbTextLineScaffold.StrictEnvVar, null);
                Check("A8", "严格模式（WPF_LINUX_TEXTLINE_STRICT=1）下：**仍欠账的会抛、已真实现的不抛**"
                    + $"（探针口径 = `StillOwedMembers`，现 {HbTextLineScaffold.StillOwedMembers.Length} 个）",
                    strictThrows && !implementedThrows,
                    $"欠账抛={strictThrows}（探针 `GetCharacterHitFromDistance`，在册）；已实现却抛={implementedThrows}"
                    + $"（探针 `GetIndexedGlyphRuns`+B2 三个）");

                Console.WriteLine();
                Console.WriteLine($"[汇总行] {HbTextLineScaffold.SummaryLine()}");
            }

            // ---------------- 5c) 开关默认关 ----------------
            {
                Environment.SetEnvironmentVariable(HbTextLineScaffold.EnableEnvVar, null);
                bool dflt = HbTextLineScaffold.Enabled;
                Environment.SetEnvironmentVariable(HbTextLineScaffold.EnableEnvVar, "1");
                // Enabled 有缓存，重新解析用 ResetEnvCache 不存在 —— 这里只验"未设 ⇒ 关"
                Check("A9", $"开关 {HbTextLineScaffold.EnableEnvVar} **未设时为关**（默认 OFF）", !dflt,
                    $"未设 ⇒ Enabled={dflt}");
                Environment.SetEnvironmentVariable(HbTextLineScaffold.EnableEnvVar, null);
            }

            // ---------------- 6) 与"现行快路径"对照 ----------------
            CompareWithFastPath(fontPath);

            // ---------------- 7) 落盘证据 ----------------
            string outDir = Path.Combine(root, "build", "MilBridge", "gen");
            Directory.CreateDirectory(outDir);
            string pngPath = Path.Combine(outDir, "textline-proto.png");
            File.WriteAllBytes(pngPath, png);
            Console.WriteLine();
            Console.WriteLine($"[证据] PNG = {pngPath}（{png.Length} 字节，{nonWhite} 个非白像素）");

            Console.WriteLine();
            Console.WriteLine($"== 通过 {s_pass} / 失败 {s_fail} ==");
            return s_fail == 0 ? 0 : 1;
        }

        // ==================================================================

        private static void CompareWithFastPath(string fontPath)
        {
            using SKTypeface tf = SKTypeface.FromFile(fontPath);
            using var font = new SKFont(tf, (float)EmSize) { Hinting = SKFontHinting.None, Subpixel = true };
            var glyphs = new ushort[Text.Length];
            font.GetGlyphs(Text.AsSpan(), glyphs.AsSpan());
            var widths = new float[glyphs.Length];
            font.GetGlyphWidths(glyphs.AsSpan(), widths.AsSpan(), default, null);
            double fastTotal = 0;
            foreach (float w in widths) fastTotal += w;

            HbShapedRun hb = HbShaper.Shape(fontPath, Text, EmSize);
            Console.WriteLine();
            Console.WriteLine("[对照] 同一串文本：");
            Console.WriteLine($"  快路径（cmap+hmtx 名义字形）: {glyphs.Length} 字形，总宽 {fastTotal:F4}px");
            Console.WriteLine($"  HarfBuzz shaping          : {hb.Glyphs.Length} 字形，总宽 {hb.TotalWidthPx:F4}px");
            Console.WriteLine($"  差                        : {hb.Glyphs.Length - glyphs.Length} 字形，Δ={hb.TotalWidthPx - fastTotal:+0.0000;-0.0000}px");
            Console.WriteLine("  （与 M7c4 的基线同量级：真实字体 37 vs 快路径 41、Δ≈−7px）");
        }

        private static bool GlyphsMatch(GlyphRun gr, HbShapedRun hb)
        {
            if (gr.GlyphIndices.Count != hb.Glyphs.Length) return false;
            for (int i = 0; i < hb.Glyphs.Length; i++)
                if (gr.GlyphIndices[i] != hb.Glyphs[i]) return false;
            return true;
        }

        private static bool AdvancesMatch(GlyphRun gr, HbShapedRun hb)
        {
            if (gr.AdvanceWidths.Count != hb.AdvancesPx.Length) return false;
            for (int i = 0; i < hb.AdvancesPx.Length; i++)
                if (Math.Abs(gr.AdvanceWidths[i] - hb.AdvancesPx[i]) > 1e-9) return false;
            return true;
        }

        /// <summary>
        /// 把 `TextLine` 产出的 `GlyphRun` 光栅化 —— **这就是"字形真的出来了"的证据**。
        /// 逐字形取轮廓并按其累计 advance 摆放（与 MIL 的 MilGlyphRun_GetGlyphOutline 同一套路）。
        /// </summary>
        private static void RasterizeViaGlyphRun(GlyphRun gr, string fontPath, out int nonWhite, out byte[] png)
        {
            const int W = 640, H = 80;
            using var tf = SKTypeface.FromFile(fontPath);
            using var font = new SKFont(tf, (float)gr.FontRenderingEmSize)
            { Hinting = SKFontHinting.None, Subpixel = true };
            using var surface = SKSurface.Create(new SKImageInfo(W, H, SKColorType.Bgra8888, SKAlphaType.Premul));
            SKCanvas canvas = surface.Canvas;
            canvas.Clear(SKColors.White);

            using var paint = new SKPaint { Color = SKColors.Black, IsAntialias = true, Style = SKPaintStyle.Fill };
            double penX = 4;
            double baseline = 4 + gr.FontRenderingEmSize;   // 顶部留 4px

            for (int i = 0; i < gr.GlyphIndices.Count; i++)
            {
                ushort gid = gr.GlyphIndices[i];
                using SKPath path = font.GetGlyphPath(gid);
                if (path != null)
                {
                    canvas.Save();
                    // ⚠️ 不要再翻 y：`SKFont.GetGlyphPath` 返回的轮廓**已经是 y 向下**的
                    //    Skia 坐标系（与 canvas 一致）。第一版多翻了
                    //    `Canvas.Scale(1,-1)`，结果 PNG 里的字是**倒的**（像素计数不受影响，
                    //    但证据图不可读）—— 这是实测踩到的。
                    canvas.Translate((float)(penX + gr.GlyphOffsets[i].X), (float)baseline);
                    canvas.DrawPath(path, paint);
                    canvas.Restore();
                }
                penX += gr.AdvanceWidths[i];
            }

            canvas.Flush();

            using SKImage img = surface.Snapshot();
            using SKBitmap bmp = SKBitmap.FromImage(img);
            nonWhite = 0;
            for (int y = 0; y < H; y++)
                for (int x = 0; x < W; x++)
                {
                    SKColor c = bmp.GetPixel(x, y);
                    if (c.Red < 200 || c.Green < 200 || c.Blue < 200) nonWhite++;
                }

            using SKImage img2 = surface.Snapshot();
            using SKData data = img2.Encode(SKEncodedImageFormat.Png, 100);
            png = data.ToArray();
        }

        /// <summary>探针 P5 已验证的路线：DWF Font → GlyphTypeface(内部 ctor)。</summary>
        private static GlyphTypeface GetGlyphTypeface(string root)
        {
            const string TI = "MS.Internal.Text.TextInterface";
            Assembly dwf = Assembly.Load("DirectWriteForwarder");
            Type colType = dwf.GetType(TI + ".FontCollection", true);
            object col = colType.GetMethod("FromDirectory",
                    BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(null, new object[] { Path.Combine(root, "build", "fonts") });

            Type famType = dwf.GetType(TI + ".FontFamily", true);
            PropertyInfo indexer = colType.GetProperty("Item",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic,
                null, famType, new[] { typeof(uint) }, null);
            object family = indexer.GetValue(col, new object[] { 0u });

            object bold = Enum.Parse(dwf.GetType(TI + ".FontWeight", true), "Bold");
            object stretch = Enum.Parse(dwf.GetType(TI + ".FontStretch", true), "Normal");
            object style = Enum.Parse(dwf.GetType(TI + ".FontStyle", true), "Normal");
            object font = family.GetType()
                .GetMethod("GetFirstMatchingFont", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(family, new[] { bold, stretch, style });

            ConstructorInfo gi = typeof(GlyphTypeface).GetConstructor(
                BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public,
                null, new[] { font.GetType() }, null);
            return (GlyphTypeface)gi.Invoke(new[] { font });
        }

        private static void Check(string id, string what, bool ok, string detail)
        {
            if (ok) { s_pass++; Console.WriteLine($"  PASS  {id}  {what}\n        {detail}"); }
            else { s_fail++; Console.WriteLine($"  FAIL  {id}  {what}\n        {detail}"); }
        }

        private static string FindRepoRoot()
        {
            var di = new DirectoryInfo(AppContext.BaseDirectory);
            for (int i = 0; i < 10 && di != null; i++, di = di.Parent)
                if (File.Exists(Path.Combine(di.FullName, "handoff.md"))) return di.FullName;
            throw new InvalidOperationException("找不到仓库根");
        }
    }
}

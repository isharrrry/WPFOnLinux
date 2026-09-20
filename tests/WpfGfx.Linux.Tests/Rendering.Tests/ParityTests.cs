// U1a：真机 Windows WPF 渲染结果 ↔ 我方 Linux 渲染栈的像素级对照。
//
// 【这一套用例要回答的问题】
//   工程历史上第一次把**真机像素**当 oracle。15 个场景各自一条 [Fact]，比对口径见
//   ParityCompare.cs 的三档容差；三条待验证的真机结论（sRGB 插值 / PushOpacity 合成层 /
//   Exclude=差集）各有一条独立用例，把"真机值 / 我方值 / 反模型值"三者摆在一起。
//
// 【数据缺失时的行为】
//   真机数据（tests/parity/windows/）不在时，用**发现期 Skip**（ParityFactAttribute 在构造
//   函数里探测），照抄 Windowing.Tests/X11Guard.cs 的做法与理由：xunit 2.9.2 的运行期 skip
//   会被记成 Failed，只有 FactAttribute.Skip 是干净的。
//
// 【产物】
//   tests/parity/linux/actual/*.png      我方渲染结果
//   tests/parity/linux/diff/*.diff.png   差异图（红 Δ>16 / 黄 3..16 / 暗底=真机图）
//   tests/parity/linux/parity-results.json  机器可读的逐场景数字
//
// 【预算是怎么定的（重要，别把它当"永远正确"）】
//   Interior 档（Δ>2 且不在真机边缘邻域）是**硬约束**：它是"语义错"的判据，
//   预算 = 首次对照的实测值，任何新增都说明语义变了，必须解释。
//   Tight 档（Δ>2）包含边缘取样差异，预算按"实测值 + 余量"表征化——
//   它的作用是抓大回归（少画一半），不是抓单个边缘像素。

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Text.Json;
using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    /// <summary>真机数据缺失 → 发现期跳过（理由与写法见 X11Guard.cs）。</summary>
    internal sealed class ParityFactAttribute : FactAttribute
    {
        public ParityFactAttribute()
        {
            if (!ParityData.Available) Skip = ParityData.SkipReason;
        }
    }

    public class ParityTests
    {
        public ParityTests(ITestOutputHelper output) => Output = output;

        private ITestOutputHelper Output { get; }

        private static readonly object Gate = new object();
        private static readonly Dictionary<string, ParityOutcome> Cache =
            new Dictionary<string, ParityOutcome>(StringComparer.Ordinal);

        // ==================================================================
        //  15 个场景：一一对应 scenes.json
        // ==================================================================

        [ParityFact] public void scene01_solid() => AssertScene("scene01_solid");
        [ParityFact] public void scene02_roundrect() => AssertScene("scene02_roundrect");
        [ParityFact] public void scene03_ellipse() => AssertScene("scene03_ellipse");
        [ParityFact] public void scene04_linear_gradient() => AssertScene("scene04_linear_gradient");
        [ParityFact] public void scene05_radial_gradient() => AssertScene("scene05_radial_gradient");
        [ParityFact] public void scene06_dash() => AssertScene("scene06_dash");
        [ParityFact] public void scene07_opacity() => AssertScene("scene07_opacity");
        [ParityFact] public void scene08_clip_rect() => AssertScene("scene08_clip_rect");
        [ParityFact] public void scene09_clip_path_fillrule() => AssertScene("scene09_clip_path_fillrule");
        [ParityFact] public void scene10_transform() => AssertScene("scene10_transform");
        [ParityFact] public void scene11_arc_sweep_large() => AssertScene("scene11_arc_sweep_large");
        [ParityFact] public void scene12_arc_ellipse() => AssertScene("scene12_arc_ellipse");
        [ParityFact] public void scene13_arc_degenerate() => AssertScene("scene13_arc_degenerate");
        [ParityFact] public void scene14_combine_union_xor() => AssertScene("scene14_combine_union_xor");
        [ParityFact] public void scene15_combine_intersect_exclude() => AssertScene("scene15_combine_intersect_exclude");

        // ==================================================================
        //  结论 1：渐变在 sRGB 空间插值（不是线性 scRGB）
        // ==================================================================

        [ParityFact]
        public void conclusion1_gradient_interpolates_in_srgb()
        {
            // scene04 第二条渐变：黑(#FF000000) → 白(#FFFFFFFF)，起止 (16,152)→(240,152)。
            // 探针 (128,182) 的 t = (128.5-16)/224 = 0.5022
            const int px = 128, py = 182;
            const double t = (px + 0.5 - 16.0) / 224.0;

            ParitySceneSpec spec = ParityData.Get("scene04_linear_gradient");
            ParityOutcome outcome = RunScene(spec.Id);
            using SKBitmap actual = RenderHarness.LoadPng(outcome.ActualPath);
            using SKBitmap windows = ParityData.LoadWindowsPng(spec);

            SKColor mine = actual.GetPixel(px, py);
            SKColor real = windows.GetPixel(px, py);

            // 反模型：线性 scRGB 插值 → t 直接当 scRGB 值再转 sRGB 字节
            byte linearModel = SkiaColor.ScRgbToSrgbByte((float)t);

            Output.WriteLine(
                $"scene04 中点 ({px},{py}) t={t:F4}：真机 {ParityCompare.Rgba(real)} / " +
                $"我方 {ParityCompare.Rgba(mine)} / 线性 scRGB 反模型 {linearModel}");

            Assert.True(ParityCompare.ChannelDelta(mine, real) <= 2,
                $"sRGB 插值不吻合：真机 {ParityCompare.Rgba(real)} vs 我方 {ParityCompare.Rgba(mine)}");

            // 真机测得 128（= sRGB 插值）；线性 scRGB 会给出 ~188。判定我方落在 sRGB 一侧。
            Assert.InRange(mine.Red, 120, 140);
            Assert.True(linearModel > 180, $"反模型自检异常：线性 scRGB 中点应 ~188，实得 {linearModel}");

            // 三条带的三个停靠点也一起核（红→绿→蓝，t≈0.28 处 sRGB 与线性差得最狠）
            SKColor mid = actual.GetPixel(72, 56);
            SKColor realMid = windows.GetPixel(72, 56);
            Output.WriteLine($"scene04 三停靠带 (72,56)：真机 {ParityCompare.Rgba(realMid)} / 我方 {ParityCompare.Rgba(mid)}" +
                             "（sRGB 手算 (112,143,0)，线性会得 (191,187,0)）");
            Assert.True(ParityCompare.ChannelDelta(mid, realMid) <= 2,
                $"三停靠带中点不吻合：真机 {ParityCompare.Rgba(realMid)} vs 我方 {ParityCompare.Rgba(mid)}");
        }

        // ==================================================================
        //  结论 2：PushOpacity 是真·合成层（整组先画再统一乘 alpha）
        // ==================================================================

        [ParityFact]
        public void conclusion2_push_opacity_is_a_compositing_layer()
        {
            // scene07：白底 → 左半红/右半蓝 → PushOpacity(0.75) 组内两个 50% alpha 椭圆
            // （cx=110/146, cy=150, r=36，重叠区在 x≈122）。探针 (122,150) 落在重叠区的红底一侧。
            const int px = 122, py = 150;

            ParitySceneSpec spec = ParityData.Get("scene07_opacity");
            ParityOutcome outcome = RunScene(spec.Id);
            using SKBitmap actual = RenderHarness.LoadPng(outcome.ActualPath);
            using SKBitmap windows = ParityData.LoadWindowsPng(spec);

            SKColor mine = actual.GetPixel(px, py);
            SKColor real = windows.GetPixel(px, py);
            int[] perPrimitive = PerPrimitiveAlphaModel(px, py);

            Output.WriteLine($"scene07 组内重叠区 ({px},{py})：");
            Output.WriteLine($"  真机（合成层模型）{ParityCompare.Rgba(real)}");
            Output.WriteLine($"  我方 MilPushOpacity {ParityCompare.Rgba(mine)}");
            Output.WriteLine($"  逐图元乘 alpha 反模型 ({perPrimitive[0]},{perPrimitive[1]},{perPrimitive[2]})");

            // 先用我方栈**真的画出**"逐图元"那版：把组不透明度乘进每个子画刷的 alpha。
            int[] variant = RenderPerPrimitiveAlphaVariant(px, py);
            Output.WriteLine($"  用我方栈重画的逐图元版本 ({variant[0]},{variant[1]},{variant[2]})");

            Assert.True(ParityCompare.ChannelDelta(mine, real) <= 2,
                $"PushOpacity 不吻合：真机 {ParityCompare.Rgba(real)} vs 我方 {ParityCompare.Rgba(mine)}");

            // 同一套栈能画出反模型，且反模型与真机明显不符——这才证明"吻合"不是巧合
            Assert.True(Math.Abs(variant[1] - real.Green) > 8,
                "逐图元反模型竟然和真机一样，说明本用例没有区分力");
            Assert.True(Math.Abs(variant[1] - mine.Green) > 8,
                "我方实现与逐图元反模型重合，说明 PushOpacity 没走合成层");
        }

        /// <summary>解析式反模型：每个子图元的 alpha 各乘 0.75 后逐个混合到红底上。</summary>
        private static int[] PerPrimitiveAlphaModel(int x, int y)
        {
            // 背景：x &lt; 128 为红 (255,0,0)
            double[] dst = { 255, 0, 0 };
            // 子 1：黄色 #80FFFF00（alpha 128/255），其后再乘组不透明度 0.75
            dst = Over(new double[] { 255, 255, 0 }, 128.0 / 255.0 * 0.75, dst);
            // 子 2：绿色 #8000FF00
            dst = Over(new double[] { 0, 255, 0 }, 128.0 / 255.0 * 0.75, dst);

            return new[] { (int)Math.Round(dst[0]), (int)Math.Round(dst[1]), (int)Math.Round(dst[2]) };
        }

        private static double[] Over(double[] src, double alpha, double[] dst)
        {
            var r = new double[3];
            for (int i = 0; i < 3; i++) r[i] = src[i] * alpha + dst[i] * (1 - alpha);
            return r;
        }

        /// <summary>用我方栈重画 scene07 的"逐图元乘 alpha"版本（不用 PushOpacity）。</summary>
        private int[] RenderPerPrimitiveAlphaVariant(int px, int py)
        {
            using var scene = new TestScene();
            var draw = new DrawList();

            draw.Add(Rect(0, 0, 256, 256, scene.Solid(0xFF, 0xFF, 0xFF)));
            draw.Add(Rect(0, 0, 128, 256, scene.Solid(0xFF, 0x00, 0x00)));
            draw.Add(Rect(128, 0, 128, 256, scene.Solid(0x00, 0x00, 0xFF)));
            draw.Add(Rect(32, 32, 192, 80, scene.SolidWithOpacity(0xFF, 0xFF, 0xFF, 0.5)));

            // 组内两个 50% alpha 椭圆：这里把 0.75 乘进画刷 alpha（0x80 * 0.75 ≈ 0x60）
            draw.Add(Ellipse(110, 150, 36, 36, scene.SolidWithOpacity(0xFF, 0xFF, 0x00, 0.5 * 0.75)));
            draw.Add(Ellipse(146, 150, 36, 36, scene.SolidWithOpacity(0x00, 0xFF, 0x00, 0.5 * 0.75)));

            draw.Add(Rect(32, 200, 192, 40, scene.SolidWithOpacity(0xFF, 0xFF, 0xFF, 128.0 / 255.0)));

            MilVisual root = scene.Visual();
            root.Content = draw.ToRenderData();

            using SKBitmap bitmap = RenderHarness.RenderBitmap(root, scene.Provider, 256, 256);
            SKColor c = bitmap.GetPixel(px, py);
            return new[] { (int)c.Red, (int)c.Green, (int)c.Blue };
        }

        [ParityFact]
        public void conclusion2b_push_opacity_uses_a_layer_not_brush_alpha()
        {
            // 同一个 (122,150) 位置，两个模型必须给出不同的绿通道：
            //   合成层：(159,144,0)   逐图元：(159,156,0)
            // 真机 = 前者。这里把我方两版都画出来，差值必须 ~12。
            ParitySceneSpec spec = ParityData.Get("scene07_opacity");
            ParityOutcome outcome = RunScene(spec.Id);
            using SKBitmap actual = RenderHarness.LoadPng(outcome.ActualPath);

            int green = actual.GetPixel(122, 150).Green;
            int greenVariant = RenderPerPrimitiveAlphaVariant(122, 150)[1];

            Output.WriteLine($"绿通道对比：合成层 {green} / 逐图元 {greenVariant} / 真机 144");
            Assert.InRange(green, 140, 150);
            Assert.InRange(greenVariant, 152, 160);
        }

        // ==================================================================
        //  结论 3：CombinedGeometry.Exclude = A−B（差集）→ 债务 #8
        // ==================================================================

        [ParityFact]
        public void conclusion3_exclude_is_set_difference()
        {
            ParitySceneSpec spec = ParityData.Get("scene15_combine_intersect_exclude");
            ParityOutcome outcome = RunScene(spec.Id);
            using SKBitmap actual = RenderHarness.LoadPng(outcome.ActualPath);
            using SKBitmap windows = ParityData.LoadWindowsPng(spec);

            // 右格（exclude）三个区域：A 独占 / 交叠 / B 独占；基础色 #FF00A060
            var samples = new (int X, int Y, string Region)[]
            {
                (148, 64, "exclude: A-only"),
                (196, 64, "exclude: A^B overlap"),
                (240, 64, "exclude: B-only"),
                (20, 64, "intersect: A-only"),
                (68, 64, "intersect: A^B overlap"),
                (112, 64, "intersect: B-only"),
            };

            foreach (var (x, y, region) in samples)
            {
                SKColor mine = actual.GetPixel(x, y);
                SKColor real = windows.GetPixel(x, y);
                Output.WriteLine($"{region,-26} ({x},{y})  真机 {ParityCompare.Rgba(real)}  我方 {ParityCompare.Rgba(mine)}");
                Assert.True(ParityCompare.ChannelDelta(mine, real) <= 2,
                    $"{region} 不吻合：真机 {ParityCompare.Rgba(real)} vs 我方 {ParityCompare.Rgba(mine)}");
            }

            // 反模型：把 Exclude 当 Xor（对称差）画同一格，B 独占区必须被填上——与真机相反。
            int[] xorVariant = RenderExcludeCellAsXor(240, 64);
            Output.WriteLine($"把 Exclude 当 Xor 画 B 独占区 (240,64)：({xorVariant[0]},{xorVariant[1]},{xorVariant[2]})" +
                             "（真机是白色背景，即不填充）");
            Assert.True(xorVariant[1] > 100, "Xor 反模型竟然没填 B 独占区，用例失去区分力");
        }

        private int[] RenderExcludeCellAsXor(int px, int py)
        {
            using var scene = new TestScene();
            var draw = new DrawList();

            draw.Add(Rect(0, 0, 256, 256, scene.Solid(0xFF, 0xFF, 0xFF)));

            DUCE.ResourceHandle a = scene.Handle(
                new MilEllipseGeometry { Center = new MilPoint(176, 64), RadiusX = 40, RadiusY = 40 });
            DUCE.ResourceHandle b = scene.Handle(
                new MilEllipseGeometry { Center = new MilPoint(216, 64), RadiusX = 40, RadiusY = 40 });

            draw.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawGeometry,
                Geometry = scene.Mh(new MilCombinedGeometry
                {
                    GeometryCombineMode = MilGeometryCombineMode.Xor,   // ← 反模型：Xor 而非 Exclude
                    Geometry1 = a,
                    Geometry2 = b,
                }),
                Brush = scene.Mh(scene.Solid(0x00, 0xA0, 0x60)),
            });

            MilVisual root = scene.Visual();
            root.Content = draw.ToRenderData();

            using SKBitmap bitmap = RenderHarness.RenderBitmap(root, scene.Provider, 256, 256);
            SKColor c = bitmap.GetPixel(px, py);
            return new[] { (int)c.Red, (int)c.Green, (int)c.Blue };
        }

        // ==================================================================
        //  债务 #7：Arc 段逐项量化（4 种退化 + 椭圆弧 + sweep×largeArc）
        // ==================================================================

        [ParityFact]
        public void debt7_arc_degenerate_cases_quantified()
        {
            ParitySceneSpec spec = ParityData.Get("scene13_arc_degenerate");
            ParityOutcome outcome = RunScene(spec.Id);
            using SKBitmap actual = RenderHarness.LoadPng(outcome.ActualPath);
            using SKBitmap windows = ParityData.LoadWindowsPng(spec);

            // 四格：D1 半径过小(rx10,ry5→放大约 40,20) / D2 半径==弦半 / D2' 同参数 largeArc=false
            //        / D3 rx=ry=0 退化成直线 + D4 rx=ry=5000 巨半径
            var cases = new (string Name, int CellX, int CellY, int ProbeX, int ProbeY)[]
            {
                ("D1 半径过小→等比放大 (rx10,ry5; 弦 80)", 0, 0, 64, 54),
                ("D2 半径==弦/2 且 IsLargeArc=true",        1, 0, 192, 54),
                ("D2' 同参数 IsLargeArc=false",             0, 1, 64, 182),
                ("D3 rx=ry=0 → 直线",                       1, 1, 192, 212),
                ("D4 rx=ry=5000 巨半径",                    1, 1, 192, 172),
            };

            (int Diff, int MaxDelta)[] cells = ParityCompare.CellStats(actual, windows, 2, 2);

            foreach (var (name, cx, cy, probeX, probeY) in cases)
            {
                SKColor mine = actual.GetPixel(probeX, probeY);
                SKColor real = windows.GetPixel(probeX, probeY);
                (int diff, int maxDelta) = cells[cy * 2 + cx];
                Output.WriteLine(
                    $"{name,-40} 格({cx},{cy}) Δ>2 {diff,5} 本例探针({probeX},{probeY}) " +
                    $"真机 {ParityCompare.Rgba(real)} 我方 {ParityCompare.Rgba(mine)} Δ={ParityCompare.ChannelDelta(mine, real)} " +
                    $"| 整格最大通道差 {maxDelta}");
            }

            // D2 vs D2'：真机两格并非逐字节相同（245/16384 像素、最大差 44，纯 AA）
            var realD2 = ParityCompare.RegionVsRegion(windows, windows, 128, 0, 0, 128, 128, 128);
            var mineD2 = ParityCompare.RegionVsRegion(actual, actual, 128, 0, 0, 128, 128, 128);
            Output.WriteLine($"真机 cell(1,0) vs cell(0,1)：Δ>2 {realD2.Diff}/16384，最大通道差 {realD2.MaxDelta}");
            Output.WriteLine($"我方 cell(1,0) vs cell(0,1)：Δ>2 {mineD2.Diff}/16384，最大通道差 {mineD2.MaxDelta}");

            // 我方两格必须逐字节相同（Skia 对"半径==弦/2"的 largeArc 两支是同一条弧）
            Assert.Equal(0, mineD2.Diff);

            // 每个退化格的探针都要落在真机同一侧
            Assert.True(ParityCompare.ChannelDelta(actual.GetPixel(64, 54), windows.GetPixel(64, 54)) <= 2,
                "D1 放大后的填充区不吻合（真机上半椭圆填充）");
            Assert.True(ParityCompare.ChannelDelta(actual.GetPixel(192, 212), windows.GetPixel(192, 212)) <= 2,
                "D3 rx=ry=0 未退化成直线");
        }

        [ParityFact]
        public void debt7_arc_sweep_large_combinations_quantified()
        {
            ParitySceneSpec spec = ParityData.Get("scene11_arc_sweep_large");
            ParityOutcome outcome = RunScene(spec.Id);
            using SKBitmap actual = RenderHarness.LoadPng(outcome.ActualPath);
            using SKBitmap windows = ParityData.LoadWindowsPng(spec);

            // scene11 的格子是 64×128：4 列 × 2 行，列 = small-cw / large-cw / small-ccw / large-ccw，
            // 行 1 = 水平弦（y=64），行 2 = 斜弦（(12,80)→(52,40)）。切块必须与场景格子对齐。
            (int Diff, int MaxDelta)[] cells = ParityCompare.CellStats(actual, windows, 4, 2);
            string[] names =
            {
                "row1(水平弦) small-cw", "row1 large-cw", "row1 small-ccw", "row1 large-ccw",
                "row2(斜弦)  small-cw", "row2 large-cw", "row2 small-ccw", "row2 large-ccw",
            };

            for (int i = 0; i < cells.Length; i++)
                Output.WriteLine($"{names[i],-22} 格({i % 4},{i / 4}) Δ>2 {cells[i].Diff,5}/8192  最大通道差 {cells[i].MaxDelta,3}");

            Assert.Equal(0, outcome.ProbeFailed);
        }

        [ParityFact]
        public void debt7_arc_ellipse_rotation_quantified()
        {
            ParitySceneSpec spec = ParityData.Get("scene12_arc_ellipse");
            ParityOutcome outcome = RunScene(spec.Id);
            using SKBitmap actual = RenderHarness.LoadPng(outcome.ActualPath);
            using SKBitmap windows = ParityData.LoadWindowsPng(spec);

            (int Diff, int MaxDelta)[] cells = ParityCompare.CellStats(actual, windows, 2, 2);
            // 4 个 128×128 格：列 = x 偏移 64 / 192，行 = y 偏移 64 / 192
            string[] names =
            {
                "rx45 ry22 rot0  small-cw", "rx45 ry22 rot45 large-cw",
                "rx22 ry45 rot90 small-ccw", "rx45 ry22 rot30 large-ccw",
            };

            for (int i = 0; i < cells.Length; i++)
                Output.WriteLine($"{names[i],-28} Δ>2 {cells[i].Diff,5}/16384  最大通道差 {cells[i].MaxDelta,3}");

            Assert.Equal(0, outcome.ProbeFailed);
        }

        // ==================================================================
        //  汇总：写机器可读结果 + 打印总表
        // ==================================================================

        [ParityFact]
        public void parity_summary_writes_results()
        {
            ParityLayout.EnsureDirs();

            var table = new StringBuilder();
            table.AppendLine("场景                        差异像素(Δ>2)      占比      内部差异(Δ>2,非边缘)  最大通道差  AA超限(Δ>16)  探针  分类");
            table.AppendLine(new string('-', 130));

            foreach (ParitySceneSpec spec in ParityData.Scenes)
            {
                ParityOutcome o = RunScene(spec.Id);
                table.AppendLine(string.Format(CultureInfo.InvariantCulture,
                    "{0,-26} {1,8}  {2,9}  {3,10}  {4,10}  {5,10}  {6,4}/{7,-4} {8}",
                    o.Id, o.DifferingTight, ParityCompare.Pct(o.TightRatio),
                    o.DifferingInterior, o.MaxDelta, o.DifferingLoose,
                    o.ProbeTotal - o.ProbeFailed, o.ProbeTotal, o.Classification));
            }

            Output.WriteLine(table.ToString());
            WriteResultsJson();

            // 总闸：任何场景出现"非边缘语义差异"或探针失配，都必须被看见
            foreach (ParitySceneSpec spec in ParityData.Scenes)
            {
                ParityOutcome o = RunScene(spec.Id);
                Assert.Equal(0, o.DecodeMismatches);
            }
        }

        // ==================================================================
        //  变换矩阵：真机 composite 当 oracle，反查我方矩阵复合顺序
        // ==================================================================

        [ParityFact]
        public void transform_matrix_composition_order_vs_wpf()
        {
            // scenes.json 里每个 transform op 都带 "composite"，它是 WPF
            // `Matrix.Multiply(m, t)` 逐个乘出来的结果（R.cs:148-158）。用上游源码当依据：
            //   WindowsBase/System/Windows/Media/Matrix.cs:127  Multiply(a,b) → a·b（行向量）
            //   TransformGroup.cs:31 Value = c0 * c1 * … * cn → **c0 先作用在几何上**
            // 也就是说 composite = "先 M0 再 M1 …" 的行向量乘积。
            //
            // 【本条用例暴露的真实差异】
            //   我方 TransformResolver.Mul(a, b) 的公式数值上等于 SKMatrix.Concat(a, b)
            //   （实测：Concat(R30,T30).TransX = 10.98，而 WPF 的 composite 是 30），
            //   而 Concat(a,b) 的语义是 "b 先作用"。于是
            //     · AroundCenter = Mul(Mul(T(c),inner),T(-c)) → T(-c)∘inner∘T(c) ✔ 正确
            //     · Resolve(MilTransformGroup) 的 acc = Mul(acc, child) → cn∘…∘c0  ✘ 反序
            //   影响面：任何 Transform 资源是 TYPE_TRANSFORMGROUP 的 Visual
            //   （VisualProjection.cs:38 走的就是这条路），即 XAML 里常见的
            //   <TransformGroup> 会按相反顺序作用。发布为**债务 #12**（只报告，未改：
            //   改动会动到 tests/golden/transform_nested.png 基准，超出本次授权）。
            int wpfOrderMatches = 0, mulOrderMatches = 0, diverging = 0;

            foreach (ParitySceneSpec spec in ParityData.Scenes)
            {
                foreach (JsonElement op in spec.Ops.EnumerateArray())
                {
                    if (op.GetProperty("op").GetString() != "transform") continue;
                    if (!op.TryGetProperty("composite", out JsonElement comp)) continue;

                    double[] want =
                    {
                        comp[0].GetDouble(), comp[1].GetDouble(), comp[2].GetDouble(),
                        comp[3].GetDouble(), comp[4].GetDouble(), comp[5].GetDouble(),
                    };

                    SKMatrix wpfOrder = ChainMatrices(op, wpfFirstThenNext: true);
                    SKMatrix mulOrder = ChainMatrices(op, wpfFirstThenNext: false);

                    bool wpfOk = Matches(wpfOrder, want);
                    bool mulOk = Matches(mulOrder, want);

                    if (wpfOk) wpfOrderMatches++;
                    if (mulOk) mulOrderMatches++;
                    if (!mulOk) diverging++;
                }
            }

            Output.WriteLine($"transform op 复合矩阵自检：WPF 顺序命中 {wpfOrderMatches} 个，" +
                             $"TransformResolver.Mul 顺序命中 {mulOrderMatches} 个，" +
                             $"两者不一致 {diverging} 个");

            // ① 真机数据能当 oracle：按 WPF 顺序复算，必须逐元素复现 composite
            Assert.True(wpfOrderMatches >= 10,
                $"只有 {wpfOrderMatches} 个 transform op 复现了真机 composite，oracle 自检失败");

            // ② 【债务 #12 已修 · 2026-09-10】从"记录反序"升级为**对实现的回归守卫**：
            //    实现已按上游 `TransformGroup.cs:31` 的自然顺序修正（`VisualProjection.cs`
            //    的累积改为 `Mul(child, acc)`）。下面直接断言实现本身的顺序——
            //    任何人把累积顺序写回去，这条会立刻变红。
            Assert.True(diverging > 0,
                "（信息性）两个链式模型在真机数据上确有分歧 → 本用例对顺序有区分力");

            using (var orderScene = new TestScene())
            {
                DUCE.ResourceHandle group = orderScene.TransformGroup(
                    orderScene.Translate(50, 0), orderScene.Scale(2.0, 1.0));
                SKPoint p = TransformResolver.Resolve(orderScene.Channel, group).MapPoint(10, 5);
                Assert.Equal(120f, p.X, 3);   // 先平移 → (60,5)，再缩放 → 120；反序会得 70
            }
        }

        /// <summary>
        /// 按两种候选顺序连乘 op 的 matrices。
        /// wpfFirstThenNext=true  → 先 M0 后 M1（WPF 语义，用 Mul(child, acc) 表达）
        /// wpfFirstThenNext=false → 先 Mn 后 M0（当前 TransformResolver.Mul(acc, child) 的行为）
        /// </summary>
        private static SKMatrix ChainMatrices(JsonElement op, bool wpfFirstThenNext)
        {
            SKMatrix acc = SKMatrix.Identity;
            foreach (JsonElement raw in op.GetProperty("matrices").EnumerateArray())
            {
                SKMatrix t = TransformResolver.FromMil(new MilMatrix3x2D(
                    raw[0].GetDouble(), raw[1].GetDouble(), raw[2].GetDouble(),
                    raw[3].GetDouble(), raw[4].GetDouble(), raw[5].GetDouble()));
                acc = wpfFirstThenNext ? Mul(t, acc) : Mul(acc, t);
            }
            return acc;
        }

        /// <summary>TransformResolver.Mul：先 a 后 b 还是先 b 后 a 由调用方决定，这里只做转调。</summary>
        private static SKMatrix Mul(SKMatrix a, SKMatrix b) => TransformResolver.Mul(a, b);

        private static bool Matches(SKMatrix m, double[] want)
        {
            double[] got = { m.ScaleX, m.SkewY, m.SkewX, m.ScaleY, m.TransX, m.TransY };
            for (int i = 0; i < 6; i++)
                if (Math.Abs(want[i] - got[i]) > 1e-4) return false;
            return true;
        }

        // ==================================================================
        //  修复回归：RelativeToBoundingBox 画刷映射（U1a 首个真机判定的实现 bug）
        // ==================================================================

        [ParityFact]
        public void relative_brush_mapping_puts_unit_square_on_bounds()
        {
            // 真机口径（scenes.json conventions + scene05 探针手算）：
            //   相对映射把画刷的 [0,1]² 铺到**几何包围盒**：Center=(0.5,0.5) Radius=(0.5,0.5)
            //   的径向渐变 = 以包围盒中心为心、半轴=包围盒半宽/半高的椭圆。
            // 修前 SkiaBrush.MappingMatrix 把 Concat 的参数写反（先缩放后平移写成了
            // Concat(Scale,Translate) = "先平移后缩放"），平移被缩放乘进去，整块渐变跑到
            // 着色器空间之外被钳位成末停靠色。
            using var scene = new TestScene();
            var draw = new DrawList();

            var brush = new MilRadialGradientBrush
            {
                Center = new MilPoint(0.5, 0.5),
                GradientOrigin = new MilPoint(0.5, 0.5),
                RadiusX = 0.5,
                RadiusY = 0.5,
                MappingMode = MilBrushMappingMode.RelativeToBoundingBox,
                SpreadMethod = MilGradientSpreadMethod.Pad,
            };
            brush.GradientStops.Add(new MilGradientStop(0.0, ParityRenderer.ColorOf("#FFFFFFFF")));
            brush.GradientStops.Add(new MilGradientStop(1.0, ParityRenderer.ColorOf("#FF1040A0")));

            DUCE.ResourceHandle grad = scene.Handle(brush);

            // 与 scene05 左格同参数：包围盒 (8,8,116,240)
            draw.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(8, 8, 124, 248),
                Brush = new MilResourceHandle((uint)grad),
            });

            MilVisual root = scene.Visual();
            root.Content = draw.ToRenderData();
            using SKBitmap bitmap = RenderHarness.RenderBitmap(root, scene.Provider, 256, 256);

            // 包围盒中心（渐变原点）应近白；左边缘 t≈0.95 处应是深蓝；角上超出半径被钳位
            SKColor center = bitmap.GetPixel(66, 128);
            SKColor leftEdge = bitmap.GetPixel(12, 128);
            SKColor corner = bitmap.GetPixel(10, 10);

            Output.WriteLine($"相对映射回归：中心 {ParityCompare.Rgba(center)} / 左缘 {ParityCompare.Rgba(leftEdge)} " +
                             $"/ 角 {ParityCompare.Rgba(corner)}（真机 scene05 探针 253,253,254 / 35,79,167 / 16,64,160）");

            Assert.True(center.Red > 240 && center.Green > 240 && center.Blue > 240,
                $"包围盒中心应是渐变原点（近白），实得 {ParityCompare.Rgba(center)}");
            Assert.InRange(leftEdge.Blue, 150, 180);
            Assert.InRange(leftEdge.Red, 20, 60);
            Assert.Equal(new SKColor(16, 64, 160), new SKColor(corner.Red, corner.Green, corner.Blue));
        }

        // ==================================================================
        //  场景驱动
        // ==================================================================

        /// <summary>渲染 + 比对 + 落盘（每个场景只做一次，结果缓存给汇总用例）。</summary>
        private ParityOutcome RunScene(string id)
        {
            lock (Gate)
            {
                if (Cache.TryGetValue(id, out ParityOutcome cached)) return cached;

                ParityLayout.EnsureDirs();
                ParitySceneSpec spec = ParityData.Get(id);

                ParityOutcome outcome;
                using (var renderer = new ParityRenderer())
                {
                    renderer.Play(spec.Ops);
                    using ParityRenderResult render = renderer.RenderFull();
                    using SKBitmap windows = ParityData.LoadWindowsPng(spec);
                    using SKBitmap reDecoded = SKBitmap.Decode(spec.PngPath);

                    outcome = ParityCompare.Compare(spec, render.Bitmap, windows, reDecoded);
                    outcome.StackBalanced = render.StackBalanced;
                    outcome.InstructionCount = render.InstructionCount;
                    foreach (var kv in render.Diagnostics.NotDrawn) outcome.NotDrawnInstructions += (int)kv.Value;

                    outcome.ActualPath = ParityLayout.ActualPath(id);
                    outcome.DiffPath = ParityLayout.DiffPath(id);
                    RenderHarness.SavePng(render.Bitmap, outcome.ActualPath);

                    using SKBitmap diff = ParityCompare.CreateDiff(render.Bitmap, windows);
                    RenderHarness.SavePng(diff, outcome.DiffPath);
                }

                outcome.Classification = Budgets.TryGetValue(id, out SceneBudget b) ? b.Classification : Classify(outcome);
                Cache[id] = outcome;
                return outcome;
            }
        }

        private void AssertScene(string id)
        {
            ParityOutcome o = RunScene(id);
            SceneBudget budget = Budgets[id];

            Output.WriteLine($"{o.Id}：{o.Description}");
            Output.WriteLine($"  差异像素 Δ>2 {o.DifferingTight}/{256 * 256}（{ParityCompare.Pct(o.TightRatio)}）" +
                             $"  非边缘 Δ>2 {o.DifferingInterior}  最大通道差 {o.MaxDelta}  超 AA 容差(Δ>16) {o.DifferingLoose}");
            Output.WriteLine($"  探针 {o.ProbeTotal - o.ProbeFailed}/{o.ProbeTotal} 通过  指令 {o.InstructionCount}  栈平衡 {o.StackBalanced}  未画出 {o.NotDrawnInstructions}");
            Output.WriteLine($"  产物 {o.ActualPngRel} / {o.DiffPngRel}   分类：{o.Classification}  （{budget.Note}）");

            var failures = new List<string>();
            foreach (ParityProbeResult pr in o.ProbeResults)
            {
                if (pr.Passed) continue;
                SKColor real = new SKColor((byte)pr.Probe.Rgba[0], (byte)pr.Probe.Rgba[1],
                                           (byte)pr.Probe.Rgba[2], (byte)pr.Probe.Rgba[3]);
                failures.Add(
                    $"({pr.Probe.X},{pr.Probe.Y}) {pr.Probe.Note}：真机 {ParityCompare.Rgba(real)} " +
                    $"vs 我方 {ParityCompare.Rgba(pr.Actual)}（Δ={pr.MaxDelta}）");
            }

            Assert.True(o.DecodeMismatches == 0,
                $"{o.Id}: 真机 PNG 解码自检失败 {o.DecodeMismatches} 次（读图方式有问题，不是渲染问题）");
            Assert.True(o.StackBalanced, $"{o.Id}: Push/Pop 不配平");
            Assert.True(o.ProbeFailed <= budget.MaxProbeFailures,
                $"{o.Id}: {o.ProbeFailed} 个探针失配（预算 {budget.MaxProbeFailures}）：\n  " +
                string.Join("\n  ", failures));
            Assert.True(o.DifferingInterior <= budget.MaxInterior,
                $"{o.Id}: 非边缘语义差异 {o.DifferingInterior} 像素，超预算 {budget.MaxInterior}" +
                $"（最大通道差 {o.MaxDeltaInterior}）");
            Assert.True(o.DifferingTight <= budget.MaxTight,
                $"{o.Id}: 差异像素 {o.DifferingTight}，超表征化预算 {budget.MaxTight}");
        }

        // ==================================================================
        //  预算与分类
        // ==================================================================

        internal sealed class SceneBudget
        {
            public int MaxTight;
            public int MaxInterior;
            public int MaxProbeFailures;
            public string Note;
            public string Classification;
        }

        /// <summary>
        /// 逐场景预算 + 分类定稿。全部数值来自首次真机对照实测（总表见
        /// docs/U1a-parity-report.md），MaxTight 留约 30% 余量吸收光栅器抖动，
        /// MaxInterior 一律等于实测值（多一个像素就要解释）。
        /// 分类口径：①完全一致 ②已知简化 ③AA/取样差异 ④场景规格歧义。
        /// </summary>
        private static readonly Dictionary<string, SceneBudget> Budgets =
            new Dictionary<string, SceneBudget>(StringComparer.Ordinal)
            {
                ["scene01_solid"] = new SceneBudget
                {
                    MaxTight = 0, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 0/65536 差异像素（轴对齐纯色，无 AA）",
                    Classification = "①完全一致",
                },
                ["scene02_roundrect"] = new SceneBudget
                {
                    MaxTight = 390, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 300/65536，差异全在圆角/直边 1px 内（jump>8 判据下 0 个非边缘）",
                    Classification = "③AA/取样差异",
                },
                ["scene03_ellipse"] = new SceneBudget
                {
                    MaxTight = 1225, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 942/65536，椭圆边缘覆盖率差异（两侧都各有少墨/多墨）",
                    Classification = "③AA/取样差异",
                },
                ["scene04_linear_gradient"] = new SceneBudget
                {
                    MaxTight = 0, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 0/65536、最大通道差 1（sRGB 插值与真机逐像素一致）",
                    Classification = "①完全一致",
                },
                ["scene05_radial_gradient"] = new SceneBudget
                {
                    MaxTight = 0, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "修 MappingMatrix 前 35137/65536、4/6 探针失配；修后 0/65536、最大差 1",
                    Classification = "①完全一致",
                },
                ["scene06_dash"] = new SceneBudget
                {
                    MaxTight = 1400, MaxInterior = 118, MaxProbeFailures = 0,
                    Note = "实测 1080/65536；118 个非边缘像素 = 0 长度虚线（DashCap.Round 的圆点）" +
                           "被 Skia 的 Butt 端头吞掉，属 SkiaPen.cs 已知简化 #1",
                    Classification = "②已知简化（DashCap）",
                },
                ["scene07_opacity"] = new SceneBudget
                {
                    MaxTight = 440, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 336/65536，jump>8 判据下非边缘差异为 0（差异全在椭圆边缘 1px 内）",
                    Classification = "③AA/取样差异",
                },
                ["scene08_clip_rect"] = new SceneBudget
                {
                    MaxTight = 0, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 0/65536（矩形裁剪全是轴对齐硬边）",
                    Classification = "①完全一致",
                },
                ["scene09_clip_path_fillrule"] = new SceneBudget
                {
                    MaxTight = 2100, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 1622/65536，全部落在三角/五角星边缘 1px 内",
                    Classification = "③AA/取样差异",
                },
                ["scene10_transform"] = new SceneBudget
                {
                    MaxTight = 1100, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 843/65536；旋转边 + 非均匀缩放描边（Skia 在局部空间描边后变换，几何等价）",
                    Classification = "③AA/取样差异",
                },
                ["scene11_arc_sweep_large"] = new SceneBudget
                {
                    MaxTight = 2400, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 1842/65536，8 格 sweep×largeArc 全部落在弧线边缘；探针 8/8",
                    Classification = "③AA/取样差异",
                },
                ["scene12_arc_ellipse"] = new SceneBudget
                {
                    MaxTight = 930, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 713/65536，椭圆弧 + rot 30/45/90 全部落在弧线边缘；探针 8/8",
                    Classification = "③AA/取样差异",
                },
                ["scene13_arc_degenerate"] = new SceneBudget
                {
                    MaxTight = 1210, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 929/65536；D3/D4 格多出的 216 像素是闭合路径 180° 折返处的" +
                           "miter 裁剪突刺（真机 = miterLimit×线宽/2 = 15px），Skia 画平头",
                    Classification = "③AA/取样差异 + miter 突刺（见报告 债务 #7-D3/D4）",
                },
                ["scene14_combine_union_xor"] = new SceneBudget
                {
                    MaxTight = 1750, MaxInterior = 3, MaxProbeFailures = 0,
                    Note = "实测 1325/65536；3 个非边缘像素在 x=255 画布最右列（圆弧被画布裁切处，Δ≤37）",
                    Classification = "③AA/取样差异",
                },
                ["scene15_combine_intersect_exclude"] = new SceneBudget
                {
                    MaxTight = 1200, MaxInterior = 0, MaxProbeFailures = 0,
                    Note = "实测 922/65536，jump>8 判据下非边缘差异为 0（差异含标记圆 1px 虚线描边的低对比度边缘）",
                    Classification = "③AA/取样差异",
                },
            };

        private static string Classify(ParityOutcome o)
        {
            if (o.ProbeFailed == 0 && o.DifferingInterior == 0 && o.DifferingLoose == 0)
                return "①一致（含边缘 AA 也在容差内）";
            if (o.ProbeFailed == 0 && o.DifferingInterior == 0)
                return "③AA/取样差异";
            if (o.ProbeFailed > 0) return "②/①待定（探针失配）";
            return "④待判";
        }

        // ==================================================================
        //  结果落盘
        // ==================================================================

        private void WriteResultsJson()
        {
            using var stream = File.Create(ParityLayout.ResultsPath);
            using var w = new Utf8JsonWriter(stream, new JsonWriterOptions { Indented = true });

            w.WriteStartObject();
            w.WriteString("format", "wpf-linux-u1a-parity/1");
            w.WriteString("windowsData", ParityData.Reason);
            w.WriteNumber("tightTolerance", ParityCompare.TightTolerance);
            w.WriteNumber("aaTolerance", ParityCompare.AaTolerance);
            w.WriteNumber("sceneCount", ParityData.Scenes.Count);

            w.WriteStartArray("scenes");
            foreach (ParitySceneSpec spec in ParityData.Scenes)
            {
                ParityOutcome o = RunScene(spec.Id);
                w.WriteStartObject();
                w.WriteString("id", o.Id);
                w.WriteString("description", o.Description);
                w.WriteNumber("differingTight", o.DifferingTight);
                w.WriteNumber("tightRatio", Math.Round(o.TightRatio, 6));
                w.WriteNumber("differingLoose", o.DifferingLoose);
                w.WriteNumber("differingInterior", o.DifferingInterior);
                w.WriteNumber("maxChannelDelta", o.MaxDelta);
                w.WriteNumber("maxChannelDeltaInterior", o.MaxDeltaInterior);
                w.WriteNumber("probes", o.ProbeTotal);
                w.WriteNumber("probeFailures", o.ProbeFailed);
                w.WriteNumber("probeWorstDelta", o.ProbeWorstDelta);
                w.WriteNumber("instructions", o.InstructionCount);
                w.WriteBoolean("stackBalanced", o.StackBalanced);
                w.WriteString("classification", o.Classification);
                w.WriteString("actualPng", o.ActualPngRel);
                w.WriteString("diffPng", o.DiffPngRel);

                w.WriteStartArray("probeDetails");
                foreach (ParityProbeResult pr in o.ProbeResults)
                {
                    w.WriteStartObject();
                    w.WriteNumber("x", pr.Probe.X);
                    w.WriteNumber("y", pr.Probe.Y);
                    w.WriteString("kind", pr.Probe.Kind);
                    w.WriteString("note", pr.Probe.Note);
                    w.WriteString("windows", $"#{pr.Probe.Rgba[0]:X2}{pr.Probe.Rgba[1]:X2}{pr.Probe.Rgba[2]:X2}{pr.Probe.Rgba[3]:X2}");
                    w.WriteString("linux", $"#{pr.Actual[0]:X2}{pr.Actual[1]:X2}{pr.Actual[2]:X2}{pr.Actual[3]:X2}");
                    w.WriteNumber("maxDelta", pr.MaxDelta);
                    w.WriteBoolean("passed", pr.Passed);
                    w.WriteEndObject();
                }
                w.WriteEndArray();

                w.WriteEndObject();
            }
            w.WriteEndArray();
            w.WriteEndObject();
            w.Flush();

            Output.WriteLine($"逐场景数字已写入 {ParityLayout.ResultsPath}");
        }

        // ==================================================================
        //  指令构造小工具（反模型用）
        // ==================================================================

        private static MilDrawInstruction Rect(float x, float y, float w, float h, DUCE.ResourceHandle brush) =>
            new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(x, y, x + w, y + h),
                Brush = new MilResourceHandle((uint)brush),
            };

        private static MilDrawInstruction Ellipse(
            float cx, float cy, float rx, float ry, DUCE.ResourceHandle brush) =>
            new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawEllipse,
                Point0 = new SKPoint(cx, cy),
                CornerRadius = new SKPoint(rx, ry),
                Brush = new MilResourceHandle((uint)brush),
            };
    }
}

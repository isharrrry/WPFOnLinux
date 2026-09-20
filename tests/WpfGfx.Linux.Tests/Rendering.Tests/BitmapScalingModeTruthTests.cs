// BitmapScalingMode 与 WPF 真机的**变体对照**断言（T2b，批次2 oracle）。
//
// 【判据形态为什么是"变体对照"而不是绝对 hex】
//   我们的采样是 Skia 的定点双线性，与 WPF 的缩放核**处处差 Δ≤1**（隔离实验：Δ>1 的像素为 0，
//   见 TileFlipTruthTests 里规则7 缺口的注释）。所以逐点等 hex 在本层不可达；
//   而"**A 档与 B 档是相同还是不同**"这个关系**不依赖那 1 个 LSB**，是稳的、可判的。
//   真值来自 windows-results-2.json 的 `variantComparisons`（真机同一对用例的差异**采样点数**）。
//
// 【防空真】"两者相同"在"两边都没画出来"时也会成立 ⇒ 每个用例都先断言
//   渲染结果**不是整片背景**（有真实内容），且差异型断言会反向锁住"旋钮确实接通了"。
//
// 【真机口径（批次2）】
//   · `Unspecified ≡ Linear`：放大 0 点差异、缩小 0 点差异 ⇒ 默认档必须按双线性实现；
//   · `NearestNeighbor` vs `Linear`：放大 68 点、缩小 187 点 ⇒ NN 必须真是最近邻；
//   · `Linear vs HighQuality`：放大 **0 点**（High 在放大时退化成 Linear）、缩小 **409 点**；
//   · **矢量源（DrawingBrush）放大时四档全同**（矢量不走位图滤波）。

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class BitmapScalingModeTruthTests
    {
        public BitmapScalingModeTruthTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        private const int Canvas = 256;

        // ==================================================================
        //  ① 默认档 = Linear（真机 Unspecified ≡ Linear，0 点差异）
        //     两轴都断言：放大 0、缩小 0。
        // ==================================================================
        [Theory]
        [InlineData("up")]
        [InlineData("down")]
        public void unspecified_is_identical_to_linear(string scale)
        {
            ComparePair($"b2_scale_{scale}_image_unspecified", $"b2_scale_{scale}_image_linear",
                        mustDiffer: false, label: $"Unspecified vs Linear（{scale}）");
        }

        // ==================================================================
        //  ② 放大档不用 High（真机 Linear vs HighQuality 放大 0 点差异）
        //     —— 这是本轮实测独立支持的一条映射：High 在放大时退化成 Linear。
        // ==================================================================
        [Fact]
        public void highquality_degrades_to_linear_when_magnifying()
        {
            ComparePair("b2_scale_up_image_linear", "b2_scale_up_image_highquality",
                        mustDiffer: false, label: "Linear vs HighQuality（放大）");
        }

        // ==================================================================
        //  ③ 最近邻必须真是最近邻（真机 NN vs Linear：放大 68、缩小 187）
        // ==================================================================
        [Theory]
        [InlineData("up")]
        [InlineData("down")]
        public void nearestneighbor_differs_from_linear(string scale)
        {
            ComparePair($"b2_scale_{scale}_image_nearestneighbor", $"b2_scale_{scale}_image_linear",
                        mustDiffer: true, label: $"NearestNeighbor vs Linear（{scale}）");
        }

        // ==================================================================
        //  ④ HighQuality 只在**缩小**时与 Linear 不同（真机缩小 409 点差异）
        // ==================================================================
        [Fact]
        public void highquality_differs_from_linear_when_minifying()
        {
            ComparePair("b2_scale_down_image_linear", "b2_scale_down_image_highquality",
                        mustDiffer: true, label: "Linear vs HighQuality（缩小）");
        }

        // ==================================================================
        //  ⑤ 矢量源：放大时四档全同（真机 DrawingBrush 四档无差异）
        //     这条同时是 ①②③ 的对照 —— 位图档的差异必须来自位图滤波，不是别处。
        // ==================================================================
        [Fact]
        public void vector_source_ignores_bitmap_scaling_mode()
        {
            string[] ids =
            {
                "b2_scale_up_drawing_unspecified", "b2_scale_up_drawing_linear",
                "b2_scale_up_drawing_nearestneighbor", "b2_scale_up_drawing_highquality",
            };
            var rendered = new List<(string Id, SKBitmap Bmp)>();
            try
            {
                foreach (string id in ids) rendered.Add((id, RenderCase(id)));

                // 防空真：基准那一档必须真的画了东西
                AssertPainted(rendered[0].Bmp, ids[0]);

                for (int i = 1; i < rendered.Count; i++)
                {
                    int diff = CountDiffering(rendered[0].Bmp, rendered[i].Bmp, PointsOf(ids[0]));
                    Output.WriteLine($"  {ids[0]} vs {rendered[i].Id}：差异采样点 {diff}");
                    Assert.True(diff == 0,
                        $"矢量源（DrawingBrush）放大时四档应全同，但 {rendered[i].Id} 与 {ids[0]} " +
                        $"差了 {diff} 个采样点 —— 规则7 的「矢量源不走位图滤波」被破坏。");
                }
            }
            finally { foreach ((string _, SKBitmap b) in rendered) b.Dispose(); }
        }

        // ==================================================================
        //  实现：按 oracle 的 case id 重放该用例，并与 oracle 的 variantComparisons 对齐
        // ==================================================================
        private void ComparePair(string idA, string idB, bool mustDiffer, string label)
        {
            int oracleDiff = OracleDifferingSamples(idA, idB);

            using SKBitmap a = RenderCase(idA);
            using SKBitmap b = RenderCase(idB);
            AssertPainted(a, idA);
            AssertPainted(b, idB);

            int ourDiff = CountDiffering(a, b, PointsOf(idA));
            Output.WriteLine($"  [{label}] 真机差异采样点 {oracleDiff}，我们 {ourDiff}");

            if (mustDiffer)
            {
                Assert.True(oracleDiff > 0, $"oracle 说 {idA} 与 {idB} 无差异，用例选错了");
                Assert.True(ourDiff > 0,
                    $"{label}：真机在 {oracleDiff} 个采样点上不同，我们却是 0 —— " +
                    "BitmapScalingMode 没有真正接到采样上（旋钮没接通）。");
            }
            else
            {
                Assert.True(oracleDiff == 0,
                    $"oracle 说 {idA} 与 {idB} 有 {oracleDiff} 点差异，不该断言相同");
                Assert.True(ourDiff == 0,
                    $"{label}：真机逐点相同（0 差异），我们却有 {ourDiff} 个采样点不同。");
            }
        }

        /// <summary>防空真：整片背景 = 什么都没画 ⇒ 「两档相同」这类断言会变成空真。</summary>
        private void AssertPainted(SKBitmap bmp, string caseId)
        {
            var bg = new SKColor(0x80, 0x80, 0x80);
            int nonBg = 0;
            for (int y = 16; y < 136 && nonBg < 50; y++)
                for (int x = 16; x < 216 && nonBg < 50; x++)
                    if (bmp.GetPixel(x, y) != bg) nonBg++;

            Assert.True(nonBg >= 50,
                $"{caseId}：目标区域内几乎没有非背景像素（只有 {nonBg} 个）—— 渲染是空的，" +
                "后面「两档相同」的断言会变成空真。");
        }

        private static int CountDiffering(SKBitmap a, SKBitmap b, List<(int X, int Y)> pts)
        {
            int n = 0;
            foreach ((int x, int y) in pts)
                if (a.GetPixel(x, y) != b.GetPixel(x, y)) n++;
            return n;
        }

        // ---- oracle 读取 ----

        private static JsonDocument _doc;
        private static JsonDocument Doc()
        {
            if (_doc != null) return _doc;
            string path = Path.Combine(RepoLayout.RootPath, "tests", "parity", "brushes", "windows-results-2.json");
            Assert.True(File.Exists(path), $"批次2 oracle 不在预期位置：{path}");
            _doc = JsonDocument.Parse(File.ReadAllText(path));
            return _doc;
        }

        private static JsonElement Case(string id)
        {
            foreach (JsonElement c in Doc().RootElement.GetProperty("cases").EnumerateArray())
                if (c.GetProperty("id").GetString() == id) return c;
            throw new Xunit.Sdk.XunitException($"批次2 oracle 里找不到用例 {id}");
        }

        private static int OracleDifferingSamples(string idA, string idB)
        {
            foreach (JsonElement v in Doc().RootElement.GetProperty("variantComparisons").EnumerateArray())
            {
                string a = v.GetProperty("a").GetString(), b = v.GetProperty("b").GetString();
                if ((a == idA && b == idB) || (a == idB && b == idA))
                    return v.GetProperty("differingSamples").GetInt32();
            }
            throw new Xunit.Sdk.XunitException($"variantComparisons 里找不到 {idA} vs {idB}");
        }

        private static readonly Dictionary<string, List<(int, int)>> _pointCache = new();
        private static List<(int, int)> PointsOf(string id)
        {
            if (_pointCache.TryGetValue(id, out List<(int, int)> cached)) return cached;
            var list = new List<(int, int)>();
            foreach (JsonElement s in Case(id).GetProperty("samples").EnumerateArray())
                list.Add((s.GetProperty("x").GetInt32(), s.GetProperty("y").GetInt32()));
            _pointCache[id] = list;
            return list;
        }

        // ---- 渲染（参数全部照抄 cases-2.json）----

        private static SKBitmap RenderCase(string id)
        {
            JsonElement c = Case(id);
            // 档位**直接从真值文件读**（bitmapScalingModeRequested），不从 id 猜
            JsonElement _modeEl = c.GetProperty("bitmapScalingModeRequested");
            MilBitmapScalingMode mode = ParseScaling(
                _modeEl.ValueKind == JsonValueKind.Null ? null : _modeEl.GetString());
            MilTileMode tileMode = Enum.Parse<MilTileMode>(c.GetProperty("tileModeDeclared").GetString());
            bool imageSource = c.GetProperty("source").GetString() != "drawing";

            MilRect vp = Rect(c.GetProperty("viewport"));
            MilBrushMappingMode vpUnits = Units(c.GetProperty("viewportUnits").GetString());
            MilRect vb = Rect(c.GetProperty("viewbox"));
            MilBrushMappingMode vbUnits = Units(c.GetProperty("viewboxUnits").GetString());
            MilStretch stretch = Enum.Parse<MilStretch>(c.GetProperty("stretch").GetString());
            double[] target = RectArr(c.GetProperty("targetRectDevice"));   // dpi=96 ⇒ 设备像素 == DIU

            using var scene = new TestScene();

            DUCE.ResourceHandle brush;
            if (imageSource)
            {
                SKBitmap pattern = Pattern32();
                scene.Own(pattern);
                DUCE.ResourceHandle src = scene.BitmapSourceHandle();
                scene.Provider.BitmapResolver = _ => pattern;
                brush = scene.ImageBrush(src, stretch, tileMode,
                    viewbox: vb, viewport: vp,
                    viewportUnits: vpUnits, viewboxUnits: vbUnits);
            }
            else
            {
                DUCE.ResourceHandle drawing = PatternDrawing(scene);
                brush = scene.Add(new MilDrawingBrush
                {
                    Drawing = drawing, Stretch = stretch, TileMode = tileMode,
                    Viewbox = vb, Viewport = vp,
                    ViewportUnits = vpUnits, ViewboxUnits = vbUnits,
                    AlignmentX = MilAlignmentX.Center, AlignmentY = MilAlignmentY.Center,
                });
            }

            DUCE.ResourceHandle background = scene.Solid(0x80, 0x80, 0x80);
            MilVisual root = scene.Visual();
            root.RenderOptions = new MilRenderOptions { BitmapScalingMode = mode };
            root.Content = scene.RenderData(d =>
            {
                d.Add(Rect(0, 0, Canvas, Canvas, background));
                d.Add(Rect((float)target[0], (float)target[1], (float)target[2], (float)target[3], brush));
            });

            return RenderHarness.RenderBitmap(root, scene.Provider, Canvas, Canvas, antialias: true);
        }

        /// <summary>
        /// ⚠ `Unspecified` 档在真值文件里是 **JSON null**（WPF 侧没给元素设 RenderOptions，
        /// 取的就是默认值）—— 所以 null 必须映射成 `Unspecified`，不能当异常。
        /// </summary>
        private static MilBitmapScalingMode ParseScaling(string name) => name switch
        {
            null => MilBitmapScalingMode.Unspecified,
            "Unspecified" => MilBitmapScalingMode.Unspecified,
            "Linear" => MilBitmapScalingMode.Linear,
            "NearestNeighbor" => MilBitmapScalingMode.NearestNeighbor,
            "HighQuality" => MilBitmapScalingMode.HighQuality,
            "LowQuality" => MilBitmapScalingMode.LowQuality,
            "Fant" => MilBitmapScalingMode.Fant,
            _ => throw new ArgumentOutOfRangeException(nameof(name), name, "未知 BitmapScalingMode"),
        };

        private static double[] RectArr(JsonElement a) =>
            new[] { a[0].GetDouble(), a[1].GetDouble(), a[2].GetDouble(), a[3].GetDouble() };

        private static MilRect Rect(JsonElement a) =>
            new MilRect(a[0].GetDouble(), a[1].GetDouble(), a[2].GetDouble(), a[3].GetDouble());

        private static MilBrushMappingMode Units(string s) =>
            s == "Absolute" ? MilBrushMappingMode.Absolute : MilBrushMappingMode.RelativeToBoundingBox;

        /// <summary>与 oracle `Sources.cs` 的 `MakeBitmap` 逐像素同法（像素中心采样、硬边、含紫三角）。</summary>
        private static SKBitmap Pattern32()
        {
            var bmp = new SKBitmap(new SKImageInfo(32, 32, SKColorType.Rgba8888, SKAlphaType.Premul));
            for (int y = 0; y < 32; y++)
            {
                for (int x = 0; x < 32; x++)
                {
                    double cx = x + 0.5, cy = y + 0.5;
                    (byte r, byte g, byte b) col = (0x20, 0x28, 0x30);
                    foreach ((double fx, double fy, double fw, double fh, byte fr, byte fg, byte fb) f in Features())
                        if (cx >= f.fx && cx < f.fx + f.fw && cy >= f.fy && cy < f.fy + f.fh)
                            col = (f.fr, f.fg, f.fb);
                    if (cx >= 12 && cy >= 12 && (cx - 12) + (cy - 12) < 8) col = (0x80, 0x40, 0xFF);
                    bmp.SetPixel(x, y, new SKColor(col.r, col.g, col.b));
                }
            }
            return bmp;
        }

        private static DUCE.ResourceHandle PatternDrawing(TestScene scene)
        {
            var children = new List<DUCE.ResourceHandle>();
            foreach ((double x, double y, double w, double h, byte r, byte g, byte b) f in Features())
            {
                DUCE.ResourceHandle fill = scene.Solid(f.r, f.g, f.b);
                children.Add(scene.Add(new MilGeometryDrawing
                {
                    Geometry = scene.RectGeometry(f.x, f.y, f.w, f.h),
                    Brush = fill,
                    Pen = default,
                }));
            }
            var group = new MilDrawingGroup { Opacity = 1.0 };
            foreach (DUCE.ResourceHandle ch in children) group.Children.Add(ch);
            return scene.Add(group);
        }

        private static IEnumerable<(double x, double y, double w, double h, byte r, byte g, byte b)> Features()
        {
            yield return (0, 0, 32, 32, 0x20, 0x28, 0x30);
            yield return (0, 0, 12, 12, 0xD0, 0x20, 0x20);
            yield return (20, 0, 12, 12, 0x20, 0xA0, 0x40);
            yield return (0, 20, 12, 12, 0x20, 0x50, 0xD0);
            yield return (20, 20, 12, 12, 0xE0, 0xC0, 0x20);
            yield return (2, 10, 4, 10, 0xFF, 0x00, 0xFF);
            yield return (10, 2, 10, 4, 0x00, 0xFF, 0xFF);
            yield return (24, 4, 3, 3, 0xFF, 0xFF, 0xFF);
        }

        private static MilDrawInstruction Rect(float x, float y, float w, float h, DUCE.ResourceHandle brush) =>
            new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(x, y, x + w, y + h),
                Brush = new MilResourceHandle((uint)brush),
            };
    }
}

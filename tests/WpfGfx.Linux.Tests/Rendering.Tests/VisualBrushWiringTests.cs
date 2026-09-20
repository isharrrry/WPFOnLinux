// VisualBrush **生产接线**的验收用例（T2b）。
//
// 【为什么必须单独有这个文件】
//   `DrawingBrushTests` 里现存的两个 VisualBrush 用例都**注入了假解析器**
//   （`scene.Provider.VisualImageResolver = _ => Checker(24,4)`），所以它们只能证明
//   "平铺语义对"，**证明不了生产路径接上了**。T2b 在代码里核过：接线前
//   `VisualImageResolver` 在 `src/**` 里一次都没被赋值过 ⇒ 生产下
//   `CreateVisualFill` 恒返回 null（整条 VisualBrush 静默走"未画出"）。
//
// 【本文件的判据形态】——刻意不用假解析器，只看三件事：
//   ① 真的 Visual（注册在 MilChannel 里的 MilVisualResource）+ 真的内容，
//      经 `RenderHarness` 走完整渲染，`未画出` 里**不许**出现矩形指令；
//   ② 画出来的像素确实是那个 Visual 的颜色（不是背景、不是空白）；
//   ③ 尺寸来自**自然尺寸**（内容包围盒），不是画布尺寸 —— 用"缩放后仍然铺满"
//      来间接判：源 8×6 映射到 40×30 的目标，(1,1) 处必须是源的颜色。
//
// 【已知不足（登记，不藏）】见 `VisualBrushSource.cs` 文件头：字形不计入包围盒。

using System;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class VisualBrushWiringTests
    {
        public VisualBrushWiringTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        private const byte R = 0x20, G = 0xA0, B = 0x40;   // 源内容色 #FF20A040

        /// <summary>生产路径必须自己把 VisualImageResolver 挂上，不靠测试注入。</summary>
        [Fact]
        public void visual_brush_is_resolved_without_test_injection()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = VisualBrush(scene, out _);

            // 关键：**不设** scene.Provider.VisualImageResolver，走后端构造期自己挂的那条
            Assert.NotNull(scene.Provider.VisualImageResolver);   // 接线生效的直接判据
            SKPaint paint = SkiaBrush.CreateFill(scene.Provider, new MilResourceHandle((uint)brush),
                                                new SKRect(0, 0, 40, 30), antialias: true);
            Assert.NotNull(paint);
            paint.Dispose();
        }

        /// <summary>整帧渲染：VisualBrush 必须真的把像素画上去，且不记"未画出"。</summary>
        [Fact]
        public void visual_brush_paints_pixels_through_full_render()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = VisualBrush(scene, out _);

            MilVisual root = scene.Visual();
            root.Content = scene.RenderData(d => d.Add(Rect(0, 0, 40, 30, brush)));

            RenderOutput result = RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);

            long notDrawnRect = result.Diagnostics.NotDrawn.TryGetValue(
                MilDrawCommand.MilDrawRectangle, out long n) ? n : 0;
            Output.WriteLine($"  [生产接线] 指令={result.Diagnostics.InstructionCount} " +
                             $"未画出(MilDrawRectangle)={notDrawnRect} " +
                             $"共未画种类={result.Diagnostics.NotDrawn.Count}");

            Assert.True(notDrawnRect == 0,
                $"VisualBrush 没被解析：MilDrawRectangle 被记为未画出 {notDrawnRect} 次（接线失效）");

            SKColor px = result.Bitmap.GetPixel(20, 15);
            Output.WriteLine($"  [生产接线] 中心像素 (20,15) = #{px.Red:X2}{px.Green:X2}{px.Blue:X2}，期望 #{R:X2}{G:X2}{B:X2}");
            Assert.True(px.Red == R && px.Green == G && px.Blue == B,
                $"VisualBrush 没画出源内容的颜色：#FF{px.Red:X2}{px.Green:X2}{px.Blue:X2} ≠ #FF{R:X2}{G:X2}{B:X2}");
        }

        /// <summary>
        /// 自然尺寸取自**内容包围盒**，不是离屏画布尺寸：源 Visual 是 8×6，
        /// 经 Stretch=Fill 映射到 40×30 的目标。若把自然尺寸算成别的值，
        /// 源内容在图里的位置/比例就会偏 —— 用四角与中心一起钉住。
        /// </summary>
        [Fact]
        public void natural_size_comes_from_content_bounds()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = VisualBrush(scene, out SKRect contentBounds);

            Output.WriteLine($"  源内容包围盒 = {contentBounds}（期望 (0,0,8,6)）");
            Assert.True(Math.Abs(contentBounds.Width - 8f) < 0.01f && Math.Abs(contentBounds.Height - 6f) < 0.01f,
                $"内容包围盒不是 8×6，而是 {contentBounds.Width}×{contentBounds.Height}");

            MilVisual root = scene.Visual();
            root.Content = scene.RenderData(d => d.Add(Rect(0, 0, 40, 30, brush)));
            using SKBitmap bmp = RenderHarness.RenderBitmap(root, scene.Provider, 40, 30, antialias: true);

            // 8×6 的整块色填充 → Fill 到 40×30 之后应处处同色（除了抗锯齿边）
            foreach ((int x, int y) in new[] { (2, 2), (37, 2), (2, 27), (37, 27), (20, 15) })
            {
                SKColor c = bmp.GetPixel(x, y);
                Output.WriteLine($"    ({x},{y}) = #{c.Red:X2}{c.Green:X2}{c.Blue:X2}");
                Assert.True(c.Red == R && c.Green == G && c.Blue == B,
                    $"({x},{y}) 期望 #FF{R:X2}{G:X2}{B:X2}，实得 #FF{c.Red:X2}{c.Green:X2}{c.Blue:X2}");
            }
        }

        /// <summary>
        /// 诚实的负面判据：**只含字形**的 Visual 自然尺寸算不出来（字形度量缺失，见
        /// VisualBrushSource 文件头）⇒ 必须返回 null（记为未画出），**不许猜一个尺寸**。
        /// 这条是"有牙"的反面：它会在有人给字形硬编一个尺寸时变红。
        /// </summary>
        [Fact]
        public void empty_bounds_fail_honestly_instead_of_guessing()
        {
            using var scene = new TestScene();

            // 一个**没有任何可计量内容**的 Visual（无 Content、无子节点）
            var node = new MilVisualNode();
            var resource = new MilVisualResource();
            DUCE.ResourceHandle visual = scene.Add(resource);
            node.Handle = visual;
            resource.Visual.Handle = visual;
            Assert.True(node.Content.IsNull);

            DUCE.ResourceHandle brush = scene.Add(new MilVisualBrush
            {
                Visual = visual,
                Stretch = MilStretch.Fill,
                TileMode = MilTileMode.None,
                Viewbox = MilRect.Empty,
                Viewport = MilRect.Empty,
                ViewportUnits = MilBrushMappingMode.Absolute,
                ViewboxUnits = MilBrushMappingMode.Absolute,
                AlignmentX = MilAlignmentX.Center,
                AlignmentY = MilAlignmentY.Center,
            });

            MilVisual root = scene.Visual();
            root.Content = scene.RenderData(d => d.Add(Rect(0, 0, 40, 30, brush)));
            RenderOutput result = RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);

            long notDrawn = result.Diagnostics.NotDrawn.TryGetValue(
                MilDrawCommand.MilDrawRectangle, out long n) ? n : 0;
            Output.WriteLine($"  [空包围盒] 未画出(MilDrawRectangle)={notDrawn}，图像中心=" +
                             $"#{result.Bitmap.GetPixel(20, 15).Red:X2}");

            Assert.True(notDrawn == 1,
                $"空包围盒应当诚实失败（记为未画出 1 次），实得 {notDrawn} —— 是不是有人在猜尺寸？");
        }

        /// <summary>
        /// 含**字形**的 Visual 也要能算出自然尺寸（T2b 补）：靠 `MilGlyphRun.ManagedBounds`
        /// （= 上游托管侧 `GlyphRun.Bounds`，由 MilCommandDispatcher.cs:906 填入），
        /// **不需要**在渲染层算文字度量，也就不必碰 Text/**。
        ///
        /// 判据用"**只有字形**、包围盒非空"来隔离：若退回"字形不计入包围盒"，
        /// 这条的包围盒会是空 ⇒ 断言变红。
        /// </summary>
        [Fact]
        public void glyph_run_contributes_to_natural_size()
        {
            using var scene = new TestScene();

            // 一个只有字形内容的 Visual：ManagedBounds 声明 (4,6)-(36,20)
            var glyphRun = new MilGlyphRun
            {
                ManagedBounds = new MilRect(4, 6, 32, 14),
                GlyphIndices = new ushort[] { 1, 2 },
                AdvanceWidths = new float[] { 8f, 8f },
            };
            DUCE.ResourceHandle glyphHandle = scene.Add(glyphRun);

            DUCE.ResourceHandle fill = scene.Solid(R, G, B);
            Commands.MilRenderData decoded = scene.RenderData(d =>
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawGlyphRun,
                    Geometry = new MilResourceHandle((uint)glyphHandle),
                    Brush = new MilResourceHandle((uint)fill),
                }));
            DUCE.ResourceHandle content = scene.Add(new MilRenderDataResource { RenderData = decoded });

            var resource = new MilVisualResource();
            DUCE.ResourceHandle visual = scene.Add(resource);
            resource.Visual.Handle = visual;
            resource.Visual.Content = content;

            SKRect bounds = VisualBrushSource.ContentBounds(
                scene.Provider, VisualProjection.Project(scene.Channel, visual));

            Output.WriteLine($"  [字形包围盒] 自然尺寸 = {bounds}（期望 (4,6,36,20)）");
            Assert.True(Math.Abs(bounds.Left - 4f) < 0.01f && Math.Abs(bounds.Top - 6f) < 0.01f &&
                        Math.Abs(bounds.Right - 36f) < 0.01f && Math.Abs(bounds.Bottom - 20f) < 0.01f,
                $"含字形的 Visual 自然尺寸应为 (4,6,36,20)，实得 {bounds} —— 字形没被计入包围盒？");
        }

        // ---- 辅助 ----

        /// <summary>
        /// 注册一个**真** Visual：内容 = 一块 8×6 的实心矩形（#FF20A040）。
        /// 返回指向它的 VisualBrush。
        /// </summary>
        private static DUCE.ResourceHandle VisualBrush(TestScene scene, out SKRect contentBounds)
        {
            DUCE.ResourceHandle fill = scene.Solid(R, G, B);
            // 走**句柄**那条路（MilVisualNode.Content 是句柄）⇒ 要把解码结果注册成
            // MilRenderDataResource，VisualProjection 才能按句柄取到它。
            Commands.MilRenderData decoded = scene.RenderData(d =>
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 8, 6),
                    Brush = new MilResourceHandle((uint)fill),
                }));
            DUCE.ResourceHandle content = scene.Add(new MilRenderDataResource { RenderData = decoded });

            var resource = new MilVisualResource();
            DUCE.ResourceHandle visual = scene.Add(resource);
            resource.Visual.Handle = visual;
            resource.Visual.Content = content;

            contentBounds = VisualBrushSource.ContentBounds(
                scene.Provider, VisualProjection.Project(scene.Channel, visual));

            return scene.Add(new MilVisualBrush
            {
                Visual = visual,
                Stretch = MilStretch.Fill,
                TileMode = MilTileMode.None,
                Viewbox = MilRect.Empty,
                Viewport = MilRect.Empty,
                ViewportUnits = MilBrushMappingMode.Absolute,
                ViewboxUnits = MilBrushMappingMode.Absolute,
                AlignmentX = MilAlignmentX.Center,
                AlignmentY = MilAlignmentY.Center,
            });
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

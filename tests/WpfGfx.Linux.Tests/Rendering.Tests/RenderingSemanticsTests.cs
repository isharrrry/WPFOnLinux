// 不依赖 golden 的断言式渲染测试。
//
// golden 适合验证"长成什么样"，但有些性质更适合直接断言：
//   · 矩阵语义（旋转方向、变换链顺序）
//   · 资源/视觉投影正确性
//   · Push/Pop 配平
//   · *Animate 静态终值与静态版逐像素一致
//   · 图像比较器本身的 sanity

using System;
using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using Xunit;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class RenderingSemanticsTests
    {
        // ==================================================================
        //  资源解析
        // ==================================================================

        [Fact]
        public void Lookup_returns_typed_resource()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle h = scene.Solid(0x12, 0x34, 0x56);

            object obj = scene.Provider.Lookup(new MilResourceHandle((uint)h));
            Assert.IsType<MilSolidColorBrush>(obj);
            var solid = (MilSolidColorBrush)obj;
            Assert.Equal(0x12, SkiaColor.ScRgbToSrgbByte(solid.Color.R));
        }

        [Fact]
        public void Lookup_null_handle_returns_null()
        {
            using var scene = new TestScene();
            Assert.Null(scene.Provider.Lookup(MilResourceHandle.Null));
        }

        [Fact]
        public void Lookup_unregistered_handle_returns_null()
        {
            using var scene = new TestScene();
            Assert.Null(scene.Provider.Lookup(new MilResourceHandle(0xDEADBEEFu)));
        }

        // ==================================================================
        //  矩阵语义：rotation/skew/transform-group/translate/scale
        //
        //  FromMil(MilMatrix3x2D → SKMatrix) 曾把 M12/M21 转置了（SkewX=S_12,
        //  SkewY=S_21），现已修正为 WPF 语义 SkewX=S_21, SkewY=S_12。
        //  对称矩阵（M12 == M21）无法区分两种写法，因此本组保留 Translate /
        //  Scale / Rotate / Skew 的单独断言作为基线，再用 MilMatrixTransform
        //  的**非对称**矩阵把行/列约定钉死。
        // ==================================================================

        [Fact]
        public void Transform_translate_round_trip()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle h = scene.Translate(50, 30);
            SKMatrix m = TransformResolver.Resolve(scene.Channel, h);

            // (0,0) 经平移后到 (50,30)
            SKPoint p = m.MapPoint(0, 0);
            Assert.Equal(50f, p.X, 3);
            Assert.Equal(30f, p.Y, 3);
        }

        [Fact]
        public void Transform_scale_about_origin()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle h = scene.Scale(2.0, 3.0);
            SKMatrix m = TransformResolver.Resolve(scene.Channel, h);

            SKPoint p = m.MapPoint(10, 10);
            Assert.Equal(20f, p.X, 3);
            Assert.Equal(30f, p.Y, 3);
        }

        [Fact]
        public void Transform_rotate_90_clockwise_around_origin()
        {
            // WPF 约定：Angle 顺时针为正（坐标系 y 向下）；点 (1,0) 旋转 90° 后
            // 应到达屏幕 (0,1) 位置。
            using var scene = new TestScene();
            DUCE.ResourceHandle h = scene.Rotate(90);
            SKMatrix m = TransformResolver.Resolve(scene.Channel, h);

            SKPoint p = m.MapPoint(1, 0);
            Assert.Equal(0f, p.X, 3);
            Assert.Equal(1f, p.Y, 3);
        }

        [Fact]
        public void Transform_rotate_around_center()
        {
            // 绕 (100,100) 旋转 180°：(120,100) → (80,100)
            using var scene = new TestScene();
            DUCE.ResourceHandle h = scene.Rotate(180, 100, 100);
            SKMatrix m = TransformResolver.Resolve(scene.Channel, h);

            SKPoint p = m.MapPoint(120, 100);
            Assert.Equal(80f, p.X, 3);
            Assert.Equal(100f, p.Y, 3);
        }

        [Fact]
        public void Transform_group_order_matters()
        {
            // WPF 语义（上游 TransformGroup.cs:31 `transform = c0; for i=1..n: transform *= c_i`）：
            // **子按列表顺序依次作用在几何上** —— 先 c0，再 c1，……
            // 本用例：TransformGroup(Translate(50,0), Scale(2,1)) 作用到点 (10,5)：
            //   先平移 → (60,5)；再缩放(2,1) → (120,5)          ← 正确
            // 若把子顺序整体画反（先缩放再平移）→ (20,5) → (70,5) ← 旧的错误实现（债务 #12）
            using var scene = new TestScene();

            DUCE.ResourceHandle translateFirst = scene.TransformGroup(
                scene.Translate(50, 0), scene.Scale(2.0, 1.0));

            SKMatrix m1 = TransformResolver.Resolve(scene.Channel, translateFirst);
            SKPoint p1 = m1.MapPoint(10, 5);
            Assert.Equal(120f, p1.X, 3);   // 先平移后缩放
            Assert.Equal(5f, p1.Y, 3);

            // 反向组（先缩放后平移）必须得到另一个值——保证本用例对顺序真的有区分力
            DUCE.ResourceHandle scaleFirst = scene.TransformGroup(
                scene.Scale(2.0, 1.0), scene.Translate(50, 0));
            SKPoint p2 = TransformResolver.Resolve(scene.Channel, scaleFirst).MapPoint(10, 5);
            Assert.Equal(70f, p2.X, 3);
            Assert.NotEqual(p1.X, p2.X);
        }

        [Fact]
        public void Transform_matrix_transform_matches_wpf_definition()
        {
            // MilMatrix3x2D 字段与 WPF Matrix 字段是**直接对应、无交换**（见上游
            // PresentationCore/System/Windows/Media/Composition.cs 的
            // TransformToMilMatrix3x2D / MilMatrix3x2DToMatrix）：
            //   S_11 = WPF M11,  S_12 = WPF M12,
            //   S_21 = WPF M21,  S_22 = WPF M22
            // WPF 几何含义（行向量 p' = p·M）→ x' 中 M11 是 x 系数、M21 是 y 系数：
            //   x' = S_11·x + S_21·y + DX
            //   y' = S_12·x + S_22·y + DY
            //
            // Skia 语义（列向量 p' = M·p）：
            //   x' = ScaleX·x + SkewX·y + TransX
            //   y' = SkewY·x  + ScaleY·y + TransY
            //
            // 两组式子对齐后得到 FromMil 的正确写法：
            //   ScaleX=S_11, SkewX=S_21, SkewY=S_12, ScaleY=S_22
            // 即 M12/M21 相对 Skia 的 SkewX/SkewY 是**交叉**映射，不是同名直连。
            //
            // 此处取一个**非对称**矩阵 (M11=2, M12=0, M21=1.5, M22=1)：对称矩阵在
            // 两种写法下结果相同，只有非对称才能把差异放大。
            //   点 (2,3)：x' = 2·2 + 1.5·3 = 8.5，y' = 0·2 + 1·3 = 3
            // 修复前 FromMil 写成 SkewX=S_12, SkewY=S_21（转置），得到 (4, 6)。

            using var scene = new TestScene();
            DUCE.ResourceHandle h = scene.Matrix(
                m11: 2.0, m12: 0.0,
                m21: 1.5, m22: 1.0,
                dx: 0, dy: 0);

            SKMatrix m = TransformResolver.Resolve(scene.Channel, h);
            SKPoint p = m.MapPoint(2, 3);

            Assert.Equal(8.5f, p.X, 3);
            Assert.Equal(3.0f, p.Y, 3);
        }

        [Fact]
        public void ResolveTransform_null_handle_returns_identity()
        {
            using var scene = new TestScene();
            SKMatrix m = scene.Provider.ResolveTransform(MilResourceHandle.Null);
            Assert.True(m.IsIdentity);
        }

        // ==================================================================
        //  Push/Pop 配平
        // ==================================================================

        [Fact]
        public void Push_pop_balanced_leaves_initial_save_count()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0xFF, 0x00, 0x00);
            DUCE.ResourceHandle clipGeom = scene.RectGeometry(10, 10, 100, 100);

            MilVisual root = scene.Visual();
            root.Content = scene.RenderData(d =>
            {
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 240, 180),
                    Brush = new MilResourceHandle((uint)brush),
                });
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilPushClip,
                    Geometry = new MilResourceHandle((uint)clipGeom),
                });
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(50, 50, 80, 80),
                    Brush = new MilResourceHandle((uint)brush),
                });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 240, 180),
                    Pen = new MilResourceHandle((uint)scene.Pen(scene.Solid(0, 0, 0), 2)),
                });
            });

            RenderOutput result = RenderHarness.Render(root, scene.Provider);
            Assert.True(result.IsStackBalanced,
                $"Push/Pop 不配平：{result.InitialSaveCount}→{result.FinalSaveCount}");
        }

        [Fact]
        public void Push_pop_mismatch_does_not_crash()
        {
            // 故意 Pop 比 Push 多一条：渲染层在 RenderContent 入口兜底
            // RestoreToCount(entry) 应当消化掉多余 Pop 而不破坏最终栈。
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0, 0, 0);

            MilVisual root = scene.Visual();
            root.Content = scene.RenderData(d =>
            {
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilPushClip,
                    Geometry = new MilResourceHandle((uint)scene.RectGeometry(0, 0, 240, 180)),
                });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });   // 多余
            });

            RenderOutput result = RenderHarness.Render(root, scene.Provider);
            // 期望 SaveCount 与入口相同；canvas.Restore 在 Count 为 1 时是 no-op，
            // 既不抛异常也不改变栈顶。
            Assert.Equal(result.InitialSaveCount, result.FinalSaveCount);
        }

        // ==================================================================
        //  *Animate vs 静态：相同几何 + 相同 brush/pen → 像素一致
        // ==================================================================

        [Fact]
        public void Animate_equals_static_for_rectangle()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0x30, 0x70, 0xC0);
            DUCE.ResourceHandle pen = scene.Pen(scene.Solid(0, 0, 0), 2);

            MilVisual staticRoot = scene.Visual();
            staticRoot.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(10, 10, 100, 80),
                Brush = new MilResourceHandle((uint)brush),
                Pen = new MilResourceHandle((uint)pen),
            }));

            MilVisual animateRoot = scene.Visual();
            animateRoot.Content = scene.RenderData(d =>
            {
                var raw = RectangleAnimatePayload(
                    new SKRect(10, 10, 100, 80),
                    new MilResourceHandle((uint)brush),
                    new MilResourceHandle((uint)pen),
                    dx: 0, dy: 0);
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangleAnimate,
                }, raw);
            });

            using SKBitmap staticBmp = RenderHarness.RenderBitmap(staticRoot, scene.Provider);
            using SKBitmap animateBmp = RenderHarness.RenderBitmap(animateRoot, scene.Provider);
            CompareResult cmp = ImageComparer.Compare(animateBmp, staticBmp);
            Assert.True(cmp.Passed,
                $"Animate 与静态不一致：{cmp.Message}");
        }

        // ==================================================================
        //  图像比较器本身的 sanity
        // ==================================================================

        [Fact]
        public void Image_compare_identical_bitmaps_pass()
        {
            using var bmp = new SKBitmap(new SKImageInfo(8, 8, SKColorType.Rgba8888, SKAlphaType.Premul));
            using var canvas = new SKCanvas(bmp);
            canvas.Clear(new SKColor(255, 128, 64, 200));

            using var clone = new SKBitmap(new SKImageInfo(8, 8, SKColorType.Rgba8888, SKAlphaType.Premul));
            using (var c2 = new SKCanvas(clone))
                c2.DrawBitmap(bmp, 0, 0);

            CompareResult r = ImageComparer.Compare(bmp, clone);
            Assert.True(r.Passed);
            Assert.Equal(0, r.DifferingPixels);
        }

        [Fact]
        public void Image_compare_size_mismatch_fails_immediately()
        {
            using var a = new SKBitmap(new SKImageInfo(4, 4, SKColorType.Rgba8888, SKAlphaType.Premul));
            using var b = new SKBitmap(new SKImageInfo(5, 4, SKColorType.Rgba8888, SKAlphaType.Premul));
            CompareResult r = ImageComparer.Compare(a, b);
            Assert.False(r.Passed);
            Assert.Contains("尺寸不一致", r.Message);
        }

        [Fact]
        public void Image_compare_detects_out_of_tolerance_pixels()
        {
            using var a = new SKBitmap(new SKImageInfo(2, 2, SKColorType.Rgba8888, SKAlphaType.Premul));
            using var b = new SKBitmap(new SKImageInfo(2, 2, SKColorType.Rgba8888, SKAlphaType.Premul));

            using (var ca = new SKCanvas(a)) ca.Clear(new SKColor(255, 0, 0, 255));
            using (var cb = new SKCanvas(b)) cb.Clear(new SKColor(0, 0, 255, 255));

            CompareResult r = ImageComparer.Compare(a, b);
            Assert.False(r.Passed);
            Assert.Equal(4, r.DifferingPixels);
            Assert.True(r.MaxChannelDelta >= 250);
        }

        // ==================================================================
        //  ImageBrush（TileBrush）语义：逐像素钉死 Stretch/Tile/Alignment
        // ==================================================================

        /// <summary>共用渲染：140×90 矩形，60×60 四色棋盘格（每格 10px）画刷。</summary>
        private static SKBitmap RenderImageBrush(
            TestScene scene, MilResourceHandle brushHandle, SKRect rect)
        {
            MilVisual root = scene.Visual();
            root.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = rect,
                Brush = brushHandle,
            }));
            return RenderHarness.RenderBitmap(root, scene.Provider);
        }

        /// <summary>场景 + ImageBrush 句柄的持有者（场景随 fixture Dispose）。</summary>
        private readonly struct ImageBrushFixture : IDisposable
        {
            public TestScene Scene { get; }
            public DUCE.ResourceHandle Brush { get; }
            public ImageBrushFixture(TestScene scene, DUCE.ResourceHandle brush)
            {
                Scene = scene; Brush = brush;
            }
            public void Dispose() => Scene.Dispose();
        }

        private static ImageBrushFixture ImageBrushScene(
            MilStretch stretch, MilTileMode tile, MilRect? viewport,
            MilAlignmentX ax = MilAlignmentX.Center, MilAlignmentY ay = MilAlignmentY.Center)
        {
            var scene = new TestScene();
            DUCE.ResourceHandle bmp = scene.BitmapSourceHandle();
            SKBitmap checker = scene.Own(TestScene.MakeCheckerboard(60, 6));
            scene.Provider.BitmapResolver = h => h.Equals(scene.Mh(bmp)) ? checker : null;
            DUCE.ResourceHandle brush = scene.ImageBrush(
                bmp, stretch, tile, viewport: viewport, alignmentX: ax, alignmentY: ay);
            return new ImageBrushFixture(scene, brush);
        }

        [Fact]
        public void ImageBrush_Uniform_centers_and_letterboxes()
        {
            // 140×90 的矩形 vs 60×60 的图：Uniform 等比 → 90×90，左右各留 25px 白底。
            using var fx = ImageBrushScene(
                MilStretch.Uniform, MilTileMode.None, viewport: null);
            using SKBitmap bmp = RenderImageBrush(fx.Scene, fx.Scene.Mh(fx.Brush), new SKRect(0, 0, 140, 90));

            // 格 (3,3) 的**格心**必须是黄。
            // ⚠【T2b 修正探针点：原为 (70,45)，那一点是 4 个格的**公共角**】
            //   Uniform 后内容 90×90 居中 ⇒ dest 起点 x=25；格 15px ⇒ 边界在
            //   x=25,40,55,70,85,…、y=0,15,30,45,… ⇒ **(70,45) 恰好落在 4 格交角**。
            //   在交角上"取到纯黄"只有**最近邻**才会发生；WPF 是双线性（真机口径：
            //   Unspecified≡Linear），交角处必然混色。所以原探针钉住的是"我们当时用
            //   Nearest"这个行为，不是 WPF 的行为。
            //   换成格心（格(3,3) 中心 = 70+7.5, 45+7.5 → (77,52)），两种采样下都必须是纯黄。
            Assert.Equal(new SKColor(0xF0, 0xC0, 0x20), bmp.GetPixel(77, 52));
            // 左右留白带必须是纯白底（不是棋盘格白格 0xF2，也不是边缘钳位色）
            Assert.Equal(SKColors.White, bmp.GetPixel(5, 45));
            Assert.Equal(SKColors.White, bmp.GetPixel(135, 45));

            // 【T2b 新增·定性判据】同一个 4 格公共角 (70,45) **必须混色**（断言 != 纯黄）。
            //   为什么只断言"不是纯黄"而不断等值：Tile/FlipX/FlipY 三档还残留 Δ1–2
            //   （Skia Low 核与 WPF 位图缩放核的取整差异），精确值不可靠；
            //   而"角上必然混色"是可判的、且**能推翻 Nearest** 的定性性质。
            //   方向与上面那条换掉的探针**正好相反**：
            //     旧断言「(70,45) == 纯黄」只在 **Nearest** 下成立 ⇒ 双线性下必红；
            //     本断言「(70,45) != 纯黄」只在 **双线性** 下成立 ⇒ Nearest 下必红。
            //   真机口径见 tests/parity/brushes 批次 2：`Unspecified ≡ Linear`（0 点差异）
            //   ⇒ WPF 位图画刷默认就是双线性，所以角上混色才是规格。
            SKColor corner = bmp.GetPixel(70, 45);
            Assert.True(corner != new SKColor(0xF0, 0xC0, 0x20),
                $"4 格公共角 (70,45) 取到了纯黄 #{corner.Red:X2}{corner.Green:X2}{corner.Blue:X2} —— " +
                "只有最近邻采样才会这样；WPF 默认档 Unspecified≡Linear（双线性），角上必然混色。");
            // （本类没有 ITestOutputHelper，读数直接进断言消息，避免再加依赖）
        }

        [Fact]
        public void ImageBrush_Tile_repeats_viewport_block()
        {
            // viewport 35×30、Tile=Repeat：每 35px 横向重复。基块原点格是蓝（格0,0），
            // 35px 处该是第二个基块的原点格 → 也是蓝。
            using var fx = ImageBrushScene(
                MilStretch.Fill, MilTileMode.Tile, viewport: new MilRect(0, 0, 35, 30));
            using SKBitmap bmp = RenderImageBrush(fx.Scene, fx.Scene.Mh(fx.Brush), new SKRect(0, 0, 140, 90));

            Assert.Equal(new SKColor(0x1E, 0x50, 0xC8), bmp.GetPixel(2, 2));    // 第 0 基块格(0,0)=蓝
            Assert.Equal(new SKColor(0x1E, 0x50, 0xC8), bmp.GetPixel(37, 2));   // 第 1 基块格(0,0)=蓝
            Assert.Equal(new SKColor(0x1E, 0x50, 0xC8), bmp.GetPixel(72, 2));   // 第 2 基块格(0,0)=蓝
        }

        [Fact]
        public void ImageBrush_None_draws_1to1_leaves_rest_transparent()
        {
            // Stretch=None：60×60 原样画在原点；TileMode=None 语义 = 基块之外不绘制
            // （Decal 透明），矩形其余部分保持白底。
            using var fx = ImageBrushScene(MilStretch.None, MilTileMode.None, viewport: null);
            using SKBitmap bmp = RenderImageBrush(fx.Scene, fx.Scene.Mh(fx.Brush), new SKRect(0, 0, 140, 90));

            // 1:1：每格 10px。格(0,0)=蓝、格(5,0)=白格（y=2 行 0）
            Assert.Equal(new SKColor(0x1E, 0x50, 0xC8), bmp.GetPixel(5, 5));
            Assert.Equal(new SKColor(0xF2, 0xF2, 0xF2), bmp.GetPixel(55, 5));
            // x>60 或 y>60：基块之外 → 透明 → 白底（不是边缘钳位色）
            Assert.Equal(SKColors.White, bmp.GetPixel(100, 5));
            Assert.Equal(SKColors.White, bmp.GetPixel(5, 80));
        }

        [Fact]
        public void ImageBrush_RelativeToBoundingBox_viewport_scales_with_bounds()
        {
            // viewport=(0.25,0.25,0.5,0.5)、RelativeToBoundingBox：目标基块 = 矩形中央 1/4 区域。
            // 矩形 (0,0,140,90) → 基块 (35,22.5,70,45)。60×60 棋盘格 Fill 进 70×45 的基块。
            using var scene = new TestScene();
            DUCE.ResourceHandle bmp = scene.BitmapSourceHandle();
            SKBitmap checker = scene.Own(TestScene.MakeCheckerboard(60, 6));
            scene.Provider.BitmapResolver = h => h.Equals(scene.Mh(bmp)) ? checker : null;
            DUCE.ResourceHandle brush = scene.ImageBrush(
                bmp, MilStretch.Fill, MilTileMode.None,
                viewport: new MilRect(0.25, 0.25, 0.5, 0.5),
                viewportUnits: MilBrushMappingMode.RelativeToBoundingBox);
            using SKBitmap bmp2 = RenderImageBrush(scene, scene.Mh(brush), new SKRect(0, 0, 140, 90));

            // 基块内：格(0,0) 起点在 (35,22.5)，每格 70/6≈11.67 × 45/6=7.5 → 蓝
            Assert.Equal(new SKColor(0x1E, 0x50, 0xC8), bmp2.GetPixel(37, 24));
            // 基块外（矩形左上角 4×4）：TileMode=None → 不绘制 → 白底
            Assert.Equal(SKColors.White, bmp2.GetPixel(2, 2));
        }

        // ==================================================================
        //  *Animate 原始字节构造（与 GoldenRenderTests 共享一份布局）
        // ==================================================================

        private static byte[] RectangleAnimatePayload(
            SKRect rect, MilResourceHandle brush, MilResourceHandle pen, float dx, float dy)
        {
            using var ms = new System.IO.MemoryStream();
            using var w = new System.IO.BinaryWriter(ms);
            w.Write((double)(rect.Left + dx));
            w.Write((double)(rect.Top + dy));
            w.Write((double)rect.Width);
            w.Write((double)rect.Height);
            w.Write(brush.Value);
            w.Write(pen.Value);
            w.Write(0u);
            w.Write(0u);
            return ms.ToArray();
        }
    }
}
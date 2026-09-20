// DrawingBrush / BitmapCacheBrush 的能力用例（T2）。
//
// 【纪律】这些用例是**先写、先红**的：`SkiaBrush.CreateFill` 对这三类画刷走 default ⇒ 返回 null
//   ⇒ 背景静默变空白。红是本轮要消掉的状态，不是"测试写早了"。
// 【形制】照 image_brush 的 TileBrush 形制：Viewbox/Viewport/Stretch/TileMode/Alignment +
//   画刷变换全显式传入（MilStretch/MilTileMode 的枚举默认是 0=None，与 WPF 属性默认不同）。
// 【两个已实测的语义陷阱】① SKMatrix.Concat(a,b) = **b 先作用**；
//   ② WPF TileMode.None → Skia **Decal**（平铺才用 Repeat/Mirror）。
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
    public class DrawingBrushTests
    {
        public DrawingBrushTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        // ==================================================================
        //  语义（像素之外的硬判据）：这三类画刷必须产出**可用画刷**，不能返回 null
        // ==================================================================
        [Fact]
        public void drawing_brush_produces_fill_paint()
        {
            TestScene scene = Scene();
            DUCE.ResourceHandle drawing = Drawing(scene);
            DUCE.ResourceHandle brush = scene.Add(new MilDrawingBrush
            {
                Drawing = drawing,
                Stretch = MilStretch.Fill,
                TileMode = MilTileMode.None,
                Viewbox = MilRect.Empty,
                Viewport = MilRect.Empty,
                ViewportUnits = MilBrushMappingMode.Absolute,
                ViewboxUnits = MilBrushMappingMode.Absolute,
                AlignmentX = MilAlignmentX.Center,
                AlignmentY = MilAlignmentY.Center,
            });

            SKPaint paint = SkiaBrush.CreateFill(scene.Provider, new MilResourceHandle((uint)brush),
                                                new SKRect(0, 0, 120, 80), antialias: true);
            Assert.NotNull(paint);
            paint.Dispose();
        }

        [Fact]
        public void bitmap_cache_brush_produces_fill_paint()
        {
            TestScene scene = Scene();
            DUCE.ResourceHandle target = scene.Solid(200, 60, 40);
            DUCE.ResourceHandle brush = scene.Add(new MilBitmapCacheBrush
            {
                BitmapCache = default,
                InternalTarget = target,
            });

            SKPaint paint = SkiaBrush.CreateFill(scene.Provider, new MilResourceHandle((uint)brush),
                                                new SKRect(0, 0, 120, 80), antialias: true);
            Assert.NotNull(paint);
            paint.Dispose();
        }

        // ==================================================================
        //  golden：四个 TileMode + 一个**非单位画刷变换**（handoff 点名未验证项）
        // ==================================================================
        [Fact]
        public void drawing_brush_tile_none() => TileCase(nameof(drawing_brush_tile_none), MilTileMode.None);

        // ⚠️【T2b 重生成说明 · 条件④】旧基准图锁的是「绝对单位 Viewport 以**画布原点**解释」
        //   这个已被真机否定的错误行为（oracle units_vpabs_viewboxabs_tile：包围盒局部原点
        //   194/194 吻合 vs 画布原点 20/216，瓦片原点实测 (26,26)）；
        //   本图已按**真机局部坐标系**重生成 —— 不是“我们又改了一次基准”。
        [Fact]
        public void drawing_brush_tile_repeat() => TileCase(nameof(drawing_brush_tile_repeat), MilTileMode.Tile);

        // ⚠【golden 锁的是**近似**，不是 WPF 语义 —— 如实写在生成说明里，别让后人误读】
        //   WPF 的 FlipX/FlipY 是**单轴**镜像（每个奇数列沿 X 翻，行不受影响）；
        //   Skia 的 shader tile mode 只有 `Mirror`（**两轴同时**按索引交替）。二者在 (奇,奇) 格上不同：
        //     · WPF FlipX：(1,1) 格 = X 镜像
        //     · Skia Mirror：(1,1) 格 = X、Y 各翻一次 = **复原**
        //   所以下面两张 golden 钉住的是**继承自 ImageBrush 的既有近似**（FlipX/FlipY → Mirror）。
        //   要真做单轴翻转，必须在 mapping 之外**自绘平铺**（按 viewport 周期逐格决定是否镜像），
        //   不能靠 shader tile mode 表达 —— 评估见交付说明，属独立一轮。
        [Fact]
        public void drawing_brush_tile_flipx() => TileCase(nameof(drawing_brush_tile_flipx), MilTileMode.FlipX);

        [Fact]
        public void drawing_brush_tile_flipy() => TileCase(nameof(drawing_brush_tile_flipy), MilTileMode.FlipY);

        // ⚠️【T2b 重生成说明 · 条件④】旧基准图锁的是「绝对单位 Viewport 以**画布原点**解释」
        //   这个已被真机否定的错误行为（oracle units_vpabs_viewboxabs_tile：包围盒局部原点
        //   194/194 吻合 vs 画布原点 20/216，瓦片原点实测 (26,26)）；
        //   本图已按**真机局部坐标系**重生成 —— 不是“我们又改了一次基准”。
        [Fact]
        public void drawing_brush_brush_transform()
        {
            GoldenRunner.Run(nameof(drawing_brush_brush_transform), () =>
            {
                TestScene scene = Scene();
                DUCE.ResourceHandle drawing = Drawing(scene);
                DUCE.ResourceHandle brush = scene.Add(new MilDrawingBrush
                {
                    Drawing = drawing,
                    Stretch = MilStretch.Fill,
                    TileMode = MilTileMode.Tile,
                    Viewbox = MilRect.Empty,
                    Viewport = new MilRect(0, 0, 40, 30),      // 小基块 → 平铺可见
                    ViewportUnits = MilBrushMappingMode.Absolute,
                    ViewboxUnits = MilBrushMappingMode.Absolute,
                    AlignmentX = MilAlignmentX.Center,
                    AlignmentY = MilAlignmentY.Center,
                    // 非单位画刷变换：30° 旋转 + 平移（用相对变换，落在 tile 空间里）
                    RelativeTransform = scene.Matrix(0.866, 0.5, -0.5, 0.866, 12, 8),
                });

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    d.Add(Rect(10, 10, 300, 200, brush));
                });
                return (scene, root);
            }, Output, width: 320, height: 220);
        }

        // ==================================================================
        //  GlyphRunDrawing：Drawing 里含文本（此前走 default ⇒ **静默不画**）
        // ==================================================================
        [Fact]
        public void drawing_with_glyph_run_invokes_glyph_renderer()
        {
            TestScene scene = Scene();
            int calls = 0;
            scene.Provider.GlyphRunRenderer = (canvas, resource, foreground) =>
            {
                calls++;
                canvas.DrawRect(new SKRect(2, 2, 34, 22), foreground);
                return true;
            };

            DUCE.ResourceHandle glyphRun = scene.Add(new MilGlyphRun());
            DUCE.ResourceHandle foreground = scene.Solid(20, 20, 20);
            DUCE.ResourceHandle glyphDrawing = scene.Add(new MilGlyphRunDrawing
            {
                GlyphRun = glyphRun,
                ForegroundBrush = foreground,
            });
            // 现实形态：组里既有几何又有文本（组包围盒由几何给出）。
            DUCE.ResourceHandle backdrop = scene.Add(new MilGeometryDrawing
            {
                Geometry = scene.RectGeometry(0, 0, 40, 30),
                Brush = scene.Solid(200, 200, 200),
                Pen = default,
            });
            DUCE.ResourceHandle group = scene.Add(new MilDrawingGroup
            {
                Opacity = 1.0,
                Children = { backdrop, glyphDrawing },
            });
            DUCE.ResourceHandle brush = scene.Add(new MilDrawingBrush
            {
                Drawing = group,
                Stretch = MilStretch.Fill,
                TileMode = MilTileMode.None,
                Viewbox = MilRect.Empty,
                Viewport = MilRect.Empty,
                ViewportUnits = MilBrushMappingMode.Absolute,
                ViewboxUnits = MilBrushMappingMode.Absolute,
                AlignmentX = MilAlignmentX.Center,
                AlignmentY = MilAlignmentY.Center,
            });

            SKPaint paint = SkiaBrush.CreateFill(scene.Provider, new MilResourceHandle((uint)brush),
                                                new SKRect(0, 0, 120, 80), antialias: true);
            Assert.NotNull(paint);
            paint.Dispose();
            // 实现前：DrawDrawing 的 default 分支直接 break ⇒ 字形渲染器一次都不会被调（用例会红）
            Assert.Equal(1, calls);
        }

        /// <summary>
        /// **纯字形** Drawing（组里只有 GlyphRunDrawing、没有几何）—— 显式跳过。
        /// 原因：DrawingBrush 的 tile 尺寸取自 Drawing 的**包围盒**，而文字范围只有字形渲染器知道
        /// （`GlyphRunRenderer` 只负责"把字画到画布上"，不返回度量）。
        /// 恢复条件：字形扩展点同时给出 bounds（或 Text 侧提供度量）后，`DrawingBounds` 即可对它返回真值，
        /// 那时把这个 Skip 去掉即可（实现侧的 `DrawDrawing` 分支已经接好，见 SkiaRenderBackend:501 同法）。
        /// </summary>
        // ⚠️【T2b 更新：上面那条"需要文字度量"的理由已经不成立】
        //   包围盒不必算度量：`MilGlyphRun.ManagedBounds` 就是上游托管侧 `GlyphRun.Bounds`，
        //   由 MilCommandDispatcher.cs:906 从命令体填入。SkiaBrush.DrawingBounds 的
        //   MilGlyphRunDrawing 分支与 VisualBrushSource 的 MilDrawGlyphRun 分支现已都用它
        //   （实测真值见 VisualBrushWiringTests.glyph_run_contributes_to_natural_size：(4,6,36,20)）。
        //   本用例**仍保留跳过**，但理由换成"它目前是 Assert.True(true) 的空壳"——
        //   空壳会假绿（本项目已记过这个陷阱）。恢复办法：把断言改成
        //   "DrawingBounds(纯字形 Drawing) == 该 GlyphRun 的 ManagedBounds" 再删 Skip。
        [Fact(Skip = "空壳用例（Assert.True(true)）；包围盒能力已由 T2b 用 ManagedBounds 补齐，" +
                     "待把断言写成真判据后再恢复。详见上方注释。")]
        public void drawing_with_only_glyph_run_bounds_need_text_metrics() => Assert.True(true);

        // ==================================================================
        //  VisualBrush：嵌套视觉渲染 + **显式递归防护**
        // ==================================================================
        [Fact]
        public void visual_brush_produces_fill_paint()
        {
            TestScene scene = Scene();
            scene.Provider.VisualImageResolver = _ => Checker(24, 4);

            DUCE.ResourceHandle brush = scene.Add(new MilVisualBrush
            {
                Visual = (DUCE.ResourceHandle)(uint)scene.Visual().Handle,
                Stretch = MilStretch.Fill,
                TileMode = MilTileMode.None,
                Viewbox = MilRect.Empty,
                Viewport = MilRect.Empty,
                ViewportUnits = MilBrushMappingMode.Absolute,
                ViewboxUnits = MilBrushMappingMode.Absolute,
                AlignmentX = MilAlignmentX.Center,
                AlignmentY = MilAlignmentY.Center,
            });

            SKPaint paint = SkiaBrush.CreateFill(scene.Provider, new MilResourceHandle((uint)brush),
                                                new SKRect(0, 0, 120, 80), antialias: true);
            Assert.NotNull(paint);
            paint.Dispose();
        }

        /// <summary>
        /// 自引用（VisualBrush 的 Visual 内容里又有指向同一个 Visual 的 VisualBrush）**不许栈溢出**：
        /// 解析器每次都会再调一次同一个画刷，若没有防护就会无限递归。
        /// 判据：调用次数 == 1（第二次被访问集拦下，返回"不画"）。
        /// </summary>
        [Fact]
        public void visual_brush_self_reference_is_guarded()
        {
            TestScene scene = Scene();
            DUCE.ResourceHandle visual = (DUCE.ResourceHandle)(uint)scene.Visual().Handle;
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

            int calls = 0;
            scene.Provider.VisualImageResolver = _ =>
            {
                calls++;
                // 模拟"这个 Visual 的内容里又有一个指向自己的 VisualBrush"
                SKPaint nested = SkiaBrush.CreateFill(scene.Provider, new MilResourceHandle((uint)brush),
                                                     new SKRect(0, 0, 24, 24), antialias: true);
                nested?.Dispose();
                return Checker(24, 4);
            };

            SKPaint paint = SkiaBrush.CreateFill(scene.Provider, new MilResourceHandle((uint)brush),
                                                new SKRect(0, 0, 120, 80), antialias: true);
            Assert.NotNull(paint);      // 外层照常出画刷
            paint.Dispose();
            Assert.Equal(1, calls);      // 递归被显式拦下：只进去一次，没有爆栈
        }

        private static SKImage Checker(int size, int cell)
        {
            var info = new SKImageInfo(size, size, SKColorType.Bgra8888, SKAlphaType.Premul);
            using SKSurface surface = SKSurface.Create(info);
            surface.Canvas.Clear(SKColors.Transparent);
            using var dark = new SKPaint { Color = new SKColor(30, 30, 30) };
            using var light = new SKPaint { Color = new SKColor(220, 220, 220) };
            for (int y = 0; y < size; y += cell)
                for (int x = 0; x < size; x += cell)
                {
                    bool on = ((x / cell) + (y / cell)) % 2 == 0;
                    surface.Canvas.DrawRect(new SKRect(x, y, x + cell, y + cell), on ? dark : light);
                }
            return surface.Snapshot();
        }

        // ==================================================================
        //  DrawingGroup 的 Transform / OpacityMask（本轮新接；此前是**静默错渲**）
        //  这两张 golden 是回归锁：实现前 Transform 被忽略（画在未变换位置）、OpacityMask 被忽略（画成不透明）。
        // ==================================================================
        [Fact]
        public void drawing_brush_group_transform()
        {
            GoldenRunner.Run(nameof(drawing_brush_group_transform), () =>
            {
                TestScene scene = Scene();
                DUCE.ResourceHandle drawing = DrawingWithGroup(scene, transform: scene.Matrix(1, 0, 0, 1, 26, 16));
                DUCE.ResourceHandle brush = scene.Add(new MilDrawingBrush
                {
                    Drawing = drawing,
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
                root.Content = scene.RenderData(d => d.Add(Rect(10, 10, 300, 200, brush)));
                return (scene, root);
            }, Output, width: 320, height: 220);
        }

        [Fact]
        public void drawing_brush_group_opacity_mask()
        {
            GoldenRunner.Run(nameof(drawing_brush_group_opacity_mask), () =>
            {
                TestScene scene = Scene();
                DUCE.ResourceHandle mask = scene.SolidWithOpacity(255, 255, 255, 0.5);   // 均匀 alpha=0.5 的 mask
                DUCE.ResourceHandle drawing = DrawingWithGroup(scene, opacityMask: mask);
                DUCE.ResourceHandle brush = scene.Add(new MilDrawingBrush
                {
                    Drawing = drawing,
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
                root.Content = scene.RenderData(d => d.Add(Rect(10, 10, 300, 200, brush)));
                return (scene, root);
            }, Output, width: 320, height: 220);
        }

        /// <summary>Drawing group（可带 Transform / OpacityMask）—— 与 Drawing() 同形，但组上带属性。</summary>
        private static DUCE.ResourceHandle DrawingWithGroup(
            TestScene scene, DUCE.ResourceHandle transform = default, DUCE.ResourceHandle opacityMask = default)
        {
            DUCE.ResourceHandle bg = scene.Solid(40, 90, 200);
            DUCE.ResourceHandle fg = scene.Solid(240, 200, 40);
            DUCE.ResourceHandle block = scene.Add(new MilGeometryDrawing
            {
                Geometry = scene.RectGeometry(0, 0, 40, 30), Brush = bg, Pen = default,
            });
            DUCE.ResourceHandle dot = scene.Add(new MilGeometryDrawing
            {
                Geometry = scene.RectGeometry(6, 5, 12, 9), Brush = fg, Pen = default,
            });
            return scene.Add(new MilDrawingGroup
            {
                Opacity = 1.0,
                Transform = transform,
                OpacityMask = opacityMask,
                Children = { block, dot },
            });
        }

        private void TileCase(string name, MilTileMode tileMode)
        {
            GoldenRunner.Run(name, () =>
            {
                TestScene scene = Scene();
                DUCE.ResourceHandle drawing = Drawing(scene);
                DUCE.ResourceHandle brush = scene.Add(new MilDrawingBrush
                {
                    Drawing = drawing,
                    Stretch = MilStretch.Fill,
                    TileMode = tileMode,
                    Viewbox = MilRect.Empty,
                    Viewport = tileMode == MilTileMode.None
                        ? MilRect.Empty
                        : new MilRect(0, 0, 40, 30),           // 平铺基块
                    ViewportUnits = MilBrushMappingMode.Absolute,
                    ViewboxUnits = MilBrushMappingMode.Absolute,
                    AlignmentX = MilAlignmentX.Center,
                    AlignmentY = MilAlignmentY.Center,
                });

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    d.Add(Rect(10, 10, 300, 200, brush));
                });
                return (scene, root);
            }, Output, width: 320, height: 220);
        }

        // ---- 辅助 ----
        private static TestScene Scene() => new TestScene();

        /// <summary>一个看得出平铺/翻转的 Drawing：DrawingGroup(实心方块 + 对比色小方块 + 描边)。</summary>
        private static DUCE.ResourceHandle Drawing(TestScene scene)
        {
            DUCE.ResourceHandle bg = scene.Solid(40, 90, 200);
            DUCE.ResourceHandle fg = scene.Solid(240, 200, 40);
            DUCE.ResourceHandle block = scene.Add(new MilGeometryDrawing
            {
                Geometry = scene.RectGeometry(0, 0, 40, 30),
                Brush = bg,
                Pen = default,
            });
            DUCE.ResourceHandle dot = scene.Add(new MilGeometryDrawing
            {
                Geometry = scene.RectGeometry(6, 5, 12, 9),
                Brush = fg,
                Pen = default,
            });
            return scene.Add(new MilDrawingGroup
            {
                Opacity = 1.0,
                Children = { block, dot },
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

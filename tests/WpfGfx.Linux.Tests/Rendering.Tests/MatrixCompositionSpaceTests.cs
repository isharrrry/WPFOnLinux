// 「矩阵组合空间」同族扫荡的牙（T2b，2026-09-13）。
//
// 【这一族是什么】"某个矩阵该在**局部(DIP)**空间还是**设备**空间参与组合"。
//   判定依据只有一条：`SKMatrix.Concat(a,b)` 实测为 **b 先作用**（`ParityTests.cs:441-443`：
//   `Concat(R30,T30).TransX = 10.98`）。于是"X 先作用、Y 后作用"必须写成 `Concat(Y, X)`。
//   写反 ⇒ 矩阵落到**错误的空间**：平移不再被该层的缩放乘到。**它不报错、不空白，只是画错**。
//
// 【为什么既有的 154 条用例一条都没红】
//   `RenderHarness` 里 `canvas.ResetMatrix()` 且 `Dpi = FixedDpi(96)` ⇒ `deviceBase` **恒为单位阵**；
//   而这一族的症状**只在 deviceBase 非单位阵时才显形**。所以下面 ① 特意用**2× 画布**（非单位
//   deviceBase）来判别 —— 这是本仓库**唯一**能看见该族的装置。
//
// 【逐条对应扫荡报告 §9 的站点】
//   ① `SkiaRenderBackend.cs:280`（`RenderVisual` 的 `world × deviceBase`）
//   ② `VisualBrushSource.cs:80/:98`（内容 push 链与 `world` 的组合 ⇒ VisualBrush 包围盒）
//   ③ `SkiaRenderBackend.cs`（`DrawingGroup.Transform` 是否进 census `PushStack`）

using System;
using System.Collections.Generic;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class MatrixCompositionSpaceTests
    {
        public MatrixCompositionSpaceTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        private static MilDrawInstruction Rect(float x, float y, float w, float h, DUCE.ResourceHandle brush) =>
            new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(x, y, x + w, y + h),
                Brush = new MilResourceHandle((uint)brush),
            };

        /// <summary>墨迹水平范围（暗像素的首/末列）。</summary>
        private static (int Left, int Right) InkSpan(SKBitmap bmp)
        {
            int left = int.MaxValue, right = int.MinValue;
            for (int y = 0; y < bmp.Height; y++)
                for (int x = 0; x < bmp.Width; x++)
                {
                    SKColor c = bmp.GetPixel(x, y);
                    if (c.Red < 128 && c.Green < 128 && c.Blue < 128)
                    {
                        if (x < left) left = x;
                        if (x > right) right = x;
                    }
                }
            Assert.True(left != int.MaxValue, "一个暗像素都没有：装置本身没画出东西");
            return (left, right);
        }

        /// <summary>
        /// ① `RenderVisual` 的 `world × deviceBase`：**2× 画布**下，`Offset(30)` 的视觉必须落在
        ///    设备 `x=60`（局部 DIP 30 × 2），不是 `x=30`。
        ///    `RenderHarness` 会把画布 `ResetMatrix()`，所以这里直接调后端、自己预置 2× 画布。
        /// </summary>
        [Fact]
        public void world_is_applied_before_device_base_under_scaled_canvas()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0, 0, 0);

            MilVisual v = scene.Visual();
            v.Offset = new SKPoint(30f, 10f);          // 局部 DIP 30
            v.Transform = SKMatrix.Identity;
            v.Content = scene.RenderData(d => d.Add(Rect(0, 0, 10, 10, brush)));

            const int w = 200, h = 60;
            var info = new SKImageInfo(w, h, SKColorType.Rgba8888, SKAlphaType.Premul, SKColorSpace.CreateSrgb());
            using SKSurface surface = SKSurface.Create(info);
            SKCanvas canvas = surface.Canvas;
            canvas.Clear(SKColors.White);
            canvas.Scale(2f, 2f);                      // ← 非单位 deviceBase：这才是判别该族的装置
            var ctx = new RenderContext
            {
                Width = w, Height = h, Dpi = RenderContext.FixedDpi,
                ClearColor = SKColors.White, FontDirectory = PackagedFont.Directory, Antialias = false,
            };
            var backend = new SkiaRenderBackend(scene.Provider);
            backend.RenderVisualTree(v, canvas, ctx);
            canvas.Flush();
            using SKImage img = surface.Snapshot();
            using SKBitmap bmp = SKBitmap.FromImage(img);

            (int Left, int Right) ink = InkSpan(bmp);
            Output.WriteLine($"  2× 画布下墨迹 x∈[{ink.Left},{ink.Right}]（正确应 [60,80]；顺序写反会给 [30,50]）");

            Assert.True(ink.Left >= 59 && ink.Left <= 61,
                $"`world` 没被作用在 `deviceBase` 之前：墨迹起点 {ink.Left}，2× 画布下应为 60。" +
                "这就是 `Concat(world, deviceBase)` 把 deviceBase 先作用的形态（平移没被缩放乘到）。");
            Assert.True(ink.Right >= 79 && ink.Right <= 81, $"墨迹终点 {ink.Right}，应为 80。");
        }

        /// <summary>
        /// ② `VisualBrushSource.ContentBounds`：内容级 `PushTransform(Scale(2))` + 视觉 `Offset(30)`
        ///    ⇒ 包围盒必须 `x∈[30,50]`（局部先缩放、再走 world），不是 `[60,80]`。
        ///    这条与 ① 是**同一个判定**，只是走 VisualBrush 的包围盒计量路径；两条必须一致，
        ///    否则"离屏画出来的 VisualBrush"与"直接渲染"会系统性错位。
        /// </summary>
        [Fact]
        public void visual_brush_bounds_use_local_space_for_content_push()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0, 0, 0);
            DUCE.ResourceHandle scale2 = scene.Scale(2.0, 2.0);

            MilVisual v = scene.Visual();
            v.Offset = new SKPoint(30f, 0f);
            v.Transform = SKMatrix.Identity;
            v.Content = scene.RenderData(d =>
            {
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilPushTransform,
                    Geometry = new MilResourceHandle((uint)scale2),
                });
                d.Add(Rect(0, 0, 10, 10, brush));
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
            });

            SKRect bounds = VisualBrushSource.ContentBounds(scene.Provider, v);
            Output.WriteLine($"  ContentBounds = ({bounds.Left},{bounds.Top},{bounds.Right},{bounds.Bottom})" +
                             "（正确应 [30,50]；顺序写反会给 [60,80]）");

            Assert.True(bounds.Left >= 29 && bounds.Left <= 31,
                $"VisualBrush 包围盒左缘 {bounds.Left}，应为 30：内容级变换被当成了设备空间（先平移后缩放）。" +
                "直接渲染（牙①）与包围盒计量**必须同序**。");
            Assert.True(bounds.Right >= 49 && bounds.Right <= 51, $"包围盒右缘 {bounds.Right}，应为 50。");
        }

        /// <summary>
        /// ③ `DrawingGroup.Transform` 必须与 `MilPushTransform` 一样进 census 的 `PushStack`，
        ///    否则"画布矩阵含这一层、诊断却打 `PushTransform=无`"——仪表与被测对象不同步。
        /// </summary>
        [Fact]
        public void drawing_group_transform_is_visible_to_census_push_stack()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0, 0, 0);
            DUCE.ResourceHandle scale2 = scene.Scale(2.0, 2.0);

            // 一个 DrawingGroup：组自身带 Transform，子项是一条几何绘制
            DUCE.ResourceHandle dot = scene.Add(new MilGeometryDrawing
            {
                Geometry = scene.RectGeometry(0, 0, 10, 10), Brush = brush, Pen = default,
            });
            DUCE.ResourceHandle groupHandle = scene.Add(new MilDrawingGroup
            {
                Opacity = 1.0,
                Transform = scale2,
                Children = { dot },
            });

            MilVisual v = scene.Visual();
            v.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawDrawing,
                Geometry = new MilResourceHandle((uint)groupHandle),
            }));

            DrawInstructionCensus.ForceEnabled(true);
            try
            {
                using SKBitmap bmp = RenderHarness.RenderBitmap(v, scene.Provider, 80, 40, antialias: false);
                Assert.NotNull(bmp);
                // 组变换生效 ⇒ 墨迹落在 [0,20)；同时诊断必须能看见这一层 push
                IReadOnlyList<string> lines = DrawInstructionCensus.LastGeometryLines;
                string joined = string.Join("\n", lines);
                Output.WriteLine("  诊断行里是否出现组变换字样：" +
                    (joined.Contains("drawingGroup:") ? "是" : "否（= 仪表与被测对象不同步）"));
                Assert.True(joined.Contains("drawingGroup:"),
                    "`DrawingGroup.Transform` 已进画布矩阵，但 census 的 `PushTransform=` 看不到它 ⇒ " +
                    "诊断会把「有变换」报成「无变换」，任何依赖该字段的判定都会误判。");
            }
            finally { DrawInstructionCensus.ForceEnabled(false); }
        }
    }
}

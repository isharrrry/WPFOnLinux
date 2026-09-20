// T4 渲染层的 golden image 用例。
//
// 每条用例一个 [Fact]，名字即基准图名：tests/golden/<name>.png。
// 覆盖任务要求的 8 类（纯色矩形 / 渐变 / 椭圆 / 路径 / 变换 / 裁剪 / 不透明度 /
// 描边虚线），另补圆角矩形、径向渐变、路径裁剪、*Animate 静态终值 各一条。
//
// 更新基准图：
//   tests/WpfGfx.Linux.Tests/Rendering.Tests/update-golden.sh
// 或
//   WPFGOLDEN_UPDATE=1 dotnet test tests/WpfGfx.Linux.Tests/Rendering.Tests/

using System;
using System.IO;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class GoldenRenderTests
    {
        public GoldenRenderTests(ITestOutputHelper output) => Output = output;

        private ITestOutputHelper Output { get; }

        private void Golden(string name, SceneFactory build) => GoldenRunner.Run(name, build, Output);

        // ------------------------------------------------------------------
        //  1. 纯色矩形
        //     顺带覆盖：父子 Offset 累加、子节点按列表顺序绘制（后者在上层）
        // ------------------------------------------------------------------
        [Fact]
        public void solid_rectangle()
        {
            Golden(nameof(solid_rectangle), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle blue = scene.Solid(0x2A, 0x6D, 0xD6);
                DUCE.ResourceHandle amber = scene.Solid(0xE8, 0xA0, 0x33);
                DUCE.ResourceHandle green = scene.Solid(0x33, 0x99, 0x55);

                // 根：整块淡灰底
                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 240, 180),
                    Brush = scene.Mh(scene.Solid(0xF2, 0xF2, 0xF2)),
                }));

                // 子 1：偏移 (20,20)，纯色矩形
                MilVisual a = scene.Visual();
                a.Offset = new SKPoint(20, 20);
                a.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 90, 60),
                    Brush = scene.Mh(blue),
                }));

                // 子 1 的子：再偏移 (20,20) → 世界坐标 (40,40)，验证父矩阵 × 偏移
                MilVisual aChild = scene.Visual();
                aChild.Offset = new SKPoint(20, 20);
                aChild.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 90, 60),
                    Brush = scene.Mh(green),
                }));
                a.Children.Add(aChild);

                // 子 2：与子 1 重叠，画在后面 → 必须盖住绿色（验证子节点序）
                MilVisual b = scene.Visual();
                b.Offset = new SKPoint(70, 60);
                b.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 100, 70),
                    Brush = scene.Mh(amber),
                }));

                root.Children.Add(a);
                root.Children.Add(b);
                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  2. 线性渐变填充（Absolute 映射 + Pad 铺展 + 多个停靠点）
        // ------------------------------------------------------------------
        [Fact]
        public void linear_gradient()
        {
            Golden(nameof(linear_gradient), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle hGrad = scene.LinearGradient(0, 0, 200, 0,
                    (0.0, 0xFF, 0x00, 0x00),
                    (0.5, 0x00, 0xC0, 0x00),
                    (1.0, 0x00, 0x00, 0xFF));

                DUCE.ResourceHandle hRel = scene.LinearGradientRelative(0, 0, 1, 1,
                    (0.0, 0xFF, 0xFF, 0x00),
                    (1.0, 0x80, 0x00, 0x80));

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(10, 15, 200, 75),
                        Brush = scene.Mh(hGrad),
                    });
                    // 相对包围盒模式：起止点是 [0,1]，铺满 (20,95)-(130,165)
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(20, 95, 130, 165),
                        Brush = scene.Mh(hRel),
                    });
                });

                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  3. 径向渐变（圆心 = 焦点 → 走 CreateRadialGradient 分支）
        // ------------------------------------------------------------------
        [Fact]
        public void radial_gradient()
        {
            Golden(nameof(radial_gradient), () =>
            {
                var scene = new TestScene();
                // 同心：焦点 == 圆心，rx == ry
                DUCE.ResourceHandle concentric = scene.RadialGradient(70, 90, 60, 60, 70, 90,
                    (0.0, 0xFF, 0xFF, 0xFF),
                    (1.0, 0xC0, 0x20, 0x20));

                // 偏心焦点 + 椭圆：走两点圆锥 + 椭圆压缩分支
                DUCE.ResourceHandle offsetFocus = scene.RadialGradient(170, 90, 55, 40, 150, 78,
                    (0.0, 0x1A, 0x1A, 0x80),
                    (0.6, 0x40, 0xA0, 0xE0),
                    (1.0, 0x05, 0x20, 0x40));

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawEllipse,
                        Point0 = new SKPoint(70, 90),
                        CornerRadius = new SKPoint(65, 65),
                        Brush = scene.Mh(concentric),
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(115, 50, 225, 130),
                        Brush = scene.Mh(offsetFocus),
                    });
                });

                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  4. 椭圆：填充 + 描边同在（FillAndStroke 双路径）
        // ------------------------------------------------------------------
        [Fact]
        public void ellipse_fill_and_stroke()
        {
            Golden(nameof(ellipse_fill_and_stroke), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle fill = scene.Solid(0xFF, 0xE0, 0x8A);
                DUCE.ResourceHandle strokeBrush = scene.Solid(0x33, 0x33, 0x33);
                DUCE.ResourceHandle pen = scene.Pen(strokeBrush, thickness: 4.0);
                DUCE.ResourceHandle thinPen = scene.Pen(scene.Solid(0xD0, 0x30, 0x30), thickness: 1.5);

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    // 正圆 + 粗描边
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawEllipse,
                        Point0 = new SKPoint(70, 60),
                        CornerRadius = new SKPoint(45, 45),
                        Brush = scene.Mh(fill),
                        Pen = scene.Mh(pen),
                    });
                    // 扁椭圆 + 细描边
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawEllipse,
                        Point0 = new SKPoint(165, 120),
                        CornerRadius = new SKPoint(60, 35),
                        Pen = scene.Mh(thinPen),
                    });
                    // 线段：验证 MilDrawLine
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawLine,
                        Point0 = new SKPoint(10, 170),
                        Point1 = new SKPoint(230, 150),
                        Pen = scene.Mh(pen),
                    });
                });

                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  5. 圆角矩形（含 radius=0 退化成直角的分支）
        // ------------------------------------------------------------------
        [Fact]
        public void rounded_rectangle()
        {
            Golden(nameof(rounded_rectangle), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle fill = scene.Solid(0x3C, 0x78, 0xB4);
                DUCE.ResourceHandle pen = scene.Pen(scene.Solid(0x10, 0x30, 0x50), thickness: 3.0);

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRoundedRectangle,
                        Rect = new SKRect(15, 20, 110, 90),
                        CornerRadius = new SKPoint(22, 22),
                        Brush = scene.Mh(fill),
                        Pen = scene.Mh(pen),
                    });
                    // 不等半径
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRoundedRectangle,
                        Rect = new SKRect(130, 20, 225, 90),
                        CornerRadius = new SKPoint(30, 10),
                        Brush = scene.Mh(fill),
                    });
                    // 半径为 0 → 走 AddRect 分支
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRoundedRectangle,
                        Rect = new SKRect(15, 110, 110, 165),
                        CornerRadius = new SKPoint(0, 0),
                        Brush = scene.Mh(fill),
                    });
                    // 几何路径：RectangleGeometry 带圆角（SkiaGeometry 分支）
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawGeometry,
                        Brush = scene.Mh(scene.Solid(0xE0, 0x70, 0x20)),
                        Geometry = scene.Mh(new MilRectangleGeometry
                        {
                            Rect = new MilRect(130, 110, 95, 55),
                            RadiusX = 16,
                            RadiusY = 16,
                        }),
                    });
                });

                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  6. PathGeometry：M/L/C/Q/A + 显式闭合 + EvenOdd 填充 + 抬笔 gap
        // ------------------------------------------------------------------
        [Fact]
        public void path_geometry()
        {
            Golden(nameof(path_geometry), () =>
            {
                var scene = new TestScene();

                // 星形（5 个直线段，闭合，Nonzero）
                byte[] star = new PathGeometryBuilder()
                    .AddFigure(60, 20, isClosed: true)
                        .Line(75, 62).Line(119, 62).Line(84, 88).Line(96, 133)
                        .Line(60, 108).Line(24, 133).Line(36, 88).Line(1, 62).Line(45, 62)
                    .End()
                    .Build();

                // 两段贝塞尔 + 一段二次 + 一段圆弧（不闭合，只描边）
                byte[] curves = new PathGeometryBuilder()
                    .AddFigure(20, 150)
                        .Bezier(50, 110, 90, 190, 120, 150)
                        .Quadratic(150, 115, 180, 150)
                        .Arc(215, 150, 28, 18, 0, largeArc: false, sweep: true)
                    .End()
                    .Build();

                // 两个子路径 + EvenOdd：中间的洞要真的透出来
                byte[] donut = new PathGeometryBuilder()
                    .AddFigure(180, 40, isClosed: true)
                        .Line(230, 40).Line(230, 90).Line(180, 90)
                    .End()
                    .AddFigure(195, 55, isClosed: true)
                        .Line(195, 75).Line(215, 75).Line(215, 55)
                    .End()
                    .Build();

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawGeometry,
                        Brush = scene.Mh(scene.Solid(0xF5, 0xC5, 0x18)),
                        Pen = scene.Mh(scene.Pen(scene.Solid(0x80, 0x50, 0x00), thickness: 2.0)),
                        Geometry = scene.Mh(scene.PathGeometry(star)),
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawGeometry,
                        Pen = scene.Mh(scene.Pen(scene.Solid(0x20, 0x60, 0xA0), thickness: 3.0,
                            cap: MilPenLineCap.Round, join: MilPenLineJoin.Round)),
                        Geometry = scene.Mh(scene.PathGeometry(curves)),
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawGeometry,
                        Brush = scene.Mh(scene.Solid(0x7B, 0x2F, 0xBE)),
                        Geometry = scene.Mh(scene.PathGeometry(donut, MilFillRule.EvenOdd)),
                    });
                    // 直线几何（MilLineGeometry 分支）
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawGeometry,
                        Pen = scene.Mh(scene.Pen(scene.Solid(0x00, 0x00, 0x00), thickness: 1.0)),
                        Geometry = scene.Mh(new MilLineGeometry
                        {
                            StartPoint = new MilPoint(0, 175),
                            EndPoint = new MilPoint(240, 175),
                        }),
                    });
                });

                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  7. 变换：视觉层级联（父矩阵 × Transform × Offset）+ MilPushTransform
        // ------------------------------------------------------------------
        [Fact]
        public void transform_nested()
        {
            Golden(nameof(transform_nested), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle blue = scene.Solid(0x2A, 0x6D, 0xD6, 0xC0);
                DUCE.ResourceHandle red = scene.Solid(0xD6, 0x3A, 0x2A, 0xC0);
                DUCE.ResourceHandle green = scene.Solid(0x2A, 0xA0, 0x60, 0xC0);
                DUCE.ResourceHandle purple = scene.Solid(0x8A, 0x40, 0xC0, 0xC0);

                // 根：整体平移 (30,20) + 缩放 1.1 —— 所有子节点的父矩阵
                MilVisual root = scene.Visual();
                root.Transform = TransformMatrix(scene, 1.1, 0, 0, 1.1, 30, 20);

                // 子 1：再偏移 + 绕自身中心旋转 25°
                MilVisual a = scene.Visual();
                a.Offset = new SKPoint(10, 10);
                a.Transform = Resolve(scene, scene.Rotate(25, 40, 30));
                a.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 80, 60),
                    Brush = scene.Mh(blue),
                }));

                // 子 2：用 MilPushTransform 在指令流里旋转
                DUCE.ResourceHandle pushRot = scene.Rotate(-30, 45, 35);
                MilVisual b = scene.Visual();
                b.Offset = new SKPoint(105, 20);
                b.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilPushTransform,
                        Geometry = scene.Mh(pushRot),
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(0, 0, 70, 50),
                        Brush = scene.Mh(red),
                    });
                    d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });

                    // Pop 之后的矩形不受上面旋转影响
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(5, 55, 65, 95),
                        Brush = scene.Mh(green),
                    });
                });

                // 子 3：TransformGroup（先平移后缩放），验证组合顺序
                DUCE.ResourceHandle group = scene.TransformGroup(
                    scene.Translate(15, 95),
                    scene.Scale(1.3, 0.8));
                MilVisual c = scene.Visual();
                c.Transform = Resolve(scene, group);
                c.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawEllipse,
                    Point0 = new SKPoint(20, 20),
                    CornerRadius = new SKPoint(18, 18),
                    Brush = scene.Mh(purple),
                }));

                root.Children.Add(a);
                root.Children.Add(b);
                root.Children.Add(c);
                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  8. 裁剪：MilVisual.Clip 矩形裁剪
        // ------------------------------------------------------------------
        [Fact]
        public void clip_rect()
        {
            Golden(nameof(clip_rect), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle fill = scene.Solid(0xE0, 0x50, 0x30);
                DUCE.ResourceHandle pen = scene.Pen(scene.Solid(0x20, 0x20, 0x20), thickness: 2.0);

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 240, 180),
                    Brush = scene.Mh(scene.Solid(0xF5, 0xF5, 0xF5)),
                }));

                // 画一个大圆，但被 (60,40)-(140,120) 裁掉一圈
                MilVisual clipped = scene.Visual();
                clipped.Clip = new SKRect(60, 40, 140, 120);
                clipped.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawEllipse,
                        Point0 = new SKPoint(100, 80),
                        CornerRadius = new SKPoint(70, 70),
                        Brush = scene.Mh(fill),
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(20, 20, 220, 160),
                        Pen = scene.Mh(pen),
                    });
                });

                // 裁剪框本身画出来，方便肉眼确认边界
                MilVisual frame = scene.Visual();
                frame.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(60, 40, 140, 120),
                    Pen = scene.Mh(scene.Pen(scene.Solid(0x00, 0x80, 0xFF), thickness: 1.0)),
                }));

                root.Children.Add(clipped);
                root.Children.Add(frame);
                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  9. 裁剪：MilPushClip 用**路径**裁剪（矩形裁剪做不到形状）
        // ------------------------------------------------------------------
        [Fact]
        public void clip_path()
        {
            Golden(nameof(clip_path), () =>
            {
                var scene = new TestScene();

                byte[] diamond = new PathGeometryBuilder()
                    .AddFigure(120, 20, isClosed: true)
                        .Line(200, 90).Line(120, 160).Line(40, 90)
                    .End()
                    .Build();

                DUCE.ResourceHandle clipGeom = scene.PathGeometry(diamond);

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(0, 0, 240, 180),
                        Brush = scene.Mh(scene.Solid(0xFA, 0xFA, 0xFA)),
                    });

                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilPushClip,
                        Geometry = scene.Mh(clipGeom),
                    });

                    // 被菱形裁掉的横向条纹
                    DUCE.ResourceHandle stripe = scene.Solid(0x30, 0x70, 0xC0);
                    for (int i = 0; i < 9; i++)
                    {
                        float y = 20 + i * 18;
                        d.Add(new MilDrawInstruction
                        {
                            Command = MilDrawCommand.MilDrawRectangle,
                            Rect = new SKRect(0, y, 240, y + 9),
                            Brush = scene.Mh(stripe),
                        });
                    }

                    d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });

                    // Pop 之后不再受裁剪：整幅边框应该完整
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(4, 4, 236, 176),
                        Pen = scene.Mh(scene.Pen(scene.Solid(0xC0, 0x20, 0x20), thickness: 2.0)),
                    });
                });

                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  10. 不透明度：MilVisual.Opacity（层级相乘）+ MilPushOpacity
        // ------------------------------------------------------------------
        [Fact]
        public void opacity()
        {
            Golden(nameof(opacity), () =>
            {
                var scene = new TestScene();

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 240, 180),
                    Brush = scene.Mh(scene.Solid(0xFF, 0xFF, 0xFF)),
                }));

                // 参考色块：不透明，用来对比
                MilVisual solidRef = scene.Visual();
                solidRef.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(15, 20, 75, 80),
                    Brush = scene.Mh(scene.Solid(0xD6, 0x2A, 0x2A)),
                }));

                // 父 Opacity=0.5，子 Opacity=0.5 → 实际 0.25（验证累乘）
                MilVisual parent = scene.Visual();
                parent.Opacity = 0.5;
                MilVisual child = scene.Visual();
                child.Opacity = 0.5;
                child.Offset = new SKPoint(90, 20);
                child.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 60, 60),
                    Brush = scene.Mh(scene.Solid(0xD6, 0x2A, 0x2A)),
                }));
                parent.Children.Add(child);

                // MilPushOpacity 0.35
                MilVisual pushed = scene.Visual();
                pushed.Offset = new SKPoint(165, 20);
                pushed.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilPushOpacity,
                        Opacity = 0.35,
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(0, 0, 60, 60),
                        Brush = scene.Mh(scene.Solid(0x2A, 0x2A, 0xD6)),
                    });
                    d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                    // Pop 之后恢复全不透明
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(0, 65, 60, 95),
                        Brush = scene.Mh(scene.Solid(0x2A, 0x2A, 0xD6)),
                    });
                });

                // 画刷自带 Opacity=0.5 的纯色块
                MilVisual brushAlpha = scene.Visual();
                brushAlpha.Offset = new SKPoint(15, 100);
                brushAlpha.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 60, 60),
                    Brush = scene.Mh(scene.SolidWithOpacity(0x20, 0xA0, 0x40, 0.5)),
                }));

                root.Children.Add(solidRef);
                root.Children.Add(parent);
                root.Children.Add(pushed);
                root.Children.Add(brushAlpha);
                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  11. 描边虚线：验证"虚线长度 = 线宽 × 倍数"这条 WPF 语义
        //      三条线用**同一份** DashStyle，只有线宽不同：
        //      线宽翻倍，虚线节距也必须翻倍。前任代码漏了这步乘法。
        // ------------------------------------------------------------------
        [Fact]
        public void dash_stroke()
        {
            Golden(nameof(dash_stroke), () =>
            {
                var scene = new TestScene();

                // 同一份虚线样式：实 2 / 空 2（单位＝线宽）
                DUCE.ResourceHandle dash = scene.DashStyle(0.0, 2.0, 2.0);
                DUCE.ResourceHandle dot = scene.DashStyle(0.0, 0.0, 2.0);
                DUCE.ResourceHandle black = scene.Solid(0x11, 0x11, 0x11);

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    // 线宽 2 / 4 / 8，节距应分别为 8 / 16 / 32 像素
                    float[] widths = { 2f, 4f, 8f };
                    for (int i = 0; i < widths.Length; i++)
                    {
                        float y = 28 + i * 26;
                        d.Add(new MilDrawInstruction
                        {
                            Command = MilDrawCommand.MilDrawLine,
                            Point0 = new SKPoint(12, y),
                            Point1 = new SKPoint(228, y),
                            Pen = scene.Mh(scene.Pen(black, widths[i], dashStyle: dash)),
                        });
                    }

                    // 点线（首段长度 0 → 圆点），带 Round 线帽
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawLine,
                        Point0 = new SKPoint(12, 112),
                        Point1 = new SKPoint(228, 112),
                        Pen = scene.Mh(scene.Pen(black, 6.0,
                            cap: MilPenLineCap.Round, join: MilPenLineJoin.Round, dashStyle: dot)),
                    });

                    // 虚线 + 矩形描边（验证 dash 作用在闭合路径上）+ 非零 Offset
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(12, 128, 228, 170),
                        Pen = scene.Mh(scene.Pen(scene.Solid(0xB0, 0x20, 0x60), 3.0,
                            dashStyle: scene.DashStyle(1.0, 3.0, 1.0))),
                    });
                });

                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  12. *Animate 变体：按静态终值渲染（动画时间线不在本轮范围）
        //      同样的几何各画一份静态版与 Animate 版，两图应当逐像素一致。
        // ------------------------------------------------------------------
        [Fact]
        public void animate_static_end_value()
        {
            Golden(nameof(animate_static_end_value), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle brush = scene.Solid(0x30, 0x70, 0xC0);
                DUCE.ResourceHandle pen = scene.Pen(scene.Solid(0x20, 0x20, 0x20), 2.0);

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    // --- 矩形：静态版（左） vs Animate 版（右，偏移 120） ---
                    var rect = new SKRect(10, 15, 100, 75);
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = rect,
                        Brush = scene.Mh(brush),
                        Pen = scene.Mh(pen),
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangleAnimate,
                    }, RectangleAnimatePayload(rect, scene.Mh(brush), scene.Mh(pen), 120, 0));

                    // --- 圆角矩形 ---
                    var rounded = new SKRect(10, 90, 100, 135);
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRoundedRectangle,
                        Rect = rounded,
                        CornerRadius = new SKPoint(12, 12),
                        Brush = scene.Mh(brush),
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRoundedRectangleAnimate,
                    }, RoundedAnimatePayload(rounded, 12, 12, scene.Mh(brush),
                        MilResourceHandle.Null, 120, 0));

                    // --- 椭圆 ---
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawEllipse,
                        Point0 = new SKPoint(55, 155),
                        CornerRadius = new SKPoint(40, 18),
                        Brush = scene.Mh(brush),
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawEllipseAnimate,
                    }, EllipseAnimatePayload(
                        new SKPoint(55, 155), 40, 18, scene.Mh(brush),
                        MilResourceHandle.Null, 120, 0));

                    // --- 线段 ---
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawLine,
                        Point0 = new SKPoint(10, 175),
                        Point1 = new SKPoint(100, 175),
                        Pen = scene.Mh(pen),
                    });
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawLineAnimate,
                    }, LineAnimatePayload(
                        new SKPoint(10, 175), new SKPoint(100, 175), scene.Mh(pen), 120, 0));
                });

                return (scene, root);
            });
        }

        // ==================================================================
        //  载荷字节构造（对应上游 Generated/RenderData.cs 的 FieldOffset）
        // ==================================================================

        /// <summary>MILCMD_DRAW_RECTANGLE_ANIMATE：rectangle@0(32) hBrush@32 hPen@36 + 动画句柄。</summary>
        private static byte[] RectangleAnimatePayload(
            SKRect rect, MilResourceHandle brush, MilResourceHandle pen, float dx, float dy)
        {
            using var ms = new MemoryStream();
            using var w = new BinaryWriter(ms);
            w.Write((double)(rect.Left + dx));
            w.Write((double)(rect.Top + dy));
            w.Write((double)rect.Width);
            w.Write((double)rect.Height);
            w.Write(brush.Value);
            w.Write(pen.Value);
            w.Write(0u);   // hRectangleAnimations
            w.Write(0u);   // QuadWordPad
            return ms.ToArray();
        }

        /// <summary>MILCMD_DRAW_ROUNDED_RECTANGLE_ANIMATE：rect@0 rX@32 rY@40 hBrush@48 hPen@52。</summary>
        private static byte[] RoundedAnimatePayload(
            SKRect rect, double rx, double ry,
            MilResourceHandle brush, MilResourceHandle pen, float dx, float dy)
        {
            using var ms = new MemoryStream();
            using var w = new BinaryWriter(ms);
            w.Write((double)(rect.Left + dx));
            w.Write((double)(rect.Top + dy));
            w.Write((double)rect.Width);
            w.Write((double)rect.Height);
            w.Write(rx);
            w.Write(ry);
            w.Write(brush.Value);
            w.Write(pen.Value);
            w.Write(0u); w.Write(0u); w.Write(0u);   // 三个动画句柄
            w.Write(0u);                             // QuadWordPad
            return ms.ToArray();
        }

        /// <summary>MILCMD_DRAW_ELLIPSE_ANIMATE：center@0 rX@16 rY@24 hBrush@32 hPen@36。</summary>
        private static byte[] EllipseAnimatePayload(
            SKPoint center, double rx, double ry,
            MilResourceHandle brush, MilResourceHandle pen, float dx, float dy)
        {
            using var ms = new MemoryStream();
            using var w = new BinaryWriter(ms);
            w.Write((double)(center.X + dx));
            w.Write((double)(center.Y + dy));
            w.Write(rx);
            w.Write(ry);
            w.Write(brush.Value);
            w.Write(pen.Value);
            w.Write(0u); w.Write(0u); w.Write(0u);
            w.Write(0u);
            return ms.ToArray();
        }

        /// <summary>MILCMD_DRAW_LINE_ANIMATE：point0@0(16) point1@16(16) hPen@32。</summary>
        private static byte[] LineAnimatePayload(
            SKPoint p0, SKPoint p1, MilResourceHandle pen, float dx, float dy)
        {
            using var ms = new MemoryStream();
            using var w = new BinaryWriter(ms);
            w.Write((double)(p0.X + dx));
            w.Write((double)(p0.Y + dy));
            w.Write((double)(p1.X + dx));
            w.Write((double)(p1.Y + dy));
            w.Write(pen.Value);
            w.Write(0u); w.Write(0u);
            w.Write(0u);
            return ms.ToArray();
        }

        // ==================================================================
        //  13. ImageBrush（TileBrush）四象限：Fill / Tile 平铺 / Uniform 居中 / None 1:1
        // ==================================================================
        // ⚠️【T2b 重生成说明 · 条件④】旧基准图锁的是「绝对单位 Viewport 以**画布原点**解释」
        //   这个已被真机否定的错误行为（oracle units_vpabs_viewboxabs_tile：包围盒局部原点
        //   194/194 吻合 vs 画布原点 20/216，瓦片原点实测 (26,26)）；
        //   本图已按**真机局部坐标系**重生成 —— 不是“我们又改了一次基准”。
        [Fact]
        public void image_brush()
        {
            GoldenRunner.Run(nameof(image_brush), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle bmp = scene.BitmapSourceHandle();
                SKBitmap checker = scene.Own(TestScene.MakeCheckerboard(60, 6));
                scene.Provider.BitmapResolver =
                    h => h.Equals(scene.Mh(bmp)) ? checker : null;

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    // Q1 左上：Stretch=Fill + Tile=None —— 棋盘格拉伸铺满整个矩形
                    d.Add(Rect(10, 10, 140, 90,
                        scene.ImageBrush(bmp, MilStretch.Fill, MilTileMode.None)));

                    // Q2 右上：viewport 35×30 的小基块 + Tile=Repeat —— 平铺出重复花纹
                    d.Add(Rect(170, 10, 140, 90,
                        scene.ImageBrush(bmp, MilStretch.Fill, MilTileMode.Tile,
                            viewport: new MilRect(0, 0, 35, 30))));

                    // Q3 左下：Stretch=Uniform 居中 —— 60×60 等比放大到 90×90，
                    // 在 140×90 的矩形里上下居中、左右留白
                    d.Add(Rect(10, 120, 140, 90,
                        scene.ImageBrush(bmp, MilStretch.Uniform, MilTileMode.None)));

                    // Q4 右下：Stretch=None —— 1:1 画在矩形原点，其余部分透明（Tile=None）
                    d.Add(Rect(170, 120, 140, 90,
                        scene.ImageBrush(bmp, MilStretch.None, MilTileMode.None)));
                });

                return (scene, root);
            }, Output, width: 320, height: 220);
        }

        private static MilDrawInstruction Rect(
            float x, float y, float w, float h, DUCE.ResourceHandle brush) =>
            new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(x, y, x + w, y + h),
                Brush = new MilResourceHandle((uint)brush),
            };

        // ==================================================================
        //  辅助
        // ==================================================================

        private static SKMatrix TransformMatrix(
            TestScene scene, double m11, double m12, double m21, double m22, double dx, double dy)
            => Resolve(scene, scene.Matrix(m11, m12, m21, m22, dx, dy));

        /// <summary>变换句柄 → 矩阵，走真实的 TransformResolver。</summary>
        private static SKMatrix Resolve(TestScene scene, DUCE.ResourceHandle handle)
            => TransformResolver.Resolve(scene.Channel, handle);
    }
}

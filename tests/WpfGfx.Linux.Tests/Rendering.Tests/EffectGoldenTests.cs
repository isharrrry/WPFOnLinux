// 位图效果的 golden 用例。名字即基准图名：tests/golden/<name>.png。
//
// 与 EffectTests 的分工：
//   EffectTests       —— 断言式（采样点、逐像素等价、裁剪不越界），跑得快、失败时直指性质
//   EffectGoldenTests —— 锁"整幅长什么样"，一次改动把全图所有像素都钉住
//
// 三张图各自想抓住的东西：
//   effect_blur        同一几何、三档模糊半径的梯度；另外验证效果作用于**整段绘制**
//                      （填充和描边一起被模糊），而不只是填充。
//   effect_drop_shadow 四个角落各一个方块，阴影方向 45/135/225/315 分别指向
//                      右上/左上/左下/右下，外加一个正下方（270°）的红色阴影。
//                      方向或 Y 轴符号写反，四个角的阴影会立刻站错位置。
//   effect_blur_clipped 模糊被裁剪框切断：框外必须干净，这是"效果不越界"的直观留证。

using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class EffectGoldenTests
    {
        public EffectGoldenTests(ITestOutputHelper output) => Output = output;

        private ITestOutputHelper Output { get; }

        private void Golden(string name, SceneFactory build) => GoldenRunner.Run(name, build, Output);

        // ------------------------------------------------------------------
        //  1. Blur：同一矩形，三档半径
        // ------------------------------------------------------------------
        [Fact]
        public void effect_blur()
        {
            Golden(nameof(effect_blur), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle blue = scene.Solid(0x2A, 0x6D, 0xD6);
                DUCE.ResourceHandle slate = scene.Solid(0x33, 0x40, 0x50);

                // 上排：锐利 → 中等 → 重模糊，同一尺寸同一颜色，只改半径。
                DUCE.ResourceHandle none = scene.Add(new MilBlurEffect { Radius = 0.0 });
                DUCE.ResourceHandle mild = scene.Add(new MilBlurEffect { Radius = 4.0 });
                DUCE.ResourceHandle heavy = scene.Add(new MilBlurEffect { Radius = 12.0 });

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(0, 0, 240, 180),
                        Brush = scene.Mh(scene.Solid(0xFF, 0xFF, 0xFF)),
                    });

                    DrawBlurredRect(scene, d, none, blue, new SKRect(20, 20, 70, 60));
                    DrawBlurredRect(scene, d, mild, blue, new SKRect(95, 20, 145, 60));
                    DrawBlurredRect(scene, d, heavy, blue, new SKRect(170, 20, 220, 60));

                    // 下排左：圆角矩形 + 描边，两者一起被模糊（不只填充）。
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilPushEffect,
                    }, PushEffect(scene.Mh(scene.Add(new MilBlurEffect { Radius = 6.0 }))));
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRoundedRectangle,
                        Rect = new SKRect(20, 95, 110, 155),
                        CornerRadius = new SKPoint(16, 16),
                        Brush = scene.Mh(scene.Solid(0xE0, 0x70, 0x20)),
                        Pen = scene.Mh(scene.Pen(slate, 4.0)),
                    });
                    d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });

                    // 下排右：椭圆 + 较重模糊，边缘应完全化开。
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilPushEffect,
                    }, PushEffect(scene.Mh(scene.Add(new MilBlurEffect { Radius = 10.0 }))));
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawEllipse,
                        Point0 = new SKPoint(175, 125),
                        CornerRadius = new SKPoint(38, 26),
                        Brush = scene.Mh(scene.Solid(0x33, 0x99, 0x55)),
                    });
                    d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                });

                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  2. DropShadow：四个方向 + 一个彩色阴影
        // ------------------------------------------------------------------
        [Fact]
        public void effect_drop_shadow()
        {
            Golden(nameof(effect_drop_shadow), () =>
            {
                var scene = new TestScene();
                DUCE.ResourceHandle white = scene.Solid(0xFF, 0xFF, 0xFF);

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(0, 0, 240, 180),
                        Brush = scene.Mh(white),
                    });

                    // 四角：方向 45/135/225/315 → 右上 / 左上 / 左下 / 右下
                    DrawShadowedSquare(scene, d, new SKRect(40, 35, 76, 71), 45.0);
                    DrawShadowedSquare(scene, d, new SKRect(164, 35, 200, 71), 135.0);
                    DrawShadowedSquare(scene, d, new SKRect(40, 109, 76, 145), 225.0);
                    DrawShadowedSquare(scene, d, new SKRect(164, 109, 200, 145), 315.0);

                    // 中央：方向 270（正下方）的**红色**阴影，验证 Color 通道。
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilPushEffect,
                    }, PushEffect(scene.Mh(scene.Add(new MilDropShadowEffect
                    {
                        ShadowDepth = 11.0,
                        Direction = 270.0,
                        BlurRadius = 4.0,
                        Opacity = 0.9,
                        Color = SkiaColor.MakeScRgb(0xC0, 0x20, 0x20, 255),
                    }))));
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(104, 74, 136, 106),
                        Brush = scene.Mh(scene.Solid(0xF0, 0xF0, 0xF0)),
                        Pen = scene.Mh(scene.Pen(scene.Solid(0x40, 0x40, 0x40), 2.0)),
                    });
                    d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                });

                return (scene, root);
            });
        }

        // ------------------------------------------------------------------
        //  3. Blur 被裁剪框切断：框外必须干净
        // ------------------------------------------------------------------
        [Fact]
        public void effect_blur_clipped()
        {
            Golden(nameof(effect_blur_clipped), () =>
            {
                var scene = new TestScene();

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 240, 180),
                    Brush = scene.Mh(scene.Solid(0xFF, 0xFF, 0xFF)),
                }));

                // 被裁剪的那一层：粗横条 + 一个圆，全部套上重模糊。
                // 若模糊越过裁剪边界，框外会出现灰边 —— 图上一眼可见。
                MilVisual clipped = scene.Visual();
                clipped.Clip = new SKRect(70, 40, 170, 140);
                clipped.Content = scene.RenderData(d =>
                {
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilPushEffect,
                    }, PushEffect(scene.Mh(scene.Add(new MilBlurEffect { Radius = 14.0 }))));

                    DUCE.ResourceHandle stripe = scene.Solid(0x30, 0x70, 0xC0);
                    for (int i = 0; i < 4; i++)
                    {
                        float y = 50 + i * 24;
                        d.Add(new MilDrawInstruction
                        {
                            Command = MilDrawCommand.MilDrawRectangle,
                            Rect = new SKRect(20, y, 220, y + 12),
                            Brush = scene.Mh(stripe),
                        });
                    }

                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawEllipse,
                        Point0 = new SKPoint(120, 90),
                        CornerRadius = new SKPoint(34, 34),
                        Brush = scene.Mh(scene.Solid(0xD6, 0x2A, 0x2A)),
                    });

                    d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                });

                // 裁剪框本身：画在裁剪之外，所以能把边界完整描出来。
                MilVisual frame = scene.Visual();
                frame.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(70, 40, 170, 140),
                    Pen = scene.Mh(scene.Pen(scene.Solid(0xC0, 0x20, 0x20), 1.0)),
                }));

                root.Children.Add(clipped);
                root.Children.Add(frame);
                return (scene, root);
            });
        }

        // ==================================================================
        //  辅助
        // ==================================================================

        /// <summary>MILCMD_PUSH_EFFECT：hEffect@0(4) hEffectInput@4(4)。</summary>
        private static byte[] PushEffect(MilResourceHandle hEffect)
        {
            var b = new byte[8];
            System.BitConverter.GetBytes(hEffect.Value).CopyTo(b, 0);
            return b;
        }

        private static void DrawBlurredRect(
            TestScene scene, DrawList d, DUCE.ResourceHandle effect,
            DUCE.ResourceHandle brush, SKRect rect)
        {
            d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushEffect },
                  PushEffect(scene.Mh(effect)));
            d.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = rect,
                Brush = scene.Mh(brush),
            });
            d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
        }

        private static void DrawShadowedSquare(
            TestScene scene, DrawList d, SKRect rect, double direction)
        {
            d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushEffect },
                  PushEffect(scene.Mh(scene.Add(new MilDropShadowEffect
                  {
                      ShadowDepth = 9.0,
                      Direction = direction,
                      BlurRadius = 5.0,
                      Opacity = 0.85,
                      Color = SkiaColor.MakeScRgb(0x20, 0x20, 0x20, 255),
                  }))));
            d.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = rect,
                Brush = scene.Mh(scene.Solid(0xF5, 0xC5, 0x18)),
                Pen = scene.Mh(scene.Pen(scene.Solid(0x60, 0x40, 0x00), 1.5)),
            });
            d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
        }
    }
}

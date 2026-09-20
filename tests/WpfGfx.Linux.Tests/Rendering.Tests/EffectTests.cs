// 位图效果（MilPushEffect 0x55）的断言式测试。不依赖 golden，全部是像素判据。
//
// 【几何约定，改任何一个采样点前先读这段】
//   画布 240×180，底色白。被画的内容是一个黑矩形 (40,40)-(200,140)。
//   把"内容"和"阴影"分开的关键：偏移后的阴影会探出内容边界，形成一条只有阴影、
//   没有内容的窄边。采样点全部落在这些窄边上，这样断言测的是**阴影**而不是内容。
//
//   Direction=315（WPF 默认）→ dx=+0.707·depth, dy=+0.707·depth，阴影朝**右下**，
//   探出内容的窄边在 x∈(200, 208.5] 与 y∈(140, 148.5]。
//   Direction=135            → dx=-0.707·depth, dy=-0.707·depth，阴影朝**左上**，
//   窄边在 x∈[31.5, 40) 与 y∈[31.5, 40)。
//   两条方向各钉一个采样点，Skia 的 Y 轴符号一旦写反，必有一侧落空成白色。
//   （depth=12 → 0.707×12 ≈ 8.49）
//
// 【为什么"半径 0 等同无效果"要用 ImageComparer 逐像素比，而不是比几个采样点】
//   只比采样点会漏掉"整层多压了一次导致半透明内容被改变"这类错误。逐像素比能
//   一次性覆盖全图，且容差沿用 golden 的 Δ≤2，与仓库其余部分同一把尺子。

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
    public class EffectTests
    {
        private readonly ITestOutputHelper _o;
        public EffectTests(ITestOutputHelper o) => _o = o;

        /// <summary>被画的内容：一个横贯画布中部的矩形。</summary>
        private static readonly SKRect Shape = new SKRect(40, 40, 200, 140);

        // ==================================================================
        //  场景构造
        // ==================================================================

        /// <summary>
        /// 白底 + 一个纯色矩形。<paramref name="effect"/> 非空时套一层 MilPushEffect/MilPop，
        /// <paramref name="clip"/> 非空时给根视觉加矩形裁剪。
        /// </summary>
        private static (TestScene Scene, MilVisual Root) BuildScene(
            MilResource effect, SKColor color, SKRect? clip = null, SKRect? shape = null)
        {
            var scene = new TestScene();
            DUCE.ResourceHandle hBrush = scene.Solid(color.Red, color.Green, color.Blue, color.Alpha);
            MilResourceHandle hEffect = effect != null ? scene.Mh(effect) : MilResourceHandle.Null;

            MilVisual root = scene.Visual();
            if (clip.HasValue) root.Clip = clip.Value;

            root.Content = scene.RenderData(d =>
            {
                if (!hEffect.IsNull)
                {
                    d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushEffect },
                          PushEffectPayload(hEffect));
                }
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = shape ?? Shape,
                    Brush = scene.Mh(hBrush),
                });
                if (!hEffect.IsNull)
                    d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
            });

            return (scene, root);
        }

        private static RenderOutput Render(
            MilResource effect, SKColor color, SKRect? clip = null, SKRect? shape = null)
        {
            (TestScene scene, MilVisual root) = BuildScene(effect, color, clip, shape);
            using (scene) return RenderHarness.Render(root, scene.Provider);
        }

        /// <summary>MILCMD_PUSH_EFFECT：hEffect@0(4) hEffectInput@4(4)。</summary>
        private static byte[] PushEffectPayload(MilResourceHandle hEffect)
        {
            var b = new byte[8];
            BitConverter.GetBytes(hEffect.Value).CopyTo(b, 0);
            return b;   // hEffectInput 留空：Blur/DropShadow 上游一律传空，见 SkiaEffect.cs 文件头
        }

        // ==================================================================
        //  断言辅助
        // ==================================================================

        /// <summary>统计矩形区域内的非纯白像素数。</summary>
        private static int CountNonWhite(SKBitmap bmp, int x0, int y0, int x1, int y1)
        {
            int n = 0;
            for (int y = y0; y <= y1; y++)
                for (int x = x0; x <= x1; x++)
                {
                    SKColor c = bmp.GetPixel(x, y);
                    if (c.Red != 255 || c.Green != 255 || c.Blue != 255) n++;
                }
            return n;
        }

        private static string Pixel(SKBitmap bmp, int x, int y) => bmp.GetPixel(x, y).ToString();

        /// <summary>沿一行扫出亮度序列，仅用于失败诊断。</summary>
        private static string Scan(SKBitmap bmp, int y, int x0, int x1)
        {
            var parts = new System.Collections.Generic.List<string>();
            for (int x = x0; x <= x1; x += 2) parts.Add($"{x}:{Luma(bmp, x, y)}");
            return string.Join(" ", parts);
        }

        /// <summary>纯色效果的"暗度"：0=全黑，255=全白。用红色通道当代表。</summary>
        private static int Luma(SKBitmap bmp, int x, int y) => bmp.GetPixel(x, y).Red;

        private void Dump(string label, RenderOutput r, params (int X, int Y)[] points)
        {
            var parts = new System.Collections.Generic.List<string>();
            foreach ((int x, int y) in points) parts.Add($"({x},{y})={Pixel(r.Bitmap, x, y)}");
            _o.WriteLine($"[{label}] {string.Join(" ", parts)} " +
                         $"未画出={r.Diagnostics.NotDrawn.Count} 栈 {r.InitialSaveCount}->{r.FinalSaveCount}");
        }

        /// <summary>两条渲染结果必须逐像素一致（容差沿用 golden 的 Δ≤2）。</summary>
        private static void AssertPixelIdentical(string what, SKBitmap actual, SKBitmap expected)
        {
            CompareResult cmp = ImageComparer.Compare(actual, expected);
            Assert.True(cmp.Passed,
                $"{what}：应与无效果渲染逐像素一致，但 {cmp.Message}");
        }

        // ==================================================================
        //  1. 效果确实生效（像素判据，不只是"不抛异常"）
        // ==================================================================

        [Fact]
        public void Blur_changes_pixels_and_softens_the_edge()
        {
            using SKBitmap plain = Render(null, SKColors.Black).Bitmap;
            RenderOutput blurred = Render(new MilBlurEffect { Radius = 9.0 }, SKColors.Black);
            using SKBitmap blur = blurred.Bitmap;

            // 整体必须和"无效果"不一样 —— 这是"效果生效"的底线。
            CompareResult cmp = ImageComparer.Compare(blur, plain);
            Assert.True(cmp.DifferingPixels > 0,
                "Blur 与无效果渲染逐像素相同 —— 效果根本没生效（只是没抛异常）。");

            // 内容内部依旧是实心黑：模糊不能把不透明的大色块洗淡。
            Assert.Equal(0, Luma(blur, 120, 90));
            Assert.Equal(0, Luma(plain, 120, 90));

            // 边界外 4px：无效果是纯白，模糊必须洇出一点灰。
            Assert.Equal(255, Luma(plain, 36, 90));
            Assert.True(Luma(blur, 36, 90) < 245,
                $"Blur 应当在矩形左边界外洇出灰色，实测 (36,90)={Pixel(blur, 36, 90)}");

            // 单调性：离边界越远越淡，证明这是渐变而非硬边位移。
            Assert.True(Luma(blur, 36, 90) > Luma(blur, 40, 90),
                $"模糊应单调衰减：内部比边界外更暗，实测 36→{Luma(blur, 36, 90)} 40→{Luma(blur, 40, 90)}");

            Dump("blur", blurred, (36, 90), (40, 90), (120, 90));
        }

        [Fact]
        public void DropShadow_changes_pixels_outside_the_content()
        {
            using SKBitmap plain = Render(null, SKColors.Black).Bitmap;
            using SKBitmap shadow = Render(
                new MilDropShadowEffect
                {
                    ShadowDepth = 12.0,
                    Direction = 315.0,
                    BlurRadius = 0.0,
                    Opacity = 1.0,
                    Color = SkiaColor.MakeScRgb(0, 0, 0, 255),
                }, SKColors.Black).Bitmap;

            CompareResult cmp = ImageComparer.Compare(shadow, plain);
            Assert.True(cmp.DifferingPixels > 0,
                "DropShadow 与无效果渲染逐像素相同 —— 效果根本没生效。");

            // 内容右侧的窄边：只有阴影、没有内容。无效果时这里是白的。
            Assert.Equal(255, Luma(plain, 204, 90));
            Assert.True(Luma(shadow, 204, 90) < 60,
                $"DropShadow 应在内容右外侧投出阴影，实测 (204,90)={Pixel(shadow, 204, 90)}");

            // 内容本身仍然可见（WPF 语义：阴影在内容**后面**，不是替换掉内容）。
            Assert.Equal(0, Luma(shadow, 120, 90));
        }

        // ==================================================================
        //  2. 退化为无效果的参数必须与"无效果"逐像素一致
        // ==================================================================

        [Theory]
        [InlineData(0.0)]
        [InlineData(-3.0)]
        [InlineData(double.NaN)]
        public void Blur_degenerate_radius_is_pixel_identical_to_no_effect(double radius)
        {
            using SKBitmap plain = Render(null, SKColors.Black).Bitmap;

            RenderOutput r = Render(new MilBlurEffect { Radius = radius }, SKColors.Black);
            using (r.Bitmap)
            {
                AssertPixelIdentical($"Blur(Radius={radius})", r.Bitmap, plain);

                // 关键：效果被**认出来了**、只是退化成空操作，所以不该记进 NotDrawn。
                Assert.Empty(r.Diagnostics.NotDrawn);
                Assert.True(r.IsStackBalanced, "Push/Pop 未配平");
            }
        }

        [Fact]
        public void DropShadow_zero_depth_and_zero_blur_is_pixel_identical_to_no_effect()
        {
            using SKBitmap plain = Render(null, SKColors.Black).Bitmap;

            RenderOutput r = Render(new MilDropShadowEffect
            {
                ShadowDepth = 0.0,
                BlurRadius = 0.0,
                Direction = 315.0,
                Opacity = 1.0,
                Color = SkiaColor.MakeScRgb(0, 0, 0, 255),
            }, SKColors.Black);

            using (r.Bitmap)
            {
                AssertPixelIdentical("DropShadow(0,0)", r.Bitmap, plain);
                Assert.Empty(r.Diagnostics.NotDrawn);
                Assert.True(r.IsStackBalanced);
            }
        }

        [Fact]
        public void DropShadow_fully_transparent_color_is_pixel_identical_to_no_effect()
        {
            using SKBitmap plain = Render(null, SKColors.Black).Bitmap;

            // Opacity=0 的阴影画出来是 0 贡献，等价于无效果。
            RenderOutput r = Render(new MilDropShadowEffect
            {
                ShadowDepth = 12.0,
                BlurRadius = 4.0,
                Direction = 315.0,
                Opacity = 0.0,
                Color = SkiaColor.MakeScRgb(0, 0, 0, 255),
            }, SKColors.Black);

            using (r.Bitmap)
            {
                AssertPixelIdentical("DropShadow(Opacity=0)", r.Bitmap, plain);
                Assert.Empty(r.Diagnostics.NotDrawn);
                Assert.True(r.IsStackBalanced);
            }
        }

        // ==================================================================
        //  3. 效果不得越界污染裁剪区域之外
        // ==================================================================

        [Fact]
        public void Blur_does_not_bleed_outside_the_clip()
        {
            // 裁剪到画布左半边；矩形本身横跨 x=40..200，被切掉右半截。
            var clip = new SKRect(0, 0, 120, 180);

            using SKBitmap unclipped = Render(new MilBlurEffect { Radius = 15.0 }, SKColors.Black).Bitmap;
            RenderOutput clipped = Render(new MilBlurEffect { Radius = 15.0 }, SKColors.Black, clip);
            using SKBitmap clippedBmp = clipped.Bitmap;

            // 裁剪确实生效了：未裁剪时 (150,90) 是黑内容，裁剪后必须是白。
            Assert.Equal(0, Luma(unclipped, 150, 90));
            Assert.Equal(255, Luma(clippedBmp, 150, 90));

            // 裁剪线右侧整片区域（含模糊能洇到的范围）必须一个非白像素都没有。
            int leaked = CountNonWhite(clippedBmp, 122, 0, 239, 179);
            Assert.Equal(0, leaked);

            // 裁剪区内确实画上了东西，避免"整幅空白"式的假通过。
            Assert.True(CountNonWhite(clippedBmp, 0, 0, 118, 179) > 1000,
                "裁剪区内应当有内容，否则这条断言失去了意义。");

            Dump("blur+clip", clipped, (110, 90), (150, 90));
        }

        [Fact]
        public void DropShadow_does_not_bleed_outside_the_clip()
        {
            var clip = new SKRect(0, 0, 120, 180);

            RenderOutput r = Render(new MilDropShadowEffect
            {
                ShadowDepth = 20.0,
                Direction = 315.0,
                BlurRadius = 6.0,
                Opacity = 1.0,
                Color = SkiaColor.MakeScRgb(0, 0, 0, 255),
            }, SKColors.Black, clip);

            using (r.Bitmap)
            {
                // 阴影朝右下、深度 20（≈14px 偏移），裁剪线在 x=120，右侧必须干净。
                Assert.Equal(0, CountNonWhite(r.Bitmap, 122, 0, 239, 179));
                Assert.True(CountNonWhite(r.Bitmap, 0, 0, 118, 179) > 1000);
            }
        }

        // ==================================================================
        //  4. DropShadow 的 偏移 / 颜色 / 半径 三个参数各自生效
        // ==================================================================

        [Fact]
        public void DropShadow_direction_315_offsets_the_shadow_down_right()
        {
            RenderOutput r = Render(Shadow(depth: 12.0, direction: 315.0, blur: 0.0), SKColors.Black);
            using (r.Bitmap)
            {
                Dump("dir315", r, (36, 90), (204, 90), (120, 144), (120, 36));

                // 右侧窄边：有阴影、无内容 → 暗
                Assert.True(Luma(r.Bitmap, 204, 90) < 60, $"(204,90) 应为阴影，实测 {Pixel(r.Bitmap, 204, 90)}");
                // 下侧窄边：有阴影、无内容 → 暗
                Assert.True(Luma(r.Bitmap, 120, 144) < 60, $"(120,144) 应为阴影，实测 {Pixel(r.Bitmap, 120, 144)}");

                // 左侧：315° 不该有阴影 → 白
                Assert.Equal(255, Luma(r.Bitmap, 36, 90));
                // 上侧：同上 → 白
                Assert.Equal(255, Luma(r.Bitmap, 120, 36));
            }
        }

        [Fact]
        public void DropShadow_direction_135_offsets_the_shadow_up_left()
        {
            RenderOutput r = Render(Shadow(depth: 12.0, direction: 135.0, blur: 0.0), SKColors.Black);
            using (r.Bitmap)
            {
                Dump("dir135", r, (36, 90), (204, 90), (120, 36), (120, 144));

                // 与 315° 严格镜像：左侧 / 上侧有阴影
                Assert.True(Luma(r.Bitmap, 36, 90) < 60, $"(36,90) 应为阴影，实测 {Pixel(r.Bitmap, 36, 90)}");
                Assert.True(Luma(r.Bitmap, 120, 36) < 60, $"(120,36) 应为阴影，实测 {Pixel(r.Bitmap, 120, 36)}");

                // 右侧 / 下侧没有
                Assert.Equal(255, Luma(r.Bitmap, 204, 90));
                Assert.Equal(255, Luma(r.Bitmap, 120, 144));
            }
        }

        [Fact]
        public void DropShadow_color_is_applied()
        {
            using SKBitmap red = Render(
                Shadow(depth: 12.0, direction: 315.0, blur: 0.0,
                       color: SkiaColor.MakeScRgb(255, 0, 0, 255)), SKColors.Black).Bitmap;
            using SKBitmap blue = Render(
                Shadow(depth: 12.0, direction: 315.0, blur: 0.0,
                       color: SkiaColor.MakeScRgb(0, 0, 255, 255)), SKColors.Black).Bitmap;

            // 采样点落在"只有阴影"的右侧窄边，读到的是阴影色而不是内容色。
            SKColor redPx = red.GetPixel(204, 90);
            SKColor bluePx = blue.GetPixel(204, 90);

            Assert.True(redPx.Red > 150 && redPx.Blue < 80,
                $"红阴影应偏红，实测 {redPx}");
            Assert.True(bluePx.Blue > 150 && bluePx.Red < 80,
                $"蓝阴影应偏蓝，实测 {bluePx}");
        }

        [Fact]
        public void DropShadow_blur_radius_softens_the_shadow()
        {
            // 硬阴影（blur=0）探到 x≈208.5；模糊半径 18（σ=6）会再往外洇出去。
            using SKBitmap hard = Render(Shadow(depth: 12.0, direction: 315.0, blur: 0.0), SKColors.Black).Bitmap;
            using SKBitmap soft = Render(Shadow(depth: 12.0, direction: 315.0, blur: 18.0), SKColors.Black).Bitmap;

            Assert.Equal(255, Luma(hard, 214, 90));
            Assert.True(Luma(soft, 214, 90) < 230,
                $"BlurRadius=18 的阴影应洇到 x=214，实测 {Pixel(soft, 214, 90)}；" +
                $"扫描 y=90 hard[{Scan(hard, 90, 198, 232)}] soft[{Scan(soft, 90, 198, 232)}]");

            // 阴影主体仍在：模糊只是软化边缘，不是把整块洗淡。
            // （这条窄边只有约 8.5px 宽，比 σ=6 的扩散范围还窄，所以重模糊下它
            //  没有"实心区"，只能断言"仍然明显偏暗"而不是"仍是纯黑"。）
            Assert.True(Luma(soft, 204, 90) < 140,
                $"阴影主体应仍然明显偏暗，实测 {Pixel(soft, 204, 90)}");
        }

        [Fact]
        public void DropShadow_opacity_is_applied()
        {
            using SKBitmap full = Render(
                Shadow(depth: 12.0, direction: 315.0, blur: 0.0, opacity: 1.0), SKColors.Black).Bitmap;
            using SKBitmap quarter = Render(
                Shadow(depth: 12.0, direction: 315.0, blur: 0.0, opacity: 0.25), SKColors.Black).Bitmap;

            int a = Luma(full, 204, 90);
            int b = Luma(quarter, 204, 90);

            Assert.True(a < 60, $"Opacity=1 的阴影应接近纯黑，实测 {a}");
            Assert.True(b > a + 60, $"Opacity=0.25 的阴影应明显更淡：全不透明 {a} vs 四分之一 {b}");
        }

        // ==================================================================
        //  5. 诊断计数 / 栈配平 / 扩展点
        // ==================================================================

        [Fact]
        public void Effect_push_pop_is_balanced_when_the_effect_is_applied()
        {
            RenderOutput blur = Render(new MilBlurEffect { Radius = 6.0 }, SKColors.Black);
            using (blur.Bitmap)
            {
                Assert.True(blur.IsStackBalanced,
                    $"应用效果后画布栈未配平：{blur.InitialSaveCount}→{blur.FinalSaveCount}");
                Assert.Empty(blur.Diagnostics.NotDrawn);
            }

            RenderOutput shadow = Render(Shadow(depth: 8.0, direction: 315.0, blur: 3.0), SKColors.Black);
            using (shadow.Bitmap)
            {
                Assert.True(shadow.IsStackBalanced);
                Assert.Empty(shadow.Diagnostics.NotDrawn);
            }
        }

        [Fact]
        public void Unknown_effect_handle_is_recorded_as_not_drawn_and_still_balanced()
        {
            using var scene = new TestScene();

            // 一个"不是效果"的资源句柄：纯色画刷。渲染层应当认不出来。
            MilResourceHandle hBogus = scene.Mh(scene.Solid(0, 0, 0));

            MilVisual root = scene.Visual();
            root.Content = scene.RenderData(d =>
            {
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushEffect },
                      PushEffectPayload(hBogus));
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = Shape,
                    Brush = scene.Mh(scene.Solid(0, 0, 0)),
                });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
            });

            RenderOutput r = RenderHarness.Render(root, scene.Provider);
            using (r.Bitmap)
            {
                Assert.True(r.Diagnostics.NotDrawn.ContainsKey(MilDrawCommand.MilPushEffect),
                    "认不出来的效果句柄必须记进 NotDrawn（将来接 ShaderEffect 时这就是告警点）。");
                Assert.True(r.IsStackBalanced, "即便退化成裸 Save，Push/Pop 也要配平。");

                // 退化不能把内容也吃掉：矩形照常画出来。
                Assert.Equal(0, Luma(r.Bitmap, 120, 90));
            }
        }

        [Fact]
        public void External_effect_resolver_wins_and_is_called_once_per_instruction()
        {
            int calls = 0;

            (TestScene scene, MilVisual root) = BuildScene(new MilBlurEffect { Radius = 6.0 }, SKColors.Black);

            // 外部工厂：把内容整体平移 (60,60)。内置实现是 Blur(Radius=6)，
            // 两者输出一眼可分，因此"谁赢了"很好判。
            scene.Provider.EffectResolver = h =>
            {
                calls++;
                return SKImageFilter.CreateOffset(60f, 60f);
            };

            RenderOutput r = RenderHarness.Render(root, scene.Provider);
            using (scene)
            using (r.Bitmap)
            {
                // 矩形 (40,40)-(200,140) 被平移成 (100,100)-(260,200)：
                // (150,150) 落在新位置 → 黑；(60,60) 被让了出来 → 白。
                // 若走的是内置 Blur，这两点恰好反过来（(60,60) 在矩形内部是黑的）。
                Assert.Equal(0, Luma(r.Bitmap, 150, 150));
                Assert.Equal(255, Luma(r.Bitmap, 60, 60));

                // 一条 MilPushEffect 指令只能问一次外部工厂。
                // 早先 Create + IsSupported 两个方法各查一遍，这里会是 2。
                Assert.Equal(1, calls);
                Assert.Empty(r.Diagnostics.NotDrawn);
                Assert.True(r.IsStackBalanced);
            }
        }

        // ==================================================================
        //  辅助
        // ==================================================================

        private static MilDropShadowEffect Shadow(
            double depth, double direction, double blur,
            double opacity = 1.0, MilColorF? color = null)
            => new MilDropShadowEffect
            {
                ShadowDepth = depth,
                Direction = direction,
                BlurRadius = blur,
                Opacity = opacity,
                Color = color ?? SkiaColor.MakeScRgb(0, 0, 0, 255),
                RenderingBias = MilRenderingBias.Quality,
            };
    }
}

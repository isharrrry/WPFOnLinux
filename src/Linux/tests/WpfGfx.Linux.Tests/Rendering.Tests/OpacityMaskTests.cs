// PushOpacityMask 的单元级复现（T2b）。只读定位用：判断"纯色 alpha 遮罩"这条既有路径本身通不通。
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
    public class OpacityMaskTests
    {
        public OpacityMaskTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        /// <summary>
        /// **路径 A**（探针走的那条）：`UIElement.OpacityMask` → `MilCmdVisualSetAlphaMask` (0x23)
        /// → `MilVisualNode.AlphaMask` → **投影** → 渲染层消费。
        /// 走 `MilVisualResource` + `VisualProjection.Project`（而不是 RenderData 指令），
        /// 与上面那条路径 B 的用例**形态不同**、覆盖不同的发射路径。
        /// </summary>
        [Theory]
        [InlineData((byte)0, false)]
        [InlineData((byte)255, true)]
        public void visual_alpha_mask_controls_subtree_visibility(byte alpha, bool visible)
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle mask = scene.SolidWithOpacity(0xFF, 0x00, 0x00, alpha);
            DUCE.ResourceHandle red = scene.Solid(0xD0, 0x20, 0x20);
            Commands.MilRenderData rd = scene.RenderData(d => d.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(0, 0, 40, 30),
                Brush = new MilResourceHandle((uint)red),
            }));
            DUCE.ResourceHandle content = scene.Add(new MilRenderDataResource { RenderData = rd });

            var res = new MilVisualResource();
            DUCE.ResourceHandle vis = scene.Add(res);
            res.Visual.Handle = vis;
            res.Visual.Content = content;
            res.Visual.AlphaMask = mask;            // ← 路径 A 的字段

            MilVisual root = VisualProjection.Project(scene.Channel, vis);
            Assert.NotNull(root);
            Assert.False(root.AlphaMask.IsNull, "投影把 AlphaMask 丢了（那正是本缺陷的根因）");

            RenderOutput out2 = RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);
            SKColor px = out2.Bitmap.GetPixel(20, 15);
            long nd = out2.Diagnostics.NotDrawn.TryGetValue(MilDrawCommand.MilPushOpacityMask, out long n) ? n : 0;
            Output.WriteLine($"  [路径A] alpha={alpha} 中心=#{px.Red:X2}{px.Green:X2}{px.Blue:X2} 未画出={nd}");
            bool isRed = px.Red == 0xD0 && px.Green == 0x20 && px.Blue == 0x20;
            Assert.Equal(visible, isRed);
        }

        /// <summary>
        /// **非纯色（渐变）遮罩**：必须**逐像素**调制，而不是"整层照画"或"整层消失"。
        /// 判据用**两端 + 中点**三个采样点，而不是"看起来变暗了"：
        ///   不透明端 ⇒ 内容色原样；透明端 ⇒ 背景色；中点 ⇒ **两者都不等**（= 真的在按渐变的 alpha 调制）。
        /// </summary>
        [Fact]
        public void gradient_mask_modulates_per_pixel()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle red = scene.Solid(0xD0, 0x20, 0x20);

            // 遮罩：横向 黑(alpha=0) → 白(alpha=255) 的线性渐变
            DUCE.ResourceHandle mask = scene.Add(new MilLinearGradientBrush
            {
                StartPoint = new MilPoint { X = 0, Y = 0 },
                EndPoint = new MilPoint { X = 40, Y = 0 },
                MappingMode = MilBrushMappingMode.Absolute,
                SpreadMethod = MilGradientSpreadMethod.Pad,
            });
            if (scene.Provider.Lookup(scene.Mh(mask)) is MilLinearGradientBrush gb)
            { gb.GradientStops.Add(new MilGradientStop(0.0, new MilColorF(0, 0, 0, 0)));
              gb.GradientStops.Add(new MilGradientStop(1.0, new MilColorF(1, 1, 1, 1))); }

            Commands.MilRenderData rd = scene.RenderData(d => d.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(0, 0, 40, 30),
                Brush = new MilResourceHandle((uint)red),
            }));
            DUCE.ResourceHandle content = scene.Add(new MilRenderDataResource { RenderData = rd });

            var res = new MilVisualResource();
            DUCE.ResourceHandle vis = scene.Add(res);
            res.Visual.Handle = vis;
            res.Visual.Content = content;
            res.Visual.AlphaMask = mask;

            MilVisual root = VisualProjection.Project(scene.Channel, vis);
            RenderOutput o = RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);
            SKColor left = o.Bitmap.GetPixel(1, 15);      // alpha≈0 端
            SKColor mid = o.Bitmap.GetPixel(20, 15);      // alpha≈0.5
            SKColor right = o.Bitmap.GetPixel(38, 15);    // alpha≈1 端
            long nd = o.Diagnostics.NotDrawn.TryGetValue(MilDrawCommand.MilPushOpacityMask, out long n) ? n : 0;
            Output.WriteLine($"  渐变遮罩 左=#{left.Red:X2}{left.Green:X2}{left.Blue:X2} " +
                             $"中=#{mid.Red:X2}{mid.Green:X2}{mid.Blue:X2} 右=#{right.Red:X2}{right.Green:X2}{right.Blue:X2} 未画出={nd}");

            Assert.Equal(0, nd);                                  // 不再记"未画"（验收第3条）
            // 断言口径修正：采样点 x=1/38 处的渐变 alpha 并不是 0/1（x=38 时约 0.95），
            // 所以**不能要求端点逐字节等于内容色/背景色**（首版就是这么把断言写错、然后红的）。
            // 这里断言的是"单调调制"这个性质本身：
            Assert.True(left.Red > 0xE0 && left.Green > 0xE0 && left.Blue > 0xE0,
                $"透明端应接近背景白，实得 #{left.Red:X2}{left.Green:X2}{left.Blue:X2}");
            Assert.True(right.Red > 0xC0 && right.Green < 0x60,
                $"不透明端应接近内容红，实得 #{right.Red:X2}{right.Green:X2}{right.Blue:X2}");
            Assert.True(mid.Red < left.Red && mid.Red > right.Red,
                $"中点红分量应严格落在两端之间：左{left.Red} 中{mid.Red} 右{right.Red}");
            // 绿分量与红分量**同向**（都是从背景白的高值单调降到内容红的低值）：
            // 左247 → 中141 → 右41。首版把这一条写成了反方向，于是它必然红 —— 记下来。
            Assert.True(mid.Green < left.Green && mid.Green > right.Green,
                $"中点绿分量应严格落在两端之间：左{left.Green} 中{mid.Green} 右{right.Green}");
        }

        /// <summary>遮罩 alpha=0 ⇒ 内容必须看不见；alpha=255 ⇒ 必须看得见。</summary>
        [Theory]
        [InlineData((byte)0, false)]
        [InlineData((byte)255, true)]
        public void solid_alpha_mask_controls_visibility(byte alpha, bool visible)
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle mask = scene.SolidWithOpacity(0xFF, 0x00, 0x00, alpha);
            DUCE.ResourceHandle red = scene.Solid(0xD0, 0x20, 0x20);

            // 渲染器在 MilPushOpacityMask 上从**原始字节偏移 16**取遮罩句柄（SkiaRenderBackend.cs:466）
            byte[] raw = new byte[20];
            BitConverter.GetBytes((uint)mask).CopyTo(raw, 16);

            MilVisual root = scene.Visual();
            root.Content = scene.RenderData(d =>
            {
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushOpacityMask }, raw);
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 40, 30), Brush = new MilResourceHandle((uint)red) });
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
            });

            RenderOutput res = RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);
            SKColor px = res.Bitmap.GetPixel(20, 15);
            long notDrawn = res.Diagnostics.NotDrawn.TryGetValue(MilDrawCommand.MilPushOpacityMask, out long n) ? n : 0;
            Output.WriteLine($"  alpha={alpha} 中心像素=#{px.Red:X2}{px.Green:X2}{px.Blue:X2} " +
                             $"未画出(PushOpacityMask)={notDrawn}");

            bool isRed = px.Red == 0xD0 && px.Green == 0x20 && px.Blue == 0x20;
            Assert.Equal(visible, isRed);
        }
    }
}

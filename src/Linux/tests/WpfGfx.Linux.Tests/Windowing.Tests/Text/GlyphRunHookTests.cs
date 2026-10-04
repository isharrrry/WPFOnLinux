// T6 与 T4 的对接点验证：MilResourceProvider.GlyphRunRenderer 钩子。
//
// 【这里测的是什么】
//   Rendering/SkiaRenderBackend.cs:273 遇到 MilDrawGlyphRun 时会调
//   `_provider.TryRenderGlyphRun(canvas, instr.Geometry, paint)`，而
//   MilResourceProvider.GlyphRunRenderer 默认是 null → 记一条"不支持"就跳过。
//   T6 要做的就是把 TextRenderer 挂上去。本文件验证：
//     1. 没挂的时候返回 false（T4 的既有行为，不能被我们改坏）
//     2. 挂上之后返回 true 且真的画出像素
//     3. MilGlyphRun（Resources/ 里的资源对象）能被正确翻译成 GlyphRunRequest
//   全程不改 Rendering/ 一行代码。
//
// 【为什么自己 new 一个 StubProvider 而不是用 MilChannel】
//   MilChannelResourceProvider 要一个真实通道，构造成本高且会牵扯 MilChannelRegistry
//   这个已知 flaky 的全局静态（handoff §0）。MilResourceProvider 是 abstract，
//   这里给一个最小实现，把"钩子接得对不对"这件事单独隔离出来测。

using System;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using WpfGfx.Linux.Text;
using Xunit;

namespace WpfGfx.Linux.Tests.Windowing
{
    /// <summary>最小资源提供者：只有一个 GlyphRun 资源，其余一律返回空。</summary>
    internal sealed class StubResourceProvider : MilResourceProvider
    {
        private readonly object _resource;

        public StubResourceProvider(object resource) => _resource = resource;

        public override object Lookup(MilResourceHandle handle) => handle.IsNull ? null : _resource;

        public override SKMatrix ResolveTransform(MilResourceHandle handle) => SKMatrix.Identity;
    }

    [Collection("TextGolden")]
    public class GlyphRunHookTests
    {
        private static readonly TextFontDescription Regular =
            new TextFontDescription(TextScene.Family, TextFontDescription.NormalWeight, SKFontStyleSlant.Upright);

        private static TextRenderer CreateRenderer() =>
            new TextRenderer(FontSet.FromDirectory(TestLayout.FontDir), Regular, fallbackSize: 12f);

        /// <summary>造一个 MilGlyphRun：内容是 "WPF" 的三个字形，基线起点 (12,56)，字号 24。</summary>
        private static MilGlyphRun CreateMilGlyphRun(string text, float size, float originX, float originY)
        {
            using FontSet fonts = FontSet.FromDirectory(TestLayout.FontDir);
            Assert.True(fonts.TryResolve(Regular, out SKTypeface face));
            using (face)
            {
                return new MilGlyphRun
                {
                    Flags = 0,                                    // Sideways=0x1 / HasOffsets=0x10 均未置位
                    Origin = new MilPoint2F(originX, originY),
                    MuSize = size,
                    BidiLevel = 0,
                    GlyphIndices = face.GetGlyphs(text),
                };
            }
        }

        [Fact]
        public void WithoutHook_TryRenderGlyphRun_ReturnsFalse()
        {
            var provider = new StubResourceProvider(CreateMilGlyphRun("WPF", 24f, 12, 56));
            using TextFrame frame = TextScene.Standard();
            using SKPaint ink = TextScene.Ink(frame.Antialias);

            // 基线行为：T4 现在就是这样的。挂上 T6 之前必须是 false。
            Assert.False(provider.TryRenderGlyphRun(
                frame.Canvas, new MilResourceHandle(1u), ink));

            using SKBitmap bmp = frame.ToBitmap();
            Assert.True(X11ScreenCapture.IsBlank(bmp), "未挂钩子时不应画出任何东西");
        }

        [Fact]
        public void WithHook_TryRenderGlyphRun_DrawsPixels_And_MatchesGolden()
        {
            using TextRenderer renderer = CreateRenderer();
            var provider = new StubResourceProvider(CreateMilGlyphRun("WPF", 24f, 12, 56));
            TextRenderer.AttachTo(provider, renderer);

            using TextFrame frame = TextScene.Standard();
            using SKPaint ink = TextScene.Ink(frame.Antialias);

            Assert.True(provider.TryRenderGlyphRun(frame.Canvas, new MilResourceHandle(1u), ink));

            using SKBitmap actual = frame.ToBitmap();
            Assert.False(X11ScreenCapture.IsBlank(actual), "挂上钩子后必须真的画出墨迹");

            CompareResult r = GoldenImage.Verify("text_milglyphrun_hook", actual);
            Assert.True(r.Passed, r.Message);
        }

        [Fact]
        public void HookOutput_MatchesDirectRendererOutput()
        {
            // 钩子路径（MilGlyphRun → 适配 → 绘制）与直连路径（GlyphRunRequest → 绘制）
            // 必须逐像素一致。两者只要有一处参数解释不同（字号单位、基线含义、
            // 字形 id 语义），这里立刻会飘。
            using TextFrame viaHook = TextScene.Standard();
            using TextFrame direct = TextScene.Standard();
            using SKPaint inkH = TextScene.Ink(viaHook.Antialias);
            using SKPaint inkD = TextScene.Ink(direct.Antialias);

            using (TextRenderer renderer = CreateRenderer())
            {
                var provider = new StubResourceProvider(CreateMilGlyphRun("WPF", 24f, 12, 56));
                TextRenderer.AttachTo(provider, renderer);
                Assert.True(provider.TryRenderGlyphRun(viaHook.Canvas, new MilResourceHandle(1u), inkH));

                using FontSet fonts = FontSet.FromDirectory(TestLayout.FontDir);
                Assert.True(fonts.TryResolve(Regular, out SKTypeface face));
                GlyphRunRequest request = GlyphRunRequest.FromText("WPF", face, Regular, 24f, new SKPoint(12, 56));
                Assert.True(renderer.Draw(direct.Canvas, request, inkD));
            }

            using SKBitmap a = viaHook.ToBitmap();
            using SKBitmap b = direct.ToBitmap();

            CompareResult r = GoldenImage.Compare(a, b);
            Assert.True(r.Passed, $"钩子路径与直连路径输出不一致：{r.Message}");
        }

        [Fact]
        public void NullHandle_ReturnsFalse_WithoutThrowing()
        {
            using TextRenderer renderer = CreateRenderer();
            var provider = new StubResourceProvider(CreateMilGlyphRun("WPF", 24f, 12, 56));
            TextRenderer.AttachTo(provider, renderer);

            using TextFrame frame = TextScene.Standard();
            using SKPaint ink = TextScene.Ink(frame.Antialias);

            // 契约层用空句柄表示"没有画刷/没有资源"，这里必须优雅返回而不是抛异常。
            Assert.False(provider.TryRenderGlyphRun(frame.Canvas, default, ink));
        }

        [Fact]
        public void ZeroMuSize_FallsBackToConfiguredSize()
        {
            // MilCmdGlyphRunCreate 解码时 MuSize 可能为 0（上游结构体有这个字段但
            // M1 的字节布局还没完全对齐）。渲染器必须退回构造期配的 fallbackSize，
            // 而不是画出 0 号大小的文字（那会渲染成一条线，golden 里看不出来）。
            using TextRenderer renderer = CreateRenderer();
            MilGlyphRun zeroSize = CreateMilGlyphRun("WPF", 0f, 12, 56);

            using FontSet fonts = FontSet.FromDirectory(TestLayout.FontDir);
            Assert.True(fonts.TryResolve(Regular, out SKTypeface face));
            GlyphRunMetrics fallback = renderer.Measure(
                GlyphRunRequest.FromText("WPF", face, Regular, 12f, SKPoint.Empty));
            GlyphRunMetrics zero = renderer.Measure(MilGlyphRunAdapter.ToRequest(zeroSize, Regular, 12f));

            Assert.Equal(fallback.TotalAdvance, zero.TotalAdvance, 2);
        }
    }
}

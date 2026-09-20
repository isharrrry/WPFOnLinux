// T6 文本渲染：离屏 golden 比对 + 度量语义断言。
//
// 【测试为什么分两类】
//   golden 比对能抓"画出来的像素对不对"，但抓不到"为什么不对"。所以 golden
//   之外再补**语义断言**（advance 单调、粗体更宽、字号线性、基线位移），一旦
//   golden 挂了，语义断言会直接指出是哪一维错了，不用人眼看 diff 图猜。
//
// 【字体只认打包的 Noto Sans】
//   FontSet 从 build/fonts 建；FontSetTests 会验证系统字体**进不来**。
//   这是 golden 可复现的前提（handoff §6 确定性保证第 1 条）。

using System;
using SkiaSharp;
using WpfGfx.Linux.Text;
using Xunit;

namespace WpfGfx.Linux.Tests.Windowing
{
    [Collection("TextGolden")]
    public class GlyphRunRenderTests
    {
        private const string Sample = "Hello WPF on Linux";
        private const string SampleWli = "Wli";

        private static readonly TextFontDescription Regular =
            new TextFontDescription(TextScene.Family, TextFontDescription.NormalWeight, SKFontStyleSlant.Upright);

        private static readonly TextFontDescription Bold =
            new TextFontDescription(TextScene.Family, TextFontDescription.BoldWeight, SKFontStyleSlant.Upright);

        private static readonly TextFontDescription Italic =
            new TextFontDescription(TextScene.Family, TextFontDescription.NormalWeight, SKFontStyleSlant.Italic);

        private static TextRenderer CreateRenderer() =>
            new TextRenderer(FontSet.FromDirectory(TestLayout.FontDir), Regular, fallbackSize: 12f);

        /// <summary>把一段文本排成 GlyphRunRequest。typeface 由 FontSet 持有，这里不额外 Dispose。</summary>
        private static GlyphRunRequest Request(string text, TextFontDescription font, float size, SKPoint origin)
        {
            using FontSet fonts = FontSet.FromDirectory(TestLayout.FontDir);
            Assert.True(fonts.TryResolve(font, out SKTypeface face),
                $"打包字体里找不到 {font.FamilyName} weight={font.Weight} slant={font.Slant}");
            return GlyphRunRequest.FromText(text, face, font, size, origin);
        }

        // ---------- 1. 常规字重：golden ----------

        [Fact]
        public void RegularText_MatchesGolden()
        {
            using TextRenderer renderer = CreateRenderer();

            using TextFrame frame = TextScene.Standard();
            using SKPaint ink = TextScene.Ink(frame.Antialias);
            Assert.True(renderer.Draw(frame.Canvas, Request(Sample, Regular, 24f, new SKPoint(12, 56)), ink));

            using SKBitmap actual = frame.ToBitmap();
            CompareResult r = GoldenImage.Verify("text_regular_24", actual);
            Assert.True(r.Passed, r.Message);
        }

        // ---------- 2. 加粗：golden + 语义（比常规更宽） ----------

        [Fact]
        public void BoldText_MatchesGolden_And_IsWiderThanRegular()
        {
            using TextRenderer renderer = CreateRenderer();
            float regularAdvance = renderer.Measure(Request(Sample, Regular, 24f, SKPoint.Empty)).TotalAdvance;
            float boldAdvance = renderer.Measure(Request(Sample, Bold, 24f, SKPoint.Empty)).TotalAdvance;

            // 语义：Noto Sans Bold 的字形 advance 必须严格大于 Regular，否则说明字重没切过去。
            Assert.True(boldAdvance > regularAdvance,
                $"粗体总 advance({boldAdvance:F2}) 应大于常规({regularAdvance:F2})");

            using TextFrame frame = TextScene.Standard();
            using SKPaint ink = TextScene.Ink(frame.Antialias);
            Assert.True(renderer.Draw(frame.Canvas, Request(Sample, Bold, 24f, new SKPoint(12, 56)), ink));

            using SKBitmap actual = frame.ToBitmap();
            CompareResult r = GoldenImage.Verify("text_bold_24", actual);
            Assert.True(r.Passed, r.Message);
        }

        // ---------- 3. 斜体：golden + 语义（与直立不同） ----------

        [Fact]
        public void ItalicText_MatchesGolden_And_DiffersFromUpright()
        {
            using TextFrame uprightFrame = TextScene.Standard();
            using TextFrame italicFrame = TextScene.Standard();
            using TextRenderer renderer = CreateRenderer();
            using SKPaint inkU = TextScene.Ink(uprightFrame.Antialias);
            using SKPaint inkI = TextScene.Ink(italicFrame.Antialias);

            renderer.Draw(uprightFrame.Canvas, Request(Sample, Regular, 24f, new SKPoint(12, 56)), inkU);
            renderer.Draw(italicFrame.Canvas, Request(Sample, Italic, 24f, new SKPoint(12, 56)), inkI);

            using SKBitmap up = uprightFrame.ToBitmap();
            using SKBitmap it = italicFrame.ToBitmap();

            // 语义：斜体不只是换个 advance，字形轮廓本身要变。
            Assert.NotEqual(GoldenImage.Hash(up), GoldenImage.Hash(it));

            CompareResult r = GoldenImage.Verify("text_italic_24", it);
            Assert.True(r.Passed, r.Message);
        }

        // ---------- 4. 字号：advance 随字号成比例 ----------

        // 【为什么断言带宽是 ±5% 而不是 ±0.5%】
        //   advance **不是**字号的严格线性函数。实测（打包 Noto Sans，upem=1000，
        //   "Hello WPF on Linux" 18 个字形）：
        //     · 12pt 逐字形 advance 全是整数：8,7,3,3,8,3,11,7,6,3,8,7,3,6,3,7,7,6
        //     · 48pt 同样全是整数：36,27,12,12,30,12,45,29,25,12,30,30,12,26,12,30,30,25
        //     · "H" 12pt→8.00、24pt→18.00、48pt→36.00，后两个都反推出 750/1000 em，
        //       唯独 12pt 是 8 而不是 9
        //   即 Skia 会**按字号逐字形量化/hinting** advance，小字号下每个字形能差到
        //   1px。按 12pt 外推到 48pt 的总偏差是 +11px（2.59%），这不是我们的缩放
        //   算错，是光栅化器的既定行为。所以"线性"只能按带宽断言。
        //
        // 【为什么还要加一条绝对量纲断言】
        //   只看比值抓不到"字号被乘了一个常数"的 bug（比如误把 pt 当 px 缩放 4/3，
        //   比值仍然是 1）。逐字形平均 advance 对拉丁字体稳定在 0.5em 附近，
        //   这条把绝对量级钉住，两种错误合起来才覆盖了"字号没生效"的各种形态。
        [Theory]
        [InlineData(12f, 24f)]
        [InlineData(24f, 48f)]
        [InlineData(12f, 48f)]
        public void Advance_ScalesProportionallyWithFontSize(float from, float to)
        {
            using TextRenderer renderer = CreateRenderer();

            GlyphRunRequest small = Request(Sample, Regular, from, SKPoint.Empty);
            GlyphRunRequest large = Request(Sample, Regular, to, SKPoint.Empty);

            double advanceFrom = renderer.Measure(small).TotalAdvance;
            double advanceTo = renderer.Measure(large).TotalAdvance;

            // 语义 1：字号翻倍，advance 也要翻倍（±5% 容纳逐字形量化）。
            double expectedRatio = to / from;
            double actualRatio = advanceTo / advanceFrom;
            Assert.InRange(actualRatio / expectedRatio, 0.95, 1.05);

            // 语义 2：绝对量纲。拉丁字形平均步进约 0.5em，实测 12/24/48pt 分别是
            // 0.49 / 0.49 / 0.50。带宽 [0.35, 0.75] 足以抓住"字号被整体缩放"。
            int glyphCount = large.GlyphIndices.Length;
            Assert.True(glyphCount > 0, "测试文本没有 shaping 出任何字形");
            double advancePerEm = advanceTo / glyphCount / to;
            Assert.InRange(advancePerEm, 0.35, 0.75);
        }

        // ---------- 5. 基线起点：整段文字随起点平移 ----------

        [Fact]
        public void BaselineOrigin_ShiftsRenderedPixels()
        {
            using TextFrame high = TextScene.Standard();
            using TextFrame low = TextScene.Standard();
            using TextRenderer renderer = CreateRenderer();
            using SKPaint inkH = TextScene.Ink(high.Antialias);
            using SKPaint inkL = TextScene.Ink(low.Antialias);

            renderer.Draw(high.Canvas, Request(Sample, Regular, 24f, new SKPoint(12, 40)), inkH);
            renderer.Draw(low.Canvas, Request(Sample, Regular, 24f, new SKPoint(12, 70)), inkL);

            using SKBitmap highBmp = high.ToBitmap();
            using SKBitmap lowBmp = low.ToBitmap();

            (int top, int bottom) highBand = InkRows(highBmp);
            (int top, int bottom) lowBand = InkRows(lowBmp);

            Assert.True(highBand.top > 0, "高基线那张图里没找到墨迹");
            Assert.True(lowBand.bottom < lowBmp.Height, "低基线那张图的墨迹溢出画布");

            // 语义：基线 y 从 40 变到 70，墨迹行区间应整体下移 30 行（±1 抗锯齿余量）。
            Assert.InRange(lowBand.top - highBand.top, 29, 31);
            Assert.InRange(lowBand.bottom - highBand.bottom, 29, 31);

            CompareResult r = GoldenImage.Verify("text_baseline_shift", lowBmp);
            Assert.True(r.Passed, r.Message);
        }

        // ---------- 6. advance 累积：位置严格右移且步长等于字形 advance ----------

        [Fact]
        public void AdvanceAccumulation_ProducesMonotonicPositions()
        {
            using TextRenderer renderer = CreateRenderer();
            GlyphRunMetrics m = renderer.Measure(Request(SampleWli, Regular, 32f, new SKPoint(20, 50)));

            Assert.Equal(SampleWli.Length, m.Positions.Length);

            // 起点就是基线起点。
            Assert.Equal(20.0, m.Positions[0].X, 2);
            Assert.Equal(50.0, m.Positions[0].Y, 2);

            // 逐字形严格右移，步长 = 前一个字形的 advance。
            for (int i = 1; i < m.Positions.Length; i++)
            {
                Assert.True(m.Positions[i].X > m.Positions[i - 1].X,
                    $"第 {i} 个字形没有右移：{m.Positions[i - 1].X} → {m.Positions[i].X}");
                Assert.Equal(m.Advances[i - 1], m.Positions[i].X - m.Positions[i - 1].X, 2);
            }

            // "W" 是宽字形、"l" 是窄字形，宽度必须显著不同，否则说明 advance 取错了。
            Assert.True(m.Advances[0] > m.Advances[1] * 1.5f,
                $"W 的 advance({m.Advances[0]:F2}) 应远大于 l 的({m.Advances[1]:F2})");

            // 总 advance = 各字形 advance 之和。
            float sum = 0f;
            foreach (float a in m.Advances) sum += a;
            Assert.Equal(sum, m.TotalAdvance, 2);
        }

        // ---------- 7. 显式 AdvanceWidths 覆盖字体默认 advance ----------

        [Fact]
        public void ExplicitAdvanceWidths_OverrideFontAdvance()
        {
            using TextRenderer renderer = CreateRenderer();
            GlyphRunRequest request = Request(SampleWli, Regular, 32f, new SKPoint(0, 50));

            // WPF 的 GlyphRun 会自带 advance 数组（M1 的 MilCmdGlyphRunCreate 还没解出来，
            // 见 docs/unimplemented.md）。这里手工塞一份，验证渲染器**优先用调用方给的**。
            var forced = new float[request.GlyphIndices.Length];
            for (int i = 0; i < forced.Length; i++) forced[i] = 25f;
            request.AdvanceWidths = forced;

            GlyphRunMetrics m = renderer.Measure(request);
            Assert.Equal(25.0 * forced.Length, m.TotalAdvance, 2);
            for (int i = 1; i < m.Positions.Length; i++)
                Assert.Equal(25.0, m.Positions[i].X - m.Positions[i - 1].X, 2);
        }

        // ---------- 8. 空 glyph run 不画也不炸 ----------

        [Fact]
        public void EmptyGlyphRun_DrawsNothing()
        {
            using TextRenderer renderer = CreateRenderer();
            GlyphRunRequest empty = Request(string.Empty, Regular, 24f, new SKPoint(10, 40));
            Assert.Empty(empty.GlyphIndices);

            using TextFrame frame = TextScene.Standard();
            using SKPaint ink = TextScene.Ink(frame.Antialias);
            Assert.True(renderer.Draw(frame.Canvas, empty, ink));

            using SKBitmap bmp = frame.ToBitmap();
            Assert.True(X11ScreenCapture.IsBlank(bmp), "空 glyph run 必须画出纯背景");
        }

        // ---------- 9. 小字号 golden（hinting / 亚像素回归锚点） ----------

        [Fact]
        public void SmallSize_MatchesGolden()
        {
            using TextRenderer renderer = CreateRenderer();
            using TextFrame frame = TextScene.Standard();
            using SKPaint ink = TextScene.Ink(frame.Antialias);

            Assert.True(renderer.Draw(frame.Canvas, Request(Sample, Regular, 11f, new SKPoint(12, 50)), ink));

            using SKBitmap actual = frame.ToBitmap();
            CompareResult r = GoldenImage.Verify("text_small_11", actual);
            Assert.True(r.Passed, r.Message);
        }

        /// <summary>返回画布上有墨迹的最小/最大行号；无墨迹返回 (-1,-1)。</summary>
        private static (int Top, int Bottom) InkRows(SKBitmap bmp)
        {
            int top = -1, bottom = -1;
            for (int y = 0; y < bmp.Height; y++)
            {
                for (int x = 0; x < bmp.Width; x++)
                {
                    SKColor c = bmp.GetPixel(x, y);
                    int lum = (c.Red * 299 + c.Green * 587 + c.Blue * 114) / 1000;
                    if (lum < 200)
                    {
                        if (top < 0) top = y;
                        bottom = y;
                        break;
                    }
                }
            }

            return (top, bottom);
        }
    }
}

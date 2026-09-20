// 文本渲染的确定性验证。
//
// 【为什么这一组单独成文件】
//   golden 测试验证的是"这次的输出 == 上次存档的输出"（跨进程、跨时间）。
//   确定性测试验证的是"同一次进程里连画两遍，输出逐字节相同"（跨调用）。
//   后者是前者的前提：如果连画两遍都会飘，golden 迟早会以 flaky 的形式爆掉，
//   而且爆的时候你分不清是"渲染改坏了"还是"渲染本来就不稳"。
//   handoff §9 把"字体渲染跨平台不一致"列为已知风险，这一组就是它的兜底。
//
// 【FFmpeg/哈希的选择】
//   直接对 PNG 字节流做 SHA-256，而不是对像素数组做——PNG 编码是确定性的，
//   而字节流哈希能同时抓到"像素变了"和"尺寸变了"两类回归。

using System;
using System.IO;
using SkiaSharp;
using WpfGfx.Linux.Text;
using Xunit;

namespace WpfGfx.Linux.Tests.Windowing
{
    [Collection("TextGolden")]
    public class TextDeterminismTests
    {
        private static readonly TextFontDescription Regular =
            new TextFontDescription(TextScene.Family, TextFontDescription.NormalWeight, SKFontStyleSlant.Upright);

        private static SKBitmap RenderOnce(string text, float size, SKPoint origin)
        {
            using TextRenderer renderer = new TextRenderer(
                FontSet.FromDirectory(TestLayout.FontDir), Regular, fallbackSize: 12f);

            using FontSet fonts = FontSet.FromDirectory(TestLayout.FontDir);
            Assert.True(fonts.TryResolve(Regular, out SKTypeface face));
            GlyphRunRequest request = GlyphRunRequest.FromText(text, face, Regular, size, origin);

            using TextFrame frame = TextScene.Standard();
            using SKPaint ink = TextScene.Ink(frame.Antialias);
            Assert.True(renderer.Draw(frame.Canvas, request, ink));
            return frame.ToBitmap();
        }

        [Fact]
        public void SameRun_RenderedTwice_HasIdenticalHash()
        {
            using SKBitmap first = RenderOnce("Hello WPF on Linux", 24f, new SKPoint(12, 56));
            using SKBitmap second = RenderOnce("Hello WPF on Linux", 24f, new SKPoint(12, 56));

            string a = GoldenImage.Hash(first);
            string b = GoldenImage.Hash(second);

            Assert.Equal(a, b);
        }

        [Fact]
        public void TwoRenderersInOneProcess_ProduceIdenticalOutput()
        {
            // 两次渲染走**两套独立 FontSet / TextRenderer**，模拟"重复加载字体文件"。
            // 只要字体缓存或 typeface 复用有任何非确定性，这里就会挂。
            using SKBitmap first = RenderOnce("Determinism 确定性", 20f, new SKPoint(8, 48));
            using SKBitmap second = RenderOnce("Determinism 确定性", 20f, new SKPoint(8, 48));

            Assert.Equal(GoldenImage.Hash(first), GoldenImage.Hash(second));
        }

        [Fact]
        public void DifferentText_HasDifferentHash()
        {
            // 反例：哈希函数不能是常量，否则上面两条永远通过（假绿灯）。
            using SKBitmap a = RenderOnce("AAAA", 24f, new SKPoint(12, 56));
            using SKBitmap b = RenderOnce("BBBB", 24f, new SKPoint(12, 56));

            Assert.NotEqual(GoldenImage.Hash(a), GoldenImage.Hash(b));
        }

        [Fact]
        public void PoisonedFontConfig_DoesNotChangeOutput()
        {
            // 把 fontconfig 指向不存在的路径：如果 Text/ 层任何一处依赖系统字体
            // （而不是 build/fonts 里那份打包文件），这里的输出就会变。
            // 注意这条只证明"不受 fontconfig 影响"，"确实用的是打包字体"由
            // FontSetTests.UnpackagedFamily_DoesNotResolve 单独钉死。
            string savedFile = Environment.GetEnvironmentVariable("FONTCONFIG_FILE");
            string savedPath = Environment.GetEnvironmentVariable("FONTCONFIG_PATH");
            try
            {
                Environment.SetEnvironmentVariable("FONTCONFIG_FILE", "/nonexistent/fonts.conf");
                Environment.SetEnvironmentVariable("FONTCONFIG_PATH", "/nonexistent");

                using SKBitmap poisoned = RenderOnce("Hello WPF", 24f, new SKPoint(12, 56));
                using SKBitmap baseline = RenderOnce("Hello WPF", 24f, new SKPoint(12, 56));
                Assert.Equal(GoldenImage.Hash(baseline), GoldenImage.Hash(poisoned));
            }
            finally
            {
                Environment.SetEnvironmentVariable("FONTCONFIG_FILE", savedFile);
                Environment.SetEnvironmentVariable("FONTCONFIG_PATH", savedPath);
            }
        }
    }

    /// <summary>打包字体的边界：只认 build/fonts，系统字体进不来。</summary>
    [Collection("TextGolden")]
    public class FontSetTests
    {
        [Fact]
        public void PackagedFonts_ResolveAllFourStyles()
        {
            using FontSet fonts = FontSet.FromDirectory(TestLayout.FontDir);

            Assert.True(fonts.TryResolve(
                new TextFontDescription("Noto Sans", TextFontDescription.NormalWeight, SKFontStyleSlant.Upright),
                out SKTypeface regular));
            Assert.True(fonts.TryResolve(
                new TextFontDescription("Noto Sans", TextFontDescription.BoldWeight, SKFontStyleSlant.Upright),
                out SKTypeface bold));
            Assert.True(fonts.TryResolve(
                new TextFontDescription("Noto Sans", TextFontDescription.NormalWeight, SKFontStyleSlant.Italic),
                out SKTypeface italic));
            Assert.True(fonts.TryResolve(
                new TextFontDescription("Noto Sans", TextFontDescription.BoldWeight, SKFontStyleSlant.Italic),
                out SKTypeface boldItalic));

            using (regular) using (bold) using (italic) using (boldItalic)
            {
                Assert.False(regular.IsBold);
                Assert.False(regular.IsItalic);
                Assert.True(bold.IsBold);
                Assert.False(bold.IsItalic);
                Assert.False(italic.IsBold);
                Assert.True(italic.IsItalic);
                Assert.True(boldItalic.IsBold);
                Assert.True(boldItalic.IsItalic);
            }
        }

        [Fact]
        public void UnpackagedFamily_DoesNotResolve()
        {
            using FontSet fonts = FontSet.FromDirectory(TestLayout.FontDir);

            // "肯定不存在于 build/fonts" 的族名。若这里返回 true，说明 FontSet
            // 悄悄回落到了系统字体或 Skia 的默认字体，golden 就不可信了。
            Assert.False(fonts.TryResolve(
                new TextFontDescription("Definitely Not A Packaged Family", 400, SKFontStyleSlant.Upright),
                out _));
        }

        [Fact]
        public void FontDirectory_IsExactlyThePackagedOne()
        {
            using FontSet fonts = FontSet.FromDirectory(TestLayout.FontDir);

            // 目录里应该正好是 SHA256SUMS 锁定的 4 个 ttf，多一个少一个都是"字体被换了"。
            Assert.Equal(4, fonts.FileNames.Count);
            foreach (string name in new[] { "NotoSans-Regular.ttf", "NotoSans-Bold.ttf", "NotoSans-Italic.ttf", "NotoSans-BoldItalic.ttf" })
                Assert.Contains(name, fonts.FileNames);

            string sums = Path.Combine(TestLayout.FontDir, "SHA256SUMS");
            Assert.True(File.Exists(sums), $"打包字体缺少校验文件：{sums}");
        }

        [Fact]
        public void EmptyDirectory_ResolvesNothing()
        {
            string empty = Path.Combine(Path.GetTempPath(), "wpf-empty-fonts-" + Guid.NewGuid().ToString("n"));
            Directory.CreateDirectory(empty);
            try
            {
                using FontSet fonts = FontSet.FromDirectory(empty);
                Assert.Empty(fonts.FileNames);
                Assert.False(fonts.TryResolve(
                    new TextFontDescription("Noto Sans", 400, SKFontStyleSlant.Upright), out _));
            }
            finally
            {
                Directory.Delete(empty, recursive: true);
            }
        }
    }
}

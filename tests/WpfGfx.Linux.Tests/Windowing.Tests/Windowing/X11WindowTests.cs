// T5 X11 窗口：真实 X server（Xvfb）下的开窗口 → 呈现 → 截屏验证。
//
// 【这是本轮唯一能证明"窗口真的开出来了"的测试】
//   离屏渲染测试（T4/T6 的 golden）证明的是"Skia 画得对"，它连 X11 都不需要。
//   要证明"X11 窗口真的被映射、真的被绘制、像素真的落到了 X server 端"，
//   必须有一个**独立进程**从外面看这个窗口。这里用 xwd（X11 自带的截屏工具）
//   抓窗口内容，再用 ImageMagick 转成 PNG 交给 Skia 解码。
//
// 【为什么不用 XGetImage 自查】
//   自己 Present 完再自己 XGetImage 读回来，验证的是"我们写的 buffer 能不能原样
//   读回来"，XPutImage → X server 这一段没被测到。xwd 走的是另一条连接、另一套
//   编码路径，看得见才算数（handoff §6 L4）。
//
// 【跳过策略】
//   无 DISPLAY 或无 X server 时 X11Guard.Require() 抛 SkipException，用例记为跳过
//   而不是失败。CI 起 Xvfb 即可全跑，本地裸容器 `dotnet test` 也不会红。

using System;
using SkiaSharp;
using WpfGfx.Linux.Text;
using WpfGfx.Linux.Windowing;
using Xunit;

namespace WpfGfx.Linux.Tests.Windowing
{
    /// <summary>
    /// 两个窗口用例类共用同一个 collection：xUnit 默认并行跑不同的类，
    /// 两个窗口一旦叠在一起，xwd 抓到的内容就可能互相污染。
    /// </summary>
    [Collection("X11Windows")]
    public class X11WindowTests
    {
        private const int WindowX = 60;

        private static readonly TextFontDescription Regular =
            new TextFontDescription(TextScene.Family, TextFontDescription.NormalWeight, SKFontStyleSlant.Upright);

        /// <summary>画一张"红色矩形 + 一行黑字"的测试帧。</summary>
        private static SKImage CreateTestFrame(int width, int height)
        {
            var info = new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Premul);
            using SKSurface surface = SKSurface.Create(info);
            SKCanvas canvas = surface.Canvas;
            canvas.Clear(SKColors.White);

            using (SKPaint red = new SKPaint { Color = new SKColor(220, 30, 30, 255), IsAntialias = true, Style = SKPaintStyle.Fill })
            {
                canvas.DrawRect(10, 10, width - 20, 30, red);
            }

            using TextRenderer renderer = new TextRenderer(FontSet.FromDirectory(TestLayout.FontDir), Regular, 12f);
            using FontSet fonts = FontSet.FromDirectory(TestLayout.FontDir);
            Assert.True(fonts.TryResolve(Regular, out SKTypeface face));
            GlyphRunRequest request = GlyphRunRequest.FromText("WPF on Linux", face, Regular, 24f, new SKPoint(14, 76));
            using SKPaint ink = new SKPaint { Color = SKColors.Black, IsAntialias = true, Style = SKPaintStyle.Fill };
            Assert.True(renderer.Draw(canvas, request, ink));

            surface.Flush();
            return surface.Snapshot();
        }

        [X11Fact]
        public void MappedWindow_IsCapturable_WithExpectedSize()
        {
            X11Guard.Require();

            const int width = 400, height = 120;

            using X11Display display = X11Display.Open(null);
            using X11Window window = new X11Window(display, width, height, "wpf-t5-size", x: WindowX, y: 60);
            window.Map();

            using SKImage frame = CreateTestFrame(width, height);
            window.Present(frame);
            window.Sync();   // 见 X11PresentationTargetTests 的注释：等 server 处理完 XPutImage 再截屏

            string displayName = Environment.GetEnvironmentVariable("DISPLAY");
            using SKBitmap capture = X11ScreenCapture.CaptureWindow(window.Id, displayName, "size");

            // 判据 1：抓得到，且尺寸就是窗口尺寸（说明 Present 出去的帧真的铺满了窗口）。
            Assert.NotNull(capture);
            Assert.Equal(width, capture.Width);
            Assert.Equal(height, capture.Height);

            // 判据 2：不是空白帧。
            Assert.False(X11ScreenCapture.IsBlank(capture), "截屏是纯色，窗口里什么都没画出来");
        }

        [X11Fact]
        public void Present_DrawsRectangleAndText_VisibleToExternalProcess()
        {
            X11Guard.Require();

            const int width = 400, height = 120;

            using X11Display display = X11Display.Open(null);
            using X11Window window = new X11Window(display, width, height, "wpf-t5-present", x: WindowX, y: 220);
            window.Map();

            using SKImage frame = CreateTestFrame(width, height);
            window.Present(frame);
            window.Sync();   // 见 X11PresentationTargetTests 的注释：等 server 处理完 XPutImage 再截屏

            string displayName = Environment.GetEnvironmentVariable("DISPLAY");
            using SKBitmap capture = X11ScreenCapture.CaptureWindow(window.Id, displayName, "present");

            // 存一份产物，人可以直接打开看"到底画成什么样"。
            TestLayout.EnsureDirectories();
            GoldenImage.Save(capture, TestLayout.ActualPath("x11_present_capture"));

            // 判据 3：红矩形在 —— 说明 XPutImage 的像素打包（RGB 掩码/字节序）是对的。
            int redPixels = X11ScreenCapture.CountNear(capture, new SKColor(220, 30, 30, 255), tolerance: 32);
            Assert.True(redPixels > 3000,
                $"截屏里接近测试红色的像素只有 {redPixels} 个，红色矩形没画出来（" +
                $"窗口 {capture.Width}×{capture.Height}）");

            // 判据 4：黑字在 —— 说明 T6 的文本渲染结果真的穿过了 X11 呈现在窗口上。
            int darkPixels = X11ScreenCapture.CountDark(capture, luminanceThreshold: 96);
            Assert.True(darkPixels > 200,
                $"截屏里深色像素只有 {darkPixels} 个，文字没画出来");
        }

        [X11Fact]
        public void Resize_ChangesWindowSize_AndNextFrameFillsIt()
        {
            X11Guard.Require();

            using X11Display display = X11Display.Open(null);
            using X11Window window = new X11Window(display, 200, 100, "wpf-t5-resize", x: WindowX, y: 380);
            window.Map();

            Assert.Equal(200, window.Width);
            Assert.Equal(100, window.Height);

            window.Resize(320, 180);
            window.Flush();
            Assert.Equal(320, window.Width);
            Assert.Equal(180, window.Height);

            using SKImage frame = CreateTestFrame(320, 180);
            window.Present(frame);
            window.Sync();

            string displayName = Environment.GetEnvironmentVariable("DISPLAY");
            using SKBitmap capture = X11ScreenCapture.CaptureWindow(window.Id, displayName, "resize");

            Assert.Equal(320, capture.Width);
            Assert.Equal(180, capture.Height);
            Assert.False(X11ScreenCapture.IsBlank(capture));
        }

        [X11Fact]
        public void TwoDisplays_CanBeOpenedAndClosed()
        {
            X11Guard.Require();

            // 冒烟：XOpenDisplay / XCloseDisplay 能成对调用，句柄非 0。
            for (int i = 0; i < 3; i++)
            {
                using X11Display display = X11Display.Open(null);
                Assert.NotEqual(IntPtr.Zero, display.Handle);
                Assert.True(display.RootWindow != 0, "根窗口 id 不应为 0");
            }
        }
    }
}

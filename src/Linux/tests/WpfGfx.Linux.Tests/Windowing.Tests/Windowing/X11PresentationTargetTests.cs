// T5 另外两条线：IPresentationTarget 契约实现 + X11 事件循环。
//
// 【契约测试的意义】
//   IPresentationTarget 是 handoff §3.4 里写死的三个跨组接口之一，T9（端到端）
//   会直接对着这个接口编程。这里把它当**契约**来测：句柄非 0、尺寸跟随 Resize、
//   Present 不抛、Dispose 可重复。
//
// 【事件循环只测到 M1 要求的三件事】
//   handoff §5 给 T5 定的 M1 范围是"能开窗口、能重绘、能关闭"。所以这里只断言
//   Map 之后收得到 Expose（重绘信号）、RequestClose 之后收得到 Closed。
//   键盘/鼠标/ConfigureNotify 的转换代码写了，但**没有用例覆盖**——它们需要模拟
//   真实的输入注入（XTest 扩展），M1 不做。这一点在报告里如实说明。

using System;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Windowing;
using Xunit;

namespace WpfGfx.Linux.Tests.Windowing
{
    [Collection("X11Windows")]
    public class X11PresentationTargetTests
    {
        private static SKImage CreateSolidFrame(int width, int height, SKColor color)
        {
            var info = new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Premul);
            using SKSurface surface = SKSurface.Create(info);
            surface.Canvas.Clear(color);
            surface.Flush();
            return surface.Snapshot();
        }

        [X11Fact]
        public void PresentationTarget_SatisfiesContract()
        {
            X11Guard.Require();

            using X11Display display = X11Display.Open(null);
            using X11PresentationTarget target = new X11PresentationTarget(display, 240, 160, "wpf-t5-target", x: 60, y: 620);

            // 契约：句柄非 0（T9 会拿它当 HWND 的替身）。
            Assert.NotEqual(IntPtr.Zero, target.NativeHandle);

            // 契约：尺寸可读。
            Assert.Equal(240, target.Width);
            Assert.Equal(160, target.Height);

            // 契约：Resize 之后尺寸立刻跟着变。
            target.Resize(300, 200);
            Assert.Equal(300, target.Width);
            Assert.Equal(200, target.Height);

            // 契约：Present 可以连续调，不抛异常。
            target.Map();
            using SKImage first = CreateSolidFrame(300, 200, new SKColor(30, 120, 220, 255));
            using SKImage second = CreateSolidFrame(300, 200, new SKColor(220, 120, 30, 255));
            target.Present(first);
            target.Present(second);

            // 连着 Present 两张不同颜色的帧，最后一张必须生效。
            // Sync 而不是只 Flush：XPutImage 只是**发出**请求，xwd 走的是另一条连接，
            // server 完全可能先服务它。XSync 保证我们的帧已经落定再让别人来看。
            target.Sync();

            // 纯色帧在 IsBlank 眼里就是"空帧"，必须显式关掉空帧重抓，否则五轮重试全落空。
            using SKBitmap capture = X11ScreenCapture.CaptureWindow(
                target.WindowId, Environment.GetEnvironmentVariable("DISPLAY"), "target",
                requireNonBlank: false);

            int orange = X11ScreenCapture.CountNear(capture, new SKColor(220, 120, 30, 255), tolerance: 32);
            int blue = X11ScreenCapture.CountNear(capture, new SKColor(30, 120, 220, 255), tolerance: 32);

            Assert.True(orange > 300 * 200 * 0.9,
                $"最后一帧（橙色）应铺满窗口，实际只有 {orange}/60000 个像素接近橙色");
            Assert.True(blue < 300 * 200 * 0.1,
                $"上一帧（蓝色）应已被覆盖，实际仍有 {blue} 个蓝色像素");
        }

        [X11Fact]
        public void EventLoop_DeliversExpose_And_Close()
        {
            X11Guard.Require();

            using X11Display display = X11Display.Open(null);
            using X11Window window = new X11Window(display, 200, 120, "wpf-t5-events", x: 60, y: 840);
            window.Map();
            window.Flush();

            // (1) 重绘信号：Map 之后 X server 一定发 Expose。
            bool sawExpose = false;
            for (int i = 0; i < 40 && !sawExpose; i++)
            {
                if (window.TryNextEvent(out WindowEvent ev) && ev.Kind == WindowEventKind.Exposed) sawExpose = true;
                else if (!window.HasPendingEvents) System.Threading.Thread.Sleep(25);
            }

            Assert.True(sawExpose, "窗口 Map 之后没有收到 Expose 事件，重绘链路不通");

            // (2) 关闭信号：发一条 WM_DELETE_WINDOW 的 ClientMessage 给自己。
            window.RequestClose();
            window.Flush();

            bool sawClose = false;
            for (int i = 0; i < 40 && !sawClose; i++)
            {
                if (window.TryNextEvent(out WindowEvent ev) && ev.Kind == WindowEventKind.Closed) sawClose = true;
                else if (!window.HasPendingEvents) System.Threading.Thread.Sleep(25);
            }

            Assert.True(sawClose, "RequestClose 之后没有收到 Closed 事件，关闭链路不通");
        }

        [X11Fact]
        public void Resize_DeliversConfigureNotify()
        {
            X11Guard.Require();

            using X11Display display = X11Display.Open(null);
            using X11Window window = new X11Window(display, 200, 120, "wpf-t5-configure", x: 60, y: 1000);
            window.Map();
            window.Resize(260, 150);
            window.Flush();

            bool sawResize = false;
            int reportedWidth = 0, reportedHeight = 0;
            for (int i = 0; i < 40 && !sawResize; i++)
            {
                if (window.TryNextEvent(out WindowEvent ev) && ev.Kind == WindowEventKind.Resized)
                {
                    sawResize = true;
                    reportedWidth = ev.Width;
                    reportedHeight = ev.Height;
                }
                else if (!window.HasPendingEvents) System.Threading.Thread.Sleep(25);
            }

            Assert.True(sawResize, "Resize 之后没有收到 ConfigureNotify");
            Assert.Equal(260, reportedWidth);
            Assert.Equal(150, reportedHeight);
        }

        [X11Fact]
        public void Dispose_IsIdempotent_And_DestroysWindow()
        {
            X11Guard.Require();

            using X11Display display = X11Display.Open(null);
            X11Window window = new X11Window(display, 120, 80, "wpf-t5-dispose", x: 60, y: 1160);
            window.Map();
            window.Flush();

            ulong id = window.Id;
            window.Dispose();
            window.Dispose(); // 二次 Dispose 不能抛

            // 窗口销毁之后，外部进程应该抓不到它了。
            Assert.False(WindowStillExists(id, Environment.GetEnvironmentVariable("DISPLAY")),
                $"Dispose 之后窗口 0x{id:x} 仍然存在");
        }

        /// <summary>用 xwininfo 探活：能查询到属性说明窗口还在。</summary>
        private static bool WindowStillExists(ulong id, string display)
        {
            try
            {
                var psi = new System.Diagnostics.ProcessStartInfo("xwininfo", $"-id 0x{id:x} -display {display}")
                {
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                };

                using System.Diagnostics.Process p = System.Diagnostics.Process.Start(psi);
                p.WaitForExit();
                return p.ExitCode == 0;
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}

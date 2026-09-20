// M7c · `Windowing/` 改动的**回归**用例。
//
// ── 这次改了什么 ──────────────────────────────────────────────────────────
//   为了让呈现层能"往 WPF 已经建好的窗口上画"，给 `X11Window` 增加了
//   `Wrap(display, existingXid)` 与一个 `_ownsWindow` 标志；`X11PresentationTarget`
//   相应增加 `WrapExisting`。既有语义**一行未改**（自己建窗的路径行为不变）。
//
// ── 为什么这组用例必须存在 ────────────────────────────────────────────────
//   "包装既有窗口"最容易出的错是**越权**：偷偷改掉窗口的事件掩码（于是
//   HwndWrapper 收不到输入）、或者在 Dispose 时把别人的窗口销毁掉。
//   这两件事都不会立刻报错，只会表现为"WPF 的键鼠突然不响应了"或
//   "关掉渲染就白屏" —— 属于最难查的一类。所以逐条钉死：
//     · Wrap 不改事件掩码（对比 Wrap 前后的 YourEventMask 位掩码）
//     · Wrap 后 OwnsWindow=false，Dispose **不销毁**窗口（窗口仍然有效）
//     · 自己建窗的路径 OwnsWindow=true，Dispose 仍然销毁（既有语义没变）
//     · 无效 XID → 抛出（而不是"包装成功但一画就崩"）
//   既有 44 条 Windowing.Tests + 19 条 HelloMil.Tests 是这套改动的主回归网，
//   本文件补的是**新增能力**这一侧。

using System;
using WpfGfx.Linux.Windowing;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Presentation
{
    public sealed class X11WindowWrapTests
    {
        private readonly ITestOutputHelper _out;

        public X11WindowWrapTests(ITestOutputHelper output) => _out = output;

        [X11Fact]
        [Trait("Category", "X11")]
        public void Wrap_DoesNotOwnWindow_And_DisposeKeepsItAlive()
        {
            using X11Display display = X11Display.Open(null);

            // 用"自己建窗"的路径造一个真实窗口，模拟 WPF 的 HwndWrapper 产物。
            ulong xid;
            using (var owner = new X11Window(display, 200, 120, "M7c-Wrap-Owner", 20, 20))
            {
                xid = owner.Id;
                owner.Map();
                owner.Sync();

                // 窗口主人的事件掩码（Wrap 之前）
                long before = EventMaskOf(display, xid);
                _out.WriteLine($"Wrap 前 your_event_mask = 0x{before:x}");

                using var wrapped = X11Window.Wrap(display, xid);

                Assert.Equal(xid, wrapped.Id);
                Assert.False(wrapped.OwnsWindow);            // ★ 不拥有
                Assert.Equal(200, wrapped.Width);
                Assert.Equal(120, wrapped.Height);

                long after = EventMaskOf(display, xid);
                _out.WriteLine($"Wrap 后 your_event_mask = 0x{after:x}");
                Assert.Equal(before, after);                 // ★ 没偷走事件掩码

                // 包装对象 Dispose 之后，窗口必须**还活着**（主人还能用）
                wrapped.Dispose();
            }

            // 主人已经 Dispose（它拥有窗口）——此时窗口才该消失。
            // 用 XGetWindowAttributes 反过来确认"Wrap 那一步没有提前销毁"没法在这里测
            // （主人已经关了），所以真正的断言放在下面一个用例里。
        }

        [X11Fact]
        [Trait("Category", "X11")]
        public void Wrap_Dispose_DoesNotDestroyTheWindow()
        {
            using X11Display display = X11Display.Open(null);

            // 这里**不**用 X11Window 当主人（它会在 Dispose 时销毁窗口），
            // 而是直接建一个裸窗口，模拟"窗口归别人管"。
            ulong xid = X11Native.XCreateSimpleWindow(
                display.Handle, display.RootWindow, 10, 10, 160, 100, 0,
                X11Native.XBlackPixel(display.Handle, display.Screen),
                X11Native.XWhitePixel(display.Handle, display.Screen));
            Assert.NotEqual(0UL, xid);

            try
            {
                var wrapped = X11Window.Wrap(display, xid);
                Assert.Equal(xid, wrapped.Id);
                wrapped.Dispose();

                // ★ 断言窗口仍然有效：能查到属性就是活着
                var attributes = default(XWindowAttributes);
                int ok = X11Native.XGetWindowAttributes(display.Handle, xid, ref attributes);
                _out.WriteLine($"Wrap.Dispose 后 XGetWindowAttributes({xid:x}) = {ok}，" +
                               $"尺寸 {attributes.Width}x{attributes.Height}");
                Assert.NotEqual(0, ok);
                Assert.Equal(160, attributes.Width);
                Assert.Equal(100, attributes.Height);
            }
            finally
            {
                X11Native.XDestroyWindow(display.Handle, xid);
                X11Native.XSync(display.Handle, 0);
            }
        }

        [X11Fact]
        [Trait("Category", "X11")]
        public void Wrap_RejectsInvalidWindowId()
        {
            using X11Display display = X11Display.Open(null);

            Assert.Throws<ArgumentOutOfRangeException>(() => X11Window.Wrap(display, 0));

            // 一个**不存在**的 XID：必须"响亮失败"，而不是包装成功、一画就崩。
            ulong bogus = 0x7F000001UL;
            Assert.ThrowsAny<Exception>(() => X11Window.Wrap(display, bogus));
        }

        [X11Fact]
        [Trait("Category", "X11")]
        public void WrapExisting_Target_ReportsForeignWindow()
        {
            using X11Display display = X11Display.Open(null);

            ulong xid = X11Native.XCreateSimpleWindow(
                display.Handle, display.RootWindow, 10, 10, 128, 96, 0,
                X11Native.XBlackPixel(display.Handle, display.Screen),
                X11Native.XWhitePixel(display.Handle, display.Screen));
            try
            {
                using X11PresentationTarget target = X11PresentationTarget.WrapExisting(display, xid);
                Assert.Equal(xid, target.WindowId);
                Assert.Equal((nint)xid, target.NativeHandle);   // ★ HWND/NativeHandle 就是 XID
                Assert.False(target.OwnsWindow);                // ★ 不拥有窗口
                Assert.Equal(128, target.Width);
                Assert.Equal(96, target.Height);
                _out.WriteLine($"WrapExisting：NativeHandle=0x{target.NativeHandle.ToInt64():x} " +
                               $"OwnsWindow={target.OwnsWindow} {target.Width}x{target.Height}");
            }
            finally
            {
                X11Native.XDestroyWindow(display.Handle, xid);
                X11Native.XSync(display.Handle, 0);
            }
        }

        [X11Fact]
        [Trait("Category", "X11")]
        public void OwnedWindow_StillOwnsAndDestroys()
        {
            // 既有语义没变的证据：自己建窗 → OwnsWindow=true → Dispose 之后窗口没了。
            using X11Display display = X11Display.Open(null);

            var owner = new X11Window(display, 64, 64, "M7c-Owned", 5, 5);
            ulong xid = owner.Id;
            Assert.True(owner.OwnsWindow);
            owner.Dispose();

            var attributes = default(XWindowAttributes);
            int ok = X11Native.XGetWindowAttributes(display.Handle, xid, ref attributes);
            _out.WriteLine($"自己建窗 Dispose 后 XGetWindowAttributes({xid:x}) = {ok}（0 = 已销毁，符合预期）");
            Assert.Equal(0, ok);
        }

        private static long EventMaskOf(X11Display display, ulong xid)
        {
            var attributes = default(XWindowAttributes);
            Assert.NotEqual(0, X11Native.XGetWindowAttributes(display.Handle, xid, ref attributes));
            return attributes.YourEventMask;
        }
    }
}

// 键鼠输入事件的**真输入**验证 —— handoff §8 留下的最后一个缺口。
//
// 【缺口是什么】
//   KeyPress / ButtonPress / MotionNotify 的转换代码一直写在
//   src/WpfGfx.Linux/Windowing/X11Window.cs 的 Translate 里，但**从未被验证过**：
//   Windowing.Tests 只覆盖了 Expose / ConfigureNotify / ClientMessage，因为那三类
//   可以自己 XSendEvent 造出来，而键鼠事件要"真输入"才测得动。
//
// 【为什么自己 XSendEvent 测不了自己】
//   XEvent 是一个 192 字节的 union，字段偏移全靠 FieldOffset 钉死。自己按"我以为是
//   的布局"写出去、再按"我以为是的布局"读回来，写错读错同一个错，**永远绿**。
//   handoff 里记的那次事故（把 4 字节 int 当成 8 字节对齐 → ConfigureNotify 的
//   width 读成 0）就是这么躲过去的。要逼出同类错误，必须让**别人**来造这个事件：
//   xdotool 按 /usr/include/X11/Xlib.h 的官方定义构造，我们只要有一个字段偏了，
//   读回来的 keycode / 坐标 / state 就一定是垃圾。
//
// 【三条注入路径与它们各自能逼出什么】
//   · key --window   → XSendEvent，state 里带真实的修饰键掩码（Shift 0x1 / Ctrl 0x4）
//   · click --window → XSendEvent，button 号与按下/释放的 state 掩码（Button1Mask 0x100…）
//   · mousemove      → XWarpPointer，X server 自己算窗口内相对坐标（最硬的一条）
//
// 【等待策略】
//   一律 Stopwatch 限时 + 短 Task.Delay 轮询，不用 Thread.Sleep 硬等。事件到了就走，
//   到不了就超时报错并把收到的事件全打出来，不静默失败。

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using WpfGfx.Linux.Windowing;
using Xunit;

namespace WpfGfx.Linux.Tests.Windowing
{
    /// <summary>
    /// 与 X11WindowTests / X11PresentationTargetTests 共用一个 collection：
    /// 真指针移动（XWarpPointer）打的是**全局**指针，两个窗口一旦叠在一起，
    /// MotionNotify 会落到最上面那个窗口上，断言必然错乱。
    /// </summary>
    [Collection("X11Windows")]
    public class X11RealInputEventTests
    {
        // 放在屏幕右半侧：其他窗口用例占着 x=60 那一竖条（宽度最大 400）。
        // 真指针移动是靠"指针落在哪个窗口里"分发的，位置必须不重叠。
        private const int WindowX = 780;
        private const int WindowY = 40;
        private const int WindowWidth = 480;
        private const int WindowHeight = 360;

        // 移动目标：窗口内相对坐标。刻意挑"大数 + 边界值"，
        // 偏移量错了（比如把 int 当 8 字节对齐读）就不可能对得上。
        private const int MoveX = 200;
        private const int MoveY = 150;

        private static readonly TimeSpan EventTimeout = TimeSpan.FromSeconds(5);
        private static readonly TimeSpan SettleWindow = TimeSpan.FromMilliseconds(150);
        private static readonly TimeSpan DrainWindow = TimeSpan.FromMilliseconds(300);
        private static readonly TimeSpan PollInterval = TimeSpan.FromMilliseconds(10);
        private static readonly TimeSpan XdotoolTimeout = TimeSpan.FromSeconds(10);

        // X.h 的修饰键 / 按键掩码
        private const uint ShiftMask = 1u << 0;
        private const uint ControlMask = 1u << 2;

        // ------------------------------------------------------------
        //  键盘
        // ------------------------------------------------------------

        [X11Fact]
        public async Task KeyPress_And_KeyRelease_CarryTheSameKeycode()
        {
            X11Guard.Require();

            // keycode 不写死：'a' 在 evdev 是 38，换 keymap 就未必。现查 keymap。
            uint expected = X11InputInjector.KeycodeOf("a");

            using X11Display display = X11Display.Open(null);
            using X11Window window = CreateWindow(display, "input-key");
            await DrainStartupEvents(window);

            using Process inject = X11InputInjector.Key(window.Id, "a");
            List<WindowEvent> events = await PumpAsync(
                window, e => e.Any(x => x.Kind == WindowEventKind.KeyReleased));
            X11InputInjector.WaitForSuccess(inject, XdotoolTimeout);

            WindowEvent press = RequireFirst(events, x => x.Kind == WindowEventKind.KeyPressed, "KeyPressed");
            WindowEvent release = RequireFirst(events, x => x.Kind == WindowEventKind.KeyReleased, "KeyReleased");

            // keycode 取自 XKeyEvent.keycode（offset 84）。偏移错了这里必然不是 'a' 的键码。
            Assert.Equal(expected, press.Detail);
            Assert.Equal(expected, release.Detail);

            // 无修饰键时 state 必须是 0 —— 顺带盯着 state 字段（offset 80）没读歪。
            Assert.Equal(0u, press.State);

            // 顺序：按下一定在释放之前，且两种事件各一条。
            Assert.Equal(1, events.Count(x => x.Kind == WindowEventKind.KeyPressed));
            Assert.Equal(1, events.Count(x => x.Kind == WindowEventKind.KeyReleased));
        }

        [X11Theory]
        [InlineData("shift+a", ShiftMask)]
        [InlineData("ctrl+a", ControlMask)]
        public async Task ModifiedKeyPress_CarriesModifierState(string sequence, uint expectedMask)
        {
            X11Guard.Require();

            uint expected = X11InputInjector.KeycodeOf("a");

            using X11Display display = X11Display.Open(null);
            using X11Window window = CreateWindow(display, "input-mod");
            await DrainStartupEvents(window);

            using Process inject = X11InputInjector.Key(window.Id, sequence);
            // shift+a 会产生 4 条：修饰键按下 → 'a' 按下 → 修饰键释放 → 'a' 释放。
            List<WindowEvent> events = await PumpAsync(
                window, e => e.Count(x => x.Kind == WindowEventKind.KeyReleased) >= 2);
            X11InputInjector.WaitForSuccess(inject, XdotoolTimeout);

            // 修饰键本身也要能被 Translate 出来（它自己就是一条 KeyPressed）。
            Assert.True(events.Count(x => x.Kind == WindowEventKind.KeyPressed) >= 2,
                $"{sequence} 应至少产生 2 条 KeyPressed（修饰键 + 'a'）。实际：{Describe(events)}");

            WindowEvent target = RequireFirst(
                events,
                x => x.Kind == WindowEventKind.KeyPressed && x.Detail == expected,
                $"带 {sequence} 的 'a' 按下事件");

            Assert.NotEqual(0u, target.State & expectedMask);
        }

        // ------------------------------------------------------------
        //  指针
        // ------------------------------------------------------------

        [X11Theory]
        [InlineData(123, 77)]
        [InlineData(7, 353)]
        [InlineData(473, 2)]
        public async Task MouseMove_DeliversMotionNotify_WithExactCoordinates(int x, int y)
        {
            X11Guard.Require();

            using X11Display display = X11Display.Open(null);
            using X11Window window = CreateWindow(display, "input-motion");
            await DrainStartupEvents(window);

            using Process inject = X11InputInjector.MouseMove(window.Id, x, y);
            List<WindowEvent> events = await PumpAsync(
                window, e => e.Any(v => v.Kind == WindowEventKind.PointerMoved));
            X11InputInjector.WaitForSuccess(inject, XdotoolTimeout);

            List<WindowEvent> motions = events.Where(v => v.Kind == WindowEventKind.PointerMoved).ToList();
            Assert.NotEmpty(motions);

            // 取最后一条：X server 可能合并中间过程，落点才是我们要断言的。
            WindowEvent last = motions[motions.Count - 1];

            // ★ 这条断言就是当年 width 读成 0 那类 bug 的照妖镜：
            //   x/y 在 XMotionEvent 里是连续两个 int（offset 64 / 68），
            //   谁把它们按 8 字节对齐摆了，这里读出来就是 0 或隔壁字段的值。
            Assert.Equal(x, last.X);
            Assert.Equal(y, last.Y);
        }

        [X11Theory]
        [InlineData(1)]
        [InlineData(3)]
        public async Task MouseClick_DeliversButtonPressAndRelease_WithButtonNumber(int button)
        {
            X11Guard.Require();

            using X11Display display = X11Display.Open(null);
            using X11Window window = CreateWindow(display, "input-click");
            await DrainStartupEvents(window);
            await MovePointerIntoWindow(window);

            using Process inject = X11InputInjector.Click(window.Id, button);
            List<WindowEvent> events = await PumpAsync(
                window, e => e.Any(v => v.Kind == WindowEventKind.MouseButtonReleased));
            X11InputInjector.WaitForSuccess(inject, XdotoolTimeout);

            WindowEvent press = RequireFirst(
                events, x => x.Kind == WindowEventKind.MouseButtonPressed, "ButtonPress");
            WindowEvent release = RequireFirst(
                events, x => x.Kind == WindowEventKind.MouseButtonReleased, "ButtonRelease");

            Assert.Equal((uint)button, press.Detail);
            Assert.Equal((uint)button, release.Detail);

            // 坐标：click 不移动指针，所以应当停在刚才 mousemove 的落点上。
            Assert.Equal(MoveX, press.X);
            Assert.Equal(MoveY, press.Y);

            // 释放事件的 state 里带 ButtonNMask（左键 0x100、右键 0x400）—— 又一个
            // 非零 state，能把 state 字段的偏移一起钉死。
            uint buttonMask = 1u << (8 + button - 1);
            Assert.NotEqual(0u, release.State & buttonMask);
        }

        [X11Theory]
        [InlineData(4)]
        [InlineData(5)]
        public async Task WheelClick_DeliversButton4Or5(int button)
        {
            X11Guard.Require();

            using X11Display display = X11Display.Open(null);
            using X11Window window = CreateWindow(display, "input-wheel");
            await DrainStartupEvents(window);
            await MovePointerIntoWindow(window);

            using Process inject = X11InputInjector.Click(window.Id, button);
            List<WindowEvent> events = await PumpAsync(
                window, e => e.Any(v => v.Kind == WindowEventKind.MouseButtonReleased));
            X11InputInjector.WaitForSuccess(inject, XdotoolTimeout);

            WindowEvent press = RequireFirst(
                events, x => x.Kind == WindowEventKind.MouseButtonPressed, "ButtonPress（滚轮）");
            WindowEvent release = RequireFirst(
                events, x => x.Kind == WindowEventKind.MouseButtonReleased, "ButtonRelease（滚轮）");

            Assert.Equal((uint)button, press.Detail);
            Assert.Equal((uint)button, release.Detail);
        }

        // ------------------------------------------------------------
        //  辅助
        // ------------------------------------------------------------

        private static X11Window CreateWindow(X11Display display, string title) =>
            new X11Window(display, WindowWidth, WindowHeight, title, x: WindowX, y: WindowY);

        /// <summary>映射窗口，并把 Map 自带的 MapNotify / Expose 排空。</summary>
        private static async Task DrainStartupEvents(X11Window window)
        {
            window.Map();
            window.Sync();

            var clock = Stopwatch.StartNew();
            while (clock.Elapsed < DrainWindow)
            {
                while (window.TryNextEvent(out _)) { }
                await Task.Delay(PollInterval);
            }
        }

        /// <summary>把真指针挪进窗口，并等这条 MotionNotify 落定。</summary>
        private static async Task MovePointerIntoWindow(X11Window window)
        {
            using Process move = X11InputInjector.MouseMove(window.Id, MoveX, MoveY);
            await PumpAsync(window, e => e.Any(v => v.Kind == WindowEventKind.PointerMoved));
            X11InputInjector.WaitForSuccess(move, XdotoolTimeout);
        }

        /// <summary>
        /// 限时轮询泵事件。<paramref name="done"/> 首次成立后再多泵 <see cref="SettleWindow"/>，
        /// 把尾随事件（比如释放）一起收上来。
        /// </summary>
        private static async Task<List<WindowEvent>> PumpAsync(
            X11Window window, Func<List<WindowEvent>, bool> done)
        {
            var events = new List<WindowEvent>();
            var clock = Stopwatch.StartNew();
            var tail = new Stopwatch();
            bool satisfied = false;

            while (clock.Elapsed < EventTimeout)
            {
                while (window.TryNextEvent(out WindowEvent ev)) events.Add(ev);

                if (!satisfied && done(events))
                {
                    satisfied = true;
                    tail.Start();
                }

                if (satisfied && tail.Elapsed >= SettleWindow) break;

                await Task.Delay(PollInterval);
            }

            while (window.TryNextEvent(out WindowEvent ev)) events.Add(ev);
            return events;
        }

        private static WindowEvent RequireFirst(
            List<WindowEvent> events, Func<WindowEvent, bool> predicate, string what)
        {
            int index = events.FindIndex(e => predicate(e));
            Assert.True(index >= 0, $"没收到{what}事件。实际收到的事件：{Describe(events)}");
            return index >= 0 ? events[index] : default;
        }

        private static string Describe(List<WindowEvent> events) =>
            events.Count == 0
                ? "（一条都没有）"
                : string.Join(", ", events.Select(e => e.ToString()));
    }
}

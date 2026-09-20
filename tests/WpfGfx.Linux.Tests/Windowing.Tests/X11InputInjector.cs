// 真输入注入：启动独立的 xdotool 进程，把真按键 / 真鼠标事件打进 Xvfb 窗口。
//
// 【为什么必须走独立进程，而不是自己 XSendEvent】
//   自己 XSendEvent 一个自己构造的 XEvent，验证的是"我们按什么布局写出去，就按
//   什么布局读回来"——布局写错了两边一起错，永远绿。handoff §8 留下的缺口正是
//   这个：KeyPress/ButtonPress/MotionNotify 的转换代码**从未被真输入验证过**。
//   xdotool 是独立进程，它按 libX11 的官方定义构造事件，我们的 XEvent 布局只要
//   有一个字段偏了，读回来的就是垃圾。
//
// 【xdotool 的三种注入路径（决定了断言能有多强）】
//   · key / click --window <id>  → XSendEvent（synthetic=YES），keycode 由 xdotool
//     用 XKeysymToKeycode 从 keymap 现查，button 号、state 掩码由它自己填。
//   · mousemove --window <id>    → XWarpPointer，**真实指针移动**（synthetic=NO），
//     坐标由 X server 自己算，是最硬的一条：偏移错了坐标必然不对。
//
// 【键码为什么不写死 38】
//   'a' 的 keycode 随 keymap 变（evdev 是 38，其他布局未必）。写死等于把测试
//   绑死在这一台机器上，换个镜像就红。所以每次用 xmodmap -pke 现查 keymap。

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Text.RegularExpressions;

namespace WpfGfx.Linux.Tests.Windowing
{
    internal static class X11InputInjector
    {
        private static readonly Regex KeycodeLine =
            new Regex(@"^\s*keycode\s+(\d+)\s*=\s*(\S+)", RegexOptions.Compiled);

        /// <summary>
        /// 启动一次 xdotool 注入（不等待）。返回的进程由调用方负责收尾：
        /// 先泵事件，再 <see cref="WaitForSuccess"/> —— 反过来会错过事件。
        /// </summary>
        public static Process Start(string arguments)
        {
            var psi = new ProcessStartInfo("xdotool", arguments)
            {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
            };

            return Process.Start(psi);
        }

        /// <summary>按键序列：key --window 0x… a / shift+a / ctrl+a。</summary>
        public static Process Key(ulong windowId, string keySequence) =>
            Start($"key --window 0x{windowId:x} {keySequence}");

        /// <summary>真实指针移动：mousemove --window 0x… x y（窗口内相对坐标）。</summary>
        public static Process MouseMove(ulong windowId, int x, int y) =>
            Start($"mousemove --window 0x{windowId:x} {x} {y}");

        /// <summary>按键/滚轮：click --window 0x… button（1 左 2 中 3 右 4/5 滚轮）。</summary>
        public static Process Click(ulong windowId, int button) =>
            Start($"click --window 0x{windowId:x} {button}");

        /// <summary>
        /// 等注入进程结束。退出码非 0 时把 stdout/stderr 一起抛出来 ——
        /// xdotool 报错（找不到窗口、键名拼错）必须一眼看出来，否则用例只会
        /// 报"等不到事件"，让人往事件链路里查。
        /// </summary>
        public static void WaitForSuccess(Process process, TimeSpan timeout)
        {
            if (process == null) return;

            if (!process.WaitForExit((int)timeout.TotalMilliseconds))
            {
                try { process.Kill(); } catch (InvalidOperationException) { /* 已退出 */ }
                throw new InvalidOperationException($"xdotool 在 {timeout.TotalMilliseconds}ms 内没有退出");
            }

            string stdout = process.StandardOutput.ReadToEnd();
            string stderr = process.StandardError.ReadToEnd();

            if (process.ExitCode != 0)
            {
                throw new InvalidOperationException(
                    $"xdotool 退出码 {process.ExitCode}（参数：{process.StartInfo.Arguments}）" +
                    $"\nstdout: {stdout}\nstderr: {stderr}");
            }
        }

        /// <summary>查 keymap 里某个 keysym 的 keycode（如 "a" → 38）。</summary>
        public static uint KeycodeOf(string keysymName)
        {
            if (KeysymToKeycode.Value.TryGetValue(keysymName, out uint code)) return code;

            throw new InvalidOperationException(
                $"xmodmap -pke 里找不到 keysym '{keysymName}' 的 keycode。" +
                "该用例依赖 xmodmap（x11-xserver-utils）读取当前 keymap；" +
                "若确实无法安装，请把断言降级为 keycode 非 0 且不同键的 keycode 互不相同。");
        }

        private static readonly Lazy<Dictionary<string, uint>> KeysymToKeycode =
            new Lazy<Dictionary<string, uint>>(QueryKeymap);

        private static Dictionary<string, uint> QueryKeymap()
        {
            var map = new Dictionary<string, uint>(StringComparer.Ordinal);

            var psi = new ProcessStartInfo("xmodmap", "-pke")
            {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
            };

            using Process process = Process.Start(psi);
            string output = process.StandardOutput.ReadToEnd();
            process.WaitForExit();

            if (process.ExitCode != 0)
            {
                throw new InvalidOperationException(
                    $"xmodmap -pke 失败（exit {process.ExitCode}）：{process.StandardError.ReadToEnd()}");
            }

            foreach (string line in output.Split('\n'))
            {
                Match m = KeycodeLine.Match(line);
                if (!m.Success) continue;

                // 一行可能是 "keycode  38 = a A a A ae AE"：第一个 keysym 是本档（无修饰）。
                uint keycode = uint.Parse(m.Groups[1].Value, CultureInfo.InvariantCulture);
                string keysym = m.Groups[2].Value;
                if (!map.ContainsKey(keysym)) map[keysym] = keycode;
            }

            return map;
        }
    }
}

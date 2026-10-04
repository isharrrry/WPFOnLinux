// M7b 烟测：xdotool / xwininfo 的薄封装。
//
// 【为什么用外部进程而不是自己 P/Invoke XTest】
//   验收指标写的是「xwininfo/xdotool 能查到该窗口」「用 xdotool 注入事件」。
//   用**第三方工具**去查、去注入，才算「从外面看这个窗口是真的」——
//   用本工程自己的代码去查自己的窗口是循环论证。
//   代价：每次调用是一次进程 spawn（3 核机器上要省着用，所以整条烟测只调
//   5 次外部命令，且全部在一次 PushFrame 内完成）。

using System;
using System.Diagnostics;
using System.Globalization;
using System.Text;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    internal sealed record CmdResult(int ExitCode, string StdOut, string StdErr)
    {
        public bool Ok => ExitCode == 0;
        public override string ToString() =>
            $"exit={ExitCode}\n--- stdout ---\n{StdOut}--- stderr ---\n{StdErr}";
    }

    internal static class XTool
    {
        public static CmdResult Run(string exe, params string[] args)
        {
            var psi = new ProcessStartInfo(exe)
            {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
            };
            foreach (string a in args) psi.ArgumentList.Add(a);

            using var p = Process.Start(psi);
            var stdout = new StringBuilder();
            var stderr = new StringBuilder();
            p.OutputDataReceived += (_, e) => { if (e.Data != null) stdout.AppendLine(e.Data); };
            p.ErrorDataReceived += (_, e) => { if (e.Data != null) stderr.AppendLine(e.Data); };
            p.BeginOutputReadLine();
            p.BeginErrorReadLine();
            if (!p.WaitForExit(15000))
            {
                try { p.Kill(true); } catch { /* 已经在退出 */ }
                return new CmdResult(-1, stdout.ToString(), stderr + "\n(超时 15s，已 kill)");
            }
            p.WaitForExit();   // 收完异步输出
            return new CmdResult(p.ExitCode, stdout.ToString(), stderr.ToString());
        }

        /// <summary>`xdotool search --name &lt;title&gt;` → 十进制窗口 id 列表。</summary>
        public static ulong[] SearchByName(string title)
        {
            CmdResult r = Run("xdotool", "search", "--name", title);
            if (!r.Ok) return Array.Empty<ulong>();
            var list = new System.Collections.Generic.List<ulong>();
            foreach (string line in r.StdOut.Split('\n'))
            {
                string s = line.Trim();
                if (s.Length > 0 && ulong.TryParse(s, NumberStyles.Integer,
                        CultureInfo.InvariantCulture, out ulong id))
                    list.Add(id);
            }
            return list.ToArray();
        }

        /// <summary>`xwininfo -id 0x…` 的关键字段。</summary>
        internal sealed record WindowInfo(
            ulong Id, string Name, int X, int Y, int Width, int Height, string MapState, string Raw)
        {
            public bool IsViewable => MapState.Contains("IsViewable", StringComparison.Ordinal);
            public override string ToString() =>
                $"id=0x{Id:x} name=\"{Name}\" pos=({X},{Y}) size={Width}x{Height} mapState=\"{MapState}\"";
        }

        public static WindowInfo QueryWindow(ulong id)
        {
            CmdResult r = Run("xwininfo", "-id", "0x" + id.ToString("x"));
            if (!r.Ok) throw new InvalidOperationException($"xwininfo 失败：{r}");
            string raw = r.StdOut;

            string name = Field(raw, "xwininfo: Window id:");
            int q1 = name.IndexOf('"');
            int q2 = q1 >= 0 ? name.IndexOf('"', q1 + 1) : -1;
            name = (q1 >= 0 && q2 > q1) ? name.Substring(q1 + 1, q2 - q1 - 1) : "";

            return new WindowInfo(
                id, name,
                Int(raw, "Absolute upper-left X:"),
                Int(raw, "Absolute upper-left Y:"),
                Int(raw, "Width:"),
                Int(raw, "Height:"),
                Field(raw, "Map State:").Trim(),
                raw);
        }

        private static string Field(string text, string key)
        {
            foreach (string line in text.Split('\n'))
            {
                int i = line.IndexOf(key, StringComparison.Ordinal);
                if (i >= 0) return line.Substring(i + key.Length).Trim();
            }
            return "";
        }

        private static int Int(string text, string key)
        {
            string v = Field(text, key);
            return int.TryParse(v, NumberStyles.Integer, CultureInfo.InvariantCulture, out int n) ? n : -1;
        }

        public static CmdResult Key(ulong windowId, string key)
            => Run("xdotool", "key", "--window", windowId.ToString(CultureInfo.InvariantCulture), key);

        /// <summary>把指针移到屏幕绝对坐标并等它真的到位（--sync）。</summary>
        public static CmdResult MouseMove(int absX, int absY)
            => Run("xdotool", "mousemove", "--sync",
                   absX.ToString(CultureInfo.InvariantCulture),
                   absY.ToString(CultureInfo.InvariantCulture));

        public static CmdResult Click(int button)
            => Run("xdotool", "click", button.ToString(CultureInfo.InvariantCulture));
    }
}

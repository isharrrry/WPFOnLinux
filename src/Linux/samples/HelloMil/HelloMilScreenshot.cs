// 用独立进程 xwd 抓真实 X11 窗口，再经 ImageMagick convert 转成 PNG。
//
// 【为什么非要用外部 xwd，而不是自己把刚 Present 的像素再读回来】
//   自己读 = 用 XGetImage 取回我们刚写进去的 buffer，那验证的是"我们写的 buffer
//   能不能原样读回来"，Present 到 X server 的那一半链路根本没被测到。xwd 是**独立
//   的第三方进程**，走 X server 的另一条连接、另一套编码路径；它能看到内容，才说明
//   窗口真的被映射、真的被绘制、像素真的落到了 server 端。
//   这是本项目"窗口到底开没开出来"唯一可信的证据。
//
// 【为什么不自己解析 XWD 容器】
//   xwd 输出的是 XWD 容器格式（变长 header + colormap + 按 visual 排布的栅格），
//   自己解析要处理 8/16/24/32 位深度与字节序。ImageMagick 已经把这些坑踩完了，
//   转一道 PNG 让所有人（包括 Read 工具）都能直接看。

using System;
using System.Diagnostics;
using System.IO;

namespace HelloMil
{
    public static class HelloMilScreenshot
    {
        /// <summary>
        /// 抓一个 X11 窗口并存成 PNG。
        /// </summary>
        /// <param name="windowId">X11 Window（XID）。</param>
        /// <param name="display">显示名，如 ":99"。传 null 时用进程的 DISPLAY 环境变量。</param>
        /// <param name="outputPng">输出 PNG 路径（目录不存在会创建）。</param>
        public static void Capture(ulong windowId, string display, string outputPng)
        {
            if (string.IsNullOrEmpty(outputPng)) throw new ArgumentException("输出路径为空", nameof(outputPng));

            string directory = Path.GetDirectoryName(Path.GetFullPath(outputPng));
            if (!string.IsNullOrEmpty(directory)) Directory.CreateDirectory(directory);

            string tag = Guid.NewGuid().ToString("n").Substring(0, 8);
            string xwdPath = Path.Combine(Path.GetTempPath(), $"hellomil-{windowId:x}-{tag}.xwd");
            string pngPath = Path.ChangeExtension(xwdPath, ".png");

            try
            {
                string displayArg = string.IsNullOrWhiteSpace(display)
                    ? string.Empty
                    : $" -display {display}";

                // xwd 偶尔在窗口刚 Map 完的瞬间拿到空帧，重试几轮再放弃。
                FileInfo written = null;
                for (int attempt = 0; attempt < 5; attempt++)
                {
                    Run("xwd", $"-id 0x{windowId:x}{displayArg} -out {Quote(xwdPath)}",
                        $"xwd 抓取窗口 0x{windowId:x}");

                    Run("convert", $"{Quote(xwdPath)} {Quote(pngPath)}", "xwd → png");

                    written = new FileInfo(pngPath);
                    if (written.Exists && written.Length > 0) break;

                    written = null;
                    System.Threading.Thread.Sleep(150);
                }

                if (written == null)
                    throw new InvalidOperationException($"convert 未产出可用的 PNG（{pngPath}）");

                File.Copy(pngPath, outputPng, overwrite: true);
            }
            finally
            {
                TryDelete(xwdPath);
                TryDelete(pngPath);
            }
        }

        private static void Run(string file, string args, string what)
        {
            var psi = new ProcessStartInfo(file, args)
            {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
            };

            using Process p = Process.Start(psi);
            string stdout = p.StandardOutput.ReadToEnd();
            string stderr = p.StandardError.ReadToEnd();
            p.WaitForExit();

            if (p.ExitCode != 0)
                throw new InvalidOperationException(
                    $"{what} 失败（exit {p.ExitCode}）：{file} {args}\nstdout: {stdout}\nstderr: {stderr}");
        }

        private static string Quote(string s) => "\"" + s + "\"";

        private static void TryDelete(string path)
        {
            try { if (File.Exists(path)) File.Delete(path); }
            catch (IOException) { /* 临时文件删不掉不影响结论 */ }
        }
    }
}

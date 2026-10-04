// 用 xwd 抓真实 X11 窗口内容，经 ImageMagick convert 转成 PNG 后交给 Skia 解码。
//
// 【为什么非要用外部 xwd 而不是自己读窗口像素】
//   自己读 = 用 XGetImage 把刚 Present 出去的内容再取回来，那验证的是
//   "我们写的 buffer 能不能原样读回来"，Present 到 X server 的那一半链路没被测到。
//   xwd 是**独立的第三方进程**，走的是 X server 的另一条连接、另一套编码，
//   它能看到内容才说明窗口真的被映射、真的被绘制、像素真的落到了 server 端。
//   这是 handoff §6 L4 定的验证手段，也是"窗口到底开没开出来"唯一可信的证据。
//
// 【为什么 xwd 之后还要 convert】
//   xwd 输出的是 XWD 容器格式（变长 header + colormap + 按 visual 排布的栅格），
//   自己解析要处理 8/16/24/32 位深度与字节序。ImageMagick 已经把这些坑踩完了，
//   转一道 PNG 让 Skia 解码，正确性和可读性都更好。

using System;
using System.Diagnostics;
using System.IO;
using SkiaSharp;

namespace WpfGfx.Linux.Tests.Windowing
{
    internal static class X11ScreenCapture
    {
        /// <summary>
        /// 抓单个窗口。windowId 是 X11 的 Window（XID）。
        /// </summary>
        /// <param name="requireNonBlank">
        /// 是否把"整张图只有一种颜色"当作空帧并重抓。默认 true。
        /// **画纯色帧的用例必须显式传 false** —— 否则纯色窗口永远被判定为空帧，
        /// 五轮重试全部落空。
        /// </param>
        public static SKBitmap CaptureWindow(ulong windowId, string display, string tag,
            bool requireNonBlank = true)
        {
            string xwdPath = Path.Combine(Path.GetTempPath(), $"wpf-{tag}-{windowId:x}.xwd");
            string pngPath = Path.ChangeExtension(xwdPath, ".png");

            try
            {
                Run("xwd", $"-id 0x{windowId:x} -display {display} -out {Q(xwdPath)}",
                    $"xwd 抓取窗口 0x{windowId:x}");

                // xwd 偶尔在窗口刚 Map 完的瞬间拿到空帧，重试几轮再放弃。
                //
                // ⚠️ 这里踩过一个坑：初版把 bitmap 声明在循环外，每轮判定失败就
                //    `bitmap?.Dispose()` 然后继续——第五轮结束后 `return bitmap`
                //    返回的是**已经 Dispose 掉的** SKBitmap。调用方再去 GetPixel
                //    就是 native 内存 use-after-free，整个测试宿主进程直接崩，
                //    而且错误信息只有一句 "Test host process crashed"，极难查。
                //    画纯色帧的用例必然五轮全空，所以每次必崩；画混合内容的用例
                //    第一轮就返回，反而一直正常——典型的"只在某些内容下炸"。
                //    修法：只有确认要返回时才让 bitmap 逃出循环，其余一律 dispose。
                for (int attempt = 0; attempt < 5; attempt++)
                {
                    Run("convert", $"{Q(xwdPath)} {Q(pngPath)}", "xwd → png");
                    SKBitmap bitmap = SKBitmap.Decode(pngPath);

                    if (bitmap == null || (requireNonBlank && IsBlank(bitmap)))
                    {
                        bitmap?.Dispose();
                        System.Threading.Thread.Sleep(150);
                        continue;
                    }

                    return bitmap;
                }

                throw new InvalidOperationException(
                    requireNonBlank
                        ? $"连续 5 次抓到的窗口 0x{windowId:x} 都是空帧（或 convert 未产出可解码的 PNG：{pngPath}）"
                        : $"convert 未产出可解码的 PNG：{pngPath}");
            }
            finally
            {
                TryDelete(xwdPath);
                TryDelete(pngPath);
            }
        }

        /// <summary>整张图是否只有一种颜色（用来判断"抓到的是空白帧"）。</summary>
        public static bool IsBlank(SKBitmap bitmap)
        {
            SKColor first = bitmap.GetPixel(0, 0);
            for (int y = 0; y < bitmap.Height; y++)
                for (int x = 0; x < bitmap.Width; x++)
                    if (bitmap.GetPixel(x, y) != first) return false;
            return true;
        }

        /// <summary>统计与背景色不同（任一通道差 > tolerance）的像素数。</summary>
        public static int CountNonBackground(SKBitmap bitmap, SKColor background, int tolerance = 8)
        {
            int count = 0;
            for (int y = 0; y < bitmap.Height; y++)
            {
                for (int x = 0; x < bitmap.Width; x++)
                {
                    SKColor c = bitmap.GetPixel(x, y);
                    if (Delta(c, background) > tolerance) count++;
                }
            }

            return count;
        }

        /// <summary>统计接近目标色的像素数（用于"红色矩形画出来了吗"）。</summary>
        public static int CountNear(SKBitmap bitmap, SKColor target, int tolerance = 24)
        {
            int count = 0;
            for (int y = 0; y < bitmap.Height; y++)
                for (int x = 0; x < bitmap.Width; x++)
                    if (Delta(bitmap.GetPixel(x, y), target) <= tolerance) count++;
            return count;
        }

        /// <summary>统计亮度低于阈值的像素数（用于"黑字画出来了吗"）。</summary>
        public static int CountDark(SKBitmap bitmap, byte luminanceThreshold = 96)
        {
            int count = 0;
            for (int y = 0; y < bitmap.Height; y++)
            {
                for (int x = 0; x < bitmap.Width; x++)
                {
                    SKColor c = bitmap.GetPixel(x, y);
                    int lum = (c.Red * 299 + c.Green * 587 + c.Blue * 114) / 1000;
                    if (lum < luminanceThreshold) count++;
                }
            }

            return count;
        }

        public static int Delta(SKColor a, SKColor b) =>
            Math.Max(
                Math.Max(Math.Abs(a.Red - b.Red), Math.Abs(a.Green - b.Green)),
                Math.Max(Math.Abs(a.Blue - b.Blue), Math.Abs(a.Alpha - b.Alpha)));

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
            {
                throw new InvalidOperationException(
                    $"{what} 失败（exit {p.ExitCode}）：{file} {args}\nstdout: {stdout}\nstderr: {stderr}");
            }
        }

        private static string Q(string s) => "\"" + s + "\"";

        private static void TryDelete(string path)
        {
            try { if (File.Exists(path)) File.Delete(path); }
            catch (IOException) { /* 临时文件删不掉不影响结论 */ }
        }
    }
}

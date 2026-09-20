// HelloMil 主流程：API 构造视觉树 → Skia 离屏渲染 → X11 真窗口呈现 → xwd 截屏。
//
// ★ 这是 HelloMil，不是 HelloWpf。
//   本程序**不引用任何 WPF 程序集**：没有 UseWPF、没有 Microsoft.WindowsDesktop.App、
//   没有 XAML、没有 Dispatcher / DependencyObject / HwndSource。它调用的是我们自己的
//   WpfGfx.Linux API。它证明的是 M1 的那件事——"Linux 上我们自己的渲染后端能从 API
//   调用一路通到真实 X11 窗口的真实像素"。
//
//   让真正的 WPF 程序（samples/HelloWpf）在 Linux 上跑起来，需要把 WPF 托管层
//   （PresentationFramework + PresentationCore + WindowsBase + System.Xaml，约 118 万行
//   C#，含 150+ 处 Win32 P/Invoke）搬到 Linux，那是 M2/M3 的范围，见 docs/T9-roadmap.md。
//
// 用法：
//   dotnet run --project samples/HelloMil -- --display :99
//   dotnet run --project samples/HelloMil -- --hold 10 --out /tmp/shot.png
//   dotnet run --project samples/HelloMil -- --offscreen-only   # 只离屏渲染，不开窗

using System;
using System.IO;
using SkiaSharp;
using WpfGfx.Linux.Windowing;

namespace HelloMil
{
    internal static class Program
    {
        private static int Main(string[] args)
        {
            string fontDir = null;
            string display = Environment.GetEnvironmentVariable("DISPLAY");
            string output = null;
            int holdSeconds = 5;
            bool offscreenOnly = false;

            // ---------------- 参数解析 ----------------
            for (int i = 0; i < args.Length; i++)
            {
                switch (args[i])
                {
                    case "--fonts": fontDir = Next(args, ref i); break;
                    case "--display": display = Next(args, ref i); break;
                    case "--out": output = Next(args, ref i); break;
                    case "--hold":
                        if (!int.TryParse(Next(args, ref i), out holdSeconds) || holdSeconds < 0)
                            return Fail("--hold 需要一个非负整数（秒）");
                        break;
                    case "--offscreen-only": offscreenOnly = true; break;
                    case "--help":
                    case "-h":
                        PrintUsage();
                        return 0;
                    default:
                        return Fail($"未知参数：{args[i]}（用 --help 看用法）");
                }
            }

            fontDir ??= HelloMilPaths.FontDirectory;
            if (string.IsNullOrEmpty(fontDir))
                return Fail("定位不到打包字体目录 build/fonts，用 --fonts <dir> 显式指定");

            output ??= HelloMilPaths.DefaultScreenshotPath;

            try
            {
                return Run(fontDir, display, output, holdSeconds, offscreenOnly);
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine();
                Console.Error.WriteLine($"失败：{ex.GetType().Name}: {ex.Message}");
                Console.Error.WriteLine(ex.StackTrace);
                return 1;
            }
        }

        private static int Run(string fontDir, string display, string output, int holdSeconds, bool offscreenOnly)
        {
            Console.WriteLine("=== HelloMil：WpfGfx.Linux 端到端 demo ===");
            Console.WriteLine($"    字体目录 : {fontDir}");
            Console.WriteLine($"    画布     : {HelloMilScene.Width}x{HelloMilScene.Height} @ 96 DPI");
            Console.WriteLine();

            // ---- [1/5] 构造场景（资源表 + 视觉树）--------------------------------
            Console.Write("[1/5] 构造 MilChannel 资源表与视觉树 ... ");
            using HelloMilScene scene = HelloMilScene.Create(fontDir);
            Console.WriteLine("OK");

            // ---- [2/5] 离屏渲染 --------------------------------------------------
            Console.Write("[2/5] SkiaRenderBackend 离屏渲染 ... ");
            using SKImage offscreen = scene.Render();
            Console.WriteLine($"OK（{scene.InstructionCount} 条指令，" +
                              $"{scene.NotDrawnCount} 条未画出，GlyphRun 跳过={scene.GlyphRunSkipped}）");

            if (scene.NotDrawnCount != 0)
                Console.WriteLine("      ⚠ 有指令没画出东西，见上面的诊断计数");

            // 离屏结果先落盘一份：即使后面 X11 那条路走不通，渲染本身是否成功也有据可查。
            string offscreenPath = Path.Combine(Path.GetTempPath(), "hellomil-offscreen.png");
            using (SKData data = offscreen.Encode(SKEncodedImageFormat.Png, 100))
            using (FileStream fs = File.Create(offscreenPath))
                data.SaveTo(fs);
            Console.WriteLine($"      离屏帧已存：{offscreenPath}");

            if (offscreenOnly)
            {
                Console.WriteLine();
                Console.WriteLine("--offscreen-only：跳过开窗与截图。");
                return 0;
            }

            // ---- [3/5] 开真实 X11 窗口 -------------------------------------------
            if (string.IsNullOrWhiteSpace(display))
                return Fail("没有 X server：DISPLAY 为空。先起 Xvfb（见 Windowing.Tests/start-xvfb.sh），" +
                            "或用 --display :99 指定，或用 --offscreen-only 只跑离屏渲染。");

            Console.Write($"[3/5] 打开 DISPLAY={display}，创建 X11 窗口 ... ");
            using X11Display dpy = X11Display.Open(display);
            using X11PresentationTarget target = new X11PresentationTarget(
                dpy, HelloMilScene.Width, HelloMilScene.Height,
                "HelloMil — WpfGfx.Linux on X11", x: 40, y: 40);
            target.Map();
            Console.WriteLine($"OK（WindowId=0x{target.WindowId:x}）");

            // ---- [4/5] 呈现到窗口 -------------------------------------------------
            Console.Write("[4/5] Present(frame) 到 X11 窗口 ... ");
            target.Present(offscreen);
            // Sync 而不是只 Flush：XPutImage 只是**发出**请求，xwd 走的是另一条连接，
            // server 完全可能先服务它。XSync 保证我们的帧已经落定再让别人来看。
            target.Sync();
            Console.WriteLine("OK");

            // ---- [5/5] 保持窗口，然后 xwd 截屏 --------------------------------------
            if (holdSeconds > 0)
            {
                Console.WriteLine($"[5/5] 保持窗口 {holdSeconds} 秒（Ctrl+C 可提前结束）...");
                System.Threading.Thread.Sleep(holdSeconds * 1000);
            }
            else
            {
                Console.WriteLine("[5/5] 不等待，直接截图。");
            }

            HelloMilScreenshot.Capture(target.WindowId, display, output);
            Console.WriteLine($"      截图已存：{Path.GetFullPath(output)}");

            Console.WriteLine();
            Console.WriteLine("完成。");
            return 0;
        }

        private static string Next(string[] args, ref int i)
        {
            if (i + 1 >= args.Length) throw new ArgumentException($"参数 {args[i]} 缺值");
            return args[++i];
        }

        private static int Fail(string message)
        {
            Console.Error.WriteLine("错误：" + message);
            Console.Error.WriteLine();
            PrintUsage();
            return 1;
        }

        private static void PrintUsage()
        {
            Console.WriteLine("用法: dotnet run --project samples/HelloMil -- [选项]");
            Console.WriteLine();
            Console.WriteLine("  --fonts <dir>        打包字体目录（默认自动定位 build/fonts）");
            Console.WriteLine("  --display <name>     X server（默认取 DISPLAY 环境变量）");
            Console.WriteLine("  --out <path>         截图输出 PNG（默认 samples/HelloMil/screenshot.png）");
            Console.WriteLine("  --hold <sec>         截图前保持窗口的秒数（默认 5，0 表示不等待）");
            Console.WriteLine("  --offscreen-only     只做离屏渲染，不开窗不截图");
            Console.WriteLine("  --help               显示本帮助");
        }
    }
}

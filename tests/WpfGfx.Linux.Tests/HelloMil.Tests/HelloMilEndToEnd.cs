// 端到端：构造场景 → 离屏渲染 → 开真 X11 窗口 → Present → xwd 截屏。
//
// 故意通过 samples/HelloMil 的公共 API 来做，让这条 X11 路径上**只有一个**地方
// 真的接触 WpfGfx.Linux.Windowing.X11Display —— 就在 Program.cs 那一段。其余流程
// （HelloMilScene / HelloMilScreenshot）都已经在非 X11 用例里被覆盖了。

using System;
using System.IO;
using SkiaSharp;
using HelloMil;

namespace WpfGfx.Linux.Tests.HelloMil
{
    internal static class HelloMilEndToEnd
    {
        public static void OpenAndCapture(string outputPng, string display, int holdSeconds)
        {
            string fontDir = HelloMilPaths.FontDirectory
                ?? throw new DirectoryNotFoundException("无法定位打包字体目录 build/fonts");

            using HelloMilScene scene = HelloMilScene.Create(fontDir);
            using SKImage frame = scene.Render();

            // 直接反射调 WpfGfx.Linux 的 X11 API：HelloMil 的公开 API 不应该把
            // X11Display / X11PresentationTarget 暴露在 HelloMilScene 上（那是
            // 窗口层的关注点，不是"场景"关注点）。但 Program.cs 里会用到，
            // 测试这里走 helloMil-Sample 的 Program 那一套 —— 不行：Program.Main
            // 是 internal + 写死参数。所以测试自己 new 一个与 Program 等价的最小环。
            //
            // 反射只在这里 X11 路径上用一次：它不需要我们去搞 InternalsVisibleTo。
            using (IDisposable dpy = (IDisposable)OpenDisplay(display))
            using (IDisposable target = (IDisposable)NewTarget(dpy, HelloMilScene.Width, HelloMilScene.Height))
            {
                ulong windowId = (ulong)GetWindowId(target);
                Invoke(target, "Map");

                Invoke(target, "Present", frame);
                Invoke(target, "Sync");

                if (holdSeconds > 0) System.Threading.Thread.Sleep(holdSeconds * 1000);

                HelloMilScreenshot.Capture(windowId, display, outputPng);
            }
        }

        // ------- 反射桥（X11 类型只在 src/ 里有，这里只取窗口尺寸/句柄/生命周期）-------

        private static object OpenDisplay(string display)
        {
            Type type = Type.GetType("WpfGfx.Linux.Windowing.X11Display, WpfGfx.Linux")!;
            return type.GetMethod("Open", new[] { typeof(string) })!.Invoke(null, new object[] { display });
        }

        private static object NewTarget(object dpy, int w, int h)
        {
            Type type = Type.GetType("WpfGfx.Linux.Windowing.X11PresentationTarget, WpfGfx.Linux")!;
            return type.GetConstructor(new[] {
                dpy.GetType(), typeof(int), typeof(int), typeof(string), typeof(int), typeof(int),
            })!.Invoke(new object[] { dpy, w, h, "HelloMil.Test", 40, 40 });
        }

        private static object GetWindowId(object target)
        {
            return target.GetType().GetProperty("WindowId")!.GetValue(target)!;
        }

        private static void Invoke(object instance, string method, params object[] args)
        {
            Type[] argTypes = new Type[args.Length];
            for (int i = 0; i < args.Length; i++) argTypes[i] = args[i]?.GetType() ?? typeof(object);
            instance.GetType().GetMethod(method, argTypes)!.Invoke(instance, args);
        }
    }
}

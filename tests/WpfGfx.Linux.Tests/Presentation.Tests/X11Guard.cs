// M7c · X server 守卫 + 经 **Win32 shim** 创建真窗口的最小 P/Invoke 面。
//
// 【为什么不直接反射 HwndWrapper（像 M7b 那样），而是直连 shim】
//   M7c Phase 1 要证明的是「**Win32 shim 下发的 HWND** 能被 MIL 呈现层直接当 XID 用」。
//   这条链路的两端是 libwpfwin32.so 与 WpfGfx.Linux，中间**不需要** WindowsBase ——
//   用 HwndWrapper 会把移植过来的托管层整个拖进本工程的依赖图，而那正是 M7b 的
//   回归网在管的事。所以这里直接用 shim 的 user32 导出建窗：
//   它就是 HwndWrapper 建窗时走的同一条路径（RegisterClassExW → CreateWindowExW），
//   只是调用方换成了测试，反而更纯粹地证明了"HWND == XID"。
//
// 【跳过模式沿用 M7b/Windowing.Tests 的发现期 Skip】
//   xunit 2.9.2 的 SkipException 在 v2 会把用例记成 Failed；唯一干净的通道是
//   FactAttribute.Skip（发现期读、构造函数也在发现期跑）。

using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using Xunit;

namespace WpfGfx.Linux.Tests.Presentation
{
    internal static class X11Probe
    {
        private const string LibX11 = "libX11.so.6";

        [DllImport(LibX11, EntryPoint = "XOpenDisplay")]
        private static extern nint XOpenDisplay(string displayName);

        [DllImport(LibX11, EntryPoint = "XCloseDisplay")]
        private static extern int XCloseDisplay(nint display);

        private static readonly Lazy<(bool Available, string Reason)> Probe =
            new Lazy<(bool, string)>(ProbeCore);

        public static bool Available => Probe.Value.Available;
        public static string Reason => Probe.Value.Reason;

        public static string SkipReason =>
            $"无 X server：{Reason}。要跑起来先执行 " +
            "tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh start，再设 DISPLAY=:99。";

        private static (bool, string) ProbeCore()
        {
            string display = Environment.GetEnvironmentVariable("DISPLAY");
            if (string.IsNullOrWhiteSpace(display))
                return (false, "环境变量 DISPLAY 未设置");
            try
            {
                nint dpy = XOpenDisplay(null);
                if (dpy == nint.Zero)
                    return (false, $"XOpenDisplay 对 DISPLAY={display} 返回 NULL（server 没在听）");
                XCloseDisplay(dpy);
                return (true, $"DISPLAY={display}");
            }
            catch (Exception ex)
            {
                return (false, $"加载 libX11 失败：{ex.GetType().Name}: {ex.Message}");
            }
        }
    }

    /// <summary>需要真实 X server 的用例（无 X 时**发现期**跳过，不是失败）。</summary>
    public sealed class X11FactAttribute : FactAttribute
    {
        public X11FactAttribute()
        {
            if (!X11Probe.Available) Skip = X11Probe.SkipReason;
        }
    }

    /// <summary>
    /// 经 Win32 shim 建一个**真实**的顶层窗口。
    ///
    /// 这条路径与 WindowsBase 的 `HwndWrapper` 构造函数逐步骤一致：
    ///   RegisterClassExW(WNDCLASSEX_D) → CreateWindowExW(...) → （WS_VISIBLE 时）XMapWindow。
    /// 区别只有一个：类名由测试生成，没有 HwndSubclass 那一层（M7c 不测输入）。
    /// </summary>
    internal static class Win32Shim
    {
        private const string Lib = "libwpfwin32.so";

        private static readonly string[] Mapped =
            { Lib, "user32.dll", "gdi32.dll", "kernel32.dll", "PresentationNative_cor3.dll" };

        static Win32Shim()
        {
            // ⚠️ 2026-09-15：`SetDllImportResolver` **对同一程序集只能调一次**，第二次抛
            //   `InvalidOperationException: A resolver is already set for the assembly.`；
            //   而本行在**静态构造**里 ⇒ 一旦抛出，整个类型被毒化、用它的一批用例全灭
            //   （同族事故见 `ManagedLayer.Tests/X11Guard.cs` 的注释与 `D-R2` 定案）。
            //   本程序集当前**只有一个**安装点（所以今天是潜伏形态），这里先兜一层：
            //   输掉竞态不算失败；装置缺件仍由下面的解析路径硬失败。
            try
            {
                NativeLibrary.SetDllImportResolver(typeof(Win32Shim).Assembly, Resolve);
            }
            catch (InvalidOperationException)
            {
                // 已有人为本程序集装过解析器。不是缺陷、不是装置缺件。
            }
            // ⚠️ 2026-09-15（同 `ManagedLayer.Tests/X11Guard.cs`）：`catch` 不能只是沉默 ——
            //   装完**自证一次**，解析不到就当场响亮失败，而不是让深处的
            //   `DllNotFoundException` 去替它背锅。
            //   ⚠️ **不能用 `NativeLibrary.TryLoad("user32.dll", assembly, …)` 做这个自证**：
            //   那个 API 只用程序集定**搜索路径**，**不会**走 `DllImportResolver`
            //   （2026-09-15 实测踩到）。⇒ 必须用**真的 `[DllImport]`**。
            if (!User32MapsToShim())
                throw new InvalidOperationException(
                    "本程序集的 `user32.dll` 解析不到：当前生效的解析器不是我们这一个"
                    + "（`SetDllImportResolver` 每程序集只能装一次，我们这次被抢先者挤掉了）。");
        }

        /// <summary>自证：把 `user32.dll` 当 DllImport 走一次，看解析器是否把它接到 shim。</summary>
        private static bool User32MapsToShim()
        {
            try { _ = ShimVersionViaUser32(); return true; }
            catch (DllNotFoundException) { return false; }
            catch (EntryPointNotFoundException) { return true; }
        }

        [DllImport("user32.dll", EntryPoint = "WpfLinuxWin32_ShimVersion")]
        private static extern nint ShimVersionViaUser32();

        private static nint Resolve(string libraryName, System.Reflection.Assembly assembly,
                                    DllImportSearchPath? searchPath)
        {
            if (!IsMapped(libraryName)) return nint.Zero;
            foreach (string c in Candidates())
                if (File.Exists(c) && NativeLibrary.TryLoad(c, out nint h))
                    return h;
            throw new DllNotFoundException(
                "找不到 " + Lib + "。先构建：src/WpfGfx.Linux.Native/build-shim.sh --all");
        }

        private static bool IsMapped(string name)
        {
            foreach (string m in Mapped)
                if (string.Equals(m, name, StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }

        /// <summary>搜索顺序与 build/shims/Win32ShimResolver.cs 一致。</summary>
        public static IEnumerable<string> Candidates()
        {
            string env = Environment.GetEnvironmentVariable("WPF_LINUX_WIN32_SHIM");
            if (!string.IsNullOrEmpty(env))
            {
                yield return env;
                yield return Path.Combine(env, Lib);
            }

            string baseDir = AppContext.BaseDirectory;
            if (!string.IsNullOrEmpty(baseDir))
                yield return Path.Combine(baseDir, Lib);

            foreach (string start in new[] { baseDir, Directory.GetCurrentDirectory() })
            {
                if (string.IsNullOrEmpty(start)) continue;
                DirectoryInfo dir;
                try { dir = new DirectoryInfo(start); } catch { continue; }
                for (int depth = 0; dir != null && depth < 12; depth++, dir = dir.Parent)
                {
                    string probe = Path.Combine(dir.FullName, "src", "WpfGfx.Linux.Native");
                    if (Directory.Exists(probe))
                        yield return Path.Combine(probe, "bin", Lib);
                }
            }
        }

        // ---- WNDCLASSEX_D（UTF-16 类名；见 win32_abi.h 的逐字段断言）----
        [StructLayout(LayoutKind.Sequential)]
        private struct WNDCLASSEX_D
        {
            public int cbSize;
            public int style;
            public IntPtr lpfnWndProc;
            public int cbClsExtra;
            public int cbWndExtra;
            public IntPtr hInstance;
            public IntPtr hIcon;
            public IntPtr hCursor;
            public IntPtr hbrBackground;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpszMenuName;
            [MarshalAs(UnmanagedType.LPWStr)] public string lpszClassName;
            public IntPtr hIconSm;
        }

        private const int WS_VISIBLE = 0x10000000;
        private const int WS_OVERLAPPEDWINDOW = 0x00CF0000;

        [DllImport(Lib, EntryPoint = "RegisterClassExW", CharSet = CharSet.Unicode)]
        private static extern ushort RegisterClassExW(ref WNDCLASSEX_D wc);

        [DllImport(Lib, EntryPoint = "UnregisterClassW")]
        private static extern int UnregisterClassW(IntPtr atom, IntPtr hInstance);

        // CharSet.Auto（Unix 上折叠为 Ansi）⇒ 运行时先探裸名，类名按 UTF-8 编。
        [DllImport(Lib, EntryPoint = "CreateWindowExW", CharSet = CharSet.Unicode)]
        private static extern IntPtr CreateWindowExW(
            int exStyle, string className, string windowName, int style,
            int x, int y, int width, int height,
            IntPtr parent, IntPtr menu, IntPtr instance, IntPtr param);

        [DllImport(Lib, EntryPoint = "DestroyWindow")]
        private static extern int DestroyWindow(IntPtr hwnd);

        /// <summary>建一个真实顶层窗口，返回 HWND（== X11 XID）。</summary>
        public static IntPtr CreateWindow(string title, int width, int height)
        {
            string className = "M7cProbe[" + Guid.NewGuid().ToString("N").Substring(0, 12) + "]";

            var wc = new WNDCLASSEX_D
            {
                cbSize = Marshal.SizeOf<WNDCLASSEX_D>(),
                style = 0,
                lpfnWndProc = IntPtr.Zero,          // shim 的默认窗口过程足够（本测试不发消息）
                hInstance = IntPtr.Zero,
                lpszMenuName = "",
                lpszClassName = className,
                hbrBackground = (IntPtr)0x1000,     // GetStockObject(NULL_BRUSH) 的返回值
            };

            ushort atom = RegisterClassExW(ref wc);
            if (atom == 0)
                throw new InvalidOperationException(
                    $"RegisterClassExW 失败（LastError={Marshal.GetLastPInvokeError()}）");

            // WS_VISIBLE ⇒ shim 里 CreateWindowExW 会 XMapWindow（见 win32_core.c）
            IntPtr hwnd = CreateWindowExW(
                0, className, title, WS_VISIBLE | WS_OVERLAPPEDWINDOW,
                40, 60, width, height,
                IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero);

            if (hwnd == IntPtr.Zero)
                throw new InvalidOperationException(
                    $"CreateWindowExW 失败（LastError={Marshal.GetLastPInvokeError()}）");
            return hwnd;
        }

        public static void Close(IntPtr hwnd)
        {
            if (hwnd != IntPtr.Zero) DestroyWindow(hwnd);
        }

        /// <summary>shim 自己的 X11 视图：HWND → X11 Window（0 = 不是它的窗口）。</summary>
        [DllImport(Lib, EntryPoint = "WpfLinuxWin32_GetX11Window")]
        public static extern ulong GetX11Window(IntPtr hwnd);

        [DllImport(Lib, EntryPoint = "WpfLinuxWin32_ShimVersion")]
        public static extern int ShimVersion();
    }
}

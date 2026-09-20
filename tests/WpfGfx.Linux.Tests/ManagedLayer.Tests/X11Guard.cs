// M7b 烟测：X server 可用性守卫 + 项目自带的 Win32 shim 探针。
//
// 【跳过模式为什么必须照抄 Windowing.Tests】
//   xunit 2.9.2 的 `SkipException.ForSkip` 需要 v3 的运行期基础设施，v2 会把
//   跳过的用例记成 **Failed**。唯一干净的通道是 `FactAttribute.Skip`——它在
//   **发现期**就读，而特性构造函数也恰好在发现期执行，于是在构造函数里探测
//   X server 并据此设 Skip，就等价于「动态跳过」，且无 X 时用例根本不执行。
//
// 【判据是「真的能 XOpenDisplay」】
//   容器里 DISPLAY 常被预设成 :0 却没有 server 在听。只有 XOpenDisplay 返回
//   非 0 才算数。这里直接 P/Invoke libX11（而不是引用 M1 的 X11Display），
//   理由：本测试工程要验的是**托管层**能否在 Linux 上跑，不该把 M1 主工程
//   拉进依赖图——M1 一改，本工程的编译就要跟着动。

using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using Xunit;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    /// <summary>纯探测：能不能连上 X server。不依赖 xunit 的断言设施。</summary>
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
                nint dpy = XOpenDisplay(null);   // null → libX11 自己读 DISPLAY
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

    /// <summary>
    /// 需要真实 X server 的用例。无 X 时在**发现期**被标成跳过（不是失败）。
    /// 资源管理器里可按 Category=X11 过滤；`dotnet test --filter "Category!=X11"`
    /// 能把窗口用例整批摘出去。
    /// </summary>
    public sealed class X11FactAttribute : FactAttribute
    {
        public X11FactAttribute()
        {
            if (!X11Probe.Available)
                Skip = X11Probe.SkipReason;
        }
    }

    /// <summary>跳过的兜底检查（万一 Skip 没生效，比如直接反射调用测试方法）。</summary>
    internal static class X11Guard
    {
        public static void Require()
        {
            if (!X11Probe.Available)
                throw new InvalidOperationException(X11Probe.SkipReason);
        }
    }

    /// <summary>
    /// 找到本工程的 Win32 shim（<c>libwpfwin32.so</c>）。
    ///
    /// 搜索顺序与 build/shims/Win32ShimResolver.cs **一致**（这是刻意的：
    /// 两边不一致的话，测试加载到的和托管层加载到的可能是两个不同文件，
    /// 于是「测试通过但 WPF 起不来」）。
    ///   env WPF_LINUX_WIN32_SHIM → 程序集目录 → 仓库 src/WpfGfx.Linux.Native/bin
    /// 区别只有一个：这里不设默认值、也不改任何环境变量，走到第三个候选
    /// 才能证明**仓库内回退路径**真的有效（托管层那边就是靠它）。
    /// </summary>
    internal static class ShimLocator
    {
        public const string FileName = "libwpfwin32.so";

        public static IEnumerable<string> Candidates()
        {
            string env = Environment.GetEnvironmentVariable("WPF_LINUX_WIN32_SHIM");
            if (!string.IsNullOrEmpty(env))
            {
                yield return env;
                yield return Path.Combine(env, FileName);
            }

            string baseDir = AppContext.BaseDirectory;
            if (!string.IsNullOrEmpty(baseDir))
                yield return Path.Combine(baseDir, FileName);

            string rootEnv = Environment.GetEnvironmentVariable("WPF_LINUX_ROOT");
            if (!string.IsNullOrEmpty(rootEnv))
                yield return Path.Combine(rootEnv, "src", "WpfGfx.Linux.Native", "bin", FileName);

            foreach (string start in new[] { baseDir, Directory.GetCurrentDirectory() })
            {
                if (string.IsNullOrEmpty(start)) continue;
                DirectoryInfo dir;
                try { dir = new DirectoryInfo(start); } catch { continue; }
                for (int depth = 0; dir != null && depth < 12; depth++, dir = dir.Parent)
                {
                    string probe = Path.Combine(dir.FullName, "src", "WpfGfx.Linux.Native");
                    if (Directory.Exists(probe))
                        yield return Path.Combine(probe, "bin", FileName);
                }
            }
        }

        public static string Resolve()
        {
            foreach (string c in Candidates())
                if (File.Exists(c)) return c;
            throw new FileNotFoundException(
                "找不到 " + FileName + "。先构建：src/WpfGfx.Linux.Native/build-shim.sh --all");
        }
    }

    /// <summary>
    /// 直连 shim 的少量探针导出（ABI 布局、X11 桥接、计数器）。
    /// 只有测试需要这些；托管层自己通过 DllImportResolver 用 Win32 名字访问同一个 .so。
    /// </summary>
    internal static class Win32Shim
    {
        private const string Lib = ShimLocator.FileName;

        /// <summary>与 build/shims/Win32ShimResolver.cs 映射同一批名字。</summary>
        private static readonly string[] Mapped =
        {
            Lib, "user32.dll", "gdi32.dll", "kernel32.dll", "PresentationNative_cor3.dll",
        };

        public static readonly string LoadedPath;

        static Win32Shim()
        {
            // 测试程序集也要自己注册一次：resolver 的作用域是**单个 Assembly**。
            // （这条不是样板代码——M7b 的 resolver 就是按这个语义设计的，见
            //   build/shims/Win32ShimResolver.cs 的注释。）
            //
            // ⚠️ 2026-09-15（`D-R2` 根因定案）：`NativeLibrary.SetDllImportResolver`
            //   **对同一个程序集只能调用一次**，第二次抛 `InvalidOperationException:
            //   A resolver is already set for the assembly.`。本程序集里**曾经**有第二个
            //   安装点（`DP1ReproTests` 的静态构造），它先跑就先占槽 ⇒ **本行抛异常** ⇒
            //   它是**静态构造** ⇒ 整个类型被毒化（`TypeInitializationException`）⇒
            //   凡用 `Win32Shim` 的用例**全灭**、重则 testhost 崩。谁先跑由 xUnit 的
            //   集合并行调度决定 ⇒ 这就是那条"间歇红"的全部来源（实测 A/B 两臂各约一半，
            //   与负载无关）。**已把第二个安装点删掉**（见 `DP1ReproTests`），此处再兜一层：
            //   输掉竞态**不算失败**，因为"本程序集的 `user32.dll` 已经有人接"本身是
            //   合法状态；但**装置缺件仍然是硬失败** —— 下面 `ShimLocator.Resolve()`
            //   找不到 `libwpfwin32.so` 时照样抛。
            try
            {
                NativeLibrary.SetDllImportResolver(typeof(Win32Shim).Assembly, Resolve);
            }
            catch (InvalidOperationException)
            {
                // 已有人为本程序集装过解析器（竞态的另一方赢了）。不是缺陷、不是装置缺件。
            }
            LoadedPath = ShimLocator.Resolve();
            // ⚠️ 2026-09-15（R17C 审计的 F2）：上面那个 `catch` **不能只是沉默** ——
            //   输给"一个映射同样名字的解析器"是合法的，输给"一个不映射 `user32.dll`
            //   的解析器"则会让本程序集的每次 `[DllImport("user32.dll")]` 在**深处**
            //   抛 `DllNotFoundException`（离成因很远）。⇒ 装完**自证一次**：
            //   ⚠️ **不能用 `NativeLibrary.TryLoad("user32.dll", assembly, …)` 做这个自证**：
            //   那个 API 只用程序集定**搜索路径**，**不会**走 `DllImportResolver`
            //   （2026-09-15 实测踩到：它返回 false ⇒ 本静态构造抛 ⇒ 33 条用例全灭）。
            //   ⇒ 必须用**真的 `[DllImport]`**（下面 `ShimVersionViaUser32`）。
            if (!User32MapsToShim())
                throw new InvalidOperationException(
                    "本程序集的 `user32.dll` 解析不到：当前生效的解析器不是我们这一个"
                    + "（`SetDllImportResolver` 每程序集只能装一次，我们这次被抢先者挤掉了）。"
                    + "⇒ 修法：让本测试程序集只保留唯一安装点，或让抢先者映射同一批名字。");
        }

        /// <summary>自证：把 `user32.dll` 当 DllImport 走一次，看解析器是否把它接到 shim。</summary>
        private static bool User32MapsToShim()
        {
            try { _ = ShimVersionViaUser32(); return true; }
            catch (DllNotFoundException) { return false; }
            catch (EntryPointNotFoundException) { return true; }  // 解析成功、只是导出名不同 ⇒ 映射已生效
        }

        [DllImport("user32.dll", EntryPoint = "WpfLinuxWin32_ShimVersion")]
        private static extern nint ShimVersionViaUser32();

        private static nint Resolve(string libraryName, System.Reflection.Assembly assembly,
                                    DllImportSearchPath? searchPath)
        {
            bool mapped = false;
            foreach (string m in Mapped)
                if (string.Equals(m, libraryName, StringComparison.OrdinalIgnoreCase)) { mapped = true; break; }
            if (!mapped)
                return nint.Zero;

            foreach (string c in ShimLocator.Candidates())
                if (File.Exists(c) && NativeLibrary.TryLoad(c, out nint h))
                    return h;
            throw new DllNotFoundException("找不到 " + Lib);
        }

        [DllImport(Lib, EntryPoint = "WpfLinuxWin32_ShimVersion")]
        public static extern int ShimVersion();

        [DllImport(Lib, EntryPoint = "WpfLinuxWin32_AbiLayout")]
        public static extern int AbiLayout([MarshalAs(UnmanagedType.LPUTF8Str)] string what,
                                           [Out] int[] values, int count);

        [DllImport(Lib, EntryPoint = "WpfLinuxWin32_GetX11Window")]
        public static extern ulong GetX11Window(nint hwnd);

        [DllImport(Lib, EntryPoint = "WpfLinuxWin32_WindowCount")]
        public static extern int WindowCount();

        [DllImport(Lib, EntryPoint = "WpfLinuxWin32_GetWndProc")]
        public static extern nint GetWndProc(nint hwnd);

        [DllImport(Lib, EntryPoint = "WpfLinuxWin32_GetClassName")]
        public static extern nint GetClassNameRaw(nint hwnd);

        [DllImport(Lib, EntryPoint = "WpfLinuxWin32_LastError")]
        public static extern nint LastErrorRaw();

        // 少量 user32 入口：测试要「自己动手」的地方（显隐/尺寸/取类名），
        // 走 shim 的裸名导出，与托管层的调用点命中同一份实现。
        [DllImport("user32.dll", EntryPoint = "ShowWindow")]
        public static extern int ShowWindow(nint hwnd, int cmd);

        /// <summary>轨道 C：从**外部**改窗口几何（真应用里"拖边框"那条路径）。</summary>
        [DllImport(Lib, EntryPoint = "SetWindowPos")]
        public static extern int SetWindowPos(nint hwnd, nint insertAfter, int x, int y, int cx, int cy, uint flags);

        [DllImport("user32.dll", EntryPoint = "GetClassNameA")]
        public static extern int GetClassNameA(nint hwnd, byte[] buf, int n);
    }
}

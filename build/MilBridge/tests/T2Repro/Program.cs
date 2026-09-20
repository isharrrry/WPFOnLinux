// T1/M7c3 —— T2 调用姿势的最小复现 + 根因判定。
//
// 逐字照抄 build/shims/PresentationCore.FontBridge.cs 的：
//   ProbeMilExport()        → NativeLibrary.TryLoad(候选路径) + TryGetExport
//   CallRegisterExport()    → Marshal.GetDelegateForFunctionPointer + StringToCoTaskMemUTF8
// 并对比"先/后 触发 MilCore 的 [DllImport]"（后者会经 resolver 注入 native 目录）。

using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using WpfGfx.Linux.Bridge;

namespace MilBridge.T2Repro
{
    internal static class Program
    {
        private const string MilCoreLibraryName = "wpfgfx_cor3.dll";
        private const string MilCoreSharedObjectName = "wpfgfx_cor3.so";
        private const string RegisterExportName = "MilFontFace_RegisterFromFile";

        // 与 FontBridge 逐字一致
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate IntPtr RegisterFromFileDelegate(IntPtr utf8Path, int faceIndex, int simulationFlags);

        // 用来"先触发一次 MilCore 的 DllImport"（经 resolver）
        [DllImport(MilCoreLibraryName, EntryPoint = "MilVersionCheck")]
        private static extern int MilVersionCheck(uint uiCallerMilSdkVersion);

        private static int Main(string[] args)
        {
            string mode = args.Length > 0 ? args[0] : "--t2-first";
            string font = args.Length > 1 ? args[1] : null;

            Console.WriteLine($"== T2Repro · mode={mode} ==");
            Console.WriteLine($"AppContext.BaseDirectory = {AppContext.BaseDirectory}");
            Console.WriteLine($"该目录有 libSkiaSharp.so = {File.Exists(Path.Combine(AppContext.BaseDirectory, "libSkiaSharp.so"))}");
            Console.WriteLine($"LD_LIBRARY_PATH = {Environment.GetEnvironmentVariable("LD_LIBRARY_PATH") ?? "(unset)"}");
            Console.WriteLine();

            if (mode == "--resolver-first")
            {
                // 先让 MilCore 解析器跑一次：它会 NativeLibrary.Load(.so) 并调
                // MilBridge_SetNativeDir 把 .so 自己的目录注入 AOT 镜像。
                int hr = MilVersionCheck(0);
                Console.WriteLine($"[pre] MilVersionCheck via resolver → hr=0x{hr:X8}");
                Console.WriteLine($"[pre] resolver LoadedPath = {MilCoreDllImportResolver.LoadedPath}");
                Console.WriteLine();
            }

            // ---- 以下逐字照抄 T2 的 ProbeMilExport + CallRegisterExport ----
            IntPtr handle = IntPtr.Zero, export = IntPtr.Zero;
            foreach (string candidate in CandidateMilLibraryPaths())
            {
                if (!NativeLibrary.TryLoad(candidate, out IntPtr h)) continue;
                handle = h;
                if (NativeLibrary.TryGetExport(h, RegisterExportName, out IntPtr e)) export = e;
                Console.WriteLine($"[probe] TryLoad OK: {candidate}");
                break;
            }

            Console.WriteLine($"[probe] registerExport = {(export != IntPtr.Zero ? "找到(" + RegisterExportName + ")" : "未找到")}");
            if (export == IntPtr.Zero) { Console.WriteLine("结论：导出没找到"); return 2; }

            if (mode == "--t2-first")
            {
                // 关键：在 T2 的调用点**之前**，MilCore 的 [DllImport] 一次都没发生 →
                // 解析器没跑过 → MilBridge_SetNativeDir 没被调用。
                Console.WriteLine($"[state] MilCoreDllImportResolver.IsLoaded = {MilCoreDllImportResolver.IsLoaded}" +
                                  "   （false ⇒ .so 内部的 native 目录从未被注入）");
            }

            Console.WriteLine();
            IntPtr token = CallRegisterExport(export, font, 0, 0);
            Console.WriteLine($"[call] MilFontFace_RegisterFromFile(\"{font}\", 0, 0) = 0x{token.ToInt64():X}");

            // ---- 失败路径 + 新诊断导出：每条都要能说出原因 ----
            Console.WriteLine();
            Console.WriteLine("[diag-matrix] 失败路径 → (返回值, 诊断码, 诊断文本)");
            DiagMatrix(handle, export, "文件不存在", "/nonexistent/NoSuchFont.ttf", 0, 0);
            DiagMatrix(handle, export, "faceIndex < 0", font, -1, 0);
            DiagMatrix(handle, export, "faceIndex 越界", font, 9999, 0);
            DiagMatrix(handle, export, "NULL 路径", null, 0, 0);
            DiagMatrix(handle, export, "空串", "", 0, 0);
            DiagMatrix(handle, export, "非法 UTF-8", "\u00ff\u00feBAD", 0, 0);

            if (token != IntPtr.Zero) DiagMatrix(handle, export, "成功（清掉上一次失败）", font, 0, 1);

            // ---- 验收 #2：跨运行时闭环 ----
            // 令牌是 .so 的运行时发的，交给**同一个 .so** 里的 MilGlyphRun_GetGlyphOutline
            // 应当能查出轮廓；宿主进程的字体面表里根本没有这个令牌。
            Console.WriteLine();
            Console.WriteLine("[cross-runtime] 令牌交给 .so 内的 MilGlyphRun_GetGlyphOutline");
            if (token == IntPtr.Zero)
            {
                Console.WriteLine("  跳过：令牌为 0");
            }
            else if (!NativeLibrary.TryGetExport(handle, "MilGlyphRun_GetGlyphOutline", out IntPtr go))
            {
                Console.WriteLine("  失败：找不到导出 MilGlyphRun_GetGlyphOutline");
            }
            else
            {
                var get = (GetGlyphOutlineDelegate)Marshal.GetDelegateForFunctionPointer(
                    go, typeof(GetGlyphOutlineDelegate));
                int hr = get(token, 36 /* 'A' */, 0, 32.0, out IntPtr data, out uint size, out int fillRule);
                Console.WriteLine($"  hr=0x{hr:X8} size={size} bytes fillRule={fillRule} ptr=0x{data.ToInt64():X}" +
                                  (hr == 0 && size > 0 ? "   ✅ 跨运行时接通（真轮廓）" : "   ❌"));

                // 对照：伪造令牌必须 E_HANDLE
                int hr2 = get(new IntPtr(0x7FFFFFFF), 36, 0, 32.0, out _, out _, out _);
                Console.WriteLine($"  对照：伪造令牌 hr=0x{hr2:X8}（期望 0x80070006 E_HANDLE）");

                if (NativeLibrary.TryGetExport(handle, "MilGlyphRun_ReleasePathGeometryData", out IntPtr rel) && data != IntPtr.Zero)
                {
                    var release = (ReleaseDelegate)Marshal.GetDelegateForFunctionPointer(rel, typeof(ReleaseDelegate));
                    Console.WriteLine($"  释放轮廓缓冲 hr=0x{release(data):X8}");
                }
            }

            return token != IntPtr.Zero ? 0 : 1;
        }

        /// <summary>跑一条失败路径，并回读新诊断导出的原因码与文本。</summary>
        private static void DiagMatrix(IntPtr handle, IntPtr export, string label, string path, int faceIndex, int simFlags)
        {
            ResetDiag(handle);
            IntPtr r = CallRegisterExport(export, path, faceIndex, simFlags);
            Console.WriteLine($"  {label,-26} ret=0x{r.ToInt64():X}  code={ReadDiagCode(handle)}  msg={PtrToUtf8(LastErrorPtr(handle))}");
        }

        private static void ResetDiag(IntPtr handle)
        {
            if (NativeLibrary.TryGetExport(handle, "MilBridge_Diag_ResetFontFaceError", out IntPtr p))
                Marshal.GetDelegateForFunctionPointer<Action>(p)();
        }

        private static string ReadDiagCode(IntPtr handle)
        {
            if (!NativeLibrary.TryGetExport(handle, "MilBridge_Diag_LastFontFaceError", out IntPtr p)) return "(无)";
            var f = (DiagFn)Marshal.GetDelegateForFunctionPointer(p, typeof(DiagFn));
            return $"0x{f().ToInt64():X}({(FontFaceFailure)f().ToInt64()})";
        }

        /// <summary>与 src/WpfGfx.Linux/Interop/MilNative.FontFace.cs 的 Failure 枚举同步。</summary>
        private enum FontFaceFailure
        {
            None = 0, NullPath = 1, EmptyPath = 2, PathTooLong = 3,
            InvalidUtf8 = 4, FileNotFound = 5, NegativeFaceIndex = 6,
            TypefaceLoadFailed = 7, Exception = 8,
        }

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate IntPtr DiagFn();

        // 上游 UnsafeNativeMethodsMilCoreApi 的形状：
        //   int MilGlyphRun_GetGlyphOutline(IntPtr pFontFace, ushort glyphIndex, bool sideways,
        //                                   double renderingEmSize, out byte* pPathGeometryData,
        //                                   out UInt32 pSize, out FillRule pFillRule)
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int GetGlyphOutlineDelegate(
            IntPtr pFontFace, ushort glyphIndex, int sideways, double renderingEmSize,
            out IntPtr pPathGeometryData, out uint pSize, out int pFillRule);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int ReleaseDelegate(IntPtr pPathGeometryData);

        private static IntPtr LastErrorPtr(IntPtr handle)
        {
            if (!NativeLibrary.TryGetExport(handle, "MilBridge_Diag_LastFontFaceErrorMessage", out IntPtr p))
                return IntPtr.Zero;
            var f = (DiagFn)Marshal.GetDelegateForFunctionPointer(p, typeof(DiagFn));
            return f();
        }

        private static string PtrToUtf8(IntPtr p) =>
            p == IntPtr.Zero ? "(null)" : Marshal.PtrToStringUTF8(p) ?? "(?)";

        private static IntPtr CallRegisterExport(IntPtr export, string path, int faceIndex, int simFlags)
        {
            try
            {
                var register = (RegisterFromFileDelegate)Marshal.GetDelegateForFunctionPointer(
                    export, typeof(RegisterFromFileDelegate));

                // "非法 UTF-8" 用例：路径以 ÿþ 开头 → StringToCoTaskMemUTF8 会编成
                // 合法 UTF-8（C3 BF C3 BE），**不是**非法字节。所以这里手工放一个 0xFF 字节。
                if (path != null && path.Length > 0 && path[0] == '\u00ff')
                {
                    byte[] raw = { 0xFF, 0xFE, (byte)'B', (byte)'A', (byte)'D', 0 };
                    IntPtr buf = Marshal.AllocHGlobal(raw.Length);
                    try
                    {
                        Marshal.Copy(raw, 0, buf, raw.Length);
                        return register(buf, faceIndex, simFlags);
                    }
                    finally { Marshal.FreeHGlobal(buf); }
                }

                IntPtr utf8 = path == null ? IntPtr.Zero : Marshal.StringToCoTaskMemUTF8(path);
                try { return register(utf8, faceIndex, simFlags); }
                finally { if (utf8 != IntPtr.Zero) Marshal.FreeCoTaskMem(utf8); }
            }
            catch (Exception ex)
            {
                Console.WriteLine("  (调用抛异常: " + ex.GetType().Name + " " + ex.Message + ")");
                return IntPtr.Zero;
            }
        }

        /// <summary>逐字照抄 FontBridge.CandidateMilLibraryPaths()。</summary>
        private static string[] CandidateMilLibraryPaths()
        {
            var candidates = new List<string>();
            string baseDirectory = AppContext.BaseDirectory;
            candidates.Add(Path.Combine(baseDirectory, MilCoreSharedObjectName));

            var dir = new DirectoryInfo(baseDirectory);
            while (dir != null)
            {
                candidates.Add(Path.Combine(dir.FullName, "build", "MilBridge", ".artifacts", "publish",
                                           "MilBridge.Linux", "release_linux-x64", MilCoreSharedObjectName));
                candidates.Add(Path.Combine(dir.FullName, "build", "MilBridge", ".artifacts", "bin",
                                           "MilBridge.Linux", "release_linux-x64", "native", MilCoreSharedObjectName));
                dir = dir.Parent;
            }

            candidates.Add(MilCoreSharedObjectName);
            return candidates.ToArray();
        }
    }
}

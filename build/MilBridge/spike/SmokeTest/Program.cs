// T1 Phase 1-A：NativeAOT .so 的真 P/Invoke 闭环。
//
// 断言：
//   A1  [DllImport("wpfgfx_cor3.dll")] 在 Linux 上默认必失败（DllNotFoundException）——
//       先证明"没有 resolver 就是不行"，否则后面的成功没有说服力。
//   A2  SetDllImportResolver + [ModuleInitializer] 之后，同一批 DllImport 能真调到 aotspike.so。
//   A3  指针参数按字节读写正确。
//   A4  AOT 库内部的托管状态真的活着（identity 往返）。

using System;
using System.IO;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

namespace MilBridge.SmokeTest
{
    internal static unsafe class Program
    {
        private const string MilCore = "wpfgfx_cor3.dll";

        // ---- 被测的 P/Invoke 声明（形状与上游 exports.cs 一致：int 返回 + byte* 参数）----
        [DllImport(MilCore, EntryPoint = "aotspike_add")]
        internal static extern int Add(int a, int b);

        [DllImport(MilCore, EntryPoint = "aotspike_sum_bytes")]
        internal static extern int SumBytes(byte* pbData, uint cbSize);

        [DllImport(MilCore, EntryPoint = "aotspike_identity")]
        internal static extern int Identity(int v);

        private static string s_libPath;
        private static int s_resolverCalls;

        [ModuleInitializer]
        internal static void InstallResolver()
        {
            s_libPath = Environment.GetEnvironmentVariable("MILBRIDGE_AOTSPIKE_SO");
            if (string.IsNullOrEmpty(s_libPath))
            {
                s_libPath = Path.Combine(AppContext.BaseDirectory, "aotspike.so");
            }

            NativeLibrary.SetDllImportResolver(typeof(Program).Assembly, Resolve);
        }

        private static IntPtr Resolve(string libraryName, System.Reflection.Assembly assembly, DllImportSearchPath? searchPath)
        {
            if (libraryName != MilCore) return IntPtr.Zero;  // 交给默认探测
            s_resolverCalls++;
            return NativeLibrary.Load(s_libPath);
        }

        private static int s_pass, s_fail;

        private static void Check(string name, bool ok, string detail)
        {
            if (ok) { s_pass++; Console.WriteLine($"  PASS  {name}  {detail}"); }
            else { s_fail++; Console.WriteLine($"  FAIL  {name}  {detail}"); }
        }

        private static int Main()
        {
            Console.WriteLine($"== MilBridge Phase 1-A：NativeAOT .so 真 P/Invoke 闭环 ==");
            Console.WriteLine($"lib = {s_libPath}");
            Console.WriteLine($"exists = {File.Exists(s_libPath)}");
            Console.WriteLine();

            // A1：先证明没有 resolver 时不行 —— 用一个**不注册 resolver 的独立 ALC**做不到，
            // 这里退化成"直接探测原始库名"，语义等价：默认探测 wpfgfx_cor3.dll 必失败。
            {
                bool threw = false;
                string msg = "";
                try { NativeLibrary.Load(MilCore); }
                catch (Exception ex) { threw = true; msg = ex.GetType().Name; }
                Check("A1 默认探测 wpfgfx_cor3.dll 必失败", threw, $"threw={threw} {msg}");
            }

            // A2：通过 resolver 真调到
            {
                int r = Add(40, 2);
                Check("A2a [DllImport] -> AOT .so: Add(40,2)", r == 42, $"got {r}, resolverCalls={s_resolverCalls}");
                int r2 = Identity(1234);
                Check("A2b AOT 库内托管状态往返", r2 == 1234, $"got {r2}");
            }

            // A3：指针参数按字节读写（用非托管缓冲，确保真的跨了 ABI 边界）
            {
                const int n = 7;
                byte* buf = (byte*)Marshal.AllocHGlobal(n);
                try
                {
                    for (int i = 0; i < n; i++) buf[i] = (byte)(i + 1); // 1..7 = 28
                    int sum = SumBytes(buf, n);
                    Check("A3 byte* 参数逐字节读", sum == 28, $"sum={sum} expect=28");
                    int hr = SumBytes(null, 1);
                    Check("A3b null 指针走错误路径", hr == unchecked((int)0x80070057), $"hr=0x{hr:X8}");
                }
                finally { Marshal.FreeHGlobal((IntPtr)buf); }
            }

            Console.WriteLine();
            Console.WriteLine($"== 通过 {s_pass} / 失败 {s_fail} ==");
            return s_fail == 0 ? 0 : 1;
        }
    }
}

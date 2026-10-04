// 只回答一个问题：.NET 侧解析导出，会不会出现在 ld.so 的 LD_DEBUG=symbols 日志里？
using System;
using System.Runtime.InteropServices;

internal static class Program
{
    private static int Main()
    {
        string shim = Environment.GetEnvironmentVariable("WPF_PROBE_SHIM")
            ?? throw new InvalidOperationException("死根已清：未设 WPF_PROBE_SHIM（本件不再内嵌退役树路径）");
        Console.WriteLine("NativeLibrary.Load(" + shim + ")");
        IntPtr h = NativeLibrary.Load(shim);
        foreach (string n in new[] { "LsDisableSpecialCharacterLigature", "LoAcquireBreakRecord", "LoCreateLine" })
        {
            try
            {
                IntPtr p = NativeLibrary.GetExport(h, n);
                Console.WriteLine($"  {n}: FOUND ({p})");
            }
            catch (EntryPointNotFoundException)
            {
                Console.WriteLine($"  {n}: MISS（EntryPointNotFoundException）");
            }
        }
        NativeLibrary.Free(h);
        return 0;
    }
}

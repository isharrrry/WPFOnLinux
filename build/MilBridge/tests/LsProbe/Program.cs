// 只回答一个问题：.NET 侧解析导出，会不会出现在 ld.so 的 LD_DEBUG=symbols 日志里？
using System;
using System.Runtime.InteropServices;

internal static class Program
{
    private static int Main()
    {
        const string shim = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";
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

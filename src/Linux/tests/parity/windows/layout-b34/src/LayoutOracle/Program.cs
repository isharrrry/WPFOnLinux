// B2/B3/B4 oracle 入口。
//
//   LayoutOracle probe <out.json> [fontDir]
//   LayoutOracle run   <cases.json> <out.json> [fontDir]        （对拍主体，见 Runner.cs）
//
// STAThread：WPF 的字体/排版类型在 STA 下最省事（字体缓存、Typeface 解析）。

using System;

namespace WpfOracleLayout
{
    internal static class Program
    {
        [STAThread]
        private static int Main(string[] args)
        {
            Console.OutputEncoding = System.Text.Encoding.UTF8;
            if (args.Length == 0)
            {
                Console.Error.WriteLine("usage: LayoutOracle probe <out.json> [fontDir] | gencases <cases.json> | run <cases.json> <out.json> [fontDir]");
                return 2;
            }

            // ⚠️ 每个模式的参数位置不同，不能共用一个 fontDir 解析：
            //    probe    <out.json> [fontDir]
            //    gencases <cases.json>
            //    run      <cases.json> <out.json> [fontDir]
            // 第一版按 args[2] 取 fontDir，run 模式下拿到的其实是**输出文件路径**，
            // 于是"文件式字体"静默退化成系统回退字体——正是自检 fileFontMismatch 抓出来的。
            string DefaultFontDir() => System.IO.Path.Combine(AppContext.BaseDirectory, "fonts");

            switch (args[0])
            {
                case "probe":
                    return Probe.Run(args.Length > 1 ? args[1] : "probe.json",
                                     args.Length > 2 ? args[2] : DefaultFontDir());
                case "run":
                    return Runner.Run(args[1], args[2],
                                      args.Length > 3 ? args[3] : DefaultFontDir());
                case "gencases":
                    return Cases.WriteCases(args.Length > 1 ? args[1] : "cases.json",
                                             args.Length > 2 ? args[2] : null);
                default:
                    Console.Error.WriteLine("unknown mode: " + args[0]);
                    return 2;
            }
        }
    }
}

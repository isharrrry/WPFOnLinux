// T1c · 覆盖查询自检的探针（**命令行 + 原始输出**；主控批准常设的第 ④ 条）
// =====================================================================================
// 用法：
//   dotnet build build/MilBridge/tests/FamilyCoverageSelfTest/FamilyCoverageSelfTest.csproj -c Release -m:1
//   # ① 缺省档（证明"缺省下逐字节不改变行为"）
//   dotnet build/MilBridge/tests/FamilyCoverageSelfTest/bin/Release/MilBridge.FamilyCoverageSelfTest.dll
//   # ② 打开档（把两条覆盖链并排打出来）
//   dotnet build/MilBridge/tests/FamilyCoverageSelfTest/bin/Release/MilBridge.FamilyCoverageSelfTest.dll --enabled
//   # 可加 --dir <目录>（可重复；缺省 = /usr/share/fonts）与 --family <族名>（缺省 = 第一个族）
//
// 【为什么要两档**分开进程**跑】`FamilyCoverageSelfTest.Enabled` 是**静态只读**（类型初始化时定值）。
//   ⇒ 开关必须在**触碰该类型之前**设好，否则读到的是上一次的值 ——
//      那正是"我加了验证步骤 ≠ 我被验证过"那一族（验证器自己骗自己）。
//      所以 `--enabled` 在 Main 的**第一行**就 `Environment.SetEnvironmentVariable`。
using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using MS.Internal.Text.TextInterface.Linux;

namespace MilBridge.T1cCoverageSelfTestProbe
{
    internal static class Program
    {
        private static int Main(string[] args)
        {
            bool wantEnabled = false;
            var dirs = new List<string>();
            string familyName = null;

            for (int i = 0; i < args.Length; i++)
            {
                switch (args[i])
                {
                    case "--enabled": wantEnabled = true; break;
                    case "--dir": if (i + 1 < args.Length) dirs.Add(args[++i]); break;
                    case "--family": if (i + 1 < args.Length) familyName = args[++i]; break;
                    default:
                        Console.Error.WriteLine("未知参数：" + args[i]);
                        return 2;
                }
            }

            // ⚠️ 必须在**任何** FamilyCoverageSelfTest 成员被触碰之前设好（见文件头）
            if (wantEnabled) Environment.SetEnvironmentVariable(FamilyCoverageSelfTest.EnableEnvVar, "1");
            else Environment.SetEnvironmentVariable(FamilyCoverageSelfTest.EnableEnvVar, null);

            if (dirs.Count == 0) dirs.Add("/usr/share/fonts");

            Console.WriteLine("== T1c 覆盖查询自检探针 ==");
            Console.WriteLine($"SELFTEST_ARM={(wantEnabled ? "enabled" : "default")}" +
                              $" env={Environment.GetEnvironmentVariable(FamilyCoverageSelfTest.EnableEnvVar) ?? "<未设>"}" +
                              $" dirs=[{string.Join(",", dirs)}]" +
                              $" family={(familyName ?? "<第一个族>")}");
            Console.WriteLine($"SELFTEST_PROVIDER dll={ProviderPath()} sha256={ProviderSha256()}");

            LinuxFontCollection collection = null;
            try
            {
                collection = LinuxFontCollection.FromDirectories(dirs, recurse: true);
            }
            catch (Exception e)
            {
                Console.Error.WriteLine("集合加载失败：" + e.GetType().Name + ": " + e.Message);
                return 3;
            }

            Console.WriteLine($"SELFTEST_COLLECTION families={collection.FamilyCount} files={collection.FileNames.Count}");

            LinuxFontFamily family = null;
            if (!string.IsNullOrEmpty(familyName)) family = collection[familyName];
            if (family == null && collection.FamilyCount > 0) family = collection[0];
            Console.WriteLine($"SELFTEST_BASEFAMILY name={(family == null ? "<无>" : family.FamilyName)}");

            // ── 关键断言：**缺省档下 `Run()` 必须什么都不做**（不输出、不查询）──
            long before = FamilyCoverageQuery.Stats.Queries;
            var report = FamilyCoverageSelfTest.Run(collection, family);
            long after = FamilyCoverageQuery.Stats.Queries;

            Console.WriteLine($"SELFTEST_REPORT {report}");

            var sb = new StringWriter();
            FamilyCoverageSelfTest.Write(report, sb);
            string text = sb.ToString();

            bool defaultArm = !wantEnabled;
            bool pass;
            string detail;

            if (defaultArm)
            {
                // ① 开关解析为 false；② 没跑；③ 没有输出；④ 查询计数**未变**
                pass = !report.Enabled && !report.Ran && text.Length == 0 && before == after;
                detail = $"enabled={report.Enabled} ran={report.Ran} outputChars={text.Length} queries={before}->{after}";
            }
            else
            {
                pass = report.Enabled && report.Ran && text.Length > 0 && report.Disagreements == 0;
                detail = $"enabled={report.Enabled} ran={report.Ran} outputChars={text.Length} " +
                         $"samples={report.Samples} disagreements={report.Disagreements}";
            }

            Console.WriteLine($"SELFTEST_{(defaultArm ? "DEFAULT" : "ENABLED")}_ASSERT={(pass ? "PASS" : "FAIL")} {detail}");

            if (!defaultArm)
            {
                Console.WriteLine("---- 原始输出（自检正文）----");
                Console.Write(text);
                Console.WriteLine("---- 原始输出结束 ----");
            }

            return pass ? 0 : 1;
        }

        private static string ProviderPath()
        {
            try { return typeof(LinuxFontCollection).Assembly.Location; }
            catch (Exception) { return "<取不到>"; }
        }

        private static string ProviderSha256()
        {
            try
            {
                string path = typeof(LinuxFontCollection).Assembly.Location;
                if (string.IsNullOrEmpty(path) || !File.Exists(path)) return "<取不到>";

                using (var sha = SHA256.Create())
                using (var stream = File.OpenRead(path))
                {
                    byte[] hash = sha.ComputeHash(stream);
                    var sb = new System.Text.StringBuilder(hash.Length * 2);
                    foreach (byte b in hash) sb.Append(b.ToString("x2"));
                    return sb.ToString();
                }
            }
            catch (Exception) { return "<取不到>"; }
        }
    }
}

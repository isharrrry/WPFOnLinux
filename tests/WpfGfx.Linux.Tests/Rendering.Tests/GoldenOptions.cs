// golden 基准图的更新开关。
//
// 【为什么不用 xUnit 的 Skip】
//   --update-golden 是一次性的维护动作，不是"永远跑"的测试。跳过会让它从报告里
//   消失，等于没人记得起还有这个开关。这里做成"任一条 golden 用例在更新模式下
//   会重写基准图并仍然 Pass"，既保留可见性，又能在 CI 上把开关关掉当回归用。
//
// 【三种触发方式，任一命中即生效】
//   1. 命令行     update-golden.sh（内部设环境变量）
//   2. 环境变量   WPFGOLDEN_UPDATE=1
//   3. 标记文件   tests/golden/UPDATE_GOLDEN （适合 IDE 里点一下就开）
//
// 另：dotnet test 有时会把 `--update-golden` 透传进命令行参数，这里也认。

using System;
using System.IO;
using System.Linq;

namespace WpfGfx.Linux.Tests.Rendering
{
    internal static class GoldenOptions
    {
        public const string EnvVar = "WPFGOLDEN_UPDATE";

        public static bool UpdateEnabled
        {
            get
            {
                string env = Environment.GetEnvironmentVariable(EnvVar);
                if (IsTruthy(env)) return true;

                try
                {
                    if (File.Exists(Path.Combine(RepoLayout.GoldenDir, "UPDATE_GOLDEN"))) return true;
                }
                catch (DirectoryNotFoundException)
                {
                    // 仓库根定位失败时不要因为开关而掩盖真正的错误
                }

                return Environment.GetCommandLineArgs()
                    .Any(a => string.Equals(a, "--update-golden", StringComparison.OrdinalIgnoreCase));
            }
        }

        /// <summary>用例里输出用：说明本次运行是不是在更新基准图。</summary>
        public static string Describe() =>
            UpdateEnabled
                ? $"更新模式（{EnvVar}=1 / tests/golden/UPDATE_GOLDEN），本次将重写基准图"
                : "比对模式（要更新基准图请加 --update-golden）";

        private static bool IsTruthy(string v) =>
            !string.IsNullOrWhiteSpace(v) &&
            (v == "1" ||
             v.Equals("true", StringComparison.OrdinalIgnoreCase) ||
             v.Equals("yes", StringComparison.OrdinalIgnoreCase) ||
             v.Equals("on", StringComparison.OrdinalIgnoreCase));
    }
}

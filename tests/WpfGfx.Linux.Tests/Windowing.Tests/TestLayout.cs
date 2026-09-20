// 测试用的仓库内固定路径。
//
// 与 Rendering.Tests/RepoLayout 的同名类是**刻意重复**而不是引用：
// Rendering.Tests 内部类型没有对我们的程序集开友元，而 tests/ 归 test-harness 组，
// 按 handoff §7 的目录边界我们不能改它。重复 20 行路径解析，代价远小于越界。
//
// golden / artifacts 落在**本测试目录**下（tests/WpfGfx.Linux.Tests/Windowing.Tests/），
// 不复用 tests/golden/ —— 后者是 T4 渲染组的资产目录，混进去会让两边的
// `--update-golden` 互相覆盖。

using System;
using System.IO;

namespace WpfGfx.Linux.Tests.Windowing
{
    internal static class TestLayout
    {
        private static readonly Lazy<string> Root = new Lazy<string>(FindRoot);

        /// <summary>仓库根：向上找到第一个含 handoff.md 的目录。</summary>
        public static string RootPath => Root.Value;

        /// <summary>本测试目录：tests/WpfGfx.Linux.Tests/Windowing.Tests。</summary>
        public static string ProjectDir { get; } = LocateProjectDir();

        /// <summary>基准图目录 Windowing.Tests/golden/。</summary>
        public static string GoldenDir => Path.Combine(ProjectDir, "golden");

        /// <summary>实测图 / diff 图目录 Windowing.Tests/artifacts/。</summary>
        public static string ArtifactDir => Path.Combine(ProjectDir, "artifacts");

        /// <summary>打包字体目录 build/fonts/（含 SHA256SUMS）。</summary>
        public static string FontDir => Path.Combine(RootPath, "build", "fonts");

        public static string GoldenPath(string name) => Path.Combine(GoldenDir, name + ".png");

        public static string ActualPath(string name) => Path.Combine(ArtifactDir, name + ".png");

        public static string DiffPath(string name) => Path.Combine(ArtifactDir, name + ".diff.png");

        public static void EnsureDirectories()
        {
            Directory.CreateDirectory(GoldenDir);
            Directory.CreateDirectory(ArtifactDir);
        }

        private static string LocateProjectDir()
        {
            // 编译期常量不可用，运行时从 AppContext.BaseDirectory 往上找本工程目录。
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null)
            {
                if (dir.Name == "Windowing.Tests") return dir.FullName;
                dir = dir.Parent;
            }

            // 兜底：bin/ 下找不到就退回仓库根拼路径。
            return Path.Combine(RootPath, "tests", "WpfGfx.Linux.Tests", "Windowing.Tests");
        }

        private static string FindRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null)
            {
                if (File.Exists(Path.Combine(dir.FullName, "handoff.md")))
                    return dir.FullName;
                dir = dir.Parent;
            }

            throw new DirectoryNotFoundException(
                $"无法从 {AppContext.BaseDirectory} 向上定位仓库根（未找到 handoff.md）");
        }
    }
}

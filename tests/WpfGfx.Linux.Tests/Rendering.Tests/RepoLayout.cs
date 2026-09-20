// 仓库内固定路径的解析。
//
// 为什么不放在 bin/ 下：golden 图是要进 Git 的基准资产，实测/diff 图是要给人看的
// 产物，两者都不能随 `dotnet build` 的清理而消失，也不能因为 Debug/Release 不同而
// 落到两套目录里。所以一律锚定到仓库根（含 handoff.md 的那一层）。

using System;
using System.IO;

namespace WpfGfx.Linux.Tests.Rendering
{
    internal static class RepoLayout
    {
        private static readonly Lazy<string> Root = new Lazy<string>(FindRoot);

        /// <summary>仓库根：向上找到第一个含 handoff.md 的目录。</summary>
        public static string RootPath => Root.Value;

        /// <summary>基准图目录 tests/golden/。</summary>
        public static string GoldenDir => Path.Combine(RootPath, "tests", "golden");

        /// <summary>实测图与 diff 图目录 tests/artifacts/rendering/。</summary>
        public static string ArtifactDir => Path.Combine(RootPath, "tests", "artifacts", "rendering");

        /// <summary>打包字体目录 build/fonts/（含 SHA256SUMS）。</summary>
        public static string FontDir => Path.Combine(RootPath, "build", "fonts");

        public static string GoldenPath(string name) => Path.Combine(GoldenDir, name + ".png");

        public static string ActualPath(string name) => Path.Combine(ArtifactDir, name + ".png");

        public static string DiffPath(string name) => Path.Combine(ArtifactDir, name + ".diff.png");

        private static string FindRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null)
            {
                if (File.Exists(Path.Combine(dir.FullName, "handoff.md")))
                    return dir.FullName;
                dir = dir.Parent;
            }

            // 兜底：找得到 global.json 也算，避免 handoff.md 被挪走后整套测试全崩。
            dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null)
            {
                if (File.Exists(Path.Combine(dir.FullName, "global.json")))
                    return dir.FullName;
                dir = dir.Parent;
            }

            throw new DirectoryNotFoundException(
                $"无法从 {AppContext.BaseDirectory} 向上定位仓库根（未找到 handoff.md 或 global.json）");
        }
    }
}

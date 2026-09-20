// 仓库内固定路径的定位（打包字体目录 + 截图输出目录）。
//
// 【为什么不能只从 AppContext.BaseDirectory 往上找】
//   handoff 要求 T9 用 `--artifacts-path` 把 obj/bin 挪到仓库外，避免并行 agent 之间
//   的文件锁冲突。一旦挪走，BaseDirectory 就变成 /tmp/hellomil-artifacts/bin/...，
//   沿着它往上走永远碰不到仓库根 —— 现有 tests/ 下的 RepoLayout / TestLayout 就是
//   这么写的，于是在 --artifacts-path 下会成片失败（详见交付报告的「发现的问题」）。
//
//   所以这里用**三个锚点**依次尝试：
//     1. AppContext.BaseDirectory     —— 常规 `dotnet run` / 不带 artifacts-path 的测试
//     2. Environment.CurrentDirectory —— 从仓库目录下发起调用
//     3. 本源文件的编译期路径         —— `dotnet build --artifacts-path` 下的兜底，
//                                       [CallerFilePath] 是编译期常量，不受输出目录影响
//   判定条件直接找 `build/fonts/*.ttf`，比"找一个叫 handoff.md 的文件"更贴近需求：
//   我们要的就是字体，找到了才算数。

using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.CompilerServices;

namespace HelloMil
{
    public static class HelloMilPaths
    {
        /// <summary>本工程目录 samples/HelloMil。</summary>
        public static string ProjectDirectory { get; } = LocateProjectDirectory();

        /// <summary>打包字体目录 build/fonts。找不到返回 null（调用方决定是报错还是跳过）。</summary>
        public static string FontDirectory => LocateFontDirectory();

        /// <summary>默认截图输出路径。</summary>
        public static string DefaultScreenshotPath => Path.Combine(ProjectDirectory, "screenshot.png");

        public static string LocateFontDirectory()
        {
            string root = LocateRepositoryRoot();
            return root == null ? null : Path.Combine(root, "build", "fonts");
        }

        /// <summary>从任一锚点向上找到含 build/fonts/*.ttf 的那一层。</summary>
        public static string LocateRepositoryRoot()
        {
            foreach (string anchor in Anchors())
            {
                string root = WalkUp(anchor);
                if (root != null) return root;
            }

            return null;
        }

        private static IEnumerable<string> Anchors([CallerFilePath] string thisFile = null)
        {
            yield return AppContext.BaseDirectory;
            yield return Environment.CurrentDirectory;
            if (!string.IsNullOrEmpty(thisFile))
                yield return Path.GetDirectoryName(thisFile);
        }

        private static string WalkUp(string start)
        {
            if (string.IsNullOrEmpty(start)) return null;

            DirectoryInfo dir;
            try { dir = new DirectoryInfo(start); }
            catch (ArgumentException) { return null; }

            while (dir != null)
            {
                string fonts = Path.Combine(dir.FullName, "build", "fonts");
                if (Directory.Exists(fonts))
                {
                    try
                    {
                        foreach (string _ in Directory.EnumerateFiles(fonts, "*.ttf"))
                            return dir.FullName;   // 至少有一份字体才算数
                    }
                    catch (IOException) { /* 落到下一层继续找 */ }
                }

                dir = dir.Parent;
            }

            return null;
        }

        private static string LocateProjectDirectory()
        {
            // 源文件路径是最可靠的锚点：无论 bin 被 --artifacts-path 挪到哪里，
            // 编译期记录的 samples/HelloMil/HelloMilPaths.cs 位置都不会变。
            string here = Path.GetDirectoryName(SourcePath());
            if (here != null && Directory.Exists(here)) return here;

            string root = LocateRepositoryRoot();
            return root == null
                ? Environment.CurrentDirectory
                : Path.Combine(root, "samples", "HelloMil");
        }

        private static string SourcePath([CallerFilePath] string path = null) => path;
    }
}

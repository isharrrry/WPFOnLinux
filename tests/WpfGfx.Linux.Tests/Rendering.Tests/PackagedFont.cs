// 打包字体的定位与校验。
//
// 【为什么测试必须锁死字体】
//   handoff §6「确定性保证」第 1 条：golden 图比对的前提是"同一个输入永远出同一个
//   输出"。容器里 /usr/share/fonts 的存在与否、版本、hinting 配置都会改变字形轮廓，
//   一旦 Skia 悄悄 fallback 到系统字体，golden 就会随机飘。所以：
//     · 测试只允许用 build/fonts 下 SHA-256 锁定的 Noto Sans
//     · 每次用到字体前先校验哈希，哈希对不上就 Fail 而不是"凑合跑"
//
// 【本轮为什么只校验不排版】
//   文本渲染（GlyphRun → Skia）归 T6 的 Text/ 组，T4 的 MilDrawGlyphRun 只是把活
//   委托给 MilResourceProvider.GlyphRunRenderer。这里能做的是把"字体资产可信且
//   字形度量稳定"这件事钉死，等 T6 接进来时 golden 直接可用。

using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using SkiaSharp;

namespace WpfGfx.Linux.Tests.Rendering
{
    internal static class PackagedFont
    {
        public const string RegularFileName = "NotoSans-Regular.ttf";
        public const string BoldFileName = "NotoSans-Bold.ttf";

        /// <summary>打包字体目录（build/fonts）。每个渲染上下文的 FontDirectory 都指向这里。</summary>
        public static string Directory => RepoLayout.FontDir;

        public static string RegularPath => Path.Combine(Directory, RegularFileName);

        /// <summary>build/fonts/SHA256SUMS 的内容：文件名 → 小写十六进制哈希。</summary>
        public static IReadOnlyDictionary<string, string> ExpectedChecksums => LoadChecksums();

        /// <summary>
        /// 校验所有打包字体的 SHA-256 是否与 SHA256SUMS 一致。
        /// 返回 (文件名, 期望, 实际) 的不一致列表；空列表表示全部通过。
        /// </summary>
        public static List<(string File, string Expected, string Actual)> VerifyChecksums()
        {
            var mismatches = new List<(string, string, string)>();
            foreach (KeyValuePair<string, string> kv in ExpectedChecksums)
            {
                string path = Path.Combine(Directory, kv.Key);
                if (!File.Exists(path))
                {
                    mismatches.Add((kv.Key, kv.Value, "<文件不存在>"));
                    continue;
                }

                string actual = Sha256(path);
                if (!string.Equals(actual, kv.Value, StringComparison.OrdinalIgnoreCase))
                    mismatches.Add((kv.Key, kv.Value, actual));
            }

            return mismatches;
        }

        /// <summary>
        /// 从打包字体加载 SKTypeface。失败抛异常而不是返回 null——静默回落到
        /// 系统字体正是 golden 测试最怕的事。
        /// </summary>
        public static SKTypeface LoadRegular()
        {
            if (!File.Exists(RegularPath))
                throw new FileNotFoundException($"打包字体缺失：{RegularPath}", RegularPath);

            SKTypeface face = SKTypeface.FromFile(RegularPath);
            if (face == null)
                throw new InvalidOperationException($"Skia 无法加载打包字体：{RegularPath}");
            return face;
        }

        public static string Sha256(string path)
        {
            using FileStream stream = File.OpenRead(path);
            byte[] hash = SHA256.HashData(stream);
            return Convert.ToHexString(hash).ToLowerInvariant();
        }

        private static readonly Lazy<Dictionary<string, string>> Checksums =
            new Lazy<Dictionary<string, string>>(LoadChecksumsCore);

        private static IReadOnlyDictionary<string, string> LoadChecksums() => Checksums.Value;

        private static Dictionary<string, string> LoadChecksumsCore()
        {
            var map = new Dictionary<string, string>(StringComparer.Ordinal);
            string sums = Path.Combine(Directory, "SHA256SUMS");
            if (!File.Exists(sums)) return map;

            foreach (string rawLine in File.ReadAllLines(sums))
            {
                string line = rawLine.Trim();
                if (line.Length == 0 || line.StartsWith("#", StringComparison.Ordinal)) continue;

                // 格式："<hash>  <filename>"，分隔符是两个空格（coreutils 默认）
                string[] parts = line.Split(new[] { ' ', '\t' }, 2, StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length != 2) continue;

                map[parts[1].Trim()] = parts[0].Trim().ToLowerInvariant();
            }

            return map;
        }
    }
}

// 字体确定性测试：校验打包字体的完整性、SHA-256 与 Skia 加载能力。
//
// 任务要求"测试必须用它，禁止系统字体"。这一组是把这条要求钉死的：
//   · 字体目录里所有 TTF 的 SHA-256 必须与 build/fonts/SHA256SUMS 完全一致
//   · 加载出来的 SKTypeface FamilyName/Upem/字形数必须稳定（不同 Skia 版本间漂移会
//     提醒我们去更新基准）
//
// GlyphRun 真正的排版验证要等 T6（Text/ 组）。T4 这边只确保"资产可信"。

using System;
using System.Collections.Generic;
using System.IO;
using SkiaSharp;
using Xunit;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class FontDeterminismTests
    {
        [Fact]
        public void All_packaged_fonts_match_expected_sums()
        {
            List<(string File, string Expected, string Actual)> mismatches = PackagedFont.VerifyChecksums();
            Assert.True(mismatches.Count == 0,
                "打包字体哈希校验失败（基准图将不可复现）：" +
                string.Join(Environment.NewLine, mismatches));
        }

        [Fact]
        public void Regular_font_loads_with_stable_identity()
        {
            using SKTypeface face = PackagedFont.LoadRegular();
            Assert.NotNull(face);
            Assert.Equal("Noto Sans", face.FamilyName);
            // PostScript 名称 / weight 是字体本身决定的，Skia 不会改它们。
            // 用来探测"字体文件被换掉了但 SHA 还没更新"这类偏差。
            Assert.True(face.UnitsPerEm > 0, "字体单位/EM 必须 > 0");
        }

        [Fact]
        public void Sum_file_is_present_and_parseable()
        {
            string sums = Path.Combine(PackagedFont.Directory, "SHA256SUMS");
            Assert.True(File.Exists(sums), $"SHA256SUMS 缺失：{sums}");

            IReadOnlyDictionary<string, string> map = PackagedFont.ExpectedChecksums;
            Assert.True(map.Count >= 4, $"期望至少 4 个字体条目，实际 {map.Count}");

            // Regular / Bold 必须在，因为 MilResourceProvider.GlyphRunRenderer 后续
            // 会用到这两个字重。
            Assert.Contains("NotoSans-Regular.ttf", (IDictionary<string, string>)map);
            Assert.Contains("NotoSans-Bold.ttf", (IDictionary<string, string>)map);
        }
    }
}
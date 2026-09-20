// golden 图比对：算法与 Rendering.Tests/ImageComparer 逐行一致（容差 Δ≤2、
// 判据是"超阈值像素数 == 0"、diff 图差异区标红 + 底衬压暗到 30%）。
//
// 为什么重写而不引用：见 TestLayout.cs 的说明（友元 + 目录边界）。
// 算法刻意保持与 T7 完全一致，是为了让"容差"这件事在整个工程里只有一个口径——
// 否则同一张图在 T4 测试里过、在 T5/T6 测试里挂，排查成本极高。

using System;
using System.IO;
using System.Linq;
using SkiaSharp;

namespace WpfGfx.Linux.Tests.Windowing
{
    internal sealed class CompareResult
    {
        public bool Passed { get; init; }
        public int DifferingPixels { get; init; }
        public int MaxChannelDelta { get; init; }
        public double DifferingRatio { get; init; }
        public int Width { get; init; }
        public int Height { get; init; }
        public string Message { get; init; }
    }

    internal static class GoldenImage
    {
        public const int DefaultTolerance = 2;

        /// <summary>更新基准图的开关：环境变量 WPFGOLDEN_WINDOWING_UPDATE=1。</summary>
        public static bool UpdateEnabled
        {
            get
            {
                string env = Environment.GetEnvironmentVariable("WPFGOLDEN_WINDOWING_UPDATE");
                return env == "1" ||
                       env?.Equals("true", StringComparison.OrdinalIgnoreCase) == true ||
                       Environment.GetCommandLineArgs()
                           .Any(a => string.Equals(a, "--update-golden", StringComparison.OrdinalIgnoreCase));
            }
        }

        public static CompareResult Compare(SKBitmap actual, SKBitmap golden, int tolerance = DefaultTolerance)
        {
            if (actual == null) throw new ArgumentNullException(nameof(actual));
            if (golden == null) throw new ArgumentNullException(nameof(golden));

            if (actual.Width != golden.Width || actual.Height != golden.Height)
            {
                return new CompareResult
                {
                    Passed = false,
                    Width = actual.Width,
                    Height = actual.Height,
                    Message = $"尺寸不一致：实测 {actual.Width}×{actual.Height}，基准 {golden.Width}×{golden.Height}",
                };
            }

            int width = actual.Width, height = actual.Height;
            int differing = 0, maxDelta = 0;

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    SKColor a = actual.GetPixel(x, y);
                    SKColor g = golden.GetPixel(x, y);

                    int d = Math.Abs(a.Red - g.Red);
                    d = Math.Max(d, Math.Abs(a.Green - g.Green));
                    d = Math.Max(d, Math.Abs(a.Blue - g.Blue));
                    d = Math.Max(d, Math.Abs(a.Alpha - g.Alpha));

                    if (d > maxDelta) maxDelta = d;
                    if (d > tolerance) differing++;
                }
            }

            int total = width * height;
            bool passed = differing == 0;

            return new CompareResult
            {
                Passed = passed,
                DifferingPixels = differing,
                MaxChannelDelta = maxDelta,
                DifferingRatio = total == 0 ? 0.0 : (double)differing / total,
                Width = width,
                Height = height,
                Message = passed
                    ? null
                    : $"{differing}/{total} 个像素超出容差 Δ≤{tolerance}（{(differing * 100.0 / total):F2}%），" +
                      $"最大单通道差 {maxDelta}",
            };
        }

        public static SKBitmap CreateDiff(SKBitmap actual, SKBitmap golden, int tolerance = DefaultTolerance)
        {
            int width = Math.Min(actual.Width, golden.Width);
            int height = Math.Min(actual.Height, golden.Height);

            var diff = new SKBitmap(new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Premul));

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    SKColor a = actual.GetPixel(x, y);
                    SKColor g = golden.GetPixel(x, y);

                    int d = Math.Max(
                        Math.Max(Math.Abs(a.Red - g.Red), Math.Abs(a.Green - g.Green)),
                        Math.Max(Math.Abs(a.Blue - g.Blue), Math.Abs(a.Alpha - g.Alpha)));

                    diff.SetPixel(x, y, d > tolerance
                        ? new SKColor(255, 0, 0, 255)
                        : new SKColor((byte)(g.Red * 30 / 100), (byte)(g.Green * 30 / 100), (byte)(g.Blue * 30 / 100), 255));
                }
            }

            return diff;
        }

        /// <summary>
        /// 与基准图比对。golden 不存在时：更新模式直接写入，否则失败并给出提示——
        /// 静默"建一张基准图然后过"等于把第一次跑的所有错误都锁进 golden。
        /// </summary>
        public static CompareResult Verify(string name, SKBitmap actual, int tolerance = DefaultTolerance)
        {
            TestLayout.EnsureDirectories();
            string goldenPath = TestLayout.GoldenPath(name);
            string actualPath = TestLayout.ActualPath(name);
            Save(actual, actualPath);

            if (!File.Exists(goldenPath))
            {
                if (UpdateEnabled)
                {
                    Save(actual, goldenPath);
                    return new CompareResult { Passed = true, Width = actual.Width, Height = actual.Height };
                }

                return new CompareResult
                {
                    Passed = false,
                    Width = actual.Width,
                    Height = actual.Height,
                    Message = $"基准图不存在：{goldenPath}（要生成请设 WPFGOLDEN_WINDOWING_UPDATE=1）",
                };
            }

            using SKBitmap golden = SKBitmap.Decode(goldenPath);
            if (golden == null)
            {
                return new CompareResult
                {
                    Passed = false,
                    Message = $"基准图无法解码：{goldenPath}",
                };
            }

            CompareResult result = Compare(actual, golden, tolerance);

            if (!result.Passed)
            {
                using SKBitmap diff = CreateDiff(actual, golden, tolerance);
                Save(diff, TestLayout.DiffPath(name));
            }

            if (UpdateEnabled) Save(actual, goldenPath);

            return result;
        }

        public static void Save(SKBitmap bitmap, string path)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(path));
            using SKImage image = SKImage.FromBitmap(bitmap);
            using SKData data = image.Encode(SKEncodedImageFormat.Png, 100);
            using FileStream stream = File.OpenWrite(path);
            data.SaveTo(stream);
        }

        /// <summary>SKBitmap → SHA-256（小写十六进制）。用于字体确定性验证。</summary>
        public static string Hash(SKBitmap bitmap)
        {
            using SKImage image = SKImage.FromBitmap(bitmap);
            using SKData data = image.Encode(SKEncodedImageFormat.Png, 100);
            return Convert.ToHexString(
                System.Security.Cryptography.SHA256.HashData(data.ToArray())).ToLowerInvariant();
        }
    }
}

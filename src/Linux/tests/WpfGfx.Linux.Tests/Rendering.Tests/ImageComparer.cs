// 逐像素比对 + diff 图生成。
//
// 【容差为什么是 Δ≤2】
//   handoff §6 L3 定的默认值。它不是"允许画错两格"，而是给 Skia 在同一台机器上
//   两次渲染之间的舍入抖动留余量——pytest 式的"完全相同"在浮点光栅化上不现实。
//   真正的画错会体现在"超阈值像素数"上，所以判据是**数量**而不是单点最大值：
//   只要有任何一个像素超阈值，整条用例就失败并输出 diff。
//
// 【为什么用 max 通道差而不是平均】
//   纯色位移类错误（少画了一个矩形）在平均差上会被大面积背景稀释；
//   取 RGBA 四通道的最大差，任何一个通道跑偏就抓得住。

using System;
using SkiaSharp;

namespace WpfGfx.Linux.Tests.Rendering
{
    internal sealed class CompareResult
    {
        public bool Passed { get; init; }

        /// <summary>超出容差的像素数。0 表示通过。</summary>
        public int DifferingPixels { get; init; }

        /// <summary>全图最大的单通道差值（诊断用，成功时也可能非 0）。</summary>
        public int MaxChannelDelta { get; init; }

        /// <summary>超阈值像素占比（0..1）。</summary>
        public double DifferingRatio { get; init; }

        public int Width { get; init; }
        public int Height { get; init; }

        /// <summary>失败信息。通过时为 null。</summary>
        public string Message { get; init; }
    }

    internal static class ImageComparer
    {
        /// <summary>默认容差：单通道最大差值 ≤2 视为一致。</summary>
        public const int DefaultTolerance = 2;

        /// <summary>尺寸不同直接失败——这不是渲染差异，是场景定义变了。</summary>
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

                    int d = ChannelDelta(a.Red, g.Red);
                    d = Math.Max(d, ChannelDelta(a.Green, g.Green));
                    d = Math.Max(d, ChannelDelta(a.Blue, g.Blue));
                    d = Math.Max(d, ChannelDelta(a.Alpha, g.Alpha));

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

        /// <summary>
        /// 生成 diff 图：差异像素标红（255,0,0），其余位置放压暗后的基准图当底衬，
        /// 这样一眼能看出"差在哪儿"而不只是"差了多少"。
        /// </summary>
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
                        Math.Max(ChannelDelta(a.Red, g.Red), ChannelDelta(a.Green, g.Green)),
                        Math.Max(ChannelDelta(a.Blue, g.Blue), ChannelDelta(a.Alpha, g.Alpha)));

                    if (d > tolerance)
                    {
                        diff.SetPixel(x, y, new SKColor(255, 0, 0, 255));
                    }
                    else
                    {
                        // 底衬压暗到 30%，避免和红色差异区抢注意力。
                        diff.SetPixel(x, y, new SKColor(
                            (byte)(g.Red * 30 / 100),
                            (byte)(g.Green * 30 / 100),
                            (byte)(g.Blue * 30 / 100),
                            255));
                    }
                }
            }

            return diff;
        }

        private static int ChannelDelta(byte a, byte b) => Math.Abs(a - b);
    }
}

// 离屏渲染驱动器。
//
// 【为什么不需要 X server】
//   SKSurface.Create(SKImageInfo) 走的是 Skia 的 **CPU 光栅后端**，像素落在托管
//   内存里，全程不碰窗口系统。对应 handoff §6 的 L3 层（有渲染、无窗口），
//   这也是 CI 容器里唯一稳定可复现的一层。
//
// 【确定性在这里钉死】
//   1. DPI 恒等于 RenderContext.FixedDpi(96) —— 凡传别的 DPI 进来一律拒绝，
//      避免有人"顺手测一下 120 DPI"污染基准图
//   2. 像素格式写死 Rgba8888 + Premul + sRGB，不依赖 Skia 的平台默认
//   3. 画布矩阵渲染前 ResetMatrix，杜绝上一帧残留
//   4. Antialias 由调用方显式给，写进黄金图文件名语义里（见 GoldenRenderTests）

using System;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Rendering;

namespace WpfGfx.Linux.Tests.Rendering
{
    internal sealed class RenderOutput
    {
        public SKBitmap Bitmap { get; init; }

        /// <summary>本次渲染的诊断计数（未画出 / 降级 的指令）。</summary>
        public RenderDiagnostics Diagnostics { get; init; }

        /// <summary>画布在渲染结束时的 SaveCount。</summary>
        public int FinalSaveCount { get; init; }

        /// <summary>
        /// 渲染开始前的 SaveCount。
        /// ⚠️ Skia 的画布**初始 SaveCount 就是 1**（有一层代表默认状态的存档），
        /// 不是 0。判断 Push/Pop 是否配平必须拿 Final 和这个比，不能和 0 比——
        /// 这一点踩过一次：初版断言 `Final == 0`，12 条用例全红，实际代码是配平的。
        /// </summary>
        public int InitialSaveCount { get; init; }

        /// <summary>Push/Pop 配平判据。</summary>
        public bool IsStackBalanced => FinalSaveCount == InitialSaveCount;
    }

    internal static class RenderHarness
    {
        public const int DefaultWidth = 240;
        public const int DefaultHeight = 180;

        /// <summary>离屏渲染一棵视觉树，返回内存位图。</summary>
        public static RenderOutput Render(
            MilVisual root,
            MilResourceProvider provider,
            int width = DefaultWidth,
            int height = DefaultHeight,
            bool antialias = true)
        {
            if (provider == null) throw new ArgumentNullException(nameof(provider));

            var ctx = new RenderContext
            {
                Width = width,
                Height = height,
                Dpi = RenderContext.FixedDpi,     // 96，golden 可复现的前提
                ClearColor = SKColors.White,
                FontDirectory = PackagedFont.Directory,
                Antialias = antialias,
            };

            if (Math.Abs(ctx.Dpi - RenderContext.FixedDpi) > 1e-4f)
                throw new InvalidOperationException($"DPI 必须固定为 {RenderContext.FixedDpi}，收到 {ctx.Dpi}");

            SKImageInfo info = new SKImageInfo(
                width, height, SKColorType.Rgba8888, SKAlphaType.Premul, SKColorSpace.CreateSrgb());

            using SKSurface surface = SKSurface.Create(info);
            if (surface == null)
                throw new InvalidOperationException("SKSurface.Create 失败：Skia CPU 后端不可用");

            SKCanvas canvas = surface.Canvas;
            canvas.ResetMatrix();
            int initialSaveCount = canvas.SaveCount;

            var backend = new SkiaRenderBackend(provider);
            backend.RenderVisualTree(root, canvas, ctx);

            canvas.Flush();

            using SKImage image = surface.Snapshot();
            SKBitmap bitmap = SKBitmap.FromImage(image);
            if (bitmap == null)
                throw new InvalidOperationException("无法从离屏表面读回像素");

            return new RenderOutput
            {
                Bitmap = bitmap,
                Diagnostics = backend.Diagnostics,
                InitialSaveCount = initialSaveCount,
                FinalSaveCount = canvas.SaveCount,
            };
        }

        /// <summary>一次性渲染并取位图（不需要诊断信息时用）。</summary>
        public static SKBitmap RenderBitmap(
            MilVisual root, MilResourceProvider provider,
            int width = DefaultWidth, int height = DefaultHeight, bool antialias = true)
            => Render(root, provider, width, height, antialias).Bitmap;

        public static void SavePng(SKBitmap bitmap, string path)
        {
            string dir = System.IO.Path.GetDirectoryName(path);
            if (!string.IsNullOrEmpty(dir)) System.IO.Directory.CreateDirectory(dir);

            using SKData data = bitmap.Encode(SKEncodedImageFormat.Png, 100);
            using System.IO.FileStream fs = System.IO.File.Open(path, System.IO.FileMode.Create);
            data.SaveTo(fs);
        }

        public static SKBitmap LoadPng(string path)
        {
            SKBitmap bitmap = SKBitmap.Decode(path);
            if (bitmap == null) throw new InvalidOperationException($"PNG 解码失败：{path}");

            // 统一到 Rgba8888/Premul，避免基准图与实测图因编码差异出现假差异
            if (bitmap.ColorType == SKColorType.Rgba8888 && bitmap.AlphaType == SKAlphaType.Premul)
                return bitmap;

            var normalized = new SKBitmap(new SKImageInfo(
                bitmap.Width, bitmap.Height, SKColorType.Rgba8888, SKAlphaType.Premul));
            using (var canvas = new SKCanvas(normalized))
            {
                canvas.Clear(SKColors.Transparent);
                canvas.DrawBitmap(bitmap, 0, 0);
            }

            bitmap.Dispose();
            return normalized;
        }
    }
}

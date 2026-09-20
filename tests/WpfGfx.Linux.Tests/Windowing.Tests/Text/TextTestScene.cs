// 文本 golden 用例共用的离屏画布。
//
// 与 Rendering.Tests/RenderHarness 的关系：那边是 T4 视觉树场景的封装，这里是
// T6 文本的。参数刻意对齐 handoff §6「确定性保证」：DPI 固定 96、画布尺寸写死、
// 背景写死、AA 由用例显式给（不靠默认值，避免"生成 golden 时和比对时不一样"）。

using System;
using SkiaSharp;

namespace WpfGfx.Linux.Tests.Windowing
{
    /// <summary>一次离屏渲染的产物。Dispose 前必须把要用到的图取走。</summary>
    internal sealed class TextFrame : IDisposable
    {
        private readonly SKSurface _surface;

        public TextFrame(int width, int height, bool antialias, SKColor background)
        {
            Width = width;
            Height = height;

            var info = new SKImageInfo(width, height, SKColorType.Rgba8888, SKAlphaType.Premul);
            _surface = SKSurface.Create(info);
            if (_surface == null) throw new InvalidOperationException("SKSurface.Create 失败（CPU 后端不可用）");

            Canvas = _surface.Canvas;
            Antialias = antialias;
            Background = background;

            Canvas.Clear(background);
        }

        public int Width { get; }
        public int Height { get; }
        public SKCanvas Canvas { get; }
        public bool Antialias { get; }
        public SKColor Background { get; }

        public SKBitmap ToBitmap()
        {
            _surface.Flush();
            using SKImage image = _surface.Snapshot();
            return SKBitmap.FromImage(image);
        }

        public void Dispose() => _surface.Dispose();
    }

    internal static class TextScene
    {
        /// <summary>标准画布：460×90，白底，开启抗锯齿。</summary>
        public const int StandardWidth = 460;
        public const int StandardHeight = 90;

        public static TextFrame Standard() =>
            new TextFrame(StandardWidth, StandardHeight, antialias: true,
                background: new SKColor(255, 255, 255, 255));

        /// <summary>标准测试字体：Noto Sans（打包字体，build/fonts）。</summary>
        public static string Family => "Noto Sans";

        /// <summary>标准绘制笔：黑色实心、AA 开关与画布一致。</summary>
        public static SKPaint Ink(bool antialias) => new SKPaint
        {
            Color = new SKColor(0, 0, 0, 255),
            IsAntialias = antialias,
            Style = SKPaintStyle.Fill,
        };
    }
}

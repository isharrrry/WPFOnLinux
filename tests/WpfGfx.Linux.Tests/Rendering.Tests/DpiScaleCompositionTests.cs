// `deviceBase` 链（DPI 缩放 × 画布矩阵）的牙（T2b，2026-09-13）。
//
// 【为什么需要单独一个文件】§9 扫荡里 #4 站点 `SkiaRenderBackend.cs:193`
//   （`deviceBase = Concat(deviceBase, Scale(dpiScale))`）判为"经核为正确，但**分支进不去**"：
//   `RenderHarness.Render` 在 `Dpi != FixedDpi(96)` 时**显式 throw**（`RenderHarness.cs:62-63`），
//   所以**走既有装置永远进不了这条分支** —— "分支进不去"本身就是一条事实，不能当成"已覆盖"。
//
// 【本文件给出的离线入口】绕过 `RenderHarness`，自己造 surface + `RenderContext { Dpi = 192 }`
//   （`dpiScale = 192/96 = 2`）**并且**把画布预置一个非单位矩阵（`Translate(100,0)` = 窗口层放的变换）。
//   这样 `deviceBase = W · S` 里两个因子都非平凡，**顺序错就会显形**：
//     正确链：局部 → world → S(DPI) → W(画布)   ⇒ 设备 x = 2·(x+21) + 100
//     若把 S 与 W 写反（`Concat(S, W)`）：设备 x = 2·(x+21+100)
//     若把 `:280` 写反（`Concat(world, deviceBase)`）：设备 x = 2x + 100 + 21
//   三者对 `Offset(21)` 的墨迹起点分别是 **142 / 242 / 121**，彼此相差几十像素 ⇒ 可断言。
//
// 【谁能变红】把 `:193` 改成 `Concat(Scale(dpiScale), deviceBase)`、或把 `:280` 改回
//   `Concat(world, deviceBase)`，本牙立刻红（差 21~100 px）。

using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class DpiScaleCompositionTests
    {
        public DpiScaleCompositionTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        private const int CanvasShift = 100;   // 画布预置的窗口层变换（非单位矩阵！）
        private const float VisualOffsetX = 21f;
        private const int Dpi = 192;           // FixedDpi = 96 ⇒ dpiScale = 2（S 非平凡）

        /// <summary>
        /// `deviceBase = 画布矩阵 · DPI 缩放` 与 `CTM = deviceBase · world` 的**顺序**：
        /// 2× DPI + 画布平移 100 + 视觉偏移 21 ⇒ 墨迹必须起于 **142**（= 2·21 + 100）。
        /// </summary>
        [Fact]
        public void dpi_scale_and_canvas_matrix_compose_in_wpf_order()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0, 0, 0);

            MilVisual v = scene.Visual();
            v.Offset = new SKPoint(VisualOffsetX, 5f);
            v.Transform = SKMatrix.Identity;
            v.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(0, 0, 10, 10),
                Brush = new MilResourceHandle((uint)brush),
            }));

            const int w = 300, h = 60;
            var info = new SKImageInfo(w, h, SKColorType.Rgba8888, SKAlphaType.Premul, SKColorSpace.CreateSrgb());
            using SKSurface surface = SKSurface.Create(info);
            SKCanvas canvas = surface.Canvas;
            canvas.Clear(SKColors.White);
            canvas.Translate(CanvasShift, 0f);      // ← 窗口层放的变换；正是让 `:193` 顺序可判别的因子

            var ctx = new RenderContext
            {
                Width = w,
                Height = h,
                Dpi = Dpi,                          // ← 绕过 RenderHarness 的 96 限制，进入 `:193` 分支
                ClearColor = SKColors.White,
                FontDirectory = PackagedFont.Directory,
                Antialias = false,
            };
            var backend = new SkiaRenderBackend(scene.Provider);
            backend.RenderVisualTree(v, canvas, ctx);
            canvas.Flush();

            using SKImage img = surface.Snapshot();
            using SKBitmap bmp = SKBitmap.FromImage(img);

            int left = int.MaxValue, right = int.MinValue;
            for (int y = 0; y < bmp.Height; y++)
                for (int x = 0; x < bmp.Width; x++)
                {
                    SKColor c = bmp.GetPixel(x, y);
                    if (c.Red < 128 && c.Green < 128 && c.Blue < 128)
                    {
                        if (x < left) left = x;
                        if (x > right) right = x;
                    }
                }
            Assert.True(left != int.MaxValue, "一个暗像素都没有：装置本身没画出东西");
            Output.WriteLine($"  Dpi={Dpi}(×2) + 画布平移 {CanvasShift} + Offset({VisualOffsetX}) ⇒ 墨迹 x∈[{left},{right}]");
            Output.WriteLine("  正确 = [142,162]；:193 写反 = [242,262]；:280 写反 = [121,141]");

            Assert.True(left >= 141 && left <= 143,
                $"墨迹起点 {left}，应为 142 = 2×21 + 100（局部→world→DPI→画布）。" +
                "142 之外的两个常见错法给出 242（`:193` 的 S 与 W 写反）或 121（`:280` 把 deviceBase 先作用）。");
            Assert.True(right >= 161 && right <= 163, $"墨迹终点 {right}，应为 162。");
        }
    }
}

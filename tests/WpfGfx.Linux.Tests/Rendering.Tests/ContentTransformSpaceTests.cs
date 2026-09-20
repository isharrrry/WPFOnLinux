// 「内容级变换必须在**局部（DIP）空间**作用，而不是被作用在 CTM 之后」—— 牙（T2b）。
//
// 【它挡什么缺陷】
//   真机（新桥 `6d6f5fb08808fede`）RTL 读数的形态是：
//     同一视觉：本节点Transform=[-1.00,…,65.3]  **累积world=[-1.04,…,89.8]**
//     同一行字形：CTM=[**+1.0417**,…,**-24.594**]
//   ⇒ 追踪到的 `world` 与画布实际矩阵**分叉**了：画布上多被作用了一个 `M11=-1` 的内容级变换。
//   数值闭合：`-24.594 = 65.2559 + (-1)×89.851` ⇒ 该变换的平移是 **DIP 值 65.2559 未乘 DPI**，
//   即它被作用在 `world`（含 DPI 缩放）**之后**。
//
// 【根因】`SKMatrix.Concat(a,b)` 实测语义 = **b 先作用**（见 `ParityTests.cs:441-443`：
//   `Concat(R30,T30).TransX = 10.98`）。于是 `SkiaRenderBackend.Execute` 里
//   `SetMatrix(Concat(m, canvas.TotalMatrix))` = `m · CTM` ⇒ **m 作用在 CTM 之后**，
//   而 WPF/MIL 的 RenderData 变换（`MilPushTransform` / `DrawingGroup.Transform`）是
//   **内容坐标系（局部 DIP）**里的变换 ⇒ 必须写作 `Concat(CTM, m)`（= m 先作用，再 CTM）。
//
// 【为什么既有用例全绿还是漏过去了】
//   ① 所有既有渲染用例的 `deviceBase` 都是**单位阵**（`RenderHarness` 强制 `Dpi = 96` 且
//      `canvas.ResetMatrix()`）⇒ "DIP 平移没被 DPI 乘"这一半症状**看不见**；
//   ② 另一半（顺序）只在**同时**有"非平凡 world"和"内容级变换"时才显形，而既有 golden
//      `transform_nested` 恰好两者都有 —— 它把**当时的实现结果**固化成了基准，
//      于是"实现与语义一致不一致"这条**没有任何用例在问**。
//   ⇒ 下面两条断言问的就是这一条：内容级变换必须**先于** world 作用。

using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class ContentTransformSpaceTests
    {
        public ContentTransformSpaceTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        private const float RowWidth = 65.255859375f;   // 真机：纯希伯来那一行的行宽

        private static MilDrawInstruction Rect(float x, float y, float w, float h, DUCE.ResourceHandle brush) =>
            new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(x, y, x + w, y + h),
                Brush = new MilResourceHandle((uint)brush),
            };

        private static MilDrawInstruction Push(DUCE.ResourceHandle transform) =>
            new MilDrawInstruction
            {
                Command = MilDrawCommand.MilPushTransform,
                Geometry = new MilResourceHandle((uint)transform),
            };

        private static MilDrawInstruction Pop() =>
            new MilDrawInstruction { Command = MilDrawCommand.MilPop };

        /// <summary>墨迹的水平范围（第一个/最后一个暗列），没有墨迹返回 null。</summary>
        private static (int Left, int Right)? InkSpan(SKBitmap bmp, int y0 = 0, int y1 = -1)
        {
            if (y1 < 0) y1 = bmp.Height;
            int left = int.MaxValue, right = int.MinValue;
            for (int y = y0; y < y1; y++)
                for (int x = 0; x < bmp.Width; x++)
                {
                    SKColor c = bmp.GetPixel(x, y);
                    if (c.Red < 128 && c.Green < 128 && c.Blue < 128)
                    {
                        if (x < left) left = x;
                        if (x > right) right = x;
                    }
                }
            return left == int.MaxValue ? ((int, int)?)null : (left, right);
        }

        /// <summary>
        /// ① 顺序：`MilPushTransform` 的 `Scale(2)` 必须作用在**局部**坐标上 ——
        ///    先缩放（0..10 → 0..20）再走 world 的 `Offset(30)` ⇒ 墨迹 `x∈[30,50]`。
        ///    若被作用在 CTM 之后（当前实现），则先平移 30 再整体×2 ⇒ 墨迹 `x∈[60,80]`。
        /// </summary>
        [Fact]
        public void push_transform_applies_in_local_space_before_world()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0, 0, 0);
            DUCE.ResourceHandle scale2 = scene.Scale(2.0, 2.0);

            MilVisual v = scene.Visual();
            v.Offset = new SKPoint(30f, 0f);            // world 的平移（局部 → 画布）
            v.Transform = SKMatrix.Identity;
            v.Content = scene.RenderData(d =>
            {
                d.Add(Push(scale2));
                d.Add(Rect(0, 0, 10, 10, brush));
                d.Add(Pop());
            });

            using SKBitmap bmp = RenderHarness.RenderBitmap(v, scene.Provider, 120, 40, antialias: false);
            (int Left, int Right)? ink = InkSpan(bmp);
            Assert.NotNull(ink);
            Output.WriteLine($"  墨迹 x∈[{ink.Value.Left},{ink.Value.Right}]（局部空间应为 [30,50]；设备空间会是 [60,80]）");

            Assert.True(ink.Value.Left >= 29 && ink.Value.Left <= 31,
                $"内容级变换被作用在 CTM 之后（设备空间）：墨迹起点 {ink.Value.Left}，局部空间语义应为 30。" +
                "这正是真机 RTL 那一格 `CTM` 与 `累积world` 分叉的形态。");
            Assert.True(ink.Value.Right >= 49 && ink.Value.Right <= 51,
                $"墨迹终点 {ink.Value.Right}，局部空间语义应为 50。");
        }

        /// <summary>
        /// ② 真机同形：**父视觉给 21 的左边距**，子视觉自身带镜像（`Transform`），内容里再有一个
        ///    同一个镜像（`PushTransform`）。正确的局部语义下两个镜像相消、墨迹落在 `x∈[21,86]`
        ///    （= 判据 `[22,88]` 那一族，也就是 LTR 的位置）；当前实现会把它推到 `x∈[-21,44]`。
        ///
        ///    ⚠ 拓扑为什么必须是"父偏移 + 子镜像"而不是"子偏移 21 + 子镜像"：实测 `world` 的语义是
        ///    **Offset 先作用、本节点 Transform 后作用**（`Concat(a,b)` = b 先作用，由牙① 独立坐实）。
        ///    真机读数 `累积world.tx = 89.8 ≈ (65.2559 + 21) × 1.0417` 也只与"21 在这一级之后"相容。
        /// </summary>
        [Fact]
        public void rtl_shaped_double_mirror_lands_in_the_expected_band()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0, 0, 0);

            // 行宽 65.2559 的镜像（真机 `SetTransform visual=0x44 hTransform=0x21` 的形态）
            DUCE.ResourceHandle mirror = scene.Matrix(-1.0, 0.0, 0.0, 1.0, RowWidth, 0.0);
            SKMatrix mirrorM = TransformResolver.FromMil(new MilMatrix3x2D
            {
                S_11 = -1.0, S_12 = 0.0, S_21 = 0.0, S_22 = 1.0, DX = RowWidth, DY = 0.0,
            });

            MilVisual child = scene.Visual();
            child.Transform = mirrorM;                  // 视觉自身的镜像
            child.Content = scene.RenderData(d =>
            {
                d.Add(Push(mirror));                    // 内容级同一个镜像
                d.Add(Rect(0, 0, RowWidth, 10, brush)); // 行宽那么宽的"整行"
                d.Add(Pop());
            });

            MilVisual root = scene.Visual();
            root.Offset = new SKPoint(21f, 4f);         // 真机 RTL/LTR 共同的左边距（父级）
            root.Children.Add(child);

            using SKBitmap bmp = RenderHarness.RenderBitmap(root, scene.Provider, 140, 40, antialias: false);
            (int Left, int Right)? ink = InkSpan(bmp);
            Assert.NotNull(ink);
            Output.WriteLine($"  墨迹 x∈[{ink.Value.Left},{ink.Value.Right}]（期望 [21,87]；错误顺序会掉到负半轴）");

            Assert.True(ink.Value.Left >= 20 && ink.Value.Left <= 22,
                $"RTL 墨迹左缘 {ink.Value.Left}，期望 ≈21：内容级镜像被作用在 CTM 之后，位置整体偏了约 46 设备像素" +
                "（真机读数 `CTM.tx=-24.594` vs `累积world.tx=+89.8` 就是这个形态）。");
            Assert.True(ink.Value.Right >= 85 && ink.Value.Right <= 88,
                $"RTL 墨迹右缘 {ink.Value.Right}，期望 ≈86。");
        }
    }
}

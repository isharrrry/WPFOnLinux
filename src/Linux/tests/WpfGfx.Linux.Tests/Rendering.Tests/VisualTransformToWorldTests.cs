// 「视觉节点的镜像变换必须活到绘制矩阵里」——RTL 水平偏移那一项的**牙**（T2b）。
//
// 【它挡什么缺陷】
//   真机读数：PC 明确把镜像交给了 MIL（`SetTransform(visual=0x44, hTransform=0x21)`，
//   `MilTransformGroup` → `M11=-1 DX=65.2559`，M7b 探针实跑），而 census 在字形绘制点打出的
//   `CTM=[1.0417,…]` **m11 是正的** ⇒ 镜像没进 `world`。这一族（**变换在某一跳被静默丢掉、
//   下游只看到单位阵**）不会有编译错误、不会有异常、也不会有"未画出"计数——它只是**画歪**。
//   所以必须有一条**能变红**的离线断言把它钉住。
//
// 【三层牙，各挡一跳】
//   ① 投影级：句柄 → `MilVisual.Transform`（`VisualProjection.cs:38`）。丢了 ⇒ `M11` 不为负。
//   ② 绘制级端到端：`MilVisual.Transform` → 真正的墨迹位置（`SkiaRenderBackend.cs:204-206`
//      的 `world`）。丢了 ⇒ 墨迹留在未镜像的一侧。**② 是真正端到端的那颗牙。**
//   ③ 仪表自证：`TransformProvenance` 对 `TransformGroup` 必须报出**解析后**的矩阵——
//      只报"子数=1"是不够的（`Resolve` 对查不到的子树**静默返回单位阵**，
//      子数照样是 1）。没有 ③，①② 红了也读不出是哪一跳丢的。
//
// 【先红后绿怎么验】把 `SkiaRenderBackend.cs:204-206` 里的 `v.Transform` 换成 `SKMatrix.Identity`
//   （或把 `VisualProjection.cs:38` 改成 `SKMatrix.Identity`），② / ① 必须变红；
//   把 `TransformProvenance.DescribeResolved` 的 `解析=` 去掉，③ 必须变红。
//   本文件所有断言都只依赖**公开语义**（墨迹落在哪一半、矩阵符号），不依赖实现细节。

using System;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class VisualTransformToWorldTests
    {
        public VisualTransformToWorldTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        private const float RowWidth = 65.255859375f;   // 真机读数：纯希伯来那一行的行宽
        private const float LeftEdge = 21.0f;           // 真机读数：LTR 的视觉偏移

        private static MilDrawInstruction Rect(float x, float y, float w, float h, DUCE.ResourceHandle brush) =>
            new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(x, y, x + w, y + h),
                Brush = new MilResourceHandle((uint)brush),
            };

        /// <summary>按真机形态造一个镜像变换句柄：`TransformGroup[Matrix(M11=-1, DX=行宽)]`。</summary>
        private static DUCE.ResourceHandle MirrorGroup(TestScene scene)
        {
            DUCE.ResourceHandle mirror = scene.Matrix(-1.0, 0.0, 0.0, 1.0, RowWidth, 0.0);
            return scene.TransformGroup(mirror);
        }

        /// <summary>① 投影级：节点上的镜像句柄必须出现在投影后的 `MilVisual.Transform` 里。</summary>
        [Fact]
        public void projection_keeps_mirror_from_transform_group()
        {
            using var scene = new TestScene();

            var resource = new MilVisualResource();
            DUCE.ResourceHandle visual = scene.Add(resource);
            resource.Visual.Handle = visual;
            resource.Visual.OffsetX = LeftEdge;
            resource.Visual.Transform = MirrorGroup(scene);

            MilVisual projected = VisualProjection.Project(scene.Channel, visual);
            Assert.NotNull(projected);
            Output.WriteLine($"  投影后 Transform=[{projected.Transform.ScaleX},{projected.Transform.SkewY}," +
                             $"{projected.Transform.SkewX},{projected.Transform.ScaleY}," +
                             $"{projected.Transform.TransX},{projected.Transform.TransY}] " +
                             $"Offset=({projected.Offset.X},{projected.Offset.Y})");

            // 镜像与它的平移都必须活着到契约里
            Assert.True(projected.Transform.ScaleX < 0f,
                $"投影丢了镜像：M11={projected.Transform.ScaleX}（应为 -1）。" +
                "这是「变换在投影这一跳被静默丢掉」——没有任何编译错误能挡住它。");
            Assert.Equal(RowWidth, projected.Transform.TransX, 3);
            Assert.Equal(LeftEdge, projected.Offset.X, 3);      // 偏移这条链是好的，别被顺手改坏
        }

        /// <summary>
        /// ② 绘制级端到端：`MilVisual.Transform` 的镜像必须**真的把墨迹翻到另一侧**。
        /// 对照用例同时存在（identity ⇒ 墨迹留在原位）——**没有对照，这条牙分不清
        /// "镜像生效"和"什么都没画"**。
        /// </summary>
        [Fact]
        public void world_applies_visual_transform_so_ink_mirrors()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0, 0, 0);
            DUCE.ResourceHandle geom = scene.RectGeometry(0, 0, 10, 10);

            // 局部方块在 x∈[0,10]；镜像 DX=100 把它翻到 x∈[90,100]
            const float mirrorDx = 100f;

            MilVisual mirrored = scene.Visual();
            mirrored.Offset = new SKPoint(0f, 0f);
            mirrored.Transform = new SKMatrix
            {
                ScaleX = -1f, SkewX = 0f, TransX = mirrorDx,
                SkewY = 0f, ScaleY = 1f, TransY = 0f,
                Persp0 = 0f, Persp1 = 0f, Persp2 = 1f,
            };
            mirrored.Content = scene.RenderData(d => d.Add(Rect(0, 0, 10, 10, brush)));

            MilVisual control = scene.Visual();
            control.Offset = new SKPoint(0f, 0f);
            control.Transform = SKMatrix.Identity;
            control.Content = scene.RenderData(d => d.Add(Rect(0, 0, 10, 10, brush)));

            using SKBitmap mirroredBmp = RenderHarness.RenderBitmap(mirrored, scene.Provider, 100, 20, antialias: false);
            using SKBitmap controlBmp = RenderHarness.RenderBitmap(control, scene.Provider, 100, 20, antialias: false);

            int mirroredLeft = DarkPixels(mirroredBmp, 0, 50);
            int mirroredRight = DarkPixels(mirroredBmp, 50, 100);
            int controlLeft = DarkPixels(controlBmp, 0, 50);
            int controlRight = DarkPixels(controlBmp, 50, 100);
            Output.WriteLine($"  镜像: 左半={mirroredLeft} 右半={mirroredRight}");
            Output.WriteLine($"  对照: 左半={controlLeft} 右半={controlRight}");

            // 对照先立"这台装置量得出左右差别"（否则下面两条可能是假绿）
            Assert.True(controlLeft > 0 && controlRight == 0,
                $"对照用例就不对：局部 x∈[0,10] 未经镜像应只落在左半（左={controlLeft} 右={controlRight}）。");

            Assert.True(mirroredRight > 0,
                $"镜像没进绘制矩阵：右半一个暗像素都没有（左={mirroredLeft} 右={mirroredRight}）。" +
                "`world` 里的 `v.Transform` 被丢掉了 —— 真机上这就是 RTL 文字落在 −24.6 而不是 +21.9 的形态。");
            Assert.Equal(0, mirroredLeft);
            Assert.Equal(controlLeft, mirroredRight);   // 镜像只是翻面，墨迹总量不变
        }

        /// <summary>
        /// ③ 仪表自证：`TransformGroup` 的来源行必须报**解析后**的矩阵，且能分清
        /// "含镜像"与"子句柄查不到 ⇒ 静默单位阵"这两种形态。
        /// </summary>
        [Fact]
        public void provenance_reports_resolved_matrix_for_group()
        {
            TransformProvenance.ForceEnabledForTest(true);
            try
            {
                using var scene = new TestScene();

                DUCE.ResourceHandle good = MirrorGroup(scene);
                string goodLine = TransformProvenance.Describe(scene.Channel, good);
                Output.WriteLine("  正常组: " + goodLine);

                // 悬空子句柄：子数仍是 1，但解析出来的必然是单位阵 —— 只报"子数"读不出这个区别
                DUCE.ResourceHandle dangling = scene.TransformGroup(
                    new DUCE.ResourceHandle(0xDEADBEEFu));
                string danglingLine = TransformProvenance.Describe(scene.Channel, dangling);
                Output.WriteLine("  悬空子: " + danglingLine);

                Assert.Contains("类型=TransformGroup", goodLine);
                Assert.Contains("解析=", goodLine);
                Assert.Contains("**含镜像**", goodLine);              // 解析后 M11 = −1
                Assert.Contains("子数=1", goodLine);                  // 原始值仍在（两读并存）

                Assert.Contains("解析=", danglingLine);
                Assert.Contains("**无信息**", danglingLine);          // 子句柄查不到要显眼
                Assert.DoesNotContain("**含镜像**", danglingLine);    // 且**不许**报成含镜像
            }
            finally { TransformProvenance.ForceEnabledForTest(false); }
        }

        private static int DarkPixels(SKBitmap bmp, int x0, int x1)
        {
            int n = 0;
            for (int y = 0; y < bmp.Height; y++)
                for (int x = x0; x < x1 && x < bmp.Width; x++)
                {
                    SKColor c = bmp.GetPixel(x, y);
                    if (c.Red < 128 && c.Green < 128 && c.Blue < 128) n++;
                }
            return n;
        }
    }
}

// HelloMil 的测试用例。
//
// 覆盖矩阵（showcase 的每个能力都要有**像素级**证据，"不抛异常"不算测过）：
//   1.  Create 场景不抛异常                        —— 资源表 + 视觉树装配的 sanity
//   2.  离屏渲染产出非空位图                        —— 渲染管线本身没崩
//   3.  纯色矩形 / 实线 / 文本（原有三件套）          —— "真渲染"，不只是 clear 出白底
//   4.  字体确定性（同输入渲染两次哈希一致）          —— 打包字体 + 固定 DPI 的金标前提
//   5.  变换链路（嵌套变换落到转过的位置）            —— 任务要求
//   6.  [X11] 端到端：开窗 + 截屏                    —— 任务要求
//   7.  圆角矩形 vs 直角矩形：角上一个白一个红
//   8.  线性渐变：沿对角线单调变色，两端差异 > 100
//   9.  径向渐变：中心亮 / 边缘暗，且左右对称（与线性的方向性形成对照）
//   10. 椭圆：内部绿、边缘描边深色、外部白
//   11. 路径几何（五角星）：中心有墨、凹点下方无墨、包围盒接近方形
//   12. 虚线笔：同长同色同宽，覆盖率递减 + 实线无空档 / 虚线有空档
//   13. 位图源：棋盘格四色逐点对位 + 平滑渐变三点采样
//   14. Blur：模糊块的色斑越出矩形边界，清晰块边缘齐整
//   15. DropShadow：右下红 / 左上蓝，反方向采样点上没有颜色
//   16. 裁剪：裁剪框外一段本该有墨的区域是白的
//   17. 嵌套变换：包围盒因旋转而变高变宽 + 虚线对照轮廓存在
//   18. 12 个标签全部画出
//   19. ImageBrush 画刷填充：NotDrawn 归零 + 采样带内棋盘格四色齐备、无纯白底残留
//
// 为什么只有 6 是 X11：核心证据 1~19 都能在离屏位图上断言；X11 那一道证明
// "Present 出去 + 独立进程 xwd 抓回来"也通。无 X server 的 CI 不会因它变红。

using System;
using System.IO;
using SkiaSharp;
using HelloMil;
using Xunit;

namespace WpfGfx.Linux.Tests.HelloMil
{
    public class HelloMilTests
    {
        private static string FontDir =>
            HelloMilPaths.FontDirectory
                ?? throw new DirectoryNotFoundException("无法定位打包字体目录 build/fonts");

        private static HelloMilScene NewScene()
        {
            HelloMilScene scene = HelloMilScene.Create(FontDir);
            return scene;
        }

        // ==================================================================
        //  离屏测试（不需要 X server）
        // ==================================================================

        [Fact]
        public void Create_DoesNotThrow_WhenFontsArePackaged()
        {
            // 资源表 + 视觉树装配的最小 sanity：
            //   · MilChannel 资源注册不抛
            //   · SkiaTransform 矩阵连乘合法
            //   · TextRenderer 接管 FontSet、MilGlyphRun shaping 不抛
            //   · 位图源登记（0x0c）不抛
            using HelloMilScene scene = NewScene();
            Assert.Equal(800, HelloMilScene.Width);
            Assert.Equal(600, HelloMilScene.Height);
            Assert.Equal(FontDir, scene.FontDirectory);
        }

        [Fact]
        public void Render_Produces_NonEmpty_Bitmap()
        {
            using HelloMilScene scene = NewScene();
            using SKImage image = scene.Render();
            Assert.NotNull(image);
            Assert.Equal(800, image.Width);
            Assert.Equal(600, image.Height);

            using SKBitmap bitmap = SKBitmap.FromImage(image);
            // 不能整张白底（= ClearColor 之外什么也没画）
            Assert.False(X11Pixel.IsBlank(bitmap), "整张图只有 ClearColor 之一，后端没画出任何东西");

            // showcase 有 47 条指令，给个保守下限
            Assert.True(scene.InstructionCount >= 40, $"指令数 {scene.InstructionCount} 偏低");

            // GlyphRun 必须有钩子接上，否则文字不会出现在画面上
            Assert.False(scene.GlyphRunSkipped, "MilDrawGlyphRun 没人接，文本没画出来");
        }

        [Fact]
        public void Render_Contains_SolidRed_SolidLine_And_DarkText_Pixels()
        {
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            // 纯色矩形：覆盖率 = 像素数 / 矩形面积 应 > 70%
            int red = X11Pixel.CountNearIn(bitmap, HelloMilScene.SolidRect, HelloMilScene.RedFill, 24);
            int redArea = (int)(HelloMilScene.SolidRect.Width * HelloMilScene.SolidRect.Height);
            Assert.True(red > redArea * 0.7,
                $"红色矩形覆盖率 {red}/{redArea} 偏低，矩形可能没被填充或被遮挡");

            // 三条线（实线 + 虚线 + 点线）：同长同色同宽，合计 ~2000 像素
            int blue = X11Pixel.CountNearIn(bitmap, HelloMilScene.LinesBand, HelloMilScene.BlueStroke, 40);
            Assert.True(blue > 1500, $"LinesBand 内蓝色像素 {blue} 偏低");

            // 文本"Hello from Linux"：在 TextBand（无其他元素）里至少 600 个深色像素
            int dark = X11Pixel.CountDarkIn(bitmap, HelloMilScene.TextBand, luminanceThreshold: 96);
            Assert.True(dark > 600,
                $"文字带内深色像素 {dark} 偏少，文本可能没画出来或位置不在预期区域");
        }

        [Fact]
        public void Render_Hash_Is_Deterministic_AcrossInvocations()
        {
            // 字体确定性 + 渲染确定性：同输入同输出，PNG 字节级一致。
            using HelloMilScene scene = NewScene();

            string hash1 = scene.RenderHash();
            string hash2 = scene.RenderHash();
            string hash3 = scene.RenderHash();

            Assert.Equal(hash1, hash2);
            Assert.Equal(hash1, hash3);
            Assert.NotEmpty(hash1);
        }

        [Fact]
        public void Render_TransformChain_MovesChild_OffOrigin()
        {
            // 变换链路通不通：子 Visual 本地是 (0,0)-(180,100)，经缩放+旋转+平移后
            // 落在 [3,2] 格子里。如果变换没起作用，amber 像素会出现在 (0,0)-(180,100)。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            int amber = X11Pixel.CountNear(bitmap, HelloMilScene.AmberFill, tolerance: 32);
            Assert.True(amber > 1000, $"amber 填充像素 {amber} 偏少，旋转矩形可能没画出来");

            SKRect amberBox = X11Pixel.BoundingBox(bitmap, HelloMilScene.AmberFill, tolerance: 32);
            Assert.True(amberBox.Top > 80, $"amber 区域顶部 y={amberBox.Top} 过低，旋转/平移可能没生效");
        }

        // ==================================================================
        //  各能力的像素证据
        // ==================================================================

        [Fact]
        public void Render_RoundedRect_CornerIsWhite_WhileSharpRectCornerIsRed()
        {
            // 圆角矩形与直角矩形同尺寸并排：直角的角上是红，圆角的角上是白底。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            SKColor sharpCorner = bitmap.GetPixel(
                (int)HelloMilScene.SolidRect.Left + 2, (int)HelloMilScene.SolidRect.Top + 2);
            Assert.True(X11Pixel.Delta(sharpCorner, HelloMilScene.RedFill) <= 40,
                $"直角矩形角上应是红色，实际 {sharpCorner}");

            SKColor roundCorner = bitmap.GetPixel(
                (int)HelloMilScene.RoundedRect.Left + 2, (int)HelloMilScene.RoundedRect.Top + 2);
            Assert.True(X11Pixel.IsNearBackground(roundCorner, 24),
                $"圆角矩形角上应是白底（圆角切掉了），实际 {roundCorner}");

            SKColor roundCenter = bitmap.GetPixel(
                (int)HelloMilScene.RoundedRect.MidX, (int)HelloMilScene.RoundedRect.MidY);
            Assert.True(X11Pixel.Delta(roundCenter, HelloMilScene.TealFill) <= 40,
                $"圆角矩形中心应是 teal 填充，实际 {roundCenter}");
        }

        [Fact]
        public void Render_LinearGradient_ChangesAlongDiagonal()
        {
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            SKPoint s = HelloMilScene.LinearStart;
            SKPoint e = HelloMilScene.LinearEnd;

            SKColor Sample(double t)
            {
                int x = (int)Math.Round(s.X + (e.X - s.X) * t);
                int y = (int)Math.Round(s.Y + (e.Y - s.Y) * t);
                return bitmap.GetPixel(x, y);
            }

            SKColor head = Sample(0.08);
            SKColor tail = Sample(0.92);

            // 渐变起点偏青（R 低），终点偏洋红（R 高、G 低）—— 方向不能反。
            Assert.True(head.Red < 60 && head.Blue > 170,
                $"线性渐变起点应偏青，实际 {head}");
            Assert.True(tail.Red > 180 && tail.Green < 110,
                $"线性渐变终点应偏洋红，实际 {tail}");

            // 不是纯色：两端差异显著
            Assert.True(X11Pixel.Delta(head, tail) > 100,
                $"线性渐变两端颜色差 {X11Pixel.Delta(head, tail)}，像是纯色填充");

            // 平滑过渡：相邻采样点之间是渐变的，不是两块纯色拼接
            SKColor prev = head;
            foreach (double t in new[] { 0.2, 0.35, 0.5, 0.65, 0.8 })
            {
                SKColor c = Sample(t);
                Assert.True(X11Pixel.Delta(c, prev) > 8,
                    $"t={t} 处颜色 {c} 与上一点 {prev} 几乎相同，渐变可能断了");
                prev = c;
            }
        }

        [Fact]
        public void Render_RadialGradient_BrightCenter_DarkEdge_LeftRightSymmetric()
        {
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            SKColor center = bitmap.GetPixel(
                (int)HelloMilScene.RadialCenter.X, (int)HelloMilScene.RadialCenter.Y);
            SKColor edge = bitmap.GetPixel(
                (int)HelloMilScene.RadialCenter.X + 50, (int)HelloMilScene.RadialCenter.Y);

            // 中心亮黄、边缘深紫：径向的"由内向外"证据
            Assert.True(center.Red > 220 && center.Green > 190,
                $"径向渐变中心应是亮色，实际 {center}");
            Assert.True(edge.Red < 170 && edge.Green < 120,
                $"径向渐变边缘应是深色，实际 {edge}");
            Assert.True(X11Pixel.Delta(center, edge) > 100,
                $"径向渐变中心/边缘差 {X11Pixel.Delta(center, edge)}，像是纯色填充");

            // 左右对称：与线性渐变的"方向性"形成对照
            SKColor left = bitmap.GetPixel(
                (int)HelloMilScene.RadialCenter.X - 40, (int)HelloMilScene.RadialCenter.Y);
            SKColor right = bitmap.GetPixel(
                (int)HelloMilScene.RadialCenter.X + 40, (int)HelloMilScene.RadialCenter.Y);
            Assert.True(X11Pixel.Delta(left, right) <= 30,
                $"径向渐变应左右对称，左 {left} vs 右 {right}");
        }

        [Fact]
        public void Render_Ellipse_HasFill_Stroke_And_WhiteOutside()
        {
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            // 内部：填充色
            SKColor inside = bitmap.GetPixel(
                (int)HelloMilScene.EllipseCenter.X, (int)HelloMilScene.EllipseCenter.Y);
            Assert.True(X11Pixel.Delta(inside, HelloMilScene.SeaGreenFill) <= 40,
                $"椭圆内部应是海绿填充，实际 {inside}");

            // 边缘：描边（深色，宽 6px）。椭圆顶部切点在 (cx, cy-ry)，描边以其为中心
            // 上下各 3px —— 在切点附近的一小条带里统计深色像素，不依赖单点取正。
            SKRect strokeBand = new SKRect(
                HelloMilScene.EllipseCenter.X - 6, HelloMilScene.EllipseCenter.Y - HelloMilScene.EllipseRadius.Y - 8,
                HelloMilScene.EllipseCenter.X + 6, HelloMilScene.EllipseCenter.Y - HelloMilScene.EllipseRadius.Y + 8);
            int stroke = X11Pixel.CountNearIn(bitmap, strokeBand, HelloMilScene.DarkStroke, 48);
            Assert.True(stroke > 20, $"椭圆顶部描边像素 {stroke} 偏少，描边可能没画");

            // 外部：白底（椭圆左端 x≈32，取 x=24）
            SKColor outside = bitmap.GetPixel(24, (int)HelloMilScene.EllipseCenter.Y);
            Assert.True(X11Pixel.IsNearBackground(outside, 24),
                $"椭圆外应是白底，实际 {outside}");
        }

        [Fact]
        public void Render_PathGeometry_StarHasConcaveNotch()
        {
            // 五角星是非凸轮廓：中心有墨，但正下方 30px 处（凹点 r=23 之外）没有墨。
            // 如果后端把路径画成了外接矩形或圆，这条断言立刻翻红。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            int cellCol = 1, cellRow = 1;
            SKRect region = HelloMilScene.Cell(cellCol, cellRow);
            int orange = X11Pixel.CountNearIn(bitmap, region, HelloMilScene.OrangeFill, 40);
            Assert.True(orange > 2500, $"五角星橙色像素 {orange} 偏少，路径可能没画出来");

            SKColor center = bitmap.GetPixel(
                (int)HelloMilScene.StarCenter.X, (int)HelloMilScene.StarCenter.Y);
            Assert.True(X11Pixel.Delta(center, HelloMilScene.OrangeFill) <= 40,
                $"星形中心应有填充，实际 {center}");

            SKColor notch = bitmap.GetPixel(
                (int)HelloMilScene.StarCenter.X, (int)HelloMilScene.StarCenter.Y + 30);
            Assert.True(X11Pixel.Delta(notch, HelloMilScene.OrangeFill) > 40
                && X11Pixel.IsNearBackground(notch, 40),
                $"星形凹点下方应是白底，实际 {notch}（轮廓可能被画成了凸形）");

            // 包围盒接近"方形"而不是 178×110 的矩形：外接圆半径 56 → 约 107×101
            SKRect box = X11Pixel.BoundingBoxIn(bitmap, region, HelloMilScene.OrangeFill, 40);
            Assert.InRange(box.Width, 90, 126);
            Assert.InRange(box.Height, 82, 120);
        }

        [Fact]
        public void Render_DashStroke_HasGaps_WhileSolidDoesNot()
        {
            // 三条线同长、同色、同宽，只有 DashStyle 不同。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            SKRect solidBand = new SKRect(418, 215, 576, 227);
            SKRect dashBand = new SKRect(418, 255, 576, 267);
            SKRect dotBand = new SKRect(418, 295, 576, 307);

            int solid = X11Pixel.CountNearIn(bitmap, solidBand, HelloMilScene.BlueStroke, 40);
            int dash = X11Pixel.CountNearIn(bitmap, dashBand, HelloMilScene.BlueStroke, 40);
            int dot = X11Pixel.CountNearIn(bitmap, dotBand, HelloMilScene.BlueStroke, 40);

            Assert.True(solid > 900, $"实线像素 {solid} 偏低");
            Assert.True(dash < solid * 0.8, $"虚线覆盖 {dash} 应明显低于实线 {solid}（虚线长度=线宽的倍数）");
            Assert.True(dot < dash * 0.85, $"点线覆盖 {dot} 应低于虚线 {dash}");

            // 实线中心行没有空档，虚线中心行至少 3 个空档
            Assert.Equal(0, X11Pixel.CountGaps(bitmap, (int)HelloMilScene.SolidLineA.Y,
                (int)HelloMilScene.SolidLineA.X + 2, (int)HelloMilScene.SolidLineB.X - 2,
                HelloMilScene.BlueStroke, 70));
            int gaps = X11Pixel.CountGaps(bitmap, (int)HelloMilScene.DashLineA.Y,
                (int)HelloMilScene.DashLineA.X + 2, (int)HelloMilScene.DashLineB.X - 2,
                HelloMilScene.BlueStroke, 70);
            Assert.True(gaps >= 3, $"虚线中心行只扫到 {gaps} 个空档，虚线可能没断开");
        }

        [Fact]
        public void Render_BitmapSource_CheckerboardColors_LandOnGrid()
        {
            // 位图源链路：MilCmdBitmapSource(0x0c) → BitmapResolver → MilDrawImage(0x47)。
            // 四色棋盘格 6×6 格、每格 9px，四个采样点分别落进四格，颜色必须各就各位。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            SKRect r = HelloMilScene.CheckerRect;
            var expected = new (int X, int Y, SKColor Color)[]
            {
                ((int)r.Left + 4,  (int)r.Top + 4,  new SKColor(0x1E, 0x50, 0xC8)),   // 蓝
                ((int)r.Left + 13, (int)r.Top + 4,  new SKColor(0xF2, 0xF2, 0xF2)),   // 白
                ((int)r.Left + 4,  (int)r.Top + 13, new SKColor(0xD8, 0x30, 0x30)),   // 红
                ((int)r.Left + 13, (int)r.Top + 13, new SKColor(0xF0, 0xC0, 0x20)),   // 黄
            };

            foreach ((int x, int y, SKColor want) in expected)
            {
                SKColor got = bitmap.GetPixel(x, y);
                Assert.True(X11Pixel.Delta(got, want) <= 16,
                    $"棋盘格 ({x},{y}) 应是 {want}，实际 {got}（位图内容或对位不对）");
            }

            // 平滑渐变位图：左上深蓝、中心灰、右下黄 —— 逐像素内容，不是纯色块
            SKRect g = HelloMilScene.RainbowRect;
            var corners = new (int X, int Y, SKColor Color)[]
            {
                ((int)g.Left + 5,  (int)g.Top + 5,  new SKColor(24, 24, 231)),
                ((int)g.MidX,      (int)g.MidY,     new SKColor(130, 130, 125)),
                ((int)g.Right - 6, (int)g.Bottom - 6, new SKColor(236, 236, 19)),
            };
            foreach ((int x, int y, SKColor want) in corners)
            {
                SKColor got = bitmap.GetPixel(x, y);
                Assert.True(X11Pixel.Delta(got, want) <= 24,
                    $"渐变位图 ({x},{y}) 应是 {want}，实际 {got}");
            }
        }

        [Fact]
        public void Render_Blur_SpreadsPastRectEdge_WhileSharpStaysInside()
        {
            // 对比展示：清晰块的边缘齐整（右缘外几乎无墨），模糊块的颜色越出矩形边界。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            SKRect cell = HelloMilScene.Cell(0, 2);

            int sharpCore = X11Pixel.CountNearIn(bitmap, HelloMilScene.SharpRect, HelloMilScene.CrimsonFill, 40);
            Assert.True(sharpCore > HelloMilScene.SharpRect.Width * HelloMilScene.SharpRect.Height * 0.85,
                $"清晰块覆盖率 {sharpCore} 偏低");

            int blurCore = X11Pixel.CountNearIn(bitmap, HelloMilScene.BlurRect, HelloMilScene.CrimsonFill, 40);
            Assert.True(blurCore < sharpCore * 0.95,
                $"模糊块核心覆盖 {blurCore} 应低于清晰块 {sharpCore}（边缘被摊开了）");

            // 清晰块右缘外（x∈[91,110]）这一行没有墨；模糊块右缘外（x∈[181,197]）
            // 同一行仍有墨且延伸得更远 —— 同一判定口径下两条边界至少差 10px。
            int sharpEdge = X11Pixel.RowExtentFromWhite(
                bitmap, (int)HelloMilScene.SharpRect.MidY,
                (int)HelloMilScene.SharpRect.Right + 1, (int)HelloMilScene.SharpRect.Right + 20, 10);
            Assert.True(sharpEdge <= (int)HelloMilScene.SharpRect.Right + 2,
                $"清晰块右缘外扫到墨迹到 x={sharpEdge}，边缘没有收住");

            int blurEdge = X11Pixel.RowExtentFromWhite(
                bitmap, (int)HelloMilScene.BlurRect.MidY,
                (int)HelloMilScene.BlurRect.Right + 1, (int)HelloMilScene.Cell(0, 2).Right - 1, 10);
            Assert.True(blurEdge >= (int)HelloMilScene.BlurRect.Right + 3,
                $"模糊块右缘外墨迹只到 x={blurEdge}，Blur 可能没生效");

            // 模糊块越出的那部分应是偏红/pink 的（还是那个颜色的 faded 版本）
            SKColor spill = bitmap.GetPixel((int)HelloMilScene.BlurRect.Right + 2, (int)HelloMilScene.BlurRect.MidY);
            Assert.True(spill.Red > spill.Green + 15 && spill.Red > spill.Blue + 15,
                $"模糊溢出的颜色应是红调，实际 {spill}");

            // 整格的红斑只在这两个方块附近（别把别处的颜色算进来）
            SKRect box = X11Pixel.BoundingBoxIn(bitmap, cell, HelloMilScene.CrimsonFill, 60);
            Assert.True(box.Left < HelloMilScene.SharpRect.Left + 4,
                $"清晰块左边界 {box.Left} 异常");
        }

        [Fact]
        public void Render_DropShadow_DirectionAndColor_AreRecognizable()
        {
            // 315° → 右下（红）；135° → 左上（蓝）。反方向采样点必须是白的。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            // A：右下应有红色调的阴影
            SKColor a = bitmap.GetPixel(
                (int)HelloMilScene.ShadowRectA.Right + 6, (int)HelloMilScene.ShadowRectA.Bottom + 6);
            Assert.True(a.Red > a.Green + 40 && a.Red > a.Blue + 40,
                $"315° 方向应是红阴影，实际 {a}");

            // A：左上应是白的（阴影不在那边）
            SKColor aOpp = bitmap.GetPixel(
                (int)HelloMilScene.ShadowRectA.Left - 6, (int)HelloMilScene.ShadowRectA.Top - 6);
            Assert.True(X11Pixel.IsNearBackground(aOpp, 20),
                $"315° 阴影不应出现在左上，实际 {aOpp}");

            // B：左上应有蓝色调的阴影
            SKColor b = bitmap.GetPixel(
                (int)HelloMilScene.ShadowRectB.Left + 4 - 10, (int)HelloMilScene.ShadowRectB.Top + 4 - 10);
            Assert.True(b.Blue > b.Red + 40 && b.Blue > b.Green + 40,
                $"135° 方向应是蓝阴影，实际 {b}");

            // B：右下应是白的
            SKColor bOpp = bitmap.GetPixel(
                (int)HelloMilScene.ShadowRectB.Right + 6, (int)HelloMilScene.ShadowRectB.Bottom + 6);
            Assert.True(X11Pixel.IsNearBackground(bOpp, 20),
                $"135° 阴影不应出现在右下，实际 {bOpp}");

            // 两块内容本体都是黄色方块
            SKColor aFill = bitmap.GetPixel(
                (int)HelloMilScene.ShadowRectA.MidX, (int)HelloMilScene.ShadowRectA.MidY);
            Assert.True(X11Pixel.Delta(aFill, HelloMilScene.YellowFill) <= 40,
                $"阴影上方应露出黄色内容本体，实际 {aFill}");
        }

        [Fact]
        public void Render_Clip_CutsShape_OffOutsideTheClipRegion()
        {
            // 椭圆本身横跨 x∈[412,582]，但裁剪框只到 x=508：
            // 框内应有紫色，框外（x>510）必须一粒紫色都没有。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            SKColor inside = bitmap.GetPixel(500, (int)HelloMilScene.ClipEllipseCenter.Y);
            Assert.True(X11Pixel.Delta(inside, HelloMilScene.PurpleFill) <= 48,
                $"裁剪框内应是紫色椭圆，实际 {inside}");

            SKRect outsideRight = new SKRect(
                HelloMilScene.ClipRect.Right + 2, HelloMilScene.ClipRect.Top - 4,
                HelloMilScene.Cell(2, 2).Right, HelloMilScene.ClipRect.Bottom + 4);
            int leaked = X11Pixel.CountNearIn(bitmap, outsideRight, HelloMilScene.PurpleFill, 60);
            Assert.Equal(0, leaked);

            SKRect outsideLeft = new SKRect(
                HelloMilScene.Cell(2, 2).Left, HelloMilScene.ClipRect.Top - 4,
                HelloMilScene.ClipRect.Left - 2, HelloMilScene.ClipRect.Bottom + 4);
            leaked = X11Pixel.CountNearIn(bitmap, outsideLeft, HelloMilScene.PurpleFill, 60);
            Assert.Equal(0, leaked);

            int clippedArea = X11Pixel.CountNearIn(bitmap, HelloMilScene.ClipRect, HelloMilScene.PurpleFill, 48);
            Assert.True(clippedArea > 4000, $"裁剪框内紫色像素 {clippedArea} 偏少");
        }

        [Fact]
        public void Render_NestedTransform_RotatedBox_Inflates_AndGhostOutlineExists()
        {
            // 父 Visual 平移 + 子 Visual 缩放/旋转：旋转后的包围盒（~133×108）应当比
            // 未旋转的缩放矩形（117×65）更高更宽；未旋转的虚线对照轮廓也要在。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            SKRect cell = HelloMilScene.Cell(3, 2);
            SKRect box = X11Pixel.BoundingBoxIn(bitmap, cell, HelloMilScene.AmberFill, 32);

            Assert.True(box.Width > 120, $"旋转后包围盒宽 {box.Width}，与未旋转的 117 几乎一样，旋转可能没生效");
            Assert.True(box.Height > 85, $"旋转后包围盒高 {box.Height}，与未旋转的 65 几乎一样，旋转可能没生效");

            // 落点在 [3,2] 格子里，而不是未变换的 (0,0)-(180,100)
            Assert.True(box.Left >= HelloMilScene.NestedHostOrigin.X - 2
                && box.Top >= HelloMilScene.NestedHostOrigin.Y - 2,
                $"amber 落在 ({box.Left},{box.Top})，嵌套平移可能没生效");

            // 未旋转的虚线对照轮廓（灰、DashStyle）
            int ghost = X11Pixel.CountNearIn(bitmap, cell, HelloMilScene.OutlineGray, 36);
            Assert.True(ghost > 120, $"对照虚线轮廓像素 {ghost} 偏少，对比参照物缺失");
        }

        [Fact]
        public void Render_AllTwelveLabels_AreDrawn()
        {
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            string[] labels =
            {
                "Solid rect", "Rounded rect", "Linear gradient", "Radial gradient",
                "Ellipse+stroke", "Path (star)", "Solid vs dash", "Bitmap source",
                "Sharp vs blur", "Drop shadow", "Clipped", "Nested transform",
            };

            for (int row = 0; row < 3; row++)
            {
                for (int col = 0; col < 4; col++)
                {
                    SKRect cell = HelloMilScene.Cell(col, row);
                    var band = new SKRect(
                        cell.Left + 5, cell.Top + HelloMilScene.LabelDrop - 13,
                        cell.Left + HelloMilScene.CellW - 5, cell.Top + HelloMilScene.LabelDrop + 4);
                    int ink = X11Pixel.CountDarkIn(bitmap, band, luminanceThreshold: 120);
                    Assert.True(ink > 40,
                        $"标签 \"{labels[row * 4 + col]}\" 深色像素 {ink} 偏少，标签可能没画出来");
                }
            }

            // 标题
            int title = X11Pixel.CountDarkIn(bitmap,
                new SKRect(14, 8, 580, 36), luminanceThreshold: 120);
            Assert.True(title > 150, $"标题深色像素 {title} 偏少");
        }

        [Fact]
        public void Render_ImageBrush_Fills_Rect_With_Checkerboard()
        {
            // ImageBrush（TileBrush）已实现（U12）：同一张棋盘格经 MilImageBrush 填充，
            // 默认 TileBrush 语义（Viewbox=整图 / Viewport=整个包围盒 / Stretch=Fill /
            // TileMode=None）应把矩形铺满。采样带避开虚线边框，断言棋盘格四色都出现、
            // 且没有纯白底残留。ImageBrushFillNotDrawn 探针必须仍为 false ——
            // 它一变红就说明 TileBrush 支持退化了，展示与这条用例都得跟着更新。
            using HelloMilScene scene = NewScene();
            using SKBitmap bitmap = scene.RenderBitmap();

            Assert.Equal(0, scene.NotDrawnCount);
            Assert.False(scene.ImageBrushFillNotDrawn,
                "ImageBrush 填充又被记成 NotDrawn —— TileBrush 支持退化了");

            // 采样带内：棋盘格四色（蓝/白格/红/黄）都要出现。注意"白格"是
            // (0xF2,0xF2,0xF2)，与纯白底 (0xFF,0xFF,0xFF) 有 13/通道的差，可区分。
            var palette = new[]
            {
                new SKColor(0x1E, 0x50, 0xC8),  // 蓝
                new SKColor(0xF2, 0xF2, 0xF2),  // 白格
                new SKColor(0xD8, 0x30, 0x30),  // 红
                new SKColor(0xF0, 0xC0, 0x20),  // 黄
            };
            foreach (SKColor c in palette)
            {
                int n = X11Pixel.CountNearIn(
                    bitmap, HelloMilScene.ImageBrushBand, c, tolerance: 24);
                Assert.True(n > 20,
                    $"ImageBrush 采样带中颜色 {c} 像素 {n} 偏少 —— 画刷填充疑似没生效");
            }

            int pureWhite = X11Pixel.CountNearIn(
                bitmap, HelloMilScene.ImageBrushBand, SKColors.White, tolerance: 4);
            Assert.Equal(0, pureWhite);
        }

        // ==================================================================
        //  端到端（需要 X server）
        // ==================================================================

        [HelloMilX11Fact]
        public void X11_Capture_From_LiveWindow_ContainsExpectedContent()
        {
            // 端到端：开真窗口 → Present → 独立进程 xwd 抓屏 → 验证截图。
            string display = Environment.GetEnvironmentVariable("DISPLAY");
            Assert.False(string.IsNullOrWhiteSpace(display), "DISPLAY 为空");

            string outPath = Path.Combine(
                Path.GetTempPath(),
                $"hellomil-test-{Guid.NewGuid():n}.png");

            try
            {
                HelloMilEndToEnd.OpenAndCapture(outPath, display, holdSeconds: 0);

                FileInfo fi = new FileInfo(outPath);
                Assert.True(fi.Exists, $"截图文件不存在：{outPath}");
                Assert.True(fi.Length > 1024, $"截图文件 {fi.Length} bytes 太小");

                using SKBitmap shot = SKBitmap.Decode(outPath);
                Assert.NotNull(shot);
                Assert.False(X11Pixel.IsBlank(shot), "截到的是空帧 —— xwd 拿到的窗口内容异常");

                int red = X11Pixel.CountNear(shot, HelloMilScene.RedFill, tolerance: 32);
                int blue = X11Pixel.CountNearIn(shot, HelloMilScene.LinesBand, HelloMilScene.BlueStroke, 48);
                int dark = X11Pixel.CountDark(shot, luminanceThreshold: 96);

                Assert.True(red > 5000, $"截屏中红色像素 {red} 偏少");
                Assert.True(blue > 800, $"截屏中蓝色像素 {blue} 偏少（端到端的线没落到 X server）");
                Assert.True(dark > 1500, $"截屏中深色像素 {dark} 偏少（端到端的字/线没落到 X server）");

                // 能力抽查：径向渐变的中心亮点与裁剪框外的"无墨区"都要落到 X server
                SKColor radial = shot.GetPixel(
                    (int)HelloMilScene.RadialCenter.X, (int)HelloMilScene.RadialCenter.Y);
                Assert.True(radial.Red > 200, $"截屏中径向渐变中心异常：{radial}");

                int leaked = X11Pixel.CountNearIn(shot,
                    new SKRect(HelloMilScene.ClipRect.Right + 2, HelloMilScene.ClipRect.Top,
                               HelloMilScene.Cell(2, 2).Right, HelloMilScene.ClipRect.Bottom),
                    HelloMilScene.PurpleFill, 60);
                Assert.Equal(0, leaked);
            }
            finally
            {
                try { if (File.Exists(outPath)) File.Delete(outPath); } catch { /* 不影响 */ }
            }
        }
    }

    /// <summary>共享的位图像素工具。挂在 test 程序集里（不被 src/ 引用）。</summary>
    internal static class X11Pixel
    {
        public static bool IsBlank(SKBitmap bitmap)
        {
            SKColor first = bitmap.GetPixel(0, 0);
            for (int y = 0; y < bitmap.Height; y++)
                for (int x = 0; x < bitmap.Width; x++)
                    if (bitmap.GetPixel(x, y) != first) return false;
            return true;
        }

        public static int CountNear(SKBitmap bitmap, SKColor target, int tolerance = 24) =>
            CountNearIn(bitmap, new SKRect(0, 0, bitmap.Width, bitmap.Height), target, tolerance);

        public static int CountNearIn(SKBitmap bitmap, SKRect region, SKColor target, int tolerance = 24)
        {
            int count = 0;
            ForEachPixel(bitmap, region, (x, y, c) => { if (Delta(c, target) <= tolerance) count++; });
            return count;
        }

        public static int CountNotBackground(SKBitmap bitmap, SKRect region, int tolerance = 8)
        {
            int count = 0;
            ForEachPixel(bitmap, region, (x, y, c) =>
            {
                if (!IsNearBackground(c, tolerance)) count++;
            });
            return count;
        }

        public static int CountGaps(
            SKBitmap bitmap, int y, int xFrom, int xTo, SKColor target, int tolerance)
        {
            int gaps = 0;
            bool inGap = false;
            for (int x = xFrom; x <= xTo; x++)
            {
                bool miss = Delta(bitmap.GetPixel(x, y), target) > tolerance;
                if (miss && !inGap) gaps++;
                inGap = miss;
            }
            return gaps;
        }

        public static int CountDarkIn(SKBitmap bitmap, SKRect region, int luminanceThreshold = 96)
        {
            int count = 0;
            ForEachPixel(bitmap, region, (x, y, c) =>
            {
                int lum = (c.Red * 299 + c.Green * 587 + c.Blue * 114) / 1000;
                if (lum < luminanceThreshold) count++;
            });
            return count;
        }

        public static int CountDark(SKBitmap bitmap, int luminanceThreshold = 96) =>
            CountDarkIn(bitmap, new SKRect(0, 0, bitmap.Width, bitmap.Height), luminanceThreshold);

        public static SKRect BoundingBox(SKBitmap bitmap, SKColor target, int tolerance = 24) =>
            BoundingBoxIn(bitmap, new SKRect(0, 0, bitmap.Width, bitmap.Height), target, tolerance);

        public static SKRect BoundingBoxIn(
            SKBitmap bitmap, SKRect region, SKColor target, int tolerance = 24)
        {
            int minX = int.MaxValue, minY = int.MaxValue;
            int maxX = int.MinValue, maxY = int.MinValue;
            bool any = false;

            ForEachPixel(bitmap, region, (x, y, c) =>
            {
                if (Delta(c, target) > tolerance) return;
                any = true;
                if (x < minX) minX = x;
                if (x > maxX) maxX = x;
                if (y < minY) minY = y;
                if (y > maxY) maxY = y;
            });

            if (!any) return SKRect.Empty;
            return new SKRect(minX, minY, maxX + 1, maxY + 1);
        }

        public static bool IsNearBackground(SKColor c, int tolerance = 12) =>
            c.Red > 255 - tolerance && c.Green > 255 - tolerance && c.Blue > 255 - tolerance;

        /// <summary>
        /// 在 y 这一行、[xFrom,xTo] 区间里，最后一个"离开白底"的像素的 x。
        /// 一行都没有墨（全白）时返回 xFrom - 1。用于比较清晰/模糊块的边界位置。
        /// </summary>
        public static int RowExtentFromWhite(
            SKBitmap bitmap, int y, int xFrom, int xTo, int tolerance = 10)
        {
            int extent = xFrom - 1;
            for (int x = xFrom; x <= xTo; x++)
            {
                SKColor c = bitmap.GetPixel(x, y);
                if (255 - c.Red > tolerance || 255 - c.Green > tolerance || 255 - c.Blue > tolerance)
                    extent = x;
            }
            return extent;
        }

        public static int Delta(SKColor a, SKColor b) =>
            Math.Max(
                Math.Max(Math.Abs(a.Red - b.Red), Math.Abs(a.Green - b.Green)),
                Math.Max(Math.Abs(a.Blue - b.Blue), Math.Abs(a.Alpha - b.Alpha)));

        private static void ForEachPixel(SKBitmap bitmap, SKRect region, Action<int, int, SKColor> body)
        {
            int left = Math.Max(0, (int)region.Left);
            int top = Math.Max(0, (int)region.Top);
            int right = Math.Min(bitmap.Width, (int)region.Right);
            int bottom = Math.Min(bitmap.Height, (int)region.Bottom);

            for (int y = top; y < bottom; y++)
                for (int x = left; x < right; x++)
                    body(x, y, bitmap.GetPixel(x, y));
        }
    }
}

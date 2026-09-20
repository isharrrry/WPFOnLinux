// HelloMil 的场景：资源表 + 视觉树 + 指令流 + 离屏渲染。
//
// 【这个文件里没有一行 X11 代码，是刻意的】
//   端到端 demo 最容易变成"一大坨 Main 里全做完"，那样既没法测、也没法在没 X server
//   的机器上验证"渲染是不是对的"。所以把「构造场景 + 渲染出位图」和「开窗 + 截图」
//   切成两半：本文件只负责前者，Program.cs 负责后者，HelloMil.Tests 直接测前者。
//
// 【为什么走真实 MilChannel 而不是自己造一张资源表】
//   画刷/画笔/字形在指令流里全是句柄，句柄要靠 MilResourceTable 解析，变换还要靠
//   TransformResolver 递归解。用 mock 就等于"我的 mock 和我的一致"，测不到真实链路。
//   这里建真的 MilChannel，用 Resources.Duplicate 把具体类型的资源塞进去，于是
//   TransformResolver / SkiaBrush / SkiaPen / SkiaEffect / Text/ 全在真实路径上被走到。
//
// 【这张图要证明什么】
//   一张 800×600 的能力展示图：纯色矩形、圆角矩形、线性/径向渐变、椭圆+描边、路径
//   几何、实线 vs 虚线、位图源、Blur（与清晰版并排）、DropShadow、裁剪、嵌套变换、
//   文本。凡是"效果类"的能力都放**成对对比**，单独一个模糊的圆证明不了模糊生效了。
//
// 【位图画刷（ImageBrush）与位图源（MilDrawImage）双链路】
//   MilDrawImage（0x47）走 MilBitmapSource 位图源链路画"图像"；ImageBrush（0x81）走
//   SkiaBrush 的 TileBrush 链路把同一张棋盘格当**画刷**填充矩形。两条链路同屏对照：
//   左上是图像，右下是画刷填充（默认 Stretch=Fill + TileMode=None 铺满整个矩形）。

using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using WpfGfx.Linux.Text;

namespace HelloMil
{
    /// <summary>
    /// HelloMil 场景。构造资源表与视觉树，可反复渲染成位图。
    /// 线程不安全（SkiaRenderBackend 与 TextRenderer 都没有加锁）。
    /// </summary>
    public sealed class HelloMilScene : IDisposable
    {
        // ==================================================================
        //  画布与网格（测试按这些常量去截图里找像素）
        // ==================================================================

        public const int Width = 800;
        public const int Height = 600;

        public const string Greeting = "Hello from Linux";
        public const string Title = "HelloMil showcase - WpfGfx.Linux rendering backend on X11";
        public const string Subtitle =
            "solid | gradients | ellipse | path | rounded rect | dash | bitmap | blur | shadow | clip | nested transform | text";

        // 4 列 × 3 行。每格 178×130，格内留 10px 边距，格下方 16px 放标签。
        public const int GridLeft = 20;
        public const int GridTop = 40;
        public const int CellW = 178;
        public const int CellH = 130;
        public const int ColStep = 194;
        public const int RowStep = 156;
        public const float LabelDrop = 146f;

        /// <summary>第 (col,row) 个格子的外框。</summary>
        public static SKRect Cell(int col, int row) => new SKRect(
            GridLeft + col * ColStep, GridTop + row * RowStep,
            GridLeft + col * ColStep + CellW, GridTop + row * RowStep + CellH);

        /// <summary>格子内缩 d 像素后的内容区。</summary>
        private static SKRect Inset(SKRect cell, float d) =>
            new SKRect(cell.Left + d, cell.Top + d, cell.Right - d, cell.Bottom - d);

        // ---------------- [0,0] 纯色矩形（与 [1,0] 圆角矩形并排对比）----------------
        // 直角、纯红、无描边 —— 最朴素的填充，也是"后端有没有真的画东西"的基准。
        public static readonly SKRect SolidRect = Inset(Cell(0, 0), 10);

        // ---------------- [1,0] 圆角矩形 ----------------
        public static readonly SKRect RoundedRect = Inset(Cell(1, 0), 10);
        public static readonly SKPoint RoundedCorner = new SKPoint(28, 28);

        // ---------------- [2,0] 线性渐变 ----------------
        // 绝对映射（MappingMode=Absolute）：起止点直接是画布坐标，左上 → 右下。
        public static readonly SKRect LinearRect = Inset(Cell(2, 0), 10);
        public static readonly SKPoint LinearStart = new SKPoint(LinearRect.Left, LinearRect.Top);
        public static readonly SKPoint LinearEnd = new SKPoint(LinearRect.Right, LinearRect.Bottom);

        // ---------------- [3,0] 径向渐变 ----------------
        public static readonly SKRect RadialRect = Inset(Cell(3, 0), 10);
        public static readonly SKPoint RadialCenter = new SKPoint(691, 105);
        public const float RadialRadius = 56f;

        // ---------------- [0,1] 椭圆 + 描边 ----------------
        public static readonly SKPoint EllipseCenter = new SKPoint(109, 261);
        public static readonly SKPoint EllipseRadius = new SKPoint(74, 52);
        public const float EllipseStrokeWidth = 6f;

        // ---------------- [1,1] 路径几何：五角星 ----------------
        public static readonly SKPoint StarCenter = new SKPoint(303, 261);
        public const float StarOuter = 56f;
        public const float StarInner = 23f;

        // ---------------- [2,1] 实线 vs 虚线 ----------------
        // 三条同长、同色、同线宽的水平线，只有 DashStyle 不同。
        public static readonly SKPoint SolidLineA = new SKPoint(418, 221);
        public static readonly SKPoint SolidLineB = new SKPoint(576, 221);
        public static readonly SKPoint DashLineA = new SKPoint(418, 261);
        public static readonly SKPoint DashLineB = new SKPoint(576, 261);
        public static readonly SKPoint DotLineA = new SKPoint(418, 301);
        public static readonly SKPoint DotLineB = new SKPoint(576, 301);
        public const float LineThickness = 6f;
        /// <summary>三条线所在区域（统计虚线"空档"用）。</summary>
        public static readonly SKRect LinesBand = new SKRect(408, 200, 586, 320);

        // ---------------- [3,1] 位图源（MilDrawImage）+ ImageBrush（0x81） ----------------
        // 上面两张是程序化生成的位图（四色棋盘格 + 双通道平滑渐变），走
        // MilBitmapSource(0x0c) → BitmapResolver → MilDrawImage(0x47) 的**图像**链路。
        // 下面那个虚线框是**画刷**链路：同一张棋盘格登记成 MilImageBrush 填充矩形，
        // SkiaBrush 按 TileBrush 语义（默认 Viewbox=整图 / Viewport=整个包围盒 /
        // Stretch=Fill / TileMode=None）把它铺满整个矩形 —— 与左上的原图逐色可对照。
        public const int BitmapSize = 54;
        public static readonly SKRect CheckerRect = new SKRect(610, 202, 664, 256);
        public static readonly SKRect RainbowRect = new SKRect(670, 202, 724, 256);
        public static readonly SKRect ImageBrushRect = new SKRect(610, 262, 772, 300);
        /// <summary>验证 ImageBrush 填充的采样带（避开虚线边框）。</summary>
        public static readonly SKRect ImageBrushBand = new SKRect(736, 266, 768, 296);

        // ---------------- [0,2] Blur：清晰 vs 模糊并排 ----------------
        // 两个同色同尺寸的方块，右边那个套 MilPushEffect(MilBlurEffect)。
        public static readonly SKRect SharpRect = new SKRect(30, 382, 90, 442);
        public static readonly SKRect BlurRect = new SKRect(120, 382, 180, 442);
        public const double BlurRadius = 12.0;

        // ---------------- [1,2] DropShadow：两个相反方向 ----------------
        // 315° → 右下（红）；135° → 左上（蓝）。方向与颜色都肉眼可辨。
        public static readonly SKRect ShadowRectA = new SKRect(234, 382, 284, 432);
        public static readonly SKRect ShadowRectB = new SKRect(322, 382, 372, 432);
        public const double ShadowDepth = 14.0;
        public const double ShadowDirectionA = 315.0;
        public const double ShadowDirectionB = 135.0;
        public const double ShadowBlurRadius = 8.0;

        // ---------------- [2,2] 裁剪 ----------------
        // 一个大椭圆被 [418,508]×[362,472] 的矩形裁剪，四条切边都是笔直的。
        public static readonly SKRect ClipRect = new SKRect(418, 362, 508, 472);
        public static readonly SKPoint ClipEllipseCenter = new SKPoint(497, 417);
        // 半径在上下方向上也超出裁剪框：切出来的四条边都是笔直的，"被切掉"无可辩驳。
        public static readonly SKPoint ClipEllipseRadius = new SKPoint(85, 62);

        // ---------------- [3,2] 嵌套变换 ----------------
        // 父 Visual 平移到格子里，子 Visual 再缩放 + 旋转 —— 两级变换相乘。
        public static readonly SKPoint NestedHostOrigin = new SKPoint(602, 352);
        public static readonly SKPoint NestedTargetCenter = new SKPoint(89, 65);
        public const float NestedScale = 0.65f;
        public const float NestedRotationDegrees = 25f;
        public static readonly SKRect TransformedRect = new SKRect(0, 0, 180, 100);
        public static readonly SKPoint TransformedCornerRadius = new SKPoint(14, 14);
        /// <summary>未旋转的对照轮廓（父 Visual 本地坐标，虚线灰）。</summary>
        public static readonly SKRect TransformedGhost = new SKRect(30, 32, 148, 98);

        // ---------------- 文本 ----------------
        public static readonly SKPoint TitleBaseline = new SKPoint(20, 28);
        public const float TitleSize = 17f;
        public static readonly SKPoint TextBaseline = new SKPoint(40, 552);
        public const float TextSize = 36f;
        public static readonly SKPoint SubtitleBaseline = new SKPoint(40, 584);
        public const float SubtitleSize = 12f;
        public const float LabelSize = 13f;

        /// <summary>
        /// 主问候语所在区域。这块里除了字墨就是白底，按亮度统计深色像素时不会被
        /// 别的元素污染（三行标签的基线在 186/342/498，都在本带之外）。
        /// </summary>
        public static readonly SKRect TextBand = new SKRect(30, 515, 600, 570);

        // ==================================================================
        //  配色
        // ==================================================================

        public static readonly SKColor Background = SKColors.White;
        public static readonly SKColor RedFill = new SKColor(200, 30, 30);        // [0,0]
        public static readonly SKColor TealFill = new SKColor(0, 138, 122);       // [1,0]
        public static readonly SKColor SeaGreenFill = new SKColor(46, 139, 87);   // [0,1]
        public static readonly SKColor OrangeFill = new SKColor(245, 124, 0);     // [1,1]
        public static readonly SKColor CrimsonFill = new SKColor(192, 40, 80);    // [0,2]
        public static readonly SKColor YellowFill = new SKColor(255, 212, 59);    // [1,2]
        public static readonly SKColor PurpleFill = new SKColor(123, 47, 190);    // [2,2]
        public static readonly SKColor AmberFill = new SKColor(235, 150, 30);     // [3,2]

        public static readonly SKColor BlueStroke = new SKColor(20, 70, 200);     // 三条线
        public static readonly SKColor GreenStroke = new SKColor(0, 110, 70);     // 变换块描边
        public static readonly SKColor DarkStroke = new SKColor(40, 44, 52);      // 通用描边

        public static readonly SKColor ShadowRed = new SKColor(176, 24, 24);      // 315° 阴影
        public static readonly SKColor ShadowBlue = new SKColor(30, 64, 184);     // 135° 阴影

        public static readonly SKColor TitleNavy = new SKColor(34, 51, 102);
        public static readonly SKColor TextInk = new SKColor(16, 24, 64);
        public static readonly SKColor SubtitleGray = new SKColor(85, 85, 102);
        public static readonly SKColor LabelGray = new SKColor(51, 51, 51);
        public static readonly SKColor OutlineGray = new SKColor(150, 150, 160);

        /// <summary>打包字体家族名。FontSet 只认 build/fonts 里的那几份。</summary>
        public const string FontFamily = "Noto Sans";

        // ---------------- 实例状态 ----------------

        private readonly MilChannel _channel;
        private readonly MilChannelResourceProvider _provider;
        private readonly TextRenderer _text;
        private readonly SkiaRenderBackend _backend;
        private readonly RenderContext _context;
        private MilVisual _root;
        private bool _disposed;

        private HelloMilScene(string fontDirectory, MilChannel channel, MilChannelResourceProvider provider,
            TextRenderer text, SkiaRenderBackend backend, RenderContext context)
        {
            FontDirectory = fontDirectory;
            _channel = channel;
            _provider = provider;
            _text = text;
            _backend = backend;
            _context = context;
        }

        /// <summary>字体目录（打包字体，决定文本渲染的确定性）。</summary>
        public string FontDirectory { get; }

        // ----- 上一帧的诊断（Render() 之后才有意义）-----

        /// <summary>上一帧后端执行过的绘图指令总数。</summary>
        public long InstructionCount { get; private set; }

        /// <summary>上一帧完全没产出绘制的指令条数（缺资源 / 类型未支持）。</summary>
        public long NotDrawnCount { get; private set; }

        /// <summary>
        /// 上一帧是否只有"ImageBrush 填充矩形"没画出来（= SkiaBrush 的 TileBrush 缺口探针）。
        /// ImageBrush 已实现（2026-09-10）后恒为 false；测试仍断言它，防止未来有人把
        /// 支持偷偷退掉而不更新展示 —— 该探针一变红就说明 ImageBrush 又画不出来了。
        /// </summary>
        public bool ImageBrushFillNotDrawn { get; private set; }

        /// <summary>
        /// 上一帧的 MilDrawGlyphRun 是否被后端记成"没画出来"。
        /// false 表示文本钩子（Text/ 的 GlyphRunRenderer）接上了并返回了 true。
        /// </summary>
        public bool GlyphRunSkipped { get; private set; }

        // ==================================================================
        //  构造
        // ==================================================================

        /// <summary>按打包字体目录构造场景。</summary>
        /// <exception cref="DirectoryNotFoundException">字体目录不存在。</exception>
        /// <exception cref="InvalidOperationException">打包字体里找不到 Noto Sans。</exception>
        public static HelloMilScene Create(string fontDirectory)
        {
            if (string.IsNullOrEmpty(fontDirectory) || !Directory.Exists(fontDirectory))
                throw new DirectoryNotFoundException($"打包字体目录不存在：{fontDirectory}");

            MilChannel channel = new MilChannel(null);
            MilChannelResourceProvider provider = new MilChannelResourceProvider(channel);

            FontSet fonts = FontSet.FromDirectory(fontDirectory);
            bool fontsOwned = false;   // TextRenderer 接管后就不能再自己 Dispose

            TextRenderer text = null;
            try
            {
                TextFontDescription regular = TextFontDescription.Regular(FontFamily);
                if (!fonts.TryResolve(regular, out SKTypeface face) || face == null)
                    throw new InvalidOperationException(
                        $"打包字体目录里找不到 {FontFamily}（{fontDirectory}）");

                text = new TextRenderer(fonts, regular, fallbackSize: TextSize);
                fontsOwned = true;     // 所有权转移给 TextRenderer，Dispose 时一起释放

                // 三个接线处：字形钩子（T6）、位图源（0x0c/0x0d），都挂在同一个 provider 上。
                TextRenderer.AttachTo(provider, text);
                MilBitmapSourceTable.AttachTo(provider);

                var context = new RenderContext
                {
                    Width = Width,
                    Height = Height,
                    Dpi = RenderContext.FixedDpi,
                    ClearColor = Background,
                    FontDirectory = fontDirectory,
                    Antialias = true,
                };

                var scene = new HelloMilScene(fontDirectory, channel, provider, text,
                    new SkiaRenderBackend(provider), context);

                // 字形 id 是**字体相关**的：同一段文字在两份字体里 id 完全不同。
                // 所以 shaping 必须用与 TextRenderer 同一份 typeface 来做。
                scene.BuildTree(face);
                return scene;
            }
            catch
            {
                text?.Dispose();                  // 接管了 fonts 时会连带释放
                if (!fontsOwned) fonts.Dispose();  // 没接管成功就自己收尾
                throw;
            }
        }

        private void BuildTree(SKTypeface face)
        {
            // ---------------- 资源登记 ----------------
            DUCE.ResourceHandle red = Register(new MilSolidColorBrush { Color = Rgb(RedFill) });
            DUCE.ResourceHandle teal = Register(new MilSolidColorBrush { Color = Rgb(TealFill) });
            DUCE.ResourceHandle sea = Register(new MilSolidColorBrush { Color = Rgb(SeaGreenFill) });
            DUCE.ResourceHandle orange = Register(new MilSolidColorBrush { Color = Rgb(OrangeFill) });
            DUCE.ResourceHandle crimson = Register(new MilSolidColorBrush { Color = Rgb(CrimsonFill) });
            DUCE.ResourceHandle yellow = Register(new MilSolidColorBrush { Color = Rgb(YellowFill) });
            DUCE.ResourceHandle purple = Register(new MilSolidColorBrush { Color = Rgb(PurpleFill) });
            DUCE.ResourceHandle amber = Register(new MilSolidColorBrush { Color = Rgb(AmberFill) });
            DUCE.ResourceHandle blue = Register(new MilSolidColorBrush { Color = Rgb(BlueStroke) });
            DUCE.ResourceHandle green = Register(new MilSolidColorBrush { Color = Rgb(GreenStroke) });
            DUCE.ResourceHandle dark = Register(new MilSolidColorBrush { Color = Rgb(DarkStroke) });
            DUCE.ResourceHandle ink = Register(new MilSolidColorBrush { Color = Rgb(TextInk) });
            DUCE.ResourceHandle navy = Register(new MilSolidColorBrush { Color = Rgb(TitleNavy) });
            DUCE.ResourceHandle subGray = Register(new MilSolidColorBrush { Color = Rgb(SubtitleGray) });
            DUCE.ResourceHandle labelGray = Register(new MilSolidColorBrush { Color = Rgb(LabelGray) });
            DUCE.ResourceHandle gray = Register(new MilSolidColorBrush { Color = Rgb(OutlineGray) });

            DUCE.ResourceHandle darkPen = Register(new MilPen { Brush = dark, Thickness = 3.0 });
            DUCE.ResourceHandle darkPenThin = Register(new MilPen { Brush = dark, Thickness = 1.5 });
            DUCE.ResourceHandle ellipsePen = Register(new MilPen { Brush = dark, Thickness = EllipseStrokeWidth });
            DUCE.ResourceHandle greenPen = Register(new MilPen { Brush = green, Thickness = 4.0 });
            DUCE.ResourceHandle grayDashPen = Register(new MilPen
            {
                Brush = gray,
                Thickness = 1.5,
                DashStyle = Register(new MilDashStyle { Dashes = { 3.0, 2.0 } }),
            });

            // 三条同色同宽的线，只有 DashStyle 不同（虚线长度是线宽的倍数，见 SkiaPen）。
            DUCE.ResourceHandle solidLinePen = Register(new MilPen { Brush = blue, Thickness = LineThickness });
            DUCE.ResourceHandle dashLinePen = Register(new MilPen
            {
                Brush = blue,
                Thickness = LineThickness,
                DashStyle = Register(new MilDashStyle { Dashes = { 4.0, 2.0 } }),
            });
            DUCE.ResourceHandle dotLinePen = Register(new MilPen
            {
                Brush = blue,
                Thickness = LineThickness,
                DashStyle = Register(new MilDashStyle { Dashes = { 1.0, 1.0 } }),
            });

            // 渐变：绝对映射，起止点/圆心直接是画布坐标。
            DUCE.ResourceHandle linear = Register(MakeLinear(new[]
            {
                (0.0, (byte)0x00, (byte)0x96, (byte)0xC0),   // 青
                (0.5, (byte)0x6E, (byte)0x32, (byte)0xC8),   // 紫
                (1.0, (byte)0xE6, (byte)0x32, (byte)0x96),   // 洋红
            }));

            DUCE.ResourceHandle radial = Register(MakeRadial(new[]
            {
                (0.0, (byte)0xFF, (byte)0xDC, (byte)0x50),   // 中心：亮黄
                (0.55, (byte)0xE6, (byte)0x5A, (byte)0x1E),  // 中环：橙
                (1.0, (byte)0x3C, (byte)0x20, (byte)0x78),   // 外环：深紫
            }));

            // 路径几何：五角星（10 个顶点，一条闭合 figure）。
            byte[] starBytes = BuildStar(StarCenter, StarOuter, StarInner);
            DUCE.ResourceHandle star = Register(new MilPathGeometry
            {
                FillRule = MilFillRule.Nonzero,
                SerializedData = starBytes,
            });

            // 位图源：两张程序化生成的位图，走 0x0c MilCmdBitmapSource 登记。
            DUCE.ResourceHandle checker = RegisterBitmap(MakeCheckerboard(BitmapSize, 6));
            DUCE.ResourceHandle rainbow = RegisterBitmap(MakeSmoothGradient(BitmapSize));

            // ImageBrush：与 MilDrawImage 的棋盘格同源 —— 一条走"图像"，一条走"画刷"。
            // ⚠ Stretch 必须显式给 Fill：MilStretch 枚举默认值是 None(0)，而 WPF 里
            // ImageBrush.Stretch 的**属性默认**是 Fill —— 真实命令流里托管层会显式发送
            // Fill，直接登记资源对象则不会替你填。
            DUCE.ResourceHandle imageBrush = Register(new MilImageBrush
            {
                ImageSource = checker,
                Stretch = MilStretch.Fill,
            });

            // 裁剪：一个矩形几何，把椭圆的右半边切掉。
            DUCE.ResourceHandle clipGeom = Register(new MilRectangleGeometry
            {
                Rect = new MilRect(ClipRect.Left, ClipRect.Top, ClipRect.Width, ClipRect.Height),
            });

            // 效果
            DUCE.ResourceHandle blur = Register(new MilBlurEffect { Radius = BlurRadius });
            DUCE.ResourceHandle shadowA = Register(new MilDropShadowEffect
            {
                ShadowDepth = ShadowDepth,
                Direction = ShadowDirectionA,
                BlurRadius = ShadowBlurRadius,
                Opacity = 1.0,
                Color = Rgb(ShadowRed),
            });
            DUCE.ResourceHandle shadowB = Register(new MilDropShadowEffect
            {
                ShadowDepth = ShadowDepth - 1.0,
                Direction = ShadowDirectionB,
                BlurRadius = ShadowBlurRadius - 1.0,
                Opacity = 1.0,
                Color = Rgb(ShadowBlue),
            });

            // ---------------- 根视觉：12 个格子 + 文本 ----------------
            MilVisual root = new MilVisual { Handle = new MilResourceHandle(0x80000001u) };
            root.Content = Data(list =>
            {
                // 标题
                list.Add(Glyph(navy, face, Title, TitleBaseline, TitleSize));

                // ---- 第 0 行 ----
                // [0,0] 纯色直角矩形
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = SolidRect,
                    Brush = Mh(red),
                });

                // [1,0] 圆角矩形（同尺寸、同位置关系，只有圆角不同）
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRoundedRectangle,
                    Rect = RoundedRect,
                    CornerRadius = RoundedCorner,
                    Brush = Mh(teal),
                    Pen = Mh(darkPen),
                });

                // [2,0] 线性渐变
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = LinearRect,
                    Brush = Mh(linear),
                });

                // [3,0] 径向渐变
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = RadialRect,
                    Brush = Mh(radial),
                });

                // ---- 第 1 行 ----
                // [0,1] 椭圆填充 + 描边
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawEllipse,
                    Point0 = EllipseCenter,
                    CornerRadius = EllipseRadius,
                    Brush = Mh(sea),
                    Pen = Mh(ellipsePen),
                });

                // [1,1] 路径几何：五角星
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawGeometry,
                    Geometry = Mh(star),
                    Brush = Mh(orange),
                    Pen = Mh(darkPen),
                });

                // [2,1] 实线 / 虚线 / 点线（同长同色同宽）
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawLine,
                    Point0 = SolidLineA, Point1 = SolidLineB,
                    Pen = Mh(solidLinePen),
                });
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawLine,
                    Point0 = DashLineA, Point1 = DashLineB,
                    Pen = Mh(dashLinePen),
                });
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawLine,
                    Point0 = DotLineA, Point1 = DotLineB,
                    Pen = Mh(dotLinePen),
                });

                // [3,1] 位图源：两张 MilDrawImage（棋盘格有白格，故加细边框圈出范围）
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawImage,
                    Rect = CheckerRect,
                    Geometry = Mh(checker),
                });
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = CheckerRect,
                    Pen = Mh(darkPenThin),
                });
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawImage,
                    Rect = RainbowRect,
                    Geometry = Mh(rainbow),
                });
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = RainbowRect,
                    Pen = Mh(darkPenThin),
                });

                // [3,1] 画刷链路：同一张棋盘格经 MilImageBrush 填充（默认 TileBrush
                // 语义：Viewbox=整图、Viewport=整个包围盒、Stretch=Fill、TileMode=None），
                // 虚线边框圈出填充范围。与上面 MilDrawImage 的棋盘格逐色可对照。
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = ImageBrushRect,
                    Brush = Mh(imageBrush),
                });
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = ImageBrushRect,
                    Pen = Mh(grayDashPen),
                });

                // ---- 第 2 行 ----
                // [0,2] 清晰 vs 模糊（同色同尺寸，右边套 BlurEffect）
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = SharpRect,
                    Brush = Mh(crimson),
                });
                list.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushEffect },
                    PushEffectBytes(Mh(blur)));
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = BlurRect,
                    Brush = Mh(crimson),
                });
                list.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });

                // [1,2] DropShadow：315° 右下（红）/ 135° 左上（蓝）
                list.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushEffect },
                    PushEffectBytes(Mh(shadowA)));
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = ShadowRectA,
                    Brush = Mh(yellow),
                });
                list.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });

                list.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPushEffect },
                    PushEffectBytes(Mh(shadowB)));
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = ShadowRectB,
                    Brush = Mh(yellow),
                });
                list.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });

                // [2,2] 裁剪：椭圆被左边 90px 宽的矩形切掉右半边
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilPushClip,
                    Geometry = Mh(clipGeom),
                });
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawEllipse,
                    Point0 = ClipEllipseCenter,
                    CornerRadius = ClipEllipseRadius,
                    Brush = Mh(purple),
                });
                list.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                // Pop 之后把裁剪框画出来，"切掉"的位置一目了然
                list.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = ClipRect,
                    Pen = Mh(grayDashPen),
                });

                // ---- 标签 ----
                AddLabel(list, labelGray, face, "Solid rect", 0, 0);
                AddLabel(list, labelGray, face, "Rounded rect", 1, 0);
                AddLabel(list, labelGray, face, "Linear gradient", 2, 0);
                AddLabel(list, labelGray, face, "Radial gradient", 3, 0);
                AddLabel(list, labelGray, face, "Ellipse+stroke", 0, 1);
                AddLabel(list, labelGray, face, "Path (star)", 1, 1);
                AddLabel(list, labelGray, face, "Solid vs dash", 2, 1);
                AddLabel(list, labelGray, face, "Bitmap source", 3, 1);
                AddLabel(list, labelGray, face, "Sharp vs blur", 0, 2);
                AddLabel(list, labelGray, face, "Drop shadow", 1, 2);
                AddLabel(list, labelGray, face, "Clipped", 2, 2);
                AddLabel(list, labelGray, face, "Nested transform", 3, 2);

                // ---- 底部文本 ----
                list.Add(Glyph(ink, face, Greeting, TextBaseline, TextSize));
                list.Add(Glyph(subGray, face, Subtitle, SubtitleBaseline, SubtitleSize));
            });

            // ---------------- 子视觉：嵌套变换（父平移 → 子缩放 + 旋转）----------------
            //
            // 行向量约定：Concat(a, b) = a·b，含义是"先 a 后 b"。
            // 父 Visual 只做平移，子 Visual 先缩放再旋转，两者由渲染层相乘成世界矩阵。
            // 反过来写（先平移后旋转）会把已经平移出去的点再绕原点转一次，图块会飞到
            // 画布外 —— 这正是"变换链路通不通"最直观的判据。
            MilVisual host = new MilVisual { Handle = new MilResourceHandle(0x80000002u) };
            host.Transform = SKMatrix.CreateTranslation(NestedHostOrigin.X, NestedHostOrigin.Y);
            host.Content = Data(list => list.Add(new MilDrawInstruction
            {
                // 未旋转的对照轮廓：与旋转后的 amber 块同中心、同大小。
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = TransformedGhost,
                Pen = Mh(grayDashPen),
            }));

            MilVisual spin = new MilVisual { Handle = new MilResourceHandle(0x80000003u) };
            spin.Transform = NestedChildTransform();
            spin.Content = Data(list => list.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRoundedRectangle,
                Rect = TransformedRect,
                CornerRadius = TransformedCornerRadius,
                Brush = Mh(amber),
                Pen = Mh(greenPen),
            }));

            host.Children.Add(spin);
            root.Children.Add(host);

            _root = root;
        }

        /// <summary>
        /// 子 Visual 的本地变换：先缩放、再旋转，最后平移到"缩放旋转之后的矩形中心
        /// 正好落在 <see cref="NestedTargetCenter"/>"。最后一步的平移量由矩阵算出来，
        /// 不写死 —— 改缩放或角度时图块不会跑偏。
        /// </summary>
        private static SKMatrix NestedChildTransform()
        {
            SKMatrix scaleRotate = SKMatrix.Concat(
                SKMatrix.CreateScale(NestedScale, NestedScale),
                SKMatrix.CreateRotationDegrees(NestedRotationDegrees));

            SKPoint localCenter = new SKPoint(TransformedRect.MidX, TransformedRect.MidY);
            SKPoint mapped = scaleRotate.MapPoint(localCenter);

            return SKMatrix.Concat(
                scaleRotate,
                SKMatrix.CreateTranslation(
                    NestedTargetCenter.X - mapped.X,
                    NestedTargetCenter.Y - mapped.Y));
        }

        // ==================================================================
        //  渲染
        // ==================================================================

        /// <summary>离屏渲染一帧，返回不可变的 SKImage（调用方负责 Dispose）。</summary>
        public SKImage Render()
        {
            ThrowIfDisposed();

            var info = new SKImageInfo(Width, Height, SKColorType.Rgba8888, SKAlphaType.Premul);
            using (SKSurface surface = SKSurface.Create(info))
            {
                if (surface == null)
                    throw new InvalidOperationException("SKSurface.Create 失败（Skia CPU 后端不可用）");

                _backend.RenderVisualTree(_root, surface.Canvas, _context);

                // 诊断必须在下一次 Render 之前读走 —— 后端每帧开头会把计数清零。
                InstructionCount = _backend.Diagnostics.InstructionCount;
                GlyphRunSkipped = _backend.Diagnostics.NotDrawn.ContainsKey(MilDrawCommand.MilDrawGlyphRun);
                NotDrawnCount = 0;
                foreach (KeyValuePair<MilDrawCommand, long> kv in _backend.Diagnostics.NotDrawn)
                    NotDrawnCount += kv.Value;

                ImageBrushFillNotDrawn = NotDrawnCount == 1
                    && _backend.Diagnostics.NotDrawn.TryGetValue(
                        MilDrawCommand.MilDrawRectangle, out long n) && n == 1;

                surface.Flush();
                return surface.Snapshot();
            }
        }

        /// <summary>渲染一帧并转成位图（调用方负责 Dispose）。</summary>
        public SKBitmap RenderBitmap()
        {
            using SKImage image = Render();
            return SKBitmap.FromImage(image);
        }

        /// <summary>
        /// 渲染一帧并返回其 PNG 字节的 SHA256。用于验证渲染的**确定性**：
        /// 同样的输入（固定 DPI、固定打包字体、固定 AA 开关）必须逐字节一致。
        /// </summary>
        public string RenderHash()
        {
            using SKImage image = Render();
            using SKData data = image.Encode(SKEncodedImageFormat.Png, 100);
            if (data == null) throw new InvalidOperationException("PNG 编码失败");

            return Convert.ToHexString(SHA256.HashData(data.AsSpan()));
        }

        // ==================================================================
        //  程序化位图素材（不下载任何东西，全部按像素算出来）
        // ==================================================================

        /// <summary>四色棋盘格。cells × cells 个方格，四色循环 —— 一眼能看出是位图。</summary>
        public static SKBitmap MakeCheckerboard(int size, int cells)
        {
            var bmp = new SKBitmap(new SKImageInfo(size, size, SKColorType.Rgba8888, SKAlphaType.Premul));
            int cell = Math.Max(1, size / cells);

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    int index = ((y / cell) % 2) * 2 + ((x / cell) % 2);
                    SKColor c = index switch
                    {
                        0 => new SKColor(0x1E, 0x50, 0xC8),   // 蓝
                        1 => new SKColor(0xF2, 0xF2, 0xF2),   // 白
                        2 => new SKColor(0xD8, 0x30, 0x30),   // 红
                        _ => new SKColor(0xF0, 0xC0, 0x20),   // 黄
                    };
                    bmp.SetPixel(x, y, c);
                }
            }

            return bmp;
        }

        /// <summary>双通道平滑渐变：R 随 x、G 随 y、B 反向 —— 证明位图是逐像素内容。</summary>
        public static SKBitmap MakeSmoothGradient(int size)
        {
            var bmp = new SKBitmap(new SKImageInfo(size, size, SKColorType.Rgba8888, SKAlphaType.Premul));

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    bmp.SetPixel(x, y, new SKColor(
                        (byte)(255 * x / (size - 1)),
                        (byte)(255 * y / (size - 1)),
                        (byte)(255 - 255 * x / (size - 1))));
                }
            }

            return bmp;
        }

        // ==================================================================
        //  内部工具
        // ==================================================================

        private DUCE.ResourceHandle Register(MilResource resource)
        {
            DUCE.ResourceHandle handle = DUCE.ResourceHandle.Null;
            _channel.Resources.Duplicate(resource, ref handle);
            return handle;
        }

        /// <summary>
        /// 登记一张位图源：先领令牌（所有权转移给登记表），再用 0x0c MilCmdBitmapSource
        /// 的语义把它挂到一个 TYPE_BITMAPSOURCE 资源上。渲染层经 BitmapResolver 取回。
        /// </summary>
        private DUCE.ResourceHandle RegisterBitmap(SKBitmap bitmap)
        {
            ulong token = MilBitmapSourceTable.Register(bitmap);
            if (token == 0)
                throw new InvalidOperationException("位图令牌登记失败（位图为空或尺寸非正）");

            MilResource resource = new MilOpaqueResource(DUCE.ResourceType.TYPE_BITMAPSOURCE);
            DUCE.ResourceHandle handle = Register(resource);

            int hr = MilBitmapSourceTable.ProcessSource(resource, token);
            if (hr != HResult.S_OK)
                throw new InvalidOperationException($"MilCmdBitmapSource 失败（hr=0x{hr:x8}）");

            return handle;
        }

        private MilResourceHandle Mh(DUCE.ResourceHandle h) => new MilResourceHandle((uint)h);

        private MilLinearGradientBrush MakeLinear((double Pos, byte R, byte G, byte B)[] stops)
        {
            var brush = new MilLinearGradientBrush
            {
                StartPoint = new MilPoint(LinearStart.X, LinearStart.Y),
                EndPoint = new MilPoint(LinearEnd.X, LinearEnd.Y),
                MappingMode = MilBrushMappingMode.Absolute,
                SpreadMethod = MilGradientSpreadMethod.Pad,
            };
            AddStops(brush.GradientStops, stops);
            return brush;
        }

        private MilRadialGradientBrush MakeRadial((double Pos, byte R, byte G, byte B)[] stops)
        {
            var brush = new MilRadialGradientBrush
            {
                Center = new MilPoint(RadialCenter.X, RadialCenter.Y),
                GradientOrigin = new MilPoint(RadialCenter.X, RadialCenter.Y),
                RadiusX = RadialRadius,
                RadiusY = RadialRadius,
                MappingMode = MilBrushMappingMode.Absolute,
                SpreadMethod = MilGradientSpreadMethod.Pad,
            };
            AddStops(brush.GradientStops, stops);
            return brush;
        }

        private static void AddStops(
            List<MilGradientStop> target, (double Pos, byte R, byte G, byte B)[] stops)
        {
            foreach ((double pos, byte r, byte g, byte b) in stops)
                target.Add(new MilGradientStop(pos, SkiaColor.MakeScRgb(r, g, b, 255)));
        }

        /// <summary>五角星的序列化几何：10 个顶点（外/内交替），一条闭合 figure。</summary>
        private static byte[] BuildStar(SKPoint center, float outer, float inner)
        {
            var pts = new SKPoint[10];
            for (int k = 0; k < 10; k++)
            {
                double deg = -90.0 + k * 36.0;
                double rad = deg * Math.PI / 180.0;
                float r = (k % 2 == 0) ? outer : inner;
                pts[k] = new SKPoint(
                    center.X + (float)(Math.Cos(rad) * r),
                    center.Y + (float)(Math.Sin(rad) * r));
            }

            PathGeometryBuilder.Figure figure =
                new PathGeometryBuilder().AddFigure(pts[0].X, pts[0].Y, isClosed: true);
            for (int k = 1; k < 10; k++) figure.Line(pts[k].X, pts[k].Y);

            return figure.End().Build();
        }

        private MilDrawInstruction Glyph(
            DUCE.ResourceHandle brush, SKTypeface face, string text, SKPoint baseline, float size)
        {
            DUCE.ResourceHandle run = Register(new MilGlyphRun
            {
                Flags = 0,                     // Sideways(0x1) / HasOffsets(0x10) 均未置位
                Origin = new MilPoint2F(baseline.X, baseline.Y),
                MuSize = size,
                BidiLevel = 0,
                GlyphIndices = face.GetGlyphs(text),
                // AdvanceWidths 留空 → GlyphRunLayout 回落到字体自身的度量。
            });

            return new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawGlyphRun,
                Brush = Mh(brush),
                Geometry = Mh(run),
            };
        }

        private void AddLabel(
            DrawList list, DUCE.ResourceHandle brush, SKTypeface face, string text, int col, int row)
        {
            SKRect cell = Cell(col, row);
            list.Add(Glyph(brush, face, text,
                new SKPoint(cell.Left + 10, cell.Top + LabelDrop), LabelSize));
        }

        /// <summary>
        /// MilPushEffect 的 8 字节载荷：hEffect@0 + hEffectInput@4。
        /// 后端只从原始字节里读 hEffect（*Animate / Effect 系列不走强类型字段）。
        /// </summary>
        private static byte[] PushEffectBytes(MilResourceHandle hEffect)
        {
            var bytes = new byte[8];
            BitConverter.GetBytes(hEffect.Value).CopyTo(bytes, 0);
            return bytes;
        }

        private MilRenderData Data(Action<DrawList> build)
        {
            var list = new DrawList();
            build(list);

            var data = new MilRenderData();
            for (int i = 0; i < list.Items.Count; i++)
            {
                // RawPayloads 与 InstructionList 必须一一对应：后端按下标取原始字节，
                // 少一条会让 *Animate / Effect 之类的指令读到错位的数据。
                data.RawPayloads.Add(list.Raw[i]);
                data.InstructionList.Add(list.Items[i]);
            }

            return data;
        }

        /// <summary>sRGB 字节 → MilColorF（scRGB）。画刷颜色走的是 scRGB 通道。</summary>
        private static MilColorF Rgb(SKColor color) =>
            SkiaColor.MakeScRgb(color.Red, color.Green, color.Blue, color.Alpha);

        private void ThrowIfDisposed()
        {
            if (_disposed) throw new ObjectDisposedException(nameof(HelloMilScene));
        }

        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;
            _text.Dispose();     // 同时释放它接管的 FontSet
        }

        /// <summary>指令列表构造器：每条指令可附带原始字节（MilPushEffect 需要）。</summary>
        private sealed class DrawList
        {
            public readonly List<MilDrawInstruction> Items = new List<MilDrawInstruction>();
            public readonly List<byte[]> Raw = new List<byte[]>();

            public void Add(MilDrawInstruction instr, byte[] raw = null)
            {
                Items.Add(instr);
                Raw.Add(raw ?? Array.Empty<byte>());
            }
        }
    }
}

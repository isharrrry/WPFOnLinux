// 渲染测试的场景构造器：资源表 + 视觉树 + 指令流。
//
// 【为什么走真实 MilChannel 而不是自己 mock 一张表】
//   渲染层拿到的画刷/画笔/几何全是句柄，句柄要靠 MilResourceTable 解析，变换还要
//   靠 TransformResolver（Resources/）递归解 TransformGroup。如果用 mock，测的就是
//   "我的 mock 和我的一致"，不是"渲染层和资源层对得上"。所以这里建一个真的
//   MilChannel，用 MilResourceTable.Duplicate 把**具体类型**的资源塞进表里——
//   这样 TransformResolver / VisualProjection 也一起被覆盖到了。
//
// 【指令流为什么直接构造 MilDrawInstruction】
//   RenderData 的字节解码归 T3（已有 221 条用例覆盖），本工程测的是 T4 的"执行"。
//   MilRenderData 同时暴露 InstructionList（强类型）和 RawPayloads（原始字节），
//   两条路都能喂，*Animate 用例走原始字节那条。

using System;
using System.Collections.Generic;
using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;

namespace WpfGfx.Linux.Tests.Rendering
{
    /// <summary>一个可渲染的场景：通道 + 资源提供者 + 构造辅助。</summary>
    internal sealed class TestScene : IDisposable
    {
        private readonly List<IDisposable> _owned = new List<IDisposable>();

        public MilChannel Channel { get; } = new MilChannel(null);
        public MilChannelResourceProvider Provider { get; }
        public SkiaRenderBackend Backend { get; }

        public TestScene()
        {
            Provider = new MilChannelResourceProvider(Channel);
            Backend = new SkiaRenderBackend(Provider);
        }

        // ---------------- 资源登记 ----------------

        /// <summary>把一个具体类型的资源放进资源表，返回它的句柄。</summary>
        public DUCE.ResourceHandle Add(MilResource resource)
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            Channel.Resources.Duplicate(resource, ref h);
            return h;
        }

        public MilResourceHandle Mh(DUCE.ResourceHandle h) => new MilResourceHandle((uint)h);
        public MilResourceHandle Mh(MilResource resource) => Mh(Add(resource));

        /// <summary>登记资源并返回强类型句柄（一步到位）。</summary>
        public DUCE.ResourceHandle Handle(MilResource resource) => Add(resource);

        // ---------------- 画刷 ----------------

        public DUCE.ResourceHandle Solid(byte r, byte g, byte b, byte a = 255) =>
            Add(new MilSolidColorBrush { Color = SkiaColor.MakeScRgb(r, g, b, a) });

        public DUCE.ResourceHandle SolidWithOpacity(byte r, byte g, byte b, double opacity) =>
            Add(new MilSolidColorBrush { Color = SkiaColor.MakeScRgb(r, g, b, 255), Opacity = opacity });

        /// <summary>线性渐变。点用绝对坐标（MappingMode.Absolute）。</summary>
        public DUCE.ResourceHandle LinearGradient(
            double x0, double y0, double x1, double y1,
            params (double Pos, byte R, byte G, byte B)[] stops)
        {
            var brush = new MilLinearGradientBrush
            {
                StartPoint = new MilPoint(x0, y0),
                EndPoint = new MilPoint(x1, y1),
                MappingMode = MilBrushMappingMode.Absolute,
                SpreadMethod = MilGradientSpreadMethod.Pad,
            };
            AddStops(brush.GradientStops, stops);
            return Add(brush);
        }

        /// <summary>线性渐变，RelativeToBoundingBox 模式（画刷坐标按包围盒归一化）。</summary>
        public DUCE.ResourceHandle LinearGradientRelative(
            double x0, double y0, double x1, double y1,
            params (double Pos, byte R, byte G, byte B)[] stops)
        {
            var brush = new MilLinearGradientBrush
            {
                StartPoint = new MilPoint(x0, y0),
                EndPoint = new MilPoint(x1, y1),
                MappingMode = MilBrushMappingMode.RelativeToBoundingBox,
                SpreadMethod = MilGradientSpreadMethod.Pad,
            };
            AddStops(brush.GradientStops, stops);
            return Add(brush);
        }

        public DUCE.ResourceHandle RadialGradient(
            double cx, double cy, double rx, double ry, double ox, double oy,
            params (double Pos, byte R, byte G, byte B)[] stops)
        {
            var brush = new MilRadialGradientBrush
            {
                Center = new MilPoint(cx, cy),
                GradientOrigin = new MilPoint(ox, oy),
                RadiusX = rx,
                RadiusY = ry,
                MappingMode = MilBrushMappingMode.Absolute,
                SpreadMethod = MilGradientSpreadMethod.Pad,
            };
            AddStops(brush.GradientStops, stops);
            return Add(brush);
        }

        private static void AddStops(
            List<MilGradientStop> target, (double Pos, byte R, byte G, byte B)[] stops)
        {
            foreach ((double pos, byte r, byte g, byte b) in stops)
                target.Add(new MilGradientStop(pos, SkiaColor.MakeScRgb(r, g, b, 255)));
        }

        // ---------------- 画笔 ----------------

        public DUCE.ResourceHandle Pen(
            DUCE.ResourceHandle brush, double thickness = 1.0,
            MilPenLineCap cap = MilPenLineCap.Flat,
            MilPenLineJoin join = MilPenLineJoin.Miter,
            DUCE.ResourceHandle dashStyle = default) =>
            Add(new MilPen
            {
                Brush = brush,
                Thickness = thickness,
                StartLineCap = cap,
                EndLineCap = cap,
                LineJoin = join,
                DashStyle = dashStyle,
            });

        public DUCE.ResourceHandle DashStyle(double offset, params double[] dashes)
        {
            var style = new MilDashStyle { Offset = offset };
            foreach (double d in dashes) style.Dashes.Add(d);
            return Add(style);
        }

        // ---------------- 位图源 / ImageBrush ----------------

        /// <summary>位图源占位句柄（TYPE_BITMAPSOURCE）。渲染侧经 Provider.BitmapResolver
        /// 解析成 SKBitmap——测试里把解析器挂成"该句柄 → 你给的位图"即可。</summary>
        public DUCE.ResourceHandle BitmapSourceHandle() =>
            Add(new MilOpaqueResource(DUCE.ResourceType.TYPE_BITMAPSOURCE));

        /// <summary>ImageBrush。TileBrush 字段全部显式传入：MilStretch/MilTileMode 的
        /// 枚举默认值是 None(0)，与 WPF 属性默认值（Stretch=Fill）不同，别依赖默认值。</summary>
        public DUCE.ResourceHandle ImageBrush(
            DUCE.ResourceHandle bitmap,
            MilStretch stretch = MilStretch.Fill,
            MilTileMode tileMode = MilTileMode.None,
            MilRect? viewbox = null,
            MilRect? viewport = null,
            MilBrushMappingMode viewportUnits = MilBrushMappingMode.Absolute,
            MilBrushMappingMode viewboxUnits = MilBrushMappingMode.Absolute,
            MilAlignmentX alignmentX = MilAlignmentX.Center,
            MilAlignmentY alignmentY = MilAlignmentY.Center) =>
            Add(new MilImageBrush
            {
                ImageSource = bitmap,
                Stretch = stretch,
                TileMode = tileMode,
                Viewbox = viewbox ?? MilRect.Empty,
                Viewport = viewport ?? MilRect.Empty,
                ViewportUnits = viewportUnits,
                ViewboxUnits = viewboxUnits,
                AlignmentX = alignmentX,
                AlignmentY = alignmentY,
            });

        /// <summary>让场景替你持有可释放对象（渲染期间必须存活，场景 Dispose 时释放）。</summary>
        public T Own<T>(T disposable) where T : IDisposable
        {
            _owned.Add(disposable);
            return disposable;
        }

        /// <summary>四色棋盘格（蓝/白格/红/黄，每格 size/cells 像素），与 HelloMil 同款。</summary>
        public static SKBitmap MakeCheckerboard(int size, int cells)
        {
            var bmp = new SKBitmap(new SKImageInfo(size, size, SKColorType.Rgba8888, SKAlphaType.Premul));
            int cell = Math.Max(1, size / cells);
            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    int i = ((y / cell) % 2) * 2 + ((x / cell) % 2);
                    bmp.SetPixel(x, y, i switch
                    {
                        0 => new SKColor(0x1E, 0x50, 0xC8),   // 蓝
                        1 => new SKColor(0xF2, 0xF2, 0xF2),   // 白格
                        2 => new SKColor(0xD8, 0x30, 0x30),   // 红
                        _ => new SKColor(0xF0, 0xC0, 0x20),   // 黄
                    });
                }
            }
            return bmp;
        }

        // ---------------- 变换 ----------------

        public DUCE.ResourceHandle Translate(double x, double y) =>
            Add(new MilTranslateTransform { X = x, Y = y });

        public DUCE.ResourceHandle Rotate(double angle, double cx = 0, double cy = 0) =>
            Add(new MilRotateTransform { Angle = angle, CenterX = cx, CenterY = cy });

        public DUCE.ResourceHandle Scale(double sx, double sy = 0, double cx = 0, double cy = 0) =>
            Add(new MilScaleTransform { ScaleX = sx, ScaleY = sy == 0 ? sx : sy, CenterX = cx, CenterY = cy });

        public DUCE.ResourceHandle Matrix(double m11, double m12, double m21, double m22, double dx, double dy) =>
            Add(new MilMatrixTransform { Matrix = new MilMatrix3x2D(m11, m12, m21, m22, dx, dy) });

        public DUCE.ResourceHandle TransformGroup(params DUCE.ResourceHandle[] children)
        {
            var g = new MilTransformGroup();
            foreach (DUCE.ResourceHandle c in children) g.Children.Add(c);
            return Add(g);
        }

        // ---------------- 几何 ----------------

        public DUCE.ResourceHandle RectGeometry(double x, double y, double w, double h) =>
            Add(new MilRectangleGeometry { Rect = new MilRect(x, y, w, h) });

        public DUCE.ResourceHandle EllipseGeometry(double cx, double cy, double rx, double ry) =>
            Add(new MilEllipseGeometry { Center = new MilPoint(cx, cy), RadiusX = rx, RadiusY = ry });

        /// <summary>PathGeometry：直接喂序列化字节（与 MilCmdPathGeometry 载荷同构）。</summary>
        public DUCE.ResourceHandle PathGeometry(byte[] serialized, MilFillRule fillRule = MilFillRule.Nonzero) =>
            Add(new MilPathGeometry { SerializedData = serialized, FillRule = fillRule });

        // ---------------- 视觉树 ----------------

        public MilVisual Visual() => new MilVisual { Handle = new MilResourceHandle(0x80000001u) };

        /// <summary>构造一段 RenderData（强类型指令 + 可选原始字节）。</summary>
        public MilRenderData RenderData(Action<DrawList> build)
        {
            var list = new DrawList();
            build(list);
            return list.ToRenderData();
        }

        public void Dispose()
        {
            foreach (IDisposable d in _owned) d.Dispose();
            _owned.Clear();
        }
    }

    /// <summary>指令列表构造器：每条指令可附带原始字节（*Animate 变体需要）。</summary>
    internal sealed class DrawList
    {
        private readonly List<MilDrawInstruction> _instr = new List<MilDrawInstruction>();
        private readonly List<byte[]> _raw = new List<byte[]>();

        public DrawList Add(MilDrawInstruction instr, byte[] raw = null)
        {
            _instr.Add(instr);
            _raw.Add(raw ?? Array.Empty<byte>());
            return this;
        }

        public MilRenderData ToRenderData()
        {
            var rd = new MilRenderData();
            for (int i = 0; i < _instr.Count; i++)
            {
                rd.RawPayloads.Add(_raw[i]);
                rd.InstructionList.Add(_instr[i]);
            }
            return rd;
        }
    }
}

// Licensed to the .NET Foundation under one or more agreements.
//
// 命令 round-trip 测试：构造 → 编码 → 解码 → 断言结构等价。
//
// 每条命令做两层断言：
//   (A) 字节层：Encode(值) → MemoryMarshal.Read<线格结构体>() 后字段相等。
//       编码器的偏移常量与结构体的 FieldOffset 是两份独立誊写的数据，
//       任一侧写错这层就红。
//   (B) 语义层：Dispatch(字节) 后资源表里的对象状态等于原值。
//       这层证明解码器把字段接到了正确的资源字段上。
//
// 注意 (A)+(B) 都过并不等于布局与 Windows 上的真实 MIL 一致——
// 编解码两侧可以「一起错」（渐变步长 16/24 的 bug 就是这样蒙过 round-trip 的）。
// 与上游 FieldOffset 的比对由 CommandLayoutTests + tools/verify-cmd-layout.py 负责。

using System;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;
using S = WpfGfx.Linux.Commands.MilCommandStructs;

namespace WpfGfx.Linux.Tests.Commands
{
    public class CommandRoundTripTests
    {
        // ============ 1. Visual：偏移 ============

        [Fact]
        public void RoundTrip_VisualSetOffset()
        {
            var ch = new TestChannel();
            MilVisualResource v = ch.Create<MilVisualResource>(DUCE.ResourceType.TYPE_VISUAL, out var h);

            byte[] cmd = MilCommandEncoder.VisualSetOffset(h, 12.5, -3.25);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VISUAL_SETOFFSET>(cmd);
            Assert.Equal(MilCmd.MilCmdVisualSetOffset, s.Type);
            Assert.Equal(h, s.Handle);
            Assert.Equal(12.5, s.OffsetX);
            Assert.Equal(-3.25, s.OffsetY);

            ch.Send(cmd);
            Assert.Equal(12.5, v.Visual.OffsetX);
            Assert.Equal(-3.25, v.Visual.OffsetY);
        }

        // ============ 2. Visual：alpha ============

        [Fact]
        public void RoundTrip_VisualSetAlpha()
        {
            var ch = new TestChannel();
            MilVisualResource v = ch.Create<MilVisualResource>(DUCE.ResourceType.TYPE_VISUAL, out var h);

            byte[] cmd = MilCommandEncoder.VisualSetAlpha(h, 0.375);
            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VISUAL_SETALPHA>(cmd);
            Assert.Equal(0.375, s.Alpha);

            ch.Send(cmd);
            Assert.Equal(0.375, v.Visual.Alpha);
        }

        // ============ 3. Visual：句柄型字段（transform/clip/content/effect/cacheMode/alphaMask） ============

        [Fact]
        public void RoundTrip_VisualSetHandleFields()
        {
            var ch = new TestChannel();
            MilVisualResource v = ch.Create<MilVisualResource>(DUCE.ResourceType.TYPE_VISUAL, out var h);
            var transform = ch.Create(DUCE.ResourceType.TYPE_MATRIXTRANSFORM);
            var clip = ch.Create(DUCE.ResourceType.TYPE_RECTANGLEGEOMETRY);
            var content = ch.Create(DUCE.ResourceType.TYPE_RENDERDATA);
            var effect = ch.Create(DUCE.ResourceType.TYPE_BLUREFFECT);
            var cache = ch.Create(DUCE.ResourceType.TYPE_BITMAPCACHE);
            var mask = ch.Create(DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH);

            ch.Send(MilCommandEncoder.VisualSetTransform(h, transform));
            ch.Send(MilCommandEncoder.VisualSetClip(h, clip));
            ch.Send(MilCommandEncoder.VisualSetContent(h, content));
            ch.Send(MilCommandEncoder.VisualSetEffect(h, effect));
            ch.Send(MilCommandEncoder.VisualSetCacheMode(h, cache));
            ch.Send(MilCommandEncoder.VisualSetAlphaMask(h, mask));

            Assert.Equal(transform, v.Visual.Transform);
            Assert.Equal(clip, v.Visual.Clip);
            Assert.Equal(content, v.Visual.Content);
            Assert.Equal(effect, v.Visual.Effect);
            Assert.Equal(cache, v.Visual.CacheMode);
            Assert.Equal(mask, v.Visual.AlphaMask);
        }

        // ============ 4. Visual：子节点增删（Z 序） ============

        [Fact]
        public void RoundTrip_VisualChildren()
        {
            var ch = new TestChannel();
            MilVisualResource root = ch.Create<MilVisualResource>(DUCE.ResourceType.TYPE_VISUAL, out var h);
            var a = ch.Create(DUCE.ResourceType.TYPE_VISUAL);
            var b = ch.Create(DUCE.ResourceType.TYPE_VISUAL);
            var c = ch.Create(DUCE.ResourceType.TYPE_VISUAL);

            ch.Send(MilCommandEncoder.VisualInsertChildAt(h, a, 0));
            ch.Send(MilCommandEncoder.VisualInsertChildAt(h, b, 1));
            ch.Send(MilCommandEncoder.VisualInsertChildAt(h, c, 1));   // 插到中间
            Assert.Equal(new[] { a, b, c }.Length, root.Visual.Children.Count);
            Assert.Equal(a, root.Visual.Children[0]);
            Assert.Equal(c, root.Visual.Children[1]);
            Assert.Equal(b, root.Visual.Children[2]);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VISUAL_INSERTCHILDAT>(
                MilCommandEncoder.VisualInsertChildAt(h, a, 7));
            Assert.Equal(7u, s.Index);

            ch.Send(MilCommandEncoder.VisualRemoveChild(h, c));
            Assert.Equal(2, root.Visual.Children.Count);
            Assert.Equal(new[] { a, b }[1], root.Visual.Children[1]);

            ch.Send(MilCommandEncoder.VisualRemoveAllChildren(h));
            Assert.Empty(root.Visual.Children);
        }

        // ============ 5. Visual：变长 float 尾部（GuidelineCollection） ============

        [Fact]
        public void RoundTrip_VisualSetGuidelineCollection_变长尾部()
        {
            var ch = new TestChannel();
            MilVisualResource v = ch.Create<MilVisualResource>(DUCE.ResourceType.TYPE_VISUAL, out var h);

            float[] x = { 1f, 2.5f, 7f };
            float[] y = { -4f, 0.5f };
            byte[] cmd = MilCommandEncoder.VisualSetGuidelineCollection(h, x, y);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VISUAL_SETGUIDELINECOLLECTION>(cmd);
            Assert.Equal(3, s.CountX);
            Assert.Equal(2, s.CountY);
            Assert.Equal(16 + (3 + 2) * 4, cmd.Length);

            ch.Send(cmd);
            Assert.Equal(x, v.Visual.GuidelinesX);
            Assert.Equal(y, v.Visual.GuidelinesY);
        }

        // ============ 6. Visual：渲染选项 + 可滚动裁剪 ============

        [Fact]
        public void RoundTrip_VisualSetRenderOptionsAndScrollableAreaClip()
        {
            var ch = new TestChannel();
            MilVisualResource v = ch.Create<MilVisualResource>(DUCE.ResourceType.TYPE_VISUAL, out var h);

            var opts = new MilRenderOptions
            {
                Flags = MilRenderOptionFlags.EdgeMode | MilRenderOptionFlags.TextRenderingMode,
                EdgeMode = MilEdgeMode.Aliased,
                CompositingMode = MilCompositingMode.SourceOver,
                BitmapScalingMode = MilBitmapScalingMode.NearestNeighbor,
                ClearTypeHint = MilClearTypeHint.Enabled,
                TextRenderingMode = MilTextRenderingMode.Aliased,
                TextHintingMode = MilTextHintingMode.Fixed,
            };
            ch.Send(MilCommandEncoder.VisualSetRenderOptions(h, opts));
            Assert.True(opts.Equals(v.Visual.RenderOptions));

            var clip = new MilRect(1, 2, 30, 40);
            byte[] cmd = MilCommandEncoder.VisualSetScrollableAreaClip(h, clip, true);
            var s = MilCommandDecoder.ReadFixed<S.MILCMD_VISUAL_SETSCROLLABLEAREACLIP>(cmd);
            Assert.True(clip.Equals(s.Clip));
            Assert.Equal(1u, s.IsEnabled);

            ch.Send(cmd);
            Assert.True(clip.Equals(v.Visual.ScrollableAreaClip));
            Assert.True(v.Visual.ScrollableAreaClipEnabled);
        }

        // ============ 7. Target：SetRoot / ClearColor / Invalidate / Flags ============

        [Fact]
        public void RoundTrip_Target()
        {
            var ch = new TestChannel();
            MilHwndTarget t = ch.Create<MilHwndTarget>(DUCE.ResourceType.TYPE_HWNDRENDERTARGET, out var ht);
            var root = ch.Create(DUCE.ResourceType.TYPE_VISUAL);

            ch.Send(MilCommandEncoder.TargetSetRoot(ht, root));
            Assert.Equal(root, t.Root);

            var color = new MilColorF(0.25f, 0.5f, 0.75f, 1f);
            byte[] cc = MilCommandEncoder.TargetSetClearColor(ht, color);
            Assert.True(color.Equals(MilCommandDecoder.ReadFixed<S.MILCMD_TARGET_SETCLEARCOLOR>(cc).ClearColor));
            ch.Send(cc);
            Assert.True(color.Equals(t.ClearColor));

            var rc = new MilRectI(3, 4, 103, 204);
            byte[] inv = MilCommandEncoder.TargetInvalidate(ht, rc);
            Assert.True(rc.Equals(MilCommandDecoder.ReadFixed<S.MILCMD_TARGET_INVALIDATE>(inv).Rc));
            ch.Send(inv);
            Assert.True(rc.Equals(t.InvalidRect));
            Assert.Equal(1, t.InvalidateCount);

            ch.Send(MilCommandEncoder.TargetSetFlags(ht, 0x3));
            Assert.Equal(0x3u, t.Flags);
        }

        // ============ 8. Target：HwndTargetCreate（92 字节头） ============

        [Fact]
        public void RoundTrip_HwndTargetCreate()
        {
            var ch = new TestChannel();
            MilHwndTarget t = ch.Create<MilHwndTarget>(DUCE.ResourceType.TYPE_HWNDRENDERTARGET, out var ht);

            var clear = new MilColorF(0f, 0f, 0f, 1f);
            byte[] cmd = MilCommandEncoder.HwndTargetCreate(
                ht, hwnd: 0xDEADBEEF, hSection: 0, masterDevice: 0,
                width: 800, height: 600, clearColor: clear, flags: 1,
                hBitmap: DUCE.ResourceHandle.Null, stride: 3200, pixelFormat: 0x1c,
                dpiAwarenessContext: 0, dpiX: 96.0, dpiY: 120.0);

            Assert.Equal(92, MilCommandLayout.FixedSize(MilCmd.MilCmdHwndTargetCreate));
            var s = MilCommandDecoder.ReadFixed<S.MILCMD_HWNDTARGET_CREATE>(cmd);
            Assert.Equal(0xDEADBEEFul, s.Hwnd);
            Assert.Equal(800u, s.Width);
            Assert.Equal(600u, s.Height);
            Assert.Equal(3200u, s.Stride);
            Assert.Equal(96.0, s.DpiX);
            Assert.Equal(120.0, s.DpiY);

            ch.Send(cmd);
            Assert.Equal(new IntPtr(unchecked((long)0xDEADBEEF)), t.NativeWindow);
            Assert.Equal(800u, t.Width);
            Assert.Equal(600u, t.Height);
            Assert.Equal(3200u, t.Stride);
            Assert.Equal(120.0, t.DpiY);
            Assert.True(clear.Equals(t.ClearColor));
        }

        // ============ 9. 画刷：SolidColorBrush ============

        [Fact]
        public void RoundTrip_SolidColorBrush()
        {
            var ch = new TestChannel();
            MilSolidColorBrush brush = ch.Create<MilSolidColorBrush>(DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH, out var h);
            var transform = ch.Create(DUCE.ResourceType.TYPE_MATRIXTRANSFORM);

            var color = new MilColorF(1f, 0.5f, 0.25f, 0.75f);
            byte[] cmd = MilCommandEncoder.SolidColorBrush(h, color, 0.5, transform);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_SOLIDCOLORBRUSH>(cmd);
            Assert.Equal(0.5, s.Opacity);
            Assert.True(color.Equals(s.Color));
            Assert.Equal(transform, s.HTransform);

            ch.Send(cmd);
            Assert.Equal(0.5, brush.Opacity);
            Assert.True(color.Equals(brush.Color));
            Assert.Equal(transform, brush.Transform);
        }

        // ============ 10. 画刷：LinearGradientBrush（24 字节步长的变长尾部） ============

        [Fact]
        public void RoundTrip_LinearGradientBrush_渐变步长24()
        {
            var ch = new TestChannel();
            MilLinearGradientBrush brush = ch.Create<MilLinearGradientBrush>(
                DUCE.ResourceType.TYPE_LINEARGRADIENTBRUSH, out var h);

            var stops = new[]
            {
                new MilGradientStop(0.0, new MilColorF(1f, 0f, 0f, 1f)),
                new MilGradientStop(0.5, new MilColorF(0f, 1f, 0f, 1f)),
                new MilGradientStop(1.0, new MilColorF(0f, 0f, 1f, 1f)),
            };

            byte[] cmd = MilCommandEncoder.LinearGradientBrush(
                h, new MilPoint(0, 0), new MilPoint(1, 1), stops, 0.9,
                MilColorInterpolationMode.ScRgbLinearInterpolation,
                MilBrushMappingMode.Absolute,
                MilGradientSpreadMethod.Reflect);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_LINEARGRADIENTBRUSH>(cmd);
            Assert.Equal(3u * 24u, s.GradientStopsSize);          // 不是 3×16
            Assert.Equal(84 + 3 * 24, cmd.Length);
            Assert.Equal(MilGradientSpreadMethod.Reflect, s.SpreadMethod);
            Assert.Equal(MilBrushMappingMode.Absolute, s.MappingMode);

            ch.Send(cmd);
            Assert.Equal(3, brush.GradientStops.Count);
            for (int i = 0; i < 3; i++)
                Assert.True(stops[i].Equals(brush.GradientStops[i]), $"stop[{i}] 不等");
            Assert.Equal(0.9, brush.Opacity);
            Assert.Equal(MilGradientSpreadMethod.Reflect, brush.SpreadMethod);
        }

        // ============ 11. 画刷：RadialGradientBrush ============

        [Fact]
        public void RoundTrip_RadialGradientBrush()
        {
            var ch = new TestChannel();
            MilRadialGradientBrush brush = ch.Create<MilRadialGradientBrush>(
                DUCE.ResourceType.TYPE_RADIALGRADIENTBRUSH, out var h);

            var stops = new[]
            {
                new MilGradientStop(0.25, new MilColorF(0.1f, 0.2f, 0.3f, 1f)),
                new MilGradientStop(0.75, new MilColorF(0.4f, 0.5f, 0.6f, 0.5f)),
            };

            byte[] cmd = MilCommandEncoder.RadialGradientBrush(
                h, new MilPoint(5, 6), new MilPoint(7, 8), 9.0, 10.0, stops);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_RADIALGRADIENTBRUSH>(cmd);
            Assert.Equal(2u * 24u, s.GradientStopsSize);
            Assert.Equal(108 + 2 * 24, cmd.Length);

            ch.Send(cmd);
            Assert.True(new MilPoint(5, 6).Equals(brush.Center));
            Assert.True(new MilPoint(7, 8).Equals(brush.GradientOrigin));
            Assert.Equal(9.0, brush.RadiusX);
            Assert.Equal(10.0, brush.RadiusY);
            Assert.Equal(2, brush.GradientStops.Count);
            Assert.True(stops[1].Equals(brush.GradientStops[1]));
        }

        // ============ 12. 几何：Rectangle / Ellipse / Line ============

        [Fact]
        public void RoundTrip_Geometry()
        {
            var ch = new TestChannel();
            var transform = ch.Create(DUCE.ResourceType.TYPE_MATRIXTRANSFORM);

            MilRectangleGeometry rect = ch.Create<MilRectangleGeometry>(DUCE.ResourceType.TYPE_RECTANGLEGEOMETRY, out var hr);
            byte[] rcmd = MilCommandEncoder.RectangleGeometry(hr, new MilRect(1, 2, 3, 4), 0.5, 0.75, transform);
            var rs = MilCommandDecoder.ReadFixed<S.MILCMD_RECTANGLEGEOMETRY>(rcmd);
            Assert.Equal(0.5, rs.RadiusX);
            Assert.True(new MilRect(1, 2, 3, 4).Equals(rs.Rect));
            ch.Send(rcmd);
            Assert.Equal(0.5, rect.RadiusX);
            Assert.Equal(0.75, rect.RadiusY);
            Assert.True(new MilRect(1, 2, 3, 4).Equals(rect.Rect));
            Assert.Equal(transform, rect.Transform);

            MilEllipseGeometry ell = ch.Create<MilEllipseGeometry>(DUCE.ResourceType.TYPE_ELLIPSEGEOMETRY, out var he);
            ch.Send(MilCommandEncoder.EllipseGeometry(he, new MilPoint(10, 20), 3, 4));
            Assert.True(new MilPoint(10, 20).Equals(ell.Center));
            Assert.Equal(3.0, ell.RadiusX);
            Assert.Equal(4.0, ell.RadiusY);

            MilLineGeometry line = ch.Create<MilLineGeometry>(DUCE.ResourceType.TYPE_LINEGEOMETRY, out var hl);
            ch.Send(MilCommandEncoder.LineGeometry(hl, new MilPoint(0, 1), new MilPoint(2, 3)));
            Assert.True(new MilPoint(0, 1).Equals(line.StartPoint));
            Assert.True(new MilPoint(2, 3).Equals(line.EndPoint));
        }

        // ============ 13. 几何：GeometryGroup（4 字节步长句柄数组） + PathGeometry（原始字节） ============

        [Fact]
        public void RoundTrip_GeometryGroupAndPathGeometry()
        {
            var ch = new TestChannel();
            MilGeometryGroup group = ch.Create<MilGeometryGroup>(DUCE.ResourceType.TYPE_GEOMETRYGROUP, out var hg);
            var g1 = ch.Create(DUCE.ResourceType.TYPE_RECTANGLEGEOMETRY);
            var g2 = ch.Create(DUCE.ResourceType.TYPE_ELLIPSEGEOMETRY);

            byte[] cmd = MilCommandEncoder.GeometryGroup(hg, MilFillRule.Nonzero, new[] { g1, g2 });
            var s = MilCommandDecoder.ReadFixed<S.MILCMD_GEOMETRYGROUP>(cmd);
            Assert.Equal(2u * 4u, s.ChildrenSize);
            Assert.Equal(MilFillRule.Nonzero, s.FillRule);

            ch.Send(cmd);
            Assert.Equal(new[] { g1, g2 }, group.Children);
            Assert.Equal(MilFillRule.Nonzero, group.FillRule);

            MilPathGeometry path = ch.Create<MilPathGeometry>(DUCE.ResourceType.TYPE_PATHGEOMETRY, out var hp);
            byte[] figures = { 1, 2, 3, 4, 5, 6, 7, 8 };
            byte[] pcmd = MilCommandEncoder.PathGeometry(hp, MilFillRule.EvenOdd, figures);
            Assert.Equal(8u, MilCommandDecoder.ReadFixed<S.MILCMD_PATHGEOMETRY>(pcmd).FiguresSize);
            ch.Send(pcmd);
            Assert.Equal(figures, path.SerializedData);
            Assert.Equal(MilFillRule.EvenOdd, path.FillRule);
        }

        // ============ 14. 变换：五种 + TransformGroup ============

        [Fact]
        public void RoundTrip_Transforms()
        {
            var ch = new TestChannel();

            MilTranslateTransform tt = ch.Create<MilTranslateTransform>(DUCE.ResourceType.TYPE_TRANSLATETRANSFORM, out var h1);
            ch.Send(MilCommandEncoder.TranslateTransform(h1, 3, -4));
            Assert.Equal(3.0, tt.X);
            Assert.Equal(-4.0, tt.Y);

            MilScaleTransform st = ch.Create<MilScaleTransform>(DUCE.ResourceType.TYPE_SCALETRANSFORM, out var h2);
            ch.Send(MilCommandEncoder.ScaleTransform(h2, 2, 3, 10, 20));
            Assert.Equal(2.0, st.ScaleX);
            Assert.Equal(3.0, st.ScaleY);
            Assert.Equal(10.0, st.CenterX);
            Assert.Equal(20.0, st.CenterY);

            MilSkewTransform kt = ch.Create<MilSkewTransform>(DUCE.ResourceType.TYPE_SKEWTRANSFORM, out var h3);
            ch.Send(MilCommandEncoder.SkewTransform(h3, 15, 30, 1, 2));
            Assert.Equal(15.0, kt.AngleX);
            Assert.Equal(30.0, kt.AngleY);

            MilRotateTransform rt = ch.Create<MilRotateTransform>(DUCE.ResourceType.TYPE_ROTATETRANSFORM, out var h4);
            ch.Send(MilCommandEncoder.RotateTransform(h4, 45, 5, 6));
            Assert.Equal(45.0, rt.Angle);
            Assert.Equal(5.0, rt.CenterX);
            Assert.Equal(6.0, rt.CenterY);

            MilMatrixTransform mt = ch.Create<MilMatrixTransform>(DUCE.ResourceType.TYPE_MATRIXTRANSFORM, out var h5);
            var m = new MilMatrix3x2D(1, 2, 3, 4, 5, 6);
            byte[] mcmd = MilCommandEncoder.MatrixTransform(h5, m);
            Assert.True(m.Equals(MilCommandDecoder.ReadFixed<S.MILCMD_MATRIXTRANSFORM>(mcmd).Matrix));
            ch.Send(mcmd);
            Assert.True(m.Equals(mt.Matrix));

            MilTransformGroup tg = ch.Create<MilTransformGroup>(DUCE.ResourceType.TYPE_TRANSFORMGROUP, out var h6);
            byte[] gcmd = MilCommandEncoder.TransformGroup(h6, new[] { h1, h4, h5 });
            Assert.Equal(3u * 4u, MilCommandDecoder.ReadFixed<S.MILCMD_TRANSFORMGROUP>(gcmd).ChildrenSize);
            ch.Send(gcmd);
            Assert.Equal(new[] { h1, h4, h5 }, tg.Children);
        }

        // ============ 15. Pen + DashStyle（8 字节步长 double 尾部） ============

        [Fact]
        public void RoundTrip_PenAndDashStyle()
        {
            var ch = new TestChannel();
            MilDashStyle dash = ch.Create<MilDashStyle>(DUCE.ResourceType.TYPE_DASHSTYLE, out var hd);
            double[] dashes = { 1.5, 2.5, 3.5 };
            byte[] dcmd = MilCommandEncoder.DashStyle(hd, 0.25, dashes);
            Assert.Equal(3u * 8u, MilCommandDecoder.ReadFixed<S.MILCMD_DASHSTYLE>(dcmd).DashesSize);
            Assert.Equal(24 + 3 * 8, dcmd.Length);
            ch.Send(dcmd);
            Assert.Equal(0.25, dash.Offset);
            Assert.Equal(dashes, dash.Dashes);

            MilPen pen = ch.Create<MilPen>(DUCE.ResourceType.TYPE_PEN, out var hp);
            var brush = ch.Create(DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH);
            byte[] pcmd = MilCommandEncoder.Pen(hp, brush, 4.0, hd, 8.0,
                MilPenLineCap.Round, MilPenLineCap.Square, MilPenLineCap.Triangle, MilPenLineJoin.Bevel);
            var ps = MilCommandDecoder.ReadFixed<S.MILCMD_PEN>(pcmd);
            Assert.Equal(4.0, ps.Thickness);
            Assert.Equal(8.0, ps.MiterLimit);
            Assert.Equal(MilPenLineCap.Round, ps.StartLineCap);
            Assert.Equal(MilPenLineJoin.Bevel, ps.LineJoin);
            ch.Send(pcmd);
            Assert.Equal(4.0, pen.Thickness);
            Assert.Equal(brush, pen.Brush);
            Assert.Equal(hd, pen.DashStyle);
            Assert.Equal(MilPenLineCap.Square, pen.EndLineCap);
            Assert.Equal(MilPenLineCap.Triangle, pen.DashCap);
        }

        // ============ 16. Drawing：GeometryDrawing / DrawingGroup（变长） / DrawingImage ============

        [Fact]
        public void RoundTrip_Drawings()
        {
            var ch = new TestChannel();
            MilGeometryDrawing gd = ch.Create<MilGeometryDrawing>(DUCE.ResourceType.TYPE_GEOMETRYDRAWING, out var hgd);
            var brush = ch.Create(DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH);
            var pen = ch.Create(DUCE.ResourceType.TYPE_PEN);
            var geom = ch.Create(DUCE.ResourceType.TYPE_RECTANGLEGEOMETRY);
            ch.Send(MilCommandEncoder.GeometryDrawing(hgd, brush, pen, geom));
            Assert.Equal(brush, gd.Brush);
            Assert.Equal(pen, gd.Pen);
            Assert.Equal(geom, gd.Geometry);

            MilDrawingGroup dg = ch.Create<MilDrawingGroup>(DUCE.ResourceType.TYPE_DRAWINGGROUP, out var hdg);
            byte[] cmd = MilCommandEncoder.DrawingGroup(hdg, 0.5, new[] { hgd },
                clip: geom, edgeMode: MilEdgeMode.Aliased);
            var s = MilCommandDecoder.ReadFixed<S.MILCMD_DRAWINGGROUP>(cmd);
            Assert.Equal(4u, s.ChildrenSize);
            Assert.Equal(MilEdgeMode.Aliased, s.EdgeMode);
            ch.Send(cmd);
            Assert.Equal(0.5, dg.Opacity);
            Assert.Equal(new[] { hgd }, dg.Children);
            Assert.Equal(geom, dg.ClipGeometry);
            Assert.Equal(MilEdgeMode.Aliased, dg.EdgeMode);

            MilDrawingImage di = ch.Create<MilDrawingImage>(DUCE.ResourceType.TYPE_DRAWINGIMAGE, out var hdi);
            ch.Send(MilCommandEncoder.DrawingImage(hdi, hdg));
            Assert.Equal(hdg, di.Drawing);
        }

        // ============ 17. 标量资源（10 种） ============

        [Fact]
        public void RoundTrip_ScalarResources()
        {
            var ch = new TestChannel();

            MilDoubleResource d = ch.Create<MilDoubleResource>(DUCE.ResourceType.TYPE_DOUBLERESOURCE, out var h1);
            ch.Send(MilCommandEncoder.DoubleResource(h1, 3.25));
            Assert.Equal(3.25, d.Value);

            MilColorResource c = ch.Create<MilColorResource>(DUCE.ResourceType.TYPE_COLORRESOURCE, out var h2);
            var color = new MilColorF(0.1f, 0.2f, 0.3f, 0.4f);
            ch.Send(MilCommandEncoder.ColorResource(h2, color));
            Assert.True(color.Equals(c.Value));

            MilPointResource p = ch.Create<MilPointResource>(DUCE.ResourceType.TYPE_POINTRESOURCE, out var h3);
            ch.Send(MilCommandEncoder.PointResource(h3, new MilPoint(9, 8)));
            Assert.True(new MilPoint(9, 8).Equals(p.Value));

            MilRectResource r = ch.Create<MilRectResource>(DUCE.ResourceType.TYPE_RECTRESOURCE, out var h4);
            ch.Send(MilCommandEncoder.RectResource(h4, new MilRect(1, 2, 3, 4)));
            Assert.True(new MilRect(1, 2, 3, 4).Equals(r.Value));

            MilSizeResource sz = ch.Create<MilSizeResource>(DUCE.ResourceType.TYPE_SIZERESOURCE, out var h5);
            ch.Send(MilCommandEncoder.SizeResource(h5, new MilSize(11, 22)));
            Assert.True(new MilSize(11, 22).Equals(sz.Value));

            MilMatrixResource m = ch.Create<MilMatrixResource>(DUCE.ResourceType.TYPE_MATRIXRESOURCE, out var h6);
            var mat = new MilMatrix3x2D(6, 5, 4, 3, 2, 1);
            ch.Send(MilCommandEncoder.MatrixResource(h6, mat));
            Assert.True(mat.Equals(m.Value));

            MilPoint3DResource p3 = ch.Create<MilPoint3DResource>(DUCE.ResourceType.TYPE_POINT3DRESOURCE, out var h7);
            ch.Send(MilCommandEncoder.Point3DResource(h7, new MilPoint3F(1, 2, 3)));
            Assert.True(new MilPoint3F(1, 2, 3).Equals(p3.Value));

            MilVector3DResource v3 = ch.Create<MilVector3DResource>(DUCE.ResourceType.TYPE_VECTOR3DRESOURCE, out var h8);
            ch.Send(MilCommandEncoder.Vector3DResource(h8, new MilPoint3F(4, 5, 6)));
            Assert.True(new MilPoint3F(4, 5, 6).Equals(v3.Value));

            MilQuaternionResource q = ch.Create<MilQuaternionResource>(DUCE.ResourceType.TYPE_QUATERNIONRESOURCE, out var h9);
            ch.Send(MilCommandEncoder.QuaternionResource(h9, new MilQuaternionF(1, 2, 3, 4)));
            Assert.True(new MilQuaternionF(1, 2, 3, 4).Equals(q.Value));

            MilEtwEventResource e = ch.Create<MilEtwEventResource>(DUCE.ResourceType.TYPE_ETWEVENTRESOURCE, out var h10);
            ch.Send(MilCommandEncoder.EtwEventResource(h10, 0x1234));
            Assert.Equal(0x1234u, e.Id);
        }

        // ============ 18. RenderData（原始指令流字节） ============

        [Fact]
        public void RoundTrip_RenderData()
        {
            var ch = new TestChannel();
            MilRenderDataResource rd = ch.Create<MilRenderDataResource>(DUCE.ResourceType.TYPE_RENDERDATA, out var h);

            // 一条 MilDrawRectangle 记录：Size=16, Id, 8 字节载荷
            byte[] stream = new byte[16];
            BitConverter.GetBytes(16).CopyTo(stream, 0);
            BitConverter.GetBytes((int)MilDrawCommand.MilDrawRectangle).CopyTo(stream, 4);
            BitConverter.GetBytes(0x1122334455667788UL).CopyTo(stream, 8);

            byte[] cmd = MilCommandEncoder.RenderData(h, stream);
            Assert.Equal(16u, MilCommandDecoder.ReadFixed<S.MILCMD_RENDERDATA>(cmd).CbData);
            ch.Send(cmd);
            Assert.Equal(stream, rd.Data);

            int records = 0;
            RenderDataStream.Enumerate(rd.Data, (id, data) =>
            {
                records++;
                Assert.Equal(MilDrawCommand.MilDrawRectangle, id);
                Assert.Equal(8, data.Length);
            });
            Assert.Equal(1, records);
        }

        // ============ 19. 效果 / GuidelineSet / BitmapCache ============

        [Fact]
        public void RoundTrip_EffectsAndMisc()
        {
            var ch = new TestChannel();

            MilBlurEffect blur = ch.Create<MilBlurEffect>(DUCE.ResourceType.TYPE_BLUREFFECT, out var h1);
            ch.Send(MilCommandEncoder.BlurEffect(h1, 12.0, MilKernelType.Box, MilRenderingBias.Quality));
            Assert.Equal(12.0, blur.Radius);
            Assert.Equal(MilKernelType.Box, blur.KernelType);
            Assert.Equal(MilRenderingBias.Quality, blur.RenderingBias);

            MilDropShadowEffect ds = ch.Create<MilDropShadowEffect>(DUCE.ResourceType.TYPE_DROPSHADOWEFFECT, out var h2);
            var shadow = new MilColorF(0f, 0f, 0f, 0.8f);
            ch.Send(MilCommandEncoder.DropShadowEffect(h2, 7.0, shadow, 270.0, 0.6, 3.0, MilRenderingBias.Performance));
            Assert.Equal(7.0, ds.ShadowDepth);
            Assert.True(shadow.Equals(ds.Color));
            Assert.Equal(270.0, ds.Direction);
            Assert.Equal(0.6, ds.Opacity);
            Assert.Equal(3.0, ds.BlurRadius);

            MilGuidelineSet gs = ch.Create<MilGuidelineSet>(DUCE.ResourceType.TYPE_GUIDELINESET, out var h3);
            double[] gx = { 1, 2 }, gy = { 3, 4, 5 };
            byte[] gcmd = MilCommandEncoder.GuidelineSet(h3, gx, gy, true);
            var gsv = MilCommandDecoder.ReadFixed<S.MILCMD_GUIDELINESET>(gcmd);
            Assert.Equal(2u * 8u, gsv.GuidelinesXSize);
            Assert.Equal(3u * 8u, gsv.GuidelinesYSize);
            ch.Send(gcmd);
            Assert.Equal(gx, gs.GuidelinesX);
            Assert.Equal(gy, gs.GuidelinesY);
            Assert.True(gs.IsDynamic);

            MilBitmapCache bc = ch.Create<MilBitmapCache>(DUCE.ResourceType.TYPE_BITMAPCACHE, out var h4);
            ch.Send(MilCommandEncoder.BitmapCache(h4, 2.0, true, false));
            Assert.Equal(2.0, bc.RenderAtScale);
            Assert.True(bc.SnapsToDevicePixels);
            Assert.False(bc.EnableClearType);
        }

        // ============ 20. GlyphRun（变长 ushort 尾部） ============

        [Fact]
        public void RoundTrip_GlyphRunCreate()
        {
            var ch = new TestChannel();
            MilGlyphRun run = ch.Create<MilGlyphRun>(DUCE.ResourceType.TYPE_GLYPHRUN, out var h);

            ushort[] glyphs = { 10, 20, 30, 40 };
            byte[] cmd = MilCommandEncoder.GlyphRunCreate(
                h, pFont: 0, flags: 0, origin: new MilPoint2F(1.5f, 2.5f), muSize: 14f,
                bounds: new MilRect(0, 0, 100, 20), glyphIndices: glyphs,
                bidiLevel: 0, measuringMethod: 1);

            var s = MilCommandDecoder.ReadFixed<S.MILCMD_GLYPHRUN_CREATE>(cmd);
            Assert.Equal(4, s.GlyphCount);
            Assert.Equal(14f, s.MuSize);
            Assert.Equal(1, s.DWriteTextMeasuringMethod);
            Assert.Equal(76 + 4 * 2, cmd.Length);

            ch.Send(cmd);
            Assert.Equal(glyphs, run.GlyphIndices);
            Assert.Equal(14f, run.MuSize);
            Assert.True(new MilPoint2F(1.5f, 2.5f).Equals(run.Origin));
        }

        // ============ 21. 分区级命令（无 Handle） ============

        [Fact]
        public void RoundTrip_PartitionCommands()
        {
            var ch = new TestChannel();

            byte[] present = new byte[12];
            BitConverter.GetBytes((int)MilCmd.MilCmdPartitionNotifyPresent).CopyTo(present, 0);
            BitConverter.GetBytes(0x0102030405060708UL).CopyTo(present, 4);
            ch.Send(present);
            Assert.Equal(0x0102030405060708UL, ch.Channel.Partition.LastPresentFrameTime);

            byte[] reg = new byte[8];
            BitConverter.GetBytes((int)MilCmd.MilCmdPartitionRegisterForNotifications).CopyTo(reg, 0);
            BitConverter.GetBytes(1u).CopyTo(reg, 4);
            ch.Send(reg);
            Assert.True(ch.Channel.Partition.RegisterForNotifications);

            byte[] tier = new byte[8];
            BitConverter.GetBytes((int)MilCmd.MilCmdChannelRequestTier).CopyTo(tier, 0);
            BitConverter.GetBytes(1u).CopyTo(tier, 4);
            ch.Send(tier);
            Assert.True(ch.Channel.Partition.ReturnCommonMinimum);
        }

        // ============ 22. 未实现命令：返回 E_NOTIMPL 并登记 ============

        [Fact]
        public void 未实现命令返回ENOTIMPL并登记()
        {
            var ch = new TestChannel();
            byte[] cmd = new byte[8];
            // ⚠️【`#49` 修：W62A 落地 `D-G58` 后本用例当场会红】
            //   原文拿 `0x6c MilCmdPixelShader` 当"稳定的 `E_NOTIMPL`"，理由是"C 类、永久划掉"——
            //   而 `#49` 把 `0x6c`/`0x70` 两条**实现掉了**（`Effects` 页不再 abort）⇒ **那条理由失效**，
            //   用例断言的"稳定"就没了。改成 `0x0a MilCmdD3DImage`：它属"载荷是 D3D/硬件加速、
            //   Linux 无对应概念"那一类（`MilCommandLayout.s_notImpl` 现为 5 条：D3DImage /
            //   D3DImagePresent / DoubleBufferedBitmap / DoubleBufferedBitmapCopyForward / MediaPlayer），
            //   且 `MilCommandDispatcher` 里**没有** `case` ⇒ 走 `default: E_NOTIMPL`。
            //   ⚠️ 这条依赖仍然脆弱：**任何**被实现掉的编号都会让本用例红 —— 真正稳的写法是
            //   "取 `s_notImpl` 里的任一条"（消费 `MilCommandLayout.NotImplCount`/`IsNotImplemented`），
            //   那属于测试侧改造，`#50` 办（本轮只做最小修复，避免顺手扩大改动面）。
            BitConverter.GetBytes((int)MilCmd.MilCmdD3DImage).CopyTo(cmd, 0);

            Assert.Equal(HResult.E_NOTIMPL, ch.Dispatch(cmd));

            // 通过通道批处理走一遍，确认登记表被写入
            ch.Channel.SendCommand(cmd, sendInSeparateBatch: true);
            Assert.True(ch.Channel.NotImplRegistry.ContainsKey(MilCmd.MilCmdD3DImage));
        }

        [Fact]
        public void 命令过短返回EINVALIDARG()
        {
            var ch = new TestChannel();
            var h = ch.Create(DUCE.ResourceType.TYPE_VISUAL);
            byte[] cmd = MilCommandEncoder.VisualSetOffset(h, 1, 2);
            Assert.Equal(HResult.E_INVALIDARG, ch.Dispatch(cmd[..(cmd.Length - 4)]));
            Assert.Equal(HResult.E_INVALIDARG, ch.Dispatch(new byte[2]));
        }

        [Fact]
        public void 句柄无效返回EHANDLE()
        {
            var ch = new TestChannel();
            byte[] cmd = MilCommandEncoder.VisualSetOffset(new DUCE.ResourceHandle(999), 1, 2);
            Assert.Equal(HResult.E_HANDLE, ch.Dispatch(cmd));
        }

        [Fact]
        public void 句柄类型不符返回EINVALIDARG()
        {
            var ch = new TestChannel();
            var brush = ch.Create(DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH);
            // 把画刷句柄当 Visual 用
            Assert.Equal(HResult.E_INVALIDARG, ch.Dispatch(MilCommandEncoder.VisualSetOffset(brush, 1, 2)));
        }
    }
}

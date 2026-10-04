// Licensed to the .NET Foundation under one or more agreements.
//
// U1c：Linux 侧 runner —— 直接调用本工程的 MilNative.MilUtility_* 实现。
//
// 与 NativeGeometryRunner（Windows 侧真身）**一一对应**：同一个 case、同一组参数、
// 同一套输出键名。两边唯一的差别就是被调用的实现。

using System;
using System.Collections.Generic;
using System.Text.Json.Nodes;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;

namespace WpfGfx.Linux.Parity.Geometry
{
    public unsafe sealed class LinuxGeometryRunner : IGeometryRunner
    {
        private readonly List<(bool filled, bool closed, float[] pts, byte[] types)> _figures =
            new List<(bool, bool, float[], byte[])>();

        public CaseResult Run(GeometryCase c)
        {
            var b = new ResultBuilder(c);
            try
            {
                switch (c.Fn)
                {
                    case CaseCatalog.FnArc: RunArc(c, b); break;
                    case CaseCatalog.FnPathBounds: RunPathBounds(c, b); break;
                    case CaseCatalog.FnPolyBounds: RunPolyBounds(c, b); break;
                    case CaseCatalog.FnFlatten: RunFlatten(c, b); break;
                    case CaseCatalog.FnOutline: RunOutline(c, b); break;
                    case CaseCatalog.FnWiden: RunWiden(c, b); break;
                    case CaseCatalog.FnCombine: RunCombine(c, b); break;
                    case CaseCatalog.FnHit: RunHit(c, b); break;
                    case CaseCatalog.FnPolyHit: RunPolyHit(c, b); break;
                    case CaseCatalog.FnHitPath: RunHitPath(c, b); break;
                    case CaseCatalog.FnArea: RunArea(c, b); break;
                    case CaseCatalog.FnLength: RunLength(c, b); break;
                    case CaseCatalog.FnTileBrush: RunTileBrush(c, b); break;
                    case CaseCatalog.FnCopyPixels: RunCopyPixels(c, b); break;
                    case CaseCatalog.FnProbe: RunProbe(c, b); break;
                    default: b.Error("Linux runner 不认识的函数：" + c.Fn); break;
                }
            }
            catch (Exception ex)
            {
                b.Error(ex.GetType().Name + ": " + ex.Message);
            }
            return b.Result;
        }

        // ---- 公共参数 ----------------------------------------------------

        private static byte[] Path(JsonObject a) => JsonHelp.Hex(JsonHelp.Str(a, "path"));

        /// <summary>把 6 个 double 的矩阵搬进栈上缓冲，返回指针（null 表示不给矩阵）。</summary>
        private static double* Matrix(JsonObject a, string name, double* scratch6)
        {
            double[] v = JsonHelp.Doubles(a[name]);
            if (v == null) return null;
            for (int i = 0; i < 6; i++) scratch6[i] = v[i];
            return scratch6;
        }

        private static MilFillRule Rule(JsonObject a, string name = "fillRule") =>
            (MilFillRule)(int)JsonHelp.Num(a, name, 0);

        private static void Pen(JsonObject a, MIL_PEN_DATA* pen, double* dashScratch, out double* dash)
        {
            dash = null;
            JsonObject p = a["pen"] as JsonObject;
            if (p == null) return;

            *pen = new MIL_PEN_DATA
            {
                Thickness = JsonHelp.Num(p, "thickness", 0),
                MiterLimit = JsonHelp.Num(p, "miterLimit", 10),
                DashOffset = JsonHelp.Num(p, "dashOffset", 0),
                StartLineCap = (MilPenLineCap)(int)JsonHelp.Num(p, "startCap", 0),
                EndLineCap = (MilPenLineCap)(int)JsonHelp.Num(p, "endCap", 0),
                DashCap = (MilPenLineCap)(int)JsonHelp.Num(p, "dashCap", 0),
                LineJoin = (MilPenLineJoin)(int)JsonHelp.Num(p, "join", 0),
            };

            double[] dashes = JsonHelp.Doubles(p["dashes"]);
            if (dashes != null)
            {
                for (int i = 0; i < dashes.Length; i++) dashScratch[i] = dashes[i];
                // ⚠️ DashArraySize 是**字节数**（上游 `DashArraySize / sizeof(double)`，
                // geometry_api.cpp:141）。第一版写的是元素个数 → 上游算成 0 条虚线，
                // 于是 widen_dash 根本没测到虚线。这里必须按字节给。
                pen->DashArraySize = (uint)(dashes.Length * sizeof(double));
                dash = dashScratch;
            }
        }

        private void ResetFigures() => _figures.Clear();

        /// <summary>图形回调收集器（回调期间可能被重入，所以用实例字段）。</summary>
        private void Collect(bool isFilled, bool isClosed, MilPointF* pPoints, uint pointCount,
            byte* pTypes, uint typeCount)
        {
            var pts = new float[pointCount * 2];
            for (uint i = 0; i < pointCount; i++)
            {
                pts[i * 2] = pPoints[i].X;
                pts[i * 2 + 1] = pPoints[i].Y;
            }
            var types = new byte[typeCount];
            for (uint i = 0; i < typeCount; i++) types[i] = pTypes[i];
            _figures.Add((isFilled, isClosed, pts, types));
        }

        private void EmitFigures(ResultBuilder b)
        {
            b.FigureCount(_figures.Count);
            for (int i = 0; i < _figures.Count; i++)
            {
                var f = _figures[i];
                b.AddFigure(i, f.filled, f.closed, f.pts, f.types);
            }
        }

        // ---- 各函数 ------------------------------------------------------

        private void RunArc(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            double[] s = JsonHelp.Doubles(a["ptStart"]);
            double[] r = JsonHelp.Doubles(a["radii"]);
            double[] e = JsonHelp.Doubles(a["ptEnd"]);
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);

            var pts = new MilPointD[12];
            fixed (MilPointD* pp = pts)
            {
                int pieces;
                MilNative.MilUtility_ArcToBezier(
                    new MilPointD(s[0], s[1]), new MilSizeD(r[0], r[1]),
                    JsonHelp.Num(a, "rotation", 0),
                    JsonHelp.Flag(a, "largeArc"),
                    JsonHelp.Flag(a, "sweepCw") ? MilSweepDirection.Clockwise : MilSweepDirection.Counterclockwise,
                    new MilPointD(e[0], e[1]), m, pp, out pieces);

                b.Hr(HResult.S_OK);
                b.Set("cPieces", pieces);
                int count = pieces < 0 ? 0 : (pieces == 0 ? 1 : 3 * pieces);
                b.Set("pointCount", count);
                var flat = new double[count * 2];
                for (int i = 0; i < count; i++)
                {
                    flat[i * 2] = pts[i].X;
                    flat[i * 2 + 1] = pts[i].Y;
                }
                b.Vec("points", flat);
            }
        }

        private void RunPathBounds(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = Path(a);
            double* worldScratch = stackalloc double[6];
            double* world = Matrix(a, "worldMatrix", worldScratch);
            double* geomScratch = stackalloc double[6];
            double* geom = Matrix(a, "geometryMatrix", geomScratch);
            MIL_PEN_DATA pen = default;
            double* dashScratch = stackalloc double[16];
            Pen(a, &pen, dashScratch, out double* dash);
            bool hasPen = a["pen"] != null;

            MilRectD bounds = default;
            int hr;
            fixed (byte* p = path)
            {
                hr = MilNative.MilUtility_PathGeometryBounds(
                    hasPen ? &pen : null, dash, world, Rule(a), p, (uint)path.Length, geom,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative"),
                    JsonHelp.Flag(a, "skipHollows"), &bounds);
            }
            b.Hr(hr);
            b.Set("left", bounds.Left).Set("top", bounds.Top)
             .Set("right", bounds.Right).Set("bottom", bounds.Bottom)
             .Set("width", bounds.Width).Set("height", bounds.Height);
            // 原始 4 个 double（消除"LTRB 还是 XYWH"的读法歧义）
            b.Vec("rawLtrb", bounds.Left, bounds.Top, bounds.Right, bounds.Bottom);
        }

        private void RunPolyBounds(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            double[] pts = JsonHelp.Doubles(a["points"]);
            double[] typesD = JsonHelp.Doubles(a["types"]);
            var types = new byte[typesD.Length];
            for (int i = 0; i < typesD.Length; i++) types[i] = (byte)typesD[i];

            double* worldScratch = stackalloc double[6];

            double* world = Matrix(a, "worldMatrix", worldScratch);
            double* geomScratch = stackalloc double[6];
            double* geom = Matrix(a, "geometryMatrix", geomScratch);
            MIL_PEN_DATA pen = default;
            double* dashScratch = stackalloc double[16];
            Pen(a, &pen, dashScratch, out double* dash);
            bool hasPen = a["pen"] != null;

            var mpts = new MilPointD[pts.Length / 2];
            for (int i = 0; i < mpts.Length; i++) mpts[i] = new MilPointD(pts[i * 2], pts[i * 2 + 1]);

            MilRectD bounds = default;
            int hr;
            fixed (MilPointD* pp = mpts)
            fixed (byte* pt = types)
            {
                hr = MilNative.MilUtility_PolygonBounds(
                    world, hasPen ? &pen : null, dash, pp, pt,
                    (uint)JsonHelp.Num(a, "pointCount", mpts.Length),
                    (uint)JsonHelp.Num(a, "segmentCount", types.Length),
                    geom, JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative"),
                    JsonHelp.Flag(a, "skipHollows"), &bounds);
            }
            b.Hr(hr);
            b.Set("left", bounds.Left).Set("top", bounds.Top)
             .Set("right", bounds.Right).Set("bottom", bounds.Bottom);
        }

        private void RunFlatten(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = Path(a);
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            ResetFigures();
            MilFillRule outRule;
            int hr;
            MilAddFigureCallback cb = Collect;
            fixed (byte* p = path)
            {
                hr = MilNative.MilUtility_PathGeometryFlatten(m, Rule(a), p, (uint)path.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative"), cb, out outRule);
            }
            b.Hr(hr).Set("outFillRule", (int)outRule);
            EmitFigures(b);
        }

        private void RunOutline(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = Path(a);
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            ResetFigures();
            MilFillRule outRule;
            int hr;
            MilAddFigureCallback cb = Collect;
            fixed (byte* p = path)
            {
                hr = MilNative.MilUtility_PathGeometryOutline(m, Rule(a), p, (uint)path.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative"), cb, out outRule);
            }
            b.Hr(hr).Set("outFillRule", (int)outRule);
            EmitFigures(b);
        }

        private void RunWiden(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = Path(a);
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            MIL_PEN_DATA pen = default;
            double* dashScratch = stackalloc double[16];
            Pen(a, &pen, dashScratch, out double* dash);

            ResetFigures();
            MilFillRule outRule;
            int hr;
            MilAddFigureCallback cb = Collect;
            fixed (byte* p = path)
            {
                hr = MilNative.MilUtility_PathGeometryWiden(&pen, dash, m, Rule(a), p, (uint)path.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative"), cb, out outRule);
            }
            b.Hr(hr).Set("outFillRule", (int)outRule);
            EmitFigures(b);
        }

        private void RunCombine(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] p1 = JsonHelp.Hex(JsonHelp.Str(a, "path1"));
            byte[] p2 = JsonHelp.Hex(JsonHelp.Str(a, "path2"));
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            double* m1Scratch = stackalloc double[6];
            double* m1 = Matrix(a, "matrix1", m1Scratch);
            double* m2Scratch = stackalloc double[6];
            double* m2 = Matrix(a, "matrix2", m2Scratch);

            ResetFigures();
            MilFillRule outRule;
            int hr;
            MilAddFigureCallback cb = Collect;
            fixed (byte* x = p1)
            fixed (byte* y = p2)
            {
                hr = MilNative.MilUtility_PathGeometryCombine(m, m1, Rule(a, "fillRule1"), x, (uint)p1.Length,
                    m2, Rule(a, "fillRule2"), y, (uint)p2.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative"), cb,
                    (MilGeometryCombineMode)(int)JsonHelp.Num(a, "combineMode", 0), out outRule);
            }
            b.Hr(hr).Set("outFillRule", (int)outRule);
            EmitFigures(b);
        }

        private void RunHit(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = Path(a);
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            MIL_PEN_DATA pen = default;
            double* dashScratch = stackalloc double[16];
            Pen(a, &pen, dashScratch, out double* dash);
            bool hasPen = a["pen"] != null;
            double[] hp = JsonHelp.Doubles(a["hitPoint"]);
            var hit = new MilPointD(hp[0], hp[1]);

            int hr, contains;
            fixed (byte* p = path)
            {
                hr = MilNative.MilUtility_PathGeometryHitTest(m, hasPen ? &pen : null, dash, Rule(a),
                    p, (uint)path.Length, JsonHelp.Num(a, "tolerance", 0), JsonHelp.Flag(a, "relative"),
                    &hit, out contains);
            }
            b.Hr(hr).Set("isHit", contains);
        }

        private void RunPolyHit(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            double[] pts = JsonHelp.Doubles(a["points"]);
            double[] typesD = JsonHelp.Doubles(a["types"]);
            var types = new byte[typesD.Length];
            for (int i = 0; i < typesD.Length; i++) types[i] = (byte)typesD[i];
            double[] hp = JsonHelp.Doubles(a["hitPoint"]);
            var hit = new MilPointD(hp[0], hp[1]);
            MIL_PEN_DATA pen = default;
            double* dashScratch = stackalloc double[16];
            Pen(a, &pen, dashScratch, out double* dash);
            bool hasPen = a["pen"] != null;

            var mpts = new MilPointD[pts.Length / 2];
            for (int i = 0; i < mpts.Length; i++) mpts[i] = new MilPointD(pts[i * 2], pts[i * 2 + 1]);

            int hr, contains;
            fixed (MilPointD* pp = mpts)
            fixed (byte* pt = types)
            {
                hr = MilNative.MilUtility_PolygonHitTest(null, hasPen ? &pen : null, dash, pp, pt,
                    (uint)JsonHelp.Num(a, "pointCount", mpts.Length),
                    (uint)JsonHelp.Num(a, "segmentCount", types.Length),
                    JsonHelp.Num(a, "tolerance", 0), JsonHelp.Flag(a, "relative"), &hit, out contains);
            }
            b.Hr(hr).Set("isHit", contains);
        }

        private void RunHitPath(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] p1 = JsonHelp.Hex(JsonHelp.Str(a, "path1"));
            byte[] p2 = JsonHelp.Hex(JsonHelp.Str(a, "path2"));
            double* m1Scratch = stackalloc double[6];
            double* m1 = Matrix(a, "matrix1", m1Scratch);
            double* m2Scratch = stackalloc double[6];
            double* m2 = Matrix(a, "matrix2", m2Scratch);

            MilIntersectionDetail detail;
            int hr;
            fixed (byte* x = p1)
            fixed (byte* y = p2)
            {
                hr = MilNative.MilUtility_PathGeometryHitTestPathGeometry(m1, Rule(a, "fillRule1"), x,
                    (uint)p1.Length, m2, Rule(a, "fillRule2"), y, (uint)p2.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative"), &detail);
            }
            b.Hr(hr).Set("detail", (int)detail);
        }

        private void RunArea(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = Path(a);
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            double area = 0;
            int hr;
            fixed (byte* p = path)
            {
                hr = MilNative.MilUtility_GeometryGetArea(Rule(a), p, (uint)path.Length, m,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative"), &area);
            }
            b.Hr(hr).Set("area", area);
        }

        private void RunLength(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = Path(a);
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            MilPointD pt, tangent;
            int hr;
            fixed (byte* p = path)
            {
                hr = MilNative.MilUtility_GetPointAtLengthFraction(m, Rule(a), p, (uint)path.Length,
                    JsonHelp.Num(a, "fraction", 0), out pt, out tangent);
            }
            b.Hr(hr);
            b.Vec2("point", pt.X, pt.Y).Vec2("tangent", tangent.X, tangent.Y);
        }

        private void RunTileBrush(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            D3DMATRIX* tf = null, rtf = null;
            D3DMATRIX tfStore = default, rtfStore = default;
            if (a["transform"] is JsonArray ta)
            {
                tfStore = ToD3D(JsonHelp.Doubles(ta));
                tf = &tfStore;
            }
            if (a["relativeTransform"] is JsonArray ra)
            {
                rtfStore = ToD3D(JsonHelp.Doubles(ra));
                rtf = &rtfStore;
            }

            MilPointAndSizeD shapeStore = default, contentStore = default;
            MilPointAndSizeD* shape = ToRect(JsonHelp.Doubles(a["shapeFillBounds"]), &shapeStore);
            MilPointAndSizeD* content = ToRect(JsonHelp.Doubles(a["contentBounds"]), &contentStore);

            MilPointAndSizeD viewport = RectOf(JsonHelp.Doubles(a["viewport"]));
            MilPointAndSizeD viewbox = RectOf(JsonHelp.Doubles(a["viewbox"]));

            MilNative.MilUtility_GetTileBrushMapping(tf, rtf,
                (MilStretch)(int)JsonHelp.Num(a, "stretch", 0),
                (MilAlignmentX)(int)JsonHelp.Num(a, "alignX", 0),
                (MilAlignmentY)(int)JsonHelp.Num(a, "alignY", 0),
                (MilBrushMappingMode)(int)JsonHelp.Num(a, "viewportUnits", 0),
                (MilBrushMappingMode)(int)JsonHelp.Num(a, "viewboxUnits", 0),
                shape, content, ref viewport, ref viewbox, out D3DMATRIX m, out int empty);

            b.Hr(HResult.S_OK);
            b.Set("brushIsEmpty", empty);
            b.Set("vp.x", viewport.X).Set("vp.y", viewport.Y)
             .Set("vp.w", viewport.Width).Set("vp.h", viewport.Height);
            b.Set("vb.x", viewbox.X).Set("vb.y", viewbox.Y)
             .Set("vb.w", viewbox.Width).Set("vb.h", viewbox.Height);
            var cells = new double[16];
            for (int i = 0; i < 16; i++) cells[i] = m[i];
            b.Vec("contentToShape", cells);
        }

        private static D3DMATRIX ToD3D(double[] v)
        {
            var m = new D3DMATRIX();
            for (int i = 0; i < 16; i++) SetCell(ref m, i, (float)v[i]);
            return m;
        }

        private static void SetCell(ref D3DMATRIX m, int i, float value)
        {
            switch (i)
            {
                case 0: m.M11 = value; break;
                case 1: m.M12 = value; break;
                case 2: m.M13 = value; break;
                case 3: m.M14 = value; break;
                case 4: m.M21 = value; break;
                case 5: m.M22 = value; break;
                case 6: m.M23 = value; break;
                case 7: m.M24 = value; break;
                case 8: m.M31 = value; break;
                case 9: m.M32 = value; break;
                case 10: m.M33 = value; break;
                case 11: m.M34 = value; break;
                case 12: m.M41 = value; break;
                case 13: m.M42 = value; break;
                case 14: m.M43 = value; break;
                default: m.M44 = value; break;
            }
        }

        private static MilPointAndSizeD* ToRect(double[] v, MilPointAndSizeD* store)
        {
            if (v == null) return null;
            *store = new MilPointAndSizeD(v[0], v[1], v[2], v[3]);
            return store;
        }

        private static MilPointAndSizeD RectOf(double[] v) =>
            v == null ? default : new MilPointAndSizeD(v[0], v[1], v[2], v[3]);

        private void RunCopyPixels(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] input = JsonHelp.Hex(JsonHelp.Str(a, "inputHex"));
            byte[] seed = JsonHelp.Hex(JsonHelp.Str(a, "outputSeedHex"));
            uint outSize = (uint)JsonHelp.Num(a, "outputSize");
            var output = new byte[outSize];
            if (seed != null) Array.Copy(seed, output, Math.Min(seed.Length, output.Length));

            int hr;
            fixed (byte* po = output)
            fixed (byte* pi = input)
            {
                hr = MilNative.MilUtility_CopyPixelBuffer(po, outSize,
                    (uint)JsonHelp.Num(a, "outputStride"), (uint)JsonHelp.Num(a, "outputOffsetInBits"),
                    pi, (uint)JsonHelp.Num(a, "inputSize"), (uint)JsonHelp.Num(a, "inputStride"),
                    (uint)JsonHelp.Num(a, "inputOffsetInBits"), (uint)JsonHelp.Num(a, "height"),
                    (uint)JsonHelp.Num(a, "copyWidthInBits"));
            }
            b.Hr(hr);
            b.Buffer("output", output);
        }

        private void RunProbe(GeometryCase c, ResultBuilder b)
        {
            b.Hr(HResult.S_OK);
            int index = 0;
            foreach (JsonNode n in (JsonArray)c.Args["names"])
            {
                string name = n.GetValue<string>();
                bool known = MilNative.ExportManifest.TryGetValue(name, out ExportDepth depth);
                b.Set("resolved." + index, known && depth != ExportDepth.NotImpl ? 1 : 0);
                index++;
            }
        }
    }
}

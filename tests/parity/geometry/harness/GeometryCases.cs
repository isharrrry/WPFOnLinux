// Licensed to the .NET Foundation under one or more agreements.
//
// U1c：几何 oracle 对拍的**共享**数据结构 + MIL_PATHGEOMETRY 字节块构造器。
//
// 这个文件在三个地方被编译（源码逐字节相同）：
//   1. Linux 侧 tools/GeometryOracle/          —— 生成 cases.json / 跑我方实现 / 出对拍报告
//   2. Windows 侧 C:\u1-geom\                  —— 跑真身 wpfgfx_cor3.dll
//   3. Linux 侧 tests/.../GeometryOracleTests.cs —— 活体复跑 + 断言
//
// 【为什么路径数据要自己手搓字节块，而不是用 MilGeometryEngine.SerializePath】
//   如果用我方序列化器产出输入，那么"序列化器有 bug"会伪装成"几何实现有偏差"。
//   所以输入字节块由本文件按上游 MIL_PATHGEOMETRY / MIL_PATHFIGURE / MIL_SEGMENT_*
//   的结构（Common/Graphics/wgx_core_types.cs:1009-1060）**独立手写**，
//   与 MilGeometryEngine.SerializePath 无任何调用关系。
//
// 【BOUNDS 标志为什么默认不设】
//   上游 CShapeBase::GetTightBounds（shapebase.cpp:1353）在"矩阵是 null 或纯平移缩放
//   且 !HasHollows()"时直接用路径数据里缓存的 Bounds 字段（前提是 BoundsValid 已置位）。
//   如果我把一个松散的包围盒写进去还置了 BoundsValid，真机会把那个松散盒子原样返回，
//   于是产出"假偏差"。所以默认**不置 BoundsValid**，强制真机自己算；
//   另有两组专门 case（boundsvalid_*）拿"精确紧包围盒 + BoundsValid"再比一次，
//   用来验证我方 SerializePath 写 Bounds 这件事本身是否可信。

using System;
using System.Collections.Generic;
using System.Text.Json.Nodes;

namespace WpfGfx.Linux.Parity.Geometry
{
    /// <summary>一个对拍用例。</summary>
    public sealed class GeometryCase
    {
        public string Id { get; set; }
        public string Fn { get; set; }
        public JsonObject Args { get; set; }
        /// <summary>给报告看的人类可读说明。</summary>
        public string Note { get; set; }
    }

    public sealed class GeometryCaseFile
    {
        public string Schema { get; set; } = "wpfgfx-geometry-oracle/1";
        public string Description { get; set; }
        public List<GeometryCase> Cases { get; set; } = new List<GeometryCase>();
    }

    /// <summary>一个用例的执行结果（两侧用同一套编码，保证可比）。</summary>
    public sealed class CaseResult
    {
        public string Id { get; set; }
        public string Fn { get; set; }
        /// <summary>返回的 HRESULT（void 函数记 0）。</summary>
        public int Hr { get; set; }
        /// <summary>命名标量输出（整数也按 double 记）。</summary>
        public Dictionary<string, double> Scalars { get; set; } = new Dictionary<string, double>();
        /// <summary>命名数值数组输出（点坐标摊平存放）。</summary>
        public Dictionary<string, double[]> Vectors { get; set; } = new Dictionary<string, double[]>();
        /// <summary>命名字节块输出（十六进制）。</summary>
        public Dictionary<string, string> Buffers { get; set; } = new Dictionary<string, string>();
        /// <summary>执行期异常（托管侧炸了、原生侧崩了等）。</summary>
        public string Error { get; set; }
    }

    // ==================================================================
    //  MIL_PATHGEOMETRY 字节块构造器（独立手写，不依赖我方序列化器）
    // ==================================================================

    public sealed class SegSpec
    {
        /// <summary>'L' 直线（1 点）或 'C' 三次贝塞尔（3 点）。</summary>
        public char Kind;
        /// <summary>直线 2 个 double；贝塞尔 6 个 double。</summary>
        public double[] Pts;
        /// <summary>SegIsAGap：抬笔（断开）。</summary>
        public bool Gap;
        /// <summary>SegSmoothJoin。</summary>
        public bool Smooth;
        /// <summary>SegClosed：上游把"图形闭合"记在最后一段上。</summary>
        public bool Closed;
    }

    public sealed class FigSpec
    {
        public double StartX;
        public double StartY;
        public bool Closed;
        /// <summary>false → 该图形不可填充（上游 HasHollows 的来源）。</summary>
        public bool Fillable = true;
        public bool RectangleData;
        public List<SegSpec> Segs = new List<SegSpec>();
    }

    public static class PathDataBuilder
    {
        public const int HeaderSize = 48;
        public const int FigureHeaderSize = 40;
        public const int LineSegSize = 32;
        public const int BezierSegSize = 64;

        // MilPathGeometryFlags
        public const uint GeomHasCurves = 0x1;
        public const uint GeomBoundsValid = 0x2;
        public const uint GeomHasGaps = 0x4;
        public const uint GeomHasHollows = 0x8;

        // MilPathFigureFlags
        public const uint FigHasGaps = 0x1;
        public const uint FigHasCurves = 0x2;
        public const uint FigIsClosed = 0x4;
        public const uint FigIsFillable = 0x8;
        public const uint FigIsRectangleData = 0x10;

        // MILCoreSegFlags
        public const uint SegTypeLine = 0x1;
        public const uint SegTypeBezier = 0x2;
        public const uint SegIsAGap = 0x4;
        public const uint SegSmoothJoin = 0x8;
        public const uint SegClosed = 0x10;

        /// <summary>图形规格 → MIL_PATHGEOMETRY 字节块。默认不置 BoundsValid。</summary>
        public static byte[] Build(IEnumerable<FigSpec> figures) => Build(figures, false);

        public static byte[] Build(IEnumerable<FigSpec> figures, bool setBoundsValid)
        {
            var figs = new List<FigSpec>(figures);

            int total = HeaderSize;
            var figSizes = new int[figs.Count];
            for (int i = 0; i < figs.Count; i++)
            {
                int size = FigureHeaderSize;
                foreach (SegSpec s in figs[i].Segs)
                    size += s.Kind == 'C' ? BezierSegSize : LineSegSize;
                figSizes[i] = size;
                total += size;
            }

            var buf = new byte[total];
            Span<byte> span = buf;

            bool hasCurves = false, hasGaps = false, hasHollows = false;

            int offset = HeaderSize;
            for (int fi = 0; fi < figs.Count; fi++)
            {
                FigSpec f = figs[fi];
                int figSize = figSizes[fi];

                uint figFlags = 0;
                if (f.Fillable) figFlags |= FigIsFillable; else hasHollows = true;
                if (f.Closed) figFlags |= FigIsClosed;
                if (f.RectangleData) figFlags |= FigIsRectangleData;
                bool figHasCurves = false, figHasGaps = false;
                foreach (SegSpec s in f.Segs)
                {
                    if (s.Kind == 'C') { figHasCurves = true; hasCurves = true; }
                    if (s.Gap) { figHasGaps = true; hasGaps = true; }
                }
                if (figHasCurves) figFlags |= FigHasCurves;
                if (figHasGaps) figFlags |= FigHasGaps;

                WriteU32(span, offset + 0, fi == 0 ? 0u : (uint)figSizes[fi - 1]); // BackSize
                WriteU32(span, offset + 4, figFlags);
                WriteU32(span, offset + 8, (uint)f.Segs.Count);                     // Count
                WriteU32(span, offset + 12, (uint)figSize);                          // Size
                WriteDouble(span, offset + 16, f.StartX);
                WriteDouble(span, offset + 24, f.StartY);

                int cursor = offset + FigureHeaderSize;
                int lastSegSize = 0;
                for (int si = 0; si < f.Segs.Count; si++)
                {
                    SegSpec s = f.Segs[si];
                    uint segFlags = s.Kind == 'C' ? SegTypeBezier : SegTypeLine;
                    if (s.Gap) segFlags |= SegIsAGap;
                    if (s.Smooth) segFlags |= SegSmoothJoin;
                    if (s.Closed) segFlags |= SegClosed;

                    int segSize = s.Kind == 'C' ? BezierSegSize : LineSegSize;
                    WriteU32(span, cursor + 0, s.Kind == 'C' ? 2u : 1u);   // MIL_SEGMENT_TYPE
                    WriteU32(span, cursor + 4, segFlags);
                    WriteU32(span, cursor + 8, (uint)lastSegSize);          // BackSize
                    WriteU32(span, cursor + 12, 0);                        // ForcePacking

                    if (s.Kind == 'C')
                    {
                        WriteDouble(span, cursor + 16, s.Pts[0]);
                        WriteDouble(span, cursor + 24, s.Pts[1]);
                        WriteDouble(span, cursor + 32, s.Pts[2]);
                        WriteDouble(span, cursor + 40, s.Pts[3]);
                        WriteDouble(span, cursor + 48, s.Pts[4]);
                        WriteDouble(span, cursor + 56, s.Pts[5]);
                    }
                    else
                    {
                        WriteDouble(span, cursor + 16, s.Pts[0]);
                        WriteDouble(span, cursor + 24, s.Pts[1]);
                    }

                    lastSegSize = segSize;
                    cursor += segSize;
                }

                // OffsetToLastSegment（上游 MIL_PATHFIGURE@32，figure header 起点算）
                WriteU32(span, offset + 32, f.Segs.Count > 0
                    ? (uint)(figSize - lastSegSize)
                    : 0u);
                WriteU32(span, offset + 36, 0);   // ForcePacking

                offset += figSize;
            }

            uint geomFlags = 0;
            if (hasCurves) geomFlags |= GeomHasCurves;
            if (hasGaps) geomFlags |= GeomHasGaps;
            if (hasHollows) geomFlags |= GeomHasHollows;

            double l = double.PositiveInfinity, t = double.PositiveInfinity;
            double r = double.NegativeInfinity, b = double.NegativeInfinity;
            foreach (FigSpec f in figs)
            {
                Track(ref l, ref t, ref r, ref b, f.StartX, f.StartY);
                foreach (SegSpec s in f.Segs)
                    for (int k = 0; k + 1 < s.Pts.Length; k += 2)
                        Track(ref l, ref t, ref r, ref b, s.Pts[k], s.Pts[k + 1]);
            }
            if (figs.Count == 0) { l = t = r = b = 0; }

            // 精确紧包围盒只对"纯直线"成立；含曲线时这里是控制点凸包（上界）。
            // 因此 setBoundsValid=true 只应当用在纯直线用例上（生成器负责把关）。
            if (setBoundsValid) geomFlags |= GeomBoundsValid;

            WriteU32(span, 0, (uint)total);
            WriteU32(span, 4, geomFlags);
            WriteDouble(span, 8, l);
            WriteDouble(span, 16, t);
            WriteDouble(span, 24, r);
            WriteDouble(span, 32, b);
            WriteU32(span, 40, (uint)figs.Count);
            WriteU32(span, 44, 0);

            return buf;
        }

        private static void Track(ref double l, ref double t, ref double r, ref double b,
            double x, double y)
        {
            if (x < l) l = x;
            if (y < t) t = y;
            if (x > r) r = x;
            if (y > b) b = y;
        }

        public static void WriteU32(Span<byte> span, int offset, uint value) =>
            System.Buffers.Binary.BinaryPrimitives.WriteUInt32LittleEndian(span.Slice(offset, 4), value);

        public static void WriteDouble(Span<byte> span, int offset, double value) =>
            System.Buffers.Binary.BinaryPrimitives.WriteDoubleLittleEndian(span.Slice(offset, 8), value);

        // ---- 常用图形 ----

        /// <summary>闭合矩形（4 条直线段，最后一段带 SegClosed）。</summary>
        public static FigSpec Rect(double x, double y, double w, double h)
        {
            var f = new FigSpec { StartX = x, StartY = y, Closed = true };
            f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { x + w, y } });
            f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { x + w, y + h } });
            f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { x, y + h } });
            f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { x, y }, Closed = true });
            return f;
        }

        /// <summary>闭合三角形。</summary>
        public static FigSpec Triangle(double ax, double ay, double bx, double by, double cx, double cy)
        {
            var f = new FigSpec { StartX = ax, StartY = ay, Closed = true };
            f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { bx, by } });
            f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { cx, cy } });
            f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { ax, ay }, Closed = true });
            return f;
        }

        /// <summary>闭合多边形（点对数组，自动回到起点）。</summary>
        public static FigSpec Polygon(params double[] xy)
        {
            var f = new FigSpec { StartX = xy[0], StartY = xy[1], Closed = true };
            for (int i = 2; i + 1 < xy.Length; i += 2)
                f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { xy[i], xy[i + 1] } });
            f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { xy[0], xy[1] }, Closed = true });
            return f;
        }

        /// <summary>四段三次贝塞尔近似圆（控制点常数 0.5522847498307936）。</summary>
        public static FigSpec Circle(double cx, double cy, double r)
        {
            const double k = 0.5522847498307936;
            double kr = k * r;
            var f = new FigSpec { StartX = cx + r, StartY = cy, Closed = true };
            f.Segs.Add(new SegSpec { Kind = 'C', Pts = new[] { cx + r, cy + kr, cx + kr, cy + r, cx, cy + r } });
            f.Segs.Add(new SegSpec { Kind = 'C', Pts = new[] { cx - kr, cy + r, cx - r, cy + kr, cx - r, cy } });
            f.Segs.Add(new SegSpec { Kind = 'C', Pts = new[] { cx - r, cy - kr, cx - kr, cy - r, cx, cy - r } });
            f.Segs.Add(new SegSpec { Kind = 'C', Pts = new[] { cx + kr, cy - r, cx + r, cy - kr, cx + r, cy }, Closed = true });
            return f;
        }

        /// <summary>单段三次贝塞尔（开放图形）。</summary>
        public static FigSpec Cubic(double x0, double y0, double x1, double y1,
            double x2, double y2, double x3, double y3)
        {
            var f = new FigSpec { StartX = x0, StartY = y0 };
            f.Segs.Add(new SegSpec { Kind = 'C', Pts = new[] { x1, y1, x2, y2, x3, y3 } });
            return f;
        }

        /// <summary>水平线段（两个点，不闭合）。</summary>
        public static FigSpec Line(double x0, double y0, double x1, double y1)
        {
            var f = new FigSpec { StartX = x0, StartY = y0 };
            f.Segs.Add(new SegSpec { Kind = 'L', Pts = new[] { x1, y1 } });
            return f;
        }
    }

    // ==================================================================
    //  JSON 便捷读写
    // ==================================================================

    public static class JsonHelp
    {
        public static JsonArray Arr(params double[] values)
        {
            var a = new JsonArray();
            foreach (double v in values) a.Add(v);
            return a;
        }

        public static JsonArray ArrOf(params int[] values)
        {
            var a = new JsonArray();
            foreach (int v in values) a.Add(v);
            return a;
        }

        /// <summary>把 JsonNode 读成 double；兼容 JSON 的命名浮点字面量（"NaN"/"Infinity"/"-Infinity"）。</summary>
        public static double AsDouble(JsonNode node)
        {
            if (node is JsonValue v)
            {
                if (v.TryGetValue(out double d)) return d;
                if (v.TryGetValue(out string s))
                {
                    switch (s)
                    {
                        case "NaN": return double.NaN;
                        case "Infinity": return double.PositiveInfinity;
                        case "-Infinity": return double.NegativeInfinity;
                        default: return double.Parse(s, System.Globalization.CultureInfo.InvariantCulture);
                    }
                }
            }
            throw new InvalidOperationException("不是数值节点：" + node?.ToJsonString());
        }

        public static double[] Doubles(JsonNode node)
        {
            if (node == null) return null;
            var a = (JsonArray)node;
            var result = new double[a.Count];
            for (int i = 0; i < a.Count; i++) result[i] = AsDouble(a[i]);
            return result;
        }

        public static double Num(JsonNode node, string name, double fallback = 0)
        {
            JsonNode v = node?[name];
            return v == null ? fallback : AsDouble(v);
        }

        public static bool Flag(JsonNode node, string name, bool fallback = false)
        {
            JsonNode v = node?[name];
            return v == null ? fallback : v.GetValue<bool>();
        }

        public static string Str(JsonNode node, string name)
        {
            JsonNode v = node?[name];
            return v == null ? null : v.GetValue<string>();
        }

        public static byte[] Hex(string hex)
        {
            if (hex == null) return null;
            var bytes = new byte[hex.Length / 2];
            for (int i = 0; i < bytes.Length; i++)
                bytes[i] = Convert.ToByte(hex.Substring(i * 2, 2), 16);
            return bytes;
        }

        public static string ToHex(byte[] bytes)
        {
            if (bytes == null) return null;
            var chars = new char[bytes.Length * 2];
            const string digits = "0123456789abcdef";
            for (int i = 0; i < bytes.Length; i++)
            {
                chars[i * 2] = digits[bytes[i] >> 4];
                chars[i * 2 + 1] = digits[bytes[i] & 0xF];
            }
            return new string(chars);
        }
    }
}

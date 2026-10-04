// Licensed to the .NET Foundation under one or more agreements.
//
// U1c：Windows 侧 runner —— 用 NativeLibrary.Load(真身全路径) +
// Marshal.GetDelegateForFunctionPointer 调用 wpfgfx_cor3.dll 的 MilUtility_* 导出。
//
// 【为什么不用 DllImport】
//   真身在 C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\<ver>\ 下，
//   名字解析会被"同目录其它 wpfgfx 副本 / 搜索路径"干扰。用绝对路径 Load + GetExport
//   可以保证：调的就是那一个文件，且导出缺失会立刻暴露（TryGetExport 返回 false）。
//
// 【ABI 探测】
//   MilUtility_ArcToBezier 是唯一一个"按值传结构体"的导出
//   （MilPoint2D ptStart / MilPoint2D rRadii / MilPoint2D ptEnd）。
//   x64 Windows 下 16 字节的 double 对结构体到底是走 XMM 还是走影子内存，
//   文档说法含混，所以这里**两种委托都声明**，用契约自检挑出真身认的那一种：
//     cPieces ∈ [-1,4]；cPieces==0 时 pPt[0] == ptEnd；cPieces>0 时
//     pPt[3*cPieces-1] == ptEnd（上游最后一点直接写 (xEnd,yEnd)）。
//   选中的形态记进结果文件的 AbiNote 字段，报告里如实写。

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text.Json.Nodes;

namespace WpfGfx.Linux.Parity.Geometry
{
    [StructLayout(LayoutKind.Sequential)]
    public struct Pt2D
    {
        public double X;
        public double Y;
        public Pt2D(double x, double y) { X = x; Y = y; }
    }

    public unsafe sealed class NativeGeometryRunner : IGeometryRunner
    {
        private readonly IntPtr _module;
        public string AbiNote { get; private set; } = "未探测";
        public readonly List<string> MissingExports = new List<string>();

        private readonly List<(bool filled, bool closed, float[] pts, byte[] types)> _figures =
            new List<(bool, bool, float[], byte[])>();

        // ---- 委托声明 ----------------------------------------------------

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate void ArcFlatFn(double sx, double sy, double rw, double rh, double rot,
            int fLargeArc, int fSweepUp, double ex, double ey,
            double* pMatrix, double* pPt, out int cPieces);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate void ArcStructFn(Pt2D ptStart, Pt2D radii, double rot,
            int fLargeArc, int fSweepUp, Pt2D ptEnd,
            double* pMatrix, double* pPt, out int cPieces);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate void ArcRefFn(ref Pt2D ptStart, ref Pt2D radii, double rot,
            int fLargeArc, int fSweepUp, ref Pt2D ptEnd,
            double* pMatrix, double* pPt, out int cPieces);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int PathBoundsFn(PenData* pen, double* dash, double* world,
            int fillRule, byte* path, uint nSize, double* geom, double tol, int relative,
            int skipHollows, Ltrb4* bounds);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int PolyBoundsFn(double* world, PenData* pen, double* dash,
            Pt2D* points, byte* types, uint pointCount, uint segmentCount, double* geom,
            double tol, int relative, int skipHollows, Rect4* bounds);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int FlattenFn(double* matrix, int fillRule, byte* path, uint nSize,
            double tol, int relative, AddFigureNative cb, int* outFillRule);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int WidenFn(PenData* pen, double* dash, double* matrix, int fillRule,
            byte* path, uint nSize, double tol, int relative, AddFigureNative cb, int* outFillRule);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int CombineFn(double* matrix, double* m1, int fr1, byte* p1, uint n1,
            double* m2, int fr2, byte* p2, uint n2, double tol, int relative,
            AddFigureNative cb, int combineMode, int* outFillRule);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int HitTestFn(double* matrix, PenData* pen, double* dash, int fillRule,
            byte* path, uint nSize, double tol, int relative, Pt2D* hitPoint, int* contains);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int PolyHitFn(double* matrix, PenData* pen, double* dash,
            Pt2D* points, byte* types, uint cPoints, uint cSegments, double tol, int relative,
            Pt2D* hitPoint, int* contains);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int HitPathFn(double* m1, int fr1, byte* p1, uint n1,
            double* m2, int fr2, byte* p2, uint n2, double tol, int relative, int* detail);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int AreaFn(int fillRule, byte* path, uint nSize, double* matrix,
            double tol, int relative, double* area);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int LengthFn(double* matrix, int fillRule, byte* path, uint nSize,
            double fraction, Pt2D* pt, Pt2D* tangent);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate void TileBrushFn(D3D* transform, D3D* relativeTransform,
            int stretch, int alignX, int alignY, int viewportUnits, int viewboxUnits,
            Rect4* shapeFillBounds, Rect4* contentBounds,
            Rect4* viewport, Rect4* viewbox, D3D* contentToShape, int* brushIsEmpty);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate int CopyPixelsFn(byte* output, uint outputSize, uint outputStride,
            uint outputOffsetBits, byte* input, uint inputSize, uint inputStride,
            uint inputOffsetBits, uint height, uint copyWidthBits);

        [UnmanagedFunctionPointer(CallingConvention.Winapi)]
        private delegate void AddFigureNative(int isFilled, int isClosed, float* pPoints,
            uint pointCount, byte* pTypes, uint typeCount);

        [StructLayout(LayoutKind.Sequential)]
        public struct PenData
        {
            public double Thickness;
            public double MiterLimit;
            public double DashOffset;
            public int StartLineCap;
            public int EndLineCap;
            public int DashCap;
            public int LineJoin;
            public uint DashArraySize;
        }

        /// <summary>X/Y/Width/Height（MilPointAndSizeD，PolygonBounds 与 TileBrush 用）。</summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct Rect4
        {
            public double X, Y, Width, Height;
        }

        /// <summary>
        /// Left/Top/Right/Bottom（MilRectD）。
        /// ⚠️ MilUtility_**PathGeometry**Bounds 的输出是 MilRectD（geometry_api.cpp:556
        /// 的 `__out MilRectD *pBounds`），而 MilUtility_**Polygon**Bounds 的输出是
        /// MilPointAndSizeD（geometry_api.cpp:499）——两者布局一样但语义不同，
        /// 第一版把前者也按 XYWH 读，导致"真机包围盒凭空变大"的假偏差。
        /// </summary>
        [StructLayout(LayoutKind.Sequential)]
        public struct Ltrb4
        {
            public double Left, Top, Right, Bottom;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct D3D
        {
            public float M11, M12, M13, M14;
            public float M21, M22, M23, M24;
            public float M31, M32, M33, M34;
            public float M41, M42, M43, M44;
        }

        // ---- 构造 / 取导出 -----------------------------------------------

        /// <summary>
        /// ArcToBezier 的按值结构体 ABI 形态。x64 Windows 上 16 字节的 double 对结构体
        /// 到底进 XMM 还是走"按引用传副本"，文档说法含混，所以三种形态都实现，
        /// 由外部（脚本）逐个进程试，能过契约自检的那一种胜出——不要在进程内试，
        /// 试错的那一次会直接把进程打崩（0xC0000005）。
        /// </summary>
        public enum ArcAbi
        {
            /// <summary>三个 double 对摊平成 6 个 double 参数。</summary>
            Flat,
            /// <summary>三个 Pt2D 按值传（本机实测胜出）。</summary>
            StructValue,
            /// <summary>三个 Pt2D 按引用传（上游"16 字节结构体按引用传副本"规则）。</summary>
            StructRef,
        }

        public ArcAbi Abi { get; }

        public NativeGeometryRunner(string dllPath) : this(dllPath, ArcAbi.StructValue)
        {
        }

        public NativeGeometryRunner(string dllPath, ArcAbi abi)
        {
            Abi = abi;
            AbiNote = abi switch
            {
                ArcAbi.Flat => "flat：MilPoint2D 摊成 2 个 double 参数",
                ArcAbi.StructValue => "struct: Pt2D 按值（16 字节 double 对进寄存器）",
                _ => "ref: Pt2D 按引用（调用方副本的指针）",
            };
            _module = NativeLibrary.Load(dllPath);
        }

        /// <summary>
        /// 单例契约自检：单位圆上的 90° 弧，(0,0) → (10,10) 半径 (10,10)。
        /// 末点必须等于 ptEnd、cPieces 必须在 [-1,4]。返回 null 表示通过。
        /// </summary>
        public static string SelfCheck(string dllPath, ArcAbi abi)
        {
            IntPtr module = NativeLibrary.Load(dllPath);
            var pts = new double[24];
            int pieces;
            fixed (double* pp = pts)
            {
                switch (abi)
                {
                    case ArcAbi.Flat:
                    {
                        var f = (ArcFlatFn)Marshal.GetDelegateForFunctionPointer(
                            NativeLibrary.GetExport(module, "MilUtility_ArcToBezier"), typeof(ArcFlatFn));
                        f(0, 0, 10, 10, 0, 0, 1, 10, 10, null, pp, out pieces);
                        break;
                    }
                    case ArcAbi.StructRef:
                    {
                        var f = (ArcRefFn)Marshal.GetDelegateForFunctionPointer(
                            NativeLibrary.GetExport(module, "MilUtility_ArcToBezier"), typeof(ArcRefFn));
                        var a = new Pt2D(0, 0);
                        var r = new Pt2D(10, 10);
                        var e = new Pt2D(10, 10);
                        f(ref a, ref r, 0, 0, 1, ref e, null, pp, out pieces);
                        break;
                    }
                    default:
                    {
                        var f = (ArcStructFn)Marshal.GetDelegateForFunctionPointer(
                            NativeLibrary.GetExport(module, "MilUtility_ArcToBezier"), typeof(ArcStructFn));
                        f(new Pt2D(0, 0), new Pt2D(10, 10), 0, 0, 1, new Pt2D(10, 10), null, pp, out pieces);
                        break;
                    }
                }
                if (!ContractOk(pieces, pp, 10, 10))
                    return $"契约自检失败：cPieces={pieces} pts=[{string.Join(",", pts.AsSpan(0, 12).ToArray())}]";
            }
            return null;
        }

        // ---- 取导出 ------------------------------------------------------

        private T Fn<T>(string name) where T : Delegate
        {
            if (!NativeLibrary.TryGetExport(_module, name, out IntPtr p))
            {
                if (!MissingExports.Contains(name)) MissingExports.Add(name);
                throw new EntryPointNotFoundException("真身 DLL 里没有导出 " + name);
            }
            return Marshal.GetDelegateForFunctionPointer<T>(p);
        }

        /// <summary>
        /// 严格的契约自检。**必须**卡住"退化成直线"这个假通过路径：
        /// 半径若是垃圾值，AcceptRadius 会拒收 → cPieces=0 → pPt[0] 恰好等于 ptEnd，
        /// 弱检查会误判为通过（第一版就踩了这个坑，flat/ref 都"通过"过）。
        /// 这里额外要求 pieces == 1，并且贝塞尔中点的真实位置落在以圆心为心、半径 10 的圆上
        /// （圆心是 (0,10) 或 (10,0)，取决于 sweep 方向）。
        /// </summary>
        private static bool ContractOk(int pieces, double* pp, double ex, double ey)
        {
            if (pieces != 1) return false;

            double lastX = pp[4], lastY = pp[5];
            if (Math.Abs(lastX - ex) > 1e-9 || Math.Abs(lastY - ey) > 1e-9) return false;

            // 三次贝塞尔在 t=0.5 处：(P0 + 3C1 + 3C2 + P3) / 8
            double mx = (0 + 3 * pp[0] + 3 * pp[2] + lastX) / 8.0;
            double my = (0 + 3 * pp[1] + 3 * pp[3] + lastY) / 8.0;

            double d1 = Math.Sqrt(mx * mx + (my - 10) * (my - 10));       // 圆心 (0,10)
            double d2 = Math.Sqrt((mx - 10) * (mx - 10) + my * my);       // 圆心 (10,0)
            return Math.Abs(d1 - 10) < 1e-6 || Math.Abs(d2 - 10) < 1e-6;
        }

        // ---- 主入口 ------------------------------------------------------

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
                    default: b.Error("native runner 不认识的函数：" + c.Fn); break;
                }
            }
            catch (Exception ex)
            {
                b.Error(ex.GetType().Name + ": " + ex.Message);
            }
            return b.Result;
        }

        // ---- 参数搬运 ----------------------------------------------------

        private static double* Matrix(JsonObject a, string name, double* scratch6)
        {
            double[] v = JsonHelp.Doubles(a[name]);
            if (v == null) return null;
            for (int i = 0; i < 6; i++) scratch6[i] = v[i];
            return scratch6;
        }

        private static void FillPen(JsonObject a, PenData* pen, double* dashScratch, out double* dash)
        {
            dash = null;
            JsonObject p = a["pen"] as JsonObject;
            if (p == null) return;
            *pen = new PenData
            {
                Thickness = JsonHelp.Num(p, "thickness", 0),
                MiterLimit = JsonHelp.Num(p, "miterLimit", 10),
                DashOffset = JsonHelp.Num(p, "dashOffset", 0),
                StartLineCap = (int)JsonHelp.Num(p, "startCap", 0),
                EndLineCap = (int)JsonHelp.Num(p, "endCap", 0),
                DashCap = (int)JsonHelp.Num(p, "dashCap", 0),
                LineJoin = (int)JsonHelp.Num(p, "join", 0),
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

        private void Collect(int isFilled, int isClosed, float* pPoints, uint pointCount,
            byte* pTypes, uint typeCount)
        {
            var pts = new float[pointCount * 2];
            for (uint i = 0; i < pointCount; i++)
            {
                pts[i * 2] = pPoints[i * 2];
                pts[i * 2 + 1] = pPoints[i * 2 + 1];
            }
            var types = new byte[typeCount];
            for (uint i = 0; i < typeCount; i++) types[i] = pTypes[i];
            _figures.Add((isFilled != 0, isClosed != 0, pts, types));
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
            int large = JsonHelp.Flag(a, "largeArc") ? 1 : 0;
            int sweep = JsonHelp.Flag(a, "sweepCw") ? 1 : 0;
            double rot = JsonHelp.Num(a, "rotation", 0);

            var pts = new double[24];
            int pieces;
            fixed (double* pp = pts)
            {
                switch (Abi)
                {
                    case ArcAbi.Flat:
                    {
                        ArcFlatFn f = Fn<ArcFlatFn>("MilUtility_ArcToBezier");
                        f(s[0], s[1], r[0], r[1], rot, large, sweep, e[0], e[1], m, pp, out pieces);
                        break;
                    }
                    case ArcAbi.StructRef:
                    {
                        ArcRefFn f = Fn<ArcRefFn>("MilUtility_ArcToBezier");
                        var pa = new Pt2D(s[0], s[1]);
                        var pr = new Pt2D(r[0], r[1]);
                        var pe = new Pt2D(e[0], e[1]);
                        f(ref pa, ref pr, rot, large, sweep, ref pe, m, pp, out pieces);
                        break;
                    }
                    default:
                    {
                        ArcStructFn f = Fn<ArcStructFn>("MilUtility_ArcToBezier");
                        f(new Pt2D(s[0], s[1]), new Pt2D(r[0], r[1]), rot, large, sweep,
                          new Pt2D(e[0], e[1]), m, pp, out pieces);
                        break;
                    }
                }
            }

            b.Hr(0);
            b.Set("cPieces", pieces);
            int count = pieces < 0 ? 0 : (pieces == 0 ? 1 : 3 * pieces);
            b.Set("pointCount", count);
            var flat = new double[count * 2];
            for (int i = 0; i < count; i++)
            {
                flat[i * 2] = pts[i * 2];
                flat[i * 2 + 1] = pts[i * 2 + 1];
            }
            b.Vec("points", flat);
        }

        private void RunPathBounds(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = JsonHelp.Hex(JsonHelp.Str(a, "path"));
            double* worldScratch = stackalloc double[6];
            double* world = Matrix(a, "worldMatrix", worldScratch);
            double* geomScratch = stackalloc double[6];
            double* geom = Matrix(a, "geometryMatrix", geomScratch);
            PenData pen = default;
            double* dashScratch = stackalloc double[16];
            FillPen(a, &pen, dashScratch, out double* dash);
            bool hasPen = a["pen"] != null;

            PathBoundsFn f = Fn<PathBoundsFn>("MilUtility_PathGeometryBounds");
            Ltrb4 bounds = default;
            int hr;
            fixed (byte* p = path)
            {
                hr = f(hasPen ? &pen : null, dash, world, (int)JsonHelp.Num(a, "fillRule", 0),
                    p, (uint)path.Length, geom, JsonHelp.Num(a, "tolerance", 0.1),
                    JsonHelp.Flag(a, "relative") ? 1 : 0, JsonHelp.Flag(a, "skipHollows") ? 1 : 0,
                    &bounds);
            }
            b.Hr(hr);
            b.Set("left", bounds.Left).Set("top", bounds.Top)
             .Set("right", bounds.Right).Set("bottom", bounds.Bottom)
             .Set("width", bounds.Right - bounds.Left).Set("height", bounds.Bottom - bounds.Top);
            b.Vec("rawLtrb", bounds.Left, bounds.Top, bounds.Right, bounds.Bottom);
        }

        private void RunPolyBounds(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            double[] pts = JsonHelp.Doubles(a["points"]);
            double[] typesD = JsonHelp.Doubles(a["types"]);
            var types = new byte[typesD.Length];
            for (int i = 0; i < typesD.Length; i++) types[i] = (byte)typesD[i];
            var mpts = new Pt2D[pts.Length / 2];
            for (int i = 0; i < mpts.Length; i++) mpts[i] = new Pt2D(pts[i * 2], pts[i * 2 + 1]);

            double* worldScratch = stackalloc double[6];

            double* world = Matrix(a, "worldMatrix", worldScratch);
            double* geomScratch = stackalloc double[6];
            double* geom = Matrix(a, "geometryMatrix", geomScratch);
            PenData pen = default;
            double* dashScratch = stackalloc double[16];
            FillPen(a, &pen, dashScratch, out double* dash);
            bool hasPen = a["pen"] != null;

            PolyBoundsFn f = Fn<PolyBoundsFn>("MilUtility_PolygonBounds");
            Rect4 bounds = default;
            int hr;
            fixed (Pt2D* pp = mpts)
            fixed (byte* pt = types)
            {
                hr = f(world, hasPen ? &pen : null, dash, pp, pt,
                    (uint)JsonHelp.Num(a, "pointCount", mpts.Length),
                    (uint)JsonHelp.Num(a, "segmentCount", types.Length),
                    geom, JsonHelp.Num(a, "tolerance", 0.1),
                    JsonHelp.Flag(a, "relative") ? 1 : 0, JsonHelp.Flag(a, "skipHollows") ? 1 : 0,
                    &bounds);
            }
            b.Hr(hr);
            b.Set("left", bounds.X).Set("top", bounds.Y)
             .Set("right", bounds.X + bounds.Width).Set("bottom", bounds.Y + bounds.Height);
        }

        private void RunFlatten(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = JsonHelp.Hex(JsonHelp.Str(a, "path"));
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            _figures.Clear();
            AddFigureNative cb = Collect;
            FlattenFn f = Fn<FlattenFn>("MilUtility_PathGeometryFlatten");
            int outRule;
            int hr;
            fixed (byte* p = path)
            {
                hr = f(m, (int)JsonHelp.Num(a, "fillRule", 0), p, (uint)path.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative") ? 1 : 0,
                    cb, &outRule);
            }
            b.Hr(hr).Set("outFillRule", outRule);
            EmitFigures(b);
        }

        private void RunOutline(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = JsonHelp.Hex(JsonHelp.Str(a, "path"));
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            _figures.Clear();
            AddFigureNative cb = Collect;
            // MilUtility_PathGeometryOutline 与 Flatten 参数表完全一致
            //（geometry_api.cpp:219 vs :421），复用同一个委托类型。
            FlattenFn f = Fn<FlattenFn>("MilUtility_PathGeometryOutline");
            int outRule;
            int hr;
            fixed (byte* p = path)
            {
                hr = f(m, (int)JsonHelp.Num(a, "fillRule", 0), p, (uint)path.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative") ? 1 : 0,
                    cb, &outRule);
            }
            b.Hr(hr).Set("outFillRule", outRule);
            EmitFigures(b);
        }

        private void RunWiden(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = JsonHelp.Hex(JsonHelp.Str(a, "path"));
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            PenData pen = default;
            double* dashScratch = stackalloc double[16];
            FillPen(a, &pen, dashScratch, out double* dash);
            _figures.Clear();
            AddFigureNative cb = Collect;
            WidenFn f = Fn<WidenFn>("MilUtility_PathGeometryWiden");
            // ⚠️ 上游 MilUtility_PathGeometryWiden **从不写** *pOutFillRule
            //（geometry_api.cpp:151-217 与 Outline:254 / Flatten:452 / Combine:397 不同，
            //  那三个都有显式赋值）。所以真机回给你的是**未初始化的栈值**。
            // 这里塞一个哨兵：如果返回值仍是哨兵，就证明"根本没写"。
            int outRule = unchecked((int)0x5EED0001);
            int hr;
            fixed (byte* p = path)
            {
                hr = f(&pen, dash, m, (int)JsonHelp.Num(a, "fillRule", 0), p, (uint)path.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative") ? 1 : 0,
                    cb, &outRule);
            }
            b.Hr(hr).Set("outFillRule", outRule);
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
            _figures.Clear();
            AddFigureNative cb = Collect;
            CombineFn f = Fn<CombineFn>("MilUtility_PathGeometryCombine");
            int outRule;
            int hr;
            fixed (byte* x = p1)
            fixed (byte* y = p2)
            {
                hr = f(m, m1, (int)JsonHelp.Num(a, "fillRule1", 0), x, (uint)p1.Length,
                    m2, (int)JsonHelp.Num(a, "fillRule2", 0), y, (uint)p2.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative") ? 1 : 0,
                    cb, (int)JsonHelp.Num(a, "combineMode", 0), &outRule);
            }
            b.Hr(hr).Set("outFillRule", outRule);
            EmitFigures(b);
        }

        private void RunHit(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = JsonHelp.Hex(JsonHelp.Str(a, "path"));
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            PenData pen = default;
            double* dashScratch = stackalloc double[16];
            FillPen(a, &pen, dashScratch, out double* dash);
            bool hasPen = a["pen"] != null;
            double[] hp = JsonHelp.Doubles(a["hitPoint"]);
            var hit = new Pt2D(hp[0], hp[1]);

            HitTestFn f = Fn<HitTestFn>("MilUtility_PathGeometryHitTest");
            int contains;
            int hr;
            fixed (byte* p = path)
            {
                hr = f(m, hasPen ? &pen : null, dash, (int)JsonHelp.Num(a, "fillRule", 0),
                    p, (uint)path.Length, JsonHelp.Num(a, "tolerance", 0),
                    JsonHelp.Flag(a, "relative") ? 1 : 0, &hit, &contains);
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
            var mpts = new Pt2D[pts.Length / 2];
            for (int i = 0; i < mpts.Length; i++) mpts[i] = new Pt2D(pts[i * 2], pts[i * 2 + 1]);
            double[] hp = JsonHelp.Doubles(a["hitPoint"]);
            var hit = new Pt2D(hp[0], hp[1]);
            PenData pen = default;
            double* dashScratch = stackalloc double[16];
            FillPen(a, &pen, dashScratch, out double* dash);
            bool hasPen = a["pen"] != null;

            PolyHitFn f = Fn<PolyHitFn>("MilUtility_PolygonHitTest");
            int contains;
            int hr;
            fixed (Pt2D* pp = mpts)
            fixed (byte* pt = types)
            {
                hr = f(null, hasPen ? &pen : null, dash, pp, pt,
                    (uint)JsonHelp.Num(a, "pointCount", mpts.Length),
                    (uint)JsonHelp.Num(a, "segmentCount", types.Length),
                    JsonHelp.Num(a, "tolerance", 0), JsonHelp.Flag(a, "relative") ? 1 : 0,
                    &hit, &contains);
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

            HitPathFn f = Fn<HitPathFn>("MilUtility_PathGeometryHitTestPathGeometry");
            int detail;
            int hr;
            fixed (byte* x = p1)
            fixed (byte* y = p2)
            {
                hr = f(m1, (int)JsonHelp.Num(a, "fillRule1", 0), x, (uint)p1.Length,
                    m2, (int)JsonHelp.Num(a, "fillRule2", 0), y, (uint)p2.Length,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative") ? 1 : 0, &detail);
            }
            b.Hr(hr).Set("detail", detail);
        }

        private void RunArea(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = JsonHelp.Hex(JsonHelp.Str(a, "path"));
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            AreaFn f = Fn<AreaFn>("MilUtility_GeometryGetArea");
            double area = 0;
            int hr;
            fixed (byte* p = path)
            {
                hr = f((int)JsonHelp.Num(a, "fillRule", 0), p, (uint)path.Length, m,
                    JsonHelp.Num(a, "tolerance", 0.1), JsonHelp.Flag(a, "relative") ? 1 : 0, &area);
            }
            b.Hr(hr).Set("area", area);
        }

        private void RunLength(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] path = JsonHelp.Hex(JsonHelp.Str(a, "path"));
            double* mScratch = stackalloc double[6];
            double* m = Matrix(a, "matrix", mScratch);
            LengthFn f = Fn<LengthFn>("MilUtility_GetPointAtLengthFraction");
            Pt2D pt, tangent;
            int hr;
            fixed (byte* p = path)
            {
                hr = f(m, (int)JsonHelp.Num(a, "fillRule", 0), p, (uint)path.Length,
                    JsonHelp.Num(a, "fraction", 0), &pt, &tangent);
            }
            b.Hr(hr);
            b.Vec2("point", pt.X, pt.Y).Vec2("tangent", tangent.X, tangent.Y);
        }

        private void RunTileBrush(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            D3D tfStore = default, rtfStore = default;
            D3D* tf = null, rtf = null;
            if (a["transform"] is JsonArray ta) { tfStore = ToD3D(JsonHelp.Doubles(ta)); tf = &tfStore; }
            if (a["relativeTransform"] is JsonArray ra) { rtfStore = ToD3D(JsonHelp.Doubles(ra)); rtf = &rtfStore; }

            Rect4 shapeStore = default, contentStore = default;
            Rect4* shape = ToRect(JsonHelp.Doubles(a["shapeFillBounds"]), &shapeStore);
            Rect4* content = ToRect(JsonHelp.Doubles(a["contentBounds"]), &contentStore);
            Rect4 viewport = RectOf(JsonHelp.Doubles(a["viewport"]));
            Rect4 viewbox = RectOf(JsonHelp.Doubles(a["viewbox"]));
            D3D outMatrix = default;
            int empty = 0;

            TileBrushFn f = Fn<TileBrushFn>("MilUtility_GetTileBrushMapping");
            f(tf, rtf, (int)JsonHelp.Num(a, "stretch", 0), (int)JsonHelp.Num(a, "alignX", 0),
                (int)JsonHelp.Num(a, "alignY", 0), (int)JsonHelp.Num(a, "viewportUnits", 0),
                (int)JsonHelp.Num(a, "viewboxUnits", 0), shape, content, &viewport, &viewbox,
                &outMatrix, &empty);

            b.Hr(0);
            b.Set("brushIsEmpty", empty);
            b.Set("vp.x", viewport.X).Set("vp.y", viewport.Y)
             .Set("vp.w", viewport.Width).Set("vp.h", viewport.Height);
            b.Set("vb.x", viewbox.X).Set("vb.y", viewbox.Y)
             .Set("vb.w", viewbox.Width).Set("vb.h", viewbox.Height);
            var cells = new double[16];
            cells[0] = outMatrix.M11; cells[1] = outMatrix.M12; cells[2] = outMatrix.M13; cells[3] = outMatrix.M14;
            cells[4] = outMatrix.M21; cells[5] = outMatrix.M22; cells[6] = outMatrix.M23; cells[7] = outMatrix.M24;
            cells[8] = outMatrix.M31; cells[9] = outMatrix.M32; cells[10] = outMatrix.M33; cells[11] = outMatrix.M34;
            cells[12] = outMatrix.M41; cells[13] = outMatrix.M42; cells[14] = outMatrix.M43; cells[15] = outMatrix.M44;
            b.Vec("contentToShape", cells);
        }

        private static D3D ToD3D(double[] v)
        {
            var m = new D3D();
            float[] cells =
            {
                (float)v[0], (float)v[1], (float)v[2], (float)v[3],
                (float)v[4], (float)v[5], (float)v[6], (float)v[7],
                (float)v[8], (float)v[9], (float)v[10], (float)v[11],
                (float)v[12], (float)v[13], (float)v[14], (float)v[15],
            };
            m.M11 = cells[0]; m.M12 = cells[1]; m.M13 = cells[2]; m.M14 = cells[3];
            m.M21 = cells[4]; m.M22 = cells[5]; m.M23 = cells[6]; m.M24 = cells[7];
            m.M31 = cells[8]; m.M32 = cells[9]; m.M33 = cells[10]; m.M34 = cells[11];
            m.M41 = cells[12]; m.M42 = cells[13]; m.M43 = cells[14]; m.M44 = cells[15];
            return m;
        }

        private static Rect4* ToRect(double[] v, Rect4* store)
        {
            if (v == null) return null;
            *store = new Rect4 { X = v[0], Y = v[1], Width = v[2], Height = v[3] };
            return store;
        }

        private static Rect4 RectOf(double[] v) =>
            v == null ? default : new Rect4 { X = v[0], Y = v[1], Width = v[2], Height = v[3] };

        private void RunCopyPixels(GeometryCase c, ResultBuilder b)
        {
            JsonObject a = c.Args;
            byte[] input = JsonHelp.Hex(JsonHelp.Str(a, "inputHex"));
            byte[] seed = JsonHelp.Hex(JsonHelp.Str(a, "outputSeedHex"));
            uint outSize = (uint)JsonHelp.Num(a, "outputSize");
            var output = new byte[outSize];
            if (seed != null) Array.Copy(seed, output, Math.Min(seed.Length, output.Length));

            CopyPixelsFn f = Fn<CopyPixelsFn>("MilUtility_CopyPixelBuffer");
            int hr;
            fixed (byte* po = output)
            fixed (byte* pi = input)
            {
                hr = f(po, outSize, (uint)JsonHelp.Num(a, "outputStride"),
                    (uint)JsonHelp.Num(a, "outputOffsetInBits"), pi,
                    (uint)JsonHelp.Num(a, "inputSize"), (uint)JsonHelp.Num(a, "inputStride"),
                    (uint)JsonHelp.Num(a, "inputOffsetInBits"), (uint)JsonHelp.Num(a, "height"),
                    (uint)JsonHelp.Num(a, "copyWidthInBits"));
            }
            b.Hr(hr);
            b.Buffer("output", output);
        }

        private void RunProbe(GeometryCase c, ResultBuilder b)
        {
            b.Hr(0);
            int index = 0;
            foreach (JsonNode n in (JsonArray)c.Args["names"])
            {
                string name = n.GetValue<string>();
                bool found = NativeLibrary.TryGetExport(_module, name, out _);
                b.Set("resolved." + index, found ? 1 : 0);
                if (!found) MissingExports.Add(name);
                index++;
            }
        }
    }
}

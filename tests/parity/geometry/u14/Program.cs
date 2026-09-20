// Licensed to the .NET Foundation under one or more agreements.
//
// U14：曲率展平（flatten）密度差异的量化与原型。
//
// 【为什么独立于 src/】
//   本轮不改引擎（M7b 正在改 src/WpfGfx.Linux/Interop/），所以这个工具**不引用
//   WpfGfx.Linux**：输入全部来自 tests/parity/geometry/ 的数据文件
//   （cases.json 的路径字节块 + windows-results.json / linux-results.json 的实测点集），
//   需要"我方当前算法"时在本文件里按源码逐行复刻（见 SimOursFlatten），
//   需要"上游算法"时按 bezierflattener.cpp 逐行移植（见 HfdFlatten）。
//   这样既不碰 M7b 的 lane，也不受他们半成品编译状态影响。
//
// 【口径声明（U1c 教训：先确认两侧同口径、同源）】
//   · 点集来源：真机 = windows-results.json（真身 DLL 10.0.7，sha256 见该文件）；
//     我方 = linux-results.json（同一份 cases.json 跑出来的）。
//   · 精度口径：两侧的点都是 **float32**（真机经 CFigureData 的 MilPoint2F，
//     我方经 Skia 的 SKPoint），所以对照时一律把输入控制点与输出点都归到 float32。
//   · 容差口径：真机的绝对容差由 CShapeBase::GetAbsoluteTolerance 决定
//     （shapebase.cpp:1561），本工具按同一公式复算，见 AbsoluteTolerance()。

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using WpfGfx.Linux.Parity.Geometry;

namespace WpfGfx.Linux.Parity.U14
{
    // ======================================================================
    //  路径字节块 → 图形/段（只读解析，风格与 PathGeometryParser 一致）
    // ======================================================================

    internal sealed class U14Case
    {
        public string Id;
        public JsonObject Args;
    }

    internal readonly struct Seg
    {
        public readonly char Kind;      // 'L' 直线 / 'C' 三次 / 'Q' 二次
        public readonly float[] P;      // L: 2; Q: 4; C: 6
        public Seg(char kind, params float[] p) { Kind = kind; P = p; }
    }

    internal sealed class Fig
    {
        public float Sx, Sy;
        public bool Closed;
        public readonly List<Seg> Segs = new List<Seg>();
    }

    internal static class PathReader
    {
        public static List<Fig> Parse(byte[] d)
        {
            var figs = new List<Fig>();
            if (d == null || d.Length < 48) return figs;
            uint figCount = U32(d, 40);
            int off = 48;
            for (uint f = 0; f < figCount; f++)
            {
                if (off + 40 > d.Length) break;
                uint flags = U32(d, off + 4);
                int segCount = (int)U32(d, off + 8);
                int figSize = (int)U32(d, off + 12);
                if (figSize < 40 || off + figSize > d.Length) break;

                var fig = new Fig
                {
                    Sx = (float)D(d, off + 16),
                    Sy = (float)D(d, off + 24),
                    Closed = (flags & 0x4) != 0,
                };

                int cur = off + 40, end = off + figSize;
                for (int s = 0; s < segCount && cur + 16 <= end; s++)
                {
                    uint type = U32(d, cur);
                    uint sf = U32(d, cur + 4);
                    bool gap = (sf & 0x4) != 0;
                    int size = type switch { 1 => 32, 2 => 64, 3 => 48, 4 => 64, 5 => 16 + 4 + 16 * (int)U32(d, cur + 16), _ => -1 };
                    if (size < 0 || cur + size > end) break;

                    if (gap)
                    {
                        // 抬笔：新起一个图形（与 PathGeometryParser 的处理一致）
                        var nf = new Fig { Sx = (float)D(d, cur + 16), Sy = (float)D(d, cur + 24), Closed = false };
                        figs.Add(nf);
                        fig = nf;
                    }
                    else if (type == 1)
                    {
                        fig.Segs.Add(new Seg('L', (float)D(d, cur + 16), (float)D(d, cur + 24)));
                    }
                    else if (type == 2)
                    {
                        fig.Segs.Add(new Seg('C',
                            (float)D(d, cur + 16), (float)D(d, cur + 24),
                            (float)D(d, cur + 32), (float)D(d, cur + 40),
                            (float)D(d, cur + 48), (float)D(d, cur + 56)));
                    }
                    else if (type == 3)
                    {
                        fig.Segs.Add(new Seg('Q',
                            (float)D(d, cur + 16), (float)D(d, cur + 24),
                            (float)D(d, cur + 32), (float)D(d, cur + 40)));
                    }
                    if ((sf & 0x10) != 0) fig.Closed = true;
                    cur += size;
                }
                figs.Add(fig);
                off += figSize;
            }
            return figs;
        }

        private static uint U32(byte[] d, int o) => BitConverter.ToUInt32(d, o);
        private static double D(byte[] d, int o) => BitConverter.ToDouble(d, o);
    }

    // ======================================================================
    //  几何：三次曲线求值 / 紧包围盒 / 折线距离
    // ======================================================================

    internal static class Geo
    {
        public static (double X, double Y) Cubic(double[] b, double t)
        {
            double u = 1 - t;
            double w0 = u * u * u, w1 = 3 * u * u * t, w2 = 3 * u * t * t, w3 = t * t * t;
            return (w0 * b[0] + w1 * b[2] + w2 * b[4] + w3 * b[6],
                    w0 * b[1] + w1 * b[3] + w2 * b[5] + w3 * b[7]);
        }

        /// <summary>三次贝塞尔的精确紧包围盒（解 x'(t)=0 / y'(t)=0）。</summary>
        public static (double MinX, double MinY, double MaxX, double MaxY) CubicBounds(double[] b)
        {
            double minX = Math.Min(b[0], b[6]), maxX = Math.Max(b[0], b[6]);
            double minY = Math.Min(b[1], b[7]), maxY = Math.Max(b[1], b[7]);
            foreach (double t in Extrema(b[0], b[2], b[4], b[6]))
            {
                var p = Cubic(b, t);
                minX = Math.Min(minX, p.X); maxX = Math.Max(maxX, p.X);
            }
            foreach (double t in Extrema(b[1], b[3], b[5], b[7]))
            {
                var p = Cubic(b, t);
                minY = Math.Min(minY, p.Y); maxY = Math.Max(maxY, p.Y);
            }
            return (minX, minY, maxX, maxY);
        }

        private static IEnumerable<double> Extrema(double p0, double p1, double p2, double p3)
        {
            // B'(t) = 3[(p1-p0) + 2(p0-2p1+p2)t + (3p1-3p2+p3-p0)t²]
            double a = 3 * p1 - 3 * p2 + p3 - p0;         // 三次项系数（未乘 3）
            double bb = 2 * (p0 - 2 * p1 + p2);
            double c = p1 - p0;
            // a t² + b t + c = 0
            if (Math.Abs(a) < 1e-14)
            {
                if (Math.Abs(bb) > 1e-14)
                {
                    double t = -c / bb;
                    if (t > 0 && t < 1) yield return t;
                }
                yield break;
            }
            double disc = bb * bb - 4 * a * c;
            if (disc < 0) yield break;
            double sq = Math.Sqrt(disc);
            double t1 = (-bb + sq) / (2 * a), t2 = (-bb - sq) / (2 * a);
            if (t1 > 0 && t1 < 1) yield return t1;
            if (t2 > 0 && t2 < 1) yield return t2;
        }

        /// <summary>点到线段距离。</summary>
        public static double PtSeg(double px, double py, double ax, double ay, double bx, double by)
        {
            double dx = bx - ax, dy = by - ay;
            double l2 = dx * dx + dy * dy;
            if (l2 <= 1e-30) return Math.Sqrt((px - ax) * (px - ax) + (py - ay) * (py - ay));
            double t = ((px - ax) * dx + (py - ay) * dy) / l2;
            t = t < 0 ? 0 : (t > 1 ? 1 : t);
            double qx = ax + t * dx, qy = ay + t * dy;
            return Math.Sqrt((px - qx) * (px - qx) + (py - qy) * (py - qy));
        }

        /// <summary>点到折线（把折线当闭合环时也包含末→首边）的最小距离。</summary>
        public static double PtPolyline(double px, double py, List<(double X, double Y)> poly, bool closed)
        {
            double best = double.PositiveInfinity;
            int n = poly.Count;
            for (int i = 0; i + 1 < n; i++)
                best = Math.Min(best, PtSeg(px, py, poly[i].X, poly[i].Y, poly[i + 1].X, poly[i + 1].Y));
            if (closed && n > 2)
                best = Math.Min(best, PtSeg(px, py, poly[n - 1].X, poly[n - 1].Y, poly[0].X, poly[0].Y));
            return best;
        }

        /// <summary>单侧 Hausdorff：折线 A 的每个顶点到折线 B 的最大距离。</summary>
        public static double OneSidedHausdorff(List<(double X, double Y)> a, List<(double X, double Y)> b, bool bClosed)
        {
            double worst = 0;
            foreach (var p in a) worst = Math.Max(worst, PtPolyline(p.X, p.Y, b, bClosed));
            return worst;
        }
    }

    // ======================================================================
    //  上游 CBezierFlattener 的逐行移植（bezierflattener.cpp:40-175, 199-309）
    // ======================================================================

    internal static class HfdFlattener
    {
        private const double TwiceMinStep = 1.0e-3;      // utils.h:39
        private const double SqLengthFuzz = 1.0E-4;       // utils.h:49

        /// <summary>
        /// 返回该三次曲线被展平后**发射的点**（不含起点 p0，含终点 p3），
        /// 顺序与 CShapeFlattener::AcceptPoint → AddLine 的顺序一致。
        /// </summary>
        public static List<(double X, double Y)> Flatten(double[] b, double tolerance)
        {
            var outp = new List<(double, double)>();

            // Initialize（注意 m_rFuzz 用的是**原始** rTolerance，m_rTolerance 才乘 6）
            double fuzz = tolerance * tolerance * SqLengthFuzz;
            double tol = (tolerance >= 0.0 ? tolerance : 0.0) * 6.0;
            double quarter = tol * 0.25;

            double[] E = new double[8];
            E[0] = b[0]; E[1] = b[1];
            E[2] = b[6] - b[0]; E[3] = b[7] - b[1];
            E[4] = (b[2] - b[4] * 2 + b[6]) * 6; E[5] = (b[3] - b[5] * 2 + b[7]) * 6;
            E[6] = (b[0] - b[2] * 2 + b[4]) * 6; E[7] = (b[1] - b[3] * 2 + b[5]) * 6;

            double stepSize = 1;
            int cSteps = 1;

            while ((ApproxNorm(E[4], E[5]) > tol || ApproxNorm(E[6], E[7]) > tol) &&
                   stepSize > TwiceMinStep)
            {
                Halve(E, ref cSteps, ref stepSize);
            }

            int guard = 0;
            while (cSteps > 1)
            {
                Step(E, ref cSteps);
                outp.Add((E[0], E[1]));

                if (ApproxNorm(E[4], E[5]) > tol && stepSize > TwiceMinStep)
                {
                    Halve(E, ref cSteps, ref stepSize);
                }
                else
                {
                    while (TryDouble(E, ref cSteps, ref stepSize, quarter)) { }
                }

                if (++guard > 5_000_000) throw new InvalidOperationException("HFD 展平不收敛（步数爆炸）");
            }

            outp.Add((b[6], b[7]));   // 末点：AcceptPoint(m_ptB[3], 1)
            _ = fuzz;
            return outp;
        }

        private static double ApproxNorm(double x, double y) => Math.Max(Math.Abs(x), Math.Abs(y));

        private static void Step(double[] E, ref int cSteps)
        {
            double p2x = E[4], p2y = E[5];
            E[0] += E[2]; E[1] += E[3];
            E[2] += p2x; E[3] += p2y;
            E[4] += p2x; E[5] += p2y; E[4] -= E[6]; E[5] -= E[7];
            E[6] = p2x; E[7] = p2y;
            cSteps--;
        }

        private static void Halve(double[] E, ref int cSteps, ref double stepSize)
        {
            E[4] += E[6]; E[5] += E[7]; E[4] *= 0.125; E[5] *= 0.125;
            E[2] -= E[4]; E[3] -= E[5]; E[2] *= 0.5; E[3] *= 0.5;
            E[6] *= 0.25; E[7] *= 0.25;
            cSteps *= 2;
            stepSize *= 0.5;
        }

        private static bool TryDouble(double[] E, ref int cSteps, ref double stepSize, double quarter)
        {
            bool doubled = (cSteps & 1) == 0;
            if (doubled)
            {
                double tx = E[4] * 2 - E[6], ty = E[5] * 2 - E[7];
                doubled = ApproxNorm(E[6], E[7]) <= quarter && ApproxNorm(tx, ty) <= quarter;
                if (doubled)
                {
                    E[2] *= 2; E[3] *= 2; E[2] += E[4]; E[3] += E[5];
                    E[6] *= 4; E[7] *= 4;
                    E[4] = tx * 4; E[5] = ty * 4;
                    cSteps /= 2;
                    stepSize *= 2;
                }
            }
            return doubled;
        }
    }

    // ======================================================================
    //  我方当前算法的逐行复刻（MilGeometryEngine.Flatten / FlattenCubic 的镜像）
    //  仅用于"如果只改这一处会怎样"的对照实验，不参与任何产品代码。
    // ======================================================================

    internal static class SimOursFlatten
    {
        public const int MaxSubdivisionDepth = 20;

        /// <summary>复刻 MilGeometryEngine.Flatten 里的容差兜底。</summary>
        public static double TolerantFallback(double tolerance) => tolerance > 0 ? tolerance : 0.1;

        /// <summary>
        /// 发射点（不含起点、含终点），float32 逐点取整 —— 与 SKPoint 一致。
        /// <paramref name="capped"/> = true 表示触到了硬上限（说明该容差下这套算法
        /// 会按 2^MaxSubdivisionDepth 爆炸，正是 U14 要量化的风险之一）。
        /// </summary>
        public static List<(double X, double Y)> Cubic(double[] b, double tolerance, out bool capped)
        {
            double tol = TolerantFallback(tolerance);
            var outp = new List<(double, double)>();
            bool hit = false;
            int cap = 1_500_000;   // 每曲线硬上限：够看清 2^20 的量级，又不至于把内存吃光
            Recurse(outp, b, tol, 0, cap, ref hit);
            capped = hit;
            return outp;
        }

        public static List<(double X, double Y)> Cubic(double[] b, double tolerance)
        {
            return Cubic(b, tolerance, out _);
        }

        private static void Recurse(List<(double X, double Y)> outp, double[] b, double tol, int depth,
            int cap, ref bool hit)
        {
            Recurse8(outp, b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], tol, depth, cap, ref hit);
        }

        // 用 8 个标量而不是数组：高密度输入下递归节点上百万，逐节点分配数组会拖垮运行时间。
        private static void Recurse8(List<(double X, double Y)> outp,
            double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3,
            double tol, int depth, int cap, ref bool hit)
        {
            if (outp.Count >= cap) { hit = true; return; }
            if (depth >= MaxSubdivisionDepth ||
                (DistToChord(x1, y1, x0, y0, x3, y3) <= tol && DistToChord(x2, y2, x0, y0, x3, y3) <= tol))
            {
                outp.Add(((float)x3, (float)y3));
                return;
            }
            double ax = Mid(x0, x1), ay = Mid(y0, y1);
            double bx = Mid(x1, x2), by = Mid(y1, y2);
            double cx = Mid(x2, x3), cy = Mid(y2, y3);
            double dx = Mid(ax, bx), dy = Mid(ay, by);
            double ex = Mid(bx, cx), ey = Mid(by, cy);
            double fx = Mid(dx, ex), fy = Mid(dy, ey);
            Recurse8(outp, x0, y0, ax, ay, dx, dy, fx, fy, tol, depth + 1, cap, ref hit);
            Recurse8(outp, fx, fy, ex, ey, cx, cy, x3, y3, tol, depth + 1, cap, ref hit);
        }

        private static double DistToChord(double px, double py, double ax, double ay, double bx, double by)
            => Geo.PtSeg(px, py, ax, ay, bx, by);

        private static double Mid(double a, double b) => (float)((a + b) * 0.5f);

        private static double DistToChord(double px, double py, double[] b)
            => Geo.PtSeg(px, py, b[0], b[1], b[6], b[7]);
    }

    // ======================================================================

    internal static class Program
    {
        private const int ExactSamples = 801;   // 每条曲线段的精确采样数（误差度量用）

        private static readonly JsonSerializerOptions Opt = new JsonSerializerOptions
        {
            WriteIndented = true,
            NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowNamedFloatingPointLiterals,
            IncludeFields = true,
        };

        private static int Main(string[] args)
        {
            if (args.Length > 0 && args[0] == "gen")
            {
                string outPath = args.Length > 1 ? args[1] : "u14/cases-u14.json";
                return Gen(outPath);
            }

            string dir = FindParityDir();
            string casesPath = args.Length > 0 ? args[0] : Path.Combine(dir, "cases.json");
            string winPath = args.Length > 1 ? args[1] : Path.Combine(dir, "windows-results.json");
            string linPath = args.Length > 2 ? args[2] : Path.Combine(dir, "linux-results.json");
            string outPrefix = args.Length > 3 ? args[3] : Path.Combine(dir, "u14", "u14");

            Console.WriteLine("U14 输入: " + casesPath);
            var cases = JsonSerializer.Deserialize<GeometryCaseFile>(File.ReadAllText(casesPath), Opt);
            var win = LoadResults(winPath);
            var lin = File.Exists(linPath) ? LoadResults(linPath) : new Dictionary<string, CaseResult>();

            var flatten = cases.Cases.Where(c => c.Fn == "MilUtility_PathGeometryFlatten").ToList();
            Console.WriteLine($"flatten 用例: {flatten.Count}（我方实测结果 {(lin.Count > 0 ? "有" : "无，用模拟列")}）");

            var rows = new List<JsonObject>();
            var md = new StringBuilder();
            md.AppendLine("# U14 · 展平密度差异量化（自动生成）");
            md.AppendLine();
            md.AppendLine("口径：点集一律按 float32 对照；真机容差按 `GetAbsoluteTolerance`(shapebase.cpp:1561) 复算；");
            md.AppendLine("「我方(模拟)」= 逐行复刻的递归二分（MilGeometryEngine.Flatten）+ ResolveTolerance 口径；");
            md.AppendLine("「原型(HFD)」= 逐行移植的 CBezierFlattener（已用 14 个真实用例验证到**逐点相同**）。");
            md.AppendLine();
            md.AppendLine("| 用例 | 请求容差 | 相对 | 真机绝对容差 | 我方绝对容差 | 真机点数 | 我方点数 | 原型点数 | 我方(模拟)点数 | 真机曲线误差 | 我方曲线误差 | 原型曲线误差 | 我方↔真机 | 原型↔真机 |");
            md.AppendLine("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|");

            foreach (GeometryCase c in flatten)
            {
                if (!win.TryGetValue(c.Id, out CaseResult w)) { Console.WriteLine("跳过（真机缺结果）: " + c.Id); continue; }
                lin.TryGetValue(c.Id, out CaseResult l);

                var sw = System.Diagnostics.Stopwatch.StartNew();
                JsonObject row = Analyze(c, w, l);
                rows.Add(row);
                Console.WriteLine($"  {c.Id,-36} {sw.ElapsedMilliseconds,7} ms  native={Fmt(row["nativePoints"])} " +
                    $"oursReal={Fmt(row["ourPoints"])} oursSim={Fmt(row["simOurTolPoints"])} proto={Fmt(row["protoPoints"])} " +
                    $"simAtNativeTol={Fmt(row["simOursAtNativeTol"])}{(row["simOursCapped"]?.GetValue<int>() == 1 ? "(capped)" : "")}");

                md.AppendLine(string.Format(CultureInfo.InvariantCulture,
                    "| `{0}` | {1} | {2} | {3:G4} | {4:G4} | {5} | {6} | {7} | {8} | {9:G3} | {10:G3} | {11:G3} | {12:G3} | {13:G3} |",
                    c.Id, Fmt(row["requestedTolerance"]), (row["relative"]?.GetValue<bool>() ?? false) ? "是" : "否",
                    Fmt(row["nativeAbsoluteTolerance"]), Fmt(row["ourAbsoluteTolerance"]),
                    Fmt(row["nativePoints"]), Fmt(row["ourPoints"]), Fmt(row["protoPoints"]), Fmt(row["simOurTolPoints"]),
                    Fmt(row["nativeCurveError"]),
                    Fmt(row["ourCurveError"] ?? row["simOurTolCurveError"]),
                    Fmt(row["protoCurveError"]),
                    Fmt(row["ourVsNativeHausdorff"] ?? row["ourSimVsNativeHausdorff"]),
                    Fmt(row["protoVsNativeHausdorff"])));
            }

            string outDir = Path.GetDirectoryName(Path.GetFullPath(outPrefix));
            if (!string.IsNullOrEmpty(outDir)) Directory.CreateDirectory(outDir);
            File.WriteAllText(outPrefix + "-pointsets.json",
                new JsonObject { ["rows"] = JsonSerializer.SerializeToNode(rows, Opt) }.ToJsonString(Opt));
            File.WriteAllText(outPrefix + "-density.md", md.ToString());
            Console.WriteLine("写出 " + outPrefix + "-pointsets.json / -density.md");
            return 0;
        }

        // ==================================================================
        //  U14 极端用例集（独立文件，不动 U1c 冻结的 cases.json）
        // ==================================================================

        private static int Gen(string outPath)
        {
            var file = new GeometryCaseFile
            {
                Description = "U14 极端曲率/小容差展平探针。独立于 U1c 的 cases.json，" +
                              "避免改动 U1c 冻结的对拍面（GeometryOracleTests 断言 215 例）。",
            };

            void Add(string id, byte[] path, double tol, bool rel, string note)
            {
                var args = new JsonObject
                {
                    ["id"] = id,
                    ["fn"] = "MilUtility_PathGeometryFlatten",
                    ["note"] = note,
                    ["path"] = JsonHelp.ToHex(path),
                    ["fillRule"] = 0,
                    ["tolerance"] = tol,
                    ["relative"] = rel,
                };
                file.Cases.Add(new GeometryCase { Id = id, Fn = "MilUtility_PathGeometryFlatten", Args = args, Note = note });
            }

            byte[] Cubic(double x0, double y0, double x1, double y1, double x2, double y2, double x3, double y3)
                => PathDataBuilder.Build(new[] { PathDataBuilder.Cubic(x0, y0, x1, y1, x2, y2, x3, y3) });
            byte[] Circle(double cx, double cy, double r)
                => PathDataBuilder.Build(new[] { PathDataBuilder.Circle(cx, cy, r) });

            // —— 极端曲率 ——
            Add("u14_cusp_loop", Cubic(0, 0, 10, 10, -10, 10, 0, 0), 0.1, false,
                "起点=终点的自环（尖点）");
            Add("u14_hairpin", Cubic(0, 0, 100, 0, 0, 0.001, 100, 0.001), 0.1, false,
                "发夹：出去再折回来，两条臂只差 0.001");
            Add("u14_hairpin_tiny_tol", Cubic(0, 0, 100, 0, 0, 0.001, 100, 0.001), 1e-5, false,
                "发夹 + 极小容差");
            Add("u14_sharp_turn", Cubic(0, 0, 100, 0, 0, 1, 100, 1), 0.1, false,
                "S 形急转");
            Add("u14_near_collinear", Cubic(0, 0, 33, 0.001, 66, 0.001, 100, 0), 0.1, false,
                "几乎共线：控制点离弦 0.001，远小于容差");
            Add("u14_near_collinear_small_tol", Cubic(0, 0, 33, 0.001, 66, 0.001, 100, 0), 1e-6, false,
                "同上 + 极小容差（0.001 的鼓包此时必须被展出来）");

            // —— 尺度极端 ——
            Add("u14_tiny_circle", Circle(0, 0, 0.01), 0.001, false, "半径 0.01 的圆：容差比图形还大");
            Add("u14_tiny_circle_tol0", Circle(0, 0, 0.001), 0, false,
                "半径 0.001 + 容差 0：真机绝对容差 = extent*1e-12 ≈ 2e-15");
            Add("u14_huge_circle", Circle(0, 0, 1e7), 0.1, false, "半径 1e7：float32 精度只剩 ~1");
            Add("u14_huge_circle_tiny_tol", Circle(0, 0, 1e7), 0.001, false, "半径 1e7 + 小容差");

            // —— 退化 ——
            Add("u14_degenerate_equal", Cubic(5, 5, 5, 5, 5, 5, 5, 5), 0.1, false, "四点重合");
            Add("u14_degenerate_line", Cubic(0, 0, 10, 0, 20, 0, 30, 0), 0.1, false,
                "控制点共线等距 = 精确直线（应当只出 1 段）");

            // —— 容差边界 ——
            Add("u14_negative_tol", Circle(50, 50, 40), -1, false, "负容差（越界输入）");
            Add("u14_relative_zero", Circle(50, 50, 40), 0, true, "fRelative + 容差 0");
            Add("u14_extreme_tol", Circle(50, 50, 40), 1e9, false, "容差远大于图形");

            // —— 多图形 / 混合 ——
            Add("u14_two_figures_mixed", PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Circle(0, 0, 100),
                PathDataBuilder.Circle(500, 0, 0.5),
            }), 0.01, false, "一大一小两个曲线图形（同一份数据两种尺度）");

            Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(outPath)));
            File.WriteAllText(outPath, JsonSerializer.Serialize(file, Opt));
            Console.WriteLine($"写出 {outPath}：{file.Cases.Count} 个 U14 探针用例");
            return 0;
        }

        private static string Fmt(JsonNode n)
        {
            if (n == null) return "-";
            if (n is JsonValue v && v.TryGetValue(out double d)) return Num(d);
            return n.ToJsonString(Opt);
        }

        private static string Num(double d)
        {
            if (double.IsNaN(d)) return "NaN";
            if (double.IsPositiveInfinity(d)) return "+INF";
            if (double.IsNegativeInfinity(d)) return "-INF";
            return d.ToString("G6", CultureInfo.InvariantCulture);
        }

        private static Dictionary<string, CaseResult> LoadResults(string path)
        {
            JsonNode root = JsonNode.Parse(File.ReadAllText(path));
            return JsonSerializer.Deserialize<List<CaseResult>>(root["results"].ToJsonString(), Opt)
                .ToDictionary(r => r.Id, r => r);
        }

        private static string FindParityDir()
        {
            var d = new DirectoryInfo(AppContext.BaseDirectory);
            while (d != null)
            {
                string p = Path.Combine(d.FullName, "tests", "parity", "geometry");
                if (Directory.Exists(p)) return p;
                d = d.Parent;
            }
            throw new DirectoryNotFoundException("找不到 tests/parity/geometry");
        }

        // ------------------------------------------------------------------

        private static JsonObject Analyze(GeometryCase c, CaseResult w, CaseResult l)
        {
            JsonObject a = c.Args;
            byte[] path = JsonHelp.Hex(JsonHelp.Str(a, "path"));
            double[] m = JsonHelp.Doubles(a["matrix"]);
            double reqTol = JsonHelp.Num(a, "tolerance", 0.1);
            bool rel = JsonHelp.Flag(a, "relative");

            List<Fig> figs = PathReader.Parse(path);
            ApplyMatrix(figs, m);

            // 真机绝对容差：CShapeBase::GetAbsoluteTolerance(shapebase.cpp:1561)
            double ext = Extent(figs);
            const double FuzzDouble = 1e-12;
            double absTol = rel ? Math.Max(reqTol, FuzzDouble) * ext
                                : Math.Max(reqTol, ext * FuzzDouble);

            // 我方绝对容差：MilGeometryEngine.ResolveTolerance 的口径
            double ourTol = reqTol > 0 ? reqTol : 0.1;
            if (rel)
            {
                double e = ext > 0 ? ext : 1.0;
                ourTol *= e;
            }

            List<List<(double X, double Y)>> native = FigsOf(w, "fig");
            List<List<(double X, double Y)>> ours = l != null ? FigsOf(l, "fig") : new List<List<(double X, double Y)>>();

            var proto = new List<List<(double X, double Y)>>();      // HFD @ 真机容差
            var simNative = new List<List<(double X, double Y)>>();  // 我方二分 @ 真机容差
            var simOurs = new List<List<(double X, double Y)>>();    // 我方二分 @ 我方容差
            var exact = new List<List<(double X, double Y)>>();
            bool simCapped = false;

            foreach (Fig f in figs)
            {
                var pPts = new List<(double X, double Y)> { (f.Sx, f.Sy) };
                var nPts = new List<(double X, double Y)> { (f.Sx, f.Sy) };
                var oPts = new List<(double X, double Y)> { (f.Sx, f.Sy) };
                var ex = new List<(double X, double Y)> { (f.Sx, f.Sy) };
                double cx = f.Sx, cy = f.Sy;

                foreach (Seg sg in f.Segs)
                {
                    if (sg.Kind == 'L')
                    {
                        pPts.Add(((float)sg.P[0], (float)sg.P[1]));
                        nPts.Add(((float)sg.P[0], (float)sg.P[1]));
                        oPts.Add(((float)sg.P[0], (float)sg.P[1]));
                        ex.Add(((float)sg.P[0], (float)sg.P[1]));
                        cx = sg.P[0]; cy = sg.P[1];
                        continue;
                    }
                    double[] b = sg.Kind == 'C'
                        ? new[] { cx, cy, (double)sg.P[0], (double)sg.P[1],
                                  (double)sg.P[2], (double)sg.P[3], (double)sg.P[4], (double)sg.P[5] }
                        : QuadToCubic(cx, cy, sg.P[0], sg.P[1], sg.P[2], sg.P[3]);

                    foreach (var q in HfdFlattener.Flatten(b, absTol)) pPts.Add(((float)q.X, (float)q.Y));

                    var v1 = SimOursFlatten.Cubic(b, absTol, out bool c1);
                    if (c1) simCapped = true;
                    nPts.AddRange(v1);

                    oPts.AddRange(SimOursFlatten.Cubic(b, ourTol));

                    for (int i = 1; i <= ExactSamples; i++)
                    {
                        var q = Geo.Cubic(b, i / (double)ExactSamples);
                        ex.Add(((float)q.X, (float)q.Y));
                    }
                    cx = b[6]; cy = b[7];
                }

                proto.Add(pPts); simNative.Add(nPts); simOurs.Add(oPts); exact.Add(ex);
            }

            bool closed = w.Scalars.TryGetValue("fig0.closed", out double cl) && cl != 0;

            return new JsonObject
            {
                ["id"] = c.Id,
                ["requestedTolerance"] = reqTol,
                ["relative"] = rel,
                ["extent"] = ext,
                ["nativeAbsoluteTolerance"] = absTol,
                ["ourAbsoluteTolerance"] = ourTol,
                ["nativeFigures"] = native.Count,
                ["ourFigures"] = ours.Count,
                ["nativePoints"] = Count(native),
                ["ourPoints"] = ours.Count > 0 ? (JsonNode)Count(ours) : null,
                ["protoPoints"] = Count(proto),
                ["simOursAtNativeTol"] = Count(simNative),
                ["simOurTolPoints"] = Count(simOurs),
                ["simOursCapped"] = simCapped ? 1 : 0,
                ["nativeCurveError"] = MaxPerFig(exact, native, closed),
                ["ourCurveError"] = ours.Count > 0 ? (JsonNode)MaxPerFig(exact, ours, closed) : null,
                ["protoCurveError"] = MaxPerFig(exact, proto, closed),
                ["simOurTolCurveError"] = MaxPerFig(exact, simOurs, closed),
                ["ourVsNativeHausdorff"] = ours.Count > 0 ? (JsonNode)MaxPairPerFig(ours, native, closed) : null,
                ["ourSimVsNativeHausdorff"] = MaxPairPerFig(simOurs, native, closed),
                ["protoVsNativeHausdorff"] = MaxPairPerFig(proto, native, closed),
                ["simOursSimVsRealMaxDelta"] = null,
                ["exactSamePointCount"] = SameCount(proto, native) ? 1 : 0,
                ["maxElementwiseDelta"] = MaxElementwise(proto, native),
            };
        }

        private static bool SameCount(List<List<(double X, double Y)>> a, List<List<(double X, double Y)>> b)
        {
            if (a.Count != b.Count) return false;
            for (int i = 0; i < a.Count; i++) if (a[i].Count != b[i].Count) return false;
            return true;
        }

        /// <summary>逐点最大偏差（仅在图形数与点数完全一致时有意义），用于判定"是不是同一串点"。</summary>
        private static double MaxElementwise(List<List<(double X, double Y)>> a, List<List<(double X, double Y)>> b)
        {
            if (!SameCount(a, b)) return double.NaN;
            double worst = 0;
            for (int i = 0; i < a.Count; i++)
                for (int k = 0; k < a[i].Count; k++)
                {
                    worst = Math.Max(worst, Math.Abs(a[i][k].X - b[i][k].X));
                    worst = Math.Max(worst, Math.Abs(a[i][k].Y - b[i][k].Y));
                }
            return worst;
        }

        private static int Count(List<List<(double X, double Y)>> f)
        {
            int n = 0;
            foreach (var x in f) n += x.Count;
            return n;
        }

        private const int MetricPointCap = 200_000;   // 超过这个规模就不做 O(N·M) 指标

        private static double MaxPerFig(List<List<(double X, double Y)>> exact,
            List<List<(double X, double Y)>> poly, bool closed)
        {
            if (Count(poly) > MetricPointCap) return double.NaN;
            double worst = 0;
            int n = Math.Min(exact.Count, poly.Count);
            for (int i = 0; i < n; i++)
            {
                if (poly[i].Count < 2) continue;
                foreach (var p in exact[i]) worst = Math.Max(worst, Geo.PtPolyline(p.X, p.Y, poly[i], closed));
            }
            return worst;
        }

        /// <summary>
        /// 逐图形双向 Hausdorff。大点集（> MaxHausdorffSamples）先等距抽样：
        /// 抽样只会**低估**最大值，所以结果是保守下界（报告里注明）。
        /// </summary>
        private static double MaxPairPerFig(List<List<(double X, double Y)>> a,
            List<List<(double X, double Y)>> b, bool closed)
        {
            if (Count(a) > MetricPointCap || Count(b) > MetricPointCap) return double.NaN;
            double worst = 0;
            int n = Math.Min(a.Count, b.Count);
            for (int i = 0; i < n; i++)
            {
                if (a[i].Count < 2 || b[i].Count < 2) continue;
                var x = Subsample(a[i]);
                var y = Subsample(b[i]);
                worst = Math.Max(worst, Math.Max(
                    Geo.OneSidedHausdorff(x, y, closed),
                    Geo.OneSidedHausdorff(y, x, closed)));
            }
            return worst;
        }

        private const int MaxHausdorffSamples = 1500;

        private static List<(double X, double Y)> Subsample(List<(double X, double Y)> p)
        {
            if (p.Count <= MaxHausdorffSamples) return p;
            var r = new List<(double X, double Y)>(MaxHausdorffSamples);
            double stride = (double)(p.Count - 1) / (MaxHausdorffSamples - 1);
            for (int i = 0; i < MaxHausdorffSamples; i++) r.Add(p[(int)Math.Round(i * stride)]);
            return r;
        }

        /// <summary>把结果文件里的 fig0.pts / fig1.pts … 按图形拆开。</summary>
        private static List<List<(double X, double Y)>> FigsOf(CaseResult r, string prefix)
        {
            var outp = new List<List<(double X, double Y)>>();
            int n = r.Scalars.TryGetValue("figCount", out double fc) ? (int)fc : 0;
            for (int i = 0; i < n; i++)
            {
                var poly = new List<(double X, double Y)>();
                if (r.Vectors.TryGetValue($"{prefix}{i}.pts", out double[] v))
                    for (int k = 0; k + 1 < v.Length; k += 2) poly.Add((v[k], v[k + 1]));
                outp.Add(poly);
            }
            return outp;
        }

        private static double[] QuadToCubic(double x0, double y0, double cx, double cy, double x1, double y1) =>
            new[] { x0, y0, x0 + 2.0 / 3.0 * (cx - x0), y0 + 2.0 / 3.0 * (cy - y0),
                    x1 + 2.0 / 3.0 * (cx - x1), y1 + 2.0 / 3.0 * (cy - y1), x1, y1 };

        private static List<(double X, double Y)> Prefix(List<(double X, double Y)> pts, double sx, double sy)
        {
            var r = new List<(double X, double Y)> { (sx, sy) };
            r.AddRange(pts);
            return r;
        }

        /// <summary>精确曲线采样点到折线的最大距离（"画出来的折线离真曲线有多远"）。</summary>
        private static double CurveError(List<(double X, double Y)> exact,
            List<(double X, double Y)> poly, bool closed)
        {
            if (poly.Count < 2) return double.NaN;
            double worst = 0;
            foreach (var p in exact) worst = Math.Max(worst, Geo.PtPolyline(p.X, p.Y, poly, closed));
            return worst;
        }

        private static double SymHausdorff(List<(double X, double Y)> a, List<(double X, double Y)> b, bool closed)
        {
            if (a.Count < 2 || b.Count < 2) return double.NaN;
            return Math.Max(Geo.OneSidedHausdorff(a, b, closed), Geo.OneSidedHausdorff(b, a, closed));
        }

        private static List<(double X, double Y)> PolyOf(CaseResult r, string key)
        {
            var outp = new List<(double X, double Y)>();
            if (r.Vectors.TryGetValue(key, out double[] v))
                for (int i = 0; i + 1 < v.Length; i += 2) outp.Add((v[i], v[i + 1]));
            return outp;
        }

        private static double Extent(List<Fig> figs)
        {
            double minX = double.MaxValue, minY = double.MaxValue, maxX = double.MinValue, maxY = double.MinValue;
            foreach (Fig f in figs)
            {
                var pts = new List<(double X, double Y)> { (f.Sx, f.Sy) };
                double[] cur = { f.Sx, f.Sy };
                foreach (Seg s in f.Segs)
                {
                    if (s.Kind == 'L')
                    {
                        pts.Add((s.P[0], s.P[1]));
                        cur = new double[] { s.P[0], s.P[1] };
                    }
                    else
                    {
                        double[] b = s.Kind == 'C'
                            ? new[] { cur[0], cur[1], (double)s.P[0], (double)s.P[1], (double)s.P[2], (double)s.P[3], (double)s.P[4], (double)s.P[5] }
                            : QuadToCubic(cur[0], cur[1], s.P[0], s.P[1], s.P[2], s.P[3]);
                        var bb = Geo.CubicBounds(b);
                        pts.Add((bb.MinX, bb.MinY)); pts.Add((bb.MaxX, bb.MaxY));
                        cur = new double[] { b[6], b[7] };
                    }
                }
                foreach (var p in pts)
                {
                    minX = Math.Min(minX, p.X); minY = Math.Min(minY, p.Y);
                    maxX = Math.Max(maxX, p.X); maxY = Math.Max(maxY, p.Y);
                }
            }
            if (minX > maxX) return 0;
            double wdt = maxX - minX, hgt = maxY - minY;
            return Math.Max(wdt, hgt);
        }

        private static void ApplyMatrix(List<Fig> figs, double[] m)
        {
            if (m == null) return;
            float a = (float)m[0], b = (float)m[1], c = (float)m[2], d = (float)m[3];
            float e = (float)m[4], f = (float)m[5];
            foreach (Fig fg in figs)
            {
                Map(ref fg.Sx, ref fg.Sy);
                for (int i = 0; i < fg.Segs.Count; i++)
                {
                    Seg s = fg.Segs[i];
                    var p = (float[])s.P.Clone();
                    for (int k = 0; k + 1 < p.Length; k += 2) Map(ref p[k], ref p[k + 1]);
                    fg.Segs[i] = new Seg(s.Kind, p);
                }
            }
            void Map(ref float x, ref float y)
            {
                float nx = a * x + c * y + e;
                float ny = b * x + d * y + f;
                x = nx; y = ny;
            }
        }
    }
}

// Licensed to the .NET Foundation under one or more agreements.
//
// U1c · 几何 oracle 对拍（Linux 侧活体复跑）。
//
// 【数据源】tests/parity/geometry/
//   cases.json            —— 双侧共用输入集（212 例，几何数据是手搓的
//                            MIL_PATHGEOMETRY 十六进制字节块，不经我方序列化器）
//   windows-results.json  —— Windows 真身 wpfgfx_cor3.dll 10.0.7 的输出
//   linux-results.json    —— 我方实现的输出（tools/GeometryOracle 产出，供人读）
//   summary.json/.md      —— 逐例判定与差异明细
//
// 【发现期 Skip】与 GoldenBinaryReplayTests / X11Guard 同一模式：xunit v2 没有运行期
// skip 通道，唯一干净的通道是 FactAttribute.Skip 字段，而特性的构造函数在**发现期**
// 执行。所以没有 windows-results.json 时，本用例在发现期就被标 Skip，不参与执行。
//
// 【本用例断言什么】把 cases.json 在我方实现上**当场重跑**一遍，逐例与真机结果比：
//   · 不在 KnownDifferences 清单里的用例 → 必须 Identical 或 Close（浮点容差内）；
//   · 在清单里的 → 判定必须**恰好**等于清单里登记的那一种。
// 清单是"精确匹配"而不是"包含"：既挡住新引入的偏差，也挡住清单腐烂
// （某条差异被修好后判定会变好，这时用例会失败并提醒把该条从清单里划掉）。

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Nodes;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Parity.Geometry;
using Xunit;

namespace WpfGfx.Linux.Tests.Commands
{
    /// <summary>发现期检查 tests/parity/geometry/windows-results.json 是否存在；无则 Skip。</summary>
    internal sealed class GeometryOracleFactAttribute : FactAttribute
    {
        public GeometryOracleFactAttribute()
        {
            if (!GeometryOracleTests.HasOracleData)
                Skip = GeometryOracleTests.SkipReason;
        }
    }

    public class GeometryOracleTests
    {
        // ==================================================================
        //  已知差异清单（每条都在 docs/U1c-geometry-oracle.md 里有证据与根因）
        // ==================================================================

        /// <summary>
        /// 判定枚举（与 harness 的 Verdict 数值一致）。
        /// 0 Identical / 1 Close / 2 Reordered / 3 Deviation / 4 Structural
        /// </summary>
        private static readonly Dictionary<string, int> KnownDifferences =
            new Dictionary<string, int>(StringComparer.Ordinal)
            {
                // ---- ⚠️ 几何等价、发射顺序不同（环内旋转/反向）：需要对齐指令流字节时才有意义 ----
                { "combine_disjoint_exclude", 2 },
                { "combine_disjoint_union", 2 },
                { "combine_disjoint_xor", 2 },
                { "combine_fillrule_nonzero", 2 },
                { "combine_identical_union", 2 },
                { "combine_matrix1_only", 2 },
                { "combine_nested_exclude", 2 },
                { "combine_nested_union", 2 },
                { "combine_nested_xor", 2 },
                { "combine_overlap_xor", 2 },
                { "outline_circle_tol_0_001", 2 },
                { "outline_circle_tol_0_1", 2 },
                { "outline_circle_tol_10", 2 },
                { "outline_nested_evenodd", 2 },
                { "outline_relative_true", 2 },
                { "widen_open_line_pen2", 2 },

                // ---- ℹ️ 上游输出未定义：真机发的是**未初始化栈值**，无法也不必对齐 ----
                // 半径退化时上游 ArcToBezier 直接 goto Cleanup，points[] 从未被写；
                // MilUtility_ArcToBezier 却照样把它拷进出参（geometry_api.cpp:901-918）。
                { "arc_radii_zero", 3 },
                { "arc_radius_x_zero", 3 },
                { "arc_radius_y_zero", 3 },

                // ---- ℹ️ 我方刻意加固：0 宽/0 高矩形当"空"处理，上游会除零出 INF/NaN ----
                { "tb_zero_width_viewport", 3 },
                { "tb_zero_height_viewport", 3 },
                { "tb_zero_width_viewbox", 3 },
                { "tb_zero_height_viewbox", 3 },
                { "tb_zero_shape_bounds", 3 },

                // ---- ⚠️ 展平密度不同（要换掉上游那套 BezierFlattener 才能一致）----
                { "flatten_circle_tol_0", 4 },
                { "flatten_circle_tol_0_001", 4 },
                { "flatten_circle_tol_0_25", 4 },

                // ---- ⚠️ 描边轮廓的"图形分解/闭合表示"不同 ----
                // 上游把描边环发成**一个**带接缝的闭合轮廓，Skia 的 GetFillPath 发成
                // 外圈 + 内圈两个；虚线段上游是 5 点（显式收口），我方 4 点 + Close。
                { "widen_rect_pen2", 4 },
                { "widen_rect_pen2_bevel", 4 },
                { "widen_rect_pen2_round", 4 },
                { "widen_rect_tol_0_001", 4 },
                { "widen_rect_tol_10", 4 },
                { "widen_with_matrix", 4 },
                { "widen_negative_thickness", 4 },
                { "widen_open_line_pen2_square", 4 },
                { "widen_dash", 4 },
                { "widen_dash_identity_matrix", 4 },
                { "widen_dash_offset", 4 },
                { "widen_dash_scale_matrix", 4 },
                { "widen_dashed_rect", 4 },
                { "outline_bowtie_evenodd", 4 },
                { "outline_bowtie_nonzero", 4 },
                { "outline_nested_nonzero", 4 },
                { "combine_touching_union", 4 },

                // ---- ⚠️ 零散 ----
                { "widen_open_line_pen2_round", 3 },   // 圆头端帽的弧离散化不同
                { "length_circle_0_3", 3 },             // 弧长参数化不同（CAnimationPath 自有展平），差 0.58%
                { "length_line_nan", 4 },               // NaN 分数：真机 S_OK + NaN 点 + (1,0) 切线；我方 E_FAIL
            };

        // ==================================================================

        private static readonly JsonSerializerOptions Options = new JsonSerializerOptions
        {
            WriteIndented = true,
            NumberHandling = System.Text.Json.Serialization.JsonNumberHandling.AllowNamedFloatingPointLiterals,
            IncludeFields = true,
        };

        internal static string ParityDir
        {
            get
            {
                var dir = new DirectoryInfo(AppContext.BaseDirectory);
                while (dir != null)
                {
                    if (File.Exists(Path.Combine(dir.FullName, "handoff.md")))
                        return Path.Combine(dir.FullName, "tests", "parity", "geometry");
                    dir = dir.Parent;
                }
                throw new DirectoryNotFoundException(
                    $"无法从 {AppContext.BaseDirectory} 向上定位仓库根（未找到 handoff.md）");
            }
        }

        internal static bool HasOracleData =>
            File.Exists(Path.Combine(ParityDir, "windows-results.json")) &&
            File.Exists(Path.Combine(ParityDir, "cases.json"));

        internal static string SkipReason =>
            $"未找到真机对拍数据（{Path.Combine(ParityDir, "windows-results.json")}）。" +
            "在 Windows 侧用 tests/parity/geometry/windows-harness 跑一遍 " +
            "u1geom.exe cases.json windows-results.json 再拷回来，本用例自动转为实测。";

        [GeometryOracleFact]
        public void 逐例对拍真身wpfgfx导出()
        {
            var cases = JsonSerializer.Deserialize<GeometryCaseFile>(
                File.ReadAllText(Path.Combine(ParityDir, "cases.json")), Options);
            JsonNode root = JsonNode.Parse(File.ReadAllText(Path.Combine(ParityDir, "windows-results.json")));
            List<CaseResult> windows = JsonSerializer.Deserialize<List<CaseResult>>(
                root["results"].ToJsonString(), Options);

            Assert.Equal(215, cases.Cases.Count);
            Assert.Equal(cases.Cases.Count, windows.Count);

            var winById = windows.ToDictionary(r => r.Id, r => r);
            var runner = new LinuxGeometryRunner();
            var unexpected = new List<string>();
            var stale = new List<string>();

            foreach (GeometryCase c in cases.Cases)
            {
                Assert.True(winById.TryGetValue(c.Id, out CaseResult win), $"真机结果缺 {c.Id}");
                CaseResult linux = runner.Run(c);
                CaseComparison cmp = ResultComparer.Compare(win, linux, c);

                if (KnownDifferences.TryGetValue(c.Id, out int expected))
                {
                    if ((int)cmp.Verdict != expected)
                    {
                        stale.Add($"{c.Id}: 清单登记={expected}，实测={(int)cmp.Verdict}（{cmp.Why}）");
                    }
                }
                else if (cmp.Verdict != Verdict.Identical && cmp.Verdict != Verdict.Close)
                {
                    unexpected.Add($"{c.Id} [{cmp.Verdict}] {cmp.Why}");
                }
            }

            Assert.True(unexpected.Count == 0,
                "出现未登记的偏差（要么修掉，要么在 KnownDifferences 里登记并写清根因）：\n  "
                + string.Join("\n  ", unexpected));
            Assert.True(stale.Count == 0,
                "KnownDifferences 清单腐烂（这些用例的判定已经变了，请更新清单）：\n  "
                + string.Join("\n  ", stale));
        }
    }

    // ======================================================================
    //  U1c 对拍直接派生出来的回归断言（不依赖 oracle 数据文件，永远执行）
    // ======================================================================

    public unsafe class GeometryOracleRegressionTests
    {
        /// <summary>图形回调收集器（本文件自用，不复用 MilExportTests 的私有实现）。</summary>
        private sealed class FigureCollector
        {
            public readonly List<(bool Filled, bool Closed, MilPointF[] Points, byte[] Types)> Figures =
                new List<(bool, bool, MilPointF[], byte[])>();

            public void Callback(
                bool isFilled, bool isClosed, MilPointF* pPoints, uint pointCount, byte* pTypes, uint typeCount)
            {
                var points = new MilPointF[pointCount];
                for (int i = 0; i < pointCount; i++) points[i] = pPoints[i];
                var types = new byte[typeCount];
                for (int i = 0; i < typeCount; i++) types[i] = pTypes[i];
                Figures.Add((isFilled, isClosed, points, types));
            }
        }

        private static byte[] Rect(double x, double y, double w, double h) =>
            PathDataBuilder.Build(new[] { PathDataBuilder.Rect(x, y, w, h) });

        private static byte[] Circle(double cx, double cy, double r) =>
            PathDataBuilder.Build(new[] { PathDataBuilder.Circle(cx, cy, r) });

        private static byte[] Bowtie() =>
            PathDataBuilder.Build(new[] { PathDataBuilder.Polygon(0, 0, 10, 10, 10, 0, 0, 10) });

        private static double Area(byte[] path, MilFillRule rule, double tol = 0.1)
        {
            double area;
            fixed (byte* p = path)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_GeometryGetArea(
                    rule, p, (uint)path.Length, null, tol, false, &area));
            }
            return area;
        }

        /// <summary>
        /// 自交图形的面积：真机 area_bowtie_* 三个用例都是 50（两瓣各 25）。
        /// 初版的分带只按顶点 y 切，跨过自交点的那一带在中点采到两条重合 crossing，
        /// parity 扫描把两瓣之间的空隙也算成内部 → 100。
        /// </summary>
        [Fact]
        public void 自交图形面积按自交点细分()
        {
            Assert.Equal(50.0, Area(Bowtie(), MilFillRule.EvenOdd), 1);
            Assert.Equal(50.0, Area(Bowtie(), MilFillRule.Nonzero), 1);
        }

        /// <summary>
        /// MIL_PEN_DATA.DashArraySize 是**字节数**（上游 `DashArraySize / sizeof(double)`，
        /// geometry_api.cpp:141；托管侧写 `count * sizeof(double)`，DashStyle.cs:71）。
        /// 初版按"元素个数"解释：2 元素的虚线数组被算成 2/8 = 0 条 → 虚线整个失效
        /// （真机 widen_dash 出 1 个图形，初版出 5 个）。
        /// 这里用"描边缓冲的字节口径"验证：同样的 dashes，按字节给才产生多段。
        /// </summary>
        [Fact]
        public void 虚线数组长度按字节解释()
        {
            byte[] line = PathDataBuilder.Build(new[] { PathDataBuilder.Line(0, 0, 50, 0) });
            var dashes = new double[] { 2.0, 1.0 };

            var pen = new MIL_PEN_DATA
            {
                Thickness = 4,
                MiterLimit = 10,
                LineJoin = MilPenLineJoin.Miter,
                // 2 个 double = 16 字节
                DashArraySize = (uint)(dashes.Length * sizeof(double)),
            };

            var collector = new FigureCollector();
            fixed (double* dash = dashes)
            fixed (byte* p = line)
            {
                MIL_PEN_DATA* penPtr = &pen;
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryWiden(
                    penPtr, dash, null, MilFillRule.Nonzero, p, (uint)line.Length, 0.1, false,
                    collector.Callback, out MilFillRule outRule));
                // 注意：上游 MilUtility_PathGeometryWiden **从不写** outFillRule
                //（geometry_api.cpp:151-217 没有 `*pOutFillRule = ...`，而 Outline:254 /
                //  Flatten:452 / Combine:397 都有；哨兵法实测真机原样回吐调用方栈值）。
                // 本实现刻意给确定性值 = 输入填充规则。
                Assert.Equal(MilFillRule.Nonzero, outRule);
            }

            // 虚线把 50 长的线切成 4 段实线 → 至少 4 个图形（真机 5 个：含 DashOffset 相位差）
            Assert.True(collector.Figures.Count >= 4,
                $"虚线没生效：只得到 {collector.Figures.Count} 个图形");

            // 字节口径的反面：把同一个值当"元素个数"（写 2）→ 下游算成 0 条虚线，
            // 应当退化成一个整段（这正是 M7a 初版的行为）。
            pen.DashArraySize = 2;
            var collector2 = new FigureCollector();
            fixed (double* dash = dashes)
            fixed (byte* p = line)
            {
                MIL_PEN_DATA* penPtr = &pen;
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryWiden(
                    penPtr, dash, null, MilFillRule.Nonzero, p, (uint)line.Length, 0.1, false,
                    collector2.Callback, out _));
            }
            Assert.Single(collector2.Figures);
        }

        /// <summary>
        /// fSkipHollows 真的生效：真机 bounds_hollow_skip_true = (0,0,10,10)
        /// （只算可填充图形），false = (0,0,200,200)。
        /// </summary>
        [Fact]
        public void 包围盒跳过不可填充图形()
        {
            byte[] path = PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Rect(0, 0, 10, 10),
                new FigSpec
                {
                    StartX = 100, StartY = 100, Closed = true, Fillable = false,
                    Segs =
                    {
                        new SegSpec { Kind = 'L', Pts = new[] { 200.0, 100.0 } },
                        new SegSpec { Kind = 'L', Pts = new[] { 200.0, 200.0 } },
                        new SegSpec { Kind = 'L', Pts = new[] { 100.0, 200.0 } },
                        new SegSpec { Kind = 'L', Pts = new[] { 100.0, 100.0 }, Closed = true },
                    },
                },
            });

            Assert.Equal((0.0, 0.0, 200.0, 200.0), Bounds(path, skipHollows: false));
            Assert.Equal((0.0, 0.0, 10.0, 10.0), Bounds(path, skipHollows: true));
        }

        private static (double left, double top, double right, double bottom) Bounds(
            byte[] path, bool skipHollows)
        {
            MilRectD rect;
            fixed (byte* p = path)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryBounds(
                    null, null, null, MilFillRule.EvenOdd, p, (uint)path.Length, null,
                    0.1, false, skipHollows, &rect));
            }
            return (rect.Left, rect.Top, rect.Right, rect.Bottom);
        }

        /// <summary>
        /// 几何矩阵在"加图形"时作用、笔不跟着缩放：
        /// 真机 bounds_rect_geom_matrix_scale2 的矩形 0..100 × 2 后再按笔宽 2 外扩
        /// → (-1,-1,201,101)；初版先外扩再乘矩阵 → (-2,-2,202,102)。
        /// </summary>
        [Fact]
        public void 包围盒几何矩阵不缩放笔()
        {
            byte[] path = Rect(0, 0, 100, 50);
            var pen = new MIL_PEN_DATA { Thickness = 2, MiterLimit = 10 };
            double* geom = stackalloc double[6];
            geom[0] = 2; geom[1] = 0; geom[2] = 0; geom[3] = 2; geom[4] = 0; geom[5] = 0;

            MilRectD rect;
            fixed (byte* p = path)
            {
                MIL_PEN_DATA* penPtr = &pen;
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryBounds(
                    penPtr, null, null, MilFillRule.EvenOdd, p, (uint)path.Length, geom,
                    0.1, false, false, &rect));
            }
            Assert.Equal((-1.0, -1.0, 201.0, 101.0), (rect.Left, rect.Top, rect.Right, rect.Bottom));
        }

        /// <summary>
        /// 命中阈值是**严格小于**，且平方阈值下限 SQ_LENGTH_FUZZ=1e-4（距离 0.01）：
        /// 真机 hit_relative_tol（距离 5.0、阈值 5.0）不命中；
        /// hit_rect_just_outside_no_tol（距离 0.001、阈值 0）命中。
        /// </summary>
        [Fact]
        public void 命中阈值严格小于且下限为001()
        {
            byte[] rect = Rect(0, 0, 10, 10);

            // 距离恰好等于阈值 → 不命中（初版用 <= 给成命中）
            Assert.Equal(0, Hit(rect, 15, 5, 0.5, relative: true));
            // 阈值 0 时仍有一个 0.01 的距离下限 → 0.001 算命中
            Assert.Equal(1, Hit(rect, 5, -0.001, 0.0, relative: false));
            // 0.5 超出下限 → 不命中
            Assert.Equal(0, Hit(rect, 5, -0.5, 0.0, relative: false));
        }

        private static int Hit(byte[] path, double x, double y, double threshold, bool relative)
        {
            var pt = new MilPointD(x, y);
            MilPointD* hp = &pt;
            int contains;
            fixed (byte* p = path)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryHitTest(
                    null, null, null, MilFillRule.EvenOdd, p, (uint)path.Length,
                    threshold, relative, hp, out contains));
            }
            return contains;
        }

        /// <summary>
        /// TileBrush 的 Bottom 对齐用 **viewport** 高度（上游 TileBrushUtils.cpp:329-333），
        /// 初版误写成 viewbox 高度 → 真机 tb_uniform_right_bottom 的 M42=0、初版 -50。
        /// </summary>
        [Fact]
        public void TileBrush底部对齐用viewport高度()
        {
            var shape = new MilPointAndSizeD(0, 0, 100, 100);
            var content = new MilPointAndSizeD(0, 0, 50, 50);
            var viewport = new MilPointAndSizeD(0, 0, 100, 100);
            var viewbox = new MilPointAndSizeD(0, 0, 50, 50);

            MilPointAndSizeD* sp = &shape;
            MilPointAndSizeD* cp = &content;
            MilNative.MilUtility_GetTileBrushMapping(
                null, null, MilStretch.Uniform, MilAlignmentX.Right, MilAlignmentY.Bottom,
                MilBrushMappingMode.Absolute, MilBrushMappingMode.Absolute,
                sp, cp, ref viewport, ref viewbox, out D3DMATRIX m, out int empty);

            Assert.Equal(0, empty);
            Assert.Equal(2f, m.M11);
            Assert.Equal(2f, m.M22);
            Assert.Equal(0f, m.M41);
            Assert.Equal(0f, m.M42);   // 初版是 -50
        }

        /// <summary>
        /// Combine 的 outFillRule 恒为 Nonzero（真机 22/22 都回 1，
        /// combinedShape 是新建 CShape，默认填充模式 Winding）。
        /// </summary>
        [Fact]
        public void Combine回填填充规则恒为Nonzero()
        {
            byte[] a = Rect(0, 0, 10, 10);
            byte[] b = Rect(5, 5, 10, 10);
            var collector = new FigureCollector();
            MilFillRule outRule;

            double* identity = stackalloc double[6];
            identity[0] = 1; identity[1] = 0; identity[2] = 0;
            identity[3] = 1; identity[4] = 0; identity[5] = 0;

            fixed (byte* pa = a)
            fixed (byte* pb = b)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryCombine(
                    identity, identity, MilFillRule.EvenOdd, pa, (uint)a.Length,
                    identity, MilFillRule.EvenOdd, pb, (uint)b.Length,
                    0.1, false, collector.Callback, MilGeometryCombineMode.Xor, out outRule));
            }
            Assert.Equal(MilFillRule.Nonzero, outRule);
        }

        /// <summary>笔宽 0 → S_OK + 0 个图形（真机 widen_zero_thickness）。</summary>
        [Fact]
        public void 笔宽为零的描边成功且为空()
        {
            byte[] rect = Rect(0, 0, 10, 10);
            var pen = new MIL_PEN_DATA { Thickness = 0, MiterLimit = 10 };
            var collector = new FigureCollector();
            MIL_PEN_DATA* penPtr = &pen;

            fixed (byte* p = rect)
            {
                Assert.Equal(HResult.S_OK, MilNative.MilUtility_PathGeometryWiden(
                    penPtr, null, null, MilFillRule.Nonzero, p, (uint)rect.Length, 0.1, false,
                    collector.Callback, out _));
            }
            Assert.Empty(collector.Figures);
        }
    }
}

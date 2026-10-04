// Licensed to the .NET Foundation under one or more agreements.
//
// U1c：共享输入集（cases.json）的生成器。
//
// 覆盖任务书点名的 10 项存疑语义：
//   A  ArcToBezier（各 sweep/large-arc/退化半径）
//   B  PathGeometryFlatten（容差参数）
//   C  GeometryGetArea（EvenOdd vs Nonzero、自交）
//   D  PathGeometryCombine（Union/Intersect/Xor/Exclude）
//   E  PathGeometryHitTest / PathGeometryHitTestPathGeometry（FullyInside/FullyContains/相交）
//   F  PathGeometryWiden / PathGeometryOutline（rTolerance 是否真被忽略）
//   G  CopyPixelBuffer（位偏移路径）
//   H  GetTileBrushMapping（0 宽/0 高矩形的边界）
//   I  PathGeometryBounds / PolygonBounds 的 fSkipHollows
//   J  侧向/旋转约定（rotation 单位、sweep 方向）与 PostScript 参数
//
// 所有几何输入都以 MIL_PATHGEOMETRY 十六进制字节块给出，两侧读到的是同一串字节。

using System;
using System.Collections.Generic;
using System.Text.Json.Nodes;

namespace WpfGfx.Linux.Parity.Geometry
{
    public static class CaseCatalog
    {
        public const string FnArc = "MilUtility_ArcToBezier";
        public const string FnPathBounds = "MilUtility_PathGeometryBounds";
        public const string FnPolyBounds = "MilUtility_PolygonBounds";
        public const string FnFlatten = "MilUtility_PathGeometryFlatten";
        public const string FnOutline = "MilUtility_PathGeometryOutline";
        public const string FnWiden = "MilUtility_PathGeometryWiden";
        public const string FnCombine = "MilUtility_PathGeometryCombine";
        public const string FnHit = "MilUtility_PathGeometryHitTest";
        public const string FnPolyHit = "MilUtility_PolygonHitTest";
        public const string FnHitPath = "MilUtility_PathGeometryHitTestPathGeometry";
        public const string FnArea = "MilUtility_GeometryGetArea";
        public const string FnLength = "MilUtility_GetPointAtLengthFraction";
        public const string FnTileBrush = "MilUtility_GetTileBrushMapping";
        public const string FnCopyPixels = "MilUtility_CopyPixelBuffer";
        public const string FnProbe = "ExportProbe";

        public static List<GeometryCase> Build()
        {
            var cases = new List<GeometryCase>();

            ArcCases(cases);
            FlattenCases(cases);
            AreaCases(cases);
            CombineCases(cases);
            HitTestCases(cases);
            HitTestPathCases(cases);
            WidenOutlineCases(cases);
            CopyPixelCases(cases);
            TileBrushCases(cases);
            BoundsCases(cases);
            PolygonHitCases(cases);
            LengthCases(cases);

            cases.Add(new GeometryCase
            {
                Id = "probe_exports",
                Fn = FnProbe,
                Args = new JsonObject
                {
                    ["names"] = new JsonArray(
                        "MilUtility_ArcToBezier", "MilUtility_PathGeometryBounds",
                        "MilUtility_PolygonBounds", "MilUtility_PathGeometryFlatten",
                        "MilUtility_PathGeometryOutline", "MilUtility_PathGeometryWiden",
                        "MilUtility_PathGeometryCombine", "MilUtility_PathGeometryHitTest",
                        "MilUtility_PolygonHitTest", "MilUtility_PathGeometryHitTestPathGeometry",
                        "MilUtility_GeometryGetArea", "MilUtility_GetPointAtLengthFraction",
                        "MilUtility_GetTileBrushMapping", "MilUtility_CopyPixelBuffer",
                        "MilUtility_GetArcBounds", "MilUtility_GetBezierBounds",
                        "MilUtility_GetQuadraticBezierBounds", "MIL3DCalcProjected2DBounds",
                        "MilGlyphRun_GetGlyphOutline", "MilGlyphRun_ReleasePathGeometryData"),
                },
                Note = "探测真身 DLL 里哪些导出名真的能解析（缺名会导致对拍面缺口）。",
            });

            return cases;
        }

        // ==================================================================
        //  小工具
        // ==================================================================

        private static JsonObject Case(string id, string fn, string note = null) =>
            new JsonObject { ["id"] = id, ["fn"] = fn, ["note"] = note };

        private static void Add(List<GeometryCase> list, JsonObject obj)
        {
            list.Add(new GeometryCase
            {
                Id = obj["id"].GetValue<string>(),
                Fn = obj["fn"].GetValue<string>(),
                Note = obj["note"]?.GetValue<string>(),
                Args = obj,
            });
        }

        private static string Hex(byte[] data) => JsonHelp.ToHex(data);

        private static JsonArray Matrix(double a, double b, double c, double d, double e, double f) =>
            JsonHelp.Arr(a, b, c, d, e, f);

        private static JsonObject Pen(double thickness, string join = null, string cap = null,
            double miterLimit = 10, double dashOffset = 0, double[] dashes = null, string dashCap = null)
        {
            var o = new JsonObject
            {
                ["thickness"] = thickness,
                ["miterLimit"] = miterLimit,
                ["dashOffset"] = dashOffset,
                ["startCap"] = CapCode(cap),
                ["endCap"] = CapCode(cap),
                ["dashCap"] = CapCode(dashCap ?? cap),
                ["join"] = JoinCode(join),
            };
            if (dashes != null) o["dashes"] = JsonHelp.Arr(dashes);
            return o;
        }

        private static int CapCode(string cap) => cap switch
        {
            "square" => 1,
            "round" => 2,
            "triangle" => 3,
            _ => 0,
        };

        private static int JoinCode(string join) => join switch
        {
            "bevel" => 1,
            "round" => 2,
            _ => 0,
        };

        private static JsonObject PathCase(string id, string fn, byte[] path, string note = null)
        {
            var o = Case(id, fn, note);
            o["path"] = Hex(path);
            return o;
        }

        // ==================================================================
        //  A. ArcToBezier
        // ==================================================================

        private static void ArcCases(List<GeometryCase> list)
        {
            void Arc(string id, double sx, double sy, double rw, double rh, double rot,
                bool large, bool sweepCw, double ex, double ey, JsonArray matrix = null, string note = null)
            {
                JsonObject o = Case(id, FnArc, note);
                o["ptStart"] = JsonHelp.Arr(sx, sy);
                o["radii"] = JsonHelp.Arr(rw, rh);
                o["rotation"] = rot;
                o["largeArc"] = large;
                // sweepCw：上游第 5 个参数 fSweepUp 直接接 SweepDirection 枚举
                //（ArcSegment.cs:73 传 SweepDirection 本身），Clockwise=1。
                o["sweepCw"] = sweepCw;
                o["ptEnd"] = JsonHelp.Arr(ex, ey);
                if (matrix != null) o["matrix"] = matrix;
                Add(list, o);
            }

            Arc("arc_quarter_ccw", 0, 0, 50, 30, 0, false, false, 40, 20, null, "小弧 + 逆时针");
            Arc("arc_quarter_cw", 0, 0, 50, 30, 0, false, true, 40, 20, null, "小弧 + 顺时针");
            Arc("arc_large_ccw", 0, 0, 50, 30, 0, true, false, 40, 20, null, "大弧 + 逆时针");
            Arc("arc_large_cw", 0, 0, 50, 30, 0, true, true, 40, 20, null, "大弧 + 顺时针");
            Arc("arc_rot30_large_cw", 0, 0, 50, 30, 30, true, true, 40, 20, null, "rotation 单位是**度**");
            Arc("arc_rot_neg45_small_ccw", 5, 5, 20, 12, -45, false, false, 18, 9);
            Arc("arc_rot90", 0, 0, 40, 20, 90, true, false, 10, 25);
            Arc("arc_rot180", 0, 0, 40, 20, 180, false, true, 10, 25);
            Arc("arc_rot_1e-7_below_fuzz", 0, 0, 50, 30, 1e-7, false, true, 40, 20, null,
                "|rot| < FUZZ(1e-6) → 走 cos=1/sin=0 快路径");
            Arc("arc_rot_1e-5_above_fuzz", 0, 0, 50, 30, 1e-5, false, true, 40, 20, null,
                "|rot| > FUZZ → 真的算三角函数");
            Arc("arc_radii_zero", 0, 0, 0, 0, 0, false, true, 40, 20, null, "半径全 0 → cPieces=0（直线）");
            Arc("arc_radius_x_zero", 0, 0, 0, 30, 0, false, true, 40, 20, null, "x 半径为 0");
            Arc("arc_radius_y_zero", 0, 0, 50, 0, 0, false, true, 40, 20, null, "y 半径为 0");
            Arc("arc_negative_radii", 0, 0, -50, -30, 0, false, true, 40, 20, null,
                "负半径：AcceptRadius 会取绝对值");
            Arc("arc_same_point", 30, 40, 50, 30, 0, false, true, 30, 40, null,
                "弦长为 0 → cPieces=-1（退化成点）");
            Arc("arc_tiny_chord", 30, 40, 50, 30, 0, false, true, 30 + 1e-7, 40, null,
                "弦长平方 2.5e-15 < FUZZ^2 → cPieces=-1");
            Arc("arc_chord_longer_than_diameter", 0, 0, 10, 10, 0, false, true, 100, 0, null,
                "半弦长 > 半径 → 半径按比例放大、圆心落回弦中点（fZeroCenter）");
            Arc("arc_chord_equals_diameter", 0, 0, 50, 50, 0, false, true, 100, 0, null,
                "半弦长 == 半径：rHalfChord2 == 1 的边界");
            Arc("arc_chord_just_under_diameter", 0, 0, 51, 51, 0, false, true, 100, 0, null);
            Arc("arc_chord_just_over_diameter", 0, 0, 49.9, 49.9, 0, false, true, 100, 0, null);
            Arc("arc_matrix_translate", 0, 0, 50, 30, 0, false, true, 40, 20,
                Matrix(1, 0, 0, 1, 10, 20), "带平移矩阵");
            Arc("arc_matrix_scale", 0, 0, 50, 30, 0, false, true, 40, 20,
                Matrix(2, 0, 0, 3, 0, 0), "带缩放矩阵");
            Arc("arc_matrix_rot90", 0, 0, 50, 30, 0, true, false, 40, 20,
                Matrix(0, 1, -1, 0, 0, 0), "矩阵与 rotation 参数是两回事");
            Arc("arc_nan_radius", 0, 0, double.NaN, 30, 0, false, true, 40, 20, null,
                "半径 NaN：AcceptRadius 文档写明 NaN 放行");
            Arc("arc_huge_coords", 0, 0, 5e7, 5e7, 0, false, true, 1e8, 0, null,
                "大坐标：上游内部全程 float，精度损失可观察");
            Arc("arc_fractional", 0.1, 0.2, 3.3, 4.7, 17.5, true, true, 5.9, 2.1, null,
                "非整数参数全开");
            Arc("arc_rot360", 0, 0, 50, 30, 360, false, true, 40, 20, null,
                "rotation=360 度 == 0 度？");
            Arc("arc_radii_tiny", 0, 0, 1e-8, 1e-8, 0, false, true, 0.001, 0, null,
                "极小半径 + 相对较大的弦");
            Arc("arc_sweep_zero_len_radius", 10, 10, 0, 0, 45, true, false, 10, 10, null,
                "退化成点优先于退化直线（弦长先判）");
        }

        // ==================================================================
        //  B. PathGeometryFlatten（容差）
        // ==================================================================

        private static void FlattenCases(List<GeometryCase> list)
        {
            byte[] circle = PathDataBuilder.Build(new[] { PathDataBuilder.Circle(50, 50, 40) });
            byte[] rect = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 100, 60) });
            byte[] polyline = PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Line(0, 0, 10, 10),
                PathDataBuilder.Line(10, 10, 20, 0),
            });

            void Flat(string id, byte[] path, double tol, bool rel, int fillRule = 0,
                JsonArray matrix = null, string note = null)
            {
                JsonObject o = PathCase(id, FnFlatten, path, note);
                o["fillRule"] = fillRule;
                o["tolerance"] = tol;
                o["relative"] = rel;
                if (matrix != null) o["matrix"] = matrix;
                Add(list, o);
            }

            Flat("flatten_rect_tol01", rect, 0.1, false, 0, null, "纯直线：容差应当不影响输出");
            Flat("flatten_circle_tol_0_001", circle, 0.001, false, 0, null, "容差极小 → 点数应当多");
            Flat("flatten_circle_tol_0_01", circle, 0.01, false, 0, null, null);
            Flat("flatten_circle_tol_0_1", circle, 0.1, false, 0, null, "WPF 默认 0.25 量级");
            Flat("flatten_circle_tol_0_25", circle, 0.25, false, 0, null, null);
            Flat("flatten_circle_tol_1_0", circle, 1.0, false, 0, null, null);
            Flat("flatten_circle_tol_10", circle, 10.0, false, 0, null, "容差很大 → 点数应当少");
            Flat("flatten_circle_tol_0", circle, 0.0, false, 0, null, "容差 0：上游 GetAbsoluteTolerance 会怎么处理？");
            Flat("flatten_circle_relative_true", circle, 0.01, true, 0, null,
                "fRelative：容差按包围盒最大边长缩放（80 → 容差 0.8）");
            Flat("flatten_circle_relative_true_tiny", circle, 0.0001, true, 0, null, null);
            Flat("flatten_circle_with_matrix_scale", circle, 0.1, false, 0,
                Matrix(3, 0, 0, 3, 5, 7), "矩阵先作用于几何还是容差？");
            Flat("flatten_circle_relative_with_matrix", circle, 0.01, true, 0,
                Matrix(3, 0, 0, 3, 0, 0), "相对容差的包围盒是变换前还是变换后？");
            Flat("flatten_polyline_open", polyline, 0.1, false, 0, null, "开放折线：IsClosed 应为 false");
            Flat("flatten_fillrule_nonzero", circle, 0.1, false, 1, null,
                "outFillRule 是否原样回填输入填充规则");
        }

        // ==================================================================
        //  C. GeometryGetArea
        // ==================================================================

        private static void AreaCases(List<GeometryCase> list)
        {
            byte[] rect10 = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 10, 10) });
            byte[] rectOffset = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(5, 7, 10, 10) });
            byte[] nestedSame = PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Rect(0, 0, 10, 10),
                PathDataBuilder.Rect(2, 2, 6, 6),
            });
            byte[] nestedOpposite = PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Rect(0, 0, 10, 10),
                PathDataBuilder.Polygon(2, 2, 2, 8, 8, 8, 8, 2),   // 反向绕
            });
            byte[] bowtie = PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Polygon(0, 0, 10, 10, 10, 0, 0, 10),
            });
            byte[] bowtieRev = PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Polygon(0, 10, 10, 0, 10, 10, 0, 0),
            });
            byte[] circle = PathDataBuilder.Build(new[] { PathDataBuilder.Circle(0, 0, 10) });
            byte[] openTri = PathDataBuilder.Build(new[]
            {
                new FigSpec
                {
                    StartX = 0, StartY = 0,
                    Segs =
                    {
                        new SegSpec { Kind = 'L', Pts = new[] { 10.0, 0.0 } },
                        new SegSpec { Kind = 'L', Pts = new[] { 0.0, 10.0 } },
                    },
                },
            });
            byte[] empty = PathDataBuilder.Build(Array.Empty<FigSpec>());
            byte[] tri = PathDataBuilder.Build(new[] { PathDataBuilder.Triangle(0, 0, 10, 0, 0, 10) });

            void Area(string id, byte[] path, int rule, double tol, bool rel,
                JsonArray matrix = null, string note = null)
            {
                JsonObject o = PathCase(id, FnArea, path, note);
                o["fillRule"] = rule;
                o["tolerance"] = tol;
                o["relative"] = rel;
                if (matrix != null) o["matrix"] = matrix;
                Add(list, o);
            }

            Area("area_rect_evenodd", rect10, 0, 0.1, false, null, "10x10 → 100");
            Area("area_rect_nonzero", rect10, 1, 0.1, false, null, "10x10 → 100");
            Area("area_rect_offset", rectOffset, 0, 0.1, false, null, "平移不改变面积");
            Area("area_rect_matrix_scale2", rect10, 0, 0.1, false, Matrix(2, 0, 0, 2, 0, 0),
                "缩放 2 → 面积 ×4");
            Area("area_rect_matrix_translate", rect10, 0, 0.1, false, Matrix(1, 0, 0, 1, 100, -50),
                "纯平移：面积不变");
            Area("area_rect_matrix_reflect", rect10, 0, 0.1, false, Matrix(-1, 0, 0, 1, 0, 0),
                "镜像：面积应取绝对值还是负数？");
            Area("area_nested_same_evenodd", nestedSame, 0, 0.1, false, null,
                "同向嵌套 EvenOdd：100-36 = 64");
            Area("area_nested_same_nonzero", nestedSame, 1, 0.1, false, null,
                "同向嵌套 Nonzero：应当仍是 100（区域全填充）");
            Area("area_nested_opposite_evenodd", nestedOpposite, 0, 0.1, false, null,
                "反向嵌套 EvenOdd：64");
            Area("area_nested_opposite_nonzero", nestedOpposite, 1, 0.1, false, null,
                "反向嵌套 Nonzero：洞 → 64");
            Area("area_bowtie_evenodd", bowtie, 0, 0.1, false, null,
                "自交蝴蝶结 EvenOdd：两半三角各 25 → 50");
            Area("area_bowtie_nonzero", bowtie, 1, 0.1, false, null,
                "自交蝴蝶结 Nonzero：两半绕向相反 → 也是一个 50 或 0？");
            Area("area_bowtie_rev_nonzero", bowtieRev, 1, 0.1, false, null, "反向蝴蝶结 Nonzero");
            Area("area_circle_tol_0_001", circle, 0, 0.001, false, null, "圆 ≈ 314.159");
            Area("area_circle_tol_10", circle, 0, 10.0, false, null,
                "容差 10 → 粗展平，面积应当明显偏小");
            Area("area_circle_nonzero", circle, 1, 0.001, false, null, "圆 Nonzero");
            Area("area_open_triangle", openTri, 0, 0.1, false, null,
                "开放图形：面积按自动闭合算还是不封口？");
            Area("area_empty_path", empty, 0, 0.1, false, null, "空路径 → 0");
            Area("area_triangle", tri, 0, 0.1, false, null, "三角形 → 50");
        }

        // ==================================================================
        //  D. PathGeometryCombine
        // ==================================================================

        private static void CombineCases(List<GeometryCase> list)
        {
            byte[] r1 = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 10, 10) });
            byte[] r2overlap = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(5, 5, 10, 10) });
            byte[] r2disjoint = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(20, 20, 10, 10) });
            byte[] r2nested = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(2, 2, 6, 6) });
            byte[] r2identical = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 10, 10) });
            byte[] r2touching = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(10, 0, 10, 10) });

            void Comb(string id, byte[] a, byte[] b, int mode, int fr1 = 0, int fr2 = 0,
                JsonArray m1 = null, JsonArray m2 = null, JsonArray m = null,
                double tol = 0.1, bool rel = false, string note = null)
            {
                JsonObject o = Case(id, FnCombine, note);
                o["path1"] = Hex(a);
                o["path2"] = Hex(b);
                o["fillRule1"] = fr1;
                o["fillRule2"] = fr2;
                o["combineMode"] = mode;   // 0 Union 1 Intersect 2 Xor 3 Exclude
                o["tolerance"] = tol;
                o["relative"] = rel;
                // ⚠️ 上游这个导出对三个矩阵指针都做了 IFCNULL（geometry_api.cpp:356-360），
                // 而 IFCNULL 的错误码就是 E_HANDLE(0x80070006)：
                //   #define IFCNULL(obj) CHECKPTRHRGOTO(Cleanup,(obj),E_HANDLE)
                // 传 NULL（尽管 SAL 写的是 __in_ecount_opt）会直接被拒。
                // 托管真实调用方 PathGeometry.InternalCombine 永远传 &matrix。
                // 所以这里**一律显式给单位矩阵**，"没给矩阵"用单位矩阵表达。
                o["matrix"] = m ?? Matrix(1, 0, 0, 1, 0, 0);
                o["matrix1"] = m1 ?? Matrix(1, 0, 0, 1, 0, 0);
                o["matrix2"] = m2 ?? Matrix(1, 0, 0, 1, 0, 0);
                Add(list, o);
            }

            string[] modes = { "union", "intersect", "xor", "exclude" };
            for (int m = 0; m < 4; m++)
            {
                Comb($"combine_overlap_{modes[m]}", r1, r2overlap, m, 0, 0, null, null, null, 0.1, false,
                    "两个相交矩形的四种布尔模式");
            }
            for (int m = 0; m < 4; m++)
            {
                Comb($"combine_disjoint_{modes[m]}", r1, r2disjoint, m, 0, 0, null, null, null, 0.1, false,
                    "相离：Xor/Exclude 与 Union 应当同形");
            }
            for (int m = 0; m < 4; m++)
            {
                Comb($"combine_nested_{modes[m]}", r1, r2nested, m, 0, 0, null, null, null, 0.1, false,
                    "内含：Exclude 应当出洞");
            }
            for (int m = 0; m < 4; m++)
            {
                Comb($"combine_identical_{modes[m]}", r1, r2identical, m, 0, 0, null, null, null, 0.1, false,
                    "完全相同");
            }
            Comb("combine_touching_union", r1, r2touching, 0, 0, 0, null, null, null, 0.1, false,
                "共边相切：Union 应当合成一个矩形还是两个图形？");
            Comb("combine_touching_intersect", r1, r2touching, 1, 0, 0, null, null, null, 0.1, false,
                "共边相切：交集是零面积（空）还是退化线？");
            Comb("combine_fillrule_nonzero", r1, r2nested, 3, 1, 1, null, null, null, 0.1, false,
                "两个输入都是 Nonzero");
            Comb("combine_matrix1_only", r1, r2overlap, 0, 0, 0, Matrix(2, 0, 0, 2, 0, 0), null, null, 0.1, false,
                "只给 geometry1 矩阵");
            Comb("combine_geometry_matrix", r1, r2overlap, 0, 0, 0, null, null, Matrix(1, 0, 0, 1, 3, 4), 0.1, false,
                "结果矩阵（第三矩阵）");
            Comb("combine_tol_10", r1, r2overlap, 0, 0, 0, null, null, null, 10.0, false,
                "容差 10：直线图形不应受影响");
        }

        // ==================================================================
        //  E. HitTest
        // ==================================================================

        private static void HitTestCases(List<GeometryCase> list)
        {
            byte[] rect = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 10, 10) });
            byte[] nested = PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Rect(0, 0, 10, 10),
                PathDataBuilder.Rect(2, 2, 6, 6),
            });
            byte[] tri = PathDataBuilder.Build(new[] { PathDataBuilder.Triangle(0, 0, 10, 0, 0, 10) });
            byte[] line = PathDataBuilder.Build(new[] { PathDataBuilder.Line(0, 0, 10, 0) });
            byte[] empty = PathDataBuilder.Build(Array.Empty<FigSpec>());

            void Hit(string id, byte[] path, int rule, double hx, double hy, double tol,
                bool rel, JsonArray matrix = null, JsonObject pen = null, string note = null)
            {
                JsonObject o = PathCase(id, FnHit, path, note);
                o["fillRule"] = rule;
                o["tolerance"] = tol;
                o["relative"] = rel;
                o["hitPoint"] = JsonHelp.Arr(hx, hy);
                if (matrix != null) o["matrix"] = matrix;
                if (pen != null) o["pen"] = pen;
                Add(list, o);
            }

            Hit("hit_rect_inside", rect, 0, 5, 5, 0.0, false, null, null, "内部 → 命中");
            Hit("hit_rect_outside", rect, 0, 20, 20, 0.0, false, null, null, "远处 → 不命中");
            Hit("hit_rect_on_edge", rect, 0, 5, 0, 0.0, false, null, null,
                "正落在边界上：上游 fill 命中是否含边界？");
            Hit("hit_rect_just_outside_no_tol", rect, 0, 5, -0.001, 0.0, false, null, null,
                "边界外一点点、阈值 0");
            Hit("hit_rect_just_outside_tol_1", rect, 0, 5, -0.5, 1.0, false, null, null,
                "边界外 0.5、阈值 1 → 应当命中（阈值语义）");
            Hit("hit_rect_just_outside_tol_0_1", rect, 0, 5, -0.5, 0.1, false, null, null,
                "边界外 0.5、阈值 0.1 → 不命中");
            Hit("hit_rect_corner", rect, 0, 0, 0, 0.0, false, null, null, "角点");
            Hit("hit_nested_evenodd_in_hole", nested, 0, 5, 5, 0.0, false, null, null,
                "EvenOdd 的洞里 → 不命中");
            Hit("hit_nested_nonzero_in_hole", nested, 1, 5, 5, 0.0, false, null, null,
                "Nonzero 同向嵌套 → 命中");
            Hit("hit_nested_nonzero_on_inner_ring", nested, 1, 2, 5, 0.0, false, null, null,
                "Nonzero 内环上 → 命中");
            Hit("hit_nested_evenodd_outside_hole", nested, 0, 1, 5, 0.0, false, null, null, "EvenOdd 环上");
            Hit("hit_triangle_inside", tri, 0, 2, 2, 0.0, false, null, null);
            Hit("hit_triangle_outside", tri, 0, 8, 8, 0.0, false, null, null, "三角形斜边外");
            Hit("hit_triangle_on_hypotenuse", tri, 0, 5, 5, 0.0, false, null, null, "斜边上");
            Hit("hit_matrix_translated_inside", rect, 0, 105, 105, 0.0, false,
                Matrix(1, 0, 0, 1, 100, 100), null, "平移后的内部");
            Hit("hit_matrix_translated_outside", rect, 0, 5, 5, 0.0, false,
                Matrix(1, 0, 0, 1, 100, 100), null, "未平移的坐标就不该命中");
            Hit("hit_relative_tol", rect, 0, 15, 5, 0.5, true, null, null,
                "fRelative：阈值按包围盒边长缩放（10*0.5=5）→ 命中");
            Hit("hit_relative_tol_small", rect, 0, 15, 5, 0.1, true, null, null,
                "fRelative：10*0.1=1 → 不命中");
            Hit("hit_empty_path", empty, 0, 0, 0, 0.0, false, null, null, "空路径");
            Hit("hit_line_fill", line, 0, 5, 0, 0.0, false, null, null,
                "零面积直线：填充命中应当不命中");
            Hit("hit_line_stroke", line, 0, 5, 0.4, 0.0, false, null,
                Pen(2.0, "miter", "flat"), "描边命中：线宽 2 → 半宽 1，偏 0.4 应当命中");
            Hit("hit_line_stroke_miss", line, 0, 5, 2.0, 0.0, false, null,
                Pen(2.0, "miter", "flat"), "描边外 2.0 → 不命中");
            Hit("hit_rect_stroke_on_edge", rect, 0, 5, 0, 0.0, false, null,
                Pen(4.0, "miter", "flat"), "矩形的边框上（描边半宽 2）");
            Hit("hit_rect_stroke_center_miss", rect, 0, 5, 5, 0.0, false, null,
                Pen(4.0, "miter", "flat"), "矩形中心不在描边上 → 不命中（描边命中只测轮廓）");
            Hit("hit_nan_point", rect, 0, double.NaN, 0, 0.0, false, null, null, "NaN 命中点");
        }

        private static void HitTestPathCases(List<GeometryCase> list)
        {
            byte[] big = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 100, 100) });
            byte[] small = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(10, 10, 20, 20) });
            byte[] smallOut = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(200, 200, 20, 20) });
            byte[] overlap = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(50, 50, 100, 100) });
            byte[] same = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 100, 100) });
            byte[] touch = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(100, 0, 50, 50) });
            byte[] sameEdge = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(10, 10, 20, 20) });

            void Rel(string id, byte[] a, byte[] b, string note)
            {
                JsonObject o = Case(id, FnHitPath, note);
                o["path1"] = Hex(a);
                o["path2"] = Hex(b);
                o["fillRule1"] = 0;
                o["fillRule2"] = 0;
                o["tolerance"] = 0.1;
                o["relative"] = false;
                Add(list, o);
            }

            Rel("hitpath_small_inside_big", big, small,
                "geometry1=大矩形、geometry2=小矩形（小在内）→ 文档说 FullyInside");
            Rel("hitpath_big_contains_small", small, big,
                "geometry1=小矩形、geometry2=大矩形 → 文档说 FullyContains");
            Rel("hitpath_overlap", big, overlap, "部分相交 → Intersects");
            Rel("hitpath_disjoint", big, smallOut, "相离 → Empty");
            Rel("hitpath_identical", big, same, "完全相同：FullyInside 还是 Intersects？");
            Rel("hitpath_edge_touch", big, touch, "共边相切");
            Rel("hitpath_same_rect_two_objects", small, sameEdge, "同一个矩形（不同对象）");
        }

        // ==================================================================
        //  F. Widen / Outline（rTolerance 是否真被忽略）
        // ==================================================================

        private static void WidenOutlineCases(List<GeometryCase> list)
        {
            byte[] rect = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 100, 100) });
            byte[] circle = PathDataBuilder.Build(new[] { PathDataBuilder.Circle(50, 50, 40) });
            byte[] bowtie = PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Polygon(0, 0, 20, 20, 20, 0, 0, 20),
            });
            byte[] nested = PathDataBuilder.Build(new[]
            {
                PathDataBuilder.Rect(0, 0, 100, 100),
                PathDataBuilder.Rect(20, 20, 60, 60),
            });
            byte[] open = PathDataBuilder.Build(new[] { PathDataBuilder.Line(0, 0, 50, 0) });

            void WO(string id, string fn, byte[] path, double tol, bool rel, int rule = 0,
                JsonObject pen = null, JsonArray matrix = null, string note = null)
            {
                JsonObject o = PathCase(id, fn, path, note);
                o["fillRule"] = rule;
                o["tolerance"] = tol;
                o["relative"] = rel;
                if (pen != null) o["pen"] = pen;
                if (matrix != null) o["matrix"] = matrix;
                Add(list, o);
            }

            WO("outline_rect", FnOutline, rect, 0.1, false, 0, null, null, "基础消解");
            WO("outline_circle_tol_0_001", FnOutline, circle, 0.001, false, 0, null, null,
                "rTolerance 是否影响 Outline 的输出点数？");
            WO("outline_circle_tol_0_1", FnOutline, circle, 0.1, false, 0, null, null, null);
            WO("outline_circle_tol_10", FnOutline, circle, 10.0, false, 0, null, null,
                "三个容差里若点数完全一样，说明 Outline 真的忽略容差");
            WO("outline_bowtie_evenodd", FnOutline, bowtie, 0.1, false, 0, null, null,
                "自交 + EvenOdd 消解");
            WO("outline_bowtie_nonzero", FnOutline, bowtie, 0.1, false, 1, null, null,
                "自交 + Nonzero 消解");
            WO("outline_nested_evenodd", FnOutline, nested, 0.1, false, 0, null, null, "嵌套 EvenOdd");
            WO("outline_nested_nonzero", FnOutline, nested, 0.1, false, 1, null, null, "嵌套 Nonzero");
            WO("outline_matrix", FnOutline, rect, 0.1, false, 0, null,
                Matrix(2, 0, 0, 2, 1, 1), "带矩阵");
            WO("outline_relative_true", FnOutline, circle, 0.01, true, 0, null, null, "fRelative=true");

            WO("widen_rect_pen2", FnWiden, rect, 0.1, false, 0,
                Pen(2.0, "miter", "flat"), null, "笔宽 2、斜接、平头");
            WO("widen_rect_pen2_round", FnWiden, rect, 0.1, false, 0,
                Pen(2.0, "round", "round"), null, "笔宽 2、圆角圆头");
            WO("widen_rect_pen2_bevel", FnWiden, rect, 0.1, false, 0,
                Pen(2.0, "bevel", "square"), null, "笔宽 2、斜角、方头");
            WO("widen_open_line_pen2", FnWiden, open, 0.1, false, 0,
                Pen(2.0, "miter", "flat"), null, "开放线段：平头 → 一个矩形");
            WO("widen_open_line_pen2_round", FnWiden, open, 0.1, false, 0,
                Pen(2.0, "miter", "round"), null, "开放线段：圆头 → 带半圆端");
            WO("widen_open_line_pen2_square", FnWiden, open, 0.1, false, 0,
                Pen(2.0, "miter", "square"), null, "开放线段：方头");
            WO("widen_dash", FnWiden, open, 0.1, false, 0,
                Pen(4.0, "miter", "flat", 10, 0, new[] { 2.0, 1.0 }), null,
                "虚线：dash 数组是相对笔宽的比例");
            WO("widen_dash_offset", FnWiden, open, 0.1, false, 0,
                Pen(4.0, "miter", "flat", 10, 0.5, new[] { 2.0, 1.0 }), null, "虚线 + DashOffset");
            WO("widen_dash_identity_matrix", FnWiden, open, 0.1, false, 0,
                Pen(4.0, "miter", "flat", 10, 0, new[] { 2.0, 1.0 }),
                Matrix(1, 0, 0, 1, 0, 0),
                "★ 显式给单位矩阵：真机在不给矩阵时**不做虚线**（见报告），这里验证是否与矩阵参数有关");
            WO("widen_dash_scale_matrix", FnWiden, open, 0.1, false, 0,
                Pen(4.0, "miter", "flat", 10, 0, new[] { 2.0, 1.0 }),
                Matrix(2, 0, 0, 2, 0, 0), "★ 虚线 + 缩放矩阵");
            WO("widen_dashed_rect", FnWiden, rect, 0.1, false, 0,
                Pen(2.0, "miter", "flat", 10, 0, new[] { 2.0, 1.0 }),
                Matrix(1, 0, 0, 1, 0, 0), "★ 闭合图形的虚线");
            WO("widen_rect_tol_0_001", FnWiden, circle, 0.001, false, 0,
                Pen(2.0, "miter", "flat"), null, "圆 + 描边：容差是否影响输出点数？");
            WO("widen_rect_tol_10", FnWiden, circle, 10.0, false, 0,
                Pen(2.0, "miter", "flat"), null, "圆 + 描边、大容差");
            WO("widen_zero_thickness", FnWiden, rect, 0.1, false, 0,
                Pen(0.0, "miter", "flat"), null, "笔宽 0：上游怎么处理？");
            WO("widen_negative_thickness", FnWiden, rect, 0.1, false, 0,
                Pen(-2.0, "miter", "flat"), null, "负笔宽");
            WO("widen_with_matrix", FnWiden, circle, 0.1, false, 0,
                Pen(2.0, "miter", "flat"), Matrix(2, 0, 0, 2, 0, 0),
                "矩阵只作用于几何、不作用于笔（geometry_api.cpp:154）");
        }

        // ==================================================================
        //  G. CopyPixelBuffer
        // ==================================================================

        private static void CopyPixelCases(List<GeometryCase> list)
        {
            void Cpb(string id, string inHex, uint outSize, uint outStride, uint outOffBits,
                uint inSize, uint inStride, uint inOffBits, uint height, uint widthBits,
                string seedHex = null, string note = null)
            {
                JsonObject o = Case(id, FnCopyPixels, note);
                o["inputHex"] = inHex;
                o["outputSize"] = outSize;
                o["outputStride"] = outStride;
                o["outputOffsetInBits"] = outOffBits;
                o["inputSize"] = inSize;
                o["inputStride"] = inStride;
                o["inputOffsetInBits"] = inOffBits;
                o["height"] = height;
                o["copyWidthInBits"] = widthBits;
                o["outputSeedHex"] = seedHex;
                Add(list, o);
            }

            string seed = "deadbeefdeadbeefdeadbeefdeadbeef";

            Cpb("cpb_8bit_1row",
                "0102030405060708", 8, 8, 0, 8, 8, 0, 1, 64, seed, "整字节整行，位偏移全 0");
            Cpb("cpb_8bit_2rows",
                "0102030405060708090a0b0c0d0e0f10", 16, 8, 0, 16, 8, 0, 2, 64, seed,
                "两行：stride 与实际宽度一致");
            Cpb("cpb_8bit_stride_gap",
                "0102030405060708090a0b0c0d0e0f10", 16, 8, 0, 16, 8, 0, 2, 60, seed,
                "宽度 60 位（非整字节）+ stride 8：末字节部分位");
            Cpb("cpb_4bpp_two_per_byte",
                "12345678", 4, 4, 0, 4, 4, 0, 1, 16, seed, "4bpp：一行 16 位 = 2 字节");
            Cpb("cpb_1bpp",
                "a5", 1, 1, 0, 1, 1, 0, 1, 8, seed, "1bpp：一行 8 位 = 1 字节");
            Cpb("cpb_1bpp_offset0_width3",
                "a5", 1, 1, 0, 1, 1, 0, 1, 3, seed, "1bpp 只拷 3 位 → 掩码应当只覆盖低 3 位");
            Cpb("cpb_out_off3_in_off3",
                "a5", 2, 2, 3, 1, 1, 3, 1, 3, seed,
                "两侧位偏移相同（3）：走逐字节掩码分支");
            Cpb("cpb_out_off0_in_off3",
                "a5", 1, 1, 0, 1, 1, 3, 1, 3, seed,
                "位偏移不同（0 vs 3）：走逐位搬运分支——作者说结果不直观");
            Cpb("cpb_out_off3_in_off0",
                "a5", 2, 2, 3, 1, 1, 0, 1, 3, seed, "位偏移不同（3 vs 0）");
            Cpb("cpb_out_off7_in_off7",
                "ff", 2, 2, 7, 1, 1, 7, 1, 1, seed, "偏移 7、宽度 1：只碰最高位");
            Cpb("cpb_out_off5_in_off2_width11",
                "a5c3", 3, 3, 5, 2, 2, 2, 1, 11, seed,
                "跨界宽度 11 位、两侧偏移都非 0");
            Cpb("cpb_out_off0_in_off7_width9",
                "80ff", 2, 2, 0, 2, 2, 7, 1, 9, seed, "宽度 9 位跨两字节、输入偏移 7");
            Cpb("cpb_2rows_offset_mismatch",
                "a5c3a5c3", 4, 2, 1, 2, 2, 3, 2, 5, seed,
                "两行 × 两侧偏移不同");
            Cpb("cpb_height0", "a5", 1, 1, 0, 1, 1, 0, 0, 8, seed,
                "height=0 → 直接 S_OK，输出缓冲应当原封不动");
            Cpb("cpb_width0", "a5", 1, 1, 0, 1, 1, 0, 1, 0, seed, "宽度 0 → 同样什么都不做");
            Cpb("cpb_stride_too_small", "a5", 1, 1, 0, 1, 1, 0, 1, 16, seed,
                "输入 stride 装不下一行 → E_INVALIDARG");
            Cpb("cpb_output_size_too_small", "a5a5a5a5", 2, 2, 0, 4, 2, 0, 3, 16, seed,
                "输出缓冲装不下 3 行 → E_INVALIDARG；输出是否被写过？");
            Cpb("cpb_input_size_too_small", "a5a5a5a5", 4, 2, 0, 2, 2, 0, 3, 16, seed,
                "输入缓冲装不下 3 行 → E_INVALIDARG");
            Cpb("cpb_offset_gt7", "a5", 1, 1, 8, 1, 1, 0, 1, 1, null, "位偏移 8 → E_INVALIDARG");
            Cpb("cpb_in_offset_gt7", "a5", 1, 1, 0, 1, 1, 9, 1, 1, null, "输入位偏移 9 → E_INVALIDARG");
            Cpb("cpb_overflow_stride", "a5", 1, 1, 0, 1, 1, 0, 4000000000, 8, null,
                "height 极大：乘法溢出保护");
        }

        // ==================================================================
        //  H. GetTileBrushMapping
        // ==================================================================

        private static void TileBrushCases(List<GeometryCase> list)
        {
            void Tb(string id, int stretch, int alignX, int alignY, int vpUnits, int vbUnits,
                double[] shape, double[] content, double[] viewport, double[] viewbox,
                JsonArray transform = null, JsonArray relTransform = null, string note = null)
            {
                JsonObject o = Case(id, FnTileBrush, note);
                o["stretch"] = stretch;          // 0 None 1 Fill 2 Uniform 3 UniformToFill
                o["alignX"] = alignX;            // 0 Left 1 Center 2 Right
                o["alignY"] = alignY;            // 0 Top 1 Center 2 Bottom
                o["viewportUnits"] = vpUnits;    // 0 Absolute 1 RelativeToBoundingBox
                o["viewboxUnits"] = vbUnits;
                if (shape != null) o["shapeFillBounds"] = JsonHelp.Arr(shape);
                if (content != null) o["contentBounds"] = JsonHelp.Arr(content);
                o["viewport"] = JsonHelp.Arr(viewport);
                o["viewbox"] = JsonHelp.Arr(viewbox);
                if (transform != null) o["transform"] = transform;
                if (relTransform != null) o["relativeTransform"] = relTransform;
                Add(list, o);
            }

            double[] shape = { 0, 0, 100, 100 };
            double[] content = { 0, 0, 50, 50 };

            Tb("tb_fill_left_top", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "Stretch=Fill、绝对单位");
            Tb("tb_uniform_center_center", 2, 1, 1, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null, null);
            Tb("tb_uniform_right_bottom", 2, 2, 2, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null, null);
            Tb("tb_uniform_to_fill", 3, 1, 1, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 30.0 }, null, null,
                "UniformToFill 取 max 缩放");
            Tb("tb_none", 0, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "Stretch=None：scale 应为 1");
            Tb("tb_relative_viewport", 1, 0, 0, 1, 0, shape, content,
                new[] { 0.0, 0.0, 0.5, 0.5 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "viewport 相对单位 → 0.5*100 = 50");
            Tb("tb_relative_viewbox", 1, 0, 0, 0, 1, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 0.5, 0.5 }, null, null,
                "viewbox 相对单位");
            Tb("tb_relative_both", 1, 1, 1, 1, 1, shape, content,
                new[] { 0.0, 0.0, 0.5, 0.5 }, new[] { 0.0, 0.1, 0.5, 0.4 }, null, null,
                "viewport+viewbox 都是相对单位（viewbox 以 contentBounds 为基准）");
            Tb("tb_zero_width_viewport", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, 0.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "★ viewport 宽 0：上游 IsRectEmptyOrInvalid 不判 0 面积 → 除零。我方刻意加固");
            Tb("tb_zero_height_viewport", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 0.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "★ viewport 高 0");
            Tb("tb_zero_width_viewbox", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 0.0, 50.0 }, null, null,
                "★ viewbox 宽 0：上游 scaleX = 100/0 = +INF");
            Tb("tb_zero_height_viewbox", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 0.0 }, null, null,
                "★ viewbox 高 0");
            Tb("tb_empty_viewport_rect", 1, 0, 0, 0, 0, shape, content,
                new[] { double.PositiveInfinity, double.PositiveInfinity, double.NegativeInfinity, double.NegativeInfinity },
                new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "viewport = Rect.Empty 形态");
            Tb("tb_empty_viewbox_rect", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 },
                new[] { double.PositiveInfinity, double.PositiveInfinity, double.NegativeInfinity, double.NegativeInfinity },
                null, null, "viewbox = Rect.Empty 形态");
            Tb("tb_nan_viewport", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, double.NaN, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "viewport 宽 NaN");
            Tb("tb_negative_viewport", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, -10.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "viewport 负宽");
            Tb("tb_zero_shape_bounds", 1, 0, 0, 1, 1, new[] { 0.0, 0.0, 0.0, 0.0 },
                new[] { 0.0, 0.0, 50.0, 50.0 }, new[] { 0.0, 0.0, 1.0, 1.0 },
                new[] { 0.0, 0.0, 1.0, 1.0 }, null, null,
                "填充包围盒 0 面积时的相对单位展开");
            Tb("tb_no_shape_bounds", 1, 0, 0, 0, 0, null, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "shapeFillBounds = NULL");
            Tb("tb_no_content_bounds", 1, 0, 0, 0, 0, shape, null,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 }, null, null,
                "contentBounds = NULL");
            Tb("tb_with_transform", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 },
                D3D(2, 0, 0, 2, 5, 6), null, "带 Brush.Transform");
            Tb("tb_with_relative_transform", 1, 0, 0, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 },
                null, D3D(1, 0, 0, 1, 0.1f, 0.2f), "带 Brush.RelativeTransform（相对填充包围盒）");
            Tb("tb_with_both_transforms", 2, 1, 1, 0, 0, shape, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 },
                D3D(1, 0, 0, 1, 3, 4), D3D(1, 0, 0, 1, 0.5f, 0.5f),
                "两个变换同时给：绝对变换后乘相对变换");
            Tb("tb_relative_transform_zero_bounds", 1, 0, 0, 0, 0,
                new[] { 0.0, 0.0, 0.0, 0.0 }, content,
                new[] { 0.0, 0.0, 100.0, 100.0 }, new[] { 0.0, 0.0, 50.0, 50.0 },
                null, D3D(1, 0, 0, 1, 0.1f, 0.2f),
                "填充包围盒宽高为 0 时 RelativeTransform 应当被忽略");
        }

        private static JsonArray D3D(float m11, float m12, float m21, float m22, float dx, float dy)
        {
            var a = new JsonArray();
            float[] v =
            {
                m11, m12, 0, 0,
                m21, m22, 0, 0,
                0, 0, 1, 0,
                dx, dy, 0, 1,
            };
            foreach (float f in v) a.Add((double)f);
            return a;
        }

        // ==================================================================
        //  I. Bounds / PolygonBounds / fSkipHollows
        // ==================================================================

        private static void BoundsCases(List<GeometryCase> list)
        {
            byte[] rect = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 100, 50) });
            byte[] circle = PathDataBuilder.Build(new[] { PathDataBuilder.Circle(50, 50, 40) });

            // 可填充矩形 + 不可填充矩形（Flags 缺 IsFillable 位）→ HasHollows
            byte[] hollow = PathDataBuilder.Build(new[]
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

            byte[] rectBoundsValid = PathDataBuilder.Build(new[] { PathDataBuilder.Rect(0, 0, 100, 50) }, true);

            void B(string id, string fn, byte[] path, double tol, bool rel, bool skipHollows,
                JsonObject pen = null, JsonArray world = null, JsonArray geom = null,
                int rule = 0, string note = null)
            {
                JsonObject o = PathCase(id, fn, path, note);
                o["fillRule"] = rule;
                o["tolerance"] = tol;
                o["relative"] = rel;
                o["skipHollows"] = skipHollows;
                if (pen != null) o["pen"] = pen;
                if (world != null) o["worldMatrix"] = world;
                if (geom != null) o["geometryMatrix"] = geom;
                Add(list, o);
            }

            B("bounds_rect_nopen", FnPathBounds, rect, 0.1, false, false, null, null, null, 0,
                "无笔：紧包围盒");
            B("bounds_rect_pen2", FnPathBounds, rect, 0.1, false, false,
                Pen(2.0, "miter", "flat"), null, null, 0, "有笔：描边包围盒外扩 1");
            B("bounds_rect_pen2_world_scale2", FnPathBounds, rect, 0.1, false, false,
                Pen(2.0, "miter", "flat"), Matrix(2, 0, 0, 2, 0, 0), null, 0,
                "世界矩阵同时作用于笔与几何 → 外扩量也 ×2");
            B("bounds_rect_geom_matrix_scale2", FnPathBounds, rect, 0.1, false, false,
                Pen(2.0, "miter", "flat"), null, Matrix(2, 0, 0, 2, 0, 0), 0,
                "几何矩阵只作用于几何、**不作用于笔** → 外扩量仍是 1");
            B("bounds_circle", FnPathBounds, circle, 0.1, false, false, null, null, null, 0,
                "曲线的紧包围盒");
            B("bounds_circle_relative", FnPathBounds, circle, 0.01, true, false, null, null, null, 0,
                "相对容差");
            B("bounds_hollow_skip_false", FnPathBounds, hollow, 0.1, false, false, null, null, null, 0,
                "★ 含不可填充图形 + fSkipHollows=false → 应当覆盖到 200");
            B("bounds_hollow_skip_true", FnPathBounds, hollow, 0.1, false, true, null, null, null, 0,
                "★ 含不可填充图形 + fSkipHollows=true → 应当只到 10");
            B("bounds_validflag_set", FnPathBounds, rectBoundsValid, 0.1, false, false, null, null, null, 0,
                "置了 BoundsValid（精确盒子）：真机应当直接返回缓存盒子");
            B("bounds_validflag_set_with_rotate", FnPathBounds, rectBoundsValid, 0.1, false, false,
                null, Matrix(0, 1, -1, 0, 0, 0), null, 0,
                "矩阵是旋转 → 缓存盒子路径不适用，真机会另算");
            B("bounds_rect_nonzero", FnPathBounds, rect, 0.1, false, false, null, null, null, 1, "fillRule=Nonzero");

            // PolygonBounds：点数组 + 段类型数组
            void P(string id, double[] pts, byte[] types, uint pointCount, uint segCount,
                JsonObject pen = null, JsonArray world = null, JsonArray geom = null,
                bool skipHollows = false, string note = null)
            {
                JsonObject o = Case(id, FnPolyBounds, note);
                o["points"] = JsonHelp.Arr(pts);
                var ta = new JsonArray();
                foreach (byte t in types) ta.Add((int)t);
                o["types"] = ta;
                o["pointCount"] = pointCount;
                o["segmentCount"] = segCount;
                o["tolerance"] = 0.1;
                o["relative"] = false;
                o["skipHollows"] = skipHollows;
                if (pen != null) o["pen"] = pen;
                if (world != null) o["worldMatrix"] = world;
                if (geom != null) o["geometryMatrix"] = geom;
                Add(list, o);
            }

            P("polybounds_square", new double[] { 0, 0, 10, 0, 10, 10, 0, 10, 0, 0 },
                new byte[] { 1, 1, 1, 1 }, 5, 4, null, null, null, false, "正方形（起点 + 4 段直线）");
            P("polybounds_square_pen2", new double[] { 0, 0, 10, 0, 10, 10, 0, 10, 0, 0 },
                new byte[] { 1, 1, 1, 1 }, 5, 4, Pen(2.0, "miter", "flat"), null, null, false, "带笔");
            P("polybounds_bezier", new double[] { 0, 0, 0, 10, 10, 10, 10, 0 },
                new byte[] { 2 }, 4, 1, null, null, null, false, "单段三次贝塞尔");
            P("polybounds_gap", new double[] { 0, 0, 10, 0, 100, 100, 110, 100 },
                new byte[] { 1, 5, 1 }, 4, 3, null, null, null, false,
                "SegIsAGap=4：抬笔后第二段另起一点（3 段：直线/抬笔直线/直线）");
        }

        private static void PolygonHitCases(List<GeometryCase> list)
        {
            void PH(string id, double[] pts, byte[] types, uint pc, uint sc,
                double hx, double hy, double tol, JsonObject pen = null, string note = null)
            {
                JsonObject o = Case(id, FnPolyHit, note);
                o["points"] = JsonHelp.Arr(pts);
                var ta = new JsonArray();
                foreach (byte t in types) ta.Add((int)t);
                o["types"] = ta;
                o["pointCount"] = pc;
                o["segmentCount"] = sc;
                o["hitPoint"] = JsonHelp.Arr(hx, hy);
                o["tolerance"] = tol;
                o["relative"] = false;
                if (pen != null) o["pen"] = pen;
                Add(list, o);
            }

            PH("polyhit_inside", new double[] { 0, 0, 10, 0, 10, 10, 0, 10, 0, 0 },
                new byte[] { 1, 1, 1, 1 }, 5, 4, 5, 5, 0, null, "内部");
            PH("polyhit_outside", new double[] { 0, 0, 10, 0, 10, 10, 0, 10, 0, 0 },
                new byte[] { 1, 1, 1, 1 }, 5, 4, 50, 50, 0, null, "外部");
            PH("polyhit_stroke", new double[] { 0, 0, 10, 0 },
                new byte[] { 1 }, 2, 1, 5, 0.5, 0, Pen(2.0, "miter", "flat"), "描边命中");
        }

        // ==================================================================
        //  J. GetPointAtLengthFraction
        // ==================================================================

        private static void LengthCases(List<GeometryCase> list)
        {
            byte[] line = PathDataBuilder.Build(new[] { PathDataBuilder.Line(0, 0, 100, 0) });
            byte[] circle = PathDataBuilder.Build(new[] { PathDataBuilder.Circle(0, 0, 10) });
            byte[] empty = PathDataBuilder.Build(Array.Empty<FigSpec>());

            void L(string id, byte[] path, double frac, int rule = 0, JsonArray matrix = null, string note = null)
            {
                JsonObject o = PathCase(id, FnLength, path, note);
                o["fillRule"] = rule;
                o["fraction"] = frac;
                if (matrix != null) o["matrix"] = matrix;
                Add(list, o);
            }

            L("length_line_0", line, 0.0, 0, null, "起点");
            L("length_line_0_25", line, 0.25, 0, null, null);
            L("length_line_0_5", line, 0.5, 0, null, null);
            L("length_line_1", line, 1.0, 0, null, "终点");
            L("length_line_over_1", line, 1.5, 0, null, "越界：应当 clamp 还是原样外推？");
            L("length_line_negative", line, -0.5, 0, null, "负分数");
            L("length_line_nan", line, double.NaN, 0, null, "NaN 分数");
            L("length_empty_path", empty, 0.5, 0, null, "空路径");
            L("length_circle_0_3", circle, 0.3, 0, null, "曲线上的点与切线");
            L("length_line_matrix", line, 0.5, 0, Matrix(2, 0, 0, 2, 10, 10), "带矩阵");
        }
    }
}

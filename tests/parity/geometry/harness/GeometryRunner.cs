// Licensed to the .NET Foundation under one or more agreements.
//
// U1c：runner 抽象 + 结果编码 + 逐 case 比较器（两侧共享，源码逐字节相同）。

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.Json.Nodes;

namespace WpfGfx.Linux.Parity.Geometry
{
    public interface IGeometryRunner
    {
        /// <summary>跑一个用例。任何异常都变成 CaseResult.Error，不要往外抛。</summary>
        CaseResult Run(GeometryCase c);
    }

    /// <summary>
    /// 结果编码器：把"图形回调"这种可变长输出编成**两侧完全同名同序**的键。
    /// 两个 runner 都必须走这里，否则键名分歧会被误判成偏差。
    /// </summary>
    public sealed class ResultBuilder
    {
        private readonly CaseResult _r;

        public ResultBuilder(GeometryCase c)
        {
            _r = new CaseResult { Id = c.Id, Fn = c.Fn };
        }

        public CaseResult Result => _r;

        public ResultBuilder Hr(int hr) { _r.Hr = hr; return this; }

        public ResultBuilder Set(string name, double value)
        {
            _r.Scalars[name] = value;
            return this;
        }

        public ResultBuilder SetBool(string name, bool value) => Set(name, value ? 1 : 0);

        public ResultBuilder Vec(string name, params double[] values)
        {
            _r.Vectors[name] = values ?? Array.Empty<double>();
            return this;
        }

        public ResultBuilder Vec2(string name, double x, double y) => Vec(name, x, y);

        public ResultBuilder Buffer(string name, byte[] bytes)
        {
            _r.Buffers[name] = JsonHelp.ToHex(bytes);
            return this;
        }

        public ResultBuilder Error(string message)
        {
            _r.Error = message;
            return this;
        }

        /// <summary>图形回调收集器：把回调数据摊平成同名键。</summary>
        public void AddFigure(int index, bool isFilled, bool isClosed,
            float[] points, byte[] types)
        {
            string prefix = "fig" + index.ToString(CultureInfo.InvariantCulture);
            SetBool(prefix + ".filled", isFilled);
            SetBool(prefix + ".closed", isClosed);
            Set(prefix + ".pointCount", points.Length / 2);
            Set(prefix + ".typeCount", types.Length);
            if (points.Length >= 2) Vec2(prefix + ".start", points[0], points[1]);
            var flat = new double[points.Length];
            for (int i = 0; i < points.Length; i++) flat[i] = points[i];
            Vec(prefix + ".pts", flat);
            var t = new double[types.Length];
            for (int i = 0; i < types.Length; i++) t[i] = types[i];
            Vec(prefix + ".types", t);
        }

        public ResultBuilder FigureCount(int n)
        {
            Set("figCount", n);
            return this;
        }
    }

    // ==================================================================
    //  比较
    // ==================================================================

    public enum Verdict
    {
        /// <summary>逐位相同。</summary>
        Identical,
        /// <summary>在声明的浮点容差内相同。</summary>
        Close,
        /// <summary>几何相同，但图形/点序不同（环内旋转或反向）。</summary>
        Reordered,
        /// <summary>真的不一样。</summary>
        Deviation,
        /// <summary>一侧报错/HRESULT 不同/键集合不同。</summary>
        Structural,
    }

    public sealed class CaseComparison
    {
        public string Id;
        public string Fn;
        public Verdict Verdict;
        public string Why;
        /// <summary>最大相对误差（Close 时的参考）。</summary>
        public double MaxRelDelta;
        public double MaxAbsDelta;
        public string WorstKey;
        public List<string> Details = new List<string>();
        public string WindowsSummary;
        public string LinuxSummary;
        public string Note;
        /// <summary>被排除比较的"上游未定义输出"键（含理由）。</summary>
        public string UndefinedKeys;

        public bool IsMatch => Verdict == Verdict.Identical || Verdict == Verdict.Close;
    }

    public static class ResultComparer
    {
        /// <summary>
        /// 上游**根本不写**的输出键：真机回吐的是调用方栈上的未初始化值，
        /// 无法（也不该）对齐。用哨兵法验证过：把出参预置成 0x5EED0001，
        /// 真机原样返回 0x5EED0001，说明这个槽位从未被写过。
        ///
        ///   MilUtility_PathGeometryWiden → outFillRule
        ///     geometry_api.cpp:151-217 的 Widen 没有 `*pOutFillRule = ...`，
        ///     而 Outline(:254) / Flatten(:452) / Combine(:397) 三个都有。
        ///     托管调用方 Geometry.cs:687 也只是把它当 out 传进去，
        ///     `new PathGeometry(list.Figures, fillRule, null)` 读到的其实是垃圾
        ///     ——这是上游自身的一个疏漏（报告里如实记录）。
        /// </summary>
        private static readonly Dictionary<string, string[]> UndefinedOutputs =
            new Dictionary<string, string[]>(StringComparer.Ordinal)
            {
                { "MilUtility_PathGeometryWiden", new[] { "outFillRule" } },
            };

        // 浮点口径：几何内部全程 float32（上游 FLOAT/REAL），两侧算法不同
        //（WPF scanner vs Skia），所以按"绝对 + 相对"双阈值判等。
        public const double AbsTol = 1e-6;
        public const double RelTol = 2e-5;

        public static bool NumClose(double a, double b, out double abs, out double rel)
        {
            abs = 0; rel = 0;
            if (double.IsNaN(a) && double.IsNaN(b)) return true;
            if (double.IsInfinity(a) || double.IsInfinity(b))
                return double.IsInfinity(a) && double.IsInfinity(b) && Math.Sign(a) == Math.Sign(b);

            abs = Math.Abs(a - b);
            double scale = Math.Max(Math.Abs(a), Math.Abs(b));
            rel = scale > 0 ? abs / scale : 0;
            return abs <= AbsTol || rel <= RelTol;
        }

        public static CaseComparison Compare(CaseResult win, CaseResult lin, GeometryCase src)
        {
            var cmp = new CaseComparison
            {
                Id = win?.Id ?? lin?.Id,
                Fn = win?.Fn ?? lin?.Fn,
                Note = src?.Note,
            };

            cmp.WindowsSummary = Summarize(win);
            cmp.LinuxSummary = Summarize(lin);

            if (win == null || lin == null)
            {
                cmp.Verdict = Verdict.Structural;
                cmp.Why = win == null ? "Windows 侧没有这个 case 的结果" : "Linux 侧没有这个 case 的结果";
                return cmp;
            }

            if (win.Error != null || lin.Error != null)
            {
                if (win.Error != null && lin.Error != null)
                {
                    cmp.Verdict = Verdict.Structural;
                    cmp.Why = "两侧都抛异常（可能是同一原因）：" + win.Error + " || " + lin.Error;
                }
                else
                {
                    cmp.Verdict = Verdict.Structural;
                    cmp.Why = win.Error != null
                        ? "仅 Windows 侧抛异常：" + win.Error
                        : "仅 Linux 侧抛异常：" + lin.Error;
                }
                return cmp;
            }

            if (win.Hr != lin.Hr)
            {
                cmp.Verdict = Verdict.Structural;
                cmp.Why = $"HRESULT 不同：win=0x{win.Hr:X8} lin=0x{lin.Hr:X8}";
                return cmp;
            }

            string[] ignored = UndefinedOutputs.TryGetValue(win.Fn ?? "", out string[] keys)
                ? keys : Array.Empty<string>();
            if (ignored.Length > 0)
            {
                cmp.UndefinedKeys = string.Join(",", ignored) +
                    "（上游不写该出参：哨兵法验证真机原样回吐调用方栈值）";
            }
            Func<string, bool> IsIgnored = key => Array.IndexOf(ignored, key) >= 0;

            // TileBrush：上游契约明确写"brushIsEmpty 非 0 时 contentToShape 必须被忽略"
            //（PresentationCore/.../TileBrush.cs:144「the output of
            //  MilUtility_GetTileBrushMapping must be ignored」），真机在那个分支里
            // 根本不写这个出参（geometry_api.cpp 的 GetTileBrushMapping 提前 goto Cleanup）。
            // 所以两侧都报非空时，不比较矩阵。
            bool brushEmptyBoth = win.Scalars.TryGetValue("brushIsEmpty", out double we)
                && lin.Scalars.TryGetValue("brushIsEmpty", out double le)
                && we != 0 && le != 0;
            if (brushEmptyBoth && win.Vectors.ContainsKey("contentToShape"))
            {
                cmp.UndefinedKeys = (cmp.UndefinedKeys == null ? "" : cmp.UndefinedKeys + "；")
                    + "contentToShape（双方都报 brushIsEmpty≠0：上游契约要求忽略该出参，真机不写它）";
                ignored = new[] { "contentToShape" };
                IsIgnored = k => Array.IndexOf(ignored, k) >= 0;
            }

            var missingWin = lin.Scalars.Keys.Except(win.Scalars.Keys)
                .Concat(lin.Vectors.Keys.Except(win.Vectors.Keys))
                .Concat(lin.Buffers.Keys.Except(win.Buffers.Keys)).ToList();
            var missingLin = win.Scalars.Keys.Except(lin.Scalars.Keys)
                .Concat(win.Vectors.Keys.Except(lin.Vectors.Keys))
                .Concat(win.Buffers.Keys.Except(lin.Buffers.Keys)).ToList();
            if (missingWin.Count > 0 || missingLin.Count > 0)
            {
                cmp.Verdict = Verdict.Structural;
                cmp.Why = "输出键集合不同："
                    + (missingWin.Count > 0 ? "win 缺 [" + string.Join(",", missingWin) + "] " : "")
                    + (missingLin.Count > 0 ? "lin 缺 [" + string.Join(",", missingLin) + "]" : "");
                return cmp;
            }

            bool identical = true;
            bool allClose = true;
            var worst = new List<(double rel, double abs, string key)>();

            foreach (var kv in win.Scalars)
            {
                if (IsIgnored(kv.Key)) continue;
                double a = kv.Value, b = lin.Scalars[kv.Key];
                bool bitEqual = a.Equals(b);
                if (!bitEqual) identical = false;
                if (!NumClose(a, b, out double abs, out double rel))
                {
                    allClose = false;
                    cmp.Details.Add($"{kv.Key}: win={Fmt(a)} lin={Fmt(b)} (Δabs={abs:G3} Δrel={rel:G3})");
                }
                else if (!bitEqual)
                {
                    worst.Add((rel, abs, kv.Key));
                }
            }

            foreach (var kv in win.Vectors)
            {
                if (IsIgnored(kv.Key)) continue;
                double[] a = kv.Value, b = lin.Vectors[kv.Key];
                if (a.Length != b.Length)
                {
                    cmp.Verdict = Verdict.Structural;
                    cmp.Why = $"{kv.Key} 长度不同：win={a.Length} lin={b.Length}";
                    return cmp;
                }
                for (int i = 0; i < a.Length; i++)
                {
                    bool bitEqual = a[i].Equals(b[i]);
                    if (!bitEqual) identical = false;
                    if (!NumClose(a[i], b[i], out double abs, out double rel))
                    {
                        allClose = false;
                        cmp.Details.Add($"{kv.Key}[{i}]: win={Fmt(a[i])} lin={Fmt(b[i])} (Δabs={abs:G3} Δrel={rel:G3})");
                    }
                    else if (!bitEqual)
                    {
                        worst.Add((rel, abs, $"{kv.Key}[{i}]"));
                    }
                }
            }

            foreach (var kv in win.Buffers)
            {
                string a = kv.Value, b = lin.Buffers[kv.Key];
                if (!string.Equals(a, b, StringComparison.Ordinal))
                {
                    identical = false;
                    allClose = false;
                    cmp.Details.Add($"{kv.Key}: win={Trunc(a)} lin={Trunc(b)}");
                }
            }

            if (worst.Count > 0)
            {
                var w = worst.OrderByDescending(t => t.rel).First();
                cmp.MaxRelDelta = w.rel;
                cmp.MaxAbsDelta = w.abs;
                cmp.WorstKey = w.key;
            }

            if (allClose)
            {
                cmp.Verdict = identical ? Verdict.Identical : Verdict.Close;
                cmp.Why = identical ? "逐位相同" : $"浮点容差内相同（最大 Δrel={cmp.MaxRelDelta:G3} @ {cmp.WorstKey}）";
                return cmp;
            }

            // 还没过：试一次"图形集合等价"（图形顺序无关 + 环内旋转/反向无关）。
            if (TryFigureSetMatch(win, lin, out string relaxedWhy))
            {
                cmp.Verdict = Verdict.Reordered;
                cmp.Why = relaxedWhy;
                return cmp;
            }

            cmp.Verdict = Verdict.Deviation;
            cmp.Why = $"首个数值差异：{cmp.Details.FirstOrDefault()}（共 {cmp.Details.Count} 处）";
            return cmp;
        }

        /// <summary>
        /// 图形等价判定：把两侧的 fig*.pts 环做"图形置换 + 环内旋转 + 反向"匹配。
        /// 用来区分"几何一样、只是发射顺序不同"和"几何真的不一样"。
        /// </summary>
        private static bool TryFigureSetMatch(CaseResult win, CaseResult lin, out string why)
        {
            why = null;

            List<int> winFigs = FigureIndices(win);
            List<int> linFigs = FigureIndices(lin);
            if (winFigs.Count == 0 && linFigs.Count == 0) return false;
            if (winFigs.Count != linFigs.Count) return false;

            var used = new bool[linFigs.Count];
            for (int i = 0; i < winFigs.Count; i++)
            {
                double[] a = win.Vectors[$"fig{winFigs[i]}.pts"];
                bool matched = false;
                for (int j = 0; j < linFigs.Count; j++)
                {
                    if (used[j]) continue;
                    double[] b = lin.Vectors[$"fig{linFigs[j]}.pts"];
                    if (RingEquivalent(a, b))
                    {
                        used[j] = true;
                        matched = true;
                        break;
                    }
                }
                if (!matched) return false;
            }

            bool sameOrder = winFigs.SequenceEqual(linFigs);
            why = sameOrder
                ? "几何等价，但至少一个图形的点序不同（环内旋转或反向）"
                : "几何等价，但图形顺序不同";
            return true;
        }

        private static List<int> FigureIndices(CaseResult r)
        {
            var list = new List<int>();
            foreach (string key in r.Scalars.Keys)
            {
                if (key.StartsWith("fig", StringComparison.Ordinal) && key.EndsWith(".pointCount", StringComparison.Ordinal))
                    list.Add(int.Parse(key.Substring(3, key.Length - 3 - ".pointCount".Length), CultureInfo.InvariantCulture));
            }
            list.Sort();
            return list;
        }

        /// <summary>两个点环是否等价（允许环内旋转 / 整体反向 / 起点不同）。</summary>
        private static bool RingEquivalent(double[] rawA, double[] rawB)
        {
            // 闭合轮廓的点表末尾常常重复起点（上游就是这么发射的），
            // 直接做模 n 的环比较会被这个重复点破坏。先归一化掉尾部的重复起点。
            double[] a = DropTrailingDuplicate(rawA);
            double[] b = DropTrailingDuplicate(rawB);
            int na = a.Length / 2, nb = b.Length / 2;
            if (na != nb) return false;
            if (na == 0) return true;
            if (na == 1) return NumClose(a[0], b[0], out _, out _) && NumClose(a[1], b[1], out _, out _);

            for (int start = 0; start < nb; start++)
            {
                if (RingMatches(a, b, start, 1)) return true;
                if (RingMatches(a, b, start, -1)) return true;
            }
            return false;
        }

        private static double[] DropTrailingDuplicate(double[] pts)
        {
            int n = pts.Length / 2;
            if (n >= 2
                && NumClose(pts[0], pts[(n - 1) * 2], out _, out _)
                && NumClose(pts[1], pts[(n - 1) * 2 + 1], out _, out _))
            {
                var trimmed = new double[(n - 1) * 2];
                Array.Copy(pts, trimmed, trimmed.Length);
                return trimmed;
            }
            return pts;
        }

        private static bool RingMatches(double[] a, double[] b, int start, int dir)
        {
            int n = a.Length / 2;
            for (int i = 0; i < n; i++)
            {
                int j = ((start + dir * i) % n + n) % n;
                if (!NumClose(a[i * 2], b[j * 2], out _, out _)) return false;
                if (!NumClose(a[i * 2 + 1], b[j * 2 + 1], out _, out _)) return false;
            }
            return true;
        }

        private static string Fmt(double v)
        {
            if (double.IsNaN(v)) return "NaN";
            if (double.IsPositiveInfinity(v)) return "+INF";
            if (double.IsNegativeInfinity(v)) return "-INF";
            return v.ToString("R", CultureInfo.InvariantCulture);
        }

        private static string Trunc(string hex) =>
            hex == null ? "<null>" : (hex.Length <= 40 ? hex : hex.Substring(0, 40) + "…");

        public static string Summarize(CaseResult r)
        {
            if (r == null) return "<missing>";
            if (r.Error != null) return "EX:" + r.Error;
            var parts = new List<string> { "hr=0x" + r.Hr.ToString("X8") };
            foreach (var kv in r.Scalars.OrderBy(k => k.Key, StringComparer.Ordinal))
                parts.Add(kv.Key + "=" + Fmt(kv.Value));
            foreach (var kv in r.Vectors.OrderBy(k => k.Key, StringComparer.Ordinal))
                parts.Add(kv.Key + "=[" + string.Join(",", kv.Value.Take(24).Select(Fmt)) + (kv.Value.Length > 24 ? ",…" : "") + "]");
            foreach (var kv in r.Buffers.OrderBy(k => k.Key, StringComparer.Ordinal))
                parts.Add(kv.Key + "=" + Trunc(kv.Value));
            return string.Join(" ", parts);
        }
    }
}

using System;
using System.Collections.Generic;
using System.Windows.Media;
using static U1Parity.J;

namespace U1Parity
{
    /// <summary>
    /// The U1a scene set.  Every scene is a data tree; the renderer walks the same tree.
    /// </summary>
    public static class Scenes
    {
        public const int W = 256;
        public const int H = 256;

        // ---------- small builders ----------
        private static Dictionary<string, object> Rect(double x, double y, double w, double h, string fill, string stroke, double sw)
            => O("op", "rect", "x", x, "y", y, "w", w, "h", h, "fill", fill, "stroke", stroke, "strokeWidth", sw);

        private static Dictionary<string, object> Rect(double x, double y, double w, double h, string fill)
            => O("op", "rect", "x", x, "y", y, "w", w, "h", h, "fill", fill, "stroke", null, "strokeWidth", 0.0);

        private static Dictionary<string, object> RoundRect(double x, double y, double w, double h, double rx, double ry, string fill, string stroke, double sw)
            => O("op", "roundrect", "x", x, "y", y, "w", w, "h", h, "rx", rx, "ry", ry, "fill", fill, "stroke", stroke, "strokeWidth", sw);

        private static Dictionary<string, object> Ellipse(double cx, double cy, double rx, double ry, string fill, string stroke, double sw)
            => O("op", "ellipse", "cx", cx, "cy", cy, "rx", rx, "ry", ry, "fill", fill, "stroke", stroke, "strokeWidth", sw);

        private static Dictionary<string, object> Line(double x1, double y1, double x2, double y2, string stroke, double sw,
            double[] dash, double dashOffset, string dashCap)
            => O("op", "line", "x1", x1, "y1", y1, "x2", x2, "y2", y2, "stroke", stroke, "strokeWidth", sw,
                 "dash", dash == null ? null : L(ToObj(dash)), "dashOffset", dashOffset, "dashCap", dashCap);

        private static object[] ToObj(double[] a)
        {
            var r = new object[a.Length];
            for (int i = 0; i < a.Length; i++) r[i] = a[i];
            return r;
        }

        private static Dictionary<string, object> Marker(double x, double y, string color)
            => Rect(x - 3.0, y - 3.0, 6.0, 6.0, color);

        private static Dictionary<string, object> ArcPath(double x0, double y0, double x1, double y1,
            double rx, double ry, double rot, bool large, string sweep, string fill, string stroke, double sw)
        {
            var fig = O("start", L(x0, y0), "closed", true, "filled", true,
                        "segments", L(O("seg", "arc", "to", L(x1, y1), "rx", rx, "ry", ry,
                                        "rot", rot, "largeArc", large, "sweep", sweep)));
            return O("op", "path", "fillRule", "nonzero", "figures", L(fig),
                     "fill", fill, "stroke", stroke, "strokeWidth", sw);
        }

        private static Dictionary<string, object> At(double tx, double ty, params object[] children)
            => O("op", "transform", "matrices", L(L(1.0, 0.0, 0.0, 1.0, tx, ty)), "children", new List<object>(children));

        private static List<object> Bg()
            => L(Rect(0.0, 0.0, W, H, "#FFFFFFFF"));

        private static Dictionary<string, object> Probe(double x, double y, string kind, string note, string expect = null, double tol = 2.0)
            => O("x", x, "y", y, "kind", kind, "note", note, "expect", expect, "expectTolerance", tol);

        private static Dictionary<string, object> Scene(string id, string desc, List<object> ops, List<object> probes)
            => O("id", id, "png", id + ".png", "description", desc, "ops", ops, "probes", probes);

        private static List<object> Star(double cx, double cy, double rOut, string fillRule, string fill)
        {
            // regular pentagram {5/2}: vertices 0,2,4,1,3
            int[] order = { 0, 2, 4, 1, 3 };
            var pts = new List<double[]>();
            for (int k = 0; k < 5; k++)
            {
                double th = (-90.0 + 72.0 * k) * Math.PI / 180.0;
                pts.Add(new[] { cx + rOut * Math.Cos(th), cy + rOut * Math.Sin(th) });
            }
            var segs = new List<object>();
            for (int i = 1; i < 5; i++)
            {
                var p = pts[order[i]];
                segs.Add(O("seg", "line", "to", L(p[0], p[1])));
            }
            var st = pts[order[0]];
            var fig = O("start", L(st[0], st[1]), "closed", true, "filled", true, "segments", segs);
            return L(O("op", "path", "fillRule", fillRule, "figures", L(fig),
                       "fill", fill, "stroke", null, "strokeWidth", 0.0));
        }

        // ---------- scene set ----------
        public static List<object> Build()
        {
            var scenes = new List<object>();

            // ============ 01 solid ============
            {
                var ops = Bg();
                ops.Add(Rect(32, 32, 120, 80, "#FF2E5FA3"));
                ops.Add(Rect(170, 150, 60, 60, "#FFB0B0B0"));
                var pr = L(
                    Probe(0, 0, "interior", "background white", "#FFFFFFFF"),
                    Probe(100, 70, "interior", "inside blue rect", "#FF2E5FA3"),
                    Probe(200, 180, "interior", "inside gray rect", "#FFB0B0B0"),
                    Probe(160, 60, "interior", "background between the two rects", "#FFFFFFFF"),
                    Probe(250, 250, "interior", "background bottom-right", "#FFFFFFFF"),
                    Probe(36, 36, "interior", "4px inside blue rect top-left corner", "#FF2E5FA3"),
                    Probe(148, 108, "interior", "4px inside blue rect bottom-right corner", "#FF2E5FA3"));
                scenes.Add(Scene("scene01_solid", "opaque axis-aligned rectangle fills, no AA dependence", ops, pr));
            }

            // ============ 02 rounded rect ============
            {
                var ops = Bg();
                ops.Add(RoundRect(40, 40, 160, 110, 24, 24, "#FFCC3333", "#FF1A1A1A", 6));
                var pr = L(
                    Probe(120, 95, "interior", "fill centre", "#FFCC3333"),
                    Probe(60, 95, "interior", "fill, 20px right of left edge", "#FFCC3333"),
                    Probe(40, 95, "interior", "stroke centre on the straight left edge", "#FF1A1A1A"),
                    Probe(120, 40, "interior", "stroke centre on the straight top edge", "#FF1A1A1A"),
                    Probe(45, 45, "interior", "on the rounded corner stroke: 26.2px from the arc centre, the 6px stroke spans 21..27", "#FF1A1A1A"),
                    Probe(180, 130, "interior", "fill near bottom-right corner", "#FFCC3333"),
                    Probe(198, 148, "interior", "outside the rounded corner arc -> background", "#FFFFFFFF"));
                scenes.Add(Scene("scene02_roundrect", "rounded rectangle, fill + 6px stroke, corner radius 24", ops, pr));
            }

            // ============ 03 ellipse ============
            {
                var ops = Bg();
                ops.Add(Ellipse(128, 128, 80, 56, "#FF33AA55", "#FF0000CC", 8));
                var pr = L(
                    Probe(128, 128, "interior", "fill centre", "#FF33AA55"),
                    Probe(128, 80, "interior", "fill near top (stroke inner edge at y=76)", "#FF33AA55"),
                    Probe(128, 72, "interior", "stroke centre at top (y=cy-ry)", "#FF0000CC"),
                    Probe(128, 58, "interior", "background above the ellipse", "#FFFFFFFF"),
                    Probe(200, 128, "interior", "fill near right", "#FF33AA55"),
                    Probe(208, 128, "interior", "stroke centre at right (x=cx+rx)", "#FF0000CC"),
                    Probe(128, 190, "interior", "background below the ellipse", "#FFFFFFFF"));
                scenes.Add(Scene("scene03_ellipse", "ellipse fill + 8px stroke, rx != ry", ops, pr));
            }

            // ============ 04 linear gradient ============
            {
                var ops = Bg();
                ops.Add(O("op", "linearGradient", "x", 16.0, "y", 16.0, "w", 224.0, "h", 80.0,
                    "mapping", "absolute", "start", L(16.0, 16.0), "end", L(240.0, 96.0), "spread", "pad",
                    "stops", L(O("offset", 0.0, "color", "#FFFF0000"),
                               O("offset", 0.5, "color", "#FF00FF00"),
                               O("offset", 1.0, "color", "#FF0000FF")),
                    "fill", null, "stroke", null, "strokeWidth", 0.0));
                ops.Add(O("op", "linearGradient", "x", 16.0, "y", 152.0, "w", 224.0, "h", 60.0,
                    "mapping", "absolute", "start", L(16.0, 152.0), "end", L(240.0, 152.0), "spread", "pad",
                    "stops", L(O("offset", 0.0, "color", "#FF000000"),
                               O("offset", 1.0, "color", "#FFFFFFFF")),
                    "fill", null, "stroke", null, "strokeWidth", 0.0));
                ops.Add(O("op", "linearGradient", "x", 16.0, "y", 224.0, "w", 224.0, "h", 28.0,
                    "mapping", "absolute", "start", L(16.0, 224.0), "end", L(128.0, 224.0), "spread", "reflect",
                    "stops", L(O("offset", 0.0, "color", "#FFFF0000"),
                               O("offset", 1.0, "color", "#FF0000FF")),
                    "fill", null, "stroke", null, "strokeWidth", 0.0));
                var pr = L(
                    Probe(16, 56, "interior", "t=0.0593 at the pixel centre -> sRGB lerp gives (225,30,0)", "#FFE11E00"),
                    Probe(128, 56, "interior", "t=0.5028 -> just past the middle stop, (0,254,1)", "#FF00FE01"),
                    Probe(72, 56, "interior", "t=0.2811 -> (112,143,0) under sRGB lerp, (191,187,0) under linear", "#FF6F9000"),
                    Probe(239, 95, "interior", "t=0.9976 -> (0,1,254)", "#FF0001FE"),
                    Probe(128, 182, "interior", "black->white at t=0.5022: 128 proves sRGB interpolation, linear scRGB would give ~188", "#FF808080"),
                    Probe(128, 238, "interior", "reflect: t=1.0045 folds to 0.9955 -> (1,0,254)", "#FF0100FE"),
                    Probe(192, 238, "interior", "reflect: t=1.5759 folds to 0.4241 -> (147,0,108)", "#FF92006D"));
                scenes.Add(Scene("scene04_linear_gradient", "linear gradients: 3 absolute stops, black->white midpoint probe, SpreadMethod.Reflect", ops, pr));
            }

            // ============ 05 radial gradient ============
            {
                var ops = Bg();
                ops.Add(O("op", "radialGradient", "x", 8.0, "y", 8.0, "w", 116.0, "h", 240.0,
                    "mapping", "relative", "center", L(0.5, 0.5), "origin", L(0.5, 0.5), "radius", L(0.5, 0.5),
                    "stops", L(O("offset", 0.0, "color", "#FFFFFFFF"), O("offset", 1.0, "color", "#FF1040A0")),
                    "fill", null, "stroke", null, "strokeWidth", 0.0));
                ops.Add(O("op", "radialGradient", "x", 132.0, "y", 8.0, "w", 116.0, "h", 240.0,
                    "mapping", "relative", "center", L(0.5, 0.5), "origin", L(0.3, 0.3), "radius", L(0.4, 0.4),
                    "stops", L(O("offset", 0.0, "color", "#FFFFFFFF"), O("offset", 1.0, "color", "#FF1040A0")),
                    "fill", null, "stroke", null, "strokeWidth", 0.0));
                var pr = L(
                    Probe(66, 128, "interior", "cell A centre == gradient centre, t~0.009 -> near-white"),
                    Probe(10, 10, "interior", "cell A corner: normalised distance 1.37 > 1 -> clamped last stop", "#FF1040A0"),
                    Probe(12, 128, "interior", "cell A left edge: t close to 1, not clamped"),
                    Probe(190, 128, "interior", "cell B centre, origin offset -> t < 1"),
                    Probe(167, 80, "interior", "cell B gradient origin, t~0.01 -> near-white"),
                    Probe(246, 246, "interior", "cell B bottom-right corner: normalised distance 1.73 > 1 -> clamped last stop", "#FF1040A0"));
                scenes.Add(Scene("scene05_radial_gradient", "radial gradients: concentric + offset GradientOrigin, radius 0.4/0.5 of bbox", ops, pr));
            }

            // ============ 06 dash ============
            {
                var ops = Bg();
                ops.Add(Line(16, 24, 240, 24, "#FF000080", 6, new[] { 4.0, 2.0 }, 0, "flat"));
                ops.Add(Line(16, 56, 240, 56, "#FF000080", 6, new[] { 2.0, 1.0 }, 0, "flat"));
                ops.Add(Line(16, 88, 240, 88, "#FF000080", 6, new[] { 2.0, 1.0, 0.5, 1.0 }, 0, "flat"));
                ops.Add(Line(16, 120, 240, 120, "#FF000080", 6, new[] { 0.0, 2.0, 4.0, 2.0 }, 0, "round"));
                ops.Add(Line(16, 152, 240, 152, "#FF000080", 6, new[] { 2.0, 2.0 }, 0, "flat"));
                ops.Add(Line(16, 184, 240, 184, "#FF000080", 6, new[] { 4.0, 2.0 }, 2, "flat"));
                ops.Add(Line(16, 216, 240, 216, "#FF000080", 6, new[] { 2.0, 2.0 }, 0, "round"));
                ops.Add(Line(16, 248, 240, 248, "#FF000080", 6, new[] { 2.0, 2.0, 0.0, 2.0 }, 0, "round"));
                var pr = L(
                    Probe(28, 24, "interior", "{4,2} offset 0: on-dash (on 24px from x=16)", "#FF000080"),
                    Probe(46, 24, "interior", "{4,2} offset 0: gap (off 12px from x=40)", "#FFFFFFFF"),
                    Probe(64, 24, "interior", "{4,2} offset 0: on-dash (from x=52)", "#FF000080"),
                    Probe(22, 56, "interior", "{2,1}: on-dash (on 12px from x=16)", "#FF000080"),
                    Probe(31, 56, "interior", "{2,1}: gap (off 6px from x=28)", "#FFFFFFFF"),
                    Probe(31, 88, "interior", "{2,1,0.5,1}: gap (off 6px from x=28)", "#FFFFFFFF"),
                    Probe(35, 88, "interior", "{2,1,0.5,1}: on-dash (on 3px from x=34)", "#FF000080"),
                    Probe(22, 184, "interior", "{4,2} offset=2 (12px phase shift): on-dash", "#FF000080"),
                    Probe(34, 184, "interior", "{4,2} offset=2: gap (off from x=28)", "#FFFFFFFF"));
                scenes.Add(Scene("scene06_dash", "dash styles: absolute dash arrays in multiples of the 6px stroke width, offsets, dash caps", ops, pr));
            }

            // ============ 07 opacity ============
            {
                var ops = Bg();
                ops.Add(Rect(0, 0, 128, 256, "#FFFF0000"));
                ops.Add(Rect(128, 0, 128, 256, "#FF0000FF"));
                var half = O("op", "opacity", "value", 0.5, "children", L(
                    O("op", "rect", "x", 32.0, "y", 32.0, "w", 192.0, "h", 80.0,
                      "fill", "#FFFFFFFF", "stroke", null, "strokeWidth", 0.0)));
                ops.Add(half);
                var grp = O("op", "opacity", "value", 0.75, "children", L(
                    Ellipse(110, 150, 36, 36, "#80FFFF00", null, 0.0),
                    Ellipse(146, 150, 36, 36, "#8000FF00", null, 0.0)));
                ops.Add(grp);
                ops.Add(Rect(32, 200, 192, 40, "#80FFFFFF"));
                var pr = L(
                    Probe(64, 64, "interior", "Opacity 0.5 white over red -> (255,128,128)", "#FFFF8080"),
                    Probe(192, 64, "interior", "Opacity 0.5 white over blue -> (128,128,255)", "#FF8080FF"),
                    Probe(100, 150, "interior", "opacity group, yellow child only over red: 0.75*0.50196 -> (255,96,0); per-primitive alpha gives the same here", "#FFFF6000"),
                    Probe(122, 150, "interior", "opacity group overlap over red -> (159,144,0). A true group layer is required; per-primitive alpha would give (159,156,0)", "#FF9F9000"),
                    Probe(134, 150, "interior", "opacity group overlap over blue -> (48,144,111); per-primitive would give (48,156,111)", "#FF30906F"),
                    Probe(170, 150, "interior", "opacity group, green child only over blue -> (0,96,159)", "#FF00609F"),
                    Probe(64, 220, "interior", "#80FFFFFF brush alpha over red -> (255,128,128)", "#FFFF8080"),
                    Probe(192, 220, "interior", "#80FFFFFF brush alpha over blue -> (128,128,255)", "#FF8080FF"));
                scenes.Add(Scene("scene07_opacity", "DrawinContext.PushOpacity(0.5) over a two-colour background, a 0.75 group with two 50%-alpha children, and a brush-alpha rect", ops, pr));
            }

            // ============ 08 clip rect ============
            {
                var ops = Bg();
                // clip A only, then clip A and B nested: the two fills land in different regions
                ops.Add(O("op", "clip",
                    "clips", L(O("g", "rect", "x", 40.0, "y", 40.0, "w", 176.0, "h", 176.0)),
                    "children", L(Rect(0, 0, 256, 256, "#FF2266CC"))));
                ops.Add(O("op", "clip",
                    "clips", L(O("g", "rect", "x", 40.0, "y", 40.0, "w", 176.0, "h", 176.0),
                               O("g", "rect", "x", 80.0, "y", 80.0, "w", 100.0, "h", 100.0)),
                    "children", L(Rect(0, 0, 256, 256, "#FFAA22EE"))));
                ops.Add(Rect(0, 0, 40, 40, "#FFFF8800"));
                var pr = L(
                    Probe(20, 20, "interior", "orange marker drawn after the clip was popped", "#FFFF8800"),
                    Probe(60, 60, "interior", "inside clip A (40..216) but outside B (80..180) -> first fill only", "#FF2266CC"),
                    Probe(100, 100, "interior", "inside A and B -> second fill on top", "#FFAA22EE"),
                    Probe(200, 200, "interior", "inside A (x=200 < 216) but outside B -> first fill only", "#FF2266CC"),
                    Probe(190, 190, "interior", "2px past B's 180 edge -> A only", "#FF2266CC"),
                    Probe(230, 230, "interior", "outside clip A -> background", "#FFFFFFFF"));
                scenes.Add(Scene("scene08_clip_rect", "rectangular clips: one fill inside clip A, a second fill inside the nested A^B; the nested clip must intersect with A, not replace it", ops, pr));
            }

            // ============ 09 clip path + fill rule ============
            {
                var ops = Bg();
                var tri = O("g", "path", "fillRule", "nonzero", "figures", L(
                    O("start", L(128.0, 28.0), "closed", true, "filled", true, "segments", L(
                        O("seg", "line", "to", L(236.0, 228.0)),
                        O("seg", "line", "to", L(20.0, 228.0))))));
                ops.Add(O("op", "clip", "clips", L(tri), "children", L(
                    O("op", "linearGradient", "x", 0.0, "y", 0.0, "w", 256.0, "h", 256.0,
                      "mapping", "absolute", "start", L(0.0, 0.0), "end", L(256.0, 256.0), "spread", "pad",
                      "stops", L(O("offset", 0.0, "color", "#FFFF0000"),
                                 O("offset", 0.5, "color", "#FFFFDD00"),
                                 O("offset", 1.0, "color", "#FF0000FF")),
                      "fill", null, "stroke", null, "strokeWidth", 0.0))));
                // outline of the same triangle, drawn unclipped
                ops.Add(O("op", "path", "fillRule", "nonzero", "figures", L(
                    O("start", L(128.0, 28.0), "closed", true, "filled", false, "segments", L(
                        O("seg", "line", "to", L(236.0, 228.0)),
                        O("seg", "line", "to", L(20.0, 228.0))))),
                    "fill", null, "stroke", "#FF000000", "strokeWidth", 2.0));
                foreach (var s in Star(52, 52, 36, "nonzero", "#FF2266CC")) ops.Add(s);
                foreach (var s in Star(204, 52, 36, "evenodd", "#FFCC6622")) ops.Add(s);
                var pr = L(
                    Probe(128, 150, "interior", "inside triangle clip, t=(x+y)/512=0.5449 -> (232,201,23)", "#FFE8C917"),
                    Probe(60, 140, "interior", "outside triangle -> background", "#FFFFFFFF"),
                    Probe(128, 60, "interior", "inside triangle near apex, t=0.3691 -> first segment (red->#FFDD00) at f=0.738 -> (255,163,0)", "#FFFFA300"),
                    Probe(128, 28, "edge", "triangle apex vertex, 2px stroke"),
                    Probe(52, 52, "interior", "pentagram centre, FillRule.Nonzero -> winding 2 -> filled", "#FF2266CC"),
                    Probe(204, 52, "interior", "pentagram centre, FillRule.EvenOdd -> winding 2 -> NOT filled", "#FFFFFFFF"),
                    Probe(49, 30, "interior", "pentagram top arm (winding 1) -> filled under both rules", "#FF2266CC"),
                    Probe(201, 30, "interior", "pentagram top arm (winding 1) -> filled under both rules", "#FFCC6622"));
                scenes.Add(Scene("scene09_clip_path_fillrule", "PathGeometry clip (filled+stroked triangle) plus pentagram fill-rule discrimination Nonzero vs EvenOdd", ops, pr));
            }

            // ============ 10 nested transforms ============
            {
                var ops = Bg();
                var r30 = new RotateTransform(30).Value;
                var rM25 = new RotateTransform(-25).Value;
                // (a) rotate 30 deg then translate
                var g1 = O("op", "transform",
                    "matrices", L(L(r30.M11, r30.M12, r30.M21, r30.M22, r30.OffsetX, r30.OffsetY),
                                  L(1.0, 0.0, 0.0, 1.0, 30.0, 30.0)),
                    "children", L(
                        O("op", "rect", "x", 0.0, "y", 0.0, "w", 60.0, "h", 40.0, "fill", "#FF1188FF", "stroke", "#FF003366", "strokeWidth", 2.0),
                        Rect(-2.0, -2.0, 10.0, 10.0, "#FFFF0000")));
                ops.Add(g1);
                // (b) scale, rotate, translate
                var g2 = O("op", "transform",
                    "matrices", L(L(1.5, 0.0, 0.0, 0.75, 0.0, 0.0),
                                  L(rM25.M11, rM25.M12, rM25.M21, rM25.M22, rM25.OffsetX, rM25.OffsetY),
                                  L(1.0, 0.0, 0.0, 1.0, 140.0, 140.0)),
                    "children", L(RoundRect(0, 0, 60, 40, 8, 8, "#FFCC88FF", "#FF552288", 2)));
                ops.Add(g2);
                // (c) non-uniform scale of a stroked rect
                var g3 = O("op", "transform",
                    "matrices", L(L(2.0, 0.0, 0.0, 1.0, 0.0, 0.0)),
                    "children", L(O("op", "rect", "x", 20.0, "y", 20.0, "w", 60.0, "h", 30.0, "fill", null, "stroke", "#FF116611", "strokeWidth", 4.0)));
                ops.Add(g3);
                var pr = L(
                    Probe(29, 52, "interior", "group a: local (10,20) rotated 30deg then +30,+30 -> fill", "#FF1188FF"),
                    Probe(46, 62, "interior", "group a: local (30,20) centre -> fill", "#FF1188FF"),
                    Probe(32, 37, "interior", "group a: red corner marker centre local (3,3)", "#FFFF0000"),
                    Probe(187, 135, "interior", "group b: local (30,20) through scale(1.5,0.75) rot(-25) translate(140,140)", "#FFCC88FF"),
                    Probe(40, 35, "interior", "group c: left edge x=40 with x-scale 2 -> 8px wide stroke", "#FF116611"),
                    Probe(100, 20, "interior", "group c: top edge y=20, y-scale 1 -> 4px stroke", "#FF116611"),
                    Probe(100, 35, "interior", "group c interior has no fill -> background", "#FFFFFFFF"),
                    Probe(10, 10, "interior", "background (outside every transformed group)", "#FFFFFFFF"));
                scenes.Add(Scene("scene10_transform", "nested transforms: rotate+translate, scale+rotate+translate, non-uniform scale of a stroke", ops, pr));
            }

            // ============ 11 arc: sweep x largeArc ============
            {
                var ops = Bg();
                // geom 1: chord along y=64, r = 26 > chord/2 = 22
                // geom 2: slanted chord (12,80)->(52,40), r = 30 > chord/2 = 28.28
                string[] combos = { "small-cw", "large-cw", "small-ccw", "large-ccw" };
                for (int c = 0; c < 4; c++)
                {
                    bool large = combos[c].StartsWith("large");
                    string sweep = combos[c].EndsWith("-cw") ? "cw" : "ccw";
                    ops.Add(At(c * 64.0, 0.0,
                        ArcPath(10, 64, 54, 64, 26, 26, 0, large, sweep, "#FFA9D0F5", "#FF11406E", 2),
                        Marker(10, 64, "#FFFF0000"),
                        Marker(54, 64, "#FF00AA00")));
                }
                for (int c = 0; c < 4; c++)
                {
                    bool large = combos[c].StartsWith("large");
                    string sweep = combos[c].EndsWith("-cw") ? "cw" : "ccw";
                    ops.Add(At(c * 64.0, 128.0,
                        ArcPath(12, 80, 52, 40, 30, 30, 0, large, sweep, "#FFFFE0B2", "#FF8A4B00", 2),
                        Marker(12, 80, "#FFFF0000"),
                        Marker(52, 40, "#FF00AA00")));
                }
                var pr = L(
                    Probe(32, 56, "interior", "cell0 (small-cw) inside the sliver above the chord -> filled. A no-op smallArc would leave this white", "#FFA9D0F5"),
                    Probe(96, 40, "interior", "cell1 (large-cw) inside the big segment above the chord -> filled. small-cw would leave this white", "#FFA9D0F5"),
                    Probe(160, 70, "interior", "cell2 (small-ccw) below the chord within the 12.1px sagitta -> filled. cw would leave this white", "#FFA9D0F5"),
                    Probe(224, 100, "interior", "cell3 (large-ccw) below the chord, 3.3px inside the arc; small-ccw only reaches y=76 so it would be white", "#FFA9D0F5"),
                    Probe(32, 178, "interior", "geom2 (slanted chord) cell0 local (32,50) - signature probe, value is empirical"),
                    Probe(96, 178, "interior", "geom2 cell1 local (32,50) - signature probe"),
                    Probe(160, 198, "interior", "geom2 cell2 local (32,70) - signature probe"),
                    Probe(224, 198, "interior", "geom2 cell3 local (32,70) - signature probe"));
                scenes.Add(Scene("scene11_arc_sweep_large", "ArcSegment specialty: SweepDirection x IsLargeArc over two chords; each arc is closed+filled so the enclosed segment is probeable. Cells L->R: small-cw, large-cw, small-ccw, large-ccw. Row 1 repeats with a slanted chord.", ops, pr));
            }

            // ============ 12 arc: elliptical + rotation ============
            {
                var ops = Bg();
                var cells = new object[]
                {
                    new object[]{ 45.0, 22.0,  0.0, false, "cw",  "rx=45 ry=22 rot=0 cw small" },
                    new object[]{ 45.0, 22.0, 45.0, true,  "cw",  "rx=45 ry=22 rot=45 cw large" },
                    new object[]{ 22.0, 45.0, 90.0, false, "ccw", "rx=22 ry=45 rot=90 ccw small (axes swapped)" },
                    new object[]{ 45.0, 22.0, 30.0, true,  "ccw", "rx=45 ry=22 rot=30 ccw large" },
                };
                for (int i = 0; i < 4; i++)
                {
                    var cell = (object[])cells[i];
                    int col = i % 2, row = i / 2;
                    ops.Add(At(col * 128.0 + 64.0, row * 128.0 + 64.0,
                        ArcPath(-35, 0, 35, 0, (double)cell[0], (double)cell[1], (double)cell[2],
                                (bool)cell[3], (string)cell[4], "#FFD5E8D4", "#FF2F6B2F", 2),
                        Marker(-35, 0, "#FFFF0000"),
                        Marker(35, 0, "#FF00AA00")));
                }
                var pr = L(
                    Probe(64, 59, "interior", "cell(0,0) local (0,-5): inside the 8.2px sagitta of the rx=45/ry=22 small arc -> filled; value empirical for the other three cells"),
                    Probe(64, 69, "interior", "cell(0,0) local (0,+5): below the chord -> background"),
                    Probe(192, 59, "interior", "cell(1,0) local (0,-5) - signature probe"),
                    Probe(192, 69, "interior", "cell(1,0) local (0,+5) - signature probe"),
                    Probe(64, 187, "interior", "cell(0,1) local (0,-5) - signature probe"),
                    Probe(64, 197, "interior", "cell(0,1) local (0,+5) - signature probe"),
                    Probe(192, 187, "interior", "cell(1,1) local (0,-5) - signature probe"),
                    Probe(192, 197, "interior", "cell(1,1) local (0,+5) - signature probe"));
                scenes.Add(Scene("scene12_arc_ellipse", "ArcSegment with RadiusX != RadiusY and non-zero RotationAngle; chord (-35,0)->(35,0) about each 128x128 cell centre. Probes are 5px either side of the chord midpoint; only cell(0,0) is analytically predicted.", ops, pr));
            }

            // ============ 13 arc: degenerate ============
            {
                var ops = Bg();
                // cell(0,0): radii too small -> must be scaled up uniformly by 4
                ops.Add(At(64.0, 64.0,
                    ArcPath(-40, 0, 40, 0, 10, 5, 0, false, "cw", "#FFDAE8FC", "#FF2B4A8B", 2),
                    Marker(-40, 0, "#FFFF0000"), Marker(40, 0, "#FF00AA00")));
                // cell(1,0): radius exactly chord/2, IsLargeArc=true
                ops.Add(At(192.0, 64.0,
                    ArcPath(-40, 0, 40, 0, 40, 40, 0, true, "cw", "#FFF8CECC", "#FF8B2B2B", 2),
                    Marker(-40, 0, "#FFFF0000"), Marker(40, 0, "#FF00AA00")));
                // cell(0,1): identical parameters but IsLargeArc=false -> must render identically to cell(1,0)
                ops.Add(At(64.0, 192.0,
                    ArcPath(-40, 0, 40, 0, 40, 40, 0, false, "cw", "#FFF8CECC", "#FF8B2B2B", 2),
                    Marker(-40, 0, "#FFFF0000"), Marker(40, 0, "#FF00AA00")));
                // cell(1,1): zero radius (must degenerate to a straight line) + absurdly large radius
                ops.Add(At(192.0, 192.0,
                    ArcPath(-40, 20, 40, 20, 0, 0, 0, false, "cw", "#FFE1D5E7", "#FF6B2B8B", 3),
                    ArcPath(-40, -20, 40, -20, 5000, 5000, 0, false, "cw", "#FFE1D5E7", "#FF6B2B8B", 3),
                    Marker(-40, 20, "#FFFF0000"), Marker(40, 20, "#FF00AA00")));
                var pr = L(
                    Probe(64, 54, "interior", "cell(0,0) local (0,-10): rx=10,ry=5 scaled x4 to 40,20 fills the upper half of the ellipse -> filled. No scaling would leave this white", "#FFDAE8FC"),
                    Probe(64, 74, "interior", "cell(0,0) below the chord -> background", "#FFFFFFFF"),
                    Probe(192, 54, "interior", "cell(1,0) r == chord/2, IsLargeArc=true -> upper semicircle filled", "#FFF8CECC"),
                    Probe(192, 74, "interior", "cell(1,0) below the chord -> background", "#FFFFFFFF"),
                    Probe(64, 182, "interior", "cell(0,1) same params but IsLargeArc=false -> must be identical to cell(1,0)", "#FFF8CECC"),
                    Probe(64, 202, "interior", "cell(0,1) below the chord -> background, must be identical to cell(1,0)", "#FFFFFFFF"),
                    Probe(192, 212, "interior", "cell(1,1) rx=ry=0 degenerates to the 3px straight line at local y=20", "#FF6B2B8B"),
                    Probe(192, 192, "interior", "cell(1,1) between the two lines -> background", "#FFFFFFFF"),
                    Probe(192, 172, "interior", "cell(1,1) rx=ry=5000 arc: sagitta is 0.16px so the 3px stroke covers y in 170.3..173.3 (or 168.3..171.3 if it bulges the other way) -> no expect recorded"));
                scenes.Add(Scene("scene13_arc_degenerate", "degenerate ArcSegments: radii too small (scaled up), radius == chord/2 (IsLargeArc is a no-op: cell(1,0) and cell(0,1) must render identically), zero radius, radius 5000", ops, pr));
            }

            // ============ 14/15 combine modes ============
            {
                // two overlapping circles, A at local (48,64) r40, B at (88,64) r40, 128x128 cells
                Func<double, double, string, string, List<object>> cellOps = (tx, ty, mode, label) =>
                {
                    var a = O("g", "ellipse", "cx", 48.0, "cy", 64.0, "rx", 40.0, "ry", 40.0);
                    var b = O("g", "ellipse", "cx", 88.0, "cy", 64.0, "rx", 40.0, "ry", 40.0);
                    return L(At(tx, ty,
                        O("op", "combine", "mode", mode, "a", a, "b", b,
                          "fill", "#FF00A060", "stroke", null, "strokeWidth", 0.0),
                        // aid for the human reader only: faint dashed outlines of A and B
                        O("op", "ellipse", "cx", tx + 48, "cy", ty + 64, "rx", 40.0, "ry", 40.0,
                          "fill", null, "stroke", "#FFB0B0B0", "strokeWidth", 1.0,
                          "dash", L(2.0, 2.0), "dashOffset", 0.0, "dashCap", "flat"),
                        O("op", "ellipse", "cx", tx + 88, "cy", ty + 64, "rx", 40.0, "ry", 40.0,
                          "fill", null, "stroke", "#FFB0B0B0", "strokeWidth", 1.0,
                          "dash", L(2.0, 2.0), "dashOffset", 0.0, "dashCap", "flat")));
                };
                {
                    var ops = Bg();
                    foreach (var o in cellOps(0, 0, "union", "union")) ops.Add(o);
                    foreach (var o in cellOps(128, 0, "xor", "xor")) ops.Add(o);
                    var pr = L(
                        Probe(20, 64, "interior", "union: A-only region -> filled", "#FF00A060"),
                        Probe(68, 64, "interior", "union: A^B overlap -> filled", "#FF00A060"),
                        Probe(112, 64, "interior", "union: B-only region -> filled", "#FF00A060"),
                        Probe(148, 64, "interior", "xor: A-only region -> filled", "#FF00A060"),
                        Probe(196, 64, "interior", "xor: A^B overlap -> NOT filled", "#FFFFFFFF"),
                        Probe(240, 64, "interior", "xor: B-only region -> filled", "#FF00A060"));
                    scenes.Add(Scene("scene14_combine_union_xor", "CombinedGeometry Union (left cell) vs Xor (right cell) of two overlapping circles r=40 with centres 40px apart", ops, pr));
                }
                {
                    var ops = Bg();
                    foreach (var o in cellOps(0, 0, "intersect", "intersect")) ops.Add(o);
                    foreach (var o in cellOps(128, 0, "exclude", "exclude")) ops.Add(o);
                    var pr = L(
                        Probe(20, 64, "interior", "intersect: A-only -> NOT filled", "#FFFFFFFF"),
                        Probe(68, 64, "interior", "intersect: A^B overlap -> filled", "#FF00A060"),
                        Probe(112, 64, "interior", "intersect: B-only -> NOT filled", "#FFFFFFFF"),
                        Probe(148, 64, "interior", "exclude (A-B): A-only -> filled", "#FF00A060"),
                        Probe(196, 64, "interior", "exclude (A-B): A^B overlap -> NOT filled. This probe decides debt #8: Exclude is A-B, NOT the symmetric difference", "#FFFFFFFF"),
                        Probe(240, 64, "interior", "exclude (A-B): B-only -> NOT filled. Symmetric difference would fill this", "#FFFFFFFF"));
                    scenes.Add(Scene("scene15_combine_intersect_exclude", "CombinedGeometry Intersect (left) vs Exclude (right). Exclude probe set resolves debt #8: A-B, not symmetric difference, not B-A.", ops, pr));
                }
            }

            return scenes;
        }

        public static Dictionary<string, object> Conventions()
        {
            return O(
                "canvas", O("width", (double)W, "height", (double)H, "dpi", 96.0, "background", "#FFFFFFFF"),
                "renderTarget", "WPF RenderTargetBitmap(256,256,96,96,PixelFormats.Pbgra32) over a single DrawingVisual; no Window, no HwndTarget",
                "pngFormat", "Bgra32 (straight alpha) produced by FormatConvertedBitmap(Pbgra32 -> Bgra32); every scene paints an opaque background so output alpha is 255 everywhere",
                "coordinateSystem", "origin top-left, +x right, +y down; pixel (x,y) is sampled at its centre (x+0.5, y+0.5); probe coordinates are integer pixel indices",
                "colorFormat", "#AARRGGBB, sRGB, straight (non-premultiplied) alpha",
                "antialiasing", "WPF default (EdgeMode.Unspecified -> anti-aliased). Probes marked 'interior' are >=3px away from any edge and are expected to match exactly; probes marked 'edge' sit on a boundary and may differ by AA coverage",
                "stroke", "centred on the geometry path; default caps Flat, default join Miter, default miter limit 10",
                "dash", "DashStyle.Dashes values are multiples of the stroke thickness; DashStyle.Offset is also in thickness units; pattern starts at the path start point",
                "matrix", "list of 6-tuples [m11,m12,m21,m22,dx,dy] in WPF row-vector convention: x' = x*m11 + y*m21 + dx, y' = x*m12 + y*m22 + dy. The list is composited as M0 x M1 x ... x Mn, so M0 is applied to the geometry first",
                "arc", "PathFigure(start) -> ArcSegment(point, size(rx,ry), rotationAngleDeg, isLargeArc, sweepDirection), x:y = IsClosed/IsFilled true; sweep 'cw' = SweepDirection.Clockwise (visually clockwise on screen because +y is down)",
                "arcDegenerate", "if the radii are too small to span the chord they are scaled up uniformly (SVG F.6.6); rx=ry=0 degenerates to a straight line",
                "fillRule", "'nonzero' = FillRule.Nonzero, 'evenodd' = FillRule.EvenOdd (PathGeometry default is evenodd)",
                "opacityGroup", "op 'opacity' = DrawingContext.PushOpacity(value): children are composited into a separate surface which is then blended as a whole, NOT per-primitive alpha",
                "clip", "op 'clip' pushes each geometry in 'clips' in order (intersection), draws children, then pops",
                "notCovered", "text/glyphs, bitmaps/ImageSource, effects (Blur/DropShadow), 3-D, animation, windowed composition"
            );
        }
    }
}

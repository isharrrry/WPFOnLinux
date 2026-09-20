using System;
using System.Collections.Generic;
using System.Globalization;
using System.Windows;
using System.Windows.Media;

namespace U1Parity
{
    /// <summary>
    /// Interprets the scene op tree with DrawingContext.  The op tree is the single source of
    /// truth: it is what gets rendered AND what gets serialized into scenes.json.
    /// </summary>
    public static class R
    {
        public static Color C(string hex)
        {
            if (hex == null) throw new ArgumentNullException(nameof(hex));
            if (hex.Length != 9 || hex[0] != '#') throw new Exception("color must be #AARRGGBB, got " + hex);
            uint v = uint.Parse(hex.Substring(1), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
            return Color.FromArgb((byte)(v >> 24), (byte)((v >> 16) & 0xFF), (byte)((v >> 8) & 0xFF), (byte)(v & 0xFF));
        }

        private static PenLineCap Cap(string s)
        {
            switch (s)
            {
                case "flat": return PenLineCap.Flat;
                case "round": return PenLineCap.Round;
                case "square": return PenLineCap.Square;
                case "triangle": return PenLineCap.Triangle;
                default: throw new Exception("bad cap " + s);
            }
        }

        private static PenLineJoin Join(string s)
        {
            switch (s)
            {
                case "miter": return PenLineJoin.Miter;
                case "bevel": return PenLineJoin.Bevel;
                case "round": return PenLineJoin.Round;
                default: throw new Exception("bad join " + s);
            }
        }

        private static GradientSpreadMethod Spread(string s)
        {
            switch (s)
            {
                case "pad": return GradientSpreadMethod.Pad;
                case "reflect": return GradientSpreadMethod.Reflect;
                case "repeat": return GradientSpreadMethod.Repeat;
                default: throw new Exception("bad spread " + s);
            }
        }

        private static GeometryCombineMode CombineMode(string s)
        {
            switch (s)
            {
                case "union": return GeometryCombineMode.Union;
                case "intersect": return GeometryCombineMode.Intersect;
                case "xor": return GeometryCombineMode.Xor;
                case "exclude": return GeometryCombineMode.Exclude;
                default: throw new Exception("bad combine mode " + s);
            }
        }

        public static Brush MakeFill(Dictionary<string, object> op)
        {
            if (!J.Has(op, "fill")) return null;
            return new SolidColorBrush(C(J.S(op, "fill")));
        }

        public static Pen MakePen(Dictionary<string, object> op)
        {
            if (!J.Has(op, "stroke")) return null;
            double w = J.Has(op, "strokeWidth") ? J.D(op, "strokeWidth") : 1.0;
            var pen = new Pen(new SolidColorBrush(C(J.S(op, "stroke"))), w);
            if (J.Has(op, "dash"))
            {
                var dashes = new List<double>();
                foreach (var d in (List<object>)op["dash"]) dashes.Add(J.N(d));
                double off = J.Has(op, "dashOffset") ? J.D(op, "dashOffset") : 0.0;
                pen.DashStyle = new DashStyle(dashes, off);
            }
            if (J.Has(op, "startCap")) pen.StartLineCap = Cap(J.S(op, "startCap"));
            if (J.Has(op, "endCap")) pen.EndLineCap = Cap(J.S(op, "endCap"));
            if (J.Has(op, "dashCap")) pen.DashCap = Cap(J.S(op, "dashCap"));
            if (J.Has(op, "lineJoin")) pen.LineJoin = Join(J.S(op, "lineJoin"));
            if (J.Has(op, "miterLimit")) pen.MiterLimit = J.D(op, "miterLimit");
            return pen;
        }

        public static Geometry MakeGeometry(Dictionary<string, object> g)
        {
            switch (J.S(g, "g"))
            {
                case "rect":
                    return new RectangleGeometry(new Rect(J.D(g, "x"), J.D(g, "y"), J.D(g, "w"), J.D(g, "h")));
                case "ellipse":
                    return new EllipseGeometry(new Point(J.D(g, "cx"), J.D(g, "cy")), J.D(g, "rx"), J.D(g, "ry"));
                case "path":
                    return MakePathGeometry(g);
                default:
                    throw new Exception("unknown geometry kind " + g["g"]);
            }
        }

        public static PathGeometry MakePathGeometry(Dictionary<string, object> g)
        {
            var pg = new PathGeometry();
            if (J.Has(g, "fillRule"))
                pg.FillRule = J.S(g, "fillRule") == "nonzero" ? FillRule.Nonzero : FillRule.EvenOdd;
            foreach (Dictionary<string, object> fig in (List<object>)g["figures"])
            {
                var pf = new PathFigure();
                var sp = (List<object>)fig["start"];
                pf.StartPoint = new Point(J.N(sp[0]), J.N(sp[1]));
                if (J.Has(fig, "closed")) pf.IsClosed = (bool)fig["closed"];
                if (J.Has(fig, "filled")) pf.IsFilled = (bool)fig["filled"];
                foreach (Dictionary<string, object> seg in (List<object>)fig["segments"])
                {
                    string kind = J.S(seg, "seg");
                    var to = (List<object>)seg["to"];
                    if (kind == "line")
                    {
                        pf.Segments.Add(new LineSegment(new Point(J.N(to[0]), J.N(to[1])), true));
                    }
                    else if (kind == "arc")
                    {
                        var arc = new ArcSegment();
                        arc.Point = new Point(J.N(to[0]), J.N(to[1]));
                        arc.Size = new Size(J.D(seg, "rx"), J.D(seg, "ry"));
                        arc.RotationAngle = J.Has(seg, "rot") ? J.D(seg, "rot") : 0.0;
                        arc.IsLargeArc = J.Has(seg, "largeArc") && (bool)seg["largeArc"];
                        arc.SweepDirection = J.S(seg, "sweep") == "cw" ? SweepDirection.Clockwise : SweepDirection.Counterclockwise;
                        arc.IsStroked = true;
                        pf.Segments.Add(arc);
                    }
                    else throw new Exception("unknown segment " + kind);
                }
                pg.Figures.Add(pf);
            }
            return pg;
        }

        public static Matrix MatrixOf(Dictionary<string, object> op)
        {
            Matrix m = Matrix.Identity;
            foreach (var raw in (List<object>)op["matrices"])
            {
                var a = (List<object>)raw;
                var t = new Matrix(J.N(a[0]), J.N(a[1]), J.N(a[2]), J.N(a[3]), J.N(a[4]), J.N(a[5]));
                m = Matrix.Multiply(m, t);
            }
            return m;
        }

        public static void DrawOps(DrawingContext dc, List<object> ops)
        {
            foreach (object raw in ops)
            {
                var op = (Dictionary<string, object>)raw;
                switch (J.S(op, "op"))
                {
                    case "rect":
                        dc.DrawRectangle(MakeFill(op), MakePen(op),
                            new Rect(J.D(op, "x"), J.D(op, "y"), J.D(op, "w"), J.D(op, "h")));
                        break;

                    case "roundrect":
                        dc.DrawRoundedRectangle(MakeFill(op), MakePen(op),
                            new Rect(J.D(op, "x"), J.D(op, "y"), J.D(op, "w"), J.D(op, "h")),
                            J.D(op, "rx"), J.D(op, "ry"));
                        break;

                    case "ellipse":
                        dc.DrawEllipse(MakeFill(op), MakePen(op),
                            new Point(J.D(op, "cx"), J.D(op, "cy")), J.D(op, "rx"), J.D(op, "ry"));
                        break;

                    case "line":
                        dc.DrawLine(MakePen(op),
                            new Point(J.D(op, "x1"), J.D(op, "y1")),
                            new Point(J.D(op, "x2"), J.D(op, "y2")));
                        break;

                    case "linearGradient":
                        {
                            var rect = new Rect(J.D(op, "x"), J.D(op, "y"), J.D(op, "w"), J.D(op, "h"));
                            var lg = new LinearGradientBrush();
                            lg.MappingMode = J.S(op, "mapping") == "relative"
                                ? BrushMappingMode.RelativeToBoundingBox : BrushMappingMode.Absolute;
                            var sp = (List<object>)op["start"];
                            var ep = (List<object>)op["end"];
                            lg.StartPoint = new Point(J.N(sp[0]), J.N(sp[1]));
                            lg.EndPoint = new Point(J.N(ep[0]), J.N(ep[1]));
                            lg.SpreadMethod = Spread(J.S(op, "spread"));
                            foreach (Dictionary<string, object> st in (List<object>)op["stops"])
                                lg.GradientStops.Add(new GradientStop(C(J.S(st, "color")), J.D(st, "offset")));
                            dc.DrawRectangle(lg, MakePen(op), rect);
                            break;
                        }

                    case "radialGradient":
                        {
                            var rect = new Rect(J.D(op, "x"), J.D(op, "y"), J.D(op, "w"), J.D(op, "h"));
                            var rg = new RadialGradientBrush();
                            rg.MappingMode = J.S(op, "mapping") == "relative"
                                ? BrushMappingMode.RelativeToBoundingBox : BrushMappingMode.Absolute;
                            var ce = (List<object>)op["center"];
                            var or = (List<object>)op["origin"];
                            rg.Center = new Point(J.N(ce[0]), J.N(ce[1]));
                            rg.GradientOrigin = new Point(J.N(or[0]), J.N(or[1]));
                            var rad = (List<object>)op["radius"];
                            rg.RadiusX = J.N(rad[0]);
                            rg.RadiusY = J.N(rad[1]);
                            foreach (Dictionary<string, object> st in (List<object>)op["stops"])
                                rg.GradientStops.Add(new GradientStop(C(J.S(st, "color")), J.D(st, "offset")));
                            dc.DrawRectangle(rg, MakePen(op), rect);
                            break;
                        }

                    case "path":
                        dc.DrawGeometry(MakeFill(op), MakePen(op), MakePathGeometry(op));
                        break;

                    case "combine":
                        {
                            var g1 = MakeGeometry((Dictionary<string, object>)op["a"]);
                            var g2 = MakeGeometry((Dictionary<string, object>)op["b"]);
                            var cg = new CombinedGeometry(CombineMode(J.S(op, "mode")), g1, g2);
                            dc.DrawGeometry(MakeFill(op), MakePen(op), cg);
                            break;
                        }

                    case "clip":
                        {
                            int n = 0;
                            foreach (Dictionary<string, object> g in (List<object>)op["clips"])
                            {
                                dc.PushClip(MakeGeometry(g));
                                n++;
                            }
                            DrawOps(dc, (List<object>)op["children"]);
                            for (int i = 0; i < n; i++) dc.Pop();
                            break;
                        }

                    case "opacity":
                        dc.PushOpacity(J.D(op, "value"));
                        DrawOps(dc, (List<object>)op["children"]);
                        dc.Pop();
                        break;

                    case "transform":
                        dc.PushTransform(new MatrixTransform(MatrixOf(op)));
                        DrawOps(dc, (List<object>)op["children"]);
                        dc.Pop();
                        break;

                    default:
                        throw new Exception("unknown op " + op["op"]);
                }
            }
        }
    }
}

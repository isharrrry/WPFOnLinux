using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Rectangle = System.Windows.Shapes.Rectangle;

namespace U1BrushOracle
{
    /// <summary>
    /// The asymmetric tile source shared by every case.
    ///
    /// WHY ASYMMETRIC: a symmetric source renders identically under Tile and FlipX,
    /// which would make the oracle look green while proving nothing. This pattern is
    /// deliberately lopsided so each flip mode is separable by named pixels:
    ///
    ///   source space is 32 x 32, continuous (rect right/bottom are exclusive)
    ///   ------------------------------------------------------------------
    ///   base            #FF202830   whole tile
    ///   red    quad     (0,0,12,12)      top-left      corner
    ///   green  quad     (20,0,12,12)     top-right     corner
    ///   blue   quad     (0,20,12,12)     bottom-left   corner
    ///   yellow quad     (20,20,12,12)    bottom-right  corner
    ///   magenta bar     (2,10,4,10)      LEFT-ONLY  (x 2..6,  y 10..20)
    ///   cyan    bar     (10,2,10,4)      TOP-ONLY   (x 10..20, y 2..6)
    ///   white   dot     (24,4,3,3)       off-centre, inside the green quad
    ///   purple triangle (12,12)->(20,12)->(12,20)  right angle at top-left
    ///   ------------------------------------------------------------------
    ///
    /// DISCRIMINATOR PIXELS (sample at pixel centres, see Program.cs):
    ///   mag-left   (4.5, 15.5)   magenta only in an UNFLIPPED tile
    ///   mag-right  (27.5,15.5)   magenta only in a HORIZONTALLY FLIPPED tile
    ///   cyan-top   (15.5, 4.5)   cyan only in an UNFLIPPED tile
    ///   cyan-bot   (15.5,27.5)   cyan only in a VERTICALLY FLIPPED tile
    /// Because the base tile (index 0) is never flipped, discrimination must be read
    /// from an odd tile index - every tiling case here produces at least tile 1.
    /// </summary>
    internal static class Pattern
    {
        public const double Size = 32.0;

        public const uint BaseColor = 0xFF202830;
        public const uint TriangleColor = 0xFF8040FF;

        public struct Feature
        {
            public double X, Y, W, H;
            public uint Argb;
            public Feature(double x, double y, double w, double h, uint argb)
            { X = x; Y = y; W = w; H = h; Argb = argb; }
        }

        /// <summary>Axis-aligned features, painted in order (later wins).</summary>
        public static readonly Feature[] Rects =
        {
            new Feature(0,  0,  12, 12, 0xFFD02020),   // red    top-left
            new Feature(20, 0,  12, 12, 0xFF20A040),   // green  top-right
            new Feature(0,  20, 12, 12, 0xFF2050D0),   // blue   bottom-left
            new Feature(20, 20, 12, 12, 0xFFE0C020),   // yellow bottom-right
            new Feature(2,  10, 4,  10, 0xFFFF00FF),   // magenta LEFT-ONLY bar
            new Feature(10, 2,  10, 4,  0xFF00FFFF),   // cyan    TOP-ONLY bar
            new Feature(24, 4,  3,  3,  0xFFFFFFFF),   // white dot
        };

        /// <summary>Same pattern with alpha, for the premultiplication family.</summary>
        public static readonly Feature[] AlphaRects =
        {
            new Feature(0,  0,  12, 12, 0x80FF0000),   // 50% red
            new Feature(20, 0,  12, 12, 0xFF00FF00),   // opaque green
            new Feature(0,  20, 12, 12, 0x402050D0),   // 25% blue
            new Feature(20, 20, 12, 12, 0xC0E0C020),   // 75% yellow
            new Feature(2,  10, 4,  10, 0xFFFF00FF),   // magenta LEFT-ONLY bar (opaque)
            new Feature(10, 2,  10, 4,  0x4000FFFF),   // 25% cyan TOP-ONLY bar
            new Feature(24, 4,  3,  3,  0xFFFFFFFF),   // white dot
        };

        public const uint AlphaBaseColor = 0xFF404040;

        // ---- named sample points, in source space (pixel centres) ----
        public static readonly (string Role, double X, double Y, uint Expect)[] Discriminators =
        {
            ("mag-left",   4.5, 15.5, 0xFFFF00FF),
            ("mag-right", 27.5, 15.5, BaseColor),
            ("cyan-top",  15.5,  4.5, 0xFF00FFFF),
            ("cyan-bot",  15.5, 27.5, BaseColor),
            ("quad-tl",    2.5,  2.5, 0xFFD02020),
            ("quad-tr",   29.5,  2.5, 0xFF20A040),
            ("quad-bl",    2.5, 29.5, 0xFF2050D0),
            ("quad-br",   29.5, 29.5, 0xFFE0C020),
            ("dot",       25.5,  5.5, 0xFFFFFFFF),
        };

        private static bool Inside(Feature f, double x, double y) =>
            x >= f.X && x < f.X + f.W && y >= f.Y && y < f.Y + f.H;

        /// <summary>Point in the purple right triangle (12,12)-(20,12)-(12,20).</summary>
        private static bool InsideTriangle(double x, double y) =>
            x >= 12 && y >= 12 && (x - 12) + (y - 12) < 8;

        /// <summary>
        /// Rasterize the pattern into a Bgra32 bitmap, sampling every pixel at its
        /// centre. Hard edges only (no AA), so the bitmap is bit-exactly reproducible.
        /// </summary>
        public static BitmapSource MakeBitmap(Feature[] rects, uint baseColor, bool triangle)
        {
            int n = (int)Size;
            var px = new byte[n * n * 4];

            for (int y = 0; y < n; y++)
            {
                for (int x = 0; x < n; x++)
                {
                    double cx = x + 0.5, cy = y + 0.5;
                    uint c = baseColor;
                    foreach (Feature f in rects)
                        if (Inside(f, cx, cy)) c = f.Argb;
                    if (triangle && InsideTriangle(cx, cy)) c = TriangleColor;

                    int o = (y * n + x) * 4;
                    px[o + 0] = (byte)(c & 0xFF);          // B
                    px[o + 1] = (byte)((c >> 8) & 0xFF);   // G
                    px[o + 2] = (byte)((c >> 16) & 0xFF);  // R
                    px[o + 3] = (byte)((c >> 24) & 0xFF);  // A
                }
            }

            var bmp = BitmapSource.Create(n, n, 96, 96, PixelFormats.Bgra32, null, px, n * 4);
            bmp.Freeze();
            return bmp;
        }

        public static BitmapSource ImageSource() => MakeBitmap(Rects, BaseColor, triangle: true);

        public static BitmapSource AlphaImageSource() => MakeBitmap(AlphaRects, AlphaBaseColor, triangle: true);

        /// <summary>Vector twin of the bitmap pattern (same geometry, same order).</summary>
        public static Drawing MakeDrawing(Feature[] rects, uint baseColor, bool triangle)
        {
            var group = new DrawingGroup();
            using (DrawingContext dc = group.Open())
            {
                dc.DrawRectangle(Brush(baseColor), null, new Rect(0, 0, Size, Size));
                foreach (Feature f in rects)
                    dc.DrawRectangle(Brush(f.Argb), null, new Rect(f.X, f.Y, f.W, f.H));
                if (triangle)
                {
                    var geo = new StreamGeometry();
                    using (StreamGeometryContext g = geo.Open())
                    {
                        g.BeginFigure(new Point(12, 12), true, true);
                        g.LineTo(new Point(20, 12), true, false);
                        g.LineTo(new Point(12, 20), true, false);
                    }
                    geo.Freeze();
                    dc.DrawGeometry(Brush(TriangleColor), null, geo);
                }
            }
            group.Freeze();
            return group;
        }

        /// <summary>
        /// Asymmetric Visual source for VisualBrush: same pattern plus a TextBlock,
        /// because glyphs expose flips/scaling in a way flat rects cannot.
        /// </summary>
        public static Visual MakeVisual(string textFormattingMode = null)
        {
            var canvas = new Canvas
            {
                Width = Size,
                Height = Size,
                Background = Brush(BaseColor),
            };

            foreach (Feature f in Rects)
            {
                if (f.Argb == 0xFFFFFFFF) continue;   // the dot is replaced by text
                var r = new Rectangle { Width = f.W, Height = f.H, Fill = Brush(f.Argb) };
                Canvas.SetLeft(r, f.X);
                Canvas.SetTop(r, f.Y);
                canvas.Children.Add(r);
            }

            var text = new TextBlock
            {
                Text = "F7",
                FontFamily = new FontFamily("Segoe UI"),
                FontSize = 11,
                FontWeight = FontWeights.Bold,
                Foreground = new SolidColorBrush(Color.FromArgb(0xFF, 0xFF, 0xFF, 0xFF)),
            };
            if (textFormattingMode == "Display")
                TextOptions.SetTextFormattingMode(text, TextFormattingMode.Display);
            else if (textFormattingMode == "Ideal")
                TextOptions.SetTextFormattingMode(text, TextFormattingMode.Ideal);

            Canvas.SetLeft(text, 11.5);
            Canvas.SetTop(text, 11.5);
            canvas.Children.Add(text);

            canvas.Measure(new Size(Size, Size));
            canvas.Arrange(new Rect(0, 0, Size, Size));
            canvas.UpdateLayout();
            return canvas;
        }

        private static SolidColorBrush Brush(uint argb)
        {
            var b = new SolidColorBrush(Color.FromArgb(
                (byte)(argb >> 24), (byte)((argb >> 16) & 0xFF),
                (byte)((argb >> 8) & 0xFF), (byte)(argb & 0xFF)));
            b.Freeze();
            return b;
        }

        public static string Hex(uint argb) => "#" + argb.ToString("X8");
    }
}

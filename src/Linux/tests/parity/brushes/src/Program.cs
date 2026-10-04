using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Rectangle = System.Windows.Shapes.Rectangle;

namespace U1BrushOracle
{
    /// <summary>
    /// TileBrush oracle: renders asymmetric tile sources through every TileBrush knob on
    /// real WPF (RenderTargetBitmap, 96 DPI, session-0 safe) and dumps, per case:
    ///   - a PNG (Bgra32 straight alpha)
    ///   - a 24x16 sampling grid over the target plus corners, tile boundaries and
    ///     named flip-discriminator pixels, all as #AARRGGBB
    ///   - layout metadata (ActualWidth/Height, rendered bounds, tile geometry, DPI)
    ///   - anti-false-green check results
    ///
    /// Anti-false-green discipline (the point of this tool):
    ///   1. every PNG must not be a flat colour (distinct sampled colours >= 3)
    ///   2. the target area must actually be painted
    ///   3. cases that differ in NOTHING but TileMode must differ pairwise at the sampled
    ///      pixels for a tiling viewport - if two modes are pixel-identical the case has
    ///      NO discriminating power and the tool exits non-zero instead of shipping it
    ///   4. when the viewport covers the whole target (single tile) the same cases MUST be
    ///      identical over the interior - an asserted WPF fact, not a silent no-op
    ///   5. --sabotage renders every Flip* case as Tile to prove check (3) can go red
    /// </summary>
    internal static class Program
    {
        private const string Format = "wpf-linux-u1a-brushes/1";

        [STAThread]
        private static int Main(string[] args)
        {
            string outDir = @"C:\wpf-oracle-brush\out";
            bool sabotage = false;
            int batch = 1;
            foreach (string a in args)
            {
                if (a == "--sabotage") sabotage = true;
                else if (a == "--batch2") batch = 2;
                else if (!a.StartsWith("--")) outDir = a;
            }

            Directory.CreateDirectory(outDir);
            Console.WriteLine($"U1BrushOracle: outDir={outDir} sabotage={sabotage} batch={batch}");

            List<CaseDef> cases = batch == 2 ? Cases.BuildBatch2() : Cases.BuildBatch1();
            var rendered = new List<RenderedCase>();
            var failures = new List<string>();

            foreach (CaseDef def in cases)
            {
                RenderedCase rc = RenderCase(def, outDir, sabotage);
                rendered.Add(rc);
                string flag = rc.CheckFailures.Count == 0 ? "ok  " : "FAIL";
                Console.WriteLine($"  [{flag}] {rc.Def.Id,-46} colors={rc.DistinctColors,4} painted={rc.PaintedSamples,5} " +
                                  $"model={rc.ModelMatched}/{rc.ModelChecked} vpOrigin={rc.Winner.Name}");
                foreach (string f in rc.CheckFailures) failures.Add(f);
            }

            // ---------- pairwise discrimination between TileModes ----------
            var discrimination = new List<JObj>();
            foreach (var group in GroupByEverythingButTileMode(rendered))
            {
                if (group.Count < 2) continue;

                // A viewport that covers the whole target produces exactly one tile, so no flip
                // is observable in the interior. (The outermost pixels DO differ: bilinear
                // sampling at the image edge reaches into the neighbouring tile, and under Flip*
                // that neighbour is mirrored - recorded, not asserted.)
                bool singleTile = group[0].Def.ViewportName == "v1same";
                string groupName = GroupLabel(group[0].Def);

                for (int a = 0; a < group.Count; a++)
                {
                    for (int b = a + 1; b < group.Count; b++)
                    {
                        RenderedCase ca = group[a], cb = group[b];
                        int diffAnywhere = CountDifferingSamples(ca, cb, s => true);
                        bool mustDiffer = !singleTile;
                        int diff = mustDiffer
                            ? diffAnywhere
                            : CountDifferingSamples(ca, cb, s => s.Role == "grid" && InteriorOf(ca.Def, s));

                        bool ok = mustDiffer ? diff > 0 : diff == 0;

                        discrimination.Add(J.O()
                            .Add("group", groupName)
                            .Add("a", ca.Def.TileMode)
                            .Add("b", cb.Def.TileMode)
                            .Add("differingSamples", diff)
                            .Add("differingSamplesAnywhere", diffAnywhere)
                            .Add("totalSamples", Math.Min(ca.Samples.Count, cb.Samples.Count))
                            .Add("comparedSamples", mustDiffer ? "all sampled pixels" : "grid pixels >=8px inside the target")
                            .Add("expectation", mustDiffer ? "must-differ" : "must-be-identical-over-interior(single tile)")
                            .Add("ok", ok));

                        if (!ok)
                        {
                            failures.Add(mustDiffer
                                ? $"NO DISCRIMINATION: {groupName} {ca.Def.TileMode} vs {cb.Def.TileMode} are pixel-identical " +
                                  $"at all {ca.Samples.Count} samples - this case cannot tell them apart"
                                : $"UNEXPECTED INTERIOR DIFFERENCE: {groupName} {ca.Def.TileMode} vs {cb.Def.TileMode} differ at {diff} " +
                                  "interior grid samples although the viewport covers the whole target (single tile)");
                        }
                    }
                }
            }

            // ---------- batch 2: cross-variant comparisons (RECORDED, not asserted) ----------
            // For these families the interesting axis is not TileMode, so the pairwise
            // TileMode machinery above produces no pairs. Whether e.g. BitmapScalingMode
            // changes a single pixel is a RESULT, not an expectation - a "all three modes
            // are identical" answer is just as reportable as a difference.
            var variantComparisons = new List<JObj>();
            foreach (var grp in GroupByVariantAxis(rendered))
            {
                for (int a = 0; a < grp.Count; a++)
                {
                    for (int b = a + 1; b < grp.Count; b++)
                    {
                        int diff = CountDifferingSamples(grp[a], grp[b], x => true);
                        variantComparisons.Add(J.O()
                            .Add("family", grp[a].Def.Family)
                            .Add("axis", VariantAxis(grp[a].Def))
                            .Add("a", grp[a].Def.Id)
                            .Add("b", grp[b].Def.Id)
                            .Add("differingSamples", diff)
                            .Add("totalSamples", Math.Min(grp[a].Samples.Count, grp[b].Samples.Count))
                            .Add("verdict", diff == 0
                                ? "IDENTICAL at every sampled pixel"
                                : "differs at " + diff + " sampled pixel(s)"));
                    }
                }
            }

            foreach (JObj cmp in variantComparisons)
            {
                foreach (KeyValuePair<string, object> kv in cmp.Items)
                {
                    if (kv.Key != "differingSamples" || (int)kv.Value == 0) continue;
                    Console.WriteLine($"  cmp {cmp.Items[2].Value} vs {cmp.Items[3].Value}: " +
                                      $"{cmp.Items[4].Value} sample(s) differ");
                    break;
                }
            }

            // ---------- comparator self-test ----------
            // The comparator must report "identical" for a case compared with itself,
            // otherwise a green discrimination result would mean nothing.
            RenderedCase probe = rendered[0];
            int selfDiff = CountDifferingSamples(probe, probe, x => true);
            bool selfTestOk = selfDiff == 0;
            if (!selfTestOk) failures.Add("comparator self-test failed: a case differs from itself");

            // ---------- write outputs ----------
            string caseFile = batch == 2 ? "cases-2.json" : "cases.json";
            string resultFile = batch == 2 ? "windows-results-2.json" : "windows-results.json";
            File.WriteAllText(Path.Combine(outDir, caseFile), BuildCasesJson(cases), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, resultFile),
                BuildResultsJson(rendered, discrimination, variantComparisons, sabotage, selfTestOk, failures),
                new UTF8Encoding(false));

            Console.WriteLine();
            Console.WriteLine($"cases={rendered.Count} failures={failures.Count} sabotage={sabotage} selfTest={(selfTestOk ? "ok" : "FAIL")}");
            foreach (string f in failures) Console.WriteLine("  ! " + f);

            return failures.Count == 0 ? 0 : 2;
        }

        // ==================================================================
        //  Rendering
        // ==================================================================

        private static RenderedCase RenderCase(CaseDef def, string outDir, bool sabotage)
        {
            Brush brush = BuildBrush(def, sabotage, out bool sabotaged);

            double scale = def.Scale;
            double canvasDiu = Cases.CanvasSize / scale;      // constant DEVICE size across DPI
            double[] targetDev = { def.Target[0] * scale, def.Target[1] * scale,
                                   def.Target[2] * scale, def.Target[3] * scale };

            var canvas = new Canvas
            {
                Width = canvasDiu,
                Height = canvasDiu,
                Background = def.OpaqueBackground
                    ? new SolidColorBrush(Color.FromArgb(0xFF, 0x80, 0x80, 0x80))
                    : Brushes.Transparent,
            };

            var rect = new Rectangle
            {
                Width = def.Target[2],
                Height = def.Target[3],
                Fill = brush,
            };
            Canvas.SetLeft(rect, def.Target[0]);
            Canvas.SetTop(rect, def.Target[1]);
            canvas.Children.Add(rect);

            if (def.BitmapScalingMode != null)
                RenderOptions.SetBitmapScalingMode(rect, ParseScalingMode(def.BitmapScalingMode));

            canvas.Measure(new Size(canvasDiu, canvasDiu));
            canvas.Arrange(new Rect(0, 0, canvasDiu, canvasDiu));
            canvas.UpdateLayout();

            int w = (int)Cases.CanvasSize, h = (int)Cases.CanvasSize;
            var rtb = new RenderTargetBitmap(w, h, def.Dpi, def.Dpi, PixelFormats.Pbgra32);
            rtb.Render(canvas);

            var straight = new FormatConvertedBitmap(rtb, PixelFormats.Bgra32, null, 0);
            var pixels = new byte[w * h * 4];
            straight.CopyPixels(pixels, w * 4, 0);

            string pngName = def.Id + ".png";
            string pngPath = Path.Combine(outDir, pngName);
            var encoder = new PngBitmapEncoder();
            encoder.Frames.Add(BitmapFrame.Create(straight));
            using (FileStream fs = File.Create(pngPath)) encoder.Save(fs);

            var rc = new RenderedCase
            {
                Def = def,
                Sabotaged = sabotaged,
                Pixels = pixels,
                Width = w,
                Height = h,
                DpiX = rtb.DpiX,
                DpiY = rtb.DpiY,
                DpiScaleFactor = scale,
                DeviceTarget = targetDev,
                PngFile = pngName,
                PngBytes = new FileInfo(pngPath).Length,
                PngSha256 = Sha256File(pngPath),
                PixelFormat = "Bgra32 (straight alpha) PNG; RenderTargetBitmap rendered as Pbgra32",
                ActualWidth = rect.ActualWidth,
                ActualHeight = rect.ActualHeight,
                RenderedBounds = RenderedBounds(canvas, rect),
                DpiScale = VisualTreeHelper.GetDpi(canvas).PixelsPerDip,
                TextFormattingMode = TextOptions.GetTextFormattingMode(canvas).ToString(),
                BitmapScalingMode = RenderOptions.GetBitmapScalingMode(rect).ToString(),
                FontFamilyInVisual = def.Source == "visual" ? "Segoe UI" : null,
                TileBrushKnobsApplied = brush is TileBrush,
                BrushTypeUsed = brush.GetType().Name,
            };

            // ---- tile-geometry hypotheses (Absolute viewport: canvas space vs rect-local) ----
            // Sample the pixels FIRST: the hypothesis score compares model against actual,
            // so an unscored (null) sample value would silently report zero matches.
            rc.Hypotheses = BuildHypotheses(def, targetDev);
            List<Sample> samples = BaseSamples(def, targetDev);
            foreach (Sample s in samples) s.Hex = HexAt(pixels, w, s.X, s.Y);
            foreach (Hypothesis hyp in rc.Hypotheses) ScoreHypothesis(def, hyp, samples);

            if (rc.Hypotheses.Count > 1)
            {
                int rateA = rc.Hypotheses[0].Checked == 0 ? -1
                    : rc.Hypotheses[0].Matched * 1000 / rc.Hypotheses[0].Checked;
                int rateB = rc.Hypotheses[1].Checked == 0 ? -1
                    : rc.Hypotheses[1].Matched * 1000 / rc.Hypotheses[1].Checked;
                rc.Winner = rateB > rateA ? rc.Hypotheses[1] : rc.Hypotheses[0];
            }
            else
            {
                rc.Winner = rc.Hypotheses[0];
            }

            List<Sample> extra = TileSamples(def, rc.Winner.Geom, targetDev);
            foreach (Sample s in extra) s.Hex = HexAt(pixels, w, s.X, s.Y);
            samples.AddRange(extra);

            rc.Tile = rc.Winner.Geom;
            rc.Samples = samples;
            foreach (Sample s in samples) Predict(def, rc.Winner, s);

            FinishChecks(rc);
            return rc;
        }

        private static Brush BuildBrush(CaseDef def, bool sabotage, out bool sabotaged)
        {
            sabotaged = false;
            Brush brush;

            switch (def.Source)
            {
                case "image":
                    brush = new ImageBrush(Pattern.ImageSource());
                    break;
                case "alphaImage":
                    brush = new ImageBrush(Pattern.AlphaImageSource());
                    break;
                case "drawing":
                    brush = new DrawingBrush(Pattern.MakeDrawing(Pattern.Rects, Pattern.BaseColor, true));
                    break;
                case "visual":
                    brush = new VisualBrush(Pattern.MakeVisual(def.TextFormattingMode));
                    break;
                default:
                    throw new Exception("unknown source " + def.Source);
            }

            if (def.BitmapCacheMode != null)
            {
                // BitmapCacheBrush can only be built around a real Visual, so it is created
                // here instead of in the switch above.
                Visual v = Pattern.MakeVisual(def.TextFormattingMode);
                var cacheBrush = new BitmapCacheBrush(v);
                if (def.BitmapCacheMode == "default") cacheBrush.BitmapCache = new BitmapCache();
                else if (def.BitmapCacheMode == "scale2")
                    cacheBrush.BitmapCache = new BitmapCache { RenderAtScale = 2.0 };
                brush = cacheBrush;
            }

            TileMode mode = ParseTileMode(def.TileMode);
            if (sabotage && mode != TileMode.Tile && mode != TileMode.None)
            {
                mode = TileMode.Tile;      // deliberate break: declared != rendered
                sabotaged = true;
            }

            // BitmapCacheBrush derives from Brush, NOT from TileBrush: it has no
            // Viewport/Viewbox/Stretch/Alignment/TileMode at all. That is itself part of
            // the scope answer, so the knobs are applied only when the brush supports them.
            if (brush is TileBrush tileBrush)
            {
                tileBrush.TileMode = mode;
                tileBrush.Viewport = new Rect(def.Viewport[0], def.Viewport[1], def.Viewport[2], def.Viewport[3]);
                tileBrush.ViewportUnits = ParseUnits(def.ViewportUnits);
                tileBrush.Viewbox = new Rect(def.Viewbox[0], def.Viewbox[1], def.Viewbox[2], def.Viewbox[3]);
                tileBrush.ViewboxUnits = ParseUnits(def.ViewboxUnits);
                tileBrush.Stretch = ParseStretch(def.Stretch);
                tileBrush.AlignmentX = ParseAlignX(def.AlignX);
                tileBrush.AlignmentY = ParseAlignY(def.AlignY);
            }
            return brush;
        }

        private static TileMode ParseTileMode(string s) => s switch
        {
            "None" => TileMode.None,
            "Tile" => TileMode.Tile,
            "FlipX" => TileMode.FlipX,
            "FlipY" => TileMode.FlipY,
            "FlipXY" => TileMode.FlipXY,
            _ => throw new Exception("bad tile mode " + s),
        };

        private static BitmapScalingMode ParseScalingMode(string s) => s switch
        {
            "NearestNeighbor" => BitmapScalingMode.NearestNeighbor,
            "Linear" => BitmapScalingMode.Linear,
            "HighQuality" => BitmapScalingMode.HighQuality,
            "LowQuality" => BitmapScalingMode.LowQuality,
            "Fant" => BitmapScalingMode.Fant,
            _ => BitmapScalingMode.Unspecified,
        };

        private static BrushMappingMode ParseUnits(string s) => s switch
        {
            "Absolute" => BrushMappingMode.Absolute,
            "RelativeToBoundingBox" => BrushMappingMode.RelativeToBoundingBox,
            _ => throw new Exception("bad units " + s),
        };

        private static Stretch ParseStretch(string s) => s switch
        {
            "None" => Stretch.None,
            "Fill" => Stretch.Fill,
            "Uniform" => Stretch.Uniform,
            "UniformToFill" => Stretch.UniformToFill,
            _ => throw new Exception("bad stretch " + s),
        };

        private static AlignmentX ParseAlignX(string s) => s switch
        {
            "Left" => AlignmentX.Left,
            "Center" => AlignmentX.Center,
            "Right" => AlignmentX.Right,
            _ => throw new Exception("bad alignX " + s),
        };

        private static AlignmentY ParseAlignY(string s) => s switch
        {
            "Top" => AlignmentY.Top,
            "Center" => AlignmentY.Center,
            "Bottom" => AlignmentY.Bottom,
            _ => throw new Exception("bad alignY " + s),
        };

        // ==================================================================
        //  Tile geometry
        // ==================================================================

        internal sealed class TileGeom
        {
            public double OriginX, OriginY, TileW, TileH;   // device space, base tile
            public int IndexLeft, IndexRight, IndexTop, IndexBottom;
            public bool Known;                              // false when Stretch != Fill
        }

        internal sealed class Hypothesis
        {
            public string Name;
            public TileGeom Geom;
            public int Checked, Matched;
        }

        private static List<Hypothesis> BuildHypotheses(CaseDef def, double[] deviceTarget)
        {
            var list = new List<Hypothesis>
            {
                new Hypothesis
                {
                    Name = def.ViewportUnits == "RelativeToBoundingBox"
                        ? "relative-to-bounding-box"
                        : "absolute-canvas-origin",
                    Geom = TileGeometry(def, deviceTarget, rectLocalOrigin: false),
                },
            };

            if (def.ViewportUnits == "Absolute")
            {
                list.Add(new Hypothesis
                {
                    Name = "absolute-rect-local-origin",
                    Geom = TileGeometry(def, deviceTarget, rectLocalOrigin: true),
                });
            }
            return list;
        }

        /// <summary>
        /// Base-tile rectangle in device space, for Stretch=Fill (the only case here where the
        /// tile is simply the mapped viewport). For an absolute Viewport the coordinate origin
        /// is ambiguous in the documentation, so both readings are generated and the pixels
        /// decide which one holds.
        /// </summary>
        private static TileGeom TileGeometry(CaseDef def, double[] deviceTarget, bool rectLocalOrigin)
        {
            var g = new TileGeom();
            // Fill and None both map the viewport to a device tile; they differ only in how the
            // content is placed INSIDE that tile. Uniform/UniformToFill letterbox the tile, so
            // the tile is not simply the mapped viewport and the model opts out there.
            if (def.Stretch != "Fill" && def.Stretch != "None") return g;

            double L = deviceTarget[0], T = deviceTarget[1], W = deviceTarget[2], H = deviceTarget[3];
            double vx, vy, vw, vh;

            if (def.ViewportUnits == "RelativeToBoundingBox")
            {
                vx = L + def.Viewport[0] * W;
                vy = T + def.Viewport[1] * H;
                vw = def.Viewport[2] * W;
                vh = def.Viewport[3] * H;
            }
            else if (rectLocalOrigin)
            {
                vx = L + def.Viewport[0] * def.Scale;
                vy = T + def.Viewport[1] * def.Scale;
                vw = def.Viewport[2] * def.Scale;
                vh = def.Viewport[3] * def.Scale;
            }
            else
            {
                vx = def.Viewport[0] * def.Scale;
                vy = def.Viewport[1] * def.Scale;
                vw = def.Viewport[2] * def.Scale;
                vh = def.Viewport[3] * def.Scale;
            }

            if (vw <= 0 || vh <= 0) return g;

            g.OriginX = vx; g.OriginY = vy; g.TileW = vw; g.TileH = vh;
            g.IndexLeft = (int)Math.Floor((L - vx) / vw);
            g.IndexRight = (int)Math.Floor((L + W - 1e-9 - vx) / vw);
            g.IndexTop = (int)Math.Floor((T - vy) / vh);
            g.IndexBottom = (int)Math.Floor((T + H - 1e-9 - vy) / vh);
            g.Known = true;
            return g;
        }

        // ==================================================================
        //  Sampling
        // ==================================================================

        internal sealed class Sample
        {
            public int X, Y;
            public string Role;
            public string Note;
            public string Hex;
            public string ModelHex;
            public bool ModelUsable;
        }

        /// <summary>Grid + corners: independent of the tile-geometry hypothesis.</summary>
        private static List<Sample> BaseSamples(CaseDef def, double[] deviceTarget)
        {
            var list = new List<Sample>();
            double L = deviceTarget[0], T = deviceTarget[1], W = deviceTarget[2], H = deviceTarget[3];

            for (int j = 0; j < 16; j++)
            {
                for (int i = 0; i < 24; i++)
                {
                    int x = (int)Math.Round(L + (i + 0.5) * W / 24.0);
                    int y = (int)Math.Round(T + (j + 0.5) * H / 16.0);
                    list.Add(new Sample { X = Clamp(x, 0, 255), Y = Clamp(y, 0, 255), Role = "grid", Note = $"g{i},{j}" });
                }
            }

            int x0 = (int)Math.Round(L) + 1, x1 = (int)Math.Round(L + W) - 2;
            int y0 = (int)Math.Round(T) + 1, y1 = (int)Math.Round(T + H) - 2;
            list.Add(new Sample { X = x0, Y = y0, Role = "corner", Note = "tl" });
            list.Add(new Sample { X = x1, Y = y0, Role = "corner", Note = "tr" });
            list.Add(new Sample { X = x0, Y = y1, Role = "corner", Note = "bl" });
            list.Add(new Sample { X = x1, Y = y1, Role = "corner", Note = "br" });
            return list;
        }

        /// <summary>Tile boundaries + named flip discriminators (need the tile geometry).</summary>
        private static List<Sample> TileSamples(CaseDef def, TileGeom g, double[] deviceTarget)
        {
            var list = new List<Sample>();
            if (!g.Known) return list;

            for (int k = g.IndexLeft + 1; k <= g.IndexRight; k++)
            {
                double bx = g.OriginX + k * g.TileW;
                int yi = (int)Math.Round(deviceTarget[1] + deviceTarget[3] / 2);
                foreach (int d in new[] { -2, -1, 0, 1, 2 })
                    AddInside(list, def, bx + d, yi, "tile-boundary-x", $"k={k} dx={d}");
            }
            for (int k = g.IndexTop + 1; k <= g.IndexBottom; k++)
            {
                double by = g.OriginY + k * g.TileH;
                int xi = (int)Math.Round(deviceTarget[0] + deviceTarget[2] / 2);
                foreach (int d in new[] { -2, -1, 0, 1, 2 })
                    AddInside(list, def, xi, by + d, "tile-boundary-y", $"k={k} dy={d}");
            }

            // Named discriminators: the base tile (index 0) is never flipped, so the flip is
            // read from tile index 1 (every tiling viewport here produces at least tile 1).
            foreach (var (role, sx, sy, expect) in Pattern.Discriminators)
            {
                for (int ti = 0; ti <= 1; ti++)
                {
                    for (int tj = 0; tj <= 1; tj++)
                    {
                        double dx = g.OriginX + ti * g.TileW + (sx / Pattern.Size) * g.TileW;
                        double dy = g.OriginY + tj * g.TileH + (sy / Pattern.Size) * g.TileH;
                        AddInside(list, def, dx, dy, "discriminator",
                            $"{role}|tile({ti},{tj})|unflipped={Pattern.Hex(expect)}");
                    }
                }
            }
            return list;
        }

        private static void AddInside(List<Sample> list, CaseDef def, double dx, double dy, string role, string note)
        {
            int x = (int)Math.Floor(dx + 0.5), y = (int)Math.Floor(dy + 0.5);
            double s = def.Scale;
            double L = def.Target[0] * s, T = def.Target[1] * s;
            if (x < L || y < T || x >= L + def.Target[2] * s || y >= T + def.Target[3] * s) return;
            if (x < 0 || y < 0 || x > 255 || y > 255) return;
            list.Add(new Sample { X = x, Y = y, Role = role, Note = note });
        }

        // ==================================================================
        //  Independent model of WPF tile semantics
        // ==================================================================

        /// <summary>
        /// Maps a device pixel back to source space using the documented TileBrush model:
        /// tile index = floor((p - viewportOrigin) / tileSize); under FlipX/FlipY odd tile
        /// indices are mirrored; the base tile is never flipped; TileMode.None paints only
        /// the base tile. Returns false when the pixel lies outside the painted base tile.
        /// </summary>
        private static bool TryMapToSource(CaseDef def, TileGeom g, int px, int py,
                                           out double sx, out double sy)
        {
            sx = sy = 0;
            if (!g.Known) return false;

            double u = (px + 0.5 - g.OriginX) / g.TileW;
            double v = (py + 0.5 - g.OriginY) / g.TileH;
            int i = (int)Math.Floor(u), j = (int)Math.Floor(v);

            if (def.TileMode == "None" && (i != 0 || j != 0)) return false;

            double fu = u - i, fv = v - j;
            bool flipX = (def.TileMode == "FlipX" || def.TileMode == "FlipXY") && (i % 2 != 0);
            bool flipY = (def.TileMode == "FlipY" || def.TileMode == "FlipXY") && (j % 2 != 0);
            if (flipX) fu = 1.0 - fu;
            if (flipY) fv = 1.0 - fv;

            sx = fu * Pattern.Size;
            sy = fv * Pattern.Size;
            return true;
        }

        /// <summary>Predicted #AARRGGBB for a pixel under one hypothesis; false = no prediction.</summary>
        private static bool Predicted(CaseDef def, Hypothesis hyp, int px, int py,
                                      out string hex, out bool usable)
        {
            hex = null;
            usable = false;
            if (!hyp.Geom.Known) return false;
            if (def.Source == "alphaImage") return false;   // composites over the background
            if (!FullSourceViewbox(def)) return false;      // sub-viewbox changes the scale

            if (def.Stretch == "None")
                return PredictedStretchNone(def, hyp.Geom, px, py, out hex, out usable);

            if (!TryMapToSource(def, hyp.Geom, px, py, out double sx, out double sy))
            {
                // TileMode.None outside the base tile -> the canvas background shows through
                hex = def.OpaqueBackground ? "#FF808080" : "#00000000";
                usable = true;
                return true;
            }

            // Stay >=1.5 texels away from the source bitmap edge: bilinear reconstruction at the
            // image edge blends with the neighbouring tile, and under Flip* that neighbour is
            // mirrored, so those pixels are not described by a source-space model.
            if (sx < 1.5 || sx > Pattern.Size - 1.5 || sy < 1.5 || sy > Pattern.Size - 1.5)
                return false;

            uint c = SourcePixel(def, sx, sy);
            if (c == UnknownColor) return false;

            for (int dy = -1; dy <= 1; dy++)
            {
                for (int dx = -1; dx <= 1; dx++)
                {
                    uint n = SourcePixel(def, sx + dx, sy + dy);
                    if (n != c) return false;      // near a feature edge: AA / filtering
                }
            }

            hex = Pattern.Hex(c);
            usable = true;
            return true;
        }

        /// <summary>True when the Viewbox selects the whole 32x32 source (model precondition).</summary>
        private static bool FullSourceViewbox(CaseDef def)
        {
            double[] v = def.Viewbox;
            return def.ViewboxUnits == "Absolute"
                ? Math.Abs(v[0]) < 1e-9 && Math.Abs(v[1]) < 1e-9 &&
                  Math.Abs(v[2] - Pattern.Size) < 1e-9 && Math.Abs(v[3] - Pattern.Size) < 1e-9
                : Math.Abs(v[0]) < 1e-9 && Math.Abs(v[1]) < 1e-9 &&
                  Math.Abs(v[2] - 1.0) < 1e-9 && Math.Abs(v[3] - 1.0) < 1e-9;
        }

        /// <summary>
        /// Stretch=None model: the source is NOT scaled, a 32x32 (96 DPI) source is placed
        /// at its natural size inside the tile according to AlignmentX/Y, and everything
        /// else in the tile is empty. A flip mirrors the WHOLE tile - placement included -
        /// which is exactly the open question this family exists to answer.
        /// </summary>
        private static bool PredictedStretchNone(CaseDef def, TileGeom g, int px, int py,
                                                 out string hex, out bool usable)
        {
            hex = null;
            usable = false;
            if (!g.Known) return false;

            double u = (px + 0.5 - g.OriginX) / g.TileW;
            double v = (py + 0.5 - g.OriginY) / g.TileH;
            int i = (int)Math.Floor(u), j = (int)Math.Floor(v);
            if (def.TileMode == "None" && (i != 0 || j != 0)) return false;

            double fu = u - i, fv = v - j;
            bool flipX = (def.TileMode == "FlipX" || def.TileMode == "FlipXY") && (i % 2 != 0);
            bool flipY = (def.TileMode == "FlipY" || def.TileMode == "FlipXY") && (j % 2 != 0);
            if (flipX) fu = 1.0 - fu;
            if (flipY) fv = 1.0 - fv;

            // position within the (possibly mirrored) tile, in device pixels
            double xInTile = fu * g.TileW;
            double yInTile = fv * g.TileH;

            // the source bitmap is 96 DPI, so its 32 source pixels occupy 32*scale device px
            double imgW = Pattern.Size * def.Scale;
            double imgH = Pattern.Size * def.Scale;
            double ox = AlignOffset(g.TileW, imgW, def.AlignX);
            double oy = AlignOffset(g.TileH, imgH, def.AlignY);

            double sx = (xInTile - ox) / def.Scale;      // source-space coordinate
            double sy = (yInTile - oy) / def.Scale;

            if (sx < 0 || sy < 0 || sx >= Pattern.Size || sy >= Pattern.Size)
            {
                hex = def.OpaqueBackground ? "#FF808080" : "#00000000";
                usable = true;
                return true;
            }
            return PredictFromSource(def, sx, sy, out hex, out usable);
        }

        private static double AlignOffset(double tile, double content, string align) => align switch
        {
            "Left" or "Top" => 0.0,
            "Right" or "Bottom" => tile - content,
            _ => (tile - content) / 2.0,
        };

        /// <summary>Source-space lookup with edge/filter safety, shared by both models.</summary>
        private static bool PredictFromSource(CaseDef def, double sx, double sy, out string hex, out bool usable)
        {
            hex = null;
            usable = false;
            if (sx < 1.5 || sx > Pattern.Size - 1.5 || sy < 1.5 || sy > Pattern.Size - 1.5)
                return false;

            uint c = SourcePixel(def, sx, sy);
            if (c == UnknownColor) return false;

            for (int dy = -1; dy <= 1; dy++)
            {
                for (int dx = -1; dx <= 1; dx++)
                {
                    if (SourcePixel(def, sx + dx, sy + dy) != c) return false;
                }
            }

            hex = Pattern.Hex(c);
            usable = true;
            return true;
        }

        private static void ScoreHypothesis(CaseDef def, Hypothesis hyp, List<Sample> samples)
        {
            foreach (Sample s in samples)
            {
                if (!Predicted(def, hyp, s.X, s.Y, out string hex, out bool usable) || !usable) continue;
                hyp.Checked++;
                if (hex == s.Hex) hyp.Matched++;
            }
        }

        private static void Predict(CaseDef def, Hypothesis hyp, Sample s)
        {
            if (Predicted(def, hyp, s.X, s.Y, out string hex, out bool usable))
            {
                s.ModelHex = hex;
                s.ModelUsable = usable;
            }
        }

        private const uint UnknownColor = 0xDEADBEEF;

        /// <summary>Colour of the source at a continuous source-space point (pixel centres).</summary>
        private static uint SourcePixel(CaseDef def, double sx, double sy)
        {
            int px = Clamp((int)Math.Floor(sx), 0, (int)Pattern.Size - 1);
            int py = Clamp((int)Math.Floor(sy), 0, (int)Pattern.Size - 1);
            double cx = px + 0.5, cy = py + 0.5;

            if (def.Source == "visual")
            {
                // the VisualBrush source replaces the white dot with a TextBlock: both are
                // unknowns to a source-space colour model
                if (cx >= 11 && cx < 26 && cy >= 11 && cy < 26) return UnknownColor;   // "F7" text
                if (cx >= 24 && cx < 27 && cy >= 4 && cy < 7) return UnknownColor;     // dot -> text
            }

            uint c = Pattern.BaseColor;
            foreach (Pattern.Feature f in Pattern.Rects)
                if (cx >= f.X && cx < f.X + f.W && cy >= f.Y && cy < f.Y + f.H) c = f.Argb;
            if (def.Source != "visual" && cx >= 12 && cy >= 12 && (cx - 12) + (cy - 12) < 8)
                c = Pattern.TriangleColor;
            return c;
        }

        // ==================================================================
        //  Per-case checks
        // ==================================================================

        private static void FinishChecks(RenderedCase rc)
        {
            var seen = new HashSet<uint>();
            foreach (Sample s in rc.Samples) seen.Add(ParseHex(s.Hex));
            rc.DistinctColors = seen.Count;

            // >=3 distinct sampled colours: enough to rule out a flat image while still
            // allowing cases that legitimately show a small uniform sub-region (e.g. a
            // Viewbox zoomed into one quadrant of the source).
            if (rc.DistinctColors < 3)
                rc.CheckFailures.Add($"{rc.Def.Id}: PNG has only {rc.DistinctColors} distinct sampled colours (<3) - flat image?");

            uint bg = rc.Def.OpaqueBackground ? 0xFF808080u : 0x00000000u;
            rc.PaintedSamples = 0;
            foreach (Sample s in rc.Samples)
            {
                uint c = ParseHex(s.Hex);
                if (rc.Def.OpaqueBackground ? c != bg : (c >> 24) != 0) rc.PaintedSamples++;
            }
            if (rc.PaintedSamples < 10)
                rc.CheckFailures.Add($"{rc.Def.Id}: target looks unpainted ({rc.PaintedSamples} painted samples)");

            foreach (Sample s in rc.Samples)
            {
                if (!s.ModelUsable || s.ModelHex == null) continue;
                rc.ModelChecked++;
                if (s.ModelHex == s.Hex) rc.ModelMatched++;
                else if (rc.ModelMismatches.Count < 8)
                    rc.ModelMismatches.Add($"{s.Role}/{s.Note} ({s.X},{s.Y}) model={s.ModelHex} actual={s.Hex}");
            }

            if ((rc.Def.Family == "core" || rc.Def.Family == "gap") && rc.ModelChecked > 0)
            {
                double rate = (double)rc.ModelMatched / rc.ModelChecked;
                if (rate < 0.99)
                    rc.CheckFailures.Add($"{rc.Def.Id}: model agreement {rc.ModelMatched}/{rc.ModelChecked} " +
                                         $"({rate:P2}) - documented tile model does not explain WPF pixels. First: " +
                                         string.Join("; ", rc.ModelMismatches));
            }
        }

        private static int CountDifferingSamples(RenderedCase a, RenderedCase b, Func<Sample, bool> filter)
        {
            var map = new Dictionary<string, string>();
            foreach (Sample s in a.Samples)
                if (filter(s)) map[s.X + "," + s.Y] = s.Hex;

            int diff = 0;
            foreach (Sample s in b.Samples)
            {
                if (!filter(s)) continue;
                if (map.TryGetValue(s.X + "," + s.Y, out string hex) && hex != s.Hex) diff++;
            }
            return diff;
        }

        /// <summary>Grid samples at least 8px away from the target edge (no edge sampling effects).</summary>
        private static bool InteriorOf(CaseDef def, Sample s)
        {
            double L = def.Target[0], T = def.Target[1];
            return s.X >= L + 8 && s.Y >= T + 8 && s.X <= L + def.Target[2] - 8 && s.Y <= T + def.Target[3] - 8;
        }

        private static string GroupLabel(CaseDef d) =>
            $"{d.Family}|{d.Source}|{d.ViewportName}|v[{string.Join(",", d.Viewport)}]|{d.ViewportUnits}" +
            $"|stretch={d.Stretch}|align={d.AlignX}/{d.AlignY}";

        /// <summary>
        /// Groups cases differing in NOTHING but TileMode - only such a group can prove that a
        /// TileMode knob is observable. (Grouping by family/viewport alone would lump together
        /// cases that legitimately differ in Stretch/Alignment.)
        /// </summary>
        private static List<List<RenderedCase>> GroupByEverythingButTileMode(List<RenderedCase> all)
        {
            var groups = new List<List<RenderedCase>>();
            var index = new Dictionary<string, List<RenderedCase>>();
            foreach (RenderedCase rc in all)
            {
                CaseDef d = rc.Def;
                // EVERY axis except TileMode must be part of the key, otherwise a group can
                // contain cases that differ in something else (DPI, BitmapScalingMode, text
                // mode, cache mode) and the "Tile vs Tile must differ" check misfires.
                string key = string.Join("|", d.Family, d.Source, d.ViewportName,
                    string.Join(",", d.Viewport), d.ViewportUnits,
                    string.Join(",", d.Viewbox), d.ViewboxUnits,
                    d.Stretch, d.AlignX, d.AlignY,
                    string.Join(",", d.Target), d.OpaqueBackground ? "opaque" : "transparent",
                    d.Dpi.ToString(CultureInfo.InvariantCulture),
                    d.BitmapScalingMode ?? "-", d.TextFormattingMode ?? "-", d.BitmapCacheMode ?? "-");
                if (!index.TryGetValue(key, out List<RenderedCase> g))
                {
                    g = new List<RenderedCase>();
                    index[key] = g;
                    groups.Add(g);
                }
                g.Add(rc);
            }
            return groups;
        }

        // ==================================================================
        //  Metadata helpers
        // ==================================================================

        private static double[] RenderedBounds(Visual root, Visual child)
        {
            try
            {
                GeneralTransform t = child.TransformToAncestor(root);
                Rect b = t.TransformBounds(VisualTreeHelper.GetDescendantBounds(child));
                return new[] { b.X, b.Y, b.Width, b.Height };
            }
            catch (Exception)
            {
                return null;
            }
        }

        private static int Clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

        private static string HexAt(byte[] px, int w, int x, int y)
        {
            int o = (y * w + x) * 4;
            return "#" + ((uint)(px[o + 3] << 24 | px[o + 2] << 16 | px[o + 1] << 8 | px[o])).ToString("X8");
        }

        private static uint ParseHex(string hex) =>
            uint.Parse(hex.Substring(1), NumberStyles.HexNumber, CultureInfo.InvariantCulture);

        /// <summary>Whether the source-space model describes this case at all.</summary>
        internal static bool ModelApplicable(CaseDef def) =>
            (def.Stretch == "Fill" || def.Stretch == "None") &&
            def.Source != "alphaImage" && def.BitmapCacheMode == null && FullSourceViewbox(def);

        private static string Sha256File(string path)
        {
            using SHA256 sha = SHA256.Create();
            using FileStream fs = File.OpenRead(path);
            return Convert.ToHexString(sha.ComputeHash(fs)).ToLowerInvariant();
        }

        // ==================================================================
        //  JSON
        // ==================================================================

        private static string BuildCasesJson(List<CaseDef> cases)
        {
            var root = J.O()
                .Add("format", Format)
                .Add("caseCount", cases.Count)
                .Add("canvas", J.O().Add("width", (int)Cases.CanvasSize).Add("height", (int)Cases.CanvasSize)
                    .Add("dpi", (int)Cases.CanvasDpi).Add("backgroundOpaque", "#FF808080")
                    .Add("backgroundTransparent", "none (alpha cases)"))
                .Add("sourcePattern", J.O()
                    .Add("space", "32x32 continuous; rect x/y is the top-left corner, w/h are exclusive")
                    .Add("base", Pattern.Hex(Pattern.BaseColor))
                    .Add("features", FeatureList(Pattern.Rects))
                    .Add("alphaBase", Pattern.Hex(Pattern.AlphaBaseColor))
                    .Add("alphaFeatures", FeatureList(Pattern.AlphaRects))
                    .Add("triangle", "right triangle (12,12)->(20,12)->(12,20), #FF8040FF")
                    .Add("discriminators", DiscriminatorList())
                    .Add("whyAsymmetric", "Tile and FlipX are pixel-identical on a symmetric source, which would " +
                                          "look green while proving nothing. The magenta bar is LEFT-ONLY and the " +
                                          "cyan bar is TOP-ONLY, so a horizontal/vertical flip moves ink onto a " +
                                          "named pixel that is otherwise background-coloured."));

            var list = new List<object>();
            foreach (CaseDef c in cases)
            {
                list.Add(J.O()
                    .Add("id", c.Id)
                    .Add("family", c.Family)
                    .Add("description", c.Description)
                    .Add("source", c.Source)
                    .Add("tileMode", c.TileMode)
                    .Add("viewportName", c.ViewportName)
                    .Add("viewport", Doubles(c.Viewport))
                    .Add("viewportUnits", c.ViewportUnits)
                    .Add("viewbox", Doubles(c.Viewbox))
                    .Add("viewboxUnits", c.ViewboxUnits)
                    .Add("stretch", c.Stretch)
                    .Add("alignmentX", c.AlignX)
                    .Add("alignmentY", c.AlignY)
                    .Add("targetRect", Doubles(c.Target))
                    .Add("opaqueBackground", c.OpaqueBackground)
                    .Add("note", c.Note));
            }
            root.Add("cases", list);
            return Json.Serialize(root);
        }

        private static List<object> FeatureList(Pattern.Feature[] features)
        {
            var list = new List<object>();
            foreach (Pattern.Feature f in features)
            {
                list.Add(J.O()
                    .Add("x", f.X).Add("y", f.Y).Add("w", f.W).Add("h", f.H)
                    .Add("color", Pattern.Hex(f.Argb)));
            }
            return list;
        }

        private static List<object> DiscriminatorList()
        {
            var list = new List<object>();
            foreach (var (role, x, y, expect) in Pattern.Discriminators)
            {
                list.Add(J.O()
                    .Add("role", role)
                    .Add("sourceX", x).Add("sourceY", y)
                    .Add("colorInUnflippedTile", Pattern.Hex(expect)));
            }
            return list;
        }

        private static List<object> Doubles(double[] a)
        {
            var l = new List<object>();
            foreach (double d in a) l.Add(d);
            return l;
        }

        /// <summary>Variant key that stays constant within one comparison group, plus the axis that varies.</summary>
        private static string VariantAxis(CaseDef d) => d.Family switch
        {
            "scaling" => "bitmapScalingMode",
            "dpi" => "dpi",
            "textmode" => "textFormattingMode",
            "cachebrush" => "bitmapCache",
            _ => "tileMode",
        };

        private static List<List<RenderedCase>> GroupByVariantAxis(List<RenderedCase> all)
        {
            var groups = new List<List<RenderedCase>>();
            var index = new Dictionary<string, List<RenderedCase>>();
            foreach (RenderedCase rc in all)
            {
                CaseDef d = rc.Def;
                string key = d.Family switch
                {
                    "scaling" => $"scaling|{d.Source}|{d.ViewportName}",
                    "dpi" => $"dpi|{StripDpi(d.Id)}",
                    "textmode" => $"textmode|{d.TileMode}",
                    "cachebrush" => "cachebrush|probe",
                    _ => null,
                };
                if (key == null) continue;
                if (!index.TryGetValue(key, out List<RenderedCase> g))
                {
                    g = new List<RenderedCase>();
                    index[key] = g;
                    groups.Add(g);
                }
                g.Add(rc);
            }
            // TileMode never varies inside these groups; drop groups with a single member
            var result = new List<List<RenderedCase>>();
            foreach (List<RenderedCase> g in groups) if (g.Count > 1) result.Add(g);
            return result;
        }

        /// <summary>"b2_dpi120_image_tile_v2" -> "image_tile_v2" (the DPI-independent part).</summary>
        private static string StripDpi(string id) =>
            System.Text.RegularExpressions.Regex.Replace(id, @"^b2_dpi\d+_", "");

        private static string BuildResultsJson(List<RenderedCase> rendered, List<JObj> discrimination,
                                               List<JObj> variantComparisons,
                                               bool sabotage, bool selfTestOk, List<string> failures)
        {
            var root = J.O()
                .Add("format", Format)
                .Add("generatedAtUtc", DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture))
                .Add("sabotage", sabotage)
                .Add("sabotageNote", sabotage
                    ? "DELIBERATE BREAK: every FlipX/FlipY/FlipXY case was rendered as TileMode.Tile"
                    : "normal run")
                .Add("environment", EnvironmentInfo())
                .Add("caseCount", rendered.Count)
                .Add("selfTest", J.O()
                    .Add("description", "comparator must report a case as identical to itself")
                    .Add("ok", selfTestOk))
                .Add("failures", new List<object>(failures.ToArray()));

            var caseList = new List<object>();
            foreach (RenderedCase rc in rendered)
            {
                var samples = new List<object>();
                foreach (Sample s in rc.Samples)
                {
                    samples.Add(J.O()
                        .Add("x", s.X).Add("y", s.Y)
                        .Add("role", s.Role)
                        .Add("note", s.Note)
                        .Add("hex", s.Hex)
                        .Add("modelHex", s.ModelHex)
                        .Add("modelUsable", s.ModelUsable));
                }

                var hypos = new List<object>();
                foreach (Hypothesis h in rc.Hypotheses)
                {
                    hypos.Add(J.O()
                        .Add("name", h.Name)
                        .Add("checked", h.Checked)
                        .Add("matched", h.Matched)
                        .Add("originX", h.Geom.Known ? h.Geom.OriginX : (double?)null)
                        .Add("originY", h.Geom.Known ? h.Geom.OriginY : (double?)null));
                }

                caseList.Add(J.O()
                    .Add("id", rc.Def.Id)
                    .Add("family", rc.Def.Family)
                    .Add("source", rc.Def.Source)
                    .Add("tileModeDeclared", rc.Def.TileMode)
                    .Add("tileModeRendered", rc.Sabotaged ? "Tile" : rc.Def.TileMode)
                    .Add("sabotaged", rc.Sabotaged)
                    .Add("viewport", Doubles(rc.Def.Viewport))
                    .Add("viewportUnits", rc.Def.ViewportUnits)
                    .Add("viewbox", Doubles(rc.Def.Viewbox))
                    .Add("viewboxUnits", rc.Def.ViewboxUnits)
                    .Add("stretch", rc.Def.Stretch)
                    .Add("alignmentX", rc.Def.AlignX)
                    .Add("alignmentY", rc.Def.AlignY)
                    .Add("targetRectDiu", Doubles(rc.Def.Target))
                    .Add("targetRectDevice", rc.DeviceTarget == null ? null : Doubles(rc.DeviceTarget))
                    .Add("dpi", rc.Def.Dpi)
                    .Add("dpiScaleFactor", rc.DpiScaleFactor)
                    .Add("bitmapScalingModeRequested", rc.Def.BitmapScalingMode)
                    .Add("textFormattingModeRequested", rc.Def.TextFormattingMode)
                    .Add("bitmapCacheMode", rc.Def.BitmapCacheMode)
                    .Add("brushTypeUsed", rc.BrushTypeUsed)
                    .Add("isTileBrush", rc.TileBrushKnobsApplied)
                    .Add("tileBrushKnobsApplied", rc.TileBrushKnobsApplied)
                    .Add("png", rc.PngFile)
                    .Add("pngBytes", rc.PngBytes)
                    .Add("pngSha256", rc.PngSha256)
                    .Add("pngSize", J.O().Add("width", rc.Width).Add("height", rc.Height)
                        .Add("dpiX", rc.DpiX).Add("dpiY", rc.DpiY).Add("pixelFormat", rc.PixelFormat))
                    .Add("layout", J.O()
                        .Add("actualWidth", rc.ActualWidth)
                        .Add("actualHeight", rc.ActualHeight)
                        .Add("renderedBounds", rc.RenderedBounds == null ? null : Doubles(rc.RenderedBounds))
                        .Add("dpiScale", rc.DpiScale)
                        .Add("textFormattingMode", rc.TextFormattingMode)
                        .Add("bitmapScalingMode", rc.BitmapScalingMode)
                        .Add("fontFamilyInVisual", rc.FontFamilyInVisual))
                    .Add("viewportOriginInterpretation", rc.Winner.Name)
                    .Add("viewportOriginHypotheses", hypos)
                    .Add("tileGeometry", rc.Tile.Known
                        ? J.O().Add("known", true)
                            .Add("originX", rc.Tile.OriginX).Add("originY", rc.Tile.OriginY)
                            .Add("tileWidth", rc.Tile.TileW).Add("tileHeight", rc.Tile.TileH)
                            .Add("indexLeft", rc.Tile.IndexLeft).Add("indexRight", rc.Tile.IndexRight)
                            .Add("indexTop", rc.Tile.IndexTop).Add("indexBottom", rc.Tile.IndexBottom)
                        : J.O().Add("known", false)
                            .Add("reason", "Stretch=" + rc.Def.Stretch + " (tile is not simply the mapped viewport)"))
                    .Add("modelApplicable", Program.ModelApplicable(rc.Def))
                    .Add("stats", J.O()
                        .Add("distinctSampledColors", rc.DistinctColors)
                        .Add("paintedSamples", rc.PaintedSamples)
                        .Add("modelChecked", rc.ModelChecked)
                        .Add("modelMatched", rc.ModelMatched)
                        .Add("modelMismatchExamples", new List<object>(rc.ModelMismatches.ToArray())))
                    .Add("checks", J.O()
                        .Add("ok", rc.CheckFailures.Count == 0)
                        .Add("failures", new List<object>(rc.CheckFailures.ToArray())))
                    .Add("samples", samples));
            }

            root.Add("cases", caseList);
            root.Add("discrimination", new List<object>(discrimination.ToArray()));
            root.Add("variantComparisons", new List<object>(variantComparisons.ToArray()));
            return Json.Serialize(root);
        }

        private static JObj EnvironmentInfo()
        {
            var core = typeof(Visual).Assembly;
            string coreVersion = "unknown", coreSha = "unknown";
            try
            {
                coreVersion = FileVersionInfo.GetVersionInfo(core.Location).FileVersion;
                coreSha = Sha256File(core.Location);
            }
            catch (Exception) { }

            string wpfgfxVersion = "unknown", wpfgfxSha = "unknown", wpfgfxPath = "unknown";
            try
            {
                string dir = Path.GetDirectoryName(core.Location);
                string p = Path.Combine(dir, "wpfgfx_cor3.dll");
                wpfgfxPath = p;
                wpfgfxVersion = FileVersionInfo.GetVersionInfo(p).FileVersion;
                wpfgfxSha = Sha256File(p);
            }
            catch (Exception) { }

            return J.O()
                .Add("machineName", System.Environment.MachineName)
                .Add("osVersion", System.Environment.OSVersion.VersionString)
                .Add("is64BitProcess", System.Environment.Is64BitProcess)
                .Add("processorCount", System.Environment.ProcessorCount)
                .Add("sessionId", Process.GetCurrentProcess().SessionId)
                .Add("userInteractive", System.Environment.UserInteractive)
                .Add("frameworkDescription", System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription)
                .Add("presentationCorePath", core.Location)
                .Add("presentationCoreFileVersion", coreVersion)
                .Add("presentationCoreSha256", coreSha)
                .Add("wpfgfxCor3Path", wpfgfxPath)
                .Add("wpfgfxCor3FileVersion", wpfgfxVersion)
                .Add("wpfgfxCor3Sha256", wpfgfxSha)
                .Add("renderTarget", "RenderTargetBitmap(256,256,96,96,PixelFormats.Pbgra32) over a Canvas");
        }
    }

    internal sealed class RenderedCase
    {
        public CaseDef Def;
        public bool Sabotaged;
        public byte[] Pixels;
        public int Width, Height;
        public double DpiX, DpiY, DpiScale, DpiScaleFactor;
        public double[] DeviceTarget;
        public bool TileBrushKnobsApplied = true;
        public string BrushTypeUsed;
        public string PngFile, PngSha256, PixelFormat, TextFormattingMode, BitmapScalingMode, FontFamilyInVisual;
        public long PngBytes;
        public double ActualWidth, ActualHeight;
        public double[] RenderedBounds;
        public Program.TileGeom Tile;
        public Program.Hypothesis Winner;
        public List<Program.Hypothesis> Hypotheses = new List<Program.Hypothesis>();
        public List<Program.Sample> Samples = new List<Program.Sample>();
        public int DistinctColors, PaintedSamples, ModelChecked, ModelMatched;
        public List<string> ModelMismatches = new List<string>();
        public List<string> CheckFailures = new List<string>();
    }
}

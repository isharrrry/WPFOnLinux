using System;
using System.Collections.Generic;
using System.Globalization;

namespace U1BrushOracle
{
    internal sealed class CaseDef
    {
        public string Id;
        public string Family;        // core | visual | stretch | units | fractional | alpha
        public string Description;
        public string Source;        // image | drawing | visual | alphaImage
        public string TileMode;      // None | Tile | FlipX | FlipY | FlipXY
        public string ViewportName;
        public double[] Viewport;
        public string ViewportUnits; // RelativeToBoundingBox | Absolute
        public double[] Viewbox;
        public string ViewboxUnits;
        public string Stretch;       // None | Fill | Uniform | UniformToFill
        public string AlignX;        // Left | Center | Right
        public string AlignY;        // Top | Center | Bottom
        public double[] Target;      // x, y, w, h  (in DIU at the case DPI)
        public bool OpaqueBackground = true;
        public string Note;

        // ---- batch 2 knobs ----
        public double Dpi = 96.0;               // RenderTargetBitmap DPI; device px = DIU * Dpi/96
        public string BitmapScalingMode;        // null = leave Unspecified
        public string TextFormattingMode;       // null = Ideal (WPF default)
        public string BitmapCacheMode;          // null = not a cache-brush case

        /// <summary>DIU -> device pixel factor.</summary>
        public double Scale => Dpi / 96.0;
    }

    internal static class Cases
    {
        public const double CanvasSize = 256.0;
        public const double CanvasDpi = 96.0;

        // ---- viewport presets (RelativeToBoundingBox unless stated) ----
        public static readonly double[] V1Same = { 0.0, 0.0, 1.0, 1.0 };          // == target, no tiling
        public static readonly double[] V2Tiling = { 0.0, 0.0, 0.4, 0.4 };        // target is 2.5 tiles
        public static readonly double[] V3Offset = { 0.3, 0.2, 0.4, 0.4 };        // tile origin offset
        public static readonly double[] VAbs = { 10.0, 10.0, 80.0, 48.0 };        // absolute units

        public static readonly double[] TargetInt = { 16.0, 16.0, 200.0, 120.0 };
        public static readonly double[] TargetFrac = { 13.5, 9.25, 183.5, 117.25 };

        private static readonly string[] AllTileModes = { "None", "Tile", "FlipX", "FlipY", "FlipXY" };

        public static List<CaseDef> BuildBatch1()
        {
            var list = new List<CaseDef>();

            // ==============================================================
            //  Batch 1 (priority): TileMode x {ImageBrush, DrawingBrush} x 3 viewports
            // ==============================================================
            foreach (string source in new[] { "image", "drawing" })
            {
                foreach (var vp in new[]
                {
                    ("v1same", V1Same), ("v2tiling", V2Tiling), ("v3offset", V3Offset),
                })
                {
                    foreach (string tm in AllTileModes)
                    {
                        list.Add(new CaseDef
                        {
                            Id = $"core_{source}_{tm.ToLowerInvariant()}_{vp.Item1}",
                            Family = "core",
                            Description = $"TileMode={tm} on {(source == "image" ? "ImageBrush" : "DrawingBrush")}, " +
                                          $"Viewport={vp.Item1} ({Fmt(vp.Item2)}), 32x32 asymmetric source, Stretch=Fill",
                            Source = source,
                            TileMode = tm,
                            ViewportName = vp.Item1,
                            Viewport = vp.Item2,
                            ViewportUnits = "RelativeToBoundingBox",
                            Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 },
                            ViewboxUnits = "Absolute",
                            Stretch = "Fill",
                            AlignX = "Center",
                            AlignY = "Center",
                            Target = TargetInt,
                        });
                    }
                }
            }

            // ==============================================================
            //  VisualBrush (same matrix, source carries a TextBlock)
            // ==============================================================
            foreach (var vp in new[]
            {
                ("v1same", V1Same), ("v2tiling", V2Tiling), ("v3offset", V3Offset),
            })
            {
                foreach (string tm in AllTileModes)
                {
                    list.Add(new CaseDef
                    {
                        Id = $"visual_{tm.ToLowerInvariant()}_{vp.Item1}",
                        Family = "visual",
                        Description = $"TileMode={tm} on VisualBrush (32x32 Canvas + TextBlock \"F7\" + asymmetric bars), " +
                                      $"Viewport={vp.Item1} ({Fmt(vp.Item2)})",
                        Source = "visual",
                        TileMode = tm,
                        ViewportName = vp.Item1,
                        Viewport = vp.Item2,
                        ViewportUnits = "RelativeToBoundingBox",
                        Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 },
                        ViewboxUnits = "Absolute",
                        Stretch = "Fill",
                        AlignX = "Center",
                        AlignY = "Center",
                        Target = TargetInt,
                    });
                }
            }

            // ==============================================================
            //  Stretch x Alignment (ImageBrush): single-tile and tiled viewports
            //  Stretch=None + Alignment is the classic divergence point.
            // ==============================================================
            foreach (string stretch in new[] { "None", "Uniform", "UniformToFill", "Fill" })
            {
                foreach (var align in new[] { ("Left", "Top"), ("Center", "Center") })
                {
                    list.Add(new CaseDef
                    {
                        Id = $"stretch_{stretch.ToLowerInvariant()}_{align.Item1.ToLowerInvariant()}_v1same",
                        Family = "stretch",
                        Description = $"ImageBrush Stretch={stretch} Alignment={align.Item1}/{align.Item2}, " +
                                      "Viewport=v1same (single tile 200x120, source 32x32)",
                        Source = "image", TileMode = "None",
                        ViewportName = "v1same", Viewport = V1Same,
                        ViewportUnits = "RelativeToBoundingBox",
                        Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                        Stretch = stretch, AlignX = align.Item1, AlignY = align.Item2,
                        Target = TargetInt,
                    });

                    list.Add(new CaseDef
                    {
                        Id = $"stretch_{stretch.ToLowerInvariant()}_{align.Item1.ToLowerInvariant()}_v2tile",
                        Family = "stretch",
                        Description = $"ImageBrush Stretch={stretch} Alignment={align.Item1}/{align.Item2}, " +
                                      "Viewport=v2tiling + TileMode=Tile (tile is 80x48, source 32x32)",
                        Source = "image", TileMode = "Tile",
                        ViewportName = "v2tiling", Viewport = V2Tiling,
                        ViewportUnits = "RelativeToBoundingBox",
                        Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                        Stretch = stretch, AlignX = align.Item1, AlignY = align.Item2,
                        Target = TargetInt,
                    });
                }
            }

            // ==============================================================
            //  Units mixing (Absolute vs RelativeToBoundingBox) -
            //  in particular WHOSE coordinate space an absolute Viewport uses.
            // ==============================================================
            list.Add(new CaseDef
            {
                Id = "units_vpabs_viewboxabs_tile",
                Family = "units",
                Description = "Viewport=(10,10,80,48) ABSOLUTE, Viewbox=(0,0,32,32) ABSOLUTE, TileMode=Tile. " +
                              "Target starts at (16,16): if 'absolute' is rect-local the first tile origin is device (26,26), " +
                              "if it is canvas-space the pattern is clipped differently.",
                Source = "image", TileMode = "Tile",
                ViewportName = "vabs", Viewport = VAbs, ViewportUnits = "Absolute",
                Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
            });

            list.Add(new CaseDef
            {
                Id = "units_vpabs_viewboxrel_tile",
                Family = "units",
                Description = "Viewport=(10,10,80,48) ABSOLUTE, Viewbox=(0,0,1,1) RELATIVE, TileMode=Tile",
                Source = "image", TileMode = "Tile",
                ViewportName = "vabs", Viewport = VAbs, ViewportUnits = "Absolute",
                Viewbox = new[] { 0.0, 0.0, 1.0, 1.0 }, ViewboxUnits = "RelativeToBoundingBox",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
            });

            list.Add(new CaseDef
            {
                Id = "units_vprel_viewboxrel_flipx",
                Family = "units",
                Description = "Viewport=(0.3,0.2,0.4,0.4) RELATIVE, Viewbox=(0,0,1,1) RELATIVE, TileMode=FlipX",
                Source = "image", TileMode = "FlipX",
                ViewportName = "v3offset", Viewport = V3Offset, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 1.0, 1.0 }, ViewboxUnits = "RelativeToBoundingBox",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
            });

            list.Add(new CaseDef
            {
                Id = "units_viewbox_subregion_2x_tile",
                Family = "units",
                Description = "Viewbox=(0,0,16,16) ABSOLUTE (half the source -> 2x zoom), Viewport=v2tiling, TileMode=Tile",
                Source = "image", TileMode = "Tile",
                ViewportName = "v2tiling", Viewport = V2Tiling, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 16.0, 16.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
            });

            list.Add(new CaseDef
            {
                Id = "units_drawing_viewbox_subregion_2x_flipx",
                Family = "units",
                Description = "DrawingBrush same as units_viewbox_subregion_2x_tile but TileMode=FlipX",
                Source = "drawing", TileMode = "FlipX",
                ViewportName = "v2tiling", Viewport = V2Tiling, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 16.0, 16.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
            });

            // ==============================================================
            //  Fractional target rect: sub-pixel origin/size (rounding + half pixels)
            // ==============================================================
            list.Add(new CaseDef
            {
                Id = "frac_image_none_v1same",
                Family = "fractional",
                Description = "ImageBrush TileMode=None, Viewport=v1same, target (13.5,9.25,183.5,117.25)",
                Source = "image", TileMode = "None",
                ViewportName = "v1same", Viewport = V1Same, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetFrac,
            });

            list.Add(new CaseDef
            {
                Id = "frac_image_tile_v2tiling",
                Family = "fractional",
                Description = "ImageBrush TileMode=Tile, Viewport=v2tiling, target (13.5,9.25,183.5,117.25)",
                Source = "image", TileMode = "Tile",
                ViewportName = "v2tiling", Viewport = V2Tiling, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetFrac,
            });

            list.Add(new CaseDef
            {
                Id = "frac_image_flipx_v2tiling",
                Family = "fractional",
                Description = "ImageBrush TileMode=FlipX, Viewport=v2tiling, target (13.5,9.25,183.5,117.25)",
                Source = "image", TileMode = "FlipX",
                ViewportName = "v2tiling", Viewport = V2Tiling, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetFrac,
            });

            list.Add(new CaseDef
            {
                Id = "frac_drawing_flipx_v2tiling",
                Family = "fractional",
                Description = "DrawingBrush TileMode=FlipX, Viewport=v2tiling, target (13.5,9.25,183.5,117.25)",
                Source = "drawing", TileMode = "FlipX",
                ViewportName = "v2tiling", Viewport = V2Tiling, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetFrac,
            });

            // ==============================================================
            //  Alpha / premultiplication: semi-transparent tile source
            // ==============================================================
            list.Add(new CaseDef
            {
                Id = "alpha_tile_v2tiling_opaque_bg",
                Family = "alpha",
                Description = "alpha ImageBrush (50%/25%/75% regions) TileMode=Tile over opaque #FF808080",
                Source = "alphaImage", TileMode = "Tile",
                ViewportName = "v2tiling", Viewport = V2Tiling, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
                Note = "canvas background #FF808080",
            });

            list.Add(new CaseDef
            {
                Id = "alpha_flipx_v2tiling_opaque_bg",
                Family = "alpha",
                Description = "alpha ImageBrush TileMode=FlipX over opaque #FF808080",
                Source = "alphaImage", TileMode = "FlipX",
                ViewportName = "v2tiling", Viewport = V2Tiling, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
                Note = "canvas background #FF808080",
            });

            list.Add(new CaseDef
            {
                Id = "alpha_tile_v2tiling_transparent_bg",
                Family = "alpha",
                Description = "alpha ImageBrush TileMode=Tile over a TRANSPARENT canvas (output alpha < 255)",
                Source = "alphaImage", TileMode = "Tile",
                ViewportName = "v2tiling", Viewport = V2Tiling, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
                OpaqueBackground = false,
                Note = "no background: straight-alpha PNG, A must be dumped",
            });

            list.Add(new CaseDef
            {
                Id = "alpha_flipy_v2tiling_transparent_bg",
                Family = "alpha",
                Description = "alpha ImageBrush TileMode=FlipY over a TRANSPARENT canvas",
                Source = "alphaImage", TileMode = "FlipY",
                ViewportName = "v2tiling", Viewport = V2Tiling, ViewportUnits = "RelativeToBoundingBox",
                Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
                OpaqueBackground = false,
                Note = "no background: straight-alpha PNG, A must be dumped",
            });

            return list;
        }

        // ==================================================================
        //  Batch 2: the knobs where our implementation actually has gaps,
        //  ordered by the parent's priority list.
        // ==================================================================

        public static List<CaseDef> BuildBatch2()
        {
            var list = new List<CaseDef>();

            // ---------------------------------------------------------------
            //  B1  Stretch=None x Alignment x TileMode  (KNOWN GAP)
            //      The source is NOT scaled: 32x32 source px sit somewhere inside
            //      an 80x48 tile. The open question is whether a flip mirrors the
            //      WHOLE tile (placement included, so the image jumps to the other
            //      side) or only the image. Alignment Left/Center/Right makes the
            //      two answers pixel-different.
            // ---------------------------------------------------------------
            foreach (var align in new[] { ("Left", "Top"), ("Center", "Center"), ("Right", "Bottom") })
            {
                foreach (string tm in AllTileModes)
                {
                    list.Add(new CaseDef
                    {
                        Id = $"b2_gap_none_{align.Item1.ToLowerInvariant()}_{tm.ToLowerInvariant()}_v2tiling",
                        Family = "gap",
                        Description = $"Stretch=None + Alignment={align.Item1}/{align.Item2} + TileMode={tm}, " +
                                      "Viewport=v2tiling (80x48 tile, 32x32 source at 1:1). " +
                                      "Discriminator: where the 32x32 image sits inside the tile after a flip.",
                        Source = "image", TileMode = tm,
                        ViewportName = "v2tiling", Viewport = V2Tiling,
                        ViewportUnits = "RelativeToBoundingBox",
                        Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                        Stretch = "None", AlignX = align.Item1, AlignY = align.Item2,
                        Target = TargetInt,
                    });
                }
            }

            foreach (var align in new[] { ("Left", "Top"), ("Center", "Center") })
            {
                foreach (string tm in new[] { "None", "Tile" })
                {
                    list.Add(new CaseDef
                    {
                        Id = $"b2_gap_none_{align.Item1.ToLowerInvariant()}_{tm.ToLowerInvariant()}_v1same",
                        Family = "gap",
                        Description = $"Stretch=None + Alignment={align.Item1}/{align.Item2} + TileMode={tm}, " +
                                      "Viewport=v1same (single 200x120 tile, 32x32 image placed by alignment)",
                        Source = "image", TileMode = tm,
                        ViewportName = "v1same", Viewport = V1Same,
                        ViewportUnits = "RelativeToBoundingBox",
                        Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                        Stretch = "None", AlignX = align.Item1, AlignY = align.Item2,
                        Target = TargetInt,
                    });
                }
            }

            // ---------------------------------------------------------------
            //  B2  BitmapScalingMode: does it change pixels at all under the
            //      software RenderTargetBitmap? Upscale and downscale both.
            // ---------------------------------------------------------------
            var downscale = new[] { 0.0, 0.0, 0.06, 0.06 };     // 12 x 7.2 device px tiles
            foreach (string mode in new[] { "NearestNeighbor", "Linear", "HighQuality", "Unspecified" })
            {
                foreach (string src in new[] { "image", "drawing" })
                {
                    list.Add(new CaseDef
                    {
                        Id = $"b2_scale_up_{src}_{mode.ToLowerInvariant()}",
                        Family = "scaling",
                        Description = $"BitmapScalingMode={mode}, {src} source, Viewport=v2tiling: 32x32 source " +
                                      "magnified to an 80x48 tile (2.5x1.5) - edges expose the filter",
                        Source = src, TileMode = "Tile",
                        ViewportName = "v2tiling", Viewport = V2Tiling,
                        ViewportUnits = "RelativeToBoundingBox",
                        Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                        Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
                        BitmapScalingMode = mode == "Unspecified" ? null : mode,
                    });

                    list.Add(new CaseDef
                    {
                        Id = $"b2_scale_down_{src}_{mode.ToLowerInvariant()}",
                        Family = "scaling",
                        Description = $"BitmapScalingMode={mode}, {src} source, Viewport=(0,0,0.06,0.06): " +
                                      "32x32 source minified into a 12x7.2 tile (0.375x) - mip/box filtering exposes the filter",
                        Source = src, TileMode = "Tile",
                        ViewportName = "v3tiny", Viewport = downscale,
                        ViewportUnits = "RelativeToBoundingBox",
                        Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                        Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
                        BitmapScalingMode = mode == "Unspecified" ? null : mode,
                    });
                }
            }

            // ---------------------------------------------------------------
            //  B3  non-96 DPI. Device-space geometry is held constant: the canvas
            //      is 256/scale DIU and the target is scaled the same way, so the
            //      device pixel grid, tile sizes and target rect stay identical to
            //      the 96 DPI baseline. What changes is how a 96 DPI BitmapSource
            //      is mapped (32 source px = 32 DIU = 32*scale device px) and how
            //      text is hinted.
            // ---------------------------------------------------------------
            foreach (double dpi in new[] { 96.0, 120.0, 144.0 })
            {
                foreach (var v in new[]
                {
                    ("image_tile_v2", "image", "Tile", "v2tiling"),
                    ("image_flipx_v2", "image", "FlipX", "v2tiling"),
                    ("drawing_tile_v2", "drawing", "Tile", "v2tiling"),
                    ("visual_tile_v2", "visual", "Tile", "v2tiling"),
                    ("image_none_v1same", "image", "None", "v1same"),
                })
                {
                    list.Add(new CaseDef
                    {
                        Id = $"b2_dpi{(int)dpi}_{v.Item1}",
                        Family = "dpi",
                        Description = $"{dpi} DPI, {v.Item2} source, TileMode={v.Item3}, Viewport={v.Item4}; " +
                                      "device-space geometry identical to the 96 DPI case of the same name",
                        Source = v.Item2, TileMode = v.Item3,
                        ViewportName = v.Item4,
                        Viewport = v.Item4 == "v1same" ? V1Same : V2Tiling,
                        ViewportUnits = "RelativeToBoundingBox",
                        Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                        Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
                        Dpi = dpi,
                    });
                }
            }

            // Stretch=None is the one place where the BitmapSource's own DPI can matter:
            // the image is drawn at its natural size (32 px at 96 DPI = 32 DIU = 32*scale
            // device px), so a DPI-aware renderer must scale it with the render DPI while a
            // renderer that treats source pixels as device pixels must not.
            foreach (double dpi in new[] { 96.0, 120.0, 144.0 })
            {
                list.Add(new CaseDef
                {
                    Id = $"b2_dpi{(int)dpi}_image_none_stretch_left_tile",
                    Family = "dpi",
                    Description = $"{dpi} DPI, ImageBrush Stretch=None Alignment=Left/Top TileMode=Tile Viewport=v2tiling: " +
                                  "the 32x32 @96dpi bitmap is drawn at its natural size, so the device footprint " +
                                  "32*scale px is directly observable",
                    Source = "image", TileMode = "Tile",
                    ViewportName = "v2tiling", Viewport = V2Tiling,
                    ViewportUnits = "RelativeToBoundingBox",
                    Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                    Stretch = "None", AlignX = "Left", AlignY = "Top", Target = TargetInt,
                    Dpi = dpi,
                });
            }

            // ---------------------------------------------------------------
            //  B4  TextFormattingMode on a text-bearing VisualBrush tile.
            //      Set on the TextBlock inside the visual (that is where the
            //      property lives for a VisualBrush source).
            // ---------------------------------------------------------------
            foreach (string mode in new[] { "Ideal", "Display" })
            {
                foreach (string tm in new[] { "Tile", "FlipX" })
                {
                    list.Add(new CaseDef
                    {
                        Id = $"b2_text_{mode.ToLowerInvariant()}_{tm.ToLowerInvariant()}",
                        Family = "textmode",
                        Description = $"VisualBrush with TextBlock(F7) at TextFormattingMode={mode}, TileMode={tm}, " +
                                      "Viewport=v2tiling (text is the most DPI/hinting sensitive content)",
                        Source = "visual", TileMode = tm,
                        ViewportName = "v2tiling", Viewport = V2Tiling,
                        ViewportUnits = "RelativeToBoundingBox",
                        Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                        Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
                        TextFormattingMode = mode,
                    });
                }
            }

            // ---------------------------------------------------------------
            //  BitmapCacheBrush scope probe (4 cases, deliberately minimal):
            //  is the cached-brush path observably different from VisualBrush
            //  under the software rasterizer at all?
            // ---------------------------------------------------------------
            foreach (var v in new[] { ("nocache", "none"), ("cache", "default"), ("cache_scale2", "scale2") })
            {
                list.Add(new CaseDef
                {
                    Id = $"b2_cachebrush_{v.Item1}_tile",
                    Family = "cachebrush",
                    Description = $"BitmapCacheBrush(Target=asymmetric visual) cacheMode={v.Item1 ?? "none"}, TileMode=Tile, " +
                                  "Viewport=v2tiling - probe whether the cache changes any pixel vs VisualBrush",
                    Source = "visual", TileMode = "Tile",
                    ViewportName = "v2tiling", Viewport = V2Tiling,
                    ViewportUnits = "RelativeToBoundingBox",
                    Viewbox = new[] { 0.0, 0.0, 32.0, 32.0 }, ViewboxUnits = "Absolute",
                    Stretch = "Fill", AlignX = "Center", AlignY = "Center", Target = TargetInt,
                    BitmapCacheMode = v.Item2,
                });
            }

            return list;
        }

        private static string Fmt(double[] a) =>
            "(" + string.Join(",", Array.ConvertAll(a, v => v.ToString("0.####", CultureInfo.InvariantCulture))) + ")";
    }
}

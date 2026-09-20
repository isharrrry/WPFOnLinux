// U1a 真机对照：把 tests/parity/windows/scenes.json 里的场景规格，用**我方渲染栈**
// （MilChannel + MilResourceTable + MilVisual + MilRenderData + SkiaRenderBackend）重画一遍。
//
// 【数据来源与只读约定】
//   tests/parity/windows/ 是真机采集侧的产物（15 张 256×256 PNG + scenes.json + probe.json），
//   本文件只读、绝不写。所有写出的中间产物一律落在 tests/parity/linux/。
//
// 【为什么逐字面翻译 R.cs 的 op 树，而不是"照着描述手写"】
//   真机的 ops 树是**唯一真源**：U1Parity 用它同时渲染和序列化 scenes.json
//   （Seens.cs 的注释写明 "the SAME tree is fed to the renderer"）。所以对照的正确做法
//   是把同一棵树喂给我方栈，而不是看着 PNG 反推。op→API 的映射逐条对着 R.cs：
//     rect        → DrawingContext.DrawRectangle   → MilDrawRectangle
//     roundrect   → DrawRoundedRectangle           → MilDrawRoundedRectangle
//     ellipse     → DrawEllipse                    → MilDrawEllipse
//     line        → DrawLine                       → MilDrawLine
//     linear/radialGradient → DrawRectangle(brush) → MilDrawRectangle + 渐变画刷
//     path        → DrawGeometry                   → MilDrawGeometry + MilPathGeometry
//     combine     → DrawGeometry(CombinedGeometry) → MilDrawGeometry + MilCombinedGeometry
//     clip        → PushClip × n / Pop × n         → MilPushClip × n / MilPop × n
//     opacity     → PushOpacity / Pop              → MilPushOpacity / MilPop
//     transform   → PushTransform / Pop            → MilPushTransform / MilPop
//
// 【颜色口径】
//   scenes.json 里是 #AARRGGBB 的 sRGB 字节；WPF 送进 MIL 的是 scRGB 浮点
//   （Composition.cs: color.r = c.ScR），所以这里走 SkiaColor.MakeScRgb 做同一趟变换——
//   与 TestScene.Solid() 用的完全是同一条路，不新开旁路。

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text.Json;
using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;

namespace WpfGfx.Linux.Tests.Rendering
{
    // ==================================================================
    //  路径
    // ==================================================================

    internal static class ParityLayout
    {
        /// <summary>真机数据目录（只读）。</summary>
        public static string WindowsDir =>
            Path.Combine(RepoLayout.RootPath, "tests", "parity", "windows");

        /// <summary>我方对照产物目录（新建，可写）。</summary>
        public static string LinuxDir =>
            Path.Combine(RepoLayout.RootPath, "tests", "parity", "linux");

        public static string ActualDir => Path.Combine(LinuxDir, "actual");
        public static string DiffDir => Path.Combine(LinuxDir, "diff");

        public static string ScenesJson => Path.Combine(WindowsDir, "scenes.json");
        public static string ProbeJson => Path.Combine(WindowsDir, "probe.json");

        public static string ActualPath(string sceneId) => Path.Combine(ActualDir, sceneId + ".png");
        public static string DiffPath(string sceneId) => Path.Combine(DiffDir, sceneId + ".diff.png");
        public static string ResultsPath => Path.Combine(LinuxDir, "parity-results.json");

        public static void EnsureDirs()
        {
            Directory.CreateDirectory(LinuxDir);
            Directory.CreateDirectory(ActualDir);
            Directory.CreateDirectory(DiffDir);
        }
    }

    // ==================================================================
    //  数据模型（scenes.json 的只读投影）
    // ==================================================================

    internal sealed class ParityProbe
    {
        public int X, Y;
        public string Kind;          // interior / edge
        public string Note;
        public string ExpectHex;     // 采集侧手算预期（可为 null，见 scene13 (192,172)）
        public bool HasExpect;
        public int[] Rgba;           // 真机 PNG 实测 RGBA
        public int ExpectTolerance;

        public override string ToString() => $"({X},{Y}) {Kind} {Note}";
    }

    internal sealed class ParitySceneSpec
    {
        public string Id;
        public string Png;
        public string Description;
        public JsonElement Ops;
        public List<ParityProbe> Probes;

        public string PngPath => Path.Combine(ParityLayout.WindowsDir, Png);
    }

    /// <summary>真机数据的加载与可用性探测（发现期 Skip 用）。</summary>
    internal static class ParityData
    {
        private static readonly Lazy<(bool Ok, string Reason, List<ParitySceneSpec> Scenes, JsonDocument Doc)>
            Loaded = new Lazy<(bool, string, List<ParitySceneSpec>, JsonDocument)>(LoadCore);

        public static bool Available => Loaded.Value.Ok;
        public static string Reason => Loaded.Value.Reason;
        public static List<ParitySceneSpec> Scenes => Loaded.Value.Scenes;

        public static string SkipReason =>
            "真机对照数据不可用：" + Reason +
            "。需要 tests/parity/windows/{scenes.json,scene*.png}（只读输入，来自 Windows 采集）。";

        private static (bool, string, List<ParitySceneSpec>, JsonDocument) LoadCore()
        {
            try
            {
                if (!File.Exists(ParityLayout.ScenesJson))
                    return (false, $"缺少 {ParityLayout.ScenesJson}", new List<ParitySceneSpec>(), null);

                JsonDocument doc = JsonDocument.Parse(File.ReadAllText(ParityLayout.ScenesJson));
                var scenes = new List<ParitySceneSpec>();

                foreach (JsonElement s in doc.RootElement.GetProperty("scenes").EnumerateArray())
                {
                    var spec = new ParitySceneSpec
                    {
                        Id = s.GetProperty("id").GetString(),
                        Png = s.GetProperty("png").GetString(),
                        Description = s.GetProperty("description").GetString(),
                        Ops = s.GetProperty("ops").Clone(),
                        Probes = new List<ParityProbe>(),
                    };

                    if (!File.Exists(spec.PngPath))
                        return (false, $"缺少真机 PNG {spec.PngPath}", new List<ParitySceneSpec>(), doc);

                    foreach (JsonElement p in s.GetProperty("probes").EnumerateArray())
                    {
                        var probe = new ParityProbe
                        {
                            X = p.GetProperty("x").GetInt32(),
                            Y = p.GetProperty("y").GetInt32(),
                            Kind = p.GetProperty("kind").GetString(),
                            Note = p.GetProperty("note").GetString(),
                            ExpectTolerance = p.TryGetProperty("expectTolerance", out JsonElement t)
                                ? (int)t.GetDouble() : 2,
                        };

                        if (p.TryGetProperty("expect", out JsonElement e) &&
                            e.ValueKind == JsonValueKind.String)
                        {
                            probe.ExpectHex = e.GetString();
                            probe.HasExpect = true;
                        }

                        JsonElement rgba = p.GetProperty("rgba");
                        probe.Rgba = new[]
                        {
                            rgba[0].GetInt32(), rgba[1].GetInt32(),
                            rgba[2].GetInt32(), rgba[3].GetInt32(),
                        };

                        spec.Probes.Add(probe);
                    }

                    scenes.Add(spec);
                }

                return (true, $"{scenes.Count} 个场景（{ParityLayout.WindowsDir}）", scenes, doc);
            }
            catch (Exception ex)
            {
                return (false, $"{ex.GetType().Name}: {ex.Message}", new List<ParitySceneSpec>(), null);
            }
        }

        /// <summary>真机 PNG → 位图。统一到 Rgba8888/Premul，与实测图同格式再比。</summary>
        public static SKBitmap LoadWindowsPng(ParitySceneSpec spec) => RenderHarness.LoadPng(spec.PngPath);

        public static ParitySceneSpec Get(string id)
        {
            foreach (ParitySceneSpec s in Scenes)
                if (s.Id == id) return s;
            throw new ArgumentException($"scenes.json 里没有场景 {id}");
        }

        /// <summary>场景 id 列表（按 scenes.json 顺序；数据缺失时为空）。</summary>
        public static IReadOnlyList<string> Ids
        {
            get
            {
                var ids = new List<string>();
                foreach (ParitySceneSpec s in Scenes) ids.Add(s.Id);
                return ids;
            }
        }
    }

    // ==================================================================
    //  PathGeometry 序列化（MIL_PATHGEOMETRY / MIL_PATHFIGURE / MIL_SEGMENT_*）
    // ==================================================================

    /// <summary>
    /// 与 Rendering/PathGeometryParser.cs 的读取约定逐字节对应的**写**侧。
    /// 为什么不复用 tests 里已有的 PathGeometryBuilder：本文件需要 figure 级
    /// "filled"（= MilPathFigureFlags.IsFillable）与 arc 的 xRotation，而那个 builder
    /// 是既有资产（不许改），故在这里独立实现一份——两边各自对着同一份布局注释写，
    /// 也算一次交叉验证。
    /// </summary>
    internal sealed class ParityPathBuilder
    {
        private const int GeometryHeaderSize = 48;
        private const int FigureHeaderSize = 40;

        private readonly List<byte[]> _figures = new List<byte[]>();

        public Figure AddFigure(double sx, double sy, bool closed, bool filled)
            => new Figure(this, sx, sy, closed, filled);

        public byte[] Build()
        {
            using var ms = new MemoryStream();
            using var w = new BinaryWriter(ms);
            w.Write(0u);                                  // Size@0（回填）
            w.Write(0u);                                  // Flags@4
            for (int i = 0; i < 4; i++) w.Write(0.0);     // Bounds@8..40
            w.Write((uint)_figures.Count);                // FigureCount@40
            w.Write(0u);                                  // ForcePacking@44
            foreach (byte[] f in _figures) w.Write(f);

            byte[] bytes = ms.ToArray();
            BitConverter.GetBytes((uint)bytes.Length).CopyTo(bytes, 0);
            return bytes;
        }

        internal void Commit(Figure f) => _figures.Add(f.ToBytes());

        internal sealed class Figure
        {
            private readonly ParityPathBuilder _owner;
            private readonly double _sx, _sy;
            private readonly uint _flags;
            private readonly MemoryStream _body = new MemoryStream();
            private readonly BinaryWriter _w;
            private int _segments;

            internal Figure(ParityPathBuilder owner, double sx, double sy, bool closed, bool filled)
            {
                _owner = owner;
                _sx = sx; _sy = sy;
                _flags = (closed ? (uint)MilPathFigureFlags.IsClosed : 0u)
                       | (filled ? (uint)MilPathFigureFlags.IsFillable : 0u);
                _w = new BinaryWriter(_body);
            }

            public Figure Line(double x, double y) => Segment(MilSegmentType.Line, w =>
            {
                w.Write(0u);                 // ForcePacking@12
                w.Write(x); w.Write(y);      // Point@16
            });

            /// <summary>ArcSegment：LargeArc@12 Point@16 Size@32 XRotation@48 Sweep@56 Pad@60。</summary>
            public Figure Arc(double x, double y, double rx, double ry, double rot,
                              bool largeArc, bool clockwise) => Segment(MilSegmentType.Arc, w =>
            {
                w.Write(largeArc ? 1u : 0u);
                w.Write(x); w.Write(y);
                w.Write(rx); w.Write(ry);
                w.Write(rot);
                w.Write(clockwise ? 1u : 0u);
                w.Write(0u);
            });

            private Figure Segment(MilSegmentType type, Action<BinaryWriter> body)
            {
                _w.Write((uint)type);
                _w.Write(0u);               // Flags@4（IsStroked 的段不带 SegIsAGap）
                _w.Write(0u);               // BackSize@8
                body(_w);
                _segments++;
                return this;
            }

            internal byte[] ToBytes()
            {
                _w.Flush();
                byte[] body = _body.ToArray();

                using var ms = new MemoryStream();
                using var w = new BinaryWriter(ms);
                w.Write(0u);                                        // BackSize@0
                w.Write(_flags);                                    // Flags@4
                w.Write((uint)_segments);                           // Count@8
                w.Write((uint)(FigureHeaderSize + body.Length));    // Size@12
                w.Write(_sx); w.Write(_sy);                         // StartPoint@16
                w.Write(0u);                                        // OffsetToLastSegment@32
                w.Write(0u);                                        // ForcePacking@36
                w.Write(body);
                return ms.ToArray();
            }

            public ParityPathBuilder End()
            {
                _owner.Commit(this);
                return _owner;
            }
        }
    }

    // ==================================================================
    //  场景播放器
    // ==================================================================

    /// <summary>一次对照渲染的结果。</summary>
    internal sealed class ParityRenderResult : IDisposable
    {
        public SKBitmap Bitmap;
        public RenderDiagnostics Diagnostics;
        public bool StackBalanced;
        public int InstructionCount;

        public void Dispose() => Bitmap?.Dispose();
    }

    /// <summary>
    /// scenes.json 的 op 树 → 我方指令流 → 256×256 位图。
    /// 资源全部经真实的 MilResourceTable（TestScene.Add → Duplicate），不走 mock。
    /// </summary>
    internal sealed class ParityRenderer : IDisposable
    {
        private readonly TestScene _scene = new TestScene();
        private readonly List<MilDrawInstruction> _instructions = new List<MilDrawInstruction>();

        public TestScene Scene => _scene;

        /// <summary>播放一棵 op 树（可多次调用，追加到同一段 RenderData）。</summary>
        public void Play(JsonElement ops)
        {
            foreach (JsonElement op in ops.EnumerateArray()) PlayOp(op);
        }

        public SKBitmap Render() => RenderFull().Bitmap;

        public ParityRenderResult RenderFull()
        {
            var draw = new DrawList();
            foreach (MilDrawInstruction instr in _instructions) draw.Add(instr);

            MilVisual root = _scene.Visual();
            root.Content = draw.ToRenderData();

            RenderOutput output = RenderHarness.Render(
                root, _scene.Provider, width: 256, height: 256, antialias: true);

            return new ParityRenderResult
            {
                Bitmap = output.Bitmap,
                Diagnostics = output.Diagnostics,
                StackBalanced = output.IsStackBalanced,
                InstructionCount = _instructions.Count,
            };
        }

        public void Dispose() => _scene.Dispose();

        // ------------------------------------------------------------------
        //  op → 指令
        // ------------------------------------------------------------------

        private void PlayOp(JsonElement op)
        {
            string kind = op.GetProperty("op").GetString();
            switch (kind)
            {
                case "rect":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = RectOf(op),
                        Brush = FillBrush(op),
                        Pen = PenOf(op),
                    });
                    break;

                case "roundrect":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRoundedRectangle,
                        Rect = RectOf(op),
                        CornerRadius = new SKPoint(DF(op, "rx"), DF(op, "ry")),
                        Brush = FillBrush(op),
                        Pen = PenOf(op),
                    });
                    break;

                case "ellipse":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawEllipse,
                        Point0 = new SKPoint(DF(op, "cx"), DF(op, "cy")),
                        CornerRadius = new SKPoint(DF(op, "rx"), DF(op, "ry")),
                        Brush = FillBrush(op),
                        Pen = PenOf(op),
                    });
                    break;

                case "line":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawLine,
                        Point0 = new SKPoint(DF(op, "x1"), DF(op, "y1")),
                        Point1 = new SKPoint(DF(op, "x2"), DF(op, "y2")),
                        Pen = PenOf(op),
                    });
                    break;

                case "path":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawGeometry,
                        Geometry = _scene.Mh(PathGeometry(op)),
                        Brush = FillBrush(op),
                        Pen = PenOf(op),
                    });
                    break;

                case "combine":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawGeometry,
                        Geometry = _scene.Mh(CombinedGeometry(op)),
                        Brush = FillBrush(op),
                        Pen = PenOf(op),
                    });
                    break;

                case "linearGradient":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = RectOf(op),
                        Brush = _scene.Mh(LinearGradient(op)),
                        // R.cs 的 MakePen(op) 对这个 op 恒为 null（"stroke": null）
                        Pen = PenOf(op),
                    });
                    break;

                case "radialGradient":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = RectOf(op),
                        Brush = _scene.Mh(RadialGradient(op)),
                        Pen = PenOf(op),
                    });
                    break;

                case "clip":
                {
                    // R.cs: 每个 clip 各 PushClip 一次（交集），children 画完再逐个 Pop
                    int n = 0;
                    foreach (JsonElement g in op.GetProperty("clips").EnumerateArray())
                    {
                        Add(new MilDrawInstruction
                        {
                            Command = MilDrawCommand.MilPushClip,
                            Geometry = _scene.Mh(GeometryOf(g)),
                        });
                        n++;
                    }

                    Play(op.GetProperty("children"));

                    for (int i = 0; i < n; i++)
                        Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                    break;
                }

                case "opacity":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilPushOpacity,
                        Opacity = op.GetProperty("value").GetDouble(),
                    });
                    Play(op.GetProperty("children"));
                    Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                    break;

                case "transform":
                    Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilPushTransform,
                        Geometry = _scene.Mh(new MilMatrixTransform
                        {
                            Matrix = Matrix3x2Of(op),
                        }),
                    });
                    Play(op.GetProperty("children"));
                    Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                    break;

                default:
                    throw new NotSupportedException($"scenes.json 里出现未支持的 op：{kind}");
            }
        }

        private void Add(MilDrawInstruction instr)
        {
            _instructions.Add(instr);
        }

        // ------------------------------------------------------------------
        //  画刷 / 画笔
        // ------------------------------------------------------------------

        private static SKRect RectOf(JsonElement op) => new SKRect(
            DF(op, "x"), DF(op, "y"), DF(op, "x") + DF(op, "w"), DF(op, "y") + DF(op, "h"));

        /// <summary>R.cs 的 MakeFill：Has(op,"fill") 为 false（缺键或 null）时无填充。</summary>
        private MilResourceHandle FillBrush(JsonElement op)
        {
            if (!TryString(op, "fill", out string hex)) return MilResourceHandle.Null;
            return _scene.Mh(new MilSolidColorBrush { Color = ColorOf(hex) });
        }

        /// <summary>R.cs 的 MakePen：缺键/null 无描边；WPF 的 Pen 默认值全部照抄。</summary>
        private MilResourceHandle PenOf(JsonElement op)
        {
            if (!TryString(op, "stroke", out string hex)) return MilResourceHandle.Null;

            var pen = new MilPen
            {
                Brush = _scene.Handle(new MilSolidColorBrush { Color = ColorOf(hex) }),
                Thickness = op.TryGetProperty("strokeWidth", out JsonElement sw) ? sw.GetDouble() : 1.0,
                // WPF `new Pen(brush, w)` 的默认值：两端 Flat、连接 Miter、MiterLimit 10、DashCap Flat
                StartLineCap = MilPenLineCap.Flat,
                EndLineCap = MilPenLineCap.Flat,
                DashCap = MilPenLineCap.Flat,
                LineJoin = MilPenLineJoin.Miter,
                MiterLimit = 10.0,
            };

            if (op.TryGetProperty("dash", out JsonElement dash) && dash.ValueKind == JsonValueKind.Array)
            {
                var style = new MilDashStyle
                {
                    Offset = op.TryGetProperty("dashOffset", out JsonElement off) ? off.GetDouble() : 0.0,
                };
                foreach (JsonElement d in dash.EnumerateArray()) style.Dashes.Add(d.GetDouble());
                pen.DashStyle = _scene.Handle(style);
            }

            if (TryString(op, "dashCap", out string cap)) pen.DashCap = CapOf(cap);
            if (TryString(op, "startCap", out string sc)) pen.StartLineCap = CapOf(sc);
            if (TryString(op, "endCap", out string ec)) pen.EndLineCap = CapOf(ec);
            if (TryString(op, "lineJoin", out string lj)) pen.LineJoin = JoinOf(lj);
            if (op.TryGetProperty("miterLimit", out JsonElement ml)) pen.MiterLimit = ml.GetDouble();

            return _scene.Mh(pen);
        }

        private static MilPenLineCap CapOf(string s) => s switch
        {
            "flat" => MilPenLineCap.Flat,
            "round" => MilPenLineCap.Round,
            "square" => MilPenLineCap.Square,
            "triangle" => MilPenLineCap.Triangle,
            _ => throw new NotSupportedException("未知线帽 " + s),
        };

        private static MilPenLineJoin JoinOf(string s) => s switch
        {
            "miter" => MilPenLineJoin.Miter,
            "bevel" => MilPenLineJoin.Bevel,
            "round" => MilPenLineJoin.Round,
            _ => throw new NotSupportedException("未知连接 " + s),
        };

        private MilLinearGradientBrush LinearGradient(JsonElement op)
        {
            JsonElement sp = op.GetProperty("start");
            JsonElement ep = op.GetProperty("end");

            var brush = new MilLinearGradientBrush
            {
                StartPoint = new MilPoint(sp[0].GetDouble(), sp[1].GetDouble()),
                EndPoint = new MilPoint(ep[0].GetDouble(), ep[1].GetDouble()),
                MappingMode = MappingModeOf(op),
                SpreadMethod = SpreadOf(op),
                // R.cs 没设 ColorInterpolationMode → WPF 默认 ScRgbLinearInterpolation(0)。
                // 真机实测（scene04 中点 128）证明 WPF 实际在 sRGB 空间插值——这一条由
                // SkiaBrush 的实现方式决定，见 ParityTests 的结论 1 用例。
                ColorInterpolationMode = MilColorInterpolationMode.ScRgbLinearInterpolation,
            };
            AddStops(brush.GradientStops, op);
            return brush;
        }

        private MilRadialGradientBrush RadialGradient(JsonElement op)
        {
            JsonElement ce = op.GetProperty("center");
            JsonElement or = op.GetProperty("origin");
            JsonElement ra = op.GetProperty("radius");

            var brush = new MilRadialGradientBrush
            {
                Center = new MilPoint(ce[0].GetDouble(), ce[1].GetDouble()),
                GradientOrigin = new MilPoint(or[0].GetDouble(), or[1].GetDouble()),
                RadiusX = ra[0].GetDouble(),
                RadiusY = ra[1].GetDouble(),
                MappingMode = MappingModeOf(op),
                SpreadMethod = SpreadOf(op),
                ColorInterpolationMode = MilColorInterpolationMode.ScRgbLinearInterpolation,
            };
            AddStops(brush.GradientStops, op);
            return brush;
        }

        private static void AddStops(List<MilGradientStop> target, JsonElement op)
        {
            foreach (JsonElement s in op.GetProperty("stops").EnumerateArray())
                target.Add(new MilGradientStop(
                    s.GetProperty("offset").GetDouble(), ColorOf(s.GetProperty("color").GetString())));
        }

        private static MilBrushMappingMode MappingModeOf(JsonElement op) =>
            op.TryGetProperty("mapping", out JsonElement m) && m.GetString() == "relative"
                ? MilBrushMappingMode.RelativeToBoundingBox
                : MilBrushMappingMode.Absolute;

        private static MilGradientSpreadMethod SpreadOf(JsonElement op)
        {
            if (!op.TryGetProperty("spread", out JsonElement s)) return MilGradientSpreadMethod.Pad;
            return s.GetString() switch
            {
                "reflect" => MilGradientSpreadMethod.Reflect,
                "repeat" => MilGradientSpreadMethod.Repeat,
                _ => MilGradientSpreadMethod.Pad,
            };
        }

        // ------------------------------------------------------------------
        //  几何
        // ------------------------------------------------------------------

        private MilGeometry GeometryOf(JsonElement g)
        {
            switch (g.GetProperty("g").GetString())
            {
                case "rect":
                    return new MilRectangleGeometry
                    {
                        Rect = new MilRect(
                            g.GetProperty("x").GetDouble(), g.GetProperty("y").GetDouble(),
                            g.GetProperty("w").GetDouble(), g.GetProperty("h").GetDouble()),
                    };

                case "ellipse":
                    return new MilEllipseGeometry
                    {
                        Center = new MilPoint(
                            g.GetProperty("cx").GetDouble(), g.GetProperty("cy").GetDouble()),
                        RadiusX = g.GetProperty("rx").GetDouble(),
                        RadiusY = g.GetProperty("ry").GetDouble(),
                    };

                case "path":
                    return PathGeometry(g);

                default:
                    throw new NotSupportedException("未知几何 " + g.GetProperty("g").GetString());
            }
        }

        /// <summary>R.cs 的 MakePathGeometry：FillRule 默认 EvenOdd（WPF PathGeometry 的默认值）。</summary>
        private MilPathGeometry PathGeometry(JsonElement op)
        {
            var builder = new ParityPathBuilder();

            foreach (JsonElement fig in op.GetProperty("figures").EnumerateArray())
            {
                JsonElement sp = fig.GetProperty("start");
                bool closed = !fig.TryGetProperty("closed", out JsonElement c) || c.GetBoolean();
                bool filled = !fig.TryGetProperty("filled", out JsonElement f) || f.GetBoolean();

                ParityPathBuilder.Figure b = builder.AddFigure(
                    sp[0].GetDouble(), sp[1].GetDouble(), closed, filled);

                foreach (JsonElement seg in fig.GetProperty("segments").EnumerateArray())
                {
                    JsonElement to = seg.GetProperty("to");
                    switch (seg.GetProperty("seg").GetString())
                    {
                        case "line":
                            b.Line(to[0].GetDouble(), to[1].GetDouble());
                            break;
                        case "arc":
                            b.Arc(
                                to[0].GetDouble(), to[1].GetDouble(),
                                seg.GetProperty("rx").GetDouble(), seg.GetProperty("ry").GetDouble(),
                                seg.TryGetProperty("rot", out JsonElement rot) ? rot.GetDouble() : 0.0,
                                seg.TryGetProperty("largeArc", out JsonElement la) && la.GetBoolean(),
                                seg.GetProperty("sweep").GetString() == "cw");
                            break;
                        default:
                            throw new NotSupportedException(
                                "未知段 " + seg.GetProperty("seg").GetString());
                    }
                }

                b.End();
            }

            MilFillRule rule = TryString(op, "fillRule", out string fr) && fr == "nonzero"
                ? MilFillRule.Nonzero : MilFillRule.EvenOdd;

            return new MilPathGeometry { SerializedData = builder.Build(), FillRule = rule };
        }

        private MilCombinedGeometry CombinedGeometry(JsonElement op)
        {
            MilGeometry a = GeometryOf(op.GetProperty("a"));
            MilGeometry b = GeometryOf(op.GetProperty("b"));

            return new MilCombinedGeometry
            {
                GeometryCombineMode = op.GetProperty("mode").GetString() switch
                {
                    "union" => MilGeometryCombineMode.Union,
                    "intersect" => MilGeometryCombineMode.Intersect,
                    "xor" => MilGeometryCombineMode.Xor,
                    "exclude" => MilGeometryCombineMode.Exclude,
                    _ => throw new NotSupportedException("未知组合模式"),
                },
                Geometry1 = _scene.Handle(a),
                Geometry2 = _scene.Handle(b),
            };
        }

        // ------------------------------------------------------------------
        //  辅助
        // ------------------------------------------------------------------

        /// <summary>WPF 矩阵（行向量，[m11,m12,m21,m22,dx,dy]）→ MilMatrix3x2D。</summary>
        private static MilMatrix3x2D Matrix3x2Of(JsonElement op)
        {
            // R.cs: m = Matrix.Multiply(m, t) 逐个复合；scenes.json 里附带的 "composite"
            // 就是这个乘积（double 精度）。有 composite 就用它，没有才自己乘。
            if (op.TryGetProperty("composite", out JsonElement comp) && comp.ValueKind == JsonValueKind.Array)
            {
                return new MilMatrix3x2D(
                    comp[0].GetDouble(), comp[1].GetDouble(),
                    comp[2].GetDouble(), comp[3].GetDouble(),
                    comp[4].GetDouble(), comp[5].GetDouble());
            }

            SKMatrix acc = SKMatrix.Identity;
            foreach (JsonElement raw in op.GetProperty("matrices").EnumerateArray())
            {
                SKMatrix t = TransformResolver.FromMil(new MilMatrix3x2D(
                    raw[0].GetDouble(), raw[1].GetDouble(),
                    raw[2].GetDouble(), raw[3].GetDouble(),
                    raw[4].GetDouble(), raw[5].GetDouble()));
                acc = TransformResolver.Mul(acc, t);
            }

            return new MilMatrix3x2D(
                acc.ScaleX, acc.SkewY, acc.SkewX, acc.ScaleY, acc.TransX, acc.TransY);
        }

        /// <summary>#AARRGGBB → MilColorF（scRGB），与 TestScene.Solid 同一条转换。</summary>
        internal static MilColorF ColorOf(string hex)
        {
            if (string.IsNullOrEmpty(hex) || hex[0] != '#' || hex.Length != 9)
                throw new FormatException("颜色必须是 #AARRGGBB，收到 " + (hex ?? "null"));

            uint v = uint.Parse(hex.Substring(1), NumberStyles.HexNumber, CultureInfo.InvariantCulture);
            byte a = (byte)(v >> 24);
            byte r = (byte)((v >> 16) & 0xFF);
            byte g = (byte)((v >> 8) & 0xFF);
            byte b = (byte)(v & 0xFF);
            return SkiaColor.MakeScRgb(r, g, b, a);
        }

        /// <summary>按 R.cs 的 J.Has 口径取字符串：缺键或 null 都算"没有"。</summary>
        private static bool TryString(JsonElement op, string name, out string value)
        {
            value = null;
            if (!op.TryGetProperty(name, out JsonElement e)) return false;
            if (e.ValueKind != JsonValueKind.String) return false;
            value = e.GetString();
            return true;
        }

        private static float DF(JsonElement op, string name) =>
            (float)op.GetProperty(name).GetDouble();
    }
}

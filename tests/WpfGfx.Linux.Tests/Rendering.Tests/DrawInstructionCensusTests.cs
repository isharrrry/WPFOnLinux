// DrawInstructionCensus（D-c 归因仪表）的自验用例（T2b）。
//
// 判据与 GlyphRunCensus 同族：① 计数算得对；② 几何行的**设备包围盒**真的算得对
// （这是 D-c 用来区分"视口外/尺寸为 0"的那一列，算错了整条归因就错）；
// ③ 关掉时纹丝不动（不扰动）。合成场景的图形是编的，不代表真机 —— 真值要等部署件带普查重跑。

using System.Collections.Generic;
using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class DrawInstructionCensusTests
    {
        public DrawInstructionCensusTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        [Fact]
        public void census_counts_commands_and_maps_geometry_to_device()
        {
            DrawInstructionCensus.ForceEnabled(true);
            try
            {
                using var scene = new TestScene();
                DUCE.ResourceHandle fill = scene.Solid(0xD0, 0x20, 0x20);
                DUCE.ResourceHandle geo = scene.RectGeometry(20, 10, 30, 15);

                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d =>
                {
                    // 一个矩形（走 FillAndStroke 的矩形分支）
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawRectangle,
                        Rect = new SKRect(5, 5, 25, 20),
                        Brush = new MilResourceHandle((uint)fill),
                    });
                    // 一个几何绘制（走 MilDrawGeometry）
                    d.Add(new MilDrawInstruction
                    {
                        Command = MilDrawCommand.MilDrawGeometry,
                        Geometry = new MilResourceHandle((uint)geo),
                        Brush = new MilResourceHandle((uint)fill),
                    });
                });

                RenderHarness.Render(root, scene.Provider, 80, 60, antialias: true);

                IReadOnlyDictionary<MilDrawCommand, int> counts = DrawInstructionCensus.LastCounts;
                IReadOnlyList<string> geom = DrawInstructionCensus.LastGeometryLines;

                foreach (KeyValuePair<MilDrawCommand, int> kv in counts)
                    Output.WriteLine($"  {kv.Key} = {kv.Value}");
                foreach (string line in geom) Output.WriteLine("  " + line);

                Assert.Equal(1, counts[MilDrawCommand.MilDrawRectangle]);
                Assert.Equal(1, counts[MilDrawCommand.MilDrawGeometry]);

                // 几何行：矩形 (5,5,25,20) 与几何 (20,10,30,15) 都必须出现，
                // 且设备包围盒要等于局部包围盒（本场景无变换 ⇒ 设备==局部）。
                Assert.Equal(2, geom.Count);
                Assert.Contains("(5.0,5.0,20.0x15.0)", geom[0]);
                Assert.Contains("(20.0,10.0,30.0x15.0)", geom[1]);
                Assert.Contains("设备=(5.0,5.0,20.0x15.0)", geom[0]);
                Assert.Contains("设备=(20.0,10.0,30.0x15.0)", geom[1]);
                Assert.DoesNotContain("尺寸为 0", geom[0]);
            }
            finally { DrawInstructionCensus.ForceEnabled(false); }
        }

        /// <summary>尺寸为 0 的几何必须被显式标出来 —— D-c 的 (b) 假设就靠这一列判。</summary>
        [Fact]
        public void census_flags_zero_sized_geometry()
        {
            DrawInstructionCensus.ForceEnabled(true);
            try
            {
                using var scene = new TestScene();
                DUCE.ResourceHandle fill = scene.Solid(0, 0, 0);
                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(5, 5, 5, 5),      // 宽高为 0
                    Brush = new MilResourceHandle((uint)fill),
                }));

                RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);

                IReadOnlyList<string> geom = DrawInstructionCensus.LastGeometryLines;
                // 本用例造的是"局部 0×0 + CTM 单位阵" ⇒ 设备为 0 的**因是局部**，
                // 不该被说成"零缩放 CTM"（那会混因）。故这里断言"局部尺寸为 0"且**不**断言零缩放。
                Assert.Single(geom);
                Output.WriteLine("  " + geom[0]);
                Assert.Contains("局部尺寸为 0", geom[0]);
                Assert.Contains("不是零缩放 CTM", geom[0]);
                Assert.DoesNotContain("零缩放 CTM**（CTM", geom[0]);
            }
            finally { DrawInstructionCensus.ForceEnabled(false); }
        }

        [Fact]
        public void census_is_inert_when_disabled()
        {
            DrawInstructionCensus.ForceEnabled(false);
            try
            {
                using var scene = new TestScene();
                DUCE.ResourceHandle fill = scene.Solid(0, 0, 0);
                MilVisual root = scene.Visual();
                root.Content = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 10, 10),
                    Brush = new MilResourceHandle((uint)fill),
                }));
                RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);
                Assert.Empty(DrawInstructionCensus.LastCounts);
                Assert.Empty(DrawInstructionCensus.LastGeometryLines);
            }
            finally { DrawInstructionCensus.ForceEnabled(false); }
        }
    }
}

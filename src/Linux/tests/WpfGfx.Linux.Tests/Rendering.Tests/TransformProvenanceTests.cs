// 变换来源留痕（零缩放 CTM 归因）的自验用例（T2b）。
//
// 【它验什么】
//   ① 投影时确实把"变换资源句柄 + 解析前原始值"带出来了（不是只带解析后的矩阵）；
//   ② 原始值里 **0 与非 0 打得出来**（`**0**` 标记）—— 这是判"上游发的 0"还是"我们解析出的 0"的唯一依据；
//   ③ 缺省关时**一个字节都不记**（`Lookup` 恒 null）；
//   ④ 端到端：退化绘制的祖链行里真的出现那份资源的原始值。
//
// 【合成场景的 0 是编的，不代表真机】本用例只验"仪表会不会说谎"，真机读数要等部署件带这一版重跑。

using System;
using System.Collections.Generic;
using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class TransformProvenanceTests
    {
        public TransformProvenanceTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        /// <summary>① 原始值被带出来，且 0 与非 0 分得清。</summary>
        [Fact]
        public void records_raw_scale_values_including_zero()
        {
            TransformProvenance.ForceEnabledForTest(true);
            try
            {
                using var scene = new TestScene();
                DUCE.ResourceHandle zero = scene.Add(new MilScaleTransform { ScaleX = 0.0, ScaleY = 0.0 });
                DUCE.ResourceHandle one = scene.Add(new MilScaleTransform { ScaleX = 1.04, ScaleY = 1.04 });

                string dZero = TransformProvenance.Describe(scene.Channel, zero);
                string dOne = TransformProvenance.Describe(scene.Channel, one);
                Output.WriteLine("  zero: " + dZero);
                Output.WriteLine("  one : " + dOne);

                Assert.Contains("类型=Scale", dZero);
                Assert.Contains("ScaleX=**0**", dZero);        // 退化值必须显眼
                Assert.Contains("ScaleY=**0**", dZero);
                Assert.Contains("ScaleX=1.04", dOne);
                // ⚠ 这里原来写的是 DoesNotContain("**0**", dOne) —— **断言写松了**：
                //   `CenterX` 本来就是 0，会被标成 **0**，于是那条断言必然红。
                //   要断言的是"**scale 不为 0**"，不是"字符串里不出现 0"。
                Assert.DoesNotContain("ScaleX=**0**", dOne);
                Assert.DoesNotContain("ScaleY=**0**", dOne);
                Assert.Contains("CenterX=**0**", dOne);        // 这一位**是** 0，就该被标出来
            }
            finally { TransformProvenance.ForceEnabledForTest(false); }
        }

        /// <summary>② 查不到资源时报"无信息"，不报 0（本项目最富的一族）。</summary>
        [Fact]
        public void unknown_handle_reports_no_information_not_zero()
        {
            TransformProvenance.ForceEnabledForTest(true);
            try
            {
                using var scene = new TestScene();
                string d = TransformProvenance.Describe(scene.Channel, new DUCE.ResourceHandle(0xDEADBEEF));
                Output.WriteLine("  " + d);
                Assert.Contains("无信息", d);
                Assert.DoesNotContain("ScaleX=**0**", d);
            }
            finally { TransformProvenance.ForceEnabledForTest(false); }
        }

        /// <summary>③ 缺省关：不记、也查不到。</summary>
        [Fact]
        public void disabled_records_nothing()
        {
            TransformProvenance.ForceEnabledForTest(false);
            TransformProvenance.Reset();
            using var scene = new TestScene();
            DUCE.ResourceHandle t = scene.Add(new MilScaleTransform { ScaleX = 0, ScaleY = 0 });
            TransformProvenance.Record(scene.Channel, 0x1234u, t);
            Assert.Null(TransformProvenance.Lookup(0x1234u));
        }

        /// <summary>④ 端到端：退化绘制的祖链行里真的出现那份变换资源的原始值。</summary>
        [Fact]
        public void degenerate_draw_chain_shows_raw_transform_resource()
        {
            TransformProvenance.ForceEnabledForTest(true);
            DrawInstructionCensus.ForceEnabled(true);
            try
            {
                using var scene = new TestScene();

                // 一个真 Visual：自己的 Transform 是 Scale(0,0)（模拟真机的退化那一代）
                DUCE.ResourceHandle scaleZero = scene.Add(new MilScaleTransform { ScaleX = 0.0, ScaleY = 0.0 });
                DUCE.ResourceHandle fill = scene.Solid(0xD0, 0x20, 0x20);
                Commands.MilRenderData decoded = scene.RenderData(d => d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilDrawRectangle,
                    Rect = new SKRect(0, 0, 30, 20),
                    Brush = new MilResourceHandle((uint)fill),
                }));
                DUCE.ResourceHandle content = scene.Add(new MilRenderDataResource { RenderData = decoded });

                var res = new MilVisualResource();
                DUCE.ResourceHandle vis = scene.Add(res);
                res.Visual.Handle = vis;
                res.Visual.Content = content;
                res.Visual.Transform = scaleZero;

                MilVisual root = VisualProjection.Project(scene.Channel, vis);
                Assert.NotNull(root);

                RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);

                IReadOnlyList<string> lines = DrawInstructionCensus.LastGeometryLines;
                string all = string.Join("\n", lines);
                Output.WriteLine(all);

                // 祖链那一行必须带出**原始资源值**（0 要显眼）
                Assert.Contains("类型=Scale", all);
                Assert.Contains("ScaleX=**0**", all);
                Assert.Contains("零引入点=", all);
                Assert.Contains("零来自这一代自己的变换", all);
            }
            finally
            {
                DrawInstructionCensus.ForceEnabled(false);
                TransformProvenance.ForceEnabledForTest(false);
            }
        }
    }
}

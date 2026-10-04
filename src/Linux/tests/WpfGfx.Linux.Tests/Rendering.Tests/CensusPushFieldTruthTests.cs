// census `PushTransform=` 字段"两个方向都要可信"的牙（T2b，2026-09-13，主控批准项 B）。
//
// 【要钉住的不变量】
//   `CurrentVisualProvenance` 的 `PushTransform=` 必须反映**此刻真正生效的**内容级变换：
//     · 有生效的 push        ⇒ 报**那个句柄**（不能报"无"）；
//     · push 已被 pop 掉之后 ⇒ 报 **`无`**（不能报**陈旧句柄**）。
//   两个方向都可信，字段才能当判据用；只可信一个方向 = 仪表与被测对象不同步。
//
// 【当前为什么不满足】`DrawInstructionCensus.PopTransform()` **零调用点**，而 `MilPop` 只做
//   `canvas.Restore()`、不通知 census ⇒ 一帧内任何 push 都**永久留在栈上** ⇒ pop 之后画的东西
//   仍会读到**陈旧句柄**。本牙就是按这个序列构造的：`Push → 画 → Pop → 再画`。
//
// 【为什么不能"见 MilPop 就 PopTransform()"】`MilPop` 是**万能 pop**，弹的画布状态可能是
//   clip/opacity/effect/guideline 里的任何一种；盲目弹变换栈会在"推了非变换、弹一次"时
//   把**仍然生效**的变换弹掉 ⇒ 反而制造新的不一致。

using SkiaSharp;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Rendering
{
    public class CensusPushFieldTruthTests
    {
        public CensusPushFieldTruthTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        private static MilDrawInstruction Rect(float x, float y, wpfSize s, DUCE.ResourceHandle brush) =>
            new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(x, y, x + s.W, y + s.H),
                Brush = new MilResourceHandle((uint)brush),
            };

        private readonly struct wpfSize
        {
            public wpfSize(float w, float h) { W = w; H = h; }
            public float W { get; }
            public float H { get; }
        }

        /// <summary>
        /// 两种仪表形态**必须都数**（这也是本条牙暴露出来的另一处不一致）：
        ///   · 几何行：`来源=PushTransform(0x…) [矩阵]`（有变换在生效）/ `来源=visual=0x…`（无变换在生效）；
        ///   · 字形行：` PushTransform=0x…` / ` PushTransform=无`。
        /// </summary>
        private static (int InEffect, int NotInEffect) CountPushFields()
        {
            int inEffect = 0, notInEffect = 0;
            foreach (string line in DrawInstructionCensus.LastGeometryLines)
            {
                if (line.Contains("来源=PushTransform(")) { inEffect++; continue; }
                if (line.Contains("来源=visual="))
                {
                    int i = line.IndexOf(" PushTransform=", System.StringComparison.Ordinal);
                    if (i >= 0 && line.Substring(i + " PushTransform=".Length).StartsWith("无"))
                        notInEffect++;
                    else if (i < 0)
                        notInEffect++;          // 旧格式：无该字段即"无变换在生效"
                    else
                        inEffect++;
                }
            }
            return (inEffect, notInEffect);
        }

        /// <summary>
        /// `Push → 画 → Pop → 再画`：pop 之后那一笔的 `PushTransform=` 必须是 `无`。
        /// 同时要求 push 期间那一笔**报出句柄**（否则"总是打无"也能骗过第一条）。
        /// </summary>
        // 先红读数（2026-09-13，修 B 之前实测，留作对照）：
        //   `Push → 画 → Pop → 再画` 序列下，pop 之后那一笔的诊断行里
        //   `CTM=[1.00,0.00,0.00,1.00,…]`（画布已还原）与 `来源=PushTransform(0x00000002) [2.00,…]` **同在一行**
        //   ⇒ 画布已撤销变换，仪表却仍声称它生效；计数「变换在生效 2 行 / 未生效 0 行」。
        //   修后（按压栈深度裁栈）该行应变成 `来源=visual=…` / `PushTransform=无`。
        [Fact]
        public void push_transform_field_reports_none_after_pop()
        {
            using var scene = new TestScene();
            DUCE.ResourceHandle brush = scene.Solid(0, 0, 0);
            DUCE.ResourceHandle scale2 = scene.Scale(2.0, 2.0);

            MilVisual v = scene.Visual();
            v.Content = scene.RenderData(d =>
            {
                d.Add(new MilDrawInstruction
                {
                    Command = MilDrawCommand.MilPushTransform,
                    Geometry = new MilResourceHandle((uint)scale2),
                });
                d.Add(Rect(0, 0, new wpfSize(10, 10), brush));      // ← push 生效期间
                d.Add(new MilDrawInstruction { Command = MilDrawCommand.MilPop });
                d.Add(Rect(40, 0, new wpfSize(10, 10), brush));     // ← pop 之后
            });

            DrawInstructionCensus.ForceEnabled(true);
            try
            {
                using SKBitmap bmp = RenderHarness.RenderBitmap(v, scene.Provider, 120, 40, antialias: false);
                Assert.NotNull(bmp);
                (int inEffect, int notInEffect) = CountPushFields();
                Output.WriteLine($"  几何行：变换在生效 {inEffect} 行 / 未生效 {notInEffect} 行（共 " +
                                 $"{DrawInstructionCensus.LastGeometryLines.Count} 行）");
                foreach (string line in DrawInstructionCensus.LastGeometryLines)
                    Output.WriteLine("    " + line);

                Assert.True(inEffect > 0,
                    "push 生效期间那一笔都没报出变换 ⇒ 字段只会报「无」，第一个方向就不可信。");
                Assert.True(notInEffect > 0,
                    "`Pop` 之后画的那一笔仍报着**陈旧变换**（没有任何一行报「无变换在生效」）⇒ " +
                    "字段在「已 pop」这个方向上会撒谎：它会让人以为变换还生效。" +
                    "根因：`PopTransform()` 零调用点，而 `MilPop` 不通知 census。");
            }
            finally { DrawInstructionCensus.ForceEnabled(false); }
        }
    }
}

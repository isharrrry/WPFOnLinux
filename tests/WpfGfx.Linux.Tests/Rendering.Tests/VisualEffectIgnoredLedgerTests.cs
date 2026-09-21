// 「视觉级效果被接受但从不被消费」的**台账牙**（波70 · `D-G71` / `TASK-0403`）。
//
// 【它挡什么缺陷】
//   `MilCmdVisualSetEffect(0x1d)` 从 `#49` 之前就在**收**（返回 `S_OK`、不 abort），但
//   `MilVisualNode.Effect` **全仓只有一个写入点**（`Commands/MilCommandDispatcher.cs`，本件改后
//   `:173-192`）＋ 一个**单元测试**读它（`Commands.Tests/CommandRoundTripTests.cs:89`）；
//   投影层（`Resources/VisualProjection.cs`）根本不看它，契约类型 `MilVisual`
//   （`Contracts/Interfaces.cs`）**连 `Effect` 字段都没有** ⇒ 效果在投影那一跳就丢了。
//   ⇒ 真机形态：hc 的 `Effects` 页发了 11 条 `0x1d`（`build/MilBridge/W62A-report.md`），
//      画面**没有任何效果**，而**没有任何一本账**记着这件事（对比 `MilPushEffect`(0x55) 那条路
//      有 `Diagnostics.RecordNotDrawn` 台账）＝「静默 no-op」，正是本仓反复登记的那一族。
//
// 【本件只做"可见化"，不做"消费"】
//   这三条用例钉的是：① 台账**看得见**且字段齐（命令号 `0x1d` ＋ 该视觉句柄 ＋ 效果句柄）；
//   ② 不许把"清除效果"（`hEffect == Null`）误记成"效果被丢弃"；③ **零判据位移** ——
//   `未画种类`/`NotDrawn` 必须**仍是 0**（它是一条**冻死的验收判据**的输入，见
//   `build/MilBridge/W70D-report.md` §2：走那一支会把 `WpfTextDemo` 判据②打红）。
//
// 【先红后绿怎么验（反极性）】
//   把 `MilCommandDispatcher.cs` 里那一行 `ch.NoteVisualEffectIgnored(se.Handle, se.HEffect);`
//   **注释掉** ⇒ 用例① 必须**红**（条目数回到 0），用例②③ 仍绿（它们断言的是"不许记"与"零位移"）。
//   还原 ⇒ 用例① 回绿。读数见报告 §4。

using System;
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
    public class VisualEffectIgnoredLedgerTests
    {
        public VisualEffectIgnoredLedgerTests(ITestOutputHelper output) => Output = output;
        private ITestOutputHelper Output { get; }

        /// <summary>造一个视觉资源（带句柄）＋ 一个效果资源句柄。</summary>
        private static (MilVisualResource Node, DUCE.ResourceHandle Visual, DUCE.ResourceHandle Effect)
            MakeVisualWithEffect(TestScene scene)
        {
            var node = new MilVisualResource();
            DUCE.ResourceHandle visual = scene.Add(node);
            node.Visual.Handle = visual;
            DUCE.ResourceHandle effect = scene.Add(new MilOpaqueResource(DUCE.ResourceType.TYPE_BLUREFFECT));
            return (node, visual, effect);
        }

        private static readonly MilCommandDispatcher Dispatcher = new MilCommandDispatcher();

        // ───────────────────────── ① 看得见且字段齐 ─────────────────────────
        [Fact]
        public void set_effect_is_recorded_with_command_id_visual_and_effect_handles()
        {
            using var scene = new TestScene();
            (MilVisualResource node, DUCE.ResourceHandle visual, DUCE.ResourceHandle effect) =
                MakeVisualWithEffect(scene);

            int hr = Dispatcher.Dispatch(MilCommandEncoder.VisualSetEffect(visual, effect), scene.Channel);

            // (a) 现有行为**逐字不变**：字段照写（本件是纯加法）
            Assert.Equal(HResult.S_OK, hr);
            Assert.Equal(effect, node.Visual.Effect);

            // (b) 台账看得见：条目数 ＋ 逐视觉明细 ＋ 那一行本身
            Assert.Equal(1, scene.Channel.VisualEffectIgnoredCommands);
            Assert.Equal(1, scene.Channel.VisualEffectIgnoredByVisual[visual]);
            string line = Assert.Single(scene.Channel.VisualEffectIgnoredLines);
            Output.WriteLine("  台账行: " + line);

            // (c) 三个必备字段逐字在行里（命令号 / 该视觉的句柄 / 效果句柄）
            Assert.Contains("id=0x1d", line);
            Assert.Contains("MilCmdVisualSetEffect", line);
            Assert.Contains($"visual=0x{visual.Value:x8}", line);
            Assert.Contains($"effect=0x{effect.Value:x8}", line);
            Assert.Contains("接受但不消费", line);
        }

        // ───────────── ② 「清除效果」与非 0x1d 命令**不许**入账 ─────────────
        [Fact]
        public void null_effect_clear_and_other_commands_do_not_enter_the_ledger()
        {
            using var scene = new TestScene();
            (MilVisualResource node, DUCE.ResourceHandle visual, DUCE.ResourceHandle effect) =
                MakeVisualWithEffect(scene);

            // 上游清效果就是发 `SetEffect(handle, Null)`（`upstream/…/Media/Visual.cs:1445`）
            Dispatcher.Dispatch(MilCommandEncoder.VisualSetEffect(visual, DUCE.ResourceHandle.Null), scene.Channel);
            Assert.Equal(DUCE.ResourceHandle.Null, node.Visual.Effect);
            Assert.True(DUCE.ResourceHandle.Null.IsNull);

            // 别的命令当然更不许入账（防"随便挂个计数"的假台账）
            DUCE.ResourceHandle xform = scene.Add(new MilOpaqueResource(DUCE.ResourceType.TYPE_MATRIXTRANSFORM));
            Dispatcher.Dispatch(MilCommandEncoder.VisualSetTransform(visual, xform), scene.Channel);
            Dispatcher.Dispatch(MilCommandEncoder.VisualSetAlpha(visual, 0.5), scene.Channel);

            Assert.Equal(0, scene.Channel.VisualEffectIgnoredCommands);
            Assert.Empty(scene.Channel.VisualEffectIgnoredLines);

            // 真效果再来一条 ⇒ 记 2 条、逐视觉计数 = 2（证明计数是按视觉累加的，不是"记过就不再记"）
            Dispatcher.Dispatch(MilCommandEncoder.VisualSetEffect(visual, effect), scene.Channel);
            Dispatcher.Dispatch(MilCommandEncoder.VisualSetEffect(visual, effect), scene.Channel);
            Assert.Equal(2, scene.Channel.VisualEffectIgnoredCommands);
            Assert.Equal(2, scene.Channel.VisualEffectIgnoredByVisual[visual]);
            Assert.Equal(2, scene.Channel.VisualEffectIgnoredLines.Count);
        }

        // ───────── ③ 零判据位移：`未画种类` 必须仍是 0（③ 是本件的红线）─────────
        [Fact]
        public void ledger_entry_does_not_move_the_not_drawn_counter()
        {
            using var scene = new TestScene();
            (MilVisualResource node, DUCE.ResourceHandle visual, DUCE.ResourceHandle effect) =
                MakeVisualWithEffect(scene);

            // 该视觉**有真内容**（红矩形）：不这样，下面的"未画 0"就是**空真**
            DUCE.ResourceHandle red = scene.Solid(0xD0, 0x20, 0x20);
            var rd = scene.RenderData(d => d.Add(new MilDrawInstruction
            {
                Command = MilDrawCommand.MilDrawRectangle,
                Rect = new SKRect(0, 0, 40, 30),
                Brush = new MilResourceHandle((uint)red),
            }));
            node.Visual.Content = scene.Add(new MilRenderDataResource { RenderData = rd });

            // 效果就挂在这个视觉上（走的就是真命令那条路）
            Dispatcher.Dispatch(MilCommandEncoder.VisualSetEffect(visual, effect), scene.Channel);
            Assert.Equal(1, scene.Channel.VisualEffectIgnoredCommands);

            MilVisual root = VisualProjection.Project(scene.Channel, visual);
            Assert.NotNull(root);
            RenderOutput r = RenderHarness.Render(root, scene.Provider, 40, 30, antialias: true);

            SKColor px = r.Bitmap.GetPixel(20, 15);
            long notDrawn = 0;
            foreach (var kv in r.Diagnostics.NotDrawn) notDrawn += kv.Value;
            Output.WriteLine($"  中心像素=#{px.Red:X2}{px.Green:X2}{px.Blue:X2} 未画种类={r.Diagnostics.NotDrawn.Count}" +
                             $" 未画总数={notDrawn} 摘要='{r.Diagnostics.NotDrawnSummary()}' 台账={scene.Channel.VisualEffectIgnoredCommands}");

            // 对照先立"这台装置真画了东西"（否则"未画 0"可能是"什么都没画"这个空真）
            Assert.True(px.Red == 0xD0 && px.Green == 0x20 && px.Blue == 0x20,
                $"装置不对：内容没画出来（中心={px}）。");

            // 红线：可见化**不许**动 `未画种类`（它是一条冻死的验收判据的输入）
            Assert.Empty(r.Diagnostics.NotDrawn);
            Assert.Equal(string.Empty, r.Diagnostics.NotDrawnSummary());
            Assert.Equal(0, notDrawn);
        }

        // ───────── ④ 有界：逐条打印有上限，触顶**会说话**（不静默截断）─────────
        [Fact]
        public void ledger_printing_is_bounded_and_reports_when_capped()
        {
            using var scene = new TestScene();
            (_, DUCE.ResourceHandle visual, DUCE.ResourceHandle effect) = MakeVisualWithEffect(scene);

            for (int i = 0; i < 40; i++)
                Dispatcher.Dispatch(MilCommandEncoder.VisualSetEffect(visual, effect), scene.Channel);

            // 累计条数**不许**被上限吃掉
            Assert.Equal(40, scene.Channel.VisualEffectIgnoredCommands);
            Assert.Equal(40, scene.Channel.VisualEffectIgnoredByVisual[visual]);

            // 打印有界：32 条明细 ＋ 1 行"到上限"，且末行**明说**后面还有
            Assert.Equal(33, scene.Channel.VisualEffectIgnoredLines.Count);
            string last = scene.Channel.VisualEffectIgnoredLines[^1];
            Output.WriteLine("  触顶行: " + last);
            Assert.Contains("已到上限", last);
            Assert.Contains("不是", last.Replace("**", string.Empty));
        }
    }
}

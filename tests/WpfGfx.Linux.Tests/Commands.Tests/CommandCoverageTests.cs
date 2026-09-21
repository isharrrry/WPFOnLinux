// Licensed to the .NET Foundation under one or more agreements.
//
// 118 条顶层命令的**覆盖率核对**。
//
// 这份测试存在的唯一目的：让报告里的「x/118」这个数字无法靠嘴说。
// 它做的是穷举——把 MilCmd 枚举的每一个值都喂给分发器，然后机械判定：
//
//   · 返回 E_NOTIMPL 的，必须能在 MilCommandLayout 的登记表里查到
//     （否则就是「悄悄吞掉的命令」，属于必须暴露的漏洞）
//   · 登记在表里的，必须真的返回 E_NOTIMPL
//     （否则登记表在虚报未实现）
//   · 两者相加必须等于 118
//
// 枚举本身也钉死 118 条，并校验 MilCmd 与 MilDrawCommand 无重叠
// （handoff §1 的易错点：143 条里前 118 是顶层命令，后 25 是 RenderData 绘图指令）。

using System;
using System.Collections.Generic;
using System.Linq;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using Xunit;

namespace WpfGfx.Linux.Tests.Commands
{
    public class CommandCoverageTests
    {
        private static readonly MilCmd[] AllCommands = Enum.GetValues<MilCmd>();

        /// <summary>构造一条最小命令：只有 Type（+ Handle 位），其余字节为 0。</summary>
        private static byte[] Minimal(MilCmd cmd)
        {
            byte[] buf = new byte[MilCommandDecoder.MinCommandSize];
            BitConverter.GetBytes((int)cmd).CopyTo(buf, MilCommandDecoder.HeaderTypeOffset);
            return buf;
        }

        [Fact]
        public void 顶层命令枚举必须是118条()
        {
            Assert.Equal(MilCommandLayout.TotalDuceCommandCount, AllCommands.Length);
            Assert.Equal(118, AllCommands.Length);
        }

        [Fact]
        public void 顶层命令与绘图指令不得重叠()
        {
            // 命令字空间 0x3e–0x56 属于 MilDrawCommand，MilCmd 里一个都不许出现。
            var drawValues = Enum.GetValues<MilDrawCommand>().Select(v => (byte)v).ToHashSet();
            var overlap = AllCommands.Select(v => (byte)v).Where(b => drawValues.Contains(b)).ToList();

            Assert.Empty(overlap);
            Assert.Equal(MilCommandLayout.RenderDrawCommandCount, drawValues.Count);
        }

        [Fact]
        public void 穷举118条_返回ENOTIMPL的必须是已登记的()
        {
            var channel = new TestChannel();
            var unregistered = new List<MilCmd>();

            foreach (MilCmd cmd in AllCommands)
            {
                if (channel.Dispatch(Minimal(cmd)) != HResult.E_NOTIMPL) continue;
                if (!MilCommandLayout.IsNotImplemented(cmd)) unregistered.Add(cmd);
            }

            // 这些命令被当成「未知命令字」悄悄返了 E_NOTIMPL，却没有登记——
            // 它们的字节布局既没移植也没说明，属于必须暴露而不是静默的洞。
            Assert.Empty(unregistered);
        }

        [Fact]
        public void 穷举118条_已登记的必须真的返ENOTIMPL()
        {
            var channel = new TestChannel();
            var notActuallyNotImpl = new List<MilCmd>();

            foreach (MilCmd cmd in MilCommandLayout.NotImplementedCommands)
            {
                if (channel.Dispatch(Minimal(cmd)) != HResult.E_NOTIMPL)
                    notActuallyNotImpl.Add(cmd);
            }

            Assert.Empty(notActuallyNotImpl);
        }

        [Fact]
        public void 已实现加未实现加哨兵等于118()
        {
            var dispatcher = new MilCommandDispatcher();

            int implemented = AllCommands.Count(dispatcher.IsImplemented);
            int notImpl = MilCommandLayout.NotImplCount;

            // 110 条真正解码 + 7 条 E_NOTIMPL + 1 条 Invalid 哨兵 = 118。
            //
            // 不把 MilCmdInvalid 算进「已实现」：它是命令字 0x00 的非法值哨兵，
            // 分发器只负责拒绝它（E_INVALIDARG），没有任何载荷可解。
            // 把它计入只为了凑 111 这个整数，是虚报。
            //
            // 108 → 110：本轮补上 0x0c MilCmdBitmapSource 与 0x0d MilCmdBitmapInvalidate
            // （实现见 Commands/MilBitmapSource.cs）。
            Assert.Equal(112, implemented);          // `#49`：110→112（0x6c/0x70 已实现）
            // `#49`：0x6c/0x70 已实现（D-G58）⇒ 未实现 ≈7→5
            Assert.Equal(5, notImpl);
            Assert.False(dispatcher.IsImplemented(MilCmd.MilCmdInvalid));
            Assert.Equal(MilCommandLayout.TotalDuceCommandCount, implemented + notImpl + 1);
        }

        [Fact]
        public void Invalid哨兵被拒而不是被当未知命令()
        {
            var channel = new TestChannel();
            Assert.Equal(HResult.E_INVALIDARG, channel.Dispatch(Minimal(MilCmd.MilCmdInvalid)));
        }

        /// <summary>
        /// 已实现但分发时不做事的 4 条。它们全部是**无载荷**命令（除命令头外没有字段），
        /// 所以「什么都不做」是正确行为，不是偷工减料。
        /// </summary>
        internal static readonly MilCmd[] NoOpByDesign =
        {
            MilCmd.MilCmdTransportSyncFlush,          // 本实现里 Commit 就是同步点
            MilCmd.MilCmdChannelCreateResource,       // 资源由 CreateOrAddRefOnChannel 建，流里只是标记
            MilCmd.MilCmdChannelDuplicateHandle,      // 重由 MilResource_DuplicateHandle 完成
            MilCmd.MilCmdValidateStructureOrder,      // 上游是调试期断言，无运行期状态
        };

        [Fact]
        public void 空实现只能是那4条无载荷命令()
        {
            // 这条测试守的是「不许用 no-op 充数」：
            // 只要某条命令的固定部分超过一个命令头（8 字节），
            // 它就带了字段，分发器就必须把字段落下去，不能只回 S_OK。
            var dispatcher = new MilCommandDispatcher();

            foreach (MilCmd cmd in NoOpByDesign)
            {
                Assert.True(dispatcher.IsImplemented(cmd), $"{cmd} 应算已实现");
                Assert.True(MilCommandLayout.FixedSize(cmd) <= MilCommandDecoder.MinCommandSize,
                    $"{cmd} 固定长度 {MilCommandLayout.FixedSize(cmd)} > 8，带了字段就不该是 no-op");
            }
        }

        [Fact]
        public void 全部命令的去向必须无重叠无遗漏()
        {
            // 把 118 这个总数拆到无重叠、无遗漏，任何一个数变了这里都会红。
            var dispatcher = new MilCommandDispatcher();
            var noop = NoOpByDesign.ToHashSet();

            int notImpl = AllCommands.Count(MilCommandLayout.IsNotImplemented);
            int withPayload = AllCommands.Count(cmd =>
                dispatcher.IsImplemented(cmd)
                && MilCommandLayout.FixedSize(cmd) > MilCommandDecoder.MinCommandSize);
            int headerOnlyWorking = AllCommands.Count(cmd =>
                dispatcher.IsImplemented(cmd)
                && MilCommandLayout.FixedSize(cmd) <= MilCommandDecoder.MinCommandSize
                && !noop.Contains(cmd));
            int sentinel = AllCommands.Count(cmd => cmd == MilCmd.MilCmdInvalid);

            Assert.Equal(5, notImpl);                // `#49` 后：D3D + Windows 句柄 + 媒体（0x6c/0x70 已实现）
            Assert.Equal(99, withPayload);          // `#49`：97→99（+2：0x6c/0x70 现在按变长载荷解）
            Assert.Equal(9, headerOnlyWorking);     // 只有句柄，但要动作（删资源/建 Visual/清子节点/分区标志/清 3D 子节点）
            Assert.Equal(4, noop.Count);
            Assert.Equal(1, sentinel);

            Assert.Equal(118, notImpl + withPayload + headerOnlyWorking + noop.Count + sentinel);
        }

        [Fact]
        public void 已实现的命令都必须有正的长度()
        {
            // FixedSize<=0 意味着解码器根本不知道这条命令有多长，
            // 只能在 Dispatch 里退化成 E_NOTIMPL。这类命令不许出现在已实现集合里。
            var noSize = AllCommands
                .Where(cmd => new MilCommandDispatcher().IsImplemented(cmd))
                .Where(cmd => MilCommandLayout.FixedSize(cmd) <= 0)
                .ToList();

            Assert.Empty(noSize);
        }

        [Fact]
        public void 未实现的5条是D3D与媒体()
        {
            var notImpl = MilCommandLayout.NotImplementedCommands.ToHashSet();

            // ---- 必须未实现的 5 条（docs/unimplemented.md §0；`#49` 后 7→5）----

            // C 类 · D3D / 硬件加速（handoff 决策 4）
            Assert.Contains(MilCmd.MilCmdD3DImage, notImpl);
            Assert.Contains(MilCmd.MilCmdD3DImagePresent, notImpl);
            // `#49`（D-G58）：这两条**已实现**（Effects 页不再 abort）⇒ 反向护栏
            Assert.DoesNotContain(MilCmd.MilCmdPixelShader, notImpl);
            Assert.DoesNotContain(MilCmd.MilCmdShaderEffect, notImpl);
            // C 类 · 载荷是 Windows 事件句柄 / 原生 C++ 对象指针
            Assert.Contains(MilCmd.MilCmdDoubleBufferedBitmap, notImpl);
            Assert.Contains(MilCmd.MilCmdDoubleBufferedBitmapCopyForward, notImpl);
            // B 类 · 媒体播放器（位图源 0x0c/0x0d 已实现，不在此列）
            Assert.Contains(MilCmd.MilCmdMediaPlayer, notImpl);

            Assert.Equal(5, notImpl.Count);

            // ---- 反向护栏：0x0c / 0x0d 已实现，不许退回 E_NOTIMPL ----
            Assert.DoesNotContain(MilCmd.MilCmdBitmapSource, notImpl);
            Assert.DoesNotContain(MilCmd.MilCmdBitmapInvalidate, notImpl);

            // ---- 回归护栏：两段 3D 命令已实现，不许悄悄退回 E_NOTIMPL ----
            // 0x29–0x30 是上一轮误判为 B、本轮纠正后实现的；钉住防止回退。
            for (byte b = 0x29; b <= 0x30; b++)
                Assert.DoesNotContain((MilCmd)b, notImpl);
            for (byte b = 0x57; b <= 0x6b; b++)
                Assert.DoesNotContain((MilCmd)b, notImpl);

            // 3D 之外的命令不许被误伤
            Assert.DoesNotContain(MilCmd.MilCmdSolidColorBrush, notImpl);
            Assert.DoesNotContain(MilCmd.MilCmdVisualCreate, notImpl);
        }
    }
}

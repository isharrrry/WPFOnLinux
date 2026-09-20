// Licensed to the .NET Foundation under one or more agreements.
//
// 通道状态机 + 批处理 + 句柄生命周期测试。
//
// 状态机契约（上游 exports.cs 的调用序列）：
//     BeginCommand → (AppendCommandData)* → EndCommand → … → CommitChannel
// 违反顺序返回 E_UNEXPECTED；命令在 Commit 之前不执行。

using System;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;

namespace WpfGfx.Linux.Tests.Commands
{
    public class ChannelStateMachineTests
    {
        private static MilChannel NewChannel() =>
            new MilChannel(new MilPartition()) { Dispatcher = new MilCommandDispatcher() };

        // ==================== 批处理顺序 ====================

        [Fact]
        public void 完整序列_Begin_Append_End_Commit()
        {
            MilChannel ch = NewChannel();
            MilVisualResource v = CreateVisual(ch, out var h);

            // VisualSetGuidelineCollection：16 字节头 + 8 字节尾部（2 个 float）
            byte[] full = MilCommandEncoder.VisualSetGuidelineCollection(h, new[] { 1f }, new[] { 2f });
            ReadOnlySpan<byte> head = full.AsSpan(0, 16);
            ReadOnlySpan<byte> tail = full.AsSpan(16);

            Assert.Equal(HResult.S_OK, ch.BeginCommand(head, (uint)tail.Length));
            Assert.True(ch.IsCommandOpen);
            Assert.Equal(HResult.S_OK, ch.AppendCommandData(tail));
            Assert.Equal(HResult.S_OK, ch.EndCommand());
            Assert.False(ch.IsCommandOpen);

            // Commit 之前不执行
            Assert.Empty(v.Visual.GuidelinesX);
            Assert.Equal(1, ch.PendingCommandCount);

            Assert.Equal(HResult.S_OK, ch.Commit());
            Assert.Equal(new[] { 1f }, v.Visual.GuidelinesX);
            Assert.Equal(new[] { 2f }, v.Visual.GuidelinesY);
            Assert.Equal(0, ch.PendingCommandCount);
            Assert.Equal(0, ch.BatchByteCount);
        }

        [Fact]
        public void 嵌套BeginCommand返回EUNEXPECTED()
        {
            MilChannel ch = NewChannel();
            byte[] cmd = new byte[8];
            Assert.Equal(HResult.S_OK, ch.BeginCommand(cmd, 0));
            Assert.Equal(HResult.E_UNEXPECTED, ch.BeginCommand(cmd, 0));
        }

        [Fact]
        public void 没有Begin就Append返回EUNEXPECTED()
        {
            MilChannel ch = NewChannel();
            Assert.Equal(HResult.E_UNEXPECTED, ch.AppendCommandData(new byte[4]));
            Assert.Equal(HResult.E_UNEXPECTED, ch.EndCommand());
        }

        [Fact]
        public void Append超出cbExtra返回EINVALIDARG()
        {
            MilChannel ch = NewChannel();
            Assert.Equal(HResult.S_OK, ch.BeginCommand(new byte[8], cbExtra: 4));
            Assert.Equal(HResult.E_INVALIDARG, ch.AppendCommandData(new byte[8]));
            Assert.Equal(HResult.S_OK, ch.AppendCommandData(new byte[4]));
            Assert.Equal(HResult.S_OK, ch.EndCommand());
        }

        [Fact]
        public void 命令未闭合时Commit与CloseBatch返回EUNEXPECTED()
        {
            MilChannel ch = NewChannel();
            Assert.Equal(HResult.S_OK, ch.BeginCommand(new byte[8], 0));
            Assert.Equal(HResult.E_UNEXPECTED, ch.Commit());
            Assert.Equal(HResult.E_UNEXPECTED, ch.CloseBatch());
            Assert.Equal(HResult.S_OK, ch.EndCommand());
            Assert.Equal(HResult.S_OK, ch.CloseBatch());
        }

        [Fact]
        public void 批内多条命令按顺序执行()
        {
            MilChannel ch = NewChannel();
            MilVisualResource v = CreateVisual(ch, out var h);
            var a = CreateVisualHandle(ch);
            var b = CreateVisualHandle(ch);

            ch.SendCommand(MilCommandEncoder.VisualInsertChildAt(h, a, 0), false);
            ch.SendCommand(MilCommandEncoder.VisualInsertChildAt(h, b, 1), false);
            ch.SendCommand(MilCommandEncoder.VisualSetAlpha(h, 0.5), false);
            Assert.Equal(3, ch.PendingCommandCount);
            Assert.Empty(v.Visual.Children);

            Assert.Equal(HResult.S_OK, ch.Commit());
            Assert.Equal(new[] { a, b }, v.Visual.Children);
            Assert.Equal(0.5, v.Visual.Alpha);
            Assert.Equal(3, ch.CommittedCommands);

            // 第二次 Commit 是空批
            Assert.Equal(HResult.S_OK, ch.Commit());
            Assert.Equal(3, ch.CommittedCommands);
        }

        [Fact]
        public void SendCommand独立批次不影响当前批()
        {
            MilChannel ch = NewChannel();
            MilVisualResource v = CreateVisual(ch, out var h);

            ch.SendCommand(MilCommandEncoder.VisualSetAlpha(h, 0.25), sendInSeparateBatch: false);
            Assert.Equal(1, ch.PendingCommandCount);
            Assert.Equal(1.0, v.Visual.Alpha);   // 未提交

            // 独立批次：立即执行，且不动已排队的那条
            Assert.Equal(HResult.S_OK,
                ch.SendCommand(MilCommandEncoder.VisualSetOffset(h, 9, 9), sendInSeparateBatch: true));
            Assert.Equal(9.0, v.Visual.OffsetX);
            Assert.Equal(1, ch.PendingCommandCount);
            Assert.Equal(1.0, v.Visual.Alpha);

            ch.Commit();
            Assert.Equal(0.25, v.Visual.Alpha);
        }

        [Fact]
        public void 空数据被拒()
        {
            MilChannel ch = NewChannel();
            Assert.Equal(HResult.E_INVALIDARG, ch.BeginCommand(ReadOnlySpan<byte>.Empty, 0));
            Assert.Equal(HResult.E_INVALIDARG, ch.SendCommand(ReadOnlySpan<byte>.Empty, false));
        }

        [Fact]
        public void 批处理缓冲会自动扩容()
        {
            MilChannel ch = NewChannel();
            MilVisualResource v = CreateVisual(ch, out var h);

            // 默认缓冲 8192 字节；灌 1000 条 24 字节命令 = 24000 字节
            for (int i = 0; i < 1000; i++)
                ch.SendCommand(MilCommandEncoder.VisualSetOffset(h, i, i), false);

            Assert.Equal(1000, ch.PendingCommandCount);
            Assert.Equal(24000, ch.BatchByteCount);
            Assert.Equal(HResult.S_OK, ch.Commit());
            Assert.Equal(999.0, v.Visual.OffsetX);
        }

        // ==================== 句柄生命周期 ====================

        [Fact]
        public void 句柄0是Null()
        {
            var table = new MilResourceTable();
            Assert.True(DUCE.ResourceHandle.Null.IsNull);
            Assert.Null(table.Lookup(DUCE.ResourceHandle.Null));
            Assert.False(table.Release(DUCE.ResourceHandle.Null, out bool deleted));
            Assert.False(deleted);
        }

        [Fact]
        public void CreateOrAddRef引用计数()
        {
            var table = new MilResourceTable();

            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h);
            Assert.False(h.IsNull);
            Assert.Equal(1u, table.GetRefCount(h));
            Assert.Equal(1, table.Count);
            MilResource first = table.Lookup(h);

            // 同一句柄再 CreateOrAddRef → AddRef，不新建对象
            DUCE.ResourceHandle same = h;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref same);
            Assert.Equal(h, same);
            Assert.Equal(2u, table.GetRefCount(h));
            Assert.Same(first, table.Lookup(h));
            Assert.Equal(1, table.Count);

            // 第一次 Release 不删
            Assert.True(table.Release(h, out bool deleted));
            Assert.False(deleted);
            Assert.Equal(1u, table.GetRefCount(h));

            // 第二次 Release 删除
            Assert.True(table.Release(h, out deleted));
            Assert.True(deleted);
            Assert.Equal(0, table.Count);
            Assert.Null(table.Lookup(h));
        }

        [Fact]
        public void 重复释放返回EHANDLE且不误删()
        {
            var table = new MilResourceTable();

            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h);
            MilResource visual = table.Lookup(h);

            Assert.True(table.Release(h, out bool deleted));
            Assert.True(deleted);
            Assert.Equal(0, table.Count);

            // 二次释放：表里已经没有这个句柄了，必须报「未找到」而不是再删一次。
            Assert.False(table.Release(h, out deleted));
            Assert.False(deleted);
            Assert.Equal(0, table.Count);
        }

        /// <summary>
        /// 句柄回收是本实现的已知危险点，这里把它钉住：释放后的句柄会立刻回到空闲栈，
        /// 下一次 Create 原样复用同一个整数。因此「先释放、后复用、再陈释放」这条序列
        /// 会删掉**新**资源——这与上游 wpfgfx 的 CResourceTable 行为一致，
        /// 不是本移植引入的偏差。留档以便排查「资源莫名消失」类问题。
        /// </summary>
        [Fact]
        public void 句柄复用后陈旧释放会命中新资源_已知危险点()
        {
            var table = new MilResourceTable();

            DUCE.ResourceHandle h1 = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h1);
            table.Release(h1, out bool deleted);
            Assert.True(deleted);

            // 句柄回到空闲栈，下一条 Create 把它原样发出去
            DUCE.ResourceHandle h2 = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH, ref h2);
            Assert.Equal(h1, h2);
            Assert.NotNull(table.Lookup(h2));

            // 陈旧释放命中了新资源：能查到，于是照删。
            Assert.True(table.Release(h2, out deleted));
            Assert.True(deleted);
            Assert.Equal(0, table.Count);
        }

        [Fact]
        public void 引用计数未归零时释放不删资源()
        {
            var table = new MilResourceTable();

            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h);
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h);
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h);
            Assert.Equal(3u, table.GetRefCount(h));

            table.Release(h, out bool deleted);
            Assert.False(deleted);
            table.Release(h, out deleted);
            Assert.False(deleted);
            Assert.Equal(1, table.Count);

            table.Release(h, out deleted);
            Assert.True(deleted);
            Assert.Equal(0, table.Count);
        }

        [Fact]
        public void 句柄回收复用()
        {
            var table = new MilResourceTable();

            DUCE.ResourceHandle h1 = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h1);
            DUCE.ResourceHandle h2 = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h2);
            Assert.NotEqual(h1, h2);
            Assert.Equal(2u, table.HighWaterMark);

            table.Release(h2, out _);

            DUCE.ResourceHandle h3 = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h3);
            Assert.Equal(h2, h3);                      // 复用了刚释放的句柄
            Assert.Equal(2u, table.HighWaterMark);     // 没有新增水位
        }

        [Fact]
        public void 资源工厂按类型建对应资源()
        {
            var table = new MilResourceTable();
            Assert.IsType<MilVisualResource>(CreateOfType(table, DUCE.ResourceType.TYPE_VISUAL));
            Assert.IsType<MilSolidColorBrush>(CreateOfType(table, DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH));
            Assert.IsType<MilHwndTarget>(CreateOfType(table, DUCE.ResourceType.TYPE_HWNDRENDERTARGET));
            Assert.IsType<MilPathGeometry>(CreateOfType(table, DUCE.ResourceType.TYPE_PATHGEOMETRY));
            // 3D / 媒体类型在 M1 落到占位资源
            Assert.IsType<MilOpaqueResource>(CreateOfType(table, DUCE.ResourceType.TYPE_MESHGEOMETRY3D));
            Assert.IsType<MilOpaqueResource>(CreateOfType(table, DUCE.ResourceType.TYPE_MEDIAPLAYER));
        }

        [Fact]
        public void Visual资源建表时回填自己的句柄()
        {
            var table = new MilResourceTable();
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h);
            Assert.Equal(h, table.Lookup<MilVisualResource>(h).Visual.Handle);
        }

        [Fact]
        public void DuplicateHandle跨通道共享同一资源实例()
        {
            var source = new MilResourceTable();
            var target = new MilResourceTable();

            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            source.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h);
            MilResource shared = source.Lookup(h);

            DUCE.ResourceHandle dup = DUCE.ResourceHandle.Null;
            target.Duplicate(shared, ref dup);

            Assert.Same(shared, target.Lookup(dup));       // 同一实例
            Assert.Equal(1u, target.GetRefCount(dup));     // 目标通道独立计数
            Assert.Equal(1u, source.GetRefCount(h));

            // 目标通道释放不影响源通道
            target.Release(dup, out bool deleted);
            Assert.True(deleted);
            Assert.Same(shared, source.Lookup(h));
        }

        [Fact]
        public void 通道注册表可解析与注销()
        {
            MilChannel ch = NewChannel();

            // 断言落在「本句柄」上，而不是 MilChannelRegistry.Count 的增量上：
            // Count 是进程级全局量，xunit 并行下别的测试集合会同时注册/注销通道，
            // 对它做增量断言本身就不是一个在并发下成立的命题（与注册表是否线程安全无关）。
            // Contains 就是 Count 断言在本句柄上的等价形式，且是确定的。
            IntPtr p = MilChannelRegistry.Register(ch);
            Assert.True(MilChannelRegistry.Contains(p));
            Assert.Same(ch, MilChannelRegistry.Resolve(p));
            Assert.Equal(p, ch.Handle);

            Assert.True(MilChannelRegistry.Unregister(p));
            Assert.Null(MilChannelRegistry.Resolve(p));
            Assert.False(MilChannelRegistry.Contains(p));

            // 陈旧句柄再注销：必须返回 false，且不能把别的通道从表里摘掉
            Assert.False(MilChannelRegistry.Unregister(p));
            Assert.Null(MilChannelRegistry.Resolve(IntPtr.Zero));
        }

        /// <summary>
        /// 回归：句柄值一度取自 <c>GCHandle.ToIntPtr(GCHandle.Alloc(channel))</c>，
        /// 而 GCHandle 不是内核对象，它的 IntPtr 只是 GC 句柄表的槽位下标，<c>Free()</c>
        /// 之后槽位会被后来的 <c>Alloc</c> 原样复用。于是
        ///     A 注销句柄 p → B 建通道拿到同一个 p → A 再注销 p
        /// 会把 B 的通道删掉 —— 这就是 xunit 并行下那条低频 flaky 的根因
        /// （实测 60 轮 9 次失败，见修复记录）。句柄值改为单调下发、进程内永不复用后该序列不再成立。
        /// </summary>
        [Fact]
        public void 注销后的句柄值不会被后续注册复用()
        {
            IntPtr retired = MilChannelRegistry.Register(NewChannel());
            Assert.True(MilChannelRegistry.Unregister(retired));

            IntPtr fresh = MilChannelRegistry.Register(NewChannel());
            try
            {
                Assert.NotEqual(retired, fresh);
                Assert.False(MilChannelRegistry.Unregister(retired));   // 陈旧句柄不得命中新通道
                Assert.True(MilChannelRegistry.Contains(fresh));        // 新通道必须还在
            }
            finally
            {
                MilChannelRegistry.Unregister(fresh);
            }
        }

        // ==================== 辅助 ====================

        private static MilResource CreateOfType(MilResourceTable table, DUCE.ResourceType type)
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            table.CreateOrAddRef(type, ref h);
            return table.Lookup(h);
        }

        private static MilVisualResource CreateVisual(MilChannel ch, out DUCE.ResourceHandle h)
        {
            h = DUCE.ResourceHandle.Null;
            ch.Resources.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h);
            return ch.Resources.Lookup<MilVisualResource>(h);
        }

        private static DUCE.ResourceHandle CreateVisualHandle(MilChannel ch)
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            ch.Resources.CreateOrAddRef(DUCE.ResourceType.TYPE_VISUAL, ref h);
            return h;
        }
    }
}

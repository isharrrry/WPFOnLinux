// Licensed to the .NET Foundation under one or more agreements.
//
// 13 个 MIL 导出函数（+3 个 M1 未实现）的行为测试。
// 签名对齐上游 Common/Graphics/exports.cs:112-204。

using System;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;

namespace WpfGfx.Linux.Tests.Commands
{
    public unsafe class MilNativeTests : IDisposable
    {
        private IntPtr _channel;
        private IntPtr _channel2;

        public MilNativeTests()
        {
            Assert.Equal(HResult.S_OK,
                MilNative.MilConnection_CreateChannel(IntPtr.Zero, IntPtr.Zero, out _channel));
        }

        public void Dispose()
        {
            if (_channel != IntPtr.Zero) MilNative.MilConnection_DestroyChannel(_channel);
            if (_channel2 != IntPtr.Zero) MilNative.MilConnection_DestroyChannel(_channel2);
        }

        private MilChannel Managed => MilChannelRegistry.Resolve(_channel);

        // ==================== 通道 ====================

        [Fact]
        public void CreateChannel返回可解析句柄()
        {
            Assert.NotEqual(IntPtr.Zero, _channel);
            Assert.NotNull(Managed);
            Assert.NotNull(Managed.Dispatcher);      // 必须装好解码器，否则命令流不会落地
        }

        [Fact]
        public void 以参考通道创建的通道共享分区()
        {
            Assert.Equal(HResult.S_OK,
                MilNative.MilConnection_CreateChannel(IntPtr.Zero, _channel, out _channel2));
            Assert.Same(Managed.Partition, MilChannelRegistry.Resolve(_channel2).Partition);
        }

        [Fact]
        public void 无参考通道各自独立分区()
        {
            Assert.Equal(HResult.S_OK,
                MilNative.MilConnection_CreateChannel(IntPtr.Zero, IntPtr.Zero, out _channel2));
            Assert.NotSame(Managed.Partition, MilChannelRegistry.Resolve(_channel2).Partition);
        }

        [Fact]
        public void DestroyChannel清空资源并注销()
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_VISUAL, ref h);
            Assert.Equal(1, Managed.Resources.Count);

            Assert.Equal(HResult.S_OK, MilNative.MilConnection_DestroyChannel(_channel));
            Assert.Null(MilChannelRegistry.Resolve(_channel));
            _channel = IntPtr.Zero;
        }

        [Fact]
        public void 非法通道句柄返回EHANDLE()
        {
            var bogus = new IntPtr(0x1234);
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;

            Assert.Equal(HResult.E_HANDLE, MilNative.MilConnection_DestroyChannel(bogus));
            Assert.Equal(HResult.E_HANDLE, MilNative.MilConnection_CloseBatch(bogus));
            Assert.Equal(HResult.E_HANDLE, MilNative.MilConnection_CommitChannel(bogus));
            Assert.Equal(HResult.E_HANDLE,
                MilNative.MilResource_CreateOrAddRefOnChannel(bogus, DUCE.ResourceType.TYPE_VISUAL, ref h));
            Assert.Equal(HResult.E_HANDLE, MilNative.MilResource_ReleaseOnChannel(bogus, h, out _));
            Assert.Equal(HResult.E_HANDLE, MilNative.MilChannel_GetMarshalType(bogus, out _));
            Assert.Equal(HResult.E_HANDLE, MilNative.MilChannel_EndCommand(bogus));
        }

        [Fact]
        public void GetMarshalType返回SameThread()
        {
            Assert.Equal(HResult.S_OK, MilNative.MilChannel_GetMarshalType(_channel, out ChannelMarshalType t));
            Assert.Equal(ChannelMarshalType.ChannelMarshalTypeSameThread, t);
        }

        // ==================== 资源句柄 ====================

        [Fact]
        public void CreateOrAddRefOnChannel建资源并AddRef()
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            Assert.Equal(HResult.S_OK,
                MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH, ref h));
            Assert.False(h.IsNull);
            Assert.IsType<MilSolidColorBrush>(Managed.Resources.Lookup(h));
            Assert.Equal(1u, Managed.Resources.GetRefCount(h));

            Assert.Equal(HResult.S_OK,
                MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH, ref h));
            Assert.Equal(2u, Managed.Resources.GetRefCount(h));
            Assert.Equal(1, Managed.Resources.Count);
        }

        [Fact]
        public void ReleaseOnChannel归零时deleted为1()
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_VISUAL, ref h);
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_VISUAL, ref h);

            Assert.Equal(HResult.S_OK, MilNative.MilResource_ReleaseOnChannel(_channel, h, out int deleted));
            Assert.Equal(0, deleted);

            Assert.Equal(HResult.S_OK, MilNative.MilResource_ReleaseOnChannel(_channel, h, out deleted));
            Assert.Equal(1, deleted);
            Assert.Equal(0, Managed.Resources.Count);
        }

        [Fact]
        public void ReleaseOnChannel对空句柄返回EINVALIDARG()
        {
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MilResource_ReleaseOnChannel(_channel, DUCE.ResourceHandle.Null, out int deleted));
            Assert.Equal(0, deleted);
        }

        [Fact]
        public void ReleaseOnChannel重复释放返回EHANDLE()
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_VISUAL, ref h);

            Assert.Equal(HResult.S_OK, MilNative.MilResource_ReleaseOnChannel(_channel, h, out int deleted));
            Assert.Equal(1, deleted);
            Assert.Equal(0, Managed.Resources.Count);

            // 第二次释放：句柄已不在表里，必须报 E_HANDLE，不能静默成功。
            Assert.Equal(HResult.E_HANDLE, MilNative.MilResource_ReleaseOnChannel(_channel, h, out deleted));
            Assert.Equal(0, deleted);
            Assert.Equal(0, Managed.Resources.Count);
        }

        [Fact]
        public void DuplicateHandle同分区跨通道共享()
        {
            Assert.Equal(HResult.S_OK,
                MilNative.MilConnection_CreateChannel(IntPtr.Zero, _channel, out _channel2));

            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_VISUAL, ref h);

            DUCE.ResourceHandle dup = DUCE.ResourceHandle.Null;
            Assert.Equal(HResult.S_OK,
                MilNative.MilResource_DuplicateHandle(_channel, h, _channel2, ref dup));
            Assert.False(dup.IsNull);
            Assert.Same(Managed.Resources.Lookup(h),
                        MilChannelRegistry.Resolve(_channel2).Resources.Lookup(dup));
        }

        [Fact]
        public void DuplicateHandle跨分区被拒()
        {
            Assert.Equal(HResult.S_OK,
                MilNative.MilConnection_CreateChannel(IntPtr.Zero, IntPtr.Zero, out _channel2));

            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_VISUAL, ref h);

            DUCE.ResourceHandle dup = DUCE.ResourceHandle.Null;
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MilResource_DuplicateHandle(_channel, h, _channel2, ref dup));
        }

        [Fact]
        public void DuplicateHandle源句柄无效返回EHANDLE()
        {
            DUCE.ResourceHandle dup = DUCE.ResourceHandle.Null;
            Assert.Equal(HResult.E_HANDLE,
                MilNative.MilResource_DuplicateHandle(_channel, new DUCE.ResourceHandle(42), _channel, ref dup));
        }

        // ==================== 命令流 ====================

        [Fact]
        public void SendCommand整条命令一次写入并在Commit时执行()
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_VISUAL, ref h);
            MilVisualNode visual = Managed.GetVisual(h);

            byte[] cmd = MilCommandEncoder.VisualSetOffset(h, 5, 6);
            fixed (byte* p = cmd)
            {
                Assert.Equal(HResult.S_OK,
                    MilNative.MilResource_SendCommand(p, (uint)cmd.Length, false, _channel));
            }
            Assert.Equal(0.0, visual.OffsetX);       // 未提交

            Assert.Equal(HResult.S_OK, MilNative.MilConnection_CloseBatch(_channel));
            Assert.Equal(HResult.S_OK, MilNative.MilConnection_CommitChannel(_channel));
            Assert.Equal(5.0, visual.OffsetX);
            Assert.Equal(6.0, visual.OffsetY);
        }

        [Fact]
        public void SendCommand独立批次立即执行()
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_VISUAL, ref h);
            MilVisualNode visual = Managed.GetVisual(h);

            byte[] cmd = MilCommandEncoder.VisualSetAlpha(h, 0.5);
            fixed (byte* p = cmd)
            {
                Assert.Equal(HResult.S_OK,
                    MilNative.MilResource_SendCommand(p, (uint)cmd.Length, true, _channel));
            }
            Assert.Equal(0.5, visual.Alpha);
        }

        [Fact]
        public void BeginAppendEnd分段写入变长命令()
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel, DUCE.ResourceType.TYPE_DASHSTYLE, ref h);

            // DashStyle：24 字节头 + 2 个 double
            byte[] full = MilCommandEncoder.DashStyle(h, 1.5, new double[] { 2.5, 3.5 });
            byte[] head = full[..24];
            byte[] tail = full[24..];

            fixed (byte* ph = head)
            fixed (byte* pt = tail)
            {
                Assert.Equal(HResult.S_OK,
                    MilNative.MilChannel_BeginCommand(_channel, ph, (uint)head.Length, (uint)tail.Length));
                Assert.Equal(HResult.S_OK,
                    MilNative.MilChannel_AppendCommandData(_channel, pt, (uint)tail.Length));
                Assert.Equal(HResult.S_OK, MilNative.MilChannel_EndCommand(_channel));
            }

            Assert.Equal(HResult.S_OK, MilNative.MilConnection_CommitChannel(_channel));
            MilDashStyle dash = Managed.Resources.Lookup<MilDashStyle>(h);
            Assert.Equal(1.5, dash.Offset);
            Assert.Equal(new double[] { 2.5, 3.5 }, dash.Dashes);
        }

        [Fact]
        public void 空指针或零长度被拒()
        {
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MilResource_SendCommand(null, 8, false, _channel));
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MilChannel_BeginCommand(_channel, null, 8, 0));

            byte[] cmd = new byte[8];
            fixed (byte* p = cmd)
            {
                Assert.Equal(HResult.E_INVALIDARG,
                    MilNative.MilResource_SendCommand(p, 0, false, _channel));
            }
        }

        [Fact]
        public void SameThreadPresent提交所有通道()
        {
            var connection = new IntPtr(0x99);
            Assert.Equal(HResult.S_OK,
                MilNative.MilConnection_CreateChannel(connection, IntPtr.Zero, out _channel2));

            MilChannel ch2 = MilChannelRegistry.Resolve(_channel2);
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            MilNative.MilResource_CreateOrAddRefOnChannel(_channel2, DUCE.ResourceType.TYPE_VISUAL, ref h);
            MilVisualNode visual = ch2.GetVisual(h);

            ch2.SendCommand(MilCommandEncoder.VisualSetOffset(h, 7, 8), false);
            Assert.Equal(0.0, visual.OffsetX);

            Assert.Equal(HResult.S_OK, MilNative.WgxConnection_SameThreadPresent(connection));
            Assert.Equal(7.0, visual.OffsetX);
            Assert.Equal(0, ch2.PendingCommandCount);
        }

        // ==================== 通道通知窗口（T1/M7c：NotImpl → State）====================

        [Fact]
        public void 通知窗口登记成功且同值重复登记幂等()
        {
            MilChannelNotificationRegistry.Unregister(_channel);
            var hwnd = (IntPtr)0x10001;
            const uint Msg = 0x8000;   // Win32 shim 的 RegisterWindowMessage 私有段首值

            Assert.Equal(HResult.S_OK, MilNative.MilChannel_SetNotificationWindow(_channel, hwnd, Msg));
            Assert.True(MilChannelNotificationRegistry.TryGet(_channel, out IntPtr gotHwnd, out uint gotMsg));
            Assert.Equal(hwnd, gotHwnd);
            Assert.Equal(Msg, gotMsg);

            // 幂等：同值再登记仍 S_OK，**同一个通道仍只有一条登记**（SetCount 累加）
            Assert.Equal(HResult.S_OK, MilNative.MilChannel_SetNotificationWindow(_channel, hwnd, Msg));
            Assert.True(MilChannelNotificationRegistry.TryGetRegistration(_channel, out var reg));
            Assert.Equal(2, reg.SetCount);
            Assert.Equal(hwnd, reg.Hwnd);
        }

        [Fact]
        public void 通知窗口换窗口是覆盖登记()
        {
            MilChannelNotificationRegistry.Unregister(_channel);
            Assert.Equal(HResult.S_OK, MilNative.MilChannel_SetNotificationWindow(_channel, (IntPtr)0x10001, 0x8000));
            Assert.Equal(HResult.S_OK, MilNative.MilChannel_SetNotificationWindow(_channel, (IntPtr)0x10002, 0x8001));

            Assert.True(MilChannelNotificationRegistry.TryGet(_channel, out IntPtr hwnd, out uint msg));
            Assert.Equal((IntPtr)0x10002, hwnd);
            Assert.Equal(0x8001u, msg);
            // 覆盖登记：本通道仍只有一条记录（全局计数不做断言 —— 别的测试类可能同时在用别的通道）
            Assert.True(MilChannelNotificationRegistry.TryGetRegistration(_channel, out var reg));
            Assert.Equal(2, reg.SetCount);   // 本测试内共登记 2 次（覆盖登记）
        }

        [Fact]
        public void 通知窗口hwnd为零表示解绑且幂等()
        {
            Assert.Equal(HResult.S_OK, MilNative.MilChannel_SetNotificationWindow(_channel, (IntPtr)0x10001, 0x8000));
            Assert.True(MilChannelNotificationRegistry.TryGet(_channel, out _, out _));

            // 解绑
            Assert.Equal(HResult.S_OK, MilNative.MilChannel_SetNotificationWindow(_channel, IntPtr.Zero, 0));
            Assert.False(MilChannelNotificationRegistry.TryGet(_channel, out _, out _));

            // 未登记过再解绑也是 S_OK（幂等）
            Assert.Equal(HResult.S_OK, MilNative.MilChannel_SetNotificationWindow(_channel, IntPtr.Zero, 0));
            Assert.False(MilChannelNotificationRegistry.TryGet(_channel, out _, out _));
        }

        [Fact]
        public void 通知窗口非法参数返回EINVALIDARG或EHANDLE()
        {
            // 通道句柄无效 → E_HANDLE（沿用既有约定，不是 E_INVALIDARG）
            Assert.Equal(HResult.E_HANDLE,
                MilNative.MilChannel_SetNotificationWindow(unchecked((IntPtr)0xDEADBEEF), (IntPtr)0x10001, 0x8000));

            // 非 0 窗口 + message == 0（WM_NULL 永远到不了）→ E_INVALIDARG
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MilChannel_SetNotificationWindow(_channel, (IntPtr)0x10001, 0));
            Assert.False(MilChannelNotificationRegistry.TryGet(_channel, out _, out _));
        }

        [Fact]
        public void 通道销毁时通知窗口登记随之摘除()
        {
            // 全部断言收敛在**本测试自己建的通道句柄**上：句柄单调下发、永不复用，
            // 所以不受别的测试类并行改动影响（不像全局计数）。
            IntPtr temp;
            Assert.Equal(HResult.S_OK, MilNative.MilConnection_CreateChannel(IntPtr.Zero, IntPtr.Zero, out temp));
            Assert.Equal(HResult.S_OK, MilNative.MilChannel_SetNotificationWindow(temp, (IntPtr)0x10001, 0x8000));
            Assert.True(MilChannelNotificationRegistry.TryGet(temp, out _, out _));

            Assert.Equal(HResult.S_OK, MilNative.MilConnection_DestroyChannel(temp));
            Assert.False(MilChannelNotificationRegistry.TryGet(temp, out _, out _));
        }

        [Fact]
        public void 同线程呈现下后向通道消息不触发跨线程唤醒()
        {
            // 同线程（当前唯一形态）下"入队即送达"，没有要唤醒的线程 ——
            // CrossThreadPokes 必须不动，不能假装唤醒过。
            //
            // 【为什么不断言 MilChannelBackChannel.PendingCount】
            //   那张表是 ResetProcessStateForTests() 会清掉的全局量，而 MilExportTests
            //   在每个测试开头都调它；xunit 默认并行跑测试类，断言绝对条数会 flaky。
            //   本测试只断言"与本次 Post 相关的、不被别人动的"量。
            MilChannelNotificationRegistry.Unregister(_channel);
            Assert.False(MilChannelNotificationRegistry.IsCrossThreadForWake(_channel));

            Assert.Equal(HResult.S_OK, MilNative.MilChannel_SetNotificationWindow(_channel, (IntPtr)0x10001, 0x8000));
            // 已登记，但通道 MarshalType == SameThread ⇒ 不需要唤醒
            Assert.False(MilChannelNotificationRegistry.IsCrossThreadForWake(_channel));

            long before = MilChannelNotificationRegistry.CrossThreadPokes;
            MilChannelBackChannel.Post(_channel, new MilMessage { Type = MilMessageType.SyncFlushReply });
            Assert.Equal(before, MilChannelNotificationRegistry.CrossThreadPokes);

            // 投递不会顺带把登记弄丢
            Assert.True(MilChannelNotificationRegistry.TryGet(_channel, out IntPtr hwnd, out uint msg));
            Assert.Equal((IntPtr)0x10001, hwnd);
            Assert.Equal(0x8000u, msg);
        }

        // ==================== M1 未实现的 2 个 ====================

        [Fact]
        public void 媒体导出仍ENOTIMPL_位图源导出已接线并按上游返回E_INVALIDARG()
        {
            // M1 存量：媒体导出仍是"从不接"（M1 决策 4：不接 MediaPlayer）。
            Assert.Equal(HResult.E_NOTIMPL,
                MilNative.MilResource_SendCommandMedia(DUCE.ResourceHandle.Null, IntPtr.Zero, _channel, false));

            // M7c/#24：`MilResource_SendCommandBitmapSource` **已从 NotImpl 升为 Real**
            //   （位图源命令接进既有的 `MilCmdBitmapSource`(0x0c) 路径），因此它不再返回 E_NOTIMPL。
            //   这里改断言它的**参数语义与上游一致**（apifunc.cpp 的 CHECKPTRARG ⇒ E_INVALIDARG），
            //   比原来那句"返回 E_NOTIMPL"更强、也更接近上游行为。
            Assert.Equal(HResult.E_INVALIDARG,
                MilNative.MilResource_SendCommandBitmapSource(DUCE.ResourceHandle.Null, IntPtr.Zero, _channel));
        }
    }
}

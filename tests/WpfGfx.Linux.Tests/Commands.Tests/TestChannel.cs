// Licensed to the .NET Foundation under one or more agreements.
//
// 测试用通道夹具：一条装好解码器的 MilChannel + 建资源的语法糖。

using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Resources;
using Xunit;
using WpfGfx.Linux.Interop;

namespace WpfGfx.Linux.Tests.Commands
{
    internal sealed class TestChannel
    {
        public readonly MilChannel Channel;

        public TestChannel()
        {
            Channel = new MilChannel(new MilPartition()) { Dispatcher = new MilCommandDispatcher() };
        }

        public MilResourceTable Resources => Channel.Resources;

        /// <summary>建一个资源，返回句柄。</summary>
        public DUCE.ResourceHandle Create(DUCE.ResourceType type)
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            Channel.Resources.CreateOrAddRef(type, ref h);
            return h;
        }

        /// <summary>建一个资源，返回强类型资源对象与句柄。</summary>
        public T Create<T>(DUCE.ResourceType type, out DUCE.ResourceHandle handle) where T : MilResource
        {
            handle = Create(type);
            return Assert.IsType<T>(Channel.Resources.Lookup(handle));
        }

        /// <summary>直接分发一条命令（跳过批处理），返回 HRESULT。</summary>
        public int Dispatch(byte[] command) => Channel.Dispatcher.Dispatch(command, Channel);

        /// <summary>分发一条命令并断言成功。</summary>
        public void Send(byte[] command) =>
            Assert.Equal(WpfGfx.Linux.Interop.HResult.S_OK, Dispatch(command));

        public T Lookup<T>(DUCE.ResourceHandle h) where T : MilResource => Channel.Resources.Lookup<T>(h);
    }
}

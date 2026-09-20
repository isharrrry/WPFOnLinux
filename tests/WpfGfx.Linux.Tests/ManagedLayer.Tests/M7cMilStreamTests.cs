// M7c · 轨道 B —— **流字节真的交还给调用方**（修掉"用户 FileStream 收到 0 字节"）
//
// 【这个文件存在的理由】
//   修前 `MILIStreamWrite` 只把字节写进 `MilStreamObject.Data`（进程内的内存副本），
//   **从不调用描述符的 `pfnWrite`**。后果不是"功能少一点"，而是**行为撒谎**：
//   WPF 级链路"编码成功、字节数正确"，而用户传进来的 `FileStream` 里**一个字节都没有**；
//   更荒谬的是"编码到只读流居然成功"。
//
//   修后：字节交还描述符的 `pfnWrite`（那才是"调用方的流"的唯一权威），
//   内存副本降级为台账（`MilStreamBytes` 仍可读，用于诊断与自证）。
//
// 【为什么用"真 FileStream"而不是"内存里数一数字节"】
//   "用户流收到多少字节"是**这个 bug 的现象本身** —— 现象必须由**真对象**回答：
//   本文件里 `pfnWrite` 的回调体就是 `FileStream.Write`，断言最后读回来的是**文件内容**。
//   只数内存台账的话，修前修后都是"收到了"（因为修前就是台账在收）。
//
// 【为什么还要机械核对偏移 32】
//   `pfnWrite` 在 `StreamDescriptor` 里的偏移是**跨语言 ABI**：托管结构体字段顺序一改，
//   32 就不再是 pfnWrite。所以这里**解析上游源码**（`StreamAsIStream.cs`）数出字段顺序，
//   而不是在注释里手抄一句"偏移是 32"。

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using System.Runtime.InteropServices;
using WpfGfx.Linux.Interop;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    /// <summary>MILIStreamWrite → 描述符 pfnWrite 的交付链路（M7c 轨道 B）。</summary>
    [Trait("Category", "ManagedLayer")]
    public sealed class M7cMilStreamTests
    {
        private readonly ITestOutputHelper _out;
        public M7cMilStreamTests(ITestOutputHelper output) => _out = output;

        /// <summary>`StreamDescriptor` = 14 个函数指针 + 1 个 GCHandle（x64：14*8 + 8 = 120）。</summary>
        private const int DescriptorPointerCount = 14;
        private const int DescriptorSize = DescriptorPointerCount * 8 + 8;

        // ==================================================================
        //  ABI：字段顺序必须与上游逐字一致
        // ==================================================================

        private static string FindRepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            for (int up = 0; up < 10 && dir != null; up++, dir = dir.Parent)
            {
                if (File.Exists(Path.Combine(dir.FullName, "handoff.md"))) return dir.FullName;
            }
            throw new InvalidOperationException($"找不到仓库根（含 handoff.md），起点 {AppContext.BaseDirectory}");
        }

        /// <summary>按**字段声明顺序**取回上游 `StreamDescriptor` 的 pfn* 字段名。</summary>
        private static List<string> UpstreamDescriptorFields(out string path)
        {
            path = Path.Combine(FindRepoRoot(), "upstream", "wpf", "src", "Microsoft.DotNet.Wpf", "src",
                "PresentationCore", "System", "Windows", "Media", "StreamAsIStream.cs");
            string text = File.ReadAllText(path);

            Match structBody = Regex.Match(text,
                @"internal struct StreamDescriptor\s*\{(?<body>.*?)\n        \}",
                RegexOptions.Singleline);
            Assert.True(structBody.Success, $"{path} 里找不到 StreamDescriptor 结构体 —— 上游搬家了？");
            string body = structBody.Groups["body"].Value;

            var fields = new List<string>();
            foreach (Match m in Regex.Matches(body, @"internal\s+[\w\.]+(?:<[^>]*>)?\s+(pfn\w+)\s*;"))
            {
                fields.Add(m.Groups[1].Value);
            }
            return fields;
        }

        [Fact]
        public void StreamDescriptor_pfnWrite偏移与上游字段顺序一致()
        {
            List<string> fields = UpstreamDescriptorFields(out string path);
            _out.WriteLine($"上游字段顺序（{fields.Count} 个）：{string.Join(", ", fields)}");

            Assert.Equal(DescriptorPointerCount, fields.Count);

            int index = fields.IndexOf("pfnWrite");
            Assert.True(index >= 0, "上游 StreamDescriptor 里没有 pfnWrite —— 契约变了？");
            int expectedOffset = index * 8;

            _out.WriteLine($"pfnWrite 是第 {index + 1} 个字段 ⇒ 偏移 {expectedOffset}；" +
                           $"实现里写的常量 {MilNative.StreamWriteCallbackOffset}");
            Assert.Equal(expectedOffset, MilNative.StreamWriteCallbackOffset);

            // 结构体总长：14 个函数指针 + 1 个 GCHandle。
            Assert.Equal(fields.Count * 8 + 8, MilNative.StreamDescriptorSize);
            Assert.Equal(fields.Count + 1, MilNative.StreamDescriptorSlotCount);

            // 顺带把"我们消费了几个回调"这件事钉住。
            // 【判据为什么是"委托转换点"而不是"读指针处"】实现先把**整个结构体拷一份**
            //   （上游 `new CManagedStreamWrapper(*pSD)` 也是按值拷贝），所以"读指针"有 15 处、
            //   那不是消费面。真正决定"哪个回调会被调用"的是
            //   `GetDelegateForFunctionPointer<StreamWriteCallback>` —— 它只有一处。
            string misc = File.ReadAllText(Path.Combine(FindRepoRoot(), "src", "WpfGfx.Linux", "Interop",
                "MilNative.Misc.cs"));
            int consumeSites = Regex.Matches(misc,
                @"GetDelegateForFunctionPointer<StreamWriteCallback>").Count;
            Assert.Equal(1, consumeSites);

            // 而且这一处用的必须是 pfnWrite 的槽位。
            Assert.Contains("Marshal.ReadIntPtr(\n                    stream.Descriptor, StreamWriteCallbackOffset)",
                misc.Replace("\r\n", "\n"));
            Assert.Equal(expectedOffset, MilNative.StreamWriteCallbackOffset);

            _out.WriteLine($"原生侧消费的描述符回调数 = {consumeSites} / {fields.Count}" +
                           $"（未消费：{string.Join(", ", fields.FindAll(f => f != "pfnWrite"))}）");
        }

        // ==================================================================
        //  描述符：在**非托管内存**里按 ABI 摆好（与 PC 的 StreamAsIStream.CreateIStream 同构）
        // ==================================================================
        private sealed class Descriptor : IDisposable
        {
            public IntPtr Memory;
            private readonly List<Delegate> _keepAlive = new List<Delegate>();

            /// <summary>`m_handle` 槽位（第 15 个槽，偏移 112）—— 用来证明回调拿到的是**完整副本**。</summary>
            public static readonly IntPtr HandleSentinel = new IntPtr(0x5A5A0000);

            public Descriptor()
            {
                Memory = Marshal.AllocHGlobal(DescriptorSize);
                for (int i = 0; i < DescriptorSize; i++) Marshal.WriteByte(Memory, i, 0);
                Marshal.WriteIntPtr(Memory, DescriptorPointerCount * 8, HandleSentinel);
            }

            /// <summary>把托管回调摆到指定字节偏移（其余槽位保持 NULL，与"只读流"等价）。</summary>
            public void SetWrite(MilNative.StreamWriteCallback callback)
            {
                Marshal.WriteIntPtr(Memory, MilNative.StreamWriteCallbackOffset,
                    Marshal.GetFunctionPointerForDelegate(callback));
                _keepAlive.Add(callback);   // 委托被 GC 掉 = 函数指针变野指针
            }

            public void Dispose() => Marshal.FreeHGlobal(Memory);
        }

        private static IntPtr CreateStream(Descriptor descriptor)
        {
            Assert.Equal(HResult.S_OK,
                MilNative.MILCreateStreamFromStreamDescriptor(descriptor.Memory, out IntPtr stream));
            Assert.NotEqual(IntPtr.Zero, stream);
            return stream;
        }

        // ==================================================================
        //  ① 交付：真 FileStream 收到字节
        // ==================================================================

        [Fact]
        public void MILIStreamWrite_把字节交还pfnWrite_真FileStream收到()
        {
            MilNative.ResetProcessStateForTests();

            byte[] first = { 0x11, 0x22, 0x33 };
            byte[] second = { 0x44, 0x55 };
            string path = Path.Combine(Path.GetTempPath(), "m7c-stream-" + Guid.NewGuid().ToString("N") + ".bin");

            int callbackCalls = 0;
            IntPtr seenDescriptor = IntPtr.Zero;
            IntPtr seenHandleSlot = IntPtr.Zero;
            try
            {
                using var descriptor = new Descriptor();
                using var sink = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.Read);
                descriptor.SetWrite((IntPtr pSD, byte[] buffer, uint cb, out uint cbWritten) =>
                {
                    // 【为什么这里不断言】回调是从 `MILIStreamWrite` 内部调进来的，
                    // 那里的 catch 会把异常转成 E_FAIL —— 断言消息会被吞掉、只剩一句"hr=E_FAIL"。
                    // 所以先记录事实，回到测试线程再断言。
                    seenDescriptor = pSD;
                    seenHandleSlot = Marshal.ReadIntPtr(pSD, DescriptorPointerCount * 8);
                    sink.Write(buffer, 0, (int)cb);            // 这就是"用户的流"
                    sink.Flush();
                    cbWritten = cb;
                    callbackCalls++;
                    return HResult.S_OK;
                });

                IntPtr stream = CreateStream(descriptor);

                Assert.Equal(HResult.S_OK, MilNative.MILIStreamWrite(stream, first, 3, out uint written1));
                Assert.Equal(3u, written1);
                Assert.Equal(HResult.S_OK, MilNative.MILIStreamWrite(stream, second, 2, out uint written2));
                Assert.Equal(2u, written2);

                _out.WriteLine($"回调调用 {callbackCalls} 次，cbWritten {written1}+{written2}");
                Assert.Equal(2, callbackCalls);
                // ★ 回调拿到的是**本工程持有的那一份副本**，不是调用方传进来的临时地址：
                //   上游 `ref StreamDescriptor` 给原生的是临时副本，调用返回后随时可能被复用；
                //   直接把它再传回回调会让 `StreamAsIStream.FromSD` 读到垃圾 m_handle
                //   （上游断言 "Stream is disposed." ⇒ 进程 FailFast，真 PC 上实测过）。
                Assert.NotEqual(IntPtr.Zero, seenDescriptor);
                Assert.NotEqual(descriptor.Memory, seenDescriptor);
                Assert.Equal(Descriptor.HandleSentinel, seenHandleSlot);   // 整份 120 字节都拷过来了

                // ★ 判据：**读文件**，不是读我们的内存台账。
                byte[] onDisk = File.ReadAllBytes(path);
                _out.WriteLine($"FileStream 上实际落盘 {onDisk.Length} 字节：{BitConverter.ToString(onDisk)}");
                Assert.Equal(new byte[] { 0x11, 0x22, 0x33, 0x44, 0x55 }, onDisk);

                // 台账（内存副本）仍然保留 —— 它是诊断面，不是交付面。
                Assert.Equal(onDisk, MilNative.MilStreamBytes(stream));

                // 拆除：描述符副本必须随流对象一起释放（Dispose 跑过的机械痕迹）。
                var payload = (MilStreamObject)MilDeviceObjectTable.Resolve(stream).Payload;
                Assert.Equal(HResult.S_OK, MilNative.MILRelease(stream));
                _out.WriteLine($"释放后：Descriptor=0x{payload.Descriptor.ToInt64():x} owned={payload.DescriptorOwned} " +
                               $"WriteCallback=0x{payload.WriteCallback.ToInt64():x}");
                Assert.Equal(IntPtr.Zero, payload.Descriptor);
                Assert.False(payload.DescriptorOwned);
                Assert.Equal(IntPtr.Zero, payload.WriteCallback);
                Assert.Equal(0, MilDeviceObjectTable.Count);
            }
            finally
            {
                try { if (File.Exists(path)) File.Delete(path); } catch { }
            }
        }

        // ==================================================================
        //  ② 描述符没给 pfnWrite：保持旧行为，且**不伪造**交付
        // ==================================================================

        [Fact]
        public void MILIStreamWrite_描述符没有pfnWrite_只进台账不交付()
        {
            MilNative.ResetProcessStateForTests();

            using var descriptor = new Descriptor();     // 14 个槽位全 NULL = 只读描述符
            IntPtr stream = CreateStream(descriptor);

            byte[] data = { 0xAA, 0xBB, 0xCC, 0xDD };
            Assert.Equal(HResult.S_OK, MilNative.MILIStreamWrite(stream, data, 4, out uint written));

            // 契约：没有可交付的对象时**保持旧行为**（返回 S_OK、cbWritten = cb），
            // 但内存台账**必须**有字节 —— 调用方从台账这一侧仍能看出"数据去哪了"。
            Assert.Equal(4u, written);
            Assert.Equal(data, MilNative.MilStreamBytes(stream));

            MilDeviceObject obj = MilDeviceObjectTable.Resolve(stream);
            var payload = (MilStreamObject)obj.Payload;
            _out.WriteLine($"BytesWritten(台账)={payload.BytesWritten} BytesDelivered(交付)={payload.BytesDelivered}");
            Assert.Equal(4u, payload.BytesWritten);
            Assert.Equal(0u, payload.BytesDelivered);      // ★ 没有交付对象 ⇒ 交付计数不涨

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(stream));
        }

        // ==================================================================
        //  ③ 回调失败：原样返回它的 HRESULT，不吞、不回填
        // ==================================================================

        [Fact]
        public void MILIStreamWrite_回调返回失败_原样返回其HRESULT且不回填cbWritten()
        {
            MilNative.ResetProcessStateForTests();

            const int E_ACCESSDENIED = unchecked((int)0x80070005);
            using var descriptor = new Descriptor();
            descriptor.SetWrite((IntPtr pSD, byte[] buffer, uint cb, out uint cbWritten) =>
            {
                cbWritten = 0;
                return E_ACCESSDENIED;      // 模拟"只读流"：调用方的流拒绝写
            });

            IntPtr stream = CreateStream(descriptor);
            byte[] data = { 1, 2, 3 };

            int hr = MilNative.MILIStreamWrite(stream, data, 3, out uint written);
            _out.WriteLine($"回调失败 ⇒ MILIStreamWrite hr=0x{hr:x8}，cbWritten={written}");
            Assert.Equal(E_ACCESSDENIED, hr);      // ★ 原样返回，不是 E_FAIL/E_UNEXPECTED
            Assert.Equal(0u, written);             // ★ 失败**不**回填

            var payload = (MilStreamObject)MilDeviceObjectTable.Resolve(stream).Payload;
            Assert.Equal(0u, payload.BytesDelivered);

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(stream));
        }

        // ==================================================================
        //  ④ 句柄语义：不是流对象 ⇒ E_HANDLE（fail-safe 未变）
        // ==================================================================

        [Fact]
        public void MILIStreamWrite_句柄不是流对象_返回E_HANDLE()
        {
            MilNative.ResetProcessStateForTests();

            Assert.Equal(HResult.S_OK, MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion));
            byte[] data = { 9, 9 };

            int hr = MilNative.MILIStreamWrite(factory, data, 2, out uint written);
            _out.WriteLine($"对工厂句柄写流 ⇒ hr=0x{hr:x8}");
            Assert.Equal(HResult.E_HANDLE, hr);
            Assert.Equal(0u, written);

            // 陈旧句柄（从未下发）同样 E_HANDLE。
            Assert.Equal(HResult.E_HANDLE,
                MilNative.MILIStreamWrite(new IntPtr(0x5EED), data, 2, out _));

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(factory));
        }
    }
}

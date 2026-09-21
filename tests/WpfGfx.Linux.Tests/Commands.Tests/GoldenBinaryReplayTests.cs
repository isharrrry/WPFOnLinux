// Licensed to the .NET Foundation under one or more agreements.
//
// U1 · 真实 WPF 命令流 golden binary 回放比对器（Linux 侧）。
//
// 数据源：tests/U1-golden/*.stream —— Windows 机器上按
//   docs/U1-command-stream-golden-plan.md §2 抓取的真实 DUCE 命令流。
// 无流文件时，本用例在**发现期**被标 Skip（xunit v2 没有运行期 skip 通道，
// 与 X11Guard 同一模式：自定义 FactAttribute 的构造函数在发现期执行）。
//
// 回放口径（黑盒验收，不是像素级比对）：
//   1. FailedCommands == 0           —— 真实流量里没有一条命令被解码器拒绝；
//   2. NotImplRegistry 的键 ⊆ 文档化的 7 条 E_NOTIMPL（docs/unimplemented.md §1）；
//   3. CommittedCommands > 0；
//   4. CreateOrAddRef 回填的句柄在流内闭合（先建后释放，句柄值自洽）。

using System;
using System.Collections.Generic;
using System.IO;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using Xunit;

namespace WpfGfx.Linux.Tests.Commands
{
    /// <summary>发现期检查 tests/U1-golden/ 有无 .stream；无则 Skip。</summary>
    internal sealed class GoldenStreamFactAttribute : FactAttribute
    {
        public GoldenStreamFactAttribute()
        {
            if (!GoldenBinaryReplayTests.HasStreamFiles)
                Skip = GoldenBinaryReplayTests.SkipReason;
        }
    }

    public class GoldenBinaryReplayTests
    {
        // 记录 op 常量（与 docs/U1-command-stream-golden-plan.md §2.3 一致）
        private const byte OpBeginCommand = 1;
        private const byte OpAppendCommandData = 2;
        private const byte OpEndCommand = 3;
        private const byte OpCommitChannel = 4;
        private const byte OpCreateOrAddRefOnChannel = 5;
        private const byte OpReleaseOnChannel = 6;

        private static readonly byte[] Magic = { 0x57, 0x50, 0x46, 0x53, 0x54, 0x01 };

        // 允许的 E_NOTIMPL 集合 = docs/unimplemented.md §1 的 **5 条**（4 C 类 + 1 B 类媒体）。
        // ⚠️【`#49` 收紧】原先还列着 `0x6c MilCmdPixelShader` / `0x70 MilCmdShaderEffect` ——
        //   它们**已被实现**（`D-G58`：`Effects` 页不再 abort）。留在"允许未实现"白名单里等于
        //   **给"静默回退到 E_NOTIMPL"开绿灯**（本仓最忌讳的那一族）⇒ 本趟**摘掉两条**，
        //   让"这两条又变回 E_NOTIMPL"当场变红。
        private static readonly HashSet<MilCmd> AllowedNotImpl = new HashSet<MilCmd>
        {
            MilCmd.MilCmdD3DImage,                        // 0x0a
            MilCmd.MilCmdD3DImagePresent,                 // 0x0b
            MilCmd.MilCmdDoubleBufferedBitmap,            // 0x3b
            MilCmd.MilCmdDoubleBufferedBitmapCopyForward, // 0x3c
            MilCmd.MilCmdMediaPlayer,                     // 0x17
        };

        internal static bool HasStreamFiles => StreamDirExists && StreamFiles().Length > 0;

        private static bool StreamDirExists => Directory.Exists(StreamDir);

        internal static string StreamDir
        {
            get
            {
                var dir = new DirectoryInfo(AppContext.BaseDirectory);
                while (dir != null)
                {
                    if (File.Exists(Path.Combine(dir.FullName, "handoff.md")))
                        return Path.Combine(dir.FullName, "tests", "U1-golden");
                    dir = dir.Parent;
                }
                throw new DirectoryNotFoundException(
                    $"无法从 {AppContext.BaseDirectory} 向上定位仓库根（未找到 handoff.md）");
            }
        }

        internal static string SkipReason =>
            $"未找到命令流文件（{StreamDir} 下没有 *.stream）。" +
            "按 docs/U1-command-stream-golden-plan.md §2 在 Windows 机器抓流后放入该目录，" +
            "本用例自动转为实测。";

        private static string[] StreamFiles() => Directory.GetFiles(StreamDir, "*.stream");

        [GoldenStreamFact]
        public void Replay_recorded_wpf_command_streams()
        {
            foreach (string path in StreamFiles())
            {
                ReplayFile(path);
            }
        }

        private static void ReplayFile(string path)
        {
            byte[] data = File.ReadAllBytes(path);
            Assert.True(data.Length >= Magic.Length, $"{path} 太短，不是合法流文件");
            for (int i = 0; i < Magic.Length; i++)
                Assert.Equal(Magic[i], data[i]);

            var channel = new MilChannel(new MilPartition()) { Dispatcher = new MilCommandDispatcher() };
            var createdHandles = new List<uint>();
            var pendingReleases = new List<uint>();
            int records = 0;

            int pos = Magic.Length;
            while (pos < data.Length)
            {
                Assert.True(pos + 5 <= data.Length, $"{path} 偏移 {pos} 记录头越界");
                byte op = data[pos];
                uint cbSize = BitConverter.ToUInt32(data, pos + 1);
                pos += 5;
                Assert.True(pos + cbSize <= data.Length, $"{path} 偏移 {pos} 载荷越界");
                ReadOnlySpan<byte> payload = data.AsSpan(pos, (int)cbSize);
                pos += (int)cbSize;
                records++;

                switch (op)
                {
                    case OpBeginCommand:
                    {
                        // payload = cbExtra(u32) + 命令字节
                        Assert.True(payload.Length >= 4, $"{path} BeginCommand 载荷缺 cbExtra");
                        uint cbExtra = BitConverter.ToUInt32(payload);
                        int hr = channel.BeginCommand(payload.Slice(4), cbExtra);
                        Assert.Equal(HResult.S_OK, hr);
                        break;
                    }
                    case OpAppendCommandData:
                    {
                        int hr = channel.AppendCommandData(payload);
                        Assert.Equal(HResult.S_OK, hr);
                        break;
                    }
                    case OpEndCommand:
                    {
                        int hr = channel.EndCommand();
                        Assert.Equal(HResult.S_OK, hr);
                        break;
                    }
                    case OpCommitChannel:
                    {
                        int hr = channel.Commit();
                        Assert.Equal(HResult.S_OK, hr);
                        // ★ 原生语义：`MilResource_ReleaseOnChannel` 只是**标记**删除，
                        //   真正的摘除推迟到"引用该资源的未提交批次"下发之后。真实 wpfgfx 会在
                        //   批次还压着的时候就发 release（实测原样流里有 51 处这种交错）。
                        //   所以这里在 Commit **之后**才把待释放句柄真正摘掉 —— 否则回放器会
                        //   比原生更早删资源，批次里的命令在 Commit 时找不到句柄，误报 E_HANDLE。
                        FlushPendingReleases(channel, pendingReleases);
                        break;
                    }
                    case OpCreateOrAddRefOnChannel:
                    {
                        // payload = type(u32) + handle(u32)（句柄为 Windows 侧回填值）
                        Assert.Equal(8, payload.Length);
                        uint type = BitConverter.ToUInt32(payload);
                        uint handle = BitConverter.ToUInt32(payload.Slice(4));
                        DUCE.ResourceHandle h = new DUCE.ResourceHandle(handle);
                        // 直接复用流里的句柄值：表会对未见过的句柄重建条目（见
                        // MilResourceTable.CreateOrAddRef 的宽容分支），保证与 Windows 侧同号。
                        DUCE.ResourceHandle result =
                            channel.Resources.CreateOrAddRef((DUCE.ResourceType)type, ref h);
                        Assert.Equal(handle, (uint)result);
                        createdHandles.Add(handle);
                        break;
                    }
                    case OpReleaseOnChannel:
                    {
                        // payload = handle(u32)
                        // ★ 只**标记**待释放（见 OpCommitChannel 的说明）：原生通道把删除推迟到
                        //   批次下发之后，回放器必须照抄这个生命周期模型，否则会误报 E_HANDLE。
                        Assert.Equal(4, payload.Length);
                        uint handle = BitConverter.ToUInt32(payload);
                        Assert.Contains(handle, createdHandles);
                        pendingReleases.Add(handle);
                        createdHandles.Remove(handle);
                        break;
                    }
                    default:
                        Assert.Fail($"{path} 未知记录 op={op}");
                        break;
                }
            }

            // 流末尾：把还没等到下一次 Commit 的待释放句柄收尾（原生在通道关闭时同样会清）
            FlushPendingReleases(channel, pendingReleases);

            // 黑盒验收口径（docs/U1-command-stream-golden-plan.md §3）
            Assert.True(records > 0, $"{path} 没有读到任何记录（流文件空或格式错）");
            Assert.Equal(0L, channel.FailedCommands);
            Assert.True(channel.CommittedCommands > 0,
                $"{path} 没有提交任何命令（流内容可疑）");
            foreach (KeyValuePair<MilCmd, long> kv in channel.NotImplRegistry)
                Assert.True(AllowedNotImpl.Contains(kv.Key),
                    $"{path} 中 {kv.Key} 被拒 {kv.Value} 次，但不在 7 条文档化 E_NOTIMPL 内");
            Assert.True(channel.ShortCommands == 0,
                $"{path} 有 {channel.ShortCommands} 条 Append 不足 cbExtra 的命令（抓流/格式可疑）");
        }

        /// <summary>
        /// 真正摘除待释放句柄。调用点只有两处：每次 Commit 之后、以及流末尾。
        /// 返回值不参与断言——句柄可能已被批次里的 `MilCmdChannelDeleteResource` 删掉，
        /// 这在原生侧同样不会报错。
        /// </summary>
        private static void FlushPendingReleases(MilChannel channel, List<uint> pending)
        {
            foreach (uint h in pending)
                channel.Resources.Release(new DUCE.ResourceHandle(h), out _);
            pending.Clear();
        }
    }
}

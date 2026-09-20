// M7c · Phase 1：用**原生导出面**驱动一条完整链路，断言像素真的落到 X server。
//
// ── 这条链路上每一环在测什么 ────────────────────────────────────────────────
//   ┌─ Win32 shim ────────────────────────────────────────────────────────┐
//   │ RegisterClassExW → CreateWindowExW →（WS_VISIBLE）XMapWindow          │
//   │            ↓ 返回 HWND —— M7b 已实证 **HWND == X11 XID**              │
//   └──────────────────────────────────────────────────────────────────────┘
//            ↓ IntPtr hwnd
//   MilVisualTarget_AttachToHwnd(hwnd)          ← M7a：身份登记；M7c：+绑 X11 呈现目标
//            ↓
//   WgxConnection_Create(true)                  ← 建 DUCE 连接（SameThread）
//            ↓
//   MilConnection_CreateChannel(conn, 0)        ← 建通道（带 MilCommandDispatcher）
//            ↓ MilChannel_BeginCommand / AppendCommandData / EndCommand（**线上字节格式**）
//   MilCmdHwndTargetCreate(0x31)  → 目标资源，NativeWindow = hwnd
//   MilCmdSolidColorBrush(0x4b)   → 画刷资源
//   MilCmdRenderData(0x2b)        → 指令流资源（MilDrawRectangle 记录）
//   MilCmdVisualSetContent(0x0f)  → 根视觉的 Content
//   MilCmdTargetSetRoot(0x35)     → 通道根（SetRootFromHandle 投影成契约 MilVisual）
//            ↓
//   WgxConnection_SameThreadPresent(conn)       ← M7a：只 Commit；M7c：渲染 + Present + XSync
//            ↓ SkiaRenderBackend.RenderVisualTree → X11PresentationTarget.Present（XPutImage）
//   ┌─ 独立进程 xwd ──────────────────────────────────────────────────────┐
//   │ 从**另一条 X 连接**读回像素 → convert → PNG → 逐像素断言              │
//   └──────────────────────────────────────────────────────────────────────┘
//
// ── 为什么截屏必须用 xwd（对齐 HelloMil 的证据链标准）────────────────────────
//   自己 XGetImage 读回来 = 验证"我刚写进去的 buffer 能不能原样读回来"，
//   而"Present 到 X server"那一半根本没被测到。xwd 是**独立进程**、走 server 的
//   另一条连接与另一套编码路径；它能看到内容，才说明窗口真被映射、真被绘制。

using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Rendering;
using WpfGfx.Linux.Resources;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.Presentation
{
    public sealed unsafe class M7cChainTests : IDisposable
    {
        private readonly ITestOutputHelper _out;

        public M7cChainTests(ITestOutputHelper output) => _out = output;

        public void Dispose() => MilNative.ResetProcessStateForTests();

        // ── 画面参数（像素断言直接引用这些常量）──────────────────────────
        private const int W = 320;
        private const int H = 200;
        private static readonly SKColor ClearColor = SKColors.White;
        private static readonly SKColor LeftFill = new SKColor(200, 30, 30);     // 左半：红
        private static readonly SKColor RightFill = new SKColor(20, 70, 200);    // 右半：蓝

        private const uint TYPE_VISUAL = 0x27;
        private const uint TYPE_RENDERDATA = 0x2b;
        private const uint TYPE_HWNDRENDERTARGET = 0x2e;
        private const uint TYPE_SOLIDCOLORBRUSH = 0x4b;

        // ══════════════════════════════════════════════════════════════════
        //  主链路
        // ══════════════════════════════════════════════════════════════════
        [X11Fact]
        [Trait("Category", "X11")]
        public void Chain_Win32Window_MilTarget_Render_Present_XwdPixels()
        {
            MilNative.ResetProcessStateForTests();

            string title = "M7c-Chain-" + Guid.NewGuid().ToString("N").Substring(0, 8);
            IntPtr hwnd = IntPtr.Zero;
            IntPtr connection = IntPtr.Zero;
            IntPtr channel = IntPtr.Zero;
            string png = null;

            try
            {
                // ---------- 1. 真窗口（经 Win32 shim，与 HwndWrapper 同一条建窗路径）----------
                hwnd = Win32Shim.CreateWindow(title, W, H);
                ulong xid = Win32Shim.GetX11Window(hwnd);
                _out.WriteLine($"[1] HWND = 0x{hwnd.ToInt64():x}；shim 认为它的 X11 XID = 0x{xid:x}");
                Assert.NotEqual(IntPtr.Zero, hwnd);
                Assert.Equal((ulong)hwnd.ToInt64(), xid);   // ★ HWND == XID（M7b 结论在 M7c 复用）

                // ---------- 2. 绑定呈现目标 ----------
                Assert.Equal(HResult.S_OK, MilNative.MilVisualTarget_AttachToHwnd(hwnd));
                Assert.True(MilPresentation.HasTarget(hwnd),
                    $"Attach 之后应当已经绑定呈现目标；绑定错误：{MilPresentation.BindError(hwnd)}");
                Assert.Equal(1, MilPresentation.TargetCount);
                Assert.True(MilPresentation.TryGetTarget(hwnd, out var boundTarget));
                Assert.False(boundTarget.OwnsWindow,   // ★ 包装既有窗口：不拥有它的生命周期
                    "呈现目标不该拥有 WPF 的窗口（销毁归 Win32 shim 的 DestroyWindow）");
                _out.WriteLine($"[2] 呈现目标已绑定：OwnsWindow={boundTarget.OwnsWindow} " +
                               $"NativeHandle=0x{boundTarget.NativeHandle.ToInt64():x}");
                Assert.Equal(hwnd, boundTarget.NativeHandle);

                // ---------- 3. 连接 + 通道 ----------
                Assert.Equal(HResult.S_OK, MilNative.WgxConnection_Create(true, out connection));
                Assert.NotEqual(IntPtr.Zero, connection);
                Assert.Equal(HResult.S_OK,
                    MilNative.MilConnection_CreateChannel(connection, IntPtr.Zero, out channel));
                Assert.NotEqual(IntPtr.Zero, channel);
                _out.WriteLine($"[3] 连接 = 0x{connection.ToInt64():x}；通道 = 0x{channel.ToInt64():x}");

                // ---------- 4. 线上命令：目标 / 画刷 / 指令流 / 视觉树 ----------
                DUCE.ResourceHandle hTarget = CreateResource(channel, TYPE_HWNDRENDERTARGET);
                Send(channel, MilCommandEncoder.HwndTargetCreate(
                    hTarget, (ulong)hwnd.ToInt64(), 0, 0,
                    W, H, ToMilColor(ClearColor), 0,
                    DUCE.ResourceHandle.Null, 0, 0, 0, 96.0, 96.0));

                DUCE.ResourceHandle hRed = CreateResource(channel, TYPE_SOLIDCOLORBRUSH);
                Send(channel, MilCommandEncoder.SolidColorBrush(hRed, ToMilColor(LeftFill)));

                DUCE.ResourceHandle hBlue = CreateResource(channel, TYPE_SOLIDCOLORBRUSH);
                Send(channel, MilCommandEncoder.SolidColorBrush(hBlue, ToMilColor(RightFill)));

                DUCE.ResourceHandle hData = CreateResource(channel, TYPE_RENDERDATA);
                Send(channel, MilCommandEncoder.RenderData(hData, BuildRectStream(
                    (0, 0, W / 2, H, hRed), (W / 2, 0, W, H, hBlue))));

                DUCE.ResourceHandle hRoot = CreateResource(channel, TYPE_VISUAL);
                Send(channel, MilCommandEncoder.VisualSetContent(hRoot, hData));

                Send(channel, MilCommandEncoder.TargetSetRoot(hTarget, hRoot));

                _out.WriteLine($"[4] 命令已入队：target=0x{hTarget.Value:x} root=0x{hRoot.Value:x} " +
                               $"data=0x{hData.Value:x} brushes=0x{hRed.Value:x}/0x{hBlue.Value:x}");

                var mch = MilChannelRegistry.Resolve(channel);
                Assert.NotNull(mch);
                Assert.Equal(0, mch.FailedCommands);
                Assert.Equal(0, mch.NotImplCommands);

                // ---------- 5. 提交 + 呈现 ----------
                Assert.Equal(HResult.S_OK, MilNative.WgxConnection_SameThreadPresent(connection));
                _out.WriteLine($"[5] Present：PresentCalls={MilPresentation.PresentCalls} " +
                               $"FramesPresented={MilPresentation.FramesPresented} " +
                               $"DrawnCommands={MilPresentation.DrawnCommands} " +
                               $"NotDrawnKinds={MilPresentation.NotDrawnCommands}");

                Assert.Equal(1, MilPresentation.PresentCalls);
                Assert.Equal(1, MilPresentation.FramesPresented);   // ★ 真的出了一帧
                Assert.True(MilPresentation.DrawnCommands >= 2,     // ★ 两条矩形指令都画了
                    $"只画了 {MilPresentation.DrawnCommands} 条指令，期望 ≥2");
                Assert.Equal(0, MilPresentation.NotDrawnCommands);  // ★ 没有"少画了东西"
                Assert.Null(MilPresentation.BindError(hwnd));

                // ---------- 6. 独立进程 xwd 截屏 ----------
                png = Path.Combine(AppContext.BaseDirectory, "artifacts", "m7c-chain.png");
                Directory.CreateDirectory(Path.GetDirectoryName(png));
                HelloMil.HelloMilScreenshot.Capture((ulong)hwnd.ToInt64(), null, png);
                Assert.True(new FileInfo(png).Length > 0, "xwd/convert 没产出 PNG");
                _out.WriteLine($"[6] xwd 截屏 → {png}（{new FileInfo(png).Length} 字节）");

                // ---------- 7. 逐像素断言 ----------
                using SKBitmap bmp = SKBitmap.Decode(png);
                Assert.NotNull(bmp);
                _out.WriteLine($"[7] PNG 尺寸 = {bmp.Width}x{bmp.Height}（窗口 {W}x{H}）");
                Assert.Equal(W, bmp.Width);
                Assert.Equal(H, bmp.Height);

                // 左半中心 = 红，右半中心 = 蓝，两处都必须**远离**清屏色（白）
                SKColor left = bmp.GetPixel(W / 4, H / 2);
                SKColor right = bmp.GetPixel(W * 3 / 4, H / 2);
                _out.WriteLine($"     左半中心 ({W / 4},{H / 2}) = {Describe(left)}  期望 {Describe(LeftFill)}");
                _out.WriteLine($"     右半中心 ({W * 3 / 4},{H / 2}) = {Describe(right)} 期望 {Describe(RightFill)}");
                AssertPixelClose(LeftFill, left, 8, "左半矩形");
                AssertPixelClose(RightFill, right, 8, "右半矩形");
                Assert.NotEqual(ClearColor, left);
                Assert.NotEqual(ClearColor, right);

                // 全图统计：三种颜色各自的像素占比要合理 —— 单独一个点可能是巧合，
                // 整片区域的分布才是"真的画了两块"的证据。
                var histogram = CountColors(bmp);
                _out.WriteLine($"     颜色分布（容差 8）：红={histogram.Red} 蓝={histogram.Blue} 白={histogram.White} 其它={histogram.Other}");
                Assert.True(histogram.Red > W * H / 4, $"红色像素 {histogram.Red} 太少（期望 > {W * H / 4}）");
                Assert.True(histogram.Blue > W * H / 4, $"蓝色像素 {histogram.Blue} 太少（期望 > {W * H / 4}）");
                Assert.True(histogram.Other < W * H / 100, $"意外颜色像素 {histogram.Other} 过多（>1%）");

                WriteEvidence(title, hwnd, xid, connection, channel, hTarget, hRoot, histogram, png);
            }
            finally
            {
                if (channel != IntPtr.Zero) MilNative.MilConnection_DestroyChannel(channel);
                if (connection != IntPtr.Zero) MilNative.WgxConnection_Disconnect(connection);
                if (hwnd != IntPtr.Zero) MilNative.MilVisualTarget_DetachFromHwnd(hwnd);
                Win32Shim.Close(hwnd);
            }
        }

        // ══════════════════════════════════════════════════════════════════
        //  失败必须**响亮**：有窗口、有根、但绑不上 → 返回失败码，不是"成功但没画"
        // ══════════════════════════════════════════════════════════════════
        [X11Fact]
        [Trait("Category", "X11")]
        public void Present_WithUnboundWindow_FailsLoudly()
        {
            MilNative.ResetProcessStateForTests();

            // 建一个真窗口但**不** Attach（模拟"呈现目标没绑上"）
            IntPtr hwnd = Win32Shim.CreateWindow("M7c-Unbound-" + Guid.NewGuid().ToString("N").Substring(0, 6), W, H);
            IntPtr connection = IntPtr.Zero, channel = IntPtr.Zero;
            try
            {
                Assert.Equal(HResult.S_OK, MilNative.WgxConnection_Create(true, out connection));
                Assert.Equal(HResult.S_OK,
                    MilNative.MilConnection_CreateChannel(connection, IntPtr.Zero, out channel));

                DUCE.ResourceHandle hTarget = CreateResource(channel, TYPE_HWNDRENDERTARGET);
                Send(channel, MilCommandEncoder.HwndTargetCreate(
                    hTarget, (ulong)hwnd.ToInt64(), 0, 0, W, H, ToMilColor(ClearColor), 0,
                    DUCE.ResourceHandle.Null, 0, 0, 0, 96.0, 96.0));

                DUCE.ResourceHandle hData = CreateResource(channel, TYPE_RENDERDATA);
                Send(channel, MilCommandEncoder.RenderData(hData, BuildRectStream(
                    (0, 0, W, H, CreateBrush(channel, LeftFill)))));
                DUCE.ResourceHandle hRoot = CreateResource(channel, TYPE_VISUAL);
                Send(channel, MilCommandEncoder.VisualSetContent(hRoot, hData));
                Send(channel, MilCommandEncoder.TargetSetRoot(hTarget, hRoot));

                int hr = MilNative.WgxConnection_SameThreadPresent(connection);
                _out.WriteLine($"未绑定窗口时 Present 返回 0x{hr:x8}（{HResult.Name(hr)}）；" +
                               $"诊断：{MilDiagnostics.Last()}");

                Assert.True(HResult.Failed(hr),
                    "有窗口目标 + 有根视觉却没有绑定呈现目标时，必须返回失败码——" +
                    "返回 S_OK 就是「看起来成功但屏幕没变」，正是本项目要杜绝的");
                Assert.Equal(0, MilPresentation.FramesPresented);
                Assert.Contains("未绑定呈现目标", MilDiagnostics.Last() ?? "");
            }
            finally
            {
                if (channel != IntPtr.Zero) MilNative.MilConnection_DestroyChannel(channel);
                if (connection != IntPtr.Zero) MilNative.WgxConnection_Disconnect(connection);
                Win32Shim.Close(hwnd);
            }
        }

        // ══════════════════════════════════════════════════════════════════
        //  离屏通道（没有窗口目标）行为**与 M7a 逐条一致**：只 Commit，S_OK
        // ══════════════════════════════════════════════════════════════════
        [Fact]
        public void Present_OffscreenChannel_KeepsM7aBehavior()
        {
            MilNative.ResetProcessStateForTests();

            Assert.Equal(HResult.S_OK, MilNative.WgxConnection_Create(true, out IntPtr connection));
            Assert.Equal(HResult.S_OK,
                MilNative.MilConnection_CreateChannel(connection, IntPtr.Zero, out IntPtr channel));
            try
            {
                DUCE.ResourceHandle hBrush = CreateResource(channel, TYPE_SOLIDCOLORBRUSH);
                Send(channel, MilCommandEncoder.SolidColorBrush(hBrush, ToMilColor(LeftFill)));

                Assert.Equal(HResult.S_OK, MilNative.WgxConnection_SameThreadPresent(connection));
                var mch = MilChannelRegistry.Resolve(channel);
                Assert.Equal(1, mch.CommittedCommands);
                // 语义区分（两个计数器刻意分开）：
                //   PresentCalls    = 呈现流程**看过**这个通道几次（含"看一眼发现没窗口"）
                //   FramesPresented = 真的渲染并推到 X server 的帧数
                // 离屏通道正确行为是"看过、但不发帧"，所以这两个值必须不同 ——
                // 用 PresentCalls 判"有没有出图"会得出错误结论。
                Assert.Equal(1, MilPresentation.PresentCalls);
                Assert.Equal(0, MilPresentation.FramesPresented);      // ★ 没有窗口 → 不发帧
                Assert.Equal(0, MilPresentation.TargetCount);
                _out.WriteLine("离屏通道：Commit 生效，未发帧（与 M7a 一致）");
            }
            finally
            {
                MilNative.MilConnection_DestroyChannel(channel);
                MilNative.WgxConnection_Disconnect(connection);
            }
        }

        // ==================================================================
        //  辅助
        // ==================================================================

        private static DUCE.ResourceHandle CreateResource(IntPtr channel, uint type)
        {
            DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
            int hr = MilNative.MilResource_CreateOrAddRefOnChannel(
                channel, (DUCE.ResourceType)type, ref h);
            Assert.Equal(HResult.S_OK, hr);
            Assert.False(h.IsNull);
            return h;
        }

        private static DUCE.ResourceHandle CreateBrush(IntPtr channel, SKColor color)
        {
            DUCE.ResourceHandle h = CreateResource(channel, TYPE_SOLIDCOLORBRUSH);
            Send(channel, MilCommandEncoder.SolidColorBrush(h, ToMilColor(color)));
            return h;
        }

        /// <summary>按 DUCE 的线上格式发一条命令（BeginCommand → EndCommand）。</summary>
        private static void Send(IntPtr channel, byte[] command)
        {
            int hr;
            fixed (byte* p = command)
            {
                hr = MilNative.MilChannel_BeginCommand(channel, p, (uint)command.Length, 0);
            }
            Assert.Equal(HResult.S_OK, hr);
            Assert.Equal(HResult.S_OK, MilNative.MilChannel_EndCommand(channel));
        }

        /// <summary>
        /// 拼 RenderData 指令流：每条记录 = [int32 size][int32 id][payload]，
        /// MilDrawRectangle 的载荷是 rect(4×double) + hBrush(u32) + hPen(u32) = 40 字节
        /// （格式取自 Commands/MilRenderData.cs 的解码器，不是猜的）。
        /// </summary>
        private static byte[] BuildRectStream(params (double L, double T, double R, double B, DUCE.ResourceHandle Brush)[] rects)
        {
            var buffer = new List<byte>(rects.Length * 48);
            foreach (var r in rects)
            {
                buffer.AddRange(BitConverter.GetBytes(48));                 // size = 8 + 40
                buffer.AddRange(BitConverter.GetBytes((int)MilDrawCommand.MilDrawRectangle));  // 0x40
                buffer.AddRange(BitConverter.GetBytes(r.L));
                buffer.AddRange(BitConverter.GetBytes(r.T));
                buffer.AddRange(BitConverter.GetBytes(r.R));
                buffer.AddRange(BitConverter.GetBytes(r.B));
                buffer.AddRange(BitConverter.GetBytes(r.Brush.Value));      // @32
                buffer.AddRange(BitConverter.GetBytes(0u));                 // hPen = Null @36
            }
            return buffer.ToArray();
        }

        private static MilColorF ToMilColor(SKColor c) =>
            SkiaColor.MakeScRgb(c.Red, c.Green, c.Blue, c.Alpha);

        private static string Describe(SKColor c) => $"#{c.Red:x2}{c.Green:x2}{c.Blue:x2}";

        private static void AssertPixelClose(SKColor expected, SKColor actual, int tolerance, string what)
        {
            int dr = Math.Abs(expected.Red - actual.Red);
            int dg = Math.Abs(expected.Green - actual.Green);
            int db = Math.Abs(expected.Blue - actual.Blue);
            Assert.True(dr <= tolerance && dg <= tolerance && db <= tolerance,
                $"{what}：期望 {Describe(expected)}，实测 {Describe(actual)}（Δ=({dr},{dg},{db})，容差 {tolerance}）");
        }

        private static (int Red, int Blue, int White, int Other) CountColors(SKBitmap bmp)
        {
            int red = 0, blue = 0, white = 0, other = 0;
            for (int y = 0; y < bmp.Height; y++)
            {
                for (int x = 0; x < bmp.Width; x++)
                {
                    SKColor c = bmp.GetPixel(x, y);
                    if (Near(c, LeftFill)) red++;
                    else if (Near(c, RightFill)) blue++;
                    else if (Near(c, ClearColor)) white++;
                    else other++;
                }
            }
            return (red, blue, white, other);

            static bool Near(SKColor a, SKColor b) =>
                Math.Abs(a.Red - b.Red) <= 8 && Math.Abs(a.Green - b.Green) <= 8 &&
                Math.Abs(a.Blue - b.Blue) <= 8;
        }

        /// <summary>证据落盘（报告直接引用，不靠"我记得跑过"）。</summary>
        private void WriteEvidence(string title, IntPtr hwnd, ulong xid, IntPtr connection,
                                   IntPtr channel, DUCE.ResourceHandle hTarget, DUCE.ResourceHandle hRoot,
                                   (int Red, int Blue, int White, int Other) hist, string png)
        {
            try
            {
                string dir = Path.Combine(AppContext.BaseDirectory, "artifacts");
                Directory.CreateDirectory(dir);
                File.WriteAllText(Path.Combine(dir, "m7c-chain.txt"),
                    "M7c · Phase 1 链路证据（原生导出面驱动）\n" +
                    "======================================\n" +
                    $"窗口标题           : {title}\n" +
                    $"HWND (Win32 shim)  : 0x{hwnd.ToInt64():x}\n" +
                    $"X11 XID            : 0x{xid:x}  （HWND == XID：{(ulong)hwnd.ToInt64() == xid}）\n" +
                    $"DUCE 连接          : 0x{connection.ToInt64():x}\n" +
                    $"DUCE 通道          : 0x{channel.ToInt64():x}\n" +
                    $"目标资源            : 0x{hTarget.Value:x}（TYPE_HWNDRENDERTARGET=0x2e）\n" +
                    $"根视觉              : 0x{hRoot.Value:x}（TYPE_VISUAL=0x27）\n" +
                    $"PresentCalls       : {MilPresentation.PresentCalls}\n" +
                    $"FramesPresented    : {MilPresentation.FramesPresented}\n" +
                    $"绘制指令数          : {MilPresentation.DrawnCommands}\n" +
                    $"未绘制指令种类      : {MilPresentation.NotDrawnCommands}\n" +
                    $"截屏 PNG           : {png}\n" +
                    $"像素分布（容差8）   : 红={hist.Red} 蓝={hist.Blue} 白={hist.White} 其它={hist.Other}\n" +
                    $"窗口像素总数        : {W * H}\n");
            }
            catch { /* 证据落盘失败不该让用例失败 */ }
        }
    }
}

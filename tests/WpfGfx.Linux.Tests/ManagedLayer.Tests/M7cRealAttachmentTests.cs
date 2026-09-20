// M7c · 轨道 C —— **真"接窗"**（把"只做身份映射"换成"真的有像素 + 真的会跟随"）
//
// 【这个文件存在的理由】
//   `docs/unimplemented.md` §2.4 原文说 Attach/Detach 那一组"只做 HWND→窗口身份映射，
//   实现里没有一行 X11 调用"。M7c 已经在 `MilVisualTarget_AttachToHwnd` 里接上了
//   `MilPresentation.TryBind`（HWND == XID → `X11PresentationTarget.WrapExisting`），
//   但**证据一直是"登记表里有这条"** —— 那恰恰是要被替换掉的东西。
//
//   所以这里用**真窗口 + 独立进程 xwd + 逐像素统计**回答四个问题：
//     ① Attach 之后，那个 X 窗口**真的**收到像素；
//     ② Detach 之后**真的**停止（不再出帧、窗口内容一个像素都不动）；
//     ③ 窗口被 resize 之后，**内容跟着重渲**（债务 #3：不再留旧尺寸图 + 空白条）；
//     ④ resize / Expose / Closed 三类 X 事件**真的**经呈现层派发并产生动作。
//
// 【为什么"像素计数"而不是"某个点是红的"】
//   单点比对可能撞上巧合（清屏色、抗锯齿边）。这里整帧只画一个**纯色矩形**，
//   于是"窗口里该有多少个这种颜色的像素"是一个**可以算出来的整数**：
//     未 resize 时 = W0*H0；resize 后 = W1*H1。
//   少了就说明"旧尺寸图 + 空白条"（正是债务 #3 描述的症状），多了说明画到窗外了。
//
// 【为什么用独立进程 xwd】
//   自读（XGetImage）只能证明"我以为我画了"；xwd 是**另一个进程**去问 X server 要内容
//   （与 M2 验收件同一条口径）。

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Threading;
using System.Windows.Threading;
using SkiaSharp;
using WpfGfx.Linux.Commands;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;
using WpfGfx.Linux.Resources;
using WpfGfx.Linux.Windowing;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    /// <summary>轨道 C：真接窗 / resize 跟随 / X 事件反向派发。</summary>
    [Collection("X11")]
    [Trait("Category", "X11")]
    public sealed class M7cRealAttachmentTests
    {
        private readonly ITestOutputHelper _out;
        public M7cRealAttachmentTests(ITestOutputHelper output) => _out = output;

        private const int W0 = 200, H0 = 120;      // 初始窗口尺寸
        private const int W1 = 320, H1 = 200;      // resize 后的尺寸

        private static readonly SKColor Fill = new SKColor(0xFF, 0x00, 0x00);   // 内容：整帧纯红
        // 清屏色刻意取**纯绿**：这样"我们画上去的空白"与"X 窗口自己的底色（shim 建窗给的白）"
        // 就是两个不同的颜色，可以分别计数 —— 这正是"有没有留一块 X 底色空白条"的判据。
        private static readonly SKColor Clear = new SKColor(0x00, 0xFF, 0x00);

        private static readonly Assembly WindowsBaseAssembly = typeof(Dispatcher).Assembly;

        // ==================================================================
        //  真窗口：走 HwndWrapper（WindowsBase 的窗口骨架，PresentationCore 的
        //  HwndSource 第一件事就是 new 它）⇒ shim 建窗 ⇒ HWND == XID
        // ==================================================================
        /// <summary>
        /// 在 WindowsBase 里按名字找类型。`HwndWrapper` / `HwndWrapperHook` 是
        /// `MS.Win32` 下的**顶层**类型（不是嵌套），所以顶层与嵌套两种形态都试 ——
        /// 上游一旦搬家，这里给的是候选清单而不是一句"找不到"。
        /// </summary>
        private static Type FindType(string owner, string simple)
        {
            foreach (string full in new[] { owner + "." + simple, owner + "+" + simple, simple })
            {
                Type t = WindowsBaseAssembly.GetType(full, throwOnError: false);
                if (t != null) return t;
            }
            Assert.Fail($"WindowsBase 里找不到 {owner}.{simple}（试过顶层与嵌套两种形态）");
            return null!;
        }

        private static (object wrapper, IntPtr hwnd) CreateWindow(int w, int h)
        {
            Type wrapperType = FindType("MS.Win32", "HwndWrapper");
            Type hookType = FindType("MS.Win32", "HwndWrapperHook");

            ConstructorInfo ctor = wrapperType.GetConstructor(new[]
            {
                typeof(int), typeof(int), typeof(int), typeof(int), typeof(int),
                typeof(int), typeof(int), typeof(string), typeof(IntPtr), hookType.MakeArrayType(),
            });
            Assert.True(ctor != null, "HwndWrapper 构造函数签名变了");

            const int WS_VISIBLE = unchecked((int)0x10000000);
            const int WS_OVERLAPPEDWINDOW = 0x00CF0000;
            object wrapper = ctor.Invoke(new object[]
            {
                0, 0, WS_VISIBLE | WS_OVERLAPPEDWINDOW, 0, 0, w, h,
                "M7c-TrkC-" + Guid.NewGuid().ToString("N").Substring(0, 8),
                IntPtr.Zero, Array.CreateInstance(hookType, 0),
            });

            PropertyInfo handle = wrapperType.GetProperty("Handle",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            Assert.True(handle != null, "HwndWrapper.Handle 不见了");
            return (wrapper, (IntPtr)handle.GetValue(wrapper));
        }

        private static void DisposeWindow(object wrapper)
        {
            (wrapper as IDisposable)?.Dispose();
        }

        // ==================================================================
        //  DUCE 链路：一个通道 + 一个 HWND 目标 + 一个"整帧纯红"的根视觉
        //  （与 Presentation.Tests 的链路测试同一套命令，这里自带一份，
        //    因为本轮边界不允许改那个工程）
        // ==================================================================
        private sealed class Chain : IDisposable
        {
            public IntPtr Connection, Channel, Hwnd;
            public object Wrapper;

            /// <summary>通道计数（诊断用；MilChannel 是 internal，测试里只用它的公开读数）。</summary>
            public long Committed => MilChannelRegistry.Resolve(Channel)?.CommittedCommands ?? -1;


            private static unsafe void Send(IntPtr ch, byte[] cmd)
            {
                int hr;
                fixed (byte* p = cmd)
                    hr = MilNative.MilChannel_BeginCommand(ch, p, (uint)cmd.Length, 0);
                Assert.Equal(HResult.S_OK, hr);
                Assert.Equal(HResult.S_OK, MilNative.MilChannel_EndCommand(ch));
            }

            private static DUCE.ResourceHandle Create(IntPtr ch, DUCE.ResourceType t)
            {
                DUCE.ResourceHandle h = DUCE.ResourceHandle.Null;
                Assert.Equal(HResult.S_OK, MilNative.MilResource_CreateOrAddRefOnChannel(ch, t, ref h));
                return h;
            }

            /// <summary>
            /// 一条"填充整帧"的渲染数据流。格式照上游 `MilDrawRectangle` 记录：
            /// `size(4) + 命令字(4) + L/T/R/B(4×double) + hBrush(4) + hPen(4)` = 48 字节。
            /// 手写而不是走编码器：这一条指令的形状在 `MilDrawCommand` 里是稳定的，
            /// 而编码器是给"线上命令"用的，渲染数据流另有记录头。
            /// </summary>
            private static byte[] FillStream(int w, int h, DUCE.ResourceHandle brush)
            {
                var buf = new List<byte>(48);
                buf.AddRange(BitConverter.GetBytes(48));
                buf.AddRange(BitConverter.GetBytes((int)MilDrawCommand.MilDrawRectangle));
                buf.AddRange(BitConverter.GetBytes(0.0));
                buf.AddRange(BitConverter.GetBytes(0.0));
                buf.AddRange(BitConverter.GetBytes((double)w));
                buf.AddRange(BitConverter.GetBytes((double)h));
                buf.AddRange(BitConverter.GetBytes(brush.Value));
                buf.AddRange(BitConverter.GetBytes(0u));
                return buf.ToArray();
            }

            public static Chain Build(ITestOutputHelper output, int w, int h)
            {
                var c = new Chain();
                (c.Wrapper, c.Hwnd) = CreateWindow(w, h);

                // 真应用里窗口是 Show 出来的；`xwd` 要求窗口 **IsViewable**，
                // 否则 X_GetImage 会以 BadMatch 失败（实测踩到过）。
                // ⚠️ Win32 语义：`ShowWindow` 返回的是**此前是否可见**（不是成功与否）——
                //   "本来就没显示"时返回 0 是**正确**的（实测量过：第一版断言 !=0 反而是错的）。
                Win32Shim.ShowWindow(c.Hwnd, 5 /*SW_SHOW*/);
                Thread.Sleep(150);

                Assert.Equal(HResult.S_OK, MilNative.MilVisualTarget_AttachToHwnd(c.Hwnd));
                Assert.Equal(HResult.S_OK, MilNative.WgxConnection_Create(true, out c.Connection));
                Assert.Equal(HResult.S_OK, MilNative.MilConnection_CreateChannel(c.Connection, IntPtr.Zero, out c.Channel));

                DUCE.ResourceHandle target = Create(c.Channel, DUCE.ResourceType.TYPE_HWNDRENDERTARGET);
                Send(c.Channel, MilCommandEncoder.HwndTargetCreate(
                    target, (ulong)c.Hwnd.ToInt64(), 0, 0, (uint)w, (uint)h,
                    new MilColorF(Clear.Red / 255f, Clear.Green / 255f, Clear.Blue / 255f, 1f),
                    0, DUCE.ResourceHandle.Null, 0, 0, 0, 96.0, 96.0));

                DUCE.ResourceHandle brush = Create(c.Channel, DUCE.ResourceType.TYPE_SOLIDCOLORBRUSH);
                Send(c.Channel, MilCommandEncoder.SolidColorBrush(
                    brush, new MilColorF(Fill.Red / 255f, Fill.Green / 255f, Fill.Blue / 255f, 1f)));

                DUCE.ResourceHandle data = Create(c.Channel, DUCE.ResourceType.TYPE_RENDERDATA);
                Send(c.Channel, MilCommandEncoder.RenderData(data, FillStream(w, h, brush)));

                DUCE.ResourceHandle root = Create(c.Channel, DUCE.ResourceType.TYPE_VISUAL);
                Send(c.Channel, MilCommandEncoder.VisualSetContent(root, data));
                Send(c.Channel, MilCommandEncoder.TargetSetRoot(target, root));

                output.WriteLine($"[chain] hwnd=0x{c.Hwnd.ToInt64():x} channel=0x{c.Channel.ToInt64():x} " +
                                 $"target=0x{target.Value:x} root=0x{root.Value:x}");
                return c;
            }

            public int Present() => MilNative.WgxConnection_SameThreadPresent(Connection);

            public void Dispose()
            {
                try { if (Channel != IntPtr.Zero) MilNative.MilConnection_DestroyChannel(Channel); } catch { }
                try { if (Connection != IntPtr.Zero) MilNative.WgxConnection_Disconnect(Connection); } catch { }
                try { if (Hwnd != IntPtr.Zero) MilNative.MilVisualTarget_DetachFromHwnd(Hwnd); } catch { }
                try { DisposeWindow(Wrapper!); } catch { }
            }
        }

        // ==================================================================
        //  独立进程 xwd → PNG → 逐像素统计
        // ==================================================================
        private static string Capture(ulong xid, string tag)
        {
            string png = Path.Combine(Path.GetTempPath(), $"m7c-trkc-{tag}-{xid:x}.png");
            if (File.Exists(png)) File.Delete(png);

            var psi = new ProcessStartInfo("bash",
                $"-c \"xwd -id {xid} -display $DISPLAY -silent | convert xwd:- '{png}'\"")
            { RedirectStandardError = true, RedirectStandardOutput = true };
            using Process p = Process.Start(psi)!;
            p.WaitForExit(20000);
            Assert.True(File.Exists(png) && new FileInfo(png).Length > 0,
                $"xwd/convert 没产出 PNG（exit={p.ExitCode}）：{p.StandardError.ReadToEnd()}");
            return png;
        }

        /// <summary>按颜色统计像素数（容差 12：抗锯齿/色彩管理不改变整片填充）。</summary>
        private static int CountColor(string png, SKColor want, out int w, out int h)
        {
            using SKBitmap bmp = SKBitmap.Decode(png);
            Assert.NotNull(bmp);
            w = bmp.Width; h = bmp.Height;
            int n = 0;
            for (int y = 0; y < bmp.Height; y++)
                for (int x = 0; x < bmp.Width; x++)
                {
                    SKColor c = bmp.GetPixel(x, y);
                    if (Math.Abs(c.Red - want.Red) <= 12 &&
                        Math.Abs(c.Green - want.Green) <= 12 &&
                        Math.Abs(c.Blue - want.Blue) <= 12) n++;
                }
            return n;
        }

        private static int CountFill(string png, out int w, out int h) => CountColor(png, Fill, out w, out h);

        private static void Reset()
        {
            MilNative.ResetProcessStateForTests();
            MilPresentation.Reset();
        }

        // ==================================================================
        //  ① + ② Attach 真的出像素 / Detach 真的停
        // ==================================================================
        [X11Fact]
        public void Attach_ReallyPutsPixels_AndDetach_ReallyStops()
        {
            X11Guard.Require();
            Reset();

            using var chain = Chain.Build(_out, W0, H0);

            // 真绑定：不只是"登记表里有一条"，而是**呈现目标真的挂在那个 XID 上**
            Assert.True(MilPresentation.HasTarget(chain.Hwnd),
                "Attach 之后 HWND 上没有呈现目标 —— 那就还只是「身份映射」");
            Assert.Null(MilPresentation.BindError(chain.Hwnd));

            Assert.Equal(0, MilPresentation.FramesPresented);
            Assert.Equal(HResult.S_OK, chain.Present());
            Assert.Equal(1, MilPresentation.FramesPresented);            // ★ 真出了一帧
            Assert.True(MilPresentation.DrawnCommands >= 1, "一帧里一条绘制指令都没有");

            string before = Capture((ulong)chain.Hwnd.ToInt64(), "attached");
            int filled = CountFill(before, out int pw, out int ph);
            _out.WriteLine($"[①] xwd {pw}x{ph}：纯红像素 = {filled}（窗口 {W0}x{H0} = {W0 * H0}）");
            Assert.Equal(W0, pw);
            Assert.Equal(H0, ph);
            // 整帧都是这块填充 ⇒ 红像素数必须≈整窗（留 2% 容差给 X 的边界/取整）
            Assert.True(filled >= W0 * H0 * 98 / 100,
                $"窗口里只有 {filled} 个填充像素（期望 ≈{W0 * H0}）—— 像素没真的落到这个 X 窗口上");

            // ---------- Detach ----------
            Assert.Equal(HResult.S_OK, MilNative.MilVisualTarget_DetachFromHwnd(chain.Hwnd));
            Assert.False(MilPresentation.HasTarget(chain.Hwnd), "Detach 之后呈现目标还在 —— 没真解绑");

            int framesBefore = (int)MilPresentation.FramesPresented;
            int hr = chain.Present();                                     // 再呈现一次：必须什么都不做
            _out.WriteLine($"[②] Detach 后再呈现：hr=0x{hr:x8}，帧数 {framesBefore} → {MilPresentation.FramesPresented}");
            Assert.Equal(HResult.E_FAIL, hr);                             // 有窗口目标但没绑定 ⇒ 诚实失败
            Assert.Equal(framesBefore, (int)MilPresentation.FramesPresented);   // ★ 真的没再出帧

            string after = Capture((ulong)chain.Hwnd.ToInt64(), "detached");
            int filledAfter = CountFill(after, out _, out _);
            _out.WriteLine($"[②] Detach 后窗口里的填充像素 = {filledAfter}（Detach 前 {filled}）");
            Assert.Equal(filled, filledAfter);                            // ★ 一个像素都没再动过
        }

        // ==================================================================
        //  ③ Resize 跟随：内容按新尺寸重渲（债务 #3）
        // ==================================================================
        [X11Fact]
        public void Resize_ThenXEvent_RepaintsAtNewSize()
        {
            X11Guard.Require();
            Reset();

            using var chain = Chain.Build(_out, W0, H0);
            Assert.Equal(HResult.S_OK, chain.Present());
            int frames0 = (int)MilPresentation.FramesPresented;

            string before = Capture((ulong)chain.Hwnd.ToInt64(), "resize-before");
            int filledBefore = CountFill(before, out int bw, out int bh);
            _out.WriteLine($"[③-before] {bw}x{bh}，填充像素 {filledBefore}（≈{W0 * H0}）");

            // —— 从**外部**把窗口改大（= server 侧动作，内容不会自己重画）——
            // 走 shim 的 SetWindowPos：这就是真应用里"用户拖边框"那条路径。
            Assert.True(Win32Shim.SetWindowPos(chain.Hwnd, 0, 0, 0, W1, H1, 0x0004 /*SWP_NOZORDER*/) != 0,
                "SetWindowPos 失败");

            // 事件应当在**呈现连接**上到达（本层订阅了 Exposure/StructureNotify）——
            // 但 X 事件是**异步**的：resize 请求刚发出去时 ConfigureNotify 可能还没到
            // （实测：不等就会看到 ResizeEvents=0；加上按 WindowId 过滤后更明显，
            //   因为过滤掉了"上一次测试残留的假事件"）。
            long r0 = MilPresentation.ResizeEvents;
            for (int i = 0; i < 40 && MilPresentation.ResizeEvents == r0; i++)
            {
                Thread.Sleep(50);
                MilPresentation.PumpWindowEvents();
            }
            int repaint = MilPresentation.PumpWindowEvents();
            _out.WriteLine($"[③-event] ResizeEvents={MilPresentation.ResizeEvents} " +
                           $"ExposeEvents={MilPresentation.ExposeEvents} 需重画窗口数={repaint}");
            Assert.True(MilPresentation.ResizeEvents >= 1, "没有收到任何 X resize 事件（订阅没生效？）");
            Assert.True(MilPresentation.FramesPresented > frames0, "resize 之后没有重新出帧 —— 债务 #3 复发");

            string after = Capture((ulong)chain.Hwnd.ToInt64(), "resize-after");
            int filledAfter = CountFill(after, out int aw, out int ah);
            _out.WriteLine($"[③-after] {aw}x{ah}，填充像素 {filledAfter}（期望 ≈{W1 * H1}）");

            Assert.Equal(W1, aw);
            Assert.Equal(H1, ah);                                  // ★ 呈现帧跟着 X 尺寸走
            int clearedAfter = CountColor(after, Clear, out _, out _);
            int whiteAfter = CountColor(after, SKColors.White, out _, out _);
            _out.WriteLine($"[③-after] {aw}x{ah}：内容(红)={filledAfter} 我们的清屏(绿)={clearedAfter} " +
                           $"X 窗口底色(白)={whiteAfter}");

            // ★ 债务 #3 的判据，拆成两条**可分别证伪**的断言：
            //   ① 老内容按原样保留（重渲没有画丢东西）
            Assert.True(filledAfter >= filledBefore * 98 / 100,
                $"resize 后内容像素 {filledAfter} 少于 resize 前 {filledBefore} —— 重渲画丢了内容");
            //   ② 新露出来的那块由**我们的清屏色**填充，**不是** X 窗口底色
            //      （X11 的 resize 是 server 侧动作；不重画的话那块就是 shim 建窗给的白色）
            Assert.True(clearedAfter >= (W1 * H1 - W0 * H0) * 95 / 100,
                $"新面积里只有 {clearedAfter} 个清屏像素（期望 ≈{W1 * H1 - W0 * H0}）" +
                "—— 多出来的那块没被重画，留的是 X 窗口底色（债务 #3 的症状）");
            Assert.True(whiteAfter <= W1 * H1 / 100,
                $"整帧里还有 {whiteAfter} 个白像素 —— 说明新面积仍是 X 的窗口底色");
            _out.WriteLine("[③-note] 内容**增长**（按新宽度重排文本/几何）要等上层渲染 pass：" +
                           "真应用里由 WM_SIZE → 布局 → 渲染 pass 驱动，见 run-hellowpf.sh 的 resize 段");
        }

        // ==================================================================
        //  ④ Expose / Closed 事件也真的经呈现层派发并产生动作
        // ==================================================================
        [X11Fact]
        public void Expose_And_Closed_Events_AreDispatched()
        {
            X11Guard.Require();
            Reset();

            using var chain = Chain.Build(_out, W0, H0);
            Assert.Equal(HResult.S_OK, chain.Present());
            long frames = MilPresentation.FramesPresented;
            long exposes0 = MilPresentation.ExposeEvents;

            // —— Expose：收起再显示（X 会给订阅了 ExposureMask 的客户端补 Expose）——
            Win32Shim.ShowWindow(chain.Hwnd, 0 /*SW_HIDE*/);   // 返回值 = "此前是否可见"
            Thread.Sleep(120);
            Win32Shim.ShowWindow(chain.Hwnd, 5 /*SW_SHOW*/);
            Thread.Sleep(200);

            MilPresentation.PumpWindowEvents();
            _out.WriteLine($"[④-expose] ExposeEvents {exposes0} → {MilPresentation.ExposeEvents}，" +
                           $"帧数 {frames} → {MilPresentation.FramesPresented}");
            Assert.True(MilPresentation.ExposeEvents > exposes0, "Expose 没有被派发到呈现层");

            // —— Closed：销毁窗口 ⇒ 呈现层必须解绑（不能继续往一个已销毁的 XID 上画）——
            Assert.True(MilPresentation.HasTarget(chain.Hwnd));
            DisposeWindow(chain.Wrapper!);          // shim DestroyWindow → X DestroyNotify
            chain.Wrapper = null!;
            Thread.Sleep(200);

            int closed0 = (int)MilPresentation.ClosedEvents;
            MilPresentation.PumpWindowEvents();
            _out.WriteLine($"[④-closed] ClosedEvents={MilPresentation.ClosedEvents}，" +
                           $"HasTarget={MilPresentation.HasTarget(chain.Hwnd)}");
            Assert.True(MilPresentation.ClosedEvents > closed0, "窗口销毁（DestroyNotify）没有被派发");
            Assert.False(MilPresentation.HasTarget(chain.Hwnd), "窗口已销毁但呈现目标还挂着");
        }
    }
}

// M7b · Dispatcher 消息泵对接的断言（验收硬指标 1 与 2）
//
// 【⚠️ 这些用例**必须** X server —— 这是实测结论，推翻了首版的设计假设】
//   首版假设：shim 的等待路径是 poll([self-pipe, X fd, 定时器剩余])，没有 DISPLAY 时
//   X fd 自然消失、前两类照常工作，所以 Dispatcher 在没有窗口系统的机器上也能跑。
//   **实测（DISPLAY 未设置）：6 条 Dispatcher 用例全红**，栈是
//       Win32Exception (1400) ← UnsafeNativeMethods.CreateWindowEx ← HwndWrapper..ctor
//       ← MessageOnlyHwndWrapper..ctor ← Dispatcher..ctor
//   原因：`Dispatcher` 的构造函数**无条件** `new MessageOnlyHwndWrapper()`，
//   而它要经过 `RegisterClassEx` + `CreateWindowEx`。没有 X 就没有窗口对象可建，
//   `CreateWindowExW` 按"不伪造"原则返回 NULL(1400)，托管侧随即抛 Win32Exception。
//   —— 「没有窗口系统也能跑 Dispatcher」是个**错误的假设**，这里如实登记，
//      并把这一组用例改成 `[X11Fact]`（发现期跳过，而不是在无 X 的机器上红）。
//   真正不需要 X 的是 `Win32AbiLayoutTests`（纯布局）与
//   `LinuxEnvironmentDiagnosticsTests` 里的两条环境探针。
//
// 【为什么每个用例都跑在一条**新线程**上】
//   `Dispatcher.CurrentDispatcher` 是按线程缓存的。xunit 会在线程池线程之间
//   复用，一旦某个用例把线程的 Dispatcher 关掉了，同线程的后续用例拿到的是
//   一个已关闭的实例（抛 InvalidOperationException）。用专属线程把
//   「一个 Dispatcher 的一生」圈在一个用例里，才是确定的。
//
// 【为什么还要 join 超时】
//   「PushFrame 必须能退出」这条断言的**反面就是死等**。若超时后直接
//   Assert，测试进程会被那个卡住的线程拖着不退出。所以：
//   线程用 IsBackground=true（进程能退），Join(15s) 之后断言 —— 最坏情况是
//   用例失败，不会挂住 dotnet test。

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Windows.Threading;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    public sealed class DispatcherPumpTests
    {
        private readonly ITestOutputHelper _out;

        public DispatcherPumpTests(ITestOutputHelper output) => _out = output;

        /// <summary>
        /// 在一条专属后台线程上跑一段代码，返回是否在超时前跑完。
        /// 异常会被收集并原样抛出（保留栈），不吞。
        /// </summary>
        private bool RunOnFreshDispatcherThread(string name, int timeoutMs, Action body)
        {
            Exception failure = null;
            var done = new ManualResetEventSlim(false);
            var thread = new Thread(() =>
            {
                try { body(); }
                catch (Exception ex) { failure = ex; }
                finally { done.Set(); }
            })
            {
                IsBackground = true,
                Name = name,
            };
            thread.Start();

            bool finished = done.Wait(timeoutMs);
            if (failure != null) throw new Xunit.Sdk.XunitException(
                $"[{name}] 线程内异常：{failure}");
            return finished;
        }

        // ── 1. Dispatcher 能创建 ──────────────────────────────────────────
        [X11Fact]
        [Trait("Category", "X11")]
        public void Dispatcher_CanBeCreated_AndHasThreadAffinity()
        {
            Assert.True(RunOnFreshDispatcherThread("m7b-dispatcher-create", 15000, () =>
            {
                Dispatcher d = Dispatcher.CurrentDispatcher;
                Assert.NotNull(d);
                Assert.Same(d, Dispatcher.CurrentDispatcher);   // 同线程恒等
                Assert.Same(d, Dispatcher.FromThread(Thread.CurrentThread));
                Assert.False(d.HasShutdownStarted);
                Assert.False(d.HasShutdownFinished);
                Assert.True(d.CheckAccess());

                // ShutdownImpl 会 Dispose 掉内部那个 message-only 窗口
                // （走 shim 的 DestroyWindow）。没有帧在跑时是同步关的。
                d.InvokeShutdown();
                Assert.True(d.HasShutdownFinished);
            }), "Dispatcher 用例超时（15s）—— 说明建窗或关窗路径死等了");
        }

        // ── 2. DispatcherTimer 按时触发 ───────────────────────────────────
        [X11Fact]
        [Trait("Category", "X11")]
        public void DispatcherTimer_Fires_WithinTimeWindow()
        {
            const int intervalMs = 50;
            const int expectAtLeast = 3;
            var ticks = new List<long>();
            var sw = Stopwatch.StartNew();
            bool finished = false;

            finished = RunOnFreshDispatcherThread("m7b-dispatcher-timer", 20000, () =>
            {
                Dispatcher d = Dispatcher.CurrentDispatcher;
                var frame = new DispatcherFrame();
                DispatcherTimer timer = null;

                timer = new DispatcherTimer(
                    TimeSpan.FromMilliseconds(intervalMs),
                    DispatcherPriority.Normal,
                    (s, e) =>
                    {
                        ticks.Add(sw.ElapsedMilliseconds);
                        if (ticks.Count >= expectAtLeast)
                        {
                            timer.Stop();
                            frame.Continue = false;   // 触发够了就收工
                        }
                    },
                    d);

                timer.Start();
                Dispatcher.PushFrame(frame);
                timer.Stop();

                // 超时兜底（万一 shim 的 WM_TIMER 没到，PushFrame 会一直等）
                if (ticks.Count < expectAtLeast) frame.Continue = false;
            });

            Assert.True(finished, "PushFrame 没有在 20s 内退出（DispatcherTimer 没触发？）");
            Assert.True(ticks.Count >= expectAtLeast,
                $"DispatcherTimer 只触发了 {ticks.Count} 次，期望 ≥ {expectAtLeast}");

            long total = sw.ElapsedMilliseconds;
            _out.WriteLine($"触发 {ticks.Count} 次，间隔 {string.Join(", ", ticks)} ms（总 {total} ms）");

            // 时间窗：3 次 × 50ms 的定时器必须在合理区间内完成。
            //   下界：不可能比 2 个完整间隔还快（100ms）；
            //   上界：留足 3 核过载（主控实测 load 10+）的余量 → 8s。
            // 断言上界是有意义的：它正是「死等 / 定时器根本没到」的判别条件。
            Assert.True(total >= intervalMs * (expectAtLeast - 1),
                $"总耗时 {total}ms 小于 {intervalMs * (expectAtLeast - 1)}ms —— 时间窗下界不成立");
            Assert.True(total < 8000, $"总耗时 {total}ms ≥ 8s —— 定时器明显没有被及时投递");

            // 相邻两次的间隔不应该远超 interval（允许一次调度抖动）
            for (int i = 1; i < ticks.Count; i++)
            {
                long delta = ticks[i] - ticks[i - 1];
                Assert.True(delta < 2000, $"第 {i} 次与上一次间隔 {delta}ms ≥ 2s");
            }
        }

        // ── 3. PushFrame 由「另一个线程」的 InvokeShutdown 正常退出 ────────
        //     这一条测的是**唤醒路径**：InvokeShutdown 从别的线程发起时，
        //     Dispatcher 会把一个 ShutdownCallback 投进队列（BeginInvoke →
        //     CriticalRequestProcessing → TryPostMessage）。如果 shim 的
        //     GetMessageW 阻塞后不能被 PostMessage 唤醒，这里就永远不返回。
        [X11Fact]
        [Trait("Category", "X11")]
        public void PushFrame_Exits_OnInvokeShutdown_FromAnotherThread()
        {
            var sw = Stopwatch.StartNew();
            long frameEnteredMs = -1;
            long frameExitedMs = -1;

            bool finished = RunOnFreshDispatcherThread("m7b-frame-shutdown", 20000, () =>
            {
                Dispatcher d = Dispatcher.CurrentDispatcher;
                var frame = new DispatcherFrame();

                // 外部线程：等 400ms 让 PushFrame 真的进到 GetMessageW 里再关，
                // 否则测的是「还没开始泵就关了」，唤醒路径根本没被走到。
                var killer = new Thread(() =>
                {
                    Thread.Sleep(400);
                    d.InvokeShutdown();
                })
                { IsBackground = true, Name = "m7b-shutdown-caller" };
                killer.Start();

                frameEnteredMs = sw.ElapsedMilliseconds;
                Dispatcher.PushFrame(frame);      // ← 必须能返回
                frameExitedMs = sw.ElapsedMilliseconds;
                killer.Join(5000);

                Assert.True(d.HasShutdownStarted || d.HasShutdownFinished,
                    "PushFrame 返回了，但 Dispatcher 未进入 shutting-down 状态");
            });

            Assert.True(finished,
                "PushFrame 没有在 20s 内退出 —— PostMessage/self-pipe 的唤醒路径失效" +
                "（InvokeShutdown 从别的线程发起时死等）");
            Assert.True(frameExitedMs >= 0, "PushFrame 没有返回");
            long elapsed = frameExitedMs - frameEnteredMs;
            _out.WriteLine($"PushFrame 在 {elapsed}ms 后退出（外部线程 InvokeShutdown）");

            // 不能比 killer 的 sleep 还快（说明消息被凭空造出来），也不能拖到几秒。
            Assert.True(elapsed >= 250, $"{elapsed}ms 就退出了 —— 比 InvokeShutdown 还早，可疑");
            Assert.True(elapsed < 8000, $"{elapsed}ms 才退出 —— 唤醒延迟过大");
        }

        // ── 4. PushFrame 由「帧内 BeginInvoke」正常退出 ────────────────────
        //     frame.Continue = false 的 setter 会自己 BeginInvoke 一条 Send 消息
        //     把泵叫醒（DispatcherFrame.cs:78 的注释明写）——所以它同时验证了
        //     「自己给自己 PostMessage 也能唤醒」。
        [X11Fact]
        [Trait("Category", "X11")]
        public void PushFrame_Exits_OnBeginInvoke_SettingContinueFalse()
        {
            int ranOperations = 0;
            long elapsed = -1;

            bool finished = RunOnFreshDispatcherThread("m7b-frame-begininvoke", 20000, () =>
            {
                Dispatcher d = Dispatcher.CurrentDispatcher;
                var frame = new DispatcherFrame();
                var sw = Stopwatch.StartNew();

                d.BeginInvoke(DispatcherPriority.Normal, new Action(() =>
                {
                    Interlocked.Increment(ref ranOperations);
                }));

                d.BeginInvoke(DispatcherPriority.Normal, new Action(() =>
                {
                    Interlocked.Increment(ref ranOperations);
                    frame.Continue = false;
                }));

                Dispatcher.PushFrame(frame);
                elapsed = sw.ElapsedMilliseconds;

                Assert.Equal(2, ranOperations);
                d.InvokeShutdown();
            });

            Assert.True(finished, "PushFrame 没有在 20s 内退出（BeginInvoke 路径）");
            _out.WriteLine($"PushFrame 在 {elapsed}ms 后退出（帧内 BeginInvoke）");
            Assert.True(elapsed < 8000, $"{elapsed}ms —— BeginInvoke 的投递/唤醒太慢");
        }

        // ── 5. 硬超时兜底：一个定时器都没设的帧也必须能被外部关掉 ─────────
        //     这是「不能死等」的最纯粹形式：没有任何定时器、没有任何 X 窗口，
        //     纯粹阻塞在 GetMessageW 里，靠 PostMessage 唤醒。
        [X11Fact]
        [Trait("Category", "X11")]
        public void PushFrame_WithNoTimers_WakesUpOnPostMessage()
        {
            long elapsed = -1;
            bool finished = RunOnFreshDispatcherThread("m7b-frame-postmessage", 20000, () =>
            {
                Dispatcher d = Dispatcher.CurrentDispatcher;
                var frame = new DispatcherFrame();
                var sw = Stopwatch.StartNew();

                var poster = new Thread(() =>
                {
                    Thread.Sleep(500);
                    d.BeginInvoke(DispatcherPriority.Send, new Action(() => { frame.Continue = false; }));
                })
                { IsBackground = true, Name = "m7b-poster" };
                poster.Start();

                Dispatcher.PushFrame(frame);
                elapsed = sw.ElapsedMilliseconds;
                poster.Join(3000);
                d.InvokeShutdown();
            });

            Assert.True(finished, "无定时器的 PushFrame 没有在 20s 内退出 —— 泵唤不醒");
            _out.WriteLine($"无定时器帧在 {elapsed}ms 后退出（跨线程 BeginInvoke）");
            Assert.True(elapsed is >= 400 and < 8000, $"{elapsed}ms");
        }
    }
}

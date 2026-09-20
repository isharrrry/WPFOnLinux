// M7b 烟测（验收硬指标 3 与 4）：真实 X11 窗口 + xdotool 注入事件被托管侧收到。
//
// 【为什么用 HwndWrapper 而不是直接上 HwndSource】
//   `MS.Win32.HwndWrapper` 是 WindowsBase 里**窗口骨架的最后一层**：
//     · Dispatcher 的 message-only 窗口是它（MessageOnlyHwndWrapper）；
//     · PresentationCore 的 HwndSource 第一件事就是 `new HwndWrapper(...)`（HwndSource.cs:256）；
//     · HwndSubclass 的整套窗口过程链挂在它身上。
//   它跑通 = 「消息泵 + 建窗 + WndProc 回退链 + 输入事件翻译」这四块都对。
//   HwndSource 则额外要 HwndTarget（呈现目标 → DUCE → MIL），那是 M7c 的范围，
//   本文件里单独用一个**特征化用例**把它的当前状态钉住（见文件末尾）。
//
// 【HwndWrapper 是 internal，怎么用】
//   用反射。三条理由：
//     1. WindowsBase 的 InternalsVisibleTo 只开给 PresentationCore（+ 上游自测），
//        本测试工程不在名单里；
//     2. 为了测试去改上游的 IVT 或加 shim 友元，属于「为测试改产品」；
//     3. 反射**顺便验证了一件事**：这条路径只依赖公开可见的程序集表面 +
//        真实的原生调用，不依赖任何编译期的 internal 访问技巧。
//   代价：签名漂移不会编译报错。所以每个反射点都 Assert 了成员存在，
//   并在失败信息里带上"上游改了签名"的提示。
//
// 【为什么全部塞进一次 PushFrame】
//   本机 3 核、8 agent 并行（主控实测 load 10+）。建窗、xwininfo、xdotool
//   注入、断言都在**同一次** PushFrame 里按时间线完成：
//     200ms  置位"泵已运行"
//     →  注入线程跑 4 条外部命令（xdotool search / xwininfo / xdotool key / mousemove+click）
//     →  100ms 轮询的检查定时器发现"键和鼠标都收到了"就停帧
//     10s 硬兜底停帧（保证用例失败而不是挂住）

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Threading;
using System.Windows.Threading;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    public sealed class ManagedWindowTests
    {
        private readonly ITestOutputHelper _out;

        public ManagedWindowTests(ITestOutputHelper output) => _out = output;

        /// <summary>
        /// 把证据落到 `artifacts/`（报告直接引用这个文件，不靠"我记得跑过"）。
        /// xunit 默认只在**失败**时打印 ITestOutputHelper，所以必须落盘。
        /// </summary>
        internal static void Evidence(string name, string content)
        {
            try
            {
                string dir = Path.Combine(AppContext.BaseDirectory, "artifacts");
                Directory.CreateDirectory(dir);
                File.WriteAllText(Path.Combine(dir, name), content);
            }
            catch { /* 证据落盘失败不该让用例失败 */ }
        }

        // ── Win32 常量 ─────────────────────────────────────────────────────
        private const int WS_VISIBLE = 0x10000000;
        private const int WS_OVERLAPPEDWINDOW = 0x00CF0000;
        private const int SW_SHOW = 5;

        private const int WM_KEYDOWN = 0x0100;
        private const int WM_KEYUP = 0x0101;
        private const int WM_CHAR = 0x0102;
        private const int WM_LBUTTONDOWN = 0x0201;
        private const int WM_LBUTTONUP = 0x0202;
        private const int WM_MOUSEMOVE = 0x0200;
        private const int WM_PAINT = 0x000F;
        private const int WM_DESTROY = 0x0002;
        private const int WM_NCDESTROY = 0x0082;

        // ── 反射句柄 ───────────────────────────────────────────────────────
        private static readonly Assembly WindowsBaseAssembly = typeof(Dispatcher).Assembly;

        private static Type HwndWrapperType()
        {
            Type t = WindowsBaseAssembly.GetType("MS.Win32.HwndWrapper", throwOnError: false);
            Assert.True(t != null, "WindowsBase 里没有 MS.Win32.HwndWrapper —— 上游改了窗口骨架的类名？");
            return t;
        }

        private static Type HwndWrapperHookType()
        {
            Type t = WindowsBaseAssembly.GetType("MS.Win32.HwndWrapperHook", throwOnError: false);
            Assert.True(t != null, "WindowsBase 里没有 MS.Win32.HwndWrapperHook —— 上游改了 hook 委托名？");
            return t;
        }

        // ── 消息记录 ───────────────────────────────────────────────────────
        private readonly object _gate = new();
        private readonly List<(int Msg, IntPtr W, IntPtr L)> _messages = new();

        private void Record(int msg, IntPtr w, IntPtr l)
        {
            lock (_gate) _messages.Add((msg, w, l));
        }

        private bool Saw(int msg, Func<IntPtr, bool> match = null)
        {
            lock (_gate)
            {
                foreach ((int m, IntPtr w, _) in _messages)
                    if (m == msg && (match == null || match(w))) return true;
            }
            return false;
        }

        private (int Msg, IntPtr W, IntPtr L)[] Snapshot()
        {
            lock (_gate) return _messages.ToArray();
        }

        /// <summary>与 <c>MS.Win32.HwndWrapperHook</c> 逐参数一致的实例方法。</summary>
        private IntPtr OnHookMessage(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            Record(msg, wParam, lParam);
            handled = false;      // 不吞消息：让 DefWindowProc 链照常走
            return IntPtr.Zero;   // 建窗期间返回非 0 会被 HwndWrapper 判成失败
        }

        // ══════════════════════════════════════════════════════════════════
        //  主烟测
        // ══════════════════════════════════════════════════════════════════
        [X11Fact]
        [Trait("Category", "X11")]
        public void HwndWrapper_CreatesRealX11Window_AndReceivesInjectedInput()
        {
            X11Guard.Require();

            string title = "WpfLinux-M7b-" + Guid.NewGuid().ToString("N").Substring(0, 8);
            const int width = 320, height = 200, posX = 40, posY = 60;

            ulong hwndValue = 0;
            ulong x11Window = 0;
            string className = "";
            nint wndProcAfterCreate = 0;

            var frameRunning = new ManualResetEventSlim(false);
            var injectionDone = new ManualResetEventSlim(false);
            var injectorLog = new List<string>();
            bool timedOut = false;
            long frameMs = -1;

            Exception threadFailure = null;
            var finished = new ManualResetEventSlim(false);

            var uiThread = new Thread(() =>
            {
                try
                {
                    Dispatcher d = Dispatcher.CurrentDispatcher;

                    // ---- 建窗（反射调 HwndWrapper 的公共构造函数）----
                    Type wrapperType = HwndWrapperType();
                    Type hookType = HwndWrapperHookType();

                    MethodInfo hookMethod = typeof(ManagedWindowTests).GetMethod(
                        nameof(OnHookMessage), BindingFlags.Instance | BindingFlags.NonPublic);
                    Delegate hook = Delegate.CreateDelegate(hookType, this, hookMethod);

                    Array hooks = Array.CreateInstance(hookType, 1);
                    hooks.SetValue(hook, 0);

                    ConstructorInfo ctor = wrapperType.GetConstructor(new[]
                    {
                        typeof(int), typeof(int), typeof(int), typeof(int), typeof(int),
                        typeof(int), typeof(int), typeof(string), typeof(IntPtr), hookType.MakeArrayType(),
                    });
                    Assert.True(ctor != null,
                        "MS.Win32.HwndWrapper 的构造函数签名变了（期望 7 个 int + string + IntPtr + Hook[]）");

                    object wrapper = ctor.Invoke(new object[]
                    {
                        0,                                   // classStyle
                        WS_VISIBLE | WS_OVERLAPPEDWINDOW,    // style
                        0,                                   // exStyle
                        posX, posY, width, height,
                        title,
                        IntPtr.Zero,                         // 顶层窗口
                        hooks,
                    });

                    PropertyInfo handleProp = wrapperType.GetProperty("Handle");
                    Assert.True(handleProp != null, "HwndWrapper.Handle 属性不见了");
                    IntPtr hwnd = (IntPtr)handleProp.GetValue(wrapper);

                    // HwndWrapper 的析构/Dispose 必须在它自己的线程上跑。
                    // 把窗口对象记下来，帧结束后在本线程销毁。
                    Assert.NotEqual(IntPtr.Zero, hwnd);
                    hwndValue = (ulong)hwnd.ToInt64();

                    // 这一段是「shim 真的把 HWND 做成了 X11 XID」的直接证据：
                    // WpfLinuxWin32_GetX11Window 只在窗口表里查得到时才返回非 0。
                    x11Window = Win32Shim.GetX11Window(hwnd);
                    Assert.Equal(hwndValue, x11Window);

                    nint namePtr = Win32Shim.GetClassNameRaw(hwnd);
                    className = System.Runtime.InteropServices.Marshal.PtrToStringUTF8(namePtr) ?? "";
                    wndProcAfterCreate = Win32Shim.GetWndProc(hwnd);

                    _out.WriteLine($"HWND(=XID) = 0x{hwndValue:x} ({hwndValue})");
                    _out.WriteLine($"窗口类名    = {className}");
                    _out.WriteLine($"GWL_WNDPROC = 0x{wndProcAfterCreate:x}");

                    Assert.StartsWith("HwndWrapper[", className, StringComparison.Ordinal);
                    Assert.NotEqual(0, (long)wndProcAfterCreate);   // HwndSubclass 已挂上链

                    // 窗口表里应该有它（message-only 的 Dispatcher 窗口 + 这一个）
                    Assert.True(Win32Shim.WindowCount() >= 2,
                        $"shim 窗口数 = {Win32Shim.WindowCount()}，至少应有 Dispatcher 的 message-only 窗口 + 本窗口");

                    Win32Shim.ShowWindow(hwnd, SW_SHOW);

                    var frame = new DispatcherFrame();
                    var sw = System.Diagnostics.Stopwatch.StartNew();

                    // ---- 注入线程：全部在**泵运行中**才动手 ----
                    var injector = new Thread(() =>
                    {
                        try
                        {
                            if (!frameRunning.Wait(TimeSpan.FromSeconds(8)))
                            {
                                lock (injectorLog) injectorLog.Add("等待泵运行超时");
                                return;
                            }

                            ulong[] found = XTool.SearchByName(title);
                            lock (injectorLog)
                                injectorLog.Add($"xdotool search --name {title} → [{string.Join(", ", found)}]");
                            Assert.Contains(hwndValue, found);

                            XTool.WindowInfo info = XTool.QueryWindow(hwndValue);
                            lock (injectorLog) injectorLog.Add("xwininfo: " + info);
                            Assert.Equal(width, info.Width);
                            Assert.Equal(height, info.Height);
                            Assert.Equal(title, info.Name);
                            Assert.True(info.IsViewable, $"窗口未映射：{info}");

                            // 键盘：`xdotool key --window <id> a`（与探针 runner 同一手法）。
                            // ⚠️ 实测（补丁 F3 的 KEY_DIAG，2026-09-12）：本机 xdotool 3.20160805 这条
                            //   命令投出来的事件 **`send_event=0`**（不是合成位）⇒ 它实际走的是
                            //   XTEST/焦点投递路径，**依赖 X 输入焦点**。所以补丁 F2（真的调
                            //   `XSetInputFocus`）是这条用例能稳定收到键的前提之一。
                            //
                            // 先注 `ctrl+a`：**补丁 F1 的牙齿** —— Win32 语义下 Ctrl+字母**不产
                            //   WM_CHAR**（它是"全选"命令）；旧实现无条件产字符 ⇒ 会多一条
                            //   WM_CHAR('a')，且真应用里 `Ctrl+A` 会变成"插入字符"而不是全选。
                            CmdResult ctrlKey = XTool.Key(hwndValue, "ctrl+a");
                            lock (injectorLog) injectorLog.Add("xdotool key --window ctrl+a → " + ctrlKey);
                            for (int i = 0; i < 60 && !Saw(WM_KEYDOWN, w => (long)w == 0x41); i++)
                                Thread.Sleep(50);
                            Thread.Sleep(200);   // 给"若旧实现产字符"留出派发窗口

                            CmdResult keyResult = XTool.Key(hwndValue, "a");
                            lock (injectorLog) injectorLog.Add("xdotool key --window a → " + keyResult);

                            // 鼠标：XTEST 真指针。先 --sync 移到窗口几何中心（绝对坐标），
                            // 再 click 1 —— 事件由 server 按"指针下的窗口"派发。
                            int cx = info.X + info.Width / 2;
                            int cy = info.Y + info.Height / 2;
                            CmdResult moveResult = XTool.MouseMove(cx, cy);
                            lock (injectorLog) injectorLog.Add($"xdotool mousemove --sync {cx},{cy} → {moveResult}");
                            CmdResult clickResult = XTool.Click(1);
                            lock (injectorLog) injectorLog.Add("xdotool click 1 → " + clickResult);
                        }
                        catch (Exception ex)
                        {
                            lock (injectorLog) injectorLog.Add("注入线程异常：" + ex);
                        }
                        finally
                        {
                            injectionDone.Set();
                        }
                    })
                    { IsBackground = true, Name = "m7b-injector" };
                    injector.Start();

                    // 200ms 后宣布"泵已经在跑了"——用一个真正的 DispatcherTimer，
                    // 它本身就是"WM_TIMER 被翻译并被派发"的证据。
                    var startGate = new DispatcherTimer(TimeSpan.FromMilliseconds(200),
                        DispatcherPriority.Normal, (s, e) =>
                        {
                            ((DispatcherTimer)s).Stop();
                            frameRunning.Set();
                        }, d);
                    startGate.Start();

                    // 100ms 轮询：键和鼠标都收到就收工
                    var checker = new DispatcherTimer(TimeSpan.FromMilliseconds(100),
                        DispatcherPriority.Normal, (s, e) =>
                        {
                            if (injectionDone.IsSet && Saw(WM_KEYDOWN) && Saw(WM_CHAR) && Saw(WM_LBUTTONDOWN))
                            {
                                ((DispatcherTimer)s).Stop();
                                frame.Continue = false;
                            }
                        }, d);
                    checker.Start();

                    // 10s 硬兜底：宁可断言失败，也不要挂住 dotnet test
                    var failsafe = new DispatcherTimer(TimeSpan.FromSeconds(10),
                        DispatcherPriority.Send, (s, e) =>
                        {
                            ((DispatcherTimer)s).Stop();
                            timedOut = true;
                            frame.Continue = false;
                        }, d);
                    failsafe.Start();

                    Dispatcher.PushFrame(frame);
                    frameMs = sw.ElapsedMilliseconds;

                    startGate.Stop(); checker.Stop(); failsafe.Stop();
                    injector.Join(5000);

                    // 收尾：Dispose 会走 DestroyWindow → WM_DESTROY/WM_NCDESTROY，
                    // 顺带验证 HwndWrapper 的销毁路径（在同一个线程上）。
                    if (wrapper is IDisposable disp) disp.Dispose();
                    d.InvokeShutdown();
                }
                catch (Exception ex)
                {
                    threadFailure = ex;
                }
                finally
                {
                    finished.Set();
                }
            })
            { IsBackground = true, Name = "m7b-ui" };

            uiThread.Start();
            bool done = finished.Wait(TimeSpan.FromSeconds(30));

            // 先把证据倒出来（即使随后断言失败，报告里也有东西可看）
            _out.WriteLine($"PushFrame 时长 = {frameMs} ms（timedOut={timedOut}）");
            lock (injectorLog)
                foreach (string line in injectorLog) _out.WriteLine("  " + line);
            _out.WriteLine($"HWND = 0x{hwndValue:x} ({hwndValue})类名 = {className}");
            _out.WriteLine("收到的消息序列：");
            foreach ((int m, IntPtr w, IntPtr l) in Snapshot())
                _out.WriteLine($"  msg=0x{m:x4} wParam=0x{(long)w:x} lParam=0x{(long)l:x}");

            Assert.True(done, "UI 线程没有在 30s 内结束 —— PushFrame 或建窗路径死等");
            if (threadFailure != null) throw threadFailure;

            Assert.False(timedOut, "10s 兜底被触发：注入的输入没有被托管侧收到");
            Assert.NotEqual(0UL, hwndValue);

            // ── 硬指标 4：事件流入 ─────────────────────────────────────────
            Assert.True(Saw(WM_KEYDOWN), $"没有收到 WM_KEYDOWN。消息：{Describe()}");
            Assert.True(Saw(WM_KEYDOWN, w => (long)w == 0x41),
                $"WM_KEYDOWN 的 wParam 不是 'A'(0x41)（xdotool key a 的 X11 keysym 'a' 应映射到 VK_A）。消息：{Describe()}");
            // 【为什么补这一条（2026-09-12，T3 的 textbox 现场：键没到 TextBox）】
            //   字符不是靠 WM_KEYDOWN 送的，而是靠 **WM_CHAR**（上游 `HwndKeyboardInputProvider`
            //   的 `case WindowMessage.WM_CHAR` → `ProcessTextInputAction`）。Windows 上它由
            //   `TranslateMessage` 产生；本 shim 是**在 X11 翻译层直接 push**
            //   （`win32_x11.c:435-439`，且 `TranslateMessage` 是空操作 `win32_msg.c:455-462`）。
            //   所以"键进了窗口"必须**分别**证明 KEYDOWN 与 CHAR 两条都到 —— 只证 KEYDOWN 不够。
            Assert.True(Saw(WM_CHAR), $"没有收到 WM_CHAR（本 shim 应在 KeyPress 时直接 push，见 win32_x11.c:435-439）。消息：{Describe()}");
            Assert.True(Saw(WM_CHAR, w => (long)w == 0x61),
                $"WM_CHAR 的 wParam 不是 'a'(0x61)（keysym 'a' 应原样作为字符）。消息：{Describe()}");
            // ── 补丁 F1 的牙齿：**Ctrl+A 不产 WM_CHAR** ────────────────────────────────
            //   本轮注入了 `ctrl+a` 与裸 `a` 各一次 ⇒ WM_CHAR 必须**恰好 1 条**（只有裸 a）。
            //   旧 shim（无条件把 keysym 当字符）会是 **2** 条 —— 用 `WPF_LINUX_WIN32_SHIM=<旧 so>`
            //   即可复现该红（旧件 sha16 4c023937421db45f）。
            int charCount = 0;
            foreach (var m in Snapshot()) if (m.Msg == WM_CHAR) charCount++;
            Assert.Equal(1, charCount);

            Assert.True(Saw(WM_LBUTTONDOWN), $"没有收到 WM_LBUTTONDOWN（xdotool click 1）。消息：{Describe()}");

            // 生命周期消息也要在（建窗/销窗路径真的走过）
            Assert.True(Saw(WM_PAINT), $"没有收到 WM_PAINT（Expose）。消息：{Describe()}");
            Assert.True(Saw(WM_DESTROY) && Saw(WM_NCDESTROY),
                $"Dispose 没有走完 WM_DESTROY/WM_NCDESTROY。消息：{Describe()}");

            // 注意：窗口此刻已经 Dispose 掉了，GetX11Window 会（正确地）返回 0。
            // 所以 HWND↔XID 的相等性必须在**建窗时**就记下来，不能在这里再查一次。
            Evidence("m7b-hwndwrapper-smoke.txt", BuildEvidence(
                title, hwndValue, x11Window, className, wndProcAfterCreate,
                frameMs, timedOut, injectorLog));
        }

        private string BuildEvidence(string title, ulong hwnd, ulong xidAtCreate, string className,
                                     nint wndProc, long frameMs, bool timedOut, List<string> injectorLog)
        {
            var sb = new System.Text.StringBuilder();
            sb.AppendLine("M7b · HwndWrapper 真实 X11 窗口烟测证据");
            sb.AppendLine("========================================");
            sb.AppendLine($"窗口标题      : {title}");
            sb.AppendLine($"HWND          : 0x{hwnd:x}  (十进制 {hwnd})");
            sb.AppendLine($"建窗时 HWND == WpfLinuxWin32_GetX11Window(HWND): " +
                          $"0x{xidAtCreate:x} vs 0x{hwnd:x} → {(xidAtCreate == hwnd ? "相等（HWND 就是 X11 XID）" : "不等")}");
            sb.AppendLine($"窗口类名      : {className}");
            sb.AppendLine($"GWL_WNDPROC   : 0x{(long)wndProc:x}");
            sb.AppendLine($"PushFrame 时长: {frameMs} ms（timedOut={timedOut}）");
            sb.AppendLine();
            sb.AppendLine("外部工具调用（由测试内的注入线程执行）：");
            foreach (string l in injectorLog) sb.AppendLine("  " + l);
            sb.AppendLine();
            sb.AppendLine("托管侧 hook 收到的消息序列：");
            foreach ((int m, IntPtr w, IntPtr l) in Snapshot())
                sb.AppendLine($"  msg=0x{m:x4} wParam=0x{(long)w:x} lParam=0x{(long)l:x}");
            return sb.ToString();
        }

        private string Describe()
        {
            var sb = new System.Text.StringBuilder();
            foreach ((int m, IntPtr w, IntPtr l) in Snapshot())
                sb.Append($"0x{m:x4}(w=0x{(long)w:x},l=0x{(long)l:x}) ");
            return sb.Length == 0 ? "(空)" : sb.ToString();
        }

        // ══════════════════════════════════════════════════════════════════
        //  HwndSource（PresentationCore 的公开入口）特征化
        // ══════════════════════════════════════════════════════════════════
        //  【这是一个"特征化测试"（characterization test），不是"必须成功"的测试】
        //    它把 HwndSource 在 Linux 上的**当前状态**钉死：
        //      · 能建出来 → 断言句柄是真的 X11 窗口（说明整条链通了）；
        //      · 建不出来 → 断言失败原因**恰好是已登记的那一条**，并落盘证据。
        //    之所以不写成"必须成功"：`HwndSource.Initialize` 无条件创建
        //    HwndMouseInputProvider/HwndKeyboardInputProvider → `InputManager.Current`
        //    → 硬 STA 检查（InputManager.cs:144），而 **Linux 上没有任何线程能报告 STA**。
        //    这条不在本里程碑的可写边界内（PresentationCore），所以只能登记 + 断言形状，
        //    不能靠"忽略异常"把门禁糊绿。修法与应用脚本见本文件末尾的说明。
        //    之所以不写成"永远通过"：分支必须由**异常的形状**决定 ——
        //    换成别的异常（比如又一次 NullReferenceException）会让用例失败，那才是真 bug。
        [X11Fact]
        [Trait("Category", "X11")]
        public void HwndSource_Characterization_OnLinux()
        {
            X11Guard.Require();

            string title = "WpfLinux-M7b-Src-" + Guid.NewGuid().ToString("N").Substring(0, 8);
            Exception captured = null;
            IntPtr handle = IntPtr.Zero;
            string phase = "构造";

            var finished = new ManualResetEventSlim(false);
            var uiThread = new Thread(() =>
            {
                try
                {
                    Dispatcher d = Dispatcher.CurrentDispatcher;
                    var p = new System.Windows.Interop.HwndSourceParameters(title)
                    {
                        Width = 200,
                        Height = 150,
                        PositionX = 200,
                        PositionY = 200,
                        WindowStyle = WS_VISIBLE | WS_OVERLAPPEDWINDOW,
                    };

                    using var src = new System.Windows.Interop.HwndSource(p);
                    handle = src.Handle;

                    phase = "xwininfo";
                    XTool.WindowInfo info = XTool.QueryWindow((ulong)handle.ToInt64());
                    _out.WriteLine("HwndSource 建窗成功：" + info);
                    Assert.Equal(200, info.Width);
                    Assert.Equal(150, info.Height);
                    Assert.Equal(title, info.Name);
                    Assert.True(info.IsViewable);

                    d.InvokeShutdown();
                }
                catch (Exception ex)
                {
                    captured = ex;
                }
                finally
                {
                    finished.Set();
                }
            })
            { IsBackground = true, Name = "m7b-hwndsource" };
            uiThread.Start();

            Assert.True(finished.Wait(TimeSpan.FromSeconds(30)),
                "HwndSource 用例没有在 30s 内结束（疑似死等）");

            if (captured == null)
            {
                _out.WriteLine($"HwndSource 可用，句柄 = 0x{handle.ToInt64():x}");
                Evidence("m7b-hwndsource.txt",
                    "HwndSource（PresentationCore 公开入口）在 Linux 上**构造成功**。\n" +
                    $"句柄 = 0x{handle.ToInt64():x}\n" +
                    "说明 M7b 的 Win32 shim 已足够支撑 HwndSource 的建窗路径；\n" +
                    "呈现路径（HwndTarget → DUCE → MIL）的接线属于 M7c。\n");
                return;
            }

            // 失败分支：必须是已登记的那几条之一，且原因可解释。
            _out.WriteLine($"HwndSource 在阶段「{phase}」失败：{captured.GetType().FullName}: {captured.Message}");

            var chain = new List<string>();
            for (Exception e = captured; e != null; e = e.InnerException)
            {
                chain.Add($"{e.GetType().Name}: {e.Message}");
                if (e.InnerException == null && e.StackTrace != null)
                    chain.Add("  最内层栈：\n    " +
                              string.Join("\n    ", e.StackTrace.Split('\n')));
            }
            _out.WriteLine("异常链：\n  " + string.Join("\n  ", chain));


            // ① 已修：注册表 NRE（补丁 G）。若又冒出 TypeInitializationException，
            //    说明还有别的加载期 Windows 依赖，必须人工看。
            Assert.False(captured is TypeInitializationException,
                "又出现了加载期类型初始化失败（补丁 G 之后不该再有）：" + captured);

            // ② 已登记且**不可在本里程碑修**的：STA 检查。
            //    断言"恰好是它"，而不是"任意异常都放过" —— 这样换成别的异常用例就会红。
            bool isStaRequirement =
                captured is InvalidOperationException &&
                captured.Message.Contains("STA", StringComparison.Ordinal);

            // ③ 其它可能出现的：原生面缺失（MIL/WIC，属 M7c）
            bool isNativeSurfaceGap =
                captured is DllNotFoundException ||
                captured is EntryPointNotFoundException ||
                captured is PlatformNotSupportedException ||
                captured is FileNotFoundException ||
                captured is System.ComponentModel.Win32Exception;

            Assert.True(isStaRequirement || isNativeSurfaceGap,
                $"HwndSource 失败原因不在已登记的清单里，需要人工看：{captured}\n" +
                "已登记：① STA 检查（InputManager.cs:144，Linux 上不可满足）；" +
                "② 原生面缺失（MIL/WIC）");

            if (isStaRequirement)
            {
                _out.WriteLine(
                    "已登记的拦路虎：PresentationCore InputManager.cs:144 的 STA 硬检查。" +
                    "修法与应用脚本见 src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py");
            }

            Evidence("m7b-hwndsource.txt",
                "HwndSource（PresentationCore 公开入口）在 Linux 上的**当前状态**：构造失败。\n" +
                $"阶段：{phase}\n" +
                "异常链：\n  " + string.Join("\n  ", chain) + "\n\n" +
                (isStaRequirement
                    ? "→ 已登记的拦路虎 ①：InputManager.cs:144 的硬 STA 检查。\n" +
                      "  Linux 上 Thread.GetApartmentState() 永远不是 STA（SetApartmentState 不被接受），\n" +
                      "  而 HwndSource.Initialize 无条件创建两个输入提供器 → InputManager.Current。\n" +
                      "  修法（1 行）：在 InputManager.cs:144 的 if 上加 `OperatingSystem.IsWindows() &&`。\n" +
                      "  一键应用：python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py\n" +
                      "  应用后本用例会自动走「构造成功」分支并断言真实 X11 窗口。\n"
                    : "→ 原生面缺失（MIL/WIC），属 M7c。\n"));
        }
    }
}

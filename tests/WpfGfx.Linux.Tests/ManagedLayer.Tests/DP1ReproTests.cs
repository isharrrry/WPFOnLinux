// WPF-on-Linux · **D-P1 最小复现**：输入路径下 `TextBox.Text` DP 是否陈旧
// ============================================================================
// 【为什么要有它（2026-09-13）】
//   `D-P1` 已收窄：**普通编辑路径复现不了**（`SelectAll(); SelectedText="A"` ⇒ `Text` 正常更新，
//   T3 的 `text-dp-min` 块），只在**输入链里那次 `SetCurrentDeferredValue` 写**上出现
//   （PF 探针：`SetCurrentDeferredValue(TextProperty, DeferredTextReference#…)` 调了 2 次，
//   而 38 次读**全部**返回旧串、`effectiveEntry.IsDeferredReference=False`）。
//   本用例把"键入"这一步搬进**测试装置**（无 X 注入、无 xdotool）：`HwndSource` + `TextBox`
//   → `Keyboard.Focus` → 直接 `PostMessage(WM_KEYDOWN/WM_CHAR/WM_KEYUP)` → 泵若干轮 → 读三个量。
//
// 【三值判定（写死，见 `DP1_输入路径_键入后TextDP是否陈旧`）】
//   (甲) `Text` 更新            ⇒ **连输入路径也复现不了** ⇒ `D-P1` 与 X/xdotool 注入时序相关（往下查注入）
//   (乙) `Text` 陈旧而**容器已变** ⇒ **最小 repro 成立**（这正是要抓的那一格）⇒ 本用例**红**
//   (丙) 装置跑不起来            ⇒ 本用例**红**，并在消息里写清"缺什么"（例如 HwndSource 建不出来）
//   (丁) 两者都没变              ⇒ **不是 `D-P1`**（输入根本没到达 TextBox）⇒ 另案，消息里区分开
//
// 【同时固化"staleness 闸门"教训（学 T1b 的 T0.7）】
//   本套件若加载 app-local 产物，必须先断言"**被测件 == 权威件**"，否则会"测旧件"却全绿
//   —— 本仓已经为此栽过两次（见 F2 报告附 D / msgflow 报告 V.2）。见 `闸门_win32shim被测件与权威件同sha`。
using System;
using System.Diagnostics;
using System.IO;
using System.Security.Cryptography;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Media;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Threading;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    public sealed class DP1ReproTests
    {
        private readonly ITestOutputHelper _out;
        public DP1ReproTests(ITestOutputHelper output) => _out = output;

        private const int WM_KEYDOWN = 0x0100;
        private const int WM_CHAR = 0x0102;
        private const int WM_KEYUP = 0x0101;
        private const int WS_VISIBLE = 0x10000000;
        private const int WS_OVERLAPPEDWINDOW = 0x00CF0000;
        private const string Seed = "seed-文本";

        [System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "PostMessageW",
            CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
        private static extern bool PostMessage(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam);

        /// <summary>
        /// ⚠️ **本测试程序集的 `user32.dll` 必须自己接解析器**（实测踩到，见报告 (丙)）：
        ///   `SetDllImportResolver` 是**按程序集**注册的，shim 只在它自己那几个程序集里注册过
        ///   ⇒ 测试程序集直接 `[DllImport("user32.dll")]` 会 `DllNotFoundException`（列出一串 `user32.dll.so`）。
        ///   这里把 `user32.dll` 指到与 `X11Guard` 同一搜索顺序找到的 `libwpfwin32.so`
        ///   （env `WPF_LINUX_WIN32_SHIM` → 程序集目录 → 仓库 `src/WpfGfx.Linux.Native/bin`）。
        /// </summary>
        static DP1ReproTests()
        {
            // ⚠️ 2026-09-15（`D-R2` 根的最后一环，主控定案）：这里**原先自己装一个解析器**，
            //   并把失败 `catch (Exception) { }` 静默吞掉。后果是它与 `X11Guard.Win32Shim`
            //   的**静态构造抢同一个槽位** —— `NativeLibrary.SetDllImportResolver` **对同一
            //   程序集只能调用一次**，谁先跑由 xUnit 的集合并行调度决定：
            //     · 本类先赢 ⇒ `Win32Shim..cctor` 抛 `InvalidOperationException:
            //       A resolver is already set for the assembly.` ⇒ 它是**静态构造** ⇒
            //       `Win32Shim` 整进程被毒化 ⇒ 用它的一批用例全灭（实测 30 条）、重则
            //       testhost 崩 ⇒ 表现为"**约一半概率的间歇红**"，与负载无关。
            //     · `Win32Shim` 先赢 ⇒ 本类的安装抛异常后被这里吞掉 ⇒ 全绿。
            //   **修法 = 每个程序集只留唯一安装点**：`X11Guard.Win32Shim` 的解析器**已经**
            //   映射 `user32.dll`（见其 `Mapped` 数组），本类只需**触发它**，不再自己安装。
            //   ⇒ 竞态消失；而"装置缺件"仍由 `Win32Shim` 的 `ShimLocator.Resolve()` 硬失败。
            _ = Win32Shim.LoadedPath;
        }

        private static string ShimPath()
        {
            string env = Environment.GetEnvironmentVariable("WPF_LINUX_WIN32_SHIM");
            if (!string.IsNullOrWhiteSpace(env)) return env;
            string beside = Path.Combine(AppContext.BaseDirectory, "libwpfwin32.so");
            if (File.Exists(beside)) return beside;
            return Path.Combine(FindRepoRoot(), "src", "WpfGfx.Linux.Native", "bin", "libwpfwin32.so");
        }

        private static string Sha16(string path)
        {
            using var fs = File.OpenRead(path);
            using var sha = SHA256.Create();
            return Convert.ToHexString(sha.ComputeHash(fs)).Substring(0, 16).ToLowerInvariant();
        }

        private static string FindRepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            for (int up = 0; up < 10 && dir != null; up++, dir = dir.Parent)
                if (File.Exists(Path.Combine(dir.FullName, "handoff.md"))) return dir.FullName;
            throw new InvalidOperationException("找不到仓库根（含 handoff.md）");
        }

        /// <summary>
        /// **staleness 闸门（不需要 X）**：本套件将要加载的 `libwpfwin32.so` 必须与权威件同 sha。
        /// 解析顺序与 `build/shims/Win32ShimResolver.cs` / `X11Guard.cs` 一致：
        ///   env `WPF_LINUX_WIN32_SHIM` → 程序集目录 → 仓库 `src/WpfGfx.Linux.Native/bin`。
        /// 若拿不到权威件 sha ⇒ 用例失败（**不静默跳过**）。
        /// </summary>
        /// <summary>`#40`：**自产件配置只许来自唯一声明**。
        /// 本闸门的扩展段原先写死 `bin/Debug` 当权威 ⇒ 切 Release 后"被测件（Release 副本）≠ 权威（Debug）"
        /// 必然红（`#40` 实测：`PF 被测 d160eaed… != 权威 e9ea2f57…`）。同一族问题在 T0.7 也出现过。</summary>
        private static string SelfBuiltConfig(string root)
        {
            string env = Environment.GetEnvironmentVariable("SELFBUILT_CONFIG");
            if (!string.IsNullOrEmpty(env)) return env;
            try
            {
                string decl = Path.Combine(root, "build", "SelfBuiltConfig.props");
                var m = System.Text.RegularExpressions.Regex.Match(
                    File.ReadAllText(decl), "<WpfLinuxSelfBuiltConfiguration[^>]*>([^<]*)<");
                if (m.Success)
                {
                    string v = m.Groups[1].Value.Trim();
                    if (v.Length > 0) return v;
                }
            }
            catch { }
            return "Debug";
        }

        [Fact]
        public void 闸门_win32shim被测件与权威件同sha()
        {
            string root = FindRepoRoot();
            string authority = Path.Combine(root, "src", "WpfGfx.Linux.Native", "bin", "libwpfwin32.so");
            Assert.True(File.Exists(authority), $"权威件不存在：{authority}");
            string authSha = Sha16(authority);

            string picked = ShimPath();     // 与 DllImport 解析器**同一口径**，避免"闸门看一件、加载另一件"
            Assert.True(File.Exists(picked), $"被测件不存在：{picked}");
            string pickedSha = Sha16(picked);
            _out.WriteLine($"权威件 {authSha}  {authority}");
            _out.WriteLine($"被测件 {pickedSha}  {picked}");
            Assert.True(pickedSha == authSha,
                $"**测的是旧件**：被测件 sha16={pickedSha} != 权威件 sha16={authSha}（{picked}）" +
                " —— 这正是本仓栽过两次的坑，先同步副本再跑本套件");

            // ── 闸门扩展（主控 2026-09-13 要求）：**桥 / PC / PF** 也要"被测件 == 权威件" ──
            //   为什么：测试装置加载的是 **app-local** 的 `wpfgfx_cor3.so` / `PresentationCore.dll` /
            //   `PresentationFramework.dll`；桥刚被重发过（T2b 的 Rendering 改动）⇒ 不比对就会"测旧件"。
            //   桥的"被测件" = `LD_LIBRARY_PATH` 里**第一个**含 `wpfgfx_cor3.so` 的目录（与加载器同口径），
            //   否则退回测试程序集目录；PC/PF 的"被测件" = 测试程序集目录里的 app-local 副本。
            // 桥：**枚举所有会/可能被加载的副本**，逐个与"权威发布件"比 sha。
            //   ⚠️ 第一版按 `LD_LIBRARY_PATH` 猜"被测件"是错的（实测：那时 `LD_LIBRARY_PATH` 里没有桥，
            //   装置照样跑起来了 ⇒ 桥是由 WpfGfx.Linux 自己的自定位逻辑加载的，猜不准）
            //   ⇒ 改成"把现有副本全比一遍"，找不到任何副本才报失败。
            CheckBridgeCopies(root);
            CheckArtifact("PC PresentationCore.dll",
                Path.Combine(AppContext.BaseDirectory, "PresentationCore.dll"),
                Path.Combine(root, "build", "PresentationCore.Linux", "bin", SelfBuiltConfig(root), "PresentationCore.dll"));
            CheckArtifact("PF PresentationFramework.dll",
                Path.Combine(AppContext.BaseDirectory, "PresentationFramework.dll"),
                Path.Combine(root, "build", "PresentationFramework.Linux", "bin", SelfBuiltConfig(root), "PresentationFramework.dll"));
        }

        /// <summary>
        /// 桥的 staleness 闸门：**枚举所有可能被加载的副本**，逐个与权威发布件（`.artifacts/publish/...`）比 sha。
        /// 权威件缺失 ⇒ 失败；**一个副本都找不到** ⇒ 失败；任何副本与权威不同 ⇒ 失败并点名那条路径。
        /// </summary>
        private void CheckBridgeCopies(string root)
        {
            const string so = "wpfgfx_cor3.so";
            string authority = Path.Combine(root, "build", "MilBridge", ".artifacts", "publish",
                                            "MilBridge.Linux", "release_linux-x64", so);
            if (!File.Exists(authority))
            {
                var alt = Directory.Exists(Path.Combine(root, "build", "MilBridge", ".artifacts"))
                    ? Directory.GetFiles(Path.Combine(root, "build", "MilBridge", ".artifacts"), so,
                                         SearchOption.AllDirectories)
                    : Array.Empty<string>();
                Assert.True(alt.Length > 0, $"**测不了**：找不到权威桥件（{authority}）");
                authority = alt[0];
            }
            string authSha = Sha16(authority);
            _out.WriteLine($"桥权威件 {authSha}  {authority}");

            var copies = new System.Collections.Generic.List<string>();
            string ld = Environment.GetEnvironmentVariable("LD_LIBRARY_PATH") ?? string.Empty;
            foreach (string d in ld.Split(':', StringSplitOptions.RemoveEmptyEntries))
            {
                string cand = Path.Combine(d, so);
                if (File.Exists(cand)) copies.Add(cand);
            }
            string beside = Path.Combine(AppContext.BaseDirectory, so);
            if (File.Exists(beside)) copies.Add(beside);
            foreach (string f in Directory.GetFiles(Path.Combine(root, "build", "MilBridge", ".artifacts"), so,
                                                    SearchOption.AllDirectories)) copies.Add(f);
            foreach (string f in Directory.GetFiles(Path.Combine(root, "samples"), so, SearchOption.AllDirectories))
                copies.Add(f);

            Assert.True(copies.Count > 0, "**测不了**：一个桥副本都没找到（装置却跑起来了 ⇒ 自定位逻辑与闸门口径不一致，请修正闸门）");
            var bad = new System.Collections.Generic.List<string>();
            foreach (string c in copies)
            {
                string cs = Sha16(c);
                _out.WriteLine($"桥副本   {cs}  {c}");
                if (cs != authSha) bad.Add($"{cs} {c}");
            }
            Assert.True(bad.Count == 0, "**测的是旧件**：以下桥副本与权威不同 sha ⇒ 先同步再跑本套件：\n  " + string.Join("\n  ", bad));
        }

        private void CheckArtifact(string what, string picked, string authority)
        {
            bool haveA = File.Exists(authority), haveP = File.Exists(picked);
            if (!haveP) { Assert.Fail($"**测不了**：{what} 的被测件不存在：{picked}"); }
            if (!haveA) { Assert.Fail($"**测不了**：{what} 的权威件不存在：{authority}"); }
            string ps = Sha16(picked), asha = Sha16(authority);
            _out.WriteLine($"{what}: 被测 {ps}  {picked}");
            _out.WriteLine($"{what}: 权威 {asha}  {authority}");
            Assert.True(ps == asha, $"**测的是旧件**：{what} 被测 sha16={ps} != 权威 sha16={asha}（{picked}）");
        }

        /// <summary>把 Dispatcher 泵指定毫秒（含 Background 优先级）。</summary>
        private static void Pump(Dispatcher d, int ms)
        {
            var frame = new DispatcherFrame();
            var stop = new DispatcherTimer(TimeSpan.FromMilliseconds(ms), DispatcherPriority.Background,
                (s, e) => { ((DispatcherTimer)s).Stop(); frame.Continue = false; }, d);
            var failsafe = new DispatcherTimer(TimeSpan.FromSeconds(20), DispatcherPriority.Send,
                (s, e) => { ((DispatcherTimer)s).Stop(); frame.Continue = false; }, d);
            stop.Start();
            failsafe.Start();
            Dispatcher.PushFrame(frame);
            stop.Stop();
            failsafe.Stop();
        }

        /// <summary>
        /// **独立于 `Text` DP 的"容器读数"**：`TextBox` 没有 `Document`/`ContentStart`（那是 RichTextBox/TextBlock 的 API）
        /// ⇒ 走 `SelectAll() + SelectedText`（它经 `TextRange` 读**容器**，与 DP 那条路不同）。
        /// 读完**恢复原选区**，避免本读数自己影响被测对象。
        /// </summary>
        private static string ContainerText(TextBox tb)
        {
            int ss = 0, sl = 0;
            try { ss = tb.SelectionStart; sl = tb.SelectionLength; } catch (Exception) { }
            try
            {
                tb.SelectAll();
                string text = tb.SelectedText ?? string.Empty;
                return text.TrimEnd('\r', '\n');
            }
            catch (Exception e) { return "(读容器抛 " + e.GetType().Name + ")"; }
            finally
            {
                try { tb.Select(Math.Min(ss, tb.Text.Length), Math.Min(sl, Math.Max(0, tb.Text.Length - ss))); }
                catch (Exception) { }
            }
        }

        // ==================================================================
        //  四档二分（主控 2026-09-13 批准）：找"哪一档会复现"
        // ==================================================================

        private sealed class Readings
        {
            public string Dp = "", Container = "", InjectionLog = "";
            public int Changed, ChangedBeforeRead, SelLenBefore, SelLenAfter;
            public long InjectAtMs, ReadAtMs;
            public bool KeyboardFocused, FocusCalled, DeviceOk = true, Repro, TypedReached;
            public string DeviceError = "";
        }

        /// <summary>
        /// 统一装置：建窗 → 放 TextBox → 泵 → 焦点 → **由 <paramref name="inject"/> 注入** → 泵 → 读三个量。
        /// `inject(src, tb, d)` 里做该档特有的注入；返回值写进 `InjectionLog`。
        /// 判据：容器变了而 `DP.Text` 没变 ⇒ **复现**。
        /// </summary>
        private void Variant(string name, Func<HwndSource, TextBox, Dispatcher, string> inject,
                             bool requireTypedReached = true, bool nestedRoot = false,
                             bool focusBeforePump = false)
        {
            Dispatcher d = Dispatcher.CurrentDispatcher;
            var sw = Stopwatch.StartNew();   // 口径：打印"注入时刻 / 读时刻" ⇒ "读在写后"可判
            var tb = new TextBox { Text = Seed, Width = 200, Height = 24 };
            var r = new Readings();
            tb.TextChanged += (_, __) => r.Changed++;

            HwndSource src = null;
            try
            {
                src = new HwndSource(new HwndSourceParameters("DP1-" + name)
                {
                    Width = 320, Height = 120, WindowStyle = WS_VISIBLE | WS_OVERLAPPEDWINDOW,
                });
                // 差异 (a)：**TextBox 不是根可视** —— 复刻应用里的嵌套（ScrollViewer→StackPanel→Border→TextBox）
                if (nestedRoot)
                {
                    var panel = new StackPanel();
                    var border = new Border { BorderThickness = new Thickness(1), Padding = new Thickness(2) };
                    border.Child = tb;
                    panel.Children.Add(border);
                    src.RootVisual = new ScrollViewer { Content = panel };
                }
                else
                {
                    src.RootVisual = tb;
                }
            }
            catch (Exception e)
            {
                r.DeviceOk = false;
                r.DeviceError = e.GetType().Name + ": " + e.Message;
            }

            if (!r.DeviceOk)
            {
                _out.WriteLine($"[{name}] 装置跑不起来：{r.DeviceError}");
                Assert.Fail($"[{name}] (丙) 装置跑不起来：{r.DeviceError} ｜ 缺什么：能建 HwndSource 的呈现目标（DUCE/MIL 桥 + X + libSkiaSharp）");
            }

            try
            {
                // 差异 (b)：**取焦点时机** —— 应用在首帧之前/之中就 `Focus()+SelectAll()`；
                //   默认档（false）是"首帧后 700ms 再取焦点"。
                if (focusBeforePump)
                {
                    r.FocusCalled = tb.Focus();
                    Keyboard.Focus(tb);
                    tb.SelectAll();
                }
                Pump(d, 700);
                if (!focusBeforePump)
                {
                    r.FocusCalled = tb.Focus();
                    Keyboard.Focus(tb);
                }
                Pump(d, 400);
                r.KeyboardFocused = tb.IsKeyboardFocused;
                r.SelLenBefore = tb.SelectionLength;

                r.InjectAtMs = sw.ElapsedMilliseconds;
                r.InjectionLog = inject(src, tb, d) ?? "";
                Pump(d, 1200);

                // 口径 · 可判：读之前先看"写发生了没有"（TextChanged>0 ⇒ 写已发生），
                //   再配合"读时刻 > 注入时刻" ⇒ 本装置的读是**写后读**。
                r.ChangedBeforeRead = r.Changed;
                r.ReadAtMs = sw.ElapsedMilliseconds;
                bool postWrite = r.ChangedBeforeRead > 0 && r.ReadAtMs > r.InjectAtMs;
                _out.WriteLine("[" + name + "] 时序：注入@" + r.InjectAtMs + "ms、读@" + r.ReadAtMs
                             + "ms；读前 TextChanged=" + r.ChangedBeforeRead + " ⇒ 写后读=" + (postWrite ? "是" : "否"));
                r.Dp = tb.Text;
                r.SelLenAfter = tb.SelectionLength;      // ⚠️ 必须在 ContainerText 之前（它会改选区）
                r.Container = ContainerText(tb);
                r.Repro = (r.Container != Seed) && (r.Dp == Seed);
                r.TypedReached = (r.Container != Seed) || (r.Dp != Seed);

                _out.WriteLine($"[{name}] 注入：{r.InjectionLog}");
                _out.WriteLine($"[{name}] IsKeyboardFocused={r.KeyboardFocused} selLenBefore={r.SelLenBefore} "
                             + $"selLenAfter={r.SelLenAfter} TextChanged={r.Changed}");
                _out.WriteLine($"[{name}] DP.Text=\"{r.Dp}\" 容器=\"{r.Container}\"");
                _out.WriteLine($"[{name}] 判定={(r.Repro ? "**复现**" : (r.TypedReached ? "不复现（DP 已更新）" : "不复现（输入没到达）"))}");

                if (r.Repro)
                {
                    Assert.Fail($"[{name}] (乙) **最小 repro 成立**：容器已变(\"{r.Container}\") 而 DP 陈旧(\"{r.Dp}\")，"
                        + $"TextChanged={r.Changed}；注入={r.InjectionLog}");
                }
                if (!r.TypedReached && requireTypedReached)
                {
                    Assert.Fail($"[{name}] (丁) 输入**没有到达** TextBox（DP 与容器都还是 \"{r.Dp}\"）"
                        + $"，IsKeyboardFocused={r.KeyboardFocused}；注入={r.InjectionLog}");
                }
            }
            finally
            {
                try { src?.Dispose(); } catch (Exception) { }
            }
        }

        /// <summary>(a) 裸 `WM_CHAR`（**不先** `WM_KEYDOWN`）⇒ 排除"KEYDOWN 的已处理语义影响后续字符"。</summary>
        [X11Fact]
        public void DP1_a_裸WM_CHAR()
            => Variant("a-裸WM_CHAR", (src, tb, d) =>
            {
                bool ch = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x41, (IntPtr)1);
                return $"PostMessage(WM_CHAR 'A')={ch}";
            });

        /// <summary>(b) 先 `SelectAll()`（现场 Verify() 的第一步）再 `WM_CHAR`。</summary>
        [X11Fact]
        public void DP1_b_先SelectAll再CHAR()
            => Variant("b-先SelectAll再CHAR", (src, tb, d) =>
            {
                tb.SelectAll();
                Pump(d, 150);
                bool ch = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x41, (IntPtr)1);
                return $"tb.SelectAll() (selLen={tb.SelectionLength}) → PostMessage(WM_CHAR 'A')={ch}";
            });

        /// <summary>(c) 连续两次键入（现场注入 `"AB"`；PF 探针看到 `SetCurrentDeferredValue` 调了**两次**）。</summary>
        [X11Fact]
        public void DP1_c_连续两次键入()
            => Variant("c-连续两次键入", (src, tb, d) =>
            {
                bool k1 = PostMessage(src.Handle, WM_KEYDOWN, (IntPtr)0x41, (IntPtr)1);
                bool c1 = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x41, (IntPtr)1);
                Pump(d, 120);
                bool k2 = PostMessage(src.Handle, WM_KEYDOWN, (IntPtr)0x42, (IntPtr)1);
                bool c2 = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x42, (IntPtr)1);
                bool u2 = PostMessage(src.Handle, WM_KEYUP, (IntPtr)0x42, (IntPtr)unchecked((nint)0x80000001L));
                return $"两轮：KEYDOWN'=A'{k1}/CHAR'A'={c1} → KEYDOWN'B'={k2}/CHAR'B'={c2}/KEYUP={u2}";
            });

        /// <summary>
        /// (d) **真注入**：对本装置自己的 hwnd 跑 `xdotool key --window <hwnd>`（与 T3 的 runner 同一手法）
        /// ⇒ 逐字复刻应用的注入方式（XSendEvent/XTEST + 成批到达），仍不需要应用槽。
        /// </summary>
        [X11Fact]
        public void DP1_d_xdotool真注入()
            => Variant("d-xdotool真注入", (src, tb, d) =>
            {
                ulong hwnd = (ulong)src.Handle.ToInt64();
                var keyA = XTool.Key(hwnd, "a");
                Pump(d, 250);
                var typeAB = XTool.Run("xdotool", "type", "--window", hwnd.ToString(), "AB");
                Pump(d, 250);
                return $"xdotool key --window 0x{hwnd:x} a → {keyA} ｜ xdotool type --window … AB → {typeAB}";
            });

        // ==================================================================
        //  §4.5 的"装置 vs 应用"四条结构性差异（主控 2026-09-13 批准）
        //  每条独立可跑：--filter ~DP1_e / ~DP1_f / ~DP1_g / ~DP1_h
        // ==================================================================

        /// <summary>(e) TextBox **不是根可视**：`ScrollViewer→StackPanel→Border→TextBox`（复刻应用嵌套）。</summary>
        [X11Fact]
        public void DP1_e_非根可视_嵌套ScrollViewer()
            => Variant("e-非根可视(嵌套)", (src, tb, d) =>
            {
                tb.SelectAll();
                Pump(d, 150);
                bool k = PostMessage(src.Handle, WM_KEYDOWN, (IntPtr)0x41, (IntPtr)1);
                bool c = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x41, (IntPtr)1);
                bool u = PostMessage(src.Handle, WM_KEYUP, (IntPtr)0x41, (IntPtr)unchecked((nint)0x80000001L));
                return $"嵌套根(ScrollViewer→StackPanel→Border→TextBox)；SelectAll→KEYDOWN={k}/CHAR={c}/KEYUP={u}";
            }, nestedRoot: true);

        /// <summary>(f) **取焦点时机**：首帧**之前/之中**就 `Focus()+SelectAll()`（应用 `Verify()` 的时机）。</summary>
        [X11Fact]
        public void DP1_f_首帧前取焦点()
            => Variant("f-首帧前取焦点", (src, tb, d) =>
            {
                bool k = PostMessage(src.Handle, WM_KEYDOWN, (IntPtr)0x41, (IntPtr)1);
                bool c = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x41, (IntPtr)1);
                return $"（焦点与 SelectAll 已在首帧前完成）KEYDOWN={k}/CHAR={c}";
            }, focusBeforePump: true);

        /// <summary>(g) **两次写的时间关系**：g1 同一帧内连发两条 CHAR；g2 跨多帧各一条。</summary>
        [X11Fact]
        public void DP1_g1_同帧连发两条CHAR()
            => Variant("g1-同帧连发", (src, tb, d) =>
            {
                tb.SelectAll();
                Pump(d, 150);
                bool a = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x41, (IntPtr)1);   // 不泵，紧接着第二条
                bool b = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x42, (IntPtr)1);
                return $"SelectAll→同帧连发 CHAR'A'={a} / CHAR'B'={b}（中间不泵）";
            });

        [X11Fact]
        public void DP1_g2_跨多帧各一条CHAR()
            => Variant("g2-跨多帧", (src, tb, d) =>
            {
                tb.SelectAll();
                Pump(d, 150);
                bool a = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x41, (IntPtr)1);
                Pump(d, 400);
                bool b = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x42, (IntPtr)1);
                Pump(d, 400);
                return $"SelectAll→CHAR'A'={a} →(泵 400ms)→ CHAR'B'={b} →(泵 400ms)";
            });

        // ==================================================================
        //  D-K1 的两条**能变红的牙**（修法前应当红；`GetKeyState` 修好后自动变绿）
        // ==================================================================

        /// <summary>
        /// (i2) **矛盾定位用例**：与 [i] 的注入**逐字相同**（`xdotool key --window <hwnd> ctrl+a` + `type AB`），
        /// 但**在两条命令之间泵**（`key` 命令返回后先泵 400ms，再 `type`）——即"到达即处理"的近似。
        /// 判据：若本档 `DP.Text=="AB"` 而 [i] 是 `"ABseed-文本"` ⇒ **差异是装置的注入批处理伪影**（不是 shim）；
        /// 若两档都是 `"AB"` ⇒ 环形表补丁已让批处理也正确；若两档都插字 ⇒ 才轮到"shim 仍不可见 Ctrl"。
        /// </summary>
        [X11Fact]
        public void DP1_i2_真ctrlA_分步泵()
            => Variant("i2-真ctrlA+分步泵", (src, tb, d) =>
            {
                ulong hwnd = (ulong)src.Handle.ToInt64();
                var ctrlA = XTool.Key(hwnd, "ctrl+a");
                Pump(d, 400);                       // ← 与 [i] 的唯一差别：这条命令之后**先泵再 type**
                int selAfterCtrlA = tb.SelectionLength;
                var typeAB = XTool.Run("xdotool", "type", "--window", hwnd.ToString(), "AB");
                Pump(d, 400);
                return $"xdotool key --window 0x{hwnd:x} ctrl+a → {ctrlA}（泵 400ms，selLen={selAfterCtrlA}）｜type AB → {typeAB}";
            });

        /// <summary>
        /// **牙 1**：`Ctrl+A` 必须**全选** ⇒ 随后 `type "AB"` 应当**替换**选区（`Text=="AB"`）。
        /// 修法前：`GetKeyState(VK_CONTROL)` 恒 0 ⇒ 命令不触发、`AB` 被**插入**成 `"ABseed-文本"` ⇒ 本用例**红**。
        /// </summary>
        [X11Fact]
        public void DP1_牙1_CtrlA全选()
        {
            Dispatcher d = Dispatcher.CurrentDispatcher;
            var tb = new TextBox { Text = Seed, Width = 200, Height = 24 };
            HwndSource src = null;
            Assert.True(TryOpen(d, out src, tb, "牙1-CtrlA"), "(丙) 装置跑不起来（见上一条用例的报错口径）");
            try
            {
                Pump(d, 700);
                tb.Focus(); Keyboard.Focus(tb);
                Pump(d, 400);
                ulong hwnd = (ulong)src.Handle.ToInt64();
                // 【装置口径修正（2026-09-14，主控指出的矛盾）】注入改为**按事件泵**：
                //   一条 `xdotool key ctrl+a` 会把 4 个 X 事件一次性投进队列，而本装置是单线程、只在注入后才泵
                //   ⇒ 4 个事件被**整批抽干** ⇒ 派发 'a' 时"实时表"已被 Ctrl↑ 清掉 ⇒ Ctrl 不可见（装置特有的伪影）。
                //   真应用有常驻泵、事件到达即处理 ⇒ 不会出现这种批。⇒ 这里改成一事件一泵，与真键盘/真应用同口径。
                //   **断言一字未改**（`selLen==Seed.Length` 与 `Text=="AB"`）。
                var kd = XTool.Run("xdotool", "keydown", "--window", hwnd.ToString(), "ctrl");
                Pump(d, 200);
                var ka = XTool.Run("xdotool", "key", "--window", hwnd.ToString(), "a");
                Pump(d, 200);
                var ku = XTool.Run("xdotool", "keyup", "--window", hwnd.ToString(), "ctrl");
                Pump(d, 200);
                int selAfterCtrlA = tb.SelectionLength;
                var typeAB = XTool.Run("xdotool", "type", "--window", hwnd.ToString(), "AB");
                Pump(d, 400);
                _out.WriteLine($"[牙1] keydown ctrl→{kd}｜key a→{ka}｜keyup ctrl→{ku}（每步之间泵 200ms）；之后 selLen={selAfterCtrlA}（期望 7）");
                _out.WriteLine($"[牙1] xdotool type --window … AB → {typeAB}；DP.Text=\"{tb.Text}\"（期望 \"AB\"）");
                Assert.True(selAfterCtrlA == Seed.Length,
                    $"[牙1 红] `Ctrl+A` **没有全选**：selLen={selAfterCtrlA}（期望 {Seed.Length}）" +
                    " ⇒ `GetKeyState(VK_CONTROL)` 仍恒 0（D-K1 未修）");
                Assert.True(tb.Text == "AB",
                    $"[牙1 红] 键入没有替换选区：DP.Text=\"{tb.Text}\"（期望 \"AB\"）⇒ D-K1 未修");
            }
            finally { try { src?.Dispose(); } catch (Exception) { } }
        }

        /// <summary>
        /// **牙 2**：`Shift+Left` 必须**扩选一格**（`selLen==1`）。
        /// 修法前：修饰键位为 0 ⇒ WPF 不认 `Shift` ⇒ 只会移动 caret（`selLen==0`）⇒ 本用例**红**。
        /// </summary>
        [X11Fact]
        public void DP1_牙2_ShiftLeft扩选()
        {
            Dispatcher d = Dispatcher.CurrentDispatcher;
            var tb = new TextBox { Text = Seed, Width = 200, Height = 24 };
            HwndSource src = null;
            Assert.True(TryOpen(d, out src, tb, "牙2-ShiftLeft"), "(丙) 装置跑不起来");
            try
            {
                Pump(d, 700);
                tb.Focus(); Keyboard.Focus(tb);
                tb.Select(3, 0);                    // caret=3、无选区
                Pump(d, 200);
                ulong hwnd = (ulong)src.Handle.ToInt64();
                // 同 [牙1] 的装置口径修正：`shift+Left` 一条命令 = 整批 ⇒ 改成按键事件分步注入。
                var sd = XTool.Run("xdotool", "keydown", "--window", hwnd.ToString(), "shift");
                Pump(d, 200);
                var kl = XTool.Run("xdotool", "key", "--window", hwnd.ToString(), "Left");
                Pump(d, 200);
                var su = XTool.Run("xdotool", "keyup", "--window", hwnd.ToString(), "shift");
                Pump(d, 200);
                _out.WriteLine($"[牙2] caret=3/无选区 → keydown shift→{sd}｜key Left→{kl}｜keyup shift→{su}（各步泵 200ms）");
                _out.WriteLine($"[牙2] 之后 selLen={tb.SelectionLength}（期望 1）selStart={tb.SelectionStart} caret={tb.CaretIndex}");
                Assert.True(tb.SelectionLength == 1,
                    $"[牙2 红] `Shift+Left` **没有扩选**：selLen={tb.SelectionLength}（期望 1）、"
                    + $"selStart={tb.SelectionStart}、caret={tb.CaretIndex} ⇒ 修饰键位仍为 0（D-K1 未修）");
            }
            finally { try { src?.Dispose(); } catch (Exception) { } }
        }

        [System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "GetKeyboardState")]
        private static extern bool GetKeyboardState(byte[] state);

        [System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "GetKeyState")]
        private static extern short GetKeyState(int vk);

        /// <summary>
        /// **D-K1 修法的 API 级读数（第 5 项）**：真注入 `keydown ctrl` / `keyup ctrl`，读两处 ——
        /// `GetKeyState(VK_CONTROL=0x11)` 的高位、`GetKeyboardState()[0x11]` 的 bit7。
        /// 修前：`GetKeyState` 是 `return 0` 的桩、`GetKeyboardState` **导出不存在** ⇒ 本用例红。
        /// </summary>
        [X11Fact]
        public void DP1_API_GetKeyboardState可用()
        {
            Dispatcher d = Dispatcher.CurrentDispatcher;
            var tb = new TextBox { Text = Seed, Width = 200, Height = 24 };
            HwndSource src = null;
            Assert.True(TryOpen(d, out src, tb, "API-GetKeyboardState"), "(丙) 装置跑不起来");
            try
            {
                Pump(d, 500);
                ulong hwnd = (ulong)src.Handle.ToInt64();
                var down = XTool.Run("xdotool", "keydown", "--window", hwnd.ToString(), "ctrl");
                Pump(d, 300);
                short ksDown = GetKeyState(0x11);
                var bufDown = new byte[256];
                bool okDown = GetKeyboardState(bufDown);
                var up = XTool.Run("xdotool", "keyup", "--window", hwnd.ToString(), "ctrl");
                Pump(d, 300);
                short ksUp = GetKeyState(0x11);
                var bufUp = new byte[256];
                bool okUp = GetKeyboardState(bufUp);
                _out.WriteLine($"[API] keydown ctrl → {down}");
                _out.WriteLine($"[API] 按住中：GetKeyState(0x11)=0x{(ushort)ksDown:x4}；GetKeyboardState ok={okDown} [0x11]=0x{bufDown[0x11]:x2}");
                _out.WriteLine($"[API] keyup   ctrl → {up}");
                _out.WriteLine($"[API] 松开后：GetKeyState(0x11)=0x{(ushort)ksUp:x4}；GetKeyboardState ok={okUp} [0x11]=0x{bufUp[0x11]:x2}");
                Assert.True(okDown && okUp, "GetKeyboardState 导出不可用（返回 false）");
                Assert.True((ksDown & 0x8000) != 0, $"GetKeyState(VK_CONTROL) 按住时高位未置：0x{(ushort)ksDown:x4}");
                Assert.True((bufDown[0x11] & 0x80) != 0, $"GetKeyboardState()[0x11] 按住时 bit7 未置：0x{bufDown[0x11]:x2}");
                Assert.True((ksUp & 0x8000) == 0 && (bufUp[0x11] & 0x80) == 0, "松开 Ctrl 后状态未清");
            }
            finally { try { src?.Dispose(); } catch (Exception) { } }
        }

        /// <summary>给两条牙共用的建窗助手（失败时把原因写进输出，供 (丙) 判定）。</summary>
        private bool TryOpen(Dispatcher d, out HwndSource src, TextBox tb, string name)
        {
            src = null;
            try
            {
                src = new HwndSource(new HwndSourceParameters("DP1-" + name)
                {
                    Width = 320, Height = 120, WindowStyle = WS_VISIBLE | WS_OVERLAPPEDWINDOW,
                });
                src.RootVisual = tb;
                return true;
            }
            catch (Exception e)
            {
                _out.WriteLine($"[{name}] (丙) 装置跑不起来：{e.GetType().Name}: {e.Message}");
                return false;
            }
        }

        /// <summary>
        /// (i) **最接近应用的复刻**：嵌套根（含别的块的结构）+ **真 `ctrl+a`**（走命令路径）+ 真 `type "AB"`。
        /// 与 T3 的 runner 注入序列**逐字一致**：`xdotool key --window <hwnd> ctrl+a` → `xdotool type --window <hwnd> AB`。
        /// 用途：若应用侧原生读数显示"`pop 0x0102` 有、而文本仍不变"，本档就是装置侧的对照物。
        /// </summary>
        [X11Fact]
        public void DP1_i_嵌套根_真ctrlA_再typeAB()
            => Variant("i-嵌套根+真ctrlA+type", (src, tb, d) =>
            {
                ulong hwnd = (ulong)src.Handle.ToInt64();
                var ctrlA = XTool.Key(hwnd, "ctrl+a");
                Pump(d, 300);
                var typeAB = XTool.Run("xdotool", "type", "--window", hwnd.ToString(), "AB");
                Pump(d, 300);
                return $"嵌套根；xdotool key --window 0x{hwnd:x} ctrl+a → {ctrlA} ｜ type --window AB → {typeAB}";
            }, nestedRoot: true);

        /// <summary>(h) **同窗口另有鼠标输入提供者**：真指针点击窗口中心后再注入字符。</summary>
        [X11Fact]
        public void DP1_h_先鼠标点击再键入()
            => Variant("h-先点击再键入", (src, tb, d) =>
            {
                ulong hwnd = (ulong)src.Handle.ToInt64();
                XTool.WindowInfo info = XTool.QueryWindow(hwnd);
                int cx = info.X + info.Width / 2, cy = info.Y + info.Height / 2;
                var mv = XTool.MouseMove(cx, cy);
                Pump(d, 200);
                var clk = XTool.Click(1);
                Pump(d, 250);
                var key = XTool.Key(hwnd, "a");
                Pump(d, 250);
                return $"xwininfo=({info.X},{info.Y},{info.Width}x{info.Height}) mousemove({cx},{cy})→{mv} click1→{clk} "
                     + $"xdotool key --window a→{key}";
            });

        /// <summary>
        /// **最小复现主体**：`HwndSource` + `TextBox` → 焦点 → 直接 Post `WM_KEYDOWN/WM_CHAR/WM_KEYUP`
        /// → 泵若干轮 → 读 `Text` / `TextChanged` / 容器。三值判定见文件头。
        /// </summary>
        [X11Fact]
        public void DP1_输入路径_键入后TextDP是否陈旧()
        {
            Dispatcher d = Dispatcher.CurrentDispatcher;
            var tb = new TextBox { Text = Seed, Width = 200, Height = 24 };
            int changed = 0;
            tb.TextChanged += (_, __) => changed++;

            HwndSource src = null;
            try
            {
                var p = new HwndSourceParameters("DP1Repro")
                {
                    Width = 320,
                    Height = 120,
                    WindowStyle = WS_VISIBLE | WS_OVERLAPPEDWINDOW,
                };
                src = new HwndSource(p);
                src.RootVisual = tb;
            }
            catch (Exception e)
            {
                Assert.Fail("(丙) 装置跑不起来：" + e.GetType().Name + ": " + e.Message
                    + " ｜ 缺什么：能建 HwndSource 的呈现目标（DUCE/MIL 桥 + X + libSkiaSharp）。"
                    + " 原始栈见下：\n" + e);
            }

            try
            {
                Pump(d, 700);                       // 布局/首帧
                bool wpfFocus = tb.Focus();
                Keyboard.Focus(tb);
                Pump(d, 400);
                _out.WriteLine($"焦点：tb.Focus()={wpfFocus} IsKeyboardFocused={tb.IsKeyboardFocused} "
                             + $"IsFocused={tb.IsFocused} hwnd=0x{src.Handle.ToInt64():x}");

                // 注入：与输入链顺序一致（KEYDOWN → CHAR → KEYUP）；lParam 用最小合法值
                bool kd = PostMessage(src.Handle, WM_KEYDOWN, (IntPtr)0x41, (IntPtr)1);
                bool ch = PostMessage(src.Handle, WM_CHAR, (IntPtr)0x41, (IntPtr)1);
                bool ku = PostMessage(src.Handle, WM_KEYUP, (IntPtr)0x41, (IntPtr)unchecked((nint)0x80000001L));
                _out.WriteLine($"PostMessage: KEYDOWN={kd} CHAR={ch} KEYUP={ku}");
                Pump(d, 1200);                      // 让输入链走完（含 Background 优先级）

                string dpText = tb.Text;
                string container = ContainerText(tb);
                _out.WriteLine($"读数：DP.Text=\"{dpText}\" 容器=\"{container}\" TextChanged={changed}");

                if (dpText != Seed)
                {
                    _out.WriteLine("(甲) **复现不了**：输入路径下 DP 已更新 ⇒ D-P1 与 X/xdotool 注入时序相关（往下查注入环节）");
                    return;                          // 用例绿：说明这条路径本身没病
                }
                if (container != Seed)
                {
                    Assert.Fail($"(乙) **最小 repro 成立**：容器已变(\"{container}\") 而 DP 仍旧(\"{dpText}\")，"
                        + $"TextChanged={changed} ⇒ 缺陷就在'输入链这一次写'上，可在此装置里快速迭代");
                }
                Assert.Fail($"(丁) **不是 D-P1**：DP 与容器都还是 \"{dpText}\" ⇒ 输入的键**没有到达 TextBox**"
                    + $"（IsKeyboardFocused={tb.IsKeyboardFocused}、PostMessage 三条都成功={kd}/{ch}/{ku}）"
                    + " ⇒ 先查焦点/输入链，不要按 DP 陈旧来修");
            }
            finally
            {
                try { src?.Dispose(); } catch (Exception) { }
            }
        }
    }
}

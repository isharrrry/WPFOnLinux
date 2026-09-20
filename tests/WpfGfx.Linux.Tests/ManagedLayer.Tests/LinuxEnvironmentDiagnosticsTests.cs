// M7b · Linux 上「托管层加载期 Windows 依赖」的登记与断言
//
// 【为什么单独一个文件】
//   M7b 的验收路径（Dispatcher + HwndWrapper + 输入事件）已经全绿，但把
//   `HwndSource`（PresentationCore 的公开入口）拉起来时又撞到**同一类**问题：
//   Windows 注册表 / ETW 这类"加载期就会碰"的 Windows 专有设施。
//   这类 bug 的特征是**编译期完全无感、一碰类型就炸**，而且症状往往是
//   TypeInitializationException 套 NullReferenceException，光看类型名归不了因。
//   所以这里把"根因"写成**可证伪的断言**（注册表在 Linux 上不可用），
//   而不是写一句注释。哪天 .NET 或者 M7c 把它修好了，这个用例会红 —— 那正是
//   提醒"文档该更新了"的机制。
//
// 【本条与 EventTrace 的关系】
//   同源不同点，两条都是 WindowsBase 的"诊断/追踪"基础设施：
//     · `MS.Utility.EventTrace` 静态构造 → `Microsoft.Win32.Registry.GetValue`
//       → **已修**（build/shims/WindowsBase.EventTrace.Shim.cs + 补丁 F），
//         不修的话 HwndWrapper 终结器会让**进程崩溃**；
//     · `MS.Internal.AvTrace.IsWpfTracingEnabledInRegistry()`（AvTrace.cs:213）
//       → `SecurityHelper.ReadRegistryValue(Registry.CurrentUser, …)` →
//         **仍未修**（需要动 Shared/MS/Internal/SecurityHelper.cs 或 AvTrace.cs，
//         属于 M7c 的范围，见 docs/U2-M7b-report.md 的"未做"清单）。

using System;
using System.IO;
using System.Threading;
using System.Windows.Threading;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    public sealed class LinuxEnvironmentDiagnosticsTests
    {
        private readonly ITestOutputHelper _out;

        public LinuxEnvironmentDiagnosticsTests(ITestOutputHelper output) => _out = output;

        /// <summary>
        /// `Environment.OSVersion` 在 Unix 上返回的是**内核版本**。
        /// 这正是上游 `EventTrace` 静态构造里
        /// <c>if (Environment.OSVersion.Version.Major &lt; 6 || …)</c>
        /// 那个短路在 Linux 上失效的原因（本机内核 6.x ⇒ Major &gt;= 6 ⇒
        /// 短不掉，于是必然去读注册表）。把这条环境事实钉住：
        /// 如果哪天换成 5.x 内核，EventTrace 的原始代码反而"碰巧能用"，
        /// 那种"靠内核版本侥幸通过"是最危险的假绿。
        /// </summary>
        [Fact]
        public void OsVersion_OnLinux_ReportsKernelVersion_NotWindows()
        {
            Version v = Environment.OSVersion.Version;
            _out.WriteLine($"Environment.OSVersion = {Environment.OSVersion}");
            _out.WriteLine($"Version = {v}  (Major={v.Major}, Minor={v.Minor})");
            _out.WriteLine($"RuntimeInformation.OSDescription = " +
                           System.Runtime.InteropServices.RuntimeInformation.OSDescription);

            // 关键断言：版本号不是 Windows 的 6.1/10.0 语义，而是内核号，
            // 且高到足以让上游的 `Major < 6` 短路失效。
            Assert.True(v.Major >= 6,
                $"内核主版本 {v.Major} < 6 —— 上游 EventTrace 的 `Major < 6` 短路会生效，" +
                "本工程对它的处置（补丁 F）需要重新评估");
        }

        /// <summary>
        /// `Microsoft.Win32.Registry` 在 Linux 上不可用 —— 这是 AvTrace → NRE 的根因。
        /// 两种表现都算命中（取决于 .NET 对 Unix 的实现）：
        ///   · `Registry.CurrentUser` 返回 null → 调用方 `baseRegistryKey.OpenSubKey(...)` 抛 NRE
        ///     （这正是实测观察到的形态）；
        ///   · 或者直接抛 PlatformNotSupportedException。
        /// 无论哪种，"从这里读注册表"这件事在 Linux 上都不成立。
        /// </summary>
        [Fact]
        public void Registry_IsUnusable_OnLinux()
        {
            bool isNull = false;
            Exception threw = null;
            try
            {
                isNull = Microsoft.Win32.Registry.CurrentUser == null;
            }
            catch (Exception ex)
            {
                threw = ex;
            }

            string outcome = isNull
                ? "Registry.CurrentUser == null（⇒ 调用方 OpenSubKey 抛 NullReferenceException）"
                : $"Registry.CurrentUser 抛 {threw?.GetType().Name}: {threw?.Message}";
            _out.WriteLine(outcome);

            Assert.True(isNull || threw is PlatformNotSupportedException,
                $"Registry.CurrentUser 在 Linux 上的行为既不是 null 也不是 PlatformNotSupportedException，" +
                $"而是：{(threw == null ? "非 null 的可用对象" : threw.GetType().FullName)} —— " +
                "AvTrace 那条 NRE 的归因需要重查");

            // 顺带把「WindowsBase 的诊断基础设施在 Linux 上是否还能用」记进证据文件
            string dir = Path.Combine(AppContext.BaseDirectory, "artifacts");
            Directory.CreateDirectory(dir);
            File.WriteAllText(Path.Combine(dir, "m7b-linux-diagnostics.txt"),
                "M7b · Linux 托管层加载期诊断\n" +
                "============================\n" +
                $"Environment.OSVersion            : {Environment.OSVersion}\n" +
                $"RuntimeInformation.OSDescription : " +
                $"{System.Runtime.InteropServices.RuntimeInformation.OSDescription}\n" +
                $"Registry.CurrentUser             : {(isNull ? "null" : threw?.GetType().Name)}\n" +
                "\n已修（补丁 F / build/shims/WindowsBase.EventTrace.Shim.cs）：\n" +
                "  MS.Utility.EventTrace 静态构造读 HKEY_CURRENT_USER\\Software\\Microsoft\\" +
                "Avalon.Graphics\\ClassicETW\n" +
                "  → Linux 上必然 TypeInitializationException（HwndWrapper 终结器会把进程带崩）\n" +
                "  → 换成 NullTraceProvider（Linux 无 ETW，语义等价于\"无订阅者\"）\n" +
                "\n未修（M7c）：\n" +
                "  MS.Internal.AvTrace.IsWpfTracingEnabledInRegistry → " +
                "SecurityHelper.ReadRegistryValue(Registry.CurrentUser, …)\n" +
                "  → Registry.CurrentUser 在 Linux 上为 null → NullReferenceException\n" +
                "  → 连带 System.Windows.PresentationSource 的静态构造失败 → HwndSource 不可用\n");
        }

        /// <summary>
        /// ★ 第 4 个拦路虎的**根因**：Linux 上没有任何线程能报告 STA。
        ///
        /// `MS.Internal` 之外的 `System.Windows.Input.InputManager` 私有构造函数
        /// （PresentationCore/System/Windows/Input/InputManager.cs:144）是硬检查：
        ///     if (Thread.CurrentThread.GetApartmentState() != ApartmentState.STA)
        ///         throw new InvalidOperationException(SR.RequiresSTA);
        /// 而 `HwndSource.Initialize` **无条件**创建 `HwndMouseInputProvider` +
        /// `HwndKeyboardInputProvider`（HwndSource.cs:212/213），两者的构造函数第一句都是
        /// `InputManager.Current` ⇒ 这个检查在 Linux 上**恒真** ⇒ `HwndSource` 永远构造不出来。
        ///
        /// 这条用例断言的是**根因本身**（"本进程里没有任何线程报告 STA"），
        /// 而不是"某段代码抛了异常"：如果哪天运行时让 Unix 支持了 STA
        /// （或者有人用别的方式绕过了），这条会红 —— 那正是提醒"该换修法了"。
        /// </summary>
        [Fact]
        public void ApartmentState_NeverReportsSTA_OnLinux()
        {
            ApartmentState mainState = Thread.CurrentThread.GetApartmentState();

            ApartmentState newThreadState = ApartmentState.Unknown;
            Exception setException = null;
            bool setAccepted = false;

            var t = new Thread(() => { newThreadState = Thread.CurrentThread.GetApartmentState(); })
            { IsBackground = true, Name = "m7b-apartment-probe" };
            try
            {
                t.SetApartmentState(ApartmentState.STA);
                setAccepted = true;
            }
            catch (Exception ex)
            {
                setException = ex;
            }
            t.Start();
            t.Join(5000);

            _out.WriteLine($"主线程 GetApartmentState()          = {mainState}");
            _out.WriteLine($"SetApartmentState(STA) 是否被接受    = {setAccepted}" +
                           (setException == null ? "" : $"（抛 {setException.GetType().Name}）"));
            _out.WriteLine($"新建线程 GetApartmentState()        = {newThreadState}");
            _out.WriteLine($"OS: {System.Runtime.InteropServices.RuntimeInformation.OSDescription}");

            // ★ 根因断言：没有任何线程报告 STA，且**设置也不被接受**
            Assert.NotEqual(ApartmentState.STA, mainState);
            Assert.NotEqual(ApartmentState.STA, newThreadState);
            Assert.True(setException != null || !setAccepted || newThreadState != ApartmentState.STA,
                "SetApartmentState(STA) 居然生效了 —— InputManager 的 STA 检查在 Linux 上" +
                "可能是可满足的，那条拦路虎的归因需要重查");

            var artifacts = Path.Combine(AppContext.BaseDirectory, "artifacts");
            Directory.CreateDirectory(artifacts);
            File.WriteAllText(Path.Combine(artifacts, "m7b-apartment-state.txt"),
                "M7b/T3 · Linux 线程单元状态探针\n" +
                "================================\n" +
                $"主线程 GetApartmentState()       : {mainState}\n" +
                $"SetApartmentState(STA) 被接受     : {setAccepted}" +
                (setException == null ? "" : $"（{setException.GetType().Name}: {setException.Message}）") + "\n" +
                $"新建线程 GetApartmentState()     : {newThreadState}\n\n" +
                "后果：PresentationCore InputManager.cs:144 的\n" +
                "  if (Thread.CurrentThread.GetApartmentState() != ApartmentState.STA) throw ...\n" +
                "在 Linux 上恒真；而 HwndSource.Initialize（HwndSource.cs:212/213）无条件创建\n" +
                "HwndMouseInputProvider / HwndKeyboardInputProvider —— 两者的构造函数第一句都是\n" +
                "InputManager.Current ⇒ **HwndSource 在 Linux 上永远构造不出来**。\n\n" +
                "修法（1 行，在 PresentationCore/System/Windows/Input/InputManager.cs:144）：\n" +
                "  if (OperatingSystem.IsWindows() &&\n" +
                "      Thread.CurrentThread.GetApartmentState() != ApartmentState.STA)\n" +
                "      throw new InvalidOperationException(SR.RequiresSTA);\n" +
                "一键应用（幂等、可回滚）：\n" +
                "  python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-apartment.py\n");
        }

        /// <summary>
        /// 在**多条不同的线程**上各建一个 Dispatcher 并关掉。
        /// 这条钉住的是两件容易被忽略的事：
        ///   1. shim 的窗口表/类表在销毁后没有残留（DestroyWindow + UnregisterClass
        ///      真的清干净了），否则第二次建窗就会撞 atom/类名；
        ///   2. message-only 窗口的销毁走了 WM_DESTROY/WM_NCDESTROY —— 见
        ///      win32_core.c 里那段"必须给 message-only 窗口发消息"的说明：
        ///      不发 WM_NCCREATE 会让 HwndSubclass 永不挂载 → 调用 GC 掉的委托 →
        ///      **进程 fail-fast**（本轮实测踩过，且只在第二次建 Dispatcher 时暴露）。
        /// （`Dispatcher.CurrentDispatcher` 是只读属性，所以"重建"只能换线程做。）
        /// ⚠️ 需要 X：`Dispatcher` 的构造函数无条件建 message-only 窗口
        /// （实测见 DispatcherPumpTests.cs 顶部的说明）。
        /// </summary>
        [X11Fact]
        [Trait("Category", "X11")]
        public void Dispatcher_CanBeCreatedAndShutdown_OnManyThreads()
        {
            const int rounds = 5;
            for (int i = 0; i < rounds; i++)
            {
                Exception failure = null;
                var done = new System.Threading.ManualResetEventSlim(false);
                int round = i;
                var thread = new System.Threading.Thread(() =>
                {
                    try
                    {
                        Dispatcher d = Dispatcher.CurrentDispatcher;
                        Assert.NotNull(d);
                        d.Invoke(() => { });
                        Assert.True(System.Runtime.InteropServices.Marshal
                            .GetLastPInvokeError() >= 0);   // 顺手确认 P/Invoke 面没崩
                        d.InvokeShutdown();
                        Assert.True(d.HasShutdownFinished, $"第 {round} 轮没有关干净");
                    }
                    catch (Exception ex) { failure = ex; }
                    finally { done.Set(); }
                })
                { IsBackground = true, Name = $"m7b-dispatcher-round{round}" };
                thread.Start();

                Assert.True(done.Wait(TimeSpan.FromSeconds(20)),
                    $"第 {round} 轮：建/关 Dispatcher 死等");
                if (failure != null)
                    throw new Xunit.Sdk.XunitException($"第 {round} 轮失败：{failure}");
            }
        }
    }
}

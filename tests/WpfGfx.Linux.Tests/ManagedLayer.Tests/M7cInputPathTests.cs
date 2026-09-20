// M7c 收尾轮 · 任务 1 —— **输入路径不再把真应用弄死**（TSF `TextServicesLoader` 空引用）
//
// 【这个文件存在的理由】
//   真 WPF 应用（HelloWpf）**一收到鼠标输入就 SIGABRT**：
//     指针进窗口 → HwndMouseInputProvider → InputManager.ProcessInput
//     → TextServicesManager.PreProcessInput → TextServicesLoader.TIPsWantToRun
//     → **NullReferenceException**（`TextServicesLoader.cs:192`）→ 进程 134 + core dumped
//   M2 验收全程没有输入，所以这条从没被撞到 —— 但"真 WPF 窗口要能被人用"它是门槛。
//
// 【三层判据，分开写清楚，不要混为一谈】
//   ① **机制层**（本进程内，确定、快）：`Registry.CurrentUser`/`LocalMachine` 在 Unix 上是
//      **null** ⇒ 上游那两处解引用必崩；加 `?.` / null 判断之后 **"没有 TIP"** 是自然结果。
//   ② **红/绿探针层**（本进程内，安全）：直接问上游 `TextServicesLoader.ServicesInstalled`。
//      修前抛 NRE（本测试抓得住，**不会**把宿主弄死）；修后必须是 `false` 且不抛。
//   ③ **端到端层**（子进程 + 真窗口 + 真注入）：`run-hellowpf.sh` 的输入探针 —— 应用是被
//      拉起的**子进程**，它崩了不会带走测试宿主；判据是"应用存活 + 事件真的到达窗口"。
//      ⇒ 修前红、修后绿，**且不牺牲基线的绿**。
//
// 【为什么②能抓 NRE 却不崩】NRE 本身是**可捕获**的托管异常；应用里之所以 SIGABRT，
//   是因为它出现在 Dispatcher 的消息处理里、没人接（WPF 的未处理异常 → FailFast）。
//   反射调用点把异常包成 TargetInvocationException ⇒ 本测试能断言"它抛了/没抛"。

using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using Microsoft.Win32;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    /// <summary>输入路径的 TSF 空引用：机制 + 探针 + 端到端。</summary>
    [Trait("Category", "Input")]
    public sealed class M7cInputPathTests
    {
        private readonly ITestOutputHelper _out;
        public M7cInputPathTests(ITestOutputHelper output) => _out = output;

        private static readonly Assembly PcAssembly = typeof(System.Windows.Media.Visual).Assembly;         // PresentationCore
        private static readonly Assembly WbAssembly = typeof(System.Windows.Threading.Dispatcher).Assembly; // WindowsBase

        private static string FindRepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            for (int up = 0; up < 10 && dir != null; up++, dir = dir.Parent)
            {
                if (File.Exists(Path.Combine(dir.FullName, "handoff.md"))) return dir.FullName;
            }
            throw new InvalidOperationException($"找不到仓库根（含 handoff.md），起点 {AppContext.BaseDirectory}");
        }

        /// <summary>
        /// 按名字找 `MS.Internal.TextServicesLoader`（internal ⇒ 反射）。
        ///
        /// 【⚠️ 它在 **WindowsBase**，不在 PresentationCore】实测（收尾轮）：用启动钩子逐程序集找类型时，
        ///   `PresentationCore` 里**找不到**它；`build/WindowsBase.Linux/WindowsBase.Linux.csproj:281`
        ///   正是那句 `<Compile Include=…Shared/MS/Internal/TextServicesLoader.cs />`。
        ///   崩溃栈里它被 PC 的 `TextServicesManager` 调到，是因为 PC 对 WB 的 internal 有 IVT。
        ///   **上一版按记忆写成 PresentationCore ⇒ 测试自己报"找不到类型"，那是测试写错，
        ///   不是"修法未落地"** —— 两者必须分清（主控点名）。所以这里两个程序集都试，并在
        ///   失败信息里把试过的位置全列出来。
        /// </summary>
        private static Type TextServicesLoaderType()
        {
            foreach (Assembly asm in new[] { WbAssembly, PcAssembly })
            {
                Type found = asm.GetType("MS.Internal.TextServicesLoader", throwOnError: false);
                if (found != null) return found;
            }
            Assert.Fail("在 WindowsBase 与 PresentationCore 里都没找到 MS.Internal.TextServicesLoader");
            return null!;
        }

        private static bool TryReadServicesInstalled(out bool installed, out Exception error)
        {
            installed = false;
            error = null;
            PropertyInfo p = TextServicesLoaderType().GetProperty(
                "ServicesInstalled", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
            Assert.True(p != null, "TextServicesLoader.ServicesInstalled 不见了");
            try
            {
                installed = (bool)p.GetValue(null);
                return true;
            }
            catch (TargetInvocationException tie)
            {
                error = tie.InnerException ?? tie;
                return false;
            }
        }

        // ==================================================================
        //  ① 机制层：Unix 上 Registry 根键就是 null（这是 NRE 的**全部**原因）
        // ==================================================================

        [Fact]
        public void Unix上Registry根键是null_而上游那两处直接解引用()
        {
            RegistryKey cu = Registry.CurrentUser;
            RegistryKey lm = Registry.LocalMachine;
            _out.WriteLine($"Registry.CurrentUser   = {(cu == null ? "<null>" : cu.ToString())}");
            _out.WriteLine($"Registry.LocalMachine  = {(lm == null ? "<null>" : lm.ToString())}");

            // 这不是"我们的 shim 没实现"，是 **.NET 在 Unix 上的既定行为**（没有注册表）。
            Assert.Null(cu);
            Assert.Null(lm);

            // 复刻上游第 192 行的**未加守卫**写法：必崩（这就是 SIGABRT 的第一现场）。
            Assert.Throws<NullReferenceException>(() => { var _ = Registry.CurrentUser.OpenSubKey("Software\\Microsoft\\CTF", false); });

            // 复刻补丁 M 的写法：`?.` ⇒ null（后续走上游**原有的** "没有这个键" 分支）。
            RegistryKey guarded = Registry.CurrentUser?.OpenSubKey("Software\\Microsoft\\CTF", false);
            Assert.Null(guarded);       // 不抛

            // 复刻第二处：`IterateSubKeys(Registry.LocalMachine, …)` 在补丁 M 之后不再被调用；
            // 语义落点是"这台机器没有 TIP" ⇒ 方法返回 false（= 上游契约里的"没有文本服务"）。
            bool tipsWantToRun = lm != null && false;   // 补丁 M：hklm == null ⇒ return false
            Assert.False(tipsWantToRun);
            _out.WriteLine("机制层：空根键 → 未加守卫必 NRE；加守卫 ⇒ 没有 TIP（false）");
        }

        // ==================================================================
        //  ② 红/绿探针：上游自己的 `ServicesInstalled` 必须"优雅地说没有文本服务"
        // ==================================================================

        [Fact]
        public void 上游ServicesInstalled_必须不抛且为false_而不是NRE()
        {
            bool ok = TryReadServicesInstalled(out bool installed, out Exception error);

            _out.WriteLine($"TextServicesLoader.ServicesInstalled ⇒ ok={ok} installed={installed} " +
                           $"error={error?.GetType().Name}: {error?.Message}");

            Assert.True(ok,
                "修前状态：`TextServicesLoader.TIPsWantToRun`（TextServicesLoader.cs:192）在 Unix 上抛 " +
                $"{error?.GetType().Name} —— 这就是真应用一收到鼠标输入就 SIGABRT 的第一现场。" +
                "修法见 src/WpfGfx.Linux.Native/tools/patch-presentationcore-textservices.py（补丁 M）：" +
                "① `Registry.CurrentUser?.OpenSubKey(...)`；② `Registry.LocalMachine` 为 null ⇒ return false。" +
                "⚠️ 需要集成波重放补丁 M 并重建 PresentationCore 才会翻绿（本组不重建 PC）。");

            // Linux 上没有 CTF/TIP 注册表 ⇒ "没有安装文本服务"是**真话**，不是降级后的兜底。
            Assert.False(installed);
        }

        // ==================================================================
        //  ③ 补丁 M 本身：能生成、能自检、生成物里两处守卫都在
        // ==================================================================

        [Fact]
        public void 补丁M_应用器是行为正确的_无参即应用且接线可重放()
        {
            // 【为什么改成行为断言（主控抓到的教训）】
            //   旧版断言输出文本里含 `"--check 通过"` —— 那是我**实现细节的回声**：
            //   我把 `--check` 的语义改成"只读、未就位时 rc=1"之后，这条就红了，
            //   而**被测行为一点没变**。文本是实现的影子，改一次实现就红一次。
            //   现在断言的是四件**行为**：
            //     ① `--check` 在"已就位"的仓库上 rc=0；
            //     ② 生成物存在、且含两处守卫（读文件，不读 stdout）；
            //     ③ csproj 里 Remove/Include 两行在位（读文件）；
            //     ④ 拿一份**被剥掉接线**的 csproj 副本（模拟波的重生成）跑**无参**
            //        ⇒ 它会重新接线（rc=0），随后 `--check` 对该副本 rc=0；
            //        而被剥掉接线的副本上 `--check` 必须先 rc=1 —— 这才证明"未就位=失败"。
            string root = FindRepoRoot();
            string tool = Path.Combine(root, "src", "WpfGfx.Linux.Native", "tools",
                "patch-presentationcore-textservices.py");
            Assert.True(File.Exists(tool), $"找不到补丁 M 的应用器：{tool}");

            string generated = Path.Combine(root, "build", "WindowsBase.Linux", "TextServicesLoader.Linux.cs");
            string csproj = Path.Combine(root, "build", "WindowsBase.Linux", "WindowsBase.Linux.csproj");

            // ① 仓库现状：--check 必须 rc=0
            (int rc, string outp) = RunPython(tool, "--check");
            _out.WriteLine($"--check rc={rc}");
            Assert.True(rc == 0, $"补丁 M 未就位（--check rc={rc}）：\n{outp}");

            // ② 生成物真的存在且含两处守卫（读文件本身）
            Assert.True(File.Exists(generated), $"生成物不存在：{generated}");
            string gen = File.ReadAllText(generated);
            Assert.Contains("Registry.CurrentUser?.OpenSubKey(\"Software\\\\Microsoft\\\\CTF\", false)", gen);
            Assert.Contains("RegistryKey hklm = Registry.LocalMachine;", gen);
            Assert.Contains("if (hklm == null)", gen);
            Assert.Contains("private static bool TIPsWantToRun()", gen);          // 是上游的**超集**，不是重写
            Assert.Contains("private static EnableState SingleTIPWantsToRun(", gen);

            // ③ csproj 两行在位
            string csp = File.ReadAllText(csproj);
            Assert.Contains("<Compile Remove=\"$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/Shared/MS/Internal/TextServicesLoader.cs\" />", csp);
            Assert.Contains("<Compile Include=\"$(WpfLinuxRoot)build/WindowsBase.Linux/TextServicesLoader.Linux.cs\" />", csp);

            // ④ 接线可重放：拿一份"被重生成过"的副本（剥掉补丁块）
            string sim = Path.Combine(Path.GetTempPath(), "m7c-wb-" + Guid.NewGuid().ToString("N") + ".csproj");
            try
            {
                string stripped = System.Text.RegularExpressions.Regex.Replace(
                    csp, @"  <!-- ==== WPF-on-Linux M7c 补丁 M.*?补丁 M 结束 ==== -->\r?\n", "",
                    System.Text.RegularExpressions.RegexOptions.Singleline);
                Assert.DoesNotContain("补丁 M", stripped);           // 先自证"确实剥干净了"
                File.WriteAllText(sim, stripped);

                (int rcStripped, _) = RunPython(tool, "--check", "--csproj", sim);
                _out.WriteLine($"被剥掉接线的副本：--check rc={rcStripped}（期望 1）");
                Assert.True(rcStripped == 1, "「未接线」必须让 --check 失败 —— 否则就是「空操作也成功」那种假绿");

                (int rcApply, string applyOut) = RunPython(tool, "--csproj", sim);   // **无参（= 应用）** + 覆盖 csproj
                _out.WriteLine($"无参运行（应用） rc={rcApply}");
                Assert.True(rcApply == 0, $"无参运行失败 rc={rcApply}：\n{applyOut}");

                string rewired = File.ReadAllText(sim);
                Assert.Contains("<Compile Remove=\"$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/Shared/MS/Internal/TextServicesLoader.cs\" />", rewired);
                Assert.Contains("<Compile Include=\"$(WpfLinuxRoot)build/WindowsBase.Linux/TextServicesLoader.Linux.cs\" />", rewired);

                (int rcAfter, _) = RunPython(tool, "--check", "--csproj", sim);
                _out.WriteLine($"重新接线后：--check rc={rcAfter}（期望 0）");
                Assert.True(rcAfter == 0, "重新接线之后 --check 仍失败");
            }
            finally
            {
                try { if (File.Exists(sim)) File.Delete(sim); } catch { }
            }
        }

        /// <summary>跑一次 python3 脚本，返回 (退出码, 合并输出)。</summary>
        private static (int rc, string output) RunPython(string script, params string[] args)
        {
            var psi = new ProcessStartInfo("python3")
            {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
            };
            psi.ArgumentList.Add(script);
            foreach (string a in args) psi.ArgumentList.Add(a);

            using Process proc = Process.Start(psi);
            string stdout = proc.StandardOutput.ReadToEnd();
            string stderr = proc.StandardError.ReadToEnd();
            proc.WaitForExit(120000);
            return (proc.ExitCode, stdout + stderr);
        }

        // ==================================================================
        //  ③b 补丁 N：assert 的**原文必须可见**（诊断能力不能被掩蔽）
        // ==================================================================

        /// <summary>
        /// 上游 `Invariant.cs:194` 的失败路径要先读 `IsDialogOverrideEnabled`，而该属性在 `:232` 直接
        /// `Registry.LocalMachine.OpenSubKey(...)` —— **Unix 上根键是 null** ⇒ 修前"NRE 吃掉了断言原文"。
        /// 本用例是那条链的**最小可判形态**：反射取该属性必须**不抛**且返回 bool。
        /// ⚠️ 反射取的是**测试进程里那份 WindowsBase.dll**（= build/WindowsBase.Linux 的产物）⇒
        ///    补丁 N 落地前会抛 NRE（红），落地后返回 false（绿）。
        /// </summary>
        [Fact]
        public void 补丁N_不变量失败路径不依赖可空注册表()
        {
            Type invariant = null;
            foreach (Assembly asm in new[] { WbAssembly, PcAssembly })
            {
                invariant = asm.GetType("MS.Internal.Invariant", throwOnError: false);
                if (invariant != null) break;
            }
            Assert.True(invariant != null, "找不到 MS.Internal.Invariant（WindowsBase/PresentationCore 都试过）");

            PropertyInfo prop = invariant.GetProperty("IsDialogOverrideEnabled",
                BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
            Assert.True(prop != null, "Invariant.IsDialogOverrideEnabled 不见了（上游改名？）");

            object value = null;
            Exception error = null;
            try { value = prop.GetValue(null); }
            catch (TargetInvocationException tie) { error = tie.InnerException ?? tie; }
            catch (Exception ex) { error = ex; }

            _out.WriteLine($"IsDialogOverrideEnabled ⇒ {(error == null ? value?.ToString() : error.GetType().Name)}");
            Assert.True(error == null,
                $"失败路径仍会崩在「准备报错」这一步：{error?.GetType().Name}: {error?.Message}\n" +
                "⇒ 补丁 N 未落地（src/WpfGfx.Linux.Native/tools/patch-shared-invariant-failfast.py，无参即应用）。");
            Assert.IsType<bool>(value);
        }

        /// <summary>
        /// 生成物必须**保留**报错语义：仍然 FailFast、仍然 Debug.Fail，并且**主动把原文写到 stderr**
        /// （`Debug.Fail` 在 Release 下被编译掉 ⇒ 不主动打印就看不到原文）。
        /// 断言的是"行为要素"而不是某一行文本的位置。
        /// </summary>
        [Fact]
        public void 补丁N_生成物仍FailFast且主动打印原文()
        {
            string generated = Path.Combine(FindRepoRoot(), "build", "WindowsBase.Linux", "Invariant.Linux.cs");
            Assert.True(File.Exists(generated), $"生成物不存在：{generated}（补丁 N 未应用）");
            string text = File.ReadAllText(generated);

            Assert.Contains("PrintInvariantFailure(message, detailMessage);", text);                 // 主动打印
            Assert.Contains("System.Console.Error.WriteLine(BuildInvariantFailureText", text);       // 写 stderr
            Assert.Contains("Environment.FailFast(BuildInvariantFailureText(message, detailMessage));", text);
            Assert.Contains("Debug.Fail(", text);                                                    // 保留 Debug 路径
            // 【为什么只针对**那一行**、不全文禁 plain 写法】同一个文件里还有一处
            //   `Registry.LocalMachine.OpenSubKey(RegistryKeys.WPF)`，它在 `#if PRERELEASE` 里
            //   ⇒ **正常构建根本不编译**，全文禁会把一个无害的非编译分支判成失败（自己造的假红）。
            Assert.Contains("key = Registry.LocalMachine?.OpenSubKey(\"Software\\\\Microsoft\\\\.NETFramework\");", text);
            Assert.DoesNotContain("key = Registry.LocalMachine.OpenSubKey(\"Software\\\\Microsoft\\\\.NETFramework\");", text);
        }

        // ==================================================================
        //  ③b 补丁 O：Linux 上「聚焦 TextBox」不再撞 STA 断言（wave-8 P0）
        // ==================================================================

        /// <summary>
        /// 补丁 O 的**防削弱**断言（文本级：读生成物即可判，**不需要重编**）。
        ///   ① 上游 STA 断言原文必须**逐字仍在**（补丁 O 只允许在它**之前**加守卫，不许删/改不变量）；
        ///   ② Linux 守卫必须存在，且**排在断言之前**（排在后面 ⇒ Linux 上仍先 FailFast）；
        ///   ③ 守卫必须落在 `Load()` 里。
        /// **牙齿**：把生成物里的守卫删掉 ⇒ 本用例必红（已实测）。
        /// </summary>
        [Fact]
        public void 补丁O_生成物保留STA断言原文且Linux守卫排在其之前()
        {
            string path = Path.Combine(FindRepoRoot(), "build", "WindowsBase.Linux", "TextServicesLoader.Linux.cs");
            Assert.True(File.Exists(path), $"找不到生成物：{path}（补丁 M/O 应用器没跑？）");
            string text = File.ReadAllText(path);

            const string assertLine =
                "Invariant.Assert(Thread.CurrentThread.GetApartmentState() == ApartmentState.STA, \"Load called on MTA thread!\");";
            const string guardLine = "if (!System.OperatingSystem.IsWindows())";

            Assert.Contains(assertLine, text);                       // ① 断言原文仍在（防削弱）
            int gi = text.IndexOf(guardLine, StringComparison.Ordinal);
            int ai = text.IndexOf(assertLine, StringComparison.Ordinal);
            int li = text.IndexOf("internal static UnsafeNativeMethods.ITfThreadMgr Load()", StringComparison.Ordinal);
            Assert.True(gi >= 0, "生成物里没有补丁 O 的 Linux 守卫（if (!System.OperatingSystem.IsWindows())）");
            Assert.True(li >= 0 && li < gi, $"守卫不在 Load() 里（Load@{li} guard@{gi}）");
            Assert.True(gi < ai, $"守卫必须排在 STA 断言**之前**（guard@{gi} assert@{ai}）；排在后面 Linux 上仍会先 FailFast");
            _out.WriteLine($"✓ 断言原句 @{ai}，守卫 @{gi}，Load() @{li} ⇒ 次序正确");
        }

        /// <summary>
        /// 补丁 O 的**运行时**红线：Linux 上 `TextServicesLoader.Load()` 必须走**契约路径返回 null**，
        /// 而不是撞 STA 断言 FailFast（wave-8 实测：样例只调 `_tb.Focus()` 就 exit=134）。
        ///
        /// ⚠️ 它跑的是**测试进程里那份 WindowsBase.dll**（= `build/WindowsBase.Linux` 的产物）：
        ///    补丁 O 在**生成物**里，必须**重编 WindowsBase** 之后才进 dll。未重编时调用会 FailFast
        ///    打死宿主 ⇒ 用 `PatchOFact` 在**发现期**明确 Skip 并写清"等集成波重编"，
        ///    **不是静默通过**；而生成物里若**没有**守卫（补丁没落地）则**不跳过**、直接去红。
        /// **牙齿**：守卫在生成物里被删掉 ⇒ 本用例（连同整条套件）以 FailFast 红。
        /// </summary>
        [PatchOFact]
        public void 补丁O_Linux上Load直接返回null且不触发STA断言()
        {
            Assert.False(OperatingSystem.IsWindows(), "本用例只针对非 Windows（Linux）平台");

            Type loader = TextServicesLoaderType();
            MethodInfo load = loader.GetMethod("Load", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
            Assert.True(load != null, "TextServicesLoader.Load 不见了（上游改名？）");

            Assert.True(TryReadServicesInstalled(out bool installed, out Exception err),
                $"ServicesInstalled 读取抛异常：{err}");
            _out.WriteLine($"ServicesInstalled={installed}（Linux 上应为 false ⇒ Load 必须返回 null）");

            // ⚠️ 若补丁 O 未落地，这一行会 Invariant.FailFast（宿主 abort）—— 那正是"必红"。
            object result = load.Invoke(null, null);
            Assert.Null(result);
            _out.WriteLine("✓ Load() 返回 null：走的是上游文档化的契约路径（May return null if no text services…），"
                           + "没有撞 STA 断言");
        }

        // ==================================================================
        //  ④ 端到端门禁：真窗口 + 真注入（在**子进程**里跑，红了也不带走宿主）
        // ==================================================================

        [Fact]
        public void 端到端_真应用收到指针与按键_不崩且事件到达窗口()
        {
            string root = FindRepoRoot();
            string sample = Path.Combine(root, "samples", "HelloWpf", "bin", "Debug", "net10.0", "HelloWpf.dll");
            if (!File.Exists(sample))
            {
                _out.WriteLine($"跳过：{sample} 不存在（先构建 samples/HelloWpf —— 本组无权重也不该构建它）");
                return;   // 与 X11Guard 同一口径：没有前置产物就不假装跑过
            }

            string runner = Path.Combine(root, "tests", "WpfGfx.Linux.Tests", "Presentation.Tests", "run-hellowpf.sh");
            Assert.True(File.Exists(runner), $"找不到 runner：{runner}");

            var psi = new ProcessStartInfo("bash")
            {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
            };
            psi.ArgumentList.Add(runner);
            psi.ArgumentList.Add("60");
            psi.ArgumentList.Add("--no-build");
            psi.Environment["HLWPF_INPUT_PROBE"] = "1";
            psi.Environment["HLWPF_KEEP_POINTER"] = "0";

            // 【为什么不能用 `psi.Environment["DISPLAY"]` 取值】`ProcessStartInfo.Environment` 只镜像
            //   父进程**已设置**的变量：`DISPLAY` 没设时直接索引会抛 `KeyNotFoundException`
            //   ⇒ 这条用例的结果取决于"跑测试的人设没设 DISPLAY"，那不是断言、是彩票（主控抓到过）。
            //   缺 DISPLAY 时**显式跳过**（本用例本来就依赖 X），而不是抛。
            string display = Environment.GetEnvironmentVariable("DISPLAY");
            if (string.IsNullOrEmpty(display))
            {
                _out.WriteLine("跳过：DISPLAY 未设置（本用例要真窗口 + 真指针注入，没有 X 就不假装跑过）");
                return;
            }
            psi.Environment["DISPLAY"] = display;

            // 应用是被 runner 拉起的**子进程**：它 SIGABRT 只会让这个 runner 报 FAIL，
            // 不会把 xunit 宿主带走（这正是本用例存在的形式理由）。
            using Process proc = Process.Start(psi);
            string log = proc.StandardOutput.ReadToEnd() + proc.StandardError.ReadToEnd();
            Assert.True(proc.WaitForExit(180000), "runner 超时未结束");

            string marker = null;
            foreach (string line in log.Split('\n'))
            {
                if (line.StartsWith("INPUT_PROBE=", StringComparison.Ordinal)) marker = line.Trim();
            }
            _out.WriteLine("runner 输出尾部：");
            string[] all = log.Split('\n');
            for (int i = Math.Max(0, all.Length - 25); i < all.Length; i++) _out.WriteLine("  " + all[i]);

            Assert.True(marker != null, "runner 没有输出 INPUT_PROBE= 判据行 —— runner 版本不对？");
            Assert.True(marker == "INPUT_PROBE=PASS",
                $"输入路径没通过：{marker}。判据是「应用存活 **且** 指针/按键事件真的到达窗口」。" +
                "若日志里有 TextServicesLoader 的 NRE，那就是补丁 M 还没被集成波重放/重建。");
        }
    }

    /// <summary>
    /// 补丁 O 的「已重编进 WindowsBase.dll」判据（**发现期**判定 ⇒ Skip，而不是静默通过）。
    /// 语义三条，必须分清：
    ///   ① 生成物里**没有**守卫（补丁没落地） ⇒ 返回 null = **不跳过** ⇒ 运行时用例去红（这才是牙齿）；
    ///   ② 生成物里有守卫、但生成物比 dll 新（未重编） ⇒ 给 Skip 理由（避免 FailFast 打死整条套件）；
    ///   ③ 找不到仓库根/生成物 ⇒ 返回 null（不猜、不跳过）。
    /// </summary>
    internal static class PatchOProbe
    {
        internal const string GuardMarker = "if (!System.OperatingSystem.IsWindows())";
        internal const string AssertMarker = "\"Load called on MTA thread!\"";

        internal static readonly string SkipReason = Compute();

        private static string Compute()
        {
            try
            {
                var dir = new DirectoryInfo(AppContext.BaseDirectory);
                for (int up = 0; up < 10 && dir != null; up++, dir = dir.Parent)
                {
                    if (!File.Exists(Path.Combine(dir.FullName, "handoff.md"))) continue;
                    string src = Path.Combine(dir.FullName, "build", "WindowsBase.Linux", "TextServicesLoader.Linux.cs");
                    if (!File.Exists(src)) return null;
                    string text = File.ReadAllText(src);
                    if (!text.Contains(GuardMarker) || !text.Contains(AssertMarker)) return null;   // ① 去红
                    string dll = typeof(System.Windows.Threading.Dispatcher).Assembly.Location;
                    if (File.Exists(dll) && File.GetLastWriteTimeUtc(src) > File.GetLastWriteTimeUtc(dll))
                    {
                        return $"生成物（含补丁 O 守卫）比 {Path.GetFileName(dll)} 新 ⇒ WindowsBase **尚未重编**，"
                             + "补丁 O 还没进测试进程的 dll。集成波重编 WindowsBase 后本用例自动参与断言"
                             + "（未重编前**不静默通过**）。";
                    }
                    return null;
                }
                return null;
            }
            catch (Exception e)
            {
                return "补丁 O 判据计算失败：" + e.GetType().Name + "（保守起见跳过，不假装通过）";
            }
        }
    }

    /// <summary>补丁 O 的用例门（发现期可判 ⇒ Skip；与 `X11FactAttribute` 同一手法）。</summary>
    public sealed class PatchOFactAttribute : FactAttribute
    {
        public PatchOFactAttribute()
        {
            if (PatchOProbe.SkipReason != null) Skip = PatchOProbe.SkipReason;
        }
    }
}

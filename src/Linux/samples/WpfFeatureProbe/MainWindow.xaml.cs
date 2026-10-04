using System;
using System.Collections.Generic;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;

namespace WpfFeatureProbe
{
    /// <summary>
    /// 功能广度样例的宿主窗口。
    ///
    /// 【设计要点（都是为了"块级可判"）】
    ///   1. 每块**独立构造 + 独立 try/catch** ⇒ 一块抛异常不会带走整个应用（否则台账只出一半，
    ///      无法区分"这块坏了"与"全崩了"）；
    ///   2. 每块**自报一行** `[feat] &lt;名称&gt; OK|FAIL|INCONCLUSIVE &lt;证据&gt;`；
    ///   3. 支持 `--only=a,b`（**崩溃分诊**用）：若某块是**原生级崩溃**（try/catch 抓不到），
    ///      runner 用 `--only=<块名>` 逐个复跑，即可把"崩在谁身上"钉出来；
    ///   4. 支持 `--late-ms=N`（默认 6000）：动画/输入/虚拟化这类需要时间的块在 N 毫秒后
    ///      再自报一次（`LateVerify`），给 runner 留出注入输入与滚动的时间窗；
    ///   5. 右列是**台账的屏上副本** ⇒ 读图即可核对，不必只信日志。
    /// </summary>
    public partial class MainWindow : Window
    {
        private readonly List<ProbeBlock> _blocks = new List<ProbeBlock>();
        private readonly Dictionary<string, string> _verdicts = new Dictionary<string, string>();

        public MainWindow()
        {
            InitializeComponent();

            // 台账 → 屏上副本（supdated 每行都会同步；读图即可核对）
            Ledger.Sink = (n, v) => { _verdicts[n] = v; };

            string[] argv = Environment.GetCommandLineArgs();
            string only = ArgValue(argv, "--only=");
            int lateMs = 6000;
            if (int.TryParse(ArgValue(argv, "--late-ms="), out var lm) && lm > 0) lateMs = lm;

            var all = new List<ProbeBlock>
            {
                new PopupBlock(),        // ① 独立窗口路径（最可能撞缺口）
                new AnimationBlock(),    // ② MilCmd*Animate 一族
                new OpacityMaskBlock(),  // ③ PushOpacityMask
                new EffectBlock(),       // ④ Effect（Blur 未验证）
                new ControlsBlock(),     // ⑤ TabControl/TreeView/DataGrid
                new TextBoxBlock(),      // ⑥ 编辑态 + 输入路径
                new VirtualizeBlock(),   // ⑦ 虚拟化
                new TransformBlock(),    // ⑧ 变换 / 裁剪 / 缓存
                new TextFeaturesBlock(), // ⑨ RTL / 折行 / 省略号
                new PureRtlBlock(),     // ⑩ **纯 RTL**（双反演判据；追加块，不改 ⑨ 的读数）
                new TextDpMinBlock(),   // ⑪ **最小复现**
                new NativeComboBlock(),  // ⑫ **标准 ComboBox 下拉**（`D-G50` 的判别仪器；波 `#45`）：SelectedText 改容器 / Text DP 是否跟随（无 X 注入）
                new ClickProbeBlock(),   // ⑬ **点击必须有反应**（波 `#47`）：ListBox 项 / TextBox / ComboBox 下拉项，
                                         //    语义 EVT ＋ 原始命中 EVT（含 `e.ButtonState`）＋ `POS` 自报坐标；点击由外部驱动给
            };

            var wanted = string.IsNullOrEmpty(only)
                ? all
                : all.Where(b => only.Split(',').Select(x => x.Trim()).Contains(b.Name)).ToList();

            Console.WriteLine($"[wfp] 模式：blocks={(string.IsNullOrEmpty(only) ? "all" : only)} 数量={wanted.Count} late_ms={lateMs}");
            Console.WriteLine($"WFP_MODE=blocks:{(string.IsNullOrEmpty(only) ? "all" : only)} count={wanted.Count}");

            foreach (var b in wanted)
            {
                try
                {
                    b.Build(ProbeHost);
                    _blocks.Add(b);
                }
                catch (Exception ex)
                {
                    // 构造期异常：**算这一块的 FAIL**，并让它留在台账里（不是静默跳过）
                    Report(b.Name, "FAIL", $"构造异常 {ex.GetType().Name}: {OneLine(ex.Message)}");
                }
            }

            Loaded += (s, e) => Dispatcher.BeginInvoke(DispatcherPriority.ContextIdle, new Action(VerifyAll));
            // ── 时序修复（2026-09-14，主控/T1c 定案后；**改的是时序，不是判据**）──────────
            // 【原缺陷】late 定时器在 `Loaded` 就起（旧写死 6s），而 `VerifyAll` 是 `ContextIdle`
            //   投递、会被 ~10s 的首帧顶到后面 ⇒ **LateVerify 跑在 Verify 之前**（实测：日志 L589/L599
            //   是 `WFP_DISPATCH_PRIO …=False` 与 `late:` 行，而 `WFP_DISPATCH_PROBE=posted`/`OK`
            //   在 L723/L734 ⇒ 顺序与设计相反；且两者**都早于注入**，首个按键在 L1492）。
            //   ⇒ 现在把 late 定时器改成**在第一次 VerifyAll 跑完之后**才起（见 VerifyAll 末尾），
            //     保证"late 确实晚于 verify"。**判定口径一个字没动。**
            _lateMs = lateMs;
        }

        private int _lateMs;
        private bool _lateStarted;

        private static string ArgValue(string[] argv, string prefix)
        {
            foreach (var a in argv) if (a.StartsWith(prefix, StringComparison.Ordinal)) return a.Substring(prefix.Length);
            return null;
        }

        private static string OneLine(string s) => (s ?? "").Replace("\r", " ").Replace("\n", " ");

        private void VerifyAll()
        {
            foreach (var b in _blocks)
            {
                try { b.Verify(); }
                catch (Exception ex) { Report(b.Name, "FAIL", $"Verify 异常 {ex.GetType().Name}: {OneLine(ex.Message)}"); }
            }
            if (_blocks.Count == 0) Console.WriteLine("[wfp] 警告：没有任何功能块被构造（--only 写错了？）");
            RefreshSummary();
            // late 校验**从现在起**计时（不是在 Loaded）⇒ 保证 LateVerify 一定晚于 Verify（时序修复）。
            if (_lateMs > 0 && !_lateStarted)
            {
                _lateStarted = true;
                var t = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(_lateMs) };
                t.Tick += (s, e) => { t.Stop(); LateVerifyAll(); };
                t.Start();
                Console.WriteLine($"WFP_LATE_SCHEDULED from=VerifyAll-complete after_ms={_lateMs}");
            }
        }

        private void LateVerifyAll()
        {
            foreach (var b in _blocks.Where(x => x.NeedsLateCheck))
            {
                try { b.LateVerify(); }
                catch (Exception ex) { Report(b.Name, "FAIL", $"LateVerify 异常 {ex.GetType().Name}: {OneLine(ex.Message)}"); }
            }
            RefreshSummary();
            Console.WriteLine($"[wfp] 台账完成（块数={_blocks.Count}）");
        }

        /// <summary>块级台账 + **屏上副本**（读图核对用）。</summary>
        private void Report(string name, string verdict, string evidence)
        {
            Ledger.Line(name, verdict, evidence);
            _verdicts[name] = verdict;
        }

        private void RefreshSummary()
        {
            var ok = _verdicts.Values.Count(v => v == "OK");
            var fail = _verdicts.Values.Count(v => v == "FAIL");
            var inc = _verdicts.Values.Count(v => v == "INCONCLUSIVE");
            SummaryText.Text = $"块数={_blocks.Count}  OK={ok}  FAIL={fail}  INCONCLUSIVE={inc}";
            VerdictHost.Children.Clear();
            foreach (var kv in _verdicts)
            {
                var color = kv.Value == "OK" ? "#FF6FD3A0" : kv.Value == "FAIL" ? "#FFE5484D" : "#FFF5A524";
                VerdictHost.Children.Add(new TextBlock
                {
                    Text = $"{kv.Key}  {kv.Value}",
                    FontSize = 11,
                    Foreground = (Brush)new BrushConverter().ConvertFromString(color),
                    Margin = new Thickness(0, 1, 0, 1)
                });
            }
        }
    }
}

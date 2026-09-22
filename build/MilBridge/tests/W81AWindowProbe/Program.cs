// ============================================================================
// W81AWindowProbe · 波 `#50` 的两个最小探针合体（**一个二进制、零产品改动**）
// ============================================================================
//
// ① `--mode=pmax-pair`（`TASK-0106`）：`PMaxSize` **声明态端到端腿**
//    · 同一个进程里开**两个**窗口，唯一的差别 = 有没有声明 `MaxWidth/MaxHeight`：
//        role=declared   ⇒ `MaxWidth=W, MaxHeight=H`
//        role=undeclared ⇒ 两个 DP 都不设（保持 `NaN`）
//    · 应用把两个窗口的 **X 窗口 id**（本移植里 `HWND == XID`）印出来
//      ⇒ 装置脚本据此 `xprop -id <xid> WM_NORMAL_HINTS`（**X 服务器自己的属性**，不是我方日志）。
//    · 判据（写死在报告 §0）：declared ⇒ `PMaxSize` **出现且等于声明值**；undeclared ⇒ `PMaxSize` **缺席**。
//
// ② `--mode=flowdoc`（`TASK-0303` 的 `A0`）：**最小 `FlowDocument` 页面**
//    · `Window` → `RichTextBox` → `FlowDocument` → `Paragraph` → `Run`（与上游 `RichTextBoxDemo` 同形）。
//    · 逐拍印 `step=` 标记 ⇒ 装置能判"到底走到哪一步"（`A0-P2` 要 `step=flowdoc-shown`）。
//    · 整条包在 `build/MilBridge/tools/t1b-ls-tripwire.sh` 里跑 ⇒ 真值 = `ld.so` 的符号查找日志。
//
// 【输出约定（机读；一律 `Console.Out` + 显式 `Flush()`）】
//   W81A_PROBE pid=… mode=… hold=…
//   W81A_TOOLKIT pf=… pc=… wb=…            ← 运行期**实际**加载的自产件路径（自证用的不是旧副本）
//   W81A_PROBE step=…                      ← 逐拍进度（A0 用它判"走到哪一步"）
//   W81A_WINDOW role=declared|undeclared xid=0x… max=WxH|none  ← 两极化腿的被观测窗口
//   W81A_READY mode=… windows=…            ← 装置脚本从这里开始 xprop
//   W81A_PROBE=ALIVE mode=…               ← 撑满 hold 且没抛 ⇒ "活着"（A0 那趟预期**看不到**它）
//   W81A_PROBE=EXC type=… msg=…            ← 捕获到的异常（**不吞**：照原样继续走向 FailFast）
// ============================================================================

using System;
using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Interop;
using System.Windows.Threading;

namespace W81AWindowProbe
{
    internal static class Program
    {
        private static string g_mode = "pmax-pair";
        private static double g_maxW = 640, g_maxH = 480;
        private static double g_minW = 500, g_minH = 400;   // 只给诊断臂③（`minonly`）用
        private static double g_hold = 12;

        private static void Say(string s)
        {
            Console.Out.WriteLine(s);
            Console.Out.Flush();
        }

        [STAThread]
        private static int Main(string[] args)
        {
            foreach (string a in args)
            {
                if (a.StartsWith("--mode=", StringComparison.Ordinal)) g_mode = a.Substring(7);
                else if (a.StartsWith("--max=", StringComparison.Ordinal))
                {
                    string v = a.Substring(6);
                    string[] p = v.Split('x', 'X');
                    if (p.Length == 2)
                    {
                        double w, h;
                        if (double.TryParse(p[0], NumberStyles.Float, CultureInfo.InvariantCulture, out w) &&
                            double.TryParse(p[1], NumberStyles.Float, CultureInfo.InvariantCulture, out h))
                        { g_maxW = w; g_maxH = h; }
                    }
                }
                else if (a.StartsWith("--hold=", StringComparison.Ordinal))
                {
                    double hv;
                    if (double.TryParse(a.Substring(7), NumberStyles.Float, CultureInfo.InvariantCulture, out hv)) g_hold = hv;
                }
            }

            Say(string.Format(CultureInfo.InvariantCulture,
                "W81A_PROBE pid={0} mode={1} hold={2} max={3}x{4}",
                Environment.ProcessId, g_mode, g_hold, g_maxW, g_maxH));
            Say("W81A_TOOLKIT wb=" + typeof(System.Windows.DependencyObject).Assembly.Location
                + " pc=" + typeof(System.Windows.Media.Visual).Assembly.Location
                + " pf=" + typeof(System.Windows.Window).Assembly.Location
                + " runtime=" + Environment.Version.ToString());

            AppDomain.CurrentDomain.UnhandledException += (s, e) =>
            {
                Exception ex = e.ExceptionObject as Exception;
                Say("W81A_PROBE=EXC where=appdomain type=" + (ex == null ? "<non-exception>" : ex.GetType().FullName)
                    + " msg=" + (ex == null ? "<null>" : ex.Message.Replace('\n', ' ')));
            };

            var app = new Application();
            app.DispatcherUnhandledException += (s, e) =>
            {
                Say("W81A_PROBE=EXC where=dispatcher type=" + e.Exception.GetType().FullName
                    + " msg=" + e.Exception.Message.Replace('\n', ' '));
                // ⚠️ **不设 `e.Handled = true`**：本探针要量的是**真实行为**（`D-G70` 的现场是
                //    `FailFast` 整进程死）。吞掉异常会把"死"变成"活着但没渲染"，那是另一回事。
            };

            int rc = 0;
            try
            {
                switch (g_mode)
                {
                    case "pmax-pair": RunPmaxPair(app); break;
                    case "flowdoc":   RunFlowDoc(app);  break;
                    default:
                        Say("W81A_PROBE=NOINFO reason=unknown-mode mode=" + g_mode);
                        return 2;
                }
            }
            catch (Exception ex)
            {
                Say("W81A_PROBE=EXC where=main type=" + ex.GetType().FullName
                    + " msg=" + ex.Message.Replace('\n', ' '));
                rc = 3;
            }

            // 撑满 `hold`（也把 X 事件/布局消息泵干净：`Show()` 之后的提示与几何要落地）
            var t = new DispatcherTimer(DispatcherPriority.Normal);
            t.Interval = TimeSpan.FromSeconds(g_hold);
            t.Tick += (s, e) => { t.Stop(); Say("W81A_PROBE=ALIVE mode=" + g_mode); app.Shutdown(); };
            t.Start();
            app.Run();
            Say("W81A_PROBE=EXIT mode=" + g_mode + " rc=" + rc);
            return rc;
        }

        // ── ① `PMaxSize` 两极化：**同一进程、四个窗口**（两个判据臂 + 两个诊断臂） ────────
        //   判据臂：declared（Show 之前声明）/ undeclared（不声明）—— 唯一的自变量就是那两个 DP。
        //   诊断臂（**如实报、不参与 PASS/FAIL**）：
        //     · late        —— 先 `Show()`、**之后**才赋 `MaxWidth/MaxHeight`；
        //     · sizecontent —— `SizeToContent` + 超限内容 + 声明上限（⇒ 用**布局结果**证明
        //                      `MaxWidth` 在本移植里是个**活的 DP**，而不是"我设了个没人读的值"）。
        private static void RunPmaxPair(Application app)
        {
            var declared = new Window
            {
                Title = "W81A-PMAX-DECLARED-" + Environment.ProcessId,
                Width = 360, Height = 260,
                MaxWidth = g_maxW, MaxHeight = g_maxH,
            };
            var plain = new Window
            {
                Title = "W81A-PMAX-UNDECLARED-" + Environment.ProcessId,
                Width = 360, Height = 260,
            };
            var late = new Window
            {
                Title = "W81A-PMAX-LATE-" + Environment.ProcessId,
                Width = 360, Height = 260,
            };
            var sc = new Window
            {
                Title = "W81A-PMAX-SIZECONTENT-" + Environment.ProcessId,
                MaxWidth = g_maxW, MaxHeight = g_maxH,
                SizeToContent = SizeToContent.WidthAndHeight,
                Content = new Border { Width = 2000, Height = 1500, Background = System.Windows.Media.Brushes.Gray },
            };
            // 诊断臂③：**只声明下限**。`WM_GETMINMAXINFO` 是同一条通道（`ptMinTrackSize` 与
            // `ptMaxTrackSize` 都靠窗口过程回填）⇒ 它能把"这一格坏在哪"从"上限那一半"推广到"整条通道"。
            var minOnly = new Window
            {
                Title = "W81A-PMAX-MINONLY-" + Environment.ProcessId,
                Width = 360, Height = 260,
                MinWidth = g_minW, MinHeight = g_minH,
            };

            Say("W81A_PROBE step=pmax-before-show");
            declared.Show();
            Say("W81A_PROBE step=pmax-declared-shown");
            plain.Show();
            Say("W81A_PROBE step=pmax-undeclared-shown");
            late.Show();
            Say("W81A_PROBE step=pmax-late-shown");
            late.MaxWidth = g_maxW;                    // ← Show() **之后**才声明（诊断臂）
            late.MaxHeight = g_maxH;
            Say("W81A_PROBE step=pmax-late-declared");
            sc.Show();
            Say("W81A_PROBE step=pmax-sizecontent-shown");
            minOnly.Show();
            Say("W81A_PROBE step=pmax-minonly-shown");

            Report("declared", declared, "declared");
            Report("undeclared", plain, "none");
            Report("late", late, "late");
            Report("sizecontent", sc, "sizecontent");
            Report("minonly", minOnly, "min-declared");
            Say("W81A_READY mode=pmax-pair windows=5");
        }

        private static void Report(string role, Window w, string how)
        {
            // `dp=` 是**那两个 DP 的回读**（证明探针真的设了值，而不是设了个没人读的东西）；
            // `dpi=` 是**工具包自己报的设备比例**（公开 API `VisualTreeHelper.GetDpi`）——
            //   判据要按它把 DIP 换算成像素（上游写回那一句是 `LogicalToDeviceUnits`），
            //   这个换算不能靠我在报告里猜一个常数。
            // `xid` = 本移植里的 X 窗口 id（shim 直接把 XID 当 HWND 用）。
            string dpi = "<未知>";
            try
            {
                var d = System.Windows.Media.VisualTreeHelper.GetDpi(w);
                dpi = d.DpiScaleX.ToString("0.######", CultureInfo.InvariantCulture) + "x"
                    + d.DpiScaleY.ToString("0.######", CultureInfo.InvariantCulture);
            }
            catch (Exception ex) { dpi = "<EXC:" + ex.GetType().Name + ">"; }
            Say(string.Format(CultureInfo.InvariantCulture,
                "W81A_WINDOW role={0} how={1} xid=0x{2:x} req={3}x{4} actual={5}x{6} dp={7}x{8} dpmin={9}x{10} dpi={11}",
                role, how, new WindowInteropHelper(w).Handle.ToInt64(),
                w.Width, w.Height, w.ActualWidth, w.ActualHeight, w.MaxWidth, w.MaxHeight,
                w.MinWidth, w.MinHeight, dpi));
        }

        // ── ② 最小 `FlowDocument` 页面（`A0`） ──────────────────────────────────
        private static void RunFlowDoc(Application app)
        {
            var doc = new FlowDocument();
            doc.Blocks.Add(new Paragraph(new Run("W81A minimal FlowDocument page")));
            Say("W81A_PROBE step=flowdoc-doc-built");

            var rtb = new RichTextBox { Document = doc };
            var w = new Window
            {
                Title = "W81A-FLOWDOC-" + Environment.ProcessId,
                Width = 800, Height = 600,
                Content = rtb,
            };
            Say("W81A_PROBE step=flowdoc-host-built");

            w.Show();                       // ← 这一步触发文档布局 ⇒ 真正的 PTS 需求从这儿开始
            Say("W81A_PROBE step=flowdoc-shown");
            Say(string.Format(CultureInfo.InvariantCulture,
                "W81A_WINDOW role=flowdoc xid=0x{0:x}",
                new WindowInteropHelper(w).Handle.ToInt64()));
            Say("W81A_READY mode=flowdoc windows=1");

            // 第二个（独立的）触碰点：**分页器**。`Show()` 之后 1 秒再走，等布局消息泵过一轮
            //   ⇒ 若第一条路没把 PTS 要出来，这一条会；若第一条已经死了，这一拍根本不会打印。
            var t = new DispatcherTimer(DispatcherPriority.Normal);
            t.Interval = TimeSpan.FromSeconds(1);
            t.Tick += (s, e) =>
            {
                t.Stop();
                try
                {
                    Say("W81A_PROBE step=flowdoc-paginator-begin");
                    var pag = ((IDocumentPaginatorSource)doc).DocumentPaginator;
                    Say("W81A_PROBE step=flowdoc-paginator-obtained");
                    var pg = pag.GetPage(0);
                    Say(string.Format(CultureInfo.InvariantCulture,
                        "W81A_PROBE step=flowdoc-getpage-ok page={0}x{1}", pg.Size.Width, pg.Size.Height));
                }
                catch (Exception ex)
                {
                    Say("W81A_PROBE step=flowdoc-paginator-EXC type=" + ex.GetType().FullName
                        + " msg=" + ex.Message.Replace('\n', ' '));
                }
            };
            t.Start();
        }
    }
}

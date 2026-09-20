using System;
using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace WpfTextDemo
{
    /// <summary>ListBox 的数据项（数据绑定演示用）。</summary>
    public class DemoRow
    {
        public string Title { get; set; }
        public string Detail { get; set; }
    }

    /// <summary>
    /// 默认配置门禁样例的主窗口。
    ///
    /// 【设计原则】**每一项可见特性都必须能被外部（xwd 截图 + 读图）判真伪**，
    ///   所以：文字/图形用高饱和、彼此可区分的颜色；鼠标事件既改颜色又打印一行台账；
    ///   位图生成走"真位图"路径并在控制台说明走的是哪条路。
    /// </summary>
    public partial class MainWindow : Window
    {
        private static readonly Brush HitIdle  = new SolidColorBrush(Color.FromRgb(0x2A, 0x3A, 0x55));
        private static readonly Brush HitHover = new SolidColorBrush(Color.FromRgb(0x3E, 0x7D, 0x5A));
        private static readonly Brush HitDown  = new SolidColorBrush(Color.FromRgb(0xB4, 0x55, 0x3F));

        private bool _hover;
        private int _clicks;

        public MainWindow()
        {
            InitializeComponent();

            // ── **常开读数**（不是诊断开关，验收档也要打）──────────────────────────
            //   判据⑥（"滚动必须改变画面"）的**前提**是"左列内容确实高于视口"。这个前提一旦被
            //   别的车道的改动破坏（实测 2026-09-11：波 8 让每段文本少算一行 ⇒ 内容 649.2 <
            //   视口 717.1），现场只剩"滚动前后 AE=0"这一条现象 ⇒ 读的人只能**反推**，分不清
            //   "没东西可滚"与"滚了但画面没变"。
            //   这里把它变成**一行一眼可见的事实**：
            //     `WPTD_SCROLL_RANGE=extent=… viewport=… scrollable=… bar=… offset=…`   （首绘后）
            //     `WPTD_SCROLL_MOVED=offset=…`                                           （偏移真变了时，最多 5 行）
            //   只报事实、不改任何行为；runner 现在不看这两行，但人/将来的判据可以立刻分辨。
            Loaded += (s, e) => ReportScrollRange();

            // ── 诊断开关（**主验收路径不使用**；见文件末 WPTD_MODE 的语义）──────────
            //   --minimal              : 用代码构造一棵**最小可视树**（3 个短 TextBlock），
            //                            绕开 BAML 里的大段文本。用途：区分"是文本量/特性把
            //                            文本快路径顶掉了"还是"这个 app/产物本身有问题"。
            //   --diagnostic-degraded  : 把已知阻塞的特性逐条关掉（折行/省略号/对齐/列表项），
            //                            以便先拿到**图证**去定位别的缺陷。会**大声列出降级了什么**，
            //                            并打印 `WPTD_DEGRADED=...` 机读标记。
            //   ⚠️ 这两个开关都**不得**出现在主验收档（default）与 env 对照档里：
            //      门禁要量的就是"真应用默认配置"，降级档只作诊断。
            string[] argv = Environment.GetCommandLineArgs();
            bool minimal = Array.IndexOf(argv, "--minimal") >= 0;
            // --text-volume=N：最小树里放 N 行文本（默认 3）。用途：**边界探测** ——
            //   "多少文本量会让行创建从快路径翻到 FullTextLine（→LS→崩）"。
            int volume = 3;
            foreach (var a in argv)
                if (a.StartsWith("--text-volume=", StringComparison.Ordinal) &&
                    int.TryParse(a.Substring("--text-volume=".Length), out var v)) volume = v;
            bool degraded = Array.IndexOf(argv, "--diagnostic-degraded") >= 0;
            // --late-content：**首帧之后**再改可视树（`#34` 波诊断开关）。判据：截屏里出现
            //   RGB(255,0,255) ⇒ 变更进了合成；没有 ⇒ 没进。第三方应用 HandyControl 的示例工程
            //   正是在 `OnContentRendered` 里 `ControlMain.Content = …`，而屏幕上只剩背景
            //   （`WPF_LINUX_MIL_TRACE`：通道 committed=120，但合成侧 `视觉树={子=0 内容=无}`）。
            //   ⚠️ 与 --minimal/--diagnostic-degraded 同列：**诊断档，不得进主验收档**。
            bool lateContent = Array.IndexOf(argv, "--late-content") >= 0;
            // --late-panel-add：与 --late-content 同族，但改的是"往**既有** Panel 里 append"。
            //   用途：把病因二选一 —— 品红**出现** ⇒ 只有"换 Content"这条路不行；
            //   仍**不出现** ⇒ "首帧后的树变更"整类不行。
            bool latePanelAdd = Array.IndexOf(argv, "--late-panel-add") >= 0;
            // --late-content-layout：与 --late-content 同路，但赋值后**显式**调一次 UpdateLayout()。
            //   A/B：品红出现 ⇒ 病因就是"换 Content 之后没有布局趟"（而不是合成不刷新）。
            bool lateLayout = Array.IndexOf(argv, "--late-content-layout") >= 0;
            // --late-content-invalidate：换 Content 之后再**显式让整棵树失效**。
            //   二分：品红出现 ⇒ 病因在"失效/渲染调度"（换了内容但没人标脏）；
            //         仍不出现 ⇒ 病因在"合成不看新树"（失效了也没用）。
            bool lateInvalidate = Array.IndexOf(argv, "--late-content-invalidate") >= 0;
            // --late-content-swap：**直接**替换 Content（不先置 null，旧内容丢弃）。
            //   二分：若品红出现 ⇒ 病根在探针里那步 `Content = null`（= 探针自伤，不是产品缺陷）；
            //         仍不出现 ⇒ 换 Content 这件事本身在合成侧不生效（产品缺陷）。
            bool lateSwap = Array.IndexOf(argv, "--late-content-swap") >= 0;

            if (minimal)
            {
                Console.WriteLine("[wptd] 诊断模式：--minimal（代码构造最小可视树，等价于把 XAML 缩到 3 个短 TextBlock）");
                Console.WriteLine($"WPTD_MODE=minimal WPTD_TEXT_VOLUME={volume}");
                BuildMinimalContent(volume);
                SetupImage();
                SetupInputDiag();
                return;
            }

            // 【注意】降级档**不调用 SetupItems()**：实测（2026-09-11）给 ListBox 赋 ItemsSource
            //   会走 Selector.OnItemsChanged → SelectionChanger.End → ListBox.OnSelectionChanged
            //   → AutomationPeer.ListenerExists → …（UIA 缺陷 D1/D2 就在这条路上），
            //   连赋 null 也算一次集合变化 ⇒ 必须**整个跳过**，而不是事后置 null。
            // --wic-image=<png 路径>：**诊断专用**，改用 `BitmapImage`（解码器 ⇒ WIC 路径）
            //   而不是 `BitmapSource.Create`（进程内位图）。用途：D-d 的 `[cwic-trace]`
            //   只在**外部 WIC 句柄**那条路上打印，`Create` 那条路不触发 ⇒ 需要这条腿取证。
            string wicImage = null;
            foreach (var a in argv)
                if (a.StartsWith("--wic-image=", StringComparison.Ordinal))
                    wicImage = a.Substring("--wic-image=".Length);

            if (!degraded) SetupItems();
            if (!string.IsNullOrEmpty(wicImage)) SetupImageFromFile(wicImage); else SetupImage();
            if (degraded) ApplyDiagnosticDegraded();

            Console.WriteLine("[wptd] MainWindow 构造完成：可视树已建（含 ScrollViewer / ListBox / Image / Effect）");
            Console.WriteLine("WPTD_MODE=" + (degraded ? "degraded" : "full"));
            if (lateContent || latePanelAdd || lateLayout || lateInvalidate || lateSwap)
            {
                if (!s_layoutHookInstalled) { s_layoutHookInstalled = true; LayoutUpdated += (s, e) => s_layoutUpdatedCount++; }
                ScheduleLateContent(latePanelAdd, lateLayout, lateInvalidate, lateSwap);
            }
            SetupInputDiag();
        }

        /// <summary>
        /// 诊断开关 `WPTD_INPUT_DIAG=1`：把**滚轮 → 滚动**这条链的每一跳打出来。
        ///
        /// 【为什么需要它】2026-09-11 的 wave-8 回归里判据⑥（滚动必须改变画面）红了：
        ///   窗口收到了 8 条 `msg=0x020a`（delta=-120）却**一帧都没变**（AE=0）。
        ///   "消息到了 hwnd"、"WPF 输入系统收到了"、"ScrollViewer 收到滚轮"、
        ///   "偏移真的变了"、"渲染跟着变了" 是**五个不同的跳**，光看截图分不出来。
        ///   这里逐跳打点，好把"是 WPF/垫片缺陷"与"是样例/仪器问题"分开。
        ///
        /// **默认关闭**：开关没设时一行日志都不加，主验收档读数不受影响。
        /// </summary>
        /// <summary>`#34` 诊断：**首帧之后**改可视树（与 HandyControl 的 `Content` 赋值同类）。</summary>
        /// <summary>`#34` 诊断：**首帧之后**改可视树（与 HandyControl 的 `Content` 赋值同类）。</summary>
        /// <param name="panelAdd">true ⇒ 往**既有** Panel 里 append；false ⇒ 换窗口 `Content`。</param>
        private void ScheduleLateContent(bool panelAdd, bool forceLayout, bool forceInvalidate, bool directSwap)
        {
            Dispatcher.BeginInvoke(System.Windows.Threading.DispatcherPriority.ContextIdle, new Action(() =>
            {
                var r = MakeMagentaRect();
                string how;

                if (directSwap)
                {
                    // 直接替换：不动旧内容（丢弃），也不先置 null —— 与 HandyControl 的写法一致
                    var g = new Grid();
                    g.Children.Add(r);
                    Content = g;
                    Console.WriteLine("WPTD_LATE_CONTENT added=yes how=direct-swap size=" + r.Width + "x" + r.Height + " fill=#FF00FF");
                    return;
                }

                if (panelAdd)
                {
                    var host = FindFirstPanel(this);
                    if (host == null)
                    {
                        Console.WriteLine("WPTD_LATE_CONTENT added=no reason=可视树里找不到Panel");
                        return;
                    }
                    host.Children.Add(r);
                    how = "panel-add-" + host.GetType().Name + "(children=" + host.Children.Count + ")";
                }
                else if (Content is Panel panel)
                {
                    panel.Children.Add(r);
                    how = "append-to-" + panel.GetType().Name;
                }
                else
                {
                    var old = Content as UIElement;
                    Content = null;   // 先断开，否则 add 抛 "already the logical child of another element"
                    var grid = new Grid();
                    if (old != null) grid.Children.Add(old);
                    grid.Children.Add(r);
                    Content = grid;
                    how = "replace-content(old=" + (old?.GetType().Name ?? "null") + ")";
                }

                Console.WriteLine("WPTD_LATE_CONTENT added=yes how=" + how
                    + " size=" + r.Width + "x" + r.Height + " fill=#FF00FF"
                    + " actual_now=" + r.ActualWidth + "x" + r.ActualHeight);

                if (forceLayout)
                {
                    UpdateLayout();   // 显式推一次布局（诊断对照，不是产品修法）
                    Console.WriteLine("WPTD_LATE_CONTENT after_UpdateLayout actual=" + r.ActualWidth + "x" + r.ActualHeight);
                }

                if (forceInvalidate)
                {
                    InvalidateVisual();
                    if (Content is UIElement ce) ce.InvalidateVisual();
                    UpdateLayout();
                    Console.WriteLine("WPTD_LATE_CONTENT after_InvalidateVisual actual=" + r.ActualWidth + "x" + r.ActualHeight);
                }

                // 延迟再读一次：区分"布局还没跑"与"布局永远不跑"。
                Dispatcher.BeginInvoke(System.Windows.Threading.DispatcherPriority.ApplicationIdle, new Action(() =>
                {
                    Console.WriteLine("WPTD_LATE_CONTENT delayed actual=" + r.ActualWidth + "x" + r.ActualHeight
                        + " measureValid=" + IsMeasureValid + " arrangeValid=" + IsArrangeValid
                        + " layoutUpdatedCount=" + s_layoutUpdatedCount);
                }));
            }));
        }

        private static int s_layoutUpdatedCount;
        private static bool s_layoutHookInstalled;

        private static System.Windows.Shapes.Rectangle MakeMagentaRect()
        {
            return new System.Windows.Shapes.Rectangle
            {
                Width = 240,
                Height = 72,
                Fill = new SolidColorBrush(Color.FromRgb(255, 0, 255)),
                HorizontalAlignment = HorizontalAlignment.Right,
                VerticalAlignment = VerticalAlignment.Bottom,
                Margin = new Thickness(0, 0, 12, 12),
            };
        }

        /// <summary>深度优先找可视树上第一个 Panel（找不到返回 null）。</summary>
        private static Panel FindFirstPanel(DependencyObject root)
        {
            int n = VisualTreeHelper.GetChildrenCount(root);
            for (int i = 0; i < n; i++)
            {
                var child = VisualTreeHelper.GetChild(root, i);
                if (child is Panel p) return p;
                var deeper = FindFirstPanel(child);
                if (deeper != null) return deeper;
            }
            return null;
        }

        private void SetupInputDiag()
        {
            if (Environment.GetEnvironmentVariable("WPTD_INPUT_DIAG") != "1") return;
            Console.WriteLine("[wptd-diag] 输入诊断开启（WPTD_INPUT_DIAG=1）");
            // 第 1 跳：滚轮有没有进 WPF 的输入系统（隧道事件，handledEventsToo=true 才能看到被处理的）
            AddHandler(Mouse.PreviewMouseWheelEvent, new MouseWheelEventHandler((s, e) =>
            {
                var svNow = FindScrollViewer(this);
                Console.WriteLine(svNow == null
                    ? $"[wptd-diag] ① PreviewMouseWheel delta={e.Delta} 源={e.OriginalSource?.GetType().Name} **找不到 ScrollViewer**"
                    : $"[wptd-diag] ① PreviewMouseWheel delta={e.Delta} 源={e.OriginalSource?.GetType().Name} 位置={e.GetPosition(this)} sv:vo={svNow.VerticalOffset:F1} extent={svNow.ExtentHeight:F1} viewport={svNow.ViewportHeight:F1}");
            }), true);
            Loaded += (s, e) =>
            {
                var sv = FindScrollViewer(this);
                if (sv == null) { Console.WriteLine("[wptd-diag] **找不到 ScrollViewer**（本档位没有？）"); Console.WriteLine("WPTD_INPUT_DIAG=no-scrollviewer"); return; }
                Console.WriteLine($"[wptd-diag] ② ScrollViewer 初值：vo={sv.VerticalOffset:F1} extent={sv.ExtentHeight:F1} viewport={sv.ViewportHeight:F1} scrollable={sv.ScrollableHeight:F1} 滚动条={sv.ComputedVerticalScrollBarVisibility}");
                Console.WriteLine($"[wptd-diag] ⑤ ScrollViewer 自身=高{sv.ActualHeight:F1} 宽{sv.ActualWidth:F1}；上级={(sv.Parent as FrameworkElement)?.GetType().Name}:{(sv.Parent as FrameworkElement)?.ActualHeight:F1}");
                // 布局取证：ScrollViewer 内容（左列 StackPanel）每个孩子的实测高度 —— 好把
                //   "内容总高从 806.4 缩到 649.2（−157.2）"这笔账**分摊到具体卡片**上，
                //   而不是只留一个总数给下游猜（旧栈 vs 新栈同一探针跑两遍即可 A/B）。
                if (sv.Content is Panel cp)
                {
                    Console.WriteLine($"[wptd-diag] ⑥ 左列内容 {cp.GetType().Name} 实测高={cp.ActualHeight:F1}，{cp.Children.Count} 个孩子：");
                    int ci = 0;
                    foreach (var ch in cp.Children)
                    {
                        if (!(ch is FrameworkElement fe)) continue;
                        Console.WriteLine($"[wptd-diag]    #{ci} {fe.GetType().Name} name={(string.IsNullOrEmpty(fe.Name) ? "-" : fe.Name)} 高={fe.ActualHeight:F1} 宽={fe.ActualWidth:F1}");
                        ci++;
                    }
                }
                // 具名元素高度：文字卡的三条腿（折行/省略号/位图说明）与其它可视特性的宿主
                foreach (var kv in new (string, FrameworkElement)[]
                         { ("WrapText", WrapText), ("TrimText", TrimText), ("ImageNote", ImageNote),
                           ("GeneratedImage", GeneratedImage), ("ItemsList", ItemsList), ("HitCard", HitCard) })
                {
                    if (kv.Item2 == null) continue;
                    Console.WriteLine($"[wptd-diag] ⑦ {kv.Item1}: 高={kv.Item2.ActualHeight:F1} 宽={kv.Item2.ActualWidth:F1}");
                }
                // 第 3 跳：ScrollViewer 自己有没有收到滚轮（以及它有没有把事件吃掉）
                MouseWheelEventHandler svWheel = (a, b) =>
                    Console.WriteLine($"[wptd-diag] ③ ScrollViewer.MouseWheel delta={b.Delta} handled(收到时)={b.Handled} vo={sv.VerticalOffset:F1}");
                sv.AddHandler(Mouse.MouseWheelEvent, svWheel, true);
                // 第 4 跳：偏移真的变了没有
                sv.ScrollChanged += (a, b) =>
                    Console.WriteLine($"[wptd-diag] ④ ScrollChanged vo {b.VerticalOffset:F1}（Δ{b.VerticalChange:F1}）extent={sv.ExtentHeight:F1} viewport={sv.ViewportHeight:F1}");
                Console.WriteLine("WPTD_INPUT_DIAG=ready");
            };
        }

        /// <summary>
        /// 常开读数：报告 ScrollViewer 的 extent / viewport / scrollable（见构造函数里的说明）。
        /// 偏移**真的变了**时另打一行 `WPTD_SCROLL_MOVED=`（最多 5 行，避免刷屏）——
        /// 这样"滚了没变"（渲染问题）与"根本没滚"（没东西可滚 / 注入没到）在日志里就是两回事。
        /// </summary>
        private void ReportScrollRange()
        {
            var sv = FindScrollViewer(this);
            if (sv == null)
            {
                Console.WriteLine("WPTD_SCROLL_RANGE=none（本档位没有 ScrollViewer）");
                return;
            }
            Console.WriteLine($"WPTD_SCROLL_RANGE=extent={sv.ExtentHeight:F1} viewport={sv.ViewportHeight:F1} scrollable={sv.ScrollableHeight:F1} bar={sv.ComputedVerticalScrollBarVisibility} offset={sv.VerticalOffset:F1}");
            int logged = 0;
            sv.ScrollChanged += (s, e) =>
            {
                if (logged++ >= 5) return;
                Console.WriteLine($"WPTD_SCROLL_MOVED=offset={e.VerticalOffset:F1} delta={e.VerticalChange:F1} scrollable={sv.ScrollableHeight:F1}");
            };
        }

        private static ScrollViewer FindScrollViewer(DependencyObject root)
        {
            if (root == null) return null;
            if (root is ScrollViewer sv) return sv;            int n = VisualTreeHelper.GetChildrenCount(root);
            for (int i = 0; i < n; i++)
            {
                var r = FindScrollViewer(VisualTreeHelper.GetChild(root, i));
                if (r != null) return r;
            }
            return null;
        }

        /// <summary>
        /// 诊断用最小可视树：与 `/tmp/wptd-iso` 那套 XAML 变体等价的代码版，
        /// 让"最小复现"成为**一行命令**（`dotnet WpfTextDemo.dll --minimal`）而不是一堆 XAML。
        /// </summary>
        private void BuildMinimalContent(int volume)
        {
            var panel = new StackPanel { Margin = new Thickness(16) };
            for (int i = 0; i < volume; i++)
            {
                panel.Children.Add(new TextBlock
                {
                    Text = i == 0
                        ? "Minimal: Hello WPF on Linux"
                        : $"line {i:D2} ascii 中文 mixed 第{i:D2}行",
                    FontSize = i == 0 ? 24 : 13,
                    FontWeight = i == 0 ? FontWeights.Bold : FontWeights.Normal,
                    Foreground = i == 0 ? Brushes.White : new SolidColorBrush(Color.FromRgb(0xE9, 0xF1, 0xFF)),
                    Margin = new Thickness(0, 4, 0, 0)
                });
            }
            // 最小树里也放**一个带鼠标处理器的 Border**（不加文本，避免改变文本量）：
            //   这样 --minimal 档就能真正验证"命中测试 + 事件派发"这条链
            //   （已知崩溃修好后，这是唯一能活着跑到注入时刻的档位）。
            panel.Children.Add(new Border
            {
                Name = "MinimalHitCard",
                Height = 30,
                Margin = new Thickness(0, 20, 0, 0),
                Background = HitIdle,
                Child = new TextBlock { Text = "", FontSize = 1 }   // 占位，不产生额外文本行
            });
            var hitProbe = (Border)panel.Children[panel.Children.Count - 1];
            hitProbe.MouseEnter += OnHitEnter;
            hitProbe.MouseLeftButtonDown += OnHitDown;

            Content = panel;   // 原来的 Border/Grid/大段文本整棵被换掉 ⇒ 不再参与测量
        }

        /// <summary>
        /// 诊断降级：把**已知阻塞**的可见特性逐条关掉，好让门禁先拿到图证。
        /// 每一条都打印在控制台，并汇总成 `WPTD_DEGRADED=` 机读标记 —— 结论必须带这个前提读。
        /// </summary>
        private void ApplyDiagnosticDegraded()
        {
            Console.WriteLine("[wptd] ⚠️ 诊断降级模式：以下特性被**关闭**（主验收档不使用本模式）");
            Console.WriteLine("[wptd]   ① TextWrapping=Wrap  → NoWrap（绕开折行）");
            WrapText.TextWrapping = TextWrapping.NoWrap;
            Console.WriteLine("[wptd]   ② TextTrimming=CharacterEllipsis → None（绕开省略号）");
            TrimText.TextTrimming = TextTrimming.None;
            Console.WriteLine("[wptd]   ③ TextAlignment Center/Right → Left（绕开三档对齐）");
            foreach (var tb in new[] { WrapText, TrimText })
                tb.TextAlignment = TextAlignment.Left;
            Console.WriteLine("[wptd]   ④ ListBox **完全不喂数据**（连 ItemsSource 赋值都跳过 —— 赋值本身就会");
            Console.WriteLine("[wptd]      触发 Selector.OnItemsChanged → ListBox.OnSelectionChanged → AutomationPeer → UIA 缺陷 D1/D2）");
            Console.WriteLine("[wptd]   ⑤ 保留：Image / Border 圆角 / DropShadowEffect / ScrollViewer / 鼠标命中");
            Console.WriteLine("WPTD_DEGRADED=wrap,trim,align,items");
        }

        // ── 数据绑定：ItemsControl/ListBox + 真滚动 ────────────────────────────
        private void SetupItems()
        {
            // 24 项 > ListBox 高度 ⇒ 它自己的 ScrollViewer 出现滚动条（真滚动，不是装饰）
            var rows = new ObservableCollection<DemoRow>();
            for (int i = 1; i <= 24; i++)
            {
                rows.Add(new DemoRow
                {
                    Title = $"绑定项 {i:D2} / Item {i:D2}",
                    Detail = i % 3 == 0
                        ? "detail: 中英混排 mixed text，用来验证绑定后的文本排版"
                        : $"detail: bound via ItemsSource ({i * 7} ms)"
                });
            }
            ItemsList.ItemsSource = rows;
            // ── 初始选中：**已知缺陷的现场**（不静默、不绕过）────────────────────
            //   实测（2026-09-11，本样例首跑）：只要 Selector 发生选中变化就会走
            //     ListBox.OnSelectionChanged → AutomationPeer.ListenerExists
            //     → AutomationPeer..cctor → TextPatternIdentifiers..cctor
            //     → MS.Internal.Automation.UiaCoreTypesApi.UiaGetReservedMixedAttributeValue()
            //     → **MarshalDirectiveException: COM 接口指针参数在 Linux 上无法封送**
            //     （该 P/Invoke 指向 Windows 的 UIAutomationCore.dll，Linux 上不存在）
            //   ⇒ 进程 abort（exit 134），窗口根本出不来。
            //   这是 **build/ 车道**的缺口（UIAutomationTypes 的 COM 封送需要按 T2 补丁 H
            //   的同一手法短路），**不在本样例可修范围**。
            //   这里的处置：**catch + 大声登记**（不是静默吞掉）——样例继续跑，
            //   好让"渲染/文本"这条面仍然可被门禁测量；缺陷本身交给 runner 的
            //   `WPTD_KNOWN_DEFECT` 行报给主控。
            try
            {
                ItemsList.SelectedIndex = 2;
                Console.WriteLine($"[wptd] 数据绑定：ItemsSource 已设，{rows.Count} 项（SelectedIndex=2）");
            }
            catch (Exception ex)
            {
                Console.WriteLine("[wptd] ❌ 初始选中失败（已知缺陷：UIAutomationTypes 的 COM 封送在 Linux 上不可用）");
                Console.WriteLine($"[wptd]    异常：{ex.GetType().Name}: {ex.Message.Split('\n')[0]}");
                Console.WriteLine("[wptd]    影响：ListBox 无初始选中；**任何选中变化（含用户点击条目）都会再次触发同一缺陷**");
                Console.WriteLine("[wptd]    车道：build/UIAutomationTypes（M7b/T 侧）；本样例只登记不改");
                Console.WriteLine("WPTD_KNOWN_DEFECT=uia-com-marshal");
            }
        }

        // ── 程序生成位图 ──────────────────────────────────────────────────────
        private void SetupImage()
        {
            const int N = 96;
            const int stride = N * 4;
            var px = new byte[N * stride];

            // 四象限 + 对角渐变 + 白色边框：一眼能看出位图真的按像素画上去了
            for (int y = 0; y < N; y++)
            {
                for (int x = 0; x < N; x++)
                {
                    int o = y * stride + x * 4;
                    byte b, g, r;
                    bool qx = x >= N / 2, qy = y >= N / 2;
                    if (qx && !qy)      { r = 0xE5; g = 0x3F; b = 0x3F; }   // 右上：红
                    else if (!qx && qy) { r = 0x3F; g = 0x7D; b = 0xE5; }   // 左下：蓝
                    else if (qx && qy)  { r = 0xE5; g = 0xC4; b = 0x3F; }   // 右下：黄
                    else                { r = 0x3F; g = 0xC4; b = 0x6B; }   // 左上：绿
                    // 【为什么改成**平坦象限**】原来的"对角渐变调制"会让每个像素都偏离基准色，
                    //   于是门禁里那四个期望色（#E53F3F/#3FC46B/#3F7DE5/#E5C43F）**在位图里根本不存在**
                    //   ⇒ 判据④ 的 image_content_* 成了**永远红**的假判据（2026-09-11 自查发现：
                    //   实测位图只有 179 种颜色，四个基准色一个都没有）。
                    //   现在四象限是**精确的平坦色**（判据可满足、且"画没画"一眼可判），
                    //   纹理改由右下角那条渐变带提供（见下面 strip 分支），信息量不减。
                    // 一条对角渐变带（保留"很多不同颜色"的性质，便于直方图/读图观察）
                    if (x >= 60 && x < 84) { int t = (y * 255) / N; r = (byte)(0x30 + t / 3); g = (byte)(0x80 + t / 4); b = (byte)(0xE0 - t / 2); }
                    if (x < 3 || y < 3 || x >= N - 3 || y >= N - 3) { r = g = b = 0xF0; }  // 白框
                    px[o] = b; px[o + 1] = g; px[o + 2] = r; px[o + 3] = 0xFF;
                }
            }

            try
            {
                var bmp = BitmapSource.Create(N, N, 96, 96, PixelFormats.Bgra32, null, px, stride);
                bmp.Freeze();
                GeneratedImage.Source = bmp;
                ImageNote.Text = $"位图路径：BitmapSource.Create（{N}x{N} Bgra32，{N * N} 像素）→ MilDrawImage";
                Console.WriteLine($"[wptd] 位图：BitmapSource.Create 成功 {N}x{N} Bgra32 stride={stride}");
                // 【给 D-d 取证】"Create 返回了" ≠ "源真的是 96x96"。
                //   实测（2026-09-11）：应用这边 Create 成功、T2b 在渲染侧量到的是
                //   `WIC 句柄 … 物化成功（**1×1** Bgra8888）` ⇒ 两边读数不一致。
                //   这里把**源对象自己报的尺寸**打出来：若它报 96x96 而物化是 1x1，
                //   问题在 port 的 WIC 路径；若它自己就报 1x1，则 Create 静默降级。
                //   （只加日志，不改任何行为；DrawingImage 那段一个字没动。）
                var srcAsBitmap = GeneratedImage.Source as BitmapSource;
                if (srcAsBitmap != null)
                {
                    Console.WriteLine($"[wptd] 位图源自报：BitmapSource PixelWidth={srcAsBitmap.PixelWidth} PixelHeight={srcAsBitmap.PixelHeight} Format={srcAsBitmap.Format} DpiX={srcAsBitmap.DpiX}");
                    Console.WriteLine($"WPTD_IMAGE_SOURCE=BitmapSource:{srcAsBitmap.PixelWidth}x{srcAsBitmap.PixelHeight}:{srcAsBitmap.Format}");
                }
                else
                {
                    Console.WriteLine($"WPTD_IMAGE_SOURCE={GeneratedImage.Source?.GetType().Name ?? "null"}");
                }
            }
            catch (Exception ex)
            {
                // 诚实降级：位图路径不可用时用矢量图顶上，并把**真实原因**打出来（不静默）
                Console.WriteLine($"[wptd] 位图：BitmapSource.Create 失败（{ex.GetType().Name}: {ex.Message}）→ 回退矢量 DrawingImage");
                var dg = new DrawingGroup();
                dg.Children.Add(new GeometryDrawing(
                    new SolidColorBrush(Color.FromRgb(0x3F, 0xC4, 0x6B)), null,
                    new RectangleGeometry(new Rect(0, 0, 48, 48))));
                dg.Children.Add(new GeometryDrawing(
                    new SolidColorBrush(Color.FromRgb(0xE5, 0x3F, 0x3F)), null,
                    new RectangleGeometry(new Rect(48, 0, 48, 48))));
                dg.Children.Add(new GeometryDrawing(
                    new SolidColorBrush(Color.FromRgb(0x3F, 0x7D, 0xE5)), null,
                    new RectangleGeometry(new Rect(0, 48, 48, 48))));
                dg.Children.Add(new GeometryDrawing(
                    new SolidColorBrush(Color.FromRgb(0xE5, 0xC4, 0x3F)), null,
                    new RectangleGeometry(new Rect(48, 48, 48, 48))));
                var img = new DrawingImage(dg);
                img.Freeze();
                GeneratedImage.Source = img;
                ImageNote.Text = "位图路径：**回退** DrawingImage（BitmapSource.Create 抛异常，见控制台）";
                Console.WriteLine("WPTD_IMAGE_SOURCE=DrawingImage:fallback");
            }
        }

        /// <summary>
        /// 诊断专用：用 `BitmapImage` 从 PNG 文件加载（解码器 ⇒ WIC 路径）。
        /// 二选一由命令行 `--wic-image=<path>` 决定；**验收档不使用**。
        /// </summary>
        private void SetupImageFromFile(string path)
        {
            try
            {
                var bi = new BitmapImage();
                bi.BeginInit();
                bi.UriSource = new Uri(path, UriKind.Absolute);
                bi.CacheOption = BitmapCacheOption.OnLoad;
                bi.EndInit();
                bi.Freeze();
                GeneratedImage.Source = bi;
                ImageNote.Text = $"位图路径：BitmapImage（WIC 解码器）← {path}";
                Console.WriteLine($"[wptd] 位图：BitmapImage {path} 源自报 {bi.PixelWidth}x{bi.PixelHeight} {bi.Format}");
                Console.WriteLine($"WPTD_IMAGE_SOURCE=BitmapImage:{bi.PixelWidth}x{bi.PixelHeight}:{bi.Format}:{path}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[wptd] 位图：BitmapImage **失败**（{ex.GetType().Name}: {ex.Message.Split('\n')[0]}）");
                Console.WriteLine("WPTD_IMAGE_SOURCE=BitmapImage:failed");
            }
        }

        // ── 鼠标命中与事件（改可见状态 + 打台账）──────────────────────────────
        private void OnHitEnter(object sender, MouseEventArgs e)
        {
            _hover = true;
            UpdateHitVisual();
            Console.WriteLine("[wptd] 事件：MouseEnter（命中 HitCard）");
        }

        private void OnHitLeave(object sender, MouseEventArgs e)
        {
            _hover = false;
            UpdateHitVisual();
            Console.WriteLine("[wptd] 事件：MouseLeave");
        }

        private void OnHitDown(object sender, MouseButtonEventArgs e)
        {
            _clicks++;
            UpdateHitVisual();
            Console.WriteLine($"[wptd] 事件：MouseLeftButtonDown（第 {_clicks} 次）");
        }

        private void UpdateHitVisual()
        {
            HitCard.Background = _clicks > 0 ? HitDown : (_hover ? HitHover : HitIdle);
            HitText.Text = _clicks > 0
                ? $"命中生效：已点击 {_clicks} 次（背景 = 橙）"
                : (_hover ? "命中生效：指针在区域内（背景 = 绿）"
                          : "把指针移到这块区域 → 变绿；点一下 → 变橙（计数 +1）");
        }

        private void OnSelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            var row = ItemsList.SelectedItem as DemoRow;
            Console.WriteLine($"[wptd] 事件：SelectionChanged → {(row == null ? "(null)" : row.Title)}");
        }
    }
}

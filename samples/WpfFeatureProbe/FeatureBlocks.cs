using System;
using System.Collections.Generic;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Effects;
using System.Windows.Shapes;
using System.Windows.Threading;

namespace WpfFeatureProbe
{
    /// <summary>
    /// 台账：**每块一行**，机读 + 人读同一行。
    ///   形如：`[feat] anim OK opacity 0.00→1.00 xform 0.0→40.0 width 40.0→120.0`
    ///   runner 按块 grep，汇总 `WFP_SUMMARY blocks=N ok=… fail=… inconclusive=…`。
    /// </summary>
    internal static class Ledger
    {
        /// <summary>可选的接收端：宿主窗口用它把台账**同步到屏上**（读图即可核对，不必只信日志）。</summary>
        public static Action<string, string> Sink;

        public static void Line(string name, string verdict, string evidence)
        {
            // 证据里**不许有换行**：runner 是逐行 grep 的。
            evidence = (evidence ?? "").Replace("\r", " ").Replace("\n", " ");
            Console.WriteLine($"[feat] {name} {verdict} {evidence}");
            Console.Out.Flush();
            try { Sink?.Invoke(name, verdict); } catch { /* 屏上副本失败不影响台账 */ }
        }
    }

    /// <summary>功能块的公共骨架。构造/布局都可能抛异常 ⇒ 一律由 runner 侧 try/catch 包住。</summary>
    internal abstract class ProbeBlock
    {
        public abstract string Name { get; }
        /// <summary>该块的"测试色"（十六进制，无 #）。runner 用它做**像素核对**（"没抛异常"≠"画出来了"）。</summary>
        public abstract string TestColor { get; }
        /// <summary>可选的第二个测试色（十六进制，无 #）；空串=本块不用第二色。</summary>
        public virtual string NegativeColor => "";
        /// <summary>要不要在滚动之后再做一次延迟核对（动画 / 输入 / 虚拟化这类需要时间的块）。</summary>
        public virtual bool NeedsLateCheck => false;

        public abstract void Build(StackPanel host);
        /// <summary>布局完成后（Loaded + 一帧之后）调用；不实现则跳过。</summary>
        public virtual void Verify() { }
        /// <summary>延迟核对（约 6 秒后）：动画是否真的推进、输入是否真的到达、容器是否被回收。</summary>
        public virtual void LateVerify() { }

        protected static Border Card(string title, Brush border)
        {
            return new Border
            {
                BorderBrush = border,
                BorderThickness = new Thickness(1),
                CornerRadius = new CornerRadius(6),
                Margin = new Thickness(0, 0, 0, 8),
                Padding = new Thickness(8),
                Background = new SolidColorBrush(Color.FromRgb(0x1B, 0x24, 0x36)),
                Child = new StackPanel()
            };
        }

        protected static StackPanel Body(Border card) => (StackPanel)card.Child;

        protected static TextBlock Title(string text) => new TextBlock
        {
            Text = text,
            FontSize = 12,
            FontWeight = FontWeights.Bold,
            Foreground = new SolidColorBrush(Color.FromRgb(0x9F, 0xB4, 0xD0)),
            Margin = new Thickness(0, 0, 0, 4)
        };

        protected static Color C(string hex) => (Color)ColorConverter.ConvertFromString("#" + hex);
        protected static SolidColorBrush B(string hex) => new SolidColorBrush(C(hex));

        /// <summary>
        /// 把控件在**窗口坐标系**里的矩形报出来（机读行 `WFP_BOXID=…`）。
        ///
        /// 【为什么必须有它（2026-09-13 突变自测抓到的假绿）】`textbox-edit` 的像素判据原先
        /// 在**整帧**上做近色计数 ⇒ 画面里**别人的橙色**（台账面板的 `#FFF5A524` 文字、标题…）
        /// 全被算进来：把 TextBox 的前景色突变成 `#010203` 之后，计数仍高达 **9320** ⇒
        /// **判据咬不住**（假绿）。有了这个矩形，runner 只在该控件范围内计数 ⇒ 判据
        /// **既有特异性、又保留"能红"**。
        /// 坐标口径：相对**窗口左上角**（runner 正是按窗口几何从 root 截图里裁的），单位 DIP→像素
        /// 由 runner 侧按帧尺寸换算（这里直接给设备无关坐标的四舍五入值；本工程 DPI=96 ⇒ 1:1）。
        /// </summary>
        protected void ReportBox(string id, FrameworkElement fe)
        {
            try
            {
                var win = Window.GetWindow(fe);
                if (win == null || fe.ActualWidth <= 0 || fe.ActualHeight <= 0) return;
                var p = fe.TransformToAncestor(win).Transform(new Point(0, 0));
                // 【2026-09-13 晚 主控/T1d 派】判"那 44 px 位移发生在 arrange 还是 draw"：
                //   ① `LayoutInformation.GetLayoutSlot(fe)` = **arrange 给的槽**（布局真值）
                //   ② `TransformToAncestor(win)` 在 (0,0) 与 (ActualWidth,0) 的变换 = **视觉/绘制层的两端角点**
                //   槽 ≈21 而墨迹在 −22.6 ⇒ **绘制/视觉层**；槽本身就是 −22.6 ⇒ **arrange**。
                //   另：RTL 元素的 `TransformToAncestor` 报的是**镜像角点**（x≈左+ActualWidth），
                //   所以旧 Δx 判据里含了 +行宽 ⇒ 旧的"① ②"两条按 T1d §10 作废。
                // 上游该类在 `System.Windows.Controls.Primitives`（不是 System.Windows）
                var slot = System.Windows.Controls.Primitives.LayoutInformation.GetLayoutSlot(fe);
                var t1 = fe.TransformToAncestor(win).Transform(new Point(fe.ActualWidth, 0));
                Console.WriteLine($"WFP_BOXID={id} x={(int)Math.Round(p.X)} y={(int)Math.Round(p.Y)} w={(int)Math.Round(fe.ActualWidth)} h={(int)Math.Round(fe.ActualHeight)}"
                    + $" slot={slot.X:F4},{slot.Y:F4},{slot.Width:F4},{slot.Height:F4} t0={p.X:F4},{p.Y:F4} t1={t1.X:F4},{t1.Y:F4} unit=DIP");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"WFP_BOXID={id} rect=FAILED {ex.GetType().Name}: {ex.Message.Split('\n')[0]}");
            }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ① Popup / ContextMenu / ToolTip —— **独立 HWND** 路径（本工程窗口胶水的薄弱处）
    // ─────────────────────────────────────────────────────────────────────────

        }

    // ⑫ **标准 WPF `ComboBox` 的下拉** —— `D-G50` 的判别仪器（波 `#45`）
    // ─────────────────────────────────────────────────────────────────────────
    //   为什么要它：真实第三方应用（仓外 hc demo）的"组合框"页其实映射到 `NativeComboBoxDemo`
    //   ⇒ 被测件是**标准 `ComboBox`**（HandyControl 只通过主题给它套模板）。而 hc 上
    //   * 点击正文区/箭头 *、* 键盘 `Alt+Down`/`F4` * 都开不出下拉，且**没有任何新 X 窗口**。
    //   ⇒ 本块把"标准 ComboBox 在这套移植上到底开不开"变成**仓内可复算**的读数：
    //      · 事件通道：`DropDownOpened/DropDownClosed/SelectionChanged` 各打一行 `EVT …`（**逐行 flush**）
    //      · 像素通道：**下拉项容器**才用测试色（选中框里看不到）⇒ 测试色出现 == 下拉真的开了
    //      · 窗口通道：`popup` 块已证"独立 X 窗口可行"，本块的下拉若开，`new_windows` 应随之变化
    //   ⚠️ runner **不注入点击** ⇒ 本块的点击判据由**外部驱动**（见 `docs/WAVE45-PREREGISTRATION.md` §1）；
    //      仓内一步到位的那一步（给 runner 加点击腿）留给下一波，块先做**载体**。
    // 复刻 HandyControl `ComboBoxTemplate` 里那个"**透明覆盖层**"开关：`Background=Transparent` 的 `Control`
    //   ＋ 覆写 `OnMouseDown` 翻转一个 DP（等价 `hc:ToggleBlock` 的 `ToggleGesture="LeftClick"`）。
    internal sealed class ToggleOverlay : Control
    {
        public static readonly DependencyProperty IsCheckedProperty = DependencyProperty.Register(
            nameof(IsChecked), typeof(bool), typeof(ToggleOverlay),
            new FrameworkPropertyMetadata(false, FrameworkPropertyMetadataOptions.BindsTwoWayByDefault));
        public bool IsChecked { get => (bool)GetValue(IsCheckedProperty); set => SetValue(IsCheckedProperty, value); }

        protected override void OnMouseDown(MouseButtonEventArgs e)
        {
            Console.WriteLine("EVT overlay.MouseDown changedButton=" + e.ChangedButton + " state=" + e.ButtonState);
            Console.Out.Flush();
            SetCurrentValue(IsCheckedProperty, !IsChecked);
            Console.WriteLine("EVT overlay.IsChecked=" + IsChecked);
            Console.Out.Flush();
            base.OnMouseDown(e);
        }
    }

    internal sealed class NativeComboBlock : ProbeBlock
    {
        private ComboBox _combo;
        public override string Name => "nativecombo";
        public override string TestColor => "7C3AED";
        public override bool NeedsLateCheck => true;   // ★ 没有它 `LateVerify()` 根本不会被调用（基类默认 false）

        public override void Build(StackPanel host)
        {
            var card = Card("⑫ 标准 ComboBox 下拉（`D-G50`：hc 的组合框点不开）", B("7C3AED"));
            var body = Body(card);
            body.Children.Add(Title("nativecombo：下拉项容器=测试色（选中框里看不到）⇒ 测试色出现即「下拉开了」"));

            _combo = new ComboBox { Width = 220, Height = 26 };
            for (int i = 0; i < 3; ++i) _combo.Items.Add("native item " + i);
            // 只有**项容器**染色 ⇒ 关着的时候屏上没有测试色
            _combo.ItemContainerStyle = new Style(typeof(ComboBoxItem))
            {
                Setters = { new Setter(Control.BackgroundProperty, B(TestColor)) }
            };
            _combo.DropDownOpened += (_, __) => { Console.WriteLine("EVT nativecombo.DropDownOpened"); Console.Out.Flush(); };
            _combo.DropDownClosed += (_, __) => { Console.WriteLine("EVT nativecombo.DropDownClosed"); Console.Out.Flush(); };
            _combo.SelectionChanged += (_, __) => { Console.WriteLine("EVT nativecombo.SelectionChanged=" + _combo.SelectedIndex); Console.Out.Flush(); };
            body.Children.Add(_combo);

            // 键盘腿也在本块里（hc 上 Alt+Down/F4 同样无效 ⇒ 必须同时测）
            _combo.KeyDown += (_, e) => { Console.WriteLine("EVT nativecombo.KeyDown=" + e.Key); Console.Out.Flush(); };

            // ★ 自报**屏幕坐标**：放在 `LateVerify()` 里 —— 实测本工程里 `_combo.Loaded` **没有触发**
            //   （应用日志里连一行都没有），而 `LateVerify()` 是样本自己 6 s 后**必调**的钩子。
            // ── 复刻 HandyControl `ComboBoxTemplate` 的形态（判 `D-G50` 断在"模板链"还是"样式层"）──
            _replBorder = new Border { Height = 28, Margin = new Thickness(0, 10, 0, 0),
                                       Background = Brushes.White, BorderBrush = B("9CA3AF"), BorderThickness = new Thickness(1) };
            var grid = new Grid();
            grid.Children.Add(_replBorder);
            _overlay = new ToggleOverlay { Background = Brushes.Transparent };          // ★ 透明覆盖层（**要为可命中**）
            grid.Children.Add(_overlay);
            var replCp = new ContentPresenter { Content = "replica content", IsHitTestVisible = false,
                                                HorizontalAlignment = HorizontalAlignment.Left,
                                                VerticalAlignment = VerticalAlignment.Center };   // ★ 压在上面但**不参与命中**
            grid.Children.Add(replCp);
            // ★ 谁吃掉了这一击：四层各挂一个 MouseDown（`#45` 用来把"命中被吞"点名到具体元素）
            grid.AddHandler(UIElement.MouseDownEvent, new MouseButtonEventHandler((_, e) =>
            { Console.WriteLine("EVT hit grid  src=" + (e.OriginalSource?.GetType().Name ?? "?")); Console.Out.Flush(); }), true);
            replCp.AddHandler(UIElement.MouseDownEvent, new MouseButtonEventHandler((_, e) =>
            { Console.WriteLine("EVT hit contentPresenter"); Console.Out.Flush(); }), true);
            _overlay.AddHandler(UIElement.MouseDownEvent, new MouseButtonEventHandler((_, e) =>
            { Console.WriteLine("EVT hit overlay"); Console.Out.Flush(); }), true);
            _replBorder.AddHandler(UIElement.MouseDownEvent, new MouseButtonEventHandler((_, e) =>
            { Console.WriteLine("EVT hit border"); Console.Out.Flush(); }), true);
            _replPopup = new Popup { PlacementTarget = _replBorder, Placement = PlacementMode.Bottom,
                                     AllowsTransparency = true, StaysOpen = true,
                                     Child = new Border { Width = 180, Height = 26, Background = B("0F766E"),
                                                          Child = new TextBlock { Text = "replica popup", FontSize = 10, Foreground = Brushes.White } } };
            _replPopup.SetBinding(Popup.IsOpenProperty,
                new System.Windows.Data.Binding(nameof(ToggleOverlay.IsChecked)) { Source = _overlay, Mode = System.Windows.Data.BindingMode.TwoWay });
            _replPopup.Opened += (_, __) => { Console.WriteLine("EVT replicaPopup.Opened"); Console.Out.Flush(); };
            _replPopup.Closed += (_, __) => { Console.WriteLine("EVT replicaPopup.Closed"); Console.Out.Flush(); };
            grid.Children.Add(_replPopup);
            body.Children.Add(grid);
            _replBorder.Loaded += (_, __) => ReportPos("overlay", _overlay);

            // ── `D-G52` 的三行对照：**透明** / **不透明** / **无背景**（每行各挂命中探针）──
            body.Children.Add(Title("D-G52 对照：透明 / 不透明 / 无背景（点每行看谁收到 MouseDown）"));
            _bgRows = new Border[3];
            string[] kinds = { "transparent", "opaque", "null" };
            for (int i = 0; i < 3; ++i)
            {
                var br = new Border
                {
                    Height = 24, Margin = new Thickness(0, 4, 0, 0),
                    BorderBrush = B("9CA3AF"), BorderThickness = new Thickness(1),
                    Background = i == 0 ? Brushes.Transparent : (i == 1 ? Brushes.White : null),
                    Child = new TextBlock { Text = "bg=" + kinds[i], FontSize = 10, VerticalAlignment = VerticalAlignment.Center }
                };
                string k = kinds[i];
                br.AddHandler(UIElement.MouseDownEvent, new MouseButtonEventHandler((_, __) =>
                { Console.WriteLine("EVT bgprobe " + k + " hit"); Console.Out.Flush(); }), true);
                body.Children.Add(br);
                _bgRows[i] = br;
            }

            host.Children.Add(card);   // ★ 必须挂上去（`#45` 首版漏了这一行 ⇒ ComboBox 从没被排版、w=0 h=0、点击无处可落）

            Ledger.Line(Name, "OK", "标准 ComboBox 已建（点击/键盘由外部驱动：`$HOME/w45-nativecombo.sh`）；判据 = EVT 行 + 测试色像素 + new_windows");
        }
    
        private Border _replBorder; private ToggleOverlay _overlay; private Popup _replPopup;
        private Border[] _bgRows;

        // 坐标自报（三条 API 都不通 ⇒ 逐级向上累加偏移；见 `D-G50` 条目的自伤记录）
        private static void ReportPos(string tag, FrameworkElement fe)
        {
            try
            {
                double ox = 0, oy = 0;
                System.Windows.DependencyObject cur = fe;
                for (int g = 0; g < 64; ++g)
                {
                    var par = System.Windows.Media.VisualTreeHelper.GetParent(cur);
                    if (par == null) break;
                    var cv = cur as System.Windows.Media.Visual; var pv = par as System.Windows.Media.Visual;
                    if (cv == null || pv == null) break;
                    var t = cv.TransformToAncestor(pv).Transform(new Point(0, 0));
                    ox += t.X; oy += t.Y; cur = par;
                }
                Console.WriteLine("POS " + tag + " relx=" + (int)ox + " rely=" + (int)oy
                                  + " w=" + (int)fe.ActualWidth + " h=" + (int)fe.ActualHeight);
                Console.Out.Flush();
            }
            catch (Exception ex) { Console.WriteLine("POS " + tag + " ERR " + ex.GetType().Name); Console.Out.Flush(); }
        }

        // ★ 坐标自报：`LateVerify()` 是样本 6 s 后必调的回调（`Loaded` 在本工程里实测没触发）
        public override void LateVerify()
        {
            try
            {
                // ⚠️ `PointToScreen` 在本移植上抛 `InvalidOperationException`（实测）⇒ 改用**相对窗口**的变换，
                //   再由外部驱动加上窗口在屏幕上的原点。
                // ⚠️ 三条都不通（实测）：`PointToScreen` 抛 `InvalidOperationException`；
                //   `Window.GetWindow(_combo)` 返回 **null**；`TransformToAncestor(MainWindow)` 抛
                //   `InvalidOperationException`（`MainWindow` 不是它的祖先）。⇒ **逐级向上累加偏移**到根，
                //   不依赖"找对那一个祖先"（每步只要求 parent→child 这一对关系成立）。
                double ox = 0, oy = 0;
                System.Windows.DependencyObject cur = _combo;
                for (int guard = 0; guard < 64; ++guard)
                {
                    var par = System.Windows.Media.VisualTreeHelper.GetParent(cur);
                    if (par == null) break;
                    var cv = cur as System.Windows.Media.Visual;
                    var pv = par as System.Windows.Media.Visual;
                    if (cv == null || pv == null) break;
                    var t = cv.TransformToAncestor(pv).Transform(new Point(0, 0));
                    ox += t.X; oy += t.Y;
                    cur = par;
                }
                var win = Window.GetWindow(_combo) ?? Application.Current?.MainWindow;
                var p0 = new Point(ox, oy);
                ReportPos("overlay", _overlay);
                Console.WriteLine("STATE nativecombo IsLoaded=" + _combo.IsLoaded + " IsDropDownOpen=" + _combo.IsDropDownOpen + " IsVisible=" + _combo.IsVisible + " w=" + (int)_combo.ActualWidth); Console.Out.Flush();
                for (int i = 0; i < 3; ++i) ReportPos("bg" + i, _bgRows[i]);
                Console.WriteLine("POS nativecombo relx=" + (int)p0.X + " rely=" + (int)p0.Y
                                  + " w=" + (int)_combo.ActualWidth + " h=" + (int)_combo.ActualHeight
                                  + " winx=" + (int)win.Left + " winy=" + (int)win.Top
                                  + " winw=" + (int)win.ActualWidth + " winh=" + (int)win.ActualHeight);
                Console.Out.Flush();
            }
            catch (Exception ex) { Console.WriteLine("POS nativecombo ERR " + ex.GetType().Name); Console.Out.Flush(); }
        }
    }

    internal sealed class PopupBlock : ProbeBlock
    {
        private Popup _popup; private ContextMenu _menu; private ToolTip _tip;
        public override string Name => "popup";
        public override string TestColor => "E5484D";

        public override void Build(StackPanel host)
        {
            var card = Card("① Popup / ContextMenu / ToolTip（独立窗口路径）", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("popup"));

            var anchor = new Border
            {
                Width = 90, Height = 24,
                Background = B(TestColor),
                Child = new TextBlock { Text = "anchor", FontSize = 10, Foreground = Brushes.White }
            };
            body.Children.Add(anchor);

            // Popup：**独立窗口**；内容用测试色，便于在"另一个窗口"里核对
            _popup = new Popup
            {
                PlacementTarget = anchor,
                Placement = PlacementMode.Bottom,
                StaysOpen = true,
                AllowsTransparency = false,
                Child = new Border { Width = 120, Height = 28, Background = B(TestColor), Child = new TextBlock { Text = "popup", FontSize = 10 } }
            };
            _popup.IsOpen = true;

            _menu = new ContextMenu { PlacementTarget = anchor, Placement = PlacementMode.Bottom };
            _menu.Items.Add(new MenuItem { Header = "menu-item-1" });
            _menu.Items.Add(new MenuItem { Header = "menu-item-2" });
            _menu.IsOpen = true;

            _tip = new ToolTip { PlacementTarget = anchor, Placement = PlacementMode.Right, Content = "tooltip" };
            _tip.IsOpen = true;

            host.Children.Add(card);
        }

        public override void Verify()
        {
            try
            {
                var w = _popup.Child is FrameworkElement fe ? $"{fe.ActualWidth:F0}x{fe.ActualHeight:F0}" : "child?-";
                Ledger.Line(Name, "OK",
                    $"popup.IsOpen={_popup.IsOpen} child={w} menu.IsOpen={_menu.IsOpen} menu.items={_menu.Items.Count} tip.IsOpen={_tip.IsOpen} " +
                    $"[独立窗口：由 runner 用 xwininfo 计数佐证]");
            }
            catch (Exception ex) { Ledger.Line(Name, "FAIL", $"{ex.GetType().Name}: {ex.Message}"); }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ② 动画：Opacity / RenderTransform.X / Width ⇒ 走 MilCmd*Animate 一族
    // ─────────────────────────────────────────────────────────────────────────
    internal sealed class AnimationBlock : ProbeBlock
    {
        private Border _box; private TranslateTransform _tt;
        // 【口径修正（2026-09-12 自查抓到的假红）】"推进百分比"必须拿**动画自己声明的起终值**算，
        //   **不能**拿"BeginAnimation 之前的属性值"当起点：`Border.Opacity` 的默认值就是 **1.0**，
        //   而动画是 `0.0→1.0` ⇒ 旧写法 `(_box.Opacity - 1.0)/(1.0 - 1.0)` = **NaN**，
        //   `Math.Min(NaN, …)` 也是 NaN ⇒ 既不 ≥80% 也不 ≤2% ⇒ 掉进 else ⇒ **误判 FAIL**
        //   （实测：`opacity 1.00→1.00(NaN) … 停在半途`）。下面这三对常量就是判据的唯一真值来源。
        private const double FromOpacity = 0.0, TargetOpacity = 1.0;
        private const double FromX = 0.0, TargetX = 40.0;
        private const double FromWidth = 40.0, TargetWidth = 120.0;
        private double _o0, _x0, _w0;
        public override string Name => "anim";
        public override string TestColor => "F5A524";
        public override bool NeedsLateCheck => true;

        public override void Build(StackPanel host)
        {
            var card = Card("② 动画（Opacity / RenderTransform.X / Width ⇒ MilCmd*Animate）", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("anim"));

            _tt = new TranslateTransform(0, 0);
            _box = new Border
            {
                Width = 40, Height = 22,
                Background = B(TestColor),
                RenderTransform = _tt,
                HorizontalAlignment = HorizontalAlignment.Left,
                Child = new TextBlock { Text = "anim", FontSize = 10 }
            };
            body.Children.Add(_box);

            _o0 = _box.Opacity; _x0 = _tt.X; _w0 = _box.Width;

            var dur = TimeSpan.FromMilliseconds(400);
            // 起终值一律用上面那三对常量 ⇒ "动画参数"和"判据真值"**不可能各写一份而走偏**
            _box.BeginAnimation(UIElement.OpacityProperty, new DoubleAnimation(FromOpacity, TargetOpacity, dur));
            _tt.BeginAnimation(TranslateTransform.XProperty, new DoubleAnimation(FromX, TargetX, dur));
            _box.BeginAnimation(FrameworkElement.WidthProperty, new DoubleAnimation(FromWidth, TargetWidth, dur));

            host.Children.Add(card);
        }

        public override void Verify()
        {
            // 【为什么不在这里下判定】2026-09-12 实测抖动：**同一配置两次跑，`[feat] anim` 一次 OK
            //   一次 INCONCLUSIVE，而且两条 `[feat]` 行在日志里的**顺序正好相反**。机制：延迟核对
            //   （`late_ms=6000`）在"窗口首绘很慢"时**会先于** `Verify` 触发 ⇒ 后写的早采
            //   INCONCLUSIVE 把先写的 OK **覆盖**掉（runner 汇总取最后一条）⇒ **用 INCONCLUSIVE
            //   掩盖了真结果**。现在判定**只由 `LateVerify` 一处给出** ⇒ 与钩子顺序无关。
            //   这里只打一条**非台账**诊断行（`[wfp]` 前缀不进 runner 的 `[feat]` 解析）。
            Console.WriteLine($"[wfp] anim 早采（不作判定）：opacity={_box?.Opacity:F2} xform={_tt?.X:F1} width={_box?.Width:F1}");
        }

        public override void LateVerify()
        {
            try
            {
                double o = _box.Opacity, x = _tt.X, w = _box.Width;
                double po = (o - FromOpacity) / (TargetOpacity - FromOpacity);
                double px = (x - FromX) / (TargetX - FromX);
                double pw = (w - FromWidth) / (TargetWidth - FromWidth);
                string vals = $"opacity {FromOpacity:F2}→{o:F2}({po:P0}) xform {FromX:F1}→{x:F1}({px:P0}) width {FromWidth:F1}→{w:F1}({pw:P0}) 初值快照=({_o0:F2},{_x0:F1},{_w0:F1})";
                // 非有限值（NaN/∞）只可能是**仪器算不出来**（例如属性被外部改成非法值）⇒ INCONCLUSIVE，
                //   不许让它掉进"停在半途"那条 ⇒ 那是**假红**（本文件 2026-09-12 就是这么误报过一次）。
                if (double.IsNaN(po) || double.IsNaN(px) || double.IsNaN(pw) ||
                    double.IsInfinity(po) || double.IsInfinity(px) || double.IsInfinity(pw))
                {
                    Ledger.Line(Name, "INCONCLUSIVE", $"{vals} —— 推进比例算不出有限值（仪器侧问题，不是动画缺陷）");
                    return;
                }
                double minp = Math.Min(po, Math.Min(px, pw));
                double maxp = Math.Max(po, Math.Max(px, pw));
                // 判据用**阈值**，不用"看值变没变"：动画 400ms、延迟核对 6s（15 倍余量）⇒
                //   到点时三条腿**应当已到终值**。因此：
                //     三条都 ≥80% ⇒ OK（时钟推进且动画跑完）
                //     三条都 ≤2%  ⇒ **FAIL**：动画时钟完全没走（值可读 ⇒ 不是仪器读不到）
                //     中间态       ⇒ **FAIL**：400ms 的动画在 6s 后还没走完 = 真缺陷，不用 INCONCLUSIVE 糊
                //   只有"读值本身抛异常"才是仪器问题 ⇒ INCONCLUSIVE。
                if (minp >= 0.80)
                    Ledger.Line(Name, "OK", $"{vals} —— 三条腿都推进到终值 80% 以上（400ms 动画在 6s 延迟核对时已应结束）");
                else if (maxp <= 0.02)
                    Ledger.Line(Name, "FAIL", $"{vals} —— **动画时钟完全没推进**（值可读、延迟窗口是动画时长的 15 倍 ⇒ 不是仪器问题）");
                else
                    Ledger.Line(Name, "FAIL", $"{vals} —— 停在半途（400ms 动画在 6s 后仍未走完 ⇒ 按真缺陷记，不给 INCONCLUSIVE）");
            }
            catch (Exception ex)
            {
                Ledger.Line(Name, "INCONCLUSIVE", $"仪器读不到动画值（这才是 INCONCLUSIVE 的用法）：{ex.GetType().Name}: {ex.Message}");
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ③ OpacityMask（PushOpacityMask）：黑遮罩=全透明、白遮罩=可见 ⇒ **正负双向**像素判据
    // ─────────────────────────────────────────────────────────────────────────
    internal sealed class OpacityMaskBlock : ProbeBlock
    {
        public override string Name => "opacitymask";
        public override string TestColor => "8B5CF6";      // 被黑遮罩盖住 ⇒ 期望**不出现**
        public override string NegativeColor => "22C55E";  // 白遮罩 ⇒ 期望**出现**

        public override void Build(StackPanel host)
        {
            var card = Card("③ OpacityMask（PushOpacityMask）：黑=透明 / 白=可见", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("opacitymask"));

            // ⚠️【样例写法更正（2026-09-11 实测撞到）】**WPF 的 OpacityMask 用的是"alpha 通道"，
            //   不是亮度** ⇒ `SolidColorBrush(Colors.Black)` 的 alpha=255 ⇒ **完全不透明** ⇒ 元素**照常可见**！
            //   我第一版就是这么写的，于是门禁报 "负向色 28644 px（本应不可见）" —— 那是**我的样例 bug**，
            //   在 Windows 上同样会这样（不是移植缺陷）。要"遮住"必须给 **alpha=0** 的刷子。
            var masked = new Border { Width = 90, Height = 22, Background = B(TestColor), HorizontalAlignment = HorizontalAlignment.Left };
            masked.OpacityMask = new SolidColorBrush(Color.FromArgb(0x00, 0x00, 0x00, 0x00));   // alpha=0 ⇒ 应看不见
            body.Children.Add(masked);

            var visible = new Border { Width = 90, Height = 22, Background = B(NegativeColor), HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, 4, 0, 0) };
            visible.OpacityMask = new SolidColorBrush(Color.FromArgb(0xFF, 0xFF, 0xFF, 0xFF));  // alpha=255 ⇒ 应看得见
            body.Children.Add(visible);

            // 第三个：**半透明渐变遮罩**（alpha 0→255）⇒ 同一元素左右两半可见度不同（更强的判据）
            // 第三个元素**用另一个颜色**（#38BDF8）：否则它会让"负向判据"（#8B5CF6 应不可见）失效
            var grad = new Border { Width = 90, Height = 22, Background = B("38BDF8"), HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, 4, 0, 0) };
            var lg = new LinearGradientBrush { StartPoint = new Point(0, 0), EndPoint = new Point(1, 0) };
            lg.GradientStops.Add(new GradientStop(Color.FromArgb(0x00, 0, 0, 0), 0.0));
            lg.GradientStops.Add(new GradientStop(Color.FromArgb(0xFF, 0, 0, 0), 1.0));
            grad.OpacityMask = lg;
            body.Children.Add(grad);

            host.Children.Add(card);
        }

        public override void Verify()
        {
            Ledger.Line(Name, "OK",
                $"alpha=0 遮罩作用于 #{TestColor}（**期望像素≈0**）、alpha=255 遮罩作用于 #{NegativeColor}（**期望像素>0**）" +
                "、alpha 渐变遮罩作用于 #38BDF8（**只作读图证据，不进判据**）；前两项由 runner 做正负双向像素核对");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ④ Effect：DropShadowEffect（已知可画）+ BlurEffect（**未验证**）
    // ─────────────────────────────────────────────────────────────────────────
    internal sealed class EffectBlock : ProbeBlock
    {
        public override string Name => "effects";
        public override string TestColor => "0EA5E9";       // DropShadow
        public string BlurColor { get; } = "EC4899";        // Blur（未验证）
        public override string NegativeColor => BlurColor;

        public override void Build(StackPanel host)
        {
            var card = Card("④ Effect：DropShadow（已知）+ Blur（未验证）", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("effects"));

            var shadow = new Border { Width = 70, Height = 22, Background = B(TestColor), HorizontalAlignment = HorizontalAlignment.Left };
            shadow.Effect = new DropShadowEffect { BlurRadius = 12, ShadowDepth = 4, Opacity = 0.8, Color = Colors.Black };
            body.Children.Add(shadow);

            var blur = new Border { Width = 70, Height = 22, Background = B(BlurColor), HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, 8, 0, 0) };
            blur.Effect = new BlurEffect { Radius = 6 };
            body.Children.Add(blur);

            host.Children.Add(card);
        }

        public override void Verify()
        {
            Ledger.Line(Name, "OK", $"DropShadowEffect #{TestColor} / BlurEffect #{BlurColor} 都已挂上（像素由 runner 核）");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ⑤ TabControl / TreeView / DataGrid（容器生成、模板、虚拟化）
    // ─────────────────────────────────────────────────────────────────────────
    internal sealed class ControlsBlock : ProbeBlock
    {
        private TabControl _tabs; private TreeView _tree; private DataGrid _grid;
        public override string Name => "controls";
        public override string TestColor => "14B8A6";

        public override void Build(StackPanel host)
        {
            var card = Card("⑤ TabControl / TreeView / DataGrid", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("controls"));

            _tabs = new TabControl { Height = 70 };
            for (int i = 0; i < 3; i++)
            {
                var ti = new TabItem { Header = $"tab-{i}" };
                ti.Content = new Border { Background = B(TestColor), Height = 20, Child = new TextBlock { Text = $"tab-{i}-content", FontSize = 10 } };
                _tabs.Items.Add(ti);
            }
            body.Children.Add(_tabs);

            _tree = new TreeView { Height = 80, Margin = new Thickness(0, 6, 0, 0) };
            for (int i = 0; i < 3; i++)
            {
                var node = new TreeViewItem { Header = $"root-{i}", IsExpanded = true };
                node.Items.Add(new TreeViewItem { Header = $"leaf-{i}.0" });
                node.Items.Add(new TreeViewItem { Header = $"leaf-{i}.1" });
                _tree.Items.Add(node);
            }
            body.Children.Add(_tree);

            _grid = new DataGrid { Height = 90, AutoGenerateColumns = false, Margin = new Thickness(0, 6, 0, 0) };
            _grid.Columns.Add(new DataGridTextColumn { Header = "A", Binding = new System.Windows.Data.Binding("A") });
            _grid.Columns.Add(new DataGridTextColumn { Header = "B", Binding = new System.Windows.Data.Binding("B") });
            var rows = new List<object>();
            for (int i = 0; i < 12; i++) rows.Add(new { A = $"a{i}", B = $"b{i}" });
            _grid.ItemsSource = rows;
            body.Children.Add(_grid);

            host.Children.Add(card);
        }

        public override void Verify()
        {
            try
            {
                var tabRealized = _tabs.ItemContainerGenerator.ContainerFromIndex(0) != null;
                var treeRealized = _tree.ItemContainerGenerator.ContainerFromIndex(0) != null;
                Ledger.Line(Name, "OK",
                    $"tabs={_tabs.Items.Count}(容器已生成={tabRealized}) tree={_tree.Items.Count}(容器已生成={treeRealized}) " +
                    $"grid.cols={_grid.Columns.Count} grid.rows={(_grid.ItemsSource as List<object>)?.Count ?? -1}");
            }
            catch (Exception ex) { Ledger.Line(Name, "FAIL", $"{ex.GetType().Name}: {ex.Message}"); }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ⑥ TextBox 编辑态：焦点 / 光标 / 选区 / Ctrl+A / 真输入（输入路径）
    // ─────────────────────────────────────────────────────────────────────────
    internal sealed class TextBoxBlock : ProbeBlock
    {
        private TextBox _tb; private int _changes;
        public override string Name => "textbox-edit";
        public override string TestColor => "F97316";
        public override bool NeedsLateCheck => true;

        public override void Build(StackPanel host)
        {
            var card = Card("⑥ TextBox 编辑态（焦点/光标/选区/输入）", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("textbox-edit"));

            _tb = new TextBox
            {
                Text = "seed-文本", Width = 240, Height = 24,
                Foreground = B(TestColor),
                HorizontalAlignment = HorizontalAlignment.Left
            };
            _tb.TextChanged += (s, e) =>
            {
                _changes++;
                // ㈠ **缺省关**（T1c 2026-09-14 要求）：下面这行要读 `_tb.Text` ⇒ 会把 TextBox 的 deferred 槽
                //   **提前解析成字符串**（值不变、表示形式被改）⇒ 必须门控，守"探针关掉 = 无副作用"这条纪律。
                if (Environment.GetEnvironmentVariable("WFP_POSTWRITE") != "1") return;
                if (_eventLogs < 10)
                {
                    _eventLogs++;
                    Console.WriteLine($"WFP_POSTWRITE-EVENT TextChanged #{_changes} text='{_tb.Text}' len={_tb.Text.Length}");
                }
                else if (_eventLogs == 10)
                {
                    _eventLogs++;   // ㈡ 触顶必须看得见（L12）
                    Console.WriteLine("WFP_POSTWRITE-EVENT 触顶 cap=10 ⇒ 之后不再打（**「没打」≠「没发生」**，L12）");
                }
            };
            StartTextWatch();
            StartPostWriteRead();
            body.Children.Add(_tb);
            host.Children.Add(card);
        }

        // ── 四个优先级的 Dispatcher 自测（主控 2026-09-13 派的"极便宜决定性实验"）──────
        //   背景（上游 `TextEditorTyping.ScheduleInput`，`:1569-1591`）：**插入真正发生在
        //   `DispatcherPriority.Background` 的 DispatcherOperation 里**（`BackgroundInputCallback`）。
        //   实跑 `pop` 的消息号里只见过 `0x8000`/`0x8009`，**从没见过 `0x8004`** ⇒ 假设：
        //   **Background 优先级的操作在这套 Dispatcher/消息泵上从不执行**。
        //   这四格就是判据：Normal/Input 是"应当跑"的对照，Background 是假设的正主，
        //   ContextIdle 更低（只在空闲时跑）⇒ 它若 False **不能**单独当证据（要分开解读）。
        private bool _prioNormal, _prioInput, _prioBackground, _prioContextIdle;
        private bool _dispatcherProbePosted;

        // ── `_tb.Text` 的时间线（判"写入到底有没有到 DP/渲染"，还是"到了又被撤掉"）──────
        //   第 3 批 Q 读数已证：`DoTextInput` 期间文档确实被写成 "A"/"AB"（Q4d/Q3c），
        //   但 6s 后的 `LateVerify` 与**注入后的截图**都还是 'seed-文本' ⇒ 必须知道
        //   **写进容器之后有没有"某一刻"在 `_tb.Text` 上出现过**：
        //     出现过 ⇒ 写入到达了 DP/渲染，随后被**回滚/重建**（往 undo-Rollback 或"容器被
        //              从旧 DP 值重新同步"两条路查）；
        //     从未出现 ⇒ 容器改了但 **容器→DP/渲染的通知链**没通（写入根本没出去）。
        private System.Windows.Threading.DispatcherTimer _watch;
        private int _watchLogs;

        private void StartTextWatch()
        {
            if (_watch != null) return;
            var t0 = DateTime.UtcNow;
            _watch = new System.Windows.Threading.DispatcherTimer(System.Windows.Threading.DispatcherPriority.Background)
            { Interval = TimeSpan.FromMilliseconds(400) };
            _watch.Tick += (s, e) =>
            {
                var ms = (int)(DateTime.UtcNow - t0).TotalMilliseconds;
                if (_watchLogs++ < 18)
                    Console.WriteLine($"WFP_TEXTWATCH t={ms} text='{_tb.Text}' len={_tb.Text.Length} sel={_tb.SelectionStart},{_tb.SelectionLength} changes={_changes} focused={_tb.IsKeyboardFocused}");
                else if (_watch != null) _watch.Stop();
            };
            _watch.Start();
        }

        // ── 写后读数（2026-09-14 主控/T1c 更正口径后的**根因修复**）────────────────────
        // 【为什么必须补】`WFP_TEXTWATCH` 的采样窗是 400ms × 18 ≈ 7.2s，实测**在注入之前就结束了**
        //   （取证：最后一条 `WFP_TEXTWATCH` 在日志 L1412 / t=17021ms，而首个按键 `XEV KeyPress`
        //    在 L1492）；`Verify`（L734）与 `LateVerify`（L599）**也都早于注入** ⇒ 整趟
        //   **没有任何写后读数** ⇒ 那些 `changes=0` 是**无信息**，**既不能读成"陈旧"、也不能读成"回归"**。
        // 【本仪器只做一件事】**只读**轮询 `_tb.Text`（`TextBox.Text` 存的是 `DeferredTextReference`，
        //   字符串是**读时现算**的）⇒ 值一变立刻打；没变则每 ≥2s 打一次心跳（总上限 30 行，不刷屏）。
        //   ⚠️ **只加读数、不改判据**：怎么判仍由 runner/读者按既有口径做。
        private System.Windows.Threading.DispatcherTimer _post;
        private int _postLogs, _eventLogs;
        private string _postLast;

        private void StartPostWriteRead()
        {
            // ㈠ **缺省关**（T1c 2026-09-14 要求）：本仪器每次 tick 都读 `_tb.Text` ⇒ 会把 TextBox 的
            //   `DeferredTextReference` 槽**提前解析成字符串**（**值不变、表示形式被改**）⇒
            //   与"探针关掉 = 无副作用"纪律一致，必须由 `WFP_POSTWRITE=1` 显式打开。
            if (Environment.GetEnvironmentVariable("WFP_POSTWRITE") != "1") return;
            if (_post != null) return;
            var t0 = DateTime.UtcNow;
            var lastBeat = -100000;
            _post = new System.Windows.Threading.DispatcherTimer(System.Windows.Threading.DispatcherPriority.Background)
            { Interval = TimeSpan.FromMilliseconds(300) };
            _post.Tick += (s, e) =>
            {
                if (_postLogs >= 30)
                {
                    _post.Stop();
                    // ㈡ **触顶必须看得见**（L12）：否则"后面没打"会被读成"后面没事发生"。
                    Console.WriteLine($"WFP_POSTWRITE 触顶 cap={_postLogs} ⇒ 之后不再打（**「没打」≠「没发生」**，L12）");
                    return;
                }
                var ms = (int)(DateTime.UtcNow - t0).TotalMilliseconds;
                string snap, text; int len, selS, selL;
                try
                {
                    text = _tb.Text; len = text.Length;
                    selS = _tb.SelectionStart; selL = _tb.SelectionLength;
                    snap = $"{text}|{selS},{selL}|{_changes}";
                }
                catch (Exception ex) { Console.WriteLine($"WFP_POSTWRITE t={ms} 读取异常 {ex.GetType().Name}"); _post.Stop(); return; }
                var changed = snap != _postLast;
                if (changed || ms - lastBeat >= 2000)
                {
                    lastBeat = ms; _postLogs++;
                    Console.WriteLine($"WFP_POSTWRITE t={ms} {(changed ? "变更" : "心跳")} text='{text}' len={len} sel={selS},{selL} changes={_changes}");
                    _postLast = snap;
                }
            };
            _post.Start();
        }

        private void ProbeDispatcherPriorities()        {
            if (_dispatcherProbePosted) return;
            _dispatcherProbePosted = true;
            var d = System.Windows.Threading.Dispatcher.CurrentDispatcher;
            d.BeginInvoke(System.Windows.Threading.DispatcherPriority.Normal,      new Action(() => { _prioNormal = true; }));
            d.BeginInvoke(System.Windows.Threading.DispatcherPriority.Input,       new Action(() => { _prioInput = true; }));
            d.BeginInvoke(System.Windows.Threading.DispatcherPriority.Background,  new Action(() => { _prioBackground = true; }));
            d.BeginInvoke(System.Windows.Threading.DispatcherPriority.ContextIdle,  new Action(() => { _prioContextIdle = true; }));
            Console.WriteLine("WFP_DISPATCH_PROBE=posted normal/input/background/contextidle");
        }

        private string PrioLine() =>
            $"WFP_DISPATCH_PRIO normal={_prioNormal} input={_prioInput} background={_prioBackground} contextidle={_prioContextIdle}";

        public override void Verify()
        {
            try
            {
                _tb.Focus();
                Keyboard.Focus(_tb);
                _tb.SelectAll();
                ProbeDispatcherPriorities();
                ReportBox(Name, _tb);
                Ledger.Line(Name, "OK",
                    $"focus={_tb.IsKeyboardFocused} caret={_tb.CaretIndex} selLen={_tb.SelectionLength} text='{_tb.Text}' changes={_changes} " +
                    "（runner 注入 Ctrl+A/键入后看 LateVerify 的增量）");
            }
            catch (Exception ex) { Ledger.Line(Name, "FAIL", $"{ex.GetType().Name}: {ex.Message}"); }
        }

        public override void LateVerify()
        {
            try
            {
                ReportBox(Name, _tb);
                // 四格机读行（判据在 runner/读者手里；这里**只报事实**）
                Console.WriteLine(PrioLine());
                Ledger.Line(Name, "INCONCLUSIVE",
                    $"late: focus={_tb.IsKeyboardFocused} caret={_tb.CaretIndex} selLen={_tb.SelectionLength} text='{_tb.Text}' changes={_changes} " +
                    $"｜ {PrioLine()}（normal/input=对照，应当 True；background=**假设的正主**；contextidle 更低、只在空闲跑 ⇒ False 不能单独当证据）" +
                    "（changes>0 才说明**输入真的到达**；本行由 runner 判读）");
            }
            catch (Exception ex) { Ledger.Line(Name, "FAIL", $"{ex.GetType().Name}: {ex.Message}"); }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ⑦ ScrollViewer + 虚拟化（滚动时容器回收）
    // ─────────────────────────────────────────────────────────────────────────
    internal sealed class VirtualizeBlock : ProbeBlock
    {
        private const int N = 200;
        private ListBox _list;
        public override string Name => "virtualize";
        public override string TestColor => "64748B";
        public override bool NeedsLateCheck => true;

        public override void Build(StackPanel host)
        {
            var card = Card($"⑦ 虚拟化：ListBox {N} 项 + 滚动", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("virtualize"));

            // 列表项前景 = 测试色 ⇒ 像素侧能判"项真的被渲染"（虚拟化块的像素信号就靠它）
            _list = new ListBox { Height = 90, Width = 260, HorizontalAlignment = HorizontalAlignment.Left, Foreground = B(TestColor) };
            VirtualizingStackPanel.SetIsVirtualizing(_list, true);
            VirtualizingStackPanel.SetVirtualizationMode(_list, VirtualizationMode.Recycling);
            ScrollViewer.SetVerticalScrollBarVisibility(_list, ScrollBarVisibility.Auto);
            var items = new List<string>();
            for (int i = 0; i < N; i++) items.Add($"row-{i:D3}");
            _list.ItemsSource = items;
            body.Children.Add(_list);
            host.Children.Add(card);
        }

        public override void Verify()
        {
            var realized = RealizedCount();
            Ledger.Line(Name, "OK", $"items={N} 已实现容器={realized}（< items 即虚拟化生效；滚动后再看 LateVerify）");
        }

        public override void LateVerify()
        {
            try
            {
                var realized = RealizedCount();
                Ledger.Line(Name, "OK", $"late: items={N} 已实现容器={realized}（滚动后仍应远小于 items）");
            }
            catch (Exception ex) { Ledger.Line(Name, "FAIL", $"{ex.GetType().Name}: {ex.Message}"); }
        }

        private int RealizedCount()
        {
            int n = 0;
            for (int i = 0; i < _list.Items.Count; i++)
                if (_list.ItemContainerGenerator.ContainerFromIndex(i) != null) n++;
            return n;
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ⑧ RenderTransform / LayoutTransform / Clip / BitmapCache
    // ─────────────────────────────────────────────────────────────────────────
    internal sealed class TransformBlock : ProbeBlock
    {
        public override string Name => "transforms";
        public override string TestColor => "EAB308";
        public override string NegativeColor => "94A3B8";   // Clip 用的第二块

        public override void Build(StackPanel host)
        {
            var card = Card("⑧ RenderTransform / LayoutTransform / Clip / BitmapCache", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("transforms"));

            var rt = new Border { Width = 60, Height = 20, Background = B(TestColor), HorizontalAlignment = HorizontalAlignment.Left };
            rt.RenderTransform = new TransformGroup
            {
                Children = { new RotateTransform(12, 30, 10), new ScaleTransform(1.1, 1.1) }
            };
            body.Children.Add(rt);

            var lt = new Border { Width = 60, Height = 20, Background = B(NegativeColor), HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, 8, 0, 0) };
            lt.LayoutTransform = new ScaleTransform(1.2, 1.0);
            body.Children.Add(lt);

            var clip = new Border { Width = 60, Height = 20, Background = B(TestColor), HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, 8, 0, 0) };
            clip.Clip = new EllipseGeometry(new Point(30, 10), 30, 10);
            body.Children.Add(clip);

            var cache = new Border { Width = 60, Height = 20, Background = B(NegativeColor), HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, 8, 0, 0) };
            cache.CacheMode = new BitmapCache(1.0);
            body.Children.Add(cache);

            host.Children.Add(card);
        }

        public override void Verify()
        {
            Ledger.Line(Name, "OK",
                $"RenderTransform=TransformGroup LayoutTransform=ScaleTransform Clip=EllipseGeometry CacheMode=BitmapCache " +
                $"(测试色 #{TestColor} ×2、#{NegativeColor} ×2；像素由 runner 核)");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ⑨ 文本：RTL / 折行 / 省略号（刚修过的文本链，值得再撞一次）
    // ─────────────────────────────────────────────────────────────────────────

    // ─────────────────────────────────────────────────────────────────────────
    // ⑩ **纯 RTL**（判"双反演还是正确"）—— 主控 2026-09-13 派单
    //   【为什么要单独一块】T1d 的只读评估（`build/MilBridge/T1d-bidi-scoping.md`）指出：
    //   我们的 shim **整段一个 HarfBuzz buffer、方向靠 `guess_segment_properties` 猜**、
    //   没有 `set_direction`，`GlyphRun.BidiLevel` **恒 0**；而实测 `'שלום עולם'` 出来的
    //   `glyphIds` 还原字符是**逻辑序的整体反序** ⇒ **我们的字形序已经是"HB 视觉序"**。
    //   于是剩下两种可能，**只能用读数定**：
    //     甲：宿主（`Line.cs:79 _mirror=(FlowDirection==RTL)` → `InvertAxes` 反演矩阵）
    //         **还会整体镜像一次** ⇒ 两次反转叠加 ⇒ **纯 RTL 也是错的**（现有缺陷）；
    //     乙：宿主不再镜像 ⇒ 纯 RTL **恰好正确**。
    //   本块放**纯 RTL**字符串（无拉丁混排），每行**独有高饱和前景色**（便于"限框 + 混合线"判据），
    //   并自报 FlowDirection/尺寸/文本；`runner` 侧配 `--app-env=WPF_LINUX_HBLINE_TRACE=1`
    //   取站点 A/D 的 run 顺序与 `runOrigins` 做机读对照。
    //   ⚠️ **不改动**上面 ⑨ 的既有读数（本块是**追加**的第 10 块）。
    // ─────────────────────────────────────────────────────────────────────────
    internal sealed class PureRtlBlock : ProbeBlock
    {
        private System.Windows.Controls.TextBlock _he, _ar, _heNum, _arNum, _heLtr;
        public override string Name => "text-rtl-pure";
        public override string TestColor => "FF2D95";          // 希伯来（纯）：品红
        public override string NegativeColor => "00E5FF";     // 阿拉伯（纯）：青
        // 另外两行用各自颜色：`ADFF2F`（希伯来+数字）、`C084FC`（阿拉伯+标点/数字）

        private static System.Windows.Controls.TextBlock Rtl(string text, string hex) => new System.Windows.Controls.TextBlock
        {
            Text = text,
            FlowDirection = FlowDirection.RightToLeft,
            FontSize = 14,
            Foreground = B(hex),
            HorizontalAlignment = HorizontalAlignment.Left,
            Margin = new Thickness(0, 0, 0, 4)
        };

        public override void Build(StackPanel host)
        {
            var card = Card("⑩ 纯 RTL（希伯来/阿拉伯，含数字与标点）⇒ 判双反演还是正确", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("text-rtl-pure"));

            _he = Rtl("שלום עולם", TestColor);                 // 纯希伯来
            _ar = Rtl("مرحبا بالعالم", NegativeColor);         // 纯阿拉伯
            // 【甲/乙 的**机器判据**】同一字符串再画一遍、但 `FlowDirection=LeftToRight`：
            //   若宿主对 RTL **又镜像了一次**（甲），则"shim 已给的视觉序"会被再翻回去
            //   ⇒ **RTL 那一行与 LTR 那一行逐列轮廓相同**（两次反转=反转两次=原样）；
            //   若宿主**不再镜像**（乙），RTL 行应是 LTR 行的**水平镜像**。
            //   判法：取两行各自颜色的**精确像素列轮廓**，比 `profile_RTL` 与 `profile_LTR`、
            //   以及 `profile_RTL` 与 `reverse(profile_LTR)`，看谁相等 ⇒ **不依赖人眼认字形**。
            _heLtr = new System.Windows.Controls.TextBlock
            {
                Text = "שלום עולם", FontSize = 14, Foreground = B("00FF7F"),
                FlowDirection = FlowDirection.LeftToRight,
                HorizontalAlignment = HorizontalAlignment.Left, Margin = new Thickness(0, 0, 0, 4)
            };
            _heNum = Rtl("שלום 123 עולם", "ADFF2F");           // 希伯来 + 数字
            _arNum = Rtl("مرحبا، 123", "C084FC");              // 阿拉伯 + 标点 + 数字
            foreach (var t in new[] { _he, _heLtr, _ar, _heNum, _arNum }) body.Children.Add(t);
            host.Children.Add(card);
        }

        public override void Verify()
        {
            Ledger.Line(Name, "OK",
                $"he='{_he.Text}' heW={_he.ActualWidth:F1} heH={_he.ActualHeight:F1} dir={_he.FlowDirection} | " +
                $"heLTR(w={_heLtr.ActualWidth:F1})='{_heLtr.Text}' | ar='{_ar.Text}' arW={_ar.ActualWidth:F1} | heNum='{_heNum.Text}' | arNum='{_arNum.Text}' " +
                "（**方向正确性不由本行判**：机读看 HBLINE 站点 A/D 的 run 顺序与 runOrigins；视觉由 runner 原生分辨率读图）");
            ReportBox(Name, _he);   // 供 runner 做"限框 + 混合线"像素判据（块的**主**框）
            // 【2026-09-13 加】RTL 基线读数要**逐行**的"布局框 vs 实际墨迹区间"：
            //   只报一行时无法判断"+74 px 布局↔绘制不一致"是不是**所有行共有**（=坐标基问题）
            //   还是**只有 RTL 行**有（=镜像症状）。这里把 5 行全报出来，id 用 `<块名>/<行标签>`。
            ReportBox(Name + "/he", _he);        // 纯希伯来（RTL）
            ReportBox(Name + "/heLTR", _heLtr);  // **同串 LTR 对照**
            ReportBox(Name + "/ar", _ar);        // 纯阿拉伯（RTL）
            ReportBox(Name + "/heNum", _heNum);  // 希伯来+数字
            ReportBox(Name + "/arNum", _arNum);  // 阿拉伯+标点+数字
        }

        public override void LateVerify()
        {
            try
            {
                Ledger.Line(Name, "INCONCLUSIVE",
                    $"late: he=(w={_he.ActualWidth:F1},h={_he.ActualHeight:F1}) ar=(w={_ar.ActualWidth:F1},h={_ar.ActualHeight:F1}) " +
                    $"heNum=(w={_heNum.ActualWidth:F1}) arNum=(w={_arNum.ActualWidth:F1}) （尺寸只说明「排出了行」，方向真值见 HBLINE/读图）");
            }
            catch (Exception ex) { Ledger.Line(Name, "FAIL", $"{ex.GetType().Name}: {ex.Message}"); }
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // ⑪ **最小复现**：改容器而不改 `Text` DP（**完全不注入 X 输入**）
    //   主控 2026-09-13 晚判定：DP 引擎里的"三个探针互相矛盾"继续钻性价比低，
    //   先把**现象本身**做成不依赖输入注入的可重复实验。
    //   序列（照主控给的）：构造 TextBox → `Text="seed-文本"` → 入树并布局 → 等一个 Dispatcher 回合
    //     → 记 t1/c1 → `SelectAll()` + `SelectedText="A"`（**正是 `DoTextInput` 那两个调用**）
    //     → 立刻记 t2/c2 → 再等一个 Background 回合记 t3/c3 → 再等 500ms 记 t4/c4。
    //   `sel=`/`line0=` 是**容器侧**读数（走 TextEditor/TextSelection，不读 `Text` DP）⇒
    //   用来证明"容器变了而 `Text` 没变"。
    // ─────────────────────────────────────────────────────────────────────────
    internal sealed class TextDpMinBlock : ProbeBlock
    {
        private System.Windows.Controls.TextBox _tb;
        private int _changes;
        public override string Name => "text-dp-min";
        public override string TestColor => "FF7A00";
        public override bool NeedsLateCheck => false;

        public override void Build(StackPanel host)
        {
            var card = Card("⑪ 最小复现：`SelectedText=\"A\"` 改容器，`Text` DP 跟不跟（无 X 注入）", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("text-dp-min"));
            _tb = new System.Windows.Controls.TextBox
            {
                Text = "seed-文本", Width = 240, Height = 24,
                Foreground = B(TestColor), HorizontalAlignment = HorizontalAlignment.Left
            };
            _tb.TextChanged += (s, e) => _changes++;
            body.Children.Add(_tb);
            host.Children.Add(card);
        }

        private string Snap(string tag)
        {
            string sel, line;
            try { sel = _tb.SelectedText; } catch (Exception ex) { sel = "ERR:" + ex.GetType().Name; }
            try { line = _tb.LineCount > 0 ? _tb.GetLineText(0) : ""; } catch (Exception ex) { line = "ERR:" + ex.GetType().Name; }
            line = line.Replace("\r", "\\r").Replace("\n", "\\n");
            return $"{tag}='{_tb.Text}' c{tag[tag.Length - 1]}={_changes} sel='{sel}' line0='{line}'";
        }

        public override void Verify()
        {
            var d = System.Windows.Threading.Dispatcher.CurrentDispatcher;
            d.BeginInvoke(System.Windows.Threading.DispatcherPriority.Loaded, new Action(() =>
            {
                Console.WriteLine("WFP_TEXTDP " + Snap("t1"));
                try { _tb.SelectAll(); _tb.SelectedText = "A"; }
                catch (Exception ex) { Console.WriteLine("WFP_TEXTDP edit=EX " + ex.GetType().Name + ": " + ex.Message.Split('\n')[0]); }
                Console.WriteLine("WFP_TEXTDP " + Snap("t2"));
                d.BeginInvoke(System.Windows.Threading.DispatcherPriority.Background, new Action(() =>
                {
                    Console.WriteLine("WFP_TEXTDP " + Snap("t3"));
                    var t = new System.Windows.Threading.DispatcherTimer(System.Windows.Threading.DispatcherPriority.Background)
                    { Interval = TimeSpan.FromMilliseconds(500) };
                    t.Tick += (s2, e2) =>
                    {
                        t.Stop();
                        string row = Snap("t4");
                        Console.WriteLine("WFP_TEXTDP " + row);
                        Ledger.Line(Name, "OK", "WFP_TEXTDP " + row + "（t1..t4 全原文；sel/line0 是容器侧读数）");
                    };
                    t.Start();
                }));
            }));
        }

        public override void LateVerify() { }
    }

    internal sealed class TextFeaturesBlock : ProbeBlock   // ← 不能叫 TextBlock：会遮蔽 WPF 的 TextBlock
    {
        private System.Windows.Controls.TextBlock _rtl, _wrap, _trim;
        public override string Name => "text-rtl";
        public override string TestColor => "A855F7";

        public override void Build(StackPanel host)
        {
            var card = Card("⑨ 文本：FlowDirection=RTL / 折行 / 省略号", B("3C4E6B"));
            var body = Body(card);
            body.Children.Add(Title("text-rtl"));

            _rtl = new System.Windows.Controls.TextBlock
            {
                Text = "مرحبا بالعالم — RTL שלום עולם",
                FlowDirection = FlowDirection.RightToLeft,
                FontSize = 14, Foreground = B(TestColor),
                Margin = new Thickness(0, 0, 0, 4)
            };
            body.Children.Add(_rtl);

            _wrap = new System.Windows.Controls.TextBlock
            {
                Text = "折行验证：这一段中文与 English mixed 混排应该被自动折成多行，行与行必须**各自独立**（不叠在同一基线）。",
                TextWrapping = TextWrapping.Wrap, Width = 300,
                FontSize = 13, Foreground = B(TestColor), TextAlignment = TextAlignment.Left
            };
            body.Children.Add(_wrap);

            _trim = new System.Windows.Controls.TextBlock
            {
                Text = "省略号验证：这一行很长很长而且不折行，右边界处应当被裁掉并显示省略号 trimmed with an ellipsis.",
                TextWrapping = TextWrapping.NoWrap, TextTrimming = TextTrimming.CharacterEllipsis, Width = 300,
                FontSize = 13, Foreground = B(TestColor), Margin = new Thickness(0, 4, 0, 0)
            };
            body.Children.Add(_trim);

            host.Children.Add(card);
        }

        public override void Verify()
        {
            try
            {
                Ledger.Line(Name, "OK",
                    $"rtl.FlowDirection={_rtl.FlowDirection} rtl.h={_rtl.ActualHeight:F1} wrap.wrap={_wrap.TextWrapping} wrap.h={_wrap.ActualHeight:F1} " +
                    $"trim.trimming={_trim.TextTrimming} trim.h={_trim.ActualHeight:F1} " +
                    "（wrap.h ≈ 单行高度的 N 倍才说明**行推进正常**；像素/读图由 runner 核）");
            }
            catch (Exception ex) { Ledger.Line(Name, "FAIL", $"{ex.GetType().Name}: {ex.Message}"); }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ⑬ **"点击某控件有没有反应"** —— 仓内可复算判据（波 `#47`）
    // ─────────────────────────────────────────────────────────────────────────
    //   为什么要它：用户报告"仓外 hc 示例程序里点击没反应（含输入框与列表项）"，而 hc 是**第三方样式**
    //   ＋**仓外**件 ⇒ 它不能当判据（`D-G50`/`D-G52`/`D-G54` 三次自伤都是这个原因）。本块把三类点击
    //   做成**仓内**载体，每类自报三通道读数：
    //     · **语义通道**：`SelectionChanged` / `GotFocus` / `TextChanged` / `DropDownOpened|Closed`
    //       ⇒ `EVT lst.selection=<i>` / `EVT tb.focus` / `EVT tb.text=<len>` / `EVT combo.selection=<i>`；
    //     · **原始通道**：被点元素上挂 `MouseLeftButtonDown/Up`（`handledEventsToo: true`）并**逐条打印
    //       `e.ButtonState`** —— 这一格正是 `D-G49`（`GetKeyState` 恒 0 ⇒ 上游 `ButtonBase` 里
    //       `if (e.ButtonState == Pressed)` 判假 ⇒ **只拿焦点、从不激活**）的判定字段
    //       ⇒ "事件没到"与"到了但激活判假"一次分清；
    //     · **坐标通道**：`LateVerify()` 里**逐级累加 `TransformToAncestor` 到根**自报 `POS`
    //       （`PointToScreen` 抛 `InvalidOperationException`、`Window.GetWindow` 返回 `null`、
    //        `TransformToAncestor(MainWindow)` 抛 —— 三条都在 `D-G50` 里实测过，不许再用）。
    //   判据（**先写死**，见 `build/MilBridge/W47B-report.md`）：
    //     点 ListBox 第 k 项 ⇒ `lst.selection=k`；点 TextBox ⇒ `tb.focus` 且键入后 `tb.text` 增长；
    //     点 ComboBox ⇒ `combo.opened`，再点弹窗第 2 项 ⇒ `combo.selection=1` 且随后 `combo.closed`。
    //   ⚠️ **本块的点击腿不在样本里**（样本不自己合成点击）：由外部 `xdotool` 驱动
    //      （`$HOME/w47b-click.sh`，真实节奏 `mousedown`→停 150 ms→`mouseup`）。
    internal sealed class ClickProbeBlock : ProbeBlock
    {
        private ListBox _lst;
        private TextBox _tb;
        private ComboBox _combo;

        public override string Name => "clickprobe";
        public override string TestColor => "22D3EE";
        public override bool NeedsLateCheck => true;

        private static void Ev(string s) { Console.WriteLine("EVT " + s); Console.Out.Flush(); }
        private static void Raw(string s) { Console.WriteLine(s); Console.Out.Flush(); }

        /// <summary>逐级向上累加偏移（相对**该可视树的根**）。返回 null = 半途遇到非 `Visual` 的父（不猜）。</summary>
        private static Point? OffsetToRoot(System.Windows.DependencyObject d)
        {
            double ox = 0, oy = 0;
            var cur = d;
            for (int g = 0; g < 64; ++g)
            {
                var par = System.Windows.Media.VisualTreeHelper.GetParent(cur);
                if (par == null) break;
                var cv = cur as System.Windows.Media.Visual;
                var pv = par as System.Windows.Media.Visual;
                if (cv == null || pv == null) return null;
                var t = cv.TransformToAncestor(pv).Transform(new Point(0, 0));
                ox += t.X; oy += t.Y;
                cur = par;
            }
            return new Point(ox, oy);
        }

        private static void Pos(string tag, FrameworkElement fe)
        {
            try
            {
                var o = OffsetToRoot(fe);
                if (o == null) { Raw("POS " + tag + " ERR nonvisual-parent"); return; }
                Raw($"POS {tag} relx={(int)o.Value.X} rely={(int)o.Value.Y} w={(int)fe.ActualWidth} h={(int)fe.ActualHeight} loaded={fe.IsLoaded}");
            }
            catch (Exception ex) { Raw("POS " + tag + " ERR " + ex.GetType().Name); }
        }

        public override void Build(StackPanel host)
        {
            var card = Card("⑬ 点击必须有反应：ListBox 项 / TextBox / ComboBox 下拉项", B(TestColor));
            var body = Body(card);
            body.Children.Add(Title("clickprobe：语义 EVT ＋ 原始命中 EVT（含 ButtonState）＋ POS 自报坐标"));

            // ── ① ListBox（3 项）：点第 k 项必须让 SelectedIndex 从 -1 → k ────────────────
            _lst = new ListBox { Width = 260, Height = 78, Margin = new Thickness(0, 0, 0, 6) };
            for (int i = 0; i < 3; ++i) _lst.Items.Add("list item " + i);
            _lst.SelectionChanged += (_, __) => Ev("lst.selection=" + _lst.SelectedIndex);
            _lst.GotFocus += (_, __) => Ev("lst.focus");
            _lst.AddHandler(UIElement.MouseLeftButtonDownEvent, new MouseButtonEventHandler((_, e) =>
                Ev($"lst.down src={e.OriginalSource?.GetType().Name ?? "?"} state={e.ButtonState} clicks={e.ClickCount}")), true);
            _lst.AddHandler(UIElement.MouseLeftButtonUpEvent, new MouseButtonEventHandler((_, e) =>
                Ev($"lst.up src={e.OriginalSource?.GetType().Name ?? "?"} state={e.ButtonState}")), true);
            body.Children.Add(_lst);

            // ── ② TextBox：点它必须 GotFocus；键入必须进文本 ─────────────────────────────
            _tb = new TextBox { Width = 260, Height = 26, Margin = new Thickness(0, 0, 0, 6) };
            _tb.GotFocus += (_, __) => Ev("tb.focus");
            _tb.GotKeyboardFocus += (_, __) => Ev("tb.kbdgotfocus");
            _tb.TextChanged += (_, __) => Ev($"tb.text={_tb.Text.Length} text='{_tb.Text.Replace("\r", " ").Replace("\n", " ")}'");
            _tb.AddHandler(UIElement.MouseLeftButtonDownEvent, new MouseButtonEventHandler((_, e) =>
                Ev($"tb.down src={e.OriginalSource?.GetType().Name ?? "?"} state={e.ButtonState}")), true);
            _tb.AddHandler(UIElement.MouseLeftButtonUpEvent, new MouseButtonEventHandler((_, e) =>
                Ev($"tb.up state={e.ButtonState}")), true);
            body.Children.Add(_tb);

            // ── ③ 标准 ComboBox（3 项）：点开下拉 → 点弹窗里第 2 项 ─────────────────────
            //   项容器染**测试色** 22D3EE（关着时屏上不该有它）⇒ 外部驱动可另做**像素判据**：
            //   测试色出现 == 下拉列表真的画出来了（`D-G53` 那一族"WPF 说开着、屏幕上没有"）。
            _combo = new ComboBox { Width = 260, Height = 26, Margin = new Thickness(0, 0, 0, 6) };
            for (int i = 0; i < 3; ++i) _combo.Items.Add("combo item " + i);
            _combo.ItemContainerStyle = new Style(typeof(ComboBoxItem))
            {
                Setters =
                {
                    new Setter(FrameworkElement.HeightProperty, 24.0),
                    new Setter(Control.BackgroundProperty, B(TestColor))
                }
            };
            _combo.GotFocus += (_, __) => Ev("combo.focus");
            _combo.DropDownOpened += (_, __) => { Ev("combo.opened"); ReportPopupItems(); };
            // 【`W90A` 加强 · `TASK-0208`：`DropDownClosed` 处**直读** `Mouse.Captured`】
            //   为什么必须补这一条（`build/MilBridge/W88A-report.md` §3.4 的读数空洞）：
            //     `R-GATE` 的 `c06`（`D-G55` 机器指纹）原先**只**从**主窗口卡片**的 `MouseMove`
            //     （`:1220-1227` 那条 `EVT move … captured=`）取数。而"点弹窗项"这条腿（`L8`）的
            //     2px 挪动**正确地**落在**弹窗窗口**上 ⇒ 修好之后主窗口卡片**一条 move 都读不到**
            //     ⇒ `grep '^EVT move ' | tail -1` 取到的是**点击之前**那条（那时下拉正开着、
            //     `ComboBox` 持有捕获**本来是合法的**）⇒ 判据只好判红。**这一格红的是"读不到"，不是"读到了错的值"。**
            //   本行按**同一时刻**的 `Mouse.Captured` 直读 ⇒ 那一格从"读不到"变成"读得对"。
            //   ⚠️ **不许**把 `captured=` 直接缀到 `combo.closed` 那一行上：`c05` 与 `c06` 的豁免计数
            //      都用 `^EVT combo\.closed[[:space:]]*$` **锚定整行** ⇒ 缀上去会把它们打红（本件实测过）。
            //   ⚠️ 新行**不许**以 `EVT lst.` / `EVT tb.` / `EVT combo.` 开头：`c07`/`c08` 用
            //      `^EVT (lst|tb|combo)\.` 数"控件级 EVT"⇒ 那会把反极性格的判据面污染。
            _combo.DropDownClosed += (_, __) =>
            {
                Ev("combo.closed");
                Ev("capture at=combo.closed captured=" + (Mouse.Captured?.GetType().Name ?? "null"));
            };
            _combo.SelectionChanged += (_, __) => Ev("combo.selection=" + _combo.SelectedIndex);
            _combo.AddHandler(UIElement.MouseLeftButtonDownEvent, new MouseButtonEventHandler((_, e) =>
                Ev($"combo.down src={e.OriginalSource?.GetType().Name ?? "?"} state={e.ButtonState}")), true);
            _combo.AddHandler(UIElement.MouseLeftButtonUpEvent, new MouseButtonEventHandler((_, e) =>
                Ev($"combo.up state={e.ButtonState}")), true);
            body.Children.Add(_combo);

            // 卡片级兜底命中探针：**任何**落在本卡里的左键按下都打一行（区分"整块收不到点击"与"某控件收不到"）
            card.AddHandler(UIElement.MouseLeftButtonDownEvent, new MouseButtonEventHandler((_, e) =>
                Ev($"card.down src={e.OriginalSource?.GetType().Name ?? "?"} state={e.ButtonState}")), true);

            // ── 坐标诚实性仪器（波 `#47` W47B 实测"自报坐标 vs 真实命中"用）──────────────
            //   ① 鼠标移动时把 **WPF 侧的客户区坐标** 打出来（`e.GetPosition(null)` = 相对可视树根）
            //      ⇒ 外部驱动给的是**屏幕**坐标，这个读数把"屏幕 → 客户区"的映射变成可复算（有偏移/缩放会立刻现形）；
            //   ② `LateVerify()` 里用 `VisualTreeHelper.HitTest(根, 客户区点)` 打一条**机内命中梯子**
            //      ⇒ 与"X 点击实际落在谁身上"对照：两者不一致 = 输入命中路径与机内命中测试不一致。
            //   两条都是**有界**打印（不刷屏、不用 `grep` 猜）。
            _rootVisual = rootForHitTest(card);
            card.MouseMove += (_, e) =>
            {
                if (_moveLines >= 300) return;
                _moveLines++;
                var r = e.GetPosition(null);        // 相对可视树根 = 客户区坐标
                // 【判据】`Mouse.DirectlyOver` = **输入系统认为**指针下的元素（命中缓存的产物）；
                //         `HitTest` = **当场**算的视觉命中 ⇒ 两者不一致 = "输入命中缓存/路径"与布局脱节
                string over = "-", fresh = "-";
                try { over = Mouse.DirectlyOver?.GetType().Name ?? "null"; } catch { over = "ERR"; }
                try { if (_rootVisual != null) fresh = System.Windows.Media.VisualTreeHelper.HitTest(_rootVisual, r)?.VisualHit?.GetType().Name ?? "null"; } catch { fresh = "ERR"; }
                Raw($"EVT move root={(int)r.X},{(int)r.Y} src={e.OriginalSource?.GetType().Name ?? "?"} directlyover={over} freshhit={fresh} captured={(Mouse.Captured?.GetType().Name ?? "null")}");
            };
            card.AddHandler(UIElement.MouseLeftButtonDownEvent, new MouseButtonEventHandler((_, e) =>
            {
                var r = e.GetPosition(null);
                Ev($"card.pos root={(int)r.X},{(int)r.Y}");
            }), true);

            host.Children.Add(card);   // ★ 必须挂上去（`D-G50` 首版漏了这行 ⇒ 控件 w=0 h=0、点击无处可落）
        }

        private static System.Windows.Media.Visual _rootVisual;
        private int _moveLines;

        private static System.Windows.Media.Visual rootForHitTest(System.Windows.DependencyObject d)
        {
            var cur = d;
            for (int g = 0; g < 64; ++g)
            {
                var p = System.Windows.Media.VisualTreeHelper.GetParent(cur);
                if (p == null) break;
                cur = p;
            }
            return cur as System.Windows.Media.Visual;
        }

        /// <summary>下拉打开后报**项容器**坐标（相对弹窗根 ⇒ 加弹窗 X 窗口原点即可点）。</summary>
        private void ReportPopupItems()
        {
            _combo.Dispatcher.BeginInvoke(DispatcherPriority.Background, new Action(() =>
            {
                try
                {
                    for (int i = 0; i < _combo.Items.Count; ++i)
                    {
                        var ci = _combo.ItemContainerGenerator.ContainerFromIndex(i) as FrameworkElement;
                        if (ci == null) { Raw("POS comboitem" + i + " ERR null-container"); continue; }
                        Pos("comboitem" + i, ci);
                    }
                }
                catch (Exception ex) { Raw("POS comboitem ERR " + ex.GetType().Name); }
            }));
        }

        /// <summary>布局矩形（`ActualWidth/Height`）与**实际渲染/命中范围**（`GetDescendantBounds`）是否一致。</summary>
        private static void ReportBounds(string tag, FrameworkElement fe)
        {
            try
            {
                var b = System.Windows.Media.VisualTreeHelper.GetDescendantBounds(fe);
                Raw($"POS bounds {tag} actual={(int)fe.ActualWidth}x{(int)fe.ActualHeight} render={(int)fe.RenderSize.Width}x{(int)fe.RenderSize.Height} "
                    + $"descendant=({b.X:F1},{b.Y:F1},{b.Width:F1},{b.Height:F1}) clip={(fe.Clip == null ? "null" : fe.Clip.ToString())}");
            }
            catch (Exception ex) { Raw("POS bounds " + tag + " ERR " + ex.GetType().Name); }
        }

        public override void LateVerify()
        {
            try
            {
                Pos("lst", _lst);
                Pos("tb", _tb);
                Pos("combo", _combo);
                for (int i = 0; i < _lst.Items.Count; ++i)
                {
                    var li = _lst.ItemContainerGenerator.ContainerFromIndex(i) as FrameworkElement;
                    if (li != null) Pos("lstitem" + i, li);
                }
                var win = Application.Current?.MainWindow;
                Raw("STATE clickprobe lst.sel=" + _lst.SelectedIndex + " tb.len=" + _tb.Text.Length
                    + " combo.open=" + _combo.IsDropDownOpen
                    + " kbd=" + (Keyboard.FocusedElement?.GetType().Name ?? "null")
                    + " win=" + (win == null ? "null" : (int)win.Left + "," + (int)win.Top + "," + (int)win.ActualWidth + "x" + (int)win.ActualHeight));
                // ── 机内命中梯子（客户区坐标；与外部 X 点击的实际落点对照）──────────────────
                if (_rootVisual != null)
                {
                    foreach (var xcol in new[] { 200, 294 })
                    {
                        for (int yy = 30; yy <= 230; yy += 6)
                        {
                            var h = System.Windows.Media.VisualTreeHelper.HitTest(_rootVisual, new Point(xcol, yy));
                            Raw($"POS hittest x={xcol} y={yy} → {(h?.VisualHit?.GetType().Name ?? "null")}");
                        }
                    }
                }
                // ── "布局矩形 vs 实际渲染/命中范围"（`#47` W47B：命中落错元素的判据）────────
                ReportBounds("lst", _lst);
                ReportBounds("tb", _tb);
                ReportBounds("combo", _combo);
                // ⚠️ 本块的**点击判据不在这里**（样本不自己合成点击）⇒ 如实记 INCONCLUSIVE，
                //   不许用"载体建好了"冒充"点击可用"（那正是 `D-G50` 假绿的同族）。
                Ledger.Line(Name, "INCONCLUSIVE",
                    $"载体已建并自报坐标 lst={_lst.ActualWidth}x{_lst.ActualHeight} tb={_tb.ActualWidth}x{_tb.ActualHeight} "
                    + $"combo={_combo.ActualWidth}x{_combo.ActualHeight}；**点击判据由外部真实点击驱动**"
                    + "（`$HOME/w47b-click.sh`，读 `EVT lst.selection=|tb.focus|tb.text=|combo.*` 行）⇒ 本条不作'点击可用'的结论");
            }
            catch (Exception ex) { Raw("POS clickprobe ERR " + ex.GetType().Name); }
        }
    }
}

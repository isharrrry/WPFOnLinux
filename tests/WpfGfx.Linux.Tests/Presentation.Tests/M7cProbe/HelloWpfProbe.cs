// WPF-on-Linux · M7c Phase 2 · HelloWpf 运行期探针（**诊断用，默认不参与编译**）
//
// 由 samples/HelloWpf/HelloWpf.csproj 在 `-p:WpfLinuxHelloProbe=true` 时用
// <Compile Include=... Link=...> 链进 HelloWpf 程序集。放在测试目录里而不是
// samples/HelloWpf 下，是为了**不改动样板的任何既有源文件**（样板本身是验收对象，
// 探针只提供观测、不改变行为）。
//
// ── 它回答的两个问题（外部观测区分不了，但修法完全不同）────────────────────
//   (R1) `HwndSource.RootVisual` 从未被赋值 ⇒ 可视树根本没挂上 → 上游问题；
//   (R2) 可视树挂上了，但 WPF 的 render pass 从未被调度 ⇒ 树没被序列化成 MIL 命令。
//   实测背景：窗口 640x400 已 map、标题正确、消息齐全，但
//     xwd 截屏纯白 + MIL 台账 DrawnCommands=0 + 视觉树 {子=0 内容=无}。
//
// ── 探针用到的都是 **public API**，不碰任何 internal ────────────────────────
//   · PresentationSource.FromVisual(window) as HwndSource → `.RootVisual` 直接回答 (R1)
//   · Window.ContentRendered / Application.Startup / Window.Loaded → 生命周期到没到
//   · CompositionTarget.Rendering → **每一帧渲染**都会触发；它不响 = render pass 没跑 (R2)
//   · VisualTreeHelper.GetChildrenCount / ActualWidth → 布局到底有没有跑
//
// 输出走 stderr，与 runner 的 MIL / Win32 台账同一条流（`$LOG`），便于对时。

using System;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Controls;   // ControlTemplate / AdornerDecorator / ContentPresenter
using System.Windows.Interop;
using System.Windows.Media;
using System.Windows.Threading;

namespace HelloWpf.M7cProbe
{
    internal static class HelloWpfProbe
    {
        private static int _frames;
        private static int _ticks;
        private static bool _hooked;

        private static void Say(string s)
        {
            try
            {
                Console.Error.WriteLine("[probe] " + s);
                Console.Error.Flush();
            }
            catch { /* 探针永不抛 */ }
        }

        /// <summary>
        /// 在 HelloWpf 程序集加载时启动。基线信息立刻打；与 Dispatcher/Application
        /// 相关的挂钩交给一个后台线程去等（不在主线程的模块初始化期碰 Dispatcher，
        /// 避免为"诊断"引入启动顺序上的副作用）。
        /// </summary>
        [ModuleInitializer]
        internal static void Install()
        {
            Say($"启动：UserInteractive={Environment.UserInteractive} " +
                $"OS={Environment.OSVersion.Platform} 运行时={Environment.Version}");
            Say($"AppContext 开关 ShouldRenderEvenWhenNoDisplayDevicesAreAvailable=" +
                $"{AppContext.TryGetSwitch("Switch.System.Windows.Media.ShouldRenderEvenWhenNoDisplayDevicesAreAvailable", out bool b) && b}");

            var t = new System.Threading.Thread(WaitForApp) { IsBackground = true, Name = "M7cProbe" };
            t.Start();
        }

        private static void WaitForApp()
        {
            for (int i = 0; i < 600; i++)          // 最多等 60s
            {
                Application app = Application.Current;
                if (app != null)
                {
                    try
                    {
                        app.Dispatcher.BeginInvoke(DispatcherPriority.Send, new Action(() => HookOnUiThread(app)));
                    }
                    catch (Exception ex) { Say("挂钩失败：" + ex.GetType().Name + ": " + ex.Message); }
                    return;
                }
                System.Threading.Thread.Sleep(100);
            }
            Say("60s 内没等到 Application.Current —— 应用可能没起来");
        }

        private static void HookOnUiThread(Application app)
        {
            if (_hooked) return;
            _hooked = true;

            // (R2) 每帧渲染都会触发这里。不响 = render pass 从未跑过。
            CompositionTarget.Rendering += (s, e) =>
            {
                _frames++;
                if (_frames <= 3 || _frames % 30 == 0)
                    Say($"CompositionTarget.Rendering 第 {_frames} 帧");
            };

            app.Startup += (s, e) => Say("Application.Startup（Application 起来了）");

            // 【为什么在这里就调用】`Window.Show()` 会在**首次布局**里进 TextBlock.MeasureOverride，
            // 而布局比 1s 的 Snapshot 早得多（实测：崩在第一个 render pass）。
            // 这些诊断只依赖类型系统、不依赖窗口，所以提前到挂钩这一刻打，保证一定看得见。
            ClassifyProbeOnce();
            FastPathProbeOnce();

            // ★ 关掉最后一个假设缺口：**真实那个 TextBlock 自己的 Typeface**。
            //   上面 ④ 用的是 `SystemFonts.MessageFontFamily` 现造的 Typeface；
            //   而崩溃点用的是窗口里那个 TextBlock 的 Typeface。两者若不同
            //   （例如它解析成了 NullFont —— `CheckFastPathNominalGlyphs` 开头就是
            //    `if (CachedTypeface.NullFont) return false;`），闸门 ④ 的"True"就毫无意义。
            //   窗口在 StartupUri 之后才建，所以在 10ms 的 Send 级定时器里等它出现
            //   ——必须赶在**首次布局**之前（布局一跑就崩）。
            // 【为什么用"Send 级自排队"而不是定时器】
            //   实测 10ms 定时器**跑不赢**首次布局：窗口建好 → Show() → 首次布局里
            //   TextBlock 一测量就崩，全程几毫秒。而布局是**渲染 pass**（DispatcherPriority.Render=7）
            //   里跑的，Send=10 比它高 ⇒ 在 Send 级反复自排队就一定**先于**首次布局执行。
            //   `Application.MainWindow` 在窗口构造时就已赋值（DoStartup 在泵启动前完成）。
            ScheduleRealTextBlockProbe(0);

            // 每秒一次的基线快照：布局到没到、根视觉挂没挂、MainWindow 是谁。
            var timer = new DispatcherTimer(DispatcherPriority.Background)
            {
                Interval = TimeSpan.FromSeconds(1),
            };
            timer.Tick += (s, e) => Snapshot(++_ticks);
            timer.Start();
        }

        // ------------------------------------------------------------------
        //  对照实验（WPF_LINUX_HELLO_TEMPLATE_PROBE=1）—— **诊断，不是修法**
        // ------------------------------------------------------------------
        // 【它证明什么】实测已确认「窗口白」的根因是 `Window.Template == null`：
        //   本工程的 PresentationFramework 声明了
        //     [assembly: ThemeInfo(ExternalAssembly, None)]      (OtherAssemblyAttrs.cs:52)
        //   即控件样式**只在外部主题程序集**里，而 `Window` 的 ControlTemplate
        //   （唯一能把 Content 变成可视子元素的东西）**只**存在于主题字典
        //   （Themes/*/Themes/*.xaml 里 `<Style x:Key="{x:Type Window}">`）。
        //   UxThemeWrapper 在"无活动主题"时把主题名解析成 `classic` ⇒ WPF 会去找
        //   `PresentationFramework.classic`；该程序集在本工程里**根本没被构建**
        //   ⇒ 主题字典为 null ⇒ 所有控件的 Template 都是 null ⇒ 可视树恒空
        //   ⇒ 渲染 pass 以 ~88 帧/秒空转、DrawnCommands=0、截屏纯白。
        //
        //   **真正的修法**是构建并部署主题程序集（交接单见 docs/U2-M7c-report.md）。
        //   本对照实验只是"把主题本该提供的那一个模板手工补上"，用来**证伪/证实**
        //   "除了这个模板，链路上再没有别的拦路虎"：补上之后如果像素真的出来了，
        //   就说明布局→渲染→Skia 后端→XPutImage→X server 全程可用，剩下的唯一缺口
        //   就是那个主题程序集。
        //
        //   因此它**默认关闭**，且默认的 runner 验收路径不会打开它 —— 打开的运行
        //   在报告里一律标注为"对照实验"，不当成验收证据。
        private static readonly bool _templateProbe =
            Environment.GetEnvironmentVariable("WPF_LINUX_HELLO_TEMPLATE_PROBE") == "1";
        private static bool _templateProbeDone;

        private static void MaybeInjectTemplate(Window w)
        {
            if (!_templateProbe || _templateProbeDone) return;
            if (w == null || w.Template != null) return;
            _templateProbeDone = true;
            try
            {
                // 与主题字典里 Window 的模板同构：
                //   <ControlTemplate TargetType="{x:Type Window}">
                //     <AdornerDecorator><ContentPresenter/></AdornerDecorator>
                //   </ControlTemplate>
                // 用 XamlReader 而不是 FrameworkElementFactory：前者走的就是
                // 主题字典加载时那条**真**路径（BAML 之外的另一半 XAML 管线）。
                string xaml =
                    "<ControlTemplate xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation' " +
                    "xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml' " +
                    "TargetType='{x:Type Window}'>" +
                    "<AdornerDecorator><ContentPresenter/></AdornerDecorator>" +
                    "</ControlTemplate>";
                var t = (ControlTemplate)System.Windows.Markup.XamlReader.Parse(xaml);
                w.Template = t;
                w.ApplyTemplate();
                Say("对照实验：已补上 Window 的 ControlTemplate（等价于主题字典里那一个）");
            }
            catch (Exception ex)
            {
                Say($"对照实验失败：{ex.GetType().Name}: {ex.Message}");
            }
        }

        private static void Snapshot(int n)
        {
            try
            {
                Window w = Application.Current?.MainWindow;
                MaybeInjectTemplate(w);
                ClassifyProbeOnce();
                string win = w == null ? "无 MainWindow" : $"MainWindow=「{w.Title}」";
                if (w != null)
                {
                    win += $" IsLoaded={w.IsLoaded} Actual={w.ActualWidth:0}x{w.ActualHeight:0}" +
                           $" 可视子元素={VisualTreeHelper.GetChildrenCount(w)}" +
                           $" Content={(w.Content == null ? "null" : w.Content.GetType().Name)}" +
                           // ★ 模板是"内容能不能出现在可视树上"的唯一通道：
                           //   Window 是 ContentControl，它的 Content 靠**控件模板**里的
                           //   ContentPresenter 才成为可视子元素。模板为 null ⇒ 可视树恒为空
                           //   ⇒ 渲染 pass 每帧空转、截屏纯白（M7c Phase 2 实测就是这个）。
                           $" Template={(w.Template == null ? "**null**" : "有")}" +
                           $" Style={(w.Style == null ? "null" : "有")}";
                    if (w.Content is DependencyObject d)
                        win += $" 内容子元素={VisualTreeHelper.GetChildrenCount(d)}";
                }

                // ★ (R1) 的判据：RootVisual 是不是挂上了
                //   ⚠️ 这里要分两层看，M7c 实测证明它们是**两回事**：
                //     · HwndSource.RootVisual       —— HwndSource 自己的字段
                //     · HwndSource.CompositionTarget.RootVisual —— **HwndTarget** 的字段
                //   渲染走的是后者（CompositionTarget.Render → if (_rootVisual != null)）。
                //   前者有值、后者为 null 的窗口会**每帧都"渲染"却什么都不画**。
                string root = "无 PresentationSource";
                if (w != null && PresentationSource.FromVisual(w) is HwndSource src)
                {
                    root = $"HwndSource.RootVisual=" +
                           (src.RootVisual == null ? "**null**" : src.RootVisual.GetType().Name);
                    CompositionTarget ct = src.CompositionTarget;
                    root += $"；HwndTarget(=CompositionTarget).RootVisual=" +
                            (ct == null ? "**CompositionTarget 为 null**"
                                        : (ct.RootVisual == null ? "**null**（渲染走的是它 → 每帧空转）"
                                                                 : $"{ct.RootVisual.GetType().Name} 子元素={VisualTreeHelper.GetChildrenCount(ct.RootVisual)}"));
                    root += $"；IsDisposed={src.IsDisposed}";
                }

                Say($"快照#{n}：{win}；{root}；渲染帧数={_frames}");
            }
            catch (Exception ex)
            {
                Say($"快照#{n} 失败：{ex.GetType().Name}: {ex.Message}");
            }
        }

        // ==================================================================
        //  #U 验证：`MILGetClassificationTables` 交出去的表到底对不对
        // ==================================================================
        // 【为什么值得这么验】"没抛异常"只能证明**函数被调到了**，证明不了**数据对**。
        //   分类表是"错得很安静"的那类东西：类值填错不会有异常，只会让文本测量
        //   走错分支（该整形的没整形 / 断行位置不对 / 组合标记当基字符）。
        //   所以这里做**三层**验证，每层都能独立失败：
        //     ① 布局层：托管 `Marshal.SizeOf/OffsetOf` vs 原生 `WpfLinuxWin32_AbiLayout`
        //        （结构错位的话下面两层都会读到垃圾，所以先验它）；
        //     ② 读法层：对 40 个码点，**原生自带的查表函数**与**托管
        //        `Classification.GetUnicodeClassUTF16/GetUnicodeClass`** 逐个对拍
        //        —— 这一层验的是"两级表 + 小整数压缩"的约定两边一致；
        //     ③ 语义层：抽查一批有代表性的字符（Latin/数字/空格/CJK/阿拉伯/组合标记/
        //        ZWJ/方向控制符），断言它们的 Script/ItemClass/Flags/BiDi 落在预期值上。
        private static bool _classifyProbeDone;
        private static Type attrType;
        private static bool _realTbDone;

        private static void ClassifyProbeOnce()
        {
            if (_classifyProbeDone) return;
            _classifyProbeDone = true;
            try { ClassifyProbe(); }
            catch (Exception ex) { Say($"#U 验证异常：{ex.GetType().Name}: {ex.Message}"); }
        }

        private static void ClassifyProbe()
        {
            // ---- 原生侧：直接加载 app-local 的 libwpfwin32.so，取两个访问器 ----
            string so = System.IO.Path.Combine(AppContext.BaseDirectory, "libwpfwin32.so");
            if (!System.Runtime.InteropServices.NativeLibrary.TryLoad(so, out IntPtr h))
            {
                Say($"#U 验证跳过：加载不到 {so}");
                return;
            }
            var nativeClassOf = (ClassOfFn)Marshal.GetDelegateForFunctionPointer(
                NativeLibrary.GetExport(h, "WpfLinuxWin32_UnicodeClassOf"), typeof(ClassOfFn));
            var selfCheck = (VoidFn)Marshal.GetDelegateForFunctionPointer(
                NativeLibrary.GetExport(h, "WpfLinuxWin32_ClassificationSelfCheck"), typeof(VoidFn));

            Say($"#U 原生自检 WpfLinuxWin32_ClassificationSelfCheck() = {selfCheck()}");

            // ---- 托管侧：反射拿 internal 的 MS.Internal.Classification ----
            Assembly pc = typeof(Visual).Assembly;                    // PresentationCore
            Type cls = pc.GetType("MS.Internal.Classification", throwOnError: false);
            if (cls == null) { Say("#U 验证失败：PresentationCore 里找不到 MS.Internal.Classification"); return; }

            // ① 布局对拍（原生 offset 由 WpfLinuxWin32_AbiLayout 交出来）
            Type raw = cls.GetNestedType("RawClassificationTables", BindingFlags.NonPublic | BindingFlags.Public);
            Type attr = pc.GetType("MS.Internal.CharacterAttribute", throwOnError: false)
                        ?? cls.GetNestedType("CharacterAttribute", BindingFlags.NonPublic | BindingFlags.Public);
            attrType = attr;
            Say($"#U 布局：RawClassificationTables={Marshal.SizeOf(raw)}(期望 72) " +
                $"UnicodeClasses@{Marshal.OffsetOf(raw, "UnicodeClasses")} " +
                $"CharAttributes@{Marshal.OffsetOf(raw, "CharacterAttributes")} " +
                $"Mirroring@{Marshal.OffsetOf(raw, "Mirroring")} " +
                $"CombiningMarks@{Marshal.OffsetOf(raw, "CombiningMarksClassification")}；" +
                $"CharacterAttribute={Marshal.SizeOf(attr)}(期望 8 Pack=1) " +
                $"Script@{Marshal.OffsetOf(attr, "Script")} Flags@{Marshal.OffsetOf(attr, "Flags")} " +
                $"LineBreak@{Marshal.OffsetOf(attr, "LineBreak")}");

            // ② 逐码点对拍：原生查表 vs 托管查表
            MethodInfo mUtf16 = cls.GetMethod("GetUnicodeClassUTF16",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            MethodInfo mScalar = cls.GetMethod("GetUnicodeClass",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            // ⚠️ `CharAttributeOf` 是 **internal static**（Classification.cs:408），
            //    不带 NonPublic 会拿到 null ⇒ 调用点 NRE（第一次跑就是这么炸的）。
            MethodInfo mAttrOf = cls.GetMethod("CharAttributeOf",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            if (mAttrOf == null) { Say("#U 验证失败：找不到 Classification.CharAttributeOf"); return; }
            int[] cps = { 0x0041, 0x005A, 0x0061, 0x0030, 0x0039, 0x0020, 0x0009, 0x000A, 0x000D,
                          0x0023, 0x0028, 0x0029, 0x002E, 0x00E9, 0x0100, 0x0301, 0x05D0, 0x0627,
                          0x0660, 0x200C, 0x200D, 0x200E, 0x2028, 0x2029, 0x3000, 0x3042, 0x4E2D,
                          0xAC00, 0xFF21, 0x1F600, 0x20AC, 0x00A0, 0x2014, 0x201C, 0x0E01, 0x0905,
                          0x0B95, 0x0C95, 0x0D15, 0x10FFFF };
            int mismatch = 0;
            foreach (int cp in cps)
            {
                int native = nativeClassOf((uint)cp);
                object managed = cp <= 0xFFFF
                    ? mUtf16.Invoke(null, new object[] { (char)cp })
                    : mScalar.Invoke(null, new object[] { cp });
                // 补充平面用标量重载；BMP 两个重载必须给出同一个答案 —— 这里顺带验了这点
                int managedScalar = (short)mScalar.Invoke(null, new object[] { cp });
                if ((short)managed != native || managedScalar != native)
                {
                    mismatch++;
                    if (mismatch <= 5)
                        Say($"#U ✗ 码点 U+{cp:X4}：原生={native} 托管UTF16={(short)managed} 托管标量={managedScalar}");
                }
            }
            Say($"#U 读法对拍：{cps.Length} 个码点，不一致 {mismatch} 个（0 = 两级表/小整数压缩约定两边一致）");

            // ③ 语义抽查
            (int cp, string what, int script, int item, int flagMask, int bidi)[] expect =
            {
                (0x0041, "A",            0x1F /*Latin*/, 0x5 /*Strong*/, 0x10 /*FastText*/, 0 /*Left*/),
                (0x0030, "0",            0x3D /*Digit*/, 0x0 /*Digit*/,   0x100 /*Digit*/,   3 /*EuropeanNumber*/),
                (0x0020, "空格",          0x00 /*Default*/,0x6 /*Weak*/,    0x80 /*Space*/,   18 /*WhiteSpace*/),
                (0x4E2D, "CJK 中",        0x0A /*CJK*/,   0x5 /*Strong*/,  0x20 /*Ideo*/,     0 /*Left*/),
                (0x0627, "阿拉伯 ا",      0x01 /*Arabic*/, 0x5 /*Strong*/,  0x3 /*Complex|RTL*/, 4 /*ArabicLetter*/),
                (0x0301, "组合尖音符",     0x00 /*Default*/,0x7 /*SimpleMark*/, 0x0,           8 /*NonSpacingMark*/),
                (0x200D, "ZWJ",          0x3E /*Control*/,0xA /*Joiner*/,  0x0,              9 /*BoundaryNeutral*/),
                (0x200E, "LRM",          0x3E /*Control*/,0x9 /*Control*/, 0x8 /*FormatAnchor*/, 0 /*Left*/),
                (0x2029, "段落分隔",       0x00,           0x6,             0x200 /*ParaBreak*/, 11 /*ParagraphSeparator*/),
                // `#` 的 Bidi_Class 是 **ET（EuropeanTerminator=7）**，不是 OtherNeutral ——
                // 这条最初写错的是**测试期望**，数据是对的（UD 里 '#' 就是 ET）。
                // 留着这个订正痕迹：它说明这层抽查不是"自己验自己"。
                (0x0023, "#",            0x00,           0xB /*NumberSign*/, 0x0,            7 /*ET*/),
            };
            int bad = 0;
            foreach (var e in expect)
            {
                short k = (short)mUtf16.Invoke(null, new object[] { (char)e.cp });
                object a = mAttrOf.Invoke(null, new object[] { (int)k });
                // 字段是 **internal**（UnicodeClasses.cs:176-184）⇒ 必须带 NonPublic，
                // 否则 GetField 返回 null（第一次跑就是这么 NRE 的）。
                int script = (byte)F("Script", a);
                int item = (byte)F("ItemClass", a);
                int flags = (ushort)F("Flags", a);
                int bidi = (byte)F("BiDi", a);
                bool ok = script == e.script && item == e.item
                          && (flags & e.flagMask) == e.flagMask && bidi == e.bidi;
                if (!ok) bad++;
                Say($"#U {(ok ? "✓" : "✗")} U+{e.cp:X4} {e.what,-10} 类={k,3} " +
                    $"Script={script}(期望{e.script}) Item={item}(期望{e.item}) " +
                    $"Flags=0x{flags:X}(需含0x{e.flagMask:X}) BiDi={bidi}(期望{e.bidi})");
            }
            Say($"#U 语义抽查：{expect.Length} 项，不符 {bad} 项");
        }

        // ==================================================================
        //  闸门诊断：fast path 到底是哪一道闸门挡住的（主控裁定 A 之后的第一件事）
        // ==================================================================
        // `Typeface.CheckFastPathNominalGlyphs` 尾部（Typeface.cs:520-562）的判定链：
        //     ushort charFastTextCheck = FastText | Ideo;        // 初值
        //     循环里 charFastTextCheck &= CharAttributeOf(class).Flags;   // ★ 逐字符按位与
        //     if ((charFastTextCheck & FastText) != 0) {
        //         if ((typography & (FastTextTypographyAvailable | FastTextMajorLanguageLocalizedFormAvailable)) != 0)
        //             return false;                              // ← 闸门 2a
        //         ...
        //         return true;                                   // ★ happy path
        //     } else if ((charFastTextCheck & Ideo) != 0) { ... }
        //     else return ((typography & Available) == 0);        // ← 位被清光时的兜底
        // 所以"闸门 1"= **Flags 里 FastText/Ideo 位被某个字符清掉**（这里是本工程的数据），
        // "闸门 2"= 字体报出来的 TypographyAvailabilities（那是 T2 的 provider）。
        // 这一段把三者一次打全：①逐字符 class+Flags ②按位与的最终值 ③typography 原始值。
        private static bool _fastPathProbeDone;

        private static void FastPathProbeOnce()
        {
            if (_fastPathProbeDone) return;
            _fastPathProbeDone = true;
            try { FastPathProbe(); }
            catch (Exception ex) { Say($"闸门诊断异常：{ex.GetType().Name}: {ex.Message}"); }
        }

        private static void FastPathProbe()
        {
            const ushort FastText = 0x10, Ideo = 0x20;

            Assembly pc = typeof(Visual).Assembly;
            Type cls = pc.GetType("MS.Internal.Classification", throwOnError: false);
            Type attr = pc.GetType("MS.Internal.CharacterAttribute", throwOnError: false);
            if (cls == null || attr == null) { Say("闸门诊断跳过：找不到 Classification/CharacterAttribute"); return; }
            attrType = attr;
            MethodInfo mCls = cls.GetMethod("GetUnicodeClassUTF16",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
            MethodInfo mOf = cls.GetMethod("CharAttributeOf",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);

            // ---- ① 逐字符 class + Flags -------------------------------------
            string text = "Hello WPF";
            ushort acc = FastText | Ideo;              // 与上游初值一致
            var sb = new System.Text.StringBuilder();
            foreach (char c in text)
            {
                short k = (short)mCls.Invoke(null, new object[] { c });
                object a = mOf.Invoke(null, new object[] { (int)k });
                ushort flags = (ushort)F("Flags", a);
                acc &= flags;
                sb.Append($"  '{c}' U+{(int)c:X4} 类={k,3} Flags=0x{flags:X3}；");
            }
            Say("闸门① 逐字符（Hello WPF）：");
            Say(sb.ToString());

            // ---- ② charFastTextCheck 的最终值 -------------------------------
            // 注意 CS8361：插补串里不能直接写含 `:` 的条件表达式，所以先算好再插。
            string branch = (acc & FastText) != 0 ? "FastText 分支"
                          : (acc & Ideo) != 0 ? "Ideo 分支"
                          : "else 兜底分支（要 typography==0 才 true）";
            Say($"闸门② charFastTextCheck(按位与后) = 0x{acc:X2}：" +
                $"FastText位={(acc & FastText) != 0} Ideo位={(acc & Ideo) != 0} ⇒ 走上游 {branch}");

            // ---- ③ 字体报的 TypographyAvailabilities ------------------------
            // 「用的哪一份字体」——把宿主环境变量与实际生效的字族一起打出来。
            // 这是与 runner 回显（路径/sha256）**互相印证**的那一半：runner 证明传了，
            // 这里证明**真的生效到了托管栈**（SystemFonts 走的是 shim 的 SystemParametersInfo）。
            Say($"字体环境：WPF_LINUX_UI_FONT=" +
                $"{Environment.GetEnvironmentVariable("WPF_LINUX_UI_FONT") ?? "<未设>"}" +
                $" WPF_LINUX_FONT_DIR={Environment.GetEnvironmentVariable("WPF_LINUX_FONT_DIR") ?? "<未设>"}");
            try
            {
                Say($"SystemFonts：MessageFontFamily={SystemFonts.MessageFontFamily?.Source ?? "<null>"}" +
                    $" MessageFontSize={SystemFonts.MessageFontSize} MessageFontWeight={SystemFonts.MessageFontWeight}");
            }
            catch (Exception ex) { Say($"SystemFonts 读取失败：{ex.GetType().Name}"); }

            // ---- ④ 直接问上游同一个函数：fast path 到底给不给过 -------------------
            // `Typeface.CheckFastPathNominalGlyphs` 是 **internal** ⇒ 反射调用。
            // 参数照 `SimpleTextLine.CreateSimpleTextRun`（SimpleTextLine.cs:1665-1683）逐项对齐：
            //   widthMax = IdealToReal(widthLeft) 在"不限宽"时是 double.MaxValue，
            //   keepAWord=true、numberSubstitution=false、scalingFactor=1.0、isSideways=false。
            // 返回值 + stringLengthFit 是**决定性**的：false 说明还有别的东西挡着
            // （glyph==0 / 首字符 complex / typography），true 说明上游会走 SimpleTextLine。
            MethodInfo mFast = typeof(Typeface).GetMethod("CheckFastPathNominalGlyphs",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            string probeText = "Hello WPF on Linux";
            foreach (var (label, tf) in new (string, Typeface)[]
                     {
                         ("MessageFontFamily/Normal", new Typeface(SystemFonts.MessageFontFamily, FontStyles.Normal, FontWeights.Normal, FontStretches.Normal)),
                         ("MessageFontFamily/Bold",   new Typeface(SystemFonts.MessageFontFamily, FontStyles.Normal, FontWeights.Bold,   FontStretches.Normal)),
                     })
            {
                if (mFast == null) { Say("闸门④ 跳过：拿不到 CheckFastPathNominalGlyphs"); break; }
                bool hasGt = tf.TryGetGlyphTypeface(out GlyphTypeface gt);
                string glyphs = "<无字面>";
                if (hasGt)
                {
                    var map = gt.CharacterToGlyphMap;
                    var gib = new System.Text.StringBuilder();
                    int missing = 0;
                    foreach (char c in probeText)
                    {
                        ushort gid = map.TryGetValue(c, out ushort v) ? v : (ushort)0;
                        if (gid == 0) missing++;
                        gib.Append($"'{(c == ' ' ? '␠' : c)}'→{gid} ");
                    }
                    // `GlyphTypeface.HasCharacter` 是 internal ⇒ 走 CharacterToGlyphMap（public）判空格
                    bool spaceOk = map.TryGetValue(' ', out ushort sg) && sg != 0;
                    glyphs = $"空格有字形={spaceOk} 缺字形字符数={missing}/{probeText.Length}：{gib}";
                }
                object[] args =
                {
                    new System.Windows.Media.TextFormatting.CharacterBufferRange(probeText.ToCharArray(), 0, probeText.Length),
                    12.0,                     // emSize（MessageFontSize）
                    1.0f,                     // pixelsPerDip
                    1.0,                      // scalingFactor
                    double.MaxValue,          // widthMax（不限宽）
                    true,                     // keepAWord
                    false,                    // numberSubstitution
                    System.Globalization.CultureInfo.InvariantCulture,
                    TextFormattingMode.Ideal,
                    false,                    // isSideways
                    false,                    // breakOnTabs
                    0,                        // out int stringLengthFit
                };
                object ret = mFast.Invoke(tf, args);
                Say($"闸门④ {label}：CheckFastPathNominalGlyphs(\"{probeText}\") = {ret}，" +
                    $"stringLengthFit={args[11]}；字面：{(hasGt ? "有" : "无")}；{glyphs}");
            }

            var faces = new (string label, Typeface tf)[]
            {
                ("MessageFontFamily/Normal", new Typeface(SystemFonts.MessageFontFamily, FontStyles.Normal, FontWeights.Normal, FontStretches.Normal)),
                ("MessageFontFamily/Bold",   new Typeface(SystemFonts.MessageFontFamily, FontStyles.Normal, FontWeights.Bold,   FontStretches.Normal)),
                ("DejaVu Sans/Normal",       new Typeface(new FontFamily("DejaVu Sans"), FontStyles.Normal, FontWeights.Normal, FontStretches.Normal)),
            };
            PropertyInfo pLayout = typeof(GlyphTypeface).GetProperty("FontFaceLayoutInfo",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            foreach (var (label, tf) in faces)
            {
                if (!tf.TryGetGlyphTypeface(out GlyphTypeface gt))
                {
                    Say($"闸门③ {label}：TryGetGlyphTypeface 失败（拿不到字体面）");
                    continue;
                }
                object layout = pLayout?.GetValue(gt);
                object tav = layout?.GetType().GetProperty("TypographyAvailabilities",
                    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic)?.GetValue(layout);
                int v = tav == null ? -1 : Convert.ToInt32(tav);
                string bits = v < 0 ? "（读不到）"
                    : $"Available={(v & 1) != 0} Ideo={(v & 2) != 0} FastText={(v & 4) != 0} " +
                      $"FastTextMajorLangLoca={(v & 8) != 0} FastTextExtraLangLoca={(v & 16) != 0}";
                Say($"闸门③ {label}：TypographyAvailabilities={v}（{bits}）");
            }
        }

        /// <summary>找到窗口逻辑树里第一个 TextBlock，用它**自己的**属性问同一个问题。</summary>
        private static void RealTextBlockProbe(Window w)
        {
            TextBlock tb = FindTextBlock(w, 0);
            if (tb == null) { Say("真实 TextBlock 探针：窗口逻辑树里没找到 TextBlock"); return; }

            var tf = new Typeface(tb.FontFamily, tb.FontStyle, tb.FontWeight, tb.FontStretch);
            bool hasGt = tf.TryGetGlyphTypeface(out GlyphTypeface gt);
            Say($"真实 TextBlock：Text=\"{tb.Text}\" FontFamily={tb.FontFamily} FontSize={tb.FontSize} " +
                $"FontWeight={tb.FontWeight} TextWrapping={tb.TextWrapping} LineHeight={tb.LineHeight} " +
                $"Typeface.TryGetGlyphTypeface={(hasGt ? "有" : "**无（NullFont？）**")}");

            MethodInfo mFast = typeof(Typeface).GetMethod("CheckFastPathNominalGlyphs",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (mFast == null) return;
            string text = tb.Text ?? "";
            object[] args =
            {
                new System.Windows.Media.TextFormatting.CharacterBufferRange(text.ToCharArray(), 0, text.Length),
                tb.FontSize, 1.0f, 1.0, double.MaxValue, true, false,
                System.Globalization.CultureInfo.InvariantCulture,
                TextFormattingMode.Ideal, false, false, 0,
            };
            object ret = mFast.Invoke(tf, args);
            Say($"真实 TextBlock：CheckFastPathNominalGlyphs(它自己的字符串/字号/字重) = {ret}，" +
                $"stringLengthFit={args[11]}");
            // 真实调用里 emSize/widthMax 都由 pixelsPerDip 参与换算（`textSource.PixelsPerDip`
            // = 宿主的 Dpi 缩放）。我上面用的是 1.0 —— 把真实的也打出来，免得又留一个假设缺口。
            try
            {
                DpiScale dpi = VisualTreeHelper.GetDpi(tb);
                DpiScale dpiW = VisualTreeHelper.GetDpi(w);
                string t2d = "<无 HwndSource>";
                if (PresentationSource.FromVisual(w) is HwndSource hs && hs.CompositionTarget != null)
                    t2d = hs.CompositionTarget.TransformToDevice.ToString().Replace("\n", " ");
                Say($"DPI：TextBlock GetDpi=({dpi.DpiScaleX},{dpi.DpiScaleY}) PixelsPerDip={dpi.PixelsPerDip}；" +
                    $"Window GetDpi=({dpiW.DpiScaleX},{dpiW.DpiScaleY})；HwndSource.TransformToDevice={t2d}");
            }
            catch (Exception ex) { Say($"DPI 读取失败：{ex.GetType().Name}"); }

            // 顺带把"它这一串字符的 Flags 按位与"也算一遍（用真实字符串，不是 "Hello WPF"）
            Assembly pc = typeof(Visual).Assembly;
            Type cls = pc.GetType("MS.Internal.Classification", throwOnError: false);
            Type attr = pc.GetType("MS.Internal.CharacterAttribute", throwOnError: false);
            if (cls != null && attr != null)
            {
                attrType = attr;
                MethodInfo mCls = cls.GetMethod("GetUnicodeClassUTF16",
                    BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
                MethodInfo mOf = cls.GetMethod("CharAttributeOf",
                    BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
                ushort acc = 0x10 | 0x20;
                var detail = new System.Text.StringBuilder();
                foreach (char c in text)
                {
                    short k = (short)mCls.Invoke(null, new object[] { c });
                    ushort fl = (ushort)F("Flags", mOf.Invoke(null, new object[] { (int)k }));
                    acc &= fl;
                    detail.Append($"'{(c == ' ' ? '␠' : c)}'=0x{fl:X} ");
                }
                Say($"真实 TextBlock：charFastTextCheck=0x{acc:X2}（FastText位={(acc & 0x10) != 0}）：{detail}");
            }
        }

        /// <summary>Send 级自排队：窗口一出现就探；有上限，不会把消息泵饿死。</summary>
        private static void ScheduleRealTextBlockProbe(int n)
        {
            // 上限刻意取小：Send 级自排队会把消息泵占住（实测会把 shim 的消息台账刷到 5000+ 行），
            // 200 次足够覆盖"窗口构造→Show"这一段，又不会扰动被观测的那次运行。
            if (n > 200 || _realTbDone) return;
            if (n == 200) { Say("真实 TextBlock 探针：窗口在首次布局前没能拿到 HwndSource，放弃（崩溃先到）"); return; }
            Application.Current?.Dispatcher.BeginInvoke(DispatcherPriority.Send, new Action(() =>
            {
                if (_realTbDone) return;
                Window mw = Application.Current?.MainWindow;
                // 等的是 **HwndSource 已建**（= Window.Show() 走过了），但**首次布局还没跑**：
                //   lay-out 在渲染 pass（Render 优先级）里跑，本循环在 Send 优先级 ⇒ 一定先于它。
                //   为什么必须等到这一刻：`PixelsPerDip` 来自宿主的 Dpi 缩放，
                //   在 HwndSource 建好之前读只会得到 (0,0)（那会是个假线索）。
                if (mw == null || PresentationSource.FromVisual(mw) == null)
                { ScheduleRealTextBlockProbe(n + 1); return; }
                _realTbDone = true;
                try { RealTextBlockProbe(mw); }
                catch (Exception ex) { Say($"真实 TextBlock 探针失败：{ex.GetType().Name}: {ex.Message}"); }
            }));
        }

        private static TextBlock FindTextBlock(DependencyObject node, int depth)
        {
            if (depth > 8 || node == null) return null;
            if (node is TextBlock t) return t;
            foreach (object child in LogicalTreeHelper.GetChildren(node))
                if (child is DependencyObject d)
                {
                    TextBlock found = FindTextBlock(d, depth + 1);
                    if (found != null) return found;
                }
            return null;
        }

        private static object F(string name, object instance) =>
            attrType.GetField(name, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic)
                   .GetValue(instance);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int ClassOfFn(uint scalar);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int VoidFn();
    }
}

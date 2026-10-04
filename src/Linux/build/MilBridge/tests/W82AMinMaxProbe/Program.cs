// ============================================================================
// W82AMinMaxProbe · 波 `#50` · `D-G83` 的**回溯仪器**（只读，零产品改动）
// ============================================================================
// 【它回答什么】`D-G83` 的修法假设 `H1` = "首次 map 之后再派发一次 WM_GETMINMAXINFO"。
//   W82A 实测第一次落地的 `H1` **没有兑现预测**（map 之后补问，窗口过程回填**仍是默认值**）
//   ⇒ 必须把"为什么还没写回"从猜测变成读数。修前 W81A 报告把这条归进 `NOINFO`
//   （"窗口的私有字段读不到"）——本探针就是来把那一格读出来的。
//
// 【两条独立读数，互不依赖】
//   ① **守卫态**：`Window.WmGetMinMaxInfo`（上游 `Window.cs:4885`）的写回块被
//      `!IsSourceWindowNull && !IsCompositionTargetInvalid` 挡住。两者各有据可查：
//        · `IsSourceWindowNull` ⇒ `_swh == null || _swh._sourceWindow == null`
//        · `IsCompositionTargetInvalid` ⇒ `HwndSource.CompositionTarget == null`（**公开属性**）
//      通过反射读 `Window._swh` 的**存在性**＋公开 API `HwndSource.FromHwnd(...).CompositionTarget`
//      ⇒ 能指名道姓说"是哪一个守卫挡的"，而不是"大概是时序问题"。
//   ② **回填实况**：应用**自己**（不是 shim）调 `SendMessage(hwnd, WM_GETMINMAXINFO, 0, &mmi)`，
//      预填"默认值"（照 `fill_minmaxinfo_defaults` 的口径：min=1x1、max=屏幕 1280x1024），
//      再把回填后的结构体印出来。这条读数**独立于 shim 的任何时序**：只要它在场就能判
//      "WPF 在这一刻会不会写回"。
//      · 回填 == 我们预填的值 ⇒ 写回**没有**发生（守卫挡住了，或消息没到过滤器）；
//      · 回填 != 预填 ⇒ 写回**发生了**，而且这就是"应用声明的值"。
//
// 【口径】本探针**不改任何产品件、不改任何判据**；只印机读行（`W82A_` 前缀），
//   判据由报告 §0 写死、由人工/脚本按行读。
// ============================================================================

using System;
using System.Globalization;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Threading;

namespace W82AMinMaxProbe
{
    internal static class Program
    {
        [StructLayout(LayoutKind.Sequential)]
        private struct POINT { public int x; public int y; }

        [StructLayout(LayoutKind.Sequential)]
        private struct MINMAXINFO
        {
            public POINT ptReserved, ptMaxSize, ptMaxPosition, ptMinTrackSize, ptMaxTrackSize;
        }

        private const uint WM_GETMINMAXINFO = 0x0024;

        // 裸名 == A：与 shim 的 `SendMessage` 导出同款（`win32_msg.c:843`）。
        [DllImport("user32.dll", EntryPoint = "SendMessage")]
        private static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wp, ref MINMAXINFO lp);

        private static void Say(string s)
        {
            Console.Out.WriteLine(s);
            Console.Out.Flush();
        }

        private static string F(object o) { return o == null ? "<null>" : o.ToString(); }

        // 反射读 Window 的私有字段（**只读**，不改）：这条读数 W81A 报告标为 NOINFO。
        private static string Field(object o, string name)
        {
            if (o == null) return "<obj-null>";
            Type t = o.GetType();
            while (t != null)
            {
                FieldInfo fi = t.GetField(name, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                if (fi != null)
                {
                    try { return F(fi.GetValue(o)); } catch (Exception e) { return "<exc:" + e.GetType().Name + ">"; }
                }
                t = t.BaseType;
            }
            return "<no-such-field>";
        }

        // 预填"shim 会填的默认值"（口径逐字照 `win32_core.c` 的 fill_minmaxinfo_defaults：
        //   ptMaxSize/ptMaxPosition = 工作区（本机 1280x1024 屏、无 WM ⇒ 工作区 == 屏幕）；
        //   ptMinTrackSize = 1x1；ptMaxTrackSize = **屏幕尺寸**）。
        private static MINMAXINFO Defaults()
        {
            MINMAXINFO m = new MINMAXINFO();
            m.ptMaxSize.x = 1280; m.ptMaxSize.y = 1024;
            m.ptMaxPosition.x = 0; m.ptMaxPosition.y = 0;
            m.ptMinTrackSize.x = 1; m.ptMinTrackSize.y = 1;
            m.ptMaxTrackSize.x = 1280; m.ptMaxTrackSize.y = 1024;
            return m;
        }

        private static string MMI(MINMAXINFO m)
        {
            return string.Format(CultureInfo.InvariantCulture,
                "maxsize={0}x{1} maxpos={2},{3} mintrack={4}x{5} maxtrack={6}x{7}",
                m.ptMaxSize.x, m.ptMaxSize.y, m.ptMaxPosition.x, m.ptMaxPosition.y,
                m.ptMinTrackSize.x, m.ptMinTrackSize.y, m.ptMaxTrackSize.x, m.ptMaxTrackSize.y);
        }

        // 反射读**属性**（`Window.IsSourceWindowNull` / `IsCompositionTargetInvalid` 是 internal
        //   **属性**，不是字段 —— 上一次我把它们当字段读，只拿到 `<no-such-field>`，那是我的错）。
        private static string Prop(object o, string name)
        {
            if (o == null) return "<obj-null>";
            Type t = o.GetType();
            while (t != null)
            {
                PropertyInfo pi = t.GetProperty(name, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                if (pi != null)
                {
                    try { return F(pi.GetValue(o, null)); } catch (Exception e) { return "<exc:" + e.GetType().Name + ">"; }
                }
                t = t.BaseType;
            }
            return "<no-such-property>";
        }

        // ── 读数③：`HwndSource._hooks` 的**成员清单**（判"Window 的过滤器到底在不在链上"）──
        //   为什么需要它：若消息根本没送到 `Window.WindowFilterMessage`（`Window.cs:4250`），
        //   那么"写回没发生"与"守卫挡住了"是**两件事**，而修法 H1 的前提是后者。
        private static void DumpHooks(HwndSource src)
        {
            object hooks = null;
            Type t = src.GetType();
            while (t != null && hooks == null)
            {
                FieldInfo fi = t.GetField("_hooks", BindingFlags.Instance | BindingFlags.NonPublic);
                if (fi != null) hooks = fi.GetValue(src);
                t = t.BaseType;
            }
            if (hooks == null) { Say("W82A_HOOKS <_hooks is null ⇒ 没有任何公开钩子>"); return; }
            object arr = hooks.GetType().GetProperty("Item2").GetValue(hooks, null);
            Array a = arr as Array;
            Say("W82A_HOOKS n=" + (a == null ? -1 : a.Length));
            if (a == null) return;
            for (int i = 0; i < a.Length; i++)
            {
                Delegate d = a.GetValue(i) as Delegate;
                if (d == null) { Say("W82A_HOOKS[" + i + "]=<null>"); continue; }
                Say("W82A_HOOKS[" + i + "]=" + d.Method.DeclaringType.FullName + "." + d.Method.Name
                    + " target=" + (d.Target == null ? "<static>" : d.Target.GetType().FullName));
            }
        }

        private static void Dump(string tag, Window w, string stage)
        {
            IntPtr h = IntPtr.Zero;
            try { h = new WindowInteropHelper(w).Handle; } catch { }
            HwndSource src = null;
            try { if (h != IntPtr.Zero) src = HwndSource.FromHwnd(h); } catch { }
            object ct = src == null ? null : (object)src.CompositionTarget;
            Say(string.Format(CultureInfo.InvariantCulture,
                "W82A_DUMP tag={0} stage={1} hwnd=0x{2:x} swh={3} IsSourceWindowNull={4} hsrc={5} ct={6}",
                tag, stage, h.ToInt64(),
                Field(w, "_swh") == "<obj-null>" ? "<null>" : "<非null>",
                Prop(w, "IsSourceWindowNull"),
                src == null ? "<null>" : "<非null>",
                ct == null ? "<null>" : ct.GetType().Name));
            // ── 判据的两个守卫**逐项**读出来（`Window.cs:4885`）────────────────────────
            //   `IsCompositionTargetInvalid` = `_swh.CompositionTarget == null`，而该 getter
            //   （`Window.cs:7484-7497`）的判据是 `_sourceWindow.CompositionTarget != null
            //   **∧ !compositionTarget.IsDisposed**` ⇒ 两半都要读。
            Say("W82A_GUARD tag=" + tag + " stage=" + stage
                + " IsSourceWindowNull=" + Prop(w, "IsSourceWindowNull")
                + " IsCompositionTargetInvalid=" + Prop(w, "IsCompositionTargetInvalid")
                + " rawCT.IsDisposed=" + (ct == null ? "<n/a>" : Prop(ct, "IsDisposed")));
        }

        [STAThread]
        private static int Main(string[] args)
        {
            double hold = 6, maxW = 640, maxH = 480, minW = 500, minH = 400;
            foreach (string a in args)
            {
                if (a.StartsWith("--hold=", StringComparison.Ordinal)) double.TryParse(a.Substring(7), NumberStyles.Float, CultureInfo.InvariantCulture, out hold);
            }

            Say("W82A_PROBE pid=" + Environment.ProcessId + " mode=minmax-live");
            Say("W82A_TOOLKIT pf=" + typeof(Window).Assembly.Location
                + " pc=" + typeof(System.Windows.Media.Visual).Assembly.Location);

            var app = new Application();
            int rc = 0;
            try
            {
                // ── 窗口 A：上限与下限**都**声明（Show() 之前），照 W81A 的 declared+minonly 口径 ──
                var a = new Window
                {
                    Title = "W82A-A-" + Environment.ProcessId,
                    Width = 360, Height = 260,
                    MaxWidth = maxW, MaxHeight = maxH,
                    MinWidth = minW, MinHeight = minH,
                };
                Say("W82A_DP tag=A max=" + a.MaxWidth + "x" + a.MaxHeight + " min=" + a.MinWidth + "x" + a.MinHeight);
                Dump("A", a, "pre-show");

                a.Show();
                Dump("A", a, "post-show-nocallback");

                // 让 Dispatcher 把布局/渲染/消息泵干净，再读第二遍（"稳定态"）
                app.Dispatcher.Invoke(new Action(() => { }), DispatcherPriority.ApplicationIdle);
                Dump("A", a, "post-show-idle");

                IntPtr ha = new WindowInteropHelper(a).Handle;
                Say("W82A_TRACKFIELDS tag=A "
                    + "_trackMinWidthDeviceUnits=" + Field(a, "_trackMinWidthDeviceUnits")
                    + " _trackMaxWidthDeviceUnits=" + Field(a, "_trackMaxWidthDeviceUnits")
                    + " _windowMaxWidthDeviceUnits=" + Field(a, "_windowMaxWidthDeviceUnits"));

                // ── 读数③：钩子链成员清单 ＋ "消息到底有没有送到公开钩子" ─────────────────
                HwndSource srca = HwndSource.FromHwnd(ha);
                DumpHooks(srca);
                // 我这个钩子是**最后**加的 ⇒ 按 HwndSource 的语义（后加先跑）它**先**于
                // Window 的过滤器跑，所以它打印的就是"进入链时"的值；而 SendMessage 返回后
                // 读到的才是"整条链跑完"的值 —— 两者一对照就能分出
                // "消息没进链" / "进了链但 Window 没写回"。
                int n24 = 0;
                srca.AddHook((IntPtr h, int msg, IntPtr wp, IntPtr lp, ref bool handled) =>
                {
                    if (msg == (int)WM_GETMINMAXINFO)
                    {
                        n24++;
                        MINMAXINFO mm = (MINMAXINFO)Marshal.PtrToStructure(lp, typeof(MINMAXINFO));
                        Say("W82A_HOOK#" + n24 + " msg=0x" + msg.ToString("x4") + " 进链时 " + MMI(mm));
                    }
                    return IntPtr.Zero;
                });

                // ── 读数④：**直接把 `Window.WindowFilterMessage` 叫起来**（隔离"投递链"这一层）──
                //   为什么需要它：①/③ 已经证明"消息进了钩子链"、"两个守卫都是 false"，
                //   而回填**仍未发生** ⇒ 必须把"方法本身"与"投递机制"分开量。
                //   反射调它**不改任何状态**（只读一次结构体、按同一段代码判守卫）。
                MethodInfo wfm = typeof(Window).GetMethod("WindowFilterMessage",
                    BindingFlags.Instance | BindingFlags.NonPublic);
                IntPtr pmmi = Marshal.AllocHGlobal(40);
                Marshal.StructureToPtr(Defaults(), pmmi, false);
                object[] iargs = new object[] { ha, (int)WM_GETMINMAXINFO, IntPtr.Zero, pmmi, false };
                try
                {
                    object ret = wfm.Invoke(a, iargs);
                    MINMAXINFO after = (MINMAXINFO)Marshal.PtrToStructure(pmmi, typeof(MINMAXINFO));
                    Say("W82A_INVOKE ok ret=" + F(ret) + " handled=" + iargs[4] + " 回填后 " + MMI(after)
                        + "  changed=" + (MMI(after) == MMI(Defaults()) ? "no" : "YES"));
                }
                catch (TargetInvocationException tie)
                {
                    Exception ie = tie.InnerException;
                    Say("W82A_INVOKE=EXC " + ie.GetType().FullName + ": " + ie.Message.Replace('\n', ' ')
                        + " | at " + (ie.StackTrace ?? "").Split('\n')[0].Trim());
                }
                finally { Marshal.FreeHGlobal(pmmi); }


                MINMAXINFO m1 = Defaults();
                Say("W82A_SEND tag=A pre   " + MMI(m1));
                SendMessage(ha, WM_GETMINMAXINFO, IntPtr.Zero, ref m1);
                Say("W82A_SEND tag=A post  " + MMI(m1)
                    + "  changed=" + (MMI(m1) == MMI(Defaults()) ? "no" : "YES"));

                // 同一条消息再发一次（判"是不是只第一次有效"）
                MINMAXINFO m1b = Defaults();
                SendMessage(ha, WM_GETMINMAXINFO, IntPtr.Zero, ref m1b);
                Say("W82A_SEND tag=A post2 " + MMI(m1b));

                // ── 窗口 B：Show() **之后**才声明（W81A 的 late 臂；诊断） ──
                var b = new Window { Title = "W82A-B-" + Environment.ProcessId, Width = 300, Height = 200 };
                b.Show();
                app.Dispatcher.Invoke(new Action(() => { }), DispatcherPriority.ApplicationIdle);
                IntPtr hb = new WindowInteropHelper(b).Handle;
                MINMAXINFO m0 = Defaults();
                SendMessage(hb, WM_GETMINMAXINFO, IntPtr.Zero, ref m0);
                Say("W82A_SEND tag=B before-declare " + MMI(m0));
                b.MaxWidth = maxW; b.MaxHeight = maxH;
                app.Dispatcher.Invoke(new Action(() => { }), DispatcherPriority.ApplicationIdle);
                MINMAXINFO m2 = Defaults();
                SendMessage(hb, WM_GETMINMAXINFO, IntPtr.Zero, ref m2);
                Say("W82A_SEND tag=B after-declare  " + MMI(m2)
                    + "  changed=" + (MMI(m2) == MMI(Defaults()) ? "no" : "YES"));

                Say("W82A_READY windows=2");
                var t = new DispatcherTimer(DispatcherPriority.Normal) { Interval = TimeSpan.FromSeconds(hold) };
                t.Tick += (s, e) => { t.Stop(); app.Shutdown(); };
                t.Start();
                app.Run();
            }
            catch (Exception ex)
            {
                Say("W82A_PROBE=EXC type=" + ex.GetType().FullName + " msg=" + ex.Message.Replace('\n', ' '));
                rc = 3;
            }
            Say("W82A_PROBE=ALIVE rc=" + rc);
            return rc;
        }
    }
}

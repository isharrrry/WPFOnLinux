// 本文件由 tools/t1c-inputtrace-verify.py 从 build/PresentationCore.Linux/HwndSource.Linux.cs **原样抽出**
// ⚠️ **不参与编译**（只作存档/取证）：该类的签名引用 PC 内部类型，独立编译必然失败；
//    两臂自检改为**反射调用真件**，见同目录 Program.cs 的说明。
// （探针编的就是将来进 PC 的那份文本；不要手改）
using System;
using System.Globalization;
using System.Threading;

namespace System.Windows.Interop
{
    /// <summary>
    /// T1c · 输入链的**只读**插桩（缺省关）：`WPF_LINUX_INPUT_TRACE=1` 才打，每进程最多
    /// <see cref="MaxLines"/> 行。**只打印**：所有调用点都在"原语句之后"读一眼，不改任何控制流、
    /// 不改任何返回值、不碰 `RenderDiagnostics`。
    ///
    /// 【它要回答的三格】① `_eatCharMessages` 是不是**卡在 true**（⇒ WM_CHAR 被静默吃掉）；
    /// ② 那条 Normal 优先级的 `RestoreCharMessages` **跑没跑**；③ `TranslateChar/OnMnemonic/
    /// ProcessTextInputAction` 里**哪一步**把 `handled` 置成了 true。
    /// </summary>
    internal static class WpfLinuxInputTrace
    {
        /// <summary>开关名。**未设/空白 ⇒ 关**（纯函数 <see cref="IsOn"/>）。</summary>
        internal const string EnvVar = "WPF_LINUX_INPUT_TRACE";

        /// <summary>有界：每进程最多打这么多行（输入路径高频，必须有界）。</summary>
        private const int MaxLines = 200;

        private static readonly bool s_enabled = IsOn(Environment.GetEnvironmentVariable(EnvVar));

        /// <summary>**尝试**打印的次数（用于封顶）。</summary>
        private static int s_attempts;
        private static int s_budgetNotice;   // L12：触顶只报一次

        /// <summary>**实际打出去**的行数 —— <see cref="LineCount"/> 报的就是它。</summary>
        private static int s_emitted;

        internal static bool Enabled { get { return s_enabled; } }

        /// <summary>
        /// **实际打出去的行数**（探针/复验可读；缺省关时恒 0）。
        /// ⚠️ 这里踩过一次：早先它记的是"调用次数"，于是在连打 250 次后报 **261**，
        ///    而真正写出去的是 200 行（封顶本身没错，**是读数会骗人** ⇒ 探针把它抓了出来）。
        ///    现在它只在实际写行时自增 ⇒ 读数 == 输出行数 ≤ MaxLines。
        /// </summary>
        internal static int LineCount { get { return s_emitted; } }

        /// <summary>尝试次数（诊断用：> MaxLines 说明发生过封顶）。</summary>
        internal static int AttemptCount { get { return s_attempts; } }

        /// <summary>未设/空白 ⇒ **false**；"1"/"true"/"on"/"yes"（不分大小写）⇒ true；其余 ⇒ false。</summary>
        internal static bool IsOn(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return false;
            string v = value.Trim();
            if (v == "1") return true;
            if (string.Equals(v, "true", StringComparison.OrdinalIgnoreCase)) return true;
            if (string.Equals(v, "on", StringComparison.OrdinalIgnoreCase)) return true;
            if (string.Equals(v, "yes", StringComparison.OrdinalIgnoreCase)) return true;
            return false;
        }

        private static void Emit(string message)
        {
            if (!s_enabled) return;
            if (System.Threading.Interlocked.Increment(ref s_attempts) > MaxLines)   // 封顶：最多尝试 MaxLines 次
            {
                if (System.Threading.Interlocked.Exchange(ref s_budgetNotice, 1) == 0)
                {
                    try
                    {
                        System.Console.Error.WriteLine("[INPUT_TRACE] **预算用尽**（MaxLines=" + MaxLines
                            + "）⇒ 之后不再打印；**「没打」≠「没发生」**：请调大额度或缩小过滤范围");
                        System.Console.Error.Flush();
                    }
                    catch (System.Exception) { }
                }
                return;
            }

            try
            {
                Console.Error.WriteLine("[INPUT_TRACE] " + message);
                Console.Error.Flush();
                System.Threading.Interlocked.Increment(ref s_emitted);                        // **只在实际写出去时**自增
            }
            catch (Exception)
            {
            }
        }

        private static string Hex(IntPtr v) { return "0x" + v.ToInt64().ToString("x"); }

        /// <summary>
        /// ⓪ **所有早退门之前**（即 `if (!HasFocusWithin() && !IsInExclusiveMenuMode) return;` **之前**）。
        /// 只对四个 char 消息打（否则每条消息都打会把 200 行预算炸掉）。
        /// `HasFocusWithin()` **惰性**求值：把 sink 传进来、只在插桩开着时才问 ⇒ 关掉时零额外代价、语义不变。
        /// 为什么非要这一格：`OnPreprocessMessage` 在 switch **之前**就有早退门，所以后面那条
        /// "WM_CHAR 入口"探针的**没打印**有三种含义 ——
        ///   (a) 消息根本没到 OnPreprocessMessage；(b) 到了、被焦点门挡回去了；(c) 到了、没进 switch 的 char 分支。
        /// 有了这一格：(a) 与 (b/c) 立刻分开（本格命中而入口格不命中 ⇒ 就是被焦点门挡的，实锤）。
        /// </summary>
        internal static void PreprocessEarlyGate(int msg, IntPtr hwnd, IntPtr wParam,
                                                 bool eatCharMessages, bool menuMode, IKeyboardInputSink sink)
        {
            if (!s_enabled) return;
            bool isChar = (msg == 0x0102 || msg == 0x0106 || msg == 0x0103 || msg == 0x0107);
            if (!isChar) return;                     // WM_CHAR / WM_SYSCHAR / WM_DEADCHAR / WM_SYSDEADCHAR
            bool hasFocus = false;
            try { hasFocus = (sink != null) && sink.HasFocusWithin(); } catch (System.Exception) { }
            Emit("PreprocessMessage **早退门之前** msg=0x" + msg.ToString("x") + " hwnd=" + Hex(hwnd)
                 + " wParam=" + wParam.ToInt64().ToString(System.Globalization.CultureInfo.InvariantCulture)
                 + " HasFocusWithin=" + hasFocus + " IsInExclusiveMenuMode=" + menuMode
                 + " _eatCharMessages=" + eatCharMessages);
        }

        /// <summary>① WM_CHAR 分支**入口（过焦点门后）**（注意：在 `if(!_eatCharMessages)` **之外**读，才看得到"卡住"）。</summary>
        internal static void PreprocessCharEntry(IntPtr hwnd, int msg, IntPtr wParam, bool eatCharMessages, bool menuMode)
        {
            Emit("PreprocessMessage WM_CHAR 入口(**过焦点门后**) hwnd=" + Hex(hwnd) + " msg=0x" + msg.ToString("x")
                 + " wParam=" + wParam.ToInt64().ToString(System.Globalization.CultureInfo.InvariantCulture)
                 + " _eatCharMessages=" + eatCharMessages + " IsInExclusiveMenuMode=" + menuMode);
        }

        /// <summary>② 每个子步骤**之后**的 handled（哪一步把它置 true 就打到那一步）。</summary>
        internal static void PreprocessCharStep(string step, bool handled)
        {
            Emit("PreprocessMessage WM_CHAR 步骤 " + step + " ⇒ handled=" + handled);
        }

        /// <summary>①' HwndSource 自己那条 WM_KEYDOWN：置 true 前 / 复位后。</summary>
        internal static void SourceKeyDown(bool eatCharMessages, bool handled, string stage)
        {
            Emit("HwndSource WM_KEYDOWN " + stage + " _eatCharMessages=" + eatCharMessages + " handled=" + handled);
        }

        /// <summary>④ `RestoreCharMessages` 被调用（"那条 Normal 优先级的 restore 到底跑没跑"）。</summary>
        internal static void RestoreCharMessagesCalled()
        {
            Emit("RestoreCharMessages 被调用（_eatCharMessages 将被置 false）");
        }

        /// <summary>③ 提供方 FilterMessage 的 WM_KEYDOWN 入口/出口。</summary>
        internal static void ProviderKeyDown(string stage, bool eatCharMessages, bool handled, bool repeated)
        {
            Emit("FilterMessage WM_KEYDOWN " + stage + " _eatCharMessages=" + eatCharMessages
                 + " handled=" + handled + " IsRepeatedKeyboardMessage=" + repeated);
        }

        /// <summary>③' 提供方 FilterMessage 的 WM_KEYDOWN 复位后（`_eatCharMessages` 是否被清掉）。</summary>
        internal static void ProviderKeyDownReset(bool eatCharMessages, bool handled)
        {
            Emit("FilterMessage WM_KEYDOWN 复位后 _eatCharMessages=" + eatCharMessages + " handled=" + handled);
        }

        // ══════════════════════════════════════════════════════════════════════════════════
        //  第 2 批（P1…P5）：`ProcessTextInputAction` **之后**发生了什么
        //
        //  第 1 批的实跑读数已把范围钉死：char 到了 OnPreprocessMessage、`_eatCharMessages`
        //  **所有描点都是 False**、三步都没置 handled，最后 **ProcessTextInputAction ⇒ handled=True**
        //  而 TextBox 文本没变 ⇒ "置位/吞掉/复位"那套判据**不成立**（已在报告里撤回）。
        //  第 2 批只回答一件事：**`TextInput` 到底有没有被 raise、raise 给了谁**。
        //
        //  预算**独立**于第 1 批（第 1 批那 200 行吃不到它）：Text 类报告**必打**，
        //  其它类报告只采样前 20 行（鼠标每帧都来，否则会把预算吃光 —— 上一轮的教训）。
        //  只对 Text 类打印的地方在注释里写明"只对 Text"。
        //  ⚠️ 本类在 `System.Windows.Interop`；**其它命名空间的文件必须全限定**
        //     （`System.Windows.Interop.WpfLinuxInputTrace.…`），否则编译不过。
        // ══════════════════════════════════════════════════════════════════════════════════
        private const int MaxB2Lines = 200;        // 第 2 批硬上限
        private const int MaxB2OtherLines = 20;    // 非 Text 类报告采样行数

        private static int s_b2Lines;
        private static int s_b2OtherLines;
        private static int s_b2TextSeen;
        private static int s_b2OtherSeen;
        private static int s_b2OtherNotice;

        /// <summary>第 2 批实际输出行数（读数 == 输出行数）。</summary>
        internal static int B2LineCount { get { return s_b2Lines; } }

        private static void EmitB2(string message)
        {
            if (!s_enabled) return;
            if (System.Threading.Interlocked.Increment(ref s_b2Lines) > MaxB2Lines) return;
            try
            {
                System.Console.Error.WriteLine("[INPUT_TRACE] " + message);
                System.Console.Error.Flush();
            }
            catch (System.Exception)
            {
                System.Threading.Interlocked.Decrement(ref s_b2Lines);
            }
        }

        private static string Chr2(int c)
        {
            if (c < 0x20 || c > 0x10FFFF) return "";
            return " ch=U+" + c.ToString("x4");
        }

        private static string TypeOf(object o)
        {
            if (o == null) return "(null)";
            try
            {
                return o.GetType().Name + "#"
                     + System.Runtime.CompilerServices.RuntimeHelpers.GetHashCode(o).ToString("x");
            }
            catch (System.Exception) { return "(读不出来)"; }
        }

        /// <summary>`InputReport` 的读数：类型名 + `Type`（Text / Mouse / Keyboard…）。</summary>
        private static string ReportOf(object inputReport)
        {
            System.Windows.Input.InputReport r = inputReport as System.Windows.Input.InputReport;
            if (r == null) return "(null)";
            try { return r.GetType().Name + "/Type=" + r.Type; }
            catch (System.Exception) { return r.GetType().Name + "/Type=(读不出来)"; }
        }

        private static bool B2IsTextReport(object inputReport)
        {
            System.Windows.Input.InputReport r = inputReport as System.Windows.Input.InputReport;
            if (r == null) return false;
            try { return r.Type == System.Windows.Input.InputType.Text; }
            catch (System.Exception) { return false; }
        }

        /// <summary>预算闸：Text 类必打；其它类采样 MaxB2OtherLines 行（封顶时打一行通知，只打一次）。</summary>
        private static bool B2Allow(object inputReport)
        {
            if (B2IsTextReport(inputReport))
            {
                System.Threading.Interlocked.Increment(ref s_b2TextSeen);
                return true;
            }
            System.Threading.Interlocked.Increment(ref s_b2OtherSeen);
            if (System.Threading.Interlocked.Increment(ref s_b2OtherLines) <= MaxB2OtherLines) return true;
            if (System.Threading.Interlocked.Exchange(ref s_b2OtherNotice, 1) == 0)
            {
                EmitB2("第 2 批：非 Text 报告明细已封顶(" + MaxB2OtherLines + " 行) ⇒ 之后**只打 Text 类**"
                       + "（累计已见 Text " + s_b2TextSeen + " 条 / 非 Text " + s_b2OtherSeen + " 条）");
            }
            return false;
        }

        /// <summary>P1 `InputProviderSite.ReportInput`：报告类型 + 返回的 handled + `_inputManager` 有没有。</summary>
        internal static void B2ReportInput(object inputReport, bool handled, object inputManager)
        {
            if (!s_enabled) return;
            if (!B2Allow(inputReport)) return;
            EmitB2("P1 InputProviderSite.ReportInput 报告=" + ReportOf(inputReport)
                   + " ⇒ 返回 handled=" + handled
                   + " _inputManager=" + (inputManager == null ? "(null)" : "有"));
        }

        /// <summary>P2 `InputManager.ProcessInput` 入口：报告类型 + RoutedEvent + Source + **焦点在谁身上**。</summary>
        internal static void B2ProcessInputEntry(object input, object keyboardDevice)
        {
            if (!s_enabled) return;
            object report = null;
            string routedEvent = "(非 InputReportEventArgs)";
            string source = "(n/a)";
            System.Windows.Input.InputReportEventArgs ire =
                input as System.Windows.Input.InputReportEventArgs;
            if (ire != null)
            {
                report = ire.Report;
                routedEvent = (ire.RoutedEvent == null) ? "(null)" : ire.RoutedEvent.Name;
                source = TypeOf(ire.Source);
            }
            if (!B2Allow(report)) return;

            string focused = "(null)";
            System.Windows.Input.KeyboardDevice dev =
                keyboardDevice as System.Windows.Input.KeyboardDevice;
            if (dev != null) focused = TypeOf(dev.FocusedElement);

            EmitB2("P2 InputManager.ProcessInput 入口 报告=" + ReportOf(report)
                   + " RoutedEvent=" + routedEvent + " Source=" + source
                   + " KeyboardDevice.FocusedElement=" + focused);
        }

        /// <summary>P2' `InputManager.ProcessInput` 返回（**只对 Text 类**打，非 Text 在入口已采样过）。</summary>
        internal static void B2ProcessInputResult(object input, bool handled)
        {
            if (!s_enabled) return;
            System.Windows.Input.InputReportEventArgs ire =
                input as System.Windows.Input.InputReportEventArgs;
            object report = (ire == null) ? null : ire.Report;
            if (!B2IsTextReport(report)) return;
            EmitB2("P2' ProcessInput 返回 handled=" + handled + " 报告=" + ReportOf(report));
        }

        /// <summary>
        /// P3a `TextCompositionManager` 的 "Raw to StartComposition" 那段**条件之前**：
        /// 报告类型 + RoutedEvent（**条件要求 `Type=Text` 且 `RoutedEvent=InputReport`**）。
        /// **只对 Text 类**打（这段每帧都会被别的报告经过）。
        /// </summary>
        internal static void B2RawReport(object input)
        {
            if (!s_enabled) return;
            System.Windows.Input.InputReportEventArgs ire =
                input as System.Windows.Input.InputReportEventArgs;
            object report = (ire == null) ? null : ire.Report;
            if (!B2IsTextReport(report)) return;
            string routedEvent = (ire.RoutedEvent == null) ? "(null)" : ire.RoutedEvent.Name;
            EmitB2("P3a TextCompositionManager 到达 Raw 段 报告=" + ReportOf(report)
                   + " RoutedEvent=" + routedEvent + " Source=" + TypeOf(ire.Source)
                   + "（条件= Type==Text && RoutedEvent==InputReport）");
        }

        /// <summary>P3b **进了** `Raw → StartComposition` 分支体（码点 + 三个标志 + 目标元素）。</summary>
        internal static void B2RawBranch(object rawTextInput, object processArgs)
        {
            if (!s_enabled) return;
            // **实参惰性**：调用点只传 `e`；`e.StagingItem.Input.Source` 这条链在这里取（try/catch 包住）
            object stagingSource = "(取不到)";
            try
            {
                System.Windows.Input.ProcessInputEventArgs pia =
                    processArgs as System.Windows.Input.ProcessInputEventArgs;
                if (pia != null && pia.StagingItem != null && pia.StagingItem.Input != null)
                    stagingSource = pia.StagingItem.Input.Source;
            }
            catch (System.Exception) { stagingSource = "(读 Source 抛)"; }
            System.Windows.Input.RawTextInputReport t =
                rawTextInput as System.Windows.Input.RawTextInputReport;
            if (t == null)
            {
                EmitB2("P3b 进了 Raw→StartComposition 分支，但 Report 不是 RawTextInputReport："
                       + TypeOf(rawTextInput));
                return;
            }
            EmitB2("P3b 进了 Raw→StartComposition 分支 码点=" + ((int)t.CharacterCode)
                   + Chr2((int)t.CharacterCode)
                   + " IsControlCharacter=" + t.IsControlCharacter
                   + " IsDeadCharacter=" + t.IsDeadCharacter
                   + " IsSystemCharacter=" + t.IsSystemCharacter
                   + " StagingItem.Source=" + TypeOf(stagingSource));
        }

        /// <summary>P4a 正常字符分支新建出来的 `TextComposition`：文本 + **目标元素（Source）**。</summary>
        internal static void B2CompositionCreated(object composition)
        {
            if (!s_enabled) return;
            System.Windows.Input.TextComposition c =
                composition as System.Windows.Input.TextComposition;
            if (c == null) { EmitB2("P4a 新建的 composition 为 null"); return; }
            string text = "(读不出来)";
            try { text = """ + c.Text + """; } catch (System.Exception) { }
            string src = "(读不出来)";
            try { src = TypeOf(c.Source); } catch (System.Exception) { }
            EmitB2("P4a 新建 TextComposition Text=" + text + " 目标(Source)=" + src);
        }

        /// <summary>P4b `UnsafeStartComposition` 的**返回值**（handled）。</summary>
        internal static void B2StartComposition(string stage, bool returned, object composition)
        {
            if (!s_enabled) return;
            System.Windows.Input.TextComposition c =
                composition as System.Windows.Input.TextComposition;
            string text = "(null)";
            try { if (c != null) text = """ + c.Text + """; } catch (System.Exception) { }
            EmitB2("P4b UnsafeStartComposition(" + stage + ") 返回 handled=" + returned + " Text=" + text);
        }

        /// <summary>
        /// P5 **`RaiseEvent` 之前**：事件名 + **目标元素（eventSource）** + `Source`。
        /// `TextInput`/`PreviewTextInput` **必打**；其它事件只采样（每个输入事件都会经过这里）。
        /// </summary>
        internal static void B2RaiseInput(object input, object eventSource)
        {
            if (!s_enabled) return;
            System.Windows.Input.InputEventArgs ie = input as System.Windows.Input.InputEventArgs;
            string ev = (ie == null || ie.RoutedEvent == null) ? "(null)" : ie.RoutedEvent.Name;
            bool isTextEvent = (ev == "TextInput" || ev == "PreviewTextInput");
            if (!isTextEvent)
            {
                if (System.Threading.Interlocked.Increment(ref s_b2OtherLines) > MaxB2OtherLines) return;
            }
            EmitB2("P5 RaiseEvent 之前 事件=" + ev + " 目标(eventSource)=" + TypeOf(eventSource)
                   + " Source=" + ((ie == null) ? "(null)" : TypeOf(ie.Source))
                   + (isTextEvent ? "" : "（非文本事件·采样）"));
        }

        /// <summary>P5' `RaiseEvent` **之后**的 `Handled`（**只对文本事件**打）——"raise 了有没有人接"。</summary>
        internal static void B2RaiseInputResult(object input, bool handled)
        {
            if (!s_enabled) return;
            System.Windows.Input.InputEventArgs ie = input as System.Windows.Input.InputEventArgs;
            string ev = (ie == null || ie.RoutedEvent == null) ? "(null)" : ie.RoutedEvent.Name;
            if (ev != "TextInput" && ev != "PreviewTextInput") return;
            EmitB2("P5' RaiseEvent 之后 事件=" + ev + " Handled=" + handled);
        }

        /// <summary>⑥ 提供方 FilterMessage 的 WM_CHAR 分支（重复消息判定 + 被 `_eatCharMessages` 门住的那一格）。</summary>
        internal static void ProviderChar(string stage, bool repeated, bool eatCharMessages, bool handled)
        {
            Emit("FilterMessage WM_CHAR " + stage + " IsRepeatedKeyboardMessage=" + repeated
                 + " _eatCharMessages=" + eatCharMessages + " handled=" + handled);
        }
    }

}

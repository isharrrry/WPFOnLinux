// =====================================================================================
//  D5CbrProbe —— `#23` §1 P1（车道 W23A）：`D-T5` 判据 + 红读数 + **abort/null 可分辨性**（只测不修）
//
//  【被判的东西】`D-T5`（`KNOWN-DEFECTS.md:700-704`，`#22` 扩宽）：
//    `TextModifier` / `TextEndOfSegment` / `TextHidden` 的 `CharacterBufferReference` 是
//    **sealed default（空）** ⇒ 生成物 `ExtractRun`（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:81-91`）
//    的 `if (buf == null) return null;` ⇒ 宽松档 `CollectLenient`（`:149-153`）
//    `DiagBeforeReturn` ⇒ `return false` ⇒ 三层托管档全落空 ⇒
//    `new TextMetrics.FullTextLine(...)`（生成物 `:618`）⇒ `LoCreateContext`
//    （`libwpfwin32.so` 里 `nm -D` **实测无该符号**）⇒ 逐层无 catch ⇒ **进程级 abort**。
//
//  【为什么不改 `PcLineOracle` / `CoverageProbe`】它们是 `verify-all` 与臂重取的仪器（§1.3 明写）。
//
//  【本探针的三条断言（草案，照 §1.3 实现）】
//    A1 「必须交出非 null 的 `TextLine`」   —— 每次 `FormatLine` 都非 null 且 ≥1 行
//    A2 「不得出现 `LoCreateContext`」      —— 无该 `EntryPointNotFoundException`
//    A3 「行 `Length` 与输入一致」          —— `Σ line.Length == CpLength`（输入**段**的码元总数）
//
//  【⭐ 本探针的核心纪律：abort 与 null 必须可分辨】
//    §1.3 明写这两者"今天在读数上长得一样"（`D-R3` 家族：**仪器崩了被读成产品崩了**）。
//    做法有三层，缺一不可：
//      ① **一例一进程**（驱动脚本 `run-matrix.sh` 逐例起进程）⇒ 一例 abort 不带走进程里的其他例；
//      ② **调用前先落盘**（`Mark()`，`FileStream.Flush(true)`）⇒ abort 后仍能看出死在**哪一次调用**；
//      ③ **装置自证**（`--selftest abort|null`）⇒ 让驱动脚本的判读逻辑**自己先被两极化验过**，
//         否则"能把 134 与 null 分开"只是**声称**，不是**读数**（纪律 25：计数要有正控）。
//
//  【`--nocatch`】故意**不**包 try/catch ⇒ `Main` 之外未处理 ⇒ .NET 运行期 `abort()` ⇒ `rc=134`。
//    这是**应用路径的忠实模拟**（`#22` 实测：从生成物到 `WpfTextDemo` 主循环**没有任何一层 catch**）。
//    两条腿都给读数（catch 版能报"抛了什么"，nocatch 版能报"应用会怎样"），**不许**只取其一。
//
//  【纪律】任何结论连 artifact + 字段 + sha16 一起写；缺数据 ⇒ `NOINFO`，**不许猜**。
// =====================================================================================

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace MilBridge.D5CbrProbe
{
    internal static class Program
    {
        private const string FallbackEnvVar = "WPF_LINUX_TEXTLINE_FALLBACK";
        private const string FontFamilyName = "Liberation Sans";
        private const double Em = 24.0;
        private const double ParagraphWidth = 200.0;

        // ---- 相位标记（崩溃取证；**每次调用之前**先落盘并 fsync） ----
        private static string s_marker;
        /// <summary>`--trace-source`：把**每一次** `GetTextRun(cp)` 调用（下标 + 返回类型 + Length）
        /// 打到 stdout。用途 = **谁在什么时候问了什么**必须可观测 —— 层级的归因不能靠读码推测。</summary>
        private static bool s_trace;
        /// <summary>`--collapsible`：置 `AlwaysCollapsible=true` ⇒ **关掉 `SimpleTextLine` 快路径**
        /// （生成物 `:546-549`）⇒ 逼被测 run 走三层托管档。**机制判别器**。</summary>
        private static bool s_collapsible;

        private static void Mark(string s)
        {
            if (s_marker == null) return;
            try
            {
                using (var fs = new FileStream(s_marker, FileMode.Append, FileAccess.Write, FileShare.ReadWrite))
                using (var w = new StreamWriter(fs, new UTF8Encoding(false)))
                {
                    w.WriteLine(s);
                    w.Flush();
                    fs.Flush(true);          // ← 真落盘：abort 带走进程时这一行仍留在盘上
                }
            }
            catch (Exception) { /* 取证失败不许改变被测行为 */ }
        }

        private static void Main(string[] argv)
        {
            string kase = null, tier = "auto", selftest = null;
            bool noCatch = false, list = false;
            for (int i = 0; i < argv.Length; ++i)
            {
                switch (argv[i])
                {
                    case "--case": if (i + 1 < argv.Length) kase = argv[++i]; break;
                    case "--tier": if (i + 1 < argv.Length) tier = argv[++i]; break;
                    case "--marker": if (i + 1 < argv.Length) s_marker = argv[++i]; break;
                    case "--selftest": if (i + 1 < argv.Length) selftest = argv[++i]; break;
                    case "--nocatch": noCatch = true; break;
                    case "--collapsible": s_collapsible = true; break;
                    case "--trace-source": s_trace = true; break;
                    case "--list": list = true; break;
                }
            }

            if (list)
            {
                foreach (string c in CaseIds()) Console.WriteLine(c);
                return;
            }

            Console.WriteLine("D5CBR lane=W23A role=D-T5独立探针 pid=" + Environment.ProcessId);
            Console.WriteLine("D5CBR BUILD  " + BuildStamp());

            // ---------- 装置自证（两极化；**先于任何产品调用**） ----------
            if (selftest != null)
            {
                Mark("T0 selftest=" + selftest);
                Console.WriteLine("D5CBR SELFTEST mode=" + selftest);
                if (selftest == "abort")
                {
                    // 刻意 abort：证明驱动脚本能把"进程被 abort 带走"与"正常返回"分开。
                    Mark("T1 about-to-abort");
                    Console.Out.Flush();
                    abort();
                    return;                        // 不可达
                }
                if (selftest == "null")
                {
                    // 刻意"产品返回 null"的形状：探针**活着**、打出判词、以 rc=1 退出。
                    Console.WriteLine("D5CBR VERDICT case=selftest tier=- verdict=RED-NULL Σlen=0 期望=0 异常=-");
                    Console.WriteLine("D5CBR_EXIT=1");
                    Mark("T3 done verdict=RED-NULL");
                    Environment.ExitCode = 1;          // ⚠️ 仪器自记缺陷：第一版只打了 `D5CBR_EXIT=1`
                    return;                            //    却没设进程退出码 ⇒ `rc=0` 与判词矛盾（已修）
                }
                Console.WriteLine("D5CBR_EXIT=NOINFO rc=2 原因=--selftest 取值非法：" + selftest);
                return;
            }

            // ---------- 0) 档位选择：**拿读数之前**先钉死，并读回产品自己的开关自证 ----------
            if (tier == "lenient") Environment.SetEnvironmentVariable(FallbackEnvVar, "0");
            else if (tier == "strict") Environment.SetEnvironmentVariable(FallbackEnvVar, null);
            else if (tier != "auto")
            {
                Console.WriteLine("D5CBR_EXIT=NOINFO rc=2 原因=--tier 取值非法：" + tier + "（只接受 auto|strict|lenient）");
                return;
            }
            string envNow = Environment.GetEnvironmentVariable(FallbackEnvVar);
            Console.WriteLine("D5CBR TIER  请求档=" + tier + " env " + FallbackEnvVar + "="
                              + (envNow == null ? "<unset>" : "\"" + envNow + "\""));

            string strictWhy;
            bool strictEnabled;
            if (!TryStrictEnabled(out strictEnabled, out strictWhy))
            {
                Console.WriteLine("D5CBR_EXIT=NOINFO rc=2 原因=读不到产品自己的严格档开关（IVT）：" + strictWhy);
                return;
            }
            // 产品侧开关的**权威判据**是 `HbTextFallback.Enabled`，不是 env（env 只是它的输入）。
            string effective = strictEnabled ? "严格档(HbTextFallback)" : "宽松档(WpfLinuxLenientTextFallback)";
            Console.WriteLine("D5CBR TIER  HbTextFallback.Enabled=" + (strictEnabled ? "true" : "false")
                              + " ⇒ **先试** " + effective
                              + "（三层序：SimpleTextLine 快路径 → 严格档 → 宽松档 → LineServices）");

            // ---------- 1) 字体（只用 public API，与 `PcLineOracle:390-420` 同一把尺子） ----------
            Typeface tf = null;
            try { tf = new Typeface(new FontFamily(FontFamilyName), FontStyles.Normal, FontWeights.Normal, FontStretches.Normal); }
            catch (Exception e) { Console.WriteLine("D5CBR FONT  构造异常：" + e.GetType().Name + ": " + e.Message); }
            if (tf == null)
            {
                Console.WriteLine("D5CBR_EXIT=NOINFO rc=2 原因=Typeface 构造失败（family=" + FontFamilyName + "）");
                return;
            }
            var props = new ProbeRunProperties(tf, Em);

            // ---------- 2) 逐例驱动 ----------
            var ids = new List<string>();
            foreach (string c in CaseIds()) if (kase == null || c == kase) ids.Add(c);
            if (ids.Count == 0)
            {
                Console.WriteLine("D5CBR_EXIT=NOINFO rc=2 原因=--case 不认识：" + kase);
                return;
            }

            int worst = 0;
            foreach (string id in ids) worst = Math.Max(worst, RunOneCase(id, tier, effective, props, noCatch));
            Console.WriteLine("D5CBR_EXIT=" + (worst == 0 ? "0" : (worst == 2 ? "NOINFO rc=2" : "1"))
                              + (ids.Count > 1 ? "（多例腿：取**最坏**例的 rc）" : ""));
            // ⚠️ 仪器纪律：**判词与 `rc` 必须一致** —— 判词说红而 `rc=0` 就是"红被压成绿"的同族。
            Environment.ExitCode = worst;
        }

        private static readonly string[] k_caseIds = { "control", "eos1", "hidden1", "mod1", "hiddenmid", "hiddenonly", "mod0", "declaredgap" };
        private static IEnumerable<string> CaseIds() => k_caseIds;

        /// <summary>一个用例 = 一次完整的"建源 + 驱动 `FormatLine` 到段落结束 + 判三条断言"。</summary>
        private static int RunOneCase(string id, string tier, string effective,
                                      TextRunProperties props, bool noCatch)
        {
            BuildCase(id, props, out ScriptedTextSource src, out int cpLength, out string runDesc);
            string tag = "case=" + id + " tier=" + tier;
            Mark("T0 enter " + tag + " collapsible=" + s_collapsible);

            Console.WriteLine("D5CBR CASE  " + tag + " effective=" + effective);
            // ⭐ 快路径状态必须**逐例印出**：它决定了被测 run 到底走哪一层
            //   （生成物 `:546-549`：`!AlwaysCollapsible && previousLineBreak == null && lineLength <= 0`）
            Console.WriteLine("D5CBR LAYER 快路径(SimpleTextLine)=" + (s_collapsible ? "**关**（--collapsible ⇒ AlwaysCollapsible=true）" : "**开**（AlwaysCollapsible=false）")
                              + " ｜ 快路径开 ⇒ run 由 `SimpleTextLine.Create` 处理，**三层托管档根本不被调用**（计数零增量可证）");
            Console.WriteLine("D5CBR INPUT " + id + " runs=" + runDesc + " CpLength=" + cpLength);

            TextFormatter fmt;
            try { fmt = TextFormatter.Create(); }
            catch (Exception e)
            {
                Console.WriteLine("D5CBR VERDICT " + tag + " verdict=NOINFO 原因=TextFormatter.Create() 抛 "
                                  + e.GetType().Name + ": " + e.Message);
                Mark("T3 done verdict=NOINFO");
                return 2;
            }
            if (fmt == null)
            {
                Console.WriteLine("D5CBR VERDICT " + tag + " verdict=NOINFO 原因=TextFormatter.Create() 返回 null");
                Mark("T3 done verdict=NOINFO");
                return 2;
            }

            var para = new ProbePara(props) { ForceCollapsible = s_collapsible };

            string sBefore = StrictDiag(), lBefore = LenientDiag();
            Console.WriteLine("D5CBR DIAGbefore strict{" + sBefore + "}");
            Console.WriteLine("D5CBR DIAGbefore lenient{" + lBefore + "}");

            int index = 0, guard = 0;
            long sumLen = 0, sumNewline = 0;
            int lines = 0;
            string excName = "-", excMsg = "-";
            bool sawNull = false;
            var perLine = new StringBuilder();

            while (index < cpLength && guard++ < 64)
            {
                // ⭐ ②**调用之前先落盘**：abort 后这一行就是"死在第几次调用"的证据
                Mark("T1 before FormatLine#" + guard + " index=" + index + " cpLength=" + cpLength);
                TextLine line;
                if (noCatch)
                {
                    // 故意不 catch ⇒ 忠实模拟应用路径（`#22`：逐层无 catch）
                    line = fmt.FormatLine(src, index, ParagraphWidth, para, null);
                }
                else
                {
                    try { line = fmt.FormatLine(src, index, ParagraphWidth, para, null); }
                    catch (Exception e)
                    {
                        excName = e.GetType().Name; excMsg = e.Message;
                        Mark("T2 EXC#" + guard + " " + excName);
                        break;
                    }
                }
                if (line == null)
                {
                    sawNull = true;
                    Mark("T2 NULL#" + guard);
                    break;
                }
                long len = line.Length;
                if (len <= 0)
                {
                    Mark("T2 ZEROLEN#" + guard);
                    excName = "ZEROLEN"; excMsg = "FormatLine 返回 0 长行（会死循环）⇒ 停";
                    break;
                }
                // ⚠️ **仪器缺陷自记（第一版，已抓掉）**：`line.Length` **含行尾符**。
                //    第一版直接拿 `Σ line.Length` 与 `CpLength` 比 ⇒ **阳性对照自己变红**
                //    （`control`：Σlen=5 期望=4，5 = 4 字符 + 1 个 `TextEndOfParagraph` 换行）。
                //    ⇒ A3 的口径改为 `Σ(line.Length − line.NewlineLength)`；`Length` 仍按 WPF 语义
                //      用于**推进 `index`**（这就是 `PcLineOracle:786-789` 的同款口径）。
                //    **没有这一条自证，本探针会把"装置活着"读成"产品红"**（纪律 21/27 家族）。
                long nl = line.NewlineLength;
                perLine.Append(" #").Append(guard).Append("=").Append(len).Append("/nl").Append(nl);
                sumLen += len; sumNewline += nl;
                ++lines;
                index += (int)len;
                Mark("T2 after FormatLine#" + guard + " len=" + len + " nl=" + nl + " sumLen=" + sumLen);
            }

            string sAfter = StrictDiag(), lAfter = LenientDiag();
            Console.WriteLine("D5CBR DIAGafter  strict{" + sAfter + "}");
            Console.WriteLine("D5CBR DIAGafter  lenient{" + lAfter + "}");

            // ---------- 层级来源逐例归因（**谁接手的**） ----------
            Console.WriteLine("D5CBR ATTR  " + tag + " " + Attribution(sBefore, sAfter, lBefore, lAfter, effective));

            // ---------- 三条断言 ----------
            long visSum = sumLen - sumNewline;
            bool lsAbort = (excName != "-" && excMsg != null
                            && (excMsg.IndexOf("LoCreateContext", StringComparison.Ordinal) >= 0
                                || excMsg.IndexOf("PresentationNative", StringComparison.Ordinal) >= 0));
            string verdict; int rc;
            if (lsAbort) { verdict = "RED-EXC-LS"; rc = 1; }
            else if (sawNull) { verdict = "RED-NULL"; rc = 1; }
            else if (excName != "-") { verdict = "RED-EXC"; rc = 1; }
            else if (lines < 1) { verdict = "RED-NOLINE"; rc = 1; }
            else if (visSum != cpLength) { verdict = "RED-LENGTH"; rc = 1; }
            else { verdict = "GREEN"; rc = 0; }

            Console.WriteLine("D5CBR ASSERT " + tag
                              + " A1非null=" + (lines >= 1 && !sawNull ? "PASS" : "FAIL")
                              + " A2无LoCreateContext=" + (!lsAbort ? "PASS" : "FAIL")
                              + " A3长度一致=" + (visSum == cpLength ? "PASS" : "FAIL")
                              + "（Σ(Length−NewlineLength)=" + visSum + " 期望=" + cpLength + "）");
            Console.WriteLine("D5CBR VERDICT " + tag + " verdict=" + verdict
                              + " 行数=" + lines + " Σlen=" + sumLen + " Σnl=" + sumNewline
                              + " Σ可见长=" + visSum + " 期望=" + cpLength
                              + " GetTextRun次=" + src.GetTextRunCalls
                              + perLine
                              + " 异常=" + (excName == "-" ? "-" : excName + ": " + excMsg));
            Mark("T3 done verdict=" + verdict + " rc=" + rc);
            return rc;
        }

        // =================================================================================
        //  用例构造：**空 CBR 的 run** 各形态 + 阳性对照
        //  ⚠️ 判据的**分母口径**（纪律 39）：`CpLength` = 源里**全部 run 的 `Length` 之和**
        //     （含 0 长的标记 run 贡献 0）。`Σ line.Length` 必须等于它 —— 这是 A3 的唯一口径。
        // =================================================================================
        private static void BuildCase(string id, TextRunProperties props,
                                      out ScriptedTextSource src, out int cpLength, out string desc)
        {
            var slots = new List<RunSlot>();
            switch (id)
            {
                case "control":
                    // 阳性对照：纯 TextCharacters ⇒ 证明**装置活着**（三层任一档都必须绿）
                    slots.Add(new RunSlot(0, new TextCharacters("WWWW", 0, 4, props)));
                    desc = "[TextCharacters L=4]@0";
                    break;
                case "eos1":
                    // `TextEndOfSegment(1)`：ctor 强制 ≥1（`TextEndOfSegment.cs:29-34`），CBR sealed 默认空
                    slots.Add(new RunSlot(0, new TextEndOfSegment(1)));
                    slots.Add(new RunSlot(1, new TextCharacters("WWWW", 0, 4, props)));
                    desc = "[TextEndOfSegment L=1]@0 [TextCharacters L=4]@1";
                    break;
                case "hidden1":
                    // `TextHidden(1)`：`#22` 查出的"更宽的那一族"；上游 `pf` 每个内联元素边缘就产它
                    slots.Add(new RunSlot(0, new TextHidden(1)));
                    slots.Add(new RunSlot(1, new TextCharacters("WWWW", 0, 4, props)));
                    desc = "[TextHidden L=1]@0 [TextCharacters L=4]@1";
                    break;
                case "mod1":
                    // `TextModifier`：`Length` 由子类给（基类 `Length` 是 abstract，`TextRun.cs:82`）
                    slots.Add(new RunSlot(0, new ProbeModifier(1, props)));
                    slots.Add(new RunSlot(1, new TextCharacters("WWWW", 0, 4, props)));
                    desc = "[TextModifier L=1]@0 [TextCharacters L=4]@1";
                    break;
                case "hiddenmid":
                    // 段**中间**的 hidden（更接近上游 pf 在内联元素边缘插入的形状）
                    slots.Add(new RunSlot(0, new TextCharacters("WW", 0, 2, props)));
                    slots.Add(new RunSlot(2, new TextHidden(1)));
                    slots.Add(new RunSlot(3, new TextCharacters("WW", 0, 2, props)));
                    desc = "[TextCharacters L=2]@0 [TextHidden L=1]@2 [TextCharacters L=2]@3";
                    break;
                case "hiddenonly":
                    // 整个段落只有一个空 CBR 的 run（退化形态）
                    slots.Add(new RunSlot(0, new TextHidden(3)));
                    desc = "[TextHidden L=3]@0";
                    break;
                case "mod0":
                    // ⭐ `Length=0` 的 `TextModifier` —— **唯一能过 `ExtractRun` 的形态**：
                    //    `if (run == null || run.Length <= 0) return string.Empty;`（生成物 `:83`）
                    //    ⇒**不是 null** ⇒ `CollectLenient` 继续 ⇒ 不落 LS。
                    //    这是 `W17D` P3 造红证时用的形态（`W17D-report.md:160`）。
                    //    ⇒ 它同时是"**假装修好**"那条第二极性的**实测代理**（见报告 §④）。
                    slots.Add(new RunSlot(0, new ProbeModifier(0, props)));
                    slots.Add(new RunSlot(0, new TextCharacters("WWWW", 0, 4, props)));
                    desc = "[TextModifier L=0]@0 + 同一下标 [TextCharacters L=4]@0";
                    break;
                case "declaredgap":
                    // ⭐ **断言牙齿对照（不是产品用例）**：源只声明 4 个码元（`TextCharacters L=4`），
                    //    但把**分母 `CpLength` 声明成 5** ⇒ `Σ(Length−NewlineLength)=4 ≠ 5`。
                    //    用途 = 证明 **A3 不是空断言**：它能在 A1（非 null）与 A2（无 LS）**都 PASS**
                    //    的情况下**单独变红**，且红的形状**正是第二极性预测的形状**
                    //    （"源声明 5 个码元，收集/交付只兑现 4 个"）。
                    //    ⇒ 这就是"假装修好"（`buf==null ⇒ 返空串`）在 `Length≥1` 标记上的**可分辨后果**。
                    slots.Add(new RunSlot(0, new TextCharacters("WWWW", 0, 4, props)));
                    desc = "[TextCharacters L=4]@0 **分母声明为 5**（断言牙齿对照，非产品用例）";
                    break;
                default:
                    throw new ArgumentException("未知用例：" + id);
            }
            cpLength = 0;
            foreach (RunSlot s in slots) cpLength += s.Run.Length;
            if (id == "declaredgap") cpLength += 1;      // ← 牙齿对照：刻意让分母比源多 1
            // ⚠️ **只有 `mod0` 允许非幂等**（零宽标记的合法姿势）；其余全部幂等（见 `ScriptedTextSource` 的缺陷自记）
            src = new ScriptedTextSource(slots, cpLength) { StatefulZeroWidth = (id == "mod0") };
        }

        // =================================================================================
        //  层级来源逐例归因
        // =================================================================================
        private static long ExtractLong(string diag, string key)
        {
            int i = diag.IndexOf(key, StringComparison.Ordinal);
            if (i < 0) return -1;
            i += key.Length;
            int j = i; while (j < diag.Length && (char.IsDigit(diag[j]) || diag[j] == '-')) ++j;
            return long.TryParse(diag.Substring(i, j - i), out long v) ? v : -1;
        }
        /// <summary>取 `key="…"` 形式的**引号内**取值。
        /// ⚠️ **仪器缺陷自记（第一版，已抓掉）**：第一版按**第一个空格**截断 ⇒ 归因行打成
        ///    `lastBail="run"`（真值是 `lastBail="run 类型 TextEndOfSegment 不支持"`）
        ///    ⇒ **归因行看起来像"没给出原因"**。判据本身不受影响（`DIAGafter` 行一直印全文），
        ///    但归因行是本报告要引用的一行 ⇒ 必须自己是对的。</summary>
        private static string Quoted(string diag, string key)
        {
            int i = diag.IndexOf(key, StringComparison.Ordinal);
            if (i < 0) return "?";
            i += key.Length;
            int j = diag.IndexOf('"', i);
            return j < 0 ? diag.Substring(i) : diag.Substring(i, j - i);
        }

        /// <summary>**这一例是谁接手的**：严格档计数增量 + 宽松档计数增量**双读**。
        /// `Calls` 涨但 `Handled` 不涨 = 严格档**看过了、没接**（bail）⇒ 不是"没走到"。
        /// 两档都零增量 ⇒ **NOINFO**（"这条路对我不可观测"），**绝不许读成绿**。</summary>
        private static string Attribution(string sB, string sA, string lB, string lA, string effective)
        {
            long sc0 = ExtractLong(sB, "fallbackCalls="), sc1 = ExtractLong(sA, "fallbackCalls=");
            long sh0 = ExtractLong(sB, "fallbackHandled="), sh1 = ExtractLong(sA, "fallbackHandled=");
            long sb0 = ExtractLong(sB, "fallbackBailed="), sb1 = ExtractLong(sA, "fallbackBailed=");
            long lc0 = ExtractLong(lB, "relaxedCalls="), lc1 = ExtractLong(lA, "relaxedCalls=");
            long lh0 = ExtractLong(lB, "relaxedHandled="), lh1 = ExtractLong(lA, "relaxedHandled=");
            long lf0 = ExtractLong(lB, "relaxedFailed="), lf1 = ExtractLong(lA, "relaxedFailed=");
            string lastBail = Quoted(sA, "lastBail=\"");
            string lastFail = Quoted(lA, "lastFail=\"");
            string chain;
            if (sc1 - sc0 == 0 && lc1 - lc0 == 0) chain = "NOINFO(两档零增量 ⇒ 这一例没走到托管档)";
            else if (sh1 - sh0 > 0) chain = "严格档**接手**";
            else if (lh1 - lh0 > 0) chain = "严格档bail ⇒ 宽松档**接手**";
            else chain = "严格档bail ⇒ 宽松档fail ⇒ **交回 LineServices**（Linux 上=abort）";
            return "接手链=" + chain
                 + " ｜ 严格档 Δcalls=" + (sc1 - sc0) + " Δhandled=" + (sh1 - sh0) + " Δbailed=" + (sb1 - sb0)
                 + " lastBail=\"" + lastBail + "\""
                 + " ｜ 宽松档 Δcalls=" + (lc1 - lc0) + " Δhandled=" + (lh1 - lh0) + " Δfailed=" + (lf1 - lf0)
                 + " lastFail=\"" + lastFail + "\"";
        }

        // =================================================================================
        //  IVT：两档的 internal 计数器（**直接字段访问 = 编译期证据**：改了名就 error CS）
        // =================================================================================
        private static bool TryStrictEnabled(out bool enabled, out string why)
        {
            enabled = false; why = "-";
            try { enabled = WpfLinux.Shims.PresentationCore.HbTextFallback.Enabled; return true; }
            catch (Exception e) { why = e.GetType().Name + ": " + e.Message; return false; }
        }
        /// <summary>严格档计数行。命名空间 = `WpfLinux.Shims.PresentationCore`（shim `:4022`）。</summary>
        private static string StrictDiag()
        {
            try
            {
                return "fallbackCalls=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Calls
                     + " fallbackHandled=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Handled
                     + " fallbackBailed=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Bailed
                     + " bailRunType=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailRunType
                     + " bailFont=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailFont
                     + " bailEmpty=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailEmpty
                     + " bailLong=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailLong
                     + " bailException=" + WpfLinux.Shims.PresentationCore.HbTextFallback.BailException
                     + " lastBail=\"" + WpfLinux.Shims.PresentationCore.HbTextFallback.LastBail + "\"";
            }
            catch (Exception e) { return "<IVT 读不到: " + e.GetType().Name + ": " + e.Message + ">"; }
        }
        /// <summary>宽松档计数行。命名空间 = `MS.Internal.TextFormatting`（生成物 `:37`）
        /// —— 与严格档**正好相反**，两处都必须现场读，不能照抄。</summary>
        private static string LenientDiag()
        {
            try { return MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics; }
            catch (Exception e) { return "<IVT 读不到: " + e.GetType().Name + ": " + e.Message + ">"; }
        }

        private static string BuildStamp()
        {
            try
            {
                var asm = typeof(Program).Assembly;
                return "self=" + asm.GetName().Version + " pid=" + Environment.ProcessId
                     + " tier-auto-env=" + (Environment.GetEnvironmentVariable(FallbackEnvVar) ?? "<unset>");
            }
            catch (Exception) { return "-"; }
        }

        [DllImport("libc", EntryPoint = "abort", SetLastError = false)]
        private static extern void abort();

        // =================================================================================
        //  用具
        // =================================================================================
        internal sealed class RunSlot
        {
            internal readonly int Start;
            internal readonly TextRun Run;
            internal RunSlot(int start, TextRun run) { Start = start; Run = run; }
        }

        /// <summary>脚本化的 `TextSource`：按**码元下标**交出预置 run 序列。
        ///
        /// ⚠️⚠️ **仪器缺陷自记（第一版，已抓掉；这是本探针最重要的一条自纠）**：
        ///   第一版让 `GetTextRun(cp)` **按"同一个 cp 被问第几次"依次交出 run**（`_served` 计数）。
        ///   后果：**严格档 bail 之后，宽松档在同一个 `cp` 上再问一次，拿到的是"下一个 run"
        ///   而不是原来那个 run** ⇒ 宽松档看到的第一个 run 变成了 `TextEndOfParagraph`！
        ///   **读数原样**（`--trace-source` 实测）：
        ///     `GetTextRun#1(cp=0) → TextEndOfSegment(L=1) CBR=null`
        ///     `GetTextRun#2(cp=0) → TextEndOfParagraph(L=1) CBR=null`   ← **不是被测的那个 run**
        ///   ⇒ 于是宽松档走的是"空段落 + 无 props"那条分支（`relaxedBlankParagraphs=1`、
        ///     `lastFail="空段落且没有 run properties …"`），**而不是** `D-T5` 的在册机制
        ///     （`ExtractRun` 见空 CBR ⇒ `return null` ⇒ `CollectLenient` `return false`）。
        ///   ⇒ **判决（红）照样是对的，归因是错的** —— 这正是本项目最怕的"仪器缺陷假归因"。
        ///   **修法**：`GetTextRun(cp)` 必须**幂等** —— 同一个 `cp` 问到第几次都交**同一个** run
        ///   （真实 `TextSource` 就是这样；`Length ≥ 1` 的 run 逐个消费码元，一个 cp 只属于一个 run）。
        ///   唯一**刻意**保留非幂等的用例是 `mod0`（**零宽**标记：零宽 run 不消费字符，
        ///   同一下标再问一次才拿到正文；`W17D-report.md:157` 逐字写明这是合法姿势）
        ///   ⇒ 用显式的 `StatefulZeroWidth` 开关，**不许**让它成为默认行为。
        /// </summary>
        internal sealed class ScriptedTextSource : TextSource
        {
            private readonly Dictionary<int, List<TextRun>> _at = new Dictionary<int, List<TextRun>>();
            private readonly Dictionary<int, int> _served = new Dictionary<int, int>();
            /// <summary>**只给 `mod0` 用**：允许"同一个 cp 第二次问 ⇒ 交出下一个 run"。</summary>
            internal bool StatefulZeroWidth;
            internal readonly int CpLength;
            internal int GetTextRunCalls;
            internal ScriptedTextSource(List<RunSlot> slots, int cpLength)
            {
                CpLength = cpLength;
                foreach (RunSlot s in slots)
                {
                    if (!_at.TryGetValue(s.Start, out List<TextRun> l)) { l = new List<TextRun>(); _at[s.Start] = l; }
                    l.Add(s.Run);
                }
            }
            public override TextRun GetTextRun(int cp)
            {
                ++GetTextRunCalls;
                TextRun r = new TextEndOfParagraph(1);
                if (_at.TryGetValue(cp, out List<TextRun> l))
                {
                    if (!StatefulZeroWidth) r = l[0];              // ⭐ **幂等**（默认；被测的真实姿势）
                    else
                    {
                        int n = _served.TryGetValue(cp, out int v) ? v : 0;
                        if (n < l.Count) { _served[cp] = n + 1; r = l[n]; }
                    }
                }
                if (s_trace)
                {
                    string cbr;
                    try { cbr = r.CharacterBufferReference.CharacterBuffer == null ? "CBR=null" : "CBR=非null"; }
                    catch (Exception e) { cbr = "CBR=抛" + e.GetType().Name; }
                    Console.WriteLine("D5CBR SRC  GetTextRun#" + GetTextRunCalls + "(cp=" + cp + ") → "
                                      + r.GetType().Name + "(L=" + r.Length + ") " + cbr);
                }
                return r;
            }
            public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
                => new TextSpan<CultureSpecificCharacterBufferRange>(0,
                       new CultureSpecificCharacterBufferRange(CultureInfo.InvariantCulture, CharacterBufferRange.Empty));
            public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
        }

        /// <summary>`TextRunProperties` 最小实现（本工程独立）。
        /// ⚠️ `ForegroundBrush` **必须是 `null`**，不能是 `Brushes.Black`（`PcLineOracle:126-132` 实测）：
        ///   `Brush` 的静态构造要建 HwndWrapper ⇒ 无 X 时抛 `TypeInitializationException`。
        ///   本探针**只量"有没有交出行 / 行的 Length"**，几何一概不量 ⇒ 取 `null` 零影响。</summary>
        internal sealed class ProbeRunProperties : TextRunProperties
        {
            private readonly Typeface _tf; private readonly double _em;
            internal ProbeRunProperties(Typeface tf, double em) { _tf = tf; _em = em; }
            public override Typeface Typeface => _tf;
            public override double FontRenderingEmSize => _em;
            public override double FontHintingEmSize => _em;
            public override CultureInfo CultureInfo => CultureInfo.InvariantCulture;
            public override Brush ForegroundBrush => null;
            public override Brush BackgroundBrush => null;
            public override TextDecorationCollection TextDecorations => null;
            public override TextEffectCollection TextEffects => null;
        }

        /// <summary>`TextParagraphProperties` 最小实现：全默认（`Left`/`Wrap`/无缩进），
        /// 目的 = **不让任何别的变量干扰 `D-T5` 的读数**。</summary>
        internal sealed class ProbePara : TextParagraphProperties
        {
            private readonly TextRunProperties _props;
            internal ProbePara(TextRunProperties props) { _props = props; }
            /// <summary>⭐ `--collapsible` 把它置 true ⇒ **关掉 `SimpleTextLine` 快路径**
            /// （生成物 `:546-549` 的条件是 `!settings.Pap.AlwaysCollapsible && previousLineBreak == null && lineLength <= 0`）
            /// ⇒ 逼被测的 run 走**严格档 → 宽松档 → LineServices** 那三层。
            /// 这是**机制判别器**：同一个 run 在快路径开/关下的两条读数能分开
            /// "`SimpleTextLine` 自己处理了" 与 "落进了 `D-T5`"（见报告 §②/§③）。</summary>
            internal bool ForceCollapsible;
            public override TextRunProperties DefaultTextRunProperties => _props;
            public override FlowDirection FlowDirection => FlowDirection.LeftToRight;
            public override TextAlignment TextAlignment => TextAlignment.Left;
            public override TextWrapping TextWrapping => TextWrapping.Wrap;
            public override double LineHeight => 0;
            public override bool FirstLineInParagraph => true;
            public override double Indent => 0;
            public override double ParagraphIndent => 0;
            public override bool AlwaysCollapsible => ForceCollapsible;
            public override TextDecorationCollection TextDecorations => null;
            public override TextMarkerProperties TextMarkerProperties => null;
            public override IList<TextTabProperties> Tabs => null;
        }

        /// <summary>`TextModifier` 的具体子类。基类只 sealed 了 `CharacterBufferReference`
        /// （`TextModifier.cs:25-28`，**恒为默认空 `CharacterBufferReference`** = 本缺陷的触发条件），
        /// `Length`（`TextRun.cs:82` abstract）与 `Properties`（`:89` abstract）由本类给。</summary>
        internal sealed class ProbeModifier : TextModifier
        {
            private readonly int _len; private readonly TextRunProperties _props;
            internal ProbeModifier(int len, TextRunProperties props) { _len = len; _props = props; }
            public override int Length => _len;
            public override TextRunProperties Properties => _props;
            public override TextRunProperties ModifyProperties(TextRunProperties properties) => properties;
            public override bool HasDirectionalEmbedding => false;
            public override FlowDirection FlowDirection => FlowDirection.LeftToRight;
        }
    }
}

// W22C · **`D-T6-b` 帧判据探针**（`docs/WAVE22-PREREGISTRATION.md` §3 P3 的红读数仪器）
// =====================================================================================
//   dotnet PresentationCore.Tests.dll --corpus <tab-anchor-raw.json>
//                                    [--tier lenient|strict] [--fresh-source]
//                                    [--case <id 子串>] [--all] [--json <out.json>]
//
// 【它回答什么】逐行比较**我方帧**与**真机真值帧**：
//   · 我方帧 = 该行自己的**段落系帧原点**。取法（**不依赖任何私有约定**）：
//       `GetTextBounds(a,1)` 逐下标扫描，取**最小的**、能拿到非空 `TextRunBounds` 的 `a`。
//       为什么它等于 `_lineStart`：`shim:3044-3045`
//         `int localFirst = firstTextSourceCharacterIndex - _lineStart;`
//         `if (localFirst < 0 || localFirst > _visibleLength) return new List<TextBounds>();`
//       ⇒ 只有 `a ∈ [_lineStart, _lineStart+_visibleLength]` 才非空 ⇒ **最小可用 `a` 恒 = `_lineStart`**。
//       （⚠️ 这条等价性**依赖我方"不相交 ⇒ 返回空表"这个行为**，而真机是**夹取**
//        —— `upstream …/FullTextLine.cs:1493-1499` + `CreateDegenerateBounds()` `:1443`。
//        在真机上同一个扫描**扫不出帧**（任何 `a` 都给退化 bounds）⇒ 本扫描是**我方专用**仪器。
//        故本探针**同时**用 `HbTextLine.LineStartForDiag`（`shim:3283`，internal，IVT）**交叉验证**，
//        并把"扫描 == 私有字段"的一致性当**仪器自证**逐例计数。）
//   · 真机真值帧 = `cases[].lines[].startChar`（真机臂 `tab-anchor/src/Program.cs:556` 落盘；
//     = `:443` 传进 `FormatLine(source, index, …)` 的 `index` = **绝对段落系**起点）。
//   ⇒ 两侧**同一套坐标系**（`ParaCache` 编址用的也是绝对系：`shim:4030-4044` 的 `Contains/LineAt`
//     从 `Start = cpFirst` 起按 `L.Length` 累加）—— 所以是**同系比较**，不是换算出来的。
//
// 【分母口径（纪律 39）】语料 436 例 / 615 行；本探针只判 `script == "latin"` 的
//   **288 例 / 421 行**（与 `PcLineOracle` 既有 421 判定行同口径；本探针另跑覆盖闸证明两者一致）。
//
// 【rc 词表】0 = 判定行全绿｜1 = 有红行（点名 id + 行号 + 我方帧 + 真值帧）｜
//   2 = NOINFO（语料/字体取不到、本腿一例都没被接手、**没有一行可判定**、**红族分解不自洽**）。
//   `NOINFO` **绝不读成绿**：逐行取不到帧的行单独计 `NOINFO行` 并打印。
//
// 【`#24` P2：`红行` 的**族分解**（只加强；既有列的取值/语义**一个字节都没动**）】
//   汇总行**末尾追加**两列 `帧红=<n>` `结构红=<n>`，并新增一行自证 `FRAMEPROBE 红族分解 …`。定义：
//     · **帧红**   = 红 ∧ `扫描帧 != 该行 cpFirst` ⇒ **帧原点机制本身错**（`D-T6-b` 那一族）；
//     · **结构红** = 红 ∧ `扫描帧 == 该行 cpFirst` ∧ `cpFirst != 真值 startChar`
//                    ⇒ 「**我方分行 ≠ 真机分行**」（`#22`/`#23` 已定性），**不是帧错**。
//   恒等式 `红行 == 帧红 + 结构红` 构造上成立；另设自洽闸（不成立 ⇒ rc=2，**坏仪器绝不许报绿**）。
//   ⇒ **下游判据断言 `帧红 == 0`，绝不断言 `红行 == 0`**（后者会把结构族吞进来，与 `#23` 的教训相反）。
//   ⚠️ `NOINFO行`（逐行）**恒非零**是**语料性质**：真值数组短于我方行数时，多出来的我方行**没有真值可比**
//      （`#24` 实测 101 行；同族的 `我方行数 != 真值行数 的例` = 60）⇒ 它**不是仪器缺口**，**不是** rc 判据。
//      ⇒ 故把它也**按族分解**（自证行里 `仪器族NOINFO=` / `结构族NOINFO=`）：
//        **下游判据断言 `仪器族NOINFO == 0`**（有真值却扫不出帧 = 仪器缺口，必须红），
//        而 `结构族NOINFO` 只**打印并点名口径**（不许把它当绿，也不许把它当仪器缺口）。
//      仪器级的 `NOINFO` 是 rc=2 那几条（rc=2 的探针、计数器缺失/字段解析不出、族分解不自洽）。
//
// 【它不做什么】不改任何既有文件；不写判据表；不进任何门禁。判据落地见报告 §5 的 diff 草案。
// =====================================================================================

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace MilBridge.FrameProbe
{
    /// <summary>假 TextSource：单 run `TextCharacters` → `TextEndOfParagraph`（照 oracle 宿主 `StringSource`）。
    /// **逐字抄自** `PcLineOracle/Program.cs:95-113`（同一份实测绿 421/421 的宿主姿势）。</summary>
    internal sealed class MockTextSource : TextSource
    {
        private readonly TextRunProperties _props;
        internal MockTextSource(string text, TextRunProperties props) { Text = text; _props = props; }
        internal string Text { get; }
        public override TextRun GetTextRun(int cp)
            => (cp >= 0 && cp < Text.Length)
                 ? (TextRun)new TextCharacters(Text, cp, Text.Length - cp, _props)
                 : new TextEndOfParagraph(1);
        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
            => new TextSpan<CultureSpecificCharacterBufferRange>(0,
                   new CultureSpecificCharacterBufferRange(CultureInfo.InvariantCulture, CharacterBufferRange.Empty));
        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
    }

    /// <summary>`TextRunProperties` 最小实现（照 `PcLineOracle` 的 `OraRunProperties`）。</summary>
    internal sealed class ProbeRunProperties : TextRunProperties
    {
        private readonly Typeface _tf; private readonly double _em;
        internal ProbeRunProperties(Typeface tf, double em) { _tf = tf; _em = em; }
        public override Typeface Typeface => _tf;
        public override double FontRenderingEmSize => _em;
        public override double FontHintingEmSize => _em;
        public override CultureInfo CultureInfo => CultureInfo.InvariantCulture;
        public override Brush ForegroundBrush => null;     // Brush 静态构造要 X ⇒ 必须 null（PcLineOracle 同）
        public override Brush BackgroundBrush => null;
        public override TextDecorationCollection TextDecorations => null;
        public override TextEffectCollection TextEffects => null;
    }

    /// <summary>`TextParagraphProperties` —— 与 `PcLineOracle/OraPara` **同口径**（本工程独立实现，
    /// 不借 shim 的 internal 类型；`AlwaysCollapsible` = 腿 B 层，与预登记 §3 的命令同层）。</summary>
    internal sealed class ProbePara : TextParagraphProperties
    {
        private readonly bool _tabZero, _firstLine, _alwaysCollapsible;
        private readonly double _indent, _paraIndent;
        private readonly FlowDirection _flow;
        private readonly TextRunProperties _props;
        internal ProbePara(TextRunProperties props, FlowDirection flow, bool tabZero,
                           double indent, double paraIndent, bool firstLine, bool alwaysCollapsible)
        {
            _props = props; _flow = flow; _tabZero = tabZero;
            _indent = indent; _paraIndent = paraIndent; _firstLine = firstLine;
            _alwaysCollapsible = alwaysCollapsible;
        }
        public override TextRunProperties DefaultTextRunProperties => _props;
        public override FlowDirection FlowDirection => _flow;
        public override TextAlignment TextAlignment => TextAlignment.Left;   // 语料 436/436 全 Left
        public override TextWrapping TextWrapping => TextWrapping.Wrap;
        public override double LineHeight => 0;
        public override bool FirstLineInParagraph => _firstLine;
        public override double Indent => _indent;
        public override double ParagraphIndent => _paraIndent;
        public override bool AlwaysCollapsible => _alwaysCollapsible;
        public override TextDecorationCollection TextDecorations => null;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override IList<TextTabProperties> Tabs => null;
        public override double DefaultIncrementalTab => _tabZero ? 0 : base.DefaultIncrementalTab;
    }

    internal static class Program
    {
        private const string FallbackEnvVar = "WPF_LINUX_TEXTLINE_FALLBACK";
        /// <summary>与 `PcLineOracle/Program.cs:176` **同一个面** ⇒ 读数与既有臂同层可对拍。</summary>
        private const string FontFamilyName = "Liberation Sans";

        private static IDictionary<int, ushort> s_cmap;
        private static string s_tier = "lenient";
        /// <summary>腿 A = `AlwaysCollapsible=false`（**与 oracle 语料记录的设置同口径**，
        /// `tab-anchor-raw.json` 的 `paragraphProperties.fixed` 逐字写着 `AlwaysCollapsible=false`）；
        /// 腿 B = `true`（`PcLineOracle` 的汇总腿 —— 刻意偏离 oracle 以避开 `SimpleTextLine` 快路径）。</summary>
        private static bool s_alwaysCollapsible = true;
        /// <summary>**`cpFirst != 0` 的源**（主控口径插话 ②③ 要求的必做补充读数）：
        /// 源串 = `new string('M', prefix) + caseText`，**首调下标 = prefix** ⇒ 被测段落的原点 ≠ 0。
        /// 真值帧 = `prefix + corpus.startChar`（**绝对系**，与真机 `startChar` 同一套系）。</summary>
        private static int s_prefix = 0;

        private static string F(double v) => v.ToString("F6", CultureInfo.InvariantCulture);
        private static string Show(string s)
        {
            if (s == null) return "<null>";
            var sb = new StringBuilder();
            foreach (char c in s)
            {
                if (c == '\t') sb.Append("\\t");
                else if (c == '\n') sb.Append("\\n");
                else if (c == '\r') sb.Append("\\r");
                else sb.Append(c);
            }
            return sb.ToString();
        }
        private static string Sha16(string path)
        {
            try
            {
                using (var s = SHA256.Create())
                using (var fs = File.OpenRead(path))
                    return Hex(s.ComputeHash(fs)).Substring(0, 16);
            }
            catch (Exception e) { return "<" + e.GetType().Name + ">"; }
        }
        private static string Hex(byte[] b)
        {
            var sb = new StringBuilder(b.Length * 2);
            foreach (byte x in b) sb.Append(x.ToString("x2"));
            return sb.ToString();
        }

        // ---- IVT：两档的**来源自证**（一个名额，两处命名空间不同 —— 必须现场读，不能照抄） ----
        private static string StrictEnabled()
        {
            try { return WpfLinux.Shims.PresentationCore.HbTextFallback.Enabled ? "true" : "false"; }
            catch (Exception e) { return "<IVT 读不到 " + e.GetType().Name + ">"; }
        }
        private static long StrictHandled() { try { return WpfLinux.Shims.PresentationCore.HbTextFallback.Handled; } catch (Exception) { return -1; } }
        private static long RelaxedHandled() { try { return ParseCounter("relaxedHandled="); } catch (Exception) { return -1; } }
        private static string StrictDiag()
        {
            try
            {
                return "fallbackCalls=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Calls
                     + " fallbackHandled=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Handled
                     + " fallbackBailed=" + WpfLinux.Shims.PresentationCore.HbTextFallback.Bailed
                     + " lastBail=\"" + WpfLinux.Shims.PresentationCore.HbTextFallback.LastBail + "\"";
            }
            catch (Exception e) { return "<IVT 读不到 " + e.GetType().Name + ">"; }
        }
        private static string RelaxedDiag()
        {
            try { return MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics; }
            catch (Exception e) { return "<IVT 读不到: " + e.GetType().Name + ": " + e.Message + ">"; }
        }
        private static int ParseCounter(string key)
        {
            string d = RelaxedDiag();
            int i = d.IndexOf(key, StringComparison.Ordinal);
            if (i < 0) return -1;
            i += key.Length;
            int j = i; while (j < d.Length && char.IsDigit(d[j])) ++j;
            return int.TryParse(d.Substring(i, j - i), out int v) ? v : -1;
        }
        private static string StrictCacheInfo()
        {
            try { return WpfLinux.Shims.PresentationCore.HbTextFallback.CacheInfo(); }
            catch (Exception e) { return "<IVT 读不到 " + e.GetType().Name + ">"; }
        }

        // ---- 帧取法 ----
        private static IList<TextBounds> Bounds(TextLine line, int arg)
        {
            try { return line.GetTextBounds(arg, 1); } catch (Exception) { return null; }
        }
        /// <summary>与既有判据**同一条件**（`PcLineOracle`:1326）：拿不到 `TextRunBounds` ⇔ 该下标与本行不相交。</summary>
        private static bool HasTrb(IList<TextBounds> b)
            => b != null && b.Count > 0 && b[0].TextRunBounds != null && b[0].TextRunBounds.Count > 0;
        /// <summary>扫描帧原点 = 最小的、能取到 `TextRunBounds` 的段落系下标；−1 = 扫不到（NOINFO）。</summary>
        private static int FrameScan(TextLine line, int hi)
        {
            for (int a = 0; a <= hi; ++a) if (HasTrb(Bounds(line, a))) return a;
            return -1;
        }
        /// <summary>私有字段交叉验证（IVT: `internal int LineStartForDiag => _lineStart;` `shim:3283`）。</summary>
        private static int LineStartViaIvt(TextLine line)
        {
            var hb = line as WpfLinux.Shims.PresentationCore.HbTextLine;
            if (hb == null) return -999;
            try { return hb.LineStartForDiag; } catch (Exception) { return -998; }
        }
        /// <summary>取不到就反射（双保险：IVT 名额若哪天被撤，仪器仍然能自证）。</summary>
        private static int LineStartViaReflect(TextLine line)
        {
            try
            {
                FieldInfo fi = line.GetType().GetField("_lineStart", BindingFlags.Instance | BindingFlags.NonPublic);
                if (fi == null) return -997;
                object v = fi.GetValue(line);
                return v == null ? -996 : Convert.ToInt32(v);
            }
            catch (Exception) { return -995; }
        }

        private static int Main(string[] argv)
        {
            try { Console.OutputEncoding = Encoding.UTF8; } catch (Exception) { }

            string corpus = null, jsonOut = null, caseFilter = null;
            bool freshSource = false, printAll = false;
            for (int i = 0; i < argv.Length; ++i)
            {
                if (argv[i] == "--corpus" && i + 1 < argv.Length) corpus = argv[++i];
                else if (argv[i] == "--tier" && i + 1 < argv.Length) s_tier = argv[++i];
                else if (argv[i] == "--json" && i + 1 < argv.Length) jsonOut = argv[++i];
                else if (argv[i] == "--case" && i + 1 < argv.Length) caseFilter = argv[++i];
                else if (argv[i] == "--fresh-source") freshSource = true;
                else if (argv[i] == "--all") printAll = true;
                else if (argv[i] == "--prefix" && i + 1 < argv.Length)
                {
                    if (!int.TryParse(argv[++i], NumberStyles.Integer, CultureInfo.InvariantCulture, out s_prefix) || s_prefix < 0)
                    { Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=--prefix 取值非法"); return 2; }
                }
                else if (argv[i] == "--leg" && i + 1 < argv.Length)
                {
                    string lg = argv[++i];
                    if (lg == "a") s_alwaysCollapsible = false;
                    else if (lg == "b") s_alwaysCollapsible = true;
                    else { Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=--leg 取值非法：" + lg); return 2; }
                }
            }

            if (s_tier != "strict" && s_tier != "lenient")
            {
                Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=--tier 取值非法：" + s_tier + "（只接受 strict|lenient）");
                return 2;
            }
            if (corpus == null || !File.Exists(corpus))
            {
                Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=语料不存在：" + (corpus ?? "<未给>"));
                return 2;
            }

            // ---------- 0) 档位转向：**拿任何读数之前**先钉死，并读回产品自己的开关自证 ----------
            string ambient = Environment.GetEnvironmentVariable(FallbackEnvVar);
            Console.WriteLine("FRAMEPROBE lane=W22C（`#22` §3 P3：`D-T6-b` 帧判据 + 红读数）");
            Console.WriteLine("FRAMEPROBE 时间=" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss zzz", CultureInfo.InvariantCulture)
                              + " kernel=" + ReadTrim("/proc/sys/kernel/osrelease")
                              + " loadavg=" + ReadTrim("/proc/loadavg")
                              + " mem_available=" + MemAvailableKiB() + "KiB");
            Console.WriteLine("FRAMEPROBE TierSelect 请求档=" + s_tier + "｜臂动作**之前**环境里的 " + FallbackEnvVar + " = "
                              + (ambient ?? "<null>"));
            if (s_tier == "strict") Environment.SetEnvironmentVariable(FallbackEnvVar, null);
            else Environment.SetEnvironmentVariable(FallbackEnvVar, "0");
            Console.WriteLine("FRAMEPROBE TierSelect 动作之后 " + FallbackEnvVar + " = "
                              + (Environment.GetEnvironmentVariable(FallbackEnvVar) ?? "<null>"));
            Console.WriteLine("FRAMEPROBE TierSelect 产品侧 HbTextFallback.Enabled = " + StrictEnabled()
                              + " ⇒ **本腿生效档** = " + (StrictEnabled() == "true" ? "严格档 HbTextFallback" : "宽松档 WpfLinuxLenientTextFallback"));
            Console.WriteLine("FRAMEPROBE prefix=" + s_prefix
                              + (s_prefix > 0 ? "（源串 = 'M'×" + s_prefix + " + 用例文本；**首调下标 = " + s_prefix
                                 + " ⇒ 段落原点 ≠ 0**；真值帧 = prefix + corpus.startChar）" : "（源串 = 用例文本；首调下标 = 0）"));
            Console.WriteLine("FRAMEPROBE leg=" + (s_alwaysCollapsible ? "B（AlwaysCollapsible=true；偏离 oracle 语料记录的 false）"
                              : "A（AlwaysCollapsible=false；**与 oracle 语料同口径**）"));
            Console.WriteLine("FRAMEPROBE freshSource=" + (freshSource ? 1 : 0)
                              + "（1 = 每次 FormatLine 都新建 TextSource ⇒ 严格档 `ParaCache` 的 `ReferenceEquals(c.Source,…)` 必不命中）");

            // ---------- 1) 被测件自证：**两份** sha16（本机副本 + 权威路径） ----------
            string localPc = Path.Combine(AppContext.BaseDirectory, "PresentationCore.dll");
            string authPc = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll";
            string pcBefore = Sha16(localPc);
            Console.WriteLine("FRAMEPROBE 被测件 本机副本=" + localPc + " sha16=" + pcBefore
                              + "｜权威路径=" + authPc + " sha16=" + Sha16(authPc));

            byte[] raw = File.ReadAllBytes(corpus);
            Console.WriteLine("FRAMEPROBE 语料=" + corpus + " sha16=" + Hex(SHA256.Create().ComputeHash(raw)).Substring(0, 16)
                              + " bytes=" + raw.Length);

            // ---------- 2) 字体 + 覆盖闸来源（与 PcLineOracle 同口径） ----------
            Typeface tf = null;
            try { tf = new Typeface(new FontFamily(FontFamilyName), FontStyles.Normal, FontWeights.Normal, FontStretches.Normal); }
            catch (Exception e) { Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=Typeface 构造抛 " + e.GetType().Name); return 2; }
            GlyphTypeface gt = null;
            if (tf != null) { try { tf.TryGetGlyphTypeface(out gt); } catch (Exception) { } }
            if (gt == null)
            {
                Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=字体面解析失败（family=" + FontFamilyName + "）");
                return 2;
            }
            try { s_cmap = gt.CharacterToGlyphMap; } catch (Exception) { }
            if (s_cmap == null)
            {
                Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=取不到已解析 GlyphTypeface 的 CharacterToGlyphMap");
                return 2;
            }
            Console.WriteLine("FRAMEPROBE font=family=" + FontFamilyName + " → " + gt.FontUri.LocalPath
                              + "#" + gt.FaceIndex + " cmap.count=" + s_cmap.Count);

            JsonDocument doc = JsonDocument.Parse(raw);
            JsonElement cases = doc.RootElement.GetProperty("cases");

            TextFormatter fmt;
            try { fmt = TextFormatter.Create(); }
            catch (Exception e)
            {
                Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=TextFormatter.Create() 抛 " + e.GetType().Name + ": " + e.Message);
                return 2;
            }

            // ---------- 3) 主循环 ----------
            int casesSeen = 0, casesJudged = 0, casesSkippedScript = 0, casesSkippedCov = 0, casesFiltered = 0;
            int linesJudged = 0, redLines = 0, greenLines = 0, noInfoLines = 0, redCases = 0;
            int truthNonZero = 0, scanVsIvtMismatch = 0, cpFirstVsTruthMismatch = 0, driveFail = 0;
            // ★ `#24` P2：`NOINFO行` **也要按族分解**（`NOINFO` 不许算绿 —— 必须先能分辨它是**仪器缺口**
            //   还是**语料性质**，否则「NOINFO≠0 ⇒ 判据永远红」与「NOINFO≠0 被当绿」两种错都会发生）：
            //     · **仪器族** = 该行有真值、但 `frame < 0`（扫描取不到帧）⇒ **仪器缺口**，判据必须红；
            //     · **结构族** = 该行**根本没有真值可比**（真值数组短于我方行数 ⇒ 多出来的我方行）
            //                   ⇒ 与 `我方行数 != 真值行数 的例` 同源，**不是仪器缺口**。
            int noInfoNoFrame = 0, noInfoNoTruth = 0;
            // ★ `#24` P2 新增（**只加强**：既有列的语义/取值一个字节都没动）——把「红行」**按族分解**。
            //   为什么必须分解：`红行` 混着两种**完全不同的病**，而下游判据只能读 `红行` ⇒ 会张冠李戴。
            //     · **帧族红** = 红 ∧ `frame != index`（我方帧 ≠ **我方自己这行**的段落系起点）
            //         ⇒ 帧原点机制本身错（`D-T6-b` 那一族）。
            //     · **结构族红** = 红 ∧ `frame == index`（我方帧 == 我方自己的起点，但该起点 ≠ 真机 startChar）
            //         ⇒ 是「**我方分行 ≠ 真机分行**」（`#22`/`#23` 已定性），**不是帧错**。
            //   恒等式（构造上成立，无需外部证明）：`红行 == 帧红 + 结构红`，下面另有自洽计数器兜底。
            int frameRedLines = 0, structRedLines = 0;
            // 分母（纪律 39）：`#23` 的「帧族红 = 0/418」里的 418 = **可比子集** =
            //   我方 cpFirst == 真值 startChar 的行（421 − 3）。此处按同一口径单独计一次。
            int frameRedComparable = 0;
            int tierStrict = 0, tierLenient = 0, tierNone = 0;
            int outOfRangeEmpty = 0, outOfRangeProbed = 0, casesLineCountDiff = 0, truthNotJudged = 0;
            int hostReadEmpty = 0;
            var redIds = new List<string>();
            var json = new StringBuilder();
            json.Append("{\"tier\":\"").Append(s_tier).Append("\",\"freshSource\":").Append(freshSource ? "true" : "false")
                .Append(",\"corpusSha16\":\"").Append(Hex(SHA256.Create().ComputeHash(raw)).Substring(0, 16)).Append("\",\"lines\":[");
            bool firstJson = true;

            foreach (JsonElement c in cases.EnumerateArray())
            {
                string id = c.GetProperty("id").GetString();
                ++casesSeen;
                if (caseFilter != null && id.IndexOf(caseFilter, StringComparison.Ordinal) < 0) { ++casesFiltered; continue; }
                string script = c.GetProperty("script").GetString();
                if (script != "latin") { ++casesSkippedScript; continue; }   // 分母口径（纪律 39）

                string text = c.GetProperty("text").GetString();
                double pw = c.GetProperty("paragraphWidthDip").GetDouble();
                bool rtl = c.GetProperty("flowDirection").GetString() == "RightToLeft";
                bool tabZero = c.GetProperty("incrementalTabArm").GetString() == "DefaultIncrementalTab=0";
                bool firstLine = c.GetProperty("firstLineInParagraph").GetBoolean();
                double ind = c.GetProperty("indentDip").GetDouble();
                double pi = c.GetProperty("paragraphIndentDip").GetDouble();

                // 覆盖闸：面缺字形 ⇒ 不可比（与 PcLineOracle:734-748 同口径）
                int missing = 0;
                foreach (char ch in text)
                {
                    if (ch == '\t' || ch == '\n' || ch == '\r') continue;
                    if (!s_cmap.TryGetValue(ch, out ushort g) || g == 0) ++missing;
                }
                if (missing > 0) { ++casesSkippedCov; continue; }

                JsonElement exp = c.GetProperty("lines");
                string srcText = (s_prefix > 0) ? (new string('M', s_prefix) + text) : text;
                int firstIndex = s_prefix;      // ★ 主控 ②③：这一段在 source 里的**原点**
                var props = new ProbeRunProperties(tf, c.GetProperty("emSizeDip").GetDouble());
                var para = new ProbePara(props, rtl ? FlowDirection.RightToLeft : FlowDirection.LeftToRight,
                                         tabZero, ind, pi, firstLine, s_alwaysCollapsible);

                long sH0 = StrictHandled(), lH0 = RelaxedHandled();
                TextSource src = new MockTextSource(srcText, props);
                int index = firstIndex, guard = 0, li = 0;
                TextLineBreak brk = null;
                int caseRed = 0, caseJudged = 0;
                var caseLens = new List<int>();
                var caseCpFirst = new List<int>();
                string stopWhy = null;

                while (index < srcText.Length && guard++ < 64)
                {
                    TextLine line;
                    try
                    {
                        if (freshSource) src = new MockTextSource(srcText, props);   // ★ 缓存专项：必不命中
                        line = fmt.FormatLine(src, index, pw, para, brk);
                    }
                    catch (Exception e) { stopWhy = "FormatLine 抛 " + e.GetType().Name + ": " + e.Message; break; }
                    if (line == null) { stopWhy = "FormatLine 返回 null"; break; }
                    int len = (int)line.Length;
                    if (len <= 0) { stopWhy = "0 长行（防死循环）"; break; }

                    // 真值：本行（li）的 startChar（绝对段落系）
                    int truth = -1, truthLines = exp.GetArrayLength();
                    {
                        int k = 0;
                        foreach (JsonElement E in exp.EnumerateArray())
                        {
                            if (k++ != li) continue;
                            truth = s_prefix + E.GetProperty("startChar").GetInt32();   // 绝对系真值
                            break;
                        }
                    }

                    // 扫描上界 = cpFirst+16（既有臂 `FrameScan` 用 cpFirst+4）：本实现的 `_lineStart`
                    // 只可能是 0 或 ≤ cpFirst 的绝对起点 ⇒ 界内必命中；若被界截断，`扫描 vs IVT` 自证计数器会红。
                    // ★ v2：**真机宿主同款读法** —— 真机臂 `tab-anchor/src/Program.cs:512-514` 就是
                    //   `int gi = lineStart + i; line.GetTextBounds(gi, 1)`，`lineStart` = 传进 `FormatLine`
                    //   的那个**绝对**下标。此处取 i=0 ⇒ `GetTextBounds(cpFirst, 1)`。
                    //   它量的是**消费者看得见的东西**：拿不到 `TextRunBounds` ⇒ 宿主读到空（我方）
                    //   或退化 bounds（真机，`FullTextLine.cs:1493-1501` + `CreateDegenerateBounds` `:1443`）。
                    bool hostReadOk = HasTrb(Bounds(line, index));
                    if (!hostReadOk) ++hostReadEmpty;
                    int frame = FrameScan(line, Math.Max(index + 16, 16));
                    int ivt = LineStartViaIvt(line);
                    int refl = LineStartViaReflect(line);
                    if (ivt != frame) ++scanVsIvtMismatch;
                    if (truth >= 0)
                    {
                        ++linesJudged; ++caseJudged;
                        if (truth > 0) ++truthNonZero;
                        if (index != truth) ++cpFirstVsTruthMismatch;
                        bool red = (frame != truth);
                        if (frame < 0) { ++noInfoLines; ++noInfoNoFrame; red = true; }
                        if (red) { ++redLines; ++caseRed; }
                        else ++greenLines;
                        // ★ `#24` P2：红行**按族分解**（只增计数，不碰上面任何一列的取值）
                        if (red)
                        {
                            if (frame != index) { ++frameRedLines; if (index == truth) ++frameRedComparable; }
                            else ++structRedLines;
                        }
                        if (red && redIds.Count < 400)
                            redIds.Add("FRAMEPROBE RED " + id + " 行#" + li + " 我方帧(扫描)=" + (frame < 0 ? "无" : frame.ToString())
                                       + " 我方帧(_lineStart)=" + ivt + "(反射 " + refl + ")"
                                       + " 真值帧(startChar)=" + truth + " 我方cpFirst=" + index
                                       + " Length=" + len + " 行类型=" + line.GetType().Name);
                        if (red || printAll || s_prefix > 0)
                            Console.WriteLine("FRAMEPROBE LINE " + id + " 行#" + li
                                              + " 真机读法(cpFirst=" + index + ",1)=" + (hostReadOk ? "非空" : "**空**")
                                              + " 我方帧(扫描)=" + (frame < 0 ? "无" : frame.ToString())
                                              + " 我方帧(_lineStart)=" + ivt + " 真值帧=" + truth
                                              + " 判=" + (red ? "红" : "绿") + " cpFirst=" + index
                                              + " Length=" + len + " 真值行数=" + truthLines);
                        if (!firstJson) json.Append(',');
                        firstJson = false;
                        json.Append("{\"id\":\"").Append(id).Append("\",\"line\":").Append(li)
                            .Append(",\"frame\":").Append(frame).Append(",\"lineStart\":").Append(ivt)
                            .Append(",\"truth\":").Append(truth).Append(",\"cpFirst\":").Append(index)
                            .Append(",\"length\":").Append(len)
                            .Append(",\"hostReadOk\":").Append(hostReadOk ? "true" : "false")
                            .Append(",\"red\":").Append(red ? "true" : "false").Append('}');
                    }
                    else { ++noInfoLines; ++noInfoNoTruth; }

                    caseLens.Add(len);
                    caseCpFirst.Add(index);
                    brk = line.GetTextLineBreak();
                    index += len;
                    ++li;
                }

                // ---- 不相交/越界读法的现场读数（真机是**夹取**，我方**返回空表**）----
                //  取几条能判定的行，问一个**明显不相交**的段落系下标（-1 与 text.Length+7）：
                //  我方返回空表（Count=0）；真机在 `FullTextLine.cs:1493-1499` 把它**夹**进 [_cpFirst, …]
                //  ⇒ 真机永不因"不相交"给空表。此读数只为**坐实两侧行为差异**，不参与帧判据。
                if (caseJudged > 0)
                {
                    ++outOfRangeProbed;
                    try
                    {
                        TextSource s2 = new MockTextSource(srcText, props);
                        TextLine l2 = fmt.FormatLine(s2, firstIndex, pw, para, null);
                        if (l2 != null)
                        {
                            IList<TextBounds> bNeg = l2.GetTextBounds(firstIndex - 1, 1);   // 与首行不相交
                            IList<TextBounds> bFar = l2.GetTextBounds(srcText.Length + 7, 1);
                            if ((bNeg == null || bNeg.Count == 0) && (bFar == null || bFar.Count == 0)) ++outOfRangeEmpty;
                        }
                    }
                    catch (Exception) { }
                }

                string prov = "none";
                long dS = StrictHandled() - sH0, dL = RelaxedHandled() - lH0;
                if (dS < 0 || dL < 0) prov = "none";
                else if (dS > 0) prov = "strict";
                else if (dL > 0) prov = "lenient";
                if (prov == "strict") ++tierStrict; else if (prov == "lenient") ++tierLenient; else ++tierNone;

                if (li < exp.GetArrayLength()) truthNotJudged += exp.GetArrayLength() - li;
                if (caseJudged > 0) { ++casesJudged; if (caseRed > 0) ++redCases; }
                // ⚠️ 行数不一致**无条件**印：它是"我方分行 != 真机分行"的现场，
                //    而既有臂按**真值数组**迭代 ⇒ 结构性看不到多出来的行（纪律 41②）。
                if (li != exp.GetArrayLength())
                {
                    ++casesLineCountDiff;
                    if (true)
                        Console.WriteLine("FRAMEPROBE LINECOUNT " + id + " 我方行数=" + li + " 真值行数=" + exp.GetArrayLength()
                                          + " text=[" + Show(text) + "] pw=" + F(pw) + " I=" + F(ind) + " PI=" + F(pi)
                                          + " tab0=" + (tabZero ? 1 : 0) + " 我方各行长=[" + string.Join(",", caseLens) + "]"
                                          + " 真值各行长=[" + TruthLens(exp) + "]");
                }
                if (caseRed > 0 || printAll || s_prefix > 0)
                    Console.WriteLine("FRAMEPROBE CASE " + id + " 首调cpFirst=" + firstIndex
                                      + " 我方各行cpFirst=[" + string.Join(",", caseCpFirst) + "]"
                                      + " 真值各行startChar(绝对)=[" + TruthStarts(exp, s_prefix) + "]"
                                      + " 行数我方=" + li + " 真值=" + exp.GetArrayLength()
                                      + " 判定行=" + caseJudged + " 红行=" + caseRed
                                      + " 接手档=" + prov + "（Δ严格Handled=" + dS + " Δ宽松Handled=" + dL + "）"
                                      + (stopWhy != null ? " ⚠️驱动中断：" + stopWhy : ""));
                if (stopWhy != null) ++driveFail;
            }

            json.Append("]}");
            if (jsonOut != null) { try { File.WriteAllText(jsonOut, json.ToString()); } catch (Exception e) { Console.WriteLine("FRAMEPROBE ⚠️ json 写失败 " + e.GetType().Name); } }

            Console.WriteLine();
            foreach (string r in redIds) Console.WriteLine(r);
            Console.WriteLine("FRAMEPROBE 汇总 tier=" + s_tier + " leg=" + (s_alwaysCollapsible ? "B" : "A")
                              + " freshSource=" + (freshSource ? 1 : 0)
                              + " 判定行=" + linesJudged + " 红行=" + redLines + " 绿行=" + greenLines
                              + " NOINFO行=" + noInfoLines + " 红例=" + redCases
                              + " 判定例=" + casesJudged + " 真值非零行=" + truthNonZero
                              // ★ `#24` P2 新增两列（**追加在既有列之后** ⇒ 上游读 `红行=`/`判定行=` 的
                              //   下游一个字节都不受影响；`#23` 的读数表与 `红行=` 逐字对照仍然成立）。
                              + " 帧红=" + frameRedLines + " 结构红=" + structRedLines);
            Console.WriteLine("FRAMEPROBE 口径 语料例=" + casesSeen + "｜非latin跳过例=" + casesSkippedScript
                              + "｜覆盖闸跳过例=" + casesSkippedCov + "｜--case 过滤掉=" + casesFiltered
                              + "（分母口径 = script==latin 的 288 例 / 421 行）");
            Console.WriteLine("FRAMEPROBE 仪器自证 扫描帧 vs _lineStart(IVT) 不一致行=" + scanVsIvtMismatch
                              + "｜我方 cpFirst vs 真值 startChar 不一致行=" + cpFirstVsTruthMismatch
                              + "｜驱动中断例=" + driveFail
                              + "｜**我方行数 != 真值行数 的例=" + casesLineCountDiff + "**"
                              + "｜**真值行没有对应我方行的（未判真值行）=" + truthNotJudged + "**"
                              + "｜**真机读法 GetTextBounds(cpFirst,1) 读到空的行=" + hostReadEmpty + "**");
            Console.WriteLine("FRAMEPROBE 越界读法现场 探了=" + outOfRangeProbed + " 例，其中 GetTextBounds(-1,1) 与 (+7) **都返回空表**的=" + outOfRangeEmpty
                              + "（真机在 FullTextLine.cs:1493-1499 **夹取**，不返回空表）");
            Console.WriteLine("FRAMEPROBE 层级来源 严格档接手例=" + tierStrict + " 宽松档接手例=" + tierLenient + " 两档都没接手=" + tierNone);
            // ★ `#24` P2：红行**族分解**的机器可读自证（新行，既有行一字未改）。
            //   自洽 = 「红行 == 帧红 + 结构红」+「帧红(可比子集) ≤ 帧红」。不自洽 ⇒ 仪器坏了 ⇒ 必出 NOINFO（见下面 rc 段）。
            Console.WriteLine("FRAMEPROBE 红族分解 帧红=" + frameRedLines + " 结构红=" + structRedLines
                              + " 红行=" + redLines + " 自洽=" + (((frameRedLines + structRedLines) == redLines
                                  && frameRedComparable <= frameRedLines) ? 1 : 0)
                              + " 帧红可比分母=" + (linesJudged - cpFirstVsTruthMismatch) + " 帧红可比子集=" + frameRedComparable
                              + " 仪器族NOINFO=" + noInfoNoFrame + " 结构族NOINFO=" + noInfoNoTruth
                              + " NOINFO行=" + noInfoLines
                              + "（帧红 = 红 ∧ 帧 != 我方cpFirst；结构红 = 红 ∧ 帧 == 我方cpFirst ⇒ 我方分行 != 真机分行；"
                              + "NOINFO：仪器族 = 有真值却扫不到帧，结构族 = 该行无真值可比）");
            Console.WriteLine("FRAMEPROBE 严格档计数 " + StrictDiag());
            Console.WriteLine("FRAMEPROBE 严格档缓存 " + StrictCacheInfo());
            Console.WriteLine("FRAMEPROBE 宽松档计数 " + RelaxedDiag());
            Console.WriteLine("FRAMEPROBE 被测件 本机副本 sha16 前=" + pcBefore + " 后=" + Sha16(localPc)
                              + "｜权威路径 后=" + Sha16(authPc));

            if (linesJudged == 0)
            {
                Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=**没有一行可判定**（判定行=0）⇒ 不许读成绿");
                return 2;
            }
            if (tierNone == casesJudged && casesJudged > 0)
            {
                Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=**两档接管计数增量都为 0**（正控失败）⇒ 哪一层接手的不可判定");
                return 2;
            }
            if ((frameRedLines + structRedLines) != redLines || frameRedComparable > frameRedLines)
            {
                // ★ `#24` P2：族分解自洽性 —— 构造上恒真；一旦不成立说明**仪器自己坏了**
                //   （计数点被改动/新增了未记账的红分支）⇒ `NOINFO`，**绝不**让坏仪器报绿。
                Console.WriteLine("FRAMEPROBE_EXIT=NOINFO rc=2 原因=**红族分解不自洽**（帧红 " + frameRedLines
                                  + " + 结构红 " + structRedLines + " != 红行 " + redLines + "）⇒ 仪器不可信");
                return 2;
            }
            if (redLines > 0)
            {
                Console.WriteLine("FRAMEPROBE_EXIT=RED rc=1 原因=" + redLines + " / " + linesJudged + " 判定行的**帧**与真机 startChar 不等");
                return 1;
            }
            Console.WriteLine("FRAMEPROBE_EXIT=GREEN rc=0 原因=" + linesJudged + " / " + linesJudged + " 判定行的帧 == 真机 startChar");
            return 0;
        }

        /// <summary>真值各行 `startChar`（+ prefix ⇒ 绝对系）。</summary>
        private static string TruthStarts(JsonElement exp, int prefix)
        {
            var l = new List<string>();
            foreach (JsonElement E in exp.EnumerateArray()) l.Add((prefix + E.GetProperty("startChar").GetInt32()).ToString());
            return string.Join(",", l);
        }

        /// <summary>真值各行 `lengthWithNewline`（用于行数不一致时的现场对拍）。</summary>
        private static string TruthLens(JsonElement exp)
        {
            var l = new List<string>();
            foreach (JsonElement E in exp.EnumerateArray()) l.Add(E.GetProperty("lengthWithNewline").GetInt32().ToString());
            return string.Join(",", l);
        }

        private static string ReadTrim(string path)
        {
            try { return File.ReadAllText(path).Trim(); } catch (Exception e) { return "<" + e.GetType().Name + ">"; }
        }
        private static string MemAvailableKiB()
        {
            try
            {
                foreach (string l in File.ReadAllLines("/proc/meminfo"))
                    if (l.StartsWith("MemAvailable:", StringComparison.Ordinal))
                        return l.Substring(13).Replace("kB", "").Trim();
            }
            catch (Exception) { }
            return "?";
        }
    }
}

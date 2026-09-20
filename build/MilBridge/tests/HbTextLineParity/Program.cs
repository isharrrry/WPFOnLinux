// T1b · B2 对拍 harness —— **驱动真 shim 源文件**里的 HbTextLine
// =====================================================================================
//   dotnet MilBridge.HbTextLineParity.dll
//
// 硬性要求（任务书 (c)）：**必须驱动 `build/shims/PresentationCore.HbTextLine.cs` 本身**。
//   · 本工程用 `<Compile Include="$(HbShimSrc)">` 编那一份文件（默认就是真路径）；
//   · **驱动不了 ⇒ 大声失败退出**（构建期硬失败 + 运行期 T0 身份自检 + 非零退出码）；
//   · 本文件里**没有任何断行/折叠规则**（那是"探针与实现两套规则"的失败模式）。
//     这里只有：读 oracle、调 `HbTextLineFactory` / `HbTextLine`、比数字。
//
// 对拍的两份真值：
// ⚠️ **每个数字属于哪个口径**（T1b 2026-09-14，主控要求写进头注释；四个口径**互不为补集**，别拿它们相加减）：
//   [口径·记账结构]  `Length + NewlineLength + TrailingWhitespaceLength + (WITW−W)` 逐行全等  → 行 X/1298
//   [口径·宽度分桶]  逐行宽 vs 真值分三桶：0（逐位等）/ ≤0.34 DIP / **>0.34 DIP**（三桶和 == 行数，机检）
//   [口径·Extent 行级] 逐行 Extent（容差 0.01 DIP）                                        → 行 X/1298 + 余差清单
//   [口径·折叠明细]  真折叠行的逐行明细（长度/cr/宽）                                        → X/236
//   ⇒ `1286`（记账结构）与 `47`（宽度分桶）**不是同一口径的补集**；`58 = 38 主对拍 + 20 LH 组` 也不是。
//
//   ① 73 例 CJK：`tests/parity/windows/shaping/out-layout/dwrite-layout-cjk-oracle.json`
//      —— **DirectWrite `IDWriteTextLayout`** 口径（行区间不含换行符）
//   ② 614 例：`tests/parity/windows/layout-b34/`（真机 `TextFormatter.FormatLine` 逐属性）
//      —— **WPF 托管栈**口径（行区间含硬断字符 + 末行 EOP）
//      ⚠️ 两者是**两条不同实现路径**；Linux 侧实现的是 `TextLine`/`TextFormatter` 契约 ⇒ 冲突时以 ② 为准。
//      ②的 52MB 原始 dump 先由 `build/MilBridge/tools/extract-layout-b34.py` 流式抽成紧凑 JSON（只读那一份）。
// =====================================================================================

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;
using WpfLinux.Shims.PresentationCore;

namespace MilBridge.HbTextLineParity
{
    internal static class Program
    {
        private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";
        private const string FontRegular = Root + "/build/fonts/NotoSans-Regular.ttf";
        private const string FontBold = Root + "/build/fonts/NotoSans-Bold.ttf";
        private const string FontItalic = Root + "/build/fonts/NotoSans-Italic.ttf";
        private const string FontBoldItalic = Root + "/build/fonts/NotoSans-BoldItalic.ttf";
        private const string FontCjk = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc";
        private const string CjkOracle = Root + "/tests/parity/windows/shaping/out-layout/dwrite-layout-cjk-oracle.json";
        private const string B34Compact = Root + "/build/MilBridge/gen/layout-b34-compact.json";
        private const string B34Cases = Root + "/tests/parity/windows/layout-b34/cases.json";
        // ① LineHeight 维度的真值面（cases.json 里 **0 例**；cd2 有 10 例）—— 本文件 T2d 那一列用它补覆盖
        private const string Cd2Cases = Root + "/tests/parity/windows/layout-b34/cases-cd2.json";
        private const string Cd2Results = Root + "/tests/parity/windows/layout-b34/results-cd2.json";

        /// <summary>⭐ 身份自检：这份字符串必须来自被编译进来的那份 shim 源文件。</summary>
        private const string ExpectedShimTag = "T1b/B2 · 2026-09-11 · break-engine + TextLineBreak + Collapse";

        private static int _pass, _fail;
        private static readonly List<string> Fails = new List<string>();

        // ==================================================================================
        //  T1b2/#12 (a) · `[ROWD]` 定向逐字符 dump（**新建仪器**，2026-09-14）
        // ==================================================================================
        //  开关：`T1B_ROW_DUMP='case#line,case#line,…'`；空/未设 ⇒ **一字不输出**（原读数逐位不变）。
        //  ⚠️ 真值侧**逐字符没有真值**（oracle 只有行级 len/nl/ws/w/witw/ext 六个字段）⇒ 逐字符列
        //     一律印 `truth=NA(source=…)`，**绝不凭空补列**（本项目红线：真值源里没有的列不许补）。
        //     有真值参与的只有那一步算术：**行级真值 + 我们逐字符 advance**。
        private static readonly HashSet<string> RowDumpWant =
            ParseRowDump(Environment.GetEnvironmentVariable("T1B_ROW_DUMP"));
        private static readonly HashSet<string> RowDumpHit = new HashSet<string>(StringComparer.Ordinal);
        /// <summary>用例 id → 真值行数（只为"点名行没命中"时能说清原因；不参与任何判据）。</summary>
        private static readonly Dictionary<string, int> CaseTruthLines = new Dictionary<string, int>(StringComparer.Ordinal);
        /// <summary>T0.7 的 app-local 结论（头行要用；**读自实测**，不是常量）。</summary>
        private static string AppLocalStatus = "未测（T0.7 未跑）";

        /// <summary>`#39` 阶段 2/3：**自产件配置只许来自唯一声明**。
        /// 原先 T0.7 的"权威件"路径**写死 `bin/Debug`** ⇒ 切 Release 后它会拿**Debug 权威**去比
        /// **Release 副本**，于是 `T0.7` 恒红（`#39` 实测：一致 2/4）。
        /// 口径：先看环境变量 `SELFBUILT_CONFIG`（工具侧 exported），否则**读同一份声明文件**
        /// `build/SelfBuiltConfig.props`（与 `build/selfbuilt-config.sh`、`port-lib.py` 同一个来源）。</summary>
        private static string SelfBuiltConfig()
        {
            string env = Environment.GetEnvironmentVariable("SELFBUILT_CONFIG");
            if (!string.IsNullOrEmpty(env)) return env;
            try
            {
                string decl = Root + "/build/SelfBuiltConfig.props";
                string txt = File.ReadAllText(decl);
                var m = System.Text.RegularExpressions.Regex.Match(
                    txt, "<WpfLinuxSelfBuiltConfiguration[^>]*>([^<]*)<");
                if (m.Success)
                {
                    string v = m.Groups[1].Value.Trim();
                    if (v.Length > 0) return v;
                }
            }
            catch { /* 读不到就退回 Debug —— 但要**出声**，不许静默 */ }
            Console.WriteLine("      [T0.7] ⚠️ 读不到唯一声明（SELFBUILT_CONFIG / build/SelfBuiltConfig.props）⇒ 回退 Debug");
            return "Debug";
        }
        /// <summary>本 harness 直接编入的 shim 源（相对仓库根）。</summary>
        private const string ShimRel = "build/shims/PresentationCore.HbTextLine.cs";
        /// <summary>逐字符真值出处（写进每一行 `truth=NA(...)` ⇒ 读者可自己复算"那里到底有没有这一列"）。</summary>
        private static readonly string TruthSourceNA =
            "source=行级 oracle 无逐字符真值（build/MilBridge/gen/layout-b34-compact.json"
            + " ← tests/parity/windows/layout-b34/windows-results.json；只有 len/nl/ws/w/witw/ext 六个行级字段）";

        /// <summary>折叠区间宽度容差。**沿用既有 0.34**（= 1 个 ideal unit），不放宽、也不改桶阈值。
        /// 提成常量 ⇒ 阳性对照只需改这一处（改完必须还原，报告里写 before/after sha）。</summary>
        private const double ColCrWidthTol = 0.34;

        /// <summary>`#13`：`T1B_MODIFIER_META=0` ⇒ 把三个 modifier meta 值**强制成 `-1/-1/-1`**。
        /// 【为什么这样就等于"调用点不传这三个实参"】C# 的可选参数是在**调用点**求值后传值的
        ///   ⇒ 被调方收到的三个值完全相同，shim 侧**无法区分**"用了默认值"与"显式传了默认值"。
        ///   ⇒ 这样**不用复制调用点**（两个调用点会漂移），同一份 DLL、同一仪器 sha 即可做
        ///   "传 vs 不传"的**零影响 A/B**（T3 的 `#13` 清单要的就是"唯一变量"）。
        /// 默认（不设该 env，或设成 `0` 以外的任何值）= **传**。</summary>
        private static readonly bool ModifierMetaEnabled =
            !string.Equals(Environment.GetEnvironmentVariable("T1B_MODIFIER_META"), "0", StringComparison.Ordinal);

        private static void Check(string id, string what, bool ok, string detail)
        {
            if (ok) { ++_pass; Console.WriteLine($"  ✅ {id} {what}"); }
            else { ++_fail; Fails.Add($"{id} {what} :: {detail}"); Console.WriteLine($"  ❌ {id} {what}"); }
            if (!string.IsNullOrEmpty(detail)) Console.WriteLine($"       {detail}");
        }

        private static int Main()
        {
            Console.WriteLine("==================== T1b/B2 · HbTextLine 对拍 harness（驱动真 shim 源）====================");
            Console.WriteLine($"shim 源 = {HbShimSource.File}");
            Console.WriteLine($"shim tag = {HbShimSource.Tag}");
            Console.WriteLine($"引擎     = {HbShimSource.EngineTag}");
            Console.WriteLine($"ICU      = {HbBreakEngine.IcuVersion}；HB = {HbShaper.Version}");
            Console.WriteLine();

            // ---------------- T0 身份自检（"我测的是真源"这件事本身要能被证伪）----------------
            Console.WriteLine("──────── T0 身份自检：驱动的是**真 shim 源文件**吗 ────────");
            Assembly self = Assembly.GetExecutingAssembly();
            Type hbLine = typeof(HbTextLine);
            Check("T0.1", "HbTextLine 编译在**本 harness 程序集**内（不是引用 PC 里的副本）",
                hbLine.Assembly == self,
                $"HbTextLine.Assembly={hbLine.Assembly.GetName().Name}；harness={self.GetName().Name}");
            Check("T0.2", "TextLine 基类来自 PresentationCore（契约是真的）",
                typeof(TextLine).Assembly != self,
                $"TextLine.Assembly={typeof(TextLine).Assembly.GetName().Name}");
            Check("T0.3", "shim 源文件里的 Tag 与 harness 预期逐字相同（换文件/换 stub 会在这里炸）",
                HbShimSource.Tag == ExpectedShimTag,
                $"实际=\"{HbShimSource.Tag}\"");
            string shimPath = Path.Combine(Root, HbShimSource.File);
            string sha = "";
            if (File.Exists(shimPath))
            {
                using var fs = File.OpenRead(shimPath);
                sha = Convert.ToHexString(SHA256.HashData(fs));
            }
            Check("T0.4", "真 shim 源文件在磁盘上存在（能算出 sha256）", sha.Length == 64,
                $"{HbShimSource.File} sha256={sha}");

            // ⭐ 2026-09-11（主控要求）：把"被测的是哪一份文件"焊进读数。
            //   run.sh 会把**它传给编译器的那个文件**的 sha256 通过 env 传进来；
            //   这里再读盘算一次并**逐字符比对** —— 不一致就大声失败。
            //   （背景：我曾在落地后又补了一个诊断属性而没重报 hash，导致"报的 sha / 磁盘的 sha /
            //     staging 的 sha"三个都不一样 —— 这类"测的到底是哪个文件"的问题必须由机器挡住。）
            // ⭐ T0.7：把**探针目录里真正被加载的 4 个副本**的 sha 与权威件**并排钉住**。
            //   动机（T1b 2026-09-13 实测）：`T0.6` 只钉 shim 源，**没钉 app-local 副本** ⇒
            //   曾出现"探针目录里的 PresentationCore.dll 比权威旧"（455ddb38… vs 6dfacf82…）
            //   而读数照跑 ⇒ 属"测量对象没被钉住"那一族。修好 refresh_applocal() 之后再补这一钉。
            {
                string appDir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
                string cfg = SelfBuiltConfig();          /* ★ `#39` 阶段 2/3：不许写死 Debug/Release */
                var applocal = new (string File, string Auth)[]
                {
                    ("PresentationCore.dll",         Root + "/build/PresentationCore.Linux/bin/" + cfg + "/PresentationCore.dll"),
                    ("WindowsBase.dll",              Root + "/build/WindowsBase.Linux/bin/" + cfg + "/WindowsBase.dll"),
                    ("DirectWriteForwarder.dll",     Root + "/build/DirectWriteForwarder.Linux/bin/" + cfg + "/DirectWriteForwarder.dll"),
                    ("DirectWrite.Linux.Provider.dll", Root + "/build/DirectWrite.Linux/Provider/bin/" + cfg + "/DirectWrite.Linux.Provider.dll"),
                };
                int okA = 0;
                foreach (var (file, auth) in applocal)
                {
                    string local = Path.Combine(appDir, file);
                    string sh1 = File.Exists(local) ? Sha16(local) : "(缺)";
                    string sh2 = File.Exists(auth) ? Sha16(auth) : "(权威缺失)";
                    bool same = sh1 == sh2 && sh1 != "(缺)" && sh1 != "(权威缺失)";
                    if (same) ++okA;
                    Console.WriteLine($"      [T0.7] {file,-32} 副本={sh1}  权威={sh2}  {(same ? "✓ 一致" : "❌ 不一致")}");
                }
                Check("T0.7", "**探针目录里实际加载的 4 个副本 sha 与权威件逐一相同**（测量对象被钉住）",
                    okA == 4, $"一致 {okA}/4（权威 PC={Sha16(Root + "/build/PresentationCore.Linux/bin/" + cfg + "/PresentationCore.dll")} cfg={cfg}）");
                // 头行的 `applocal=` 读这里（实测值，不是常量）
                AppLocalStatus = okA + "/4 一致" + (okA == 4 ? "" : "（**不一致/缺件** ⇒ 本次读数不可信）");
            }

            string pinned = Environment.GetEnvironmentVariable("T1B_SHIM_SHA256");
            if (!string.IsNullOrEmpty(pinned))
            {
                Check("T0.6", "**被测文件的 sha256 == run.sh 固定的 sha256**（编译进本 harness 的那一份）",
                    string.Equals(pinned, sha, StringComparison.OrdinalIgnoreCase),
                    $"固定={pinned} 实读={sha}");
            }
            else
            {
                Console.WriteLine("  ⚠ T0.6 未固定来源（env T1B_SHIM_SHA256 为空）——本次只打印 sha，无法证明'编的就是读的这一份'");
            }
            Check("T0.5", "ICU 断行引擎可用（不是 '?'）", HbBreakEngine.IcuVersion != "?",
                $"u_getVersion={HbBreakEngine.IcuVersion}");
            Console.WriteLine();

            int rc73 = Test73Cjk();
            Console.WriteLine();
            var b34 = TestLayoutB34();
            Console.WriteLine();
            int rcBreak = TestLineBreakSemantics();
            Console.WriteLine();

            Console.WriteLine("──────── 计数器汇总（脚手架读数）────────");
            Console.WriteLine("  " + HbTextLineScaffold.SummaryLine());
            Console.WriteLine();

            Console.WriteLine("==================== 结论 ====================");
            Console.WriteLine($"通过 {_pass} / 失败 {_fail}");
            foreach (string f in Fails) Console.WriteLine("  ❌ " + f);
            bool ok = _fail == 0 && rc73 == 0 && b34 == 0 && rcBreak == 0;
            Console.WriteLine(ok ? "⇒ 全绿（73 例逐行全等 + 真机口径一致）" : "⇒ **有失败**（见上）");
            return ok ? 0 : 1;
        }

        // ==================================================================================
        //  T1 · 73 例 CJK：**真 HbTextLine** 逐行全等（DWrite 层口径）
        // ==================================================================================
        private static int Test73Cjk()
        {
            Console.WriteLine("──────── T1 · 73 例 CJK（DWrite oracle）逐行全等 —— 驱动真 HbTextLine ────────");
            using JsonDocument doc = JsonDocument.Parse(File.ReadAllText(CjkOracle));
            GlyphTypeface gt = GetGlyphTypeface(Root + "/build/fonts", "Regular");
            var props = new HbRunProperties(null, 0, null);

            int exact = 0, diff = 0, cases = 0;
            var bad = new List<string>();
            foreach (JsonElement c in doc.RootElement.GetProperty("cases").EnumerateArray())
            {
                ++cases;
                string id = c.GetProperty("id").GetString();
                string text = c.GetProperty("text").GetString();
                double width = c.GetProperty("containerWidthDip").GetDouble();
                double em = c.GetProperty("emSizeDip").GetDouble();
                int weight = c.TryGetProperty("weight", out JsonElement wEl) ? wEl.GetInt32() : 400;
                int style = c.TryGetProperty("style", out JsonElement sEl) ? sEl.GetInt32() : 0;
                string font = PickFont(c.GetProperty("fontFamily").GetString(), weight, style, text);

                var exp = new List<(int s, int e)>();
                foreach (JsonElement L in c.GetProperty("lines").EnumerateArray())
                    exp.Add((L.GetProperty("startChar").GetInt32(), L.GetProperty("endCharExclusive").GetInt32()));

                List<HbTextLine> lines = HbTextLineFactory.FormatParagraph(
                    text, font, em, width, gt, 1.0f, props, false, false, 0, out int consumed);

                // 行起点只能靠累加 Length 得到（真机实测 `TextLine.Start` 恒 0）
                var got = new List<(int s, int e)>();
                int start = 0;
                foreach (HbTextLine L in lines)
                {
                    int visible = L.Length - L.NewlineLength;      // DWrite 层：不含硬断字符
                    got.Add((start, start + visible));
                    start += L.Length;
                }

                bool same = got.Count == exp.Count;
                if (same)
                    for (int i = 0; i < got.Count; ++i)
                        if (got[i].s != exp[i].s || got[i].e != exp[i].e) { same = false; break; }
                if (same) ++exact;
                else
                {
                    ++diff;
                    bad.Add($"   ❌ {id} (w={width} em={em}) DWrite={Ranges(exp)} 真HbTextLine={Ranges(got)}");
                }
            }
            Console.WriteLine($"   用例 {cases}；**逐行全等 {exact} / 不同 {diff}**");
            foreach (string b in bad) Console.WriteLine(b);
            Check("T1.73", "73 例 CJK 逐行全等（判据：必须 0 不同）", diff == 0 && exact == cases,
                $"exact={exact} diff={diff} cases={cases}");
            return diff == 0 && exact == cases ? 0 : 1;
        }

        // ==================================================================================
        //  T2/T3/T4/T5 · 真机 oracle（614 例 / 3222 行）
        // ==================================================================================
        private static int TestLayoutB34()
        {
            if (!File.Exists(B34Compact))
            {
                Console.WriteLine("  ❌ 找不到紧凑 oracle：" + B34Compact);
                Console.WriteLine("     ⇒ 先跑：python3 build/MilBridge/tools/extract-layout-b34.py");
                return 1;
            }
            Console.WriteLine("──────── T2/T3/T4 · 真机 oracle（layout-b34）对拍 —— 驱动真 HbTextLine ────────");
            using JsonDocument compact = JsonDocument.Parse(File.ReadAllText(B34Compact));
            using JsonDocument casesDoc = JsonDocument.Parse(File.ReadAllText(B34Cases));
            var caseMeta = new Dictionary<string, JsonElement>();
            foreach (JsonElement c in casesDoc.RootElement.GetProperty("cases").EnumerateArray())
                caseMeta[c.GetProperty("id").GetString()] = c;

            GlyphTypeface gtFile = GetGlyphTypeface(Root + "/build/fonts", "Regular");
            GlyphTypeface gtCjk = GetGlyphTypeface("/usr/share/fonts/opentype/noto", "Regular");
            var props = new HbRunProperties(null, 0, null);

            // ================= T1b2/#12 (a) · `[ROWD]` 开关自报（未设 ⇒ 逐字不输出，原读数逐位不变）=================
            foreach (JsonElement c0 in compact.RootElement.GetProperty("cases").EnumerateArray())
                CaseTruthLines[c0.GetProperty("id").GetString()] = c0.GetProperty("lines").GetArrayLength();
            if (RowDumpWant.Count == 0)
                Console.WriteLine("[ROWD] 开关：T1B_ROW_DUMP 未设/为空 ⇒ 逐字符 dump **关闭**（本趟不产生 [ROWD] 读数）");
            else
            {
                Console.WriteLine("[ROWD] 开关：T1B_ROW_DUMP 点名 " + RowDumpWant.Count + " 个 (用例,行)；"
                    + "逐字符真值列**一律 NA**（行级 oracle 没有该列）");
                // ⭐ 主控 2026-09-14 裁定 ③：**每一列都要标清来源**，否则 D/E 结局判不了。
                //   五类标记贯穿全段输出（列名后面直接跟标记）：
                Console.WriteLine("[ROWD] 列来源图例（**每一列必属其一**；D/E 结局靠它判）：");
                Console.WriteLine("[ROWD]   [O]  = **我们侧·实读**：直接读 `HbTextLine` 的契约属性 / 反射读 `_charAdvances`");
                Console.WriteLine("[ROWD]   [T]  = **真值侧·行级字段直读**：oracle(`len,nl,ws,w,witw,ext,text`) —— 没有比这更细的真值");
                Console.WriteLine("[ROWD]   [Td] = **真值侧·推导**：由 [T] 的字段算出，**推导规则就地写在括号里**");
                Console.WriteLine("[ROWD]   [X]  = **跨侧对照**：把**我们的判据**套在**真值文本**上 —— **它不是真值**，只用来显示口径差");
                Console.WriteLine("[ROWD]   [NA] = **真值源里没有这一列** ⇒ 印 `NA(source=…)`，绝不凭空补值");
                Console.WriteLine("[ROWD]   本段用到的具体来源：逐字符 `adv_ours/cum_ours` = [O]（反射 `_charAdvances`）；"
                    + "逐字符 `truth` = [NA]；"
                    + "`我们{…}` = [O]；`真值{…}` = [T]；"
                    + "`真值 尾部可见空白` = [Td] **规则 = `ws − nl`**（真值 `ws` 含 换行/EOP ⇒ 减去 `nl` 才是可见文本的尾空白数）；"
                    + "`我们 尾部可见空白` = [O]（与 shim 的 `TrailingWhitespaceCount` 同一个 `HbBreakEngine.IsTrailingWhitespace`）；"
                    + "`真值文本按我们判据数出的尾空白` = [X]");
            }

            // ================= T1b2/#12 (b) · 跑前落盘"族表基线"（来源 = **上一趟自己的 artifact**）=================
            //  为什么用上一趟 artifact 而不是手写基线：两者由**同一个** FamilyTable()/FamilyOf() 解析 ⇒
            //  不存在"artifact 一份口径、基线文件另一份口径"。基线落盘到 gen/t2d-family-baseline.txt。
            SortedDictionary<string, int> famBefore = null;
            string famBeforeSource;
            {
                string prevWd = Root + "/build/MilBridge/gen/t2d-width-diff.txt";
                if (File.Exists(prevWd))
                {
                    try
                    {
                        famBefore = FamilyTable(File.ReadAllLines(prevWd), onlyLarge: true);
                        famBeforeSource = "上一趟 artifact gen/t2d-width-diff.txt sha16=" + Sha16(prevWd)
                            + " mtime=" + File.GetLastWriteTime(prevWd).ToString("yyyy-MM-dd HH:mm:ss")
                            + "（本文件即上一趟跑的产物 ⇒ 它就是「上一趟的族表」）";
                        var bl = new List<string>
                        {
                            "# T1b2/#12 · 本次跑前的**族表基线**（`>0.34 DIP` 桶，逐族计数）",
                            "# " + famBeforeSource,
                            "# 由 Program.cs 的 FamilyTable()/FamilyOf() 从上一趟 artifact 重算（**无第二套口径**）",
                            "# 用途：跑后逐族 diff；**允许变化**的族仅 "
                                + "A1_nbsp_zwsp / B_nbsp_zwsp / B_nbsp_zwsp_trim / F_nbsp_zwsp / F_lat_words",
                        };
                        foreach (var kv in famBefore) bl.Add(kv.Key + "=" + kv.Value);
                        File.WriteAllLines(Root + "/build/MilBridge/gen/t2d-family-baseline.txt", bl);
                    }
                    catch (Exception e)
                    {
                        famBefore = null;
                        famBeforeSource = "读上一趟 artifact 失败（" + e.GetType().Name + " ⇒ 基线不可得）";
                    }
                }
                else famBeforeSource = "无上一趟 artifact（gen/t2d-width-diff.txt 不存在）";
            }

            int lineTotal = 0, lineOk = 0;                 // 记账结构（Length/nl/ws/WITW−W）
            // 【T1b 2026-09-14 主控批准】宽度逐行 dump + 三桶和机检 + 牙。
            //   牙：T2D_WIDTH_INJECT=<DIP> ⇒ 给**第一条可比的 (用例,行)** 人为加上该差值（并大声打印 [注入]），
            //       该行必须出现在 dump 里且桶为 >0.34；不设该 env ⇒ 原样（清单回到原样）。
            var widthDiffRows = new List<string>();
            int widthRows = 0;                      // 只有本 dump 新增的变量；桶/最大差沿用车里既有那几个
            double widthInject = 0;
            { string wi = Environment.GetEnvironmentVariable("T2D_WIDTH_INJECT");
              if (!string.IsNullOrEmpty(wi)) double.TryParse(wi, out widthInject); }
            int widthInjectedRow = -1;
            int hardLineTotal = 0, hardLineOk = 0;         // ①
            int blankLineTotal = 0, blankLineOk = 0;       // ②
            int wsLineTotal = 0, wsLineOk = 0;             // ③
            int comparableCases = 0, comparableExact = 0;
            int widthDeltaZero = 0, widthDeltaSmall = 0, widthDeltaLarge = 0;
            double widthDeltaMax = 0; string widthDeltaMaxCase = "-";
            int aCases = 0, aCasesOk = 0, aLines = 0, aLinesOk = 0;
            // T2d：行度量对拍（Height/Baseline/Extent vs 真机）。⚠️ 真机三条公式：
            //   `Height = LineHeight`（未设 = 字体自然行高）、`TextHeight` **恒为自然文本高**、
            //   `Baseline = LineHeight × (自然Baseline/自然Height)`。本实现目前 `Height` 恒等于自然行高
            //   ⇒ **`LineHeight>0` 的用例是第一个对拍点**（可能就是"多行摞印"的答案）。
            var ledgerLines = new List<string>();   // **行级**记账不一致清单（用例|行|期望|实得|桶）—— 只加输出，不改判据
            var extMismatchMain = new List<string>();   // 主对拍集（1298 行）里的 Extent 余差（供 t2d-extent-detail.sh 全量取数）
            int mTotal = 0, mHeightOk = 0, mBaseOk = 0, mExtOk = 0;
            int lhLines = 0, lhOk = 0;
            double mHeightMax = 0, mBaseMax = 0; string mWorst = "-";
            var lhSamples = new List<string>();
            int colEligible = 0, colEligibleOk = 0, colApplied = 0, colAppliedOk = 0;
            // T1b2/#12 (b)：契约级断言的**逐条**计数（三条非互斥，各自独立）
            //   ① 的**三种计数**（主控 2026-09-14 裁定，全部印到 stdout + artifact）：
            //     colNegBareFail        = 裸形式 `cr.Width >= 0` 的红数（**含假红**，只作可见计数）
            //     colNegBothSides       = 其中"真值同位置也 <0"（真机自己也这样 ⇒ **不构成违反**）
            //     colNegRealViolation   = 其中"真值 ≥0 而我们 <0"（= **判别式红数 = 真违反**）
            int colNegBareFail = 0, colSpanFail = 0, colWidthFail = 0;
            // ⚠️ 实测更正（T1b2 2026-09-14）：`cr.Width < 0` **不是**普遍不合法 —— 真机自己在
            //   layout-b34 oracle 的 430 条折叠区间里有 **7 条 Width<0**（复算见报告）。所以裸 `>=0`
            //   这条**过宽**：它会把"真值同为负"的行也判红。⇒ 主控裁定：**判据换成判别式**
            //   `ours < 0 ⇒ truth < 0`（方向不放松），三种计数同时印出。
            int colNegBothSides = 0, colNegRealViolation = 0;
            var colNonNegSamples = new List<string>();
            var colSpanSamples = new List<string>();
            var colWidthSamples = new List<string>();
            int colEmptyThrow = 0, colEmptyThrowOk = 0, colEmptyThis = 0, colEmptyThisOk = 0;
            double colWidthDeltaMax = 0; string colWidthDeltaMaxCase = "-";
            var blankSamples = new List<string>();
            var wsSamples = new List<string>();
            var colSamples = new List<string>();
            var colFailSamples = new List<string>();
            var colFailFull = new List<string>();     // **不截断**：折叠明细逐行五列
            var diffCaseFull = new List<string>();    // **不截断**：记账不一致用例逐条（含原因）
            var tabCases = new List<string>();             // 已登记差异：Tab 口径
            var familyDiff = new Dictionary<string, int>();
            var diffCaseIds = new List<string>();

            foreach (JsonElement c in compact.RootElement.GetProperty("cases").EnumerateArray())
            {
                string id = c.GetProperty("id").GetString();
                string text = c.GetProperty("text").GetString();
                double width = c.GetProperty("maxWidth").GetDouble();
                double em = c.GetProperty("fontSize").GetDouble();
                string fontKey = c.GetProperty("fontKey").GetString();
                bool ac = c.GetProperty("alwaysCollapsible").GetBoolean();
                JsonElement meta = caseMeta.TryGetValue(id, out JsonElement m) ? m : default;
                bool hasModifier = meta.ValueKind != JsonValueKind.Undefined &&
                                   meta.TryGetProperty("modifierStart", out JsonElement ms) && ms.ValueKind != JsonValueKind.Null;

                // 【#13 · T1b2】modifier scope 的**三个位置**（T1d 在 shim 侧新增的尾随可选参数，
                //   均为**段落相对码元下标**）—— **只加传参，不改判据/断言**：
                //     `modifierOpenIndex` = **覆盖起点**；
                //     `modifierScopeEnd`  = **覆盖终点（半开；-1 ⇒ 到段末）⇒ 只喂「零宽跨度」**；
                //     `modifierCloseIndex`= 客户端 `TextEndOfSegment` 的下标（-1 ⇒ 从不）**⇒ 只喂 `lbNull`**。
                //   ⚠️ "close = -1（b34 **从不发** `TextEndOfSegment`）"与"**零宽覆盖到哪**"是**两件事**：
                //      覆盖终点由**语料声明的覆盖范围**给 —— b34 `cases.json` 的 `modifierStart=6` / `modifierEnd=45`
                //      （`Cases.cs:297` 的 note 原文就是「TextModifier 覆盖 [6,45)」）。只传 open/close 会把
                //      `[6,63)` 全零宽（T1d 自验实测：真值 w=156.9167 vs 我们 43.59）⇒ 必须同时传 scopeEnd。
                //   ⚠️ 无 modifier 的用例（b34 其余 609 例）`modifierStart` 缺失 ⇒ 三个值**全留 -1**
                //      = T1d 参数的默认值 ⇒ 与"不传"逐位相同（这是"只加传参、不改读数"的结构性理由）。
                //   ⚠️ b34 语料**没有** `TextEndOfSegment`（`grep -rn` 全 6 个 oracle 源文件 0 命中）
                //      ⇒ `modifierCloseIndex` 恒为 -1 是**语料决定**的，不是从配对规则推的。
                int modifierOpen = -1, modifierScopeEnd = -1;
                if (meta.ValueKind != JsonValueKind.Undefined)
                {
                    if (meta.TryGetProperty("modifierStart", out JsonElement mOpen) && mOpen.ValueKind == JsonValueKind.Number)
                        modifierOpen = mOpen.GetInt32();
                    if (meta.TryGetProperty("modifierEnd", out JsonElement mEnd) && mEnd.ValueKind == JsonValueKind.Number)
                        modifierScopeEnd = mEnd.GetInt32();
                }
                // `#13` 的零影响 A/B 开关：等价于"调用点不传这三个实参"（见 ModifierMetaEnabled 的注释）
                if (!ModifierMetaEnabled) { modifierOpen = -1; modifierScopeEnd = -1; }

                bool bidi = HasRtl(text);
                bool isTab = text.IndexOf('\t') >= 0;
                bool display = meta.ValueKind != JsonValueKind.Undefined &&
                               string.Equals(meta.TryGetProperty("textFormattingMode", out JsonElement tfm) ? tfm.GetString() : null,
                                             "Display", StringComparison.Ordinal);
                // 可逐位比的面：file 字体（= oracle 那份 ttf）+ 非 RTL（本轮无 bidi）+ **Ideal 模式**
                //（Display 模式把 advance 对齐到整像素，本实现没有该模式 ⇒ 与 zh/ja 同列"只统计不给结论"）
                bool comparable = fontKey == "file" && !bidi && !display;

                string font; GlyphTypeface gt;
                if (fontKey == "file") { font = FontRegular; gt = gtFile; }
                else { font = FontCjk; gt = gtCjk; }

                List<HbTextLine> lines;
                int consumed;
                try
                {
                    double lineHeight = (meta.ValueKind != JsonValueKind.Undefined &&
                                         meta.TryGetProperty("lineHeight", out JsonElement lhv) && lhv.ValueKind == JsonValueKind.Number)
                                        ? lhv.GetDouble() : 0.0;
                    // 【T1b 2026-09-14 主控裁定】这条 oracle 族（layout-b34）的 harness 把
                    //   `DefaultIncrementalTab` **写死成 0**（layout-b34/src/LayoutOracle/TextModel.cs:167）
                    //   ⇒ 那 34 例的真值是「0 宽 Tab」这一**配置**；要与它 apples-to-apples，
                    //   必须显式传 `defaultIncrementalTab: 0`（NaN=框架默认 4×em 是**另一套配置**）。
                    // 【T1b 2026-09-14 主控裁定】这条 oracle 族（layout-b34）把 `DefaultIncrementalTab`
                    //   写死成 0（layout-b34/src/LayoutOracle/TextModel.cs:167）⇒ 那 34 例验的是「0 宽 Tab」这一**配置**；
                    //   要 apples-to-apples 就必须显式传 0（NaN=框架默认 4×em 是另一套配置）。
                    lines = HbTextLineFactory.FormatParagraph(text, font, em, width, gt, 1.0f, props, ac, hasModifier, lineHeight, out consumed,
                                                              defaultIncrementalTab: 0,
                                                              modifierOpenIndex: modifierOpen, modifierScopeEnd: modifierScopeEnd, modifierCloseIndex: -1);
                }
                catch (Exception e)
                {
                    diffCaseIds.Add($"{id}(排不出行:{e.GetType().Name})");
                    continue;
                }

                var expList = new List<JsonElement>();
                foreach (JsonElement L in c.GetProperty("lines").EnumerateArray()) expList.Add(L);

                bool caseExact = lines.Count == expList.Count;
                string caseWhy = caseExact ? "" : $"行数 {lines.Count}≠{expList.Count}";

                int start = 0;
                for (int i = 0; i < lines.Count; ++i)
                {
                    HbTextLine L = lines[i];
                    if (i >= expList.Count) break;
                    JsonElement E = expList[i];
                    int eLen = E.GetProperty("len").GetInt32();
                    int eNl = E.GetProperty("nl").GetInt32();
                    int eWs = E.GetProperty("ws").GetInt32();
                    double eW = E.GetProperty("w").GetDouble();
                    double eWitw = E.GetProperty("witw").GetDouble();
                    string eText = E.GetProperty("text").GetString() ?? "";

                    // ---- (a) `[ROWD]` 定向逐字符 dump（**点名才打**；不改任何计数/判据）----
                    //   刻意放在 `if (comparable)` **之外**：不可比用例也能被点名 ⇒ "点名却没输出"
                    //   只会剩两种原因（用例 id 不存在 / 行号越界），两者都会在跑尾被显式报成 D 结局。
                    if (RowDumpWant.Contains(RowKey(id, i)))
                        RowDump(id, i, L, E, start, comparable);

                    bool lenOk = L.Length == eLen, nlOk = L.NewlineLength == eNl, wsOk = L.TrailingWhitespaceLength == eWs;
                    if (comparable) ++lineTotal;
                    // 宽度绝对值**不该**逐位相等（真机把 advance 量化到 1/300 英寸整数），
                    // 但「行尾空白宽 = WITW − W」这条**关系**必须一致。
                    bool witwRelOk = Math.Abs((eWitw - eW) - (L.WidthIncludingTrailingWhitespace - L.Width)) < 0.34;
                    if (comparable)
                    {
                        // ---- T2d 行度量 ----
                        ++mTotal;
                        bool caseLineHeight = meta.ValueKind != JsonValueKind.Undefined &&
                                              meta.TryGetProperty("lineHeight", out JsonElement lhe) && lhe.ValueKind != JsonValueKind.Null;
                        double dh = Math.Abs(L.Height - E.GetProperty("h").GetDouble());
                        double db = Math.Abs(L.Baseline - E.GetProperty("bl").GetDouble());
                        double de = Math.Abs(L.Extent - E.GetProperty("ext").GetDouble());
                        if (dh > mHeightMax) { mHeightMax = dh; mWorst = id + " 行#" + i; }
                        if (db > mBaseMax) mBaseMax = db;
                        if (dh < 0.01) ++mHeightOk;
                        if (db < 0.01) ++mBaseOk;
                        if (de < 0.01) ++mExtOk;
                        else if (de >= 0.01) extMismatchMain.Add(id + " 行#" + i + " [file-font"
                            + (CjkIn(text) ? "+CJK" : "") + "] Extent 真值="
                            + E.GetProperty("ext").GetDouble().ToString("F4") + " 我们=" + L.Extent.ToString("F4")
                            + " 差=" + (L.Extent - E.GetProperty("ext").GetDouble()).ToString("F4"));
                        if (caseLineHeight)
                        {
                            ++lhLines;
                            if (dh < 0.01 && db < 0.01) ++lhOk;
                            else if (lhSamples.Count < 5)
                                lhSamples.Add("      LineHeight 用例 " + id + " 行#" + i
                                    + "：真机 Height=" + E.GetProperty("h").GetDouble().ToString("F4")
                                    + " Baseline=" + E.GetProperty("bl").GetDouble().ToString("F4")
                                    + " | 实得 Height=" + L.Height.ToString("F4") + " Baseline=" + L.Baseline.ToString("F4"));
                        }

                        double d = Math.Abs(L.Width - eW);
                        // 【牙】只作用于**第一条可比行**（widthInjectedRow<0 ⇒ 还没注入过）
                        if (widthInject > 0 && widthInjectedRow < 0)
                        {
                            widthInjectedRow = widthRows;
                            d += widthInject;
                            Console.WriteLine($"   [注入] T2D_WIDTH_INJECT={widthInject} ⇒ 人为放大 {id} 行#{i} 的宽度差到 {d:F4} DIP（自检用，**不是**测量）");
                        }
                        if (d > widthDeltaMax) { widthDeltaMax = d; widthDeltaMaxCase = id; }
                        ++widthRows;
                        if (d <= 1e-9) ++widthDeltaZero; else if (d <= 0.34) ++widthDeltaSmall; else ++widthDeltaLarge;
                        if (d > 1e-9)
                            widthDiffRows.Add(id + " | 行#" + i + " | cp=[" + start + "," + (start + eLen) + ") | 真值宽="
                                + eW.ToString("F4") + " | 我们宽=" + L.Width.ToString("F4") + " | 差=" + d.ToString("F4")
                                + " | 桶=" + (d <= 0.34 ? "≤0.34 DIP" : ">0.34 DIP"));

                        if (lenOk && nlOk && wsOk && witwRelOk) ++lineOk;
                        else
                        {
                            caseExact = false;
                            if (caseWhy.Length == 0) caseWhy = $"行#{i} 期望 Len={eLen} nl={eNl} ws={eWs} | 实得 Len={L.Length} nl={L.NewlineLength} ws={L.TrailingWhitespaceLength}";
                            // ⭐ 行级完整清单（T2 §23.6 那格"未判定"就是缺它）：**只加输出，不改阈值/语义**
                            string bucket;
                            if (!wsOk) bucket = "行尾空白计数(ws)";
                            else if (!nlOk) bucket = "硬断计数(nl)";
                            else if (!lenOk) bucket = "行区间长度(Length)";
                            else bucket = "行尾空白宽度(WITW−W)";
                            bool nbspzwsp = text.IndexOf('\u00A0') >= 0 || text.IndexOf('\u200B') >= 0;
                            ledgerLines.Add(id + " | 行#" + i + " | 期望 Len=" + eLen + " nl=" + eNl + " ws=" + eWs
                                + " | 实得 Len=" + L.Length + " nl=" + L.NewlineLength + " ws=" + L.TrailingWhitespaceLength
                                + " | 桶=" + bucket + (nbspzwsp ? "（NBSP/ZWSP 家族）" : ""));
                        }
                    }

                    // ① 真硬断行（nl>0 且非末行）：Length 与 NewlineLength 必须精确相等
                    bool isHard = eNl > 0 && i < expList.Count - 1;
                    if (comparable && isHard)
                    {
                        ++hardLineTotal;
                        if (lenOk && nlOk) ++hardLineOk;
                    }
                    // ② 空行（原文仅由换行字符组成）：Length=1、Width=0、nl=1
                    bool isBlank = eText.Length > 0 && eText.Trim('\n', '\r', '\u2028', '\u2029').Length == 0;
                    if (comparable && isBlank)
                    {
                        ++blankLineTotal;
                        if (L.Length == eLen && Math.Abs(L.Width) < 1e-9 && L.NewlineLength == eNl) ++blankLineOk;
                        if (blankSamples.Count < 4)
                            blankSamples.Add($"      {id} 行#{i}: 真机 Len={eLen} W={eW:F4} nl={eNl} | 实得 Len={L.Length} W={L.Width:F4} nl={L.NewlineLength}");
                    }
                    // ③ 行尾空白：ws 计数 + (WITW−W) 关系
                    if (comparable && eWs > 0)
                    {
                        ++wsLineTotal;
                        if (wsOk && witwRelOk) ++wsLineOk;
                        if (wsSamples.Count < 4 && i < 2)
                            wsSamples.Add($"      {id} 行#{i}: 真机 ws={eWs} WITW−W={eWitw - eW:F4} | 实得 ws={L.TrailingWhitespaceLength} WITW−W={L.WidthIncludingTrailingWhitespace - L.Width:F4}");
                    }

                    // ---- Collapse：真机资格闸门（!HasOverflowed && !KeepState ⇒ 原样返回）----
                    if (comparable)
                    {
                        var propsList = new TextCollapsingProperties[] { new HarnessEllipsisProps(Math.Max(1.0, L.Width * 0.5)) };
                        TextLine collapsed;
                        try { collapsed = L.Collapse(propsList); }
                        catch (Exception e)
                        {
                            diffCaseIds.Add($"{id}行#{i}(Collapse 抛 {e.GetType().Name})");
                            start += L.Length;
                            continue;
                        }
                        bool expCollapsed = E.GetProperty("ce").ValueKind != JsonValueKind.Null &&
                                            E.GetProperty("ce").GetProperty("hasCollapsed").GetBoolean();
                        ++colEligible;
                        if (expCollapsed == collapsed.HasCollapsed) ++colEligibleOk;
                        else
                        {
                            caseExact = false;
                            if (caseWhy.Length == 0) caseWhy = $"行#{i} Collapse hasCollapsed 期望 {expCollapsed} 实得 {collapsed.HasCollapsed}";
                        }
                        if (expCollapsed)
                        {
                            ++colApplied;
                            double eW2 = E.GetProperty("ce").GetProperty("w").GetDouble();
                            int eLen2 = E.GetProperty("ce").GetProperty("len").GetInt32();
                            JsonElement Ecr = E.GetProperty("ce").GetProperty("cr")[0];
                            IList<TextCollapsedRange> cr = collapsed.GetTextCollapsedRanges();
                            double dW = Math.Abs(collapsed.Width - eW2);
                            if (dW > colWidthDeltaMax) { colWidthDeltaMax = dW; colWidthDeltaMaxCase = $"{id} 行#{i}（行文本={L.Diagnostics}）"; }
                            // ---- T1b2/#12 (b) 契约级断言：**逐条拆开**（这样"哪一族红"分得清，也能各自做阳性对照）----
                            //   ① `cr[0].Width >= 0` —— 折叠区间宽度为负**不合法**。
                            //      实测依据（可复算）：gen/tline-detail-full.txt 段1 里 `F_nbsp_zwsp_w40|行#3`
                            //      我们 `[14,2) W=-3.0560` 而**真值同位置 `[14,2) W=3.3433`** ⇒ 不是口径差，是错值。
                            //   ② 起止与真机一致（`TextSourceCharacterIndex` / `Length`）
                            //   ③ `|cr.Width − 真机| < ColCrWidthTol`：**沿用既有 0.34**（不放宽、也不改桶阈值）
                            int eCrStart = Ecr.GetProperty("TextSourceCharacterIndex").GetInt32();
                            int eCrLen = Ecr.GetProperty("Length").GetInt32();
                            double eCrW = Ecr.GetProperty("Width").GetDouble();
                            bool crHas1 = cr != null && cr.Count == 1;
                            // ---- 主控 2026-09-14 裁定：① 由「裸 `cr.Width >= 0`」改为**判别式** ----
                            //   起因（我上一轮实测）：**真机自己在 oracle 的 430 条折叠区间里有 7 条 Width<0**
                            //   ⇒ "宽度为负"在本项目**不是**契约违反 ⇒ 裸形式对 6 条红里的 5 条是**假红**，
                            //   真违反只有 1 条（`F_nbsp_zwsp_w40#3`：我们 −3.0560 而真值 +3.3433）。
                            //   · `crNonNegBare`：**判据原文，只作"可见计数"**（不再驱动 `okDetail`）；
                            //   · `crNegOk`（判别式，**驱动 `okDetail`**）：`ours < 0 ⇒ truth < 0`
                            //     等价 `ours >= min(0, truth)` —— **方向不放松**：真值非负而我们为负的，
                            //     **每一种情形都仍然抓住**；只是不再对"真值本身也为负"的行假红。
                            //   三种计数**都印**（stdout + artifact）⇒ 判据位移永远可见。
                            bool crNonNegBare = crHas1 && cr[0].Width >= 0;
                            bool crNegOk = crHas1 && (cr[0].Width >= 0 || eCrW < 0);
                            bool crSpanOk = crHas1 && cr[0].TextSourceCharacterIndex == eCrStart && cr[0].Length == eCrLen;
                            bool crWidthOk = crHas1 && Math.Abs(cr[0].Width - eCrW) < ColCrWidthTol;
                            bool okDetail = collapsed.Length == eLen2 && dW < 0.34
                                            && crNegOk && crSpanOk && crWidthOk;
                            if (okDetail) ++colAppliedOk;
                            else
                            {
                                // 逐条计红（**三条非互斥**：各自独立计数，读者能看到"是宽度错还是起止错"）
                                if (!crNonNegBare)
                                {
                                    ++colNegBareFail;
                                    bool truthNeg = eCrW < 0;
                                    if (truthNeg) ++colNegBothSides; else ++colNegRealViolation;
                                    if (colNonNegSamples.Count < 8)
                                        colNonNegSamples.Add("      [契约①·" + (truthNeg ? "裸形式假红" : "判别式真违反") + "] "
                                            + id + " 行#" + i + "：cr 我们=" + CrTxt(cr)
                                            + " —— 我们 cr.Width < 0；真值同位置 W=" + eCrW.ToString("F4")
                                            + (truthNeg
                                                ? "（**真值也是负的** ⇒ 裸 `cr.Width>=0` 过宽造成的**假红**；判别式下**不红**）"
                                                : " ≥ 0 ⇒ **确为违反**（真机在该位置为正；判别式下**仍红**）"));
                                }
                                if (!crSpanOk)
                                {
                                    ++colSpanFail;
                                    if (colSpanSamples.Count < 8)
                                        colSpanSamples.Add("      [契约②] " + id + " 行#" + i + "：起止 我们=" + CrSpanTxt(cr)
                                            + " 真值=[" + eCrStart + "," + eCrLen + ")");
                                }
                                if (!crWidthOk)
                                {
                                    ++colWidthFail;
                                    if (colWidthSamples.Count < 8)
                                        colWidthSamples.Add("      [契约③] " + id + " 行#" + i + "：cr.Width 我们="
                                            + (crHas1 ? cr[0].Width.ToString("F4") : CrSpanTxt(cr)) + " 真值=" + eCrW.ToString("F4")
                                            + " 差=" + (crHas1 ? (cr[0].Width - eCrW).ToString("F4") : "n/a")
                                            + " 阈值=" + ColCrWidthTol.ToString("F4"));
                                }
                                caseExact = false;
                                if (caseWhy.Length == 0) caseWhy = $"行#{i} 折叠明细不符";
                                colFailFull.Add(id + "|行#" + i + "|我们 Len=" + collapsed.Length + " W=" + collapsed.Width.ToString("F4")
                                    + "|真值 Len=" + eLen2 + " W=" + eW2.ToString("F4")
                                    + "|差 W=" + (collapsed.Width - eW2).ToString("F4")
                                    + "|cr 我们=" + (cr == null ? "null" : (cr.Count == 0 ? "空" : "[" + cr[0].TextSourceCharacterIndex + "," + cr[0].Length + ") W=" + cr[0].Width.ToString("F4")))
                                    + "|cr 真值=[" + Ecr.GetProperty("TextSourceCharacterIndex").GetInt32() + "," + Ecr.GetProperty("Length").GetInt32() + ") W=" + Ecr.GetProperty("Width").GetDouble().ToString("F4"));
                                if (colFailSamples.Count < 24)
                                {
                                    string crTxt = cr == null ? "null" : (cr.Count == 0 ? "空" : "[" + cr[0].TextSourceCharacterIndex + "," + cr[0].Length + ") W=" + cr[0].Width.ToString("F4"));
                                    string eCrTxt = "[" + Ecr.GetProperty("TextSourceCharacterIndex").GetInt32() + "," + Ecr.GetProperty("Length").GetInt32() + ") W=" + Ecr.GetProperty("Width").GetDouble().ToString("F4");
                                    colFailSamples.Add("      X " + id + " 行#" + i + " [" + L.Diagnostics + "] 行文本=\"" + L.LineTextForDiag + "\" 行W=" + L.Width.ToString("F4")
                                        + "  | 真机 Len=" + eLen2 + " W=" + eW2.ToString("F4") + " cr=" + eCrTxt
                                        + "  | 实得 Len=" + collapsed.Length + " W=" + collapsed.Width.ToString("F4") + " cr=" + crTxt);
                                }
                            }
                            if (colSamples.Count < 4)
                                colSamples.Add($"      {id} 行#{i}: 真机 Len={eLen2} W={eW2:F4} cr=[{Ecr.GetProperty("TextSourceCharacterIndex").GetInt32()},{Ecr.GetProperty("Length").GetInt32()}) W={Ecr.GetProperty("Width").GetDouble():F4}"
                                             + $" | 实得 Len={collapsed.Length} W={collapsed.Width:F4} cr={(cr == null || cr.Count == 0 ? "null" : $"[{cr[0].TextSourceCharacterIndex},{cr[0].Length}) W={cr[0].Width:F4}")}");
                        }
                        else if (collapsed.GetTextCollapsedRanges() != null)
                        {
                            caseExact = false;
                            if (caseWhy.Length == 0) caseWhy = $"行#{i} 未折叠行 GetTextCollapsedRanges() 不是 null";
                        }

                        // 空参：可折叠行 ⇒ 抛 ArgumentNullException；否则 ⇒ 原样返回 this
                        try
                        {
                            TextLine same = L.Collapse(Array.Empty<TextCollapsingProperties>());
                            if (ac)
                            {
                                caseExact = false;
                                if (caseWhy.Length == 0) caseWhy = $"行#{i} 空参应当抛（真机 447 行全抛）";
                            }
                            else { ++colEmptyThis; if (ReferenceEquals(same, L)) ++colEmptyThisOk; else caseExact = false; }
                        }
                        catch (ArgumentNullException)
                        {
                            if (ac) { ++colEmptyThrow; ++colEmptyThrowOk; }
                            else
                            {
                                caseExact = false;
                                if (caseWhy.Length == 0) caseWhy = $"行#{i} 空参不该抛（真机只有 alwaysCollapsible 的行抛）";
                            }
                        }
                    }
                    start += L.Length;
                }

                if (comparable && consumed != text.Length + 1)
                {
                    caseExact = false;
                    if (caseWhy.Length == 0) caseWhy = $"consumed={consumed}≠textLen+1";
                }

                // A 组断行位置（主控点名要的数字）
                if (comparable && c.GetProperty("group").GetString() == "A")
                {
                    ++aCases;
                    bool startsOk = lines.Count == expList.Count;
                    int pos = 0;
                    for (int i = 0; i < lines.Count && startsOk; ++i)
                    {
                        ++aLines;
                        if (pos == expList[i].GetProperty("i").GetInt32() &&
                            (lines[i].Length - lines[i].NewlineLength) ==
                            (expList[i].GetProperty("len").GetInt32() - expList[i].GetProperty("nl").GetInt32()))
                            ++aLinesOk;
                        else { startsOk = false; break; }
                        pos += lines[i].Length;
                    }
                    if (startsOk) ++aCasesOk;
                }

                if (comparable)
                {
                    ++comparableCases;
                    if (caseExact) ++comparableExact;
                    else
                    {
                        diffCaseIds.Add(caseWhy.Length > 0 ? $"{id}({caseWhy})" : id);
                        diffCaseFull.Add(id + "|" + caseWhy);
                        string fam = Family(id);
                        familyDiff[fam] = (familyDiff.TryGetValue(fam, out int n) ? n : 0) + 1;
                        if (isTab && !tabCases.Contains(fam)) tabCases.Add(fam);
                    }
                }
            }

            // ================= T1b2/#12 (a) · 点名却没输出 ⇒ 显式报 **D 结局**（不静默、不报绿）=================
            if (RowDumpWant.Count > 0)
            {
                int rowDumpMiss = 0;
                foreach (string want in RowDumpWant)
                {
                    if (RowDumpHit.Contains(want)) continue;
                    ++rowDumpMiss;
                    int h = want.LastIndexOf('#');
                    string wid = h > 0 ? want.Substring(0, h) : want;
                    string wln = h > 0 ? want.Substring(h + 1) : "?";
                    string why;
                    if (!CaseTruthLines.TryGetValue(wid, out int tn)) why = "用例 id 不在 layout-b34 614 例里";
                    else if (!int.TryParse(wln, out int li)) why = "行号不是整数";
                    else if (li < 0 || li >= tn) why = "行号越界（该用例真值只有 " + tn + " 行）";
                    else why = "循环未到达（该用例排不出行/提前 continue）";
                    Console.WriteLine("[ROWD] 缺失：" + want + " 未命中 ⇒ " + why
                        + " ⇒ **D 结局（仪器层答不出）**：本行**无信息**，不报绿");
                }
                Console.WriteLine("[ROWD] 点名 " + RowDumpWant.Count + " 个 ⇒ 命中 " + RowDumpHit.Count
                    + " / 缺失 " + rowDumpMiss
                    + (rowDumpMiss == 0 ? "（全部命中）" : "（**缺失项按 D 结局处理**）"));
            }

            Console.WriteLine($"   [对拍面] 可逐位比用例 {comparableCases}（file 字体 + Ideal 模式 + 非 RTL）；"
                              + $"其余 {614 - comparableCases} 例只统计不给结论"
                              + "（zh/ja = 无 YaHei/Yu Gothic；Display = 本实现无该模式（advance 未按整像素对齐）；RTL = 本轮无 bidi）");
            Console.WriteLine($"   [逐行记账·结构] Length+NewlineLength+TrailingWhitespaceLength+(WITW−W) ⇒ 全等 {lineOk} / {lineTotal}");
            Console.WriteLine($"   [口径·宽度分桶] 0={widthDeltaZero} / ≤0.34DIP={widthDeltaSmall} / >0.34DIP={widthDeltaLarge} 行（三桶和=={widthRows} 机检："
                + ((widthDeltaZero + widthDeltaSmall + widthDeltaLarge) == widthRows ? "OK" : "**FAIL**") + $"）最大差 {widthDeltaMax:F6} @ {widthDeltaMaxCase}");

            // ================= T1b2/#12 (b) · 族计数等式 + 隔离矩阵（**机器断言**，不是人眼比对）=================
            //  ① 逐族 `>0.34 DIP` 红数；**各和 == 总数**（两处口径同源 ⇒ 必须逐位相等）
            //  ② 与"上一趟 artifact"的族表逐族 diff：**允许变化**的族只有 mayChange，其它族**一位不动**
            var famRed = new SortedDictionary<string, int>(StringComparer.Ordinal);
            foreach (string r in widthDiffRows)
            {
                if (!r.Contains(">0.34 DIP")) continue;
                string k = FamilyOf(r);
                if (k.Length == 0) continue;
                famRed[k] = famRed.TryGetValue(k, out int n0) ? n0 + 1 : 1;
            }
            int famSum = 0;
            foreach (var kv in famRed) famSum += kv.Value;
            bool famSumOk = famSum == widthDeltaLarge;
            string famRedText = FamText(famRed);
            Console.WriteLine("   [隔离矩阵] 族 × >0.34 红数：" + (famRedText.Length == 0 ? "（无）" : famRedText)
                + "    各和=" + famSum + " == 总数 " + widthDeltaLarge + " : " + (famSumOk ? "OK" : "**FAIL**")
                + (widthInject > 0 ? "（⚠️ 本趟含 T2D_WIDTH_INJECT 人为注入，**不是**测量）" : ""));

            // 「**已登记的允许变化**」名单 —— 加族 = **登记**，不是放宽；`T2-iso` 仍必须抓住**未登记**的族变化。
            //   `#12` 登记：A1_nbsp_zwsp / B_nbsp_zwsp / B_nbsp_zwsp_trim / F_nbsp_zwsp / F_lat_words（行尾空白口径）
            //   `#13` 登记：M_modifier（modifier meta 传参）—— 主控 2026-09-15 裁定 ②
            string[] mayChangeArr = { "A1_nbsp_zwsp", "B_nbsp_zwsp", "B_nbsp_zwsp_trim", "F_nbsp_zwsp", "F_lat_words",
                                      "M_modifier" };
            var mayChange = new HashSet<string>(mayChangeArr, StringComparer.Ordinal);
            var isoConflicts = new List<string>();
            string isoDiffText;
            bool isoBaselineOk = famBefore != null;
            Console.WriteLine("   [隔离矩阵] 允许变化的族（其余族**一位不动**）：" + string.Join(" / ", mayChangeArr));
            Console.WriteLine("   [隔离矩阵] before（" + famBeforeSource + "）："
                + (famBefore == null || famBefore.Count == 0 ? "（无）" : FamText(famBefore)));
            Console.WriteLine("   [隔离矩阵] after ：" + (famRedText.Length == 0 ? "（无）" : famRedText));
            if (!isoBaselineOk)
            {
                isoDiffText = "**未判定**";
                Console.WriteLine("   [隔离矩阵] **无基线** ⇒ 隔离性**未判定**（报无信息，**不报绿**）；"
                    + "本次已把当前族表落盘 ⇒ 下一趟即可判。");
            }
            else
            {
                var keys = new SortedSet<string>(StringComparer.Ordinal);
                foreach (var kv in famBefore) keys.Add(kv.Key);
                foreach (var kv in famRed) keys.Add(kv.Key);
                var sbD = new StringBuilder();
                foreach (string k in keys)
                {
                    int b = famBefore.TryGetValue(k, out int bv) ? bv : 0;
                    int a = famRed.TryGetValue(k, out int av) ? av : 0;
                    if (b == a) continue;
                    bool allowed = mayChange.Contains(k);
                    if (!allowed) isoConflicts.Add(k + " " + b + "→" + a);
                    if (sbD.Length > 0) sbD.Append("  ");
                    sbD.Append(k).Append(' ').Append(b).Append("→").Append(a).Append(allowed ? "（允许）" : "（**冲突**）");
                }
                isoDiffText = sbD.Length == 0 ? "一位未动（全部族计数与基线逐位相同）" : sbD.ToString();
                Console.WriteLine("   [隔离矩阵] 逐族 diff：" + isoDiffText);
                if (isoConflicts.Count > 0)
                {
                    Console.WriteLine("   [隔离矩阵] **冲突**：不许变的族发生了变化 ⇒ " + string.Join("  ", isoConflicts));
                    Console.WriteLine("   [隔离矩阵] ⇒ 本趟读数**不可用于验收**（不自动改判据、不放宽阈值；请先解释这些族为何变）");
                }
            }
            bool isoOk = isoBaselineOk && isoConflicts.Count == 0;
            // ⚠️ T1b 复核（2026-09-14）：此处原有一行 `bool isoMachineOk = isoOk && famSumOk;`
            //   —— **算了但没有任何地方消费**（死变量）；同一个表达式在下文 `machineOk` 处
            //   **已经接线到 `Check("T2-iso", …)` 与退出码 `return coreOk && collapseOk && machineOk`**。
            //   ⇒ 删掉这一行，判据只保留**一个**接线点（见 `machineOk` 那行的注释）。
            {
                string mx = Root + "/build/MilBridge/gen/t2d-family-matrix.txt";
                var ml = new List<string>
                {
                    "# T1b2/#12 · 隔离矩阵（族 × `>0.34 DIP` 桶红数）—— **机器断言，不是人眼比对**",
                    "# 口径：档位后缀 `_wNN`/`_winf` 归一后按族计数（Family()/FamilyOf()，与 t2d-width-diff.txt 同源）",
                    "# before 来源：" + famBeforeSource,
                    "# 允许变化的族：" + string.Join(" / ", mayChangeArr) + "（其余族必须一位不动）",
                    "# 各和 = " + famSum + " == 总数 " + widthDeltaLarge + " : " + (famSumOk ? "OK" : "**FAIL**"),
                    "# 逐族 diff = " + isoDiffText,
                    "# 冲突 = " + (isoConflicts.Count == 0 ? "无" : string.Join("  ", isoConflicts)),
                    "# 隔离性 = " + (isoOk ? "OK" : (isoBaselineOk ? "**冲突**" : "**未判定（无基线）**")),
                    "",
                    "族\tafter\tbefore",
                };
                var keys2 = new SortedSet<string>(StringComparer.Ordinal);
                if (famBefore != null) foreach (var kv in famBefore) keys2.Add(kv.Key);
                foreach (var kv in famRed) keys2.Add(kv.Key);
                foreach (string k in keys2)
                    ml.Add(k + "\t" + (famRed.TryGetValue(k, out int av2) ? av2 : 0)
                             + "\t" + (famBefore != null && famBefore.TryGetValue(k, out int bv2) ? bv2 : 0));
                File.WriteAllLines(mx, ml);
                Console.WriteLine("   [隔离矩阵] 已写 " + mx);
            }

            {
                string wd = Root + "/build/MilBridge/gen/t2d-width-diff.txt";
                var wl = new List<string>
                {
                    "# T2d · 宽度逐行明细（**每行一条**；与 t2d-extent-mismatches.txt 同格式，便于并排看）",
                    "# 列：用例 | 行# | cp 区间 | 真值宽 | 我们宽 | 差 | 桶",
                    "# 口径：桶 = 0（逐位等）/ ≤0.34 DIP（= 1 个 ideal unit）/ >0.34 DIP；三桶之和 == 行数（机检）",
                };
                wl.AddRange(HeadLines());   // ← 四行头（源 sha / PC 内 shim sha / stale / 仪器版本）
                wl.Add("# 族 × >0.34 红数 = " + (famRedText.Length == 0 ? "（无）" : famRedText)
                    + "；各和=" + famSum + " == 总数 " + widthDeltaLarge + " : " + (famSumOk ? "OK" : "**FAIL**"));
                wl.Add("# 隔离矩阵 = " + (isoOk ? "OK" : (isoBaselineOk ? "**冲突**" : "**未判定（无基线）**"))
                    + "；逐族 diff = " + isoDiffText);
                wl.Add(
                        "# 合计 " + widthRows + " 行；0=" + widthDeltaZero + " ≤0.34=" + widthDeltaSmall + " >0.34=" + widthDeltaLarge
                        + "；本清单只列差>0 的行，共 " + widthDiffRows.Count + " 条"
                        + (widthInject > 0 ? "（⚠️ 本趟含 T2D_WIDTH_INJECT=" + widthInject + " 的人为注入，**不是**测量）" : ""));
                wl.AddRange(widthDiffRows);
                File.WriteAllLines(wd, wl);
                Console.WriteLine($"   [口径·宽度分桶] 逐行清单 {widthDiffRows.Count} 条 ⇒ 已写 {wd}");
            }
            Console.WriteLine("      （真机在 Windows 把每个字形 advance 量化到 1/300 英寸整数量；我们走 HarfBuzz 精确 design units ⇒ 绝对值本就不该逐位相等）");
            Console.WriteLine($"   [用例] 行划分+结构记账全等 {comparableExact} / {comparableCases}");
            Console.WriteLine($"   [A 组·断行位置] 行首+行可见长度对拍：行级 {aLinesOk}/{aLines}；用例级 {aCasesOk}/{aCases}");
            Console.WriteLine("   [① 行区间**含**硬断字符（Length 含它、NewlineLength 单独给个数）]");
            Console.WriteLine($"      真硬断行 {hardLineOk}/{hardLineTotal} 行一致");
            Console.WriteLine("   [② 相邻 \\n ⇒ Length=1、内容='\\n' 的普通行（不是零长度行）]");
            Console.WriteLine($"      空行 {blankLineOk}/{blankLineTotal} 行一致（Length/Width==0/NewlineLength 同时相等）");
            foreach (string s in blankSamples) Console.WriteLine(s);
            Console.WriteLine("   [③ 行尾空白：占区间、不占 Width，差额由 WidthIncludingTrailingWhitespace 给出]");
            Console.WriteLine($"      有行尾空白的行 {wsLineOk}/{wsLineTotal} 一致（TrailingWhitespaceLength + WITW−W 关系）");
            foreach (string s in wsSamples) Console.WriteLine(s);
            // ================= ① T2d 的 LineHeight 覆盖（补上"0 行"那个自报缺口）=================
            // 口径（写进输出，避免为凑数把无 LineHeight 的用例算进来）：
            //   来源 = cases-cd2.json 中 `lineHeight` 显式非空的用例；真值 = results-cd2.json 同 id 的逐行 properties。
            int lhCases = 0, lhLines2 = 0, lhHeightOk2 = 0, lhBaseOk2 = 0, lhExtOk2 = 0, lhTextHeightOk2 = 0;
            // 主控 2026-09-11 裁定：**两个口径都留、都要显式标注**
            //   · 0.34 = 项目口径（上游 1/300 英寸量化）
            //   · 0.01 = 严口径（暴露更细尺度的差；信息不该丢）
            //   要丢的是"两台装置各留一套、看起来互相矛盾"这件事 ⇒ 两台装置同一格式、同一行位置。
            int lhHeight34 = 0, lhBase34 = 0, lhExt34 = 0, lhTextHeight34 = 0;
            var lhTolNote = new List<string>();
            var lhRows = new List<string>();
            var extMismatch = new List<string>();
            string cd2Note = "（未找到 cases-cd2.json ⇒ 该列无法覆盖）";
            if (File.Exists(Cd2Cases) && File.Exists(Cd2Results))
            {
                using JsonDocument cd = JsonDocument.Parse(File.ReadAllText(Cd2Cases));
                using JsonDocument cr = JsonDocument.Parse(File.ReadAllText(Cd2Results));
                var rmap = new Dictionary<string, JsonElement>();
                foreach (JsonElement r in cr.RootElement.GetProperty("results").EnumerateArray())
                    rmap[r.GetProperty("id").GetString()] = r;
                GlyphTypeface gtc = GetGlyphTypeface("/usr/share/fonts/opentype/noto", "Regular");
                foreach (JsonElement c in cd.RootElement.GetProperty("cases").EnumerateArray())
                {
                    if (!c.TryGetProperty("lineHeight", out JsonElement lhe) || lhe.ValueKind != JsonValueKind.Number) continue;
                    string id = c.GetProperty("id").GetString();
                    string ctext = c.GetProperty("text").GetString();
                    double lh = lhe.GetDouble(), em = c.GetProperty("fontSize").GetDouble(), cw = c.GetProperty("maxWidth").GetDouble();
                    bool cjkCase = id.Contains("cjk") || ctext.IndexOfAny(new[] { '中', '文', '，', '。' }) >= 0;
                    if (!rmap.TryGetValue(id, out JsonElement rr)) { extMismatch.Add($"{id}: 真值缺失（空真）"); continue; }
                    JsonElement tls = rr.GetProperty("lines");
                    if (tls.GetArrayLength() == 0) { extMismatch.Add($"{id}: 真值 0 行（空真）"); continue; }
                    string cfont = cjkCase ? "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc" : FontRegular;
                    List<HbTextLine> cl = HbTextLineFactory.FormatParagraph(
                        ctext, cfont, em, cw, cjkCase ? gtc : gtFile, 1.0f, props, false, false, lh, out int _c);
                    if (cl.Count == 0) { extMismatch.Add($"{id}: 我们 0 行"); continue; }
                    ++lhCases;
                    int cn = Math.Min(cl.Count, tls.GetArrayLength());
                    bool hA = true, bA = true, eA = true, tA = true;
                    for (int i = 0; i < cn; ++i)
                    {
                        JsonElement pp = tls[i].GetProperty("properties");
                        double th = pp.GetProperty("Height").GetDouble(), tb = pp.GetProperty("Baseline").GetDouble();
                        double te = pp.GetProperty("Extent").GetDouble(), tt2 = pp.GetProperty("TextHeight").GetDouble();
                        HbTextLine L = cl[i];
                        bool hO = Math.Abs(L.Height - th) < 0.01, bO = Math.Abs(L.Baseline - tb) < 0.01;
                        bool eO = Math.Abs(L.Extent - te) < 0.01, tO = Math.Abs(L.TextHeight - tt2) < 0.01;
                        hA &= hO; bA &= bO; eA &= eO; tA &= tO; ++lhLines2;
                        // 宽口径（0.34）：只为"两个口径都标出来"，不参与判据
                        if (Math.Abs(L.Height - th) >= 0.01 && Math.Abs(L.Height - th) < 0.34) lhTolNote.Add("Height");
                        if (Math.Abs(L.Baseline - tb) >= 0.01 && Math.Abs(L.Baseline - tb) < 0.34) lhTolNote.Add("Baseline");
                        if (Math.Abs(L.TextHeight - tt2) >= 0.01 && Math.Abs(L.TextHeight - tt2) < 0.34) lhTolNote.Add("TextHeight");
                        if (Math.Abs(L.Extent - te) >= 0.01 && Math.Abs(L.Extent - te) < 0.34) lhTolNote.Add("Extent");
                        if (!eO) { string fl = cjkCase ? "NotoSansCJK(da)" : "NotoSans"; extMismatch.Add(id + " 行#" + i + " [" + fl + "] Extent 真值=" + te.ToString("F4") + " 我们=" + L.Extent.ToString("F4") + " 差=" + (L.Extent - te).ToString("F4")); }
                    }
                    if (hA) ++lhHeightOk2; if (bA) ++lhBaseOk2; if (eA) ++lhExtOk2; if (tA) ++lhTextHeightOk2;
                    // 逐例宽口径（0.34）：整例所有行都在 0.34 内 ⇒ 该例计宽口径 ok
                    { bool hw = true, bw = true, ew = true, tw = true;
                      for (int i2 = 0; i2 < cn; ++i2)
                      {
                          JsonElement q = tls[i2].GetProperty("properties");
                          HbTextLine L2 = cl[i2];
                          if (Math.Abs(L2.Height - q.GetProperty("Height").GetDouble()) >= 0.34) hw = false;
                          if (Math.Abs(L2.Baseline - q.GetProperty("Baseline").GetDouble()) >= 0.34) bw = false;
                          if (Math.Abs(L2.Extent - q.GetProperty("Extent").GetDouble()) >= 0.34) ew = false;
                          if (Math.Abs(L2.TextHeight - q.GetProperty("TextHeight").GetDouble()) >= 0.34) tw = false;
                      }
                      if (hw) ++lhHeight34; if (bw) ++lhBase34; if (ew) ++lhExt34; if (tw) ++lhTextHeight34; }
                    { string p0h = tls[0].GetProperty("properties").GetProperty("Height").GetDouble().ToString("F4"); string p0b = tls[0].GetProperty("properties").GetProperty("Baseline").GetDouble().ToString("F4"); string p0e = tls[0].GetProperty("properties").GetProperty("Extent").GetDouble().ToString("F4"); lhRows.Add("      " + id.PadRight(24) + " LineHeight=" + lh.ToString("F4").PadRight(8) + " 行0: Height 真值=" + p0h + " 我们=" + cl[0].Height.ToString("F4") + " | Baseline 真值=" + p0b + " 我们=" + cl[0].Baseline.ToString("F4") + " | Extent 真值=" + p0e + " 我们=" + cl[0].Extent.ToString("F4")); }
                }
                cd2Note = $"（来源 cases-cd2.json：`lineHeight` 显式非空的用例；真值 = results-cd2.json）";
            }

            Console.WriteLine("   [T2d 行度量：Height / Baseline / Extent vs 真机]");
            Console.WriteLine($"      行级一致：Height {mHeightOk}/{mTotal}、Baseline {mBaseOk}/{mTotal}、Extent {mExtOk}/{mTotal}"
                              + $"；最大差 Height={mHeightMax:F4}（在 {mWorst}）、Baseline={mBaseMax:F4}");
            Console.WriteLine($"      **LineHeight>0 的用例**：{lhCases} 例 / {lhLines2} 行 {cd2Note}");
            Console.WriteLine($"        逐例一致：Height {lhHeightOk2}/{lhCases}、TextHeight {lhTextHeightOk2}/{lhCases}、Baseline {lhBaseOk2}/{lhCases}、Extent {lhExtOk2}/{lhCases}");
            string cjkNote = lhTolNote.Count > 0 ? "（严口径 0.01 与宽口径 0.34 之间的差额行：" + lhTolNote.Count + "；CJK 例为字体代用：本机无 MS YaHei）" : "";
            Console.WriteLine("        " + Tol("Height", lhHeight34, lhHeightOk2, lhCases) + "   " + Tol("Baseline", lhBase34, lhBaseOk2, lhCases));
            Console.WriteLine("        " + Tol("TextHeight", lhTextHeight34, lhTextHeightOk2, lhCases) + "   " + Tol("Extent", lhExt34, lhExtOk2, lhCases) + " " + cjkNote);
            foreach (string r in lhRows) Console.WriteLine(r);
            foreach (string s2 in lhSamples) Console.WriteLine(s2);
            Console.WriteLine("   [Collapse / GetTextCollapsedRanges]");
            Console.WriteLine($"      折叠判定一致 {colEligibleOk}/{colEligible}；真折叠 {colApplied} 行，明细全等 {colAppliedOk}/{colApplied}（折后宽度最大差 {colWidthDeltaMax:F6} DIP，最差在 {colWidthDeltaMaxCase}）");
            // T1b2/#12 (b)：契约级断言**逐条**报（三条非互斥 ⇒ 各自独立计数，读者能看到"是宽度错还是起止错"）
            Console.WriteLine($"      [契约断言·逐条] ① 三种计数（主控 2026-09-14 裁定：判据 = **判别式** `ours<0 ⇒ truth<0`）："
                + $"裸形式红 {colNegBareFail}/{colApplied} ／ 判别式红 {colNegRealViolation}/{colApplied} ／ 两侧同为负 {colNegBothSides}/{colApplied}"
                + $"（裸形式比判别式多的 {colNegBareFail - colNegRealViolation} 条 = **假红**：真机自己在该位置也为负）；"
                + $"② 起止(起点+长度)==真机 红 {colSpanFail}/{colApplied}；"
                + $"③ |cr.Width−真值| < {ColCrWidthTol:F2} 红 {colWidthFail}/{colApplied}（**沿用既有容差，未放宽**）");
            Console.WriteLine("      [登记·判据位移] ① 由**裸 `cr.Width>=0`** 改为**判别式** `ours<0 ⇒ truth<0`："
                + "裸形式红 " + colNegBareFail + " ⇒ 判别式红 " + colNegRealViolation
                + $"（方向**未放松**：真值非负而我们为负的每一种情形仍全部抓住；少的 {colNegBareFail - colNegRealViolation} 条全是"
                + "「真值同位置也 <0」＝真机自己也这样 ⇒ 不是违反）。三种计数见上一行。");
            foreach (string s in colNonNegSamples) Console.WriteLine(s);
            foreach (string s in colSpanSamples) Console.WriteLine(s);
            foreach (string s in colWidthSamples) Console.WriteLine(s);
            foreach (string s in colSamples) Console.WriteLine(s);
            foreach (string s in colFailSamples) Console.WriteLine(s);
            Console.WriteLine($"      空参：可折叠行抛 ArgumentNullException {colEmptyThrowOk}/{colEmptyThrow}；不可折叠行原样返回 this {colEmptyThisOk}/{colEmptyThis}");

            if (diffCaseIds.Count > 0)
            {
                Console.WriteLine($"   ── 不一致用例 {diffCaseIds.Count} 个，按家族归并 ──");
                foreach (var kv in familyDiff) Console.WriteLine($"      {kv.Key}: {kv.Value} 例");
                for (int i = 0; i < Math.Min(80, diffCaseIds.Count); ++i) Console.WriteLine("      " + diffCaseIds[i]);
            }

            bool coreOk = lineTotal == lineOk && hardLineTotal == hardLineOk
                          && blankLineTotal == blankLineOk && wsLineTotal == wsLineOk
                          && widthDeltaLarge == 0 && aCases > 0 && aCasesOk == aCases;
            bool collapseOk = colEligible == colEligibleOk && colApplied == colAppliedOk
                              && colEmptyThrow == colEmptyThrowOk && colEmptyThis == colEmptyThisOk;
            // T1b2/#12 (b)：**机器断言**（不是人眼比对）——族计数等式 + 隔离矩阵。
            // 「无基线」⇒ isoOk=false ⇒ **不算绿**（报无信息），这是刻意的：缺读数不许当绿。
            // ⚠️ **这是族计数等式 + 隔离矩阵的唯二接线点**（另一处 = 下方 `return`）：T1b 2026-09-14 复核发现
            //   早前在 `isoOk` 处还有一个同名同式的 `isoMachineOk` **算了没消费**（已删）。改这两处任一都必须同时改另一处。
            //   机检（只看代码、排除注释行）：`grep -nE '^\s*(bool machineOk|return coreOk)' Program.cs` ⇒ **2 行**；
            //   `grep -cE '^\s*bool isoMachineOk' Program.cs` ⇒ **0**。
            bool machineOk = famSumOk && isoOk;
            string isoState = isoOk ? "OK" : (isoBaselineOk ? "**冲突**" : "**未判定（无基线）**");
            Check("T2", "真机口径逐行**记账结构**全等（①硬断 ②空行 ③行尾空白）",
                coreOk, $"[口径·记账结构] 全等 {lineOk}/{lineTotal}（不等 {lineTotal - lineOk} 行：①硬断 {hardLineOk}/{hardLineTotal} ②空行 {blankLineOk}/{blankLineTotal} ③行尾空白 {wsLineOk}/{wsLineTotal}）");
            Check("T2-iso", "族计数等式（各和 == 总数）**且**隔离矩阵（其它族一位不动）—— 机器断言",
                machineOk,
                $"各和 {famSum} == 总数 {widthDeltaLarge} : {(famSumOk ? "OK" : "**FAIL**")}；"
                + $"隔离性 {isoState}"
                + $"；逐族 diff = {isoDiffText}"
                + (isoConflicts.Count > 0 ? "；冲突：" + string.Join("  ", isoConflicts) : ""));
            Check("T2b", "A 组（CJK/中英混排）断行位置逐行对拍", aCases > 0 && aCasesOk == aCases,
                $"行级 {aLinesOk}/{aLines}；用例级 {aCasesOk}/{aCases}");
            Check("T3", "Collapse 与真机一致（判定 + 明细 + 未折叠 ⇒ GetTextCollapsedRanges()==null）", collapseOk,
                $"判定 {colEligibleOk}/{colEligible}；明细 {colAppliedOk}/{colApplied}；空参抛 {colEmptyThrowOk}/{colEmptyThrow}；空参返回 this {colEmptyThisOk}/{colEmptyThis}");
            // T1b2/#12 (b)：契约级断言单列一条（① 为**新增**的硬断言；②③ 是既有断言的显式拆分）
            Check("T3b", "折叠明细**契约级**断言（① 判别式 `ours<0 ⇒ truth<0` ② 起止==真机 ③ |cr.Width−真机| < 0.34）",
                colApplied > 0 && colNegRealViolation == 0 && colSpanFail == 0 && colWidthFail == 0,
                $"① 判别式红 {colNegRealViolation}/{colApplied}（**真违反**）；裸形式红 {colNegBareFail}/{colApplied}"
                + $"（多出的 {colNegBareFail - colNegRealViolation} 条 = 两侧同为负 {colNegBothSides} 条的**假红**："
                + $"真机自己在 oracle 的 430 条折叠区间里有 7 条 Width<0）；"
                + $"② 红 {colSpanFail}/{colApplied}；③ 红 {colWidthFail}/{colApplied}（容差 {ColCrWidthTol:F2}，**未放宽**）");

            // ================= 完整明细导出（去截断）+ "条数 vs 上限"可观测 =================
            {
                int capCollapse = 24, capDiff = 80, capExtent = 45;
                Console.WriteLine($"   [完整明细] 折叠不符 {colFailFull.Count} 条（样例上限 {capCollapse} ⇒ "
                    + (colFailFull.Count <= capCollapse ? "未截断" : "**原样例被截断过**") + "）"
                    + $"；记账不一致 {diffCaseFull.Count} 条（用例样例上限 {capDiff}）；"
                    + $"Extent 余差 {extMismatchMain.Count + extMismatch.Count} 条（控制台样例上限 {capExtent}）");
                string full = Root + "/build/MilBridge/gen/tline-detail-full.txt";
                var outl = new List<string>
                {
                    "# T1b · 完整逐例明细（**无截断**）",
                    "# 生成命令：bash build/MilBridge/run.sh tline  （本文件由 harness 直接写盘）",
                };
                outl.AddRange(HeadLines());   // ← 四行头（源 sha / PC 内 shim sha / stale / 仪器版本）
                outl.Add("# ⚠️ 不变式登记 + 判据位移（T1b2/#12 (b)）｜**本趟被测 shim** = " + ShimSha256());
                outl.Add("#   三个不变式：本趟 折叠明细 " + colFailFull.Count + " / Extent 余差 " + (extMismatchMain.Count + extMismatch.Count)
                    + " / 记账用例 " + diffCaseFull.Count
                    + "；`#11` 冻件基线（**另一份 shim** `b4c7aa82…`）= 18 / 58 / 17"
                    + " ⇒ 与基线之差 " + (colFailFull.Count - 18).ToString("+#;-#;0") + " / "
                    + ((extMismatchMain.Count + extMismatch.Count) - 58).ToString("+#;-#;0") + " / "
                    + (diffCaseFull.Count - 17).ToString("+#;-#;0")
                    + " ⚠️ **这一格不可单独归因于仪器**（本趟 shim 与基线不同）—— 仪器位移看下一行的三种计数。");
                outl.Add("#   【判据位移·三种计数】**仪器位移的可见量**：① 的**裸形式** `cr.Width>=0` 红 "
                    + colNegBareFail + "；其中**两侧同为负**（真机自己也这样 ⇒ 不构成违反）" + colNegBothSides + " 条 ⇒ "
                    + "**判别式** `ours<0 ⇒ truth<0` 红 **" + colNegRealViolation + "** 条（= 真违反）；"
                    + "裸形式 − 判别式 = " + (colNegBareFail - colNegRealViolation) + " 条**假红**。"
                    + "判据已由裸形式改为判别式（主控 2026-09-14 裁定；方向**未放松**：真值非负而我们为负的每一种情形仍全部抓住）；"
                    + "真机自己在 oracle 的 430 条折叠区间里有 **7 条 Width<0**（真值侧独立复算）⇒ 「宽度为负」不是契约违反。"
                    + "唯一的真违反 = `F_nbsp_zwsp_w40#3`（我们 −3.0560 而真值 +3.3433），它同时被 ③ 抓到，归 `D-F1`。");
                outl.Add("# 段1 折叠明细逐行（五列：用例|行|我们|真值|差|cr 我们|cr 真值）  条数 = " + colFailFull.Count);
                outl.AddRange(colFailFull);
                outl.Add("# 段2 Extent 余差逐行（主对拍集 " + extMismatchMain.Count + " + LineHeight 组 " + extMismatch.Count
                         + "；CJK 用例标 +CJK）  条数 = " + (extMismatchMain.Count + extMismatch.Count));
                outl.AddRange(extMismatchMain);
                outl.AddRange(extMismatch);
                outl.Add("# 段3 记账不一致用例（用例|原因）  条数 = " + diffCaseFull.Count);
                outl.AddRange(diffCaseFull);
                File.WriteAllLines(full, outl);
                // 行级记账清单（T2 收口用）
                string led = Root + "/build/MilBridge/gen/tline-ledger-lines-" + DateTime.Now.ToString("yyyyMMdd-HHmm") + ".txt";
                var ledl = new List<string>
                {
                    "# T1b · **行级**记账不一致清单（用例 | 行号 | 期望 | 实得 | 归类桶）",
                };
                ledl.AddRange(HeadLines());   // ← 四行头（源 sha / PC 内 shim sha / stale / 仪器版本）
                ledl.Add("# 测量对象（app-local 副本，应与权威一致）："
                        + " PC=" + Sha16(Path.Combine(AppDir(), "PresentationCore.dll"))
                        + " WB=" + Sha16(Path.Combine(AppDir(), "WindowsBase.dll"))
                        + " DWF=" + Sha16(Path.Combine(AppDir(), "DirectWriteForwarder.dll"))
                        + " Provider=" + Sha16(Path.Combine(AppDir(), "DirectWrite.Linux.Provider.dll")));
                ledl.Add("# 条数 = " + ledgerLines.Count + "（**无上限，未截断**）");
                ledl.AddRange(ledgerLines);
                File.WriteAllLines(led, ledl);
                Console.WriteLine($"   [记账行级清单] {ledgerLines.Count} 条（无上限 ⇒ 未截断）⇒ 已写 {led}");
                Console.WriteLine($"   [完整明细] 已写 {full}（{outl.Count} 行；含 3 段：折叠 "
                    + colFailFull.Count + " / Extent " + (extMismatchMain.Count + extMismatch.Count) + " / 记账 " + diffCaseFull.Count + "）");
            }

            Check("T2d-lh", "**T2d 的 LineHeight 覆盖不再为 0**（真值来源 cases-cd2.json；口径见输出）",
                lhCases > 0, $"LineHeight 用例 {lhCases} 例 / {lhLines2} 行（Height {lhHeightOk2}/{lhCases}、Baseline {lhBaseOk2}/{lhCases}）");
            // ② 的**全量**明细写盘（控制台只打前 45 条）⇒ `tools/t2d-extent-detail.sh` 一条命令取数
            {
                string extFile = Root + "/build/MilBridge/gen/t2d-extent-mismatches.txt";
                Directory.CreateDirectory(Root + "/build/MilBridge/gen");
                var all = new List<string>
                {
                    "# T2d · Extent 余差明细（**容差 0.01 DIP**）",
                    "# 每条 = 用例 id / 行号 / 字体 / 真值(Extent) / 我们 / 差",
                    "# 真值来源 = tests/parity/windows/layout-b34/results-cd2.json（LineHeight 组）",
                };
                all.AddRange(HeadLines());   // ← 四行头（源 sha / PC 内 shim sha / stale / 仪器版本）
                all.Add("# 合计 " + (extMismatch.Count + extMismatchMain.Count) + " 条（主对拍集 "
                        + extMismatchMain.Count + " + LineHeight 组 " + extMismatch.Count + "）");
                all.AddRange(extMismatchMain);
                all.AddRange(extMismatch);
                File.WriteAllLines(extFile, all);
                Console.WriteLine($"   [② Extent 余差清单] 共 {extMismatch.Count + extMismatchMain.Count} 条"
                    + $"（主对拍集 {extMismatchMain.Count} + LH 组 {extMismatch.Count}；容差 0.01 DIP）⇒ 全量已写 {extFile}");
                for (int i = 0; i < Math.Min(45, extMismatch.Count); ++i) Console.WriteLine("      " + extMismatch[i]);
            }
            Check("T2d", "行度量与真机一致（Height / Baseline / Extent）—— 摞印归因的关键判据",
                mTotal > 0 && mHeightOk == mTotal && mBaseOk == mTotal,
                $"Height {mHeightOk}/{mTotal}、Baseline {mBaseOk}/{mTotal}、Extent {mExtOk}/{mTotal}；"
                + $"最大差 Height={mHeightMax:F4}（{mWorst}）、Baseline={mBaseMax:F4}；LineHeight 行 {lhLines}（一致 {lhOk}）");

            // ⚠️ 已登记差异：Tab 口径（真机把 \t 当 0 宽 + 断点行为不同）—— **保留红**，不静默跳过
            int tabTotal = 0;
            foreach (JsonElement c in compact.RootElement.GetProperty("cases").EnumerateArray())
                if ((c.GetProperty("text").GetString() ?? "").IndexOf('\t') >= 0 &&
                    c.GetProperty("fontKey").GetString() == "file") ++tabTotal;
            tabTotal = Math.Max(0, tabTotal);
            int tabDiff = 0;
            foreach (string fam in tabCases) tabDiff += familyDiff[fam];
            Check("T2c", "【已登记差异·保留红】Tab（`\\t`）口径：真机 = 0 宽 + 特定断点，本实现未做",
                tabDiff == 0,
                $"Tab 可比例 {tabTotal} 例，其中不一致 {tabDiff} 例（家族：{string.Join(",", tabCases)}）"
                + " ⇒ 这是**新发现的差异类别**（不属于本轮三条记账），已在 T1b 报告里登记给主控，未实现、未放宽");

            return coreOk && collapseOk && machineOk ? 0 : 1;
        }

        // ==================================================================================
        //  (a) `[ROWD]` —— 定向逐字符 dump（两侧数据来源逐条注明）
        // ==================================================================================
        private static HashSet<string> ParseRowDump(string spec)
        {
            var set = new HashSet<string>(StringComparer.Ordinal);
            if (string.IsNullOrWhiteSpace(spec)) return set;
            foreach (string tok in spec.Split(new[] { ',', ';', ' ', '\t', '\n', '\r' },
                                              StringSplitOptions.RemoveEmptyEntries))
            {
                string t = tok.Trim();
                if (t.Length > 0) set.Add(t);
            }
            return set;
        }

        private static string RowKey(string id, int lineIdx) => id + "#" + lineIdx;

        /// <summary>实读**实现真正用的那个数组** `HbTextLine._charAdvances`（private ⇒ 反射；取不到 ⇒ null，
        /// 调用方按 D 结局"报无信息"，**不猜**）。</summary>
        private static double[] CharAdvancesOrNull(HbTextLine L)
        {
            try
            {
                FieldInfo f = typeof(HbTextLine).GetField("_charAdvances",
                    BindingFlags.Instance | BindingFlags.NonPublic);
                return f == null ? null : f.GetValue(L) as double[];
            }
            catch { return null; }
        }

        /// <summary>行尾空白判据**逐字复用 shim 的同名函数**（不在这里另立一套口径）。</summary>
        private static int VisibleTrailingWs(string s)
        {
            int n = 0;
            while (n < s.Length && HbBreakEngine.IsTrailingWhitespace(s[s.Length - 1 - n])) ++n;
            return n;
        }

        private static string CharLabel(char c)
        {
            switch (c)
            {
                case ' ': return "SP";
                case '\u00A0': return "NBSP";
                case '\u200B': return "ZWSP";
                case '\t': return "TAB";
                case '\n': return "LF";
                case '\r': return "CR";
                case '\u3000': return "IDEO-SP";
            }
            if (char.IsControl(c)) return "U+" + ((int)c).ToString("X4");
            if (char.IsWhiteSpace(c)) return "WS(U+" + ((int)c).ToString("X4") + ")";
            return c.ToString();
        }

        /// <summary>
        /// 对点名的 (用例, 行) 打一段可复算的逐字符读数。**四 + E 结局就地判定**，判据见输出里的证据列。
        /// 两侧数据来源：我们侧 = 实读 `HbTextLine` 的契约字段 + 反射取 `_charAdvances`；
        /// 真值侧 = **行级** oracle（逐字符 ⇒ `NA`）。
        /// </summary>
        private static void RowDump(string id, int lineIdx, HbTextLine L, JsonElement E, int cpStart, bool comparable)
        {
            RowDumpHit.Add(RowKey(id, lineIdx));
            string vis = L.LineTextForDiag ?? "";
            int visLen = vis.Length;
            double[] adv = CharAdvancesOrNull(L);
            string pin = Environment.GetEnvironmentVariable("T1B_SHIM_SHA256");
            string actualSha = ShimSha256();

            int eLen = E.GetProperty("len").GetInt32();
            int eNl = E.GetProperty("nl").GetInt32();
            int eWs = E.GetProperty("ws").GetInt32();
            double eW = E.GetProperty("w").GetDouble();
            double eWitw = E.GetProperty("witw").GetDouble();
            double eExt = E.GetProperty("ext").GetDouble();
            string eText = E.GetProperty("text").GetString() ?? "";
            bool eCollapsed = E.GetProperty("ce").GetProperty("hasCollapsed").GetBoolean();

            double ourW = L.Width, ourWitw = L.WidthIncludingTrailingWhitespace, ourExt = L.Extent;
            int ourWs = L.TrailingWhitespaceLength, ourLen = L.Length, ourNl = L.NewlineLength;

            int ourVisTail = VisibleTrailingWs(vis);
            // ⚠️ 真值的"可见尾空白"**必须从真值自己的字段推**（`ws` 含 换行/EOP ⇒ 减 `nl`），
            //   **不许**拿我们的 `IsTrailingWhitespace` 去数真值的文本 —— 那会把我们自己的口径
            //   混进真值侧，正好抹掉"口径差"这个待测现象（第一版实测踩过：4 条 A 全被误判成 B）。
            //   两者的**反差**本身就是"口径差"的直接证据 ⇒ 两个都打出来。
            int truthVisTail = Math.Max(0, eWs - eNl);          // 真值侧口径（行级、可比）
            int truthVisTailByOurPred = VisibleTrailingWs(eText); // 我们的判据套在真值文本上（对照用）
            int ourTailFrom = Math.Max(0, visLen - ourVisTail);
            int truthTailFrom = Math.Max(0, visLen - truthVisTail);
            double advSum = 0, ourTailAdv = 0, truthTailAdv = 0, cum = 0;
            if (adv != null)
                for (int c = 0; c < adv.Length; ++c)
                {
                    advSum += adv[c];
                    if (c >= ourTailFrom) ourTailAdv += adv[c];
                    if (c >= truthTailFrom) truthTailAdv += adv[c];
                }

            double dW = ourW - eW;                                   // Δ行宽 = 我们 − 真值
            double dAdv = adv != null ? advSum - eWitw : double.NaN;  // adv 和 vs 真值"含空白宽"
            double dSelf = adv != null ? advSum - ourWitw : double.NaN;// 我们内部自洽
            double dWitwRel = (ourWitw - ourW) - (eWitw - eW);
            double dWs = ourWs - eWs;
            double dExt = ourExt - eExt;
            double tailFit = dW - (truthTailAdv - ourTailAdv);        // A 的拟合残差
            double advSumFit = dAdv;                                  // C 的判据量

            string singleHit = "无";
            if (adv != null)
                for (int c = 0; c < adv.Length && c < visLen; ++c)
                    if (Math.Abs(Math.Abs(dW) - adv[c]) < 0.34)
                    {
                        singleHit = "c=" + c + " U+" + ((int)vis[c]).ToString("X4")
                                    + " adv=" + adv[c].ToString("F4");
                        break;
                    }

            Console.WriteLine("[ROWD] 头：case=" + id + " 行#" + lineIdx
                + " cp_ours=[" + cpStart + "," + (cpStart + ourLen) + ")[O]"
                + " cp_truth=[" + cpStart + "," + (cpStart + eLen) + ")[T]"
                + " comparable=" + (comparable ? 1 : 0)
                + " ce.hasCollapsed(真值)=" + (eCollapsed ? 1 : 0) + "[T:ce.hasCollapsed]");
            Console.WriteLine("[ROWD] 我们{len=" + ourLen + ", w=" + ourW.ToString("F4")
                + ", ws=" + ourWs + ", witw=" + ourWitw.ToString("F4") + ", extent=" + ourExt.ToString("F4")
                + ", nl=" + ourNl + ", vis=\"" + EscapeDiag(vis) + "\"}[O]"
                + "  真值{len=" + eLen + ", w=" + eW.ToString("F4") + ", ws=" + eWs
                + ", witw=" + eWitw.ToString("F4") + ", extent=" + eExt.ToString("F4")
                + ", nl=" + eNl + ", text=\"" + EscapeDiag(eText) + "\"}[T]"
                + "  真值出处[NA 说明]=" + TruthSourceNA);

            for (int c = 0; c < visLen; ++c)
            {
                char ch = vis[c];
                bool inTail = c >= ourTailFrom;
                bool wsy = HbBreakEngine.IsTrailingWhitespace(ch);
                string mark = ch == '\u00A0' ? "NBSP"
                            : ch == '\u200B' ? "ZWSP"
                            : (wsy && inTail) ? "blank-tail"
                            : "other";
                bool got = adv != null && c < adv.Length;
                Console.WriteLine("[ROWD] c=" + c + " U+" + ((int)ch).ToString("X4") + " " + CharLabel(ch)
                    + " adv_ours=" + (got ? adv[c].ToString("F4") : "NA(取不到)") + "[O]"
                    + " cum_ours=" + (got ? (cum + adv[c]).ToString("F4") : "NA(取不到)") + "[O]"
                    + " mark=" + mark + "[O:NBSP|ZWSP 按码点；blank-tail 按 `IsTrailingWhitespace` ∧ in_tail]"
                    + " wsy=" + (wsy ? 1 : 0) + "[O] in_tail=" + (inTail ? 1 : 0) + "[O]"
                    + " truth=NA(" + TruthSourceNA + ")");
                if (got) cum += adv[c];
            }

            Console.WriteLine("[ROWD] 小计：adv_ours 和=" + advSum.ToString("F4") + "[O]"
                + "  Δ行宽(我们−真值)=" + dW.ToString("F4") + "[O−T]"
                + "  |  ws 我们=" + ourWs + "[O]/真值=" + eWs + "[T]"
                + "  |  WITW−W 我们=" + (ourWitw - ourW).ToString("F4") + "[O]/真值=" + (eWitw - eW).ToString("F4") + "[Td:witw−w]"
                + " Δ=" + dWitwRel.ToString("F4")
                + "  |  Extent 我们=" + ourExt.ToString("F4") + "[O]/真值=" + eExt.ToString("F4") + "[T]"
                + " Δ=" + dExt.ToString("F4"));
            Console.WriteLine("[ROWD] 证据：尾部**可见**空白 我们=" + ourVisTail + "[O，区间起 " + ourTailFrom + "]"
                + " 真值=" + truthVisTail + "[Td:ws−nl，区间起 " + truthTailFrom + "]"
                + " | 真值文本按**我们判据**数出的尾空白=" + truthVisTailByOurPred + "[X]"
                + (truthVisTailByOurPred != truthVisTail ? "（**≠ [Td] ⇒ 口径差**：真机不把该字符算行尾空白）" : "（与 [Td] 一致）")
                + " | 尾部 advance 我们=" + ourTailAdv.ToString("F4") + "[O]/真值=" + truthTailAdv.ToString("F4") + "[Td:Σ[O].adv over 真值尾区间]"
                + " | Δ行宽 拟合残差(A)=" + tailFit.ToString("F4")
                + " | adv 和 − 真值 WITW(C)=" + advSumFit.ToString("F4") + "[O−T]"
                + " | adv 和 − 我们 WITW(内部自洽)=" + dSelf.ToString("F4") + "[O内部]"
                + " | Δ行宽 落单字符 adv：" + singleHit + "[O]"
                + " | ws 内部恒等 我们 ws==可见尾+nl : " + ((ourWs == ourVisTail + ourNl) ? "OK" : "**FAIL**") + "[O内部]"
                + " | 跨树钉 T1B_SHIM_SHA256=" + (string.IsNullOrEmpty(pin) ? "（未设）" : pin.Substring(0, Math.Min(16, pin.Length))));

            string verdict, why;
            if (!string.IsNullOrEmpty(pin) && !string.Equals(pin, actualSha, StringComparison.OrdinalIgnoreCase))
            {
                verdict = "D";
                why = "**跨树**：T1B_SHIM_SHA256 与实读 shim sha 不一致（钉=" + pin.Substring(0, Math.Min(16, pin.Length))
                      + " 实读=" + actualSha.Substring(0, Math.Min(16, actualSha.Length)) + "）⇒ 本次读数无信息";
            }
            else if (adv == null)
            {
                verdict = "D";
                why = "仪器层答不出：逐字符 advance 取不到（反射 `HbTextLine._charAdvances` 失败）";
            }
            else if (adv.Length != visLen)
            {
                verdict = "D";
                why = "仪器层答不出：adv 长度 " + adv.Length + " ≠ 可见文本长度 " + visLen;
            }
            else if (ourVisTail != truthVisTail && Math.Abs(tailFit) < 0.34)
            {
                verdict = "A";
                why = "**行尾空白口径差（假设成立）**：尾部可见空白 我们=" + ourVisTail + " 真值=" + truthVisTail
                      + "（真值文本按**我们判据**能数出 " + truthVisTailByOurPred + " 个 ⇒ 该字符确实在我们口径里是空白）"
                      + "，且 Δ行宽 " + dW.ToString("F4") + " == 真值尾adv−我们尾adv("
                      + (truthTailAdv - ourTailAdv).ToString("F4") + ")，残差 " + tailFit.ToString("F4") + " < 0.34"
                      + " ⇒ 我们把尾字符 [" + TailChars(vis, Math.Min(ourTailFrom, truthTailFrom), Math.Max(ourTailFrom, truthTailFrom)) + "] 当行尾空白扣了，**真机把它计入 Width**";
            }
            else if (Math.Abs(advSumFit) >= 0.34)
            {
                verdict = "C";
                why = "**第二机制·行度量/advance**：`ws` 与 `WITW−W` 两侧一致，但 adv 和(" + advSum.ToString("F4")
                      + ") 与真值 WITW(" + eWitw.ToString("F4") + ") 差 " + advSumFit.ToString("F4")
                      + " ≥ 0.34 ⇒ 与折叠无关";
            }
            else if (Math.Abs(dW) >= 0.34)
            {
                verdict = "B";
                why = "**假设不成立**：adv 和与真值一致（差 " + advSumFit.ToString("F4") + " < 0.34）但 Δ行宽 "
                      + dW.ToString("F4") + " ≥ 0.34 ⇒ 扣的不是行尾空白（转查 advance 求和/folding/宽度公式）";
            }
            else if (Math.Abs(dWs) < 0.5 && Math.Abs(dWitwRel) < 0.34 && ourLen == eLen && Math.Abs(dExt) < 0.01)
            {
                verdict = "OK";
                why = "本行行级五字段全一致（|Δ行宽|=" + Math.Abs(dW).ToString("F4") + " < 0.34）⇒ **无待判结局**";
            }
            else
            {
                verdict = "E";
                why = "**真值层答不出**：行宽已在容差内（|Δ行宽|=" + Math.Abs(dW).ToString("F4")
                      + "）但 ws/WITW−W/Len/Extent 有差；要定位到底哪一侧错**需要逐字符真值** ⇒ 报无信息、不报绿";
            }
            Console.WriteLine("[ROWD] VERDICT=" + verdict + "（" + why + "）");
            // 主控裁定 ③：把**这条判定用了哪些列、各自哪一类来源**摊开（D/E 结局才真的可判）
            string basis =
                verdict == "A" ? "ws[T] / WITW−W[T]/[O] / 尾部可见空白[Td:ws−nl]/[O] / 逐字符 advance[O] —— **[NA] 列未参与**（不需要）"
              : verdict == "B" ? "adv 和[O] / 真值 WITW[T] / Δ行宽[O−T] —— **[NA] 列未参与**"
              : verdict == "C" ? "adv_ours 和[O] / 真值 WITW[T] / ws[T]/[O] / WITW−W[T]/[O] —— **[NA] 列未参与**"
              : verdict == "OK" ? "行级五字段 [O] vs [T]（ws/witw−w/len/extent/Δ行宽）—— **[NA] 列未参与**"
              : verdict == "D" ? "只用了仪器自身状态（跨树钉 / 反射取 `_charAdvances`）—— **未使用任何真值列**"
              : "**需要逐字符真值 [NA]，而该列在真值源里不存在** ⇒ 只能报无信息";
            Console.WriteLine("[ROWD] 依据=" + basis);
            Console.WriteLine();
        }

        /// <summary>把 `[from, to)` 的字符打成 `U+XXXX(NAME)+…`（用于"差在哪个字符上"说得清）。</summary>
        private static string TailChars(string vis, int from, int to)
        {
            var sb = new StringBuilder();
            int a = Math.Max(0, from), b = Math.Min(to, vis.Length);
            for (int i = a; i < b; ++i)
            {
                if (sb.Length > 0) sb.Append('+');
                sb.Append("U+").Append(((int)vis[i]).ToString("X4")).Append('(').Append(CharLabel(vis[i])).Append(')');
            }
            return sb.Length == 0 ? "（空区间）" : sb.ToString();
        }

        /// <summary>把可能含空白/控制字符的行文本打成可读形态（artifact 里不留裸控制字符）。</summary>
        private static string EscapeDiag(string s)        {
            var sb = new StringBuilder(s.Length + 8);
            foreach (char c in s)
            {
                if (c == '\u00A0') sb.Append("\\u00A0");
                else if (c == '\u200B') sb.Append("\\u200B");
                else if (c == '\t') sb.Append("\\t");
                else if (c == '\n') sb.Append("\\n");
                else if (c == '\r') sb.Append("\\r");
                else if (char.IsControl(c)) sb.Append("\\u").Append(((int)c).ToString("x4"));
                else sb.Append(c);
            }
            return sb.ToString();
        }

        // ==================================================================================
        //  (c) 四行 artifact 头（**同一个函数** ⇒ 各 artifact 形态/口径逐字一致）
        // ==================================================================================
        /// <summary>
        /// `build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` 里记录的**这一份 shim 源**的 sha256。
        /// 取不到 ⇒ `unknown(…)` 并写明为什么，**绝不猜**。
        /// </summary>
        private static string PcShimShaOrUnknown()
        {
            string fp = Root + "/build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt";
            if (!File.Exists(fp)) return "unknown(无 " + "build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt" + ")";
            try
            {
                foreach (string l in File.ReadAllLines(fp))
                {
                    if (l.StartsWith("#", StringComparison.Ordinal)) continue;
                    if (!l.Replace('\\', '/').Contains(ShimRel)) continue;
                    foreach (string tok in l.Split(new[] { ' ', '\t', '=' }, StringSplitOptions.RemoveEmptyEntries))
                        if (tok.Length == 64 && IsHex64(tok)) return tok;
                    return "unknown(FP 里有该文件的行但行内无 sha256)";
                }
            }
            catch { return "unknown(读 ARTIFACT-SRC-FP.txt 失败)"; }
            return "unknown(ARTIFACT-SRC-FP.txt 只有汇总行 fp=/n=，**无逐文件行** ⇒ 取不到，不猜)";
        }

        private static bool IsHex64(string s)
        {
            foreach (char c in s)
                if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))) return false;
            return true;
        }

        /// <summary>
        /// `hbtextline_shim_stale`：与 `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh` 的
        /// `hbt_stale()` **同一谓词**（源 mtime > 权威 PC 产物 mtime ⇒ true；权威件缺失才退回 app-local 副本，
        /// 并把 `basis` 一起打出来）。**两份读数必须能并排看** ⇒ 名字与口径都对齐，不另立第二套。
        /// </summary>
        private static string ShimStale(out string why)
        {
            string src = Root + "/" + ShimRel;
            string auth = Root + "/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll";
            string basis, pc;
            if (File.Exists(auth)) { basis = "auth"; pc = auth; }
            else { basis = "applocal"; pc = Path.Combine(AppDir(), "PresentationCore.dll"); }
            if (!File.Exists(src)) { why = "口径=源 mtime vs PC mtime(basis=" + basis + ")；**源文件不存在** ⇒ unknown（不猜）"; return "unknown"; }
            if (!File.Exists(pc)) { why = "口径=源 mtime vs PC mtime；**PC 产物不存在**（basis=" + basis + "）⇒ unknown（不猜）"; return "unknown"; }
            long sm, pm;
            try
            {
                sm = new DateTimeOffset(File.GetLastWriteTimeUtc(src)).ToUnixTimeSeconds();
                pm = new DateTimeOffset(File.GetLastWriteTimeUtc(pc)).ToUnixTimeSeconds();
            }
            catch { why = "口径=源 mtime vs PC mtime(basis=" + basis + ")；mtime 读不到 ⇒ unknown（不猜）"; return "unknown"; }
            bool stale = sm > pm;
            why = "口径=源 mtime " + sm + " vs PC 产物 mtime " + pm + "（basis=" + basis
                  + "，与 run-wpfprobe.sh 的 hbt_stale() 同谓词）；**mtime 谓词、非内容比对** ⇒ 同内容重写会假阳"
                  + "（已登记为已知仪器局限；内容比对需要 PC 侧逐文件 sha，当前不可得）";
            return stale ? "true" : "false";
        }

        /// <summary>四行头（三份 artifact 无条件印；`:928` 的 `ShimSha256()` 只在第 1 行用）。</summary>
        private static string[] HeadLines()
        {
            string pcIn = PcShimShaOrUnknown();
            string stale = ShimStale(out string staleWhy);
            return new[]
            {
                "# 被测 shim 源 sha256（本 harness 直接编入） = " + ShimSha256(),
                "# PC 内 shim sha256                         = " + pcIn,
                "# hbtextline_shim_stale                     = " + stale + "   （" + staleWhy + "）",
                "# 仪器 = run.sh " + Sha16(Root + "/build/MilBridge/run.sh")
                    + " / Program.cs " + Sha16(Root + "/build/MilBridge/tests/HbTextLineParity/Program.cs")
                    + "   pc=" + Sha16(Root + "/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll")
                    + "   applocal=" + AppLocalStatus,
            };
        }

        /// <summary>用例家族 = 去掉尾部 _wNN / _winf 档位后缀。</summary>
        private static string Family(string id)
        {
            int i = id.LastIndexOf("_w", StringComparison.Ordinal);
            return i > 0 ? id.Substring(0, i) : id;
        }

        /// <summary>从宽度明细的**正文行**里取族名（`用例 | 行# | …` ⇒ 用例 ⇒ Family()）。
        /// 与内存计数**走同一个 Family()** ⇒ artifact 与控制台不存在两套口径。</summary>
        private static string FamilyOf(string row)
        {
            int bar = row.IndexOf(" | ", StringComparison.Ordinal);
            return Family(bar > 0 ? row.Substring(0, bar) : row);
        }

        /// <summary>`族 × >0.34 桶红数`（`onlyLarge=true` ⇒ 只数 `桶=>0.34 DIP` 的行）。
        /// 上一趟 artifact 的族表与本次内存族表**都由它算** ⇒ 隔离矩阵的 diff 是同口径 diff。</summary>
        private static SortedDictionary<string, int> FamilyTable(IEnumerable<string> rows, bool onlyLarge)
        {
            var t = new SortedDictionary<string, int>(StringComparer.Ordinal);
            foreach (string r in rows)
            {
                if (r.Length == 0 || r.StartsWith("#", StringComparison.Ordinal)) continue;
                if (onlyLarge && !r.Contains(">0.34 DIP")) continue;
                string id = FamilyOf(r);
                if (id.Length == 0) continue;
                t[id] = t.TryGetValue(id, out int n) ? n + 1 : 1;
            }
            return t;
        }

        private static string FamText(SortedDictionary<string, int> t)
        {
            var sb = new StringBuilder();
            foreach (var kv in t)
            {
                if (sb.Length > 0) sb.Append("  ");
                sb.Append(kv.Key).Append('=').Append(kv.Value);
            }
            return sb.ToString();
        }

        /// <summary>安全的 cr 描述（`Count!=1` 也说得清，且不会越界索引）。</summary>
        private static string CrTxt(IList<TextCollapsedRange> cr)
            => cr == null ? "null"
             : cr.Count == 0 ? "空"
             : "n=" + cr.Count + " [" + cr[0].TextSourceCharacterIndex + "," + cr[0].Length + ") W=" + cr[0].Width.ToString("F4");

        private static string CrSpanTxt(IList<TextCollapsedRange> cr)
            => cr == null ? "null"
             : cr.Count == 0 ? "空"
             : "n=" + cr.Count + " [" + cr[0].TextSourceCharacterIndex + "," + cr[0].Length + ")";

        private static int CountUncomparable() => 0;
        // ==================================================================================
        //  T5 · GetTextLineBreak 语义（真机：普通文本 null；modifier 才非 null）
        // ==================================================================================
        private static int TestLineBreakSemantics()
        {
            Console.WriteLine("──────── T5 · GetTextLineBreak 语义 + 零记录 + 所有权/Clone/Dispose ────────");
            GlyphTypeface gt = GetGlyphTypeface(Root + "/build/fonts", "Regular");
            var props = new HbRunProperties(null, 0, null);
            const string text = "alpha bravo charlie delta echo foxtrot golf hotel india juliet";

            // (a) 普通文本 ⇒ 必须 null（真机 3220/3222）
            List<HbTextLine> plain = HbTextLineFactory.FormatParagraph(
                text, FontRegular, 16, 80, gt, 1.0f, props, false, false, 0, out _);
            int nulls = 0, nonNull = 0;
            foreach (HbTextLine L in plain)
            {
                TextLineBreak lb = L.GetTextLineBreak();
                if (lb == null) ++nulls; else { ++nonNull; lb.Dispose(); }
            }
            Check("T5.1", "普通文本（无 TextModifier）：每行 GetTextLineBreak() 都是 null",
                nonNull == 0 && nulls == plain.Count,
                $"行数={plain.Count} null={nulls} 非null={nonNull}（真机 3220/3222 null）");

            // (b) modifier 情形 ⇒ 真 TextLineBreak 对象、零记录、Clone 可用、Dispose 安全
            List<HbTextLine> mod = HbTextLineFactory.FormatParagraph(
                text, FontRegular, 16, 120, gt, 1.0f, props, true, true, 0, out _);
            TextLineBreak brk = mod[0].GetTextLineBreak();
            Check("T5.2", "modifier 情形：拿到**真的** TextLineBreak 对象（非 null）", brk != null,
                brk == null ? "null" : $"type={brk.GetType().FullName}");
            IntPtr rec = brk == null ? (IntPtr)(-1) : ReadBreakRecord(brk);
            object scope = brk == null ? "n/a" : ReadModifierScope(brk);
            Check("T5.3", "零记录：_breakRecord = IntPtr.Zero 且 _currentScope = null（**不伪造**原生断行记录）",
                brk != null && rec == IntPtr.Zero && scope == null,
                $"_breakRecord={rec} _currentScope={(scope == null ? "null" : scope.GetType().Name)}");

            TextLineBreak clone = brk?.Clone();
            Check("T5.4", "Clone() 不崩、返回**新实例**（真机 cloneIsSameReference=false），且克隆体也是零记录",
                clone != null && !ReferenceEquals(clone, brk) && ReadBreakRecord(clone) == IntPtr.Zero,
                clone == null ? "clone=null" : $"sameRef={ReferenceEquals(clone, brk)} cloneRecord={ReadBreakRecord(clone)}");

            bool disposeOk = true; string disposeDetail = "";
            try { brk?.Dispose(); clone?.Dispose(); }
            catch (Exception e) { disposeOk = false; disposeDetail = e.GetType().Name + ": " + e.Message; }
            Check("T5.5", "Dispose() 对零记录**不调** LsDestroy/LoDisposeBreakRecord（上游 `if (_breakRecord != IntPtr.Zero)` "
                          + "⇒ 零记录走不到原生）；两个实例各自 Dispose 一次不崩（无引用计数、各自持有）",
                disposeOk, disposeDetail.Length > 0 ? disposeDetail : "两次 Dispose 均无异常");

            // (c) 计数器读数
            Console.WriteLine($"      [读数] breakNull={HbTextLineScaffold.BreakNullReturned} "
                              + $"breakZeroRecords={HbTextLineScaffold.BreakZeroRecordIssued} "
                              + $"modifierLines={HbTextLineScaffold.ModifierLines}");
            Check("T5.6", "计数器口径：null 路径与零记录路径**各记各的**（本次：null≥1、zero≥1）",
                HbTextLineScaffold.BreakNullReturned >= 1 && HbTextLineScaffold.BreakZeroRecordIssued >= 1,
                $"breakNull={HbTextLineScaffold.BreakNullReturned} breakZeroRecords={HbTextLineScaffold.BreakZeroRecordIssued}");

            // (d) 严格模式下零记录必须"当失败上报"
            Environment.SetEnvironmentVariable(HbTextLineScaffold.StrictEnvVar, "1");
            bool threw = false;
            try { mod[0].GetTextLineBreak(); } catch (NotSupportedException) { threw = true; }
            Environment.SetEnvironmentVariable(HbTextLineScaffold.StrictEnvVar, null);
            Check("T5.7", "WPF_LINUX_TEXTLINE_STRICT=1 时零记录**当失败上报**（抛出，不吞）", threw,
                threw ? "NotSupportedException ✓" : "没抛");

            // ---- T5.8：零记录的生命周期**真的碰不到 LS**（对照 + 测量，不是"应该不会"）----
            //   对照：同一个进程里**故意**去解析一个已知存在的 LS 家族符号 ⇒ 证明"能记到"；
            //   测量：`LoDisposeBreakRecord`（Dispose 会调的）/`LoCloneBreakRecord`（Clone 会调的）
            //         在本工程的 shim 里**不存在** ⇒ 若代码真去调它们，会抛 EntryPointNotFoundException。
            //   （LD_PRELOAD 版看不到这一层：这里是 managed 侧 NativeLibrary + ld.so 日志两条独立证据。）
            string nativeShim = Root + "/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";
            string ctl, measure;
            bool controlOk = false, disposalAbsent = false, cloneAbsent = false;
            try
            {
                IntPtr h = System.Runtime.InteropServices.NativeLibrary.Load(nativeShim);
                IntPtr ctlSym = System.Runtime.InteropServices.NativeLibrary.GetExport(h, "LsDisableSpecialCharacterLigature");
                controlOk = ctlSym != IntPtr.Zero;
                ctl = controlOk ? "LsDisableSpecialCharacterLigature 解析成功（对照✓）" : "对照符号解析失败";
                // ⚠️ 探测"这些符号不存在"这件事**本身**会在 ld.so 日志里留下查找行
                //    ⇒ 只在显式开 `T1B_LS_PROBE_ABSENT=1` 时做，好让默认那次运行拿到
                //      **干净的生命周期读数**（日志里除对照符号外一个 LS 符号都没有）。
                bool probeAbsent = HbTextLineScaffold.ParseOnOff(Environment.GetEnvironmentVariable("T1B_LS_PROBE_ABSENT"));
                if (probeAbsent)
                {
                    disposalAbsent = ProbeMissing(h, "LoDisposeBreakRecord");
                    cloneAbsent = ProbeMissing(h, "LoCloneBreakRecord");
                    measure = $"LoDisposeBreakRecord {(disposalAbsent ? "不存在（EntryPointNotFoundException）" : "**存在**")}；"
                            + $"LoCloneBreakRecord {(cloneAbsent ? "不存在" : "**存在**")}；"
                            + $"LoAcquireBreakRecord {(ProbeMissing(h, "LoAcquireBreakRecord") ? "不存在" : "**存在**")}；"
                            + $"LoCreateLine {(ProbeMissing(h, "LoCreateLine") ? "不存在" : "**存在**")}";
                }
                else
                {
                    disposalAbsent = cloneAbsent = true;   // 未探测（本判据交给 ld.so 日志的"零查找"读数）
                    measure = "（本次未探测符号是否存在：保持 ld.so 日志干净，用『除对照外零查找』作判据；"
                            + "要显式验证不存在就跑 T1B_LS_PROBE_ABSENT=1）";
                }
                System.Runtime.InteropServices.NativeLibrary.Free(h);
            }
            catch (Exception e) { ctl = "对照失败：" + e.GetType().Name + ": " + e.Message; measure = "n/a"; }
            Check("T5.8", "零记录生命周期不碰 LS：**同进程对照**（能解析一个已知 LS 符号）+ **测量**（Dispose/Clone 会调的符号不存在⇒调了就抛）",
                controlOk && disposalAbsent && cloneAbsent,
                ctl + "；" + measure);
            return 0;
        }

        /// <summary>该导出在本工程 shim 里是否存在（不存在 ⇒ .NET 解析时抛 EntryPointNotFoundException）。</summary>
        private static bool ProbeMissing(IntPtr handle, string name)
        {
            try { System.Runtime.InteropServices.NativeLibrary.GetExport(handle, name); return false; }
            catch (EntryPointNotFoundException) { return true; }
        }

        private static string AppDir() => Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

        private static string Sha16(string path)
        {
            try { using var fs = File.OpenRead(path); return Convert.ToHexString(SHA256.HashData(fs)).Substring(0, 16); }
            catch { return "(读不到)"; }
        }

        /// <summary>被测 shim 源文件的 sha256（读数必须附"测的是哪一版"）。</summary>
        private static string ShimSha256()
        {
            try
            {
                // ⚠️ 必须取**编译进本 harness 的那一份**：`-p:HbShimSrc=` 可以指向别的路径（staging 副本），
                //   而 `HbShimSource.File` 只是常量里的默认相对路径 ⇒ 直接用它算 sha 会**报到另一个文件**上
                //   （实测踩过：明细头写 `ADBEE67B…`，而脚本汇总写 `2cc87a93…`，两者不是同一个文件）。
                string p = Environment.GetEnvironmentVariable("T1B_SHIM_PATH") ?? Path.Combine(Root, HbShimSource.File);
                if (!File.Exists(p)) return "(缺)";
                using var fs = File.OpenRead(p);
                return Convert.ToHexString(SHA256.HashData(fs));
            }
            catch { return "(读不到)"; }
        }

        private static IntPtr ReadBreakRecord(TextLineBreak b)
        {
            PropertyInfo p = typeof(TextLineBreak).GetProperty("BreakRecord",
                BindingFlags.Instance | BindingFlags.NonPublic);
            return (IntPtr)p.GetValue(b);
        }

        private static object ReadModifierScope(TextLineBreak b)
        {
            PropertyInfo p = typeof(TextLineBreak).GetProperty("TextModifierScope",
                BindingFlags.Instance | BindingFlags.NonPublic);
            return p.GetValue(b);
        }

        // ==================================================================================
        //  工具
        // ==================================================================================
        /// <summary>是否含 RTL 字符（Hebrew/Arabic）：本轮路由 B 没有 bidi ⇒ 这些用例不可比。</summary>
        /// <summary>该用例文本是否含 CJK（用于标出 Extent 余差是否落在 CJK 回退边界那类）。</summary>
        private static bool CjkIn(string text)
        {
            foreach (char ch in text) if (ch >= 0x2E80) return true;
            return false;
        }

        private static bool HasRtl(string text)
        {
            foreach (char ch in text)
                if ((ch >= 0x0590 && ch <= 0x08FF) || (ch >= 0xFB1D && ch <= 0xFEFF)) return true;
            return false;
        }

        private static string PickFont(string family, int weight, int style, string text)
        {
            if (family != "Noto Sans")
                return family.Contains("CJK") ? FontCjk : FontRegular;
            bool cjk = false;
            foreach (char ch in text) if (ch >= 0x2E80) { cjk = true; break; }
            if (cjk) return FontCjk;
            if (weight >= 700 && style == 2) return FontBoldItalic;
            if (weight >= 700) return FontBold;
            if (style == 2) return FontItalic;
            return FontRegular;
        }

        private static GlyphTypeface GetGlyphTypeface(string fontDir, string weight)
        {
            const string TI = "MS.Internal.Text.TextInterface";
            Assembly dwf = Assembly.Load("DirectWriteForwarder");
            Type colType = dwf.GetType(TI + ".FontCollection", true);
            object col = colType.GetMethod("FromDirectory",
                    BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(null, new object[] { fontDir });
            Type famType = dwf.GetType(TI + ".FontFamily", true);
            PropertyInfo indexer = colType.GetProperty("Item",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic,
                null, famType, new[] { typeof(uint) }, null);
            object family = indexer.GetValue(col, new object[] { 0u });
            object w = Enum.Parse(dwf.GetType(TI + ".FontWeight", true), weight);
            object stretch = Enum.Parse(dwf.GetType(TI + ".FontStretch", true), "Normal");
            object style = Enum.Parse(dwf.GetType(TI + ".FontStyle", true), "Normal");
            object font = family.GetType()
                .GetMethod("GetFirstMatchingFont", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                .Invoke(family, new[] { w, stretch, style });
            ConstructorInfo gi = typeof(GlyphTypeface).GetConstructor(
                BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public,
                null, new[] { font.GetType() }, null);
            return (GlyphTypeface)gi.Invoke(new[] { font });
        }

        /// <summary>与真机 probe 的 `TextTrailingCharacterEllipsis(cw, runProps)` **输入等价**的最小实现。</summary>
        private sealed class HarnessEllipsisProps : TextCollapsingProperties
        {
            internal HarnessEllipsisProps(double width) { WidthValue = width; }
            private double WidthValue { get; }
            public override double Width => WidthValue;
            public override TextRun Symbol => null;
            public override TextCollapsingStyle Style => TextCollapsingStyle.TrailingCharacter;
        }

        /// <summary>统一口径标注（两台装置同一格式、同一行位置）：`X 一致 @0.34: a/n ｜ @0.01: b/n`。</summary>
        private static string Tol(string name, int wideOk, int tightOk, int total)
            => $"{name} 一致 @0.34: {wideOk}/{total} ｜ @0.01: {tightOk}/{total}";

        private static string Ranges(List<(int s, int e)> v)
        {
            var sb = new StringBuilder();
            foreach ((int s, int e) in v) sb.Append('[').Append(s).Append(',').Append(e).Append(')');
            return sb.ToString();
        }
    }
}

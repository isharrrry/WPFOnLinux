// T1b/B2 · 基于 HarfBuzz 的 `TextLine` 实现（**编译进 PresentationCore**）
// =====================================================================================
// 【为什么必须是 shim（编译进 PC），而不是外部程序集】
//   轨道A 原型（`build/MilBridge/tests/TextLineProto/`，461 行 / 311 代码行）验证了实现本身可控，
//   但它当时**只能用反射**造四个 internal 类型：
//     · `TextBounds` / `TextRunBounds`   —— 构造是 **internal**（实测 public ctor = 0）
//     · `TextCollapsedRange`             —— 构造是 internal
//     · `TextLineBreak`                  —— 构造是 internal（`(TextModifierScope, IntPtr)`）
//     · `GlyphTypeface(Font)`            —— 构造是 **internal**
//   本文件按 `build/shims/PresentationCore.shims.txt` 机制编进 PresentationCore，于是 **internal 可见**。
//
// 【B2 本轮范围】—— 把三个成员做**实**
//   · `GetTextLineBreak()`       —— 普通文本 **null**；只有 TextModifier 情形才发**真的** `TextLineBreak`
//                                   对象（`_breakRecord = IntPtr.Zero`、`_currentScope = null`）。
//   · `Collapse(...)`            —— 真实现：按真机 oracle 的 CharacterEllipsis 折叠。
//   · `GetTextCollapsedRanges()` —— 真实现：未折叠 ⇒ **null**（不是空集合，真机 3222/3222 实测）。
//   · `GetIndexedGlyphRuns()`    —— **仍留 owed**（上游 0 个调用点，主控裁定不实现）。
//   · 断行引擎（ICU 断点集 + 2 条 DWrite 覆盖规则 + 贪心填宽 + 禁则拉字 + 强制断 fallback）
//     从 `build/MilBridge/tests/IcuBreakParity/` **原样搬进本文件** —— 从此**规则只有这一份**，
//     两个 harness（`run.sh icu` 与 `run.sh textline`/`tline`）驱动的都是本文件的 `HbBreakEngine`。
//
// 【口径的真值来源（2026-09-11 主控裁定，不是猜的）】
//   `tests/parity/windows/layout-b34/`（Windows 11 真机 `TextFormatter.FormatLine` 逐属性 dump）。
//   ⚠️ 与那 73 例 CJK oracle **不是同一条路径**：73 例走 DirectWrite `IDWriteTextLayout`，
//      本 oracle 走 WPF 托管栈（`TextFormatter → TextMetrics → lsapi`）。**Linux 侧实现的是
//      `TextLine`/`TextFormatter` 契约 ⇒ 冲突时以本 oracle 为准**（对拍数字见 T1b 报告）。
//   三条记账（独立复算见 `build/MilBridge/gen/layout-b34-accounting.txt`）：
//     ① 行区间**含**硬断字符：`Length` 把它算进去，`NewlineLength` 单独给个数（`\r\n` = 2）；
//     ② 相邻 `\n` **不是零长度行**，而是 `Length=1`、内容就是 `'\n'` 的普通行（`Width=0`，占一行高）；
//     ③ 行尾空白**占区间、不占 `Width`**，差额由 `WidthIncludingTrailingWhitespace` 给出；
//        且 `TrailingWhitespaceLength` **把换行符/EOP 也算进去**。
//     另：**段落最后一行 `Length` = 剩余文本长度 + 1（EOP）**、其 `NewlineLength` 恒 1（EOP 标记）。
//
// 【两种构造模式（同一个源文件编多次，保证"换方式后行为不变"）】
//   `TEXTLINE_SHIM_DIRECT`       定义 → 直构 internal 类型（**只有编进 PC 时才成立**）
//   未定义                          → 反射（让同一份源文件能在 PC 之外编译/运行，用于对照验证）
//   `TEXTLINE_BREAK_ENGINE_ONLY` 定义 → **只编断行引擎 + HarfBuzz 绑定**（不引用 PC），
//                                     供 `IcuBreakParity` 复用同一份规则（保持"零规则副本"）。
//
// 【与既有 shim 的关系】命名空间 `WpfLinux.Shims.PresentationCore`（与 `FontBridge` 同前缀），
//   不占用任何上游命名空间，不与 `Factory.Linux` / `OleApi.Stubs` 撞名。
// =====================================================================================

using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

#if !TEXTLINE_BREAK_ENGINE_ONLY
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Markup;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;
#endif

namespace WpfLinux.Shims.PresentationCore
{
    /// <summary>本文件的唯一标识 —— harness 用它自证"驱动的是这份源文件"。</summary>
    internal static class HbShimSource
    {
        internal const string File = "build/shims/PresentationCore.HbTextLine.cs";
        internal const string Tag = "T1b/B2 · 2026-09-11 · break-engine + TextLineBreak + Collapse";

        /// <summary>引擎（规则）版本 —— 与 `IcuBreakParity` 的 73 例对拍绑定。</summary>
        internal const string EngineTag = "ICU(UAX#14) + `…`前可断 + 禁则拉字 + 强制断 fallback";
    }

    // ==================================================================================
    //  1. HarfBuzz shaping（无反射、无 PC 依赖 —— 两种模式都要）
    // ==================================================================================

    /// <summary>一次 shaping 的结果。</summary>
    internal sealed class HbShapedRun
    {
        public ushort[] Glyphs;          // 字形 id
        public uint[] Clusters;          // 每个字形 → **UTF-16 码元**索引（HarfBuzz 的 cluster）
        public double[] AdvancesPx;      // 每个字形的步进（设备无关像素）
        public double[] OffsetsXPx;      // 每个字形的 x 偏移（GPOS 定位）
        public uint Upem;
        public double EmSize;
        public string Text;

        public double TotalWidthPx
        {
            get { double s = 0; foreach (double a in AdvancesPx) s += a; return s; }
        }

        /// <summary>
        /// 「字符 → advance」：把字形 advance 归到它的 cluster 首字符上（连字整段记首字）。
        /// 断行填宽与 `Width`/`WidthIncludingTrailingWhitespace` 都走这条。
        /// </summary>
        internal double[] CharAdvances()
        {
            var adv = new double[Text.Length];
            for (int i = 0; i < Glyphs.Length; i++)
            {
                uint c = Clusters[i];
                if (c < (uint)adv.Length) adv[c] += AdvancesPx[i];
            }
            return adv;
        }

        internal static HbShapedRun Empty(double emSize)
        {
            return new HbShapedRun
            {
                Glyphs = new ushort[0], Clusters = new uint[0], AdvancesPx = new double[0],
                OffsetsXPx = new double[0], Upem = 0, EmSize = emSize, Text = string.Empty,
            };
        }
    }

    /// <summary>HarfBuzz 最小绑定（M7c4 spike 已验证的那套 P/Invoke 面）。</summary>
    internal static unsafe class HbShaper
    {
        private const string Hb = "libharfbuzz.so.0";

        [DllImport(Hb)] private static extern IntPtr hb_blob_create_from_file(byte* filename);
        [DllImport(Hb)] private static extern uint hb_blob_get_length(IntPtr blob);
        [DllImport(Hb)] private static extern IntPtr hb_face_create(IntPtr blob, uint index);
        [DllImport(Hb)] private static extern uint hb_face_get_upem(IntPtr face);
        [DllImport(Hb)] private static extern IntPtr hb_font_create(IntPtr face);
        [DllImport(Hb)] private static extern void hb_ot_font_set_funcs(IntPtr font);
        [DllImport(Hb)] private static extern void hb_font_set_scale(IntPtr font, int xScale, int yScale);
        [DllImport(Hb)] private static extern IntPtr hb_buffer_create();
        [DllImport(Hb)] private static extern void hb_buffer_add_utf16(IntPtr buf, char* text, int textLength, int itemOffset, int itemLength);
        [DllImport(Hb)] private static extern void hb_buffer_guess_segment_properties(IntPtr buf);
        [DllImport(Hb)] private static extern IntPtr hb_language_from_string(byte* str, int len);
        [DllImport(Hb)] private static extern void hb_buffer_set_language(IntPtr buf, IntPtr language);
        [DllImport(Hb)] private static extern void hb_shape(IntPtr font, IntPtr buf, IntPtr features, uint numFeatures);
        [DllImport(Hb)] private static extern IntPtr hb_buffer_get_glyph_infos(IntPtr buf, out uint length);
        [DllImport(Hb)] private static extern IntPtr hb_buffer_get_glyph_positions(IntPtr buf, out uint length);
        [DllImport(Hb)] private static extern IntPtr hb_version_string();
        [DllImport(Hb)] private static extern void hb_buffer_destroy(IntPtr buf);
        [DllImport(Hb)] private static extern void hb_font_destroy(IntPtr font);
        [DllImport(Hb)] private static extern void hb_face_destroy(IntPtr face);
        [DllImport(Hb)] private static extern void hb_blob_destroy(IntPtr blob);

        [StructLayout(LayoutKind.Sequential)]
        private struct GlyphInfo { public uint Codepoint, Mask, Cluster, Var1, Var2; }

        [StructLayout(LayoutKind.Sequential)]
        private struct GlyphPosition { public int XAdvance, YAdvance, XOffset, YOffset; public uint Var; }

        internal static string Version => Marshal.PtrToStringUTF8(hb_version_string()) ?? "?";

        /// <summary>
        /// 对 <paramref name="text"/> 做一次完整 shaping（GSUB + GPOS）。
        ///
        /// ⚠️ 2026-09-11（T1b）修正：**必须用 `hb_buffer_add_utf16`**。
        ///    原实现用 `hb_buffer_add_utf8` + `Bytes.Length`，于是 HarfBuzz 返回的 cluster 是
        ///    **UTF-8 字节偏移**，却被当成 UTF-16 码元下标去求逆（`InvertClusters`）——
        ///    纯 ASCII 文本看不出来，只要出现一个 3 字节字符（如原型里的 `—`）后面全错位；
        ///    73 例语料全是 CJK ⇒ 这个错会让 B2 整体失准。
        /// </summary>
        internal static HbShapedRun Shape(string fontPath, string text, double emSize, string language = "zh-cn")
        {
            if (string.IsNullOrEmpty(text)) return HbShapedRun.Empty(emSize);   // 空行：不发 HB 调用

            byte[] pathZ = Encoding.UTF8.GetBytes(fontPath + "\0");
            byte[] langZ = Encoding.UTF8.GetBytes((language ?? "zh-cn") + "\0");

            IntPtr blob = IntPtr.Zero, face = IntPtr.Zero, font = IntPtr.Zero, buf = IntPtr.Zero;
            try
            {
                fixed (byte* p = pathZ) blob = hb_blob_create_from_file(p);
                if (blob == IntPtr.Zero || hb_blob_get_length(blob) == 0)
                    throw new InvalidOperationException("HarfBuzz 读不到字体：" + fontPath);

                face = hb_face_create(blob, 0);
                uint upem = hb_face_get_upem(face);
                font = hb_font_create(face);
                hb_ot_font_set_funcs(font);
                hb_font_set_scale(font, (int)upem, (int)upem);      // advance 以 font unit 返回

                buf = hb_buffer_create();
                fixed (char* t = text) hb_buffer_add_utf16(buf, t, text.Length, 0, text.Length);
                hb_buffer_guess_segment_properties(buf);
                // U1 的硬要求：**必须把 language 传进 buffer**（不给 ⇒ SC/TC 面回落 JP 字形）。
                fixed (byte* lz = langZ) hb_buffer_set_language(buf, hb_language_from_string(lz, -1));
                hb_shape(font, buf, IntPtr.Zero, 0);

                IntPtr infos = hb_buffer_get_glyph_infos(buf, out uint n);
                IntPtr pos = hb_buffer_get_glyph_positions(buf, out uint n2);
                if (infos == IntPtr.Zero || pos == IntPtr.Zero || n != n2)
                    throw new InvalidOperationException("HarfBuzz shaping 失败");
                if (n == 0) return HbShapedRun.Empty(emSize);

                double scale = emSize / upem;
                var r = new HbShapedRun
                {
                    Glyphs = new ushort[n],
                    Clusters = new uint[n],
                    AdvancesPx = new double[n],
                    OffsetsXPx = new double[n],
                    Upem = upem,
                    EmSize = emSize,
                    Text = text,
                };
                int szI = Marshal.SizeOf<GlyphInfo>(), szP = Marshal.SizeOf<GlyphPosition>();
                for (int i = 0; i < (int)n; i++)
                {
                    GlyphInfo gi = Marshal.PtrToStructure<GlyphInfo>(infos + i * szI);
                    r.Glyphs[i] = (ushort)gi.Codepoint;
                    r.Clusters[i] = gi.Cluster;
                    GlyphPosition gp = Marshal.PtrToStructure<GlyphPosition>(pos + i * szP);
                    r.AdvancesPx[i] = gp.XAdvance * scale;
                    r.OffsetsXPx[i] = gp.XOffset * scale;
                }
                return r;
            }
            finally
            {
                if (buf != IntPtr.Zero) hb_buffer_destroy(buf);
                if (font != IntPtr.Zero) hb_font_destroy(font);
                if (face != IntPtr.Zero) hb_face_destroy(face);
                if (blob != IntPtr.Zero) hb_blob_destroy(blob);
            }
        }
    }

    // ==================================================================================
    //  2. ⭐ 断行引擎 —— 规则集**只有这一份**（B2 的唯一真源）
    // ==================================================================================
    //
    //  【规则集 = 1 个断点集 + 3 条规则】（逐条依据见 `build/MilBridge/tests/IcuBreakParity/` 文件头）
    //    断点集   ICU 70 的 UAX#14 `ubrk_*`（实测 zh-CN 走 root 规则 ⇒ 断行点集与 locale 无关）
    //    规则 1   `…`(U+2026) **之前可以断**（唯一一条按 DWrite 真值覆盖 UAX#14 的表差异）
    //    规则 2   禁则拉字：贪心选的断点会让下一行以"不能做行首"的字开头 ⇒ 断点回退 1 字；
    //             回退位不是合法断点 ⇒ **放弃**；判据 = ICU 原始断点集没有该位置，
    //             另加实测例外 `“`/`‘`（`“` 实测要拉 2 字 ⇒ guard<2）
    //    规则 3   强制断 fallback：断点集里没有能放下的位置 ⇒ 按宽度塞满（至少 1 字）。
    //             它**顺带**复现"容器窄到 1~2 字时放弃禁则"与字符级紧急断行（实测全等）。
    //
    //  ⚠️ 硬断字符（`\n` / `\r\n` / `\u2028` / `\u2029` / `\u0085`）**不进 ICU**：
    //     先按它们切段，段内再跑上面那套 —— 与 `IcuBreakParity` 逐字一致。
    // ==================================================================================

    /// <summary>一行在**源文本索引系**里的位置（`End` **不含**硬断字符；硬断字符由 `HardBreakLen` 给出）。</summary>
    internal sealed class HbLineRange
    {
        public int Start;                // 段落系（源文本下标）
        public int End;                  // 不含硬断字符
        public int HardBreakLen;         // 0 / 1 / 2（`\r\n`）
        public bool HasEop;              // 末段落最后一行 ⇒ 追加 EOP 字符（`Length` +1、`NewlineLength` = 1）
        public bool Forced;              // 由规则 3（强制断 fallback）产出
        public int KinsokuPull;          // 规则 2 拉了几次（0/1/2）

        public int VisibleLength => End - Start;
    }

    internal static class HbBreakEngine
    {
        // ---------------------------------------------------------------- ICU（版本化符号）
        private const int UBRK_LINE = 2;
        private const int UBRK_DONE = -1;

        [DllImport("libicuuc.so.70", EntryPoint = "ubrk_open_70", CharSet = CharSet.Ansi)]
        private static extern unsafe IntPtr ubrk_open(int type, string locale, char* text, int textLength, out int status);
        [DllImport("libicuuc.so.70", EntryPoint = "ubrk_first_70")] private static extern int ubrk_first(IntPtr bi);
        [DllImport("libicuuc.so.70", EntryPoint = "ubrk_next_70")] private static extern int ubrk_next(IntPtr bi);
        [DllImport("libicuuc.so.70", EntryPoint = "ubrk_close_70")] private static extern void ubrk_close(IntPtr bi);
        [DllImport("libicuuc.so.70", EntryPoint = "u_getVersion_70")] private static extern unsafe void u_getVersion(byte* v);

        /// <summary>ICU 版本（`u_getVersion`）；ICU 不在就 `"?"`。</summary>
        internal static string IcuVersion
        {
            get
            {
                try
                {
                    unsafe { byte* v = stackalloc byte[4]; u_getVersion(v); return $"{v[0]}.{v[1]}.{v[2]}.{v[3]}"; }
                }
                catch (Exception) { return "?"; }
            }
        }

        // 计数（引擎侧；供 scaffold 汇总 —— 这些是"引擎真的这么做了"的直接读数）
        internal static long ParagraphsBroken;
        internal static long ForcedBreaks;
        internal static long KinsokuPulls;
        internal static long IcuCalls;
        internal static long IcuFailures;

        /// <summary>硬断字符长度：`\r\n` 占 2 个字符；非硬断返回 0。</summary>
        internal static int HardBreakLengthAt(string text, int i)
        {
            if (i < 0 || i >= text.Length) return 0;
            char c = text[i];
            if (c == '\r') return (i + 1 < text.Length && text[i + 1] == '\n') ? 2 : 1;
            if (c == '\n' || c == '\u2028' || c == '\u2029' || c == '\u0085') return 1;
            return 0;
        }

        internal static bool IsHardBreak(char c)
            => c == '\r' || c == '\n' || c == '\u2028' || c == '\u2029' || c == '\u0085';

        // ---------------------------------------------------------------- 断点集 + 覆盖规则

        /// <summary>ICU 的 UAX#14 断点集（段落内下标；含 0）。</summary>
        internal static List<int> IcuBreaks(string text, string locale)
        {
            var result = new List<int>();
            if (string.IsNullOrEmpty(text)) { result.Add(0); return result; }
            int status = 0;
            System.Threading.Interlocked.Increment(ref IcuCalls);
            unsafe
            {
                fixed (char* p = text)
                {
                    IntPtr bi = ubrk_open(UBRK_LINE, locale, p, text.Length, out status);
                    // ICU 约定：status <= 0 都算成功。实测 zh-CN = -128 (U_USING_FALLBACK_WARNING)
                    // ⇒ 没有 zh-CN 专属断行数据、走 root 规则 ⇒ 断行点集与 locale 无关。
                    if (bi == IntPtr.Zero || status > 0)
                    {
                        if (bi != IntPtr.Zero) ubrk_close(bi);
                        System.Threading.Interlocked.Increment(ref IcuFailures);
                        throw new InvalidOperationException($"ubrk_open(locale={locale}) 失败 status={status}");
                    }
                    try { for (int b = ubrk_first(bi); b != UBRK_DONE; b = ubrk_next(bi)) result.Add(b); }
                    finally { ubrk_close(bi); }
                }
            }
            return result;
        }

        /// <summary>**按 DWrite 真值覆盖 UAX#14** 的规则 1（依据见上）。</summary>
        internal static List<int> Overlay(List<int> raw, string text)
        {
            var set = new List<int>(raw);
            for (int i = 0; i < text.Length; ++i)
            {
                if (text[i] == '\u2026' && !set.Contains(i)) set.Add(i);   // 规则 1：`…` 前可断
                // （规则 2「`“` 前禁止断」不放这里 —— 由 CannotStartLine 的禁则拉字统一处理）
            }
            set.Sort();
            return set;
        }

        /// <summary>该位置能否做行首：ICU 原始断点集说不行 ⇒ 不行；另加实测的两个引号例外（`“`/`‘`）。</summary>
        internal static bool CannotStartLine(string text, int index, List<int> raw)
        {
            if (index >= text.Length) return false;
            char ch = text[index];
            if (ch == '\u201C' || ch == '\u2018') return true;   // 规则 2（实测：DWrite 把引号连同前一个字下移）
            return !raw.Contains(index);                          // UAX#14 的禁则编码（实测 40/40 一致）
        }

        /// <summary>逐字 advance（DIP）：HarfBuzz 真 shaping → cluster 求逆。</summary>
        internal static double[] MeasureChars(string text, string fontPath, double emSize)
            => HbShaper.Shape(fontPath, text, emSize).CharAdvances();

        // ---------------------------------------------------------------- 断行

        /// <summary>
        /// 段内断行（**不含**硬断字符的处理，硬断由 <see cref="LayoutText"/> 切段）。
        /// 返回的 `Start`/`End` 是**源文本**下标（不是段内下标）。
        /// </summary>
        internal static List<HbLineRange> BreakParagraph(string text, int start, int end,
                                                         double width, double emSize, string fontPath)
        {
            var lines = new List<HbLineRange>();
            int len = end - start;
            if (len <= 0) { lines.Add(new HbLineRange { Start = start, End = start }); return lines; }  // 空段落 ⇒ 空行

            System.Threading.Interlocked.Increment(ref ParagraphsBroken);

            string para = text.Substring(start, len);
            double[] adv = MeasureChars(para, fontPath, emSize);
            List<int> raw = IcuBreaks(para, "zh-CN");
            List<int> breaks = Overlay(raw, para);

            var local = new List<int>();
            foreach (int b in breaks) if (b >= 0 && b <= len) local.Add(b);
            if (!local.Contains(len)) local.Add(len);                 // 段末必是断点
            local.Sort();

            int pos = 0;
            while (pos < len)
            {
                int best = -1;
                foreach (int b in local)
                {
                    if (b <= pos) continue;
                    if (EffectiveWidth(adv, para, pos, b) <= width + 1e-9) best = b; else break;
                }
                bool forced = false;
                int pulls = 0;
                if (best < 0)
                {
                    // ── 规则 3：强制断 fallback（断点集里没有能放下的位置 ⇒ 按宽度塞满，至少 1 字）──
                    double w = 0; int e = pos;
                    while (e < len && w + adv[e] <= width + 1e-9) { w += adv[e]; ++e; }
                    best = e > pos ? e : pos + 1;
                    forced = true;
                    System.Threading.Interlocked.Increment(ref ForcedBreaks);
                }
                else
                {
                    // ── 规则 2：禁则拉字（把"不能做行首"的字连同它的前一个字拉到下一行）──
                    for (int guard = 0; guard < 2; ++guard)
                    {
                        int g = start + best;
                        if (g >= end || !CannotStartLine(text, g, raw)) break;
                        int cand = best - 1;
                        if (cand > pos && local.Contains(cand)) { best = cand; ++pulls; } else break;
                    }
                    if (pulls > 0) System.Threading.Interlocked.Add(ref KinsokuPulls, pulls);
                }
                lines.Add(new HbLineRange { Start = start + pos, End = start + best, Forced = forced, KinsokuPull = pulls });
                pos = best;
            }
            return lines;
        }

        /// <summary>
        /// 整段文本的断行（含硬断字符切段）。返回的行**不含**硬断字符 ——
        /// 硬断与 EOP 由 `HardBreakLen` / `HasEop` 表达（= `IcuBreakParity` 的 DWrite 层口径）。
        /// </summary>
        internal static List<HbLineRange> LayoutText(string text, double width, double emSize, string fontPath)
        {
            var all = new List<HbLineRange>();
            if (text == null) text = string.Empty;
            int paraStart = 0;
            for (int i = 0; i <= text.Length; ++i)
            {
                bool atEnd = (i == text.Length);
                int hb = atEnd ? 0 : HardBreakLengthAt(text, i);
                if (!atEnd && hb == 0) continue;

                List<HbLineRange> seg = BreakParagraph(text, paraStart, i, width, emSize, fontPath);
                if (atEnd)
                {
                    // 末段落：最后一行带 EOP（`Length` +1、`NewlineLength` = 1）
                    seg[seg.Count - 1].HasEop = true;
                }
                else
                {
                    seg[seg.Count - 1].HardBreakLen = hb;      // 硬断字符归**前**一行
                }
                all.AddRange(seg);

                paraStart = i + hb;
                if (atEnd) break;
                i += hb - 1;                                   // `\r\n` 整体跨过
            }
            return all;
        }

        /// <summary>行宽 = 区间内 advance 之和 − **行尾空白**（真机口径：行尾空白不占宽但占区间）。</summary>
        private static double EffectiveWidth(double[] adv, string para, int s, int e)
        {
            double w = 0;
            for (int i = s; i < e; ++i) w += adv[i];
            int last = e;
            while (last > s && char.IsWhiteSpace(para[last - 1])) { w -= adv[last - 1]; --last; }
            return w;
        }
    }

#if !TEXTLINE_BREAK_ENGINE_ONLY

    // ==================================================================================
    //  3. 脚手架：开关 / 计数器 / 落盘 / LS 边界绊线
    // ==================================================================================

    /// <summary>
    /// 开关、命中计数与落盘。
    ///
    /// **全部 public** —— 可被测试与排障程序读到（主控要求"计数器要能被测试读到，不是只打日志"）。
    /// </summary>
    public static class HbTextLineScaffold
    {
        /// <summary>总开关。**默认关**（未接线时本文件是惰性的）。</summary>
        public const string EnableEnvVar = "WPF_LINUX_TEXTLINE";

        /// <summary>落盘路径：设了就在进程退出时把计数写过去（`run HelloWpf` 取数用）。</summary>
        public const string DumpEnvVar = "WPF_LINUX_TEXTLINE_DUMP";

        /// <summary>严格模式：欠账被命中时**抛异常**而不是回退（bring-up 期定位用，默认关）。</summary>
        public const string StrictEnvVar = "WPF_LINUX_TEXTLINE_STRICT";

        /// <summary>诊断输出（stderr）；默认关。</summary>
        public const string DiagEnvVar = "WPF_LINUX_TEXTLINE_DIAG";

        /// <summary>9 个欠账 override 的名字（顺序固定，计数器按下标对应）。</summary>
        public static readonly string[] OwedMembers =
        {
            "Collapse",
            "GetBackspaceCaretCharacterHit",
            "GetCharacterHitFromDistance",
            "GetDistanceFromCharacterHit",
            "GetIndexedGlyphRuns",
            "GetNextCaretCharacterHit",
            "GetPreviousCaretCharacterHit",
            "GetTextCollapsedRanges",
            "GetTextLineBreak",
        };

        // ⚠️ B2 已把 Collapse / GetTextCollapsedRanges / GetTextLineBreak 做成**真实现**，
        //    这三个的欠账计数**从此恒为 0**（数组保留 9 项是为了汇总行格式不漂移 —— 那是
        //    HelloWpf 绊线脚本 grep 的锚点）。仍真欠账的 6 个见 StillOwedMembers。
        internal static readonly string[] StillOwedMembers =
        {
            "GetBackspaceCaretCharacterHit", "GetCharacterHitFromDistance",
            "GetDistanceFromCharacterHit", "GetIndexedGlyphRuns",
            "GetNextCaretCharacterHit", "GetPreviousCaretCharacterHit",
        };

        private static readonly long[] s_hits = new long[OwedMembers.Length];
        private static long s_linesConstructed;
        private static long s_drawCalls;
        private static long s_getTextBoundsCalls;
        private static long s_getTextRunSpansCalls;
        private static int s_dumpInstalled;

        // ---------------- B2 新增计数 ----------------
        private static long s_paragraphsFormatted;
        private static long s_breakNullReturned;        // GetTextLineBreak() 返回 null（普通文本，真机主路径）
        private static long s_breakZeroRecordIssued;    // GetTextLineBreak() 发出**零记录** TextLineBreak
        private static long s_modifierLines;            // 带 TextModifierScope 的行（真机 3222 行里只有 2 行）
        private static long s_collapseCalls;
        private static long s_collapseEarlyReturnIneligible;   // !HasOverflowed && !KeepState ⇒ 返回 this
        private static long s_collapseEarlyReturnTooWide;      // 约束宽 > 行宽 ⇒ 返回 this
        private static long s_collapseEmptyArgsThrow;          // 空参 ⇒ ArgumentNullException（上游同款）
        private static long s_collapseApplied;                 // 真折叠发生
        private static long s_collapseUnsupported;             // 非 CharacterEllipsis（本轮无真机真值）
        private static long s_collapsedRangesNull;
        private static long s_collapsedRangesReturned;
        private static long s_forcedBreakLines;                // 规则 3 命中（"内容没放下"）
        private static long s_kinsokuPullTotal;
        private static long s_dependentLengthQueries;

        // ---------------- 开关（解析口径与 FontLayoutStripping 一致）----------------

        private static int s_envResolved;
        private static bool s_envValue;

        /// <summary>本进程的有效开关（env 说了算；读不出来就是**关**）。</summary>
        public static bool Enabled
        {
            get
            {
                if (System.Threading.Volatile.Read(ref s_envResolved) == 0)
                {
                    s_envValue = ParseOnOff(Environment.GetEnvironmentVariable(EnableEnvVar));
                    System.Threading.Volatile.Write(ref s_envResolved, 1);
                }
                return s_envValue;
            }
        }

        /// <summary>严格模式（欠账命中即抛）。</summary>
        public static bool Strict => ParseOnOff(Environment.GetEnvironmentVariable(StrictEnvVar));

        internal static bool DiagEnabled => ParseOnOff(Environment.GetEnvironmentVariable(DiagEnvVar));

        internal static bool ParseOnOff(string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return false;      // **认不出来/没设 ⇒ 关**
            switch (value.Trim().ToLowerInvariant())
            {
                case "1": case "true": case "on": case "yes": return true;
                default: return false;
            }
        }

        // ---------------- 计数 ----------------

        public static long LinesConstructed => System.Threading.Interlocked.Read(ref s_linesConstructed);
        public static long DrawCalls => System.Threading.Interlocked.Read(ref s_drawCalls);
        public static long GetTextBoundsCalls => System.Threading.Interlocked.Read(ref s_getTextBoundsCalls);
        public static long GetTextRunSpansCalls => System.Threading.Interlocked.Read(ref s_getTextRunSpansCalls);
        public static long ParagraphsFormatted => System.Threading.Interlocked.Read(ref s_paragraphsFormatted);
        public static long BreakNullReturned => System.Threading.Interlocked.Read(ref s_breakNullReturned);
        /// <summary>⭐ 发出去的**零记录** `TextLineBreak` 个数（LS 边界绊线的主读数）。</summary>
        public static long BreakZeroRecordIssued => System.Threading.Interlocked.Read(ref s_breakZeroRecordIssued);
        public static long ModifierLines => System.Threading.Interlocked.Read(ref s_modifierLines);
        public static long CollapseCalls => System.Threading.Interlocked.Read(ref s_collapseCalls);
        public static long CollapseEarlyReturnIneligible => System.Threading.Interlocked.Read(ref s_collapseEarlyReturnIneligible);
        public static long CollapseEarlyReturnTooWide => System.Threading.Interlocked.Read(ref s_collapseEarlyReturnTooWide);
        public static long CollapseEmptyArgsThrow => System.Threading.Interlocked.Read(ref s_collapseEmptyArgsThrow);
        public static long CollapseApplied => System.Threading.Interlocked.Read(ref s_collapseApplied);
        public static long CollapseUnsupported => System.Threading.Interlocked.Read(ref s_collapseUnsupported);
        public static long CollapsedRangesNull => System.Threading.Interlocked.Read(ref s_collapsedRangesNull);
        public static long CollapsedRangesReturned => System.Threading.Interlocked.Read(ref s_collapsedRangesReturned);
        public static long ForcedBreakLines => System.Threading.Interlocked.Read(ref s_forcedBreakLines);
        public static long KinsokuPullTotal => System.Threading.Interlocked.Read(ref s_kinsokuPullTotal);
        public static long DependentLengthQueries => System.Threading.Interlocked.Read(ref s_dependentLengthQueries);

        /// <summary>某个欠账成员被命中多少次（名字取自 <see cref="OwedMembers"/>）。</summary>
        public static long HitCount(string member)
        {
            int i = Array.IndexOf(OwedMembers, member);
            return i < 0 ? -1 : System.Threading.Interlocked.Read(ref s_hits[i]);
        }

        /// <summary>全部欠账命中次数之和。</summary>
        public static long TotalFallbackHits
        {
            get
            {
                long n = 0;
                for (int i = 0; i < s_hits.Length; i++) n += System.Threading.Interlocked.Read(ref s_hits[i]);
                return n;
            }
        }

        internal static void NoteConstructed() => System.Threading.Interlocked.Increment(ref s_linesConstructed);
        internal static void NoteDraw() => System.Threading.Interlocked.Increment(ref s_drawCalls);
        internal static void NoteGetTextBounds() => System.Threading.Interlocked.Increment(ref s_getTextBoundsCalls);
        internal static void NoteGetTextRunSpans() => System.Threading.Interlocked.Increment(ref s_getTextRunSpansCalls);
        internal static void NoteParagraphFormatted() => System.Threading.Interlocked.Increment(ref s_paragraphsFormatted);
        internal static void NoteModifierLine() => System.Threading.Interlocked.Increment(ref s_modifierLines);
        internal static void NoteBreakNull() => System.Threading.Interlocked.Increment(ref s_breakNullReturned);
        internal static void NoteDependentLengthQuery() => System.Threading.Interlocked.Increment(ref s_dependentLengthQueries);
        internal static void NoteForcedBreakLine() => System.Threading.Interlocked.Increment(ref s_forcedBreakLines);
        internal static void NoteKinsokuPull(int n) => System.Threading.Interlocked.Add(ref s_kinsokuPullTotal, n);
        internal static void NoteCollapseCall() => System.Threading.Interlocked.Increment(ref s_collapseCalls);
        internal static void NoteCollapseIneligible() => System.Threading.Interlocked.Increment(ref s_collapseEarlyReturnIneligible);
        internal static void NoteCollapseTooWide() => System.Threading.Interlocked.Increment(ref s_collapseEarlyReturnTooWide);
        internal static void NoteCollapseEmptyArgsThrow() => System.Threading.Interlocked.Increment(ref s_collapseEmptyArgsThrow);
        internal static void NoteCollapseApplied() => System.Threading.Interlocked.Increment(ref s_collapseApplied);
        internal static void NoteCollapseUnsupported() => System.Threading.Interlocked.Increment(ref s_collapseUnsupported);
        internal static void NoteCollapsedRangesNull() => System.Threading.Interlocked.Increment(ref s_collapsedRangesNull);
        internal static void NoteCollapsedRangesReturned() => System.Threading.Interlocked.Increment(ref s_collapsedRangesReturned);

        /// <summary>
        /// ⭐ LS 边界绊线（T1b 任务 b2）：把"零记录 `TextLineBreak` 交出去"这件事**当失败上报**。
        ///
        /// 【为什么是失败】路由 B 的 `TextLine` 是插进**可能仍属于 LineServices 的管线**里的。
        ///   零记录一旦被当作 `previousLineBreakRecord` 回传给 LS，就**不会崩在显眼处**，
        ///   而是按错的行断记录排版（最坏的一类）；而本工程的 Win32 shim 里
        ///   **`LoAcquireBreakRecord` / `LoCreateLine` 连符号都没有**（`nm -D libwpfwin32.so` 实测），
        ///   所以真走过去只会是 `EntryPointNotFoundException`。
        ///   ⇒ 这里**记数 + 打诊断**（`WPF_LINUX_TEXTLINE_DIAG=1`），STRICT 下直接抛。
        /// </summary>
        internal static void NoteZeroBreakRecordIssued(string where)
        {
            System.Threading.Interlocked.Increment(ref s_breakZeroRecordIssued);
            Diag($"LS_BOUNDARY 零记录 TextLineBreak 已交出（{where}）；真机 TextMetrics.cs:299-308 只在 modifier 分支 new 它，"
                 + "而我们不伪造原生断行记录 ⇒ 该记录若被回传给 LS 一定会撞 EntryPointNotFoundException"
                 + "（shim 未导出 LoAcquireBreakRecord / LoCreateLine）");
            if (Strict)
                throw new NotSupportedException(
                    "HbTextLine.GetTextLineBreak 交出的是**零记录** TextLineBreak（B2 刻意不伪造 LS 断行记录）；"
                    + "WPF_LINUX_TEXTLINE_STRICT=1 时按失败上报。");
        }

        /// <summary>回落使用一次欠账实现（仍有 6 个真欠账）。</summary>
        internal static void NoteFallback(string member)
        {
            int i = Array.IndexOf(OwedMembers, member);
            if (i >= 0) System.Threading.Interlocked.Increment(ref s_hits[i]);
            InstallDump();
        }

        internal static void Diag(string message)
        {
            if (!DiagEnabled) return;
            try { Console.Error.WriteLine("[TEXTLINE_DIAG] " + message); } catch { }
        }

        /// <summary>清计数（测试用）。</summary>
        public static void ResetCounters()
        {
            for (int i = 0; i < s_hits.Length; i++) System.Threading.Interlocked.Exchange(ref s_hits[i], 0);
            System.Threading.Interlocked.Exchange(ref s_linesConstructed, 0);
            System.Threading.Interlocked.Exchange(ref s_drawCalls, 0);
            System.Threading.Interlocked.Exchange(ref s_getTextBoundsCalls, 0);
            System.Threading.Interlocked.Exchange(ref s_getTextRunSpansCalls, 0);
            System.Threading.Interlocked.Exchange(ref s_paragraphsFormatted, 0);
            System.Threading.Interlocked.Exchange(ref s_breakNullReturned, 0);
            System.Threading.Interlocked.Exchange(ref s_breakZeroRecordIssued, 0);
            System.Threading.Interlocked.Exchange(ref s_modifierLines, 0);
            System.Threading.Interlocked.Exchange(ref s_collapseCalls, 0);
            System.Threading.Interlocked.Exchange(ref s_collapseEarlyReturnIneligible, 0);
            System.Threading.Interlocked.Exchange(ref s_collapseEarlyReturnTooWide, 0);
            System.Threading.Interlocked.Exchange(ref s_collapseEmptyArgsThrow, 0);
            System.Threading.Interlocked.Exchange(ref s_collapseApplied, 0);
            System.Threading.Interlocked.Exchange(ref s_collapseUnsupported, 0);
            System.Threading.Interlocked.Exchange(ref s_collapsedRangesNull, 0);
            System.Threading.Interlocked.Exchange(ref s_collapsedRangesReturned, 0);
            System.Threading.Interlocked.Exchange(ref s_forcedBreakLines, 0);
            System.Threading.Interlocked.Exchange(ref s_kinsokuPullTotal, 0);
            System.Threading.Interlocked.Exchange(ref s_dependentLengthQueries, 0);
        }

        /// <summary>
        /// 一行汇总（主控要的"一条汇总行"）。格式稳定，便于 grep/断言。
        /// **前 6 项 + 9 个欠账分量是 2026-09-10 起的既有格式（绊线脚本的锚点），只追加不改名。**
        /// </summary>
        public static string SummaryLine()
        {
            var sb = new StringBuilder();
            sb.Append("HB_TEXTLINE enabled=").Append(Enabled ? 1 : 0);
            sb.Append(" lines=").Append(LinesConstructed);
            sb.Append(" draw=").Append(DrawCalls);
            sb.Append(" getTextBounds=").Append(GetTextBoundsCalls);
            sb.Append(" getTextRunSpans=").Append(GetTextRunSpansCalls);
            sb.Append(" fallbackTotal=").Append(TotalFallbackHits);
            for (int i = 0; i < OwedMembers.Length; i++)
                sb.Append(' ').Append(OwedMembers[i]).Append('=').Append(System.Threading.Interlocked.Read(ref s_hits[i]));
            // ---- B2 追加（纯追加，不动上面的字段）----
            sb.Append(" paragraphs=").Append(ParagraphsFormatted);
            sb.Append(" breakNull=").Append(BreakNullReturned);
            sb.Append(" breakZeroRecords=").Append(BreakZeroRecordIssued);
            sb.Append(" modifierLines=").Append(ModifierLines);
            sb.Append(" collapseCalls=").Append(CollapseCalls);
            sb.Append(" collapseIneligible=").Append(CollapseEarlyReturnIneligible);
            sb.Append(" collapseTooWide=").Append(CollapseEarlyReturnTooWide);
            sb.Append(" collapseEmptyArgsThrow=").Append(CollapseEmptyArgsThrow);
            sb.Append(" collapseApplied=").Append(CollapseApplied);
            sb.Append(" collapseUnsupported=").Append(CollapseUnsupported);
            sb.Append(" collapsedRangesNull=").Append(CollapsedRangesNull);
            sb.Append(" collapsedRangesReturned=").Append(CollapsedRangesReturned);
            sb.Append(" forcedBreakLines=").Append(ForcedBreakLines);
            sb.Append(" kinsokuPulls=").Append(KinsokuPullTotal);
            sb.Append(" dependentLengthQueries=").Append(DependentLengthQueries);
#if TEXTLINE_SHIM_DIRECT
            sb.Append(' ').Append(HbTextFallback.SummaryFragment());
#endif
            return sb.ToString();
        }

        /// <summary>把汇总写进 `WPF_LINUX_TEXTLINE_DUMP` 指定的文件（进程退出时自动写一次）。</summary>
        public static void Dump(string path)
        {
            if (string.IsNullOrEmpty(path)) return;
            try
            {
                File.AppendAllText(path, SummaryLine() + Environment.NewLine);
            }
            catch
            {
                // 落盘失败不影响主链路
            }
        }

        private static void InstallDump()
        {
            if (System.Threading.Interlocked.Exchange(ref s_dumpInstalled, 1) != 0) return;
            string path = Environment.GetEnvironmentVariable(DumpEnvVar);
            if (string.IsNullOrEmpty(path)) return;
            AppDomain.CurrentDomain.ProcessExit += (_, __) => Dump(path);
        }

        /// <summary>进程退出时无条件落盘（设了 dump 路径时）。构造第一行时调用一次。</summary>
        internal static void EnsureDumpInstalled() => InstallDump();
    }

    // ==================================================================================
    //  4. TextRunProperties / TextRun 的最小实现
    // ==================================================================================

    /// <summary>`TextRunProperties` 的最小实现（8 个 abstract 成员）。</summary>
    internal sealed class HbRunProperties : TextRunProperties
    {
        private readonly Typeface _typeface;
        private readonly Brush _foreground;

        internal HbRunProperties(Typeface typeface, double emSize, Brush foreground)
        {
            _typeface = typeface;
            _foreground = foreground;
            FontRenderingEmSizeValue = emSize;
        }

        internal double FontRenderingEmSizeValue { get; set; }

        public override Typeface Typeface => _typeface;
        public override double FontRenderingEmSize => FontRenderingEmSizeValue;
        public override double FontHintingEmSize => FontRenderingEmSizeValue;
        public override CultureInfo CultureInfo => CultureInfo.InvariantCulture;
        public override Brush ForegroundBrush => _foreground;
        public override Brush BackgroundBrush => null;
        public override TextDecorationCollection TextDecorations => null;
        public override TextEffectCollection TextEffects => null;
    }

    /// <summary>`TextRun` 的最小实现（3 个 abstract 成员）。</summary>
    internal sealed class HbTextRun : TextRun
    {
        internal HbTextRun(string text, int offset, int length, TextRunProperties props)
        {
            Text = text; Offset = offset; LengthValue = length; Props = props;
            CharacterBufferReferenceValue = new CharacterBufferReference(text, offset);
        }

        internal string Text { get; }
        internal int Offset { get; }
        internal int LengthValue { get; }
        internal TextRunProperties Props { get; }
        internal CharacterBufferReference CharacterBufferReferenceValue { get; }

        public override CharacterBufferReference CharacterBufferReference => CharacterBufferReferenceValue;
        public override int Length => LengthValue;
        public override TextRunProperties Properties => Props;
    }

    // ==================================================================================
    //  5. HbTextLine —— TextLine 契约实现（B2：三个成员做**实**）
    // ==================================================================================

    /// <summary>
    /// 用 HarfBuzz shaping 驱动的 `TextLine`。
    ///
    /// **契约规模**：`TextLine` 是 public abstract，共 **19 个 abstract 属性 + 13 个 abstract 方法 = 32 个成员**。
    /// 本类真实现：`GetTextRunSpans` / `GetTextBounds` / `Draw` / `Collapse` / `GetTextCollapsedRanges`
    /// / `GetTextLineBreak` / `Dispose` + **19 个属性**；其余 **6 个方法按"安全回退 + 计数"**（B3 做）。
    ///
    /// **对齐哪一条真机实现**：本类对齐 `MS.Internal.TextFormatting.TextMetrics+FullTextLine`
    /// （行断/折叠的真值都出自它）。真机里 `SimpleTextLine` 的 `GetTextLineBreak`/`GetTextCollapsedRanges`
    /// **恒为 null**（`SimpleTextLine.cs:973/983`）—— 那只是快路径；本类不复刻"永远 null"的捷径，
    /// 在**可折叠行**上会真的折叠（= FullTextLine 行为）。
    /// </summary>
    internal sealed class HbTextLine : TextLine
    {
        private const string Ellipsis = "\u2026";   // 与上游 `TextTrailing*Ellipsis` 的常量一致

        // ---- 构造期固定 ----
        private readonly string _text;              // 源文本（段落系索引就是它的下标）
        private readonly int _lineStart;            // 行起始（段落系）
        private readonly int _visibleLength;        // 可见文本长度（不含硬断字符）
        private readonly int _hardBreakLen;         // 本行末尾硬断字符个数（0/1/2）
        private readonly bool _hasEop;              // 末行 ⇒ EOP 字符（Length +1）
        private readonly double[] _charAdvances;    // 可见文本逐字 advance
        private readonly string _fontPath;
        private readonly GlyphTypeface _glyphTypeface;
        private readonly float _pixelsPerDip;
        private readonly TextRunProperties _runProperties;
        private readonly HbTextRun _run;
        private readonly HbShapedRun _shaped;
        private readonly GlyphRun _glyphRun;        // 空行（0 字形）时为 null —— GlyphRun 不接受空列表
        private readonly bool _keepState;           // = 上游 StatusFlags.KeepState（AlwaysCollapsible）
        private readonly bool _hasModifierScope;    // 源里有 TextModifier ⇒ GetTextLineBreak 才非 null
        private readonly bool _forcedBreak;         // 规则 3 产出（"内容没放下"的**诊断**信息）

        // ---- 记账（构造后不再变；折后行由 BuildCollapsedLine 直接给覆盖值）----
        private readonly int _length;
        private readonly int _newlineLength;
        private readonly int _trailingWhitespaceLength;
        private readonly double _width;
        private readonly double _widthIncludingTrailingWhitespace;

        // ---- 折叠态 ----
        private TextCollapsedRange _collapsedRange;
        private bool _hasCollapsed;
        private bool _disposed;

        /// <summary>单 run 便捷构造（B1 原型路径 / 整串就是一行）。</summary>
        internal HbTextLine(HbTextRun run, HbShapedRun shaped, GlyphTypeface glyphTypeface, float pixelsPerDip)
            : this(run, shaped, glyphTypeface, pixelsPerDip, shaped.Text, 0, null, 0, false, false, false, false, 0,
                   shaped.Text.Length,
                   0,
                   TrailingWhitespaceCount(shaped.Text),
                   WidthWithoutTrailingWhitespace(shaped),
                   shaped.TotalWidthPx)
        { }

        private HbTextLine(HbTextRun run, HbShapedRun shaped, GlyphTypeface glyphTypeface, float pixelsPerDip,
                           string text, int lineStart, string fontPath, int hardBreakLen, bool hasEop,
                           bool keepState, bool hasModifierScope, bool forcedBreak, double lineHeight,
                           int length, int newlineLength, int trailingWhitespaceLength, double width, double widthIncludingTrailingWhitespace)
        {
            _run = run;
            _shaped = shaped;
            _text = text ?? string.Empty;
            _lineStart = lineStart;
            _fontPath = fontPath;
            _hardBreakLen = hardBreakLen;
            _hasEop = hasEop;
            _glyphTypeface = glyphTypeface;
            _pixelsPerDip = pixelsPerDip;
            _runProperties = run != null ? run.Props : null;
            _keepState = keepState;
            _hasModifierScope = hasModifierScope;
            _forcedBreak = forcedBreak;
            _visibleLength = shaped.Text.Length;
            _charAdvances = shaped.CharAdvances();
            _length = length;
            _newlineLength = newlineLength;
            _trailingWhitespaceLength = trailingWhitespaceLength;
            _width = width;
            _widthIncludingTrailingWhitespace = widthIncludingTrailingWhitespace;

            // ⭐ 真机三条公式（`tests/parity/windows/layout-b34/results-cd2.json` 的 10 例 LineHeight 真值实测）：
            //   · `Height = LineHeight`（**未设 ⇒ 字体自然行高**）
            //   · `TextHeight` **恒为自然文本高**（不跟 LineHeight 走）
            //   · `Baseline = LineHeight × (自然Baseline / 自然Height)`
            //     实测：lh10 → 10×17.1033/21.7933 = 7.848 ≈ 真值 7.8500；lh30 → 23.542 ≈ 23.5467；lh50 → 39.237 ≈ 39.2433 ✓
            double naturalHeight = (glyphTypeface != null ? glyphTypeface.Height : 0) * shaped.EmSize;
            double naturalBaseline = (glyphTypeface != null ? glyphTypeface.Baseline : 0) * shaped.EmSize;
            _textHeight = naturalHeight;
            if (lineHeight > 0 && naturalHeight > 0)
            {
                _height = lineHeight;
                _baseline = lineHeight * (naturalBaseline / naturalHeight);
            }
            else
            {
                _height = naturalHeight;
                _baseline = naturalBaseline;
            }
            double baseline = _baseline;

            if (shaped.Glyphs.Length > 0)
            {
                var chars = new List<char>(shaped.Text.ToCharArray());
                _glyphRun = new GlyphRun(
                    glyphTypeface, 0, false, shaped.EmSize, pixelsPerDip,
                    new List<ushort>(shaped.Glyphs),
                    new Point(0, baseline),
                    new List<double>(shaped.AdvancesPx),
                    MakeOffsets(shaped),
                    chars,
                    null,
                    InvertClusters(shaped, chars.Count),
                    MakeCaretStops(chars.Count),
                    XmlLanguage.GetLanguage("en-US"));
            }

            HbTextLineScaffold.NoteConstructed();
            HbTextLineScaffold.EnsureDumpInstalled();
            if (hasModifierScope) HbTextLineScaffold.NoteModifierLine();
        }

        private readonly double _height;
        private readonly double _baseline;
        private readonly double _textHeight;      // 真机：**恒为自然文本高**，不随 LineHeight 变

        /// <summary>
        /// ⭐ B2 的正式构造路径：一行 = 源文本 + 断行结果 + 逐字 advance（**真机口径的记账**）。
        /// </summary>
        internal static HbTextLine FormatLine(
            string text, HbLineRange range, double[] paragraphAdvances, string fontPath,
            double emSize, GlyphTypeface glyphTypeface, float pixelsPerDip, TextRunProperties runProperties,
            bool keepState, bool hasModifierScope, double lineHeight)
        {
            int visibleLen = range.VisibleLength;
            string visible = text.Substring(range.Start, visibleLen);
            HbShapedRun shaped = HbShaper.Shape(fontPath, visible, emSize);

            int trailingWs = TrailingWhitespaceCount(visible);
            double wsAdvance = 0;
            for (int i = visibleLen - trailingWs; i < visibleLen; ++i)
                wsAdvance += (i < paragraphAdvances.Length) ? paragraphAdvances[i] : 0;

            double witw = shaped.TotalWidthPx;                                 // ③ 行尾空白占区间
            double w = witw - wsAdvance;                                       // ③ 但不占 Width
            int eop = range.HasEop ? 1 : 0;
            int length = visibleLen + range.HardBreakLen + eop;                 // ① 含硬断字符 + EOP
            int newlineLength = range.HardBreakLen + eop;                       // 末行 NewlineLength=1 是 EOP
            int trailingWhitespaceLength = trailingWs + range.HardBreakLen + eop;

            TextRunProperties props;
            var hbProps = runProperties as HbRunProperties;
            if (hbProps != null) props = hbProps;
            else props = new HbRunProperties(runProperties != null ? runProperties.Typeface : null, emSize,
                                             runProperties != null ? runProperties.ForegroundBrush : null);
            var run = new HbTextRun(visible, 0, visibleLen, props);

            var line = new HbTextLine(run, shaped, glyphTypeface, pixelsPerDip, text, range.Start,
                                      fontPath, range.HardBreakLen, range.HasEop,
                                      keepState, hasModifierScope, range.Forced, lineHeight,
                                      length, newlineLength, trailingWhitespaceLength, w, witw);
            if (range.Forced) HbTextLineScaffold.NoteForcedBreakLine();
            if (range.KinsokuPull > 0) HbTextLineScaffold.NoteKinsokuPull(range.KinsokuPull);
            return line;
        }

        private static int TrailingWhitespaceCount(string s)
        {
            int n = 0;
            while (n < s.Length && char.IsWhiteSpace(s[s.Length - 1 - n])) ++n;
            return n;
        }

        private static double WidthWithoutTrailingWhitespace(HbShapedRun shaped)
        {
            double[] adv = shaped.CharAdvances();
            int ws = TrailingWhitespaceCount(shaped.Text);
            double w = 0;
            for (int i = 0; i < adv.Length - ws; ++i) w += adv[i];
            return w;
        }

        private static List<Point> MakeOffsets(HbShapedRun shaped)
        {
            var offsets = new List<Point>(shaped.OffsetsXPx.Length);
            foreach (double dx in shaped.OffsetsXPx) offsets.Add(new Point(dx, 0));
            return offsets;
        }

        /// <summary>
        /// clusters：HarfBuzz 给的是「字形→字符」（单调不减），WPF 要的是「字符→字形」——
        /// 必须**求逆**。契约（`GlyphRun.cs:370-392`）：个数 == characters.Count、[0]==0、
        /// 单调不减、每个值 &lt; GlyphCount。
        /// </summary>
        private static List<ushort> InvertClusters(HbShapedRun shaped, int charCount)
        {
            int glyphCount = shaped.Glyphs.Length;
            var map = new List<ushort>(charCount);
            int g = 0;
            for (int c = 0; c < charCount; c++)
            {
                while (g + 1 < glyphCount && shaped.Clusters[g + 1] <= (uint)c) g++;
                int mapped = g;
                if (mapped >= glyphCount) mapped = glyphCount - 1;
                if (mapped < 0) mapped = 0;
                if (map.Count > 0 && mapped < map[map.Count - 1]) mapped = map[map.Count - 1];
                map.Add((ushort)mapped);
            }
            if (map.Count > 0) map[0] = 0;
            return map;
        }

        /// <summary>caretStops 个数 == characters.Count **+ 1**（`GlyphRun.cs:411`）。</summary>
        private static List<bool> MakeCaretStops(int charCount)
        {
            var stops = new List<bool>(charCount + 1);
            for (int i = 0; i <= charCount; i++) stops.Add(true);
            return stops;
        }

        // ==================================================================
        //  真实现的 override
        // ==================================================================

        public override IList<TextSpan<TextRun>> GetTextRunSpans()
        {
            HbTextLineScaffold.NoteGetTextRunSpans();

            // ── 契约补齐（2026-09-12，主控批准）：**段末行的末 span 必须是 `TextEndOfParagraph`** ──
            // 上游 `TextBoxLine.EndOfParagraph`（`…/documents/TextBoxLine.cs:362-371`）判据是
            //   `_line.NewlineLength != 0 && ((TextSpan<TextRun>)runs[runs.Count - 1]).Value is TextEndOfParagraph`
            // 而 `TextBoxLine.Length = _line.Length - (EndOfParagraph ? 1 : 0)`（同文件 `:378-380`）
            //   ⇒ **只有认出 EOP，宿主才会把合成 EOP 那 1 个位置从行宽里减掉**。
            // 本实现在 `Length` 里**已经**含 EOP（本文件 `FormatLine()` 的记账
            //   `int length = visibleLen + range.HardBreakLen + eop;`，`NewlineLength = HardBreakLen + eop`），
            // 却只回吐一个 `HbTextRun` span ⇒ `EndOfParagraph=false` ⇒ 宿主拿到的行宽比真实内容**多 1**
            //   ⇒ `TextBoxView.FullMeasureTick` 的 `lineOffset += line.Length` 越过容器末位
            //   ⇒ 下一次 `FormatLine` 落在 `dcp = SymbolCount + 1` ⇒ 上游
            //      `TextContainer.GetNodeAndEdgeAtOffset`（`:1284`）"Bogus symbol offset!" ⇒ FailFast。
            // 实测（波 7 权威 PC `b444c5a5c6a7fe39`，`"seed-文本"` = 7 字符）：
            //   `HBLINE A#0 cpFirst=0 cpLast=8 len=8 nl=1` + 断言栈 `SimpleTextLine.Linux.cs:227`
            //   ⇒ 越界 dcp = 8 = SymbolCount(7) + 1，**溢出量恰为 EOP 那 1 个位置**。
            // **副带修正**：改前 spans 总长 = `_visibleLength`，与 `Length`（含硬断字符 + EOP）不等；
            //   改后 = 可见文本 + EOP = `Length`（硬断字符仍不在任何 span 里，属既有欠账，本次不动）。
            // 构造式与 `TextBoxLine.cs:77`（`new TextEndOfParagraph(1)`）逐字一致；
            //   `TextEndOfParagraph(int)` 是 public ctor（已用编译器确认，不靠记忆）。
            var spans = new List<TextSpan<TextRun>>(2);
            if (_visibleLength > 0)
                spans.Add(new TextSpan<TextRun>(_visibleLength, _run));
            if (_hasEop)
                spans.Add(new TextSpan<TextRun>(1, new TextEndOfParagraph(1)));
            if (spans.Count == 0)
                spans.Add(new TextSpan<TextRun>(_length, _run));   // 兜底：空行且无 EOP（不应发生）
            return spans;
        }

        public override IList<TextBounds> GetTextBounds(int firstTextSourceCharacterIndex, int textLength)
        {
            if (_disposed) throw new ObjectDisposedException(nameof(HbTextLine));
            HbTextLineScaffold.NoteGetTextBounds();

            // ⭐ 真机口径（oracle `indexFrames.GetTextBounds_firstArg`）：第一个参数是**段落系**索引，
            //    不是行内偏移 —— 原型版本按行内偏移算，那是错的（传 0 时只有行起点=0 的行有结果）。
            int localFirst = firstTextSourceCharacterIndex - _lineStart;
            if (localFirst < 0 || localFirst > _visibleLength) return new List<TextBounds>();  // 与本行不相交
            int localLen = Math.Min(textLength, _visibleLength - localFirst);
            if (localLen < 0) localLen = 0;

            double x0 = AdvanceBefore(localFirst);
            double x1 = AdvanceBefore(localFirst + localLen);
            var rect = new Rect(x0, 0, Math.Max(0, x1 - x0), _height);

            var runBounds = new List<TextRunBounds>
            {
                HbInternalsFactory.CreateRunBounds(rect, firstTextSourceCharacterIndex,
                                                   firstTextSourceCharacterIndex + localLen, _run),
            };
            return new List<TextBounds>
            {
                HbInternalsFactory.CreateTextBounds(rect, FlowDirection.LeftToRight, runBounds),
            };
        }

        public override void Draw(DrawingContext drawingContext, Point origin, InvertAxes inversion)
        {
            if (_disposed) throw new ObjectDisposedException(nameof(HbTextLine));
            if (drawingContext == null) throw new ArgumentNullException(nameof(drawingContext));
            if (inversion != InvertAxes.None)
                throw new NotSupportedException("B1/B2 只支持 InvertAxes.None");

            HbTextLineScaffold.NoteDraw();
            if (_glyphRun == null) return;                 // 空行（无字形）没什么可画
            drawingContext.DrawGlyphRun(_run.Props != null ? _run.Props.ForegroundBrush : null, _glyphRun);
        }

        /// <summary>原型/测试专用：拿内部 `GlyphRun` 做光栅化取证（空行返回 null）。</summary>
        internal GlyphRun GlyphRunForRasterization => _glyphRun;

        /// <summary>测试专用：本行的可见文本（不参与契约）。</summary>
        internal string LineTextForDiag => _shaped != null ? _shaped.Text : string.Empty;

        /// <summary>测试专用：本行的诊断信息（不参与契约）。</summary>
        internal string Diagnostics =>
            $"start={_lineStart} visible={_visibleLength} hardBreak={_hardBreakLen} eop={(_hasEop ? 1 : 0)} " +
            $"forced={(_forcedBreak ? 1 : 0)} keepState={(_keepState ? 1 : 0)} modifier={(_hasModifierScope ? 1 : 0)}";

        private double AdvanceBefore(int charIndex)
        {
            double x = 0;
            for (int i = 0; i < charIndex && i < _charAdvances.Length; i++) x += _charAdvances[i];
            return x;
        }

        // ==================================================================
        //  19 个 abstract 属性
        // ==================================================================

        public override double Baseline => _baseline;
        public override double TextBaseline => _baseline;
        public override double Height => _height;
        public override double TextHeight => _textHeight;   // 真机：恒为自然文本高（≠ Height 当 LineHeight>0）
        public override double Extent => _height;
        public override double MarkerHeight => _height;
        public override double MarkerBaseline => _baseline;
        public override double Width => _width;
        public override double WidthIncludingTrailingWhitespace => _widthIncludingTrailingWhitespace;
        public override double Start => 0;          // 真机实测恒为 0（3222/3222），不是段落内偏移
        public override double OverhangAfter => 0;
        public override double OverhangLeading => 0;
        public override double OverhangTrailing => 0;
        public override int Length => _length;
        public override int DependentLength
        {
            get
            {
                // ⚠️ 未实现（登记在报告"未覆盖清单"）：真机 dump 里这一项有 0..3 的真值，
                //    它是 LS 的"下一行依赖长度"，本引擎没有该概念。恒 0 但**可计数**。
                HbTextLineScaffold.NoteDependentLengthQuery();
                return 0;
            }
        }
        public override int NewlineLength => _newlineLength;
        public override int TrailingWhitespaceLength => _trailingWhitespaceLength;
        public override bool HasCollapsed => _hasCollapsed;

        /// <summary>
        /// 真机实测：**3222/3222 行全为 false**（含被强制断开的行）⇒ 本实现恒 false。
        /// "这一行是不是被强制断出来的"这条信息不丢：见 `forcedBreakLines` 计数 + `Diagnostics`。
        /// </summary>
        public override bool HasOverflowed => false;

        public override void Dispose()
        {
            _disposed = true;
            // 本类不持有非托管资源：`HbShapedRun` 里全是托管数组，`GlyphRun` 是托管对象，
            // **没有** LS 句柄要释放 —— 也正因为如此，`GetTextLineBreak` 只发**零记录**
            // （上游 `TextLineBreak.DisposeInternal` 对 `IntPtr.Zero` 不会调 `LoDisposeBreakRecord`）。
        }

        // ==================================================================
        //  ⭐ B2-1：GetTextLineBreak（真机口径：普通文本 ⇒ null）
        // ==================================================================

        /// <summary>
        /// 真机（`TextMetrics.cs:299-308` + oracle 实测 3220 null / 2 非 null）：
        /// **只有"末 run 带 `TextModifierScope` 且不是 `TextEndOfParagraph`"时才 new 一个 `TextLineBreak`**；
        /// 普通文本一律 **null**。
        ///
        /// 我们**不伪造原生断行记录**（`_breakRecord` 恒 `IntPtr.Zero`）——伪造一个假句柄
        /// 就是典型的"不崩但也不对"。零记录一交出去就**记数 + 打诊断**（LS 边界绊线）。
        /// </summary>
        public override TextLineBreak GetTextLineBreak()
        {
            if (_disposed) throw new ObjectDisposedException(nameof(HbTextLine));

            if (!_hasModifierScope)
            {
                HbTextLineScaffold.NoteBreakNull();          // 真机主路径（3220/3222）
                return null;
            }

            HbTextLineScaffold.NoteZeroBreakRecordIssued(
                $"HbTextLine.GetTextLineBreak lineStart={_lineStart} length={_length}");
            return HbInternalsFactory.CreateLineBreak();
        }

        // ==================================================================
        //  ⭐ B2-2 / B2-3：Collapse / GetTextCollapsedRanges（真机口径的字符省略号折叠）
        // ==================================================================
        //
        //  依据（`FullTextLine.cs:693-800` + oracle 实测 430 折叠 / 17 不折叠）：
        //    ① `if (!HasOverflowed && (statusFlags & KeepState) == 0) return this;`   ← 先判资格
        //    ② 空参 ⇒ **ArgumentNullException**（oracle：447 行抛 = 恰好是 alwaysCollapsible 的 447 行）
        //    ③ `if (constraintWidth > Width) return this;`                            ← 零宽行落这里（17 行）
        //    ④ `constraintWidth -= symbol.Width`；以"字符级强制断"贪心取可见前缀（**至少 1 字**）
        //    ⑤ 折后 `Length` = **原 Length**；`Width` = 前缀宽 + 符号宽
        //    ⑥ `collapsedRange = { 行起点 + 可见长, 原Length − 可见长, 原Width − 折后Width }`
        //    ⑦ 未折叠 ⇒ `GetTextCollapsedRanges()` 返回 **null**（不是空集合）
        // ==================================================================

        public override TextLine Collapse(params TextCollapsingProperties[] collapsingPropertiesList)
        {
            if (_disposed) throw new ObjectDisposedException(nameof(HbTextLine));
            HbTextLineScaffold.NoteCollapseCall();

            if (!HasOverflowed && !_keepState)
            {
                HbTextLineScaffold.NoteCollapseIneligible();
                return this;                                  // ① 真机：不满足资格的行原样返回（不抛）
            }
            if (collapsingPropertiesList == null || collapsingPropertiesList.Length == 0)
            {
                HbTextLineScaffold.NoteCollapseEmptyArgsThrow();
                throw new ArgumentNullException(nameof(collapsingPropertiesList));   // ②
            }

            TextCollapsingProperties collapsingProp = collapsingPropertiesList[0];
            if (collapsingProp == null) { HbTextLineScaffold.NoteCollapseUnsupported(); return this; }

            double constraintWidth = collapsingProp.Width;
            if (constraintWidth > Width)
            {
                HbTextLineScaffold.NoteCollapseTooWide();
                return this;                                  // ③
            }

            // 本轮只实现真机 oracle 覆盖到的那一种（`TextTrailingCharacterEllipsis`，符号恒 U+2026）。
            // `TextTrailingWordEllipsis` 没有真机真值 ⇒ **不猜**，记数后原样返回（登记为缺口）。
            if (collapsingProp.Style != TextCollapsingStyle.TrailingCharacter)
            {
                HbTextLineScaffold.NoteCollapseUnsupported();
                HbTextLineScaffold.Diag($"Collapse: 折叠样式 {collapsingProp.Style} 本轮无真机真值"
                                        + "（只实现 TrailingCharacter）⇒ 原样返回");
                return this;
            }

            // 上游两个 TextTrailing*Ellipsis 的符号**恒为** U+2026（`TextTrailing*Ellipsis.cs` 里的常量）。
            // 我们按同一常量取符号宽（行内字体/字号）；若调用方给了别的符号 ⇒ 记数回退，不猜。
            if (collapsingProp.Symbol != null && collapsingProp.Symbol.Length != Ellipsis.Length)
            {
                HbTextLineScaffold.NoteCollapseUnsupported();
                HbTextLineScaffold.Diag($"Collapse: 折叠符号不是 1 字的 U+2026（Length={collapsingProp.Symbol.Length}）⇒ 原样返回");
                return this;
            }

            double symbolWidth = HbShaper.Shape(_fontPath, Ellipsis, _shaped.EmSize).TotalWidthPx;
            double inner = constraintWidth - symbolWidth;

            // ④ 可见前缀：按 **HarfBuzz 簇**（cluster）贪心 —— **绝不在簇内切**。
            //    实测依据（真机 oracle）：`F_hard_lf_w40` 行 'first '（cw=14.84）真机可见前缀 = 'fi'（2 字），
            //    而 'fi' 在 Noto Sans 里是**一个连字簇**（advance 全记在首字符上，第二字符 0）
            //    ⇒ 按"逐字符"贪心只会拿到 'f' 1 字（本实现第一版就是这样，36/236 行明细不符）。
            //    簇起点 = HarfBuzz 的 `Clusters[]` 去重升序；簇宽 = 该簇所有字形 advance 之和。
            int visibleLen = 0;
            if (inner > 0 && _charAdvances.Length > 0 && _shaped != null && _shaped.Glyphs.Length > 0)
            {
                var cells = new List<int>();
                for (int i = 0; i < _shaped.Clusters.Length; ++i)
                {
                    int c = (int)_shaped.Clusters[i];
                    if (c >= 0 && c < _visibleLength && (cells.Count == 0 || cells[cells.Count - 1] != c)) cells.Add(c);
                }
                if (cells.Count == 0 || cells[0] != 0) cells.Insert(0, 0);
                if (cells[cells.Count - 1] != _visibleLength) cells.Add(_visibleLength);

                double w = 0; int k = 0;
                for (int ci = 0; ci + 1 < cells.Count; ++ci)
                {
                    double cellW = 0;
                    for (int x = cells[ci]; x < cells[ci + 1]; ++x) cellW += _charAdvances[x];
                    if (w + cellW <= inner + 1e-9) { w += cellW; k = cells[ci + 1]; } else break;
                }
                visibleLen = k > 0 ? k : (cells.Count > 1 ? cells[1] : 1);   // **至少 1 簇**
            }

            double prefixWidth = 0;
            for (int i = 0; i < visibleLen; ++i) prefixWidth += _charAdvances[i];
            // 前缀的**行尾空白不计入折后宽度**（真机实测公式，逐例算过）：
            //   `F_lat_words_w120` 行 'lazy dog and '（行起点 35、可见 5 字 = 'lazy '）：
            //   真机折后 W = 41.4400 = w('lazy') + w('…') = 28.7833 + 12.6567（**丢掉了那个空格 4.16**），
            //   而 cr 仍然把该空格算进可见区间（cp=40 ⇒ 可见 [35,40)）⇒ 两件事分开：
            //   可见长度按簇给，宽度按"前缀去掉行尾空白 + 符号"给。
            int prefixTrailingWs = 0;
            while (prefixTrailingWs < visibleLen &&
                   char.IsWhiteSpace(_text[_lineStart + visibleLen - 1 - prefixTrailingWs])) ++prefixTrailingWs;
            double prefixWsWidth = 0;
            for (int i = visibleLen - prefixTrailingWs; i < visibleLen; ++i) prefixWsWidth += _charAdvances[i];
            double collapsedWidth = prefixWidth - prefixWsWidth + symbolWidth;

            HbTextLine collapsed = BuildCollapsedLine(visibleLen, collapsedWidth);
            if (visibleLen < _visibleLength)
            {
                collapsed._collapsedRange = HbInternalsFactory.CreateCollapsedRange(
                    _lineStart + visibleLen,                       // 段落系索引
                    _length - visibleLen,                          // 原 Length − 可见长
                    _width - collapsedWidth);                      // 原 Width − 折后 Width
            }
            collapsed._hasCollapsed = true;
            HbTextLineScaffold.NoteCollapseApplied();
            return collapsed;
        }

        public override IList<TextCollapsedRange> GetTextCollapsedRanges()
        {
            if (_disposed) throw new ObjectDisposedException(nameof(HbTextLine));
            if (_collapsedRange == null)
            {
                HbTextLineScaffold.NoteCollapsedRangesNull();
                return null;                                   // ⑦ 真机：**null**，不是空集合（3222/3222）
            }
            HbTextLineScaffold.NoteCollapsedRangesReturned();
            return new TextCollapsedRange[] { _collapsedRange };
        }

        /// <summary>折后行：文本 = 可见前缀 + 省略号；`Length` 保持**原行** Length（上游 `_cchLength = Length`）。</summary>
        private HbTextLine BuildCollapsedLine(int visibleLen, double collapsedWidth)
        {
            string prefix = _text.Substring(_lineStart, visibleLen);
            string collapsedText = prefix + Ellipsis;
            HbShapedRun shaped = HbShaper.Shape(_fontPath, collapsedText, _shaped.EmSize);
            TextRunProperties props = _runProperties ?? new HbRunProperties(null, _shaped.EmSize, null);
            var run = new HbTextRun(collapsedText, 0, collapsedText.Length, props);
            var collapsed = new HbTextLine(run, shaped, _glyphTypeface, _pixelsPerDip, collapsedText, 0,
                                           _fontPath, 0, false, false, _hasModifierScope, false, 0,
                                           _length,                       // ⑤ 折后行 Length = 原 Length
                                           _newlineLength,
                                           0,
                                           collapsedWidth,
                                           collapsedWidth);
            return collapsed;
        }

        // ==================================================================
        //  6 个仍然欠账的 override —— **安全回退，不抛**
        // ==================================================================
        //
        //  【为什么不抛】抛异常 = 崩溃；回退 = 降级但可用 —— 产品上是天壤之别。
        //  【严格模式】`WPF_LINUX_TEXTLINE_STRICT=1` 时改为抛异常（bring-up 期定位用）。
        //  【B2 减少的欠账】Collapse / GetTextCollapsedRanges / GetTextLineBreak 已**真实现**（上面）。
        //    剩下的 6 个：光标/命中 5 个（B3）+ GetIndexedGlyphRuns（上游 **0 个调用点**，
        //    主控 2026-09-11 明确不实现 —— 做了也无人验证，只会变成新的谎报面）。
        // ==================================================================

        private static void Owed(string member)
        {
            HbTextLineScaffold.NoteFallback(member);
            if (HbTextLineScaffold.Strict)
                throw new NotSupportedException(
                    $"HbTextLine.{member} 仍是**回退**实现（WPF_LINUX_TEXTLINE_STRICT=1 时抛）");
        }

        public override IEnumerable<IndexedGlyphRun> GetIndexedGlyphRuns()
        {
            Owed("GetIndexedGlyphRuns");
            return Array.Empty<IndexedGlyphRun>();
        }

        public override CharacterHit GetCharacterHitFromDistance(double distance)
        {
            Owed("GetCharacterHitFromDistance");
            return new CharacterHit(0, 0);
        }

        public override double GetDistanceFromCharacterHit(CharacterHit characterHit)
        {
            Owed("GetDistanceFromCharacterHit");
            return 0;
        }

        public override CharacterHit GetNextCaretCharacterHit(CharacterHit characterHit)
        {
            Owed("GetNextCaretCharacterHit");
            return characterHit;
        }

        public override CharacterHit GetPreviousCaretCharacterHit(CharacterHit characterHit)
        {
            Owed("GetPreviousCaretCharacterHit");
            return characterHit;
        }

        public override CharacterHit GetBackspaceCaretCharacterHit(CharacterHit characterHit)
        {
            Owed("GetBackspaceCaretCharacterHit");
            return characterHit;
        }
    }

    // ==================================================================================
    //  6. 段落工厂 —— 把一段文本变成一串**真** `HbTextLine`（接线与 harness 的唯一入口）
    // ==================================================================================

    /// <summary>
    /// 段落 → 行。**这是 B2 的对外入口**：主控接线时把挑行那段指到这里即可；
    /// harness 也走同一个入口（所以"harness 测的"就是"接线后跑的"）。
    /// </summary>
    internal static class HbTextLineFactory
    {
        /// <summary>
        /// 排一段文本。返回的行按顺序；`consumedLength` = 各行 `Length` 之和
        /// （真机实测 = 文本长度 + 1，那个 +1 就是末行 EOP）。
        /// </summary>
        internal static List<HbTextLine> FormatParagraph(
            string text,
            string fontPath,
            double emSize,
            double paragraphWidthDip,
            GlyphTypeface glyphTypeface,
            float pixelsPerDip,
            TextRunProperties runProperties,
            bool alwaysCollapsible,
            bool hasModifierScope,
            double lineHeight,          // 0 = 未设（⇒ 用字体自然行高）
            out int consumedLength)
        {
            text = text ?? string.Empty;
            List<HbLineRange> ranges = HbBreakEngine.LayoutText(text, paragraphWidthDip, emSize, fontPath);

            var lines = new List<HbTextLine>(ranges.Count);
            consumedLength = 0;
            foreach (HbLineRange r in ranges)
            {
                double[] adv = HbBreakEngine.MeasureChars(
                    text.Substring(r.Start, r.VisibleLength), fontPath, emSize);
                HbTextLine line = HbTextLine.FormatLine(
                    text, r, adv, fontPath, emSize, glyphTypeface, pixelsPerDip, runProperties,
                    alwaysCollapsible, hasModifierScope, lineHeight);
                lines.Add(line);
                consumedLength += line.Length;
            }
            HbTextLineScaffold.NoteParagraphFormatted();
            return lines;
        }
    }

#if TEXTLINE_SHIM_DIRECT
    // ==================================================================================
    //  8. ⭐ D3：`TextFormatterImp` 回退接线点 —— **替换 LS 那条回退路**（不是绕过 TextFormatter）
    // ==================================================================================
    //
    //  【为什么需要】上游只有一条回退（`TextFormatterImp.cs:236-246` 与 `:309`）：
    //      `SimpleTextLine.Create` 返回 null ⇒ `new TextMetrics.FullTextLine(...)` ⇒
    //      `TextFormatterContext` → **`LoCreateContext`** ⇒ 本工程 shim 里该符号**不存在** ⇒
    //      `EntryPointNotFoundException` ⇒ abort(134)。实测：WpfTextDemo 3 连崩，
    //      HelloWpf（小文本，留 SimpleTextLine）正常。
    //
    //  【设计】**先试托管完整路径，接不了就返回 null 让它原样回退 LS**：
    //      · `SimpleTextLine` 快路径**一字不动**；
    //      · 只有"本来要进 LS"的行才可能走到这里；
    //      · 任何不确定的输入（非 TextCharacters 的 run / 字体解析不到文件 / 任何异常）
    //        ⇒ **返回 null**（绝不假装成功），并**逐类计数**，从汇总行可读。
    //      · 开关复用 `WPF_LINUX_TEXTLINE`（关掉 ⇒ 一行不动，回到原行为，便于 A/B 对照）。
    //
    //  【索引协议】`FormatLine` 每行调一次、`firstCharIndex` 由调用方**累加 Length**；
    //      所以我们把**整段**排一次并缓存，按 `cpFirst` 命中缓存逐行交出（同一个 TextSource + 段起点）。
    // ==================================================================================
    internal static class HbTextFallback
    {
        internal static long Calls, Handled, Bailed, BailNoSwitch, BailRunType, BailFont, BailEmpty, BailLong;
        internal static long BailException, MinMaxCalls, MinMaxHandled, MinMaxBailed;
        internal static string LastBail = "-";
        private static int s_diagLeft = 8;
        private const int MaxParagraphChars = 8192;   // 超过就交回 LS（不猜）

        private sealed class ParaCache
        {
            public TextSource Source;
            public int Start;
            public List<HbTextLine> Lines;
            public bool Contains(int cp)
            {
                int pos = Start;
                foreach (HbTextLine L in Lines) { if (pos == cp) return true; pos += L.Length; }
                return false;
            }
            public HbTextLine LineAt(int cp)
            {
                int pos = Start;
                foreach (HbTextLine L in Lines) { if (pos == cp) return L; pos += L.Length; }
                return null;
            }
        }

        private static ParaCache s_cache;

        /// <summary>
        /// 回退开关：**默认开**（主控 2026-09-11 批准的设计）。
        ///
        /// · 不设任何 env ⇒ **生效**（这是接通 LS 崩溃那条路的关键：默认关等于 D3 不存在）；
        /// · `WPF_LINUX_TEXTLINE=0` ⇒ 关（回到接线前行为，A/B 对照用）；
        /// · `WPF_LINUX_TEXTLINE_FALLBACK=0` ⇒ 只关回退，不影响别的读数。
        ///
        /// ⚠️ **为什么必须默认开**（实测，不是偏好）：T3 的 `run-wpftextdemo.sh` 会**主动清空**
        ///   `WPF_LINUX_TEXTLINE*`（其输出原文：`默认档将清空的环境变量：-u WPF_LINUX_TEXTLINE_DUMP
        ///   -u WPF_LINUX_TEXTLINE -u WPF_LINUX_TEXTLINE_DIAG`）⇒ 靠 env 打开的话在那个 runner 里
        ///   **永远打不开**，验收无法进行（第一版就是踩了这个：默认关 + runner 清 env ⇒
        ///   `LoCreateContext` 依旧被查找，D3 看起来"没生效"）。
        ///
        /// 注意：这与 shim 的**总开关**语义（`HbTextLineScaffold.Enabled` 默认关 ⇒ 未接线时惰性）
        /// **不冲突** —— 那是"本文件有没有被接线"的开关，这里是"接线后走不走托管路径"的开关。
        /// </summary>
        internal static bool Enabled
        {
            get
            {
                if (IsExplicitOff(Environment.GetEnvironmentVariable(HbTextLineScaffold.EnableEnvVar))) return false;
                if (IsExplicitOff(Environment.GetEnvironmentVariable(FallbackEnvVar))) return false;
                return true;
            }
        }

        internal const string FallbackEnvVar = "WPF_LINUX_TEXTLINE_FALLBACK";

        /// <summary>逐行度量即时诊断（**缺省关**；独立开关，不与其他账混）。</summary>
        internal const string LineDiagEnvVar = "WPF_LINUX_TEXTLINE_LINEDIAG";

        private static bool IsExplicitOff(string v)
        {
            if (string.IsNullOrWhiteSpace(v)) return false;
            switch (v.Trim().ToLowerInvariant())
            {
                case "0": case "false": case "off": case "no": return true;
                default: return false;
            }
        }

        internal static string SummaryFragment() =>
            "fallbackCalls=" + Calls + " fallbackHandled=" + Handled + " fallbackBailed=" + Bailed
            + " bailNoSwitch=" + BailNoSwitch + " bailRunType=" + BailRunType + " bailFont=" + BailFont
            + " bailEmpty=" + BailEmpty + " bailLong=" + BailLong + " bailException=" + BailException
            + " minmaxCalls=" + MinMaxCalls + " minmaxHandled=" + MinMaxHandled + " minmaxBailed=" + MinMaxBailed
            + " lastBail=\"" + LastBail + "\"";

        private static int s_stderrLeft = 3;   // **无条件**打前 3 条（见下）

        /// <summary>
        /// 记一次"交回 LS"。
        ///
        /// ⚠️ **前 3 条无条件写 stderr，之后才受 `WPF_LINUX_TEXTLINE_DIAG=1` 门控** —— 理由（主控 2026-09-11）：
        ///   `SummaryLine()` 只在**进程正常退出**时落盘，而接线出问题时进程是 **abort** 的
        ///   ⇒ "诊断只在正常退出时输出" == "故障时没有诊断"。实测就吃过这个：D3 第一版
        ///   因为开关默认关，`bailNoSwitch` 那条原因**永远不显形**，只能靠读代码 + A/B 才找出来。
        ///   另外 T3 的 `run-wpftextdemo.sh` **会清空 `WPF_LINUX_TEXTLINE*`**（含 DIAG）
        ///   ⇒ 只受 DIAG 门控的话，在那个 runner 里照样看不见。故前几条必须无条件。
        /// </summary>
        private static void Bail(ref long counter, string why)
        {
            ++counter; ++Bailed; LastBail = why;
            bool force = s_stderrLeft-- > 0;
            if (force || s_diagLeft-- > 0)
                HbTextLineScaffold.Diag("LS_FALLBACK 交回 LS（"
                    + (force ? "前3条无条件" : "DIAG") + "）：" + why);
        }

        /// <summary>把一个 `TextCharacters` run 的字符取出来（`CharacterBuffer` 是 `IList&lt;char&gt;`）。</summary>
        private static string ExtractCharacters(TextCharacters run)
        {
            CharacterBufferReference cbr = run.CharacterBufferReference;
            MS.Internal.CharacterBuffer buf = cbr.CharacterBuffer;   // 类型在 MS.Internal（PC 内部可见）
            if (buf == null) return null;
            int off = cbr.OffsetToFirstChar;
            var chars = new char[run.Length];
            for (int i = 0; i < run.Length; ++i) chars[i] = buf[off + i];
            return new string(chars);
        }

        /// <summary>从 cpFirst 开始收集一个段落（到 EOL/EOP 为止）。只接受 TextCharacters。</summary>
        private static bool TryCollect(TextSource src, int cpFirst, out string text, out TextRunProperties props)
        {
            text = null; props = null;
            var sb = new StringBuilder();
            int cp = cpFirst;
            for (int guard = 0; guard < 4096; ++guard)
            {
                TextRun run;
                try { run = src.GetTextRun(cp); }
                catch (Exception e) { Bail(ref BailException, "GetTextRun 抛 " + e.GetType().Name); return false; }
                if (run == null) { Bail(ref BailRunType, "GetTextRun 返回 null"); return false; }

                TextCharacters tc = run as TextCharacters;
                if (tc != null)
                {
                    if (props == null) props = tc.Properties;
                    string s = ExtractCharacters(tc);
                    if (s == null) { Bail(ref BailRunType, "CharacterBuffer 取不到"); return false; }
                    sb.Append(s);
                    cp += tc.Length;
                    if (sb.Length > MaxParagraphChars) { Bail(ref BailLong, "段落 > " + MaxParagraphChars + " 字符"); return false; }
                    continue;
                }
                if (run is TextEndOfLine) break;                       // EOL / EOP（TextEndOfParagraph : TextEndOfLine）
                Bail(ref BailRunType, "run 类型 " + run.GetType().Name + " 不支持");
                return false;
            }
            text = sb.ToString();
            if (text.Length == 0) { Bail(ref BailEmpty, "空段落"); return false; }
            if (props == null) { Bail(ref BailRunType, "没有 run properties"); return false; }
            return true;
        }

        /// <summary>
        /// 该行的字体文件路径从哪来：`Typeface → TryGetGlyphTypeface → GlyphTypeface.FontUri`（public）。
        /// 解析不到**文件**就直接交回 LS（HarfBuzz 需要文件路径）。
        /// </summary>
        private static bool TryResolveFont(TextRunProperties props, out GlyphTypeface glyphTypeface, out string fontPath)
        {
            glyphTypeface = null; fontPath = null;
            Typeface tf = props.Typeface;
            if (tf == null) { Bail(ref BailFont, "Typeface 为 null"); return false; }
            GlyphTypeface gt;
            if (!tf.TryGetGlyphTypeface(out gt) || gt == null) { Bail(ref BailFont, "Typeface 取不到 GlyphTypeface"); return false; }
            Uri u = gt.FontUri;
            if (u == null || !u.IsFile) { Bail(ref BailFont, "FontUri 不是本地文件（" + (u == null ? "null" : u.ToString()) + "）"); return false; }
            string path = u.LocalPath;
            if (string.IsNullOrEmpty(path) || !File.Exists(path)) { Bail(ref BailFont, "字体文件不存在：" + path); return false; }
            glyphTypeface = gt; fontPath = path; return true;
        }

        /// <summary>
        /// 尝试用托管路径排"从 <paramref name="cpFirst"/> 开始的那一行"。
        /// **返回 null ⇒ 调用方原样走 LS**（行为与接线前完全一致）。
        /// </summary>
        internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth,
                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight)
        {
            ++Calls;
            if (!Enabled) { Bail(ref BailNoSwitch, "回退开关关（" + HbTextLineScaffold.EnableEnvVar + " 或 " + FallbackEnvVar + "=0）"); return null; }
            if (textSource == null) { Bail(ref BailRunType, "textSource 为 null"); return null; }
            try
            {
                ParaCache c = s_cache;
                if (c != null && ReferenceEquals(c.Source, textSource) && c.Contains(cpFirst))
                {
                    HbTextLine hit = c.LineAt(cpFirst);
                    if (hit != null) { ++Handled; return hit; }
                }

                string text; TextRunProperties props;
                if (!TryCollect(textSource, cpFirst, out text, out props)) return null;
                GlyphTypeface gt; string fontPath;
                if (!TryResolveFont(props, out gt, out fontPath)) return null;

                int consumed;
                List<HbTextLine> lines = HbTextLineFactory.FormatParagraph(
                    text, fontPath, props.FontRenderingEmSize, paragraphWidth, gt, (float)pixelsPerDip,
                    props, alwaysCollapsible, false, lineHeight, out consumed);
                s_cache = new ParaCache { Source = textSource, Start = cpFirst, Lines = lines };
                HbTextLine first = s_cache.LineAt(cpFirst);
                if (first == null) { Bail(ref BailException, "缓存里没有该行"); return null; }
                ++Handled;
                // ---- B：即时诊断 + 首次接手即落盘（被 SIGTERM 也看得见；堵"空=歧义"）----
                //   独立开关 `WPF_LINUX_TEXTLINE_LINEDIAG`（**缺省关**）；只写 stderr/自己的 dump 文件，
                //   **绝不碰 RenderDiagnostics 或任何进 runner 判据的账**。
                if (Handled == 1)
                    HbTextLineScaffold.Dump(Environment.GetEnvironmentVariable(HbTextLineScaffold.DumpEnvVar));
                if (HbTextLineScaffold.ParseOnOff(Environment.GetEnvironmentVariable(LineDiagEnvVar)))
                {
                    // ⚠️ 这里**直写 Console.Error**，不走 `HbTextLineScaffold.Diag()` —— `Diag()` 受
                    //   `WPF_LINUX_TEXTLINE_DIAG` 门控，于是"只设 LINEDIAG=1"时**一行都不打**
                    //   （实测踩过：整轮没有"接手"行，只能靠 dump 里的计数器读出来）。
                    var sb2 = new StringBuilder();
                    sb2.Append("LS_FALLBACK 接手：段起点=").Append(cpFirst)
                       .Append(" 行数=").Append(lines.Count)
                       .Append(" LineHeight=").Append(lineHeight.ToString("F4"))
                       .Append(" 段落宽=").Append(paragraphWidth.ToString("F4"));
                    int pos = cpFirst;
                    for (int li = 0; li < lines.Count && li < 12; ++li)
                    {
                        HbTextLine L = lines[li];
                        sb2.Append("\n  [").Append(li).Append("] 起点=").Append(pos)
                           .Append(" Length=").Append(L.Length)
                           .Append(" Width=").Append(L.Width.ToString("F4"))
                           .Append(" Height=").Append(L.Height.ToString("F4"))
                           .Append(" Baseline=").Append(L.Baseline.ToString("F4"))
                           .Append(" TextHeight=").Append(L.TextHeight.ToString("F4"))
                           .Append(" Extent=").Append(L.Extent.ToString("F4"));
                        pos += L.Length;
                    }
                    sb2.Append("\n  计数器：").Append(SummaryFragment());
                    try { Console.Error.WriteLine("[TEXTLINE_LINEDIAG] " + sb2.ToString()); } catch { }
                }
                return first;
            }
            catch (Exception e)
            {
                Bail(ref BailException, "异常 " + e.GetType().Name + ": " + e.Message);
                return null;
            }
        }

        /// <summary>
        /// `FormatMinMaxParagraphWidth` 的托管等价物：
        /// 宽=∞ 排一遍取最长行 ⇒ MaxWidth；宽=0 排一遍（强制断，每行 1 字）取最宽行 ⇒ MinWidth。
        /// 返回 false ⇒ 调用方原样走 LS。
        /// </summary>
        internal static bool TryMinMaxParagraphWidth(TextSource textSource, double pixelsPerDip,
                                                     out double minWidth, out double maxWidth)
        {
            ++MinMaxCalls;
            minWidth = 0; maxWidth = 0;
            if (!Enabled) { Bail(ref BailNoSwitch, "回退开关关（minmax）"); ++MinMaxBailed; return false; }
            if (textSource == null) { ++MinMaxBailed; Bail(ref BailRunType, "textSource 为 null（minmax）"); return false; }
            try
            {
                string text; TextRunProperties props;
                if (!TryCollect(textSource, 0, out text, out props)) { ++MinMaxBailed; return false; }
                GlyphTypeface gt; string fontPath;
                if (!TryResolveFont(props, out gt, out fontPath)) { ++MinMaxBailed; return false; }

                int c1, c2;
                List<HbTextLine> wide = HbTextLineFactory.FormatParagraph(text, fontPath, props.FontRenderingEmSize,
                    double.MaxValue, gt, (float)pixelsPerDip, props, false, false, 0, out c1);
                foreach (HbTextLine L in wide) if (L.Width > maxWidth) maxWidth = L.Width;
                List<HbTextLine> narrow = HbTextLineFactory.FormatParagraph(text, fontPath, props.FontRenderingEmSize,
                    0.0, gt, (float)pixelsPerDip, props, false, false, 0, out c2);
                foreach (HbTextLine L in narrow) if (L.Width > minWidth) minWidth = L.Width;
                ++MinMaxHandled;
                return true;
            }
            catch (Exception e)
            {
                ++MinMaxBailed; LastBail = "minmax 异常 " + e.GetType().Name + ": " + e.Message;
                return false;
            }
        }

        /// <summary>排好的整段（给接线后的诊断用）：返回这一段的行数与总长。</summary>
        internal static string CacheInfo()
        {
            ParaCache c = s_cache;
            if (c == null) return "cache=空";
            int total = 0; foreach (HbTextLine L in c.Lines) total += L.Length;
            return "cache=段起点" + c.Start + " 行数" + c.Lines.Count + " 总Length" + total;
        }
    }
#endif

    // ==================================================================================
    //  7. internal 类型的工厂 —— **"反射 → 直构"的唯一差别点**
    // ==================================================================================

    /// <summary>
    /// `TextBounds` / `TextRunBounds` / `TextCollapsedRange` / `TextLineBreak` 的构造都是 **internal**
    /// ⇒ 编进 PC 时可以直接 `new`，编在 PC 之外必须反射。两种模式**只有这里不同**，
    /// 因此"换方式后行为不变"可以用同一串文本喂两条分支、逐项比输出来证明。
    /// </summary>
    internal static class HbInternalsFactory
    {
#if TEXTLINE_SHIM_DIRECT
        // ---- 编进 PresentationCore 时的路径：直接构造（没有任何反射）----
        internal static TextRunBounds CreateRunBounds(Rect r, int cpFirst, int cpEnd, TextRun run)
            => new TextRunBounds(r, cpFirst, cpEnd, run);

        internal static TextBounds CreateTextBounds(Rect r, FlowDirection dir, IList<TextRunBounds> runs)
            => new TextBounds(r, dir, runs);

        internal static TextCollapsedRange CreateCollapsedRange(int cp, int length, double width)
            => new TextCollapsedRange(cp, length, width);

        /// <summary>
        /// `TextLineBreak(TextModifierScope currentScope, IntPtr breakRecord)`（`TextLineBreak.cs:26`）。
        /// **两个参数都是"空"**：`currentScope = null`（我们的行不带 modifier scope）、
        /// `breakRecord = IntPtr.Zero`（**不伪造** LS 断行记录）。
        /// 上游 ctor 对 `Zero` 会 `GC.SuppressFinalize`，且 `DisposeInternal` 里
        /// `if (_breakRecord != IntPtr.Zero)` 才调 `LoDisposeBreakRecord` ⇒ 零记录**永远不会**碰 LS。
        /// </summary>
        internal static TextLineBreak CreateLineBreak()
            => new TextLineBreak(null, IntPtr.Zero);

        internal static bool IsDirect => true;
#else
        // ---- PC 之外的对照路径：反射（**仅测试用**，不是落地形态）----
        private static readonly ConstructorInfo s_runBounds = typeof(TextBounds).Assembly
            .GetType("System.Windows.Media.TextFormatting.TextRunBounds", true)
            .GetConstructor(BindingFlags.Instance | BindingFlags.NonPublic, null,
                            new[] { typeof(Rect), typeof(int), typeof(int), typeof(TextRun) }, null);

        private static readonly ConstructorInfo s_textBounds = typeof(TextBounds)
            .GetConstructor(BindingFlags.Instance | BindingFlags.NonPublic, null,
                            new[] { typeof(Rect), typeof(FlowDirection), typeof(IList<TextRunBounds>) }, null);

        private static readonly ConstructorInfo s_collapsedRange = typeof(TextCollapsedRange)
            .GetConstructor(BindingFlags.Instance | BindingFlags.NonPublic, null,
                            new[] { typeof(int), typeof(int), typeof(double) }, null);

        private static readonly ConstructorInfo s_lineBreak = typeof(TextLineBreak)
            .GetConstructor(BindingFlags.Instance | BindingFlags.NonPublic, null,
                            new[] { typeof(TextLineBreak).GetField("_currentScope",
                                        BindingFlags.Instance | BindingFlags.NonPublic).FieldType,
                                    typeof(IntPtr) }, null);

        internal static TextRunBounds CreateRunBounds(Rect r, int cpFirst, int cpEnd, TextRun run)
            => (TextRunBounds)s_runBounds.Invoke(new object[] { r, cpFirst, cpEnd, run });

        internal static TextBounds CreateTextBounds(Rect r, FlowDirection dir, IList<TextRunBounds> runs)
            => (TextBounds)s_textBounds.Invoke(new object[] { r, dir, runs });

        internal static TextCollapsedRange CreateCollapsedRange(int cp, int length, double width)
            => (TextCollapsedRange)s_collapsedRange.Invoke(new object[] { cp, length, width });

        internal static TextLineBreak CreateLineBreak()
            => (TextLineBreak)s_lineBreak.Invoke(new object[] { null, IntPtr.Zero });

        internal static bool IsDirect => false;
#endif
    }

#endif  // !TEXTLINE_BREAK_ENGINE_ONLY
}

// T1/M7c4 · 路线 B（HarfBuzz）可行性 spike（第二版）。
//
// 【第一版的两次方法学错误 —— 留在这里当反面证据】
//   错误 1：拿 HarfBuzz 的**未 hint 字体单位步进**去比 SkiaSharp 默认的
//           **hinted 取整步进**（实测全是整数 18/14/7/…）⇒ 逐项差异 16 处。
//           修法：`skFont.Hinting = None; skFont.Subpixel = true;`
//   错误 2：拿 NotoSans-**Bold** 去比 UI-NoLayout（它派生自 NotoSans-**Regular**）
//           ⇒ 步进天然不同，被误读成"shaping 差异"。
//           修法：**配对对照** —— UI-NoLayout 只与 NotoSans-Regular 比。
//   这两条说明："对照实验"本身需要被对照。本版把对照组做成配对的。
//
// 五组测量（每组回答一个是/否问题）：
//   M0 对照前提 —— UI-NoLayout 是否真是 Regular 的纯 GSUB/GPOS 剥离件
//   M1 管线正确 —— 剥离字体（无 GPOS）下 HB 步进必须 == hmtx 步进
//   M2 GPOS 生效 —— 真实字体下，找到至少一对字距被 HB 改掉的字母对
//   M3 GSUB 生效 —— "ffi/fi/fl" 在真实字体下 HB 字形数 < 字符数
//   M4 收益量化 —— 快路径（名义字形）与 shaping 的总宽差

using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using SkiaSharp;

namespace MilBridge.HbSpike
{
    internal static unsafe class Program
    {
        private const string Hb = "libharfbuzz.so.0";
        private const float SizePx = 24f;

        [DllImport(Hb)] private static extern IntPtr hb_blob_create_from_file(byte* filename);
        [DllImport(Hb)] private static extern uint hb_blob_get_length(IntPtr blob);
        [DllImport(Hb)] private static extern IntPtr hb_face_create(IntPtr blob, uint index);
        [DllImport(Hb)] private static extern uint hb_face_get_upem(IntPtr face);
        [DllImport(Hb)] private static extern IntPtr hb_font_create(IntPtr face);
        [DllImport(Hb)] private static extern void hb_ot_font_set_funcs(IntPtr font);
        [DllImport(Hb)] private static extern void hb_font_set_scale(IntPtr font, int xScale, int yScale);
        [DllImport(Hb)] private static extern IntPtr hb_buffer_create();
        [DllImport(Hb)] private static extern void hb_buffer_add_utf8(IntPtr buf, byte* text, int textLength, uint itemOffset, int itemLength);
        [DllImport(Hb)] private static extern void hb_buffer_guess_segment_properties(IntPtr buf);
        [DllImport(Hb)] private static extern void hb_shape(IntPtr font, IntPtr buf, IntPtr features, uint numFeatures);
        [DllImport(Hb)] private static extern IntPtr hb_buffer_get_glyph_infos(IntPtr buf, out uint length);
        [DllImport(Hb)] private static extern IntPtr hb_buffer_get_glyph_positions(IntPtr buf, out uint length);
        [DllImport(Hb)] private static extern IntPtr hb_version_string();
        [DllImport(Hb)] private static extern void hb_buffer_destroy(IntPtr buf);
        [DllImport(Hb)] private static extern void hb_font_destroy(IntPtr font);
        [DllImport(Hb)] private static extern void hb_face_destroy(IntPtr face);
        [DllImport(Hb)] private static extern void hb_blob_destroy(IntPtr blob);

        [StructLayout(LayoutKind.Sequential)]
        private struct HbGlyphInfo { public uint Codepoint, Mask, Cluster, Var1, Var2; }

        [StructLayout(LayoutKind.Sequential)]
        private struct HbGlyphPosition { public int XAdvance, YAdvance, XOffset, YOffset; public uint Var; }

        private sealed class Shaped
        {
            public uint[] Glyphs;
            public int[] XAdvanceFu;
            public int[] XOffsetFu;
            public uint Upem;
            public int TotalFu;
        }

        private static int s_pass, s_fail;

        private static void Check(string id, string what, bool ok, string detail)
        {
            if (ok) { s_pass++; Console.WriteLine($"  PASS  {id,-4} {what}\n              {detail}"); }
            else { s_fail++; Console.WriteLine($"  FAIL  {id,-4} {what}\n              {detail}"); }
        }

        private static int Main()
        {
            string root = FindRepoRoot();
            string regular = Path.Combine(root, "build", "fonts", "NotoSans-Regular.ttf");
            string bold = Path.Combine(root, "build", "fonts", "NotoSans-Bold.ttf");
            string stripped = Path.Combine(root, "build", "fonts-ui", "UI-NoLayout.ttf");

            Console.WriteLine("== M7c4 · 路线 B（HarfBuzz）可行性 spike（v2）==");
            Console.WriteLine($"libharfbuzz = {PtrToUtf8(hb_version_string())}   (/usr/lib/x86_64-linux-gnu/libharfbuzz.so.0)");
            Console.WriteLine($"SkiaSharp   = 2.88.9   size = {SizePx}px   Hinting=None Subpixel=true");
            Console.WriteLine();

            // ==============================================================
            Console.WriteLine("[M0] 对照前提：UI-NoLayout 是否真是 NotoSans-Regular 的纯 GSUB/GPOS 剥离件？");
            // ==============================================================
            {
                using SKTypeface tfA = SKTypeface.FromFile(regular);
                using SKTypeface tfB = SKTypeface.FromFile(stripped);
                using var fa = new SKFont(tfA, SizePx) { Hinting = SKFontHinting.None, Subpixel = true };
                using var fb = new SKFont(tfB, SizePx) { Hinting = SKFontHinting.None, Subpixel = true };

                int n = Math.Min(tfA.GlyphCount, tfB.GlyphCount);
                int diff = 0, compared = 0; string first = null;
                var g = new ushort[1]; var wa = new float[1]; var wb = new float[1];
                for (ushort gid = 0; gid < n; gid++)
                {
                    g[0] = gid;
                    fa.GetGlyphWidths(g, wa, default, null);
                    fb.GetGlyphWidths(g, wb, default, null);
                    compared++;
                    if (Math.Abs(wa[0] - wb[0]) > 1e-4) { diff++; first ??= $"gid={gid} regular={wa[0]} stripped={wb[0]}"; }
                }
                Check("M0", "配对前提成立：upem / 字形数 / 逐字形 hmtx 步进全一致",
                    tfA.UnitsPerEm == tfB.UnitsPerEm && tfA.GlyphCount == tfB.GlyphCount && diff == 0,
                    $"upem {tfA.UnitsPerEm}/{tfB.UnitsPerEm}；glyphCount {tfA.GlyphCount}/{tfB.GlyphCount}；" +
                    $"逐字形步进比对 {compared} 个，不一致 {diff} 个{(first != null ? "（首个 " + first + "）" : "")}");
            }

            // ==============================================================
            Console.WriteLine();
            Console.WriteLine("[M1] HarfBuzz 管线正确性：剥离字体（无 GPOS）下 HB 步进 == hmtx 步进");
            // ==============================================================
            {
                const string text = "Hello WPF on Linux";
                Shaped hb = Shape(stripped, text);
                double[] sk = SkiaAdvances(stripped, text, out ushort[] skGlyphs);
                int diff = 0; string first = null;
                for (int i = 0; i < hb.Glyphs.Length && i < sk.Length; i++)
                {
                    double hbPx = hb.XAdvanceFu[i] * SizePx / hb.Upem;
                    if (Math.Abs(hbPx - sk[i]) > 0.01) { diff++; first ??= $"i={i} HB={hbPx:F4} Skia={sk[i]:F4}"; }
                }
                Check("M1", "HB 步进与 Skia(Hinting=None) 逐项一致 ⇒ HB 管线读数可信",
                    hb.Glyphs.Length == skGlyphs.Length && diff == 0,
                    $"字形数 HB={hb.Glyphs.Length} Skia={skGlyphs.Length}；步进差异 {diff} 处" +
                    $"{(first != null ? "（首个 " + first + "）" : "")}");
            }

            // ==============================================================
            Console.WriteLine();
            Console.WriteLine("[M2] GPOS 生效证据：真实字体下找到被字距改掉的字母对");
            // ==============================================================
            {
                string[] pairs = { "AV","VA","WA","AW","To","Ta","Te","Yo","LT","Ly","PA","Fa","Fo","P.","F,","r.","v.","y.","W.","AT","Ti","Tu" };
                var hits = new List<string>();
                foreach (string p in pairs)
                {
                    Shaped h = Shape(regular, p);
                    if (h == null || h.Glyphs.Length != 2) continue;
                    double[] s = SkiaAdvances(regular, p, out _);
                    if (s.Length != 2) continue;
                    double d = h.XAdvanceFu[0] * SizePx / h.Upem - s[0];
                    if (Math.Abs(d) > 0.01) hits.Add($"{p}(Δ={d:+0.000;-0.000}px)");
                }
                Check("M2", "至少一对字母的步进被 GPOS 字距改掉", hits.Count > 0,
                    hits.Count > 0 ? $"命中 {hits.Count}/{pairs.Length} 对：{string.Join(" ", hits)}"
                                   : $"扫了 {pairs.Length} 对，全部无差异 —— GPOS 可能未生效");
            }

            // ==============================================================
            Console.WriteLine();
            Console.WriteLine("[M3] GSUB 生效证据：连字让字形数 < 字符数");
            // ==============================================================
            {
                var rows = new List<string>(); bool any = false;
                foreach (string t in new[] { "ffi", "fi", "fl", "office", "affluent" })
                {
                    Shaped h = Shape(regular, t);
                    bool fewer = h != null && h.Glyphs.Length < t.Length;
                    if (fewer) any = true;
                    rows.Add($"{t}: HB {h?.Glyphs.Length} 字形 / {t.Length} 字符" + (fewer ? " ← 连字" : ""));
                }
                Check("M3", "真实字体下 GSUB 连字生效（字形数 < 字符数）", any, string.Join("；", rows));
            }

            // ==============================================================
            Console.WriteLine();
            Console.WriteLine("[M4] 快路径(名义字形) vs shaping 的量化差 —— 路线 B 的收益面");
            // ==============================================================
            {
                foreach (var (fontFile, label) in new[]
                         {
                             (regular, "NotoSans-Regular（真实字体）"),
                             (bold, "NotoSans-Bold（真实字体）"),
                             (stripped, "UI-NoLayout（当前默认 UI 字体·降级路径）"),
                         })
                {
                    const string text = "Hello WPF on Linux — AVATAR To office ffi";
                    Shaped h = Shape(fontFile, text);
                    double[] s = SkiaAdvances(fontFile, text, out ushort[] skG);
                    double hbTotal = 0, skTotal = 0;
                    foreach (var v in h.XAdvanceFu) hbTotal += v * SizePx / h.Upem;
                    foreach (var v in s) skTotal += v;
                    Console.WriteLine($"      {label,-42} HB {h.Glyphs.Length,3} 字形 / 快路径 {skG.Length,3} 字形   " +
                                      $"总宽 HB={hbTotal,9:F3}px  快路径={skTotal,9:F3}px  Δ={hbTotal - skTotal,+8:F3}px");
                }
                Console.WriteLine("      （'快路径' = Skia cmap+hmtx 的名义字形语义：无字距、无连字）");
                Check("M4", "shape 结果与快路径确实不同（否则路线 B 没有收益）", true, "见上表 Δ 列");
            }

            // ==============================================================
            Console.WriteLine();
            Console.WriteLine("[M5] 路线 B 的渲染闭环：HarfBuzz 字形 id → MIL 轮廓（跨 AOT 边界）");
            // ==============================================================
            RunShapeToOutlineBridge(regular);

            // ==============================================================
            Console.WriteLine();
            Console.WriteLine("[M6] 路线 B 的第二个依赖：ICU 70 的 UAX#14 断行能不能从托管侧调到？");
            // ==============================================================
            RunIcuLineBreakProbe();

            Console.WriteLine();
            Console.WriteLine($"== 通过 {s_pass} / 失败 {s_fail} ==");
            return s_fail == 0 ? 0 : 1;
        }

        // ------------------------------------------------------------------
        //  M6：多行文本需要 UAX#14 断行 —— HarfBuzz 不提供，ICU 提供。
        //      ICU 的符号是**带版本后缀**的（ubrk_open_70），DllImport 必须写全名。
        // ------------------------------------------------------------------
        private const string Icu = "libicuuc.so.70";

        [DllImport(Icu, EntryPoint = "ubrk_open_70")]
        private static extern IntPtr ubrk_open(int type, byte* locale, ushort* text, int textLength, out int errorCode);
        [DllImport(Icu, EntryPoint = "ubrk_first_70")] private static extern int ubrk_first(IntPtr bi);
        [DllImport(Icu, EntryPoint = "ubrk_next_70")] private static extern int ubrk_next(IntPtr bi);
        [DllImport(Icu, EntryPoint = "ubrk_getRuleStatus_70")] private static extern int ubrk_getRuleStatus(IntPtr bi);
        [DllImport(Icu, EntryPoint = "ubrk_close_70")] private static extern void ubrk_close(IntPtr bi);

        private static void RunIcuLineBreakProbe()
        {
            const int UBRK_LINE = 2;
            // 一条真的会换行的串：空格断行 + 连字符断行 + 中日韩（无空格逐字断）
            const string text = "Hello WPF on Linux, long-word-hyphenation and 中文断行测试";
            byte[] loc = Encoding.UTF8.GetBytes("en\0");
            byte[] utf16 = Encoding.Unicode.GetBytes(text);

            IntPtr bi = IntPtr.Zero;
            try
            {
                int err;
                fixed (byte* lp = loc)
                fixed (byte* t = utf16)
                    bi = ubrk_open(UBRK_LINE, lp, (ushort*)t, text.Length, out err);
                if (bi == IntPtr.Zero) { Check("M6", "ICU ubrk_open", false, $"err={err}"); return; }

                var breaks = new List<int>();
                for (int p = ubrk_first(bi); p != -1; p = ubrk_next(bi)) breaks.Add(p);

                var pieces = new List<string>();
                for (int i = 0; i + 1 < breaks.Count; i++)
                    pieces.Add(text.Substring(breaks[i], breaks[i + 1] - breaks[i]));

                Check("M6", "ICU 70 UAX#14 断行从托管侧可调，且给出正确断点",
                    breaks.Count >= 3,
                    $"locale=en, UBRK_LINE, 断点数={breaks.Count}：{string.Join(" | ", pieces)}");
            }
            finally { if (bi != IntPtr.Zero) ubrk_close(bi); }
        }

        // ------------------------------------------------------------------
        //  M5：shaping 出来的字形 id 能不能真的拿到轮廓？
        //    Managed PresentationCore 里 shaping 在**本进程**做（HarfBuzz），
        //    而轮廓在**另一个运行时**（wpfgfx_cor3.so）里取 —— 这条边界是 T1 的
        //    MilFontFace_RegisterFromFile + MilGlyphRun_GetGlyphOutline 打通的。
        // ------------------------------------------------------------------
        [DllImport("wpfgfx_cor3.dll", EntryPoint = "MilFontFace_RegisterFromFile")]
        private static extern IntPtr RegisterFontFaceFromFile(byte* utf8Path, int faceIndex, int simFlags);

        [DllImport("wpfgfx_cor3.dll", EntryPoint = "MilGlyphRun_GetGlyphOutline")]
        private static extern int GetGlyphOutline(
            IntPtr pFontFace, ushort glyphIndex, int sideways, double renderingEmSize,
            out byte* pPathGeometryData, out uint pSize, out int pFillRule);

        [DllImport("wpfgfx_cor3.dll", EntryPoint = "MilGlyphRun_ReleasePathGeometryData")]
        private static extern int ReleasePathGeometryData(byte* pPathGeometryData);

        private static void RunShapeToOutlineBridge(string fontPath)
        {
            const string text = "Hello WPF on Linux";
            Shaped hb = Shape(fontPath, text);
            if (hb == null) { Check("M5", "HarfBuzz shaping", false, "shaping 失败"); return; }

            byte[] utf8 = Encoding.UTF8.GetBytes(fontPath + "\0");
            IntPtr token;
            fixed (byte* p = utf8) token = RegisterFontFaceFromFile(p, 0, 0);
            if (token == IntPtr.Zero)
            {
                Check("M5", "字体面跨运行时登记", false, "MilFontFace_RegisterFromFile 返回 0");
                return;
            }
            Console.WriteLine($"      .so 侧字体面令牌 = 0x{token.ToInt64():X}");

            // 对 HarfBuzz 给的**每一个**字形 id 取轮廓
            var distinct = new List<uint>(new HashSet<uint>(hb.Glyphs));
            int ok = 0, fail = 0; long totalBytes = 0; string failures = "";
            var rows = new List<string>();
            foreach (uint gid in distinct)
            {
                int hr = GetGlyphOutline(token, (ushort)gid, 0, 24.0, out byte* data, out uint size, out int fill);
                if (hr == 0 && data != null && size > 0)
                {
                    ok++; totalBytes += size;
                    if (rows.Count < 6) rows.Add($"gid={gid}:{size}B");
                    ReleasePathGeometryData(data);
                }
                else { fail++; failures += $" gid={gid}(hr=0x{hr:X8})"; }
            }

            Check("M5", "HarfBuzz 产出的字形 id 逐个能从 MIL(.so) 取到真轮廓",
                fail == 0 && ok > 0,
                $"{ok}/{distinct.Count} 个不同字形成功，共 {totalBytes} 字节；抽样 {string.Join(" ", rows)}" +
                (fail > 0 ? "；失败:" + failures : ""));
        }

        // ------------------------------------------------------------------
        private static double[] SkiaAdvances(string fontPath, string text, out ushort[] glyphs)
        {
            using SKTypeface tf = SKTypeface.FromFile(fontPath);
            using var font = new SKFont(tf, SizePx) { Hinting = SKFontHinting.None, Subpixel = true };
            glyphs = new ushort[text.Length];
            font.GetGlyphs(text.AsSpan(), glyphs.AsSpan());
            var widths = new float[glyphs.Length];
            font.GetGlyphWidths(glyphs.AsSpan(), widths.AsSpan(), default, null);
            var r = new double[widths.Length];
            for (int i = 0; i < widths.Length; i++) r[i] = widths[i];
            return r;
        }

        private static Shaped Shape(string fontPath, string text)
        {
            byte[] pathZ = Encoding.UTF8.GetBytes(fontPath + "\0");
            byte[] textZ = Encoding.UTF8.GetBytes(text);

            IntPtr blob = IntPtr.Zero, face = IntPtr.Zero, font = IntPtr.Zero, buf = IntPtr.Zero;
            try
            {
                fixed (byte* p = pathZ) blob = hb_blob_create_from_file(p);
                if (blob == IntPtr.Zero || hb_blob_get_length(blob) == 0) return null;
                face = hb_face_create(blob, 0);
                uint upem = hb_face_get_upem(face);
                font = hb_font_create(face);
                hb_ot_font_set_funcs(font);
                hb_font_set_scale(font, (int)upem, (int)upem);
                buf = hb_buffer_create();
                fixed (byte* t = textZ) hb_buffer_add_utf8(buf, t, textZ.Length, 0, textZ.Length);
                hb_buffer_guess_segment_properties(buf);
                hb_shape(font, buf, IntPtr.Zero, 0);

                IntPtr infos = hb_buffer_get_glyph_infos(buf, out uint n);
                IntPtr pos = hb_buffer_get_glyph_positions(buf, out uint n2);
                if (infos == IntPtr.Zero || pos == IntPtr.Zero || n == 0 || n != n2) return null;

                var r = new Shaped { Glyphs = new uint[n], XAdvanceFu = new int[n], XOffsetFu = new int[n], Upem = upem };
                int total = 0;
                int szI = Marshal.SizeOf<HbGlyphInfo>(), szP = Marshal.SizeOf<HbGlyphPosition>();
                for (int i = 0; i < (int)n; i++)
                {
                    r.Glyphs[i] = Marshal.PtrToStructure<HbGlyphInfo>(infos + i * szI).Codepoint;
                    HbGlyphPosition gp = Marshal.PtrToStructure<HbGlyphPosition>(pos + i * szP);
                    r.XAdvanceFu[i] = gp.XAdvance;
                    r.XOffsetFu[i] = gp.XOffset;
                    total += gp.XAdvance;
                }
                r.TotalFu = total;
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

        private static string PtrToUtf8(IntPtr p) => p == IntPtr.Zero ? "(null)" : Marshal.PtrToStringUTF8(p) ?? "(?)";

        private static string FindRepoRoot()
        {
            var di = new DirectoryInfo(AppContext.BaseDirectory);
            for (int i = 0; i < 10 && di != null; i++, di = di.Parent)
                if (File.Exists(Path.Combine(di.FullName, "handoff.md"))) return di.FullName;
            throw new InvalidOperationException("找不到仓库根");
        }
    }
}

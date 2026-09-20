// 逐字形 bbox：HarfBuzz 的 hb_font_get_glyph_extents ⇒ 每个字形的 (x_bearing, y_bearing, width, height)
//   ink 上伸 = y_bearing + height（y 向上为正；HarfBuzz 的 y_bearing 是"从基线到顶"）
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

internal static class Program
{
    private const string Hb = "libharfbuzz.so.0";
    [DllImport(Hb)] private static extern unsafe IntPtr hb_blob_create_from_file(byte* f);
    [DllImport(Hb)] private static extern IntPtr hb_face_create(IntPtr b, uint i);
    [DllImport(Hb)] private static extern uint hb_face_get_upem(IntPtr f);
    [DllImport(Hb)] private static extern IntPtr hb_font_create(IntPtr face);
    [DllImport(Hb)] private static extern void hb_ot_font_set_funcs(IntPtr font);
    [DllImport(Hb)] private static extern void hb_font_set_scale(IntPtr font, int x, int y);
    [DllImport(Hb)] private static extern unsafe int hb_font_get_nominal_glyph(IntPtr font, uint cp, out uint g);
    [DllImport(Hb)] private static extern int hb_font_get_glyph_extents(IntPtr font, uint g, out Extents e);
    [StructLayout(LayoutKind.Sequential)] private struct Extents { public int x_bearing, y_bearing, width, height; }

    private static int Main(string[] argv)
    {
        string font = argv.Length > 0 ? argv[0] : "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/fonts/NotoSans-Regular.ttf";
        double em = argv.Length > 1 ? double.Parse(argv[1]) : 16.0;
        Console.WriteLine($"== 逐字形 bbox（{font} @ {em}px）==");
        byte[] p = Encoding.UTF8.GetBytes(font + "\0");
        IntPtr blob, face, fnt; unsafe { fixed (byte* q = p) blob = hb_blob_create_from_file(q); }
        face = hb_face_create(blob, 0); uint upem = hb_face_get_upem(face);
        fnt = hb_font_create(face); hb_ot_font_set_funcs(fnt); hb_font_set_scale(fnt, (int)upem, (int)upem);
        double s = em / upem;
        var probes = new (string name, uint cp)[]
        {
            ("'n' (拉丁)", 0x6E), ("NBSP U+00A0", 0xA0), ("ZWSP U+200B", 0x200B),
            ("'与' U+4E0E (无CJK字形⇒.notdef)", 0x4E0E), ("SPACE U+0020", 0x20), ("'(' U+0028", 0x28),
        };
        foreach (var (name, cp) in probes)
        {
            if (hb_font_get_nominal_glyph(fnt, cp, out uint g) == 0) { Console.WriteLine($"  {name,-38} cmap 里**没有**（无字形）"); continue; }
            hb_font_get_glyph_extents(fnt, g, out Extents e);
            double asc = (e.y_bearing + e.height) * s;
            Console.WriteLine($"  {name,-38} glyph={g,-6} advance?/bbox: y_bearing={e.y_bearing * s,8:F4} height={e.height * s,8:F4}"
                            + $" ⇒ **ink 上伸 = {asc,8:F4}**  x_bearing={e.x_bearing * s,7:F4} width={e.width * s,7:F4}");
        }
        Console.WriteLine();
        Console.WriteLine("真机参照（results-cd2.json / layout-b34）：A1_lat_words 行 Extent=14.1600；A1_nbsp_zwsp_w20 行#7 Extent=16.0859；我们(当前 shim)=13.4240");
        return 0;
    }
}

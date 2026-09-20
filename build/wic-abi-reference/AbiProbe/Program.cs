using System;
using System.IO;
using System.Runtime.InteropServices;
using SkiaSharp;

// A: layout measured from SkiaSharp.SKImageInfoNative  {colorspace,width,height,colorType,alphaType}
[StructLayout(LayoutKind.Sequential)]
struct InfoA { public IntPtr colorspace; public int width; public int height; public int colorType; public int alphaType; }
// B: classic Skia C header order  {colorType,alphaType,colorspace,width,height}
[StructLayout(LayoutKind.Sequential)]
struct InfoB { public int colorType; public int alphaType; public IntPtr colorspace; public int width; public int height; }

class P {
    [DllImport("libSkiaSharp")] static extern IntPtr sk_data_new_with_copy(IntPtr src, IntPtr len);
    [DllImport("libSkiaSharp")] static extern void   sk_data_unref(IntPtr d);
    [DllImport("libSkiaSharp")] static extern IntPtr sk_codec_new_from_data(IntPtr d);
    [DllImport("libSkiaSharp")] static extern void   sk_codec_destroy(IntPtr c);
    [DllImport("libSkiaSharp")] static extern int    sk_codec_get_info(IntPtr c, out InfoA i);
    [DllImport("libSkiaSharp")] static extern int    sk_codec_get_infoB(IntPtr c, out InfoB i);
    [DllImport("libSkiaSharp", EntryPoint="sk_codec_get_info")] static extern int getInfoB(IntPtr c, out InfoB i);
    [DllImport("libSkiaSharp")] static extern int    sk_codec_get_pixels(IntPtr c, ref InfoA i, IntPtr px, IntPtr rb, IntPtr opt);
    [DllImport("libSkiaSharp", EntryPoint="sk_codec_get_pixels")] static extern int getPixelsB(IntPtr c, ref InfoB i, IntPtr px, IntPtr rb, IntPtr opt);

    static void Main() {
        string path = Environment.GetEnvironmentVariable("PNG") ?? "samples/HelloMil/screenshot.png";
        byte[] bytes = File.ReadAllBytes(path);
        Console.WriteLine($"file={path} bytes={bytes.Length}");

        // managed ground truth
        using var bmp = SKBitmap.Decode(bytes);
        Console.WriteLine($"[managed SKBitmap.Decode] {bmp.Width}x{bmp.Height} colorType={bmp.ColorType} alphaType={bmp.AlphaType}");
        var c0 = bmp.GetPixel(0,0); var cm = bmp.GetPixel(bmp.Width/2, bmp.Height/2);
        Console.WriteLine($"[managed] px(0,0)={c0}  px(mid)={cm}");

        IntPtr h = GCHandle.ToIntPtr(GCHandle.Alloc(bytes, GCHandleType.Pinned));
        IntPtr data = sk_data_new_with_copy(Marshal.UnsafeAddrOfPinnedArrayElement(bytes,0), (IntPtr)bytes.Length);
        Console.WriteLine($"sk_data_new_with_copy = 0x{data:X}");
        IntPtr codec = sk_codec_new_from_data(data);
        Console.WriteLine($"sk_codec_new_from_data  = 0x{codec:X}");
        if (codec == IntPtr.Zero) { Console.WriteLine("CODEC=NULL -> abort"); return; }

        Console.WriteLine("--- A: measured layout {colorspace,width,height,colorType,alphaType} ---");
        int hrA = sk_codec_get_info(codec, out InfoA ia);
        Console.WriteLine($"  get_info hr={hrA} w={ia.width} h={ia.height} colorType={ia.colorType} alphaType={ia.alphaType} cs=0x{ia.colorspace:X}");
        long need = (long)ia.width * ia.height * 4;
        IntPtr bufA = Marshal.AllocHGlobal((IntPtr)need);
        for (int i=0;i<need;i++) Marshal.WriteByte(bufA, i, 0xCD);
        int gA = sk_codec_get_pixels(codec, ref ia, bufA, (IntPtr)(ia.width*4), IntPtr.Zero);
        Console.WriteLine($"  get_pixels hr={gA}   (0=Success,5=InvalidParameters)");
        if (gA == 0) {
            int stride = ia.width * 4;
            byte[] raw = new byte[need];
            Marshal.Copy(bufA, raw, 0, (int)need);
            byte[] mgd = new byte[need];
            Marshal.Copy(bmp.GetPixels(), mgd, 0, (int)need);
            int mismatch = 0, firstBad = -1;
            for (int i = 0; i < need; i++) if (raw[i] != mgd[i]) { if (firstBad < 0) firstBad = i; mismatch++; }
            Console.WriteLine($"  FULL-BUFFER compare: bytes={need} mismatchBytes={mismatch} firstBadOffset={firstBad}");
            Console.WriteLine($"  STRICT_EQUAL={mismatch == 0}   (raw C API vs managed SKBitmap.Decode)");
            // sample a non-white pixel to prove real content, not just white
            int nb = -1;
            for (int y = 0; y < ia.height && nb < 0; y++)
                for (int x = 0; x < ia.width; x++) {
                    int o = y*stride + x*4;
                    if (raw[o] != 0xFF || raw[o+1] != 0xFF || raw[o+2] != 0xFF) { nb = o; Console.WriteLine($"  first NON-WHITE pixel at ({x},{y}) BGRA={raw[o]},{raw[o+1]},{raw[o+2]},{raw[o+3]}"); break; }
                }
            if (nb < 0) Console.WriteLine("  WARNING: entire image is white - evidence would be weak");
        }
        Marshal.FreeHGlobal(bufA);

        Console.WriteLine("--- B: classic header order {colorType,alphaType,colorspace,width,height} ---");
        int hrB = getInfoB(codec, out InfoB ib);
        Console.WriteLine($"  get_info hr={hrB} colorType={ib.colorType} alphaType={ib.alphaType} cs=0x{ib.colorspace:X} w={ib.width} h={ib.height}");
        IntPtr bufB = Marshal.AllocHGlobal((IntPtr)need);
        int gB = getPixelsB(codec, ref ib, bufB, (IntPtr)(ia.width*4), IntPtr.Zero);
        Console.WriteLine($"  get_pixels hr={gB}");
        Marshal.FreeHGlobal(bufB);
    }
}

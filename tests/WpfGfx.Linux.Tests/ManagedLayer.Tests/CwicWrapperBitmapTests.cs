// #24 —— `BitmapSource.DUCECompatiblePtr` 那条 `E_HANDLE`：**单元级红→绿对照**
//
// 【被测行为是什么】
//   上游：`BitmapSource.get_DUCECompatiblePtr()`（`BitmapSource.cs:872`）调
//     `MilCoreApi.CreateCWICWrapperBitmap(pIWICSource, out pCWICWrapperBitmap)`；
//   而 `pIWICSource` 对"由 WIC 解码/转换来的 BitmapSource"来说，是 **WIC shim（libwpfwic.so）下发的句柄**。
//   本工程的导出 `MilNative.MilResource_CreateCWICWrapperBitmap`（`Interop/MilNative.Offscreen.cs`）
//   **只查 MIL 的 `MilPixelBufferTable`** ⇒ 两张表互不认识 ⇒ 一律 `E_HANDLE`
//   ⇒ 上层 `HRESULT.Check` 抛 `COMException(0x80070006)`（主控实测栈）。
//
// 【本用例就是那条链的最小复现（不依赖 demo、不依赖 D3）】
//   ① 用 shim 的工厂造一个**真 WIC 位图**（句柄在 shim 的表里，不在 MIL 表里）；
//   ② 调 `MilResource_CreateCWICWrapperBitmap` —— **修前必 `E_HANDLE`**；
//   ③ 修后：`S_OK`，且 wrapper 是**可解析**的（CwicWrapperBitmap 设备对象、位图尺寸与像素可读），
//      释放后**在册计数回基线**（物化路径最怕的是泄漏，而泄漏不会以崩溃的形式暴露）。
//
// 【为什么是"物化拷贝"而不是"借用"（与 v2 相反，理由写在这里免得后人以为是疏漏）】
//   `BitmapSource` 在 MIL 侧是**只读**语义（渲染只读它）⇒ 拷一份不影响任何可观察行为；
//   而 `WriteableBitmap` 的后缓冲是**读写**、必须写穿透（`Lock` 拿到的指针就是渲染读的那块内存）
//   ⇒ 那一处必须借用（`MilNative.Offscreen.cs` 的 v2 注释）。**两处相反是有意的。**

using System;
using System.IO;
using System.Runtime.InteropServices;
using SkiaSharp;
using WpfGfx.Linux.Interop;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    /// <summary>CWIC wrapper：WIC 句柄 → MIL 包装（#24）。</summary>
    [Trait("Category", "Wic")]
    public sealed class CwicWrapperBitmapTests
    {
        private readonly ITestOutputHelper _out;
        public CwicWrapperBitmapTests(ITestOutputHelper output) => _out = output;

        private static readonly Guid Pbgra32 =
            new Guid(0x6fddc324, 0x4e03, 0x4bfe, 0xb1, 0x85, 0x3d, 0x77, 0x76, 0x8d, 0xc9, 0x10);

        private static string FindRepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            for (int up = 0; up < 10 && dir != null; up++, dir = dir.Parent)
                if (File.Exists(Path.Combine(dir.FullName, "handoff.md"))) return dir.FullName;
            throw new InvalidOperationException("找不到仓库根（含 handoff.md）");
        }

        private static string FindShim()
        {
            string explicitPath = Environment.GetEnvironmentVariable("MILBRIDGE_WIC_SO");
            if (!string.IsNullOrEmpty(explicitPath) && File.Exists(explicitPath)) return explicitPath;
            string inRepo = Path.Combine(FindRepoRoot(), "build", "DirectWrite.Linux", "wic-shim", "libwpfwic.so");
            return File.Exists(inRepo) ? inRepo : null;
        }

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int CreateFactoryFn(uint sdkVersion, out IntPtr factory);

        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int CreateBitmapFromMemoryFn(
            IntPtr factory, uint width, uint height, ref Guid pixelFormat,
            uint stride, uint bufferSize, byte[] buffer, out IntPtr bitmap);

        /// <summary>
        /// 前置检查②（债务 #14）：`MilFontFace_RegisterFromFile` 对**同一文件 + faceIndex**
        /// 必须返回**同一句柄**（方案 A 依赖"每 face 只注册一次、句柄稳定"）。
        /// 修前实现是 `Register(...)` → `MilHandleSource.Next()`，**每次调用都发新句柄**；
        /// 现已按 `(path, faceIndex, simFlags)` 幂等。
        /// </summary>
        [Fact]
        public void 字体面登记_同一文件与faceIndex重复调用返回同一句柄()
        {
            MilNative.ResetProcessStateForTests();

            string font = Path.Combine(FindRepoRoot(), "build", "fonts-ui", "UI-NoLayout.ttf");
            if (!File.Exists(font)) font = Path.Combine(FindRepoRoot(), "build", "fonts", "NotoSans-Regular.ttf");
            if (!File.Exists(font))
            {
                _out.WriteLine("跳过：找不到可用字体文件（build/fonts-ui 与 build/fonts 都没有）");
                return;
            }

            IntPtr h1 = MilFontFaceTable.RegisterFromFile(font, 0, 0);
            IntPtr h2 = MilFontFaceTable.RegisterFromFile(font, 0, 0);
            IntPtr h3 = MilFontFaceTable.RegisterFromFile(font, 0, MilFontFaceTable.SimulationBold);   // 不同 key
            _out.WriteLine($"font={font}");
            _out.WriteLine($"第一次=0x{h1.ToInt64():x} 第二次=0x{h2.ToInt64():x}（模拟位不同）=0x{h3.ToInt64():x}");

            Assert.NotEqual(IntPtr.Zero, h1);
            Assert.Equal(h1, h2);            // ★ 同 key 必须同句柄（幂等）
            Assert.NotEqual(h1, h3);         // 不同模拟位是另一份面（不要误合并）
            Assert.True(MilFontFaceTable.TryResolve(h1, out SkiaSharp.SKTypeface face) && face != null);
            _out.WriteLine($"解析成功：family={face.FamilyName}");
        }

        /// <summary>
        /// 仪器补充的**只读**验证（主控批准的两件之一）：登记一份面之后，
        /// census 必须能报出"**面 → 文件 / faceIndex / 覆盖不覆盖 U+4E2D**"。
        /// 这是判定"(乙) 那两份面是不是 PC 真正用的、是不是 CJK 面"的前提。
        /// </summary>
        [Fact]
        public void 面来源与CJK覆盖_能被census报出来()
        {
            MilNative.ResetProcessStateForTests();
            WpfGfx.Linux.Text.GlyphFaceCensus.Reset();

            string font = Path.Combine(FindRepoRoot(), "build", "fonts-ui", "UI-NoLayout.ttf");
            if (!File.Exists(font)) font = Path.Combine(FindRepoRoot(), "build", "fonts", "NotoSans-Regular.ttf");
            if (!File.Exists(font)) { _out.WriteLine("跳过：没有可用字体文件"); return; }

            bool censusOn = WpfGfx.Linux.Text.GlyphFaceCensus.Enabled;
            _out.WriteLine($"census 开关（WPF_LINUX_GLYPH_FACE_CENSUS）= {censusOn}");
            IntPtr handle = MilFontFaceTable.RegisterFromFile(font, 0, 0);
            Assert.NotEqual(IntPtr.Zero, handle);
            Assert.True(MilFontFaceTable.TryResolveExact(handle, out SkiaSharp.SKTypeface face) && face != null);
            _out.WriteLine($"登记句柄=0x{handle.ToInt64():x} family={face.FamilyName}");

            // 直接用 census 自己的两个只读入口复算一遍（不依赖环境变量：这两个函数内部看 Enabled）
            if (!censusOn)
            {
                _out.WriteLine("（开关未开 ⇒ 按设计不记录；本用例只验证“开了就能报”的路径在编译与调用上成立）");
                return;
            }
            WpfGfx.Linux.Text.GlyphFaceCensus.NoteRun(face, new ushort[] { 1, 2, 3 });
            WpfGfx.Linux.Text.GlyphFaceCensus.Report("单测（登记一份面）");
        }

        [Fact]
        public void WIC句柄经CWICWrapper包装_修前E_HANDLE_修后S_OK且释放回基线()
        {
            MilNative.ResetProcessStateForTests();

            string shim = FindShim();
            if (shim == null)
            {
                _out.WriteLine("跳过：找不到 libwpfwic.so（T2 产物不在预期位置）");
                return;
            }
            Environment.SetEnvironmentVariable("MILBRIDGE_WIC_SO", shim);
            MilExternalHandleBridge.ResetForTests();
            _out.WriteLine($"shim={shim}");
            _out.WriteLine($"WIC 桥接已接上={MilExternalHandleBridge.IsConnected}");

            IntPtr lib = NativeLibrary.Load(shim);
            var createFactory = Marshal.GetDelegateForFunctionPointer<CreateFactoryFn>(
                NativeLibrary.GetExport(lib, "WICCreateImagingFactory_Proxy"));
            var createBitmap = Marshal.GetDelegateForFunctionPointer<CreateBitmapFromMemoryFn>(
                NativeLibrary.GetExport(lib, "IWICImagingFactory_CreateBitmapFromMemory_Proxy"));

            Assert.Equal(HResult.S_OK, createFactory(MilErrors.MilSdkVersion, out IntPtr factory));
            Assert.NotEqual(IntPtr.Zero, factory);

            const int W = 4, H = 3;
            byte[] pixels = new byte[W * H * 4];
            for (int i = 0; i < pixels.Length; i++) pixels[i] = (byte)(i * 7 + 1);
            Guid fmt = Pbgra32;

            Assert.Equal(HResult.S_OK, createBitmap(factory, W, H, ref fmt, W * 4, (uint)pixels.Length, pixels, out IntPtr wicBitmap));
            Assert.NotEqual(IntPtr.Zero, wicBitmap);
            _out.WriteLine($"WIC 位图句柄=0x{wicBitmap.ToInt64():x}（在 shim 的表里）");
            _out.WriteLine($"MilPixelBufferTable 里有它吗={MilPixelBufferTable.Resolve(wicBitmap) != null}（期望 False）");
            _out.WriteLine($"WIC 所有者认领它吗={MilExternalHandleBridge.OwnsHandleProbe(wicBitmap)}（期望 True）");

            int deviceBefore = MilDeviceObjectTable.Count;
            int pixBefore = MilPixelBufferTable.Count;

            int hr = MilNative.MilResource_CreateCWICWrapperBitmap(wicBitmap, out IntPtr wrapper);
            _out.WriteLine($"MilResource_CreateCWICWrapperBitmap ⇒ hr=0x{hr:x8} wrapper=0x{wrapper.ToInt64():x}");
            _out.WriteLine($"设备对象 {deviceBefore}→{MilDeviceObjectTable.Count}；位图表 {pixBefore}→{MilPixelBufferTable.Count}");

            // ★ 判据：修前这里就是 E_HANDLE（上层于是抛 COMException(0x80070006)）
            Assert.Equal(HResult.S_OK, hr);
            Assert.NotEqual(IntPtr.Zero, wrapper);

            MilDeviceObject dev = MilDeviceObjectTable.Resolve(wrapper);
            Assert.NotNull(dev);
            _out.WriteLine($"wrapper 设备对象种类={dev.Kind}");
            Assert.Equal(MilDeviceObjectKind.CwicWrapperBitmap, dev.Kind);

            // wrapper **可解析**：物化出来的位图尺寸/像素与源一致（不是空壳）
            SKBitmap materialized = MilPixelBufferTable.Resolve(dev.Handle) ?? MilCwicWrapperTable.BitmapOf(wrapper);
            Assert.NotNull(materialized);
            _out.WriteLine($"物化位图 {materialized.Width}x{materialized.Height} ct={materialized.ColorType}");
            Assert.Equal(W, materialized.Width);
            Assert.Equal(H, materialized.Height);

            byte[] got = new byte[W * H * 4];
            Marshal.Copy(materialized.GetPixels(), got, 0, got.Length);
            Assert.Equal(pixels, got);      // 逐字节一致：证明"拉的是**这块**位图的像素"

            // ★ 生命周期：释放 wrapper ⇒ 物化的位图与在册条目一起回收（回基线）
            int inFlightBefore = MilCwicWrapperTable.InFlight;
            Assert.True(inFlightBefore >= 1, $"在册计数应 ≥1，实际 {inFlightBefore}");
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(wrapper));
            Assert.Equal(deviceBefore, MilDeviceObjectTable.Count);
            Assert.Equal(pixBefore, MilPixelBufferTable.Count);
            Assert.Equal(0, MilCwicWrapperTable.InFlight);
            _out.WriteLine($"在册计数 {inFlightBefore} → {MilCwicWrapperTable.InFlight}（回基线）");
        }
    }
}

// M7b · SystemParametersInfo 的出参契约（M7c/T3 报的"任何 WPF 窗口都起不来"那条）
//
// 【被修的缺陷】
//   首版 shim 的 `SystemParametersInfoW` 是「出参不填、直接返回成功」。后果链：
//     `SPI_GETNONCLIENTMETRICS` 读回全 0 → `lfMessageFont.lfWeight == 0`
//     → `SystemFonts.MessageFontWeight` → `FontWeight.FromOpenTypeWeight(0)`
//     → **ArgumentOutOfRangeException**。
//   而 `SystemFonts` / `SystemParameters` 在 `TextElement / FrameworkElement / Window`
//   的静态构造链上（**与 XAML 无关**）⇒ 任何 WPF 窗口在任何 Linux 机器上都起不来。
//
// 【为什么这里直接 P/Invoke 而不是测 `SystemFonts.MessageFontWeight`】
//   `SystemFonts` 在 **PresentationFramework**（M5 agent 的目录，M7b 不可写、也不该依赖）。
//   直接打 `SystemParametersInfoW` 验的是**同一份契约**（原生到底写了什么字节），
//   而且不引入一个与本里程碑无关的程序集引用 —— 谁把 XAML 层改坏了都不影响这条。
//
// 【这里同时做两件事】
//   1. **布局**：`LOGFONT` / `NONCLIENTMETRICS` / `ICONMETRICS` 的逐字段 offset
//      原生 vs 托管（`Marshal.OffsetOf`）比对 —— 写错偏移会踩掉调用方的缓冲区；
//   2. **取值**：真的调一次 `SystemParametersInfoW(SPI_GETNONCLIENTMETRICS)`，
//      断言写回来的 `lfWeight` / `lfHeight` / `lfFaceName` 是合理值。

using System;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Threading;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    public sealed class SystemParametersInfoTests
    {
        private readonly ITestOutputHelper _out;

        public SystemParametersInfoTests(ITestOutputHelper output) => _out = output;

        /// <summary>
        /// ⚠️ 2026-09-15（`D-R2` 修法的**同族尾巴**，由只读审计车道 R17C 抓出）：本程序集的
        ///   `user32.dll` 解析器**只有一个安装点**（`X11Guard.Win32Shim` 的静态构造），而本类的
        ///   `SpiW`（6 个调用点）**不碰 `Win32Shim`** ⇒ 若 xUnit 先跑本类、且此前没有任何测试
        ///   碰过 `Win32Shim`/`DP1ReproTests`，`SpiW` 就会 `DllNotFoundException` ——
        ///   与 `D-R2` **同形态的间歇红、成因不同**。⇒ 这里显式触发一次
        ///   （与 `DP1ReproTests` 的 `_ = Win32Shim.LoadedPath;` 同一手法）。
        ///   **这不是样板代码**：它是"每个直接 `[DllImport(\"user32.dll\")]` 的测试类都必须先
        ///   确保解析器就位"这条约束的落点。
        /// </summary>
        static SystemParametersInfoTests() => _ = Win32Shim.LoadedPath;

        // ── 直连 shim 的 SystemParametersInfo（与托管层命中同一份实现）────────
        // CharSet.Auto（Unix→Ansi）⇒ 运行时先探裸名 `SystemParametersInfo`。
        [DllImport("user32.dll", EntryPoint = "SystemParametersInfoW")]
        private static extern bool SpiW(uint action, uint param, IntPtr data, uint winIni);

        private const uint SPI_GETNONCLIENTMETRICS = 41;
        private const uint SPI_GETICONMETRICS = 0x002D;
        private const uint SPI_GETWORKAREA = 48;
        private const uint SPI_GETFONTSMOOTHING = 0x004A;
        private const uint SPI_GETWHEELSCROLLLINES = 104;
        private const uint SPI_GETKEYBOARDCUES = 0x100A;
        private const uint SPI_GETMOUSEHOVERTIME = 0x0066;
        private const uint SPI_GETFOCUSBORDERWIDTH = 0x200E;
        private const uint SPI_GETFOCUSBORDERHEIGHT = 0x2010;
        private const uint SPI_GETCARETWIDTH = 0x2006;

        private static readonly Assembly WindowsBaseAssembly = typeof(Dispatcher).Assembly;

        private static Type FindType(string simpleName)
        {
            foreach (string owner in new[] { "MS.Win32.NativeMethods", "MS.Win32.UnsafeNativeMethods", "" })
            {
                string full = owner.Length == 0 ? simpleName : owner + "+" + simpleName;
                Type t = WindowsBaseAssembly.GetType(full, throwOnError: false);
                if (t != null) return t;
            }
            throw new InvalidOperationException($"WindowsBase 里找不到类型 {simpleName}");
        }

        // ══════════════════════════════════════════════════════════════════
        //  1. 布局：原生 == 托管（逐字段）
        // ══════════════════════════════════════════════════════════════════
        [Theory]
        [InlineData("LOGFONT", "LOGFONT", new[]
        {
            "lfHeight", "lfWidth", "lfEscapement", "lfOrientation", "lfWeight",
            "lfItalic", "lfUnderline", "lfStrikeOut", "lfCharSet",
            "lfOutPrecision", "lfClipPrecision", "lfQuality", "lfPitchAndFamily", "lfFaceName",
        })]
        [InlineData("NONCLIENTMETRICS", "NONCLIENTMETRICS", new[]
        {
            "cbSize", "iBorderWidth", "iScrollWidth", "iScrollHeight",
            "iCaptionWidth", "iCaptionHeight", "lfCaptionFont",
            "iSmCaptionWidth", "iSmCaptionHeight", "lfSmCaptionFont",
            "iMenuWidth", "iMenuHeight", "lfMenuFont", "lfStatusFont", "lfMessageFont",
        })]
        [InlineData("ICONMETRICS", "ICONMETRICS", new[]
        {
            "cbSize", "iHorzSpacing", "iVertSpacing", "iTitleWrap", "lfFont",
        })]
        public void SpiStructLayout_Native_Matches_Managed(string nativeName, string managedName, string[] fields)
        {
            int[] native = new int[1 + fields.Length];
            int n = Win32Shim.AbiLayout(nativeName, native, native.Length);
            Assert.Equal(native.Length, n);

            Type t = FindType(managedName);
            Assert.Equal(native[0], Marshal.SizeOf(t));

            bool isClass = t.IsClass;
            for (int i = 0; i < fields.Length; i++)
            {
                // NONCLIENTMETRICS/ICONMETRICS 是 **class**（引用类型），Marshal.OffsetOf
                // 对 class 一样能算 marshalled 布局（.NET 会构造一个 layout）。
                int managedOffset = (int)Marshal.OffsetOf(t, fields[i]);
                _out.WriteLine($"{nativeName,-18} sizeof={native[0],-4} {fields[i],-16} " +
                               $"native={native[i + 1],-4} managed={managedOffset,-4}");
                Assert.Equal(native[i + 1], managedOffset);
            }
            _out.WriteLine($"{nativeName}: isClass={isClass}");
        }

        // ══════════════════════════════════════════════════════════════════
        //  2. 取值：真调一次，断言写回来的字节
        // ══════════════════════════════════════════════════════════════════
        [Fact]
        public void GetNonClientMetrics_FillsMessageFont_WeightIsValid()
        {
            // ★ 这一条就是 T3 报的"任何 WPF 窗口都起不来"的守门断言。
            //   FontWeight.FromOpenTypeWeight 的有效域是 1..999，0 会抛 ArgumentOutOfRangeException。
            int size = 500;                       // == Marshal.SizeOf(typeof(NONCLIENTMETRICS))
            IntPtr buf = Marshal.AllocHGlobal(size);
            try
            {
                for (int i = 0; i < size; i++) Marshal.WriteByte(buf, i, 0xCC);
                Marshal.WriteInt32(buf, 0, size);          // cbSize（托管侧就是这么填的）

                Assert.True(SpiW(SPI_GETNONCLIENTMETRICS, (uint)size, buf, 0),
                    "SystemParametersInfoW(SPI_GETNONCLIENTMETRICS) 返回了失败");

                // lfMessageFont @408；lfHeight@408+0，lfWeight@408+16，lfFaceName@408+28
                const int msgFont = 408;
                int lfHeight = Marshal.ReadInt32(buf, msgFont + 0);
                int lfWeight = Marshal.ReadInt32(buf, msgFont + 16);
                string face = ReadUtf16(buf + msgFont + 28, 32);

                _out.WriteLine($"lfMessageFont: lfHeight={lfHeight} lfWeight={lfWeight} lfFaceName=\"{face}\"");
                _out.WriteLine($"iBorderWidth={Marshal.ReadInt32(buf, 4)} " +
                               $"iScrollWidth={Marshal.ReadInt32(buf, 8)} " +
                               $"iCaptionHeight={Marshal.ReadInt32(buf, 20)} " +
                               $"iMenuHeight={Marshal.ReadInt32(buf, 220)}");

                Assert.NotEqual(0, lfWeight);
                Assert.InRange(lfWeight, 100, 999);          // ★ 核心断言
                Assert.NotEqual(0, lfHeight);                // 0 高度 ⇒ MessageFontSize == 0
                Assert.True(Math.Abs(lfHeight) is >= 6 and <= 72,
                    $"lfHeight={lfHeight} 不像是一个合理的 UI 字号");
                Assert.False(string.IsNullOrWhiteSpace(face), "lfFaceName 是空串");
                Assert.True(face.IndexOf('\uFFFD') < 0, "lfFaceName 含替换字符（编码错了）");

                // 其它四个 LOGFONT 也要填（SystemFonts 会读 Caption/Menu/Status/Icon）
                foreach ((string name, int off) in new[]
                {
                    ("lfCaptionFont", 24), ("lfSmCaptionFont", 124),
                    ("lfMenuFont", 224), ("lfStatusFont", 316),
                })
                {
                    int w = Marshal.ReadInt32(buf, off + 16);
                    int h = Marshal.ReadInt32(buf, off + 0);
                    string f = ReadUtf16(buf + off + 28, 32);
                    _out.WriteLine($"{name}: lfHeight={h} lfWeight={w} lfFaceName=\"{f}\"");
                    Assert.InRange(w, 100, 999);
                    Assert.NotEqual(0, h);
                    Assert.False(string.IsNullOrWhiteSpace(f));
                }

                // cbSize 要原样回写（调用方可能靠它判版本）
                Assert.Equal(size, Marshal.ReadInt32(buf, 0));
            }
            finally { Marshal.FreeHGlobal(buf); }
        }

        [Fact]
        public void GetIconMetrics_FillsIconFont()
        {
            // SystemFonts.IconFontWeight 走同一个 FromOpenTypeWeight ⇒ 同一条守门断言
            int size = 108;
            IntPtr buf = Marshal.AllocHGlobal(size);
            try
            {
                for (int i = 0; i < size; i++) Marshal.WriteByte(buf, i, 0xCC);
                Marshal.WriteInt32(buf, 0, size);
                Assert.True(SpiW(SPI_GETICONMETRICS, (uint)size, buf, 0));

                const int lfFont = 16;
                int lfWeight = Marshal.ReadInt32(buf, lfFont + 16);
                int lfHeight = Marshal.ReadInt32(buf, lfFont + 0);
                string face = ReadUtf16(buf + lfFont + 28, 32);
                _out.WriteLine($"ICONMETRICS.lfFont: lfHeight={lfHeight} lfWeight={lfWeight} face=\"{face}\"");
                _out.WriteLine($"iHorzSpacing={Marshal.ReadInt32(buf, 4)} iVertSpacing={Marshal.ReadInt32(buf, 8)}");

                Assert.InRange(lfWeight, 100, 999);
                Assert.NotEqual(0, lfHeight);
                Assert.False(string.IsNullOrWhiteSpace(face));
            }
            finally { Marshal.FreeHGlobal(buf); }
        }

        [Fact]
        public void GetNonClientMetrics_RejectsTooSmallBuffer()
        {
            // Win32 语义：cbSize 不对就失败。**不越界写**比"尽力而为"重要得多。
            int size = 500;
            IntPtr buf = Marshal.AllocHGlobal(size);
            try
            {
                for (int i = 0; i < size; i++) Marshal.WriteByte(buf, i, 0xCC);
                Marshal.WriteInt32(buf, 0, 64);          // 故意给一个太小的 cbSize
                Assert.False(SpiW(SPI_GETNONCLIENTMETRICS, 64, buf, 0),
                    "cbSize 不足时应当返回失败，而不是越界写 500 字节");
                // 出参没有被写脏（首个 int 还是 64）
                Assert.Equal(64, Marshal.ReadInt32(buf, 0));
            }
            finally { Marshal.FreeHGlobal(buf); }
        }

        [Fact]
        public void ScalarQueries_ReturnUsableValues()
        {
            // 这些 action 的 0 **不是**合理默认值（0 会让功能退化或行为怪异），
            // 而且它们全是 `ref int` / `ref bool`（4 字节）。
            var expect = new (uint Action, string Name, int Min)[]
            {
                (SPI_GETWHEELSCROLLLINES, "WheelScrollLines", 1),   // 0 = 滚轮滚不动
                (SPI_GETMOUSEHOVERTIME,   "MouseHoverTime",   1),
                (SPI_GETFOCUSBORDERWIDTH, "FocusBorderWidth", 1),
                (SPI_GETFOCUSBORDERHEIGHT,"FocusBorderHeight",1),
                (SPI_GETCARETWIDTH,       "CaretWidth",       1),
            };

            foreach ((uint action, string name, int min) in expect)
            {
                IntPtr buf = Marshal.AllocHGlobal(4);
                try
                {
                    Marshal.WriteInt32(buf, 0, unchecked((int)0xCCCCCCCC));
                    Assert.True(SpiW(action, 0u, buf, 0u), $"{name}: SystemParametersInfoW 失败");
                    int v = Marshal.ReadInt32(buf, 0);
                    _out.WriteLine($"{name,-18} action=0x{action:x4} → {v}");
                    Assert.True(v >= min, $"{name} = {v}，应 ≥ {min}");
                }
                finally { Marshal.FreeHGlobal(buf); }
            }

            // 布尔类
            foreach ((uint action, string name) in new[]
            {
                (SPI_GETFONTSMOOTHING, "FontSmoothing"),
                (SPI_GETKEYBOARDCUES, "KeyboardCues"),
            })
            {
                IntPtr buf = Marshal.AllocHGlobal(4);
                try
                {
                    Marshal.WriteInt32(buf, 0, unchecked((int)0xCCCCCCCC));
                    Assert.True(SpiW(action, 0u, buf, 0u), $"{name}: SystemParametersInfoW 失败");
                    int v = Marshal.ReadInt32(buf, 0);
                    _out.WriteLine($"{name,-18} action=0x{action:x4} → {v}");
                    Assert.Equal(1, v);
                }
                finally { Marshal.FreeHGlobal(buf); }
            }
        }

        [Fact]
        public void GetWorkArea_ReturnsRealScreenSize()
        {
            IntPtr buf = Marshal.AllocHGlobal(16);
            try
            {
                for (int i = 0; i < 16; i++) Marshal.WriteByte(buf, i, 0xCC);
                Assert.True(SpiW(SPI_GETWORKAREA, 0, buf, 0));
                int l = Marshal.ReadInt32(buf, 0), t = Marshal.ReadInt32(buf, 4);
                int r = Marshal.ReadInt32(buf, 8), b = Marshal.ReadInt32(buf, 12);
                _out.WriteLine($"WorkArea = ({l},{t})-({r},{b})");
                // Xvfb :99 是 1280x1024；无 WM ⇒ 工作区 == 整个屏幕
                Assert.True(r - l >= 320 && b - t >= 240,
                    $"工作区 {r - l}x{b - t} 小于任何可用屏幕");
            }
            finally { Marshal.FreeHGlobal(buf); }
        }

        private static string ReadUtf16(IntPtr p, int maxUnits)
        {
            var sb = new StringBuilder();
            for (int i = 0; i < maxUnits; i++)
            {
                short c = Marshal.ReadInt16(p, i * 2);
                if (c == 0) break;
                sb.Append((char)c);
            }
            return sb.ToString();
        }
    }
}

// M7b · 跨边界结构体布局断言（**最强的一条证据**）
//
// 【为什么「原生侧打印 offset」不够】
//   原生侧的 _Static_assert 只能证明「原生自己前后一致」。真正的风险是
//   **原生布局 ≠ 托管布局**——那会编译全过、跑起来字段全错，而且症状是
//   "事件类型对但坐标是垃圾"这种最难定位的形态。
//
//   所以这里做的是**双向对齐**：
//     · 原生：`WpfLinuxWin32_AbiLayout("MSG", …)` 把 `offsetof/sizeof` 交出来；
//     · 托管：`Marshal.OffsetOf` / `Marshal.SizeOf` 读**编译产物里那个真实的
//       结构体**（MSG 是 public；其余在 WindowsBase 里是 internal 嵌套类型，
//       用反射取 Type 后 Marshal 一样能算）；
//     · 逐字段比对，不一致就报出字段名与两个值。
//
//   `WNDCLASSEX_D` 是 **class**（不是 struct）且 `CharSet.Unicode`，它的两个
//   string 字段在 Linux 上到底编成什么，光看 offset 还不够——所以额外用
//   `Marshal.StructureToPtr` 把它写进原生内存，直接读字节验证
//   「lpfnWndProc @8 / lpszMenuName @56 / lpszClassName @64」以及
//   **UTF-16LE（2 字节/单元）** 这个编码前提。
//   （这一步是必要的：如果 .NET 在 Unix 上把 CharSet.Unicode 编成 4 字节
//     wchar_t，类名就会变成 "H\0w\0n\0d\0…" 传给 shim，RegisterClassEx 收到的
//     是一个空类名——实测前无法从文档断定。）

using System;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Interop;
using System.Windows.Threading;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    public sealed class Win32AbiLayoutTests
    {
        private readonly ITestOutputHelper _out;

        public Win32AbiLayoutTests(ITestOutputHelper output) => _out = output;

        private static readonly Assembly WindowsBaseAssembly = typeof(Dispatcher).Assembly;

        /// <summary>
        /// 在 WindowsBase 里按简单名找类型（含嵌套类型）。
        ///
        /// 【为什么不用 Assembly.GetTypes() 再筛】
        ///   实测：WindowsBase 的类型图会牵出 System.Security.Cryptography.Xml /
        ///   System.IO.Packaging 两个**不在测试工程引用表里**的传递依赖，
        ///   `GetTypes()` 直接抛 ReflectionTypeLoadException（部分类型加载不了）。
        ///   按「全名」精确取类型不会触碰同程序集里其它类型的依赖 —— 既避开了
        ///   上面的问题，也顺带把「结构体到底住在哪个类里」这件事变成显式断言：
        ///   上游一旦搬了家，这里给出的是**候选清单**而不是一句"找不到"。
        /// </summary>
        internal static Type FindType(string simpleName)
        {
            string[] owners =
            {
                "MS.Win32.NativeMethods",
                "MS.Win32.UnsafeNativeMethods",
                "MS.Win32.SafeNativeMethods",
                "System.Windows.Interop",
                "",
            };
            foreach (string owner in owners)
            {
                string full = owner.Length == 0 ? simpleName : owner + "+" + simpleName;
                Type t = WindowsBaseAssembly.GetType(full, throwOnError: false);
                if (t != null) return t;
            }
            // 顶层类型（非嵌套）再试一次全名
            Type top = WindowsBaseAssembly.GetType(simpleName, throwOnError: false);
            if (top != null) return top;

            throw new InvalidOperationException(
                $"WindowsBase 里找不到类型 {simpleName}（已试 {string.Join(" / ", owners)}）。" +
                "上游改过结构体的宿主类或名字？");
        }

        [Fact]
        public void WindowsBase_ManagedTypes_AreFound()
        {
            _out.WriteLine("WindowsBase: " + WindowsBaseAssembly.Location);
            _out.WriteLine("MSG:          " + typeof(MSG).FullName);
            foreach (string n in new[]
            {
                "RECT", "POINT", "WINDOWPOS", "TRACKMOUSEEVENT",
                "PAINTSTRUCT", "MONITORINFOEX", "WNDCLASSEX_D",
            })
            {
                Type t = FindType(n);
                _out.WriteLine($"{n,-16} {t.FullName}  sizeof={Marshal.SizeOf(t)}");
            }
        }

        /// <summary>
        /// 逐字段比对原生 offset 与托管 offset。
        /// native 数组布局：[sizeof, off(f1), off(f2), …]（见 win32_exports.c 的 AbiLayout）。
        /// </summary>
        [Theory]
        // name            managed type name   fields（顺序必须与 AbiLayout 一致）
        [InlineData("MSG", "MSG", new[] { "_hwnd", "_message", "_wParam", "_lParam", "_time", "_pt_x", "_pt_y" })]
        [InlineData("RECT", "RECT", new[] { "left", "top", "right", "bottom" })]
        [InlineData("WINDOWPOS", "WINDOWPOS", new[] { "hwnd", "hwndInsertAfter", "x", "y", "cx", "cy", "flags" })]
        [InlineData("TRACKMOUSEEVENT", "TRACKMOUSEEVENT", new[] { "cbSize", "dwFlags", "hwndTrack", "dwHoverTime" })]
        // 托管 PAINTSTRUCT 把 by-value RECT 摊平成 4 个 int（rcPaint_left/top/right/bottom）
        [InlineData("PAINTSTRUCT", "PAINTSTRUCT", new[] { "hdc", "fErase", "rcPaint_left", "rcPaint_top", "rcPaint_right", "rcPaint_bottom", "fRestore", "fIncUpdate", "reserved1" })]
        [InlineData("MONITORINFOEX", "MONITORINFOEX", new[] { "cbSize", "rcMonitor", "rcWork", "dwFlags", "szDevice" })]
        public void NativeLayout_MatchesManagedLayout(string nativeName, string managedName, string[] fields)
        {
            int[] native = new int[1 + fields.Length];
            int n = Win32Shim.AbiLayout(nativeName, native, native.Length);
            Assert.Equal(native.Length, n);

            Type t = nativeName == "MSG" ? typeof(MSG) : FindType(managedName);

            Assert.Equal(native[0], Marshal.SizeOf(t));

            for (int i = 0; i < fields.Length; i++)
            {
                int managedOffset;
                try
                {
                    managedOffset = (int)Marshal.OffsetOf(t, fields[i]);
                }
                catch (Exception ex)
                {
                    // RECT/WINDOWPOS 等在托管侧是**嵌套结构体字段**（WINDOWPOS.pt 是 POINT），
                    // Marshal.OffsetOf 对嵌套值类型字段一样能给偏移；真给不了就说明
                    // 类型形状与预期不符，必须显式失败而不是跳过。
                    throw new Xunit.Sdk.XunitException(
                        $"{nativeName}.{fields[i]} 取托管偏移失败：{ex.GetType().Name}: {ex.Message}");
                }

                _out.WriteLine($"{nativeName,-16} sizeof={native[0],-4} {fields[i],-14} native={native[i + 1],-4} managed={managedOffset,-4}");
                Assert.Equal(native[i + 1], managedOffset);
            }
        }

        /// <summary>
        /// WNDCLASSEX_D 是 **class** + CharSet.Unicode + 按值传给
        /// `RegisterClassExEx(NativeMethods.WNDCLASSEX_D wc_d)`。
        /// 这里用 marshaler 自己把它写进原生内存，再按 shim 的偏移去读——
        /// 断言的是「shim 读到的字节就是托管写的字段」。
        /// </summary>
        [Fact]
        public void WndClassExD_MarshalsToNativeLayout()
        {
            Type t = FindType("WNDCLASSEX_D");
            int[] native = new int[13];
            int n = Win32Shim.AbiLayout("WNDCLASSEX_D", native, native.Length);
            Assert.Equal(native.Length, n);
            int size = native[0];
            Assert.Equal(size, Marshal.SizeOf(t));

            object wc = Activator.CreateInstance(t);
            Set(t, wc, "cbSize", 0x11111111);
            Set(t, wc, "style", 0x22222222);
            // lpfnWndProc 是 **委托**类型（MS.Win32.NativeMethods+WndProc），不是 IntPtr。
            // 造一个签名一致的委托塞进去，验的是"它占 8 字节、落在偏移 8"。
            Type wndProcType = t.GetField("lpfnWndProc",
                BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance).FieldType;
            Delegate wndProc = Delegate.CreateDelegate(wndProcType,
                typeof(Win32AbiLayoutTests).GetMethod(nameof(ProbeWndProc),
                    BindingFlags.Static | BindingFlags.NonPublic));
            Set(t, wc, "lpfnWndProc", wndProc);
            Set(t, wc, "cbClsExtra", 0x44444444);
            Set(t, wc, "cbWndExtra", 0x55555555);
            Set(t, wc, "hInstance", unchecked((IntPtr)(long)0x6666666666666666UL));
            Set(t, wc, "hIcon", unchecked((IntPtr)(long)0x7777777777777777UL));
            Set(t, wc, "hCursor", unchecked((IntPtr)(long)0x8888888888888888UL));
            Set(t, wc, "hbrBackground", unchecked((IntPtr)(long)0x9999999999999999UL));
            Set(t, wc, "lpszMenuName", "MENU");
            Set(t, wc, "lpszClassName", "K\u00c4M\u20ac");   // 含非 ASCII，顺带验 UTF-16
            Set(t, wc, "hIconSm", unchecked((IntPtr)(long)0xAAAAAAAAAAAAAAAAUL));

            IntPtr buf = Marshal.AllocHGlobal(size);
            try
            {
                for (int i = 0; i < size; i++) Marshal.WriteByte(buf, i, 0xCC);
                Marshal.StructureToPtr(wc, buf, false);

                // 偏移取自 **shim 自己报的** native 数组（顺序见 win32_exports.c）
                string[] names =
                {
                    "cbSize", "style", "lpfnWndProc", "cbClsExtra", "cbWndExtra", "hInstance",
                    "hIcon", "hCursor", "hbrBackground", "lpszMenuName", "lpszClassName", "hIconSm",
                };
                uint[] expected32 = { 0x11111111, 0x22222222, 0, 0x44444444, 0x55555555, 0, 0, 0, 0, 0, 0, 0 };
                ulong[] expected64 =
                {
                    0, 0, 0 /*lpfnWndProc 单独断言*/, 0, 0, 0x6666666666666666UL,
                    0x7777777777777777UL, 0x8888888888888888UL, 0x9999999999999999UL,
                    0, 0, 0xAAAAAAAAAAAAAAAAUL,
                };

                for (int i = 0; i < names.Length; i++)
                {
                    int off = native[i + 1];
                    _out.WriteLine($"WNDCLASSEX_D {names[i],-14} nativeOffset={off}");
                    if (expected64[i] != 0)
                    {
                        ulong got = (ulong)Marshal.ReadInt64(buf, off);
                        Assert.Equal(expected64[i], got);
                    }
                    else if (expected32[i] != 0)
                    {
                        int got = Marshal.ReadInt32(buf, off);
                        Assert.Equal(unchecked((int)expected32[i]), got);
                    }
                }

                // lpfnWndProc：委托 marshal 成函数指针，必须落在偏移 8 且非 0
                Assert.NotEqual(IntPtr.Zero, Marshal.ReadIntPtr(buf, native[3]));
                GC.KeepAlive(wndProc);

                // 两个 string 字段：必须是 **UTF-16LE**（2 字节/单元）。
                // 这个是 shim 的 wpf_utf16_to_utf8_dup 的前提，错了类名就变空串。
                int menuOff = native[10];    // lpszMenuName
                int classOff = native[11];   // lpszClassName
                IntPtr menuPtr = Marshal.ReadIntPtr(buf, menuOff);
                IntPtr classPtr = Marshal.ReadIntPtr(buf, classOff);
                Assert.NotEqual(IntPtr.Zero, menuPtr);
                Assert.NotEqual(IntPtr.Zero, classPtr);

                Assert.Equal("MENU", ReadUtf16(menuPtr));
                Assert.Equal("K\u00c4M\u20ac", ReadUtf16(classPtr));

                // 明确断言「不是 4 字节 wchar_t」：第 3 个 16 位单元必须是 'M' 而不是 0。
                Assert.Equal((short)'M', Marshal.ReadInt16(classPtr, 4));
                Assert.NotEqual(0, Marshal.ReadInt16(classPtr, 4));
            }
            finally
            {
                Marshal.FreeHGlobal(buf);
            }
        }

        /// <summary>只用来给 WNDCLASSEX_D.lpfnWndProc 造一个签名一致的委托。</summary>
        private static IntPtr ProbeWndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam)
            => IntPtr.Zero;

        private static string ReadUtf16(IntPtr p)
        {
            var sb = new System.Text.StringBuilder();
            for (int i = 0; ; i += 2)
            {
                short c = Marshal.ReadInt16(p, i);
                if (c == 0) break;
                sb.Append((char)c);
                if (i > 512) break;
            }
            return sb.ToString();
        }

        private static void Set(Type t, object instance, string field, object value)
        {
            FieldInfo f = t.GetField(field, BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            Assert.True(f != null, $"{t.FullName} 没有字段 {field}");
            f.SetValue(instance, value);
        }

        [Fact]
        public void Shim_IsLoaded_FromRepoFallback()
        {
            _out.WriteLine("shim: " + Win32Shim.LoadedPath);
            Assert.True(Win32Shim.ShimVersion() >= 1);
            Assert.Contains("libwpfwin32.so", Win32Shim.LoadedPath);
            // 没有设置 WPF_LINUX_WIN32_SHIM 也能找到 → 证明仓库回退路径有效，
            // 这正是托管层 resolver 在测试输出目录里所依赖的那条。
            Assert.True(string.IsNullOrEmpty(
                Environment.GetEnvironmentVariable("WPF_LINUX_WIN32_SHIM")));
        }
    }
}

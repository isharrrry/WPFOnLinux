// M7c · 轨道 B —— **后台缓冲句柄真的能被当作 IWICBitmapSource 查询**（+ 引用计数配平）
//
// 【这个文件存在的理由】
//   `WriteableBitmap.AcquireBackBuffer`（`WriteableBitmap.cs:957`）拿到的是
//   `MILSwDoubleBufferedBitmapGetBackBuffer` 交出的**像素缓冲令牌**，紧接着
//   `WicSourceHandle = _pBackBuffer`（`:962`）→ `BitmapSource.set_WicSourceHandle`
//   （`BitmapSource.cs:581-586`）对**这个令牌**调
//   `MILQueryInterface(token, IID_IWICBitmapSource, out _)`。
//   修前：令牌既不在 `MilDeviceObjectTable`，也不被 WIC shim 认领 ⇒ **E_HANDLE**
//   ⇒ `HRESULT.Check` 抛，`WriteableBitmap.Lock()` 在第一步就死。
//
// 【判据为什么不是"跑通了"】
//   QI 只是**入口**。主控给的硬约束是"成功的 QI 会 AddRef、返回的指针一定由 `MILRelease` 释放"
//   —— 所以本文件的重头是**配平**，而且照 T1 的 G6/G6b 口径：
//     · 稳态计数回基线（必要，但**不够**）；
//     · **高水位不涨**（才排得掉"计数相等但其实一直在涨/回收"的假配平）；
//     · **账本不串门**：MIL 自己下发的令牌一次都不该落进 `WicShim_*` 那条路
//       （`OwnedHits`/活句柄数一个不动 —— 这才证明"两边账本单边"没有发生）。

using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using WpfGfx.Linux.Interop;
using Xunit;
using Xunit.Abstractions;

namespace WpfGfx.Linux.Tests.ManagedLayer
{
    /// <summary>后台缓冲令牌的 QI 语义 + 引用计数配平。</summary>
    [Trait("Category", "ManagedLayer")]
    public sealed class MilWicQueryInterfaceTests
    {
        private readonly ITestOutputHelper _out;
        public MilWicQueryInterfaceTests(ITestOutputHelper output) => _out = output;

        private static readonly Guid IID_NotImplemented =
            new Guid(0x00000001, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

        // ==================================================================
        //  ① IID 常量必须与上游逐字一致（不手抄、机械核对）
        // ==================================================================

        private static string FindRepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            for (int up = 0; up < 10 && dir != null; up++, dir = dir.Parent)
            {
                if (File.Exists(Path.Combine(dir.FullName, "handoff.md"))) return dir.FullName;
            }
            throw new InvalidOperationException($"找不到仓库根（含 handoff.md），起点 {AppContext.BaseDirectory}");
        }

        [Fact]
        public void IID_IWICBitmapSource_与上游定义逐字一致()
        {
            string path = Path.Combine(FindRepoRoot(), "upstream", "wpf", "src", "Microsoft.DotNet.Wpf",
                "src", "Common", "Graphics", "wgx_exports.cs");
            string text = File.ReadAllText(path);

            Match m = Regex.Match(text,
                @"IID_IWICBitmapSource\s*=\s*new Guid\((?<args>[^)]*)\)");
            Assert.True(m.Success, $"{path} 里找不到 IID_IWICBitmapSource —— 上游搬家了？");

            Guid upstream = ParseGuidArgs(m.Groups["args"].Value);
            _out.WriteLine($"上游 IID_IWICBitmapSource = {upstream:D}");
            _out.WriteLine($"本工程常量              = {MilNative.IID_IWICBitmapSource:D}");
            Assert.Equal(upstream, MilNative.IID_IWICBitmapSource);

            // IID_IUnknown 是 COM 的标准值（{00000000-0000-0000-C000-000000000046}），
            // 上游 wgx_exports.cs 里没有它，所以这一条按标准值直接钉。
            Assert.Equal(new Guid(0x00000000, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46),
                MilNative.IID_IUnknown);
        }

        private static Guid ParseGuidArgs(string args)
        {
            string[] parts = args.Split(',');
            Assert.Equal(11, parts.Length);
            uint a = Convert.ToUInt32(parts[0].Trim().Replace("0x", ""), 16);
            ushort b = Convert.ToUInt16(parts[1].Trim().Replace("0x", ""), 16);
            ushort c = Convert.ToUInt16(parts[2].Trim().Replace("0x", ""), 16);
            byte[] d = new byte[8];
            for (int i = 0; i < 8; i++) d[i] = Convert.ToByte(parts[3 + i].Trim().Replace("0x", ""), 16);
            return new Guid(a, b, c, d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7]);
        }

        // ==================================================================
        //  ② 后台缓冲：QI 放行 + 对象同一性
        // ==================================================================

        private static IntPtr CreateDoubleBuffered(uint w, uint h, out IntPtr backBuffer, out uint backSize)
        {
            Guid fmt = MilPixelFormats.Pbgra32;
            Assert.Equal(HResult.S_OK,
                MilNative.MILSwDoubleBufferedBitmapCreate(w, h, 96.0, 96.0, ref fmt, IntPtr.Zero, out IntPtr swdbb));
            Assert.NotEqual(IntPtr.Zero, swdbb);

            MilNative.MILSwDoubleBufferedBitmapGetBackBuffer(swdbb, out backBuffer, out backSize);
            Assert.NotEqual(IntPtr.Zero, backBuffer);
            return swdbb;
        }

        private static int Query(IntPtr handle, Guid iid, out IntPtr ppv)
            => MilNative.MILQueryInterface(handle, ref iid, out ppv);

        [Fact]
        public void 后台缓冲_QI为IWICBitmapSource_放行且返回同一对象()
        {
            MilNative.ResetProcessStateForTests();
            IntPtr swdbb = CreateDoubleBuffered(4, 4, out IntPtr back, out uint size);
            _out.WriteLine($"swdbb=0x{swdbb.ToInt64():x} 后台缓冲令牌=0x{back.ToInt64():x} 字节数={size}");
            Assert.Equal(4u * 4 * 4, size);

            Guid wic = MilNative.IID_IWICBitmapSource;
            int hr = Query(back, wic, out IntPtr ppv);
            _out.WriteLine($"QI(token, IID_IWICBitmapSource) ⇒ hr=0x{hr:x8} ppv=0x{ppv.ToInt64():x}");
            Assert.Equal(HResult.S_OK, hr);
            Assert.Equal(back, ppv);      // COM 语义：同一个对象，不是新发一个句柄

            Guid unknown = MilNative.IID_IUnknown;
            Assert.Equal(HResult.S_OK, Query(back, unknown, out IntPtr ppv2));
            Assert.Equal(back, ppv2);

            // 两个成功的 QI 各自 AddRef 了一根 ⇒ 逐个还回去。
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(back));
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(back));

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(swdbb));
        }

        [Fact]
        public void 后台缓冲_QI其它IID_仍然E_NOINTERFACE()
        {
            MilNative.ResetProcessStateForTests();
            IntPtr swdbb = CreateDoubleBuffered(2, 2, out IntPtr back, out _);

            Guid other = IID_NotImplemented;
            int hr = Query(back, other, out IntPtr ppv);
            _out.WriteLine($"QI(token, 未实现 IID) ⇒ hr=0x{hr:x8}");
            Assert.Equal(HResult.E_NOINTERFACE, hr);
            Assert.Equal(IntPtr.Zero, ppv);

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(swdbb));
        }

        /// <summary>
        /// **反放宽**断言：放行 `IID_IWICBitmapSource` 只对"可作为位图源"的那一类对象成立。
        /// 工厂、双缓冲位图**主对象**这些都不是位图源，问它们要 IWICBitmapSource 必须仍是
        /// `E_NOINTERFACE` —— 否则就是把 M7a 的语义从"严格"放宽成"什么 IID 都答"。
        /// </summary>
        [Fact]
        public void 非位图源对象_QI位图源_仍是E_NOINTERFACE()
        {
            MilNative.ResetProcessStateForTests();

            Assert.Equal(HResult.S_OK, MilNative.MILCreateFactory(out IntPtr factory, MilErrors.MilSdkVersion));
            IntPtr swdbb = CreateDoubleBuffered(2, 2, out IntPtr back, out _);

            Guid wic = MilNative.IID_IWICBitmapSource;

            int hrFactory = Query(factory, wic, out IntPtr ppvFactory);
            int hrSwdbb = Query(swdbb, wic, out IntPtr ppvSwdbb);
            _out.WriteLine($"工厂 ⇒ hr=0x{hrFactory:x8}；双缓冲主对象 ⇒ hr=0x{hrSwdbb:x8}");
            Assert.Equal(HResult.E_NOINTERFACE, hrFactory);
            Assert.Equal(HResult.E_NOINTERFACE, hrSwdbb);
            Assert.Equal(IntPtr.Zero, ppvFactory);
            Assert.Equal(IntPtr.Zero, ppvSwdbb);

            // 但它们仍然答 IUnknown（MIL 下发对象的原有语义，未动）。
            // 每次成功的 QI 都会 AddRef ⇒ 逐个还回去（含创建时那一根）。
            Guid unk = MilNative.IID_IUnknown;
            Assert.Equal(HResult.S_OK, Query(factory, unk, out _));
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(factory));   // QI 那根
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(factory));   // 创建那根

            Assert.Equal(HResult.S_OK, Query(swdbb, unk, out _));
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(swdbb));     // QI 那根
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(swdbb));     // 创建那根 ⇒ 析构 + 收别名

            Assert.Equal(0, MilDeviceObjectTable.Count);
            Assert.Equal(0, MilPixelBufferTable.Count);
            Assert.Equal(0, MilBackBufferSourceTable.Count);
            _ = back;
        }

        // ==================================================================
        //  ③ AddRef/Release 契约：同一张账、迟到一根也不提前销毁
        // ==================================================================

        [Fact]
        public void 后台缓冲_AddRef与Release走同一张账()
        {
            MilNative.ResetProcessStateForTests();
            IntPtr swdbb = CreateDoubleBuffered(2, 2, out IntPtr back, out _);

            IntPtr dev = MilBackBufferSourceTable.ResolveDevice(back);
            Assert.NotEqual(IntPtr.Zero, dev);
            MilDeviceObject obj = MilDeviceObjectTable.Resolve(dev);
            Assert.NotNull(obj);
            _out.WriteLine($"令牌 0x{back.ToInt64():x} → 设备对象 0x{dev.ToInt64():x}（初始 refs={obj.RefCount}）");
            Assert.Equal(1u, obj.RefCount);         // 初始那一根归主对象（swdbb）

            // ★ 直接对**令牌** AddRef 也要算数（上游会这么干：D3DImage.cs:796
            //   `AddRef(_softwareCopy.WicSourceHandle)`，随后把句柄交给原生侧由它 Release）。
            Assert.Equal(2u, MilNative.MILAddRef(back));
            Assert.Equal(3u, MilNative.MILAddRef(back));

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(back));    // 3 → 2
            Assert.Equal(2u, MilDeviceObjectTable.Resolve(dev).RefCount);
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(back));    // 2 → 1（主对象那根还在）
            Assert.NotNull(MilDeviceObjectTable.Resolve(dev));
            _out.WriteLine($"两次还完 ⇒ refs={MilDeviceObjectTable.Resolve(dev).RefCount}（只剩主对象那根）");

            // 主对象析构 ⇒ 连带把别名与后台缓冲句柄一起收掉。
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(swdbb));
            Assert.Null(MilDeviceObjectTable.Resolve(dev));
            Assert.Null(MilDeviceObjectTable.Resolve(swdbb));
            Assert.Equal(IntPtr.Zero, MilBackBufferSourceTable.ResolveDevice(back));

            // 拆除之后：QI / Release 都回 fail-safe E_HANDLE（不是"继续放行悬挂句柄"）。
            Guid wic = MilNative.IID_IWICBitmapSource;
            Assert.Equal(HResult.E_HANDLE, Query(back, wic, out _));
            Assert.Equal(HResult.E_HANDLE, MilNative.MILRelease(back));
        }

        /// <summary>
        /// 调用方还握着 QI 那根引用时主对象被释放：对象按 COM 语义活到最后一根引用消失，
        /// 别名**不能**提前摘（否则那次迟到的 Release 会拿到 E_HANDLE）。
        /// </summary>
        [Fact]
        public void 调用方仍持有QI引用时释放主对象_迟到的Release仍配平()
        {
            MilNative.ResetProcessStateForTests();
            IntPtr swdbb = CreateDoubleBuffered(2, 2, out IntPtr back, out _);
            IntPtr dev = MilBackBufferSourceTable.ResolveDevice(back);

            Guid wic = MilNative.IID_IWICBitmapSource;
            Assert.Equal(HResult.S_OK, Query(back, wic, out _));       // refs: 1 → 2

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(swdbb));   // 主对象那根走了 ⇒ 剩 1
            Assert.NotNull(MilDeviceObjectTable.Resolve(dev));
            Assert.Equal(dev, MilBackBufferSourceTable.ResolveDevice(back));

            Assert.Equal(HResult.S_OK, MilNative.MILRelease(back));    // 迟到的那根 ⇒ 0，对象消失
            Assert.Null(MilDeviceObjectTable.Resolve(dev));
            Assert.Equal(IntPtr.Zero, MilBackBufferSourceTable.ResolveDevice(back));

            // 账本回基线（本用例自己开的那两个对象都收干净了）。
            Assert.Equal(0, MilDeviceObjectTable.Count);
            Assert.Equal(0, MilPixelBufferTable.Count);
            Assert.Equal(0, MilBackBufferSourceTable.Count);
        }

        // ==================================================================
        //  ④ 配平 + 高水位（照 T1 G6/G6b 口径）
        // ==================================================================

        [Fact]
        public void 创建释放N轮_MIL与WIC两本账都回基线且高水位不涨()
        {
            MilNative.ResetProcessStateForTests();

            // WIC 侧：把桥接指向 T2 的 shim（这是**读**它，不是改它）。
            string shim = Path.Combine(FindRepoRoot(), "build", "DirectWrite.Linux", "wic-shim", "libwpfwic.so");
            bool wicConnected = false;
            if (File.Exists(shim))
            {
                Environment.SetEnvironmentVariable("MILBRIDGE_WIC_SO", shim);
                MilExternalHandleBridge.ResetForTests();
                wicConnected = MilExternalHandleBridge.ExternalHandleCount() >= 0;
            }
            _out.WriteLine($"WIC shim: {shim}（存在={File.Exists(shim)} 已接上={wicConnected}）");

            int baselineDev = MilDeviceObjectTable.Count;
            int baselinePix = MilPixelBufferTable.Count;
            int baselineAlias = MilBackBufferSourceTable.Count;
            int baselineWic = wicConnected ? MilExternalHandleBridge.ExternalHandleCount() : -1;
            int baselineWicPeak = wicConnected ? MilExternalHandleBridge.ExternalPeakHandleCount() : -1;
            long baselineOwnedHits = MilExternalHandleBridge.OwnedHits;
            long baselineProbes = MilExternalHandleBridge.ProbeCount;
            int baselineForeign = wicConnected ? MilExternalHandleBridge.ForeignSourceCount() : -1;

            int peakDev = baselineDev, peakPix = baselinePix, peakAlias = baselineAlias;
            int peakWic = baselineWic, peakWicPeak = baselineWicPeak;

            const int Rounds = 40;
            for (int i = 0; i < Rounds; i++)
            {
                bool qi = (i % 2) == 0;          // 一半走 QI+Release，一半直接拆（考验别名清理）
                IntPtr swdbb = CreateDoubleBuffered(8, 8, out IntPtr back, out _);

                // 轮内采样：**高水位必须在"对象还活着"的这一刻取**，
                // 只在轮末取的话位图表永远是 0，那条断言就是空的（第一版正是这样，已修）。
                int midDev = MilDeviceObjectTable.Count;
                int midAlias = MilBackBufferSourceTable.Count;
                int midPix = MilPixelBufferTable.Count;

                if (qi)
                {
                    Guid wic = MilNative.IID_IWICBitmapSource;
                    Assert.Equal(HResult.S_OK, Query(back, wic, out IntPtr ppv));
                    Assert.Equal(back, ppv);
                    Assert.Equal(HResult.S_OK, MilNative.MILRelease(back));   // 还掉 QI 那一根
                }

                Assert.Equal(HResult.S_OK, MilNative.MILRelease(swdbb));      // 主对象拆掉

                peakDev = Math.Max(peakDev, Math.Max(midDev, MilDeviceObjectTable.Count));
                peakAlias = Math.Max(peakAlias, Math.Max(midAlias, MilBackBufferSourceTable.Count));
                peakPix = Math.Max(peakPix, Math.Max(midPix, MilPixelBufferTable.Count));
                if (wicConnected)
                {
                    peakWic = Math.Max(peakWic, MilExternalHandleBridge.ExternalHandleCount());
                    peakWicPeak = Math.Max(peakWicPeak, MilExternalHandleBridge.ExternalPeakHandleCount());
                }
            }

            int finalDev = MilDeviceObjectTable.Count;
            int finalPix = MilPixelBufferTable.Count;
            int finalAlias = MilBackBufferSourceTable.Count;
            int finalWic = wicConnected ? MilExternalHandleBridge.ExternalHandleCount() : -1;
            int finalWicPeak = wicConnected ? MilExternalHandleBridge.ExternalPeakHandleCount() : -1;

            _out.WriteLine($"[MIL] 设备对象 {baselineDev}→{finalDev}（高水位 {peakDev}）；" +
                           $"位图表 {baselinePix}→{finalPix}（高水位 {peakPix}）；" +
                           $"别名表 {baselineAlias}→{finalAlias}（高水位 {peakAlias}）");
            int finalForeign = wicConnected ? MilExternalHandleBridge.ForeignSourceCount() : -1;
            _out.WriteLine($"[WIC] 活句柄 {baselineWic}→{finalWic}（高水位 {peakWic}）；" +
                           $"shim 高水位 {baselineWicPeak}→{finalWicPeak}（观测 {peakWicPeak}）；" +
                           $"外来源登记 {baselineForeign}→{finalForeign}；" +
                           $"OwnedHits {baselineOwnedHits}→{MilExternalHandleBridge.OwnedHits}、" +
                           $"ProbeCount {baselineProbes}→{MilExternalHandleBridge.ProbeCount}");

            // ① 稳态回基线
            Assert.Equal(baselineDev, finalDev);
            Assert.Equal(baselinePix, finalPix);
            Assert.Equal(baselineAlias, finalAlias);

            // ② **高水位不涨**：40 轮里一次都没超过"一轮里该有的"那点对象数。
            //    只断言稳态相等会漏掉"回收后又涨"的假配平。
            Assert.True(peakDev <= baselineDev + 3,
                $"设备对象高水位涨到 {peakDev}（基线 {baselineDev} + 每轮 swdbb/别名 2 个 + 余量 1）");
            Assert.True(peakAlias <= baselineAlias + 1,
                $"别名表高水位涨到 {peakAlias}（基线 {baselineAlias}）");
            Assert.True(peakPix <= baselinePix + 1,
                $"位图表高水位涨到 {peakPix}（基线 {baselinePix}）");

            // ③ 账本不串门：MIL 自己下发的令牌一次都不该被 WIC 认领，
            //    也不该让 shim 的活句柄/高水位动一根。
            Assert.Equal(baselineOwnedHits, MilExternalHandleBridge.OwnedHits);
            if (wicConnected)
            {
                Assert.Equal(baselineWic, finalWic);          // 记账面：活句柄回基线
                Assert.Equal(baselineForeign, finalForeign);  // 派发面：外来源登记也回基线（0→0）

                // 【为什么这里断言的是"有界"而不是"与基线逐字相等"】收尾轮接上 T2 的
                //   外来源派发之后，每一次双缓冲创建都会**临时**在 shim 里占一个派发槽
                //   （`WicShim_RegisterForeignSource` 复用 KIND_FRAME 槽位），于是 shim 的
                //   **高水位**会从 0 抬到 1 —— 那是**派发槽**，不是记账（`HandleCount` 不数它、
                //   `OwnsHandle` 对外来条目返回 0，两者都在本用例里断言过）。
                //   所以这里钉的是：**同时最多只有 1 个外来源在册**（每轮登记/注销配平）；
                //   单调高水位不可能回落到基线，用 `== baseline` 断言只会得到一条恒红的假断言。
                Assert.True(peakWicPeak <= baselineWicPeak + 1,
                    $"外来源派发槽高水位涨到 {peakWicPeak}（基线 {baselineWicPeak} + 同时最多 1 个）");
                Assert.Equal(baselineWic, peakWic);
            }
            else
            {
                _out.WriteLine("⚠ WIC 侧配平断言**未执行**：libwpfwic.so 不在预期路径（T2 产物搬家了？）");
            }
        }

        // ==================================================================
        //  ⑤ T2 交办的接线：后缓冲句柄登记成 WIC **外来源**（派发），**记账一字未动**
        // ==================================================================

        [Fact]
        public void 后缓冲登记为WIC外来源_派发可用且记账未变()
        {
            MilNative.ResetProcessStateForTests();

            // 让桥指向 T2 的 shim（**读**它，不改它）。
            string shim = Path.Combine(FindRepoRoot(), "build", "DirectWrite.Linux", "wic-shim", "libwpfwic.so");
            if (!File.Exists(shim))
            {
                _out.WriteLine($"跳过：{shim} 不存在（T2 产物不在预期位置）");
                return;
            }
            Environment.SetEnvironmentVariable("MILBRIDGE_WIC_SO", shim);
            MilExternalHandleBridge.ResetForTests();
            bool available = MilExternalHandleBridge.ForeignSourceDispatchAvailable;
            _out.WriteLine($"WIC 外来源派发可用={available}（shim={shim}）");

            int devBefore = MilDeviceObjectTable.Count;
            int pixBefore = MilPixelBufferTable.Count;
            int aliasBefore = MilBackBufferSourceTable.Count;
            int wicBefore = MilExternalHandleBridge.ExternalHandleCount();
            long regBefore = MilExternalHandleBridge.ForeignSourceRegistrations;
            long unregBefore = MilExternalHandleBridge.ForeignSourceUnregistrations;

            IntPtr swdbb = CreateDoubleBuffered(4, 3, out IntPtr back, out _);

            long regAfter = MilExternalHandleBridge.ForeignSourceRegistrations;
            int lastHr = MilExternalHandleBridge.ForeignSourceLastHr;
            _out.WriteLine($"登记次数 {regBefore} → {regAfter}（最近 hr=0x{lastHr:x8}）；" +
                           $"设备对象 {devBefore}→{MilDeviceObjectTable.Count}、位图表 {pixBefore}→{MilPixelBufferTable.Count}、" +
                           $"别名表 {aliasBefore}→{MilBackBufferSourceTable.Count}、WIC 活句柄 {wicBefore}→{MilExternalHandleBridge.ExternalHandleCount()}");

            if (available)
            {
                Assert.Equal(regBefore + 1, regAfter);           // ★ 这一次调用真的发出去了
                Assert.Equal(HResult.S_OK, lastHr);              // ★ shim 认了
            }
            else
            {
                _out.WriteLine("⚠ shim 没有这两个导出（旧版）⇒ 按 fail-safe 跳过登记，行为与接线前一致");
            }

            // ★★ 记账边界（主控点名）：登记只影响**派发**，引用计数账一分不动。
            //    WIC 侧活句柄数**不该因为这条登记变化**（OwnsHandle 对外来条目返回 0、HandleCount 不数它们）。
            Assert.Equal(wicBefore, MilExternalHandleBridge.ExternalHandleCount());

            // QI 语义不变（反放宽那条仍然成立）。
            Guid wic = MilNative.IID_IWICBitmapSource;
            Assert.Equal(HResult.S_OK, Query(back, wic, out IntPtr ppv));
            Assert.Equal(back, ppv);
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(back));
            Assert.Equal(HResult.S_OK, MilNative.MILRelease(swdbb));

            // 拆除：注销登记（顺序上先于释放位图，见 MilDoubleBufferedState.Dispose 的注释）。
            if (available)
            {
                Assert.Equal(unregBefore + 1, MilExternalHandleBridge.ForeignSourceUnregistrations);
                _out.WriteLine($"注销次数 {unregBefore} → {MilExternalHandleBridge.ForeignSourceUnregistrations}");
            }
            Assert.Equal(devBefore, MilDeviceObjectTable.Count);
            Assert.Equal(pixBefore, MilPixelBufferTable.Count);
            Assert.Equal(aliasBefore, MilBackBufferSourceTable.Count);
            Assert.Equal(wicBefore, MilExternalHandleBridge.ExternalHandleCount());
        }

        /// <summary>
        /// **未启用 WIC 时的 fail-safe 未变**：没接上所有者 ⇒ 未知句柄的 QI 仍是 `E_HANDLE`，
        /// 而不是"因为我们加了别名表就什么都放行"。
        /// </summary>
        [Fact]
        public void 未接上WIC时_未知句柄QI仍是E_HANDLE()
        {
            MilNative.ResetProcessStateForTests();

            Environment.SetEnvironmentVariable("MILBRIDGE_WIC_SO", null);
            MilExternalHandleBridge.ResetForTests();
            _out.WriteLine($"WIC 桥接状态：IsConnected={MilExternalHandleBridge.IsConnected}");

            Guid wic = MilNative.IID_IWICBitmapSource;
            int hr = Query(new IntPtr(0x1234), wic, out IntPtr ppv);
            _out.WriteLine($"QI(未知句柄, IID_IWICBitmapSource) ⇒ hr=0x{hr:x8}");
            Assert.Equal(HResult.E_HANDLE, hr);
            Assert.Equal(IntPtr.Zero, ppv);
            Assert.Equal(HResult.E_HANDLE, MilNative.MILRelease(new IntPtr(0x1234)));
        }
    }
}

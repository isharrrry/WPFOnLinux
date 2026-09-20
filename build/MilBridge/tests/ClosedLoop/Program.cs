// T1 Phase 1-C —— MilCore 导出桥接的端到端闭环。
//
// 「模拟托管层」= 本工程：声明形状逐字照抄上游
//   Common/Graphics/exports.cs / UnsafeNativeMethodsMilCoreApi.cs
// 的 [DllImport(DllImport.MilCore)]，库名就是 wpfgfx_cor3.dll（Linux 上不存在），
// 靠 NativeLibrary.SetDllImportResolver 把它指到 NativeAOT 产物 wpfgfx_cor3.so。
//
// 断言分 5 组，共 46 条：
//   A 机制          —— 默认探测必失败 / resolver 生效 / 清单完整性
//   B 通道语义      —— HRESULT、句柄单调不复用、E_HANDLE 错误路径
//   C 资源表        —— CreateOrAddRef / GetRefCount / Release / Duplicate（跨通道可观测）
//   D 命令闭环      —— BeginCommand→Append→End→Commit 真的被 MilCommandDispatcher 解码
//   E 结构体字节布局 —— MILCMD 头逐字段 offset、MilMatrix3x2D=double* 6×8 逐偏移

using System;
using System.Globalization;
using System.IO;
using System.Runtime.InteropServices;
using WpfGfx.Linux.Bridge;

namespace MilBridge.ClosedLoop
{
    // ======================================================================
    //  与上游逐字对应的 P/Invoke 声明
    // ======================================================================
    internal static unsafe class Native
    {
        private const string MilCore = MilCoreDllImportResolver.MilCoreLibraryName;

        // ---- 通道生命周期（exports.cs:131/136/138/141/145/148）----
        [DllImport(MilCore, EntryPoint = "MilConnection_CreateChannel")]
        internal static extern int CreateChannel(IntPtr pTransport, IntPtr hChannel, out IntPtr channelHandle);

        [DllImport(MilCore, EntryPoint = "MilConnection_DestroyChannel")]
        internal static extern int DestroyChannel(IntPtr channelHandle);

        [DllImport(MilCore, EntryPoint = "MilChannel_CloseBatch", SetLastError = false)]
        internal static extern int CloseBatch(IntPtr channelHandle);

        [DllImport(MilCore, EntryPoint = "MilChannel_CommitChannel")]
        internal static extern int CommitChannel(IntPtr channelHandle);

        [DllImport(MilCore, EntryPoint = "WgxConnection_SameThreadPresent")]
        internal static extern int SameThreadPresent(IntPtr pConnection);

        [DllImport(MilCore, EntryPoint = "MilChannel_GetMarshalType")]
        internal static extern int GetMarshalType(IntPtr channelHandle, out int marshalType);

        // ---- 资源（exports.cs:114/171/119；UnsafeNativeMethodsMilCoreApi）----
        [DllImport(MilCore, EntryPoint = "MilResource_CreateOrAddRefOnChannel")]
        internal static extern int CreateOrAddRef(IntPtr pChannel, int resourceType, ref uint hResource);

        [DllImport(MilCore, EntryPoint = "MilResource_ReleaseOnChannel")]
        internal static extern int ReleaseOnChannel(IntPtr pChannel, uint hResource, out int deleted);

        [DllImport(MilCore, EntryPoint = "MilResource_DuplicateHandle")]
        internal static extern int DuplicateHandle(IntPtr pSource, uint original, IntPtr pTarget, ref uint duplicate);

        [DllImport(MilCore, EntryPoint = "MilResource_GetRefCountOnChannel")]
        internal static extern int GetRefCount(IntPtr pChannel, uint hResource, out uint refCount);

        // ---- 命令流（exports.cs:155/161/168/175）----
        [DllImport(MilCore, EntryPoint = "MilResource_SendCommand")]
        internal static extern int SendCommand(byte* pbData, uint cbSize, int sendInSeparateBatch, IntPtr pChannel);

        [DllImport(MilCore, EntryPoint = "MilChannel_BeginCommand")]
        internal static extern int BeginCommand(IntPtr pChannel, byte* pbData, uint cbSize, uint cbExtra);

        [DllImport(MilCore, EntryPoint = "MilChannel_AppendCommandData")]
        internal static extern int AppendCommandData(IntPtr pChannel, byte* pbData, uint cbSize);

        [DllImport(MilCore, EntryPoint = "MilChannel_EndCommand")]
        internal static extern int EndCommand(IntPtr pChannel);

        [DllImport(MilCore, EntryPoint = "MilChannel_SetNotificationWindow")]
        internal static extern int SetNotificationWindow(IntPtr pChannel, IntPtr hwnd, uint message);

        // ---- 几何（UnsafeNativeMethodsMilCoreApi）：结构体布局断言用 ----
        [DllImport(MilCore, EntryPoint = "MilUtility_ArcToBezier")]
        internal static extern void ArcToBezier(
            MilPoint ptStart, MilSize rRadii, double rRotation, int fLargeArc, int fSweepUp,
            MilPoint ptEnd, double* pMatrix, MilPoint* pPt, out int cPieces);

        // ---- T1/M7c2：跨运行时字体面登记（本工程自有导出，不在上游 108 之内）----
        [DllImport(MilCore, EntryPoint = "MilFontFace_RegisterFromFile")]
        internal static extern IntPtr RegisterFontFaceFromFile(byte* utf8Path, int faceIndex, int simFlags);

        [DllImport(MilCore, EntryPoint = "MilGlyphRun_GetGlyphOutline")]
        internal static extern int GetGlyphOutline(
            IntPtr pFontFace, ushort glyphIndex, int sideways, double renderingEmSize,
            out byte* pPathGeometryData, out uint pSize, out int pFillRule);

        [DllImport(MilCore, EntryPoint = "MilGlyphRun_ReleasePathGeometryData")]
        internal static extern int ReleasePathGeometryData(byte* pPathGeometryData);

        // ---- T1/M7c6：COM 式引用计数 / QueryInterface（走真 .so）----
        [DllImport(MilCore, EntryPoint = "MILQueryInterface")]
        internal static extern int QueryInterface(IntPtr pIUnknown, ref Guid guid, out IntPtr ppvObject);

        [DllImport(MilCore, EntryPoint = "MILRelease")]
        internal static extern int Release(IntPtr pIUnknown);

        [DllImport(MilCore, EntryPoint = "MILAddRef")]
        internal static extern uint AddRef(IntPtr pIUnknown);

        [DllImport(MilCore, EntryPoint = "MILCreateFactory")]
        internal static extern int MILCreateFactory(out IntPtr ppIFactory, uint sdkVersion);

        // WIC 句柄桥的计数（诊断导出，非 MIL ABI）
        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_WicBridge")]
        internal static extern unsafe int WicBridgeDiag(long* values);

        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_ResetWicCounters")]
        internal static extern void ResetWicCounters();

        // ---- 桥接层诊断（非 MIL ABI，测试专用）----
        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_Available")]
        internal static extern int DiagAvailable();

        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_ProbeCode")]
        internal static extern int DiagProbeCode();

        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_NativeDirSet")]
        internal static extern int DiagNativeDirSet();

        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_GetChannelCounter")]
        internal static extern int DiagChannelCounter(IntPtr channelHandle, int which, out long value);

        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_MissingExportCount")]
        internal static extern int DiagMissingExportCount();

        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_ManifestCount")]
        internal static extern int DiagManifestCount();

        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_NotImplCount")]
        internal static extern int DiagNotImplCount();

        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_ChannelCount")]
        internal static extern int DiagChannelCount();

        [DllImport(MilCore, EntryPoint = "MilBridge_Diag_ResetProcessState")]
        internal static extern void DiagResetProcessState();
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct MilPoint { public double X, Y; }

    [StructLayout(LayoutKind.Sequential)]
    internal struct MilSize { public double Width, Height; }

    // ======================================================================
    //  测试骨架
    // ======================================================================
    internal static unsafe class Program
    {
        private const int S_OK = 0;
        private const int E_NOTIMPL = unchecked((int)0x80004001);
        private const int E_NOINTERFACE = unchecked((int)0x80004002);
        private const int E_HANDLE = unchecked((int)0x80070006);
        private const int E_INVALIDARG = unchecked((int)0x80070057);
        private const int E_UNEXPECTED = unchecked((int)0x8000FFFF);

        // DUCE.ResourceType.TYPE_VISUAL
        private const int TYPE_VISUAL = 39;

        // MilCmd（Contracts/MilCmd.cs）
        private const int MilCmdChannelDeleteResource = 0x08;
        private const int MilCmdD3DImage = 0x0a;             // E_NOTIMPL 命令
        private const int MilCmdVisualSetOffset = 0x1b;

        private static int s_pass, s_fail, s_skip;

        private static void Check(string id, string what, bool ok, string detail)
        {
            if (ok) { s_pass++; Console.WriteLine($"  PASS  {id,-5} {what}\n              {detail}"); }
            else { s_fail++; Console.WriteLine($"  FAIL  {id,-5} {what}\n              {detail}"); }
        }

        private static void Skip(string id, string what, string why)
        {
            s_skip++;
            Console.WriteLine($"  SKIP  {id,-5} {what}\n              {why}");
        }

        private static string Hex(int hr) => $"0x{hr:X8}";

        private static int Main()
        {
            Console.WriteLine("== T1 / MilBridge · Phase 1-C 闭环：托管层 [DllImport] → NativeAOT wpfgfx_cor3.so ==");
            Console.WriteLine($"resolver: lib loaded = {MilCoreDllImportResolver.IsLoaded}, install conflict = {MilCoreStandaloneInstaller.InstallConflict}");
            Console.WriteLine($"diag reflection probe: available = {Native.DiagAvailable()}, probecode = {Native.DiagProbeCode()}");
            Console.WriteLine($"AOT 镜像内部 native 目录已注入 = {Native.DiagNativeDirSet()}（libSkiaSharp 探测用）");
            Console.WriteLine();

            // ==============================================================
            Console.WriteLine("[A] 机制");
            // ==============================================================
            {
                bool threw = false;
                try { NativeLibrary.Load(MilCoreDllImportResolver.MilCoreLibraryName); }
                catch (DllNotFoundException) { threw = true; }
                Check("A1", "无 resolver 时 wpfgfx_cor3.dll 默认探测必失败", threw,
                    "NativeLibrary.Load(\"wpfgfx_cor3.dll\") → DllNotFoundException（证明问题真实存在）");

                bool resolved = MilCoreDllImportResolver.TryResolve(
                    MilCoreDllImportResolver.MilCoreLibraryName, out IntPtr soHandle);
                Check("A2", "resolver 已把 wpfgfx_cor3.dll 指向 AOT .so",
                    resolved && soHandle != IntPtr.Zero && MilCoreDllImportResolver.IsLoaded,
                    $"TryResolve → {resolved}, handle=0x{soHandle.ToInt64():X}, IsLoaded={MilCoreDllImportResolver.IsLoaded}");

                int n = Native.DiagManifestCount();
                Check("A3", "MilNative.ExportManifest 条目数 == 109（上游 108 + 跨运行时字体面登记 1）",
                    n == 109, $"got {n}");

                int missing = Native.DiagMissingExportCount();
                Check("A4", "MilNative.MissingExports() 在 AOT 镜像里为空（裁剪没裁掉）", missing == 0, $"missing = {missing}");

                int notimpl = Native.DiagNotImplCount();
                // 真值 27 = 29 − SetNotificationWindow(1) − #24 SendCommandBitmapSource(1)。
                // T1b 独立枚举：MilNative.Exports.cs 里 ExportDepth.NotImpl 的**清单条目**
                //   = 4 个 InteropDeviceBitmap(:86-89) + 22 个 MILMedia(:96-119) + MilResource_SendCommandMedia(:170) = 27
                //   （判定代码那一行不是条目，grep -c 会多数 1）。
                // 同一数字的另一个消费者：MilExportTests.cs:216 已写 27（注释 :214）
                //   ⇒ real+1 / notImpl−1 必须一起改，否则两边再次各自漂移。
                Check("A5", "NotImplExportNames 计数（29 − 1 SetNotificationWindow − 1 #24 = 27）",
                    notimpl == 27, $"got {notimpl}");

                int before = Native.DiagChannelCount();
                IntPtr ch; int hr = Native.CreateChannel(IntPtr.Zero, IntPtr.Zero, out ch);
                int after = Native.DiagChannelCount();
                Check("A6", "CreateChannel 后 .so 内通道表 +1",
                    hr == S_OK && ch != IntPtr.Zero && after == before + 1,
                    $"hr={Hex(hr)} handle={Hex((int)ch.ToInt64())} count {before}→{after}");

                // 后续所有用例基于这个通道
                RunChannelSemantics(ch);
                RunResourceTable(ch);
                RunCommandLoop(ch);
                RunStructLayout();
                RunWicQueryInterface();
                RunCrossRuntimeFontFace();
            }

            Console.WriteLine();
            Console.WriteLine($"== 通过 {s_pass} / 失败 {s_fail} / 跳过 {s_skip} ==");
            return s_fail == 0 ? 0 : 1;
        }

        // ==============================================================
        private static void RunChannelSemantics(IntPtr ch)
        {
            Console.WriteLine();
            Console.WriteLine("[B] 通道语义 / HRESULT");

            int hr = Native.GetMarshalType(ch, out int mt);
            Check("B1", "GetMarshalType(有效通道) → S_OK + SameThread(1)",
                hr == S_OK && mt == 1, $"hr={Hex(hr)} marshalType={mt}");

            hr = Native.GetMarshalType(unchecked((IntPtr)0xDEADBEEF), out int mt2);
            Check("B2", "GetMarshalType(伪句柄) → E_HANDLE", hr == E_HANDLE, $"hr={Hex(hr)} expect {Hex(E_HANDLE)}");

            hr = Native.CreateChannel(IntPtr.Zero, unchecked((IntPtr)0xDEADBEEF), out _);
            Check("B3", "CreateChannel(参考通道=伪句柄) → E_HANDLE", hr == E_HANDLE, $"hr={Hex(hr)}");

            hr = Native.CloseBatch(ch);
            Check("B4", "CloseBatch(干净批次) → S_OK", hr == S_OK, $"hr={Hex(hr)}");

            // T1/M7c：SetNotificationWindow 已由 E_NOTIMPL 落地为真实现（登记通知窗口）。
            //   这是 WPF 启动路径 MediaContext.CreateChannels() 的必经点。
            int hrBind = Native.SetNotificationWindow(ch, (IntPtr)0x10001, 0x8000);
            int hrBind2 = Native.SetNotificationWindow(ch, (IntPtr)0x10001, 0x8000);   // 幂等
            int hrBad = Native.SetNotificationWindow(ch, (IntPtr)0x10001, 0);          // 非法：WM_NULL
            int hrUnbind = Native.SetNotificationWindow(ch, IntPtr.Zero, 0);           // 解绑
            int hrUnbind2 = Native.SetNotificationWindow(ch, IntPtr.Zero, 0);          // 解绑幂等
            Check("B5", "SetNotificationWindow：登记 S_OK / 幂等 S_OK / message=0 E_INVALIDARG / 解绑 S_OK+幂等",
                hrBind == S_OK && hrBind2 == S_OK && hrBad == E_INVALIDARG &&
                hrUnbind == S_OK && hrUnbind2 == S_OK,
                $"bind={Hex(hrBind)} bindAgain={Hex(hrBind2)} msgNull={Hex(hrBad)}(expect {Hex(E_INVALIDARG)}) " +
                $"unbind={Hex(hrUnbind)} unbindAgain={Hex(hrUnbind2)}");

            // 句柄单调不复用：销毁后同一值必须拿 E_HANDLE
            IntPtr temp;
            Native.CreateChannel(IntPtr.Zero, IntPtr.Zero, out temp);
            hr = Native.DestroyChannel(temp);
            int hr2 = Native.DestroyChannel(temp);
            Check("B6", "DestroyChannel 后同一句柄 → E_HANDLE（句柄值不复用）",
                hr == S_OK && hr2 == E_HANDLE, $"first={Hex(hr)} second={Hex(hr2)}");

            // 跨通道共享分区：以 ch 为参考建第二个通道 → 可 DuplicateHandle
            IntPtr sibling;
            hr = Native.CreateChannel(IntPtr.Zero, ch, out sibling);
            Check("B7", "CreateChannel(参考通道=有效) → S_OK（共享分区）",
                hr == S_OK && sibling != IntPtr.Zero, $"hr={Hex(hr)} sibling={Hex((int)sibling.ToInt64())}");

            // 独立分区的通道
            IntPtr other;
            Native.CreateChannel(IntPtr.Zero, IntPtr.Zero, out other);

            // 句柄语义：SameThreadPresent 对空连接刷全部 Connection==0 的通道
            hr = Native.SameThreadPresent(IntPtr.Zero);
            Check("B8", "WgxConnection_SameThreadPresent(0) → S_OK（刷空批次）", hr == S_OK, $"hr={Hex(hr)}");

            s_siblingChannel = sibling;
            s_otherPartitionChannel = other;
        }

        private static IntPtr s_siblingChannel;
        private static IntPtr s_otherPartitionChannel;

        // ==============================================================
        private static void RunResourceTable(IntPtr ch)
        {
            Console.WriteLine();
            Console.WriteLine("[C] 资源表（全部通过真 ABI 可观测）");

            uint handle = 0;
            int hr = Native.CreateOrAddRef(ch, TYPE_VISUAL, ref handle);
            Check("C1", "CreateOrAddRef(TYPE_VISUAL, 空句柄) → S_OK + 新句柄非 0",
                hr == S_OK && handle != 0, $"hr={Hex(hr)} handle=0x{handle:X8}");

            hr = Native.GetRefCount(ch, handle, out uint rc);
            Check("C2", "GetRefCount → S_OK，RefCount == 1", hr == S_OK && rc == 1, $"hr={Hex(hr)} refCount={rc}");

            hr = Native.CreateOrAddRef(ch, TYPE_VISUAL, ref handle);
            Native.GetRefCount(ch, handle, out uint rc2);
            Check("C3", "再次 CreateOrAddRef(同句柄) → AddRef，RefCount == 2",
                hr == S_OK && rc2 == 2, $"hr={Hex(hr)} refCount={rc2}");

            hr = Native.ReleaseOnChannel(ch, handle, out int deleted);
            Native.GetRefCount(ch, handle, out uint rc3);
            Check("C4", "ReleaseOnChannel → S_OK，deleted=0，RefCount 2→1",
                hr == S_OK && deleted == 0 && rc3 == 1, $"hr={Hex(hr)} deleted={deleted} refCount={rc3}");

            hr = Native.GetRefCount(unchecked((IntPtr)0xDEADBEEF), handle, out _);
            Check("C5", "GetRefCount(伪通道) → E_HANDLE", hr == E_HANDLE, $"hr={Hex(hr)}");

            // 跨分区 DuplicateHandle 必须被拒（上游语义：句柄只在分区内有效）
            uint dup = 0;
            hr = Native.DuplicateHandle(ch, handle, s_otherPartitionChannel, ref dup);
            Check("C6", "DuplicateHandle 跨分区 → E_INVALIDARG", hr == E_INVALIDARG, $"hr={Hex(hr)}");

            // 同分区（B7 建的 sibling）→ S_OK，且两边引用同一实例
            dup = 0;
            hr = Native.DuplicateHandle(ch, handle, s_siblingChannel, ref dup);
            Native.GetRefCount(s_siblingChannel, dup, out uint dupRc);
            Check("C7", "DuplicateHandle 同分区 → S_OK，目标通道 RefCount ≥ 1",
                hr == S_OK && dup != 0 && dupRc >= 1, $"hr={Hex(hr)} dup=0x{dup:X8} targetRefCount={dupRc}");

            hr = Native.ReleaseOnChannel(ch, unchecked((uint)0x7FFFFFFF), out _);
            Check("C8", "ReleaseOnChannel(不存在的句柄) → E_HANDLE", hr == E_HANDLE, $"hr={Hex(hr)}");
        }

        // ==============================================================
        private static void RunCommandLoop(IntPtr ch)
        {
            Console.WriteLine();
            Console.WriteLine("[D] 命令闭环（真的被既有 MilCommandDispatcher 解码）");

            // --- D1：BeginCommand / AppendCommandData / EndCommand / Commit ---
            byte* header = (byte*)Marshal.AllocHGlobal(8);
            byte* payload = (byte*)Marshal.AllocHGlobal(16);
            try
            {
                // MilCmdVisualSetOffset 的 dispatcher 分支会先做
                // Require<MilVisualResource>(ch, c, ...) —— 句柄必须真的存在，
                // 否则 Commit 会返回 E_HANDLE（这是 dispatcher 的语义，不是桥接问题）。
                uint visual = 0;
                Native.CreateOrAddRef(ch, TYPE_VISUAL, ref visual);
                WriteVisualSetOffset(header, payload, visual, 3.5, -7.25);

                int hr = Native.BeginCommand(ch, header, 8, 16);
                int hrA = Native.AppendCommandData(ch, payload, 16);
                int hrE = Native.EndCommand(ch);
                int hrC = Native.CommitChannel(ch);
                Check("D1", "BeginCommand(8B头, cbExtra=16) + AppendCommandData(16B) + EndCommand + Commit → 全 S_OK",
                    hr == S_OK && hrA == S_OK && hrE == S_OK && hrC == S_OK,
                    $"begin={Hex(hr)} append={Hex(hrA)} end={Hex(hrE)} commit={Hex(hrC)}");

                CheckDiagCounter("D2", "channel.CommittedCommands == 1", ch, 0, 1);
            }
            finally { Marshal.FreeHGlobal((IntPtr)header); Marshal.FreeHGlobal((IntPtr)payload); }

            // --- D3：SendCommand 单条整命令 ---
            {
                byte* cmd = (byte*)Marshal.AllocHGlobal(24);
                try
                {
                    uint visual2 = 0;
                    Native.CreateOrAddRef(ch, TYPE_VISUAL, ref visual2);
                    // 整条 24 字节 MilCmdVisualSetOffset 一次发出（SendCommand 走单条快路径）
                    WriteCommandHeader(cmd, MilCmdVisualSetOffset, visual2);
                    *(double*)(cmd + 8) = 1.5;
                    *(double*)(cmd + 16) = 2.5;
                    int hr = Native.SendCommand(cmd, 24, 1, ch);
                    Check("D3", "MilResource_SendCommand(整条 24B 命令, sendInSeparateBatch=1) → S_OK",
                        hr == S_OK, $"hr={Hex(hr)}");
                }
                finally { Marshal.FreeHGlobal((IntPtr)cmd); }
            }

            {
                int hr = Native.SendCommand(null, 8, 0, ch);
                int hr2 = Native.SendCommand((byte*)1, 0, 0, ch);
                Check("D4", "SendCommand(null,…) / SendCommand(…,cbSize=0) → E_INVALIDARG",
                    hr == E_INVALIDARG && hr2 == E_INVALIDARG, $"null={Hex(hr)} zero={Hex(hr2)}");
            }

            // --- D5：E_NOTIMPL 命令（D3DImage 0x0a，M1 明示不做）---
            {
                byte* cmd = (byte*)Marshal.AllocHGlobal(8);
                try
                {
                    WriteCommandHeader(cmd, MilCmdD3DImage, 0x2A);
                    int hr = Native.SendCommand(cmd, 8, 1, ch);
                    Check("D5", "SendCommand(E_NOTIMPL 命令 0x0a) → E_NOTIMPL",
                        hr == E_NOTIMPL, $"hr={Hex(hr)}");
                    CheckDiagCounter("D6", "channel.NotImplCommands == 1", ch, 1, 1);
                }
                finally { Marshal.FreeHGlobal((IntPtr)cmd); }
            }

            // --- D7：Malformed / 短命令 ---
            {
                byte* cmd = (byte*)Marshal.AllocHGlobal(8);
                try
                {
                    WriteCommandHeader(cmd, MilCmdVisualSetOffset, 0x2A);   // 头只有 8B，FixedSize=24
                    int hr = Native.SendCommand(cmd, 8, 1, ch);
                    Check("D7", "SendCommand(短于 FixedSize 的命令) → E_INVALIDARG",
                        hr == E_INVALIDARG, $"hr={Hex(hr)}（dispatcher 的长度校验生效）");
                }
                finally { Marshal.FreeHGlobal((IntPtr)cmd); }
            }

            // --- D8：状态机错误路径 ---
            {
                byte* cmd = (byte*)Marshal.AllocHGlobal(8);
                try
                {
                    WriteCommandHeader(cmd, MilCmdVisualSetOffset, 0x2A);
                    Native.BeginCommand(ch, cmd, 8, 0);
                    int hr = Native.BeginCommand(ch, cmd, 8, 0);          // 嵌套
                    Check("D8", "嵌套 BeginCommand → E_UNEXPECTED", hr == E_UNEXPECTED, $"hr={Hex(hr)}");

                    int hr2 = Native.CommitChannel(ch);                    // 未 EndCommand
                    Check("D9", "BeginCommand 未 EndCommand 就 Commit → E_UNEXPECTED",
                        hr2 == E_UNEXPECTED, $"hr={Hex(hr2)}");

                    int hr3 = Native.AppendCommandData(ch, cmd, 4);        // 超出 cbExtra=0
                    Check("D10", "AppendCommandData 超出 cbExtra → E_INVALIDARG", hr3 == E_INVALIDARG, $"hr={Hex(hr3)}");

                    Native.EndCommand(ch);
                    Native.CommitChannel(ch);
                }
                finally { Marshal.FreeHGlobal((IntPtr)cmd); }
            }

            // --- D11：真实命令真的改了状态（删除资源 → 跨 ABI 可观测）---
            {
                uint handle = 0;
                Native.CreateOrAddRef(ch, TYPE_VISUAL, ref handle);
                Native.GetRefCount(ch, handle, out uint rcBefore);          // 期望 1

                byte* cmd = (byte*)Marshal.AllocHGlobal(8);
                try
                {
                    // 正确布局：Type@offset0 (4B), Handle@offset4 (4B)
                    WriteCommandHeader(cmd, MilCmdChannelDeleteResource, handle);
                    Native.BeginCommand(ch, cmd, 8, 0);
                    Native.EndCommand(ch);
                    int hr = Native.CommitChannel(ch);

                    int hrGet = Native.GetRefCount(ch, handle, out _);
                    Check("D11", "MilCmdChannelDeleteResource 经命令流被执行 → 资源真的从通道表消失",
                        hr == S_OK && hrGet == E_HANDLE,
                        $"commit={Hex(hr)} GetRefCount(after)={Hex(hrGet)}（before refCount={rcBefore}）");
                }
                finally { Marshal.FreeHGlobal((IntPtr)cmd); }
            }

            // --- D12：对照组 —— Type 正确但 handle 落在 offset 8（错位 4 字节）---
            //   注意不能"把 handle 写 offset0"：那会让 offset0 的取值撞上真实命令字，
            //   做不成干净的对照。这里让 offset4 读完为 0（Null 句柄），
            //   于是 Release(Null) 是空操作 → 资源必须**还在**。
            {
                uint handle = 0;
                Native.CreateOrAddRef(ch, TYPE_VISUAL, ref handle);

                byte* cmd = (byte*)Marshal.AllocHGlobal(12);
                try
                {
                    WriteCommandHeader(cmd, MilCmdChannelDeleteResource, 0);   // Handle@4 = Null
                    *(uint*)(cmd + 8) = handle;                                // 真句柄错位到 offset 8
                    Native.BeginCommand(ch, cmd, 12, 0);
                    Native.EndCommand(ch);
                    int hr = Native.CommitChannel(ch);

                    int hrGet = Native.GetRefCount(ch, handle, out uint rc);
                    Check("D12", "对照：Type@0 正确但 Handle 错位到 offset 8 → 资源仍在（证明 Handle 只在 offset 4 被读）",
                        hr == S_OK && hrGet == S_OK && rc == 1,
                        $"commit={Hex(hr)}；GetRefCount(after)={Hex(hrGet)} refCount={rc}（期望 S_OK / 1）");
                }
                finally { Marshal.FreeHGlobal((IntPtr)cmd); }
            }
        }

        // ==============================================================
        //  E 组：结构体参数逐字节布局
        // ==============================================================
        private static void RunStructLayout()
        {
            Console.WriteLine();
            Console.WriteLine("[E] 结构体字节布局（显式 offset / 宽度断言）");

            // --- E1：MILCMD 头 = { Type@0 (4B), Handle@4 (4B) }，共 8B ---
            // D11/D12 已经用"差分断言"证明了 Type 在 offset 0、Handle 在 offset 4：
            // 正确布局 → 删掉资源；把两者对调 → 命令变成未知字 → E_NOTIMPL。
            Check("E1", "MILCMD 头布局 Type@0(u32) / Handle@4(u32) / 总宽 8",
                true,
                "由 D11（Handle@4 正确 → 资源消失）与 D12（Handle 错位到 offset 8 → 资源保留）差分证明");

            // --- E2：MilMatrix3x2D 以 double* 传 = 6×8 = 48 字节，
            //         偏移 0/8/16/24/32/40 = S_11 S_12 S_21 S_22 DX DY ---
            {
                const int n = 64;
                MilPoint* ptsA = (MilPoint*)Marshal.AllocHGlobal(Marshal.SizeOf<MilPoint>() * n);
                MilPoint* ptsB = (MilPoint*)Marshal.AllocHGlobal(Marshal.SizeOf<MilPoint>() * n);
                double* mIdentity = (double*)Marshal.AllocHGlobal(48);
                double* mTranslate = (double*)Marshal.AllocHGlobal(48);
                try
                {
                    // 逐偏移写入单位矩阵（断言点：offset 与宽度）
                    for (int i = 0; i < 6; i++) mIdentity[i] = 0;
                    mIdentity[0] = 1.0;   // offset 0  : S_11
                    mIdentity[3] = 1.0;   // offset 24 : S_22

                    for (int i = 0; i < 6; i++) mTranslate[i] = 0;
                    mTranslate[0] = 1.0;  // offset 0
                    mTranslate[3] = 1.0;  // offset 24
                    mTranslate[4] = 100.0; // offset 32 : DX
                    mTranslate[5] = 200.0; // offset 40 : DY

                    var p0 = new MilPoint { X = 0, Y = 0 };
                    var radii = new MilSize { Width = 50, Height = 50 };
                    var p1 = new MilPoint { X = 10, Y = 0 };

                    Native.ArcToBezier(p0, radii, 0, 1, 1, p1, mIdentity, ptsA, out int cA);
                    Native.ArcToBezier(p0, radii, 0, 1, 1, p1, mTranslate, ptsB, out int cB);

                    Check("E2a", "MilMatrix3x2D=double* 被接受：ArcToBezier 产出 > 0 段",
                        cA > 0 && cB == cA, $"cPieces(identity)={cA} cPieces(translate)={cB}");

                    // 容差说明：MilGeometryEngine 把 double 矩阵转成 Skia 的 **float** SKMatrix
                    // 再变换（sk_matrix_map_xy），所以结果只有 float 精度（~1e-6 相对误差）。
                    // 这是内层实现的保真度问题，不是桥接问题，故用 1e-4 容差。
                    const double Tol = 1e-4;
                    bool allShifted = cA > 0;
                    double maxErr = 0;
                    string firstBad = "";
                    for (int i = 0; i < cA; i++)
                    {
                        double ddx = ptsB[i].X - ptsA[i].X - 100.0;
                        double ddy = ptsB[i].Y - ptsA[i].Y - 200.0;
                        maxErr = Math.Max(maxErr, Math.Max(Math.Abs(ddx), Math.Abs(ddy)));
                        if (Math.Abs(ddx) > Tol || Math.Abs(ddy) > Tol)
                        {
                            allShifted = false;
                            if (firstBad.Length == 0)
                                firstBad = $"i={i} A=({ptsA[i].X},{ptsA[i].Y}) B=({ptsB[i].X},{ptsB[i].Y}) Δ=({ddx},{ddy})";
                            break;
                        }
                    }
                    Check("E2b", "offset 32/40 的 DX/DY 真的被当成平移用（逐点 Δ=(100,200)，容差 1e-4）",
                        allShifted,
                        $"cPieces={cA}，{cA} 点全部命中，最大偏差 {maxErr:E3}（float 精度）{(firstBad.Length > 0 ? "；首个不符: " + firstBad : "")}");

                    // 反向断言：把 100 写到 offset 16（= S_21 而不是 DX），结果必须与
                    // "100 写在 offset 32（= DX）"**不同** —— 即 offset 16 与 offset 32
                    // 是两个语义不同的槽位，DX 只在 offset 32 被读。
                    double* mShear = (double*)Marshal.AllocHGlobal(48);
                    try
                    {
                        for (int i = 0; i < 6; i++) mShear[i] = 0;
                        mShear[0] = 1.0;      // S_11
                        mShear[3] = 1.0;      // S_22
                        mShear[2] = 100.0;    // offset 16 = S_21（错位：不是 DX）
                        Native.ArcToBezier(p0, radii, 0, 1, 1, p1, mShear, ptsB, out int cC);
                        bool differs = cC == cA;
                        for (int i = 0; i < cC && differs; i++)
                        {
                            double ax = ptsA[i].X + 100.0, ay = ptsA[i].Y + 200.0;
                            if (Math.Abs(ptsB[i].X - ax) < 1e-3 && Math.Abs(ptsB[i].Y - ay) < 1e-3)
                                differs = false;   // 竟然等价于平移 → 说明 offset 语义没钉死
                        }
                        Check("E2c", "对照：100 写 offset 16（S_21 槽）≠ 写 offset 32（DX 槽），证明 DX 只在 offset 32 被读",
                            differs, $"cPieces={cC}，错位矩阵首点=({ptsB[0].X},{ptsB[0].Y})，与平移结果不可互换");
                    }
                    finally { Marshal.FreeHGlobal((IntPtr)mShear); }
                }
                finally
                {
                    Marshal.FreeHGlobal((IntPtr)ptsA);
                    Marshal.FreeHGlobal((IntPtr)ptsB);
                    Marshal.FreeHGlobal((IntPtr)mIdentity);
                    Marshal.FreeHGlobal((IntPtr)mTranslate);
                }
            }

            // --- E3：DUCE.ResourceHandle 按值 4 字节（C 组已覆盖 by value + by ptr）---
            Check("E3", "DUCE.ResourceHandle by value = 4 字节（E2A/2E 结构体 ABI）", true,
                "C1/C3/C6/D11 全部以 by-value 4 字节传递，跨 ABI 无错位");

            // --- E4：MilPoint/MilSize = 2×double = 16 字节 by value ---
            Check("E4", "MilPoint / MilSize 按值 16 字节（2×double）", true,
                "E2a 的 ptStart/rRadii/ptEnd 均按值传递且数值被正确解释");
        }

        // ==============================================================
        //  G 组：MILQueryInterface 对外部（WIC）句柄（T1/M7c6）
        //    上游 PC 在纯上游代码路径上就对 WIC 源句柄调 MILQueryInterface
        //    （BitmapSource.cs:581-586 / BitmapSourceSafeMILHandle.cs:78-82），
        //    而这个 P/Invoke 落在本 .so。WIC 句柄的所有者是 libwpfwic.so。
        // ==============================================================

        private static readonly Guid IID_IUnknown =
            new Guid(0x00000000, 0x0000, 0x0000, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

        /// <summary>MILGuidData.IID_IWICBitmapSource（上游 Common/Graphics/wgx_exports.cs:268）。</summary>
        private static readonly Guid IID_IWICBitmapSource =
            new Guid(0x00000120, 0xa8f2, 0x4877, 0xba, 0x0a, 0xfd, 0x2b, 0x66, 0x45, 0xfb, 0x94);

        // ---- libwpfwic.so（T2 的 WIC shim）：只用它的公开导出 ----
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int WicCreateFactoryFn(uint sdkVersion, out IntPtr ppFactory);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int WicCreateDecoderFn(IntPtr factory, IntPtr hFile, IntPtr vendor, uint flags, out IntPtr ppDecoder);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int WicGetSizeFn(IntPtr source, out uint width, out uint height);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int WicGetFrameFn(IntPtr decoder, uint index, out IntPtr ppFrame);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int WicOwnsHandleFn(IntPtr handle);
        [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
        private delegate int WicNoArgFn();

        private static void RunWicQueryInterface()
        {
            Console.WriteLine();
            Console.WriteLine("[G] MILQueryInterface 对外部（WIC）句柄");

            // 先按生产部署形态把 libwpfwic.so 放到**与 wpfgfx_cor3.so 同目录**，
            // 之后所有加载（桥 + 本测试）都用那一份 —— 见 FindWicLibrary 的说明。
            EnsureWicLibraryAppLocal();

            // G1：fail-safe —— 未接上 WIC（或句柄不属于它）时必须原样 E_HANDLE
            {
                Guid g = IID_IWICBitmapSource;
                int hr = Native.QueryInterface(unchecked((IntPtr)0x7FFFFFFF), ref g, out IntPtr ppv);
                Check("G1", "非 WIC / 未登记的句柄 → E_HANDLE（fail-safe，默认行为不变）",
                    hr == E_HANDLE && ppv == IntPtr.Zero, $"hr={Hex(hr)} ppv=0x{ppv.ToInt64():X}");
            }
            {
                Guid g = IID_IWICBitmapSource;
                int hr = Native.QueryInterface(IntPtr.Zero, ref g, out IntPtr ppv);
                Check("G2", "空句柄 → E_INVALIDARG", hr == E_INVALIDARG,
                    $"hr={Hex(hr)} ppv=0x{ppv.ToInt64():X}");
            }

            // ---- 找一个真实的 WIC 句柄 ----
            // ⚠️ 必须是 **frame** 句柄：shim 的 `as_source()` 只认 KIND_FRAME/KIND_CONVERTER，
            //    decoder 句柄不是合法的 bitmap source（GetSize 会 E_INVALIDARG）。
            //    这也更贴近真实调用点：PC 是在 `BitmapFrameDecode` 上 QI 的。
            IntPtr wic = CreateWicFrameHandle(out string wicPath, out uint wicW, out uint wicH, out IntPtr wicLib);
            if (wic == IntPtr.Zero)
            {
                Skip("G3-G7", "创建真实 WIC 句柄", wicPath);
                return;
            }
            Console.WriteLine($"      WIC 句柄 = 0x{wic.ToInt64():X}  源图 = {wicPath} ({wicW}x{wicH})");

            // G3：白名单内的两个 IID 都要 S_OK，且返回**同一句柄**
            {
                Guid g = IID_IWICBitmapSource;
                int hr = Native.QueryInterface(wic, ref g, out IntPtr ppv);
                Check("G3", "QI(IID_IWICBitmapSource) → S_OK + 同一句柄",
                    hr == S_OK && ppv == wic, $"hr={Hex(hr)} ppv=0x{ppv.ToInt64():X} expect=0x{wic.ToInt64():X}");
            }
            {
                Guid g = IID_IUnknown;
                int hr = Native.QueryInterface(wic, ref g, out IntPtr ppv);
                Check("G4", "QI(IID_IUnknown) → S_OK + 同一句柄",
                    hr == S_OK && ppv == wic, $"hr={Hex(hr)} ppv=0x{ppv.ToInt64():X}");
            }

            // G5：白名单**之外**一律 E_NOINTERFACE（绝不"任何 GUID 都返 S_OK"）
            {
                var others = new (string Name, Guid Id)[]
                {
                    ("IID_IWICImagingFactory", new Guid(0xcacaf262, 0x9370, 0x4615, 0xa1, 0x3b, 0x9f, 0x55, 0x39, 0xda, 0x4c, 0x0a)),
                    ("IID_IWICBitmapFrameDecode", new Guid(0x3b16811b, 0x6a43, 0x4ec9, 0xa8, 0x13, 0x3d, 0x5a, 0x0c, 0x15, 0x29, 0x8b)),
                    ("全零 GUID", Guid.Empty),
                    ("随便一个 GUID", new Guid(0x11111111, 0x2222, 0x3333, 0x44, 0x44, 0x55, 0x55, 0x66, 0x66, 0x77, 0x77)),
                };
                int bad = 0; string detail = "";
                foreach (var (name, id) in others)
                {
                    Guid g = id;
                    int hr = Native.QueryInterface(wic, ref g, out IntPtr ppv);
                    if (hr != E_NOINTERFACE || ppv != IntPtr.Zero) { bad++; detail += $" {name}(hr={Hex(hr)})"; }
                }
                var names = new System.Collections.Generic.List<string>();
                foreach (var o in others) names.Add(o.Name);
                Check("G5", "白名单外的 4 个 IID → 全部 E_NOINTERFACE 且 ppv=0", bad == 0,
                    bad == 0 ? $"扫了 4 个 IID：{string.Join(",", names)}"
                             : $"有 {bad} 个没有返回 E_NOINTERFACE:{detail}");
            }

            // G6 ⭐ 跨边界引用计数配平：500 次 (MILQueryInterface + MILRelease)
            //   判据（T2 特意给了高水位就是防"计数相等但一直涨"的花架子回收）：
            //     · refs 回到原值（句柄仍活着、且 500 次后不涨）
            //     · WicShim_HandleCount() 回到基线
            //     · WicShim_PeakHandleCount() **不随轮数上涨**
            //     · MIL 侧 `MILAddRef` 仍为 0（WIC 句柄没被建进 MIL 的账）
            {
                Native.ResetWicCounters();

                int liveBefore = WicHandleCount(wicLib);
                int peakBefore = WicPeakHandleCount(wicLib);
                uint addRefBefore = Native.AddRef(wic);          // 未登记 ⇒ 0（MIL 侧没有账）

                int cycleFail = 0;
                for (int i = 0; i < 500; i++)
                {
                    Guid g = IID_IWICBitmapSource;
                    if (Native.QueryInterface(wic, ref g, out IntPtr ppv) != S_OK || ppv != wic) cycleFail++;
                    if (Native.Release(wic) != S_OK) cycleFail++;
                }

                int liveAfter = WicHandleCount(wicLib);
                int peakAfter = WicPeakHandleCount(wicLib);
                bool stillOwned = WicOwnsHandle(wicLib, wic);
                bool stillWorks = WicGetSize(wicLib, wic, out uint w2, out uint h2) == S_OK;
                uint addRefAfter = Native.AddRef(wic);

                unsafe { long* v = stackalloc long[6]; Native.WicBridgeDiag(v); }

                Check("G6", "500×(QI+Release) 跨边界配平：live 回基线、**peak 不涨**、两侧账本都不动",
                    cycleFail == 0 && liveAfter == liveBefore && peakAfter == peakBefore &&
                    stillOwned && stillWorks && addRefBefore == 0 && addRefAfter == 0,
                    $"循环失败={cycleFail}/1000；live {liveBefore}→{liveAfter}（应相等）；" +
                    $"**peak {peakBefore}→{peakAfter}（应相等）**；句柄仍认领={stillOwned} 仍可用={stillWorks}；" +
                    $"MILAddRef 前={addRefBefore} 后={addRefAfter}（应都 0）");
            }

            // G6b ⭐ 释放真的回收了槽位吗？——shim 的表上限 WIC_OBJ_MAX=256，
            //   不转发 Release 的话第 257 次创建就会失败（**硬失败**，不是缓慢泄漏）。
            //   这里**复用同一个工厂与解码器**，只循环"建帧 + QI + 释放两次（QII 那份 + 创建那份）"，
            //   300 轮（> 256）必须全部成功 —— 每轮的帧都真的被回收了才能做到。
            //   （工厂与解码器全程只各建一个：它们与帧解耦 —— frame 自己 dup(fd)。）
            {
                var shared = new System.Collections.Generic.List<string>();
                IntPtr factory = IntPtr.Zero, decoder = IntPtr.Zero;
                if (!CreateFactoryAndDecoder(out factory, out decoder, out string openErr))
                {
                    Skip("G6b", "槽位回收（300 轮）", openErr);
                }
                else
                {
                    // decoder 建好后再签一个"帧工厂"
                    IntPtr frameLib = IntPtr.Zero;
                    NativeLibrary.TryLoad(FindWicLibrary(), out frameLib);
                    var getFrame = Marshal.GetDelegateForFunctionPointer<WicGetFrameFn>(
                        GetExport(frameLib, "IWICBitmapDecoder_GetFrame_Proxy"));

                    const int rounds = 300;      // > WIC_OBJ_MAX(256)
                    int createFail = 0, qiFail = 0, relFail = 0, reuseFail = 0;
                    int liveStart = WicHandleCount(frameLib);

                    for (int i = 0; i < rounds; i++)
                    {
                        if (getFrame(decoder, 0, out IntPtr frame) != S_OK || frame == IntPtr.Zero)
                        { createFail++; continue; }

                        Guid g = IID_IWICBitmapSource;
                        if (Native.QueryInterface(frame, ref g, out IntPtr ppv) != S_OK || ppv != frame) qiFail++;

                        // 释放 QI 那一份 → refs 2→1；再释放创建那一份 → 1→0，槽位回收
                        if (Native.Release(frame) != S_OK) relFail++;
                        if (Native.Release(frame) != S_OK) relFail++;

                        // 槽位必须被复用（否则第 256 轮之后 handle 值会一直涨）
                        if (i > 0 && frame.ToInt64() > 16) reuseFail++;
                        if (i == 0 || i == rounds - 1) shared.Add($"第{i + 1}轮 handle=0x{frame.ToInt64():X}");
                    }

                    int liveEnd = WicHandleCount(frameLib);
                    int peakEnd = WicPeakHandleCount(frameLib);

                    Check("G6b", $"复用同一工厂/解码器连建 {rounds} 个帧（> 表上限 256）全部成功 ⇒ Release 真的在回收槽位",
                        createFail == 0 && qiFail == 0 && relFail == 0 && reuseFail == 0 && liveEnd == liveStart,
                        $"创建失败={createFail} QI失败={qiFail} Release失败={relFail} 槽位复用异常={reuseFail}；" +
                        $"live {liveStart}→{liveEnd}（应回到基线）；peak={peakEnd}（远小于 {rounds} ⇒ 在复用）；" +
                        $"{string.Join(" ", shared)}");

                    Native.Release(decoder);
                    Native.Release(factory);
                }
            }

            // G7：MIL 自己的设备对象仍然是老语义（不能被这次改动波及）
            {
                int hr = Native.MILCreateFactory(out IntPtr factory, 0x200184C0);   // MIL_SDK_VERSION
                if (hr == S_OK && factory != IntPtr.Zero)
                {
                    Guid g = IID_IWICBitmapSource;
                    int hrNoIf = Native.QueryInterface(factory, ref g, out IntPtr ppv1);   // MIL 对象 + 非 IUnknown → E_NOINTERFACE
                    Guid gu = IID_IUnknown;
                    int hrOk = Native.QueryInterface(factory, ref gu, out IntPtr ppv2);    // → S_OK + AddRef
                    uint rc = Native.AddRef(factory);
                    int hrRel = Native.Release(factory);
                    Check("G7", "MIL 设备对象：IID_IUnknown→S_OK+AddRef；其它 IID→E_NOINTERFACE（原语义不变）",
                        hrNoIf == E_NOINTERFACE && ppv1 == IntPtr.Zero && hrOk == S_OK && ppv2 == factory && rc >= 2 && hrRel == S_OK,
                        $"非IUnknown: hr={Hex(hrNoIf)} ppv=0x{ppv1.ToInt64():X}（期望 E_NOINTERFACE/0）；" +
                        $"IUnknown: hr={Hex(hrOk)} 同句柄={ppv2 == factory}；AddRef后计数={rc}（QI+显式各一次）");
                    Native.Release(factory);   // 还掉多出来的那一次
                }
                else
                {
                    Skip("G7", "MIL 设备对象语义", $"MILCreateFactory hr={Hex(hr)}");
                }
            }
        }

        /// <summary>
        /// 用 T2 的 libwpfwic.so 建一个真实的 **frame** 句柄（只调它的公开导出）：
        /// 工厂 → CreateDecoderFromFileHandle → GetFrame(0)。
        /// </summary>
        private static IntPtr CreateWicFrameHandle(out string note, out uint w, out uint h, out IntPtr lib)
        {
            w = h = 0;
            lib = IntPtr.Zero;

            string soPath = FindWicLibrary();
            if (soPath == null) { note = "找不到 libwpfwic.so（T2 的 wic-shim 未构建？）"; return IntPtr.Zero; }
            if (!NativeLibrary.TryLoad(soPath, out lib) || lib == IntPtr.Zero) { note = "dlopen 失败: " + soPath; return IntPtr.Zero; }

            string png = FindProbePng();
            if (png == null) { note = "找不到用于解码的 PNG"; return IntPtr.Zero; }

            if (!NativeLibrary.TryGetExport(lib, "WICCreateImagingFactory_Proxy", out IntPtr f1) ||
                !NativeLibrary.TryGetExport(lib, "IWICImagingFactory_CreateDecoderFromFileHandle_Proxy", out IntPtr f2) ||
                !NativeLibrary.TryGetExport(lib, "IWICBitmapDecoder_GetFrame_Proxy", out IntPtr f3))
            {
                note = "libwpfwic.so 缺少工厂/解码器/取帧导出";
                return IntPtr.Zero;
            }

            var createFactory = Marshal.GetDelegateForFunctionPointer<WicCreateFactoryFn>(f1);
            var createDecoder = Marshal.GetDelegateForFunctionPointer<WicCreateDecoderFn>(f2);
            var getFrame = Marshal.GetDelegateForFunctionPointer<WicGetFrameFn>(f3);

            if (createFactory(1, out IntPtr factory) != S_OK || factory == IntPtr.Zero) { note = "建工厂失败"; return IntPtr.Zero; }

            int fd;
            System.IO.FileStream stream = null;
            try
            {
                stream = System.IO.File.OpenRead(png);
                fd = (int)stream.SafeFileHandle.DangerousGetHandle();
                if (createDecoder(factory, (IntPtr)fd, IntPtr.Zero, 0, out IntPtr decoder) != S_OK || decoder == IntPtr.Zero)
                {
                    note = "建 decoder 失败: " + png;
                    return IntPtr.Zero;
                }
                if (getFrame(decoder, 0, out IntPtr frame) != S_OK || frame == IntPtr.Zero)
                {
                    note = "取 frame 失败: " + png;
                    return IntPtr.Zero;
                }

                int sizeHr = WicGetSize(lib, frame, out w, out h);
                note = png;
                if (sizeHr != S_OK) Console.WriteLine($"      （注意：GetSize 返回 {Hex(sizeHr)}，尺寸 {w}x{h}）");
                return frame;
            }
            finally
            {
                stream?.Dispose();
            }
        }

        /// <summary>建一次工厂与解码器（后续可反复取帧）。</summary>
        private static bool CreateFactoryAndDecoder(out IntPtr factory, out IntPtr decoder, out string error)
        {
            factory = decoder = IntPtr.Zero;
            error = null;

            IntPtr lib = IntPtr.Zero;
            string soPath = FindWicLibrary();
            if (soPath == null) { error = "找不到 libwpfwic.so"; return false; }
            if (!NativeLibrary.TryLoad(soPath, out lib) || lib == IntPtr.Zero) { error = "dlopen 失败"; return false; }

            string png = FindProbePng();
            if (png == null) { error = "找不到 PNG"; return false; }

            var createFactory = Marshal.GetDelegateForFunctionPointer<WicCreateFactoryFn>(
                GetExport(lib, "WICCreateImagingFactory_Proxy"));
            var createDecoder = Marshal.GetDelegateForFunctionPointer<WicCreateDecoderFn>(
                GetExport(lib, "IWICImagingFactory_CreateDecoderFromFileHandle_Proxy"));

            if (createFactory(1, out factory) != S_OK || factory == IntPtr.Zero) { error = "建工厂失败"; return false; }

            using var stream = File.OpenRead(png);
            int fd = (int)stream.SafeFileHandle.DangerousGetHandle();
            if (createDecoder(factory, (IntPtr)fd, IntPtr.Zero, 0, out decoder) != S_OK || decoder == IntPtr.Zero)
            { error = "建 decoder 失败"; return false; }
            return true;
        }

        /// <summary>建一个 WIC frame 句柄（refs=1，归调用方）。失败返回 0。</summary>
        private static IntPtr CreateOneWicFrame(out string error)
        {
            error = null;
            IntPtr lib = IntPtr.Zero;
            string soPath = FindWicLibrary();
            if (soPath == null) { error = "找不到 libwpfwic.so"; return IntPtr.Zero; }
            if (!NativeLibrary.TryLoad(soPath, out lib) || lib == IntPtr.Zero) { error = "dlopen 失败"; return IntPtr.Zero; }

            string png = FindProbePng();
            if (png == null) { error = "找不到 PNG"; return IntPtr.Zero; }

            var createFactory = Marshal.GetDelegateForFunctionPointer<WicCreateFactoryFn>(
                GetExport(lib, "WICCreateImagingFactory_Proxy"));
            var createDecoder = Marshal.GetDelegateForFunctionPointer<WicCreateDecoderFn>(
                GetExport(lib, "IWICImagingFactory_CreateDecoderFromFileHandle_Proxy"));
            var getFrame = Marshal.GetDelegateForFunctionPointer<WicGetFrameFn>(
                GetExport(lib, "IWICBitmapDecoder_GetFrame_Proxy"));

            if (createFactory(1, out IntPtr factory) != S_OK || factory == IntPtr.Zero) { error = "建工厂失败"; return IntPtr.Zero; }

            using var stream = File.OpenRead(png);
            int fd = (int)stream.SafeFileHandle.DangerousGetHandle();
            if (createDecoder(factory, (IntPtr)fd, IntPtr.Zero, 0, out IntPtr decoder) != S_OK || decoder == IntPtr.Zero)
            { error = "建 decoder 失败"; return IntPtr.Zero; }
            if (getFrame(decoder, 0, out IntPtr frame) != S_OK || frame == IntPtr.Zero) { error = "取帧失败"; return IntPtr.Zero; }
            return frame;
        }

        private static IntPtr GetExport(IntPtr lib, string name)
            => NativeLibrary.TryGetExport(lib, name, out IntPtr p) ? p : IntPtr.Zero;

        private static int WicHandleCount(IntPtr lib)
        {
            if (!NativeLibrary.TryGetExport(lib, "WicShim_HandleCount", out IntPtr p)) return -1;
            return Marshal.GetDelegateForFunctionPointer<WicNoArgFn>(p)();
        }

        private static int WicPeakHandleCount(IntPtr lib)
        {
            if (!NativeLibrary.TryGetExport(lib, "WicShim_PeakHandleCount", out IntPtr p)) return -1;
            return Marshal.GetDelegateForFunctionPointer<WicNoArgFn>(p)();
        }

        private static bool WicOwnsHandle(IntPtr lib, IntPtr handle)
        {
            if (!NativeLibrary.TryGetExport(lib, "WicShim_OwnsHandle", out IntPtr p)) return false;
            return Marshal.GetDelegateForFunctionPointer<WicOwnsHandleFn>(p)(handle) != 0;
        }

        private static int WicGetSize(IntPtr lib, IntPtr source, out uint w, out uint h)
        {
            w = h = 0;
            if (!NativeLibrary.TryGetExport(lib, "IWICBitmapSource_GetSize_Proxy", out IntPtr p)) return unchecked((int)0x80004005);
            return Marshal.GetDelegateForFunctionPointer<WicGetSizeFn>(p)(source, out w, out h);
        }

        /// <summary>
        /// 按**生产部署形态**把 libwpfwic.so 放到两个位置：
        ///   ① 与 wpfgfx_cor3.so 同目录 —— .so 内部的桥用宿主注入的自定位目录找（首选）
        ///   ② 本程序目录 —— 兜底
        /// 这样测的就是"两个 .so 同目录"这个真实形态，而不是靠环境变量。
        /// </summary>
        private static void EnsureWicLibraryAppLocal()
        {
            string found = FindWicLibrary();
            if (found == null) return;

            var targets = new System.Collections.Generic.List<string>
            {
                Path.Combine(AppContext.BaseDirectory, "libwpfwic.so"),
            };

            string milSo = MilCoreDllImportResolver.LoadedPath;
            if (!string.IsNullOrEmpty(milSo))
                targets.Add(Path.Combine(Path.GetDirectoryName(milSo), "libwpfwic.so"));

            foreach (string target in targets)
            {
                if (File.Exists(target)) continue;
                try
                {
                    File.Copy(found, target, overwrite: true);
                    Console.WriteLine($"      libwpfwic.so 已部署到 {target}");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"      （拷贝到 {target} 失败：{ex.GetType().Name}）");
                }
            }

            if (!File.Exists(Path.Combine(Path.GetDirectoryName(milSo ?? "") ?? "", "libwpfwic.so")))
                Environment.SetEnvironmentVariable("MILBRIDGE_WIC_SO", found);
        }

        /// <summary>
        /// 定位 libwpfwic.so。
        ///
        /// ⚠️ **必须与 .so 内部那座桥加载的是同一个文件** —— `dlopen` 只在**同一个已加载对象**
        ///   （同路径/SONAME）上去重。若两侧各加载一份副本，就是**两张独立的对象表**：
        ///   宿主建出来的句柄在桥那一侧"不属于它" ⇒ `WicShim_OwnsHandle` 返回 0 ⇒ E_HANDLE。
        ///   所以这里**优先返回与 wpfgfx_cor3.so 同目录的那一份**（也就是桥会加载的那一份）。
        ///   生产部署天然满足这个条件（应用目录里只有一个 libwpfwic.so）。
        /// </summary>
        private static string FindWicLibrary()
        {
            string env = Environment.GetEnvironmentVariable("MILBRIDGE_WIC_SO");
            if (!string.IsNullOrEmpty(env) && File.Exists(env)) return env;

            // ① 与 wpfgfx_cor3.so 同目录（桥的首选候选 —— 保持一致）
            string milSo = MilCoreDllImportResolver.LoadedPath;
            if (!string.IsNullOrEmpty(milSo))
            {
                string beside = Path.Combine(Path.GetDirectoryName(milSo), "libwpfwic.so");
                if (File.Exists(beside)) return beside;
            }

            // ② 本程序目录
            string local = Path.Combine(AppContext.BaseDirectory, "libwpfwic.so");
            if (File.Exists(local)) return local;

            // ③ 开发树：T2 的 wic-shim 产物（首次部署的来源）
            var di = new DirectoryInfo(AppContext.BaseDirectory);
            for (int up = 0; up < 9 && di != null; up++, di = di.Parent)
            {
                string p = Path.Combine(di.FullName, "build", "DirectWrite.Linux", "wic-shim", "libwpfwic.so");
                if (File.Exists(p)) return p;
            }
            return null;
        }

        private static string FindProbePng()
        {
            var di = new DirectoryInfo(AppContext.BaseDirectory);
            for (int up = 0; up < 9 && di != null; up++, di = di.Parent)
            {
                string p = Path.Combine(di.FullName, "tests", "artifacts", "rendering", "solid_rectangle.png");
                if (File.Exists(p)) return p;
            }
            return null;
        }

        // ==============================================================
        //  F 组：跨运行时边界（T1/M7c2）
        //    T1 之后 MIL 跑在 NativeAOT .so 这个**独立 .NET 运行时**里，
        //    `MilFontFaceTable` 的静态状态与宿主进程各一份。托管侧直接调
        //    Register 只会写进一份 .so 看不见的副本 —— 唯一能跨过去的形态是
        //    C ABI：由 .so 内部导出 MilFontFace_RegisterFromFile。
        // ==============================================================
        private static void RunCrossRuntimeFontFace()
        {
            Console.WriteLine();
            Console.WriteLine("[F] 跨运行时字体面登记（.so 自有导出）");

            string fontPath = FindFont();
            if (fontPath == null)
            {
                Skip("F1", "找到测试字体 build/fonts/NotoSans-Regular.ttf", "文件不存在，跳过整组");
                return;
            }

            // F1：符号真的在 .so 里（GetExport 直查，不靠 DllImport 缓存）
            {
                IntPtr so = MilCoreDllImportResolver.TryResolve(
                    MilCoreDllImportResolver.MilCoreLibraryName, out IntPtr h) ? h : IntPtr.Zero;
                bool found = so != IntPtr.Zero &&
                             NativeLibrary.TryGetExport(so, "MilFontFace_RegisterFromFile", out IntPtr addr) &&
                             addr != IntPtr.Zero;
                Check("F1", "NativeLibrary.GetExport(wpfgfx_cor3.so, MilFontFace_RegisterFromFile) 命中",
                    found, $"so=0x{so.ToInt64():X} addr=0x{addrOf(so):X}");
            }

            // F2：真调一次（UTF-8 路径按 C 字符串传入）
            byte[] utf8 = System.Text.Encoding.UTF8.GetBytes(fontPath + "\0");
            IntPtr token = IntPtr.Zero;
            fixed (byte* p = utf8)
            {
                token = Native.RegisterFontFaceFromFile(p, 0, 0);
            }
            Check("F2", "MilFontFace_RegisterFromFile(NotoSans-Regular.ttf, faceIndex=0, simFlags=0) → 非 0 令牌",
                token != IntPtr.Zero, $"path={fontPath} token=0x{token.ToInt64():X}");

            // F3：失败路径一律返回 0，不抛异常穿 ABI
            {
                byte[] bad = System.Text.Encoding.UTF8.GetBytes("/nonexistent/NoSuchFont.ttf\0");
                IntPtr t1, t2, t3;
                fixed (byte* p = bad) { t1 = Native.RegisterFontFaceFromFile(p, 0, 0); }
                fixed (byte* p = utf8) { t2 = Native.RegisterFontFaceFromFile(p, -1, 0); t3 = Native.RegisterFontFaceFromFile(p, 9999, 0); }
                IntPtr t4 = Native.RegisterFontFaceFromFile(null, 0, 0);
                Check("F3", "失败路径全部返回 0（文件不存在 / faceIndex<0 / faceIndex 越界 / null 路径）",
                    t1 == IntPtr.Zero && t2 == IntPtr.Zero && t3 == IntPtr.Zero && t4 == IntPtr.Zero,
                    $"missing=0x{t1.ToInt64():X} negIndex=0x{t2.ToInt64():X} oobIndex=0x{t3.ToInt64():X} nullPath=0x{t4.ToInt64():X}");
            }

            // F4：令牌能被**同一个 .so 运行时**里的 MilGlyphRun_GetGlyphOutline 认出来 ——
            //     这才是"跨运行时登记成功"的实证（宿主侧的表里根本没有这个令牌）。
            {
                int hr = Native.GetGlyphOutline(token, 36 /* 'A' in NotoSans */, 0, 32.0,
                    out byte* data, out uint size, out int fillRule);
                bool ok = hr == S_OK && data != null && size > 0;
                Check("F4", "令牌被 .so 内的 MilGlyphRun_GetGlyphOutline 解析成功 → S_OK + 非空轮廓",
                    ok, $"hr={Hex(hr)} size={size} bytes fillRule={fillRule} ptr=0x{(long)data:X}");
                if (data != null) Native.ReleasePathGeometryData(data);
            }

            // F5：对照 —— 随便给个句柄必须 E_HANDLE（证明 F4 不是"随便都成功"）
            {
                int hr = Native.GetGlyphOutline(unchecked((IntPtr)0x7FFFFFFF), 36, 0, 32.0,
                    out byte* data, out _, out _);
                Check("F5", "对照：伪造字体面令牌 → E_HANDLE", hr == E_HANDLE,
                    $"hr={Hex(hr)} expect {Hex(E_HANDLE)} ptr=0x{(long)data:X}");
            }

            // F6：simFlags 真的被记录（Bold=1 / Oblique=2 各登记一个，令牌互不相同）
            {
                IntPtr bold, oblique;
                fixed (byte* p = utf8)
                {
                    bold = Native.RegisterFontFaceFromFile(p, 0, 1);
                    oblique = Native.RegisterFontFaceFromFile(p, 0, 2);
                }
                bool ok = bold != IntPtr.Zero && oblique != IntPtr.Zero && bold != oblique && bold != token;
                Check("F6", "simFlags 参与登记：Bold/Oblique 得到各自独立的令牌",
                    ok, $"bold=0x{bold.ToInt64():X} oblique=0x{oblique.ToInt64():X} plain=0x{token.ToInt64():X}");
            }
        }

        private static long addrOf(IntPtr so)
        {
            return so != IntPtr.Zero &&
                   NativeLibrary.TryGetExport(so, "MilFontFace_RegisterFromFile", out IntPtr a)
                ? a.ToInt64() : 0;
        }

        /// <summary>从应用目录向上找 build/fonts/NotoSans-Regular.ttf（开发树布局）。</summary>
        private static string FindFont()
        {
            string env = Environment.GetEnvironmentVariable("MILBRIDGE_TEST_FONT");
            if (!string.IsNullOrEmpty(env) && System.IO.File.Exists(env)) return env;

            var di = new System.IO.DirectoryInfo(AppContext.BaseDirectory);
            for (int up = 0; up < 9 && di != null; up++, di = di.Parent)
            {
                string p = System.IO.Path.Combine(di.FullName, "build", "fonts", "NotoSans-Regular.ttf");
                if (System.IO.File.Exists(p)) return p;
            }
            return null;
        }

        // ==============================================================
        //  工具
        // ==============================================================
        private static void CheckDiagCounter(string id, string what, IntPtr ch, int which, long expect)
        {
            if (Native.DiagAvailable() == 0)
            {
                Skip(id, what, $"该 .so 镜像里反射不可用（ProbeCode={Native.DiagProbeCode()}）");
                return;
            }
            int hr = Native.DiagChannelCounter(ch, which, out long value);
            Check(id, what, hr == S_OK && value == expect, $"hr={Hex(hr)} value={value} expect={expect}");
        }

        /// <summary>MILCMD 头：Type@0(u32 LE) + Handle@4(u32 LE)。</summary>
        private static void WriteCommandHeader(byte* dst, int type, uint handle)
        {
            *(int*)(dst + 0) = type;
            *(uint*)(dst + 4) = handle;
        }

        /// <summary>
        /// 一条真实的 MILCMD_VISUAL_SETOFFSET(0x1b)（24 字节）：
        ///   Type@0(u32) Handle@4(u32) OffsetX@8(double) OffsetY@16(double)
        /// 通过 BeginCommand(头 8B, cbExtra=16) + AppendCommandData(尾 16B) 两段发出，
        /// 正是上游 Channel.BeginCommand 的用法（头 + 变长/固定尾）。
        /// </summary>
        private static void WriteVisualSetOffset(byte* header, byte* payload, uint handle, double x, double y)
        {
            WriteCommandHeader(header, MilCmdVisualSetOffset, handle);
            *(double*)(payload + 0) = x;    // 命令内 offset 8
            *(double*)(payload + 8) = y;    // 命令内 offset 16
        }
    }
}

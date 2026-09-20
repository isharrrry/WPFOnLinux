// T1 Phase 1-D：路线 B 的「朴素写法」—— 直接把 [DllImport] 换成 MilNative.<同名方法>。
//
// 这是 handoff 决策 3 的字面读法：「把 [DllImport] 换成同名方法调用」。
// 本文件**预期编译失败**，每一条错误都是一个必须逐点适配的调用点。
// 错误清单见 build/MilBridge/gen/route-b-diagnostics.txt。

using System;
using WpfGfx.Linux.Interop;

// 上游命名空间下的同名类型（与 PresentationCore 里完全一致）
using PcHandle = System.Windows.Media.Composition.DUCE.ResourceHandle;
using PcResourceType = System.Windows.Media.Composition.DUCE.ResourceType;
using PcMatrix = MS.Internal.MilMatrix3x2D;
using PcWindowMessage = MS.Internal.WindowMessage;

namespace ProbeB
{
    internal static unsafe class NaiveCallSites
    {
        // ---- 阻塞 1a：ref DUCE.ResourceHandle 类型同一性 ----
        internal static int CreateOrAddRef(IntPtr pChannel, PcResourceType type, ref PcHandle h)
            => MilNative.MilResource_CreateOrAddRefOnChannel(pChannel, type, ref h);

        // ---- 阻塞 1b：ref DUCE.ResourceHandle 出参 ----
        internal static int DuplicateHandle(IntPtr src, PcHandle original, IntPtr dst, ref PcHandle dup)
            => MilNative.MilResource_DuplicateHandle(src, original, dst, ref dup);

        // ---- 阻塞 1c：MilMatrix3x2D* vs double* ----
        internal static int GeometryGetArea(PcMatrix* m, double* pArea)
            => MilNative.MilUtility_GeometryGetArea(
                   MilFillRule.EvenOdd, null, 0, m, 0.0, false, pArea);

        // ---- 阻塞 1d：WindowMessage 枚举 vs uint ----
        internal static int SetNotificationWindow(IntPtr ch, IntPtr hwnd, PcWindowMessage msg)
            => MilNative.MilChannel_SetNotificationWindow(ch, hwnd, msg);

        // ---- 阻塞 1e：out bool vs out int（上游 out bool，MilNative out int）----
        internal static int HitTest(byte* path, uint n, out bool contains)
        {
            MilPointD hit = default;
            return MilNative.MilUtility_PathGeometryHitTest(
                null, null, null, MilFillRule.EvenOdd, path, n, 0.0, false, &hit, out contains);
        }

        // ---- 阻塞 3：PreserveSig=false。上游声明是 `void MILCopyPixelBuffer(...)`，
        //      DllImport 的 CLR 会在失败时抛异常；直调 MilNative 返回 int，不抛。
        //      这一条**能编译**（返回值被丢弃），但语义静默变了 —— 列在这里当"语义阻塞"。
        internal static void CopyPixelBuffer(byte* dst, byte* src)
            => MilNative.MilUtility_CopyPixelBuffer(dst, 0, 0, 0, src, 0, 0, 0, 0, 0);
    }
}

// T1 Phase 1-D：路线 B 的「适配后写法」—— 证明路线 B **可行性**，同时量化每条的成本。
//
// 每条调用点至少要多写什么，本文件逐条标注（# 适配 N）。
// 统计口径见报告：路线 B 需要在 10 个文件、108 个调用点各加适配代码。

using System;
using System.Runtime.InteropServices;
using WpfGfx.Linux.Interop;

using PcHandle = System.Windows.Media.Composition.DUCE.ResourceHandle;
using PcResourceType = System.Windows.Media.Composition.DUCE.ResourceType;
using PcMatrix = MS.Internal.MilMatrix3x2D;
using PcWindowMessage = MS.Internal.WindowMessage;

namespace ProbeB
{
    internal static unsafe class AdaptedCallSites
    {
        /// <summary># 适配 1：句柄类型转换（PC 的 4 字节 struct → WpfGfx 的 4 字节 struct）。</summary>
        private static DUCE.ResourceHandle ToMil(PcHandle h) => new DUCE.ResourceHandle((uint)h);
        private static PcHandle FromMil(DUCE.ResourceHandle h) => new PcHandle(h.Value);

        internal static int CreateOrAddRef(IntPtr pChannel, PcResourceType type, ref PcHandle h)
        {
            // # 适配 2：枚举按底层值转 + ref 参数要借道局部变量再写回
            DUCE.ResourceHandle local = ToMil(h);
            int hr = MilNative.MilResource_CreateOrAddRefOnChannel(
                pChannel, (DUCE.ResourceType)(int)type, ref local);
            h = FromMil(local);
            return hr;
        }

        internal static int DuplicateHandle(IntPtr src, PcHandle original, IntPtr dst, ref PcHandle dup)
        {
            DUCE.ResourceHandle local = ToMil(dup);
            int hr = MilNative.MilResource_DuplicateHandle(src, ToMil(original), dst, ref local);
            dup = FromMil(local);
            return hr;
        }

        /// <summary># 适配 3：MilMatrix3x2D* → double*（调用点自己 pin/取址）。</summary>
        internal static int GeometryGetArea(PcMatrix* m, double* pArea)
            => MilNative.MilUtility_GeometryGetArea(
                   MilFillRule.EvenOdd, null, 0, (double*)m, 0.0, false, pArea);

        internal static int SetNotificationWindow(IntPtr ch, IntPtr hwnd, PcWindowMessage msg)
            // # 适配 4：枚举 → uint
            => MilNative.MilChannel_SetNotificationWindow(ch, hwnd, (uint)msg);

        internal static int HitTest(byte* path, uint n, out bool contains)
        {
            MilPointD hit = default;
            // # 适配 5：out bool → out int → 再转回 bool
            int hr = MilNative.MilUtility_PathGeometryHitTest(
                null, null, null, MilFillRule.EvenOdd, path, n, 0.0, false, &hit, out int c);
            contains = c != 0;
            return hr;
        }

        /// <summary>
        /// # 适配 6：PreserveSig=false 语义必须手写 —— 上游调用点依赖"失败即抛"，
        /// 直调不会抛。3 条 PreserveSig=false 声明（CopyPixelBuffer /
        /// MILSwDoubleBufferedBitmapGetBackBuffer / AddDirtyRect）都有这个问题。
        /// 漏掉 = 失败被静默吞掉。
        /// </summary>
        internal static void CopyPixelBuffer(byte* dst, byte* src)
        {
            int hr = MilNative.MilUtility_CopyPixelBuffer(dst, 0, 0, 0, src, 0, 0, 0, 0, 0);
            if (hr < 0) Marshal.ThrowExceptionForHR(hr);
        }
    }
}

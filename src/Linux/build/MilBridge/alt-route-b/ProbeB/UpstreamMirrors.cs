// T1 Phase 1-D：把上游 PresentationCore / Common/Graphics 里的关键类型**逐字抄一份**过来。
//
// 为什么抄：路线 B（编译期替换）要在 PresentationCore 的编译单元里把
//   [DllImport(DllImport.MilCore)] 换成对 WpfGfx.Linux.MilNative 的直调。
//   在 PresentationCore 里，`DUCE.ResourceHandle` 是 **它自己的 internal struct**
//   （Common/Graphics/exports.cs:967），`MilMatrix3x2D` 也是它自己的
//   （PresentationCore/.../MILUtilities.cs 引用的 MS.Internal 类型）。
//   本文件把这两个类型按上游原文抄进来，就能在**独立工程里复现**同一个编译错误。
//
// 这些类型是 internal —— 与 PresentationCore 里的可见性一致（等价性见报告）。

using System;
using System.Runtime.InteropServices;

namespace System.Windows.Media.Composition
{
    public static class DUCE
    {
        /// <summary>上游 Common/Graphics/exports.cs:967（逐字，含 [StructLayout(LayoutKind.Explicit)]）。</summary>
        [StructLayout(LayoutKind.Explicit)]
        public struct ResourceHandle
        {
            public static readonly ResourceHandle Null = new ResourceHandle(0);

            public static explicit operator uint(ResourceHandle r) => r._handle;

            [FieldOffset(0)]
            private UInt32 _handle;
            public ResourceHandle(UInt32 handle) { _handle = handle; }

            public bool IsNull => _handle == 0;
        }

        /// <summary>上游 Common/Graphics/exports.cs:783 之后的 ResourceType（只取几个值示意）。</summary>
        public enum ResourceType
        {
            TYPE_NULL = 0,
            TYPE_VISUAL = 39,
            TYPE_GLYPHRUN = 42,
        }
    }
}

namespace MS.Internal
{
    /// <summary>
    /// 上游 MilMatrix3x2D（PresentationCore 里的 2D 仿射矩阵，S_11 S_12 S_21 S_22 DX DY）。
    /// MilNative 侧对应的是 `double*`（因 CS0051 退化），两者**不是同一个类型**。
    /// </summary>
    [StructLayout(LayoutKind.Sequential)]
    public struct MilMatrix3x2D
    {
        public double S_11, S_12, S_21, S_22, DX, DY;
    }

    /// <summary>上游 WindowMessage（PresentationCore 的 MS.Win32 枚举，底层 int）。</summary>
    public enum WindowMessage
    {
        WM_NULL = 0x0000,
        WM_USER = 0x0400,
    }
}

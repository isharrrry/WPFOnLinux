// T1 Phase 1-A：最小 AOT 导出面。
// 两个函数：一个返回 int，一个收指针 —— 覆盖"返回值 + 指针参数"两类 ABI 形状。

using System;
using System.Runtime.InteropServices;

namespace AotSpike
{
    public static unsafe class Exports
    {
        /// <summary>返回 int。签名形状对应 HRESULT 类导出。</summary>
        [UnmanagedCallersOnly(EntryPoint = "aotspike_add")]
        public static int Add(int a, int b) => a + b;

        /// <summary>收指针并写回。签名形状对应 `byte* pbData, uint cbSize` 类导出。</summary>
        [UnmanagedCallersOnly(EntryPoint = "aotspike_sum_bytes")]
        public static int SumBytes(byte* pbData, uint cbSize)
        {
            if (pbData == null) return unchecked((int)0x80070057); // E_INVALIDARG
            int sum = 0;
            for (uint i = 0; i < cbSize; i++) sum += pbData[i];
            return sum;
        }

        /// <summary>写托管静态状态，验证 AOT 库内的托管运行时真的活了。</summary>
        [UnmanagedCallersOnly(EntryPoint = "aotspike_identity")]
        public static int Identity(int v)
        {
            StrongBox = v;
            return StrongBox;
        }

        private static int StrongBox;
    }
}

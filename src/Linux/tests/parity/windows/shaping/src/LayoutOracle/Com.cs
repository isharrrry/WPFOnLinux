using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

namespace LayoutOracle
{
    /// <summary>
    /// In-process COM servers built by hand.  An "object" is a block of unmanaged memory
    /// { vtable*, refCount, kind, data0..data3 } whose vtable points at [UnmanagedCallersOnly]
    /// static methods.  No CCW / [ComImport]: the CLR marshaller produced invalid stubs for
    /// this kind of interface on this machine (0xC0000005).
    ///
    /// Refcounting: AddRef/Release only change the counter and NEVER free.  The process is
    /// short lived, and this removes every use-after-free risk in the DWrite callbacks.
    /// [UnmanagedCallersOnly] without CallConvs uses the platform default convention, which on
    /// x64 is the one DWrite expects (and the one `delegate* unmanaged<...>` denotes).
    /// </summary>
    internal static unsafe class Com
    {
        internal const int OffVtbl = 0, OffRef = 8, OffKind = 12;
        internal const int OffData0 = 16, OffData1 = 24, OffData2 = 32, OffData3 = 40;
        internal const int ObjSize = 48;

        internal const int KindStream = 0, KindFileLoader = 1, KindEnumerator = 2, KindCollLoader = 3;

        internal const int S_OK = 0;
        internal const int E_NOINTERFACE = unchecked((int)0x80004002);
        internal const int E_INVALIDARG = unchecked((int)0x80070057);

        internal static readonly Guid IID_IUnknown = new Guid("00000000-0000-0000-C000-000000000046");
        internal static readonly Guid IID_FileStream = new Guid("6d4865fe-0ab8-4d91-8f62-5dd6be34a3e0");
        internal static readonly Guid IID_FileLoader = new Guid("727cad4e-d6af-4c9e-8a08-d695b11caa49");
        internal static readonly Guid IID_Enumerator = new Guid("72755049-5ff7-435d-8348-4be97cfa6c7c");
        internal static readonly Guid IID_CollLoader = new Guid("cca920e4-52f0-492b-bfa8-29c72ee0a468");

        internal static IntPtr NewVtbl(params IntPtr[] fns)
        {
            IntPtr vtbl = Marshal.AllocHGlobal(fns.Length * IntPtr.Size);
            for (int i = 0; i < fns.Length; i++) Marshal.WriteIntPtr(vtbl, i * IntPtr.Size, fns[i]);
            return vtbl;
        }

        internal static IntPtr New(IntPtr vtbl, int kind)
        {
            IntPtr obj = Marshal.AllocHGlobal(ObjSize);
            for (int i = 0; i < ObjSize; i++) Marshal.WriteByte(obj, i, 0);
            Marshal.WriteIntPtr(obj, OffVtbl, vtbl);
            Marshal.WriteInt32(obj, OffRef, 1);
            Marshal.WriteInt32(obj, OffKind, kind);
            return obj;
        }

        internal static long D0(IntPtr o) => Marshal.ReadInt64(o, OffData0);
        internal static long D1(IntPtr o) => Marshal.ReadInt64(o, OffData1);
        internal static long D2(IntPtr o) => Marshal.ReadInt64(o, OffData2);
        internal static long D3(IntPtr o) => Marshal.ReadInt64(o, OffData3);
        internal static void SetD0(IntPtr o, long v) => Marshal.WriteInt64(o, OffData0, v);
        internal static void SetD1(IntPtr o, long v) => Marshal.WriteInt64(o, OffData1, v);
        internal static void SetD2(IntPtr o, long v) => Marshal.WriteInt64(o, OffData2, v);
        internal static void SetD3(IntPtr o, long v) => Marshal.WriteInt64(o, OffData3, v);
    }

    internal static unsafe class Servers
    {
        internal static int N_QI, N_AddRef, N_Release, N_CreateEnum, N_MoveNext, N_GetCurrent,
                            N_CreateStream, N_ReadFragment, N_GetFileSize, N_ReleaseFragment;

        // ---------------------------------------------------------------- IUnknown
        [UnmanagedCallersOnly]
        internal static int QueryInterface(IntPtr self, Guid* iid, IntPtr* ppv)
        {
            N_QI++;
            *ppv = IntPtr.Zero;
            int kind = Marshal.ReadInt32(self, Com.OffKind);
            Guid want = *iid;
            bool ok = want.Equals(Com.IID_IUnknown);
            if (!ok)
            {
                switch (kind)
                {
                    case Com.KindStream: ok = want.Equals(Com.IID_FileStream); break;
                    case Com.KindFileLoader: ok = want.Equals(Com.IID_FileLoader); break;
                    case Com.KindEnumerator: ok = want.Equals(Com.IID_Enumerator); break;
                    case Com.KindCollLoader: ok = want.Equals(Com.IID_CollLoader); break;
                }
            }
            if (!ok) return Com.E_NOINTERFACE;
            Marshal.WriteInt32(self, Com.OffRef, Marshal.ReadInt32(self, Com.OffRef) + 1);
            *ppv = self;
            return Com.S_OK;
        }

        [UnmanagedCallersOnly]
        internal static uint AddRef(IntPtr self)
        {
            N_AddRef++;
            int n = Marshal.ReadInt32(self, Com.OffRef) + 1;
            Marshal.WriteInt32(self, Com.OffRef, n);
            return (uint)n;
        }

        [UnmanagedCallersOnly]
        internal static uint Release(IntPtr self)
        {
            N_Release++;
            int n = Marshal.ReadInt32(self, Com.OffRef) - 1;
            if (n < 0) n = 0;
            Marshal.WriteInt32(self, Com.OffRef, n);
            return (uint)n;
        }

        // --------------------------------------------------- IDWriteFontFileStream
        [UnmanagedCallersOnly]
        internal static int ReadFileFragment(IntPtr self, IntPtr* fragmentStart, ulong fileOffset,
                                             ulong fragmentSize, IntPtr* fragmentContext)
        {
            N_ReadFragment++;
            long basePtr = Com.D0(self), len = Com.D1(self);
            if ((long)fileOffset + (long)fragmentSize > len)
            {
                *fragmentStart = IntPtr.Zero; *fragmentContext = IntPtr.Zero;
                return Com.E_INVALIDARG;
            }
            *fragmentStart = (IntPtr)(basePtr + (long)fileOffset);
            *fragmentContext = IntPtr.Zero;
            return Com.S_OK;
        }

        [UnmanagedCallersOnly]
        internal static int ReleaseFileFragment(IntPtr self, IntPtr fragmentContext) => Com.S_OK;

        [UnmanagedCallersOnly]
        internal static int GetFileSize(IntPtr self, ulong* fileSize)
        {
            N_ReleaseFragment++;
            N_GetFileSize++;
            *fileSize = (ulong)Com.D1(self);
            return Com.S_OK;
        }

        [UnmanagedCallersOnly]
        internal static int GetLastWriteTime(IntPtr self, ulong* lastWriteTime)
        {
            *lastWriteTime = 0;
            return Com.S_OK;
        }

        // ------------------------------------------------- IDWriteFontFileLoader
        [UnmanagedCallersOnly]
        internal static int CreateStreamFromKey(IntPtr self, void* key, uint keySize, IntPtr* stream)
        {
            N_CreateStream++;
            *stream = IntPtr.Zero;
            if (key == null || keySize < 4) return Com.E_INVALIDARG;
            int fontIndex = *(int*)key;
            if (fontIndex < 0 || fontIndex >= FontStore.Count) return Com.E_INVALIDARG;
            *stream = FontStore.CreateStreamObject(fontIndex);
            return Com.S_OK;
        }

        // --------------------------------------------- IDWriteFontFileEnumerator
        [UnmanagedCallersOnly]
        internal static int MoveNext(IntPtr self, int* hasCurrentFile)
        {
            N_MoveNext++;
            int next = (int)Com.D1(self);
            int collId = (int)Com.D0(self);
            int[] list = CollectionTable.ListFor(collId);
            if (next >= list.Length) { *hasCurrentFile = 0; return Com.S_OK; }
            Com.SetD2(self, next);            // current slot
            Com.SetD1(self, next + 1);        // advance
            *hasCurrentFile = 1;
            return Com.S_OK;
        }

        [UnmanagedCallersOnly]
        internal static int GetCurrentFontFile(IntPtr self, IntPtr* fontFile)
        {
            N_GetCurrent++;
            *fontFile = IntPtr.Zero;
            int slot = (int)Com.D2(self);
            int collId = (int)Com.D0(self);
            int fontIndex = CollectionTable.ListFor(collId)[slot];
            IntPtr factory = (IntPtr)Com.D3(self);
            return Dw.CreateCustomFontFileReference(factory, fontIndex, fontFile);
        }

        // ------------------------------------------- IDWriteFontCollectionLoader
        [UnmanagedCallersOnly]
        internal static int CreateEnumeratorFromKey(IntPtr self, IntPtr factory, void* key, uint keySize,
                                                    IntPtr* enumerator)
        {
            N_CreateEnum++;
            *enumerator = IntPtr.Zero;
            if (key == null || keySize < 4) return Com.E_INVALIDARG;
            int collId = *(int*)key;
            *enumerator = CollectionTable.CreateEnumeratorObject(factory, collId);
            return Com.S_OK;
        }

        // ------------------------------------------------------------ vtable cache
        internal static readonly IntPtr StreamVtbl = Com.NewVtbl(
            (IntPtr)(delegate* unmanaged<IntPtr, Guid*, IntPtr*, int>)&QueryInterface,
            (IntPtr)(delegate* unmanaged<IntPtr, uint>)&AddRef,
            (IntPtr)(delegate* unmanaged<IntPtr, uint>)&Release,
            (IntPtr)(delegate* unmanaged<IntPtr, IntPtr*, ulong, ulong, IntPtr*, int>)&ReadFileFragment,
            (IntPtr)(delegate* unmanaged<IntPtr, IntPtr, int>)&ReleaseFileFragment,
            (IntPtr)(delegate* unmanaged<IntPtr, ulong*, int>)&GetFileSize,
            (IntPtr)(delegate* unmanaged<IntPtr, ulong*, int>)&GetLastWriteTime);

        internal static readonly IntPtr FileLoaderVtbl = Com.NewVtbl(
            (IntPtr)(delegate* unmanaged<IntPtr, Guid*, IntPtr*, int>)&QueryInterface,
            (IntPtr)(delegate* unmanaged<IntPtr, uint>)&AddRef,
            (IntPtr)(delegate* unmanaged<IntPtr, uint>)&Release,
            (IntPtr)(delegate* unmanaged<IntPtr, void*, uint, IntPtr*, int>)&CreateStreamFromKey);

        internal static readonly IntPtr EnumeratorVtbl = Com.NewVtbl(
            (IntPtr)(delegate* unmanaged<IntPtr, Guid*, IntPtr*, int>)&QueryInterface,
            (IntPtr)(delegate* unmanaged<IntPtr, uint>)&AddRef,
            (IntPtr)(delegate* unmanaged<IntPtr, uint>)&Release,
            (IntPtr)(delegate* unmanaged<IntPtr, int*, int>)&MoveNext,
            (IntPtr)(delegate* unmanaged<IntPtr, IntPtr*, int>)&GetCurrentFontFile);

        internal static readonly IntPtr CollLoaderVtbl = Com.NewVtbl(
            (IntPtr)(delegate* unmanaged<IntPtr, Guid*, IntPtr*, int>)&QueryInterface,
            (IntPtr)(delegate* unmanaged<IntPtr, uint>)&AddRef,
            (IntPtr)(delegate* unmanaged<IntPtr, uint>)&Release,
            (IntPtr)(delegate* unmanaged<IntPtr, IntPtr, void*, uint, IntPtr*, int>)&CreateEnumeratorFromKey);
    }

    /// <summary>Font files served to DWrite out of pinned managed byte arrays.</summary>
    internal static class FontStore
    {
        private static readonly List<GCHandle> Pins = new List<GCHandle>();
        private static readonly List<byte[]> Data = new List<byte[]>();
        private static readonly List<string> Paths = new List<string>();

        internal static int Count => Data.Count;

        internal static int Add(string path)
        {
            byte[] bytes = File.ReadAllBytes(path);
            Data.Add(bytes);
            Paths.Add(path);
            Pins.Add(GCHandle.Alloc(bytes, GCHandleType.Pinned));   // kept alive for the process lifetime
            return Data.Count - 1;
        }

        internal static string PathOf(int i) => Paths[i];

        internal static IntPtr CreateStreamObject(int index)
        {
            IntPtr obj = Com.New(Servers.StreamVtbl, Com.KindStream);
            Com.SetD0(obj, Pins[index].AddrOfPinnedObject().ToInt64());
            Com.SetD1(obj, Data[index].LongLength);
            return obj;
        }
    }

    internal static class CollectionTable
    {
        // collection id -> font indices (built by Program before anything is registered)
        internal static readonly List<int[]> Lists = new List<int[]>();

        internal static int Add(int[] fontIndices) { Lists.Add(fontIndices); return Lists.Count - 1; }

        internal static int[] ListFor(int id) => (id >= 0 && id < Lists.Count) ? Lists[id] : Array.Empty<int>();

        internal static IntPtr CreateEnumeratorObject(IntPtr factory, int collId)
        {
            IntPtr obj = Com.New(Servers.EnumeratorVtbl, Com.KindEnumerator);
            Com.SetD0(obj, collId);
            Com.SetD1(obj, 0);
            Com.SetD2(obj, 0);
            Com.SetD3(obj, factory.ToInt64());
            return obj;
        }

        internal static IntPtr CreateLoaderObject()
            => Com.New(Servers.CollLoaderVtbl, Com.KindCollLoader);
    }
}

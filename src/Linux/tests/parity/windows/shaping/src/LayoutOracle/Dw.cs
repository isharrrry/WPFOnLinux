using System;
using System.Runtime.InteropServices;

namespace LayoutOracle
{
    [StructLayout(LayoutKind.Sequential)]
    internal struct DWRITE_TEXT_METRICS
    {
        public float left, top, width, widthIncludingTrailingWhitespace, height;
        public float layoutWidth, layoutHeight;
        public uint maxBidiReorderingDepth, lineCount;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DWRITE_LINE_METRICS
    {
        public uint length, trailingWhitespaceLength, newlineLength;
        public float height, baseline;
        public int isTrimmed;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DWRITE_HIT_TEST_METRICS
    {
        public uint textPosition, length;
        public float left, top, width, height;
        public uint bidiLevel;
        public int isText, isTrimmed;
    }

    /// <summary>
    /// DirectWrite calling layer.  Slot indices come from the MIDL-generated Windows SDK header
    /// dwrite.h (see SDK_dwrite.h.reference).  IDWriteTextLayout derives from IDWriteTextFormat,
    /// so its own methods start after the format's 30.
    /// </summary>
    internal static unsafe class Dw
    {
        // IDWriteFactory (authoritative order from the SDK header, see SDK_dwrite.h.reference)
        private const int F_CreateCustomFontCollection = 4;
        private const int F_RegisterFontCollectionLoader = 5;
        private const int F_UnregisterFontCollectionLoader = 6;
        private const int F_CreateFontFileReference = 7;
        private const int F_CreateCustomFontFileReference = 8;   // NOT 6: 6 is UnregisterFontCollectionLoader
        private const int F_CreateFontFace = 9;
        private const int F_RegisterFontFileLoader = 13;
        private const int F_CreateTextFormat = 15;
        private const int F_CreateTextLayout = 18;

        // IDWriteFontCollection
        private const int C_GetFontFamilyCount = 3;
        private const int C_GetFontFamily = 4;
        private const int C_FindFamilyName = 5;

        // IDWriteTextFormat (IDWriteTextLayout inherits these)
        private const int TF_SetWordWrapping = 5;

        // IDWriteTextLayout derives from IDWriteTextFormat, whose own methods are 25 (slots 3..27),
        // so the layout's own methods start at slot 28.  Counting from the SDK header:
        //   28 SetMaxWidth ... 57 GetLocaleName, 58 Draw, 59 GetLineMetrics, 60 GetMetrics,
        //   61 GetOverhangMetrics, 62 GetClusterMetrics, 63 DetermineMinWidth, 64 HitTestPoint,
        //   65 HitTestTextPosition, 66 HitTestTextRange
        private const int TL_GetLineMetrics = 59;
        private const int TL_GetMetrics = 60;
        private const int TL_HitTestTextPosition = 65;
        private const int TL_HitTestTextRange = 66;

        private static readonly Guid IID_IDWriteFactory = new Guid("b859ee5a-d838-4b5b-a2e8-1adc7d93db48");

        [DllImport("dwrite.dll", ExactSpelling = true, PreserveSig = true)]
        private static extern int DWriteCreateFactory(int factoryType, ref Guid iid, out IntPtr factory);

        internal static IntPtr Factory;

        internal static void* Slot(IntPtr obj, int index)
            => (void*)Marshal.ReadIntPtr(Marshal.ReadIntPtr(obj), index * IntPtr.Size);

        internal static void Init()
        {
            Guid iid = IID_IDWriteFactory;
            int hr = DWriteCreateFactory(0, ref iid, out Factory);
            Check(hr, "DWriteCreateFactory");
        }

        internal static void RegisterLoaders(IntPtr collectionLoader, IntPtr fileLoader)
        {
            var regColl = (delegate* unmanaged<IntPtr, IntPtr, int>)Slot(Factory, F_RegisterFontCollectionLoader);
            Check(regColl(Factory, collectionLoader), "RegisterFontCollectionLoader");
            var regFile = (delegate* unmanaged<IntPtr, IntPtr, int>)Slot(Factory, F_RegisterFontFileLoader);
            Check(regFile(Factory, fileLoader), "RegisterFontFileLoader");
        }

        internal static IntPtr CreateCustomFontCollection(IntPtr loader, int collId)
        {
            var fn = (delegate* unmanaged<IntPtr, IntPtr, void*, uint, IntPtr*, int>)Slot(Factory, F_CreateCustomFontCollection);
            int key = collId;
            IntPtr coll;
            int hr = fn(Factory, loader, &key, 4, &coll);
            Check(hr, "CreateCustomFontCollection");
            return coll;
        }

        internal static int CreateCustomFontFileReference(IntPtr factory, int fontIndex, IntPtr* fontFile)
        {
            var fn = (delegate* unmanaged<IntPtr, void*, uint, IntPtr, IntPtr*, int>)Slot(factory, F_CreateCustomFontFileReference);
            int key = fontIndex;
            IntPtr loader = ServerHandles.FileLoader;
            return fn(factory, &key, 4, loader, fontFile);
        }

        internal static IntPtr CreateFontFaceFromFile(string path, uint faceIndex)
        {
            var mk = (delegate* unmanaged<IntPtr, char*, IntPtr, IntPtr*, int>)Slot(Factory, F_CreateFontFileReference);
            IntPtr file;
            fixed (char* p = path) Check(mk(Factory, p, IntPtr.Zero, &file), "CreateFontFileReference");
            var cf = (delegate* unmanaged<IntPtr, int, uint, IntPtr*, uint, int, IntPtr*, int>)Slot(Factory, F_CreateFontFace);
            IntPtr* files = stackalloc IntPtr[1];
            files[0] = file;
            IntPtr face;
            Check(cf(Factory, 1, 1, files, faceIndex, 0, &face), "CreateFontFace");
            return face;
        }

        internal static bool FindFamilyName(IntPtr collection, string name, out int index)
        {
            var fn = (delegate* unmanaged<IntPtr, char*, uint*, int*, int>)Slot(collection, C_FindFamilyName);
            uint idx; int exists;
            fixed (char* p = name)
            {
                Check(fn(collection, p, &idx, &exists), "FindFamilyName");
            }
            index = (int)idx;
            return exists != 0;
        }

        internal static int FontFamilyCount(IntPtr collection)
        {
            var fn = (delegate* unmanaged<IntPtr, uint>)Slot(collection, C_GetFontFamilyCount);
            return (int)fn(collection);
        }

        internal static IntPtr CreateTextFormat(IntPtr collection, string family, int weight, int style,
                                                int stretch, float size, string locale)
        {
            var fn = (delegate* unmanaged<IntPtr, char*, IntPtr, int, int, int, float, char*, IntPtr*, int>)Slot(Factory, F_CreateTextFormat);
            IntPtr fmt;
            fixed (char* f = family)
            fixed (char* l = locale)
            {
                Check(fn(Factory, f, collection, weight, style, stretch, size, l, &fmt), "CreateTextFormat");
            }
            return fmt;
        }

        internal static void SetWordWrapping(IntPtr format, int mode)
        {
            var fn = (delegate* unmanaged<IntPtr, int, int>)Slot(format, TF_SetWordWrapping);
            Check(fn(format, mode), "SetWordWrapping");
        }

        internal static IntPtr CreateTextLayout(string text, IntPtr format, float maxWidth, float maxHeight)
        {
            var fn = (delegate* unmanaged<IntPtr, char*, uint, IntPtr, float, float, IntPtr*, int>)Slot(Factory, F_CreateTextLayout);
            IntPtr layout;
            fixed (char* p = text)
            {
                Check(fn(Factory, p, (uint)text.Length, format, maxWidth, maxHeight, &layout), "CreateTextLayout");
            }
            return layout;
        }

        internal static DWRITE_TEXT_METRICS LayoutMetrics(IntPtr layout)
        {
            var fn = (delegate* unmanaged<IntPtr, DWRITE_TEXT_METRICS*, int>)Slot(layout, TL_GetMetrics);
            DWRITE_TEXT_METRICS m;
            Check(fn(layout, &m), "IDWriteTextLayout::GetMetrics");
            return m;
        }

        internal static DWRITE_LINE_METRICS[] LineMetrics(IntPtr layout)
        {
            // DWrite returns E_INSUFFICIENT_BUFFER for maxLineCount = 0 (it does not support the
            // "query the count first" pattern), so always hand it a real buffer.
            const int cap = 512;
            var fn = (delegate* unmanaged<IntPtr, DWRITE_LINE_METRICS*, uint, uint*, int>)Slot(layout, TL_GetLineMetrics);
            var arr = new DWRITE_LINE_METRICS[cap];
            uint got;
            fixed (DWRITE_LINE_METRICS* p = arr)
            {
                Check(fn(layout, p, cap, &got), "GetLineMetrics");
            }
            if (got > cap) got = cap;
            var res = new DWRITE_LINE_METRICS[got];
            Array.Copy(arr, res, (int)got);
            return res;
        }

        internal static DWRITE_HIT_TEST_METRICS[] HitTestTextRange(IntPtr layout, uint pos, uint len)
        {
            var fn = (delegate* unmanaged<IntPtr, uint, uint, float, float, DWRITE_HIT_TEST_METRICS*, uint, uint*, int>)Slot(layout, TL_HitTestTextRange);
            const int cap = 512;
            var arr = new DWRITE_HIT_TEST_METRICS[cap];
            uint actual;
            fixed (DWRITE_HIT_TEST_METRICS* p = arr)
            {
                Check(fn(layout, pos, len, 0f, 0f, p, cap, &actual), "HitTestTextRange");
            }
            if (actual > cap) actual = cap;
            var res = new DWRITE_HIT_TEST_METRICS[actual];
            Array.Copy(arr, res, (int)actual);
            return res;
        }

        internal static void HitTestTextPosition(IntPtr layout, uint pos, int trailing, out float x, out float y,
                                                 out DWRITE_HIT_TEST_METRICS m)
        {
            var fn = (delegate* unmanaged<IntPtr, uint, int, float*, float*, DWRITE_HIT_TEST_METRICS*, int>)Slot(layout, TL_HitTestTextPosition);
            float px, py;
            DWRITE_HIT_TEST_METRICS hm;
            Check(fn(layout, pos, trailing, &px, &py, &hm), "HitTestTextPosition");
            x = px; y = py; m = hm;
        }

        internal static void Check(int hr, string what)
        {
            if (hr < 0) throw new Exception(what + " failed: 0x" + hr.ToString("x8"));
        }
    }

    internal static class ServerHandles
    {
        internal static IntPtr CollLoader, FileLoader;
    }
}

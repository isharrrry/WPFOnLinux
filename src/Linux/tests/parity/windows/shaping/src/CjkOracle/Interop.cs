using System;
using System.Runtime.InteropServices;

namespace CjkOracle
{
    // ------------------------------------------------------------------
    //  DirectWrite interop with raw vtable function pointers.
    //
    //  Neither [ComImport] interfaces nor Marshal.GetDelegateForFunctionPointer are
    //  used: the former produced invalid stubs (0xC0000005) and the latter returned
    //  garbage HRESULTs intermittently.  `delegate* unmanaged<...>` is what upstream
    //  WPF uses in MS.Internal.Interop.DWrite and has no marshalling or stub-lifetime
    //  machinery at all.
    //
    //  Slot indices come from the MIDL-generated Windows SDK header dwrite.h
    //  (package Microsoft.Windows.SDK.CPP 10.0.29648.1000-preview):
    //    IDWriteFactory         3 GetSystemFontCollection ... 7 CreateFontFileReference
    //                           9 CreateFontFace ... 21 CreateTextAnalyzer
    //    IDWriteFontFace        3 GetType 4 GetFiles 5 GetIndex 6 GetSimulations
    //                           7 IsSymbolFont 8 GetMetrics 9 GetGlyphCount
    //    IDWriteTextAnalyzer    3 AnalyzeScript 4 AnalyzeBidi 5 AnalyzeNumberSubstitution
    //                           6 AnalyzeLineBreakpoints 7 GetGlyphs 8 GetGlyphPlacements
    // ------------------------------------------------------------------

    [StructLayout(LayoutKind.Sequential)]
    internal struct DWRITE_SCRIPT_ANALYSIS
    {
        public ushort script;
        public int shapes;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DWRITE_FONT_METRICS
    {
        public ushort designUnitsPerEm, ascent, descent, lineGap, capHeight, xHeight;
        public short underlinePosition, underlineThickness, strikethroughPosition, strikethroughThickness;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DWRITE_GLYPH_OFFSET
    {
        public float advanceOffset, ascenderOffset;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DWRITE_SHAPING_TEXT_PROPERTIES { public ushort value; }

    [StructLayout(LayoutKind.Sequential)]
    internal struct DWRITE_SHAPING_GLYPH_PROPERTIES { public ushort value; }

    internal static unsafe class Vtbl
    {
        internal static void* Slot(IntPtr obj, int index)
        {
            return (void*)Marshal.ReadIntPtr(Marshal.ReadIntPtr(obj), index * IntPtr.Size);
        }
    }

    internal sealed unsafe class DWrite
    {
        private const int FACTORY_TYPE_SHARED = 0;
        private const int FONT_FACE_TYPE_TRUETYPE = 1;
        private const int FONT_FACE_TYPE_OPENTYPE_COLLECTION = 2;   // .ttc: faceIndex selects the face
        private const int FONT_SIMULATIONS_NONE = 0;

        private static readonly Guid IID_IDWriteFactory = new Guid("b859ee5a-d838-4b5b-a2e8-1adc7d93db48");

        [DllImport("dwrite.dll", ExactSpelling = true, PreserveSig = true)]
        private static extern int DWriteCreateFactory(int factoryType, ref Guid iid, out IntPtr factory);

        public readonly IntPtr Factory;
        public readonly IntPtr Analyzer;

        public DWrite()
        {
            Guid iid = IID_IDWriteFactory;
            int hr = DWriteCreateFactory(FACTORY_TYPE_SHARED, ref iid, out IntPtr factory);
            Check(hr, "DWriteCreateFactory");
            Factory = factory;

            var createTextAnalyzer =
                (delegate* unmanaged<IntPtr, IntPtr*, int>)Vtbl.Slot(Factory, 21);
            IntPtr analyzer;
            hr = createTextAnalyzer(Factory, &analyzer);
            Check(hr, "IDWriteFactory::CreateTextAnalyzer");
            Analyzer = analyzer;
        }

        public IntPtr CreateFontFileReference(string path)
        {
            var fn = (delegate* unmanaged<IntPtr, char*, IntPtr, IntPtr*, int>)Vtbl.Slot(Factory, 7);
            IntPtr file;
            fixed (char* p = path)
            {
                int hr = fn(Factory, p, IntPtr.Zero, &file);
                Check(hr, "CreateFontFileReference");
            }
            return file;
        }

        /// <summary>
        /// faceIndex matters for .ttc font collections: NotoSansCJK-Regular.ttc packs
        /// 0=JP 1=KR 2=SC 3=TC 4=HK into one file, so the same code points can resolve to
        /// different glyphs depending on the face (that is the `locl` feature at work).
        /// </summary>
        public IntPtr CreateFontFace(IntPtr fontFile, uint faceIndex, bool collection = false)
        {
            var fn = (delegate* unmanaged<IntPtr, int, uint, IntPtr*, uint, int, IntPtr*, int>)Vtbl.Slot(Factory, 9);
            IntPtr* files = stackalloc IntPtr[1];
            files[0] = fontFile;
            IntPtr face;
            int faceType = collection ? FONT_FACE_TYPE_OPENTYPE_COLLECTION : FONT_FACE_TYPE_TRUETYPE;
            int hr = fn(Factory, faceType, 1, files, faceIndex, FONT_SIMULATIONS_NONE, &face);
            Check(hr, "CreateFontFace(faceType=" + faceType + ", faceIndex=" + faceIndex + ")");
            return face;
        }

        public static int FaceType(IntPtr face)
            => ((delegate* unmanaged<IntPtr, int>)Vtbl.Slot(face, 3))(face);

        public static int GlyphCount(IntPtr face)
            => ((delegate* unmanaged<IntPtr, ushort>)Vtbl.Slot(face, 9))(face);

        public static DWRITE_FONT_METRICS FaceMetrics(IntPtr face)
        {
            var fn = (delegate* unmanaged<IntPtr, DWRITE_FONT_METRICS*, int>)Vtbl.Slot(face, 8);
            DWRITE_FONT_METRICS m;
            int hr = fn(face, &m);
            Check(hr, "IDWriteFontFace::GetMetrics");
            return m;
        }

        public void GetGlyphs(IntPtr face, string text, DWRITE_SCRIPT_ANALYSIS* sa,
            ushort* textToGlyph, DWRITE_SHAPING_TEXT_PROPERTIES* textProps,
            ushort* glyphIndices, DWRITE_SHAPING_GLYPH_PROPERTIES* glyphProps,
            uint maxGlyphCount, out uint actualGlyphCount)
        {
            var fn = (delegate* unmanaged<IntPtr, char*, uint, IntPtr, int, int, DWRITE_SCRIPT_ANALYSIS*,
                char*, IntPtr, IntPtr, IntPtr, uint, uint, ushort*, DWRITE_SHAPING_TEXT_PROPERTIES*,
                ushort*, DWRITE_SHAPING_GLYPH_PROPERTIES*, uint*, int>)Vtbl.Slot(Analyzer, 7);
            uint actual;
            fixed (char* p = text)
            fixed (char* loc = "en-us")
            {
                int hr = fn(Analyzer, p, (uint)text.Length, face, 0, 0, sa, loc, IntPtr.Zero, IntPtr.Zero,
                            IntPtr.Zero, 0, maxGlyphCount, textToGlyph, textProps, glyphIndices, glyphProps, &actual);
                Check(hr, "IDWriteTextAnalyzer::GetGlyphs");
            }
            actualGlyphCount = actual;
        }

        public void GetGlyphPlacements(IntPtr face, string text, float emSize, DWRITE_SCRIPT_ANALYSIS* sa,
            ushort* textToGlyph, DWRITE_SHAPING_TEXT_PROPERTIES* textProps,
            ushort* glyphIndices, DWRITE_SHAPING_GLYPH_PROPERTIES* glyphProps, uint glyphCount,
            float* advances, DWRITE_GLYPH_OFFSET* offsets)
        {
            var fn = (delegate* unmanaged<IntPtr, char*, ushort*, DWRITE_SHAPING_TEXT_PROPERTIES*, uint,
                ushort*, DWRITE_SHAPING_GLYPH_PROPERTIES*, uint, IntPtr, float, int, int,
                DWRITE_SCRIPT_ANALYSIS*, char*, IntPtr, IntPtr, uint, float*, DWRITE_GLYPH_OFFSET*, int>)Vtbl.Slot(Analyzer, 8);
            fixed (char* p = text)
            fixed (char* loc = "en-us")
            {
                int hr = fn(Analyzer, p, textToGlyph, textProps, (uint)text.Length, glyphIndices, glyphProps,
                            glyphCount, face, emSize, 0, 0, sa, loc, IntPtr.Zero, IntPtr.Zero, 0, advances, offsets);
                Check(hr, "IDWriteTextAnalyzer::GetGlyphPlacements");
            }
        }

        internal static void Check(int hr, string what)
        {
            if (hr < 0) throw new Exception(what + " failed: 0x" + hr.ToString("x8"));
        }
    }
}

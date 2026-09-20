using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Windows;
using System.Windows.Markup;
using System.Windows.Media;
using Microsoft.Win32;

namespace U1SystemFontsOracle
{
    /// <summary>
    /// SystemFonts / SPI truth oracle.
    ///
    /// WHY: on the Linux side text currently renders as *nothing* under the default
    /// configuration, and the suspected root cause is that "the face that supplies glyph
    /// ids is not the face that rasterizes" (the renderer falls back to a hard-coded
    /// family name that does not exist in /usr/share/fonts, while WPF resolves
    /// SystemFonts.MessageFontFamily to a real family). The relationship between
    ///   SystemFonts.* property  ->  family name  ->  actual font FILE  ->  family names
    /// recorded inside that file
    /// was being guessed. This tool records it instead.
    ///
    /// WHAT IT DUMPS (all read-only, nothing is modified):
    ///   1. every public static property of SystemFonts (enumerated by reflection, so a
    ///      newly added property cannot be silently missed), with FontFamily-valued
    ///      properties fully resolved to files
    ///   2. Fonts.SystemFontFamilies: count, first five in enumeration order, and whether
    ///      MessageFontFamily is a member - answered four different ways (Equals /
    ///      Source string / localized FamilyNames / resolved file URI)
    ///   3. the raw SystemParametersInfo values behind those properties, plus the
    ///      registry values they are stored in, plus the active theme name and the theme
    ///      files - i.e. evidence about whether the value is theme-dependent
    ///   4. TextFormattingMode / TextRenderingMode defaults
    ///   5. sha256 of every font file referenced
    ///
    /// ANTI-FALSE-GREEN: every family must resolve to an existing file (recorded with a
    /// hash); a deliberately bogus family name must NOT resolve - that negative control
    /// is what proves the resolution check has teeth; --sabotage makes the tool report
    /// the bogus name as if it were the real one, which must turn the checks red.
    /// </summary>
    internal static class Program
    {
        private const string Format = "wpf-linux-u1a-systemfonts/1";
        private const string BogusFamily = "__NoSuchFontFamily_U1__";

        [STAThread]
        private static int Main(string[] args)
        {
            string outDir = @"C:\wpf-oracle-systemfonts\out";
            bool sabotage = false;
            foreach (string a in args)
            {
                if (a == "--sabotage") sabotage = true;
                else if (!a.StartsWith("--")) outDir = a;
            }

            Directory.CreateDirectory(outDir);
            Console.WriteLine($"U1SystemFontsOracle: outDir={outDir} sabotage={sabotage}");

            var failures = new List<string>();

            // ---------- 1. every SystemFonts property ----------
            var systemFonts = new List<object>();
            foreach (PropertyInfo p in typeof(SystemFonts)
                         .GetProperties(BindingFlags.Public | BindingFlags.Static))
            {
                object value;
                try { value = p.GetValue(null); }
                catch (Exception ex)
                {
                    systemFonts.Add(J.O().Add("property", p.Name).Add("type", p.PropertyType.Name)
                        .Add("error", ex.GetType().Name + ": " + ex.Message));
                    continue;
                }

                var rec = J.O()
                    .Add("property", p.Name)
                    .Add("type", p.PropertyType.Name);

                if (value is FontFamily ff)
                {
                    // --sabotage deliberately breaks the RESOLUTION, not just the label:
                    // claiming a family name that resolves to no file is exactly the
                    // failure mode this oracle exists to catch, so the checks must refuse
                    // to ship the result (non-zero exit).
                    bool broken = sabotage && p.Name == "MessageFontFamily";
                    FontFamily resolved = broken ? new FontFamily(BogusFamily) : ff;

                    rec.Add("source", broken ? BogusFamily : ff.Source);
                    rec.Add("reportedSource", ff.Source);
                    rec.Add("familyNames", DictObj(FamilyNames(resolved)));
                    rec.Add("typefaces", TypefaceList(resolved));
                    rec.Add("resolvedFiles", ResolvedFiles(resolved));
                    rec.Add("baseUri", resolved.BaseUri == null ? null : resolved.BaseUri.ToString());
                    rec.Add("nameMatchesFileFamilyName", NameMatchesFile(resolved));
                    rec.Add("sabotaged", broken);

                    if (ResolvedFiles(resolved).Count == 0)
                        failures.Add($"SystemFonts.{p.Name} ('{resolved.Source}') resolves to NO font file" +
                                     (broken ? " [sabotaged]" : ""));
                }
                else if (value is double d) rec.Add("value", d);
                else if (value is FontWeight w) rec.Add("openTypeWeight", w.ToOpenTypeWeight());
                else if (value is FontStyle st) rec.Add("value", st.ToString());
                else if (value is FontStretch sc) rec.Add("value", sc.ToString());
                else if (value is TextDecorationCollection tdc)
                    rec.Add("value", tdc == null ? "null" : "count=" + tdc.Count);
                else rec.Add("value", value == null ? null : value.ToString());

                systemFonts.Add(rec);
            }

            // ---------- 2. Fonts.SystemFontFamilies ----------
            FontFamily message = SystemFonts.MessageFontFamily;
            ICollection<FontFamily> allFamilies = Fonts.SystemFontFamilies;
            var names1 = new List<string>();
            foreach (FontFamily f in allFamilies) names1.Add(f.Source);
            var names2 = new List<string>();
            foreach (FontFamily f in Fonts.SystemFontFamilies) names2.Add(f.Source);

            bool orderStable = names1.Count == names2.Count;
            if (orderStable)
                for (int i = 0; i < names1.Count; i++)
                    if (names1[i] != names2[i]) { orderStable = false; break; }

            bool memberByEquals = allFamilies.Contains(message);
            bool memberBySource = names1.Contains(message.Source);
            string messageLocalizedName = FirstFamilyName(message);
            bool memberByLocalizedName = false;
            var sameFileFamilies = new List<string>();
            var messageFiles = new HashSet<string>(ResolvedFiles(message));
            foreach (FontFamily f in allFamilies)
            {
                foreach (string n in FamilyNames(f).Values)
                    if (n == messageLocalizedName) memberByLocalizedName = true;
                foreach (string file in ResolvedFiles(f))
                    if (messageFiles.Contains(file)) sameFileFamilies.Add(f.Source);
            }

            var systemFontFamilies = J.O()
                .Add("count", names1.Count)
                .Add("firstFiveInEnumerationOrder", names1.GetRange(0, Math.Min(5, names1.Count)))
                .Add("enumerationOrderStableAcrossTwoCalls", orderStable)
                .Add("firstFiveSecondCall", names2.GetRange(0, Math.Min(5, names2.Count)))
                .Add("messageFontFamilySource", message.Source)
                .Add("messageFontFamilyLocalizedNames", DictObj(FamilyNames(message)))
                .Add("messageFontFamilyInCollection", J.O()
                    .Add("byEquals", memberByEquals)
                    .Add("bySourceString", memberBySource)
                    .Add("byLocalizedFamilyName", memberByLocalizedName)
                    .Add("verdict", (memberBySource || memberByLocalizedName)
                        ? "YES - present (matched by name)"
                        : "NO - not present by name")
                    .Add("note", "byEquals uses object identity; WPF returns a fresh FontFamily instance " +
                                 "for SystemFonts, so identity is expected to be false even when the " +
                                 "family is present - the meaningful comparisons are by name and by file."))
                .Add("familiesSharingMessageFontFile", sameFileFamilies)
                .Add("systemTypefacesCount", Fonts.SystemTypefaces.Count)
                .Add("messageFontFileInSystemTypefaces", MessageFilePresent(Fonts.SystemTypefaces, messageFiles))
                .Add("allFamilies", names1);

            // ---------- 3. raw SPI / registry / theme evidence ----------
            var spi = RawSpi();

            // ---------- 4. text rendering defaults ----------
            var dependency = new System.Windows.DependencyObject();
            var textDefaults = J.O()
                .Add("TextFormattingMode.default", TextOptions.GetTextFormattingMode(dependency).ToString())
                .Add("TextRenderingMode.default", TextOptions.GetTextRenderingMode(dependency).ToString())
                .Add("TextHintingMode.default", TextOptions.GetTextHintingMode(dependency).ToString())
                .Add("TextFormattingMode.onTextBlock", TextOptions.GetTextFormattingMode(new System.Windows.Controls.TextBlock()).ToString())
                .Add("dpiScale", System.Windows.Media.VisualTreeHelper.GetDpi(new System.Windows.Media.DrawingVisual()).PixelsPerDip)
                .Add("note", "TextOptions.GetTextFormattingMode on a fresh DependencyObject returns the " +
                             "process default that a TextBlock inherits when nothing sets it explicitly.");

            // ---------- 5. negative control: a bogus family must NOT resolve ----------
            var bogus = new FontFamily(BogusFamily);
            var bogusFiles = ResolvedFiles(bogus);
            bool negativeControlOk = bogusFiles.Count == 0;
            if (!negativeControlOk)
                failures.Add($"negative control failed: bogus family '{BogusFamily}' resolved to {bogusFiles.Count} file(s)");

            if (!spi.FaceNamesNonEmpty)
                failures.Add("SPI returned an empty face name for at least one system font");

            // ---------- write ----------
            var root = J.O()
                .Add("format", Format)
                .Add("generatedAtUtc", DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture))
                .Add("sabotage", sabotage)
                .Add("sabotageNote", sabotage
                    ? $"DELIBERATE BREAK: SystemFonts.MessageFontFamily is reported as '{BogusFamily}'"
                    : "normal run")
                .Add("environment", EnvironmentInfo())
                .Add("systemFonts", systemFonts)
                .Add("systemFontFamilies", systemFontFamilies)
                .Add("rawSpi", spi.Json)
                .Add("textRenderingDefaults", textDefaults)
                .Add("negativeControl", J.O()
                    .Add("bogusFamily", BogusFamily)
                    .Add("resolvedFiles", bogusFiles)
                    .Add("ok", negativeControlOk)
                    .Add("why", "a family that does not exist must not resolve to a font file; " +
                                "otherwise the resolution check in this tool proves nothing"))
                .Add("failures", new List<object>(failures.ToArray()));

            File.WriteAllText(Path.Combine(outDir, "windows-results.json"), Json.Serialize(root),
                new UTF8Encoding(false));

            Console.WriteLine();
            Console.WriteLine($"systemFonts properties={systemFonts.Count} " +
                              $"SystemFontFamilies={names1.Count} (orderStable={orderStable})");
            Console.WriteLine($"message family source='{message.Source}' " +
                              $"localized='{messageLocalizedName}' files={messageFiles.Count} " +
                              $"inSystemFontFamilies=(bySource={memberBySource}, byName={memberByLocalizedName}, byEquals={memberByEquals})");
            Console.WriteLine($"negative control ok={negativeControlOk} failures={failures.Count} sabotage={sabotage}");
            foreach (string f in failures) Console.WriteLine("  ! " + f);

            return failures.Count == 0 ? 0 : 2;
        }

        // ==================================================================
        //  family resolution
        // ==================================================================

        private static string KeyName(object key) => key switch
        {
            CultureInfo ci => ci.Name,
            XmlLanguage xl => xl.IetfLanguageTag,
            null => "null",
            _ => key.ToString(),
        };

        private static Dictionary<string, string> Map<TKey>(IEnumerable<KeyValuePair<TKey, string>> src)
        {
            var d = new Dictionary<string, string>();
            if (src == null) return d;
            foreach (KeyValuePair<TKey, string> kv in src) d[KeyName(kv.Key)] = kv.Value;
            return d;
        }

        private static Dictionary<string, string> FamilyNames(FontFamily ff) => Map(ff.FamilyNames);

        /// <summary>Dictionaries must become ordered JSON objects, not KeyValuePair lists.</summary>
        private static JObj DictObj(Dictionary<string, string> d)
        {
            var o = J.O();
            if (d == null) return o;
            foreach (KeyValuePair<string, string> kv in d) o.Add(kv.Key, kv.Value);
            return o;
        }

        /// <summary>
        /// THE P0 QUESTION IN ONE BOOLEAN: does the family name WPF reports match the
        /// family name recorded INSIDE the font file it resolved to? A false here is the
        /// Windows-side shape of "the face that supplies glyph ids is not the face that
        /// rasterizes".
        /// </summary>
        private static string NameMatchesFile(FontFamily ff)
        {
            string wanted = ff.Source;
            var inner = new List<string>();
            foreach (Typeface tf in ff.GetTypefaces())
            {
                if (!tf.TryGetGlyphTypeface(out GlyphTypeface gt)) continue;
                foreach (var kv in gt.FamilyNames) inner.Add(kv.Value);
                foreach (var kv in gt.Win32FamilyNames) inner.Add(kv.Value);
            }
            if (inner.Count == 0) return "no-file";
            foreach (string n in inner)
                if (string.Equals(n, wanted, StringComparison.OrdinalIgnoreCase)) return "yes";
            return "no (file family names: " + string.Join(" | ", inner.ToArray()) + ")";
        }

        private static string FirstFamilyName(FontFamily ff)
        {
            foreach (var kv in ff.FamilyNames) return kv.Value;
            return ff.Source;
        }

        private static bool MessageFilePresent(ICollection<Typeface> all, HashSet<string> messageFiles)
        {
            foreach (Typeface tf in all)
            {
                if (!tf.TryGetGlyphTypeface(out GlyphTypeface gt)) continue;
                if (messageFiles.Contains(LocalPath(gt.FontUri))) return true;
            }
            return false;
        }

        private static List<object> TypefaceList(FontFamily ff)
        {
            var list = new List<object>();
            ICollection<Typeface> typefaces;
            try { typefaces = ff.GetTypefaces(); }
            catch (Exception ex)
            {
                list.Add(J.O().Add("error", ex.GetType().Name + ": " + ex.Message));
                return list;
            }

            foreach (Typeface tf in typefaces)
            {
                var rec = J.O()
                    .Add("weight", tf.Weight.ToOpenTypeWeight())
                    .Add("style", tf.Style.ToString())
                    .Add("stretch", tf.Stretch.ToString());

                if (tf.TryGetGlyphTypeface(out GlyphTypeface gt))
                {
                    rec.Add("glyphTypeface", true);
                    rec.Add("fontUri", gt.FontUri.ToString());
                    rec.Add("isCompositeFont", gt.FontUri.ToString().IndexOf(".CompositeFont",
                        StringComparison.OrdinalIgnoreCase) >= 0);
                    rec.Add("glyphCount", gt.GlyphCount);
                    rec.Add("familyNames", DictObj(Map(gt.FamilyNames)));
                    rec.Add("win32FamilyNames", DictObj(Map(gt.Win32FamilyNames)));
                    rec.Add("faceNames", DictObj(Map(gt.FaceNames)));
                    rec.Add("win32FaceNames", DictObj(Map(gt.Win32FaceNames)));
                    rec.Add("versionStrings", StringList(gt.VersionStrings));
                    rec.Add("localFile", LocalPath(gt.FontUri));
                    rec.Add("sha256", Sha256Of(LocalPath(gt.FontUri)));
                }
                else
                {
                    rec.Add("glyphTypeface", false);
                }
                list.Add(rec);
            }
            return list;
        }

        /// <summary>Distinct local font files behind a family (empty = the family has no face).</summary>
        private static List<string> ResolvedFiles(FontFamily ff)
        {
            var files = new List<string>();
            ICollection<Typeface> typefaces;
            try { typefaces = ff.GetTypefaces(); }
            catch (Exception) { return files; }

            foreach (Typeface tf in typefaces)
            {
                if (!tf.TryGetGlyphTypeface(out GlyphTypeface gt)) continue;
                string path = LocalPath(gt.FontUri);
                if (path != null && !files.Contains(path)) files.Add(path);
            }
            return files;
        }

        private static string LocalPath(Uri uri)
        {
            if (uri == null) return null;
            try { return uri.IsFile ? uri.LocalPath : uri.ToString(); }
            catch (Exception) { return uri.ToString(); }
        }

        private static List<object> StringList<TKey>(IEnumerable<KeyValuePair<TKey, string>> map)
        {
            var l = new List<object>();
            if (map == null) return l;
            foreach (KeyValuePair<TKey, string> kv in map) l.Add(KeyName(kv.Key) + "=" + kv.Value);
            return l;
        }

        private static string Sha256Of(string path)
        {
            try
            {
                if (string.IsNullOrEmpty(path) || !File.Exists(path)) return null;
                using SHA256 sha = SHA256.Create();
                using FileStream fs = File.OpenRead(path);
                return Convert.ToHexString(sha.ComputeHash(fs)).ToLowerInvariant();
            }
            catch (Exception) { return null; }
        }

        // ==================================================================
        //  raw SPI + registry + theme evidence
        // ==================================================================

        private const uint SPI_GETNONCLIENTMETRICS = 0x0029;
        private const uint SPI_GETICONTITLELOGFONT = 0x001F;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct LOGFONT
        {
            public int lfHeight, lfWidth, lfEscapement, lfOrientation, lfWeight;
            public byte lfItalic, lfUnderline, lfStrikeOut, lfCharSet, lfOutPrecision,
                        lfClipPrecision, lfQuality, lfPitchAndFamily;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string lfFaceName;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct NONCLIENTMETRICS
        {
            public uint cbSize;
            public int iBorderWidth, iScrollWidth, iScrollHeight, iCaptionWidth, iCaptionHeight;
            public LOGFONT lfCaptionFont;
            public int iSmCaptionWidth, iSmCaptionHeight;
            public LOGFONT lfSmCaptionFont;
            public int iMenuWidth, iMenuHeight;
            public LOGFONT lfMenuFont;
            public LOGFONT lfStatusFont;
            public LOGFONT lfMessageFont;
            public int iPaddedBorderWidth;
        }

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref NONCLIENTMETRICS pvParam, uint fWinIni);

        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        private static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref LOGFONT pvParam, uint fWinIni);

        private sealed class SpiResult
        {
            public JObj Json;
            public bool FaceNamesNonEmpty = true;
        }

        private static SpiResult RawSpi()
        {
            var res = new SpiResult();
            var ncm = new NONCLIENTMETRICS();
            ncm.cbSize = (uint)Marshal.SizeOf(typeof(NONCLIENTMETRICS));
            bool ncmOk = SystemParametersInfo(SPI_GETNONCLIENTMETRICS, ncm.cbSize, ref ncm, 0);
            int ncmErr = Marshal.GetLastWin32Error();

            var icon = new LOGFONT();
            bool iconOk = SystemParametersInfo(SPI_GETICONTITLELOGFONT, (uint)Marshal.SizeOf(typeof(LOGFONT)), ref icon, 0);
            int iconErr = Marshal.GetLastWin32Error();

            var fonts = new List<object>();
            if (ncmOk)
            {
                fonts.Add(LogFont("lfMessageFont", ncm.lfMessageFont));
                fonts.Add(LogFont("lfCaptionFont", ncm.lfCaptionFont));
                fonts.Add(LogFont("lfSmCaptionFont", ncm.lfSmCaptionFont));
                fonts.Add(LogFont("lfMenuFont", ncm.lfMenuFont));
                fonts.Add(LogFont("lfStatusFont", ncm.lfStatusFont));
            }
            if (iconOk) fonts.Add(LogFont("SPI_GETICONTITLELOGFONT", icon));

            foreach (object o in fonts)
            {
                var rec = (JObj)o;
                foreach (KeyValuePair<string, object> kv in rec.Items)
                    if (kv.Key == "faceName" && string.IsNullOrEmpty(kv.Value as string))
                        res.FaceNamesNonEmpty = false;
            }

            var registry = new List<object>();
            registry.Add(RegString(@"HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics", "MessageFont"));
            registry.Add(RegString(@"HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics", "CaptionFont"));
            registry.Add(RegString(@"HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics", "SmCaptionFont"));
            registry.Add(RegString(@"HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics", "MenuFont"));
            registry.Add(RegString(@"HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics", "StatusFont"));
            registry.Add(RegString(@"HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics", "IconFont"));

            object currentTheme = RegValue(
                @"HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes", "CurrentTheme");

            res.Json = J.O()
                .Add("nonClientMetrics", J.O()
                    .Add("call", "SystemParametersInfo(SPI_GETNONCLIENTMETRICS)")
                    .Add("cbSize", ncm.cbSize)
                    .Add("ok", ncmOk)
                    .Add("lastError", ncmErr))
                .Add("logFonts", fonts)
                .Add("registryWindowMetrics", registry)
                .Add("currentThemeRegistryValue", currentTheme == null ? null : currentTheme.ToString())
                .Add("themeFiles", ThemeFiles())
                .Add("fontSubstitutes", FontSubstitutes())
                .Add("readOnly", "SPI_GET* and registry reads only; nothing was written, no theme was changed");
            return res;
        }

        private static object RegValue(string fullKey, string name)
        {
            try
            {
                string sub = fullKey.StartsWith("HKEY_CURRENT_USER\\", StringComparison.Ordinal)
                    ? fullKey.Substring("HKEY_CURRENT_USER\\".Length) : fullKey;
                using RegistryKey k = Registry.CurrentUser.OpenSubKey(sub);
                return k?.GetValue(name);
            }
            catch (Exception) { return null; }
        }

        private static JObj LogFont(string which, LOGFONT lf) => J.O()
            .Add("which", which)
            .Add("faceName", lf.lfFaceName)
            .Add("height", lf.lfHeight)
            .Add("weight", lf.lfWeight)
            .Add("italic", lf.lfItalic != 0)
            .Add("charSet", lf.lfCharSet)
            .Add("pitchAndFamily", lf.lfPitchAndFamily);

        private static object RegString(string key, string name)
        {
            try
            {
                using RegistryKey k = Registry.CurrentUser.OpenSubKey(
                    key.StartsWith("HKEY_CURRENT_USER\\") ? key.Substring("HKEY_CURRENT_USER\\".Length) : key);
                if (k == null) return J.O().Add("name", name).Add("present", false);
                object v = k.GetValue(name);
                if (v == null) return J.O().Add("name", name).Add("present", false);

                if (v is byte[] bytes)
                {
                    // stored as a LOGFONT blob: the face name is the trailing UTF-16 string
                    string face = ExtractFaceName(bytes);
                    return J.O().Add("name", name).Add("present", true)
                        .Add("kind", "REG_BINARY").Add("bytes", bytes.Length)
                        .Add("faceNameFromBlob", face)
                        .Add("hex", Convert.ToHexString(bytes));
                }
                return J.O().Add("name", name).Add("present", true).Add("value", v.ToString());
            }
            catch (Exception ex)
            {
                return J.O().Add("name", name).Add("error", ex.GetType().Name + ": " + ex.Message);
            }
        }

        /// <summary>
        /// Pulls the face name out of a LOGFONTW blob. The documented layout puts it at
        /// offset 28, but the WindowMetrics values are written by several different code
        /// paths, so a scan for the longest plausible UTF-16 run is used as a fallback.
        /// </summary>
        private static string ExtractFaceName(byte[] blob)
        {
            if (blob == null || blob.Length < 4) return null;

            string at28 = ReadUtf16(blob, 28);
            if (!string.IsNullOrEmpty(at28)) return at28;

            string best = null;
            for (int start = 0; start + 3 < blob.Length; start += 2)
            {
                string s = ReadUtf16(blob, start);
                if (s != null && s.Length >= 3 && (best == null || s.Length > best.Length)) best = s;
            }
            return best;
        }

        private static string ReadUtf16(byte[] blob, int start)
        {
            if (start < 0 || start + 1 >= blob.Length) return null;
            var sb = new StringBuilder();
            for (int i = start; i + 1 < blob.Length && sb.Length < 64; i += 2)
            {
                char c = (char)(blob[i] | (blob[i + 1] << 8));
                if (c == '\0') break;
                if (c < 0x20 || c > 0x7E) { return null; }   // not a plain face name
                sb.Append(c);
            }
            return sb.Length == 0 ? null : sb.ToString();
        }

        private static List<object> ThemeFiles()
        {
            var list = new List<object>();
            try
            {
                string dir = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.Windows), "Resources", "Themes");
                if (!Directory.Exists(dir)) return list;

                foreach (string file in Directory.GetFiles(dir, "*.theme"))
                {
                    var lines = new List<object>();
                    bool inWindowMetrics = false;
                    bool sawWindowMetricsSection = false;
                    foreach (string raw in File.ReadAllLines(file))
                    {
                        string t = raw.Trim();
                        if (t.StartsWith("["))
                        {
                            inWindowMetrics = t.IndexOf("WindowMetrics", StringComparison.OrdinalIgnoreCase) >= 0;
                            if (inWindowMetrics) sawWindowMetricsSection = true;
                            continue;
                        }
                        if (!inWindowMetrics) continue;
                        if (t.StartsWith("MessageFont", StringComparison.OrdinalIgnoreCase) ||
                            t.StartsWith("CaptionFont", StringComparison.OrdinalIgnoreCase) ||
                            t.StartsWith("MenuFont", StringComparison.OrdinalIgnoreCase) ||
                            t.StartsWith("StatusFont", StringComparison.OrdinalIgnoreCase) ||
                            t.StartsWith("SmCaptionFont", StringComparison.OrdinalIgnoreCase) ||
                            t.StartsWith("IconFont", StringComparison.OrdinalIgnoreCase))
                            lines.Add(t);
                    }
                    list.Add(J.O()
                        .Add("file", file)
                        .Add("bytes", new FileInfo(file).Length)
                        .Add("sha256", Sha256Of(file))
                        .Add("hasWindowMetricsSection", sawWindowMetricsSection)
                        .Add("windowMetricFontLines", lines));
                }
            }
            catch (Exception ex)
            {
                list.Add(J.O().Add("error", ex.GetType().Name + ": " + ex.Message));
            }
            return list;
        }

        private static List<object> FontSubstitutes()
        {
            var list = new List<object>();
            try
            {
                using RegistryKey k = Registry.LocalMachine.OpenSubKey(
                    @"SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes");
                if (k == null) return list;
                foreach (string name in k.GetValueNames())
                {
                    string val = k.GetValue(name) as string;
                    if (name.IndexOf("shell", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        name.IndexOf("Segoe", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        name.IndexOf("Tahoma", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        name.IndexOf("MS Sans", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        name.IndexOf("System", StringComparison.OrdinalIgnoreCase) >= 0)
                        list.Add(J.O().Add("alias", name).Add("target", val));
                }
            }
            catch (Exception ex)
            {
                list.Add(J.O().Add("error", ex.GetType().Name + ": " + ex.Message));
            }
            return list;
        }

        // ==================================================================
        //  environment
        // ==================================================================

        private static JObj EnvironmentInfo()
        {
            var core = typeof(Visual).Assembly;
            string coreVersion = "unknown", coreSha = "unknown";
            try
            {
                coreVersion = FileVersionInfo.GetVersionInfo(core.Location).FileVersion;
                coreSha = Sha256Of(core.Location);
            }
            catch (Exception) { }

            string wpfgfxVersion = "unknown", wpfgfxSha = "unknown";
            try
            {
                string p = Path.Combine(Path.GetDirectoryName(core.Location), "wpfgfx_cor3.dll");
                wpfgfxVersion = FileVersionInfo.GetVersionInfo(p).FileVersion;
                wpfgfxSha = Sha256Of(p);
            }
            catch (Exception) { }

            return J.O()
                .Add("machineName", System.Environment.MachineName)
                .Add("osVersion", System.Environment.OSVersion.VersionString)
                .Add("is64BitProcess", System.Environment.Is64BitProcess)
                .Add("sessionId", Process.GetCurrentProcess().SessionId)
                .Add("userInteractive", System.Environment.UserInteractive)
                .Add("frameworkDescription", RuntimeInformation.FrameworkDescription)
                .Add("presentationCoreFileVersion", coreVersion)
                .Add("presentationCoreSha256", coreSha)
                .Add("wpfgfxCor3FileVersion", wpfgfxVersion)
                .Add("wpfgfxCor3Sha256", wpfgfxSha)
                .Add("windowsFontsDirectory",
                    Path.Combine(System.Environment.GetFolderPath(System.Environment.SpecialFolder.Windows), "Fonts"))
                .Add("userCulture", CultureInfo.CurrentUICulture.Name)
                .Add("systemCulture", CultureInfo.InstalledUICulture.Name);
        }
    }
}

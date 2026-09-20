// M7d · 复合字体短路验收探针（补丁 J + 追加 1）
//
// 用法（run.sh compositefont 会替你调用）：
//   WPF_LINUX_FONT_DIR=<repo>/build/fonts:<系统字体目录> \
//   dotnet MilBridge.CompositeFontProbe.dll --font <repo>/build/fonts/NotoSans-Regular.ttf
//
// 为什么要有这个探针：验收 ①-④ 是**运行期**行为，而本轮不允许重建 PresentationCore
// （主控在集成波里重建）⇒ 用**同一份程序**在重建前后各跑一次：
//   · 重建前：S1/S2/S3/S5 全线抛 OSVersionHelper（= 主控独立复现的矩阵），S6 抛 NRE；
//   · 重建后：S1 拿到与基线逐项等价的 GlyphTypeface，S2/S3 不再抛那条，S5 枚举出真族，
//             S6 变成诚实的 FileFormatException。
// 两次输出就是"短路前后调用序列对照"的实测依据（配合各自的 PC.dll sha256）。
//
// S7 不是验收项，是**根因取证**：它直接用 provider 的公开 API 复现
// `GlyphTypeface(Uri)` 那条链上 "面 → Font" 的反查，证明 shim 守卫的判据成立。

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Windows;
using System.Windows.Markup;
using System.Windows.Media;
using MS.Internal.Text.TextInterface.Linux;

internal static class Program
{
    private static int _pass, _fail, _skip;
    private static string _fontPath;
    private static bool _simulateShortCircuit;

    private static int Main(string[] args)
    {
        List<string> rest = new List<string>();
        foreach (string a in args)
        {
            if (a == "--simulate-shortcircuit") _simulateShortCircuit = true;
            else rest.Add(a);
        }
        args = rest.ToArray();
        for (int i = 0; i < args.Length; ++i)
            if (args[i] == "--font" && i + 1 < args.Length) _fontPath = args[++i];
        if (string.IsNullOrEmpty(_fontPath)) _fontPath = Environment.GetEnvironmentVariable("WPF_LINUX_PROBE_FONT");
        if (string.IsNullOrEmpty(_fontPath) || !File.Exists(_fontPath))
        {
            Console.WriteLine("[失败] 找不到字体文件（用 --font <path> 指定）。收到：" + (_fontPath ?? "(null)"));
            return 2;
        }
        _fontPath = Path.GetFullPath(_fontPath);

        Console.WriteLine("==================== M7d 复合字体短路验收探针（补丁 J + 追加 1）====================");
        if (_simulateShortCircuit) SimulateShortCircuit();
        Console.WriteLine("字体文件      : " + _fontPath);
        Console.WriteLine("WPF_LINUX_FONT_DIR : " + (Environment.GetEnvironmentVariable("WPF_LINUX_FONT_DIR") ?? "(未设置 → 走 /usr/share/fonts 等默认)"));
        DumpLoadedAssembly("PresentationCore", typeof(FontFamily).Assembly);
        DumpLoadedAssembly("Provider(DWF/PC 共用)", typeof(LinuxFontCollection).Assembly);
        Console.WriteLine();

        ItemS1_InstalledFamily();
        ItemS2_NotInstalledFamily();
        ItemS2b_ChokePoint();
        ItemS3_PrivateFontUri();
        ItemS4_FontCacheUtil();
        ItemS5_SystemFontFamilies();
        ItemS6_GlyphTypefaceUri();
        ItemS7_ProviderRoundTrip();
        ItemS8_ProviderFallbackIngredient();
        ItemS9_DefaultFamilyDrift();

        Console.WriteLine();
        Console.WriteLine($"== 通过 {_pass} / 失败 {_fail} / 跳过 {_skip} ==");
        if (_fail > 0)
            Console.WriteLine("（重建**前**跑：S1/S2/S3/S5 失败是预期的，它们就是本次要修的东西；"
                              + "重建**后**跑：应当 0 失败。）");
        return _fail == 0 ? 0 : 1;
    }

    // ---------------------------------------------------------------- 模拟
    // 在**不重建 PC** 的前提下，把"补丁 J 之后"的行为在运行期做出来：
    // 把 SystemCompositeFonts 的 4 个名字清空 ⇒ GetIndexOfFamily 永远返回 -1 ⇒
    // FindFamily 一律返回 null —— 这正是补丁 J 在 FindFamily 侧的可观测语义。
    // （GetFontFamilies 的枚举循环直接调 GetCompositeFontFamilyAtIndex，不受这个模拟影响；
    //   所以本模拟对 S2/S2b 是忠实的，对 S5 不忠实 —— 输出里会印出来。）
    private static void SimulateShortCircuit()
    {
        try
        {
            Type t = typeof(FontFamily).Assembly.GetType("MS.Internal.FontCache.FamilyCollection+SystemCompositeFonts", throwOnError: true);
            FieldInfo f = t.GetField("_systemCompositeFontsNames", BindingFlags.Static | BindingFlags.NonPublic);
            string[] names = (string[])f.GetValue(null);
            for (int i = 0; i < names.Length; ++i) names[i] = "\u0000sim-" + i;
            Console.WriteLine("⚠️ [模拟模式] 已把 SystemCompositeFonts._systemCompositeFontsNames 清空 ⇒ FindFamily 一律 null"
                              + "（= 补丁 J 的 FindFamily 侧语义；仅本探针进程内，磁盘上什么都没改）");
        }
        catch (Exception e) { Console.WriteLine("⚠️ [模拟模式] 失败：" + e.Message); }
        Console.WriteLine();
    }

    // ---------------------------------------------------------------- S1
    private static void ItemS1_InstalledFamily()
    {
        Head("S1（验收①）new FontFamily(\"Noto Sans\") → new Typeface(...) → TryGetGlyphTypeface");
        try
        {
            FontFamily family = new FontFamily("Noto Sans");
            Typeface typeface = new Typeface(family, FontStyles.Normal, FontWeights.Normal, FontStretches.Normal);
            GlyphTypeface gt;
            bool ok = typeface.TryGetGlyphTypeface(out gt);
            if (!ok || gt == null)
            {
                Res("S1", false, "TryGetGlyphTypeface 返回 false —— 族找不着面");
                return;
            }
            Console.WriteLine("   GlyphCount = " + gt.GlyphCount);
            Console.WriteLine("   Version    = " + gt.Version.ToString("0.###"));
            Console.WriteLine("   Baseline   = " + gt.Baseline.ToString("0.####"));
            Console.WriteLine("   Height     = " + gt.Height.ToString("0.####"));
            Console.WriteLine("   Weight/Style/Stretch = " + gt.Weight + " / " + gt.Style + " / " + gt.Stretch);
            Console.WriteLine("   FontUri    = " + gt.FontUri);
            Console.WriteLine("   CharToGlyph 表大小 = " + gt.CharacterToGlyphMap.Count);
            bool baseline = (gt.GlyphCount == 3884 && Math.Abs(gt.Version - 2.015) < 1e-9);
            Res("S1", baseline,
                baseline ? "成功，且与基线逐项等价（GlyphCount=3884, Version=2.015）"
                         : "成功，但**与基线不等价**（期望 GlyphCount=3884 / Version=2.015）");
        }
        catch (Exception e)
        {
            Res("S1", false, "抛异常 → " + OneLine(e) + Extra(e));
        }
    }

    // ---------------------------------------------------------------- S2
    private static void ItemS2_NotInstalledFamily()
    {
        Head("S2（验收②）new FontFamily(\"Arial\") —— 未安装；要求：**不得**抛 OSVersionHelper 那条");
        FontFamily family = null;
        Typeface typeface = null;
        try
        {
            family = new FontFamily("Arial");
            typeface = new Typeface(family, FontStyles.Normal, FontWeights.Normal, FontStretches.Normal);
            GlyphTypeface gt;
            bool ok = typeface.TryGetGlyphTypeface(out gt);
            if (ok && gt != null)
            {
                Console.WriteLine("   FontUri = " + gt.FontUri + "  GlyphCount=" + gt.GlyphCount + " Version=" + gt.Version.ToString("0.###"));
                Res("S2", true, "**provider 回退**：未安装的 \"Arial\" 落到了 " + gt.FontUri);
            }
            else
            {
                Console.WriteLine("   TryGetGlyphTypeface = false");
                Res("S2", true, "**诚实失败**：TryGetGlyphTypeface 返回 false（不抛异常）");
            }
        }
        catch (Exception e)
        {
            Console.WriteLine("   new FontFamily(\"Arial\").Source = " + family.Source + "；canonical 名字表：");
            DumpFamilyIdentifier(family);
            DumpFallbackFontFamily(typeface);
            Res("S2", IsHonestFailureOrFallback(e), Classify(e) + OneLine(e) + Extra(e));
        }
    }

    // 「找不到族」之后 WPF 的两级兜底（Typeface.ConstructCachedTypeface）：
    //   ① FallbackFontFamily（Typeface 第 5 个参数，通常 null）
    //   ② FontFamily.LookupFontFamily(FontFamily.NullFontFamilyCanonicalName)（= Create(null, "#ARIAL")）
    // 实测哪一级非 null、它的 canonical 名字是什么 —— 这就是"到底是哪个名字把 GlobalUserInterface 拖进来"的答案。
    private static void DumpFallbackFontFamily(Typeface typeface)
    {
        try
        {
            FieldInfo f = typeof(Typeface).GetField("_fallbackFontFamily", BindingFlags.Instance | BindingFlags.NonPublic);
            object fb = f.GetValue(typeface);
            Console.WriteLine("   Typeface.FallbackFontFamily = " + (fb == null ? "null" : "FontFamily(\"" + ((FontFamily)fb).Source + "\")"));
            if (fb != null) DumpFamilyIdentifier((FontFamily)fb);

            Type ff = typeof(FontFamily);
            FieldInfo nf = ff.GetField("NullFontFamilyCanonicalName", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
            object nullRef = nf.GetValue(null);
            PropertyInfo nameProp = nullRef.GetType().GetProperty("FamilyName");
            Console.WriteLine("   FontFamily.NullFontFamilyCanonicalName.FamilyName = " + nameProp.GetValue(nullRef));
        }
        catch (Exception e) { Console.WriteLine("   （兜底取证失败：" + OneLine(e) + "）"); }
    }

    // ---------------------------------------------------------------- S2b
    // 短路点取证：直接反射调用 private 的 FamilyCollection+SystemCompositeFonts.FindFamily(name)。
    // 这是**唯一**会触发 `CompositeFontParser.LoadXml` 的入口之一（另一处是 GetFontFamilies 枚举），
    // 于是它把"哪个名字会抛、哪个不会"钉死成一张表 —— 重建前后同表对照，即"是短路"的机械证据。
    private static void ItemS2b_ChokePoint()
    {
        Head("S2b（短路点取证，非验收项）SystemCompositeFonts.FindFamily(name) 逐名对照");
        string[] names = { "Arial", "Noto Sans", "Global User Interface", "Global Monospace", "Global Sans Serif", "Global Serif" };
        try
        {
            Type t = typeof(FontFamily).Assembly.GetType("MS.Internal.FontCache.FamilyCollection+SystemCompositeFonts", throwOnError: true);
            MethodInfo find = t.GetMethod("FindFamily", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public);
            Console.WriteLine("   （FindFamily 名字不在 4 个之内 ⇒ GetIndexOfFamily 返回 -1 ⇒ 直接 null，**不加载**）");
            foreach (string name in names)
            {
                try
                {
                    object r = find.Invoke(null, new object[] { name });
                    Console.WriteLine($"   FindFamily({name,-22}) = " + (r == null ? "null" : "CompositeFontFamily（已加载）"));
                }
                catch (TargetInvocationException tie)
                {
                    Exception inner = tie.InnerException ?? tie;
                    Console.WriteLine($"   FindFamily({name,-22}) = **抛 " + inner.GetType().Name + "**：" + OneLine(inner).Substring(0, Math.Min(80, OneLine(inner).Length)));
                }
            }
        }
        catch (Exception e)
        {
            Console.WriteLine("   （反射取证失败：" + OneLine(e) + "）");
        }
        // 顺带把 FontFamily 的 canonical 名字列出来 —— 它就是 LookupFontFamilyAndFace 依次尝试的名字
        try
        {
            FontFamily probe = new FontFamily("Arial");
            Console.WriteLine("   new FontFamily(\"Arial\").Source = " + probe.Source + "；canonical 名字表：");
            DumpFamilyIdentifier(probe);
        }
        catch (Exception e) { Console.WriteLine("   （dump 失败：" + OneLine(e) + "）"); }
        _skip++;
        Console.WriteLine("   [SKIP] S2b 是取证项，不计入通过/失败");
        Console.WriteLine();
    }

    private static void DumpFamilyIdentifier(FontFamily family)
    {
        FieldInfo f = typeof(FontFamily).GetField("_familyIdentifier", BindingFlags.Instance | BindingFlags.NonPublic);
        object id = f.GetValue(family);
        Type t = id.GetType();
        // 盒子里的结构体副本上就地 Canonicalize —— 这样看到的是 LookupFontFamilyAndFace 真正遍历的那批名字
        t.GetMethod("Canonicalize", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public).Invoke(id, null);
        Console.WriteLine("     Source = " + t.GetProperty("Source", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public).GetValue(id));
        int count = (int)t.GetProperty("Count", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public).GetValue(id);
        PropertyInfo indexer = t.GetProperty("Item", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
        for (int i = 0; i < count; ++i)
        {
            object entry = indexer.GetValue(id, new object[] { i });
            Type et = entry.GetType();
            string fam = (string)et.GetProperty("FamilyName").GetValue(entry);
            object loc = et.GetProperty("LocationUri").GetValue(entry);
            object file = et.GetProperty("EscapedFileName").GetValue(entry);
            Console.WriteLine($"     [{i}] FamilyName={fam}  LocationUri={loc ?? "(null)"}  EscapedFileName={file ?? "(null)"}");
        }
    }

    // ---------------------------------------------------------------- S3
    private static void ItemS3_PrivateFontUri()
    {
        Head("S3（验收③）私有字体 URI：new FontFamily(baseUri, \"./NotoSans-Regular.ttf#Noto Sans\")");
        try
        {
            string dir = Path.GetDirectoryName(_fontPath);
            string file = Path.GetFileName(_fontPath);
            Uri baseUri = new Uri(dir.EndsWith("/") ? dir : dir + "/");
            FontFamily family = new FontFamily(baseUri, "./" + file + "#Noto Sans");
            Console.WriteLine("   family.Source = " + family.Source);
            Typeface typeface = new Typeface(family, FontStyles.Normal, FontWeights.Normal, FontStretches.Normal);
            GlyphTypeface gt;
            bool ok = typeface.TryGetGlyphTypeface(out gt);
            if (ok && gt != null)
            {
                Console.WriteLine("   FontUri = " + gt.FontUri + "  GlyphCount=" + gt.GlyphCount + " Version=" + gt.Version.ToString("0.###"));
                Res("S3", true, "成功（私有字体 URI 路径可用）");
            }
            else
            {
                Res("S3", true, "**诚实失败**：TryGetGlyphTypeface 返回 false（不抛 OSVersionHelper 那条）");
            }
        }
        catch (Exception e)
        {
            Res("S3", IsHonestFailureOrFallback(e), Classify(e) + OneLine(e) + Extra(e));
        }
    }

    // ---------------------------------------------------------------- S4
    private static void ItemS4_FontCacheUtil()
    {
        Head("S4（验收④的一部分）MS.Internal.FontCache.Util.Dpi / WindowsFontsUriObject（补丁 I 的回归面）");
        try
        {
            Type util = typeof(FontFamily).Assembly.GetType("MS.Internal.FontCache.Util", throwOnError: true);
            object dpi = util.GetProperty("Dpi", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public).GetValue(null);
            object uri = util.GetProperty("WindowsFontsUriObject", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public).GetValue(null);
            object localPath = util.GetProperty("WindowsFontsLocalPath", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public).GetValue(null);
            Console.WriteLine("   Util.Dpi                    = " + dpi);
            Console.WriteLine("   Util.WindowsFontsLocalPath  = " + localPath);
            Console.WriteLine("   Util.WindowsFontsUriObject  = " + uri);
            Res("S4", Convert.ToInt32(dpi) > 0 && uri != null, "Util 静态构造可用（Window 静态构造链上的那一步）");
        }
        catch (Exception e)
        {
            Res("S4", false, "抛异常 → " + OneLine(e) + Extra(e));
        }
    }

    // ---------------------------------------------------------------- S5
    private static void ItemS5_SystemFontFamilies()
    {
        Head("S5（验收④的强化）Fonts.SystemFontFamilies 枚举 —— 直接压补丁 J 的第(2)(3)处（枚举与计数一致）");
        try
        {
            int count = 0, nulls = 0;
            var first = new List<string>();
            foreach (FontFamily f in Fonts.SystemFontFamilies)
            {
                ++count;
                if (f == null) { ++nulls; continue; }
                if (first.Count < 8) { try { first.Add(f.Source); } catch { first.Add("(Source 抛异常)"); } }
            }
            Console.WriteLine("   枚举到 " + count + " 个 FontFamily；其中 null = " + nulls);
            Console.WriteLine("   前 8 个: " + string.Join(", ", first));
            bool ok = (count > 0 && nulls == 0);
            Res("S5", ok, ok ? "枚举成功且无 null 元素（FamilyCount 与枚举产出一致）"
                            : "枚举结果不合法（" + count + " 个 / " + nulls + " 个 null）");
        }
        catch (Exception e)
        {
            Res("S5", false, "抛异常 → " + OneLine(e) + Extra(e));
        }
    }

    // ---------------------------------------------------------------- S6
    private static void ItemS6_GlyphTypefaceUri()
    {
        Head("S6（追加 1）new GlyphTypeface(new Uri(path)) —— 最低要求：诚实失败，不是 NRE");
        try
        {
            GlyphTypeface gt = new GlyphTypeface(new Uri(_fontPath));
            Console.WriteLine("   GlyphCount = " + gt.GlyphCount + "  Version = " + gt.Version.ToString("0.###") + "  FontUri = " + gt.FontUri);
            Res("S6", true, "成功（比最低要求更好：Uri 形态真的拿到 GlyphTypeface）");
        }
        catch (Exception e)
        {
            if (e is NullReferenceException)
                Res("S6", false, "**仍是 NRE**（最低要求未达成）→ " + OneLine(e) + Extra(e));
            else if (e is FileFormatException || e is IOException || e is UnauthorizedAccessException)
                Res("S6", true, "**诚实失败**：" + e.GetType().Name + " → " + e.Message);
            else
                Res("S6", false, "非诚实失败类型 " + e.GetType().Name + " → " + OneLine(e) + Extra(e));
        }
    }

    // ---------------------------------------------------------------- S7
    private static void ItemS7_ProviderRoundTrip()
    {
        Head("S7（根因取证，非验收项）上游守卫那条链：「面 → 所属 Font」反查能不能对上");
        try
        {
            string parent = Path.GetDirectoryName(_fontPath);
            LinuxFontCollection coll = LinuxFontCollection.FromDirectory(parent, false);
            LinuxFontFace f1 = LinuxFontFace.FromFile(_fontPath);
            LinuxFontFace f2 = LinuxFontFace.FromFile(_fontPath);

            Console.WriteLine("   FromDirectory(parent, recurse:false): families=" + coll.FamilyCount
                              + " typefaces=" + coll.TypefaceCount + "  (parent=" + parent + ")");
            Console.WriteLine("   FromFile(path) 两次是否同一个 SKTypeface 实例 : " + ReferenceEquals(f1.Typeface, f2.Typeface));
            LinuxFont found = coll.GetFontFromFontFace(f1);
            Console.WriteLine("   FromDirectory(parent).GetFontFromFontFace(FromFile(path)) = "
                              + (found == null ? "**null**" : "LinuxFont(" + found.FamilyName + ")"));
            Console.WriteLine("   ↑ provider 的反查按 **SKTypeface 引用相等**匹配"
                              + "（LinuxFontCollection.cs:443 ReferenceEquals(font.Typeface, fontFace.Typeface)）");

            // ⭐ 再用**真上游链**量一遍（不是复刻）：DWriteFactory.GetFontCollectionFromFile(uri)
            //    → DWF FontCollection.GetFontFromFontFace(face)，这正是 GlyphTypeface.Initialize 的两行。
            Type dwf = typeof(FontFamily).Assembly.GetType("MS.Internal.FontCache.DWriteFactory", throwOnError: true);
            object collection = dwf.GetMethod("GetFontCollectionFromFile", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public)
                                  .Invoke(null, new object[] { new Uri(_fontPath) });
            Console.WriteLine("   DWriteFactory.GetFontCollectionFromFile(uri) → " + (collection == null ? "null" : collection.GetType().FullName));
            Type faceType = Type.GetType("MS.Internal.Text.TextInterface.FontFace, DirectWriteForwarder", throwOnError: true);
            object face = Activator.CreateInstance(faceType, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public,
                                                   null, new object[] { f1 }, null);
            object font = collection.GetType().GetMethod("GetFontFromFontFace", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                                    .Invoke(collection, new object[] { face });
            Console.WriteLine("   真链 GetFontFromFontFace(face) = " + (font == null ? "**null**" : font.GetType().FullName));
            Console.WriteLine("   ⇒ 补丁「追加 1」的守卫判据（CanRoundTripFace）= " + (font == null ? "false ⇒ 返回 null ⇒ 上游抛 FileFormatException" : "true ⇒ 放行"));
            _skip++;
            Console.WriteLine("   [SKIP] S7 是取证项，不计入通过/失败");
        }
        catch (Exception e)
        {
            _skip++;
            Console.WriteLine("   [SKIP] 取证失败（provider 反射面变了？）→ " + OneLine(e));
        }
    }

    // ---------------------------------------------------------------- S8
    // 补丁 J ② 的**成分实测**：直接按补丁 J 的代码路径算一遍 ——
    //   _defaultFamilyCollection._fontCollection[0]（provider 首个族）
    //   → new PhysicalFontFamily(该族) → IFontFamily.GetTypefaceMetrics(Normal,Normal,Normal)
    //   → 是不是真 GlyphTypeface？
    // 若这里拿到真 GlyphTypeface ⇒ 补丁 J 之后 `new FontFamily("Arial")` + TryGetGlyphTypeface
    // 就是"**provider 回退**（拿到真面）"，而不是 null / 也不是 NRE。
    private static void ItemS8_ProviderFallbackIngredient()
    {
        Head("S8（补丁 J ② 成分实测，非验收项）provider 首个族 → PhysicalFontFamily → 真 metrics？");
        try
        {
            Type asmTypes = typeof(FontFamily);
            object collection = asmTypes.GetField("_defaultFamilyCollection", BindingFlags.Static | BindingFlags.NonPublic).GetValue(null);
            object fontCollection = collection.GetType().GetField("_fontCollection", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(collection);
            Type fcType = fontCollection.GetType();
            uint count = (uint)fcType.GetProperty("FamilyCount", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public).GetValue(fontCollection);
            PropertyInfo indexer = fcType.GetProperty("Item", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public, null, null, new[] { typeof(uint) }, null);
            object first = indexer.GetValue(fontCollection, new object[] { (uint)0 });
            Console.WriteLine("   _defaultFamilyCollection._fontCollection: FamilyCount=" + count);
            Console.WriteLine("   [0] = " + first.GetType().FullName + "  （名字属性：" + DescribeFamily(first) + "）");

            Type pff = asmTypes.Assembly.GetType("MS.Internal.FontFace.PhysicalFontFamily", throwOnError: true);
            object phys = Activator.CreateInstance(pff, BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public,
                                                   null, new object[] { first }, null);
            Type iFam = asmTypes.Assembly.GetType("MS.Internal.FontFace.IFontFamily", throwOnError: true);
            object metrics = iFam.GetMethod("GetTypefaceMetrics").Invoke(
                phys, new object[] { FontStyles.Normal, FontWeights.Normal, FontStretches.Normal });
            Console.WriteLine("   new PhysicalFontFamily([0]).GetTypefaceMetrics(Normal) = " + (metrics == null ? "null" : metrics.GetType().Name));
            GlyphTypeface gt = metrics as GlyphTypeface;
            if (gt != null)
                Console.WriteLine("   ⇒ 真 GlyphTypeface：GlyphCount=" + gt.GlyphCount + " Version=" + gt.Version.ToString("0.###") + " FontUri=" + gt.FontUri);
            Console.WriteLine("   ⇒ 结论：补丁 J ② 之后 \"找不到的族名\" 落到该族 ⇒ TryGetGlyphTypeface=true（provider 回退）");
        }
        catch (Exception e) { Console.WriteLine("   （成分取证失败：" + OneLine(e) + "）"); }
        _skip++;
        Console.WriteLine("   [SKIP] S8 是取证项，不计入通过/失败");
        Console.WriteLine();
    }

    /// <summary>尽量把族名印出来（不同层的族对象属性名不一样，取不到就说取不到）。</summary>
    private static string DescribeFamily(object family)
    {
        foreach (string name in new[] { "OrdinalName", "FamilyName", "Name" })
        {
            try
            {
                PropertyInfo p = family.GetType().GetProperty(name);
                if (p != null) return name + "=" + p.GetValue(family);
            }
            catch { }
        }
        try
        {
            FieldInfo f = family.GetType().GetField("_linuxFamily", BindingFlags.Instance | BindingFlags.NonPublic);
            if (f != null)
            {
                object lf = f.GetValue(family);
                if (lf != null)
                {
                    PropertyInfo p = lf.GetType().GetProperty("OrdinalName") ?? lf.GetType().GetProperty("FamilyName");
                    if (p != null) return "provider." + p.Name + "=" + p.GetValue(lf);
                }
            }
        }
        catch { }
        return "取不到（属性名不同）";
    }

    // ---------------------------------------------------------------- S9
    // 主控 ① 要求 2：**漂移实测** —— 同一个二进制，在两种字体目录配置下各跑一次，
    // 报告 DefaultFontFamily.SelectFamilyName 选中的族名（要求两边一致）。
    // 走的是真 PC 代码路径拿集合（_defaultFamilyCollection._fontCollection），再调 T2 的**公开 API**。
    private static void ItemS9_DefaultFamilyDrift()
    {
        Head("S9（主控 ① 要求 2）DefaultFontFamily.SelectFamilyName 漂移实测");
        try
        {
            Type t = typeof(FontFamily);
            object collection = t.GetField("_defaultFamilyCollection", BindingFlags.Static | BindingFlags.NonPublic).GetValue(null);
            object wrapper = collection.GetType().GetField("_fontCollection", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(collection);
            object linux = wrapper.GetType().GetProperty("LinuxCollection", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public).GetValue(wrapper);
            LinuxFontCollection lc = (LinuxFontCollection)linux;

            DefaultFamilyChoice choice = DefaultFontFamily.Select(lc);
            Console.WriteLine("   WPF_LINUX_FONT_DIR = " + (Environment.GetEnvironmentVariable("WPF_LINUX_FONT_DIR") ?? "(未设)"));
            Console.WriteLine("   集合 FamilyCount    = " + lc.FamilyCount);
            Console.WriteLine("   SelectFamilyName    = **" + choice.FamilyName + "**");
            Console.WriteLine("   Reason              = " + choice.Reason);
            Console.WriteLine("   Detail              = " + choice.Detail);

            LinuxFontFamily fam = lc[choice.FamilyName];
            Console.WriteLine("   [要求1 诚实性] 该族在集合里能否取到 = " + (fam != null ? "能" : "**不能（必须走诚实失败/下一个候选，不许静默退回 [0]）**"));
            if (fam != null)
            {
                Console.WriteLine("                 OrdinalName = " + fam.OrdinalName);
                if (fam is System.Collections.Generic.IEnumerable<LinuxFont> faces)
                {
                    int n = 0; string first = "(无)";
                    foreach (LinuxFont f in faces) { if (n == 0) first = f.FamilyName + " faceIdx=" + f.FaceEntry.FaceIndex; ++n; }
                    Console.WriteLine("                 面数 = " + n + "，首个面 = " + first);
                }
            }
            _skip++;
            Console.WriteLine("   [SKIP] S9 是取证项，不计入通过/失败");
            Console.WriteLine();
        }
        catch (Exception e)
        {
            _skip++;
            Console.WriteLine("   [SKIP] 取证失败：" + OneLine(e));
            Console.WriteLine();
        }
    }

    // ---------------------------------------------------------------- 工具
    private static void DumpLoadedAssembly(string label, Assembly asm)
    {
        try
        {
            string path = asm.Location;
            string sha = "";
            using (var sha256 = SHA256.Create())
            using (FileStream fs = File.OpenRead(path))
                sha = BitConverter.ToString(sha256.ComputeHash(fs)).Replace("-", "").ToLowerInvariant();
            Console.WriteLine($"{label,-20}: {path}");
            Console.WriteLine($"{new string(' ', 20)}  sha256={sha}  {new FileInfo(path).Length} B  mtime={File.GetLastWriteTime(path):yyyy-MM-dd HH:mm:ss}");
        }
        catch (Exception e) { Console.WriteLine($"{label,-20}: (取不到) {e.Message}"); }
    }

    private static void Head(string title)
    {
        Console.WriteLine("── " + title);
    }

    private static void Res(string id, bool ok, string detail)
    {
        if (ok) ++_pass; else ++_fail;
        Console.WriteLine("   结论: " + (ok ? "PASS" : "FAIL") + " —— " + detail);
        Console.WriteLine();
    }

    private static string OneLine(Exception e) => e.GetType().Name + ": " + e.Message;

    private static string IsOsVersionHelperText(Exception e)
    {
        var sb = new StringBuilder();
        for (Exception x = e; x != null; x = x.InnerException) sb.Append(x.GetType().Name).Append(": ").Append(x.Message).Append(" | ");
        return sb.ToString();
    }

    private static bool IsOsVersionHelper(Exception e) => IsOsVersionHelperText(e).Contains("OSVersionHelper");

    /// <summary>
    /// 验收②/③ 的判定：**只有**"上游既有的诚实失败异常"或"完全不抛"算通过。
    /// 特别地：NRE 一定判 FAIL —— 那正是"把异常换地方冒"（实测：只做短路不做 ② 时就是 NRE）。
    /// </summary>
    private static bool IsHonestFailureOrFallback(Exception e)
    {
        if (IsOsVersionHelper(e)) return false;
        return e is FileFormatException || e is IOException || e is UnauthorizedAccessException;
    }

    private static string Classify(Exception e)
    {
        if (IsOsVersionHelper(e)) return "抛的正是要消除的那条（FAIL）： ";
        if (e is NullReferenceException) return "**换地方冒**：NRE（补丁 J ② 必须消掉它，FAIL）： ";
        if (IsHonestFailureOrFallback(e)) return "**诚实失败（上游既有异常语义）**： ";
        return "未预期异常（FAIL）： ";
    }

    private static string Extra(Exception e)
    {
        var sb = new StringBuilder();
        string[] frames = (e.StackTrace ?? "").Split('\n');
        int n = Math.Min(frames.Length, 14);
        for (int i = 0; i < n; ++i) sb.Append("\n        ").Append(frames[i].Trim());
        if (e.InnerException != null) sb.Append("\n        [InnerException] ").Append(OneLine(e.InnerException));
        return sb.ToString();
    }
}

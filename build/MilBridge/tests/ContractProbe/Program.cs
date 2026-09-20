// T1/轨道A · **契约探针** —— 在写 TextLine 原型之前，先验证 4 个最可能不成立的托管侧假设。
//
//   P1  `new GlyphTypeface(new Uri(file://...))` 能不能直接指向 build/fonts 里的 ttf？
//       （不能的话，GlyphRun 就没有 GlyphTypeface 可喂）
//   P2  `new FontFamily("Noto Sans")` 能不能在 Linux 字体缓存里解析？
//       （TextRunProperties.Typeface 需要一个非 null 的 Typeface）
//   P3  `TextBounds` / `TextRunBounds` 的构造是 **internal** —— 反射能不能造出来？
//       （造不出来 ⇒ 外部程序集实现 TextLine 契约不完整 ⇒ 这是一条硬"连锁"）
//   P4  `new DrawingVisual().RenderOpen()` 在纯 PC 下能不能拿到 DrawingContext？
//       （决定 Draw 覆盖能不能被真正驱动）
//
// 只读引用已构建的 PresentationCore.dll —— **本轮不重建 PC**。

using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace MilBridge.ContractProbe
{
    internal static class Program
    {
        private const string Pc = "PresentationCore";

        private static int Main()
        {
            string root = FindRepoRoot();
            string fontPath = Path.Combine(root, "build", "fonts", "NotoSans-Bold.ttf");
            // PC 的字体缓存（补丁 I）指向平台字体目录；用 env 把它锁到我们的打包字体
            Environment.SetEnvironmentVariable("WPF_LINUX_FONTS_DIR", Path.Combine(root, "build", "fonts"));

            Console.WriteLine("== 轨道A 契约探针 ==");
            Console.WriteLine($"Win32 shim 在本目录 = {File.Exists(Path.Combine(AppContext.BaseDirectory, "libwpfwin32.so"))}");
            Console.WriteLine($"font = {fontPath} (exists={File.Exists(fontPath)})");
            Console.WriteLine($"PresentationCore = {typeof(TextLine).Assembly.GetName().FullName}");
            Console.WriteLine($"WindowsBase      = {typeof(DependencyObject).Assembly.GetName().FullName}");
            Console.WriteLine();

            int pass = 0, fail = 0;

            // ---------------- P1: GlyphTypeface(Uri) ----------------
            GlyphTypeface gt = null;
            try
            {
                gt = new GlyphTypeface(new Uri(fontPath));
                bool ok = gt != null && gt.GlyphCount > 0;
                Report("P1", "new GlyphTypeface(new Uri(file://…)) 指向 build/fonts 的 ttf", ok,
                    ok ? $"GlyphCount={gt.GlyphCount} FamilyNames={gt.FamilyNames.Count} Version={gt.Version}"
                       : "构造成功但 GlyphCount==0");
                if (ok) pass++; else fail++;
            }
            catch (Exception e)
            {
                Report("P1", "new GlyphTypeface(new Uri(file://…))", false, Ex(e));
                fail++;
            }

            // ---------------- P2: FontFamily / Typeface ----------------
            try
            {
                var ff = new FontFamily("Noto Sans");
                var tf = new Typeface(ff, FontStyles.Normal, FontWeights.Bold, FontStretches.Normal);
                bool resolved = tf.TryGetGlyphTypeface(out GlyphTypeface resolvedGt);
                Report("P2", "new FontFamily(\"Noto Sans\") + Typeface 解析", resolved,
                    resolved ? $"解析到 GlyphTypeface，GlyphCount={resolvedGt.GlyphCount}"
                             : "FontFamily 构造成功但 TryGetGlyphTypeface 返回 false（缓存里没这个族）");
                if (resolved) pass++; else fail++;
            }
            catch (Exception e)
            {
                Report("P2", "new FontFamily(\"Noto Sans\") + Typeface 解析", false, Ex(e));
                fail++;
            }

            // ---------------- P3: TextBounds / TextRunBounds 的 internal 构造 ----------------
            {
                Type tb = typeof(TextBounds);
                Type trb = Type.GetType("System.Windows.Media.TextFormatting.TextRunBounds, " + Pc, false);

                var pub = tb.GetConstructors(BindingFlags.Public | BindingFlags.Instance);
                var nonPub = tb.GetConstructors(BindingFlags.NonPublic | BindingFlags.Instance);
                Console.WriteLine($"      TextBounds: public ctor={pub.Length}  non-public ctor={nonPub.Length}");
                if (trb != null)
                {
                    var p2 = trb.GetConstructors(BindingFlags.Public | BindingFlags.Instance);
                    var n2 = trb.GetConstructors(BindingFlags.NonPublic | BindingFlags.Instance);
                    Console.WriteLine($"      TextRunBounds: public ctor={p2.Length}  non-public ctor={n2.Length}");
                }

                bool ok = false; string detail;
                try
                {
                    if (nonPub.Length == 0) { detail = "没有非公开构造可反射调用"; }
                    else
                    {
                        // 反射造一个 TextBounds（矩形 + 流向 + **正确类型**的 runBounds 列表）
                        Type iListOfTrb = nonPub[0].GetParameters()[2].ParameterType;
                        Type listOfTrb = typeof(List<>).MakeGenericType(iListOfTrb.GetGenericArguments()[0]);
                        object runBounds = Activator.CreateInstance(listOfTrb);
                        object bounds = nonPub[0].Invoke(new object[]
                        {
                            new Rect(0, 0, 10, 10), FlowDirection.LeftToRight, runBounds,
                        });
                        ok = bounds != null;
                        detail = ok
                            ? $"反射成功：Rectangle={((TextBounds)bounds).Rectangle}（ctor 参数 {nonPub[0].GetParameters().Length} 个）"
                            : "反射返回 null";
                    }
                }
                catch (Exception e)
                {
                    detail = "反射失败：" + Ex(e);
                }

                Report("P3", "TextBounds 只能反射构造（public ctor = 0）", ok, detail);
                if (ok) pass++; else fail++;
            }

            // ---------------- P4: DrawingVisual.RenderOpen() ----------------
            try
            {
                var visual = new DrawingVisual();
                using (DrawingContext dc = visual.RenderOpen())
                {
                    dc.DrawRectangle(Brushes.Black, null, new Rect(0, 0, 1, 1));
                }
                Report("P4", "new DrawingVisual().RenderOpen() 在纯 PC 下可用", true,
                    "拿到 DrawingContext 并画了一个矩形（Draw 覆盖可以被真正驱动）");
                pass++;
            }
            catch (Exception e)
            {
                Report("P4", "new DrawingVisual().RenderOpen() 在纯 PC 下可用", false, Ex(e));
                fail++;
            }

            // ---------------- P5: 走 WiringSmoke 已验证的序列拿 DWF Font → GlyphTypeface 内部 ctor ----------------
            try
            {
                const string TI = "MS.Internal.Text.TextInterface";
                Assembly dwf = Assembly.Load("DirectWriteForwarder");
                Type colType = dwf.GetType(TI + ".FontCollection", true);
                object col = colType.GetMethod("FromDirectory",
                        BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public)
                    .Invoke(null, new object[] { Path.Combine(root, "build", "fonts") });

                // 集合的 uint 索引器取第 0 个族（显式按参数类型取，避免 Item 重载歧义）
                Type famType = dwf.GetType(TI + ".FontFamily", true);
                PropertyInfo indexer = colType.GetProperty("Item",
                    BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic,
                    null, famType, new[] { typeof(uint) }, null);
                if (indexer == null) throw new MissingMemberException("FontCollection 上没有 uint 索引器");
                object family = indexer.GetValue(col, new object[] { 0u });
                if (family == null) throw new InvalidOperationException("集合为空：取不到第 0 个族");

                Type weightType = dwf.GetType(TI + ".FontWeight", true);
                Type stretchType = dwf.GetType(TI + ".FontStretch", true);
                Type styleType = dwf.GetType(TI + ".FontStyle", true);
                object bold = Enum.Parse(weightType, "Bold");
                object normalStretch = Enum.Parse(stretchType, "Normal");
                object normalStyle = Enum.Parse(styleType, "Normal");

                object font = family.GetType()
                    .GetMethod("GetFirstMatchingFont", BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public)
                    .Invoke(family, new[] { bold, normalStretch, normalStyle });

                ConstructorInfo gi = typeof(GlyphTypeface).GetConstructor(
                    BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public,
                    null, new[] { font.GetType() }, null);

                if (gi == null)
                {
                    Report("P5", "DWF Font → GlyphTypeface(内部 ctor)", false, "找不到 GlyphTypeface(Font) 构造");
                    fail++;
                }
                else
                {
                    var g2 = (GlyphTypeface)gi.Invoke(new[] { font });
                    bool ok = g2 != null && g2.GlyphCount > 0;
                    Report("P5", "DWF Font → GlyphTypeface(内部 ctor) → **真 GlyphTypeface**", ok,
                        ok ? $"GlyphCount={g2.GlyphCount} Version={g2.Version} Baseline={g2.Baseline:F4} " +
                             $"FaceNames={(g2.FaceNames != null ? g2.FaceNames.Count : -1)}"
                           : "构造成功但 GlyphCount==0");
                    if (ok) pass++; else fail++;
                }
            }
            catch (Exception e) { Report("P5", "DWF Font → GlyphTypeface(内部 ctor)", false, Ex(e)); fail++; }

            // ---------------- P6: GlyphRun 的构造路径 ----------------
            try
            {
                var gr = new GlyphRun();
                // BeginInit/EndInit 是 ISupportInitialize 的**显式实现**，必须强转才调得到
                var init = (System.ComponentModel.ISupportInitialize)gr;
                init.BeginInit();                   // ← setter 有 CheckInitializing()，必须先 BeginInit
                gr.GlyphIndices = new List<ushort> { 43, 72, 79 };
                gr.AdvanceWidths = new List<double> { 18.36, 14.328, 7.152 };
                gr.FontRenderingEmSize = 24.0;
                gr.BaselineOrigin = new Point(0, 20);
                gr.BidiLevel = 0;
                gr.IsSideways = false;
                gr.PixelsPerDip = 1.0f;

                string endInit = "未调 EndInit";
                try { init.EndInit(); endInit = "EndInit 也通过（无 GlyphTypeface 也能收尾）"; }
                catch (Exception e2) { endInit = "EndInit 抛：" + e2.GetType().Name + ": " + e2.Message; }

                bool ok = gr.GlyphIndices.Count == 3 && Math.Abs(gr.AdvanceWidths[1] - 14.328) < 1e-9;
                Report("P6", "BeginInit + 属性 setter 构造 GlyphRun", ok,
                    ok ? $"{endInit}；GlyphIndices={gr.GlyphIndices.Count} 个，AdvanceWidths[1]={gr.AdvanceWidths[1]}"
                       : "setter 未生效");
                if (ok) pass++; else fail++;
            }
            catch (Exception e) { Report("P6", "BeginInit + 属性 setter 构造 GlyphRun", false, Ex(e)); fail++; }

            Console.WriteLine();
            Console.WriteLine($"== 探针：通过 {pass} / 失败 {fail} ==");
            return fail == 0 ? 0 : 1;
        }

        private static void Report(string id, string what, bool ok, string detail)
        {
            Console.WriteLine($"  {(ok ? "PASS" : "FAIL")}  {id}  {what}");
            Console.WriteLine($"        {detail}");
        }

        private static string Ex(Exception e)
        {
            Exception inner = e is TargetInvocationException tie && tie.InnerException != null ? tie.InnerException : e;
            return inner.GetType().Name + ": " + inner.Message + "\n        栈: " + Short(inner);
        }

        private static string Short(Exception e)
        {
            string[] frames = (e.StackTrace ?? "").Split('\n');
            var sb = new System.Text.StringBuilder();
            for (int i = 0; i < Math.Min(3, frames.Length); i++) sb.Append(frames[i].Trim()).Append(" | ");
            return sb.ToString();
        }

        private static string FindRepoRoot()
        {
            var di = new DirectoryInfo(AppContext.BaseDirectory);
            for (int i = 0; i < 10 && di != null; i++, di = di.Parent)
                if (File.Exists(Path.Combine(di.FullName, "handoff.md"))) return di.FullName;
            throw new InvalidOperationException("找不到仓库根");
        }
    }
}

// B2/B3/B4 oracle · 环境/API 面/字体 探针
//
// 这一份的用途是**先把真值面摸清楚**再写对拍主体：
//   1. 环境（OS / .NET / DPI / culture）；
//   2. System.Windows.Media.TextFormatting 的**公开面反射 dump**（含枚举值）——
//      B2 要的"TextLineBreak 到底携带什么"、"GetTextCollapsedRanges 存不存在"
//      这类问题由它直接回答，不靠猜；
//   3. 系统字体里哪些能排 CJK，各自的**文件路径 + sha256**（字体不许安装，只能引用）；
//   4. 文件式加载 build/fonts/NotoSans-Regular.ttf 是否真的生效（用 GlyphTypeface.FontUri 证伪系统回退）；
//   5. **竖排文本**：公开面里有没有任何竖排入口（负结果也要有据）。

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace WpfOracleLayout
{
    internal static class Probe
    {
        [DllImport("user32.dll")]
        private static extern uint GetDpiForSystem();

        private static readonly JsonSerializerOptions Opt = new JsonSerializerOptions { WriteIndented = true };

        public static int Run(string outPath, string fontDir)
        {
            var root = new JsonObject();
            root["generatedUtc"] = DateTime.UtcNow.ToString("o");
            root["environment"] = Env();
            root["apiSurface"] = ApiSurface();
            root["fonts"] = FontTable(fontDir);
            root["verticalText"] = VerticalText();

            File.WriteAllText(outPath, root.ToJsonString(Opt));
            Console.WriteLine("wrote " + outPath);
            return 0;
        }

        // ------------------------------------------------------------------

        private static JsonObject Env()
        {
            var o = new JsonObject
            {
                ["machine"] = Environment.MachineName,
                ["user"] = Environment.UserName,
                ["osVersion"] = Environment.OSVersion.VersionString,
                ["osDescription"] = RuntimeInformation.OSDescription,
                ["processArch"] = RuntimeInformation.ProcessArchitecture.ToString(),
                ["dotnetVersion"] = Environment.Version.ToString(),
                ["runtimeDir"] = RuntimeEnvironment.GetRuntimeDirectory(),
                ["currentCulture"] = CultureInfo.CurrentCulture.Name,
                ["currentUICulture"] = CultureInfo.CurrentUICulture.Name,
                ["installedCultures"] = new JsonArray(
                    CultureInfo.GetCultures(CultureTypes.SpecificCultures)
                        .Select(c => c.Name)
                        .Where(n => n is "en-US" or "zh-CN" or "ja-JP" or "he-IL" or "ar-SA")
                        .OrderBy(n => n, StringComparer.Ordinal)
                        .Select(n => (JsonNode)n).ToArray()),
            };

            try { o["dpi"] = (int)GetDpiForSystem(); }
            catch (Exception e) { o["dpi"] = "ERR:" + e.Message; }

            // WPF 侧的程序集版本（真值来源要能追溯）
            o["assemblies"] = new JsonObject
            {
                ["PresentationCore"] = typeof(TextFormatter).Assembly.GetName().Version?.ToString(),
                ["PresentationCoreLocation"] = Safe(() => typeof(TextFormatter).Assembly.Location),
                ["WindowsBase"] = typeof(System.Windows.DependencyObject).Assembly.GetName().Version?.ToString(),
                ["SystemXaml"] = Safe(() => typeof(System.Windows.Markup.IAddChild).Assembly.GetName().Version?.ToString()),
            };

            return o;
        }

        private static string Safe(Func<string> f)
        {
            try { return f(); } catch (Exception e) { return "ERR:" + e.Message; }
        }

        // ------------------------------------------------------------------
        //  2. 公开面反射 dump
        // ------------------------------------------------------------------

        private static readonly Type[] SurfaceTypes =
        {
            typeof(TextFormatter),
            typeof(TextLine),
            typeof(TextLineBreak),
            typeof(TextCollapsedRange),
            typeof(TextRunBounds),
            typeof(CharacterHit),
            typeof(TextSource),
            typeof(TextRun),
            typeof(TextRunProperties),
            typeof(TextParagraphProperties),
            typeof(System.Windows.TextWrapping),
            typeof(System.Windows.TextTrimming),
            typeof(System.Windows.TextAlignment),
            typeof(System.Windows.LineStackingStrategy),
            typeof(System.Windows.FlowDirection),
            typeof(System.Windows.Media.TextFormattingMode),
            typeof(Fonts),
        };

        private static JsonObject ApiSurface()
        {
            var o = new JsonObject();
            foreach (Type t in SurfaceTypes)
            {
                var to = new JsonObject
                {
                    ["fullName"] = t.FullName,
                    ["isEnum"] = t.IsEnum,
                    ["isAbstract"] = t.IsAbstract,
                };

                if (t.IsEnum)
                {
                    var vals = new JsonArray();
                    foreach (string n in Enum.GetNames(t))
                        vals.Add(n + " = " + Convert.ToInt64(Enum.Parse(t, n), CultureInfo.InvariantCulture));
                    to["enumValues"] = vals;
                    o[t.Name] = to;
                    continue;
                }

                var props = new JsonArray();
                foreach (PropertyInfo p in t.GetProperties(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static)
                                               .OrderBy(p => p.Name, StringComparer.Ordinal))
                {
                    props.Add($"{p.PropertyType.Name} {p.Name} {{ {(p.CanRead ? "get; " : "")}{(p.CanWrite ? "set; " : "")}}}");
                }
                to["properties"] = props;

                var methods = new JsonArray();
                foreach (MethodInfo m in t.GetMethods(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static)
                                           .Where(m => !m.IsSpecialName)
                                           .OrderBy(m => m.Name, StringComparer.Ordinal))
                {
                    string ps = string.Join(", ", m.GetParameters().Select(p => p.ParameterType.Name + " " + p.Name));
                    methods.Add($"{m.ReturnType.Name} {m.Name}({ps})");
                }
                to["methods"] = methods;
                o[t.Name] = to;
            }
            return o;
        }

        // ------------------------------------------------------------------
        //  5. 竖排：公开面里有没有入口
        // ------------------------------------------------------------------

        private static JsonObject VerticalText()
        {
            var hits = new JsonArray();
            string[] needles = { "vertical", "writingmode", "writing-mode", "upright", "rotate",
                                 "tategaki", "lineorientation", "orientation", "glyphorientation" };

            foreach (Type t in typeof(TextFormatter).Assembly.GetExportedTypes())
            {
                if (!t.Namespace?.StartsWith("System.Windows.Media.TextFormatting") ?? true) continue;
                foreach (MemberInfo m in t.GetMembers(BindingFlags.Public | BindingFlags.Instance | BindingFlags.Static))
                {
                    string name = m.Name.ToLowerInvariant();
                    if (needles.Any(n => name.Contains(n))) hits.Add($"{t.Name}.{m.Name} ({m.MemberType})");
                }
            }

            var o = new JsonObject
            {
                ["suspectedUnsupported"] = true,
                ["namespaceMembersMatchingVerticalKeywords"] = hits,
                ["flowDirectionValues"] = new JsonArray(
                    Enum.GetNames(typeof(System.Windows.FlowDirection)).Select(n => (JsonNode)n).ToArray()),
                ["note"] = "上面这个数组为空 = 公开面里没有任何竖排入口；FlowDirection 只有 LTR/RTL 两个值。",
            };
            return o;
        }

        // ------------------------------------------------------------------
        //  3/4. 字体
        // ------------------------------------------------------------------

        private static JsonObject FontTable(string fontDir)
        {
            var o = new JsonObject();

            // 4) 文件式加载 + 证伪系统回退
            o["fileBased"] = FileBasedFont(fontDir);

            // 3) 系统里能排 CJK 的字族（只引用，不安装）
            string[] candidates =
            {
                "Microsoft YaHei", "Microsoft YaHei UI", "SimSun", "NSimSun", "SimHei", "KaiTi", "FangSong",
                "MingLiU", "PMingLiU", "MS Gothic", "MS Mincho", "Yu Gothic", "Meiryo", "Malgun Gothic",
                "Batang", "Gulim", "Arial Unicode MS", "DengXian", "Microsoft JhengHei",
            };

            var found = new JsonObject();
            var installed = new HashSet<string>(Fonts.SystemFontFamilies.Select(f => f.Source), StringComparer.OrdinalIgnoreCase);
            foreach (string c in candidates)
            {
                if (!installed.Contains(c)) { found[c] = null; continue; }
                var entry = new JsonObject();
                try
                {
                    var ff = new FontFamily(c);
                    var files = new JsonArray();
                    foreach (Typeface tf in ff.GetTypefaces())
                    {
                        if (tf.TryGetGlyphTypeface(out GlyphTypeface gtf))
                        {
                            string uri = gtf.FontUri.IsFile ? gtf.FontUri.LocalPath : gtf.FontUri.ToString();
                            var fo = new JsonObject { ["uri"] = uri };
                            try { if (File.Exists(uri)) fo["sha256"] = Sha256(uri); } catch { }
                            files.Add(fo);
                        }
                    }
                    entry["files"] = files;
                    entry["familyNames"] = new JsonArray(ff.FamilyNames.Values.Select(v => (JsonNode)v).ToArray());
                }
                catch (Exception e) { entry["error"] = e.GetType().Name + ": " + e.Message; }
                found[c] = entry;
            }
            o["systemCjkCandidates"] = found;
            o["systemFontFamilyCount"] = Fonts.SystemFontFamilies.Count;
            return o;
        }

        private static JsonObject FileBasedFont(string fontDir)
        {
            var o = new JsonObject { ["dir"] = fontDir };
            string fullDir = Path.GetFullPath(fontDir);
            string file = Path.Combine(fullDir, "NotoSans-Regular.ttf");
            o["fullDir"] = fullDir;
            o["file"] = file;
            o["fileExists"] = File.Exists(file);
            if (File.Exists(file)) o["fileSha256"] = Sha256(file);

            string dirUri = "file:///" + (fullDir.Replace('\\', '/').TrimEnd('/')) + "/";
            string fileUri = "file:///" + file.Replace('\\', '/');
            o["dirUri"] = dirUri;
            o["fileUri"] = fileUri;

            var variants = new JsonObject();

            // V1: 目录 URI + "./#Family"
            TryVariant(variants, "V1_newFontFamily_dirUri_dotSlashHash", () =>
                new FontFamily(new Uri(dirUri), "./#Noto Sans"));

            // V2: 目录 URI + "#Family"
            TryVariant(variants, "V2_newFontFamily_dirUri_hash", () =>
                new FontFamily(new Uri(dirUri), "#Noto Sans"));

            // V3: 文件 URI + "#Family"
            TryVariant(variants, "V3_newFontFamily_fileUri_hash", () =>
                new FontFamily(fileUri + "#Noto Sans"));

            // V4: Fonts.GetFontFamily —— 本机 .NET 10 的 System.Windows.Media.Fonts 里**没有**这个方法
            //     （编译期即失败，这里如实记录为"该 API 不存在"，见 apiSurface.Fonts.methods）

            o["variants"] = variants;

            // WPF 到底看不看得见这个目录里的 loose font
            try
            {
                var list = new JsonArray();
                foreach (FontFamily f in Fonts.GetFontFamilies(new Uri(dirUri)))
                    list.Add(f.Source + " :: " + string.Join("|", f.FamilyNames.Values));
                o["Fonts_GetFontFamilies_dirUri"] = list;
            }
            catch (Exception e) { o["Fonts_GetFontFamilies_dirUri"] = "ERR:" + e.GetType().Name + ": " + e.Message; }

            return o;
        }

        private static void TryVariant(JsonObject sink, string name, Func<FontFamily> make)
        {
            var r = new JsonObject();
            try
            {
                FontFamily ff = make();
                r["source"] = ff.Source;
                r["familyNames"] = new JsonArray(ff.FamilyNames.Values.Select(v => (JsonNode)v).ToArray());
                r["typefaceCount"] = ff.GetTypefaces().Count;
                var tf = new Typeface(ff, System.Windows.FontStyles.Normal,
                                      System.Windows.FontWeights.Normal, System.Windows.FontStretches.Normal);
                bool ok = tf.TryGetGlyphTypeface(out GlyphTypeface gtf);
                r["tryGetGlyphTypeface"] = ok;
                if (ok && gtf != null)
                {
                    r["glyphTypefaceUri"] = gtf.FontUri.IsFile ? gtf.FontUri.LocalPath : gtf.FontUri.ToString();
                    r["glyphCount"] = gtf.GlyphCount;
                    r["familyNamesFromGlyphTypeface"] = new JsonArray(gtf.FamilyNames.Values.Select(v => (JsonNode)v).ToArray());
                }
            }
            catch (Exception e) { r["error"] = e.GetType().Name + ": " + e.Message; }
            sink[name] = r;
        }

        private static string Sha256(string path)
        {
            using var sha = SHA256.Create();
            using FileStream fs = File.OpenRead(path);
            return Convert.ToHexString(sha.ComputeHash(fs)).ToLowerInvariant();
        }
    }
}

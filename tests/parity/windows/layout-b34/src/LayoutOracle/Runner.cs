// B2/B3/B4 oracle · 对拍主体
//
// 逐用例：TextFormatter.Create(mode).FormatLine(...) 循环取行，对**每一行** dump：
//   · TextLine 的全部公开属性（反射遍历，不挑字段）
//   · GetTextLineBreak() 的公开面（本轮实测：TextLineBreak **没有任何公开属性**）
//   · GetTextBounds(0, Length) → 每个 run 的 TextSourceCharacterIndex/Length/Rectangle/TextRun
//   · GetTextRunSpans() → run 跨度
//   · GetTextCollapsedRanges() → 折叠区间
//   · caret 五个 API 在若干位置的返回值
//   · GetIndexedGlyphRuns() 的条数与首个元素的公开属性
//
// 防假绿：文本非空、每例行数 > 0、行宽 > 0、消费长度 == 文本长度、
// 文件式字体必须真的解析到我们自己那份 ttf（否则抛错退出，绝不写空/半截文件）。

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace WpfOracleLayout
{
    internal static class Runner
    {
        private static readonly JsonSerializerOptions Opt = new JsonSerializerOptions { WriteIndented = true };
        private static readonly List<string> Problems = new List<string>();

        public static int Run(string casesPath, string outPath, string fontDir)
        {
            JsonNode root = JsonNode.Parse(File.ReadAllText(casesPath));
            JsonArray cases = root["cases"].AsArray();

            string fullFont = Path.GetFullPath(Path.Combine(fontDir, "NotoSans-Regular.ttf"));
            string fontDirFull = Path.GetDirectoryName(fullFont).Replace('\\', '/') + "/";
            var fontBaseUri = new Uri("file:///" + fontDirFull);

            // 字族解析：file = 文件式 Noto Sans；zh/ja = 系统字族（只引用，不安装）
            var families = new Dictionary<string, FontFamily>(StringComparer.Ordinal)
            {
                ["file"] = new FontFamily(fontBaseUri, "./#Noto Sans"),
                ["zh"] = new FontFamily("Microsoft YaHei"),
                ["ja"] = new FontFamily("Yu Gothic"),
                // 希伯来/阿拉伯要用带这些字形的系统字体（Noto Sans 没有），仍然只引用不安装
                ["bidi"] = new FontFamily("Segoe UI"),
            };

            var formatters = new Dictionary<string, TextFormatter>(StringComparer.Ordinal);
            var results = new JsonArray();

            foreach (JsonNode cn in cases)
            {
                JsonObject c = cn.AsObject();
                string id = (string)c["id"];
                try
                {
                    results.Add(RunCase(c, families, formatters));
                }
                catch (Exception e)
                {
                    Problems.Add($"{id}: {e.GetType().Name}: {e.Message}");
                    Console.Error.WriteLine($"CASE FAILED {id}: {e.Message}");
                }
                if (results.Count % 50 == 0) Console.WriteLine($"  ...{results.Count}/{cases.Count}");
            }

            // ---- 防假绿：先看数据，再决定写不写文件 ----
            if (Problems.Count > 0)
            {
                foreach (string p in Problems.Take(20)) Console.Error.WriteLine("  " + p);
                Console.Error.WriteLine($"FATAL: {Problems.Count} 个用例失败，拒绝写出结果文件（防假绿）");
                return 4;
            }
            if (results.Count != cases.Count)
            {
                Console.Error.WriteLine($"FATAL: 结果数 {results.Count} != 用例数 {cases.Count}");
                return 4;
            }

            JsonObject selfCheck = SelfCheck(results);
            var payload = new JsonObject
            {
                ["schema"] = "wpf-textlayout-oracle-results/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o"),
                ["api"] = "System.Windows.Media.TextFormatting.TextFormatter.FormatLine（公开 API）",
                ["indexFrames"] = new JsonObject
                {
                    ["lineStart"] = "TextLine.Start **恒为 0**（实测 3222/3222）：它不是段落内偏移；"
                                    + "行起点由调用方累加 Length 得到（本文件每行的 lineIndexInText 就是这个累加值）",
                    ["TextCollapsedRange.TextSourceCharacterIndex"] = "段落系（text source）索引",
                    ["TextRunBounds.TextSourceCharacterIndex"] = "段落系（text source）索引",
                    ["GetTextBounds_firstArg"] = "段落系索引；传 0 只有行起点=0 的行有结果",
                    ["NewlineLength"] = "本行末尾硬断字符个数；段落最后一行恒为 1（表示 EOP）",
                },
                ["environment"] = Env(),
                ["selfCheck"] = selfCheck,
                ["apiFacts"] = ApiFacts(),
                ["results"] = results,
            };

            if (selfCheck["ok"]?.GetValue<bool>() != true)
            {
                // 自检没过：**不写正式结果文件**，但写一份 .debug.json 以便定位
                // （否则"哪一行 Width=0 / 字体解析到哪了"只能靠猜）。
                string dbg = outPath + ".debug.json";
                File.WriteAllText(dbg, payload.ToJsonString(Opt));
                Console.Error.WriteLine("FATAL: 自检未通过，已写诊断文件 " + dbg);
                Console.Error.WriteLine("  " + selfCheck.ToJsonString());
                return 5;
            }

            File.WriteAllText(outPath, payload.ToJsonString(Opt));
            Console.WriteLine($"wrote {outPath}: {results.Count} cases");
            Console.WriteLine("selfCheck: " + selfCheck.ToJsonString());
            return 0;
        }

        // ------------------------------------------------------------------

        private static JsonObject RunCase(JsonObject c, Dictionary<string, FontFamily> families,
            Dictionary<string, TextFormatter> formatters)
        {
            string id = (string)c["id"];
            string text = (string)c["text"];
            string mode = (string)c["textFormattingMode"];
            string cultureName = (string)c["culture"];
            string fontKey = (string)c["fontFamily"];
            double fontSize = (double)c["fontSize"];
            double maxWidth = (double)c["maxWidth"];

            CultureInfo culture = CultureInfo.GetCultureInfo(cultureName);
            FontFamily family = families[fontKey];
            var typeface = new Typeface(family, FontStyles.Normal, FontWeights.Normal, FontStretches.Normal);

            var runProps = new OracleRunProperties(typeface, fontSize, culture, 1.0);
            var pprops = new OracleParagraphProperties(
                runProps,
                (FlowDirection)Enum.Parse(typeof(FlowDirection), (string)c["flowDirection"]),
                (TextAlignment)Enum.Parse(typeof(TextAlignment), (string)c["textAlignment"]),
                (TextWrapping)Enum.Parse(typeof(TextWrapping), (string)c["textWrapping"]),
                c["lineHeight"] != null ? (double)c["lineHeight"] : 0.0,
                (bool)c["firstLineInParagraph"],
                (double)c["indent"],
                (double)c["paragraphIndent"],
                (bool)c["alwaysCollapsible"]);

            if (!formatters.TryGetValue(mode, out TextFormatter formatter))
            {
                formatter = TextFormatter.Create(
                    (TextFormattingMode)Enum.Parse(typeof(TextFormattingMode), mode));
                formatters[mode] = formatter;
            }

            int modStart = c["modifierStart"] != null ? (int)c["modifierStart"] : -1;
            int modEnd = c["modifierEnd"] != null ? (int)c["modifierEnd"] : -1;
            TextSource source = modStart >= 0
                ? (TextSource)new OracleTextSourceWithModifier(text, runProps, modStart, modEnd)
                : new OracleTextSource(text, runProps);
            var lines = new JsonArray();
            int index = 0;
            int guard = 0;
            double firstLineWidth = 0;
            bool firstLine = true;

            // 【消费者标准调用序列】——这一点是 U 型踩坑后纠正的：
            // 第一版每行都传 previousLineBreak=null 且不用 TextRunCache，
            // 结果 GetTextLineBreak() 恒为 null、GetTextCollapsedRanges()/GetIndexedGlyphRuns()
            // 直接抛 NullReferenceException。WPF 自己的 TextBlock 是这么调的：
            //   cache = new TextRunCache(); lineBreak = null;
            //   line = formatter.FormatLine(source, index, width, pprops, lineBreak, cache);
            //   lineBreak = line.GetTextLineBreak();
            var cache = new TextRunCache();
            TextLineBreak previousBreak = null;

            int maxLines = c["maxLines"] != null ? (int)c["maxLines"] : 0;
            string trimMode = (string)c["textTrimming"];
            double trimWidth = c["trimWidth"] != null ? (double)c["trimWidth"] : maxWidth;

            while (index < text.Length)
            {
                if (++guard > text.Length + 8)
                    throw new InvalidOperationException($"断行不收敛：index={index} guard={guard}");

                TextLine line = formatter.FormatLine(source, index, maxWidth, pprops, previousBreak, cache);
                if (line == null)
                    throw new InvalidOperationException($"FormatLine 返回 null（index={index}）");

                if (line.Length <= 0)
                    throw new InvalidOperationException($"零长度行（index={index}）—— 会死循环，真值可疑");

                JsonObject dumped = DumpLine(line, text, index, (int)line.Length, runProps);
                dumped["previousLineBreakWasNull"] = previousBreak == null;
                dumped["isFirstLineOfParagraph"] = firstLine;
                lines.Add(dumped);
                if (lines.Count == 1) firstLineWidth = line.Width;

                index += line.Length;
                firstLine = false;

                // maxLines>0：模拟 TextBlock 的 MaxHeight —— 排到第 maxLines 行就停，
                // 并对**最后一行**施加 TextTrimming（这与 WPF TextBlock 的行为一致）。
                if (maxLines > 0 && lines.Count >= maxLines)
                {
                    dumped["trim"] = DoTrim(line, trimMode, trimWidth, text, index - line.Length, runProps);
                    break;
                }
                previousBreak = line.GetTextLineBreak();
            }

            var fontProof = new JsonObject();
            if (typeface.TryGetGlyphTypeface(out GlyphTypeface gtf))
            {
                fontProof["fontUri"] = gtf.FontUri.IsFile ? gtf.FontUri.LocalPath : gtf.FontUri.ToString();
                fontProof["version"] = gtf.Version.ToString();
                fontProof["familyNames"] = new JsonArray(gtf.FamilyNames.Values.Select(v => (JsonNode)v).ToArray());
                fontProof["glyphCount"] = gtf.GlyphCount;
                try
                {
                    if (gtf.FontUri.IsFile && File.Exists(gtf.FontUri.LocalPath))
                        using (var sha = System.Security.Cryptography.SHA256.Create())
                        using (FileStream fs = File.OpenRead(gtf.FontUri.LocalPath))
                            fontProof["fontFileSha256"] =
                                Convert.ToHexString(sha.ComputeHash(fs)).ToLowerInvariant();
                }
                catch (Exception e) { fontProof["fontFileSha256Error"] = e.GetType().Name; }
            }

            return new JsonObject
            {
                ["id"] = id,
                ["group"] = (string)c["group"],
                ["note"] = (string)c["note"],
                ["input"] = new JsonObject
                {
                    ["text"] = text,
                    ["textCodepoints"] = c["textCodepoints"].DeepClone(),
                    ["culture"] = cultureName,
                    ["fontKey"] = fontKey,
                    ["fontFamilySource"] = family.Source,
                    ["fontSize"] = fontSize,
                    ["textFormattingMode"] = mode,
                    ["flowDirection"] = (string)c["flowDirection"],
                    ["maxWidth"] = maxWidth,
                    ["textAlignment"] = (string)c["textAlignment"],
                    ["textTrimming"] = (string)c["textTrimming"],
                    ["textWrapping"] = (string)c["textWrapping"],
                    ["lineHeight"] = c["lineHeight"]?.DeepClone(),
                    ["firstLineInParagraph"] = (bool)c["firstLineInParagraph"],
                    ["indent"] = (double)c["indent"],
                    ["paragraphIndent"] = (double)c["paragraphIndent"],
                    ["alwaysCollapsible"] = (bool)c["alwaysCollapsible"],
                    ["modifierStart"] = c["modifierStart"]?.DeepClone(),
                    ["modifierEnd"] = c["modifierEnd"]?.DeepClone(),
                    // 这两个必须带进结果：自检按 maxLines 区分"修剪提前结束"与"漏排"
                    ["maxLines"] = c["maxLines"]?.DeepClone(),
                    ["trimWidth"] = c["trimWidth"]?.DeepClone(),
                    ["callPattern"] = "FormatLine(source, index, maxWidth, pprops, previousLineBreak, new TextRunCache())；"
                                      + "previousLineBreak 逐行串接（WPF TextBlock 的标准调用序列）",
                },
                ["fontProof"] = fontProof,
                ["lineCount"] = lines.Count,
                ["consumedLength"] = index,
                ["firstLineWidth"] = firstLineWidth,
                ["lines"] = lines,
            };
        }

        // ------------------------------------------------------------------

        /// <summary>
        /// 施加 TextTrimming。语义映射与 WPF TextBlock 一致：
        ///   CharacterEllipsis → TextTrailingCharacterEllipsis(约束宽, runProps)
        ///   WordEllipsis      → TextTrailingWordEllipsis(约束宽, runProps)
        /// 结果给 before/after 两侧，便于 Linux 侧直接对齐。
        /// </summary>
        private static JsonObject DoTrim(TextLine line, string mode, double constraint,
            string text, int lineStart, TextRunProperties runProps)
        {
            var o = new JsonObject
            {
                ["mode"] = mode,
                ["constraintWidth"] = constraint,
                // WPF 框架侧的修剪闸门（Line.cs:109）：HasOverflowed 为假时框架**根本不会**调 Collapse。
                // 这里两个都记：闸门输入 + 实际调用结果，便于 Linux 侧复刻判断顺序。
                ["hasOverflowedBeforeTrim"] = line.HasOverflowed,
                ["lineWidthBeforeTrim"] = line.Width,
                ["constraintNarrowerThanLine"] = constraint < line.Width,
                ["before"] = new JsonObject
                {
                    ["length"] = line.Length,
                    ["width"] = line.Width,
                    ["widthIncludingTrailingWhitespace"] = line.WidthIncludingTrailingWhitespace,
                    ["text"] = SafeSub(text, lineStart, line.Length),
                },
            };
            if (mode == "None") { o["applied"] = false; return o; }

            try
            {
                TextCollapsingProperties cp = mode == "WordEllipsis"
                    ? (TextCollapsingProperties)new TextTrailingWordEllipsis(constraint, runProps)
                    : new TextTrailingCharacterEllipsis(constraint, runProps);

                TextLine collapsed = line.Collapse(new[] { cp });
                o["applied"] = true;
                if (collapsed == null) { o["after"] = null; return o; }

                var after = new JsonObject
                {
                    ["runtimeType"] = collapsed.GetType().FullName,
                    ["length"] = collapsed.Length,
                    ["width"] = collapsed.Width,
                    ["widthIncludingTrailingWhitespace"] = collapsed.WidthIncludingTrailingWhitespace,
                    ["hasCollapsed"] = collapsed.HasCollapsed,
                    ["text"] = SafeSub(text, (int)collapsed.Start, collapsed.Length),
                    ["properties"] = Dumper.Props(collapsed),
                };
                var crArr = new JsonArray();
                IList<TextCollapsedRange> cr = collapsed.GetTextCollapsedRanges();
                after["collapsedRangesIsNull"] = cr == null;
                if (cr != null)
                    foreach (TextCollapsedRange r in cr)
                        crArr.Add(new JsonObject
                        {
                            ["TextSourceCharacterIndex"] = r.TextSourceCharacterIndex,   // 段落系
                            ["Length"] = r.Length,
                            ["Width"] = r.Width,
                            ["textAtParagraphIndex"] = SafeSub(text, r.TextSourceCharacterIndex, r.Length),
                        });
                after["collapsedRanges"] = crArr;
                o["after"] = after;
                collapsed.Dispose();
            }
            catch (Exception e) { o["error"] = e.GetType().Name + ": " + e.Message; }
            return o;
        }

        private static JsonObject DumpLine(TextLine line, string text, int index, int length, TextRunProperties runProps)
        {
            string lineText = SafeSub(text, index, length);
            var o = new JsonObject
            {
                ["lineIndexInText"] = index,
                ["length"] = length,
                ["text"] = lineText,
                ["textCodepoints"] = new JsonArray(lineText.Select(ch => (JsonNode)(int)ch).ToArray()),
                // 【B2 直接模板】行起点累加自证：本行的起点 = 上一行起点 + 上一行 Length。
                // TextLine.Start 恒为 0（不是段落内偏移），所以行区间只能这样累加出来。
                ["startAccumulation"] = new JsonObject
                {
                    ["lineStart"] = index,
                    ["length"] = length,
                    ["nextLineStart"] = index + length,
                    ["sourceSlice"] = lineText,
                    ["sliceMatchesSource"] = SafeSub(text, index, length) == lineText,
                },
                // WPF 内部有两条实现：SimpleTextLine（简单文本快路径）与 FullTextLine。
                // 二者的 GetTextLineBreak/GetTextCollapsedRanges 行为**完全不同**
                //（SimpleTextLine.cs:973/983 直接 return null），所以必须记下每行实际是哪一个。
                ["lineRuntimeType"] = line.GetType().FullName,
                ["properties"] = Dumper.Props(line),      // 全部公开属性
            };

            // ---- TextLineBreak（B2 核心）----
            var lb = new JsonObject();
            try
            {
                TextLineBreak brk = line.GetTextLineBreak();
                lb["isNull"] = brk == null;
                if (brk != null)
                {
                    lb["publicProperties"] = Dumper.Props(brk);
                    lb["publicPropertyCount"] = brk.GetType().GetProperties().Length;
                    lb["toString"] = brk.ToString();
                    try
                    {
                        TextLineBreak clone = brk.Clone();
                        lb["cloneIsSameReference"] = ReferenceEquals(clone, brk);
                        lb["cloneEqualsOriginal"] = clone.Equals(brk);
                        clone.Dispose();
                    }
                    catch (Exception e) { lb["cloneError"] = e.GetType().Name + ": " + e.Message; }
                }
            }
            catch (Exception e) { lb["error"] = e.GetType().Name + ": " + e.Message; }
            o["lineBreak"] = lb;

            // ---- per-run 范围 ----
            try
            {
                // ⚠️ GetTextBounds 的第一个参数是**段落系**（text source）索引，不是行内偏移。
                // 第一版传 0，于是只有"行起点=0"的行拿得到 run 范围，其它行的 inner TextRunBounds 为 null。
                var runs = new JsonArray();
                foreach (object rb in line.GetTextBounds(index, length))
                {
                    var ro = Dumper.Props(rb);
                    if (rb is TextBounds tb)
                    {
                        var inner = new JsonArray();
                        if (tb.TextRunBounds != null)
                        {
                            foreach (TextRunBounds b in tb.TextRunBounds)
                            {
                                inner.Add(new JsonObject
                                {
                                    // 同样是**段落系**索引（与 TextCollapsedRange 一致）
                                    ["TextSourceCharacterIndex"] = b.TextSourceCharacterIndex,
                                    ["Length"] = b.Length,
                                    ["RectangleX"] = b.Rectangle.X,
                                    ["RectangleY"] = b.Rectangle.Y,
                                    ["RectangleWidth"] = b.Rectangle.Width,
                                    ["RectangleHeight"] = b.Rectangle.Height,
                                    ["runText"] = SafeSub(text, b.TextSourceCharacterIndex, b.Length),
                                });
                            }
                        }
                        ro["runs"] = inner;
                    }
                    runs.Add(ro);
                }
                o["textBounds"] = runs;
            }
            catch (Exception e) { o["textBoundsError"] = e.GetType().Name + ": " + e.Message; }

            try
            {
                var spans = new JsonArray();
                foreach (object sp in line.GetTextRunSpans())
                {
                    var so = Dumper.Props(sp);
                    if (sp is TextSpan<TextRun> ts)
                    {
                        // TextSpan<T> 只有 Length/Value（没有 Offset）；run 在源文本里的起点
                        // 由 TextRun.CharacterBufferReference.CharacterBufferOffset 给出。
                        // TextSpan<T> 只有 Length/Value（没有 Offset）；run 的源文本位置不靠猜，
                        // 直接把它 CharacterBufferReference 的公开属性整份 dump 出来
                        // （权威的逐 run 字符区间在 textBounds 里，那里有 TextSourceCharacterIndex）。
                        so["spanLength"] = ts.Length;
                        if (ts.Value != null)
                        {
                            so["runLength"] = ts.Value.Length;
                            so["runCharacterBufferReference"] = Dumper.Props(ts.Value.CharacterBufferReference);
                        }
                    }
                    spans.Add(so);
                }
                o["runSpans"] = spans;
            }
            catch (Exception e) { o["runSpansError"] = e.GetType().Name + ": " + e.Message; }

            // ---- Collapse / 折叠区间（B2）----
            try
            {
                // 注意：这个 API 在**未折叠**的行上返回的是 **null**，不是空集合
                //（FullTextLine.cs:810 `if (_collapsedRange == null) return null;`）。
                // 第一版直接 foreach，把 null 变成 NRE，反而看不出"就是没有折叠"。
                IList<TextCollapsedRange> cr = line.GetTextCollapsedRanges();
                o["collapsedRangesIsNull"] = cr == null;
                var crArr = new JsonArray();
                if (cr != null)
                {
                    foreach (TextCollapsedRange r in cr)
                    {
                        var ro = Dumper.Props(r);
                        // 段落系（实测：行起点=10、index=12、len=8 → 'own fox '，即行内第 2 个字符起）
                        ro["textAtParagraphIndex"] = SafeSub(text, r.TextSourceCharacterIndex, r.Length);
                        crArr.Add(ro);
                    }
                }
                o["collapsedRanges"] = crArr;
            }
            catch (Exception e) { o["collapsedRangesError"] = e.GetType().Name + ": " + e.Message; }

            try
            {
                // 真折叠：公开的 TextTrailingCharacterEllipsis（= TextTrimming.CharacterEllipsis 的实现）。
                // 折叠宽度取"行宽的一半"，保证一定发生折叠（否则拿不到 collapsedRange 真值）。
                double cw = Math.Max(1.0, line.Width * 0.5);
                TextLine ell = line.Collapse(new TextCollapsingProperties[]
                {
                    new TextTrailingCharacterEllipsis(cw, runProps),
                });
                var eo = new JsonObject
                {
                    ["constraintWidth"] = cw,
                    ["isNull"] = ell == null,
                };
                if (ell != null)
                {
                    eo["runtimeType"] = ell.GetType().FullName;
                    eo["length"] = ell.Length;
                    eo["width"] = ell.Width;
                    eo["hasCollapsed"] = ell.HasCollapsed;
                    eo["text"] = SafeSub(text, (int)ell.Start, ell.Length);
                    eo["properties"] = Dumper.Props(ell);
                    IList<TextCollapsedRange> ecr = ell.GetTextCollapsedRanges();
                    eo["collapsedRangesIsNull"] = ecr == null;
                    var ear = new JsonArray();
                    if (ecr != null)
                        foreach (TextCollapsedRange r in ecr)
                        {
                            var ro = Dumper.Props(r);
                            ro["textAtParagraphIndex"] = SafeSub(text, r.TextSourceCharacterIndex, r.Length);
                            ear.Add(ro);
                        }
                    eo["collapsedRanges"] = ear;
                    ell.Dispose();
                }
                o["collapseCharacterEllipsis"] = eo;
            }
            catch (Exception e) { o["collapseCharacterEllipsisError"] = e.GetType().Name + ": " + e.Message; }

            try
            {
                // 公开面只有 Collapse(TextCollapsingProperties[])；Collapse(TextLine) 不存在（见 apiFacts）
                TextLine collapsed = line.Collapse(Array.Empty<TextCollapsingProperties>());
                o["collapseEmptyArgs"] = new JsonObject
                {
                    ["isNull"] = collapsed == null,
                    ["width"] = collapsed?.Width,
                    ["length"] = collapsed?.Length,
                    ["hasCollapsed"] = collapsed?.HasCollapsed,
                    ["text"] = collapsed == null ? null : SafeSub(text, (int)collapsed.Start, collapsed.Length),
                    ["properties"] = collapsed == null ? null : Dumper.Props(collapsed),
                };
                collapsed?.Dispose();
            }
            catch (Exception e) { o["collapseError"] = e.GetType().Name + ": " + e.Message; }

            // ---- caret（B3/B4 先手）----
            try
            {
                var caret = new JsonObject();
                var distances = new[]
                {
                    0.0, line.Width * 0.25, line.Width * 0.5, line.Width * 0.75,
                    Math.Max(0, line.Width - 0.01), line.Width, line.Width + 10,
                };
                var hits = new JsonArray();
                foreach (double d in distances)
                {
                    CharacterHit h = line.GetCharacterHitFromDistance(d);
                    hits.Add(new JsonObject
                    {
                        ["distance"] = d,
                        ["firstCharacterIndex"] = h.FirstCharacterIndex,
                        ["trailingLength"] = h.TrailingLength,
                    });
                }
                caret["fromDistance"] = hits;

                var probeIdx = new List<int> { index, index + 1, index + length / 2, index + Math.Max(0, length - 1), index + length };
                var recs = new JsonArray();
                foreach (int i in probeIdx.Distinct().OrderBy(x => x))
                {
                    var hit = new CharacterHit(i, 0);
                    var rec = new JsonObject
                    {
                        ["characterIndex"] = i,
                        ["distance"] = line.GetDistanceFromCharacterHit(hit),
                    };
                    try { rec["backspace"] = Dumper.Props(line.GetBackspaceCaretCharacterHit(hit)); }
                    catch (Exception e) { rec["backspace"] = "THROW:" + e.GetType().Name; }
                    try { rec["next"] = Dumper.Props(line.GetNextCaretCharacterHit(hit)); }
                    catch (Exception e) { rec["next"] = "THROW:" + e.GetType().Name; }
                    try { rec["prev"] = Dumper.Props(line.GetPreviousCaretCharacterHit(hit)); }
                    catch (Exception e) { rec["prev"] = "THROW:" + e.GetType().Name; }
                    recs.Add(rec);
                }
                caret["fromCharacterHit"] = recs;
                o["caret"] = caret;
            }
            catch (Exception e) { o["caretError"] = e.GetType().Name + ": " + e.Message; }

            // ---- 字形 run（只记条数 + 首个）----
            try
            {
                IEnumerable<IndexedGlyphRun> runs = line.GetIndexedGlyphRuns();
                o["indexedGlyphRunsIsNull"] = runs == null;
                var list = new List<object>();
                if (runs != null)
                    foreach (object g in runs) { list.Add(g); if (list.Count >= 8) break; }
                o["indexedGlyphRunCount"] = list.Count;
                if (list.Count > 0) o["indexedGlyphRunFirst"] = Dumper.Props(list[0]);
            }
            catch (Exception e) { o["indexedGlyphRunError"] = e.GetType().Name + ": " + e.Message; }

            return o;
        }

        private static string SafeSub(string s, int start, int len)
        {
            if (s == null) return null;
            if (start < 0) start = 0;
            if (start > s.Length) return "";
            int n = Math.Min(len, s.Length - start);
            return s.Substring(start, Math.Max(0, n));
        }

        // ------------------------------------------------------------------

        private static JsonObject Env()
        {
            return new JsonObject
            {
                ["machine"] = System.Environment.MachineName,
                ["os"] = System.Runtime.InteropServices.RuntimeInformation.OSDescription,
                ["dotnet"] = System.Environment.Version.ToString(),
                ["processArch"] = System.Runtime.InteropServices.RuntimeInformation.ProcessArchitecture.ToString(),
                ["currentCulture"] = CultureInfo.CurrentCulture.Name,
                ["presentationCore"] = typeof(TextFormatter).Assembly.GetName().Version?.ToString(),
                ["presentationCorePath"] = typeof(TextFormatter).Assembly.Location,
            };
        }

        /// <summary>把"这一批结果的形状"变成可断言的数字，防假绿。</summary>
        private static JsonObject SelfCheck(JsonArray results)
        {
            int cases = 0, lines = 0, zeroWidthVisible = 0, zeroWidthBlank = 0;
            int notConsumed = 0, emptyText = 0, casesWithNoLines = 0;
            int fileFontCases = 0, fileFontMismatch = 0, trimmedCases = 0;
            var consumedDelta = new Dictionary<int, int>();

            foreach (JsonNode rn in results)
            {
                JsonObject r = rn.AsObject();
                cases++;
                string text = (string)r["input"]["text"];
                if (string.IsNullOrEmpty(text)) emptyText++;

                int consumed = (int)r["consumedLength"];
                int maxLines = r["input"]["maxLines"] != null ? (int)r["input"]["maxLines"] : 0;
                if (maxLines > 0)
                {
                    // 修剪场景：排到 maxLines 行就停，剩余文本不排版
                    if (consumed > text.Length + 1) notConsumed++;
                    trimmedCases++;
                    continue;
                }
                int delta = consumed - text.Length;
                consumedDelta[delta] = consumedDelta.TryGetValue(delta, out int cc) ? cc + 1 : 1;
                // 末行 Length 通常把 TextEndOfParagraph 的 1 个位置算进去，故允许 0 或 +1
                if (delta < 0 || delta > 1) notConsumed++;

                int n = 0;
                foreach (JsonNode ln in r["lines"].AsArray())
                {
                    n++; lines++;
                    double w = (double)ln["properties"]["Width"];
                    string lt = (string)ln["text"] ?? "";
                    bool blank = lt.Trim().Length == 0;
                    if (w <= 0)
                    {
                        // 空行/纯空白行 Width=0 是**合法真值**（"\n\n\n" 就会造出空行）；
                        // 只有"有可见字符却零宽"才算异常。
                        if (blank) zeroWidthBlank++; else zeroWidthVisible++;
                    }
                }
                if (n == 0) casesWithNoLines++;

                if ((string)r["input"]["fontKey"] == "file")
                {
                    fileFontCases++;
                    string uri = (string)r["fontProof"]["fontUri"];
                    if (uri == null
                        || !uri.EndsWith("NotoSans-Regular.ttf", StringComparison.OrdinalIgnoreCase)
                        || !uri.Contains("wpf-oracle-layout", StringComparison.OrdinalIgnoreCase))
                        fileFontMismatch++;
                }
            }

            var deltaObj = new JsonObject();
            foreach (var kv in consumedDelta.OrderBy(k => k.Key)) deltaObj[kv.Key.ToString()] = kv.Value;

            bool ok = cases > 0 && lines > 0 && emptyText == 0 && notConsumed == 0
                      && zeroWidthVisible == 0 && casesWithNoLines == 0
                      && fileFontMismatch == 0 && fileFontCases > 0;

            return new JsonObject
            {
                ["ok"] = ok,
                ["cases"] = cases,
                ["lines"] = lines,
                ["zeroWidthVisibleLines"] = zeroWidthVisible,
                ["zeroWidthBlankLines"] = zeroWidthBlank,
                ["casesWithNoLines"] = casesWithNoLines,
                ["casesNotFullyConsumed"] = notConsumed,
                ["trimmedCases"] = trimmedCases,
                ["consumedMinusTextLengthHistogram"] = deltaObj,
                ["emptyTextCases"] = emptyText,
                ["fileFontCases"] = fileFontCases,
                ["fileFontMismatch"] = fileFontMismatch,
                ["rule"] = "行数>0、**非空白行** Width>0、消费长度∈[文本长度, 文本长度+1]、" +
                           "文件式字体必须解析到 C:\\wpf-oracle-layout\\fonts\\NotoSans-Regular.ttf；" +
                           "否则只写 .debug.json，不写正式结果文件",
            };
        }

        /// <summary>API 面的**负结论**也入库（"该重载不存在"本身就是数据）。</summary>
        private static JsonObject ApiFacts()
        {
            var collapseOverloads = new JsonArray(
                typeof(TextLine).GetMethods()
                    .Where(m => m.Name == "Collapse")
                    .Select(m => (JsonNode)m.ToString()).ToArray());

            return new JsonObject
            {
                ["TextLine_Collapse_overloads"] = collapseOverloads,
                ["TextLine_Collapse_TextLine_exists"] = typeof(TextLine).GetMethods().Any(m =>
                    m.Name == "Collapse" && m.GetParameters().Length == 1 &&
                    m.GetParameters()[0].ParameterType == typeof(TextLine)),
                ["TextLine_GetTextRunBounds_exists"] =
                    typeof(TextLine).GetMethods().Any(m => m.Name == "GetTextRunBounds"),
                ["TextLine_GetTextBounds_exists"] =
                    typeof(TextLine).GetMethods().Any(m => m.Name == "GetTextBounds"),
                ["TextLine_GetTextCollapsedRanges_exists"] =
                    typeof(TextLine).GetMethods().Any(m => m.Name == "GetTextCollapsedRanges"),
                ["TextLine_GetInsertionCaretCharacterHit_exists"] =
                    typeof(TextLine).GetMethods().Any(m => m.Name == "GetInsertionCaretCharacterHit"),
                ["TextLineBreak_publicPropertyCount"] = typeof(TextLineBreak).GetProperties().Length,
                ["TextLine_publicPropertyCount"] = typeof(TextLine).GetProperties().Length,
                ["TextParagraphProperties_LineStackingStrategy_exists"] =
                    typeof(TextParagraphProperties).GetProperties().Any(p => p.Name == "LineStackingStrategy"),
                ["TextParagraphProperties_LineStacking_members"] = new JsonArray(
                    typeof(TextParagraphProperties)
                        .GetMembers(System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance
                                    | System.Reflection.BindingFlags.Public)
                        .Where(m => m.Name.IndexOf("LineStacking", StringComparison.OrdinalIgnoreCase) >= 0)
                        .Select(m => (JsonNode)(m.MemberType + " " + m.Name)).ToArray()),
            };
        }
    }
}

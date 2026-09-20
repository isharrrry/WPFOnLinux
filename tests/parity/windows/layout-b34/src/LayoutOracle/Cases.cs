// B2/B3/B4 oracle · 用例集生成（`LayoutOracle gencases <out.json>`）
//
// 用例定义**写在这里**而不是手搓 JSON：跑例子的程序和造例子的程序是同一个，
// 不可能出现"cases.json 与 runner 理解不一致"。
//
// 宽度扫描 21 档：20 个有限宽度 + 一个"极宽"（自然单行宽度，用于拿原始度量）。
// 文本样本见 Texts：拉丁连字 / CJK 无空格 / CJK 禁则标点 / 中英混排 / 硬断(LF,CRLF,LS)
// / 连续空行 / 超长不可断词 / 前导尾随空格 / Tab / NBSP / ZWSP / 阿拉伯+希伯来。

using System;
using System.Collections.Generic;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace WpfOracleLayout
{
    internal sealed class CaseSpec
    {
        public string Id;
        public string Group;            // A / B / C / D
        public string Note;
        public string Text;
        public string FontFamily;       // "file" 或系统字族名
        public double FontSize = 16;
        public string Culture = "en-US";
        public string Mode = "Ideal";   // Ideal | Display
        public string Flow = "LeftToRight";
        public double MaxWidth = 1e6;
        public string Alignment = "Left";
        public string Trimming = "None";
        public double LineHeight = double.NaN;   // NaN = 不设置
        public string Wrapping = "Wrap";
        public bool FirstLineInParagraph = true;
        public double Indent = 0;
        public double ParagraphIndent = 0;
        public bool AlwaysCollapsible = false;
        public int ModifierStart = -1;   // >=0 时用带 TextModifier 的源
        public int ModifierEnd = -1;
        public int MaxLines = 0;         // >0 = 只排这么多行（模拟 TextBlock 的 MaxHeight），最后一行做修剪
        public double TrimWidth = double.NaN;   // NaN = 用 maxWidth 作修剪约束宽

        public JsonObject ToJson()
        {
            var o = new JsonObject
            {
                ["id"] = Id,
                ["group"] = Group,
                ["note"] = Note,
                ["text"] = Text,
                ["textCodepoints"] = new JsonArray(
                    System.Linq.Enumerable.ToArray(
                        System.Linq.Enumerable.Select(Text, ch => (JsonNode)(int)ch))),
                ["textLengthUtf16"] = Text.Length,
                ["fontFamily"] = FontFamily,
                ["fontSize"] = FontSize,
                ["culture"] = Culture,
                ["textFormattingMode"] = Mode,
                ["flowDirection"] = Flow,
                ["maxWidth"] = MaxWidth,
                ["textAlignment"] = Alignment,
                ["textTrimming"] = Trimming,
                ["textWrapping"] = Wrapping,
                ["firstLineInParagraph"] = FirstLineInParagraph,
                ["indent"] = Indent,
                ["paragraphIndent"] = ParagraphIndent,
                ["alwaysCollapsible"] = AlwaysCollapsible,
            };
            if (!double.IsNaN(LineHeight)) o["lineHeight"] = LineHeight;
            if (ModifierStart >= 0) { o["modifierStart"] = ModifierStart; o["modifierEnd"] = ModifierEnd; }
            o["maxLines"] = MaxLines;
            if (!double.IsNaN(TrimWidth)) o["trimWidth"] = TrimWidth;
            return o;
        }
    }

    internal static class Cases
    {
        // 21 档宽度（DIP）。20 档有限 + 一档"极宽"。
        private static readonly double[] Widths =
        {
            20, 30, 40, 50, 60, 70, 80, 100, 120, 150,
            180, 200, 240, 280, 320, 400, 480, 560, 700, 900,
            1e6,
        };

        internal static readonly (string Id, string Font, string Text, string Note)[] Texts =
        {
            ("lat_words", "file",
                "The quick brown fox jumps over the lazy dog and the waffle office ffl flourish.",
                "纯拉丁多词，含 ffl/ffi 连字候选"),
            ("cjk_nospace", "zh",
                "中文没有空格需要按字断行标点符号的行首禁则与行尾禁则都要对上",
                "CJK 无空格，禁则"),
            ("cjk_punct", "zh",
                "他说：「今天很好。」（真的吗？）『引号』“双引号”【方括号】——破折号……还有省略号。",
                "CJK 标点：pull-2 收尾引号/括号、避头尾"),
            ("cjk_small_kana", "ja",
                "ァィゥェォッャュョ と きょうは いい てんき です。",
                "日文小假名（行首禁则）"),
            ("mixed", "zh",
                "混合 mixed 中英 text with ASCII words 和标点，测试断点位置。",
                "中英混排"),
            ("hard_lf", "file", "first line\nsecond line\nthird", "LF 硬断"),
            ("hard_crlf", "file", "first line\r\nsecond line\r\nthird", "CRLF 硬断"),
            ("hard_ls", "file", "first line\u2028second line\u2029third", "U+2028/U+2029 硬断"),
            ("blank_lines", "file", "para one\n\n\npara three", "连续空行（3 个 LF = 2 个空行）"),
            ("long_word", "file", "short Supercalifragilisticexpialidocious1234567890 tail",
                "超长不可断词（紧急断行）"),
            ("spaces", "file", "  leading and   inner    and trailing    ",
                "前导/尾随/连续空格"),
            ("tabs", "file", "a\tb\t\tc\td", "Tab"),
            ("nbsp_zwsp", "file", "no\u00A0break\u00A0nbsp 与 zero\u200Bwidth\u200Bspace",
                "NBSP（禁断）与 ZWSP（可断）"),
            ("bidi_mix", "file",
                "hello \u05E9\u05DC\u05D5\u05DD world \u0645\u0631\u062D\u0628\u0627 end",
                "拉丁+希伯来+阿拉伯（bidi 先手）"),
            // C/D 第二批：RTL/bidi 专用样本（用 Segoe UI，见 fontKey=bidi）
            ("he_only", "bidi", "\u05E9\u05DC\u05D5\u05DD \u05E2\u05D5\u05DC\u05DD \u05D6\u05D4 \u05D8\u05E7\u05E1\u05D8 \u05E2\u05D1\u05E8\u05D9",
                "纯希伯来文"),
            ("ar_only", "bidi", "\u0645\u0631\u062D\u0628\u0627 \u0628\u0627\u0644\u0639\u0627\u0644\u0645 \u0647\u0630\u0627 \u0646\u0635 \u0639\u0631\u0628\u064A",
                "纯阿拉伯文"),
            ("he_lat_digits", "bidi", "abc 123 \u05E9\u05DC\u05D5\u05DD xyz 456 \u05E2\u05D5\u05DC\u05DD",
                "拉丁+数字+希伯来（数字运行方向）"),
            ("ar_parens", "bidi", "\u0645\u0631\u062D\u0628\u0627 (\u0627\u062E\u062A\u0628\u0627\u0631) [\u0642\u0648\u0633] 123 \u00AB\u0627\u0642\u062A\u0628\u0627\u0633\u00BB",
                "阿拉伯 + 括号/引号镜像 + 数字"),
            ("mixed_3way", "bidi", "hello \u05E9\u05DC\u05D5\u05DD \u0645\u0631\u062D\u0628\u0627 123 world",
                "拉丁+希伯来+阿拉伯+数字三方混排"),
        };

        public static int WriteCases(string outPath, string groupFilter = null)
        {
            var cases = new List<CaseSpec>();
            var root = new JsonObject
            {
                ["schema"] = "wpf-textlayout-oracle-cases/1",
                ["description"] =
                    "TextFormatter/TextLine 逐行真值。走公开 API System.Windows.Media.TextFormatting：" +
                    "TextFormatter.Create(mode).FormatLine(...)，逐行 dump TextLine 的**全部公开属性** + " +
                    "TextLineBreak + GetTextBounds/GetTextRunSpans/GetTextCollapsedRanges + caret API。",
                ["fonts"] = new JsonObject
                {
                    ["file"] = "C:\\wpf-oracle-layout\\fonts\\NotoSans-Regular.ttf（= 仓库 build/fonts/，sha256 见 PROVENANCE）",
                    ["zh"] = "Microsoft YaHei（系统字族，只引用不安装；文件 C:\\WINDOWS\\FONTS\\MSYH.TTC）",
                    ["ja"] = "Yu Gothic / MS Gothic（系统字族，只引用不安装）",
                },
                ["notes"] = new JsonArray(
                    "maxWidth 单位是 DIP；1e6 表示\"极宽\"档（取自然单行宽度）。",
                    "所有字符串都带 textCodepoints，方便 Linux 侧按码点复算。"),
            };

            var arr = new JsonArray();

            // ---- A1：全文本 × 全宽度 × en-US × Ideal ----
            foreach ((string tid, string font, string text, string note) in Texts)
            {
                foreach (double w in Widths)
                {
                    var c = new CaseSpec
                    {
                        Id = $"A1_{tid}_w{Ws(w)}",
                        Group = "A",
                        Note = note,
                        Text = text,
                        FontFamily = font,
                        MaxWidth = w,
                    };
                    cases.Add(c);
                }
            }

            // ---- A2：culture / formattingMode 矩阵（子集）----
            string[] matrixTexts = { "lat_words", "cjk_nospace", "cjk_punct", "mixed", "long_word" };
            double[] matrixWidths = { 40, 80, 120, 200, 320, 560 };
            foreach (string tid in matrixTexts)
            {
                (string Id, string Font, string Text, string Note) t =
                    Array.Find(Texts, x => x.Id == tid);
                foreach (string culture in new[] { "zh-CN", "ja-JP" })
                foreach (double w in matrixWidths)
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"A2_{tid}_{culture}_w{Ws(w)}",
                        Group = "A",
                        Note = t.Note + $"（culture={culture}）",
                        Text = t.Text,
                        FontFamily = t.Font,
                        Culture = culture,
                        MaxWidth = w,
                    });
                }
            }

            // ---- A3：Display 模式（子集）----
            foreach (string tid in matrixTexts)
            {
                (string Id, string Font, string Text, string Note) t =
                    Array.Find(Texts, x => x.Id == tid);
                foreach (double w in Widths)
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"A3_{tid}_display_w{Ws(w)}",
                        Group = "A",
                        Note = t.Note + "（TextFormattingMode=Display）",
                        Text = t.Text,
                        FontFamily = t.Font,
                        Mode = "Display",
                        MaxWidth = w,
                    });
                }
            }

            // ---- B：空白与折叠专项（宽度给几档，重点看 collapsed / trailingWhitespace）----
            string[] bTexts = { "spaces", "tabs", "nbsp_zwsp", "hard_lf", "blank_lines", "cjk_punct" };
            double[] bWidths = { 60, 120, 240, 1e6 };
            foreach (string tid in bTexts)
            {
                (string Id, string Font, string Text, string Note) t =
                    Array.Find(Texts, x => x.Id == tid);
                foreach (double w in bWidths)
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"B_{tid}_w{Ws(w)}",
                        Group = "B",
                        Note = "空白/折叠：" + t.Note,
                        Text = t.Text,
                        FontFamily = t.Font,
                        MaxWidth = w,
                    });
                }
                // 折叠与 trim 的交互：同一文本再加一档"窄 + 字符省略"
                cases.Add(new CaseSpec
                {
                    Id = $"B_{tid}_trim",
                    Group = "B",
                    Note = "空白/折叠 + CharacterEllipsis：" + t.Note,
                    Text = t.Text,
                    FontFamily = t.Font,
                    MaxWidth = 120,
                    Trimming = "CharacterEllipsis",
                });
            }

            // ---- F：完整路径（AlwaysCollapsible=true）----
            // WPF 在 TextFormatterImp.cs:224 按 `!AlwaysCollapsible && previousLineBreak==null && lineLength<=0`
            // 决定走 SimpleTextLine（快路径），而 SimpleTextLine 的 GetTextLineBreak/
            // GetTextCollapsedRanges **恒为 null**（SimpleTextLine.cs:973/983）。
            // 把 AlwaysCollapsible 置 true 即强制走 FullTextLine —— 那才是 B2 要的真值。
            double[] fullWidths = { 40, 80, 120, 200, 320, 560, 900, 1e6 };
            foreach ((string tid, string font, string text, string note) in Texts)
            {
                foreach (double w in fullWidths)
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"F_{tid}_w{Ws(w)}",
                        Group = "F",
                        Note = "完整路径(AlwaysCollapsible=true)：" + note,
                        Text = text,
                        FontFamily = font,
                        MaxWidth = w,
                        AlwaysCollapsible = true,
                    });
                }
            }
            foreach (string culture in new[] { "zh-CN", "ja-JP" })
            {
                foreach (string tid in new[] { "cjk_nospace", "cjk_punct", "cjk_small_kana", "mixed" })
                {
                    (string Id, string Font, string Text, string Note) t = Array.Find(Texts, x => x.Id == tid);
                    cases.Add(new CaseSpec
                    {
                        Id = $"F_{tid}_{culture}_w200",
                        Group = "F",
                        Note = $"完整路径 + culture={culture}：" + t.Note,
                        Text = t.Text,
                        FontFamily = t.Font,
                        Culture = culture,
                        MaxWidth = 200,
                        AlwaysCollapsible = true,
                    });
                }
            }

            // ---- M：TextModifier 跨越断行 → 实测 TextLineBreak 的非 null 分支 ----
            // 文本固定用拉丁词串，modifier 覆盖中间一段（跨越换行点）。
            string modText = "alpha bravo charlie delta echo foxtrot golf hotel india juliet";
            foreach (double w in new double[] { 80, 120, 200, 320, 1e6 })
            {
                cases.Add(new CaseSpec
                {
                    Id = $"M_modifier_w{Ws(w)}",
                    Group = "M",
                    Note = "TextModifier 覆盖 [6,45)，跨越换行点：验证 TextLineBreak 何时非 null",
                    Text = modText,
                    FontFamily = "file",
                    MaxWidth = w,
                    AlwaysCollapsible = true,
                    ModifierStart = 6,
                    ModifierEnd = 45,
                });
            }

            // ================= C/D 第一批：T（修剪）+ L（行起点自证）+ P（AlwaysCollapsible 对照）=====

            // ---- T：TextTrimming 三档 ----
            // 【关键机制】WPF 框架侧的修剪判据是 `_line.HasOverflowed && TextTrimming != None`
            //（PresentationFramework/MS/Internal/Text/Line.cs:109/161/197/455）。
            // 而 **Wrap 模式下永远不 overflow**（实测 614 例 3400+ 行里 HasOverflowed 全为 false）
            // ⇒ 要触发真修剪必须用 NoWrap / WrapWithOverflow，或让约束宽 < 行宽。
            // 本组三种触发路径都给：
            //   T1 NoWrap         —— 单行溢出（TextBlock 单行省略号的真实场景）
            //   T2 WrapWithOverflow —— 长不可断词导致的溢出
            //   T3 Wrap + 约束宽 < 段落宽（框架为高度裁剪的末行做的那种）
            string[] tTexts = { "lat_words", "cjk_nospace", "cjk_punct", "mixed", "long_word", "spaces" };
            string[] tModes = { "None", "CharacterEllipsis", "WordEllipsis" };

            foreach (string tid in tTexts)
            {
                (string Id, string Font, string Text, string Note) t = Array.Find(Texts, x => x.Id == tid);
                foreach (string mode in tModes)
                foreach (double w in new[] { 60, 120, 200 })
                {
                    // T1：NoWrap → 单行 + 溢出
                    cases.Add(new CaseSpec
                    {
                        Id = $"T1_{tid}_{mode}_nowrap_w{Ws(w)}",
                        Group = "T",
                        Note = $"NoWrap 单行溢出 + TextTrimming={mode}：" + t.Note,
                        Text = t.Text, FontFamily = t.Font, MaxWidth = w,
                        Wrapping = "NoWrap", Trimming = mode, MaxLines = 1,
                    });
                    // T2：WrapWithOverflow → 长词溢出
                    cases.Add(new CaseSpec
                    {
                        Id = $"T2_{tid}_{mode}_wo_w{Ws(w)}",
                        Group = "T",
                        Note = $"WrapWithOverflow + TextTrimming={mode}：" + t.Note,
                        Text = t.Text, FontFamily = t.Font, MaxWidth = w,
                        Wrapping = "WrapWithOverflow", Trimming = mode, MaxLines = 1,
                    });
                }
                // T3：Wrap（行本身不溢出）+ 约束宽只有段落宽的一半 → 拟合框架对高度裁剪末行的做法
                foreach (string mode in new[] { "CharacterEllipsis", "WordEllipsis" })
                foreach (double w in new[] { 200, 320 })
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"T3_{tid}_{mode}_narrow_w{Ws(w)}",
                        Group = "T",
                        Note = $"Wrap 段落宽 {w} 但修剪约束只有 {w / 2}（行不溢出，靠窄约束触发）：" + t.Note,
                        Text = t.Text, FontFamily = t.Font, MaxWidth = w,
                        Wrapping = "Wrap", Trimming = mode, MaxLines = 1, TrimWidth = w / 2,
                    });
                }
                // T4：多行（maxLines=3）—— 末行不溢出，用来证明"overflow 是闸门"
                foreach (string mode in new[] { "CharacterEllipsis", "WordEllipsis" })
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"T4_{tid}_{mode}_multi",
                        Group = "T",
                        Note = $"Wrap + maxLines=3 + TextTrimming={mode}（末行不溢出，预期不折叠）：" + t.Note,
                        Text = t.Text, FontFamily = t.Font, MaxWidth = 200,
                        Wrapping = "Wrap", Trimming = mode, MaxLines = 3,
                    });
                }
            }

            // ---- L：行起点累加自证（B2 实现行区间的直接模板）----
            // 每行都会 dump startAccumulation 块（见 Runner），这里挑"硬断 + 空行 + 多行"的组合。
            var lTexts = new (string Id, string Font, string Text, string Note)[]
            {
                ("hard_lf", "file", "first line\nsecond line\nthird", "LF 硬断三行"),
                ("blank_lines", "file", "para one\n\n\npara three", "含两个空行"),
                ("lat_words", "file", "The quick brown fox jumps over the lazy dog", "软换行多行"),
                ("cjk_punct", "zh", "他说：「今天很好。」（真的吗？）『引号』", "CJK 多行"),
                ("mixed_lf", "file", "head\n\n中英 mixed tail with words 结束", "硬断+空行+中英混排"),
            };
            foreach ((string tid, string font, string text, string note) in lTexts)
            foreach (double w in new[] { 100, 200 })
            {
                cases.Add(new CaseSpec
                {
                    Id = $"L_{tid}_w{Ws(w)}",
                    Group = "L",
                    Note = "行起点累加自证：" + note,
                    Text = text,
                    FontFamily = font,
                    MaxWidth = w,
                });
            }

            // ---- P：AlwaysCollapsible 开/关对照（同一文本、同一宽度）----
            // 用来钉死 TextFormatterImp.cs:224 的实现选择规则，以及 SimpleTextLine 的
            // GetTextLineBreak/GetTextCollapsedRanges 恒 null 这件事。
            foreach (string tid in new[] { "lat_words", "cjk_nospace", "hard_lf", "blank_lines", "spaces" })
            {
                (string Id, string Font, string Text, string Note) t = Array.Find(Texts, x => x.Id == tid);
                foreach (double w in new[] { 60, 120, 200 })
                foreach (bool ac in new[] { false, true })
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"P_{tid}_{(ac ? "ac1" : "ac0")}_w{Ws(w)}",
                        Group = "P",
                        Note = $"AlwaysCollapsible={(ac ? "true" : "false")}：" + t.Note,
                        Text = t.Text,
                        FontFamily = t.Font,
                        MaxWidth = w,
                        AlwaysCollapsible = ac,
                    });
                }
            }

            // 可选分组过滤：C/D 的并列文件只装新组，避免把 614 例老数据重复采一遍
            if (!string.IsNullOrEmpty(groupFilter))
            {
                var want = new HashSet<string>(groupFilter.Split(','), StringComparer.Ordinal);
                cases = cases.FindAll(x => want.Contains(x.Group));
            }

            // ================= C/D 第二批：AL（对齐）+ BD（bidi）+ LH（行高）=================

            // ---- AL：TextAlignment 四档（含 Justify × CJK 专项）----
            // Justify 只在 TextWrapping=Wrap 且非末行时才拉伸，所以整组固定 Wrap。
            string[] alTexts = { "lat_words", "cjk_punct", "cjk_nospace", "mixed" };
            string[] alAligns = { "Left", "Right", "Center", "Justify" };
            foreach (string tid in alTexts)
            {
                (string Id, string Font, string Text, string Note) t = Array.Find(Texts, x => x.Id == tid);
                bool isCjk = tid.StartsWith("cjk");
                foreach (string al in alAligns)
                foreach (double w in new double[] { 120, 200, 320, 600 })
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"AL_{tid}_{al}_w{Ws(w)}",
                        Group = "AL",
                        Note = (isCjk && al == "Justify" ? "★Justify×CJK：全角文本两端对齐；" : "") +
                               $"TextAlignment={al}：" + t.Note,
                        Text = t.Text, FontFamily = t.Font, MaxWidth = w,
                        Wrapping = "Wrap", Alignment = al,
                    });
                }
            }

            // ---- BD：RTL / bidi 混排 ----
            foreach (string tid in new[] { "he_only", "ar_only", "he_lat_digits", "ar_parens", "mixed_3way" })
            {
                (string Id, string Font, string Text, string Note) t = Array.Find(Texts, x => x.Id == tid);
                foreach (string flow in new[] { "LeftToRight", "RightToLeft" })
                foreach (double w in new double[] { 120, 240, 400 })
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"BD_{tid}_{(flow == "RightToLeft" ? "rtl" : "ltr")}_w{Ws(w)}",
                        Group = "BD",
                        Note = $"FlowDirection={flow}：" + t.Note,
                        Text = t.Text, FontFamily = "bidi", MaxWidth = w,
                        Wrapping = "Wrap", Flow = flow,
                    });
                }
            }

            // ---- LH：LineHeight 影响（LineStackingStrategy 无公开面，只能覆盖 LineHeight）----
            foreach (string tid in new[] { "lat_words", "cjk_punct" })
            {
                (string Id, string Font, string Text, string Note) t = Array.Find(Texts, x => x.Id == tid);
                foreach (double lh in new[] { double.NaN, 10, 21.793, 30, 50 })
                {
                    cases.Add(new CaseSpec
                    {
                        Id = $"LH_{tid}_lh{(double.IsNaN(lh) ? "unset" : ((int)Math.Round(lh)).ToString())}",
                        Group = "LH",
                        Note = (double.IsNaN(lh) ? "LineHeight 未设置（自然行高）" : $"LineHeight={lh}") + "：" + t.Note,
                        Text = t.Text, FontFamily = t.Font, MaxWidth = 200,
                        Wrapping = "Wrap", LineHeight = lh,
                    });
                }
                // 与 AlwaysCollapsible 的交叉一格（验证行高不受实现选择影响）
                cases.Add(new CaseSpec
                {
                    Id = $"LH_{tid}_lh30_ac1",
                    Group = "LH",
                    Note = "LineHeight=30 + AlwaysCollapsible=true：" + t.Note,
                    Text = t.Text, FontFamily = t.Font, MaxWidth = 200,
                    Wrapping = "Wrap", LineHeight = 30, AlwaysCollapsible = true,
                });
            }

            foreach (CaseSpec c in cases) arr.Add(c.ToJson());

            root["cases"] = arr;
            root["caseCount"] = cases.Count;
            System.IO.File.WriteAllText(outPath, root.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
            Console.WriteLine($"wrote {outPath}: {cases.Count} cases");

            // 分布小结，便于人眼核对
            var byGroup = new Dictionary<string, int>(StringComparer.Ordinal);
            foreach (CaseSpec c in cases)
                byGroup[c.Group] = byGroup.TryGetValue(c.Group, out int n) ? n + 1 : 1;
            foreach (var kv in byGroup) Console.WriteLine($"  group {kv.Key}: {kv.Value}");
            return 0;
        }

        /// <summary>宽度 → id 片段（1e6 记作 "inf"）。</summary>
        private static string Ws(double w) => w >= 1e5 ? "inf" : ((int)w).ToString();
    }
}

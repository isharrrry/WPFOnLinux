using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace ModifierScopeOracle
{
    /// <summary>One paragraph under test. The buffer may contain two synthetic marker characters.</summary>
    internal sealed class Doc
    {
        public string Group, Id, Note, Buffer;
        public int OpenIndex = -1;      // buffer index where the source returns a TextModifier run (length 1)
        public int CloseIndex = -1;     // buffer index where the source returns TextEndOfSegment(1)
        public bool ModifierVisible;    // ModifyProperties really changes the em size (positive control)

        public Doc(string group, string id, string note, string buffer)
        { Group = group; Id = id; Note = note; Buffer = buffer; }

        public Doc WithMarkers(int open, int close) { OpenIndex = open; CloseIndex = close; return this; }

        public string VisibleText
        {
            get
            {
                var sb = new StringBuilder();
                foreach (char c in Buffer) if (c != TextModel.OpenMarker && c != TextModel.CloseMarker) sb.Append(c);
                return sb.ToString();
            }
        }
    }

    internal sealed class IndentArm
    {
        public string Id; public double Indent; public double ParagraphIndent; public bool FirstLine; public string Note;
        public IndentArm(string id, double indent, double paraIndent, bool firstLine, string note)
        { Id = id; Indent = indent; ParagraphIndent = paraIndent; FirstLine = firstLine; Note = note; }
    }

    internal static class TextModel
    {
        public const char OpenMarker = '\uE000';
        public const char CloseMarker = '\uE001';
    }

    public static class Program
    {
        internal const double EmSize = 24.0;
        private const double Dpi = 96.0;

        private static readonly string[] FontCandidates = { "Arial", "Segoe UI", "Tahoma", "Times New Roman" };

        internal static readonly IndentArm I0 = new IndentArm("i0", 0, 0, true, "Indent=0, ParagraphIndent=0");
        internal static readonly IndentArm I24 = new IndentArm("i24", 24, 0, true, "Indent=24");
        internal static readonly IndentArm I24P24 = new IndentArm("i24p24", 24, 24, true, "Indent=24, ParagraphIndent=24");
        internal static readonly IndentArm I24P48 = new IndentArm("i24p48", 24, 48, true, "Indent=24, ParagraphIndent=48");

        private const string LONG_LOWER = "abcdefghijklmnopqrstuvwxyz";

        private static Doc[] BuildScopeDocs()
        {
            char O = TextModel.OpenMarker, C = TextModel.CloseMarker;
            var list = new List<Doc>();
            // A: the scope opens at index 0 and CLOSES after 3 letters, so it ends inside line 0
            list.Add(new Doc("A-scope-line0", "scope-line0",
                "modifier scope opens at index 0 and CLOSES after 3 letters, so it ends inside line 0; the later " +
                "lines consist of characters that do NOT intersect the scope",
                "" + O + "abc" + C + "defghijklmnopqrstuvwxyz0123").WithMarkers(0, 4));
            // A-RTL: the same shape with an RTL paragraph and pure Hebrew content
            list.Add(new Doc("A-rtl-scope-line0", "rtl-scope-line0",
                "same shape as scope-line0, but FlowDirection=RightToLeft and pure Hebrew content",
                "" + O + "\u05D0\u05D1\u05D2" + C + "\u05D3\u05D4\u05D5\u05D6\u05D7\u05D8\u05D9\u05DB\u05DC\u05DE\u05E0\u05E1\u05E2\u05E4\u05E6").WithMarkers(0, 4));
            // B: the scope opens near the end, so only the last line intersects it
            list.Add(new Doc("B-scope-lastline", "scope-lastline",
                "modifier scope opens near the END: only the LAST line intersects it",
                LONG_LOWER + "0123" + O + "abc" + C).WithMarkers(LONG_LOWER.Length + 4, LONG_LOWER.Length + 8));
            // C: the scope is never closed, so it covers the whole paragraph
            list.Add(new Doc("C-scope-whole", "scope-whole",
                "modifier scope opens at index 0 and is never closed: it covers the whole paragraph",
                "" + O + LONG_LOWER + "0123456789").WithMarkers(0, -1));
            // C2: same as C but ModifyProperties really changes the em size (positive control)
            var c2 = new Doc("C2-scope-visible", "scope-visible",
                "same as scope-whole but ModifyProperties DOUBLES the em size: positive control that the modifier " +
                "machinery is really applied",
                "" + O + LONG_LOWER + "0123456789").WithMarkers(0, -1);
            c2.ModifierVisible = true;
            list.Add(c2);
            // D: control, no modifier run at all
            list.Add(new Doc("D-nomodifier", "nomodifier",
                "CONTROL: the same text and width with no modifier run at all",
                LONG_LOWER + "0123456789"));
            // E: modifier present but the paragraph is a single line (no following line)
            list.Add(new Doc("E-scope-oneline", "scope-oneline",
                "modifier scope present but the paragraph fits on ONE line, so there is no following line",
                "" + O + "abc").WithMarkers(0, -1));
            return list.ToArray();
        }

        public static int Main(string[] args)
        {
            string outDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\out-modifier";
            Directory.CreateDirectory(outDir);

            var allCps = new SortedSet<int>();
            void AddCps(string text)
            {
                foreach (char ch in text)
                    if (ch != '\t' && ch != TextModel.OpenMarker && ch != TextModel.CloseMarker) allCps.Add(ch);
            }
            foreach (var d in BuildScopeDocs()) AddCps(d.Buffer);
            AddCps("b" + "\t" + "c" + "\u05D0\u05D1\u05D2\u05D3\u05D4\u05D5\u05D6\u05D7\u05D8\u05D9\u05DB\u05DC\u05DE\u05E0\u05E1\u05E2\u05E4\u05E6\u05E7\u05E8\u05E9\u05EA");

            var typefaces = new Dictionary<string, GlyphTypeface>();
            var fontStates = new Dictionary<string, (bool resolvable, bool usable, string uri, string sha, List<object> missing)>();
            foreach (string fam in FontCandidates)
            {
                if (!new Typeface(fam).TryGetGlyphTypeface(out GlyphTypeface gt))
                { fontStates[fam] = (false, false, null, null, null); continue; }
                typefaces[fam] = gt;
                var missing = new List<object>();
                foreach (int cp in allCps) if (!gt.CharacterToGlyphMap.ContainsKey(cp)) missing.Add("U+" + cp.ToString("X4"));
                fontStates[fam] = (true, missing.Count == 0, gt.FontUri.ToString(),
                    gt.FontUri.IsFile ? Sha256(gt.FontUri.LocalPath) : null, missing);
            }
            string chosen = null;
            foreach (string fam in FontCandidates) if (fontStates.TryGetValue(fam, out var st) && st.usable) { chosen = fam; break; }
            if (chosen == null)
            {
                Console.Error.WriteLine("NO SINGLE FONT COVERS THE CORPUS");
                foreach (var kv in fontStates)
                    Console.Error.WriteLine("  " + kv.Key + " resolvable=" + kv.Value.resolvable + " missing=" +
                        (kv.Value.missing == null ? "n/a" : string.Join(",", kv.Value.missing)));
                return 3;
            }
            var chosenState = fontStates[chosen];

            var coverage = new List<object>();
            foreach (string fam in FontCandidates)
            {
                var st = fontStates[fam];
                var entry = new Dictionary<string, object>
                {
                    ["family"] = fam, ["typefaceResolvable"] = st.resolvable,
                    ["fontUri"] = st.uri, ["sha256"] = st.sha,
                    ["coversEveryCodePointUsed"] = st.usable, ["missing"] = st.missing,
                    ["chosen"] = fam == chosen,
                };
                if (fam == chosen)
                {
                    var per = new List<object>();
                    var g = typefaces[fam].CharacterToGlyphMap;
                    foreach (int cp in allCps)
                        per.Add(new Dictionary<string, object>
                        {
                            ["codePoint"] = "U+" + cp.ToString("X4"),
                            ["char"] = char.ConvertFromUtf32(cp),
                            ["covered"] = g.ContainsKey(cp),
                            ["glyphIndex"] = g.ContainsKey(cp) ? (int)g[cp] : -1,
                        });
                    entry["perCodePoint"] = per;
                }
                coverage.Add(entry);
            }

            var formatter = TextFormatter.Create();
            var cases = new List<object>();
            var human = new StringBuilder();
            human.AppendLine("WPF oracle - TextModifier scope / pen-on-stop / RTL clamp / two tabs at line start (RAW machine output)");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine("machine: " + Environment.OSVersion.VersionString + " | " +
                             System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription +
                             " | PresentationCore " + typeof(TextFormatter).Assembly.GetName().Version);
            human.AppendLine("font: " + chosen + " sha256=" + chosenState.sha);
            human.AppendLine($"Dpi={Dpi} emSize={EmSize} interval(rule)=4*emSize={4 * EmSize}");
            human.AppendLine("markers: U+E000 = the index where the TextSource returns a TextModifier run (length 1);");
            human.AppendLine("         U+E001 = the index where it returns TextEndOfSegment(1). Neither is returned as text.");
            human.AppendLine();

            // ---- item 1: modifier scope vs GetTextLineBreak() ----
            foreach (var doc in BuildScopeDocs())
                foreach (double w in new[] { 80.0, 100.0, 140.0 })
                    cases.Add(Measure(formatter, doc, w,
                        doc.Group.StartsWith("A-rtl") ? FlowDirection.RightToLeft : FlowDirection.LeftToRight,
                        I0, chosen, human));

            // ---- item 2: pen exactly on a tab stop ----
            var penDocs = new List<Doc>
            {
                new Doc("F-pen-on-stop", "two-tabs", "tab1 reaches the stop 96, so tab2's pen is EXACTLY 96.000000", "\t\tb"),
                new Doc("F-pen-on-stop", "c7-tab", "CALIBRATION: 7 x 'c' = 84.000000, so the stop is 96 (advance 12)", "ccccccc\tb"),
                new Doc("F-pen-on-stop", "c8-tab", "8 x 'c' = 96.000000 exactly, so the pen is EXACTLY on the stop", "cccccccc\tb"),
                new Doc("F-pen-on-stop", "c9-tab", "CALIBRATION: 9 x 'c' = 108.000000, so the stop is 192 (advance 84)", "ccccccccc\tb"),
            };
            foreach (var doc in penDocs)
                cases.Add(Measure(formatter, doc, 400.0, FlowDirection.LeftToRight, I0, chosen, human));
            cases.Add(Measure(formatter, new Doc("F-pen-on-stop", "c6-tab-ind24", "Indent=24 + 6 x 'c' = 96.000000 exactly", "cccccc\tb"), 400.0, FlowDirection.LeftToRight, I24, chosen, human));
            cases.Add(Measure(formatter, new Doc("F-pen-on-stop", "c7-tab-ind24", "CALIBRATION: Indent=24 + 7 x 'c' = 108.000000", "ccccccc\tb"), 400.0, FlowDirection.LeftToRight, I24, chosen, human));
            cases.Add(Measure(formatter, new Doc("F-pen-on-stop-rtl", "two-tabs-rtl", "RTL: tab1 reaches the stop, so tab2's pen is EXACTLY at the stop", "\t\t\u05D0"), 400.0, FlowDirection.RightToLeft, I0, chosen, human));
            cases.Add(Measure(formatter, new Doc("F-pen-on-stop-rtl", "he-then-two-tabs", "RTL: alef then two tabs, so tab2's pen is exactly the stop tab1 reached", "\u05D0\t\t\u05D1"), 400.0, FlowDirection.RightToLeft, I0, chosen, human));

            // ---- item 3: RTL + Indent > 0 + ParagraphIndent > 0 ----
            foreach (string text in new[] { "\t\u05D0", "\u05D0\t\u05D1" })
                foreach (double w in new[] { 60.0, 100.0, 140.0 })
                    foreach (var arm in new[] { I24P24, I24P48 })
                        cases.Add(Measure(formatter, new Doc("G-rtl-indent-paraindent",
                            text == "\t\u05D0" ? "he-lead-tab" : "he-mid-tab",
                            "RTL clamp span with Indent>0 AND ParagraphIndent>0", text),
                            w, FlowDirection.RightToLeft, arm, chosen, human));

            // ---- item 4 (bonus): two adjacent tabs at line start ----
            foreach (var t in new[] { ("two-tabs-ltr", "\t\tb", FlowDirection.LeftToRight), ("two-tabs-rtl", "\t\t\u05D0", FlowDirection.RightToLeft) })
                foreach (double w in new[] { 40.0, 80.0, 100.0 })
                    foreach (var arm in new[] { I0, I24 })
                        cases.Add(Measure(formatter, new Doc("H-two-tabs-line-start", t.Item1,
                            "two adjacent tabs at line start: after the first is clamped, what does the second do?", t.Item2),
                            w, t.Item3, arm, chosen, human));

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-modifier-scope-raw/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["os"] = Environment.OSVersion.VersionString,
                ["clr"] = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
                ["presentationCore"] = typeof(TextFormatter).Assembly.GetName().Version.ToString(),
                ["measurement"] = "TextFormatter.Create().FormatLine(...) looped over TextLine.GetTextLineBreak(); for every line the " +
                                  "break object is recorded (null or not) and additionally dumped through reflection",
                ["dpi"] = Dpi, ["units"] = "DIP (1/96 inch)", ["emSizeDip"] = EmSize,
                ["fontFamily"] = chosen, ["fontUri"] = chosenState.uri, ["fontSha256"] = chosenState.sha,
                ["fontSelection"] = "first candidate whose CharacterToGlyphMap covers every code point of every document here",
                ["fontCoverageTable"] = coverage,
                ["markers"] = "U+E000 marks the index where the client TextSource returns a TextModifier run of length 1; U+E001 marks " +
                              "the index where it returns TextEndOfSegment(1). The source never returns those characters as text, so they " +
                              "occupy a character index but produce no glyph and no advance.",
                ["paragraphProperties"] = "TextAlignment=Left, TextWrapping=Wrap, LineHeight=0 (natural), Tabs=null, DefaultIncrementalTab " +
                                          "not overridden; Indent/ParagraphIndent are named per case",
                ["xNote"] = "rawX is the TextBounds x as WPF reports it (origin = the line's start edge, increasing in the advance " +
                            "direction: device left edge for LTR, device RIGHT edge for RTL). xFromLeftDip is measured from the line's left edge.",
                ["breakReasonApi"] = "NOT AVAILABLE: WPF exposes no 'why did it break here'; breakCause in each line is DERIVED",
                ["textLineBreakApiSurface"] = ApiSurfaceProbe(),
                ["cases"] = cases,
            };

            var seen = new HashSet<string>();
            foreach (var o in cases)
            {
                var d = (Dictionary<string, object>)o;
                if (!seen.Add((string)d["id"])) { Console.Error.WriteLine("DUPLICATE CASE ID: " + d["id"]); return 4; }
            }

            File.WriteAllText(Path.Combine(outDir, "modifier-scope-raw.json"),
                JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "modifier-scope-raw.txt"), human.ToString(), new UTF8Encoding(false));
            Console.WriteLine("cases: " + cases.Count);
            int nullBreaks = 0, nonNull = 0;
            foreach (var o in cases)
                foreach (var b in (List<object>)((Dictionary<string, object>)o)["lineBreaks"])
                    if ((bool)((Dictionary<string, object>)b)["isNull"]) nullBreaks++; else nonNull++;
            Console.WriteLine("lineBreaks: null=" + nullBreaks + " nonNull=" + nonNull);
            // quick console read-out of the item-1 groups: "N" = the break is NULL, "y" = non-null
            foreach (var o in cases)
            {
                var c = (Dictionary<string, object>)o;
                string g = (string)c["group"];
                if (g == "F-pen-on-stop" || g == "F-pen-on-stop-rtl" || g == "G-rtl-indent-paraindent" || g == "H-two-tabs-line-start") continue;
                var sb = new StringBuilder();
                foreach (var b in (List<object>)c["lineBreaks"]) sb.Append((bool)((Dictionary<string, object>)b)["isNull"] ? "N" : "y");
                var sc = new StringBuilder();
                foreach (var lo in (List<object>)c["lines"])
                {
                    object v = ((Dictionary<string, object>)lo)["intersectsModifierScope_openInclusive_closeExclusive"];
                    sc.Append(v == null ? "-" : ((bool)v ? "S" : "."));
                }
                Console.WriteLine("SCOPE " + c["id"] + "  breaks(null=N,nonNull=y)=" + sb + "  scopeIntersect(S=yes,.=no,-=n/a)=" + sc);
            }
            return 0;
        }

        /// <summary>
        /// Machine-side answer to "can a client read the scope out of a TextLineBreak?" - enumerates the
        /// public instance surface of TextLineBreak and the visibility of the TextModifierScope type.
        /// </summary>
        private static Dictionary<string, object> ApiSurfaceProbe()
        {
            var asm = typeof(TextFormatter).Assembly;
            var tlb = typeof(TextLineBreak);
            var publicMembers = new List<object>();
            bool anyReturnsScope = false;
            foreach (MemberInfo m in tlb.GetMembers(BindingFlags.Public | BindingFlags.Instance))
            {
                string sig;
                if (m is MethodInfo mi) sig = mi.ReturnType.Name + " " + mi.Name + "(" + string.Join(",", Array.ConvertAll(mi.GetParameters(), x => x.ParameterType.Name)) + ")";
                else if (m is PropertyInfo pi) sig = pi.PropertyType.Name + " " + pi.Name;
                else if (m is FieldInfo fi) sig = fi.FieldType.Name + " " + fi.Name;
                else sig = m.MemberType + " " + m.Name;
                if (sig.IndexOf("Scope", StringComparison.Ordinal) >= 0) anyReturnsScope = true;
                publicMembers.Add(sig);
            }
            var scopeType = asm.GetType("System.Windows.Media.TextFormatting.TextModifierScope");
            var internalMembers = new List<object>();
            foreach (FieldInfo f in tlb.GetFields(BindingFlags.Instance | BindingFlags.NonPublic))
                internalMembers.Add(f.FieldType.Name + " " + f.Name);
            foreach (PropertyInfo p in tlb.GetProperties(BindingFlags.Instance | BindingFlags.NonPublic))
                internalMembers.Add(p.PropertyType.Name + " " + p.Name + " (non-public)");
            var scopeFields = new List<object>();
            if (scopeType != null)
                foreach (FieldInfo f in scopeType.GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
                    scopeFields.Add(f.FieldType.Name + " " + f.Name);
            return new Dictionary<string, object>
            {
                ["textLineBreakPublicInstanceMembers"] = publicMembers,
                ["textLineBreakHasPublicScopeMember"] = anyReturnsScope,
                ["textLineBreakNonPublicInstanceMembers"] = internalMembers,
                ["textModifierScopeTypeFound"] = scopeType != null,
                ["textModifierScopeTypeVisibility"] = scopeType == null ? "type not found in PresentationCore" :
                    ((scopeType.IsPublic || scopeType.IsNestedPublic) ? "PUBLIC" : "NON-public (internal) - not reachable from client code without reflection"),
                ["textModifierScopeMembers"] = scopeFields,
                ["conclusion"] = "a client can obtain the TextLineBreak object but the scope it carries is not part of the " +
                                 "public surface; the values reported under lineBreaks[].reflectionOfTextLineBreak were read " +
                                 "through non-public reflection over the runtime objects.",
            };
        }

        private static Dictionary<string, object> Measure(TextFormatter formatter, Doc doc, double width, FlowDirection flow,
            IndentArm indentArm, string font, StringBuilder human)
        {
            var props = new Props(new Typeface(font), EmSize);
            var para = new Para(props, flow, indentArm);
            var source = new StringSource(doc, props, flow);

            var lines = new List<object>();
            var breakDumps = new List<object>();
            int index = 0;
            TextLineBreak brk = null;
            int guard = 0;
            bool stoppedEarly = false;
            while (index < doc.Buffer.Length && guard++ < 64)
            {
                TextLine line = formatter.FormatLine(source, index, width, para, brk);
                TextLineBreak thisBreak = null;
                string breakError = null;
                try { thisBreak = line.GetTextLineBreak(); }
                catch (Exception e) { breakError = e.GetType().Name + ": " + e.Message; }
                lines.Add(DescribeLine(line, doc, flow, index, lines.Count));
                breakDumps.Add(new Dictionary<string, object>
                {
                    ["lineIndex"] = lines.Count - 1,
                    ["isNull"] = thisBreak == null,
                    ["error"] = breakError,
                    ["reflectionOfTextLineBreak"] = thisBreak == null ? null : Reflect(thisBreak),
                });
                if (brk != null) brk.Dispose();
                brk = thisBreak;
                if (line.Length <= 0) { stoppedEarly = true; break; }
                index += line.Length;
            }
            if (brk != null) brk.Dispose();

            string id = doc.Group + "/" + doc.Id + "@w" + width.ToString("0", CultureInfo.InvariantCulture) +
                        "@" + (flow == FlowDirection.RightToLeft ? "RTL" : "LTR") + "@" + indentArm.Id;
            string fontSha = new Typeface(font).TryGetGlyphTypeface(out GlyphTypeface g) && g.FontUri.IsFile ? Sha256(g.FontUri.LocalPath) : null;
            var rec = new Dictionary<string, object>
            {
                ["id"] = id,
                ["group"] = doc.Group,
                ["docId"] = doc.Id,
                ["note"] = doc.Note,
                ["bufferLength"] = doc.Buffer.Length,
                ["visibleText"] = doc.VisibleText,
                ["bufferWithMarkers"] = Esc(doc.Buffer),
                ["modifierOpenIndex"] = doc.OpenIndex,
                ["modifierCloseIndex"] = doc.CloseIndex,
                ["modifierScopeCharRange"] = doc.OpenIndex < 0 ? null :
                    (object)new[] { doc.OpenIndex, doc.CloseIndex < 0 ? doc.Buffer.Length : doc.CloseIndex },
                ["modifierChangesPropertiesVisibly"] = doc.ModifierVisible,
                ["paragraphWidthDip"] = width,
                ["indentArm"] = indentArm.Id, ["indentDip"] = indentArm.Indent,
                ["paragraphIndentDip"] = indentArm.ParagraphIndent, ["firstLineInParagraph"] = indentArm.FirstLine,
                ["flowDirection"] = flow == FlowDirection.RightToLeft ? "RightToLeft" : "LeftToRight",
                ["fontFamily"] = font, ["fontSha256"] = fontSha,
                ["dpi"] = Dpi, ["emSizeDip"] = EmSize,
                ["lineCount"] = lines.Count,
                ["stoppedEarlyBecauseLineLengthWasZero"] = stoppedEarly,
                ["lineBreaks"] = breakDumps,
                ["lines"] = lines,
            };
            if (human != null)
            {
                human.AppendLine($"== [{id}] visible=\"{Esc(doc.VisibleText)}\"");
                human.AppendLine($"   buffer=\"{Esc(doc.Buffer)}\" open={doc.OpenIndex} close={doc.CloseIndex} scope={(doc.OpenIndex < 0 ? "none" : "[" + doc.OpenIndex + "," + (doc.CloseIndex < 0 ? doc.Buffer.Length : doc.CloseIndex) + ")")}");
                foreach (var o in lines)
                {
                    var L = (Dictionary<string, object>)o;
                    var b = (Dictionary<string, object>)breakDumps[(int)L["index"]];
                    human.AppendLine($"   line {L["index"]}: [{L["startChar"]},{L["endCharExclusive"]}) text=\"{Esc((string)L["lineText"])}\" " +
                                     $"w={F((double)L["width"])} witw={F((double)L["widthIncludingTrailingWhitespace"])} ovf={L["hasOverflowed"]} " +
                                     $"isLast={L["isLastLine"]} breaksScope={L["intersectsModifierScope_openInclusive_closeExclusive"]} " +
                                     $"lineBreakIsNull={b["isNull"]}");
                    foreach (var po in (List<object>)L["perChar"])
                    {
                        var p = (Dictionary<string, object>)po;
                        if (p["rawX"] == null) { human.AppendLine($"        i={p["i"]} {p["kind"]} (no bounds)"); continue; }
                        human.AppendLine($"        i={p["i"]} '{Esc((string)p["char"])}' kind={p["kind"]} rawX={F((double)p["rawX"])} w={F((double)p["width"])} xFromLeft={F((double)p["xFromLeftDip"])}");
                    }
                }
            }
            return rec;
        }

        private static Dictionary<string, object> DescribeLine(TextLine line, Doc doc, FlowDirection flow, int lineStart, int lineIndex)
        {
            int len = (int)line.Length;
            int textLen = len - (int)line.NewlineLength;
            if (lineStart + textLen > doc.Buffer.Length) textLen = Math.Max(doc.Buffer.Length - lineStart, 0);

            var perChar = new List<object>();
            for (int i = 0; i < textLen; i++)
            {
                int gi = lineStart + i;
                if (gi >= doc.Buffer.Length) break;
                string ch = doc.Buffer[gi].ToString();
                IList<TextBounds> b = null;
                string err = null;
                try { b = line.GetTextBounds(gi, 1); }
                catch (Exception e) { err = e.GetType().Name; }
                if (b == null || b.Count == 0)
                {
                    perChar.Add(new Dictionary<string, object>
                    { ["i"] = gi, ["char"] = ch, ["kind"] = KindOf(doc, gi), ["rawX"] = null, ["width"] = null, ["boundsError"] = err });
                    continue;
                }
                perChar.Add(new Dictionary<string, object>
                {
                    ["i"] = gi, ["char"] = ch, ["kind"] = KindOf(doc, gi),
                    ["codePoint"] = "U+" + ((int)doc.Buffer[gi]).ToString("X4"),
                    ["rawX"] = R(b[0].Rectangle.X), ["width"] = R(b[0].Rectangle.Width),
                    ["runFlowDirection"] = b[0].FlowDirection.ToString(),
                });
            }
            double inkRight = 0;
            foreach (var o in perChar) { var d = (Dictionary<string, object>)o; if (d["rawX"] != null) { double r = (double)d["rawX"] + (double)d["width"]; if (r > inkRight) inkRight = r; } }
            foreach (var o in perChar)
            {
                var d = (Dictionary<string, object>)o;
                if (d["rawX"] == null) continue;
                double raw = (double)d["rawX"], w = (double)d["width"];
                d["xFromLeftDip"] = R(flow == FlowDirection.RightToLeft ? inkRight - (raw + w) : raw);
            }

            int end = lineStart + textLen;
            int lastKept = end - 1;
            string cause;
            if (end >= doc.Buffer.Length) cause = "end-of-text";
            else if (textLen == 0) cause = "empty-line";
            else if (lastKept >= 0 && doc.Buffer[lastKept] == '\t') cause = "after-tab";
            else if (doc.Buffer[end] == '\t') cause = "before-tab";
            else if (lastKept >= 0 && doc.Buffer[lastKept] == ' ') cause = "at-space";
            else if (doc.Buffer[end] == TextModel.CloseMarker) cause = "before-close-marker";
            else cause = "mid-token";

            object intersectsExclusive = null, intersectsInclusive = null;
            if (doc.OpenIndex >= 0)
            {
                int scopeEnd = doc.CloseIndex < 0 ? doc.Buffer.Length : doc.CloseIndex;
                intersectsExclusive = lineStart < scopeEnd && end > doc.OpenIndex;
                int scopeEndInc = doc.CloseIndex < 0 ? doc.Buffer.Length - 1 : doc.CloseIndex;
                intersectsInclusive = lineStart <= scopeEndInc && end > doc.OpenIndex;
            }

            return new Dictionary<string, object>
            {
                ["index"] = lineIndex,
                ["paragraphStartOffsetDip"] = R(line.Start),
                ["startChar"] = lineStart,
                ["endCharExclusive"] = end,
                ["lengthWithNewline"] = len,
                ["newlineLength"] = (int)line.NewlineLength,
                ["trailingWhitespaceLength"] = (int)line.TrailingWhitespaceLength,
                ["width"] = R(line.Width),
                ["widthIncludingTrailingWhitespace"] = R(line.WidthIncludingTrailingWhitespace),
                ["hasOverflowed"] = line.HasOverflowed,
                ["isLastLine"] = end >= doc.Buffer.Length,
                ["containsOpenMarker"] = doc.OpenIndex >= 0 && doc.OpenIndex >= lineStart && doc.OpenIndex < end,
                ["containsCloseMarker"] = doc.CloseIndex >= 0 && doc.CloseIndex >= lineStart && doc.CloseIndex < end,
                ["intersectsModifierScope_openInclusive_closeExclusive"] = intersectsExclusive,
                ["intersectsModifierScope_openInclusive_closeInclusive"] = intersectsInclusive,
                ["lineText"] = SafeSlice(doc.Buffer, lineStart, textLen),
                ["visibleLineText"] = Visible(doc.Buffer, lineStart, textLen),
                ["breakCause"] = cause,
                ["breakCauseNote"] = "DERIVED from the characters around the break, not reported by WPF",
                ["perChar"] = perChar,
            };
        }

        private static string KindOf(Doc doc, int i)
        {
            if (i == doc.OpenIndex) return "OPEN-MARKER(TextModifier run site)";
            if (i == doc.CloseIndex) return "CLOSE-MARKER(TextEndOfSegment run site)";
            return doc.Buffer[i] == '\t' ? "tab" : "char";
        }

        private static string Visible(string s, int start, int len)
        {
            var sb = new StringBuilder();
            for (int i = start; i < start + len && i < s.Length; i++)
                if (s[i] != TextModel.OpenMarker && s[i] != TextModel.CloseMarker) sb.Append(s[i]);
            return sb.ToString();
        }

        // ---------------- reflection dump ----------------

        private static object Reflect(object root)
        {
            var visited = new HashSet<object>(ReferenceEqualityComparer.Instance);
            return Describe(root, 3, visited);
        }

        private static object Describe(object v, int depth, HashSet<object> visited)
        {
            if (v == null) return null;
            Type t = v.GetType();
            if (v is string s) return "string: \"" + Esc(s) + "\"";
            if (v is Type ty) return "Type: " + ty.FullName;
            if (v is TextModifier tm) return "<TextModifier " + tm.GetType().Name + " Length=" + tm.Length + ">";
            if (v is TextRunProperties trp) return "<TextRunProperties " + trp.GetType().Name + " emSize=" + trp.FontRenderingEmSize.ToString(CultureInfo.InvariantCulture) + ">";
            if (t.IsPrimitive || v is decimal) return v.ToString();
            if (t.IsEnum) return t.Name + "." + v.ToString();
            if (depth <= 0) return "<" + t.FullName + " not expanded>";
            if (!t.IsValueType)
            {
                if (visited.Contains(v)) return "<" + t.FullName + " already visited>";
                visited.Add(v);
            }
            var d = new Dictionary<string, object> { ["__type"] = t.FullName };
            if (v is IEnumerable en)
            {
                int n = 0;
                try { foreach (var _ in en) { n++; if (n > 64) break; } } catch { }
                d["__count"] = n;
            }
            foreach (FieldInfo f in t.GetFields(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
            {
                object fv;
                try { fv = f.GetValue(v); }
                catch (Exception e) { d[f.Name] = "<read error " + e.GetType().Name + ">"; continue; }
                d[(f.IsPublic ? "" : "_") + f.Name] = Describe(fv, depth - 1, visited);
            }
            foreach (PropertyInfo p in t.GetProperties(BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic))
            {
                if (p.GetIndexParameters().Length != 0) continue;
                object pv;
                try { pv = p.GetValue(v); }
                catch (Exception e) { d["prop:" + p.Name] = "<read error " + e.GetType().Name + ">"; continue; }
                d["prop:" + p.Name] = Describe(pv, depth - 1, visited);
            }
            return d;
        }

        // ---------------- helpers ----------------

        private static string SafeSlice(string s, int start, int len)
        {
            if (start < 0 || start > s.Length || len <= 0) return "";
            if (start + len > s.Length) len = s.Length - start;
            return s.Substring(start, len);
        }
        private static string Esc(string s) => s == null ? "" : s.Replace("\t", "\\t").Replace("\n", "\\n")
            .Replace(TextModel.OpenMarker.ToString(), "<OPEN>").Replace(TextModel.CloseMarker.ToString(), "<CLOSE>");
        private static double R(double v) => double.IsNaN(v) ? v : Math.Round(v, 6, MidpointRounding.AwayFromZero);
        private static string F(double v) => double.IsNaN(v) ? "n/a" : v.ToString("0.######", CultureInfo.InvariantCulture);

        private static string Sha256(string path)
        {
            try
            {
                using var sha = SHA256.Create();
                using var fs = File.OpenRead(path);
                byte[] h = sha.ComputeHash(fs);
                var sb = new StringBuilder(h.Length * 2);
                foreach (byte b in h) sb.Append(b.ToString("x2", CultureInfo.InvariantCulture));
                return sb.ToString();
            }
            catch (Exception e) { return "ERR " + e.Message; }
        }
    }

    // ============================ text model ============================

    internal sealed class StringSource : TextSource
    {
        private readonly string _text;
        private readonly TextRunProperties _props;
        private readonly FlowDirection _flow;
        private readonly int _openIndex, _closeIndex;
        private readonly bool _visibleModifier;

        public StringSource(Doc doc, TextRunProperties props, FlowDirection flow)
        {
            _text = doc.Buffer; _props = props; _flow = flow;
            _openIndex = doc.OpenIndex; _closeIndex = doc.CloseIndex; _visibleModifier = doc.ModifierVisible;
        }

        public override TextRun GetTextRun(int index)
        {
            if (index >= _text.Length) return new TextEndOfParagraph(1);
            if (index == _openIndex) return new Modifier(1, _flow, _props, _visibleModifier);
            if (index == _closeIndex) return new TextEndOfSegment(1);
            int next = _text.Length;
            if (_openIndex > index) next = Math.Min(next, _openIndex);
            if (_closeIndex > index) next = Math.Min(next, _closeIndex);
            return new TextCharacters(_text, index, next - index, _props);
        }

        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
        {
            int len = Math.Min(Math.Max(limit, 0), _text.Length);
            return new TextSpan<CultureSpecificCharacterBufferRange>(len,
                new CultureSpecificCharacterBufferRange(CultureInfo.CurrentCulture, new CharacterBufferRange(_text, 0, len)));
        }

        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
    }

    /// <summary>Client TextModifier: a marker run with no glyphs that pushes a modification scope.</summary>
    internal sealed class Modifier : TextModifier
    {
        private readonly int _length;
        private readonly FlowDirection _flow;
        private readonly TextRunProperties _props;
        private readonly bool _visible;

        public Modifier(int length, FlowDirection flow, TextRunProperties props, bool visible)
        { _length = length; _flow = flow; _props = props; _visible = visible; }

        public override int Length => _length;
        public override TextRunProperties Properties => null;   // null for a TextModifier run
        public override FlowDirection FlowDirection => _flow;
        public override bool HasDirectionalEmbedding => false;

        public override TextRunProperties ModifyProperties(TextRunProperties properties)
        {
            if (!_visible) return properties;
            var p = (properties as Props) ?? (_props as Props);
            double size = p != null ? p.FontRenderingEmSize : Program.EmSize;
            return new Props(p != null ? p.Typeface : new Typeface("Arial"), size * 2.0);
        }
    }

    internal sealed class Props : TextRunProperties
    {
        public Props(Typeface tf, double size) { Typeface = tf; FontRenderingEmSize = size; }
        public override Typeface Typeface { get; }
        public override double FontRenderingEmSize { get; }
        public override double FontHintingEmSize => FontRenderingEmSize;
        public override Brush ForegroundBrush => Brushes.Black;
        public override Brush BackgroundBrush => null;
        public override CultureInfo CultureInfo => CultureInfo.GetCultureInfo("en-us");
        public override TextDecorationCollection TextDecorations => null;
        public override TextEffectCollection TextEffects => null;
        public override BaselineAlignment BaselineAlignment => BaselineAlignment.Baseline;
        public override NumberSubstitution NumberSubstitution => null;
        public override TextRunTypographyProperties TypographyProperties => null;
    }

    internal sealed class Para : TextParagraphProperties
    {
        private readonly double _indent, _paraIndent;
        private readonly bool _firstLine;
        public Para(TextRunProperties props, FlowDirection flow, IndentArm arm)
        {
            DefaultTextRunProperties = props; FlowDirection = flow;
            _indent = arm.Indent; _paraIndent = arm.ParagraphIndent; _firstLine = arm.FirstLine;
        }
        public override TextRunProperties DefaultTextRunProperties { get; }
        public override FlowDirection FlowDirection { get; }
        public override TextAlignment TextAlignment => TextAlignment.Left;
        public override TextWrapping TextWrapping => TextWrapping.Wrap;
        public override double LineHeight => 0;
        public override bool FirstLineInParagraph => _firstLine;
        public override double Indent => _indent;
        public override double ParagraphIndent => _paraIndent;
        public override bool AlwaysCollapsible => false;
        public override TextDecorationCollection TextDecorations => null;
        public override TextMarkerProperties TextMarkerProperties => null;
        public override IList<TextTabProperties> Tabs => null;
    }
}

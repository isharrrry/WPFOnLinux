using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

namespace TabAnchorOracle
{
    /// <summary>
    /// U1 real-machine oracle: Tab ANCHOR discrimination + Indent semantics.
    ///
    /// WHY THIS ARM EXISTS (asked by the main control agent):
    ///   The previous tab oracle family fixed the paragraph width to 40/80/160/320 and the interval is
    ///   4*emSize = 96 at emSize 24. Every line width that carried a tab happened to be an exact
    ///   multiple of 96, and when L mod interval == 0 the two competing hypotheses
    ///       "the tab stop grid is anchored at the line's LEFT edge"  and
    ///       "the tab stop grid is anchored at the line's RIGHT edge"
    ///   produce THE SAME stop positions. Those samples therefore cannot distinguish them.
    ///   This arm re-runs the same measurement on widths that are NOT multiples of the interval, where
    ///   the two grids are disjoint (L mod I = r != 0  =>  "on grid from left" == "on grid from right"
    ///   is impossible), so a single reading decides the question.
    ///
    /// SECOND DIMENSION (added by the main control agent, same trip): Indent x line-start tab.
    ///   T1d needs a definition for "tab is at line start" (pen position 0): with Indent > 0 the pen
    ///   at a line-start tab is `indent`, not 0, so it is an open question whether "line start" is
    ///   judged against the line origin or against the indented content start. Also open: when a tab
    ///   IS clamped, does it fill `width` or `width - indent`.
    ///
    /// Everything is measured, nothing is assumed: the interval itself is MEASURED from probe cases
    /// with two adjacent tabs (distance between two consecutive reached stops), not taken from the
    /// 4*emSize rule.
    /// </summary>
    public static class Program
    {
        private const double EmSize = 24.0;
        private const double Dpi = 96.0;

        // ---- Block A: anchor discrimination. Non-multiples of the interval (96) are the decisive
        //      widths; 96/192 are kept as the ambiguous controls the previous arm used.
        private static readonly double[] AnchorWidths = { 96.0, 100.0, 140.0, 192.0, 200.0, 220.0, 260.0 };

        private static readonly (string Id, string Text, string Note)[] AnchorTexts =
        {
            ("lat-a-t-b",  "a\tb",                                  "Latin content, ONE tab in the middle (tab is not at line end)"),
            ("lat-ab-t-c", "ab\tc",                                 "Latin content, ONE tab in the middle, longer prefix"),
            ("he-a-t-b",   "\u05D0\t\u05D1",                       "pure Hebrew, ONE tab in the middle"),
            ("he-ab-t-g",  "\u05D0\u05D1\t\u05D2",                 "pure Hebrew, ONE tab in the middle, longer prefix"),
            ("ar-a-t-b",   "\u0627\t\u0628",                       "pure Arabic, ONE tab in the middle"),
            ("ar-ab-t-j",  "\u0627\u0628\t\u062C",                 "pure Arabic, ONE tab in the middle, longer prefix"),
        };

        // ---- Block B: Indent x tab position (LTR).
        private static readonly double[] IndentWidths = { 40.0, 80.0, 96.0, 100.0, 140.0, 160.0, 192.0, 220.0 };
        private static readonly double[] IndentExtraWidths = { 40.0, 80.0, 140.0 };

        private static readonly (string Id, string Text, string Note)[] IndentTexts =
        {
            ("lead-tab-a",     "\ta",       "ONE tab at line START, then a non-tab char (tab is not at line end)"),
            ("lead-tab-b-t-c", "\tb\tc",    "tab at line START + a second tab in the middle"),
            ("mid-tab-a-t-b",  "a\tb",      "ONE tab in the middle (never at line start)"),
            ("notab-control",  "ab",        "CONTROL: no tab at all"),
        };

        // ---- Block C: Indent x line-start tab under an RTL paragraph (pure Hebrew content).
        private static readonly double[] RtlIndentWidths = { 40.0, 100.0, 140.0, 220.0 };

        private static readonly (string Id, string Text, string Note)[] RtlIndentTexts =
        {
            ("he-lead-tab-a", "\t\u05D0",           "pure Hebrew, ONE tab at line START"),
            ("he-mid-tab",    "\u05D0\t\u05D1",     "pure Hebrew, ONE tab in the middle"),
        };

        // ---- Block D: does ParagraphIndent move the tab grid? (seen in Block B; gets its own samples here) ----
        private static readonly double[] ParaIndentWidths = { 100.0, 140.0, 220.0 };
        private static readonly (string Id, string Text, string Note)[] ParaIndentLtrTexts =
        {
            ("lead-tab-a",    "\ta",  "ONE tab at line START, then a non-tab char"),
            ("mid-tab-a-t-b", "a\tb", "ONE tab in the middle"),
        };
        private static readonly (string Id, string Text, string Note)[] ParaIndentRtlTexts =
        {
            ("he-lead-tab-a", "\t\u05D0",        "pure Hebrew, ONE tab at line START"),
            ("he-mid-tab",    "\u05D0\t\u05D1", "pure Hebrew, ONE tab in the middle"),
        };

        // ---- Block P: the interval MEASURING instrument (two adjacent tabs -> two consecutive stops).
        private static readonly double[] ProbeWidths = { 1000.0 };

        private static readonly (string Id, string Text, string Note)[] ProbeTexts =
        {
            ("probe-lat", "ab\t\tc",                              "INSTRUMENT (not an answer sample): two adjacent tabs expose two consecutive reached stops"),
            ("probe-he",  "\u05D0\u05D1\t\t\u05D2",               "INSTRUMENT (not an answer sample): pure Hebrew"),
            ("probe-ar",  "\u0627\u0628\t\t\u062C",               "INSTRUMENT (not an answer sample): pure Arabic"),
        };

        private static readonly string[] FontCandidates = { "Arial", "Segoe UI", "Tahoma", "Times New Roman" };

        private static readonly IndentArm I0 = new IndentArm("i0", 0, 0, true,
            "baseline: Indent=0, ParagraphIndent=0, FirstLineInParagraph=true");
        private static readonly IndentArm I24 = new IndentArm("i24", 24, 0, true,
            "Indent=24, ParagraphIndent=0, FirstLineInParagraph=true");
        private static readonly IndentArm I24P24 = new IndentArm("i24p24", 24, 24, true,
            "Indent=24 AND ParagraphIndent=24 (does ParagraphIndent add on top?)");
        private static readonly IndentArm I0P24 = new IndentArm("i0p24", 0, 24, true,
            "ParagraphIndent=24 only (isolates ParagraphIndent)");
        private static readonly IndentArm I0P48 = new IndentArm("i0p48", 0, 48, true,
            "ParagraphIndent=48 only (confirms the grid origin scales with ParagraphIndent)");
        private static readonly IndentArm I24P48 = new IndentArm("i24p48", 24, 48, true,
            "Indent=24 AND ParagraphIndent=48");
        private static readonly IndentArm I24NL = new IndentArm("i24nl", 24, 0, false,
            "Indent=24 with FirstLineInParagraph=false (does Indent still apply?)");
        private static readonly IndentArm[] AllIndentArms = { I0, I24, I24P24, I0P24, I0P48, I24P48, I24NL };

        public static int Main(string[] args)
        {
            string outDir = args.Length > 0 ? args[0] : @"C:\u1-shaping\out-tabanchor";
            Directory.CreateDirectory(outDir);

            // ---------- font selection: one family that covers every code point used, per script group ----------
            var cpsByScript = new Dictionary<string, SortedSet<int>>();
            var allCps = new SortedSet<int>();
            void AddCps(string script, string text)
            {
                if (!cpsByScript.TryGetValue(script, out var s)) cpsByScript[script] = s = new SortedSet<int>();
                foreach (char ch in text) if (ch != '\t') { s.Add(ch); allCps.Add(ch); }
            }
            foreach (var t in AnchorTexts) AddCps(ScriptOf(t.Text), t.Text);
            foreach (var t in IndentTexts) AddCps(ScriptOf(t.Text), t.Text);
            foreach (var t in RtlIndentTexts) AddCps(ScriptOf(t.Text), t.Text);
            foreach (var t in ProbeTexts) AddCps(ScriptOf(t.Text), t.Text);

            var typefaces = new Dictionary<string, GlyphTypeface>();
            var fontStates = new Dictionary<string, (bool usable, string uri, string sha, List<object> missing)>();
            foreach (string fam in FontCandidates)
            {
                if (!new Typeface(fam).TryGetGlyphTypeface(out GlyphTypeface gt))
                { fontStates[fam] = (false, null, null, null); continue; }
                typefaces[fam] = gt;
                var missing = new List<object>();
                foreach (int cp in allCps) if (!gt.CharacterToGlyphMap.ContainsKey(cp)) missing.Add("U+" + cp.ToString("X4"));
                string sha = gt.FontUri.IsFile ? Sha256(gt.FontUri.LocalPath) : null;
                fontStates[fam] = (missing.Count == 0, gt.FontUri.ToString(), sha, missing);
            }

            // per-script font choice: prefer a single family that covers everything, else the best family per script
            string single = null;
            foreach (string fam in FontCandidates) if (fontStates.TryGetValue(fam, out var st) && st.usable) { single = fam; break; }
            var fontByScript = new Dictionary<string, string>();
            foreach (var kv in cpsByScript)
            {
                if (single != null) { fontByScript[kv.Key] = single; continue; }
                string best = null; int bestMissing = int.MaxValue;
                foreach (string fam in FontCandidates)
                {
                    if (!typefaces.ContainsKey(fam)) continue;
                    int miss = 0; foreach (int cp in kv.Value) if (!typefaces[fam].CharacterToGlyphMap.ContainsKey(cp)) miss++;
                    if (miss < bestMissing) { bestMissing = miss; best = fam; }
                }
                fontByScript[kv.Key] = best;
            }
            string fontSelectionMode = single != null
                ? "single-font: '" + single + "' covers every code point of every script used here"
                : "per-script: no single candidate covers all scripts; the best-covering family was chosen per script";

            var formatter = TextFormatter.Create();

            // ---------- coverage table (+ per-code-point advance measured in BOTH paragraph directions) ----------
            var coverageTable = new List<object>();
            foreach (string fam in FontCandidates)
            {
                if (!fontStates.TryGetValue(fam, out var st)) continue;
                if (!st.usable && st.missing == null)
                { coverageTable.Add(new Dictionary<string, object> { ["family"] = fam, ["typefaceResolvable"] = false }); continue; }
                var entry = new Dictionary<string, object>
                {
                    ["family"] = fam, ["typefaceResolvable"] = true, ["fontUri"] = st.uri, ["sha256"] = st.sha,
                    ["coversEveryCodePointUsed"] = st.missing.Count == 0, ["missing"] = st.missing,
                    ["isChosenFor"] = ChosenFor(fontByScript, fam),
                };
                if (fam == fontByScript.GetValueOrDefault("hebrew") || fam == single)
                {
                    var per = new List<object>();
                    foreach (int cp in allCps)
                    {
                        var g = typefaces[fam].CharacterToGlyphMap;
                        var row = new Dictionary<string, object>
                        {
                            ["codePoint"] = "U+" + cp.ToString("X4"),
                            ["char"] = char.ConvertFromUtf32(cp),
                            ["covered"] = g.ContainsKey(cp),
                            ["glyphIndex"] = g.ContainsKey(cp) ? (int)g[cp] : -1,
                        };
                        if (g.ContainsKey(cp))
                        {
                            double advL = Advance(formatter, char.ConvertFromUtf32(cp), FlowDirection.LeftToRight, fam);
                            double advR = Advance(formatter, char.ConvertFromUtf32(cp), FlowDirection.RightToLeft, fam);
                            row["advanceLtrParagraphDip"] = R(advL);
                            row["advanceRtlParagraphDip"] = R(advR);
                            row["advanceSameInBothDirections"] = Math.Abs(advL - advR) < 1e-9;
                        }
                        per.Add(row);
                    }
                    entry["perCodePoint"] = per;
                }
                coverageTable.Add(entry);
            }

            var cases = new List<object>();
            var human = new StringBuilder();
            human.AppendLine("WPF tab oracle - ANCHOR discrimination + Indent semantics (RAW machine output, human readable)");
            human.AppendLine("generated: " + DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture));
            human.AppendLine("machine: " + Environment.OSVersion.VersionString + " | " +
                             System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription +
                             " | PresentationCore " + typeof(TextFormatter).Assembly.GetName().Version);
            human.AppendLine($"Dpi={Dpi} emSize={EmSize} interval(rule)=4*emSize={4 * EmSize} (the rule is NOT used by the analyzer; the interval is MEASURED from the probe cases)");
            human.AppendLine("TextWrapping=Wrap, TextAlignment=Left, LineHeight=0 (natural)");
            human.AppendLine("tab arms: default (DefaultIncrementalTab not overridden) | tab0 (DefaultIncrementalTab=0)");
            human.AppendLine("font selection: " + fontSelectionMode);
            foreach (var kv in fontByScript)
                human.AppendLine($"   script {kv.Key} -> {kv.Value}  sha256={(fontStates.TryGetValue(kv.Value, out var s2) ? s2.sha : "n/a")}");
            human.AppendLine();
            human.AppendLine("=== FONT COVERAGE / ADVANCE TABLE (each script's code points) ===");
            human.AppendLine("   (advance measured alone in a 1000-DIP paragraph, once per paragraph direction)");
            foreach (var o in coverageTable)
            {
                var d = (Dictionary<string, object>)o;
                if (!(bool)d["typefaceResolvable"]) { human.AppendLine($"   {d["family"]}: typeface NOT resolvable"); continue; }
                var miss = (List<object>)d["missing"];
                human.AppendLine($"   {d["family"]}: coversAll={d["coversEveryCodePointUsed"]} missing={miss.Count} uri={d["fontUri"]} sha256={d["sha256"]} isChosenFor={string.Join(",", (List<string>)d["isChosenFor"])}");
                if (d.ContainsKey("perCodePoint"))
                    foreach (var po in (List<object>)d["perCodePoint"])
                    {
                        var p = (Dictionary<string, object>)po;
                        human.AppendLine($"      {p["codePoint"]} '{p["char"]}' covered={p["covered"]} glyph={p["glyphIndex"]}" +
                                         (p.ContainsKey("advanceLtrParagraphDip")
                                            ? $" advLTR={F((double)p["advanceLtrParagraphDip"])} advRTL={F((double)p["advanceRtlParagraphDip"])} same={p["advanceSameInBothDirections"]}"
                                            : ""));
                    }
            }
            human.AppendLine();

            // ---------- Block A ----------
            foreach (var t in AnchorTexts)
            {
                var flow = ScriptOf(t.Text) == "latin" ? FlowDirection.LeftToRight : FlowDirection.RightToLeft;
                foreach (double w in AnchorWidths)
                    foreach (bool tabZero in new[] { false, true })
                        cases.Add(Measure(formatter, "A-anchor", t.Id, t.Text, t.Note, w, flow, I0, tabZero, fontByScript, human));
            }
            // Block A contrast: pure-Hebrew content inside an LTR paragraph (paragraph direction != content direction)
            foreach (var t in new[] { AnchorTexts[2], AnchorTexts[3] })
                foreach (double w in AnchorWidths)
                    foreach (bool tabZero in new[] { false, true })
                        cases.Add(Measure(formatter, "A-contrast", "ltr-" + t.Id, t.Text, "CONTRAST: " + t.Note + ", but the PARAGRAPH direction is LeftToRight",
                            w, FlowDirection.LeftToRight, I0, tabZero, fontByScript, human));

            // ---------- Block B ----------
            foreach (var t in IndentTexts)
                foreach (double w in IndentWidths)
                    foreach (var arm in new[] { I0, I24 })
                        foreach (bool tabZero in new[] { false, true })
                            cases.Add(Measure(formatter, "B-indent", t.Id, t.Text, t.Note, w, FlowDirection.LeftToRight, arm, tabZero, fontByScript, human));
            // tab-only text: nothing but a tab, so a clamp cannot be hidden by a following character
            foreach (double w in new[] { 40.0, 80.0, 100.0, 140.0 })
                foreach (var arm in new[] { I0, I24 })
                    foreach (bool tabZero in new[] { false, true })
                        cases.Add(Measure(formatter, "B-indent", "lead-tab-only", "\t", "ONLY a tab: the line contains nothing else", w,
                            FlowDirection.LeftToRight, arm, tabZero, fontByScript, human));
            // extra Indent/ParagraphIndent/FirstLineInParagraph combinations
            foreach (var t in IndentTexts)
                foreach (double w in IndentExtraWidths)
                    foreach (var arm in new[] { I24P24, I0P24, I24NL })
                        foreach (bool tabZero in new[] { false, true })
                            cases.Add(Measure(formatter, "B-indent-extra", t.Id, t.Text, t.Note, w, FlowDirection.LeftToRight, arm, tabZero, fontByScript, human));

            // ---------- Block C (RTL paragraph) ----------
            foreach (var t in RtlIndentTexts)
                foreach (double w in RtlIndentWidths)
                    foreach (var arm in new[] { I0, I24 })
                        foreach (bool tabZero in new[] { false, true })
                            cases.Add(Measure(formatter, "C-rtl-indent", t.Id, t.Text, t.Note, w, FlowDirection.RightToLeft, arm, tabZero, fontByScript, human));

            // ---------- Block D (ParagraphIndent x grid origin) ----------
            foreach (var t in ParaIndentLtrTexts)
                foreach (double w in ParaIndentWidths)
                    foreach (var arm in new[] { I0P24, I24P24, I0P48 })
                        foreach (bool tabZero in new[] { false, true })
                            cases.Add(Measure(formatter, "D-paraindent", t.Id, t.Text, t.Note, w, FlowDirection.LeftToRight, arm, tabZero, fontByScript, human));
            foreach (var t in ParaIndentLtrTexts)   // I24P48 on one width only (case-count control)
                foreach (bool tabZero in new[] { false, true })
                    cases.Add(Measure(formatter, "D-paraindent", t.Id, t.Text, t.Note, 220.0, FlowDirection.LeftToRight, I24P48, tabZero, fontByScript, human));
            foreach (var t in ParaIndentRtlTexts)
                foreach (double w in ParaIndentWidths)
                    foreach (var arm in new[] { I0P24, I0P48 })
                        foreach (bool tabZero in new[] { false, true })
                            cases.Add(Measure(formatter, "D-paraindent", t.Id, t.Text, t.Note, w, FlowDirection.RightToLeft, arm, tabZero, fontByScript, human));

            // ---------- Block P (interval instrument) ----------
            var intervalProbes = new List<object>();
            foreach (var t in ProbeTexts)
                foreach (var flow in new[] { FlowDirection.LeftToRight, FlowDirection.RightToLeft })
                    foreach (bool tabZero in new[] { false, true })
                    {
                        var rec = Measure(formatter, "P-probe", t.Id, t.Text, t.Note, ProbeWidths[0], flow, I0, tabZero, fontByScript, human);
                        cases.Add(rec);
                        intervalProbes.Add(DescribeIntervalProbe(rec, 4 * EmSize));
                    }

            var root = new Dictionary<string, object>
            {
                ["format"] = "wpf-linux-u1-tab-anchor-raw/1",
                ["generatedUtc"] = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture),
                ["os"] = Environment.OSVersion.VersionString,
                ["clr"] = System.Runtime.InteropServices.RuntimeInformation.FrameworkDescription,
                ["presentationCore"] = typeof(TextFormatter).Assembly.GetName().Version.ToString(),
                ["measurement"] = "TextFormatter.Create().FormatLine(...) looped over TextLine.GetTextLineBreak() so every line is recorded",
                ["dpi"] = Dpi, ["units"] = "DIP (1/96 inch)",
                ["emSizeDip"] = EmSize,
                ["intervalRuleNotUsedByAnalyzer"] = "4*emSize = " + (4 * EmSize) + " is only printed for comparison; the answers are computed against the MEASURED interval in `intervalProbes`",
                ["paragraphProperties"] = new Dictionary<string, object>
                {
                    ["fixed"] = "TextAlignment=Left, TextWrapping=Wrap, LineHeight=0 (natural), Tabs=null, TextDecorations=null, TextMarkerProperties=null, AlwaysCollapsible=false",
                    ["indentArms"] = IndentArmTable(),
                    ["tabArms"] = "default (DefaultIncrementalTab not overridden) | tab0 (DefaultIncrementalTab=0)",
                },
                ["fontSelectionMode"] = fontSelectionMode,
                ["fontByScript"] = fontByScript,
                ["fontCoverageTable"] = coverageTable,
                ["xNote"] = "per-char xFromLeftDip = distance from the LINE's left edge (raw TextBounds.X origin is the RIGHT edge for RightToLeft paragraphs). inkRightDip = rightmost ink edge on that line.",
                ["breakReasonApi"] = "NOT AVAILABLE: WPF's TextFormatter/TextLine expose no 'why did it break here' information. " +
                                     "lineStart/lineEnd + the line text are the only truth; breakCause in each line is DERIVED by inspecting the character before/at the break.",
                ["trimmingApi"] = "NOT AVAILABLE in TextFormatter: upstream PresentationCore TextParagraphProperties has NO Trimming member. " +
                                  "Only TextLine.HasOverflowed is reported.",
                ["intervalProbes"] = intervalProbes,
                ["cases"] = cases,
            };

            var seen = new HashSet<string>();
            foreach (var o in cases) { var d = (Dictionary<string, object>)o; if (!seen.Add((string)d["id"])) { Console.Error.WriteLine("DUPLICATE CASE ID: " + d["id"]); return 4; } }

            File.WriteAllText(Path.Combine(outDir, "tab-anchor-raw.json"),
                JsonSerializer.Serialize(root, new JsonSerializerOptions { WriteIndented = true }), new UTF8Encoding(false));
            File.WriteAllText(Path.Combine(outDir, "tab-anchor-raw.txt"), human.ToString(), new UTF8Encoding(false));
            Console.WriteLine("cases: " + cases.Count);
            foreach (var o in intervalProbes) { var d = (Dictionary<string, object>)o; Console.WriteLine("probe " + d["case"] + " -> " + d["verdict"]); }
            return 0;
        }

        private static List<string> ChosenFor(Dictionary<string, string> map, string fam)
        {
            var l = new List<string>();
            foreach (var kv in map) if (kv.Value == fam) l.Add(kv.Key);
            return l;
        }

        private static List<object> IndentArmTable()
        {
            var l = new List<object>();
            foreach (var a in AllIndentArms)
                l.Add(new Dictionary<string, object> { ["arm"] = a.Id, ["Indent"] = a.Indent, ["ParagraphIndent"] = a.ParagraphIndent, ["FirstLineInParagraph"] = a.FirstLine, ["note"] = a.Note });
            return l;
        }

        private static string ScriptOf(string text)
        {
            foreach (char ch in text)
            {
                if (ch >= '\u0590' && ch <= '\u05FF') return "hebrew";
                if (ch >= '\u0600' && ch <= '\u06FF') return "arabic";
            }
            return "latin";
        }

        /// <summary>Advance width of one code point measured on its own in a 1000-DIP paragraph (direction check).</summary>
        private static double Advance(TextFormatter f, string s, FlowDirection flow, string font)
        {
            var props = new Props(new Typeface(font), EmSize);
            var para = new Para(props, flow, I0, false);
            var src = new StringSource(s, props);
            var line = f.FormatLine(src, 0, 1000.0, para, null);
            var b = line.GetTextBounds(0, 1);
            if (b == null || b.Count == 0) return double.NaN;
            return b[0].Rectangle.Width;
        }

        /// <summary>Measures the interval from a probe case: the distance between the two reached stops of two ADJACENT tabs.</summary>
        private static Dictionary<string, object> DescribeIntervalProbe(Dictionary<string, object> rec, double intervalRule)
        {
            string id = (string)rec["id"];
            bool tabZero = (string)rec["incrementalTabArm"] == "DefaultIncrementalTab=0";
            var tabs = new List<(double x, double w, int line)>();
            foreach (var lo in (List<object>)rec["lines"])
            {
                var L = (Dictionary<string, object>)lo;
                foreach (var po in (List<object>)L["perChar"])
                {
                    var p = (Dictionary<string, object>)po;
                    if ((string)p["char"] == "\t" && p["xFromLeftDip"] != null)
                        tabs.Add(((double)p["xFromLeftDip"], (double)p["width"], (int)L["index"]));
                }
            }
            var row = new Dictionary<string, object> { ["case"] = id, ["flow"] = rec["flowDirection"], ["arm"] = rec["incrementalTabArm"], ["tabCount"] = tabs.Count };
            if (tabZero) { row["verdict"] = "tab0 arm: no grid, skipped"; return row; }
            if (tabs.Count < 2) { row["verdict"] = "MEASUREMENT FAILED: fewer than 2 tab runs with geometry on this case"; return row; }
            tabs.Sort((a, b) => a.x.CompareTo(b.x));
            double dLeft = Math.Abs(tabs[1].x - tabs[0].x);
            double dRight = Math.Abs((tabs[1].x + tabs[1].w) - (tabs[0].x + tabs[0].w));
            row["deltaBetweenTabLeftEdgesDip"] = R(dLeft);
            row["deltaBetweenTabRightEdgesDip"] = R(dRight);
            row["agree"] = Math.Abs(dLeft - dRight) < 1e-9;
            row["intervalRule4xEmSize"] = R(intervalRule);
            row["matchesRule"] = Math.Abs(dLeft - intervalRule) < 1e-6 && Math.Abs(dRight - intervalRule) < 1e-6;
            row["verdict"] = "both edge deltas reported; the delta that repeats across every probe is the interval, the " +
                             "other one is (interval - width of the first tab run) by construction. left=" + F(dLeft) + " right=" + F(dRight);
            return row;
        }

        private static Dictionary<string, object> Measure(TextFormatter formatter, string group, string textId, string text, string note,
            double width, FlowDirection flow, IndentArm indentArm, bool tabZero, Dictionary<string, string> fontByScript, StringBuilder human)
        {
            string script = ScriptOf(text);
            string font = fontByScript[script];
            string fontSha = null, fontUri = null;
            if (new Typeface(font).TryGetGlyphTypeface(out GlyphTypeface gt)) { fontUri = gt.FontUri.ToString(); if (gt.FontUri.IsFile) fontSha = Sha256(gt.FontUri.LocalPath); }

            var props = new Props(new Typeface(font), EmSize);
            var para = new Para(props, flow, indentArm, tabZero);
            var source = new StringSource(text, props);

            var lines = new List<object>();
            var lineIndents = new List<double>();
            int index = 0;
            TextLineBreak brk = null;
            int guard = 0;
            bool stoppedEarly = false;
            while (index < text.Length && guard++ < 64)
            {
                TextLine line = formatter.FormatLine(source, index, width, para, brk);
                lines.Add(DescribeLine(line, text, flow, index, lines.Count));
                lineIndents.Add(R(line.Start));
                brk = line.GetTextLineBreak();
                if (line.Length <= 0) { stoppedEarly = true; break; }
                index += line.Length;
            }

            // ids are prefixed with the block/group so that a case id is unique across the whole document
            // (two blocks may legitimately re-measure the same text at the same width with different arms).
            string id = group + "/" + textId + "@w" + width.ToString("0", CultureInfo.InvariantCulture) +
                        "@" + (flow == FlowDirection.RightToLeft ? "RTL" : "LTR") +
                        "@" + indentArm.Id + "@" + (tabZero ? "tab0" : "default");
            var rec = new Dictionary<string, object>
            {
                ["id"] = id,
                ["group"] = group,
                ["textId"] = textId,
                ["text"] = text,
                ["note"] = note,
                ["paragraphWidthDip"] = width,
                ["emSizeDip"] = EmSize,
                ["flowDirection"] = flow == FlowDirection.RightToLeft ? "RightToLeft" : "LeftToRight",
                ["indentArm"] = indentArm.Id,
                ["indentDip"] = indentArm.Indent,
                ["paragraphIndentDip"] = indentArm.ParagraphIndent,
                ["firstLineInParagraph"] = indentArm.FirstLine,
                ["incrementalTabArm"] = tabZero ? "DefaultIncrementalTab=0" : "DefaultIncrementalTab=default",
                ["fontFamily"] = font, ["fontUri"] = fontUri, ["fontSha256"] = fontSha, ["script"] = script, ["dpi"] = Dpi,
                ["textWrapping"] = "Wrap",
                ["lineCount"] = lines.Count,
                ["tabCount"] = CountTabs(text),
                ["stoppedEarlyBecauseLineLengthWasZero"] = stoppedEarly,
                ["lineStartOffsetsDip"] = lineIndents,
                ["lines"] = lines,
            };
            if (human != null)
            {
                human.AppendLine($"== [{id}] \"{Esc(text)}\"   group={group}  indent={indentArm.Indent} paraIndent={indentArm.ParagraphIndent} firstLine={indentArm.FirstLine}");
                foreach (var o in lines)
                {
                    var L = (Dictionary<string, object>)o;
                    human.AppendLine($"   line {L["index"]}: [{L["startChar"]},{L["endCharExclusive"]}) nl={L["newlineLength"]} " +
                                     $"trailWs={L["trailingWhitespaceLength"]} w={F((double)L["width"])} witw={F((double)L["widthIncludingTrailingWhitespace"])} " +
                                     $"ovf={L["hasOverflowed"]} start={F((double)L["paragraphStartOffsetDip"])} cause={L["breakCause"]}  \"{Esc((string)L["lineText"])}\"");
                    // per-char geometry is dumped only for lines that actually carry a tab (the rest is in the JSON)
                    if (((string)L["lineText"]).Contains("\t"))
                        foreach (var po in (List<object>)L["perChar"])
                        {
                            var p = (Dictionary<string, object>)po;
                            human.AppendLine($"        i={p["i"]} '{Esc((string)p["char"])}' xFromLeft={F((double)p["xFromLeftDip"])} w={F((double)p["width"])}");
                        }
                }
                if (stoppedEarly) human.AppendLine("   !! stopped early: FormatLine returned a zero-length line (would be an infinite loop)");
            }
            return rec;
        }

        private static Dictionary<string, object> DescribeLine(TextLine line, string text, FlowDirection flow, int lineStart, int lineIndex)
        {
            // NOTE: TextLine.Start is a DOUBLE distance ("distance from paragraph start to line start", in DIPs),
            // NOT a character index - casting it to int silently yields 0 and slices the wrong text.
            int len = (int)line.Length;
            int textLen = len - (int)line.NewlineLength;
            if (lineStart + textLen > text.Length) textLen = Math.Max(text.Length - lineStart, 0);

            var perChar = new List<object>();
            for (int i = 0; i < textLen; i++)
            {
                int gi = lineStart + i;
                if (gi >= text.Length) break;
                IList<TextBounds> b = line.GetTextBounds(gi, 1);
                if (b == null || b.Count == 0)
                {
                    perChar.Add(new Dictionary<string, object> { ["i"] = gi, ["char"] = text[gi].ToString(), ["xFromLeftDip"] = null, ["width"] = null });
                    continue;
                }
                perChar.Add(new Dictionary<string, object>
                {
                    ["i"] = gi,
                    ["char"] = text[gi].ToString(),
                    ["codePoint"] = "U+" + ((int)text[gi]).ToString("X4"),
                    ["x"] = R(b[0].Rectangle.X),
                    ["width"] = R(b[0].Rectangle.Width),
                    ["flowDirection"] = b[0].FlowDirection.ToString(),
                });
            }
            double inkRight = 0;
            foreach (var o in perChar) { var d = (Dictionary<string, object>)o; if (d["x"] != null) { double r = (double)d["x"] + (double)d["width"]; if (r > inkRight) inkRight = r; } }
            foreach (var o in perChar)
            {
                var d = (Dictionary<string, object>)o;
                if (d["x"] == null) continue;
                double raw = (double)d["x"], w = (double)d["width"];
                d["xFromLeftDip"] = R(flow == FlowDirection.RightToLeft ? inkRight - (raw + w) : raw);
            }

            // DERIVED break cause (WPF exposes none): look at the last character kept and the first dropped.
            int lastKept = lineStart + textLen - 1;
            int firstDropped = lineStart + textLen;
            string cause;
            if (firstDropped >= text.Length) cause = "end-of-text";
            else if (textLen == 0) cause = "empty-line";
            else if (text[firstDropped] == '\n') cause = "explicit-newline";
            else if (lastKept >= 0 && text[lastKept] == '\t') cause = "after-tab";
            else if (text[firstDropped] == '\t') cause = "before-tab";
            else if (lastKept >= 0 && text[lastKept] == ' ') cause = "at-space";
            else cause = "mid-token";

            return new Dictionary<string, object>
            {
                ["index"] = lineIndex,
                ["paragraphStartOffsetDip"] = R(line.Start),
                ["startChar"] = lineStart,
                ["endCharExclusive"] = lineStart + textLen,
                ["lengthWithNewline"] = len,
                ["dependentLength"] = (int)line.DependentLength,
                ["newlineLength"] = (int)line.NewlineLength,
                ["trailingWhitespaceLength"] = (int)line.TrailingWhitespaceLength,
                ["width"] = R(line.Width),
                ["widthIncludingTrailingWhitespace"] = R(line.WidthIncludingTrailingWhitespace),
                ["height"] = R(line.Height),
                ["baseline"] = R(line.Baseline),
                ["hasOverflowed"] = line.HasOverflowed,
                ["inkRightDip"] = R(inkRight),
                ["lineText"] = SafeSlice(text, lineStart, textLen),
                ["breakCause"] = cause,
                ["breakCauseNote"] = "DERIVED from the characters around the break, not reported by WPF",
                ["perChar"] = perChar,
            };
        }

        private static int CountTabs(string s) { int n = 0; foreach (char c in s) if (c == '\t') n++; return n; }
        private static string SafeSlice(string s, int start, int len)
        {
            if (start < 0 || start > s.Length || len <= 0) return "";
            if (start + len > s.Length) len = s.Length - start;
            return s.Substring(start, len);
        }
        private static string Esc(string s) => s == null ? "" : s.Replace("\t", "\\t").Replace("\n", "\\n");
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

/// <summary>One Indent / ParagraphIndent / FirstLineInParagraph combination (top-level so Para can use it).</summary>
internal sealed class IndentArm
{
    public string Id; public double Indent; public double ParagraphIndent; public bool FirstLine; public string Note;
    public IndentArm(string id, double indent, double paraIndent, bool firstLine, string note)
    { Id = id; Indent = indent; ParagraphIndent = paraIndent; FirstLine = firstLine; Note = note; }
}

    internal sealed class StringSource : TextSource
    {
        private readonly string _text;
        private readonly TextRunProperties _props;
        public StringSource(string text, TextRunProperties props) { _text = text; _props = props; }
        public override TextRun GetTextRun(int index)
            => index < _text.Length ? (TextRun)new TextCharacters(_text, index, _text.Length - index, _props) : new TextEndOfParagraph(1);
        public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int limit)
        {
            int len = Math.Min(Math.Max(limit, 0), _text.Length);
            return new TextSpan<CultureSpecificCharacterBufferRange>(len,
                new CultureSpecificCharacterBufferRange(CultureInfo.CurrentCulture, new CharacterBufferRange(_text, 0, len)));
        }
        public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int i) => i;
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

    /// <summary>Mirrors layout-b34's TextModel; the ONLY differences between arms are Indent/ParagraphIndent/FirstLineInParagraph and DefaultIncrementalTab.</summary>
    internal sealed class Para : TextParagraphProperties
    {
        private readonly bool _tabZero;
        private readonly double _indent, _paraIndent;
        private readonly bool _firstLine;
        public Para(TextRunProperties props, FlowDirection flow, IndentArm arm, bool tabZero)
        { DefaultTextRunProperties = props; FlowDirection = flow; _tabZero = tabZero; _indent = arm.Indent; _paraIndent = arm.ParagraphIndent; _firstLine = arm.FirstLine; }
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
        public override double DefaultIncrementalTab => _tabZero ? 0 : base.DefaultIncrementalTab;
    }
}

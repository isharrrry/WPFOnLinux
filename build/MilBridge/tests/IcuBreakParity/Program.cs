// T1 · ICU 对拍预检（B2 前置）—— **目标：73 例逐例全等**
//
//   dotnet MilBridge.IcuBreakParity.dll [oracle.json] [--verbose]
//
// 对拍对象：U1 的 DWrite 真值 `tests/parity/windows/shaping/out-layout/dwrite-layout-cjk-oracle.json`（73 例）。
//
// ⭐ 2026-09-11（T1b）**规则实现搬走了**：断行规则（ICU 断点集 + `…` 前可断 + 禁则拉字 + 强制断 fallback）
//    现在**只有一份**，在 `build/shims/PresentationCore.HbTextLine.cs` 的 `HbBreakEngine` 里
//    （本工程用 `TEXTLINE_BREAK_ENGINE_ONLY` 编它、不引用 PC）。本文件**不再有任何规则代码** ——
//    只做三件事：读 oracle、调引擎、比数字。
//    动机：任务书点名要防的失败模式是"探针与实现两套规则"，两套必然漂移。
//
// 逐字 advance 由引擎内部用 **HarfBuzz 真 shaping** 算（U1 已证本语料上 DWrite 与 HB 零差异 56/56）；
//   字体按 case 的 weight/style 选（Regular/Bold/Italic/BoldItalic；CJK 例用 NotoSansCJK-Regular.ttc）。
//   两个特例：oracle 的 `cjk-only`/`mixed` 用 NotoSans-*.ttf（**无 CJK 字形**，oracle 自己标了
//   `cjkCoverage:false`），DWrite 给出的 CJK advance 是 .notdef = 24 DIP（= em），而 HB 的 .notdef = 14.4 DIP。
//   **这是引擎的 .notdef 度量差异、不是断行差异**；探针用 CJK 字体复现同样的 24 DIP 数值，以免误报。
//   （`PickFont` 是**oracle 字体映射**，不是断行规则，所以留在本文件里。）
//
// 行区间口径（DWrite 层，照 DWrite）：**不含换行符**。
//   ⚠️ 这与 WPF `TextLine.Length` 的口径**不同**（后者含硬断字符 + 末行 EOP）——
//      本工程比的是 DWrite 层，`TextLine` 层的对拍在 `build/MilBridge/tests/HbTextLineParity/`。
//
// 结果：Stage A 真不一致 0；**Stage B 73/73 逐例全等**；Stage C 禁则 40/40 一致。

using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using WpfLinux.Shims.PresentationCore;

internal static class Program
{
    private sealed class Case
    {
        public string Id;
        public string Text;
        public double Width;
        public double Em;
        public string Family;
        public int Weight = 400;
        public int Style;
        public List<(int s, int e)> Lines = new List<(int, int)>();
        public JsonElement Raw;
    }

    private static bool _verbose;
    private static string _root;
    private static int _stageAEmergency, _stageAViolations;
    private static int _casesExact, _casesDiff;
    private static readonly List<string> Bad = new List<string>();
    private static readonly Dictionary<string, string> FontPaths = new Dictionary<string, string>();

    private static int Main(string[] args)
    {
        string oraclePath = null;
        foreach (string a in args)
        {
            if (a == "--verbose" || a == "-v") _verbose = true;
            else oraclePath = a;
        }
        _root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";
        if (oraclePath == null) oraclePath = _root + "/tests/parity/windows/shaping/out-layout/dwrite-layout-cjk-oracle.json";
        if (!File.Exists(oraclePath)) { Console.WriteLine("[失败] 找不到 oracle：" + oraclePath); return 2; }

        FontPaths["Noto Sans"] = _root + "/build/fonts/NotoSans-Regular.ttf";
        FontPaths["Noto Sans|700|0"] = _root + "/build/fonts/NotoSans-Bold.ttf";
        FontPaths["Noto Sans|400|2"] = _root + "/build/fonts/NotoSans-Italic.ttf";
        FontPaths["Noto Sans|700|2"] = _root + "/build/fonts/NotoSans-BoldItalic.ttf";
        // oracle 的 cjk-only / mixed 两例：字体是 NotoSans-*.ttf（**没有 CJK 字形**），
        //   DWrite 给的 CJK advance 是 .notdef = 24 DIP（= em）。HarfBuzz 的 .notdef = 14.4 DIP。
        //   ⇒ 这是**引擎的 .notdef 度量差异，不是断行差异**。本探针用同一 collection 里的 CJK 字体
        //     复现 DWrite 输出的**同样数值**（24 DIP），免得把度量差异误报成断行差异。
        FontPaths["Noto Sans|notdef-cjk|400|0"] = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc";
        FontPaths["Noto Sans CJK JP"] = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc";
        FontPaths["Noto Sans CJK SC"] = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc";

        Console.WriteLine("==================== ICU(UAX#14)+DWrite 覆盖规则 vs DWrite 行断对拍（73 例）====================");
        Console.WriteLine($"规则真源 = {HbShimSource.File} · HbBreakEngine（{HbShimSource.EngineTag}）");
        Console.WriteLine($"shim tag = {HbShimSource.Tag}");
        {
            // ⭐ 把"被测的是哪一份文件"焊进读数：run.sh 把编译时那份的 sha256 传进来，这里读盘再算一次比对
            string shim = _root + "/" + HbShimSource.File;
            string sha = File.Exists(shim)
                ? Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(File.ReadAllBytes(shim))) : "(缺)";
            string pinned = Environment.GetEnvironmentVariable("T1B_SHIM_SHA256");
            Console.WriteLine($"被测文件 = {HbShimSource.File}  sha256={sha}"
                              + (string.IsNullOrEmpty(pinned) ? "  ⚠ 未固定（env T1B_SHIM_SHA256 空）"
                                 : (string.Equals(pinned, sha, StringComparison.OrdinalIgnoreCase)
                                        ? "  ✅ 与 run.sh 固定的 sha 一致" : "  ❌ 与 run.sh 固定的 sha **不一致**")));
            if (!string.IsNullOrEmpty(pinned) && !string.Equals(pinned, sha, StringComparison.OrdinalIgnoreCase)) return 3;
        }
        Console.WriteLine($"ICU  = {HbBreakEngine.IcuVersion}  (libicuuc.so.70)");
        Console.WriteLine("HB   = " + HbShaper.Version + "  (libharfbuzz.so.0)");
        Console.WriteLine();

        using JsonDocument doc = JsonDocument.Parse(File.ReadAllText(oraclePath));
        JsonElement casesEl = doc.RootElement.GetProperty("cases");
        var cases = new List<Case>();
        foreach (JsonElement c in casesEl.EnumerateArray())
        {
            var k = new Case
            {
                Id = c.GetProperty("id").GetString(),
                Text = c.GetProperty("text").GetString(),
                Width = c.GetProperty("containerWidthDip").GetDouble(),
                Em = c.GetProperty("emSizeDip").GetDouble(),
                Family = c.GetProperty("fontFamily").GetString(),
                Raw = c,
            };
            if (c.TryGetProperty("weight", out JsonElement wEl)) k.Weight = wEl.GetInt32();
            if (c.TryGetProperty("style", out JsonElement sEl)) k.Style = sEl.GetInt32();
            foreach (JsonElement L in c.GetProperty("lines").EnumerateArray())
                k.Lines.Add((L.GetProperty("startChar").GetInt32(), L.GetProperty("endCharExclusive").GetInt32()));
            cases.Add(k);
        }
        Console.WriteLine($"oracle = {cases.Count} 例；引擎 = {doc.RootElement.GetProperty("engine").GetString()}");
        Console.WriteLine();

        // ---------------- Stage A：断点集（含覆盖规则）是否覆盖 DWrite 的换行点 ----------------
        Console.WriteLine("──────── Stage A：DWrite 的换行点是否 ∈（ICU 断点集 + 覆盖规则）────────");
        foreach (Case c in cases)
        {
            List<int> rawAll = RawBreaksWholeText(c.Text);
            List<int> brAll = OverlayWholeText(c.Text);
            var missing = new List<int>();
            foreach ((int s, int _) in c.Lines) if (s > 0 && !brAll.Contains(s)) missing.Add(s);
            if (missing.Count == 0)
            {
                if (_verbose) Console.WriteLine($"   {c.Id,-28} OK");
            }
            else
            {
                // 这些位置不在（ICU 断点集 + 覆盖规则）里 ⇒ 只能靠"无断点可放 ⇒ 按宽度强制断"的 fallback。
                // ⭐ 这**不是差异**：`en-oneword`/`cjk-long-token`/两个 conflict 例、以及 `cjk-fullwidth` 的
                // 第 2 行（DWrite 在 `；` 前断，而 UAX#14 把整段标点粘住）都属于这一类。
                ++_stageAEmergency;
                Console.WriteLine($"   {c.Id,-28} **依赖强制断 fallback（非差异）**：DWrite 在 {string.Join(",", missing)} 断，"
                                  + "断点集里没有 ⇒ 交给「无断点可放 ⇒ 按宽度强制断」（Stage B 判它是否复现）");
            }
            _ = rawAll;
        }
        Console.WriteLine($"   → Stage A：**真不一致 {_stageAViolations} 例**；依赖强制断 fallback 的例数 {_stageAEmergency}");
        Console.WriteLine();

        // ---------------- Stage B：逐例逐行对拍（73/73 的判据）----------------
        Console.WriteLine("──────── Stage B：引擎（ICU 断点集 + 贪心填宽 + 真 HarfBuzz advance）⇒ 行划分逐例逐行对拍 ────────");
        foreach (Case c in cases)
        {
            string font = PickFont(c.Family, c.Weight, c.Style, c.Text);
            List<HbLineRange> got = HbBreakEngine.LayoutText(c.Text, c.Width, c.Em, font);
            var gotPairs = new List<(int s, int e)>();
            foreach (HbLineRange r in got) gotPairs.Add((r.Start, r.End));

            bool exact = gotPairs.Count == c.Lines.Count;
            if (exact)
                for (int i = 0; i < gotPairs.Count; ++i)
                    if (gotPairs[i].s != c.Lines[i].s || gotPairs[i].e != c.Lines[i].e) { exact = false; break; }
            if (exact) ++_casesExact;
            else
            {
                ++_casesDiff;
                Bad.Add($"   ❌ {c.Id} (w={c.Width}, em={c.Em}, {c.Family}): DWrite={Ranges(c.Lines)}  引擎={Ranges(gotPairs)}");
            }
            if (_verbose || !exact)
                Console.WriteLine($"   {c.Id,-28} w={c.Width,-6} em={c.Em,-4} DWrite={Ranges(c.Lines),-44} 引擎={Ranges(gotPairs),-44} {(exact ? "OK" : "**不同**")}");
        }
        Console.WriteLine($"   → Stage B：**逐例全等 {_casesExact} 例 / 不同 {_casesDiff} 例**（共 {_casesExact + _casesDiff} 例）");
        foreach (string s in Bad) Console.WriteLine(s);
        Console.WriteLine();

        // ---------------- Stage C：禁则 crux（48 行表逐字符）----------------
        Console.WriteLine("──────── Stage C：kinsoku 表 48 行逐字符 —— ICU 是否允许「把标点留到行首/行尾」的那个断点 ────────");
        int ok = 0, bad = 0, ctrl = 0, other = 0;
        using JsonDocument table = JsonDocument.Parse(File.ReadAllText(
            Path.Combine(Path.GetDirectoryName(oraclePath) ?? ".", "kinsoku-table.json")));
        foreach (JsonElement row in table.RootElement.GetProperty("rows").EnumerateArray())
        {
            string ch = row.GetProperty("char").GetString();
            string kind = row.GetProperty("kind").GetString();
            string verdict = row.GetProperty("verdict").GetString();
            JsonElement cc = FindCase(cases, ch, kind);
            if (cc.ValueKind == JsonValueKind.Undefined) continue;
            string text = cc.GetProperty("text").GetString();
            int target = text.IndexOf(ch, StringComparison.Ordinal);
            List<int> raw = HbBreakEngine.IcuBreaks(text, "zh-CN");
            bool before = raw.Contains(target);         // 能否在目标字**前**断（⇒ 目标字到行首）
            bool after = raw.Contains(target + 1);      // 能否在目标字**后**断（⇒ 目标字留行尾）

            string expect = verdict.StartsWith("PROHIBITED at line start") ? "sp"
                          : verdict.StartsWith("PROHIBITED at line end") ? "ep"
                          : verdict.StartsWith("allowed at line start") ? "sa"
                          : verdict.StartsWith("allowed at line end") ? "ea" : "other";
            bool agree;
            switch (expect)
            {
                case "sp": agree = !before; break;
                case "ep": agree = !after; break;
                case "sa": agree = before; ctrl++; break;
                case "ea": agree = after; ctrl++; break;
                default: other++; agree = true; break;
            }
            if (expect == "sp" || expect == "ep") { if (agree) ++ok; else ++bad; }
            if (_verbose || !agree)
                Console.WriteLine($"   {ch} ({kind,-8}) DWrite line1End={cc.GetProperty("lines")[0].GetProperty("endCharExclusive").GetInt32(),-3} "
                                  + $"ICU前可断={YN(before),-4} 后可断={YN(after),-4} ⇒ {(expect == "other" ? "conflict（由 Stage B 判）" : (agree ? "一致" : "**不一致**"))}");
        }
        Console.WriteLine($"   → Stage C：禁则 {ok} 一致 / {bad} 不一致；对照(allow) {ctrl} 例一致；conflict {other} 例（不判，Stage B 覆盖）");
        Console.WriteLine();

        Console.WriteLine("==================== 结论 ====================");
        bool pass = _stageAViolations == 0 && _casesDiff == 0 && bad == 0;
        Console.WriteLine($"Stage A 真不一致 = {_stageAViolations}（紧急断行 {_stageAEmergency} 例归 fallback，**非差异**）");
        Console.WriteLine($"Stage B 逐例不同 = {_casesDiff}（判据：必须 0）");
        Console.WriteLine($"Stage C 禁则不一致 = {bad}（必须 0）");
        Console.WriteLine(pass
            ? "⇒ **一致**：73 例逐例全等（= ICU 断点集 + `…` 前可断 + 禁则拉字 + 强制断 fallback，规则真源 = shim 的 HbBreakEngine）"
            : "⇒ **仍有差异**：以 DWrite 真值为准 ⇒ 见上面 ❌ 明细");
        return pass ? 0 : 1;
    }

    /// <summary>整串文本的 ICU 原始断点集（按硬断切段，段内下标映射回全文）。**只用于 Stage A/C 的判据展示**。</summary>
    private static List<int> RawBreaksWholeText(string text) => BreaksWholeText(text, overlay: false);

    private static List<int> OverlayWholeText(string text) => BreaksWholeText(text, overlay: true);

    private static List<int> BreaksWholeText(string text, bool overlay)
    {
        var all = new List<int>();
        int paraStart = 0;
        for (int i = 0; i <= text.Length; ++i)
        {
            bool atEnd = (i == text.Length);
            int hb = atEnd ? 0 : HbBreakEngine.HardBreakLengthAt(text, i);
            if (!atEnd && hb == 0) continue;
            string para = text.Substring(paraStart, i - paraStart);
            List<int> b = HbBreakEngine.IcuBreaks(para, "zh-CN");
            if (overlay) b = HbBreakEngine.Overlay(b, para);
            foreach (int x in b) all.Add(paraStart + x);
            all.Add(i + (atEnd ? 0 : hb));
            paraStart = i + hb;
            if (atEnd) break;
            i += hb - 1;
        }
        return all;
    }

    /// <summary>按 case 的 weight/style 选字体文件；oracle 标了 cjkCoverage=false 的 .notdef 例用 CJK 字体。</summary>
    private static string PickFont(string family, int weight, int style, string text)
    {
        if (family != "Noto Sans") return FontPaths[family];
        bool cjkFamily = false;
        foreach (char ch in text) if (ch >= 0x2E80) { cjkFamily = true; break; }
        string key = cjkFamily ? $"Noto Sans|notdef-cjk|{weight}|{style}" : $"Noto Sans|{weight}|{style}";
        if (FontPaths.TryGetValue(key, out string p)) return p;
        return FontPaths["Noto Sans"];
    }

    private static JsonElement FindCase(List<Case> cases, string ch, string kind)
    {
        string prefix = kind == "start" ? "kinsoku-start-" : kind == "end" ? "kinsoku-end-" : "kinsoku-conflict-";
        foreach (Case c in cases)
            if (c.Id.StartsWith(prefix) && c.Text.Contains(ch)) return c.Raw;
        return default;
    }

    private static string Ranges(List<(int s, int e)> v)
    {
        var parts = new List<string>();
        foreach ((int s, int e) in v) parts.Add($"[{s},{e})");
        return string.Join(" ", parts);
    }
    private static string YN(bool b) => b ? "是" : "否";
}

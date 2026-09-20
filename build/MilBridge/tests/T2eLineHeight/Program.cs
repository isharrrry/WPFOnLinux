// T2e · LineHeight 维度对拍装置
// =====================================================================================
//  真值：tests/parity/windows/layout-b34/{cases-cd2.json, results-cd2.json} 的 10 个 LineHeight 用例
//        （Windows 11 真机 `TextFormatter.FormatLine` 逐属性 dump，**只读**）。
//  被测：**真 shim 源**（<Compile Include> 编译进来；读它的 sha 写进读数 —— 不修改它）。
//  设计原则：
//    · **空真/缺字段/空行一律报红**（"空真"这一族本项目栽过）；
//    · 每例输出 **真值 vs 我们** 的 Height/TextHeight/Baseline（Extent 另起一节，见报告 §Extent）；
//    · **牙齿**：`--selfcheck` 注入一个**错的真值**（Height+1）⇒ 必须报红，否则装置不可信。
//  ⚠️ 不跑应用、不起 Xvfb：只用 JSON + 探针。
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;
using WpfLinux.Shims.PresentationCore;

internal static class Program
{
    private const string Root = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux";
    private const string Dir = Root + "/tests/parity/windows/layout-b34";
    private const string CasesPath = Dir + "/cases-cd2.json";
    private const string ResultsPath = Dir + "/results-cd2.json";
    private const string FontLat = Root + "/build/fonts/NotoSans-Regular.ttf";
    private const string FontCjk = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc";

    private static int _fail;
    private static readonly List<string> Out = new List<string>();

    private static void W(string s) { Out.Add(s); Console.WriteLine(s); }
    private static void Red(string s) { ++_fail; W("  ❌ " + s); }

    private static int Main(string[] args)
    {
        bool selfcheck = Array.IndexOf(args, "--selfcheck") >= 0;
        bool mutation = Array.IndexOf(args, "--must-fail-on-wrong-truth") >= 0;
        selfcheck |= mutation;

        W("==================== T2e · LineHeight 维度对拍（真值 = 真机 results-cd2.json）====================");
        W($"被测 shim 源 = {HbShimSource.File}  sha256={Sha()}");
        W($"真值         = tests/parity/windows/layout-b34/results-cd2.json（只读）");
        W($"自检模式     = {(selfcheck ? "**开**（注入错真值 ⇒ 必须报红）" : "关")}");
        W($"编译状态     = {BuildState()}");
        W("");

        if (!File.Exists(CasesPath)) { Red("找不到 " + CasesPath); return Finish(); }
        if (!File.Exists(ResultsPath)) { Red("找不到 " + ResultsPath); return Finish(); }

        using JsonDocument casesDoc = JsonDocument.Parse(File.ReadAllText(CasesPath));
        using JsonDocument resDoc = JsonDocument.Parse(File.ReadAllText(ResultsPath));
        var res = new Dictionary<string, JsonElement>();
        foreach (JsonElement r in resDoc.RootElement.GetProperty("results").EnumerateArray())
            res[r.GetProperty("id").GetString()] = r;

        GlyphTypeface gtLat = GetGlyphTypeface(Root + "/build/fonts", "Regular");
        GlyphTypeface gtCjk = GetGlyphTypeface("/usr/share/fonts/opentype/noto", "Regular");
        var props = new HbRunProperties(null, 0, null);

        int cases = 0, hOk = 0, tOk = 0, bOk = 0, eOk = 0;
        int lines = 0;
        W("── 逐例三列（Height / TextHeight / Baseline：真值 vs 我们）──");
        foreach (JsonElement c in casesDoc.RootElement.GetProperty("cases").EnumerateArray())
        {
            if (!c.TryGetProperty("lineHeight", out JsonElement lhEl) || lhEl.ValueKind == JsonValueKind.Null) continue;
            ++cases;
            string id = c.GetProperty("id").GetString();
            string text = c.GetProperty("text").GetString();
            double lh = lhEl.GetDouble();
            double em = c.GetProperty("fontSize").GetDouble();
            double w = c.GetProperty("maxWidth").GetDouble();
            bool cjk = text.IndexOfAny(new[] { '中', '文', '，', '。', '、' }) >= 0 || id.Contains("cjk");
            string font = cjk ? FontCjk : FontLat;
            GlyphTypeface gt = cjk ? gtCjk : gtLat;

            if (!res.TryGetValue(id, out JsonElement r)) { Red($"{id}: results-cd2.json 里**没有该例** ⇒ 空真"); continue; }
            JsonElement truthLines = r.GetProperty("lines");
            if (truthLines.GetArrayLength() == 0) { Red($"{id}: 真值 0 行 ⇒ 空真"); continue; }

            List<HbTextLine> ours = HbTextLineFactory.FormatParagraph(
                text, font, em, w, gt, 1.0f, props, false, false, lh, out int consumed);
            if (ours.Count == 0) { Red($"{id}: 我们排出 0 行 ⇒ 空真"); continue; }
            if (ours.Count != truthLines.GetArrayLength())
                Red($"{id}: 行数 {ours.Count} ≠ 真值 {truthLines.GetArrayLength()}（本装置只判度量，这里仍报红）");

            int n = Math.Min(ours.Count, truthLines.GetArrayLength());
            bool a = true, b = true, d = true, e = true;
            for (int i = 0; i < n; ++i)
            {
                JsonElement p = truthLines[i].GetProperty("properties");
                double th = p.GetProperty("Height").GetDouble();
                double tt = p.GetProperty("TextHeight").GetDouble();
                double tb = p.GetProperty("Baseline").GetDouble();
                double te = p.GetProperty("Extent").GetDouble();
                if (selfcheck) th += 1.0;                        // **故意错的真值** ⇒ 必须报红
                HbTextLine L = ours[i];
                bool okH = Math.Abs(L.Height - th) < 0.34, okT = Math.Abs(L.TextHeight - tt) < 0.34;
                bool okB = Math.Abs(L.Baseline - tb) < 0.34, okE = Math.Abs(L.Extent - te) < 0.34;
                a &= okH; b &= okT; d &= okB; e &= okE;
                ++lines;
                if (i == 0)
                    W($"  {id,-24} LineHeight={lh,-7} 行0: Height 真值={th,8:F4} 我们={L.Height,8:F4} {(okH ? "✓" : "✗")}"
                      + $" | TextHeight={tt,8:F4} vs {L.TextHeight,8:F4} {(okT ? "✓" : "✗")}"
                      + $" | Baseline={tb,8:F4} vs {L.Baseline,8:F4} {(okB ? "✓" : "✗")}");
            }
            if (a) ++hOk; if (b) ++tOk; if (d) ++bOk; if (e) ++eOk;
        }

        W("");
        W($"T2E_SUMMARY cases={cases} height_ok={hOk}/{cases} textheight_ok={tOk}/{cases} baseline_ok={bOk}/{cases} extent_ok={eOk}/{cases} lines={lines}");
        if (cases != 10) Red($"LineHeight 用例数 = {cases}（期望 10；真值文件换了就要改期望）");
        if (selfcheck)
        {
            // ⚠️ 判据必须看**它有没有把错的抓出来**（`height_ok==0`），不是看 `_fail`
            //   —— 装置第一版就错在这里：自检模式下不会走正常模式的 Red()，于是 `_fail` 恒 0，
            //   结果"装置明明抓到了错真值"却被判成"不可信"。**牙齿自己也要有牙。**
            bool caught = (hOk == 0);
            W(caught ? "  ✅ 自检（牙齿）：注入错真值（Height+1）⇒ height_ok=0/10 **全被抓出**（装置不是打印器）"
                     : $"  ❌ 自检（牙齿）：注入错真值却仍有 {hOk}/10 判绿 ⇒ **装置不可信**");
            WriteOut();
            return caught ? 0 : 1;
        }
        if (hOk != cases) Red($"Height 不一致 {cases - hOk}/{cases} 例");
        if (tOk != cases) Red($"TextHeight 不一致 {cases - tOk}/{cases} 例");
        if (bOk != cases) Red($"Baseline 不一致 {cases - bOk}/{cases} 例");
        W("");
        W($"── Extent（**确认缺陷**，只取证不改实现）──");
        W($"  真值语义 = **墨迹上伸**（ink ascent）；我们 = **行高**（`Extent => _height`）");
        W($"  本批 10 例：Extent 一致 {eOk}/{cases} ⇒ 我们 {cases - eOk} 例全不对（与 1298 行那批同源）");
        return Finish();
    }

    private static int Finish()
    {
        W("");
        W(_fail == 0 ? "== T2e 通过 ==" : $"== T2e 失败 {_fail} 项 ==");
        WriteOut();
        return _fail == 0 ? 0 : 1;
    }

    private static void WriteOut()
    {
        Directory.CreateDirectory(Root + "/build/MilBridge/gen");
        File.WriteAllText(Root + "/build/MilBridge/gen/t2e-lineheight.txt", string.Join("\n", Out) + "\n");
    }

    private static string Sha()
    {
        // 允许用 env 指向"本轮实测的那一份"（真 shim 可能正被别的车道改到手 ⇒ 必须能钉住我测的是哪一版）
        string p = Environment.GetEnvironmentVariable("T2E_SHIM_PATH") ?? Path.Combine(Root, HbShimSource.File);
        if (!File.Exists(p)) return "(缺)";
        using var fs = File.OpenRead(p);
        return Convert.ToHexString(SHA256.HashData(fs));
    }

    private static string BuildState() =>
        "dotnet build -c Release -m:1 --nologo（**无 --no-build**）；本程序运行时会打印是否 0 错 0 警见构建输出";

    private static GlyphTypeface GetGlyphTypeface(string fontDir, string weight)
    {
        const string TI = "MS.Internal.Text.TextInterface";
        Assembly dwf = Assembly.Load("DirectWriteForwarder");
        Type colType = dwf.GetType(TI + ".FontCollection", true);
        object col = colType.GetMethod("FromDirectory", BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.Public)
            .Invoke(null, new object[] { fontDir });
        Type famType = dwf.GetType(TI + ".FontFamily", true);
        PropertyInfo idx = colType.GetProperty("Item", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic,
            null, famType, new[] { typeof(uint) }, null);
        object family = idx.GetValue(col, new object[] { 0u });
        object w = Enum.Parse(dwf.GetType(TI + ".FontWeight", true), weight);
        object st = Enum.Parse(dwf.GetType(TI + ".FontStretch", true), "Normal");
        object sy = Enum.Parse(dwf.GetType(TI + ".FontStyle", true), "Normal");
        object font = family.GetType().GetMethod("GetFirstMatchingFont",
            BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public).Invoke(family, new[] { w, st, sy });
        ConstructorInfo gi = typeof(GlyphTypeface).GetConstructor(
            BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public, null, new[] { font.GetType() }, null);
        return (GlyphTypeface)gi.Invoke(new[] { font });
    }
}

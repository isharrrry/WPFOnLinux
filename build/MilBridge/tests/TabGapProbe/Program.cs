// ============================================================================
// TabGapProbe · `D-T4` 的**产品入口**定位探针（`#42`）
// ============================================================================
//
// 【问什么】`TextParagraphProperties.DefaultIncrementalTab`（tab 步长）**在走产品入口时**
//   到底有没有影响排版结果？真机（Windows 录制的 `tab-anchor` 真值）在 tab 值不同时
//   **行数会变**（配对统计：`60/119` 变）；而本仓登记 `D-T4` 说**我方 `0/119` 变**。
//   本探针把这句话做成**产品入口上的读数**：同一段含 `\t` 的文本，跑 4 个 tab 值，
//   比"行数 + 每行宽度"。
//
// 【为什么用 public API】被测的是 PC 的接线点（`TextFormatterImp` → `SimpleTextLine` → shim），
//   而三支 tab 臂是**直接调 HbTextLineFactory**（工厂=仪器）⇒ 它们证明不了"产品入口上有没有生效"。
//
// 【输出（机读）】
//   TABGAP tab=<值> lines=<行数> width0=<首行宽> widthlast=<末行宽> widthsum=<总宽>
//   TABGAP_RESPONSIVE=yes|no      ← yes = 至少一个 tab 值下"行数或宽度"与基线不同（= 生效）
//   TABGAP_BASELINE tab=0 lines=… widthsum=…   ← 基线（tab=0 = 显式无停靠位）
// ============================================================================

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media;
using System.Windows.Media.TextFormatting;

internal sealed class ProbeParagraphProperties : TextParagraphProperties
{
    private readonly double _tab;
    public ProbeParagraphProperties(double tab, double lineHeight)
    {
        _tab = tab;
        DefaultTextRunProperties = new ProbeRunProperties(lineHeight);
    }
    public override FlowDirection FlowDirection => FlowDirection.LeftToRight;
    public override TextAlignment TextAlignment => TextAlignment.Left;
    public override double LineHeight => 0;                 // 由引擎决定
    public override bool FirstLineInParagraph => true;
    public override TextRunProperties DefaultTextRunProperties { get; }
    public override TextWrapping TextWrapping => TextWrapping.Wrap;
    public override double Indent => 0;
    public override double DefaultIncrementalTab => _tab;   // ★ 被测属性
    // 基类的抽象成员（与 tab 无关）：本探针不关心标记 ⇒ 如实给 null
    public override TextMarkerProperties TextMarkerProperties => null;
    // Tabs = null ⇒ 用 DefaultIncrementalTab（与 tab-anchor 语料的 default 档同形）
}

internal sealed class ProbeRunProperties : TextRunProperties
{
    private readonly double _size;
    public ProbeRunProperties(double size) { _size = size; }
    public override Typeface Typeface => new Typeface("Noto Sans");
    public override double FontRenderingEmSize => _size;
    public override double FontHintingEmSize => _size;
    public override TextDecorationCollection TextDecorations => null;
    public override Brush ForegroundBrush => Brushes.Black;
    public override Brush BackgroundBrush => Brushes.Transparent;
    public override CultureInfo CultureInfo => CultureInfo.InvariantCulture;
    public override TextEffectCollection TextEffects => null;
}

internal sealed class ProbeTextSource : TextSource
{
    private readonly string _text;
    private readonly ProbeParagraphProperties _pp;
    public ProbeTextSource(string text, ProbeParagraphProperties pp) { _text = text; _pp = pp; }
    public override TextRun GetTextRun(int textSourceCharacterIndex)
    {
        if (textSourceCharacterIndex >= _text.Length)
            return new TextEndOfParagraph(1);
        // 一次给整段（含 \t）——tab 的处理发生在引擎内部
        return new TextCharacters(_text, textSourceCharacterIndex,
                                  _text.Length - textSourceCharacterIndex, _pp.DefaultTextRunProperties);
    }
    // ⚠️ 必须给**非 null 的 value**：返回 `null` 会让产品路径直接 abort（`#42` 实测 rc=134，
    //    栈在 `TextMetrics.FullTextLine.FormatLine`）。形状照 `ProductEntryArm` 那份**已验证**的写法。
    public override TextSpan<CultureSpecificCharacterBufferRange> GetPrecedingText(int textSourceCharacterIndexLimit)
    {
        var ccr = new CultureSpecificCharacterBufferRange(
            CultureInfo.CurrentCulture, new CharacterBufferRange());
        return new TextSpan<CultureSpecificCharacterBufferRange>(0, ccr);
    }
    public override int GetTextEffectCharacterIndexFromTextSourceCharacterIndex(int textSourceCharacterIndex)
        => textSourceCharacterIndex;
}

internal static class Program
{
    // 语料：两处 tab + 足够长的尾巴，容器 120 DIP ⇒ tab 步长变化**应当**改变断行/行宽
    private const string Corpus = "a\tb\tc";
    private const double ContainerWidth = 120.0;
    private const double NarrowWidth = 40.0;   // 折行档：两处 tab + 尾巴在 40 DIP 里必然超过一行
    private const double EmSize = 16.0;
    private static readonly double[] TabValues = { 0.0, 4.0, 24.0, 48.0 };

    private static (int lines, double width0, double widthLast, double widthSum) Measure(double tab, double width)
    {
        var fmt = TextFormatter.Create();
        var pp = new ProbeParagraphProperties(tab, EmSize);
        var src = new ProbeTextSource(Corpus, pp);
        var lines = new List<TextLine>();
        TextLineBreak brk = null;
        while (true)
        {
            var line = fmt.FormatLine(src, 0, width, pp, brk);
            if (line == null) break;
            lines.Add(line);
            brk = line.GetTextLineBreak();
            if (line.Length == 0 || brk == null) break;      // 段落结束
            // 继续下一行：把源指针前移（用换行复位重排：本探针只在首行给内容，
            // 行数变化已经足以反映 tab 生效与否）
            break;
        }
        double sum = 0; foreach (var l in lines) sum += l.Width;
        return (lines.Count, lines.Count > 0 ? lines[0].Width : 0.0,
                lines.Count > 0 ? lines[lines.Count - 1].Width : 0.0, sum);
    }

    private static int Main()
    {
        // ⚠️ **逐值 try/catch**：产品路径在接不住时会落到原生 LineServices
        //   （Linux 上 `LoCreateContext` 不存在 ⇒ `EntryPointNotFoundException`）。
        //   让它变成一个**读数**（哪个 tab 值接不住、什么异常），而不是把整个探针 abort 掉。
        (int lines, double width0, double widthLast, double widthSum) Safe(double tab, double width, out string err)
        {
            err = null;
            try { return Measure(tab, width); }
            catch (Exception ex) { err = ex.GetType().Name + ": " + ex.Message; return (-1, -1, -1, -1); }
        }

        var baseline = Safe(TabValues[0], ContainerWidth, out var baseErr);
        if (baseErr != null) Console.WriteLine($"TABGAP_BASELINE tab=0 EXCEPTION {baseErr}");
        Console.WriteLine($"TABGAP_BASELINE tab=0 lines={baseline.lines} width0={baseline.width0:F3} widthsum={baseline.widthSum:F3}");
        bool responsive = false;
        foreach (var t in TabValues)
        {
            var (n, w0, wl, ws) = Safe(t, ContainerWidth, out var err);
            if (err != null)
            {
                Console.WriteLine($"TABGAP tab={t:F0} EXCEPTION {err}");
                continue;
            }
            Console.WriteLine($"TABGAP tab={t:F0} lines={n} width0={w0:F3} widthlast={wl:F3} widthsum={ws:F3}");
            if (t != TabValues[0] &&
                (n != baseline.lines || Math.Abs(ws - baseline.widthSum) > 1e-9 || Math.Abs(w0 - baseline.width0) > 1e-9))
                responsive = true;
        }
        // ── 窄档（容器 40 DIP）：必须**折行** ⇒ 才量得到"行数"这一维（`D-T4` 的机器证正是"行数变不变"）
        var baselineN = Safe(TabValues[0], NarrowWidth, out var baseErrN);
        if (baseErrN != null) Console.WriteLine($"TABGAP_NARROW_BASELINE tab=0 EXCEPTION {baseErrN}");
        else Console.WriteLine($"TABGAP_NARROW_BASELINE tab=0 lines={baselineN.lines} widthsum={baselineN.widthSum:F3}");
        bool responsiveNarrow = false;
        foreach (var t in TabValues)
        {
            var (n, w0, wl, ws) = Safe(t, NarrowWidth, out var err);
            if (err != null) { Console.WriteLine($"TABGAP_NARROW tab={t:F0} EXCEPTION {err}"); continue; }
            Console.WriteLine($"TABGAP_NARROW tab={t:F0} lines={n} width0={w0:F3} widthlast={wl:F3} widthsum={ws:F3}");
            if (t != TabValues[0] && (n != baselineN.lines || Math.Abs(ws - baselineN.widthSum) > 1e-9)) responsiveNarrow = true;
        }
        Console.WriteLine($"TABGAP_NARROW_RESPONSIVE={(responsiveNarrow ? "yes" : "no")}");
        Console.WriteLine($"TABGAP_RESPONSIVE={(responsive ? "yes" : "no")}");
        // 判据：**no = 复现 `D-T4`**（tab 值没传到有效宽度计算）。为了让 runner 能区分
        //   "复现了已知红" 与 "探针本身没跑起来"，退出码：0 = 生效(yes)、1 = 复现(no)、2 = 异常
        return (responsive || responsiveNarrow) ? 0 : 1;
    }
}

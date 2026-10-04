// T1b · 直构分支闸门 + **默认值语义自检**（主控 2026-09-11 建议：把"默认值"也纳入波前自检）
//
// 两件事：
//   ① 让编译器去检查 `#if TEXTLINE_SHIM_DIRECT` 那一支（PC 内形态）——需要 internal 可见，
//      本工程用 PC 的 IVT 名额（程序集名 = `PresentationCore.Tests` + 同一把公钥公开签名）实现；
//   ② **跑**几条默认值断言。动机（实测踩过）：D3 第一版把回退开关做成"未设 ⇒ 关"，
//      而设计是"默认开"，于是波后 `LoCreateContext` 依旧被查找、D3 看起来"没生效"——
//      这种 bug **编译期发现不了**，只有"不设任何 env 时断言 Enabled == true"能挡。
using System;

internal static class DirectBranchProbe
{
    /// <summary>true 表示刚编的确实是直构分支（`HbInternalsFactory.IsDirect`）。</summary>
    internal static bool IsDirectCompiled => WpfLinux.Shims.PresentationCore.HbInternalsFactory.IsDirect;

    private static int s_fail;

    private static void Check(string what, bool ok, string detail)
    {
        Console.WriteLine((ok ? "  PASS  " : "  FAIL  ") + what + (detail.Length > 0 ? "\n        " + detail : ""));
        if (!ok) ++s_fail;
    }

    private static int Main()
    {
        Console.WriteLine("== T1b · 直构分支（PC 内形态）+ 默认值语义自检 ==");
        Check("D1 编的是直构分支（Direct == true）", IsDirectCompiled, $"IsDirect={IsDirectCompiled}");

        var fb = typeof(WpfLinux.Shims.PresentationCore.HbTextLine).Assembly
            .GetType("WpfLinux.Shims.PresentationCore.HbTextFallback");
        Check("D2 HbTextFallback 存在（D3 接线钩子已编入）", fb != null, fb == null ? "找不到类型" : "ok");
        if (fb == null) return 1;

        var enabled = fb.GetProperty("Enabled", System.Reflection.BindingFlags.Static |
            System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.NonPublic);

        Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE", null);
        Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE_FALLBACK", null);
        Check("D3 **不设任何 env ⇒ 回退默认「开」**（D3 第一版就栽在这里：默认关 ⇒ 接线等于不存在）",
            (bool)enabled.GetValue(null), "Enabled=" + enabled.GetValue(null));

        Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE", "0");
        Check("D4 `WPF_LINUX_TEXTLINE=0` ⇒ 回退关（回到接线前行为，用于 A/B 对照）",
            !(bool)enabled.GetValue(null), "Enabled=" + enabled.GetValue(null));
        Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE", null);

        Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE_FALLBACK", "0");
        Check("D5 `WPF_LINUX_TEXTLINE_FALLBACK=0` ⇒ 回退关（独立开关，不动总开关语义）",
            !(bool)enabled.GetValue(null), "Enabled=" + enabled.GetValue(null));
        Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE_FALLBACK", null);

        Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE", "1");
        Check("D6 `WPF_LINUX_TEXTLINE=1` ⇒ 仍开（打开别的读数不该关掉回退）",
            (bool)enabled.GetValue(null), "Enabled=" + enabled.GetValue(null));
        Environment.SetEnvironmentVariable("WPF_LINUX_TEXTLINE", null);

        Console.WriteLine(s_fail == 0 ? "== 通过 ==" : $"== 失败 {s_fail} ==");
        return s_fail == 0 ? 0 : 1;
    }
}

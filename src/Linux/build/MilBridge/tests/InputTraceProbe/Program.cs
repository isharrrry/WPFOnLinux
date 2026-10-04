// T1c 输入插桩的两向自检（**反射调真件**：不起 WPF、不开 X、不需要 WPF 引用）
//   用法：InputTraceProbe [--enabled] --pc <PresentationCore.dll> --envvar <开关名>
using System;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;

internal static class Program
{
    private static Type _t;
    private static object Call(string name, object[] args)
    {
        foreach (var mi in _t.GetMethods(BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic))
        {
            if (mi.Name != name) continue;
            var ps = mi.GetParameters();
            if (ps.Length != args.Length) continue;
            var a = new object[args.Length];
            for (int i = 0; i < args.Length; ++i)
            {
                var pt = ps[i].ParameterType;
                if (pt == typeof(IntPtr)) a[i] = (IntPtr)args[i];
                else if (pt == typeof(bool)) a[i] = (bool)args[i];
                else if (pt == typeof(string)) a[i] = (string)args[i];
                else if (pt.IsEnum) a[i] = Enum.ToObject(pt, args[i]);
                else a[i] = Convert.ChangeType(args[i], pt);
            }
            return mi.Invoke(null, a);
        }
        throw new MissingMethodException(_t.FullName + "." + name + "/" + args.Length);
    }

    private static int Prop(string name)
    {
        var pi = _t.GetProperty(name, BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        return (int)pi.GetValue(null);
    }

    private static bool PropBool(string name)
    {
        var pi = _t.GetProperty(name, BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
        return (bool)pi.GetValue(null);
    }

    private static string Sha16(string path)
    {
        using (var s = File.OpenRead(path))
        using (var h = SHA256.Create())
        {
            var d = h.ComputeHash(s);
            var sb = new System.Text.StringBuilder();
            for (int i = 0; i < 8; ++i) sb.Append(d[i].ToString("x2"));
            return sb.ToString();
        }
    }

    private static int Main(string[] args)
    {
        bool wantEnabled = Array.IndexOf(args, "--enabled") >= 0;
        string pc = null, envvar = null;
        for (int i = 0; i < args.Length; ++i)
        {
            if (args[i] == "--pc" && i + 1 < args.Length) pc = args[++i];
            if (args[i] == "--envvar" && i + 1 < args.Length) envvar = args[++i];
        }
        if (pc == null || envvar == null) { Console.WriteLine("usage: --pc <dll> --envvar <name> [--enabled]"); return 2; }

        // **先设开关再碰类型**：`s_enabled` 是字段初始化器，类型一被触到就定型
        Environment.SetEnvironmentVariable(envvar, wantEnabled ? "1" : null);
        var asm = Assembly.LoadFrom(pc);
        _t = asm.GetType("System.Windows.Interop.WpfLinuxInputTrace", true);
        Console.WriteLine($"PROBE arm={(wantEnabled ? "enabled" : "default")} env={Environment.GetEnvironmentVariable(envvar) ?? "<unset>"} "
            + $"type={_t.FullName} asm={Path.GetFileName(pc)} sha16={Sha16(pc)}");

        var sw = new StringWriter();
        var origErr = Console.Error;
        Console.SetError(sw);

        var calls = new (string name, object[] args)[]
        {
            ("PreprocessCharEntry", new object[] { new IntPtr(0x200005), 0x102, new IntPtr(0x41), true, false }),
            ("PreprocessCharStep", new object[] { "TranslateChar", false }),
            ("PreprocessCharStep", new object[] { "OnMnemonic", false }),
            ("PreprocessCharStep", new object[] { "ProcessTextInputAction", true }),
            ("SourceKeyDown", new object[] { true, false, "置true前" }),
            ("SourceKeyDown", new object[] { false, false, "复位后" }),
            ("RestoreCharMessagesCalled", new object[0]),
            ("ProviderKeyDown", new object[] { "入口", true, false, false }),
            ("ProviderKeyDownReset", new object[] { false, false }),
            ("ProviderChar", new object[] { "入口", false, true, false }),
            ("ProviderChar", new object[] { "被 _eatCharMessages 门住 ⇒ 丢弃", false, true, false }),
        };

        var perApi = new System.Collections.Generic.List<string>();
        int zeroApis = 0;
        foreach (var c in calls)
        {
            int before = Prop("LineCount");
            Call(c.name, c.args);
            int after = Prop("LineCount");
            int delta = after - before;
            if (delta == 0) zeroApis++;
            perApi.Add($"{c.name}({c.args.Length})={delta}");
        }
        int afterEleven = sw.ToString().Split('\n', StringSplitOptions.RemoveEmptyEntries).Length;

        // 有界性：再打 250 次
        for (int i = 0; i < 250; ++i) Call("PreprocessCharStep", new object[] { "bound-" + i, false });
        int lineCount = Prop("LineCount");

        Console.SetError(origErr);
        string text = sw.ToString();
        int lines = text.Split('\n', StringSplitOptions.RemoveEmptyEntries).Length;
        bool hasPrefix = text.Contains("[INPUT_TRACE]");

        bool pass; string detail;
        if (!wantEnabled)
        {
            pass = !PropBool("Enabled") && lines == 0 && lineCount == 0;
            detail = $"enabled={PropBool("Enabled")} lines={lines} lineCount={lineCount} 每入口行数=[{string.Join(" ", perApi)}]";
        }
        else
        {
            pass = PropBool("Enabled") && afterEleven == calls.Length && zeroApis == 0 && hasPrefix && lineCount <= 200;
            detail = $"enabled={PropBool("Enabled")} linesAfter11Apis={afterEleven}/{calls.Length} 零行入口数={zeroApis} "
                   + $"totalLines={lines} lineCount={lineCount}（有界 ≤200）hasPrefix={hasPrefix}";
        }
        Console.WriteLine($"INPUT_TRACE_{(wantEnabled ? "ENABLED" : "DEFAULT")}_ASSERT={(pass ? "PASS" : "FAIL")} {detail}");
        Console.WriteLine($"INPUT_TRACE_{(wantEnabled ? "ENABLED" : "DEFAULT")}_PERAPI {string.Join(" ", perApi)}");
        if (wantEnabled)
        {
            Console.WriteLine("---- 原始输出（前 3 行）----");
            int k = 0;
            foreach (var l in text.Split('\n')) { if (l.Length == 0) continue; Console.WriteLine(l); if (++k >= 3) break; }
        }
        return pass ? 0 : 1;
    }
}

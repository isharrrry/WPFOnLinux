#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T1c/输入追踪的**自检装置**（两向）：

    python3 build/MilBridge/tools/t1c-inputtrace-verify.py

【① "只插入"证明（最硬的一条）】
  把生成物里**恰好是我插入的那些片段**按**逆序**摘掉，剩下的必须与上游**逐字节相同**（sha256 比对）。
  ⇒ 这就把"只读插桩"从"我说它只打印"变成**可复算的事实**：控制流/返回值/异常结构一个字节都没动。
  （做法：import 应用器模块，拿它的 EDITS 表，逆序 `repl → anchor` 回代。）

【② 插桩类本身的两向行为（用现成最轻装置：一个纯 .NET 探针，**不起 WPF 应用**）】
  从**生成物**里把 `WpfLinuxInputTrace` 的源码**原样抽出**编进探针 ⇒ 测的就是将来进 PC 的那份文本：
    · 缺省（不设 `WPF_LINUX_INPUT_TRACE`）⇒ `Enabled=false`、调全部入口 **0 行输出**、`LineCount==0`；
    · `=1` ⇒ 每个入口都出 1 行且带 `[INPUT_TRACE]` 前缀；连打 250 次 ⇒ **有界 ≤200**。
  探针不跑 WPF、不开 X、不起窗口（纯控制台）。

【做不到的一条（如实登记）】
  "插桩行**确实会在 WM_CHAR 分支被执行到**"这句话，离线**证不了** —— 它需要真的来一条 WM_CHAR
  （= 真输入 + WPF 应用，本轮被禁止）。离线能给的最强证据是：
  应用器的**锚点就是那段 `case WindowMessage.WM_CHAR:` 上下文本身**（命中数断言 == 1），
  且"只插入"证明保证那些行**落在原位**。真正的执行证据由波后那次 `--only=textbox-edit` 跑给出。
"""

import hashlib
import importlib.util
import os
import re
import subprocess
import sys

ROOT = "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux"
APPLIER = os.path.join(ROOT, "src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py")
GEN_HS = os.path.join(ROOT, "build/PresentationCore.Linux/HwndSource.Linux.cs")
GEN_HK = os.path.join(ROOT, "build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs")
PROBE_DIR = os.path.join(ROOT, "build/MilBridge/tests/InputTraceProbe")
PC_DLL = os.path.join(ROOT, "build/PresentationCore.Linux/bin/Debug/PresentationCore.dll")


def load_applier():
    spec = importlib.util.spec_from_file_location("inputtrace_applier", APPLIER)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def strip_header(text):
    """去掉生成物头（HEADER + 上游原文）；返回上游原文部分。"""
    i = text.find("// ↓↓↓")
    # 头以最后一行 `// ...` 结束；上游正文从第一行 `// Licensed` 开始
    j = text.find("// Licensed to the .NET Foundation")
    if j < 0:
        return None
    return text[j:]


def verify_insert_only(mod):
    ok = True
    for gen_path, upstream_path, edits, label in (
        (GEN_HS, mod.UPSTREAM_HS, mod.EDITS_HS, "HwndSource"),
        (GEN_HK, mod.UPSTREAM_HK, mod.EDITS_HK, "HwndKeyboardInputProvider"),
    ):
        with open(gen_path, encoding="utf-8") as f:
            gen = f.read()
        body = strip_header(gen)
        if body is None:
            print(f"[失败] {label}：生成物里找不到上游正文起点")
            ok = False
            continue

        # 逆序回代 repl → anchor（EDITS 是顺序应用的 ⇒ 逆序还原）
        restored = body
        for name, anchor, repl in reversed(edits):
            n = restored.count(repl)
            if n != 1:
                print(f"[失败] {label} {name}：逆代时 `repl` 命中 {n} 次（要求 1）")
                ok = False
                break
            restored = restored.replace(repl, anchor, 1)

        with open(upstream_path, encoding="utf-8-sig") as f:
            upstream = f.read()

        a = hashlib.sha256(restored.encode("utf-8")).hexdigest()
        b = hashlib.sha256(upstream.encode("utf-8")).hexdigest()
        if a == b:
            print(f"[① 只插入] {label}：摘掉插桩后与上游**逐字节相同** ✓ sha256={b[:24]}…")
        else:
            ok = False
            print(f"[① 只插入] {label}：**不一致** 还原后 {a[:24]}… ≠ 上游 {b[:24]}…")
            # 给出第一处差异位置，便于定位
            for i, (x, y) in enumerate(zip(restored, upstream)):
                if x != y:
                    print(f"      首个差异 @ 字符 {i}：还原后 {restored[max(0,i-40):i+40]!r}")
                    print(f"      上游同位置   {upstream[max(0,i-40):i+40]!r}")
                    break
    return ok


def extract_trace_class(gen_hs_path):
    """从**生成物**里原样抽出 WpfLinuxInputTrace 类（探针编的就是将来进 PC 的那份文本）。"""
    with open(gen_hs_path, encoding="utf-8") as f:
        text = f.read()
    start = text.find("    /// <summary>\n    /// T1c · 输入链的")
    if start < 0:
        start = text.find("    internal static class WpfLinuxInputTrace")
        start = text.rfind("    /// <summary>", 0, start)
    end = text.find("    public class HwndSource", start)
    if start < 0 or end < 0:
        return None
    return text[start:end]


def build_probe():
    os.makedirs(PROBE_DIR, exist_ok=True)
    cls = extract_trace_class(GEN_HS)
    if cls is None:
        print("[失败] 无法从生成物里抽出 WpfLinuxInputTrace")
        return 1
    with open(os.path.join(PROBE_DIR, "WpfLinuxInputTrace.extracted.cs"), "w", encoding="utf-8") as f:
        f.write("// 本文件由 tools/t1c-inputtrace-verify.py 从 build/PresentationCore.Linux/HwndSource.Linux.cs **原样抽出**\n"
                "// ⚠️ **不参与编译**（只作存档/取证）：该类的签名引用 PC 内部类型，独立编译必然失败；\n"
                "//    两臂自检改为**反射调用真件**，见同目录 Program.cs 的说明。\n"
                "// （探针编的就是将来进 PC 的那份文本；不要手改）\n"
                "using System;\nusing System.Globalization;\nusing System.Threading;\n\n"
                "namespace System.Windows.Interop\n{\n" + cls + "}\n")

    with open(os.path.join(PROBE_DIR, "InputTraceProbe.csproj"), "w", encoding="utf-8") as f:
        f.write("""<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <AssemblyName>MilBridge.InputTraceProbe</AssemblyName>
    <Nullable>disable</Nullable>
    <ImplicitUsings>disable</ImplicitUsings>
    <AppendTargetFrameworkToOutputPath>false</AppendTargetFrameworkToOutputPath>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
    <BaseOutputPath>$(MSBuildThisFileDirectory)bin\\</BaseOutputPath>
    <BaseIntermediateOutputPath>$(MSBuildThisFileDirectory)obj\\</BaseIntermediateOutputPath>
  </PropertyGroup>
  <!-- 【2026-09-14 重写】只编 Program.cs（**反射**驱动真件）。抽出的
       `WpfLinuxInputTrace.extracted.cs` **不参与编译**：v3 之后该类已引用 PresentationCore 的
       **内部类型**（`InputReport`/`InputReportEventArgs`/`IKeyboardInputSink`…）⇒ 独立编译必然
       CS0246/CS0122；要让它能编得加 `InternalsVisibleTo`（= 改 PC 源码 = 一轮波）⇒ 不做。
       反射版编的是真件、调的是真件，反而更强；该文件仅作"这一版产物里的插桩文本"存档。 -->
  <ItemGroup>
    <Compile Include="$(MSBuildThisFileDirectory)Program.cs" />
  </ItemGroup>
</Project>
""")
    with open(os.path.join(PROBE_DIR, "Program.cs"), "w", encoding="utf-8") as f:
        f.write('''// T1c 输入插桩的两向自检（**反射调真件**：不起 WPF、不开 X、不需要 WPF 引用）
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
        int afterEleven = sw.ToString().Split('\\n', StringSplitOptions.RemoveEmptyEntries).Length;

        // 有界性：再打 250 次
        for (int i = 0; i < 250; ++i) Call("PreprocessCharStep", new object[] { "bound-" + i, false });
        int lineCount = Prop("LineCount");

        Console.SetError(origErr);
        string text = sw.ToString();
        int lines = text.Split('\\n', StringSplitOptions.RemoveEmptyEntries).Length;
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
            foreach (var l in text.Split('\\n')) { if (l.Length == 0) continue; Console.WriteLine(l); if (++k >= 3) break; }
        }
        return pass ? 0 : 1;
    }
}
''')
    return 0



def run_probe():
    env = dict(os.environ)
    env["PATH"] = os.path.expanduser("~/.dotnet") + ":" + env.get("PATH", "")
    cmd = ["dotnet", "build", os.path.join(PROBE_DIR, "InputTraceProbe.csproj"),
           "-c", "Release", "-m:1", "--nologo", "-v", "q"]
    print("[② 探针编译] cmd=" + " ".join(cmd))
    b = subprocess.run(cmd, capture_output=True, text=True, env=env)
    out = (b.stdout + b.stderr).strip().splitlines()
    if b.returncode != 0:
        # 【2026-09-14 修·不许藏失败】旧版只打最后 3 行 ⇒ 真正的 `error CS…` 被吞掉，
        #   只剩"1 个错误"，于是"编译失败"会被读成"断言失败"（同一族的隐藏失败）。
        #   现在：**所有** error 行 + 结语，并明确"两个臂没有跑"。
        errs = [l for l in out if "error" in l.lower() or "错误" in l]
        print("[② 探针编译] **FAIL**（rc=%d）：" % b.returncode)
        for l in errs[:12]:
            print("    " + l.strip())
        if len(errs) > 12:
            print("    …（另有 %d 行 error，未打印）" % (len(errs) - 12))
        print("[② 探针编译] ⇒ **两个臂都没有跑**（这是**装置编译失败**，不是断言失败）")
        return 1
    print("[② 探针编译] OK：" + " / ".join(out[-3:]))
    dll = os.path.join(PROBE_DIR, "bin/Release/MilBridge.InputTraceProbe.dll")
    envvar = None
    with open(os.path.join(PROBE_DIR, "WpfLinuxInputTrace.extracted.cs"), encoding="utf-8") as f:
        m = re.search(r'internal const string EnvVar = "([^"]+)"', f.read())
        envvar = m.group(1) if m else "WPF_LINUX_INPUT_TRACE"
    pc_sha = hashlib.sha256(open(PC_DLL, "rb").read()).hexdigest()[:16]
    print("[③ 被测真件] PC=%s sha16=%s 开关=%s（反射调用；无 WPF 引用、不起 WPF）"
          % (os.path.relpath(PC_DLL, ROOT), pc_sha, envvar))
    rc = 0
    for arm in ([], ["--enabled"]):
        name = "enabled" if arm else "default"
        r = subprocess.run(["dotnet", dll] + arm + ["--pc", PC_DLL, "--envvar", envvar],
                           capture_output=True, text=True, env=env)
        print("[③ 臂 %s] rc=%d" % (name, r.returncode))
        print(r.stdout.strip())
        if r.stderr.strip():
            print("  [stderr] " + r.stderr.strip().splitlines()[-1])
        if r.returncode != 0:
            rc = 1
    return rc


def main():
    mod = load_applier()
    ok = verify_insert_only(mod)
    if build_probe() != 0:
        ok = False
    if run_probe() != 0:
        ok = False
    print(f"\n== 自检结论：{'全部通过 ✅' if ok else '**有失败** ❌'} ==")
    print("（失败阶段看上面的 `[①/②/③]` 标记：**② 失败 ⇒ 两个臂没有跑，禁止读成断言失败**）")
    print("（离线**证不了**的一条：\"插桩行会在 WM_CHAR 分支被执行到\" —— 需要真输入；见文件头说明）")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())

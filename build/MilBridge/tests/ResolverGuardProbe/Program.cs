// V18A · 产品侧 DllImport 解析器安装点 —— 红证探针
//
// 用法（每条命令一个模式，一个进程只跑一个模式，因为解析器槽位/类型静态构造都只跑一次）：
//
//   dotnet ResolverGuardProbe.dll order1 <asmPath>
//   dotnet ResolverGuardProbe.dll order2 <asmPath> <typeFullName>
//   dotnet ResolverGuardProbe.dll order3 <asmPath> <typeFullName>
//   dotnet ResolverGuardProbe.dll dump   <asmPath>
//   dotnet ResolverGuardProbe.dll v1     <asmPath> <self|replica|different|none> [--shim <so>]
//   dotnet ResolverGuardProbe.dll v2     <wpfgfxPath> <replica|different|broken|none>
//
// 全部读数以 `KEY=VALUE` 逐行打印，便于逐字对拍（纪律 15/18/26）。

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Runtime.Loader;

internal static class Program
{
    private static string s_targetDir;
    private static string s_targetFile;

    private static int Main(string[] args)
    {
        if (args.Length < 2)
        {
            Console.WriteLine("usage: ResolverGuardProbe <order1|order2|order3|dump|v1|v2> <path> [args…]");
            return 2;
        }

        string mode = args[0];
        string path = Path.GetFullPath(args[1]);
        List<string> rest = args.Skip(2).ToList();
        s_useStream = rest.Remove("--loadstream");   // 无值开关：去掉即算给了
        string shim = TakeOption(rest, "--shim") ?? "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";

        Console.WriteLine("PROBE=ResolverGuardProbe");
        Console.WriteLine("MODE=" + mode);
        Console.WriteLine("TARGET=" + path);
        Console.WriteLine("TARGET_EXISTS=" + File.Exists(path));
        Console.WriteLine("SHIM=" + shim);
        Console.WriteLine("SHIM_EXISTS=" + File.Exists(shim));
        Console.WriteLine("PID=" + Environment.ProcessId);
        if (!File.Exists(path))
        {
            Console.WriteLine("RESULT=NOINFO reason=target-missing");
            return 2;
        }

        s_targetDir = Path.GetDirectoryName(path);
        s_targetFile = Path.GetFileName(path);
        AssemblyLoadContext.Default.Resolving += (ctx, name) =>
        {
            // ⚠️ 不许把**目标自己**也塞回去：`Assembly.LoadFrom(target)` 期间运行时会为同名程序集
            //    走一次 Resolving，若这里再 `LoadFromAssemblyPath(同一个文件)` ⇒ 递归 ⇒
            //    `FileLoadException: The located assembly's manifest definition does not match`（实测踩过）。
            if (string.Equals(name.Name + ".dll", s_targetFile, StringComparison.OrdinalIgnoreCase))
                return null;
            string cand = Path.Combine(s_targetDir, name.Name + ".dll");
            return File.Exists(cand) ? ctx.LoadFromAssemblyPath(cand) : null;
        };

        switch (mode)
        {
            case "order1": return Order(path, null, false, shim);
            case "order2": return Order(path, rest.FirstOrDefault(), false, shim);
            case "order3": return Order(path, rest.FirstOrDefault(), true, shim);
            case "dump": return Dump(path);
            case "mapload": return MapLoad(path);
            case "realcall": return RealCall(path);
            case "v1": return V1(path, rest.FirstOrDefault() ?? "none", shim);
            case "v2": return V2(path, rest.FirstOrDefault() ?? "none");
            default:
                Console.WriteLine("RESULT=NOINFO reason=unknown-mode");
                return 2;
        }
    }

    private static string TakeOption(List<string> rest, string name)
    {
        int i = rest.IndexOf(name);
        if (i < 0 || i + 1 >= rest.Count) return null;
        string v = rest[i + 1];
        rest.RemoveRange(i, 2);
        return v;
    }

    // =====================================================================================
    //  加载顺序测量：模块初始化器到底在"加载"时跑，还是在"首次触碰该模块的类型"时跑？
    //  =· 这三种模式回答 R17C 审计 §7-① 那条"只读手段做不到"的问题。
    //    order1 = LoadFrom 后立刻试装外国解析器
    //    order2 = 先 asm.GetType(名字) 再试装
    //    order3 = 再 RunClassConstructor(该类型) 之后试装
    //  三种各跑一个进程（试装成功会占槽 ⇒ 同进程内不可重复）。
    // =====================================================================================
    private static int Order(string path, string typeName, bool runCctor, string shim)
    {
        Assembly asm = LoadTarget(path);
        Console.WriteLine("LOADED=" + asm.FullName);
        Console.WriteLine("STEP=after-load");
        ReportForeignInstall(asm, "replica", shim);

        if (!string.IsNullOrEmpty(typeName))
        {
            Type t = asm.GetType(typeName, throwOnError: false);
            Console.WriteLine("TYPE_FOUND=" + (t != null) + " (" + typeName + ")");
            Console.WriteLine("STEP=after-gettype");
            // 注意：GetType 可能已经触发模块初始化器 ⇒ 这里必须**新进程**才好判，故由调用方决定模式。
            Console.WriteLine("NOTE=see-order2-order3-separate-processes");
            if (runCctor && t != null)
            {
                try
                {
                    RuntimeHelpers.RunClassConstructor(t.TypeHandle);
                    Console.WriteLine("RUNCTOR=OK");
                }
                catch (Exception e)
                {
                    Console.WriteLine("RUNCTOR_THROW=" + Describe(e));
                }
                Console.WriteLine("STEP=after-runctor");
            }
        }
        Console.WriteLine("RESULT=DONE");
        return 0;
    }

    // =====================================================================================
    //  `mapload`：**模块初始化器跑完之后**，shim 到底有没有被 dlopen 进来？
    //  用 /proc/self/maps 取证（不看日志文案，直接看进程的映射表）。
    //  动机：V1 的守卫在**正常路径**上也要做一次真 `[DllImport]` 自证 ⇒ 会把 shim **提前**加载进来
    //  （修前是懒加载：首个真 P/Invoke 才 dlopen）⇒ 这是本波**必须如实登记的位移**。
    // =====================================================================================
    private static int MapLoad(string path)
    {
        Assembly asm = LoadTarget(path);
        Console.WriteLine("LOADED=" + asm.FullName);
        Console.WriteLine("MAPS_TOTAL_BEFORE=" + CountMaps(null));
        Console.WriteLine("MAPS_WPFWIN32_BEFORE=" + CountMaps("wpfwin32"));
        Console.WriteLine("MAPS_LIBX11_BEFORE=" + CountMaps("libX11"));
        // V1（PC/WB/UIAutomation*）触发 Win32ShimResolver 的成员；V2（WpfGfx.Linux）触发 X11Native 的静态构造。
        Type t = FindShimResolverType(asm);
        if (t != null)
        {
            try
            {
                MethodInfo m = t.GetMethod("IsWicMappingEnabled", BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
                Console.WriteLine("TRIGGER=natural IsWicMappingEnabled=" + m.Invoke(null, null));
            }
            catch (Exception e) { Console.WriteLine("TRIGGER=natural THROW " + Describe(e)); }
        }
        else
        {
            Type x11 = asm.GetType("WpfGfx.Linux.Windowing.X11Native", throwOnError: false);
            Console.WriteLine("TRIGGER_TYPE=" + (x11 == null ? "<none>" : x11.FullName));
            if (x11 != null)
            {
                try { RuntimeHelpers.RunClassConstructor(x11.TypeHandle); Console.WriteLine("TRIGGER=natural X11Native cctor NO_THROW"); }
                catch (Exception e) { Console.WriteLine("TRIGGER=natural X11Native cctor THROW " + Describe(e)); }
            }
        }
        Console.WriteLine("MAPS_TOTAL_AFTER=" + CountMaps(null));
        Console.WriteLine("MAPS_WPFWIN32_AFTER=" + CountMaps("wpfwin32"));
        Console.WriteLine("MAPS_LIBX11_AFTER=" + CountMaps("libX11"));
        foreach (string line in File.ReadAllLines("/proc/self/maps"))
            if (line.Contains("wpfwin32") || line.Contains("libX11")) Console.WriteLine("MAPS_LINE=" + line);
        Console.WriteLine("RESULT=DONE");
        return 0;
    }

    // =====================================================================================
    //  `realcall`：正常路径下**用目标程序集自己声明的真 `[DllImport]`** 走一次
    //  （判据①的直测：`WpfLinuxWin32_ShimVersion` 声明在目标程序集内 ⇒ 走目标的解析器；
    //    探针程序集里写的 DllImport 不算）。
    // =====================================================================================
    private static int RealCall(string path)
    {
        Assembly asm = LoadTarget(path);
        Console.WriteLine("LOADED=" + asm.FullName);
        Type t = FindShimResolverType(asm);
        Console.WriteLine("TRIGGER_TYPE=" + (t == null ? "<none>" : t.FullName));
        if (t != null)
        {
            try
            {
                MethodInfo mi = t.GetMethod("IsWicMappingEnabled", BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
                Console.WriteLine("MODULE_INIT=NO_THROW IsWicMappingEnabled=" + mi.Invoke(null, null));
            }
            catch (Exception e) { Console.WriteLine("MODULE_INIT=THROW " + Describe(e)); }
        }
        try
        {
            MethodInfo real = t.GetMethod("ShimVersionViaUser32", BindingFlags.NonPublic | BindingFlags.Static);
            if (real == null) { Console.WriteLine("REAL_DLLIMPORT=NOINFO method-absent"); }
            else { object v = real.Invoke(null, null); Console.WriteLine("REAL_DLLIMPORT=OK value=" + v); }
        }
        catch (Exception e)
        {
            Console.WriteLine("REAL_DLLIMPORT=THROW " + Describe(e));
        }
        Console.WriteLine("RESULT=DONE");
        return 0;
    }

    private static int CountMaps(string needle)
        => File.ReadAllLines("/proc/self/maps").Count(l => needle == null || l.Contains(needle));

    // =====================================================================================
    //  列出目标程序集里的安装点形态（模块初始化器 / 静态构造）
    // =====================================================================================
    private static int Dump(string path)
    {
        Assembly asm = LoadTarget(path);
        Console.WriteLine("LOADED=" + asm.FullName);

        // ⚠️ 注意：LoadFrom 本身可能已经跑了模块初始化器（正是 order* 要测的）。
        //    本模式只看**静态形态**（反射元数据），所以它不能用来判"跑没跑"。
        Type moduleType = asm.GetType("<Module>");
        Console.WriteLine("MODULE_TYPE=" + (moduleType != null));
        if (moduleType != null)
        {
            Console.WriteLine("MODULE_TYPE_INITIALIZER=" + (moduleType.TypeInitializer != null));
            foreach (MethodInfo m in moduleType.GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.DeclaredOnly))
            {
                bool isMi = m.GetCustomAttribute<ModuleInitializerAttribute>() != null;
                Console.WriteLine($"MODULE_METHOD={m.Name} public={m.IsPublic} static={m.IsStatic} moduleinitattr={isMi}");
            }
        }

        // Win32ShimResolver / X11Native 的形态
        foreach (string tn in new[] { "WpfLinux.Shims.WindowsBase.Win32ShimResolver", "WpfLinux.Shims.WindowsBase.Win32ShimResolver+Diagnostics", "WpfGfx.Linux.Windowing.X11Native", "WpfGfx.Linux.Windowing.X11LibraryResolver" })
        {
            Type t = asm.GetType(tn, throwOnError: false);
            if (t == null) { Console.WriteLine("TYPE_ABSENT=" + tn); continue; }
            Console.WriteLine("TYPE_PRESENT=" + tn + " cctor=" + (t.TypeInitializer != null));
            foreach (MemberInfo mi in t.GetMembers(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.Instance | BindingFlags.DeclaredOnly))
                Console.WriteLine($"  MEMBER={mi.MemberType} {mi.Name}");
        }
        Console.WriteLine("RESULT=DONE");
        return 0;
    }

    // =====================================================================================
    //  V1：build/shims/Win32ShimResolver.cs 的 [ModuleInitializer]
    // =====================================================================================
    private static int V1(string path, string variant, string shim)
    {
        Assembly asm = LoadTarget(path);
        Console.WriteLine("LOADED=" + asm.FullName);

        // ① 先占槽：外国解析器（能不能装 = 产品模块初始化器跑没跑）
        bool foreign = ReportForeignInstall(asm, variant, shim);

        // ② **自然路径**触发产品模块初始化器：跑本模块里一个**无外部依赖**的静态成员
        //    （`WpfLinux.Shims.*.Win32ShimResolver.IsWicMappingEnabled()`：本文件自己的类型；
        //      用 `Colors.Red` 会拖 WindowsBase，属夹具噪声 —— 实测踩过）
        Type t = FindShimResolverType(asm);
        Console.WriteLine("TRIGGER_TYPE=" + (t == null ? "<none>" : t.FullName));
        try
        {
            MethodInfo m = t.GetMethod("IsWicMappingEnabled", BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
            object v = m.Invoke(null, null);
            Console.WriteLine("TRIGGER=natural NO_THROW IsWicMappingEnabled=" + v);
        }
        catch (Exception e)
        {
            Console.WriteLine("TRIGGER=natural THROW " + Describe(e));
        }

        // ③ 毒化检查：再碰一次（模块初始化器失败后，本模块**每个类型**都应当继续响亮地抛）
        try
        {
            MethodInfo m = t.GetMethod("IsWicMappingEnabled", BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
            object v = m.Invoke(null, null);
            Console.WriteLine("POISON_RECHECK=NO_THROW IsWicMappingEnabled=" + v);
        }
        catch (Exception e)
        {
            Console.WriteLine("POISON_RECHECK=THROW " + Describe(e));
        }

        // ③b 诊断位：产品安装点自己有没有记下"输掉了竞态"（修后才有；修前应为 NOINFO）
        foreach (string pn in new[] { "ResolverConflict", "SelfCheckShimVersion", "SelfCheckResolved" })
        {
            try
            {
                PropertyInfo pi = t.GetProperty(pn, BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
                if (pi == null) { Console.WriteLine("DIAG_" + pn + "=NOINFO property-absent"); continue; }
                Console.WriteLine("DIAG_" + pn + "=" + pi.GetValue(null));
            }
            catch (Exception e)
            {
                Console.WriteLine("DIAG_" + pn + "=THROW " + Describe(e));
            }
        }

        // ④ 显式路径：运行时 API（跑的就是那个模块初始化器本体）
        try
        {
            RuntimeHelpers.RunModuleConstructor(asm.ManifestModule.ModuleHandle);
            Console.WriteLine("RUNMODULECTOR=NO_THROW");
        }
        catch (Exception e)
        {
            Console.WriteLine("RUNMODULECTOR=THROW " + Describe(e));
        }

        Console.WriteLine("FOREIGN_WAS_INSTALLED=" + foreign);
        Console.WriteLine("RESULT=DONE");
        return 0;
    }

    // =====================================================================================
    //  V2：src/WpfGfx.Linux/Windowing/X11Native.cs 的静态构造
    // =====================================================================================
    private static int V2(string path, string variant)
    {
        Assembly asm = LoadTarget(path);
        Console.WriteLine("LOADED=" + asm.FullName);

        Type x11 = asm.GetType("WpfGfx.Linux.Windowing.X11Native", throwOnError: false);
        Console.WriteLine("X11NATIVE_FOUND=" + (x11 != null));
        if (x11 == null) { Console.WriteLine("RESULT=NOINFO reason=x11native-not-found"); return 2; }

        // ⚠️ 不许在这里"探一下 cctor 跑没跑" —— 任何触碰 X11Native 的动作都会把 cctor 跑掉，
        //    而本模式的全部意义就是"先占槽、再跑 cctor"。只读反射元数据（TypeInitializer != null）不触发执行。
        Console.WriteLine("X11NATIVE_HAS_CCTOR=" + (x11.TypeInitializer != null));

        bool foreign = ReportForeignInstall(asm, variant, null);
        Console.WriteLine("FOREIGN_INSTALL=" + (foreign ? "OK" : "REJECTED"));

        // 触发类型静态构造（= 产品安装点）
        try
        {
            RuntimeHelpers.RunClassConstructor(x11.TypeHandle);
            Console.WriteLine("CCTOR_RESULT=NO_THROW");
        }
        catch (Exception e)
        {
            Console.WriteLine("CCTOR_THROW=" + Describe(e));
        }

        // 类型是否被毒化：再跑一次 + 取一个成员
        try
        {
            RuntimeHelpers.RunClassConstructor(x11.TypeHandle);
            Console.WriteLine("POISON_RECHECK=NO_THROW");
        }
        catch (Exception e)
        {
            Console.WriteLine("POISON_RECHECK=THROW " + Describe(e));
        }

        // 诊断位（正对照：必须能证明"我们**真的**走过了丢竞态那一支"）
        foreach (string pn in new[] { "ResolverConflict", "SelfCheckX11NameResolved" })
        {
            try
            {
                PropertyInfo pi = x11.GetProperty(pn, BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);
                Console.WriteLine("DIAG_" + pn + "=" + (pi == null ? "NOINFO property-absent" : pi.GetValue(null)?.ToString()));
            }
            catch (Exception e)
            {
                Console.WriteLine("DIAG_" + pn + "=THROW " + Describe(e));
            }
        }

        Console.WriteLine("RESULT=DONE");
        return 0;
    }

    // =====================================================================================
    //  外国解析器的两/三个变体
    //    replica   = 映射**与产品同一批名字**（对 V1：user32/gdi32/kernel32/PresentationNative_cor3/uxtheme/wtsapi32 → libwpfwin32.so；
    //                对 V2：libX11.so.6 → libX11.so.6）
    //    different = 映射**另一批名字**（产品那批一个都不映射）
    //    broken    = 映射产品同名名字，但指向不存在的路径（⇒ 名字解析不了）
    //    self/none = 不装外国解析器（对照臂）
    // =====================================================================================
    private static bool ReportForeignInstall(Assembly asm, string variant, string shim)
    {
        if (variant == "none" || variant == "self")
        {
            Console.WriteLine("FOREIGN_INSTALL=SKIPPED(variant=" + variant + ")");
            return false;
        }

        try
        {
            NativeLibrary.SetDllImportResolver(asm, MakeForeign(variant, shim));
            Console.WriteLine("FOREIGN_INSTALL=OK variant=" + variant);
            return true;
        }
        catch (Exception e)
        {
            Console.WriteLine("FOREIGN_INSTALL=REJECTED variant=" + variant + " " + Describe(e));
            return false;
        }
    }

    private static readonly string[] V1Names =
    {
        "user32.dll", "gdi32.dll", "kernel32.dll", "PresentationNative_cor3.dll", "uxtheme.dll", "wtsapi32.dll",
    };

    private static DllImportResolver MakeForeign(string variant, string shim)
    {
        switch (variant)
        {
            case "replica":
                return (name, asm, sp) =>
                {
                    if (V1Names.Any(n => string.Equals(n, name, StringComparison.OrdinalIgnoreCase)))
                    {
                        Console.WriteLine("FOREIGN_HIT=" + name);
                        return NativeLibrary.Load(shim);
                    }
                    if (string.Equals(name, "libX11.so.6", StringComparison.Ordinal))
                    {
                        Console.WriteLine("FOREIGN_HIT=" + name);
                        return NativeLibrary.Load("libX11.so.6");
                    }
                    return IntPtr.Zero;
                };
            case "different":
                return (name, asm, sp) =>
                {
                    if (string.Equals(name, "hostonly.dll", StringComparison.OrdinalIgnoreCase))
                    {
                        Console.WriteLine("FOREIGN_HIT=" + name);
                        return NativeLibrary.Load("libc.so.6");
                    }
                    return IntPtr.Zero;
                };
            case "broken":
                return (name, asm, sp) =>
                {
                    bool ours = V1Names.Any(n => string.Equals(n, name, StringComparison.OrdinalIgnoreCase))
                                || string.Equals(name, "libX11.so.6", StringComparison.Ordinal);
                    if (ours)
                    {
                        Console.WriteLine("FOREIGN_HIT=" + name + " → <nonexistent>");
                        return NativeLibrary.Load("/nonexistent-dir-please-fail/libX11.so.6");
                    }
                    return IntPtr.Zero;
                };
            default:
                throw new ArgumentException("unknown variant: " + variant);
        }
    }

    private static Type FindShimResolverType(Assembly asm)
    {
        foreach (string tn in new[]
        {
            "WpfLinux.Shims.PresentationCore.Win32ShimResolver",
            "WpfLinux.Shims.WindowsBase.Win32ShimResolver",
            "WpfLinux.Shims.UIAutomation.Win32ShimResolver",
        })
        {
            Type t = asm.GetType(tn, throwOnError: false);
            if (t != null) return t;
        }
        return null;
    }


    // =====================================================================================
    //  载入目标件：两条腿
    //    from   = `Assembly.LoadFrom(path)`（默认落到 Default ALC）
    //    stream = 自建 ALC + `LoadFromStream`（**不用路径**）
    //  为什么需要第二条：本机实测 **权威 `WindowsBase.dll` 用 `Assembly.LoadFrom` 必然失败**
    //    `FileLoadException … The located assembly's manifest definition does not match the assembly reference. (0x80131040)`
    //    而同一批产物里的 PC / UIAutomationTypes / UIAutomationProvider 都能 LoadFrom；
    //    这是**夹具**性质、不是本波判据（报告 §6 逐字留档）。真宿主按身份装（app-local 探测）没有这个问题。
    // =====================================================================================
    private sealed class ProbeAlc : AssemblyLoadContext
    {
        private readonly string _dir;
        public ProbeAlc(string dir) : base("ResolverGuardProbe", isCollectible: false) { _dir = dir; }
        protected override Assembly Load(AssemblyName name)
        {
            string p = Path.Combine(_dir, name.Name + ".dll");
            if (!File.Exists(p)) return null;
            using FileStream fs = File.OpenRead(p);
            return LoadFromStream(fs);
        }
    }

    private static bool s_useStream;
    private static Assembly LoadTarget(string path)
    {
        if (!s_useStream) return Assembly.LoadFrom(path);
        var alc = new ProbeAlc(Path.GetDirectoryName(path));
        using FileStream fs = File.OpenRead(path);
        return alc.LoadFromStream(fs);
    }

    private static MethodInfo FindModuleInitializer(Assembly asm)
    {
        Type mt = asm.GetType("<Module>");
        if (mt == null) return null;
        foreach (MethodInfo m in mt.GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.DeclaredOnly))
            if (m.GetCustomAttribute<ModuleInitializerAttribute>() != null) return m;
        // 兜底：C# 把 [ModuleInitializer] 方法编进 <Module>，方法名保留；属性也可能被剥掉
        foreach (MethodInfo m in mt.GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.DeclaredOnly))
            if (m.Name == "Register" || m.Name == "Install" || m.Name == "InstallResolver") return m;
        return null;
    }

    private static string Describe(Exception e)
    {
        if (e == null) return "<null>";
        string inner = e.InnerException != null ? " | inner=" + e.InnerException.GetType().FullName + ": " + Flat(e.InnerException.Message) : "";
        return e.GetType().FullName + ": " + Flat(e.Message) + inner;
    }

    private static string Flat(string s) => (s ?? "").Replace("\r", "\\r").Replace("\n", "\\n");
}

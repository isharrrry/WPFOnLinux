# V18A · 两个**产品侧** DllImport 解析器安装点的守卫（`#18` 波 · V1/V2/V3 · `D-R3`）

> **lane = V18A**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **时刻（落地）**：`2026-09-16T14:55:31+0800`…`14:55:53+0800`｜**时刻（读数）**：`15:01:41+0800` = `2026-09-16T07:01:41Z`
> `kernel = 6.8.0-138-generic`（x86_64, VirtualBox）｜`/proc/loadavg = 0.96 2.33 1.36`
> `mem_available = 2,551,592 kB`（`grep MemAvailable /proc/meminfo`；本波期间峰值出现在两次私有 PC 构建时，见 §9）
> **写域声明**：`build/shims/Win32ShimResolver.cs`（V1）｜`src/WpfGfx.Linux/Windowing/X11Native.cs`（V2）｜`build/DirectWrite.Linux/WicClosedLoop/Program.cs`（V3）｜`build/MilBridge/tests/ResolverGuardProbe/**`（新红证探针）｜`build/MilBridge/V18A-report.md`（本文件）｜`$HOME/wfp-runs/w18-laneV18A/**`、`$HOME/w18a-build/**`（scratch/私有输出）。
> **本文件自身的 sha/size 由父车道现场复查**（`sha256sum build/MilBridge/V18A-report.md | cut -c1-16`、`stat -c '%s %y'`）—— 自指不可内嵌：任何一次落盘都会改它自己的 sha。
> **未碰**：`build/shims/PresentationCore.HbTextLine.cs`（世代绑定，`bc04c05ab6d8d82a` 逐位未变）｜`build/MilBridge/run.sh`｜`tests/**`｜`docs/**`｜`samples/**`｜`verify-all.sh`｜`known-red.json`｜`tline-gate.sh`｜`integration-wave.sh`｜**任何 `build/*.Linux/**` 权威产物**（§9 有 before/after 逐位对照）｜**未跑** `close-wave.sh`/`integration-wave.sh`/`publish-milbridge.sh`｜**未跑** `pkill`。

---

## 0. 一行判决

**V1/V2/V3 三件全部落地并（私有输出目录）`error CS = 0`；两条红证都成立 —— 修前"输掉竞态"是**整模块/整类型投毒**（实测 `TypeInitializationException` + `InvalidOperationException: A resolver is already set for the assembly.`），修后 (a) 抢先者映射同名 ⇒ **无害且可自证**（`SelfCheckShimVersion=1`），(b) 抢先者不映射我们的名字 ⇒ **响亮并点名**；非空泛检查成立（`libwpfwin32.so` 缺件时**照样硬失败**，且比修前更早更清楚）。**
**⚠️ 同时报三条会改变主控决策的发现**：① **模块初始化器不是加载期跑的**（`Assembly.LoadFrom` 之后外国解析器**装得上**）⇒ R17C §3-C1「外部安装者**只能输**」**被推翻**，产品丢竞态的路径是**可达**的（我按可达路径取的红证）；② **V2 的判据 (b) 在本机不可能响亮**（`libX11.so.6` 是系统可解析名 —— 证明见 §6，我按最诚实的口径实现并给出可达的响亮路径）；③ **V1 的守卫在正常路径上把 shim 提前 dlopen 了**（`/proc/self/maps` 0 → 5 条），这是预登记 §2 位移表**没预料到的一条**，主控要拍板保留还是收窄（§7，含现成的两行改法）。

---

## 1. 每个被编辑文件的 before/after（sha16 + size + mtime）+ 备份

备份目录：`$HOME/wfp-runs/w18-laneV18A/backup/`（`.before` = 编辑前逐字节副本；`.after` = 落地后逐字节副本；**每份都用 `cmp` 自证**）

| 件 | before sha16 | before size / mtime | after sha16 | after size / mtime | `cmp` 自证 |
|---|---|---|---|---|---|
| `build/shims/Win32ShimResolver.cs` | `ff3c53964cb8328b` | 24,117 / 2026-09-11 16:50:50 | **`37b65d0ede827650`** | 30,792 / 2026-09-16 14:55:31 | `cmp(after)=SAME`、`cmp(before)=DIFF` |
| `src/WpfGfx.Linux/Windowing/X11Native.cs` | `045faa9b0785f6d2` | 10,521 / 2026-09-10 16:11:54 | **`12d7cf8217b34c0c`** | 16,665 / 2026-09-16 14:55:45 | `cmp(after)=SAME`、`cmp(before)=DIFF` |
| `build/DirectWrite.Linux/WicClosedLoop/Program.cs` | `ef09e6e09e8e6f75` | 26,868 / 2026-09-10 19:54:18 | **`f7c7fd61ef5c8ad8`** | 28,709 / 2026-09-16 14:55:53 | `cmp(after)=SAME`、`cmp(before)=DIFF` |

```bash
$ for p in "build/shims/Win32ShimResolver.cs:Win32ShimResolver.cs" \
           "src/WpfGfx.Linux/Windowing/X11Native.cs:X11Native.cs" \
           "build/DirectWrite.Linux/WicClosedLoop/Program.cs:Program.cs"; do
    f=${p%%:*}; n=${p##*:}
    printf '%-60s before=%s after=%s cmp_after=%s cmp_before=%s\n' "$f" \
      "$(sha256sum $B/$n.before|cut -c1-16)" "$(sha256sum $f|cut -c1-16)" \
      "$(cmp -s $f $B/$n.after && echo SAME || echo DIFF)" \
      "$(cmp -s $f $B/$n.before && echo SAME || echo DIFF)"; done
build/shims/Win32ShimResolver.cs                   before=ff3c53964cb8328b after=37b65d0ede827650 cmp_after=SAME cmp_before=DIFF
src/WpfGfx.Linux/Windowing/X11Native.cs            before=045faa9b0785f6d2 after=12d7cf8217b34c0c cmp_after=SAME cmp_before=DIFF
build/DirectWrite.Linux/WicClosedLoop/Program.cs   before=ef09e6e09e8e6f75 after=f7c7fd61ef5c8ad8 cmp_after=SAME cmp_before=DIFF
```

**备份清单的边界（照实写）**：V1/V2 的 before sha **与 R17C 审计 §6 表里的值逐位相同**（`ff3c53964cb8328b` / `045faa9b0785f6d2`），V3 亦同（`ef09e6e09e8e6f75`）⇒ 这三件的 before 状态**有第三方留档可复核**，不是只有我这一份。
**⚠️ 一条旁证（顺手记录，不是本波判据）**：`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs` 现在的 sha16 = **`e393137a8309d4b8`**（12,808 B），而 R17C §6 表里记的是 `1f46443e86553876`（10,950 B）⇒ **R17C 落盘之后有人又改过那个文件**（§5-② 那段"已修"的描述基于当时的版本）。本波**未碰**它。

---

## 2. 设计：两处守卫 + V3 的取舍

### 2.0 一条把设计钉死的地基事实（本波实测，R17C 没做到）

**`[DllImport]` 走的是"声明它的那个程序集"的解析器**；**外部探针程序集里写的 `[DllImport]` 不会**走目标程序集的解析器。⇒ "用真 `[DllImport]` 自证"这件事**只能在目标程序集内部做**（测试侧 `X11Guard` 之所以有效，正是因为安装点与自证**同程序集**）。这决定了红证探针的形态：**必须调用产品安装点本身的代码**（反射取 `<Module>` 的 `[ModuleInitializer]` / 触发类型静态构造），让自证在目标程序集里执行。

### 2.1 V1 · `build/shims/Win32ShimResolver.cs`（`[ModuleInitializer]`，编进四个程序集）

**改动量**：`+87 / −2` 行（412 → 497 行）。落地后的 `Register()`（逐字）：

```csharp
        [ModuleInitializer]
        internal static void Register()
        {
            bool installedByUs = false;
            try
            {
                NativeLibrary.SetDllImportResolver(
                    typeof(Win32ShimResolver).Assembly, Resolve);
                installedByUs = true;
            }
            catch (InvalidOperationException)
            {
                // 本程序集的解析器槽位已被别人占用（竞态的另一方赢了）。合法状态 ⇒ 不在这里抛，
                // 但**立刻自证**（下面那段）——否则就变成了 `D-R2` 那种"静默吞"。
                ResolverConflict = true;
            }

            // ---- 自证：用**真的 `[DllImport]`** 走一次 ----
            try
            {
                SelfCheckShimVersion = ShimVersionViaUser32();
            }
            catch (EntryPointNotFoundException)
            {
                SelfCheckShimVersion = -1;      // 库解析成功、只是导出名不同 ⇒ 映射已生效
            }
            catch (DllNotFoundException ex)
            {
                if (!installedByUs)
                    throw new InvalidOperationException("WPF-on-Linux: 本程序集的 'user32.dll' 解析不到 —— **当前生效的解析器不是我们这一个**。…", ex);
                throw new DllNotFoundException("WPF-on-Linux: Win32 shim 映射自证失败 —— … 'user32.dll' 解析不到 ⇒ libwpfwin32.so 缺失或不可加载。…", ex);
            }
        }

        [DllImport("user32.dll", EntryPoint = "WpfLinuxWin32_ShimVersion")]
        private static extern int ShimVersionViaUser32();

        internal static bool ResolverConflict { get; private set; }
        internal static int SelfCheckShimVersion { get; private set; }
```

- **为什么自证选 `user32.dll` 上的 `WpfLinuxWin32_ShimVersion`**：该导出在 shim 里真实存在（`src/WpfGfx.Linux.Native/src/win32_exports.c:93` `int WpfLinuxWin32_ShimVersion(void) { return WPFWIN32_SHIM_VERSION; }`；`src/WpfGfx.Linux.Native/bin/exports.txt:428` 有它），**无参数、无副作用**，回值 = 版本号（实测 `1`）；而 `user32.dll` 在 Linux 上**默认探测解析不到** ⇒ 这条 DllImport **只有"生效的解析器"能救** ⇒ 天然是"赢家映射不映射我们的名字"的判据（与 `X11Guard.cs:200-208` 的 `User32MapsToShim()` 同口径）。
- **为什么 `installedByUs` 分两条路**：`!installedByUs` 时解析不到 = **赢家不映射**（点名）；`installedByUs` 时解析不到 = **我们自己装的但 shim 缺件**（装置缺件，照样硬失败，**不许被守卫吞掉**）。
- **既有注释的措辞更正（原意保留）**：`Resolve` 里 T1 那段「为什么挂在这里而不是自己再装一个解析器」（编辑后 `:268-275`）加了 4 行更正行，说明"输的那个抛未捕获异常"这句要读成**别人**再装一个；`TryResolve` 的设计（不自己装、只暴露组合入口）**一行未动、照旧成立**。

### 2.2 V2 · `src/WpfGfx.Linux/Windowing/X11Native.cs`（静态构造）

**改动量**：`+91 / −1` 行（216 → 306 行）。同款两段式：

```csharp
        static X11Native()
        {
            bool installedByUs = false;
            try { NativeLibrary.SetDllImportResolver(typeof(X11Native).Assembly, X11LibraryResolver.Resolve); installedByUs = true; }
            catch (InvalidOperationException) { ResolverConflict = true; }   // 合法状态 ⇒ 不抛；但立刻自证

            if (X11NameResolves()) { SelfCheckX11NameResolved = true; return; }

            if (!installedByUs)
                throw new InvalidOperationException("WPF-on-Linux: 本程序集的 'libX11.so.6' 解析不到 —— **当前生效的解析器不是我们这一个**。…");
            throw new DllNotFoundException("WPF-on-Linux: libX11 自证失败 —— … '" + LibraryName + "' 解析不到 ⇒ libX11 缺失或不可加载。…" + X11LibraryResolver.LoadError);
        }

        [DllImport(LibraryName, EntryPoint = "WpfLinuxX11__SelfCheck_NoSuchExport")]
        private static extern void SelfCheckProbe();

        private static bool X11NameResolves()
        {
            try { SelfCheckProbe(); return true; }
            catch (EntryPointNotFoundException) { return true; }   // 库解析成功、只是导出名不同
            catch (DllNotFoundException) { return false; }
        }

        internal static bool ResolverConflict { get; private set; }
        internal static bool SelfCheckX11NameResolved { get; private set; }
```

- **为什么自证用"故意不存在的导出名"而不是调真导出**：Xlib 里**没有**"无参数、无副作用"的现成函数（`XOpenDisplay` 要连 server、`XSetErrorHandler` 会改全局状态…），而"导出名不存在"能让运行时**在库解析成功之后**立刻抛 `EntryPointNotFoundException`，**恰好把"库解析"这一步单独隔离出来**，且**绝不执行任何本地代码**。
- **边界（写死，见 §6）**：`libX11.so.6` 是**系统可解析名** ⇒ 本自证回答的是"**我们的名字解析得到吗**"，**不是**"生效的解析器是不是我们这一个"（后者在本机对该名字**不可判**）。

### 2.3 V3 · `build/DirectWrite.Linux/WicClosedLoop/Program.cs` —— **选了"删掉 + 写明理由"**

**改动量**：`+35 / −24` 行（`Program.cs` 114-155 一段重写 + 删一个字段）。落地后的形态：

```csharp
    private static void InstallWicResolver(string shimPath)
    {
        Console.WriteLine("RESOLVER_INSTALLED=N/A (product-side owns the slot)");
        Console.WriteLine("RESOLVER_NOTE=本 harness 刻意不自装 PresentationCore 的解析器：…SHIM=" + shimPath);
    }
```

**依据（三条，全部可复核）**：
1. **它不可能赢**：`Main` 的 `typeof(BitmapImage)`（原 `:122`）是**触碰 PC 模块里的一个类型** ⇒ PC 的 `[ModuleInitializer]` 先跑、槽位归 PC；实测留档 `build/DirectWrite.Linux/REPORT.md:1021` 逐字 `RESOLVER_INSTALLED=False  InvalidOperationException: A resolver is already set for the assembly.`。
2. **第二条出路（"只补 PC 没映射的名字"）不成立**：本 harness 只映射 `WindowsCodecs.dll`，而 PC 侧 `WicMappedLibraries`（`Win32ShimResolver.cs:107-124`）**已经**映射 `WindowsCodecs.dll` 与 `ole32.dll` 且**默认启用**（`:152 WicEnabledByDefault = true`；解析分支 `:216-241`）⇒ **差集是空集**。删掉 ≡ 补空集，但少一份会漂移的重复策略（`D-R2` 的定案："每个程序集只留唯一安装点"，见 `DP1ReproTests.cs` 那次删除）。
3. **删掉不改变任何实际行为**：harness 的 `_shimPath`（`Main` `:65-67`）与 PC 侧候选序**同源**（同一个 `WPF_LINUX_WIC_SHIM`）⇒ "两侧 dlopen 同一个文件"那条不变量**照旧**由 PC 侧落点保证。
   顺带删掉 `_resolverInstalled`：我**独立复核**了 R17C 的"只写不读"—— `grep -n '_resolverInstalled' build/DirectWrite.Linux/WicClosedLoop/Program.cs` 全仓只有**声明 + 赋值**两行（无读点）。
**编译器独立确认了这条依据**：把该文件换回 `.before` 用**全新 obj 目录**重编 ⇒ `warning CS0414: 字段"Program._resolverInstalled"已被赋值，但从未使用过它的值`（`Program.cs(51,25)`）——这正是 R17C §3-C1/F3 说的"只写不读"，而删掉它即消警（修后只剩既存的 `CA2022`，见 §4）。⇒ 顺带说明：**修前**这个 harness 工程本来就不满足"0 错 0 警"。

**留下的可断言面**：R17C 的 **F3**（断言 `WindowsCodecs.dll` 确实由 PC 侧接管、且 `dlopen` 到的就是 `_shimPath`）**本波未做**（属宿主侧、产物无关）⇒ 见 §10。

---

## 3. 修前的失败形态（红证 part A，全部实测）

**探针**：`build/MilBridge/tests/ResolverGuardProbe/`（新工程，`ResolverGuardProbe.csproj` `f303d8cfc0b638bd`、`Program.cs` `cdacfbdd5077ace7`、私有构建产物 `ee038e44203c0a8e`）。**套件脚本**：`$HOME/wfp-runs/w18-laneV18A/probe-set.sh`（`831cbed329965c19`）。日志：`prefix.log`（`2bc1eacbe0534c32`，修前/权威件）、`postfix.log`（`4359f3dda5cc4dc9`，修后/私有件）。

### 3.1 **顺序性事实：模块初始化器不是加载期跑的**（这是本波最值钱的一条）

```bash
$ dotnet $HOME/w18a-build/probe-bin/Debug/net10.0/ResolverGuardProbe.dll order1 \
    build/PresentationCore.Linux/bin/Debug/PresentationCore.dll
LOADED=PresentationCore, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35
STEP=after-load
FOREIGN_INSTALL=OK variant=replica          ← 槽位**是空的** ⇒ PC 的模块初始化器**还没跑**
RESULT=DONE   rc=0
```

⇒ **`Assembly.LoadFrom(pc)` 之后，外部安装者装得上。** 同一读数在**修后**的私有 PC 上也一样（`postfix.log` §A，两次 `FOREIGN_INSTALL=OK`，`--loadstream` 与 `LoadFrom` 两条腿都是）。
这与 R17C §3-C1 的推论（「`SetDllImportResolver` 需要 `Assembly` 对象 ⇒ 必须先把模块加载 ⇒ `[ModuleInitializer]` 已经跑完 ⇒ **外部安装者只能输**」）**冲突**：**加载 ≠ 跑初始化器**。R17C 那次观测（`REPORT.md:1021`）之所以是"宿主输"，是因为 `WicClosedLoop` 走的是 `typeof(BitmapImage)`（**触碰类型**）而不是 `Assembly.LoadFrom`。**⇒ 产品丢竞态是可达的，不是"只靠一个被观察到的性质撑着"的纯理论风险**；本波的红证就是按这条可达路径取的。
（**"首次触碰类型时才跑"这一半**：我原打算用 `order2/order3` 取，但权威 `WindowsBase.dll` 在裸 `net10.0` 宿主里 `Assembly.LoadFrom` 必失败（见 §10-③），`order2/order3` 的 `GetType(…BitmapImage)` 会先撞上那个夹具问题 ⇒ **只取到"加载期不跑"这半边**，另一半**未取**。）

### 3.2 V1（PC）· 修前 · 外国解析器抢先 + 自然路径触发

```bash
$ dotnet …/ResolverGuardProbe.dll v1 build/PresentationCore.Linux/bin/Debug/PresentationCore.dll replica --loadstream
FOREIGN_INSTALL=OK variant=replica
TRIGGER_TYPE=WpfLinux.Shims.PresentationCore.Win32ShimResolver
TRIGGER=natural THROW System.Reflection.TargetInvocationException: … | inner=System.TypeInitializationException: The type initializer for '<Module>' threw an exception.
POISON_RECHECK=THROW … inner=System.TypeInitializationException: The type initializer for '<Module>' threw an exception.
DIAG_ResolverConflict=NOINFO property-absent
DIAG_SelfCheckShimVersion=NOINFO property-absent
RUNMODULECTOR=THROW System.TypeInitializationException: The type initializer for '<Module>' threw an exception.
  | inner=System.InvalidOperationException: A resolver is already set for the assembly.
rc=0
```

同一个读数在 **WindowsBase / UIAutomationTypes / UIAutomationProvider** 三件上**逐字相同**（`prefix.log` §B，共 4 件 × 4 变体 = 16 趟）。`variant=different`、`variant=broken` 的**修前**结果与 `replica` **逐字相同**（`RUNMODULECTOR=THROW … A resolver is already set for the assembly.`）⇒ **预登记要求"今天两个变体都抛"成立**。
**类型/模块确实被毒化**：`POISON_RECHECK=THROW`（再碰一次仍抛）+ 自然触发的 `GetMethod("IsWicMappingEnabled")` 也抛 ⇒ 不是"一条调用失败"，是**整个模块**。

### 3.3 V2（`WpfGfx.Linux`）· 修前 · 四种变体

```bash
$ dotnet …/ResolverGuardProbe.dll v2 src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll replica
X11NATIVE_FOUND=True   X11NATIVE_HAS_CCTOR=True
FOREIGN_INSTALL=OK variant=replica
CCTOR_THROW=System.TypeInitializationException: The type initializer for 'WpfGfx.Linux.Windowing.X11Native' threw an exception.
  | inner=System.InvalidOperationException: A resolver is already set for the assembly.
POISON_RECHECK=THROW … （同一条）
rc=0
```

`none` 臂：`CCTOR_RESULT=NO_THROW`（对照组）；`replica`/`different`/`broken` 三臂：**逐字相同的 `CCTOR_THROW`** ⇒ 修前四变体结论 = **除对照外全抛**。

### 3.4 rc 分类（纪律 21/27/28）

探针自身的 `rc` 一律 `0`：**它把被测现象（异常）当读数打印**，不把"产品抛异常"当自己的失败。`rc=134` 出现过两次，是**夹具**问题（`Assembly.LoadFrom(WindowsBase.dll)` 的 `FileLoadException`，见 §10-③），已在脚本里换成 `--loadstream` 腿；`rc≠0` 在这套探针里**没有**被当作判据。

---

## 4. 编译证据（纪律 33：`--check` 通过 ≠ 编得过）

**全部走私有输出目录**（不写权威 `bin/obj`；`WpfGfx.Linux` 与 `WicClosedLoop` 因为用 SDK 默认 glob，必须额外 `-p:DefaultItemExcludes='obj/**'`，否则会把**权威 `obj/` 里的生成物**当源码再编一遍 ⇒ `CS0579 特性重复`，实测踩过）：

```bash
export PATH="$HOME/.dotnet:$PATH"
D=$HOME/w18a-build
dotnet build build/WindowsBase.Linux/WindowsBase.Linux.csproj        -c Debug -m:1 --nologo -p:BaseOutputPath=$D/WindowsBase.Linux-bin/        -p:BaseIntermediateOutputPath=$D/obj-WindowsBase.Linux/
dotnet build build/UIAutomationTypes.Linux/UIAutomationTypes.Linux.csproj -c Debug -m:1 --nologo -p:BaseOutputPath=$D/UIAutomationTypes.Linux-bin/ -p:BaseIntermediateOutputPath=$D/obj-UIAutomationTypes.Linux/
dotnet build build/UIAutomationProvider.Linux/UIAutomationProvider.Linux.csproj -c Debug -m:1 --nologo -p:BaseOutputPath=$D/UIAutomationProvider.Linux-bin/ -p:BaseIntermediateOutputPath=$D/obj-UIAutomationProvider.Linux/
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Debug -m:1 --nologo -p:BaseOutputPath=$D/pc-bin/ -p:BaseIntermediateOutputPath=$D/obj-pc/
dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj -c Debug -m:1 --nologo -p:BaseOutputPath=$D/wpfgfx-bin/ -p:BaseIntermediateOutputPath=$D/obj-wpfgfx/ -p:DefaultItemExcludes='obj/**'
dotnet build build/DirectWrite.Linux/WicClosedLoop/DirectWrite.Linux.WicClosedLoop.csproj -c Debug -m:1 --nologo -p:BaseOutputPath=$D/wic-post-bin/ -p:BaseIntermediateOutputPath=$D/obj-wic-post/ -p:DefaultItemExcludes='obj/**'
```

| 工程 | 结果 | 私有产物 sha16 / size / mtime |
|---|---|---|
| WindowsBase.Linux | **0 错 0 警** | `4b0d449a4df0b120` / 1,242,624 / 14:57:55 |
| UIAutomationTypes.Linux | **0 错 0 警** | `404d8474b790ce68` / 229,376 / 14:58:13 |
| UIAutomationProvider.Linux | **0 错 0 警** | `70e6c3b81341beb3` / 43,008 / 14:58:17 |
| PresentationCore.Linux | **0 错 0 警** | `0371b34691dbbc47` / 4,196,864 / 14:59:03 |
| WpfGfx.Linux | **0 错 0 警** | `b8a959cdbc4f814a` / 359,424 / 14:57:40 |
| WicClosedLoop（V3） | **0 错**，1 条 `CA2022`（**比修前少一条**，见下） | `0a078e2f7bea2192` / 24,064 /（`$D/wic-post-bin`） |

**编译读数两极化（**既存**告警，且我的改动**减少**一条）** —— 把 V3 的文件换回 `.before`、用**全新 obj 目录**重编（`logs/build-wic-prefix-clean.log`）：

```text
（修前：2 个警告 / 0 个错误）
Program.cs(51,25):  warning CS0414: 字段“Program._resolverInstalled”已被赋值，但从未使用过它的值
Program.cs(320,52): warning CA2022: 避免使用“System.IO.FileStream.Read(byte[], int, int)”进行不准确读取
（修后：1 个警告 / 0 个错误）
Program.cs(331,52): warning CA2022: 避免使用“System.IO.FileStream.Read(byte[], int, int)”进行不准确读取
```

- **`CS0414` 是编译器独立确认了 R17C 的"只写不读"**（R17C §3-C1/F3 说 `_resolverInstalled` 只写不读、`catch` 里的"丢竞态"从来没被断言过）⇒ 这正是**本波删掉它**的直接依据，且**删掉即消警**（修后不再有 CS0414）。⇒ 顺带说明：**修前** `WicClosedLoop` 这个工程本来就不满足"0 错 0 警"。
- **`CA2022` 是既存告警**，两处行号（320 → 331）只因我新增 11 行而位移，调用点是同一个未触碰的 `using (FileStream fs = File.OpenRead(png)) fs.Read(head, 0, head.Length);`（`Program.cs:331`）。
- **⚠️ 顺带抓到一次自己的仪器错误（记档）**：第一次做这个对照时我用**同一个 obj 目录**重编 ⇒ MSBuild 的**增量判断**（`cp -p` 保留了旧 mtime < 产物 mtime）直接跳过编译、打出"0 警告"的**假读数**；换全新 obj 目录后才看到真值（CS0414 + CA2022）。⇒ "编译读数也必须防增量"。

**最终一遍复检（字面 `error CS = 0`，日志留在 `$HOME/w18a-build/logs/final-*.log`）**：

```text
WindowsBase.Linux        rc=0 errorCS=0  0 个警告  0 个错误
UIAutomationTypes.Linux  rc=0 errorCS=0  0 个警告  0 个错误
UIAutomationProvider.Linux rc=0 errorCS=0  0 个警告  0 个错误
PresentationCore.Linux   rc=0 errorCS=0  0 个警告  0 个错误
WpfGfx.Linux             rc=0 errorCS=0  0 个警告  0 个错误
```

**⚠️ 一条会影响"私有构建 sha 能不能跨车道对拍"的仪器事实（本轮实测+定因）**：把**同一份源码**编到不同输出目录，`pc` 的 sha **不一样**（`$D/pc-bin` = `0371b34691dbbc47` vs `$D/PresentationCore.Linux-bin` = `22e3cad04c28f0f7`，两者 size 都是 4,196,864）。定因实验：**同 obj 路径、换 bin 目录 ⇒ sha 相同**（`0371b34691dbbc47` 复现两次）；**换 obj 路径 ⇒ sha 变**；且 `grep -aoc 'obj-pc' pc-bin/…/PresentationCore.dll` = **1**（另一个件里是 `obj-PresentationCore.Linux` = 1）⇒ **中间目录的路径被嵌进产物**（嵌入 PDB 里那条生成 `AssemblyInfo.cs` 的路径）。
⇒ **口径**：私有构建的 sha **只在"同 obj 路径"下才可复现/可对拍**；本报告引用的私有 `pc` 读数一律挂在 `$D/obj-pc` + `$D/pc-bin/Debug/PresentationCore.dll` = **`0371b34691dbbc47`**（mtime 14:59:03）这一对路径上；各日志头部逐字记了 target 的 sha16/size/mtime（`postfix.log:5-9`）。

**产物级两极化正对照（证明"确实编进去了"，不是靠源文件自证）**：

```bash
$ grep -aoc 'SelfCheckShimVersion' <dll>   # V1 新增的 ASCII 标记（#Strings 堆）
PresentationCore.dll|0371b346  1      PresentationCore.dll|df6dbb1c  0     ← 私有(修后) vs 权威(修前)
WindowsBase.dll|4b0d449a       1      WindowsBase.dll|e6216fe9       0
UIAutomationTypes.dll|404d8474 1      UIAutomationTypes.dll|2ac8d37b 0
UIAutomationProvider|70e6c3b8  1      UIAutomationProvider|352ccd75  0
$ grep -aoc 'WpfLinuxX11__SelfCheck_NoSuchExport' <dll>   # V2
WpfGfx.Linux.dll|b8a959cd 1           WpfGfx.Linux.dll|0c597fb6       0
```

---

## 5. 修后的红证（part B）：(a) 无害 / (b) 响亮点名 / 非空泛

**判据口径（写死）**：
- **(a) 无害** = 产品安装点**不抛**、类型/模块**不毒化**、并且**自证证明名字解析得到**；
- **(b) 响亮** = **抛**，且消息**点名"当前生效的解析器不是我们这一个"**。

| # | 件 | 变体（抢先者） | 修前 | 修后 | 判定 |
|---|---|---|---|---|---|
| 1 | PC/WB/UIAutomationTypes/UIAutomationProvider | `none`（对照） | `NO_THROW` | `TRIGGER=natural NO_THROW IsWicMappingEnabled=True`、`ResolverConflict=False`、**`SelfCheckShimVersion=1`** | **正常路径可用**（判据①，真 `[DllImport]` 调用成功） |
| 2 | 同上 4 件 | **(a) replica**（映射同一批 6 个名字 → `libwpfwin32.so`） | `TypeInitializationException`(+IOE) | **`TRIGGER=natural NO_THROW`**、`ResolverConflict=True`、**`SelfCheckShimVersion=1`** | **(a) 无害 ✓**（且 `SelfCheckShimVersion=1` 证明赢家接到的是**我们的 shim**） |
| 3 | 同上 4 件 | **(b) different**（只映射 `hostonly.dll`，一个我们的名字都不接） | `TypeInitializationException`(+IOE) | **抛**，inner = `InvalidOperationException: WPF-on-Linux: 本程序集的 'user32.dll' 解析不到 —— **当前生效的解析器不是我们这一个**。…（列全 6 个名字 + 后果 + 两条修法）` | **(b) 响亮且点名 ✓** |
| 4 | 同上 4 件 | **broken**（接我们的名字、但指向不存在路径） | `TypeInitializationException`(+IOE) | **抛**，同上点名消息 | ✓ |
| 5 | `WpfGfx.Linux` | `none` | `CCTOR_RESULT=NO_THROW` | `CCTOR_RESULT=NO_THROW`、`ResolverConflict=False`、**`SelfCheckX11NameResolved=True`** | 正常路径 ✓ |
| 6 | `WpfGfx.Linux` | **(a) replica**（`libX11.so.6` → 系统 libX11） | `CCTOR_THROW`(+IOE) | **`CCTOR_RESULT=NO_THROW`**、`ResolverConflict=True`、`SelfCheckX11NameResolved=True` | **(a) 无害 ✓** |
| 7 | `WpfGfx.Linux` | **(b) different** | `CCTOR_THROW`(+IOE) | **`CCTOR_RESULT=NO_THROW`**、`ResolverConflict=True`、`SelfCheckX11NameResolved=True` | **无害 + 记诊断位**（**不是**响亮 —— **判据 (b) 在本机不可达**，证明见 §6） |
| 8 | `WpfGfx.Linux` | **broken**（`libX11.so.6` → 不存在路径） | `CCTOR_THROW`(+IOE) | **抛**，inner = `InvalidOperationException: WPF-on-Linux: 本程序集的 'libX11.so.6' 解析不到 —— **当前生效的解析器不是我们这一个**。…` | **真有害的那一类：响亮且点名 ✓** |

**非空泛检查（"守卫不许吞掉真缺件"）—— 四种变体之外的两条**：

```bash
# ⓪ 装置缺件：把 target 的**整目录**（依赖带齐、**故意不带 shim**）抄到一个没有仓库回退的隔离目录里跑
$ ls -l $ISO/libwpfwin32.so
ls: 无法访问 '…/isolated-postfix/libwpfwin32.so': 没有那个文件或目录
$ cd $ISO && dotnet …/ResolverGuardProbe.dll v1 $ISO/PresentationCore.dll none
TRIGGER=natural NO_THROW IsWicMappingEnabled=True        ← **修前**：模块初始化器**什么都没发现**
RUNMODULECTOR=NO_THROW
```
```bash
# 修后（同一夹具、只是换了修后件）
TRIGGER=natural THROW … inner=System.TypeInitializationException: The type initializer for '<Module>' threw an exception.
RUNMODULECTOR=THROW System.TypeInitializationException: …
  | inner=System.DllNotFoundException: WPF-on-Linux: Win32 shim 映射自证失败 —— 本程序集装的是**我们的**解析器，
    但 'user32.dll' 解析不到 ⇒ libwpfwin32.so 缺失或不可加载。
    原始诊断（含候选路径逐条）：WPF-on-Linux: 'user32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库。
    搜索过程：· 不存在 …/libwpfwin32.so  修复：先构建 shim —— src/WpfGfx.Linux.Native/build-shim.sh --all；…
```

⇒ **缺件不会被吞**（修后比修前**更早、更点名**；这正是"判据只许变强"），且 `broken` 变体（§5 表 #4/#8）是第二条独立的正对照。

**"恢复逐字节"证明**：本节的非空泛检查**没有改动仓库里任何文件**（用的是**隔离目录**里的副本 + 探针自己的外国解析器）⇒ 无需恢复。真正被**临时**换过的是 V3 的 `Program.cs`（§4 的 CA2022 两极化对照）：换回 `.before` 编译后已还原，并给出 `cmp(after)=SAME` 与 `sha16` 双证（§1 表 + §4 命令）。

---

## 6. **被推翻的判据**：V2 的 (b) 在本机**不可能响亮**（附证明与我的取舍）

预登记 §1 V2 判据③要求"抢先者不映射我们的名字 ⇒ 抛且消息点名"。**这一条对 V2 无法与 (a) 区分**，理由是硬的：

1. **本机 `libX11.so.6` 是系统可解析名**（`/sbin/ldconfig -p | grep libX11`）：`libX11.so.6 (libc6,x86-64) => /lib/x86_64-linux-gnu/libX11.so.6`、`libX11.so (libc6,x86-64) => /lib/x86_64-linux-gnu/libX11.so`。⇒ 抢先者**不**映射它时，**默认探测照样把库接上**，产品功能不受影响。
2. **产品侧可观察的面完全由"名字解析得到吗"决定**：
   - (a) 抢先者映射同名 → `DllImport("libX11.so.6")` 成功；
   - (b) 抢先者映射别的名字 → 抢先者返回 `IntPtr.Zero` → 默认探测 → **也成功**。
   ⇒ 对 V2 的产品代码而言，(a) 与 (b) 的**可观察输入完全相同**；唯一能区分两者的办法是"用一个**只有我们的解析器**能解析的探针名字"（sentinel）。而那样的守卫会在**真实的无害场景**里误报 —— 即"别人好心装了同一映射（例如把 `libX11.so.6` 指到同一个系统库）"，被我们判成响亮失败，与 `D-R2` 的定案（"输了竞态不算失败，因为'已经有人接这个名字'本身是合法状态"）直接冲突。
3. **我选的语义（最诚实的一种）**：**响亮 ⟺ 我们的名字解析不到**。于是
   - (a) 无害 ✓（实测 `CCTOR_RESULT=NO_THROW`）；
   - (b) **无害 + 具名诊断**（`ResolverConflict=True`，可读、不静默，但**不抛**）—— **判据 (b) 被本报告推翻，不是被绕开**；
   - **真正有害的那一类**（抢先者接名字但接到不可加载的位置）**会响亮点名** ✓（§5 #8 实测）。
4. **代价与补救**：如果主控要**逐字**满足"任何非我们的解析器 ⇒ 响亮"，做法是给 `X11LibraryResolver` 加一个 sentinel 名并让自证探它 —— **本波不推荐**（会误报）。若主控坚持，改动很小，但必须在预登记里把 (a) 的定义改成"映射**含 sentinel 的**同一批名字"，否则两条判据互斥。

---

## 7. 我发现了**预登记位移表没预料到**的一条位移（V1 正常路径 eager dlopen）

V1 的守卫在**正常路径**上也做一次真 `[DllImport]` 自证（预登记 §1 的字面要求："并紧跟一次自证"）⇒ 模块初始化器**会立刻把 shim 载进来**（修前是懒加载）。取证（`/proc/self/maps`，不看文案）：

```bash
$ dotnet …/ResolverGuardProbe.dll mapload build/PresentationCore.Linux/bin/Debug/PresentationCore.dll   # 修前（权威）
MAPS_WPFWIN32_BEFORE=0
TRIGGER=natural IsWicMappingEnabled=True
MAPS_WPFWIN32_AFTER=0                      ← 模块初始化器跑完，shim **没有**被映射
$ dotnet …/ResolverGuardProbe.dll mapload $HOME/w18a-build/pc-bin/Debug/PresentationCore.dll          # 修后（私有）
MAPS_WPFWIN32_AFTER=5                      ← 5 条映射，路径 = src/WpfGfx.Linux.Native/bin/libwpfwin32.so
```

**含义（分开写，不许混）**：
- **不会**改变任何判据**数值**：多出来的是**同一个 `.so` 的提前 dlopen**（该 .so 的 `INIT_ARRAY` 只有 16 字节、源码里**没有** `__attribute__((constructor))`/`atexit`/打印，`grep` 证据在本轮读数里）；文本/图像类读数与它无关。**但这是推论，不是读数** —— 五臂/应用门禁的逐位对照只有主控在**波后产物**上重跑才算数。
- **会**改变两件实事：① **dlopen 时刻**（首启模块 → 首个真 P/Invoke）；② **缺件时的失败时刻**（修前"装完啥都不说"、修后"装的时候就响亮"——§5 的隔离目录对照就是这条）。
- **风险面**：任何"加载 PC/WB/UIAutomation* 但从不调 user32"的进程，现在**也需要 shim 可定位**。树内**总能**定位（仓库回退：`EnumerateCandidates` 从 `AppContext.BaseDirectory` 与 cwd 逐级向上找 `src/WpfGfx.Linux.Native/bin/`；我这次的隔离夹具正是靠"把整目录搬到 `<repo>` 之外"才把它变成缺件）。
- **主控可选的收窄（现成两行，我没有擅自采用）**：把自证**只在输掉竞态时**做（`catch` 分支里），正常路径**一位不改**：

```diff
-            // ---- 自证：用**真的 `[DllImport]`** 走一次 ----
-            try { SelfCheckShimVersion = ShimVersionViaUser32(); }
+            // ---- 自证：**只在输掉竞态时**做（正常路径保持修前的懒加载语义，零位移）----
+            if (installedByUs) return;
+            try { SelfCheckShimVersion = ShimVersionViaUser32(); }
```
  **代价（写清楚）**：判据①（正常路径真 `[DllImport]` 成功）与判据④（shim 缺件 ⇒ 在**安装点**响亮）就不再由守卫本身行使（缺件仍会在首个真 P/Invoke 处**响亮且带候选路径**地失败，那是**修前**的既有行为）。**本报告按预登记字面选了"无条件自证"**，并如实登记这条位移；**要收窄请主控一句话**，我或下一车道按上面两行改。

---

## 8. 另一条给主控的落地缺口：`WpfGfx.Linux` **不在**波的重建表里

预登记 §2 预测 `WpfGfx.Linux.dll`（非九位可见位）**会变**。但波的 `integration-wave.sh`（`close-wave.sh` 的第 1 步）`ORDER=(…)` 逐字是
`System.Xaml.Linux / WindowsBase.Linux / …Provider.csproj / DirectWriteForwarder.Linux / UIAutomationTypes.Linux / System.Windows.Input.Manipulations.Linux / UIAutomationProvider.Linux / PresentationCore.Linux / System.Printing.Linux / CycleStub.* / ReachFramework.Linux / PresentationFramework.Linux / ReachFramework.Linux` —— **里面没有 `WpfGfx.Linux` 这一项**；`close-wave.sh` 也只把它当**输入指纹**（`find src/WpfGfx.Linux -type f -name '*.cs'`），不重建它。桥那边会经 `MilBridge.Linux.csproj:50` 的 `ProjectReference` 以 **Release** 建一份（供 AOT），而**权威可见位是 `src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll`**（`CURRENT-STATE.md` §1 记 `0c597fb6ec1eec70`、mtime `2026-09-15`，**`#16`/`#17` 都没动过它**）。
⇒ **若不显式建它，波后会出现"桥里是修后的、可见位是修前的"** —— 本波**必须**加一步（见 §9 的命令）。

---

## 9. 读数表（纪律 32）

| 项 | 值 |
|---|---|
| `lane` | **V18A** |
| 时刻 | 落地 `2026-09-16T14:55:31…14:55:53+0800`；读数 `2026-09-16T15:01:41+0800` = `T07:01:41Z` |
| `kernel` | `6.8.0-138-generic`（x86_64, VirtualBox） |
| `loadavg` | 读数时 `0.96 2.33 1.36`（探针套件期间最高观测 `2.62 2.91 1.45`） |
| `mem_available` | 读数时 `2,551,592 kB`（探针套件期间最低观测 `2,356,012 kB`，出现在两次私有 PC 构建附近） |
| 探针（新） | `build/MilBridge/tests/ResolverGuardProbe/Program.cs` = `cdacfbdd5077ace7`（22,258 B）；`ResolverGuardProbe.csproj` = `f303d8cfc0b638bd`（2,206 B）；二进制 `ee038e44203c0a8e`（18,432 B） |
| 套件脚本 | `$HOME/wfp-runs/w18-laneV18A/probe-set.sh` = `831cbed329965c19`（2,975 B） |
| 修前日志 | `$HOME/wfp-runs/w18-laneV18A/prefix.log` = **`e1e863738df59fae`**（32,397 B） |
| 修后日志 | `$HOME/wfp-runs/w18-laneV18A/postfix.log` = **`573add8e5f45c594`**（43,016 B） |
| 日志的**可复现性**（两趟独立跑） | 上一版探针二进制跑出的两份留档：`prefix.probe-v1.log` = `2bc1eacbe0534c32`、`postfix.probe-v1.log` = `4359f3dda5cc4dc9`；与上表两份**逐字节只差 `PID=`/`# when=` 两行**（`diff` 排除这两行后**空**）⇒ 读数可复现。 |
| 我实现的预登记那一版 | `docs/WAVE18-PREREGISTRATION.md` = **`c7dfe75d7f7da4cf`**（9,317 B、90 行、mtime 2026-09-16 14:47:07 —— 与 R17C 审计 `d5062f8b95369574` 一样，都是本车道开工前最后落盘的那一版；本波期间**未再变**，已现场重读关键三段：`:29`（"并紧跟一次自证"）、`:31`（判据①-④）、`:37`（V3 两条出路）逐字仍在） |
| 备份 | `backup/{Win32ShimResolver.cs,X11Native.cs,Program.cs}.{before,after}`（sha 见 §1） |

**权威产物在整轮前后逐位未变（并发规则 + 未重建权威产物的证据）**：

| 位 | sha16 | size | mtime |
|---|---|---|---|
| `pc` `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `df6dbb1c2bfb4162` | 4,195,328 | 2026-09-16 12:42:08 |
| `windowsbase` `build/WindowsBase.Linux/bin/Debug/WindowsBase.dll` | `e6216fe961a2bfb9` | 1,241,088 | 2026-09-16 12:41:42 |
| 可见位 `build/UIAutomationTypes.Linux/bin/Debug/UIAutomationTypes.dll` | `2ac8d37b7cdc5afd` | 227,840 | 2026-09-16 12:41:47 |
| 可见位 `build/UIAutomationProvider.Linux/bin/Debug/UIAutomationProvider.dll` | `352ccd757a2f2fb0` | 41,472 | 2026-09-16 12:41:51 |
| 可见位 `src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` | `0c597fb6ec1eec70` | 357,888 | 2026-09-15 12:38:40 |
| `bridge` `…/wpfgfx_cor3.so` | `caf7baf9e67719aa` | 4,983,696 | 2026-09-15 12:43:18 |
| **`shim`（世代绑定）** `build/shims/PresentationCore.HbTextLine.cs` | **`bc04c05ab6d8d82a`** | 275,765 | 2026-09-15 18:25:25 ⇒ **本波未动** ✓ |

**主控要跑的权威重建命令（我不跑）**：
```bash
export PATH="$HOME/.dotnet:$PATH"
bash build/close-wave.sh                 # 内部：integration-wave（按 ORDER 重建 WB/UIAutomation*/PC…）
                                         # → native shim（源码未动 ⇒ 应判"无需重建"）→ **桥重发**
                                         #   （build/bridge-src-fp.sh 的 BRIDGE_SRC_FP 因 src/WpfGfx.Linux/** 变化而变
                                         #    ⇒ 走 build/publish-milbridge.sh）→ 身份四件套 → verify-all
# ⚠️ §8 的缺口：上面**不会**建 Debug 的可见位 —— 必须显式补这一步
dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj -m:1 --nologo
# 可选（我未做）：WicClosedLoop 的宿主读数（V3 影响面）
dotnet build build/DirectWrite.Linux/WicClosedLoop/DirectWrite.Linux.WicClosedLoop.csproj -m:1 --nologo
```

---

## 10. 没能确立的 / 未测的（不许读成"已证"）

1. **五臂日志、应用门禁（`drawn/colors/frames/cross_ae/leftover_after`）、`tline` 六项、`verify-all`（10 步 / 871 通过）、`T1C_CENSUS_SUMMARY` 的逐位不变** —— **未测**（要权威重建 + 跑门禁；§2 位移表要求它们不变，且**本波新增了 §7 那条 eager dlopen 位移**，主控必须在波后产物上重取）。**本车道未重建任何权威产物**。
2. **桥重发后的红证**（`BRIDGE_SRC_FP` 两侧一致 / 新 `.so` 里 `grep -a` 到 V2 的点名文案片段 / 旧 `.so` 留档）—— **未做**（`publish-milbridge.sh` 是主控动作）。
3. **`Assembly.LoadFrom(权威 WindowsBase.dll)` 在裸 `net10.0` 宿主里必失败**（`FileLoadException … manifest definition does not match the assembly reference. (0x80131040)`），而同一目录的 `PresentationCore.dll` / `UIAutomationTypes.dll` / `UIAutomationProvider.dll` 都能加载；**修后我私有构建的 `WindowsBase.dll` 也一样失败** ⇒ **是 WindowsBase 这份程序集清单的性质，不是本波改动造成的**。**根因未确立**（未做两极化实验；候选解释：强名称/公钥签名的清单差异、`ProcessorArchitecture`/`Retargetable` 一类标志 —— **都只是猜测**）。夹具对策 = 自建 ALC + `LoadFromStream`（`--loadstream`），这条腿对四件都成立。**影响面**：只影响"外部探针用 LoadFrom 加载 WB"，不影响产品、不影响真宿主（它们按身份 app-local 装）。
4. **"模块初始化器在首次触碰类型时才跑"这半边** — **未取**（`order2/order3` 撞上 §10-③ 的夹具问题）。已取的是"**加载期不跑**"（§3.1）。
5. **`WicClosedLoop` 宿主读数**（`RESOLVER_INSTALLED=N/A …` 之后 `RESULT=PASS`、`BYTE_MISMATCH=0` 等）—— **未跑**（要构建 harness + WIC shim + PNG；只做了 `error CS = 0`）。
6. **R17C 的 F3**（断言 PC 侧确实接管 `WindowsCodecs.dll`、且 `dlopen` 到 `_shimPath`）—— **未做**（宿主侧、产物无关，本波未授权扩大写域）。
7. **AOT 镜像内 `X11Native` 的静态构造会不会跑、`typeof(X11Native).Assembly` 的身份**（R17C §7-③）—— **仍未测**（需重建桥 + 运行期诊断）。
8. **对 V1 而言"输掉竞态"的进程可达性**：本波证明**可达**（§3.1 的 `Assembly.LoadFrom` 路径），但**没有**证明真宿主里会走到（`WicClosedLoop` 走 `typeof(BitmapImage)` ⇒ 产品仍先赢）。⇒ **守卫是防御性的，且今天仍然赢**；这条不许读成"今天有活的碰撞"。
9. **`PresentationCore.FontBridge.cs:368` 的第二个模块初始化器**在隔离夹具里曾以 `FileNotFoundException: DirectWrite.Linux.Provider` 的形式先失败（我第一版夹具只抄了 PC 一个文件）⇒ 已改成"整目录"，但**"模块初始化器失败时哪个初始化器先抛"的顺序**未确立。

## 11. 一句话给主控的行动清单

1. 拍板 §7（**无条件自证** vs **只在输竞态时自证**）——这是本波唯一的"口径选择"。
2. `close-wave.sh` + **补建 `src/WpfGfx.Linux`（Debug）**（§8）。
3. 波后在这五件上各跑一次我的探针（命令见 §9/§3），期望：**V1 四件 (a) 无害 / (b) 点名**、**V2 (a) 无害 / broken 点名**；并重取 §10-1 的全部判据读数。
4. 若要逐字满足 V2 判据 (b)，先改预登记 (a) 的定义（§6-4），否则两条互斥。

---

## 10. 收窄（2026-09-16 15:1x）

> **lane = V18A**｜执行窗口 `2026-09-16T15:05:5x…15:08:30+0800`｜`loadavg = 2.64 2.84 1.88`｜`mem_available = 3,166,848 kB`｜`kernel = 6.8.0-138-generic`
> **本节是追加**：§1–§9 原文未动。**§7 里那条"主控可选的两行收窄改法"已被主控裁决 1 采纳并落地**，故 §7 的"本报告按预登记字面选了无条件自证"这句**对当前树已失效**，以本节为准。
> **编号说明（追加造成的重号，照实标注）**：全文原有 `## 10. 没能确立的 / 未测的` 与 `## 11. 一句话给主控的行动清单` **逐字保留在原处**；本节按主控给的字面标题追加 ⇒ 出现**两个 `## 10.`**。引用时请写 **`§10（收窄）`** 与 **`§10-原（未测）`**。
> **边界遵守**：**未重建任何权威产物**（`pc df6dbb1c2bfb4162` / `windowsbase e6216fe961a2bfb9` / `uiatypes 2ac8d37b7cdc5afd` / `uiaprovider 352ccd757a2f2fb0` / `src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll 0c597fb6ec1eec70` / 桥 `caf7baf9e67719aa` 全部逐位未变）；**`build/shims/PresentationCore.HbTextLine.cs` = `bc04c05ab6d8d82a` 一个字节都没动**；未跑 `close-wave.sh`/`publish-milbridge.sh`；未 `pkill`。

### 10.0 裁决与执行摘要

| 裁决 | 内容 | 执行 |
|---|---|---|
| **1（返工）** | **采用 §7 的"只在输竞态时自证"收窄**（理由：内存类主判据是"段数 / Σ虚拟"（`D-F1c` 线口径），无条件自证在正常路径多一次 dlopen**就是往以"段数"为尺子的判据里塞新映射**） | **V1 与 V2 都收窄了** —— V2 的位移**比 V1 更大**（见 §10.3），只收窄 V1 不足以满足"正常路径回到修前" |
| **2** | V2 的 (a)/(b) 判据按 §6 的口径改写预登记（"响亮 ⟺ 我们自己映射的名字解析不到"），**本轮不改代码** | 已记档（§6 原文保留 + 本节 §10.5 复述证据）；代码未因裁决 2 变动 |
| **3** | V3 = 删掉 + 写明理由，**通过** | 无动作 |

### 10.1 收窄这一次的 before/after（三态 sha16）

| 件 | 修前（`#17` 基线） | **收窄前**（= §1 那一版，无条件自证） | **收窄后**（当前树） |
|---|---|---|---|
| `build/shims/Win32ShimResolver.cs` | `ff3c53964cb8328b`（24,117） | `37b65d0ede827650`（30,792） | **`0735327b6ca3ae4b`（31,607）** |
| `src/WpfGfx.Linux/Windowing/X11Native.cs` | `045faa9b0785f6d2`（10,521） | `12d7cf8217b34c0c`（16,665） | **`8ede4d8a13cb3a28`（17,068）** |
| `build/DirectWrite.Linux/WicClosedLoop/Program.cs` | `ef09e6e09e8e6f75` | `f7c7fd61ef5c8ad8` | `f7c7fd61ef5c8ad8`（**本轮未动**） |

备份：`backup/{Win32ShimResolver.cs,X11Native.cs}.{before,before-narrow,after,after-narrow}`；`after-narrow` 与现树 `cmp` = **identical**（`CMP(after-narrow)=identical`）。
**改动内容（两件同款一行门）**：把自证整体挪到"**输掉竞态**"之后 ——

```csharp
            catch (InvalidOperationException) { ResolverConflict = true; }   // 槽位被别人占了：合法状态

            if (installedByUs)
                return;                     // ← 收窄：正常路径**一位不改**（不 dlopen、不探名字）

            // ---- 自证（只在输竞态时）：真 [DllImport] 走一次 ----
            try { SelfCheckShimVersion = ShimVersionViaUser32(); }            // V2 同形：X11NameResolves()
            catch (EntryPointNotFoundException) { SelfCheckShimVersion = -1; } // 赢家接了名字 ⇒ 无害
            catch (DllNotFoundException ex) { throw new InvalidOperationException("…点名「当前生效的解析器不是我们这一个」…", ex); }
```
V2 同步把 `SelfCheckX11NameResolved` 的语义收窄为"**输竞态时**才可能为 true"（诊断位注释同步改口径）。

### 10.2 四条红证（命令 + 输出 + rc，逐条）

**① (a) 抢先者映射同名 ⇒ 无害，且 `SelfCheckShimVersion` 仍为 1**（V1 PC；WB/UIAutomationTypes/UIAutomationProvider 三件逐字相同）

```text
$ dotnet …/ResolverGuardProbe.dll v1 …/PresentationCore.Linux-bin/Debug/PresentationCore.dll replica --loadstream
FOREIGN_INSTALL=OK variant=replica
TRIGGER=natural NO_THROW IsWicMappingEnabled=True
DIAG_ResolverConflict=True
DIAG_SelfCheckShimVersion=1
RUNMODULECTOR=NO_THROW
rc=0
```
⇒ 收窄后**仍然成立**（自证在输竞态分支里跑 ⇒ `1`）✓。对照：**`variant=none`（正常路径）`DIAG_SelfCheckShimVersion=0`** —— 自证确实**没有**在正常路径跑（收窄生效的行为指纹）。

**② (b) 抢先者不映射我们的名字 ⇒ 仍响亮且点名**

```text
$ dotnet …/ResolverGuardProbe.dll v1 …/PresentationCore.Linux-bin/Debug/PresentationCore.dll different --loadstream
FOREIGN_INSTALL=OK variant=different
TRIGGER=natural THROW … inner=System.TypeInitializationException: The type initializer for '<Module>' threw an exception.
POISON_RECHECK=THROW … （同上）
RUNMODULECTOR=THROW System.TypeInitializationException: … | inner=System.InvalidOperationException:
  WPF-on-Linux: 本程序集的 'user32.dll' 解析不到 —— **当前生效的解析器不是我们这一个**。
  · 成因：`NativeLibrary.SetDllImportResolver` 对同一程序集只能装一次，本文件的 [ModuleInitializer] 输掉了竞态，
    而抢先者不映射我们要的那批名字： user32.dll / gdi32.dll / kernel32.dll / PresentationNative_cor3.dll / uxtheme.dll / wtsapi32.dll
  · 后果：…  · 修法（二选一）：…  · 说明：…
rc=0
```
（`broken` 变体同款，逐字相近。）**V2** 侧：`replica`/`different` ⇒ `CCTOR_RESULT=NO_THROW` + `DIAG_ResolverConflict=True` + `DIAG_SelfCheckX11NameResolved=True`（按裁决 2 的正确口径 = 无害 + 具名诊断）；**`broken` ⇒ `CCTOR_THROW … inner=InvalidOperationException: … 'libX11.so.6' 解析不到 —— 当前生效的解析器不是我们这一个…`** ✓

**③ 非空泛：隔离夹具（依赖带齐、**没有** shim）⇒ 收窄后仍响亮失败；并说清走的是哪条路**

```text
$ ls -l …/isolated-postfix/libwpfwin32.so
ls: 无法访问 '…/isolated-postfix/libwpfwin32.so': 没有那个文件或目录          rc=2
$ (cd …/isolated-postfix && dotnet …/ResolverGuardProbe.dll v1 …/PresentationCore.dll none)
TRIGGER=natural NO_THROW IsWicMappingEnabled=True      ← 模块初始化**不抛**
RUNMODULECTOR=NO_THROW                                 ← 也不抛
FOREIGN_WAS_INSTALLED=False
rc=0
$ (cd …/isolated-postfix && dotnet …/ResolverGuardProbe.dll realcall …/PresentationCore.dll)
MODULE_INIT=NO_THROW IsWicMappingEnabled=True
REAL_DLLIMPORT=THROW System.Reflection.TargetInvocationException: … | inner=System.DllNotFoundException:
  WPF-on-Linux: 'user32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库。
  搜索过程：  · 不存在 …/libwpfwin32.so
  修复：先构建 shim —— src/WpfGfx.Linux.Native/build-shim.sh --all；或用 WPF_LINUX_WIN32_SHIM=<…> 显式指定。
rc=0
```
**走的是哪条路（照实说）**：收窄后，这一场景里**我们赢了竞态** ⇒ 守卫的自证**根本不跑** ⇒ 缺件**不在安装点**被拦，而是走**原有的解析路径**：`[DllImport("user32.dll")]` 首次解析 → `Win32ShimResolver.Resolve` → `TryLoadShim` 全候选落空 → **带候选路径逐条 + 修复命令的 `DllNotFoundException`**（= **修前就有的行为**）⇒ 仍然**响亮**，且**不是**被守卫吞掉。**另一条（守卫内部的）非空泛证明** = ②里的 `broken` 变体（输竞态 + 自证失败 ⇒ 抛）。

**④ 收窄的验收核心：正常路径 `/proc/self/maps` 回到修前**

```bash
$ dotnet …/ResolverGuardProbe.dll mapload <目标 dll>      # 触发模块初始化 / X11Native 静态构造，然后数 /proc/self/maps
```

| 目标（正常路径） | `MAPS_WPFWIN32`（`libwpfwin32.so` 行数） | `MAPS_LIBX11`（`libX11` 行数） | `MAPS_TOTAL`（全部行数） | 判定 |
|---|---|---|---|---|
| **V1 PC 修前**（权威 `df6dbb1c2bfb4162`） | **0 → 0** | 0 → 0 | 248 → 263 | 基线 |
| V1 PC **收窄前**（无条件自证，`0371b34691dbbc47`） | **0 → 5** | 0 → 6 | 245 → **298** | 位移（+37 行） |
| **V1 PC 收窄后**（`821266ade3407730`） | **0 → 0** ✓ | 0 → 0 ✓ | 246 → 259 | **通过** |
| V1 WB 收窄后（`492e3f62cd85f87b`，`--loadstream`） | **0 → 0** ✓ | 0 → 0 ✓ | 245 → 245 | 通过 |
| **V2 `WpfGfx.Linux` 修前**（权威 `0c597fb6ec1eec70`） | 0 → 0 | **0 → 0** | 247 → 247 | 基线 |
| V2 `WpfGfx.Linux` **收窄前**（`b8a959cdbc4f814a`） | 0 → 0 | **0 → 6** | 244 → **279** | 位移（+35 行；**比 V1 还大**） |
| **V2 `WpfGfx.Linux` 收窄后**（`6ec38dd709ed1133`） | 0 → 0 | **0 → 0** ✓ | 244 → 244 | **通过（与修前逐项相同）** |

**判定**：**收窄生效 ✓**（不是 0→5）。命令与输出原文：`$HOME/wfp-runs/w18-laneV18A/narrow-maps.log` = **`54bf93e0ef15d8e4`**（9,579 B）。
**两点如实说明**：① `MAPS_TOTAL` 在**同一目标的不同进程**之间有 ±2 行的抖动（JIT/GC），所以机器断言只能下在**针数**上（`libwpfwin32.so` / `libX11` 的 0→0）；② V1 收窄后 `TOTAL` 仍 +13（修前 +15）——那是**自然触发本身**（`Win32ShimResolver` 的 cctor + JIT）带来的，**修前也一样有**，与 dlopen 无关。

### 10.3 为什么 V2 也必须收窄（主控只点了 V1，但证据指向两件）

收窄前的实测：`X11Native` 的静态构造**在正常路径上就把 `libX11.so.6` 载进进程**（`libX11` **0→6** 行、`TOTAL` 244→279），而**修前**同一趟是 247→247（静态构造什么都不载）。⇒ 只看 `libwpfwin32.so` 会漏掉这一条更大的位移；按裁决 1 的**同一理由**（段数尺子），V2 一并收窄，收窄后 `libX11` **0→0**、`TOTAL` **244→244**（**与修前逐项相同**）。

### 10.4 五件私有编译（收窄后重新取，字面 `error CS = 0`）

```bash
$ export PATH="$HOME/.dotnet:$PATH"; D=$HOME/w18a-build
$ dotnet build <proj> -c Debug -m:1 --nologo [-p:DefaultItemExcludes=obj/**]       -p:BaseOutputPath=$D/<n>-bin/ -p:BaseIntermediateOutputPath=$D/obj-<n>/
PresentationCore.Linux       rc=0 errorCS=0  0 个警告  0 个错误
WindowsBase.Linux            rc=0 errorCS=0  0 个警告  0 个错误
UIAutomationTypes.Linux      rc=0 errorCS=0  0 个警告  0 个错误
UIAutomationProvider.Linux   rc=0 errorCS=0  0 个警告  0 个错误
WpfGfx.Linux                 rc=0 errorCS=0  0 个警告  0 个错误
```
日志：`$D/logs/narrow2-<n>.log`。**收窄后的私有产物**：

| 件 | sha16 | size |
|---|---|---|
| `PresentationCore.dll` | `821266ade3407730` | 4,196,352 |
| `WindowsBase.dll` | `492e3f62cd85f87b` | 1,242,624 |
| `UIAutomationTypes.dll` | `1145288b55c9a4d6` | 228,864 |
| `UIAutomationProvider.dll` | `4eec4fb4050982ed` | 42,496 |
| `WpfGfx.Linux.dll` | `6ec38dd709ed1133` | 359,424 |

（私有件 sha 只在**同 obj 路径**下可复现，见 §4 末条的实测；本轮 obj 路径 = `$D/obj-<n>`，与 §4 的 `obj-pc` 不同名 ⇒ **两轮的私有 `pc` sha 不可直接对拍**，这是路径效应、不是内容差异。）

### 10.5 收窄让哪些原判据变成"没测过"（**如实回答，不补读数**）

| 原判据 | 收窄后状态 | 我实际测到了什么 |
|---|---|---|
| ① **正常路径下 `user32.dll` 等映射仍然可用（真 `[DllImport]` 调用成功）** | **不再由守卫行使**（守卫在正常路径直接 `return`）；但**不是没测过** —— 我用探针**直测**：模块初始化后，反射调用**目标程序集内部**的真 `[DllImport]` `WpfLinuxWin32_ShimVersion`（`realcall` 模式） | **四件全绿**：`MODULE_INIT=NO_THROW IsWicMappingEnabled=True` + **`REAL_DLLIMPORT=OK value=1`**（PC / WB / UIAutomationTypes / UIAutomationProvider 各一次；日志 `narrow-realcall.log` = `f1f51f830064d963`）。**两极化缺口照实说**：**修前**那份权威件里**没有** `ShimVersionViaUser32` 这个方法（它是本波新增的）⇒ 同一命令在修前只能打 `REAL_DLLIMPORT=NOINFO method-absent` ⇒ **① 的"修前对照"这一段没测过**（我没有修前的等价探针；`Resolve` 的解析逻辑本波一行未改，但那是**读码**不是读数）。 |
| ④ **`shim` 文件缺失 ⇒ 仍然响亮失败** | **安装点不再响亮**（那是收窄的直接代价）；**但失败仍然响亮**，只是晚到"首个真 `[DllImport]`"，走原有的 `Win32ShimResolver.Resolve` 路径（§10.2 ③ 逐字） | **测到了**：隔离夹具里 `REAL_DLLIMPORT=THROW … DllNotFoundException: … 没找到可加载的 shim 库。搜索过程：… 修复：…`。**口径变化必须写明**：这一条现在是**修前同款行为**（修前也是"装完不说、首个 P/Invoke 才炸"），所以它**不再是"守卫带来的加强"**。 |
| ② **(a) 抢先者映射同名 ⇒ 无害** | **仍由守卫行使**，未变 | §10.2 ① 逐字（`SelfCheckShimVersion=1`） |
| ③ **(b) 抢先者不映射 ⇒ 响亮且点名** | **仍由守卫行使**，未变 | §10.2 ② 逐字 |
| V2 的 ①（正常路径 `libX11.so.6` 可用） | **不再由守卫行使**；`SelfCheckX11NameResolved` 正常路径保持 `false`（收窄指纹） | **未做等价直测**（V2 侧我没有"目标程序集内部调真导出"的 safe 调用点：Xlib 没有无副作用函数，见 §2.2）⇒ **这一条现在是"没测过"**，如实记。修前/修后的对照只有"cctor 不抛"（`CCTOR_RESULT=NO_THROW`）这一层。 |

**一句话**：收窄把 **①/④ 从"守卫行使的判据"降级为"靠外部直测或既有路径成立的性质"**；其中 **V1 的 ① 我直测到了、V2 的 ① 没测到、① 的修前对照没测到、④ 现在等价于修前行为** —— 四条都写在这里，不补。

### 10.6 本节新增/更新的留档 sha

| 物 | sha16 | size |
|---|---|---|
| `$HOME/wfp-runs/w18-laneV18A/prefix.log`（修前/权威，已含 `realcall`） | `c04029c11038fc31` | 32,918 |
| `$HOME/wfp-runs/w18-laneV18A/postfix.log`（**收窄后**） | `0c8bb85d7d0255cc` | 42,928 |
| `$HOME/wfp-runs/w18-laneV18A/postfix.narrow1.log`（**收窄前**那一版读数，留档对拍） | `573add8e5f45c594` | 43,016 |
| `$HOME/wfp-runs/w18-laneV18A/narrow-maps.log` | `54bf93e0ef15d8e4` | 9,579 |
| `$HOME/wfp-runs/w18-laneV18A/narrow-realcall.log` | `f1f51f830064d963` | 4,911 |
| `$HOME/wfp-runs/w18-laneV18A/probe-set.sh`（新增 `realcall` 直测） | `8ccc34195b6c7bd1` | 3,305 |
| `build/MilBridge/tests/ResolverGuardProbe/Program.cs`（新增 `mapload` 总行数/V2 触发 + `realcall`） | `76caccc4693bf4a1` | 24,970 |
| 探针二进制 | `38f94893edc47478` | 19,968 |

**§9 引用值的勘误（照实说，不隐藏）**：§9 的表里写的是 `prefix.log = e1e863738df59fae`、`postfix.log = 573add8e5f45c594` —— 那是**本节重跑之前**的状态。本节为测 ③ 给 `probe-set.sh` 的 §D 加了 `realcall` 一段，于是两份日志**被重跑覆盖**：
- `prefix.log`：内容差异**只有** §D 里多出来的 `realcall` 块（其余逐字相同）⇒ 现 sha = `c04029c11038fc31`；**`e1e863738df59fae` 那一份已不存在**（我没有为它保留副本，如实记）。
- `postfix.log`：那份 `573add8e5f45c594` = **收窄前**读数，已**留档**为 `postfix.narrow1.log`（逐字节同 sha）；现 `postfix.log` = **收窄后**读数 `0c8bb85d7d0255cc`。

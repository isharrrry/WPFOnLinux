# R17C · `NativeLibrary.SetDllImportResolver` 单槽位（每程序集一次）全仓审计

> **lane = R17C**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **时刻（开头）**：`2026-09-15T23:28:06+08:00`｜`uname -r = 6.8.0-138-generic`｜`/proc/loadavg = 0.72 1.02 0.63`｜`free -m` ⇒ `mem_available = 3706 MB`（total 7923 / used 3734 / free 163 / buff-cache 4025 / swap used 938）。
> **时刻（收尾）**：`2026-09-15T23:31:41+08:00`｜`loadavg = 0.72 0.93 0.68`｜`mem_available = 3776 MB`（used 3664 / free 197 / buff-cache 4061 / swap used 952）。
> **时刻（落盘）**：`2026-09-15T23:34:56+08:00`｜`loadavg = 0.83 0.86 0.70`｜`mem_available = 3900 MB`（used 3598 / free 687 / buff-cache 3637 / swap used 952）｜**本文件自身的行数 / sha256/16 / size 由父车道现场复查**（`sha256sum build/MilBridge/R17C-audit.md | cut -c1-16`）——文件自指不可内嵌：任何一次落盘都会改变它自己的 sha。
> **本轮是只读审计**：写域 = `build/MilBridge/R17C-audit.md`（本文件）+ `$HOME/wfp-runs/w17-laneR17C/`（本轮实际未落任何中间文件）。
> **机器约束遵守声明**：**未跑** `dotnet build` / `dotnet test` / `dotnet run` / 任何编译器或 MSBuild；**未起任何长驻进程**；**未 `pkill`**；**未改动** `docs/**`、`build/shims/**`、`src/**`、`tests/**`、`samples/**`、任何 `build/*.Linux/**` 产物。
> 用到的命令仅 `ls` / `read` / `grep`（含 `grep -a`）/ `sha256sum` / `stat` / `sed -n` / `head` / `wc`。引用行号一律现场重读。

---

## 0. 判决（先给结论）

**产品侧（product assembly 被装两次，或产品类型 / 模块初始化器的抛出路径）今天不存在**——9 个代码安装点里**没有任何一条路径**能让同一个程序集在同一个进程里被两个安装者盯上，**除了** PresentationCore 程序集在 **WIC 闭环 harness 进程**里被"产品 `[ModuleInitializer]` + harness 自装器"同时盯上——而那一条的**方向是固定的、且今天输的永远是 harness**（实测见 §3-C1）。**但**存在两处**未加守卫的产品侧安装点**（`build/shims/Win32ShimResolver.cs:171-176` 的 `[ModuleInitializer]` ×4 程序集；`src/WpfGfx.Linux/Windowing/X11Native.cs:32-35` 的**静态构造**），它们的"输掉"分支的后果不是降级而是**投毒**（模块初始化失败 / 类型 `TypeInitializationException`）——今天靠"运行时在模块加载期就跑模块初始化器"这一**被实测过一次**的性质挡着，**不是**靠代码挡着。

---

## 1. 方法、枚举口径与正对照（纪律 25）

### 1.1 全量枚举（含二进制、排除 `upstream/**`）

```bash
$ grep -rn -a 'SetDllImportResolver(' . --exclude-dir=upstream | wc -l
13
$ grep -rn -a 'SetDllImportResolver(' . --exclude-dir=upstream | grep -v '^\./docs/' | wc -l
11
$ grep -rn -a 'SetDllImportResolver(' docs/ | wc -l
2
```

11 条非 docs 命中 = **9 条真代码调用** + 2 条 `README-合并写.txt` 里的注释文本（第 3 行、第 18 行）。2 条 docs 命中 = `docs/U1-windows-probe.md:358`（U1 探针片段，与 §2 站点 S9 同源）+ `docs/U2-M7b-report.md:133`（叙述）。**故安装点数 = 9**（这一条计数就是"有没有漏"的唯一口径；`upstream/**` 按任务书排除，附注：`grep -rn --binary-files=without-match 'SetDllImportResolver' upstream/ | wc -l` ⇒ **0**，即上游 WPF 本体一处都没有，排除它不影响站点集合）。

**其它枚举完备性对照（反射式/字符串式安装 + 模块初始化器全量）：**

```bash
$ grep -rn -a -e 'GetMethod("SetDllImportResolver' -e '"SetDllImportResolver"' . --exclude-dir=upstream
（无输出）            # ⇒ 没有"反射/字符串"式安装，grep 枚举是完备的
$ grep -rn -a --include='*.cs' 'ModuleInitializer\]' . --exclude-dir=upstream | wc -l
16                   # 16 行"提到"，其中真属性只有 6 条 ↓
$ grep -rn -a --include='*.cs' '^\s*\[ModuleInitializer\]' . --exclude-dir=upstream | sort
./build/MilBridge/spike/SmokeTest/Program.cs:34
./build/MilBridge/src/MilBridge.Linux/NativeSearchPath.cs:40
./build/MilBridge/src/MilBridge.Resolver/MilCoreStandaloneInstaller.cs:25
./build/shims/PresentationCore.FontBridge.cs:368
./build/shims/Win32ShimResolver.cs:171
./tests/WpfGfx.Linux.Tests/Presentation.Tests/M7cProbe/HelloWpfProbe.cs:55
```

**6 条真 `[ModuleInitializer]` 与安装点的关系（这是"机构"口径的全量，不是 4 条）**：其中 4 条是安装点（S1/S2/S3/S8）；`PresentationCore.FontBridge.cs:368` **不是**安装点（它只调 `FontFaceBridge.Install()`，见 §5-⑤）；`M7cProbe/HelloWpfProbe.cs:55` **也不是**（该文件 `SetDllImportResolver` 计数 = **0**，它只打印基线并起一个探针线程，且 `Say()` 自身 `try/catch` 不抛）⇒ **模块初始化器"能抛 ⇒ 毒化整个模块"的风险面 = 上述 4 个安装点 + `FontBridge.Install()`**（后者已证不抛，见 §5-⑤）。

**注（本审计自身的可见性副作用）**：本文件写进 `build/MilBridge/` 之后，仓库内的 `grep SetDllImportResolver` 会**多命中本文件**（它会把自己的表格与引文当成命中）。§1.1 的 9 站点计数是**本文件落盘之前**跑的；后续任何人复核时应加 `--exclude=R17C-audit.md`。

### 1.2 守卫模式的正对照（"N 个未加守卫"必须给出守卫的搜索式）

```bash
$ grep -rn -a --include='*.cs' 'catch (InvalidOperationException)' . --exclude-dir=upstream | sort
./build/MilBridge/src/MilBridge.Linux/NativeSearchPath.cs:51              ← 解析器守卫（S3）
./build/MilBridge/src/MilBridge.Resolver/MilCoreStandaloneInstaller.cs:33 ← 解析器守卫（S2）
./build/PresentationCore.Linux/FamilyCollection.Linux.cs:1501             ← 与本主题无关
./build/PresentationFramework.Linux/SystemResources.Linux.cs:932          ← 与本主题无关
./src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs:54                    ← 与本主题无关
./src/WpfGfx.Linux/Interop/MilPresentation.cs:736                         ← 与本主题无关
./tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs:179             ← 解析器守卫（S5）
./tests/WpfGfx.Linux.Tests/Presentation.Tests/X11Guard.cs:98              ← 解析器守卫（S6）
./tests/WpfGfx.Linux.Tests/Windowing.Tests/X11InputInjector.cs:72         ← 与本主题无关（process.Kill）
$ grep -rn -a 'catch (Exception e)' build/DirectWrite.Linux/WicClosedLoop/Program.cs
135:        catch (Exception e)                                              ← S7 的守卫
$ grep -rn -a 'catch (Exception ex)' tests/parity/windows/src/U1Recorder/Program.cs
155:                catch (Exception ex)                                     ← S9 的守卫
```

⇒ **9 个站点中 6 个有守卫**（S2/S3/S5/S6/S7/S9），**3 个没有**（S1 = `Win32ShimResolver.Register` ×4 程序集实例化；S4 = `X11Native` 静态构造；S8 = SmokeTest spike 的 `[ModuleInitializer]`）。上表那 9 行是**全仓**命中，其中**只有已标注的 4 行**与解析器守卫有关——这正是"守卫搜索式必须连同全量输出一起给"要防的误读。

### 1.3 产物侧证据（不靠源文件自证"编进去了"）

```bash
$ for a in build/{WindowsBase.Linux,PresentationCore.Linux,UIAutomationTypes.Linux,UIAutomationProvider.Linux}/bin/Debug/*.dll; do echo -n "$a "; grep -aoc 'Win32ShimResolver' "$a"; done
（四件全部 = 2，且 grep -ao 'WpfLinux\.Shims\.[A-Za-z]*' 各只回一个命名空间：
  WindowsBase → WpfLinux.Shims.WindowsBase；PresentationCore → WpfLinux.Shims.PresentationCore；
  UIAutomationTypes / UIAutomationProvider → WpfLinux.Shims.UIAutomation）
$ grep -aoc 'MilCoreStandaloneInstaller' build/PresentationCore.Linux/bin/Debug/PresentationCore.dll
0        # ⇒ 独立自装器没有混进产品件（与 MilCoreStandaloneInstaller.cs:4-8 的告诫一致）
$ grep -aoc 'X11LibraryResolver' src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll
1
$ so=build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so
$ for s in NativeSearchPath MilCoreStandaloneInstaller MilCoreDllImportResolver X11Native X11LibraryResolver Win32ShimResolver; do echo -n "$s="; grep -aoc "$s" "$so"; done
NativeSearchPath=1  MilCoreStandaloneInstaller=0  MilCoreDllImportResolver=0  X11Native=1  X11LibraryResolver=1  Win32ShimResolver=0
```

**正对照（证明 `grep -a` 在这些二进制上真的能命中）**：`grep -ac 'libSkiaSharp' ~/.nuget/packages/skiasharp/2.88.9/lib/net6.0/SkiaSharp.dll` ⇒ **1**（`grep -ao` 回 `libSkiaSharp`）。因此下面这条 **0 是有意义的 0**：

```bash
$ for f in ~/.nuget/packages/skiasharp/2.88.9/lib/*/SkiaSharp.dll; do grep -ac 'SetDllImportResolver' "$f"; done | sort -u | tr '\n' ' '
0        # 全部 39 个 TFM 变体都是 0 ⇒ SkiaSharp 自己不装解析器（S3 无竞争者）
```

---

## 2. 站点总表（1 行 = 1 个安装点；S1 展开为 4 个"程序集实例"）

| # | file:line | target assembly（**精确表达式**） | mechanism | guarded? | who else installs for that assembly | same process? | verdict |
|---|---|---|---|---|---|---|---|
| **S1** | `build/shims/Win32ShimResolver.cs:174` | `typeof(Win32ShimResolver).Assembly` —— **源文件被编进 4 个程序集**，每个程序集各得一份实例：WindowsBase(`WINDOWS_BASE`) / PresentationCore(`PRESENTATION_CORE`) / UIAutomationTypes(`UIAUTOMATIONTYPES`) / UIAutomationProvider(`AUTOMATION`) | `[ModuleInitializer] Register()`（行 171） | **否**（无 try/catch、无幂等位） | **PC 实例**：S7（`WicClosedLoop` 宿主）＋（Windows 侧）S9。WB / UIAutomationTypes / UIAutomationProvider 实例：**无** | **PC：是**（`WicClosedLoop` 进程同时加载 PC）。其余 3 个实例：不适用 | **PC：ORDER-DEPENDENT**（今天是"产品赢、宿主输"，确定方向；若该初始化器哪天输 ⇒ **POISONED-MODULE**）。WB / UIAutomationTypes / UIAutomationProvider：**SAFE**（各 1 个安装点） |
| **S2** | `build/MilBridge/src/MilBridge.Resolver/MilCoreStandaloneInstaller.cs:30` | `typeof(MilCoreStandaloneInstaller).Assembly` = **宿主 exe 自己的程序集**（该文件被 `<Compile Include>` 链进 `ClosedLoop.csproj:26`、`HbSpike.csproj:32`、`T2Repro.csproj:31`） | `[ModuleInitializer] Install()`（行 25） | 是：`catch (InvalidOperationException) { InstallConflict = true; }`（行 33-35） | 无 | 不适用 | **SAFE** |
| **S3** | `build/MilBridge/src/MilBridge.Linux/NativeSearchPath.cs:49` | `typeof(SkiaSharp.SKBitmap).Assembly` = **SkiaSharp** | `[ModuleInitializer] Install()`（行 40）＋ `s_installed` 幂等位（行 43-44） | 是：`catch (InvalidOperationException)`（行 51-54） | 无（SkiaSharp 自身 0 处，见 §1.3 正对照） | 仅 AOT 镜像 runtime | **SAFE** |
| **S4** | `src/WpfGfx.Linux/Windowing/X11Native.cs:34` | `typeof(X11Native).Assembly` = **`WpfGfx.Linux`** | **静态构造** `static X11Native()`（行 32） | **否** | 无（9 站点全枚举下没有任何别的站点指向 `WpfGfx.Linux`） | 不适用 | **SAFE-LATENT**：今天安全；但它是**产品源里唯一的静态构造安装点**，任何新增第二个安装点 ⇒ 立刻 **POISONED-TYPE** |
| **S5** | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs:177` | `typeof(Win32Shim).Assembly` = `WpfGfx.Linux.ManagedLayer.Tests` | **静态构造** `static Win32Shim()`（行 158） | 是：`catch (InvalidOperationException)`（行 179-182） | **无**（`D-R2` 修完后；此前是 `DP1ReproTests` 静态构造，已删） | 不适用 | **SAFE**（`D-R2` 的输家已消除；见 §3-C2） |
| **S6** | `tests/WpfGfx.Linux.Tests/Presentation.Tests/X11Guard.cs:96` | `typeof(Win32Shim).Assembly` = `WpfGfx.Linux.Presentation.Tests` | **静态构造** `static Win32Shim()`（行 86） | 是：`catch (InvalidOperationException)`（行 98-101） | 无 | 不适用 | **SAFE**（但守卫是**静默吞**，见 §4/F2） |
| **S7** | `build/DirectWrite.Linux/WicClosedLoop/Program.cs:123` | `pc = typeof(BitmapImage).Assembly` = **PresentationCore** | 普通方法 `InstallWicResolver`（行 118），由 `Main` 调一次（行 85） | 是：`catch (Exception e)`（行 135-141），失败只打印 | **S1 的 PC 实例**（`[ModuleInitializer]`） | **是**（同进程；`typeof(BitmapImage).Assembly` 必然把 PC 拉进来） | **ORDER-DEPENDENT**（方向固定：宿主必输，实测 `build/DirectWrite.Linux/REPORT.md:1021`） |
| **S8** | `build/MilBridge/spike/SmokeTest/Program.cs:43` | `typeof(Program).Assembly` = `SmokeTest` exe | `[ModuleInitializer] InstallResolver()`（行 34） | **否** | 无 | 不适用 | **SAFE**（spike，独占自己的 exe 程序集） |
| **S9** | `tests/parity/windows/src/U1Recorder/Program.cs:147` | `typeof(Visual).Assembly` = **微软真 PresentationCore（Windows）** | `Main` 内普通方法（行 144-167） | 是：`catch (Exception ex)`（行 155） | 无（真 PC 自己不注册，`docs/U1-windows-probe.md:363` 实测 `SetDllImportResolver: OK`，`tests/parity/windows/src/U1Proxy/out/recorder-report.txt:2` 同证） | Windows-only，本机不可跑 | **SAFE**（Linux 上不适用；**NOT-ESTABLISHED on this machine**——见 §8） |

**统计**：**9 个安装点**（源级）→ **14 个"程序集实例"**（S1 贡献 4、S2 贡献 3 个宿主 exe、其余各 1）。**冲突（同一程序集 ≥2 个安装者）共 2 处**：① PresentationCore（S1-PC × S7，加 Windows 侧 S9 但那是另一份 PC 件、另一台机器）② PresentationCore-on-Windows（S9 × 微软真 PC 自身，实测无冲突）。`ManagedLayer.Tests` 程序集上的那一处（曾 = `D-R2`）**已消失**。

### 2.1 各站点"机构"分类（任务书要求的口径）

| 机构 | 站点 |
|---|---|
| `[ModuleInitializer]` | S1（`Win32ShimResolver.cs:171`）、S2（`MilCoreStandaloneInstaller.cs:25`）、S3（`NativeSearchPath.cs:40`）、S8（`SmokeTest/Program.cs:34`） |
| **静态构造** | S4（`X11Native.cs:32`）、S5（`ManagedLayer.Tests/X11Guard.cs:158`）、S6（`Presentation.Tests/X11Guard.cs:86`） |
| 普通方法（调用方恰好只调一次） | S7（`WicClosedLoop/Program.cs:118`，调用点 `:85`）、S9（`U1Recorder/Program.cs:147`，`Main` 内） |

**注**：S7/S9 的"只调一次"是**读出来的**（各只有一个调用点；`grep -rn 'InstallWicResolver' build/DirectWrite.Linux/WicClosedLoop/Program.cs` ⇒ 只有 `:85` 与定义 `:118` 两行），不是 API 保证的。

---

## 3. 逐冲突分析（含"进程可达性"推导）

> 推导原则：`SetDllImportResolver(assembly, …)` 的作用域 = **传入的那个 `Assembly` 对象**（本仓多处注释均已确认，见 `build/shims/Win32ShimResolver.cs:15-17`：「**注册必须按程序集各做一次**（`SetDllImportResolver` 的作用域就是传入的那个 Assembly）」）。因此**跨程序集的安装互不影响**，冲突只在"**同一个程序集对象**被两个安装者盯上"且"**两个安装者能在同一个进程里都跑到**"时成立。`Assembly` 对象另外还按 `AssemblyLoadContext` 区分——本仓**只使用默认 ALC**：`grep -rn -a --include='*.cs' 'AssemblyLoadContext' . --exclude-dir=upstream` ⇒ **1 行**，`build/DirectWrite.Linux/SystemFontsProbe/Program.cs:33: AssemblyLoadContext.Default.Resolving += (context, name) =>`（一个"缺 WindowsBase 就 `LoadFromAssemblyPath` 补"的**诊断探针回退**，`:35-39`，只处理 `WindowsBase`，用的是 **Default** 上下文 ⇒ `LoadFromAssemblyPath` 对同一身份仍是**同一个 `Assembly` 对象**，不会造出第二个槽位）。⇒ 全仓"程序集身份 = 唯一对象"。

### C1 · PresentationCore 程序集：**产品 `[ModuleInitializer]` vs `WicClosedLoop` 宿主自装器**（唯一"产品件被外部第二次盯上"的实例）

**分类：(b) 一守卫一未守卫 —— 但"未守卫的那个是 `[ModuleInitializer]`"，所以它今天总是赢。**

- 产品侧（未守卫）：`build/shims/Win32ShimResolver.cs:171-176`
  ```csharp
  #pragma warning disable CA2255
          [ModuleInitializer]
          internal static void Register()
          {
              NativeLibrary.SetDllImportResolver(
                  typeof(Win32ShimResolver).Assembly, Resolve);
          }
  #pragma warning restore CA2255
  ```
  同文件 `:188-190` 自述了这个设计：「为什么挂在这里而不是自己再装一个解析器：`SetDllImportResolver` 对**同一程序集只能调一次**，本文件的 [ModuleInitializer] 已占位；再装一个会由"谁先跑谁赢"决定，输的那个抛未捕获异常。」
- 宿主侧（有守卫）：`build/DirectWrite.Linux/WicClosedLoop/Program.cs:118-141`，`:122` 取 `Assembly pc = typeof(BitmapImage).Assembly;` → `:123` 装 `WindowsCodecs.dll → _shimPath`；失败路径 `:136-140` 打印
  `RESOLVER_INSTALLED=False …` ＋「RESOLVER_NOTE=PresentationCore 的 [ModuleInitializer]（Win32ShimResolver）已占用该程序集的解析器槽位 → 本 harness **无法**自装。」
- **同进程推导（established by reading）**：`WicClosedLoop/Program.cs:85` 在 `Main` 里调 `InstallWicResolver`，而 `:122` 的 `typeof(BitmapImage)` 已经把 PC 拉进本进程 ⇒ **两个安装者必然都在这个进程里**。除它以外**没有第二个宿主**会为 PC 装解析器：`samples/**` 里**源级**命中 = 0，两个测试程序集（S5/S6）只为自己那个程序集装。这一条**必须把两个命令一起给**，否则会得出错误结论：
  ```bash
  $ grep -rn --binary-files=without-match 'SetDllImportResolver' samples/ | wc -l
  0                      # ← 源级（正确答案）
  $ grep -rn -a 'SetDllImportResolver' samples/ | wc -l
  17                     # ← 假阳：全部落在 samples/*/bin/** 里**已构建产物**的字符串表
  $ grep -rl -a 'SetDllImportResolver' samples/ | sort
  samples/HelloMil/bin/Debug/net10.0/WpfGfx.Linux.dll
  samples/HelloWpf/bin/{Debug,Release}/net10.0/{PresentationCore,WindowsBase,UIAutomationTypes,UIAutomationProvider}.dll
  samples/WpfFeatureProbe/bin/Debug/net10.0/{PresentationCore,WindowsBase,UIAutomationTypes,UIAutomationProvider}.dll
  samples/WpfTextDemo/bin/Debug/net10.0/{PresentationCore,WindowsBase,UIAutomationTypes,UIAutomationProvider}.dll
  ```
  ⇒ 这 17 处**不是安装点**，而是"产品件被拷进 app 输出目录"的指纹（`HelloWpf` 的四件套 + `HelloMil` 的 `WpfGfx.Linux.dll`）。**顺带印证 S1 的进程可达性**：HelloWpf 进程里四件产品程序集各带一个 `[ModuleInitializer]` 安装点 ⇒ 每件各装一次（= C5）。
- **实测方向（proven，一次观测）**：`build/DirectWrite.Linux/REPORT.md:1021-1023`
  ```
  RESOLVER_INSTALLED=False  InvalidOperationException: A resolver is already set for the assembly.
    ⇒ PresentationCore 的 [ModuleInitializer]（Win32ShimResolver）已占用该程序集的解析器槽位，
      harness **无法**自装 ⇒ **WIC 映射只能由 build/shims/Win32ShimResolver.cs 提供（需 PC 重建一次）**。
  ```
  ⇒ 在 **PC 这一侧**，宿主 `typeof(...)` 一取到 `Assembly`，PC 的模块初始化器**已经跑完**（否则 `SetDllImportResolver` 不会报 "already set"）。**这是本仓唯一的顺序性实测证据。**
- **它为什么"不是竞态"**：`SetDllImportResolver` 需要拿到 `Assembly` 对象 ⇒ 调用方必须先让该模块被加载；而 `[ModuleInitializer]` 的契约是"在模块内任何代码执行前运行"（当前 CoreCLR 落地为**模块加载期**执行，与上面那次实测一致）。⇒ 外部安装者**只能输**，除非运行时把模块初始化器推迟到"首次方法调用"才跑——**这一点是本审计唯一无法用只读手段证否的产品侧风险**（见 §8-①）。
- **ORDER-DEPENDENT 的具体内容**：两个解析器**映射同一个名字 `WindowsCodecs.dll`**（PC 侧 `WicMappedLibraries` 见 `Win32ShimResolver.cs:107-124`；harness 侧 `:125`），名字相同但**指向来源不同**（PC 侧候选序：`WPF_LINUX_WIC_SHIM` → 程序集目录 → 仓库 `build/DirectWrite.Linux/wic-shim/`，见 `EnumerateCandidates` `:349-380`；harness 侧是它自己算出来的 `_shimPath`，`:81-85` 附近）。今天两边通常落到**同一个文件**（harness 脚本把 `WPF_LINUX_WIC_SHIM` 设成同一绝对路径，见 `FontEntryClosedLoop/run-font-harness.sh:61-63`），所以是良性的；但 harness 的映射这一路是**死代码**——它"看起来在工作"（`RESOLVER_INSTALLED=False` 那行是唯一线索，而 `_resolverInstalled` 只在 `:132` 被**写**、全仓**没有读**，`grep -rn '_resolverInstalled' build/DirectWrite.Linux/WicClosedLoop/Program.cs` ⇒ 只有 `:51`、`:132` 两行）⇒ **"丢了竞态"没有被断言**。

### C2 · `WpfGfx.Linux.ManagedLayer.Tests` 程序集：**`D-R2` 的旧址**（已修，但留下一条新的顺序依赖）

- 修完后的现状（源）：`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs:175-183`
  ```csharp
              try
              {
                  NativeLibrary.SetDllImportResolver(typeof(Win32Shim).Assembly, Resolve);
              }
              catch (InvalidOperationException)
              {
                  // 已有人为本程序集装过解析器（竞态的另一方赢了）。不是缺陷、不是装置缺件。
              }
              LoadedPath = ShimLocator.Resolve();
  ```
  与 `DP1ReproTests.cs:70-73`：「**修法 = 每个程序集只留唯一安装点**：`X11Guard.Win32Shim` 的解析器**已经**映射 `user32.dll`（见其 `Mapped` 数组），本类只需**触发它**，不再自己安装。」⇒ `:73 _ = Win32Shim.LoadedPath;`
- **安装点数核验**：`grep -rn -a 'SetDllImportResolver(' tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ | wc -l` ⇒ **1**（只有 `X11Guard.cs:177`）⇒ 该程序集**不再有第二个安装点** ⇒ `D-R2` 的投毒路径**已断**。
- **产物不陈旧（proven）**：`DP1ReproTests.cs` mtime `23:27:22`、`X11Guard.cs` `23:27:10`，而 `bin/Debug/net10.0/WpfGfx.Linux.ManagedLayer.Tests.dll` mtime `23:27:37`（sha16 `3bd37556b50f9a71`）——**产物晚于源**，即当前验证序列用的那份程序集已含修复。
- **残留顺序依赖（新发现，NOT-ESTABLISHED 概率、但机理 proven）**：本程序集里 `[DllImport("user32.dll")]` 等被映射名字的使用者共 4 个文件（`grep -rn -a 'DllImport(' tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ --include='*.cs'`），其中
  - `DP1ReproTests.cs`：静态构造 `:73` 主动触发 `Win32Shim` ⇒ 自足；
  - `SystemParametersInfoTests.cs`：`:40-41` 声明 `[DllImport("user32.dll", EntryPoint = "SystemParametersInfoW")] SpiW`，`:125/:180/:206/:234/:253/:269` **6 处调用**；而该类里**唯一**触发 `Win32Shim`（= 全程序集唯一安装点）的地方是 `:91 int n = Win32Shim.AbiLayout(...)`，它位于**另一个**测试方法（`:70 [Theory] :88 SpiStructLayout_Native_Matches_Managed`）里；
  - `UIAutomationLinuxTests.cs`：`grep -n 'Win32Shim'` 的 3 处（`:3`、`:8`、`:90`）**全在注释里**，代码不触发。
  ⇒ 若 xUnit 让某个 `SpiW` 用例**早于**任何 `Win32Shim` 触发点运行，则这些用例会以 **`DllNotFoundException: user32.dll`** 红——**症状与 `D-R2` 同类（"约一半概率的间歇红"），但根因不同**。今天两个测试工程都设了串行（`xunit.runner.json` = `parallelizeTestCollections:false`、`parallelizeAssembly:false`、`maxParallelThreads:1`），所以概率取决于**类/集合的执行顺序**；该顺序**不能用只读手段确定**（见 §8-②）。**这是本轮"最值得马上做"的一条**（修法 = F1，一行）。

### C3 · `WpfGfx.Linux.Presentation.Tests` 程序集：单点，但守卫是"静默吞"

`tests/WpfGfx.Linux.Tests/Presentation.Tests/X11Guard.cs:88-101`：
```
// ⚠️ 2026-09-15：`SetDllImportResolver` **对同一程序集只能调一次**，第二次抛 …
//   本程序集当前**只有一个**安装点（所以今天是潜伏形态），这里先兜一层：
//   输掉竞态不算失败；装置缺件仍由下面的解析路径硬失败。
```
核验：`grep -rn -a 'SetDllImportResolver(' tests/WpfGfx.Linux.Tests/Presentation.Tests/ | wc -l` ⇒ **1**（注释自述与事实一致、**proven**）。**风险**：该 `catch` 与 `ManagedLayer` 那处不同——它**只在** `Resolve` 里 `throw DllNotFoundException`（`:111-112`）而没有 `LoadedPath = ShimLocator.Resolve()` 那样的"装置在位"硬检查。⇒ 一旦将来有人再加一个安装点（`D-R2` 的复制粘贴形态），本程序集会**静默**把"名字解析不到"推迟到远端的 `DllNotFoundException`，而不是在安装点报错。**ORDER-DEPENDENT（潜伏）**，修法 = F2。

### C4 · `WpfGfx.Linux` 程序集（JIT）与 AOT 镜像（**两个运行时**）：单点，但产品侧唯一的静态构造在这

- 站点 S4：`src/WpfGfx.Linux/Windowing/X11Native.cs:29-35`
  ```csharp
          // 显式静态构造函数：保证任何一次 P/Invoke 之前 resolver 已经注册。
          // （没用 [ModuleInitializer]，因为它是给应用代码用的，在库里会触发 CA2255，
          //   而本工程的基线上限是 0 警告。）
          static X11Native()
          {
              NativeLibrary.SetDllImportResolver(typeof(X11Native).Assembly, X11LibraryResolver.Resolve);
          }
  ```
- **谁和它同进程**（按引用形态分列，`samples/*/*.csproj` 现场读数）：`samples/HelloMil/HelloMil.csproj:42` 是 **`ProjectReference`**（`<ProjectReference Include="../../src/WpfGfx.Linux/WpfGfx.Linux.csproj" />`）；`samples/HelloWpf/HelloWpf.csproj:139-179` 与 `WpfFeatureProbe`/`WpfTextDemo` 走 **`HintPath` 引 `build/*.Linux/bin/Debug/*.dll`**（`grep -rn 'WpfGfx.Linux\|PresentationCore\|HintPath' samples/*/*.csproj` 的读数；`HelloWpf` 的注释 `:74-80` 自述"自产四件套 HintPath"），`HelloWpf` 输出目录里实测躺着四件产品的拷贝（见 C1 的 `samples/*/bin/**` 读数）；测试侧：`tests/.../Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj:96` 用 `ProjectReference`，`tests/.../ManagedLayer.Tests/ManagedLayer.Tests.csproj:105-108` 用 `HintPath` 引 `WpfGfx.Linux.dll`（`Private=true`）。⇒ 这些宿主都可能让这个静态构造跑起来。**但没有任何第二个安装者指向 `WpfGfx.Linux`**（9 站点全枚举；`grep -rn -a 'typeof(X11Native)' . --exclude-dir=upstream | grep -v R17C-audit.md` 只剩 `src/WpfGfx.Linux/Windowing/X11Native.cs:34` 本身）⇒ 今天 **SAFE**。
- **AOT 镜像里的同一份代码（proven 存在）**：`wpfgfx_cor3.so` 含 `X11Native=1`、`X11LibraryResolver=1`、`NativeSearchPath=1`、`MilCoreStandaloneInstaller=0`、`MilCoreDllImportResolver=0`（§1.3）。`MilBridge.Linux.csproj:50` 用 `ProjectReference` 引 `WpfGfx.Linux.csproj` ＋ `:56 <TrimmerRootAssembly Include="WpfGfx.Linux" />` ⇒ 整程序集连静态构造一起被钉进镜像。
- **跨运行时不构成冲突（reasoning，非实测）**：AOT 镜像自带**另一个 .NET 运行时**（本仓自己两处这么写：`src/WpfGfx.Linux/Interop/MilHandleTables.cs:593`「（`wpfgfx_cor3.so`）里 —— **那是另一个 .NET 运行时**，静态状态与托管侧…」；`MilNative.FontFace.cs:7` 同义）。解析器表是**每个运行时实例**的状态 ⇒ 宿主的 `X11Native` 注册与镜像内的注册**互不可见**。**注**：镜像内 `typeof(X11Native).Assembly` 到底返回 `WpfGfx.Linux` 身份还是镜像自身身份，**reading 不可定**（§7-③）；但两种情形下该目标程序集都**只有这一个**安装者（镜像里的另一安装者 S3 指向 **SkiaSharp**，`:47-49` 的注释也明说这一点：「这里对 SkiaSharp 注册不会与 MilCore 的解析器冲突」）⇒ 仍 **SAFE**。
- **风险**：它是**产品源里唯一的静态构造安装点**。静态构造抛 ⇒ 类型被投毒（`TypeInitializationException`），且 `X11Native` 是 `WpfGfx.Linux` 全部 X11 呈现路径的入口（`X11PresentationTarget` 等）⇒ 投毒半径 = 该进程里所有经 `WpfGfx.Linux` 的建窗/呈现。修法 = G2。

### C5 · 其余三件产品程序集（WindowsBase / UIAutomationTypes / UIAutomationProvider）：各 1 点

S1 在这三件里各实例化一次（§1.3 产物证据：四件各含 `Win32ShimResolver` 字符串且互不串命名空间）。**没有任何安装者指向它们**：9 站点里"目标程序集"分别落在 PC / SkiaSharp / WpfGfx.Linux / 两个测试程序集 / 三个 harness exe / SmokeTest exe / 真 PC(Windows)，**没有一个**落在 WB / UIAutomationTypes / UIAutomationProvider 上 ⇒ **SAFE**。附注（本仓已闭环的历史教训）：`UIAutomationLinuxTests.cs:3-8` 记的 `D1` 就是"这两件**当初没编进** `Win32ShimResolver` ⇒ `PresentationNative_cor3.dll` DllNotFound"；现在的状态由 `build/UIAutomationTypes.Linux/UIAutomationTypes.Linux.csproj:95`、`build/UIAutomationProvider.Linux/UIAutomationProvider.Linux.csproj:65` 各一条 `<Compile Include>` 保证，**每件各一次**（`grep -rc 'Win32ShimResolver.cs' <四个 csproj>` ⇒ 全部 = 1）⇒ 不存在"同一程序集编进两份"的产品侧双装。

### C6 · harness exe 们（S2×3 / S8）：各 1 点 ⇒ SAFE

`MilCoreStandaloneInstaller.cs` 被链进 3 个 harness，`typeof(MilCoreStandaloneInstaller).Assembly` 在各自 exe 里 = **该 exe 自己的程序集**，且都带守卫＋`InstallConflict` 诊断位（`:23`、`:33-36`）；`ClosedLoop/Program.cs:190` 把它打印出来。**没有任何别的安装者指向这些 exe 程序集** ⇒ SAFE。

### 3.1 名字映射差异（任务书的分类 (d)：即使不抛，输家的名字会静默解析不到）

| # | 名字 | 谁映射 | 差异与后果 |
|---|---|---|---|
| N1 | `WindowsCodecs.dll` | PC 侧 S1（`:107-124`）／harness S7（`:125`） | **同名不同源**：今天是同一个文件（env 指同路径），但**决定权在 PC 侧**；若两者分叉，harness 会静默测**另一个 .so**（其自述症状是 MIL 句柄在另一张 `g_objs` 表里 ⇒ `MILQueryInterface` 返 `E_HANDLE`，会伪装成"MIL 补丁没生效"，见 `WicClosedLoop/Program.cs:77-83`）。 |
| N2 | `ole32.dll` | **只有** PC 侧 S1，且在 `#if PRESENTATION_CORE` 里（`:216` 起）、`ole32` 属 WIC 组（`:111-123`） | 若 S7 曾经赢，PC 里 `ole32.dll` 就**没人接**了——而 `FontEntryClosedLoop/run-font-harness.sh:45` 的严格模式明确依赖 PC 侧映射：「MODE=严格（不设 `LD_LIBRARY_PATH`：ole32.dll 只能靠 PC 的 `WicMappedLibraries` 解析）」。⇒ **"谁赢"直接决定某些名字能不能解析**，这正是任务书说的"输家名字静默失效"。今天方向固定，**良性但不可依赖**。 |
| N3 | `user32.dll` / `gdi32.dll` / `kernel32.dll` / `PresentationNative_cor3.dll` / `libwpfwin32.so` | S1（每件产品程序集）＋ S5/S6（每个测试程序集） | 四条名字两组映射到**同一个** `libwpfwin32.so`，**跨程序集** ⇒ 不冲突；但**赢家决定搜索顺序**（测试侧含 `WPF_LINUX_ROOT` 候选：`ManagedLayer.Tests/X11Guard.cs:115-117`；PC 侧含 `WPF_LINUX_ROOT`＋仓库向上查找：`Win32ShimResolver.cs:382-399`）。若测试侧输掉，其 `[DllImport("user32.dll")]` 会退回默认探测 ⇒ `DllNotFoundException`。 |

---

## 4. 排名修复清单（test/host 与 product/shim 分开）

### 4.A 测试/宿主修复（**不改变任何产品产物**，任何时刻可做，不进 wave）

| 排名 | file:line | 一行描述 | 理由 |
|---|---|---|---|
| **F1** | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/SystemParametersInfoTests.cs:32`（类声明处，仿 `DP1ReproTests.cs:59,73`） | 加 `static SystemParametersInfoTests() { _ = Win32Shim.LoadedPath; }` | ⇒ 本类 6 处 `[DllImport("user32.dll")]`（`:40-41`）的调用点（`:125/:180/:206/:234/:253/:269`）**不再依赖 xUnit 的类顺序**去等别人触发全程序集唯一的安装点。机理 proven（见 §3-C2），只是"今天是否会红"不可读（§8-②）——但这一行成本为一、消除了一个与 `D-R2` **同症状**的间歇红来源。 |
| **F2** | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs:179-182` 与 `tests/WpfGfx.Linux.Tests/Presentation.Tests/X11Guard.cs:98-101` | `catch (InvalidOperationException)` 里**记一个可断言的位**（如 `public static bool ResolverConflict { get; private set; }`），并加一条 `[Fact]` 断言它为 `false` | 现在的 `catch` 把"有人抢了槽位"变成**静默**。D-R2 的教训是"静默吞异常 = 后面花几天误判成机器负载"；把冲突变成**有名字的断言**，既保留"输掉不算失败"的语义，又保住可诊断性。**纯测试侧**。 |
| **F3** | `build/DirectWrite.Linux/WicClosedLoop/Program.cs:118-142`（＋ `:51`/`:132` 只写不读的 `_resolverInstalled`） | 把"注定输的自装"改成**对生效解析器的断言**：断言 `WindowsCodecs.dll` 确实被 PC 侧 `Win32ShimResolver` 接管、且实际 `dlopen` 到的是 `_shimPath`（`/proc/self/maps` 或 `NativeLibrary.Load` 句柄比对） | 让"harness 以为自己在测 A，实际测的是 B"不可能发生（§3-C1/N1）。宿主侧，产物无关。 |
| **F4** | `build/DirectWrite.Linux/FontEntryClosedLoop/DirectWrite.Linux.FontEntryClosedLoop.csproj:5-10` 与 `build/DirectWrite.Linux/WicWriteClosedLoop/DirectWrite.Linux.WicWriteClosedLoop.csproj:5-10` | 删掉/改正「【为什么它自己装 DllImportResolver】… 本 harness 用与 `MilCoreStandaloneInstaller` 同一套"独立宿主自装解析器"的办法：对 **PresentationCore 程序集**装一个解析器」这段**假陈述** | 这两个工程**一处安装都没有**（`grep -c 'SetDllImportResolver' <两个 Program.cs>` ⇒ 0/0；正对照 `grep -c 'using System' <同文件>` ⇒ 7/7），而 `run-font-harness.sh:45` 明说依赖 **PC 侧**映射。假陈述会让下一个读者对解析器拓扑判断错（正是 R17C 这类审计最怕的噪声）。 |
| **F5** | `build/MilBridge/spike/SmokeTest/Program.cs:34-44` | 给这个 `[ModuleInitializer]` 补 `try/catch`（或注明"独占程序集、无竞争者，刻意不加"） | Spike 独占自己的 exe 程序集 ⇒ 今天 SAFE；统一纪律，避免被复制成模板。 |
| **F6** | `src/WpfGfx.Linux.Native/tools/check-shim-coverage.py`（其 `load_mapped()` 在 `:104` 起、解析 `MappedLibraries` 的正则在 `:117`，已在读 `Win32ShimResolver.cs` 的 ground truth） | 增加一条**"每个程序集至多一个安装点"**的机械检查：扫四个产品 csproj 的 `<Compile Include>` 集合与全仓 9 个安装点的目标程序集表达式，>1 即非零退出 | 现在"产品件只允许一个自装器"**只靠注释**（`MilCoreDllImportResolver.cs:4-20`、`MilCoreStandaloneInstaller.cs:3-8`、`PresentationCore.shims.txt:21-24`）与一处 `#error`（只挡"常量写错"，不挡"多编一个文件"）。工具侧，产物无关，可随时做。 |

### 4.B 产品/shim 修复（**改变被编译产物 ⇒ 冻结基线失效 ⇒ 必须排进 wave**）

| 排名 | file:line | 一行描述 | 理由 |
|---|---|---|---|
| **G1** | `build/shims/Win32ShimResolver.cs:171-176` | 给 `[ModuleInitializer] Register()` 加 `try { … } catch (InvalidOperationException) { s_conflict = true; }` ＋ 一个可读的诊断（如 `internal static bool ResolverConflict`／经既有诊断导出暴露） | 它是**四件产品程序集**的自装器，且**未加守卫**：一旦输掉，抛的是**模块初始化器**里的未捕获异常 ⇒ 不是"某个用例红"，而是**整个模块（PC/WB/UIAutomation*）的所有类型全灭**。今天靠"模块初始化器在模块加载期先跑"挡着（实测 `REPORT.md:1021` 那一次）。加守卫的代价是**把致命投毒换成静默降级**，所以**必须同时**把冲突做成可观测（否则就复刻了 D-R2 的静默吞）。**wave 项**：`build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt:45` 记着 `file=ff3c53964cb8328b  build/shims/Win32ShimResolver.cs`（本文件当前 sha16 一致），文件头 `fp=3ffb245017622e10`、`n=1369` ⇒ 改这一行即**破 PC/WB/UIAutomation 的冻结基线**，需与基线重冻同波。 |
| **G2** | `src/WpfGfx.Linux/Windowing/X11Native.cs:32-35` | 同款 `try/catch` ＋ 诊断位（或改成"幂等位 + 显式入口"，与 S2/S3 的形态统一） | 产品源里**唯一的静态构造安装点**，投毒半径 = `WpfGfx.Linux` 的全部 X11 路径（§3-C4）。**wave 项**：改它要重建 `WpfGfx.Linux.dll`，并经 `MilBridge.Linux.csproj:50,56` 的 `ProjectReference`＋`TrimmerRootAssembly` 进 AOT 镜像（`wpfgfx_cor3.so`，sha16 `caf7baf9e67719aa`），需连带重冻 bridge 指纹（`build/bridge-src-fp.sh`）。**注**：`grep -n 'X11Native' build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt` ⇒ **无命中** ⇒ 它**不在** PC 的 `ARTIFACT-SRC-FP` 名单里（名单只含 `build/shims/**` 与上游被编译源），所以 G2 的"破基线"范围是 MilBridge/WpfGfx.Linux 一侧，**不是** PC 那份 `fp=3ffb245017622e10`。 |
| **G3** | `build/shims/Win32ShimResolver.cs` ＋ 既有诊断面（如 `MilBridge_Diag_*`／`Win32ShimResolver.LoadedPath` 一类，`:403-410`） | 暴露"**本程序集的解析器到底是不是我装的**"这一读数 | 让"产品侧丢了槽位"在**运行期**可判（今天只能靠 `InvalidOperationException` 的**有无**间接判，而 G1 之后连异常都没了）。建议与 G1 同波落地。 |

**排序理由**：F1/F2 是"今天就可能以同症状咬人"的活风险且零成本；F3/F4 消除"测试在测错东西"；F6 把纪律机械化；G1/G2 是"概率低、后果最大"的预防项，且**必须成波**——这也是为什么它们排在 test/host 项之后而不与之混做。

---

## 5. 被推翻 / 被更正的说法（撤回声明优先于辩护）

1. **【推翻：任务书里的仓库根路径】** 任务书给的绝对路径 `/home/links-dev/wpf-linux-20260906/wpf-linux` **不存在**（`ls -ld /home/links-dev/wpf-linux-20260906` ⇒ `没有那个文件或目录`，exit 2）。真实路径 = **`/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`**（= 本会话工作目录 + `/wpf-linux`）。本轮所有证据都基于后者；前者下的任何读数都不可能存在。
2. **【更正：`D-R2` 两个"肇事点"的现状描述】** 任务书描述的 `X11Guard.cs:163`「static ctor 装一个、无守卫无 catch」与 `DP1ReproTests.cs:63`「static ctor 装一个、静默吞异常」是**修复前**的版本：今天 `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs:164-182` 已是**带注释的守卫版**（`catch (InvalidOperationException)`，行 179），`DP1ReproTests.cs:61-73` 已**不装**任何东西（`63` 行现在是注释文本，`:73` 是 `_ = Win32Shim.LoadedPath;`）。**并且产物已同步**：两个测试 dll（`3bd37556b50f9a71` @23:27:37、`820ba282a5e62dfc` @23:27:41）晚于两个源文件（23:27:10 / 23:27:22）⇒ **当前验证序列跑的那份程序集里没有这个 bug**。
3. **【推翻：两个 harness 的 csproj 自述】** `FontEntryClosedLoop/*.csproj:5-10` 与 `WicWriteClosedLoop/*.csproj:5-10` 声称"本 harness 自己对 PresentationCore 装解析器"。**实测 0 处**：两个 `Program.cs` 里 `SetDllImportResolver` 计数 = 0/0（正对照 `using System` = 7/7，证明文件可 grep）；反过来 `run-font-harness.sh:45` 写着「ole32.dll **只能靠 PC 的** `WicMappedLibraries` 解析」。⇒ 该注释是**假陈述**（应为从 `WicClosedLoop` 复制而来，见 F4）。
4. **【更正：`WicClosedLoop` 的"自装"是一条活路】** 它**不可能赢**（§3-C1，实测 `REPORT.md:1021`），且它记下来的 `_resolverInstalled` **只写不读**（`:51`、`:132`，全仓无读）⇒ 该 harness 的 WIC 闭环**只能**依赖 PC 侧映射——这一条与 `REPORT.md:1022-1023` 的结论一致，但**没有**任何断言守着它（F3）。
5. **【维持（本仓说法正确）】** `build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs:20`「MilCoreStandaloneInstaller.cs —— 只有它才会去 `SetDllImportResolver`」——`MilCoreDllImportResolver.cs` 全文**无** `SetDllImportResolver(` 调用（§1.1 的 9 站点名单里没有它）⇒ **成立**。`build/shims/PresentationCore.FontBridge.cs:357-360`「本类**不**调用 `SetDllImportResolver`，不会与它抢槽位」——同文件唯一命中都在注释里，唯一 `[ModuleInitializer]`（`:368-369`）只调 `FontFaceBridge.Install()`，而 `Install()`→`ProbeMilExport()` 全程 `try/catch`（`ProbeMilExport` 内 `catch (Exception) {}`）⇒ **成立，且不会投毒 PC 模块**（附加读数：PC 产物含 `FontFaceBridgeModuleInitializer` = 1，即确实编进去了）。

---

## 6. 读数表（sha16 + size + mtime；纪律 32）

**环境**：`lane=R17C`｜`kernel=6.8.0-138-generic`（x86_64, VirtualBox）｜时刻见下两行｜`/proc/loadavg` 与 `free -m` 取值如下。

| 项 | 开头 2026-09-15T23:28:06+08:00 | 收尾 2026-09-15T23:31:41+08:00 | 落盘 2026-09-15T23:34:56+08:00 |
|---|---|---|---|
| `/proc/loadavg` | `0.72 1.02 0.63 6/639 1419356` | `0.72 0.93 0.68 2/636 1425385` | `0.83 0.86 0.70 2/573 1430435` |
| `mem_available` (`free -m`) | **3706 MB**（total 7923 / used 3734 / free 163 / buff 4025 / swap used 938） | **3776 MB**（used 3664 / free 197 / buff 4061 / swap used 952） | **3900 MB**（used 3598 / free 687 / buff 3637 / swap used 952） |

> ⚠️ 同上：本轮是**纯读取**审计，两条 loadavg 只用于纪律 32 的出处记录，**不可**当作性能/静树读数（R17A/R17B 的同类声明同样适用）。

| sha16 | size | mtime | path |
|---|---|---|---|
| `ff3c53964cb8328b` | 24117 | 2026-09-11 16:50:50 | `build/shims/Win32ShimResolver.cs` |
| `d06088eb854df1ab` | 19407 | 2026-09-11 18:43:28 | `build/shims/PresentationCore.FontBridge.cs` |
| `e94786d6e2b11b5d` | 2397 | 2026-09-10 20:01:24 | `build/shims/PresentationCore.shims.txt` |
| `23a1fec326b3cd03` | 810 | 2026-09-10 14:51:12 | `build/shims/WindowsBase.shims.txt` |
| `bda5abcfe9adac1a` | 67 | 2026-09-11 16:52:07 | `build/shims/UIAutomationTypes.shims.txt` |
| `7387f01da2f2777b` | 33 | 2026-09-11 16:50:50 | `build/shims/UIAutomationProvider.shims.txt` |
| `da73fd4ee9da722f` | 1736 | 2026-09-10 15:10:16 | `build/MilBridge/src/MilBridge.Resolver/MilCoreStandaloneInstaller.cs` |
| `d2e034e81ce265bc` | 8180 | 2026-09-10 15:11:35 | `build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs` |
| `347d4a475ab62197` | 1667 | 2026-09-10 15:05:09 | `build/MilBridge/src/MilBridge.Resolver/README-合并写.txt` |
| `e32d24ca00be2b91` | 9721 | 2026-09-10 18:04:14 | `build/MilBridge/src/MilBridge.Linux/NativeSearchPath.cs` |
| `7db47d37b943f312` | 2901 | 2026-09-10 15:07:38 | `build/MilBridge/src/MilBridge.Linux/MilBridge.Linux.csproj` |
| `f4eddc41d6c184ea` | 4456 | 2026-09-10 14:54:24 | `build/MilBridge/spike/SmokeTest/Program.cs` |
| `ef09e6e09e8e6f75` | 26868 | 2026-09-10 19:54:18 | `build/DirectWrite.Linux/WicClosedLoop/Program.cs` |
| `46e0155f88ef2755` | 3265 | 2026-09-10 17:43:17 | `build/DirectWrite.Linux/WicClosedLoop/DirectWrite.Linux.WicClosedLoop.csproj` |
| `d5d9beaa8e75354b` | 3271 | 2026-09-10 20:00:46 | `build/DirectWrite.Linux/FontEntryClosedLoop/DirectWrite.Linux.FontEntryClosedLoop.csproj` |
| `db296e6f2422ef2a` | 3725 | 2026-09-10 20:00:46 | `build/DirectWrite.Linux/FontEntryClosedLoop/run-font-harness.sh` |
| `cc46fef28981fc77` | 3270 | 2026-09-10 19:44:27 | `build/DirectWrite.Linux/WicWriteClosedLoop/DirectWrite.Linux.WicWriteClosedLoop.csproj` |
| `2e9a3c91040dbe66` | 308611 | 2026-09-15 12:34:33 | `build/DirectWrite.Linux/REPORT.md` |
| `045faa9b0785f6d2` | 10521 | 2026-09-10 16:11:54 | `src/WpfGfx.Linux/Windowing/X11Native.cs` |
| `f38feba94f6f788f` | 1046 | 2026-09-01 08:20:09 | `src/WpfGfx.Linux/WpfGfx.Linux.csproj` |
| `1f46443e86553876` | 10950 | 2026-09-15 23:27:10 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs` |
| `1a7bc29203853850` | 41668 | 2026-09-15 23:27:22 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/DP1ReproTests.cs` |
| `6aea67618fc8bb03` | 14920 | 2026-09-10 15:23:21 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/SystemParametersInfoTests.cs` |
| `2618aed85a598d96` | 15874 | 2026-09-14 20:24:46 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/UIAutomationLinuxTests.cs` |
| `2ac4d1e10c852298` | 6811 | 2026-09-13 22:38:31 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj` |
| `ce211441b3aa5383` | 10306 | 2026-09-15 23:27:14 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/X11Guard.cs` |
| `3d88a79bc054b6e7` | 5255 | 2026-09-10 16:42:30 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/WpfGfx.Linux.Presentation.Tests.csproj` |
| `80ac39a9ff849f03` | 32787 | 2026-09-10 15:28:29 | `tests/parity/windows/src/U1Recorder/Program.cs` |
| `65c46f3c525d8244` | 13513 | 2026-09-10 15:37:19 | `tests/parity/windows/src/U1Proxy/out/recorder-report.txt` |
| `68d961def360f2b9` | 32263 | 2026-09-10 15:38:44 | `docs/U1-windows-probe.md` |
| `2511425c711dd888` | 39029 | 2026-09-10 15:10:10 | `docs/U2-M7b-report.md` |
| `b07cce3f2e7cf51a` | 11824 | 2026-09-10 16:21:23 | `src/WpfGfx.Linux.Native/tools/check-shim-coverage.py` |
| `e2558faa0cc6b5d1` | 205471 | 2026-09-15 18:37:23 | `build/PresentationCore.Linux/PresentationCore.Linux.csproj` |
| `85f73a258528c9ac` | 47832 | 2026-09-15 18:37:23 | `build/WindowsBase.Linux/WindowsBase.Linux.csproj` |
| `4e1ad23b1d7c2516` | 12389 | 2026-09-15 18:37:22 | `build/UIAutomationTypes.Linux/UIAutomationTypes.Linux.csproj` |
| `490a0f199e616f7e` | 7701 | 2026-09-15 18:37:22 | `build/UIAutomationProvider.Linux/UIAutomationProvider.Linux.csproj` |
| `21fa957ab1daf8df` | 1337 | 2026-09-10 15:10:22 | `build/MilBridge/tests/ClosedLoop/ClosedLoop.csproj` |
| `fa906d8c7208177a` | 1540 | 2026-09-10 17:20:57 | `build/MilBridge/tests/T2Repro/T2Repro.csproj` |
| `ffbe4b2a7bba616e` | 1770 | 2026-09-10 17:30:35 | `build/MilBridge/tests/HbSpike/HbSpike.csproj` |
| `f19778e90190abcf` | 4443 | 2026-09-15 18:39:14 | `build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt`（`fp=3ffb245017622e10`、`n=1369`、`peer_fp=1d8a7cf4b46dc3c9`） |
| `c0763fc10173e7ff` | 4194816 | 2026-09-15 18:38:14 | `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` |
| `e6216fe961a2bfb9` | 1241088 | 2026-09-15 18:37:37 | `build/WindowsBase.Linux/bin/Debug/WindowsBase.dll` |
| `2ac8d37b7cdc5afd` | 227840 | 2026-09-15 18:37:45 | `build/UIAutomationTypes.Linux/bin/Debug/UIAutomationTypes.dll` |
| `352ccd757a2f2fb0` | 41472 | 2026-09-15 18:37:50 | `build/UIAutomationProvider.Linux/bin/Debug/UIAutomationProvider.dll` |
| `0c597fb6ec1eec70` | 357888 | 2026-09-15 12:38:40 | `src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` |
| `caf7baf9e67719aa` | 4983696 | 2026-09-15 12:43:18 | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` |
| `3bd37556b50f9a71` | 146432 | 2026-09-15 23:27:37 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/bin/Debug/net10.0/WpfGfx.Linux.ManagedLayer.Tests.dll` |
| `820ba282a5e62dfc` | 29184 | 2026-09-15 23:27:41 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/bin/Debug/net10.0/WpfGfx.Linux.Presentation.Tests.dll` |
| `17ee1284313749f7` | 437808 | 2024-11-07 21:55:12 | `~/.nuget/packages/skiasharp/2.88.9/lib/net6.0/SkiaSharp.dll`（S3 的"无竞争者"正向证据；其余 38 个 TFM 变体同样为 0） |

---

## 7. 只读手段**做不到**的事 + 能定案的确切命令

| # | 未能确立（**NOT established / not measurable by reading**） | 为什么读不出来 | 定案命令（**需要跑**，故不在本轮执行） |
|---|---|---|---|
| ① | **"模块初始化器一定先于外部 `SetDllImportResolver` 跑"是否是可依赖的保证**（§3-C1 的产品侧唯一真风险）。本仓只有**一次**观测（`REPORT.md:1021`），而 `ModuleInitializer` 的**契约**只说"在模块内任何代码执行前"，CoreCLR 当前实现是模块加载期跑——**契约措辞**本轮无法取证：本机 GitHub/官方文档拉取被挡（`web_fetch https://github.com/dotnet/runtime/issues/35749` ⇒ `TypeError: fetch failed`；与仓内记录的 GitHub/NuGet 被阻断一致）。 | 运行时实现细节，非本仓代码可判 | 已在仓内、可离线跑的最小复现：`dotnet build build/DirectWrite.Linux/WicClosedLoop/…` 后 `WIC_SHIM_MAPS=1 … dotnet …/WicClosedLoop.dll`，看 `RESOLVER_INSTALLED=` 是 `False`（今天的预期，宿主输）还是**出现** `InvalidOperationException` 反向抛在 PC 模块初始化（= 产品输 ⇒ 投毒）。**命令形态**（本轮**未执行**）：`bash build/DirectWrite.Linux/WicClosedLoop/run-harness.sh 2>&1 \| grep -E 'RESOLVER_INSTALLED\|RESOLVER_NOTE'`。 |
| ② | **`ManagedLayer.Tests` 里 xUnit 的类/集合执行顺序**是否真的会让某个 `SpiW` 用例先跑（§3-C2 的残留红概率）。 | 需要运行时观测 | `dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj --logger 'console;verbosity=detailed' 2>&1 \| grep -E 'SystemParametersInfoTests\|DllNotFoundException\|user32\.dll'`（看是否有 `DllNotFoundException: user32.dll`，以及用例顺序）。**无论结果如何 F1 都值得做**（把"顺序依赖"变成"无顺序依赖"）。 |
| ③ | **AOT 镜像内 `typeof(X11Native).Assembly` 返回的身份**（`WpfGfx.Linux` 还是镜像自身），以及**镜像内 `X11Native` 的静态构造今天到底跑不跑**（X11 呈现是否真的在 .so 内部发生）。 | NativeAOT 运行期语义 + 死代码裁剪结果，reading 不可判 | `dotnet build` 后：`strings` 之外要看**运行期**——例：在 `wpfgfx_cor3.so` 的 X11 被首次触达的路径上加/读诊断导出（`MilBridge_Diag_*` 面上已有自定位目录，`:73`），跑一次 Presentation 测试后读它；或 `nm -D wpfgfx_cor3.so` 配合 `ILC` 的 `--map`/`IlcGenerateMapFile` 看 `X11Native::.cctor` 是否保留。**本轮未执行**（需重建/跑测）。 |
| ④ | **S9（Windows U1Recorder）在真 Windows 上的现状**。 | 本机不可能跑 Windows 侧 | `powershell tests/parity/windows/src/U1Proxy/runproxy2.ps1`（其 `:28` 已经 grep `SetDllImportResolver`）；或直接看 `tests/parity/windows/src/U1Proxy/out/recorder-report.txt:2`（历史记录已 = `SetDllImportResolver: OK`）。 |
| ⑤ | `_resolverInstalled`（`WicClosedLoop/Program.cs:51,132`）**是否曾在其它分支被读**（本轮只审工作树，未查历史）。 | 只读工作树；未查 git 历史（`git log` 亦未跑，避免与验证序列争 IO——非必要不跑） | `git -C <repo> log -p --follow -- build/DirectWrite.Linux/WicClosedLoop/Program.cs \| grep -n '_resolverInstalled'`。 |

---

## 8. 一句话回报（给主控）

> lane=R17C｜**9 个 `SetDllImportResolver` 安装点（14 个程序集实例）、2 处同程序集冲突（PresentationCore 上的"产品 `[ModuleInitializer]` × WIC harness"；以及 Windows 侧 U1Recorder × 真 PC，实测无冲突）**；`D-R2` 的旧址（`ManagedLayer.Tests`）已确认**只剩 1 个安装点且产物已含修复**；**产品侧今天不存在"同一程序集被装两次"的路径**，但两处未加守卫的产品侧安装点（`Win32ShimResolver.cs:171-176` ×4 程序集、`X11Native.cs:32-35` 静态构造）的"输掉"分支是**投毒级**，建议作为 wave 项（G1/G2）处理；**最该马上做的是 F1（一行）与 F2（把静默 `catch` 变成可断言位）**——它们属于"与 `D-R2` 同症状、但被 `D-R2` 的修复顺手引入"的新间歇红来源。

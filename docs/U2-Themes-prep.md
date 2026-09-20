# WPF 主题程序集移植预研（PresentationFramework.Classic）—— M2 最后一环

> 目标：补上 `PresentationFramework.Classic`（控件默认样式/模板的**唯一来源**），
> 解开 M7c 定位到的「窗口已映射、渲染管线齐全，但 `Window.Template == null` ⇒ 可视树恒空、画面全白」。
> 本轮产出 **0 错 0 警**、身份/资源/查找链全部实测通过，并给出部署指令与其余主题的后续清单。
> 上游全程只读；实测环境 dotnet SDK 10.0.111 / net10.0 / Linux x64。

## 0. 一句话结论

`build/PresentationFramework.Classic.Linux` 出 **`PresentationFramework.Classic.dll`（267,264 B，v4.0.0.1，PKT=31bf3856ad364e35）**，
内含清单资源 **`PresentationFramework.Classic.g.resources`**，其键 **`themes/classic.baml`（208,387 B）**
正是 PF `SystemResources.LoadExternalAssembly/LoadDictionary` 查找的两级名字。
自验证探针 **PASS=15 / FAIL=0**：按名加载（含 `"PresentationFramework.classic"` 小写部分名）✓、
`ResourceManager("PresentationFramework.classic.g").GetStream("themes/classic.baml")` 非空 ✓、
pack URI 载入字典 204 个键 ✓、`Window` 的隐式 `Style` 取到且其 `Template` 是 `ControlTemplate` ✓、
`Window.ApplyTemplate()` 通过 ✓。

**部署的硬条件（实测，容易踩）**：产物必须①放进 app 目录 **且**②进 app 的 `deps.json`
——只把 DLL 拷到同目录**不够**：默认 AssemblyLoadContext 只按 `deps.json`/TPA 解析，
`Assembly.Load("PresentationFramework.classic, Version=4.0.0.1, …, PublicKeyToken=31bf3856ad364e35")`
会 `FileNotFoundException`（探针 [2] 有对照实测）。故部署＝在 app 工程里加一行 `<Reference>`（见 §5）。

---

## 1. 上游工程实际清单（交付物 ①）

`upstream/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Classic/`

| 类型 | 内容 |
|---|---|
| csproj | `PresentationFramework.Classic.csproj`（`Page` 1 个、`Compile` 8 个、`DefineConstants=THEME_CLASSIC`、`InternalMarkupCompilation=true`、`NoInternalTypeHelper=true`、`GenerateDependencyFile=false`） |
| XAML | `Themes/Classic.xaml` —— **9,522 行**，根元素 `<ResourceDictionary>`（**无 x:Class**），是主题模板的唯一来源 |
| 本地 .cs | `Microsoft/Windows/Themes/ClassicBorderDecorator.cs`、`Microsoft/Windows/Themes/DataGridHeaderBorder.cs` |
| 共享 .cs | `Themes/Shared/Microsoft/Windows/Themes/` 下 5 个：`DataGridHeaderBorder.cs`、`KnownTypeHelper.cs`、`PlatformCulture.cs`、`SystemDropShadowChrome.cs`、`ProgressBarBrushConverter.cs` |
| 其它 | `Shared/RefAssemblyAttrs.cs`（第 8 个 Compile）、`ref/PresentationFramework.Classic{,-ref}.csproj`（引用程序集，跳过） |
| 上游引用 | PresentationUI / System.Xaml / WindowsBase / PresentationCore / PresentationFramework（+ 自引用 ref，`ReferenceOutputAssembly=false`） |

**XAML 对外部程序集的依赖（grep 实测，决定我们引用什么）**：
`assembly=PresentationFramework`（`framework:FrameworkAppContextSwitches`）、`assembly=PresentationUI`
（`ui:PresentationUIStyleResources` ×2）、`assembly=WindowsBase`（`base:AccessibilitySwitches`）；
其余 `theme:` 前缀是**本程序集**类型（ClassicBorderDecorator / DataGridHeaderBorder / PlatformCulture /
ProgressBarBrushConverter / SystemDropShadowChrome —— **全部 public**，这一点在 §4 的补丁 F 里是关键论据）。

## 2. 生成方式：port-lib + 补丁脚本（交付物 ②）

```bash
python3 build/port-lib.py PresentationFramework.Classic          # 生成骨架（可重放）
python3 build/PresentationFramework.Classic.Linux/reapply-patches.py   # 补上 XAML/标记编译链（幂等）
dotnet build build/PresentationFramework.Classic.Linux/PresentationFramework.Classic.Linux.csproj -m:1
# [PresentationFramework.Classic] 源文件 8（找回 0）/ 缺失 0 | 丢弃 PR 6(vcx 0) 私有 0 Target 0 Import 0
# 提示：跳过 -ref 引用 PresentationFramework.Classic-ref（若是某某组件的唯一托管面，需手工建工程）
# 已成功生成。 0 个警告 0 个错误
```

**为什么不是纯 port-lib**：port-lib 只收集 `Compile`/`EmbeddedResource`，**不处理 XAML `<Page>`** ——
而本主题程序集的全部价值就在 `Classic.xaml` 编出来的 BAML。故按主控给的退路，
用 `reapply-patches.py`（照 T3/HelloWpf 那套**已验证**的链）补齐标记编译；
其余一切（Compile 清单、引用、身份、签名、`GenerateDependencyFile=false`）**都走 port-lib 生成**。

port-lib 生成物里已经正确的部分（实测）：AssemblyName=`PresentationFramework.Classic`、
`DefineConstants=THEME_CLASSIC;WINDOWS_BASE_OR_PC`、System.Xaml/WindowsBase/PresentationCore/PresentationFramework
四条本地引用、`LinuxAssemblyIdentity.cs`（4.0.0.1）、**PublicSign + WcpPublicKey.snk**、
`GenerateDependencyFile=false`、NoWarn 自动搬运。

补丁脚本内容（**幂等**：连续跑三次 csproj md5 不变，实测）：

| 补丁 | 内容 | 理由（实测/出处） |
|---|---|---|
| A | `Page Include="…/Classic.xaml"` + `Generator=MSBuild:Compile` / `XamlRuntime=Wpf` / `SubType=Designer` | `UseWPF=false` 后 SDK 的 XAML 通配（定义在 WindowsDesktop.props，条件 `UseWPF=true`）不再生效，必须显式声明 |
| B | ①`_PresentationBuildTasksAssembly`=自产 PBT(Release)（**必须早于 Sdk.targets**，WinFX.targets 的定义带 `Condition="…==''"`）②显式 `<Import Microsoft.WinFX.targets>`（net10.0 的 SDK 不自动导入 ⇒ 否则 XAML 不编译但**构建成功**）③`<Import build/WpfMarkupCompile.Linux.targets>` | 与 samples/HelloWpf 同一套已验证链 |
| C | `PresentationUI` 引用 → `build/CycleStub.PresentationUI.Linux`（Exists 守卫） | 上游引用 PresentationUI.csproj；port-lib 找不到 `build/PresentationUI.Linux`（本移植由替身顶替，见 `docs/U2-PresentationFramework-prep.md` §6.4） |
| D | `NoWarn CS8002` | 本工程必须公开签名，而 WindowsBase 在本移植工程中未签名（上游全签名故无此警告） |
| E | 构建期自检：标记链存在性 + **BAML 产出断言**（`obj/…/Classic.baml` 必须存在） | 防「构建成功但没产出 BAML」这种最难查的静默失败（T3 教训） |
| F | 摘除/清空 PBT 生成的 `GeneratedInternalTypeHelper.g.cs` | 见 §4（本工程唯一的真问题） |

## 3. 身份 / 签名 / BAML 键名（交付物 ③，全部实测）

```
AssemblyName.GetAssemblyName("PresentationFramework.Classic.dll")
  → PresentationFramework.Classic, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35
```

**为什么是这三个值**（不是照抄，是上游运行期代码决定的）：
`PresentationFramework/System/Windows/SystemResources.cs:764 LoadExternalAssembly(classic: true, …)` 拼出
`_assemblyName + "." + "classic"` = **`PresentationFramework.classic`**，再经
`Shared/MS/Internal/ReflectionUtils.cs:27 GetFullAssemblyNameFromPartialName(_assembly, …)` ——
该函数**取 PF 自己的 FullName 只换 Name** ⇒ 请求的全名是
`PresentationFramework.classic, Version=<PF 的版本>, Culture=neutral, PublicKeyToken=<PF 的 PKT>`。
我们的 PF 是 **4.0.0.1 + WCP 公钥** ⇒ 主题程序集必须同版本同公钥（探针 [2] 用这条全名实测加载成功 ✓）。

**资源键名**（`SystemResources.LoadDictionary` 的两级查找，源码位置：`SystemResources.cs:888-903`）：
1. `new ResourceManager($"{assemblyName}.g", assembly)` ⇒ 基名 **`PresentationFramework.classic.g`**
2. `resourceName = "themes/classic" + ".baml"`（常量 `ClassicResourceName = "themes/classic"`，`SystemResources.cs:1674`）

实测产物：
```
清单资源：PresentationFramework.Classic.g.resources          ← SDK 按 $(AssemblyName) 生成，与第 1 级名字大小写不敏感匹配
.resources 内键（共 1）：themes/classic.baml                 ← 与第 2 级键完全一致
ResourceManager("PresentationFramework.classic.g").GetStream("themes/classic.baml")
  → 208,387 B（非空）                                        ← PF 代码的原样调用，命中
```
> 说明：ResourceManager 对**基名**的清单资源匹配是大小写不敏感的（实测 `…classic.g` 命中 `…Classic.g.resources`），
> 对 **.resources 内的键**是大小写敏感的 —— 我们的键 `themes/classic.baml` 是 SDK 由 `Link=Themes\Classic.xaml` 生成的小写形式，正合查找串。

**已知类型助手**（PF 加载主题程序集后会跑的静态构造，`SystemResources.cs:799-806`）：
`Microsoft.Windows.Themes.KnownTypeHelper` 存在、静态构造可运行 ✓（`THEME_CLASSIC` define 就是给它用的）。

## 4. 唯一的真问题：`GeneratedInternalTypeHelper` 的 CS0507（补丁 F）

**现象**（首轮构建 5 条错误）：
```
obj/Debug/GeneratedInternalTypeHelper.g.cs(24,35): error CS0507:
  "GeneratedInternalTypeHelper.CreateInstance(Type, CultureInfo)":
  当重写"protected internal"继承成员"InternalTypeHelper.CreateInstance(Type, CultureInfo)"时，无法更改访问修饰符
```
**根因（两条实测事实叠加）**：
1. `WindowsBase/System/Windows/Markup/InternalTypeHelper.cs:29` 的成员是 `protected internal abstract`；
2. `WindowsBase/OtherAssemblyAttrs.cs:24` 有
   `[assembly: InternalsVisibleTo(BuildInfo.PresentationFrameworkClassic)]`
   —— **主题程序集是 WindowsBase 的友元**，所以 Roslyn 要求 override 写 `protected internal`
   （internal 部分对它可见），而 PBT 生成的是 `protected` ⇒ 必然 CS0507。

**上游怎么没这个问题**：PBT 的 `MarkupCompilePass2.cs:663-678` 在「本程序集无 internal 需求」时
会把该文件**重写为空**并记 `InternalTypeHelperNotRequired`；我们这条链没有跑到那一步。

**处置（补丁 F）**：把该文件**内容清空**（等价上游行为）并从 `@(Compile)` 摘除。
安全性实测依据：`Classic.xaml` 引用的本地类型 5 个**全部 public**（§1），
helper 只在「BAML 需要解析本程序集 internal 类型/成员」时才被 `XamlTypeMapper` 使用；
PF 源码亦注明 *"We don't actually use the GeneratedInternalTypeHelper any more."*（`XamlReader.cs:1076`）。
> 只做「从 `@(Compile)` 摘除」实测**无效**（PBT 用 `<Output ItemName="Compile">` 注入，摘除时机与 csc 取用存在竞态），
> 故清空文件是主手段、摘除是双保险。

## 5. 自验证探针（交付物 ④）：PASS=15 / FAIL=0

探针在 `/tmp/m5/theme-probe/`（**不进仓库**），做法是把主题程序集当 `<Reference>` 引入（⇒ 进 deps.json、进输出目录），
再走 **PF 运行期实际使用的同一条查找链**：

```
=== [1] 身份 ===                            PASS ×3（名字/版本/PKT）
=== [2] 按名加载 ===                        PASS（Assembly.Load("PresentationFramework.classic, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35") → OK）
=== [3] 清单资源名 + BAML 键名 ===          PASS ×2（PresentationFramework.Classic.g.resources / themes/classic.baml）
=== [4] ResourceManager 原样调用 ===        PASS（GetStream("themes/classic.baml") → 208,387 B）
=== [5] KnownTypeHelper ===                PASS ×2（类型存在 / 静态构造可运行）
=== [6] 端到端（pack URI → Window 模板）===  PASS ×6
      ResourceDictionary 加载成功 → 204 个键
      字典里有 typeof(Window) 的隐式样式 → Style
      Style.TargetType == System.Windows.Window
      样式中设置了 Control.TemplateProperty
      Template 是 System.Windows.Controls.ControlTemplate
      Window.ApplyTemplate() 后 Template 已应用
=== 结果：PASS=15 FAIL=0 ===
```

**对照实验（部署条件的实测依据）**：主题 DLL **只放进 app 目录、不进 deps.json** 时，
`Assembly.Load(简单名/全名)` 全部 `FileNotFoundException`，只有 `AssemblyLoadContext` 之外的手段
（`Assembly.LoadFrom(路径)`）成功；把它改为工程 `<Reference>`（进 deps.json）后**四种加载方式全部成功**
⇒ 「同目录」是必要不充分条件（这正是 M7c 那条 `catch (FileNotFoundException) {}` 静默吞掉的前提）。

**运行期前置条件（探针 [6] 实测踩到）**：pack URI/`Application` 路径需要
① 原生 shim：`WPF_LINUX_WIN32_SHIM=<repo>/src/WpfGfx.Linux.Native/bin/libwpfwin32.so`
（否则 `Application` 静态构造链抛 `DllNotFoundException: kernel32.dll 已映射到 libwpfwin32.so，但没找到可加载的 shim 库`）；
② 一个可连的 X display（`DISPLAY=:0/:1/:99` 均可，不设则 `Win32Exception: Unknown error 1400`）。
这两条是 M7b/M7c 运行器的既有环境，此处仅登记。

## 6. 部署指令（交付物 ⑤）

**推荐（一行，进 deps.json + 自动 copy-local）**——加进 app 工程（M7c runner 用的 `samples/HelloWpf/HelloWpf.csproj`，
引用形态与它现有 8 条自产件一致）：

```xml
<Reference Include="PresentationFramework.Classic"><HintPath>$(WpfLinuxBinDir)/PresentationFramework.Classic.Linux/bin/$(WpfLinuxSelfBuiltConfiguration)/PresentationFramework.Classic.dll</HintPath><Private>true</Private></Reference>
```

**若 runner 不能改工程**（纯文件级部署）：只 `cp` 到 app 目录**不够**（§5 对照实验）。
两条可行退路，任选其一：
```bash
# 退路 A（不改进程）：手工把条目补进 app 的 deps.json（键名即程序集简单名，version 4.0.0.1）
# 退路 B（不改文件）：进程内挂解析钩子（与 M7c 探针同款做法）
#   AssemblyLoadContext.Default.Resolving += (ctx, n) =>
#       n.Name.Equals("PresentationFramework.Classic", StringComparison.OrdinalIgnoreCase)
#           ? ctx.LoadFromAssemblyPath(Path.Combine(AppContext.BaseDirectory, "PresentationFramework.Classic.dll")) : null;
```
> 归属：`samples/HelloWpf/` 由 M7b 维护，本轮按边界**未改动**；上面就是需要他们加的那一行。

## 7. 其余主题工程清单与「何时需要」（交付物 ⑥）

| 主题工程 | Compile | Page | Define | 何时需要 |
|---|---|---|---|---|
| **PresentationFramework.Classic** | 8 | 1 | `THEME_CLASSIC` | ✅ **本轮完成** —— 我们的 `IsThemeActive()=0`（Linux 真话）⇒ `UxThemeWrapper` 解析主题名为 `"classic"` ⇒ 只会走这一支 |
| PresentationFramework.Aero | 12 | 1 | `THEME_AERO` | 仅当 `IsThemeActive()` 返回真且主题名解析为 `aero`（即 shim 开始伪造 Windows 主题） |
| PresentationFramework.Aero2 | 12 | 1 | `THEME_AERO2` | 同上（`aero2`；Win8+ 默认） |
| PresentationFramework.AeroLite | 9 | 1 | `THEME_AEROLITE` | 同上（高对比度/低配） |
| PresentationFramework.Luna | 11 | **3** | `THEME_LUNA` | 同上（`luna`；**3 个 Page** ⇒ 标记编译面更大） |
| PresentationFramework.Royale | 11 | 1 | `THEME_ROYALE` | 同上（`royale`） |
| PresentationFramework.Fluent | 3 | 1 | `THEME_Fluent` | 同上（`fluent`；**注意 define 大小写为 `THEME_Fluent`**，与其它不一致，移植时别照抄成全大写） |

**结论**：只要 `IsThemeActive()` 仍是 0（当前口径），**只需 Classic 一个**；
上表其余 6 个工程本轮的移植方式可直接复用（同一条 port-lib + 同一条补丁脚本，改 3 处：工程名/Define/CycleStub 引用），
但**前提是先决定是否要让 shim 假装 Windows 主题**——那属于运行期语义决策，不在本轮范围。
（`Themes/Shared/` 下 6 个共享文件按各工程 csproj 的 Compile 清单各自编入，无需额外处置；
`Themes/XAML/`、`Themes/Generator/` 是生成器/公共 XAML 片段，本主题工程未引用。）

## 8. 文件清单与边界确认（交付物 ⑦）

| 文件 | 动作 | 说明 |
|---|---|---|
| `build/PresentationFramework.Classic.Linux/PresentationFramework.Classic.Linux.csproj` | 新增（port-lib 生成 + 补丁 A–F） | 8 Compile + 1 Page；0 错 0 警 |
| `build/PresentationFramework.Classic.Linux/reapply-patches.py` | 新增 | 补丁 A–F，**幂等**（三次连跑 csproj md5 不变） |
| `build/PresentationFramework.Classic.Linux/PORT-CHANGES.md` | 新增（自动） | port-lib 改动清单 |
| `build/PresentationFramework.Classic.Linux/bin/Debug/PresentationFramework.Classic.dll` | 新增（产物） | **267,264 B**，v4.0.0.1，PKT=31bf3856ad364e35，内含 `…g.resources` → `themes/classic.baml`（208,387 B） |
| `docs/U2-Themes-prep.md` | 新增 | 本文档 |
| `build/shims/PresentationFramework.Classic.shims.txt` | **未创建** | 本工程不需要 shim（上游零改动 + 引用皆为现成自产件） |
| `/tmp/m5/theme-probe/`（**不进仓库**） | 新增 | 探针工程：`theme-probe.csproj` + `Program.cs`，PASS=15 / FAIL=0 |

**边界确认**：只写了 `build/PresentationFramework.Classic.Linux/` 与本文档；
**未触碰** `src/`（含 `src/WpfGfx.Linux.Native/`）、`build/WindowsBase.*`、`build/PresentationCore.Linux/`、
`build/PresentationFramework.Linux/`、`build/MilBridge/`、`samples/`、`tests/parity/`、
`handoff.md`、`build/port-lib.py`、`verify-all.sh`、`wpf-linux.sln`；`upstream/` 全程只读（mtime 实测零写入）。
构建一律 `-m:1`、增量，未跑 verify-all。

### 附：本轮新增的 port-lib 口径记录
`<Page>`（XAML 标记编译输入）port-lib 不处理 —— 与既有缺口 #2（`-ref` 跳过）/ #3（`WpfCycleBreakersDir` 未定义）
并列，属「需要在补丁脚本里补」的第三类。本主题工程是**第一个**真正需要它的工程
（PresentationCore/PresentationFramework 都是纯 .cs 工程），后续 6 个主题工程同理。

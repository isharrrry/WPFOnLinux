# PresentationFramework 编译预研（M5 交付）

> 状态：**骨架已生成 + 三处补丁 + 2 个 shim 落地；编译预研完成，距 0 错只差 1 轮**。
> 本轮中途 **PresentationCore.dll / DirectWriteForwarder.dll 由并行 agent 落地**（14:32–14:34），
> 于是本工程自动重接后**实测到最终基线：64 错 / 0 警（去重 63）**，且**全部 63 条来自三个未移植的上游工程**——
> **PresentationFramework 自身代码 0 条真实编译错误**。
> 上游全程只读（`upstream/wpf` 零写入）；本轮新增/修改文件见文末「交付物清单」。
> 实测环境：dotnet SDK 10.0.111 / net10.0 / Linux x64；所有数字均可按 §附录A 的命令复现。

## 0. 一句话结论

port-lib 一次跑通：**1350 个源文件、67 条大小写找回、0 缺失、0 剔除**，最终 1354 个 `@(Compile)`
（1328 项目内 + 22 Common/Shared + SR.g.cs + 3 个 shim）。三处补丁 + 2 个新增 shim 之后：

| 阶段 | 实测基线 | 说明 |
|---|---|---|
| E0（port-lib 原样） | 6239 错 / 9 警（去重 6107 / 9） | 未签名 + 缺 PC + 缺 WPF0001 NoWarn |
| E3（三补丁 + 2 shim，**PC 仍缺失**） | 5074 错 / 5 警（去重 4983 / 5） | 其中 **4920 条可逐条归属到「等 PresentationCore」** |
| **E5（PC 落地后重跑 port-lib）** | **64 错 / 0 警（去重 63 / 0）** | **全部 63 条 = 三个未移植工程**（ReachFramework / System.Printing-ref / PresentationUI-cycle） |

**预测 vs 实测**：E3 阶段按声明索引逐条归属，得出「等 PC 4920 条、剩余真实 63 条、且这 63 条应全部是
`PrintTicket`/`PrintQueue`/`XpsDocumentWriter`/`System.Windows.Xps`/`FindToolBar`」；PC 落地后实测
**恰好 63 条残留、构成完全一致、0 条新增**（且我预警的「PC 的 OLE 剔除外溢」实测未发生，原因见 §5.2）。

**签名结论：需要 PublicSign**（`build/keys/WcpPublicKey.snk`，只含公钥）。依据：WindowsBase /
PresentationCore 的 `OtherAssemblyAttrs.cs` 用 `BuildInfo.PresentationFramework =
"PresentationFramework, PublicKey=<WCP 公钥>"` 授予友元；不签名实测 CS0281 ×720（唯一）。

**0 错预测：再 1 轮**——路线 A（补齐三个未移植工程的托管面）或路线 C（造两个 API stub 程序集，
与 PC 轮 OLE 裁决同口径，**推荐优先评估**），见 §5；**0 警已达成**。

---

## 1. `port-lib` 生成结果摘要（交付物 ①）

### 1.1 生成命令与数字

```bash
python3 build/port-lib.py PresentationFramework
# [PresentationFramework] 源文件 1350（找回 67）/ 缺失 0 | 丢弃 PR 10(vcx 1) 私有 2 Target 0 Import 2
#          ⚠ 未解析的本地引用：['PresentationUI-PresentationFramework-impl-cycle', 'ReachFramework']
```

| 项 | 数值 | 说明 / 实测依据 |
|---|---|---|
| 上游目录内 `.cs`（磁盘） | **1336** | `find` 实测 |
| 上游 csproj `<Compile Include>` 条目 | **1329** | 1328 条显式 + **1 条通配符** `MS\Internal\WindowsRuntime\Generated\**\*.cs`（展开 22 个文件） |
| 上游**未编入**的 `.cs` | **8** | 7 个死文件 + `ref/PresentationFramework.cs`；见 §4.3 |
| 解析成功写入 csproj 的源文件 | **1350** | 1261 条路径精确命中 + 67 条大小写找回 + 22 条通配符展开 |
| 按**大小写不敏感精确路径**找回 | **67** | 全部是 `MS\Internal\Documents\…` vs 磁盘 `MS/Internal/documents/…` 的目录大小写错配；抽查 12 条全部正确，0 误配 |
| **仍缺失** | **0** | 无 |
| 最终 `@(Compile)`（MSBuild 实算） | **1354** | = 1328 项目内 + 22 Common/Shared + `SR.g.cs` + 3 shim（2 个 PF 专用 + `LinuxAssemblyIdentity.cs`）；`dotnet msbuild -getItem:Compile` 实测 |
| 剔除（excludes） | **0** | 实测无需剔除任何文件，故**未创建** `build/excludes/PresentationFramework.txt`（理由见 §4.1） |
| 丢弃 `ProjectReference` | **10**（含 vcxproj 1） | 详表见 §2.1 |
| 本地引用重接 | **5** | PresentationCore ✅（14:34 落地后自动重接）+ WindowsBase / System.Xaml / UIAutomationTypes / UIAutomationProvider |
| 未解析的本地引用 | **2** | ReachFramework、PresentationUI-PresentationFramework-impl-cycle |
| 丢弃私有 WinForms 引用 | **2** | `Accessibility`、`System.Private.Windows.Core` |
| 丢弃代码生成 Target | **0** | 上游本工程无 AvTrace/T4 Target（`AvTraceMessages.txt/.xml` 是数据文件，产物 `MS/Internal/AvTraceMessages.cs` 已 checked-in 且在编） |
| 丢弃 Arcade/CodeGen Import | **2** | `GenAvMessages.targets`、`DesignTimeTextTemplating.targets` |
| `PackageReference` | **4** | 见 §2.2，全部还原通过 |
| `DefineConstants` | `FRAMEWORK_NATIVEMETHODS;COMMONDPS;PRESENTATIONFRAMEWORK_ONLY;PRESENTATIONFRAMEWORK;RIBBON_IN_FRAMEWORK;WINDOWS_BASE_OR_PC` | `SR.g.cs` 命名空间 = `System.Windows` ✅（`Common/src/System/SR.cs` 的 `PRESENTATIONFRAMEWORK` 分支命中；resx 1300 条字符串） |
| `EmbeddedResource` | **3** | `Strings.resx` + `split.cur` + `splitopen.cur`（后两者由补丁 C 补齐，见 §4.2） |

### 1.2 一处「和 PresentationCore 不同」的好消息

上游 PresentationFramework 的 csproj 用的是 **`<EnableDefaultItems>false</EnableDefaultItems>`**（csproj:16），
且 port-lib 现在**两种写法都识别**（`EnableDefaultCompileItems=false` 与 `EnableDefaultItems=false`）——
所以本工程**没有** PresentationCore 那种「默认 glob 误纳上游刻意不编的文件」问题（PC 当时误纳 9 个、引发 80 条错误）。
本工程编入的 22 个 `MS/Internal/WindowsRuntime/Generated/**` 文件来自上游 csproj:401 的**显式通配符**，是上游本就要编的。

### 1.3 port-lib 口径缺口（本轮实测新发现 5 条，未改 port-lib，用补丁/文档兜住）

| # | 缺口 | 实测代价 | 兜法 |
|---|---|---|---|
| 1 | **不继承上游「最近一层 `Directory.Build.Props`」的 NoWarn**。上游 PF 向上最近一层是 `src/Microsoft.DotNet.Wpf/Directory.Build.Props:4` → `<NoWarn>$(NoWarn);CA1420;WPF0001</NoWarn>`；port-lib 只搬 csproj 自己的 NoWarn | **WPF0001 ×11（error 级！）**：`ThemeMode`/`ThemeModeConverter` 的 `[Experimental]` 诊断 | 补丁 B |
| 2 | **`-ref` 后缀的 ProjectReference 一律跳过**。规则本意是跳过「自引用 ref 程序集」（如 `PresentationFramework-ref.csproj`），但 `System.Printing\ref\System.Printing-ref.csproj` 是**别的程序集的 API 工程**——System.Printing 的实现是 C++（`System.Printing.vcxproj`），托管面**只存在于这个 ref 工程里** | 丢掉整个 `System.Printing` 命名空间 → **17 条**错误（E5 实测仍在） | 记入文档；M5 第 2 轮补一个 `build/System.Printing-ref.Linux` 工程 |
| 3 | **`$(WpfCycleBreakersDir)` 未知变量**：port-lib 的 `VARS` 里没有它，上游快照里也没有 `CycleBreakers/` 目录（`find` 为空）→ 三个 `*-impl-cycle`/`*-api-cycle` 引用**永远解析不出**，且只进内部变量不进 PORT-CHANGES | PF 侧 **7 条** `FindToolBar` 错误；ReachFramework / System.Printing-ref 同样依赖它 | 记入文档；M5 第 2 轮需自建等价子工程 |
| 4 | 未解析 ProjectReference **不写进 PORT-CHANGES.md**（PC 轮已提过同一问题） | 本轮靠脚本 stdout 才发现 | 沿用 stdout；建议 port-lib 落盘 |
| 5 | **多行 `<EmbeddedResource>` 只搬到第一个**：正则 `<(?:EmbeddedResource\|Resource)\s+Include="([^"]+)"(.*?)/>` 对带子元素的元素错配 | `splitopen.cur` 整条丢失 + 两个 `.cur` 的 `Type/ManifestResourceName` 元数据全丢（运行期资源名错，编译不报错） | 补丁 C（Remove + Include 复原） |

**port-lib 本轮表现正常的部分（实测确认）**：① `EnableDefaultItems=false` 已识别（§1.2）；
② 大小写找回工作正常且**只在精确路径唯一命中时采用**（67/67 命中，0 误配）；
③ 上游 NoWarn 搬运生效（`1058;SYSLIB5005` 已进生成物）；④ 自动注入 `LinuxAssemblyIdentity.cs`；
⑤ **本地引用自动重接**（PC.dll 落地后重跑即接入，无需手改 csproj）；⑥ excludes 机制可用（本工程未用）。

---

## 2. 依赖梳理（交付物 ②）

### 2.1 `ProjectReference` 全清单（10 条）与解析状态

| # | 上游 ProjectReference | port-lib 处置 | 本轮实测状态 |
|---|---|---|---|
| 1 | `$(WpfCycleBreakersDir)PresentationUI\PresentationUI-PresentationFramework-impl-cycle.csproj` | 丢弃（未解析） | ❌ **上游快照里不存在该工程**（`find upstream/wpf -iname "*impl-cycle*"` 为空，`CycleBreakers` 目录亦不存在）→ **7 条**错误 |
| 2 | `$(WpfSourceDir)ReachFramework\ReachFramework.csproj` | 丢弃（未解析） | ❌ 工程未移植（285 条 Compile）→ **47 条**错误（PrintTicket 31 + System.Windows.Xps 8 + System.Printing 命名空间 8） |
| 3 | `$(WpfSourceDir)System.Printing\ref\System.Printing-ref.csproj` | 丢弃（`-ref` 规则） | ❌ **口径缺口 #2**：这是 System.Printing 唯一托管面 → **17 条**错误 |
| 4 | `$(WpfSourceDir)PresentationCore\PresentationCore.csproj` | ✅ 重接 | `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`（3.6 MB，14:34） |
| 5 | `$(WpfSourceDir)DirectWriteForwarder\DirectWriteForwarder.vcxproj` | 丢弃 | 🚫 C++/CLI；PF **不直接**引用任何 DWrite 类型（0 条错误），托管面 `DirectWriteForwarder.dll` 已随 PC 落地 |
| 6 | `$(WpfSourceDir)System.Xaml\System.Xaml.csproj` | ✅ 重接 | `build/System.Xaml.Linux/bin/Debug/System.Xaml.dll` |
| 7 | `$(WpfSourceDir)WindowsBase\WindowsBase.csproj` | ✅ 重接 | AssemblyVersion **4.0.0.1**（反射实测） |
| 8 | `$(WpfSourceDir)UIAutomation\UIAutomationTypes\UIAutomationTypes.csproj` | ✅ 重接 | 同上目录 |
| 9 | `$(WpfSourceDir)UIAutomation\UIAutomationProvider\UIAutomationProvider.csproj` | ✅ 重接 | 同上目录 |
| 10 | `$(WpfSourceDir)PresentationFramework\ref\PresentationFramework-ref.csproj`（`ReferenceOutputAssembly=false`） | 跳过（自引用 ref，规则正确） | ✅ 无影响 |

**`Manipulations`（`System.Windows.Input.Manipulations.dll`）不在 PF 的 ProjectReference 里** —— 它经
PresentationCore 传递（PC 的 csproj 才引用它）。本工程**不直接**需要。

### 2.2 `PackageReference`（4 条，全部还原通过）

| 上游包 | 版本变量 | 生成结果 | 实测 |
|---|---|---|---|
| `System.Formats.Nrbf` | `$(SystemFormatsNrbfVersion)` | 9.0.0（`PKG_VERSIONS` 回退） | ✅ 还原通过；`SYSLIB5005` 已随上游 NoWarn 搬入 |
| `System.Configuration.ConfigurationManager` | `$(SystemConfigurationConfigurationManagerPackageVersion)` | 9.0.0 | ✅ |
| `System.Windows.Extensions` | `$(SystemWindowsExtensionsPackageVersion)` | 9.0.0 | ✅ |
| `$(SystemIOPackagingPackage)` → `System.IO.Packaging` | `$(SystemIOPackagingVersion)` | 9.0.0 | ✅（`PKG_NAMES` 映射生效） |

### 2.3 私有 WinForms 引用 / CsWin32 / 代码生成 / 默认项开关

| 项 | 上游 | port-lib 处置 | 本轮实测结论 |
|---|---|---|---|
| `MicrosoftPrivateWinFormsReference Include="Accessibility"` | 1 条 | 丢弃 | ✅ **不需要补**：唯一消费者 `System/Windows/Controls/Primitives/Popup.cs:19 using Accessibility;` 由**已就绪的 `UIAutomationTypes.dll` 传递提供**（其 shim 清单含 `Accessibility.Shim.cs`）→ 0 错误 |
| `MicrosoftPrivateWinFormsReference Include="System.Private.Windows.Core"` | 1 条 | 丢弃 | ❌ 离线不可得：**本轮独立复验 `dotnet restore` → `NU1101 找不到包 System.Private.Windows.Core`（源 huaweicloud）**；唯一消费者 `MS/Internal/DataStreams.cs` → **用源码 shim 兜住**（§4.2） |
| CsWin32（`System.Windows.Primitives`） | 上游 PF **没有**该 ProjectReference | — | ✅ **PF 全工程 0 处 `Windows.Win32.*` 引用**（grep 实测）→ 不需要任何 CsWin32 类型，也不需要 `WindowsWin32.Shim.cs` |
| `EnableDefaultItems` | `false`（csproj:16） | 识别为「关闭默认 glob」 | ✅ 无 glob 误纳（§1.2） |
| `GenerateDependencyFile=false` / `Platforms` / `ResolveAssemblyWarnOrErrorOnTargetArchitectureMismatch` | 上游 3 个属性 | 未搬运 | 无编译影响 |
| 代码生成 Target | 本工程 0 个（只有 2 个 Import 被丢） | — | ✅ `AvTraceMessages.cs` 等产物均已 checked-in 且在编 |
| `EmbeddedResource` 元数据 | `split.cur` / `splitopen.cur` 带 `Type=Non-Resx` + `ManifestResourceName` | 只搬到一个、元数据全丢 | ⚠️ **补丁 C** 按上游补回（§4.2） |

### 2.4 `InternalsVisibleTo` / 签名需求 —— **结论：必须 PublicSign**

**入向（我们需要别人给权限）**：

| 授予方（均已就绪） | IVT 声明位置 | 授予的对象与公钥 |
|---|---|---|
| `WindowsBase.dll` ✅ | `WindowsBase/OtherAssemblyAttrs.cs:17` | `InternalsVisibleTo(BuildInfo.PresentationFramework)` |
| `PresentationCore.dll` ✅ | `PresentationCore/OtherAssemblyAttrs.cs:11` | 同上 |

`BuildInfo` 定义在 **`Shared/RefAssemblyAttrs.cs`**（本工程在编文件）：
```csharp
internal const string WCP_PUBLIC_KEY_STRING = "002400000480000094000000060200000024000052534131…055da9";
internal const string PresentationFramework = $"PresentationFramework, PublicKey={WCP_PUBLIC_KEY_STRING}";
```

**实测依据（三条）**：
1. **不签名 → CS0281 ×720（唯一）/ ×1448（行）**，报错原文：
   *“友元访问权限由"WindowsBase, Version=4.0.0.1, Culture=neutral, PublicKeyToken=null"授予，
   但是输出程序集('')的公钥与授予程序集中 InternalsVisibleTo 特性指定的公钥不匹配。”*
   连带 CS0122 ×268（internal 成员不可访问）、CS0538 ×200（`UnsafeNativeMethods.IOleInPlaceSite` 等显式接口声明）、CS0115 ×339。
2. `build/keys/WcpPublicKey.snk` 与 `WCP_PUBLIC_KEY_STRING` **逐字节相同**（python 比对：160 字节，`IDENTICAL`）。
3. 加 PublicSign 后 → **CS0281 归零、CS0122 归零**，CS0538 从 200 降到 128（剩余全是 PC 缺失级联，PC 落地后归零）。

**出向（我们授予别人）**：只有一条 `LibraryAssemblyInfo.cs` → `PresentationFramework.Fluent.Tests`（DEVDIV 测试公钥），
**不影响**我们的签名选择。

**AssemblyVersion/身份**：`LibraryAssemblyInfo.cs` 无版本特性，port-lib 自动注入的 `LinuxAssemblyIdentity.cs`
（AssemblyVersion **4.0.0.1**）不冲突（0 条 CS0579）。实测**不需要** PresentationCore 那种
「补丁 A：摘掉框架 WindowsBase 门面引用」—— 本工程编译用的确实是我们的 `WindowsBase, Version=4.0.0.1`
（CS0281 原文即证），`build/Directory.Upstream.props` 的门面摘除 Target 全程未触发（E0 日志 0 条 `WpfLinux:` 提示）。

---

## 3. 实测基线（交付物 ②③合流）

### 3.1 E0 → E5 演进（全部实测，命令见附录 A）

| 阶段 | 施加的改动 | MSBuild 汇总 | 去重（文件,行,码,消息） |
|---|---|---|---|
| **E0** | port-lib 原样生成（PC 缺失） | **6239 错 / 9 警** | 6107 错 / 9 警 |
| **E1** | + 补丁 A（PublicSign + WCP 公钥） | 5088 错 / 9 警 | 4995 错 / 9 警 |
| **E2** | + 补丁 B（NoWarn `CA1420;WPF0001`）+ Nrbf shim | 5074 错 / 9 警 | 4983 错 / 9 警 |
| **E3** | + 补丁 C（资源元数据）+ `CLSCompliant(false)` shim | 5074 错 / 5 警 | 4983 错 / 5 警 |
| **E4** | **PresentationCore.dll 落地 → port-lib 自动重接** | **64 错 / 0 警** | 63 错 / 0 警 |
| **E5** | + 补丁 C 补回 `splitopen.cur`（资源完整性） | **64 错 / 0 警** | **63 错 / 0 警** |

> 口径说明：MSBuild 汇总数与「文件,行,码,消息」去重数的差（如 64 vs 63、5074 vs 4983）实测是
> **同一行、同一消息、不同列**的重复计数（E3 时 86 组、多 91 条；E5 时 1 条）。本文「去重」口径为后者。

**各步净收益（去重错误）**：
- 补丁 A：**−1112**（720 CS0281 + 340 internal 访问失败 + 52 级联）；
- 补丁 B + Nrbf shim：**−12**（WPF0001 ×11 + `System.Private` ×1）；
- 补丁 C + `CLSCompliant` shim：**−0 错 / −4 警**（CS3021 ×4）；
- **PC 落地：−4920**（= E3 分类里逐条归属到 PC 的 4613 直接 + 304 级联 + 3 手工裁定），
  同时 **−5 警**（CS0109 ×3 / CS0660 / CS0661，实测全部是 PC 级联）。

### 3.2 PC 缺失期（E3）的错误分类：真阻塞 vs 等 PresentationCore

E3 去重错误 4983 条，按「缺失名归属哪个上游工程」逐条归类（口径见附录 B）：

| 桶 | 条数 | 代表缺失名（条数） | 性质 |
|---|---|---|---|
| `wait_pc`（直接缺 PC 名） | **4613** | `UIElement` 334、`RoutedUICommand` 202、`RoutedEventArgs` 174、`LocalizabilityAttribute` 156、`Visual` 155、`IAddChild` 144、`RoutedEvent` 132、`LocalizationCategory` 131、`AutomationPeer` 131、`ExecutedRoutedEventArgs` 121、`Brush` 102… | **等 PC** |
| `pc_cascade`（成员级错误、基类链断在 PC 类型上） | **304** | `OnCreateAutomationPeer()`、`GetClassNameCore()`、`GetAutomationControlTypeCore()`（`*AutomationPeer` 全体，基类 `AutomationPeer` 在 PC）、`ThicknessAnimationUsingKeyFrames.*Core()` | **等 PC**（级联） |
| 手工裁定为 PC 级联 | **3** | `AccentColorHelper.cs:5` / `SystemColors.cs:7` 的 `MS.Internal.WindowsRuntime.Windows.UI` ×2（`UISettings`/`UISettingsRCW` 实测声明在 PC 的 `MS/internal/WindowsRuntime/Windows/UI/ViewManagement/UISettings.cs`）、`InkPresenter.cs:589 CS0246 Ink` | **等 PC** |
| `wait_unported:*` | **55** | `PrintTicket` 31、`System.Printing` 8、`PrintQueue` 9、`FindToolBar` 7 | **等未移植工程** |
| `ready_but_unresolved` | **8** | `System.Windows.Xps` ×8（`XpsDocumentWriter` 在 ReachFramework） | **等未移植工程** |
| **PC 无关的真实阻塞** | **0** | — | — |

**E3 警告 5 条（去重）**：`CS0109` ×3（`ContentTextAutomationPeer.ProviderFromPeer`、`TextAutomationPeer.ProviderFromPeer`、
`ThicknessAnimationUsingKeyFrames.CloneCurrentValue`，基成员分别在 PC 的 `AutomationPeer`/`Freezable`）、
`CS0660`/`CS0661` ×各 1（`TypographyProperties`，实测同文件同时报 `CS0246 TextRunTypographyProperties`(PC) →
基类是错误类型、`override Equals/GetHashCode` 未生效）。**5 条实测随 PC 落地全部归零（E4/E5 = 0 警）。**

### 3.3 E5 最终残留：63 条，逐项（这就是 PF 除已就绪件外要补的全部）

| 缺失名 | 条数 | 错误码 | 提供方 | 报错文件（条数） |
|---|---|---|---|---|
| `PrintTicket` | **31** | CS0246 | ReachFramework | `SerializerWriter.cs`(17)、`PrintDialog.cs`(6)、`SerializerWriterCollator.cs`(3)、`Win32PrintDialog.cs`(2)、`PrintDlgExMarshaler.cs`(2)、`SerializerWriterEventHandlers.cs`(1) |
| `System.Windows.Xps` 命名空间 | **8** | CS0234 | ReachFramework | `SerializerWriterEventHandlers.cs`(3)、`PrintDialog.cs`(2)、`SerializerProvider.cs`(1)、`DocumentViewerHelper.cs`(1)、`Primitives/DocumentViewerBase.cs`(1) |
| `System.Printing` 命名空间 | **8** | CS0234 | System.Printing（含 ReachFramework 共有） | `PrintDlgExMarshaler.cs`(2)、`Win32PrintDialog.cs`(2)、`SerializerWriter*.cs`(3)、`PrintDialog.cs`(1) |
| `PrintQueue` | **8** | CS0246 | System.Printing | `PrintDialog.cs`(5)、`Win32PrintDialog.cs`(2)、`PrintDlgExMarshaler.cs`(1) |
| `XpsDocumentWriter` | **1** | CS0246 | System.Printing | `PrintDialog.cs`(1) |
| `FindToolBar` | **7** | CS0246 | PresentationUI（`MS.Internal.Documents.FindToolBar`，**带 BAML**） | `DocumentViewerHelper.cs`(2)、`DocumentViewer.cs`、`FlowDocumentReader.cs`、`FlowDocumentScrollViewer.cs`、`SinglePageViewer.cs`、`Primitives/DocumentViewerBase.cs`（各 1） |
| **合计** | **63**（去重）/ 64（含列） | CS0246 ×55 / CS0234 ×8 | 3 个未移植工程 | **13 个文件**（见下） |

**报错文件共 13 个**（按条数降序）：`Documents/Serialization/SerializerWriter.cs` 17、
`Controls/PrintDialog.cs` 15、`MS/Internal/Printing/Win32PrintDialog.cs` 6、
`Documents/Serialization/SerializerWriterEventHandlers.cs` 6、`MS/Internal/Printing/PrintDlgExMarshaler.cs` 5、
`Documents/Serialization/SerializerWriterCollator.cs` 4、`MS/Internal/documents/DocumentViewerHelper.cs` 3、
`Controls/Primitives/DocumentViewerBase.cs` 2、`Documents/Serialization/SerializerProvider.cs` 1、
`Controls/DocumentViewer.cs` 1、`Controls/FlowDocumentReader.cs` 1、`Controls/FlowDocumentScrollViewer.cs` 1、
`Controls/SinglePageViewer.cs` 1。

> 口径提示：**源码层**提到这些符号的文件有 19 个（14 打印 + 7 FindToolBar − 2 重叠，grep 实测），
> 但真正**报错**的是 13 个（差集是 `FixedDocument.cs`/`FixedPage.cs`/`FixedSchema.cs` 等——它们的引用落在
> 未编译条件分支或模板字符串里）。路线 B 的剔除清单应以**报错的 13 个**为准。

**PF 需要 `FindToolBar` 的成员面很小且已从调用点反推**：`ctor` + `InitializeComponent()`（BAML）+
`SearchUp`（可写）+ `FindClicked` 事件 + 继承来的 `SetResourceReference`。

---

## 4. 逐文件处置（交付物 ③）

### 4.1 需要 excludes 的文件：**0 个**（决策 + 依据）

**依据（实测）**：E5 的 63 条去重错误逐条归属后，**没有任何一条**是「上游源码在本平台不可编译」造成的 ——
63 条真实残留全部是「上游别的工程还没移植」。**因此本轮不创建 `build/excludes/PresentationFramework.txt`**，
也不做任何静默剔除（纪律要求）。

**曾经评估过、最终判定「不剔除」的三个候选**：

| 候选 | 候选理由 | 实测结论 |
|---|---|---|
| `MS/Internal/DataStreams.cs`（411 行，唯一 `System.Private.Windows.BinaryFormat` 消费者） | 依赖离线不可得的私有包（NU1101 已复验） | **不剔除**：改用源码 shim（§4.2）；它有 5 个引用方（`Journal.cs`/`NavigationService.cs`/`JournalEntry.cs`/`Frame.cs`/`Journaling.cs`），剔除会把错误扩散到导航/Journal 公开 API |
| 打印栈 + FindToolBar 共 **13 个报错文件** | 依赖未移植工程 | **不剔除**：`PrintDialog`/`FixedDocument`/`DocumentViewer`/`FlowDocumentReader` 都是公开 API，剔除＝挖掉公开面（PC 轮 OLE 剔除的教训）。**备选方案**见 §5 路线 B |
| `MS/Internal/WindowsRuntime/Generated/**`（22 个 WinRT 投影文件） | 看着像生成物 | **不剔除**：上游 csproj:401 明确用通配符编入；实测 0 错误 |

### 4.2 需要 shim 的文件：**2 个新增**（`build/shims/`，由 `build/shims/PresentationFramework.shims.txt` 显式列出）

| shim 文件 | 解决什么 | 形态来源（可验证性） | 实测 |
|---|---|---|---|
| `build/shims/PresentationFramework.NrbfFrameworkObjects.Shim.cs` | `MS/Internal/DataStreams.cs:13 using System.Private.Windows.BinaryFormat;`（WinForms 私有包，NU1101） | **从调用点反推的 2 个成员**：`static bool BinaryFormatWriter.TryWriteFrameworkObject(Stream, object)`、`static bool SerializationRecord.TryGetFrameworkObject(out object)`；**恒返回 false 正是上游自带的降级路径**（`DataStreams.cs:134 if(!success) → BinaryFormatter.Serialize`；`:257 if(newValue==null) → Formatter.Deserialize`），不是伪造语义 | `System.Private` 错误 **1 → 0**；全工程该命名空间需求量为 0（仅此 1 文件） |
| `build/shims/PresentationFramework.AssemblyAttrs.Shim.cs` | 程序集级 `[assembly: CLSCompliant(false)]`：上游由 Arcade 生成 AssemblyInfo 时补上，我们切断 Arcade 后缺失 → 成员级 `[CLSCompliant(false)]` 报 CS3021 ×4 | **二选一实测**：`CLSCompliant(true)` → 新增 CS3001/CS3003 **数百条**（`Window.cs` 逐成员刷屏）；`CLSCompliant(false)` → **CS3021 归零、新增 0** ⇒ 上游口径必为 false（上游 NoWarn 里没有 CS30xx） | 警告 9 → **5**（−4），错误 0 变化。（**注**：并行 agent 对 PresentationCore 独立得出同一结论，见 `build/shims/PresentationCore.AssemblyAttrs.cs`） |

**刻意不做的 shim**：
- `Accessibility.IAccessible`：已由 UIAutomationTypes 传递提供（§2.3），再加一份会造成 CS0433/CS0436 双份同名类型。
- `Windows.Win32.*`：本工程 0 引用（§2.3），不需要。
- `UISettings` / `UISettingsRCW`：**曾误判为缺口，经查证是 PC 提供的**，不写 shim。
- `FindToolBar`（PresentationUI）：它是**带 BAML 的控件**，源码 shim 只能给类型壳、给不了模板 → 运行期 `PART_FindToolBarHost` 找不到模板（能编译、功能假）。
  按 PC 轮 `SplashScreen` 先例，**不做凭记忆的假实现**，走 §5 路线 A。

**补丁 C 覆盖的第三项**：`EmbeddedResource` 元数据 + `splitopen.cur`（port-lib 缺口 #5）。见 §5 reapply-patches.py 的 PATCH_C。

### 4.3 上游未编入的 8 个 `.cs` 核查（防「静默漏编」）

| 文件 | 上游 csproj 依据 | 判定 |
|---|---|---|
| `System/Windows/Markup/TreeBuilder.cs`、`XamlReaderHelper.cs`、`StyleXamlParser.cs`、`TemplateXamlParser.cs`、`System/Windows/Documents/TextFlow.cs`、`System/Windows/Controls/CalendarVisualStates.cs` | csproj 里**完全没有**这些路径（grep 全 0 命中） | 上游死文件（.NET Framework 时代遗留），**我们同样不编**——已核对不是漏编 |
| `System/Windows/Design/AdornerHitTestResult.cs` | csproj:851 编的是 **`Documents/AdornerHitTestResult.cs`**（同名文件在树里有两份） | 编 `Documents/` 版、不编 `Design/` 版（与上游一致）；两份都编会 CS0101 |
| `ref/PresentationFramework.cs` | 引用程序集源码，`-ref` 工程专用 | 不编（正确） |

---

## 5. 剩余阻塞预测表（交付物 ⑤）

**当前实测基线：64 错 / 0 警（去重 63 / 0）；PC 无关真实阻塞 0 条。**

| 轮次 | 前置条件 | 动作 | 预期结果 | 不确定性 |
|---|---|---|---|---|
| **第 1 轮**（等 PC）— **已完成** ✅ | `PresentationCore.dll`（并行 agent，14:34 落地） | `python3 build/port-lib.py PresentationFramework` + `reapply-patches.py` | 实测 **−4920 错 / −5 警** → 64 错 / 0 警 | 预测的「等 PC 4920 条 + 残留 63 条」与实测**完全一致**；预警的 OLE 外溢未发生（§5.2） |
| **第 2 轮**（收尾，**必做**） | 第 1 轮 | 补齐三个未移植工程的托管面（**路线 A**，见下） | 63 → **0 错**，`PresentationFramework.dll` 落地，里程碑口径达成 | 三个工程的依赖链与 BAML 编译是本轮唯一「没做过的事」（见下） |
| **备选路线 B**（若要求尽快 0 错且可接受挖公开 API） | 第 1 轮 | 在 `build/excludes/PresentationFramework.txt` 剔除 **13 个报错文件**（`PrintDialog.cs`、`DocumentViewer*.cs`、`FlowDocumentReader/ScrollViewer.cs`、`SinglePageViewer.cs`、`Serialization/SerializerWriter*.cs`、`MS/Internal/Printing/*`，完整清单见 §3.3） | 63 → 0 错，代价：`PrintDialog`/`FixedDocument`/`DocumentViewer`/`FlowDocumentReader`/`SinglePageViewer`/`ToolBar` 的公开与模板面被挖掉 | **不推荐**（PC 轮 OLE 剔除已产生 12 条「挖掉公开 API」代价） |
| **备选路线 C**（与 PC 的 OLE 裁决口径一致，**推荐优先评估**） | 第 1 轮 | 造两个**独立 stub 程序集**（不是改 PF）：`build/System.Printing.Linux`（2 个 .cs 的 API 面 + 打印成员 `throw new PlatformNotSupportedException()`）与 `build/ReachFramework.Linux`（仅 `System.Printing.PrintTicket` / `System.Windows.Xps.*` 的 API 面 stub），供 PF 引用；真正实现留到 M7（Linux 打印栈是 CUPS 路线） | 63 → 0 错，公开 API **形态保留**（类型/成员在，调用才抛）；代价：打印功能运行期不可用（与 PC 的 `PresentationCore.OleApi.Stubs.cs` 同一权衡） | 需要主控裁定——PC 轮已就这一模式拍过板（M4 主控裁决），本路线是它的直接延续；**唯一技术前提**是 stub 程序集的程序集名/公钥要与上游一致（`System.Printing`/`ReachFramework` 走 WCP 公钥，同 PublicSign 口径） |

### 5.1 第 2 轮（路线 A）三件事的实测依据

| 子项 | 上游资源（均在树内，无需联网） | 要点 |
|---|---|---|
| `ReachFramework.Linux`（解决 47 条：PrintTicket 31 + Xps 8 + 与 SP 共有的 System.Printing 8） | 285 条 `<Compile Include>`，port-lib 直接支持 | 它自己还引用 ① `PresentationFramework-ReachFramework-impl-cycle.csproj`（**源码不在树内**，同缺口 #3）② `DirectWriteForwarder.vcxproj`（已就绪）③ `System.Printing-ref`（下一项）→ **需先定这两条的处置** |
| `System.Printing-ref.Linux`（解决 17 条：PrintQueue 8 + XpsDocumentWriter 1 + 共有 8） | **2 个 .cs**：`ref/System.Printing.cs` + `ref/System.Printing.internals.cs`（纯 API 面） | 它引用 `PC-ref`/`System.Xaml-ref`/`WindowsBase-ref`/`UIAutomation*-ref` + 2 个 cycle-breaker（**不在树内**）→ 若坚持编 ref 工程，需处理这 2 条 |
| `PresentationUI` impl-cycle 等价子工程 | `PresentationUI/MS/Internal/Documents/FindToolBar.xaml{,.cs}`（在树内）+ `build/WpfMarkupCompile.Linux.targets`（已就绪） | 上游 CycleBreakers 目录在本快照**不存在**，需自建：把 FindToolBar 编成小程序集（BAML 参与编译）。这是全轮唯一「本仓库还没做过」的技术动作 |

### 5.2 跨项目风险（本轮实测已解除 1 条、留下 3 条建议）

1. **【已解除】PC 的 OLE 剔除外溢**：我在 E3 阶段预警「PC 剔除的 `DataObject`/`Clipboard`/`DataFormats` 会波及 PF 22 个文件（约 380 处引用点）」。
   **实测未发生**：PC 落地产出了 `build/shims/PresentationCore.OleApi.Stubs.cs`（M4 主控裁决的最小诚实 stub），
   PF 侧 `DataObject`/`Clipboard`/`DataFormats` 相关错误 **0 条**（E5 实测）。
2. **【建议】`[assembly: CLSCompliant(false)]` 提升为共用**：这是 PC 的 37 条 CS3021 与 PF 的 4 条 CS3021 的**同一根因**。
   两个 agent 各自独立得出同一结论（PC: `build/shims/PresentationCore.AssemblyAttrs.cs`；PF: `PresentationFramework.AssemblyAttrs.Shim.cs`）。
   建议由主控移入 `build/shims/LinuxAssemblyIdentity.cs`（一处生效、避免每个工程复制一份）。
3. **【建议】port-lib 两条口径缺口影响的不止 PF**：`-ref` 跳过规则（缺口 #2）与 `WpfCycleBreakersDir` 未定义（缺口 #3）会被
   `ReachFramework`、`System.Printing-ref`、`System.Windows.Controls.Ribbon` 全部踩到；缺口 #5（多行 EmbeddedResource）
   对任何带 `Type=Non-Resx` 资源的工程都成立。
4. **【风险】未移植工程的 cycle-breaker 依赖是结构性障碍**：`*-impl-cycle` / `*-api-cycle` 三类工程在上游快照里都**不存在**，
   所以「把 ReachFramework 编出来」并不是单纯跑一次 port-lib——需要先给出 cycle-breaker 的自建口径。

---

---

## 6. M5 第二轮 · 0 错落地（真移植优先 + CycleBreaker 最小替身）

> 主控裁定：路线「真移植优先，stub 兜底 —— 不走整包 stub」。本节记录落地结果与口径。

### 6.1 结果一览（实测）

| 工程 | 性质 | 实测 |
|---|---|---|
| `build/ReachFramework.Linux`（285 .cs） | **真移植**（port-lib + 3 处补丁） | **0 错 / 0 警** |
| `build/System.Printing.Linux`（2 .cs） | **真移植**（上游唯一托管面；手写工程，理由见 6.3） | **0 错 / 0 警** |
| `build/CycleStub.ReachFramework.Linux` | CycleBreaker 最小替身（AssemblyName=ReachFramework） | **0 错 / 0 警** |
| `build/CycleStub.PresentationFramework.Linux` | CycleBreaker 最小替身（AssemblyName=PresentationFramework） | **0 错 / 0 警** |
| `build/CycleStub.PresentationUI.Linux` | CycleBreaker 最小替身（AssemblyName=PresentationUI，含 FindToolBar） | **0 错 / 0 警** |
| `build/PresentationFramework.Linux` | 真移植（1354 Compile） | ✅ **0 错 / 0 警**，产出 `PresentationFramework.dll` **7,099,904 B（6.77 MB）** |

**最终产物（实测尺寸/身份）**

| 产物 | 大小 | 身份（self / 关键 AssemblyRef） |
|---|---|---|
| `build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll` | **7,099,904 B** | v4.0.0.1 PKT=31bf3856ad364e35；ref System.Xaml PKT=**31bf…** ✓ / WindowsBase PKT=**null** ✓ |
| `build/ReachFramework.Linux/bin/Debug/ReachFramework.dll`（pass 2，对真 PF 编） | 741,376 B | v4.0.0.1 PKT=31bf… ✓ |
| `build/System.Printing.Linux/bin/Debug/System.Printing.dll` | 49,152 B | v4.0.0.1 PKT=31bf… ✓ |
| `build/CycleStub.PresentationUI.Linux/bin/Debug/PresentationUI.dll` | 7,680 B | v4.0.0.1 PKT=31bf… ✓（替身即当前运行期 PresentationUI） |
| `build/CycleStub.PresentationFramework.Linux` / `CycleStub.ReachFramework.Linux` | 13,824 / 5,120 B | 同上（只参与编译，`<Private>false</Private>`） |

**ReachFramework pass 2 已执行并通过（0 错 0 警）** ⇒ 编译器逐条确认「RF 对 PF 替身的全部使用在真 PF 上依然成立」，
替身保真度得到硬验证（§6.4）。PF 的 bin 里也随之带上了 pass 2 的真 `ReachFramework.dll`。

### 6.2 ReachFramework 真移植（0 错）做了什么

port-lib 一次跑通：**285 源文件 / 64 条大小写找回 / 0 缺失**；`reapply-patches.py` 三处补丁（幂等）：

| 补丁 | 内容 | 实测依据 |
|---|---|---|
| A | PublicSign + `WcpPublicKey.snk` | 不签名 CS0281 ×140 行（`ReachFramework` 是 WindowsBase / PresentationCore / System.Printing 的 IVT 受益方，三家都用 `BuildInfo.ReachFramework`=WCP 公钥授予）；同时压制 `CS8002`（本移植工程 WindowsBase 未签名，上游全签名故无此警告） |
| B | `[assembly: CLSCompliant(false)]`（`build/shims/ReachFramework.AssemblyAttrs.Shim.cs`） | 同 PF：程序集级特性由 Arcade 生成，切断继承后缺失 → CS3021；取值 false 经 PF 轮实测二选一确定 |
| C | 接回 3 个被 port-lib 丢弃的引用 | ① CycleBreakers 替身（PF 侧，自举两步）② `System.Printing`（`-ref` 规则跳过）③ `DirectWriteForwarder`（port-lib 丢弃 vcxproj；实测 CS0012「类型 Font 在未引用的程序集 DirectWriteForwarder 中定义」） |

> 顺带验证了主控修好的 port-lib：**NoWarn 链**（生成物自动含 `CA1420;WPF0001`）与 **EmbeddedResource 元数据保真**
> 在 RF 上同样生效；因此 PF 侧原先的两处手工补丁已删除（成冗余）。

### 6.3 System.Printing：为什么是**手写工程**而不是 port-lib 生成

上游 `System.Printing` 的**实现是 C++**（`System.Printing.vcxproj` + `CPP/`），托管面只存在于
`System.Printing/ref/System.Printing-ref.csproj`（`System.Printing.cs` 785 行公开 API +
`System.Printing.internals.cs` 86 行内部面，全部 `throw null` API 形态）。
但 port-lib 有两条会绕过它的规则：`find_csproj()` **过滤掉路径含 `/ref/` 的候选**，
`ProjectReference` 解析**跳过 `*-ref`**（后者是 PF 侧要靠补丁 B 接回的原因）。
⇒ 按上游 ref csproj 逐项等价**手写** `build/System.Printing.Linux/System.Printing.Linux.csproj`
（AssemblyName=System.Printing、2 个 .cs + `Shared/RefAssemblyAttrs.cs`、
引用真 PC/System.Xaml/WindowsBase/UIAutomation* DLL + 2 个 CycleStub、PublicSign、身份 4.0.0.1）。
这是已留档的口径缺口 #2 的兜法，未改 port-lib。

### 6.4 CycleBreaker 替身：为什么「结构上不可移植」+ 保真度怎么保证

**结构性理由（实测）**：`PresentationFramework.csproj:1377`、`ReachFramework.csproj:351-352`、
`System.Printing-ref.csproj:31-32` 都引用 `$(WpfCycleBreakersDir)` 下的工程，而
`find upstream/wpf -iname "*impl-cycle*" -o -iname "*api-cycle*"` **为空**、`grep -rn WpfCycleBreakersDir upstream/wpf`
**只有引用没有定义** —— 三个 `*-cycle.csproj` 的**源码在上游快照里根本不存在**，无法「真移植」。

**替身的构造原则（三条）**：
1. **AssemblyName 就是真程序集名**（ReachFramework / PresentationFramework / PresentationUI）
   + AssemblyVersion 4.0.0.1 + WCP 公开签名 ⇒ 与真程序集**身份一致**：
   替身只参与**编译**，运行期由真程序集顶替（System.Printing / ReachFramework 的引用自动绑定到真件）。
2. **参考方一律 `<Private>false</Private>`**（PresentationUI 除外：它当前**就是**运行期的 PresentationUI），
   绝不把替身复制进输出目录 —— 避免出现两个同名程序集。
3. **成员一律来自上游真源码**（逐条注明文件:行），没有凭记忆的形状；能用真源码的直接用真源码：
   PF 替身里 `Documents/Serialization` 的 4 个 API 文件（`SerializerWriter`/`SerializerWriterCollator`/
   `SerializerWriterEventHandlers`/`ISerializerFactory`）**直接编译上游原文件**，
   以保证 RF 继承/实现的抽象成员签名与上游逐个一致；`PrintTicketScope`/`ValidationResult`/
   `PageRangeSelection`/`PrintTicketLevel` 等的取值也照抄真源码。
4. **继承链保真**（关键，防静默走错分支）：替身里 `FixedPage`/`DocumentReference` 派生自
   `FrameworkElement`、`FixedDocument`/`FixedDocumentSequence`/`Hyperlink` 派生自 `FrameworkContentElement`
   —— 因为 RF 里有大量 `element is FrameworkElement` / `is FrameworkContentElement` 分支，
   链错了**能编译但语义错**。为此替身自己也声明了最小 `FrameworkElement`/`FrameworkContentElement`
   （真类在 PF 内，替身无法引用真 PF —— 那会形成编译期循环）。

**保真度硬验证（自举两步）**：RF 先对替身编（pass 1），真 PF 产出后 `reapply-patches.py` 的
Exists() 条件自动改指真 PF，再编一次（pass 2）—— 编译器逐条复核 RF 对替身的所有使用在真 PF 上依然成立。
**替身与真件的任何成员/继承差异都会变成编译错误，不会留到运行期。**

**运行期降级（诚实清单，非伪造）**：
- `PresentationUI` 替身：`FindToolBar` 无 BAML/模板 ⇒ 文档查看器的「查找」工具条**不显示、查找不可用**
  （PF 原有的 `PART_FindToolBarHost` 空引用分支处理）；`DocumentApplicationDocumentViewer` 同理
  （模板里找不到 → PF 自己的 null 检查分支）。没有任何方法假装成功。
- `System.Printing`：API 形态完整但方法体是上游 ref 源的 `throw null` ⇒ 打印/XPS 输出在 Linux 上不可用（M7 若做需走 CUPS）。
- 替身里的 `PresentationUIStyleResources` 是空类（真源码注释亦写明「应保持为空」）。

### 6.5 6 条残余错误 = **过期产物**（不是源码问题；已上报主控重建）

`System.Xaml.dll` 于 **14:55** 变成公开签名（PKT=31bf3856ad364e35），而
`WindowsBase.dll`（**14:52**）记录的引用仍是 `System.Xaml v4.0.0.1 PKT=null` ⇒ PF 编译时
`MarkupObject.AssignRootContext(IValueSerializerContext)` 的形参类型两侧**不是同一个类型身份** →
6 条 CS0534/CS0115（`ElementMarkupObject`/`MarkupObjectWrapper`/`FrameworkElementFactoryMarkupObject`）。

**最小探针确证**（`/tmp/m5/sxprobe`，仅引用这两个 DLL + 一个 override 子类）复现同一条
`CS0534 不实现继承的抽象成员 MarkupObject.AssignRootContext(IValueSerializerContext)` ⇒ 与 PF 源码无关。
**修复**：对签名后的 System.Xaml 重编 WindowsBase（并检查 14:53 的 PresentationCore 是否有同样问题）。
另注：`build/WindowsBase.Linux/bin/Debug/System.Xaml.dll` 是 14:21 的**旧未签名副本**，与 14:55 的新件不一致，建议清理。

### 6.6 本轮对 shim 的两处修正（实测驱动）

| 修正 | 原因（实测） |
|---|---|
| 删除 `PresentationFramework.NrbfFrameworkObjects.Shim.cs` 里的 `TryGetFrameworkObject` 扩展 | `System.Formats.Nrbf 9.0.0` 包**自己提供**该扩展（`SerializationRecordExtensions.TryGetFrameworkObject`）→ 两份声明触发 **CS0121 二义性**（DataStreams.cs:254） |
| 新增 `IsCriticalException(this Exception)` 扩展，**委托**给上游 `Shared/MS/Internal/CriticalExceptions.cs:19`（编入 WindowsBase，PF 有 IVT） | 上游 DataStreams.cs 的这个扩展来自 WinForms 私有包（NU1101 不可得）；委托上游实现而不是复制「哪些异常算致命」的判断逻辑 |

### 6.6b 0 错路上的最后四处修正（全部实测驱动）

| # | 修正 | 实测依据 |
|---|---|---|
| 1 | PresentationUI 替身：`DocumentApplicationDocumentViewer` 的命名空间从 `MS.Internal.Documents.Application` 改到 **`MS.Internal.Documents`** | 真文件 `PresentationUI/MS/Internal/Documents/DocumentApplicationDocumentViewer.cs:24` 的 namespace 是 `MS.Internal.Documents`（只有 `DocumentApplicationState` 在 `.Application` 子命名空间）→ 编译器报 `DocumentGridContextMenu.cs:30/73 CS0246` 当场纠正 |
| 2 | PF 补丁 A 增补 `NoWarn CS8002` | 本工程（及 PC/RF/SP）公开签名，而 WindowsBase / UIAutomationTypes / UIAutomationProvider 在本移植工程中**未签名** → ×3；上游「全签名」故无此警告。主控已排期在集成波统一签名，届时可撤 |
| 3 | PF 补丁 A 增补 `NoWarn CS0184` | `DocumentGridContextMenu.cs:73` 的 `DocumentViewerOwner is DocumentApplicationDocumentViewer`：真类派生自 PF 的 `DocumentViewer`，而替身不能引用 PF（编译期循环）⇒ 基类取 `UIElement`，编译期判定永假。**运行期行为与编译期结论一致**（该 DocumentApplication 旧特性路径在 Linux 不启用）；真 PresentationUI 移植后基类归位即可撤销 |
| 4 | **`GenerateDependencyFile=false`**（RF/PF/SP 三处；port-lib 口径缺口 #6） | 上游三个工程都有这一条（`ReachFramework.csproj:9` / `PresentationFramework.csproj:12` / `System.Printing-ref.csproj:9`），port-lib 未搬运。RF pass 2（引用真 PF）时 deps.json 生成抛 `MSB4018 System.ArgumentException: An item with the same key has already been added. Key: ReachFramework`（同一程序集同时出现在项目输出与 reference copy-local 列表）→ 按上游关闭 deps 生成 |

### 6.6c 过期产物事故的收尾（主控已重建）
主控按依赖序重建了 WindowsBase / DirectWriteForwarder / UIAutomation* / Manipulations / PresentationCore 并核对身份链；
本轮据其要求把 `System.Printing → ReachFramework → 三个 CycleStub → PresentationFramework` 各自重建一次（全部 `-m:1`），
之后 PF 与 RF pass 2 均为 **0 错 0 警**。身份判据（每个产物 self/ref 的公钥令牌）已在上表逐条列出。

### 6.7 本轮新增/修改文件

见文末「交付物清单（M5 第二轮追加）」。

## 附录 A：复现命令

```bash
REPO=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"

# 0) 【M5 第二轮】完整自举链（依赖顺序；-m:1 以适配 3 核低配机）
#    a. CycleBreaker 替身（互相独立）
for p in CycleStub.ReachFramework.Linux CycleStub.PresentationFramework.Linux CycleStub.PresentationUI.Linux; do
  dotnet build build/$p/$p.csproj -m:1 -v:m -nologo
done
#    b. System.Printing（唯一托管面，API-only）
dotnet build build/System.Printing.Linux/System.Printing.Linux.csproj -m:1 -v:m -nologo
#    c. ReachFramework pass 1（对 PF 替身编）
python3 build/port-lib.py ReachFramework && python3 build/ReachFramework.Linux/reapply-patches.py
dotnet build build/ReachFramework.Linux/ReachFramework.Linux.csproj -m:1 -v:m -nologo
#    d. PresentationFramework（对真 RF + 真 SP + PresentationUI 替身编）
python3 build/port-lib.py PresentationFramework && python3 build/PresentationFramework.Linux/reapply-patches.py
dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -m:1 -v:m -nologo
#    e. ReachFramework pass 2（条件自动改指真 PF → 复核替身保真度）
python3 build/ReachFramework.Linux/reapply-patches.py
dotnet build build/ReachFramework.Linux/ReachFramework.Linux.csproj -m:1 -v:m -nologo

# 1) 生成骨架（整份覆盖 csproj）→ 重放补丁（幂等，可连续执行两次）
cd $REPO && python3 build/port-lib.py PresentationFramework
python3 build/PresentationFramework.Linux/reapply-patches.py
python3 build/PresentationFramework.Linux/reapply-patches.py    # 幂等验证：结果不变

# 2) 构建（当前基线：MSBuild 汇总 64 错 / 0 警；去重 63 / 0）
dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -v:m -nologo 2>&1 | tee /tmp/pf.log

# 3) 计数口径
grep -E ": error (CS|WPF)[0-9]+:" /tmp/pf.log | sed 's/ \[.*$//' | sort -u | wc -l   # 64（含列去重）
python3 - <<'EOF'
import re
PAT=re.compile(r'^(/\S+?)\((\d+),(\d+)\): (error|warning) (CS\d+|[A-Z]+\d+): (.*?) \[', re.M)
t=open('/tmp/pf.log',encoding='utf-8',errors='ignore').read()
rows=[m for m in PAT.findall(t) if m[3]=='error']
print("去重(文件,行,码,消息):", len({(r[0],r[1],r[4],r[5]) for r in rows}))
print("去重(文件,行,列,码,消息):", len({(r[0],r[1],r[2],r[4],r[5]) for r in rows}))
EOF

# 4) 最终编译文件数（权威口径 1354 = 1328 + 22 + SR.g.cs + 3 shim）
dotnet msbuild build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -getItem:Compile -nologo | grep -c '"Identity"'

# 5) PC 缺失期基线复现（E0–E3）：把 reapply-patches.py 的 PATCH_A/B/C 逐块停用重跑，
#    并临时把 csproj 里的 PresentationCore <Reference> 删掉即可复现 6239 → 5074 的四级台阶

# 6) CLSCompliant 二选一实测（§4.2）
printf '[assembly: System.CLSCompliant(true)]\n' > /tmp/ClsTrue.cs
cat > /tmp/cls.targets <<'X'
<Project><ItemGroup><Compile Include="$(ClsProbeFile)" /></ItemGroup></Project>
X
dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -v:m -nologo \
  -p:ClsProbeFile=/tmp/ClsTrue.cs -p:CustomAfterMicrosoftCommonTargets=/tmp/cls.targets 2>&1 | grep -c "warning CS30"

# 7) 私有包不可得复验（§2.3）
mkdir -p /tmp/pkgprobe && cd /tmp/pkgprobe && cat > p.csproj <<'X'
<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net10.0</TargetFramework>
<OutputType>Library</OutputType></PropertyGroup>
<ItemGroup><PackageReference Include="System.Private.Windows.Core" Version="9.0.0" /></ItemGroup></Project>
X
dotnet restore p.csproj     # → NU1101 找不到包（源 huaweicloud）

# 8) 上游只读性自检（本机无 git，用 mtime 判定）
find $REPO/upstream/wpf -newermt "2026-09-10 14:20" -type f | head   # 必须为空（实测为空：6417 个上游文件零改动）
```

## 附录 B：错误归属分类口径（本文所有「等 PC / 真阻塞」数字的算法）

**实测脚本**：`/tmp/m5/classify.py`（**不进仓库**，本轮一次性分析工具）。规则三步：

1. **建声明索引**：对每个上游工程取「本工程 `*.Linux.csproj` 的 `@(Compile)` 清单」（权威口径 = 该 DLL 到底编了哪些文件），
   用正则抽取它声明的 `namespace X` 与 `class/struct/interface/enum/record/delegate NAME`
   （实测规模：PC 1350 文件/2355 类型、WindowsBase 314/939、System.Xaml 181/337、UIAutomationTypes 64/236、
   UIAutomationProvider 32/38、Manipulations 26/43；未移植工程按整目录扫描：ReachFramework 288、PresentationUI 92、
   System.Printing 2、Ribbon 132）。
2. **逐条归属**：从每条诊断里取出缺失名（`CS0234` 取「命名空间 A + 成员 B」= A.B；`CS0246`/`CS0538`/`CS0122` 取引号内名字，
   并额外尝试 `名字+"Attribute"`、剥离泛型 `<>` 后缀），到索引里查**哪个工程声明它**：
   命中 PC 且不命中已就绪程序集 → `wait_pc`；命中已就绪程序集 → 近失配；只命中未移植工程 → `wait_unported:<工程>`。
3. **级联归并**：成员级错误码（`CS0115/CS1061/CS0534/CS0535/CS0539`）出现在「含直接 PC 缺失错误的文件」里 → 记为 `pc_cascade`。

**手工裁定 8 条**（脚本无法自动判、逐条读源码确认）：`MetadataFlags` ×2（经 `UIPropertyMetadata`(PC) 继承）、
`DpiUtil` ×5（PC 的 `MS.Internal.DpiUtil`）、`ReadOnlyFrameworkPropertyMetadata.GetReadOnlyValueCallback` ×1
（基类链断在 `UIPropertyMetadata`(PC)）、以及 5 个 `*AutomationPeer` / `Run.cs` 的 CS0115（基类链断在 PC 的
`AutomationPeer` / `ContentElement`）。

---

## 交付物清单（本轮新增 / 修改）

| 文件 | 动作 | 说明 |
|---|---|---|
| `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` | 新增（port-lib 生成 + 补丁 A/B/C） | 1354 个 `@(Compile)`；5 条本地引用（全部解析）；4 条包引用 |
| `build/PresentationFramework.Linux/reapply-patches.py` | 新增 | 补丁 A（PublicSign）/ B（NoWarn）/ C（资源元数据 + `splitopen.cur`），**幂等可重放**（连跑两次结果一致，已实测） |
| `build/PresentationFramework.Linux/PORT-CHANGES.md`、`SR.g.cs` | 新增（自动） | port-lib 产物；SR 命名空间 `System.Windows`（1300 条字符串） |
| `build/shims/PresentationFramework.shims.txt` | 新增 | 本工程 shim 清单（2 条） |
| `build/shims/PresentationFramework.NrbfFrameworkObjects.Shim.cs` | 新增 | WinForms 私有 NRBF 读写面的语义化降级 shim（恒 false → 上游自带回退路径） |
| `build/shims/PresentationFramework.AssemblyAttrs.Shim.cs` | 新增 | `[assembly: CLSCompliant(false)]`（取值经 true/false 实测二选一） |
| `docs/U2-PresentationFramework-prep.md` | 新增 | 本文档 |
| **未创建**：`build/excludes/PresentationFramework.txt` | — | 实测无需剔除任何文件（§4.1） |
| `/tmp/m5/`（classify.py、asmprobe、logs/E0–E5） | 新增（**不进仓库**） | 分类脚本、程序集身份探针、六份构建日志 |

**上游零改动**：`upstream/wpf` 全程只读。
**本轮未触碰**：`build/PresentationCore.Linux/`、`build/DirectWriteForwarder.Linux/`、`build/port-lib.py`、
`build/Directory.Upstream.props`、`build/shims/WindowsWin32.Shim.cs`、`build/shims/LinuxAssemblyIdentity.cs`、
`build/keys/`、`src/`、`handoff.md`、`verify-all.sh`。
（另：`build/shims/PresentationCore.OleApi.Stubs.cs`、`PresentationCore.AssemblyAttrs.cs`、`DirectWriteForwarder.dll`
均为并行 agent 在本轮期间产出，**非本 agent 所为**，仅作引用。）

---

## 交付物清单（M5 第二轮追加）

| 文件 | 动作 | 说明 |
|---|---|---|
| `build/ReachFramework.Linux/{ReachFramework.Linux.csproj,PORT-CHANGES.md,SR.g.cs,reapply-patches.py}` | 新增 | RF 真移植（285 .cs，0 错 0 警）；补丁 A 签名 / B CLSCompliant / C 接回 3 个引用（含自举两步） |
| `build/shims/ReachFramework.AssemblyAttrs.Shim.cs` | 新增 | `[assembly: CLSCompliant(false)]`（同 PF 口径） |
| `build/System.Printing.Linux/System.Printing.Linux.csproj` | 新增（**手写**） | 上游唯一托管面 2 个 .cs；理由：port-lib 的 `/ref/` 过滤（口径缺口 #2） |
| `build/CycleStub.ReachFramework.Linux/{csproj,ApiSubset.cs}` | 新增 | 替身（PrintTicket/PrintCapabilities/PrintTicketScope/ValidationResult/XpsDocument/RCW 接口 + IVT→System.Printing） |
| `build/CycleStub.PresentationFramework.Linux/{csproj,ApiSubset.cs}` | 新增 | 替身（Fixed*/DocumentReference/PageContent/Hyperlink/PageRange/序列化 API 真源码/最小 FrameworkElement 等） |
| `build/CycleStub.PresentationUI.Linux/{csproj,FindToolBar.ApiSubset.cs}` | 新增 | 替身（FindToolBar/PresentationUIStyleResources/DocumentApplication*，含 IVT→PresentationFramework） |
| `build/PresentationFramework.Linux/reapply-patches.py` | 修改 | 删除已成冗余的 NoWarn/资源补丁（主控修好 port-lib）；新增补丁 B 接回 PresentationUI 替身 + System.Printing |
| `build/shims/PresentationFramework.NrbfFrameworkObjects.Shim.cs` | 修改 | 删 `TryGetFrameworkObject`（与 NuGet 包二义性）；`IsCriticalException` 委托上游实现 |
| `docs/U2-PresentationFramework-prep.md` | 修改 | 追加 §6（第二轮：0 错落地，含最终产物尺寸/身份表、自举复现链、4 处收尾修正） |
| `/tmp/asmref`（主控提供）/ `/tmp/m5/asmprobe`（**不进仓库**） | 新增 | 程序集身份链探针（self + AssemblyRef 的 PKT 复核） |
| `/tmp/m5/sxprobe`（**不进仓库**） | 新增 | 过期产物最小探针（确证 6 条残余错误与 PB 源码无关） |

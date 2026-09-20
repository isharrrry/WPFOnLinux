# PC/PF 资源与 BAML 管线审计（M4 追加任务 · U2）

> 审计对象：`PresentationCore`（已构建）、`PresentationFramework`（M5 收尾中，仅静态比对）、`DirectWriteForwarder`（本工程新建）。
> 上游只读；本文件是唯一产出物之一，另一份是 `build/PresentationCore.Linux/resource-manifest.txt`（实际资源清单快照）。
> 所有数字与结论均为**实测**（区分「实测」与「推断/待复验」，逐条标注）。

## 0. 一句话结论

**PC 的资源管线有一处会直接毁掉运行期文本渲染的缺口，已修**：上游用 **WPF `<Resource>`** 承载的 4 个复合字体，被 port-lib 搬成了普通 `<EmbeddedResource>`，而 SDK 对未知扩展名**静默丢弃**——实测构建产物里**一个字体都没有**；PC 运行期是从 **`PresentationCore.g.resources`** 流里按 `fonts/<小写文件名>` 取字的（`FontSource.cs:394`），此前必然"找不到资源"。修复后实测 4/4 命中（端到端复刻运行期取法）。
同时修掉一处**静默降级**：SR 资源表基名（`PresentationCore.Resources.Strings`）与清单实名（`MS.Internal.Strings.resources`）不一致，靠 `SR.cs` 的 `catch(MissingManifestResourceException)` 回落到内联默认串才没崩。
**PF 侧同一处 SR 名不一致仍然存在**（属 M5 agent 的文件，本审计只报不改）；上游 PF **没有** XAML/BAML 资源（全树 171 个 .xaml 全在 `Themes/*` 独立工程里），因此"PF 的 BAML 资源漏搬"这一假设**不成立**。

---

## 1. 上游资源清单（逐项，含 oracle 位置）

### 1.1 PresentationCore（4 项，`PresentationCore.csproj:1429-1450` 附近）

| # | 上游项 | 种类 | 元数据 | 运行期取法（oracle） |
|---|---|---|---|---|
| PC-1 | `Fonts\*.CompositeFont`（**4 个文件**） | **`<Resource>`（WPF 资源）** | `GenerateSource=false`、`XlfSource=false` | `MS/internal/FontCache/FontSource.cs:394` → `new ResourceManager("<asm>.g", asm).GetStream("fonts/" + 文件名小写)`；文件名列表见 `FamilyCollection.cs:200`（GlobalUserInterface / GlobalMonospace / GlobalSansSerif / GlobalSerif） |
| PC-2 | `Resources\Strings.resx` | `EmbeddedResource` | 无 | `MS/internal/PresentationCore/SR.cs` → `ResourceManager("PresentationCore.Resources.Strings")`（本工程 `SR.g.cs:16` 实测值） |
| PC-3 | `System\Windows\Media\Resources\ColorProfiles\ColorProfiles.resx` | `EmbeddedResource` | `ManifestResourceName=ColorProfiles` | `System/Windows/Media/ColorContext.cs:529` → `new ResourceManager("ColorProfiles", assembly)` |
| PC-4 | `ILLinkTrim.xml` | `EmbeddedResource` | `Condition=Exists(...)`、`LogicalName=$(AssemblyName).xml` | 供 ILLinker 读取（Linux 无 ILLink，保留即可） |

补充实测（**不构成缺口**）：
- `PresentationCore/Fonts/` 下另有 6 个 `.ttf`（andlso/simpbdo/simpfxo/simpo/tradbdo/trado）与 `AnalyzeFont.txt`：**上游 csproj 未引用**，全树 grep 无任何引用 → 非资源，无需搬运。
- `PresentationCore/Resources/ExceptionStringTable.txt`：上游 csproj 未引用 → 非资源。
- `Resources/xlf/`：Arcade XLF 本地化管线输入，本工程未移植该管线 → **N/A**（无卫星程序集）。

### 1.2 PresentationFramework（3 项）

| # | 上游项 | 种类 | 元数据 | 备注 |
|---|---|---|---|---|
| PF-1 | `Resources\Strings.resx` | `EmbeddedResource` | 无 | 运行期基名应为 `PresentationFramework.Resources.Strings`（本工程 `SR.g.cs:16` 实测） |
| PF-2 | `Resources\win32res\split.cur` | `EmbeddedResource` | `Type=Non-Resx`、`ManifestResourceName=SplitCursor`、`WithCulture=false`、`GenerateSource=false` | 光标资源；**这两个项 port-lib 已保真搬运**（实测生成物里 4 条元数据齐全） |
| PF-3 | `Resources\win32res\splitopen.cur` | 同上 | `ManifestResourceName=SplitOpenCursor` | 同上 |

**关于"PF 的 BAML/主题资源"（重要更正）**：实测 `PresentationFramework/` 目录下 **0 个 .xaml、0 个 .baml**，csproj 里**没有任何 `<Page>`/`<ApplicationDefinition>`/`<Resource>` 项**（全部 Item 类型统计：Compile 1329 / ProjectReference 10 / PackageReference 4 / EmbeddedResource 3 / MicrosoftPrivateWinFormsReference 2）。
全树 171 个 `.xaml` 全在 **`Themes/PresentationFramework.*` 独立工程**（Aero/Aero2/AeroLite/Classic/Luna/Royale/Fluent），它们的 BAML 是**那些程序集**的资源，不是 PF 的。
→ 因此本审计范围内"PF BAML 漏搬"不成立；真正的风险在 **Themes 工程尚未移植**（`UxThemeWrapper.cs:417/428` 与 `SystemResources.cs:1673` 的 `themes/generic`、`themes/<name>.<color>` 查找会打到那些程序集）—— 属 M7 主题范畴，登记为缺口（§6）。

### 1.3 DirectWriteForwarder

上游是 C++/CLI（`DirectWriteForwarder.vcxproj`），使用 `<ResourceCompile>`（`version.rc`、VERSIONINFO）——**不是托管资源**。本工程用托管骨架替代（`build/DirectWriteForwarder.Linux`），无 VERSIONINFO 需求 → **N/A**（如需版本信息，已在 `LinuxAssemblyIdentity.cs` 里给出 4.0.0.1）。

---

## 2. 差异表：上游项 → 我们是否有 → 影响 → 处置

| 上游项 | 修复前（实测） | 缺失影响（判定依据） | 处置 | 修复后（实测） |
|---|---|---|---|---|
| **PC-1 复合字体 ×4** | ❌ **完全没有进程序集**（清单仅 3 项，无字体）；port-lib 搬成 `<EmbeddedResource>`，扩展名 `.CompositeFont` 类型未知 → 被 SDK 静默丢弃 | **致命**：运行期 `ResourceManager("PresentationCore.g").GetStream("fonts/globaluserinterface.compositefont")` 必失败 → 字体族/文本渲染全线异常（不是编译错误） | **已修**：补丁 E1（见 §4）——摘掉那 4 条 EmbeddedResource，改用内联任务生成 `PresentationCore.g.resources`（键 `fonts/<小写>`、值按 **Stream** 写入）并以 `LogicalName=$(AssemblyName).g.resources` + `Type=Non-Resx` + `WithCulture=false` 嵌入 | ✅ `PresentationCore.g.resources` 存在，4 条键齐全；**端到端** `ResourceManager(...).GetStream(...)` 4/4 返回 Stream（259500/25313/25749/29021 字节） |
| **PC-2 Strings.resx** | ⚠️ 清单名 `MS.Internal.Strings.resources`（RootNamespace=MS.Internal + 跨目录路径被丢弃），与 `SR.g.cs` 期望的 `PresentationCore.Resources.Strings` **不一致** | **静默降级**：`SR.GetResourceString` catch `MissingManifestResourceException` → 回落到 `SR.g.cs` 内联默认串。不崩，但资源表整体失效（本地化/后续新增串会返回 null） | **已修**：补丁 E2（`ManifestResourceName=$(AssemblyName).Resources.Strings`） | ✅ 清单名 `PresentationCore.Resources.Strings.resources`；`ResourceManager("PresentationCore.Resources.Strings").GetString(...)` 实测 2/2 命中真实串 |
| **PC-3 ColorProfiles.resx** | ✅ 正确：`ColorProfiles.resources`（`ManifestResourceName` 被 port-lib 保真搬运） | — | 无需处置 | ✅ 一致（与 `ColorContext.cs:529` 的 `new ResourceManager("ColorProfiles", asm)` 匹配） |
| **PC-4 ILLinkTrim.xml** | ✅ 正确：`PresentationCore.xml`（`LogicalName` 生效，csc 实参 `/resource:...ILLinkTrim.xml,PresentationCore.xml` 实测） | — | 无需处置 | ✅ |
| **PF-1 Strings.resx** | ⚠️ 生成物里**无** `ManifestResourceName`（实测 `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj:1399`），预期清单名会落到 `MS.Internal.Strings.resources`，而 `SR.g.cs` 期望 `PresentationFramework.Resources.Strings` | 同 PC-2：静默回落到内联默认串 | **未动**（M5 agent 的文件）：已给 port-lib 需求（§5-①）与对应补丁写法（同补丁 E2） | ⏳ 待 M5 落地后复验（PF 尚未构建） |
| **PF-2/PF-3 光标 .cur ×2** | ✅ 元数据保真（`Type=Non-Resx`/`ManifestResourceName=SplitCursor|SplitOpenCursor`/`WithCulture=false` 实测在生成物里） | —（`ManifestResourceName` 是这两个项能进程序集的关键） | 无需处置 | ⏳ 待 PF 构建后按同一探针复验 |
| **PF BAML/主题** | 不适用（上游 PF 无 XAML/BAML，实测） | 主题程序集未移植（M7） | 登记缺口，不在本任务范围 | — |
| **DWF 资源** | N/A（C++/CLI 的 version.rc 非托管资源） | — | 无需处置 | — |

**PC 资源清单数字（实测，快照见 `build/PresentationCore.Linux/resource-manifest.txt`）**

| 指标 | 上游预期 | 修复前实测 | 修复后实测 |
|---|---|---|---|
| 顶层清单资源数 | 3（`PresentationCore.g.resources`、`ColorProfiles.resources`、`PresentationCore.Resources.Strings.resources`）+ `PresentationCore.xml`＝**4** | **3**（少了 `PresentationCore.g.resources`） | **4** ✅ |
| `.g.resources` 内条目 | **4**（fonts/globaluserinterface|globalmonospace|globalsansserif|globalserif `.compositefont`） | **0**（无 `.g.resources` 流） | **4** ✅ |
| 缺失 | 0 | **4**（复合字体） | **0** ✅ |
| 多出 | 0 | 0 | **0** ✅ |
| 键名大小写 | 全小写（`FontSource.cs:391` `ToLowerInvariant()`） | — | ✅ 全小写 |
| 值类型 | **Stream**（`ResourceManager.GetStream` 要求） | — | ✅ Stream（探针按 Stream 读取并报字节数） |

> 探针在 `/tmp/m4/resprobe`（不进仓库）：既做「清单枚举」也做「端到端复刻 PC 运行期取法」，后者是本次两个坑能被抓住的关键（只比"名字存在"会漏掉值类型与键大小写）。

---

## 3. 顺带实测到的**兄弟工程**同类问题（属 port-lib 口径，属他人工件，仅登记）

| 程序集 | 实测清单资源 | 其 `SR.g.cs` 期望基名 | 判定 |
|---|---|---|---|
| `WindowsBase.dll` | **0 项** | `WindowsBase.Resources.Strings` | ❌ 该 resx **根本没被嵌**（上游 WB/System.Xaml csproj 未禁用默认项，靠 SDK 默认 `**/*.resx` glob 嵌入；port-lib 无条件写了 `EnableDefaultEmbeddedResourceItems=false` 且未补显式项）→ SR 全部回落内联默认串 |
| `System.Xaml.dll` | **0 项** | `System.Xaml.Resources.Strings` | ❌ 同上 |
| `UIAutomationTypes.dll` | 1 项：`MS.Internal.Strings.resources` | `UIAutomationTypes.Resources.Strings` | ⚠️ 名字不一致（同 PC-2 修复前） |
| `System.Windows.Input.Manipulations.dll` | 1 项：`MS.Internal.Strings.resources` | `System.Windows.Input.Manipulations.Resources.Strings` | ⚠️ 同上 |
| `PresentationCore.dll` | 4 项（本审计修复后） | `PresentationCore.Resources.Strings` | ✅ |

---

## 4. 我修的项（含 before/after 证据）

全部落在 `build/PresentationCore.Linux/reapply-patches.py`（**补丁 E**，幂等，随 port-lib 重跑后重放）：

| 修复 | 做法 | before | after |
|---|---|---|---|
| **E1 复合字体 → `.g.resources`** | ① 用显式 spec `Remove` 摘掉 port-lib 搬来的 4 条 `<EmbeddedResource ...CompositeFont>`（实测：带元数据条件的 `Remove` 在 Target 内不生效，必须显式 spec）；② `RoslynCodeTaskFactory` 内联任务在 `CreateManifestResourceNames/PrepareResources` 之前生成 `obj/Debug/PresentationCore.g.resources`（`ResourceWriter`，键 `fonts/<小写文件名>`，值 `new MemoryStream(bytes)`）；③ 以 `LogicalName=$(AssemblyName).g.resources` + **`Type=Non-Resx`** + **`WithCulture=false`** 嵌入 | 清单 3 项、无字体、DLL 3,716,096 B | 清单 **4 项**、字体 **4/4**、DLL **4,056,576 B**（+340 KB ≈ .g.resources 体积） |
| **E2 SR 基名对齐** | 对该 resx 加 `ManifestResourceName=$(AssemblyName).Resources.Strings`（用 **`Update="@(EmbeddedResource)"` + 元数据批处理条件**；实测用路径 spec 的 `Update` 会**误伤所有 resx**——曾把 ColorProfiles 的名字也改成 Strings，触发 MSB3577 输出路径冲突） | `MS.Internal.Strings.resources` | `PresentationCore.Resources.Strings.resources`，`ResourceManager(...).GetString()` 2/2 命中 |

**踩坑记录（两条都值得写进 port-lib 的注释）**：
1. SDK 只把 `Type=Non-Resx` **且** `WithCulture=false` 的 `EmbeddedResource` 收进 `ManifestNonResxWithNoCultureOnDisk`（`Microsoft.Common.CurrentVersion.targets:3512`）；缺任一条 → **静默不嵌入**。这正是 PC-1 修复前"4 个字体一个都没进"的机制。
2. `.g.resources` 的条目值必须是 **Stream**：运行期走 `ResourceManager.GetStream`，写成 `byte[]` 会在运行期抛 `InvalidOperationException`（探针从 `[-1 bytes]` 变为真实字节数即是这条的证据）。

---

## 5. 需要主控改 port-lib 的需求清单

> 均已实测，且给出最小规则；PC 侧我已用补丁 E 自己兜住，但**根因在 port-lib**，后续 PF/Themes 会重复踩。

1. **【必修】`EmbeddedResource` 的清单名（ManifestResourceName/LogicalName）必须显式生成，不能靠 SDK 推导。**
   现状：跨工程锥（我们所有项都在 `upstream/...` 下）的文件，SDK 用 `$(RootNamespace)` + 文件名推名，而 port-lib 把 `RootNamespace` 统一写成 `MS.Internal`（PC/PF 都是）→ 实测得到 `MS.Internal.Strings.resources`，与 `gen-sr.py --basename "<Name>.Resources.Strings"` **必然不一致**。
   规则建议：对每个 `<EmbeddedResource>` 生成 `ManifestResourceName = $(AssemblyName) + "." + (<Link或上游相对路径> 去扩展名、'/'→'.')`；`Strings.resx` 的结果正好是 `<AssemblyName>.Resources.Strings`（与 gen-sr.py 对齐）。等价做法：保留上游 `Link` 元数据 + 把 `RootNamespace` 设为 `$(AssemblyName)`。
   影响面（实测）：PC、UIAutomationTypes、System.Windows.Input.Manipulations 三处已错名；PF 待复验。
2. **【必修】`EnableDefaultEmbeddedResourceItems=false` 与"上游未禁用默认项"的组合会**丢资源**。**
   现状：WindowsBase / System.Xaml 上游 csproj **没有** `EnableDefaultItems=false`，它们靠 SDK 默认 `**/*.resx` glob 把 `Resources/Strings.resx` 嵌进去；port-lib 无条件写 `false` 且未补显式项 → 实测这两个 DLL **0 个清单资源**。
   规则建议：当上游未禁用默认项时，port-lib 自行 glob `**/*.resx`（排除 bin/obj/ref）并显式生成项（同时按 ① 命名）。
3. **【必修】WPF `<Resource>` 项不能降级成 `<EmbeddedResource>`。**
   现状：PC-1 的 `<Resource Include="Fonts\*.CompositeFont">` 被搬成 `<EmbeddedResource>` → 既不进 `.g.resources`（运行期要这个），又因缺 `Type` 连普通清单资源都进不去（双重失效）。实测运行期 oracle：`ResourceManagerWrapper.cs:255`「Our build system always generate a resource base name `$(AssemblyShortname).g`」+ `FontSource.cs:394`。
   规则建议：把 `<Resource>` 项汇成一个 `$(AssemblyName).g.resources`（`ResourceWriter`；键 = 上游相对路径小写、值 = `MemoryStream`），以 `LogicalName=$(AssemblyName).g.resources`、`Type=Non-Resx`、`WithCulture=false` 嵌入；**若暂时不做**，至少也要给 `<EmbeddedResource>` 补 `Type=Non-Resx`+`WithCulture=false`，否则项被静默丢弃（比不搬更危险：看不出缺）。
4. **【建议】`Resource` vs `EmbeddedResource` 不要互转**：两者在 .NET Core 里语义不同（前者=WPF `.g.resources`，后者=程序集清单资源）。本次审计范围内，除 PC-1 外未发现其它互转（PF 的 2 个 `.cur` 保持 `EmbeddedResource` 是**正确**的）。
5. **【建议】`CopyToOutput`/`None` 项**：PC/PF 上游均无此类项（实测），暂无需求；若将来移植 Themes/ReachFramework 需复查。

---

## 6. 剩余缺口与复验清单

| 缺口 | 现状 | 恢复/复验条件 |
|---|---|---|
| PF 的 `Strings.resx` 清单名 | 生成物缺 `ManifestResourceName`（实测），预期名与 `SR.g.cs` 不一致 | M5 给 PF 的 `reapply-patches.py` 加同款 E2；PF 构建后用 `/tmp/m4/resprobe -- <PF.dll>` 复验 |
| PF 的 2 个 `.cur` | 元数据齐备（实测），但**未构建**无法验证实际清单名 | PF 构建后复验应见 `SplitCursor` / `SplitOpenCursor` 两个清单资源 |
| 兄弟工程 SR 资源表 | WindowsBase/System.Xaml **0 项**；UIAutomationTypes/Manipulations 名不一致（实测） | 由 §5-①② 的 port-lib 修复统一解决；修完用同一探针扫 5 个 DLL |
| `Themes/*` 主题程序集（BAML）未移植 | 全树 171 个 .xaml 都在这些独立工程里；PF 运行期按 `themes/generic`、`themes/aero.normalcolor` 查找（`SystemResources.cs:1673`、`UxThemeWrapper.cs:417`） | M7 主题里程碑：需要移植 Themes 工程 + 走 `PresentationBuildTasks.Linux`（M2 已有 BAML 编译器）产出各主题程序集的 `.g.resources` |
| `Resources/xlf/` 本地化 | 未移植 Arcade XLF 管线 → 无卫星程序集 | 需要本地化时再评估（当前只发英文内联默认串） |
| `ILLinkTrim.xml` 的消费者 | 已嵌入为 `PresentationCore.xml`，但 Linux 无 ILLinker | 无动作；若引入 trimming 需复查 |

---

## 7. 复现命令

```bash
REPO=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"

# 0) 资源约束（主控实测：3 核/7GB，多 agent 并行）：构建一律增量 + -m:1，
#    且只在需要时构建一次后复用产物（资源清单只在这条链上生成）。
# 1) 生成 + 打补丁（含资源管线补丁 E）+ 构建（实测 0 错 0 警）
cd $REPO
python3 build/port-lib.py PresentationCore
python3 build/PresentationCore.Linux/reapply-patches.py      # B(签名) + D(DWriteForwarder) + E(资源管线)
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -v:m -m:1
#   构建日志中会出现： WPF-on-Linux: 生成 obj/Debug/PresentationCore.g.resources（4 个复合字体 → fonts/*）

# 2) 枚举实际资源名 + 端到端复刻运行期取法（探针在 /tmp，不进仓库）
cd /tmp/m4/resprobe
dotnet run --project resprobe.csproj -- $REPO/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll
#   预期：清单 4 项；fonts/* 4 条；GetStream 4/4；SR 表 2/2

# 3) 快照（本仓库内）
cat $REPO/build/PresentationCore.Linux/resource-manifest.txt
```

## 8. 附：本次审计用到的上游 oracle（便于复核）

| 结论 | oracle 位置 |
|---|---|
| 复合字体要进 `.g.resources`、键 `fonts/<小写>`、值 Stream | `PresentationCore/MS/internal/FontCache/FontSource.cs:391-396` |
| 资源基名一律 `$(AssemblyShortname).g` | `PresentationCore/MS/internal/Resources/ResourceManagerWrapper.cs:255-257` |
| 系统复合字体文件名表（4 个） | `PresentationCore/MS/internal/FontCache/FamilyCollection.cs:200` |
| SR 资源基名 | `build/PresentationCore.Linux/SR.g.cs:16`（由 `gen-sr.py --basename` 生成）；`Common/src/System/SR.cs` 的 `catch(MissingManifestResourceException)` 决定了失配是"静默降级"而非崩溃 |
| `pack://` / 资源枚举也走 `.g.resources` | `PresentationCore/MS/internal/FontCache/FontResourceCache.cs:36` |
| 主题资源名 | `PresentationFramework/System/Windows/SystemResources.cs:1673`、`MS/Win32/UxThemeWrapper.cs:417,428` |
| SDK 只嵌入 `Type=Non-Resx && WithCulture=false` | `$(DOTNET_ROOT)/sdk/10.0.111/Microsoft.Common.CurrentVersion.targets:3512` |

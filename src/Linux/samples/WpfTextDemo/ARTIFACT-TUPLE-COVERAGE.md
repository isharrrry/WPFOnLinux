# 元组覆盖度：**哪些件在应用加载路径里、却不在八位元组里** — 2026-09-14（T3）

**为什么要这份表**：wave21 里 `DirectWriteForwarder.dll` 变了（`879f0020… → 2f77dbdf5e7e2cd5`）
而**八位元组看不见它** ⇒ 与"#6 把源陈旧的桥冻成基线"**同族的静默位**。
下表把"在 app-local 加载路径、又不在元组里"的件**逐条列清**并给出判断与依据。

**判据（主控给的口径，采用并写死在这里）**：
> 该件是否**可能影响门禁判据所测的行为**？（判据行为面 = ①存活/退出 ②skia 指令数>0 且未画种类=0
> ③有效帧/颜色数 ④特性色像素 ⑤裁剪几何 ⑥真滚动 AE ⑦行推进 distinct_origin_y）
> **再叠加本项目既有纪律**：自产件"**宁可多报，不可漏报**"（#6 事件的教训）。

## 一、已进元组的九位（现状）
`bridge`(wpfgfx_cor3.so) ｜ `pc` ｜ `pf` ｜ `provider` ｜ `win32shim`(libwpfwin32.so) ｜ `wic_shim`(libwpfwic.so) ｜
`hbtextline`(shim 源) ｜ `windowsbase` ｜ **`dwf`（第九位，自本版起）**。

## 二、未进元组、但在 app-local 加载路径里的自产件（逐条）

| 件 | 权威路径 | 现值(16) | 影响判据行为面的可能性 | 判断 | 依据 |
|---|---|---|---|---|---|
| **DirectWriteForwarder.dll** | `build/DirectWriteForwarder.Linux/bin/Debug/` | `2f77dbdf5e7e2cd5` | **高**：字体/文本栈（给 PC 提供 DirectWrite API），字形度量/整形直接决定 ②③④⑦ | **✅ 进元组（已落地，第九位）** | 主控派的正是它；wave21 实测它变了而读数看不见 |
| **ReachFramework.dll** | `build/ReachFramework.Linux/bin/Debug/` | `ede1f3644a56ccc0` | **中低**：XPS/打印方向；门禁应用的被测行为（文本/滚动/图像）**不经过**它；但 PF 依赖它、它在加载闭包里 | **⚠️ 可见位，不进冻结元组** | ① **app-local 陈旧史**：连续三波其 bin↔权威对都不同（`daf9b6f0/f64b76d4` → `9ad071fe/f608cbc9` → `da65eaf4/ede1f364`）；② 若进冻结元组，**每一波都会强制重冻**，而它多半与判据无关 ⇒ **噪声大于信息**。**升级触发条件**：某一波它变了**且**门禁读数出现任何差异 ⇒ 立刻升进冻结元组 |
| **System.Xaml.dll** | `build/System.Xaml.Linux/bin/Debug/` | `d6ea4ffe6a5d4737` | **中高**：XAML 解析 ⇒ 应用能否建起可视树 ⇒ ①②③ | **⚠️ 可见位，不进冻结元组** | 自产件 + 在加载路径 + 影响启动阶段；当前值跨 #6–#8 未变。**升级触发条件同上** |
| **PresentationUI.dll** | **`build/CycleStub.PresentationUI.Linux/bin/Debug/`**（断环 stub；**不存在** `build/PresentationUI.Linux/`） | `bf20bd9e57290b09` | **中**：内建对话框/主题辅助；门禁应用不一定触达 | ⚠️ 可见位 | 旁证：`build/PresentationFramework.Linux/bin/Debug/PresentationUI.dll` 与它同 sha；成本一次 sha256 |
| **PresentationFramework.Classic.dll** | `build/PresentationFramework.Classic.Linux/bin/Debug/` | `55f981c3261309ea` | **低**：Classic 主题资源；应用用默认主题 | ⚠️ 可见位 | 值多波未变；只在切 Classic 主题时被加载 |
| **System.Printing.dll** | `build/System.Printing.Linux/bin/Debug/` | `17beaac6842d9a5c` | **低**：打印；判据不测 | ⚠️ 可见位 | 自产件、在目录里、成本低 |
| **UIAutomationTypes.dll** | `build/UIAutomationTypes.Linux/bin/Debug/` | `2ac8d37b7cdc5afd` | **低**（判据不测自动化） | ⚠️ 可见位 | 自产件、在加载路径；成本一次 sha256 |
| **UIAutomationProvider.dll** | `build/UIAutomationProvider.Linux/bin/Debug/` | `352ccd757a2f2fb0` | **低** | ⚠️ 可见位 | 同上 |
| **libSkiaSharp.so**（native） | `build/DirectWrite.Linux/wic-shim/libSkiaSharp.so`（仓内 vendored，9,244,960 B） | `a02cd03f1ebcbb97` | **高**：Skia 后端，落在渲染路径上（②③④） | ⚠️ 可见位 | **主控已查清出处**：与 **NuGet 钉版** `~/.nuget/packages/skiasharp.nativeassets.linux/2.88.9/runtimes/linux-x64/native/libSkiaSharp.so` **逐字节相同**（同 sha、同 9,244,960 B、包内 mtime 2024-11-07）；版本由 `src/WpfGfx.Linux/WpfGfx.Linux.csproj` 钉住（`SkiaSharp 2.88.9` + `NativeAssets.Linux 2.88.9`，注释"4.x 有破坏性 API 变更，禁止升级"）⇒ **不是来路不明的二进制**。可见位判据 = **可复算一句**："仓内副本 == NuGet 2.88.9 linux-x64 native asset（同 sha）" |
| **System.Windows.Input.Manipulations.dll** | `build/System.Windows.Input.Manipulations.Linux/bin/Debug/` | `c264f0ec86fad755` | **低中**：触控/操作输入（判据不测触控） | ⚠️ 可见位 | 输入族；值多波未变 |
| **上游 .NET / NuGet 件**（`SkiaSharp.dll`、`System.*` 运行时等） | 不在仓内构建 | — | 由 SDK/包版本钉住 | **❌ 不进** | 不是自产件；变它们等于换 SDK，另有构建侧记录 |

## 三、更正（2026-09-14；主控派 M7b 核出，我**现场复核**后改表）

**❌ 原表那句「`UIAutomationTypes` 另有已知缺口（未编 resolver，M7b 车道）」= 陈旧且不属实** ⇒ 现按实读拆成**两条**，不再混成一句：

| # | 事实 | 状态 | 现场复核（我实跑/实读的原文） |
|---|---|---|---|
| **A** | **`UIAutomationTypes` 的 D1 resolver 已落地**（曾被误记为缺口） | **已落地** | `python3 src/WpfGfx.Linux.Native/tools/wire-uiautomation-resolver.py --check` 原文：`[resolver] 分支已就位（幂等，不改）` / `[清单] UIAutomationTypes.shims.txt 已就位（2 行，幂等，不改）` / `[清单] UIAutomationProvider.shims.txt 已就位（1 行，幂等，不改）`，**rc=0**。佐证：`UIAutomationTypes.Linux.csproj:95` 已含 `build/shims/Win32ShimResolver.cs`；`build/shims/UIAutomationTypes.shims.txt` = `Win32ShimResolver.cs` + `Accessibility.Shim.cs`（2 行）；`build/shims/Win32ShimResolver.cs:41-48` 的 `#elif UIAUTOMATIONTYPES || AUTOMATION` 分支在位；已建 DLL 内含 `Win32ShimResolver`(2 处) / `DllImportResolver`(1 处) |
| **B** | **`UiaLookupId` 的 raw P/Invoke 仍指向未映射的 `UIAutomationCore.dll`**（**这才是那条在册未做项**） | **在册未做 · 本波不落** | `build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs`：`[DllImport(DllImport.UIAutomationCore, EntryPoint = "UiaLookupId")] private static extern int RawUiaLookupId(AutomationIdType type, ref Guid guid);`；`UIAutomationCore` **不在** `build/shims/Win32ShimResolver.cs:86` 的 `MappedLibraries`（我在 shim 源码与两个清单里 grep `UIAutomationCore` **零命中**）；`nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| grep -c " T Uia"` = **0** ⇒ 今天 = **诚实的 `DllNotFoundException`**；`SupportsWin7Identifiers()`（同文件 `:89-95`）取不到句柄/入口 ⇒ **恒 NULL ⇒ 静默 `false`（降级）** |
| | **影响面** | 只限 **GUID → UIA 整型 ID** 这条转换 | **渲染 / 输入 / 文本链零影响**（正因如此它不在冻结元组的判据行为面上） |
| | **修法前置（顺序不可反）** | **先落导出，再映射** | 只加映射会**降级成 `EntryPointNotFoundException`**（本项目一路在避免"用崩溃换一个假绿"）⇒ 前置 = shim 先导 `Uia*`；判据 = 落完后 `--check` 仍 rc=0、且 `SupportsWin7Identifiers()` 返回真值（不再是恒 false） |

## 四、落地状态（主控 2026-09-14 批准后已实现）
1. **冻结元组** = "八位 + `dwf_sha`"（判据行为面最强的那些件）；
2. **两个 runner 各加了一行扩展可见位**（`WPTD_ARTIFACTS_EXT` / `WFP_ARTIFACTS_EXT`，**只追加、不参与冻结判定**）：
   含第二节 9 个件；`reachframework_role` / `systemxaml_role` 行内标 **`visible-not-frozen`**；
   `libskia_sha` + `libskia_nuget_2_88_9_match` 为**可复算口径**（NuGet 副本缺失 ⇒ `NOINFO`，**不当 yes**）。
3. 判读口径：**扩展位变化 = 不自动作废基线，但必须在下一版表头记录**。
4. 2026-09-14 实算值（`bash -n` 自检 + 直接执行同段逻辑，**未跑应用**）：
```
reachframework=ede1f3644a56ccc0  systemxaml=d6ea4ffe6a5d4737  presentationui=bf20bd9e57290b09  pfclassic=55f981c3261309ea
systemprinting=17beaac6842d9a5c  uiatypes=2ac8d37b7cdc5afd  uiaprovider=352ccd757a2f2fb0  manipulations=c264f0ec86fad755
libskia_sha=a02cd03f1ebcbb97  libskia_nuget_2_88_9_match=yes(nuget-2.88.9-linux-x64)
```

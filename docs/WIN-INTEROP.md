# Windows 互兼容性现状（大白话版）

> 主题：**Windows 上编出来的东西（XAML 编译二进制 / dll / 现成 NuGet 包），这套 Linux 移植栈能不能直接用？反过来呢？**
> 结论口径：本仓规格**明文不做二进制兼容**（`README.md:4`、`docs/PORT-SPEC.md:13`）⇒ 本文只回答"**实际会不会通、卡在哪**"，不承诺路线。
> 取证方式：3 路只读取证（程序集身份 / BAML 链路 / NuGet 包）+ 主控交叉复验；全部读数带可复算命令。
> 读时：2026-10-01。⚠️ 本页所有数字都是**现场读数**，权威一律以现场重算为准。

---

## 0. 一页速答

| 你拿来的东西 | 能不能直接用 | 卡在哪 |
|---|---|---|
| **XAML 编译二进制**（`.baml` / `.g.resources`） | 🟡 **格式层面兼容**（字节相同的同源编译器、版本头都是 0.96） | 能不能用不取决于 BAML 自己，取决于外层 dll 能不能被宿主加载起来 |
| **Windows 编的 WPF dll**（含 XAML 的应用/库） | ❌ **默认不能** | 四道闸：宿主框架（WindowsDesktop.App）、程序集版本（10.0.0.0 vs 4.0.0.1）、原生依赖（X11/ELF）、API 覆盖 |
| **Windows 编的普通 .NET 库 dll**（不碰 WPF） | ✅ 基本可以 | 只要它的 `TargetFramework` 与本栈一致（net10.0），且不引用官方 WPF 身份 |
| **现成 NuGet 包** | ⚠️ **看包** | 官方 WPF 组件在 nuget.org 上没有独立包；带 `runtimes/win` 的包在 Linux 上落回"必抛桩"；WPF 控件库包带 `frameworkReference` ⇒ 直接拒装 |
| **反过来：本栈 Linux 产物拿到 Windows 跑** | ❌ **不可能** | `libwpfwin32.so` / `wpfgfx_cor3.so` 是 **ELF 共享库**（Windows 加载不了），且要 X11 |

**一句话**：这套移植栈的姿势是"**把你的源码拿来，在 Linux 上重新编译一遍**"（`<UseWPF>false</UseWPF>` + 引用自产件），不是"把你的 Windows 产物拿来跑"。第三方实证（HandyControl 371 个 `.cs`、`samples/ThirdPartyMini`）**全部是源码重编**，仓内**没有任何一条**"直接跑 Windows 编译产物"的记录。

---

## 1. 大白话：三块分别是什么情况

### 1.1 XAML 编译二进制（BAML）：**能对上，字节都一样**

- **编译本身同源同版**：本仓把上游的 `PresentationBuildTasks` 移植成 Linux 版（`build/PresentationBuildTasks.Linux/`，改动只有工程/路径/包版本 8 项，**编译算法一行没动**），实测**自产 PBT 与 SDK 官方 PBT 对同一份 XAML 的输出逐字节相同**：

  ```
  cd74886ae4ce10449cbf9e4395dcb73d67f21d4ba62121399324d861d2b3a73c  self/App.baml
  4b461312c8c7198624807c5446d25bd4d365a523889145bbf56bcf292fd484d3  self/MainWindow.baml
  cd74886ae4ce10449cbf9e4395dcb73d67f21d4ba62121399324d861d2b3a73c  sdk/App.baml
  4b461312c8c7198624807c5446d25bd4d365a523889145bbf56bcf292fd484d3  sdk/MainWindow.baml
  ```
  ⇒ "Linux 生成的 BAML 与 Windows 生成的 BAML 一样"这句话，**今天仍可复算且为真**（T0T1 那条旧记录的具体产物 860B/1756B 已不可原样复算，但等价命题成立）。

- **版本头是硬闸**：加载时读 BAML 头 `MSBAML` 的版本对，与代码里硬编码的 `(0, 96)` **做相等比较**，不等就抛 `InvalidOperationException(SR.ParserBamlVersion)`（`upstream/.../Markup/BamlVersionHeader.cs:28,78`）。现场自产 BAML 头 `0x0060 = 96`，与 win 侧同一个 0.96 ⇒ **这一关是通的**。

- **但 BAML 里记的是"程序集全名"**（含版本+令牌），不是光名字：
  ```
  PresentationCore, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35   ← 本栈 BAML 里写的是自产身份
  ```
  Windows 侧编出来的 BAML 里写的会是 `Version=10.0.0.0`。加载侧有一层**回退**能救：先按全名找 → 失败则 `Assembly.Load(短名)`（`Baml6Assembly.cs:43-67`、`Baml2006SchemaContext.cs:455-505`），实测**短名回退成功且令牌差异被忽略**。

⛔ 所以 BAML 不是障碍，**障碍在 dll 这一层**。

### 1.2 Windows 编的 dll：**四道闸，默认过不去**

| 闸 | 现象 | 证据 |
|---|---|---|
| ① **宿主框架** | Windows 的 WPF 应用 `runtimeconfig.json` 声明 `Microsoft.WindowsDesktop.App`；Linux 上没这个框架 ⇒ 应用**根本没启动**（该报错来自本栈早期用 `UseWPF=true` 编出的**同形态**产物） | `docs/T0T1-report.md:71` 原文：`Framework: 'Microsoft.WindowsDesktop.App', version '10.0.0' ... No frameworks were found`；本栈样本的 `runtimeconfig.json` 只有 `Microsoft.NETCore.App`（现场读） |
| ② **程序集版本** | .NET 默认绑定要求"找到的版本 **≥** 请求的版本"。自产件一律 **4.0.0.1**；官方 ref 包是 **4.0.0.0(net48) / 8.0.0.0(net8) / 10.0.0.0(net10)** ⇒ 请求 8/10 的 dll **绑不上**（`FileNotFoundException 0x80070002`） | 探针实测：请求 `4.0.0.0` → OK；请求 `8.0.0.0`/`10.0.0.0` → FAIL。交叉印证：`Baml6Assembly` 那条短名回退也救不了非 BAML 的普通引用 |
| ③ **令牌** | 自产件用的是上游 WCP 公钥（令牌 `31bf3856ad364e35`），**除 `System.Xaml` / `System.Windows.Input.Manipulations` 外与官方一致**；实测**令牌不阻塞绑定** | 自产 10 件身份实测；反向：官方 `System.Xaml` 是 `b77a5c561934e089`，请求它也能绑到自产件（`Assembly.Load` 忽略 token） |
| ④ **原生依赖** | 本栈的渲染/Win32/WIC 全靠 `.so` + X11：`libwpfwin32.so`、`libwpfwic.so`、`wpfgfx_cor3.so`（`file` 实测 = **ELF 64-bit LSB shared object**）+ `libSkiaSharp.so`；宿主需求与 Windows 完全不同 | `file -b` 输出；部署配方见 `docs/THIRD-PARTY-APPS.md` §3 |

补充：全仓**没有任何"身份重定向"机制**——`AssemblyResolve` 在产品代码里 **0 命中**、无 `bindingRedirect`、没有把官方身份映射到自产件的表。唯一让官方身份落到自产件的通道是**编译期**（`<Reference HintPath>`）与**手工改 `deps.json`**。

### 1.3 现成 NuGet 包：**官方 WPF 那批包根本不存在；第三方看包**

| 包类 | 情况 |
|---|---|
| `System.Xaml` / `System.Printing` / `UIAutomationTypes` / `UIAutomationProvider` / `System.Windows.Input.Manipulations` | **nuget.org 上没有独立包**（flatcontainer + search API 双通道均为空/404；对照组 `Newtonsoft.Json` 200）。它们只随 `Microsoft.WindowsDesktop.App` 共享框架走 ⇒ 本仓一律**源码重编** |
| `Microsoft.WindowsDesktop.App.Ref` | 本机缓存里有（`8.0.30` / `10.0.11`，**纯引用程序集**）⇒ **编译期**能拿到官方身份，**运行期无实现** |
| `Microsoft.WindowsDesktop.App.Runtime.win-x64` / `.win-arm64` | 有；`runtime.linux-x64` **404** ⇒ Linux 上没有 WPF 运行时 |
| `System.Windows.Extensions` | 非 Windows 资产 = **必抛桩**（`strings` 实测文案 `System.Windows.Extensions types are not supported on this platform.`）；本仓用替身 `build/System.Windows.Extensions.Linux/` + `ExcludeAssets="compile;runtime"` 占位配方打通（`#38`；反极性：换回官方包必崩 `PlatformNotSupportedException`） |
| `System.Diagnostics.EventLog` / `Microsoft.Win32.SystemEvents` | 带 `runtimes/win` ⇒ Linux 上落回非 win 资产（行为降级/桩） |
| `SkiaSharp` + `SkiaSharp.NativeAssets.Linux` | **唯一被本栈重度使用的现成包**（覆盖 36 个消费方）；**必须成对**、版本 `2.88.9`：只装托管包 ⇒ 运行期 `DllNotFoundException: libSkiaSharp` |
| 第三方普通库包（`Newtonsoft.Json` 等） | ✅ 可引可用 |
| 第三方 **WPF 控件库包** | ❌ 带 `<frameworkReference name="Microsoft.WindowsDesktop.App"/>` 的包直接 **`NETSDK1136`**（实例：HandyControl 依赖的 `AvalonEdit 6.0.1` 被换成源码 stub） |
| 本仓自产件本身 | **没有打成 NuGet 包**（`GeneratePackageOnBuild`/`dotnet pack`/`.nupkg`/`IsPackable` 在 `*.Linux` 上命中 **0/0/0/0**）⇒ 不能"装包"，只能 `<Reference HintPath>` 指到 `build/*.Linux/bin/<Config>/` |

---

## 2. ASCII 总览

### 2.1 Windows 编出来的三种东西，走这四道闸

```
 Windows 侧编出来的东西                    Linux 本栈的关卡                              结果
 ──────────────────────────────────────────────────────────────────────────────────────────────────
 ├─ ① XAML 编译二进制（App.baml / *.g.resources）
 │     ┄┄ 闸A 格式版本   头部要 0.96，win 与本栈都是 0.96 …………… ┄┄ ✅ 相等才过（硬闸）
 │     ┄┄ 闸B 程序集名   全名（10.0.0.0）查不到 → 回退短名 ……… ┄┄ 🟡 能救（仅 BAML 解析路径内）
 │     ⇒ BAML 本身不是障碍，障碍在外层 dll
 │
 ├─ ② 应用 / 库 dll（Xxx.dll + Xxx.runtimeconfig.json + 资源）
 │     闸1 宿主框架   runtimeconfig 要 Microsoft.WindowsDesktop.App …… Linux 无此框架  ❌
 │     闸2 程序集版本  请求 8.0.0.0/10.0.0.0，自产只有 4.0.0.1 ……………… 默认绑不上  ❌
 │     闸3 公钥令牌   31bf… vs b77a…（只差 System.Xaml 等 2 件）………… 不阻塞绑定  🟡
 │     闸4 原生依赖   libwpfwin32.so / wpfgfx_cor3.so / X11 ……………… 与 win 完全不同  ❌
 │     ⇒ 默认过不去；且仓内**没有**身份重定向解析器来补闸2
 │
 └─ ③ NuGet 包
       官方 WPF 组件包（System.Xaml / System.Printing / UIAutomation*）→ nuget.org 无独立包  ❌
       带 runtimes/win 的 BCL 包（SWE / EventLog / SystemEvents）…… → 落回非 win 桩 ⇒ 必抛  ⚠️
       普通库包（Newtonsoft.Json 等）………………………………………… → 可用                ✅
       WPF 控件库包（AvalonEdit 6.0.1 实测）………………………… → frameworkReference ⇒ NETSDK1136  ❌

 反向：本栈产物 → Windows ⇒ ❌ 不可能（libwpfwin32.so / wpfgfx_cor3.so 是 ELF，且要 X11）
```

### 2.2 本栈**唯一支持的姿势**（源码重编）

```
   你的源码 (.cs / .xaml / .csproj)
        │  改三处：<UseWPF>false</UseWPF> + import WpfLinux.props + 显式 XAML Item
        ▼
   build/third-party/WpfLinux.props ──▶ <Reference HintPath> 自产 10 件（bin/<Config>/）
        │
        ├─ XAML ──▶ 自产 PresentationBuildTasks ──▶ BAML（与官方 PBT 输出逐字节相同）
        │
        └─ 编译产物（应用 dll + 4 个 .so + libSkiaSharp.so，零环境变量布局）
                │
                ▼
           X11（真显示器 / Xvfb）── dotnet YourApp.dll
```

### 2.3 身份对照（谁跟谁"同名"）

```
  程序集名                        自产（本栈）                    官方（Windows Desktop）
  ────────────────────────────────────────────────────────────────────────────────────────
  PresentationCore ............. 4.0.0.1 / 31bf…          net48 4.0.0.0｜net8 8.0.0.0｜net10 10.0.0.0 / 31bf…
  PresentationFramework ........ 4.0.0.1 / 31bf…          同上 / 31bf…
  WindowsBase .................. 4.0.0.1 / 31bf…          同上 / 31bf…      （另有框架空门面 4.0.0.0）
  System.Xaml .................. 4.0.0.1 / 31bf…  ⚠️      同上 / b77a…      ⚠️ 令牌不同
  System.Windows.Input.Manip. .. 4.0.0.1 / 31bf…  ⚠️      同上 / b77a…      ⚠️ 令牌不同
  PresentationFramework.Classic  4.0.0.1 / 31bf…          同上 / 31bf…
  UIAutomationTypes/Provider ... 4.0.0.1 / 31bf…          同上 / 31bf…
  DirectWriteForwarder ......... 4.0.0.1 / 31bf…          NOINFO（ref 包不含该件）
  DirectWrite.Linux.Provider ... 1.0.0.0 / 无令牌          官方无此名（本仓自造）
  ────────────────────────────────────────────────────────────────────────────────────────
  署名方式：PublicSign（只含公钥的 WcpPublicKey.snk，160 B 纯公钥）
            ⇒ 签名区是 128 B 全零占位，真验签**过不了**；.NET Core 运行期**不验签** ⇒ 加载不受阻
```

---

## 3. 如果真想"跨用"，最短的坎清单

1. **只能走 BAML 解析路的那一半**：程序集短名回退（`Baml6Assembly.cs:43-67`）能让"官方身份的名字"落到自产件上，但这条只在 BAML 加载器内部，普通 `AssemblyRef` 不走它。
2. **要改 `runtimeconfig.json`**：把 `Microsoft.WindowsDesktop.App` 框架项去掉/换成 `Microsoft.NETCore.App`，否则宿主直接起不来（本栈样本的 runtimeconfig 现场就是这样写的）。
3. **要给版本绑定搭桥**：net8/net10 编的 dll 请求 `8.0.0.0/10.0.0.0`，自产件 4.0.0.1 太低 ⇒ 需要一个 `Resolving`/`AssemblyResolve` 式**身份重定向解析器**（实测 `Resolving` 无条件供件时全部成功）—— **本仓没有这段代码**，写它等于新开一条与"源码重编"并行的路线。
4. **要解决原生面**：`.so` 四件套 + X11 + 本栈 wpfgfx 桥，Windows 应用本来的 D3D/DirectWrite 路径在这里会被降级或如实失败。
5. **行为不等价**：本栈目标只有"能编译、能开窗、能画出来、能交互"，**不是完整 API 覆盖**（很多 Win32/GDI+/ntdll 面是"如实失败"，主题栈只移植了 Classic）。

**反之**（Linux 产物 → Windows）：`libwpfwin32.so`、`wpfgfx_cor3.so` 是 ELF；自产托管件依赖这些 `.so` 与 X11 ⇒ **Windows 上不可能跑**。

---

## 4. 可复算命令（挑最关键的）

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux

# ① 自产件身份（Version / PublicKeyToken）
#    报告内的取值工具：/tmp/wincompat/probe/bin/Release/net10.0/ident.dll <dll>
#    官方对照（本机缓存，无需下载）：
ls ~/.nuget/packages/microsoft.windowsdesktop.app.ref/10.0.11/ref/net10.0/PresentationFramework.dll

# ② BAML：自产 PBT 与 SDK PBT 输出逐字节比对（/tmp 最小工程，见 B 报告 §6 实验 A）
#    自产 PBT 权威路径（diag 原始输出里 "正在使用程序集…MarkupCompilePass1"）：
dotnet msbuild samples/HelloWpf/HelloWpf.csproj -p:Configuration=Release -v:diag \
  | grep -m1 'MarkupCompilePass1'

# ③ BAML 版本头 = (0,96) 硬相等
grep -n 'BamlWriterVersion = new VersionPair\|ReaderVersion != BamlWriterVersion' \
  upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/System/Windows/Markup/BamlVersionHeader.cs
xxd -l 32 samples/ThirdPartyMini/obj/Release/net10.0/MainWindow.baml     # 0x0060 = 96

# ④ 本栈样本不带 WindowsDesktop 框架（对照 Windows 应用的 runtimeconfig）
cat samples/ThirdPartyMini/bin/Release/net10.0/ThirdPartyMini.runtimeconfig.json

# ⑤ 原生件是 ELF（Windows 跑不了）
file -b src/WpfGfx.Linux.Native/bin/libwpfwin32.so \
        build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so

# ⑥ 无身份重定向
grep -rn "AssemblyResolve" --include=*.cs build src samples tests | wc -l    # → 0
```

---

## 5. 待裁决 / 已知文档与现场不一致（取证过程中抓到的）

| # | 事项 | 现状 | 建议 |
|---|---|---|---|
| 1 | 自产 `System.Xaml`、`System.Windows.Input.Manipulations` 用令牌 `31bf…`，官方用 `b77a…` | 与官方**身份不符**（"披着 WCP 令牌的官方名"）；实测不阻塞绑定 | 要么登记为**有意差异**，要么改为 `b77a…` 签名 |
| 2 | 自产件版本固定 `4.0.0.1`（为绕开框架空门面 4.0.0.0） | 代价：**系统性拒绝** net8/net10 编译的 WPF dll（4.0.0.1 < 8.0.0.0） | 在规格里显式登记这条兼容性代价 |
| 3 | `build/SelfBuiltConfig.props` 头注写"当前值 **Debug**"，文件实际是 `Release`；`docs/THIRD-PARTY-APPS.md:188` 也说权限件是 Debug | 注释/文档滞后 | 改注释（值以文件为准） |
| 4 | `D-G45`（System.Windows.Extensions 替身）在 4 处文档里状态不一：`未打通`/`停用`/`已打通` | 现场真相 = **已打通**（7 工程 + 3 样本已接线，替身进了应用输出） | 统一为"已打通" |
| 5 | `System.Windows.Extensions` 配方：`PORT-CHANGES.md` 写 `ExcludeAssets="runtime"`，实际用 `compile;runtime` | 前者**不够**（编译资产还在，包照样赢） | 改过期措辞 |
| 6 | `docs/THIRD-PARTY-APPS.md:28-37` 列产物路径为 `bin/Debug/` | 唯一声明已是 `Release` | 改文档 |
| 7 | `build/DirectWrite.Linux/WiringSmoke/fix-deps.py` 称"写进 deps.json 就能让宿主选自产 WindowsBase" | A 的探针**未复现**（框架门面仍胜出，且未复现 `0x80131040`，只拿到 `0x80070002`） | 待定位（写法差异或宿主版本） |
| 8 | 工作树有两处未提交改动（`src/WpfGfx.Linux.Native/src/win32_pts.c`、`build/MilBridge/tasks-tail2/T-A53.md`） | **非本次取证所为**（取证全程只读） | 由仓库所有者处理 |

---

## 6. 边界（照抄规格，不许美化）

- `README.md:4`：**不**兼容"在 Windows 上编译好的 WPF 二进制"——这个边界砍掉了整条二进制兼容路线的工作量。
- `docs/PORT-SPEC.md:13`：**不**要求"在 Windows 上编译好的 WPF 二进制"能在 Linux 跑。
- `docs/THIRD-PARTY-APPS.md:178`：目标是"**从源码编译 + 真的画出界面**"，**不是**二进制兼容、也不是完整 API 覆盖。
- 第三方实证（HandyControl）**在仓外**，仓内判据只覆盖自建样本（`samples/ThirdPartyMini` 是仓内的"第三方形态"样本）。

<!-- 取证来源：/tmp/wincompat/{A,B,C}-REPORT.md（程序集身份 / BAML 链路 / NuGet 包），均由主控交叉复验 -->

---

## 7.（追加 2026-10-01）「零改动接入 + 双向互跑」要多少改动

> 诉求原文：① 让第三方工程**不必**改三处（`UseWPF=false` / `import WpfLinux.props` / 显式 XAML Item）；② 现成 NuGet 包（Windows 侧编出来的）能用；③ Linux 编出来的 WPF 程序**在 Windows 上也能直接跑**（不再重编）。
> 目标候选：造一个"替代版 `Microsoft.WindowsDesktop.App`"，或"Linux 编译 → Linux 能跑 → Windows 上跑个 bat 替换 runtime dll 即可"。
> 本文把这三件事**拆开单独算账**——它们的成本差一个数量级，混在一起谈会得出错误结论。

## 7.0 结论速览

| 子目标 | 今天的状态 | 还需要做什么 | 难度 |
|---|---|---|---|
| **G1 零 csproj 改动编译**（Linux） | ✅ **已成立**（实测） | 只差 TFM 变成 `net10.0-windows`（±`EnableWindowsTargeting`）；PBT/ref pack/默认 XAML glob **全部可复用官方** | **低** |
| **G2 零改动运行**（Linux） | ❌ 缺 `Microsoft.WindowsDesktop.App` 的 Linux 运行时 | 自产该框架（**唯一必须新做的一块**）；两种落点（shared framework 目录 / runtime pack） | **中~高** |
| **G3 跑 Windows 编的 NuGet 包**（二进制） | ❌ 版本 4.0.0.1 < 官方 8.0/10.0.0.0 ⇒ 默认绑不上 | 自产件身份抬到 `10.0.0.0`（+ 对齐 `System.Xaml`/`Manipulations` 令牌）+ 接受"API 覆盖仍是子集" | **中**（身份）＋**不可控**（覆盖度） |
| **G4 Linux 编 → Windows 跑** | ❌ 原样搬必崩（自产 resolver 会把 `user32.dll` 劫持到不存在的 `.so`） | ① shim 加一行"Windows 上短路"② 导出脚本改 runtimeconfig/deps ③ API 面审计 | **低~中** |
| **G5 绝对零改动**（`net10.0` 不改 TFM） | ❌ **不可能** | `WindowsDesktopTargetPlatformMustBeWindows` 要求 `TargetPlatformIdentifier=Windows` | — |

**一句话**：G1 免费（只动 TFM），G2 是新工程主体，G3 靠改版本号换一半、另一半（行为覆盖）无解，G4 很便宜但必须承认"Windows 上跑的是官方件、不是我们的实现"。

## 7.1 已成立的那一半：零改动编译（实测）

在 `/tmp` 造的标准工程（`net10.0-windows` + `EnableWindowsTargeting=true` + `UseWPF=true` + 默认 glob，只引官方 ref pack）：

```
$ dotnet build /tmp/wincompat/exp1/exp1.csproj -c Release
  exp1 -> /tmp/wincompat/exp1/bin/Release/net10.0-windows/exp1.dll
已成功生成。   0 个警告   0 个错误        EXIT=0
```

- `App.xaml` → `ApplicationDefinition`、`**/*.xaml` → `Page` **自动 glob**（条件：`EnableDefaultItems=true` ∧ `UseWPF=true` ∧ TFV≥3.0；`EnableDefaultPageItems`/`EnableDefaultApplicationDefinition` 默认 `true`，`DefaultXamlRuntime` 默认 `Wpf`）⇒ **"显式 XAML Item"那一条根本不需要**。
- XAML 真编过：`obj/` 下产出 `App.g.cs`、`MainWindow.g.cs`、`MainWindow.baml`（**官方 PBT 在 Linux 上跑得动**；要用自产 PBT 时可用下面任一注入点抢先设 `_PresentationBuildTasksAssembly`）。
- ref 层**不必自产**：`Microsoft.WindowsDesktop.App.Ref` 走 NuGet 下载（`obj/project.assets.json` 的 `downloadDependencies`），官方包在 Linux 上直接就位。
- **唯一在工程外就能生效的注入点**（实测可行）：
  | 注入点 | 结果 |
  |---|---|
  | 环境变量 `CustomBeforeMicrosoftCommonTargets` / `CustomAfterMicrosoftCommonTargets` | ✅ 可行，且**早于** WinFX targets ⇒ 能"先设值"接管 PBT |
  | 环境变量 `CustomAfterMicrosoftCommonProps` | ✅ 导入生效（props 阶段，最早） |
  | NuGet 包的 `build/*.targets` | ✅ 可行（由 `obj/*.nuget.g.targets` 早于 WindowsDesktop targets 导入）⚠️ 推翻"需要更早注入点"的预设 |
  | 本地 NuGet 源放**同 id/version** 的 `Microsoft.WindowsDesktop.App.Ref` | ✅ 实测顶替成功（自产 ref 层可行，但没必要） |
  | 环境变量 `MSBuildSDKsPath` 指向副本 | ⚠️ 可行但**必须镜像整个 dotnet 根**（只复制 `Sdks/` 会 `MSB4186`/`MSB4019`/`NETSDK1226`） |
  | `global.json` 的 `msbuild-sdks` | ❌ 不可行（in-box SDK 优先命中） |

⛔ **"零改动"的硬下界（必须说清）**：
1. **TFM 必须带 `-windows`**（纯 `net10.0` 会被 `_CheckForInvalidWindowsDesktopTargetingConfiguration` 拦成 `WindowsDesktopTargetPlatformMustBeWindows`）。`EnableWindowsTargeting=true` 可以用环境变量给，TFM 能不能用工程外注入改（环境变量 `TargetFramework` / `CustomAfterMicrosoftCommonProps` 里设）**未验证**——若工程里已写死 `<TargetFramework>`，就压不过去 ⇒ 至少这一行得改。
2. **`SkiaSharp` / `SkiaSharp.NativeAssets.Linux` / OOB BCL 包必须有 `PackageReference`**（restore 需要）。它们能否从工程外的注入点补进 `PackageReference` 项 **未验证**（注入 targets 在求值顺序上够早，但要实测）；退一步的做法是在工程目录放一份 `Directory.Build.props`/`Directory.Packages.props`（1 个文件，不是 3 处）。
3. ⇒ 现实的"零改动"形态是：**工程外一个注入 targets ＋ 最多一个 `Directory.Build.props` ＋ TFM 一行**。绝对零改动做不到（SDK 的 Windows 门就卡在那儿）。

## 7.2 唯一必须新做的一块：Linux 版 `Microsoft.WindowsDesktop.App`（G2）

编译产物 `runtimeconfig.json` 写死：

```json
{ "runtimeOptions": { "tfm":"net10.0",
  "frameworks":[ {"name":"Microsoft.NETCore.App","version":"10.0.0"},
                 {"name":"Microsoft.WindowsDesktop.App","version":"10.0.0"} ] } }
```

Linux 上直接跑：

```
Framework: 'Microsoft.WindowsDesktop.App', version '10.0.0' (x64)
No frameworks were found.                ← host 在托管代码执行之前就失败
```

SDK 侧的障碍（`Microsoft.NETCoreSdk.BundledVersions.props` 的 `KnownFrameworkReference`）：

```
RuntimeFrameworkName="Microsoft.WindowsDesktop.App"   DefaultRuntimeFrameworkVersion="10.0.0"
TargetingPackName="Microsoft.WindowsDesktop.App.Ref"  TargetingPackVersion="10.0.11"
RuntimePackNamePatterns="Microsoft.WindowsDesktop.App.Runtime.**RID**"
RuntimePackRuntimeIdentifiers="win-x64;win-x86;win-arm64"      ← 没有 linux-*
IsWindowsOnly="true"                                            ← 运行包只认 Windows
```

做法（两条，选一或都做；**Ref 层不用做**）：

```
	路线①  shared framework 目录（运行期零改动，最省用户）
	  <dotnet root>/shared/Microsoft.WindowsDesktop.App/10.0.0.11/
	      ├── 自产 12 件（PresentationFramework/PresentationCore/WindowsBase/System.Xaml/…）
	      ├── Microsoft.WindowsDesktop.App.deps.json      ← 需自造（可仿 NETCore.App 的）
	      ├── Microsoft.WindowsDesktop.App.runtimeconfig.json
	      └── 原生件落点（libwpfwin32.so / libwpfwic.so / wpfgfx_cor3.so / libSkiaSharp.so）
	  ⇒ 应用只装一次框架即可 `dotnet YourApp.dll`；runtimeconfig 不必改
	  ⚠️ 待验：host 对框架目录的清单要求；.so 在框架目录里能否被现有 resolver 搜到

	路线②  自产 runtime pack（`Microsoft.WindowsDesktop.App.Runtime.linux-x64`）+ 注入
	  props 里 `KnownFrameworkReference Update` 把 RuntimePackRuntimeIdentifiers 加上 linux-x64
	  ⇒ 支持 `--self-contained`/发布带 native 资产；工程外注入即可生效
```

**版本号必须与官方对齐**（`10.0.0.x`）：这样连 Windows 侧编出来的 `runtimeconfig.json` 也能直接吃（这就是"替代版 WindowsDesktop.App"的正确形态——**替代的是 runtime，不是 ref**）。

## 7.3 跑 Windows 编的 NuGet 包（G3）：改版本号换一半，覆盖度换不来

- **枢纽是 `AssemblyVersion`**：自产件 `4.0.0.1` < 官方 `8.0.0.0`/`10.0.0.0` ⇒ 默认绑不上（`FileNotFoundException 0x80070002`）。
- **抬到 `10.0.0.0` 是安全的**（实测/读码）：唯一功能性读者是 `build/DirectWrite.Linux/WiringSmoke/fix-deps.py:13`（硬编码 `WindowsBase/4.0.0.1` 的 deps 键，要同步）；核心不变量"自产版本 > 框架门面 `4.0.0.0`"在 `10.0.0.0` 下**仍成立**；`build/Directory.Upstream.props` 的"丢弃同名门面引用"逻辑**仍需要**（它按"同名"触发，与版本数值无关）。
- 影响面：全仓 `4.0.0.1` 命中 **77 个文件 / 114 行**（`.log 41 / .csproj 18 / .md 7 / .py 4 / .cs 4 / .txt 2 / .props 1`），其中判据级读者只有上面那 1 处。
- **令牌**：`System.Xaml` / `System.Windows.Input.Manipulations` 自产 `31bf…`、官方 `b77a…`。实测**令牌不阻塞绑定**（默认 ALC 不按 PKT 过滤），但属未文档化行为 ⇒ 建议改为 `b77a…` 对齐。
- ⚠️ **改完也换不来的那一半**：能"绑上"≠"行为对"。本栈是**子集实现**（Win32/GDI+/ntdll 面"如实失败"、主题只移植 Classic、渲染走 Skia CPU）。第三方库只要摸到没实现的面就报错/降级——这与身份无关，**靠版本号解决不了**。

## 7.4 Linux 编 → Windows 跑（G4）：便宜，但不是"原样搬"

**原样搬产物必崩**（实测复现的码路）：

```
build/shims/Win32ShimResolver.cs:205-206  [ModuleInitializer] Register()
                              :219        AssemblyLoadContext.Default.ResolvingUnmanagedDll += …
                              :239        NativeLibrary.SetDllImportResolver(...)   ← 在默认探测之前拦截
                              :87-115     user32/gdi32/kernel32/… ⇒ libwpfwin32.so
                              :399-403    加载不到 ⇒ throw DllNotFoundException
实测（把该 .cs 原样链进 /tmp 控制台，声明 [DllImport("user32.dll")]）：
  情形1（没有 .so，= Windows 上的形态）: DllNotFoundException
        "WPF-on-Linux: 'user32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库。"
  情形2（把 .so 指出来）              : OK  GetSystemMetrics(0)=1280   ← 证明 user32 确实被劫持
```

⇒ 要让"Linux 编的产物"在 Windows 上跑，三件事：

| # | 做什么 | 量与风险 |
|---|---|---|
| ① | shim 里加**平台短路**（`if (OperatingSystem.IsWindows()) return;`），Windows 上不注册 resolver | **1 行**，但落在 `PresentationCore` 的编译集里 ⇒ 会动九位产物（要按波走） |
| ② | Windows 侧脚本（bat/ps1）：删掉输出目录里的**自产 WPF 件**、写回**标准 `runtimeconfig.json`**（指向 `Microsoft.WindowsDesktop.App`）、同步 `deps.json`（去掉自产件登记） | 脚本 1 个；⚠️ **deps.json 与磁盘必须一致**（只删件不改 deps ⇒ 启动即 `FileNotFoundException`，实测） |
| ③ | API 面审计：产物里若引用了自产件的**扩展面**，Windows（官方件）上会 `TypeLoad`/`MissingMethod` | 自产扩展面：`WindowsBase` **20 个新 public 类型 / 155 新成员**、`PresentationCore` **2 / 40**；其余 6 件**与官方一致**。本仓两个样本**不引用**（实测）⇒ 安全；第三方库需逐库比对（**工具已就位**：`asmmeta pubadd <自产件> <官方 ref 件>`，今天可跑） |

能跑通的原理（不对称绑定，**实测**）：产物里的 `AssemblyRef` 是 `PresentationFramework, Version=4.0.0.1`；Windows 上框架提供 `10.0.0.0` ⇒ **请求低、提供高 = 绑成功**（同规则实测：请求 `System.ObjectModel 4.0.0.0` → 绑到 `10.0.0.0`；请求 `11.0.0.0` → 失败）。
⚠️ 两点如实标注：① "在 Windows 上用**真实现件**绑 4.0.0.1"这一格是**外推**（本机没有官方 Win 运行时包，只有 ref 件；ref 件被选中后报 `BadImageFormatException 0x80131058 "Reference assemblies cannot be loaded for execution"` ⇒ 恰好证明"绑定已匹配，只是 ref 不能执行"）；② "Windows 上框架件优先于 app 目录残留的自产件"是类比实测（用 `System.ObjectModel`），未在 WPF 件上直测。

**必须承认的事实**：替换之后，**Windows 上跑的是官方 WPF，不是本栈实现**。所谓"双向互跑"实际是"一份源码，两边各用各自的原生 WPF"——而不是"一份二进制，两边同一实现"。

## 7.5 建议做到什么程度（推荐分级）

```
	L0（现状）      改 3 处 csproj + 源码重编                      —— 零新工作
	L1（推荐★）     零改动编译 + Linux 原生运行
	                  · 注入 targets/props（工程外）＋ Directory.Build.props（1 个文件）＋ TFM 一行
	                  · 自产 Microsoft.WindowsDesktop.App 的 Linux 运行时（路线① 或 ②）
	                  · 收益：第三方工程"几乎不用改"，标准包引用照常 restore
	L2（可选）      L1 ＋ 身份抬到 10.0.0.0（+ 令牌对齐）
	                  · 收益：Windows 编的**库包**能绑上；成本：1 处判据 + 77 处文字 + 全面回归
	                  · 别期待"行为全兼容"（子集实现不变）
	L3（可选）      L2 ＋ 导出脚本（Windows 端替换 runtime）
	                  · 收益：同一份产物能在 Windows 直接跑（跑的是官方件）
	                  · 成本：shim 1 行短路 ＋ 1 个脚本 ＋ asmmeta 审计
	L4（不建议）    真·二进制兼容（真签名、System.Xaml 令牌、API 全覆盖、双向同一实现）
	                  · 与规格边界（README:4 / PORT-SPEC:13）冲突，且覆盖度是无底洞
```

**建议 = L1**（性价比最高、收益最直接）：把"改三处 + 手工接线"降成"装一次运行时 + 一行 TFM"。想再进一步就先做 **L3 的脚本**（很小），**L2 放在有明确"要跑别人编的库包"需求时再做**，L4 不做。

## 7.6 开工前必须先验证的 5 件事（都是本报告没测到的）

1. 工程外注入能否设 `TargetFramework` / `UseWPF`（`CustomAfterMicrosoftCommonProps` 或环境变量）——**决定"零改动"能不能到 TFM 那一行**。
2. 工程外注入能否加 `PackageReference`（`SkiaSharp` 等）——**决定要不要多一个 `Directory.Build.props`**。
3. shared framework（路线①）的**目录清单要求**：`Microsoft.WindowsDesktop.App.deps.json` 的最小内容、host 是否接受"自造框架"。
4. 原生件（`.so`）在"框架目录 vs app 目录"两种落点下，现有 resolver 的搜索路径够不够（`Win32ShimResolver.cs:520-537`、`MilCoreDllImportResolver.cs:101-151`）。
5. `KnownFrameworkReference Update` 加 `linux-x64` 后，`--self-contained` 发布能否带出 native 资产（路线②）。

## 7.7 这一节的取证边界

- **实测**：§7.1 的零改动编译、注入点可行/不可行、§7.3 的 77 文件/114 行、§7.4 的绑定矩阵与 `Win32ShimResolver` 劫持复现、扩展面计数与两个样本的引用面、两种 runtimeconfig 形态的报错原文。
- **外推（未直测）**：Windows 上用官方实现件绑定 4.0.0.1；Windows 上框架件 vs app-local 残留件的优先权；Windows 上 `.so` 找不到的形态（只复现了对应的码路）。
- **NOINFO**：本机无 `Microsoft.WindowsDesktop.App.Runtime.win-x64`（离线未下载）、无 wine ⇒ "在真 Windows 上端到端跑通"这一格**本机无法取得**，必须在 Windows 机上复验。

## 7.8 可复算命令

```bash
# 零改动编译（Linux 上编 net10.0-windows + UseWPF=true）
dotnet build /tmp/wincompat/exp1/exp1.csproj -c Release        # 期望 EXIT=0，产出 .baml
dotnet exec /tmp/wincompat/exp1/bin/Release/net10.0-windows/exp1.dll
#   → "Framework: 'Microsoft.WindowsDesktop.App' … No frameworks were found."（就是 G2 要补的那块）

# 注入点接管 PBT（工程外）
CustomBeforeMicrosoftCommonTargets=/tmp/x.targets dotnet msbuild <proj> -getProperty:_PresentationBuildTasksAssembly -nologo

# 身份影响面
grep -rn "4\.0\.0\.1" --include=*.py --include=*.sh --include=*.props --include=*.csproj . | grep -v upstream/ | wc -l

# 不对称绑定规则（请求低 → 绑高版本）
#   /tmp/wincompat/probe-e + run_d.sh：请求 System.ObjectModel 4.0.0.0 → 绑到 10.0.0.0 OK

# 扩展 API 面审计（可跑；换官方件前用它查第三方库）
dotnet /tmp/wincompat/asmmeta/bin/Release/net10.0/asmmeta.dll pubadd \
  build/WindowsBase.Linux/bin/Release/WindowsBase.dll \
  ~/.nuget/packages/microsoft.windowsdesktop.app.ref/10.0.11/ref/net10.0/WindowsBase.dll
```

<!-- 本节取证来源：/tmp/wincompat/{D,E}-REPORT.md（编译接入面 / 运行接入面），主控已复核关键格 -->


## 8.（追加 2026-10-02）L1／L2／L3 落地现状（**逐条现取**）

| 级 | 状态 | 现取证据 |
|---|---|---|
| **L1** 零改动编译 + Linux 原生运行（路线①） | ✅ **已落地** | 仓内 `build/third-party/windowsdesktop-app-linux-framework.sh`（`install`／`uninstall`／`verify`，一条命令、整目录可回滚）＋ `WindowsDesktop.App.Linux.props` ＋ `…-e2e.sh`；仓外 `<dotnet root>/shared/Microsoft.WindowsDesktop.App/10.0.11/`（**目录名须 3 段**：`10.0.0.11` 四段 host 不认）。**端到端**：源码重编的 `WpfTextDemo.dll`（`runtimeconfig` 未改、12 件不 app-local）⇒ `dotnet WpfTextDemo.dll` **起窗并渲染**（`colors=3130`，4 个 `.so` **从框架目录**加载）。**反极性**：撤目录 ⇒ 逐字 `No frameworks were found`（`RC=150`）。前置实测三条：目录名 3 段／`deps.json` 的 `assemblyVersion` 必需／框架目录里的 `.so` **现有 resolver 搜不到** ⇒ 只**追加一档**搜索路径（`Win32ShimResolver.cs`／`MilCoreDllImportResolver.cs`，**语义不变、应用目录仍优先**） |
| **L2** 身份抬到 `10.0.0.0` ＋ 令牌对齐 | ⚠️ **已实现但已回退默认**（`git revert` 两笔，见 `cd8e4bc`） | 实现（现仍可查）：`build/shims/LinuxAssemblyIdentity.cs` 抬到 `10.0.0.0`（12 件同源）＋ `build/keys/EcmaPublicKey.snk` ⇒ `System.Xaml`／`System.Windows.Input.Manipulations` 令牌对齐官方 ECMA `b77a5c561934e089`；`fix-deps.py`／`WiringTests.cs` 同趟同步；**库包绑定**（请求 `4.0.0.0/4.0.0.1/8.0.0.0/10.0.0.0`）rc=0、反极性 `FileNotFoundException 0x80070002`。**回退理由（实测）**：hc demo（HandyControl 示例）在 L2 下 **`System.IO.FileNotFoundException: Could not load file or assembly 'System.Xaml, Version=10.0.0.0, …, PublicKeyToken=b77a5c561934e089'`** ⇒ 身份一改，**app-local 全 12 件必须同步换代**，否则即崩；这正是 §7.5 记的「**成本：1 处判据 + 77 处文字 + 全面回归**」 |
| **L3** 导出脚本（Windows 端替换 runtime） | ✅ **已落地** | shim **1 行短路**（`build/shims/Win32ShimResolver.cs:228-229`：`if (OperatingSystem.IsWindows()) return;` ⇒ Windows 上交回**官方件**；Linux 正极性 4/4 `REAL_DLLIMPORT=OK`，替 true 则 `DllNotFoundException 'user32.dll'`）＋ `build/third-party/windowsdesktop-app-win-export.ps1`（`install`／`uninstall`／`verify`，回滚后 `diff -r` 逐字节相同）＋ asmmeta 审计（`WindowsBase 20/155`、`PresentationCore 2/40`、`PresentationFramework 0/2`、其余 8 件 `0/0`、`DirectWriteForwarder=NOINFO`） |

**结论**：**L1 与 L3 已落地并入仓**；**L2 属"能开但代价高"**——其收益是绑 Windows 编的库包，代价是**全 app-local 同步换代 + 全面回归**，实测会**打破 hc demo**，故**默认保持 `4.0.0.1`**，L2 的键与改法留档（`build/keys/EcmaPublicKey.snk`、报告 `P1-wininteropL2-impl-report.md`），**待有明确"跑别人编的库包"需求时再启**（§7.5 原有建议即如此）。

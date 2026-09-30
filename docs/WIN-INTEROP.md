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

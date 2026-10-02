# P1-wininteropL2-impl 报告 —— `WIN-INTEROP.md` §7.5 **L2**：身份抬到 `10.0.0.0` ＋ 令牌对齐（实现）

> 任务：`build/MilBridge/tasks-tail2/T-B5.md`（实现子代理；本轮唯一写者）。
> 读时：2026-10-02。口径：**本文所有数字都是现场读数**；命令与输出逐条给出，可复算。
> 规格源：`/home/links-dev/netTest/GitProj/WIN-INTEROP.md` §7.3 / §7.5（并复核 §7.2 的 L1 落地）。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **身份源**（单一声明） | `build/shims/LinuxAssemblyIdentity.cs`：`AssemblyVersion/FileVersion/InformationalVersion` = **`10.0.0.0`**（改前 `4.0.0.1`） |
| **唯一功能性读者**（同趟同步） | `build/DirectWrite.Linux/WiringSmoke/fix-deps.py:13`：deps 键 `WindowsBase/4.0.0.1` → **`WindowsBase/10.0.0.0`** |
| **令牌对齐** | `System.Xaml` / `System.Windows.Input.Manipulations` 由 WCP 密钥改签 **ECMA 密钥** ⇒ 令牌 `31bf…` → **`b77a5c561934e089`**（与官方逐件相同） |
| **不变量①：自产版本 > 框架门面 `4.0.0.0`** | ✅ 仍成立（`10.0.0.0 > 4.0.0.0`；门面现取见 §4.1） |
| **不变量②：`Directory.Upstream.props` 的「丢弃同名门面引用」仍需** | ✅ 仍需要且仍触发（按**同名**，与数值无关；现取见 §4.2） |
| **影响面**（任务 grep：`py/sh/props/csproj`） | **37 行 / 26 件 → 11 行 / 6 件**；余下 6 件逐件处置见 §1 |
| **库包绑定**（正极性） | ✅ 请求 `10.0.0.0`（Windows 编的库包）**绑上**自产 `10.0.0.0`；`4.0.0.0/4.0.0.1/8.0.0.0` 亦绑上 |
| **反极性**（回 `4.0.0.1`） | ✅ 请求 `8.0.0.0/10.0.0.0` ⇒ **`FileNotFoundException 0x80070002`**（逐字复现） |
| **L1 e2e 回归** | ✅ 框架目录 `verify` **25/25**；`dotnet WpfTextDemo.dll` 起窗渲染（`colors=3130`） |
| **两牙** | `DEFREG=PASS`（rc=0）／`REPORTID=PASS`（rc=0）；`APPLIER_AUDIT` rc=0；`ARTIFACT_SRC_FP` 三件 `state=ok` |
| **暴露出的既有缺口（如实登记）** | 生成/手写 csproj 里若干 **HintPath 写死 `bin/Debug`** 的引导引用；L2 换身份后它们与 `Release` 权威件**身份错位**（详见 §7） |

**一句话**：自产 12 件的 `AssemblyVersion` 从 `4.0.0.1` 抬到官方对齐的 `10.0.0.0`、`System.Xaml`/`Manipulations`
的令牌改签成官方的 ECMA 令牌后，**在 Windows 上按官方身份编出来的库包（`AssemblyRef` 请求 `10.0.0.0`）
现在真的绑得上本栈自产件**；L1 的「源码重编 → 共享框架 → `dotnet YourApp.dll`」那条链**一字未退**。
不改的那一半（行为覆盖）照旧：能绑上 ≠ 行为对（§7.3 原文）。

---

## §1 影响面（`grep` 计数前后 ＋ 逐件处置）

### §1.1 任务口径（`--include=*.py --include=*.sh --include=*.props --include=*.csproj`，排除 `upstream/`）

```bash
grep -rn "4\.0\.0\.1" --include=*.py --include=*.sh --include=*.props --include=*.csproj . | grep -v upstream/ | wc -l
# 改前 = 37 行（26 件）        改后 = 11 行（6 件）
grep -rl "4\.0\.0\.1" --include=*.py --include=*.sh --include=*.props --include=*.csproj . | grep -v upstream/ | wc -l
# 改前 = 26 件                改后 = 6 件
```

（`WIN-INTEROP.md` §7.3 当时记的口径更宽 —— 含 `.log/.md/.cs/.txt`，合 77 件 / 114 行；那是**取证当时**的读数，
本轮的射程按任务给的四类扩展名。全仓口径见 §1.3。）

### §1.2 改前 37 行逐件处置

**A. 功能/判据级（必须同趟改，改了）—— 2 件**

| 件 | 角色 | 处置 |
|---|---|---|
| `build/DirectWrite.Linux/WiringSmoke/fix-deps.py:13` | **唯一功能性读者**（硬编码 deps 键 `WindowsBase/4.0.0.1`；不改则宿主按旧键找件） | 键改 `WindowsBase/10.0.0.0`；文件头背景注释同步（§2.2 现取） |
| `build/DirectWrite.Linux/Tests/WiringTests.cs:98` | **测试断言**（`ASSEMBLY` 冒烟输出以 `DirectWriteForwarder 4.0.0.1` 开头）；`DirectWriteForwarder` 带身份 shim ⇒ 必失效 | 断言改 `DirectWriteForwarder 10.0.0.0`（§2.3 冒烟现取） |

> 任务 ① 只点了 `fix-deps.py` 一处；本波另发现 `WiringTests.cs:98` 这一条**同族判据级读者**（测试断言），
> 同趟修。**这两处之外无第三条功能读者**（全仓 `.cs` 里除注释外无其它按该版本串判定的代码，§1.3 复核）。

**B. 身份声明/注释（改了，保持自述准确）—— 21 件**

| 类 | 件（改前命中） | 处置 |
|---|---|---|
| 身份源 | `build/shims/LinuxAssemblyIdentity.cs`（3 行） | `4.0.0.1` → `10.0.0.0`；头注补 L2 动因 |
| 生成器 | `build/port-lib.py`（1 行） | 生成注释同步；并加「按工程选密钥」（§3.2） |
| 2 个改签工程 csproj | `System.Xaml.Linux.csproj`、`System.Windows.Input.Manipulations.Linux.csproj` | 身份注释同步；`AssemblyOriginatorKeyFile` 改 `EcmaPublicKey.snk`（§3.2） |
| 其余生成 csproj 的身份注释 | `WindowsBase` / `PresentationCore` / `PresentationFramework` / `ReachFramework` / `System.Printing` / `UIAutomationProvider` / `UIAutomationTypes` / `PresentationFramework.Classic` | 注释值 `4.0.0.1` → `10.0.0.0`（与 `port-lib.py` 的输出**逐字同形**） |
| CycleStub 说明注释 | `CycleStub.PresentationFramework` / `PresentationUI` / `ReachFramework` 的 csproj | 同上 |
| shim/骨架说明注释 | `build/shims/PresentationCore.AssemblyAttrs.cs:18`、`build/DirectWriteForwarder.Linux/AssemblyAttrs.cs:9`、`DirectWriteForwarder.Linux.csproj:54,81` | 引用值同步 |
| 应用器 docstring | `build/PresentationCore.Linux/reapply-patches.py:52` | 引用值同步 |
| **L1 交付物注释** | `build/third-party/WindowsDesktop.App.Linux.props`（2 行）、`windowsdesktop-app-linux-framework.sh`（2 行）、`windowsdesktop-app-linux-framework-e2e.sh`（2 行） | 编译身份 `4.0.0.1` → `10.0.0.0`（L1 交付物自述现状） |
| 测试工程注释 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj:28` | 同上 |

**C. 历史/证据/错误原文（不改，留档） —— 改后仍在的 6 件（11 行）**

| 件:行 | 为什么留 |
|---|---|
| `build/Directory.Upstream.props:163,164,166,170` | M3 实测**历史实验**记录（`-p:AssemblyVersion=4.0.0.1` 的复现命令）与"建议 4.0.0.1 或更高"——`10.0.0.0` 仍满足该建议，改成 `10.0.0.0` 反会把历史命令改错 |
| `build/DirectWrite.Linux/SystemFontsProbe/...csproj:58`、`WiringSmoke/...csproj:14` | 描述**当年**身份错位现象的历史注释 |
| `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj:1484`、`reapply-patches.py:63` | **逐字引用的旧报错原文**（`友元访问权限由"WindowsBase, Version=4.0.0.1…"授予`）——改它等于篡改证据 |
| `samples/HelloWpf/HelloWpf.csproj:89,117,238` | 同样是旧报错原文 + 历史结论 |

### §1.3 全仓口径（含 `.log/.md/.cs/.txt/.json`；排除 `upstream/`、`.git/`）

```bash
grep -rIn "4\.0\.0\.1" . | grep -v '/upstream/' | grep -v '/\.git/'
# 改前 = 132 件 / 1834 行        改后 = 97 件 / 1551 行
```

改后剩余按扩展：`.log` 41 件/42 行（历史证据日志）、`.json` 38 件/1450 行（**生成物** `bin/**/*.deps.json`，
由各工程重建时重写）、`.md` 9 件/42 行（`docs/WIN-INTEROP.md` 与历史报告——**取证留档**）、
`.csproj/.py/.cs/.txt/.props` 合计 6 件/11 行（= §1.2-C 那张表）。
**无第三条功能读者**：改后 `*.cs` 里不含任何按该版本串做判断的**可执行**代码（余下命中都在注释里）。

---

## §2 身份抬升（`4.0.0.1` → `10.0.0.0`）

### §2.1 单一来源（改的就是这一处）

`build/shims/LinuxAssemblyIdentity.cs`（全项目共用 shim，被 `port-lib.py` 自动注入每个移植工程）：

```csharp
[assembly: AssemblyVersion("10.0.0.0")]
[assembly: AssemblyFileVersion("10.0.0.0")]
[assembly: AssemblyInformationalVersion("10.0.0.0-wpf-linux")]
```

改这条即改全栈 12 件的身份（`GenerateAssemblyInfo=false` 下唯一声明处）。

### §2.2 唯一功能性读者同步现取

```bash
$ python3 build/DirectWrite.Linux/WiringSmoke/fix-deps.py <deps.json 副本>
[SKIP] WindowsBase/10.0.0.0 已在 deps.json 里
$ grep -o '"WindowsBase/[0-9.]*"' <deps.json> | sort -u
"WindowsBase/10.0.0.0"
```

### §2.3 测试断言同步现取（冒烟真跑）

```bash
$ cd build/DirectWrite.Linux/WiringSmoke/bin/Debug
$ dotnet DirectWrite.Linux.WiringSmoke.dll --font-dir <repo>/build/fonts | grep '^ASSEMBLY='
ASSEMBLY=DirectWriteForwarder 10.0.0.0        # ← WiringTests 的 Assert.StartsWith 现在对得上
```

### §2.4 12 件逐件现取（权威源 `bin/Release`；sha16 / 字节 / 身份）

| # | 件 | 字节 | sha16（**改后**） | sha16（改前，留档） | 身份（现取） |
|---|---|---|---|---|---|
| 1 | `WindowsBase.dll` | 1112064 | **`6b8fceaf70d4a71d`** | `fcdb44f8dd0470f9` | `10.0.0.0 / 31bf3856ad364e35` |
| 2 | `System.Xaml.dll` | 614400 | **`43424428b860cd8d`** | `50c037fe785d0a7f` | `10.0.0.0 / b77a5c561934e089` |
| 3 | `PresentationCore.dll` | 3603456 | **`7d680fade8d665e6`** | `9e703ef212752aed` | `10.0.0.0 / 31bf3856ad364e35` |
| 4 | `PresentationFramework.dll` | 6159872 | **`a708ae46f59317aa`** | `a48504540c296366` | `10.0.0.0 / 31bf3856ad364e35` |
| 5 | `PresentationFramework.Classic.dll` | 179712 | **`58cb7cfb232610e3`** | `b5cfe401e1f53565` | `10.0.0.0 / 31bf3856ad364e35` |
| 6 | `PresentationUI.dll` | 7168 | **`94702615e29e0f63`** | `56308571f810f50c` | `10.0.0.0 / 31bf3856ad364e35` |
| 7 | `ReachFramework.dll` | 5120 | **`2181e8d02a2d84c8`** | `72081d50d65c0f04` | `10.0.0.0 / 31bf3856ad364e35` |
| 8 | `System.Printing.dll` | 48640 | **`704d6c5f65e1fcce`** | `5cecbe296dea70e7` | `10.0.0.0 / 31bf3856ad364e35` |
| 9 | `System.Windows.Input.Manipulations.dll` | 53248 | **`78ac68ad0ddde028`** | `4038a9e74c46de58` | `10.0.0.0 / b77a5c561934e089` |
| 10 | `UIAutomationTypes.dll` | 223744 | **`f3f0fb8302e73349`** | `130f8f2881b0d9c0` | `10.0.0.0 / 31bf3856ad364e35` |
| 11 | `UIAutomationProvider.dll` | 42496 | **`0a710c5b21f4ad9e`** | `1481c919abbd4816` | `10.0.0.0 / 31bf3856ad364e35` |
| 12 | `DirectWriteForwarder.dll` | 39936 | **`0b66bb775c7037d8`** | `11b983efa4c8a09d` | `10.0.0.0 / 31bf3856ad364e35` |

> 上表 12 件与「装进框架目录的 12 件」**逐字节相同**（`verify` 25/25，§6）。非 12 件的真 `ReachFramework.Linux`（自举件）
> 亦已重建为 `10.0.0.0`（`sha16=…`，见 §2.5 说明）。

### §2.5 重建面（哪些件重编了）

```
Release（权威）：System.Xaml → WindowsBase → DirectWriteForwarder → UIAutomationTypes →
                 System.Windows.Input.Manipulations → UIAutomationProvider → PresentationCore →
                 System.Printing → CycleStub.PresentationFramework → CycleStub.ReachFramework →
                 CycleStub.PresentationUI → PresentationFramework → PresentationFramework.Classic →
                 ReachFramework（自举件；见 §7）
Debug（供 csproj 里若干 `bin/Debug` 引导引用；见 §7）：同一串（ReachFramework 放最后）
```
全部 **0 错 0 警**（每个工程逐一现取）。

---

## §3 令牌对齐（按官方件）

### §3.1 官方对照（本机 ref pack `Microsoft.WindowsDesktop.App.Ref 10.0.11`，逐件现读）

```bash
$ dotnet /tmp/pkprobe/bin/Release/net10.0/pkprobe.dll <ref>/System.Xaml.dll <ref>/System.Windows.Input.Manipulations.dll <ref>/WindowsBase.dll
System.Xaml.dll                        len=16   hex=00000000000000000400000000000000  PKT=b77a5c561934e089  Ver=10.0.0.0
System.Windows.Input.Manipulations.dll len=16   hex=00000000000000000400000000000000  PKT=b77a5c561934e089  Ver=10.0.0.0
WindowsBase.dll                        len=160  hex=00240000…08055da9                  PKT=31bf3856ad364e35  Ver=10.0.0.0
```
⇒ 官方**只有** `System.Xaml` / `System.Windows.Input.Manipulations` 用**16 字节 ECMA 公钥**（令牌 `b77a5c561934e089`）；
其余 8 件用 160 字节 WCP 公钥（令牌 `31bf3856ad364e35`）。

### §3.2 自产改签（**仅这 2 件**；其余不动）

- 新增 `build/keys/EcmaPublicKey.snk`（16 字节 `00000000000000000400000000000000`，纯公钥、非机密）；
  `ident --snk` 现取令牌 = **`b77a5c561934e089`**。
- `port-lib.py` 加一条「按工程选密钥」：`{System.Xaml, System.Windows.Input.Manipulations}` → `EcmaPublicKey.snk`，其余 → `WcpPublicKey.snk`
  （⇒ 未来 port-lib 重生成这两件时**自动保持**新令牌，不需再手改）。
- 两个生成 csproj 的 `AssemblyOriginatorKeyFile` 同趟改指 `EcmaPublicKey.snk`。
- 编译验证（一次小工程试签）：`PublicSign=true` 吃 16 字节 ECMA 公钥**成立**（产出件 `PublicKey` = 那 16 字节）。

### §3.3 令牌对拍（官方 vs 自产，改前/改后）

| 件 | 官方 ref | 自产 **改前** | 自产 **改后** |
|---|---|---|---|
| `System.Xaml.dll` | `10.0.0.0 / b77a5c561934e089` | `4.0.0.1 / 31bf3856ad364e35` | **`10.0.0.0 / b77a5c561934e089`** ✅ |
| `System.Windows.Input.Manipulations.dll` | `10.0.0.0 / b77a5c561934e089` | `4.0.0.1 / 31bf3856ad364e35` | **`10.0.0.0 / b77a5c561934e089`** ✅ |
| （其余 7 件抽查：`WindowsBase`/`PresentationCore`/`PresentationFramework`/`PresentationFramework.Classic`/`System.Printing`/`UIAutomationTypes`/`UIAutomationProvider`） | `10.0.0.0 / 31bf3856ad364e35` | `4.0.0.1 / 31bf3856ad364e35` | `10.0.0.0 / 31bf3856ad364e35`（不变） |

### §3.4 为什么改签是安全的（读码复核）

- 全上游**没有任何** `InternalsVisibleTo` 指向 `System.Xaml`（唯一列表：`PresentationCore` / `ReachFramework` /
  `System.Printing` / 三个 `.Tests`）⇒ 换令牌不影响任何 IVT 授权。
- `System.Xaml` 自身 `OtherAssemblyAttrs.cs` 只 `TypeForwardedTo` + `Dependency`，无 `InternalsVisibleTo`。
- `.NET Core` 运行期**不验签**（`PublicSign` 只满足身份匹配）；默认 ALC 不按 PKT 过滤（§1.2 闸③）。

---

## §4 不变量复核（逐条现取）

### §4.1 不变量① ·「自产版本 > 框架门面 `4.0.0.0`」在 `10.0.0.0` 下仍成立

```bash
$ dotnet …/ident.dll ~/.dotnet/shared/Microsoft.NETCore.App/10.0.11/WindowsBase.dll
WindowsBase.dll  …  Ver=4.0.0.0          # ← 框架空门面
$ dotnet …/ident.dll ~/.dotnet/shared/Microsoft.WindowsDesktop.App/10.0.11/WindowsBase.dll
WindowsBase.dll  …  Ver=10.0.0.0         # ← 自产
```
`10.0.0.0 > 4.0.0.0` ⇒ 编译期 `ResolvePackageFileConflicts`（版本高者胜）与运行期绑定**照旧选自产件**。

### §4.2 不变量② ·「丢弃同名门面引用」仍需要（按同名触发，与数值无关）

`build/Directory.Upstream.props:49` 的 `WpfLinuxDropShadowedReferenceAssemblies`（`BeforeTargets="_HandlePackageFileConflicts"`）
判据是**文件名相同**（`%(RefFileDll)` 字符串包含比较），**不含任何版本数值**。实测它**仍在触发**（重建 UIAutomationTypes 抓 `normal` 消息）：

```
  WpfLinux: 已移除被本地引用遮蔽的 .NET 基础类库门面 → WindowsBase.dll
  WpfLinux: 已把被框架门面遮蔽的本地程序集放回 copy-local → WindowsBase.dll
```
⇒ 逻辑与 `10.0.0.0` 无耦合，**照旧需要且照旧成立**。

---

## §5 库包绑定（正 / 反极性）

**装置**（仓外 `/tmp/tb5-probe/`）：
- `LibConsumer` = **「Windows 上编出来的库包」形态**：`net10.0-windows` + `UseWPF=true`，只引官方 ref pack ⇒
  其 `AssemblyRef` 现取 `PresentationFramework, Version=10.0.0.0, Culture=neutral, PKT=31bf3856ad364e35`。
- `Probe` = 消费例宿主：`net10.0-windows`，`FrameworkReference Microsoft.WindowsDesktop.App`，不引任何自产件
  （只 `Assembly.Load` 与 `Assembly.LoadFrom` 观察**绑定**）。

### §5.1 正极性（L2 态：自产 `10.0.0.0`）

```bash
$ dotnet Probe.dll LibConsumer.dll
LOAD OK   req=PresentationFramework,4.0.0.0,PKT=31bf… -> got=10.0.0.0 loc=…/Microsoft.WindowsDesktop.App/10.0.11/PresentationFramework.dll
LOAD OK   req=PresentationFramework,4.0.0.1,PKT=31bf… -> got=10.0.0.0 …
LOAD OK   req=PresentationFramework,8.0.0.0,PKT=31bf… -> got=10.0.0.0 …
LOAD OK   req=PresentationFramework,10.0.0.0,PKT=31bf… -> got=10.0.0.0 …
LOAD OK   req=System.Xaml,10.0.0.0,PKT=b77a… -> got=10.0.0.0 PKT=b77a5c561934e089 …
LOAD OK   req=System.Windows.Input.Manipulations,10.0.0.0,PKT=b77a… -> got=10.0.0.0 PKT=b77a5c561934e089 …
LIBCONSUMER OK   PresentationFramework, Version=10.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35
RC=0
```
即：**请求低版本（`4.0.0.0` / `4.0.0.1`）与本栈原请求、以及 Windows 编的库包请求（`8.0.0.0` / `10.0.0.0`）
全部绑上**；`System.Xaml` / `Manipulations` 连**官方 ECMA 令牌**也对得上。

### §5.2 反极性（撤到 `4.0.0.1` ⇒ 库包绑定失败形态复现）

装置：影子 dotnet 根 `/tmp/tb5-polarity/sbx`（`host/fxr` 与 `Microsoft.NETCore.App` 软链真根，只把 WindowsDesktop.App
换成**改前真实件**（`/tmp/tb5-bak/bin-release/`，逐件 `AssemblyVersion=4.0.0.1`，deps.json 同步回 `4.0.0.1`））。

```bash
$ DOTNET_ROOT=/tmp/tb5-polarity/sbx /tmp/tb5-polarity/sbx/dotnet Probe.dll LibConsumer.dll
LOAD OK   req=PresentationFramework,4.0.0.0,PKT=31bf… -> got=4.0.0.1 …
LOAD OK   req=PresentationFramework,4.0.0.1,PKT=31bf… -> got=4.0.0.1 …
LOAD FAIL req=PresentationFramework,8.0.0.0,PKT=31bf… -> FileNotFoundException hresult=0x80070002 msg=Could not load file or assembly 'PresentationFramework, Version=8.0.0.0, …'
LOAD FAIL req=PresentationFramework,10.0.0.0,PKT=31bf… -> FileNotFoundException hresult=0x80070002 msg=… 'PresentationFramework, Version=10.0.0.0, …'
LOAD FAIL req=System.Xaml,10.0.0.0,PKT=b77a…        -> FileNotFoundException hresult=0x80070002 msg=… 'System.Xaml, Version=10.0.0.0, … PublicKeyToken=b77a5c561934e089'
LOAD FAIL req=System.Windows.Input.Manipulations,10.0.0.0,PKT=b77a… -> FileNotFoundException hresult=0x80070002 …
LIBCONSUMER FAIL -> FileNotFoundException hresult=0x80070002 msg=Could not load file or assembly 'PresentationFramework, Version=10.0.0.0, …'
RC=1
```
⇒ **反极性逐字复现** `FileNotFoundException 0x80070002`（与 `WIN-INTEROP.md` §7.3 记的形态**同形**）。

---

## §6 L1 e2e 回归（框架目录 `verify` ＋ `dotnet WpfTextDemo.dll`）

```bash
$ bash build/third-party/windowsdesktop-app-linux-framework.sh verify
VERIFY=PASS (25/25 与权威件逐字节相同)

$ bash ~/heavy-slot.sh --min-avail 2500 --max-hold 900 --wait 1800 -- \
    bash build/third-party/windowsdesktop-app-linux-framework-e2e.sh --display :233
== 1) 构建（net10.0-windows + 自产件编译面 + WindowsDesktop 框架声明）==
  WpfTextDemo -> /tmp/wpfwd-e2e-*/wtd/bin/Release/net10.0-windows/WpfTextDemo.dll   已成功生成。
== 2) 产物读数 ==
runtimeconfig.frameworks = ['Microsoft.NETCore.App', 'Microsoft.WindowsDesktop.App']
app-local dll            = ['DirectWrite.Linux.Provider.dll', 'SkiaSharp.dll', 'WpfTextDemo.dll']
框架件是否 app-local     = False
-- AssemblyRef（自产身份）--
System.Xaml, Version=10.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089
WindowsBase, Version=10.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35
PresentationCore, Version=10.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35
PresentationFramework, Version=10.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35
== 3) 跑（DISPLAY=:233）==
ALIVE=yes    window: 938x938 colors=3130
WPTD_SCROLL_RANGE=extent=926.4 viewport=717.1 scrollable=209.2 bar=Visible offset=0.0
-- .so 落点（/proc/<pid>/maps）--  （4 个 .so 全从框架目录加载）
/home/links-dev/.dotnet/shared/Microsoft.WindowsDesktop.App/10.0.11/{libSkiaSharp,libwpfwic,libwpfwin32,wpfgfx_cor3}.so
KILL=ok（按 PID）      HEAVYSLOT=RELEASED rc=0
```

框架目录 `deps.json` 里 12 件的 `assemblyVersion` **全部现读为 `10.0.0.0`**（脚本从 CLI 元数据现读，不写死），
9 件 BCL 闭包仍 `9.0.0.0`（不变）。

---

## §7 如实登记：L2 换身份**暴露出**的一处既有缺口（生成 csproj 的 `bin/Debug` 引导引用）

**现象（实测）**：改身份的**第一趟**重建在 `ReachFramework.Linux` 报 4 条：

```
NGCSerializerAsync.cs(1296,44): error CS0012: 类型"IQueryAmbient"在未引用的程序集中定义。
  必须添加对程序集"System.Xaml, Version=4.0.0.1, …, PublicKeyToken=31bf3856ad364e35"的引用。
```

**根因（读码 ＋ 现取）**：若干**生成/手写** csproj 的引导引用 **HintPath 写死 `bin/Debug/`**：

| 件 | 引用 | 位置 |
|---|---|---|
| `build/ReachFramework.Linux/…csproj` / `reapply-patches.py` | PF / CycleStub.PF / System.Printing / PC-bin-DWF | `:395,398,401,408` |
| `build/PresentationCore.Linux/…csproj` / `reapply-patches.py` | DirectWriteForwarder / Provider | `:1549-1568` |
| `build/PresentationFramework.Classic.Linux/…csproj` | System.Xaml / WindowsBase / PC / PF / PresentationUI | `:27-30,67-68` |

`SelfBuiltConfig.props` 的**唯一声明**是 **`Release`** ⇒ 这些 `bin/Debug` 件是**换配置前的遗留**。
它们在「Debug/Release 身份相同」时**看不出来**（两边都是 `4.0.0.1/31bf` ⇒ 编译器可合一），
L2 把身份分开后才暴露（`Debug=4.0.0.1` vs `Release=10.0.0.0` ⇒ `CS0012`）。

**本波处置（模式守恒，不动引导逻辑）**：按既有形态**把被引的 `Debug` 件也重建**（`bin/Debug` 与 `bin/Release`
身份一致），引导逻辑一个字没改。⇒ `ReachFramework.Linux` 恢复 0 错 0 警（§2.5）。

**如实标注（留给主控定夺，本波不裁）**：这些 `bin/Debug` 写死属**既有**缺口（“权威配置已切 Release 而引导引用仍指 Debug”），
与 L2 无关但被 L2 放大。可选的两条收口路：① 把这几处改成 `$(Configuration)`（与权威声明对齐）；
② 每波同时重建 Debug（本波用的）。**本报告不作裁决。**

---

## §8 两牙与仪器（rc 现取）

```bash
$ bash build/MilBridge/tools/defect-registry-check.sh | tail -1
DEFREG=PASS declared=225 route_ids=225（…）                         # rc=0
$ bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
REPORTID=PASS files=353 ids=2265 declared=225 glob=build/MilBridge/*report*.md   # rc=0
$ python3 build/MilBridge/tools/applier-audit.py | tail -1
APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0           # rc=0
$ python3 build/artifact-src-fp.py --check | tail -3
ARTIFACT_SRC_FP proj=PresentationCore      … state=ok
ARTIFACT_SRC_FP proj=WindowsBase           … state=ok
ARTIFACT_SRC_FP proj=PresentationFramework … state=ok
```
（换身份改了 `port-lib.py` + `shims/LinuxAssemblyIdentity.cs` ⇒ 三件 `ARTIFACT-SRC-FP.txt` 已按波规矩 `--write` 刷新。）
**未跑整趟 `verify-all`**（任务边界）；未动 `upstream/**`、`verify-all.sh`、`build/close-wave.sh`、`build/MilBridge/tools/**`。

---

## §9 具名 NOINFO / 待裁决

1. **`NOINFO(reason=真 Windows 端到端本机不可得)`**：本机无 `Microsoft.WindowsDesktop.App.Runtime.win-x64`、无 wine
   ⇒「在真 Windows 上跑通本栈库包/产物」这一格**本机无法取得**（与 `WIN-INTEROP.md` §7.7 同）。
   本报告的「库包绑定」是**在 Linux 共享框架上**用「官方身份库包形态」复现的（`AssemblyRef` 逐字等于 Windows 侧形态）。
2. **待裁决 · `bin/Debug` 引导引用**（§7）：本波按"重建 Debug"处置；是否改成 `$(Configuration)` 由主控定。
3. **待裁决 · `WIN-INTEROP.md` §5 的两条**：第 1 条（`System.Xaml`/`Manipulations` 令牌）**本波已对齐**；
   第 2 条（版本固定 `4.0.0.1` 的兼容性代价）**本波已消除**（抬到 `10.0.0.0`）⇒ 建议同趟把 §5 与 §7.3/§7.5 的
   "改前现状"语气改成"已完成"，并把 §2.3 身份对照表里的 `4.0.0.1` 更新为 `10.0.0.0`（本报告不改规格，留档）。
4. **`NOINFO(reason=DirectWrite.Linux.Tests 套件本身编译不过)`**：该套件（`build/DirectWrite.Linux/Tests/`）
   在**改前**就因 `src/WpfGfx.Linux/Text/FontSet.cs` 引用 `WpfGfx.Linux.Interop` 而该工程未纳入 `Interop/` 源文件
   ⇒ `CS0234`（与本轮无关；`verify-all` 也不跑它）。故 §2.3 的断言改用**直接跑冒烟**验证。

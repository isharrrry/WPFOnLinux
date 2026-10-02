# P1-wininteropL1-impl 报告 —— `WIN-INTEROP.md` §7.5 **L1 路线①**：Linux 版 `Microsoft.WindowsDesktop.App` shared framework（实现）

> 任务：`build/MilBridge/tasks-tail2/T-B2.md`（实现子代理；本轮唯一写者）。
> 读时：2026-10-02。口径：**本文所有数字都是现场读数**；命令与输出逐条给出，可复算。
> 规格源：`/home/links-dev/netTest/GitProj/WIN-INTEROP.md` §7.1 / §7.2 / §7.5 / §7.6。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **交付物①** 安装／卸载脚本（一条命令、整目录可回滚） | `build/third-party/windowsdesktop-app-linux-framework.sh`（install / uninstall / verify） |
| **交付物②** 接入形态 props（`net10.0-windows` 工程：runtimeconfig 带 `Microsoft.WindowsDesktop.App`，编译面用自产件） | `build/third-party/WindowsDesktop.App.Linux.props` |
| **交付物③** 端到端复现脚本 | `build/third-party/windowsdesktop-app-linux-framework-e2e.sh` |
| **交付物④** 仓外框架目录（新增） | `<dotnet root>/shared/Microsoft.WindowsDesktop.App/10.0.11/`（25 件 + 2 个自造清单） |
| **交付物⑤** 搜索路径（只加一档，语义不变） | `build/shims/Win32ShimResolver.cs:502-511` ＋ `build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs:130-148`（＋ 4 位重建） |
| **端到端**（源码重编的 WPF 应用、**未改 runtimeconfig**） | ✅ `dotnet WpfTextDemo.dll` 起窗并渲染（`colors=3130`、`WPTD_SCROLL_*` 真读数）；4 个 `.so` **从框架目录**加载 |
| **反极性**（撤框架目录） | ✅ 逐字复现 `Framework: 'Microsoft.WindowsDesktop.App' … No frameworks were found.`，`RC=150` |
| **逐件在位** | ✅ 12 托管件 ＋ 4 原生件（点名，见 §5）＋ **9 件运行期 BCL 闭包**（§5.3 说明为什么必须有） |

**一句话**：Linux 上现在真的有一个能被 host 认下来的 `Microsoft.WindowsDesktop.App` 共享框架目录；
装一次，`net10.0-windows`（零改动编译形态，§7.1）编出来的应用就能 `dotnet YourApp.dll`，
**runtimeconfig 一个字不用改**。前提是产物的 `AssemblyRef` 是**自产身份**（`4.0.0.1`）——
这一条是 L1 与 L2 的分界（见 §8 待裁决 1）。

---

## §1 前置三条（§7.6 的前置验证，逐条现取）

### §1.1 前置① · host 对框架目录的**清单要求**（实测）

**实验装置**（不碰真实 dotnet root）：把 host 的"根"做成影子根
`/tmp/wpfwsd/sbx`（复制 muxer ＋ 软链 `host/fxr`、`shared/Microsoft.NETCore.App`），
只对 `shared/Microsoft.WindowsDesktop.App/` 做真实副本 ⇒ 每一步都可整目录回滚。

测试应用用 §7.1 的原件 `/tmp/wincompat/exp1`（`runtimeconfig.json` 声明
`Microsoft.NETCore.App 10.0.0` ＋ `Microsoft.WindowsDesktop.App 10.0.0`）。

**读数 1（目录名版本：4 段不认）** —— `Microsoft.WindowsDesktop.App/<VER>/` 的 `<VER>` 矩阵：

| `<VER>` | 结果 |
|---|---|
| `10.0.11` | **host 认**（roll-forward：请求 `10.0.0` → 命中 `10.0.11`） |
| `10.0.0` | **host 认**（精确命中） |
| `10.0.0.11` | **host 不认** → `No frameworks were found.` |
| `10.0.0.0` | **host 不认** → `No frameworks were found.` |

复算：

```bash
SBX=/tmp/wpfwsd/sbx; FW=$SBX/shared/Microsoft.WindowsDesktop.App
cd /tmp/wincompat/exp1
for d in 10.0.11 10.0.0.11 10.0.0 10.0.0.0; do
  rm -rf $FW; mkdir -p $FW/$d
  cp /tmp/wpfwsd/fw-base/*.json $FW/$d/     # 最小 runtimeconfig.json + 最小 deps.json
  echo "### $d"; DOTNET_ROOT=$SBX $SBX/dotnet bin/Release/net10.0-windows/exp1.dll 2>&1 | head -3
done
```

⚠️ **与 `WIN-INTEROP.md` §7.2 的字面不一致**：§7.2 路线① 示例写的是 `<与官方对齐的 10.0.0.x>/`
（如 `10.0.0.11`）。**实测 4 段目录名 host 不认**。本实现取 **`10.0.11`**（3 段，与官方
`Microsoft.WindowsDesktop.App.Runtime` 10.0.11 / SDK 10.0.111 / `Microsoft.NETCore.App` 10.0.11 对齐），
它同时满足"请求 `10.0.0`"与"请求 `10.0.11`"。⇒ **版本号与官方对齐这件事，判据是"请求 ≤ 目录"，
不是"目录写成 4 段"。**

**读数 2（清单文件：两个都必需）**：

| 目录内容 | 结果 |
|---|---|
| 空目录 | `No frameworks were found.` |
| 只有 `*.runtimeconfig.json` | `No frameworks were found.` |
| 只有 `*.deps.json` | `No frameworks were found.` |
| 两个都有 | **框架被认下**（host 开始解析框架 TPA；没有件时就报 `FileNotFoundException`） |

⇒ **最小清单 = `Microsoft.WindowsDesktop.App.runtimeconfig.json` ＋ `Microsoft.WindowsDesktop.App.deps.json`**，
两者缺一 host 都当"没有这个框架"。

**读数 3（`deps.json` 里 `assemblyVersion` 是必需项，不是装饰）**：

`COREHOST_TRACE=1` 现取（同一份 deps，只改 `assemblyVersion` 字段）：

```
Adding tpa entry: .../WindowsBase.dll, AssemblyVersion: , FileVersion:            ← 留空
```

⇒ 留空时该框架件的 TPA 条目**版本为空**，与应用请求的 `4.0.0.1` **对不上**，
启动即：

```
Unhandled exception. System.IO.FileNotFoundException: Could not load file or assembly
'WindowsBase, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35'.
```

把 `assemblyVersion` 按**文件里真实的值**写进去（本实现的脚本从 CLI 元数据现读，不写死）后即可绑定。
（注意 `Microsoft.NETCore.App` 里另有一份 `WindowsBase 4.0.0.0` 的**空门面**也进 TPA ——
本框架件若留空版本，连那份门面都比它"高"。）

**读数 4（框架形态的最小 deps.json）** —— 本实现生成的形态（仿 `Microsoft.NETCore.App.deps.json`）：

```json
{
  "runtimeTarget": { "name": ".NETCoreApp,Version=v10.0/linux-x64", "signature": "" },
  "compilationOptions": {},
  "targets": {
    ".NETCoreApp,Version=v10.0": {},
    ".NETCoreApp,Version=v10.0/linux-x64": {
      "Microsoft.WindowsDesktop.App.Runtime.linux-x64/10.0.11": {
        "runtime": { "WindowsBase.dll": { "assemblyVersion": "4.0.0.1" }, "...（12+9 件）": {} },
        "native":  { "libwpfwin32.so": {}, "libwpfwic.so": {}, "wpfgfx_cor3.so": {}, "libSkiaSharp.so": {} }
      }
    }
  },
  "libraries": { "Microsoft.WindowsDesktop.App.Runtime.linux-x64/10.0.11":
                 { "type": "package", "serviceable": true, "sha512": "",
                   "path": "microsoft.windowsdesktop.app.runtime.linux-x64/10.0.11" } }
}
```

`fileVersion` **不写**：本实现没有现读它的手段（它在 Win32 版本资源里，不在 CLI 元数据里），
按本仓口径"**不实读就不写**"，不编。

### §1.2 前置② · `.so` 在**框架目录**里，现有 resolver 搜不到（件:行 ＋ 实测）

**结论：搜不到。** 两条 resolver 的候选路径里**都没有"框架目录"这一档**：

| resolver | 候选顺序（改动前） | 关键行 |
|---|---|---|
| `Win32ShimResolver`（`libwpfwin32.so` / `libwpfwic.so`） | ① `WPF_LINUX_WIN32_SHIM` env ② **`AppContext.BaseDirectory`**（= **应用**目录）③ 仓库 `src/WpfGfx.Linux.Native/bin/`（从 app 目录/cwd 向上找 12 层） | `build/shims/Win32ShimResolver.cs:498`（`string baseDir = AppContext.BaseDirectory;`）、`:520-537`（仓库回退） |
| `MilCoreDllImportResolver`（`wpfgfx_cor3.so`） | ① `MILBRIDGE_MILCORE_SO` env ② `MILBRIDGE_MILCORE_DIR` ③ **`AppContext.BaseDirectory`** ④ `app/runtimes/linux-x64/native/` ⑤ 仓库 `build/MilBridge/.artifacts/publish/**` | `build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs:101-151`（`FindSharedObject`）、`:119`（`AppContext.BaseDirectory`） |

**实测读数（改动前）**：把 12 件托管件放进框架目录跑一个"框架提供托管件"的应用，第一步就停：

```
Unhandled exception. System.TypeInitializationException: The type initializer for
'System.Windows.Application' threw an exception.
 ---> System.DllNotFoundException: WPF-on-Linux: 'kernel32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库。
搜索过程：
  · 不存在 /tmp/wpfwsd/app1/libwpfwin32.so          ← 只有"应用目录"这一档
```

### §1.3 前置③ · 只加搜索路径（语义不变）＋ 4 位重建

**改动只有"追加一档"**，不删不改任何既有档，不动任何判定逻辑：

- `build/shims/Win32ShimResolver.cs:502-511`：在"应用目录"之后**追加**
  `本程序集所在目录/libwpfwin32.so`（`AssemblyDirectory` 新属性在 `:554-571`，取
  `typeof(Win32ShimResolver).Assembly.Location` 的目录 —— 共享框架布局下即**框架目录**）。
  WIC 组（`useWicCandidates`）复用同一档 ⇒ `libwpfwic.so` 同样够得着。
- `build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs:130-148`：`FindSharedObject()`
  在"应用目录"之后**追加**同义的一档。

**为什么"够不着"是必然**：这两条 resolver 服务的是**应用**的 P/Invoke，而
`AppContext.BaseDirectory` 是**应用**目录；框架件（`WindowsBase.dll`）自己住在框架目录里。
⇒ 新增档取的是"**托管件所在目录**"，与"应用目录"在 app-local 部署下**同值**（那时新档不产生候选，
`!string.Equals(asmDir, baseDir)` 守卫），在共享框架布局下才生效 ⇒ **app-local 行为逐字不变**。

**重建（改动落进产物才有用）** —— `Win32ShimResolver.cs` 被编进 **4 个**程序集
（`WindowsBase` / `PresentationCore` / `UIAutomationTypes` / `UIAutomationProvider`，见各自 `.shims.txt`），
`MilCoreDllImportResolver.cs` 只进 `PresentationCore`：

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux
dotnet build build/WindowsBase.Linux/WindowsBase.Linux.csproj                  -c Release
dotnet build build/UIAutomationTypes.Linux/UIAutomationTypes.Linux.csproj      -c Release
dotnet build build/UIAutomationProvider.Linux/UIAutomationProvider.Linux.csproj -c Release
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj         -c Release      # 0 错 0 警
```

**位移（如实登记，`sha16`）**：

| 件 | 改前 sha16 | 改后 sha16 | 字节 |
|---|---|---|---|
| `WindowsBase.dll` | `7f1c38f90e916718` | **`fcdb44f8dd0470f9`** | 1111552 → 1112064 |
| `PresentationCore.dll` | `ba162811e97e4484` | **`9e703ef212752aed`** | 3602944 → 3603456 |
| `UIAutomationTypes.dll` | `4cda62a98151995d` | **`130f8f2881b0d9c0`** | 223232 → 223744 |
| `UIAutomationProvider.dll` | `0869d64a8361c71f` | **`1481c919abbd4816`** | 41984 → 42496 |

⚠️ 这四位是**产品件**（不在 `WIN-INTEROP.md` 的"12 件"点名表之外 —— 就是那 12 件里的 4 件），
按本仓"九位"规矩属于**会动的读点**：任何按旧 `sha16` 冻结的判据都要按现场重取。

---

## §2 端到端（**未改 runtimeconfig**）

### §2.1 装置

- **应用**：`samples/WpfTextDemo` 的**源码**（XAML/BAML/绑定/滚动/位图/效果全在），
  按"共享框架接入形态"在一个**仓外**目录里重编 —— 用
  `build/third-party/windowsdesktop-app-linux-framework-e2e.sh`（一条命令）。
- **框架**：`bash build/third-party/windowsdesktop-app-linux-framework.sh install`（装进**真** dotnet root）。
- **显示**：`Xvfb :234 -screen 0 1280x1024x24`（空闲显示位；进程按 PID 收）。

### §2.2 一条命令 + 现取输出

```bash
$ cd /home/links-dev/netTest/GitProj/WPFOnLinux
$ bash build/third-party/windowsdesktop-app-linux-framework-e2e.sh --display :234
== 1) 构建（net10.0-windows + 自产件编译面 + WindowsDesktop 框架声明）==
  WpfTextDemo -> /tmp/wpfwd-e2e-M52AKh/wtd/bin/Release/net10.0-windows/WpfTextDemo.dll
已成功生成。
== 2) 产物读数 ==
runtimeconfig.frameworks = ['Microsoft.NETCore.App', 'Microsoft.WindowsDesktop.App']      ← 未手改
app-local dll            = ['DirectWrite.Linux.Provider.dll', 'SkiaSharp.dll', 'WpfTextDemo.dll']
框架件是否 app-local     = False                                                          ← 12 件由框架提供
-- AssemblyRef（自产身份）--
NSystem.Xaml, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35
NWindowsBase, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35
SPresentationCore, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35
XPresentationFramework, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35
== 3) 跑（DISPLAY=:234）==
APP_PID=1891447
ALIVE=yes
window: 938x938 colors=3130                                           ← 真渲染
-- 应用自己报的读数（行模型/滚动）--
WPTD_SCROLL_RANGE=extent=926.4 viewport=717.1 scrollable=209.2 bar=Visible offset=0.0
-- .so 落点（/proc/1891447/maps）--
/home/links-dev/.dotnet/shared/Microsoft.WindowsDesktop.App/10.0.11/libSkiaSharp.so
/home/links-dev/.dotnet/shared/Microsoft.WindowsDesktop.App/10.0.11/libwpfwic.so
/home/links-dev/.dotnet/shared/Microsoft.WindowsDesktop.App/10.0.11/libwpfwin32.so
/home/links-dev/.dotnet/shared/Microsoft.WindowsDesktop.App/10.0.11/wpfgfx_cor3.so
-- 框架目录被引用的 map 行数 --
33
KILL=ok（按 PID）
```

**rc**：脚本整体 `exit 0`；应用进程被按 PID 正常收掉（`KILL=ok`）。

### §2.3 `dotnet <app>.dll` 的最裸形态（同装置，手工现取）

```bash
$ cd /tmp/wpfwsd/harness2/wtd/bin/Release/net10.0-windows
$ DISPLAY=:234 dotnet WpfTextDemo.dll     # 后台起，14s 后按 PID 读
PID=1890533 WID=2097157 alive=yes
window: 938x938 colors=2575
...
WPTD_SCROLL_MOVED=offset=48.0 delta=48.0 scrollable=209.2
```

### §2.4 另一个"源码重编"形态：§7.1 的 exp1（重编为自产身份）

同装置、同 props，把 `/tmp/wincompat/exp1` 的源码重编（TFM 仍 `net10.0-windows`、`UseWPF` 仍 `true`）：

```bash
$ cd /tmp/wpfwsd/harness/exp1/bin/Release/net10.0-windows
$ DISPLAY=:234 dotnet exp1.dll
APP_PID=1890830 WID=2097156 alive=yes
# 窗口 313x208 起在 (0,0)，进程存活；日志：[G147_WORKAREA]… / [FONT_FALLBACK] requested=DEJAVU SANS resolved=DEJAVU SANS
```

⚠️ 如实标注：exp1 这个最小样例**起了窗但抓图里看不到 "hi" 文本像素**（窗口面为均匀
`#F0F0F0`；`import -window root` 的窗口区域内另有 1495 个白色像素 —— 两种口径不一致，
**未定位**）。同一装置下 `WpfTextDemo`（`colors=3130`、`WPTD_SCROLL_*`）**渲染正常**
⇒ 这是 exp1 这个最小样例的观测量，**不是**框架目录加载面的问题。见 §7 NOINFO 条目一。

---

## §3 反极性（撤框架目录 ⇒ 原始报错逐字复现）

```bash
$ bash build/third-party/windowsdesktop-app-linux-framework.sh uninstall --root /home/links-dev/.dotnet
=== uninstall ===
OK 已移除 /home/links-dev/.dotnet/shared/Microsoft.WindowsDesktop.App/10.0.11（整目录回滚）
父目录现在：（已删）

$ cd /tmp/wpfwsd/harness2/wtd/bin/Release/net10.0-windows
$ DISPLAY=:234 dotnet WpfTextDemo.dll ; echo "RC=$?"
You must install or update .NET to run this application.

App: /tmp/wpfwsd/harness2/wtd/bin/Release/net10.0-windows/WpfTextDemo.dll
Architecture: x64
Framework: 'Microsoft.WindowsDesktop.App', version '10.0.0' (x64)
.NET location: /home/links-dev/.dotnet/

No frameworks were found.
...
RC=150
```

与 `docs/T0T1-report.md:71` 记的原始形态**逐字同形**（同为 `RC=150`）。复装：

```bash
$ bash build/third-party/windowsdesktop-app-linux-framework.sh install --root /home/links-dev/.dotnet
$ bash build/third-party/windowsdesktop-app-linux-framework.sh verify  --root /home/links-dev/.dotnet
VERIFY=PASS (25/25 与权威件逐字节相同)
```

---

## §4 交付物与落点

| # | 落点 | 类型 |
|---|---|---|
| ① | `build/third-party/windowsdesktop-app-linux-framework.sh` | 新增（install / uninstall / verify ＋ 内置 CLI 元数据 AssemblyVersion 读取器） |
| ② | `build/third-party/WindowsDesktop.App.Linux.props` | 新增（`net10.0-windows` + `FrameworkReference` + 丢官方 ref 面） |
| ③ | `build/third-party/windowsdesktop-app-linux-framework-e2e.sh` | 新增（端到端复现） |
| ④ | `build/shims/Win32ShimResolver.cs`、`build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs` | 改（**只追加一档搜索路径**） |
| ⑤ | `build/WindowsBase.Linux`、`build/UIAutomationTypes.Linux`、`build/UIAutomationProvider.Linux`、`build/PresentationCore.Linux` 的 `bin/Release` | 重建（位移见 §1.3） |
| ⑥ | `<dotnet root>/shared/Microsoft.WindowsDesktop.App/10.0.11/`（= `/home/links-dev/.dotnet/shared/…`） | 新增（**仓外**；整目录可回滚） |

**没碰**：`upstream/**`、`verify-all.sh`、`build/close-wave.sh`、`build/MilBridge/tools/**`、`src/**`、`samples/**`。

---

## §5 逐件在位（sha16 / 字节；现取，真 dotnet root）

### §5.1 自产 12 件（点名 —— 与官方 `WindowsDesktop.App` 同名的本仓实现）

| # | 件 | 字节 | sha16 | 权威源（仓内） |
|---|---|---|---|---|
| 1 | `WindowsBase.dll` | 1112064 | `fcdb44f8dd0470f9` | `build/WindowsBase.Linux/bin/Release/` |
| 2 | `System.Xaml.dll` | 614400 | `50c037fe785d0a7f` | `build/System.Xaml.Linux/bin/Release/` |
| 3 | `PresentationCore.dll` | 3603456 | `9e703ef212752aed` | `build/PresentationCore.Linux/bin/Release/` |
| 4 | `PresentationFramework.dll` | 6159360 | `93f0368dac89f9c2` | `build/PresentationFramework.Linux/bin/Release/` |
| 5 | `PresentationFramework.Classic.dll` | 179712 | `b5cfe401e1f53565` | `build/PresentationFramework.Classic.Linux/bin/Release/` |
| 6 | `PresentationUI.dll` | 7168 | `56308571f810f50c` | `build/CycleStub.PresentationUI.Linux/bin/Release/` |
| 7 | `ReachFramework.dll` | 5120 | `72081d50d65c0f04` | `build/CycleStub.ReachFramework.Linux/bin/Release/` |
| 8 | `System.Printing.dll` | 48640 | `5cecbe296dea70e7` | `build/System.Printing.Linux/bin/Release/` |
| 9 | `System.Windows.Input.Manipulations.dll` | 53248 | `4038a9e74c46de58` | `build/System.Windows.Input.Manipulations.Linux/bin/Release/` |
| 10 | `UIAutomationTypes.dll` | 223744 | `130f8f2881b0d9c0` | `build/UIAutomationTypes.Linux/bin/Release/` |
| 11 | `UIAutomationProvider.dll` | 42496 | `1481c919abbd4816` | `build/UIAutomationProvider.Linux/bin/Release/` |
| 12 | `DirectWriteForwarder.dll` | 39936 | `11b983efa4c8a09d` | `build/DirectWriteForwarder.Linux/bin/Release/` |

### §5.2 原生 4 件（与 `samples/ThirdPartyMini` 的部署配方**同源**）

| # | 件 | 字节 | sha16 | 权威源（仓内） |
|---|---|---|---|---|
| 13 | `libwpfwin32.so` | 553936 | `df27801beb222f05` | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` |
| 14 | `libwpfwic.so` | 74984 | `f7b3026c8c019be2` | `build/DirectWrite.Linux/wic-shim/libwpfwic.so` |
| 15 | `wpfgfx_cor3.so` | 5028208 | `941e69902d82ef02` | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` |
| 16 | `libSkiaSharp.so` | 9244960 | `a02cd03f1ebcbb97` | `build/DirectWrite.Linux/wic-shim/libSkiaSharp.so` |

### §5.3 ＋ 运行期 BCL 闭包 9 件（**为什么必须有** —— 这是本任务的实测发现）

**发现**：应用一旦声明 `FrameworkReference Microsoft.WindowsDesktop.App`，SDK 就认定
`System.IO.Packaging` 这批是"**框架提供的**"：

- 把它们从应用的 `ReferenceCopyLocalPaths`/`deps.json` 里剪掉（`ResolveReferences` 现取：
  `CopyLocal=false`，且**不在** `WpfTextDemo.deps.json` 的 runtime 段里）；
- 连带的 `PackageReference` 被 prune（现取警告 `NU1510`；`RestoreEnablePackagePruning=false` 也改不了 `CopyLocal=false`）。

**后果（实测）**：框架目录只放 12 件时，应用走到 `System.Windows.Application..cctor()` 就：
`FileNotFoundException: Could not load file or assembly 'System.IO.Packaging, Version=9.0.0.0'`。
把 9 件放进框架目录后即恢复（§2 全绿）。
**官方 `Microsoft.WindowsDesktop.App` 本来就含这批件** ⇒ 这是"替代 runtime"应有的形态，不是补丁。

| # | 件 | 字节 | sha16 | 源 |
|---|---|---|---|---|
| 17 | `System.Windows.Extensions.dll` | 8704 | `2322a23281557e89` | **自产替身** `build/System.Windows.Extensions.Linux/bin/Release/`（官方包非 Windows 必抛，`#38`） |
| 18 | `System.IO.Packaging.dll` | 158496 | `99e9461d6d5d303e` | `~/.nuget/packages/system.io.packaging/9.0.0/lib/net9.0/` |
| 19 | `System.Configuration.ConfigurationManager.dll` | 443168 | `df795025f207b494` | `…/system.configuration.configurationmanager/9.0.0/lib/net9.0/` |
| 20 | `System.Diagnostics.EventLog.dll` | 53528 | `803ba4a0bd41b63b` | `…/system.diagnostics.eventlog/9.0.0/lib/net9.0/` |
| 21 | `System.Formats.Nrbf.dll` | 67848 | `7018d6744e48213f` | `…/system.formats.nrbf/9.0.0/lib/net9.0/` |
| 22 | `System.Security.Cryptography.Pkcs.dll` | 265496 | `152c218416c40728` | `…/system.security.cryptography.pkcs/9.0.0/lib/net9.0/` |
| 23 | `System.Security.Cryptography.ProtectedData.dll` | 38664 | `b761c998813562ba` | `…/system.security.cryptography.protecteddata/9.0.0/lib/net9.0/` |
| 24 | `System.Security.Cryptography.Xml.dll` | 200992 | `ee3e88c494e53b9a` | `…/system.security.cryptography.xml/9.0.0/lib/net9.0/` |
| 25 | `System.Security.Permissions.dll` | 117520 | `c4188ef6d9c744e5` | `…/system.security.permissions/9.0.0/lib/net9.0/` |

**TFM 选择规则（脚本里写死、可复算）**：先取 `lib/net<major>.<minor>/`（排除 `net462` 这类
三位数 TFM），无则退 `lib/netstandard*/` —— 所以上表落的是 `net9.0` 资产，不是 `netstandard2.0`
（后者在 `sort -V` 里会排到最后，是**踩到过**的一个坑，已修）。

外加自造清单 2 个：`Microsoft.WindowsDesktop.App.deps.json`（2772 B，`41ef88d76d20be5d`）、
`Microsoft.WindowsDesktop.App.runtimeconfig.json`（175 B，`a8785721df214f04`）。

`bash …/windowsdesktop-app-linux-framework.sh verify` ⇒ `VERIFY=PASS (25/25 与权威件逐字节相同)`。

---

## §6 安装 / 卸载（一条命令，可回滚）

```bash
cd /home/links-dev/netTest/GitProj/WPFOnLinux

# 装（默认装进 `dotnet` 可执行文件所在根；--root 可改；默认版本目录 10.0.11）
bash build/third-party/windowsdesktop-app-linux-framework.sh install

# 验（25/25 与仓内权威件逐字节比对）
bash build/third-party/windowsdesktop-app-linux-framework.sh verify

# 卸（删 `<root>/shared/Microsoft.WindowsDesktop.App/10.0.11/`；父目录空则一并删）
bash build/third-party/windowsdesktop-app-linux-framework.sh uninstall
```

脚本特性：`--dry-run` 先看计划；`--force` 覆盖；`--version` / `--config` 可改；缺件**大声失败**；
落盘走 **temp（`.stage-<ver>-<pid>`）＋ rename**；`assemblyVersion` 从 CLI 元数据**现读**（不写死）。

---

## §7 具名 NOINFO

1. **`NOINFO(reason=exp1-最小样例文本像素未定位)`**：§2.4 的 exp1 重编样例**起窗、进程存活**，
   但抓图口径下"hi"文本像素不可见（`import -window <id>` 为均匀 `#F0F0F0`，`import -window root`
   的同一区域却有 1495 个白像素）。同一装置下 `WpfTextDemo` 渲染正常 ⇒ **未判定**这是
   exp1 的 XAML/主题差异还是抓图口径问题。**不声称已定位**。
2. **`NOINFO(reason=真 Windows 端到端本机不可得)`**：本机无 `Microsoft.WindowsDesktop.App.Runtime.win-x64`、
   无 wine ⇒ **"在真 Windows 上用本仓产物/本框架互通"这一格本机无法取得**（与 `WIN-INTEROP.md` §7.7 同）。
   本报告不含任何 Windows 侧读数。
3. **`NOINFO(reason=上游应用自带的 deps 引用未逐一验证)`**：本报告只验证了**一个**真应用
   （`WpfTextDemo` 源码重编）与一个最小样例（`exp1` 重编）。"任意第三方 WPF 应用"是否只差
   §5.3 那 9 件 BCL —— **未做全量扫描**（`samples/WpfFeatureProbe`、`ThirdPartyMini`、仓外
   HandyControl 均未在本波验证）。

---

## §8 主动披露（待裁决 / 与规格字面不一致）

1. **⚠️ L1 的适用面比 §7.2 的字面窄一层 —— 编译身份必须"≤ 框架提供的 4.0.0.1"。**
   §7.1 的零改动编译产物（`UseWPF=true` 引官方 ref pack）其 `AssemblyRef` 是
   `PresentationFramework, Version=10.0.0.0`（实测），**绑不到**自产的 `4.0.0.1`
   （现场：`FileNotFoundException … Version=10.0.0.0`）。⇒ 本波端到端用的是
   **"源码重编 + 自产件编译面"**（`build/third-party/WindowsDesktop.App.Linux.props`）。
   想让 §7.1 **原样**产物（官方身份）直接吃本框架，就得把自产件身份抬到 `10.0.0.0`
   —— 那是 **L2**（§7.5），另需 77 文件/114 行同步（§7.3）。
   **建议主控裁定**："L1 = 框架目录 ＋ 自产件编译面"是否就是 §7.5 的预期口径。
2. **⚠️ 与 §7.2 字面不一致**：目录名写 `10.0.0.x`（4 段）**host 不认**（§1.1 读数 1）。
   本实现取 3 段 `10.0.11`。**建议把 §7.2 的示例改成 3 段**。
3. **框架件数不是 12 —— 是 12 ＋ 4 ＋ 9。** 前两组是任务点名的；第 3 组（BCL 闭包）是
   §5.3 实测逼出来的（SDK 把"框架已提供"的 BCL 从应用输出里剪掉）。
   这 9 件**不是自产件**，是"替代 runtime 必须替应用拿出的那批"。
4. **本波动了 4 位产品件**（`WindowsBase`/`PresentationCore`/`UIAutomationTypes`/`UIAutomationProvider`
   的 `sha16` 位移，见 §1.3）。虽然只加了一档搜索路径、语义不变，但按本仓冻结规矩
   **必须由主控按波登记**（本波无 `docs/WAVE*-PREREGISTRATION.md` 对应记录 —— 任务是"tail2 批"的 T-B2）。
5. **仓外新增了一个目录**（`<dotnet root>/shared/Microsoft.WindowsDesktop.App/10.0.11/`），
   当前**处于已安装状态**（便于验收）；一条命令可整目录回滚（§6）。
6. **§5.3 的 BCL 依赖 `~/.nuget/packages` 缓存**：缓存里没有（`System.*` 9.0.0 系列）时脚本
   **大声失败**并指路 `build/setup-env.sh`；不静默降级。
7. **`exp1` 也重编过一份**（§2.4）—— 它的源码在 `/tmp/wincompat/exp1`（仓外，本波未改），
   重编落在 `/tmp/wpfwsd/harness/exp1`（仓外临时）。报告里的命令可复算，但该临时目录
   **不构成仓内交付物**；§2.2 的 `…-e2e.sh` 才是可复现入口（它从 `samples/WpfTextDemo` 现场取源）。

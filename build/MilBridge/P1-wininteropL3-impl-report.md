# P1-wininteropL3-impl 报告 —— `WIN-INTEROP.md` §7.5 **L3**：导出脚本（Windows 端替换 runtime）—— 实现

> 任务：`build/MilBridge/tasks-tail2/T-B6.md`（实现子代理；本轮唯一写者）。
> 读时：2026-10-02。口径：**本文所有数字都是现场读数**；命令与输出逐条给出，可复算。
> 规格源：`/home/links-dev/netTest/GitProj/WIN-INTEROP.md` §7.4（Linux 编 → Windows 跑的三件事）、§7.5 的 **L3**、§7.7（取证边界）、§7.8（可复算命令）。
> 前置：`P1-wininteropL1-impl-report.md`（L1 框架目录）、`P1-wininteropL2-impl-report.md`（身份 `10.0.0.0` ＋ 令牌对齐）。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① shim 1 行短路** | `build/shims/Win32ShimResolver.cs:228-229`：`if (OperatingSystem.IsWindows()) return;`（＋ 头注 `:31-38`）；落在 **4 个**自产程序集（WindowsBase/PresentationCore/UIAutomationTypes/UIAutomationProvider） |
| **逐件现取（件:行）** | `:214 internal static void Register()`；短路本体 `:228-229`；Linux 正极性 4/4 `REAL_DLLIMPORT=OK value=1`；Windows 支（同源、谓词替 `true`）`REAL_DLLIMPORT=THROW DllNotFoundException 'user32.dll'` ⇒ 交回默认探测 = 官方件 |
| **② 导出脚本**（一条命令、可回滚） | `build/third-party/windowsdesktop-app-win-export.ps1`（`install` / `uninstall` / `verify`；pwsh 7） |
| → install | 删 **34** 个 app-local 件（21 官方名 ×(dll+pdb)＋自产 ELF）＋ 写回标准 `runtimeconfig.json` ＋ 去 **21** 条 deps 登记（逐命令输出） |
| → uninstall | 按 `manifest.json` 整份还原；与导出前 **逐字节相同**（`diff -r` 空） |
| → 反极性 | 对**未导出**的原始产物跑 `verify` ⇒ `rc=1`／`VERIFY=FAIL` |
| **③ asmmeta 审计**（逐件） | 11 件可审：`WindowsBase 20 类型/155 成员`、`PresentationCore 2/40`、`PresentationFramework 0/2`、**其余 8 件 0/0**；`DirectWriteForwarder` **`NOINFO`（官方 ref 包不含该件）** |
| ↑ 扩展面性质 | `WindowsBase` 的 20 类型**全是** `Windows.Win32.*`（CsWin32 面）；`PresentationCore` 的 2 类型是本栈 shim（`MilCoreDllImportResolver` / `HbTextLineScaffold`） |
| ↑ 两个样本 | **不引用**任何扩展面（`memrefs` 现取 0 命中） |
| **④ L2 绑定不回退** | ✅ `/tmp/tb5-probe` 正极性 6/6 `LOAD OK` ＋ `LIBCONSUMER OK`，`RC=0` |
| **⑤ L1 e2e 不回退** | ✅ 框架目录 `VERIFY=PASS (25/25 逐字节相同)`；`dotnet WpfTextDemo.dll` → `window: 938x938 colors=3130` ＋ `WPTD_SCROLL_RANGE=…`；4 个 `.so` 从框架目录加载；`KILL=ok` `rc=0` |
| **⑥ 两牙** | `DEFREG=PASS` rc=0 ／ `REPORTID=PASS` rc=0；`ARTIFACT-SRC-FP` 3 件 `state=ok` |
| **半程证据**（本机可得） | 导出后的产物在 **Linux**（自产框架）上真起窗渲染（`colors=3130`）；**反向对照**「只删件、不改 deps」⇒ 逐字复现 §7.4 ② 的 `FileNotFoundException: WindowsBase, Version=10.0.0.0` |
| **具名 NOINFO** | `真 Windows 端到端本机不可得`（无 `WindowsDesktop.App.Runtime.win-x64`、无 wine）；`DirectWriteForwarder 官方件审计不可得`（ref 包不含，runtime 包未下载） |

**一句话**：L3 的三件交付物都落地了 —— **shim 多了一行"到 Windows 就不注册"的平台短路**，**一个 pwsh 脚本**把 Linux 产物就地改成"标准 Windows WPF 应用形态"（装/卸可整目录回滚），**asmmeta 逐件审完扩展面**；L1/L2 两条既有链一字未退。
但**必须如实划界**：替换之后 **Windows 上跑的是官方 WPF，不是本栈实现**（§7.4 末段）；"在真 Windows 上端到端跑通"这一格**本机取不到**，本报告不含任何 Windows 侧读数。

---

## §1 ① shim 1 行平台短路

### §1.1 件:行（改的就是这一段）

```csharp
// build/shims/Win32ShimResolver.cs
:214        internal static void Register()          // [ModuleInitializer]（:213）
:215        {
:216-227        // ── L3（`WIN-INTEROP.md` §7.4 ①）：**Windows 平台短路** ── …（理由注释）
:228            if (OperatingSystem.IsWindows())
:229                return;
```

文件头另加一段自述（`:31-38`）指向本报告。**这就是 §7.4 ① 那"1 行"**：Windows 上 `Register()` 直接返回 ⇒ **既不装 ALC 级 `ResolvingUnmanagedDll` 钩子（`:231+`），也不占本程序集的 `SetDllImportResolver` 槽位（`:262+`）**，一切 `[DllImport("user32.dll")]` 等交回**默认探测** ⇒ 走的正是**官方系统件**。
Linux 上 `OperatingSystem.IsWindows()` **恒 false** ⇒ 下方既有行为**逐字不变**（"一位不差"，见 §1.2 的正极性读数）。

### §1.2 前后行为成对（探针现取）

**装置**（仓外 `/tmp/l3-guard/`）：把**同一份源件**编成两个探针目标程序集（`net10.0`，`DefineConstants=WINDOWS_BASE`），用仓内既有探针 `build/MilBridge/tests/ResolverGuardProbe` 的 `realcall` 模式驱动（它反射调用本程序集内声明的**真** `[DllImport("user32.dll")] ShimVersionViaUser32`，走的就是本程序集注册的那个解析器）：

| 腿 | 源件 | `linux-as-is` | `win-sim` |
|---|---|---|---|
| 平台判定 | — | 真件原样（`OperatingSystem.IsWindows()`） | 同源，**只把谓词替成 `true`**（模拟"运行在 Windows 上"这一支） |
| `diff` | — | — | **只有 2 行不同**（`:228` 谓词 ＋ `:34` 那句注释） |
| 编译 | — | `0 错 0 警` | `0 错`，**1 警 `CS0162`（无法访问的代码 `:240`）** ← 短路之后整段都没了 |
| `REAL_DLLIMPORT` | — | **`OK value=1`**（`user32.dll` → `libwpfwin32.so` 劫持生效） | **`THROW DllNotFoundException: Unable to load shared library 'user32.dll' …`** |

`win-sim` 那一条的**逐字报错**（截取）：

```
inner=System.DllNotFoundException: Unable to load shared library 'user32.dll' or one of its dependencies.
/home/links-dev/.dotnet/shared/Microsoft.NETCore.App/10.0.11/user32.dll.so: cannot open shared object file: No such file or directory
/tmp/l3-guard/win-sim/bin/Release/net10.0/user32.dll.so: cannot open shared object file: No such file or directory
```

⇒ 报错里列的全是**默认探测**路径（框架目录 / 应用目录），**"已映射到 libwpfwin32.so"那句不再出现** ⇒ 短路确实把名字**交回默认探测**了。在真 Windows 上，默认探测命中的就是**官方系统 `user32.dll`**。

**成对结论**：不短路 = 劫持到 `libwpfwin32.so`（Windows 上 ⇒ ELF 加载不了 ⇒ §7.4 复现过的 `DllNotFoundException`）；短路 = 交回默认 ⇒ 官方件。

### §1.3 落地的 4 个程序集（Linux 正极性现取）

`Win32ShimResolver.cs` 由各工程的 `build/shims/<Name>.shims.txt` 引入，被编进 **4 个**程序集。改后重建，用同一探针跑**真件**：

```bash
$ WPF_PROBE_SHIM=<repo>/src/WpfGfx.Linux.Native/bin/libwpfwin32.so \
  dotnet build/MilBridge/tests/ResolverGuardProbe/bin/Release/net10.0/ResolverGuardProbe.dll \
         realcall <自产件> --loadstream | grep REAL_DLLIMPORT
build/WindowsBase.Linux/bin/Release/WindowsBase.dll                     REAL_DLLIMPORT=OK value=1
build/PresentationCore.Linux/bin/Release/PresentationCore.dll            REAL_DLLIMPORT=OK value=1
build/UIAutomationTypes.Linux/bin/Release/UIAutomationTypes.dll          REAL_DLLIMPORT=OK value=1
build/UIAutomationProvider.Linux/bin/Release/UIAutomationProvider.dll    REAL_DLLIMPORT=OK value=1
```

⇒ 4/4 正极性不变（Linux 上 resolver 照旧注册、照旧劫持）。

### §1.4 `P8`：为什么**直接改这个源件**才是对的落点

`P8`（"生成件走生成器"）在本件的落点判定是**先查它是不是生成件**：

```bash
$ grep -n "Win32ShimResolver\|shims" build/port-lib.py | head
602:    # ---------- 4c. shim：build/shims 下的兼容层源文件 ----------
607:    shims = []
608:    shim_list = os.path.join(HERE, "shims", name + ".shims.txt")
613:                shims.append(...)
615:    out.append("  <!-- WPF-on-Linux 兼容层：build/shims 下手写的等价类型（上游零改动） -->")
```

⇒ `port-lib.py` 只**读** `build/shims/<Name>.shims.txt` 的清单、往 csproj 里**发** `<Compile Include>`；**shim 源件本身是手写件，没有任何生成器写它** ⇒ **直接改它**是 P8 要求的正确落点（"无生成器可走"），不是违规。
（对照：真正的生成件如 `build/PresentationCore.Linux/FamilyCollection.Linux.cs` 才必须走 `src/WpfGfx.Linux.Native/tools/patch-…py`。）

**写前副本**（"副本先行；写前 `cp -p`"）：改前原件由 git 保全，现取命令：

```bash
git show HEAD:build/shims/Win32ShimResolver.cs > /tmp/Win32ShimResolver.pre.cs   # 改前原件
git diff -- build/shims/Win32ShimResolver.cs                                     # +23 行（头注 8 ＋ 短路 15）
```

---

## §2 ② 导出脚本（Windows 端替换 runtime）

### §2.1 交付物与用法

`build/third-party/windowsdesktop-app-win-export.ps1`（新增；**PowerShell 7**，§7.4 ② 点的是"bat/ps1"）：

```bash
pwsh -File build/third-party/windowsdesktop-app-win-export.ps1 install   <appdir> [-Force] [-DryRun] [-FrameworkVersion 10.0.0]
pwsh -File build/third-party/windowsdesktop-app-win-export.ps1 verify    <appdir>
pwsh -File build/third-party/windowsdesktop-app-win-export.ps1 uninstall <appdir>
```

它做 §7.4 ② 的三件事：**删掉 app-local 的框架同名件**、**写回标准 `runtimeconfig.json`**（`frameworks` = NETCore.App ＋ WindowsDesktop.App）、**同步 `deps.json`**（去掉被删件的登记）。
**它只动"官方框架会同名提供"的那一层**（§2.7 划界）；不改应用自己的件、不碰第三方包。

### §2.2 install（逐命令输出，现取）

装置：`samples/WpfTextDemo` 的 **L0 形态**产物（`UseWPF=false` ＋ `<Reference HintPath>` 指自产件 ＋ `Private=true`；`runtimeconfig` 只声明 `Microsoft.NETCore.App`）复制到 `/tmp/l3-export/app0`，再跑脚本。

```bash
$ pwsh -File build/third-party/windowsdesktop-app-win-export.ps1 install /tmp/l3-export/app0
=== install：把 Linux 编出来的产物改成「Windows 直接跑（跑官方件）」形态 ===
APP            = WpfTextDemo
APP_DIR        = /tmp/l3-export/app0
RUNTIMECONFIG  = /tmp/l3-export/app0/WpfTextDemo.runtimeconfig.json
DEPS           = /tmp/l3-export/app0/WpfTextDemo.deps.json
BACKUP_DIR     = /tmp/l3-export/app0/.wpf-win-export-backup
FW_VERSION     = 10.0.0
-- 1) 删掉 app-local 里「官方 WindowsDesktop.App 会同名提供」的件 + 自产 ELF --
  [cmd] backup + del  WindowsBase.dll
  [cmd] backup + del  WindowsBase.pdb
  …（逐件；共 34 条）
  [cmd] backup + del  DirectWriteForwarder.pdb
        共删除 34 个文件
-- 2) 写回标准 runtimeconfig.json（frameworks = NETCore.App + WindowsDesktop.App）--
  [cmd] rewrite WpfTextDemo.runtimeconfig.json
-- 3) 同步 deps.json（去掉被删件的登记；只删件不改 deps ⇒ 启动 FileNotFoundException）--
  [cmd] rewrite WpfTextDemo.deps.json（移除 21 条库登记：… PresentationFramework, System.Windows.Extensions.Reference, …, ReachFramework）
  [cmd] write .wpf-win-export-backup/manifest.json
OK 已导出 → /tmp/l3-export/app0
```

导出后的两份清单（现取）：

```json
// WpfTextDemo.runtimeconfig.json  —— 与官方 UseWPF=true 产物同形（对照 /tmp/wincompat/exp1/…/exp1.runtimeconfig.json）
{ "runtimeOptions": { "tfm": "net10.0",
    "frameworks": [ {"name":"Microsoft.NETCore.App","version":"10.0.0"},
                    {"name":"Microsoft.WindowsDesktop.App","version":"10.0.0"} ],
    "configProperties": { …原样保留… } } }
```

`deps.json`：`targets`/`libraries` 里**不再登记**那 21 件（含由"runtime 段只登记被删件"规则逮到的 `System.Windows.Extensions.Reference/9.0.0.0`），应用条目的 `dependencies` 也同步掉；**剩余**只有应用自己 ＋ `SkiaSharp` 图 ＋ `DirectWrite.Linux.Provider`（见 §2.7）。`runtimeTarget` 保持 `.NETCoreApp,Version=v10.0` 不动。

### §2.3 verify（形态断言；不依赖 Windows）

```bash
$ pwsh -File build/third-party/windowsdesktop-app-win-export.ps1 verify /tmp/l3-export/app0 ; echo rc=$?
-- ① 框架同名件/自产 ELF 必须**不在** app-local --
  OK  none present
-- ② runtimeconfig 必须声明 Microsoft.WindowsDesktop.App --
  frameworks = [Microsoft.NETCore.App, Microsoft.WindowsDesktop.App]
-- ③ deps.json 不得再登记被删件 --
  OK  none registered
-- 产物剩余（app-local .dll）--
  DirectWrite.Linux.Provider.dll
  SkiaSharp.dll
  WpfTextDemo.dll
VERIFY=PASS (产物形态 = 标准 Windows WPF 应用；"在 Windows 上端到端跑通"须到 Windows 机复验)
rc=0
```

### §2.4 uninstall（可回滚；逐字节相同）

`install` 把**动过的每一个文件**（删的/改的）原样存进 `<appdir>/.wpf-win-export-backup/files/…`，并写 `manifest.json` 记逐条动作；`uninstall` 按清单整份还原后删备份目录。

```bash
$ diff -r app0 app0.pristine >/dev/null && echo ROLLBACK=PASS   # 导出前先 cp -rp 了一份 pristine
$ pwsh … uninstall /tmp/l3-export/app0 ; echo rc=$?
  [cmd] restore  …（逐件）
        共还原 36 个文件
  [cmd] rm -r .wpf-win-export-backup
OK 已回滚 → /tmp/l3-export/app0
rc=0
ROLLBACK=PASS (整目录逐字节相同)          # diff -r 空
```

（36 = 34 个删除件 ＋ 2 个重写清单。）

### §2.5 反极性：对**未导出**的原始产物跑 `verify` ⇒ 红

```bash
$ pwsh … verify /tmp/l3-export/app0.pristine ; echo rc=$?
  FAIL 仍在：WindowsBase.dll
  FAIL 仍在：WindowsBase.pdb
  …（逐件）
VERIFY=FAIL
rc=1
```

⇒ 判据**有牙**：它不是"打印一下就绿"。

### §2.6 半程证据（本机可得的那一半）

⚠️ 本机无 Windows ⇒ "真 Windows 端到端"取不到（§6 NOINFO）。本节能给的是**同机（Linux）上把"产物形态"这条路走通**的读数：

**（a）导出后的形态在 Linux（用 L1 自产框架）上真起窗渲染** —— 证明"删件 ＋ 改清单"后**deps/磁盘/runtimeconfig 三者自洽**，且 WPF 全部由**框架**提供（应用目录里一件没有）：

```bash
$ bash ~/heavy-slot.sh --min-avail 2500 --max-hold 300 --wait 900 -- bash /tmp/l3-export/runC.sh
PID=2128868 ALIVE=yes
WID=2097157
window: 938x938 colors=3130                      # 真渲染
WPTD_SCROLL_RANGE=extent=926.4 viewport=717.1 scrollable=209.2 bar=Visible offset=0.0
-- .so / .dll 落点（/proc/<pid>/maps）--         # 全部来自**框架目录**
/home/links-dev/.dotnet/shared/Microsoft.WindowsDesktop.App/10.0.11/{PresentationFramework,PresentationCore,PresentationFramework.Classic,DirectWriteForwarder,System.IO.Packaging,System.Windows.Extensions}.dll
/home/links-dev/.dotnet/shared/Microsoft.WindowsDesktop.App/10.0.11/{libwpfwin32,libwpfwic,wpfgfx_cor3,libSkiaSharp}.so
KILL=ok（按 PID）   HEAVYSLOT=RELEASED rc=0
```

⇒ 产物里**没有**任何 WPF 件，全靠框架；Windows 上那把"框架"换成**官方**的即可（这正是"替代 runtime、不是替代 ref"的形态，§7.2）。

**（b）反向对照：只删件、不改 `deps.json`** ⇒ 逐字复现 §7.4 ② 的后果：

```bash
# appB = pristine 复制后 rm WindowsBase.dll（**不**跑脚本）
$ … dotnet WpfTextDemo.dll
Unhandled exception. System.IO.FileNotFoundException: Could not load file or assembly
'WindowsBase, Version=10.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35'. The system cannot find the file specified.
ALIVE=no
```

⇒ **"deps.json 与磁盘必须一致"这条不是理论**：脚本的第 3 步（同步 deps）是**必需**的。

**（c）l2 的收益在此兑现**：样本产物的 `AssemblyRef` 现取**逐字等于官方身份** ⇒ Windows 上锚定无歧义：

```
System.Xaml,      Version=10.0.0.0, PKT=b77a5c561934e089     ← L2 才对齐的 ECMA 令牌
WindowsBase,      Version=10.0.0.0, PKT=31bf3856ad364e35
PresentationCore, Version=10.0.0.0, PKT=31bf3856ad364e35
PresentationFramework, Version=10.0.0.0, PKT=31bf3856ad364e35
```

### §2.7 删除集 / 保留集的划界（脚本里写死、可复算）

| 组 | 成员 | 处置 | 依据 |
|---|---|---|---|
| **官方框架同名件**（21 托管） | 12 件 WPF ＋ 9 件 OOB BCL（`System.IO.Packaging` … `System.Windows.Extensions`） | **删**（dll+pdb）＋ 去 deps 登记 | 件名清单 = `~/.nuget/…/microsoft.windowsdesktop.app.ref/10.0.11/ref/net10.0/` 现读（`DirectWriteForwarder` 不在 ref 包、在官方 **runtime** 包 ⇒ 同让位） |
| **自产 ELF**（3） | `libwpfwin32.so` / `libwpfwic.so` / `wpfgfx_cor3.so` | **删**（若在） | Windows 加载不了；本样本的 L0 产物里其实**没有**它们（运行期走框架目录）⇒ 这条是稳健兜底 |
| **自产 Linux 专用件**（1） | `DirectWrite.Linux.Provider.dll` | **保留** | 官方**无同名对应**（非框架件遮蔽物）；缺它会 `FileNotFoundException: DirectWrite.Linux.Provider`（`FontFaceBridge.Install` 按名加载，实测）；Windows 上官方 `PresentationCore` 不走那条路 ⇒ 留着无害，且让同一份产物在 Linux 下自洽 |
| **第三方包**（SkiaSharp 图等） | `SkiaSharp.dll` / `runtimes/**` | **保留** | 不是框架件；删它会动第三方语义 |

---

## §3 ③ asmmeta 审计（扩展 API 面，逐件结论）

### §3.1 命令（§7.8 的原件）

```bash
REF=~/.nuget/packages/microsoft.windowsdesktop.app.ref/10.0.11/ref/net10.0
dotnet /tmp/wincompat/asmmeta/bin/Release/net10.0/asmmeta.dll pubadd <自产件> $REF/<同名件>.dll
```

### §3.2 逐件结论（现取）

| # | 件（自产 Release 权威源） | 新类型 | 新成员 | 结论 |
|---|---|---|---|---|
| 1 | `WindowsBase.dll` | **20** | **155** | 扩展面**全在** `Windows.Win32.*`（CsWin32 生成类型）；官方件没有这些**类** ⇒ 第三方库除非自己写了同名 `Windows.Win32` 类型，否则**不触** |
| 2 | `System.Xaml.dll` | 0 | 0 | **与官方一致** |
| 3 | `PresentationCore.dll` | **2** | **40** | 2 个新**类型**是本栈 shim：`WpfGfx.Linux.Bridge.MilCoreDllImportResolver`(5) ＋ `WpfLinux.Shims.PresentationCore.HbTextLineScaffold`(34)；1 个新**成员** `System.Windows.DataFormat::M:ToString` |
| 4 | `PresentationFramework.dll` | 0 | **2** | 两个 **protected** 成员：`WindowAutomationPeer::IsDialogCore`、`ItemsControl::OnCreateAutomationPeer`（官方 ref 里该类型无此名）⇒ 与"派生类"有关，**需逐库比对**（本仓两样本不触） |
| 5 | `PresentationFramework.Classic.dll` | 0 | 0 | **与官方一致** |
| 6 | `PresentationUI.dll` | 0 | 0 | **与官方一致** |
| 7 | `ReachFramework.dll` | 0 | 0 | **与官方一致** |
| 8 | `System.Printing.dll` | 0 | 0 | **与官方一致** |
| 9 | `System.Windows.Input.Manipulations.dll` | 0 | 0 | **与官方一致** |
| 10 | `UIAutomationTypes.dll` | 0 | 0 | **与官方一致** |
| 11 | `UIAutomationProvider.dll` | 0 | 0 | **与官方一致** |
| 12 | `DirectWriteForwarder.dll` | — | — | **`NOINFO`：官方对照件取不到**（ref 包**不含**该件；`Microsoft.WindowsDesktop.App.Runtime.win-x64` 未下载） |

`WindowsBase` 20 个新类型**逐一**：`Windows.Win32.Foundation.{BOOL,HANDLE,HINSTANCE,HMENU,HRESULT,HWND,LPARAM,LRESULT,WPARAM}`、`Windows.Win32.Graphics.Gdi.{BLENDFUNCTION,GdiHandleExtensions,HBITMAP,HDC,HENHMETAFILE}`、`Windows.Win32.System.Com.{DVASPECT,FORMATETC,STGMEDIUM,STGMEDIUM+_u,TYMED}`、`Windows.Win32.System.Ole.CLIPBOARD_FORMAT`（共 20；155 成员即这些类型自身的公开成员和）。

**结论口径**（照 §7.4 ③）：**"产物里若引用了自产件的扩展面，Windows（官方件）上会 `TypeLoad`/`MissingMethod`"** —— 所以判据是**"消费方有没有引用扩展面"**，不是"扩展面有几个"。

### §3.3 两个样本是否引用扩展面（现取）

```bash
$ for s in WpfTextDemo ThirdPartyMini; do \
    dotnet …/asmmeta.dll memrefs samples/$s/bin/Release/net10.0/$s.dll \
    | grep -iE "Windows.Win32|HbTextLineScaffold|MilCoreDllImportResolver|DirectWrite.Linux"; done
（空）
```

⇒ **两个样本（`WpfTextDemo` / `ThirdPartyMini`，均实测 `memrefs` 0 命中）不引用**任何扩展面 ⇒ 换官方件**安全**。第三方库需**逐库比对**（工具已就位，命令见 §3.1）。

---

## §4 ④ 回归：L2 绑定 ＋ L1 e2e 不回退

### §4.1 L1 框架目录

```bash
$ bash build/third-party/windowsdesktop-app-linux-framework.sh install --force   # 换身份/换 shim 后重装（12 件随动）
install rc=0
$ bash build/third-party/windowsdesktop-app-linux-framework.sh verify
VERIFY=PASS (25/25 与权威件逐字节相同)
```

### §4.2 L1 e2e（**未改 runtimeconfig**）

```bash
$ bash ~/heavy-slot.sh --min-avail 2500 --max-hold 900 --wait 1800 -- \
    bash build/third-party/windowsdesktop-app-linux-framework-e2e.sh --display :233
runtimeconfig.frameworks = ['Microsoft.NETCore.App', 'Microsoft.WindowsDesktop.App']
app-local dll            = ['DirectWrite.Linux.Provider.dll', 'SkiaSharp.dll', 'WpfTextDemo.dll']
框架件是否 app-local     = False
-- AssemblyRef（自产身份）--
System.Xaml, Version=10.0.0.0, …, PublicKeyToken=b77a5c561934e089
WindowsBase/PresentationCore/PresentationFramework, Version=10.0.0.0, …, PKT=31bf3856ad364e35
ALIVE=yes    window: 938x938 colors=3130
WPTD_SCROLL_RANGE=extent=926.4 viewport=717.1 scrollable=209.2 bar=Visible offset=0.0
-- .so 落点（/proc/<pid>/maps）-- （4 个 .so 全从框架目录加载）
KILL=ok（按 PID）   HEAVYSLOT=RELEASED rc=0
```

### §4.3 L2 库包绑定（`/tmp/tb5-probe`，正极性）

```bash
$ cd /tmp/tb5-probe/Probe/bin/Release/net10.0-windows && dotnet Probe.dll \
    /tmp/tb5-probe/LibConsumer/bin/Release/net10.0-windows/LibConsumer.dll ; echo RC=$?
LOAD OK   req=PresentationFramework,4.0.0.0,… -> got=10.0.0.0 …
LOAD OK   req=PresentationFramework,4.0.0.1,… -> got=10.0.0.0 …
LOAD OK   req=PresentationFramework,8.0.0.0,… -> got=10.0.0.0 …
LOAD OK   req=PresentationFramework,10.0.0.0,… -> got=10.0.0.0 …
LOAD OK   req=System.Xaml,10.0.0.0,PKT=b77a… -> got=10.0.0.0 PKT=b77a5c561934e089 …
LOAD OK   req=System.Windows.Input.Manipulations,10.0.0.0,PKT=b77a… -> got=10.0.0.0 PKT=b77a5c561934e089 …
LIBCONSUMER OK   PresentationFramework, Version=10.0.0.0, …, PublicKeyToken=31bf3856ad364e35
RC=0
```

### §4.4 两牙 ＋ 指纹

```bash
$ bash build/MilBridge/tools/defect-registry-check.sh | tail -1
DEFREG=PASS declared=225 route_ids=225（…）      # rc=0
$ bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
REPORTID=PASS files=354 ids=2265 declared=225 glob=build/MilBridge/*report*.md   # rc=0
$ python3 build/artifact-src-fp.py --check
ARTIFACT_SRC_FP proj=PresentationCore     … state=ok
ARTIFACT_SRC_FP proj=WindowsBase          … state=ok
ARTIFACT_SRC_FP proj=PresentationFramework … state=ok
```

（`artifact-src-fp.py --check` 改后先报这 3 件 `state=stale` —— `WindowsBase`/`PresentationCore` 是**源变了**，`PresentationFramework` 是**被引产物变了**；按波规矩重建下游链后 `--write` 刷新。）
**未跑整趟 `verify-all`**（任务边界）；未动 `upstream/**`、`verify-all.sh`、`build/close-wave.sh`、`build/MilBridge/tools/**`。

---

## §5 改动清单与 `sha16` 位移

### §5.1 改动文件（`git status --short` 现取）

```
 M build/shims/Win32ShimResolver.cs              # ① shim 短路（+23 行）
 M build/WindowsBase.Linux/ARTIFACT-SRC-FP.txt   # 指纹刷新（ⓘ）
 M build/PresentationCore.Linux/ARTIFACT-SRC-FP.txt
 M build/PresentationFramework.Linux/ARTIFACT-SRC-FP.txt
?? build/third-party/windowsdesktop-app-win-export.ps1   # ② 导出脚本（新增）
?? build/MilBridge/P1-wininteropL3-impl-report.md        # 本报告
```

（`?? build/MilBridge/tasks-tail2/T-B6.md` 是**任务书**，非本轮所为。）
**没碰**：`upstream/**`、`verify-all.sh`、`build/close-wave.sh`、`build/MilBridge/tools/**`、`src/**`、`samples/**`。

### §5.2 12 件 `sha16` 位移（权威源 `bin/Release`；`—` = 未变）

| 件 | 改前 | 改后 | 移位原因 |
|---|---|---|---|
| `WindowsBase.dll` | `6b8fceaf70d4a71d` | **`f0cfe3a877c6bf16`** | 源（shim） |
| `PresentationCore.dll` | `7d680fade8d665e6` | **`c4f20e0d1b5ea339`** | 源（shim） |
| `UIAutomationTypes.dll` | `f3f0fb8302e73349` | **`0524d6cc8e5e7512`** | 源（shim） |
| `UIAutomationProvider.dll` | `0a710c5b21f4ad9e` | **`e8fc2b0de550a964`** | 源（shim） |
| `PresentationFramework.dll` | `a708ae46f59317aa` | **`632a4d6a9ef92942`** | 被引产物变了（下游链，实测：重建即换字） |
| `PresentationFramework.Classic.dll` | `58cb7cfb232610e3` | **`9b5a2ab7189ca728`** | 同上 |
| `PresentationUI.dll` | `94702615e29e0f63` | **`9366ca705a6bc210`** | 同上 |
| `System.Printing.dll` | `704d6c5f65e1fcce` | **`74301e528e5dfd15`** | 同上 |
| `System.Xaml.dll` | `43424428b860cd8d` | `43424428b860cd8d` | — |
| `System.Windows.Input.Manipulations.dll` | `78ac68ad0ddde028` | `78ac68ad0ddde028` | — |
| `ReachFramework.dll`（CycleStub） | `2181e8d02a2d84c8` | `2181e8d02a2d84c8` | — |
| `DirectWriteForwarder.dll` | `0b66bb775c7037d8` | `0b66bb775c7037d8` | — |

**Debug** 同趟重建（供样本 csproj 的 `bin/Debug` 引导引用；L2 §7 已登记的既有形态）：`WindowsBase 1a89511f3bb67584→b4b532250e0fef53`、`PresentationCore 33e35916034f2c3b→5811a612d2a89550`、`UIAutomationTypes f15e2ba2afd9ec1e→8711e3b1d3320f6c`、`UIAutomationProvider e037927997a73d2a→15be7ed11d490d2c`，及下游 `PresentationFramework b2812927fd643c32→27e5dcd1eb784b39`、`PresentationFramework.Classic b3efe1e0991c2a1e→b772655e24d932a3`、`PresentationUI e347207d17a7b926→fcfbbe7bdc23f5fb`、`System.Printing f2cda96d33cba873→c7b57d72d16875fa`。**身份未变**（`ident` 现取 4/4 仍 `10.0.0.0`）。

> ⚠️ 这 8 件是**产品件**（`WIN-INTEROP.md` 的"12 件"点名表内），按本仓"九位"规矩属**会动的读点**：任何按旧 `sha16` 冻结的判据都要按现场重取；仓外框架目录已按新件**重装并 `verify 25/25`**。

### §5.3 重建面

```
直接（源=shim）：WindowsBase → PresentationCore → UIAutomationTypes → UIAutomationProvider
下游（被引产物变了）：System.Printing → CycleStub.PresentationFramework → CycleStub.ReachFramework
                    → CycleStub.PresentationUI → PresentationFramework → PresentationFramework.Classic
                    → ReachFramework（自举件）
两配置都做（Release 权威 ＋ Debug 供样本引导引用）；每个工程 **0 错 0 警**（逐工程现取）。
```

---

## §6 具名 `NOINFO` / 待裁决 / 主动披露

1. **`NOINFO(reason=真 Windows 端到端本机不可得)`**：本机无 `Microsoft.WindowsDesktop.App.Runtime.win-x64`、无 wine（与 `WIN-INTEROP.md` §7.7 同）⇒ **"在真 Windows 上跑通导出后的产物"这一格本机无法取得**。本报告**不含任何 Windows 侧读数**；§2.6 给的是**同机（Linux + 自产框架）**上的形态自洽证据 ＋ `sha16`/`ident` 现取。
2. **`NOINFO(reason=DirectWriteForwarder 官方对照件不可得)`**：`asmmeta pubadd` 需要官方同名件，而 `Microsoft.WindowsDesktop.App.Ref` **不含** `DirectWriteForwarder.dll`、runtime 包未下载 ⇒ 该件**扩展面未审**（§3.2 #12）。
3. **`NOINFO(reason=exp1 最小样例本波未复跑)`**：L1 §7 已登记 exp1 的"文本像素未定位"；本轮未触及该现象（L3 不新增文本面）。
4. **待裁决 · 导出脚本的"删除集"是否该收/放**：本实现取"**官方框架同名件（21）＋ 自产 ELF**"，保留 `DirectWrite.Linux.Provider.dll`（理由见 §2.7）。若主控认为导出形态应"更彻底地像官方产物"（连 Linux-only provider 也清），改一处数组即可 —— **本报告不作裁决**。
5. **待裁决 · `WIN-INTEROP.md` §7.4/§7.5 的"待做"语气**：§7.5 把 L3 记成"可选 / 成本 shim 1 行短路 ＋ 1 个脚本 ＋ asmmeta 审计" —— 本波三件**都已落地**（含 L2 前置）。建议同趟把 §7.4 ① 的"1 行"补一句"**已落地：`build/shims/Win32ShimResolver.cs:228-229`**"、§7.5 L3 行标注"**已完成**，导出脚本 = `build/third-party/windowsdesktop-app-win-export.ps1`"。**本报告不改规格，留档。**
6. **如实登记 · 导出脚本形态可被本机复算**：选 `.ps1`（§7.4 ② 的"bat/ps1"之一）而非 bat，正是为了**本机（pwsh 7.6.6）能逐命令复算**（文件操作跨平台；§2.2-§2.6 全是本机现取）。在真 Windows 上命令同形。
7. **与 §7.4 末段一致的事实陈述**：替换之后 **Windows 上跑的是官方 WPF，不是本栈实现** —— 所谓"双向互跑"实际是"一份源码/一份产物形态，两边各用各自的原生 WPF"，**不是**"一份二进制、两边同一实现"。

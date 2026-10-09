# 任务 B 完成报告：把自产 WPF 栈包化成 NuGet 包（MVP）

> 任务书：`.agents/tasks/B-wpflinux-sdk-package.md`
> 结论：**MVP-1 全绿（含运行）**；**MVP-2 全绿（编译 0 错误 + 起窗口）**，但有一处"不算包化"的残留（见 §3.6）。

## 1. 交付物（全部为新增文件）

| 位置 | 文件 |
|---|---|
| `WPFOnLinux/src/Linux/build/third-party/pkg/` | `WpfLinux.Sdk.csproj`、`PackageMarker.cs`、`buildTransitive/WpfLinux.Sdk.props`、`buildTransitive/WpfLinux.Sdk.targets`、`README.md` |
| `WPFOnLinux/src/Linux/samples/WpfLinuxSdkProbe/` | `WpfLinuxSdkProbe.csproj`、`App.xaml(.cs)`、`MainWindow.xaml(.cs)`、`nuget.config`、`README.md`、`evidence/*` |
| `RT/Links-ICD-Kit/PortWpfLinux/ICDStudioSdkProbe/` | `ICDStudioSdkProbe.Port.csproj`、`srctree`(符号链接)、`FodyWeavers.xml(.xsd)`、`nuget.config`、`README.md`、`evidence/*` |

**未改动**任何既有文件（`git status` 里只有 `pkg/`、`WpfLinuxSdkProbe/` 两个未跟踪目录；`src/WpfGfx.Linux.Native/src/win32_core.c` 的改动 mtime 是 10-06，早于本任务）。

## 2. 验收项 → 证据映射

### MVP-1（必达）

| # | 判据 | 读数 | 证据 |
|---|---|---|---|
| 1 | `*.nupkg` 落盘 | `WpfLinux.Sdk.1.0.0.nupkg`，**7 616 980 B**，`sha256=5405fed260f7d2e3…` | `pkg/out/` |
| 2 | 样板接入 ≤8 行、无绝对 `HintPath` | 非空行 **8**；`grep -c HintPath` = **0** | `WpfLinuxSdkProbe.csproj` |
| 3 | `dotnet build -v:m` 0 错误 | **0 错误 / 0 警告** | `evidence/mvp1-build.log` |
| 4 | 产物 + `deps.json` 身份来自包 | `bin/Debug/net10.0/WpfLinuxSdkProbe.dll` 存在；`deps.json` 里 15 个件全部挂 `WpfLinux.Sdk/1.0.0` 的 `lib/net10.0/…`；身份 `WindowsBase/PresentationFramework = 4.0.0.1 / 31bf3856ad364e35`、`System.Windows.Extensions = 9.0.0.0 / 31bf…` | `evidence/mvp1-deps.txt` |
| 5 | **不带任何 `-p:`** 的 `-t:Rebuild` 仍 0 错误 | **0 错误 / 0 警告**；且 XAML 临时工程取证：`*_wpftmp.csproj` 的 `ReferencePath` 全指 `…/wpflinux.sdk/1.0.0/lib/net10.0/…` | `evidence/mvp1-rebuild.log`、`evidence/mvp1-wpftmp.txt`、`wpftmp.csproj.sample` |

> 额外（超出判据）：**仓外运行** `/tmp/probe1/app` ⇒ `ALIVE_AFTER_12S=yes COLORS=216`（窗口起来了，非全黑）。
> 见 `evidence/mvp1-run.log`、`mvp1-shot.png`、`mvp1-run-result.txt`。

### MVP-2（可选）

| # | 判据 | 读数 | 证据 |
|---|---|---|---|
| 6 | 包化接入的 ICDStudio 等价工程编译 0 错误（**无 `-p:`**） | **0 错误 / 1041 警告**，命令 `dotnet build ICDStudioSdkProbe.Port.csproj -v:m` | `ICDStudioSdkProbe/evidence/mvp2-build.log` |
| 7 | `dotnet <产物>.dll` 启动到出现窗口（存活 ≥10s） | 仓外 `/tmp/icdprobe/app`：`ALIVE_AFTER_12S=yes COLORS=226`；同环境同部署的**现状 ICDStudio** 对照读数 `12s / 226 色` | `ICDStudioSdkProbe/evidence/mvp2-run.log`、`mvp2-shot.png`、`mvp2-run-result.txt` |

### 复跑

```bash
export PATH="$HOME/.dotnet:$PATH"
cd WPFOnLinux/src/Linux/build/third-party/pkg && dotnet pack WpfLinux.Sdk.csproj -c Release -o out
bash /tmp/mvp1-verify.sh                       # 或在 samples/WpfLinuxSdkProbe 手工两步 build
export PortWpfRefsMode=selfbuilt               # 只有 MVP-2 需要（见 §3.6）
bash RT/Links-ICD-Kit/PortWpfLinux/ICDStudioSdkProbe/evidence/mvp2-verify.sh
```

验证脚本随证据一起落盘在各自 `evidence/` 下（`mvp1-verify.sh` / `mvp2-verify.sh` / `exp-*.sh` 为失败留档）。

## 3. 主动披露

1. **任务书「已在事实」与现场不符（1 处）**：聚合目录
   `…/src/CycleStub.PresentationFramework/bin/Release/PresentationFramework.dll` 是 **12 800 B 的桩件**
   （只引用 `PresentationCore`/`WindowsBase`），真件 **6 180 352 B** 在 `…/src/PresentationFramework/bin/Release/`。
   其余 7 件与聚合目录逐字节相同（已比对 sha256）。包因此改成"每个组件取自己的 `bin/Release`"。
2. **技术判断 1（wpftmp 生效）成立，但机制与描述不同**：Microsoft.WinFX.targets 会把主工程的
   `*.nuget.g.props/.targets/.dgspec.json` **显式复制**成 `<proj>_<rand>_wpftmp.csproj.nuget.g.*`
   再注入临时工程；而且临时工程直接复用主工程 RAR 的 `ReferencePath`。⇒ 身份一致比"props 生效"更直接。
   取证：`evidence/mvp1-wpftmp.txt`。
3. **技术判断 2 被推翻：包内 lib 用的是自产真件（4.0.0.1），不是 `xamlrefs/` 改版件（10.0.0.0）。**
   依据：`RT/…/REPORT-治全黑.md` §C 实测改版件会让运行期与编译期身份分裂（窗口全黑），而自产 PBT 已支持
   "按名回退"，真件能直接编译。任务书写的"退回 selfbuilt 真件"就是本方案。
4. **技术判断 3 部分推翻**：RID native assets **确实**部署到了 `bin/…/runtimes/linux-x64/native/`，
   但 `Win32ShimResolver` 只在 **app 根目录**找 `libwpfwin32.so` ⇒ 包内加了
   `WpfLinuxSdkDeployNativeShims`（`AfterTargets=Build`，把它复制到 `$(OutDir)`）。
   反证据（仓外干净目录）：`DllNotFoundException: …'kernel32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库`。
5. **`System.Windows.Extensions` 要"切断传递"才干净**：只写 `ExcludeAssets` 没用（`System.Security.Permissions 9.0.0`
   在 net8/net9 组里依赖官方 SWE）。包改成"`PackageDownload` 取 Permissions 的 dll + 自带进 lib"，
   把官方 SWE 从依赖图里彻底摘掉（`nuspec` 里已无 SWE 条目）。
6. **MVP-2 有一处"不算包化"的残留（最重要的披露）**：本工程依赖的 4 个 WPF 工程仍是仓内配方 wrapper，
   它们用 `PortWpfRefsMode` 选引用身份，而该属性**无法通过包传播**：
   * `ProjectReference` 的 `AdditionalProperties` 只对**直接**子工程生效，不递归 ⇒ `Common.Resources` 走 repack 默认
     ⇒ **878 个 `CS0103`**（`/tmp/exp-b.log`）；
   * 把 `Common.Resources` 也列成直接引用 ⇒ 与 `LicenseManagerGUI` 的引用撞车、同一工程被并发构建两次
     （Fody 抢 `CommonExt.pdb`，`IOException`）⇒ 仍失败。
   最终靠 **环境变量** `export PortWpfRefsMode=selfbuilt`（**不是 `-p:`**）统一整图才通过。
   ⇒ **"包化尚未覆盖全树"时的真实边界：入口工程可以只写一行 `PackageReference`，但既有 wrapper 依赖仍要求在入口处给一次 `PortWpfRefsMode`。**
7. **包不含官方借用件**（Ribbon / WinForms 系 7 件）：它们是"业务代码真用到才需要"的可选件，与 WPF 栈无关。
   MVP-2 里按老配方引 `PortWpfLinux/refruntime`；少 Ribbon 会在运行期 `Assembly.Load` 失败、应用起不来。
8. **另一条传递性坑**：依赖 wrapper 里的 `PackageReference System.Windows.Extensions ExcludeAssets="compile;runtime"`
   **只在它自己工程里生效**，作为依赖流到入口工程就不再排除 ⇒ 官方 SWE 盖掉包里的替身，
   运行期 `PlatformNotSupportedException: System.Windows.Extensions types are not supported on this platform`。
   入口工程必须再排除一次。
9. **未覆盖**：`dotnet publish` / 单文件 / 非 `linux-x64` RID；包对 `net10.0-windows` 只做了兼容性使用（MVP-2 用的就是它）；
   MVP-2 只验"能起 + 有色画面"，未验界面完整与业务功能（`PortShotHook` 未挂载、登录流程未驱动）；
   运行期 `libwpfwin32.so` 依赖"与 app 同目录"的部署布局（包已代劳，但若消费方自行搬运产物需注意）。
10. **包版本策略**：版本写死 `1.0.0`，改包后 NuGet 会命中 `~/.nuget/packages/wpflinux.sdk` 的旧包 ⇒ 必须
    `rm -rf ~/.nuget/packages/wpflinux.sdk` 或 bump 版本（本任务所有复跑脚本都先清缓存）。

## 4. 自包含结论

* **背景**：消费方每个 WPF 工程都要写 ~30 行 wrapper 接线（自产件 `HintPath`、OOB 包、PBT 路径、身份替换），
  12 份；且 `PortWpfRefsMode` 设在 wrapper 里传不到 XAML 临时工程。
* **做了什么**：把"自产引用件（lib/net10.0）+ 自产 PBT（tools/net10.0）+ 原生库（runtimes + 复制到输出根）
  + 接线（buildTransitive props/targets）+ OOB 依赖（nuspec）"打成一个包 `WpfLinux.Sdk 1.0.0`（7.6 MB）。
  消费方一行 `PackageReference` + 自己的 `TargetFramework` 即可编译。
* **验证了什么**：MVP-1：干净首次构建 0 错 0 警、无 `-p:` 的 Rebuild 0 错、`deps.json` 身份全是包内自产真件、
  wpftmp 取证身份一致、仓外运行存活 ≥12s/216 色。MVP-2：ICDStudio 等价工程（0 错误）仓外运行存活 ≥12s/226 色，
  与现状产物同环境对照一致。
* **遗留什么**：①既有 WPF wrapper 未包化 ⇒ `PortWpfRefsMode` 仍需在入口给一次（环境变量）；
  ②官方借用件与 SWE 的二次排除仍是"老配方残留"；③`publish`/多 RID/界面完整未验。

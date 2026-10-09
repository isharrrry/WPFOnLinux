# 任务 B-R2 完成报告：包化覆盖依赖链 —— 真实工程"零外部设置"即可编译

> 任务书：`.agents/tasks/B-R2-full-tree-package.md`
> 结论：**判据 1~5 全部成立**。`ICDStudioSdkProbe` 在**不设任何环境变量、不带任何 `-p:`** 下
> `dotnet build` / `-t:Rebuild` 均 **0 错误**，仓外运行存活 ≥12s、画面 226 色（与现状 ICDStudio 对照读数一致）。
> 依赖链上的 6 个 WPF 工程已改成"包化接入"（`*.Sdk.csproj`），`PortWpfRefsMode` 整图**不再需要**。

---

## 1. 交付物

| 类别 | 位置 |
|---|---|
| **修改**（包能力） | `WPFOnLinux/src/Linux/build/third-party/pkg/buildTransitive/WpfLinux.Sdk.props`（加：源码树模式 + 官方借用件） |
| **修改**（包） | `WPFOnLinux/src/Linux/build/third-party/pkg/WpfLinux.Sdk.csproj`（把借用件打进 `borrow/`）、`pkg/README.md` |
| **新增**（依赖链包化工程 6 个） | `RT/Links-ICD-Kit/PortWpfLinux/APPGuarder/APPGuarder.Sdk.csproj`<br>`RT/Links-ICD-Kit/PortWpfLinux/Config/Config.Sdk.csproj`<br>`RT/Links-ICD-Kit/PortWpfLinux/ICDLite/ICDLite.Sdk.csproj`<br>`RT/Links-ICD-Kit/PortWpfLinux/AgentRT/AgentRT.Sdk.csproj`<br>`RT/Links-License-Mgr/PortWpfLinux/LicenseManagerGUI/LicenseManagerGUI.Sdk.csproj`<br>`RT/Links-License-Mgr/PortWpfLinux/Common.Resources/Common.Resources.Sdk.csproj` |
| **修改**（入口） | `RT/Links-ICD-Kit/PortWpfLinux/ICDStudioSdkProbe/ICDStudioSdkProbe.Port.csproj`（改指包化版依赖 + 用包的新能力；文件名保持不变，判据命令照旧）、同目录 `README.md` |
| **证据** | `RT/Links-ICD-Kit/PortWpfLinux/ICDStudioSdkProbe/evidence/{r2-verify.sh,r2-results.txt,r2-verbatim-summary.txt,r2-build.log,r2-rebuild.log,r2-run.log,r2-shot.png,port-regress.log,mvp1-regress.log}`（`*.log` 被仓 `.gitignore` 忽略，故读数另存 `r2-results.txt`） |

**一个字节都没动的**：`WPFOnLinux` 既有文件（只改了 `pkg/` 内 3 个：`WpfLinux.Sdk.csproj`、
`buildTransitive/WpfLinux.Sdk.props`、`README.md`）；`RT/Links-*` 既有的 12 个 `*.Port.csproj`
（13 个里只有任务书**允许**改的 `ICDStudioSdkProbe.Port.csproj` 被改）；任何业务源码；
两棵 `PortWpfLinux` 树的 `NuGet.config` / `Directory.Build.props` / `PortWpf.Wrapper.*` /
`PortXamlRefs.props` / `PortRuntimeRefs.props`。既有 `*.Port.csproj` **保持可用**（见 §2 附加回归）。

---

## 2. 验收项 → 证据映射

### 判据 1（核心）：零外部设置编译

```
$ export PATH="$HOME/.dotnet:$PATH"; unset PortWpfRefsMode
$ cd RT/Links-ICD-Kit/PortWpfLinux/ICDStudioSdkProbe; rm -rf obj bin
$ dotnet build ICDStudioSdkProbe.Port.csproj -v:m
...
    947 个警告
    0 个错误

已用时间 00:00:34.89          rc=0     # 命令里没有 -p:；环境里没有 PortWpfRefsMode
```

原始日志：`evidence/r2-build.log`（`grep -c "error" → 0`）。
（该 log 由 `evidence/r2-verify.sh` 产生；脚本在构建前多做一步
`rm -rf ~/.nuget/packages/wpflinux.sdk` —— 见 §4.1，不改判据本身。）
另有一次**逐字复跑（不额外清缓存，只 `unset PortWpfRefsMode; rm -rf obj bin` 后直接 build）**：
`build → 0 错误 / 947 警告`、`-t:Rebuild → 0 错误 / 1204 警告`，
读数同上，见 `evidence/r2-verbatim-summary.txt`。

### 判据 2：同命令 `-t:Rebuild`

```
$ dotnet build ICDStudioSdkProbe.Port.csproj -t:Rebuild -v:m
    1204 个警告
    0 个错误
已用时间 00:00:40.35          rc=0
```

原始日志：`evidence/r2-rebuild.log`。**整图重建后仍 0 错误** ⇒ 不是 wpftmp 缓存掩盖的假绿
（取证：`bin/Debug/net10.0-windows/*.deps.json` 里 15 个自产件全挂 `WpfLinux.Sdk/1.0.0` 的 `lib/net10.0/…`）。

### 判据 3：接入行数（逐项记录）

计数口径：**非注释、非空、且非"工程特有清单/特有属性"**（清单＝`ItemGroup` 里的
`Compile/Page/ApplicationDefinition/Resource/Content/ProjectReference/第三方 PackageReference`；
特有属性＝`TargetFramework/AssemblyName/RootNamespace/ApplicationIcon/ImplicitUsings/Nullable/
SatelliteResourceLanguages/NoWarn`）。下表"接入行"逐字列出，便于复核：

| 工程 | 接入行（逐字） | 行数 | 备注 |
|---|---|---|---|
| `ICDStudioSdkProbe` | `<WpfLinuxSrcTree>…/srctree</WpfLinuxSrcTree>`<br>`<WpfLinuxOfficialBorrows>true</WpfLinuxOfficialBorrows>`<br>`<PackageReference Include="WpfLinux.Sdk" Version="1.0.0" />`<br>`<EnableDefaultCompileItems>false</EnableDefaultCompileItems>`<br>`<EnableDefaultNoneItems>false</EnableDefaultNoneItems>`<br>`<EnableDefaultContentItems>false</EnableDefaultContentItems>` | **6** ✅≤12 | 全文件 84 行；非注释非空行 63（= 上表 6 行接入 + 8 行特有属性 + 49 行结构标记/特有清单） |
| `APPGuarder.Sdk` | `PackageReference WpfLinux.Sdk`、`WpfLinuxSrcTree`、`WpfLinuxSrcTreeExclude`、`EnableDefaultCompileItems`、`RestoreAdditionalProjectSources`、`BaseIntermediateOutputPath`、`BaseOutputPath` | 7 | 全文件 51 行；非注释非空 34 |
| `Config.Sdk` | 同上 7 项 | 7 | 全文件 36 行；非注释非空 24 |
| `ICDLite.Sdk` | 同上 7 项 + `WpfLinuxOfficialBorrows` | 8 | 全文件 57 行；非注释非空 41 |
| `AgentRT.Sdk` | 同上 7 项 | 7 | 全文件 47 行；非注释非空 34 |
| `LicenseManagerGUI.Sdk` | 同上 7 项 | 7 | 全文件 40 行；非注释非空 27 |
| `Common.Resources.Sdk` | 同上 7 项 + `WpfLinuxSrcTreePageExclude` + `WpfLinuxOfficialBorrows` | 9 | 全文件 80 行；非注释非空 58 |

其中 3 项值得点明：
* `BaseIntermediateOutputPath`/`BaseOutputPath`（`obj/Sdk/`、`bin/Sdk/`）是**硬约束不是可选**：
  同目录两个工程共用一个 `obj/` 会互相盖掉 `project.assets.json`（`ICDStudioSdkProbe` 目录里只有一个入口工程，故不需要）。
* `RestoreAdditionalProjectSources` = `$(WpfLinuxRoot)/src/Linux/build/third-party/pkg/out`（1 行）：
  这两棵树既有的 `NuGet.config` 里没有自产包源，**不改既有配置**、按工程追加。
* `WpfLinuxSrcTreeExclude`/`WpfLinuxSrcTreePageExclude` 是"这个工程的清单长什么样"的声明，不是接线。

### 判据 4：无绝对 `HintPath`（指向 `WpfLinuxRepoRoot` 的计数 = 0）

```
$ grep -rn "HintPath"  <6 个 *.Sdk.csproj> <ICDStudioSdkProbe.Port.csproj>   → 无匹配
$ grep -rn "WpfLinuxRepoRoot" <同上>                                          → 无匹配
```

借用件（Ribbon / WinForms 系 7 件）**已进包**（`WpfLinux.Sdk.1.0.0.nupkg` 的 `borrow/`），
所以工程侧一行 `WpfLinuxOfficialBorrows` 取代了原来的 7 组绝对 `HintPath`。
包内的 `borrow/*.dll` 是**唯一**的 `HintPath` 去处，且它指的是包根（`$(WpfLinuxSdkPackageRoot)`），不是仓根。

### 判据 5：运行

```
ALIVE_AFTER_12S=yes COLORS=226          # /tmp/icdsdk/app，Xvfb :95 1280x1024x24
```

原始日志/截图：`evidence/r2-run.log`、`evidence/r2-shot.png`（10640 B）。
对照：`evidence/mvp2-run-result.txt` 里**现状 ICDStudio.dll** 同环境读数是 `12s / 226 色` ⇒ 一致。

### 附加回归（超出判据，但"保持可用"是边界条款）

| 回归项 | 命令 | 读数 | 日志 |
|---|---|---|---|
| 既有 wrapper 仍可用 | `dotnet build ICDStudio.Port.csproj`（`PortWpfRefsMode=selfbuilt`，仓库最全那棵树） | **0 错误** / 1096 警告 | `evidence/port-regress.log` |
| MVP-1 仍绿（包被我改过） | `dotnet build WpfLinuxSdkProbe.csproj`（`samples/WpfLinuxSdkProbe`，无 `-p:`） | **0 错误 / 0 警告** | `evidence/mvp1-regress.log` |

---

## 3. "依赖链"到底改了哪几个工程（按真实引用图补齐）

`ICDStudioSdkProbe`（= ICDStudio）下的 WPF 栈引用闭包不是任务书建议的 4 个，**实际是 6 个**：

```
ICDStudio ── APPGuarder ── Config ─┐
          ├─ ICDLite ─── AgentRT ─┤
          ├─ LicenseManagerGUI ───┼─ Common.Resources ─ CommonExt / Common.AbsResource（netstandard，不涉 WPF）
          └─ （DbcParserLib / Lib* / ICDConverter：原 csproj，不涉 WPF，保持直引）
```

⇒ 新增 `Config.Sdk`、`AgentRT.Sdk`（任务书只列了 4 个），这两个也在闭包里。
**为什么不"只包化真正出问题的那 2 个"**：分叉点确实只有 `Common.Resources` / `LicenseManagerGUI`
（Links-License-Mgr 侧 wrapper **不声明** `PortWpfRefsMode` ⇒ 走 `PortXamlRefs.props` 的 `repack` 默认；
Links-ICD-Kit 侧 4 个 wrapper 各自声明了 `selfbuilt` 默认）。但那样整图会是"半包化 + 半配方"：
能过只是**碰巧**因为配方默认值等于包的身份，任何一处默认值/配方改动就会再分叉，而且入口要混引
`.Port` 与 `.Sdk` 两类身份来源。全包化后"引用身份只有一个来源（包）"是**可核对**的
（6 个工程的 `project.assets.json` 里 15 个自产件全指包）；这也正是原任务要根除的东西。

**为什么这样就成立**（根因对照）：原来的病根是"引用身份由**每个工程自己的配方**（`PortWpfRefsMode`）决定"，
而该属性不随 `ProjectReference` 递归 ⇒ 整图必然分叉。现在身份只由**包**一份决定
（`lib/net10.0/` = 自产真件 4.0.0.1 / 31bf3856ad364e35），每个包化工程的 `project.assets.json` 里
`System.Xaml`/`WindowsBase`… 15 个编译资产**全部**指向 `…/wpflinux.sdk/1.0.0/lib/net10.0/`
（6 个工程逐个核对，读数一致）⇒ 不可能分叉。

---

## 4. 主动披露（仍做不到的事 + 成因）

1. **包版本写死 `1.0.0`，重打包后必须清缓存**：`rm -rf ~/.nuget/packages/wpflinux.sdk`。
   这是 B 轮已知事实的延续。我没有 bump 版本，因为 `samples/WpfLinuxSdkProbe/WpfLinuxSdkProbe.csproj`
   写的是 `Version="1.0.0"`，而它在"禁止改动"的 `WPFOnLinux` 既有文件里。**本机缓存已刷新为新包**
   （最后一次 restore 之后就是新包），所以按判据命令直接复跑即可；换机器/换包必须清缓存。
2. **`WpfLinuxSrcTree` 模式只覆盖 `Compile`/`Page`/`ApplicationDefinition`/`EmbeddedResource(*.resx)`，
   不覆盖 `Resource`/`Content` 的图片/字体/数据文件**：这些的"是不是嵌入、叫什么资源名、要不要拷到输出"
   是逐工程的（`Common.Resources` 把 `**/*.txt` 当 `Resource`，`ICDStudio` 把 `Help/*.txt` 当 `Content`），
   通用默认必然出错，所以留给工程自己列（`Resource` 1~5 行）。这是**有意的边界**，不是遗漏。
3. **警告构成：`MSB3277`（程序集版本冲突）是主体**。根源是借用件（官方 ref pack 身份 `10.0.0.0`）
   引用 `PresentationFramework 10.0.0.0`，而包给的是自产真件 `4.0.0.1`；RAR 固定选"主版本"
   = 自产真件（正确的那一个）。日志里含 `MSB3277` 的行共 1900 条（同一批警告会在 wpftmp 那一趟
   再打印一次），MSBuild 自己的汇总读数是 **947 个警告**（判据 2 的整图重建是 1204 个）。
   这是 B 轮同一套借用件就存在的既有噪音（B 轮 MVP-2 读数 1041 个警告，同一量级）。没有去压它：
   压它要么得 `-p:NoWarn=`（判据禁止），要么改 `MSBuildWarningsAsMessages` 把真信号一起吞掉。
4. **借用件只有元数据**：`borrow/` 是"官方引用件去掉 `ReferenceAssemblyAttribute`"，方法体是空实现。
   XAML 解析时"按类型名找程序集"这一步能被满足（所以应用起得来、画面 226 色），
   真去**执行** Ribbon/WinForms 的 API 仍无实现（与 B 轮一致，非本次新增边界）。
5. **`System.Windows.Extensions` 传递坑：本次自动解决了，但只对"官方版本更低"的图成立**。
   包化后依赖工程不再引 `System.Security.Permissions 9.0.0`（原来那句 `PackageReference` 是仓内配方带的），
   官方 SWE 只剩第三方的 `7.0.0`；运行期解析结果是包内自产替身：
   ```
   deps.json:  System.Windows.Extensions/7.0.0     runtime = []          ← 官方包无资产
               WpfLinux.Sdk/1.0.0                  → lib/net10.0/System.Windows.Extensions.dll  ← 生效的是这份
   sha256(输出根/System.Windows.Extensions.dll) = c34c8d12… = 自产替身（≠ 官方 7.0.0/9.0.0 任一）
   ```
   ⇒ 入口工程**不再需要**那句 `ExcludeAssets="compile;runtime"`（已删）。
   **但**：若某个消费方图里官方 SWE 的版本 ≥ 自产替身的 `9.0.0.0`，这条链仍可能被盖掉 —— 未构造该场景验证。
6. **每个 `*.Sdk.csproj` 把中间/输出目录挪到 `obj/Sdk/`、`bin/Sdk/`**：同目录两个工程不能共用一个 `obj`
   （`project.assets.json` 会互相覆盖）。代价是这 3 行看起来像"接线"，其实是同目录并存的必需隔离。
   副作用：`bin/Sdk/Debug/…` 是独立目录，**.Port 与 .Sdk 的产物不会互相覆盖**（两者我各验过一次 0 错误）。
7. **未覆盖（与 B 轮同）**：`dotnet publish` / 单文件 / 非 `linux-x64` RID；界面完整性与业务功能
   （`PortShotHook` 未驱动登录流程，只验"起得来 + 有色画面"）;`net10.0`（无 `-windows`）入口未验
   （本次入口沿用 `net10.0-windows`）。
8. **没做的扩展**：任务书建议的"源码树模式"我做了（`WpfLinuxSrcTree`，见 §3 与 `pkg/README.md`），
   但**没有**再往上做"给库工程按需注入 `Resource` glob"之类 —— 理由见第 2 条。
9. **`RestoreAdditionalProjectSources` 里 `$(WpfLinuxRoot)` 来自两棵树既有的 `Directory.Build.props`**
   （值 = `/home/links-dev/netTest/GitProj/WPFOnLinux`）。若换仓根，两处都要跟着改 —— 这是既有配方已存在的
   硬编码，本次没有新增同类硬编码，但也没有消除它。

---

## 5. 自包含结论

* **背景**：B 轮把自产 WPF 栈打成了包，入口工程能"一行接入"，但入口**依赖的** 4 个 WPF 工程还是"仓内配方
  wrapper"，它们用 `PortWpfRefsMode` 选引用身份，而该属性过不了 `ProjectReference` ⇒ 整图身份分叉
  ⇒ 不设环境变量就 `CS0012`（要求 `System.Xaml, Version=10.0.0.0, …b77a…`）。
* **做了什么**：① 给包加两项能力——**源码树模式**（`WpfLinuxSrcTree`，自动派生 Compile/Page/
  ApplicationDefinition/EmbeddedResource，库工程自动把 `App.xaml` 降级为 `Page`）与**可选官方借用件**
  （`WpfLinuxOfficialBorrows`，`borrow/` 7 件）；② 按真实引用图新增 6 个 `*.Sdk.csproj`
  （`APPGuarder`/`Config`/`ICDLite`/`AgentRT`/`LicenseManagerGUI`/`Common.Resources`），
  每个只写"包引用 + 源码树 + 该工程的特有清单"；③ 把 `ICDStudioSdkProbe` 改指这 6 个包化版。
* **验证了什么**：零外部设置 `build`/`-t:Rebuild` 各 0 错误（947 / 1204 警告）；
  6 个依赖工程的编译资产全部来自包（身份不可能分叉）；
  新增工程绝对 `HintPath` 计数 0；仓外运行存活 ≥12s、226 色；
  回归：`ICDStudio.Port.csproj`（旧 wrapper）与 MVP-1 样板工程仍 0 错误。
* **遗留什么**：包版本仍是写死的 `1.0.0`（重打包需清缓存）；`Resource`/`Content` 清单仍归工程；
  MSB3277 噪音；借用件只有元数据；`publish`/多 RID/界面完整性未验。

## 6. 一键复跑

```bash
export PATH="$HOME/.dotnet:$PATH"
# ① 若重打包过包，先清缓存（本机已刷新，可跳过）
rm -rf ~/.nuget/packages/wpflinux.sdk
# ② 判据 1/2/5 全跑
bash /home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/ICDStudioSdkProbe/evidence/r2-verify.sh
# ③ 回归（旧 wrapper / MVP-1）
cd /home/links-dev/netTest/GitProj/RT/Links-ICD-Kit/PortWpfLinux/ICDStudio && PortWpfRefsMode=selfbuilt dotnet build ICDStudio.Port.csproj -v:m
cd /home/links-dev/netTest/GitProj/WPFOnLinux/src/Linux/samples/WpfLinuxSdkProbe && dotnet build WpfLinuxSdkProbe.csproj -v:m
```

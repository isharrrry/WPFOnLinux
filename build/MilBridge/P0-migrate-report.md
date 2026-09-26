# P0-migrate-report —— 把 `#76` 冻结态搬进 git 树，并证明两树求值级等价（＋主控裁定 (A) 的结构性去重）

> 任务 `t1` ｜ attempt `94ba7f83-84b3-40d0-b807-62c5a58bbffb` ｜ 执行者 `migrator`（AgentTeams `wpf-linux-route-completion`）
> 撰写时点：2026-09-26 19:2x–19:3x（+08:00）｜ 全程绝对路径，**所有读数同命令现算**（纪律 40）
> 纪律：重活一律 `bash ~/heavy-slot.sh --min-avail 1500 --max-hold … --` 串行；开跑前现取 `df -Pk` 第 4 列（≥5 GB）＋ `free -m` 的 `available` **与** `swapfree`；**零** `pkill`／`pgrep -f`（`D-G103`）；进程只按 PID 收；改动前 `cp -p` 备份。

## §0 一句话

`N`（git 树）**已被搬成与 `O`（`#76` 冻结树）在有效构建输入上逐位等价的开发树**：九位全部命中冻结值、`inputs_fp` 与清单长度逐位不变、**88/88 个两树都有的工程求值级逐字节等价**；让这成为可能的**唯一**修法是把 MSBuild 会自动导入的两个根件（`Directory.Build.props`／`Directory.Build.targets`）移出，并按主控裁定 **(A)** 把那棵**重复的 dotnet/wpf 源码/构建基础设施**（19 条路径／7346 件／125,377,211 B）整体移出 —— 移出后 `verify-all.sh` 第 `[9]` 步从 `FAIL reason=drift（cand=88→180／undeclared=0→92）` **回到 `PASS reason=ok cand=88 undeclared=0`**，与 `#76` 逐字相同。

🔴 **本迁移不单独发波**：它**只提交**（不冻结、不推、不动九位、不触发重取）；端到端证明仍是 `#77` 的整波链。

---

## §1 现场与资源

| 项 | 读数（现取） |
|---|---|
| `N`（git 树） | `/home/links-dev/netTest/GitProj/WPFOnLinux`（git 2.34.1；迁移前 HEAD `1fe6cec5ee49504fe682cdfdb40a2d1a1ffae737`） |
| `O`（旧路径，**现在是符号链接**） | `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux` → `readlink -f` = `N` |
| `#76` 原树**真实路径**（冻结证据） | `/home/links-dev/netTest/wpf-linux-20260906/.p0shadow-wpf-linux`（`mv` 改名，非拷贝；`du -sh` 5.1 G） |
| 移出件停放（第二回滚路径） | `~/w-p0mig/quarantine-dedupe/`（同 inode 改名，**非**硬链接 ⇒ 不触发 `D-G127`／`[41] REPO-ALIAS`） |
| 本机 | `nproc=4`；开跑时 `available=8843 MB`／`swapfree=2047 MB`；`df` 可用 **26.6 GB** |
| ⚠️ 中途世界漂移（如实） | 19:10→19:13 之间**盘上可用从 26.6 GB 跳到 122.9 GB**（`/dev/sda2` 已用 159 G→63 G）—— 与本任务无关的**大清理**（`~/w**` 回收）。本件所有重活**仍按 ≥5 GB 闸**执行；但**这不是本件做的**，不许记到本件头上。 |

---

## §2 九位（`verify` 命令 V1 原文）

现取 `for f in …; do sha256sum "$f" | cut -c1-16; done`，在 `N` 上：

| # | 件（相对 `N`） | `#76` 冻结值 | `N` 迁移前 | **`N` 现在** |
|---|---|---|---|---|
| 1 | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`（bridge） | `4e25e4b27d4d5ae1` | **MISSING** | **`4e25e4b27d4d5ae1`** ✅ |
| 2 | `build/PresentationCore.Linux/bin/Release/PresentationCore.dll`（pc） | `722e0ab8205b7c3f` | **MISSING** | **`722e0ab8205b7c3f`** ✅ |
| 3 | `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`（pf） | `963c59991fd1f709` | **MISSING** | **`963c59991fd1f709`** ✅ |
| 4 | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（win32shim） | `fc60c34d51fd9247` | **MISSING** | **`fc60c34d51fd9247`** ✅ |
| 5 | `build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll`（provider） | `1f9511a7ef395bfe` | **MISSING** | **`1f9511a7ef395bfe`** ✅ |
| 6 | `build/DirectWrite.Linux/wic-shim/libwpfwic.so`（wic） | `f7b3026c8c019be2` | **`56278c14b4ecd672`**（主控点名的修前陈旧件） | **`f7b3026c8c019be2`** ✅ |
| 7 | `build/shims/PresentationCore.HbTextLine.cs`（hbtextline） | `921ba9c65e9fb3be` | `921ba9c65e9fb3be`（本来就同） | **`921ba9c65e9fb3be`** ✅ |
| 8 | `build/WindowsBase.Linux/bin/Debug/WindowsBase.dll`（windowsbase） | `2e4e46e539a72cd7` | **MISSING** | **`2e4e46e539a72cd7`** ✅ |
| 9 | `build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll`（dwf） | `ce3469f49efcbcfa` | **MISSING** | **`ce3469f49efcbcfa`** ✅ |

**九位逐位命中 `#76` 冻结值**；且**去重前后逐位不变**（机器判：`cmp -s nine-before-dedupe.txt nine-after-dedupe.txt` ⇒ `NINE_UNCHANGED=yes`）。

---

## §3 `inputs_fp`（`verify` 命令 V2 原文）

```
$ bash ~/w153a/bin/infp.sh fp
bb54413c8a3f0474a3d04e41dc08ec29fb993f7ea7a8ab689ae29f372904eb9a        # == 契约期望值
$ bash ~/w153a/bin/infp.sh list | wc -l
205
```

* **连算两遍同值**（`INFP_OLD_PATH_1 = INFP_OLD_PATH_2 = bb54413c…4eb9a`，树静止）。
* 契约那条命令里的 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux` 是**硬编码**的 ⇒ 它现在经**符号链接**读到活树 `N`；另用直指 `N` 的副本 `~/w-p0mig/bin/infp-n.sh`（与 w153a 版**只差 `R=` 一行**，`--selfcheck` ⇒ `EXTRACT_SELFSAME=yes`／`FILES_N=205`）复算，**同值**。
* **去重前后逐位不变**（`FP_BEFORE == FP_AFTER` 且 `LIST_BEFORE == LIST_AFTER == 205`）⇒ 机器证明**被移出的 19 条路径一件都不在 `fp_inputs()` 覆盖面里**（覆盖面的 `find` 链与白名单都不吃根目录件）。
* 旁证：`[12] FP-INPUTS-HYGIENE` 现读 `PASS reason=clean coverage_n=205 artifact_n=0 missing_n=0 stderr_bytes=0`。

---

## §4 求值级等价（**机器证据**，不是 `rc=0`）

### §4.1 判法

对**两树都存在**的每一个 `*.csproj`（现取：`find src build samples tests tools -name '*.csproj'` 在 `O` 侧枚举 ∩ 在 `N` 侧存在 ⇒ **88 个**），两树各跑同一条命令：

```
dotnet msbuild <proj> --nologo -getProperty:TargetFramework,TargetFrameworkVersion,WpfArcadeSdkPath,RepositoryName,
  DirectoryBuildPropsPath,DirectoryBuildTargetsPath,ImportDirectoryBuildProps,MSBuildProjectExtensionsPath,Configuration,
  BaseOutputPath,BaseIntermediateOutputPath,OutputPath,IntermediateOutputPath,AssemblyName,RootNamespace,LangVersion,
  Nullable,ImplicitUsings,AllowUnsafeBlocks,Deterministic,GenerateAssemblyInfo,IsPackable,TreatWarningsAsErrors,
  NoWarn,DefineConstants,EnableDefaultCompileItems,MSBuildProjectName -getItem:Compile
```

再**两侧同规则**归一化后逐字节 `cmp`。**两条**归一化规则（各自有独立机器依据）：

1. **树根路径**：`s|$N|@ROOT@|g` ＋ `s|${N#/}|@ROOT@|g`（`$O` 同）。
   依据：`-getItem` 的 JSON 里**绝对路径不带前导 `/`**（现取样例：`"Directory": "home/links-dev/netTest/GitProj/WPFOnLinux/build/…"`）⇒ 只写带前导 `/` 的那条规则**一条都匹配不上**（我第一次就栽在这里，见 §11 自伤 1）。
2. **`"AccessedTime"` 的「值」**（**键保留**，值换成 `@ATIME@`）。
   **反遮羞布**：开这条之前先逐件抽**残余差异的键名集合**，现读 `RESIDUAL_KEY_KINDS=1`，唯一那个键就是 `AccessedTime`（文件 atime：两棵各自独立的树必然不同，且读文件本身就会改它；**不是**构建输入）。⇒ 这条**只**吃掉 atime，不许再开第三条。

### §4.2 结果（两个时点各跑一遍，`O` 侧都用**真实路径**）

| 时点 | `O` 侧 | `PROJS_O`／`BOTH` | 路径归一化后逐字节相同 | 全归一化后 | 残余差异键种类 |
|---|---|---|---|---|---|
| 去重**前**（19:17，`O` 还是真目录） | `/home/…/wpf-linux-20260906/wpf-linux` | 88／88 | **65**/88 相同；23 件只差 `AccessedTime` | **88/88 PASS** | 1（`AccessedTime`） |
| 去重**后**（19:3x，`O` 侧改指 `#76` 原树真实路径 `.p0shadow-wpf-linux`） | `/home/…/.p0shadow-wpf-linux` | 88／88 | **65**/88 相同；23 件只差 `AccessedTime` | **88/88 PASS** | 1（`AccessedTime`） |

⇒ `EVALEQ_FULL=PASS n_both=88 full_pass=88 full_fail=0`（**两次逐字相同**）⇒ **去重没有改变求值结论**。

### §4.3 覆盖与抽样（契约要求 ≥8 且覆盖 `src/`、`build/`、`samples/`、`tests/` 四类）

| 类 | 工程数 | 全归一化失败 | 备注 |
|---|---|---|---|
| `src/` | 1 | 0 | `src/WpfGfx.Linux/WpfGfx.Linux.csproj`（`Compile` 件 70/70） |
| `build/` | 57 | 0 | 含两个**对照臂**：自带 `Directory.Build.props` 的 `DirectWrite.Linux/**`、`PresentationBuildTasks.Linux/**` |
| `samples/` | 5 | 0 | HelloMil／HelloWpf／ThirdPartyMini／WpfFeatureProbe／WpfTextDemo |
| `tests/` | 24 | 0 | 六个 `WpfGfx.Linux.Tests/*` ＋ `tests/parity/**` |
| `tools/` | 1 | 0 | `tools/GeometryOracle/GeometryOracle.csproj` |

抽样逐件读数（`items=` 为 `Compile` 件数 `N/O`，`DBP` = `DirectoryBuildPropsPath`）：

| 工程 | 全归一化 | `Compile` | `DBP`（N 与 O 同） |
|---|---|---|---|
| `samples/HelloMil/HelloMil.csproj` | PASS | 5/5 | `""` |
| `src/WpfGfx.Linux/WpfGfx.Linux.csproj` | PASS | 70/70 | `""` |
| `samples/WpfTextDemo/WpfTextDemo.csproj` | PASS | 2/2 | `""` |
| `samples/WpfFeatureProbe/WpfFeatureProbe.csproj` | PASS | 3/3 | `""` |
| `build/PresentationCore.Linux/PresentationCore.Linux.csproj` | PASS | 1356/1356 | `""` |
| `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` | PASS | 1354/1354 | `""` |
| `build/WindowsBase.Linux/WindowsBase.Linux.csproj` | PASS | 314/314 | `""` |
| `build/DirectWriteForwarder.Linux/DirectWriteForwarder.Linux.csproj` | PASS | 5/5 | `""` |
| `build/MilBridge/src/MilBridge.Linux/MilBridge.Linux.csproj` | PASS | 3/3 | `""` |
| `build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj` | PASS | 2/2 | `""` |
| `build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj`（**对照**） | PASS | 20/20 | `@ROOT@/build/DirectWrite.Linux/Directory.Build.props` |
| `build/PresentationBuildTasks.Linux/PresentationBuildTasks.Linux.csproj`（**对照**） | PASS | 97/97 | `@ROOT@/build/PresentationBuildTasks.Linux/Directory.Build.props` |
| `tests/WpfGfx.Linux.Tests/Windowing.Tests/…csproj` | PASS | 13/13 | `""` |
| `tests/parity/geometry/u14/U14.csproj` | PASS | 3/3 | `""` |
| `tools/GeometryOracle/GeometryOracle.csproj` | PASS | 6/6 | `""` |

> 88 件的 `DirectoryBuildPropsPath` 分布（现取）：**77** 件 `""`（走到根、而根上已无该件）＋ **10** 件 `build/DirectWrite.Linux/Directory.Build.props` ＋ **1** 件 `build/PresentationBuildTasks.Linux/Directory.Build.props` ⇒ 与"MSBuild 取**最近**一个"的设计完全一致，且**两侧逐字相同**。

---

## §5 修法（**最小且有据**）

### §5.1 修法一：移出根 `Directory.Build.props` ＋ `Directory.Build.targets`（**只此两件**）

**为什么是这两件（判据＝机制＋两极化实测）**：`N` 的根 `Directory.Build.props:20-36` 判 `Exists('eng/WpfArcadeSdk/')` ⇒ 置 `WpfArcadeSdkPath` ⇒ `:31` import `eng/…/Sdk.props` ⇒ 其 `:5` `Sdk="Microsoft.DotNet.Arcade.Sdk"` ⇒ **本机无该 SDK ⇒ `MSB4236`**。根 `Directory.Build.targets:3-9` 另有三条独立 import（`$(WpfArcadeSdkTargets)`／`Sdk="Microsoft.DotNet.Arcade.Wpf.Sdk"`／`eng/Testing.targets`）。

**六臂两极化实测**（仓外最小工程三臂 ＋ 树内真工程三臂，全部现取原文）：

| 臂 | 条件 | 读数 |
|---|---|---|
| M1 | 根 props 在 ∧ `eng/WpfArcadeSdk/Sdk` 在 | `error MSB4236: 找不到指定的 SDK"Microsoft.DotNet.Arcade.Sdk"`（`…/eng/WpfArcadeSdk/Sdk/Sdk.props(5,31)`） |
| M2 | 根 props 在 ∧ **`eng/` 不在** | `error MSB4236: 找不到指定的 SDK"Microsoft.DotNet.Arcade.Wpf.Sdk"`（`Directory.Build.props(34,11)`）⇒ **只删 `eng/` 不解决** |
| M3 | 两件都不在 | 求值正常（`TargetFramework:""` 的最小工程） |
| ARM0 | 树内 `samples/HelloMil`，两件都在 | `MSB4236`（Arcade.Sdk，`eng/…/Sdk.props:5,31`） |
| ARM1 | 只移出 `Directory.Build.props` | `MSB4236`（**Arcade.Wpf.Sdk**，`Directory.Build.targets(6,11)`）⇒ **只移一件不解决** |
| ARM2 | 两件都移出 | `{"TargetFramework":"net10.0","WpfArcadeSdkPath":"","RepositoryName":""}` —— 与 `O` **逐字节相同** |

**为什么"最小"**：只有这**两件**是 MSBuild 的**隐式自动导入**入口；根目录其余 fork 件（`eng/`、`packaging/`、`LICENSE.TXT`…）在这两件移出后对**求值**完全惰性（`eng/` 唯一的外部引用是 `build/port-pbt.sh` 的注释文字）。
**为什么不是"删整棵 fork 根树"**：一是"最小改动 ⇒ 可读、可审、可回滚"；二是 fork 根里混着**移植面自己的**根件（`global.json`／`README.md`／`handoff.md`／`verify-all.sh`／`wpf-linux.sln`／`BuildHygiene.props`／`.gitignore`／`upstream/`），一刀切会连它们一起删。至于那棵**确实重复**的上游树 —— 见 §5.2（按主控裁定另行结构性去重）。
**回滚**：`git restore --source=HEAD --staged --worktree Directory.Build.props Directory.Build.targets`，或 `cp -p ~/w-p0mig/backup/Directory.Build.{props,targets}.p0bak .`（备份先于任何写，sha16 与现场逐位相同），或 `cp -p upstream/wpf/Directory.Build.{props,targets} .`（两者**逐字节相同**：`3a43d0988773baec`／`ca39bd05621a5838`）。

### §5.2 修法二（主控裁定 **(A)**）：结构性去重 —— 把重复的 dotnet/wpf 源码/构建基础设施移出 `N`

**触发证据（我"先报不改"、主控裁定的那条）**：`verify-all.sh` 第 `[9]` 步在 `N` 上 `BHYGIENE_IMPORT=FAIL reason=drift … cand=180 undeclared=92`，而 `#76` 原树上 `PASS reason=ok … cand=88 undeclared=0`。机制：该牙的 `collect_candidates()` = `find $ROOT -name '*.csproj' -not -path '*/upstream/*' …`；声明册只列移植面的 **88** 个工程，而那棵重复树的 **92** 个 csproj 也被收进候选集（逐目录：`src/Microsoft.DotNet.Wpf/` **74** ＋ `packaging/` **17** ＋ `eng/common` **1**；这 92 件**全部 git-tracked ⇒ 迁移前就在**，非本件引入）。

**移出集合（19 条路径；界定 = 「重复的上游源码/构建基础设施」）**：逐件清单（路径／件数／字节／**该路径逐件 `<sha256>  <path>` 行块再 sha256 的聚合指纹**）：

| 路径 | 件数 | 字节 | 聚合 sha16 |
|---|---|---|---|
| `src/Microsoft.DotNet.Wpf/` | 6821 | 123481513 | `3e536b81ca1fd429` |
| `packaging/` | 214 | 339692 | `5e8205395827d61f` |
| `eng/` | 272 | 1037182 | `28a2d828ff0e222d` |
| `Microsoft.Dotnet.Wpf.sln` | 1 | 146696 | `d4ff209698935a03` |
| `build.sh` | 1 | 516 | `233265f2fe2ef7a5` |
| `build.cmd` | 1 | 144 | `cf1e82fc9f6bacea` |
| `test.cmd` | 1 | 132 | `daf490a28aec2c12` |
| `Restore.cmd` | 1 | 113 | `6fe5bdb24bb13068` |
| `start-vs.cmd` | 1 | 1467 | `66eeb3964686f872` |
| `dotnet-test-install.ps1` | 1 | 65665 | `1d16a4097c08ea7e` |
| `.azuredevops/` | 1 | 182 | `d30c7d7d9215fe04` |
| `azure-pipelines.yml` | 1 | 1389 | `8a4106a87de840a3` |
| `azure-pipelines-pr.yml` | 1 | 5999 | `5468f4e7cf80091f` |
| `codecov.yml` | 1 | 671 | `8aa710baff50bbf1` |
| `es-metadata.yml` | 1 | 215 | `0e6173d69efcc9ae` |
| `github-merge-flow.jsonc.txt` | 1 | 335 | `605d4e3194df72e2` |
| `roadmap.md` | 1 | 5448 | `c5d5d9d1c4126940` |
| `Documentation/` | 24 | 287445 | `2769fb7bc1f49183` |
| `NuGet.config` | 1 | 2407 | `68b32b0899da24bb` |
| **合计** | **7346** | **125377211**（`du -sb` 128510651） | — |

* **逐件清单（路径／字节／每件 sha16／`git ls-files` 命中）**：`~/w-p0mig/logs/del-list.tsv`，**7346 行**，行块 sha16 = **`b1aca04f1e69e069`**（`sha256sum` 现算）。
* **可回滚（双路径）**：① 安全闸现读 `files=7346 tracked=7346 local_dirty=0 abort=0`（**全 tracked ⇒ git 可逐字取回**；路径下**零未跟踪件** ⇒ 不会丢东西）；② 物理回滚 = `~/w-p0mig/quarantine-dedupe/`（**`mv` 改名**，同 inode，**不是**硬链接影子 ⇒ 与 `D-G127`／`[41] REPO-ALIAS` 无冲突，该步现读 `ALIAS=PASS examined=24753 linked_gt1=0`）。远端亦在：抽样 `git cat-file -e origin/feat-Linux:src/Microsoft.DotNet.Wpf/src/PresentationCore/PresentationCore.csproj` ⇒ 命中。
* **保留**（主控点名；治理与移植面，**未动**）：`LICENSE.TXT`／`SECURITY.md`／`CODEOWNERS`／`CODE_OF_CONDUCT.md`／`THIRD-PARTY-NOTICES.TXT`／`.github/`／`.editorconfig`／`.gitattributes`／`.gitignore`／`README.md`／`README-Window.md`／`docs/`／`build/`／`samples/`／`src/WpfGfx.*`／`tests/`／`tools/`／`upstream/`／`global.json`／`wpf-linux.sln`／`verify-all.sh`／`handoff.md`／`BuildHygiene.props`／`home/`。

#### §5.2.1 读者清扫（动手**前**做，硬约束）

对 19 条路径逐条全仓 grep（代码件优先）。结论：**没有任何仓内件读被移出的那棵树**，逐条如下：

| 被查的引用 | 命中 | 判定 |
|---|---|---|
| `src/Microsoft.DotNet.Wpf` | `ime-landing-check.sh:113`／`pts-gap-count-check.sh:113`／`check-mil-guids.py:26,27,34`／`nl-intent-check.sh:72`／`uia-door-check.sh:101-112`／`scan-milcore-dllimports.py:15` | **全部拼成 `upstream/wpf/src/Microsoft.DotNet.Wpf/…`** ⇒ 读的是快照，**不是**根树 |
| `src/Microsoft.DotNet.Wpf`（唯一例外） | `build/MilBridge/tools/applier-audit.py:201`：`if rel.startswith("src/Microsoft.DotNet.Wpf/"): return os.path.join(root, "upstream", "wpf", rel)` | **显式重定向到 `upstream/wpf/`** —— 这正是文档里"两种拼写都读"的真相：**两种拼写都被解析到同一份快照** ⇒ 不是根树的读者 |
| `packaging/` | 仅 `system.io.packaging` 包路径（误命中） | 无读者 |
| `eng/` | `azure-pipelines-pr.yml`／`Microsoft.Dotnet.Wpf.sln`（**都在移出集合内，自引用**）＋ `build/port-pbt.sh:51` 的注释文字 | 无读者 |
| `NuGet.config` | `build/MilBridge/NuGet.config` 注释里指的是 `build/NuGet.config`（**另一件**） | 无读者 |
| `azure-pipelines*`／`.azuredevops`／`codecov.yml`／`es-metadata.yml`／`github-merge-flow`／`roadmap.md`／`dotnet-test-install.ps1`／`start-vs.cmd`／`Restore.cmd`／`test.cmd`／`build.cmd`／`Documentation/` | 仅出现在**移出集合内部**（`Microsoft.Dotnet.Wpf.sln`／`start-vs.cmd`／`azure-pipelines-pr.yml` 的自引用）；`.github/**` 对它们**零命中** | 无外部读者 |

#### §5.2.2 `upstream_nowarn()` 实证（不许照抄文档）

`build/port-lib.py:40-65`：`_upstream_repo()` = `$OUTROOT/upstream/wpf`（或 `$UPSTREAM_WPF_ROOT`），函数从 `proj_dir` **向上走，直到 `d == repo` 就 break**。实测（现算）：

```
upstream_repo = /home/links-dev/netTest/GitProj/WPFOnLinux/upstream/wpf
module UPSTREAM = …/upstream/wpf/src/Microsoft.DotNet.Wpf/src
nowarn(去重前) = ['CA1420', 'WPF0001']
nowarn(去重后) = ['CA1420', 'WPF0001']        ← 逐字相同
```
⇒ 它读的是 `upstream/wpf/**`（`Directory.Build.Props` 那份），**根树那份从未被读** ⇒ `src/Microsoft.DotNet.Wpf/` 可移出且**零影响**。

#### §5.2.3 根 `NuGet.config` 实证（不是 `NOINFO`，是**正证据**）

`#76` 的还原用的是**哪一份 config**，现取 `O` 侧 `obj/project.assets.json` 的 `project.restore`：

```
samples/WpfTextDemo, samples/HelloMil, src/WpfGfx.Linux, tests/WpfGfx.Linux.Tests/Windowing.Tests:
    configFilePaths = ['/home/links-dev/.nuget/NuGet/NuGet.Config']     ← 机器级，仅此一份
    sources         = ['https://mirrors.huaweicloud.com/repository/nuget/v3/index.json']
build/PresentationCore.Linux:
    configFilePaths = ['…/build/NuGet.config', '/home/links-dev/.nuget/NuGet/NuGet.Config']
```

而 `N` 上**有**根 `NuGet.config`（比上游多 2 个 `dotnet12` feed），且它会被 `samples/`／`src/`／`tests/`／`tools/` 下**没有更近 config** 的工程向上搜到 ⇒ 实测（`cd <tree>/samples/WpfTextDemo && dotnet nuget list source`，**只读、零网络**）：

| 树 | 有效源 |
|---|---|
| `N`（去重**前**） | `pkgs.dev.azure.com/dnceng/…`：`dotnet-eng`／`dotnet-public`／`dotnet-libraries-transport`／`dotnet-tools`／`dotnet7..10(+transport)` ……（**一长串 fork feed**） |
| `#76` 原树 | `mirrors.huaweicloud.com/repository/nuget/v3/index.json`（**只此一条**） |
| `N`（去重**后**） | `mirrors.huaweicloud.com/repository/nuget/v3/index.json`（**与 `#76` 逐字相同**） |

⇒ **保留根 `NuGet.config` 会让 `N` 的还原与 `#76` 不可比** ⇒ 移出它才是"恢复冻结形状"。**restore 本身未跑** ⇒ "会不会真的解析出不同包"仍属 `NOINFO`。

---

## §6 `O` 里未入库的车道产物 → `N`（逐件 before/after）

`rsync -a -c -i`（**不带 `--delete`**）从 `O` 灌入 `N`：`Number of files: 16,416 (reg: 13,833, dir: 2,583)`／`Total file size: 5,363,449,793`／`Total transferred file size: 4,942,596,617`／`rc=0`。之后 `diff -rq -x .git` 从 **176 行**（去重前）收敛到 **26 行**（去重后仅剩"只在 N 存在"的治理面根件）。

| 件 | `N` before | `O`（权威） | `N` after |
|---|---|---|---|
| `build/MilBridge/W136A-report.md` | `MISSING` | `cb4a58bdd2092288` | **`cb4a58bdd2092288`** ✅ |
| `build/MilBridge/W143A-report.md` | `MISSING` | `6884f7246e578429` | **`6884f7246e578429`** ✅ |
| `build/MilBridge/W148A-report.md` | `MISSING` | `1779068fff57772c` | **`1779068fff57772c`** ✅ |
| `build/MilBridge/gen/tline-ledger-lines-20260924-0021.txt` | `MISSING` | `81880ac3d10638a4` | **`81880ac3d10638a4`** ✅ |
| `multi.txt`（`O` 根，**0 字节**） | `MISSING` | `e3b0c44298fc1c14`（=空文件） | **`e3b0c44298fc1c14`** ✅ |
| `build/wave-audit.log` | `d8760f67f31af65d` | `39f6e4b5974769f9` | **`39f6e4b5974769f9`** ✅ |
| `build/DirectWrite.Linux/wic-shim/libwpfwic.so` | `56278c14b4ecd672`（修前陈旧件） | `f7b3026c8c019be2` | **`f7b3026c8c019be2`** ✅ |

**`build/wave-audit.log` 的差异定性（哪边权威、为什么）**：它是 `close-wave` 的**责任溯源审计日志**，git-tracked。现取：`git show HEAD:build/wave-audit.log` = 74,937 B／518 行／`d8760f67f31af65d`；`O` 版 = 81,230 B／572 行／`39f6e4b5974769f9`；**`HEAD` 的整份内容与 `O` 版的前 74,937 字节 `cmp` 逐字节相同**（`PREFIX=yes`）⇒ `O` 版是**严格超集**（多出的 54 行是 `2026-09-24` 在 `O` 里跑的 `close-wave`／`integration-wave` 记录，`cwd=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`）⇒ **`O` 权威**，取它。
`multi.txt` 与 `build/.applocal-selftest.log` 是 `O` 独有件，随 `rsync` 一并带入（`multi.txt` 0 字节、仓内**零读者**；其"谁造的"**未能归因** ⇒ 见 §10 `NOINFO`）。

---

## §7 旧路径过渡（已做、可逆、已实地往返）

**为什么必须做**：仓内 **205 个文件**里出现旧路径字面（其中 ~10 个是**代码件**的默认值 `ROOT=/R=/W163A_R=`）；若旧路径解析到陈旧影子树，它们会读到过期读数。

**做法（两步，可逆）**：
```bash
PAR=/home/links-dev/netTest/wpf-linux-20260906
mv "$PAR/wpf-linux" "$PAR/.p0shadow-wpf-linux"      # ① 原树**改名**（同 inode，零拷贝、零硬链接）
ln -s /home/links-dev/netTest/GitProj/WPFOnLinux "$PAR/wpf-linux"   # ② 旧路径 → 活树
```
**回退（逐字）**：`rm "$PAR/wpf-linux" && mv "$PAR/.p0shadow-wpf-linux" "$PAR/wpf-linux"`。
**本轮已实地往返一次**（机读）：`[before] O_is=dir shadow=absent` → `[after] O_is=symlink shadow=dir readlink_f_O=N` → `[rolledback] O_is=dir`（`ROLLBACK_real_dir=yes`，`wic` 回到 `f7b3026c8c019be2`，`fp` 回到 `bb54413c…4eb9a`）→ `[final] O_is=symlink shadow=dir`。活进程闸：两趟 `QUIESCE_hits=0`（按 `/proc/*/cwd`＋`/proc/*/fd` 扫，排除自身祖先链，**零** `pgrep -f`）。

**过渡后读数（经旧路径）**：`readlink -f = N`；`pwd`=`旧路径`（logical）／`pwd -P`=`N`（physical）；**九位逐位 = 冻结值**；`infp.sh fp` = `bb54413c…4eb9a`（**连算两遍**）＋`list=205`。

**⚠️ 新引入的机器级坑（如实、可复算、**不修**——主控裁定本波不修，`t5` 重指向后自行消失）**：GNU `find` 对**符号链接起点不跟随**⇒ 裸 `find "<旧路径>"` **一件都看不到**。现取四档：

| 写法 | 结果 |
|---|---|
| `find "$OLD" -maxdepth 1 -type f -name 'README*'` | **空**（不下钻） |
| `find "$OLD/" -maxdepth 1 -type f -name 'README*'` | 2 件 ✅ |
| `find "$OLD/build/shims" -maxdepth 1 -name '*.cs'` | **13** 件 ✅（子路径型都正常） |
| `find -L "$OLD" …` | 2 件 ✅ |

**仓内只有 2 处裸根 `find`**（`build/MilBridge/tools/boundary-decl-check.sh:404` 的 `find "$REPO"`、`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh:579` 的扫描根），其触发条件是"**以旧路径为 cwd**"。现取 cwd 对照：

| cwd | `DECL_CLOSURE` | `BOUNDARY_DECL` |
|---|---|---|
| `N`（推荐） | `members=57 max_depth=3 used=2` | **`PASS records=2 pass=2 rc=0`** |
| 旧路径（logical） | `members=39 used=1` | 🔴 `FAIL records=2 pass=1 fail=1 reason=record-failure(fail=1) rc=1` |
| 旧路径 ＋ `cd -P` | `members=57 used=2` | **`PASS rc=0`** |
| 旧路径 ＋ `--repo <physical>` | — | **`PASS rc=0`** |

机制（有据）：该牙的 `REPO` 由 `cd … && pwd` 取得（**logical** 字符串），而内部 token 被规范化成 **physical** 前缀 ⇒ `case "$p" in "$REPO"/*)` 前缀不匹配 ⇒ 调用闭包**静默截断**（57→39），随后 `:404` 的裸 `find "$REPO"` 又返回 0 ⇒ 报 `in-repo-twin n=0`。⇒ **一切从 `N` 跑**（本波之后本来就该如此）。

---

## §8 两树口径可比矩阵（同一批仓内牙，`N` vs `#76` 原树真实路径，纯读）

| 牙 | `N` 去重**前** | `N` 现在 | `#76` 原树 | 判定 |
|---|---|---|---|---|
| `[9]` **BUILD-HYGIENE** | 🔴 `FAIL reason=drift … cand=180 undeclared=92 rc=1` | ✅ **`PASS reason=ok files=41 lines=41 list=41 mention_files=42 mention_lines=84 undeclared=0 cand=88 rc=0`** | `PASS reason=ok … undeclared=0 cand=88 rc=0` | **恢复到逐字相同** ✅ |
| `[11]` VERIFYALL-SELF | `PASS names=47 decl=47 gen=#76 vfile_sha16=b30c685909832f38` | 同 | 同 | 逐字相同 ✅ |
| `[12]` FP-INPUTS-HYGIENE | `PASS coverage_n=205 artifact_n=0` | 同 | 同 | 逐字相同 ✅ |
| DEFECT-REGISTRY | `PASS declared=182 route_ids=182` | 同 | 同 | 逐字相同 ✅ |
| `[+]` LANE-PATH | `PASS examined=65 hits=15 code=0 declared=15` | 同 | 同 | 逐字相同 ✅ |
| `[41]` REPO-ALIAS | `PASS examined=24753 linked_gt1=0` | 同 | 同 | 逐字相同 ✅（**去重没有造出任何 inode 孪生**） |
| QUOTE-TRAP | `rc=0`，射程 `files=210 sh=121 py=89` | `rc=0`，射程 **`files=184 sh=96 py=88`** | `rc=0`，射程 `files=184 sh=96 py=88` | 结论同；**射程也恢复相同** ✅ |

> 判据①（`#76` 的 `BHYGIENE` 行含 `mention_files=42`／`mention_lines=84`，而 `#75` 的注释里写 41／83）⇒ 41→42 是 `#75`→`#76` 之间的**既有**位移，**两边都是 42** ⇒ 与本迁移无关（两条我都没动）。

---

## §9 我推翻了哪句话

**`README.md:180`（`upstream/wpf/` 那一行）原文断言：「本仓构建只读 `upstream/wpf/**`，根目录那份不使用」—— 该句被证伪**，两条**独立机制**（都不是论证，是现取读数）：

1. `N` 的根 `Directory.Build.props` 是 **MSBuild 隐式自动导入**入口 ⇒ `samples/HelloMil/HelloMil.csproj` **求值即** `error MSB4236: 找不到指定的 SDK"Microsoft.DotNet.Arcade.Sdk"`（同一条命令在 `O` 上给出正常 JSON）。
2. 那棵树的 **92 个 csproj** 进 `build-hygiene-import-check.sh` 的候选集 ⇒ `verify-all.sh` 第 `[9]` 步 `cand=88→180`／`undeclared=0→92`／`reason=drift`。

⇒ 已按裁定 **(A)** 落地结构性去重，并把 README 该行**同趟改写**（逐行 `diff` = **1 删 1 增**）；`docs/ROUTES.md` §8 R8 的"暂缓去重"**追加状态更新行**（原文一字未动，`diff` = **0 删**）；`docs/FORK-AND-PUSH.md` §0 前提 1 的现状读法**追加注**（原文一字未动，`diff` = **0 删**）。

---

## §10 边界与 `NOINFO`（逐条）

1. `NOINFO` **restore 的实际后果**：只证了"**生效的 config 与源**在两树间不同/相同"（§5.2.3 的 `dotnet nuget list source` 与 `#76` 的 `project.assets.json`），**没有跑过一次 restore** ⇒ "会不会解析出不同包"未测。
2. `NOINFO` **本迁移不单独发波**：它**只提交**（不冻结、不推、不动九位、不触发五臂重取、不产生新世代）；端到端证明 = `#77` 的整波链（若 `#77` 链上任一读数与 `#76` 不可比 ⇒ 迁移失败）。
3. `NOINFO` **判据①（干净 clone ＋ 按 README 从零构建）未跑**（那是 R8 的判据①，需重活；本件只做"树形态对齐"）。
4. `NOINFO` **`multi.txt` 的来源**：0 字节、仓内零读者；`build/MilBridge/tools/pipefail-sigpipe-check.sh` 里有同名临时件（`$TMPD/multi.txt`），但**未能把 `O` 根那份归因到它** ⇒ 不猜。**处置**：它**留在 `N` 的工作树里**（满足"5 件在 N"）但**不入库**（它本来就"未入库"，`O` 也从未有 git）—— 若入库，git 会把它与 `packaging/Microsoft.Dotnet.Wpf.ProjectTemplates/useSharedDesignerContext.txt`（同为 **0 字节**）配成 `R100` 重命名，把"移出的 19 条路径"读成"搬了个文件"，**账目会串**（实测：`git diff --cached --name-status -M` 出现 `R100 … useSharedDesignerContext.txt -> multi.txt`；撤回它的暂存后该 R 条目消失）。
5. `NOINFO` **旧路径下裸 `find` 的射程**：本件只测了**仓内**的 2 处；`~/w**/bin/**` 里车道自带的脚本未逐一审（它们要么用 `$R/<子路径>`、要么接受环境覆盖）。
6. **未跑**：`verify-all.sh` 整趟、`close-wave.sh`、`integration-wave.sh`、任何构建/门禁/应用/五臂重取（本件按契约"重活串行、不越界"执行；`[9]/[11]/[12]/[+]` 等**单件**牙都单独跑过，读数见 §8）。
7. **世界漂移**：19:10→19:13 之间盘上可用从 26.6 GB 跳到 122.9 GB（他人清理）⇒ §1 已记，**不计入本件成果**。

---

## §11 自伤与踩坑（如实入册）

1. **归一化 bug #1（差点把 88/88 全判红）**：`-getItem` 的 JSON 里绝对路径**不带前导 `/`**，我第一版只写了带前导 `/` 的 `sed` 规则 ⇒ 88 件**全 FAIL**、且每件只差 1 行。**发现方式**：88/88 全红 + 每件仅 1 行差异本身就是"规则错了"的形状（真缺陷不会那么整齐一致）。修正后 65 件直接逐字节相同、23 件只差 atime。
2. **假绿的近失（最该记住的一条）**：旧路径过渡之后我又"跑了一遍 88/88"，得到 `raw_identical=88`（**完美得可疑**）。机制：旧路径已是指向 `N` 的符号链接 ⇒ `cd $O && dotnet msbuild` **跑的就是 `N`** ⇒ **自己跟自己比**。**发现方式**：`raw_identical` 从 0 跳到 88 太整齐 ⇒ 回头核 `readlink -f $O`。**处置**：把 `O` 侧改指 `#76` 原树**真实路径**（`.p0shadow-wpf-linux`）重跑（§4.2 第二行）。⇒ 教训：**任何"两树对比"必须先机器断言两侧的根本路径不同**（`[ "$(readlink -f $A)" != "$(readlink -f $B)" ]`）。同理，契约里那条 `verify` 命令（`cd $N …; cd $O …`）在过渡后**已退化为单树自比**，本件在 §4/§12 里用真实路径的两树比替代它。
3. **纪律 39 违规 1 次**：一条 `git status --porcelain | head -20` 忘了先 `wc -l`，把 **7356 行**灌进会话（应只报计数）。
4. **`awk` 列号错 1 次**：可比矩阵的"按类覆盖"用了 `$7`（实际 `$6` = 工程路径）⇒ 五类全读成 0；靠"五类同时为 0"这种不可能形状发现并改正。
5. 其余守纪律：**零** `pkill`/`pgrep -f`；所有长活（rsync 5.4 GB、两轮 88 件求值、7 件牙）都走 `~/heavy-slot.sh`；每次重活前现取 `df`／`avail`／`swapfree` 并写进日志头；`git status` 全量输出仅"报告所需"处使用。

---

## §12 复算命令清单（照抄即可重放）

```bash
N=/home/links-dev/netTest/GitProj/WPFOnLinux
SH=/home/links-dev/netTest/wpf-linux-20260906/.p0shadow-wpf-linux      # #76 原树（真实路径）

# ① 九位
cd $N && for f in build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so \
  build/PresentationCore.Linux/bin/Release/PresentationCore.dll \
  build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll \
  src/WpfGfx.Linux.Native/bin/libwpfwin32.so \
  build/PresentationCore.Linux/bin/Release/DirectWrite.Linux.Provider.dll \
  build/DirectWrite.Linux/wic-shim/libwpfwic.so build/shims/PresentationCore.HbTextLine.cs \
  build/WindowsBase.Linux/bin/Debug/WindowsBase.dll \
  build/DirectWriteForwarder.Linux/bin/Release/DirectWriteForwarder.dll; do sha256sum "$f" | cut -c1-16; done

# ② inputs_fp（旧路径经符号链接读活树）
bash ~/w153a/bin/infp.sh fp && bash ~/w153a/bin/infp.sh list | wc -l        # bb54413c…4eb9a / 205

# ③ 求值级等价（88/88；重放脚本在 ~/w-p0mig/）
bash ~/w-p0mig/stepC.sh  && bash ~/w-p0mig/stepC3.sh                        # O=O 旧路径（真目录时）
bash ~/w-p0mig/stepC4.sh && bash ~/w-p0mig/stepC6.sh                        # O=$SH 真实路径（过渡后正确口径）

# ④ 结构去重的两条硬读数
cd $N && find . -name '*.csproj' -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/upstream/*' \
  -not -path '*/.artifacts/*' -print | wc -l                                # 88
cd $N && bash build/MilBridge/tools/build-hygiene-import-check.sh | grep '^BHYGIENE_IMPORT='

# ⑤ 逐件删除清单的可复核指纹
sha256sum ~/w-p0mig/logs/del-list.tsv | cut -c1-16                          # b1aca04f1e69e069
wc -l ~/w-p0mig/logs/del-list.tsv                                           # 7346

# ⑥ 旧路径的三种 cwd 对照
( cd $N  && bash build/MilBridge/tools/boundary-decl-check.sh | grep '^BOUNDARY_DECL=' )   # PASS
( cd $SH/parent/…/wpf-linux && … )   # 见 §7 表；`cd -P` 或 `--repo $N` 均 PASS
readlink -f /home/links-dev/netTest/wpf-linux-20260906/wpf-linux            # == $N
```

**留档（仓外，全是本件现跑产物）**：`~/w-p0mig/criteria.md`（原契约判据，先写死）｜`~/w-p0mig/criteria-A.md`（裁定 (A) 的追加判据）｜`~/w-p0mig/logs/{stepA,stepB,stepC,stepC2,stepC3,stepD,stepE,stepF,stepG}.log`｜`~/w-p0mig/logs/del-list.tsv`｜`~/w-p0mig/logs/{diffrq,diffrq-after}.txt`｜`~/w-p0mig/logs/stepC-prededupe/**`／`stepC-post2/**`（两轮 88 件的全部原始 JSON）｜`~/w-p0mig/backup/{Directory.Build.props.p0bak,Directory.Build.targets.p0bak,README.md.p0bak,ROUTES.md.p0bak,FORK-AND-PUSH.md.p0bak}`｜`~/w-p0mig/quarantine-dedupe/**`（19 条路径的物理副本）｜`~/w-p0mig/{stepA,stepB,stepC,stepC2,stepC3,stepC4,stepC5,stepC6,stepD,stepE,stepF,stepG}.sh`。

---

## §13 大白话小结（≤8 行）

1. `#76` 那棵能跑的树，已整体搬进 git 树：**九位、`inputs_fp`、205 件清单，逐位对上了**。
2. 挡住移植工程的根 `Directory.Build.props` 会让 MSBuild 去要一个本机没有的 SDK；**只把它和它的 `.targets` 兄弟移开**（只移一件照样报错，已实测），求值立刻与冻结树一致。
3. 主控查出来更脏的一层：fork 根还带着**一整套重复的 dotnet/wpf 源码**，它会污染门禁的"候选工程集"（88→180）。**按主控裁定 (A) 整体移出 19 条路径／7346 件**，门禁回到 `PASS cand=88 undeclared=0`。
4. 移出的东西**没有一件被仓内代码读**（唯一像的 `applier-audit.py` 是把它**显式重定向**到 `upstream/wpf/`），而且**全部 git-tracked** ⇒ 一条命令就能逐字取回。
5. **两棵树都按真实路径比过**：88/88 工程的求值（含 `Compile` 件清单）**逐字节相同**（只允许 atime 与树根路径两处归一化，且 atime 是唯一残余键）。
6. 旧路径现在**指向活树**（符号链接），可逆且已实地往返；代价是"裸 `find 旧路径` 不下钻"这一条，只在 2 处牙里能咬人 ⇒ **一律在 N 里跑**。
7. **我只提交，不发波**：九位不动、不冻结、不推、不重取；真正的端到端证明留给 `#77`。
8. 最险的一次是我自己差点造假绿（过渡后 `O` 其实是 `N` 的符号链接 ⇒ "自己跟自己比"），靠"太完美"这一形状发现并改口径重跑。

---

## §14 提交与工作树

见下节「机上现取」区块（commit sha／`git status --porcelain`）。**不推送**（推送留给 `#77`，届时是快进）。

<!-- SHA16 PLACEHOLDER -->

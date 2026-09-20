# 上游快照出处：`upstream/wpf`

> **一句话**：本仓的 `upstream/wpf/` 是 **dotnet/wpf（MIT）的一份被裁剪的快照**，由**非 git 手段**搬入（全树 6414 件落在 **2026-08-31 09:35** 同一秒级窗口内）。
> ✅ **基点 commit 已钉死 = `1cfc37f708f91ff4556bd25af414546c446f3a16`**（*Restoring autoConvert behavior in Clipboard APIs* `#11837`，2026-08-21）—— 判据见 §1.1：
> 6414 件里 **6384 件逐字节相同**、**29 件仅换行不同**、**1 件**是本仓刻意改的 `.gitattributes`、**954 件**为已登记的裁剪。
> 本文给出 ①**可复算的完整性指纹**（改树即变）、②身份与世代的 in-tree 自证、③**裁剪面的成对证据**、④把 commit 钉死的完整配方与复算命令。
>
> **口径纪律**：本文每一格都要么是**当场跑出来的读数**（附命令），要么**明确标注【推断】并写出依据与反证条件**。没有第三种。

本文**不是**判据件，也**不在**任何指纹覆盖面内（依据见 §8）——新增本文**不移动** `inputs_fp`，也不改任何门禁读数。

---

## 0. 能证明到什么程度（先说边界）

| 想证明的事 | 手里有什么 | 强度 |
|---|---|---|
| 这棵树**是** dotnet/wpf | 树内自证：`Directory.Build.props` 的 `RepositoryName=wpf`／`PackageProjectUrl=https://github.com/dotnet/wpf`；`README.md` 徽章指向 `dotnet/wpf` 的 `main` 分支；`LICENSE.TXT` = MIT | **强**（上游自己写的字） |
| 是 **.NET 11** 世代 | `TargetFramework=net11.0`；`global.json` 的 SDK／tools pin 为 `11.0.100-preview.6.26359.118` | **强** |
| 树**没被本项目改过** | 全树 `WpfLinux\|wpf-linux\|SELFBUILT\|WPF_LINUX` **0 命中**；mtime 只有 2 个批次（6414 + 3） | **强** |
| 树**此后没被任何人改过** | §3 的三条摘要（复算即知） | **强**（但**没有机器牙**，见 §8） |
| 是**完整** checkout | ✗ **反证成立**：`.git`、`eng/`、`Documentation/`、`.github/`、`packaging/`、`redist/`、`tests/` 全缺，而树内文件**正引用着它们** | **已推翻**（§5） |
| **精确 commit** | ✅ **`1cfc37f708f91ff4556bd25af414546c446f3a16`**（`#11837`，2026-08-21 03:44 -0700）：全树 mtime 落在 2026-08-31 09:35，而 dotnet/wpf 主干在该时刻**之前的最后一次提交**就是它（下一次提交在 **2026-09-04** ⇒ 8-22~9-03 确为空档） | **已钉死**（逐件字节比对见 §1.1） |

---

## 1. 身份（in-tree 自证）

跑：

```bash
cd upstream/wpf
sed -n '1,12p' Directory.Build.props      # RepositoryName / PackageProjectUrl / TargetFramework
head -5 README.md                          # 徽章指向的仓库与分支
head -3 LICENSE.TXT                        # MIT + .NET Foundation
cat es-metadata.yml                        # SDL 路由
```

读数：

- `Directory.Build.props`：`<RepositoryName>wpf</RepositoryName>`、`<PackageProjectUrl>https://github.com/dotnet/wpf</PackageProjectUrl>`、`<TargetFramework>net11.0</TargetFramework>`、`<TestRunnerName>XUnitV3</TestRunnerName>`
- `README.md:4-5`：`codecov.io/gh/dotnet/wpf/branch/main/...`、`github.com/dotnet/wpf/blob/main/LICENSE.TXT` ⇒ 这份 README 是 **`main` 分支**上的版本
- `LICENSE.TXT`：`The MIT License (MIT)` / `Copyright (c) .NET Foundation and Contributors`
- `es-metadata.yml`：`isProduction: true`，SDL 路由 `devdiv / DevDiv\NET Fundamentals\NET Partners\WPF\Security\SDL`
- `NuGet.config`：注释自述 "should be kept in sync across https://www.github.com/dotnet/wpf and dotnet-wpf-int repos"

⇒ **上游身份无歧义**：`dotnet/wpf`（`main` 分支内容），MIT。

---

## 1.1 基点 commit 的**逐件字节验证**（2026-09-20 实测，可复算）

做法：取 `dotnet/wpf` 的 git 历史里「快照时刻**之前**的最后一次提交」，再把我们 vendored 树里**每一件**
算成 git blob 摘要（`git hash-object`）与该 commit 的树（`git ls-tree -r`）**逐件比对**。

```bash
cd <dotnet/wpf 的 clone>
git fetch --shallow-since=2026-06-01 upstream main               # 需要那一段历史
git log -1 --until='2026-08-31 09:35:00 +0800' upstream/main     # ⇒ 1cfc37f708f91ff4556bd25af414546c446f3a16（见下表）
# 逐件比对：upstream/wpf/** 每件的 `git hash-object` vs `git ls-tree -r <commit>` 同路径的 blob 摘要
#   排除 3 件本地追加：T1_SCOPE.md / DUCE_INVENTORY.md / winbase_pinvoke.json
```

| 结论 | 件数 | 说明 |
|---|---|---|
| **逐字节相同** | **6384** | 强证据：基点就是 `1cfc37f708f91ff4556bd25af414546c446f3a16` |
| **仅换行不同** | **29** | 主要是 `*.cmd` / `*.sln`：**上游存 LF，我们的快照是 CRLF** ⇒ 非 git 搬入的搬运伪影（上游 `.gitattributes` 曾按 CRLF 处理这类文件） |
| **真内容不同** | **1** | 就是 `.gitattributes` —— 本仓**刻意**改为 `* -text`（见 §3 顶部与 §9 附录），目的是「磁盘字节 == 库内字节」 |
| 上游有、快照缺（裁剪面） | **954** | 与 §5 的「被裁剪」一致（`.github/`、`.azuredevops/`、`eng/` 等） |

⇒ **「钉死」的口径**：6384/6414 逐字节相同 ＋ 29 件可解释的换行差异 ＋ 1 件已登记的刻意差异 ＋ 954 件已登记的裁剪。
任何人按上面命令重跑都应得到同一组数（若不同，先看是不是换行差异）。

## 2. 世代（版本 pin，逐字）

```bash
cd upstream/wpf && cat global.json
```

| 键 | 值（逐字） |
|---|---|
| `sdk.version` / `tools.dotnet` | `11.0.100-preview.6.26359.118` |
| `sdk.rollForward` | `latestFeature`（`allowPrerelease: true`） |
| `msbuild-sdks["Microsoft.DotNet.Arcade.Sdk"]` | `11.0.0-beta.26411.119` |
| `msbuild-sdks["Microsoft.DotNet.Helix.Sdk"]` | `11.0.0-beta.26411.119` |
| `msbuild-sdks["Microsoft.Build.NoTargets"]` | `3.7.56` |
| `tools.vs.version` | `17.2` |
| `test.runner` | `Microsoft.Testing.Platform` |

⚠️ **刻意不做的事**：SDK 的 `26359` 与 Arcade 的 `26411` **不是同一种编号**（数值区间与编码规则都不同），**本文不把任何一个数字解码成日期**。日期只能来自 §6 那种外部旁证，且必须标注为推断。

---

## 3. 完整性指纹（可复算；改一个字节即变）

四条定义如下（`cd upstream/wpf` 后逐字可跑）。`sha16` = 前 16 位，与本仓其余记录同口径。

| 记号 | 覆盖 | 摘要（sha256，2026-09-19 当场读数） | sha16 |
|---|---|---|---|
| **M1** | 全部 6417 件：**路径+大小** | `37a71c4f4effa87fd487203333871afda85522523bb154bde271133f81091943` | `37a71c4f4effa87f` |
| **M2** | 全部 6417 件：**内容** | `618f2c73782d64f55b11d61be69b57ca0c31b2b9212d58a050030d7492bd84c4` | `618f2c73782d64f5` |
| **M3** | 上游原件 **6414** 件（排除 3 件本地追加）：**内容** | `4bdafac2801ab3e41cf3ae2e5cfb3cbc4ebb298069d54b076b73c320d129b11d` | `4bdafac2801ab3e4` |
| **M4** | 上游原件 **6414** 件：**路径+大小** | `fa5a7a6abe88928e432e2fff828be129b298b8da7446d0ee87088275ddace091` | `fa5a7a6abe88928e` |

> ⚠️ **2026-09-20 更新（`#49` 准备趟）**：上表四个值已**重算**，因为本仓对 vendored 快照做了**一处刻意的偏差**：
> `upstream/wpf/.gitattributes` 被替换为 `* -text`（原文件 = 67 行 / 1425 B / sha256 `2c621eaf0983ae89…`，
> 原文逐字保存在本文档 §9 附录）。**理由**：git 的换行归一化（上游规则 `* text=auto`）会让
> "我们算的字节"与"别人 clone 到的字节"不是同一份 ⇒ **本仓所有以字节为口径的判据**
> （冻结基线逐件 sha16、五臂日志、语料指纹、本表的 M1–M4）在贡献者机器上会**系统性对不上**。
> 属性规则**深层文件胜出** ⇒ 只改仓库根不够，必须把 `upstream/wpf/.gitattributes` 这一层也关掉。
> 改前值：`M1=31adafc6be9cea01`／`M2=d81e29233e29e47e`／`M3=f402e345053e7967`／`M4=0a098c16479e315c`。
> **本改动不影响构建**（`.gitattributes` 是 git 元数据，不进编译）。

命令（逐字）：

```bash
cd upstream/wpf

# M1 —— 路径+大小清单的摘要（传输无关：只看名字与大小）
find . -type f -printf '%P\t%s\n' | LC_ALL=C sort | sha256sum

# M2 —— 全树内容摘要
find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum

# M3 —— 上游原件内容摘要（排除三件本地追加件；按**路径**排除 = 传输无关口径）
find . -type f ! -name 'T1_SCOPE.md' ! -name 'DUCE_INVENTORY.md' ! -name 'winbase_pinvoke.json' \
  -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum

# M4 —— 同 M3 覆盖面，但只算路径+大小
find . -type f ! -name 'T1_SCOPE.md' ! -name 'DUCE_INVENTORY.md' ! -name 'winbase_pinvoke.json' \
  -printf '%P\t%s\n' | LC_ALL=C sort | sha256sum
```

**两条自证**（都当场跑过）：

1. **确定性**：M1/M2/M3 各跑两遍，读数逐位相同。
2. **口径一致性**：M3 用**两种互不相干**的排除法算出的值**相同** —— ① 按 mtime（`! -newermt '2026-08-31 09:36'`）、② 按路径（上面那条）。两者若分叉，说明"本地追加件"这个划分本身站不住。

件数与体积（`find . -type f ... | wc -l` / `awk '{s+=$1} END{print s}'`）：

| 面 | 件数 | 字节 |
|---|---|---|
| 全部 | **6417** | **116,107,857** |
| 顶层散件（`maxdepth 1`） | 29 | 453,340 |
| `src/Microsoft.DotNet.Wpf/` 直属 | 2 | 7,849 |
| `src/Microsoft.DotNet.Wpf/src/` 直属 | 1（`.editorconfig`） | 7,713 |
| 21 个工程子树（`src/Microsoft.DotNet.Wpf/src/*/`） | 6,385 | 115,646,449 |

> 对账：`6,385 + 29 + 2 + 1 = 6,417` ✓ ｜ `115,646,449 + 453,340 + 7,849 + 7,713 = 116,107,857` ✓
> （上表逐格可由 `for d in src/Microsoft.DotNet.Wpf/src/*/; do ... done` 复算；`du -sh .` 给 127M —— 那是**块占用**，与字节总数不是同一口径。）

21 个子树逐格（件数 / 字节）：

```
Common                                 27      311,479
DirectWriteForwarder                  108      970,329
Extensions                             12       43,511
PenImc                                 53      374,469
PresentationBuildTasks                 48    1,748,193
PresentationCore                    1,332   21,549,732
PresentationFramework               1,359   35,703,929
PresentationUI                        139    2,989,492
ReachFramework                        351    3,834,333
Shared                                155    2,371,291
System.Printing                       175    2,448,220
System.Windows.Controls.Ribbon         197    5,235,298
System.Windows.Input.Manipulations     40      336,111
System.Windows.Presentation             7       12,906
System.Windows.Primitives               5        4,253
System.Xaml                           209    3,055,415
Themes                                179    9,940,829
UIAutomation                          299    3,783,813
WindowsBase                           272    5,157,196
WindowsFormsIntegration                39      274,491
WpfGfx                              1,379   15,501,159
```

---

## 4. 落盘形状（观测，全部可复算）

```bash
cd upstream/wpf
find . -type f -printf '%TY-%Tm-%Td %TH:%TM\n' | sort | uniq -c   # mtime 批次（按分）
find . -type f -printf '%TH:%TM:%TS\t%P\n' | sort | uniq -c       # 到秒：应 26 / 6388 / 1 / 1 / 1
find . -type f -printf '%TH:%TM:%TS\t%P\n' | grep '^09:35:12' | cut -f2- | grep -c '/'   # 0 ⇒ 那 26 件全是顶层
find . -type f -newermt '2026-08-31 09:36' -printf '%TH:%TM  %P\n' | sort   # 本地追加件
find . -name '.git*' -maxdepth 3                                  # 只有两个文本文件
grep -rlE 'WpfLinux|wpf-linux|SELFBUILT|WPF_LINUX' . | wc -l      # 应为 0
grep -rEo '\b[0-9a-f]{40}\b' . | wc -l                            # 疑似 commit 串
```

| 观测 | 读数 | 含义 |
|---|---|---|
| mtime 批次 | 按秒 **5 个**时间戳／按分 **4 组**：`6414 件 @ 2026-08-31 09:35` ＋ 3 件 @ `09:41/09:42/09:43` | 6414 件是**一次性批量落盘**（不是逐次编辑的产物）；后 3 件是**本地分析件** |
| **落盘顺序** | `09:35:12` → **26 件**；`09:35:23` → **6388 件**；`09:41:32`／`09:42:50`／`09:43:30` 各 1 件 | 搬运是**脚本化两趟**（先根后 `src/`）：`09:35:12` 那 26 件与**顶层上游件清单逐行相同**、且**含 `/` 的件数 = 0**；`09:35:23` 那 6388 件**全在 `src/` 下**（非 `src` 的 = 0）⇒ 四类件数**逐格对账**：`26 + 6388 + 3 = 6417` ✓、`6385 + 2 + 1 = 6388` ✓ |
| 那 3 件 | `winbase_pinvoke.json`(09:41)、`DUCE_INVENTORY.md`(09:42)、`T1_SCOPE.md`(09:43) | 见 §5 末：它们是**上一轮 T1 spike 的产物**，不是上游件 |
| git 元数据 | **无 `.git/`**；只有 `.gitignore`(5992 B)、`.gitattributes`(1425 B) 两个**文本** | 快照**不是** git checkout ⇒ 无 commit 可读 |
| 本项目特征串 | **0 命中** | 本项目**没有**改写过上游树（与"`upstream/wpf/**` 只读"政策一致） |
| 40 位十六进制 | **1 处**，在 `src/Microsoft.DotNet.Wpf/src/PresentationBuildTasks/MS/Internal/MarkupCompiler/VersionHelper.cs` | 是源码内容，**不是** commit 串（无 `.git` 已先从结构上排除） |
| 传输伪影 | 3 处**大小写**被改（下表） | 非 git 传输留下的**硬证据** |

**大小写伪影**（Linux 上**大小写敏感**，所以这不是洁癖）：

| 树里的名字 | 上游真名（按 MSBuild 约定） | 后果 |
|---|---|---|
| `Microsoft.Dotnet.Wpf.sln` | `Microsoft.DotNet.Wpf.sln` | 只影响"按名字找 sln"的脚本；本仓用自己的 `wpf-linux.sln`，**当前 0 影响** |
| `src/Microsoft.DotNet.Wpf/Directory.Build.Props` | `Directory.Build.props` | Linux 上 MSBuild **不自动导入**（自动导入按精确大小写）⇒ 该文件的属性**默认失效** |
| `src/Microsoft.DotNet.Wpf/src/Directory.Build.Props` | `Directory.Build.props` | 同上 |
| （对照）顶层 `Directory.Build.props` | 拼写**正确** | ⇒ 伪影只打在 `src/` 下的两件上 |

那份"会失效"的 `src/Microsoft.DotNet.Wpf/Directory.Build.Props` 内容只有两条：`Import` 上一层 `Directory.Build.props` + `<NoWarn>$(NoWarn);CA1420;WPF0001</NoWarn>`。其中 **`WPF0001` 是 error 级诊断** ⇒ 不搬就会把可编过的工程判死。本仓的补偿在 `build/port-lib.py:40-61`（`upstream_nowarn()`）：**逐层向上、两种拼写都读**，只收 `NoWarn` 令牌。这是全仓**唯一**"必须知道上游这个伪影"的地方。

---

## 5. 裁剪证据（树内引用 × 树内缺失，成对出现）

判据：**上游自己的文件引用了一个路径，而该路径在树里不存在** ⇒ 该路径被裁掉了（不是"上游本来没有"）。

```bash
cd upstream/wpf
for p in Documentation Documentation/contributing.md eng eng/common .github packaging \
         src/Microsoft.DotNet.Wpf/redist src/Microsoft.DotNet.Wpf/tests; do
  [ -e "$p" ] && echo "存在 $p" || echo "缺失 $p"
done
grep -oE '\]\([A-Za-z0-9_./-]+\)' README.md | sort -u     # README 指向的仓内路径
```

| 被裁路径 | 树内**引用者**（引用者本身在树里） | 快照状态 |
|---|---|---|
| `eng/`、`eng/common/` | `global.json` 的 `errorMessage`：`Please run ./eng/common/dotnet.cmd/sh to install it` | **缺失** |
| `Documentation/contributing.md` | `README.md` 链接 | **缺失** |
| `Documentation/getting-started.md` | `README.md` 链接 | **缺失** |
| `.github/` | （上游 CI／模板所在；本快照无） | **缺失** |
| `packaging/` | （上游打包所在；本快照无） | **缺失** |
| `src/Microsoft.DotNet.Wpf/redist/`（`PresentationNative.vcxproj` 等） | `Microsoft.Dotnet.Wpf.sln:247` 直接列着该工程 | **缺失**（本仓在更早已记录：`build/MilBridge/T1-report.md:1141`、`:1331`） |
| `src/Microsoft.DotNet.Wpf/tests/` | （上游测试工程所在） | **缺失** |

⇒ **结论（已推翻"完整 checkout"这一假设）**：任何"本树逐字节等于上游某 commit"的比对**不可能直接成立**；必须先补齐裁剪面。**同时**：`src/` 下的**托管层**看起来是完整的（21 个工程子树、6,385 件，与解决方案里列出的工程一一对得上），而缺失面集中在 **构建基础设施（`eng/`）、文档、打包、非托管 `redist/`、测试** 上 —— 这与本快照的用途（在 Linux 上重编托管层 + 自建非托管位）是**吻合**的：真正被裁掉的正是"Linux 上编不了的 Windows 构建链"。

**三件本地追加件的出处**（它们不是上游件，是**上一轮工程的产物**）：

| 件 | 自述出处（件内首行） |
|---|---|
| `T1_SCOPE.md` | 依据 `DUCE_INVENTORY.md` 与 `winbase_pinvoke.json`；仓库 `/workspace/wpf2web/upstream-wpf/src/Microsoft.DotNet.Wpf/src/` |
| `DUCE_INVENTORY.md` | 分析范围 `/workspace/wpf2web/upstream-wpf/src/Microsoft.DotNet.Wpf/src/`（仅托管 `src` 层，MIT，**经 gh-proxy 克隆**） |
| `winbase_pinvoke.json` | 上述静态分析的机器产物（P/Invoke 清点） |

⇒ 快照的**搬运路径** = 某台机器上的 `/workspace/wpf2web/upstream-wpf`（**经 gh-proxy 克隆**）→ 复制进本仓 `upstream/wpf/`。⚠️ 这一条**只有文档自述**，**没有独立复算**（见 §9 缺口 3）。

---

## 6. 时间窗【推断】

**依据 A（in-tree，硬）**：`TargetFramework=net11.0` + `global.json` pin `11.0.100-preview.6.*`。
**依据 B（外部检索摘要，软）**：同世代兄弟仓在 **.NET 11 preview.6** 窗口里的 pin（`web_search` 返回的标题/摘要）：

| 来源（外部，仅摘要） | 读到的东西 |
|---|---|
| [dotnet/maui PR #36462](https://github.com/dotnet/maui/pull/36462) | "Bump dotnet/dotnet (BAR 321994) to **blessed preview.6.26357.118**" |
| [dotnet/maui PR #36184](https://github.com/dotnet/maui/pull/36184) | "Bump dotnet/dotnet to **preview.6.26325.125**" |
| [dotnet/maui release tag](https://github.com/dotnet/maui/releases/tag/11.0.0-preview.6.26360.8) | tag `11.0.0-preview.6.26360.8` |
| [dotnet/runtime commit b5388ad](https://github.com/dotnet/runtime/commit/b5388ad2d10c70dcc26b4c43592eb18e0e219bd5) | `"dotnet": "11.0.100-**rc.1**.26420.103"`（同世代、**更晚**的 serial） |
| [.NET 11 Preview 6 发布文](https://www.der-windows-papst.de/2026/07/25/net-11-preview-6/) | 页面日期 **2026/07/25** |

**推断**：本快照的 SDK serial `26359` 落在公开可见的 preview.6 serial 群（`26325` / `26357` / `26360`）**之内**，且**晚于** blessed `26357.118`、**早于** RC1 的 `26420` ⇒ 取树时间在 **"preview.6 已发布、`main` 仍 pin preview.6、尚未 bump 到 RC1"** 这个窗口里；与观测到的落盘时间 `2026-08-31` 相容（preview.6 发布 ≈ 2026-07-25）。

**反证条件（写清楚，别让它变成不可反驳的话）**：若在 `dotnet/wpf` 的 `main` 历史上找到**长于**该窗口仍保持 `11.0.100-preview.6.26359.118` 的区间，则窗口须放宽到该区间；若 `26359` 在公开 preview.6 serial 群之外，则依据 B 作废、只剩依据 A（"是 .NET 11 世代"）。

⚠️ **方法学限制（必须一起读）**：上表是 **`web_search` 的摘要**，**不是取回正文**——本机 `web_fetch` 对该域**不可用**（实测：`raw.githubusercontent.com` 30 s 超时；`dotnet/core` release-notes 页 `fetch failed`）。⇒ 依据 B **不进证据链**，只作窗口旁证。

---

## 7. 把 commit 钉死（第三方配方）

本仓环境**没有**到 github 的网络（同上）⇒ 这一节是**给别人跑的**配方，不是本仓已完成的动作。

```bash
# 1) 克隆上游（要网络）
git clone --filter=blob:none https://github.com/dotnet/wpf && cd wpf

# 2) 用 SDK pin 定位区间（pin 是逐字串，最适合 -S）
git log -S'11.0.100-preview.6.26359.118' --format='%H %ad %s' --date=short -- global.json

# 3) 拿到候选提交后，在候选树上复算本文 §3 的 M4/M3 并与读数比对
#    （本快照有 §5 的裁剪面 + §4 的大小写伪影 ⇒ **先补齐裁剪面**再比，否则必然不等）
```

**比对口径（重要）**：M3/M4 覆盖的是**本快照里存在的 6414 件**。要在上游候选 commit 上比，必须：

1. 用本快照的路径清单做**子集**比对（`find . -type f ! -name 'T1_SCOPE.md' ...`）；
2. 把 §4 的**大小写伪影**按上游真名还原（3 处）；
3. 再比 `sha256sum` 清单。

⇒ 预期结果：**逐文件全等**才能宣称"就是那个 commit"。任何一处不等都要先归因（裁剪面？伪影？上游在本快照之后又改过？）。

---

## 8. 本仓怎么用这份快照（只读政策 + 覆盖面事实）

- **政策**：`upstream/wpf/**` **只读**。移植不复写上游，而由 `build/*.Linux/*.csproj` 用 `Compile Remove`（Windows 专属件）+ `Compile Include`（生成的 `*.Linux.cs`）替换编译面；`build/port-lib.py` **整份重写**这些 csproj ⇒ **手工编辑会被抹掉**，接线必须落在应用器（`src/WpfGfx.Linux.Native/tools/patch-*.py`）里。
- **本文在外还是在内（逐行核对过的）**：`build/close-wave.sh` 的 `fp_inputs()` 覆盖面 = ①`src/WpfGfx.Linux.Native/tools` + `build` 下的 `patch-*.py`/`port-lib.py`/`integration-wave.sh`/`close-wave.sh`；②`build/shims/**/*.cs`；③`src/WpfGfx.Linux/**/*.cs`；④一份**逐件点名**的判据件清单（门禁、登记表、核对器、第三方 runner）。**`docs/` 与 `upstream/` 都不在里面** ⇒ 新增/修改本文**不移动** `inputs_fp`，也不改任何门禁读数。
- **覆盖是间接的**：改上游**有效件**会经生成物反映到九位（`bridge`/`pc`/`pf`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`hbtextline`/`dwf`）的 sha 与各道闸 ⇒ **会被抓住**。
- **缺口（诚实）**：**没有"上游字节"的直接牙**。上面那条只在"改动影响构建"时成立；改一个**不参与编译**的文件（或注释）⇒ **零机器红**。若要补：在 `verify-all` 加一步比对 **M3** 摘要即可——但那是"加一步"，会动步数/步名/口径句三处与冻结基线 ⇒ **必须单列一趟波**，不在本次收尾里顺手做。

---

## 9. 未确定项（诚实清单）

1. ~~**精确 commit**：未定~~ ⇒ ✅ **2026-09-20 已钉死**：`1cfc37f708f91ff4556bd25af414546c446f3a16`（`#11837`），判据与复算命令见 §1.1。（原先只能给「未定 + 配方」，因为树里没有 `.git`／没有 `Version.Details.xml`／没有任何 commit 串；钉死靠的是**外部 git 历史 + 逐件字节比对**。）
2. **裁剪面不完整**：只确证"上表 7 条路径**确实缺失**且被树内文件引用着"；**完整的**剔除清单无从得知（没有上游清单可比）。
3. **搬运工具/代理**：`gh-proxy` 一说**只有 `DUCE_INVENTORY.md` 自述**；本仓无网络，**未独立复算**。"非 git 传输"这一判断本身是**强证据**（无 `.git` + 同一秒级批量 mtime + 3 处大小写伪影 + `.jsonc`→`.jsonc.txt` 改名），但**具体哪个工具**不知道。
4. **三件本地追加件的内容**（`DUCE_INVENTORY.md` 的 143 条 MILCMD、`winbase_pinvoke.json` 的 357 条 P/Invoke 等）**未逐条复算**——它们在本仓是**参考资料**，不是任何判据的输入。
5. **§6 的时间窗**只有"in-tree 世代"是硬的；具体日期依赖外部检索摘要（本机 `web_fetch` 不可用）。
6. **`github-merge-flow.jsonc.txt`**：文件名被加了 `.txt`（上游真名 `github-merge-flow.jsonc`），内容是 .NET 9 时代的 `release/9.0-rc2 → release/9.0` 配置 ⇒ 既证明"传输改名"这一伪影，也说明该文件**与本次世代无关**。

---

## 10. 复算清单（照抄即可）

```bash
cd upstream/wpf

# 身份
sed -n '1,12p' Directory.Build.props; head -5 README.md; head -3 LICENSE.TXT; cat es-metadata.yml

# 世代
cat global.json

# 指纹（四条，读数应分别等于 §3 表里的 sha256）
find . -type f -printf '%P\t%s\n' | LC_ALL=C sort | sha256sum
find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum
find . -type f ! -name 'T1_SCOPE.md' ! -name 'DUCE_INVENTORY.md' ! -name 'winbase_pinvoke.json' \
  -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum
find . -type f ! -name 'T1_SCOPE.md' ! -name 'DUCE_INVENTORY.md' ! -name 'winbase_pinvoke.json' \
  -printf '%P\t%s\n' | LC_ALL=C sort | sha256sum

# 落盘形状
find . -type f -printf '%TY-%Tm-%Td %TH:%TM\n' | sort | uniq -c
find . -type f -printf '%TH:%TM:%TS\t%P\n' | sort | uniq -c              # 26/6388/1/1/1
find . -type f -newermt '2026-08-31 09:36' -printf '%TH:%TM  %P\n' | sort
grep -rlE 'WpfLinux|wpf-linux|SELFBUILT|WPF_LINUX' . | wc -l     # 0

# 裁剪面
for p in Documentation eng .github packaging src/Microsoft.DotNet.Wpf/redist \
         src/Microsoft.DotNet.Wpf/tests; do [ -e "$p" ] && echo "存在 $p" || echo "缺失 $p"; done

# 大小写伪影
ls | grep -i '\.sln$'; ls src/Microsoft.DotNet.Wpf | grep -i '^directory'
```

**任何一条读数与本文不符 ⇒ 本文作废，以现盘为准。**

---

## §9 附录：`upstream/wpf/.gitattributes` 的**上游原文**（逐字，2026-09-20 替换前保存）

> 保存理由：这是本仓对 vendored 快照的**唯一一处刻意偏差**（见 §3 顶部的更新说明）。
> 原文件指纹：**1425 B / 67 行 / sha256 `2c621eaf0983ae89…`**（本附录内容 = 其逐字原文）。
> 替换后的文件 = 3 行说明 + `* -text`（sha16 `a72f879fb536f5ce`）。
> 复算：`sha256sum upstream/wpf/.gitattributes`（应为替换后的值）＋ 本附录内容落地后应重现原指纹。

```gitattributes
# Set default behavior to automatically normalize line endings.
*   text=auto

*.doc   binary
*.DOC   binary
*.docx  binary
*.DOCX  binary
*.dot   binary
*.DOT   binary
*.pdf   binary
*.PDF   binary
*.rtf   binary
*.RTF   binary

*.jpg   binary
*.png   binary
*.gif   binary

# Force bash scripts to always use lf line endings so that if a repo is accessed
# in Unix via a file share from Windows, the scripts will work.
*.in    text eol=lf
*.sh    text eol=lf

# Likewise, force cmd and batch scripts to always use crlf
*.cmd   text eol=crlf
*.bat   text eol=crlf

*.cs    text=auto diff=csharp
*.vb    text=auto
*.resx  text=auto
*.c     text=auto
*.cpp   text=auto
*.cxx   text=auto
*.h     text=auto
*.hxx   text=auto
*.py    text=auto
*.rb    text=auto
*.java  text=auto
*.html  text=auto
*.htm   text=auto
*.css   text=auto
*.scss  text=auto
*.sass  text=auto
*.less  text=auto
*.js    text=auto
*.lisp  text=auto
*.clj   text=auto
*.sql   text=auto
*.php   text=auto
*.lua   text=auto
*.m     text=auto
*.asm   text=auto
*.erl   text=auto
*.fs    text=auto
*.fsx   text=auto
*.hs    text=auto

*.csproj    text=auto
*.vbproj    text=auto
*.fsproj    text=auto
*.dbproj    text=auto
*.sln       text=auto eol=crlf

# Set linguist language for .h files explicitly based on
# https://github.com/github/linguist/issues/1626#issuecomment-401442069
# this only affects the repo's language statistics
*.h linguist-language=C
```

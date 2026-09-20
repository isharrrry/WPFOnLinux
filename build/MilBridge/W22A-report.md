# W22A · `D-R3` 残项 (iii)：**判据① 的修前对照**（预登记 `#22` §1 = P1）

> `lane=W22A` ｜ 开工 `2026-09-16T19:40:49+0800` ｜ 收工读数 `2026-09-16T19:45:11+0800`
> `kernel=6.8.0-138-generic`（x86_64, VirtualBox）｜ `nproc=3` ｜ `loadavg` 开 `3.30 0.84 0.42` / 收 `4.70 2.40 1.12` ｜ `mem_available` 开 `3,467,168 kB` / 收 `3,156,104 kB`
> 预登记：`docs/WAVE22-PREREGISTRATION.md` = **`e6339689a41f2bfc`**（170 行）｜ 冻结基线 `#21` 表头 = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 整文件 **`0d048e6e8808c4e7`** ✅ 逐位相符
> **未重建任何产品件**；**未改任何既有文件**（只新建了本报告 + 私有 scratch）；构建只跑了被点名的 `ResolverGuardProbe` 一个工程。

---

## §0 一句话判决

**① 与 ④ 都不是 `D-R3` 的判据（两者在修前/修后都没有可观测的行为差异），但原因不是"恒绿"，而是更硬的 "修前件上不可测"：探针给 ① 用的调用点 `Win32ShimResolver.ShimVersionViaUser32` 是 `#18` **自己加进去的**，修前件里根本不存在（`REAL_DLLIMPORT=NOINFO method-absent`）。**

**真正有判别力的是 (a)/(b)/broken 这三类"抢占形态"的读数 —— 而且它们的分量比预登记以为的更大：修前件对这三类抢占给出的是 **逐字相同**的读数（机器证：`v1` 三变体两两 `IDENTICAL`、`v2` 三变体两两 `IDENTICAL`）⇒ `D-R3` 的缺陷本体 = **"任何抢占一律致命 + 成因误归"，而不是"抢占会不会静默"**。修后才把这三类**分开**（三类两两全部 `DIFFERENT`），并把"无害抢占"从灾难里救出来。**

判据①/④ **按预登记 §1.3-1 的第一分支改判为"正常路径回归锁"并登记**（但理由要按本报告改写：不是"两侧读数相同"，而是"**修前侧结构性不可得**"）。

---

## §1 要回答的四个问题 —— 逐条裁定（读数见 §3–§6）

| # | 问题 | 裁定 | 一句话 |
|---|---|---|---|
| 1 | 判据①（`realcall`）修前 vs 修后 | **改判为「正常路径回归锁」并登记** | 修前 `NOINFO method-absent`（调用点 = 修法的一部分）；**① 永远不可能因本缺陷而红** |
| 2 | 判据④ 修前 vs 修后 | **对 `D-R3` 零判别力 ⇒ 改判为「缺件不变式锁」并登记**；`#18` 的"④ 退回修前同款行为"**实测证实** | 可测的一极（安装点）**两侧逐字相同**；另一极（首个真 P/Invoke）修前同样 `NOINFO` |
| 3 | (a)/(b) 在修前件上 | **(a) 两极真实（修前红/硬失败 → 修后绿/无害）**；**(b) 修前"响亮"但"不点名"** ⇒ 按预登记字面，**"响亮"这个属性守卫没修**；但**"分类能力"是守卫引入的全新可观测位移** | 见 §5：修前 (a)≡(b)≡broken **逐字相同**，修后三者**全部不同** |
| 4 | `order1/2/3` 地基 | **仍然成立（实测，不是引用）** | 修后 `FOREIGN_INSTALL=OK variant=replica`（PC 与 WB 都是）⇒ 模块初始化器**不是**加载期跑的 |

**反极性：存在，且远不止一条**（§7 列了 7 条）⇒ **本件不作废**。

---

## §2 留档 sha16（纪律 15/18）

### §2.1 四份目标件 —— **开工前复核 + 收工后再复核，两次逐位不变**（读数全程可归因）

| 侧 | 件 | 期望 sha16 | **实测（开工）** | **实测（收工）** | size | mtime |
|---|---|---|---|---|---|---|
| **修前 V1**（无守卫） | `$HOME/w22-preserve/WindowsBase.dll.preV1-e6216fe961a2bfb9` | `e6216fe961a2bfb9` | ✅ `e6216fe961a2bfb9` | ✅ 同 | 1,241,088 B | 2026-09-16 12:41:42.333684425 +0800 |
| **修后 V1**（有守卫） | `build/WindowsBase.Linux/bin/Debug/WindowsBase.dll` | `1114a28ec5a03ab7` | ✅ `1114a28ec5a03ab7` | ✅ 同 | 1,242,624 B | 2026-09-16 18:46:58.927834497 +0800 |
| **修前 V2**（无守卫） | `$HOME/w22-preserve/WpfGfx.Linux.dll.preV2-0c597fb6ec1eec70` | `0c597fb6ec1eec70` | ✅ `0c597fb6ec1eec70` | ✅ 同 | 357,888 B | 2026-09-15 12:38:40.570125621 +0800 |
| **修后 V2**（有守卫） | `src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` | `c400ab1638e0c3d2` | ✅ `c400ab1638e0c3d2` | ✅ 同 | 358,912 B | 2026-09-16 15:08:58.429280035 +0800 |

**任务书要求复算的两位**（`#21` 九位）：`windowsbase 1114a28ec5a03ab7` ✅ ／ `hbtextline 76089e1de586ac91`（`build/shims/PresentationCore.HbTextLine.cs`，283,557 B，mtime 18:31）✅ —— **逐位一致，未触发"停并报告"**。

### §2.2 探针（**未改一行**）

| 件 | sha16 | size | mtime |
|---|---|---|---|
| `build/MilBridge/tests/ResolverGuardProbe/Program.cs` | `76caccc4693bf4a1` | 24,970 B | 2026-09-16 15:05:54.660348680 +0800（**V18A 留下的，本件未动**） |
| `build/MilBridge/tests/ResolverGuardProbe/ResolverGuardProbe.csproj` | `ece22ef0afc8b176` | 2,630 B | 2026-09-16 18:30:15.831624557 +0800（未动） |
| `…/bin/Release/net10.0/ResolverGuardProbe.dll`（**本轮构建产物**） | **`38abcc97017e65a6`** | 18,944 B | 2026-09-16 19:41:13.257652146 +0800 |

构建命令（**唯一一次 dotnet build**，`0 warning / 0 error`）：
```bash
$ export PATH="$HOME/.dotnet:$PATH"
$ dotnet build build/MilBridge/tests/ResolverGuardProbe/ResolverGuardProbe.csproj -c Release
  → 已成功生成。 0 个警告 0 个错误
```
**仓内被我写过的文件只有：本工程自己的 `bin/`+`obj/`，以及本报告**（`find $R/{build,src,docs,tests,samples} -newermt '2026-09-16 19:35' -type f` 的命中，除我的报告外全部落在 `build/MilBridge/tests/ResolverGuardProbe/{bin,obj}` 内）——符合任务书写域。

⚠️ **同一条 `find` 还命中 `build/MilBridge/tests/FrameProbe/obj/Release/**`（`FrameProbe.csproj`、`PresentationCore.Tests.dll` 等，mtime 19:4x）—— 那是本波另一条车道的构建，不是我的**（我全程只对 `ResolverGuardProbe.csproj` 跑过一次 `dotnet build`，见上面的命令）。它不影响本件读数：本件测的四个目标件与 `hbtextline` 在收工后仍逐位不变（§2.1 + 下方复核）。**照实记录，供主控归因。**

### §2.3 读数日志（`$HOME/w22a-runs/`，**原样留档**）

| 日志 | sha16 | size | 内容 |
|---|---|---|---|
| `pre.log` | **`6bd0a9304d5341c1`** | 13,873 B | 修前件全矩阵（①、V1 四变体、V2 四变体、mapload） |
| `post.log` | **`735832c2a3d82674`** | 16,378 B | 修后件全矩阵（同一脚本、同一参数） |
| `pre2.log` | `12b9e9a16950c7c2` | 13,875 B | **可复现性第二趟**（修前） |
| `post2.log` | `58154d2fd32b5a68` | 16,380 B | 可复现性第二趟（修后） |
| `iso-pre.log` | **`b25da1effa1d8e17`** | 3,288 B | 判据④隔离夹具（修前） |
| `iso-post.log` | **`bddbe9888987a129`** | 3,720 B | 判据④隔离夹具（修后） |
| `order-post.log` | **`44daaa0440209f24`** | 5,943 B | `order1/2/3`（修后，任务书字面） |
| `order-pre.log` | `040f16efb5c373ae` | 1,584 B | `order1/2/3`（修前，**我补的对照**） |
| `matrix.sh` / `order.sh` / `iso.sh` | `…/matrix.sh` 2,328 B ／ `order.sh` 1,957 B ／ `iso.sh` 2,977 B | | 本轮全部命令都在脚本里，可原样重跑 |

**可复现性（机器证）**：`diff <(grep -v '^PID=\|^TARGET=\|^# \|MAPS_TOTAL' pre.log) <(同上 pre2.log)` ⇒ **只差 `DONE=matrix label=` 一行**；`post`/`post2` 同。⇒ 读数**逐字节可复现**（`MAPS_TOTAL` 是已知的 ±2 JIT/GC 抖动，`#18` §10.2 已登记）。

### §2.4 承载件与调用点（**行号级 + 产物级**双重证据）

| 证据层 | 修前 | 修后 |
|---|---|---|
| 源 | `$HOME/wfp-runs/w18-laneV18A/backup/Win32ShimResolver.cs.before` = **`ff3c53964cb8328b`**：`Register()` 在 `:171-176` **只有** `SetDllImportResolver(...)` 一句，**没有**任何自证 | `build/shims/Win32ShimResolver.cs` = **`0735327b6ca3ae4b`**：`:201` `ResolverConflict = true;`／`:215-216` `if (installedByUs) return;`／`:225` `SelfCheckShimVersion = ShimVersionViaUser32();`／`:256` `private static extern int ShimVersionViaUser32();`／`:259` `ResolverConflict` 属性／`:265` `SelfCheckShimVersion` 属性 |
| **产物**（`grep -aoc`，ASCII 标记） | `WindowsBase.dll e6216fe961a2bfb9`：`SelfCheckShimVersion=0`、`ShimVersionViaUser32=0`、`ResolverConflict=0` | `WindowsBase.dll 1114a28ec5a03ab7`：`SelfCheckShimVersion=1`、`ShimVersionViaUser32=1`、`ResolverConflict=1` |
| **产物**（V2） | `WpfGfx.Linux.dll 0c597fb6ec1eec70`：`ResolverConflict=0`、`SelfCheckX11NameResolved=0`、`SelfCheckProbe=0` | `WpfGfx.Linux.dll c400ab1638e0c3d2`：`ResolverConflict=1`、`SelfCheckX11NameResolved=1`、`SelfCheckProbe=1` |

（`dump` 反射也逐条印证：修前 `X11Native` 成员表里**没有** `SelfCheckX11NameResolved`/`SelfCheckProbe`/`X11NameResolves`/`ResolverConflict`；修后有。）

---

## §3 问题 1 —— 判据①（`realcall`）的修前读数

### §3.1 原样读数

```text
$ dotnet …/ResolverGuardProbe.dll realcall /home/links-dev/w22-preserve/WindowsBase.dll.preV1-e6216fe961a2bfb9 --loadstream
LOADED=WindowsBase, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35
TRIGGER_TYPE=WpfLinux.Shims.WindowsBase.Win32ShimResolver
MODULE_INIT=NO_THROW IsWicMappingEnabled=True
REAL_DLLIMPORT=NOINFO method-absent          ← ★ 修前
RESULT=DONE
rc=0
```
```text
$ dotnet …/ResolverGuardProbe.dll realcall build/WindowsBase.Linux/bin/Debug/WindowsBase.dll --loadstream
LOADED=WindowsBase, Version=4.0.0.1, Culture=neutral, PublicKeyToken=31bf3856ad364e35
TRIGGER_TYPE=WpfLinux.Shims.WindowsBase.Win32ShimResolver
MODULE_INIT=NO_THROW IsWicMappingEnabled=True
REAL_DLLIMPORT=OK value=1                    ← ★ 修后
RESULT=DONE
rc=0
```

### §3.2 对照表

| 项 | 修前 `e6216fe961a2bfb9` | 修后 `1114a28ec5a03ab7` | 判定 |
|---|---|---|---|
| `MODULE_INIT` | `NO_THROW IsWicMappingEnabled=True` | 逐字相同 | **恒定** |
| `REAL_DLLIMPORT` | **`NOINFO method-absent`** | **`OK value=1`** | 字符串**不同**，但**不是行为差异** |
| （V2 侧）`realcall` on `WpfGfx.Linux` | `REAL_DLLIMPORT=THROW System.NullReferenceException: …` | **逐字相同** | **恒定**（且是探针缺陷，见 §9） |

### §3.3 裁定

**① 在修前件上 = `NOINFO`，而且这个 `NOINFO` 是结构性的、不可修补的：**

探针给 ① 用的调用点是 `Win32ShimResolver.ShimVersionViaUser32`（`Program.cs:198`）—— 而这个方法**本身就是 `#18` 的产物**（§2.4：修前产物里该标记出现 **0** 次，修后 **1** 次）。⇒

> **① 的修前对照**不是"没测过"，而是**"用这个仪器测不到"**。任何"再补一课就测到了"的说法都不成立：要测修前件，就得往修前件里塞一个修后才有的方法。

⇒ **① 按预登记 §1.3-1 的第一分支改判：`①` 对本缺陷零判别力，登记为「正常路径回归锁」。**

**补一条独立的、可测的理由**（不靠上面的"不可得"）：收窄之后，正常路径上 `Register()` 的行为与修前**同形**——修前是"装完即返回"，修后是"装完 → `if (installedByUs) return;`"。实测指纹：两侧 `v1 … none` 都 `TRIGGER=natural NO_THROW` + `RUNMODULECTOR=NO_THROW`；两侧 `mapload` 都是 `MAPS_WPFWIN32` **0→0**、`MAPS_LIBX11` **0→0**。⇒ ① 所描述的那个路径**在修前/修后是同一条路径** ⇒ 它**在原理上**不可能因 `D-R3` 而红。

**⚠️ 预登记 §1.3-1 的两分支（"相同"/"不同"）没有覆盖实况**：实况是第三态 `NOINFO`。若照字面把"`NOINFO` vs `OK`"读成"不同 ⇒ ① 有判别力"，就会把一个**仪器差异**当成**产品差异**。**这是本件必须点名的一条读法陷阱。**

---

## §4 问题 2 —— 判据④ 的两读

**先消歧（任务书未点明，现场实测后才清楚）**：`#18` 文本里 `④` 有两个落点 ——
- **④-原始**（`docs/WAVE18-PREREGISTRATION.md:31`）："**shim 文件缺失 ⇒ 仍然响亮失败**（不许被守卫吞掉）"；
- **④-收窄验收**（`V18A-report.md` §10.4 标题）："**正常路径 `/proc/self/maps` 回到修前**"。

两者我都取了读数。

### §4.1 夹具与隔离性自检（夹具**必须**是仓外的）

`Win32ShimResolver.cs:474-490` 的 shim 候选枚举里有"从 `AppContext.BaseDirectory` **和 cwd** 逐级向上找 `src/WpfGfx.Linux.Native`"⇒ **探针二进制自己留在仓内就会命中仓库产物，隔离失效**。故本件把**探针也搬到仓外**（`$HOME/w22a-iso/probe/`，与仓内探针 **同 sha `38abcc97017e65a6`**）。

```text
$ ls -d /home/links-dev/w22a-iso/src/WpfGfx.Linux.Native
ls: 无法访问 '…': 没有那个文件或目录                     rc=2   ✅
$ find /home/links-dev/w22a-iso -name 'libwpfwin32.so'
                                                          （空） ✅
$ ls -l <ISO>/libwpfwin32.so
ls: 无法访问 '<ISO>/libwpfwin32.so': 没有那个文件或目录   rc=2   ✅
```
夹具 = `build/WindowsBase.Linux/bin/Debug/*.dll` 整目录（依赖带齐）+ **只换** `WindowsBase.dll` 一份（修前 / 修后）。

### §4.2 ④-a 安装点（`variant=none` ⇒ 正常路径）

| 读数 | 修前 `e6216fe961a2bfb9` | 修后 `1114a28ec5a03ab7` | 判定 |
|---|---|---|---|
| `TRIGGER=natural` | `NO_THROW IsWicMappingEnabled=True` | **逐字相同** | **恒定** |
| `POISON_RECHECK` | `NO_THROW IsWicMappingEnabled=True` | **逐字相同** | **恒定** |
| `RUNMODULECTOR` | `NO_THROW` | **逐字相同** | **恒定** |
| `DIAG_ResolverConflict` | `NOINFO property-absent` | `False` | 仅"属性有无"之差 |
| `DIAG_SelfCheckShimVersion` | `NOINFO property-absent` | `0` | 仅"属性有无"之差 |

⇒ **`#18` 的登记"收窄后 ④ 现在等价于修前行为"经实测证实（不是推测）**：安装点在缺件时**两侧都不抛**。

### §4.3 ④-b 首个真 `[DllImport]`（`realcall`，同一隔离夹具）

```text
修前 REAL_DLLIMPORT=NOINFO method-absent                      ← 与 ① 同病：调用点不存在
修后 REAL_DLLIMPORT=THROW System.Reflection.TargetInvocationException: …
       | inner=System.DllNotFoundException:
         WPF-on-Linux: 'user32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库。
         搜索过程：
           · 不存在 <PROBEDIR>/libwpfwin32.so
         修复：先构建 shim —— src/WpfGfx.Linux.Native/build-shim.sh --all；或用 WPF_LINUX_WIN32_SHIM=<…> 显式指定。
```

### §4.4 ④-c 正常路径 dlopen 指纹（`mapload`，隔离夹具内）

| 读数 | 修前 | 修后 | 判定 |
|---|---|---|---|
| `MAPS_WPFWIN32` | `0 → 0` | `0 → 0` | **恒定** ✅ |
| `MAPS_LIBX11` | `0 → 0` | `0 → 0` | **恒定** |
| `MAPS_TOTAL` | `247 → 247` | `246 → 246` | 抖动（同 `#18` §10.2 ① 的 ±2 说明） |

（仓内非隔离夹具同款：修前 `245→245`、修后 `244→244`；`libwpfwin32.so` / `libX11` 两侧都 **0→0**。）

### §4.5 裁定

**④ 对 `D-R3` 零判别力，改判为「缺件不变式锁」并登记。** 两条理由：
1. **可测的那一极（安装点）修前/修后逐字相同** ⇒ 它**永远不会因 `D-R3` 而变**；
2. **另一极（首个真 P/Invoke 处响亮）在修前件上不可测**（`NOINFO method-absent`，与 ① 同一根因）⇒ ④ 也**没有真正的修前对照**。

⇒ 预登记 §1.3-2 说的"④ 可能是恒定的，必须实测" —— **实测成立**，而且是**"恒定 + 修前侧不可得"**双重。
⇒ **不许**把 §4.2 的"两侧都不抛"读成"守卫没问题"：它是**收窄的直接代价**（`#18` §10.5 已如实登记），本件只是把它变成了**读数**。

---

## §5 问题 3 —— (a)/(b) 在修前件上；**`D-R3` 的缺陷本体**

### §5.1 修前件的完整读数（V1 = `WindowsBase` `e6216fe961a2bfb9`，`--loadstream`）

| 变体 | 修前 | 修后（`1114a28ec5a03ab7`） |
|---|---|---|
| `none`（对照，不装抢先者） | `FOREIGN_INSTALL=SKIPPED(variant=none)`；`TRIGGER=natural NO_THROW IsWicMappingEnabled=True`；`POISON_RECHECK=NO_THROW…`；`RUNMODULECTOR=NO_THROW` | `TRIGGER=natural NO_THROW …`；`DIAG_ResolverConflict=False`；`DIAG_SelfCheckShimVersion=0`（**自证没在正常路径跑 = 收窄指纹**） |
| **(a) `replica`**（映射我们那 6 个名字 → 我们的 shim） | **`TRIGGER=natural THROW TargetInvocationException … inner=TypeInitializationException: The type initializer for '<Module>' threw an exception.`**；**`POISON_RECHECK=THROW`**；**`RUNMODULECTOR=THROW … inner=InvalidOperationException: A resolver is already set for the assembly.`**；`DIAG_* = NOINFO property-absent` | **`FOREIGN_HIT=user32.dll`**；**`TRIGGER=natural NO_THROW`**；**`POISON_RECHECK=NO_THROW`**；**`RUNMODULECTOR=NO_THROW`**；`DIAG_ResolverConflict=True`；**`DIAG_SelfCheckShimVersion=1`** |
| **(b) `different`**（我们的名字一个都不接） | **`TRIGGER=natural THROW`**（同上外包一层）；**`RUNMODULECTOR=THROW … inner=IOE: A resolver is already set for the assembly.`** | **`TRIGGER=natural THROW`**；**`RUNMODULECTOR=THROW … inner=IOE: WPF-on-Linux: 本程序集的 'user32.dll' 解析不到 —— **当前生效的解析器不是我们这一个**。／· 成因：…／· 后果：…／· 修法（二选一）：…／· 说明：…`** |
| `broken`（接名字但指向不存在路径） | **与 (b) 逐字相同** | `FOREIGN_HIT=user32.dll → <nonexistent>`；`THROW`，同款**点名**消息 |

（V2 = `WpfGfx.Linux`，`v2` 模式）修前 `replica`/`different`/`broken` **三者都** `CCTOR_THROW … inner=IOE: A resolver is already set for the assembly.` + `POISON_RECHECK=THROW`；修后 `replica`/`different` → `CCTOR_RESULT=NO_THROW` + `ResolverConflict=True` + `SelfCheckX11NameResolved=True`；`broken` → `CCTOR_THROW … inner=IOE: …本程序集的 'libX11.so.6' 解析不到 —— **当前生效的解析器不是我们这一个**…`。

### §5.2 ★ 机器证：**修前件对三类抢占给出逐字相同的读数**

用同一份日志按 `$ dotnet …` 分块、屏蔽只回显变体名的 `FOREIGN_INSTALL=OK variant=…` 行与表头行后逐字对比：

```text
--- pre: blocks = [mapload, realcall, v1×4, v2×4]
  pre v1 replica   vs different -> IDENTICAL ★
  pre v1 different vs broken    -> IDENTICAL ★
  pre v1 replica   vs broken    -> IDENTICAL ★
  pre v2 replica   vs different -> IDENTICAL ★
  pre v2 different vs broken    -> IDENTICAL ★
  pre v2 replica   vs broken    -> IDENTICAL ★
--- post: blocks = [mapload, realcall, v1×4, v2×4]
  post v1 replica   vs different -> DIFFERENT
  post v1 different vs broken    -> DIFFERENT
  post v1 replica   vs broken    -> DIFFERENT
  post v2 replica   vs different -> DIFFERENT
  post v2 different vs broken    -> DIFFERENT
  post v2 replica   vs broken    -> DIFFERENT
```

> **修前：6/6 对 `IDENTICAL`。修后：6/6 对 `DIFFERENT`。**

### §5.3 四个裁定（问题 3 的正式回答）

**(1) 修前件在 (b) 下是"响亮失败"，还是"静默降级/崩溃"？**
⇒ **响亮失败**。既**不是静默**（抛异常、模块被毒化、`POISON_RECHECK=THROW`），也**不是崩溃**（进程 `rc=0`，异常被探针捕获，无未捕获终止、无段错误）。
⇒ 但它是**"响亮却不点名"**：唯一给出的成因句是 `A resolver is already set for the assembly.` —— 这句把成因指向"**重复安装**"（一个**错误的**成因），而真正的成因（**赢家不映射我们要的那批名字**）**一个字都没说**。

**(2) 所以 `#18` 的守卫"没有修任何可观测的东西"这句话，成立吗？**
⇒ **在 (b) 这条上，逐字成立**：按 `WAVE18` §1 对 (b) 的字面定义（"**响亮** = …**当场失败并点名**"），拆成两半看 —— "**当场失败**"修前**本来就有**（不是守卫带来的），"**点名**"才是守卫带来的。⇒ **若把"响亮"理解为"不静默"，守卫在 (b) 上确实什么都没修**，改的只是文案。
⇒ **但整句"守卫什么都没修"是错的**：**(a) 这条上守卫修的是实打实的、可观测的东西** —— 修前 (a)（= `D-R2` 定案的"合法状态"：别人好心装了同一批名字的映射）会**把整个模块打死**；修后 `NO_THROW` + `SelfCheckShimVersion=1`（证明赢家接到的确实是我们那个 shim）。**这是本件新测出来的、预登记 §1.3 没提到的位移。**

**(3) 那么 `D-R3` 的缺陷本体是什么？**（本件的回答，比预登记更锐）
不是"抢占会不会静默"，而是：
> **修前件对任何抢占都一律致命、且把成因误归为"重复安装"；它连"无害抢占"与"有害抢占"都分不开（§5.2 的 6/6 `IDENTICAL`）。修后的位移 = ①把无害抢占从灾难里救出来、②把失败成因点名、③让三类抢占彼此可区分。**

**(4) 守卫的价值在哪一维？** ⇒ **集中在 (a)（无害抢占）这一维 + 文案维**。`(b)` 的"响亮"这一维**不是**它带来的。

### §5.4 ⚠️ 一条与任务书措辞冲突的读法提醒

任务书说 "**(a) 抢先者映射同名 ⇒ 无害**"。这是**修后的**性质。**修前 (a) 是有害的**（硬失败）。引用 "(a) 无害" 时必须带世代，否则会把 `#18` 的成果写成 `#18` 之前的事实。

---

## §6 问题 4 —— `order1/order2/order3`（各一次，修后件）

**读数（`order-post.log` `44daaa0440209f24`）**：

| 模式 | 目标 | 读数 |
|---|---|---|
| `order1`（`LoadFrom` 后立刻试装外国解析器） | `PresentationCore.dll e7cabff9417ed380` | `STEP=after-load` → **`FOREIGN_INSTALL=OK variant=replica`** |
| `order1` | `WindowsBase.dll 1114a28ec5a03ab7 --loadstream` | `STEP=after-load` → **`FOREIGN_INSTALL=OK variant=replica`** |
| `order2`（先 `GetType` 再试装） | PC / WB（类型 `…Shims.{PresentationCore,WindowsBase}.Win32ShimResolver`） | `TYPE_FOUND=True`、`STEP=after-gettype`，**`FOREIGN_INSTALL=OK variant=replica`** |
| `order3`（再 `RunClassConstructor` 之后试装） | PC / WB | `FOREIGN_INSTALL=OK variant=replica`、`FOREIGN_HIT=user32.dll`、**`RUNCTOR=OK`** |

**裁定：`#18` 赖以立论的地基——「模块初始化器**不是**在加载期跑的 ⇒ 外部安装者**可以**抢先」——仍然成立，且本件是**实测**得到的（不是引用 `#18`）。** `order3` 的 `FOREIGN_HIT=user32.dll` + `RUNCTOR=OK` 还顺带**独立复现了 (a) 无害**（守卫在输竞态分支里跑的自证，经由抢先者的 replica 解析器拿到了 shim，于是 `SHIM_VERSION=1`）。

**我补的对照（任务书没要求，但免费）**：`order-pre.log` `040f16efb5c373ae` —— 修前件 `order1`/`order2` 同样 `FOREIGN_INSTALL=OK variant=replica`（⇒ 地基与世代无关），而 **`order3` = `RUNCTOR_THROW … inner=IOE: A resolver is already set for the assembly.`**，且**没有** `FOREIGN_HIT=user32.dll`（因为自证压根不存在）。⇒ 又一条两极读数。

---

## §7 反极性汇总（纪律：**至少一条真的不同** ⇒ 本件不作废）

| # | 读数 | 修前 | 修后 | 维度 |
|---|---|---|---|---|
| 1 | `REAL_DLLIMPORT`（WB） | `NOINFO method-absent` | `OK value=1` | 调用点有无（**仪器**维） |
| 2 | V1 `(a) replica` `TRIGGER=natural` | **`THROW`** | **`NO_THROW`** | **行为**维 ★ |
| 3 | V1 `(a) replica` `DIAG_SelfCheckShimVersion` | `NOINFO property-absent` | **`1`** | **行为**维 ★ |
| 4 | V2 `(a) replica` `CCTOR_THROW` → `CCTOR_RESULT` | **`CCTOR_THROW`** | **`CCTOR_RESULT=NO_THROW`** | **行为**维 ★ |
| 5 | V2 `(b) different` `CCTOR` | **`CCTOR_THROW`**（不点名） | **`CCTOR_RESULT=NO_THROW`**（无害 + 具名诊断） | **行为**维 ★ |
| 6 | `RUNMODULECTOR` 消息文本 | `IOE: A resolver is already set for the assembly.` | `IOE: WPF-on-Linux: …解析不到 —— **当前生效的解析器不是我们这一个**。…` | 文案维 |
| 7 | `order3` | `RUNCTOR_THROW`（无 `FOREIGN_HIT`） | `RUNCTOR=OK` + `FOREIGN_HIT=user32.dll` | **行为**维 ★ |
| 8 | ★★ **三类抢占的可区分性** | **(a)≡(b)≡broken 6/6 `IDENTICAL`** | **6/6 `DIFFERENT`** | **分类能力**维 ★★ |

**在两棵树上逐字相同的读数（如实列出，供对拍）**：`v1 none`（`TRIGGER/POISON_RECHECK/RUNMODULECTOR` 全 `NO_THROW`）、`v2 none`（`CCTOR_RESULT=NO_THROW`/`POISON_RECHECK=NO_THROW`）、`realcall` on `WpfGfx`（`NullReferenceException`，见 §9）、`mapload` 正常路径（`MAPS_WPFWIN32`/`MAPS_LIBX11` 两侧 0→0）、隔离夹具 `v1 none`（两条 `NO_THROW`）。

---

## §8 我推翻 / 纠正 / 收紧的句子

1. **`#18` §10.5 的"① 的修前对照**没测到**" ⇒ 应改为"**测不到**"。**
   证据：`ShimVersionViaUser32` 是 `#18` 自己加的方法（§2.4 产物级 `0 → 1`）。"没测到"暗示补一趟就能测；事实是**用这个仪器不可能测**。
2. **预登记 §1.1 同一句话的同一处问题**（"① 的修前对照没测过"）⇒ 同上。
3. **预登记 §1.3-1 的两分支（"相同"/"不同"）不覆盖实况** —— 实况是 `NOINFO`。照字面把 `NOINFO → OK` 读成"不同 ⇒ ① 有判别力"会把**仪器差异**当成**产品差异**。这是本件最要紧的一条读法纠正。
4. **任务书 Q3 的措辞"若修前件在 (b) 下本来就响亮 ⇒ `#18` 的守卫没有修任何可观测的东西"** ⇒ **前半句实测成立，后半句只对 (b) 成立、对全局不成立**（(a) 维上有实打实的位移：修前硬失败 → 修后无害，§5.3(2)）。**不许**把它总括成"守卫什么都没修"。
5. **任务书/`#18` 对 (a) 的措辞"(a) 抢先者映射同名 ⇒ 无害"** ⇒ **必须带世代**：修前 (a) **有害**（模块毒化）。
6. **`#18` §10.5 的"④ 如今等价于修前行为"** ⇒ **实测证实**（§4.2 逐字相同）——不是推翻，是**把登记升级成读数**。
7. **预登记 §1.2 表格把"修前 `WindowsBase.dll`"的现成副本举为 `$HOME/w18a-build/bin/Debug/WindowsBase.dll` 等 10+ 份** ⇒ 现场核到的事实是：那些目录里能用的**修前**承载件我**没有**逐一复核；本件只用任务书指定的两份 `$HOME/w22-preserve/*`。**不主张**其它副本同 sha。
8. **夹具性质（不是缺陷）**：`WindowsBase.dll` 在本探针宿主里**无论修前修后**、**无论文件名**，`Assembly.LoadFrom` 都抛 `FileLoadException … manifest definition does not match the assembly reference (0x80131040)` ⇒ 必须 `--loadstream`。这与 `V18A-report.md` §7 的记载一致，且**两棵树同款**（`WpfGfx.Linux` 则两条腿都能 `LoadFrom`）。⇒ 读数不受影响。

---

## §9 探针自身的两处缺陷（**新登记**，本件未改探针）

**§9.1 `realcall` 对 V2 目标必然抛 `NullReferenceException`（两棵树逐字相同 ⇒ 零判别力）**
`Program.cs:185-198`：`FindShimResolverType(asm)` 对 `WpfGfx.Linux` 返回 **null**（它的类型名表里只有 `WpfLinux.Shims.{PresentationCore,WindowsBase,UIAutomation}.Win32ShimResolver`），随后 `:198` 直接 `t.GetMethod(...)` ⇒ 空引用。读数落成
```text
REAL_DLLIMPORT=THROW System.NullReferenceException: Object reference not set to an instance of an object.
```
**这看起来像"产品真 DllImport 失败"，其实是探针自己崩了。** 修法（建议，一行）：`:198` 前加 `if (t == null) { Console.WriteLine("REAL_DLLIMPORT=NOINFO reason=resolver-type-absent"); }` 并把 `:196-205` 整段包进 `t != null` 守卫。**未落地**（本件写域只许报告）。

**§9.2 `v2` 模式里 `FOREIGN_INSTALL=REJECTED` 是误读风险**
`Program.cs:334` 先打印 `FOREIGN_INSTALL=SKIPPED(variant=none)`（返回值 `false`），`:335` 又打印 `FOREIGN_INSTALL=REJECTED`（因为 `foreign==false`）⇒ 同一段里出现**两次 `FOREIGN_INSTALL=`**，而后一次读起来像"外国解析器被产品拒绝"。实际只是"没装"。消歧靠紧邻的 `SKIPPED(...)` 那一行。**未落地。**

---

## §10 未测清单（**不许读成已测**）

1. **判据②/③ 在 PC / UIAutomationTypes / UIAutomationProvider 三个 V1 承载件上未测** —— 本件只有 `WindowsBase` 的修前承载件。（`#18` 用的是 PC；我没有 `#17` 世代的 PC 产物。**现场核过**：`$HOME/w21a-pre/PresentationCore.dll.pre` = sha16 `f4a454c8fe69cdfe`／mtime `2026-09-16 15:40:28`／`SelfCheckShimVersion=1`、`ShimVersionViaUser32=1`、`ResolverConflict=1` ⇒ 它**已经带 V1 守卫**（是 `#19` 世代件、`#18` 之后），**不是修前件** ⇒ **未使用**。同理 `$HOME/w18a-build/bin/Debug/` 那一批也是 `#18` 的**修后**私有产物。）
2. **① / ④-b 的修前读数不可得**（非"未测"）：调用点不存在。**不补读数、不猜。**
3. **`lo`-级运行期证据未取**：本件全部是探针级读数；**没有**跑五臂门禁 / `verify-all` / 应用门禁 / 任何渲染用例（**不在本件射程，且任务书禁止**）。
4. **V2 的 (b) 是否"可能响亮"**：本件实测确认 `different` 在修后 **不抛**（与 `V18A` §6 的推翻一致），但**没有**再独立重证 `libX11.so.6` 是系统可解析名那条机制。
5. **`mapload` 的 `MAPS_TOTAL` 抖动幅度**：只观测到 ±1~2 行，未做统计。
6. **修前件 `order1/2/3`** 我**补测了**（`order-pre.log`），但任务书只要求修后件 —— 若主控认为这超出射程，请以任务书为准，读数仍然留档。

---

## §11 复现配方（全部命令都在脚本里，原样可重跑）

```bash
export PATH="$HOME/.dotnet:$PATH"
unset WPF_LINUX_WIN32_SHIM WPF_LINUX_WIC_SHIM WPF_LINUX_WIC WPF_LINUX_ROOT
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
cd "$R"   # ⚠️ 非隔离夹具必须从仓库根跑（shim 的仓库回退路径靠 cwd 向上找）

dotnet build build/MilBridge/tests/ResolverGuardProbe/ResolverGuardProbe.csproj -c Release
#   → …/bin/Release/net10.0/ResolverGuardProbe.dll  sha16=38abcc97017e65a6

bash $HOME/w22a-runs/matrix.sh pre  $HOME/w22-preserve/WindowsBase.dll.preV1-e6216fe961a2bfb9 \
                                   $HOME/w22-preserve/WpfGfx.Linux.dll.preV2-0c597fb6ec1eec70
bash $HOME/w22a-runs/matrix.sh post build/WindowsBase.Linux/bin/Debug/WindowsBase.dll \
                                   src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll
bash $HOME/w22a-runs/order.sh
bash $HOME/w22a-runs/iso.sh pre  $HOME/w22-preserve/WindowsBase.dll.preV1-e6216fe961a2bfb9
bash $HOME/w22a-runs/iso.sh post build/WindowsBase.Linux/bin/Debug/WindowsBase.dll
```
**注意**：`matrix.sh` 用 `--loadstream` 测 `WindowsBase`（`LoadFrom` 在本宿主必抛 `0x80131040`，两棵树同款）；`iso.sh` 会**把探针副本也放到仓外**（否则隔离失效，理由见 §4.1）。

---

## §12 给主控的落地建议（**本件不动任何既有文件**）

1. **`KNOWN-DEFECTS.md` / `CURRENT-STATE.md` 登记**：
   - `D-R3`-(iii) 的结论 = **① 与 ④ 双双降级**（①：正常路径回归锁；④：缺件不变式锁），且**修前对照结构性不可得**（不是"待补"）。
   - **`D-R3` 缺陷本体的新表述**（§5.3(3)）：修前 = **"抢占一律致命 + 成因误归 + 三类抢占不可区分"**；修后 = **"三类可区分 + 无害抢占被救出 + 成因点名"**。
2. **判据建议**：把 `P1` 那套 `(a)/(b)/broken` **三变体 × 两承载件**的"三类互相 `DIFFERENT`"做成**机器断言**（它才是真正有判别力的那一维；本件的 §5.2 脚本已现成）。① 与 ④ **不要再当"守卫的判据"引用**。
3. **探针缺陷**（§9.1 / §9.2）建议单开一小波修（都在 `Program.cs`，不碰产品件、零世代成本），修完需重取本件读数做对拍（本件日志已留 `38abcc97017e65a6` 基线）。
4. **若主控要"① 真的有修前对照"**：只有一条路 —— 造一个"把 `ShimVersionViaUser32` 单独编进 `#17` 世代载体"的**合成件**。**我不建议**：那是**自造对照**，不是修前件，会破坏"修前对照只能是旧产物"这条纪律。**驳回为默认。**

---

*报告自校验：本文件 = `build/MilBridge/W22A-report.md`，`sha256sum` 见最终回复。*

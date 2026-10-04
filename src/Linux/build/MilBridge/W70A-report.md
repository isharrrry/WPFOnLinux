# W70A 报告 —— `TASK-0301` 落地「零墨」修法（`D-G57` 单段行用错面）＋ `TASK-0202` `D-G72`（点菜单条 NRE 致死）

> 车道 **W70A**｜2026-09-21 12:12 → 12:37 +0800｜kernel `6.8.0-138-generic`｜`nproc=3`
> 仓根 `$R = /home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> 写域：**新建本报告** ＋ `build/shims/PresentationCore.HbTextLine.cs`（落地 `D-G57` 修法）＋ 重建出的
> `build/PresentationCore.Linux/bin/Release/PresentationCore.dll`；`$HOME/w70a/**` 全是仓外私有件。
> **未碰**：四个路由件、`defect-registry-declared.tsv`、`known-red.json`、`arm-logs/**`、`integration-wave.sh`、`close-wave.sh`、`verify-all.sh`。
> 报告自身 sha16 = 见 **§9**（自指文件无法把含本行的哈希写进本行）。

---

## §0 判据（**先落纸，读数后填**）

> 本仓铁律：判据先写进报告、读数后填；`NOINFO` 既不算绿也不算红。以下每条都写明"期望"与"不达标时怎么记"。

### 0.1 装置（唯一被测件 = `pc`；其余四件两侧逐位相同）

| 项 | 值 |
|---|---|
| 私有应用目录 | `$HOME/w70a/app`（`cp -a` 自 `$HOME/w61a/app`，即 W61A 那套读数件；**71 个文件**） |
| 五件（**两侧只差 `PresentationCore.dll`**） | `libwpfwin32.so 054037aadfd7d192`｜`wpfgfx_cor3.so e3ea092010734f44`｜**`PresentationCore.dll`（被测件）**｜`PresentationFramework.dll 1011da6390c3bf1e`｜`WindowsBase.dll 2e4e46e539a72cd7` |
| 五件合并指纹（负极） | `FIVE_FP=062a8eafac327b70`（含修前 `pc`） |
| 显示 | 自建 `Xvfb :198 -screen 0 1400x1050x24`（与 W61A 同几何 ⇒ 四区矩形可直接沿用） |
| 探针脚本 | `$HOME/w70a/bin/probe.sh`（**派生自** `$HOME/w61a/bin/probe.sh`，sha16 `02cb591d1eeda3b9`；改动逐处见 §6） ＋ `$HOME/w70a/bin/analyze.py` |
| 阈值 | 与 W47A/W52A/W61A **同法**：区域唯一色数 `colors` 与亮度 `fx:standard_deviation`（`analyze.py ink`） |

⚠️ **为什么不换权威件**：本修法只动 `pc`（由 shim 重建而来）。若用 `sync-applocal.sh` 拉权威五件，**桥会被一起换掉**（W62A 23:52 重发过桥，`79e45aed26487045` ≠ 本装置 `e3ea092010734f44`）⇒ 同一趟换两件 ⇒ **归因不成立**。故本趟**只** `cp -p` 被测那件 `pc`。

### 0.2 判据清单（C1–C8）

| # | 判据 | 期望（正极 = 修后） | 不达标时的记法 |
|---|---|---|---|
| **C1** | **机制级**：`HBLINE D#…` 站点 D 里 `实用例子/样式模板/控件/工具/请输入关键字` 的 `[r0 face=…]` | 由 `DejaVuSans.ttf` **变为** `NotoSansCJK-Regular.ttc` | 不变 ⇒ **机制未生效**，正极作废（不许只看像素） |
| **C2** | **像素级 · 页签行** `228x27+318+318` | `colors` **> 1**（负极 = 1） | ≤1 ⇒ 正极不成立 |
| **C3** | **像素级 · 按钮** `203x27+328+284` | `colors` **> 8** 且非众数像素 **≫ 10**（负极 = 8 / 10） | 同上 |
| **C4** | **像素级 · 搜索框 Placeholder** `176x27+328+358` | `colors` **> 19**（负极 = 19） | 同上 |
| **C5** | **零回归（强判据）**：导航项 `203x27+328+391`（多段行） | `colors=69`、`stddev=10.47%`、**非众数像素 = 303** —— **逐位不变** | 任一变 ⇒ **本修法打红了既有读数**，必须点名上报 |
| **C6** | **下划线带** `228x4+318+343`（非本修法射程） | `colors=2`、非众数像素 156（`y=345/346` 各 116 px `#326CF3`） —— **逐位不变** | 变 ⇒ 同上 |
| **C7** | **反极性**：`cp -p` 逐字节还原 shim ＋ `pc` | 区域读数**回到** `1 / 8 / 19`；`hbtextline=e89fed55fd8e32bc`、`pc=9465f9dce39e2dfc`（`cmp` 双证） | 回不去 ⇒ 修法"不可逆/不归因"，**本件作废** |
| **C8** | **既有绿判据不被本修法打红** | `HbTextLineParity`（编**真 shim 源**）与 `PcLineOracle`、`D5CbrProbe`、`FrameProbe` 的读数：**除预期列外逐字节相同** | 任一新红 ⇒ 点名上报，**不许压绿** |

### 0.3 预测（**先写死**）

* `hbtextline` **必变**（本件就是改 shim）⇒ 预期 `e89fed55fd8e32bc` → `921ba9c65e9fb3be`（W61A §2.3 曾落地过同一 diff，报的就是这个值；**W61A 是另一趟的读数，本趟必须自己复算**）。
* `pc` **必变**（shim 内容 sha 会被 `patch-presentationcore-hbtextline-shimsha` 写进程序集元数据 ⇒ 即使代码路径不变也会变）。
* 其余七位（`bridge`/`pf`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf`）**逐位不变**（我不构建它们）。
* 负极四格应**逐位复现** W61A §3.1：`1 / 8 / 19 / 69`。

---

## §1 开工现场

| 项 | 读数 |
|---|---|
| 时间 | 2026-09-21 12:12 开工（`BRIEF.md` 3,806 B 读完） |
| 仓内九位（现场复算，**与 W61A §0 逐位相同**） | `bridge=79e45aed26487045`｜`pc=9465f9dce39e2dfc`｜`pf=1011da6390c3bf1e`｜`windowsbase=2e4e46e539a72cd7`｜`provider=1f9511a7ef395bfe`｜`win32shim=11aa9d8fa154f20f`｜`wic_shim=56278c14b4ecd672`｜**`hbtextline=e89fed55fd8e32bc`（290,825 B）**｜`dwf=de2d555105b7d04b` |
| 被引件核对 | `build/shims/PresentationCore.HbTextLine.cs` = `e89fed55fd8e32bc` ⇒ **与 diff 基线一致**（`patch --dry-run` **rc=0**）；`~/w61a/diff/W61A-D-G57-shim-singleface.diff` = `cac51d6f54ad9845`（3,284 B / 42 行，与派单书一致） |
| `hc-linux` 真应用目录五件 | `win32shim=11aa9d8fa154f20f`｜`bridge=79e45aed26487045`｜`pc=9465f9dce39e2dfc`｜`pf=1011da6390c3bf1e`｜`wb=2e4e46e539a72cd7` |
| 报告口径核对（**不是手抄**） | 派单书给的 `W61A-report.md sha16=81b920d6755516bb` —— 现场 `sed '/^> 报告自身 sha16 = /d' … \| sha256sum \| cut -c1-16` = **`81b920d6755516bb`** ✓（该报告的 sha16 口径是"删掉自指那一行"；直接 `sha256sum` 得 `79880bd4b6414648` —— **两者都对**，是口径差，不是抄错） |
| 内存三值 | 开工 **2,122 MB**（12:12）｜最低 **1,505 MB**（12:34，那趟 FATAL 未跑成 ⇒ **不是读数**；有效读数区间 **1,885–2,717 MB**）｜收工 **2,488 MB**（12:36）｜`loadavg` 开工 `0.62 0.40 0.41`／峰值 `5.02 3.95 2.81`／收工 `2.62 3.33 2.77`（详见 §9.2） |

---

## §2 负极（修前）读数（全部实测，非引用）

**取数条件**：`W70A_APP=$HOME/w70a/app`（五件 `FIVE_FP=062a8eafac327b70`，`PresentationCore.dll=9465f9dce39e2dfc`）＋ 自建 `Xvfb :198 -screen 0 1400x1050x24` ＋ 窗口 `Absolute upper-left 300,225 / 800x600 / IsViewable` ＋ 槽内 `HEAVYSLOT=ACQUIRED waited=0s`、`timeout 110`、`unhandled=0`、`APP_RC=124`（我自己的 timeout 收尾，**不是崩溃**）。
命令：`W70A_APP=$HOME/w70a/app W61A_TIMEOUT=110 bash ~/w70a/bin/probe.sh neg1 :198 census`

| 区域（屏幕坐标） | `colors` | `stddev` | 众数色 | 非众数像素 | 判读 |
|---|---|---|---|---|---|
| **页签行** `228x27+318+318` | **1** | **0.00 %** | `#FFFFFF`(6156/6156) | **0** | **零墨** |
| **「实用例子」按钮** `203x27+328+284` | **8** | 0.15 % | `#EEEEEE`(5471/5481) | **10** | 只有圆角 AA |
| **搜索框 Placeholder** `176x27+328+358` | 19 | 2.71 % | `#FFFFFF`(4441/4752) | 311 | 只有放大镜图标 |
| **导航项（对照）** `203x27+328+391` | **69** | **10.47 %** | `#FFFFFF`(5178/5481) | **303** | 有墨 |
| **下划线带** `228x4+318+343` | 2 | 22.00 % | `#FFFFFF`(756/912) | **156** | `y=345/346` 各 116 px `#326CF3` |
| `root.png` sha16 | **`9380291b84d81dd6`** | | | | **与 W61A `diag1`/`diag2` 逐位相同** |
| 机制负读数 | `grep -ac 'HBLINE D#'` = **0** | | | | ⚠️ **`census` 档不含 `WPF_LINUX_HBLINE_TRACE`** ⇒ 机制级读数取不到（**配方缺口**，见 §6.2）；机制负极改由 §5 的还原腿补 |

⇒ **`1 / 8 / 19 / 69` ＋ 下划线 `2/22.00%/156` ＋ `root.png 9380291b84d81dd6` 与 W61A §3.1 逐位相同**（跨车道、跨半天、跨进程 ⇒ 渲染确定性成立，且我这套装置与 W61A 的**是同一只尺**）。

---

## §3 修法落地

| 件 | before sha16 | after sha16 | 字节 |
|---|---|---|---|
| `build/shims/PresentationCore.HbTextLine.cs` | `e89fed55fd8e32bc` | **`921ba9c65e9fb3be`** | 290,825 → **293,165** |
| `build/PresentationCore.Linux/bin/Release/PresentationCore.dll`（`pc`） | `9465f9dce39e2dfc` | **`21e3e88a5090cd3b`** | 3,601,408 → 3,601,408 |

* 落地方式：`patch build/shims/PresentationCore.HbTextLine.cs < ~/w70a/diff/W61A-D-G57-shim-singleface.diff` ⇒ `PATCH_RC=0`，**无 `.rej`／无 `.orig`**。
* 备份（`cp -p`，仓外）：`$HOME/w70a/backup/PresentationCore.HbTextLine.cs.PRE`（`e89fed55fd8e32bc`）＋ 四份 `pc`（`PresentationCore.dll.PRE_{RELEASE,DEBUG,HCAPP,W70AAPP}`，**四份现场复算彼此逐位相同** = `9465f9dce39e2dfc`）。
* 重建命令（**从 `build/integration-wave.sh` 同名步骤抄，未整波跑**）：
  `bash ~/heavy-slot.sh --min-avail 1500 --max-hold 120 --wait 600 -- timeout 110 dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Release -m:1 --nologo -v q`
  ⇒ `HEAVYSLOT=ACQUIRED waited=0s` / `HEAVYSLOT=MEMOK avail=3073MB` / **0 个警告 0 个错误 / 00:00:27.67** / `HEAVYSLOT=RELEASED rc=0 held=28s`。
* **程序集元数据已跟着走**（这是 `pc` 必变的机械原因，不是推测）：`build/PresentationCore.Linux/obj/Release/HbTextLineShimSha.g.cs` = `[assembly: AssemblyMetadata("HbTextLineShimSha", "921ba9c65e9fb3be9e31d402fd98568ee78639063d75bb4e656b20201b30dc2b")]`（新 sha **全 64 位**）。
* **两个 sha16 都与 W61A §2.3 独立复算一致** ⇒ 同一 diff 的落地是**确定性**的，两条车道互证。
* 只换被测那一件：`cp -p <新 pc> $HOME/w70a/app/PresentationCore.dll` ⇒ `FIVE_FP 062a8eafac327b70 → 121844b3efad8302`（**其余四件逐位未动**）。

---

## §4 正极（修后）读数

**取数条件**：同 §2，**只换 `pc` 一件**（`FIVE_FP=121844b3efad8302`，`pc=21e3e88a5090cd3b`）＋ **另加** `W61A_EXTRA="WPF_LINUX_HBLINE_TRACE=1"`（为了同一趟拿到 C1 机制读数；该开关**纯只读**，见 §6.2）。
命令：`W70A_APP=$HOME/w70a/app W61A_TIMEOUT=110 W61A_EXTRA="WPF_LINUX_HBLINE_TRACE=1" bash ~/w70a/bin/probe.sh pos1 :198 census`

### 4.1 C1 · 机制级（站点 D 的 `face=`）

`grep -ac 'HBLINE D#'` = **43**（负极那趟 = **0**，因为没开开关；机制负极见 §5.2）。命中五处文案：

```
HBLINE D#0 cpFirst=0 brush=#FF212121         glyphRuns=1 [r0 face=NotoSansCJK-Regular.ttc glyphs=4 chars="实用例子"]
HBLINE D#0 cpFirst=0 brush=LinearGradientBrush glyphRuns=1 [r0 face=NotoSansCJK-Regular.ttc glyphs=4 chars="样式模板"]
HBLINE D#0 cpFirst=0 brush=#FFBDBDBD        glyphRuns=1 [r0 face=NotoSansCJK-Regular.ttc glyphs=6 chars="请输入关键字"]
HBLINE D#0 cpFirst=0 brush=#FF212121        glyphRuns=1 [r0 face=NotoSansCJK-Regular.ttc glyphs=2 chars="控件"]
HBLINE D#0 cpFirst=0 brush=#FF212121        glyphRuns=1 [r0 face=NotoSansCJK-Regular.ttc glyphs=2 chars="工具"]
```

旁证：多段行（导航项）**照旧 3 个 run** ⇒ 多段分支一行未执行：
`[r0 face=DejaVuSans.ttf glyphs=1 chars=""] [r1 face=NotoSansCJK-Regular.ttc glyphs=5 chars="选项卡控件"] [r2 face=DejaVuSans.ttf glyphs=1 chars=""]`

### 4.2 C2–C6 · 像素级（同一脚本、同一阈值、同一几何）

| 区域 | 负极 | **正极** | 期望 | 判读 |
|---|---|---|---|---|
| **C2 页签行** `228x27+318+318` | 1 / 0.00 % / 非众数 **0** | **`colors=90` / 9.03 % / 非众数 259** | `>1` | ✅ **零墨消失** |
| **C3 按钮** `203x27+328+284` | 8 / 0.15 % / **10** | **`colors=120` / 10.30 % / 非众数 335** | `>8` 且 ≫10 | ✅ |
| **C4 搜索框** `176x27+328+358` | 19 / 2.71 % / 311 | **`colors=67` / 5.56 % / 非众数 768** | `>19` | ✅ |
| **C5 导航项（零回归强判据）** `203x27+328+391` | 69 / 10.47 % / **303** | **`69` / `10.47 %` / `303`** | **逐位不变** | ✅ 逐位不变 |
| **C6 下划线带** `228x4+318+343` | 2 / 22.00 % / **156** | **`2` / `22.00 %` / `156`** | **逐位不变** | ✅ 逐位不变 |
| `root.png` sha16 | `9380291b84d81dd6` | **`149ad2330fd4a1a9`** | 变（三区有墨） | 变，且只由被测件引起 |
| `alive` / `unhandled` | yes / 0 | **yes / 0** | 不许崩 | ✅ |

⇒ **C1/C2/C3/C4 四条正极判据全部成立**；**C5/C6 两条零回归判据逐位成立**。

---

## §5 反极性（逐字节还原）

### 5.1 还原的机械证明

| 件 | 还原前 | 还原方式 | 还原后 | 证 |
|---|---|---|---|---|
| `build/shims/PresentationCore.HbTextLine.cs` | `921ba9c65e9fb3be`（293,165 B） | `cp -p $HOME/w70a/backup/PresentationCore.HbTextLine.cs.PRE` | **`e89fed55fd8e32bc`**（290,825 B） | `cmp` = **IDENTICAL** |
| `pc`（重建） | `21e3e88a5090cd3b` | 同一条 `dotnet build … -c Release -m:1` | **`0d8993521d5517d0`** | 见 §5.3（**不是**冻结值，原因已定死） |
| `pc`（摆回冻结件，供 §5.2 腿） | — | `cp -p backup/PresentationCore.dll.PRE_RELEASE` | **`9465f9dce39e2dfc`** | `cmp` = **IDENTICAL**（= §2 负极那一件） |

### 5.2 还原腿的实测读数（`~/w70a/logs/neg2`，`FIVE_FP=062a8eafac327b70` ＝ §2 的**同一套五件**）

| 区域 | §2 负极（neg1） | **还原腿（neg2）** | 判读 |
|---|---|---|---|
| 页签行 | 1 / 0.00 % / 0 | **1 / 0.00 % / 0** | **逐位相同** |
| 按钮 | 8 / 0.15 % / 10 | **8 / 0.15 % / 10** | 逐位相同 |
| 搜索框 | 19 / 2.71 % / 311 | **19 / 2.71 % / 311** | 逐位相同 |
| 导航项 | 69 / 10.47 % / 303 | **69 / 10.47 % / 303** | 逐位相同 |
| 下划线带 | 2 / 22.00 % / 156 | **2 / 22.00 % / 156** | 逐位相同 |
| `root.png` sha16 | `9380291b84d81dd6` | **`9380291b84d81dd6`** | **逐位相同**（且与 W61A diag1/diag2 同值） |
| 机制级 `HBLINE D#`（这趟开了 `WPF_LINUX_HBLINE_TRACE=1`） | （neg1 未开开关 ⇒ 0 行） | **43 行；五处文案的 `[r0 face=DejaVuSans.ttf]`** | **机制负极也取到了** |

机制负读数的原样三行（供逐字对照 §4.1）：
```
HBLINE D#0 cpFirst=0 brush=#FF212121         glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=4 chars="实用例子"]
HBLINE D#0 cpFirst=0 brush=LinearGradientBrush glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=4 chars="样式模板"]
HBLINE D#0 cpFirst=0 brush=#FFBDBDBD        glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=6 chars="请输入关键字"]
```
⇒ **C7 成立**：还原后**零墨逐位回来**，`root.png` 逐字节回到负极值；正/负两极的差别**只**由被测件引起。

### 5.3 ⚠️ 一条必须写明的偏差：**重建**还原态 shim 得到的 `pc` **≠ 冻结值**

* 实测：还原 shim（`e89fed55…`，`cmp` IDENTICAL）后重建 ⇒ `pc = 0d8993521d5517d0`，**不是** `9465f9dce39e2dfc`。
* **不是构建不确定**（两极化实测）：`touch` shim（**内容不变**、sha 不变、只推 mtime ⇒ 强制真重编译）后再跑**同一条命令** ⇒ **又是 `0d8993521d5517d0`**，`cmp` **IDENTICAL**；且修后 shim 的构建在 **W61A（09-21 00:12）与我（09-21 12:19 / 12:31）三次独立执行**下**逐位同值** `21e3e88a5090cd3b`。
  ⇒ **`pc` 具备逐位可复现性**（同源同命令 ⇒ 同值）；收尾链世代位可以继续按"值相等"判。
* 差异的**性质**：`cmp -l 冻结pc 重建pc | wc -l` = **72 字节**，且只落在 **5 个聚簇** —— `0x88`(4 B, COFF `TimeDateStamp`)、`0x2DA1F0`(16 B, MVID)、`0x36E484`(4 B, 调试目录时间戳)、`0x36E4D8`(16 B, PDB GUID)、`0x36E566`(32 B, PDB SHA-256 校验和)。**文件其余 3,601,336 字节逐位相同** ⇒ **IL／`#Strings`／`#Blob`／`#~` 表全同**；两份 pc 内含的 `HbTextLineShimSha` 串**都是** `e89fed55fd8e32bc` ⇒ 两份都是修前 shim 建的。
* **已排除的候选（都有读数）**：① SDK/编译器（`~/.dotnet/sdk` 只有 `10.0.111`，装于 09-10 ⇒ 冻结与现在同一套）；② shim 内容（同 sha）；③ `build/**` 下比冻结 pc 新的 `.cs/.csproj/.props/.targets` = **0 个**；④ **D-G58 那三个文件不在 pc 的编译输入里**（`grep -n "WpfGfx.Linux" build/PresentationCore.Linux/PresentationCore.Linux.csproj` = **0 命中**，且该工程 `EnableDefaultCompileItems=false`、`Compile Include` 逐条列出）—— 派单/主控给的这条归因**不成立**，如实报。
* ⇒ **`NOINFO(冻结 pc 与当前源重建值之差的确切输入)`**；但"同源可复现"这条已由两极化与三次独立构建坐实，**不登记为缺陷**。
* **纪律后果（写给收尾链）**：还原腿里的 `pc` **必须**用 `cp -p` 摆回冻结件（W61A §3.2 的配方本来就是这么写的）；**不许**用"重建还原态"来声称"逐字节回退"。

---

## §6 探针与装置改动（如实登记：我动了仪器）

| 件 | 原值 | 我的改动 | 新 sha16 |
|---|---|---|---|
| `$HOME/w70a/bin/probe.sh`（**派生自** `$HOME/w61a/bin/probe.sh`，仓外，W61A 的件一位未动） | `02cb591d1eeda3b9`（派生后） | ① `APP`/`OUT` 缺省指向 `$HOME/w70a/**`；② `analyze.py` 路径改指向我的副本；③ **内层 `heavy-slot.sh` 补 `--min-avail 1500 --max-hold 120`**（W61A 原版内层**没有**内存闸门与持有上限）；④ `SLOTWAIT` 600 / `APP_TIMEOUT` 110；⑤ **新增 `W70A_CLICK_XY`**（任意屏幕坐标点一下，`D-G72` 用；W61A 原版只有"点导航项"） | **`3c02ee1d24d12744`** |
| `$HOME/w70a/bin/analyze.py` | 逐字节＝W61A 件 | **未改** | 同 W61A |
| `$HOME/w70a/bin/wgmon.c`（**新件**，D-G72 机制探针） | — | 新建（`cc -O0`） | 见 §8 |
| `$HOME/w70a/app`（71 文件） | — | `cp -a` 自 `$HOME/w61a/app` 的快照 | 五件见 §2 |

### 6.1 ⚠️ 配方坑（**先报给主控，已实测**）

**`probe.sh` 自己内部就调 `~/heavy-slot.sh`** ⇒ 若按派单书"把整条命令包进槽"再包一层，**外层持锁、内层等同一把 `$HOME/heavy.lock`** ⇒ 内层必 `HEAVYSLOT=TIMEOUT` ⇒ 整趟被记成 `NOINFO`（**假阴性，且会被误读成"资源不足"**）。本趟的处理：应用探针**只**在 `probe.sh` 内部那一层加 `--min-avail 1500 --max-hold 120`（不套外层）；`dotnet build` 这类**不自带槽**的重活才用派单书给的外层。

### 6.2 ⚠️ 另一个配方坑：W61A §3.2 的 `census` 档**取不到机制级读数**

`census` 档的 env 是 `HC_GEO_EVERY` ＋ `WPF_LINUX_{DRAW,GLYPH,GLYPH_FACE}_CENSUS` ＋ `WPF_LINUX_LINEHEIGHT_TRACE` ＋ `HBLINE_ENVS`，**不含 `WPF_LINUX_HBLINE_TRACE`** ⇒ 站点 D 的 `HBLINE D#…[r0 face=…]`（W61A §1.5 用来定死判定点的那条读数）**一行都不打**（我按配方跑的 neg1 实测 `grep -ac 'HBLINE D#'` = **0**）。本趟正/负两极都**另加** `W61A_EXTRA="WPF_LINUX_HBLINE_TRACE=1"`（该开关纯只读，见 shim `:2424`），C1 才拿到读数。

---

## §7 零回归（既有绿判据）

### 7.1 tline 臂（`HbTextLineParity`，**它直接编真 shim 源**）——同代 A/B，**只差 shim 一个输入**

方法：把 `pc`（树的权威件 ＋ 臂 `bin/Release` 的副本）**两腿都钉在同值**（`21e3e88a5090cd3b`），只用 `-p:HbShimSrc=` 切换 shim 源 ⇒ 两腿**只差 shim**。命令：
```
dotnet build build/MilBridge/tests/HbTextLineParity -c Release -m:1 --nologo -p:HbShimSrc=<PRE|真源>
cd bin/Release && T1B_SHIM_SHA256=<对应sha> dotnet MilBridge.HbTextLineParity.dll
```

| 判据 | PRE 腿（`e89fed55…`） | POST 腿（`921ba9c6…`） | 结论 |
|---|---|---|---|
| `通过 / 失败` | **22 / 2** | **22 / 2** | **不变** |
| ❌ 逐条 | `T3 Collapse…`、`T3b 折叠明细契约级…` | **同两条，逐字相同** | **没有新红** |
| 73 例 CJK 逐行全等 | `exact=73 diff=0` | `exact=73 diff=0` | 不变 |
| 记账结构 `Height`/`Baseline` | `1298/1298`、`1298/1298` | `1298/1298`、`1298/1298` | 不变 |
| **`Extent` 行级一致** | **`1223/1298`** | **`96/1298`** | ⚠️ **读数大幅位移** |
| LH 组 `Extent 一致 @0.34` | `5/10` | **`0/10`** | ⚠️ 同上 |
| `[② Extent 余差清单]` | **95 条**（主 75 ＋ LH 20） | **1242 条**（主 1202 ＋ LH 40） | ⚠️ **同上，且这条被登记表钉着** |
| `T2d` 判据状态（宽口径 0.34） | 无该 ❌ | 无该 ❌ | 不变 |

**⚠️ 这条位移必须点名（不许压绿）**：`build/MilBridge/known-red.json` 的 **`entries[1]`** 是
`{"arm":"tline","case_id":"T2d-Extent余差","field":"Extent余差条数","expected_shape":"count==95","generation":"#23","red_authority":"读数 count>0"}`。
我的修法把它推到 **1242** ⇒ 该条谓词 `count==95` 不成立，而 `red_authority: count>0` 仍成立
⇒ 按 `tline-gate.sh:1031-1038` 的语义会判成 **`KNOWN_RED_DRIFT`**，进而 `reasons.append("registry-stale(drift)")`（`:1204`）
⇒ **既有门禁会变红**。**这不是"某个绿判据被打红"，而是"一条被登记为 95 的读数漂到 1242，登记表过期"**
（门禁自己就是这么写的："红仍在，但读数漂移 ⇒ 登记表需更新"）。

**机器读数（我真跑了门禁：只读读者，`--outdir` 在我自己目录；五臂日志 = 我的 POST 日志 ＋ 既有 `arm-logs/` 四支）**：
```
TLINE_GATE=NOINFO arms=5 red=0 green=0 noinfo_arm=5 drift=0 gone=0 caliber=MISMATCH generation=#23 tree_gen=advanced
GATE_REASON=noinfo-arms        （rc=2）
  NOINFO(arm) tline :: 口径不一致：instr_shim 登记=e89fed55fd8e32bc 实测=921ba9c65e9fb3be
  NOINFO(arm) tab-oracle-* / textlineproto :: 树已前进（树 shim=921ba9c6… ≠ 登记 shim=e89fed55…）⇒ NOINFO
```
⇒ **口径精确化（我先前的说法要收窄）**：门禁**第一道**就卡在"树已前进 ⇒ 口径不一致"⇒ 现状是 **`NOINFO`（不是绿，也不是那条 drift 红）**；`drift=0` 是因为**根本没走到**逐条判定那一步。
**可预期的后果（写给 W71A，别当已发生）**：把世代重钉到新 shim 之后，口径检查放行 ⇒ 逐条判定会走到 `entries[1]` ⇒ `count==95` 对 **1242** 判假、`count>0` 判真 ⇒ **`KNOWN_RED_DRIFT` ⇒ `registry-stale(drift)` ⇒ 门禁 FAIL**。
⇒ 重钉时**必须同趟**更新 `entries[1].expected_shape`／`expected_reading`（或由主控另裁），**否则重钉之后立刻红**。
另：`generation.instr_shim = e89fed55…` 本身就是旧 shim ⇒ 任何改 shim 的波都必然要重钉世代。

**机制上的解释（讲得通，故不是"仪器坏了"）**：shim 的 `Extent` = 逐 run `gr.ComputeInkBoundingBox()` 的并集
（`shim:3434/3443-3460`，与上游 `SimpleTextLine.cs:1796-1802` 同一条公式）⇒ **面一改，墨迹盒就改**。
修前是"用 A 面的字形 id 去 B 面取轮廓"（账本不自洽），修后自洽但相对真机 oracle 的差变大。
**"修后是否更对"我判不了** ⇒ **`NOINFO(Extent 修后与真机的接近度谁更对)`**（本机字体是代用集，"真值"本身带代用偏差；要判需要真机重录）。

### 7.2 其余绿判据

* `FrameProbe`/`PcLineOracle`/`D5CbrProbe`：**本趟未跑**（时间与槽），见 §9 `NOINFO`。
* 应用级零回归：**导航项 69/10.47%/303 与下划线带 2/22.00%/156 两极逐位不变**（§4.2/§5.2），`root.png` 的两极值各自确定 ⇒ 修法射程**只**落在"单段行"。

---

## §8 `TASK-0202` · `D-G72`（点顶部菜单条 ⇒ NRE ⇒ 进程死）—— **已修（但第二处理由主控定：它是第二处世代位）**

### 8.1 现象与判定点（**首次拿到 `文件:行`**）

点 hc 客户区 **+150,+14**（屏幕 `450,239`；窗口 `300,225` 起）⇒ 进程 **`rc=134`** 死。异常栈**带 pdb 行号**（app 目录里有 `HandyControl.pdb`）：

```
Unhandled exception. System.NullReferenceException: Object reference not set to an instance of an object.
   at HandyControl.Tools.ScreenHelper.FindMonitorRectsFromPoint(Point point, Rect& monitorRect, Rect& workAreaRect)
        in /home/links-dev/hc-linux/src/Shared/HandyControl_Shared/Tools/Helper/ScreenHelper.cs:line 81
   at HandyControl.Controls.MenuTopLineAttach.Popup_Opened(Object sender, EventArgs e)
        in .../Controls/Attach/MenuTopLineAttach.cs:line 63
   at System.Windows.Controls.Primitives.Popup.OnOpened(EventArgs e) …（Popup.cs:400 ← CreateWindow:1568 ← OnIsOpenChanged:357）
   … ← MenuItem.OpenMenu()（MenuItem.cs:2302） ← MenuItem.ClickHeader()（MenuItem.cs:2283）
```
`ScreenHelper.cs:77-81` 就是那三行：
```csharp
InteropValues.MONITORINFO monitorInfo = default;                                  // :77  40 字节
monitorInfo.cbSize = (uint) Marshal.SizeOf(typeof(InteropValues.MONITORINFO));    // :78  = 40
InteropMethods.GetMonitorInfo(intPtr, ref monitorInfo);                           // :79
monitorRect   = new Rect(monitorInfo.rcMonitor.Position, monitorInfo.rcMonitor.Size);  // :80
workAreaRect  = new Rect(monitorInfo.rcWork.Position,  monitorInfo.rcWork.Size);       // :81 ← 抛点
```

### 8.2 真判定点 = **我们 shim 的 `GetMonitorInfo` 写越界 32 字节**（不是 hc 的逻辑错）

`src/WpfGfx.Linux.Native/src/win32_core.c` 的 `GetMonitorInfoW` **从不读调用方的 `cbSize`**，却**无条件**写 `szDevice[32]`；
而托管侧有**两套形状**：`MONITORINFO`（**40 B**，无 `szDevice`）与 `MONITORINFOEX`（**72 B**，含 `szDevice[32]`，`win32_abi.h:222`）。
hc 传的是 40 B ⇒ **越界写 32 字节，直接踩在调用方的栈上**。
`docs/U2-M7b-report.md:226` **早在 U2 就写下过这条预测**："症状会是 `GetMonitorInfo` 把 32 字节写越界踩掉后面的栈" —— 一直没兑现成读数，本趟兑现了。

**机制探针（新件 `$HOME/w70a/bin/wgmon.c`，`dlopen` 真 `.so`，调用方形状照抄 hc 的 40 B ＋ 后置 64 B 哨兵 `0xA5`）**：

| 格 | 修前（`11aa9d8fa154f20f`） | **修后（`c493639d15678803`）** |
|---|---|---|
| `cbSize=40`（hc 真实姿势） | `ret=1` **`OVERWRITE_BYTES_PAST_STRUCT=32`** | **`ret=1` `OVERWRITE_BYTES_PAST_STRUCT=0`** |
| `cbSize=0`（畸形） | `ret=1` **越界 32**（畸形也照写） | **`ret=0` 越界 0**（如实失败，`SetLastError(87)`） |
| `cbSize=72`（`MONITORINFOEX`） | `ret=1 dev="X11"` 越界 0 | `ret=1 dev="X11"` 越界 0（**未回退**） |
| `MonitorFromPoint(100,100)` | `0x1` | `0x1` |

原文读数留档：`$HOME/w70a/out/wgmon-PRE.txt`、`wgmon-POST.txt`。

### 8.3 修法（逐处）

* `src/WpfGfx.Linux.Native/src/win32_core.c`：`GetMonitorInfoW` 读 `cbSize` → `cb < offsetof(WPF_MONITORINFOEX, szDevice)`(=40) ⇒ `SetLastError(87)`＋`FALSE`＋**一个字节都不写**；`cb >= 40` 写基线字段；**只有** `cb >= 72` 才写 `szDevice`。＋`#include <stddef.h>`。
* before/after：`win32_core.c` `529d999e4818568d` → **`ba1d9ba959da163c`**（105,688 B → 见 §9.3 字节数）；`libwpfwin32.so` `11aa9d8fa154f20f` → **`c493639d15678803`**（322,056 B，`build-shim.sh` rc=0；**唯一警告**是 `win32_misc.c:224 -Wmisleading-indentation`，在**我未改动**的文件里，属既有）。
* 备份：`$HOME/w70a/backup/{win32_core.c.PRE, libwpfwin32.so.PRE}`。

### 8.4 两极化（三种 `.so`，**其余四件完全相同**：`pc=21e3e88a5090cd3b`）

| 腿 | `.so` | 点 `(450,239)` 后 | 读数 |
|---|---|---|---|
| **C（反极性）** | `11aa9d8fa154f20f`（= 现权威、**无** cbSize 修） | **死** | `alive=no` / `unhandled=1` / **`APP_RC=134`** / NRE @ `ScreenHelper.cs:line 81`（`~/w70a/logs/posC`） |
| **B（正极）** | **`c493639d15678803`**（= 11aa9d8f ＋ cbSize 修） | **活** | `alive=yes` / `unhandled=0` / `NullReferenceException` 计数 **0** / `APP_RC=124`（我自己的 timeout 收尾）（`~/w70a/logs/pos2`） |
| 旁证（修前件） | `054037aadfd7d192`（W59A 之前的件） | **死**，同一栈同一行 | `APP_RC=134`（`~/w70a/logs/neg2`，正是 W59A 说的"修前件同样可复现"） |

⇒ **判据成立**：修后同一点击 ⇒ **存活且无 NRE**；还原 `.so` ⇒ **又 134**（同一行、同一栈）。
⇒ 机制归因**闭合**：唯一变量是 `GetMonitorInfo` 的写入边界。

### 8.5 为什么"不越界"就修好了（机制，带保留）

hc 那两行读的是**结构体字段**（本不该 NRE），所以严格说"越界写"与"NRE"之间我**没有**做到逐字节的因果证明（越界落在 40 B 结构体之后的 32 字节里，那 32 字节是哪个栈槽、由谁持有，我没测出来）。
**但两极化已经把它钉成机制**：`cbSize=40` 那条路唯一的差别是"写不写第 40..71 字节"，而**恰好这一个差别**决定 134 / 存活 ⇒ `NOINFO(越界 32 字节具体踩掉哪个栈槽的逐字节证明)`，**但"越界 ⇒ 崩 / 不越界 ⇒ 不崩"是实测的**。

### 8.6 ⚠️ 交接口径：`win32shim` 是**第二处世代位** ⇒ 收尾链要一起排

* `win32shim` `11aa9d8fa154f20f` → **`c493639d15678803`**（权威件 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`）。
* **我只重建了权威件那一份**，其余副本（`close-wave.sh` 第 2 步负责"同步 4 份并断言同 sha"）**未同步** ⇒ 现树里 `libwpfwin32.so` 副本 sha 不齐，**`close-wave.sh --native` 会做这件事**（我没跑整波，那是 W71A 的活）。
* 同时 `defect-registry` 与 `known-red.json` 都要重钉（见 §7.1 与 §9）。

---

## §9 边界 · `NOINFO` · 内存三值

### 9.1 `NOINFO` 清单（**没做到的一格 ＋ 确切条件**）

1. **`NOINFO(冻结 pc 与当前源重建值之差的确切输入)`** —— 排除项与"同源可复现"证据见 §5.3；差异只落在 5 个身份戳聚簇。
2. **`NOINFO(Extent 修后与真机 oracle 谁更对)`** —— 修后 `Extent` 余差 95 → **1242**（同代 A/B、只差 shim）；本机字体是代用集（无 MS YaHei），"真值"本身带代用偏差 ⇒ 要判必须**真机重录**。**我不把"修后更自洽"写成"修后更对"。**
3. **`NOINFO(越界 32 字节逐字节踩到哪个栈槽)`** —— 两极化已定性（§8.5），微观因果未逐字节证明。
4. **`NOINFO(FrameProbe / PcLineOracle / D5CbrProbe 的修前修后)`** —— 时间与重活槽没排上；它们的输入含 `pc`，`pc` 已变 ⇒ **不能引用旧读数**。
5. **`NOINFO(真机 or 用户级验收：hc 示例窗口内逐文案肉眼可读)`** —— 我只有**区域像素**与**进程内 `face=`**两条读数；没有 OCR/人工确认。
6. **`NOINFO(31 个导航页里同族零墨文本的普查)`** —— 本次窗口右页是图片演示页；预测"整行 CJK 且无拉丁/无隐形 run 的单段行"同族，**未逐页跑**。
7. **`NOINFO(用户实际看见的那份件)`** —— 用户跑的是 `hc-linux/.../bin/Debug/net10.0/`，我**没动它**（不在我写域）；本报告全部应用读数取自 `$HOME/w70a/app`（`cp -a` 自 W61A 的读数件，只换被测件）。**要用户看到修好，需要 W71A 走 `close-wave.sh` 的同步步**（`pc` ＋ `libwpfwin32.so` 两件）。
8. **`NOINFO(全五臂 / verify-all / 应用门禁)`** —— 派单书明确不属本车道。

### 9.2 内存三值 ＋ loadavg（派单书要求）

| 项 | 读数 |
|---|---|
| `MemAvailable` **开工** | **2,122 MB**（12:12，开工自检） |
| `MemAvailable` **最低** | **1,505 MB**（12:34，posC 第一趟）—— ⚠️ 该趟因 `:198` 被我自己的 pos2 占着而 **FATAL 未跑成**，**不是读数**；有效读数落在 **1,885–2,717 MB** |
| `MemAvailable` **收工** | **2,488 MB** |
| `loadavg` | 开工 `0.62 0.40 0.41`｜峰值 `5.02 3.95 2.81`（pos2 期间）｜收工 `2.62 3.33 2.77` |
| 槽纪律 | 每趟重活都在 `~/heavy-slot.sh` 内；**未出现** `HEAVYSLOT=MAXHOLD_KILL`、`HEAVYSLOT=NOINFO`、`rc=137`；收工 `dotnet`/MSBuild 残留 **0**；**零 `pkill -f`**（一次按 PID 都没用上，全部进程正常退出） |
| 槽持有 | 构建最长 30 s（`max_hold 120`）；探针最长 158 s（`max_hold 260`） |

### 9.3 树终态（**收工时的实际值，脚本现场算**）

| 位 | 值 |
|---|---|
| `hbtextline` | **`921ba9c65e9fb3be`**（293,165 B）—— 修法**在位** |
| `pc` | **`21e3e88a5090cd3b`**（3,601,408 B）—— **在修后 shim 状态下重建**（`cmp` = 该次构建产物） |
| `win32shim`（权威件） | **`c493639d15678803`**（322,056 B）—— `D-G72` 修法**在位**；**副本未同步**（交 `close-wave.sh --native`） |
| 其余七位 | `bridge 79e45aed26487045`｜`pf 1011da6390c3bf1e`｜`windowsbase 2e4e46e539a72cd7`｜`provider 1f9511a7ef395bfe`｜`wic_shim 56278c14b4ecd672`｜`dwf=de2d555105b7d04b` —— **一位未动** |
| 仓内被改的文件 | `build/shims/PresentationCore.HbTextLine.cs`、`src/WpfGfx.Linux.Native/src/win32_core.c`、`build/PresentationCore.Linux/bin/Release/PresentationCore.dll`、`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`、本报告（＋ `build/MilBridge/tests/HbTextLineParity/{bin,obj}` 的常规构建产物） |

---

## §10 大白话小结（≤6 行）

1. **页签/按钮/占位符没字这件事，修好了**：根因是"字形按 A 面（NotoSansCJK）整形、却拿 B 面（DejaVuSans）去画"；改成"按计划要面画"后，页签行墨量从 **1 色/0.00%** 涨到 **90 色/9.03%**，按钮 **8→120 色**，搜索框占位符 **19→67 色**，导航项与下划线带**逐位没动**。
2. **两极都实测到了**：把 shim 与 `pc` 逐字节还原 ⇒ 四个区域**逐位回到** `1 / 8 / 19 / 69`，截图 sha 回到 `9380291b84d81dd6`；`hbtextline` 现在 **`921ba9c65e9fb3be`**、`pc` **`21e3e88a5090cd3b`**（在修后状态下重建，两趟同值）。
3. **但有一条必须你知道的账**：这个修法把 tline 臂的 `Extent` 余差从 **95 条推到 1242 条**（同代 A/B、只差 shim 一个输入）——`通过 22 / 失败 2` 与两条既有 ❌ **没变**，可 `known-red.json` 把 `Extent余差条数` **钉成 `count==95`**；门禁**现在**读成 `TLINE_GATE=NOINFO`（`caliber=MISMATCH`：树已前进），**重钉世代之后**会走到那一条 ⇒ 判 `registry-stale(drift)` **变红**。⇒ **重钉时必须同趟改这一条**（我没碰登记表）。
4. **顺带把 `D-G72` 修了**：点菜单条必死（`ScreenHelper.cs:81` NRE、`rc=134`）的根因是**我们 shim 的 `GetMonitorInfo` 不读 `cbSize`、对 40 字节的调用方越界写 32 字节**（老早 U2 报告就预测过这条，今天才兑现成读数）；修后同一点击**存活、零 NRE、零异常**，还原 `.so` **又 134**。
5. **`win32shim` 因此成了第二处世代位**：`11aa9d8fa154f20f → c493639d15678803`；**我只建了权威件**，4 份副本的同步、登记表/基线重钉、五臂重取、`verify-all` 都在 W71A 手里。
6. **没做到的**：`FrameProbe`/`PcLineOracle`/`D5CbrProbe` 没跑；"Extent 修后是否更对"本机判不了（要真机重录）；用户那份 `hc-linux` 应用目录**我没动**（要 W71A 走同步步，否则你屏幕上看不到变化）。

---

## §11 本报告自身 sha16

**口径**：删掉本行后整份文件的 `sha256sum | cut -c1-16`（与 W61A/`W59A` 报告的自指口径一致；自指文件无法把"含本行的哈希"写进本行）。

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
sed '/^> 报告自身 sha16 = /d' build/MilBridge/W70A-report.md | sha256sum | cut -c1-16
```

> 报告自身 sha16 = `acb6bcc321648fdf`

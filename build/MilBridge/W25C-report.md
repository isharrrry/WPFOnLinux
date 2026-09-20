# W25C 报告 —— **登记结算**（3 条结构族帧红建书面登记 + `known-red-PC-copies.md` 按世代结算）

- **车道**：`W25C`（文档/登记车道）｜**开工** 2026-09-17 12:23 +0800 ｜**收工** 2026-09-17 12:3x +0800
- **预登记**：`docs/WAVE25-PREREGISTRATION.md` §1（W25C 行）、§4、§7、§8
- **机器**：`nproc=3`｜kernel `6.8.0-138-generic`｜开工 `loadavg 0.39/0.23/0.20`、`MemAvailable 3,575 MB`
- **硬约束遵守**：**零 `dotnet`**（全程未调用 `dotnet`/`msbuild`/`verify-all`）｜**零 `pkill`**｜
  **未用 `pgrep -f` 单独下结论**（只在 `/proc/*/cmdline` 里看进程是否存在，用来**回避**读同一个文件）
- **写域**（仅这三个文件）：
  1. `build/MilBridge/known-red-frame-structural.md`（**新建**）
  2. `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md`（追加三节）
  3. `build/MilBridge/W25C-report.md`（本文件）
- **未碰**：`build/MilBridge/known-red.json`（现场复核 sha16 与 `#24` 记录一致 ⇒ 未动）、
  `check-applocal-sync.sh`（**W25B 写域**，我只**读**它、并在**沙箱副本**上跑它）、
  `applocal-expect.py`、`docs/**`、`handoff.md`、`samples/**`、任何基线文件。

## 摘要（结论在前）

1. **3 条结构族帧红已建书面登记**：`build/MilBridge/known-red-frame-structural.md`
   （before = 不存在｜after `db3b449112daedd1`，14,371 B）。**条目数 = 3，与探针点名的 3 条一致**
   （三条腿 `结构红=3` × 3 腿 = 9 次点名，**去重后 3 个 `id`**）。
2. **它是只读的（有实证，不是自称）**：消费者集合 = **空**（`FrameProbe`/`frame-step.sh` 里
   `grep 'known-red\|registry\|在册'` 各 **0 命中**；新文件全仓 **0 引用**）；
   同机制姊妹文件的**沙箱三趟实测**证明"有登记 / 空登记 / **登记文件整份不存在**"三种状态下
   `rc`、`计数：`、`APPSYNC=`、`scan() 内部 rc=` **逐字相同**，剔段后输出 `cmp IDENTICAL`。
3. **13 份副本的世代结算已完成**：`known-red-PC-copies.md` `e5946a8a7ce1cfe0 → 8497a0ca1689cf90`
   （6,109 → 26,822 B）。**历史 13 行一字未改**（`diff` 证明只**增**行：`<` 侧 **0** 行）。
4. **世代归属结论**：**12 份 `PresentationCore.dll` 副本** =
   `登记态 #23（e7cabff9417ed380）` → **`#24`（`476994e35d31a7e1`）下一度已转绿**，
   **"已转绿"只在 `pc == 476994e35d31a7e1` 下成立**（换世代即回落）；
   **第 13 份**（`tools/GeometryOracle/…/WpfGfx.Linux.dll` `16baacfccfcf1df0`）= **与 `pc` 世代无关**，归
   `WpfGfx.Linux.dll`（`c400ab1638e0c3d2`）的世代，**今天仍红**。
5. **⭐ 世代切换在本次开工期间被现场逮到（最硬的证据）**：12:30 W25A 重建 `pc` ⇒
   权威 `476994e35d31a7e1 → 7374308a00c55572`（4,197,376 → 4,197,888 B，mtime 12:30:42）
   ⇒ **那 12 份的"已转绿"在同一分钟内全部回落为"仍红"**（12:32 实测：**已转绿 0 / 仍红 13**）。
   **这不是回归，正是纪律 52 要的"按世代结算"** —— 完整时间线已写进登记文件 §7。
6. **世代绑定已做两极性实证**（本地沙箱、仓库零改动）：同一份登记 + 同一份副本，**只换权威 sha** ⇒
   `[在册红·已转绿] ⇄ [在册红]` **两个方向都成立**，`rc` 三趟相同（1/1/1）⇒ 本段**不参与判定**。
7. **一处与登记表口径不符（如实上报）**：登记表写"全仓 `PresentationCore.dll` 共 33 份"，
   12:25 现场枚举为 **34 份**（= 权威自身 1 + 非权威 33）⇒ 那是"含不含权威自身"的口径差，
   **不是**多出/少了副本。**在册红条目数仍是 13，与现场点名一致。**
8. **`#24` 的裁决（3 条无处在册）已解除**：那 3 条今天**有处可登记**；
   **但没有**把任何一条压成绿 —— 探针 `probe_rc=1`、`frame-step.sh` 的口径**一字未动**。

## 1 · 写域清单 + before/after sha16

| 文件 | before sha16 | after sha16 | before 字节 | after 字节 | 备份 |
|---|---|---|---|---|---|
| `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md` | `e5946a8a7ce1cfe0` | **`8497a0ca1689cf90`** | 6,109 | 26,822 | `$HOME/w25c-backups/known-red-PC-copies.md.before`（`cp -p`，sha16 与 before 同值） |
| `build/MilBridge/known-red-frame-structural.md` | **不存在**（新建） | **`db3b449112daedd1`** | — | 14,371 | 无需备份（新文件） |
| `build/MilBridge/W25C-report.md` | 不存在 | 见文末（现场算） | — | — | — |

**未动（现场复核）**：

```
e623d2b17d948e3b  32602  build/MilBridge/known-red.json          ← 与 #24 冻结记录同值 ⇒ 未动
7bc9364091a28fd4  86734  build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh   ← **W25B** 的写域（12:27:48 由它改）
503e6ebd86d70303  43380  build/MilBridge/tests/FrameProbe/Program.cs              ← 探针本体未动
37f27df68e52bf8c  12429  build/MilBridge/tools/frame-step.sh                     ← 判据脚本未动
476994e35d31a7e1  4197376 build/PresentationCore.Linux/bin/Debug/PresentationCore.dll ← 权威 pc（现场算）
```

## 2 · 件 ①：3 条结构族帧红的书面登记

**落点**：`build/MilBridge/known-red-frame-structural.md`（新建）。形态**仿** `known-red-PC-copies.md`：
开头即声明"**登记 ≠ 已容忍**"，并自述**不参与判定**、**不产生任何 `rc`/计数器效应**。

### 2.1 逐条内容（`id` / 位置 / 自报字段 / 取证来源）

**共同身份**：`text = "\tb\tc"`（`textId` = `lead-tab-b-t-c`）、`paragraphWidthDip = 40`、`emSizeDip = 24`、
`flowDirection = LeftToRight`、`script = latin`、`textWrapping = Wrap`、`incrementalTabArm = DefaultIncrementalTab=0`、
`fontFamily = Arial`、`dpi = 96`；**真机**（语料自报）`lineCount = 2`，两行 = `"\tb"` / `"\tc"` ⇒ **真值帧 = `[0, 2]`**。

| # | `id`（逐字） | 取到 / 未取到的字段 | 取证来源（文件:行） |
|---|---|---|---|
| 1 | `B-indent/lead-tab-b-t-c@w40@LTR@i24@tab0` | 取到：我方各行 `cpFirst=[0,1,2,3]`、行数我方 `4`、真值 `[0,2]`/`2`、判定行 `2`、红行 `1`、接手档 `strict`、帧 `(扫描)=1`、`cpFirst=1`、真值帧 `2`、`Length=1`、行类型 `HbTextLine`；**未取到**：逐字符几何（本登记不需要） | `/home/links-dev/w24b-run/final-logs/strict.log:27`（CASE）、`:79`（RED 点名） |
| 2 | `B-indent-extra/lead-tab-b-t-c@w40@LTR@i0p24@tab0` | 同上（`indentArm=i0p24`、`paragraphIndentDip=24`） | 同档 `:54`（LINECOUNT）、`:55`（CASE）、`:80`（RED） |
| 3 | `B-indent-extra/lead-tab-b-t-c@w40@LTR@i24nl@tab0` | 同上（`firstLineInParagraph=false`） | 同档 `:57`（LINECOUNT）、`:58`（CASE）、`:81`（RED） |

**三条腿点名（同一批三条）**：`strict.log:79-81`｜`lenient.log:79-81`（差异仅在 `_lineStart` 反射值 `1 → 0`）｜
`strict+prefix40.log:782-784`（**整体平移 40**：`我方帧(扫描)=41`、`真值帧=42`）。
**机器可读汇总**（`/home/links-dev/w24b-run/frame-step-final.out`，sha16 `ab23bdd2da10e86f`）：

```
L9   腿 strict 计数器 = … 判定行=421 红行=3 绿行=418 NOINFO行=101 红例=3 判定例=288 真值非零行=133 帧红=0 结构红=3
L39  FRAME_STEP 结构族红汇总（**未登记，主控的登记决定；本步不判**）： strict:3 lenient:3 strict+prefix40:3
L40  FRAME_STEP=PASS 三条腿 … 均 帧红=0 ∧ 判定行>0 ∧ 仪器族NOINFO=0 ∧ 自洽=1
```

**为什么恰好 3 条（不是"行数不等的例"全都算）**：探针自报 `我方行数 != 真值行数 的例 = 60`
（`grep -ac '^FRAMEPROBE LINECOUNT' strict.log` = **60**，60 个不同 `id`），
而**结构红的定义**（`Program.cs:33-34`）= `红 ∧ 扫描帧 == 该行 cpFirst ∧ cpFirst != 真值 startChar`
⇒ 只有"真值那一行在我方被**错位**"才算；60 条里**恰好 3 条**命中（**另 57 条行数不等但不红**）。
**根因**（机器证）：三条点名行里 `扫描帧 == cpFirst`（`1 == 1`；prefix40 腿 `41 == 41`）
⇒ **帧原点机制是对的**，错的是**我方分行**（真机把 `"\tb"` 当一整行，我方把中间的 TAB 单独断成一行）。

### 2.2 只读性证明（"删掉它不会让任何判据变绿/变红"）

**判断依据 = 消费者集合为空**（现场 `grep`，12:2x）：

| 去向 | 命令 | 实测 |
|---|---|---|
| `FrameProbe` 本体 | `grep -n 'known-red\|registry\|在册' build/MilBridge/tests/FrameProbe/Program.cs` | **0 命中**（rc=1） |
| `frame-step.sh`（`verify-all` 第 `[6]` 步的零件） | `grep -n 'known-red\|registry\|在册' build/MilBridge/tools/frame-step.sh` | **0 命中**（rc=1） |
| 新登记文件自身的引用 | `grep -rn 'known-red-frame-structural' --include='*.sh' --include='*.py' --include='*.cs' --include='*.json' .` | **0 命中**（今天新建 ⇒ 结构上不可能有读者） |
| 五臂登记表是否覆盖这 3 条 | `grep -c 'lead-tab-b-t-c' build/MilBridge/known-red.json` | **0**（`known-red.json` 只有 4 条 `entries`） |

**同机制姊妹文件的实测先例**（把"只读"从"自称"变成"读数"）：`known-red-PC-copies.md` 的
`show_registry()` 三趟沙箱实测见 §4.2 ——
**登记文件整份不存在**时，`rc`/`计数：`/`APPSYNC=`/`scan() 内部 rc=` **逐字不变**，
剔段后整份输出 `cmp IDENTICAL`（三份同一 sha `c07c481d87324ebc`）。
⇒ 新登记文件与本文件**同构**（同样的"只打印"形态），且**连读者都没有**。

**⚠️ 诚实边界**：本车道**零 `dotnet`** ⇒ 该探针今天的读数**没有重取**。
本登记取自 `#24` 车道 W24B 的留档日志（`$HOME/w24b-run/**`，非仓内、**不是冻树件**）。
**可复现条件已现场复核成立**：探针产物目录里的 `PresentationCore.dll` 副本与树内权威**两者 sha16 均为
`476994e35d31a7e1`**；`Program.cs` `503e6ebd86d70303`、`csproj` `9be882d85aac2ad4`、语料 `88559d670f1bb955`
**与日志自报逐位一致** ⇒ 那趟读数**今天仍可复现**（但**不是本波重取的**）。

## 3 · 件 ②：`known-red-PC-copies.md` 的世代结算

### 3.1 现场核（全部现场算，非抄录）

```
权威 pc = build/PresentationCore.Linux/bin/Debug/PresentationCore.dll
          476994e35d31a7e1  4,197,376 B  mtime 2026-09-17 10:35:02
在册红条目数（照 check-applocal-sync.sh :905-914 的闸逐行解析本文件）= 13   ← 与现场点名数一致
```

**逐份实测**（表 A 12 份 + 表 B 1 份；左二列 = **历史值，一字未改写**）：

| # | 路径 | 登记时副本 sha16 | 本次实测副本 sha16 | 本次判定 | mtime |
|---|---|---|---|---|---|
| 1 | `build/DirectWrite.Linux/FontEntryClosedLoop/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 2 | `build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 3 | `build/DirectWrite.Linux/WicClosedLoop/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 4 | `build/DirectWrite.Linux/WicWriteClosedLoop/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 5 | `build/DirectWrite.Linux/WiringSmoke/bin/Debug/PresentationCore.dll` | `23567d420f0dbbaa` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 6 | `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/PresentationCore.dll` | `c0763fc10173e7ff` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 7 | `build/MilBridge/tests/CoverageProbe/bin/Debug/PresentationCore.dll` | `9adac6b8d8e285c3` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 8 | `build/MilBridge/tests/HbTextLineParity/bin/Debug/PresentationCore.dll` | `f4a454c8fe69cdfe` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:58 |
| 9 | `build/MilBridge/tests/TextLineProto/bin/Debug/PresentationCore.dll` | `f4a454c8fe69cdfe` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 10 | `build/PresentationFramework.Classic.Linux/bin/Debug/PresentationCore.dll` | `95a669cc510337d1` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 11 | `samples/HelloWpf/bin/Debug/net10.0/PresentationCore.dll` | `f31822ce4a3e510d` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:36:00 |
| 12 | `samples/WpfFeatureProbe/bin/Debug/net10.0/PresentationCore.dll` | `9adac6b8d8e285c3` | `476994e35d31a7e1` | **已转绿** | 2026-09-17 10:35:59 |
| 13 | `tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll` | `16baacfccfcf1df0` | `16baacfccfcf1df0` | **仍红**（权威 `c400ab1638e0c3d2`） | 2026-09-11 09:21:37 |

**用检查器自己的读法在本文件上实算**（`bash` 复刻 `:905-929`，同一 `sha()`/`auth_sha_of()` 语义）
⇒ 输出 **12 行 `[在册红·已转绿]` + 1 行 `[在册红]`**，汇总行 **`在册 13 条：仍红 1 ｜ 已转绿 12 ｜ 缺件 0`**。

### 3.2 世代归属结论（写进登记文件 §4）

| 批次 | 是什么 | 归哪个世代 | 换世代的后果 |
|---|---|---|---|
| **PC-1** | 表 A 12 份的 `登记时副本 sha16`（`23567d…`/`c0763f…`/`9adac6…`/`f4a454…`/`95a669…`/`f31822…`） | **`#23` 世代的"未收敛态"** | 只作历史；**不参与今日判定** |
| **PC-2** | 表 A 那列 `登记时权威 sha16` = `e7cabff9417ed380` | `#23`（写登记时的**将来权威**） | 同上 |
| **PC-3** | 表 A 12 份 `本次实测` = `476994e35d31a7e1` | **`#24`** | **`pc` 每重建一次即回落为红**（纪律 52）；`#24` 实测过 `MISMATCH 13 → 18` |
| **PC-4** | 表 B 1 份（`tools/GeometryOracle`） | **与 `pc` 无关** —— 归 `WpfGfx.Linux.dll` 的世代 | `pc` 换世代**不影响**它；**今天仍红** |

**两条要点（写进登记文件）**：

1. **那 12 份是被"刷新"收敛的，不是自己重编收敛的**（现场 mtime 证）：权威 mtime `10:35:02`，
   12 份副本 mtime 全在 **`10:35:58–10:36:00`**（**晚于**权威 56–58 s）；
   机制 = `sync-applocal-authority.sh`（默认干跑、`--apply` 才写）。
   **⚠️ 哪一趟触发的，本车道未取证**（未用 `pgrep -f` 下结论）。
2. **队列形状**：12 份与权威同处一条刷新路径 ⇒ 只要波尾跑一次 `--apply` 就**集体**收敛
   ⇒ **它们的账应记在"刷新机制是否在波尾跑过"上**，不是记在 12 条路径上。

### 3.3 世代绑定的两极性实证（**本地沙箱，仓库零改动**）

脚本 `$HOME/w25c-run/run-genbind-test.sh`（sha16 `b4afa20e24aad84d`），输出 `$HOME/w25c-run/genbind.out`
（`d51fe240d11e9267`）。**被测 `check-applocal-sync.sh` = `7bc9364091a28fd4`**。
唯一变量 = **权威件的内容**（同一份登记 + 同一份副本 + 同一命令形态）：

| 趟 | 沙箱权威 sha16（现场算） | 登记段措辞 | 汇总 | `rc` |
|---|---|---|---|---|
| ① | `476994e35d31a7e1`（== 副本） | **`[在册红·已转绿]`** | 在册 1 条：仍红 0 ｜ 已转绿 **1** ｜ 缺件 0 | 1 |
| ② | `f21b1f8f6edd9da6`（**换一个 sha**） | **`[在册红]`**（仍红） | 在册 1 条：仍红 **1** ｜ 已转绿 0 ｜ 缺件 0 | 1 |
| ③ | `476994e35d31a7e1`（**换回**） | **`[在册红·已转绿]`** | 在册 1 条：仍红 0 ｜ 已转绿 **1** ｜ 缺件 0 | 1 |

⇒ **`GENBIND=PASS`**（两个方向都成立）；**`rc` 三趟相同（1/1/1）** ⇒ 本段**不参与判定**。
（沙箱布局踩坑记录：检查器里 `REPO="${AUTH_ROOT:-…}"` **同时**是"权威根"与"登记表路径的根"
⇒ 沙箱必须把**权威件 + 副本 + 登记表**放同一个根下。第一版没这么做 ⇒ 全部报"缺件"，已废弃重做。）

### 3.4 只读性证明（三趟沙箱实测）

脚本 `$HOME/w25c-run/run-readonly-test.sh`（`53b3d1b65e4b85f1`），输出 `$HOME/w25c-run/readonly-test.out`
（`9a1819b9b792fc7a`）。唯一变量 = **登记文件**（有登记 / 空登记 / **整份不存在**）：

```
rc：A(有登记)=1  B(**无登记文件**)=1  C(空登记)=1
[A]/[B]/[C] 计数：… MISMATCH=0（STALE=0 NEWER-DIFF=0）… AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0   ← 三趟逐字相同
[A]/[B]/[C] APPSYNC=MISMATCH（…）        ← 逐字相同
[A]/[B]/[C] scan() 内部 rc=1（…）        ← 逐字相同
剔除登记段 + 路径归一化后：cmp A B = IDENTICAL；cmp A C = IDENTICAL；行数 104/104/104
sha16 = c07c481d87324ebc（三份同一个）
```

⇒ 删掉登记文件 ⇒ **只有登记段消失**，`rc`/计数器/`APPSYNC`/`scan()` 全不动。

### 3.5 ⭐ **世代切换现场实录**（本车道开工期间真实发生；已写成登记文件 §7）

**这不是推演 —— 是现场逮到的**：

| 时刻（+0800） | 权威 `pc` sha16 | 字节 | 12 份 `pc` 副本的登记段判定 | 来源 |
|---|---|---|---|---|
| **12:25–12:29** | `476994e35d31a7e1` | 4,197,376 | **已转绿 12 ／ 仍红 1** | 本报告 §3 快照 |
| **12:30:42**（**W25A 重建 `pc`**） | `7374308a00c55572` | 4,197,888 | —— | `stat` + `sha256sum` 现场算 |
| **12:32:07** | `7374308a00c55572` | 4,197,888 | **已转绿 0 ／ 仍红 13** | 现场重放 `show_registry()` 读法 |

⇒ **那 12 份的"已转绿"在同一分钟内全部回落为"仍红"** —— **这正是纪律 52 的现场正控**：
`[在册红·已转绿]` **只在某个权威 `pc` sha 下成立**，**不是永久销账**。
⇒ 同时得到**新一代的落后集合规模**：现场枚举 34 份 `PresentationCore.dll` 中
**31 份**仍为 `476994e35d31a7e1`（未刷新）、**3 份** = 新权威 ⇒
**波尾 `sync-applocal-authority.sh --apply` 要刷的份数 ≈ 31，而不是 12**。
⇒ 表 B（`tools/GeometryOracle` `16baacfccfcf1df0`）**跨世代纹丝不动、仍红** ⇒ 再次证明它与 `pc` 世代无关。

**⚠️ 这三行读数只属于各自那一刻**：`pc` 在 `#25` 波内**还会被再次重建** ⇒ 引用前**必须现场重算**。

## 4 · 差异与如实上报

1. **副本总数口径差 1（非缺陷）**：登记表写"全仓 `PresentationCore.dll` 共 **33** 份 = 12 + 6 + 12 + 2 + 1"，
   12:25 现场枚举 **34** 份 = **权威自身 1 + 非权威 33** ⇒ **两套口径一个含权威、一个不含**。
   非权威 33 份的现场分组（**现场枚举，不跑检查器**）：**12** 份 mtime `10:35:58–10:36:00`（= 表 A 那 12）、
   **15** 份 mtime ∈ `{10:35:02, 09:54:50}`、**6** 份 mtime `10:36:00–10:36:01`；
   ⚠️ **各自 `OK`/`NO-AUTHORITY`/`SKIP(obj)`/`SKIP(stub)`/`LIB-COPY` 的精确分类未复算 ⇒ `NOINFO`**。
2. **本报告 §3 的快照是"12:25 那一代"的**：12:30 `pc` 已被 W25A 重建（见 §3.5）⇒
   那一节**只在 `pc == 476994e35d31a7e1` 下成立**；**切换后的现场已另记为登记文件 §7**。
   ⇒ 我**没有**改写 §3（历史值），也**没有**把两代混读。
3. **本波没有亲自跑 `check-applocal-sync.sh`**：它是 W25B 的写域，且我在 12:27 观察到它**正在被改**
   （mtime `12:27:48`）⇒ 那一刻的真仓读数**不可归因**。
   我改用的是**沙箱副本**（两条测试都在沙箱里跑同一份脚本副本）；
   §3 / §3.5 的逐份判定是**用它的 `show_registry()` 逐行读法在真仓上重放**得出的，**不是门禁读数**。
4. **`#24` 车道 W24B 的留档日志不在仓内**（`$HOME/w24b-run/**`）⇒ 本登记的两条来源是**非冻树件**；
   已在登记文件里逐条注明"取自哪份日志的哪一行"、并附**现场 sha16/字节/mtime**，并注明**本波未重取**。

## 5 · 未测 / `NOINFO` 清单

- 那 3 条结构族帧红的**今天重取读数**（**零 `dotnet`** ⇒ 未重跑探针；只复核了可复现条件）。
- 33 份非权威 `PresentationCore.dll` 的**逐份类别**（`OK`/`NO-AUTHORITY`/`SKIP(*)/LIB-COPY`）——未跑检查器。
- `pc` 以外其它 `ITEMS`（`libwpfwic.so`/`libwpfwin32.so`/`Provider`/`WpfGfx.Linux.dll`/`ReachFramework.dll`）
  的副本**本轮未逐份复算**。
- `sync-applocal-authority.sh --apply` **由哪一趟触发**；`tools/**` 是否在其覆盖范围内。
- `--leg a` 在 `#25` 之后的读数（`#24` 测过与腿 B 一致，但**本次未取证**）。
- 新登记文件**未来**若被接线进判定，其行为（**今天不存在读者** ⇒ 无从测）。
- `pc` **12:30 之后再被重建**的次数与后果（本车道收工时值是 `7374308a00c55572`，**不保证是终值**）。

## 6 · 可复算命令（给复核者）

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux

# ① 权威 pc（现场算）
sha256sum build/PresentationCore.Linux/bin/Debug/PresentationCore.dll | cut -c1-16

# ② 登记条目数（照检查器 :905-914 的闸；必须 = 13）
python3 -c "
import re
pat=re.compile(r'^[0-9a-f]{16}\$'); n=0
for line in open('build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md',encoding='utf-8'):
    if not line.startswith('|'): continue
    c=[x.strip() for x in line.strip().strip('|').split('|')]
    if len(c)<3 or '---' in c[1]: continue
    if pat.match(c[1]): n+=1
print('entries =',n)"

# ③ 只读性（三趟沙箱；唯一变量 = 登记文件）
bash \$HOME/w25c-run/run-readonly-test.sh        # 期望：rc 三趟相同 + cmp IDENTICAL

# ④ 世代绑定（两极性；只换权威 sha）
bash \$HOME/w25c-run/run-genbind-test.sh         # 期望：GENBIND=PASS

# ⑤ 结构族帧红的消费者 = 空
grep -n 'known-red\|registry\|在册' build/MilBridge/tests/FrameProbe/Program.cs   # 期望 0 命中
grep -n 'known-red\|registry\|在册' build/MilBridge/tools/frame-step.sh          # 期望 0 命中
grep -rn 'known-red-frame-structural' --include='*.sh' --include='*.py' --include='*.cs' --include='*.json' .  # 期望 0 命中
```

---

**报告 sha16**：**不内嵌**（内嵌即自指 ⇒ 写入后立刻失效，纪律 49 的同类坑）。
取值方式 = 现场算：

```bash
sha256sum build/MilBridge/W25C-report.md | cut -c1-16
```

**收工时的实测值**（本行写入前的最后一次现场算）：以现场 `sha256sum` 为准（见下面"收工读数"）。
**本文件不再改动** ⇒ 复核者现场算出的值即为报告 sha16。

## 7 · 收工读数（现场）

```
交付三件（sha16 / 字节）
  db3b449112daedd1     14371 B  build/MilBridge/known-red-frame-structural.md
  8497a0ca1689cf90     26822 B  build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md
  （本报告：见 `sha256sum build/MilBridge/W25C-report.md | cut -c1-16`）

未动（收工复核，与开工同值）
  e623d2b17d948e3b  build/MilBridge/known-red.json
  503e6ebd86d70303  build/MilBridge/tests/FrameProbe/Program.cs
  37f27df68e52bf8c  build/MilBridge/tools/frame-step.sh
  7becc5266636c405  build/DirectWrite.Linux/wic-shim/applocal-expect.py
  （`check-applocal-sync.sh` 归 W25B：收工时 `7bc9364091a28fd4`，本车道未写过它）

权威 pc（收工时刻 12:32 +0800）  7374308a00c55572  4,197,888 B  mtime 2026-09-17 12:30:42
环境  MemAvailable 3,022 MB ｜ swap free 约 0.5 GB ｜ loadavg 4.38/4.51/2.46 ｜ nproc=3
```


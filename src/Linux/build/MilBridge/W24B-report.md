# 车道 W24B 报告 —— 波 `#24` **P2：帧列接线**（让残余红**有处可登记**）

> `lane=W24B`｜`2026-09-17 09:30:33 → 10:32:08 +0800`（读数的收工时刻 = 无并发确认跑结束）｜kernel `6.8.0-138-generic`｜`nproc=3`｜全程**未** `pkill -f`（只按 PID 观察）
> `MemAvailable` **开工 3,489,236 kB**（09:30:33，我自测）／**最低 2,180,852 kB**（09:30:55–10:05:26 窗口，由**另一条车道**的 30 s 采样器 `PID 414986` 记在 `$HOME/w24-mem.log`，70 个样本；**我自己的仪器自报最低 2,628,704 kB**）／**收工 3,380,068 kB**（10:32:38，我自测）
> `SwapFree` **977,148 → 827,900 kB** ⇒ **本波期间确实发生了换出（−149,248 kB）**，⚠️ 因此**不能**写"全程未动用"；它**不是**我这条车道的重构建造成的（我同一时刻只有一段构建，本步峰值 RSS **706,576 kB**），**究竟是谁换出的未归因 ⇒ `NOINFO`**
> `loadavg` 开工 **0.14 0.08 0.04** → 峰值 **4.36**（并发车道所致）→ 收工 **0.67 1.22 2.03**
> 收工按 PID 复查：**没有留下我自己的 `dotnet`/MSBuild/`VBCSCompiler`/`frame-step` 进程**（唯一命中是我自己那条 `grep`）
> 仓库根 = `$R` = `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（下文所有路径均绝对）
> 读的预登记：`docs/WAVE24-PREREGISTRATION.md`（§2 = 本件；§5 位移表、§6 停条件、§7 内存纪律对本件有约束力）

---

## §0 判决（一行）

**`FrameProbe` 现在把 `红行` 按族分解（新列 `帧红=` / `结构红=` + 新自证行 `FRAMEPROBE 红族分解 …`），新建的 `build/MilBridge/tools/frame-step.sh` 单独跑 `rc=0`（三条腿 `帧红=0`、`判定行=421`、`仪器族NOINFO=0`、`自洽=1`）；**反极性拿到真红**——同一支探针、同一语料，**修前 pc `e7cabff9417ed380` ⇒ `帧红=421`（`--prefix 40`）/ `133`（宽松档）**；残余 3 条**结构族**红**未登记、未压绿、判据一字未放松**。**

**本件最重要的实测发现（§8.1）**：`#23` 表里那三格**判别力并不等价** —— **只接 `--leg b --tier strict`（不带 `--prefix`）这一条腿，本判据对 `D-T6-b` 是零判别力的**（修前 `帧红=0 / 结构红=3`，修后**逐位相同**）。真正能分辨修前/修后的是 **`--prefix 40` 格（421 → 0）** 与 **宽松档格（133 → 0）**。这就是我把 `--prefix 40` 也接成**决定 rc 的腿**的实测理由。

---

## §1 交付物、身份与留档（纪律 15/40/49：哈希一律脚本现场算）

| 文件 | before | after | 说明 |
|---|---|---|---|
| `build/MilBridge/tests/FrameProbe/Program.cs` | `c6a66724ad56760a`（37,216 B，2026-09-16 20:13:07） | **`503e6ebd86d70303`**（43,380 B，2026-09-17 09:39:09，655 行） | 仪器改动（本件唯一改的既有文件） |
| `build/MilBridge/tests/FrameProbe/bin/Release/PresentationCore.Tests.dll` | `6b65924a52a59d89`（26,624 B） | **`db3b321944f31a15`**（27,648 B） | ⚠️ **该 dll 的 sha 随被测 pc 变**（csproj 用 `HintPath` 引 pc）：新仪器 + pc `7b47a7b3d69ad62f` ⇒ `a137e8f4a514b36d`；新仪器 + pc `476994e35d31a7e1` ⇒ `db3b321944f31a15` ⇒ **报 dll sha 必须连 pc sha 一起报** |
| `build/MilBridge/tools/frame-step.sh` | （新建） | **`37f27df68e52bf8c`**（12,429 B，195 行，`-rwx--x--x`） | 交付本体（§10 附录 A 全文） |
| `build/MilBridge/W24B-report.md` | （新建） | 本文件 | |

**留档（`cp -p`，本件实测过 before/after）**：`$HOME/w24b-backup/Program.cs.before` = `c6a66724ad56760a`｜`$HOME/w24b-backup/PresentationCore.Tests.dll.before` = `6b65924a52a59d89`｜`$HOME/w24b-backup/frame-step.sh.orig` = `b168c353385df785`（**修 §8.3 那个 bug 之前的首版**）｜读数与日志 `$HOME/w24b-run/`。

**我没有碰**：`build/MilBridge/known-red.json`（仍 `e623d2b17d948e3b`）、`build/MilBridge/tools/tline-gate.sh`、`verify-all.sh`、`build/MilBridge/arm-logs/**`、`CoverageProbe/**`、`PcLineOracle/**`、`build/shims/**`、`build/PresentationCore.Linux/**`。⇒ `hbtextline` 全程 `e89fed55fd8e32bc` **未变**（§7 复算）。

---

## §2 仪器改动（`FrameProbe/Program.cs`）—— 逐处 + **只加强**的机器证

### §2.1 逐处（新文件行号）
| # | 行 | 改动 |
|---|---|---|
| H1 | `:27-43`（头注释） | rc 词表加一条（**红族分解不自洽 ⇒ rc=2**）；新增「`红行` 的族分解」口径段（帧红/结构红定义、`NOINFO` 两族、下游必须断言 `帧红` 而非 `红行`） |
| H2 | `:350-369` | 新增 `noInfoNoFrame` / `noInfoNoTruth`（`:358`）、`frameRedLines` / `structRedLines`（`:366`）、`frameRedComparable`（`:369`） |
| H3 | `:461-473` | 判定分支里**只加计数**：`:464` `if (frame < 0) { ++noInfoLines; ++noInfoNoFrame; red = true; }`；`:468-472` `if (red) { if (frame != index) { ++frameRedLines; if (index == truth) ++frameRedComparable; } else ++structRedLines; }` |
| H4 | `:494` | `else { ++noInfoLines; ++noInfoNoTruth; }` |
| H5 | `:561-567` | **汇总行末尾追加**两列：`+ " 帧红=" + frameRedLines + " 结构红=" + structRedLines`（既有 8 列一字未动） |
| H6 | `:580-588` | **新增一行**自证：`FRAMEPROBE 红族分解 帧红=… 结构红=… 红行=… 自洽=… 帧红可比分母=… 帧红可比子集=… 仪器族NOINFO=… 结构族NOINFO=… NOINFO行=…（口径）` |
| H7 | `:606-614` | **新增自洽闸**：`(帧红+结构红) != 红行` 或 `帧红可比子集 > 帧红` ⇒ `FRAMEPROBE_EXIT=NOINFO rc=2`（**坏仪器绝不许报绿**） |

`NOINFO行` **也**按族分解的理由（这是本件第二重要的一条，见 §8.4）：`#24` 实测 `NOINFO行=101` **恒非零**，若按字面把「`NOINFO≠0`」当红，本步**永远红**、退化成"没人看的红"（事故 `L26` 的同族）；若当绿则是明令禁止的作弊。⇒ 必须先能分辨它是**仪器缺口**（有真值却扫不出帧）还是**语料性质**（真值数组短于我方的那些行**没有真值可比**，同族的 `我方行数 != 真值行数 的例=60`）。

### §2.2 「只加强」的机器证（同一 pc、同一语料、同一腿，修前 vs 修后仪器）
方法：把**新增的东西**（`红族分解` 行、汇总行末尾两列、运行相关行）剔掉后**逐字节 `cmp`**：
- **汇总行**：剔除追加列后 **`IDENTICAL`**；`post` 的实际文本 = `FRAMEPROBE 汇总 tier=strict leg=B freshSource=0 判定行=421 红行=3 绿行=418 NOINFO行=101 红例=3 判定例=288 真值非零行=133 帧红=0 结构红=3`（前 8 列与 `#23` 读数逐字相同）
- **全日志**：剔除 `FRAMEPROBE 时间=`/`FRAMEPROBE 被测件 `/`FRAMEPROBE 红族分解 ` 三类行后，**88 行 `IDENTICAL`**（`cmp` rc=0，strict 与 lenient 各验一次）
⇒ 既有列的取值/语义/顺序**零射程**；`#23` 的读数表与 `红行=` 逐字对照仍然成立。

---

## §3 `frame-step.sh` 设计（三态 / 哪条腿决定 rc / 它**不**判什么）

### §3.1 判据面 = **`帧红` 一列**，**不是** `红行`
- **帧红** = 红 ∧ `扫描帧 != 我方 cpFirst` ⇒ **帧原点机制本身错**（`D-T6-b` 那一族）
- **结构红** = 红 ∧ `扫描帧 == 我方 cpFirst` ∧ `我方 cpFirst != 真值 startChar` ⇒ 「**我方分行 ≠ 真机分行**」（`#22`/`#23` 已定性），**不是帧错**
- ⛔ 预登记 §2.2 明令：**不许**把 `红行 == 0` 当判据（会把结构族吞进来，与 `#23` 的教训相反，且会让本步永远红）

### §3.2 三条腿，**全部决定 rc**
| # | 腿 | 决定 rc | 理由 |
|---|---|---|---|
| ① | `--leg b --tier strict` | ✅ | PC **先试**的那一层（`HbTextFallback`） |
| ② | `--leg b --tier lenient` | ✅ | 它返回 null 之后的兜底层（`WpfLinuxLenientTextFallback`）——**另一条代码路径**；`D-T3` 的一半当初就是这么漏掉的 |
| ③ | `--leg b --tier strict --prefix 40` | ✅ | **唯一**"段落原点 ≠ 0"的腿；`D-T6-b` 这一族缺陷**恰恰是帧原点与段落原点的关系**。⚠️ 它的**真值侧被整体平移**（`真值非零行 133 → 421`，`#23` 已实测）⇒ **它的读数不能与 ①② 直接比列**，但**断言形式完全相同** |

判据（**三条腿各自**）：`帧红 == 0` ∧ `判定行 > 0` ∧ `仪器族NOINFO == 0` ∧ `自洽 == 1`；外加全程断言 **产物副本 == 权威件**、**本步期间 `pc` 未变**。

### §3.3 三态
| rc | 含义 |
|---|---|
| **0** | 三条腿全部通过（`FRAME_STEP=PASS`） |
| **1** | 判据红（`帧红≠0` / `仪器族NOINFO≠0` / **恒绿退化** `判定行=0`）（`FRAME_STEP=FAIL`，逐腿点名） |
| **2** | `NOINFO`：探针 rc=2｜汇总行/族分解行缺失｜字段解析不出｜族分解不自洽｜构建失败｜**pc 副本≠权威**｜**本步期间 pc 变了**（纪律 35/48） |

### §3.4 它**不**判什么（规则 41：在射程内 ≠ 真的看了）
1. **结构族红**（今天 3 条）：本步**只逐条点名**（`FRAMEPROBE RED …` 原样打印 + `结构族红汇总`），**不判**、**不登记**、**不压绿**。"把 3 条压成登记"是**主控的登记决定**；探针自己的 `probe_rc=1` 也**逐腿原样打印**，不会被本步吞掉。
2. **真值一致性**：`帧红` 是"我方帧 == 我方自己的行起点"的**自洽**量，**不看真值**（§5 N-4 实测：把语料真值改坏 ⇒ `结构红` 由 3 涨到 12，而本步**仍 rc=0**）⇒ 那部分由**结构族**那笔账负责。
3. **`--leg a`**（`AlwaysCollapsible=false`；`#22` 记录它走 `SimpleTextLine` 快路径）：本波**测过**（§4.3）`帧红=0 / 结构红=3`，与腿 B **完全一致** ⇒ **加它只增成本不增判别力**，故未接。
4. **`--fresh-source` 腿**：未接、未测（`#23` 记录修前 133 → 修后 3）。

### §3.5 代价与资源（实测，两条独立读数）
| 趟 | 谁跑的 | WALL | MAXRSS |
|---|---|---|---|
| 首跑 rc=0 | 我（与一个外部并发进程**时间窗重叠**，见 §7.4） | 7 分 06 秒（10:17:01 → 10:24:07） | 未测 |
| **无并发确认跑 rc=0** | 我 | **6 分 34 秒（394.07 s）** | **706,576 KB ≈ 690 MB** |
| 外部并发那趟 | **不是我**（`PID 522415/522416/522720`，见 §7.4） | 427.96 s | 708,300 KB |

⇒ `verify-all` 由 11 步变 12 步并**增加约 6.5~7 分钟**；**峰值 RSS ≈ 690 MB**（对预登记 §7 的 1200 MB 余量自检是安全的）——**这两项代价是主控接第 12 步时要一起接受的**。

---

## §4 单独跑的读数（**拿 rc=0**）

### §4.1 命令与原样判据行
```
bash build/MilBridge/tools/frame-step.sh            # FRAME_STEP_LOGDIR 可覆盖日志目录（缺省 /tmp/frame-step）
```
```
FRAME_STEP 仪器·Program.cs = 503e6ebd86d70303（波 #24 P2 后：含 帧红/结构红 + NOINFO 族分解）
FRAME_STEP 仪器·FrameProbe.csproj = 9be882d85aac2ad4
FRAME_STEP 语料           = 88559d670f1bb955  路径=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/parity/windows/tab-anchor/out/tab-anchor-raw.json
FRAME_STEP 被测 pc（树）  = 476994e35d31a7e1  路径=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll
FRAME_STEP 被测 pc        = 476994e35d31a7e1（copy == auth ✓）
FRAME_STEP 腿 strict 机读 判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 probe_rc=1
FRAME_STEP 腿 lenient 机读 判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 probe_rc=1
FRAME_STEP 腿 strict+prefix40 机读 判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 probe_rc=1
FRAME_STEP 被测 pc 全程未变 = 476994e35d31a7e1
FRAME_STEP 结构族红汇总（**未登记，主控的登记决定；本步不判**）： strict:3 lenient:3 strict+prefix40:3
FRAME_STEP=PASS 三条腿（strict / lenient / strict+prefix40）均 帧红=0 ∧ 判定行>0 ∧ 仪器族NOINFO=0 ∧ 自洽=1
```
**`rc=0`**；输出 sha16 **`ab23bdd2da10e86f`**（40 行，`$HOME/w24b-run/frame-step-final.out`）。
⚠️ 这一趟与**另一个外部进程**（`PID 522415/522416/522720`，非我启动）**时间窗重叠且同用一份工程输出目录** ⇒ **引用 `rc=0` 时请引用 §11 的无并发确认跑**（纪律 48）。

### §4.2 三条腿的读数表（`pc=476994e35d31a7e1` 全程未变；仪器 `503e6ebd86d70303`/`db3b321944f31a15`）
| 腿 | 判定行 | 红行 | **帧红** | 结构红 | 仪器族NOINFO | 结构族NOINFO | 自洽 | 真值非零行 | probe_rc |
|---|---|---|---|---|---|---|---|---|---|
| `strict` | 421 | 3 | **0** | 3 | 0 | 101 | 1 | 133 | 1 |
| `lenient` | 421 | 3 | **0** | 3 | 0 | 101 | 1 | 133 | 1 |
| `strict --prefix 40` | 421 | 3 | **0** | 3 | 0 | 101 | 1 | **421** | 1 |

⇒ 分母/口径：**`script==latin` 的 288 例 / 421 行**（纪律 39）；`帧红可比分母=418`（=421−3，正是 `#23` 说的「0/**418**」那个 418），`帧红可比子集=0`。
⇒ 3 条结构族红逐条点名（三条腿同一批，都是 `@tab0`）：
```
FRAMEPROBE RED B-indent/lead-tab-b-t-c@w40@LTR@i24@tab0 行#1 我方帧(扫描)=1 我方帧(_lineStart)=1(反射 1) 真值帧(startChar)=2 我方cpFirst=1 Length=1 行类型=HbTextLine
FRAMEPROBE RED B-indent-extra/lead-tab-b-t-c@w40@LTR@i0p24@tab0 行#1 我方帧(扫描)=1 我方帧(_lineStart)=1(反射 1) 真值帧(startChar)=2 我方cpFirst=1 Length=1 行类型=HbTextLine
FRAMEPROBE RED B-indent-extra/lead-tab-b-t-c@w40@LTR@i24nl@tab0 行#1 我方帧(扫描)=1 我方帧(_lineStart)=1(反射 1) 真值帧(startChar)=2 我方cpFirst=1 Length=1 行类型=HbTextLine
```
`我方帧(扫描) == 我方cpFirst`（1 == 1）⇒ **结构族**判定成立；`--prefix 40` 腿同批为 `我方帧(扫描)=41 / 我方cpFirst=41 / 真值帧=42`（**平移一致**）。
`strict+prefix40` 腿另有一条本件顺手取到的形状证据：**`我方帧(_lineStart)=1` 而 `我方cpFirst=41`** ⇒ `_lineStart`（`#23` 的 Option 1 之后是**行相对**量）与"帧"（**段落系绝对**量）**不是同一个量**，本判据读的是**帧**（= `GetTextBounds` 扫描，与真机宿主读法同源）。

### §4.3 额外读数（不进 step）
| 腿 | 判定行 | 红行 | 帧红 | 结构红 | 层级来源 |
|---|---|---|---|---|---|
| `--leg a --tier lenient` | 421 | 3 | **0** | 3 | 宽松档接手 250 / 两档都没接手 38 |
| `--leg a --tier strict` | 421 | 3 | **0** | 3 | 严格档接手 250 / 两档都没接手 38 |
（腿 A 的 `扫描帧 vs _lineStart(IVT) 不一致行` = **272**（宽松）/ **73**（严格），而腿 B 该值 = **0** ⇒ 说明"扫描帧"与 `_lineStart` 在腿 A 上**大面积不同**；本判据选的读者是**扫描帧**，理由见 `Program.cs` 头注释 `:8-18`：真机宿主就是 `line.GetTextBounds(gi,1)`。）

### §4.4 仪器修前/修后的零射程（同一 pc `7b47a7b3d69ad62f`、同一语料、同一腿）
| 腿 | 修前仪器（`6b65924a52a59d89`） | 修后仪器（`a137e8f4a514b36d`） |
|---|---|---|
| `strict` | 判定行=421 红行=3 绿行=418 NOINFO行=101 红例=3 判定例=288 真值非零行=133 | 同一串 + ` 帧红=0 结构红=3` |
| `lenient` | 同上 | 同上 |
⇒ 既有 8 列**逐字节相同**（§2.2 的 `cmp` 证明）。

---

## §5 反极性（**全部实测**）

### §5.1 N-1（**最强**：同一支探针、同一语料、真实件）—— 修前 pc ⇒ **真红**
方法：**私有目录**（不动树）：`cp -a build/MilBridge/tests/FrameProbe/bin/Release $HOME/w24b-run/prefixpc/`，再把**修前 pc**（`/home/links-dev/wfp-runs/w21-gate1/PresentationCore.dll`，sha16 **`e7cabff9417ed380`**，4,196,864 B = `#21` 冻结值）盖进去。探针自带 `本机副本 sha16 前/后` 自证（三趟都是 `e7cabff9417ed380`）。
仪器 = **同一支** `db3b321944f31a15`；口径环境：`WPF_LINUX_WIN32_SHIM=$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**仪器输入，纪律 40**；私目录里没有 native shim，不指就会 `DllNotFoundException` ——首趟实测 rc=134，见 §9）。

| 腿（pc = `e7cabff9417ed380`） | 判定行 | 红行 | **帧红** | 结构红 | 自洽 | 真值非零行 | `#23`/W23B 记录的修前值 |
|---|---|---|---|---|---|---|---|
| `strict` | 421 | 3 | **0** | 3 | 1 | 133 | 红 3 行（帧红 0、那 3 条是结构红）✅ |
| `lenient` | 421 | **133** | **133** | 0 | 1 | 133 | 红 133 行（帧恒 0）✅ |
| `strict --prefix 40` | 421 | **421** | **421** | 0 | 1 | 421 | 红 421 / 帧红 421 ✅ |

**⇒ 同一支探针、同一语料：修前 pc 给 `帧红=421`（prefix40）/ `133`（宽松档），现树 pc 给 `帧红=0` ⇒ 这个判据能变红，今天的 `帧红=0` 是真绿、不是恒真。**
`strict --prefix 40` 腿上 `真机读法 GetTextBounds(cpFirst,1) 读到空的行=522`（现树 pc 该值为 0）—— 与 W23B「修前 104 → 0（宽松）/ 522 → 0（prefix40）」的记录吻合。

### §5.2 N-2（脚本级：**恒绿退化**闸）—— 退化语料 ⇒ `rc=1`
临时变体（**仅 1 行差异**：`CORPUS` 指向 `$HOME/w24b-run/corpus-nolatin.json`，sha16 `803a063da0957bd3`，436/436 例 `script` 改成非 `latin`）：
```
FRAME_STEP=FAIL 腿 strict 判定行=0 ⇒ **恒绿退化**：一行都没判过，'帧红=0' 毫无意义
FRAME_STEP=FAIL 腿 lenient 判定行=0 ⇒ **恒绿退化**：…
FRAME_STEP=FAIL 腿 strict+prefix40 判定行=0 ⇒ **恒绿退化**：…
FRAME_STEP=FAIL 见上面逐腿点名（帧红≠0 或 仪器族NOINFO≠0 或 恒绿退化）
```
`rc=1`（`$HOME/w24b-run/neg-degen2.out`）。⇒ 「一行都没判过时 `帧红=0`」**不会被读成绿**。

### §5.3 N-3（脚本级：预登记 §6.3 许可的**判据翻转**）—— ⇒ `rc=1`
临时变体（**2 处差异**：`LEGS` 只留 `strict`；断言对象由 `帧红` 换成 `结构红`）：
```
FRAME_STEP 腿 strict 机读 判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 probe_rc=1
FRAME_STEP=FAIL 腿 strict **（N-3 临时：判结构红）**=3 / 判定行=421 ⇒ 结构族红（我方分行 != 真机分行）
FRAME_STEP=FAIL 见上面逐腿点名（帧红≠0 或 仪器族NOINFO≠0 或 恒绿退化）
```
`rc=1`（`$HOME/w24b-run/neg-n3.out`）。⇒ ① 本步的**红路径是活的**（不是只会打 PASS）；② `结构红=3` **是真的**、没被本步吞掉（若本步把结构族"吞绿"了，翻转后不会红）。

### §5.4 N-4（**边界**，如实标出本步**看不见**什么）—— 真值侧改坏 ⇒ 本步**仍 rc=0**
把前 5 个 `latin` 例的 `lines[k].startChar` 各 +1（`$HOME/w24b-run/corpus-truthmut.json`，sha16 `729deeddc64fe408`），直接跑探针（`--leg b --tier strict`）：
```
FRAMEPROBE 汇总 … 判定行=421 红行=12 绿行=409 NOINFO行=101 红例=8 判定例=288 真值非零行=138 帧红=0 结构红=12
FRAMEPROBE 红族分解 帧红=0 结构红=12 红行=12 自洽=1 帧红可比分母=409 帧红可比子集=0 仪器族NOINFO=0 …
```
⇒ 探针**确实读真值**（`红行` 3→12、`结构红` 3→12），而这一切**全落在结构族** ⇒ 本步（断言 `帧红`）**会绿**。**这是设计，不是漏洞**（预登记 §2.2 明令不许用 `红行` 当判据）；本节即为"它不判什么"的**实测**版本（规则 41）。

### §5.5 临时变体已清除（不留在树里）
N-2 / N-3 的变体曾作为**同目录兄弟脚本**存在（好让 `ROOT` 解析与交付体一致）：`build/MilBridge/tools/frame-step-degen.sh`、`build/MilBridge/tools/frame-step-n3.sh`。跑完**已 `rm -f`**；现在 `ls build/MilBridge/tools/ | grep frame-step` = **只有 `frame-step.sh` 一个**，且其 sha16 仍 = **`37f27df68e52bf8c`**（与交付值相同）。⚠️ 变体**从未**改名/替换交付体 ⇒ 交付体在整个反极性过程中**逐字节未变**。

---

## §6 插进 `verify-all.sh` 的**补丁草案**（逐字；**由主控来落**，我不改）

**位置**：`verify-all.sh:218`（`run_step "PcLineOracle·Start 列" bash build/MilBridge/tools/pc-line-step.sh`）**之后**、`:220` 的 `# ---…` 汇总块**之前**，整段插入：

```bash
# ---------------------------------------------------------
# [6] 帧列 —— `FrameProbe` 的冻树牙齿（`#24` P2 新增；步数 **11 → 12，口径已变**）
# ---------------------------------------------------------
# 【为什么加这一步（事故 `L26` 的同族第三次发作）】
#   `#23` 实测：`FrameProbe`（`#22` 建的 `D-T6-b` 帧判据探针）在
#     `verify-all.sh` / `tline-gate.sh` / `pc-line-step.sh` / `run.sh` / `arm-logs/README.md`
#   **五处 grep 全 0**（`#24` 已独立复算，见 W24B-report §7.3）⇒ 它**不在任何冻树回路里**，
#   它报的残余红（strict/lenient 各 `红行=3`）**无处可登记**；而"帧"这一列在冻树上
#   **没有任何别的牙齿**：第 [5] 步只判 `TextLine.Start` 一列。
# 【判据 = `帧红`，**不是** `红行`】`#23` 已定性：那 3 条全是"行数不等"**结构族**（不是帧错）——
#   `frame == 我方 cpFirst` 全部成立，只是"我方分行 ≠ 真机分行"。`#24` P2 让 `FrameProbe`
#   把 `红行` 按族分解（汇总行末尾新增 `帧红=` / `结构红=`，另加自证行 `FRAMEPROBE 红族分解`）⇒
#   本步断言 `帧红==0 ∧ 判定行>0 ∧ 仪器族NOINFO==0 ∧ 自洽==1`，**三条腿**
#   （`strict` / `lenient` / `strict --prefix 40`）。口径、代价、"哪条腿决定 rc"、"它不判什么"
#   逐条写在 `build/MilBridge/tools/frame-step.sh` 的文件头，务必与读数一起读。
# 【两极化已实测，不是声明】同一支探针、同一语料：修前 pc `e7cabff9417ed380`（私目录）
#   ⇒ `帧红=421`（`--prefix 40`）/ `帧红=133`（宽松档）；现树 pc ⇒ `帧红=0`。
#   逐条（含退化语料、判据翻转两个脚本级反极性）见 `build/MilBridge/W24B-report.md` §5。
# 【代价】三条腿 ≈ 6.5~7 分钟（无并发实测 WALL=394.07 s，MAXRSS≈690 MB）。
echo
echo "[6] 帧列（FrameProbe：段落系帧 vs 真机 startChar；产品 pc，经 TextFormatter/HbTextFrame）"
run_step "FrameProbe-frame" bash build/MilBridge/tools/frame-step.sh
```

**步名故意用 ASCII `FrameProbe-frame`**：`run_step` 失败时会把日志另存到
`/tmp/verify-all-$(echo "$name" | tr -c 'A-Za-z0-9' '_').log`（`verify-all.sh:88`）——用 CJK 步名（例如 `FrameProbe·帧列`）会按**字节**变成一串下划线、路径不可读；ASCII 名给到 **`/tmp/verify-all-FrameProbe_frame.log`**。

**同步要改的口径（否则文档与门禁不一致）**：
1. `verify-all.sh:2-3` 的文件头注释（那里还写着"4 个测试套件"，**已经是陈旧的**：现在 `[1]+[2]+[3]+[4]+[5]` = 11 步）⇒ 建议改成"Xvfb → 构建 → 6 个测试工程 → 命令线格校验 → 五臂门禁 → `TextLine.Start` 列 → **帧列**"。
2. 基线表头 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的**步数 11 → 12**（口径已变）。
3. `docs/CURRENT-STATE.md` §1 表 / 纪律段 + `handoff.md` + `docs/WAVE24-PREREGISTRATION.md` §2.3/§8 的步数。
4. **可选（主控决定）**：`run_step` 失败时的诊断 `grep -E "error [A-Z]+[0-9]+|Failed!|Failed [A-Za-z]"`（`:87`）**匹配不到** `PCLINE_START_STEP=FAIL …` 与 `FRAME_STEP=FAIL …`（两者都不含 `Failed`）⇒ 失败时屏上只有 `❌ (rc=1)`，细节要靠 `/tmp/verify-all-*.log`。若要屏上直接可见，可把该 grep 扩成 `…|Failed [A-Za-z]|_STEP=FAIL`；**但那会同时改变第 11 步的输出**，属主控决定，我**没有**动。

---

## §7 复算、位移与并发/纪律 48 披露

### §7.1 九位与 `inputs_fp`（算法照抄 `build/close-wave.sh` 的 `fp_inputs()`，脚本现场算，**不手抄**）
| 位 | 开工（09:30:3x） | 收工（10:26） | 判定 |
|---|---|---|---|
| `bridge` | `d567c26f197ec1e3` | `d567c26f197ec1e3` | 不变 ✅ |
| **`pc`** | `7b47a7b3d69ad62f` | **`476994e35d31a7e1`** | **变**（W24A = P1 改 patcher ⇒ 重建 PC）＝**§5 表内预测** |
| `pf` | `1c3fe23261c22bc6` | `1c3fe23261c22bc6` | 不变（预告"波尾 `close-wave` 才变"） |
| `windowsbase` / `provider` / `win32shim` / `wic_shim` / `dwf` | `1114a28ec5a03ab7` / `9aa0d744802aaa31` / `0098234982391bbf` / `03b67fbcd7c385b6` / `0ed422ef2dd46445` | 同 | 不变 ✅ |
| **`hbtextline`** | `e89fed55fd8e32bc` | `e89fed55fd8e32bc` | **不变** ✅（**本波不许动 shim** —— 也是我"没碰别人写域"的机器证） |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | `b6acdba4f01599d8` | 不变 ✅ |
| **`inputs_fp`** | `6146f3641b87a5a7d74e182ab9ca3f6f72299377bbfce2993843cb56ccbca0ca` | **`a87034194a66f7d18a9903a06337ad839cae8dba2669736abbec9cd8f6dee793`** | **变**＝§5 表内预测（`src/WpfGfx.Linux.Native/tools/patch-*.py` 在覆盖面内，由 W24A 改动） |
| `known-red.json` | `e623d2b17d948e3b` | `e623d2b17d948e3b` | 不变 ✅（我没碰） |

**⇒ 表外位移：无。** 我自己的两份产物（`build/MilBridge/tests/FrameProbe/Program.cs`、`build/MilBridge/tools/frame-step.sh`）**都不在 `fp_inputs()` 的覆盖面内**（该函数只收 `patch-*.py`/`port-lib.py`/`integration-wave.sh`/`close-wave.sh`、`build/shims/**.cs`、`src/WpfGfx.Linux/**.cs`）⇒ 上面 `inputs_fp` 的变化**只能**归因 W24A 的 patcher。

### §7.2 `pc` 在我读数期间**变过**（纪律 35 ⇒ 逐趟标定，**不重取已有归属清楚的读数**）
| 时刻 | `pc` | 我的读数 |
|---|---|---|
| 09:30–09:38 | `7b47a7b3d69ad62f` | 修前仪器 strict/lenient；修后仪器 strict/lenient |
| ~09:46:20 | → **`476994e35d31a7e1`**（W24A） | 修后仪器 `--prefix 40` 腿**跨越了这个时刻** ⇒ 但探针自证 `本机副本 sha16 前=后=7b47a7b3d69ad62f`（进程启动时就把它 mmap 了；`权威路径 后=476994e35d31a7e1`）⇒ **该读数归属 `7b47a7b3d69ad62f`**，日志里两侧都印着 |
| 09:53–10:24 | `476994e35d31a7e1`（稳定） | `frame-step.sh` 首跑（rc=0）、腿 A、N-1（私目录修前 pc）、N-2/N-3/N-4、**终跑 rc=0** —— 每一步都印了 `被测 pc 全程未变` |

### §7.3 独立复算 `#23` 的"五处 grep 全 0"
`grep -ac FrameProbe` ⇒ `verify-all.sh` **0**｜`build/MilBridge/tools/tline-gate.sh` **0**｜`build/MilBridge/tools/pc-line-step.sh` **0**｜`build/MilBridge/run.sh` **0**｜`build/MilBridge/arm-logs/README.md` **0**（可与 `#23` 的结论逐条对照）。

### §7.4 并发披露（纪律 48：并发跑同一仪器必须标 PID/时刻/被测件 sha）
本波至少还有三条车道在跑，且**有一次外部进程在并发跑我这份 `frame-step.sh`**：
- **W24A**（P1，重建 `pc`）：`bash -c … CASES=… run-matrix.sh ~/w24a-run/…`（`PID 415166` @09:31、`PID 493100` @09:46–09:52，其 `dotnet` 子进程 `PID 493644/493645`）；`PcLineOracle` 预读那趟 `PID 439657/452372`、`dotnet 452374/452375` @09:50–09:52；内存采样器 `PID 414986`。**`pc` 的换代是它做的**（09:46:20 前后）。
- **W24C**（P3）：`PID 452556` / `timeout 454089` / `dotnet 454090` 跑 `--tab-lines-oracle` @09:44–09:46。
- **⚠️ 另有一个外部进程并发跑我的 `frame-step.sh`**：`PID 522415` → `522416`（`/usr/bin/time -f … bash build/MilBridge/tools/frame-step.sh`，输出 `$HOME/w24b-step-timed.out`）→ `PID 522720`（探针 `--leg b --tier strict --prefix 40`），**起于 10:17，与我的终跑（10:17:01→10:24:07）时间窗完全重叠**，用的是**同一个工程输出目录**。我的终跑 `rc=0`、`pc` 全程未变、`copy==auth`、族分解自洽，**读数自身自洽**；但**两个进程同时构建同一工程是我无法排除的噪声源**，故我在 §4.2 之外**另取了一趟无并发确认跑**（见 §11）。**若主控要引用"rc=0"作判据，请引用无并发那一趟。**

**补记（无并发确认跑）**：外部那趟在 **10:24:38** 结束（`$HOME/w24b-step-timed.out` 的 mtime），我的确认跑 **10:25:34** 才起 ⇒ **两窗不重叠**，确认跑是**无并发**的；它 `rc=0`、`pc` 全程未变、输出与首跑**逐字节相同（只差日志目录那一行）**。详据见 §11。

---

## §8 我推翻 / 更正 / 自查出的问题

### §8.1 **推翻**（最重要）：`#23` 表里那三格**判别力不等价**；只接 `strict`（不带 `--prefix`）这一条腿对 `D-T6-b` **零判别力**
`#23`/W23B 的修前表把三格并列：宽松档 133｜严格档 **3**｜严格档+`--prefix 40` **421**。本件用**同一支探针**在**修前 pc `e7cabff9417ed380`** 上实测：
- 修前 `strict`：`红行=3 帧红=0 结构红=3`；现树 `pc` 的 `strict`：`红行=3 帧红=0 结构红=3` ⇒ **逐位相同**；
- 修前 `lenient`：`红行=133 帧红=133`；修前 `strict+prefix40`：`红行=421 帧红=421`。
⇒ 「严格档 红 3 行」这一格**不能**作为 `D-T6-b` 修法的证据（它修前修后一样）；**真正有判别力的是 `--prefix 40` 格与宽松档格**。⚠️ 请主控注意：**下游若只接 `strict` 一条腿，本判据对 `D-T6-b` 是空判据**。这也是我把 `--prefix 40` 接成**决定 rc 的腿**的直接原因。

### §8.2 **更正**：`#23` 的「帧族红 = 0/**418**」口径被独立复现，但分母要给对
现树 pc 三条腿 `帧红可比分母=418 / 帧红可比子集=0` ⇒ 「0/418」成立；而 `红行` 的分母是 **421**。**两个分母**（418 = 可比的、421 = 判定的）必须分开写，否则"0/421"是错的。

### §8.3 **自查出我自己的 bug（已修、已留证）**：`frame-step.sh` 首版在三处 `echo` 里用了反引号
`echo "…（\`#24\` P2 后…）"` 里的反引号被 bash 做成**命令替换** ⇒ 运行时 stderr 打出 `行 188: 帧红: 未找到命令` 且**把词吃掉**（首版实测日志 `$HOME/w24b-run/neg-degen.out:28-29` 原样可查；当时打印的是"见上面逐腿点名（≠0 或 ≠0 或恒绿退化）"）。已改为无反引号写法并在文件头留下防复发注释；首版 sha16 `b168c353385df785`（留档 `$HOME/w24b-backup/frame-step.sh.orig`），修后 `37f27df68e52bf8c`。⇒ 现在所有读数都是修后版本取的（N-2 的**复跑**已无该噪声）。

### §8.4 **更正预登记的字面表述**：`NOINFO` 必须**按族**分解，否则本步要么永远红、要么作弊
预登记 §2.2 只写"`NOINFO` 不许算绿"。实测 `NOINFO行=101` **恒非零**（语料性质：真值数组短于我方行数 ⇒ 多出来的我方行没有真值可比）。若把 `NOINFO行>0` 当红 ⇒ 本步**永远 rc=1**（退化成"没人看的红"）；当绿则是明令禁止的。⇒ 我把它按族分解，断言 **`仪器族NOINFO==0`**、打印 `结构族NOINFO=`。

### §8.5 一处**没有**推翻但需要主控知道的形状证据
`strict+prefix40` 腿上同一行同时印出 `我方帧(扫描)=41`、`我方帧(_lineStart)=1`、`我方cpFirst=41` ⇒ `_lineStart`（Option 1 之后是**行相对**量）**不是**"帧"；本判据读**帧**（`GetTextBounds` 扫描），与真机宿主读法同源。

---

## §9 `NOINFO` / 未测清单（缺数据就说缺数据）

1. **`--fresh-source` 腿**：未接、未测（`#23` 记录修前 133 → 修后 3；本波未复算）⇒ **`NOINFO`**。
2. **`--leg a` 的判别力**：只测了它与腿 B **同值**（`帧红=0/结构红=3`）⇒ 结论仅限"加它不增判别力"，**没有**测它在修前 pc 上的行为 ⇒ 未测。
3. **修前 pc 的 `--leg a` / `--fresh-source`**：未测。
4. **`GetTextBounds` "空表 vs 真机夹取"**：本件**不实现**夹取，也未新增读数（W23B 已据实标 `NOINFO`）——本件沿用其结论，**不重复**。
5. **结构族红（3 条）的登记**：**未做**（主控的登记决定；本件只做到"点名可见"，探针 `probe_rc=1` 原样保留）⇒ 这是本件的**已知欠账**。
6. **`pc` 归属**：`--prefix 40`（修后仪器）那一趟**跨了 `pc` 换代时刻**；靠探针自证 `本机副本 前=后=7b47a7b3d69ad62f` 判定归属，**但"权威路径在跑动中途变了"这一事实**我如实记下（§7.2），**没有**重取那一趟。
7. **`verify-all.sh` 真的插进第 12 步后**的整趟读数：**未跑**（`verify-all` 是**主控写域**，预登记 §7.5 明令禁止我跑）⇒ 第 12 步在**全量回归里的实际 rc** 是 `NOINFO`。
8. **私目录跑修前 pc 需要的 `WPF_LINUX_WIN32_SHIM`**：那是**仪器输入**（纪律 40），我只在私目录那一族读数里设置；**交付脚本里没有**这个环境变量（树里探针自己找得到 native shim）。

---

## §10 附录 A —— `build/MilBridge/tools/frame-step.sh` **全文**
（本附录由脚本在写报告时**从文件直接拼进来**，**不是手抄**；机器核过：代码块内容 == 文件内容**去掉末尾那一个换行**，其余**逐字节相同**；sha16 见 §1）

```bash
#!/usr/bin/env bash
#
# 主控 · 波 `#24` —— **帧列**（`FrameProbe`）的冻树牙齿（`verify-all` 的**第 12 步**）。
#
# 【为什么需要它（本波新查出的**结构性缺口**，见 `docs/WAVE24-PREREGISTRATION.md` §2）】
#   `#23` 实测：`FrameProbe`（`#22` 建的 `D-T6-b` 帧判据探针）在
#     `verify-all.sh` / `tline-gate.sh` / `pc-line-step.sh` / `run.sh` / `arm-logs/README.md`
#   **五处 grep 全 0** ⇒ 它**不在任何冻树回路里**；而它报的残余红（strict/lenient 各 `红行=3`）
#   **今天无处可登记**。⇒ **欠的是接线，不是登记**（车道 W23D 的结论，主控采纳）。
#   而"帧"这一列在冻树上**没有任何别的牙齿**：`pc-line-step.sh` 只判 `TextLine.Start` 一列。
#
# 【本步判**哪一列**：`帧红`，**不是** `红行` —— 这是本步最重要的一条口径】
#   `#23` 已定性：`红行=3` 那 3 条**全是"行数不等"结构族**（每条自报 `行数我方=4 真值=2`），
#   **不是帧错**：全量 421 行上 `frame == 我方cpFirst`（帧原点机制没坏），
#   只是"我方分行 ≠ 真机分行" ⇒ 我方 cpFirst ≠ 真值 startChar。
#   ⇒ `#24` P2 让 `FrameProbe` 把 `红行` **按族分解**（`Program.cs` 汇总行末尾新增 `帧红=` / `结构红=`，
#     并新增自证行 `FRAMEPROBE 红族分解 …`）：
#       · **帧红**   = 红 ∧ `扫描帧 != 我方cpFirst` ⇒ **帧原点机制本身错**（`D-T6-b` 那一族）；
#       · **结构红** = 红 ∧ `扫描帧 == 我方cpFirst` ∧ `我方cpFirst != 真值 startChar`
#                      ⇒ 「我方分行 ≠ 真机分行」，**不是帧错**。
#   ⛔ **本步断言 `帧红 == 0`，绝不断言 `红行 == 0`**（预登记 §2.2 明令）：
#      把 `红行` 当判据 = 把结构族也吞进来，**与 `#23` 的教训相反**，而且会让本步**永远红**、
#      从而退化成"没人看的红"（事故 `L26` 的同族）。
#   ⚠️ **本步不判**结构族红（`结构红=3`）。它是**另一笔账**（"把 3 条压成登记"是**主控的登记决定**）：
#      本步只在输出里**逐条点名** `结构红` 的 id，让那 3 条**有处可登记**；
#      **不许**读成"本步把它洗绿了"—— 探针自己的 rc（=1）在下面**逐腿原样打印**。
#
# 【`NOINFO` 不许算绿 —— 两类 `NOINFO` 必须分开，否则判据必错】
#   探针的 `NOINFO行`（`#24` 实测 101）**不是仪器缺口**，是**语料性质**：真值数组短于我方行数时，
#   多出来的我方行**没有真值可比**（同族的 `我方行数 != 真值行数 的例` = 60）。
#   `#24` P2 因此也把它按族分解：`仪器族NOINFO`（有真值却扫不出帧 = **仪器缺口**）与
#   `结构族NOINFO`（该行无真值可比 = **语料性质**）。**本步断言 `仪器族NOINFO == 0`**，
#   而 `结构族NOINFO` 只打印并标口径（既**不许当绿**，也**不许当仪器缺口**）。
#   仪器级 `NOINFO` 另有四条，**一律 rc=2**：探针 rc=2｜汇总行缺失｜字段解析不出｜族分解不自洽。
#
# 【三条腿，以及**哪几条决定 rc**（预登记 §2.3 要求逐条写清）】
#   ① `--leg b --tier strict`                      —— **决定 rc**
#   ② `--leg b --tier lenient`                     —— **决定 rc**
#   ③ `--leg b --tier strict --prefix 40`          —— **决定 rc**
#   **理由（为什么 ①② 必须都有）**：`strict` = PC 先试的那一层（`HbTextFallback`），
#     `lenient` = 它返回 null 之后的兜底层（`WpfLinuxLenientTextFallback`）——**两条是不同代码路径**，
#     只跑一条等于把另一条留在回路外（`D-T3` 的一半当初就是这么漏掉的）。
#   **理由（为什么 ③ 也决定 rc，尽管它口径与 ①② 不同）**：`--prefix 40` 把源串变成 `'M'×40 + 用例文本`、
#     首调下标 = 40 ⇒ **段落原点 ≠ 0**，且真值帧 = `40 + startChar` ⇒ 真值侧被**整体平移**
#     （`真值非零行 133 → 421`：`#23` 实测，所以**它的读数不能与 ①② 直接比列**）。
#     它是**唯一**一条"段落原点 ≠ 0"的腿 —— 而 `D-T6-b` 这一族缺陷**恰恰是帧原点与段落原点的关系**。
#     不接它 ⇒ 本步对"假设段落原点恒为 0"这类错误**零判别力**。故接，但**只在输出里标清口径差异**。
#   **所有三条腿的判据形式完全相同**（`帧红==0 ∧ 判定行>0 ∧ 仪器族NOINFO==0 ∧ 自洽==1`）——
#     差别只在**列的可比性**（真值非零行），不在断言；**任一条腿任何一条断言不成立 ⇒ rc=1**。
#   代价：三条腿 ≈ 9~10 分钟（`#24` 实测 ①≈3 min / ②≈3 min / ③≈3.5 min）。
#
# 【为什么自己重建】`FrameProbe.csproj` 用 `HintPath`+`Private=true` 引 PC ⇒ 产物目录里有一份
#   `PresentationCore.dll` **副本**。跑之前必须让它与树里的权威件**逐位相同**，否则量的是一份**旧产物**
#   （`D-A2` 那一族；`#22`/`#23` 都踩过）。⇒ 强制重建 + **断言副本 == 权威**；不等 ⇒ `NOINFO`。
#   ⚠️ 本波 `pc` 由**另一条车道**改（纪律 48）⇒ 全程记 `pc` sha16，**跨整个步变了就作废**（rc=2）。
#
# 三态：rc=0 判据通过｜rc=1 判据**红**（`帧红`≠0 / `仪器族NOINFO`≠0 / **恒绿退化**）｜rc=2 `NOINFO`（算不出）。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT" || exit 2
export PATH="$HOME/.dotnet:$PATH"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
# 内存纪律（预登记 §7.2）：**所有** dotnet 命令 `-m:1` + `DOTNET_gcServer=0`
export DOTNET_gcServer=0

PROJ_DIR="$ROOT/build/MilBridge/tests/FrameProbe"
PROJ="$PROJ_DIR/FrameProbe.csproj"
CORPUS="$ROOT/tests/parity/windows/tab-anchor/out/tab-anchor-raw.json"
OUT="$PROJ_DIR/bin/Release"
ARM="$OUT/PresentationCore.Tests.dll"
AUTH_PC="$ROOT/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll"
COPY_PC="$OUT/PresentationCore.dll"
LOGDIR="${FRAME_STEP_LOGDIR:-/tmp/frame-step}"

sha16() { [ -f "$1" ] && sha256sum "$1" | cut -c1-16 || echo "MISSING"; }

for f in "$PROJ" "$CORPUS" "$AUTH_PC"; do
    [ -f "$f" ] || { echo "FRAME_STEP=NOINFO 缺文件：$f"; exit 2; }
done
mkdir -p "$LOGDIR" || { echo "FRAME_STEP=NOINFO 建不了日志目录：$LOGDIR"; exit 2; }

# 纪律 15/18/40：读数必须连 artifact+字段+sha 一起写；**仪器变更要披露**
# ⚠️ 所有 `echo` 串里**不许出现反引号**（那双引号里的反引号会被做成命令替换）：
#   `#24` P2 首版在三处 echo 里踩了这条 ⇒ 运行时 stderr 打出"帧红: 未找到命令"**并把词吃掉**
#   （实测日志 `$HOME/w24b-run/neg-degen.out:188`）。已改；本注释即为防复发。
echo "FRAME_STEP 仪器·Program.cs = $(sha16 "$PROJ_DIR/Program.cs")（波 #24 P2 后：含 帧红/结构红 + NOINFO 族分解）"
echo "FRAME_STEP 仪器·FrameProbe.csproj = $(sha16 "$PROJ")"
echo "FRAME_STEP 语料           = $(sha16 "$CORPUS")  路径=$CORPUS"
PC_AT_START="$(sha16 "$AUTH_PC")"
echo "FRAME_STEP 被测 pc（树）  = $PC_AT_START  路径=$AUTH_PC"
echo "FRAME_STEP 日志目录       = $LOGDIR"

dotnet build "$PROJ" -c Release -m:1 --nologo -v q >"$LOGDIR/build.log" 2>&1 \
    || { echo "FRAME_STEP=NOINFO 构建失败 ⇒ 算不出，不是绿（见 $LOGDIR/build.log）"; exit 2; }

S_AUTH="$(sha16 "$AUTH_PC")"; S_COPY="$(sha16 "$COPY_PC")"
if [ "$S_COPY" = "MISSING" ] || [ "$S_AUTH" = "MISSING" ]; then
    echo "FRAME_STEP=NOINFO 产物副本或权威件缺失：copy=$S_COPY auth=$S_AUTH"; exit 2
fi
if [ "$S_AUTH" != "$S_COPY" ]; then
    echo "FRAME_STEP=NOINFO 产物目录里的 pc 副本与权威件不符：copy=$S_COPY auth=$S_AUTH"
    exit 2
fi
echo "FRAME_STEP 被测 pc        = $S_COPY（copy == auth ✓）"

num() { printf '%s' "$1" | grep -oE "$2=[0-9]+" | head -1 | cut -d= -f2; }

# 腿表：<标签>|<tier>|<额外参数>   （决定 rc 的三条腿，见文件头）
LEGS=(
  "strict|strict|"
  "lenient|lenient|"
  "strict+prefix40|strict|--prefix 40"
)

DEC=0          # 0=通过 1=红 2=NOINFO；取最大 ⇒ NOINFO 压过红（"算不出"不许被"红"盖住）
STRUCT_IDS=""

for spec in "${LEGS[@]}"; do
    TAG="${spec%%|*}"; rest="${spec#*|}"; TIER="${rest%%|*}"; EXTRA="${rest#*|}"
    LOG="$LOGDIR/$TAG.log"
    # shellcheck disable=SC2086
    DISPLAY="${DISPLAY:-:97}" dotnet "$ARM" --corpus "$CORPUS" --leg b --tier $TIER $EXTRA > "$LOG" 2>&1
    PRC=$?
    echo
    echo "FRAME_STEP ── 腿 $TAG（--leg b --tier $TIER $EXTRA）probe_rc=$PRC  日志=$LOG"

    SUM="$(grep -a -m1 '^FRAMEPROBE 汇总 ' "$LOG" || true)"
    FAM="$(grep -a -m1 '^FRAMEPROBE 红族分解 ' "$LOG" || true)"
    if [ -z "$SUM" ] || [ -z "$FAM" ]; then
        echo "FRAME_STEP=NOINFO 腿 $TAG 找不到计数器行（汇总/红族分解）⇒ 算不出（探针换了？腿没跑？）"
        echo "                 probe_rc=$PRC  日志=$LOG"
        DEC=2; continue
    fi
    echo "FRAME_STEP 腿 $TAG 计数器 = $SUM"
    echo "FRAME_STEP 腿 $TAG 族分解 = $FAM"

    JR="$(num "$SUM" 判定行)"; RH="$(num "$SUM" 红行)"; FR="$(num "$SUM" 帧红)"; ST="$(num "$SUM" 结构红)"
    NI="$(num "$FAM" 仪器族NOINFO)"; NS="$(num "$FAM" 结构族NOINFO)"; OK="$(num "$FAM" 自洽)"
    for v in "$JR" "$RH" "$FR" "$ST" "$NI" "$NS" "$OK"; do
        if [ -z "$v" ]; then
            echo "FRAME_STEP=NOINFO 腿 $TAG 计数器字段解析不出来（判定行/红行/帧红/结构红/仪器族NOINFO/结构族NOINFO/自洽）⇒ 算不出"
            DEC=2; continue 2
        fi
    done
    echo "FRAME_STEP 腿 $TAG 机读 判定行=$JR 红行=$RH 帧红=$FR 结构红=$ST 仪器族NOINFO=$NI 结构族NOINFO=$NS 自洽=$OK probe_rc=$PRC"

    # ① 族分解自洽（仪器坏了 ⇒ NOINFO，绝不让坏仪器报绿）
    if [ "$OK" -ne 1 ] || [ $((FR + ST)) -ne "$RH" ]; then
        echo "FRAME_STEP=NOINFO 腿 $TAG 红族分解不自洽（帧红 $FR + 结构红 $ST != 红行 $RH，自洽=$OK）⇒ 仪器不可信"
        DEC=2; continue
    fi
    # ② 恒绿退化（一行都没判过 ⇒ "帧红=0" 恒真、毫无意义）
    if [ "$JR" -le 0 ]; then
        echo "FRAME_STEP=FAIL 腿 $TAG 判定行=$JR ⇒ **恒绿退化**：一行都没判过，'帧红=0' 毫无意义"
        DEC=1; continue
    fi
    # ③ 仪器缺口（有真值却扫不出帧）—— `NOINFO` 的那一半，**不许算绿**
    if [ "$NI" -ne 0 ]; then
        echo "FRAME_STEP=FAIL 腿 $TAG 仪器族NOINFO=$NI ⇒ 有真值的行扫不出帧（**仪器/实现缺口**，不是语料性质）"
        DEC=1; continue
    fi
    # ④ 判据本体
    if [ "$FR" -ne 0 ]; then
        echo "FRAME_STEP=FAIL 腿 $TAG **帧红**=$FR / 判定行=$JR ⇒ 帧原点机制错（D-T6-b 那一族）"
        grep -a '^FRAMEPROBE RED ' "$LOG" | head -5 | sed 's/^/      /'
        DEC=1; continue
    fi
    # ⑤ 结构族红：**只点名，不判**（另一笔账；见文件头）
    echo "FRAME_STEP 腿 $TAG 结构族红=$ST（**本步不判**：我方分行 != 真机分行，属登记决定，见文件头）｜结构族NOINFO=$NS（语料性质，非仪器缺口）"
    if [ "$ST" -gt 0 ]; then
        echo "FRAME_STEP 腿 $TAG 结构族红点名（供登记用）："
        grep -a '^FRAMEPROBE RED ' "$LOG" | sed 's/^/      /'
        STRUCT_IDS="$STRUCT_IDS $TAG:$ST"
    fi
done

# ④ 全步期间 `pc` 不许被动过（纪律 35/48：并发跑同一仪器要标时刻与件 sha）
PC_AT_END="$(sha16 "$AUTH_PC")"
echo
if [ "$PC_AT_END" != "$PC_AT_START" ]; then
    echo "FRAME_STEP=NOINFO 本步期间被测 pc 变了：start=$PC_AT_START end=$PC_AT_END ⇒ 本次读数不可归因（纪律 35）"
    exit 2
fi
echo "FRAME_STEP 被测 pc 全程未变 = $PC_AT_START"
echo "FRAME_STEP 结构族红汇总（**未登记，主控的登记决定；本步不判**）：${STRUCT_IDS:- 无}"

case "$DEC" in
    0) echo "FRAME_STEP=PASS 三条腿（strict / lenient / strict+prefix40）均 帧红=0 ∧ 判定行>0 ∧ 仪器族NOINFO=0 ∧ 自洽=1"
       exit 0 ;;
    1) echo "FRAME_STEP=FAIL 见上面逐腿点名（帧红≠0 或 仪器族NOINFO≠0 或 恒绿退化）"
       exit 1 ;;
    *) echo "FRAME_STEP=NOINFO 见上面逐腿原因（算不出 ⇒ **不是通过**）"
       exit 2 ;;
esac
```

---

## §11 无并发确认跑（终跑；**引用 `rc=0` 时应引用这一趟**）

**命令（逐字）**
```
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
FRAME_STEP_LOGDIR=$HOME/w24b-run/confirm-logs \
  /usr/bin/time -f "WALL=%e s  MAXRSS=%M KB" bash build/MilBridge/tools/frame-step.sh
```
**起点/终点（脚本自印）**
```
START 2026-09-17T10:25:34+08:00 pc=476994e35d31a7e1 loadavg=1.05 1.95 2.62 mem=3397804
END   2026-09-17T10:32:08+08:00 pc=476994e35d31a7e1 loadavg=1.11 1.35 2.09 mem=3386156
```
**判据行（原样）**
```
FRAME_STEP 仪器·Program.cs = 503e6ebd86d70303（波 #24 P2 后：含 帧红/结构红 + NOINFO 族分解）
FRAME_STEP 语料           = 88559d670f1bb955  路径=…/tests/parity/windows/tab-anchor/out/tab-anchor-raw.json
FRAME_STEP 被测 pc（树）  = 476994e35d31a7e1  路径=…/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll
FRAME_STEP 被测 pc        = 476994e35d31a7e1（copy == auth ✓）
FRAME_STEP 腿 strict 机读 判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 probe_rc=1
FRAME_STEP 腿 lenient 机读 判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 probe_rc=1
FRAME_STEP 腿 strict+prefix40 机读 判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1 probe_rc=1
FRAME_STEP 被测 pc 全程未变 = 476994e35d31a7e1
FRAME_STEP 结构族红汇总（**未登记，主控的登记决定；本步不判**）： strict:3 lenient:3 strict+prefix40:3
FRAME_STEP=PASS 三条腿（strict / lenient / strict+prefix40）均 帧红=0 ∧ 判定行>0 ∧ 仪器族NOINFO=0 ∧ 自洽=1
```
**`rc=0`**；`WALL=394.07 s  MAXRSS=706576 KB`；输出 sha16 **`72ede9085b130e73`**（40 行，`$HOME/w24b-run/frame-step-confirm.out`）；时序 `$HOME/w24b-run/frame-step-confirm.time`。

**可复现性（机器证）**：两趟 `rc=0` 的输出在**剔掉"日志目录"那一行**后 `diff` **无差异** ⇒ 同一 `pc`、同一语料、同一仪器下**逐字节可复现**。

**外部独立复现（不是我跑的，如实登记）**：另一个进程在 **10:17:28–10:24:38** 用同一份脚本跑出 `FRAME_STEP=PASS`（`WALL=427.96 s  MAXRSS=708300 KB`，输出 `$HOME/w24b-step-timed.out`）。它的读数与我的**逐列相同**（`判定行=421 红行=3 帧红=0 结构红=3 仪器族NOINFO=0 结构族NOINFO=101 自洽=1`）。⚠️ 它与我的**首跑时间窗重叠**（同工程同输出目录）⇒ 这也是我在 §4/§11 以"无并发确认跑"为**正式依据**的原因（纪律 48）。


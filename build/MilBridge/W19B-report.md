# W19B —— 臂 `PcLineOracle` 的**严格档腿** + 层级来源自证；`#19` §0.1 **B** 的**修前红证**

> **lane = W19B**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **时刻（开工）**：`2026-09-16 15:22:29 +0800`｜`uname -r = 6.8.0-138-generic`｜`loadavg = 0.56 0.88 1.34`｜`MemAvailable = 3,203,572 kB`
> **时刻（收尾）**：`2026-09-16 15:39:26 +0800`｜`uname -r = 6.8.0-138-generic`｜`loadavg = 0.36 2.33 2.70`｜`MemAvailable = 3,646,236 kB`｜收尾时 `pc` **仍是 `663114436443d2de`**（未被重建）、`shim` 已是 W19A 的 `fe1b7ed8fa3ed231`（见 §8.3）
> **写域**：`build/MilBridge/tests/PcLineOracle/**`（改了 `Program.cs` 一个文件）、本文件、`$HOME/wfp-runs/w19-laneW19B/`。
> **未改**：`build/shims/**`（**另一条车道 W19A 在本车道作业期间改了它两次**，见 §8.3）、`build/MilBridge/known-red.json`、`build/MilBridge/tools/tline-gate.sh`、`verify-all.sh`、`docs/**`、`samples/**`、`tests/**`、`build/MilBridge/tests/MinMaxProbe/**`、任何 `build/*.Linux/**` 的权威输出。
> **未重建 `PresentationCore`**（本工程只*引用*它；`pc` 全趟逐位不变，见 §8.1）。

---

## 1. 一行判决

**严格档腿建成了，`#19` §0.1 B 的修前红证到手：`rc=1`，`非0缩进 红=184 / 224（绿=0）`，两个判别例的 Δ **恰好 = `−24.000000`**，层级来源自证 `严格档接手=270 例 / 宽松档=0 例`（`fallbackHandled=482`、`relaxedHandled=0`）—— 与预测**同形且逐位吻合**。**

**但（本车道最值钱的一条）**：严格档腿的红**不止** B 这一族。同一趟读数里还测出**第二族与 indent 无关的红**：**零缩进 `@default` 例 19 条**（`A-anchor` 4 + `B-indent` 15，全部 `行#N i=0 取不到字符边界`），它们在**宽松档下全绿**、在**严格档下全红**（同例跨档对照见 §5.4）；另有 20 条 `@tab0` 例是"宽松档绿、严格档红"。
⇒ **§1 B 的"修后必须绿：非 0 缩进 红=0"在严格档腿上按字面**不可达**（已登记的 `tab0` 族 92 条修后仍红），且**修后 `未登记失败` 必然 ≥19** ⇒ 严格档腿**修后仍会是 `rc=1`**。
⇒ 判据必须**按桶 + 按失配词**读（§6），**不许**拿"整腿 rc 还是 1"读成"B 没修好"。

**另外推翻两条现场前提**（§1.1）。

### 1.1 被本车道推翻/更正的（含派单与本波预登记的措辞）

| # | 谁 | 原话（逐字） | 反证 | 处置 |
|---|---|---|---|---|
| R1 | 本波派单 §「What to do」1 + `WAVE19-PREREGISTRATION.md:35` | "现有臂 … **层级由 `WPF_LINUX_TEXTLINE_FALLBACK` 决定** … ⇒ **把那个 env 去掉**（默认 ⇒ 先走严格档）就是严格档腿" | 旧版臂在 `Main` 里**无条件** `Environment.SetEnvironmentVariable(FallbackEnvVar, "0")`（备份 `Program.cs.before:179`）⇒ **命令行上"去掉 env"什么也改不了**，它自己会再置 0（实测：外部 `env -u` 也一样） | 严格档腿**必须**有旗标；已加 `--tier strict`。预登记那句在**旧版臂**上不成立（不是错，是措辞把"臂的默认"当成了"环境的默认"） |
| R2 | `W17A-report.md` §7.1 第 1 条 | "严格档（`HbTextFallback.TryFormatLine`, shim `:4496`）的 `Indent`/`PI` 缺口 … **本臂对严格档零射程**" | 那是一句**关于未经改动的臂**的真话；本车道给了它射程（`--tier strict`）⇒ **该句对旧版臂仍成立，对本版臂不再成立**，已在源码抬头逐字标注 | 已改写臂内注释（§3.4），预登记的"§1 B 红证必须用严格档腿"由此才真正可执行 |
| R3 | `W17A-report.md` §2.5 表格 | 腿 B："`SimpleTextLine.Linux.cs:210` 的闸门 ⇒ 436 例**全部**落宽松档" | 只在**宽松档腿**成立；严格档腿下 436 例先由严格档接手（实测 `严格档接手=270 例、宽松档接手=0 例`） | 已把该行改成**分档陈述**（§3.4） |
| R4 | `W17A-report.md` §2.4 的正控设计（"`relaxedHandled <= 0` ⇒ `rc=2 NOINFO`"） | 每例都要求宽松档被走到 | 旧代码逐字：备份 `Program.cs.before:551` `if (DiagHandled() <= 0)` ⇒ `:554` `PCLINE_EXIT=NOINFO rc=2 原因=被测宽松档未被走到（正控失败）`。严格档腿上 `relaxedHandled` **结构性**恒 0 ⇒ 旧正控**必然**把严格档腿判成 `NOINFO` ⇒ **旧版臂在结构上不可能有严格档腿**（`proven`：代码 + 本趟宽松档腿实测 `relaxedCalls=0`） | 正控改为**档位感知**（§3.3），并保留"两档皆 0 ⇒ `rc=2` 不许报绿" |

---

## 2. 改了哪些文件（before → after，含备份）

| 文件 | sha16 **前** | 字节 | mtime 前 | sha16 **后** | 字节 | mtime 后 |
|---|---|---|---|---|---|---|
| `build/MilBridge/tests/PcLineOracle/Program.cs` | **`544aab374ee8e1a6`** | 57,572 | 2026-09-16 11:44:53.475295279 +0800 | **`a46e5e046583f69a`** | 72,948 | 2026-09-16 15:26:10.091231778 +0800 |
| `$HOME/wfp-runs/w19-laneW19B/backup/Program.cs.before`（**备份，`cp -p`**） | — | 57,572 | **保留原 mtime** 11:44:53.475295279 | `544aab374ee8e1a6`（逐位 == 改前） | 57,572 | 同左 |
| 臂产物 `…/PcLineOracle/bin/Release/PresentationCore.Tests.dll` | `3a474e675b24fdf4`（W17B 时代，38,912 B） | 38,912 | — | **`8f6771a9a2ffad20`** | 45,568 | 2026-09-16 15:26:13.687267404 +0800 |
| `PcLineOracle.csproj`（**未动**，自证） | `b0bf270206fe9c09` | 4,380 | 2026-09-16 11:09:12 | `b0bf270206fe9c09` | 4,380 | 同左 |
| `PcLineOracle/known-red.txt`（**未动**，自证） | `89324f1f643167e5` | 17,501 | 2026-09-16 12:00:16 | `89324f1f643167e5` | 17,501 | 同左 |

构建（纪律 33：真实构建，不是 `--check`）：
```bash
export PATH="$HOME/.dotnet:$PATH"          # ⚠️ SDK 不在默认 PATH（rc=127 = 没跑）
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
dotnet build -m:1 -c Release build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj
# ⇒ 已成功生成。**0 个警告 / 0 个错误**（BUILD_RC=0）
```
`diff` 规模：**14 个 hunk，`<` 37 行 / `>` 219 行**（无重复块：`diff | grep -c '^@@'` = 14）。

**一条必须点名的编译期证据**：严格档计数是**直接字段访问**（不是反射）——
`WpfLinux.Shims.PresentationCore.HbTextFallback.{Calls,Handled,Bailed,BailNoSwitch,…,LastBail}` ——
Roslyn 能解析它 = **这些 `internal` 成员真的在 `pc` 的元数据里**；改名/删除会立刻 `error CS`。

---

## 3. 臂的改动：tier 选择器 + 层级来源

### 3.1 `--tier`（缺省 `auto`）

| 取值 | 动作 | 生效档（**由产品自己的开关判定**，不是由 env 判定） |
|---|---|---|
| `strict` | **清掉** `WPF_LINUX_TEXTLINE_FALLBACK`（`SetEnvironmentVariable(...,null)`） | PC 生成物 `:565` 的 `HbTextFallback.TryFormatLine`（**产品默认先走的这一层**；`:565` 是**现场重读**的行号，W19A 落地 B 之前也是 `:565`） |
| `lenient` | 置 `= 0`（**与建臂以来逐字相同**） | PC 生成物 `WpfLinuxLenientTextFallback.TryFormatLine` —— ⚠️ **行号已漂**：W17A/W17B 时代是 `:575`，W19A 落地 B 之后是 **`:596`**（预登记 §4.4 说的"行号会漂"的又一实例；引用一律带 sha） |
| `auto`（**缺省**） | 环境里**已给** ⇒ 不动它；环境里**没给** ⇒ 沿用今天的行为（置 0） | 跟着上面的结果 |

**歧义与我的取法（派单要求记录）**：派单同时要求"缺省保持今天的行为"与"把 env 去掉就是严格档腿"。今天的"行为"是**进程内**置 0 ⇒ 我取 **`auto` = 尊重调用方环境，环境没给则沿用今天的行为（宽松档）**；严格档腿显式给 `--tier strict`。
⇒ **后果（必须记住）**：`dotnet … --leg b`（一个旗标都不加）**仍然是宽松档腿**。

`--tier` 取值非法 ⇒ 立刻 `PCLINE_EXIT=NOINFO rc=2`（实测 `ctrl/tier-bogus/`，stdout 94 B）。
`--leg a|b` 语义**一字未改**；所有既有判据行的格式**一字未改**（§7 用 `diff` 证明）。

### 3.2 档位的权威判据 = **产品自己的开关**（不是 env 字符串）

```
TierSteer   : 产品侧 `HbTextFallback.Enabled` = true ⇒ **生效档 = 严格档**
```
读法 = IVT 直接读 `internal static bool WpfLinux.Shims.PresentationCore.HbTextFallback.Enabled`（`try/catch` ⇒ 读不到就 `rc=2 NOINFO`）。
两处**结构性自相矛盾**当场判 `NOINFO`（都实测过）：
- `--tier strict` 而 `Enabled == false` ⇒ `rc=2`（`ctrl/strict-masteroff/`，用 `WPF_LINUX_TEXTLINE=0` 触发）；
- `--tier lenient` 而 `Enabled == true` ⇒ `rc=2`。

### 3.3 层级来源 = **逐例归因**（这是"红能不能归因"的唯一机器证据）

每例**驱动前后**各取一次 `HbTextFallback.Handled` 与 `WpfLinuxLenientTextFallback.Diagnostics` 的 `relaxedHandled`：
- `Δ严格档 > 0` ⇒ 本例**严格档接手**；否则 `Δ宽松档 > 0` ⇒ **宽松档接手**；**两档都为 0 ⇒ `rc=2 NOINFO`**（"哪一层接手的不可判定" ≠ 通过）。
- 用**增量**而不是累计值判：宽松档腿里严格档被**调用** 496 次却 `Handled=0`（全 `bailNoSwitch`）⇒ 拿 `fallbackCalls>0` 当正控会**假阳**。
- 命中测量缓存（同输入键）的例**不再驱动** ⇒ 计数不增；故缓存条目**带上首趟的层级**（`CachedMeasure{Tier}`），归因沿用首趟。**这一条是必需的**：不带它，缓存命中的 18 例会变成"两档皆 0"的**假 NOINFO**。
- **非生效档接手**的例逐条点名（`PCLINE TIER …`）；本趟 **0 例**。
- 腿级新增行（**不覆盖**任何既有行）：
```
PCLINE LEG=B 层级来源 请求档=… 生效档=… ｜ 严格档接手=N 例、宽松档接手=M 例、缓存复用=K 例…、非生效档接手=…、两档皆0=…
PCLINE LEG=B 严格档计数 fallbackCalls=… fallbackHandled=… fallbackBailed=… bailNoSwitch=… bailRunType=… bailFont=… bailEmpty=… bailLong=… bailException=… minmaxCalls=… minmaxHandled=… minmaxBailed=… lastBail="…"
PCLINE LEG=B 宽松档计数 relaxedCalls=… relaxedHandled=…（既有「正控」行**格式逐字保留**）
PCLINE LEG=B 层级分桶 严格档接手(可比): … ｜ 宽松档接手(可比): …
```
**新增"层级分桶"的理由**：严格档腿里若某几例其实是宽松档接的，它们**不是**严格档的读数 ⇒ 分桶必须按接手档拆开，否则混读。

### 3.4 顺带更正的两处**臂内**陈述（与 §1.1 R2/R3 对应）

- 抬头诚实清单第 ① 条**原文**："严格档（shim `:4496`）… **不在本臂射程内**" ⇒ 改成"**W17A/W17B 的读数**对严格档零射程这句仍成立；**本臂现在有严格档腿**"。
- `LEG=B` 说明行原文："…⇒ 436 例**全部**落宽松档" ⇒ 改成"不在上游快路径被接走（宽松档腿 ⇒ 全部落宽松档；`--tier strict` 腿 ⇒ 先由严格档接手）"。
两处都只在**说明行**上，判据行一个字节未动（§7 的 `diff` 证明：`PCLINE CASE/NAMED/TWIN/合计/分桶/最大差/EXIT` **零差异**）。

---

## 4. 修前严格档读数（**本次交付的核心**）

### 4.1 精确命令 + rc

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"
dotnet build -m:1 -c Release build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj   # 0 error
cd build/MilBridge/tests/PcLineOracle/bin/Release
dotnet PresentationCore.Tests.dll --pc-lines-oracle \
  /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json \
  --leg b --tier strict --known-red $HOME/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt
```
**`rc = 1`**｜stdout `$HOME/wfp-runs/w19-laneW19B/strict-t1/stdout.txt`（**`c9cfde187ec7c173`**，160,372 B）｜stderr **0 字节**｜`pc` 跑前 = 跑后 = **`663114436443d2de`**（可归因）。
**复现趟** `strict-t2`：stdout **同一 sha16 `c9cfde187ec7c173`**（`cmp` 逐字节相同）。
**无缓存对照** `strict-nocache`（同一命令 + `--no-cache`，stdout `bf321613d406fe55`，160,371 B）：**除计数行外，1220 条 `PCLINE` 判据行逐字节相同**（差 1 行 = `fallbackCalls 482 → 508`，缓存只是少驱动了 18 例同输入的例）⇒ **缓存不改变读数**。

### 4.2 逐字判据行（`strict-t1`）

```
PCLINE LEG=B 合计 cases=436 判定过=41 判定红=247 不可比(缺字形)=148（其中非0缩进 40、零缩进 108） 其中 bidi 重排例=2
PCLINE LEG=B 非0缩进: 红=184 绿=0 /224；零缩进: 红=63 绿=41 /212；PI≠0: 红=88 /112
PCLINE LEG=B 层级来源 请求档=strict 生效档=严格档(HbTextFallback) ｜ 严格档接手=270 例、宽松档接手=0 例、缓存复用=18 例（层级沿用同输入键的首趟）、非生效档接手=0 例、两档皆0=0 例
PCLINE LEG=B 严格档计数 fallbackCalls=482 fallbackHandled=482 fallbackBailed=0 bailNoSwitch=0 bailRunType=0 bailFont=0 bailEmpty=0 bailLong=0 bailException=0 minmaxCalls=0 minmaxHandled=0 minmaxBailed=0 lastBail="-"（本腿 fallbackCalls 增量=482、fallbackHandled 增量=482）
PCLINE LEG=B 宽松档计数 relaxedCalls=0 relaxedHandled=0 relaxedFailed=0 relaxedSkippedRuns=0 relaxedBlankParagraphs=0 lastSkip="-" lastSkippedRange="-" lastFail="-"（本腿 relaxedCalls 增量=0）
PCLINE LEG=B 层级分桶 严格档接手(可比): 非0缩进 红=184 绿=0；零缩进 红=63 绿=41；PI≠0 红=88 /88 ｜ 宽松档接手(可比): 非0缩进 红=0 绿=0；零缩进 红=0 绿=0；PI≠0 红=0 /0
PCLINE 孪生 有 @i0 孪生的例=72（其中 tab0 臂=恒等式不适用 36）（无孪生=216）；孪生恒等式违反=0；孪生最大差=0.0020 @B-indent/notab-control@w40@LTR@i24@default 行#0 width Δ=0.001980
PCLINE 最大差=178.6467 @B-indent/lead-tab-b-t-c@w220@LTR@i0@tab0 行#0 width
PCLINE 登记表=/home/links-dev/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt ⇒ 已登记 136 条
PCLINE 未登记失败=111
PCLINE_EXIT rc=1（未登记失败 111 / 红 247 / 绿 41 / 不可比 148）
```

### 4.3 两个判别例（**按名**逐字）

```
---- 判别例 B-indent/lead-tab-a@w140@LTR@i24@default  文本=[\ta] Indent=24 ParagraphIndent=0 我方行数=1 真值行数=1
PCLINE NAMED   B-indent/lead-tab-a@w140@LTR@i24@default 行#0 width 我方=109.347656 真值=109.346667 Δ=0.000989  尾部空白 我方=1 真值=1  换行长 我方=1 真值=1  lineText 我方=[\ta] 真值=[\ta]
PCLINE NAMED   B-indent/lead-tab-a@w140@LTR@i24@default 行#0 i=0 char=[	] xFromLeft 我方=0.000000 真值=24.000000 Δ=-24.000000
PCLINE NAMED   B-indent/lead-tab-a@w140@LTR@i24@default 行#0 i=1 char=[a] xFromLeft 我方=96.000000 真值=96.000000 Δ=0.000000

---- 判别例 B-indent/notab-control@w80@LTR@i24@default  文本=[ab] Indent=24 ParagraphIndent=0 我方行数=1 真值行数=1
PCLINE NAMED   B-indent/notab-control@w80@LTR@i24@default 行#0 width 我方=26.695312 真值=50.693333 Δ=-23.998021  尾部空白 我方=1 真值=1  换行长 我方=1 真值=1  lineText 我方=[ab] 真值=[ab]
PCLINE NAMED   B-indent/notab-control@w80@LTR@i24@default 行#0 i=0 char=[a] xFromLeft 我方=0.000000 真值=24.000000 Δ=-24.000000
PCLINE NAMED   B-indent/notab-control@w80@LTR@i24@default 行#0 i=1 char=[b] xFromLeft 我方=13.347656 真值=37.346667 Δ=-23.999011
```

**红形与预测（"`Indent`/`PI` 被丢 ⇒ 网格锚与内容起点都少 indent"）逐条对照**：

| 预测 | 实测（严格档） | 判决 |
|---|---|---|
| 判别例 A：宽**已经对**、**只有网格锚**差 −24 | 宽 `109.347656`（Δ=+0.000989，绿）｜tab x `0.000000`（Δ=**−24.000000**，红）｜`a` x `96.000000`（Δ=0，绿） | **成立**（红**唯一地**钉在网格锚上） |
| 判别例 B：宽与两个 x 都差 −24 | 宽 Δ=**−23.998021**；x(a) Δ=**−24.000000**；x(b) Δ=**−23.999011** | **成立** |
| 非 0 缩进桶整片红 | `红=184 绿=0 /224`（可比 184/184 全红） | **成立** |
| `PI≠0` 桶整片红 | 分桶行 `PI≠0 红=88 /88`（可比全红；既有汇总行的 `/112` 含 24 条缺字形跳过） | **成立** |

**一条比上面更强的交叉证据**：把本趟 `strict-t1` 与 **W17A 的修前宽松档读**（`$HOME/wfp-runs/w17-laneW17A/run-prefix-legB/stdout.txt`，sha16 `5d0b58c0d2ef5c57`）逐例比：

```bash
diff <(grep -E "PCLINE NAMED   B-indent/(lead-tab-a@w140|notab-control@w80)" <W17A stdout>) \
     <(grep -E "PCLINE NAMED   B-indent/(lead-tab-a@w140|notab-control@w80)" strict-t1/stdout.txt)
# ⇒ 无输出：NAMED_GEOMETRY_BYTE_IDENTICAL
```
- **两个判别例的几何行逐字节相同** ⇒ 严格档"整条丢掉 indent"与宽松档"修前那条"在这两个例上给出**同一个数**；
- 288 条可比例里**只有 19 条判定不同**（全部是**零缩进**例：W17A 绿 → 本趟红），`非0缩进红` **两边都是 184**。

**⇒ "严格档修前是红的"这件事同时有三重证据**：臂的总数、判别例的数、以及与上一代修前读数的逐例一致性。

### 4.4 未登记红的**构成**（不是一句"111 条红"）

| 桶 | 已登记 `KNOWN-RED` | **未登记** | 未登记的共同处 |
|---|---|---|---|
| 非 0 缩进 | 92（全是 `@tab0` 族） | **92** | 全部 `@default`：`B-indent` 36 / `B-indent-extra` 36 / `D-paraindent` 20 |
| 零缩进 | 44（全是 `@tab0` 族） | **19** | 全部 `@default`：`A-anchor` 4 / `B-indent` 15 |
| 合计 | **136** | **111** | 247 = 136 + 111 |

未登记红的**首个失配词**分类：`TAB网格锚` 36 ｜ `width` 31 ｜ `xFromLeft` 19 ｜ `取不到字符边界` **19** ｜ `行数` 6。
**量级自查**（92 条非 0 缩进未登记例）：**70 条的首个失配量逐位 = `−(Indent+ParagraphIndent)`**（58×`−24.0`、10×`−48.0`、2×`−72.0`）；6 条是"行数 期望=2/3 实得=1"（断点划分被改写，正是丢 indent 的次生形态）；其余 16 条是同一机制经**停靠位/断点**的次生形态（如 `D-paraindent/lead-tab-a@w100@i0p24` 真值宽 76 = 100−24，我方 96）。
**反向自查（重要）**：严格档**没有**变成 ×300 那种坏形态 —— 全腿 `最大差=178.6467`（一个停靠位量），**不是** `7200/14400` 量级 ⇒ 严格档修前是"**整条丢**"，不是"**传了理想整数**"（后者是宽松档修前的形态）。

---

## 5. 层级来源证据（**"红"能不能归因**）

### 5.1 严格档腿：接手来自**严格档**

```
TierSteer   : 产品侧 `HbTextFallback.Enabled` = true ⇒ **生效档 = 严格档**
PCLINE LEG=B 层级来源 … 严格档接手=270 例、宽松档接手=0 例、缓存复用=18 例…、非生效档接手=0 例、两档皆0=0 例
PCLINE LEG=B 严格档计数 fallbackCalls=482 fallbackHandled=482 fallbackBailed=0 … lastBail="-"
PCLINE LEG=B 宽松档计数 relaxedCalls=0 relaxedHandled=0 …
```
- **判据成立**：可比 288 例 = 直接驱动 270 + 缓存复用 18，**全部由严格档接手**；宽松档 `relaxedCalls=0`（**一次都没被走到**）。
- `fallbackBailed=0 / lastBail="-"` ⇒ 严格档**没有**因为"接不了"而把任何一例让给下面的层（预登记担心的"红可能来自别的层"在本趟**不成立**）。
- 宽松档腿（同一臂、`--tier lenient`）是**镜像**：`严格档接手=0、宽松档接手=270、缓存复用=18`，而严格档 `fallbackCalls=496 / fallbackHandled=0 / bailNoSwitch=496`、`lastBail="回退开关关（WPF_LINUX_TEXTLINE 或 WPF_LINUX_TEXTLINE_FALLBACK=0）"` ⇒ 两条腿的**接管归属互为反面**，这正是"层级来源"这一行的用处。

### 5.2 `--tier auto` 的三态（缺省行为**未变**）

| 命令 | 生效档 | rc | 证据 |
|---|---|---|---|
| `--leg b`（无旗标、无 env） | **宽松档** | 0 | `ctrl/auto-unset/`（`fd5a875b22191323`） |
| `env WPF_LINUX_TEXTLINE_FALLBACK=0` + `--leg b` | 宽松档 | 0 | `ctrl/auto-env0/`（`4788c1b4dc3f5d79`） |
| `env WPF_LINUX_TEXTLINE_FALLBACK=1` + `--leg b` | **严格档** | 1 | `ctrl/auto-env1/`（`a630c95f1c154e81`） |

### 5.3 `NOINFO` 两极（**"没跑"绝不许读成绿**）

| 场景 | 期望 | 实测 |
|---|---|---|
| `--tier bogus` | `NOINFO rc=2` | **rc=2**，`原因=--tier 取值非法：bogus（只接受 auto|strict|lenient）`（94 B） |
| `--tier strict --case ZZZ-no-such-case`（**空集**） | `NOINFO rc=2` | **rc=2**，`原因=--tier strict 生效，但**严格档一例都没接住**（严格档接手=0 例）…⇒ 这条路径对本臂**不可观测**，不是绿` |
| `--tier strict` + `WPF_LINUX_TEXTLINE=0`（总开关关） | `NOINFO rc=2` | **rc=2**，`原因=要严格档腿，但产品侧开关读出 false ⇒ 转向未生效（不许报绿）` |
| **"某例两档 `Handled` 增量都为 0"** | `NOINFO rc=2` | ⚠️ **未实测**（见 §9 第 3 条）：本语料下严格档 `Bailed=0`、宽松档又无开关可关 ⇒ 无可达路径。它由**空集那条**（同一条判据语句）间接覆盖 |

### 5.4 第二族红：**同例跨档对照**（这是"红不止一族"的证据）

```bash
--case "A-anchor/lat-a-t-b@w96@LTR@i0@default"
```
| 趟 | 档 | CASE 行 | rc |
|---|---|---|---|
| `ctrl/same-case-strict/` | 严格档 | `… I=0 PI=0 非0缩进=0 结构=PASS 位置=FAIL :: 行#1 i=0 取不到字符边界` | 1 |
| `ctrl/same-case-strict-nc/`（+`--no-cache`） | 严格档 | **同一行、stdout sha 同一 `98e16b47a5c32d46`** | 1 |
| `ctrl/same-case-lenient/` | 宽松档 | `… 结构=PASS 位置=PASS` | 0 |

⇒ 该例 `Indent=PI=0`（**与 B 毫无关系**），却在严格档下红、宽松档下绿，且**与缓存无关**（两条 stdout 逐字节相同）。
**它是什么，本车道只能给到"读数 + 计数 + 最小复现"**：19 条同族例（`A-anchor` 4 / `B-indent` 15），**机制未归因**（见 §9 第 2 条）。

---

## 6. **post-fix 期望（记录在册，后续复跑照此判）**

**同一命令**（§4.1 那条，**一个字都不改**；`pc` 须是**修后重建**的产物）：
```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux && export PATH="$HOME/.dotnet:$PATH"
cd build/MilBridge/tests/PcLineOracle/bin/Release
dotnet PresentationCore.Tests.dll --pc-lines-oracle \
  /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json \
  --leg b --tier strict --known-red $HOME/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt
```

| # | 量 | 修前（本次实测） | **修后必须** | 强度 |
|---|---|---|---|---|
| E1 | **非 0 缩进的未登记失败** | 92（+19 零缩进） | **`非0缩进` 桶的未登记失败 = 0**；该桶 `红=92 绿=92`（92 红**全部**是已登记 `@tab0` 族） | **判据（B 的落点）** |
| E2 | 判别例 `lead-tab-a@w140@i24@default` | 宽 `109.347656`(绿) / tab x `0.000000` / `a` x `96.000000` | **tab x ≈ `24.000000`（Δ=0.000000）**；宽 Δ ≤0.002；`a` x = `96.000000` ⇒ **三项全绿** | **逐位** |
| E3 | 判别例 `notab-control@w80@i24@default` | 宽 `26.695312` / x=[`0.000000`,`13.347656`] | 宽 ≈`50.695312`（Δ=+0.001979）；x(a) ≈`24.000000`；x(b) ≈`37.347656`（**Δ ≤0.002，不是 0**：字体量化） | **逐位** |
| E4 | **零缩进同层对照（射程外逐位不动）** | `红=63 绿=41 /212` | **仍是 `红=63 绿=41`（逐位不动）** —— 这 82 条里 `Indent=PI=0`，B 不许碰它们；其中 19 条未登记红**预期仍在** | 射程外不动 |
| E5 | **孪生统计必须**翻面 | `违反=0；孪生最大差=0.0020` | **`违反 ≈36`**（72 个孪生里 36 个是 `tab0` 臂 ⇒ 恒等式**不适用**，故形式上界 = 36）、**孪生最大差 ≈ `24.0019`**：修好后我方 `@i24` 读数**必须不再等于** `@i0` 孪生真值（差值 = `Indent`）。**若修后孪生最大差仍停在 0.002 ⇒ indent 仍在被丢** | **判据（本波新增）** |
| E6 | 层级来源 | 严格档接手=270 / 宽松档=0 | 严格档接手 ≈270、宽松档 = 0（**层级没变**；若宽松档接手 >0 ⇒ 严格档开始 bail，先查这一条再读红绿） | 归因前提 |
| E7 | 整腿 `rc` | `1`（未登记 111） | **`rc=1` 是预期值，不是失败**：19 条零缩进未登记红（§5.4）与 B 无关 ⇒ 除非先给严格档腿另立登记表/限制表，`未登记失败 ≥19` | ⚠️ **不许**拿 rc 判 B |
| E8 | `PCLINE 最大差` | `178.6467`（停靠位量） | 应离开 `14400/7200` 量级；**若出现 Δ≈`+7200/14400`** ⇒ 用的是 `settings.Pap.*`（理想整数 ×300）⇒ **坏修法指纹**，停 | 指纹 |

**读法（三句话）**：
1. **B 的判据 = E1 + E2 + E3**（按桶、按名、按量），**不是**整腿 rc。
2. **E4 是"射程外逐位不动"**：零缩进桶若动了 ⇒ 越界，停。
3. **E5 是本次新加的、最锐的一条**：孪生恒等式 `我方 == @i0 孪生` 是**缺陷态的签名**（修前 `违反=0`）；修好后它必须破。`W17A-report.md` 的 E7 曾把它当"与修法无关的规律"，**被 `#17` 的落地推翻过一次**（`docs/CURRENT-STATE.md` 的 `#17` 段："E7 被推翻（它把缺陷态当成了规律）"）——本车道在此给出**第二个实例与机器读数**。

---

## 7. 宽松档读数仍可复现（`#17` P2 修后基线）

```bash
dotnet PresentationCore.Tests.dll --pc-lines-oracle <corpus> --leg b --tier lenient --known-red $HOME/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt
```
- `rc = 0`｜stdout **`a4cd321f5699cefc`**（124,388 B）｜stderr 0 B｜`pc` 跑前=跑后=`663114436443d2de`；复现趟 `lenient-t2` **逐字节相同**（同一 sha16；**该趟期间 `shim` 又被改了一次**，读数不变 ⇒ 臂量的是**产物**不是源，见 §8.3）。
- 与 `W17B-report.md` §5.1 的基线 **`07615909a1ffaa8b`（122,518 B）** 的 `diff`：**只有 8 行被替换、18 行是新增**，且**全部**落在
  ① 抬头/tier 选择行、② `LEG=B` 说明行、③ **新增的 4 行层级行**、④ 两条汇总文字行；
  **`PCLINE CASE` / `PCLINE NAMED` / `PCLINE TWIN` / `PCLINE 合计` / `PCLINE 分桶` / `PCLINE 最大差` / `PCLINE_EXIT` 零差异**。
- ⇒ **判据基线未变**（`判定过=172 / 红=116 / 不可比=148`、`非0缩进 红=72 绿=112`、`零缩进 红=44 绿=60`、`PI≠0 红=35 /112`、`rc=0`，与 W17B 逐位相同）；
  旧基线 sha 之所以失效，**只**因为臂多了层级行 ⇒ **新参考 = `a4cd321f5699cefc`（宽松档腿）；严格档腿参考 = `c9cfde187ec7c173`**。**一个既有判据都没动**（这是本条的目的）。

---

## 8. 读数表

### 8.1 每一趟的 `pc` sha（并发规则的硬要求）+ 环境

**权威 `pc`（被测件）= `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`，`663114436443d2de`，4,196,864 B，mtime `2026-09-16 15:09:34.759810754 +0800`（`#18` 冻结值）。**

| 趟 | 时刻（local） | 档 | rc | stdout sha16 / 字节 | `pc` 前→后 | loadavg 前→后 | MemAvail 前→后 (kB) |
|---|---|---|---|---|---|---|---|
| `strict-t1`（**交付读数**） | 15:26:21 → 15:27:47 | strict | **1** | **`c9cfde187ec7c173`** / 160,372 | `663114436443d2de` → `663114436443d2de` ✅ | 3.28 → 6.74 | 3,052,684 → 2,506,468 |
| `lenient-t1` | 15:27:47 → 15:29:46 | lenient | **0** | **`a4cd321f5699cefc`** / 124,388 | 同上 ✅ | 6.74 → 3.74 | 2,506,220 → 2,722,332 |
| `strict-t2`（复现） | 15:29:46 → 15:31:03 | strict | 1 | **`c9cfde187ec7c173`**（== t1） | 同上 ✅ | 3.74 → 7.01 | 2,722,408 → 2,626,920 |
| `lenient-t2`（复现） | 15:31:03 → 15:33:03 | lenient | 0 | **`a4cd321f5699cefc`**（== t1） | 同上 ✅ | 7.01 → 12.24 | 2,626,616 → 2,639,268 |
| `strict-nocache` | 15:35 → 15:37 | strict+`--no-cache` | 1 | `bf321613d406fe55` / 160,371 | 同上 ✅ | 1.79 → （未记） | （未记） |

**全部 14 趟（5 趟主读数 + 9 趟控制）`pc` 全部跑前=跑后** ⇒ 每一次读数都可归因。`stderr` 全趟 **0 字节**。

### 8.2 控制趟

| 目录（`$HOME/wfp-runs/w19-laneW19B/ctrl/`） | env / argv | rc | stdout sha16 |
|---|---|---|---|
| `tier-bogus` | `--tier bogus` | 2 | `18d1e6a4d5850487` |
| `strict-empty-set` | `--tier strict --case ZZZ-no-such-case` | 2 | `7217ac56fdea74d2` |
| `strict-masteroff` | `WPF_LINUX_TEXTLINE=0 --tier strict` | 2 | `e8e09bddc11cd24e` |
| `auto-unset` | （无 env、无旗标） | 0 | `fd5a875b22191323` |
| `auto-env0` | env=0 | 0 | `4788c1b4dc3f5d79` |
| `auto-env1` | env=1 | 1 | `a630c95f1c154e81` |
| `same-case-strict` | `--tier strict --case A-anchor/lat-a-t-b@w96@LTR@i0@default` | 1 | `98e16b47a5c32d46` |
| `same-case-strict-nc` | 同上 + `--no-cache` | 1 | `98e16b47a5c32d46`（**逐字节相同**） |
| `same-case-lenient` | `--tier lenient` + 同例 | 0 | **`ee60285bf9c86274`** |

### 8.3 件 sha（**本车道作业期间树在动，必须点名**）

| 件 | 值 | 字节 | mtime |
|---|---|---|---|
| **被测件 `pc`**（全趟不变） | **`663114436443d2de`** | 4,196,864 | 2026-09-16 15:09:34 |
| **`pc` 里**编进去的 shim（等号读者读出） | **`bc04c05ab6d8d82a`**（full64 `bc04c05ab6d8d82ae337481787ef1016f066e79cb6e33afb5dce386b7230e4fd`） | — | — |
| `build/shims/PresentationCore.HbTextLine.cs`（**别人在改，我没动**） | 15:22 `bc04c05ab6d8d82a`(275,765) → 15:23 `cd9e8f2a4dfb254a`(278,692) → 15:30 **`fe1b7ed8fa3ed231`**(278,692) | — | 15:30:15 |
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（W19A 写的，**我没动**） | 15:22 `56a5b4a5be1c6bcc` → 15:31 `799e0366b312ec65` | 53,783 → 55,223 | 15:31:51 |
| 语料 `tests/…/tab-anchor-oracle.json` | `a31a813114256faf` | 1,251,441 | 2026-09-14 19:33:26 |
| 登记表（W17B 的 136 条） | `89324f1f643167e5` | 17,501 | 2026-09-16 12:00 |
| 臂源 `Program.cs` | `544aab374ee8e1a6` → **`a46e5e046583f69a`** | 57,572 → 72,948 | 15:26:10 |
| 臂产物 `PresentationCore.Tests.dll` | `3a474e675b24fdf4` → **`8f6771a9a2ffad20`** | 38,912 → 45,568 | 15:26:13 |
| `build/keys/WcpPublicKey.snk`（IVT 借用） | `6fe03f0bbe162b4b` | 160 | 2026-09-10 |

**"修前"这件事**是**机器证明**的，不是断言：`pc` 是 15:09 建的、`shim` 的 `#19` 两件 15:23/15:24 才落；而**等号读者**（W17C 的 `ShimShaReader`）从**产物元数据**里读出 `product_sha256 = bc04c05ab6d8d82a…`，与 `#18` 冻结表头的 `hbtextline bc04c05ab6d8d82a` 逐位相同：
```bash
dotnet $HOME/w17c-build/reader-bin/Debug/net10.0/ShimShaReader.dll --root /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# SHIM_SHA=yes reason=content-compare artifact=663114436443d2de … product_sha16=bc04c05ab6d8d82a tree_sha16=fe1b7ed8fa3ed231 … cmp=full64   rc=1
```
⇒ **我量的是"修前 shim（`bc04c05ab6d8d82a`）编出来的产物"**；树上的 shim 在我作业期间被改了两次（`cd9e8f2a4dfb254a`、`fe1b7ed8fa3ed231`），**这不影响我的读数**（臂量产物），而且 `lenient-t2` 恰好跨过一次树变更仍逐字节复现 —— 这是"臂的读数**不依赖树源**"的一条顺带实测。

### 8.4 本车道的**越界自查**

`find build docs src samples tests -newermt "2026-09-16 15:22:30" -type f`（去掉 `bin/obj`）列出 **9 个文件**：属于**我写域的只有 2 个** —— `build/MilBridge/tests/PcLineOracle/Program.cs` 与本报告；其余 7 个是**别的车道**（`build/shims/PresentationCore.HbTextLine.cs`、`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`、`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`、`build/MilBridge/W19A-report.md`、`docs/CURRENT-STATE.md`、`docs/WAVE19-PREREGISTRATION.md`、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）。
禁改件逐位未变：`known-red.json f9843bde351029dc`、`tline-gate.sh b37a5c9f55ae71a4`、`verify-all.sh a68823631e8f8919`、`CoverageProbe/Program.cs a8727a5bed6bf049`、`MinMaxProbe/Program.cs cfcf464457163280`。
**纪律 11**：本车道**未用** `pkill -f` / `pgrep -f`；全程无止损需求。

---

## 9. 测不出来的、以及为什么（**不许读成绿**）

1. **严格档修后的数值**：`pc` 未重建（另属主控/波的第 1 步）⇒ 本车道只给**期望**（§6），给不了读数。**未证明**。
2. **§5.4 那 19 条零缩进红的机制**：**只到"读数 + 同例跨档对照 + 最小复现"**（`--case … --tier strict/lenient`、`--no-cache` 逐字节相同）。它**不是** B、**不是我这条臂的缓存**、**不是覆盖闸**；但"严格档与宽松档在这 19 例上到底哪一步分岔"**未归因**（未证明）。这是**留给 `#19` 波主控的一条新登记**。
3. **"某例两档 `Handled` 增量都为 0"的 `NOINFO` 分支未实测**：本语料下严格档 `Bailed=0`、宽松档又**没有开关**可关（`TextFormatterImp.Linux.cs` 里只有 `WPF_LINUX_TEXTLINE_DIAG`，无 enable 门）⇒ 无可达路径。它由**空集那条**（同一条判据语句）间接覆盖。**不写成"已验证"**。
4. **"严格档那 92 条未登记红修后是否全绿"**：这是**预测**（§6 E1），依据 = 它们的首个失配量 70/92 逐位 `−(I+PI)` + 6 条行数 + 16 条次生；**逐条未证明**。
5. **`@…@tab0` 臂（语料 218 例）**：`DefaultIncrementalTab` 在严格档的调用点（`:565`）**也没有形参** ⇒ 修后**仍红**（其中 136 条已登记：92 条非 0 缩进 + 44 条零缩进）——这是**登记在册的产品缺口 + 本臂表达限制**，**不是 B 的红**，也**不是 B 能修的**。
6. **`PI≠0` 的逐行精算值**：`Indent+PI` 会改写断点划分 ⇒ 本臂只**量**不预言（纪律 22）；本报告**没有编造任何逐行真值**。
7. **应用级（`WpfTextDemo` 默认档真的走哪一层）**：需要跑应用门禁，本车道只跑探针 ⇒ **未测**。这条恰恰是 §0.1 B 的**动机**（产品默认先走严格档），建议波内由应用门禁那趟补读。
8. **`--leg a` 的严格档腿**：未跑（腿 A 的零缩进半边会被上游 `SimpleTextLine` 快路径接走 ⇒ 不是同层对照）⇒ 严格档腿一律用 `--leg b`。

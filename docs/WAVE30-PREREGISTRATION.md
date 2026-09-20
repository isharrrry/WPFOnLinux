# 波 `#30` 预登记（**落地前先登记；红了只许加严，不许放松**）

> 生成：主控，2026-09-17 22:5x，基于**当前冻结基线 `#29`**（权威 = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`；⚠️ 按纪律 53 **本文件不重述整份 sha 的值**）。
> 承接：`docs/WAVE29-PREREGISTRATION.md` §11 的候选表。

## §1 内容（六条车道；**写域互不重叠**是硬约束）

| 车道 | 件 | 需 `dotnet`？ | **独占写域** |
|---|---|---|---|
| **W30A** | **`D-G27` ＋ `D-G9` 合案落地**（给**三个自指值**一个**外挂**读者：两颗列级下限 ＋ `generation.arm_logs`）。**草稿已备**（W29D：`$HOME/w29d/column-floor-check.sh 95e1c5433c9716f0` ＋ `column-floor.baseline-lines.txt ed2b97a5d3b29b60` ＋ `verify-all-wiring.md 289f23fb1427e68a`；形状 = **A(冻结块 `# COLUMN-FLOOR` 行) ＋ B(门禁自报行核对) ＋ C(语料复算)**，**只有 C 回答"这个数该是多少"**）。⚠️ **不许写 `known-red.json`**（本项不引入新声明；那个"另一处"**不许**是同一份 `known-red.json`） | 否 | **新建** `build/MilBridge/tools/column-floor-check.sh` ＋ `$HOME/w30a/` |
| **W30B** | **`D-G26` 落地**：探针**构建时**把 `Program.cs` 的 sha 嵌进 `AssemblyMetadata` ⇒ 在 `RunTabLinesOracle` 入口打 `TAB_LINES_PROBE sha256=<64>` ⇒ 门禁新增 `probe` 段（"日志自报 == 现场"）。**⚠️ 落地必须重取三支 `tab-*` 臂**（`tab-zero`/`tab-anchor`/`tab-rtl`；`tline`/`textlineproto` 不编探针 ⇒ 不用）。**走纪律 59 的 11 步时序**（换 `OUT` → `cp -p` 归档 → 记 `nlink`/mtime → 建 → 跑 → **验自报行存在（无则停）** → `ln -f` → 复跑门禁 → `arm-log-sha-check` → 推 `generation.arm_logs` → 归档）。草稿：`$HOME/w29e/probe-identity.diff 198978626ac63c5d`、`gate-probe-arm.diff 9dd1fd1b7c23f999` | **是**（1 次 build ＋ 3 次探针运行） | **`build/MilBridge/tools/tline-gate.sh`** ＋ **`build/MilBridge/known-red.json`** ＋ 探针侧那两件 ＋ `build/MilBridge/arm-logs/*` |
| **W30C** | **三条小项**：① **`D-G33`**（`no-in-repo-obj` 见证有"删 `obj/` 即变绿"的**假绿解** ⇒ 换一个**不依赖构建产物是否存在**的见证）；② **`D-G34`**（`close-wave.sh:134` 的 `pgrep -af` **自匹配** ⇒ 判据要排除**调用者自己的命令行**）；③ **`D-G30` 的同族第三格**：`tab-zero`/`tab-rtl` 的 `OVERFLOWED` 对账行仍无读者 + `判定行` **上向**谎报 —— **只出方案**（`tline-gate.sh` 是 W30B 的写域） | 否 | **`build/MilBridge/tools/build-hygiene-import-check.sh`** ＋ **`build/close-wave.sh`** ＋ `$HOME/w30c/` |
| **W30D** | **`D-T5-R` 接线准备**：① 修 W29C 查出的两处（`:499` 的 `*LoCreateContext*` **死归因分支**、`:316` 的"恰 4 格红"**字面**）；② 按**现件 18 步**重锚（新步 `[13]`、`18 → 19`；四处同趟改：`STEPS-DECL` ＋ `STEP-NAMES` ＋ 口径句 ＋ 头注释机器读句）。**只交付，接线由主控** | 否 | `build/MilBridge/tools/hidden-only-step.sh` ＋ `$HOME/w30d/` |
| **W30E** | **产品侧只读侦察：`M_modifier`（`TextModifier` 未实现）** —— 给出"用到 `TextModifier` 的文本走不到预期路径"的**根因 ＋ 最小修法 ＋ 可复算判据**，并回答"它与现场那 4 条 `M_modifier_*` Extent 余差是什么关系" | 否 | 仅 `$HOME/w30e/` |
| **W30F** | **主控自己的仪器清账**：扫 `$HOME/w21-verify/*.py`（`w2x/w3x-freeze.py`、`*-fill.py`、`*-cs.py`、`*-handoff.py`）里**复制了仓库脚本函数体**或**写死世代/步数**的地方（`#29` 实测：`w29-fill.py` 仍带 `#27` 时代的 `fp_inputs()` 硬编码拷贝 ⇒ 打出过**老定义**的值），逐个修成 `source` 真函数 / 现算 | 否 | `$HOME/w21-verify/*.py` ＋ `$HOME/w30f/` |

**主控在波尾做**：① 判定并接线 W30A/C/D 的交付；② `close-wave.sh` → 五臂 → **零构建窗口** → `verify-all` 两趟 → 应用门禁 ×2 → 重冻 `#30` → 文档。

## §2 位移预测（**表外位移 ⇒ 停**）

| 位/量 | 预期 |
|---|---|
| 九位 | **全部不动**（`pf` 预计波尾 `close-wave` 时变 —— 照惯例） |
| **`generation.arm_logs`** | **必变**（W30B 重取三支 `tab-*` 臂 ⇒ 三支日志的 sha 全变；⚠️ **这是本波唯一预期的"派生件位移"，必须单列并说明成因**） |
| `GEN_KEYS` 三项 | **不动**（不动 `run.sh`/`Parity.cs`/shim） |
| `inputs_fp` | **不动**（⚠️ 但 `arm-logs` **不在**覆盖面里 —— 纪律 64） |
| `known-red.json` | **必变**（W30B 加 `probes` 段 ＋ 改三支 `arm_logs`） |
| `tline-gate.sh` | **必变**（W30B 加 `probe` 段） |
| `close-wave.sh` | **必变**（W30C 修 `pgrep` 自匹配） |
| `build-hygiene-import-check.sh` ＋ roster | **必变**（W30C 换见证） |

## §3 W30B 的判据（**本波唯一"判据面扩张 ＋ 派生件重取"**）

1. **正极性**：三支新臂日志**各有** `TAB_LINES_PROBE sha256=<64>` 且**逐位等于现场 `CoverageProbe/Program.cs`**；门禁 `GATE_PROBE=PASS`；`TLINE_GATE=PASS` 且既有字段**逐项不变**。
2. **反极性 ≥5 档**：一位翻转 ⇒ `FAIL`；前缀 ＋ 48 个 0 ⇒ `FAIL`；另一合法 64 位 ⇒ `FAIL`；现场改一字节 ⇒ `FAIL`；双行冲突 ⇒ `FAIL`；**无自报行 ⇒ `NOINFO`**（老日志不许读成绿）；**探针源缺件 ⇒ `NOINFO`**；只声明一支 ⇒ **不牵连**。
3. **零位移**：用**未打补丁的旧门禁**读带新行的日志 ⇒ 既有四行机读行**逐字不变**（W29E 已实测）。
4. **纪律 59 全流程留档**：`OUT` 换过、旧件 `cp -p` 归档、`nlink` 与 mtime 记录、**验自报行存在后才 `ln -f`**；`arm-log-sha-check.sh` 复跑 `PASS`。
5. ⚠️ **不许**动臂日志之外的任何 `arm-logs` 文件；**不许**改 `verify-all.sh`（主控写域）。

## §4 W30A/C/D/E/F 的判据（要点）

- **W30A**：`--selftest` **必须在落地位置对现件跑绿**（纪律 63／`D-G29`；W29D 自测的**正极性档用的是"现场基线＋只插 3 行"的忠实复制品** ⇒ 那一格必须由本车道在**真落地位置**补跑）；反极性 ≥5 必红 ＋ ≥4 必 `NOINFO`；**三处同改 ⇒ 期望 PASS** 的边界要**固化成期望值并写明理由**。
- **W30C**：① 新见证要**逐条给"为什么它不依赖构建产物"**，并**实测**"删 `obj/` ⇒ 不再变绿"；② `pgrep` 修法要**实测**"调用者命令行含 `WpfTextDemo` 时不再假停"；③ 第三格**只出方案**，含反极性设计与成本。
- **W30D**：两处修复各给**成对读数**；重锚要给**正文字符串锚**（不给行号）；`--selftest` 就地 16/16 以上。
- **W30E**：根因要**给 `file:line` ＋ 逐字代码**；最小修法要**说明是否动 `pc`**（动 `pc` ⇒ 世代成本）。
- **W30F**：逐个文件给"改了哪一处、为什么、修前/修后行为对比"，并**自证"修后打的数与真函数逐位相同"**。

## §5 停条件（**触发即停、如实上报**）

1. 九位里任何一位变了（`pf` 除外）⇒ 停。
2. `inputs_fp` 变了 ⇒ 停。
3. `build/shims/PresentationCore.HbTextLine.cs` 被碰 ⇒ 停。
4. `GEN_KEYS` 三项变了 ⇒ 停。
5. **重取后的臂日志缺 `TAB_LINES_PROBE` 行 ⇒ 停**（不许 `ln -f` 覆盖旧件）。
6. 任何车道改了不属于自己写域的文件 ⇒ 停、回退、登记。
7. **任何写操作落在硬链接沙箱路径上** ⇒ **立即停并报**（纪律 60）。
8. **`--selftest` 只在旧件沙箱里绿** ⇒ 视为**未达成**（纪律 63／`D-G29`）。
9. **任何车道落地前必须先把 pre-landing 备份放到 `$HOME/<lane>-run/backup/` 并在报告里给 before sha16**（纪律 **65**，`#29` 险中一次）。
10. ⚠️ **主控自己的命令行文本不许含 `WpfTextDemo`/`WpfFeatureProbe`/`run-wpf*`字样**（`D-G34`：`close-wave.sh:134` 的 `pgrep -af` **会匹配到承载它的 shell 自己**）⇒ 一律用**薄包装脚本**调用收官链。

## §6 资源与内存纪律

- **并行车道上限 = 7**（纪律 57）。本波**只有 W30B 一个构建者** ⇒ 它独占；其余纯 bash。
- ⚠️ **`#29` 实测一次 `swapfree=0MB`**（21:50:08，而同一笔 `avail=4050MB` **看着健康**）⇒ **采样器阈值必须同时看 `swapfree`**；`avail` 单独会漏。
- 零 `dotnet` 车道**不许跑会自行构建的步骤脚本**（`frame-step.sh`/`verify-all.sh` 第 `[1]` 步/`pc-line-step.sh`）；**`tline-gate.sh` 例外（纯读者）**。
- 不许 `pkill`；不许用 `pgrep -f`/`ps|grep` **单独**下结论（自匹配 —— 本波 `D-G34` 就是它的新现场）；**定人不能用 `PPID`**。

## §7 收官清单（顺序不可颠倒 —— 纪律 46；收官时再加勾）

- [ ] W30A：`D-G27`＋`D-G9` 合案（外挂读者 ＋ 语料复算）
- [ ] W30B：`D-G26` 落地（探针自报 sha ＋ 门禁 `probe` 段 ＋ **重取三支臂** ＋ 推 `arm_logs`）
- [ ] W30C：`D-G33`（换见证）＋ `D-G34`（`pgrep` 自匹配）＋ `D-G30` 第三格方案
- [ ] W30D：`D-T5-R` 接线准备（修两处 ＋ 按 18 步重锚；只交付）
- [ ] W30E：`M_modifier` 根因 ＋ 最小修法（只读）
- [ ] W30F：主控仪器清账（`$HOME/w21-verify/*.py` 的复制/写死）
- [ ] **主控**：判定并接线 W30A/C/D 的交付（单写者）
- [ ] `close-wave.sh` ⇒ 五臂 ⇒【**零构建窗口**】⇒ `verify-all` **两趟** ⇒ 应用门禁 ×2（带 `WPTD_BASELINE_OUT`）⇒ **重冻 `#30`** ⇒ 文档四件同趟

## §8 主控裁定（`#30` 车道请裁项，逐条）

**① W30F 的"4 件死件不修" —— 采纳，并升为原则。**
`w25-freeze.py`/`w26-freeze.py`/`freeze-w24.py`/`fix-inputs-fp.py` 今天重跑**必红**（例如 `w25-freeze:63` 的 `OLD_FP=0b8b6559…` ≠ 现值；`freeze-w24:53` 钉 `bsfP b6acdba4…` ≠ 现场 `fdcb41bd…`）—— **但它们当时是对的**（分叉发生在 `#28`：那是"`fp_inputs()` 开始纳入门禁/登记表"的那一波）。
⇒ **原则（与纪律 61 同族，写进纪律 66）**：**历史波尾脚本是历史记录的一部分 ⇒ 不许为了让它们"今天能跑"而改**；只有**当代**的（`w29-*`、以及下一个 `w30-*`）才要求"现算/必填"。**判据**：若某脚本的输出被**当时的冻结块**引用过，它就属历史记录。

**② W30A 请裁的 `# ARM-LOG-SHA` 那一档 —— 装。** 把 5 行 `# ARM-LOG-SHA arm=<臂> sha16=<16hex>` 与重冻 `#30` **同趟**插进最新 `# RE-FROZEN` 块，使 `column-floor-check.sh` 的第 ⑤ 档生效。理由：W30B 本波**已现场演示**"改臂 ⇒ `ARMLOG_SHA=FAIL pass=4 fail=1` ⇒ 同趟改 `arm_logs` ⇒ `PASS pass=5 fail=0`" ⇒ 那半颗牙的价值正是**把"同趟改 `arm_logs` 洗绿"这条自指通道暴露出来**（`D-G27` 立项的第二个理由）。

**③ W30A 的"新读者应纳入 `fp_inputs()`" —— 采纳，但必须与重冻同趟**（否则 `close-wave` 的"波前==波后"会 `exit 5`）。

**④ W30F 要求的调用契约（新）**：`#30` 重冻时 `w27-freeze.py` **必须显式给 `#30`**（它的树世代断言会先校验树停在 `#29`）；三支 `-fill.py` 的采样器路径与行车道句现在是**必填**（`W30F_MEMLOG`/`W30F_LANES`，不填即红）；`w29-cs.py` 换代**只许改 `NEWG` 一行**（漏改必红 —— 已实测）。

**⑤ W30E 的结构性观测 —— 立为纪律 67**：**"零产品位移"可能是"没有一支臂走产品入口"的副产品**。`tline` 是**仪器**（把语料 meta 直接喂 `FormatParagraph`，**绕过 PC**）、`PcLineOracle` 语料 modifier 命中 **0**、`MinMaxProbe`/`D5CbrProbe` 用 `Length=>0` 且**不在 `verify-all` 里** ⇒ **产品侧的缺口在回归里看不见**。W30E 已用**零 `dotnet` 独立复算**证明那 5 条 `M_modifier` Extent 余差**与 modifier 跨度未接线同根**（差 `0.08 = f 的 765 − 760 = 5/1000em × em16`，因隐形段含 `f` 而可见子集不含）。**对策 = 它推荐的方案 C**：加一支**走产品入口**（`TextFormatter.Create()` ＋ `FormatLine`）的臂，真值**直接复用** `layout-b34-compact.json` 的 5 个 M 例（**不需 Windows 重录**），代价 = 1 新工程 ＋ 1 次构建、**不动 `pc`/shim/世代**。⇒ **`#31` 头号候选。**

## §9 收官（`#30` 完成，2026-09-17 23:5x）

**`#30` 已重冻：整份 `sha16=e7d4977c773dd639`（347,350 B）**；机器行核对 `rc=0`、`BASELINEGEN=PASS decl_gen=#30`、`BASELINEDUP=PASS`。
**两趟 `verify-all` 各 `rc=0` / 18 步 / 871 通过 / 2 跳过，结论区逐字相同**；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、各 **6/6 `result=PASS`**；五臂 `TLINE_GATE=PASS … judge=t1b3-tline-gate/6` ＋ `GATE_PROBE=PASS`；`ARMLOG_SHA=PASS 5/5`。**九位只有环成员 `pf` 变**（`9178561e0fb1451c → 51e987d58da11654`），六条门禁行归一化后与 `#29` **逐字相同**。`inputs_fp = 98f600e5f44797b4…`（设计性变更：本波改了覆盖面里的 `close-wave.sh`）。
**重冻脚本的"牙齿②"现场逮住一件事**：头注释里没有 `#30` 这一代的步数声明（本波不动步数）⇒ `AssertionError`，**两个脚本都在写盘前失败、未产生半成品**；补上 `` **`#30` 收官起 = 18 步**（本波不动步数） `` 后才冻成。
**本波两条未接线项（刻意）**：`hidden-only-step.sh`（构建者，+101.9 s/趟、35 次 `dotnet`/趟）与 `column-floor-check.sh`（其声明行须与接线同趟落）⇒ 均留给 `#31`，理由已写进 `#30` 块。

# 波 `#24` 预登记（**落地之前先登记**）

> 生成：主控，基于**当前冻结基线 `#23`**（权威 = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`；⚠️ 本行**原先写了一个整份 sha**并在 `#24` 收官时被查出与 `docs/CURRENT-STATE.md` 记的**不一致**、且**已不可复算** ⇒ 按 `#24` 新立的规矩**值一律不在此处重述**，**只以 `CURRENT-STATE.md` 的 `BASELINE-FROZEN` 机器行为准**，由 `BASELINE-SHA` 那一步机器核对）。
> 冻结九位（开工前现场复算**逐位一致**）：`bridge d567c26f197ec1e3`(4,987,840 B) | `pc 7b47a7b3d69ad62f`(4,197,376 B) | `pf 1c3fe23261c22bc6` | `windowsbase 1114a28ec5a03ab7` | `provider 9aa0d744802aaa31` | `win32shim 0098234982391bbf` | `wic_shim 03b67fbcd7c385b6` | `hbtextline e89fed55fd8e32bc`(290,825 B) | `dwf 0ed422ef2dd46445`；`BRIDGE_SRC_FP=b6acdba4f01599d8`；`inputs_fp=6146f3641b87a5a7d74e182ab9ca3f6f72299377bbfce2993843cb56ccbca0ca`；`known-red.json=e623d2b17d948e3b`（`generation=#23`）。
> 纪律：**先登记后落地**｜红判据**只许加强**｜**表外位移 ⇒ 停**｜缺数据 ⇒ `NOINFO`｜**分母/是哪一列都要写清**（39）｜**仪器输入也算仪器**（40）｜**"在射程内"≠"真的看了"**（41）｜**改字段语义前逐消费点读语义**（44）｜**判据要断言集合基数**（45，**已按 `#23` 更正**）｜**收官从 `close-wave.sh` 开始**（46）｜**元断言采纳前先核机制**（47）｜**并发跑同一仪器要标 PID/时刻**（48）｜**不许手抄哈希**（49）。

## §0 本波四件 —— **目标：零世代成本**

| 件 | 题目 | 是否动 shim | 世代成本 |
|---|---|---|---|
| **P1** | `D-T5` **修法落地**（**只在应用器**：`ExtractRun` 先分类再取 CBR） | **不动** | **无** ✅ |
| **P2** | **帧列接线**：把 `FrameProbe` 接进 `verify-all`（新一步），让那 67 例/3 行**有处可登记** | 不动 | 无 |
| **P3** | `hasOverflowed` 判据（`CoverageProbe --tab-lines-oracle`；**必须写死严格 `>`**） | 不动 | 无 |
| **P4** | `D-G8`（`scanrc` 被丢弃 + `SELFTEST_E` 同趟改）+ `D-A2` 的"两份 `.so` 一起换旧仍静默"设计 | 不动 | 无 |

**⚠️ 本波的核心约束：`build/shims/**` 一个字节都不许改** ⇒ 世代绑定的三项（`run.sh`/`Parity.cs`/shim）**全不变** ⇒ **不重取五臂、不重钉 `known-red.json`、`generation` 仍是 `#23`**。
**若某件发现"非动 shim 不可" ⇒ 停下报告，不落地**（那件事排到需要付世代成本的下一波，与 `D-T5` 的严格档那半一起合并）。

---

## §1 P1 —— `D-T5` 修法（**只在应用器**）

### §1.1 上游法律（车道 W23A 已取证，**照录**）
**空 CBR 的 `TextHidden`/`TextModifier`/`TextEndOfSegment` 是「合法的隐形 run」** —— **保留 `Length`（占码元）、宽度为 0（Ghost）、绝不 deref CBR**。
三条上游引注：`Plsrun.Text` 才 deref `CharacterBuffer`（`:196-202`）；`Plsrun.Hidden` 用**哨兵字符** `TextStore.PwchHidden`（`:244`，声明 `TextStore.cs:2393`、赋值 `:86`、消费 `:1616`）；`TextHidden.cs:33` `ThrowIfNegativeOrZero(length)`、`:44-47` 返回**空** `CharacterBufferReference`。
⇒ **我方缺陷 = 在分类之前就 deref 了 CBR**（`ExtractRun` **先**取 `cbr.CharacterBuffer`，`buf == null` ⇒ `return null` ⇒ `CollectLenient` `return false` ⇒ 交回 LS ⇒ **abort 134**）。

### §1.2 修法（**逐字按车道的建议，主控已核**）
- **位置**：patcher `patch-presentationcore-textline-fallback.py` 的 `REPLACEMENT_3`（注入块 `:186–:507`，`ANCHOR_3` = `:184`）之内、**`ExtractRun`**（patcher `:241-249`；生成物 `:83-94`，关键行 `:88`）。
- **形态**：**先按 run 类型分类** —— 只有 `TextCharacters`（或 `ITextSymbols`）才 deref CBR；**其余按上游给空串 + 记一次 skip**（宽度天然 0）。
- ⛔ **不许**手改生成物（纪律 38）；**只改 patcher**。
- ⛔ **不许引入 `throw`**（`:811-813` 的"上游 `throw` 4 == 生成物 4"**是活的守恒断言**，实测过）。
- ⛔ **不许新增调用点**（`:803` 各恰好 1）。
- **保留** `++skipped;` 与 `DiagBeforeReturn`。
- **牙齿要同步**：① 修正 `:581` 那条**已被推翻**的 needle 文案（"任何 run 都取字符"）；② **新增一条正向 needle**："**隐形 run 不再 deref CBR**"。

### §1.3 判据与两极化（**用具现探针，不许自造**）
仪器 = `build/MilBridge/tests/D5CbrProbe/`（`#23` 建；冻结仪器 dll **`117582b2a40d30c0`**）。
**修前读数（已知）**：`control` GREEN｜`eos1`/`mod1` **`RED-EXC-LS` / `ABORT 134`**（快路径开即产品缺省也如此）｜`hidden*` 快路径**开时 GREEN**、**关时红**｜`mod0` 快路径开时 `RED-EXC`（快路径拒零长 run）、关时 GREEN。
**修后预测**：`eos1`/`mod1` **两条腿都转绿**（不再交回 LS）；`control` 仍绿；**`hidden*` 在 `--collapsible` 下也转绿**；**`mod0` 的"快路径拒零长 run"不应改变**（那是 `SimpleTextLine` 的行为，与本修法无关）。
**两极化**：① **回退证**（把 `ExtractRun` 的改动逐字节复原 ⇒ 必须又红）；② **第二极性**（假修 = 让 `ExtractRun` 返空串而**不动 `Length` 账** ⇒ **A3 必须仍红**：`Σ(Length−NewlineLength)` ≠ `CpLength`）。W23A 已用 `declaredgap` 牙齿**实测兑现**过第二极性（`A1=PASS A2=PASS A3=FAIL（Σ可见长=4 期望=5）`）。
**`abort` 与 `null` 的可分辨性**：规则 = `rc=134` ∧ 标记文件**无 `T3` 收尾行` ⇒ 被 abort；`rc∈{0,1,2}` ∧ 有 `VERDICT` ⇒ 探针活着。**规则自身已被 `--selftest abort|null` 两极化先验过**。

### §1.4 世代成本 = **零**（本件的最大价值）
`ExtractRun`/`CollectLenient` **都在应用器里** ⇒ **shim 不动** ⇒ **不重取五臂、不重钉登记表**。
⚠️ **但 `pc` 会变**（patcher 变了 ⇒ 重新生成 ⇒ 重建 PC），且 **`inputs_fp` 会变**（`patch-*.py` 在覆盖面内）⇒ 波尾仍需**应用门禁两趟 + 重冻基线**。
**严格档的那一半**（shim `TryCollect` `:4513`）**本波不做**（要付世代成本）⇒ 排到下一波与它同族的改动合并。

---

## §2 P2 —— 帧列接线（让残余红**有处可登记**）

### §2.1 为什么必须做
`#23` 实测：`FrameProbe` 在 `verify-all` / `tline-gate.sh` / `pc-line-step.sh` / `run.sh` / `arm-logs/README.md` **五处 grep 全 0** ⇒ 它**不在任何冻树回路里**；而它报的残余 **3 行红 / 67 例（`#22` 口径）** **今天无处可登记**。
⇒ **欠的是接线，不是登记**（车道 W23D 的结论，主控采纳）。

### §2.2 做法（**照 `pc-line-step.sh` 的形态**，不要发明新范式）
1. **`FrameProbe` 暴露机器可读的计数器**：在它的汇总行里加 **`帧红=<n>`**（把**帧族红**与**结构族红**分开计数；`#22` 的读数表原本就有这一列）。否则下游只能读 `红行=`（3），而那 3 条**全是结构族**。
2. **新建 `build/MilBridge/tools/frame-step.sh`**（照 `pc-line-step.sh`）：跑 `FrameProbe --leg b --tier strict`（与宽松/`--prefix` 的关系见 §2.3），然后断言：
   - **`帧红 == 0`**；**`判定行 > 0`**（**防恒绿退化**）；**`NOINFO` 不许算绿**；**`FrameProbe` 的产物目录里那份 `PresentationCore.dll` 副本必须 == 权威**（照 `pc-line-step.sh` 的既有自检 —— `#23` 实测该副本确实 == 权威）。
   - ⚠️ **不许**把"`红行=0`"当判据（那会把结构族也吞进来 ⇒ 与 `#23` 的教训相反）。
3. **接进 `verify-all`** 作为**第 12 步**（**步数 11 → 12，口径已变**，必须写进文档与基线表头）。
   ⚠️ **必须先单独跑一次 `frame-step.sh` 拿到 rc=0**，再接进 `verify-all`（**绝不许接一个没量过的步**）。

### §2.3 覆盖哪几条腿（**要写清，别只跑一条**）
至少 **`--leg b --tier strict`** 与 **`--leg b --tier lenient`** 两条；`--prefix 40` 那条**如果也接**，必须说明它同时改变了真值侧（`真值非零行 421`），因此它的判据口径与另两条**不同**（`#23` 实测）。
**步的 rc 由哪几条腿决定、哪几条只打印 ⇒ 必须逐条写清**。

### §2.4 仪器变更披露（纪律 40）
`FrameProbe/Program.cs` 的 before/after sha16 + 产物 dll 的 before/after sha16 都要记；并说明"**新加的 `帧红=` 让下游读数改变了**"。

---

## §3 P3 —— `hasOverflowed` 判据（22 行真值、**零判据**）

### §3.1 为什么它优先级高
`#22`/`#23` 两波查出的"同族普查"里，**`hasOverflowed` 是最该补的一条**：语料里 **22 行为 `True`**，而**当前没有任何判据看它** —— 而 `D-O1`（`#16`）**刚把它从"恒假"改成真实现**（三支真判据）。

### §3.2 设计（**照 W23D 的草案，主控已独立复核真值侧规律**）
- **放层**：**`CoverageProbe --tab-lines-oracle`**（在门禁里、语料自带真值、**已断言行数**、已喂 `pw`/`indent`/`PI`）。**不建新探针**（`D-G2`：别再加"只在车道里跑过"的仪器）。
- **真值侧规律（主控现算 615/615）**：`paragraphStartOffsetDip + width > paragraphWidthDip` ⇒ **命中 22 / 假阳 0 / 漏 0**，全部在 `script==latin` 可判定集内（`B-indent-extra` × `i24p24` × `w40`）。
- **接线后预测红 = 0 行 / 0 例**（我方分支③ `_boxOriginX + _width > _paragraphWidth + 1e-9` 与它**逐字同构**）。
- **⚠️ 必须写死严格 `>`**：**去掉严格 `>`（改 `>=`）⇒ 红 74 行 / 63 例（latin 58/47）** —— 那 74 行坐在"**恰好到达边缘、余量为 0**"的**发丝扳机**上。
- **反极性四档（全部现算，接线时必须实测至少两档）**：`=> false` ⇒ 红 **22 行/8 例**（首选）｜`=> true` ⇒ 593/428｜**错驱动量**（内容起点 `_startPenX+_width>W`）⇒ 89/54。

### §3.3 要求
- **只许加强**：新列**必须能决定红**；必须有**可点名计数器**；**既有列/分桶口径一个字节不许改**。
- **仪器变更披露**（纪律 40）：`CoverageProbe/Program.cs` before/after + 产物 dll before/after。
- **臂日志的影响**：`tab-anchor.log` 会多出新行 ⇒ 按 `#22` 的做法**重取该臂**（`ln -f`，**绝不 `cp`/`ln -s`**），并**逐行 `diff` 证明既有判据行逐字不动**（剔掉新增行后与 `#23` 原日志 `cmp` 逐字节相同）。
- **门禁必须仍 `PASS`**（`generation=#23 tree_gen=same`、`drift=0 gone=0 unregistered=0`）。**若出现未登记红 ⇒ 停并报告**（不许自行登记）。

---

## §4 P4 —— `D-G8` 修法 + `D-A2` 残余设计（**零 `dotnet`**）

### §4.1 `D-G8`：`scan()` 的 `rc` 被丢弃 ⇒ **权威整份不见时 `rc` 可能仍 0**
- **现场**：`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh:654` `scan; scanrc=$?`，而 **`grep -c scanrc` = 1**（赋值后**从未被读**）。
- **要做**：让"某个权威整份不见"**能让 `rc` 非 0**。
- ⚠️ **必须同趟改 `--selftest` 的 `SELFTEST_E`**（那个沙箱里没有 `ReachFramework`/`PC` 的权威件 ⇒ 补上 `rc` 的消费会让它**立刻红**）。
- **两极化（必须实测）**：**删掉一份权威件** ⇒ `rc≠0`；恢复 ⇒ `rc=0`。**并且** `--selftest` 必须仍 **`rc=0 / 16 项全 PASS`**。
- 用户已裁决的口径不许动：**13 份在册红照旧**、书面登记照旧、**不许发明"登记就变绿"的机制**。

### §4.2 `D-A2` 残余："两份 `wpfgfx_cor3.so` 一起换旧仍静默"
设计一条最小判据（例如**给 `wpfgfx_cor3.so` 配非 Debug 权威**，`#22` 已指出：④ 豁免要求"权威是 Debug"，权威改 release 后 `.artifacts/bin/.../native/` 那份会掉进 ⑥ 被真判）⇒ 给出**反极性**与**预估新红条数**，并说明**会不会与 13 份在册红冲突**。
**本件只出设计 + 反极性方案，不落地**（它是 §4.1 的同一份文件 ⇒ 与 §4.1 同趟改会更省，但要注意"一次只让一个东西动"）。

---

## §5 位移预测表（**表外位移 ⇒ 停**）

| 位 | 现（`#23`） | 预测 |
|---|---|---|
| **`pc`** | `7b47a7b3d69ad62f` | **变**（P1 改了 patcher ⇒ 重新生成 ⇒ 重建 PC） |
| **`pf`** | `1c3fe23261c22bc6` | **变**（环成员；**由波尾 `close-wave.sh` 重编引起** —— 纪律 46：**别在波尾之前下结论**） |
| **`inputs_fp`** | `6146f364…ca0ca` | **变**（`src/WpfGfx.Linux.Native/tools/patch-*.py` 在覆盖面内 —— **只此一个原因**，要现场核算子组） |
| **`hbtextline`** | `e89fed55fd8e32bc` | **不变**（**本波不许动 shim** ⇒ 世代绑定不变） |
| `bridge` / `BRIDGE_SRC_FP` | `d567c26f197ec1e3` / `b6acdba4f01599d8` | **不变**（不动 `src/WpfGfx.Linux/**`） |
| `windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` | 见 §0 | **均不变** |
| 五臂门禁 | `PASS generation=#23 tree_gen=same` | **仍 `PASS`**（`hbtextline` 未变 ⇒ **不重钉**）；⚠️ P3 会改 `tab-anchor` 臂日志 ⇒ **必须仍 `drift=0 gone=0 unregistered=0`** |
| `verify-all` | rc=0 / 11 步 | rc=0 / **12 步**（P2 加了帧列步 ⇒ **步数变了，口径已变**） |
| 应用门禁 | 6/6 `PASS`、六条机读行与 `#21` 逐字相同 | **预测逐位不变**；⚠️ **本波有命名候选**：P1 让 `eos1`/`mod1` 段落**从 abort 变成交出 TextLine** ⇒ 若样例里有这种段落，渲染会变 —— 但 `#23` 已证 `samples/**` **0 载体**（全走 `SimpleLine`）⇒ 预测不变 |
| 等号读者 | `SHIM_SHA=no` | **`no`**（产物仍用同一份 shim 编） |

---

## §6 停条件（**触发即停**）

1. 任何位移落在 §5 表外。
2. **任何一件需要动 `build/shims/**`** ⇒ 停下报告（本波是零世代成本波）。
3. P1 的**第二极性**拿不到（假修后 A3 不红）⇒ 判据作废。
4. P1 修后 `control`（阳性对照）或 `mod0` 的读数**发生变化**（说明动了不该动的地方）。
5. P2 的 `frame-step.sh` **单独跑不是 rc=0**。
6. P3 接线后**出现未登记红**，或**门禁不再 `PASS`**。
7. P4 补 `scanrc` 后 **`--selftest` 不再 `rc=0 / 16 项全 PASS`**。
8. 任何"把红判据放松""把未登记红压成绿""手改生成物"的动作。
9. 内存：见 §7。

---

## §7 资源与内存纪律（**沿用 `#23` 的协议**）
开工前实测：`MemTotal` 7,923 MB；`#23` 波的内存信封 = `MemAvailable` **最低 2,752 / 均值 3,406 MB**、`SwapFree` **全程未动**。
1. **同一时刻只允许一个重构建**：**只有 P1 可以重建 `pc`**；P2/P3 只许构建**各自的小工程**（`FrameProbe`/`CoverageProbe`）；P4 **零 `dotnet`**。
2. 所有 `dotnet` 命令必须带 **`-m:1`** + **`DOTNET_gcServer=0`**。
3. 构建前自检：`MemAvailable < 1200 MB` ⇒ 等 20 s 重试（最多 5 次）；仍不足 ⇒ **报 `NOINFO` 并停**。
4. 报告里必须写 `MemAvailable` 的**开工/最低/收工**三值 + `loadavg`。
5. **禁止**：`dotnet build wpf-linux.sln`、`verify-all`（主控的活）、并发两个重构建、`pkill -f`。
6. 收工前按 PID 确认**没有留下自己的 `dotnet`/MSBuild 进程**。
7. **并发跑同一仪器必须在报告里标 `PID` + 时刻 + 被测件 sha**（纪律 48）。

---

## §9 P4 收官 —— `D-G8` 修法（车道 W24D，报告 `484738db104b56f2`）

### §9.1 现场复核（主控独立）
`check-applocal-sync.sh` `013df358c0bed2a3 →` **`fc4c249851fa1d71`**（71,502 B / 778 行）。
**主控复核三处**：① `grep -c scanrc` = **1**（改前 `:654` `scan; scanrc=$?`，全脚本仅此一次）；② **`AUTH-MISSING` 真的接进 rc** —— `:226` `[ -f "$exp" ] || { CNT_AUTHMISS=$((CNT_AUTHMISS+1)); rc=1; printf '    AUTH-MISSING …' }`；
③ 总判定规则（`:34`）含 **`AUTH-MISSING>0` ⇒ `APPSYNC=MISMATCH` + `exit 1`**；`:29` 仍写着「**登记条目照样计红**（`APPSYNC=MISMATCH` + `exit 1` 不变）⇒ **登记 ≠ 已容忍**」⇒ **用户裁决的口径未被削弱**。

### §9.2 两极化（**删权威 ⇒ `rc 0 → 1`**，四组 11 趟留档）
- **改前假绿复现**：私有沙箱里移走一份权威（`ReachFramework.dll`，该沙箱内无副本）⇒ **`rc=0` + `APPSYNC=PASS`，且计数器与"权威俱全"那趟逐字相同** ⇒ **假绿**（这正是 `D-G8` 的危害）。
- **改后同一状态** ⇒ **`rc=1` + `AUTH-MISSING=1` + `APPSYNC=MISMATCH`**，而**其余计数器与绿趟逐字相同**（"**红只来自新信号**"有**永久断言**）。
- **`cp -p` 整份还原** ⇒ `rc=0`，且与绿趟 **`cmp` 逐字节相同**。
- **主控独立跑了它的自检**：`--selftest` ⇒ **`rc=0`、`SELFTEST_*=PASS` 计 17 项、`=FAIL` 计 0 项**（改前 16 项 ⇒ 新增 **O** 作**永久反极性**；**E 同趟加固**：沙箱补 `ReachFramework`/`PC` 权威 + 断言 `AUTH-MISSING=0`，否则消费 rc 会立刻假红）。主控并**逐字读到** `SELFTEST_O` 的三态断言与 `AUTH-MISSING` 的具名行。

### §9.3 车道**如实偏离**任务书一处（**这是对的**）
任务书要"删真件验 `rc≠0`"，它**没删真件**，理由写清：
① **真仓基线 rc 本来就是 1**（`MISMATCH=1` + `UNEXPECTED=1[DECL-GAP-EQ]` + `DIVERGENT=1`）⇒ **0↔1 在真件上不可观测**；
② 移真件会与**另两条在跑的构建争用**（本波有 W24A/W24B 在跑 `dotnet`）。
替代证据 = **旧脚本 vs 新脚本在真仓、同命令形态、同一时刻的对比**：`diff` = **5 行 / 3 处，全部是它新加的输出**（`scan() 内部 rc=` 行 + 计数格/`APPSYNC` 行尾 `AUTH-MISSING=0`）⇒ **真仓零位移、零新红**。
⚠️ **主控的测量限制（记我头上）**：我用 60 s 超时跑真仓那次**被 SIGTERM 杀掉**（全仓扫描 + 两条车道在构建 ⇒ 太慢）⇒ 我的那次读数**作废**（不是检查器的问题）；已改用长超时重取。

### §9.4 在册红：**登记表仍是 13 条**，现场是"**仍红 1 ｜ 已转绿 12**"
`known-red-PC-copies.md`（`e5946a8a7ce1cfe0`）**未变**、`known-red.json` **未碰**。
**"已转绿 12"不是本件造成的**：`pc` 在 `#23` 重生为 `7b47a7b3d69ad62f` 后，那 12 份 PC 副本**已收敛**（改前就是这样）⇒ R0 与 R1 的在册红段落**逐条相同**。
⇒ **`[在册红·已转绿]` 这个自证机制正在按设计工作**（它指出该删的条目），**待主控按 12 条逐条销账**（排 `#25`）。

### §9.5 🆕 `D-A2` 残余：**车道推翻了 `#22` 的预测**（主控采纳）
`#22`/W22D 预测"给 `wpfgfx_cor3.so` 配**非 Debug 权威**就能堵住'两份一起换旧'" ⇒ **实测 2×2 矩阵否掉**（真旧桥 `caf7baf9e67719aa`）：**两份一起换旧时仍 `rc=0`/`APPSYNC=PASS`**，因为**权威本身就是那两份副本之一** ⇒ **该方案的结构性增量 = 0 条新红、0 个新覆盖场景**。
**正确的锚其实已经存在**：`<publish>/bridge-src-fp.txt` 里**有** `BRIDGE_SO_SHA256`（`publish-milbridge.sh:81` 写、`run-wpftextdemo.sh:122` **已在应用层读**）⇒ `ITEMS` 里那句"**无跨波稳定的期望 sha**"**只对一半**：**记录是有的，缺的是校验器去读它**。
⇒ **`#25` 的判据草案（~5 行）**：`ITEMS` 的 `wpfgfx_cor3.so` 权威从空串改成 **读 `bridge-src-fp.txt` 的 `BRIDGE_SO_SHA256`**；**今天 0 条新红**；与 13 份在册红不冲突；**需主控先裁"记录陈旧算不算红"**。

---

## §10 P3 收官 —— `hasOverflowed` 判据接线（车道 W24C，报告 `bc9f3af81a312ef0`）

### §10.1 读数（**逐位兑现预登记 §3.2**）
`TAB_LINES OVERFLOWED 红=0 绿=421 判定行=421 NOINFO=194 红例=0 NOINFO例=148 对齐=Left 真值True=22 诊断发丝边界行=58`，且 `对账 … ⇒ 与汇总一致`。
分母严格按纪律 39 = **latin 288 例 / 421 行**；真值 `True` = **22 行 / 8 例**（全在可判定集内）⇒ **列有判别力**，且**接线后红 = 0 行 / 0 例，与预登记逐位吻合**。

### §10.2 反极性：**拿到 4 档**（要求 2 档）
| 档 | 红行 / 红例 | 说明 |
|---|---|---|
| **(a) `=> false`** | **22 / 8** | = W23D 的预测（首选档） |
| **(b) 错驱动量**（`_startPenX+_width>W`） | **79 / 48** | ⚠️ 见 §10.4 |
| **(c) `=> true`** | **399 / 280** | 第二极性 |
| **(e) 去掉严格 `>`（改 `>=`）** | **58 / 47** | **把"必须写死严格 `>`"从告诫变成读数** |
四档 `rc` 全 = 1（**未登记红如实进 rc**）；**逐例点名行数（22/79/399/58）↔ `OVERFLOWED-RED` 明细 ↔ `UNREGISTERED` 例级行数（8/48/280/47）三方对账全一致**。
**复原三重证明**：树 shim 全程 `e89fed55fd8e32bc` **未动**｜末次构建 dll 回到 `1c112f42e9708638`（与绿跑同一份）｜复原后重跑 anchor 日志 **`cmp` IDENTICAL**。临时态只在 `$HOME/w24c-laneW24C/mut/**` ⇒ **树里零残留**。

### §10.3 「只新增」是机器证（**比"我保证没改别的"强**）
- `CoverageProbe/Program.cs` `421fe394bea93fe2 →` **`dea2a02cf8bab55a`**（116,496 → 125,908 B；**`diff` 删除行 = 0**，新增 109 行全为插入）；产物 dll `ec490a628beef3d5 →` **`1c112f42e9708638`**。
- **最硬的一条**：三支臂日志**剥掉全部 `^TAB_LINES OVERFLOWED` 行**后与 `#23` 原日志 **`cmp` 逐字节相同**（剥后 sha16 恰为 `#23` 原值 `b9d81590f3fcd800` / `1a5bc7181d0155c3` / `419e8aaa9c72a9a0`）；`diff` 的 `only-in-old = 0`、新增里非 `OVERFLOWED` 的行 = **0**；三支 `退出码=` 行与 `#23` **逐字相同**。
- 臂日志（全部 `ln -f`，链接数 2）：`tab-anchor 1a5bc7181d0155c3 → 56abc845dbd29e93`｜`tab-zero b9d81590f3fcd800 → 424d4c6d5ab121cb`｜`tab-rtl 419e8aaa9c72a9a0 → 5e4d9ef3c64f7d7e`；**四支无关臂未动**。
- **门禁 4 趟 `PASS`**、`generation=#23 tree_gen=same drift=0 gone=0 unregistered=0 caliber=OK`；09:48:09 连跑两趟**逐字节相同**（`204d379e7c029c40`）⇒ **不需要重钉**（与预登记 §5 一致）。

### §10.4 车道**更正主控**与**两条新事实**
1. **我派单里 (b) 档的预测数又用错了分母**：「错驱动量 ⇒ 89 行 / 54 例」是**全域**数，而本臂只判 `script==latin` ⇒ 实测 **79 / 48**，与 W23D 表的 **latin 列**逐位吻合。⇒ **生效预测 = 79/48**（纪律 39 同族错法，第 **6** 次；**主控记**）。
2. **新事实（W23D 未覆盖）**：`tab-zero` / `tab-rtl` 两份语料**确实带 `hasOverflowed` 真值**（138 / 163 行）**但没有 `paragraphProperties` 段、没有 `script` 字段** ⇒ **这两支臂上本列只能全 `NOINFO`**（`对齐=NOINFO`、真值 `True` = 0）⇒ **本列的实际判别面只在 `tab-anchor` 一支臂上**。要更大判别力应接 **`--tab-oracle`（U1，36 例 true）** —— **那条路今天仍不在任何门里**。
3. **把 W23D 的"风险带"变成机器事实**：`诊断发丝边界行=58` ↔ 独立 python 现算（**58 行 / 47 例**，真值全 `false`）↔ (e) 档实测红（**58 / 47**）**三处逐位相同**。

### §10.5 残留 `NOINFO`（不许读成绿）
`tab-zero`/`tab-rtl` 的判定（无对齐法律）｜branch ②（语料不可行使）｜branch ①（本臂恒喂 `pw>0`）｜`Right`/`Center`/`Justify`（语料 **436/436 全 Left**）｜**产品路径**（`PcLineOracle`/`TextFormatter`）上的 `HasOverflowed`（本件**只接源直调层**）｜RTL 半边｜`--prefix 40`/`FrameProbe` 的消费者面（P2 射程）｜`D-O1` 之前的史实读数（用 (a) 档等效重现，已标注）｜`--tab-oracle` 那条更具判别力的路。

### §10.6 内存
开工 3,420,132 kB｜采样最低 **2,505,392 kB**（09:46:43，含他车道负荷）｜收工 2,857,996 kB；`loadavg` 0.39 → 6.62（另有两车道在跑）。收工 `dotnet build-server shutdown` ⇒ 本件 0 残留。

### §10.7 ⚠️ 主控**现场发现的一条瞬时态**（写清楚，免得被当成新缺陷）
主控在 W24A 落树之后、波尾之前跑真仓检查器，读到 **`MISMATCH=18（STALE=18）`**（`#23` 收官时是 13）。
**成因 = `pc` 刚被重建**（`7b47a7b3d69ad62f → 476994e35d31a7e1`，mtime `09:46:20`）⇒ **12 份 PC 副本立刻全部转 STALE**（逐份点名的 `EXPECT 476994e35d31a7e1 / ACTUAL 7b47a7b3d69ad62f`），待波尾 `close-wave.sh` 的 `refresh_applocal` 收敛。
⇒ **不是新缺陷**；**并且它解释了 §9.4 的"已转绿 12"** —— 那 12 条**只是"当时与 `pc` 相同"**，`pc` 一变就又 stale。
⇒ **两条口径（本波产出）**：
1. **`APPSYNC` 的读数只在"某个 `pc` sha"下有意义** ⇒ **它必须在波尾、`pc` 定型之后再读**（与纪律 46 同族：**别在波尾之前下结论**）。
2. **`known-red-PC-copies.md` 的 `[在册红·已转绿]` 是同样性质的信号** ⇒ **销账必须按"当时的 `pc` sha"逐个世代核**，不能拿一次"已转绿"就当永久销账（**登记 ≠ 已容忍**的反面同样成立：**转绿 ≠ 永久修好**）。

### §7.1 ⚠️ 主控**自查**：本波的并发开高了（协议要收紧）
**实测信封（70 样本 / 35 分钟）**：`MemAvailable` **最低 2,130 MB / 均值 2,750 MB**；**`SwapFree` 最低 807 MB** —— 而 `#23`（同样四车道）是**全程未动 1,057 MB**。⇒ **本波吃掉了约 250 MB swap**；`load1` 峰值 **9.31**（3 核）。
**成因（不是别人的问题）**：协议只写了"**只有一个重构建者**"，但本波实际是 **P1 重建 `pc`** + **P2 建 `FrameProbe`** + **P3 建 `CoverageProbe` 且重跑三支臂** **同时**在跑 ⇒ 3 个 `dotnet` 各自再起 MSBuild 节点 ⇒ 3 核被超订 3 倍。
**⇒ 收紧后的协议（`#25` 起生效）**：在 **3 核**机器上，**同时最多 2 个构建者**（不是 3）；若某件必须重建 `pc`，则该件**独占**，其余车道**只许跑"零 `dotnet`"或"纯 python/shell"**的工作，构建类工作**排到前者收工之后**。
**为什么写进预登记而不是只记在心里**：`#23` 的"没出事"给了**假的安全感** —— 本波才是**真实压力**下的读数（**测出来的边界**），而这正是本项目一贯要的东西。

---

## §11 P1 收官 —— `D-T5` 修法（车道 W24A；**本节含主控的独立复现**）

### §11.1 ⭐ 主控**独立复现**（在 W24A 落树之后、波尾之前，我自己跑的）
仪器 = `build/MilBridge/tests/D5CbrProbe/`（`#23` 建）。**前置自检**：该探针产物目录里的 `PresentationCore.dll` 副本 **== 权威**（`476994e35d31a7e1`）⇒ 量的是新产物。
命令形态：`dotnet PresentationCore.Tests.dll --case <名> --tier <strict|lenient> --marker /tmp/…`（`unset DISPLAY`）。

| 输入 | 修前（W23A 基线） | **主控实测（修后）** |
|---|---|---|
| `control`（纯 `TextCharacters`，阳性对照） | GREEN | **`rc=0`**（仍绿） |
| **`eos1`（`TextEndOfSegment(1)`）** | `RED-EXC-LS` / `--nocatch` **`rc=134`** | **`verdict=GREEN`**：`A1非null=PASS A2无LoCreateContext=PASS A3长度一致=PASS（Σ=5 期望=5）` |
| **`mod1`（`TextModifier(1)`）** | 同上 | **`rc=0`**（两档） |
| `mod0`（`Length=0`） | 快路径**开**时 `RED-EXC`、关时 GREEN | **`RED-EXC` 不变**（见下，**与 `D-T5` 无关**） |
| **`hidden1` / strict + `--collapsible`** | **`RED-EXC` / `rc=134`** | **`verdict=GREEN`**：`A1/A2/A3` 全 `PASS`；链 = 严格档 bail（"run 类型 TextHidden …"）⇒ 宽松档接手 |

⇒ **三种 run 类型（`TextEndOfSegment`/`TextModifier`/`TextHidden`）在主控的独立跑里全部转绿**，且**机制在探针自己的诊断里可见**（见下）。

**`eos1` 的接手链（探针自己印的，不是我推的）**：
`严格档 bail("run 类型 TextEndOfSegment 不支持") ⇒ 宽松档接手`，且 `relaxedSkippedRuns=1`、**`lastSkip="TextEndOfSegment x1"`**、**`relaxedInvisibleRuns=1`**、`lastFail="-"` ⇒ **正是上游法律说的「合法的隐形 run」形态**（**先分类、不 deref CBR、记一次 skip、照样交出 `TextLine`**）⇒ **修法语义正确，不只是"`rc=0`"**。

**`mod0` 的 `RED-EXC` 是修前就有的、且不在本件射程**：异常 = `ArgumentOutOfRangeException: textRun.Length ('0') must be a non-negative and non-zero value`，且接手链印 **`NOINFO(两档零增量 ⇒ 这一例没走到托管档)`** ⇒ **是 `SimpleTextLine` 快路径拒零长 run**（`TextHidden.cs:33` 同族的前置校验），**不是 `D-T5`**。修前基线同形 ⇒ **不变**。

### §11.2 硬约束成立：**零世代成本兑现**
`hbtextline` 全程 **`e89fed55fd8e32bc` 未变**（主控每次复算）⇒ **世代绑定三项不变** ⇒ **不重取五臂、不重钉登记表**，门禁仍 **`PASS generation=#23 tree_gen=same`**。
变的只有：`pc`（`7b47a7b3d69ad62f → 476994e35d31a7e1`）、patcher、生成物、`inputs_fp`（**唯一原因 = `patch-*.py`**）。

### §11.3 W24A 的完整读数（车道报告 `4b517c6e8d1f76e8`）

**修后 × 两类快路径**（仪器 `D5CbrProbe` 冻结 dll `117582b2a40d30c0`；strict/lenient × catch/nocatch **四格全同**）：

| 输入 | 快路径**开**（修前 → 修后） | 快路径**关**`--collapsible`（修前 → 修后） |
|---|---|---|
| `control`（阳性对照） | GREEN → **GREEN**（**逐字节同**） | GREEN → **GREEN**（**逐字节同**） |
| `eos1` / `mod1` | `RED-EXC-LS`/`ABORT 134` → **GREEN** | 同 → **GREEN** |
| `hidden1` / `hiddenmid` | GREEN（快路径接）→ GREEN | `RED`/`134` → **GREEN** |
| **`hiddenonly`** | GREEN → GREEN | `RED`/`134` → **仍 `RED-EXC-LS`/`ABORT 134`**（**残项**，见 §11.5） |
| `mod0`（`Length=0`） | `RED-EXC`/`134` → **不变** | GREEN → **不变** |
| `declaredgap`（牙齿对照） | `RED-LENGTH` → 不变 | `RED-LENGTH` → 不变 |

**§6 停条件 4 未触发**（`control`/`mod0` 逐字节未变 ⇒ 没动不该动的地方）。

### §11.4 两极化：**两个层级都拿到**（`#23` 标为 `NOINFO` 的那格已补上）
① **回退证（逐字节往返闭合）**：复原 patcher ⇒ patcher `00c2179b87fc0509`、生成物 `fef2cfb47f882a82`、**`pc` 逐字节回到 `7b47a7b3d69ad62f`**，探针 MATRIX 与修前**逐字节相同**（又红）；复原终态 ⇒ `pc` 又是 `476994e35d31a7e1` ⇒ **往返闭合、树里 0 残留**。
② **真·假修端到端**：
   - **牙级**：只把代码改成 `return string.Empty;` 而**牙齿不动** ⇒ **生成 `rc=1`、生成物根本没写盘**（`a6f1b678ce87a8a2` 不变）⇒ **牙齿真的在挡**（这是"**注册了但没生效**"的反面现场）。
   - **端到端**：代码 + needle **一起**改 ⇒ `pc 0acc01198b5d0d36` ⇒ `eos1`/`mod1`/`hidden1`/`hiddenmid` 全为 `A1=PASS A2=PASS` **`A3=FAIL（Σ可见长=4 期望=5）`** ⇒ **`RED-LENGTH`**，而 `control`/`mod0` 不变。
   ⇒ **真修 `A3` PASS / 假修 `A3` FAIL ⇒ `A3` 有判别力**（不是恒真）。

### §11.5 主控裁决三条（车道如实上报，我逐条定）

#### ① 占位字符：**接受落地，并把偏差登记为 `D-T7`**（**真值只能靠真机重录**）
车道自陈：§1.2 说的"给空串"与 §1.3 说的"转绿"**互相矛盾** —— 返空串 ⇒ `A3` **必然红**（分母 `CpLength` 由源定死 = 5，只交 4 个码元对不上）⇒ 它按 §1.3 落地为**零宽占位**（上游 Ghost 语义"**占码元、宽度 0**"）。
**主控补的证据**：占位取 `U+200B`，理由是"**零宽是它的定义性质**"+ 仓内实测佐证（`layout-b34` 的 `A1_nbsp_zwsp_*` 族含 **2 个** U+200B 而**宽度契约全过**、`T1b-report.md:1007` 实测 Noto Sans 里它 bbox 全零）。
**我另查了真值的来源**：上游真机的隐形字符是 **LineServices 原生**给的哨兵 `LSEsc.szHidden`（`TextStore.cs:86` 赋值、`FormatSettings.cs:244` 消费）—— **我们这份仓里定不出它的码点**；且**仓内没有 `U+2060` 的任何证据**（我 `grep` 过）⇒ 换 `U+2060` 是**没有依据的猜**。
⇒ **裁决：接受 `U+200B`**，但把它**如实登记为 `D-T7`**：
- **偏差**：UAX#14 里 ZWSP **可断**（ZW 类），而真机 Ghost run **不产生断点**；
- **风险限定（关键）**：该偏差**只在"修前会 abort 的段落"上出现**（= 全新领域）⇒ **不会让任何现有读数变差**（车道的零射程证支持这一点）；
- **真值只能靠真机重录**：判据草案 = 造一个 `TextHidden` 段落使占位恰好落在断点候选处，真值 = **真机的行数**；反极性 = 现状（若在某处多断一行）必红。**排 `#25`。**

#### ② `hiddenonly` 仍红：**裁决 = 车道做得对（不落地、不压绿），登记为 `D-T5` 残项**
机制（车道实测）：`lastFail="没有 run properties"` —— `TextHidden.Properties` **恒 null**，而探针段末交出的 `TextEndOfParagraph.Properties` **也是 null**。
⇒ 修它要动 `CollectLenient` 的 **props 兜底**并**透传段落属性** ⇒ **超出 §1.2 的 `ExtractRun` 写域**。
⇒ **裁决**：**本波不落地**（写域之外 + 会引入"props 从哪来"的新设计问题）；**登记为 `D-T5` 的残项**（"全隐形段落"这一形态），修法域已点名。**不许**把它写成"`hidden*` 全转绿"。

#### ③ 车道撤回的一条差点写歪的读法（**主控采纳**）
它原打算写"零射程覆盖 `tab-anchor` 全体"，随后自查发现：`tab-anchor` 的 **148 例 hebrew/arabic（含 `C-rtl-indent` 16 例）全是 `跳过=面缺字形`、未被任何档接手** ⇒ **零射程证只覆盖 latin 288 例 / 421 行，不覆盖 RTL**；RTL 已移入 `NOINFO`。
⇒ **这与 `#21`/`#22` 反复立的"分母/是哪一列"是同一条纪律**（第 39 条）⇒ 采纳，并在报告里保留其撤回过程。

### §11.6 `inputs_fp` 的子组分解（**"只此一个原因"被逐字兑现**）
`inputs_fp` `6146f364…ccbca0ca →` **`a87034194a66f7d18a9903a06337ad839cae8dba2669736abbec9cd8f6dee793`**；
**唯一变化组 = G1 `patch-*.py`**（`31f8c41f… → 5f862595…`）；**G2 shims 与 G3 `src/WpfGfx.Linux/**` 未变** ⇒ 与预登记 §5"**只此一个原因**"**逐字一致**。
**`hbtextline` 未变** = `e89fed55fd8e32bc`；`bridge`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf`/`pf` **全未变** ⇒ **§5 表外位移：无**。
**闸门**：`patcher --check rc=0`；`check-appliers.sh` **`appliers=22 ok=80 miss=0 red=0 rc=0`**；**纪律 38 红线**（再生成）⇒ 生成物逐字节不变、注入仍在。

### §11.7 一条**运维发现**（影响 P2 的接线）
车道的零射程证：`PcLineOracle` 修前/修后各 1,480 行，**只差 4 行**（每腿 2 行，全部是既有诊断串**追加** `relaxedInvisibleRuns=0 lastInvisible="-"`），其余逐字节相同。
⚠️ 但它同时报告：**`--prefix 40` 腿单跑 > 600 s**（并发时约 11 分钟）⇒ **若把帧步接进 `verify-all`，必须单独算它的时间预算**（见 §12 主控的实测与裁定）。

---

## §12 P2 收官（主控部分）—— 帧列已接进 `verify-all` 作为**第 12 步**

### §12.1 主控**独立跑通**（接线的前置条件）
`bash build/MilBridge/tools/frame-step.sh` ⇒ **`FRAME_STEP_RC=0`、`FRAME_STEP=PASS`**：
```
腿 strict / lenient / strict+prefix40 三条腿均：
  判定行=421  红行=3  帧红=0  结构红=3  仪器族NOINFO=0  结构族NOINFO=101  自洽=1
被测 pc 全程未变 = 476994e35d31a7e1
结构族红汇总（未登记，主控的登记决定；本步不判）： strict:3 lenient:3 strict+prefix40:3
```
设计**逐条照预登记 §2.2**：断言 **`帧红==0` ∧ `判定行>0` ∧ `仪器族NOINFO=0` ∧ `自洽=1`**（防恒绿 + `NOINFO` 不算绿 + 自洽），**绝不断言 `红行==0`**；结构族红**点名供登记但不判**。

### §12.2 ⭐ 主控**实测**的时间预算（不是估计）
`/usr/bin/time` 跑三条腿全量：**`WALL=427.96 s`（≈7.1 min）、`MAXRSS=708,300 KB`（≈692 MB）**、rc=0。
（车道报的">600 s"是**并发下**的最坏值；干净单跑是 428 s。）
⇒ **`verify-all` 的时长预期 +≈7 min**，已写进第 [6] 步的注释。

### §12.3 裁决：**三条腿全留**（不把 `--prefix 40` 降为可选）
- `--prefix 40` 是**唯一**行使"**段落原点本身偏移**（`cpFirst≠0`）"的腿 —— 而那正是本波 `_paragraphOrigin` 的**机制所在**；
- 把它降为 opt-in **就是减覆盖**（与"红判据只许加强"相悖），而代价只是 7 分钟；
- 若日后必须缩短，**唯一的正确做法**是先实测"去掉它之后还有没有腿能行使 `cpFirst≠0`"，**不许**凭"太慢"就删。

### §12.4 接线形态
`verify-all.sh` `279b958dda238447 →` **`b9d500568d02201e`**：在第 [5] 步之后插入**第 [6] 步**：
`run_step "FrameProbe·帧列" bash build/MilBridge/tools/frame-step.sh`（注释里写明"**步数 11 → 12，口径已变**"、"**只判帧红**"、"不覆盖那 3 条结构族红"、以及实测时间预算）。
`bash -n` 通过。⇒ **旧的"11 步"读数与新的"12 步"不能互相引用**（与 `#15`/`#16`/`#21` 的步数口径变更同族）。
`frame-step.sh` = **`37f27df68e52bf8c`**（`#24` P2 车道建；主控核过其稳定性：mtime 10:11，我 10:17 的计时跑用的就是当前版）。

### §12.5 本步**明确不覆盖**什么（写清，免得被读成"已守"）
1. **那 3 条结构族红**（`行数我方=4 真值=2`）—— **`frame-step.sh` 只点名、不判**；它们是**主控的登记决定**（今天仍无处可登记）。
2. **RTL 半边**（`tab-anchor` 的 148 例 hebrew/arabic 全 `跳过=面缺字形` ⇒ 未被任何档接手）。
3. **`--prefix 40` 腿的真值侧同时变了**（`真值非零行 133 → 421`）⇒ 它的口径与另两条**不同**，读它的数时要连口径一起读。

---

## §13 P2 收官 —— 帧列（车道 W24B，报告 `89309b0fdb905bda`）

### §13.1 三条腿的读数（**帧红全 0**）
| 腿 | 判定行 | 红行 | **帧红** | 结构红 | 仪器族NOINFO | 结构族NOINFO | 真值非零行 |
|---|---|---|---|---|---|---|---|
| `strict` | 421 | 3 | **0** | 3 | 0 | 101 | 133 |
| `lenient` | 421 | 3 | **0** | 3 | 0 | 101 | 133 |
| `strict --prefix 40` | 421 | 3 | **0** | 3 | 0 | 101 | **421** |

仪器 = `FrameProbe/Program.cs` **`503e6ebd86d70303`**（修前 `c6a66724ad56760a`），产物 dll `db3b321944f31a15`。
**既有 8 列零射程**：剔掉新增项后全日志 **88 行逐字节 `IDENTICAL`**、汇总行 `IDENTICAL`（`cmp` 证）。

### §13.2 `frame-step.sh` 单独跑 = **rc=0**（接线前置条件）
无并发确认跑：**`WALL=394.07 s`、`MAXRSS=706,576 KB`（≈690 MB）**，输出 sha16 `72ede9085b130e73`，`FRAME_STEP=PASS`；两趟 rc=0 剔掉日志目录行后 `diff` 无差异 ⇒ **可复现**。
（主控另在并发下独立跑一次：**`WALL=427.96 s`、`MAXRSS=708,300 KB`**、rc=0 ⇒ 两者一致。）

### §13.3 ⭐⭐ 反极性：**拿到真红（4 组）**，其中 **N-1 是最强的一档**
- **N-1（最强，用真实件）**：私目录里用**修前 `pc e7cabff9417ed380`**（`$HOME/wfp-runs/w21-gate1/`，4,196,864 B）、**同一支探针**、同一语料 ⇒ **`strict+prefix40` 帧红=421 / `lenient` 帧红=133**，与 `#23` 的修前表（`W23B`）**逐格吻合**；现树 `pc` ⇒ 0。
  ⇒ **这把"判据能红"从"改代码造出来的红"升级成"用真实旧产物得到的红"**（与 `#21`/`#22` 用留档旧 `pc` 做红证同族）。
- **N-2**：退化语料（436/436 例 `script` 改非 latin）⇒ **`判定行=0` ⇒ `rc=1`** ⇒ **防恒绿退化的闸是活的**。
- **N-3**：临时把断言换成 `结构红`（预登记 §6.3 许可）⇒ `rc=1` ⇒ 红路径活、`结构红=3` 没被吞。
- **N-4（边界，如实标）**：把语料真值改坏 ⇒ `结构红` 3→12 而本步**仍 `rc=0`** ⇒ **"本步不看真值一致性"是设计**，已实测写明。
临时变体已 `rm -f`，**交付体 sha 全程未变**。

### §13.4 🔴 车道**推翻**的一条（**最值钱**）—— 而它**正好证明主控"三条腿全留"的裁决是对的**
> **`#23` 修前表里那三格判别力不等价**：**只接 `--leg b --tier strict`（不带 `--prefix`）这一条腿，对 `D-T6-b` 是零判别力** —— 修前 `帧红=0/结构红=3`，现在 `帧红=0/结构红=3`，**逐位相同**；「严格档红 3 行」**不能当修法证据**。真正有判别力的是 **`--prefix 40`（421→0）** 与 **宽松档（133→0）**。

⇒ **主控在 §12.3 的裁决（三条腿全留、不许把 `--prefix 40` 降为可选）因此从"机制理由"升级为"实测理由"**：那条腿是**判别力的载体**，删它就是删判据。
⇒ 同时**更正 `#23` 的读法**：`#23`/`W23B` 表里"严格档 `红 3 → 3`"那一格**不是"修法没修到"**（我当时的预登记曾把它读成残留），而是**那条腿本来就看不见这个缺陷**。⇒ **报"某格没动"之前，必须先问"这条腿有没有判别力"**（纪律 41 的又一次现场；建议并入 41 的注脚）。

### §13.5 车道**改进**了我预登记的一处设计（**主控采纳，它比我的写得好**）
我 §2.2 只写"**`NOINFO` 不许算绿**"。实测：**`NOINFO行=101` 恒非零**（**语料性质**）⇒ 断言 `NOINFO == 0` 会让本步**要么永远红、要么只能作弊**。
⇒ 车道的设计：**按族分解**，断言 **`仪器族NOINFO == 0`**、同时打印 `结构族NOINFO=`（101）。⇒ **我把 §2.2 的口径按它的写法更正**（**只加强**：族内不许有 `NOINFO`，族外的语料性质单独列）。

### §13.6 车道**自查出自己的一处 bug**（如实留档）
首版 `frame-step.sh` 三处 `echo` 里的**反引号被做成命令替换**（stderr 打"帧红: 未找到命令"并吃词）⇒ 已修并留证：首版 `b168c353385df785` → 交付体 **`37f27df68e52bf8c`**。

### §13.7 主控采纳它的两条**接线改进**（都已落）
1. **步名必须是 ASCII**：`run_step` 失败时按 `tr -c 'A-Za-z0-9' '_'` 生成 `/tmp/verify-all-<name>.log` ⇒ **CJK 步名会变成一串下划线**。我原写 `"FrameProbe·帧列"`，**已改成 `"FrameProbe-frame"`**（**这是我接线里的一处真缺陷，车道指出**）。
2. **`run_step:87` 的失败诊断 grep 抓不到本项目的失败形态**：各步是用 `KEY=FAIL`/`KEY=NOINFO` **自报**的（`FRAME_STEP=FAIL …`、`PCLINE_START_STEP=FAIL …`、`TLINE_GATE=FAIL/NOINFO …` —— **都不含 `Failed`**）⇒ 失败时屏上只有 `❌ (rc=1)`，细节全在被拷走的日志里。⇒ **主控已补** `|[A-Z][A-Z0-9_]*=(FAIL|NOINFO)`（**旧 pattern 原样保留，只加不删**），并用一个含 `FRAME_STEP=FAIL` / `PCLINE_START_STEP=FAIL` / `error CS1234` 的合成日志自测过（三条都抓到）。
3. 另按它的清单同步了 `verify-all.sh` 的**陈旧头注释**（原写"**4 个测试套件**"，是 `#15` 之前的旧描述）⇒ 已改成 6 个测试套件 + **六个步骤的口径表 + 第 11/12 步的实测时间预算**。

### §13.8 其余如实登记
- **`pc` 在它读数期间变过**（纪律 35 逐趟标定）：`7b47a7b3d69ad62f → 476994e35d31a7e1`；`--prefix 40` 那趟**跨了换代时刻**，靠探针自证「本机副本 前=后=`7b47a7b3d69ad62f`」判归属。`hbtextline` 全程未变。
- **并发交底（纪律 48）**：它记录 10:17:28–10:24:38 有**外部进程**（`PID 522415/522416/522720`）跑同一脚本 —— **那是主控的计时跑**；它自己的确认跑 10:25:34 起，**两窗不重叠**。
- **欠账**：结构族红 3 条**未登记**（主控决定；本步只做到"逐条点名 + `probe_rc` 原样保留"）；`--fresh-source` 腿未接未测；腿 A 只在现树 `pc` 上测过；**`verify-all` 整趟 12 步未跑**（主控写域）。

---

## §8 收官清单（**顺序不可颠倒 —— 纪律 46**）

- [x] **主控第一步：`bash build/close-wave.sh --skip-verify-all`**（它会重建 PC/PF/WB ⇒ **动 `pf`**）⇒ 实测 `OUT=~/wfp-runs/close-wave-24`、rc=0、**`native_rebuilt=0`、`bridge_republished=0`**、桥源指纹两侧一致 `b6acdba4f01599d8`、生成物指纹 `state=ok`、应用器审计 `miss=0`
- [x] 复核九位与 `inputs_fp`（**`hbtextline` 必须未变** ⇒ 若变了说明有人动了 shim ⇒ 停）⇒ **`hbtextline e89fed55fd8e32bc` 一个字节未动** ✓（相对 `#23` 只 `pc`/`pf`/`inputs_fp` 三位变）；`inputs_fp` **输入稳定性 波前==波后** `a8703419…ee793`
- [x] **五臂：本波预期「不必重取」** —— 但**必须实测确认** `TLINE_GATE=PASS generation=#23 tree_gen=same drift=0 gone=0 unregistered=0`；
      ⚠️ P3 改了 `CoverageProbe` 且重取了 `tab-anchor` 臂 ⇒ 门禁读的是**新日志**，必须仍 PASS
      ⇒ 实测 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc`**、`GATE_REASON=all-as-registered`、rc=0 ⇒ **预测兑现**（且 `known-red.json` **一字未改**、`generation` 仍 `#23`）
- [x] `frame-step.sh` 单独跑通（rc=0）后再进 `verify-all` ⇒ 实测单独跑 `rc=0`、`WALL=394–428 s`、峰值 RSS ≈690 MB
- [x] `verify-all`（**12 步 →（收官时补第 `[7]` 步）13 步**）⇒ 实测 **rc=0 / 13 步 / 871 通过 2 跳过 / `结论：✅ 全部通过`**；**跑了两趟**（`w24-verify13.out` = 升到 13 步之后；`w24-verify13b.out` = 基线改成 13 步、机器行重算之后 —— **为让第 `[7]` 步的 PASS 落在最终冻结版上**，见 §14.4）
- [x] 应用门禁**两趟**（`:97` 前置断言 + **逐字记录装置行**，按 `D-G7`）⇒ 两趟均 `WPTD_GATE=PASS acceptance=2/2`、`6/6 BASELINE result=PASS`，**六条机读行与 `#23` 逐字相同**（只差 `pc`/`pf` 与 `rundir`）
- [x] **重冻 `#24`**（`ACCEPTANCE-BASELINE.md`：新表头 + `#24` 块 + 6 条机读行；`#23` 降历史；**`inputs_fp` 用脚本算出来的值写，不许手抄** —— 纪律 49）⇒ 已冻，整份 sha **由 `BASELINE-SHA` 机器核对**（`PASS/PASS/PASS`、rc=0）
- [x] 文档：`CURRENT-STATE.md`（横幅/§1 表/纪律）+ `handoff.md`（`#24` 记录）+ `KNOWN-DEFECTS.md`（`D-T5` 已修 + `D-G8` 已修/未修 + `hasOverflowed` 已接判据）+ 本文件 **§14**
- [x] 纪律 38 红线：**再跑一次 patcher** ⇒ 注入逐字节还在、`--check` rc=0、`check-appliers.sh` `miss=0 red=0` ⇒ 实测 `miss=0`（`close-wave.sh` 的应用器审计）、生成物 `state=ok`

## §14 收官（主控：`#24` 波收口）—— **含两处"收官时才发现"的新牙齿**

### §14.1 顺序（纪律 46）逐条兑现
`close-wave.sh --skip-verify-all` → 九位/`inputs_fp` 复核 → 五臂实测 → `frame-step.sh` 单独跑 → `verify-all` → 应用门禁 ×2 → **重冻 `#24`** → 文档。逐条读数见上面的勾选清单与 `handoff.md` 的 `#24` 记录（`4600a9f967709233`）。

### §14.2 预测 vs 实测（本文件 §5 位移表 / §6 停条件）
| 预测 | 实测 | 判定 |
|---|---|---|
| `hbtextline` **一个字节不动**（零世代成本） | `e89fed55fd8e32bc` 未变 | ✅ |
| 五臂**不重取**、`known-red.json` **不重钉** | `generation=#23 tree_gen=same`、`known-red.json` 一字未改 | ✅ |
| 只 `pc`/`pf`/`inputs_fp` 三位变 | 正是这三位（`pf` 由**波尾** `close-wave.sh` 重编引起） | ✅ |
| `bridge` 不重发 | `d567c26f197ec1e3` 未变、`bridge_republished=0` | ✅ |
| 应用门禁**读数不变** | 六条机读行与 `#23` **逐字相同** | ✅ |
| **停条件 4**（阳性对照 `control`/`mod0` 若变 ⇒ 停） | **未触发**（逐字节未变） | ✅ 未触发 |
| **§12.3 的决定**（帧列三条腿**全留**、`--prefix 40` 不降为可选） | 被 W24B 的实测**证实必要**（见 `handoff.md` `#24` 记录 ② 与 §13） | ✅ 决定正确 |

### §14.3 收官时新加的第 `[7]` 步 `BASELINE-SHA`（**预登记里没有这一项**）
**加它的理由不是"想加"，是本波自己查出的一处不可复算**：`#23` 的整份 sha 在**三个**文档里记成**两个**值（`docs/CURRENT-STATE.md` 与 `docs/WAVE23-PREREGISTRATION.md:481` 记 `5ccdf74a56955096`；`docs/WAVE24-PREREGISTRATION.md:3` 记 `87ae111462ca2159`），而 `#23` 内容已被本波覆盖 ⇒ **今天无法判定哪个对**。**可证实的一点**：`~/w21-verify/fix-inputs-fp.py`（mtime `01:00`）在 `freeze-w23.py`（`00:58`）**之后**改过基线 ⇒ **冻结时那个 sha 必然已失效**。**主控试过逐字节重建**（用 `freeze-w23.py` 的 `newhdr`/`blk` 字面量 + 尚存的 `~/wfp-runs/w23-gate2b/baseline23-run2.md` + 现文件尾部反推）⇒ **两个值都不命中 ⇒ 重建前提不成立 ⇒ 放弃**（**不拿推测冒充结论**）。
落地 = `build/MilBridge/tools/baseline-sha-check.sh`（`5836b8296b2e4245`）+ `verify-all.sh 0d268f4f0bb441c3 → 741b638acaf02e7a`（**步数 12 → 13**）。判据 = 现场重算基线**整份** sha16 ↔ `CURRENT-STATE.md` 的机器行 `> BASELINE-FROZEN gen=#NN sha16=<hex16> file=<path>`，并核对"文档声明的世代 == 基线文件里**最新**那行 `# RE-FROZEN #NN`"。三态 `PASS/FAIL/NOINFO`，**`rc=0` 只在全 PASS 时给出**（"没声明"也判失败 ⇒ **防静默绿**）。**另加反重复牙齿 `BASELINEDUP`**：活的权威对（`CURRENT-STATE.md` + 基线文件）里**禁止**散文式「……整份 sha = `<hex16>`」声明 —— **值只许出现在机器行里**。
**反极性 `--selftest` 6/6 PASS**（PASS / sha 扰动一位 ⇒ FAIL / 删声明 ⇒ NOINFO / 世代写错 ⇒ `BASELINEGEN=FAIL` / 文件里出现更新世代 ⇒ `BASELINEGEN=FAIL` / 塞一句散文声明 ⇒ `BASELINEDUP=FAIL`）；**自测当场抓出两个真缺陷**（扰动值只造出 15 位 ⇒ 只证出 NOINFO 没证出 FAIL；抽取没取首行 ⇒ 声明缺失时匹配到两行、比较永远失败）⇒ 新立纪律 **53**。

### §14.4 自指问题（纪律 54）——为什么 `verify-all` 跑了**两趟**
第 `[7]` 步验的是**基线文件的整份 sha**，而"13 步"这个读数要**写进基线块** ⇒ 一写就改了 sha ⇒ **牙齿验的是上一版**。⇒ 处理：**同一次动作里**改基线 + 重算机器行（脚本一起做），然后**再跑一趟** `verify-all`，使第 `[7]` 步的 PASS 落在**最终冻结版**上；并断言**九位波前==波后**（`w24-pre-verify13.nine` vs `w24-post-verify13.nine`，机器 `diff` 证过 ⇒ `verify-all` 不改九位）。两趟读数**逐格相同**。

### §14.5 预登记没写、收官时新开的**两条只读侦察车道**（零 `dotnet`、零仓内写入）
派它们是为了**下一波**，但结果**反过来改了本波的记录**：
- **`D-A2-r` 方案**（`~/w25-recon/da2r-plan.md fabd8ae7cb81975f`）：找到绝对锚 = `bridge-src-fp.txt:3` 的 `BRIDGE_SO_SHA256`（写点 `build/publish-milbridge.sh:81`；⚠️ **我派单书写错了路径**）、`run-wpftextdemo.sh:122` **已在读但不判定**、桥**其实在 `ITEMS` 里但 `exp` 空 ⇒ 在 `:225` 被跳过**；🔴 **推翻我原方案 A** —— 给它配非空权威会经 `sync-applocal-authority.sh:103` **用 376 B 的 `.txt` 覆盖 4,987,840 B 的 `.so`** ⇒ 改**只读方案 B**。**裁决见 `handoff.md` `#24` 记录 ⑨**（判据**只看 sha**；**"记录过期"与"件被换"不需要可分判据** ⇒ 两种口径都判红；记录缺失 ⇒ `NOINFO`）。
- **`D-T5-R` 修法域**（`~/w25-recon/d-t5r-plan.md cb70e58b4e479ace`）：**推翻我的派单前提** —— `CollectLenient` **不在 shim 里**（`grep -c` = 0），真身在**生成物** `TextFormatterImp.Linux.cs:243-248`（源头 = 应用器 `REPLACEMENT_3`）；根因 = 全隐形段落里**每个 run 的 `Properties` 恒 `null`**；兜底候选 = `paragraphProperties.DefaultTextRunProperties`；⇒ **修法可 100% 落在应用器 ⇒ 也是零世代成本**。

### §14.6 本波登记的两处**车道引注错误**（由侦察车道发现、主控现场核对）
`build/MilBridge/W24A-report.md:253` 把那条 `return false` 引成 `CollectLenient` 的 `:358-363`，而**现盘任何件里都没有这个位置**（真身 = 生成物 `:245-248`）。**成因**：`没有 run properties` 这个串**在六个件里都存在**（生成物 `:245`/`:246`、应用器 `:403`/`:404`、shim `:4580`（**死码**）、`staging/PresentationCore.HbTextLine.cs:1605`、`CoverageProbe/refs/…ebccdb1e.cs:3539`）⇒ **`grep` 归属天然歧义**。另：`W23A-report.md:230` 的"收集串 = 空串"是**假修情形**的描述。⇒ 纪律 4 的又一现场（**引注要连文件名一起写**）。

### §14.7 下一波（`#25`）候选（**按价值排序**）
① **`D-T5-R` 修法**（修法域已定位、零世代成本；判别力边界必须写进落地报告：`A1/A2/A3` 对"占位字符是否真零宽"**零判别力**，且冻结语料**不含全隐形段落** ⇒ "能否转绿"可测、"转绿是否对"**本仓不可测**，要真机重录）｜② **`D-A2-r` 落地方案 B**（判据草案已在侦察报告里，含 `--selftest` 用例 P；**今天就 0 条新红**）｜③ **`D-T7`**（零宽占位码点，**必须真机重录**）｜④ **`hasOverflowed` 的更大判别面**（`--tab-oracle`/`U1`/36 条真值 —— **仍不在任何门或步里**）｜⑤ **收紧三步的自报口径**（`pc-line-step`/`frame-step`/`baseline-sha-check` 各吐一条 `KEY=PASS` 汇总行，让 `run_step` 的失败诊断 grep 直接命中）。

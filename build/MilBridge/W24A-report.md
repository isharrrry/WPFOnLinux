# W24A 报告 —— `#24` §1 P1：`D-T5` 修法落地（**只在应用器**，零世代成本）

> **lane=W24A** ｜ 开工 `2026-09-17 09:31 +0800` ｜ 收工 `2026-09-17 10:15 +0800` ｜ **kernel `6.8.0-138-generic`** ｜ `nproc=3`
> `loadavg` 开工 `0.14 0.08 0.04` ／ 收工 `3.57 3.42 3.36`（**另有一条车道 W24B 在跑 `FrameProbe`**，见 §⑪ 并发交底）
> **`MemAvailable`** 开工 **`3,411 MB`**（`free -m` 首采样）／ **最低 `2,197 MB`**（首次重建 `pc` 后）／ 收工 **`3,009 MB`**；`SwapFree` 开工 `951 MB` → 收工 `801 MB`（**非本车道独占：另两条车道同时在跑**）
> 全程 `-m:1` + `DOTNET_gcServer=0`；**未跑** `wpf-linux.sln`、**未跑** `verify-all`、**未跑** `tline-gate.sh`（五臂门禁 = 主控）、**未并发两个重构建**。
> 收工按 PID 查：**没有留下我自己的 `dotnet`/MSBuild 进程**（`pgrep -a dotnet` 剩下的两条都是 **W24B** 的，`pgrep -c MSBuild` = 0）。全程**未执行** `pkill -f`。

---

## ① 一句话判决

**`D-T5` 修法已落地，`eos1`/`mod1` 在**两条腿、两类快路径、两种 catch 姿势**下全部由 `RED-EXC-LS / ABORT 134` 变成 `GREEN`（`A1/A2/A3` 三条全 PASS）；`control` 与 `mod0` 的读数**一个字节没动**（预登记 §6 停条件 4 未触发）；`hbtextline` 未变（**零世代成本**）。**
**但预登记 §1.3 的"`hidden*` 在 `--collapsible` 下也转绿"只兑现 2/3**：`hiddenonly`（整段只有一个 `TextHidden` 的退化形态）**仍红（`ABORT 134`）**，机制已实测钉死（§⑦.2）——**未落地、未压绿、如实上报**。

---

## ② 拿到读数之前先复算冻结基线（`#23`）

**逐位一致（脚本现场算，纪律 49：不手抄）**：

| 位 | `#23` 冻结 | 我开工实测 |
|---|---|---|
| `bridge` | `d567c26f197ec1e3` | ✅ `d567c26f197ec1e3`（4,987,840 B） |
| `pc` | `7b47a7b3d69ad62f` | ✅ `7b47a7b3d69ad62f`（4,197,376 B） |
| `pf` | `1c3fe23261c22bc6` | ✅ `1c3fe23261c22bc6` |
| `windowsbase` | `1114a28ec5a03ab7` | ✅ 同 |
| `provider` | `9aa0d744802aaa31` | ✅ 同 |
| `win32shim` | `0098234982391bbf` | ✅ 同（283,648 B） |
| `wic_shim` | `03b67fbcd7c385b6` | ✅ 同 |
| `hbtextline` | `e89fed55fd8e32bc` | ✅ 同（290,825 B） |
| `dwf` | `0ed422ef2dd46445` | ✅ 同 |
| `inputs_fp` | `6146f3641b87a5a7d74e182ab9ca3f6f72299377bbfce2993843cb56ccbca0ca` | ✅ 同（**算法照抄 `build/close-wave.sh` 的 `fp_inputs()`**，未自己发明） |
| `known-red.json` | `e623d2b17d948e3b` | ✅ 同（**未动**） |

⇒ 树未被别人动过，未触发"停并报告"。

---

## ③ 改动逐处（**只动一个文件**：应用器 `patch-presentationcore-textline-fallback.py`）

| 件 | 修前 sha16 | 修后 sha16 | 尺寸 | mtime |
|---|---|---|---|---|
| `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` | **`00c2179b87fc0509`** | **`536f58b338a2369d`** | 54,344 → **61,044** B | 00:12:26 → 10:02 |
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（**生成物，未手改**） | `fef2cfb47f882a82` | **`a6f1b678ce87a8a2`** | 56,380 → **60,034** B（1,227 行） | — |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `7b47a7b3d69ad62f` | **`476994e35d31a7e1`** | 4,197,376 B（**尺寸巧合不变**，见 §⑩.7） | 00:48 → 10:05 |

**备份**（`cp -p`，改动之前）：`$HOME/w24a-pre/patch-presentationcore-textline-fallback.py`（= `00c2179b87fc0509`）、`$HOME/w24a-pre/TextFormatterImp.Linux.cs`（= `fef2cfb47f882a82`）、`$HOME/w24a-pre/pc-before.dll`（= `7b47a7b3d69ad62f`）、终态留档 `$HOME/w24a-pre/patcher-finalform.py`（= `536f58b338a2369d`）。

**`diff` 只有 5 个 hunk（+79 / −7 行）**（`/tmp/w24a-patcher.diff`）：

| # | hunk（patcher 新行号） | 改什么 |
|---|---|---|
| 1 | `@@ -204,8 +204,11 @@` → 新 `:208`/`:211` | 新增两个字段：`private static int s_invisibleRuns;`、`private static string s_lastInvisible = "-";` |
| 2 | `@@ -219,8 +222,10 @@` → 新 `:225`/`:228` | `Diagnostics` 串**追加**两个字段（`relaxedInvisibleRuns=` / `lastInvisible="…"`）；**既有字段一个没动** |
| 3 | `@@ -232,18 +237,56 @@` → 新 `:237–292` | **修法本体**：`ExtractRun` 前的整段注释重写 + 新增 `IsTextRunType`（`:258`）+ `GhostChar`（`:274`）+ `ExtractRun` 里**分类 guard 在 deref 之前**（`:281-286`） |
| 4 | `@@ -578,13 +621,32 @@` → 新 `:621–652` | **牙齿**：`:628` 那条被推翻的 needle **改文案**（代码串逐字未动）+ **新增 4 条正向 needle** |
| 5 | `@@ -807,6 +869,19 @@` → 新 `:869–887` | **新增一条"顺序"牙齿**（`i_guard < i_deref`） |

**生成物里的落点**（`a6f1b678ce87a8a2`）：`:50`/`:53` 字段、`:67`/`:70` 诊断串、`:100` `IsTextRunType`、`:116` `GhostChar`、`:123` 分类 guard、`:127` 占位。

### ③.1 修法的形状（**先分类、再取字符**）

```csharp
        private static bool IsTextRunType(TextRun run)   // 上游 `Plsrun.Text` 那一支（`GetRunType:398`）
        {
            return run is ITextSymbols || run is TextShapeableSymbols;
        }
        private const char GhostChar = '\u200B';
        private static string ExtractRun(TextRun run)
        {
            if (run == null || run.Length <= 0) return string.Empty;
            if (!IsTextRunType(run))                      // ⭐ 分类**在 deref 之前**
            {
                ++s_invisibleRuns;
                s_lastInvisible = run.GetType().Name + " x" + run.Length;
                return new string(GhostChar, run.Length); // 占码元、零宽（上游 Ghost 语义）
            }
            CharacterBufferReference cbr = run.CharacterBufferReference;
            MS.Internal.CharacterBuffer buf = cbr.CharacterBuffer;
            if (buf == null) return null;                 // 取字符类 run 取不到 ⇒ 仍**诚实失败**
            …
        }
```

**上游依据（照录 `W23A-report.md` §⑥.1）**：`TextProperties.GetRunType`（`:396-412`）只有 `ITextSymbols`/`TextShapeableSymbols` 是 `Plsrun.Text`（**唯一** deref `CharacterBuffer` 的分支，`FormatSettings.cs:196-202`）；其余一律 `Plsrun.Hidden`（`:410` 注释逐字 *"Other text run type are all considered hidden by LS"*）⇒ 拿**哨兵字符**（`FormatSettings.cs:241-246`），**从不 deref CBR**。

### ③.2 ⚠️ 一处**必须披露的自主决定**：占位字符取 `U+200B`

- **为什么不能照抄上游的哨兵**：上游用的是 LineServices 的 `TextStore.PwchHidden`（`TextStore.cs:86/2393`）——那个哨兵**由 LS 自己消费、不整形**；我方这条路的字符**要交给 HarfBuzz 整形** ⇒ 照抄码位不成立。
- **为什么是"占位"而不是"空串"**：见 §⑦.1 —— 上游 Ghost 语义是"**保留 `Length`（占码元）、宽度 0**"，返空串**丢掉了 `Length` 账**。
- **为什么取 ZWSP**：零宽是它的定义性质；HarfBuzz 对 default-ignorable 一律给 0 advance。**仓内实测佐证**：`tests/parity/windows/layout-b34` 的 `A1_nbsp_zwsp_*` 族（文本含 **2 个** U+200B）在 `tline` 臂与真机**宽度契约全过**（`build/MilBridge/arm-logs/tline.log`，该族唯一不一致的是一例 `Collapse hasCollapsed` 期望）⇒ **ZWSP 在我方管线里贡献 0 宽度**。
- ⛔ **如实登记的偏差**：UAX#14 里 ZWSP = **ZW 类（其前可断）**，而真机的 Ghost run **不产生断点** ⇒ 本修法会在**"修前必然 abort 的那些段落"**上多出断点。它**不可能让任何现有读数变差**（那些段落修前是进程级 abort），但它是**与真机的偏离** ⇒ 已列 §⑧ 残项。备选（更好但**仓内无实测证据**）：`U+2060 WORD JOINER`（default-ignorable ⇒ 0 advance，UAX#14 = WJ ⇒ **禁断**）。

---

## ④ 牙齿改动逐条 + 断言条数解释

**`REQUIRED_IN_OUTPUT` 条数：26 → 30（+4）**；`--check` 打印的 `[断言]` 行：**12 → 13（+1）**。

| 动作 | 条 | 说明 |
|---|---|---|
| **改文案** | `:628` | 原：`("**任何 run 都取字符**（不再只认 TextCharacters）", "private static string ExtractRun(TextRun run)")`。**这句话已被 `W23A` ⑦.1 实测推翻**，而本修法**正是"不再任何 run 都取字符"** ⇒ 它在为一本被推翻的命题背书。**needle 的代码串逐字未动**（只改标签）⇒ **射程未变**。 |
| **新增正向** | `:637` | `"return run is ITextSymbols || run is TextShapeableSymbols;"` —— 分类 = 上游 `Plsrun.Text` 那一支 |
| **新增正向** | `:642` | `"if (!IsTextRunType(run))"` —— **"隐形 run 不再 deref CBR"**（本波要求的第二条） |
| **新增正向** | `:646` | `"return new string(GhostChar, run.Length);"` —— 占位给足 `Length`（**区分真修 / 假修**的那一条） |
| **新增正向** | `:649` | `"relaxedInvisibleRuns="` —— 计数可读（"修了但没生效"必须能被外部看见） |
| **新增顺序牙** | `:869-887` | **程序化断言**：`out.find("if (!IsTextRunType(run))") < out.find("CharacterBufferReference cbr = run.CharacterBufferReference;")` |

**为什么要"顺序"那条**：needle 只能证明"两串都在文件里"；而 `D-T5` 的根因**恰恰是顺序**（先 deref ⇒ 隐形 run 的空 CBR 必然 null ⇒ abort）。**光有分类代码、却把它放在 deref 之后 ⇒ 所有 needle 全绿而缺陷照旧**（`#17` "注册了但没生效"同族）。实测（`--check` 实录）：

```
[断言] D-T5 顺序：分类 guard @5666 < CBR deref @5923（隐形 run 在 deref 之前被拦下）✅
[断言] `throw` 条数 上游 4 == 生成物 4
[断言] 大括号平衡 {=118 }=118；上游 776 行 → 生成物 1215 行（+439 行，全是判断与注释）
```

**守恒未被打破**：`throw` 上游 4 == 生成物 4 ✅；两处 `WpfLinuxLenientTextFallback.TryXxx(` 各 1 处 ✅（**未新增调用点**）；`++skipped;` 与 `DiagBeforeReturn` **都在** ✅（隐形 run 仍走 `++skipped` 那条"放宽了一类 run"的记账）。

---

## ⑤ 读数表（**修前 / 修后 × 两类快路径 × 四种输入**）

仪器 = `build/MilBridge/tests/D5CbrProbe/`，**冻结仪器 dll `117582b2a40d30c0`**、`Program.cs 92694cf0c9c5d392`（**本件一个字节未动**）。驱动 = `$HOME/w23a-run/run-matrix.sh`（W23A 的驱动，**一例一进程** ⇒ abort 不会带走别的例）；`pc` 权威 = 探针目录内副本（每趟表头都自报两处 sha）。
**判读规则**（W23A §③ 已被 `--selftest abort|null` 两极化先验过）：`rc=134` ∧ 标记文件**无 `T3` 收尾行** ⇒ **进程被 abort 带走**；`rc∈{0,1,2}` 且有 `VERDICT` ⇒ 探针活着。

### 5.1 快路径**开**（产品缺省姿势）—— `$HOME/w24a-run/pre-fpon`（修前）/ `Y-fpon`（修后）

| 输入 | 修前（`pc 7b47a7b3d69ad62f`） | 修后（`pc 476994e35d31a7e1`） | 预测（§1.3） |
|---|---|---|---|
| `control`（纯 `TextCharacters`，**阳性对照**） | **GREEN (0)** | **GREEN (0)**（逐字节相同） | 仍绿 ✅ |
| `eos1`（`TextEndOfSegment(1)`） | **`RED-EXC-LS` ／ nocatch `ABORT(134)`** | **GREEN (0)** | 转绿 ✅ |
| `mod1`（`TextModifier(1)`） | **`RED-EXC-LS` ／ `ABORT(134)`** | **GREEN (0)** | 转绿 ✅ |
| `hidden1`/`hiddenmid`/`hiddenonly`（`TextHidden`） | GREEN（`SimpleTextLine` 快路径处理，**不是 `D-T5`**） | GREEN（**不变**） | —（快路径开时本来就不进 `D-T5`） |
| `mod0`（`Length=0` 的 modifier） | `RED-EXC (1)` ／ `ABORT(134)` | **`RED-EXC (1)` ／ `ABORT(134)`（一字未变）** | **不应变** ✅ |
| `declaredgap`（牙齿对照，非产品用例） | `RED-LENGTH (1)` | **`RED-LENGTH (1)`（一字未变）** | — |

### 5.2 快路径**关**（`--collapsible` ⇒ `AlwaysCollapsible=true` 关掉 `SimpleTextLine` 快路径；**`D-T5` 可达姿势**）—— `pre-fpoff` / `Y-fpoff`

| 输入 | 修前 | 修后 | 预测（§1.3） |
|---|---|---|---|
| `control` | **GREEN**（严格档接手） | **GREEN**（严格档接手，逐字节相同） | 仍绿 ✅ |
| `eos1` | **`RED-EXC-LS` ／ `ABORT(134)`**（两条腿都红） | **GREEN**（宽松档接手，`rc=0`） | 转绿 ✅ |
| `mod1` | **`RED-EXC-LS` ／ `ABORT(134)`** | **GREEN** | 转绿 ✅ |
| `hidden1` | **`RED-EXC-LS` ／ `ABORT(134)`** | **GREEN** | 转绿 ✅ |
| `hiddenmid` | **`RED-EXC-LS` ／ `ABORT(134)`** | **GREEN** | 转绿 ✅ |
| **`hiddenonly`** | **`RED-EXC-LS` ／ `ABORT(134)`** | **`RED-EXC-LS` ／ `ABORT(134)`（仍红）** | 转绿 ❌ **未兑现**（见 §⑦.2） |
| `mod0` | **GREEN**（宽松档接手） | **GREEN**（逐字节相同） | 不应变 ✅ |
| `declaredgap`（牙齿） | `RED-LENGTH` | **`RED-LENGTH`（一字未变）** | — |

两条腿（`--tier strict` / `--tier lenient`）× 两种 catch（`catch` / `--nocatch`）共 **4 个格子**，`eos1`/`mod1`/`hidden1`/`hiddenmid` **4/4 全绿**；`control`/`mod0`/`declaredgap` **4/4 与修前逐字节相同**。
**修后两趟独立复跑**（`Y2-fpon`/`Y2-fpoff`）与首跑 **逐字节相同**。

### 5.3 逐例原样摘录（修后，`--collapsible`，`--tier strict`，`catch`）

```
D5CBR INPUT eos1 runs=[TextEndOfSegment L=1]@0 [TextCharacters L=4]@1 CpLength=5
D5CBR ATTR  case=eos1 tier=strict 接手链=严格档bail ⇒ 宽松档**接手** ｜ 严格档 Δcalls=1 Δhandled=0 Δbailed=1 lastBail="run 类型 TextEndOfSegment 不支持" ｜ 宽松档 Δcalls=1 Δhandled=1 Δfailed=0 lastFail="-"
D5CBR DIAGafter  lenient{relaxedCalls=1 relaxedHandled=1 relaxedFailed=0 relaxedSkippedRuns=1 relaxedBlankParagraphs=0 relaxedInvisibleRuns=1 lastSkip="TextEndOfSegment x1" lastSkippedRange="[0,1) TextEndOfSegment" lastInvisible="TextEndOfSegment x1" lastFail="-"}
D5CBR ASSERT case=eos1 tier=strict A1非null=PASS A2无LoCreateContext=PASS A3长度一致=PASS（Σ(Length−NewlineLength)=5 期望=5）
D5CBR VERDICT case=eos1 tier=strict verdict=GREEN 行数=1 Σlen=6 Σnl=1 Σ可见长=5 期望=5 GetTextRun次=4 #1=6/nl1 异常=-
```

**这一段是修法的"三重自证"**：① **谁接手**（严格档 `bailed=1` ⇒ 宽松档 `handled=1`）；② **修法真的生效**（`relaxedInvisibleRuns=1`、`lastInvisible="TextEndOfSegment x1"`、`lastSkippedRange="[0,1) TextEndOfSegment"` —— 修前这三项**一个都不存在**，因为修前这条路在 `ExtractRun` 就 `return null` 走不到这里）；③ **账目守恒**（`Σ可见长=5 == CpLength=5`，`Σlen=6 = 5 + 1 个行尾符`）。

`mod1` / `hidden1` / `hiddenmid` 同形（`lastInvisible="ProbeModifier x1"` / `"TextHidden x1"`；`hiddenmid` 的 `lastSkippedRange="[2,3) TextHidden"` ⇒ **占位落在段中间的正确下标**）。

### 5.4 `GetTextRun` 次数与"最长 4096 轮"闸

`eos1` `GetTextRun次=4`（修前同格 `GetTextRun次=2`）。多出来的两次 = 宽松档**真的走完了收集循环**（修前在第一个 run 就 `return false`）。**未贴近 `guard < 4096` 上限**（探针另有一层 `guard++ < 64` 的行循环闸）。

---

## ⑥ 两极化（**缺一即本件作废**）

### 6.1 ① 回退证：**逐字节复原 ⇒ 又红**（三级同一性都取到）

| 级别 | 修前 | 修后 | **复原后** | 结论 |
|---|---|---|---|---|
| 应用器 | `00c2179b87fc0509` | `536f58b338a2369d` | **`00c2179b87fc0509`** | 逐字节相同 |
| 生成物 | `fef2cfb47f882a82` | `a6f1b678ce87a8a2` | **`fef2cfb47f882a82`** | 逐字节相同 |
| **`pc`** | `7b47a7b3d69ad62f` | `476994e35d31a7e1` | **`7b47a7b3d69ad62f`** | **逐字节相同**（⇒ 重建**可复现**，`pc` 的变化**唯一归因**于本应用器改动） |
| 探针读数 | 红（`eos1` `ABORT 134`） | 绿 | **红（`ABORT 134`）** | 见下 |

**读数证据**：复原态 `--collapsible`/`strict` 的 8 例 × 2 模式行与**修前 MATRIX 逐字节相同**（含 `pc_sha_before/after` 列）：

```
$ diff <(…pre-fpoff…$2=="strict"|sort) <(…revert-fpoff…$2=="strict"|sort)
  ✅ 排序后：复原态 strict 行与修前**逐字节相同**（8 例 × 2 模式，含 pc sha 列）
D5CBR ASSERT case=eos1 tier=strict A1非null=FAIL A2无LoCreateContext=FAIL A3长度一致=FAIL（Σ(Length−NewlineLength)=0 期望=5）
```

**随后逐字节复原成终态**：应用器 → `536f58b338a2369d`、生成物 → `a6f1b678ce87a8a2`、`pc` → **`476994e35d31a7e1`（与首次修后构建逐字节相同）** ⇒ **往返闭合**，树里 **0 残留**。

### 6.2 ② 第二极性：**真·假修的端到端读数**（`#23` 标 `NOINFO`，本件补上）

**假修的定义（§1.3 逐字）**：`ExtractRun` **返空串**而**不动 `Length` 账**。分两级取读数：

**(a) 牙级**（只把注入代码改成 `return string.Empty;`，**牙齿一根不动**）：

```
[失败] 生成物缺少结构断言：D-T5 正向：隐形 run 按 `Length` 给零宽占位（账目守恒，不是「返空串」）（'return new string(GhostChar, run.Length);'）
=== 退出码 1 ===
generated sha16（应仍是修后那次 a6f1b678ce87a8a2，即**未被写入**）=a6f1b678ce87a8a2
```

⇒ **假修当场被牙咬住**：生成 `rc=1`、**生成物根本没被写盘**（sha 不变）⇒ 假修**无法静默落地**（`#17` 那一族已关门）。

**(b) 端到端**（把代码**和那条 needle 一起**改成假修形态 —— 这正是作弊者会做的事）：`patcher cb06f2dd6f9d9eed` → 生成物 `9b43e1fe495b7a2b` → **`pc 0acc01198b5d0d36`**，`--collapsible` 读数：

| 用例 | 假修读数（原样） |
|---|---|
| `control` | `A1非null=PASS A2无LoCreateContext=PASS A3长度一致=PASS（Σ可见长=4 期望=4）` → **GREEN** |
| **`eos1`** | `A1非null=PASS A2无LoCreateContext=PASS **A3长度一致=FAIL（Σ(Length−NewlineLength)=4 期望=5）**` ⇒ **`RED-LENGTH`** |
| **`mod1`** | 同上 ⇒ **`RED-LENGTH`** |
| `hidden1`/`hiddenmid` | 同上 ⇒ **`RED-LENGTH`** |
| `hiddenonly` | 仍 `RED-EXC-LS` / `ABORT 134` |
| `mod0` | **GREEN（不变）** |
| `declaredgap` | `RED-LENGTH`（不变） |

⇒ **A3 有判别力，且形状与 §5.1 预测的假修后果逐字相同**（"源声明 5 个码元，交付只兑现 4 个"）：

| | `eos1`/`mod1` 的 A3 | 判决 |
|---|---|---|
| **真修**（零宽占位，占码元） | `Σ可见长=5 期望=5` **PASS** | **GREEN** |
| **假修**（返空串，不占码元） | `Σ可见长=4 期望=5` **FAIL** | **RED-LENGTH** |

### 6.3 `abort` 与 `null` 的可分辨性（每趟都落标记文件）

修后 `eos1`：`rc=0`、标记文件末行 `T3 done verdict=GREEN rc=0` ⇒ 探针活着；`hiddenonly`：`rc=134`、末行 `T1 before FormatLine#1 index=0 cpLength=3`（**停在第一次 `FormatLine` 之前**）⇒ **进程级 abort**，两者**没有混读**。

---

## ⑦ 我推翻 / 修正了哪句话

### ⑦.1 ⭐ §1.2 的"**其余按上游给空串**"与 §1.3 的"`eos1`/`mod1` **转绿**"**互相矛盾**；只有"占位"那一半能同时兑现

- **实测**（§6.2b）：**给空串 ⇒ `A3` 必然红**（`Σ可见长=4 ≠ 5`）⇒ `RED-LENGTH`，**不是绿**。
- **为什么**：本探针的 `A3` 口径 = `Σ(line.Length − line.NewlineLength) == CpLength`（输入段**码元总数**），`CpLength` 由**源**的 `Σ run.Length` 定死（`eos1` = 1 + 4 = 5）。**交出 4 个码元就必然对不上** —— 这是**分母决定的**，与判据宽严无关。
- **上游法律站在哪一边**：上游 Ghost run 是"**保留 `Length`（占码元）、宽度 0**"（`W23A` §⑥.1）⇒ "给空串"**丢掉了上游语义的一半**。§1.3 括号里那句"假修 = 返空串而**不动 `Length` 账**"**已经隐含**了真修必须动 `Length` 账。
- **⇒ 我的读法（已按它落地）**：§1.2 的"给空串"应读作"**不取 CBR 的字符**"，**不是"交付 0 个码元"**。落地形态 = **每个隐形 cp 一个零宽占位**（`U+200B`，理由与证据见 §③.2）⇒ `A3` PASS ⇒ **两条腿都转绿**（§1.3 的预测**字面兑现**），且真/假修在 `A3` 上**可分辨**（这正是 §1.3 第二极性**有意义**的前提）。
- **代价（如实登记）**：占位字符引入了 §③.2 的**断点偏差**；且这是**我在 §1.2 文字之外的一处自主决定**（预先无法向主控确认，故按"取更接近上游语义、且能被仓内实测支持的那一支"抉择）。

### ⑦.2 ❌ §1.3"`hidden*` 在 `--collapsible` 下也转绿"**未字面兑现**：`hiddenonly` 仍红

**实测机制（不是猜）**：

```
D5CBR DIAGafter  lenient{relaxedCalls=1 relaxedHandled=0 relaxedFailed=1 relaxedSkippedRuns=1 relaxedBlankParagraphs=0 relaxedInvisibleRuns=1 lastSkip="TextHidden x1" lastSkippedRange="[0,3) TextHidden" lastInvisible="TextHidden x3" lastFail="没有 run properties"}
D5CBR ASSERT case=hiddenonly tier=strict A1非null=FAIL A2无LoCreateContext=FAIL A3长度一致=FAIL（Σ(Length−NewlineLength)=0 期望=3）
```

`lastFail="没有 run properties"` 把我方那条 `return false` 精确点到了 `CollectLenient` 的 **`:358-363`**（"没有 run properties"）：`hiddenonly` 整段只有一个 `TextHidden(3)`，而 **`TextHidden.Properties` 是 `sealed` 且恒返 `null`**（`TextHidden.cs:62-65`），探针在段末交出的 `TextEndOfParagraph(1)` 的 `Properties` **也是 null**（`TextEndOfParagraph.cs:26` → `TextEndOfLine(length, null)` → `_textRunProperties = null`）⇒ props 取不到 ⇒ 连"空白行"都产不出 ⇒ 交回 LS ⇒ abort。
⇒ **这一族要修的是 `CollectLenient` 的 props 兜底（`W23A` §⑥.2 的选项 ②）**，而它需要把**段落属性**（`DefaultTextRunProperties`）透传进 `CollectLenient`（两个站点 + 形参表）⇒ **超出 §1.2 划定的 `ExtractRun` 写域，本件未落地**。**未压绿、未登记，等主控裁决。**
（补一条**边界事实**：`hiddenonly` 是**退化形态**——真机侧 `pf` 在**内联元素边缘**产 `TextSpanModifier`/`TextEndOfSegment` 时，同一段总还有 `TextCharacters` 正文（`ComplexLine.cs`/`LineBase.cs`）⇒ "整段皆隐"在真宿主的可达性**未测**。）

### ⑦.3 ⚠️ 更正一处**射程**：本件的零射程证**不覆盖 RTL**（我差点把它读成"无 RTL 回归"）

`tab-anchor-raw.json` 的 436 例按 `script` 分成 **288 例 latin**（= 判定集 / 421 判定行）与 **148 例 hebrew/arabic**，而**后者整整 148 例全部是 `跳过=面缺字形`**（臂日志逐例原样：`PCLINE CASE [B] C-rtl-indent/he-lead-tab-a@w40@RTL@i0@default 臂=RTL 跳过=面缺字形1`）：

| 观测 | 读数 |
|---|---|
| 被宽松档**接手**的例 | **270 例 + 缓存复用 18 例 = 288 例（= 全部 latin）**；`relaxedHandled=496` |
| 这些例里的非 `TextCharacters` run | **0**（`relaxedSkippedRuns=0`、`relaxedInvisibleRuns=0`，修前修后**同**） |
| `C-rtl-indent`（16 例）/ `A-anchor` he/ar / `D-paraindent` he 等 **148 例** | **`跳过=面缺字形`⇒ 未被任何档接手、不在判定集** ⇒ **其 run 类型本件一棵都没观测到** |

⇒ 正确的话只有两句：① **在 288 例 latin 上**"该语料没有被本修法触碰的 run 类型"（`relaxedSkippedRuns=0`）；② **RTL 半边（含 `C-rtl-indent` 16 例）本件未测**，`W23A`/`T1c` 里"非 `TextCharacters` 的 run 才是 RTL 根因"这一**历史结论本件既未证也未证伪**（`T1c` 的 R1 面未重跑）。
**⇒ 我**撤回**"这个含 RTL 的语料一个字节没变 ⇒ 无 RTL 回归"这种读法** —— §8.1 的零射程证**只对 latin 288 例成立**，RTL 已移入 §⑩ `NOINFO`。

---

## ⑧ 落盘闸门与"注册了但没生效"红线

| 检查 | 读数 |
|---|---|
| `python3 …patch-presentationcore-textline-fallback.py --check` | **`rc=0`**（`--check`，rc **不经管道**取）；13 条 `[断言]` 全 ✅；`[检查] …：内容已是最新` |
| `bash build/check-appliers.sh` | **`APPLIER_AUDIT_SUMMARY appliers=22 ok=80 miss=0 red=0 rc=0`**（**`miss=0` 是独立读数** —— `#17` 的"注册了但没生效"就死在这一列） |
| **纪律 38 红线**（再跑一次应用器） | 生成物 **`a6f1b678ce87a8a2` → `a6f1b678ce87a8a2`（逐字节不变）**；注入行仍在（`IsTextRunType` ×2 处、`GhostChar` `:116`、`relaxedInvisibleRuns=` `:67`）⇒ **不是"手改生成物被静默抹掉"** |
| `build/artifact-src-fp.py` | 修后 `PresentationCore … state=stale`（**预期**：源变了 ⇒ 需重建）；重建后跑 `--write`（= `integration-wave.sh` 3.5 步）⇒ PC/WB/PF 三件 `state=ok`（**披露**：这是我对 `build/MilBridge/.artifacts/**` 指纹文件的写入，非源改动；波尾 `close-wave` 会重写） |
| 生成物大括号/`throw`/调用点 | `{=118 }=118`；`throw` 上游 4 == 生成物 4；两处 `TryXxx(` 各 1 处 |

**零射程（同版仪器、按列对比）**：

1. **`PcLineOracle`**（`Program.cs a787a9db23c3302c`，`--leg b --tier strict/lenient`，语料 `tab-anchor-raw.json 88559d670f1bb955`，`known-red.txt 89324f1f643167e5`）：修前 `rc=1`、`判定行=421`、`红=0 绿=421 最大Δ=0.000000`；修后**同**。

   | 腿 | 修前 stdout sha16 | 修后 stdout sha16 | 逐行 diff |
   |---|---|---|---|
   | strict | `db37ce865e8b91b1` | `d4b6c3d3570371d0` | **4 行** |
   | lenient | `01a195270c95468b` | `239061b007b42f38` | **4 行** |

   **4 行差异逐字可解释**：每腿**只有** 2 行（`宽松档计数` / `正控`）**追加了新字段**，其余 **1,476 行逐字节相同**：

   ```
   < …relaxedBlankParagraphs=0 lastSkip="-" lastSkippedRange="-" lastFail="-"
   > …relaxedBlankParagraphs=0 relaxedInvisibleRuns=0 lastSkip="-" lastSkippedRange="-" lastInvisible="-" lastFail="-"
   ```

   `PCLINE START 腿=B 红=0 绿=421 … 最大Δ=0.000000`、`层级来源 严格档接手=270 / 宽松档接手=270`、436 例 `CASE` 行、`STRUCT/TWIN/NAMED/GUARD` 全同 ⇒ **判据列零射程**。
   ⚠️ **射程边界（见 §⑦.3）**：判定的只有 latin **288 例 / 421 行**；其余 **148 例（hebrew/arabic，含 `C-rtl-indent` 16 例）是 `跳过=面缺字形`**，它们的 `CASE` 行虽然逐字节相同，但**从未进入被测代码** ⇒ **本证不覆盖 RTL**。
2. **`FrameProbe`** 四条腿（修后）：`宽松档 红行 3 / 帧红 0`、`严格档 红行 3 / 帧红 0`、`--fresh-source 红行 3 / 帧红 0`、**`--prefix 40 红行 3 / 帧红 0`**（`真值非零行 421`）—— 与 `W23B-report.md` §167-170 的修后表**逐格相同**。
   ⚠️ **仪器披露（纪律 40）**：`FrameProbe` 的 dll 现在是 **`db3b321944f31a15`**（`Program.cs 503e6ebd86d70303`），**≠** `W23B` 报的 `6b65924a52a59d89`（`c6a66724a…`）⇒ **本波 P2 车道改过它** ⇒ **只能按"列相同"比，不能声称逐字节**。
3. **`D5CbrProbe` 冻结仪器未动**：`Program.cs 92694cf0c9c5d392`、dll **`117582b2a40d30c0`**（= `#23` 冻结值）。

---

## ⑨ 新 `pc` / `inputs_fp`（**全部脚本现场算**）+ 十位复算

**`inputs_fp`：`6146f3641b87a5a7d74e182ab9ca3f6f72299377bbfce2993843cb56ccbca0ca` → `a87034194a66f7d18a9903a06337ad839cae8dba2669736abbec9cd8f6dee793`**

**"哪一组子 sha 变了"（W23B 的三分组口径，脚本算）**：

| 组 | 修前 | 修后 | 变？ |
|---|---|---|---|
| **G1** `patch-*.py` + `port-lib.py` + `integration-wave.sh` + `close-wave.sh` | `31f8c41fddcf746f9cf04a2709c24ea50079acf7c49fd9c7e7ff6376c0da2b66` | **`5f862595dcaddd0d0f67a95dc3f1012ef4902e27dab7261ca5ba8935996f04bb`** | ✅ **变（唯一原因 = 本件改的那个 `patch-*.py`）** |
| G2 `build/shims/**/*.cs` | `5edc91a5ec9d6f11a6308ef768bc72fc2a07d6498662ae2b1a8bf315917ea981` | 同 | ❌ 未变 |
| G3 `src/WpfGfx.Linux/**/*.cs` | `b78e40a306be744220282b5262c8431f70b948566e4974a00038e97366d113bb` | 同 | ❌ 未变 |

⇒ **与 §5 预测"只此一个原因"逐字一致。**

| 位 | `#23` | 修后 | §5 预测 | 兑现？ |
|---|---|---|---|---|
| **`pc`** | `7b47a7b3d69ad62f` | **`476994e35d31a7e1`**（4,197,376 B，`0 警告 0 错误`，61 s） | **变** | ✅ |
| **`inputs_fp`** | `6146f364…ca0ca` | **`a8703419…e793`** | **变（只 patcher 一个原因）** | ✅ |
| **`hbtextline`** | `e89fed55fd8e32bc` | **`e89fed55fd8e32bc`（未变，290,825 B）** | **不变** | ✅ **零世代成本成立** |
| `bridge` / `BRIDGE_SRC_FP` | `d567c26f197ec1e3` / `b6acdba4f01599d8` | 同 | 不变 | ✅ |
| `pf` | `1c3fe23261c22bc6` | **`1c3fe23261c22bc6`（本件未触发重建）** | 变（**由波尾 `close-wave` 重编引起** —— 纪律 46） | 波尾裁决 |
| `windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` | — | **全部未变** | 不变 | ✅ |

**§5 位移预测表外位移：无。**

---

## ⑩ `NOINFO` 清单（**不许算绿**）

1. **应用级读数**：`run-wpfprobe.sh --only=text-rtl`（`text-rtl` 块 = `TextBlock` + `FlowDirection=RightToLeft`，纯文本 ⇒ 其 run 是 `TextCharacters`，**与本修法射程相关但未取读数**）与**应用门禁**——**未跑**（主控写域；且 §5 预测 `samples/**` **0 载体**）。⇒ 本件**不主张**应用侧任何变化。
2. **占位字符的墨迹 / 断点行为**：**无仪器**。`D5CbrProbe` 只量"有没有交出行 / 行 `Length` 账"，**不量宽度、不断点、不量墨迹** ⇒ ZWSP 的**零宽**结论来自**仓内既有语料**（§③.2）**不是本件自测**；**断点偏差**更是**未测**（已按残项登记）。
3. **`hiddenonly` 的修法**（选项 ② `props` 兜底）：未落地（§⑦.2）。
4. **严格档那一半**（shim `TryCollect` `:4513` 的 `Bail(ref BailRunType, …)`）：**本波不做**（要付世代成本）⇒ 严格档仍 **bail**（读数里的 `Δbailed=1` 就是它）——本修法**只**让第二层（宽松档）接住。
5. **RTL 射程的历史复核**：`T1c` 的 R1 面（`text-rtl`）**未重跑**；而 `tab-anchor-raw.json` 的 **148 例 hebrew/arabic（含 `C-rtl-indent` 16 例）全部 `跳过=面缺字形`、未被任何档接手** ⇒ "波 6 的空文本根因是 run 类型"这句**本件未证也未证伪**；**本件对 RTL 的行为一个字都不能主张**（§⑦.3）。
6. **`GetTextBounds` 夹取 / 帧几何 / RTL 视觉序**：与本修法无关，**未测**。
7. **`pc` 尺寸不变（4,197,376 B）的巧合**：**不是**"没重建"——`mtime 09:46→10:05`、sha 三次不同、行为三态可分辨（修前红 / 修后绿 / 假修 `RED-LENGTH`）⇒ 只是这一版 IL 体积恰好相同。
8. **`--prefix 40` 的 FrameProbe 腿耗时 >600 s**（首跑被 600 s 超时切断，改用后台作业 + 1500 s 才完成） ⇒ 若主控要把 `frame-step.sh` 接进 `verify-all`，**该腿的运行时间**要单独预算（本件实测：与另一条车道的 `FrameProbe` **并发**时约 **11 分钟**）。

---

## ⑪ readings 表（纪律 32 / 48）

| 项 | 值 |
|---|---|
| lane / 时间 | **W24A** ｜ `2026-09-17 09:31:11 → 10:15:14 +0800` |
| kernel / nproc | `6.8.0-138-generic` ｜ `3` |
| `MemAvailable` 开工 / 最低 / 收工 | **3,411 MB** / **2,197 MB** / **3,009 MB** |
| `SwapFree` 开工 / 收工 | 951 MB / 801 MB（**另两条车道同时在跑**） |
| `loadavg` 开工 / 收工 | `0.14 0.08 0.04` / `3.57 3.42 3.36` |
| 构建 | 5 趟 `pc` 重建（修后 / 假修 / 复原 / 终态 / 首次）——**串行**，均 `-m:1` + `DOTNET_gcServer=0`，各 `0 警告 0 错误`，33–61 s |
| `pc` sha（每趟读数前后） | 探针表头**逐例自报** `pc_authority_sha16` 与 `pc_local_copy_sha16`：修前 32 行 = `7b47a7b3d69ad62f`；修后 32 行 = `476994e35d31a7e1` ⇒ **读数期间未变**（探针目录内副本已 `cp -f` 同步权威件，**副本刷新 = `integration-wave.sh` 3.6 步的行为**，非改仪器源码） |
| **并发交底（纪律 48）** | 10:02–10:15 期间另有一条车道（**W24B**）在跑 `FrameProbe --leg b --tier lenient/strict/--prefix 40`（PID `521406`/`521831`/`521666`/`522121`，cwd 与语料见 `pgrep -a`；其中一条用 `/home/links-dev/w24b-run/corpus-truthmut.json`）——**不是我的**。我的 `FrameProbe` 读数与之**并发**取得（同仪器、同 pc 副本）。我**未** `pkill`，未打扰。 |
| 我改过的仓内文件 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`、由它生成的 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`、重建的 `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`、**两处测试目录内的 `pc` app-local 副本**（`D5CbrProbe`/`PcLineOracle`/`FrameProbe`，`cp -f` 同步权威件）、`build/MilBridge/.artifacts/**` 指纹（`artifact-src-fp.py --write`）、本报告 |
| **未碰** | `build/shims/**`（**一个字节**）、`known-red.json`、`tline-gate.sh`、`verify-all.sh`、`arm-logs/**`、`PcLineOracle/**`（源码）、`CoverageProbe/**`、`tests/**`、`samples/**`、`docs/**`、`verify-all` |

## ⑫ 产物清单

| 件 | sha16 | 尺寸 |
|---|---|---|
| `build/MilBridge/W24A-report.md`（本文件） | **文件内自指会改变自身哈希 ⇒ 不写入**；sha16/行数/尺寸在交付回复里给出（`sha256sum` 现场算） | — |
| `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` | `536f58b338a2369d` | 61,044 B |
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | `a6f1b678ce87a8a2` | 60,034 B |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `476994e35d31a7e1` | 4,197,376 B |
| 留档（`$HOME/w24a-pre/`） | 原件 patcher / 原件生成物 / 修前 `pc` / 终态 patcher | — |
| 读数（`$HOME/w24a-run/`） | `pre-fpon` `pre-fpoff` `Y-fpon` `Y-fpoff` `Y2-*` `fake-fpoff` `revert-fpoff` `pre-pcline` `post-pcline` `frameprobe` | — |

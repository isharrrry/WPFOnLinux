# W23A 报告 —— `#23` §1 P1：`D-T5` 判据 + 红读数 + 修法设计（**只测不修**）

> **lane=W23A** ｜ 起 `2026-09-16 23:55:11 +0800` ｜ 讫 `2026-09-17 00:2x +0800` ｜ **kernel `6.8.0-138-generic`** ｜ `nproc=3`
> `loadavg` 开工 `0.35 0.26 0.11` ／ 收工 `2.99 2.74 2.24`
> **`MemAvailable`** 开工 **`3,150,156 kB`（3,076 MiB）** ／ 最低（开工那一读；**本件未连续监控，只在下面几处取样**）**3,076 MiB** ／ 收工 **`3,624,348 kB`（3,539 MiB）**；`SwapFree` 收工 `1,089,276 kB`
> 全程 `-m:1` + `DOTNET_gcServer=0`，**未跑** `wpf-linux.sln`、**未跑** `verify-all`、**未并发两个构建**；**只构建了自己新建的探针工程**。
> 收工前按 PID 查：**没有留下我自己的 `dotnet`/MSBuild 进程**（`pgrep -a dotnet` 只剩**别的车道** W23B 的 `FrameProbe`，我未碰）。全程**未执行** `pkill -f`。
>
> ⚠️ **行号口径**：本报告里**生成物**（`TextFormatterImp.Linux.cs` = `fef2cfb47f882a82`）与**应用器**（`patch-presentationcore-textline-fallback.py` = `00c2179b87fc0509`）的行号**一律是当前文件**（两者都在 `2026-09-17 00:12` 被 W23B 重生成过 ⇒ 与本件早期临时读数里的行号**有 +2 一类的小偏移**）。**引用时请连 sha16 一起引。**

---

## ① 一句话判决

**`D-T5` 成立且是进程级 abort —— 但在**默认配置**下它比在册更**窄**：`TextModifier` 与 `TextEndOfSegment` 会 abort（`rc=134`），而 **`TextHidden` 不会**（被 `SimpleTextLine` 快路径当 Ghost run 正常处理，逐位正确）。只有**关掉快路径**（`AlwaysCollapsible=true`）时 `TextHidden` 才落进 `D-T5`。**

三条独立读数：

| 输入 | 快路径**开**（产品缺省姿势） | 快路径**关**（`--collapsible`） |
|---|---|---|
| `control`（纯 `TextCharacters`） | **GREEN** | **GREEN**（严格档接手，正控活） |
| `eos1`（`TextEndOfSegment(1)`） | **`RED-EXC-LS` / `rc=134`** | **`RED-EXC-LS` / `rc=134`** |
| `mod1`（`TextModifier(1)`） | **`RED-EXC-LS` / `rc=134`** | **`RED-EXC-LS` / `rc=134`** |
| `hidden1`/`hiddenmid`/`hiddenonly`（`TextHidden`） | **GREEN**（**不是** `D-T5`） | **`RED-EXC-LS` / `rc=134`** |
| `mod0`（`Length=0` modifier） | `RED-EXC`（快路径拒零长 run） | **GREEN**（宽松档接手 —— 唯一能过 `ExtractRun` 的形态） |

**abort 与「产品返回 null」已经可分辨**（§③，由 `--selftest abort|null` 两极化**先验过判读逻辑**才敢这么说）。

---

## ② 探针设计与装置自证

### ②.1 新建了什么（**未改** `PcLineOracle` / `CoverageProbe` 一个字节）

| 件 | sha16 | 大小 | mtime |
|---|---|---|---|
| `build/MilBridge/tests/D5CbrProbe/D5CbrProbe.csproj` | **`212df5f87cdf2542`** | 4,483 | 2026-09-16 23:56:58 |
| `build/MilBridge/tests/D5CbrProbe/Program.cs` | **`92694cf0c9c5d392`** | 38,405 | 2026-09-17 00:17:45 |
| 产物 `bin/Release/PresentationCore.Tests.dll`（**冻结仪器**） | **`117582b2a40d30c0`** | 23,040 | 2026-09-17 00:17:49 |

**禁改件未被触碰**（只读复核）：`PcLineOracle/Program.cs` = `a787a9db23c3302c`（车道 W21A 的产物，非我改）、`CoverageProbe/Program.cs` = `421fe394bea93fe2`、`known-red.json` = **`2fdc02931c2af796`**（= `#23` 预登记值）、`verify-all.sh` = `279b958dda238447`、`build/shims/**`、`build/PresentationCore.Linux/**`、`arm-logs/` **全部未动**。

工程形态照抄 `PcLineOracle.csproj`：`AssemblyName=PresentationCore.Tests` + 同一把公钥公开签名（借 IVT 读两档 internal 计数器）＋ `HintPath` 指向三份权威产品件 ＋ **`<Import Project="$([MSBuild]::GetPathOfFileAbove('BuildHygiene.props'))" />`**（`D-R8`）。`dotnet build -c Release -m:1` ⇒ **`0 个警告 / 0 个错误`**。

### ②.2 三种 `TextSource` + 阳性对照（判据分母口径，纪律 39）

`CpLength` = **源里全部 run 的 `Length` 之和**（零长标记贡献 0）。`Σ(line.Length − line.NewlineLength)` 必须等于它。

| 用例 | run 序列 |
|---|---|
| `control` | `[TextCharacters L=4]@0` ← **阳性对照** |
| `eos1` | `[TextEndOfSegment L=1]@0 [TextCharacters L=4]@1` |
| `hidden1` | `[TextHidden L=1]@0 [TextCharacters L=4]@1` |
| `mod1` | `[TextModifier L=1]@0 [TextCharacters L=4]@1` |
| `hiddenmid` | `[TextCharacters L=2]@0 [TextHidden L=1]@2 [TextCharacters L=2]@3` |
| `hiddenonly` | `[TextHidden L=3]@0`（整段皆隐的退化形态） |
| `mod0` | `[TextModifier L=0]@0` + 同一下标 `[TextCharacters L=4]@0` |
| `declaredgap` | `[TextCharacters L=4]@0` **但分母声明为 5** ← **断言牙齿对照（非产品用例）** |

两条腿 = `--tier strict`（`WPF_LINUX_TEXTLINE_FALLBACK` 清空）/ `--tier lenient`（置 `0`），**层级来源自证**：严格档 `HbTextFallback.{Enabled,Calls,Handled,Bailed,BailRunType,LastBail}`（**直接字段访问 = 编译期证据**）× 宽松档 `WpfLinuxLenientTextFallback.Diagnostics`（**命名空间是 `MS.Internal.TextFormatting`，与严格档的 `WpfLinux.Shims.PresentationCore` 正好相反 —— 两处现场各读一次，未照抄**）。两档都零增量 ⇒ 印 **`NOINFO`**，**不读成绿**。

### ②.3 ⭐ 机制判别器：`--collapsible`

生成物 **`:556-559`** 逐字：

```
556:            if (    !settings.Pap.AlwaysCollapsible
557:                &&  previousLineBreak == null
558:                &&  lineLength <= 0
559:                )
```

即**快路径 `SimpleTextLine.Create` 只在 `AlwaysCollapsible=false` 且无前次断行时生效**。`--collapsible` 把 `AlwaysCollapsible` 置 `true` ⇒ **逼被测 run 走三层托管档**。同一个用例在开/关两条读数上分开 ⇒ **"谁处理了它"是读数，不是推断**。

### ②.4 ⭐⭐ 仪器缺陷自记（**本件最重要的一条自纠**）

第一版的 `ScriptedTextSource.GetTextRun(cp)` 按**"同一个 `cp` 被问第几次"依次交出 run**。后果（`--trace-source` 原始读数）：

```
D5CBR SRC  GetTextRun#1(cp=0) → TextEndOfSegment(L=1) CBR=null
D5CBR SRC  GetTextRun#2(cp=0) → TextEndOfParagraph(L=1) CBR=null   ← **不是被测的那个 run**
```

⇒ 严格档 bail 之后，**宽松档在同一个 `cp` 上再问一次，拿到的是下一个 run** ⇒ 宽松档看到的第一个 run 变成 `TextEndOfParagraph` ⇒ 走的是**"空段落 + 无 props"**那条分支（`lastFail="空段落且没有 run properties ⇒ 连空白行都产不出"`），**而不是 `D-T5` 的在册机制**。

> **判决（红）照样是对的，归因是错的** —— 这正是本项目最怕的「仪器缺陷假归因」。**若不修，本报告 §① 的"机制"一栏全是假的。**

**修法**：`GetTextRun(cp)` 必须**幂等**（真实 `TextSource` 就是这样；`Length ≥ 1` 的 run 逐个消费码元，一个 `cp` 只属于一个 run）。唯一**刻意**保留非幂等的是 `mod0`（**零宽**标记不消费字符，同一下标再问才拿到正文；`W17D-report.md:157` 逐字写明这是合法姿势），用显式开关 `StatefulZeroWidth`，**不许**成为默认。

**修后的归因（与在册机制逐字吻合，产品自己的诊断行）**：

```
[TEXTLINE_RELAXED] **即将交回 LS**（Linux 上等于 abort）原因：CharacterBuffer 取不到（run 类型 TextEndOfSegment） ｜ skipped=0 lastSkip=-
```

这正是生成物 **`:151-155`**：「`ExtractRun` 见空 CBR 返 null ⇒ `CollectLenient` `return false`」。

**另两条仪器自记（已修，留档）**：
1. **A3 分母口径错**：第一版拿 `Σ line.Length` 与 `CpLength` 比 ⇒ **阳性对照自己变红**（`control`：`Σlen=5` 期望 `4`，5 = 4 字符 + 1 个 `TextEndOfParagraph`）。`line.Length` **含行尾符** ⇒ 改为 `Σ(Length − NewlineLength)`（`PcLineOracle:786-789` 同款口径）。**没有这一条自证，本探针会把"装置活着"读成"产品红"。**
2. **归因行截断**：第一版按第一个空格截断 `key="…"` ⇒ 打成 `lastBail="run"`（真值 `lastBail="run 类型 TextEndOfSegment 不支持"`）⇒ 改成引号内取值。

### ②.5 ⭐ 机器证：**X 不是本仪器的输入**（主控硬要求）

同一单例、同一份 `pc`，三种 X 状态各跑一次：`:0`（宿主自己的 display，**仅这一次证明里碰**）／`unset`／`:97`。

```
CASE       DISPLAY  RC       RAW_SHA16              NORM_SHA16             IDENTICAL
control    :0       0        2c11a9921e390dfa       aa88366d2aa3af11       YES
control    UNSET    0        c389a56eec3b550a       aa88366d2aa3af11       YES
control    :97      0        2d07dcadb648bfc3       aa88366d2aa3af11       YES
eos1       :0       1        d102973b17542613       7884cccaad434b83       YES
eos1       UNSET    1        04c414a6f0718283       7884cccaad434b83       YES
eos1       :97      1        ccb218e90e22c102       7884cccaad434b83       YES
hidden1    :0       1        6d0697593b35f011       e2d7172dab576c1c       YES
hidden1    UNSET    1        e72470913a287115       e2d7172dab576c1c       YES
hidden1    :97      1        5fea12653126c43e       e2d7172dab576c1c       YES
# X_INVARIANT=YES
```

**归一化声明（可复算）**：探针自报行含 `pid=<digits>`，**每次进程必然不同、与 X 无关** ⇒ 比对前 `sed -E 's/pid=[0-9]+/pid=PID/g'`，**只动这一个字段**。
**更强的证据**：`diff <(归一化 :0) <(归一化 unset)` 与 `diff <(归一化 :0) <(归一化 :97)` **三例全部无输出**；原始文件的逐行 `diff` **只出现 pid 数字差异**（`pid=328887` vs `pid=328910`）。
⇒ 主判据读数**一律 `unset DISPLAY`**（脚本 `run-matrix.sh:18`）。**`:97` 由主控重启、我未自起 Xvfb**。

### ②.6 崩溃取证：**一例一进程** + **调用前先落盘**

`run-matrix.sh` 对 `case × tier × mode` 的每一个组合**单起进程**（一例 abort 不带走别的），探针在**每次 `FormatLine` 之前**先 `FileStream.Flush(true)` 落一行相位标记。

---

## ③ ⭐ 「探针自己 abort」与「产品返回 null」**可分辨性证明**

**先验过判读逻辑**（纪律 25：判据本身要有正控）——`--selftest abort` / `--selftest null` 两极化：

| 自证 | `rc` | stdout 判词 | 标记文件末行 |
|---|---|---|---|
| `--selftest abort`（`libc abort()`） | **134** | **无** `VERDICT` | `T1 about-to-abort`（**无 `T3` 收尾**） |
| `--selftest null` | **1** | `verdict=RED-NULL` | `T3 done verdict=RED-NULL` |

**⇒ 三元判读（本件实际使用的规则）**：

| 观察 | 判读 |
|---|---|
| `rc=134` 且标记文件**无 `T3` 收尾行** | **进程被 abort 带走**（探针没机会说话） |
| `rc∈{0,1,2}` 且有 `D5CBR VERDICT …` | **探针活着**，判词是产品行为（含 `RED-NULL`） |

**现场读数（`eos1`，快路径关，`--tier strict --nocatch`）**：

```
rc=134
Unhandled exception. System.EntryPointNotFoundException: Unable to find an entry point named 'LoCreateContext' in shared library 'PresentationNative_cor3.dll'.
   at MS.Internal.TextFormatting.UnsafeNativeMethods.LoCreateContext(LsContextInfo& contextInfo, LscbkRedefined& lscbkRedef, IntPtr& ploc)
   at System.Windows.Media.TextFormatting.TextFormatterContext.Init() in …/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Media/textformatting/TextFormatterContext.cs:line 113
--- marker ---
T0 enter case=eos1 tier=strict collapsible=True
T1 before FormatLine#1 index=0 cpLength=5
```

**标记停在第一次调用之前** ⇒ 死点是**第一次 `FormatLine`**，**不是**"没跑过"，**也不是**"返回 null"。
`--nocatch` 是**应用路径的忠实模拟**（`#22` 实测：生成物 → `WpfTextDemo` 主循环**逐层无 catch**）：**catch 版**证明"抛了什么"，**nocatch 版**证明"应用会怎样"，**两条腿都取，未只取其一**。
**本族在 catch 版下永远看不到 `RED-NULL`** —— 因为 LS 回退**必然先抛**（`ExtractRun` null ⇒ 宽松档 false ⇒ 构造 `FullTextLine`）。

---

## ④ 逐例读数（**冻结仪器 `117582b2a40d30c0`**）

**`pc` = `7b47a7b3d69ad62f`（权威）＝探针目录内副本，逐位一致**；两趟共 **128** 个 before/after 采样**全是这一个值** ⇒ **读数期间 `pc` 未变**（见 §⑧ 的并发交底）。

### 4.1 快路径**关**（`--collapsible`；`D-T5` 可达）—— `F-fpoff/MATRIX.tsv`

| 用例 | strict/catch | strict/nocatch | lenient/catch | lenient/nocatch |
|---|---|---|---|---|
| `control` | **GREEN (0)** | GREEN (0) | **GREEN (0)** | GREEN (0) |
| `eos1` | **RED-EXC-LS (1)** | **ABORT (134)** | **RED-EXC-LS (1)** | **ABORT (134)** |
| `hidden1` | **RED-EXC-LS (1)** | **ABORT (134)** | **RED-EXC-LS (1)** | **ABORT (134)** |
| `mod1` | **RED-EXC-LS (1)** | **ABORT (134)** | **RED-EXC-LS (1)** | **ABORT (134)** |
| `hiddenmid` | **RED-EXC-LS (1)** | **ABORT (134)** | **RED-EXC-LS (1)** | **ABORT (134)** |
| `hiddenonly` | **RED-EXC-LS (1)** | **ABORT (134)** | **RED-EXC-LS (1)** | **ABORT (134)** |
| `mod0` | **GREEN (0)** | GREEN (0) | **GREEN (0)** | GREEN (0) |
| `declaredgap`（牙齿） | **RED-LENGTH (1)** | RED-LENGTH (1) | **RED-LENGTH (1)** | RED-LENGTH (1) |

### 4.2 快路径**开**（产品缺省姿势）—— `F-fpon/MATRIX.tsv`

| 用例 | strict/catch | 说明 |
|---|---|---|
| `control` | **GREEN (0)** | 快路径处理（两档零增量） |
| `eos1` | **RED-EXC-LS (1)** / nocatch **134** | `TextEndOfSegment` 不被快路径接受 |
| `mod1` | **RED-EXC-LS (1)** / nocatch **134** | 同上 |
| `hidden1` / `hiddenmid` / `hiddenonly` | **GREEN (0)** | **`SimpleTextLine` 处理，`D-T5` 不成立** |
| `mod0` | `RED-EXC (1)` / nocatch **134** | `ArgumentOutOfRangeException: textRun.Length ('0') must be a non-negative and non-zero value.` |
| `declaredgap` | RED-LENGTH (1) | 牙齿对照 |

### 4.3 逐例**层级归因**（原样摘录，`strict/catch`）

```
D5CBR ATTR  case=control tier=strict 接手链=严格档**接手** ｜ 严格档 Δcalls=1 Δhandled=1 Δbailed=0 lastBail="-" ｜ 宽松档 Δcalls=0 Δhandled=0 Δfailed=0 lastFail="-"
D5CBR ATTR  case=eos1 tier=strict 接手链=严格档bail ⇒ 宽松档fail ⇒ **交回 LineServices**（Linux 上=abort） ｜ 严格档 Δcalls=1 Δhandled=0 Δbailed=1 lastBail="run 类型 TextEndOfSegment 不支持" ｜ 宽松档 Δcalls=1 Δhandled=0 Δfailed=1 lastFail="-"
D5CBR ATTR  case=hidden1 tier=strict 接手链=严格档bail ⇒ 宽松档fail ⇒ **交回 LineServices**（Linux 上=abort） ｜ 严格档 Δcalls=1 Δhandled=0 Δbailed=1 lastBail="run 类型 TextHidden 不支持" ｜ 宽松档 Δcalls=1 Δhandled=0 Δfailed=1 lastFail="-"
D5CBR ATTR  case=mod1 tier=strict 接手链=严格档bail ⇒ 宽松档fail ⇒ **交回 LineServices**（Linux 上=abort） ｜ 严格档 Δcalls=1 Δhandled=0 Δbailed=1 lastBail="run 类型 ProbeModifier 不支持" ｜ 宽松档 Δcalls=1 Δhandled=0 Δfailed=1 lastFail="-"
D5CBR ATTR  case=hiddenonly tier=strict 接手链=严格档bail ⇒ 宽松档fail ⇒ **交回 LineServices**（Linux 上=abort） ｜ 严格档 Δcalls=1 Δhandled=0 Δbailed=1 lastBail="run 类型 TextHidden 不支持" ｜ 宽松档 Δcalls=1 Δhandled=0 Δfailed=1 lastFail="-"
D5CBR ATTR  case=mod0 tier=strict 接手链=严格档bail ⇒ 宽松档**接手** ｜ 严格档 Δcalls=1 Δhandled=0 Δbailed=1 lastBail="run 类型 ProbeModifier 不支持" ｜ 宽松档 Δcalls=1 Δhandled=1 Δfailed=0 lastFail="-"
D5CBR ATTR  case=declaredgap tier=strict 接手链=严格档**接手** ｜ 严格档 Δcalls=1 Δhandled=1 Δbailed=0 lastBail="-" ｜ 宽松档 Δcalls=0 Δhandled=0 Δfailed=0 lastFail="-"
```

**关键**：严格档 `Δcalls=1 Δhandled=0 Δbailed=1` ⇒ 它**看过了、没接**（bail），**不是"没走到"**；宽松档 `Δcalls=1 Δhandled=0 Δfailed=1` ⇒ 它**也接不了**。**两条腿的增量都点名**，所以"交回 LS"不是推断。

### 4.4 断言逐条（`eos1`，快路径关，原样摘录）

```
D5CBR DIAGafter  strict{fallbackCalls=1 fallbackHandled=0 fallbackBailed=1 bailRunType=1 bailFont=0 bailEmpty=0 bailLong=0 bailException=0 lastBail="run 类型 TextEndOfSegment 不支持"}
D5CBR DIAGafter  lenient{relaxedCalls=1 relaxedHandled=0 relaxedFailed=1 relaxedSkippedRuns=0 relaxedBlankParagraphs=0 lastSkip="-" lastSkippedRange="-" lastFail="-"}
D5CBR ASSERT case=eos1 tier=strict A1非null=FAIL A2无LoCreateContext=FAIL A3长度一致=FAIL（Σ(Length−NewlineLength)=0 期望=5）
D5CBR VERDICT case=eos1 tier=strict verdict=RED-EXC-LS 行数=0 Σlen=0 Σnl=0 Σ可见长=0 期望=5 GetTextRun次=2 异常=EntryPointNotFoundException: Unable to find an entry point named 'LoCreateContext' in shared library 'PresentationNative_cor3.dll'.
D5CBR_EXIT=1
```

**三条断言全红**（A1 交不出行、A2 出现 `LoCreateContext`、A3 长度不一致）。`rc` 与判词一致（`D5CBR_EXIT=1` 且 `Environment.ExitCode=1`）—— 第一版只打判词不设退出码，已修。

---

## ⑤ 第二极性（防作弊）：**假装修好之后，哪一条仍必须红**

### 5.1 假修的后果（逐层推演，引当前文件行号）

生成物 **`:85`**：`if (run == null || run.Length <= 0) return string.Empty;`、**`:88`**：`if (buf == null) return null;`。
把 `:88` 改成「**假装修好**」（`return string.Empty;`）之后：

| 用例 | 结果 |
|---|---|
| `eos1` / `hidden1` / `mod1` / `hiddenmid` | `ExtractRun` 返**空串**（不是 null）⇒ `CollectLenient` **不再 return false** ⇒ 收集串 = `"WWWW"`（**4** 个码元），而**分母 `CpLength` = 5** ⇒ **A3 `RED-LENGTH`（Σ可见长=4 ≠ 5）** |
| `hiddenonly` | 收集串 = `""` ⇒ 落到 `:342` 的"空段落"分支，`props == null`（`TextHidden.Properties` **sealed 返 null**，`TextHidden.cs:62-65`）⇒ `++s_failed` ⇒ `return false` ⇒ **A2 仍红**（照样 abort） |

⇒ **必须仍红的断言 = A3（长度一致）**，且 `hiddenonly` 这一类**连 A2 都仍红**。

### 5.2 这一条**已实测兑现**（不是推演）

因为 `mod0`（`Length=0`）走的就是**「`ExtractRun` 返空串」那条现成的代码路径**（`:85` 的 `Length <= 0` 分支），它是"假修"的**天然代理**：

```
D5CBR ATTR  case=mod0 tier=strict 接手链=严格档bail ⇒ 宽松档**接手** … 宽松档 Δcalls=1 Δhandled=1 Δfailed=0
D5CBR ASSERT case=mod0 tier=strict A1非null=PASS A2无LoCreateContext=PASS A3长度一致=PASS（Σ(Length−NewlineLength)=4 期望=4）
```

`mod0` **绿**，恰恰因为**零长标记对 `CpLength` 贡献 0**（分母也是 4）⇒ 账是平的。

**⇒ 由此得到本件第二条独立判据（牙齿对照 `declaredgap`）**：把分母声明成比源多 1，A3 **在 A1/A2 都 PASS 的情况下单独变红**：

```
D5CBR ASSERT case=declaredgap tier=strict A1非null=PASS A2无LoCreateContext=PASS A3长度一致=FAIL（Σ(Length−NewlineLength)=4 期望=5）
D5CBR VERDICT case=declaredgap tier=strict verdict=RED-LENGTH 行数=1 Σlen=5 Σnl=1 Σ可见长=4 期望=5 GetTextRun次=2 #1=5/nl1 异常=-
```

**这个红的形状与 §5.1 预测的假修后果逐字相同**（"源声明 5 个码元，交付只兑现 4 个"）⇒ **A3 不是空断言，且它正是假修必须撞上的那一条**。

### 5.3 `NOINFO`（不许编）

**"真的把 `:88` 改成假修再跑"这件事本件未做** —— 它要改**产品件**（生成物 / patcher），而本件是**只测不修**（§1.2）。⇒ 上面 §5.1 是**代码级引文 + 代理实测（`mod0`/`declaredgap`）**，**不是**端到端的假修读数。**可执行方案**（下一波照做即可）：

```bash
# 在 patcher 的注入块里把 `return null` 换成 `return string.Empty`（见 §⑥.4 的落点）
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py --check   # 牙齿是否仍过
bash build/integration-wave.sh            # 重生成 + 重编 pc
dotnet build build/MilBridge/tests/D5CbrProbe/D5CbrProbe.csproj -c Release -m:1
CASES="eos1 hidden1 mod1 hiddenmid hiddenonly mod0 declaredgap" EXTRA=--collapsible \
  LABEL=fake-fix bash ~/w23a-run/run-matrix.sh <outdir>
# 判据：**必须仍是 RED-LENGTH，不得是 GREEN**；hiddenonly 必须仍是 RED-EXC-LS
```

---

## ⑥ 修法逐层方案（**只写，不施加**）

### ⑥.1 ⭐ 上游真机对「空 CBR 的 `TextModifier`/`TextHidden`/`TextEndOfSegment`」是什么行为？

**上游**从不 deref 这些 run 的 CBR —— 它**先分类、再取字符**。三条源码引注：

**(1) 分类器**：`upstream/…/PresentationCore/MS/internal/TextFormatting/TextProperties.cs:396-412`

```
396:        internal static Plsrun GetRunType(TextRun textRun)
397:        {
398:            if (textRun is ITextSymbols || textRun is TextShapeableSymbols)
399:                return Plsrun.Text;
401:            if (textRun is TextEmbeddedObject)
402:                return Plsrun.InlineObject;
404:            if (textRun is TextEndOfParagraph)
405:                return Plsrun.ParaBreak;
407:            if (textRun is TextEndOfLine)
408:                return Plsrun.LineBreak;
410:            // Other text run type are all considered hidden by LS
411:            return Plsrun.Hidden;
412:        }
```

⇒ **`TextHidden`、`TextModifier`、`TextEndOfSegment`、乃至任何非上述类型的 run 一律 = `Plsrun.Hidden`**（`:410` 的注释逐字：「Other text run type are all considered hidden by LS」）。

**(2) 取字符**：`…/MS/internal/TextFormatting/FormatSettings.cs:180-254`

```
192:            switch (TextRunInfo.GetRunType(textRun))
193:            {
194:                case Plsrun.Text:
196:                    CharacterBufferReference charBufferRef = textRun.CharacterBufferReference;
198:                    charString = new CharacterBufferRange(
199:                        charBufferRef.CharacterBuffer,
200:                        charBufferRef.OffsetToFirstChar + offsetToFirstCp,
201:                        runLength
202:                        );
241:                case Plsrun.Hidden:
242:                    unsafe
243:                    {
244:                        charString = new CharacterBufferRange((char*) TextStore.PwchHidden, 1);
245:                    }
246:                    break;
248:                default:
249:                    charString = CharacterBufferRange.Empty;
```

⇒ **只有 `Plsrun.Text` 才 deref `CharacterBuffer`（`:196-202`）**。`Plsrun.Hidden` 拿的是**哨兵字符** `TextStore.PwchHidden`（`:244`，声明于 `TextStore.cs:2393`、由 `esc.szHidden` 赋值于 `TextStore.cs:86`；消费点 `TextStore.cs:1616`）。

**(3) 快路径**：`…/MS/internal/TextFormatting/SimpleTextLine.cs:1559-1563`（我方逐字移植 = **`build/PresentationCore.Linux/SimpleTextLine.Linux.cs:1703-1707`**）

```
1559:            else if (textRun is TextHidden)
1560:            {
1561:                // hidden run
1562:                run = new SimpleRun(runLength, textRun, Flags.Ghost, settings.Formatter, pixelsPerDip);
1563:            }
```

**(4) 三种 run 的 CBR 为什么**必然**空**（sealed，构造期强制 `Length ≥ 1`）：
`TextHidden.cs:33` `ArgumentOutOfRangeException.ThrowIfNegativeOrZero(length);` + `:44-47` `public sealed override CharacterBufferReference CharacterBufferReference { get { return new CharacterBufferReference(); } }`；
`TextEndOfSegment.cs:31` + `:42-45` **逐字同形**；
`TextModifier.cs:25-28` **同形**（`Length` 与 `Properties` 在 `TextRun.cs:82/89` 是 abstract，由子类给）。

> **⇒ 上游法律（一句话）**：**空 CBR 的 `TextHidden`/`TextModifier`/`TextEndOfSegment` 是"合法的隐形 run"** —— 保留 `Length`（占码元）、宽度为 0（Ghost）、**绝不 deref CBR**。我方缺陷 = **在分类之前就 deref 了 CBR**。

### ⑥.2 逐层选项与代价

| 层 | 落点（当前行号） | 改什么 | 写域 | 代价 |
|---|---|---|---|---|
| **① `ExtractRun`** | patcher `:241-249`（生成物 `:83-94`，关键行 `:88`） | 让它**先按 run 类型分类**：`TextCharacters`（或 `ITextSymbols`）才取 CBR；其余按上游给**空串 + 记一次 skip**（宽度天然 0，因为不产字形） | ⛔ **生成物（应用器）** | **不付世代成本**（不动 shim） |
| **② `CollectLenient`** | patcher `:261+`（生成物 `:103+`），`:115-190` 的记账与"空段落"分支 | 若只改 ① 则 ② 可能**不必动**；只有"整段皆隐"（`hiddenonly`）仍需 ② 的 `props == null` 兜底（`TextHidden.Properties` **恒 null**，`TextHidden.cs:62-65`）⇒ 用 `DefaultTextRunProperties` 兜 | ⛔ **生成物（应用器）** | 同上 |
| **③ 严格档 `TryCollect`** | shim `:4487-4520`（`Bail(ref BailRunType, "run 类型 … 不支持")` @ `:4513`） | 让严格档也接受隐形 run（占位不产字形） | ✅ **`build/shims/**`** | **要付世代成本**（五臂重取 + `known-red.json` 重钉），**与 P2 同族可合并** |
| **④ LineServices 回退** | 生成物 `:628` | **不动**（"接不了就原样回落"是设计；改了就是"搬异常"） | — | — |

**判据取在哪一层**：**本探针（`D5CbrProbe`）取在应用级入口**（`TextFormatter.Create()` + `FormatLine`）—— 这是**唯一**能同时看到"谁接手""交出行没""进程有没有 abort"的一层。**只改 ①/②（不付世代成本）就足以让本探针全绿**；③ 是"严格档也能接"的**加固**，可以后置。

### ⑥.3 ⛔ 修 ①/② 必须改**应用器**，不许手改生成物（纪律 38）

生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（当前 **`fef2cfb47f882a82`**，56,380 B，2026-09-17 00:12:27）**每波被 `build/integration-wave.sh:161` 的 `patch-presentationcore-textline-fallback` 整份重生成** ⇒ 手改会被**静默抹掉**，而且**所有绿判据都不会红**。

**注入块落点**：应用器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`（当前 **`00c2179b87fc0509`**，54,344 B，2026-09-17 00:12:26）：

| 项 | 位置 |
|---|---|
| 注入块 = **`REPLACEMENT_3`**（`r"""` 字符串） | **`:186` – `:507`**（`ANCHOR_3` = `:184` 的 `'    internal sealed class TextFormatterImp : TextFormatter\n'`） |
| `ExtractRun`（**①的主落点**） | patcher **`:241-249`**，关键行 **`:246`** = `if (buf == null) return null;` |
| `DiagBeforeReturn` | patcher **`:254`** |
| `CollectLenient`（**②的主落点**） | patcher **`:261`** 起；空段落分支 **`:342`** 一带 |
| 站点 1 / 站点 2 派发块 | `REPLACEMENT_4` `:515`、`REPLACEMENT_5` `:549` |

### ⑥.4 ⚠️ needle / 计数牙齿**要不要跟着改**（逐条，主控要求）

**结论：改 ①/② 会碰到 4 条牙齿，必须一并处理。**（全部在 `REQUIRED_IN_OUTPUT` `:568` 起 + 计数断言 `:803-808` + `throw` 守恒 `:811-813`）

| # | 牙齿 | 位置 | 改 ①/② 会不会碰 | 处理 |
|---|---|---|---|---|
| 1 | `("宽松兜底：**跳过**而不是 bail（关键放宽）", "++skipped;")` | `:577` | **会** —— 若把"隐形 run"改成**不计数**地跳过，`++skipped;` 消失 ⇒ **牙齿立刻报错** | **保留 `++skipped;`**（隐形 run 仍算"放宽了一类 run"）；否则同步改 needle |
| 2 | `("**任何 run 都取字符**（不再只认 TextCharacters）", "private static string ExtractRun(TextRun run)")` | `:581` | **不改名就不碰**；但**这条 needle 的语义会被推翻**（改后恰恰**只认**能取到字符的 run） | **必须改文案/或加一条新 needle**，否则牙齿在为一个被推翻的命题背书（同 `L25`/`ProviderShapeTests` 家族：**把缺陷写成预期**） |
| 3 | `("**空文本不再交回 LS**（改成空白行 + 计数）", "绝不因为\"空文本\"交回 LS")` | `:582` | **会** —— 它是**注释文本** needle，落在 `:342` 的注释里 | 改 ② 的注释 ⇒ **同步改 needle** |
| 4 | `("**进入 return false 之前先诊断**", "private static void DiagBeforeReturn(string why)")` | `:585` | **会** —— 若 ①/② 之后"这条路不再 `return false`"，方法可能被删/改名 | **保留该方法**（它仍服务别的 `return false` 分支）或同步改 needle |
| 5 | `:583` `relaxedBlankParagraphs=`、`:584` `lastSkippedRange=` | `:583-584` | 不碰（Diagnostics 串仍在） | — |
| 6 | **计数牙齿**：两个 `WpfLinuxLenientTextFallback.TryXxx(` 各**恰好 1** 处 | `:803-807` | **会** —— 若新修法**新增**一个调用点就破 | 保持调用点数不变 |
| 7 | **`throw` 守恒**：上游 `throw ` 条数 == 生成物 | `:811-813` | **会** —— 任何"改成抛一个清晰异常"的设计**当场破** | ⇒ **修法不许引入 `throw`**（上游是"当隐形 run 处理"，本来也不需要抛） |

### ⑥.5 现状基线（**实测**，供改前/改后对照）

```
$ python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py --check
CHECK_RC=0        # [断言] 条数 = 12
```

其中与本节直接相关的两条**原样摘录**：

```
[断言] LS 站点数 = 2（两处都被 ①shim ②宽松兜底 包住）；宽松兜底调用各 1 处
[断言] `throw` 条数 上游 4 == 生成物 4
[断言] W23-B 段落原点：宽松兜底透传 `paragraphOrigin: cpFirst` = 1（要求 1）✅
```

⇒ `throw` 守恒是**活的**（上游 4 == 生成物 4），所以 §⑥.4 第 7 条（**修法不许引入 `throw`**）不是推测。

**⇒ 给主控的建议（写死）**：① 改 patcher 的 `REPLACEMENT_3` 之内 `ExtractRun` 的 `:246`；② 保持 `++skipped;`、保持 `DiagBeforeReturn`、**不加 `throw`、不加调用点**；③ **同步修正 `:581` 那条已被推翻的 needle 文案**，并**新增一条正向 needle**断言"隐形 run 不再 deref CBR"（否则牙齿在为被推翻的命题背书）；④ 落地后 `--check` 必须 rc=0，且**改前后断言条数要能解释**（今天 12 条；增删逐条说明）。

---

## ⑦ 我推翻/修正了哪句话

### ⑦.1 ⭐ 推翻 `#22`（W22D）/ `#23` §1.1 的**家族宽度**：「`TextHidden` 一族」在**默认配置**下**不命中** `D-T5`

预登记 §1.1 逐字：「`TextHidden`（`shim:44-47`，默认空 CBR、ctor 强制 ≥1）机制相同 …… ⇒ **`<Run>`/`<Bold>`/`<Span>`/`<Underline>`/`<Hyperlink>` 都会命中**」。

**反证据（同一份 `pc`、同一条用例、只换快路径开关）**：

| | `hidden1` | `hiddenmid` | `hiddenonly` |
|---|---|---|---|
| 快路径**开** | **GREEN**（`Σ可见长=5 期望=5`，`接手链=NOINFO(两档零增量)`） | **GREEN** | **GREEN** |
| 快路径**关** | **RED-EXC-LS** / `rc=134` | **RED-EXC-LS** / `rc=134` | **RED-EXC-LS** / `rc=134` |

**机制**：`SimpleTextLine.cs:1559-1563`（我方 `SimpleTextLine.Linux.cs:1703-1707`）**专门处理 `TextHidden`**（`Flags.Ghost`）⇒ 只要走快路径（`AlwaysCollapsible=false` 且无前次断行，生成物 `:556-559`），`TextHidden` **根本到不了三层托管档**。
⇒ **精确表述应为**：「`TextModifier`/`TextEndOfSegment`（任何非 `TextCharacters` 且非 `TextEndOfLine` 的 run）在**所有**配置下命中；**`TextHidden` 只在快路径被关掉时命中**（`AlwaysCollapsible=true`、或段落有前次断行、或 `lineLength>0`）。」

**边框（不许读大）**：我**只测了** `Formatter.FormatLine` 这一条入口、`AlwaysCollapsible ∈ {false,true}`、`FlowDirection=LeftToRight`、单段。**"真 XAML 里 `<Bold>` 走的到底是不是 `TextHidden`、以及是否总在快路径"本件未测 ⇒ `NOINFO`**（那需要跑 `pf`/控件层的宿主）。

### ⑦.2 修正 `mod0` 的可达性：**零长 modifier 在 `FormatLine` 路径上会在快路径抛异常**

`W17D-report.md:160` 逐字：「**零宽** modifier 在 `cp=0`、同一下标第二次给 `TextCharacters("WWWW")` —— **这才是 `modifierOpenIndex >= 0` 唯一可达的形态**」。**该结论成立于 `FormatMinMaxParagraphWidth`**（W17D 的仪器是 `MinMaxProbe`）。

**在 `FormatLine` 上**：

```
D5CBR VERDICT case=mod0 tier=strict verdict=RED-EXC 行数=0 异常=ArgumentOutOfRangeException: textRun.Length ('0') must be a non-negative and non-zero value. (Parameter 'textRun.Length')
```
（快路径开）—— 快路径**拒收零长 run**。**只有关掉快路径**（`--collapsible`）零长 modifier 才由宽松档接手并绿（`宽松档 Δhandled=1`）。⇒ **"唯一可达形态"这句话与入口有关，不是普适的**。

### ⑦.3 ⚠️ 一处先前我自己疑似发现的"产品双计"—— **撤回**

改对幂等之前，我读到 `relaxedCalls=1 relaxedFailed=2`，并**一度准备登记为"产品计数器双计"**。**核后撤回该归因**：`relaxedFailed=2` 是**我的非幂等源**造成的假象（宽松档根本没看到那个 run）。
**保留一条独立的、可复算的观察**（与本族无关、低严重度）：生成物 **`:191`** 在 `CollectLenient` 内部 `++s_failed` 后 `return false`，调用方 **`:244`** **再** `++s_failed` ⇒ **同一次逻辑失败计两次**。**仅**在"空段落且无 props"分支可达（本族修好幂等后 `relaxedFailed=1`，与该分支无关）。**是否值得修由主控裁决；本件不改，也不登记为 `D-T5` 的一部分。**

---

## ⑧ 并发交底：`pc` 在读数期间**真的变过**

| 时刻 | `pc`（权威） | `hbtextline` |
|---|---|---|
| 开工复核（与 `#21` **逐位一致** ✅） | `e7cabff9417ed380` | `76089e1de586ac91` |
| **变更点**（另一车道 W23B 落 P2） | `e7cabff9417ed380` → **`7b47a7b3d69ad62f`**（mtime `2026-09-17 00:13:09.850907721`） | `76089e1de586ac91` → `e89fed55fd8e32bc`（mtime `00:12:06`） |

**处置（纪律 35，照做）**：
1. **发现**：`R-final-fpon/MATRIX.tsv` 第 27 行 `hiddenmid lenient catch` 的 `pc_sha_before=e7cabff9417ed380` / `pc_sha_after=7b47a7b3d69ad62f` ⇒ **该趟作废**。
2. **实测关键事实**：探针 bin 目录里的 `PresentationCore.dll` **一直是 `e7cabff9417ed380`**（`Private=true` 在**构建时刻**拷贝）⇒ 那几趟**实际被测的产物从未变**，读数**内部自洽**；但它们**被测的是旧 `pc`** ⇒ 按纪律仍**重取**。
3. **重取**：`dotnet build … -c Release -m:1` 刷新本地副本 ⇒ 副本 = 权威 = **`7b47a7b3d69ad62f`**；重跑两趟矩阵 ⇒ **128/128 个 before/after 采样全是 `7b47a7b3d69ad62f`**（读数期间**未再变**）。
4. **正交性预测**：`D-T5`（宽松档 `ExtractRun`/`CollectLenient`）× `D-T6-b`（`_lineStart` 双用字段）**理论上正交** ⇒ 预测"重取后读数相同"。**实测兑现**：

```
=== fpoff : old pc (e7cabff9) vs new pc (7b47a7b3) ===
  逐行相同（case/tier/mode/rc/verdict 全同）
=== fpon : old pc (e7cabff9) vs new pc (7b47a7b3) ===
  逐行相同（case/tier/mode/rc/verdict 全同）
```

⇒ **本报告 §④ 的读数全部取自 `pc = 7b47a7b3d69ad62f`**（`#23` 的当前状态），并把"换 `pc` 读数不变"本身做成了读数。

---

## ⑨ readings 表（规则 32）

| 项 | 值 |
|---|---|
| **lane** | **W23A** |
| 起 / 讫（+0800） | **2026-09-16 23:55:11** / **2026-09-17 00:2x** |
| `kernel` | **`6.8.0-138-generic`** |
| `nproc` | 3 |
| `loadavg` 开工 / 收工 | `0.35 0.26 0.11` / `2.99 2.74 2.24` |
| `MemAvailable` 开工 / 最低 / 收工 | `3,150,156 kB` / `3,150,156 kB` / `3,624,348 kB` |
| `SwapFree` 收工 | `1,089,276 kB` |
| **开工基线复核** | `pc e7cabff9417ed380` ✅ / `hbtextline 76089e1de586ac91` ✅ **与 `#21` 逐位一致** |
| `pc`（读数用，权威＝探针副本） | **`7b47a7b3d69ad62f`**（4,197,376 B，2026-09-17 00:13:09） |
| `hbtextline`（读数期间，W23B 已改） | `e89fed55fd8e32bc`（290,825 B） |
| 生成物 `TextFormatterImp.Linux.cs` | `fef2cfb47f882a82`（56,380 B） |
| 应用器 patcher | `00c2179b87fc0509`（54,344 B） |
| 探针仪器 dll（**冻结**） | **`117582b2a40d30c0`** |
| `DISPLAY`（主判据读数） | **unset**（`X_INVARIANT=YES`，见 §②.5） |

---

## ⑩ `NOINFO` 清单（**不许算绿**）

1. **真 XAML 里 `<Run>/<Bold>/<Span>/<Underline>/<Hyperlink>` 是否真的会走到 `D-T5`** —— 需要 `pf`/控件层宿主。**本件只证"某个 `TextSource` 姿势下会"**。
2. **`AlwaysCollapsible=true` 在真实控件里有多常见** —— 未测。⇒ **§⑦.1 的"窄"是"在这条入口、这个姿势下"的结论，不是对应用影响面的估计**。
3. **`TextEmbeddedObject`/`TextShapeableSymbols` 的空 CBR 行为** —— 未测（`W22D` 也已标 `NOINFO`）。
4. **`FlowDirection=RightToLeft`、多段、`lineLength>0`（`FormatLine` 带长度那支）、`RecreateLine` 入口** —— 本件全 `LTR`、单段、`lineLength=0`。**RTL 会是 `CollectLenient` 记账的另一条分叉**（生成物 `:115-190` 的 `modifierOpenIndex` 记账），**未测**。
5. **`--nocatch` 之外的"应用层真实 abort"** —— 我证的是"`Main` 之外未处理 ⇒ `abort()`"；**真宿主（`WpfTextDemo`）里是否有人 catch** 本件未重测（引 `#22` 的静态追踪）。
6. **§5.3 的假修端到端读数** —— 见 §5.3（有可执行方案，**未实测**）。
7. **修法落地后的绿证** —— **本件不修**，故没有绿证。
8. **`MemAvailable` 最低值** —— 未连续监控，只有取样点（见 §⑨ 脚注）。

---

## ⑪ 产物清单

| 件 | sha16 | 说明 |
|---|---|---|
| `build/MilBridge/W23A-report.md` | **（自指，本件无法自含 —— 见最终回复）** | 本文件。按本项目惯例：**报告 sha16 在冻结后由 `sha256sum` 打印并写进最终回复**；此处不写死，以免"文件里的值 ≠ 文件自己的值"。 |
| `build/MilBridge/tests/D5CbrProbe/Program.cs` | `92694cf0c9c5d392` | 探针源（新建） |
| `build/MilBridge/tests/D5CbrProbe/D5CbrProbe.csproj` | `212df5f87cdf2542` | 工程（新建） |
| `build/MilBridge/tests/D5CbrProbe/bin/Release/PresentationCore.Tests.dll` | `117582b2a40d30c0` | 冻结仪器 |
| `$HOME/w23a-run/run-matrix.sh` | — | 驱动（一例一进程 + 崩溃取证） |
| `$HOME/w23a-run/run-xinvar.sh` | — | X 不变性证明 |
| `$HOME/w23a-run/F-fpoff/`、`F-fpon/` | — | **最终两趟矩阵**（32 + 32 组合） |
| `$HOME/w23a-run/xinvar3/RESULT.txt` | — | X 不变性结果 |
| `$HOME/w23a-run/R-final-*/`（旧 `pc`） | — | 换 `pc` 前的对照趟（用于 §⑧ 的正交性兑现） |

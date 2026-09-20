# 在册红 —— `FrameProbe` 的 **3 条结构族帧红**（**登记 ≠ 已容忍**）

- **车道**：`W25C`｜**首次登记**：2026-09-17 12:2x（+0800）｜**预登记**：`docs/WAVE25-PREREGISTRATION.md` §4①
- **登记对象**：`build/MilBridge/tests/FrameProbe/`（`D-T6-b` 帧判据探针）在 `--leg b` 三条腿上**逐条点名**的
  3 条「**行数我方 ≠ 真值**」红。它们 `#23` 查出、`#24` 定性，**此前无处可登记**（该探针**不读任何在册红表**，见 §0）。
- **本登记的性质**：**书面登记 + 只读**。它**不是**豁免机制，**不进任何计数器**，**不改任何 `rc`**。
  **探针自己的 `probe_rc=1` 与本文件的存在与否毫无关系** —— 登记一条红，绝不等于把那条红读成绿。

## 0 · 这份登记**不是**豁免机制（读之前先看这五条）

1. **登记在册 ≠ 已容忍**：本段**不参与判定**。它不让任何一条红变绿、不改任何 `CNT_*`/计数器、不改任何 `rc`。
2. **两个消费者都不读它**（可现场复算）：
   - `FrameProbe`（`Program.cs` `503e6ebd86d70303`）：`grep -n 'known-red\|registry\|在册' Program.cs` ⇒ **0 命中**；
   - `build/MilBridge/tools/frame-step.sh`（`a8800cd897606cf7`）：`grep -n 'known-red\|registry\|在册' frame-step.sh` ⇒ **0 命中**
     （该脚本只 `grep` 探针输出里的 `^FRAMEPROBE 汇总 ` / `^FRAMEPROBE 红族分解 ` 两行算数）。
   ⇒ **删掉本文件，探针与 `frame-step.sh` 的行为逐字节不变**（判据见 §3）。
3. **`frame-step.sh` 今天不判结构族**，且这是**它的书面口径**（`frame-step.sh:24-26`、`:169-170`）：
   `⛔ 本步断言 帧红 == 0，绝不断言 红行 == 0` / `② 结构族红：只点名，不判（另一笔账；见文件头）`。
   ⇒ 本文件登记的红**本来就是**该步**明确不判**的那一族。
4. **静态快照，不是常量**：下面每条都绑着**测量时的仪器 sha + 语料 sha + 被测 `pc` sha**。
   任一变了 ⇒ 这些条目**不再可归因**，必须**重取**（§4）。**尤其**：`pc` 在 `#25`（W25A 落地 `D-T5-R`）**必变**。
5. **本文件的存在理由**是"**有处可登记**"，不是"门禁"。若将来有人把"结构族"接进判定，那要**新开一波**、
   **改 `frame-step.sh` 并加 `--selftest` 两极**，**不是**靠读本文件（见 §5）。

## 1 · 三条登记条目（**逐条点名 + 取证来源**）

**共同身份**（三条只在 `id`/`indentArm`/`paragraphIndentDip`/`firstLineInParagraph` 上不同）：

- `text` = `"\tb\tc"`（1 个前导 TAB + `b` + 中间 TAB + `c`），`textId` = `lead-tab-b-t-c`，
  `note` = `tab at line START + a second tab in the middle`（语料原文，见 `tab-anchor-raw.json`）。
- `paragraphWidthDip` = **40**｜`emSizeDip` = 24｜`flowDirection` = `LeftToRight`｜`script` = `latin`｜
  `textWrapping` = `"Wrap"`｜`incrementalTabArm` = `DefaultIncrementalTab=0`｜`fontFamily` = `Arial`｜`dpi` = 96。
- **真机（语料）自报**：`lineCount` = **2**，`lines[0]` = `startChar 0 / endCharExclusive 2 / "\tb"`，
  `lines[1]` = `startChar 2 / endCharExclusive 4 / "\tc"` ⇒ 真值帧（绝对）= **`[0, 2]`**。

| # | `id`（逐字） | `indentArm` / `indentDip` / `paragraphIndentDip` / `firstLineInParagraph` | 我方自报（strict 腿） | 真值 | 取证来源（文件:行） |
|---|---|---|---|---|---|
| 1 | `B-indent/lead-tab-b-t-c@w40@LTR@i24@tab0` | `i24` / `24` / `0` / `true` | `首调cpFirst=0`、`我方各行cpFirst=[0,1,2,3]`、**行数我方=4**、`判定行=2`、`红行=1`、`接手档=strict` | `真值各行startChar(绝对)=[0,2]`、**真值=2** | `/home/links-dev/w24b-run/final-logs/strict.log:27`（`FRAMEPROBE CASE …`） |
| 2 | `B-indent-extra/lead-tab-b-t-c@w40@LTR@i0p24@tab0` | `i0p24` / `0` / `24` / `true` | `首调cpFirst=0`、`我方各行cpFirst=[0,1,2,3]`、**行数我方=4**、`判定行=2`、`红行=1`、`接手档=strict` | `真值各行startChar(绝对)=[0,2]`、**真值=2** | `/home/links-dev/w24b-run/final-logs/strict.log:54`（`FRAMEPROBE LINECOUNT …`）、`:55`（`FRAMEPROBE CASE …`） |
| 3 | `B-indent-extra/lead-tab-b-t-c@w40@LTR@i24nl@tab0` | `i24nl` / `24` / `0` / **`false`** | `首调cpFirst=0`、`我方各行cpFirst=[0,1,2,3]`、**行数我方=4**、`判定行=2`、`红行=1`、`接手档=strict` | `真值各行startChar(绝对)=[0,2]`、**真值=2** | `/home/links-dev/w24b-run/final-logs/strict.log:57`（LINECOUNT）、`:58`（CASE） |

**逐条点名行原文**（`FRAMEPROBE RED …`，**三条腿各一批、同一批三条**）：

| 腿 | 点名行原文（取自 `…/final-logs/<腿>.log`） | 行号 |
|---|---|---|
| `--leg b --tier strict` | `FRAMEPROBE RED B-indent/lead-tab-b-t-c@w40@LTR@i24@tab0 行#1 我方帧(扫描)=1 我方帧(_lineStart)=1(反射 1) 真值帧(startChar)=2 我方cpFirst=1 Length=1 行类型=HbTextLine` | `strict.log:79`（另两条 `:80`、`:81`） |
| `--leg b --tier lenient` | 同上，仅 `我方帧(_lineStart)=0(反射 0)` 不同（**扫描帧与 cpFirst 仍是 1**） | `lenient.log:79`（`:80`、`:81`） |
| `--leg b --tier strict --prefix 40` | `… 我方帧(扫描)=41 我方帧(_lineStart)=1(反射 1) 真值帧(startChar)=42 我方cpFirst=41 Length=1 行类型=HbTextLine`（**整体平移 40**） | `strict+prefix40.log:782`（`:783`、`:784`） |

**汇总读数**（同一趟，`frame-step.sh` 的输出档 `/home/links-dev/w24b-run/frame-step-final.out`）：

```
L9  腿 strict        计数器 = FRAMEPROBE 汇总 … 判定行=421 红行=3 绿行=418 NOINFO行=101 红例=3 判定例=288 真值非零行=133 帧红=0 结构红=3
L12 腿 strict        结构族红=3（**本步不判**：我方分行 != 真机分行，属登记决定，见文件头）｜结构族NOINFO=101（语料性质，非仪器缺口）
L38 FRAME_STEP 被测 pc 全程未变 = b877ff3e3437145a
L39 FRAME_STEP 结构族红汇总（**未登记，主控的登记决定；本步不判**）： strict:3 lenient:3 strict+prefix40:3
L40 FRAME_STEP=PASS 三条腿（strict / lenient / strict+prefix40）均 帧红=0 ∧ 判定行>0 ∧ 仪器族NOINFO=0 ∧ 自洽=1
```

⇒ **条目数 = 3，与 `FrameProbe` 逐条点名的条数一致**（三条腿 `结构红=3` × 3 腿 = 点名 **3 条 × 3 腿 = 9 行**，
但**去重后是 3 个 `id`** —— 同一批用例在三条腿上各点名一次）。

## 2 · 为什么恰好是 3 条（**不是"行数不等的例"全都算**）

- 探针自己报 **`我方行数 != 真值行数 的例=60`**（`strict.log` 的 `FRAMEPROBE 仪器自证 …` 行自报；
  `grep -ac '^FRAMEPROBE LINECOUNT' strict.log` = **60**，**逐条例点、60 个不同 `id`**）。
- 但**结构红的定义**（`Program.cs:33-34`）要求**逐行**同时满足三项：
  `红 ∧ 扫描帧 == 该行 cpFirst ∧ cpFirst != 真值 startChar`。
  ⇒ 只有当"**真值那一行**在我方被**错位**成另一行"时才算；**行数不等但真值行仍逐行对得上**的例，**不红**。
- 60 条 `LINECOUNT` 例里，只有 §1 那 3 个 `id` 的**真值第 1 行**（`startChar=2`）在我方被错位
  （我方 `cpFirst=1`，即**中间那个 TAB 成了独立一行**）⇒ 恰好 3 条。
  另 57 条**行数不等但没红**（其真值行逐行对得上）⇒ **本文件不登记它们**。
- 阳性对照（计数器有判别力，不是恒 0）：`grep -ac '^FRAMEPROBE RED' strict.log` = **3**、
  `lenient.log` = **3**、`strict+prefix40.log` = **3**；三份合起来 `awk '{print $3}' | sort -u` = **3 个 `id`**。
  同一条 `FRAMEPROBE 仪器自证` 行还把"红"与"结构"分开报：`我方 cpFirst vs 真值 startChar 不一致行=3`、
  `扫描帧 vs _lineStart(IVT) 不一致行=0`（后者 = 帧红那一族的计数器，今天 **0**）。
- **根因（机器证，不是我推测）**：三条点名行里 **`扫描帧 == 我方 cpFirst`**（`1 == 1`；prefix40 腿 `41 == 41`）
  ⇒ **帧原点机制是对的**（`D-T6-b` 那一族已修好），错的是**我方的分行**：真机把 `"\tb"` 当**一整行**（2 个码元），
  我方把**中间那个 TAB** 单独断成一行 ⇒ 我方 `[0,1,2,3]` vs 真值 `[0,2]`。
  ⇒ 这是**分行/断行（break partition）**那一族的账，**不是帧的账**。

## 3 · 只读性证明（**删掉本文件不会让任何判据变绿/变红**）

**判断依据 = 消费者集合为空**（现场 `grep`，2026-09-17 12:2x）：

| 去向 | 命令 | 实测 |
|---|---|---|
| `FrameProbe` 探针本体 | `grep -n 'known-red\|registry\|在册' build/MilBridge/tests/FrameProbe/Program.cs` | **0 命中** |
| `frame-step.sh`（`verify-all` 第 `[6]` 步的零件） | `grep -n 'known-red\|registry\|在册' build/MilBridge/tools/frame-step.sh` | **0 命中** |
| 新登记文件自身的**任何**引用 | `grep -rn 'known-red-frame-structural' --include='*.sh' --include='*.py' --include='*.cs' --include='*.json' .` | **0 命中**（本文件是**今天新建**的 ⇒ 结构上不可能已有读者） |
| 五臂门禁登记表 | `grep -c 'lead-tab-b-t-c' build/MilBridge/known-red.json` | **0**（`known-red.json` 只有 **4** 条 `entries`，全不涉及本三条） |

**同一形态的实测先例**（姊妹文件、已跑过两极化）：`known-red-PC-copies.md` 的只读性由
`check-applocal-sync.sh` 的沙箱三趟实测证明 —— **有登记 / 空登记 / 登记文件整份不存在** 三种状态下
`rc` 全为 `1`、`计数：` 行、`APPSYNC=` 行、`scan() 内部 rc=` 行**逐字相同**，
剔除登记段并归一化沙箱路径后整份输出 `cmp` **IDENTICAL**（**两趟独立实测同结论**：
在被测脚本 `c843…` 一类的中间版本上 sha16 `1c97df146afe27c5` × 3（104 行中 89 行）、
在 W25B 改过的 `7bc9364091a28fd4` 上 sha16 `c07c481d87324ebc` × 3（104 行）——
**sha 变了是因为脚本变了，判据每次都在那份脚本上成立**）。
脚本与日志落档：`$HOME/w25c-run/run-readonly-test.sh`（`53b3d1b65e4b85f1`）、
`$HOME/w25c-run/readonly-test.out`（`9a1819b9b792fc7a`）。
⇒ 本文件的机制**同构**（同样的 `show_registry()` 形态、同样"只打印"），且**连读者都没有**。

## 4 · 这份登记覆盖什么 / 不覆盖什么（**射程**）

**本次测量身份（缺一不可归因）**：

| 项 | 值 | 来源 |
|---|---|---|
| 探针 `Program.cs` | `503e6ebd86d70303`（43,380 B） | 现场 `sha256sum` |
| 探针工程 `FrameProbe.csproj` | `9be882d85aac2ad4`（4,603 B） | 现场 `sha256sum` |
| 语料 `tests/parity/windows/tab-anchor/out/tab-anchor-raw.json` | `88559d670f1bb955`（1,196,289 B） | 现场 `sha256sum` |
| 被测 `pc`（树内权威 + 探针产物副本，两者 `cmp` 同） | `b877ff3e3437145a`（4,197,376 B） | `frame-step-final.out:4-6` 自报 + 现场复算 |
| 判据脚本 `frame-step.sh` | `a8800cd897606cf7`（12,429 B） | 现场 `sha256sum` |
| 读数日志 | `strict.log 82b9851728b5a0db`｜`lenient.log 8eae1fca8aedc10d`｜`strict+prefix40.log 91c2e97951594ba4` | 现场 `sha256sum` |
| 汇总输出档 | `frame-step-final.out ab23bdd2da10e86f`｜`frame-step-confirm.out 72ede9085b130e73` | 现场 `sha256sum` |

**⚠️ 本登记只覆盖**：`--leg b`、语料 `88559d670f1bb955`、`pc b877ff3e3437145a`、上表仪器 sha。
**⚠️ 不覆盖**（明确列出）：

1. **`--leg a`**（`AlwaysCollapsible=false`）：`#24` 测过与腿 B **完全一致**（`帧红=0 / 结构红=3`），但**本次登记未取证** ⇒ 它若变，本文件不认。
2. **换语料/换 `--prefix` 值**：只登记 `--prefix 40`（与 0）；
   其它 prefix 值、别的语料（如 `tab-anchor-oracle.json`）**全不在射程**。
3. **RTL / 非 latin**：`--leg b` 的分母口径是 `script==latin` 的 288 例/421 行；Hebrew/Arabic 例被覆盖闸跳过 ⇒ **不覆盖**。
4. **`pc` 换世代之后的同一批用例**：`#25`（W25A `D-T5-R`）**`pc` 必变** ⇒ 本登记**必然要重取**（见下）。
5. **`结构族NOINFO=101`**（语料性质，非本条）：那是**另一笔账**，本文件不登记它。
6. **"我方分行 ≠ 真机分行"的其它形态**：本文件只登记**今日逐条点名的这 3 条**；同族但今天不红的例（§2 的另 57 条 `LINECOUNT`）**不在册**。

**重取条件（三条任一成立 ⇒ 本登记作废、必须重取）**：
① 上表任一仪器 sha 变（`Program.cs` / `csproj` / `frame-step.sh` / 语料）；
② 被测 `pc` 的 sha 变（**`#25` 必变**）；
③ `frame-step.sh` 的腿表（`LEGS`）变。

**⚠️ 一条关于"可复现性"的实话**：§1 的读数是 `#24` 车道 W24B 在 **`pc b877ff3e3437145a`** 下取的；
本车道（W25C）**按硬约束零 `dotnet`** ⇒ **没有重跑探针**。
今天现场复算的只是**条件**：探针 `bin/Release/` 里的 `PresentationCore.dll` 副本 **`cmp` 等于**树内权威
（两者 sha16 均 `b877ff3e3437145a`）⇒ 那趟读数的**前提今天仍成立**，但**读数本身不是本波重取的**。

## 5 · 若将来要把结构族接进判定（**今天不做，只记下路**）

- 那要**改 `build/MilBridge/tools/frame-step.sh`**（新增一条断言 + `--selftest` 两极），
  **不是**读本文件；并且要**先裁决**："结构族红到底该判 0，还是该有账面数字"。
- `#24` 已实测的反面：把 `红行` 当判据 ⇒ **本步永远红**（`结构红=3` 恒在）⇒ 退化成"没人看的红"（事故 `L26` 同族）。
- 本文件**不预设**那个决定；它只是**把那 3 条从"无处可登记"变成"有处可登记"**。

**取证日志的现场 sha16 / 字节 / mtime**（`sha256sum` 现场算；这些档**不在仓内**，在 `$HOME/w24b-run/`）：

```
5a79e2b34996dd27     16800 B  2026-09-17 10:19:18  /home/links-dev/w24b-run/final-logs/strict.log
ec8a51112349ab4f     16866 B  2026-09-17 10:21:53  /home/links-dev/w24b-run/final-logs/lenient.log
b044f5a2045c187e    170598 B  2026-09-17 10:24:07  /home/links-dev/w24b-run/final-logs/strict+prefix40.log
ab23bdd2da10e86f      6076 B  2026-09-17 10:24:07  /home/links-dev/w24b-run/frame-step-final.out
72ede9085b130e73      6084 B  2026-09-17 10:32:08  /home/links-dev/w24b-run/frame-step-confirm.out
b6f8f92149c5a537      6065 B  2026-09-17 09:55:25  /home/links-dev/w24b-run/frame-step-standalone.out
```

**根因归属**（`#33` W33C 追加）：本 3 条 = `D-T4`（`KNOWN-DEFECTS.md`；`docs/CURRENT-STATE.md` §4）**在帧列上的可见后果** —— 机器证 = 三条腿 `tab0 ↔ default` 配对：**我方行数 `0/119` 变、真机 `60/119` 变**。
**同 3 条另见** `build/MilBridge/tests/PcLineOracle/known-red.txt`（同用例 id，`修前: 行数 期望=2 实得=4`）。
**身份表已重锚（`#33` 波尾）**：被测 `pc` = `b877ff3e3437145a`｜判据脚本 `frame-step.sh` = `a8800cd897606cf7`｜读数日志（`#32` 波尾，mtime 2026-09-18 13:21~13:26）= `strict.log 82b9851728b5a0db`／`lenient.log 8eae1fca8aedc10d`／`strict+prefix40.log 91c2e97951594ba4`。
⚠️ **本册子的撤登记条件见 §5**（`D-T4` 修好后三条全绿 ＋ `判定行>0` ＋ `结构族NOINFO` 下降 ⇒ 两册**同趟**删）。

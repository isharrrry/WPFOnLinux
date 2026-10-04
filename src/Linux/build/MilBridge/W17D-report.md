# W17D —— 落地 `WAVE17-PREREGISTRATION.md` §1 **P3**（`D-T2` 真身：min 探针的 `TextModifier` 作用域实参），并用**构造用例**判它

> **lane = W17D**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **开工**：`2026-09-16 12:11:22 +0800`｜`uname -r = 6.8.0-138-generic`｜`/proc/loadavg = 0.69 0.98 1.00`｜`MemAvailable = 2806876 kB`
> **收尾**：`2026-09-16 12:19:14 +0800`｜`loadavg = 1.84 2.20 1.57`｜`MemAvailable = 3664432 kB`
> **写域**：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`｜生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`｜**新**工程 `build/MilBridge/tests/MinMaxProbe/**`｜本文件｜`$HOME/wfp-runs/w17-laneW17D/`。
> **未改**（逐件 sha16 见 §8.3）：`build/shims/**`（`bc04c05ab6d8d82a`）｜`build/MilBridge/run.sh`｜`build/MilBridge/tests/HbTextLineParity/Program.cs`｜`build/MilBridge/tests/PcLineOracle/Program.cs`（`544aab374ee8e1a6`）｜`PcLineOracle.csproj`（`b0bf270206fe9c09`）｜`build/MilBridge/known-red.json`｜`build/MilBridge/tools/tline-gate.sh`｜`verify-all.sh`｜`docs/**`｜`samples/**`｜`build/PresentationCore.Linux/PresentationCore.Linux.csproj`（`26ce64b8f4452ed4`）｜`HbTextLineShimSha.targets`（`3aa64fd08fc7ea05`）｜`build/MilBridge/tests/ShimShaReader/**`。
> **未用** `pkill -f` / `pgrep -f`（本轮一次都没有需要止损）。

---

## 1. 一行判决

**P3 落地，判据成立**：min 探针补上 `modifierOpenIndex/modifierCloseIndex` 后，**构造用例确实翻转 —— `min=22.652344 > max=0.000000`（修前）→ `min=0.000000 = max=0.000000`（修后）**，阴性对照（无 modifier）**逐位不动**（`min=22.652344 max=90.609375`，两相相同）；权威 `pc` `1280323c9173bcde` → **`14086882b1509dcd`**；`PcLineOracle` 复跑 stdout **`07615909a1ffaa8b`**，与 `W17B-report.md` 交付的那份 **`cmp` 逐字节相同**（⇒ P3 在那支臂的射程之外）。`D-T2-c` **只登记、零代码改动**（§9）。

**两条更正（都比本件本身值钱，全部留档）**：

1. **TDT2 §2.5 设计的构造例（`TextModifier` 且 `Length = 1`）到不了被测代码** —— 实测：`CollectLenient` 当场 `return false`（正控 `relaxedFailed=1 relaxedHandled=0`、`GetTextRun` 只被调 **1** 次），随后交回 LineServices ⇒ 抛 **`EntryPointNotFoundException: … 'LoCreateContext' …`**。所以"用 `Length=1` 的 modifier 造 `min > max`"这条路线**在仪器上是死的**；本臂改用**零长** `TextModifier`（唯一能过 `ExtractRun` 的形态，§6.1 有代码级依据）才把红证做出来。
2. **由此暴露一条更硬的缺口（不在 P3 射程内，只登记）**：`CollectLenient`（生成物 `:101-103`）里那套 modifier 记账（`:156-157`）对**任何 `Length ≥ 1` 的 `TextModifier`/`TextEndOfSegment`** 都不可能生效 —— `ExtractRun`（`:81-91`）对它们返回 `null` ⇒ `CollectLenient` **必然 return false**（`:149-152`）⇒ **含 modifier 的段落在 PC 路径上整条交回 LS**（Linux 上没有 `LoCreateContext` ⇒ 抛异常）。这正是"`#13` 的零宽接线只在工厂级臂上被验证过、从来没在 `TextSource` 路径上被走到"的机器证据。

---

## 2. 先写死的预测（**测量之前**写在臂的 stdout 与本节；测完逐条对照）

| # | 用例 | 预测（写死于 12:13 之前） | 实测 | 判决 |
|---|---|---|---|---|
| P-a | `mod0`（零长 modifier 在 `cp=0`）**修前** | `min ≈ (W 的 advance @em24) > max = 0.000000` ⇒ `rel=gt` | `min=22.652344 max=0.000000 rel=gt` | ✅ 命中 |
| P-b | `mod0` **修后** | `min = 0.000000 = max = 0.000000` ⇒ `rel=eq` | `min=0.000000 max=0.000000 rel=eq` | ✅ 命中 |
| P-c | `control`（同文本、**无** modifier）两相 | `rel=lt`（两探针参数等价） | `min=22.652344 max=90.609375 rel=lt`（两相逐位相同） | ✅ 命中 |
| P-d | `mod1`（TDT2 设计的 `Length=1` 形态） | "**到不了**被测代码"（判 `NOINFO`/异常） | `relaxedFailed=1 handled=0` ⇒ `EntryPointNotFoundException`（`LoCreateContext`） | ✅ 命中 |
| P-e | 权威 `pc` 的 sha 是否因本件改变 | 必变（改的是编译进产物的源） | `1280323c9173bcde` → `14086882b1509dcd`（**字节数逐位不变** 4,195,328） | ✅ 命中 |
| P-f | `PcLineOracle` 分桶 | **逐位不变**（没有任何臂消费 `minWidth`） | stdout `cmp` **逐字节相同**（`07615909a1ffaa8b`） | ✅ 命中 |

**没有一条预测被推翻。** 预测原文也印在臂的 stdout 里（`PREDICT …` 三行，见 §6.3 逐字）。

---

## 3. 精确 diff（应用器 + 生成物，含 before/after sha16）

### 3.1 备份（纪律 16：**先备份再改**，`cp -p`）

| 文件 | sha16 | 字节 | mtime |
|---|---|---|---|
| `$HOME/wfp-runs/w17-laneW17D/backup/applier.before.py` | **`a3357070dae6de99`** | 41,304 | 2026-09-16 11:59:21.510853545 +0800 |
| `$HOME/wfp-runs/w17-laneW17D/backup/generated.before.cs` | **`9fd04d10a6479dcd`** | 52,598 | 2026-09-16 12:05:21.632533271 +0800 |
| （另存修前**权威产物**）`$HOME/wfp-runs/w17-laneW17D/pc-prefix-1280323c9173bcde.dll` | **`1280323c9173bcde`** | 4,195,328 | 12:00:10.743118178 +0800 |

两条 before 与实际树逐位相同（`W17B-report.md` §8.2 记的是同一对 sha16）⇒ **我是从 W17B 交付的那一版改起**，before 都拿得到（未重演 W17C 的"before 不可得"）。

### 3.2 现场重锚（**TDT2 引的行号已经漂了；先报当前值**）

| 引用对象 | TDT2 引的 | **现场实测（本轮开工时）** | 漂移 |
|---|---|---|---|
| 生成物 max 探针的 modifier 实参 | `:305` | **`:307`**（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`，修前 `9fd04d10a6479dcd`） | +2 |
| 生成物 min 探针（**无** modifier 实参，`out c2);` 结束） | `:309`/`:311` | **`:312-313`**（`:313` = `props, false, false, 0, out c2);`） | +2…+4 |
| 应用器 max 探针 | `:445-448` | **`:448-450`** | +2…+3 |
| 应用器 min 探针 | `:451-454` | **`:455-456`**（`:456` = `out c2);`） | +2…+4 |

⇒ **TDT2 的"`:309` vs `:305`"结论本身成立、位置已位移**；本报告一律给**文件名 + 当前行号**。

### 3.3 改动（**一件只改一处**）

改的是 **min（narrow）探针那一次 `FormatParagraph` 调用**，让它与 max（wide）探针**用同一组作用域实参**：

```diff
--- applier a3357070dae6de99 (41,304 B)
+++ applier 188f75a67294138f (44,274 B)
@@ 应用器 :453-457（= 生成物 :320-323）@@
+                // ── WAVE17 §1 P3（`D-T2` **真身**）：min 探针必须与 max 探针**用同一把尺子** ──
+                //   …（注释 9 行：修前形态 / 实测数值 / 为什么不动 `scopeEnd`）…
                 System.Collections.Generic.List<WpfLinux.Shims.PresentationCore.HbTextLine> narrow =
                     WpfLinux.Shims.PresentationCore.HbTextLineFactory.FormatParagraph(
                         text, fontPath, props.FontRenderingEmSize, 0.0, gt, (float)pixelsPerDip,
-                        props, false, false, 0, out c2);
+                        props, false, false, 0, out c2,
+                            modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2);
```

**生成物**：`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`
**`9fd04d10a6479dcd`（52,598 B @ 09-16 12:05:21）→ `56a5b4a5be1c6bcc`（53,783 B @ 12:18:00）**；
`diff -u backup/generated.before.cs <现树>` = **恰好 1 个 hunk**（`@@ -307,10 +307,20 @@`），内容与该注释块 + 两行实参一一对应（逐字已核）。修后锚点：**max `:307`、min `:322-323`**。

**"没有顺手改别的"的机器自证**：
- `grep -c 'out c2);'` **修前 = 1、修后 = 0**；`grep -c 'modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2);'` **修前 = 1、修后 = 2**（`_count` 牙齿的口径，§4.3）。
- **严格层一个字没动**、**`FormatLine` 那条链一个字没动**：生成物 diff 只有上面 1 个 hunk。
- **`scopeEnd` 一个字没动**（两个探针都没传它 —— 见 §9 的 `D-T2-c`）。

---

## 4. 编译证据（**私有输出目录**，纪律 33）

### 4.1 真的编译（`--check` rc=0 **不算**）

```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet build -m:1 build/PresentationCore.Linux/PresentationCore.Linux.csproj \
  -p:BaseOutputPath=$HOME/w17d-build/bin/ -p:BaseIntermediateOutputPath=$HOME/w17d-build/obj/
```
```
BUILD_RC=0
error CS = 0
warning CS = 0
已成功生成。 0 个警告 0 个错误
```
私生产物 `$HOME/w17d-build/bin/Debug/PresentationCore.dll` = **`c4f9c1f18b5f01de`**（4,195,328 B @ 12:16:31）。
**⚠️ 已知事实、照实记**：私生产物的 sha 与权威产物**不同**（`c4f9c1f18b5f01de` vs `14086882b1509dcd`，同源同 shim 同 csproj）——与 W17B §3 观察到的同一现象一致。⇒ **一切读数按"臂自己印出来的已加载 pc 的 sha16"归属**（§6.3 每例都印），不靠目录位置推断。

### 4.2 应用器 `--check`（改前 / 改后）

- **改前 = `rc=1`**：`[检查] …：缺失/与上游不同步（需要重新生成）`（记录在案，免得把"改前也 rc=0"当证据）。
- **改后 = `rc=0`**：`[检查] build/PresentationCore.Linux/TextFormatterImp.Linux.cs：内容已是最新`。
- **新增断言逐字**：`[断言] P3 负断言：min 探针的旧形态（`out c2);`）**不存在** ✅`｜`[断言] P3 参数对等：modifier 作用域实参 2 处（max + min）✅`。

### 4.3 新牙齿的**两极性**（每条都必须能变红 —— 纪律 21/25）

| 实验 | 注入 | 期望 | 实测 |
|---|---|---|---|
| **E1** | 把 min 探针退回 `out c2);`（= 修前形态） | 报红 | `rc=1`，`[失败] 生成物缺少结构断言：P3：min 探针也收了 modifier 作用域实参（调用行尾）（'props, false, false, 0, out c2,'）` |
| **E3** | 保留正常形态，只让字符串 `out c2);` 出现 | **负断言**报红 | `rc=1`，`[失败] P3 负断言：min 探针又退回**不带** modifier 作用域实参的形态（`out c2);`）` |
| **E2** | 多插一处 modifier 实参（3 处） | **计数牙齿**报红 | `rc=1`，`[失败] P3 计数牙齿：modifier 作用域实参出现 3 处（要求 2 = max 探针 + min 探针）` |

**口径诚实**：E1 这个"单点回退"场景里，**先报的是** REQUIRED_IN_OUTPUT 的存在性断言（它在负断言之前跑），负断言只在"部分应用"（存在性字符串在、旧形态也在）时才第一个报 —— E3 就是专门为这条造的。三条牙齿**都不是空转**。
三次注入后应用器**逐字节还原**（`188f75a67294138f`，`--check rc=0`，生成物 `56a5b4a5be1c6bcc`）。

### 4.4 反向复现 + 幂等 + 确定性

- **反向复现**：`cp backup/generated.before.cs` ⇒ sha 回到 **`9fd04d10a6479dcd`**；再跑应用器 ⇒ **`56a5b4a5be1c6bcc`**，与改后内容 `cmp` **逐字节相同**（`CMP_IDENTICAL`）。
- **幂等**：应用器连跑两次，第二次**未重写**（`--check` 直接 rc=0）。
- **权威路径确定性**：同一源再建一次 ⇒ 仍是 **`14086882b1509dcd`**（`error CS = 0`），只有 mtime 走到 12:19:35。

---

## 5. 权威写入（`build/PresentationCore.Linux/bin/Debug/`，供他车道归属）

| | sha16 | 字节 | mtime | 命令时刻 |
|---|---|---|---|---|
| `pc` **before** | **`1280323c9173bcde`** | 4,195,328 | 2026-09-16 **12:00:10**.743118178 +0800 | — |
| `pc` **after** | **`14086882b1509dcd`** | 4,195,328 | 2026-09-16 **12:17:13**.429368211（复建校验后 12:19:35，**sha 不变**） | 12:17:13 +0800 |
| `pdb` before → after | `be6de7589ec7cbf7` → **`e31bef2b22c2b8c8`** | 2,159,556 → 2,159,556 | 12:00:10 → 12:17:13 | — |

写入命令：`dotnet build -m:1 build/PresentationCore.Linux/PresentationCore.Linux.csproj`（`error CS = 0`，`AUTHORITY_BUILD_RC=0`）。
**字节数逐位不变**（4,195,328 B）—— 与"只改了 IL 里一次调用的两个具名实参"一致（多出来的是注释，不进产物）。
⇒ `#16` 冻结表头里那个 `pc` 已**第三次**过期（`c076…` → `18c4…` → `1280…` → **`1408…`**）；凡引用本波以前的 `pc` 锚点**必须点名是哪一代**。

---

## 6. 红证（本件的核心）

### 6.1 为什么必须这么构造（`Length ≥ 1` 的 modifier **到不了**被测代码）

链（每一环都是现场重读的逐字引文）：

1. 宽松层 `CollectLenient`（生成物 `:101-103`）**只**在 `run is TextModifier` 时记 `modifierOpenIndex`（`:156`），且它**先**调 `ExtractRun`（`:146`）。
2. `ExtractRun`（`:81-91`）第一行 = `if (run == null || run.Length <= 0) return string.Empty;`；对 `Length > 0` 的 run 取 `cbr.CharacterBuffer`，**为 null 就 `return null`**。
3. 而 `TextModifier.CharacterBufferReference` 是 **`public sealed override` 返回 `new CharacterBufferReference()`**（上游 `TextModifier.cs:25-28`）⇒ `CharacterBuffer` 恒 **null**（`CharacterBufferReference.cs:159-162` `get { return _charBuffer; }`，默认结构体 ⇒ null）。
4. ⇒ 任何 **`Length ≥ 1`** 的 `TextModifier` 都让 `CollectLenient` 在 `:149-152` **直接 return false**。**唯一**能通过的形态 = `Length <= 0`。
5. 零长 run **不推进 `cp`**（`:161` 的 `cp += run.Length`）⇒ 文本源必须在**同一个 `cp`** 上第二次给出正文（合法：`GetTextRun(cp)` 问的是"该下标处的 run"，零宽标记不消费字符）。
6. 严格层**不会**先把它吃掉：`WPF_LINUX_TEXTLINE_FALLBACK=0` ⇒ `HbTextFallback.Enabled == false`（shim `:4009-4016`）⇒ `TryMinMaxParagraphWidth` 在**碰文本源之前**就 `return false`（shim `:4577`）⇒ `GetTextRun` 的**第一次调用只可能来自宽松层** —— 这一条**由臂印出的调用序自证**（§6.3：`#0` 就是 modifier）。

**❗因此 TDT2 §2.5 那张 worked example 表里"run#0 = `TextModifier`（长度 1）"的形态是死的**（`mod1` 实测：只有 1 次 `GetTextRun`、`relaxedFailed=1`、随后 LS 异常）。本件把构造改成"**零长** modifier 在 `cp=0`、同一下标第二次给 `TextCharacters("WWWW")`"——**这才是 `modifierOpenIndex >= 0` 唯一可达的形态**。

### 6.2 臂（新工程 `build/MilBridge/tests/MinMaxProbe/**`）

- **入口**：**public** `TextFormatter.Create()` + `FormatMinMaxParagraphWidth(src, 0, para)`（零 IVT 即可；IVT 只借来读**正控** `MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics`）。
- **文本**：`"WWWW"`，em 24，`Liberation Sans`（与三支 tab 臂、W17A 臂**同一把尺子**）；`MmPara` 的 `Indent`/`ParagraphIndent` **恒 0**（不引入 P2 的位移）。
- **三个用例**：
  - `control` = 纯 `TextCharacters`（**阴性对照**，`modAt=-1` ⇒ 永不发 modifier）；
  - `mod0` = 零长 `TextModifier` 在 `cp=0`（**判别例**）；
  - `mod1` = `Length=1` 的 `TextModifier`（**TDT2 设计的形态**，用来实测它到底能不能到）。
- **正控**：每例之后读 `relaxedCalls/Handled/Failed/SkippedRuns` 的**增量**，`calls≥1 ∧ handled≥1` 才算"真走到了被测代码"，否则 `rc=2`。
- **归属**：程序印**已加载**那一份 `PresentationCore.dll` 的路径 + sha16 + 字节（`pc(已加载) = … sha16=…`）。
- **rc 语义**：`0` = 测到且与 `--phase` 声明的期望形态一致；`1` = 测到但形态不一致（判据红）；`2` = `NOINFO`（tier 未生效 / 字体面解析失败 / 抛异常 / 正控为假）。**臂源码 `cfcf464457163280`（20,528 B）｜产物 `a7a7aaa7b6df9451`（18,944 B）。**

### 6.3 修前读数（权威 `pc 1280323c9173bcde`，`rc` 与逐字输出）

```bash
cd build/MilBridge/tests/MinMaxProbe/bin/Release
dotnet PresentationCore.Tests.dll --case mod0 --phase prefix      # rc=0
dotnet PresentationCore.Tests.dll --case control --phase prefix   # rc=0
dotnet PresentationCore.Tests.dll --case mod1 --phase prefix      # rc=2（NOINFO：异常）
```
```
pc(已加载)  = …/bin/Release/PresentationCore.dll  sha16=1280323c9173bcde  bytes=4195328
TierSteer   : 设 WPF_LINUX_TEXTLINE_FALLBACK=0 ；读回=0 ⇒ OK
PREDICT mod0/prefix : min≈(W 的 advance @em24) > max=0.000000  ⇒ rel=gt
GETTEXTRUN 调用序（3 次；chars=1 mod=1 eop=1 null=0）：
   #0 cp=0->ZeroLenModifier(Length=0)
   #1 cp=0->TextCharacters("WWWW",0,4)
   #2 cp=4->TextEndOfParagraph(1)
正控 增量   = relaxedCalls+1 relaxedHandled+1 relaxedSkippedRuns+1
MINMAX CASE mod0 RESULT min=22.652344 max=0.000000 rel=gt min_minus_max=22.652344
MINMAX CASE mod0 判据 phase=prefix expect rel=gt measured=gt ⇒ GREEN
```
```
MINMAX CASE control RESULT min=22.652344 max=90.609375 rel=lt min_minus_max=-67.957031
MINMAX CASE control 判据 phase=prefix expect rel=lt measured=lt ⇒ GREEN
```
```
MINMAX CASE mod1 EXCEPTION EntryPointNotFoundException: Unable to find an entry point named 'LoCreateContext' in shared library 'PresentationNative_cor3.dll'.
MINMAX CASE mod1 RESULT min=NA max=NA rel=NA verdict=NOINFO（异常 ⇒ 未测到）
```

### 6.4 修后读数（权威 `pc 14086882b1509dcd`）

```
MINMAX CASE control RESULT min=22.652344 max=90.609375 rel=lt min_minus_max=-67.957031   （rc=0，与修前**逐位相同**）
MINMAX CASE mod0    RESULT min=0.000000  max=0.000000  rel=eq min_minus_max=0.000000    （rc=0）★ 翻转
MINMAX CASE mod1    EXCEPTION EntryPointNotFoundException …（rc=2，与修前**相同**）
```
正控每例都是 `relaxedCalls+1 relaxedHandled+1`（`mod0` 另有 `relaxedSkippedRuns+1`，`lastSkip="ZeroLenModifier x1"`）。

### 6.5 翻转表 + 单变量归因

| 用例 | 修前 `1280323c9173bcde` | 修后 `14086882b1509dcd` | 结论 |
|---|---|---|---|
| `control`（无 modifier） | `min=22.652344` / `max=90.609375` / `lt` | `min=22.652344` / `max=90.609375` / `lt` | **逐位不动**（阴性对照） |
| **`mod0`（零长 modifier）** | **`min=22.652344` / `max=0.000000` / `gt`** | **`min=0.000000` / `max=0.000000` / `eq`** | **`min > max` → `min = max`（契约违反消失）** |
| `mod1`（`Length=1`） | `NOINFO`（LS 异常） | `NOINFO`（LS 异常） | 两相相同，**P3 对它零射程**（它根本到不了这一层） |

**单变量归因（`proven`）**：`control` 与 `mod0` 的**唯一**差别 = `CollectLenient` 有没有在 `cp=0` 记下 modifier（文本、字体、em、段落属性、tier 全同）⇒ 修前 `max` 由 `90.609375` 掉到 `0.000000` **只能**归给 `modifierOpenIndex: modOpen2` 这一路（`mod0` 的 narrow 探针拿不到它 ⇒ `min` 两例都是 `22.652344`）。
**机制（代码级 `proven`，数值为实测）**：shim `BreakParagraph:1729-1734` 在 `modifierOpenIndex >= 0` 且 `modifierScopeEnd < 0` 时把 `[open, len)` 的 advance 全置 0；`BuildLine` 侧同理（`:2843-2854` 按 cluster 落 0）⇒ 宽=∞ 时全零宽 ⇒ `max = 0`；宽=0 时"零宽 ⇒ 全部放得下 ⇒ 单行" ⇒ `min = 0`。修前 min 那一侧没收到作用域 ⇒ 仍按真 advance 逐字断行 ⇒ `min = 22.652344`（= `W`@em24 的 advance）。

### 6.6 同一臂二进制 × 两个 pc（把"读数 = pc 字节的函数"钉死）

把 §3.1 另存的**修前权威产物**拷回臂的输出目录，**同一个臂二进制**（`a7a7aaa7b6df9451`）重跑：

| 已加载 pc | `mod0` 读数 | `control` 读数 |
|---|---|---|
| `1280323c9173bcde`（另存的修前件） | `min=22.652344 max=0.000000 rel=gt` | `min=22.652344 max=90.609375 rel=lt` |
| `14086882b1509dcd`（现权威件） | `min=0.000000 max=0.000000 rel=eq` | 同上，逐位相同 |

⇒ 两次读数**只随 pc 字节变**，不随树状态/目录/时刻变。**可重复性**：同一命令连跑两次，机读行（`RESULT`/`GETTEXTRUN`/正控/`DIAG`）**逐行相同**（`MACHINE_LINES_IDENTICAL`；stdout 整体含 `time=`/`loadavg`/`elapsed_ms`，故**不**逐字节相同 —— 这一点写明，免得被当成"不可重复"）。

---

## 7. `PcLineOracle` 复跑：**射程外逐位不动**

命令与 `W17B-report.md` §5.1 **逐字相同**（含它的 `--known-red` 文件，`89324f1f643167e5`，17,501 B）：

```bash
export PATH="$HOME/.dotnet:$PATH"
dotnet build -m:1 -c Release build/MilBridge/tests/PcLineOracle/PcLineOracle.csproj     # BUILD_RC=0  error_CS=0
cd build/MilBridge/tests/PcLineOracle/bin/Release
dotnet PresentationCore.Tests.dll --pc-lines-oracle \
  tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json \
  --leg b --known-red $HOME/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt
```

| 量 | 值 |
|---|---|
| `rc` | **0** |
| **stdout sha16** | **`07615909a1ffaa8b`**（122,518 B） |
| 与 W17B 交付 `$HOME/wfp-runs/w17-laneW17B/postfix/stdout.txt`（`07615909a1ffaa8b`） | **`cmp` 逐字节相同**（`CMP_IDENTICAL_WITH_W17B_DELIVERY`） |
| stderr | 0 字节 |
| `pc` 跑前 / 跑后 | `14086882b1509dcd` / `14086882b1509dcd`（可归因） |

逐字判据行：
```
PCLINE LEG=B 合计 cases=436 判定过=172 判定红=116 不可比(缺字形)=148（其中非0缩进 40、零缩进 108） 其中 bidi 重排例=2
PCLINE LEG=B 非0缩进: 红=72 绿=112 /224；零缩进: 红=44 绿=60 /212；PI≠0: 红=35 /112
PCLINE LEG=B 正控 relaxedCalls=496 relaxedHandled=496 relaxedFailed=0 …（本腿 relaxedCalls 增量=496）
PCLINE 登记表=…/pc-line-oracle-known-red.txt ⇒ 已登记 136 条
PCLINE 未登记失败=0
PCLINE_EXIT rc=0（未登记失败 0 / 红 116 / 绿 172 / 不可比 148）
```
⇒ **每一个分桶数字都与 W17B 修后交付逐位相同，且整份 stdout 字节相同** —— 这是"P3 在那支臂射程之外"的**机器断言**，不是论证（依据：那支臂只调 `FormatLine`，从不消费 `minWidth`；TDT2 Claim 2 + W17A/W17B 已各自复核过 13 支宿主与真机 oracle 侧 `min|max` 字段）。

---

## 8. 读数表

### 8.1 环境（lane=W17D）

| 时刻 | 事件 | `loadavg` | `MemAvailable` |
|---|---|---|---|
| 2026-09-16 12:11:22 +0800 | 开工 | `0.69 0.98 1.00` | 2,806,876 kB |
| 12:17:26 → 12:18:58 | `PcLineOracle` 复跑 | `4.96 2.45 1.55` → `2.37 2.32 1.60` | 2,528,896 kB → 3,403,548 kB |
| 2026-09-16 12:19:14 +0800 | 收尾 | `1.84 2.20 1.57` | 3,664,432 kB |

`kernel = 6.8.0-138-generic`。**并发说明**：本轮与任何其它车道**没有共享被测件**（本波 P1/P2 的车道已在 11:20 / 12:09 收工；`pc` 在本轮内**只被本车道改过一次**）。
**读数时段**：`pc` 在 12:17:13 换件，修前读数全部在 12:12–12:13 取（`pc = 1280323c9173bcde`），修后读数全部在 12:17:2x 之后取（`pc = 14086882b1509dcd`）。

> ⚠️ **一件现场事实（纪律 15/18 要求点名；不是本车道所为）**：`docs/CURRENT-STATE.md` 在本轮窗口内被**别的车道**改过 —— 开工时 `aec7db3835f815ff`（159,443 B @ 11:58:42），收尾时 **`9af50699f922ab8b`（161,569 B @ 12:18:07）**。**本车道没有写过 `docs/**` 一个字节**（禁改清单），且该文件**不参与编译**、不在本件任何判据的输入里 ⇒ **本件读数不受它影响**；点名是为了让收尾者知道"12:18 那一次文档改动不是 W17D 的"。


### 8.2 件 sha16 / 字节 / mtime

| 文件 | sha16（前→后） | 字节 | mtime |
|---|---|---|---|
| 应用器 `…/patch-presentationcore-textline-fallback.py` | `a3357070dae6de99` → **`188f75a67294138f`** | 41,304 → 44,274 | 09-16 11:59:21 → **12:15:51** |
| 生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | `9fd04d10a6479dcd` → **`56a5b4a5be1c6bcc`** | 52,598 → 53,783 | 09-16 12:05:21 → **12:18:00** |
| **权威 `pc`** `…/bin/Debug/PresentationCore.dll` | `1280323c9173bcde` → **`14086882b1509dcd`** | 4,195,328 → 4,195,328 | 12:00:10 → **12:17:13**（复建后 12:19:35，sha 不变） |
| `pc` .pdb | `be6de7589ec7cbf7` → `e31bef2b22c2b8c8` | 2,159,556 → 2,159,556 | 12:00:10 → 12:17:13 |
| **新臂源** `build/MilBridge/tests/MinMaxProbe/Program.cs` | **`cfcf464457163280`** | 20,528 | 09-16 12:14:56 |
| **新臂工程** `…/MinMaxProbe/MinMaxProbe.csproj` | **`d6e45fd3ecf893bf`** | 3,703 | 09-16 12:14:06 |
| 新臂产物 `…/MinMaxProbe/bin/Release/PresentationCore.Tests.dll` | `a7a7aaa7b6df9451` | 18,944 | 12:17:28 |
| `PcLineOracle` 臂源（**未动**） | `544aab374ee8e1a6` | 57,572 | 09-16 11:44:53 |
| `PcLineOracle` 工程（**未动**） | `b0bf270206fe9c09` | 4,380 | 09-16 11:09:12 |
| `PcLineOracle` 产物（被 §7 的**强制命令**重编） | `3a474e675b24fdf4` → `4ee1a17904839e22` | 38,912 | 12:00:20 → 12:17:26 |
| `build/shims/PresentationCore.HbTextLine.cs`（**未动**） | `bc04c05ab6d8d82a` | 275,765 | 09-15 18:25:25 |
| `build/PresentationCore.Linux/PresentationCore.Linux.csproj`（**未动**） | `26ce64b8f4452ed4` | 205,939 | 09-16 11:09:03 |
| `HbTextLineShimSha.targets`（**未动**） | `3aa64fd08fc7ea05` | 4,908 | 09-16 11:09:00 |
| 语料 `tests/…/tab-anchor-oracle.json` | `a31a813114256faf` | 1,251,441 | 09-14 19:33:26 |
| 登记表 `$HOME/wfp-runs/w17-laneW17B/pc-line-oracle-known-red.txt` | `89324f1f643167e5` | 17,501 | 09-16 12:00 |

> **纪律 34 的点名**：`build/MilBridge/tests/PcLineOracle/**` 在禁改清单里。被我改动的是**它的构建输出**（`bin/` `obj/`），来源是**派单要求的"用 §5.1 那条命令复跑"**（那条命令的第一步就是 `dotnet build …PcLineOracle.csproj`）。它的**源**（`Program.cs` / `.csproj`）**一个字节未改**（sha 见表）。W17B 复跑时同样如此。

### 8.3 本轮产生的读数文件（`$HOME/wfp-runs/w17-laneW17D/`）

| 文件 | sha16 |
|---|---|
| `prefix/mod0.txt` / `prefix/control.txt` / `prefix/mod1.txt` | `274fe4f9109cab3c` / `5bb5d2bd8e49dd52` / `dd6742397dfc0e84` |
| `postfix/mod0.txt` / `postfix/control.txt` / `postfix/mod1.txt` | `0c27f65a38008be0` / `08ee4a586a8cc510` / `0651d59054b3928c` |
| `prefix-reeval/mod0.txt` / `control.txt`（同一臂二进制 × 修前 pc） | `e455a1e7270d3dad` / `766327f719b18da3` |
| `postfix-private/mod0.txt`（私产 pc `c4f9c1f18b5f01de`） | `767d7ec2d4e3a819` |
| `pcline-postfix/stdout.txt` | **`07615909a1ffaa8b`** |
| `pc-prefix-1280323c9173bcde.dll`（另存的修前权威产物） | `1280323c9173bcde` |
| 牙齿实验 `teeth-E1.log` / `teeth-E2.log` / `teeth-E3.log` | `rc=1` 各一次 |

---

## 9. 没能建立的东西 + `D-T2-c` 登记

| # | 没能建立的 | 为什么 | 需要什么 |
|---|---|---|---|
| 1 | **真机 `MinWidth`/`MaxWidth` 的数值真值** | `tests/parity/windows/**/*.json` 30 份**没有** min/max 段落宽字段（TDT2 §3.2③ 复核过）⇒ 本件判的是**内部一致性契约**（`MinWidth ≤ MaxWidth`），**不是**"对齐真机" | Windows 侧 `tab-anchor` oracle 宿主加一次 `FormatMinMaxParagraphWidth` + 重跑 `run.ps1`（TDT2 §4.2 已写死） |
| 2 | **修好后两边到底对不对** | 修后两个探针**都**用 `[open, 段末)` 的**已知错**跨度（R17A §2.2 判定）⇒ `min = max = 0` 这个值本身**不是真值**，只是"两支不再互相矛盾" | 见 #1；且要先满足 `D-T2-c` 的前置 |
| 3 | **本件在真实（`Length ≥ 1`）modifier 段落上的行为** | 那种段落**根本到不了**这两个探针（§6.1/§6.4 的 `mod1` 实测：LS 异常）⇒ P3 对它的射程 = **0** | 另立一件：让 `CollectLenient` 对 modifier run **跳过而不是 return false**（属 PC 接线点，写域在应用器）；**本件不做**（同件不许顺手改第二处） |
| 4 | **`@…@tab0` / 严格档**等既有射程限制 | 与本件无关（沿用 W17A/W17B 的登记） | — |
| 5 | 应用门禁 / 五臂 | 本轮**没有**跑（那是波收尾的活，且需要静树）；本件的"逐位不动"证据是 §7 那一支臂 + §6.5 的阴性对照 | 波收尾按 `WAVE17-PREREGISTRATION.md` §3.1 走 |

### 9.1 `D-T2-c` 登记（**只登记，零代码改动**）

**结论：max 探针那条 `scopeEnd = -1` 仍然是那把"已知错"的尺子，且本件**没有**动它。**

- **现场实读（修后生成物 `56a5b4a5be1c6bcc`）**：max 探针 `:305-307` 传了 `modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2`，**没传** `modifierScopeEnd`；min 探针 `:321-323` 现在**传的是同一组**。两者都拿默认 `-1`。
- **`-1` 的语义（shim 自述）**：`build/shims/PresentationCore.HbTextLine.cs:3854-3858` 逐字 —— "客户端覆盖的**字符范围终点** `modifierScopeEnd`（半开；`-1` ⇒ 到段末）。它**不等于** `closeIndex` … 若拿 `close<0` 当'到段末'，会把 [6,63) 全零宽 ⇒ **实测 `w=43.59`，而真值 `156.9167`**"；消费点 `:1729-1734`（`kh = (modifierScopeEnd < 0 ? len : …)`）。
- **为什么今天不能改**：PC 的 `CollectLenient`（生成物 `:101-103`）的形参表**根本没有** `out int modifierScopeEnd`（`:156-157` 只记 open/close，且 `:107-112` 自述 R1 配对规则是"**未验证的选择**"）⇒ **这个量今天取不到**。要改 max 的 `scopeEnd`，只能填一个**猜**的值 ⇒ **等于编一个值**（纪律 22 明令禁止）。
- **⇒ 登记为 `D-T2-c`**（预登记 §1 P3 / §2 已点名）：**"PC 宽松层的两个探针共用一把已知错的尺子"**，根因 = `CollectLenient` 不收集"覆盖终点"。**前置条件** = `CollectLenient` 增加 `out int modifierScopeEnd`（并从 `TextSource` 的 run 序列推出覆盖终点，而不是拿 `closeIndex` 冒充）；**前置未满足前不许改**。
- **文档落点**：`docs/CURRENT-STATE.md` §4 与本预登记 §2 的 `D-T2-c` 行**属主控写域**（`docs/**` 在禁改清单里）⇒ 本车道的登记动作 = **本节 + 派单要求的"只登记不许改代码"**；请主控在收尾时把本节转写进文档。

---

## 10. 口径与纪律自查

- **纪律 15/18（读数 = 四元组）**：每条读数都带 **件 sha（`pc 1280323c9173bcde` / `14086882b1509dcd`，臂自己印的"已加载 pc"）+ 仪器 sha（臂源 `cfcf464457163280` / 产物 `a7a7aaa7b6df9451`）+ 判据口径（`min > max` / `min == max`，`rel` 的 `1e-9` 容差）+ artifact/字段名（`MinMaxParagraphWidth.MinWidth/MaxWidth`）**。
- **纪律 16（先备份）**：§3.1 两条 `cp -p` 备份 + 另存修前权威产物；**before sha16 全部拿到**。
- **纪律 33（`--check` ≠ 能编译）**：§4.1 私有目录 `error CS = 0`（`warning CS = 0`）与 §4.2 的 `--check`（改前 `rc=1` / 改后 `rc=0`）**分开写**。
- **纪律 21/25/27（判据必须能变红 + 正控）**：本件两极性**实测**（`gt` → `eq`），**阴性对照**两相逐位不动，**正控**每例 `handled+1`；三条新牙齿各自被 E1/E3/E2 打红过一次；"计数"都是数出来的（`:322-323` 与牙齿的 `2` 处）。
- **纪律 22（缺列不许补列）**：`scopeEnd` **没有**被填任何值；真机 min/max 真值不存在 ⇒ 只判内部一致性（§9）。
- **纪律 3（红检测只许加强）**：没有任何判据被放宽；`min=0` 这条新读数**不被**当成"对齐真机"。
- **纪律 32（谁跑的这趟）**：抬头 `lane=W17D` + 时刻 + `loadavg` + `MemAvailable` + `kernel`，§8.1 另有逐时段表。
- **`proven` / `not proven` / `not measurable`**：§6.5（翻转 + 单变量归因）、§7（逐字节不动）、§4.3（牙齿可红）是 **proven 实测**；§6.1 的"`Length ≥ 1` 到不了"是 **proven（代码级引文 + `mod1` 实测双证）**；§9 是 **not measurable / not proven**，且写明所需仪器。**本报告没有把任何不可测写成已证。**

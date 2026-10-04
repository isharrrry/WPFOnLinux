# W23D · `#23` P4 —— 只读设计（`hasOverflowed` 判据草案 + 「集合基数相等」落地草案 + 117 条 `@default` 帧红的登记口径 + `#22` 三条欠账排期）

> **lane=W23D**｜时间 **2026-09-16 23:55:32 → 2026-09-17 00:0x +0800**｜`kernel` **6.8.0-138-generic**｜`nproc=3`｜`loadavg` 开工 **0.70 0.34 0.14**、收尾 **3.57 2.69 1.30**（区间 0.70–3.57，**本波另有两条车道在跑构建**）｜`MemAvailable` 开工 **3,109,000 kB**、收尾 **3,634,160 kB**（`MemTotal` 8,113,356 kB、`SwapFree` 1,089,020 kB）。
> **硬约束遵守**：全程 **零 `dotnet`**（未 build / 未 run / 未 restore / 未 msbuild）、**零 `verify-all`**、**未 `pkill -f`**、**未修改任何既有文件**（唯一新建件 = 本报告）。收尾现场另有两条 **不是我的** `dotnet` 进程（PID **319070 / 319298**，别的车道，**未触碰**）。
> **本件的性质**：**设计 + 现算**。凡"我方侧取值"一律是**预测**（我无权取读数）—— 每条预测都写清它**条件于哪一条已测量的列**。**`NOINFO` 一处不省**（§7）。

---

## §0 一句话结论（四件各一条）

| 件 | 结论（一句话） |
|---|---|
| **1 · `hasOverflowed`** | 真值 **22 行 / 8 例，全部在 `script==latin` 的可判定集内**（不是"躺在不可比子集里"）；真值自身的规律**现算 615/615**（`paragraphStartOffsetDip + width > paragraphWidthDip`），与我方三分支实现的**第三条分支逐字同构**；⇒ **接线后预测红 = 0 行 / 0 例**（纪律 39 分母：latin **288 例 / 421 行**），但**有 74 行（latin 58 行 / 47 例）坐在"恰好到达边缘"的发丝扳机上** ⇒ 判据必须**连严格 `>` 的语义一起写死**，且**不能**拿既有 `最大差=0.0000` 当"宽度精确相等"的证据（它是**最大违规量**，不是最大偏差）。 |
| **2 · 「集合基数相等」** | **既有臂已经在断言它**（`CoverageProbe/Program.cs:1391`、`PcLineOracle/Program.cs:905`）—— 主控/`#22` 那句"既有臂按真值数组迭代 ⇒ 结构性看不见"**对这两支臂不成立**（真正失明的只有**逐行子循环**与 **TWIN/FrameProbe**）；60 例的**独立复算**（两支仪器、逐例对账）与 `#22` 逐位一致，且 **60/60 全部已在 `known-red.txt` 在册**、**60/60 的我方行数 == 真值孪生 `@default` 例的行数**（⇒ 机制 = `D-T4`「`DefaultIncrementalTab` 到不了工厂」这条**臂姿势限制**，**不是**产品多分行）⇒ **接线后新增未登记红 = 0 条**。 |
| **3 · 117 条 `@default` 帧红** | 精确形状 = **117 行 / 67 例（全 `@default`）**（另外 16 行 / 13 例是 `@tab0`，**已在** `known-red.txt`）；这 67 例**今天在任何登记表里都无法登记** —— 因为量它们的是 `FrameProbe`，而它**不在门禁、不在 `verify-all`、不在 `run.sh`**（`grep` 三处全 0）⇒ 真正的欠账是**接线**（`D-G2` 家族），不是登记；`W23B` 按预登记 §2.3 修完这批**预期自动透明**，**残留才需要裁决**（口径见 §4.3）。 |
| **4 · 三条欠账排期** | ① **117 条** ⇒ 与 `W23B` **自动消解**（不重复计工作量），`#24` 的真活是**把帧列接进一个门/步**；② **60 例多分行** ⇒ **不是缺陷、不排修**（在册 + 臂姿势 + 真值缺口），`#24` 只值得花 **1 行**把 TWIN 的"只印不判"升成判据；③ **78 行静默错** ⇒ 与 ① **同一批行、同一件工作**（消费者可见面），**不许重复计**。 |

---

## §1 现场与口径基线（读数表见 §8）

**树状态（现场取，逐件带时刻）**：`shim` `76089e1de586ac91`（283,557 B，mtime `2026-09-16 18:31:48`）｜`pc` `e7cabff9417ed380`（4,196,864 B，mtime `18:47:26`）｜**即本件全程都在 `#21` 冻树上**（`W23B` 的 shim 改动**此刻尚未落树**，`2026-09-17 00:02` 复取仍同）。
**权威基线**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **现场 sha16 = `4f4bfe732c097a77`**（185,962 B / 622 行，mtime `2026-09-16 20:32:54`）。
⚠️ **纪律 4/42 的现场（本件自己先写错、当场用现算更正）**：派单/预登记写的 `0d048e6e8808c4e7` **不是"表头行的 sha16"**（表头第 1 行现算 = **`c49d8fa93bafb76a`**），而是**`#21` 重冻那一刻整份文件的 sha16**（`W22A-report.md:5` 逐字"整文件 **`0d048e6e8808c4e7`** ✅ 逐位相符"）；该文件其后在 **`#22` 波尾**被追加了一段复核注记（`:7` 逐字"✅ **波 `#22` 复核（2026-09-16 20:3x）—— 零位移 ⇒ 本块仍是当前冻结基线** … **本次不重冻**"）⇒ **文件 sha 变、冻结内容未变**。⇒ **引用时必须写明"是哪一版文件的 sha"**：`0d048e6e8808c4e7` = `#21` 冻结点、`4f4bfe732c097a77` = `#22` 波尾之后的现行文件。（本件只报不裁；该注记在文件里**自述**了，我不把它算成未登记位移。）
**预登记**：`docs/WAVE23-PREREGISTRATION.md` —— 我**开工时读到的那一版** = **`72215b0f5ed741b3`**（17,268 B / 167 行，mtime `23:54:46`）；**收尾复取 = `6e2bb9a9e1d930ab`**（305 行，mtime `2026-09-17 00:04:16`）。
⚠️ **纪律 35 的现场（读数之后仪器变了 ⇒ 作废的是「配对」，不是「读数」）**：主控在我工作期间**追加**了 §9（开工后两条裁决 + `D-G7`）、§10（P3 收官），并**更正了 §6 第 6 条**（`17` 份红的停条件撤回）。我已**逐节复核**：① **§4（P4 本件任务）逐字未变**；② §6 其余停条件与 §7 内存纪律未变；③ 新增的 §9.4（主控自纠「帧列没有 `88` 例」）**与本件 §4.2 的现算一致**（见 §4.2 末尾）。⇒ 本报告读数**仍有效**，配对写在此处。
**语料（本件全部现算的输入）**：
| 语料 | sha16 | 大小 | 行/例 | `hasOverflowed==true` |
|---|---|---|---|---|
| `tests/parity/windows/tab-anchor/out/tab-anchor-raw.json`（**`PcLineOracle`/`FrameProbe` 用**） | **`88559d670f1bb955`** | 1,196,289 B | 436 例 / 615 行 | **22** |
| `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`（**三支 tab 臂的输入**，`analyze.py` 产出） | **`0cebc0afd5142fbf`** | 1,252,008 B | 436 例 / 615 行 | **22** |
| `tests/parity/windows/tab-zero/out/tab-zero-oracle.json` | — | 238,351 B | 86 例 / 138 行 | 0 |
| `tests/parity/windows/tab-rtl/out/tab-rtl-oracle.json` | — | 297,654 B | 84 例 / 163 行 | 0 |
| `tests/parity/windows/tab/out/tab-oracle.json`（U1，**逐例**结构） | — | 298,055 B | 114 例 | **36** |
| `tests/parity/windows/modifier-scope/out/modifier-scope-oracle.json` | — | 504,676 B | 53 例 / 194 行 | **8** |
| `tests/parity/windows/layout-b34/windows-results.json` | — | 57,715,362 B | 1,617,780 行文本 | **字段不存在**（`grep -o '"hasOverflowed"'` = **0**） |

**分母口径（纪律 39，本报告全文适用）**：三支 tab 臂的可判定集 = **`script==latin` 的 288 例 / 421 行**（依据 = 臂自己的 `TAB_LINES 合计 cases=436 判定过=288 结构败=0 不可比(缺字形)=148`，`build/MilBridge/arm-logs/tab-anchor.log` **`1a5bc7181d0155c3`**）；**全域** = 436 例 / 615 行。`latin` 的 421 行**全部**通过覆盖闸（`W22C` 的 `FRAMEPROBE 口径 … 覆盖闸跳过例=0`）。⇒ 本件凡写"预期红/绿"，**两个分母都写**。

---

## §2 件 1 · `hasOverflowed` 判据草案

### 2.1 真值在哪、有几个（**现算，不抽样**）

**字段**：`cases[].lines[].hasOverflowed`（布尔，**615/615 行非 null**）。**两份语料同值**（`raw` 与 `oracle` 的 `cases` 块逐字同源，`#21` 纪律 40 的机器证）。

**现算（`script` 全域 / latin 两个分母都给）**：

| 量 | 全域 | `script==latin`（= 臂的可判定集） |
|---|---|---|
| 行 | 615 | 421 |
| `hasOverflowed == true` | **22** | **22**（**100% 在可判定集内**） |
| 含 true 行的**例** | **8** | **8** |

**22 行的形状**：**全部**满足 `group == B-indent-extra` ∧ `indentArm == i24p24`（`Indent=24` **且** `ParagraphIndent=24`）∧ `paragraphWidthDip == 40` ∧ `script == latin`；8 例 = 4 个 `textId`（`lead-tab-a`、`lead-tab-b-t-c`、`mid-tab-a-t-b`、`notab-control`）× {`@…@default`, `@…@tab0`}。
**机制一句话**：`Indent + ParagraphIndent = 48 ≥ paragraphWidth = 40` ⇒ **内容起点本身就在行盒远缘之外**，所以**整段的每一行都溢出**（连只装一个 `\t` 的行也是 `hasOverflowed=true`，见 `B-indent-extra/lead-tab-a@w40@LTR@i24p24@default` 行#0：`width=24`、`perChar=[(i=0,'\t',x=48,width=0)]`、`hasOverflowed=true`）。

**⇒ 我推翻派单里的一句隐含前提**：这 22 行**不在**"不可比子集"里（不是 `hebrew`/`arabic` 那 148 个缺字形例）—— 它们是 **latin、可判定、臂今天就能看到的行**。所以"加一列会 NOINFO 一片"的顾虑**不成立**：本列的**可判定面就是 288 例 / 421 行**。

### 2.2 判据怎么取数

| 侧 | 取数 | 出处（行号级） |
|---|---|---|
| **真值** | `cases[].lines[].hasOverflowed`，**按真值数组下标 `k`** 与第 `k` 行配对 | `tab-anchor-oracle.json`（`0cebc0afd5142fbf`）；三支臂共用入口 `CoverageProbe/Program.cs` 的 `--tab-lines-oracle` 路径（比较区 `:1391-1544`） |
| **我方** | 逐行 `L.HasOverflowed`（`bool`，**无容差**） | `build/shims/PresentationCore.HbTextLine.cs:3466-3476`（`public override bool HasOverflowed`） |
| **断言** | `bool ours == (bool)truth`（**布尔全等，不是"阈值"**） | —— |
| **可比性闸门** | ① 该例过了覆盖闸（`latin`）② `lines.Count == truth.lines.Count`（**行数不符 ⇒ 该行 NOINFO**，照 `Start` 列 `#22` 的既有做法 `:1513` 的 `行数不符` 分支）③ `TextAlignment == "Left"`（`startAssert = startField && startAlign == "Left"`，`:1312`）④ 语料 `paragraphProperties.fixed` 钉死 | `Program.cs:1391`（行数）、`:1392`（`why` 串）、`:1513`（行数不符的 NOINFO 口径）、`:1312`（对齐闸门） |

**⚠️ 判据必须写死的两条语义**（否则是"编一个口径"）：
1. **严格 `>`**：实现是 `_boxOriginX + _width > _paragraphWidth + 1e-9`（`shim:3475` 逐字注释"**严格 `>`**（相等 ⇒ false）"）⇒ 判据**只断言等值**，**不许**在臂侧另发明容差（那会与实现的口径打架）。
2. **只对 `TextAlignment=Left` 断言**（与 `Start` 列同一条纪律）；`Right`/`Center`/`Justify` ⇒ **NOINFO，不许发明公式**（本语料 436/436 全 `Left`，`:106` 的既有闸门）。

### 2.3 真值侧规律**现算**（阳性对照：证明这列有判别力、不是"编出来的"）

对 **615/615 行**（不抽样）逐行重算候选公式，与真值 `hasOverflowed` 对比：

| 候选规律（全部用**真值自己的**几何量） | 判为 true 的行 | 命中真 true | **假阳性** | **漏判** | 判定 |
|---|---|---|---|---|---|
| `paragraphStartOffsetDip + width > paragraphWidthDip + 1e-6` | 22 | **22** | **0** | **0** | ✅ **615/615 精确复现** |
| `perChar[i].x + width > W`（用**内容起点**而非盒原点） | 111 | 22 | **89** | 0 | ❌ 假阳性 89 |
| `paragraphStartOffsetDip >= W`（只等价 branch ②） | 0 | 0 | 0 | **22** | ❌ 全漏 |
| `max(perChar.x + perChar.width) > W`（内容右缘） | 22 | 22 | 0 | 0 | ✅（与本一行等价） |

⇒ **真值的 `hasOverflowed` 就是"盒原点 + 行宽 > 段落宽"**，而**盒原点 = `paragraphStartOffsetDip`（= `TextLine.Start` = `ParagraphIndent`）** —— 这正是 `D-O1` 三分支里**第三条分支**的形态（`shim:3461` 的注释与 `:3475` 的代码）。
**这条现算同时是判据的阳性对照**：真值域 **{False: 593, True: 22}**（不是常数）⇒ 加列**有判别力**（纪律 3/27 要的"不是恒绿/恒空"）。

### 2.4 反极性与分母口径（**预测，不是读数**）

我方实现的**输入逐条落到语料上**（静态读码，逐条给行号）：
```
shim:2905-2906   new HbTextLine(..., indentDip + paragraphIndentDip,   // ← _startPenX（合量）
                                    paragraphIndentDip,                 // ← _boxOriginX（= PI）
                                    paragraphIndentDip);               // ← _paragraphIndentDip（Start）
shim:3473-3475   if (!(_paragraphWidth > 0)) return false;
                 if (_startPenX >= _paragraphWidth) return true;
                 return _boxOriginX + _width > _paragraphWidth + 1e-9;
```
⇒ 我方 = `PI + width > W`（branch ③）**or** `Indent+PI >= W`（branch ②）。
**用真值的几何代入这套式子**（等价于假设"我方 `PI`/`width`/`Indent` 与真值相同"——**这个前提是被测量过的**，见下）⇒ **错配 0 行 / 0 例（615/615 及 latin 421/421）**。

**前提的三条已测量依据**（不是我推的，是门禁臂今天印的读数）：
1. **`PI`**：`TAB_LINES START 红=0 绿=421 判定行=421 …`（`tab-anchor.log` `1a5bc7181d0155c3`）⇒ 我方 `Start`（≡`ParagraphIndent`）在**全部 421 latin 行**上与真值逐位相等；
2. **内容起点 `Indent+PI`**：`TAB_LINES   B-indent-extra/…结构 18/18；位置可比 18 其中过 18`（同日志尾部逐族表）⇒ 逐字 `perChar.xFromLeftDip` 在**可判定例上全过**；
3. **`width`**：同一行的 `结构=PASS` 要求 `|Δwidth| ≤ 0.05`（`:1402`）。**⚠️ 但 `最大差=0.0000` 不是"精确相等"的证据** —— 读码：`worst` 只在 `if (dW > 0.05)` 分支里更新（`:1400` 算 `dW`、`:1402` 更新 `worst`）⇒ 那行是"**最大违规量**"，没有违规时恒印 `0.0000`。（`W22B` §4 的表里把 `最大差=0.0000` 当"逐位不变"的同义词用过，这里**更正语义**。）

**⇒ 反极性的四种预测（全部现算，分母两个都给）**：

| 突变（判据要能把它抓红） | 预测红行 | 预测红例 | latin 行 / 例 | 说明 |
|---|---|---|---|---|
| **(a) `HasOverflowed => false`**（`D-O1` 修前形态） | **22** | 8 | 22 / 8 | 首选反极性：**正好命中那 22 行** |
| (a′) `=> true` | 593 | 428 | 399 / 280 | 第二极性（防"恒真"作弊） |
| **(b) 错驱动量：`_startPenX + _width > W`**（用内容起点替盒原点） | **89** | 54 | 79 / 48 | 与 `#21` 的"红证 (b)"同形（错驱动量必须红） |
| **(e) 去掉严格性（`>=`）** | **74** | 63 | 58 / 47 | **发丝扳机**：只差 1e-9 就能红 74 行 |
| (c) 删掉 branch ② | **0** | 0 | 0 / 0 | ⚠️ **本语料行使不了 branch ②** ⇒ 覆盖边界（§7） |

**（e）的机制（必须一起写进判据说明）**：**74 行**（latin **58 行 / 47 例**）满足 `paragraphStartOffsetDip + width == paragraphWidthDip`（**余量恰为 0**，全语料 `margin ∈ (-0.05,0)` 的 False 行 = **0** 条）—— 它们是"`\t` 被钳满整行"那族（`breakCause=after-tab`、`lineText="\t"`、`width == W`）。真值说 **`false`**（"恰好到达边缘不算溢出"，正是 `D-O1` 注释 `:3469` 那句 Q11 反例批）。⇒ **这 74 行的判定完全依赖"我方 `width` 不比真值大 1e-9 以上"**，而`width` 列**只保证 ≤ 0.05**。⇒ **判据接线时必须同时给一条"边界行宽度"读数**（或把这 74 行单列成 `NOINFO=边界行`），**不许**把"宽度差 0.03 导致翻面"读成产品缺陷。

### 2.5 放在哪一层（三选一，给理由）

| 候选 | 判 | 理由 |
|---|---|---|
| **`CoverageProbe --tab-lines-oracle`（三支 tab 臂）** | ✅ **首选** | ① 它**在门禁里**（五臂之一，`tab-oracle-anchor`），未登记红会**经 `failures` 通道进 rc**（`Program.cs:1560` 的既有做法）⇒ 才可能"变红有人管"（纪律 41 第三种强度）；② 它的**输入就是带真值的 `tab-anchor-oracle.json`**（`0cebc0afd5142fbf`），**新语料字段零成本**；③ 它**已经在断言行数**（`:1391`）⇒ 直接满足纪律 45；④ 它**已经**喂 `pw`（`:1378` 的实参）与 `indentDip`/`paragraphIndentDip`（`:1381`）、`defaultIncrementalTab`（`:1380`） ⇒ 三分支的输入**全都在**。 |
| `PcLineOracle` | ⭕ 次选（**若要量"产品路径"就选它**） | 它驱动**产品 `TextFormatter`**（`verify-all` 第 [5] 步的仪器）⇒ 量的是"应用路径上的 `HasOverflowed`"，与本臂的"源直调层"**不是同一条链**（`W22B` §10.6 的同族边界）。**代价**：登记要走**另一张表**（`known-red.txt`）⇒ 两套登记口径。**建议：先只做首选那一条**（一个家，一套登记）。 |
| 新探针（照 `FrameProbe`） | ❌ **不建议** | 那正是 `D-G2`/`D-G5` 的病：新探针**不在任何门里**（`FrameProbe` 今天 `grep` 门禁/`verify-all`/`run.sh` **三处全 0**）⇒ 判据"只活在报告文字里"。**除非同时接线**，否则等于**再加一个没人跑的好仪器**。 |
| **额外高判别力候选（登记，不建议本波做）** | ⭕ | `CoverageProbe --tab-oracle`（U1 语料 `tests/parity/windows/tab/out/tab-oracle.json`，**114 例 / 36 例 `hasOverflowed=true`** = **32%**，比 tab-anchor 的 22/615 = 3.6% **判别力高一个量级**）**已经在探针里**（`:703`/`:726`）但**不在任何门里**（`grep --tab-oracle run.sh/verify-all.sh/*.sh` = **0**）。⇒ 若将来要给这列"最锋利的尺子"，是**给这条路接线**，不是改判据。 |

**⚠️ 首选层的两条已知边界（不许读过头）**：① 它内联 shim **源**（`<Compile Include="$(HbShimSrc)">`，纪律 36 的机制）⇒ 证的是**源直调层**，**不是**应用路径（`W22B` §10.6）；② 它**不经 PC `TextFormatter`**（`D-G2` 原文）。

### 2.6 会不会与既有 `known-red` 冲突

**两份登记表的分工见 §4.1**。就本列而言：
- **中心表 `build/MilBridge/known-red.json`**（**`2fdc02931c2af796`**，`schema tline-known-red/4`，`generation.id=#21`）**只有 4 条** = 3 条 `tline` + **1 条 `tab-oracle-zero`**；**`tab-oracle-anchor` 一条都没有**（该臂今天全绿）⇒ **预测红 = 0 ⇒ 无冲突、无需登记**。
- **反极性/两极化时的临时红**：按 `#22` 的既有做法走**探针自带表**（`CoverageProbe/known-red.txt` **`e37603a8825d85ae`**）**且绝不进中心表**；注意**探针自带的 `KNOWN-RED` 行在门禁里等于"未登记"**（`tline-gate.sh:511-514` 逐字"**只在探针自带表里登记**（中心登记表没有）⇒ 视为未登记失败"）⇒ **它洗不绿任何东西**（这是好事，也是"临时表只许放私有目录"的理由）。
- **若将来真红**：那是**新未登记红** ⇒ `unregistered>0` ⇒ `GATE_REASON=unregistered-failure`、**rc=1**（`tline-gate.sh:504-510` + `:647-656`）⇒ **正确行为**：登记是主控的决定（`W23D` 无此写域，本件一个字未改）。

### 2.7 接线后会不会立刻产生未登记红

**预测：0 条（0 行 / 0 例）**，分母 = **latin 288 例 / 421 行**（全域 436/615 同结论）。
**条件（必须一起写）**：条件于 §2.4 的三条已测量列（`Start` 421/421 全绿、逐字 `xFromLeftDip` 全过、`width` 在 0.05 内）。**风险带**：若我方 `width` 在那 **58 个 latin 零余量行**上比真值大 ≥1e-9 ⇒ 那 58 行（47 例）翻红 ⇒ 接线首趟就会是 `红=58`。⇒ **接线时第一件事是看这个数是不是 0**；不是 0 ⇒ **先查宽度**（`D-O1` 的盒几何/钳位），**不许**改判据的容差。

### 2.8 `D-O1` 的连带风险（**必须写清**）

`HasOverflowed` **同时是折叠资格闸门**的输入：`shim:3533`
```
if (!HasOverflowed && !_keepState) { HbTextLineScaffold.NoteCollapseIneligible(); return this; }
```
`#16` 的 `D-O1` 落地时**实测**过它的爆炸半径（`known-red.json` 的 `tline` 第一条逐字）：`collapseIneligible 2090→2088`、`collapseApplied 236→237`、`collapsedRangesReturned 236→237`。
⇒ **两条纪律**：① **本列判据只读 `HasOverflowed`、不改它** ⇒ 按构造**零位移**（与 `W22B` 的"只新增"同形）；② **但若本列红了、而有人去"修 `HasOverflowed`"** ⇒ 折叠族会**成批移动** ⇒ 必须按 `#16` 的既有裁定**与折叠族分开取读数**（同一读数两族齐变 ⇒ 该结论作废）。**这一条要写进接线 PR 的注释里**，否则未来的修法会污染折叠归因。

### 2.9 §2 附带发现：`shim:3453` 那条注释本身是**同族伪证**（第三落点，`Start` 那条已修、这条没修）

`shim:3453` 逐字：「真机实测：**3222/3222 行全为 false** —— 那是**真机语料**的分布，**不是**本实现的取值域。」
现算反例：
- 唯一含 "3222" 的语料是 `layout-b34/windows-results.json`（57,715,362 B），其 `indexFrames.lineStart` 逐字写「`TextLine.Start` **恒为 0**（实测 3222/3222）」—— 那是 **`Start`** 的口径；而**该文件里 `hasOverflowed` 字段出现 0 次**（`grep -o '"hasOverflowed"' | wc -l` = **0**）⇒ 这条 3222 与 `HasOverflowed` **没有任何数据关系**。
- 仓内**有真值**的语料里 `hasOverflowed==true` 共 **66 行**：`tab`（U1，**36 例**）、`tab-anchor`（**22 行**）、`modifier-scope`（**8 行**）。
⇒ 这是**纪律 43**（"全称断言必须现算 + 给反例计数"）的**第三处落点**（前两处 = `D-T6-c` 的 shim 注释 + `analyze.py` 的手写串，`#21` 已处置）。**处置**：改它的**代价 = 改 shim = 换世代**（纪律 31）⇒ **不许顺手改**；建议**与下一次动 shim 的波合并**（`W23B` 正在动 shim ⇒ 若还来得及，主控可决定是否搭车；**本件无权改**）。

---

## §3 件 2 · 「集合基数相等」落地草案（纪律 45）

### 3.1 现状实测：**四个地方，谁在断言行数**（行号级）

| 位置 | 现在做什么 | 证据 |
|---|---|---|
| **`CoverageProbe --tab-lines-oracle`（三支 tab 臂）** | ✅ **断言**：`bool structOk = lines.Count == exp.GetArrayLength();`，不满足 ⇒ `why = "行数 期望=X 实得=Y"` | `Program.cs:1391`（逐字）；`:1392`（`why` 串） |
| **`PcLineOracle`（`verify-all` 第 [5] 步的仪器）** | ✅ **断言**：`bool structOk = (driveErr == null) && our.Count == exp.GetArrayLength();`，`why = "行数 期望=… 实得=…"` | `Program.cs:905`、`:914` |
| **`PcLineOracle` 的 TWIN 孪生对拍** | ⚠️ **只印不判**：印 `⚠️行数不等`，但只有 `TwinAcc(… width)` 进违规计数 | `Program.cs:1354`（印）、`:1361-1363`（`TwinAcc` 只吃 width） |
| **`FrameProbe`（`#22` 建）** | ⚠️ **只计数不判**：多出来的行计 `NOINFO行`，rc 只看**帧** | `Program.cs:531`（`FRAMEPROBE 仪器自证 … 我方行数 != 真值行数 的例=60`）、`:558`/`:561`（rc 只看帧） |
| **`PcLineOracle` 的逐行/逐字子循环** | ⚠️ **`if (li >= our.Count) break;`** ⇒ 多出来的行**永不进逐行比较**（只有例级红） | `Program.cs:1246`、`:1359` |

**⇒ 更正（这是我推翻的第一句）**：主控预登记 §4 P4.2 写"既有 tab 臂**按真值数组迭代** ⇒ **结构性看不见**"—— **对 `CoverageProbe` 与 `PcLineOracle` 的例级判据不成立**：两支臂都有独立的"行数相等"闸门（`:1391` / `:905`），而且**今天就在红**（见 3.2）。真正结构性失明的只有：**逐行子循环里的多出行**（没有逐行归属）＋ **TWIN/FrameProbe**（只印不判）。
**纪律 45 的正确表述**因此要收窄为：**"按真值数组迭代的*逐行*判据，看不见多出来的行；例级基数断言（若存在）能看见它们，但只给出一个例级红、不给逐行归属。"**

**红能力的既有实证（不是我推理出来的，是现场 artifact）**：
- `CoverageProbe` 侧：`$HOME/wfp-runs/w15-pre/gate-arm5.out`（**`20ee101787bb1e05`**，81,488 B，mtime `2026-09-15 16:34:32`）里 **68 行** `行数 期望=X 实得=Y`（门禁原文："探针报 UNREGISTERED 且登记表没有该 case_id：**行数 期望=3 实得=2**"）⇒ 那条闸门**能红**。
- `PcLineOracle` 侧：`/tmp/pc-line-start-step.out`（218,679 B，mtime **`2026-09-16 20:32`**，`#21` 树的 `pc-line-step.sh` 输出）里 **恰 60 行** `PCLINE CASE [B] … 结构=FAIL :: 行数 期望=X 实得=Y`。

### 3.2 60 例的**独立复算**（两支仪器、逐例对账）+ 机制归因

**复算 A（`FrameProbe` v2 的 `--prefix 40` 两趟日志**，它**为每个可判定例都印 CASE 行**⇒ 可全量枚举；`行数我方/真值` 与 `--prefix` 无关，`W22C` §3.4 已证）：`$HOME/w22c-laneW22C/run/v2lenBpre40.log`（宽松档）与 `v2strBpre40.log`（严格档）各 **288 条 `FRAMEPROBE CASE`** ⇒ 行数不符 = **60 例**（两趟**同一批 id**），多出 **101 行**。
**复算 B（`PcLineOracle` 腿 B 严格档**）：`/tmp/pc-line-start-step.out` 的 `结构=FAIL :: 行数 期望=` 行 = **60**。
**两法逐例对账（不看任何汇总行）**：交集 **60/60**、`only-in-A = 0`、`only-in-B = 0`，且每例 `(实得, 期望)` 与 `FrameProbe` 的 `(我方, 真值)` **逐位相同**（60/60）。

**形状（现算）**：**60/60 是 `@tab0`**；族分布 `B-indent 30 + B-indent-extra 18 + D-paraindent 8 + A-anchor 4`；真值行数 `{1: 54, 2: 6}`、我方 `{2: 26, 3: 21, 4: 13}`；`ours > truth` **60/60**、`ours < truth` **0**（"真机有而我方没有的行"= **0**，这一半干净）。
**机制归因（决定性，现算）**：把每个 `@tab0` 例与我方行数**同文本的 `@default` 孪生例的真值行数**比：**60/60 相等**（例：`A-anchor/lat-a-t-b@w96@LTR@i0@tab0` 我方 **3** 行，而其 `@default` 孪生**真值就是 3 行**；本例 `@tab0` 真值 = **1** 行）。
⇒ **多出来的行 = "我方用了 tab 网格 96 而不是 0"**，即 **`D-T4`**（`TextParagraphProperties.DefaultIncrementalTab` **到不了** `FormatParagraph`；`KNOWN-DEFECTS.md:695-698` 逐字），**不是**"分行算法多切了行"。
**⇒ 更正（我推翻的第二句）**：`#22` 登记为"**未登记红**"的这 60 例，**60/60 已在 `known-red.txt` 在册**（该表 136 条**全是裸 id**，`grep -c '::'` = **0** ⇒ **例级登记、任何失配词都匹配**；见 `Program.cs:1614-1622`），而且**它们本来就是 `D-T4` 那条"本臂表达不出来的输入"族的成员**（该表文件头逐字：「本表**只**登记"**本臂表达不出来的输入**"，不登记任何产品缺陷」）⇒ **新增未登记红 = 0**。
**为什么在门禁臂上红不了**：`CoverageProbe` **能表达**这条输入（`:1380` 逐字 `defaultIncrementalTab: arm0 ? 0.0 : double.NaN`）⇒ 该臂 **`结构败=0` / 436 例全过**。"同一断言在两支臂上取值不同"本身是**姿势差异**的读数，不是矛盾。

### 3.3 断言形式与放置建议

- **形式 = 例级 `ours == truth`（逐例 `case_id` 归属）**，**不是**"总分相等"。四条理由：① 登记表就是**按 `case_id`** 键的（中心表 `{arm, case_id}`；`known-red.txt` 裸 id）⇒ **例级红才登记得上**；② 门禁的未登记检测**按 `case_id`** 走（`tline-gate.sh:504-510`）；③ "总分相等"会被**互相抵消**（一例 +1、另一例 −1 ⇒ 总分相同而两例都错）⇒ **比例级弱**；④ 例级才可点名（本件 60 个 id 可逐条复算）。
- **行级归属（建议补，成本极低）**：多出来的行**逐行印出**（`id` + 该行的 `cpFirst`/帧/`Length`），并把它们计入 `NOINFO行`（`FrameProbe` 已经这么做了，`#22` 的 `101` 就是这么来的）⇒ **让"多出来的行"有 id，而不是只留一个例级红**。
- **补进哪几个臂**（点名）：
  1. **`CoverageProbe` 的 `--tab-lines-oracle`**：**已有**，**不动**（它今天绿，正是"能表达输入"的证据）。
  2. **`PcLineOracle` 主判据**：**已有**，**不动**。
  3. **`PcLineOracle` 的 TWIN**：**补**（`:1354` 的 `⚠️行数不等` 升成判据）—— **1 行**，且**不会**新增未登记红（孪生表今天的违规只吃 width；若把行数也计入，需先跑一趟看红在哪 —— **本件取不到该读数 ⇒ 预测按"孪生例也是 `@tab0/@i24` 族"估：可能落在在册例上，`NOINFO` 的部分见 §7**）。
  4. **`FrameProbe`**：**不要**在这里补成判据（它不在任何门里 ⇒ 加了也没人跑）；**要么先接线**（§5.1），**要么**保持"只计数"的诊断身份（它作为**独立第二仪器**的价值正在于"能看见多出来的行"，见 3.2）。

### 3.4 反极性与新增未登记红

| 臂 | 现状读数（"行数相等"这一条） | 分母 | 新增未登记红（若把断言补齐） |
|---|---|---|---|
| `CoverageProbe`（`tab-oracle-anchor`） | **红 0 例**（`结构败=0`，436 例全过） | 436 例（可判定 288） | **0** |
| `PcLineOracle`（腿 B 严格档） | **红 60 例**（全 `@tab0`，**全部在册**） | 288 例可判定 / 148 例不可比 | **0**（60/60 在册 + 裸 id 例级登记） |
| `FrameProbe`（不在门里） | 60 例计 `NOINFO行=101`，**不判** | 288 例 / 421 行 | 接线前**不适用**（无门可红） |

**⇒ 结论**：纪律 45 的**目的**（"多出来的东西不许结构性隐身"）**在门里的两臂上已经达成**；若目标是"让这 60 例有一个**判据**而不是一个例级红"，**今天就已经有**（`:905` 那条）。

### 3.5 排期建议

**不建议为本条新开工作项**（没有可修的东西：60 例的真身是 `D-T4`，且**该输入的真值本身缺失** —— `KNOWN-DEFECTS.md:698` 逐字"真机 oracle 的 `@tab0` 例把 `DefaultIncrementalTab` **写死成 0** ⇒ **"真机在这条输入下是什么行为"本身没有真值** ⇒ 判据需先补 Windows 重录"）。
⇒ **`#24` 只做 1 行**（TWIN 行数升判据，取一趟读数确认红落在在册例上）；**`D-T4` 本体**（PC 携带 `DefaultIncrementalTab`）**排在需要 Windows 重录的波**（`#25` 之后），**且必须与"60 例会消失"这件事一起记**。

---

## §4 件 3 · 117 条 `@default` 帧红的登记口径分析

### 4.1 两份登记表的分工（**行号级**）

| | **中心表** `build/MilBridge/known-red.json` | **臂自带表** `build/MilBridge/tests/PcLineOracle/known-red.txt` |
|---|---|---|
| sha16 / 大小 | **`2fdc02931c2af796`** / 31,498 B | **`89324f1f643167e5`** / 17,501 B（155 行，**136 条**） |
| **被谁读** | **只有** `build/MilBridge/tools/tline-gate.sh`（`REG_DEFAULT="$MB/known-red.json"` **:125**；`--registry` 覆盖 **:100**） | **只有** `PcLineOracle/Program.cs`（`--known-red` 解析 **:228**、装载 **:371**、`KnownRed.Load` **:1594-1622**） |
| 结构 | `schema tline-known-red/4`；顶层 `generation{}`/`entries[]`/`pending`/`changelog`/`_FIELDTABLE` | **纯文本**：`<id>` 或 `<id>::<判据片段>`，`#` 起注释 |
| **绑世代** | ✅ `generation.instr_{run_sh,program_cs,shim}`（`GEN_KEYS`，比对见 **:464-465**、**:446-452**）+ `instr_pc`（**信息性、不参与绑定**，见该文件 `_pc_note`） | ❌ 无世代概念 |
| 条目粒度 | `{arm, case_id, artifact, field, expected_shape, carrier, generation, caliber[, unlocated]}` | **裸 id ⇒ 例级**（`grep -c '::'` = **0**）⇒ **任何失配词都算"已登记"**（`:1614-1622`） |
| 红的后果 | `unregistered>0` ⇒ **`GATE_REASON=unregistered-failure` + rc=1**（**:504-514**、**:647-656**） | 登记过 ⇒ **只点名、不改 rc**；**未登记 ⇒ rc=1**（`:565-572`、`:616`） |
| **本件最该记住的一条** | **`TAB_LINES KNOWN-RED` 只出现在探针自带表里 ⇒ 门禁视为未登记**（**`:511-514`** 逐字） | ⚠️ **它不 gate `verify-all`**：`pc-line-step.sh:72-79` **只读 `PCLINE START` 那一行**，并逐字写"oracle 自身 rc … **不是本步的判据**；其未登记红属另一笔账" |
| 现状内容 | **4 条** = 3× `tline`（`T3-Collapse明细`、`T2d-Extent余差`、`T3b[unlocated:true]`）+ 1× `tab-oracle-zero`（`notab-control@w40@em24@RTL@tab0`） | **136 条**，**全 `@…@tab0`**（文件头逐字"**本表不含**任何 `@…@default` 臂的条目"） |

**一句话分工**：**中心表 = 五臂门禁的登记表**（绑世代、有 `unlocated`/`carrier`、红的**缺席**会让门禁 rc≠0）；**`known-red.txt` = `PcLineOracle` 的"本臂表达不出来的输入"表**（例级吸收、无世代、在 `verify-all` 里**不产生任何判决**）。

### 4.2 117 条的精确形状（现算，**修正 `#22` 的数法**）

`FrameProbe` 宽松档腿（`$HOME/w22c-laneW22C/run/v2lenB.json`，`#22` 的读数，**本件复算**）：

| 量 | 值 |
|---|---|
| 帧红**行** | **133**（分母：`script==latin` 421 行） |
| 其中 `@default` | **117 行**（在 **67 例**） |
| 其中 `@tab0` | **16 行**（在 **13 例**）⇒ **13/13 已在 `known-red.txt` 在册** |
| 红**例** | **80** = 67 `@default` + 13 `@tab0` |
| **不在中央/臂表任何登记范围的** | **117 行 / 67 例**（= 派单说的那批） |

⇒ **更正（第三句）**：`#22` 的"**117 条**"是**行**，对应 **67 例**（`@tab0` 那 16 行反而**是在册的**）。写预测/登记时**必须分行/例**，否则分母口径错一档（纪律 39 的同族错法）。

**⭐ 回答主控 §9.4 当天提的那个问题**（"帧列自己的**红例**数是多少、**是否把 `行数不等` 的 60 例算进红例**"）—— 现算，**两个列的口径必须分开写**：

| 列 | 红**行** | 红**例** | 与"60 例行数不等"的交集 |
|---|---|---|---|
| **帧列**（`FrameProbe` 宽松档腿，判据 = `我方帧 == corpus.startChar`） | **133** | **80** | **仅 6 例**（⇒ **不把 60 例算进红例**） |
| 帧列（严格档腿） | 3（**全是结构红**，帧红 0） | **3** | 3/3（那 3 条正是 `@tab0` 的结构红） |
| **`Start` 列**（`#21`，`PcLineOracle`，修前 pc） | 138 | **88** | —— （**另一列、另一仪器**） |

⇒ **主控的自我更正（§9.4）被本件的数据证实**：`88` 明确属于 **`Start` 那一列**（`W21A-report.md` 的 138 行 / 88 例），**帧列是 133 行 / 80 例**；且"行数不等"的 60 例**几乎不是**帧红例（交集 6）⇒ **三列（`Start` / 帧 / 行数）三套红例口径**，混用一次就错一次（纪律 39 的加强版）。

### 4.3 `W23B` 修后：预期与"若不全绿"的裁决口径

**预期（预登记 §2.3 原文的预测，不是本件读数）**：`FrameProbe` 宽松档 **133 → 0**、`--fresh-source` **133 → 0**、`--prefix 40` **421 → 0**；严格档**仍 421/421 正确**且那 **3 条结构红不变**（§6.2/§6.3 的停条件）。
⇒ **若兑现**：**117 行 / 67 例与 16 行 / 13 例一起变绿** ⇒ **不需要任何新登记**；而 `known-red.txt` 里的 **13 条 `@tab0`** 会因为"该例的结构红还在（`行数 期望=…`）"**继续红**⇒ **不会**触发"在册红消失"（该表的 gone 语义在 `PcLineOracle` 里只是点名，不影响 `verify-all`）。
**若不全绿**（残留），按下面口径**分两半**裁决：

| 残留种类 | 放哪张表 | `generation` | `carrier` | `unlocated` |
|---|---|---|---|---|
| **`@default` 族残留帧红**（真产品红） | **中心表**（前提：帧列**已接进**某个门里的臂 —— **今天没有**，见 4.5） | **`#23`**（与重钉同步；`caliber` 三项照抄 `generation`） | = **帧读取器本身**（例如"`GetTextBounds` 的段落系口径那一层"） | **`true`**（机制未归因时**必须** `true`；**不许**用 `false` 冒充"已理解"） |
| **`@tab0` 族残留** | **`known-red.txt`**（臂姿势限制，与既有 136 条同族） | 无此字段 | 无此字段 | 无此字段（**该表没有这个区分** ⇒ 见 4.4 的建议） |
| **那 3 条严格档结构红** | 已在 `known-red.txt`/`@tab0` 族 | — | — | — |

**⚠️ 前置条件必须写死**：残余帧红**今天无法登记**，因为量它的是 `FrameProbe`，而它**不在任何门/步/脚本里**（`grep -c FrameProbe verify-all.sh build/MilBridge/tools/tline-gate.sh build/MilBridge/tools/pc-line-step.sh build/MilBridge/run.sh build/MilBridge/arm-logs/README.md` ⇒ **五项全 0**）。⇒ **顺序必须是"先接线、后登记"**，否则登记表里会出现一条**没有任何判据读它**的条目（`known-red.json` 的 `entries` 是"**该臂的 case 必须有 FAILCASE 行**"才判红，**没有臂就没有读数** ⇒ 那条会落进 `NOINFO`/`gone` 分支）。

### 4.4 "登记 ≠ 已容忍"在本项目里**具体表现为什么字段**

| 机制 | 位置 | 具体形态 |
|---|---|---|
| **`unlocated: true`** | 中心表条目字段；门禁 **`:554`** 用它选 marker | 打 **`KNOWN_RED_UNLOCATED`**（**与 `KNOWN_RED` 不同的 marker**），并在汇总行里单独成一位 **`unlocated=N`**（**:647-652**）；文件头逐字"**登记 ≠ 已理解、更 ≠ 已容忍**"（`:70-71`） |
| **`carrier`** | 中心表条目字段；**:595-597**、**:640** 逐条印 | "**这条红当前由谁承载**"—— 强制写清"红挂在哪个判据/仪器的哪一项上"，`<未登记 carrier>` 会**照印** |
| **`drift` / `gone`** | **:543-562**、**:610-620** | `KNOWN_RED_DRIFT`（红还在、**读数漂了** ⇒ 登记表要更新）与 `KNOWN_RED_GONE`（**在册红消失** ⇒ `registry-stale(gone)` ⇒ **FAIL**）⇒ 登记是**被监控的**，不是**被赦免的** |
| **探针自带表洗不绿** | **:511-514** | `TAB_LINES KNOWN-RED`（只在探针自带表里）⇒ **视为未登记失败** |
| ⚠️ **`known-red.txt` 没有上面任何一项** | `grep -c unlocated build/MilBridge/tests/PcLineOracle/Program.cs` = **0** | ⇒ 在**该表**里，"未定位的在册红"与"已定位的在册红"**长得一模一样** ⇒ **建议**：① **不许**把"未定位"的红放进该表；② 若必须放，至少在行尾用 `#` 注释写明"机制未归因"（人读，不参与判定 —— `Program.cs:1607-1608` 会截掉 `#` 之后的内容） |

### 4.5 ⚠️ 结构性发现（本件最值钱的一条）

**那 117 行不是"漏登记"，是"没有登记的地方可放"**：`FrameProbe` 是 `#22` 新建的**车道级仪器**，它**不在五臂、不在 `verify-all`、不在 `run.sh`**（4.3 的 grep 全 0）⇒ 与 `D-G2`（"产品级文本路径在冻树回路里没有自动红/绿"）**同一族**。⇒ **117 条的真正处置不是裁决登记口径，而是接线**（§5.1）。**在接线之前**，任何"把 117 条登记进某张表"的动作都会产出一条**没有人读**的条目（比不登记更危险：读者会以为有人看着它）。

---

## §5 件 4 · `#22` 三条欠账的排期建议

### 5.1 逐件处置（**不重复计工作量**）

| # | 欠账 | 处置 | 会随 `W23B` 自动消解吗 | 排在 `#24` 还是更后 | 理由 |
|---|---|---|---|---|---|
| **①** | **117 行 / 67 例未登记帧红** | **不登记** ⇒ 改为**接线**：把帧列（+消费者可见面）接进一个**有判决、有登记口径**的步（照 `pc-line-step.sh` 的形态：`PCLINE_STEP=NOINFO/FAIL/PASS` 三态 + `判定行>0` 防空绿 + `NOINFO≠0 ⇒ FAIL`） | ✅ **预期是（宽松档 133→0）** | **`#24`（首选，因为它是 `D-G2` 的结构缺口）** —— 但**必须排在 `W23B` 修完之后**：先有"修后绿"的读数，接线才有正极性的基线（反极性 = 换回修前 pc/shim，`$HOME/w21a-pre/` 有修前 pc 的留档形态可参考） | 不登记的理由见 4.3/4.5：**没有臂就没有读数**，登记条目会落进 `NOINFO/gone` |
| **②** | **60 例（`@tab0`）我方分行多于真机（多 101 行）** | **判定 = 不是产品缺陷**：60/60 在册、60/60 == 孪生 `@default` 真值行数、机制 = `D-T4` 的**臂姿势**；⇒ **只做 1 行**（TWIN 的行数从"只印不判"升成判据） | ❌ **不会**（`D-T6-b` 的逐成员影响面里**不含分行**：`KNOWN-DEFECTS.md:774` 列的是 `GetTextBounds`/`GetIndexedGlyphRuns`/`Collapse`；且 Option 1 只改 3 个绝对消费者 + 折叠行透传） | **1 行的部分排 `#24`**；`D-T4` **本体**（PC 携带 `DefaultIncrementalTab`）**排到需要 Windows 重录的波（`#25`+）** | `D-T4` 的**真值缺口**（`KNOWN-DEFECTS.md:698`：`@tab0` 例把该输入写死 0 ⇒ "真机在这条输入下是什么行为本身没有真值"）⇒ **现在修了也无法判红/绿** |
| **③** | **78 行静默错**（133 帧错里 55 行读到空 + **78 行读到"别人"的边界**） | **与 ① 是同一批行、同一件工作**（那是**同一缺陷的消费者可见面**）⇒ **吸收进 ①**，判据必须**两种后果都覆盖**（`FrameProbe` 已有两列） | ✅ **预期是**（帧修好 ⇒ 读空/静默错都应归零） | **`#24` 随 ①** | **不许**单独再派一件（会与 ① 重复计工作量） |

### 5.2 排期表（一句话可执行）

| 波 | 做 | 不做 |
|---|---|---|
| **`#23`（本波）** | `W23B` 修 `D-T6-b`（Option 1）+ 取修后读数 | **不**为本件的三件欠账做任何落地（本件是只读设计） |
| **`#24`** | ① **接帧步**（含 78 行静默错的消费者可见面）+ ① 的**反极性**（换回修前 pc）＋ ② 的 **1 行**（TWIN 行数）＋（可选）**`hasOverflowed` 列**（§2，预测红 0，需要 `=>false` 的反极性红证 22 行） | **不**修 `D-T4`（真值缺口）、**不**改 `HasOverflowed` 语义（那会动折叠族）、**不**顺手改 `shim:3453` 的注释（换世代，除非搭 `W23B` 的车） |
| **`#25`+** | `D-T4`（PC 携带 `DefaultIncrementalTab`）+ Windows 重录（`@tab0` 输入的真值） | —— |

---

## §6 我推翻 / 更正了哪几句话（**如实写**）

1. **推翻了预登记 §4 P4.2 的前提**"既有 tab 臂**按真值数组迭代** ⇒ **结构性看不见**多出来的行" —— **对两支臂的例级判据不成立**：`CoverageProbe/Program.cs:1391` 与 `PcLineOracle/Program.cs:905` **都在断言行数相等**，而且**今天就在红**（`PcLineOracle` 60 例；另有 `$HOME/wfp-runs/w15-pre/gate-arm5.out` 的历史红证 68 行）。失明的只有**逐行子循环**（`:1246`/`:1359` 的 `break`）与 **TWIN/`FrameProbe`**（只印不判）。
2. **更正 `#22` 的"60 例多分行 = 未登记红"** —— **60/60 已在 `known-red.txt` 在册**（裸 id ⇒ 例级），且 **60/60 的我方行数 == 该例 `@default` 孪生的**真值**行数** ⇒ 机制是 **`D-T4`（`DefaultIncrementalTab` 到不了工厂）这条臂姿势限制**，**不是**产品多分行、**不是**新未登记红。
3. **更正 `#22` 的"117 条"数法** —— **117 行 / 67 例**（`@default`），另外 **16 行 / 13 例**是 `@tab0`（**在册**）；混写会把分母口径错一档（纪律 39）。
4. **更正 `hasOverflowed` 的"22 行"语境** —— 这 22 行**全部在 `script==latin` 的可判定集内**（8 例），**不是**"躺在不可比/NOINFO 子集里"；它们**今天就能被门禁臂看到**（`tab-anchor.log` 里这 8 例 `结构=PASS 位置=PASS`、`START 红=0`，行数 2/2/4/4/3/3/2/2 = **22**）。
5. **更正 `TAB_LINES 最大差=0.0000` 的语义** —— 读码 `Program.cs:1402`：`worst` **只在 `dW > 0.05` 分支里更新** ⇒ 那是"**最大违规量**"，无违规时恒印 0.0000 ⇒ **它不能当"宽度逐位相等"的证据**（`W22B` §4 的表述会被这样读）。本件的 `hasOverflowed` 预测因此带**风险带**（58 latin 零余量行）。
6. **`shim:3453` 的"真机实测：3222/3222 行全为 false"是未背书的断言** —— 唯一含 "3222" 的语料 `layout-b34/windows-results.json` 里 **`hasOverflowed` 字段出现 0 次**；而仓内三份语料合计有 **66 行** `true`（`tab` 36、`tab-anchor` 22、`modifier-scope` 8）⇒ 与 `D-T6-c` 的"恒为 0"同族（纪律 43 的第三落点）。
7. **更正派单/预登记的"`hasOverflowed` 与 `D-O1` 的关系"里一处隐含读法** —— `D-O1` **已经**是三分支真实现（`shim:3466-3476`），所以本列**不是**"给一个恒假成员加判据"（那会零判别力），而是**给一个真实现加锁**；因此**判据必须自带反极性红证**（`=> false` ⇒ 预测 **22 行 / 8 例**），否则它今天就是一片绿、无法自证活着（纪律 3/41）。
8. **我自己的一处收紧**：`hasOverflowed` 的第三条分支**在本语料上行使不了**（删掉 branch ② ⇒ 预测红 **0 行**）⇒ 这列的"判别力映射"是**有洞的**，必须在报告/登记里作为**覆盖边界**写出，不许读成"三分支都被验证了"（§7）。
9. **确认了主控本波 §9.4 的自我更正**（不是我推翻它，是**用现算给它收口**）：帧列 = **133 行 / 80 例**、`Start` 列 = **138 行 / 88 例**、"行数不等" = **60 例**（与帧红例交集**仅 6**）⇒ **三列三套红例口径**，任何"把 88 套到帧列"的写法都是第四次同类错（纪律 39 加强版）。**本件 §0/§4.2 已按"行 + 例"双写**（`117 行 / 67 例`），后续任何引用请连写，否则就是第四次同类错。
10. **我自己写错、当场更正的一处（纪律 4/42 的现场）**：我起初把派单里的 `0d048e6e8808c4e7` 当"`ACCEPTANCE-BASELINE.md` **表头行**的 sha16" —— **错**：表头第 1 行的现算 sha16 = **`c49d8fa93bafb76a`**；`0d048e6e8808c4e7` 是 **`#21` 重冻那一刻整份文件**的 sha16（`W22A-report.md:5` 逐字可证），而**现行文件**因 `#22` 波尾追加了一段复核注记（该文件 `:7` 自述"零位移 ⇒ 本次不重冻"）而变为 **`4f4bfe732c097a77`**（mtime `20:32:54`）⇒ **文件 sha 变、冻结内容未变**。**给主控的一条建议**（不是缺陷）：凡"权威 = 某文件 sha16"的口径，**必须写明是哪一版文件的 sha**（否则下一位接手人会像我一样把它读成"表头行"或误判为未登记位移）。

---

## §7 NOINFO / 未测清单（**一条都不许读成绿**）

| # | 项 | 状态 | 卡在哪 |
|---|---|---|---|
| 1 | **我方侧 `HasOverflowed` 的任何真实读数** | **NOINFO（本件零 `dotnet`）** | 无任何仪器打印它（`grep -c hasOverflowed CoverageProbe/Program.cs` = **0**；`FrameProbe` json 只存 `frame/lineStart/truth/cpFirst/length/hostReadOk/red`）⇒ §2.4/§2.7 的"红=0"是**条件预测**，条件 = 三条已测量列（§2.4） |
| 2 | **那 58 个 latin 零余量行的宽度是否"精确相等"** | **NOINFO** | 既有宽度列只保证 ≤ 0.05，且 `最大差` 是"最大违规量" ⇒ **无法从现有读数判定**；必须靠接线首趟实测 |
| 3 | **branch ②（`Indent + PI ≥ W`）的单独判别力** | **NOINFO（本语料不可行使）** | 删掉 branch ② ⇒ 预测红 **0**（现算）；要行使它需要"`Indent+PI ≥ W` 且 `PI+width ≤ W`"的用例，**语料里没有**（本语料 `Indent ≤ 24`、`W ≥ 40`） |
| 4 | **`TextAlignment ∈ {Right, Center, Justify}`** | **NOINFO** | 语料 436/436 全 `Left`（与既有两列同一条边界） |
| 5 | **RTL 半边** | **NOINFO** | 本列 22 个 true 行**全是 latin/LTR**；`C-rtl-indent` 的 33 个非零行被覆盖闸跳过（缺字形）⇒ **不许**写成"覆盖了 RTL" |
| 6 | **产品路径（`PcLineOracle`）上的 `HasOverflowed`** | **NOINFO** | 本件只给"`CoverageProbe --tab-lines-oracle`（源直调层）"的草案；`PcLineOracle` 那条链**没有任何 `hasOverflowed` 读数**（也不该由本件取） |
| 7 | **`W23B` 修后的一切读数**（含 117 是否归零） | **NOINFO** | 本件全程在 `#21` 冻树上（`shim 76089e1de586ac91` / `pc e7cabff9417ed380`，`00:02` 复取仍同） |
| 8 | **`FrameProbe` 修后重取**（含 60 例是否变化） | **NOINFO** | 同上；本件的 60 例枚举取自 `#22` 的 **v2 日志**（`v2lenBpre40`/`v2strBpre40`），与 `PcLineOracle` 60 号**交叉一致**（60/60） |
| 9 | **TWIN 行数升判据后会红在哪** | **NOINFO** | 需要跑一趟 `PcLineOracle`（本件零 `dotnet`）⇒ §3.3 只给"1 行改动 + 先取读数"的建议 |
| 10 | **`modifier-scope`（8 行 true）/ U1 `tab`（36 例 true）这两份语料的可达性** | **NOINFO（本件只登记）** | U1 `tab` 有现成入口（`--tab-oracle`，`CoverageProbe:703/:726`）但**不在任何门里**；`modifier-scope` 是否被某支臂消费**未盘点** |

---

## §8 读数表 + "未动"自证

| 项 | 值 |
|---|---|
| **lane** | **W23D** |
| 起止（本地） | **2026-09-16 23:55:32 → 2026-09-17 00:0x +0800** |
| `kernel` | `6.8.0-138-generic` |
| `nproc` | **3** |
| `loadavg` | 开工 `0.70 0.34 0.14`｜收尾 `3.57 2.69 1.30`（区间 0.70–3.57） |
| `MemAvailable` | 开工 **3,109,000 kB**｜收尾 **3,634,160 kB**（`MemTotal` 8,113,356 kB、`SwapFree` 1,089,020 kB）—— **本件零 `dotnet`** ⇒ 未对内存施加压力（未做连续采样，**如实记**：只有开工/收尾两点） |
| `dotnet`/MSBuild 进程 | 本车道 **0 个**；现场另有 **PID 319070 / 319298**（**别人车道**，未触碰、未 `pkill`） |
| `DISPLAY` | **本件全程未使用任何 `DISPLAY`**（零 `dotnet`、纯读档 + 现算）⇒ 与预登记 §9.1 的裁决（`:97` 曾 DOWN；`FrameProbe`/`PcLineOracle` 一类**托管文本排版对 JSON** 的臂**没有渲染面 ⇒ X 不是仪器输入**）**无冲突**；`:97` 的状态**不影响本件的任何数** |
| `shim`（开工/收尾） | `76089e1de586ac91` / `76089e1de586ac91`（283,557 B） |
| `pc`（开工/收尾） | `e7cabff9417ed380` / `e7cabff9417ed380`（4,196,864 B） |
| 语料（raw / oracle） | `88559d670f1bb955` / `0cebc0afd5142fbf` |
| **本件写过的文件** | **只有本报告**（`build/MilBridge/W23D-report.md`，新建）—— 其余**只读**（`read`/`grep`/`sha256sum`/`stat`/`python3` 现算） |
| 引用到的既有件 sha16 | `known-red.json` `2fdc02931c2af796`｜`PcLineOracle/known-red.txt` `89324f1f643167e5`｜`tline-gate.sh` `b37a5c9f55ae71a4`｜`pc-line-step.sh` `fa62842d8e211b07`｜`verify-all.sh` `279b958dda238447`｜`CoverageProbe/Program.cs` `421fe394bea93fe2`｜`PcLineOracle/Program.cs` `a787a9db23c3302c`｜`FrameProbe/Program.cs` `c6a66724ad56760a`｜`tab-anchor.log` `1a5bc7181d0155c3`｜`W22B-report.md` `c98c71f106fec8d7`｜`W22C-report.md` `93d66fa348ddbb3a`｜`KNOWN-DEFECTS.md` `0454fe932d84ac96`｜`CURRENT-STATE.md` `86f6bb753d74bc06`｜`WAVE23-PREREGISTRATION.md` `72215b0f5ed741b3` |
| 本件引用的**他人** artifact（读数出处，纪律 32） | `$HOME/w22c-laneW22C/run/v2lenB.{log,json}`（W22C，宽松档腿）｜`v2lenBpre40.log`/`v2strBpre40.log`（W22C，`--prefix 40`，**288 条 CASE 行 ⇒ 可全量枚举**）｜`/tmp/pc-line-start-step.out`（`pc-line-step.sh` 的现场输出，218,679 B，mtime `2026-09-16 20:32`）｜`$HOME/wfp-runs/w15-pre/gate-arm5.out`（`20ee101787bb1e05`） |

**"未动"自证**：本件对**任何既有文件**都没有执行过写操作（无 `cp`/`write`/`edit`/`> file` 于仓内；现算全走 `python3` 的**只读**读档，输出只打印到 stdout 与 `$HOME/w23d-*.json` 两个**临时**件）。派单禁改清单（`known-red.json`、`tline-gate.sh`、`verify-all.sh`、`build/shims/**`、`build/PresentationCore.Linux/**`、`PcLineOracle/**`、`CoverageProbe/**`、`arm-logs/`）**逐一未触碰**，§8 表里的 sha16 是**收尾现场取**。

---

## §9 现算脚本（可复算，全部零内存压力）

**S1 · `hasOverflowed` 的形状与规律**（本报告 §2.1/§2.3 的数）：
```bash
cd "$R" && python3 - <<'EOF'
import json, collections
d=json.load(open("tests/parity/windows/tab-anchor/out/tab-anchor-raw.json"))
rows=[(c,L) for c in d["cases"] for L in c["lines"]]
print("rows",len(rows),"True",sum(1 for c,L in rows if L["hasOverflowed"]),
      "latinTrue",sum(1 for c,L in rows if L["hasOverflowed"] and c["script"]=="latin"))
print(collections.Counter((c["group"],c["indentArm"],c["paragraphWidthDip"]) for c,L in rows if L["hasOverflowed"]))
def test(n,f):
    hit=sum(1 for c,L in rows if f(c,L) and L["hasOverflowed"])
    fp =sum(1 for c,L in rows if f(c,L) and not L["hasOverflowed"])
    fn =sum(1 for c,L in rows if not f(c,L) and L["hasOverflowed"])
    print("%-46s 判true=%-4d 命中=%-3d 假阳=%-3d 漏=%-3d"%(n,hit+fp,hit,fp,fn))
test("ps+width > W+1e-6", lambda c,L: L["paragraphStartOffsetDip"]+L["width"]>c["paragraphWidthDip"]+1e-6)
test("perChar.x+width > W+1e-6", lambda c,L: max((p["x"]+p["width"]) for p in L["perChar"])>c["paragraphWidthDip"]+1e-6)
test("ps >= W", lambda c,L: L["paragraphStartOffsetDip"]>=c["paragraphWidthDip"])
m=[c["paragraphWidthDip"]-(L["paragraphStartOffsetDip"]+L["width"]) for c,L in rows if not L["hasOverflowed"]]
print("零余量 False 行", sum(1 for x in m if abs(x)<1e-9))
EOF
```
**S2 · 反极性四极化预测（本报告 §2.4 的表）**：把上面的 `test()` 换成 §2.4 的四个突变式即可（`=>false` / `=>true` / `_startPenX+_width>W` / `>=`）。
**S3 · 60 例的独立复算（两支仪器）**：
```bash
# 法 A：FrameProbe v2 的 --prefix 40 两趟（288 条 CASE 行 ⇒ 全量）
python3 - <<'EOF'
import re
for p in ["v2lenBpre40.log","v2strBpre40.log"]:
    cs=[(m.group(1),int(m.group(3)),int(m.group(4))) for m in
        (re.match(r'FRAMEPROBE CASE (\S+) 首调cpFirst=(-?\d+) .*行数我方=(\d+) 真值=(\d+)',l) for l in open("/home/links-dev/w22c-laneW22C/run/"+p,encoding="utf-8",errors="replace")) if m]
    mm=[c for c in cs if c[1]!=c[2]]
    print(p,"CASE",len(cs),"mismatch",len(mm),"extra",sum(c[1]-c[2] for c in mm))
EOF
# 法 B：PcLineOracle 腿 B（只看 CASE 行，不看汇总）
grep -a '^PCLINE CASE \[B\]' /tmp/pc-line-start-step.out | grep -c '行数 期望='
# 对账：两法的 id 集合与 (实得,期望) 是否逐例相同（见报告 §3.2）
```
**S4 · 登记表分工的现场复核**：`sha256sum build/MilBridge/{known-red.json,tools/tline-gate.sh,tools/pc-line-step.sh}`；`grep -c '::' build/MilBridge/tests/PcLineOracle/known-red.txt`（=0 ⇒ 裸 id）；`grep -c unlocated build/MilBridge/tests/PcLineOracle/Program.cs`（=0）。
**S5 · `FrameProbe` 的接线状态**：`grep -c FrameProbe verify-all.sh build/MilBridge/tools/tline-gate.sh build/MilBridge/tools/pc-line-step.sh build/MilBridge/run.sh build/MilBridge/arm-logs/README.md`（**五项全 0**）。

---

### 附：本报告**没有**做的事（避免读者误会）

- **没有**修改任何判据/登记表/脚本/源码（含 `CoverageProbe`、`PcLineOracle`、`FrameProbe`、`known-red.*`、`shim`、`pc`）；
- **没有**跑 `dotnet`、没有跑 `verify-all`、没有跑任何臂（⇒ 一切"我方侧"数字都是**预测**，条件写在 §2.4）；
- **没有**替主控做任何登记裁决（本件只给口径与代价，**登记与否是主控的决定**）。

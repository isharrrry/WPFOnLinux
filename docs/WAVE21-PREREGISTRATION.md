# 波 `#21` 预登记（**落地之前先登记**）

> 生成：主控，基于**当前冻结基线 `#19`**（权威 = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 表头 `f5d8a6f1cdf49635`）。
> 纪律：**落地前先预登记**（判据、预测位移、反极性红证、停条件、落地顺序）｜红判据**只许加强，不许放松**｜**预测表之外的位移 ⇒ 停**｜缺数据 ⇒ `NOINFO`，**不许猜**。

---

## §0 本波四件（按价值排序）

| 件 | 题目 | 定性 | 代价 |
|---|---|---|---|
| **P1** | `D-T6-c`：真机 `TextLine.Start` 的法律 —— 定性 + 落地 | **产品缺陷（本波确证）** | **要付世代成本**（动 `build/shims/**`） |
| P2 | `D-R8` 残项：其余暴露工程用共享 `.props` 收口 | 工程卫生 | 不付（无 shim 变动） |
| P3 | `D-T6-b`：宽松档交回的行丢段落帧 | 只读归因 | 不付 |
| P4 | `D-R3` 残项枚举 + `D-T5`/`D-T4` 就绪度 | 只读盘点 | 不付 |

**资源约束（本波硬约束）**：`nproc = 3`。⇒ **只有 P1 车道可以跑 `dotnet build`/`dotnet run`**；P2 车道**只许** `-getItem:Compile`（求值，不构建）；P3/P4 车道**完全只读**（纯静态阅读 + `python3` 分析），**不许**跑 dotnet。理由：位移读数虽确定，但**共享 `obj/`/`bin/` 的构建并发会互相污染**，而 `#19` 的口径是"**每件各自取一次读数**"。

---

## §1 P1 —— `D-T6-c`：真机 `TextLine.Start` 的法律

### 1.1 三条**互相独立**的腿

**腿 ①（真机公式，照录 `upstream/wpf` 原文）** —— `MS/internal/TextFormatting/TextMetrics.cs:355-358`：

```csharp
public double Start
{
    get { return _formatter.IdealToReal(_paragraphToText - _textStart, _pixelsPerDip); }
}
```

而 `_paragraphToText` 的 `default:`（`= Left`）分支（`:255-263`，**注释原文**）：

```
// alignment rule:
//   "Paragraph start to line start is paragraph indent"
//        PTL = PI
//        PTT - LTT = PI
// (thus) PTT = PI + LTT
_paragraphToText = pap.ParagraphIndent + _textStart;
```

⇒ 代入即得 **`Start ≡ IdealToReal(ParagraphIndent)`**：`_textStart`（"LS origin → text start"，首行缩进/前导空白时**非零**）**精确相消** ⇒ `Start` 与 `Indent`、与 `_textStart` 是否非零**都无关**，**只等于 `ParagraphIndent`**。
（`TextMetrics.cs:65-68`/`:91-92` 的说明段亦把 `Start` 定义为"distance from the paragraph starting point to the actual beginning of the line"。）

**腿 ②（真机逐行实测）** —— `tests/parity/windows/tab-anchor/out/tab-anchor-raw.json`（真机 `os = Microsoft Windows NT 10.0.22631.0`、`clr 10.0.7`、`generatedUtc 2026-09-14T11:32:21Z`）里的 `lineStartOffsetsDip` **就是**真机臂逐行的 `line.Start`：

```csharp
// tests/parity/windows/tab-anchor/src/Program.cs:445
lineIndents.Add(R(line.Start));
// 同文件 :555  paragraphStartOffsetDip = R(line.Start)   ← 同一读数第二处落盘
```

主控在 436 例 / **615 行**上**重算**（`R(v) = Math.Round(v, 6, MidpointRounding.AwayFromZero)`，`tab-anchor/src/Program.cs:583`）：

| 假设 | 命中 |
|---|---|
| **`Start == ParagraphIndent`** | **615 / 615（错 0）** |
| `Start == Indent` | 337 / 615 |

且**互斥互覆盖**：`PI=0 而 Start≠0` 的行 = **0**；`PI≠0 而 Start==0` 的行 = **0**。实测取值域 = `{0: 444, 24: 131, 48: 40}`，与语料 `ParagraphIndent ∈ {0,24,48}`（例数 `324/84/28`）**一一对应**。⇒ **驱动量是 `ParagraphIndent`，不是 `Indent`**。

**两条加强（主控用另一条遍历重算，可复现）**：
- `PI → Start` 是**双射**：`{0: [0], 24: [24], 48: [48]}` —— 每个 `PI` 只对应**唯一**一个 `Start` 值，**没有第三种可能**。
- 语料**自洽**：逐行字段 `paragraphStartOffsetDip`（同一 `line.Start` 的**第二处**落盘，`Program.cs:555`）与 `lineStartOffsetsDip[k]` 逐行比较 ⇒ **615/615 一致、0 处矛盾**。

**腿 ③（上游忠实移植版不硬编码）** —— `build/PresentationCore.Linux/SimpleTextLine.Linux.cs:1158-1161`：`public override double Start { get { return _offset; } }` —— **不是**常量 0（该版 `_offset` 只按 `Align` 赋值，是**另一条**路径的既有缺口，见 §1.8）。

### 1.2 我们的现状

```csharp
// build/shims/PresentationCore.HbTextLine.cs:3390
public override double Start => 0;          // 真机实测恒为 0（3222/3222），不是段落内偏移
```

⇒ 反极性：**`PI≠0` 的行我们给 0，真机给 24/48**。**171 行**（全 `PI≠0` 用例）逐行错。

### 1.3 "3222/3222 恒为 0"那句注释的**伪证来源已定位**（不是谁编的数，是**语料性质被当成了规律**）

该数字出自 `layout-b34` 语料（614 例 / 3222 行）。主控实检该语料四个文件：

```
tests/parity/windows/layout-b34/{cases,cases-cd1,cases-cd2,windows-results}.json
   'ParagraphIndent' 出现次数 = 0   'Indent' 出现次数 = 0
```

⇒ 在**那份语料**上，真法律的**唯一非零驱动量 `ParagraphIndent` 压根没被采样**（取值恒 0）⇒ 真机在那 3222 行上**必然**全给 0。**"0 是语料性质，不是实现性质"** —— 与纪律 34 同族（把**语料分布**当成**规律**）。同时这也**推翻** `PcLineOracle/Program.cs:462` 那条在册口径"`88 条 PI≠0 的逐行精算值**不可从语料推出**"：语料**含** `lineStartOffsetsDip`（615 个值），**可从语料推出**，只是**从未被比较过**。

### 1.4 判据（本波新增，落进 `build/MilBridge/tests/PcLineOracle/Program.cs`）

- **比较对象**：每例逐行 `R(我方 line.Start)` vs 语料 `lineStartOffsetsDip[k]`（同 `R` 口径）。
- **口径边界（不许越界）**：语料头 `paragraphProperties.fixed` **钉死** `TextAlignment=Left, TextWrapping=Wrap, LineHeight=0(natural), Tabs=null, …`（`TextAlignment` **不是逐例变量**）⇒ **只对 `TextAlignment=Left` 断言** `Start == ParagraphIndent`。
  **流方向是逐例变量、且两个方向都被覆盖**：`LeftToRight` 318 例 / `RightToLeft` 118 例；`171` 行非零值里 **LTR 138 / RTL 33**，**法律在两个方向上都是 0 反例** ⇒ 判据覆盖 **LTR + RTL**（不是只有 LTR）。
- **`Right`/`Center`：`NOINFO`，不许发明**。真机公公式为 `paragraphWidth − _textWidthAtTrailing`（Right）/ `(paragraphWidth + _textStart − _textWidthAtTrailing)/2`（Center），**本语料零覆盖**；要测需**另录真机语料**，登记为后续项，**本波不动**。
- 判据必须**逐例可归因**（打印 `id` + 行号 + 我方值 + 真值），并进**既有红/绿/NOINFO 分桶**，不得改变既有分桶语义（只**新增**一列比较）。

### 1.5 修法（**最小面**）

```csharp
public override double Start => _paragraphIndentDip;   // = TextParagraphProperties.ParagraphIndent（DIP）
```

配套：私有 ctor（`shim:2702-2708`）末尾新增 `double paragraphIndentDip = 0` 形参 + `private readonly double _paragraphIndentDip;` 字段 + **全部构造点透传**：至少 `shim:2884`（行构造，现传 `indentDip + paragraphIndentDip` 作 `boxOriginX`）与**折叠路径 `BuildCollapsedLine`**（`shim:2680` 注释：折后行"直接给覆盖值"⇒ 必须一并给）。
`shim:2693` 的单 run 便捷构造走默认 0 ⇒ `Start = 0`（与"无段落缩进"一致，不改）。

⚠️ **禁止**用 `_startPenX` / `_boxOriginX` 反推 PI：`_boxOriginX = indentDip + paragraphIndentDip`（`shim:2884`）是**合量**，**推不出 PI** —— `shim:2635` 已经写明这一点。
⚠️ 顺手把 `:3390` 那句**已被推翻的注释**改成真法律（同纪律 4 一族：引注前现场重读）。**本波不碰** `build/MilBridge/staging/**`（不在 `inputs_fp` 内，是历史副本）与 `build/MilBridge/tests/CoverageProbe/refs/*.cs`（钉住的快照）。

### 1.6 预测：红 → 绿

| 读数 | 修前 | 修后（预测） |
|---|---|---|
| 判据（615 行） | **红 171 / 绿 444** | **红 0 / 绿 615** |
| 取值 | `PI≠0` 行我方 `0.000000`，真值 `24`（131 行）/ `48`（40 行） | 逐行 `Δ = 0.000000` |
| 判别例 | `B-indent-extra/lead-tab-a@w40@LTR@i24p24@{default,tab0}` 行 0/1：`0.000000` vs 真机 `24.000000` | 两行皆 `Δ=0.000000` |
| `PI=0` 的 444 行 | 绿（真值 0） | **逐位不动**（`Start` 仍 0） |
| 其余既有判据列 | —— | **逐位不动**（本波只**新增**一列比较，不改任何既有列的口径） |

**档位覆盖预测（主控补，取读数之前写下）**：PI 在**两个调用点**都已被送进回退（生成物 `TextFormatterImp.Linux.cs:586` 与 `:611`，两处都是 `paragraphIndentDip: paragraphProperties.ParagraphIndent`）⇒ **严格档与宽松档都应变绿**。
⇒ **若只有一档变绿、另一档仍红 ⇒ 不是"部分成功"，是发现**（该档的 PI 没有接通）⇒ **停并归因**，不许把"平均下来大部分绿了"当成功。
（旁证：上游 `SimpleTextLine.Linux.cs:203-216` 的闸门 `settings.TextIndent != 0 || pap.ParagraphIndent != 0 ⇒ return null` ⇒ `PI≠0` 的例**不会**被简单快路径接走 ⇒ PI≠0 的行一定会走到要修的那条路径上。）

---

## §2 P2 —— `D-R8` 残项

`#20` 只修了 `build/MilBridge/tests/{TextLineProto,HbTextLineParity}/*.csproj`（各加一行）。机制（`#20` 已确证）：SDK 只按**当前生效的** `$(OutputPath)`/`$(IntermediateOutputPath)` 排除产物目录（`Microsoft.NET.DefaultOutputPaths.targets:126-127`）⇒ 一旦命令行 `-p:BaseIntermediateOutputPath=<仓外>`，**工程目录下**的 `obj/` 就**不再**被默认 glob 排除 ⇒ 陈旧 `*.AssemblyInfo.cs` 被收进编译 ⇒ `CS0579`。

**本件**：把同一行排除收敛到一个**共享 `.props`**，覆盖**全部**暴露工程（暴露集**必须实测枚举**，不采信"7 个"这个数）。
**硬要求**：放完共享 `.props` 后，`HbTextLineParity`/`TextLineProto` 的 `-getItem:Compile` 清单必须与放之前 **`cmp` 逐字节相同**（`#20` 的方法）—— 那两个工程是**五臂门禁/原型臂**的构件，**清单动了就等于动臂** ⇒ **动了就停并报告**。
**本件不跑构建**（`-getItem:Compile` 是求值，不构建）；完整构建验证**推迟到 P1 落地后**由主控在波尾做。

---

## §3 P3 —— `D-T6-b`：宽松档交回的行丢段落帧

`#20` 已实测：同 `pc`、同用例、只换档 ⇒ 两档**交回的行逐位相同**、只有**帧**不同（严格档 `0,1,2` / 宽松档 `0,0,0`）。本件要**静态归因**：定位 `HbTextFallback.TryFormatLine` 的"从 `cpFirst` 重新起段 + `return lines[0]`"路径，给出**精确到行号**的机制说明，并**写出下一波可用的判据草案**（含反极性：现状必红）。
**只读**：不跑 dotnet；需要运行期读数的地方**如实标为"本件未测"**，留给下一波。

---

## §4 P4 —— `D-R3` 残项 + `D-T5`/`D-T4` 就绪度

**只读盘点**，产出"下一波可执行条目表"：每项写清 ① 现场锚点（文件:行）② 判据草案 ③ 反极性 ④ 是否要动 shim（= 是否付世代成本）⑤ 阻塞项（如"需 Windows 重录"）。
`D-T4`（`DefaultIncrementalTab` 未在 PC 路径携带）**必须点明"需真机重录才有真值"**，不许用推测值当判据。

---

## §5 位移预测表（**P1 落地**；表外位移 ⇒ 停）

| 位 | 现（`#19`） | 预测 |
|---|---|---|
| `bridge` | `d567c26f197ec1e3`（4,987,840 B） | **不变**（不动 `src/WpfGfx.Linux/**` ⇒ **不重发桥**） |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | **不变** |
| **`pc`** | `f4a454c8fe69cdfe`（4,196,864 B） | **变**（`#16` 的 P1 把 **shim 整文件 sha** 编进 `AssemblyMetadata` ⇒ shim 一改必变；**"pc 变"不蕴含"行为变"**） |
| **`hbtextline`** | `fe1b7ed8fa3ed231`（278,692 B） | **变**（本波唯一实质源改） |
| `pf` | `bd4e28e6a6f8b0e5` | **变**（环成员，**每趟波必变**） |
| `windowsbase` | `1114a28ec5a03ab7` | **不变** |
| `provider` | `9aa0d744802aaa31` | **不变** |
| `win32shim` | `0098234982391bbf` | **不变** |
| `wic_shim` | `03b67fbcd7c385b6` | **不变** |
| `dwf` | `0ed422ef2dd46445` | **不变**（`dwf` 随 **WB** 字节变，WB 本波不变） |
| `inputs_fp` | `288447d98d255f4c…68d39` | **变**（`inputs_fp` 覆盖 `build/shims/**/*.cs`） |
| 五臂门禁 | `generation=#19 tree_gen=same` | **必然先 `NOINFO/rc=2 tree_gen=advanced`（设计，不是缺陷）** ⇒ **重取五臂 + 重钉 `known-red.json` 到 `#21`** |
| 应用门禁 | 6/6 `PASS`、`drawn=260/144`、`colors=3960/2828`、`frames=14/14`、`cross_ae=0`、`leftover_after=0` | **逐位不变**（⚠️ **watch item**：`Start` 若被渲染路径消费则会变 —— **变 ⇒ 不是失败，是发现，必须归因后再动**） |
| `verify-all` | rc=0 / 10 步 / 871 通过 / 第 10 步 ✅ | 重钉后**同前**（第 10 步在重钉前必然 `NOINFO`） |
| 等号读者 | `SHIM_SHA=no` | **`no`**（产物确实用这一份 shim 编） |

---

## §6 反极性红证（**缺一即本件作废**）

| 证 | 做法 | 必须看到 |
|---|---|---|
| **(a) 判据有判别力** | 用**修前 `pc`** 的留档副本（`f4a454c8fe69cdfe`）跑**新判据** | **红 171**（点名那 171 行、我方 `0` vs 真值 `24/48`）。**若修前也是全绿 ⇒ 判据零判别力 ⇒ 停** |
| **(b) 错驱动量也红** | 临时把 `Start` 改成 `=> indentDip` | **红 278**（`Start==Indent` 只命中 337/615） |
| **(c) 非空泛** | (a) 已经在**真实总体**（615 行）上红，不是"恒真/恒假" | 修后须**红 0 / 绿 615**，且 `PI=0` 的 444 行**逐位不动** |

(a) 与 (b) 都必须**留日志 + sha**；`Start` 的**修前**产物副本必须 `cp -p` 留档（`$HOME/wfp-runs/w21-pre/`）。

---

## §7 停条件（**触发即停，不许"顺手修好"**）

1. 任何位移**落在 §5 表外**。
2. 应用门禁读数**与预测不符**（先归因，再决定）。
3. 反极性 (a) 在修前 `pc` 上**不给红** ⇒ 判据作废。
4. 五臂重钉后 `unregistered>0` 或 `drift/gone>0`，或 `verify-all` 第 10 步**不恢复**。
5. 发现需要动 `Right`/`Center` 的 `Start` ⇒ **停**（本语料零覆盖 = 无真值）。
6. 任何"把红判据放松"的改动 ⇒ **停**（本波只许加强）。

---

## §8 落地顺序

1. **留档**：`cp -p` shim 与修前 `pc`（记 `before/after` 两个 sha16）。
2. **先落判据**（PcLineOracle 新增一列比较）⇒ 对**修前 `pc`** 跑 ⇒ 取 **红证 (a)**（红 171）。
3. **落 shim 修法**（`Start => _paragraphIndentDip` + 字段/构造点透传 + 注释更正）⇒ 重建 `pc` ⇒ 判据转 **绿 615/615**。
4. 取 **红证 (b)**（错驱动量 = `indentDip` ⇒ 红 278），随后**逐字节复原**。
5. **五臂重取** + `known-red.json` 重钉到 `#21`（`generation.id=#21`、`instr_shim` = 新 shim sha、`entries` 不变 ⇒ 若变必须逐条裁定）。
6. `verify-all` 冻树跑。
7. 应用门禁**两趟**（常驻 `:97` 复用）。
8. 文档：`docs/CURRENT-STATE.md`＋`handoff.md`＋`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（重冻 `#21`）＋`KNOWN-DEFECTS.md`（`D-T6-c` 由"可能产品缺陷"→ **已确证并已修**）＋ 本文件 §9 收官节。

---

## §9 收官清单

- [ ] 判据新增列 + 逐例可归因
- [ ] 红证 (a)(b) 日志 + sha
- [ ] shim 修法 + 注释更正 + 两个 sha16
- [ ] 九位位移**逐条**对上 §5（表外位移 ⇒ 停并记）
- [ ] 五臂重取、`known-red.json` 重钉 `#21`、`drift=0 gone=0 unregistered=0`
- [ ] `verify-all` 10 步 / 第 10 步 ✅
- [ ] 应用门禁两趟 6/6 + 与 `#19` 逐位对照
- [ ] 等号读者 `SHIM_SHA=no`
- [ ] `D-T6-c` 在 `KNOWN-DEFECTS.md` 改判 + 承认"3222/3222"是语料性质
- [ ] 基线重冻 `#21`（`ACCEPTANCE-BASELINE.md` 表头 + 6×6 `BASELINE` 行）

---

## §10 预登记**补遗**（主控，**在取任何读数之前**写下 ⇒ 不是事后解释）

### §10.1 `Start` **不是死成员**：消费方已定位（本波新查）

渲染路径**确实**消费 `TextLine.Start`：

| 锚点 | 用途 |
|---|---|
| `build/PresentationFramework.Linux/TextBlock.Linux.cs:1579` | `lineMetrics = UpdateLine(i, lineMetrics, line.Start, line.Width)` |
| `build/PresentationFramework.Linux/TextBlock.Linux.cs:1711` | 命中测试 `if ((line.Start <= point.X) && (line.Start + line.Width >= point.X))` |
| `build/PresentationFramework.Linux/TextBlock.Linux.cs:2057` | **布局盒 X** `new Rect(contentOffset.X + lineMetrics.Start, contentOffset.Y + lineOffset, …)` |

⇒ §5 里"应用门禁逐位不变"的 **watch item 是活的**（不是形式条款）。**前提已现场复读并成立**：
`grep -rn "ParagraphIndent\|\bIndent\b" samples/ --include=*.cs --include=*.xaml` ⇒ **0 命中**；`build/PresentationFramework.Linux/**` 里**没有任何** `ParagraphIndent` 赋值 ⇒ 应用路径 `PI ≡ 0` ⇒ `Start` 由 0 变 0 ⇒ **应用门禁逐位不变**（与 `#17` 已登记的同一前提一致）。
⇒ **但这是有作用域的**：`PI≠0` 时 PF 侧会**真的**移动（`contentOffset.X + PI`）。**本波没有一个样例覆盖 `PI≠0`** ⇒ PF 侧在 `PI≠0` 下的正确性 = **NOINFO，登记为后续项，本波不测也不改**。本波只断言**PC 成员与真机一致**。

### §10.2 坐标框架已实测（决定"修 `Start` 会不会重复计数"）

真机语料实测（`lead-tab-a`，逐字符）：

| 臂 | Indent | PI | `lineStartOffsetsDip[0]`（= `Start`） | 字符 0（`\t`）的 `x` | `width` |
|---|---|---|---|---|---|
| `i0p24` | 0 | 24 | **24** | **24** | 16 |
| `i24p24` | 24 | 24 | **24** | **48** | 24 |

- 字符 `x` = `Indent + PI`（`i0p24`: 0+24=24 ✓；`i24p24`: 24+24=48 ✓）⇒ **`GetTextBounds` 的 `x` 是段落系**（与 `#16` 确立的 "tab 的 `x` = `Indent + PI`" 一致）。
- 而 `Start` = **PI 单独**（两臂都是 24）⇒ **`Start` 与 `x` 不是同一个框架**，`Start` 是"线段自己的原点相对段落原点"。
- ⇒ 修 `Start` **不触碰 `x`/`width`**（本波不加不减任何几何量），只是把"线段原点"这个**成员读数**对齐真机。**不存在重复计数**：真机的 `TextBlock` 跑的就是同一对值，我们改完与真机同值。
- ⚠️ 如实登记的**残余不确定**：我们 PF 侧 `:2057` 在 `PI≠0` 下与真机是否同形，**本波未测**（无样例）⇒ 见 §10.1。

### §10.3 本波新查出的**仪器盲区**（登记为发现，**本波不修**）

1. **五臂门禁的 tab 臂对 `Start` 零判别力**：`build/MilBridge/tests/CoverageProbe/Program.cs`（`tab-oracle-zero/anchor/rtl` 三臂的宿主）**一个** `lineStartOffsetsDip` / `.Start` 的引用都没有（`grep` 命中 0）；它实际比较的字段是 `lineText` / `startChar` / `newlineLength` / `trailingWhitespaceLength` / `width` / `maxWidth` / `modifierStart` / `visibleText`。
   ⇒ **语料里一直躺着 615 个真值，而门禁从来没看过它** —— 这正是 `D-T6-c` 能长期存活的**结构性原因**。`height`/`baseline`/`hasOverflowed` 同族（也在语料里、也不在比较列）。
2. **新判据不在冻树回路里**：`PcLineOracle` 自述"本臂不是五臂门禁成员、不进 `verify-all`"（`Program.cs:463`），而五臂门禁是**只读读者**（不跑 harness）⇒ 只把比较加进 `PcLineOracle` 的话，**`verify-all` 仍然量不到它**。
   ⇒ 本波**先落判据**（保证有判别力），**接线**按 W21D 的"最小接线方案"在波尾评估；若本波不接线，**必须在 `CURRENT-STATE.md` 明确写"该判据当前不在冻树回路内"**（不许让它看起来像已守）。

### §10.4 文档自查（顺手，只记不修 ⇒ 波尾修）

`build/MilBridge/arm-logs/README.md:24` 写"跑五臂并把日志**软链**到本目录"，而**同文件** `:3-8` 与 `:60-64` 明令 **必须硬链接（`ln -f`）**、**禁止 `cp` 也禁止 `ln -s`**（`:5-6` 实测符号链接会被门禁 `find -type f` 漏掉 ⇒ 全臂 `NOINFO rc=2`）。
⇒ **`:24` 的"软链"是错字/过时表述，且它指向的正是会被实测判死的那种做法** ⇒ 波尾按纪律 4（引注前现场重读）更正为 `ln -f`，并记该文件 sha16 before/after。**仅文档，不付世代成本。**
（已更正：`build/MilBridge/arm-logs/README.md` `6924605fab87660e → 7de8a8cb069be60a`。⚠️ **同一句错话在 `verify-all.sh:184` 还有一份**（把 `arm-logs/*.log` 说成"**符号链接，不是拷贝**"），波尾随"新增第 11 步"一并更正。）

---

## §11 任务书**更正**（由车道用原始数据推翻；**原文保留在 §3 不删** —— 记我的错，不是抹掉）

### §11.1 §3 里我对 `D-T6-b` 的**现场定位四条全错**（车道 W21C，报告 `0dd5cf70f7e5d673`）

| 我写的（§3） | 实测 | 判定 |
|---|---|---|
| "宽松回退路径（`HbTextFallback.TryFormatLine` …，约 `:4496` 起）" | `HbTextFallback`（shim `:3972`）是**严格档**；**宽松档的类根本不在 shim 里**（在生成物 `:37`/`:264`，由应用器 `:195` 生成） | **错**（把严格档当宽松档） |
| "`return lines[0]`" | **shim 里 `grep lines[0]` = 0 命中**；真身在**生成物** `:264` | **错**（在错误的文件里找） |
| "`shim:3851` 起那个 `...FormatLine(...)` 入口" | `:3851` 是**形参表**；入口是 `:2819` | **错**（形参表 ≠ 入口） |
| 把 `D-T6-b` 说成"**宽松档**丢段落帧" | **两档共有**：帧原点 = "**最近一次重新收集的 `cpFirst`**"；**严格档在缓存未命中时退化成同一形状**（形状与 W20A 的 `--fresh-source` 读数 `0,1,2 → 0,0,0` 逐字吻合） | **错**（低估为单档缺陷） |

⇒ **定性收紧（本波实质发现）**：W20A 的"缓存是**保持正确帧**的一方"应升级为"**缓存是帧的唯一来源**"；`D-T6-b` 的真实名称是"**帧原点 = 最近一次重新收集的 `cpFirst`**"。
⇒ **与 `D-T6-c` 的关系（关键排期结论）**：`Start` **与帧无关**（`:3390` 是常量，不吃 `_lineStart`）⇒ **`D-T6-b` 与 `D-T6-c` 必须分开修、分开取读数**（本波只修 `D-T6-c`，与 §0 的分件一致）。
⇒ **逐成员影响面（车道已静态定完，本波只登记）**：受影响 = `GetTextBounds`（`shim:3022-3023` 返回**空表**，而真机是**夹取**，`upstream …/FullTextLine.cs:1495-1504`）、`GetIndexedGlyphRuns`、`Collapse`/`GetTextCollapsedRanges`，另 `BuildCollapsedLine` **硬写帧 0**（`shim:3625`）；**不受影响** = `Length`/`Width`/`WITW`/`NewlineLength`/`TrailingWhitespaceLength`/`Height`/`Baseline`/`HasOverflowed`/`GetTextRunSpans`/`Draw` 几何。
⇒ **真机消费者会炸**（不是"读数偏一点"）：`MS/Internal/Text/Line.cs:167` 之后紧跟 `:171 Invariant.Assert(textBounds.Count > 0)`；另有 `TextBoxLine.cs:259/:496`、`PtsHost/Line.cs:501/505/995/999`、`TextBlock.cs:2314`（选区高亮）⇒ **空表在真机侧是断言失败**。
⇒ 修法**要付世代成本**（需给 `HbTextLineFactory.FormatParagraph` 加**带默认值**的段落原点形参并透传到 `_lineStart`/`_glyphRunCharStart`）。

### §11.2 任务 C 的裁定 = **半对**（我引用的在册口径也该改）

被核句（`PcLineOracle/Program.cs:463` 一带）："88 条 `PI≠0` 的**逐行精算值不可从语料推出**（只量不预言）"。
- "**88 条**" **对**（`PI≠0` 例 112 个，其中 `script==latin` 恰好 88）；
- "**不可从语料推出**" **错** —— 语料**完整携带** `PI≠0` 的逐行真值：**16 个逐行字段 × 171 行全部存在且非 null**，另 292 条 `perChar` 的 `x`/`xFromLeftDip` **0 个 null**；
- "**只量不预言**" **对** —— 把 id 里的 arm 换成 `i0` 后，**没有一个 `PI≠0` 例的孪生 id 存在**（0 例）⇒ 孪生恒等式对它们**结构性不可用**（理由独立成立：`300·PI` 改写断点划分）。
⇒ 该句应改成"**真值在语料里、只是从未被比较过**；且**不可用孪生法交叉验证**"。**波尾改这句 + 一并改 `tab-anchor-oracle.json` 的 `unavailableOrUntested` 元数据。**

### §11.3 同一条伪证的**第三处**落点（本波新查）

`tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json` 的 `unavailableOrUntested` 末条写着 **"TextLine.Start is reported but is 0 for every line here"** —— **被它自己同一份数据否掉**（171 行是 24/48）。
⇒ 至此同一条"恒为 0"的伪证有**三处**独立落点：① shim `:3390` 的注释；② `layout-b34` 语料（`ParagraphIndent` 出现 **0** 次）上的推断；③ oracle 的元数据。
⇒ **修 [`D-T6-c`] 时必须三处一起改**，否则同一条伪证会被**第三次**引用（与 `#19` item A 同族：**注释/元数据与实现不符**）。
同理 shim `:1553`（`// 段落系（源文本下标）`）与 `:2628`（`// 行起始（段落系）`）在此调用姿势下**不成立**（只在 `text` 从段落原点起时成立）—— 这是 `D-T6-b` 的**文档侧伪证**，与 `D-T6-c` 的伪证**同族**，一并登记。

### §11.4 W21C 的**盲复核**结论（这是本波对 `D-T6-c` 最有价值的一条独立证据）

车道**在读完落盘之后**才读本预登记 ⇒ 是**真盲复核**，不是复述。它独立重算得到：
`Start==ParagraphIndent` **615/615、0 反例**；对照假设 `Indent` **337/615**、`PI+Indent` **384/615**、`Start==0` **444/615**、`PI+(firstLine?Indent:0)` **425/615**；子群体（LTR 459 / RTL 156、7 个 group、`firstLine` T/F）**全部 0 反例**；`PI→Start` **双射**、crosstab **无一个 off-diagonal**、**段内恒定**、语料自洽 **615/615**。
⇒ 与主控**逐位相同**，且它加固了两条我没写的：① **`R` 只舍 `1e-6` 而理想单位是 `1/300`** ⇒ `R` **藏不住真实差异**（"精确相等"是**可证**的，不是偏好）；② **快路径闸门**（`SimpleTextLine.cs:91-92`：`TextIndent≠0 或 PI≠0 ⇒ Create` 必返 null）⇒ 法律在 **LS 路径与快路径上同时成立、不留缝**。

---

## §12 另一条车道（W21D，报告 `c473dfc1dcbff583`）的**一条更正 + 一条采纳**

### §12.1 更正：`D-A2` 的机制说错了，**结论仍成立**

W21D 称"`SCAN_ROOTS` **不含** `.artifacts/**`"。**主控实测否掉**：`check-applocal-sync.sh:93` `SCAN_ROOTS="${SCAN_ROOTS:-$REPO/build:$REPO/tests:$REPO/samples:$REPO/src}"`，而 `build/MilBridge/.artifacts/**` **就在 `$REPO/build` 之下** ⇒ **在扫描范围内**。
**但它的结论对，正确的机制是两条**：
1. **`PresentationCore.dll` 根本不在 `ITEMS` 里**（`check-applocal-sync.sh:97-104` 只有 6 项：`libwpfwic.so`、`libwpfwin32.so`、`DirectWrite.Linux.Provider.dll`、`WpfGfx.Linux.dll`、`ReachFramework.dll`、`wpfgfx_cor3.so`）⇒ 它的副本**再陈旧也不会有任何读数**（这正是 `D-A2` 那条）。
2. `wpfgfx_cor3.so` 的**权威串是空的**，且**显式写明不覆盖**（`:103`：由集成波逐波重建、publish 输出即权威，交给发布脚本的并排 sha 打印）⇒ **桥的任何副本在 `APPSYNC` 里永远不能变红**。
⇒ 记：**"只判 5 个件 + 1 个显式不覆盖"** 是准确的；"扫描范围不含 `.artifacts`" **是错的**。**结论（有大片未判副本）成立，机制按上两条重写。**

### §12.2 采纳：**接线后的可证伪预测**（本波要实测它）

W21D 预测"接线后 `tline-gate（五臂）` 会先红（`known-red.json` 无 `pc-line-oracle` 条目 ⇒ `unregistered>0` ⇒ `rc=1`）"。
**主控裁定：这条被证伪的概率很高，理由是指令本身**——`tline-gate.sh` 是**只读读者**，只吃 `--logdir`（`arm-logs/*.log`）且 `ARMS=(tline tab-oracle-zero tab-oracle-anchor tab-oracle-rtl textlineproto)` **是固定五项**；而新增的 `pc-line-step.sh` **不往 `arm-logs/` 写任何日志** ⇒ 它**不进门的射程**。
⇒ **但"预测"必须用读数裁决，不许用推理裁决**：波尾接线后**实测门禁**，把 `TLINE_GATE=… unregistered=… rc=…` 原样记录下来。若门禁真的变红 ⇒ **W21D 对、我错**，按它的路径处理并写进文档。

---

## §13 主控**自认的一处口径错误**（必须与结论一起读；**这条是我的错，不是车道的**）

### §13.1 错误内容
我在本文件 §1.1/§1.6 与发给 W21A 的指令里，把 `Start` 判据的**预期红数**写成 **171 行 / 112 例**。那个数来自 `$HOME/w21-verify/expected-red.tsv`（sha16 `52fe6204f09be64a`），是**整份语料**的统计 —— **不是"臂该报的红数"**。

### §13.2 为什么错
W21A 的臂**有覆盖闸**：只有 `script == "latin"` 的例可比，其余 **148 例**（hebrew/arabic）因**缺字形跳过**（臂日志头自己写 `script=latin=288`）。而我**没有把覆盖闸算进预期**。

### §13.3 正确的双口径表（主控重算，可复现）

| 口径 | 例数 | 行数 | `Start ≠ 0` 的行 |
|---|---|---|---|
| **整份语料**（= 真值总量） | 436 | 615 | **171** |
| **臂真正判定的**（`script==latin`） | **288** | **421** | **138** |
| 其中 `PI≠0` 的例 | **88** | —— | `Start≠0` 的行全在这 88 例里 |

⇒ **本波判据的预期红 = `138 行 / 88 例`**（绿 = `421 - 138 = 283` 行）。
⇒ 若最终读数落在 171 ⇒ **说明覆盖闸没生效、把不可比的例也算进来了**（那是**另一种**错，要查）；若落在别处 ⇒ 逐条点名核对。**三种情形都要在报告里区分开，不许含混。**

### §13.4 连带更正：§1.4 补遗里"判据覆盖 LTR + RTL"**只对语料成立、对臂不成立**
RTL 的 33 行非零值**全在 `C-rtl-indent` 组**，而该组是 **Hebrew ⇒ 全部被覆盖闸跳过**；`latin` 的那 138 行**恰好全是 LTR**。
- **法律本身**在 LTR(138 行) / RTL(33 行) 两向都是 **0 反例** —— 这是**语料侧**的独立证据，**仍然成立**，应写进报告；
- **但本臂实际判定的是 LTR 那一半** ⇒ 报告必须写"**RTL 半边由语料侧证据支持、本臂因缺字形未行使**"，**不许**写成"判据覆盖了 RTL"。
- 这与 §10.3 第 1 项**同族**：**"在射程内"与"真的看了"不是一回事** —— 我在 §10.3 里刚刚指出别人的这个错，转头在 §1.4 里自己犯了它的镜像（把"语料里有"当成"臂会判"）。

### §13.5 元教训（记进纪律候选）
**"真值总量"与"本条腿的可比子集"是两个不同的分母**。凡写"预期红/绿"必须**同时写清分母是哪一档**（这里：`script=latin`）。本项目已有"读数必须连 artifact+字段+sha 一起写"（纪律 15/18），本条是它的**同族**：**还要连"分母口径"一起写**。

---

## §14 主控落地的**第三处伪证**修复（`#21` 内完成；这处**不付世代成本**，但**要按纪律 35 披露**）

### §14.1 动手前的两条前置检查（都通过）
1. **该文件是生成物**：`tests/parity/windows/tab-anchor/out/tab-anchor-oracle.{json,txt}` 由 `tests/parity/windows/tab-anchor/analyze.py` 生成 ⇒ **手改生成物 = 纪律 38 的坑**（`#17` 的事故形态）⇒ 必须**改分析器再重生成**。
2. **生成物可复现（本波顺带证实的一条硬性质）**：在**未改动**任何文件的状态下重跑
   `python3 analyze.py out/tab-anchor-raw.json <tmp>/oracle` ⇒ 与仓库里已提交的 `out/tab-anchor-oracle.{json,txt}` **`cmp` 逐字节 IDENTICAL**。⇒ 这份 oracle **确实可从它自己记录的 `raw` 重算出来**（`derivedFrom.sha256` 也钉着 raw）。
   ⇒ 处置 = **把断言换成读数**：`analyze.py` 里那条手写字符串改成**从 `data["cases"]` 现算**的 `START_NOTE`（逐行比较 `lineStartOffsetsDip[k]` 与 `paragraphIndentDip`，把命中数/反例数/取值域写进 oracle 自己）。**断言变成读数 ⇒ 它不可能再过期。**

### §14.2 改动与 before/after（**留档**）

| 件 | before | after |
|---|---|---|
| `tests/parity/windows/tab-anchor/analyze.py` | `8f953bd002616689` | **`f4780fbb12efbc7c`** |
| `…/out/tab-anchor-oracle.json` | `a31a813114256faf` | **`0cebc0afd5142fbf`** |
| `…/out/tab-anchor-oracle.txt` | `bdf2c31a7a34fbc9` | **`34bab0b1032d2cd2`** |

备份在 `$HOME/w21-verify/backup/`（`cp -p`）。

### §14.3 三条**证明**（改的就是该改的，没碰别的）
- **`cases` 逐字未动**：`json.load(...)["cases"]` 前后**完全相等** ⇒ **臂吃的数据一个字节没变**（臂读的就是 `cases`）。
- **`unavailableOrUntested` 只有 1 条变**：两版逐条比较 ⇒ `len 9 == 9`、**唯一差异在 `index 8`**，其余 8 条逐字相同；**其余任何顶层键都没变**（含 `derivedFrom.sha256` = `88559d670f1bb955…`，即 raw 的指纹未被触碰）。
- **幂等**：重跑一次分析器 ⇒ 产物 sha **逐位不变**（`0cebc0afd5142fbf` / `34bab0b1032d2cd2`）⇒ 修完仍是确定性生成物。
- **伪证在生成物里已绝迹**：`grep -rln "is 0 for every line here" tests/ build/` ⇒ **0 命中**（只在本预登记与 `W21C-report.md` 里作为**被推翻的历史**被引用）。

新读数原文（**现算**，写进 oracle）：
> TextLine.Start IS reported for every line and is **NOT always 0**. … **171 of 615** lines report a NON-zero Start … All 615 lines satisfy **Start == ParagraphIndent** (counterexamples to that rule in this corpus: **0**); the observed value set is **{0: 444, 24: 131, 48: 40}**. …

### §14.4 ⚠️ 纪律 35 披露（**这是"仪器输入"的改动，必须与读数一起读**）
- `tab-anchor-oracle.json` 是**五臂门禁里 `tab-oracle-anchor` 那一支的输入**。它变了 ⇒ 该臂**下一次重取的日志**是在**新输入**上取的。
- **但它不可能改变该臂的任何判决**：臂读的是 `cases`，而 `cases` 已证明**逐字未动**（§14.3）。（臂**也不看** `unavailableOrUntested` —— 该字段纯人读。）
- **仍要实测兑现，不许只靠推理**：本波重取五臂后，把 `tab-anchor` 臂的**判据行**与 `#19` 的日志逐行对照；若有任何判据行移动 ⇒ **停并归因**（那时的候选因就有两个：shim 与这份输入）。
- 另：`#21` 因此在**同一世代里有两个非语义改动**（shim 的 `Start`＋这份 oracle 元数据）。**它们的可观测面互不相交**（前者只动 `TextLine.Start` 一个成员；后者只动一个纯人读字段），所以归因仍可分 —— 但这一点**必须在报告里写明**，不许含糊。另两处伪证落点：① 我方 shim `:3390` 的注释 —— **已由 W21A 在本波改掉**（现 `:3417-3434` 有长篇更正）；② `layout-b34` 语料的推断 —— 是**推断**不是文件，已在 `W21B`/`CURRENT-STATE` 口径里更正。

### §14.5 归因点名（**回答 W21A 在报告里提的那个问题**）
W21A 报告末尾提请注意："`tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`（18:39:23）与 `analyze.py` 在本波进行中被写过，**不在我写域** …… 请核是谁改的。"
⇒ **是我（主控）改的**，就在 §14 里，改动时间 18:38–18:40，**不是第三方、不是并发污染**。三条边界必须一起读：
1. **W21A 的读数不受影响**（它自己核过）：它的判据只吃 `tab-anchor-raw.json`（`88559d670f1bb955`，本波**未被触碰**），而 §14.3 已**机器证明** `cases` 块在改动前后**逐字相等**。⇒ 它的红/绿证都成立。
2. **`analyze.py` 与那份 oracle 是我的写域**（`tests/parity/windows/**` 不属任何车道的写域，也不在 `inputs_fp` 内）。
3. **但"我改的"不等于"没有代价"**：它给 `tab-oracle-anchor` 臂**换了输入** ⇒ 本波重取该臂后，其**判据行与 `#19` 日志逐行对照**这件事**必须做**（§14.4 已写为硬要求），不许因为"只是元数据"就跳过。

---

## §15 主控**第二处口径错误**与三条精确化（由 W21A 的实测推翻，**原文保留在 §1.6/§5/§6 不删**）

### §15.1 **§6 红证 (b) 的目标数写错了：`222 行 / 148 例`，不是 `278`**
- 我写的 **278** 是**整份语料**口径（`Start==Indent` 命中 337/615 ⇒ 615−337 = 278）。
- 臂的**实际可判定**口径是 `script=latin` 的 **421 行** ⇒ 正确目标 = **615→421 同比例换算后的 222 行 / 148 例**（绿 199）。**W21A 独立重算 222/421 与实测逐位吻合。**
- ⇒ **这与 §13 是同一个错**：我又一次把"**语料总量**"当成了"**本条腿的分母**"。**§13.5 那条元教训我写下了却没在同一份文件里贯彻到 §6** —— 如实记。
- ⚠️ **这条错的性质要说清**：它**没有**导致误判（W21A 自己算了正确分母并报告了偏差，我据以更正），但它**本可以**导致"你没做出 278 ⇒ 判你失败"的假红。

### §15.2 §5 的 `pf` 预测：**前提写错了**（预测本身在波尾仍然成立）
我写"`pf` **变**（环成员，每趟波必变）"—— 实测 W21A 车道内 `pf` **未变**（`bd4e28e6a6f8b0e5`）。
⇒ **前提错在**：`pf` 只在**波尾 `close-wave` 的 `integration-wave.sh`** 重编 PC/PF/WB 时才变，**不在单条车道的射程内**。⇒ §5 的位移表量的是"**整趟波**"，而车道只跑其中一段。**该预测在波尾仍然生效，我必须在波尾逐位复核它**（这正是 §5 存在的意义）。
⇒ 记法更正：位移表的每一行都要标**"由谁的动作引起"**（车道 / 波尾 / 两者），否则"预测未兑现"与"还没轮到"分不开。

### §15.3 §1.6 的"最大差"判别例点错了族
应点 **`D-paraindent/lead-tab-a@w100@LTR@i0p48@default`（Δ = **48**）**，不是 `i24` 那族（Δ = 24）。我点名的 `B-indent-extra/lead-tab-a@w40@LTR@i24p24@default` 行 0/1（`0.000000` vs `24.000000`）**逐字如预测**，那部分没问题；错的是"最大差"那格。

### §15.4 `rc=3` 的精确化（我上一条给 W21A 的话**不够准**）
我写"`rc=3` 是 W20A 的 `--guard enforce` 出口码"。**W21A 实测推翻**：`--guard enforce` 而 `s_guardFailed=0` 时**落回三态 `rc=1`**；`rc=3` 的**必要条件**是"**贴标签前提不成立**" ⇒ `enforce` 是**必要不充分**。⇒ 正确写法：**`rc=3` ⇔ 前提不成立（`enforce` 下）**，不是"`enforce` ⇒ `rc=3`"。
另：我引的那份 `$HOME/w21a-run/redA-prefixpc.out`（451 行 / 末行 `rc=3`）**W21A 核不到出处**（它两份主日志是 1,311/1,654 行、`rc` 均 1）⇒ 那是**车道过程中的中间产物**，我用它立论**技术上成立**（`位置=` 确实不反映新列，W21A 已照三条要求补齐），但**"证据来自哪一趟"这一步我当时没核**。⇒ 与 §13.5 同族：**引读数还要连"它是哪一趟的产物"一起核**。

### §15.5 新增在册项（由 W21A 的两条额外证产出，**都值得进 `CURRENT-STATE`**）
1. **判据两极化（防 `NOINFO` 恒绿）**：把语料头的 `TextAlignment` 改成 `Right` ⇒ `判定行=0 / NOINFO=216 / rc=2`；删掉 `fixed` ⇒ `rc=2`；真语料阳性对照 ⇒ 真断言 `rc=1`。⇒ **"判据在无覆盖时不给绿"** 这件事被实测钉住了。
2. **无回归是机器证、不是人眼**：修前/修后同版仪器日志按列对比 ⇒ `PCLINE CASE` 头 **436/436 相同**、`STRUCT 56/56`、`TWIN 355/355`、`NAMED 6/6`、`GUARD 74/74` **全逐位相同**；**修后新增红 = 0 例**；且既有读数与 `#19` 冻结基线**逐位复现**（`红=127 绿=57`、`零缩进 63/41`、`PI≠0 64/112`、`未登记失败=67`）⇒ **本修法在 `Start` 之外零射程**。这是本波最强的一条"我们没碰别的东西"的证据。


---

# §16 收官（`#21` 波完成记录，主控，2026-09-16 19:1x）

## §16.1 本波交付的件与它们的 sha

| 件 | 变更 |
|---|---|
| `build/shims/PresentationCore.HbTextLine.cs` | `fe1b7ed8fa3ed231 →` **`76089e1de586ac91`**（278,692 → 283,557 B） |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `f4a454c8fe69cdfe →` **`e7cabff9417ed380`** |
| `build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll` | `bd4e28e6a6f8b0e5 →` **`2fb1a896f8277647`**（环成员，波尾重编） |
| `build/MilBridge/tests/PcLineOracle/Program.cs` | `19f9e7e78e9bb5c7 →` **`a787a9db23c3302c`**（新增 `Start` 列） |
| `build/MilBridge/known-red.json` | `3bf26e12f320dece →` **`2fdc02931c2af796`**（`generation.id=#21`） |
| `verify-all.sh` | `a68823631e8f8919 →` **`279b958dda238447`**（**第 11 步** + 更正"符号链接"错话） |
| `build/MilBridge/tools/pc-line-step.sh` | **新**；**两版**（纪律 35 两个 sha 都记）：初版（只跑 oracle 并透传它的 rc）`3f8d26ab077d2ec1` → **定版**（只判 `Start` 列 + 防恒绿退化 + 副本==权威自检）**`fa62842d8e211b07`**。⇒ 引用必须点明是哪一版；`verify-all` 第 [5] 步用的是**定版** |
| `build/MilBridge/tools/retake-arms-w21.sh` | **新** |
| `BuildHygiene.props`（仓根） | **新** `c88fcccde138263b` + 38 个 csproj 各加一行 `Import` |
| `tests/parity/windows/tab-anchor/analyze.py` | `8f953bd002616689 →` **`f4780fbb12efbc7c`** |
| `…/out/tab-anchor-oracle.json` / `.txt` | `a31a813114256faf →` **`0cebc0afd5142fbf`** ／ `bdf2c31a7a34fbc9 →` **`34bab0b1032d2cd2`** |
| `build/MilBridge/arm-logs/README.md` | `6924605fab87660e →` **`7de8a8cb069be60a`** |
| `docs/CURRENT-STATE.md` | `a0463319bf6bad70 →` **`61030d422e0d7cac`**（含纪律 39–43） |
| `handoff.md` | `54b8df7c5b8aee47 →` **`540b7564e365492f`** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `f1351506adf4dbc7 →`（`D-T6-c` 改判为**已修** + 新增 `D-T6-b` 收紧条目） |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `f5d8a6f1cdf49635 →` **`0d048e6e8808c4e7`**（**重冻 `#21`**） |
| 四份车道报告 | `W21A` `b6865b2409091298`｜`W21B` `66a78a99bf1b3847`｜`W21C` `0dd5cf70f7e5d673`｜`W21D` `c473dfc1dcbff583` |

## §16.2 位移表**逐条兑现**（§5 的预测 vs 实测）

| 位 | 预测 | 实测 | 判定 |
|---|---|---|---|
| `bridge` | 不变 | `d567c26f197ec1e3` 未变 | ✅ |
| `BRIDGE_SRC_FP` | 不变 | `b6acdba4f01599d8` 未变 | ✅ |
| `pc` | 变 | `f4a454c8fe69cdfe → e7cabff9417ed380` | ✅ |
| `hbtextline` | 变 | `fe1b7ed8fa3ed231 → 76089e1de586ac91` | ✅ |
| `pf` | 变 | `bd4e28e6a6f8b0e5 → 2fb1a896f8277647` | ✅（**但在车道射程内不变** —— 见 §15.2 的更正） |
| `windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` | 不变 | 逐位未变 | ✅ |
| `inputs_fp` | 变 | `288447d9… → a2b74537427ecc4a987edbe52a59c5d01d4817d54de58f445833c33dfb0e78e0` | ✅ |
| 五臂门禁 | 先 `NOINFO/advanced`，重钉后 `PASS` | 逐字如预测 | ✅ |
| 应用门禁读数 | 逐位不变 | **六条机读 `BASELINE` 行与 `#19` 逐字相同**（只差三个 sha 与 `rundir`） | ✅ |
| `verify-all` | 重钉后同前 | rc=0 / **11 步** / 871 通过 2 跳过 | ✅（**步数 +1，口径已变**） |
| 等号读者 | `no` | `SHIM_SHA=no`（`product_sha16 == tree_sha16 == 76089e1de586ac91`） | ✅ |

**表外位移：无。**

## §16.3 三条读数（全部可复算）

1. **判据两极化（`Start` 列）**：修前 pc ⇒ **红 138 行 / 88 例**（判定行 421，最大 Δ=48.0 @`i0p48` 行#0）；修后 ⇒ **红 0 / 绿 421 / 最大 Δ=0.000000**；错驱动量 ⇒ 红 222/148。
   与主控冻结的期望集 `$HOME/w21-verify/expected-red.tsv`（`52fe6204f09be64a`）**集合级对账**：`only-in-arm = 0`、`only-in-exp = 0`。
2. **五臂门禁**：`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#21 tree_gen=same saved_shim=76089e1de586ac91 gate=b37a5c9f55ae71a4 judge=t1b3-tline-gate/2`、`GATE_REASON=all-as-registered`、`rc=0`。
   **四支臂逐字节不变**（`tab-zero b9d81590f3fcd800`、`tab-anchor 99d72b385fe23a90`、`tab-rtl 419e8aaa9c72a9a0`、`textlineproto 4bceceeed570ba70`）；`tline` 换日志 `aa7259da9e2c77e8 → de605bf708dcdb5a`，逐行 diff **26 行（13 对）全是身份/管道行、无一条判据行移动**。
3. **冻树 `verify-all`**：`步骤通过 11 ❌ 失败 0`、`用例通过 871 跳过 2`、`结论：✅ 全部通过`、脚本 `rc=0`；第 [4] 步五臂 ✅、**第 [5] 步 `PcLineOracle·Start 列` ✅**（`红=0 绿=421 判定行=421 NOINFO=0`）。

## §16.4 纪律 38 的红线判据（**已做**）

`W21B` 往 38 个 csproj 手加了 `Import` 行，而波的第 1 步会跑 `port-lib.py`（历史上静默抹掉过手加内容 ⇒ 纪律 38）。
⇒ **主控做法**：波**前**冻结这 38 个 csproj 的 sha 清单（`$HOME/w21-verify/csproj-imports-before.txt`，`d0873b57ef29c53a`），波**后**重算并 `cmp` ⇒ **IDENTICAL（38/38 逐字节存活）**。
⇒ 且**事先用推理排除**了风险：`port-lib.py` 只重写 `build/<Name>.Linux/<Name>.Linux.csproj`，**38 个里没有一个属于该家族**。**但推理不算数，以 `cmp` 为准。**

## §16.5 本波**未做**（不许当绿）

1. **`CoverageProbe` 仍对 `TextLine.Start` 零判别力** —— `#21` 把判据接进 `PcLineOracle`（→ `verify-all` 第 11 步），**没有**把它接进五臂门禁的臂仪器。⇒ `D-G1` 只堵了一半。
2. **`StrictTierProbe`（`D-T6` 定性仪器，`d628ce429240b37c`）不在任何冻结文档 / 门禁 / 基线里** ⇒ `D-T6` 的 `ARM/DEVICE` 定性**在冻树上无法复算**。
3. **非九位"可见位"仍无指纹判据**（`D-G3`）：`WpfGfx.Linux.dll = c400ab1638e0c3d2` 已在 §1 记录，但**没有任何判据盯它**；文档里 `D-A1` 那行引的仍是旧值。
4. **折叠行 / 单 run 便捷构造在 `PI≠0` 下的 `Start` 真值 = NOINFO**（语料零覆盖）。
5. **`D-T6-b` 未修**（要付世代成本）；**`D-F2` 的三个静默计数器未接出口**（`D-G4`）。
6. **`D-R8` 残项 1 个未封**（`src/WpfGfx.Linux/WpfGfx.Linux.csproj`，按停条件挂起）。

## §16.6 下一波建议（按价值排序）

1. **`D-T6-b`**（帧原点 = 最近一次重新收集的 `cpFirst`；真机是**夹取**而我们是**空表** ⇒ 真机侧是断言失败级）。**要付那笔世代成本**，且**正是**把 `D-F2` 的三个计数器一起接出口的最佳时机（两者都动 shim ⇒ 只付一笔）。
2. **把 `lineStartOffsetsDip` / `Start` 的比较接进 `CoverageProbe`**（补 `D-G1` 的另一半；代价 = 臂仪器变更，按纪律 35 记 before/after）。`height`/`baseline`/`hasOverflowed` 同族，一并评估。
3. **`D-R3` 残项 (iii)：判据① 的修前对照** —— **唯一一条"判据本身从未被验过"**（可能恒绿 = 不算判据），成本极低，且**有保质期**（修前件在 `$HOME`，历史上被清过一次）。
4. `D-A2` 间接依赖副本盲区；`D-T5`（若"异常会传到应用层"被实测为真 ⇒ 立刻升第 1）。

## §16.7 元结论（本波最值钱的三条，都与"判据"本身有关）

1. **判据存在有三种强度，只有第三种算有判据**：① 不在门里（`PcLineOracle`）；② **在门里但不看那个字段**（三支 tab 臂在门里，宿主 `CoverageProbe` 对 `lineStartOffsetsDip`/`Start` 零引用）；③ 真的看了且能变红。**`D-T6-c` 靠的正是第 ② 种 —— 比"不在门里"更隐蔽。**（已立纪律 41）
2. **手写的"全称断言"是伪证的温床**：`D-T6-c` 的伪证有三个落点，共同机制都是"把当时语料上成立的现象手写成一句永远为真的断言"。**处置 = 把断言换成读数**（`analyze.py` 改成现算）。**写不出反例计数的全称断言，视为未验证。**（已立纪律 43）
3. **"真值总量"与"本条腿的可比子集"是两个分母**，而主控在本波**两次**用错（171 vs 138、278 vs 222）。**分母写大会假红、写小会假绿，两种都不报错。**（已立纪律 39）

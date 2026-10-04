# T1d：逐行 EOP dump（handoff:403 欠账）——实现 + 牙 + 结构性结论（2026-09-13）

> **源已定**：`build/shims/PresentationCore.HbTextLine.cs` = `e1bc947afc248b323e227ba0f55e8e36a25dd791f92c3e8ba767f841df402860`（4040 行）。
> 本轮**没跑应用、没发桥、没重建 PC**；`src/**`、`samples/**`、`build/*.Linux/**`、别人的 `build/MilBridge/**`、`CoverageProbe/refs/**` 都没动。

## 0 结论速览
1. **逐行 dump 已具备**：`WPF_LINUX_TEXTLINE_PERLINE=1` ⇒ 每行一条机读 tuple（有界 1000 条），字段含
   `start/cpFirst/cpLast/len/nl/visible/hardBreak/eop/forced/keepState/modifier/runs/spans/text`。
2. **默认关 = 逐字节无副作用**（A/B `diff` 为空）+ 关时 dump 文件里 **0** 条逐行记录、stderr **0** 污染。
3. **牙已咬**：同一段文本里 `eop=0`（软断行）紧接 `eop=1`（段末）实测 **142 处**；`eop=1` 之后同段还有行的反例 **0 处**。
4. **结构性结论（重要）**：`GetTextRunSpans()` **不是"按构造不可得"** —— 它有 5 个 PF 调用点，但**当前样例一条都走不到**
   ⇒ `getTextRunSpans=0` 是**预期**；欠账应改写为"**当前样例不可得 + 取样路径**"（见 §3），而不是继续挂着。

---

## 1 实现（改了哪些行、惰性怎么保证）

**新增开关**：`WPF_LINUX_TEXTLINE_PERLINE`（`HbTextLineScaffold.PerLineEnvVar`，`:1799`）。
**落盘位置**：复用 `WPF_LINUX_TEXTLINE_DUMP` 指定的文件（未配 ⇒ stderr）。逐行记录在**构造时**追加，汇总仍在 `ProcessExit` 追加 ⇒ 同一文件里**逐行记录在前、汇总在后**。
**接线点**（4 处，全部只读）：
| 位置 | 内容 |
|---|---|
| `:1822` `HbTextLineScaffold.NoteLine(line)` | 逐行 dump 入口；返回本行 `seq`（0 = 未 dump） |
| `:2357`（`HbTextLine` 私有构造器末尾） | `_dumpSeq = HbTextLineScaffold.NoteLine(this);` |
| `:2807` `HbTextLine.LineDumpTuple(seq)` | **唯一建串处**（`StringBuilder(200)`），只在开关打开后被调用 |
| `:2505`（`GetTextRunSpans()` 内） | `if (_dumpSeq != 0) NoteSpanQueryOnLine(this, _dumpSeq);` ⇒ 事后补记"这一行被问过" |

**惰性纪律（本项目栽过"探针把调用点实参提前求值 ⇒ 静态初始化炸"）怎么保证**：
- `NoteLine()` 的**第一条语句就是** `if (!PerLineEnabled) return 0;`（`:1824`）⇒ **关时**：不读环境变量（开关本身缓存在静态 `int`，`-1/0/1`，见 `:1810-1815`）、
  **不构造任何字符串**、**不装箱**（全部是 `int`/`bool`/现成 `string` 字段）、**不做任何遍历**（`runs=` 只读 `_glyphRuns.Count`，不枚举）。
- 建串只在 `LineDumpTuple()`/`EscapeForDump()` 里发生，而它们**只在开关打开后**被调用 ⇒ "关时零分配"是**结构性**的，不是"看起来快"。
- `GetTextRunSpans()` 那一格在关时只多一次 `int` 比较（`_dumpSeq` 由构造器写成 0）。
- **有界**：逐行 `PerLineBudget = 1000` 条、查询补记 `SpanQBudget = 200` 条，超限只打**一次** `**预算用尽**` 标记（实测恰 1 条）。

## 2 牙（离线，本轮实测）

**装置**：`HbTextLineParity`（同一 harness、同一 PC、只换 shim 源）+ 我车道内的 A/B。

**(a) 默认关：逐字节无副作用**
```
$ diff <旧(5a04875a 重建件) 的 harness 输出> <新(e1bc947a) 的 harness 输出>
OFF_DIFF_RC=0          ← 逐字节相同
两趟都是：通过 20 / 失败 2
```
关时把 dump 打开也不许有逐行记录：
```
WPF_LINUX_TEXTLINE_DUMP=/tmp/…off.dump（不设 PERLINE）⇒ 文件里 HBLINE_LINE 条数 = 0（只有汇总行）；stderr 里 0
```
**(b) 开 `PERLINE=1`：逐行 tuple + 同一段里 `eop` 随行变化**
```
逐行记录 1000 条（= 预算上限；多余部分只打 1 条"预算用尽"）
eop=1 → 159 条；eop=0 → 841 条
HBLINE_LINE#1 start=0 cpFirst=0 cpLast=16 len=16 nl=0 visible=16 hardBreak=0 eop=0 forced=0 keepState=0 modifier=0 runs=1 spans=0 text="The quick brown "
HBLINE_LINE#2 start=16 cpFirst=16 cpLast=31 len=15 nl=0 visible=15 hardBreak=0 eop=0 …
…
同一段里 `eop=0` 紧跟 `eop=1`（`cpLast(i)==cpFirst(i+1)`）的处数 = **142**
  例：seq#6 start=84 cpLast=92 eop=0 → seq#7 cpFirst=92 cpLast=103 eop=1
反向校验：段内 `eop=1` 之后**还有**同段行的处数 = **0**（语义正确：EOP 只出现在段末行）
另：`nl>0` 的记录 165 条，其中 `eop=1` 159 条（⇒ 6 条是段中硬断行 `nl>0 & eop=0`）
start == cpFirst 全部成立（同一个字段 `_lineStart`，tuple 里两个名字都给）
```
**(c) 三形态编译**：`DirectBranchCheck` / `HbTextLineParity` / `CoverageProbe` 各 **0 错**。
**(d) "只加了读数"的逐字节自证（两步）**：新件回退 `start=` 字段 ⇒ 命中 `e8db366c…`；再回退逐行 dump 的 4 处 ⇒ 命中 `5a04875a…`
⇒ 与上一版相比**只多了逐行 dump**，修法①/② 与其它插桩一行未动。

⚠️ **未自证的牙（如实登记）**：`spans` / `HBLINE_LINEQ#` 那一格**本轮没有牙** ——
它只能由**真实调用点**触发，而 harness/探针都不调 `GetTextRunSpans()`；
按主控明令（"在 harness 里自己调一下让它变 1 = 伪造证据，明确禁止"）**我没有伪造调用**。
⇒ 它的牙要等 T3 的 `--only=textbox-edit` 那趟（TextBox 路径）带 `WPF_LINUX_TEXTLINE_PERLINE=1` 一并取；届时可见"**哪一行**被问过"。

## 3 结构性结论：`GetTextRunSpans()` 到底能不能取？（要求 4）

**能取 —— 不是按构造不可得**；但它只在 5 条 PF 路径上被调用（T1b 给的清单，我把每处的宿主方法读出来了）：

| PF 调用点 | 宿主方法 | 触发条件 | 当前样例走不走 |
|---|---|---|---|
| `MS/Internal/documents/TextBoxLine.cs:370` | `IsAtCaretCharacterHit`（`:320`） | **TextBox** 光标命中 | ✗（⑩ 块是 `TextBlock`） |
| `MS/Internal/Text/Line.cs:414` | `GetCollapsedWidth()`（`:325`） | `TextBlock` + **TextTrimming**/collapse 宽度 | ✗（样例无 trimming） |
| `MS/Internal/Text/ComplexLine.cs:150` | `ComplexLine.Arrange` | 行内含 **inline 对象/复杂内容** | ✗（纯 `TextBlock.Text`） |
| `MS/Internal/Text/ComplexLine.cs:225` | `ComplexLine.HasInlineObjects` | 同上 | ✗ |
| `MS/Internal/PtsHost/Line.cs:277` / `:381` / `:661` | `PtsHost.Line.Format` / `CreateVisual` / `GetGlyphRuns` | **FlowDocument / PTS 段落**路径 | ✗ |

⇒ **判定**：`getTextRunSpans=0` 在**当前样例**上是**预期行为**（这些块既不进 TextBox、也不开 trimming、也没有 inline，走的正是"不该调它"的那条路）。
**欠账应改写为**：
> "`GetTextRunSpans()` 的达标读数**在纯 `TextBlock.Text` 样例上按构造不可得**；要取必须换路径：
> ① T3 的 `--only=textbox-edit`（走 `TextBoxLine.cs:370`）；或 ② 加一块带 `TextTrimming` 的 `TextBlock`（走 `Text/Line.cs:325`）；或 ③ 加一块含 inline 对象的块（`ComplexLine.cs:150/225`）。"
（这条与 T1b 的核实一致：PC 侧一个调用点都没有 ⇒ 只能由 PF 侧那些路径触发。）

## 4 主控下一步 / 边界
- **源已定**（sha 见文首）⇒ 请发波把 shim 编进权威 PC（`hbtextline` 位会变 ⇒ **会重冻 #8**）。
- 应用侧取逐行 EOP 的姿势：`WPF_LINUX_TEXTLINE_PERLINE=1` + `WPF_LINUX_TEXTLINE_DUMP=<path>`（不配 dump 路径则写 stderr），
  与 `--only=…` 那趟一起跑；文件里逐行记录在前、汇总在后，逐行字段用 `start/cpFirst` 关联到 case。
- 跑应用是 T3 的槽（`:97`）；我只用了自己的 `:96`，已按 PID 收掉。

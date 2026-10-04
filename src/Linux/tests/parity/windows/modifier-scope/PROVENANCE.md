# U1 · 真机 oracle：`TextModifier` scope × `TextLineBreak` + 笔位恰在停靠位 + RTL 缩进钳位（53 例）

> 一趟出行做四件：① **`TextModifier` 的 `lbNull` 分离用例**（主项，卡住 #13 判据）、② **`pen` 恰好落在停靠位上**、
> ③ **RTL + `Indent>0` + `ParagraphIndent>0`**、④ 便宜项：**行首 `\t\t`**。
> **全部在远端真机完成**；本地只落盘 oracle 文件，未构建、未运行应用（`:97` 归 T3）。

## 1. 元组

| 项 | 值 |
|---|---|
| 机器 / 运行时 | `bilintu\pc`（Windows NT 10.0.22631.0）／ **.NET 10.0.7**，PresentationCore 10.0.0.0 |
| 测量 | `TextFormatter.Create().FormatLine(...)` 循环；**每行都取 `TextLine.GetTextLineBreak()`**，记录 null/非 null，并对返回对象做**反射转储** |
| 设置 | 同 `layout-b34`：`TextAlignment=Left`、`TextWrapping=Wrap`、`LineHeight=0`、`Tabs=null`、`DefaultIncrementalTab` 不覆盖；缩进按用例标注 |
| Dpi / emSize / interval | 96 / 24 / **96**（本 arm 的 `\t\t` 用例再次实测：tab1 到 96.000000、tab2 到 192.000000） |
| 字体 | **Arial 单字体**，覆盖本轮全部码点（拉丁 + 希伯来），`fontSha256` 逐用例内嵌、覆盖率表在 json `fonts` 段 |
| 样本总数 | **53 cases，id 全唯一**，`DETERMINISM=MATCH` |

### 合成标记字符（本 arm 的关键构造）

`TextModifier : TextRun`，由客户端 `TextSource.GetTextRun` **返回一个 TextModifier run** 来开启作用域，
由随后的 `TextEndOfSegment` run 关闭（与 WPF 自己 `TextSpanModifier`/`TextEndOfSegment` 的用法一致）。
因此每个作用域需要**两个"元素边缘"字符位**：

- `U+E000` → 该下标处 `GetTextRun` 返回 `TextModifier`（`Length = 1`，`Properties = null`，无字形无 advance）；
- `U+E001` → 该下标处返回 `TextEndOfSegment(1)`（关闭作用域，本身仍属旧作用域）。

这两个字符**从不作为文本返回**，所以它们占一个字符下标但不产生任何宽度。
每个用例都记录 `bufferWithMarkers`、`modifierOpenIndex`、`modifierCloseIndex` 与每行的 `[startChar,endCharExclusive)`，
所以"行下标区间 ↔ 可见文本"的映射是显式的、可核对的。
（RTL 段落里同构构造，已含 `A-rtl-scope-line0` 一组。）

## 2. ⭐ ① 主项：`TextLineBreak` 何时非 null

**结论：既不是 (i) 也不是 (ii) 的原样表述。实测规则是——**

> **非 null ⟺ 该行不是末行 ∧ 该行结束时 TextModifier 作用域仍处于打开状态**
> （即关闭用的 `TextEndOfSegment` 到该行结束为止**还没有被消费**）。

判据（逐字可核对，写进 json 的 `predicateThatFitsEveryLine`）：

```
nonNull(line) == (!line.isLastLine)
              && (modifierOpenIndex >= 0 && modifierOpenIndex < line.endCharExclusive)
              && (modifierCloseIndex < 0 || modifierCloseIndex >= line.endCharExclusive)
```

**99/99 行全部吻合**（6 组 × 3 宽度 + 对照）。

**两条候选规则各自被反例否掉：**

| 候选 | 反例（真机读数） |
|---|---|
| **(i) 段落级**：非 null ⟺ 有后续行 ∧ 段落带 TextModifier | `A-scope-line0` 的 **第 1..n 行**：段落确实带 TextModifier、每行都有后续行，但 break **全为 NULL** |
| **(ii) 行级（原样：该行与 scope 相交）** | `A-scope-line0` 的**第 0 行**（3 个宽度全中）与 `A-rtl-scope-line0` 第 0 行：该行**确实与 scope 相交**、也不是末行，但 break **为 NULL** —— 因为 scope 在**同一行内就关闭了** |

⇒ 对 T1d 的可操作表述：**`lbNull` 取 false 的条件不是"该行与某段 scope 相交"，而是"断点处 scope 仍打开"**。
这解释了为什么"scope 只覆盖首行"时**中间行全是 null**（`A` 组 15 行），
而"scope 覆盖末行"时**只有相交且未关闭的那一行**是 false（`B` 组：`line4/line3/line2` 分别非 null，末行仍 null）。

**对照与边界：**

| 组 | 构造 | break 序列（N=null，y=非 null） | 说明 |
|---|---|---|---|
| `A-scope-line0` | scope 开在 0、**在同一行内关闭** | `NNNNN` / `NNNN` / `NNN`（w80/100/140） | 段落有 modifier、非末行也全 null |
| `A-rtl-scope-line0` | 同上，RTL + 纯希伯来 | `NNN` / `NNN` / `NN` | **RTL 同构** |
| `B-scope-lastline` | scope 只覆盖**末行** | `NNNNyN` / `NNNyN` / `NNyN` | 只有"相交且未关闭"那一行非 null |
| `C-scope-whole` | scope 覆盖全段（从不关闭） | `yyyyyN` / `yyyyN` / `yyyN` | 所有非末行非 null，末行 null |
| `D-nomodifier` | **无 modifier** | `NNNNNN` / `NNNNN` / `NNNN` | 没有 modifier ⇒ 永远 null（含非末行） |
| `E-scope-oneline` | 有 modifier 但**单行**（无后续行） | `N` / `N` / `N` | 末行 ⇒ null |

**正向对照（证明 modifier 机制真的生效）**：`C2-scope-visible` 的 `ModifyProperties` 把 emSize **翻倍**：
w80 行数 **6 → 14**、最宽字符 advance **19.993333 → 39.983333** ⇒ 作用域确实作用到了几何上。

### ① 附带项：非 null 时 `TextLineBreak` 里装的是什么

**答案：装的是"最内层仍打开的那个 modifier 自己的起点"，而且它**没有**终点。**

- 转储显示 `TextLineBreak` 私有字段 `_currentScope`（`TextModifierScope`）与其内部属性 `TextModifierScope`；
- `TextModifierScope` 的成员只有 `_parentScope` / `_modifier` / `_cp` ——**没有任何 end/limit 字段** ⇒
  "该行相交的那一段的起止"**在对象里根本不存在**，能读到的只有起点；
- 该 `_cp`（`TextSourceCharacterIndex`）**等于客户端返回 TextModifier run 的那个字符下标**：
  `B` 组（scope 开在段落中部）⇒ **30**；`C`/`C2` 组（开在段首）⇒ **0**；**43/43 非 null break 全部满足**，`ParentScope` 全为 null；
- ⇒ 所以"是**该段自己的起点**还是**段落起点**"有了确定答案：**是 scope 自己的起点**（B 组给出 30 就是证据）。

**⚠️ 取不到（必须标注）**：这条**不在公开 API 上**。同一份真机输出里我让机器自己枚举了 API 面：

```
TextLineBreak 的公开实例成员 = { Void Dispose(), TextLineBreak Clone(), GetType, ToString, Equals, GetHashCode }
textLineBreakHasPublicScopeMember = false
TextModifierScope 类型可见性 = NON-public (internal) - not reachable from client code without reflection
```

⇒ 客户端**唯一受支持的用法**是把 `TextLineBreak` 对象整体传给下一次 `FormatLine`；**作用域内容只能靠非公开反射读**，
本 oracle 里那些值就是这么读的（json 中 `conclusion` 字段已如实标注）。**T1d 不应依赖它。**

## 3. ② 笔位恰好落在停靠位上 ⇒ **前进整整一个 interval**（不是 0）

**结论：`stop = (floor(pen/interval) + 1) × interval`，即停靠位是"严格大于笔位"的最小整数倍。**

这**修正了上一轮 `tab-anchor` 里"最小的 `k*interval ≥ pen`"的措辞** —— 上一轮所有样本的笔位都不在停靠位上，
两种写法都能拟合；本 arm 把它们分开了。`pen = 0` 时两种写法同解（=96），所以旧结论不受影响。

| 用例 | 构造 | tab 的 box 跨度 | advance | 笔位恰在停靠位？ |
|---|---|---|---|---|
| `two-tabs@LTR` | 两个相邻 tab | `[0,96]` / **[96,192]** | 96 / **96** | tab2 是 |
| `c8-tab@LTR` | 8×`c` = **96.000000** 整 | **[96,192]** | **96** | 是 |
| `c6-tab-ind24@LTR` | Indent24 + 6×`c` = **96.000000** 整 | **[96,192]** | **96** | 是 |
| `two-tabs-rtl@RTL` | 两个相邻 tab | `[0,96]` / **[96,192]** | 96 / **96** | tab2 是 |
| `he-then-two-tabs@RTL` | `א` + 两个 tab | `[13.513333,96]` / **[96,192]** | 96 | tab2 是 |
| `c7-tab`（对照） | 7×`c` = 84 | `[84,96]` | 12 | 否（stop 96） |
| `c9-tab`（对照） | 9×`c` = 108 | `[108,192]` | 84 | 否（stop 192） |
| `c7-tab-ind24`（对照） | 24 + 84 = 108 | `[108,192]` | 84 | 否 |

**7 个"笔位恰在停靠位"的样本全部前进 96（一个 interval），没有一个前进 0**（LTR 5 + RTL 2）。
构造方式有两种（相邻 tab 到达停靠位；以及 `c` 的 advance 恰为 12.000000 使前缀精确等于 96），
所以结论不依赖单一字体度量；两侧还各配了 84→96、108→192 的标定样本。

## 4. ③ RTL + `Indent>0` + `ParagraphIndent>0`：闭式公式**成立**

`Indent=24`、`ParagraphIndent ∈ {24,48}`、RTL、纯希伯来，宽度 60/100/140：

| 用例 | 容器 | 行框宽 = C−pInd | tab 的 box 跨度 | tab 的 device 跨度 | 预测 `[0, C−pInd−Indent]` | 判定 |
|---|---|---|---|---|---|---|
| `he-lead-tab@w60@i24p24` | 60 | 36 | `[24,36]` | **[0, 12]** | `[0,12]` | 钳满 ✓ |
| `he-lead-tab@w100@i24p24` | 100 | 76 | `[24,76]` | **[0, 52]** | `[0,52]` | 钳满 ✓ |
| `he-lead-tab@w100@i24p48` | 100 | 52 | `[24,52]` | **[0, 28]** | `[0,28]` | 钳满 ✓ |
| `he-lead-tab@w140@i24p48` | 140 | 92 | `[24,92]` | **[0, 68]** | `[0,68]` | 钳满 ✓ |
| `he-mid-tab@w60/w100@i24p24`、`@w100/w140@i24p48` | 同上 | 同上 | 同上 | 同上 | 同上 | 钳满 ✓（先在 tab 前断行，tab 落到下一行行首再钳满） |
| `he-lead-tab@w60@i24p48` | 60 | 12 | `[24,24]` | `[0, 0]` | `[0,−12]` | **退化**：闭式为负 ⇒ **零宽 + `HasOverflowed=true`** ✓ |
| `he-mid-tab@w60@i24p48` | 60 | 12 | `[24,24]` | `[0, 0]` | `[0,−12]` | 退化 ✓ |
| `he-lead-tab@w140@i24p24` | 140 | 116 | `[24,96]` | `[13.513333, 85.513333]` | —（自然） | **自然**（96 ≤ 116），停靠位仍 = 1×96 ✓ |

⇒ 8 条钳满样本**全部**满足闭式；2 条退化为零宽并溢出（与 `tab-anchor` 在 LTR 上看到的退化族一致）；
2 条自然样本作为对照。**公式在 RTL 三属性同时非零时成立。**

## 5. ④ 行首 `\t\t`：每个 tab **各占一行**、各自钳满；不合并、不零宽

| 用例 | 容器 | Indent | 行序列（每行 tab 的 raw 跨度） |
|---|---|---|---|
| `two-tabs-ltr@w40@i0` | 40 | 0 | L0 `[0,40]` ／ L1 `[0,40]` ／ L2 `b` |
| `two-tabs-ltr@w40@i24` | 40 | 24 | L0 `[24,40]` ／ L1 `[24,40]` ／ L2 `b` |
| `two-tabs-ltr@w80@i0/@i24` | 80 | 0/24 | L0 `[0,80]`／`[24,80]`，L1 同，L2 `b` |
| `two-tabs-ltr@w100@i0/@i24` | 100 | 0/24 | L0 `[0,96]`／`[24,96]`，L1 同，L2 `b` |
| `two-tabs-rtl@w40/w80/w100@i0/@i24` | — | — | 同构 ✓ |

⇒ **没有一行同时装两个 tab**（`anyLineCarryingBothTabs = false`）、**没有零宽 tab**、**没有空行**；
w40/80 时每个 tab 都是钳满整行（`everyClampedTabFillsItsBox = true`，16 行），
w100 时每个 tab 是"自然到达 96"（`everyNaturalTabReachesTheNaturalStop = true`，8 行）—— **即使不钳位，也是一 tab 一行**。
这正是"循环能终止"的边界：**每个 tab 结束它所在的行**。

## 6. 产物与复现

| 文件 | 说明 |
|---|---|
| `out/modifier-scope-raw.json` | **真机原始输出，未经修改**（53 cases，sha256 `6818b4783061cda3e13895b40c0a47cf42ed7b3fca8ba8a3c032523e12453232`） |
| `out/modifier-scope-raw.txt` | 同上人读版 |
| `out/modifier-scope-oracle.json` | **推导产物**（`cases` 原样内嵌 + `model` / `answers` / `unavailableOrUntested`） |
| `out/modifier-scope-oracle.txt` | 同上人读版 |
| `analyze.py` | 推导脚本（入库可复跑）：`python3 analyze.py out/modifier-scope-raw.json out/modifier-scope-oracle` |
| `src/Program.cs` `src/ModifierScope.csproj` `src/run.ps1` | 真机测量程序；`run.ps1` 跑两遍 + 规范化 sha256 比对**确定性**，并**逐个文件打印 SHA256** |

本轮 `DETERMINISM=MATCH`（`A=e1878e807eb7f0fd B=e1878e807eb7f0fd`），`cases: 53`，
两个输出文件的 sha256 由 `run.ps1` 打印、**回传后逐个复核一致**（见 §8 的教训）。

## 7. API 契约来源（**用于写出可编译的程序**，不是答案来源）

为了让程序能编译并正确构造 run 序列，我读了 `upstream/wpf/.../PresentationCore` 下的**公开 API 定义**：
`TextModifier.cs` / `TextModifierScope.cs` / `TextEndOfSegment.cs` / `TextRun.cs` / `ref/PresentationCore.cs`，
以及 `PresentationFramework` 里 WPF 自己的客户端用法 `TextSpanModifier.cs` / `LineBase.cs`（用它确认
"modifier run 的长度取合成边缘字符长度、`Properties` 返回 null、由 `TextEndOfSegment` 关闭"这一**用法**）。
**上面所有结论都来自真机读数**；程序里**没有任何**"照着实现推断答案"的分支，
`analyze.py` 也只比较"预测 vs 实测"。上游 `upstream/` 只读未改。

## 8. 自我纠错 / 纪律固化（3 条）

1. **scp 双源漏传（上一轮教训，本轮已固化）**：`run.ps1` 现在**逐个输出文件打印 SHA256**，
   我这边**每个文件单独 scp**并**逐个复核 sha**；本轮两个文件 sha 与真机打印值逐位相符。
   （`tab-anchor` 那轮就是因为一次 scp 传两个远端源、只传回第一个，导致 `raw.txt` 一度陈旧。）
2. **`analyze.py` 两处判读缺陷（我自己的，已修）**：
   (a) 反射转储把整数渲染成字符串，我拿 `"30" != 30` 去比 ⇒ 误报"全部不匹配"；
   (b) "是否存在 end/limit 字段"的探针用子串 `"nd"` 匹配，命中了 `TextSourceCharacterIndex` 里的 "nd" ⇒ 误报存在。
   两处都改成按字段名精确判定后复跑，结论为**起点 43/43 相符、无 end/limit 字段**。
3. **口径修正（跨轮）**：`tab-anchor` 写的自然停靠位"最小 `k*interval ≥ pen`"应为**严格大于**（见 §3），
   已在本文件与 `modifier-scope-oracle.json` 的 `model` 段写明；旧结论在 `pen` 不在停靠位上时不受影响。

## 9. 取不到 / 未覆盖（无信息就报无信息）

- **`TextLineBreak` 携带的 scope 不在公开 API 上**（`TextLineBreak` 公开面只有 `Dispose`/`Clone`，
  `TextModifierScope` 是 internal）——那些值是**非公开反射**读出来的，客户端不可依赖；
- scope 对象**没有 end/limit 字段** ⇒ "该行相交的 scope 起止"**在对象里根本不存在**，取不到；
- **嵌套 modifier**（同一次断点上有两层 scope）**未测**：本 arm 全部样本 `ParentScope = null`；
- `HasDirectionalEmbedding = true` 的 modifier（即 `TextSpanModifier` 的 bidi 嵌入用法）**未测**；
- `TextTrimming` 无该成员（只报 `HasOverflowed`）；`Tabs` 非 null **仍未测**；`NoWrap`/`WrapWithOverflow` **未测**；
- 两个合成标记字符各占一个字符下标（无字形、无 advance），所有字符下标**含**它们，每行都给了区间与标记位置以便换算；
- `breakCause` 是**推导值**（WPF 不暴露断行原因）。

## 10. 合规与清理

真机**只读**（未装软件、未改工程配置、未动他人文件）；**本地零构建零应用**；未跑 `integration-wave.sh`；
只写 `tests/parity/windows/modifier-scope/**`；未碰 `src/`、`build/`、`samples/`、
`tests/parity/{linux,geometry}/`、`tests/golden/`、`docs/unimplemented.md`、`verify-all.sh`、`upstream/`（只读）、`handoff.md`。

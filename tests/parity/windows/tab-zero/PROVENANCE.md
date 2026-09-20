# U1 · 真机 oracle：`DefaultIncrementalTab = 0` 臂（86 例）

> 供 T1d 判定"21 例不一致"的归属。**形状沿用 `tests/parity/windows/tab/`，只改一个输入。**
> **全部在远端真机完成**（本地只落盘 oracle 文件，未跑应用、未构建）。
> 停止点参照：桥 `759a322431f1e457`｜PC `6be29475b6aeb34e`｜PF `50da85138a7bc3e8`｜shim `e1bc947afc248b32`

## 1. 元组
| 项 | 值 |
|---|---|
| 机器 / 运行时 | `bilintu\pc`（Win11 23H2 22631）／ **.NET 10.0.7**，PresentationCore 10.0.0.0 |
| 测量 | `TextFormatter.Create().FormatLine(...)`，**按 `TextLine.GetTextLineBreak()` 循环到段末**（所以给的是**整段每一行**，不是只有第一行） |
| **设置** | 与 `layout-b34/src/LayoutOracle/TextModel.cs` 完全一致：`TextAlignment=Left`、**`TextWrapping=Wrap`**、`LineHeight=0`（自然）、`FirstLineInParagraph=true`、`Indent=0`、`ParagraphIndent=0`、`AlwaysCollapsible=false`、`Tabs=null`、`TextDecorations=null`、`TextMarkerProperties=null`；**唯一变化 = `DefaultIncrementalTab`**：`tab0` 臂 = **0**，`default` 臂 = 不覆盖（WPF 默认） |
| Dpi / emSize | 96；**24** 为主，另扫 **12 / 48** |
| 宽度 | **40 / 80 / 160 / 320** DIP |
| 方向 | **LTR 与 RTL 各跑** |
| 字体 | **Arial**，`file:///C:/WINDOWS/FONTS/ARIAL.TTF`，**sha256 `baa251526d6862712a58e613ef451d8a2b60482142ec6aab1d47fb8e23e21a7c`**（逐码点覆盖验证；`\t` 是控制字符无字形，已排除） |
| 文本 | `abc def`（**控制组**）、`a\tb`、`\ta`、`a\t`、`a\t\tb`、`\t\t`、**`a\tb\t\tc\td`（= T1d `'tabs'` 用例的原文，逐字符一致）** |

## 2. ⭐ 两个 arm 的对比（同文本、同宽度的并排读数）

### A. tab=0 臂 · T1d 原文本 `a\tb\t\tc\td`
### A. tab=0 臂 · T1d 原文本 `a\tb\t\tc\td`

| 用例 | 行数 | 行（起始,结束）| trailWs | 行宽 | 行内文本 |
|---|---|---|---|---|---|
| `b34-tabs@w40@em24@LTR@tab0` | 2 | [0,6) | 0 | 38.703 | `a\tb\t\tc` |
| `b34-tabs@w40@em24@LTR@tab0` | 2 | [6,8) | 1 | 13.350 | `\td` |
| `b34-tabs@w80@em24@LTR@tab0` | 1 | [0,8) | 1 | 52.053 | `a\tb\t\tc\td` |
| `b34-tabs@w160@em24@LTR@tab0` | 1 | [0,8) | 1 | 52.053 | `a\tb\t\tc\td` |
| `b34-tabs@w40@em24@RTL@tab0` | 2 | [0,6) | 0 | 38.703 | `a\tb\t\tc` |
| `b34-tabs@w40@em24@RTL@tab0` | 2 | [6,8) | 1 | 13.350 | `\td` |
| `b34-tabs@w80@em24@RTL@tab0` | 1 | [0,8) | 1 | 52.053 | `a\tb\t\tc\td` |
### B. tab=0 臂 · 单/连排/首/尾 Tab（w=40）
### B. tab=0 臂 · 单/连排/首/尾 Tab（w=40）

| 用例 | 行数 | 行（起始,结束）| trailWs | 行宽 | 行内文本 |
|---|---|---|---|---|---|
| `notab-control@w40@em24@LTR@tab0` | 2 | [0,4) | 1 | 38.693 | `abc ` |
| `notab-control@w40@em24@LTR@tab0` | 2 | [4,7) | 1 | 33.360 | `def` |
| `tab-single@w40@em24@LTR@tab0` | 1 | [0,3) | 1 | 26.697 | `a\tb` |
| `tab-head@w40@em24@LTR@tab0` | 1 | [0,2) | 1 | 13.350 | `\ta` |
| `tab-tail@w40@em24@LTR@tab0` | 1 | [0,2) | 1 | 13.350 | `a\t` |
| `tab-adjacent@w40@em24@LTR@tab0` | 1 | [0,4) | 1 | 26.700 | `a\t\tb` |
| `tab-only@w40@em24@LTR@tab0` | 1 | [0,2) | 1 | 0.007 | `\t\t` |
### C. default 臂（同文本并排，DefaultIncrementalTab 不覆盖）
### C. default 臂（同文本并排，DefaultIncrementalTab 不覆盖）

| 用例 | 行数 | 行（起始,结束）| trailWs | 行宽 | 行内文本 |
|---|---|---|---|---|---|
| `b34-tabs@w80@em24@LTR@default` | 8 | [0,1) | 0 | 13.347 | `a` |
| `b34-tabs@w80@em24@LTR@default` | 8 | [1,2) | 0 | 80.000 | `\t` |
| `b34-tabs@w80@em24@LTR@default` | 8 | [2,3) | 0 | 13.347 | `b` |
| `b34-tabs@w80@em24@LTR@default` | 8 | [3,4) | 0 | 80.000 | `\t` |
| `b34-tabs@w80@em24@LTR@default` | 8 | [4,5) | 0 | 80.000 | `\t` |
| `b34-tabs@w80@em24@LTR@default` | 8 | [5,6) | 0 | 12.000 | `c` |
| `b34-tabs@w80@em24@LTR@default` | 8 | [6,7) | 0 | 80.000 | `\t` |
| `b34-tabs@w80@em24@LTR@default` | 8 | [7,8) | 1 | 13.347 | `d` |
| `b34-tabs@w160@em24@LTR@default` | 4 | [0,3) | 0 | 109.347 | `a\tb` |
| `b34-tabs@w160@em24@LTR@default` | 4 | [3,4) | 0 | 96.000 | `\t` |
| `b34-tabs@w160@em24@LTR@default` | 4 | [4,6) | 0 | 108.000 | `\tc` |
| `b34-tabs@w160@em24@LTR@default` | 4 | [6,8) | 1 | 109.347 | `\td` |
| `tab-only@w80@em24@LTR@default` | 2 | [0,1) | 0 | 80.000 | `\t` |
| `tab-only@w80@em24@LTR@default` | 2 | [1,2) | 1 | 80.000 | `\t` |
### D. tab=0 臂的逐字 x（`b34-tabs@w40@LTR@tab0` 第 1 行）

`a@0.000 \t@13.347 b@13.350 \t@26.697 \t@26.700 c@26.703`

（每个 Tab 的 `width` ≈ **0.003 DIP**，即推进量 0）

**对比读法（这两张表就是 T1d 需要的"并排"）**：
* **tab=0**：`a\tb\t\tc\td` 在 w=40 只断成 **2 行**，断点在**第 8 个字符（一个 Tab）之前**，第 2 行以 **Tab 开头**；
  行宽 38.703 / 13.350。
* **default**：同一文本在 w=80 断成 **8 行**、w=160 断成 **4 行** —— 因为默认间隔是 **96 DIP**（=4×emSize），
  而容器只有 80/160，**每个 Tab 都要独占一行**（那几行的行宽正好是 80.000 / 96.000 / 108.000）。
  这就是"0 配置"与"默认配置"在同一文本上的**断行数量差异（2 行 vs 8 行）**。

## 3. 能对拍的关键读数（每例都有）
* **逐行** `startChar` / `endCharExclusive` / `lengthWithNewline` / `dependentLength` / `newlineLength` /
  **`trailingWhitespaceLength`** / `width` / **`widthIncludingTrailingWhitespace`** / `height` / `baseline` /
  `hasOverflowed` / `lineText` / `paragraphStartOffsetDip`；
* **逐字** `xFromLeftDip`（归一化，RTL 也正确）+ `width` + `flowDirection`（含 `\t` 自身）；
* 段落级 `lineCount` / `tabCount`。

**tab=0 的推进量实证**：`b34-tabs@w40@LTR@tab0` 第 1 行逐字 x 里每个 Tab 的 `width` ≈ **0.003 DIP**
（`a`@0 → `\t`@13.347 → `b`@13.350 → `\t`@26.697 → `\t`@26.700 → `c`@26.703），即**推进量 0** ✓
与 T1d"0 ⇒ 每个 Tab 推进 0"的理解一致。
`\t\t` 单行在 tab=0 下整行宽 **0.007** ✓。

## 4. ⚠️ 两项"取不到"（不造读数）
1. **断点原因**：**WPF 不提供**。`TextFormatter`/`TextLine` 没有任何"为什么在这里断"的 API。
   本 oracle 的 `lines[].breakCause` 是**推导值**（看断点两侧的字符）：`before-tab` / `after-tab` /
   `at-space` / `explicit-newline` / `mid-token` / `end-of-text`，字段里带 `breakCauseNote` 标明是推导。
2. **`TextTrimming`（CharacterEllipsis）**：**`TextFormatter` 层没有这个能力** —— 核对上游
   `PresentationCore/.../textformatting/TextParagraphProperties.cs`，其成员是
   `FlowDirection / TextAlignment / LineHeight / FirstLineInParagraph / AlwaysCollapsible / DefaultTextRunProperties /
   TextDecorations / TextWrapping / TextMarkerProperties / Indent / ParagraphIndent / DefaultIncrementalTab / Tabs / Hyphenator`，
   **没有 `Trimming`**。修剪是**框架层（TextBlock）**依据 **`TextLine.HasOverflowed`** 做的决定
   （T1d 也这么记的）⇒ 本 oracle **把修剪判据所需要的量全部给全了**（逐行 `hasOverflowed` /
   `width` / `WITW` / 逐字 x），**但没有"修剪后"的真值**，因为 TextFormatter 里不存在这种布局。

## 5. 可复算
```powershell
cd C:\u1-shaping\src\TabZeroOracle
dotnet build
powershell -File C:\Windows\Temp\run.ps1     # 打印 EXITCODE / stdout / stderr / 产物大小
# 产物： C:\u1-shaping\out-tabzero\tab-zero-oracle.{json,txt}
```
源码同步在 `src/`。除 `generatedUtc` 外输出确定。真机只读（未装东西/未改配置/未动他人文件），`C:\u1-shaping\` 已清理。

## 6. 踩到的坑（对后来者有用，已修）
**`TextLine.Start` 是 `double`，语义是"从段首到行首的距离（DIP）"，不是字符下标。**
我第一版写 `(int)line.Start` 当行起始下标用，编译通过、运行不报错，但**每一行都被切片成第 0 行**，
于是"折行点/行文本"整列是错的（表现为多行全部显示同一段文本）。
修法：**行的字符下标自己用 `FormatLine` 的第一参数累加维护**（`index += line.Length`），
`line.Start` 只当"段首偏移"记录在 `paragraphStartOffsetDip` 里。
⇒ 这条值得 T1d 也自查：任何用 `TextLine.Start` 当字符索引的地方都会静默错位。

## 7. 能对拍 / 不能对拍
**能对拍**：tab=0 与 default 两臂的逐行断点（`startChar/endCharExclusive`）、逐行 `trailingWhitespaceLength`、
`width`/`WITW`、`hasOverflowed`、逐字 `xFromLeftDip`/`width`、`lineCount`、`tabCount`、以及"Tab 推进量为 0"这一事实。
**不能对拍/未覆盖**：
1. **断点原因**：WPF 无此 API（§4.1），只有推导值；
2. **修剪后的布局**：TextFormatter 无 Trimming（§4.2）；
3. **显式自定义停靠位（`Tabs` 非 null）未测** —— 只测了 `Tabs=null` + `DefaultIncrementalTab∈{0,默认}`；
4. `TextWrapping` 只测了 `Wrap`（T1d 的 `NoWrap`/`WrapWithOverflow` 组合未测）；
5. `TextTrimming` 三档、`MaxLines`/`AlwaysCollapsible` 交互未测（属框架层）；
6. 字体固定 Arial（换字体需重跑）；真值只代表 `TextFormatter` 这一层。

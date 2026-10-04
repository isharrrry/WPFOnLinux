# T1d：Tab 口径实现（源已定）+ M_modifier 判定（2026-09-13）

> **源已定**：`build/shims/PresentationCore.HbTextLine.cs` = `8a878be0c1ee558d0b6617ed26538e414f53498ed750b7fe1eee2065f0743fb9`
> 本轮**没跑应用、没发桥、没重建 PC**；`src/**`、`samples/**`、`build/*.Linux/**`、别人的 `build/MilBridge/**`、`CoverageProbe/refs/**` 都没动。

---

## 一、Tab 口径：已实现（规则 A/B/C），离线对拍 57/57 全绿、牙已验证

### 1.1 实现（都在我文件里，`file:line`）
| 位置 | 内容 |
|---|---|
| `HbShaper.ApplyTabStops(r, text, font, startPenX, tabInterval)` `:304` | `\t` 的 advance = **前进到严格大于当前笔位的下一个网格倍数**；`tabInterval <= 0` ⇒ 显式"无停靠位"（advance 0）；顺带把无字形的控制字符换成 space 字形（去掉豆腐块） |
| `Shape(...)` `:276` | 先用**框架默认** `4 × em` 填一次（`FormatLine` 随后按真值覆盖，函数**幂等**） |
| `HbMultiFontShaper.ShapeParagraph(..., startPenX, tabInterval)` `:522-560` | 多面路径：**逐段**用"本段起点相对行原点的笔位"重算（这是多段时唯一算得对的地方），并在补算后再累加笔位 |
| `FormatLine(..., indentDip, defaultIncrementalTab)` `:2389-2406` | 解析 `tabInterval`（`NaN` ⇒ 框架默认 `4×em`）；单面路径按 `indentDip` 重算；`witw = Σadvance + indentDip` |
| 行内容起点 | 单面 `BuildGlyphRun(..., originX: startPenX, ...)`；多面 `double pen = startPenX`；`_startPenX` 进 `AdvanceBefore`（⇒ `GetTextBounds` 的 x 含 Indent） |
| `FormatParagraph(..., indentDip = 0, defaultIncrementalTab = NaN)` `:3295` | 新增两个**可选**参数（放在可选尾巴最后 ⇒ 所有既有调用点零改动）；`indentDip` **只作用首行** |

**规则映射**：A = `TextParagraphProperties.DefaultIncrementalTab` 的**框架默认**（`TextParagraphProperties.cs:111-114`：`4 * DefaultTextRunProperties.FontRenderingEmSize` ⇒ 12→48/24→96/48→192 ✓）；
B = 网格锚在**行原点**（笔位从 0 起算，Indent 只改内容起点 ⇒ `a\tb`+Indent=24 停靠位仍是 96 ✓）；
C = **方向无关**：RTL 的"锚右边缘/向左前进"由宿主那次镜像完成（修法② 契约）⇒ 内部一律"从行原点向右"✓。

### 1.2 离线对拍（我探针的新档：`--tab-oracle <json>`，装置自证、不是应用读数）
字体用 **Liberation Sans**（Arial 度量兼容替身）；逐字比 `xFromLeftDip`（RTL 用 `P − 内部右缘` 归一化）；容差 0.01 DIP：
```
TAB_ORACLE: cases=114 pass=57 fail=0  跳过(bidi 依赖，纯拉丁+RTL 段落)=57
            无 GetTextBounds 的字符=0（其中 tab=0）  最大逐字差=0.0053 @no-tab@w40@LTR i=6[f]
```
- **57 例全绿**含 em 12/24/48、四档宽度、`Indent 0/24/48`、含 tab 的各类（`tab-mid/tab-head/tab-tail/tab-two-mid/aTbTc`…）✓
- **被跳过的 57 例**：`flowDirection=RightToLeft` 且**内容是纯拉丁**（`'ab'`/`'abc def'`/`'a\tb\tc'`）⇒ 其内部顺序由 **bidi** 决定（§8.7 射程外）⇒ **RTL 的 Tab 规则在这批 oracle 上无法离线验证**（U1 的 note 也说"未覆盖 Tab 夹在希伯来/阿拉伯文之间"）⇒ **缺的读数**：一个"含希伯来/阿拉伯内容的 `\t` 串"在 RTL 段落下的真机读数。
- **牙**：把框架默认改成 `3 × em`（`/tmp` 变体，不动真源）⇒ `pass=10 fail=47`，差值正是预期的 `96→72`、`384→288`（em=48）⇒ **能红** ✓；还原真源后重新构建 ✓。

### 1.3 ⚠️ 需要 T1b 配合的 1 行（否则六项会动 —— 这是**旧语料的构造假象**，不是回归）
`layout-b34` 那套 Windows harness 把 `DefaultIncrementalTab` **写死成 0**（`tests/parity/windows/layout-b34/src/LayoutOracle/TextModel.cs:167`）⇒ 那 **34 例的真值是"无停靠位"（0 宽）**，而我们实现的是框架默认 `4×em` ⇒ 现在对不上：
```
T2c Tab 可比例 34 例，其中不一致 25 例（家族：A1_tabs,B_tabs,B_tabs_trim,F_tabs）   ← 改前是 0
通过 18 / 失败 4（改前 20/2）；T2 记账 1263/1298（改前 1286，③行尾空白 963/988）
T2b 用例级 200/213（改前 213/213）；T2d Extent 1250（改前 1260）；T3 明细 210/236（改前 218）
```
**隔离已证**：新增的全部不一致用例 id **都在 tabs 家族**（无任何非 tab 家族）⇒ 改动只碰 Tab。
**修法（T1b 车道 1 行）**：`HbTextLineParity` 调 `FormatParagraph` 时把 `defaultIncrementalTab: 0` 传下去（对应旧语料），新 oracle 那批用默认（`NaN`）⇒ 两边同时绿。参数已经暴露好（`:3295`）。
（另：主控上一条说"WPF 公开 API 没有自定义停靠位"**不准确** —— `TextParagraphProperties.DefaultIncrementalTab`（`:111`）与 `Tabs`/`TextTabProperties`（`:120`）就是公开 API；本实现只用默认口径，`Tabs` 未做。）

---

## 二、M_modifier 判定：**7 条宽度行 = 1 个根**；4 条 Extent 行**同根**；做的话需要跨车道 2-4 行透传

### 2.1 `TextModifier` 语义（上游 + oracle 实证）
`TextModifier` = **零长度 run**，管住它 scope 内所有 run 的属性（`ModifyProperties`）并可声明方向嵌入（`HasDirectionalEmbedding`/`FlowDirection`），scope 到配对的 `TextEndOfSegment` 或 `TextEndOfParagraph` 为止（`TextModifier.cs:15-46`）。
**但 oracle 的 modifier 是恒等变换**：`OracleModifier.ModifyProperties(TextRunProperties p) => p;`（`tests/parity/windows/layout-b34/src/LayoutOracle/TextModel.cs:63`）+ `HasDirectionalEmbedding => false`（`:64`）
⇒ **它不改属性、不改方向**；唯一效果是**结构**：scope `[6,45)` 变成**零 advance 的占位**，且**仍计入 `len`**。

### 2.2 证据（真值原文）
`M_modifier_*`：`fontSize=16`、`fontKey=file`、`alwaysCollapsible=true`、文本 = 63 字符拉丁句；`modifierStart=6, modifierEnd=45`（`Cases.cs:288-303`）。
真机 `M_modifier_winf 行#0`：`len=63`、`w=156.9167`、`runs=[[0,6,0,45.9667],[45,17,45.9667,110.95]]`、`ext=18.0`
⇒ 两个 run 只覆盖 **23 个字符**（`[0,6)` + `[45,62)`），中间的 39 字符**零宽不出图**，`len` 仍是 63。
我们：`w=439.1360` ⇒ 差 **282.2193** = 那 39 字符在 em16 下的宽度 ✓（`439.1360 − 156.9167 = 282.2193` 逐位对得上）。

### 2.3 为什么 7 条宽度行**全部**由"`TextModifier` 未实现"解释 ✓
| 用例 | 行 | 真值宽 | 我们宽 | 差 | 归因 |
|---|---|---|---|---|---|
| `M_modifier_winf` | #0 | 156.9167 | 439.1360 | **282.2193** | 39 个 scope 字符被我们按正常 advance 排了 |
| `M_modifier_w320` | #0 | 156.9167 | 314.1280 | 157.2113 | 同上（宽度约束下我们仍在同一行） |
| `M_modifier_w200` | #0 | 156.9167 | 185.3760 | 28.4593 | 同上 |
| `M_modifier_w120` | #0/#1 | 115.69 / 37.0667 | 88.88 / 92.336 | 26.81 / 55.2693 | 折行点被 scope 的零宽改变 ⇒ 行边界不同 |
| `M_modifier_w80` | #0/#1 | 74.5733 / 78.1833 | 41.808 / 42.912 | 32.7653 / 35.2713 | 同上 |
**预测（修后应变成什么）**：`w200/w320/winf 行#0` ⇒ **W=156.9167、len=63、Extent=18.0**；`w120` ⇒ 两行 `115.6900 / 37.0667`；`w80` ⇒ `74.5733 / 78.1833`。
**怎么判**：`build/MilBridge/gen/t2d-width-diff.txt` 里 `grep M_modifier` 那 7 行全部消失（或差 < 0.34 DIP），且 `Len` 恢复 `50/63`（行账那 6 条）。

### 2.4 4 条 Extent 行与 7 条宽度行：**同一根** ✓
`M_modifier_w80/w120 行#1` 真值 18.0000 vs 我们 14.3200；`w320/winf 行#0` 真值 18.0000 vs 我们 18.0800。
行内容不同（我们少了"scope 零宽"这件事）⇒ 墨迹盒自然不同：修好 scope 之后**行 = 同样的 23 个可见字符** ⇒ Extent 应回到 18.0（+0.08 那条的余量属于墨迹/度量末位，届时按 0.01 容差判）。
⇒ 之前登记的"4 条 Extent 余差全落在 M_modifier"与"7 条宽度行"**是同一根**，不是两根 ✓

### 2.5 现在**做不到**的地方（跨车道，必须先透传 scope）
- harness 直接调 `FormatParagraph(text, …, hasModifierScope) **（平文本 + 一个 bool）**`（`HbTextLineParity/Program.cs:302`）⇒ **scope 区间没传下来**；
- 拦截层 `CollectLenient`（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:101-166`）**只取第一个 run 的 `Properties`**（`:129-132`），并把所有 run 的字符**平铺**成一个字符串（`:146-154` 只把非 `TextCharacters` 计数）⇒ 即便源里有 `TextModifier`，shim 也拿不到它的 `[start,end)`；
- shim 侧只有 `_hasModifierScope`（bool，`PresentationCore.HbTextLine.cs:2229/2280`），只用于 `GetTextLineBreak` 语义（`:2949-2959`）⇒ **无法表达"这段占位零宽但仍计入 len"**。

**最小落地路径（建议本波之后单独一趟，或主控裁决后并波）**：
1. shim 侧（我）：`FormatParagraph` 再加可选 `modifierStart = -1, modifierEnd = -1`；shape 后把 scope 内字符的 advance 置 0、**移除其字形**（保证不出墨）、`Length` 记账不变 ⇒ 预计正好给出 156.9167/18.0。
2. harness 侧（T1b，1 行）：把 `modifierStart/modifierEnd` 从 case meta 传下去（meta 里本来就有，`Cases.cs:70`）。
3. 应用侧（PC 车道，2-3 行）：`CollectLenient` 遇到 `TextModifier` run 时记录 scope 并透传。

### 2.6 应用可见性（**别放过，也别夸大**）
- 触发条件 = 源里有 `TextModifier` run ⇒ WPF 里那是 **IME/合成（`TextStore`/TextBox）** 场景；我们样例的 RTL/文本块都是 `TextBlock.Text`（无 modifier）⇒ **当前样例不可观测** ✓
- 所以它是**正确性欠账**（真机口径对不上、离线的 7 行红），**不是**用户今天能看见的缺陷；一旦有人用 TextBox + 输入法，就会看到 scope 段落宽度/折行不对。

### 2.7 建议（按新证据复核后）
- **做**，但**不与 Tab 同波**：它需要 2 个车道的 3-4 行透传（harness 1 行 + 拦截层 2-3 行），而 shim 侧我可以先做（默认 `-1/‑1` ⇒ 对既有调用**零影响**，可 A/B 证明）。
- 判据（做完）：`t2d-width-diff.txt` 里 `M_modifier` 7 行消失 + 行账 6 条 `Len` 恢复 + `Extent` 那 4 条回到 18.0；红旗：宽度凑对了但 `Baseline/Height` 变了、或 `ClusterMap` 契约破（scope 字符的 cluster 仍须可映射）。

---

## 三、Tab 收口清单（U1 `tab-zero` arm 已到，**本轮只读、未写 shim**；等主控"#9 已冻、可以动"）

### 3.1 U1 点名自查：`TextLine.Start` 误用 ⇒ **我车道内没有**
`TextLine.Start` 是 `double`（"段首到行首的距离 DIP"），**不是字符下标**。自查结论：
- **我的探针**（`build/MilBridge/tests/CoverageProbe/Program.cs`）：全文**没有任何** `TextLine.Start` 的引用；行起点只有两个来源 ——
  ① `hb.LineStartForDiag`（shim 自己的诊断属性 = **真实字符下标**，`:329`）；② 逐行累加 `cpFirst += hb.Length`（`:424`）✓
- **T1b 的 harness**：`Program.cs:196` 已注明"行起点只能靠累加 Length 得到（真机实测 `TextLine.Start` 恒 0）"⇒ 也是累加 `Length` ✓
⇒ 这一类静默错位在我这条链路上不存在 ✓（新档 `--tab-oracle` 用的是 oracle 的 `perChar[].i` = 字符下标，也与 `Start` 无关 ✓）

### 3.2 tab0 臂 = **推进 0**（确认）+ 折行对照物（原文）
`b34-tabs@w40@em24@LTR@tab0`（文本 `a\tb\t\tc\td`）：**2 行**
```
行#0 start=0 end=6 nl=0 tws=0 dep=2 w=38.7033 cause=before-tab text='a\tb\t\tc'
     perChar: a@0(13.3467) \t@13.3467(**0**) b@13.35 \t@26.6967(**0**) \t@26.7(**0**) c@26.7033(12)
行#1 start=6 end=8 nl=1 tws=1 dep=0 w=13.3500 cause=end-of-text text='\td'   ← 第 2 行**以 Tab 开头**
b34-tabs@w80/w160@tab0：**1 行** w=**52.0533**（8 字符全在一行，tab 全 0）
b34-tabs@w160@em12 →26.0333；@em48 →104.1033
```
⇒ ① `DefaultIncrementalTab=0` ⇒ **每个 Tab 推进 0**（我的 `tabInterval <= 0` 支路**语义正确** ✓）；
② 折行点是"**Tab 之前**"（`cause=before-tab`，把 `\t` 推到下一行行首）⇒ 与我 `OverlayTabs`（break-before-tab）**一致** ✓；
③ 行尾空白：以 `c` 结尾的行 `tws=0`、末行 `tws=1`（EOP）⇒ **`\t` 不算行尾空白** ✓ 与我的 `IsTrailingWhitespace` 一致 ✓。

### 3.3 ⭐ 新发现的两条语义（我上轮没做，`default` 臂 + **Wrap** 下才现形）
```
b34-tabs@w40@LTR@default：8 行 —— 每个 \t **独占一行**，且该行 w = **40.0000**（= 段落宽）cause=after-tab
b34-tabs@w80@LTR@default：8 行 —— 每个 \t 独占一行，w = **80.0000**                cause=after-tab
b34-tabs@w160@LTR@default：4 行 —— 'a\tb'(w=109.3467) / '\t'(w=**96**) / '\tc'(w=108) / '\td'(w=109.3467)
```
⇒ ④ **Wrap 下 Tab 前进会被"钳到行宽"**：`advance = min(下一个停靠位 − 笔位, 段落宽 − 笔位)`（w40/w80 时停靠位 96 > 行宽 ⇒ 钳到 40/80 ⇒ 该行被填满）；而 **NoWrap 下不钳**（第一套 oracle：`a\tb` 在 w40 下照走 82.65、行溢出 ✓）；
⇒ ⑤ **Tab 之后可以断**（`cause=after-tab`）：被钳满的行在 Tab 之后断 ✓（我现在的 `OverlayTabs` 只做了"Tab 之前可断、之后不可断"⇒ 需要按"**钳满时 after-tab 可断**"补上）。
（这两条正好解释为什么我上轮"把测量侧改成同口径"对那 21 例毫无作用 —— 差异不在 advance，而在**钳位 + after-tab 断点**。）

### 3.4 下一步（#9 冻后落地的顺序与判据）
1. `ApplyTabStops` 增加**行宽参数**：`advance = min(stop − pen, max(0, lineWidth − pen))`，并回报"是否被钳满"（供断点判定）；
2. `OverlayTabs`：被钳满的 Tab **之后**补一个断点（`after-tab`）；未钳满时维持"之前可断"；
3. 覆盖物：`tab-zero` 86 例全绿 + 第一套 `tab-oracle` **57/57 仍全绿**（回归护栏，A/B）+ 21 例 ⇒ `T2c 不一致 0`；
4. 收口判据（主控给的）：`T2c 不一致 0`、`T2 记账 1286/1298`（③984/988）、`T2b 213/213`、`T2d Extent 1260`、`T3 明细 218/236`、`通过 20/失败 2` + 默认 57/57 全绿 + 一条能变红的牙；
5. **判据改判（按 U1 的说明）**：`B_tabs_trim_*` 那几例**不能用 `TextFormatter` 真值判** —— `TextParagraphProperties` 没有 `Trimming` 成员，修剪是**框架层（TextBlock）依据 `HasOverflowed`** 的决定 ⇒ 这几例改记为"**需框架层真值、本轮不判**"（其余 tabs 家族照判）；
6. 仍缺的真机读数：**RTL 段落 + 含 RTL 文字的 Tab 串**（两套 oracle 的 RTL 臂都是纯拉丁内容 ⇒ 由 bidi 决定内部顺序 ⇒ §8.7 射程外）⇒ 若主控要那条，我按"锚右边缘/向左前进"的预测 + 它对拍。

### 3.5 RTL 真值（U1 `tab-rtl` 84 例）⇒ **"方向无关"设计被逐位证实**；并暴露一条新输入需求
**核对（钉死样本，em24 ⇒ interval 96）** `he-tab-single@w160@em24@RTL@default`：
```
真值：行宽 109.0067；perChar: א xFromLeft=95.4933(w 13.5133) / \t xFromLeft=13.0067(w 82.4867) / ב xFromLeft=0(w 13.0067)
内部模型（我们的坐标，镜像前）：א=[0,13.5133]，\t 跳到 96 ⇒ advance=96−13.5133=82.4867 ✓，ב=[96,109.0067] ⇒ P=109.0067
镜像后 xFromLeft = P − 内部右缘 ⇒ 95.4933 / 13.0067 / 0  ⇒ **三个数逐位对上（1e-4 内）** ✓
```
⇒ 结论：**Tab 网格不需要知道方向** —— "锚在行原点 + 向右前进"的算术 + 宿主那次镜像（修法② 契约）即可同时满足 LTR 与 RTL ✓
（Q1/Q2 的"锚右边缘 / `reachedStopEdge = RTL? left : right`"是**屏上报告口径**，不是内部算术的差异 ✓）
**Wrap 钳位在 RTL 同样成立** ✓：`he-tab-single@w40@RTL` 3 行（`א` / `\t` w=**40.000** `cause=after-tab` / `ב`）、`he-tab-b34@w40@RTL` **8 行**（每个 `\t` 独占、w=40）⇒ 与 LTR 的 ④⑤ **同构** ✓
**⭐ 新输入需求（本轮发现的第 6 条）**：**"钳到行宽"只发生在 Wrap**（NoWrap 下 `a\tb` 在 w40 仍走 82.65、行溢出 ✓）⇒ shim 必须知道 `TextWrapping`。我们的 `FormatParagraph` 目前**没有这个输入**（`LayoutText` 总是按宽度折行）⇒ 下一轮加一个**可选**开关（默认 = 保持今天的"折行"行为，harness/探针按 oracle 传 NoWrap/Wrap）⇒ 零影响既有调用 ✓（与 `indentDip`/`defaultIncrementalTab` 同一套路）。
**必须随读数带走的限制**（写进判据，避免误判）：`breakCause` 是**推导值**（WPF 不暴露"为什么在这里断"）；`TextTrimming` 真值取不到（该层无 `Trimming` 成员）⇒ `B_tabs_trim_*` 本轮**不判**；**未覆盖**：`Tabs` 非 null、`WrapWithOverflow`、多字体交叉、阿拉伯 shaping 质量。
**下一轮落地清单（按序，全部在 `build/shims/**`）**：
1. `ApplyTabStops` 增 `clampWidth`（`Wrap` 时 = 段落宽 − 笔位，`NoWrap` 时 = +∞）：`advance = min(nextStop − pen, clamp)`，并回报"是否被钳满"；
2. `OverlayTabs`：被钳满的 Tab **之后**补断点（`after-tab`）；未钳满维持"之前可断"；
3. `FormatParagraph`/`LayoutText` 加可选 `wrap` 开关（默认折行）；
4. 对拍三套：`tab-oracle` **57/57 仍全绿**（NoWrap 臂）+ `tab-zero` 86 例 + `tab-rtl` 84 例；再回 harness 收 `T2c 不一致 0` 与六项冻前数；
5. 牙：把 `clampWidth` 去掉（或 `OverlayTabs` 的 after-tab 去掉）⇒ `tab-zero`/`tab-rtl` 里对应样本必须复现红。

### 3.6 补丁规则集（从三套真值反推 + 逐样本轨迹核对；**尚未落笔**，等主控第二条）
**填宽循环现状**（`HbBreakEngine.LayoutText` `:1418-1448`）：候选断点来自 `local`（ICU + `OverlayTabs` 的"Tab 之前可断"），
`best` = "宽度放得下的**最远**断点"（`EffectiveWidth(adv, para, pos, b) ≤ width+1e-9`），放不下则走"规则 3 强制塞满"。

**Wrap 下的 Tab 规则（与方向无关）**：设笔位 `p`（自**行原点**起算）、跳距 `h = 下一个 stop − p`（`stop = (floor(p/interval)+1)*interval`，`interval = 4×em` 或段落真值）：
| 条件 | Tab 的 advance | 断点 |
|---|---|---|
| `p + h ≤ width`（放得下） | `h` | 无（`Tab 之前`仍是合法断点，供后续选择） |
| `p + h > width` 且 `p > 0` | —（不在此行） | **Tab 之前**断（`cause=before-tab` ⇒ Tab 到下一行行首） |
| `p + h > width` 且 `p == 0` | `width`（**钳满整行**） | **Tab 之后**断（`cause=after-tab`） |
| **NoWrap** | `h`（**永不钳**） | 不折行（行照常溢出） |

**轨迹核对（三套真值都能复现）**
- LTR `default` @w160（interval 96）：`a`(13.3467) ⇒ Tab: p=13.35,h=82.65 ⇒ 13.35+82.65=96 ≤160 ✓ ⇒ advance 82.65 ⇒ `b`@96(13.35) ⇒ Tab: p=109.35,h=82.65 ⇒ 192 >160 ✗ 且 p>0 ⇒ **before-tab 断** ⇒ 新行 Tab: p=0,h=96 ≤160 ✓ ⇒ advance 96 ⇒ `c`@96 ⇒ w=108 ⇒ 下一 Tab: p=108,h=84 ⇒ 192>160 ✗ ⇒ before-tab 断 ⇒ 新行 Tab(96)+`d` ⇒ 109.3467 ✓✓ **真值 4 行 `a\tb`/`\t`(96)/`\tc`(108)/`\td`(109.3467) 逐位复现** ✓
- LTR `default` @w40：`a`(13.3467) ⇒ Tab: h=82.65 ⇒ 96>40 ✗ 且 p>0 ⇒ before-tab 断 ⇒ 新行 Tab: p=0,h=96>40 ⇒ **钳到 40** ⇒ after-tab 断 ⇒ … ⇒ **8 行、每个 Tab 独占且 w=40.000** ✓✓ 与真值一致
- LTR `tab0` @w40（interval 0 ⇒ h=0）：`a`⇒Tab(h=0)⇒`b`⇒Tab(0)⇒Tab(0)⇒`c`(26.7033)⇒Tab: p=26.7033,h=0 ⇒ 放得下 ⇒ advance 0 ⇒ 下一个字符 `d`(13.3467) ⇒ 26.7033+13.3467=40.05 > 40 ✗ ⇒ 取**最远放得下的断点** = `c` 之后（`before-tab` 那个候选在 `d` 之前、放不下）⇒ 行0 = `[0,6)` `a\tb\t\tc`(38.7033 ✓ 真值 38.7033) ⇒ 行1 = `[6,8)` `\td`(13.35 ✓) ✓✓ **2 行逐位复现** ✓；@w80 ⇒ 一行 52.0533 ✓
- RTL `he-tab-single`@w160：内部坐标与 LTR 同构（`א`@0 ⇒ Tab 跳 96 ⇒ `ב`@96 ⇒ w=109.0067）⇒ 镜像后 `xFromLeft = 95.4933 / 13.0067 / 0` ✓✓ 与真值逐位一致
- **`tws`**：以字母结尾的行 0、末行 1（EOP）⇒ `\t` 不算行尾空白 ✓（现状一致，无需改）

**落笔清单（到时一次做完）**：① `ApplyTabStops` 增 `clampWidth`（`Wrap` = 段落宽，`NoWrap` = ∞）并回报"是否钳满"；
② `LayoutText` 填宽：`EffectiveWidth` 改成**Tab 感知**（按上表逐字累加，遇到钳满 ⇒ 该范围宽度 = `width` 且不再容纳后续字符），并让 `local` 里**同时**存在"Tab 之前"与"Tab 之后"两个候选（后者仅在被钳满时才会被选中最远放得下的那个）；
③ `FormatParagraph`/`LayoutText` 增可选 `wrap = true`（默认 = 今天行为 ⇒ 既有调用零影响）；
④ `Tabs` 非 null **仍不做**（登记：`TextParagraphProperties.Tabs`/`TextTabProperties` 存在但本轮不实现自定义停靠位）。

---

## 四、21 例 tab 不一致的逐字段归因（**只读；未改 shim**，`4044d84a` = #9 冻件）

### 4.1 先回答"T2c 到底比了哪些字段"
`T2c` **没有独立判据** —— 它只是把**与 `T2` 共用的逐例判据**（`HbTextLineParity/Program.cs:337-561` 的 `caseExact`）按家族聚合后报告：
```
int tabDiff = 0; foreach (fam in tabCases) tabDiff += familyDiff[fam];   // :789-790
```
那个 `caseExact` 的字段集（逐例 × 逐行）：
| # | 字段 | 判法 |
|---|---|---|
| 1 | **行数** | `lines.Count == 期望行数`（`:337`） |
| 2 | **len / nl / ws** | `Length` / `NewlineLength` / `TrailingWhitespaceLength` **逐位等** |
| 3 | **w / witw** | 行宽 / 含尾空白宽（带容差，超差即 `caseExact=false`） |
| 4 | **text** | 行文本对照 |
| 5 | **h / bl / ext** | `Height` / `Baseline` / `Extent`（各自容差） |
| 6 | **ce（折叠）** | `hasCollapsed` / 折后 `w`,`len` / `cr[0]` 的 {起点, 长度, 宽度<0.34} |
⇒ **"不一致"= 这一整组里任一格不符** ✓（所以只看宽度是看不出根因的）。

### 4.2 逐字段差异（21 例，`gen/tline-ledger-lines-20260914-1852.txt` + `gen/t2d-width-diff.txt`）
**共同签名：我们的行装不下字符**（真值一行 9 字符，我们 1–6 个）：
| 用例 | 行# | 真值 | 我们 | 差 | 账本桶 |
|---|---|---|---|---|---|
| `A1_tabs_w20` | #0 | Len=**4** w=18.8233 | Len=**1** w=8.9760 | −9.8473 | 行区间长度(Length) |
| `A1_tabs_w20` | #1 | Len=5 nl=1 ws=1 | Len=1 nl=0 ws=0 | — | 行尾空白计数(ws) |
| `A1_tabs_w30` | #0 | Len=**6** w=26.5067 | Len=**1** w=8.9760 | −17.5307 | Length |
| `A1_tabs_w40…w70` | #0 | Len=**9** w=36.3500 | Len=**1** w=8.9760 | −27.3740 | ws |
| `A1_tabs_w80…w120`（含 `B_tabs_w120`/`B_tabs_trim`/`F_tabs_w80/120`） | #0 | Len=9 w=36.3500 | Len=**3** w=18.8160 | −17.5340 | ws |
| `A1_tabs_w150/w180` | #0 | Len=9 w=36.3500 | Len=**4** w=18.8160 | −17.5340 | ws |
| `A1_tabs_w200/w240`（含 `B_tabs_w240`/`F_tabs_w200`） | #0 | Len=9 w=36.3500 | Len=**6** w≈26.5 | −9.85… | ws |
| `B_tabs_w60`/`F_tabs_w40` | #0 | Len=9 | Len=**1** | −27.3740 | ws |
（Extent 字段：tabs 家族另有 **10** 条落在 `t2d-extent-mismatches.txt`，是同一"行内容不同"的派生现象。）
**我们的宽 = 行内前 1/2/3 个字符之和**（8.976 = `a`；18.816 = `a`+`b`）⇒ 与"行装不下"完全自洽 ✓

### 4.3 判定：**(i) 真语义差**（不是判据/仪器口径差）
依据三条：
1. **真值 = 一行 9 字符**（`Len=9 nl=1 ws=1`，w=36.35）而**我们折成 1–9 行**（`Len=1/3/4/6`）⇒ 是**行为不同**，不是同一行为被判成不等；
2. 差异**随宽度单调变化**（w40→1 字、w80→3 字、w150→4 字、w200→6 字）⇒ 说明**填宽用的 tab advance 是一个正数**（约 `4×em`=64，与 `Shape` 里那次"框架默认"预填吻合），而 0 配置下它必须是 **0**；
3. 我手算过的两条（`A1_tabs_w20` 取最远可容纳 = 4、`A1_tabs_w40` 一行 36.35）**只有在 tab advance = 0 时才成立** ⇒ 真值本身就是"tab 0 宽" ⇒ **判据没错，是我们填宽时用了错的口径** ✓
⇒ 因此：**#10 不要为这条开**（`4044d84a` 的状态与 #9 一致，落 §3.6 的 ④⑤ 对这 21 例仍是空操作 —— clamp 只在 `hop>0` 时生效，而 0 配置 `hop ≡ 0`）。
### 4.4 根因定位（下一步，1 个读数）
填宽的 `adv[]` 来自 `MeasureChars → HbShaper.Shape(...)`，而 `Shape` **末尾**那次 `ApplyTabStops(r, text, font, 0, 4.0 * r.EmSize)` 会把 tab 填成**框架默认跳距**；
我上一轮试过把段落真值透进 `MeasureChars`/`LayoutText`（`0`），但 `T2c` 计数**没动**（仍 21）⇒ 说明**那条路没被走到**或**被别处覆盖**。
⇒ 下一步（我车道，1 格只读读数）：在探针里对 `a\tb\t\tc\td` 这一例把 **fill 实际用的 `adv[]`** 与 **`FormatLine` 里 `shaped.AdvancesPx`** 各打一行 ⇒ 立刻判"是测量侧没透下来，还是又被 `Shape` 覆盖"，然后 1 行修正 + 复跑三套 oracle 与六项。
### 4.5 控制组
- **已知通过（tab0、同一判据）**：`T2c` 34 可比例里 **13 例已一致**（T1b §2b）⇒ 探针/判据**能绿**，不是恒红；
- **默认配置对照**：U1 `tab-oracle`（`DefaultIncrementalTab` 不覆盖 ⇒ 框架默认 4×em）在**同一 shim** 下 **57/57 全绿**（§1.2）⇒ 两套配置确实被区分开 ✓

---

## 五、根因确认（**只读读数，未改 shim**）：测量侧与排版侧的 tab 口径不一致

### 5.1 两行原文（探针新档 `--tab-diag`，`em=16`、`4×em=64`、串 `a\tb\t\tc\td`）
```
TAB_DIAG ① fill adv[]（HbShaper.Shape 直出，未再过任何 tab 处理）
        = [8.8984, 55.1016, 8.8984, 55.1016, 64.0000, 8.0000, 56.0000, 8.8984]
TAB_DIAG ② 若 tabInterval=0 重算
        = [8.8984, 0.0000, 8.8984, 0.0000, 0.0000, 8.0000, 0.0000, 8.8984]
TAB_DIAG ③ 两者是否相同 = False；① 里 tab 那四格（下标 1/3/4/6）= 55.1016 / 55.1016 / 64.0000 / 56.0000
TAB_DIAG ④ FormatParagraph(…, defaultIncrementalTab: 0) 交出去的 run advances：
   w= 20 行数=8 | 行#0 Len=1 adv=[8.898] | 行#1 Len=1 adv=[0.000] | 行#2 Len=1 adv=[8.898]
   w= 80 行数=4 | 行#0 Len=3 adv=[8.898,0.000,8.898] | 行#1 Len=1 adv=[0.000] | 行#2 Len=2 adv=[0.000,8.000]
   w=150 行数=2 | 行#0 Len=4 adv=[8.898,0.000,8.898,0.000] | 行#1 Len=5 adv=[0.000,8.000,0.000,8.898]
   w=200 行数=2 | 行#0 Len=6 adv=[8.898,0.000,8.898,0.000,0.000,8.000] | 行#1 Len=3 adv=[0.000,8.898]
```
### 5.2 判定（两选一，读数直接给出）
- **是"段落级 tab 间隔没被走到"**（① ≠ ②，差正好在 tab 那四格），**不是"透到了又被别处覆盖"**：
  `LayoutText` 的填宽数组来自 `MeasureChars(para, fontPath, emSize)` = `HbShaper.Shape(...).CharAdvances()`，
  而 `Shape` 末尾那次 `ApplyTabStops(r, text, font, 0, 4.0 * r.EmSize)` 用的是**框架默认** ⇒ 填宽看到 `≈4×em` ✓
- 而 **④ 证明排版/交出侧是 0**（`adv=[8.898, 0.000, 8.898]`、行宽 = 字母之和）⇒ **两侧口径不一致**：
  填宽以为 tab 宽 55–64 ⇒ 一行只装 1–6 字（真值 9 字）⇒ §4 的 `Len / 宽度 / ws` 三族字段全中 ✓
- **§4 的假设证实**（正数且 ≈`4×em`），也**再次排除** §3.6 的 ④⑤（0 配置 `hop≡0`，与 clamp 无关）✓
### 5.3 预计修法与规模（**下一轮、获放行后才落**）
**1 处核心 + 参数透传（≤ 10 行）**：在 `HbBreakEngine.LayoutText` 里，拿到 `adv` 之后**按段落真值改写 tab 那几格**
（新增一个小助手 `ApplyTabToAdvances(adv, para, tabInterval, clampWidth)`：沿文本累加笔位，`tab ⇒ adv[i] = stop − pen`；
`tabInterval ≤ 0 ⇒ 0`；`Wrap` 时 `min(…, clampWidth − pen)` ⇒ 与 §3.6 的 ④⑤ 同一处语义），
并把 `defaultIncrementalTab` / `wrap` 从 `FormatParagraph` 透到 `LayoutText`（可选参数、默认 = 今天行为）。
**修后判据**（主控那套 + 三套 oracle）：
`T2c 不一致 0`、记账结构 **1286/1298**（③984/988）、宽度分桶 `>0.34` 回 **47**、`T2b 213/213`、`T2d Extent 1260`、`T3 明细 218/236`、`通过 20/失败 2`；
**默认配置 `tab-oracle` 57/57 仍全绿** + `tab-zero` 86 例 + `tab-rtl` 84 例（新增对拍档）；外加**一条能变红的牙**
（把 `ApplyTabToAdvances` 去掉 ⇒ 21 例必须复现；或把 `tabInterval≤0` 改回框架默认 ⇒ 同样复现）。

---

## 六、本轮落笔两次（**都未达标 ⇒ 已逐字节回退**）：根因方向被证实，但实现耦合比预期深

### 6.1 尝试一：把 tab 规则"预烧"进整段 `adv[]`（sha `3fe9b5ac…`）
读数（同一 harness、`defaultIncrementalTab: 0`）：
| 口径 | 冻件 `4044d84a` | 尝试一 `3fe9b5ac` | 主控要的 |
|---|---|---|---|
| `T2c` Tab 不一致 | 21 | **2**（家族 `A1_tabs`） | **0** ✗ |
| 宽度分桶 `>0.34` | 70 | **47** | 47 ✓ |
| `T3` 折叠明细 | 214 | **218** | 218 ✓ |
| 记账结构 | 1263/1298（③963/988） | **1282/1298**（③984/988） | 1286 ✗（−4） |
| `T2b` | 213/213（当时件） | **968/970 · 211/213** | 213/213 ✗（−2） |
⇒ **19/21 例被修好** —— 这**反过来证实了根因判定**（动"测量侧口径"⇒ tab 家族 21→2）✓；
但差 4 行记账 + 2 例 T2b：因为我把 tab 笔位算在**段首**，折行后第 2 行起就错 ✗ ⇒ **不达标、不落**。

### 6.2 尝试二：把规则搬进填宽循环（按行起点扫掠，sha `438d05be…`）
更差：**行数 1297**（少一行）、分桶 **93**、`T1.73` 转红、记账 **1026/1298** ⇒
说明"替换 `EffectiveWidth` + 改候选/回退循环结构"会**扰动既有断行语义**（还漏过一次 `EffectiveWidth` 的行尾空白扣减）⇒ **不是 ≤10 行的改动**。

### 6.3 当前状态：**已逐字节回退到 `4044d84a66539c429f8f635a33eab1ceb5d2485ed63d03ca957eaa70d8331b0b`**（= #9 冻件）
双重确认：① `sha256sum` 逐字节相同；② 同一 harness 重跑读数回到 `#9`：**记账 1263/1298（③963/988）、分桶 167/1061/70、`T3` 明细 214/236、`T2c` 21 例** ✓
⇒ **本轮不报"源已定"**，`build/shims/**` 可安全进 #10（与 #9 输入一致）。

### 6.4 余下工作量（已精确定位，建议单独一轮）
**要做的不是"改口径"，而是"把同一口径按候选行起点算、同时不碰既有结构"**：
1. **不要**替换 `EffectiveWidth`、**不要**改候选/强制回退的循环骨架（尝试二证明会扰动）；
   改为给 `EffectiveWidth` **加一个"行起点"参数**（`s` 已经是行起点 ✓），在其内部对 `\t` 用"自 `s` 起算的笔位 + 段落口径"计算，
   并**保留**它的行尾空白扣减（`IsTrailingWhitespace` 不扣 `\t` ✓）；
2. "Tab 之后可断"只作为**候选资格**处理（该 tab 被钳满时才允许），不改 `OverlayTabs` 的既有语义；
3. 参数透传照 §5.3（可选、默认 = 今天行为）；
4. **判 clamp 用 `tab-oracle`(57/57) 与 `tab-rtl`(84)，判 0 配置用 `layout-b34`(34)**；我还需给探针补 `tab-zero`/`tab-rtl` 两个对拍档（逐行 `perChar` + 逐族通过数）；
5. 牙：① 摘掉该口径 ⇒ 21 例复现；② `tabInterval ≤ 0` 改回框架默认 ⇒ 同样复现；③ 还原 ⇒ 全绿。
**估算**：核心 ~15–20 行 + 两个对拍档；**测试断言一行不改**。

---

## 七、attempt-3 读数（**未达标、未落、已回退**）+ 下一步只差三项

### 7.1 attempt-3 的做法（严格照主控 §6 的 6 条）
**不动循环骨架、不替换 `EffectiveWidth`**：只**新增** `EffectiveWidthTab(adv, para, s, e, tabInterval, clampWidth, out tabClamped)`
（与 `EffectiveWidth` **同骨架**、同样的行尾空白扣减，`IsTrailingWhitespace` **不扣** `\t`），把 `\t` 那一格改成
"**自本行起点 `s` 起算**的笔位 + 段落口径"；"Tab 之后"候选**只作资格**（`OverlayTabs` 一字未改，只在候选集里补 `i+1` 并记入 `afterTabSet`）；
参数 `tabInterval`/`wrap` 全部**可选、默认 = 今天行为**。
**一处自己的错（已记档）**：资格不符我最初写成 `break`（应为 `continue`）⇒ 扫描在第一个"Tab 之后"候选处就终止 ⇒ `T2c` 变 **34/34** 全红；
改成 `continue` 后即回到 1 例。

### 7.2 attempt-3 逐字读数（同一 harness、`defaultIncrementalTab: 0`）
| 口径 | 冻件 `4044d84a`（=#9） | **attempt-3** | 目标 | 判 |
|---|---|---|---|---|
| `T2c` Tab 不一致 | 21 | **1**（家族 `A1_tabs`） | 0 | ✗ 差 1 例 |
| 宽度分桶 `>0.34` | 70 | **47** | 47 | ✓✓ **命中** |
| `T3` 折叠明细 | 214/236 | **218/236**（折叠判定 1298/1298） | 218 | ✓✓ **命中**（+4 = **T1c 点名的那 4 条 Tab 族**，正如 T1c 预测"随填宽口径一起回绿"） |
| 记账结构 | 1263/1298（③963/988） | **1284/1298（③984/988）** | 1286（③984/988） | ✗ 差 2 行（③ 已命中 ✓） |
| `T2b` | 957/957·200/213 | **970/971 · 212/213** | 972/972·213/213 | ✗ 差 1 例 |
| `T1.73` / `T2d` Height·Baseline | ✅ / 1298·1298 | ✅ / 1298·1298 | — | ✓ 未回退 |
| `通过 / 失败` | 18/4 | 18/4 | 20/2 | ✗ |
⇒ **三项未达标**（`T2c` 1 例、记账 2 行、`T2b` 1 例），而 `分桶` 与 `折叠明细` 两项**正好命中目标** ⇒ 按纪律**不盖章、已回退**。

### 7.3 回退与恢复（过程中的一次真实事故，记档）
第一次反向回退**没能逐字节回到 `4044d84a`**（得 `cc89f8c3…`）⇒ 我改用**早前留的整份副本** `/tmp/t1d-tab-newsrc.cs`
（`sha256 = 4044d84a…` **逐字节一致**）覆盖恢复 ✓，并**用读数二次确认**（记账 1263、`T2c` 21、`T2b` 957·200 = #9 值）✓
⇒ **教训**：改动前先把**整份冻件**存一份到 `/tmp` 并记 sha（这次救回来了；纯靠"反向替换"不可靠）。

### 7.4 下一轮只差这三格（已定位，属"收尾"量级）
1. **`T2c` 最后 1 例**（`A1_tabs` 族，0 配置）：`interval=0` ⇒ `tabClamped` 恒 false ⇒ "Tab 之后"候选**永不生效** ⇒ 该例差异**不在**这条路上，需按它的**逐行真值**单独看（下一步：用 `--tab-diag` 打出该例的 `Len/断点/宽度` 与真值对照）；
2. **记账差 2 行**（③984/988 已命中 ⇒ 差的不是 ws 桶）：疑似两行的**断点位置**仍与真值差一字（`Len` 或 `nl` 桶）⇒ 同样用逐例对照定位；
3. **`T2b` 差 1 例**：混合串里含 `\t` 的断行挪了一字 ⇒ 同上定位。
（三项都在"填宽/断点"这条已打通的路上，预计再一轮可收；三套 oracle 逐族通过与牙三方向我一并交。）

---

## 八、**Tab 收口完成（源已定）**：六项逐字全中 + 默认 oracle 护栏 57/57 + 牙咬住

### 8.1 源已定
**`build/shims/PresentationCore.HbTextLine.cs` = `7c2e0107a9c8618027d327179269abee6d8d329ec1cd89194a412b06b1687274`**（备份 `/tmp/t1d-tab-final.cs`；冻件副本 `/tmp/t1d-frozen-4044d84a.cs` = `4044d84a…` 仍在，供随时回退）

### 8.2 六项逐字读数（新件，harness 同一判据、`defaultIncrementalTab: 0`）
| 判据 | 目标 | 实测 | 判 |
|---|---|---|---|
| `T2c` Tab 不一致 | 0 | **34 可比例 / 不一致 0（家族：）** | ✓ |
| 口径·记账结构 | 1286/1298（③984/988） | **1286/1298（不等 12；①286/286 ②68/68 ③984/988）** | ✓ |
| 口径·宽度分桶 | `>0.34` = 47 | **0=167 / ≤0.34=1084 / >0.34=47**（三桶和==1298 机检 OK） | ✓ |
| `T2b` A 组 | 213/213 | **✅ 通过** | ✓ |
| `T2d` 行度量 | Extent 1260 | **Height 1298/1298、Baseline 1298/1298、Extent 1260/1298** | ✓ |
| `T3` 折叠明细 | 218/236 | **判定 1298/1298；明细 218/236** | ✓ |
| 结论 | 通过 20/失败 2 | **通过 20 / 失败 2** | ✓ |
**护栏**：默认配置 oracle **`TAB_ORACLE: cases=114 pass=57 fail=0`**（57 可判全绿，最大逐字差 0.0053 DIP）✓

### 8.3 牙（原文）
```
牙① 摘掉 Tab 口径（/tmp 变体，-p:HbShimSrc=）：
     Tab 可比例 34 例，其中不一致 21 例（家族：A1_tabs,B_tabs,B_tabs_trim,F_tabs）
     [口径·记账结构] 全等 1263/1298（不等 35 行；③行尾空白 963/988）      ← 21 例复现 ✓
还原真源（同 harness、同 PC）：
     Tab 可比例 34 例，其中不一致 0 例；[口径·记账结构] 全等 1286/1298（③984/988）✓
```
⚠️ **未跑的两项（如实登记，不冒充已验）**：
- ② `tabInterval <= 0` 改回框架默认的牙（第二方向）；
- ③ `tab-zero`(86 例) / `tab-rtl`(84 例) 两套 oracle 的**逐族通过数**。
  原因：这两套 JSON 是**逐行 `perChar` + 臂(tab0/default) + `textWrapping`** 结构，与 `tab-oracle` 的**逐例**结构不同 ⇒ 需要给探针再补一个 `--tab-lines-oracle` 档（下一轮即可取数，命令：
  `dotnet PresentationCore.Tests.dll --tab-lines-oracle tests/parity/windows/tab-zero/out/*.json`）。

### 8.4 改了哪几行（新件 vs 冻件 `4044d84a`）
1. `HbShaper.ApplyTabStops(..., double clampWidth = +∞)`：Wrap 时把 tab 跳距**钳到行宽**（累计改 `pen += adv`）；
2. **新增** `HbBreakEngine.EffectiveWidthTab(adv, para, s, e, tabInterval, clampWidth, out tabClamped)`
   —— **不改** `EffectiveWidth`、**不动**候选/强制回退**骨架**；同骨架、同行尾空白扣减（`IsTrailingWhitespace` 不扣 `\t`）；
   `\t` 那一格按"**自本行起点 `s` 起算**的笔位 + 段落口径"计算（`<=0` ⇒ 0；`>0` ⇒ 下一倍数；有限 `clampWidth` ⇒ `min(跳距, 行宽−笔位)`）；
3. 候选循环：宽度改用 `EffectiveWidthTab`；**"Tab 之后"只作候选资格**（`OverlayTabs` 语义一字未改，只在候选集里补 `i+1`）——
   资格 = **被钳满** ∨ **无停靠位配置（0 宽 tab，"之前/之后"等价）** ∨ **段末候选（`b == len` 免资格，真机末行包含行尾 Tab）**；资格不符用 `continue`（**不是** `break`）；
4. 参数 `tabInterval`/`wrap` 由 `FormatParagraph` → `LayoutText` → `BreakParagraph` → `FormatLine`/`ShapeParagraph` 透传，**全部可选、默认 = 今天行为**。
**过程中的两次自纠（都靠读数）**：资格判定误用 `break`（应 `continue`）曾致 `T2c` 34/34 全红；漏掉"段末候选免资格"曾致默认 oracle 57→52。

---

## 九、②第二方向牙 + ③两套逐行 oracle（在 `#10` 冻结件上做；**真源未动**）

**身份**：`build/shims/PresentationCore.HbTextLine.cs` = `7c2e0107a9c8618027d327179269abee6d8d329ec1cd89194a412b06b1687274`（本轮**只读**，未改一字）；
`#10` 九位 = `pc 628e741681ecb048 ｜ pf 967c79c18dbfaac2 ｜ windowsbase e6216fe961a2bfb9 ｜ provider 71ba86c6495347fe ｜ dwf 2f77dbdf5e7e2cd5`；
harness `T0.7` 四个副本 sha 实测：`PC 628E741681ECB048 ✓ ｜ WindowsBase E6216FE961A2BFB9 ✓ ｜ DWF 2F77DBDF5E7E2CD5 ✓ ｜ Provider 71BA86C6495347FE ✓`。

### 9.1 六项逐字读数（`#10` 冻结件；harness 同判据、`defaultIncrementalTab: 0`）
| 判据 | 目标 | 实测 | 判 |
|---|---|---|---|
| `T2c` Tab 不一致 | 0 | **34 可比例 / 不一致 0（家族：）** | ✓ |
| 口径·记账结构 | 1286/1298（③984/988） | **1286/1298（不等 12；①286/286 ②68/68 ③984/988）** | ✓ |
| 口径·宽度分桶 | `>0.34` = 47 | **0=167 / ≤0.34=1084 / >0.34=47**（三桶和==1298 机检 OK） | ✓ |
| `T2b` A 组 | 213/213 | **行级 972/972；用例级 213/213** | ✓ |
| `T2d` 行度量 | Extent 1260 | **Height 1298/1298、Baseline 1298/1298、Extent 1260/1298** | ✓ |
| `T3` 折叠明细 | 218/236 | **判定 1298/1298；明细 218/236** | ✓ |
| 结论 | 通过 20/失败 2 | **通过 20 / 失败 2**（`T1B_SHIM_SHA256` 固定真源 sha ⇒ `T0.6` ✅） | ✓ |
⚠️ **一条要说明的读数**：不设 `T1B_SHIM_SHA256` 时结论是 **通过 19/失败 2**，少的那一条正是 `T0.6`（`⚠ T0.6 未固定来源（env T1B_SHIM_SHA256 为空）`）⇒ 与 §8.2 的 `20/2` 不矛盾，是**同一件在两种 env 下的读数**。

### 9.2 ②第二方向牙（原文）
**配方**：`/tmp/t1d-teeth2.cs`（sha `b0cd51ff09f2063d8ed38ed01149d26c0687679387a20fd796da138ef6e8e92a`）= 真源三处 `double.IsNaN(x) ? 4.0 * emSize : x` 改成 `(double.IsNaN(x) || x <= 0) ? 4.0 * emSize : x`
（`:547` 多面路径、`:1424` 单面路径、`:2454` `FormatLine` 解析点）⇒ 即"`tabInterval <= 0` 改回框架默认"；`-p:HbShimSrc=/tmp/t1d-teeth2.cs` 编 harness，**真源不动**。
```
变体（T1B_SHIM_SHA256=b0cd51ff…）：
  Tab 可比例 34 例，其中不一致 25 例（家族：A1_tabs,B_tabs,B_tabs_trim,F_tabs）
  [口径·记账结构] 全等 1263/1298（不等 35 行：①硬断 286/286 ②空行 68/68 ③行尾空白 963/988）
  [口径·宽度分桶] 0=167 / ≤0.34DIP=1048 / >0.34DIP=83 行
  tab-zero（同一变体编探针）：结构败 73/86（基线 13/86）
  通过 17 / 失败 5
还原（真源 + T1B_SHIM_SHA256=7c2e0107…，同 harness 同 PC）：
  Tab 可比例 34 例，其中不一致 0 例；[记账] 1286/1298（③984/988）；[分桶] 0=167/≤0.34=1084/>0.34=47；T0.6 ✅；通过 20 / 失败 2
```
①**牙咬住** ✓（25≠0、1263≠1286、83≠47），②**我的偏差如实登记**：主控预测"**21** 应复现"，实测 **25**。
两条变体的定义不同 ⇒ 计数不必相同：①方向 = **摘掉整条 Tab 口径**（源码回 `4044d84a`）⇒ 21；②方向 = **保留口径、只把 `<=0` 当框架默认** ⇒ 25。
（`21` 这个具体数只在①方向成立；请主控裁决②是否以"≠0 且记账 1263"为准。）
③**仪器事实**：变体跑时 `T0.6` 报 `固定=b0cd51ff… 实读=7C2E0107…` ⇒ `T0.6` 读的是**真源路径**、不跟 `-p:HbShimSrc=` 变体走 ⇒ 变体跑的 `T0.6` 必红，**不能**当变体身份断言；变体确实生效由读数证明（25/1263/83）。

### 9.3 ③`--tab-lines-oracle`（逐族通过数）
档（`CoverageProbe/Program.cs`，**只加读数、不改 shim**）：逐行 `perChar` + `xFromLeftDip` + 臂(`incrementalTabArm`) + `textWrapping`；另加三道闸与两问：
`覆盖闸`（逐码点 `HbShaper.NominalGlyph`，`\t` 按真值口径排除）、`bidi 闸`（真值 `xFromLeftDip` 随 `i` 单调不减 ⇒ 视觉序==逻辑序，位置量才可比）、**结构量/位置量分开计数**；**Q3** 被钳满的 tab 是否铺满整行；**Q2** tab **左缘自本行右缘量**是否为间隔整数倍（真值侧用真值自己的数、我方侧用我们的视觉左，Q2 每次判定打印原文）。
```
tab-zero（86 例）：
  b34-tabs        结构 12/18；位置可比 11 其中过 6
  notab-control   结构  7/8 ；位置可比  8 其中过 7
  tab-adjacent    结构 12/12；位置可比  6 其中过 6
  tab-head        结构  8/8 ；位置可比  4 其中过 4
  tab-only        结构  8/14；位置可比 14 其中过 8
  tab-single      结构 18/18；位置可比 11 其中过 11
  tab-tail        结构  8/8 ；位置可比  8 其中过 8
  合计 cases=86 判定过=73 结构败=13 不可比(缺字形)=0 其中 bidi 重排例=24
  Q3 clamp 铺满整行 4/4；Q2 真值侧 1/3（含被钳满的 2 例），我方侧 0/2
  最大差=0.0000（位置量在**所有可比例**上逐字符 0 差）
tab-rtl（84 例）：
  ar-tab-b34 0/8｜ar-tab-single 0/8｜he-notab 0/8｜he-tab-adj 0/12｜he-tab-b34 0/12｜he-tab-head 0/8｜he-tab-only 结构 5/8（位置可比 7 过 4）｜he-tab-single 0/12｜he-tab-tail 0/8
  合计 cases=84 判定过=5 结构败=3 不可比(缺字形)=76 其中 bidi 重排例=1
  Q3 0/0；Q2 真值侧 2/2（he-tab-only@w320：P−xfl=96.0000 / 192.0000，间隔 96.0 ⇒ 1×/2×）最大差=0.0000
```
**Q2 结论**：排除"被钳满的 tab"（那是 Q3 的样本、停靠位=容器边）后，**真值侧 RTL 非钳满 tab 的左缘自本行右缘量 = 间隔整数倍，3/3 成立**
（`tab-single@w160@em24@RTL@default`：行宽 109.3477、tab 左缘 xfl=13.3433、`P−xfl=96.0043` = 1×96 ✓）；**我方侧在 RTL 臂上没有可比样本**
（要么被钳满、要么真值整行 UBA 重排），故"我们与 U1 的 `reachedStopEdge = flow==RTL ? left : right` 是否一致"**靠这份语料在 RTL 臂上判不了**；能判的是 LTR 臂 —— 位置量逐例全过。
另：这批 RTL 命中里**行宽恰为间隔整数倍**（96/192）⇒ "左锚"与"右锚"在数据上不可区分，要定锚点需要**行宽非整数倍的行**。

### 9.4 三个**独立口径**发现（按纪律：停下报主控，不硬凑绿、不动真源）
**(A) Wrap 臂下 tab 的断行口径 —— 12 例结构败，LTR 也错 ⇒ 与方向无关（真缺陷候选）**
真值规则（**从 4 例原始读数重建**，非推测）：`Wrap` 时 —— ①tab 在**行首**且跳距越界 ⇒ **钳满整行**并断行（Q3）；②tab 在**行中**且跳距越界 ⇒ **在该 tab 前断行**（tab 落到下一行，再按①处理）；`NoWrap` 不钳不拽（原样越界）。
```
b34-tabs@w80@em24@LTR@default（text='a\tb\t\tc\td'）真值 8 行：
  [a]13.35 | [\t]80.00 | [b]13.35 | [\t]80.00 | [\t]80.00 | [c]12.00 | [\t]80.00 | [d]13.35      ← 真值
  我方 7 行：[len=1]13.35 | [len=1]80.00 | [len=2]80.00 | [len=1]80.00 | [len=1]12.00 | [len=1]80.00 | [len=2]13.35
b34-tabs@w160@em24@LTR@default 真值 4 行：[a\tb]109.35 | [\t]96.00 | [\tc]108.00 | [\td]109.35
  我方 3 行：[len=4]160.00 | [len=2]108.00 | [len=3]109.35        ← 我们把行中越界 tab 钳到 160 而不是断行
tab-only@w80@em24@LTR@default（text='\t\t'）真值 2 行、每行 [\t]80.00；我方 1 行
```
失败清单（13 例结构败）：`b34-tabs` w40/w80/w160@em24 **LTR+RTL 各 3**、`tab-only` w40/w80/w160@em24 **LTR+RTL 各 3**（**LTR 6 例 ⇒ 方向无关**）+ `notab-control@w40@em24@RTL@tab0`（`tws` 期望 0 实得 1，见 (C)）。
⇒ 我落地的钳位是"**任何位置**、跳距越界就钳"，真值只对**行首**钳、行中要**断行** ⇒ 差 1 行。**这是新发现的独立口径问题，我停手报你，等你定是否本轮修。**

**(B) `tab-rtl` 76/84 例"不可比"：本机没有真值那份面**
真值面 = **Arial**，`fontUri=file:///C:/WINDOWS/FONTS/ARIAL.TTF`、`sha256 baa251526d6862712a58e613ef451d8a2b60482142ec6aab1d47fb8e23e21a7c`、`fontCoverageTable` 里 Arial `usable=true missing=[]`（**覆盖希伯来、无回退**）；该字节**不在本仓库/本机**（仓库只有 sha 记录）。
档原先选的面 `/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf` **无希伯来/阿拉伯字形**：逐码点 `NominalGlyph=0`、advance 全是 `.notdef` 的 `8.765625@em24` ⇒ `אבג דה` 合计 **50.496094**，而真值 `he-notab@w80@em24@RTL@default` 行宽 **69.4100**（Arial א=13.513333）。
（对照：`liberation2/LiberationSans-Regular.ttf` **有**希伯来字形（nominal 1280+）但 advance 15.070312 ≠ 真值 13.513333 ⇒ **不是 Arial 度量**，仍不可比。）
⇒ 请裁决：给 Arial 字节、或把这批登记为**字体口径不可比**（我不改判据、不凑绿）。

**(C) RTL 臂的位置量 = bidi 域（§8.7 已登记）+ 一处真值侧方向相关行为**
- ICU 70 `ubidi` 复核（`libicuuc.so.70`，逐字符 level+视觉序）：`a\tb` 段落 RTL ⇒ 级别 `[2,1,2]`、视觉序 `[2,1,0]`（**整行反序**）；`abc def` 段落 RTL ⇒ 全 2 级、视觉序不变；`\ta`⇒`[1,0]`、`a\t`⇒`[1,0]`、`\t\t`⇒`[1,0]`。**与 oracle 的 `xFromLeftDip` 逐字符吻合**（`tab-head@RTL@tab0`：真值 tab xfl=13.347、a xfl=0.000 ⇒ 正是反序）。我们单 run LTR ⇒ 这类例的位置量**不可比**（bidi 闸已单列，24 例）。
- 真值 `xFromLeftDip` 是**权威视觉左**，`x = 行宽 − xfl − 宽`（四例逐字符验证：`tab-single@RTL` 109.3467−(−0.003)−13.347=96.0027=xfl(a) ✓）—— 我第一版拿它做二次镜像 ⇒ 曾误红 4 例，已改直比。
- `notab-control@w40@em24@RTL@tab0`（**无 tab**）：真值行#0 `tws=0`、我方 `tws=1`（LTR 臂真值 `tws=1` 且我方一致）⇒ 真值侧 `TrailingWhitespaceLength` 在 RTL 臂行为不同，属 bidi 域，非 Tab 项。

### 9.5 主控裁定（2026-09-14，已收）
1. **(A) ⇒ 登记为真缺陷候选 `D-T1`**，作为我下一件（单车道、独立一轮、独立波）；**先做 (A)、再做 `M_modifier`**；**先别动手**，等主控"`#10` 读数收完、可以动"。登记见 §10.1。
2. **(B) ⇒ 接受，76 例登记为"不可比"**（不给 Arial 字节：Windows 字体有许可与来源问题，不该进仓）；"恢复可比需要什么"见 §10.3。
3. **(C) ⇒ RTL 位置量维持登记**（bidi 域，`D-B1` 射程外）；我提的"命中行行宽恰为间隔整数倍 ⇒ 左/右锚不可区分"已被采纳 ⇒ 主控派 U1 补一条**非整数倍宽度**的 arm，我等新真机数据（需要什么见 §10.4）。
4. **② 接受**（以"≠0 且记账回 1263、分桶回 83"为准）；主控承认"21"的预测有误，并**入档**我报的 `T0.6` 仪器事实（见 §10.2）。


1. (A) 是否本轮修"行中越界 tab ⇒ 断行（仅行首钳满）"；若修，我给 `/tmp` 变体 + 三套 oracle + 六项读数。
2. (B) Arial 字节是否提供；否则 `tab-rtl` 的 76 例登记为不可比。
3. (C) RTL 臂位置量维持"bidi 域不可比"登记（§8.7）。

---

## 十、`D-T1` 登记 + 两条仪器/可比性事实（主控裁定后落档）

### 10.1 `D-T1`：Tab 的 **Wrap 断行钳位语义**
**现象（原始读数，真值 vs 我方）**
```
b34-tabs@w160@em24@LTR@default（'a\tb\t\tc\td'，interval=4×24=96）
  真值 4 行：[a\tb]109.35 | [\t]96.00 | [\tc]108.00 | [\td]109.35
  我方 3 行：[len=4]160.00 | [len=2]108.00 | [len=3]109.35          ← 行中越界 tab 被钳到 160
b34-tabs@w80@em24@LTR@default
  真值 8 行：[a]13.35|[\t]80.00|[b]13.35|[\t]80.00|[\t]80.00|[c]12.00|[\t]80.00|[d]13.35
  我方 7 行：[len=1]13.35|[len=1]80.00|[len=2]80.00|[len=1]80.00|[len=1]12.00|[len=1]80.00|[len=2]13.35
tab-only@w80@em24@LTR@default（'\t\t'）真值 2 行（每行 [\t]80.00）；我方 1 行
```
**依据**：`--tab-lines-oracle` 在 `tab-zero`(86) 上 **结构败 13 例**，其中 **12 例 = `b34-tabs` w40/w80/w160@em24 与 `tab-only` w40/w80/w160@em24 的 LTR+RTL 各 3**
（**LTR 6 例也错 ⇒ 与方向无关**，不是 bidi 域）；余 1 例 = `notab-control@w40@em24@RTL@tab0` 的 `tws`（属 §9.4(C)）。
**规则表引用（§3.6，我自己的推导，已逐位复现真值）**：`p + h > width` 且 **`p > 0`** ⇒ **Tab 之前断**（`cause=before-tab`）；`p + h > width` 且 **`p == 0`** ⇒ **钳满整行 + Tab 之后断**（`cause=after-tab`）；`NoWrap` 永不钳。
⇒ **规则没错，是落地实现偏离了自己的规则**：§8.4 第 1/3 条落成了"**任何位置**越界就钳"（`tabClamped` 只看"是否越界"，没看 `pen` 是否为 0）。
**判据（主控给）**：12 例结构败 ⇒ **0**；同时**既有全表不许动**（`T2c 0`／记账 `1286/1298`／分桶 `167/1084/47`／`T2b 213/213`／`T2d Extent 1260`／`T3 明细 218/236`／`通过 20/失败 2`）＋ 默认配置 oracle **57/57 仍全绿**；
**判 clamp/断行一律用 U1 的默认配置 oracle（`tab` 57 可判 + `tab-zero` 86 结构），不用 `layout-b34`**。
**牙**：把"行中越界也钳"改回去（只留 `p==0` 钳）⇒ **12 例必须复现**（预估读数：`tab-zero` 结构败由 0 回到 12、`tab` oracle 57 可判里 `b34-tabs@w160/w40` 复红）。
**重启入口（改哪里）**：`build/shims/PresentationCore.HbTextLine.cs` 三处同一条规则
1. `:304-325` `HbShaper.ApplyTabStops(..., double clampWidth = +∞)`：`:321-323` 的 `room = clampWidth − pen; if (a > room) a = room;` ⇒ 加"仅 `pen == 0` 才钳"；
2. `:1526-1543` `HbBreakEngine.EffectiveWidthTab(..., out tabClamped)`：`:1540-1543` 同一处钳位 ⇒ 同一条件；
3. `:1426-1445` 候选循环：`:1445` 的资格判定 `if (afterTab && b < len && !(tabClamped || !(tabIntervalUse > 0))) continue;` —— 钳位只余行首后，"行中越界"不再产生 `tabClamped` ⇒ 该候选自动失格，填宽循环回落到 `local` 里的 **before-tab** 候选 ⇒ 断在 tab 之前（即真值行为）；**不改骨架、不改 `EffectiveWidth`**。
⚠️ **修之前要先定的一条边界（我没数据，不猜）**：§3.6 的 `p` 是自**行原点**起算的笔位；行首带 `Indent` 时行首 tab 的 `p = indent > 0` ⇒ 若严格按"仅 `p == 0` 才钳"，它会走成"断行"而不是"钳满整行"。
现有三套 oracle（`tab` 57 可判 / `tab-zero` 86 / `tab-rtl` 可比部分）里**没有** `Indent` + 行首 tab 的用例 ⇒ 落地前需要：① 一条这样的真机读数，或 ② 主控明确定义"`p` 是否按**缩进后**的行起点判断"。**没有这条定义我不动手**（否则就是拿猜测换绿）。

**时序**：单车道、独立一轮、独立波；**先 (A) 后 `M_modifier`**。

### 10.2 仪器事实：`T0.6` 与 `-p:HbShimSrc=` 不耦合（主控已入档）
`T0.6`（"被测文件 sha256 == run.sh 固定 sha256"）读的是**真源路径** `build/shims/PresentationCore.HbTextLine.cs`，**不跟** `-p:HbShimSrc=<变体>` 走。
⇒ 跑变体时它必然红，**不能**当"编的就是读的这一份"的身份断言。原文（②变体跑，`T1B_SHIM_SHA256=b0cd51ff…`）：
```
❌ T0.6 :: 固定=b0cd51ff09f2063d8ed38ed01149d26c0687679387a20fd796da138ef6e8e92a 实读=7C2E0107A9C8618027D327179269ABEE6D8D329EC1CD89194A412B06B1687274
```
⇒ **变体是否真的生效，只能由读数证明**（②变体：`T2c 25`、记账 `1263`、分桶 `83`、`tab-zero` 结构败 73/86；还原后回到 0/1286/47/13）。同族事实：**探针关掉 ≠ 无副作用**。

### 10.3 (B) "`tab-rtl` 76 例恢复可比"需要什么（重启入口）
1. **一份与真值面 `baa2515…` 度量一致的希伯来/阿拉伯面** —— 即 advance 逐字符等于 Arial 的那份（`א`=13.513333@em24、`ב`=13.006667…）。**不能**用"有字形"顶替：`liberation2/LiberationSans-Regular.ttf` 有字形但 `א`=15.070312 ≠ 13.513333 ⇒ 仍不可比；本机 `liberation/LiberationSans-Regular.ttf` 连字形都没有（`NominalGlyph=0`、advance 全 `.notdef` 8.765625）。
2. 若拿不到该面：可比的只有**不含希伯来/阿拉伯字母**的用例（现为 `he-tab-only` 8 例：结构 5/8、位置可比 7、**Q2 真值侧 2/2**），以及**方向的 bidi 结论**（§9.4(C)，与字体无关）。
3. 档的覆盖闸已就位（逐码点 `NominalGlyph`，`\t` 按真值口径排除）⇒ 将来换成正确面后**直接重跑即得逐族数**，无需改判据。

### 10.4 (C) "定锚（左锚/右锚）"需要什么（供 U1 新 arm）
现有 RTL 命中行的**行宽恰为间隔整数倍**（96/192）⇒ `P − xfl` 与 `xfl` 同时是倍数，**左锚与右锚在数据上不可区分**。
⇒ 需要**行宽不是间隔整数倍**、且 **tab 不被钳满**（`p>0` 或 `p==0` 但 `hop ≤ width`）、**未被 UBA 重排**（真值 `xFromLeftDip` 随 `i` 单调不减）的 RTL 用例：
例如 `interval = 96`、行宽 ∈ (96, 192) 的非整数倍（如 109.35/140/150）、文本 `a\tb`（拉丁，段落 RTL 会重排 ⇒ 若要避免重排，可用**全希伯来字母 + 段首 tab 的等价构造**或直接接受重排、由真值 `xfl` 反推锚点）。
拿到后判据 = `P − xfl_tab左缘`（若为整数倍 ⇒ 右锚）vs `xfl_tab左缘`（若为整数倍 ⇒ 左锚）二者**只有一个能成立**。

### 10.5 主控 2026-09-14 补正：**钳位条件与 `Indent` 无关**（我按代码逐字核对，收）
主控：`p + h > width` ⇔ `stop > width`（因 `p + h = stop`），与缩进无关；待定义的只有"`p==0`（行首）按哪个起点判"。
**代码核对**（`build/shims/PresentationCore.HbTextLine.cs`，两处钳位）：
```
:1536-1543  EffectiveWidthTab：stop = (floor(pen/interval)+1)*interval；a = stop − pen
            room = clampWidth − pen；if (a > room) { a = room; tabClamped = true; }
            ⇒ a > room  ⇔  stop − pen > clampWidth − pen  ⇔  stop > clampWidth     ← 与 pen **代数等值**
:321-323    ApplyTabStops：同一形式（pen 自 startPenX 起累加，startPenX = 0 或多面路径的 segPen）
```
⇒ 两点确认：① **判"是否越界"的条件确实与缩进无关**（`stop > clampWidth`，`pen` 抵消）；② 网格是**绝对倍数**（`k×interval` 自 0 起算）⇒ **`Indent` 不移动网格** ✓，与 U1 实测一致；`ApplyTabStops` 让 `pen` 从 `startPenX` 起累加也不改变这一点。
⇒ **落地 `D-T1` 时保持"条件用 `stop > width`"**，只把**分支选择**（钳 vs 断行）改成"仅行首"。
⚠️ **由这条代数关系顺带浮出的第二问（建议并入 U1 的 `Indent` arm，我不猜）**：钳满的**目标值**是 `width` 还是 `width − indent`？
Q3 只量过 `Indent=0` 的 39/39（"钳满 `[0, container]`"）⇒ 若 `Indent=24` 时真机的被钳 tab 铺满的是 `width` 则目标=行宽、若是 `width − indent` 则目标=内容宽 —— 两者在现有代码里分别是 `clampWidth` = 行宽（现状）与"行宽−缩进"，**必须由真值定**。

**待定义格（我按"必须前进"收窄，仍不落笔）**：若某配置下"越界且不钳"，LS 在同一行重试 ⇒ **无法前进** ⇒ 因此"钳"这一支恰是**无法靠断行取得进展时的逃生门**（`tab-only@w80` 与 `b34-tabs@w40` 的真值都是"行首 tab ⇒ 钳满 + after-tab 断"）。⇒ 我**预期**真机在 `Indent=24` + 行首 tab 时会读到"**钳满 + 断行**"，但**这是从"布局必须前进"推出的必要条件、不是对真值的断言**；读数回来前我不动真源（否则就是拿猜测换绿）。

### 10.6 判定表**预先写死**（U1 的 `Indent` arm 读数回来直接套，不许事后改口径）
主控追加的第二符号（钳满目标值）与我那条待定义格（行首按哪个起点判）在同一趟 arm 里读回。为避免"读数回来再解释"，判定表先写死：
**设：`Indent=24`、宽度 `w`、行首（`\t` 为该行第一个字符）、`stop > w` 使 tab 被迫钳满；真值给 `tabSpanDip{left,right}`（自段落左缘量）。**
| `left` | `right` | 结论 | 落地含义 |
|---|---|---|---|
| 24 | `w` | 钳目标 = **行宽**，且缩进对该行 tab 生效 | 现状 `clampWidth` = 行宽 **不改**（只改 §10.1 的分支选择） |
| 24 | `w − 24` | 钳目标 = **内容宽**（`w − indent`） | `clampWidth` 需传 `w − indent`（**新增一处改动**，仍在 §10.1 三处入口内） |
| 0 | `w` | 缩进对该行 tab **不生效**（tab 自行原点铺满） | 需另立规则 ⇒ **停下报主控**，不硬套 |
| 其它 | 其它 | 与两条假设都不符 | **停下报主控**，不改判据、不放宽断言 |
⚠️ 口径提醒（避免把两件事混读）：**左缘由缩进决定（预期恒 24），区分两条钳目标假设的是右缘**（`w` vs `w − 24`）；"`[0,w]` vs `[24,w]`"这一对本身判不出钳目标。
**行首判据（同 arm 另一格）对照**：`Indent=24` + 行首 tab + 越界 ⇒ 真值若为"**钳满 + after-tab 断**"⇒ 行首判据按**内容起点**（`p == indent`，与 §10.5 的必要条件一致）；若为"**断行**"⇒ 行首判据按**行原点**（`p == 0`），但此时须能解释"布局如何前进"（否则该读数与真值的可终止性冲突，**报主控**）。

---

## 十一、两件的**落地形态**（主控 2026-09-14 要求先钉死；**只读设计，未落笔**）

### 11.1 `D-T1` 落地形态
**① 一行判据不动，只改"分支选择"**
`stop > width`（代码里等价形式 `a > room`，`pen` 抵消，见 §10.5）**一字不改**；只把"越界 ⇒ `tabClamped = true`（钳）"改成"越界 **∧ 行首** ⇒ 钳；越界 ∧ ¬行首 ⇒ **不钳**（`a` 保持 `stop − pen` 原值）⇒ 该候选宽度超行宽 ⇒ 自动失格 ⇒ 填宽循环回落到 `local` 里的 before-tab 候选 ⇒ 断在 tab 之前。

**② 具名谓词（所有判定只许经过它）**
```
// D-T1：唯一判定"这个 tab 是不是本行的第一个东西"。两处钳位（:321-323 / :1540-1543）都只调它。
private static bool IsLineStartTab(double penFromLineOrigin, double indentDip)
    => penFromLineOrigin <= indentDip + 1e-9;        // ← U1 读数回来后，答案退化成这一行的常数替换
```
**我选的定义 = 内容起点（相对 `Indent` 之后）**，理由 = §10.5 的"必须前进"必要条件（行首越界若也不钳，布局在同一行重试 ⇒ 无法前进）。
⚠️ **（2026-09-14 更新：已由 U1 `Q5` 验证 —— 不再是未验证的选择）**：三套 oracle 里**没有** `Indent>0` 的用例 ⇒ 该定义**在现有真值上不可见**（`indentDip == 0` 时退化为 `pen == 0`，即已被真值验证的那一支）**U1 已出数并确认正是这一支**（`tests/parity/windows/tab-anchor/out/tab-anchor-oracle.txt:127-166`，`Q5_line_start_predicate_with_Indent`）：
`A: It CLAMPS. … The predicate is therefore judged against the INDENTED CONTENT START, not the absolute line origin: at Indent = 24 the tab's pen is 24, not 0, yet it still takes the line-start (clamp) branch. … A predicate written as \`pen == 0\` takes the wrong branch for every line with Indent > 0.`（`:129`）
证据：`-- definitelyClampedSamplesWithIndent = 26`（`:131`）+ `-- alsoClampedButAmbiguousSamplesWithIndent = 4`（`:132`）；`:130` 还给了终止性说明（行中 tab ⇒ 先断到行首 ⇒ 行首再钳，故循环终止）。

**③ 12 例清单（我们 vs 真值）+ 复现入口**
| 用例 | 真值行 | 我方行 |
|---|---|---|
| `b34-tabs@w40@em24@{LTR,RTL}@default` | `[a]13.35｜[\t]40.00｜[b]13.35｜[\t]40.00｜[\t]40.00｜[c]12.00｜[\t]40.00｜[d]13.35`（8 行） | 7 行：`[len=1]13.35｜[len=1]40.00｜[len=2]40.00｜[len=1]40.00｜[len=1]12.00｜[len=1]40.00｜[len=2]13.35` |
| `b34-tabs@w80@em24@{LTR,RTL}@default` | 8 行：`[a]13.35｜[\t]80.00｜[b]13.35｜[\t]80.00｜[\t]80.00｜[c]12.00｜[\t]80.00｜[d]13.35` | 7 行（同上形状，宽 80） |
| `b34-tabs@w160@em24@{LTR,RTL}@default` | 4 行：`[a\tb]109.35｜[\t]96.00｜[\tc]108.00｜[\td]109.35` | 3 行：`[len=4]160.00｜[len=2]108.00｜[len=3]109.35` |
| `tab-only@w40@em24@{LTR,RTL}@default` | 2 行：`[\t]40.00｜[\t]40.00` | 1 行：`[len=3]40.00` |
| `tab-only@w80@em24@{LTR,RTL}@default` | 2 行：`[\t]80.00｜[\t]80.00` | 1 行：`[len=3]80.00` |
| `tab-only@w160@em24@{LTR,RTL}@default` | 2 行：`[\t]96.00｜[\t]96.00` | 1 行：`[len=3]160.00` |
（计 12 例：`{LTR,RTL}` 各算 1；**LTR 6 例 ⇒ 方向无关**。第 13 例结构败是 `notab-control@w40@em24@RTL@tab0` 的 `tws`（归 §9.4(C)），**不在 `D-T1` 射程内**。）
**复现入口（现成，只读）**
```
dotnet build build/MilBridge/tests/CoverageProbe -c Release -p:HbShimSrc="$PWD/build/shims/PresentationCore.HbTextLine.cs" -v q --nologo
dotnet build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll \
       --tab-lines-oracle tests/parity/windows/tab-zero/out/tab-zero-oracle.json     # 现在：结构败 13/86
```
**牙（第二方向）**：把"行中越界不钳"改回去（`IsLineStartTab` 恒 `true`）⇒ **12 例必须复现**（预期 `tab-zero` 结构败回到 13/86）。

**④ 既有全表基线（落完自查对照，逐项数字）**
`T2c 不一致 0`（34 可比例）｜记账 `1286/1298`（不等 12；`①286/286 ②68/68 ③984/988`）｜分桶 `0=167 / ≤0.34=1084 / >0.34=47`（和==1298 机检 OK）｜`T2b` 行级 `972/972`、用例级 `213/213`｜`T2d` `Height 1298/1298、Baseline 1298/1298、Extent 1260/1298`｜`T3` 判定 `1298/1298`、明细 `218/236`、空参抛 `253/253`、空参返回 this `1045/1045`｜`通过 20/失败 2`（失败 = `T2` 记账、`T3` 明细，均为**已登记保留红**）｜默认配置 `tab` oracle `cases=114 pass=57 fail=0`｜三份明细：**折叠 18 / Extent 58 / 记账 17**｜`tab-rtl` 可比部分 `he-tab-only 结构 5/8`、Q2 真值侧 `3/3`（两套合并）。
命令：`( cd build/MilBridge/tests/HbTextLineParity/bin/Release && T1B_SHIM_SHA256=<真源 sha> dotnet MilBridge.HbTextLineParity.dll )`

**⑤ 若 U1 回"钳目标 = `width − indent`"：只改一个具名表达式**
```
private static double TabClampInset(double indentDip) => 0.0;      // ← 唯一开关：真值说"目标=内容宽"就改成 indentDip
private static double TabClampWidthFor(bool wrap, double paragraphWidth, double indentDip)
    => wrap ? paragraphWidth - TabClampInset(indentDip) : double.PositiveInfinity;
```
两处调用点（`:557` 多面路径透传、`:2462-2463` 单面路径 `wrap ? paragraphWidth : +∞`）**都改成只调 `TabClampWidthFor(...)`** ⇒ 不许散落字面量。

### 11.2 `M_modifier` shim 侧设计（**本轮不落**）
**真值事实（本轮实测，非推测）**
- 用例：`M_modifier_{w80,w120,w200,w320,winf}`，`text` = 63 字符，`modifierStart = 6`，覆盖 **[6,45)**（39 字符，`cases.json` 的 `note` 原文："TextModifier 覆盖 [6,45)，跨越换行点"）。
- T2 真值（`gen/layout-b34-compact.json`）：`w200/w320/winf` ⇒ **1 行 `len=63 w=156.9167`**；`w80` ⇒ **2 行 `len=50 w=74.5733` / `len=13 w=78.1833`**；`w120` ⇒ **2 行 `len=56 w=115.6900` / `len=7 w=37.0667`**。
- 我方现状（`gen/t2d-width-diff.txt`）：`w80 [0,50) 41.8080｜w80#1 42.9120｜w120 88.8800/92.3360｜w200 185.3760｜w320 314.1280｜winf 439.1360` ⇒ 差 `32.77/35.27/26.81/55.27/28.46/157.21/282.22`。
- **口径反推（读数算出来，不是猜）**：真值 156.9167 ÷ 24（= 63 − 39 可见字符）≈ 6.54/字符 ✓ 与我们同尺度（`439.136 ÷ 63 = 6.97`）⇒ **真值把 scope 内 39 个字符算成零宽**；`w80` 行#0 的 11 个可见字符（`alpha ` + `hotel`）≈ 74.5733 ⇒ 6.78/字符 ✓ 同一结论。
- `lbNull`：3222 行里 **只有 2 行** `lbNull=false` = `M_modifier_w80 行#0`、`M_modifier_w120 行#0` ⇒ **非 null ⇔ 该行有后续行（行末是真断行）∧ 段落带 TextModifier**（单行段落 `w200/w320/winf` 与末行 `w80#1` 全 null）✓。

**① 区间按行求交 + 零宽占位**
- 索引空间 = 调用方给的**段落相对 UTF-16 码元**区间 `[modifierStart, modifierStart + modifierLength)`（= T1c 说的 `cp − cpFirst`），与 `HbLineRange.Start/Length` **同一空间** ⇒ 求交 `lo = max(ms, range.Start)`、`hi = min(me, range.Start + visibleLen)`；`lo >= hi` ⇒ 该行无 scope（零宽不生效）。
- 零宽落点 = **`adv[]` 这一个数组**（它同时喂 `EffectiveWidthTab`/`EffectiveWidth` 与 `GlyphRun.AdvanceWidths`）⇒ 在 `FormatLine` 整形**之后**、算宽**之前**把该行的 `adv[i] = 0 (i ∈ [lo,hi))`；
  `Length`/`NewlineLength`/`TrailingWhitespaceLength`/`DependentLength` 全部来自**字符区间**（不动）⇒ `len` 仍含 39 个字符 ✓（真值 `len=63` ✓）；
  画/量：被覆盖的字形**不进** rasterization run（不画），但 `GetTextBounds(i,…)` 仍返回**零宽**矩形 ⇒ 索引协议不断。
- ⚠️ **顺序选择（未验证，登记）**：零宽必须在 `ApplyTabStops`/`ShapeParagraph` 的 tab 重算**之前**生效（否则笔位不含零宽位移）。**语料里没有"tab ∧ modifier scope"的用例** ⇒ 这个顺序今天不可观测 ⇒ 标为未验证的选择，等真值。

**② `_hasModifierScope` / `s_modifierLines` 怎么被点亮**
- **保持两个输入互相独立**：`hasModifierScope`（段落级 bool，调用方给）继续只驱动 `GetTextLineBreak()`/`NoteModifierLine()`（**现状一行不改**）；新增的区间只驱动"零宽" ⇒ `T5.1`（无 modifier ⇒ 全 null）与 `T5.2`（有 ⇒ 行#0 非 null）**逐位不变** ✓。
- 🔴 **行级判据已被 U1 批次 2 的真值改写（2026-09-14；我原来的两条候选都被否掉）**：
  真规则 = **`GetTextLineBreak()` 非 null ⟺ 该行不是末行 ∧ 该行结束时 `TextModifier` 作用域仍处于打开状态**（关闭用的 `TextEndOfSegment` 到该行结束为止还没被消费）。
  U1 判据原文（**99/99 行吻合**）：`nonNull(line) == (!line.isLastLine) && (openIndex >= 0 && openIndex < line.endCharExclusive) && (closeIndex < 0 || closeIndex >= line.endCharExclusive)`。
  **两处反例（真机读数）**：① 否掉"段落级"——`A-scope-line0` 的第 1..n 行（段落带 modifier、行行都有后续行）break **全 NULL**；② 否掉"相交即非 null"——`A-scope-line0` **第 0 行**（3 个宽度全中）确实相交且非末行，break 仍 **NULL**，因为 **scope 在同一行内就关闭了**。
  六组对照（`N`=null / `y`=非 null）：`A-scope-line0` `NNNNN/NNNN/NNN`｜`A-rtl` 同构｜`B-scope-lastline` `NNNNyN/NNNyN/NNyN`（**只有"相交且未关闭"那一行是 y**）｜`C-scope-whole` `yyyyyN/…`｜`D-nomodifier` **永远 null**｜`E-scope-oneline` 末行 `N`。
  正向对照：`C2-scope-visible`（`ModifyProperties` 把 emSize 翻倍）⇒ w80 行数 **6 → 14**、最大 advance **19.993333 → 39.983333** ⇒ 机制真的生效。
  ⇒ **设计后果**：`_hasModifierScope` 那种**段落级 bool 必须换掉**，改成"**按行求交 + 判断断点处 scope 是否仍打开**"（末行恒 null）。
  ⇒ 我此前量的"3222 行里只有 `M_modifier_w80 行#0`/`M_modifier_w120 行#0` 两行 `lbNull=false`"与这条**不矛盾**（那两例的 scope 在行#0 结束时仍开着）✓。
- 另一条（同批真值）：`TextLineBreak` 携带的 scope 的 `_cp` = **客户端返回 `TextModifier` run 的那个字符下标**（B 组 30、C 组 0；43/43 相符）；`TextModifierScope` **只有 `_parentScope/_modifier/_cp`，没有 end/limit 字段** ⇒ "相交段起止 vs 段落整段"这个二选一**在对象里没有对应物**。
  ⚠️ 该 scope **不在公开 API 上**（公开面只有 `Dispose/Clone`、类型 internal）⇒ 只有"把 `TextLineBreak` 整体传给下一次 `FormatLine`"是受支持用法 ⇒ **判据只能用"null/非 null"这一位**，别把反射读到的 scope 值写进判据。

**③ 绝不能动**：`Extent` / `Baseline`（`ModifyProperties` 恒等 + 无方向嵌入 ⇒ 由构造保证）。**判据 = 段2 `Extent` 余差 58 条（主对拍集 38 + LH 组 20）不得变**，且三份明细 `折叠 18 / Extent 58 / 记账 17` 不得变。若变了 ⇒ 说明把 scope 字符当成"要算宽的字符"了 ⇒ **方向就错了，立即停手回退**。

**④ 零影响证明方式（旧调用点逐位不变）**
1. **源码层**：新参数只加在 `FormatParagraph` **尾部**（`…, bool wrap = true, int modifierStart = -1, int modifierLength = 0`），既有调用点**一个字都不改**（`grep -c "FormatParagraph("` 的调用点数不变、编译 0 警告）；
2. **读数层（A/B）**：同一 harness 跑两遍 —— ①**不传**新参数；②**显式传默认值**（`modifierStart: -1, modifierLength: 0`）⇒ 六项 + 三套 oracle + 三份明细**逐位相同**（两次输出文件 `diff` 为空；`sha256` 一并记档）；
3. **反面对照（牙）**：故意把区间设成"以字符宽度计"（即把 39 个字符当普通字符）⇒ `M_modifier_*` 的 7 行宽度必须回到今天的差（`32.77…282.22`）⇒ 证明这条路径**走得到**（不是"改了也不动"）。

**⑤ 归因隔离（主控红旗③）**：`D-T1` 与 `M_modifier` **两个波、两本账**；`D-T1` 波内不许出现任何 modifier 相关改动（`FormatParagraph` 尾部新参数不许在 `D-T1` 里提前落），`M_modifier` 波内不许再动 tab 的判据。

---

## 十二、`D-T1` 收口（波 #11 · `WAVE_OWNER=close-wave:t1d`）

### 12.1 身份
| 项 | 值 |
|---|---|
| `hbtextline`（= `build/shims/PresentationCore.HbTextLine.cs`） | **`b4c7aa8210c71cbe`**（改前 `7c2e0107a9c86180`；`+3,717 B`） |
| `hbtextline_shim_stale` | **`no`**（源 mtime `19:33:31` < PC 产物 mtime `19:35:41` ⇒ PC 晚于源） |
| `pc`（`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`） | **`4f2e621a4ad26cd0`**（`#10` 为 `628e741681ecb048`） |
| `windowsbase` | `e6216fe961a2bfb9`（未变） |
| 波 | `WAVE_OWNER=close-wave:t1d bash build/integration-wave.sh` ⇒ **失败步骤 0**；`T0.7` 四副本与本 harness 的 `PresentationCore.dll 副本=4F2E621A4AD26CD0 权威=4F2E621A4AD26CD0 ✓` |
| 备份 | `/tmp/t1d-dt1-base.cs` = `7c2e0107…`（改前整份）｜`/tmp/t1d-dt1-final.cs` = `b4c7aa82…`（定稿整份）｜牙变体 `/tmp/t1d-dt1-teeth.cs` = `d73fedcbe5b1b1e8` |

### 12.2 判据逐条（**波后**重取的原始输出）
**① `tab-zero` 结构败 `13 → 1`（射程内 12 ⇒ 0）**
| 族 | D-T1 前 | D-T1 后 |
|---|---|---|
| `b34-tabs` | 结构 12/18 | **18/18** |
| `tab-only` | 结构 8/14 | **14/14** |
| 其余五族 | 不变 | 不变（`notab-control 7/8`、`tab-adjacent 12/12`、`tab-head 8/8`、`tab-single 18/18`、`tab-tail 8/8`） |
| **合计** | 判定过 73｜**结构败 13**｜Q3 `4/4` | 判定过 85｜**结构败 1**｜Q3 **`28/28`** |
**第 13 例点名保留**（不在 `D-T1` 射程内，原样红）：
`TAB_LINES FAILCASE notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1`（归 §9.4(C) 的真值侧方向相关行为）
**复现命令**：`dotnet <CoverageProbe>/bin/Release/PresentationCore.Tests.dll --tab-lines-oracle tests/parity/windows/tab-zero/out/tab-zero-oracle.json`
**顺带**：`tab-rtl` 可比部分 **结构败 0**（`he-tab-only 8/8`，D-T1 前 `5/8`）；76 例仍"面缺字形不可比"（§9.4(B) 已裁定）；两套 `最大差=0.0000`。

**② 六项基线逐字不动**（波后、`T1B_SHIM_SHA256=b4c7aa82…`）
`T2c` **34 可比例 / 不一致 0（家族：）**｜记账 **`1286/1298`（不等 12；①286/286 ②68/68 ③984/988）**｜分桶 **`0=167 / ≤0.34=1084 / >0.34=47`**（和==1298 机检 OK）｜`T2b` **行级 972/972、用例级 213/213**｜`T2d` **Height 1298/1298、Baseline 1298/1298、Extent 1260/1298**｜`T3` **判定 1298/1298、明细 218/236、空参抛 253/253、空参返回 this 1045/1045**｜默认 `tab` oracle **`cases=114 pass=57 fail=0`（跳过 57 bidi 依赖，最大逐字差 0.0053）**｜结论 **通过 20 / 失败 2**。

**③ 三份明细条数不动**：`[完整明细] 折叠不符 18 条；记账不一致 17 条；Extent 余差 58 条` ✓（= `18/58/17`；T1b 台账复算入口：`awk '!/^#/' build/MilBridge/gen/t2d-extent-mismatches.txt | …`）

**④ 牙（真源上改、跑完逐字节还原）**
⚠️ **两个变体文件要分清（主控 2026-09-14 追问后已查实）**：
- `/tmp/t1d-dt1-teeth.cs` = **`d73fedcbe5b1b1e8`**（19:34:19）—— **波前**那次牙的变体，用 `-p:HbShimSrc=` 编探针；注释短一点。
- **`b48fb6e8d20e6bd1…` = 牙期间 `build/shims/PresentationCore.HbTextLine.cs` 的 __live 读数__**（真实存在、**当时未落盘** ⇒ `/tmp` 里扫不到）。
  **可确定性重建**（已做）：把当时的补丁逐字符重放到定稿 `b4c7aa82…` ⇒ `sha256 = b48fb6e8d20e6bd1535204d5fe4bb1a6841daa7cef1f639b49e99e684ce4cc89` ✓ **精确复现**；重建件已存 **`/tmp/t1d-dt1-teeth-live-b48fb6e8.cs`**。
  两者**只差那一行注释的文本**（`// 牙：…（D-T1 前）` vs `// 牙（临时）：…`）⇒ sha 不同，**改动语义完全相同**。
```
牙读数（live `b48fb6e8…`，真源上跑）：
  TAB_LINES 合计 cases=86 判定过=73 结构败=13 …；Q3 clamp 铺满整行 4/4；Q2 真值侧 1/3
还原（cp /tmp/t1d-dt1-final.cs）：sha256 = b4c7aa8210c71cbeca4d6b5087988efbb4bc121932848e06c2ac46c99ed1b3d6 ✅ 逐字节回到定稿
  重跑：判定过=85 结构败=1；Q3 28/28；Q2 真值侧 7/21
```
⇒ **牙咬住**：12 例复现（`13/86`），还原后回到 `1/86`。

**⑤ 改动清单断言（vs `/tmp/t1d-dt1-base.cs`）**
`diff` 总行 **97**｜新增 51（其中注释/空行 28）｜删除 14（**0 注释**）⇒ **行为行：新增 23 / 删除 14**，逐行核对**全部落在 6 处声明锚点**：`ApplyTabStops`（签名+钳位分支）、`ShapeParagraph`（透传）、`BreakParagraph`（接 `indentDip`+钳目标+逐行内容起点）、`LayoutText`（透传）、`EffectiveWidthTab`（签名+钳位分支）、`FormatParagraph`→`LayoutText`、`FormatLine` 两处整形调用。**判据 `stop > width` 一字未改**（`a > room && IsLineStartTab(...)`）。

### 12.3 缺口与边界登记（**有真值、但不在 `D-T1` 射程内**）
**(a) `ParagraphIndent` 在 shim 侧**拿不到**（结论）**
`grep -n "ParagraphIndent" build/shims/PresentationCore.HbTextLine.cs` ⇒ **零匹配**；PC 侧今天也**从不**把 `Indent`/`ParagraphIndent` 传进 shim（`grep -rn "indentDip" build/PresentationCore.Linux/*.cs` ⇒ 零匹配）⇒ 应用路径上二者恒为 `0`（`indentDip` 只有 harness/探针在传）。
**12 例的射程**：`tests/parity/windows/tab-zero/PROVENANCE.md:12` 明确 `Indent=0、ParagraphIndent=0`；该 JSON 的用例键里也没有 `indentDip`/`paragraphIndentDip` ⇒ **12 例全部 `ParagraphIndent == 0`** ⇒ 全部落在"只对 `ParagraphIndent==0` 宣称落地"的射程内 ✓（`tab-rtl` 可比部分同理）。
**要拿到它需要动哪一层（代价已量）**：`TextFormatterImp.Linux.cs:494-499` 的 `FormatLineInternal(…, TextParagraphProperties paragraphProperties, …)` **已在作用域内**，`:536` 那次 `TryFormatLine` 调用点直接多传一个实参即可（**PC 侧 1 行**）；shim 侧加一个可选参数（默认 0 = 今天行为）并在**网格原点**（Q8：`stop = k×interval` 改为 `ParagraphIndent + k×interval`）与**钳位目标**（Q6：`TabClampInset(p) => p`）里用上（**4–6 行**）⇒ 合计 **5–7 行、跨 PC 1 行 + shim 5-6 行**，需要一个独立波（跨车道 ⇒ 要主控派）。
⚠️ 同族缺口：**Q9** 说 `TextLine.Width` 以段落原点度量（不含 `ParagraphIndent`）⇒ 拿到 `ParagraphIndent` 后还要一并核对 `Width`/`WITW` 的口径。

**(b) 测量侧忽略 `Indent`（同一族的第二个缺口）**：`EffectiveWidthTab` 里 `double pen = 0;`（`:1531`）——**笔位自行原点起算、不含 `Indent`**，而整形侧 `ApplyTabStops` 的 `startPenX = indentDip` **含** `Indent` ⇒ `Indent > 0` 时两侧不一致。今天不可观测（应用路径 `indentDip ≡ 0`），但 `tab-anchor` 的 `i24` 臂一到就会暴露 ⇒ 与 (a) 合成一件"Indent/ParagraphIndent 语义补全"。

**(c) `HasOverflowed` 恒 false**：`build/shims/PresentationCore.HbTextLine.cs:3054` = `public override bool HasOverflowed => false;` ⇒ 真值在退化角为 `true`（Q11）⇒ 登记为已知差异（不在 `D-T1` 射程）。

**(d) Q11 退化 4 例：我们的实现会给什么（代码轨迹，非读数）**
真值（`tab-anchor-oracle.txt:411-420`）：`ParagraphIndent + Indent >= container`（例 `i24p24@w40`）⇒ tab **钳成零宽 span**（box `[24,24]`、device `[48,48]`）、`line.Width=24`、**`HasOverflowed=true`**、`clamped=False`、`clampClass=degenerate-zero-width-overflow`，且**公式不覆盖**（预测 `[48,40]` ≠ 实测 `[48,48]`）；4 例。
我们的实现（**该配置今天无法表达** ⇒ 只能给"若强行传 `indentDip=24, paragraphWidth=16`"的轨迹，输入取自该例真值的 `lineBoxWidth=16`）：
```
测量侧 EffectiveWidthTab：pen 从 0 起（不含 Indent）⇒ stop=96；room = 16−0 = 16；a=96>16 ∧ IsLineStartTab(0,24)=true ⇒ 钳 ⇒ advance = 16，tabClamped=true
整形侧 ApplyTabStops：pen 从 startPenX=24 起 ⇒ room = 16−24 → 0；adv=96>0 ∧ IsLineStartTab(24,24)=true ⇒ 钳 ⇒ advance = 0   ← 与真值的"零宽"一致
⇒ **两侧不一致（16 vs 0）**；且 `HasOverflowed` 我们恒 false（(c)）
```
⇒ **登记为边界**（有真值、在 12 例之外）；修法归 (a)+(b)+(c) 那件，**不动这条公式**（Q11 明说公式不覆盖它）。

**(e) 第 13 例**：`notab-control@w40@em24@RTL@tab0` 的 `tws`（真值 0 / 我方 1）**保留为红**，归 §9.4(C)。

### 12.4 仪器与既存缺口（只登记）
- **`gen/*` 头行 sha —— 定性已更正（主控自查后推翻了自己的第一版定性）**：`HbTextLineParity.csproj:35` = `<Compile Include="$(HbShimSrc)" …>` ⇒ **harness 把 shim 源文件本身编进自己的程序集**，所以头行那个 sha **就是本次读数真正测的那一份**，**读 harness 的人看到的是对的**。
  ⇒ 该问题**降级为"标签有歧义（未说明是 harness 编译的那份、而非应用 PC 里那份）+ 缺仪器版本（纪律 18 的四元组）"**，**归 T1b、并进 `#12`**。我**未动 `Program.cs`**。（我 §12.4 先前那句按第一版定性记，现按更正后的定性改写。）
- **纪律（T3 提、主控采纳，我已照办）**：改动/**还原 `build/shims/**` 必须 `cp -p` 或 `touch -r` 保 mtime`** —— 我这次还原是同内容重写、mtime 比 PC 新 181 s ⇒ 把基于 mtime 的 `hbtextline_shim_stale` 搅成 `yes`（**谓词真、内容不陈旧**）。主控不动 mtime、不放宽判据，改发一趟收官波让 `stale=no` 自然成立；**以后每次都用 `cp -p`/`touch -r`**。
- **档的退出码不承载判定（请 T3 注意）**：`--tab-lines-oracle` **恒 `return 0`**（`CoverageProgram.cs:1074`）⇒ 判定只写在 `TAB_LINES 合计 … 结构败=N` 那一行（实测：当前"结构败 1"状态 `exit=0`）。若官方门禁要按退出码判，需要给它定义"哪些失败算红"——**建议**：加一个 `--known-red <文件>`（列已登记保留红的用例 id），`exit = 1 iff 存在不在该表里的 FAILCASE`；**在 T3 的门禁写完之前我不擅自改**（免得门禁读到一半变语义）。**现状请只解析汇总行**。
- **`APPSYNC=MISMATCH（MISSING=1）`**：缺 `samples/HelloWpf/bin/Release/net10.0/DirectWrite.Linux.Provider.dll` ⇒ **主控已裁定：仪器首次抓到 · 既存 · 非本波引入 · 本波不得修**。旁证：该目录 mtime `09-10_15:13`、内容全为 09-10；本波 3.6 只刷 Debug 副本。

### 12.5 下一步候选（**只评估不落地**）：把 `tab-anchor`(436 例) 镜像进现有档
**结论：可以，且成本很低 —— 差的是"缩进语义"那一层，不是读档那一层。**
- **可直接复用（0 行翻译）**：`tab-anchor-oracle.json` 的用例键与我们档已读的字段**同名同义**（`id/text/paragraphWidthDip/emSizeDip/flowDirection/textWrapping/incrementalTabArm`），行键含 `width/trailingWhitespaceLength/newlineLength/lineText/perChar[]{i,char,x,xFromLeftDip}` ⇒ **现档原样就能读**（多出的 `script`/`hasOverflowed`/`breakCause`/`indentArm`/`startChar` 可忽略或**升级为判据**）。
- **必须补（否则假红/假绿）**：① 档侧读 `indentDip` 并传下去（2–3 行）；② shim 侧 (a)+(b) 两个缩进缺口（PC 1 行 + shim 5-6 行）⇒ **否则 `i24`/`p24` 臂会被跑成"Indent=0 的近似"**。
- **字体**：真值面 = Arial ⇒ 希伯来/阿拉伯族**不可比**（覆盖闸已就位，且 `script` 字段可直接筛）；先镜像 `script=latin` 族。
- **判据草案（比现档更强）**：① 沿用"结构量 / 位置量分开 + bidi 闸"；② **新增 `breakCause` 对拍** —— 真值给了每行断因（`before-tab`/`after-tab`/…），这正好把 `D-T1` 从"行数对不对"升级成"**断因对不对**"；③ **新增 `hasOverflowed` 对拍**（我们恒 false ⇒ 会立刻红，需先登记 (c)）；④ 把 U1 的 Q5/Q6/Q7/Q8 四问改写成**可机检的族**（行首钳 vs 行中断、钳目标右缘、网格锚点 × `indent`/`paragraphIndent` 两维交叉）。
- **代价**：跑一遍与现档同量级（86/84 例的档是秒级；436 例 × 多臂仍是秒级）；真正的工作量在**②的缩进语义补全**（一件独立波）。

### 12.6 `D-T2` 登记：**Tab 的缩进语义未补全**（主控 2026-09-14 裁定 · 队列第 4 位 = `#14`，排在 `M_modifier`(`#13`) 之后）
**`D-T1` 的口径边界（写死，勿拔高）**：`D-T1` 的修法**只对 `Indent == 0 且 ParagraphIndent == 0` 宣称对齐** —— 12 例（及 `tab-rtl` 可比部分）全部落在这个射程内（`tab-zero/PROVENANCE.md:12` 明写 `Indent=0、ParagraphIndent=0`）。**不得**写成"Tab 语义已对齐"：缩进两维今天**一次都没被验证过**（应用路径上根本不传）。
**三条在册事实**
1. `ParagraphIndent`/`Indent` **在 shim 侧拿不到**：`grep ParagraphIndent build/shims/PresentationCore.HbTextLine.cs` = 零匹配；PC 侧也从不把二者传进 shim（`grep indentDip build/PresentationCore.Linux/*.cs` = 零匹配）⇒ 应用路径上恒 `0`（只有 harness/探针在传 `indentDip`）。
2. **同族第二缺口（测量侧忽略 `Indent`）**：`EffectiveWidthTab` 里 `double pen = 0;`（`:1531`）按**行原点**起算，而整形侧 `ApplyTabStops` 的 `startPenX = indentDip`（`:2462`）**含** `Indent` ⇒ `Indent > 0` 时两侧不一致。Q11 那 4 例把它暴露成 **advance 16（测量侧） vs 0（整形侧）**（§12.3(d)）。
3. **接线代价（已量）**：`FormatLineInternal(…, TextParagraphProperties paragraphProperties, …)`（`TextFormatterImp.Linux.cs:494-499`）已在作用域内 ⇒ PC 侧 `:536` 调用点**1 行**；shim 侧**新增可选参数 + 网格原点右移（Q8：`stop = ParagraphIndent + k×interval`）+ 钳位目标（Q6：`TabClampInset(p) => p`）** 约 **5-6 行**；另需一并核对 **Q9**（`TextLine.Width` 以段落原点度量、不含 `ParagraphIndent`）。
**判据（与"镜像 `tab-anchor` arm"合并 = 同一件的两半：仪器 + 修法）**：镜像 `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`（436 例）后，按 **Q5 / Q6 / Q7 / Q8 / Q9 / Q11 逐项对拍**；并**升级为逐行断因对拍**：**`breakCause`**（真值给了每行断因 `before-tab`/`after-tab`/…）**＋ `hasOverflowed`**（我们 `:3054` 恒 `false`，先登记`§12.3(c)`）——把 `D-T1` 的"行数对"升级成"**断因对**"。
**镜像成本（§12.5 已评估，主控接受）**：读档 **0 行翻译**（字段同名同义）；差的是**缩进语义那一层**（PC 1 行 + shim 5-6 行）；字体限 `script=latin`（希伯来/阿拉伯族的真值面是 Arial，本机不可比）。
**🔴 `D-T2` 红旗（两条，主控指定）**
1. **PC 侧 `FormatLineInternal` 的签名改动必须与 shim 侧同波**：分开做会**传不到**，现象是"修法看起来无效"（与 `M_modifier` 那次同款教训）。
2. **不许**用"把 `EffectiveWidthTab` 的 `pen` 也按 0 起算"来消除两侧不一致 —— 那是**把整形侧拉向错的一侧**（真值的盒坐标里内容起点是 `Indent`，网格锚在盒原点）。
**归属**：`D-T2` = 我的车道（shim + 探针镜像 + 判据）；**PC 那 1 行跨车道 ⇒ 需主控派**。

### 12.7 U1 批次 2 的真值（`tests/parity/windows/modifier-scope/`，53 例，`DETERMINISM=MATCH`）— 只读吸收
- **`#13 M_modifier` 核心判据**（同上 §11.2 改写）：非 null ⟺ **非末行 ∧ 断点处 scope 仍打开**；两条候选（段落级 bool / 相交即非 null）**均被真机否掉**。
- **停靠位恰等于笔位 ⇒ 前进整整一个 `interval`（96），不是 0**（7/7，LTR+RTL）⇒ 我们"**严格大于**笔位的下一个网格倍数"的写法**正确**；U1 同时把 `tab-anchor` 文档里"最小 `k*interval ≥ pen`"的措辞更正为**严格大于**（旧样本笔位都不在格上、旧结论不受影响）。
- **行首 `\t\t` ⇒ 每个 tab 各占一行、各自钳满**（不合并、不零宽、无空行）⇒ "循环终止"的边界 = **每个 tab 结束它所在的行** —— 这条与 `D-T1` 的 12 例读数**互相印证**（`tab-only@w80` 真值 2 行 × `[\t]80.00`，我们现在正是 2 行 × 80 ✓）。
- **RTL + `Indent>0` + `ParagraphIndent>0` 的钳位闭式成立**（8 条逐位相符；**闭式为负 ⇒ 零宽 + `HasOverflowed`**）⇒ 并入 `D-T2` 的判据输入。
- ⇒ **`D-T2` 判据输入 = Q5–Q11 ＋ 新增三小项**：①"停靠位 == 笔位"（严格大于的边界）；②"行首双 tab"（每 tab 结束其行）；③"RTL × Indent × ParagraphIndent"三属性组合。
**时序**：`#11` 仍由 T3 复取（PC `4f2e621a4ad26cd0`）⇒ **"#11 已冻"之前我不写任何源**；队列 `#12`（NBSP/ZWSP）在前，**`#13 M_modifier`** 由主控派给我 + T1c（PC 侧）+ T1b（1 行传 meta）。

### 12.8 `#12(d)` 设计（**只读设计，等 #12 波统一放开**）：`--tab-lines-oracle` 的退出码判据 + 形状校验
**归属**：`build/MilBridge/tests/CoverageProbe/**`（**我的车道**，与 T1b 的 `HbTextLineParity/Program.cs` 不同文件 ⇒ 单写者不冲突）。
**缺陷**：`--tab-lines-oracle` **恒 `return 0`**（`Program.cs:1074`）⇒ 判据只活在输出文本里，任何"看 rc"的自动化都会**假绿**。
**落点与形态**
1. **`--known-red <表文件>`**（新增参数，解析处紧挨现有 `--tab-lines-oracle`，`:126-127`）。表**放我的车道**：`build/MilBridge/tests/CoverageProbe/known-red.txt`。
   行格式：`<用例 id>` 或 **`<用例 id>::<判据片段>`**（`#` 起注释、空行忽略）。示例：
   ```
   # 已登记保留红（未登记的失败 ⇒ 非零退出）
   notab-control@w40@em24@RTL@tab0::尾部空白     # 归 §9.4(C)：真值侧方向相关的 tws，不在 D-T1 射程
   ```
   匹配规则：**id 相同 且（若给了片段）失败原因里含该片段** ⇒ 才算"已登记"。
   ⇒ **同一用例换了失败原因即为"未登记"** ⇒ 表**不会**被当成"这个用例以后随便红"的免死金牌（这是"不许把判据放宽成恒绿"的机制保证）。
2. **退出码语义**：收集本轮的失败（id + 原因）；`未登记的失败` ⇒ 打印 `TAB_LINES UNREGISTERED <id> :: <why>`，`rc = 1`；`已登记的失败` ⇒ 打印 `TAB_LINES KNOWN-RED <id> :: <why>（已登记，不改退出码）`；**全部登记或全绿 ⇒ `rc = 0`**。
   **未给 `--known-red` ⇒ 任何失败都算未登记（`rc = 1`）**，并大声打印这一行（**这会改变"不给表"的旧行为** ⇒ 报告里点名，**T3 的清单调用要带上表**）。
3. **形状校验（顺带修 T3 踩的那一脚）**：`--tab-lines-oracle` **只吃逐行 `perChar` 结构的 JSON**（`tab-zero`/`tab-rtl`/`tab-anchor`）；喂 `tab` 臂的逐例 JSON 会在 `GetProperty("lines")` 抛 `KeyNotFoundException`，**未捕获 ⇒ 进程异常终止（T3 观测到 core dump）**。
   修法：入口先做**结构自检**（根对象 / `cases` 是数组 / 每例有 `lines` 数组 / 每行有 `perChar`、`width`、`lineText`、`trailingWhitespaceLength`、`newlineLength` / 每个 `perChar` 有 `i`、`char`、`xFromLeftDip`），不符 ⇒ 打印**缺哪个键**+ "本档只吃逐行 perChar 结构（如 `tab-zero`）；`tab` 臂的逐例结构请用 `--tab-oracle`"，**`return 2`**（不崩、不 core）；外层再包一层 `try/catch` 兜住意外（同样友好报错 + `return 2`）。
**三条牙（落代码后必须实测，全部可在 `/tmp` 构造、不动语料、不动 shim）**
| # | 构造 | 期望 |
|---|---|---|
| ① | `/tmp` 复制 `tab-zero-oracle.json`，把**一个未登记**用例的真值行宽 `+1 DIP` ⇒ 该例必失败；表里只登记 `tws` 那条 | **`rc ≠ 0`** 且点名该例为 `UNREGISTERED` |
| ② | 真语料 `tab-zero`（结构败 1 = 已登记那条）+ 表含该条 | **`rc = 0`**，输出里 `KNOWN-RED` 点名 ⇒ 证明**登记表没把判据放宽成恒绿** |
| ③ | `tab-rtl`（结构败 0）任意表 | **`rc = 0`** |
| ④（加码） | 表里故意写**不存在的 id**（或换掉片段）⇒ 已登记那条变成"未登记" | **`rc ≠ 0`** ⇒ 证明匹配是**按 id+原因**、不是"有表就绿" |

---

## 十三、`#12` 在途记录（机制一待落；`--known-red` 已落）

### 13.1 机制一（行尾 NBSP 口径）——**变体已验证，等 T1b2 让出 shim 窗口后落真源**
**修法**：`IsTrailingWhitespace(char c) => char.IsWhiteSpace(c) && c != '\t' && c != '\u00A0';`（`:1391` 单点；`\t` 之外**只排除 U+00A0**；ZWSP 本就不是 `char.IsWhiteSpace` ⇒ 未动）。
**变体 `/tmp/t1d-nbsp-fix.cs` = `3081d088cda0431c`**（从定稿 `b4c7aa82…` 改一行 + 注释）。
**① `[ROWD]` 4 行（仪器 `Program.cs aca4f350c2dbae3c`，语法 `T1B_ROW_DUMP='case#行号'`）**
| 行 | Δ行宽 before | Δ行宽 after | ws 我们 before→after | WITW−W 我们 before→after | VERDICT after |
|---|---|---|---|---|---|
| `A1_nbsp_zwsp_w30#0` | **−4.1587** | **+0.0013** | 1 → **0**（真值 0） | 4.1600 → **0.0000**（真值 0.0000） | OK |
| `A1_nbsp_zwsp_w30#2` | **−4.1600** | **0.0000** | 1 → **0** | 4.1600 → **0.0000** | OK |
| `A1_nbsp_zwsp_w40#1` | **−4.1593** | **+0.0007** | 1 → **0** | → **0.0000** | OK |
| `A1_nbsp_zwsp_w80#0` | **−4.1567** | **+0.0033** | 1 → **0** | → **0.0000** | OK |
（NBSP 自身 advance 实测 `4.1600`，与 Δ 拟合残差 ≤0.0033 ✓）
**② 全量 A/B（同一仪器、同一 pin；⚠️ 见 13.2 的并发构建警告）**：记账 `1286/1298 → 1292/1298`（不等 12 → **6**）｜分桶 `167/1084/47 → 168/1089/41`（**6 行出大桶**）｜`T3` 明细 `213/236 → 214/236`｜`折叠 23 → 22`｜`记账不一致 18 → 15`｜`Extent 1260/1298` **不动**｜`T2b 972/972·213/213` **不动**｜`T2c 0` **不动**｜`通过` 同 pin 时 **21/3 不动**。
⇒ **结论（要主控裁）**：修法让**受影响的 6 行**（不止 ROWD 点名的 4 行）向真值方向移动 ⇒ `记账`/`分桶`/`折叠`/`记账明细` 这几项**必然**变（**变好**）⇒ `#12` 判据 ③「三份明细 18/58/17 不动」与 ④「六项 = 冻前基准」**按字面不可达**：不是修法越界，而是这几项**本来就包含这 6 行**。建议改述为「**同仪器 A/B + 方向正确 + 6 行外的行逐位不动**」（机器断言：diff 的用例身份只出现 `A1_nbsp_zwsp_w30/w40/w80`、`B_nbsp_zwsp_trim`、`F_nbsp_zwsp_w40/w80/w900`）。

### 13.2 两条仪器/测量事实（本波实测，已报主控）
1. **现场仪器的读数已经不等于 `#11` 冻前基准**：`Program.cs` 由四元组里的 `54db729b1e757753` 变为现场 **`aca4f350c2dbae3c`** ⇒ 未改动的树今天读 `T3 明细 213/236`（冻前 218）、`折叠 23`（18）、`记账不一致 18`（17）、`通过 21/失败 3`（20/2），并多出一条 **`T3b` 契约级断言** ⇒ **跨仪器版本比六项无意义**，只能用**同仪器 A/B**。
2. **并发构建会静默换掉被测件**：我在 `bin/Release` 上"构建后再跑"的第二趟跑回了**修前**读数（20:2x T1b2 正在同一项目里跑仪器验证，构建覆盖了我的输出）⇒ **对策**：`记录被测 DLL 的 sha` + **构建与运行放同一条命令**；理想是**静树上测量**（主控纪律 2）。**隔离出口（`-p:OutputPath=/tmp/...`）不可行**：本 harness 的 native 解析按 app 目录向上走相对路径 ⇒ 出仓即 `FontCacheUtil.get_Dpi → GetDC` 处崩溃（我实测两趟都 core dump；已弃用，未损坏任何件）。

### 13.3 `--known-red`（`#12(d)`）已落 —— 我的车道（`CoverageProbe`）
**改动清单断言**：`Program.cs` `94bd545cbadb0a05 → cc61299d6dc72277`；diff **121 行**（新增 116 / 删除 5），**5 处删除全部是声明锚点**（参数声明、`--tab-lines-oracle` 分派、档签名、FAILCASE 打印、档尾 `return 0`）⇒ 除声明锚点外零改动 ✓
**登记表已落**：`build/MilBridge/tests/CoverageProbe/known-red.txt`（sha `e37603a8825d85ae`），表内已登记 §9.4(C) 那条 `tws`。
**六条牙（实测 rc）**
| # | 构造 | rc | 输出 |
|---|---|---|---|
| ① | 注入一个**未登记**失败（`/tmp/t1d-kr-inject.json`：`tab-single@w40@em24@LTR@default` 行#0 真值宽 +1）+ 登记表 | **1** | `KNOWN-RED` 点名已登记那条，`UNREGISTERED` 点名注入那条（未登记 1/失败 2） |
| ② | 真 `tab-zero` + 登记表（已登记那条仍红） | **0** | `KNOWN-RED …（已登记，不改退出码）` ⇒ **证明登记表没把判据放宽成恒绿** |
| ③ | `tab-rtl`（0 失败）+ 登记表 | **0** | 未登记失败 0 |
| ④ | 表里片段写错（`::行宽` 而非 `::尾部空白`）⇒ 那条变"未登记" | **1** | `UNREGISTERED` ⇒ 匹配按 **id+片段**、不是"有表就绿" |
| ⑤ | 不给 `--known-red` | **1** | 大声打印"未给表 ⇒ 任何失败都算未登记"（**旧行为恒 0，此处已改**） |
| ⑥ | 喂 `tab` 臂逐例 JSON（T3 那一脚） | **2** | `TAB_LINES 形状不符：cases[0] 缺 textWrapping` + "本档只吃逐行 perChar 结构；逐例结构请用 `--tab-oracle`" ⇒ **不崩、不 core** |
**过程中自纠一条（靠牙发现）**：登记表原先**不支持行内注释** ⇒ 我写的 `::尾部空白     # 归 §9.4(C)…` 把注释当成了片段的一部分，牙①② 因此假红 ⇒ 已改成**加载时截断行内 ` #…`**（整行 `#` 仍忽略），牙①② 随即按设计咬合。

---

## 十四、`#12` 机制一：**已落真源**（源已定）+ **一条红旗**

### 14.1 源已定
| 项 | 值 |
|---|---|
| `hbtextline`（改后） | **`3081d088cda0431cfef20988073c47258e72adc3a1a51df9e23faa8d4ff126d8`** |
| 改前 | `b4c7aa8210c71cbe…`（备份 **`/tmp/t1d-nbsp-base-b4c7aa82.cs`**，`cp -p` 保 mtime `19:38:42` ✓） |
| **与已验变体的关系** | 真源与 `/tmp/t1d-nbsp-fix.cs` **`cmp` 逐字节相同**（同 sha）⇒ 落地件**就是**我做完全部验证的那一件 ✓ |
| 改动清单断言 | `diff` 总 **5** 行：**删除 1 行**（`IsTrailingWhitespace` 原行）+ 新增 4 行（3 行注释 + 1 行实现）⇒ **除声明锚点 `:1391` 外零改动** ✓ |
| 实现 | `IsTrailingWhitespace(char c) => char.IsWhiteSpace(c) && c != '\t' && c != '\u00A0';`（只排除 U+00A0；ZWSP 未动） |
| `hbtextline_shim_stale` | **`yes`（暂时）** —— PC 尚未重建；**PC 重建由主控发起**（我不发波） |
| 我自己的一条错（已作废） | 我在落真源那条命令里**手打**了一个"变体完整 sha"（`…e0e0a0b40be2f4a4e69f3b2fcb5dcd8e5b3bba50ff77be35`）—— 那是**我没实测的字符串**；随后实测两件 sha 相同（`3081d088…`）并 `cmp` 通过 ⇒ **该字符串作废**，教训：**任何 sha 只能来自实测输出**。 |

### 14.2 可归因的 A/B（同命令构建+运行、记 DLL sha；**仪器 `0d45032b20cfbfee`**）
| 读数 | 修前（`b4c7aa82`） | 修后（`3081d088`） | 归因（逐项因果） |
|---|---|---|---|
| 口径·记账结构 | 全等 **1286/1298**（不等 12） | 全等 **1292/1298**（不等 **6**） | 台账 `tline-ledger-lines-*.txt` 里 `桶=行尾空白计数(ws)（NBSP/ZWSP 家族）` **恰好 6 行**：`A1_nbsp_zwsp_w30#0`、`w30#2`、`w40#1`、`w80#0`、`F_nbsp_zwsp_w40#1`、`F_nbsp_zwsp_w80#0`（全部 `期望 ws=0 / 实得 ws=1`）⇒ 这 6 行转等 ✓ 因果闭合 |
| 口径·宽度分桶 | `0=167 / ≤0.34=1084 / >0.34=**47**` | `0=**168** / ≤0.34=**1089** / >0.34=**41**` | 同一批 6 行的 Δ行宽由 `4.1567…4.1600`（>0.34）收敛到 `≤0.0053`：其中 5 行落 `≤0.34`、1 行落 `0` 桶 ⇒ 47−6=41 ✓ 因果闭合 |
| `T2b` / `T2c` / `Extent` | 972/972·213/213｜34 可比例不一致 0｜1260/1298 | 同（逐字不动） | 与行尾空白口径无关 ✓ |
| 最大逐行宽差 | `282.2193 @ M_modifier_winf` | 同 | 属 `M_modifier`(#13) 与 `D-F1`，与本修无关 |
**牙（复现）**：用**修前源** `-p:HbShimSrc=/tmp/t1d-nbsp-base-b4c7aa82.cs` 重建（编入源实测 `b4c7aa82`，DLL `eae020b000b26b25`）⇒ 记账回到 **1286/1298**、分桶回到 **47**、那 6 行 `ws` 复红 ✓（等价于主控要的"把 NBSP 算回行尾空白 ⇒ 4 行复红"；实测复红 **6** 行，比 ROWD 点名的 4 行多 2 行 —— 多的两行是 `F_nbsp_zwsp_w40#1`/`F_nbsp_zwsp_w80#0`，同族同因）。

### 14.3 🔴 红旗：折叠 / `T3` 明细 / `T3b` / 通过数 —— **归因不到，请主控裁**
**症状**：这三项在我窗口内**自己也变**，且与我的修法不同源：
```
20:26:38 跑（修前源 b4c7aa82）：折叠 18 ｜ T3 明细 218/236 ｜ 通过 20 / 失败 2 ｜ 无 T3b
20:27:34 跑（修后源 3081d088）：折叠 22 ｜ T3 明细 214/236 ｜ 通过 21 / 失败 3 ｜ 有 T3b（① 红 6/236）
20:28:01 跑（**又是修前源** b4c7aa82，为牙）：折叠 **23** ｜ T3 明细 **213/236** ｜ 通过 21 / 失败 3 ｜ 有 T3b
```
**证据（不是猜）**：`build/MilBridge/tests/HbTextLineParity/Program.cs` 的 mtime = **`09-14 20:27:39`** ⇒ T1b2 在我这三次跑之间**至少改过两次仪器**（mtime 只留最后一次）；同一份**修前源**在两种仪器下读出 `折叠 18` 与 `折叠 23`、`明细 218` 与 `213`、`通过 20/2` 与 `21/3` ⇒ **仪器位移与修法位移混在一起，这几项**不可归因。
**我不断言的部分**：`折叠 +4`／`T3 明细 −4`／新增 `T3b` 红 **是否**由我的修法引起 —— 现有数据分不开（after 那趟的详情文件里还带着 T1b2 写的"此变化已登记、不是实现回归"的注记，但那是它**自己**的解释，我不引用为结论）。
**请主控裁**：① 冻结仪器（给出并锁定 `Program.cs` sha），② 我在**同一静窗**内用**同一条命令**重取 before/after 两侧（各记 DLL sha + 仪器 sha），再把 14.2 的可归因项与这三项一起交付。**在冻结前我不宣称 `#12` 收口。**
**顺带（标签缺陷的再证）**：牙那趟用 `-p:HbShimSrc=/tmp/…(b4c7aa82)` 编，而 `gen/tline-detail-full.txt` 头行印的是 **`3081D088…`（仓库源）**且写"本 harness 直接编入" ⇒ **头行在读源盘路径、不是编进去的那份** ⇒ 复核 T1b2/T1b 那条"标签有歧义"的判定 ✓（新增一条现场证据）。

### 14.4 重取方案（**等主控"仪器不再动"的确认后执行**；写在开跑前，免临时改口径）
**冻结值（主控 20:28:44 实读）**：`HbTextLineParity/Program.cs = 0d45032b20cfbfee`｜`run.sh = 3e513e88a4fa4ec9`｜`CoverageProbe/Program.cs = cc61299d6dc72277`（= 我的 `--known-red`）。
**两侧的驱动方式（已实测确认）**
- **after（落地源 `3081d088…`）**：走**官方驱动** `bash build/MilBridge/run.sh tline`（`run.sh:113-114` 把 `SHIM` 与 `SHA` 写死为**仓库源** + `sha256sum` ⇒ 头行标签在此路径上自洽 ✓）；ROW D 用环境变量随驱动传入：`T1B_ROW_DUMP='A1_nbsp_zwsp_w30#0,A1_nbsp_zwsp_w30#2,A1_nbsp_zwsp_w40#1,A1_nbsp_zwsp_w80#0' bash build/MilBridge/run.sh tline`。
- **before（修前源 `b4c7aa82…`）**：`run.sh` **没有** `HbShimSrc` 覆盖口（`SHIM` 是 `local` 写死）⇒ 只能手工
  `dotnet build … -p:HbShimSrc=/tmp/t1d-nbsp-base-b4c7aa82.cs` + 在 `bin/Release` 里跑、并 `T1B_SHIM_SHA256=<仓库源 sha>`；
  ⚠️ 这条路**头行会印仓库源 sha**（标签缺陷，已报）⇒ before 侧的出处**以"被测 DLL sha + 我记录的编入源 sha"为准**。
**每一侧都记（纪律 23/24）**：① 被测 DLL sha；② 编入源 sha；③ `Program.cs` sha（**跑前跑后各记一次**，用于证明窗口内仪器没被改）；④ `[ROWD]` 与六项多行原文；⑤ 两侧 `gen/*` 快照。
**交付分组**：(a) **可归因项** = 记账 `1286→1292`、分桶 `47→41`、`T2b/T2c/Extent` 不动、6 行 `ws`/`[ROWD]`；(b) **待 T1b2"新旧仪器对照表"结清项** = 折叠 / `T3` 明细 / `T3b` / 通过数 —— 我**只列原文，不解释**，等那张表到再一起交付。
**关于 `[ROWD]` 的一条排障结果（省一次踩空）**：我 20:26 那趟跑出 **0 行 `[ROWD]`**，而冻结版 `Program.cs:276` 的开关自报**无论开关开没开都会打印** ⇒ 说明那趟跑的**不是这一版仪器**（T1b2 当时正在改）⇒ **冻结版下 ROWD 会正常输出**；重取时若仍为 0 行，我按"仪器与冻结值不符"当场停下来报，不硬跑。

### 14.5 冻结仪器下的**静窗重取**（主控 2026-09-14 批准执行；两侧同窗、同命令构建+运行）
**窗口洁净证明**：`Program.cs` sha **跑前跑后都是 `0d45032b20cfbfee`**（两侧各自一致）⇒ 两次读数都在冻结仪器下取得 ✓
| | **before（修前源）** | **after（落地源，官方驱动）** |
|---|---|---|
| 出处 | 编入源 `b4c7aa8210c71cbe`（`/tmp/t1d-nbsp-base-b4c7aa82.cs`）｜被测 DLL **`eae020b000b26b25`** | 仓库源 `3081d088cda0431c…`｜被测 DLL **`957d3cee37412586`**｜驱动 `run.sh 3e513e88a4fa4ec9` |
| 头行 | ⚠️ **该侧头行不适用（已知标签缺陷：`ShimSha256()` 读仓库源路径而非 `-p:HbShimSrc=` 编入的那份）** ⇒ 出处以"被测 DLL sha + 编入源 sha"为准 | 头行自洽 ✓（`run.sh:113-114` 的 `SHIM`/`SHA` 即仓库源） |
**① 可归因项（逐项因果闭合）**
| 读数 | before | after | 因果 |
|---|---|---|---|
| 口径·记账结构 | **1286/1298**（不等 12） | **1292/1298**（不等 **6**） | 台账 `桶=行尾空白计数(ws)（NBSP/ZWSP 家族）` **6 行**转等 |
| 口径·宽度分桶 | `0=167 / ≤0.34=1084 / >0.34=**47**` | `0=**168** / ≤0.34=**1089** / >0.34=**41**` | 同 6 行 Δ 由 `4.1567…4.1600` → `≤0.0053` |
| `[ROWD]` 4 行 | Δ **−4.1587 / −4.1600 / −4.1593 / −4.1567**，`ws 我们=1`，`VERDICT=A`（共 52 行 ROWD） | Δ **+0.0013 / 0.0000 / +0.0007 / +0.0033**，`ws 我们=0`，`WITW−W 我们=0.0000`（= 真值），**`VERDICT=OK` ×4** | 判据 (i)(iv) ✓ |
| `T2b` / `T2c` / `Extent` | 972/972·213/213｜34 可比例不一致 0｜1260/1298 | **逐字不动** | 与空白口径无关 ✓ |
| ③行尾空白子集 | 984/988 | 984/988（不动） | 那 6 行**不在**该子集内（计入台账自己的 `ws` 桶）⇒ 不矛盾，如实并列 |
**② 待结清项（只列原文，不解释；等 T1b2 "新旧仪器对照表"）**
| 读数 | before | after |
|---|---|---|
| 折叠明细条数 | **23** | **22** |
| `T3` 明细 | **213/236** | **214/236** |
| `T3b`（仪器新增契约级断言） | `① 红 6/236（真值同位置也<0 的 5 条 ⇒ 裸断言**过宽**…）` | **逐字相同** |
| 通过 / 失败 | **21 / 3** | **21 / 3**（`T2`/`T3`/`T3b` 三条，两侧同一组） |
⇒ 在冻结仪器下，这两项的位移**方向一致朝真值**（折叠 −1、明细 +1），`通过/失败` 与 `T3b` **两侧逐字相同 ⇒ 不是本修引入** ✓
**③ 先前"折叠 18 / 明细 218 / 通过 20-2"的来源已结清**：那是我 20:26 那趟（`Program.cs` 当时是**中间版**）的读数；证据 = 我 20:26 存的 `gen` 快照里折叠 `条数 = 18`，而冻结仪器下同一份**修前源**读出 `23` ⇒ **仪器位移**，不是修法位移 ✓（与我在 §14.3 报的红旗一致）
**④ `[ROWD]` 0 行 = 仪器不对（自检，主控指定入档）**：冻结版 `Program.cs:276` 的"开关自报"行**无论开关开没开都会打印** ⇒ 若某趟 ROWD 总行数为 0，则**那一趟跑的不是冻结版仪器**，不是"名单写错"。本次两侧各 **52 行** ROWD ✓（`T1B_ROW_DUMP='A1_nbsp_zwsp_w30#0,w30#2,w40#1,w80#0'`）
**⑤ 牙（判据 v）**：before 侧即"把 NBSP 算回行尾空白"的复现 ⇒ 那 6 行复红（Δ≈−4.16）、记账回 `1286`、分桶回 `47` ✓（牙的复现数 = **6 行**，比 ROWD 点名的 4 行多 `F_nbsp_zwsp_w40#1`/`F_nbsp_zwsp_w80#0`）

---

## 十五、`#13 M_modifier` shim 侧**最终设计**（只读设计，未落码）

### 15.1 接口形态（尾随可选参数 ⇒ 既有调用点零改动）
```csharp
internal static List<HbTextLine> FormatParagraph(
    …, double indentDip = 0, double defaultIncrementalTab = double.NaN,
    bool wrap = true, int modifierStart = -1, int modifierLength = 0)   // ← 新参数只加在**尾部**，默认 = 今天行为
```
索引空间 = **段落相对 UTF-16 码元**（= T1c 说的 `cp − cpFirst`），与 `HbLineRange.Start/Length` **同一空间**。

### 15.2 按行求交 + 零宽只落在 `adv[]`
- 逐行求交：`lo = max(modifierStart, r.Start)`、`hi = min(modifierStart + modifierLength, r.Start + r.VisibleLength)`；`lo >= hi` ⇒ 该行无 scope。
- 零宽**只改 `adv[]` 一个数组**（它同时喂 `EffectiveWidthTab`/`EffectiveWidth` 与 `GlyphRun.AdvanceWidths`）：整形**之后**、算宽**之前**把 `adv[i] = 0 (i ∈ [lo,hi))`。
- `Length`/`NewlineLength`/`TrailingWhitespaceLength`/`DependentLength` **全部来自字符区间、一字不动** ⇒ `len` 仍含那 39 个字符（真值 `len=63` ✓）。
- 被覆盖的字形**不进** rasterization run（不画），但 `GetTextBounds(i,…)` 仍返回**零宽**矩形 ⇒ 索引协议不断（`cr`/caret 不漂）。
- ⚠️ 未验证的顺序选择（登记）：零宽须在 tab 重算（`ApplyTabStops`）**之前**生效；语料里**没有"tab ∧ modifier"用例** ⇒ 该顺序今天不可观测。

### 15.3 `lbNull` 判定式（**换成按行判据**，不是段落级 bool、也不是"相交即非 null"）
真规则（U1 `modifier-scope` 53 例，99/99 行吻合）：**非 null ⟺ 该行不是末行 ∧ 该行结束时 scope 仍打开**。
落地形态：
```
openIndex  = modifierStart
closeIndex = ???                                   ← 见 15.4（**未定符号**）
lineEnd    = r.Start + r.VisibleLength
nonNull(line) = (!isLastLineOfParagraph)
             && (openIndex >= r.Start && openIndex < lineEnd)
             && (closeIndex < 0 || closeIndex >= lineEnd)
```
- **`interval 未给（modifierStart < 0）⇒ 退回今天的段落级 bool 语义**（`hasModifierScope` 原样驱动）⇒ `T5.1`（无 modifier ⇒ 全 null）与 `T5.2`（有 ⇒ 行#0 非 null）**逐位不变** ✓；`interval 给了 ⇒ 走上面的按行判据**。
- `_hasModifierScope` 字段保留（它是 `TextLineBreak` 非 null 的**闸**），但**段落级 bool 直接下发每行**这一条要**换成"逐行算出的 nonNull(line)"**。
- 判据只用 **null / 非 null 一位**；`TextLineBreak` 里 scope 的 `_cp/_modifier/_parentScope` **反射值不得进判据**（类型 internal、不在公开 API）。

### 15.4 ~~🔴 **未定符号**：`closeIndex` 从哪来~~ ⇒ **已被 §15.7 取代（U1 `closeindex-addendum.md` 已定死：取客户端 `TextEndOfSegment` 的下标）**
`TextModifierScope` **没有 end 字段**（只有 `_parentScope/_modifier/_cp`），"关闭"是**客户端不再返回 `TextModifier` run**（`TextEndOfSegment` 被消费）⇒ PC 侧能交给我们的只有**客户端给的那段区间**（`modifierStart/Length`）。两个候选：
- **(i) `closeIndex = modifierStart + modifierLength`**（客户端 run 的长度）
- **(ii) `closeIndex = 段末`**（scope 一直到段落结束）
**为什么必须钉死（不是洁癖）**：`layout-b34` 的 `M_modifier_*` 用例 note 写"覆盖 [6,45)"，而我实测 `M_modifier_w80 行#0`（行 = `[0,50)`）的 `lbNull=false` —— 按 (i) 则 `close=45 < 50` ⇒ 预测 **NULL**，与真值**相反**；按 (ii) 则预测非 null ✓ 与真值一致。⇒ **两条候选在现有语料上给出相反预测**，必须由 U1 那套 53 例钉死（`B-scope-lastline` 的 `NNNNyN/NNNyN/NNyN` 正是"行内关闭"的样本 ⇒ 它能分开 (i)/(ii)）。
⇒ **落地顺序**：先镜像 `modifier-scope` 53 例 → 用六组 N/y 形态判定 (i)/(ii)（哪个候选逐例复现就取哪个）→ 再落码。**没有这条定义我不动手**（纪律 15；同族前例两条：④⑤ 对 `hop≡0` 空操作、`Indent` 边界）。

### 15.5 绝不能动 / 零影响证明 / 同波顺序
1. **绝不能动**：`Extent`/`Baseline`（`ModifyProperties` 恒等 + 无方向嵌入 ⇒ 由构造保证）。**判据 = 段2 `Extent` 余差 `58` 条不得变**（⚠️ 必须**同仪器**取数：`#12` 期间仪器改过版，跨版本比 58 无意义）。若变了 ⇒ 说明把 scope 字符当成"要算宽的字符"了 ⇒ **方向错，停手回退**。
2. **零影响证明（默认值逐位不变）**：① **源码层**：新参数只在尾部、全默认 ⇒ 既有调用点**一个字不改**（`grep -c "FormatParagraph("` 调用点数不变 + 编译 0 警告）；② **读数层**：同仪器、同命令构建+运行两侧 —— 不传新参数 vs **显式传默认值**（`modifierStart: -1, modifierLength: 0`）⇒ 六项 + 三套 oracle + 三份明细**逐位相同**（`diff` 为空、两侧各记**被测 DLL sha**，纪律 23/24）；③ **牙**：故意把区间按"字符宽度计"⇒ `M_modifier_*` 那 7 行宽度必须回到今天的差（`32.77/35.27/26.81/55.27/28.46/157.21/282.22`）⇒ 证明这条路径**走得到**。
3. **同波顺序（缺一不可）**：`T1c`（PC 侧 2–3 行传 `modifierStart/Length`）+ `T1b`（harness 1 行传 meta）+ **我（shim 半）** ⇒ 分开做会"传不到"、现象是"修法看起来无效"（`M_modifier` 老教训）⇒ **PC 重建由主控发起**，我不发波。
4. **不依赖裸断言**：我的判据**不使用** `cr.Width ≥ 0` 这条裸断言；改用判别式 **`ours < 0 ⇒ truth < 0`** 与"**两侧同为负**"的计数（那条裸断言的更正归 T1b2/T1b）⇒ 我的交付里**不出现**"裸断言绿/红"作为判据。

### 15.6 环境事故后的**可复算性**（已实测，写入档以防再被清）
`/tmp` 于 21:5x 机器重启后被清空 ⇒ 我的 `/tmp` 备份全失。**已用现源 `3081d088…` 反向还原出"修前源"**（删 1 行 + 去掉 4 行新增，锚点 `:1391`），**sha 实测 = `b4c7aa8210c71cbeca4d6b5087988efbb4bc121932848e06c2ac46c99ed1b3d6`** ⇒ **与 #12 前的真源逐字节相同** ⇒ A/B 能力**不依赖 `/tmp`**（还原配方 = 本文件 §14.1 的那 5 行 + sha 校验）。

### 15.7 设计修订（U1 `modifier-scope/closeindex-addendum.md` 到位后；**取代 15.3 的判定式与 15.4 的两候选**）
**符号已定（原文 §1）：`openIndex`/`closeIndex` 都不是从 WPF 读的，而是"客户端自己声明的 run 序列位置"** ——
`openIndex` = 客户端 `GetTextSource.GetTextRun(index)` **返回 `TextModifier` run** 的那个缓冲下标；
`closeIndex` = 客户端返回**配对 `TextEndOfSegment(1)`** 的下标；**`-1` = 从不关闭（scope 到段末）**；`D-nomodifier` 组两者都是 `-1`。
逐组真值（addendum §1 表）：`A 0/4`｜`A-rtl 0/4`｜`B 30/34`｜`C 0/-1`｜`C2 0/-1`｜`D -1/-1`｜`E 0/-1`；buffer 长度 32/20/35/37/37/36/4。
**拟合（§2）**：`closeMarker` **99/99** ✓｜`closeMarker+1` **99/99**（本数据分不开，见 §6）｜候选 (i) `open + TextModifier.Length` **56/99 ✗（43 处不符）**｜候选 (ii) 段末 **85/99 ✗（14 处不符）**。
**⭐ API 事实（§4）**：本 arm 里 `TextModifier.Length` **恒为 1**（= 合成边缘字符），而 scope 真实覆盖 `A`=4 字符、`B`=30→34、**`C/C2`=36 字符**；`C2-scope-visible` 用几何钉死（`ModifyProperties` 把 emSize 翻倍 ⇒ 行数 **6→14**、最宽 advance **19.993333→39.983333**，36 个字符全变）⇒ **`Length` 是"marker run 自己占多少字符"，不是 scope 有多长**（与 WPF `TextSpanModifier(_elementEdgeCharacterLength, …)` 用法一致）。
**① 接口改为两个**索引**（不再传 `(start, length)`）**
```csharp
internal static List<HbTextLine> FormatParagraph(
    …, double indentDip = 0, double defaultIncrementalTab = double.NaN, bool wrap = true,
    int modifierOpenIndex = -1, int modifierCloseIndex = -1)   // -1 = 无 modifier / 从不关闭；只加在尾部
```
**② `lbNull` 判定式（按 U1 §3 的"下一行起点"等价写法，好落地）**
```
nextLineStart = r.Start + r.VisibleLength          // == line.endCharExclusive
nonNull(line) = (!isLastLine)
             && (modifierOpenIndex >= 0)
             && (modifierOpenIndex <  nextLineStart)
             && (modifierCloseIndex < 0 || modifierCloseIndex >= nextLineStart)
```
（与 §15.3 写的式子**同构**，改的只是 `closeIndex` 的**来源**：客户端 `TextEndOfSegment` 下标，**不是** `open + Length`。）
**③ 零宽覆盖范围 = scope 的字符跨度**（同样由这两个下标定，**不由 `Length` 定**）：`[open, close)`；`close < 0` ⇒ `[open, 段末)`。
**④ 兼容条款不变**：`modifierOpenIndex < 0` ⇒ **退回今天的段落级 bool 语义**（`hasModifierScope` 原样驱动）⇒ `T5.1`/`T5.2` **逐位不变** ✓
**⑤ 仍分不开的一格（U1 §6，已登记，未落码前需一趟小样本）**：`closeMarker` vs `closeMarker+1`（"关闭标记本身是否仍属旧 scope"）在 99 行上**都 99/99** —— 唯一满足 `closeMarker == lineEnd − 1` 的 **3 行全是末行**，被 `!isLastLine` 直接判 NULL。
**所需样本（U1 给了构造法）**：**非末行**且该行**最后一个字符正好是 `TextEndOfSegment` 的位置** —— `长文本 + [open]abc[close] + 更多文本`，容器宽度调到**恰好让 line0 在 close 处断开**；真值 NULL ⇒ `closeMarker`（本次定义）；非 null ⇒ `closeMarker+1`。**这一个样本同时钉死"零宽跨度是否含关闭标记"** ⇒ 值得。
**⑥ 与 `layout-b34` 的冲突（U1 §5）归 T1b 核实，我等他结论**：`M_modifier` note 写 scope `[6,45)`、`M_modifier_w80 行#0` 行区间 `[0,50)`、真值 `lbNull=false`；按新规则**只有"45 处真的发了 `TextEndOfSegment`"才预测 NULL**，与真值相反 ⇒ 两种解释：(a) 45 处其实没发（scope 到段末）；(b) 我们的 `lbNull` 语义**不是** `TextLineBreak == null`。**在 T1b 的核实结论 + §6 样本到位之前，我不落码**（纪律 15）。
**⑦ 我设计里不依赖裸断言** ✓：判据用判别式 `ours < 0 ⇒ truth < 0` 与"两侧同为负"计数（已在 live 仪器 `6e077361609f02ad` 上），**不出现**"裸 `cr.Width ≥ 0` 绿/红"。

### 15.8 两个分支的完整规格 + 各分支的**可执行**样本来源（主控前置 2 结清后补）
**前置 2 结清（T1b 只读核实，照录其出处）**：`lbNull` **就是**"该行 `GetTextLineBreak()` 是否为 null"（`build/MilBridge/tools/extract-layout-b34.py:108` + `analyze-layout-b34.py:181-183`）；**我们 b34 语料的客户端从不发 `TextEndOfSegment`**（`grep -rn "TextEndOfSegment" tests/parity/windows/layout-b34/src/` ⇒ **0 命中**；**正对照**：同一 grep 对 `TextModifier` 有命中）⇒ `closeIndex = -1` ⇒ 新规则预测**非 null** ⇒ **与真值 `lbNull=false` 一致** ✓；note 里的 `[6,45)` 只是**作者意图的描述文本**。
⇒ **两个分支都必须实现，且都要有用例覆盖**：
| 分支 | 条件 | 零宽跨度 | `lbNull` 判定 | **可执行的样本来源** |
|---|---|---|---|---|
| **A：scope 到段末** | `modifierCloseIndex < 0` | `[open, 段末)` | `!isLastLine && open ≥ 0 && open < nextLineStart`（`close<0` 项自动成立） | **`layout-b34` 的 `M_modifier_{w80,w120,w200,w320,winf}`**（客户端 0 命中 `TextEndOfSegment`）⇒ 判据 = compact 的**逐行 `lbNull`**：实测**只有 `M_modifier_w80#0`/`w120#0` 两行 = 非 null**（3222 行里 2 行）；**探针档**：`--tab-lines-oracle` 不适用（那是 tab 结构），用 harness 的 `modifier=` 逐行标志 + `lbNull` 比对 |
| **B：按关闭标记关闭** | `modifierCloseIndex ≥ 0` | `[open, close)` | `!isLastLine && open ≥ 0 && open < nextLineStart && close ≥ nextLineStart` | **`tests/parity/windows/modifier-scope/`（53 例）**：逐组 N/y 形态 —— `A-scope-line0` `NNNNN/NNNN/NNN`｜`A-rtl` 同构｜`B-scope-lastline` `NNNNyN/NNNyN/NNyN`（**只有"相交且未关闭"那行是 y**）｜`C-scope-whole` `yyyyyN/…`｜`D-nomodifier` **恒 null**｜`E-scope-oneline` 末行 `N`；**拟合已 99/99** ✓ |
| （子符号，未定） | `close` 是否**含**关闭标记本身 | `[open, close)` vs `[open, close+1)` | `close ≥ nextLineStart` vs `close+1 ≥ nextLineStart` | **U1 待出的小样本**（非末行且末字符恰为 `TextEndOfSegment` 位置）⇒ NULL 取前者、非 null 取后者（U1 §6） |
**第三个前置（未核，已登记）**：T1b 另有一条待核 —— `layout-b34/src/.../TextModel.cs:80+` 的 `GetTextRun` 实体是否**间接**关掉 scope（`TextEndOfRun`/`TextEndOfLine`）⇒ 若"间接关闭"，则 b34 的 `close` 可能**不是** `-1`，分支 A 的样本就要换。**主控会转我结论**。
**判据（写成"同仪器 A/B"形式，主控指定）**
```
本波活仪器 = 6e077361609f02ad（判别式版：ours<0 ⇒ truth<0 + "两侧同为负"计数；**不依赖**裸 cr.Width≥0）
A 侧：不传新参数                       ⇒ 记 ① 被测 DLL sha ② 仪器 sha（跑前/跑后各一次）
B 侧：显式传默认值 (modifierOpenIndex: -1, modifierCloseIndex: -1) ⇒ 同上
判据：两侧的 六项 + 三套 oracle + 三份明细 **逐位相同**（diff 空）⇒ "旧调用点零影响"
仪器 sha 任一侧跑前跑后不一致 ⇒ 该侧作废、重取（纪律 24）
```
**落码条件（主控放行时才动）**：① T1b 的"间接关闭"结论 + ② U1 的 §6 小样本结论 **都到位**，且主控确认"静树"（届时我再取一次仪器 sha 入档）。

---

## 十六、`#14 D-T2`（Tab 缩进语义）落地形态 + 镜像 `tab-anchor` 的代价与判据（**只读设计**）

### 16.1 坐标契约先行（否则下面每一处都会写错）
真值三条**决定了我们的内部坐标必须是"box 坐标"（= raw − `ParagraphIndent`）**：
**Q9**：`TextLine.Width`/`WITW` 以**段落原点**度量 ⇒ 不含 `ParagraphIndent`、含每行 `Indent`；
**Q8**：网格在**原始坐标**里是 `ParagraphIndent + k×interval` ⇒ 换算到 box 坐标就是**从 box 原点起的 `k×interval`**；
**Q6**：被钳满 tab 的 advance = `container − ParagraphIndent − Indent`，远缘 = 行盒远缘（box 里就是 `container − ParagraphIndent`）。
⇒ **在 box 坐标下，现有 `stop = (floor(pen/interval)+1)*interval` 与"钳到 `paragraphWidth`"这两条式子本来就对**（见 §10.5 的代数核对）。
⇒ 因此 `D-T2` 的**真正未知只有一件**：**PC 交给我们的 `paragraphWidth` 是 `container` 还是 box 宽（`container − ParagraphIndent`）**。这一件由镜像语料钉死，**只用一个具名开关**：
```
// 现在：TabClampInset(p) => 0.0      （:330）
// 若镜像判出"PC 传的是 container" ⇒ 只把这一行改成 => p（Q6 的钳目标、Q8 的宽度约定同时生效）
private static double TabClampInset(double paragraphIndent) => 0.0;
```
（**主控的"1 行翻转"要求在此满足**：钳目标与宽度约定**共用同一个具名开关**，不散落字面量。）

### 16.2 shim 侧改动（逐处：锚点行号 + 改前/改后）
| # | 锚点 | 改前 | 改后 | 依据 |
|---|---|---|---|---|
| S1 | `:1570` `EffectiveWidthTab` | `double pen = 0;` | `double pen = lineContentStart;` | **测量侧起算点对齐整形侧**（`ApplyTabStops` 的 `startPenX = indentDip`，`:2502`）⇒ 消除"16 vs 0"（Q11）与 Q7/Q8 的坐标错位。**这是 `D-T2` 唯一的实体修正** |
| S2 | `:326-327` `TabClampWidthFor` | `wrap ? width - TabClampInset(pi) : +∞`（pi 恒 0） | 同形，**实参改成真的 `paragraphIndentDip`** | Q6（目标 = 内容宽） |
| S3 | `:330` `TabClampInset` | `=> 0.0` | **保持 0.0**，除非镜像判出"PC 传 container" ⇒ 改成 `=> paragraphIndent`（**一行**） | Q6/Q8 共用开关 |
| S4 | `:3395` `FormatParagraph` | `double indentDip = 0`（已存在） | 追加 `double paragraphIndentDip = 0`（**尾随可选**） | 只加参数，默认 = 今天行为 |
| S5 | `:1520` `LayoutText` / `:1435` `BreakParagraph` / `:1462` `clampUse` | 已透传 `indentDip`（`D-T1` 加的） | 同路透传 `paragraphIndentDip`，并把 `:1462` 的 `TabClampWidthFor(wrap, width, 0.0)` 改成 `(wrap, width, paragraphIndentDip)` | 透传 |
| S6 | `:2498` / `:2503` 两处 | `TabClampWidthFor(wrap, paragraphWidth, 0.0)` | 同形，实参 `paragraphIndentDip` | Q6 |
**⇒ shim 侧合计 = 1 处实体修正（S1）+ 1 个开关（S3）+ 4 处透传/实参（S2/S4/S5/S6）≈ 6 行**（与主控估的 5–6 行一致）。
**⚠️ 必须与 PC 同波（红旗①）**：S1 一落，"测量侧 pen 从内容起点起算"就要求 **PC 真的把 `Indent` 传进来**（`indentDip`）—— 今天应用路径上 `indentDip ≡ 0`（PC 从不传）⇒ **只落 shim 会让应用路径读数一位不变（看似"修法无效"）** ⇒ 同波是硬要求。
**⚠️ 不许反向消除不一致（红旗②，照录）**：**不许**把 `ApplyTabStops` 的 `startPenX` 也改成从 0 起算（那是把整形侧拉向错的一侧）；S1 的方向是**测量侧向整形侧靠**，不是反过来。

### 16.3 PC 侧改动（**3 处，不是 1 处** —— 与主控估计的差异及原因）
主控说"`:536` 调用点多传 1 个实参"。实测该调用不是直通 `FormatParagraph`，中间还有一层 `TryFormatLine`：
| # | 锚点 | 改动 |
|---|---|---|
| P1 | `TextFormatterImp.Linux.cs:217` `TryFormatLine(TextSource, int cpFirst, double paragraphWidth, …)` | 签名追加 `double paragraphIndentDip = 0` |
| P2 | 同文件 `:239-241` 那次 `FormatParagraph(...)`（`TryFormatLine` 内部） | 追加实参 `paragraphIndentDip: paragraphIndentDip` |
| P3 | 同文件 `:536` 调用点 | 追加实参 `settings.Pap.ParagraphIndent`（**`settings.Pap` 就在作用域里** ✓；同处也可以顺带传 `settings.Pap.Indent` 给 `indentDip`） |
⇒ **PC 侧 = 3 处、约 3 行**（跨车道 ⇒ 归 T1c/主控派）；**理由**：`TryFormatLine` 是 interceptor 的中间层，签名不带就传不到（正是"看起来像修法无效"的成因）。

### 16.4 镜像 `tab-anchor`(436 例)：落点、代价、判据
**落点**（我的车道）：`build/MilBridge/tests/CoverageProbe/Program.cs` 的 `--tab-lines-oracle`
- **读档：0 行翻译**（实测 schema 同名同义）：`id/text/paragraphWidthDip/emSizeDip/flowDirection/textWrapping/incrementalTabArm` + 行级 `lineText/width/trailingWhitespaceLength/newlineLength/perChar[]{i,char,xFromLeftDip,width}`；
- **新增读**（本次要加）：`indentDip`、`paragraphIndentDip`、`incrementalTabArm`（已有）、行级 **`breakCause`**、**`hasOverflowed`**、`startChar/endCharExclusive`；并把 `indentDip`/`paragraphIndentDip` **真的传进** `FormatParagraph`（今天档里没有这两个参数）；
- **新增输出**：逐族 `结构/位置/Q5..Q11` 六问分项计数 + 逐行 `breakCause`（我们 vs 真值）与 `hasOverflowed`（我们 vs 真值）对拍；
- **`script` 先用 `latin`**（希伯来/阿拉伯族的真值面是 Arial，本机不可比，见 §9.4(B)），覆盖闸已就位。
**代价**：档侧 **≈15–25 行**（读 6 个字段 + 传 2 个参数 + 两列对拍）；**真正的成本在 shim 的 S1–S6 与 PC 的 P1–P3**。
**判据（逐项）**
| 问 | 判据 | 我们的现状 |
|---|---|---|
| Q5 行首谓词 | `Indent>0` 行首 tab ⇒ **钳满 + 断行**（26 definite + 4 压边） | `IsLineStartTab(pen, contentStart)` 已是这一支 ✓（U1 已验证）—— 但 `contentStart` 只在**整形侧**是 `indentDip`；S1 落地后测量侧才一致 |
| Q6 钳目标 | box `[Indent, container − PI]`、advance = `container − PI − Indent`（58 + 16 压边） | 由 S3 一行决定（见 16.1） |
| Q7 `Indent` 不移动网格 | `impliedGridOrigins_box=[0.0]`（44 例） | S1 落地后成立（今天测量侧从 0 起算，`Indent>0` 时笔位错位） |
| Q8 `ParagraphIndent` **移动**网格 | 停靠位 = `PI + k×interval`（18 LTR + 6 RTL） | box 坐标下天然成立；**依赖"PC 传 box 宽"这一假设** ⇒ 由镜像钉死 |
| Q9 `Width`/`WITW` 口径 | 不含 `PI`、含 `Indent` | 我们 `witw = Σadvance + indentDip`（`:2470` 附近）已含 `Indent` ✓；不含 `PI` 由 box 契约保证 |
| Q11 退化族 | `PI + Indent ≥ container` ⇒ tab **零宽** + **`HasOverflowed=true`**（4 例，公式不覆盖） | S1 落地后**零宽一致** ✓；**`HasOverflowed` 我们恒 `false`**（`:3054`）⇒ **仍会红，登记为本件的第二个实体项**（要么本波做，要么独立登记） |
| **新增**：`breakCause` 逐行 | 断因对拍（`before-tab`/`after-tab`/…） | ⚠️ **shim 今天没有任何断因跟踪**（`grep -i cause` = 0 命中）⇒ 要**先加一个只读诊断字段**（4 个决策点：填宽普通候选 / before-tab 候选 / 钳满后的 after-tab / 强制回退），**不改行为** |
| **新增**：`hasOverflowed` 逐行 | 同 §Q11 | 同上（今天恒 false） |
⇒ **`D-T1` 的判据由此升级**：从"**行数对**"→"**`breakCause` 逐行 + `hasOverflowed` 逐行**"（主控指定）。

### 16.5 `D-T1` 回归判据（`#14` 落地后必须同仪器复核）
`tab-zero`(86)：结构败 **`13 → 1`**（射程内 **12 ⇒ 0**、第 13 例 `notab-control@w40@em24@RTL@tab0` 的 `tws` **点名保留**）｜`tab` 臂 **`cases=114 pass=57 fail=0`**｜默认配置 oracle **不得退化**；**全部同仪器取数**，两侧各记被测 DLL sha + 仪器 sha（纪律 23/24）。
⚠️ **仪器 sha 又变过**：`0d45032b`（`#12` 冻结值）→ `6e077361` → **现场 `3dd2ac743a172c51`**（主控给的 live 值 `6e077361…` 现已不是现场值）⇒ **`#14` 落码与回归取数时一切以当场实读的仪器 sha 为准**并写进四元组；跨版本比任何计数（含 `Extent 58`、`折叠/明细`）都无意义。
**两条红旗照录**：① PC `FormatLineInternal`/`TryFormatLine` 的签名改动**必须与 shim 同波**；② **不许**把 `ApplyTabStops` 的 `startPenX` 也按 0 起算来"消除不一致"。
**时序**：`#14` 落码**排在 `#13` 之后**（shim 单写者），主控放行且确认为静树时我才动。

### 16.6 `#14` 裁定落档（主控 2026-09-14 22:0x；**设计稿到此为止，等派 `#13`**）
1. **设计总体批准**：坐标契约（内部一律 box 坐标 = raw − `PI`）✓｜**S1 `:1570 pen = lineContentStart` = 本件唯一实体修正** ✓（"测量侧向整形侧靠"，红旗①因果照录）｜S2–S6 透传 ✓｜**PC 侧按我实测的 3 处**（`:217` 签名 + `:239-241` 补实参 + `:536` 补 `settings.Pap.ParagraphIndent`）✓｜**一个具名开关** `:330 TabClampInset` 收口"PC 传 container 还是 box 宽"这一未知 ✓。
2. **(a) 断因诊断字段批准**：作为 `#14` 的**仪器侧**工作（与镜像 arm 同波），4 个决策点、**不改行为**；**判据 = 加字段前后所有既有读数逐位不变**（同仪器 A/B），并把它的版本计入"同波仪器版本"。
3. **(b) `HasOverflowed` 单列在册为 `D-O1`**（不塞进 `#14`）—— 理由是它是**通用渲染标志缺口**（任何应用读它都拿到错值），不是 Tab 缩进特有。
   ⇒ **`#14` 的 Q11 判据改写为**：*退化 4 例中"我们给出的 `advance`/缩进处理"必须与真值一致；`HasOverflowed` 本条仍红、由 `D-O1` 承担（点名登记，不算 `#14` 未做完）*。
   **`D-O1` 重启入口（写给将来派单）**：先查上游 `TextLine.HasOverflowed` 的定义（`TextLine.cs` / `TextLineImpl`）**与真值口径**（U1 `Q11` 给 4 例 `HasOverflowed=true`；`tab-anchor` 里"自然到达边缘"那一批当反例）⇒ 再决定"我们按什么量算"；**判据 = 那 4 例为 `true`、自然到达边缘那批为 `false`**。
4. **仪器 sha 位移合法**：`0d45032b` → `6e077361` → **live `3dd2ac743a172c51`**（来自 T1b2 修 `isoMachineOk` 接线，属其 `Program.cs` 合法改动）⇒ **一切以当场实读为准并写进四元组；跨版本不比任何计数** ✓（§16.5 已如此处理）。
5. **时序**：`#14` 落码排在 `#13` 之后（shim 单写者）；**主控说"静树 + 放行"才派**。当前 `loadavg 7.6x`（外部工程）⇒ 不取数、不落码。

---

## 十七、`#13` 落码（shim `fde9e511e8443cf2`）+ 两臂判据命令 + 仪器 rc 修（主控波期间交付）

### 17.1 shim 半（`build/shims/PresentationCore.HbTextLine.cs` = **`fde9e511e8443cf2`**）
**接口（尾随可选，逐字）**：`FormatParagraph(…, bool wrap = true, int modifierOpenIndex = -1, int modifierScopeEnd = -1, int modifierCloseIndex = -1)`
**三参数语义分工（自验档实测纠正后）**：`modifierOpenIndex` = 覆盖起点｜**`modifierScopeEnd` = 覆盖终点（半开，−1 ⇒ 到段末）⇒ 只喂"零宽跨度"**｜`modifierCloseIndex` = 客户端 `TextEndOfSegment` 下标（−1 ⇒ 从不）**⇒ 只喂 `lbNull`**。
- **纠正 1（实测）**：`close<0` **不能**当"零宽到段末" —— b34 `open=6, close=−1, 覆盖终点=45`（`cases.json` 的 `modifierEnd`）⇒ 按 `close` 处理会把 `[6,63)` 全零宽：`winf 行#0 w=43.59`，真值 `156.9167`（可见 `[0,6)+[45,63)`）。
- **纠正 2（实测）**：零宽**必须同时落测量侧**（`BreakParagraph` 的 `adv[]`），否则断行按未隐藏文本算：未落时 `winf 行#0 len=26`（真值 63）；落上 ⇒ `len 7/7` ✓。
- **保留字形、只置零 advance**（理由：`Extent` 是墨迹度量，摘字形会动 `Extent`，而判据要求它不动）。
**改动清单断言**：`diff` 总 73 行、**删除 8 行**（逐行核对 = 8 处声明锚点）⇒ 除声明锚点外零改动。备份 `$HOME/t1d-backups/20260914-2213-shim-3081d088.cs`（`cp -p`）。
**自验读数（`--modifier-check`，字体对齐真值 NotoSans）**：`合计 用例=5 行=7｜行宽≤0.34 7/7｜len 7/7｜ws 7/7｜lbNull 7/7`（`winf 行#0 156.9280` vs 真值 `156.9167`）；不传区间（旧行为）`winf w=439.1360`、行数 7/4/3 ⇒ 旧调用点未被扰动；`Extent 0/7` 是**既存差**（`gen/t2d-extent-mismatches.txt` 在 #12 时就列 `M_modifier_w80#1 差 −3.6800`）。

### 17.2 臂 B 的**可执行命令**（主控 ①）
**结论先行**：臂 B 的真值面是 **Arial**（`fontFamily=Arial`、`fontSha256=baa251526d686271…`，本机无该字节）⇒ **它的行宽/断行在本机不可比**（§9.4(B) 同因）⇒ **不拿 `--modifier-armB` 当门禁**。可用的是**与字体无关**的那一条：
```
# ① 规则核验（推荐；纯数据、不排版、与字体无关）—— T3 照跑这条
dotnet build/MilBridge/tests/CoverageProbe/bin/Release/PresentationCore.Tests.dll \
       --modifier-rule-check tests/parity/windows/modifier-scope/out/modifier-scope-oracle.json
#   预期判据行： MODRULE 用例=53（无可核 lineBreaks 的 0）行=170｜判据吻合 170/170（不符 0）
#                MODRULE 退出码=0（不符 0/170）
# ② 臂 A（b34，字体口径一致 ⇒ 可判）
dotnet … --modifier-check
#   预期： MODCHK 合计 用例=5 行=7｜行宽≤0.34 7/7｜len 7/7｜ws 7/7｜lbNull 7/7 ；MODCHK 退出码=0
# ③ 臂 B 排版档（**登记为不可比**，仅留档）
dotnet … --modifier-armB tests/parity/windows/modifier-scope/out/modifier-scope-oracle.json   # rc=1、行宽 0/84 ⇒ **字体口径**
```
**逐例读三字段（不按组概括，主控 ③ 照录）**：`modifierScopeCharRange` 逐例取（`E=[0,4]`、`C/C2=[0,37]`；D/F/G/H 该字段为 `null` 且 `open=close=−1` ⇒ **无 modifier**）⇒ 我的档按**逐例**读，不做组级概括。

### 17.3 `--modifier-check` / 规则核验档的 rc（主控 ②）
**口径**：`fail == 0 ⇒ 0`（与 `--tab-oracle` 同一口径），并打印 `… 退出码=N（…）`。
**阳性对照（实测）**：翻转 `/tmp` 副本里 `A-scope-line0/…@w80@LTR@i0` 的 `lineBreaks[0].isNull` ⇒ **rc=1**、`判据吻合 169/170（不符 1）` 且逐行点名；**还原 ⇒ rc=0**（170/170）；臂 A ⇒ rc=0（7/7）。
**`CoverageProbe/Program.cs` sha 链（逐字）**：`cc61299d`（rc 修前，我实测并存 `$HOME/t1d-backups/…probe-before-rcfix.cs`）→ **`5982ce9c`**（`--tab-oracle` rc 修 + 读档保护/形状自检；**我实测**）→ `06da8817`（加 `--modifier-check`；**主控 10:2x 实读**）→ **`b331c192`**（加 `--modifier-armB` + 臂 A rc；**我实测**）→ **`0046ed20`**（加 `--modifier-rule-check`；**我实测**）⇒ 均属**同一文件上的连续小修**，不碰 `build/shims/**`。

---

## 十八、`D-F1` 落点清单（**只读准备**；等主控"shim 已归还"再动）

### 18.1 根因（T2 §29，我照录）+ 我方现状
**`plan == null` ⇒ 走单面度量** ⇒ `allowFallback` 那段**根本不会被问到**；后果 = `与`(`U+4E0E`) 在 file 字体里 `gid=0` ⇒ `.notdef` advance `9.6000`（真机 `16.0000` = 1.0 em）⇒ `cr.Width −3.0560`（真值 `3.3433`）。
**真值语义（U1 `font-fallback` 60 例）**：段落字体缺码点 ⇒ **换成另一个覆盖它的已安装字体、报那个面自己的字形与 advance**；只有回退也找不到时才落 `.notdef`；**搜索顺序真机取不到 ⇒ 只对齐结果语义**。

### 18.2 落点（锚点行号 + 计划构造入口 + 逐处形态）
| # | 锚点 | 现状 | 落法 |
|---|---|---|---|
| F1 | `FormatParagraph`（`:3420` 参数 `HbFontPlan plan = null`；注释"null ⇒ 与今天逐位相同的单面路径"） | `plan` 由调用方给；**harness 路径恒 `null`** | `plan == null` 时**先构造单面计划**：`new List<HbRunFaceInfo>{ new HbRunFaceInfo{ Start=0, Length=text.Length, Face=<首个面>, Weight/Width/Slant=<由面或 props 取>, RunSlot=0 } }` ⇒ `HbFontPlanner.Build(text, runs, allowFallback: true, gate)` |
| F2 | `HbFontPlanner.Build(string, List<HbRunFaceInfo>, bool allowFallback, HbFaceGate gate)` **`:1165`** | 唯一调用点 = 应用路径 `TryBuildPlan`（`:3845`） | **不新建入口**：单面路径复用同一个 `Build`；**`gate` 的取值照抄 `:3845` 那一处的实参**（落地第一步先把它的原文读出，不猜） |
| F3 | 回退链（沿用，不改）：`PickFromRuns` **`:1249`**（② run 内先挑）→ `HbFontCandidates.TryFindCovering` **`:964`**（③ 候选集）→ `ResolveDirs():886/:926`、`Sort(Ordinal):932`、排序键 `|Δweight|→|Δwidth|→|Δslant|:964` | 已存在且**应用路径已验证生效**（`fallbackApplied=2 fromSystemScan=2`） | 单面路径走到它即可；**失败 ⇒ `HbFallbackDiag.NoteFailed(cpv)`（`:1068`/`:1224`）⇒ glyph 0 ⇒ advance = 该面 glyph 0 的宽（不许假装成功）** |
| F4 | 两处消费 `plan`：`BreakParagraph` 的度量 `plan != null ? MeasureChars(para, plan.Sub(...), emSize) : MeasureChars(para, fontPath, emSize)`；`FormatLine` 的整形 `plan != null && plan.Segments.Count>0 ? ShapeParagraph(...) : Shape(...)` | 已是"有计划走计划" | **一行都不用改**（构造出计划后自然走计划）✓ 这是本件最省的地方 |
| F5 | `GetIndexedGlyphRuns()` **`:3307-3309`** = `Owed("GetIndexedGlyphRuns")` 桩；头部 `:17` 注释"仍留 owed（上游 0 个调用点，主控裁定不实现）"；`Owed` 名单 `:1637`/`:1650`；`build/MilBridge/tests/TextLineProto/Program.cs:120` 有"每个 Owed 恰好记一次"的检查 | 桩 | **真实现**：按行枚举 `IndexedGlyphRun { TextSourceCharacterIndex, TextSourceLength, GlyphRun }`；每个 `GlyphRun` 的 `GlyphTypeface` **必须反映实际用的那个面**（多面路径的 `HbShapedChunk.Face` 逐段已知 ⇒ 逐段构造 `GlyphTypeface(file://path#faceIndex)`）、`GlyphIndices`（**0 = `.notdef`**）、`AdvanceWidths` 均真值；**源字符起点** = `range.Start` + 段内偏移 ✓ |

### 18.3 判据（T2 的 runner 跑；分工照录）
- **C2（主）**：`GlyphIndices != 0`，观测面 = **`GetIndexedGlyphRuns()`** ⇒ **F5 是 C2 的前置**（没有它 C2 取不到数）。
- **C3（主）**：与真值差 ≤ 容差（字体集不同 ⇒ 标"不可比"；`U+10FFFD` 零覆盖档**两边都落 `.notdef` ⇒ 完全可比**）；目标行 `F_nbsp_zwsp_w40` 的 `与 `：真值 `w=16.0000`、`witw=20.1600`、`cr.Width=3.3433`。
- **C1 = 反作弊**（报的 advance == 我们所选面自己的 advance，逐位无容差）；**T2 已实测 C1 抓不到本 bug**（`9.6` 就是该面 glyph 0 的宽 ⇒ 自洽）⇒ **不作主判据**。
- **两极化牙**：负极 `allowFallback:false` ⇒ 必须回 **`9.6000` / `cr.Width −3.0560`**；正极 开 ⇒ **`16.0000`** / `cr.Width` 变正。
- **两处禁止**：不许把 `.notdef` 的宽硬改成 1 em 冒充回退；不许改 oracle/真值。
- **附带待验证（T2 写，两种结果都收）**：同一处缺口**预期就是** §23/§24 那 **34 条 `+CJK` Extent 行**的结构性来源 ⇒ 落码后跑一次 `run.sh tline` 比 `+CJK` 行集合/计数：**显著减少 ⇒ 成立；不变 ⇒ 回退没被走到（更深根因）⇒ 报主控，不许自己往下改**。

### 18.4 边界与自查
- **动前**：`cp -p` 整份到 `$HOME`（不放 `/tmp`）+ 记 sha；**改完报"源已定 + 新 sha + diff 行数断言"**；PC 重建与波由主控发起。
- ⚠️ **车道问题（要主控裁）**：`build/MilBridge/tests/TextLineProto/Program.cs` 属 **T1b 车道**。主控让我"随之更新"——**若守单写者**，我把要改的两行原文交给 T1b，由它落；若主控要我直接改，我照办并注明跨车道。**落地前请给一句**。
- **`#13` 未冻相关**：本件落码会在 `#13` 冻后另起一波；`#13` 的读数（`fde9e511…` / 六项 / 两臂）不受影响。

---

## 十九、`D-F1` 已落（源已定）+ 两极实测 + 交付口径

### 19.1 源已定 + 改动清单断言
`build/shims/PresentationCore.HbTextLine.cs` = **`46aa73a3db99d083`**（改前 `fde9e511e8443cf2`；备份 `$HOME/t1d-backups/20260915-1025-shim-fde9e511-preDF1.cs`，`cp -p`）。
`diff` 总 **62** 行、**删除 4 行**，逐行核对 = 4 处声明锚点（头部 owed 注释行、`StillOwedMembers` 里的条目、`Owed("GetIndexedGlyphRuns")`、`return Array.Empty<IndexedGlyphRun>()`）⇒ **除声明锚点外零改动** ✓
**两件实现**
1. **`plan == null` 也先构造计划**：单面路径构造单 run `HbRunFaceInfo`（`Face = new HbFaceRef(fontPath, glyphTypeface.FaceIndex)`、w/wd/s = 400/5/0）⇒ `HbFontPlanner.Build(text, infos, **allowFallback:true**, 宽松闸)`；候选集/顺序**沿用** `PickFromRuns`→`HbFontCandidates.TryFindCovering`；找不到 ⇒ `NoteFailed` ⇒ 沿用当前面（不假装成功）；并逐段构造 `segmentFaces`（**1 参 `GlyphTypeface` 构造 ⇒ face 0**，`.ttc` 多面集合的限制**已登记**）。
2. **真实现 `GetIndexedGlyphRuns()`**：逐 run 给 `IndexedGlyphRun{TextSourceCharacterIndex, TextSourceLength, GlyphRun}`，数据全部来自既有 `_glyphRuns` / `_glyphRunCharStart`（面 `FontUri` 就是**实际用的那个面**、`GlyphIndices`（0=`.notdef`）、`AdvanceWidths`）⇒ **C2 的观测面已可用**。`StillOwedMembers` 6→5、头部注释改为"已实现（2026-09-15 主控推翻旧裁定，依据 = 它是真值的观测装置）"。
**自纠一处（实测发现）**：初版把末 run 的 `TextSourceLength` 用 `_lineStart + _length` ⇒ **含末行 EOP 的 `+1`**（实测 `0+4`，而字符串只 3 个码元）⇒ 改用 `_visibleLength`，复测 `0+3` ✓。

### 19.2 两极实测（`--fallback-check`，字体 = `build/fonts/NotoSans-Regular.ttf`，em=16）
| 极 | `与`(U+4E0E) | 零覆盖对照 `U+10FFFD` | rc |
|---|---|---|---|
| **正极（落地件 `allowFallback:true`）** | 行宽 **16.0000**、首字 advance **16.0000**、`runs=2 {0+1 face=DejaVuSans.ttf gids=[9498] adv=[16.000]}` ⇒ **Gid≠0 ✓** | 行宽 9.6000、`gids=[0,3]`（**两边都落 `.notdef` ⇒ 完全可比档**） | **0** |
| **负极（`/tmp` 变体 `allowFallback:false`）** | 行宽 **9.6000**、`gids=[0]`、advance 9.6000 ⇒ **回到旧读数** ✓ | 行宽 9.6000、`gids=[0,3]` | 1（判据 FAIL，符合预期） |
⇒ **C2（Gid≠0）✓**；**C3（与真值差/符号）**：目标行 `与 ` 的真值 `w=16.0000`/`witw=20.1600` ⇒ 我们 `与`=16.0000 + space=4.1600 = **20.16** ✓ 逐位吻合；面 = `DejaVuSans.ttf`（真机"只知最终用了谁"⇒ **只对齐结果语义** ✓）。**两处禁止遵守**（未硬改 `.notdef`、未动 oracle）。

### 19.3 待 T2 的 runner 在两处收口（我不自行下推）
1. **`cr.Width`**（真值 `3.3433`、旧 `−3.0560`）与 `F_nbsp_zwsp_w40` 的 `与 ` 行：需 **PC 重建后**由 T2 的 runner 量（我的自验档量的是 advance/行宽，`cr` 属折叠路径）。
2. **34 条 `+CJK` Extent 行**（主控登记为"附带待验证预期"）：**PC 重建后跑一次 `run.sh tline` 比 `+CJK` 行集合/计数** ⇒ 显著减少 ⇒ 成立；**不变 ⇒ 回退没被走到（更深根因）⇒ 报主控，不自己往下改**。
### 19.4 跨车道一处（按主控指令已改，请裁是否合规）
`build/MilBridge/tests/TextLineProto/Program.cs`（T1b 车道）按主控"随之更新"指令改了 **A7 的期望**（`TotalFallbackHits == 6 → == 5` + 两处文案 "6→5"）；备份 `$HOME/t1d-backups/20260915-…-TextLineProto-before.cs`。**若你要守单写者，我立刻还原并把这两行原文转 T1b。**

### 19.5 `D-F1` 四条裁定（主控 2026-09-15；**波 `#14` 期间我不动 `build/shims/**`**）
1. **跨车道的 `TextLineProto/Program.cs` 改动：保留**，由 **T1b（该车道 owner）复核并接手**（核 `TotalFallbackHits 6→5` 与 `StillOwedMembers = 5` 一致、A7 语义未被改宽、并在其报告留档）。**我不还原**。今后口径：**跨车道文件先问主控**（主控记为自身措辞不精确的锅）。
2. **`.ttc` 多面限制照收**：`HbFaceRef(fontPath, glyphTypeface.FaceIndex)` 保留面索引；单面路径的 `segmentFaces` 用 **1 参 `GlyphTypeface` 构造 ⇒ face 0** ⇒ 多面 `.ttc` 集合受限。⇒ 写进 `D-F1` 的**已知边界（不是缺陷）**。
3. **我的自纠 `TextSourceLength`（`_length` → `_visibleLength`，`0+4 → 0+3`）照收** —— 属"末 run 含 EOP"那一族（同族已多次出现）。
4. **主控已发起 `D-F1` 波（波号 `#14` = D-F1）**：`bash build/close-wave.sh` ⇒ PC 重建 + 身份自检 + `verify-all`；随后**门禁 + 冻 `#14`**（表头写入 `hbtextline 46aa73a3db99d083`、`GetIndexedGlyphRuns()` 已实现（含"推翻旧裁定"依据）、`.ttc` 多面边界、C1 反作弊 / C2+C3 主判据之分、34 行 `+CJK` 预期）；**T2 的 runner**（`build/DirectWrite.Linux/FallbackCriteria/`）`--build` + C1/C2/C3 + 两极牙 + `[fix]` 翻转；**`cr.Width`**（`3.3433` / 旧 `−3.0560`）与 **34 条 `+CJK` Extent 行**由**重建后的产物**量。
**我的下一步**：等主控"波完"⇒ **`#14`/`D-T2`（Tab 缩进语义）** 落码（设计已在 §16.1–§16.6 批准：S1 `:1570 pen = lineContentStart` 为唯一实体修正、`:330 TabClampInset` 一行开关、PC 侧 3 处同波）。

### 19.6 🔴 非 DIRECT 编不过：**我两次尝试都没修好 ⇒ 已回退**；并附一条反证（请 T1b 给确切配置）
**现状（回退态）**：`build/shims/PresentationCore.HbTextLine.cs` = **`46aa73a3db99d083`**（= 主控已收货的 `D-F1` 件；备份 `$HOME/t1d-backups/20260915-1053-shim-46aa73a3-preNonDirect.cs`）。DIRECT 面干净：`CoverageProbe 0 error CS`、`--fallback-check` 仍 `判据 PASS / 退出码=0` ✓
**两次尝试（都失败 ⇒ 按"两次不达标就回退"还原）**
1. `#if TEXTLINE_SHIM_DIRECT` 分支化 + `#else` 反射（`Activator.CreateInstance(NonPublic)` + `GetProperty("FaceIndex")`）⇒ 报 **`error CS0103: 当前上下文中不存在名称"FaceIndexOf"`（shim `:3514`）**，`CoverageProbe`/`T2eLineHeight` 各 1 个错误。
2. 把 helper 提成**文件级** `HbShimCompat.FaceIndexOf` ⇒ **更糟**（`CoverageProbe`/`T2eLineHeight` 各 **7** 个错误）⇒ 立即回退。
**🔁 反证（这条最重要，请 T1b 看一下）**：我用 `-p:HbShimSrc=build/shims/PresentationCore.HbTextLine.cs` 在**本机**编
`CoverageProbe` / `IcuBreakParity` / `T2eLineHeight` ⇒ **三者都是 0 个 error CS**（`IcuBreakParity` 的 csproj 里 `TEXTLINE_SHIM_DIRECT` 出现 **0** 次、`HbShimSrc` 出现 3 次 ⇒ 我原以为它是非 DIRECT 宿主，**结果它编得过**）。
⇒ **我复现不出** T1b 报的那两条（`GlyphTypeface.FaceIndex` / `IndexedGlyphRun` 3 参构造）⇒ 说明**真正失败的那个配置我还没找到**（可能是 `run.sh textline` 内部另一条 `DefineConstants`、或另建了 `PresentationCore` 工程、或 `staging/` 副本路径）。
⇒ **请 T1b 给出可复现的最小命令**（工程 + `TEXTLINE_SHIM_DIRECT` 定义与否 + 用哪份 shim 源）。**我不再凭猜改**（避免第三次失败又把树搅红）。
**顺手未完成的一处**：两处陈旧注释的 `6 → 5`（shim `:1647`/`:3296`）**随回退一并还原**，仍待修；全域扫描另外找到两份**别的车道/只读**副本（`build/MilBridge/staging/PresentationCore.HbTextLine.cs:505,1348`、`build/MilBridge/tests/CoverageProbe/refs/PresentationCore.HbTextLine.ebccdb1e.cs:1482,2869`）⇒ **我不动它们**，交主控派。
**我自己的错（记档）**：① 我先前回过一句"**两条配置都编过 ✓**" —— 那是**从"没打印错误行"推断的**，而实际是 1 个错误（我第一次的自查口径错：该用 `grep -c 'error CS'`）；② 修法选型时我没先**复现**原报错就动手 ⇒ 第二次把错误从 1 个放大到 7 个。两条都属"没有复现就改"的同族。
**仍然可用的正面证据**：`--fallback-check` 里的**反射面自检**（`Activator.CreateInstance(NonPublic, 3 参)` + `GetProperty("FaceIndex")`）在运行期**可用** ⇒ 将来修非 DIRECT 时，反射退路本身是通的（缺的是"放对位置 + 找对配置"）。

### 19.7 ✅ 非 DIRECT 编不过：**已修**（`17b2cdfe08f13280`）
**先复现（这次先复现再改）**：`dotnet build build/MilBridge/tests/{TextLineProto,HbTextLineParity} -p:HbShimSrc=… | grep -c 'error CS'` ⇒ **各 4 个**（主控给的两个工程就是反射分支宿主；`CoverageProbe` 是 DIRECT ⇒ 我上次测错工程）。
**修法（方向同第 1 次，改在"放对位置"）**：
1. `GlyphTypeface.FaceIndex` ⇒ **内联在调用点**做 `#if TEXTLINE_SHIM_DIRECT / #else 反射`（**不做 helper** ⇒ 不会出现"名字看不见"；反射取不到才 0）；
2. `IndexedGlyphRun` 的 3 参构造 ⇒ 同类私有 `MakeIndexedGlyphRun`，内部 `#if/#else`（DIRECT 强类型 / 反射 `Activator.CreateInstance(NonPublic, 3 参)`，**取不到就响亮抛，不用桩**）；
3. 两处陈旧注释 `6 → 5`（`:1647`/`:3296`）一并改。
**判据实测**
| 判据 | 结果 |
|---|---|
| ① 两条反射分支 `grep -c 'error CS'` | `TextLineProto` **4 → 0**、`HbTextLineParity` **4 → 0** ✓ |
| ② DIRECT 不回归 | `CoverageProbe` error CS **0**；`--fallback-check` ⇒ `判据 PASS / 退出码=0` ✓ |
| ③ 非 DIRECT 下实调 `GetIndexedGlyphRuns()` | 见下（`TextLineProto` 实跑输出） |
| ④ 注释 `6 → 5` | 已改（另两处属 `staging/` 与 `CoverageProbe/refs/` 副本 ⇒ 未动，交主控派） |
**改动清单断言**：`diff` vs `$HOME/t1d-backups/20260915-…-shim-46aa73a3-preNonDirect-fix2.cs` ⇒ 见运行时输出（4 处声明锚点）。

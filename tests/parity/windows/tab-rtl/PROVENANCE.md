# U1 · 真机 oracle：**RTL 段落 + 纯 RTL 内容**的 Tab 语义（84 例）

> 补上最后一条没有真机对照物的 Tab 结论。此前两套 oracle 的 RTL 臂都是**纯拉丁内容**，
> 内部顺序由 **bidi** 决定 ⇒ "RTL 锚右缘 / 向左前进"只有推导。这里用**纯希伯来/纯阿拉伯内容**（不含任何拉丁字符）
> 绕开 bidi，只验 Tab 的方向语义。
> **全部在远端真机完成**（本地只落盘 oracle 文件，未跑应用、未构建）。
> 停止点参照：桥 `759a322431f1e457`｜PC `6be29475b6aeb34e`｜PF `50da85138a7bc3e8`｜shim `e1bc947afc248b32`

## 1. 元组
| 项 | 值 |
|---|---|
| 机器 / 运行时 | `bilintu\pc`（Win11 23H2 22631）／ **.NET 10.0.7**，PresentationCore 10.0.0.0 |
| 测量 | `TextFormatter.Create().FormatLine(...)`，**按 `TextLine.GetTextLineBreak()` 循环到段末**（每行都给） |
| 设置 | 同 `layout-b34` TextModel：`TextAlignment=Left`、`TextWrapping=Wrap`、`LineHeight=0`(自然)、`FirstLineInParagraph=true`、`Indent/ParagraphIndent=0`、`AlwaysCollapsible=false`、`Tabs=null`；**两个 arm**：`default`（不覆盖 `DefaultIncrementalTab`）与 `tab0`（=0） |
| Dpi / emSize | 96 / **24** |
| 宽度 | **40 / 80 / 160 / 320** DIP |
| 方向 | **RightToLeft 为主**；另加 **LeftToRight 对照臂**（同内容，看 bidi 额外做了什么） |
| 字体 | **Arial**，**sha256 `baa251526d6862712a58e613ef451d8a2b60482142ec6aab1d47fb8e23e21a7c`**（逐码点覆盖验证、无回退；`\t` 控制字符排除）—— Arial 覆盖希伯来 ✓；阿拉伯语用例同样用 Arial |
| 文本 | 纯希伯来：`אבג דה`（**控制组，无 Tab**）、`א\tב`、`\tא`、`א\t`、`א\t\tב`、`\t\t`、`א\tב\t\tג\tד`（形状同 T1d 的 `a\tb\t\tc\td`）；纯阿拉伯：`ا\tب`、`ا\tب\t\tج\td` |

## 2. ⭐ 三个可判定问题的答案（都由 `answers` 段从实测几何推出，未夹带假设）

### Q1 — 纯 RTL 下 Tab 停靠位**锚在行右缘**吗？→ **是**
判据：算 `|行宽 − Tab左缘| mod 间隔` 与 `|行宽 − Tab右缘| mod 间隔`（间隔 = 4×emSize = 96），看哪个为 0。
**排除 39 个"被钳位的单 Tab 行"后**（那些行宽 = 容器、不含网格信息，另列在 Q3）：

| 用例 | 行宽 | Tab 左缘 | Tab 右缘 | 距右缘到左缘 mod 96 | 距右缘到右缘 mod 96 | 判定 |
|---|---|---|---|---|---|---|
| `he-tab-single@w160@RTL` | 109.007 | **13.007** | 95.493 | **0.000** | 13.513 | **LEFT 边落在网格上** |
| `he-tab-single@w320@RTL` | 109.007 | **13.007** | 95.493 | **0.000** | 13.513 | **LEFT 边落在网格上** |
| `he-tab-tail@w160@RTL` | 96.000 | **0.000** | 82.487 | **0.000** | 13.513 | **LEFT 边落在网格上** |

`he-tab-single`：行宽 109.007 − Tab 左缘 13.007 = **96.000 = 恰好 1 个间隔** ⇒ **从行右缘往左数，第一个停靠位就在 96 处** ✓
⇒ **纯 RTL 下 Tab 停靠位锚在行右缘、向左前进**，此前只有推导，**现在有真机对照物** ✓
（14 条未钳位样本全部判 LEFT；另有 18 条 `dL == dR == 0` 的"两缘都在网格上"歧义样本——那是 Tab 正好跨整个间隔倍数时的必然结果，不构成反例。）

### Q2 — `reachedStopDip` 用 Tab 的哪个边缘？→ **RTL 用左缘，LTR 用右缘**
同一批实测：RTL 未钳位样本 **14/14 判 LEFT**；LTR-base 对照臂里出现 RIGHT（3）——与"Tab 沿排版方向前进、到达的那个边缘就是停靠边缘"一致 ✓
（这也是我在前两套 oracle 里采用的约定；这次是**实测确认**而不是约定沿用。）

### Q3 — 钳位（④）在 RTL 下朝哪个方向钳？→ **钳到"整行宽度"，Tab 占满该行 [0, 容器宽]**
**39 条被钳位的 Tab**，全部形如：容器 = 行宽，Tab 左缘 = **0.000**、右缘 = **容器宽**：
`he-tab-single@w40/w80`、`he-tab-head@w40/w80`、`he-tab-tail@w40/w80` 等 ⇒
`tabLeftEdge=0.000, tabRightEdge=40.000/80.000, tabWidth=40.000/80.000` ✓
⇒ **RTL 的钳位与 LTR 相同：Tab 吃满整行、行宽 = 容器宽**（不是"从某一侧钳"），
与 tab-zero 里 LTR 的 `w=80.000` 现象一致 ✓ ⇒ **④ 在 RTL 下同样成立**。

## 3. 逐行读数（`w=160`，`default` 臂，纯 RTL）
| 用例 | 行数 | 行（起,止）| w | WITW | trailWs | nl | 行文本 |
|---|---|---|---|---|---|---|---|
| `he-notab@w160@em24@RTL@default` | 1 | [0,6) | 69.410 | 69.410 | 1 | 1 | `אבג דה` |
| `he-tab-single@w160@em24@RTL@default` | 1 | [0,3) | 109.007 | 109.007 | 1 | 1 | `א\tב` |
| `he-tab-head@w160@em24@RTL@default` | 1 | [0,2) | 109.513 | 109.513 | 1 | 1 | `\tא` |
| `he-tab-tail@w160@em24@RTL@default` | 1 | [0,2) | 96.000 | 96.000 | 1 | 1 | `א\t` |
| `he-tab-adj@w160@em24@RTL@default` | 2 | [0,2) | 96.000 | 96.000 | 0 | 0 | `א\t` |
| `he-tab-adj@w160@em24@RTL@default` | 2 | [2,4) | 109.007 | 109.007 | 1 | 1 | `\tב` |
| `he-tab-only@w160@em24@RTL@default` | 2 | [0,1) | 96.000 | 96.000 | 0 | 0 | `\t` |
| `he-tab-only@w160@em24@RTL@default` | 2 | [1,2) | 96.000 | 96.000 | 1 | 1 | `\t` |
| `he-tab-b34@w160@em24@RTL@default` | 4 | [0,3) | 109.007 | 109.007 | 0 | 0 | `א\tב` |
| `he-tab-b34@w160@em24@RTL@default` | 4 | [3,4) | 96.000 | 96.000 | 0 | 0 | `\t` |
| `he-tab-b34@w160@em24@RTL@default` | 4 | [4,6) | 105.573 | 105.573 | 0 | 0 | `\tג` |
| `he-tab-b34@w160@em24@RTL@default` | 4 | [6,8) | 108.200 | 108.200 | 1 | 1 | `\tד` |
| `ar-tab-single@w160@em24@RTL@default` | 1 | [0,3) | 113.120 | 113.120 | 1 | 1 | `ا\tب` |
| `ar-tab-b34@w160@em24@RTL@default` | 4 | [0,3) | 113.120 | 113.120 | 0 | 0 | `ا\tب` |
| `ar-tab-b34@w160@em24@RTL@default` | 4 | [3,4) | 96.000 | 96.000 | 0 | 0 | `\t` |
| `ar-tab-b34@w160@em24@RTL@default` | 4 | [4,6) | 109.513 | 109.513 | 0 | 0 | `\tج` |
| `ar-tab-b34@w160@em24@RTL@default` | 4 | [6,8) | 104.097 | 104.097 | 1 | 1 | `\tد` |

| 用例（wrap 钳位，前 4 行行宽）| 行数 | 各行 w | 容器 |
|---|---|---|---|
| `he-tab-b34@w40@em24@RTL@default` | 8 | 13.513 / 40.000 / 13.007 / 40.000 | 40 |
| `he-tab-b34@w80@em24@RTL@default` | 8 | 13.513 / 80.000 / 13.007 / 80.000 | 80 |
| `he-tab-b34@w40@em24@RTL@tab0` | 2 | 36.103 / 12.203 | 40 |
| `he-tab-b34@w160@em24@RTL@tab0` | 1 | 48.307 | 160 |
## 4. 逐字 `xFromLeftDip` 与 `flowDirection`（每例都有）
`perChar[]` 给 `xFromLeftDip`（**归一化：到行左缘的距离**，RTL 段 raw `TextBounds.X` 原点在**右缘**，直接用 raw 会读反）+
`width` + `flowDirection`（含 `\t` 自身）。样例（`he-tab-single@w160@RTL@default`）：
Tab 左缘 13.007、右缘 95.493；`א` 在 96.000 处 ⇒ **Tab 在 `א` 左边、从左缘 13.007 起向右占 82.487** ——
这正是"从右缘的 96 停靠位向左推进"的几何表现 ✓

## 5. 顺带确认（与 tab-zero 一致）
* **Wrap 下钳位**：`he-tab-b34@w40@RTL@default` = **8 行**、`@w80` = **8 行**，每个 `\t` **独占一行且该行 `w` = 容器宽**（40.000 / 80.000）✓ 与 tab-zero 的 LTR 现象一致 ⇒ **④⑤ 在 RTL 下同样成立**。
* **tab0 臂**：`he-tab-b34@w40@RTL@tab0` = 2 行（Tab 推进 0 ⇒ 几乎不占宽），与 LTR 的 tab0 行为一致 ✓

## 6. 可复算
```powershell
cd C:\u1-shaping\src\TabRtlOracle
dotnet build
powershell -File C:\Windows\Temp\run.ps1
# 产物： C:\u1-shaping\out-tabrtl\tab-rtl-oracle.{json,txt}
```
除 `generatedUtc` 外输出确定。真机只读（未装东西/未改配置/未动他人文件），`C:\u1-shaping\` 已清理。

## 7. 能对拍 / 不能对拍
**能对拍**：纯 RTL 下的 Tab 停靠位锚点（行右缘，左缘落在 k×4×emSize）、Tab 的 `xFromLeftDip`/`width`、
逐行 `width/WITW/trailingWhitespaceLength/newlineLength/lineText/hasOverflowed`、折行点、钳位形态（Tab 吃满整行）。
**不能对拍/未覆盖**：
1. **`breakCause` 是推导值**（WPF 无此 API）——JSON/txt 里保留了标注；
2. **`TextTrimming` 层不存在**（已记，本轮未再试）；
3. **`Tabs` 显式非 null** 未测（只测 `Tabs=null` + `DefaultIncrementalTab∈{0,默认}`）；
4. **阿拉伯语用例只覆盖了"不连写也可辨"的简单串**：Arial 对阿拉伯语的字形/连写质量不保证，
   本轮目的只是"纯 RTL 内容 + Tab"，**阿拉伯语 shaping 本身不是本 oracle 的目标**；
5. `TextWrapping` 只测 `Wrap`；`NoWrap`/`WrapWithOverflow` 未测；
6. 字体固定 Arial；真值只代表 `TextFormatter` 这一层。

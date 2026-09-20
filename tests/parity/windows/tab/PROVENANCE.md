# U1 · Windows 真机「Tab 口径」oracle（114 例）

> 供 `T2c`（Tab 口径 15 例，已登记差异未实现）判定"是我们实现错"还是"真值口径不同"。
> **全部在远端真机完成**（本地只落盘 oracle 文件，未跑应用、未构建）。
> 停止点参照：桥 `759a322431f1e457`｜PC `6be29475b6aeb34e`｜PF `50da85138a7bc3e8`｜shim `e1bc947afc248b32`

## 1. 元组（口径）

| 项 | 值 |
|---|---|
| 机器 | `bilintu\pc@192.168.193.97`，Windows 11 23H2 `10.0.22631`，x64 |
| 运行时 | **.NET 10.0.7**（`Microsoft.WindowsDesktop.App 10.0.7`），PresentationCore 10.0.0.0 |
| **测量方式** | `TextFormatter.Create().FormatLine(source, 0, paragraphWidth, paraProps, null)` → `TextLine` |
| 逐字 x 区间 | `TextLine.GetTextBounds(i, 1)`（i = 0..N−1）；整行 `GetTextBounds(0, line.Length)` |
| 行信息 | `Length` / `NewlineLength` / `Width` / `WidthIncludingTrailingWhitespace` / `Height` / `Baseline` / `Extent` / `TextHeight` / `TrailingWhitespaceLength` / `HasOverflowed` |
| **Dpi** | **96**（TextFormatter 与分辨率无关；x/width 是 DIP） |
| **emSize** | **24 DIP** 为主；另做 **12 / 24 / 48** 三档扫描以确认 Tab 间隔的比例关系 |
| paragraphWidth | **40 / 80 / 160 / 320 / 10000** DIP |
| 方向 | **LTR 与 RTL 各跑一遍** |
| 字体 | **Arial**，`file:///C:/WINDOWS/FONTS/ARIAL.TTF`，**sha256 `baa251526d6862712a58e613ef451d8a2b60482142ec6aab1d47fb8e23e21a7c`**（逐码点覆盖验证；**Tab U+0009 无字形，属控制字符，已从覆盖检查里排除**，其余全部覆盖 ⇒ 无回退） |

**⚠️ WPF 没有公开的自定义 Tab 停靠位 API**：`TextParagraphProperties` 的成员只有
`Alignment / DefaultTextRunProperties / FirstLineInParagraph / FlowDirection / Indent / LineHeight /
ParagraphIndent / TextAlignment / TextDecorations / TextMarkerProperties / TextWrapping`，
**没有 TabProperties**。所以"显式设置 Tab 宽度"这件事**在 WPF 层做不到**，
本 oracle 改为**测量默认口径**，并用 `Indent` 做了变量对照（见 §5）。

## 2. ⭐ 实测出的 Tab 口径（三条规则，均有数据支撑）

**规则 A —— 默认 Tab 间隔 = 4 × emSize**（不是固定 DIP 值）：
| emSize | `"\t"` 一行 = Tab 间隔 |
|---|---|
| 12 | **48.000** = 4×12 |
| 24 | **96.000** = 4×24 |
| 48 | **192.000** = 4×48 |

**规则 B —— 停靠位锚在"行原点"**：LTR 锚**左边缘**、**RTL 锚右边缘**。
每个 Tab 前进到**沿排版方向的下一个 `k × 间隔`**。证据（`a\tb\tc`，emSize 24，行宽 204）：
* LTR：到达 **96 / 192**；
* RTL：到达 **107.997 / 11.997** = **204−96 / 204−192** ⇒ 正是从**右边缘**起的 96 网格 ✓

**规则 C —— Tab 前进方向 = 排版方向**：所以"到达的停靠位"在 RTL 下是 Tab 的**左边缘**，LTR 下是**右边缘**。
JSON 里 `tabs[].reachedStopDip` **已经按方向算好**了（不是简单的 `x+width`），并另给 `tabSpanDip{left,right}` 供核对。

## 3. 结果表（`paragraphWidth=10000`，emSize 24）

| 用例 | 方向 | 文本 | 行宽 DIP | Tab 数 | 每个 Tab 的 advance / 到达停靠位 |
|---|---|---|---|---|---|
| `no-tab` | LTR | `abc def` | 78.720 | 0 | - |
| `no-tab` | RTL | `abc def` | 78.720 | 0 | - |
| `no-tab-short` | LTR | `ab` | 26.693 | 0 | - |
| `no-tab-short` | RTL | `ab` | 26.693 | 0 | - |
| `tab-mid` | LTR | `a\tb` | 109.347 | 1 | i=1 adv=82.653333 stop=96 |
| `tab-mid` | RTL | `a\tb` | 109.347 | 1 | i=1 adv=82.653333 stop=13.343334 |
| `tab-head` | LTR | `\ta` | 109.347 | 1 | i=0 adv=96 stop=96 |
| `tab-head` | RTL | `\ta` | 109.347 | 1 | i=0 adv=96 stop=13.343334 |
| `tab-tail` | LTR | `a\t` | 96.000 | 1 | i=1 adv=82.653333 stop=96 |
| `tab-tail` | RTL | `a\t` | 96.000 | 1 | i=1 adv=82.653333 stop=0 |
| `tab-only` | LTR | `\t` | 96.000 | 1 | i=0 adv=96 stop=96 |
| `tab-only` | RTL | `\t` | 96.000 | 1 | i=0 adv=96 stop=0 |
| `tab-two-mid` | LTR | `a\tb\tc` | 204.000 | 2 | i=1 adv=82.653333 stop=96 i=3 adv=82.653333 stop=192 |
| `tab-two-mid` | RTL | `a\tb\tc` | 204.000 | 2 | i=1 adv=82.653333 stop=107.996667 i=3 adv=82.653333 stop=11.996667 |
| `tab-two-only` | LTR | `\t\t` | 192.000 | 2 | i=0 adv=96 stop=96 i=1 adv=96 stop=192 |
| `tab-two-only` | RTL | `\t\t` | 192.000 | 2 | i=0 adv=96 stop=96 i=1 adv=96 stop=0 |
| `tab-double-mid` | LTR | `a\t\tb` | 205.347 | 2 | i=1 adv=82.653333 stop=96 i=2 adv=96 stop=192 |
| `tab-double-mid` | RTL | `a\t\tb` | 205.347 | 2 | i=1 adv=82.653333 stop=109.343334 i=2 adv=96 stop=13.343334 |

| 宽度约束（`a\tb`） | 行宽 | hasOverflowed | Tab advance |
|---|---|---|---|
| paragraphWidth=40 | 109.347 | True | 82.653 |
| paragraphWidth=80 | 109.347 | True | 82.653 |
| paragraphWidth=160 | 109.347 | False | 82.653 |
| paragraphWidth=320 | 109.347 | False | 82.653 |

| emSize | `\t` 行宽 = Tab 间隔 | `a\tb` 的 Tab advance |
|---|---|---|
| 12 | 48.000 | 41.327 |
| 24 | 96.000 | 82.653 |
| 48 | 192.000 | 165.303 |

| Indent | 文本 | Tab x | advance | 到达停靠位 |
|---|---|---|---|---|
| 24 | `\ta` | 24.000 | 72.000 | 96.000 |
| 24 | `a\tb` | 37.347 | 58.653 | 96.000 |
| 48 | `\ta` | 48.000 | 48.000 | 96.000 |
| 48 | `a\tb` | 61.347 | 34.653 | 96.000 |

**控制组**：`no-tab`（`abc def`）与 `no-tab-short`（`ab`）在 LTR/RTL 下都**没有 Tab**、行宽分别为 78.720 / 26.693 且两方向相同
⇒ 装置在"不含 Tab"时不产生伪 Tab 读数 ✓。

## 4. 宽度约束：**不影响 Tab 前进，只影响 `HasOverflowed`**

| paragraphWidth | 行宽 | HasOverflowed | Tab advance |
|---|---|---|---|
| 40 | 109.347 | **True** | 82.653 |
| 80 | 109.347 | **True** | 82.653 |
| 160 | 109.347 | False | 82.653 |
| 320 | 109.347 | False | 82.653 |

⇒ **Tab 不会为了塞进容器而缩短或换行**（本 oracle 用 `TextWrapping.NoWrap`；折行下的 Tab 行为**未覆盖**，见 §8），
容器不够时**行照常溢出**，只有 `HasOverflowed` 变 True。

## 5. Indent：Tab 网格锚在**行原点**，**不随 Indent 平移**

| Indent | 文本 | Tab x | advance | 到达停靠位 |
|---|---|---|---|---|
| 24 | `\ta` | 24.000 | 72.000 | **96.000** |
| 48 | `\ta` | 48.000 | 48.000 | **96.000** |
| 24 | `a\tb` | 37.347 | 58.653 | **96.000** |
| 48 | `a\tb` | 61.347 | 34.653 | **96.000** |
| 24 | `a\tb\tc` | 37.347 / 109.347 | 58.653 / 82.653 | **96.000 / 192.000** |

⇒ 无论 Indent 是 0/24/48，**停靠位始终是行原点起的 96/192**（Indent 只把文本起点右移）✓

## 6. 逐字 x 区间与"Tab 占的宽度"怎么来的
* 每个字符给 **`xFromLeftDip`（左缘到**行左缘**的距离，已归一化）** + `width`。
  **raw `TextBounds.X` 的原点在 RTL 段落是右边缘**（bidi oracle 踩过的同一个坑），所以比较必须用 `xFromLeftDip`。
* **Tab 占的宽度 = `tabs[].advanceDip`**，来源是 `TextBounds.Rectangle.Width`（对 Tab 所在下标调 `GetTextBounds(i,1)`）；
  `tabs[].derivedAdvanceDip` 是**独立推算**（下一个逻辑字符的 x − 本 Tab 的 x）用于交叉验证，
  **仅在下一个逻辑字符确实在右侧时才给出**（RTL 下为 `null` 并注明原因——那里下一个逻辑字符被重排到左边，推算会得出负数）。
* 实证 tiling 连续：LTR `a\tb\tc` = `a[0,13.347] | \t[13.347,96] | b[96,109.347] | \t[109.347,192] | c[192,204]`，严丝合缝 ✓

## 7. 可复算
```powershell
cd C:\u1-shaping\src\TabOracle
dotnet build
powershell -File C:\Windows\Temp\run.ps1     # 打印 EXITCODE / stdout / stderr / 产物大小
# 产物： C:\u1-shaping\out-tab\tab-oracle.{json,txt}
```
源码同步在 `src/`（`Program.cs` / `TabOracle.csproj` / `run.ps1`）。除 `generatedUtc` 外输出**确定**（无随机、无时间依赖）。
真机只读：**没装东西、没改工程配置、没动别人文件**；`C:\u1-shaping\` 已清理。

## 8. 能对拍 / 不能对拍
**能对拍**：Tab 的 `advanceDip`、`reachedStopDip`、间隔 = 4×emSize、网格锚点（LTR 左 / RTL 右）、
Indent 不移动网格、宽度约束不影响 Tab 前进、逐字 `xFromLeftDip`/`width`、行 `Width`/`Height`/`Baseline`。
**不能对拍/未覆盖**：
1. **折行（`TextWrapping.Wrap`）下的 Tab**：本轮全用 `NoWrap`；换行时的 Tab 复位行为未测。
2. **显式自定义 Tab 停靠位**：WPF 公开 API **不支持**（§1），所以"显式设置"这一半**没有真值**，
   只能承认它在 WPF 层不存在。
3. **多行/`LineHeight`/`ParagraphIndent` 非默认**、`TextAlignment` 非 Left（本 oracle 用 `Left`；
   RTL 下的对齐语义未单独测）未覆盖。
4. **`\t` 与 RTL/双向混排交互**只测了纯拉丁 + Tab；Tab 夹在希伯来/阿拉伯文之间的行为未测。
5. 字体固定 Arial（已用逐码点覆盖排除回退，**换字体需重跑**）。
6. 真值只代表 **`TextFormatter` 这一层**；`TextBlock`/`FormattedText` 未交叉验证。
7. 环境备注：本机 oracle 进程约有一半启动会撞上已知的 `GetMetrics` 垃圾 HRESULT 问题（与 WPF 无关，重启即可）；
   本轮 114 例的数据已校验一致。

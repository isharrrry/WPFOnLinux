# B2/B3/B4 · Windows 真机 oracle（`TextFormatter` / `TextLine` 逐行行为）

> 数据源：**公开 API** `System.Windows.Media.TextFormatting.TextFormatter.FormatLine(...)`，
> 不是 `FormattedText.Width` 那种整块数字。
> 本目录是 **T1 的 B2/B3/B4 验收锚**：Linux 侧 `HbTextLine`/`TextLine` 桩要与这里的逐行真值对齐。

| 产物 | 说明 |
|---|---|
| `cases.json` | 614 个用例（A/B/F/M 四组），21 档 `MaxTextWidth`，15 个文本样本 |
| `windows-results.json` | 614 个用例的**逐行逐属性** dump（**53 MB**，3222 行） |
| `probe.json` | 环境 + `TextFormatting` 公开面反射 dump + 字体可用性/文件 sha256 + 竖排负结果 |
| `verify.py` / `verify-report.txt` | 数据完整性核验脚本与输出（**可复算**，见 §5） |
| `src/LayoutOracle/` | oracle 源码（net10.0-windows，`UseWPF`，无 NuGet 依赖） |

---

## 1. 生产环境（可追溯）

| 项 | 值 |
|---|---|
| 机器 | `BILINTU`（`bilintu\pc@192.168.193.97`），Windows 11 `10.0.22631`，x64 |
| .NET SDK | **10.0.203**；运行 `Microsoft.NETCore.App 10.0.7` |
| WPF | `Microsoft.WindowsDesktop.App 10.0.7`；`PresentationCore.dll` = `C:\Program Files\dotnet\shared\Microsoft.WindowsDesktop.App\10.0.7\PresentationCore.dll`（程序集版本 10.0.0.0） |
| **DPI** | **96**（`GetDpiForSystem()`；`PixelsPerDip = 1.0` 传给 TextRunProperties） |
| **CultureInfo** | 机器默认 `zh-CN`；**每个用例显式指定**（`en-US` / `zh-CN` / `ja-JP`），并 dump 进 `input.culture` |
| **TextFormattingMode** | **两档都跑**：`Ideal`（A/B/F/M 组默认）与 `Display`（A3 组 105 例），dump 进 `input.textFormattingMode` |
| Windows 工作目录 | `C:\wpf-oracle-layout\`（字体在 `fonts\`；与其它 agent 的 `C:\wpf-oracle-brush\` / `C:\wpf-oracle-systemfonts\` 不共用） |
| 生成时间 | 见 `windows-results.json.generatedUtc` |

## 2. 字体（**只引用，未安装**）

字体**没有**拷进 `C:\Windows\Fonts`、**没有**改注册表、**没有**改任何系统设置。
拉丁用**文件式**加载（可证伪系统回退），CJK 只按系统字族名引用并记录其物理文件 sha256。

| 用途 | 取法 | 物理文件 | sha256 |
|---|---|---|---|
| 拉丁（`fontKey=file`，387 例） | `new FontFamily(new Uri("file:///C:/wpf-oracle-layout/fonts/"), "./#Noto Sans")` | `C:\wpf-oracle-layout\fonts\NotoSans-Regular.ttf`（= 仓库 `build/fonts/NotoSans-Regular.ttf`） | `f3961a9cde016d41a4879aecda1474d3a36d6bf54fa0e4643de029cc2248b0e8` |
| 中文（`fontKey=zh`） | `new FontFamily("Microsoft YaHei")` | `C:\WINDOWS\FONTS\MSYH.TTC` | `3084f1f88369af6bf9989c909024164d953d1e38d08734f05f28ef24b2f9d577` |
| 日文（`fontKey=ja`） | `new FontFamily("Yu Gothic")` | `C:\WINDOWS\FONTS\YUGOTHR.TTC` | `27c9b8e4cc7c5cbd846d1fa978b7713938e8ae766875962c70c3986b004bbc85` |

**回退证伪（防假绿的核心一条）**：每个用例都 dump `fontProof`，取的是
`Typeface.TryGetGlyphTypeface().FontUri`；自检要求 `fontKey=file` 的用例其 `FontUri`
必须是 `…\wpf-oracle-layout\fonts\NotoSans-Regular.ttf`，否则**拒绝写出结果文件**。
386/386 例通过（`selfCheck.fileFontMismatch = 0`）。
> 这条不是形式主义：第一版因为参数位置写错（`run` 模式把**输出路径**当成了字体目录），
> 拉丁文本全部静默回退到系统字体，正是这条断言把 53 MB 的"看起来正常"的数据挡了下来。

## 3. 复现命令

```powershell
# Windows（C:\wpf-oracle-layout\，源码在 src\LayoutOracle\）
dotnet build -c Release
src\LayoutOracle\bin\Release\net10.0-windows\LayoutOracle.exe gencases cases.json
src\LayoutOracle\bin\Release\net10.0-windows\LayoutOracle.exe run cases.json windows-results.json fonts
src\LayoutOracle\bin\Release\net10.0-windows\LayoutOracle.exe probe probe.json fonts
```

```bash
# Linux 侧（只读核验，无需构建）
cd tests/parity/windows/layout-b34
python3 verify.py            # 打印并写出 verify-report.txt
```

`run` 的退出码非 0 = 自检未通过；此时**只写 `windows-results.json.debug.json`**，不写正式结果。

## 4. 调用序列（口径，逐点固定）

```csharp
var formatter = TextFormatter.Create(TextFormattingMode.Ideal | Display);
var cache     = new TextRunCache();          // 每个用例一个
TextLineBreak previousBreak = null;          // 逐行串接（WPF TextBlock 的标准调用序列）
int index = 0;
while (index < text.Length)
{
    TextLine line = formatter.FormatLine(source, index, maxWidth, paraProps, previousBreak, cache);
    … dump …
    previousBreak = line.GetTextLineBreak();
    index += line.Length;                    // 行起点只能这样累加，见 §6
}
```

`TextSource` 刻意做**最小**：整段文本作为一个 `TextCharacters` run 交给 WPF（切分/断行全部由 WPF 决定，
不被我们自己的切分策略污染），除 M 组的 `TextModifier` 变体（见 §6）。
`TextParagraphProperties` 按用例设置 `FlowDirection/TextAlignment/TextWrapping/LineHeight/Indent/AlwaysCollapsible` 等。

## 5. 防假绿自检（写文件之前先过闸）

`windows-results.json.selfCheck` 里固化了规则，任何一条不满足就**拒绝写正式结果**：

* `cases` > 0 且结果数 == 用例数；
* 每例**行数 > 0**；**非空白行 `Width > 0`**（空白行的 `Width == 0` 是合法真值，见 §6）；
* `consumedLength ∈ [文本长度, 文本长度+1]`（末行的 EOP 标记多 1，实测 614/614 都是 +1）；
* 文本非空；
* `fontKey=file` 的用例其解析到的物理字体必须是我们自己那份 ttf。

当前：`ok=true, cases=614, lines=3222, zeroWidthVisibleLines=0, casesNotFullyConsumed=0, fileFontMismatch=0`。

## 6. API 事实与坑（都是实测/源码双证，T1 直接可用）

| # | 事实 | 证据 |
|---|---|---|
| 1 | **WPF 有两条 `TextLine` 实现**：`MS.Internal.TextFormatting.SimpleTextLine`（快路径）与 `…TextMetrics+FullTextLine`。选择条件见 `TextFormatterImp.cs:224`：`!AlwaysCollapsible && previousLineBreak==null && lineLength<=0` → 走 SimpleTextLine | 实测行分布 3170 FullTextLine / 52 SimpleTextLine；`lineRuntimeType` 逐行 dump |
| 2 | **SimpleTextLine 的 `GetTextLineBreak()` 与 `GetTextCollapsedRanges()` 恒为 null**（`SimpleTextLine.cs:973/983` 直接 `return null`）⇒ 要拿这两项真值必须走 FullTextLine，即把 `TextParagraphProperties.AlwaysCollapsible` 置 **true**（F 组就是这么做的） | F 组 120 例 |
| 3 | **`TextLineBreak` 公开属性数 = 0**（唯一公开成员是 `Clone()`/`Dispose()`）；它只在 `TextSource` 含 **`TextModifier`**（末 run 有 TextModifierScope）时非 null —— 3222 行里只有 2 行非 null，正是 M 组的 modifier 用例 | `apiFacts.TextLineBreak_publicPropertyCount=0`；`M_modifier_w80/w120` |
| 4 | **`Collapse(TextLine)` 不存在**。公开面只有 `Collapse(TextCollapsingProperties[])` | `apiFacts.TextLine_Collapse_TextLine_exists=false` |
| 5 | **`GetTextRunBounds` 不存在**；等价物是 `GetTextBounds(firstTextSourceCharacterIndex, textLength)`，返回 `IList<TextBounds>`，其中 `TextBounds.TextRunBounds` 才是逐 run 的 `{TextSourceCharacterIndex, Length, Rectangle}` | `apiFacts.*`；本 dump 的 `textBounds[].runs[]` |
| 6 | **`GetInsertionCaretCharacterHit` 不存在**；存在的是 `GetNextCaretCharacterHit` / `GetPreviousCaretCharacterHit` / `GetBackspaceCaretCharacterHit` / `GetCharacterHitFromDistance` / `GetDistanceFromCharacterHit` | `apiFacts` |
| 7 | **`TextParagraphProperties` 没有 `LineStackingStrategy`**（公开与非公开成员里都没有）⇒ 行高策略只能通过 `LineHeight` 间接影响，`MaxHeight`/`BlockLineHeight` 这两档**在 `TextFormatter` 公开面上拿不到** | `apiFacts.TextParagraphProperties_LineStacking*` |
| 8 | **`TextLine.Start` 恒为 0**（3222/3222），**不是段落内偏移**；行起点只能由调用方累加 `Length` 得到（本 dump 的 `lineIndexInText`） | `verify-report.txt` §1 |
| 9 | 索引参照系：`TextCollapsedRange.TextSourceCharacterIndex` 与 `TextRunBounds.TextSourceCharacterIndex` 都是**段落系**；`GetTextBounds` 的第一个参数也是段落系（传 0 时只有行起点=0 的行有结果——第一版踩过） | 实测 `行起点=10 → range.index=12` 指向行内第 2 字符 |
| 10 | `TextLine.Start` 以外的坑：`GetTextCollapsedRanges()` 在未折叠行上返回 **null（不是空集合）**；`GetIndexedGlyphRuns()` 也可能返回 null | 逐行 `collapsedRangesIsNull` / `indexedGlyphRunsIsNull` |
| 11 | **WPF 没有竖排文本布局**：`System.Windows.Media.TextFormatting` 命名空间的公开成员里没有任何 vertical/writing-mode/upright/tategaki/orientation 入口，`FlowDirection` 只有 `LeftToRight`/`RightToLeft`；唯一命中 `InvertAxes.Vertical` 是 `TextLine.Draw()` 的坐标轴翻转参数，与竖排排版无关 | `probe.json.verticalText` |
| 12 | `System.Windows.Media.Fonts` **没有 `GetFontFamily`** 方法（任务书里那个写法在本机 .NET 10 上不存在）；可用的是 `GetFontFamilies(String/Uri)` | `probe.json.apiSurface.Fonts.methods` |

### 与"73 例 kinsoku 那套"的口径差异（重要）

已验收的 `tests/parity/windows/shaping/out-layout/kinsoku-table.json` 走的是
**DirectWrite `IDWriteTextLayout`**（`engine` 字段自述：*"DirectWrite IDWriteTextLayout (word wrapping = WRAP)"*，
字体 Noto Sans CJK SC），即 **`dwrite.dll` 的断行引擎**。

本 oracle 走的是 **WPF 托管文本栈**：`TextFormatter.FormatLine` → `TextMetrics` → `lsapi`
（`LoAcquireBreakRecord`，`TextMetrics.cs:291`）+ WPF 自己的断行/禁则处理。

两者是**两条不同的实现路径**，断行结论不保证一致。因此：

* Linux 侧要跟的是 **WPF `TextFormatter` 的行为**（我们要实现的是 `TextLine`/`TextFormatter` 的契约），
  **本 oracle 是权威**；
* 那份 kinsoku 表是"DWrite 引擎口径"，**不能直接当 `TextFormatter` 的真值**；
  与 Linux 侧 kinsoku 单测对接时应标注口径来源，二者冲突时以本 oracle 为准。

## 7. 未覆盖项（诚实清单）

1. **`LineStackingStrategy`（MaxHeight / BlockLineHeight）拿不到**：`TextParagraphProperties` 公开面没有该属性（§6-7）。
   D 组只能覆盖 `LineHeight` 的直接影响，**两档策略的差异无法在本 oracle 里给出真值**；
   若要它，只能走 `TextBlock`（FrameworkElement）那一层，属于另一个 API 面。
2. **`GetTextCollapsedRanges` 的真实折叠只用 `TextTrailingCharacterEllipsis` 造过**；
   `TextTrailingWordEllipsis`（WordEllipsis）与 `TextTrimming` 的三种取值**尚未覆盖**（计划中的 C 组）。
3. **caret API 的返回值已 dump，但只取了 7 个距离 + 5 个字符位置**（覆盖度有限，够 B3 起步不够穷尽）。
4. **`TextAlignment`（含 Justify）/ `FlowDirection=RTL` / bidi 混排**：用例集里已有 `bidi_mix` 文本，
   但**对齐与 RTL 的专项用例尚未生成**（计划中的 C 组）。
5. **`GetIndexedGlyphRuns` 只 dump 了条数与首个元素**（整份 dump 体积不可接受）；
   字形级（glyph index/advance）真值请用已验收的 U1 shaping oracle。
6. **`TextLine.Width` 的 Display 模式像素对齐细节**：A3 组有数据，但未做 `Ideal`↔`Display` 的逐例对比分析。
7. `M` 组的 `TextModifier` 只用于证明 `TextLineBreak` 的非空分支，**不是 modifier 语义的完整覆盖**。
8. 本 oracle 只覆盖 **`TextFormatter` 公开 API**；`TextBlock` 层的对齐/修剪组合行为（内部会再包装一层）未覆盖。

---

# 附：C/D 第一批（`cases-cd1.json` / `results-cd1.json`，184 例）

**未覆盖原有文件**：第一批用并列文件名，`windows-results.json`（614 例 A/B/F/M）保持原样。

| 文件 | 内容 |
|---|---|
| `cases-cd1.json` | 184 例：T（TextTrimming，144）/ L（行起点自证，10）/ P（AlwaysCollapsible 对照，30） |
| `results-cd1.json` | 同上的逐行逐属性 dump（与 `windows-results.json` 同一套 dump 结构 + `trim` / `startAccumulation` 两个新块） |
| `evidence-cd1.md` | 由 `python3 evidence-cd1.py` 生成的**证据表**（可直接贴给 B2/B3） |

## 覆盖清单更新（相对 §7"未覆盖项"）

**新覆盖**：

* **`TextTrimming` 三档**（None / CharacterEllipsis / WordEllipsis）× 三种溢出触发路径
  （`NoWrap` / `WrapWithOverflow` / `Wrap`+窄约束）；`TextTrailingCharacterEllipsis` 与
  `TextTrailingWordEllipsis` 都造了真折叠（36 行 `HasCollapsed=true` 带 `collapsedRanges`）。
* **`TextLine.HasOverflowed` 闸门**：实测溢出+非 None 才真折叠；不溢出时调 `Collapse` 得 `HasCollapsed=false`。
* **行起点累加模板**：每行新增 `startAccumulation` 块（`lineStart`/`length`/`nextLineStart`/`sourceSlice`/`sliceMatchesSource`）。
* **`AlwaysCollapsible` 开/关对照**（30 例，同文本同宽度成对）：两条实现的**可观测行度量完全相同**，
  差异只体现在 `lineRuntimeType`（AC=关时 3 例落到 `SimpleTextLine`）。

**仍然未覆盖**（顺延）：

1. `LineStackingStrategy` 两档 —— **API 面就没有**（§6-7），只能覆盖 `LineHeight`；D 组待做。
2. **`TextAlignment` 三档 + `Justify`（含 Justify×CJK 专项）** —— C/D 第二批。
3. **RTL / bidi 混排**（阿拉伯/希伯来 + 拉丁数字 + 括号镜像）—— C/D 第二批；
   `Segoe UI` 已作为 `fontKey=bidi` 接入（逐例 `fontProof.fontFileSha256` 记录物理文件哈希）。
4. **`T3` 构型缺陷**：想用"约束宽 < 行宽"触发折叠，但 `Wrap` 下首行常常本来就窄 ⇒ 短行拉丁上什么都没折叠。
   第二批换成「先 `NoWrap` 拿长行，再窄约束」。
5. **`SimpleTextLine` + `Collapse` 的组合未覆盖**：T 组 106 次 `Collapse` 全部落在 `FullTextLine` 上
   （`SimpleTextLine.Create` 在需要溢出/折叠的场景会返回 null，于是回退到 Full）。
   **推断（未证明）**：Simple 路径只用于"整行放得下"的行，因此它那两个恒 null 的成员在可观测面上不产生分叉。
6. 折叠后的可见文本**不能只看 `Length`**（实测折叠后 `Length` 不变）；必须用 `collapsedRanges`。这条已写进 `evidence-cd1.md`。

---

# 附：C/D 第二批（`cases-cd2.json` / `results-cd2.json`，106 例）

| 文件 | 内容 |
|---|---|
| `cases-cd2.json` / `results-cd2.json` | AL 对齐 64 / BD bidi 30 / LH 行高 12 |
| `evidence-cd2.md` | 由 `python3 evidence-cd2.py` 生成的证据表（含实测公式） |

**新覆盖**：

* **`TextAlignment` 四档**：Left/Right/Center/Justify。实测对齐公式 —— `Right` 的 run X = `w - Width`、
  `Center` = `(w - Width)/2`（全量核对 52/52 行，0 不符）；`TextLine.Width` 本身不随对齐变化。
* **Justify**：非末行 `Width` 恰好 = 段落宽，**末行不拉伸**（`NewlineLength=1`，保持自然宽）。
* **★ Justify × CJK**：8 组（cjk_punct / cjk_nospace × 4 个宽度）与 `Left` **逐行 (Length,Width) 完全相同**
  ⇒ WPF 的 Justify **只拉伸空格**，CJK 无可拉伸空格 ⇒ 不拉伸。
* **RTL / bidi 混排**（5 个文本 × LTR/RTL × 3 个宽度）：RTL 段落视觉序 == 逻辑序（5/5）；
  LTR 段落里的 RTL 片段被重排；`mixed_3way` 的 **run 切分随段落方向变化（5 vs 6 个 run）**。
  字体 `SEGOEUI.TTF`，逐例 `fontProof.fontFileSha256`。
* **`LineHeight`**：三条实测公式 —— `Height = LineHeight`；`TextHeight` 恒为字体自然文本高（≠ Height）；
  `Baseline = LineHeight × (自然Baseline/自然Height)`（最大偏差 0.0035 DIP）；`MarkerHeight` 跟随 Height。

**仍然未覆盖**：

1. **`LineStackingStrategy` 两档**：`TextFormatter` 公开面**没有**该属性（再次确认，见 `apiFacts`）——
   只有 `LineHeight` 能覆盖。D 组的这一项**永久登记为"公开面拿不到"**。
2. **RTL × 非 Left 对齐的交叉**（BD 组的段落对齐固定为 Left）：RTL+Right / RTL+Justify 未覆盖。
3. **括号镜像的字形级证据**：只 dump 了 run 的 X 顺序与 `FlowDirection`，未 dump 镜像后的实际字形
   （字形级请用已验收的 U1 shaping oracle）。
4. 对齐的 **`Display` 模式**（A3 组有 Display 数据，但 AL 组只跑了 Ideal）。

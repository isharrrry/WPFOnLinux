# T1d · 真 bidi / RTL 视觉顺序 —— **立项评估**（只读评估，未开�工；2026-09-13）

> **本轮性质**：**只读**。没有改任何被指纹覆盖的文件（shim 仍 `ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf`），
> 没有 build、没有跑应用。所有读数都标了来源；**凡"我们推的"都写成推断并给出"决定性读数"**。
> 被测/被引坐标：`build/shims/PresentationCore.HbTextLine.cs`（T1d 车道）、`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（D3 钩子）、
> `upstream/wpf/**`（只读）、`tests/parity/windows/**`（只读真值）。

---

## 1. 我们现在到底做到哪一步

### 1.1 方向相关的调用面（`grep -an` 原文，shim 内只有这些）
```
136:        [DllImport(Hb)] internal static extern void hb_buffer_guess_segment_properties(IntPtr buf);
138:        [DllImport(Hb)] internal static extern void hb_buffer_set_language(IntPtr buf, IntPtr language);
205:                hb_buffer_guess_segment_properties(buf);
207:                fixed (byte* lz = langZ) hb_buffer_set_language(buf, hb_language_from_string(lz, -1));
```
- **没有** `hb_buffer_set_direction` / `HB_DIRECTION_RTL` / `hb_buffer_reverse` / `hb_buffer_set_script`（全库 0 处）。
  ⇒ 方向**完全靠 `guess_segment_properties` 猜**（按 buffer 内容的脚本定），且**整段文本只进一个 buffer**。
- 语言被**硬编码**为 `Shape(..., language = "zh-cn")`（`:159` 的默认参；U1 要求，为 CJK SC/TC 面选择）⇒ 阿拉伯/希伯来也吃 `zh-cn`。
- **段落方向进不到 shim**：D3 钩子签名是
  `HbTextFallback.TryFormatLine(TextSource, int cpFirst, double paragraphWidth, double pixelsPerDip, bool alwaysCollapsible, double lineHeight)`
  （`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:217`，调用点 `:536`）；
  而**同一个文件里 `paragraphProperties`（含 `FlowDirection`）就在手上**（`:399/:430/:468/:495/:507` 都是它的入参）
  ⇒ **方向信息是在钩子这一层被丢掉的**（不是 shim"没接到"）。shim 唯一间接看到方向的时机是 `Draw(...)` 的 `InvertAxes`。
- `GlyphRun` 的 **`BidiLevel` 恒为 0**：`HbTextLine.BuildGlyphRun` 构造 `new GlyphRun(face, 0, false, …)`（第二个参数就是 bidiLevel），
  `IsSideways = false` 也恒定。`Clusters` 是**逻辑**字符下标（HB 的 cluster ✓ 段内平移）。

### 1.2 `InvertAxes` 反演矩阵**解决什么、不解决什么**
| | 内容 | 依据 |
|---|---|---|
| **解决的** | **"把一个已经排好的行整体镜像"**：`x' = 段落宽 − x`（`Vertical` 则是 `y' = 行高 − y`）。这是**宿主契约**：`MS/Internal/Text/Line.cs:79` `_mirror = (lineProperties.FlowDirection == FlowDirection.RightToLeft)` ⇒ `:116` `line.Draw(ctx, origin, _mirror ? InvertAxes.Horizontal : InvertAxes.None)`。上游同款：`SimpleTextLine.cs:482-501` push `TextFormatterImp.CreateAntiInversionTransform(...)`（`TextFormatterImp.cs:565-595` 纯矩阵） | 我上一轮 P0 的实测（P7–P11、`M11=-1 OffsetX=段落宽`） |
| **不解决的** | **簇/段的按 bidi 重排**：它**不改逻辑顺序、不分段、不设 bidi level、不改字形序**。它只是把整行坐标翻一下 | 同上（矩阵只有 m11/offsetX/m22/offsetY 四个自由度） |

**两者差别（一句话）**：反演矩阵是"**把画好的东西照镜子**"；bidi 是"**决定画的时候按什么顺序、哪一段属于哪个方向**"。
前者对"坐标系被镜像"的调用方正确；后者才是 RTL/混合方向文本的**内容正确性**。

### 1.3 两种情况下的当前行为
**(甲) 纯 RTL 段落**（例：`BD_he_only_rtl_*`，`flowDirection=RightToLeft`）
- **已实测的事**（本轮，**用已编好的探针二进制**，未 build）：把 `'שלום עולם'` 走一遍我们的路径，读出交给 `GlyphRun` 的字形序列：
```
我们的 glyphIds = [1332, 1331, 1324, 1337, 3, 1332, 1324, 1331, 1344]
按 id→char 还原的**绘制顺序** = ם ל ו ע ␠ ם ו ל ש
逻辑串 =                      ש ל ו ם ␠ ע ו ל ם
⇒ 绘制顺序 == 逻辑序的**整体反序**（= HarfBuzz 对 RTL 的**视觉序**输出）
（读数来源：`CoverageProbe --inkdiag` 打 `glyphIds=[...]`；id→char 用 HB 的 cmap 反查，字体 = 探针实际用的 DejaVuSans）
```
- **推断（未验证，需读数）**：字形序**已是视觉序**，而宿主对 RTL 段落**还会**要我们整体镜像（1.2）⇒
  **两次反转叠加** ⇒ 预测屏上呈"逻辑序从左到右 + 每个字形被水平镜像"（即**反向且字形镜像**）。
  ⚠️ 这条**不是结论**：要钉它需要 §5 的读数（应用级像素，或"逐字符 x 真值"）。
- **判不了的部分**：`SimpleTextLine`（上游）在同一条镜像下画的是**逻辑序**的 run ⇒ 上游的镜像**是被设计来产生 RTL 视觉序的**；
  我们却交视觉序 ⇒ **谁该负责镜像这件事必须先在 Windows 侧确认**（见 §3 的"逐字符 x"采集）。

**(乙) LTR 段落里嵌一小段阿拉伯文**
- **代码级可定**：整段只进**一个** HB buffer 且方向靠猜 ⇒ **一个 buffer 只有一个方向** ⇒
  混合方向时，非主方向的子串会被按主方向整形。T1c 早先已判过"混合方向**静默画错**（代码级确定）"；本轮 §1.1 的三条（无 `set_direction`、无按 bidi level 分段、`BidiLevel` 恒 0）正是它的**可指认坐标**。
- **还缺的**：真机在该情形下**逐字符 x / 逐段 FlowDirection**的真值（§3 说明为什么现在的 oracle 给不出逐字符）。

---

## 2. 正确实现该落在哪一层

### 2.1 候选与取舍
| 层 | 候选 | 现状 | 取舍 |
|---|---|---|---|
| **(a) 段落级 bidi 分析**（逐字符 level + 逐 bidi-run 切分） | ① **树内已有**：`MS.Internal.TextFormatting.Bidi`（上游托管 UBA；`PresentationCore.Linux.csproj` **已编入** `TextFormatting/Bidi.cs`；`TextStore.cs:946-1033` 已经在用它：`Bidi.BidiAnalyzeInternal` / `Bidi.BidiStack.Push/Pop/GetMaximumLevel`）<br>② ICU `ubidi`（ICU 70 本机已链接，shim 里已用 `ubiri/ubrk`） | **完全缺失**：shim 直接读 `TextSource`，**绕过了 `TextStore`**（后者本来会算 `bidiLevels[]` 并 `CreateLSRunsUniformBidiLevel` / `CreateReverseLSRuns`，但它面向 `LSRUN`） | **优先 ①**：同源、无新依赖、已在进程里；ICU 作为②备选（其 `ubidi` 也是权威实现，但要在 shim 里多一层绑定） |
| **(b) run 内方向（HB）** | `hb_buffer_set_direction(level 奇⇒RTL)` + **按 bidi-run 分段 shape** | 现在整段一个 buffer、方向靠猜（§1.1） | **必须改**：这是"每个方向段各自整形"的正确层；HB 的视觉序输出是**per-buffer**的，分段才能正确 |
| **(c) 行内顺序与位置（shim）** | 把各 bidi-run 按 level 拼成视觉顺序；每张 `GlyphRun` 填**正确 `BidiLevel`**；`_charAdvances` 仍按**逻辑**下标 | `BidiLevel` 恒 0；顺序=逻辑 | **必须改**：这是唯一"顺序"能落地的地方（见 2.2 契约） |
| **(d) 渲染侧** | 若方案依赖"渲染器按 `BidiLevel` 奇偶处理镜像/形状"，需 `MilGlyphRunAdapter`/`GlyphRunPainter` 读 `BidiLevel` | **不读**（`ToRequest` 只用 `Origin/MuSize/GlyphIndices/advances/offsets`；`MILCMD_GLYPHRUN_CREATE` 里有 `BidiLevel` 字段但没人消费） | **风险项**：这属于**别的车道**（`src/WpfGfx.Linux/**`），若要动必须**主控协调**；本评估建议先做 §5 的读数再决定是否必须 |
| **(e) 上层（PC/`TextLine` 契约）** | 让 PC/宿主做 bidi | 上游是 **LS 在建行时做 bidi**；本移植把 LS 换成了 shim ⇒ **上层没有别人能做** | **不能指望上层**：`TextBlock` 只消费 `TextLine`；`Line.cs` 只有"整体镜像"这一个方向概念 |

### 2.2 哪些契约**不能动**（会打破谁）
- **索引契约**：`TextLine.GetTextBounds(firstTextSourceCharacterIndex, textLength)` 收的是**段落系逻辑索引**、返回行内 x 区间；`Length/NewlineLength/TrailingWhitespaceLength` 的记账口径（T2 四项 1286/1298 建立其上）；`GetTextRunSpans()` 的 span 划分；6 个 owed 的 caret/hit 映射。
  ⇒ 结论：**重排只能发生在"绘制顺序/位置"里，不能改索引语义**（把 `_charAdvances` 保持按逻辑下标即可：视觉顺序由 glyph 序列与 x 位置表达）。
- **`Draw` 的 `origin`/`InvertAxes` 语义**：上一轮刚按上游实现（push 矩阵），**别在 bidi 里顺手改它**；bidi 与它是**两件事**（§1.2）。
- **`GetTextRunSpans()`**：若 bidi 分段要与 span 划分一致，会**碰到 M7b 改过的两处（TextBox P0 的修法）** ⇒ **必须先报主控排波序**。

---

## 3. 验收装置：能复用多少、要新增什么

### 3.1 现有真值能给什么（**已核对，非推断**）
`tests/parity/windows/layout-b34/results-cd2.json` 里有 **27 个 RTL/方向相关用例**（`BD_{he,ar}_only_{ltr,rtl}_w{120,240,400}` 等）；每行含：
```
properties{Width,Height,Extent,Baseline,Length,NewlineLength,TrailingWhitespaceLength,…}
textBounds[]  → { Rectangle, FlowDirection, runs[{TextSourceCharacterIndex,Length,RectangleX,RectangleWidth,runText}] }
runSpans[]    → { Length, Value{CharacterBufferReference, Properties{Typeface,ForegroundBrush,…}} }
caret / collapseCharacterEllipsis / indexedGlyphRunsIsNull / lineRuntimeType=…FullTextLine
```
⇒ **可判**：① 行内**方向分段**（每个 `textBounds.runs[]` 条目带 `FlowDirection` 真值；`evidence-cd2.md` 还记了一条"纯希伯来文本在 **LTR 段落**里也报 `RightToLeft`"）；② 每个方向段的 **x 区间/宽度**（`RectangleX/Width`）。
⇒ **判不了**：**段内的逐字符视觉序**。实测该 oracle 对 RTL 行 `textBounds` 只有**整行 1 条**、`indexedGlyphRunsIsNull: True` ⇒ **没有逐字符 x、没有逐字形 x**。
（另：614 例的 `cases.json` 全是 `flowDirection=LeftToRight` ⇒ 现 harness 的 RTL 例全在 `cases-cd2.json` 一侧。）

### 3.2 要新增的真值（建议，成本很小）
在 **Windows 侧采集脚本**里对 RTL/混合行**逐字符**调 `GetTextBounds(i, 1)`（返回该字符的矩形 X），并对纯 RTL 行另外采一次 `GetIndexedGlyphRuns()`（若真机给 null 就记为"该 API 在 LS 路径不可用"，别假装有）。
- **机读判据（视觉序）**：
  1. **纯 RTL 行**：`x(i)` 随**逻辑**下标 `i` **单调递减**（相邻差 ≈ 该字符 advance，容差 0.34）；
  2. **混合行**：按 `FlowDirection` 分段，段内按上面规则（LTR 段单调递增、RTL 段单调递减），**段序**要与真值 `runs[]` 的顺序逐项一致；
  3. **段级**：我们每张 `GlyphRun` 的 `(bidiLevel 奇偶, x 区间)` 与真值 `(FlowDirection, RectangleX/Width)` **逐段相等**（容差 0.34）。
- **建议新增用例集**（都放进 Windows 采集，理由逐条）：
  | 用例 | 为什么必须 |
  |---|---|
  | 纯希 / 纯阿（已有 `BD_*_only_rtl_*`） | 基线：单方向视觉序 |
  | **LTR 段嵌 RTL 段**（`abc שלום xyz`） | 唯一能判"按 bidi level 分段"的形状 |
  | **RTL 段嵌拉丁/数字**（`שלום abc 123`） | 判 EN/AN 数字规则与"数字在 RTL 里不反转" |
  | **括号/镜像对**（`שלום (abc) עולם`） | 判 UBA 的 **mirroring**（括号在 RTL 段里要镜像） |
  | **RTL 行里的 tab / 空格 / 行尾空白** | 与 T1d 已落的 tab(0 宽)/记账口径交叉，防"bidi 顺手破记账" |
  | **RTL + trimming** | 折叠与视觉序的交互（`collapseCharacterEllipsis` 真值已有字段） |
- **能变红的牙（必须）**：
  1. **关掉"按 bidi level 分段 shape"** ⇒ 混合方向用例的段级判据必须红（今天就是红的，正好当基线）；
  2. **只设 `hb_buffer_set_direction` 但保留整段一个 buffer** ⇒ 纯 RTL 用例的**逐字符 x 单调性**必须红；
  3. **把 `BidiLevel` 一律填 0** ⇒ 若最终方案依赖它，段级 `(bidiLevel 奇偶)` 判据必须红（这条同时是"渲染侧要不要改"的探针）。

---

## 4. 成本、阶段与风险

### 4.1 分阶段（每阶段都带"可验收读数"）
| 阶段 | 内容 | 可验收读数 | 预计 |
|---|---|---|---|
| **P1** 段落级视觉序 + 逐 bidi-run 重排 | 用树内 `Bidi` 算逐字符 level → 按 level 切 run → 每 run `hb_buffer_set_direction` → 按视觉序拼行 + 填 `BidiLevel` | ① 纯 RTL 行逐字符 x 单调递减；② 混合行段级 `(方向,x区间)` 与真值逐段相等；③ `T1.73/T2/T2b/T2d/T3` **六项不退** | **1–1.5 天** |
| **P2** 命中测试/坐标映射 | `GetTextBounds`/`GetCharacterHitFromDistance`/`GetNextCaret*` 等在 RTL 下的逻辑↔视觉映射 | 与真值 `textBounds`/`caret` 字段对齐；6 个 owed 计数下降 | **1–1.5 天** |
| **P3** 镜像标点/括号 + trimming 交互 | UBA mirroring（`(`↔`)` 等）+ 与 `Collapse` 的交互 | 括号用例逐字符 x/字形对上；折叠明细不退（现 218/236） | **0.5–1 天** |
| （**P0 前置**）**先决定"谁负责镜像"** | 见 §5：确认"HB 视觉序 + 宿主镜像"是否双重反演；这决定 P1 是"取消视觉序交宿主"还是"保留视觉序并抑制镜像" | 一条应用级/像素读数 | **0.25 天** |

### 4.2 最可能翻车的三条 + 早期信号
1. **双重反演**（HB 视觉序 + 宿主 `InvertAxes.Horizontal`）：**早期信号** = 纯 RTL 行在应用里**左右颠倒且字形镜像**（读图一眼可见；也可看 `HBLINE B#` 的 `delta` 与 run origin 是否被推了镜像）。**对策**：P0 前置先定责（很可能要"RTL 段落里我们不再输出视觉序，改回逻辑序交给宿主镜像"，或相反）。
2. **修法依赖渲染侧读 `BidiLevel`，但移植里没人读**（§2.1(d)）：**早期信号** = 我们把 level 填对了、段级判据仍红、像素不变 ⇒ 立刻能判"必须动渲染侧"（**别人车道，需主控协调**）。这是最可能的"工作量翻倍点"。
3. **契约被顺手打破**（`GetTextBounds`/caret/`GetTextRunSpans` 的索引语义）：**早期信号** = 既有 1298 行/3222 行的记账与折叠读数开始漂（注意：现在**没有**判据盯 `textBounds`/caret 的 RTL 行为，所以要么新增判据、要么会静默漂）。

---

## 5. 一个最小否证实验（便宜，含**已做**与**待做**）

**F1（已做，本轮）**：纯希伯来串走我们的路径，读**交给 `GlyphRun` 的字形序列**：
```bash
cd build/MilBridge/tests/CoverageProbe/bin/Release        # 已编好的二进制，未 build
dotnet PresentationCore.Tests.dll --text 'שלום עולם' --em 16 --width 240 --scenario single --inkdiag
```
读数（原文）：`glyphIds=[1332,1331,1324,1337,3,1332,1324,1331,1344]` ⇒ 还原成字符 = `ם ל ו ע ␠ ם ו ל ש` = **逻辑序的整体反序** ⇒
**我们的字形序已是"视觉序"**（HB 猜 RTL 的结果）。这一条**单独**还不足以判"对/错"（视觉序本身在"宿主不镜像"的前提下是对的），
但它把问题**缩小成一句话**：*宿主还会不会替我们再镜像一次*。

**F2（待做，成本 = 一个应用 slot 的读图）**：取**纯 RTL 段落**（`BD_he_only_rtl_*` 那一类，`FlowDirection=RightToLeft`）：
- 若屏上是"**希伯来文正常、从右往左读**" ⇒ 说明**我们的视觉序 + 宿主镜像正好抵消**（即"我们这条路的镜像语义"与上游 `SimpleTextLine` **不同**，将来做 bidi 时**必须避开**再镜像）**← 这就是 F1 结论的直接后果**；
- 若屏上"**左右颠倒 / 字形镜像**" ⇒ 双重反演成立，P0 前置必须先修"镜像归属"；
- 若屏上"**方块/不画**" ⇒ 那是另一条线索（`text-rtl` 块的其它缺口），与本评估并行。
  （**命令**：`WPF_LINUX_HBLINE_TRACE=1` + 能注入 env 的装置起 `WpfFeatureProbe --only=text-rtl`，按 PID 收尾；**需要主控 slot**。）

**F3（最省钱的真值路，供 P1 前做）**：不必等像素 —— 只要 §3.2 的**逐字符 x** 采到，纯 RTL 行的单调性就能当 F2 的替代判据，
因为它**同时**决定"镜像归属"（真值行里 x 必然按逻辑下标递减 ⇒ 屏上从右往左；我们的实现要么自己做到、要么靠宿主镜像做到，二者只能有一个）。

---

## 6. 建议（给主控的一句话）
**值得立项，但先花 0.25 天做 §5-F2/F3 的"镜像归属"判定**：它决定 P1 是"取消视觉序"还是"抑制宿主镜像"，
否则 P1 极可能白做一遍（这也是 §4.2 第 1 条翻车点）。真值成本很低（Windows 侧对 RTL 行加一个逐字符 `GetTextBounds(i,1)` 的采集），
**不需要**改任何既有的 614 例/73 例判据。

---

## 7. P0 追加（2026-09-13）：用离线装置判 T3 的 `text-rtl-pure` 实测 —— **"甲/乙 都不是"可解释，且归因落在两处**

**本轮仍然只读**：没改任何文件（shim 仍 `ebccdb1e…`）、**没 build**、**没跑应用**；只用了**已编好的探针二进制** + 自己的空显示号 `:95`（按 PID 收尾，无残留）。T3 的元组：`bridge=e0d01832… pc=34792537… pf=36abe241… win32shim=e1691fd8… hbtextline=ebccdb1e…`。

### 7.1 离线复现同一串（先把"尺寸对得上"钉住）
T3 自报 `heH=16.3 / heW=65.3` ⇒ 我据 DejaVu 自然行高 1.164em 反推 **em=14**，用同串同字体跑：
```
dotnet PresentationCore.Tests.dll --text 'שלום עולם' --em 14 --width 200 --scenario single --inkdiag
行#0  cp 0..10  Length=10  Width=65.256  Height=16.297  Baseline=12.995  TextHeight=16.2969  Extent=13.5049  ws=1
[inkdiag r0] glyphs=9  inkBox=(0.271,-11.206)-(65.654,2.299) h=13.505  face=DejaVuSans.ttf#0
```
⇒ **`Width=65.256`、`Height=16.297`、`Baseline=12.995` 与 T3 的 `heW=65.3 / heH=16.3`（以及主块历史上的 `originDIP.y=12.995`）逐位吻合** ⇒ 我们的**布局/度量与实跑同源**，
且 **本行墨迹横跨 x≈0.27→65.65（≈65.4 DIP）** —— 这一格是下面所有判断的基础。

### 7.2 逐 run 的 glyphId 全序列 + 逐字形 advance/累计 x（与逻辑码点并排）
同一串，HB（= shim 整形用的同一库/同一字体/同一方向猜测）逐字形读数：
```
i  gid    cluster   advance   cum x    逻辑字符@cluster
0  1332   8          9.290     9.290   ם   ← 逻辑下标 8（最后一个字符）
1  1331   7          7.957    17.247   ל
2  1324   6          3.814    21.062   ו
3  1337   5          8.764    29.825   ע
4     3   4          4.450    34.275   ␠
5  1332   3          9.290    43.565   ם
6  1324   2          3.814    47.380   ו
7  1331   1          7.957    55.337   ל
8  1344   0          9.919    65.256   ש   ← 逻辑下标 0
逻辑串          = ש ל ו ם ␠ ע ו ל ם（下标 0..8）
cluster 序列    = [8,7,6,5,4,3,2,1,0] ⇒ **单调递减 = HarfBuzz 的视觉序**
总 advance       = **65.2559** ⇒ **与 LTR 完全同一个数**（advance 是同一组，只是顺序不同）
```
⇒ **字形序 = 逻辑序的整体反序**（"是否整体反序"= **是**）；**行宽与方向无关**（这解释了 T3 的"同串同字号布局宽度一致 65.3"）。

### 7.3 **`InvertAxes` 在我装置里怎么设 / 两种设置下的差异**
- **方向在我装置里的唯一入口就是 `Draw(..., InvertAxes)`**（钩子签名不带 `FlowDirection`，见 §1.1）⇒ 我用 `--invert` 对同一次排版分别以 `None / Horizontal / Vertical / Both` 调 `Draw`。
- 读数（同串 em=14，段落宽 200）：
```
P9  PASS  Draw 前后**行内 run 原点/字形数逐位不变**（run 原点 (0,12.995)…；只有矩阵变）
P8  PASS  Horizontal ⇒ 绘制树里真有矩阵 M11=-1 M22=1 OffsetX=200 OffsetY=0
P10 PASS  Vertical ⇒ M11=1 M22=-1 OffsetY=16.296875 ；Both ⇒ M11=-1 M22=-1 OffsetX=200 OffsetY=16.296875
```
⇒ **两种设置的差别只有"整行被镜像/不平移"**：`x' = 200 − x`，**跨度（≈65.4 DIP）不变**，只是被搬到 `[134.6, 200]`。
⚠️ 同时注意：**`OffsetX` 用的是"FormatLine 拿到的段落宽"（我这里是 200，不是文本宽 65.3）** ⇒ 若应用里 RTL 行被格式化的**段落宽远大于块自身宽度**，镜像就会把整行搬到块外，**再被宿主的裁剪切掉**（这条正是 T3 看到的"更窄"的候选机制，见 7.5）。

### 7.4 判"甲/乙/都不是"：**都不是**，而且**我们的模型正好预测"都不是"**
- **甲（RTL 逐列 == LTR 逐列）不可能成立**：我们的 **glyph 序列不同**（RTL=视觉序 `[1332,1331,1324,1337,3,1332,1324,1331,1344]`；LTR=逻辑序 `[1344,1331,1324,1332,3,1337,1324,1331,1332]`）⇒ 逐列图案本就不同。
- **乙（RTL == flop(LTR)）也不可能成立**：flop(LTR) 是"**逻辑序**的字形 + 位置/形状镜像"；我们给的是"**视觉序**的字形 + 宿主再镜像" ⇒ 组合出来的序列是 `flop(视觉序)` = **逻辑序但字形被镜像**，与 `flop(逻辑序)` **不是同一串**（一个的字形序是逻辑序的反序，另一个是逻辑序）⇒ 两类签名都落空 ✓ **与 T3 的 `12/23` 与 `6/23` 正好自洽**。
- **"RTL 更窄（23 px vs 58 px）"不能由几何解释**：7.1 实测**本行墨迹跨度 ≈65.4 DIP**，而**任何镜像/平移都保跨度**（7.3 的矩阵只有 m11/offset）⇒ 23 px 只可能是**"测量只覆盖了一部分行"**（宿主裁剪 / 只有部分字形落在测量区 / 精确色计数被抗锯齿吃掉）。
  ⚠️ **仪器警戒**：这里用的是**精确色像素计数**（`#FF2D95` 22 px vs `#00FF7F` 44 px）——**同一个块历史上已经栽过一次**（`#F97316` 精确色 = 0 px，原因是抗锯齿）；
  而**镜像 CTM（m11=−1）恰好会把字形放到分数像素/重采样**，精确色匹配数会大幅塌陷 ⇒ **"23 px" 更像是仪器的产物，不是行的几何**。**这一格必须换仪器**（见 7.6）。

### 7.5 归属：一处在本 shim、一处在本 shim 之外的坐标/裁剪
| 现象 | 归谁 | 依据 |
|---|---|---|
| **字形序 = 视觉序** | **本 shim**（HB 猜方向 + 整段一个 buffer；`hb_buffer_set_direction` 在库内 0 处） | §1.1、§7.2 |
| **`GlyphRun.ClusterMap` 对 RTL 退化**（**新发现**） | **本 shim** | 用我们的 `InvertClusters` 算法在实测 cluster 上模拟：得到 `[0,0,0,0,0,0,0,8,8]`（7 个字符映射到 glyph 0）。契约只要求单调不减/首项 0，**构造不会抛**，所以它**静默错**；渲染不受影响（MIL 不带 cluster），但 **caret/命中/任何读 ClusterMap 的消费者会全错**（P2 的主要地雷） |
| **整行被搬到块外 / 被裁剪**（"更窄"的候选机制） | **本 shim 的镜像基准量**（`_paragraphWidth` = FormatLine 的段落宽）**或宿主传给 `Draw` 的 `origin`/裁剪** | 7.3：镜像跨度不变但**位置由 `OffsetX=段落宽` 决定**；`MS/Internal/Text/Line.cs:79/116`（PC/PF 侧）决定"传不传 Horizontal、`origin.X` 怎么算" |
| **两色/其它** | 与本节无关 | — |

### 7.6 P0 的一句话结论（可落笔）
> **宿主确实会镜像**：只要段落 `FlowDirection=RightToLeft`，`MS/Internal/Text/Line.cs:79` 置 `_mirror`、`:116` 传 `InvertAxes.Horizontal`，而我们 `Draw` 会**真的** push `M11=−1, OffsetX=段落宽`（本轮实测 P8）⇒ **"谁负责镜像"这一问已定：宿主提出、我们按契约执行**。
> **因此 P1 的关键不是"要不要镜像"，而是"我们该不该继续输出视觉序字形"** —— 现在 shim 交视觉序 + 宿主再镜像 = **两次反转**（§7.4 的组合正好解释"甲/乙都不是"）。
> **但"RTL 行更窄"不能拿来做 P0 的判据**：本行墨迹实测跨度 ≈65.4 DIP，几何上不可能变成 23 px；那一格是**精确色计数在镜像 CTM 下的抗锯齿产物**，需换仪器重测（见下）。

### 7.7 下一步该看谁 + 缺的读数（按优先级）
1. **缺 `_paragraphWidth`**（镜像基准量）：站点 B/D 现在**不打印它**（`HbLineTrace.SiteB/SiteD` 打 `hostOrigin` 与 run 原点，但不打 `_paragraphWidth`）⇒ **解冻后加一格**（一行），就能判"是否被搬到块外"。
2. **换掉"精确色像素计数"这个仪器**：用**非精确色的墨迹包络**（阈值化后逐列/逐行求 min/max x），**或**直接在 `MilGlyphRun` 层读 `Origin`（T2b 的 `devY` 那一套已有先例）⇒ 才能量"行的几何"。
3. **宿主的坐标基**：T3 报的 `WFP_BOXID=65x16+86+39`（`TransformToAncestor(Window)`）与截图 `x∈[24,81]` 差 ~62 px ⇒ **先核坐标基**（窗口在 root 的位置 / 裁图原点），再把"布局坐标 vs 绘制坐标差 +73 px"当结论。
4. **P1 的第一个可判实验（很便宜）**：把 RTL run 的**输出序改回逻辑序**（shape 用 RTL、输出前把 glyph/advance 反回逻辑序），让宿主镜像去产生视觉序 ⇒ 用**同一套列轮廓 + 包络**重测：若"RTL == LTR 的镜像"成立（flop 签名），则 P1 方向确定；若不成立，则说明镜像基准/裁剪还有问题（回到第 1、2 条）。

---

## 8. `ClusterMap` 对 RTL 退化：根因 + 修法候选（2026-09-13，**只读**）

**本轮纪律**：**没改任何文件**（shim 仍 `ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf`）、**没 build**、**没跑应用**；
离线装置 = 已编好的探针二进制 + Python 复刻 shim 的算法（逐字等价）；`:95` 自起自灭，**只按 PID 杀**、无残留。

### 8.1 根因（逐字 + file:line）
```
build/shims/PresentationCore.HbTextLine.cs
  :232      r.Clusters[i] = gi.Cluster;                        ← HB 原始 cluster（RTL 下是**视觉序**）
  :2256     InvertClusters(r, chars.Count),                    ← 在 BuildGlyphRun 里（**构造期**）
  :2268-2272  /// clusters：HarfBuzz 给的是「字形→字符」（**单调不减**），WPF 要的是「字符→字形」——
              /// 必须**求逆**。契约（`GlyphRun.cs:370-392`）：个数 == characters.Count、[0]==0、
              /// 单调不减、每个值 < GlyphCount。
  :2273-2289  private static List<ushort> InvertClusters(HbShapedRun shaped, int charCount)
              {
                  int glyphCount = shaped.Glyphs.Length;
                  var map = new List<ushort>(charCount);
                  int g = 0;
                  for (int c = 0; c < charCount; c++)
                  {
                      while (g + 1 < glyphCount && shaped.Clusters[g + 1] <= (uint)c) g++;   // ← 假设"不减"
                      int mapped = g;
                      if (mapped >= glyphCount) mapped = glyphCount - 1;
                      if (mapped < 0) mapped = 0;
                      if (map.Count > 0 && mapped < map[map.Count - 1]) mapped = map[map.Count - 1];
                      map.Add((ushort)mapped);
                  }
                  if (map.Count > 0) map[0] = 0;
                  return map;
              }
```
**冲突点**：注释声称"HB 给的是单调不减"，但 **RTL 下 HB 给的是视觉序 ⇒ cluster 单调递减**（§7.2 实测 `[8,7,6,5,4,3,2,1,0]`）
⇒ `while (… <= c)` 对前 7 个字符**永不前进**（`Clusters[1]=7 > 0`），到 `c=7` 才跳到最后 ⇒ 产出 `[0,0,0,0,0,0,0,8,8]`。

**更深一层的根因（这条才是关键）**：对**视觉序**的字形数组，**任何忠实的"字符→字形"映射都是递减的** ⇒ 它**根本无法**满足 `GlyphRun` 的契约。
证据（上游校验逐字，`GlyphRun.cs:368-395`）：
```
if (clusterMap[0] == 0) { … for (i…) { if ((current >= previous) && (current < glyphCount)) previous = current;
                                       else { if (clusterMap[i] < clusterMap[i-1]) throw …ClusterMapEntriesShouldNotDecrease…;
                                              if (clusterMap[i] >= GlyphCount)   throw …ClusterMapEntryShouldPointWithinGlyphIndices…; } } }
else throw …ClusterMapFirstEntryMustBeZero…;
```
⇒ 校验**只查"递减/越界"**，而 `[0,0,…,0,8,8]` 既不递减也不越界 ⇒ **构造不抛、静默错**（与 §5 登记一致）。
⇒ **真正的根因 = "RTL run 以视觉序交给 `GlyphRun`"** —— 与 §7 的**双重反演是同一个根**。

### 8.2 可达性：与 `InvertAxes` **无关**；现状影响 = **潜伏**
- `map` 在**构造期**生成（`:2256`），`InvertAxes` 只在 `Draw` 生效 ⇒ 两者不相干。实测（同串 em=14，`None` vs `Horizontal`）：
```
P9  PASS  Draw 前后**行内 run 原点/字形数逐位不变**（⇒ 只有镜像矩阵变，run 内容不随 InvertAxes 变）
P8  PASS  Horizontal ⇒ 矩阵 M11=-1 M22=1 OffsetX=200 OffsetY=0
```
- **现状影响 = 0 个"因它而错"的可观测量**，理由是逐字的：我们自己的 caret/命中**本来就是 owed 桩**：
```
:2887  public override CharacterHit GetCharacterHitFromDistance(double distance)
:2889      Owed("GetCharacterHitFromDistance");   return new CharacterHit(0, 0);
:2893  public override double GetDistanceFromCharacterHit(CharacterHit characterHit)
:2895      Owed("GetDistanceFromCharacterHit");   return 0;
```
  ⇒ **RTL 行上"错多少"= 与 LTR 完全相同（恒 `(0,0)` / `0`，且逐次计数）** ⇒ 量化结论：**退化目前不产生额外可观测错误**。
- 树内真实消费者（将来会吃到这个退化）：
  `GlyphsSerializer.cs:36`（XPS 序列化 `_clusters = glyphRun.ClusterMap`）、
  `FixedSOMPageConstructor.cs:434-436`（固定文档 `glyphIndex = glyphRun.ClusterMap[charIndex]`）、
  以及**上游自带的** `GlyphRun.GetDistanceFromCharacterHit`（`GlyphRun.cs:505-516` 用 `ClusterMap` 累加 advance，null 时回落 `DefaultClusterMap`，其取值就是**恒等** `:2203-2208` `return (ushort)index;`）。
  ⇒ 风险集中在 **P2（实现 caret/命中）** 与 XPS/固定文档两条路。
- **缺的读数**：无 —— 这一问用代码 + 离线实测即可定；**要变成"运行时读数"**只需在探针里加一行打印 `gr.ClusterMap`（解冻后再加）。

### 8.3 修法候选（代价/风险 + 推荐）
| # | 做法 | 代价 | 风险 | 评价 |
|---|---|---|---|---|
| **①** | **RTL run 改为逻辑序输出**：shape 仍用 RTL 方向，但把该段的 `Glyphs/Clusters/AdvancesPx/OffsetsXPx` **反回逻辑序**，并把 `BidiLevel` 填 1 | ~15 行（按**段**判方向 + 反转；`InvertClusters` 一行不改） | 必须**逐段**判方向（同在 HBLINE D# 里见过 LTR/RTL 混合段）；`CharAdvances()` 按 cluster 归并到**逻辑下标** ⇒ 与顺序无关 ✓ 不受影响 | **推荐**：它同时修掉 §7 的"视觉序 + 宿主镜像 = 双重反演"⇒ **一处修两个洞** |
| **②** | 退化时给 `GlyphRun` 传 **`clusterMap = null`**（WPF 回落恒等 map） | **1 行** | **只在 `glyphCount == charCount` 且 1:1 时安全**：实测反例 `'لا'` = **2 字符 → 1 字形** ⇒ 恒等 map `[0,1]` 里 `1 >= GlyphCount` ⇒ **构造抛** `ClusterMapEntryShouldPointWithinGlyphIndices` | 只能当"1:1 情况的一行止损"，**不能无条件用** |
| **③** | 在 `GetTextRunSpans`/caret/命中层做逻辑↔视觉换算 | 最高 | XPS 与固定文档那两个消费者**仍然错**；且会碰 M7b 改过的两处 | 不推荐作首选；作为 P2 的**补充层** |

### 8.4 修法之后哪些既有读数会变
- **必须逐位不变**：`T1.73 73/73`、`T2 记账 1286/1298`、`T2b 972/972·213/213`、`T2d 1298/1298`、`T3 折叠 判定1298/1298 明细218/236`、`Tab 0 例` —— 因为**这些语料全是 LTR**，而修法对 LTR 是**恒等**（实测：`'Hello'` 的 clusters `[0,1,2,3,4]` 递增 ⇒ 走原分支，map 与改前**同一个**）。**若六项有任何一项变了，说明修法越界**。
- **会变（且正是目的）**：RTL 行的**字形顺序/位置** ⇒ 应用级列轮廓与 `HBLINE D#` 的 `glyphIds` 顺序；`ClusterMap` 不再退化。

### 8.5 牙齿（离线，先红后绿）
判据（对 1:1 的 RTL 串）：**`ClusterMap` 必须单调不减、首项 0、且"每个字形都属于某个被引用到的簇"**；在 1:1 情形退化为"**覆盖每个字形**"。
```
=== 输入 'שלום עולם'（长 9）===
  HB: glyphs=[1332,1331,1324,1337,3,1332,1324,1331,1344]  clusters=[8,7,6,5,4,3,2,1,0] ⇒ 递减(视觉序)
  [现状] map=[0,0,0,0,0,0,0,8,8]   契约OK；**字形覆盖 = 2/9**；未被触及的字形 = [1,2,3,4,5,6,7]   ⇒ **红**
  [修法①] map=[0,1,2,3,4,5,6,7,8]  契约OK；**字形覆盖 = 9/9**                                ⇒ **绿**
=== LTR 对照 'Hello'：修法对它**恒等**（同一函数、同一输入）: True ===
```
**⚠️ 覆盖类断言只能用在 1:1 的串上**（避免过度修）：实测 `'שָׁלוֹם'`（带 niqqud）= 7 字符 / 7 字形但 clusters `[6,4,4,3,0,0,0]`（**多字形簇**）⇒ 修法①后 map `[0,2,2,3,5,5,6]`、覆盖 5/7 —— **这是正确的**（一个簇有多个字形时，字符→字形映射本来就指不到每个字形）。
⇒ 一般形式的判据应写成："**对每个字符 c，`Clusters[map[c]]` 必须等于 c 所属簇的簇值；且每个簇值都必须被某个字符引用到**"。

### 8.6 落地清单（解冻后可直接照做；**本轮未动**）
1. **改哪儿**：`build/shims/PresentationCore.HbTextLine.cs`
   - `HbShaper.Shape`（`:232` 附近）或 `HbMultiFontShaper.ShapeParagraph`（per-chunk 循环内）：对**该段**判定方向（判据：`Clusters[0] > Clusters[len-1]` ⇒ 视觉序），是则把 `Glyphs/Clusters/AdvancesPx/OffsetsXPx` **整体反转**，并把该段的 `Rtl = true` 带进 `HbShapedChunk`；
   - `HbTextLine.BuildGlyphRun`（`:2256` 附近）：`BidiLevel = chunk.Rtl ? 1 : 0`（现在写死 0）。
   - **`InvertClusters` 一行不改**（逻辑序输入下它本来就对）。
2. **预估行数**：**≈15 行**（判方向 + 4 个数组反转 + 1 个 `Rtl` 字段 + `BidiLevel` 传参）。
3. **验收（缺一不可）**：
   - 牙齿：§8.5 的 1:1 串 **绿**（现在的实现是**红**）；
   - 六项 tline **逐位不变**（§8.4；变了就是越界）；
   - 三形态编译 **0 错 0 警**；
   - RTL 应用级：`HBLINE D#` 的 `glyphIds` 变**逻辑序** + 列轮廓变化（T3 的 slot）。
4. **sha 怎么验**：改后 `sha256sum build/shims/PresentationCore.HbTextLine.cs` 应为**新值**（本轮冻结基线 `ebccdb1e…`），并把它写进报告 §0 的版本纪律；**PC 必须由主控重建**后才可能拿到应用级读数（否则 PC 旧于源 ⇒ 读数无效，见 §0）。
5. **回滚**：改动集中在 `Shape`/`ShapeParagraph` 的一处反转 + `BidiLevel` 一处传参 ⇒ 回滚 = 去掉反转（`BidiLevel` 恢复 0），与今天的 `ebccdb1e…` 逐字节同源可比。

---

## 8.7 修法①**已落地**（2026-09-13，主控授权）—— RTL run 改回逻辑序输出

**sha**：`ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf` → **`1c6c764e38c958580b40701a900a430f767ae84373c0506d44570ce4cd629a4b`**（3815 行）
→ **`d116bcb8a34769d81520a9225a9900f703631f38d3f7a7a04bdb7b89d4e2e4a4`**（3816 行，**仅注释订正**，见 §8.7.1 —— 上表行号按这一版核对）。
**`InvertClusters` 一行未改**（机器核：声明体 `private static List<ushort> InvertClusters(HbShapedRun, int)` 在 `ebccdb1e` `:2273` 与 `d116bcb8` `:2323` **逐字节相同** —— 17 行，体 sha `b34c62fa5f62a13b`）；`GetTextRunSpans()`（M7b 的两处）一字未碰。

### 改了几行 / 每行在哪
| # | 位置 | 内容 |
|---|---|---|
| 1 | `:144-145` | 新增 `hb_buffer_get_direction` 绑定 + `private const int HB_DIRECTION_RTL = 5;` |
| 2 | `:215`（`Shape`，`guess_segment_properties` 之后） | `bool rtlDir = hb_buffer_get_direction(buf) == HB_DIRECTION_RTL;` —— 方向取自 **HB 自己**（不靠猜 cluster 序） |
| 3 | `:263-274`（`Shape` 末尾，`ZeroTabAdvances` 之前） | `:263` `if (rtlDir && r.Glyphs.Length > 1)` → `:265-268` 四次 `Array.Reverse`（`Glyphs/Clusters/AdvancesPx/OffsetsXPx`）→ `:269` `r.Rtl = true`；`:271-274` `else if (rtlDir)` → `r.Rtl = true`（单字形：顺序无从反转，方向仍带下去） |
| 4 | `:90`（`HbShapedRun`，共享层）+ `:556`（`ShapeParagraph`） | 新增 `public bool Rtl;`；合并 run 的 `Rtl` 仅"只有一段"时有意义（多段混合方向时每段自带） |
| 5 | `:2299`（`BuildGlyphRun` 的 `GlyphRun` 第二实参 `face, 0, false, …`） | **`BidiLevel` 保持 0**，理由写在 `:2289-2298` —— 见下面的自我纠正 |

> 行号按 **`d116bcb8`**（见 §8.7.1）核对；`grep -an` 单点锚：`hb_buffer_get_direction`、`rtlDir`、`Array.Reverse`、`public bool Rtl;`、`face, 0, false`。

**`Rtl` 怎么传下去**：`HbShaper.Shape` 读出方向 → 反转该段四个数组 → 置 `HbShapedRun.Rtl`；
多面路径：每段自己的 `HbShapedRun` 挂在 `HbShapedChunk.Run` 上（`BuildGlyphRun(ch.Run, …)` 直接读到）；
单面路径：`FormatLine` 拿到的 `HbShapedRun` 就是 `Shape` 的返回值 ✓ 同一个标记。

### ⚠️ 自我纠正：`BidiLevel` **不能**给 1（我 §8.6 那条写错了，有实测）
- 上游同款路径（`SimpleTextLine` 用的 `GlyphTypeface.ComputeUnshapedGlyphRun`）**传的就是 `0, // bidiLevel`**（`GlyphTypeface.cs:1405`）——它同样靠宿主反镜像产生视觉序；
- 本移植里给 1 ⇒ `GlyphRun.ComputeInkBoundingBox` 走 **RTL 分支**（`IsLeftToRight=false`），**实测墨迹盒**从 `(0.271,-11.206)-(65.654,2.299)` 变成 **`(-64.984,…)-(0.398,…)`**（负 x）；
  而渲染侧 `MilGlyphRunAdapter` **不读 `BidiLevel`**（§2.1(d)）⇒ 照旧按正 advance 从左往右画 ⇒ **"账本说负 x、实际画正 x" = 新的不自洽** ⇒ **保持 0**。
  （`r.Rtl` 仍保留：它是"这一段是 RTL"的事实，供将来 caret/命中与真 bidi 使用。）

### 运行时读数（探针二进制内嵌 shim，`--inkdiag`；本轮给探针加了 `clusterMap=`/`bidiLevel=` 一格**只读**读数）
```
改前（内嵌 ebccdb1e）：glyphIds=[1332,1331,1324,1337,3,1332,1324,1331,1344]  ← **视觉序**
改后（内嵌 1c6c764e）：glyphIds=[1344,1331,1324,1332,3,1337,1324,1331,1332]  ← **逻辑序**（首=ש 下标0，末=ם 下标8）
                       clusterMap=[0,1,2,3,4,5,6,7,8]   （改前**按 §8.5 模拟**为 [0,0,0,0,0,0,0,8,8]）
                       ⇒ 牙齿：字形覆盖 **2/9 → 9/9**（红 → 绿）
                       bidiLevel=0；Width=65.256 / Height=16.297 / Baseline=12.995 / Extent=13.5049 **逐位不变**
LTR 对照（同装置 'Hello world'）：clusterMap=[0,1,2,3,4,5,6,7,8,9,10]、bidiLevel=0 ⇒ **恒等**
```

### 不回归（离线已确认）
```
run.sh tline：T1.73 ✅73/73；T2 记账 1286/1298（①286/286 ②68/68 ③984/988 宽度超差47）；
              T2b 972/972·213/213；T2d ✅1298/1298；T3 判定1298/1298 明细218/236；Tab 0 例；通过19/失败2
run.sh icu  ：73 例逐例全等（Stage B/C 不一致 = 0）
三形态编译  ：DirectBranchCheck / HbTextLineParity / CoverageProbe 各 **0 错 0 警**
```
**"LTR 零影响"的受控证明**：**同一个 harness 二进制**、只换 shim（`-p:HbShimSrc=/tmp/t1d-shim-runbrush.cs`，
其 sha 实测 = `ebccdb1e…`）⇒ 两次输出**除 `T0.6` 身份行外逐字节相同**（diff 仅 2 行：`T0.6` 与由它引起的 `通过 18/失败 3` vs `19/2`）。

### T3 的四条验收（写死）
1. `he_pure_RTL` 包络宽 **31 → ≈66**；2. `he_pure_RTL` 的 **Δx −74 → ≈+2**；
3. `ar_with_punct_digits_RTL` **不再**与 `ar_pure_RTL` 逐桶相同；4. **六项 tline 逐位不变** —— **第 4 条已在本轮离线确认**；
第 1–3 条要 **PC 重建（主控）+ 应用 slot（T3）**。本修法去掉的正是"两次反转"这一根因（改前：视觉序 run + 宿主镜像 ⇒ 行被搬到块外）。
（`ar_*` 行的 advance 我这边只能给"同串同字体"的口径；应用级数字以 T3 为准。）

### 射程声明（必须写清）
**混合方向不在本修法的射程内。** 本修法只处理"**整段同向**"的 RTL run（方向由 HB 对**该段**解析，段内只有一个方向）。
"LTR 里嵌 RTL（或反之）"仍需**段落级 UBA** + 逐 bidi-run 切段（§2.1(a)：树内 `MS.Internal.TextFormatting.Bidi` 或 ICU `ubidi`）⇒ 那仍是 §4 的 P1 主体。
T3 已把 `text-rtl` 混合块的现状留档在 README §⑬ 作对照。

### 回滚方法
去掉 `Shape` 末尾那段 `if (rtlDir && …) { Array.Reverse(…); r.Rtl = true; }`（或把 `rtlDir` 置 `false`）即可回到 `ebccdb1e` 的行为；
`Rtl` 字段与 `hb_buffer_get_direction` 绑定**留着无害**（不参与绘制）。回滚后 `sha256sum` 应逐字节等于 `ebccdb1e…`。

---

## 8.7.1 落地后订正（`1c6c764e` → **`d116bcb8`**）：注释订正 + 逐字节 A/B 自证

### 订正了什么
我落修法①时在 `Shape` 里留的注释写的是"**【BidiLevel】同一处把方向带给 `BuildGlyphRun`（改前恒 0）**"，
而**代码在 `:2299` 传的是字面量 `0`**（`face, 0, false, …`）——即 §8.7 那条自我纠正的**结论**落地了、**注释没跟着改**。
注释与代码相反是最坏的一类注释（下一个人会把注释当契约）⇒ 已改为与代码一致的两行（`:259-260`）。

### 三条机器可查的"只动了注释"证明
1. **重建 sha 命中**：按原文把这两行写回 ⇒ `sha256sum = 1c6c764e38c958580b40701a900a430f767ae84373c0506d44570ce4cd629a4b` **逐字节命中**上一轮已验证的 sha
   ⇒ `1c6c764e` 与 `d116bcb8` 之间的**全部**差异就是这 2 行（文件存于 `/tmp/t1d-shim-rtl-1c6c764e.cs`，可复核）。
2. **`diff` 原文**：`259c259,260`，两行均以 `//` 开头 ⇒ 不是代码。
   ```
   <                 // 【BidiLevel】同一处把方向带给 `BuildGlyphRun`（改前恒 0）。
   ---
   >                 // 【BidiLevel】**不给**方向：`BuildGlyphRun` 照旧传 0（理由见该处注释——上游同款路径也是 0，
   >                 //   给 1 会让 `ComputeInkBoundingBox` 走 RTL 分支、而渲染侧不读它 ⇒ 账本与实画不自洽）。
   ```
3. **A/B 逐字节**（最强的一条）：同一 harness 源，只把 `-p:HbShimSrc=` 换成上面那份 byte-exact 的 `1c6c764e` 重建并运行
   ⇒ 两次输出 **172 行完全相同**，`diff` 只报"一个行尾空行"：
   ```
   $ diff <(sed -n '28,200p' /tmp/t1d-tline-d116bcb8.log) /tmp/t1d-tline-1c6c764e-ab.log
   173d172
   <            ← 只差这一个空行
   ```
   两边 `T1B_SHIM_SHA256` **都固定为真源 sha `d116bcb8`** ⇒ 身份断言 `T0.6` 两边都**通过**，
   不靠"故意让身份行变红"来制造差异（上一轮那次 A/B 是 18/3 vs 19/2，因为 T0.6 红了）。

### 记账读数订正（我自己的旧账）
我此前记 T2d `Extent 1259/1298`；本轮**两次独立实测**（真源 `d116bcb8` 的 run.sh 那次、`1c6c764e` 的 A/B 那次）**都是 `1260/1298`**
（余差 **38** 条属主对拍集，另 20 条在 LH 组，故清单写"共 58 条"）。
⇒ **`1259` 是 Tab 修法之前的旧读数**，与本轮无关；§8.7 的"六项不变"以本轮 `通过 19 / 失败 2` 那次为准（逐项见上）。

### 版本纪律：用**二进制标记**证明 PC 里没有修法①（不是看 mtime 猜）
PC = `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`，sha `455ddb381743df1fa29bfc8cb5149526c184a9a8fe2683f72cae4ad60b5391cd`，mtime `2026-09-13 19:37:03`（shim `19:42:44`）。

| 标记 | 在 PC 里 | 说明 |
|---|---|---|
| `hb_buffer_guess_segment_properties` / `hb_shape` / `HbMultiFontShaper` / `HbFontPlanner` / `PositionedRuns` / `ComputeInkExtent` / `OverlayTabs` / `BuildAntiInversion` / `antiMatrixMismatch` / `invertedNoWidth` | **在**（各 1 次） | R1、摞印、Extent、Tab、P0 反镜像**都已进 PC** |
| `hb_buffer_get_direction` | **不在**（0 次） | ⇒ **PC = shim 减去修法①** |

⇒ 修法① 目前**只在我这份源 + 我的探针二进制里**；T3 的三条应用级读数（①②③）**必须等主控重建 PC**。
本轮我**不下任何应用级结论**。（标记法自证：同一 `grep -ac` 手法在 R1/摞印/Extent/P0 期的名字上都命中 ✓，不是"全都 0"的假读数。）

### 顺手发现（不在我车道，只报不改）
`run.sh:182-204` 的 `refresh_applocal()` 用 `$ROOT/build/…` 拼路径，而 `ROOT`（`run.sh:29` = `$MB/..`）本身就是 `…/wpf-linux/build`
⇒ 拼成 `…/wpf-linux/build/build/…`，四个"权威产物"**永远判为缺失并静默跳过**（本轮日志里 4 行 `[applocal] 权威产物缺失（跳过）` 可复现）。
**实测影响 = 无**：`HbTextLineParity.csproj:39-42` 用 HintPath + `<Private>true</Private>` 直接引用权威 PC，构建即拷；
实测 `bin/Release/PresentationCore.dll` 与权威件 **sha 相同**（`455ddb38…`，4180480 B）。
⇒ 属"死代码 + 误导性日志"，建议主控把 `$ROOT/build/…` 改成 `$ROOT/…`（或 ROOT 取 `$MB/../..`）。

### 运行时读数复核（新 sha `d116bcb8` 内嵌探针，逐位同 §8.7）
```
行#0 Length=10 Width=65.256 Height=16.297 Baseline=12.995 TextHeight=16.2969 Extent=13.5049
[inkdiag r0] glyphs=9 inkBox=(-0.398,-11.206)-(64.984,2.299) h=13.505 face=DejaVuSans.ttf#0
             glyphIds=[1344,1331,1324,1332,3,1337,1324,1331,1332] clusterMap=[0,1,2,3,4,5,6,7,8] bidiLevel=0
LTR 对照 'Hello world'：clusterMap=[0,1,2,3,4,5,6,7,8,9,10] bidiLevel=0
```
⇒ 逻辑序、覆盖 9/9、度量逐位不变 —— 与 `1c6c764e` 那轮**完全一致**（与上面 A/B 的 172 行全等互为佐证）。

---

## 9 修法① 应用级验收"不过"的根因分析（2026-09-13，**只读轮，未改 shim**）

### 9.0 口径与出处
- **两份 JSON 各自的元组**（原文在文件头）：修法① 前 `pc_sha=29a7939cb37152a9 pf_sha=d7e48055e0b98b8a`；修法① 后 `pc_sha=6dfacf822e4163bb pf_sha=c08ac77204cc5b80`
  ⇒ **这一波变的不只是 hbtextline：PF 也换了 sha**（这一点后面判"LTR 行轮廓变了"时要用到）。
- **修法① 确实进了应用**（二进制标记法）：`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` = `6dfacf822e4163bb08acb3da11c3025e2b68ca7ac2f6caa679a07b216e1fba77`（mtime 19:49:45），`grep -ac hb_buffer_get_direction` = **1**（上一轮同一手法测得它是 0）。
- 数据：`samples/WpfFeatureProbe/rtl-baseline-20260913.json`、`rtl-after-fix1-20260913.json`；帧 `/home/links-dev/wfp-runs/go-rtl{base2,fix}/b-only-1.png`（470×400）；HBLINE 原文 `/home/links-dev/wfp-runs/go-rtlfix/probe-only.log`；
  样例源码 `samples/WpfFeatureProbe/FeatureBlocks.cs:633-692`（⑩ 块：5 个 `TextBlock`，FontSize=14，`HorizontalAlignment=Left`，四个 RTL + 一个同串 LTR 对照）与 `:92-105`（`ReportBox` = `TransformToAncestor(Window)` 的 (0,0) 点）；读图工具 `tests/WpfGfx.Linux.Tests/Presentation.Tests/rtl-ink-profile.py`。

### 9.1 结论摘要（四条）
1. **修法① 生效了**（顺序真的改了：`clusterMap` 2/N→N/N、`glyphIds` 由视觉序变逻辑序），但它**对"墨迹包络宽度"是恒等变换** ⇒ 验收①（宽 31→≈66）**在原理上不可能由任何"顺序"修法达成**（§9.3 逐串实测）。
2. **①② 不过的主导缺陷与顺序无关**：⑩ 块四条 RTL 行的文字被画在**离其布局位置约 44 px 的左侧**，行头被**容器内容边缘切掉约 34 px**（四条行"缺失量"33.1–35.3 px）⇒ 量到的"包络宽 30/40/62/35"量的是**裁剪窗口**，不是文字。
3. **T3 的 Δx 口径对 RTL 行含一个整行宽的假偏差**：`WFP_BOXID` 的 x 恰好 = `21 + ActualWidth`（86=21+65.3、95=21+73.8、117=21+96.4、89=21+68.1；LTR 对照行报 21 且墨迹就在 [22,88]）⇒ RTL 行报的是**镜像后的角点**，Δx=−73/−82/−105/−77 里含了 +行宽；相对同串 LTR 对照行的真实左移量约 **44 px**。
4. **修法① 在 shim 层是对的**（上游契约 + ClusterMap 2/9→9/9 + LTR/CJK 逐字节不变，§9.3/§9.6）；但**在产品层它可能把这四行画成"反的"**——因为"画出来的左端与行宽无关"这个签名说明这条路径上**净效果是一次平移（而非一次镜像）**，即**外面还有一次镜像**（§9.5 给出一次读数就能判死）。

### 9.2 逐项实测（原始读数）
**(a) 应用侧表**（T3 JSON；括号内是我用整帧颜色扫描复核的结果，阈值不同故 ink 数略异，**包络完全一致**）

| 行 | 修法① 前 包络/宽/ink | 修法① 后 包络/宽/ink | 报的框 | T3 Δx |
|---|---|---|---|---|
| `he_pure_RTL` | [12,42] / 31 / 130 | [13,42] / **30** / 119 | {x86,y198,w65,h16} | −73 |
| `he_same_string_LTR` | [23,88] / 66 / 260 | [22,88] / 67 / 260 | {x21,y218,w65,h16} | **+1** |
| `ar_pure_RTL` | [18,49] / 32 / 134 | [13,52] / **40** / 219 | {x95,y239,w74,h16} | −82 |
| `he_with_digits_RTL` | [12,73] / 62 / 253 | [12,73] / 62 / 246 | {x117,y259,w96,h16} | −105 |
| `ar_with_punct_digits_RTL` | [14,45] / 32 / 132 | [12,46] / 35 / 123 | {x89,y279,w68,h16} | −77 |

**(b) "缺失量" = 行宽 − 可见宽**（行宽取我的探针实测 `Width`，与站点的 `w=` 一致）
`he` 65.256−30 = **35.3**；`ar` 73.849−40 = **33.8**；`heNum` 96.428−62 = **34.4**；`arNum` 68.059−35 = **33.1** ⇒ **34.2 ± 1.1（4/4 条都一样）**
**(c) "画出来的左端" = 可见右端 − 行宽**（帧坐标）
`he` 42−65.256 = **−23.3**；`ar` 52−73.849 = **−21.8**；`heNum` 73−96.428 = **−23.4**；`arNum` 46−68.059 = **−22.1** ⇒ **−22.6 ± 0.8（4/4）**
★**关键签名**：四条行宽差 31 px，而"画出来的左端"只差 1.6 px ⇒ **这个左端与本行的宽度无关** ⇒ 净效果是**平移**（一次镜像会让右端/左端随行宽变化）。而 LTR 对照行画在 [22,88] ⇒ **RTL 行相对它左移 ≈ 44 px**。
**(d) 切口在容器内容边缘（像素证据）**：`convert b-only-1.png -crop 34x1+0+215 +repage txt:-`
`x=0..11` = `#10141C`（窗口底）｜`x=12` = `#1B2330`（过渡）｜**`x=13` = `#592C54`（已含品红墨迹）**｜`x=16..17` = `#1B2436`（卡片底色）
⇒ 墨迹**恰好从容器内容边缘开始**，其左侧无墨迹 ⇒ 行头是**被切掉**，不是"没画"。
**(e) 字形确实全提交了**：`HBLINE D#0 cpFirst=0 brush=#FFFF2D95 glyphRuns=1 [r0 face=DejaVuSans.ttf glyphs=9 chars="שלום עולם"]`；
    站点 B：`HBLINE B#0 cpFirst=0 cpLast=10 len=10 nl=1 h=16.2969 bl=12.9951 w=65.2559 hostOrigin=(0.0000,0.0000) glyphRuns=1 runOrigins(已烘入宿主原点)=[(0.000,12.995)] delta=0.0000 inv=1`（同串 LTR 行 `inv=0`）
⇒ 宿主**确实**按 `MS/Internal/Text/Line.cs:79/116` 传了 `InvertAxes.Horizontal`（主控假设"甲"在 API 层成立），而 shim 侧 `Draw` 与上游 `SimpleTextLine.Draw`（`SimpleTextLine.cs:482-505`）+ `CreateAntiInversionTransform`（`TextFormatterImp.cs:565-595`）逐字段同式。

### 9.3 机器证明：修法① 对"墨迹包络宽度"是恒等变换（探针 A/B，只换 shim 源）
同一探针源、`-p:HbShimSrc=` 换成 `refs/PresentationCore.HbTextLine.ebccdb1e.cs`（sha `ebccdb1e…`=修法①前）vs 真源（`d116bcb8…`）：

| 串（em=14, DejaVu） | Width 旧/新 | Extent 旧/新 | inkBox 宽 旧→新 | clusterMap 覆盖 |
|---|---|---|---|---|
| `שלום עולם` | 65.256 / 65.256 | 13.5049 / 13.5049 | 65.383 → **65.382** | 2/9 → **9/9** |
| `مرحبا بالعالم` | 73.849 / 73.849 | 16.0547 / 16.0547 | 73.777 → **76.122** | 2/13 → **13/13** |
| `שלום 123 עולם` | 96.428 / 96.428 | 13.6895 / 13.6895 | 96.555 → **96.554** | 2/13 → **13/13** |
| `مرحبا، 123` | 68.059 / 68.059 | 16.0547 / 16.0547 | 67.878 → **69.075** | 2/10 → **10/10** |
| `Hello world` | 78.483 / 78.483 | 12.8350 / 12.8350 | 77.838 → 77.838 | 11/11（**逐字节相同**） |
| `中文混排 test` | 87.336 / 87.336 | 15.0200 / 15.0200 | r0/r1 均**逐字节相同** | 4/4 + 5/5（**逐字节相同**） |

⇒ 希伯来两条的墨迹盒宽度变化 **≤0.001 px** ⇒ **改顺序 = 改不动包络宽度**（这正是验收①不可能靠顺序达成的证明）；
⇒ 阿拉伯两条 +1.2 / +2.3 px（反序把连写形态换了字形，两侧 bearing 变了）——方向与应用侧 `ar` 行 ink 134→219 一致，但应用侧那 85 px 的增量主要来自**裁剪窗口内的重排**，不是包络变宽。

### 9.4 为什么"阿拉伯变了、希伯来几乎没变"
- **两条其实都变了**（he：`binned8 [39,28,33,30]→[35,28,33,23]`、ink 130→119；ar：`[44,32,27,31]→[40,53,46,49,31]`、ink 134→219、可见宽 32→40）。
  **没变的是"可见段的位置与宽度"**（he 31→30、左端 12→13）——而位置/宽度由 §9.2(b)(c)(d) 的**位移+裁剪**决定，与顺序无关。
- ar 变化大是因为阿拉伯字形有**上下文形态/连字**：反序会把不同的字形摆进那个 30–40 px 的窗口；希伯来是 1:1 字形，反序后窗口内墨迹总量几乎不变（130→119）。机制侧可复核的同类读数见 §9.3（ar 的 inkBox 宽 +2.3 px、arNum +1.2 px；希伯来 0.001 px）。
- ⚠️ **"可见段内部顺序对不对"用列轮廓判不出来**：我把 he 的可见段与 LTR 全串做切片匹配 —— 正序最佳偏移 36、平均|Δ|=**1.28**；反序最佳偏移 13、**1.59** ⇒ 正序"略优"但差得不干净（希伯来两个字共享 ל/ו/ם 的列形，轮廓区分度不足）⇒ **不要用列轮廓下"顺序对了"的结论**，要用 §9.5 的读数。

### 9.5 下一个最小修法：**先补一格读数**（0 行为改动），再动代码
**为什么要先补**：现在缺的正好是把"多出来的那 44 px"归到哪一层的那个数（= handoff.md 列的"缺的读数①"）。
1. `HbLineTrace` 站点 B 加 `pw=`（`_paragraphWidth`）：现在站点 A/B 打的 `w=` 是 **`line.Width`**（`build/shims/PresentationCore.HbTextLine.cs:1933` 的 `line.Width`），**不是段落宽**。
2. 宿主侧一行：`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:238-240` 把传进 `FormatParagraph` 的 `paragraphWidth` 打进日志（PC 车道）。
**判别表**（拿到 `pw` 立刻二选一，不用猜）：
- `pw ≥ 行宽`（**必然**：站点 B 显示 `len=10`、`w=65.2559` 单行无折行 ⇒ 格式宽度 ≥ 行宽，而 `_paragraphWidth` 是 `readonly`（`:2078/:2117`）且与格式化同一个实参 ⇒ 镜像基准不可能小于行宽）⇒ shim 把 run 放在**行内** `[pw−W, pw]`（`pw−W ≥ 0`）⇒ 观测到的"画出来的左端 −22.6（帧坐标）/相对 LTR 行 −44"**只能来自宿主的绘制原点/视觉层** ⇒ 缺陷在宿主侧（不是 shim 的顺序，也不是 shim 的镜像基准）。
- `pw == 行宽`（TextBlock 把格式宽度夹到自身宽度的可能）⇒ shim 的镜像退化成**就地镜像**（位置不变、顺序翻转）⇒ 此时**修法① 会把纯 RTL 画反**，而"退回视觉序"才对——但这只在"宿主不再另加一次镜像"时成立。
⇒ **两种世界的分辨判据**：同一行、同一 shim，只把 `FlowDirection` 由 RTL 换成 LTR（T3 已有 `he_same_string_LTR`）：LTR 行 [22,88] 完整、RTL 行 30 px 残条 ⇒ 差异**只**来自镜像/位移这条路径（已满足）；再加一格 `pw` 就能分开"宿主位移"与"shim 基准"。
**定位后预期**：`he_pure_RTL` 的包络宽 30 → **≈65（= 行宽）**、可见左端 13 → **≈22（与同串 LTR 对照行对齐）**；建议把验收①② 的判据改成"与**同串 LTR 对照行**对齐 + 墨迹总量相当"，比"绝对宽度 66 / Δx +2"稳（后者把上面第 3 条的 +行宽 假偏差也算进去了）。
**会不会影响 LTR**：不会，且已有机器证明 —— §9.3 表的 `Hello world` / `中文混排 test` 在 A/B 下**逐字节相同**；`run.sh tline` 六项在 `d116bcb8` 与修法①前基线**逐项相同**（通过 19 / 失败 2；T2 1286/1298、T2b 972/972·213/213、T2d H/B 1298/1298+Extent 1260/1298）。

### 9.6 交付给 T1b 的严格 A/B（修法①前的 shim 源）
- **稳定路径**：`build/MilBridge/tests/CoverageProbe/refs/PresentationCore.HbTextLine.ebccdb1e.cs`
  sha256 = **`ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf`**（3766 行）= 修法① **之前**的源（上轮 `/tmp/t1d-shim-runbrush.cs` 的副本，sha 逐字节一致；`/tmp` 会被清，故放进我的车道目录；该工程 `EnableDefaultCompileItems=false` ⇒ 这份参考件不会被编进探针）。
- **配方**（两边 `T1B_SHIM_SHA256` **都固定为真源 sha** ⇒ `T0.6` 两边都过，diff 只反映真实行为差异）：
```bash
PRE=$PWD/build/MilBridge/tests/CoverageProbe/refs/PresentationCore.HbTextLine.ebccdb1e.cs
REAL=$(sha256sum build/shims/PresentationCore.HbTextLine.cs | cut -d' ' -f1)
cd build/MilBridge/tests/HbTextLineParity
dotnet build -c Release -m:1 --nologo -p:HbShimSrc="$PRE"
( cd bin/Release && T1B_SHIM_SHA256="$REAL" dotnet MilBridge.HbTextLineParity.dll > /tmp/pre.log )
dotnet build -c Release -m:1 --nologo          # 恢复真源
( cd bin/Release && T1B_SHIM_SHA256="$REAL" dotnet MilBridge.HbTextLineParity.dll > /tmp/post.log )
diff /tmp/pre.log /tmp/post.log
```
- **预期**：语料全是 LTR/CJK ⇒ RTL 分支不触发 ⇒ **diff 应为空**（我同装置探针 A/B 的 LTR/CJK 两串已逐字节相同）。
- **回滚法**（若主控裁决回滚）：删 `build/shims/PresentationCore.HbTextLine.cs:263-274` 的 `if (rtlDir …)` 段即可（`Rtl` 字段与 `hb_buffer_get_direction` 绑定留着无害）。

### 9.7 本轮边界（我没做什么）
未改 `build/shims/**`（按指示）、未跑应用、未动 `samples/**`、`src/**`、`build/*.Linux/**`、`build/MilBridge/**` 里别人的文件；唯一新增是我车道内的只读参考件 `refs/PresentationCore.HbTextLine.ebccdb1e.cs`。

### 9.8 补记（同装置 A/B 已由我跑完；以及两条版本纪律读数）
**(A) "LTR/CJK 恒等"的严格 A/B —— 已完成，结果是 `diff` 为空**
同一 harness（当前 `HbTextLineParity` 源码）、同一 PC（当前权威件）、**只换 shim 源**：
```
PRE  = refs/PresentationCore.HbTextLine.ebccdb1e.cs   (sha ebccdb1e…, 修法①之前)
POST = build/shims/PresentationCore.HbTextLine.cs     (sha d116bcb8…, 修法①之后)
$ diff /tmp/t1d-tline-ebccdb1e.log /tmp/t1d-tline-post-now.log
DIFF_RC=0        ← 两份日志**逐字节相同**
两边：通过 20 / 失败 2；T1.73 73/73；T2 记账 1286/1298（①286/286 ②68/68 ③984/988 宽度超差47）；
      T2b 972/972·213/213；T2d Height/Baseline 1298/1298、Extent 1260/1298；Tab 不一致 0 例
```
⇒ 修法① **对 LTR/CJK 语料零影响**（这是 T1b 想要的那条 A/B，配方见 §9.6；T1b 可直接复核，或引用本条）。

**(B) harness 新长了一条 `T0.7`**（我上一轮的基线日志里没有 ⇒ 拿旧日志直接横比会凭空多 13 行差异、通过数 19→20，**那是装置变化不是行为变化**）：
```
[T0.7] PresentationCore.dll 副本=B5FC5BA10DC0BBD8 权威=B5FC5BA10DC0BBD8 ✓ 一致  (WindowsBase / DirectWriteForwarder / Provider 同)
✅ T0.7 探针目录里实际加载的 4 个副本 sha 与权威件逐一相同（测量对象被钉住）  一致 4/4
```
⇒ 这正好补上我在 §8.7.1 报的"`refresh_applocal` 死路径"带来的风险（现在"测的是哪一份 PC"被 T0.7 钉住了）。

**(C) 版本纪律：PC 在 T3 验收**之后**又动过**
| | PC sha | mtime | 修法① 在内？ |
|---|---|---|---|
| T3 验收那趟（两份 JSON 的 `pc_sha`） | `6dfacf822e4163bb…` | 19:49:45 | 是（`hb_buffer_get_direction` 命中 1） |
| 我这一轮看到的权威件 | **`b5fc5ba10dc0bbd8fb1a232fa20f484e1efe7559f45f9b1b0ea0966c5f8a9ab0`** | **20:16:53** | 是（命中 1） |

⇒ §9.2 的表**只对 `6dfacf82` 那份 PC 有效**；复measure 必须**钉住 PC sha**（否则又会出"两趟不同 PC"的横比）。

---

## 10 判别读数 `pw` / `W` / `pw−W`（2026-09-13，**只加一格读数，未改修法①**）

### 10.0 新 sha 与"只加读数"的机器证明
- **新 shim sha = `13992b58905d00e0aea8736c14a94836515f9d4355e2db75dc12d1af00a89e91`**（3832 行；上一版 `d116bcb8…` = 3816 行）
- **只加读数的证明**：把新增的 11 行按原文删掉重建 ⇒ `sha256sum` **逐字节命中 `ebccdb1e`→`d116bcb8`** 中的后者（重建件 `/tmp/t1d-recon-d116bcb8.cs` = `d116bcb8a34769d81520a9225a9900f703631f38d3f7a7a04bdb7b89d4e2e4a4`）；
  `diff` 只有两处：`1957a1958,1965`（站点行尾追加三格）与 `2612a2621,2628`（只读属性 + 注释）⇒ **修法① 的代码（`Shape`/`Draw`/`BuildGlyphRun`）逐字未动**。
- **行为不变**：同一 harness、同一 PC，只换 shim（重建件 vs 新件）⇒ `diff` **为空（`DIFF_RC=0`）**，两边 `通过 20 / 失败 2`。
- 三形态编译：`DirectBranchCheck` / `HbTextLineParity` / `CoverageProbe` 各 **0 错**。
- 新增代码坐标：`:2621-2628` `internal double ParagraphWidthForDiag => _paragraphWidth;`（只读属性）；`:1958-1965` 在站点 A/B 行尾追加
  `" pw=" + pw.ToString("F4") + " W=" + line.Width.ToString("F4") + " pw-W=" + (pw - line.Width).ToString("F4")`。

### 10.1 逐行原始读数
**(a) 探针（真的 `Draw(InvertAxes.Horizontal)`：P7/P8/P9 全 PASS；自起 Xvfb `:97`，按 PID 收）**
```
--width 65.2559 : pw=65.2559 W=65.2559 pw-W=0.0000  inv=1   ← 「镜像就地」（位置中性、顺序翻一次）
--width 200     : pw=200.0000 W=65.2559 pw-W=134.7441 inv=1  ← 「镜像把 run 推到行内右侧」
（探针自报也印证：`—— InvertAxes/RTL 检查（本行段落宽=65.3，由 FormatLine 传入）——`）
```
**(b) harness 语料（trace 打开，60 行；节选；多宽度、含折行）**

| 站点行 | cp 区间 | `pw` | `W` | `pw−W` |
|---|---|---|---|---|
| A#0 | 0..16 | 200.0000 | 186.2400 | 13.7600 |
| A#48 | 48..65 | 200.0000 | 198.1680 | **1.8320** |
| A#19 | 19..34 | 150.0000 | 148.1520 | **1.8480** |
| A#84 | 84..92 | 200.0000 | 85.9440 | 114.0560 |
| A#0 | 0..8 | 150.0000 | 91.1760 | 58.8240 |
| A#31 | 31..48 | 200.0000 | 186.0240 | 13.9760 |

- **`pw−W < 0` 的行数 = 0（60/60）** ⇒ `pw` 确实是**换行基准**，且**每行都装得下** ⇒ 镜像后 run 永远落在行内
  `[pw−W, pw]`（`pw−W ≥ 0`）⇒ **shim 的镜像不可能把 run 搬到行外** ✓
- 语料里最小 `pw−W = 0.5280`（"行几乎填满段落"的样本本来就有）。

### 10.2 判别表结论：应用落在 **"`pw ≈ W` ⇒ 镜像就地"** 这一支
**静态链（不需要应用、不需要 PC）**：
`TextBlock`（upstream 源，由 `build/PresentationFramework.Linux` 编译）→ `wrappingWidth = CalcWrappingWidth(RenderSize.Width)`
（`TextBlock.cs:1395 / 1500 / 1540 / 1657 / 1785 / 2031 / 2068 / 2114`）→ `Line.Format(dcp, wrappingWidth, …)`（`MS/Internal/Text/Line.cs:74/83`）
→ `TextFormatter.FormatLine(..., paragraphWidth = width, ...)` → 我方拦截 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:238-240`
→ `HbTextLineFactory.FormatParagraph(..., paragraphWidth, ...)`。
`CalcWrappingWidth`（`TextBlock.cs:3160-3228`）= 夹到 `[_previousDesiredSize.Width, _referenceSize.Width]`、减 padding、
Display 模式再 `+0.5/DpiScaleY`、padding≠0 时 `+1e-11`。
⑩ 块的行是 **Auto 宽**（`FeatureBlocks.cs:641-649`：无 `Width`、`FontSize=14`、`HorizontalAlignment=Left`）
⇒ `RenderSize.Width = ActualWidth = 65.3`（应用自报 `heW=65.3`，与 T3 报框 w=65 一致），padding = 0
⇒ **`pw = 65.3`（Ideal，默认）或 `65.8`（Display）**，而该行 `W = 65.2559` ⇒ **`pw−W = +0.04 … +0.55 px`**。
⇒ 与 10.1(a) 第一种 regime **同款**：**镜像就地**（位置中性、只沿 x 把顺序翻一次）。
⇒ **"RTL 行被搬到块外 ≈44 px" 与镜像基准无关**（`pw−W≈0` ⇒ 镜像不产生位移）⇒ 只能是**宿主绘制原点/视觉层** ✓
   （与 §9 的"画出来的左端与行宽无关 = 平移签名"互为印证）。
**已排除的宿主候选**：`CalcContentOffset`（`TextBlock.cs:3091-3116`）在 `TextAlignment.Left` 下 **X 偏移恒 0** ⇒ 不是它。

### 10.3 ⚠️ 自我纠正：§9.5 判别表第二支的**结论**写错了
§9.5 我写的是："若 `pw == W` ⇒ shim 的镜像退化成**就地镜像** ⇒ **修法① 会把纯 RTL 画反、应当回滚**"。
**结论错**，错在把"位置中性"当成了"镜像没发生"：`pw ≈ W` 时镜像**照旧发生**，只是**位置中性**——
它把数组顺序沿 x **翻一次** ⇒ **逻辑序输入 → 屏上呈现视觉序 = 正确 RTL**；被翻反的恰恰是**修法① 之前的视觉序输入**。
**顺序方向的实测锚（离线机读，不靠列轮廓）**——串 `שלום 123 עולם`（'1','2','3' 的 glyph id = 20,21,22）：

| | 数字段 glyphIds | 读作 |
|---|---|---|
| 修法① **前**（HB 原始输出） | `[…,3,22,21,20,3,…]` | **"3,2,1"** |
| 修法① **后** | `[…,3,20,21,22,3,…]` | **"1,2,3"** |

⇒ **HB 的原始输出 = 逻辑序的整体反序**（连内嵌数字一起反 ⇒ 即"HB 视觉序"）；修法① 把它反回**逻辑序** ✓
⇒ 与上游契约（`SimpleTextLine` 交**逻辑序** run + 宿主 `InvertAxes` 反镜像）**一致** ✓ **建议不回滚**（回滚会把词序重新弄反）。

### 10.4 位置缺陷的归属 + 候选坐标（给主控，本轮未动手）
- **不可能是 shim**：`pw−W ≥ 0` 恒成立（10.1(b) 60/60）⇒ 镜像不产生左移；`Draw` 与上游 `SimpleTextLine.cs:482-505`+`TextFormatterImp.cs:565-595` 逐字段同式。
- **不是 `CalcContentOffset`**（`TextBlock.cs:3091-3116`，Left ⇒ X=0）。
- **不是段落宽本身**（`pw ≈ W ≈ 65.3`，10.2）。
⇒ 落在**宿主的绘制原点/视觉层**。**候选检查点**：
1. `MS/Internal/Text/Line.cs:92-117`：`Arrange`（上游为空实现）/ `Render` 的 `origin = (lineOffset.X + delta, lineOffset.Y)`——实测 `delta = 0`、`hostOrigin = (0,0)` ⇒ 位移**不在这一层之内**，而在"哪个 DC/视觉把这一行摆到哪儿"。
2. `TextBlock.cs:1395-1420 / 1500-1547 / 1657-1690`：`wrappingWidth` / `contentOffset` 的使用处（`contentOffset.X` 已排除为 0 ⇒ 剩下的是**视觉摆放**）。
3. **RTL 子元素的 arrange / 视觉镜像**：`src/**`、`build/*.Linux/**` 里我 grep **没有**显式 RTL 镜像代码 ⇒ 更可能是 **arrange 的镜像分支**（或 MIL 的视觉变换）把 RTL 子元素摆到了 `x ≈ −22.6`（LTR 兄弟在同一父容器里是 `x ≈ 21`）。
**一次读数判死（给 T3，1 行）**：`ReportBox` 里同时报
`LayoutInformation.GetLayoutSlot(fe)`（布局槽，父空间）与 `TransformToAncestor(win).Transform(new Point(0,0))` / `…new Point(fe.ActualWidth,0)`：
- **槽**说 ≈21（与 LTR 对照行同）而墨迹在 −22.6 ⇒ 位移在**绘制/视觉层**；
- **槽**本身就是 ≈−22.6 ⇒ 位移在 **arrange**。

### 10.5 T3 的四条新验收判据（写死，替换被证伪的部分）
**判据 0（口径前置，必须先做）**
- 0.1 RTL 行的 `WFP_BOXID` 报的是**镜像角点**（实测 x = 21 + ActualWidth：86/95/117/89 = 21+65.3 / 21+73.8 / 21+96.4 / 21+68.1），**不能当左边界用**；参考基准改用**同父容器、同对齐的同串 LTR 对照行**（`he_same_string_LTR`），并**加报** `TransformToAncestor(win).Transform(new Point(fe.ActualWidth, 0))` 作交叉核对（两点之差应 = ActualWidth）。
- 0.2 框与像素的 **y** 有 ≈ +10…12 px 的固定偏差（**LTR 行也同样**）⇒ 判据只用 **x 的相对量**与**同一父容器内两行之间**的差。
- 0.3 **噪声底**：同一构建**重复采样 2 趟**，把两趟包络差当仪器噪声底；下列阈值不得小于它。
**判据 1（位置与宽度 —— 修法① 之后必须绿）**
`he_pure_RTL`（RTL）与 `he_same_string_LTR`（**同串** LTR）应给出**相同包络**：**右端差 |Δright| ≤ 2 px**、**宽度差 |Δw| ≤ 3 px**、**墨迹总量比 ∈ [0.9, 1.1]**。
依据：同串同字体 ⇒ 两者**墨迹包络必须相同**（RTL 只是把内容沿行内镜像，总 advance 不变）；用**右端**是因为左端当前被容器裁掉。
现状（pc=6dfacf82）：RTL `[13,42]` vs LTR `[22,88]` ⇒ **Δright = −46 px ✗**。
**判据 2（顺序/镜像 —— 判据 1 绿之后才可判）**
同串两行的**列轮廓**：`profile(RTL) ≈ reverse(profile(LTR))`（逐列平均 |Δ| ≤ 1.0，墨迹总量比 ∈ [0.9,1.1]），
**同时** `profile(RTL) ≈ profile(LTR)`（正序）必须**不成立**（若成立 ⇒ 没镜像或镜像了两次）。
适用前提：希伯来这类 **1:1 字形、无上下文形态**的串；**被裁 34 px 的状态下不可判**。
**判据 3（不得回退 LTR/CJK）**
整帧所有非 RTL 文本行：包络与墨迹总量与基线**逐行相同**（容差 = 判据 0.3 的噪声底；方向 ±1 px / ±2%）。
**判据 4（契约 —— 离线装置机读，不需要应用）**
RTL run：`ClusterMap` 计数 == 字符数、`[0] == 0`、非降、值 < GlyphCount（现状 **9/9** ✓）；
且**数组顺序 = 逻辑序**，用**数字锚**证明：串内放 `123` ⇒ 必须读到 `[20,21,22]`（修法① 前是 `[22,21,20]`，实测）。
**登记（不在射程，不作验收项）**：`he_with_digits_RTL` / `ar_with_punct_digits_RTL` 的**内嵌数字/标点呈现方向** ⇒ 需**段落级 UBA + 逐 bidi-run 切段**（§8.7 射程声明）；现状：修法① 后**词序正确、内嵌数字会显示成 "321"**（修法① 前相反，因为整段一个 HB buffer、没有 bidi 分段；上游 Windows 是逐 bidi-run 交，嵌套 run 交视觉序 + `BidiLevel>0`）。

### 10.6 回滚与否
- **建议：不回滚。** 依据 = 10.3 的顺序锚 + 上游契约 + §9.3 的 LTR/CJK 逐字节不变 + 判据 4（ClusterMap 9/9）。
- **顺序问题最终由判据 2 判定**（同串 RTL vs LTR 列轮廓 = 反序相等 ⇒ 恰好一次镜像 ✓）；它必须在**判据 1 先绿**之后做——现在 34 px 被裁，判不了。
- **唯一会让我改主意的情况**：① 新字段在应用里打出 `pw−W` **明显为负**（或 `pw ≈ 0`）⇒ 说明我这边的基准/守卫有问题；② 判据 1 绿了之后判据 2 判出"两次镜像"⇒ 那时该摘的是**宿主的那一次**，而不是回滚修法①。

---

## 11 "shim 是否双重纠正"的判定（2026-09-13，**本轮未改 shim**：sha 仍 `13992b58…`）

### 11.0 先自我订正一处
§10.2 我按 `CalcWrappingWidth` 的 Display 分支估 `pw−W = +0.04…+0.55`；**T3 实测 `pw == W` 精确成立**（纯 RTL `pw=65.2559 W=65.2559 pw-W=0.0000`；ar `73.8486/73.8486`；同串 LTR 也是 `0.0000`）。
⇒ 量级估错（应是 Ideal 模式/或端口把精确行宽传下来），但**判别表的落点没变**（`pw ≈ W` ⇒ 镜像就地）。**以 T3 的实测为准**。

### 11.1 问题 1：修法① 之后 shim 在 RTL 行上还推不推反演矩阵？——**推，且与上游逐字段同式**
`build/shims/PresentationCore.HbTextLine.cs:2424-2439`（逐字）：
```csharp
MatrixTransform anti = null;
if (inversion != InvertAxes.None)
{
    bool needX = (inversion & InvertAxes.Horizontal) != 0;
    if (needX && !(_paragraphWidth > 0))
    {
        HbTextLineScaffold.NoteInvertedNoWidth(inversion);      // 降级：段落宽未知 ⇒ 不推
    }
    else
    {
        anti = BuildAntiInversion(inversion, _paragraphWidth, _height);
        if (anti != null) HbTextLineScaffold.NoteInvertedLine(inversion);
    }
    if (anti != null) drawingContext.PushTransform(anti);
}
```
`BuildAntiInversion`（`:2468-2474`）：`Horizontal ⇒ m11 = −1, offsetX = paragraphWidth`（与 `TextFormatterImp.cs:582-586` 同式；DIRECT 模式下还有逐字段比对 → `antiMatrixMismatch`）。
**应用里的实际条件**：T3 实测 `inv=1`（`:2461` 之前的站点 B 打出）且 `pw=65.2559 > 0` ⇒ **`needX` 走 else 分支 ⇒ 必推** `Matrix(−1, 0, 0, 1, 65.2559, 0)` ✓
⇒ `invertedNoWidth` **不会**命中（那是 `pw ≤ 0` 的降级路径）；`antiMatrixMismatch` 也不会（同参同式）——**你的怀疑"到期条件不再命中"这一半是对的，但命中的结论是"照推"**。

### 11.2 问题 2：它与宿主镜像合起来把 run 映射到哪 —— **关键：`pw == W` 时它是"区间自映射"，位置中性**
- shim 的矩阵 `M: x ↦ pw − x` 把 run 的区间 `[0, W]` 映射到 `[pw − W, pw]`；**`pw == W` 精确成立 ⇒ `[0, W]` 映射到 `[0, W]` 自己**。
- 用**探针实测的墨迹盒**代入（修法① 后 `inkBox=(−0.398,−11.206)-(64.984,2.299)`）：`[−0.398, 64.984] ↦ [0.272, 65.654]`，**宽 65.382 → 65.382（±0.001）**（与 §9.3 的 A/B 数字一致）。
⇒ **shim 这次镜像只翻顺序、不动位置** ⇒ **它不可能是"墨迹落在视觉框外 + 宽度只剩 46%"的原因**（去掉它，区间一模一样）。
- 宿主候选（用 T3 实测：`TransformToAncestor` 报 `t0=86.3 → t1=21.0`，即 RTL 行视觉框 `[21.0, 86.3]`，跨度 65.3）：

| 宿主那一次是什么 | 预测墨迹区间 | 与实测（可见 `[13,42]`，由右端反推"画出来的区间"=`[42−W, 42]`=`[−23.26, 42]`） |
|---|---|---|
| 上游口径 `GetFlowDirectionTransform`＝`Matrix(−1,0,0,1,RenderSize.Width,0)`（`FrameworkElement.cs:3940-3948`）⇒ `V(y)=86.3−y` | `[20.65, 86.03]` | **对不上（差 44.3 px）** |
| 渲染实测等效 `R(y)=42−y`（镜像点 = 元素**左边缘** 21） | `[−23.65, 41.73]` | **对得上（≤0.4 px）** |
| 纯平移 `T(y)=y−23.26` | `[−22.99, 42.39]` | **对得上（≤0.4 px）** |

⇒ **结论**：`TransformToAncestor` 报的那个镜像（镜在元素**右边缘**/框中心，能把框映射到自己）**与渲染实际用的变换不是同一个**——
渲染实际把内容摆到了元素左边缘之外（等效"镜在元素左边缘"或"整体左移 ≈44.3 px"）。**这是宿主侧"报告口径与渲染口径不一致"**，不是 shim 的双重纠正。
（另外两条已排除：`CalcContentOffset` 在 `TextAlignment.Left` 下 X≡0（`TextBlock.cs:3091-3116`）；`GetLayoutSlot` 被拉伸到整面板 `0.0…546.5`，无区分力。）

### 11.3 问题 3：最小修法 —— **shim 侧没有能修好判据 1 的杠杆**（有证明），杠杆在宿主
**(a) 你提的"`inv=1` 时不再推 shim 反演"：判据 1 不变。**
证明（§11.2 第一条）：`pw == W` ⇒ 该矩阵是**区间自映射**的（`[0,W]→[0,W]`，实测墨迹盒宽度 65.382→65.382）⇒ 推与不推，**画出来的区间完全相同**（`[−23.26, 42]`），只有**屏上顺序**会翻回去。
⇒ 预期读数：`Δright` 仍 ≈ **−46**、`Δw` ≈ **−37**、墨迹比仍 ≈ **0.46** ⇒ **判据 1 依然红**（所以它**不是**修法① 造成的，也不是修它的办法）。
**(b) 宿主侧最小改动（给主控，坐标齐全）**：让 RTL 元素的**渲染**用与 `TransformToAncestor` 一致的那次镜像：
- 上游原文：`FrameworkElement.cs:3940-3948` `GetFlowDirectionTransform()` ⇒ `new MatrixTransform(-1.0, 0.0, 0.0, 1.0, **RenderSize.Width**, 0.0)`；
  判据来源 `:3950-3984` `ShouldApplyMirrorTransform` + `:4031-4035` `ApplyMirrorTransform`（父/子流向不同 ⇒ 建镜像）。
- 现状（由读数反推）：渲染路径用的偏移**不是** `RenderSize.Width`（等效"镜在元素左边缘"或整体左移 ≈44.3 px），而 `TransformToAncestor` 用的是上游口径 ⇒ 两者**必须统一**。
- **预期读数（判据 1）**：RTL 行的墨迹会落回它自己的视觉框 ⇒ 与同串 LTR 行**同一个墨迹盒**（因为 `pw==W` 时 shim 的镜像是就地翻转，位置由元素摆放决定）⇒ **Δright ≈ 0（≤2 ✓）、Δw ≈ 0（≤3 ✓）、墨迹比 ≈ 1.0（∈[0.9,1.1] ✓）**。
- **然后**判据 2 才可判（顺序）：若渲染与 `TransformToAncestor` 统一后**两次镜像真的并存**，则屏上 = 数组序 = 逻辑序 ⇒ 判据 2 会显示"`profile(RTL) ≈ profile(LTR)`（正序）"（= 词序反）⇒ **那时该摘的是宿主那一次元素镜像**（`ShouldApplyMirrorTransform` 对这类文本元素返回 true 这一条），**而不是回滚修法①**（回滚只会把词序从"反"改成"再反一次"，治不了镜像重复）。
**(c) 想做"应用里实测推入矩阵"的话**（可选、1 行、只读）：站点 B 可再打 `mx=`(m11,offsetX) 与 `mapX=`(run 区间经该矩阵后的区间)——**本轮我没加**（分析的结论已不依赖它，且省你一次 PC 重建）；要就说一声。

### 11.4 问题 4：不许回退 LTR/CJK —— 已有机器证明（本轮复用，未重跑）
- **逐串探针 A/B**（同一探针源，只换 shim 源）：`Hello world` 与 `中文混排 test` 的 `glyphIds / clusterMap / inkBox / Width / Extent` **逐字节相同**（§9.3 表最后两行）。
- **同 harness、同 PC、只换 shim 源**：`diff` **为空**（`通过 20 / 失败 2`，T2 1286/1298、T2b 972/972·213/213、T2d 1298/1298 + Extent 1260/1298、Tab 0 例）——见 §9.8(A)。
- 本轮只加读数那一版也做过同样的 A/B：`diff` 为空（§10.0）。
⇒ 无论修法① 还是那一格读数，**LTR/CJK 侧逐字节不变**。

### 11.5 一个便宜的"顺序"判别（判据 2 的前置替代，供 T3 选用）
现在 34 px 被裁，列轮廓判不动顺序（§9.4 实测：正序 1.28 / 反序 1.59，分不干净）。**换成"一宽一窄两个词"的串**（例如首词用宽字母 `מממ`、次词用窄字母 `ווו`）：
墨迹总量在整流里是**不对称**的 ⇒ 只要看 RTL 行**可见条**的墨迹总量更接近"宽词侧"还是"窄词侧"，就能判可见条落在串的哪一端、以及是否被翻转（T3 的既有仪器即可，不需要新工具）。

---

## 12 绘制时几何读数（站点 E）：**run 的行内区间正常 ⇒ 压缩/左移不在 shim 内**（2026-09-13）

### 12.0 交付 sha + "只加读数"的两次逐字节自证
- **新 shim sha = `e019db5646217ba0530fbeeb155df1a1e480106ec7544a24a8f9f5ce327bbf03`**（3897 行）；中间版 `cd5a90b2…`（3894）、加读数前 `13992b58…`（3832）。
- 自证①：从新件逐字回退"判据格改成逐 run 累加"+`xEnd` ⇒ `sha256sum` **命中 `cd5a90b28157d4b5a3eaf6839cd95cf8a0db80b3715d2123af9bc34129cda14d`**（重建件 `/tmp/t1d-recon-cd5a90b2.cs`）。
- 自证②：继续回退整段 `SiteE`/`s_budgetE`/`DrawCore` 参数 ⇒ **命中 `13992b58905d00e0aea8736c14a94836515f9d4355e2db75dc12d1af00a89e91`**（`/tmp/t1d-recon-13992b58.cs`）⇒ **全部改动都在插桩里，修法① 一行未动**。
- 三形态编译（`DirectBranchCheck` / `HbTextLineParity` / `CoverageProbe`）各 **0 错**。
- **A/B（recon `cd5a90b2` vs 新件）**：`diff` 只有**一行**，且是带时间戳的输出文件名
  （`…/gen/tline-ledger-lines-20260913-2120.txt` vs `…-2121.txt`）；两边 **`通过 20 / 失败 2`** ⇒ **行为不变**。

### 12.1 站点 E 是什么（`file:line`）
- 方法：`build/shims/PresentationCore.HbTextLine.cs:2023`（`internal static void SiteE(...)`，独立预算 `s_budgetE`，缺省关）。
- 调用点：`Draw` 把**推入的反演矩阵**作为实参交给 `DrawCore`（`:2513`）；`DrawCore`（`:2574`）在**空行路径**（`:2580`）与**正常路径**（`:2591`）各打一行（与站点 B/D 并列，互不共享预算）。
- 字段：`hostOrigin=(x,y)`｜`pw=`｜`W=`｜`H=`｜`inv=`｜`anti=(M11,M22,offX,offY)` 或 `None(未推)`｜`ctm=读不到(契约无公开CTM)`｜`runs=`｜每 run `[rK bo=(行内 x,y) n=字形数 adv=Σadvance x=[a,b] absX=[a,b]]`｜判据格 `Σadv(all)-W`、`xEnd(all)-W`。
- **CTM 为什么"读不到"**：`DrawingContext` 是**抽象类**且只有 `public abstract void PushTransform(Transform)`（`upstream/…/Media/Generated/DrawingContext.cs:374`），**契约上没有任何 CTM 读出口** —— 这不是"没做"，是取不到；能取到的绝对值 = **宿主 `origin` + 行内区间**（就是 `absX` 那一格）。
- 惰性/只读：只读 `GlyphRun.BaselineOrigin` / `AdvanceWidths` / `GlyphIndices.Count` / 本行字段，不碰面令牌、不构造对象、不改调用次数。

### 12.2 判据命中：**行内区间正常**（逐字读数，自起 Xvfb `:97`，按 PID 839777 收）
| 场景 | `pw` | `W` | `anti` | runs 区间（行内） | 判据格 |
|---|---|---|---|---|---|
| 纯希伯来 `שלום עולם`，`--width 65.2559`，`inv=1` | 65.2559 | 65.2559 | `(-1.0000,1.0000,offX=65.2559,offY=0.0000)` | `r0 n=9 adv=65.2559 x=[0.000,65.256] absX=[0.000,65.256]` | **`Σadv(all)-W=0.0000 xEnd(all)-W=0.0000`** |
| 同串，`--width 200`，`inv=1` | **200.0000** | 65.2559 | `(-1.0000,1.0000,offX=200.0000,…)` | `r0 n=9 adv=65.2559 x=[0.000,65.256]` | `0.0000 / 0.0000` |
| `中文混排 test`（**两段**），`--width 200`，`inv=1` | 200.0000 | 87.3359 | 同上（offX=200） | `r0 n=4 adv=56.0000 x=[0.000,56.000]`；`r1 n=5 adv=31.3359 x=[56.000,87.336]` | `0.0000 / 0.0000` |
| （对照）`pw=0` 的降级行 | 0.0000 | 9.8047 | **`None(未推)`** | `r0 n=1 adv=9.8047 x=[0.000,9.805]` | `0.0000 / 0.0000` |

⇒ **`Σadvance(all) == W` 且 `xEnd(all) == W`（差 0.0000）** ⇒ **run 的行内区间完全正常**：
单 run 时它正好铺满 `[0, W]`；两段时首尾相接铺满（`56.0000 + 31.3359 = 87.3359 = W`）⇒ **横向压缩/左移不在 shim 内** ⇒ 下一个站是**宿主/MIL**：
`GlyphRun.BaselineOrigin` 的绝对值与渲染器入口的 `originDIP`/CTM（我这一格给出的 `absX=[0.000,65.256]` 就是 shim 交出去的绝对区间；像素上却是 `[13,42]` 可见 / 反推画出区间 `[−23.26,42]` ⇒ 差异只能产生在 shim 之外）。
- 旁证两条：`pw=0` 时 `anti=None(未推)`（§11.1 的诚实降级路径确实可见）；`--width 200` 时 `offX` 跟着 `pw` 走（200）而 run 区间**不变**（`[0, 65.256]`）⇒ 与 §11.2 的"`pw==W` 时区间自映射"一致。

### 12.3 "压缩 vs 左移+裁剪"判死：**左移 + 裁剪**（四条互证，用应用那两帧的像素）
1. **密度**（你的判别式）：RTL 可见条 `119 px / 30 列 = 3.97/列`，LTR 全行 `260 / 67 = 3.88/列` ⇒ **密度不变**；若整串被横向压到 46%，同样的 260 px 墨迹要挤进 30 列 ⇒ `8.67/列`（**2.2×**）⇒ **压缩否证**。
2. **簇数**：LTR 全串 66 列里有 **8 个字母簇**（= 串的 8 个字母；空格无墨迹，实测 ~7–8 簇）；RTL 可见条只有 **5 簇** ⇒ 它是**串的一段**，不是"整串挤进来"。
3. **最小簇间距（判缩放最直接的量）**：RTL 条最小簇间距 **4.0 px** ≈ 最窄字母 `ו` 的 advance **3.814 px**（探针实测 `g1324: aw=3.814`）⇒ 比例 **≈1.00**；若 0.46× 压缩 ⇒ 应为 **1.75 px** ⇒ **否证**。
4. **切片匹配**：RTL 条 ⊂ LTR 全串轮廓的**连续切片**（最佳偏移 36）逐列平均 |Δ| = **1.28**，优于"把 LTR 轮廓按 0.46 压缩到同宽"的 **1.51** ⇒ 更像裁剪。
   **残留（如实登记）**：同字母切片的 ink 比 = 0.69、最大列差 8；列轮廓对希伯来（两个字共享 ל/ו/ם）区分度本来就低 ⇒ 主判据是 1–3 条，第 4 条只作旁证。

### 12.4 下一步（给主控）
- shim 侧**已排除**（§12.2 判据命中 + §9.3"修法① 不改包络宽度"）；**镜像线也已按你的读数收口**（`OffsetX == 当时的 RenderSize.Width`，与报告口径一致）。
- 建议下一格读数落在**宿主/MIL**（不在我车道）：渲染器入口处的 `originDIP` / CTM，与 `GlyphRun.BaselineOrigin`（或 `MilGlyphRun.Origin`）的实测值 ⇒ 判"是谁把 `[0.000,65.256]` 这段搬到 `[−23.26,42]`"。
- 我这边的插桩已就位：**应用里跑一趟 `WPF_LINUX_HBLINE_TRACE=1`**，`HBLINE E#` 那一行会直接把"宿主 origin / pw / W / 推入矩阵 / 每 run 行内与绝对区间 / 判据差"一次给全。

---

## 13 修法②：**输出逻辑序的 RTL 行不再推反演矩阵**（2026-09-13，主控授权）

### 13.0 交付 sha
**`build/shims/PresentationCore.HbTextLine.cs` = `5a04875ae87a294d04fd8db2f14960d62828f5dbed23b7e4151f0e60fa645d33`**（3897 行；上一版 `e019db56…`）
- **只改了 17 行**：从新件删掉那 17 行 ⇒ `sha256sum` **逐字节命中 `e019db5646217ba0530fbeeb155df1a1e480106ec7544a24a8f9f5ce327bbf03`**（重建件 `/tmp/t1d-recon-e019db56.cs`）⇒ 修法① 的数组反转、`InvertClusters`、站点 A–E、其它一切**一行未动**。

### 13.1 为什么（镜像计数）——并且**订正**我 §8/§9 的一处说法
屏上顺序 = `reverse^(推入的反演次数 + 1)(数组序)`（那个"1" = 宿主对 RTL 元素的**一次**元素镜像
`FrameworkElement.GetFlowDirectionTransform()` = `MatrixTransform(-1,0,0,1,RenderSize.Width,0)`，`FrameworkElement.cs:3940-3948`；桥侧实测 `[VISTRANS] M11=-1 DX=65.2559 镜像=是`）：

| 时点 | 数组序 | 推入次数 | 屏上 | 判定 |
|---|---|---|---|---|
| 修法① **之前** | HB **视觉序** | 1（我们）+ 1（宿主）= 2 | 视觉序 | ✓ 正确 —— **反演是正确的补偿** |
| 修法① **之后**（改前） | **逻辑序** | 2 | **逻辑序** | ✗ 反了；且桥侧 `CTM` 的 m11 被抵消成 `+1.0417`、`dx=−24.594` ⇒ run 出框 |
| **修法②（本次）** | 逻辑序 | **0 + 1** = 1 | **视觉序** | ✓ 正确，且落在框内 |

⇒ 我 §8/§9 里"上游交逻辑序 run"的说法**不准确**：上游（LS）交的是**视觉序**，所以它才需要那次反演去抵消宿主镜像。
修法① 把我们的输出改成逻辑序之后，**宿主那次镜像正是产出视觉序所必需的那一次** ⇒ 我们再推反演就是第二次反转。

### 13.2 改了什么（逐字，`:2495-2531`）
```csharp
anti = BuildAntiInversion(inversion, _paragraphWidth, _height);
if (anti != null) HbTextLineScaffold.NoteInvertedLine(inversion);
// ⭐ 修法②（T1d §13）：**我们输出逻辑序 RTL ⇒ 不再抵消宿主的镜像**。
//   `_shaped.Rtl` 的取值恰好就是这条判据：单段 RTL ⇒ true（我们输出逻辑序 ⇒ 摘掉 X 分量）；
//   LTR 内容 ⇒ false；多段混合 ⇒ 合并处给 false（保守：维持改前行为，混合方向本就不在射程 §8.7）。
if (anti != null && needX && _shaped != null && _shaped.Rtl)
{
    Matrix m = anti.Matrix;
    if (m.M22 == 1 && m.OffsetY == 0) anti = null;                    // 只剩水平分量 ⇒ 干脆不推
    else anti = new MatrixTransform(1, 0, 0, m.M22, 0, m.OffsetY);    // 保留垂直分量
}
```
**为什么"只摘 Horizontal、不整体跳过"**（这是我按判断做的选择，理由 = 上面的镜像计数）：
RTL **段落**里放 **LTR 内容**（例如拉丁文件名）时，数组序对 LTR 就是视觉序，**必须**保留那次反演去抵消元素镜像，
否则拉丁字母会被镜像成反字。所以判据是**内容方向**（`_shaped.Rtl`），不是"有没有 `InvertAxes`"。
多段混合（`chunks.Count > 1` ⇒ 合并出 `Rtl = false`）保守保持改前行为——那本就属于 §8.7 声明的射程外（需段落级 UBA）。
**诊断语义保持不变**：`invertedNoWidth` 的命中条件仍是 `needX && !(_paragraphWidth > 0)`（诚实降级，未动）；
`antiMatrixMismatch` 仍拿**未摘前**的矩阵与上游 `TextFormatterImp.CreateAntiInversionTransform` 逐字段比对（命中条件未动）；
`invertedLines` 现在表示"收到 `InvertAxes≠None` 且本行已按内容方向处理"（RTL ⇒ 不推；其它 ⇒ 推）。
**`InvertClusters` 一行未改**。

### 13.3 离线读数（自起 Xvfb `:97`，按 PID 907146 收）
**(a) run 数据（`--inkdiag`）逐字节不变** —— 五条串（`שלום עולם` / `مرحبا بالعالم` / `שלום 123 עולם` / `Hello world` / `中文混排 test`）
在"上一版 vs 新件"下 `diff` **为空（`INKDIAG_DIFF_RC=0`）** ⇒ 修法② **只动 Draw 的变换，不碰整形/run 数据**。
**(b) Draw 变换分支（站点 E 的 `anti=` 那一格 + 探针 P8/P10）**
```
RTL 内容  [שלום עולם]  inv=1  ⇒ HBLINE E#0 … pw=65.2559 W=65.2559 … inv=1 **anti=None(未推)** … [r0 n=9 adv=65.2559 x=[0.000,65.256] absX=[0.000,65.256]] Σadv(all)-W=0.0000
        PASS P7（不抛）｜ PASS P8 **RTL 内容**：Horizontal 时**不推**水平反演 ｜ PASS P10（Both 只留 M22=−1）
非 RTL 内容 [Hello world] inv=1 ⇒ HBLINE E#0 … pw=200.0000 W=78.4834 … inv=1 **anti=(-1.0000,1.0000,offX=200.0000,offY=0.0000)** … [r0 n=11 adv=78.4834 x=[0.000,78.483]]
        PASS P7 ｜ PASS P8 **非 RTL 内容**：**仍推**镜像矩阵（M11=−1、OffsetX=段落宽） ｜ PASS P10（Both 两者都有）
```
（探针的 P8/P10 判据已按新契约改成分支式 —— 否则 RTL 那条会假红；这是**我装置的断言更新**，不是被测行为。）

### 13.4 不许回退的既有读数（新 shim `5a04875a` 下重跑，逐项相同）
- **三形态编译**：`DirectBranchCheck` / `HbTextLineParity` / `CoverageProbe` 各 **0 错**。
- **`run.sh tline` 六项**（新 shim）：**通过 20 / 失败 2**；
  `T1.73` **73/73** ✅｜`T2` 记账 **1286/1298**（①286/286 ②68/68 ③984/988 宽度超差 47）❌已知｜
  `T2b` 行级 **972/972**、用例级 **213/213** ✅｜`T2d` Height/Baseline **1298/1298**、Extent **1260/1298** ✅｜
  `T3` 判定 **1298/1298** 明细 218/236 ❌已知｜`Tab` 不一致 **0 例** ✅ ⇒ **与上一版逐项相同**；
  计数器行（`HB_TEXTLINE enabled=… antiMatrixMismatch=…`）与上一版**逐字相同**。

### 13.5 预期应用级读数（给 T3 复measure；含"判据 1 三条全绿"的算式）
以桥侧 `累积world`（含镜像）与我的实测墨迹盒（`[−0.398, 64.984]` 行内、`W=65.2559`）推算：
- **`CTM` 应 ≈ 同行 `累积world`**：`m11≈−1.04`、`dx≈89.8/98.8/122.3/92.8`（不再出现 `+1.0417 / −24.594` 那一族）；
- `he_pure_RTL` 的墨迹应落在 **`[≈22.1, ≈90.2]`（device，1.0417 缩放）**，而**同串 LTR 对照**是 `[≈21.5, ≈89.6]`
  ⇒ **`|Δright| ≈ 0.6 ≤ 2` ✓、`|Δw| ≈ 0.1 ≤ 3` ✓、墨迹比 ≈ 1.0 ∈[0.9,1.1] ✓** ⇒ **判据 1 三条全绿**；
- 顺序上现在**只有宿主的 1 次镜像** ⇒ 屏上 = 视觉序 ⇒ **判据 2**（`profile(RTL) ≈ reverse(profile(LTR))`）应成立。
- **登记（射程外）**：单 run 的 RTL 串里**内嵌数字/标点**（`שלום 123 עולם`、`مرحبا، 123`）现在词序正确、但**内嵌数字会显示成 "321"**
  —— 这是"整段一个 HB buffer、没有 bidi 分段"的既有欠账（§8.7 已声明），真解是段落级 UBA；不作为修法② 的验收项。

### 13.6 回滚
删掉 §13.2 那 17 行（或把条件改成 `false`）⇒ 逐字节回到 `e019db5646217ba0530fbeeb155df1a1e480106ec7544a24a8f9f5ce327bbf03`。

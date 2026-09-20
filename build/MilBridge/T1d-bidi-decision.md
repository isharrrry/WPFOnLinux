# T1d 决策报告：要不要为**真双向文本/RTL 视觉序**开专项？（2026-09-13）

> 口径：本报告**没跑应用**、**没改 `src/**`**、**没改 shim**（`build/shims/PresentationCore.HbTextLine.cs` 仍是 `5a04875ae87a294d04fd8db2f14960d62828f5dbed23b7e4151f0e60fa645d33`）。
> 所有读数来自**离线装置**：`build/MilBridge/tests/CoverageProbe`（内嵌当前 shim）+ **ICU 70 `ubidi` 参考**（`ctypes` 直调 `libicuuc.so.70`，与工程链接的是同一个库）+ 自起 Xvfb `:96`（按 PID 收；`:97` 是 T3 的，我没碰）。
> 混合方向此前登记为"需 UBA、超范围"（`§8.7`）；纯 RTL 已由**修法②**（§13）修好。

---

## 1 最小失败例（可复算）

**装置**：`--scenario single --em 14 --width 200 --inkdiag [--invert]`；字符方向由**站点 E 的 `anti=`** 读出
（`anti=None(未推)` ⇒ 我方判为 RTL 内容；否则 LTR）；产出的**数组序**用**数字/拉丁/希伯来锚**解码
（锚表实测：`a=68 b=69 c=70 1=20 2=21 3=22 ' '=3 .=17 ש=1344 ל=1331 ו=1324 ם=1332 ע=1337 ן=1334`）；
**实画序** = 数组序（LTR 内容）/ 数组**反序**（RTL 内容，因修法② 不推反演、宿主元素镜像翻一次 —— 桥侧读数 `[VISTRANS] M11=-1 DX=65.2559` 佐证）；
**应然序** = ICU `ubidi`（`ubidi_setPara` + `ubidi_getVisualIndex`）给出的**左→右字符序列**。

| 输入 | 段落向 | 内容向(HB) | runs | 我方数组 | **实画(左→右)** | **应然(UBA)** | 判 |
|---|---|---|---|---|---|---|---|
| `שלום עולם` | RTL | RTL | 1 | 逻辑序 | `םלוע םולש` | `םלוע םולש` | ✓（纯 RTL，修法② 的成果） |
| `abc 123` | LTR | LTR | 1 | 逻辑序 | `abc 123` | `abc 123` | ✓（纯 LTR） |
| `123 abc` | LTR | LTR | 1 | 逻辑序 | `123 abc` | `123 abc` | ✓ |
| `שלום.` | RTL | RTL | 1 | 逻辑序 | `.םולש` | `.םולש` | ✓ **碰巧**（见下） |
| **`שלום 123`** | RTL | RTL | 1 | 逻辑序 | **`321 םולש`** | `123 םולש` | ✗ **数字反序** |
| `שלום 123 עולם` | RTL | RTL | 1 | 逻辑序 | `םלוע 321 םולש` | `םלוע 123 םולש` | ✗ **词对、数字反**（最危险的一类） |
| `שלום abc` | RTL | RTL | 1 | 逻辑序 | `cba םולש` | `abc םולש` | ✗ 拉丁段反序 |
| **`abc שלום`** | LTR | LTR | 1 | 逻辑序 | **`abc שלום`** | `abc םולש` | ✗ 希伯来字**逐个反**（词读反） |
| `abc שלום` | RTL | LTR | 1 | 逻辑序 | `abc שלום` | `םולש abc` | ✗ 段序与词形都错 |
| `abc שלום 123` | LTR | LTR | 1 | 逻辑序 | `abc שלום 123` | `abc 123 םולש` | ✗ |

**结构性读数（全部 10 例都一样）**：`runs = 1`、`BidiLevel = 0`、`ClusterMap = 0..N-1`（恒等）⇒
**段内的双向结构从来没有离开 shim 之前就被压成"一个方向 + 一个 run"**，宿主拿不到任何可供重排的信息。

### "碰巧对"与反例边界（这一节是给人做决策用的）
- **真对**：整串只有一个方向（纯 RTL / 纯 LTR，含纯数字）。这是修法② 之后应有的结果。
- **碰巧对**：`שלום.`（RTL + 中性标点）。整串同向后，HB 的"整体反序"恰好把句点送到行首（RTL 里正确）。
  ⇒ **中性/弱字符（空格、标点）不构成反例**，所以"我试了一句看着对"**不能**当证据。
- **反例边界**：只要串里同时出现 **RTL 文字 + LTR 强字符（拉丁字母、欧数字）**，实画序就与 UBA 不符 ——
  两条子类：① RTL 段落里的 LTR 段（数字/拉丁）被**整体反序**（`321`、`cba`）；
  ② LTR 段落（或 HB 猜成 LTR 的段）里的 RTL 文字**逐个反**（希伯来词读反）。
- **"对"是不是巧合**：对纯向串**不是**巧合（是单方向渲染的正确行为）；对含中性字符的串**是**巧合；
  对混合串**必然错**（因为"整体反序"= 把 LTR 段也当成 RTL 处理）。

---

## 2 UBA 该进哪一层

**上游给的公开信息只有"段落方向"**：
- `TextParagraphProperties.FlowDirection`（`upstream/…/textformatting/TextParagraphProperties.cs:25`）——**段落级**；
- `TextRunProperties` **没有**任何方向/bidi 成员（只有 `Typeface/FontRenderingEmSize/FontHintingEmSize/TextDecorations/ForegroundBrush/BackgroundBrush/CultureInfo/TextEffects/BaselineAlignment/TypographyProperties/NumberSubstitution/PixelsPerDip`，`upstream/…/textformatting/TextRunProperties.cs:26-111`）。
⇒ **逐字双向分析属于"TextLine 实现"的职责**（上游是 LS/`FullTextLine` 在做），不是调用方的。

**树内已有 UBA，但挂在 LS 那条路上**：`MS.Internal.TextFormatting.Bidi`（托管 UBA，`upstream/…/MS/internal/TextFormatting/Bidi.cs`）的入口 `Bidi.BidiAnalyzeInternal(...)` 被 `TextStore.cs:946-1033` 调用（LS 集成），**我们的 `HbTextLine` 从不调它**。

**我们 shim 在哪里丢的**（`build/shims/PresentationCore.HbTextLine.cs`）：
| 位置 | 事实 |
|---|---|
| `:214` `hb_buffer_guess_segment_properties(buf)` | **整段一个 HB buffer，方向猜一次**（按首个强字符的 script），此后不再细分 |
| `:215` `bool rtlDir = hb_buffer_get_direction(buf) == HB_DIRECTION_RTL;` | 整段只有**一个**方向；修法① 的反转也是**整段**做（`:263-274`） |
| `:2370` `face, 0, false, …`（`BuildGlyphRun` 第二实参 = `bidiLevel`） | 交给宿主的 run **`BidiLevel` 恒 0**（上游"逻辑序 run"约定） |
| run 切分 | 由 **`HbFontPlanner`（按字体覆盖）**切，不是按 bidi level ⇒ "run" ≠ "bidi run" |
| **`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:216-241`** | 拦截层 `TryFormatLine(textSource, cpFirst, paragraphWidth, pixelsPerDip, alwaysCollapsible, lineHeight)` → `FormatParagraph(text, fontPath, emSize, paragraphWidth, gt, ppd, props, alwaysCollapsible, false, lineHeight, out consumed)` —— **没有 `FlowDirection` 参数** ⇒ **shim 在排版时根本不知道段落方向**（它只在 `Draw` 时通过 `InvertAxes` 间接知道，而那时断行/整形早就做完了） |

**按现有架构（HarfBuzz + ICU + 托管 TextLine）的最小可行路径**（都在我车道内，除第 1 步 2 行）：
1. **把段落方向送进 shim**：拦截层多传一个 `FlowDirection`（`TextFormatterImp.Linux.cs` + `FormatParagraph`/`FormatLine` 签名；PC 车道 2 行）——UBA 必须有基准方向，否则只能像今天这样"猜"。
2. **用 ICU `ubidi` 算 levels**：`ubidi_setPara(text, len, paraLevel, …)` + `ubidi_getLevels`（`libicuuc.so.70` **已链接**，shim 里已有 ICU P/Invoke 用于断行 ⇒ 沿用同一模式；也可用树内 `Bidi.BidiAnalyzeInternal`，但它只在 DIRECT 形态可见，ICU 两种编译形态都能用）。
3. **按 level 切 bidi run**，每段用 `hb_buffer_set_direction` 显式给方向后整形（取代 `guess_segment_properties` 作为方向来源）。
4. **每段一个 `GlyphRun`**，按与宿主那次镜像**相容**的顺序摆放（§13 的契约：**我们要交的是"期望视觉序的镜像"**，这样宿主的 1 次镜像正好还原）；`BidiLevel` **保持 0**（理由见 §3 的风险项）。
5. 下游 API（`GetTextBounds` / `GetDistanceFromCharacterHit` / `GetCharacterHitFromDistance` / `GetIndexedGlyphRuns` / `GetTextRunSpans`）在"多 run、逻辑↔视觉不一致"之后的**序一致性**要一起改，否则 caret/命中会错位。

---

## 3 成本与风险

**涉及站点（核心）**：shim 内 4 处 —— 方向输入（`Shape` 的 `:214-215`）、run 切分（`HbFontPlanner`/`ShapeParagraph`）、每段整形方向、`BuildGlyphRun`+摆放（`:2370` 附近）；
再加**下游 5 个 API**（上表第 5 条）与站点 A–E 的读数扩展。**我车道外 2 行**：拦截层传 `FlowDirection`。

**对已冻判据的影响（这是决定性的）**：
- `tline` 六项语料里 RTL 用例是**纯 RTL**（`cases-cd2.json` 那 15 例）⇒ 只要**门控"仅当 levels 非单一才走新路"**，这些行**逐字节不变** ⇒ 六项/T2*/T3 基线**可证不动**（用现有 A/B：同一 harness、同一 PC、只换 shim 源 ⇒ `diff` 必须为空）。
- **`BidiLevel` 是个雷**：实测把 run 的 `BidiLevel` 设成 1 会让 `GlyphRun.ComputeInkBoundingBox` 走 RTL 分支、墨迹盒从 `(0.271,…)-(65.654,…)` 变成 `(−64.984,…)-(0.398,…)`
  ⇒ 直接动 `Extent`（`T2d` 的 `Extent 1260/1298` 是冻的）⇒ **新路径必须保持 `BidiLevel=0`**，级别信息只体现为 run 顺序（要真级别就得同时改 `Extent` 的口径，那是第二次冻结变更）。

**"做一半会不会更糟"：会，而且我们已经量到了那一类**。
`שלום 123 עולם` 现在画成 `םלוע 321 םולש` —— **词是对的、数字是反的**，肉眼极易判"通过"；
而今天**没有**混合支持时，这类错误是**成体系登记在册**的（§8.7 + 判据④登记）。半支持会把"已知的整类错"变成"零散、看起来对、测不出来"的错 ⇒ **比不做更糟**。

---

## 4 建议（做 / 不做 / 先做什么）+ 判据

**建议：不要现在开"全专项"；先做第 0 步（零风险、可判、可回退），用读数决定要不要继续。**
理由：① 纯 RTL（用户最常问的那一类）已经对了；② 混合方向的**真实占比未知**（见 §5 缺的读数）；
③ 核心做完还要拖上下游 5 个 API，成本 ≈ 2 个车道轮次，而收益面取决于 ②。

- **0a（读数量，half-day 级）**：在 shim 里用 ICU `ubidi` 算一遍 levels，**只加只读计数器/站点**（如 `mixedParagraphs=`、`maxLevel=`、`bidiRuns=`），默认关。用途：量"混合段在真实场景里到底有多少"。
- **0b（可行性验证，可回退）**：把混合路径做在**环境开关 + 门控**后面（`WPF_LINUX_TEXT_BIDI=1`，默认关；且**仅当 levels 非单一**才启用）⇒ 纯向串逐字节不变、六项零风险；用 §1 的 battery + T3 一次混合串读数即可判"值不值得转默认开"。
- **若 0a 显示真实场景里混合段极少 ⇒ 建议直接不做**，保留现有登记（登记已经把边界写清楚：纯向对、混合错、需 UBA）。

**判据（"做完"的定义，可直接拿去当验收）**
1. §1 那张表**10/10 全 ✓**，且**两种段落方向**都对；特别是 `שלום 123` / `שלום 123 עולם` 这类"半对"必须变全对；
2. **纯向串与今天逐字节相同**（`שלום עולם` / `abc 123` / `123 abc` 的 `inkBox/Width/Extent/clusterMap` 逐位不变）；
3. `tline` 六项 + `T2*` 基线：**开关关**时逐位不变；**开关开**时纯向串不变（同一 harness、同一 PC、只换 shim 源的 A/B `diff` 为空）；
4. 每个 run 的 `ClusterMap` 仍满足契约（count == 该段字符数、`[0]==0`、非降、值 < `GlyphCount`）；
5. `GetTextBounds(i,1)` 与 caret 两个 API 在混合串上与视觉序自洽（**需要新增读数**，见 §5）。

**判据（"没做完"的红旗）**：只在一种段落方向对；数字/标点仍反；靠改 `BidiLevel` 去凑顺序（会动 `Extent` 基线）；任何纯向串读数变化；`ClusterMap` 变成非单调（宿主会拒收，见 `GlyphRun.cs:368-395`）。

---

## 5 缺哪些读数、怎么取（给主控派单）

| # | 缺的读数 | 怎么取 | 谁 |
|---|---|---|---|
| 1 | **混合方向在真实样例里的占比** | T3 在探针样例里加一块（或复用 ⑩ 块）：放 `שלום 123`、`abc שלום` 两类串，取 `HBLINE A/E`（run 数、`pw/W`、`anti=`）+ 像素实画序（用 §1 的数字/拉丁锚法判"数字是否反序"） | T3（应用槽） |
| 2 | 段落方向在**排版阶段**确实拿不到 | 离线已由签名证明（`TextFormatterImp.Linux.cs:216-241` 无 `FlowDirection`）；若要应用级佐证，PC 车道在 `TryFormatLine` 加一行日志 | PC 车道（可选） |
| 3 | 混合串的**逐字 x 区间**真值 | Windows 真机对 `שלום 123` / `abc שלום` 逐字收 `GetTextBounds(i,1)`（配合我们的同串读数）⇒ 判据⑤的输入 | T1c/T3（真机侧） |
| 4 | 混合串上 caret/命中的现状 | 离线可先给"单 run 下必然不自洽"的论证；要真值需应用级 `--only=textbox-edit` 那趟 | T3 |

> 另：本报告**没有**用 `strings` 判"某串在不在产物里"——按主控的更正，这类判断必须**字节级计数**；
> 本报告也不需要该判据（全部读数来自装置输出与 ICU 直调）。

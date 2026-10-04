# U1 · 真机 oracle：**缺码点时 WPF 报什么 advance / 谁决定**（`D-F1` 用）+ `TextModifier` 方向嵌入（60 例）

> 主项：**段落字体缺该码点时，真机报出来的 advance 是什么、由谁决定**——回退到别的字体？用 `.notdef`？还是某个固定宽度？
> 便宜项：`HasDirectionalEmbedding = true` 的 `TextModifier`。
> **全部在远端真机完成**；本地只落盘 oracle 文件，未构建、未运行应用（`:97` 归 T3）。

## 1. 元组

| 项 | 值 |
|---|---|
| 机器 / 运行时 | `bilintu\pc`（Windows NT 10.0.22631.0）／ **.NET 10.0.7**，PresentationCore 10.0.0.0 |
| 测量 | `TextFormatter.Create().FormatLine(...)`；advance 取 `TextLine.GetTextBounds`；**实际用的字体/字形取公开 API `TextLine.GetIndexedGlyphRuns()`**（`GlyphRun.GlyphTypeface` / `GlyphIndices`）——**全程零反射** |
| 设置 | `TextAlignment=Left`、`TextWrapping=Wrap`、`LineHeight=0`、`Tabs=null`；emSize **24**、Dpi 96、段落宽 400（方向嵌入组另用 40/140） |
| 码点 | `U+4E0E 与`（现场例）、`U+6C49 汉`、`U+05D0 א`、`U+0627 ا`、`U+2192 →`、`U+E000`（BMP 私用）、`U+10FFFD`（16 平面私用，需代理对） |
| 字体设定 | ① 单字体 `Arial` ② 单字体 `Times New Roman` ③ **文件字体** `C:\u1-shaping\fonts\NotoSans-Regular.ttf`（工程自身处境）④ **字体族列表** `FontFamily("Arial, Segoe UI Symbol")` ⑤ **`Typeface(..., fallbackFontFamily: Microsoft YaHei)`** ⑥ **显式指定覆盖该码点的族**（运行时从候选表挑） |
| 样本数 | **60 cases，id 全唯一**，`DETERMINISM=MATCH` |

## 2. ⭐ 一句话答案

> **真机在段落字体缺该码点时，不用该字体的 `.notdef`，而是做「字体回退」——换成另一个覆盖该码点的已安装字体，并报那个字体自己的字形与 advance。**
> advance 是多少**取决于被换上的那个字形**：CJK 码点上换上的是**全宽字形 ⇒ 恰好 1.0 em（emSize 24 时 24.000000 DIP）**——**这才是现场例看到 "1 em" 的原因，不是"缺字固定宽度"**。
> **只有当回退也找不到覆盖字体时**才落到段落字体自己的 `.notdef`，此时 advance = **该字体 glyph 0 的 advance**（Arial `18.000000`、Times New Roman `18.666667`、Noto 文件字体 `14.400000` DIP）。
> 另外：**在 `FontFamily` 列表里或 `Typeface(..., fallbackFontFamily)` 里点名的字体会被优先采用**（见 `U+E000` 一行）。

23 个"指定字体缺该码点"的样本里：**14 个发生了回退**、**9 个落到 `.notdef`**，无一例外由"是否有可用覆盖字体"决定。

## 3. ⭐ 可复算的表（`码点 | 字体设定 | 该字体有/无 | advance | 与 1em 的关系 | 与 .notdef 的关系`）

以下 23 行即"指定字体缺该码点"的全部样本（完整 41 行在 `out/font-fallback-oracle.json` 的
`table_whatTheMainQuestionAskedFor`，含"有该码点"的 18 行对照）：

| 码点 | 字体设定 | 该字体有? | advance (DIP) | =1em? | =该字体 .notdef? | 实际用的字体 / 字形 | 回退? | 本机覆盖族数 |
|---|---|---|---|---|---|---|---|---|
| `U+4E0E 与` | `single-Arial` | **无** | **24.000000** | ✅ | ✗ | `YUGOTHM.TTC#1` / 3883 | **是** | 15/91 |
| `U+4E0E` | `single-TimesNewRoman` | 无 | 24.000000 | ✅ | ✗ | `YUGOTHM.TTC#1` / 3883 | 是 | 15/91 |
| `U+4E0E` | **`file-NotoSans-Regular`** | 无 | **24.000000** | ✅ | ✗ | `YUGOTHM.TTC#1` / 3883 | **是** | 15/91 |
| `U+4E0E` | `list-Arial-SegoeUISymbol` | 无 | 24.000000 | ✅ | ✗ | `YUGOTHM.TTC#1` / 3883 | 是 | 15/91 |
| `U+4E0E` | `typeface-declared-fallback-YaHei` | 无 | 24.000000 | ✅ | ✗ | `MSYH.TTC` / 1034 | 是（用点名的族） | 15/91 |
| `U+6C49 汉` | `single-Arial` / `TimesNewRoman` / `file-NotoSans-Regular` / `list-…` | 无 | **24.000000** | ✅ | ✗ | `MSJH.TTC#1` / 15408 | 是 | 10/91 |
| `U+6C49` | `typeface-declared-fallback-YaHei` | 无 | 24.000000 | ✅ | ✗ | `MSYH.TTC` / 2126 | 是 | 10/91 |
| `U+05D0 א` | `file-NotoSans-Regular` | 无 | 15.280000 | ✗ | ✗ | `SEGOEUI.TTF` / 2920 | 是 | 10/91 |
| `U+0627 ا` | `file-NotoSans-Regular` | 无 | 6.013333 | ✗ | ✗ | `SEGOEUI.TTF` / 2317 | 是 | 10/91 |
| `U+2192 →` | `file-NotoSans-Regular` | 无 | 20.706667 | ✗ | ✗ | `SEGOEUI.TTF` / 2862 | 是 | 41/91 |
| `U+E000` | `single-Arial` | 无 | **18.000000** | ✗ | **✅** | `ARIAL.TTF` / **glyph 0** | 否 | **2/91** |
| `U+E000` | `single-TimesNewRoman` | 无 | 18.666667 | ✗ | ≈（见 §6） | `TIMES.TTF` / **glyph 0** | 否 | 2/91 |
| `U+E000` | `file-NotoSans-Regular` | 无 | **14.400000** | ✗ | **✅** | `NOTOSANS-REGULAR.TTF` / **glyph 0** | 否 | 2/91 |
| `U+E000` | **`list-Arial-SegoeUISymbol`** | 无 | **24.000000** | ✅ | ✗ | **`SEGUISYM.TTF` / 4366** | **是（用列表里点名的族）** | 2/91 |
| `U+E000` | `typeface-declared-fallback-YaHei` | 无 | 18.000000 | ✗ | ✅ | `ARIAL.TTF` / glyph 0 | 否 | 2/91 |
| `U+10FFFD` | 全部 5 个设定 + `explicit-covering-NONE-FOUND`（共 6） | 无 | 18.0 / 18.666667 / 14.4 | ✗ | ✅（Arial/Noto）/ ≈（Times） | 段落字体自身 / **glyph 0** | 否 | **0/91** |

**"有该码点"的 18 行对照（全部无回退）**：`U+05D0`/`U+0627`/`U+2192` 在 `Arial`、`Times New Roman` 上都有 → 用它们**自己的**字形与 advance（如 `א` Arial 13.513333 / Times 11.553333；`ا` 4.97；`→` Arial/Times **24.000000 = 1 em**、glyph 314）。
⇒ **"1 em" 在"有该码点"的样本上也照样出现**（Arial 自己的 `→` 就是 1 em）——再次说明它不是缺字规则。

## 4. 本机安装字体覆盖计数（把"没有字体覆盖它"从假设变成读数）

由程序在真机上枚举 `Fonts.SystemFontFamilies` 逐个 face 查 `CharacterToGlyphMap` 得到：

| 码点 | 覆盖族数 | 覆盖 face 数 | 例子（族 / 文件 / 字形 / advance-em） |
|---|---|---|---|
| `U+4E0E 与` | **15 / 91** | 80 / 563 | Microsoft JhengHei / `MSJH.TTC` / 7669 / **1.0** |
| `U+6C49 汉` | 10 / 91 | 50 / 563 | Microsoft JhengHei / `MSJH.TTC` / 15408 / **1.0** |
| `U+05D0 א` | 10 / 91 | 97 / 563 | Cascadia Code / `CASCADIACODE.TTF` / 1674 / 0.585938 |
| `U+0627 ا` | 10 / 91 | 86 / 563 | Cascadia Code / `CASCADIACODE.TTF` / 681 / 0.585938 |
| `U+2192 →` | 41 / 91 | 289 / 563 | Cascadia Code / `CASCADIACODE.TTF` / 2094 / 0.585938 |
| `U+E000` | **2 / 91** | 8 / 563 | Gabriola / `GABRIOLA.TTF` / 4327 / 0.792725 |
| `U+10FFFD` | **0 / 91** | **0 / 563** | — |

⇒ `U+10FFFD` 是**实测零覆盖**，所以 6/6 全都落到 `.notdef`；
`U+E000` 只有 **2 个族**覆盖，于是**只有在列表里点名了 `Segoe UI Symbol` 时才被换上**，否则 `.notdef`。

## 5. 便宜项：`TextModifier` 的**方向嵌入**

**一句话结论**：**在本批构造下完全观测不到差异。**
3 种"段落×内容"形态（LTR 段落里的拉丁 scope、LTR 段落里的希伯来 scope、RTL 段落里的希伯来 scope）× 2 个宽度（**40 会折成 2 行**，因此 `GetTextLineBreak()` 有信息量；140 单行）= **6 组比较**，
`HasDirectionalEmbedding=true`（LTR 与 RTL 两个方向都试了）与"恒等 `ModifyProperties`"**逐位相同**：
行数、每行行宽、每行首个 glyph run 的 `BidiLevel`、以及 `GetTextLineBreak()` 的 null 模式**全部一致**。
例：`latin-scope-ltr-para@w40` 三种模式都是 `lines=2, widths=[38.693, 36.093], breaks=[非null, null], bidi=[0,1]`。

**必须标注的边界**：读作"**本构造下无可观测影响**"，**不等于**"该标志无意义"——
本批每个 doc 都是单一 text source、单一打开的 scope；WPF 自己（`PresentationFramework`）只在**内联元素的 `FlowDirection` 与其父不同**时用方向版 `TextSpanModifier`。
**本批分不开**"该形状下嵌入本就是 no-op"与"仅带标记的 modifier run 无法把嵌入带到 run 上"。

## 6. 取不到 / 未覆盖（无信息就报无信息）

- **回退的搜索顺序取不到**：只能读到"最终用了哪个字体"，读不到"怎么选的"；回退表是 DirectWrite/系统层面的事，未暴露。
- **方向嵌入为何无影响未定**（见 §5 的边界；需要"内联嵌套"那种构造才能分辨）。
- `Times New Roman` 的 `.notdef` 实测 advance `18.666667` 与 `GlyphTypeface.AdvanceWidths[0]*emSize = 18.667969` **差 0.0013 DIP**：两个值并列给出，**未做调和**，如实登记为该字体的观测量差异。
- 码点表只用了 **emSize 24 + 段落宽 400** 一档；"advance 比例不随字号变"是**预期**不是读数。
- 只测到 **glyph 0（`.notdef`）**这一种"缺字行为"；若某字体真的为私用区码点做了字形，本 oracle 会把它算作"覆盖"（`U+E000` + Segoe UI Symbol 正是这种情况）。
- `TextTrimming` / `Tabs` 非 null / `NoWrap` 仍未测（按既定边界不为它们花出行成本）。

## 7. 产物与复现

| 文件 | 说明 |
|---|---|
| `out/font-fallback-raw.json` | **真机原始输出，未经修改**（60 cases，sha256 `62e2d45dd04d36e279fcf32fff1de98701bb827c270cad576da09f56fb61abaa`） |
| `out/font-fallback-raw.txt` | 同上人读版 |
| `out/font-fallback-oracle.json` / `.txt` | 推导产物（`cases` 原样内嵌 + `answers` / 41 行主表 / `unavailableOrUntested`） |
| `analyze.py` | `python3 analyze.py out/font-fallback-raw.json out/font-fallback-oracle` |
| `src/Program.cs` `src/FontFallback.csproj` `src/run.ps1` | 真机测量程序；`run.ps1` 跑两遍 + 规范化 sha256 比对 + **逐文件打印 SHA256** |

`DETERMINISM=MATCH`（`A=e2c68e6b602c0911 B=e2c68e6b602c0911`），`cases: 60`。两个输出文件 sha 与真机打印值**回传后逐文件复核一致**（`json 62e2d45d…`、`txt b43e3206…`）。

## 8. 自我纠错（本轮 2 条，都已修并复跑）

1. **首两次出行失败，如实报失败、未伪造任何读数**：
   (a) 程序把 `NaN/Infinity` 写进 JSON ⇒ `System.Text.Json` 抛异常，真机 `EXITCODE=-532462766`，`run.ps1` 六次重试全失败 —— 修为**序列化前把 NaN/±Inf 归一为 `null``；
   (b) 修好后我自己的**控制台摘要**用错了键名（`specifiedNotdefAdvanceDip`，实际是 `specifiedFontNotdefAdvanceDip`）⇒ 文件已写出但退出码非 0 —— 修键名后复跑，`EXITCODE=0`。
2. **便宜项首版设计不合格（我自己的缺陷）**：方向嵌入最初只在 400 DIP 单行宽度下测 ⇒ 9 个样本**全是单行**，`GetTextLineBreak()` 全为 null，"非 null/行数/行宽是否不同"这半问**没有信息量**。已补 **w=40（会折成 2 行）**，样本 9 → 18，重跑后才给出 §5 的结论。

## 9. 合规与清理

真机**只读**（未装软件、未改工程配置、未动他人文件；只读 `C:\u1-shaping\fonts\NotoSans-Regular.ttf` 作为"文件字体"样本）；
**本地零构建零应用**；只写 `tests/parity/windows/font-fallback/**`；未碰 `src/`、`build/`、`samples/`、
`tests/parity/{linux,geometry}/`、`tests/golden/`、`docs/unimplemented.md`、`verify-all.sh`、`upstream/`（只读）、`handoff.md`。
远端收工后清理（见最终汇报）。

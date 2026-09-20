# 波 `#22` 预登记（**落地之前先登记**）

> 生成：主控，基于**当前冻结基线 `#21`**（权威 = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 表头 `0d048e6e8808c4e7`）。
> 冻结九位（开工前已现场复算**逐位一致**）：`bridge d567c26f197ec1e3`(4,987,840 B) | `pc e7cabff9417ed380` | `pf 2fb1a896f8277647` | `windowsbase 1114a28ec5a03ab7` | `provider 9aa0d744802aaa31` | `win32shim 0098234982391bbf` | `wic_shim 03b67fbcd7c385b6` | `hbtextline 76089e1de586ac91`(283,557 B) | `dwf 0ed422ef2dd46445`；`BRIDGE_SRC_FP=b6acdba4f01599d8`；`inputs_fp=a2b74537427ecc4a987edbe52a59c5d01d4817d54de58f445833c33dfb0e78e0`。
> 纪律：**落地前先预登记**｜红判据**只许加强**｜**预测表之外的位移 ⇒ 停**｜缺数据 ⇒ `NOINFO`｜**分母口径必须写清**（纪律 39）｜**仪器输入也算仪器**（纪律 40）｜**"在射程内"≠"真的看了"**（纪律 41）。
> 沿用 `#21` 的资源约定：`nproc=3` ⇒ **只有被点名的车道可以跑 `dotnet build`**；只读车道**零 dotnet**。

## §0 本波四件（按价值排序）

| 件 | 题目 | 类型 | 世代成本 |
|---|---|---|---|
| **P1** | `D-R3` 残项 (iii)：**判据① 的修前对照** —— 唯一一条"**判据本身从未被验过**" | 判据自检 | **无**（只需跑探针） |
| **P2** | `D-G1`：把 `lineStartOffsetsDip`/`Start` 的比较接进 **`CoverageProbe`**（补 `#21` 只堵一半的那一半） | 仪器补强 | 无（**但要按纪律 40 披露仪器变更**） |
| **P3** | `D-T6-b`：**判据 + 红证 + 落地方案**（帧原点 = 最近一次重新收集的 `cpFirst`） | 判据先行 | 修法**要**（本波**条件性**落地，见 §3.6） |
| **P4** | `D-A2` 未判副本盲区 + `D-T5`「异常会不会传到应用层」 | 只读盘点 | 无 |

---

## §1 P1 —— `D-R3` 残项 (iii)：判据① 的修前对照

### §1.1 为什么它排第一（**它是唯一一条"判据自己没被验过"**）
`#18` 给两个产品侧安装点加了守卫，`#18` 收官时**如实登记**了一条代价：**收窄**（只让自证在"输了竞态"的分支里跑）之后
**"判据① 不再由守卫行使"**（改用探针 `ResolverGuardProbe` 的 `realcall` 直测），而**"① 的修前对照没测过"**。
⇒ 于是**存在这种可能：① 是恒绿的**（正常路径在修前也是好的 ⇒ 这条判据**从来不会红**）。若如此，它**根本不是判据**，只是"回归锁"。
**这与 `D-T6-c` 是同一族疾病**（纪律 41 的第 ② 种强度：在射程内但不看/不会红），所以必须现在查清。

### §1.2 **成本已被主控查清 = 低**（不必重建！）
判据①的两侧件都在 `$HOME` 里**现成**（本波开工前已定位并记 sha）：

| 侧 | 件 | sha16 | 现成副本（示例） |
|---|---|---|---|
| **修前**（**无** V1 守卫） | `WindowsBase.dll` | **`e6216fe961a2bfb9`**（= `#17` 世代值） | `$HOME/w18a-build/bin/Debug/WindowsBase.dll`（另有 10+ 份：`w17d-build/`、`w18-build/`、`w17-gate-wicdiag/` …） |
| **修后**（**有** V1 守卫） | `WindowsBase.dll` | **`1114a28ec5a03ab7`**（= `#18` 起的值） | `build/WindowsBase.Linux/bin/Debug/WindowsBase.dll` |
| **修前**（**无** V2 守卫） | `WpfGfx.Linux.dll` | **`0c597fb6ec1eec70`** | **`$HOME/m7b-w8/nat/new/WpfGfx.Linux.dll`**（唯一一份，**务必先 `cp -p` 留档到仓库外的第二处**） |
| **修后**（**有** V2 守卫） | `WpfGfx.Linux.dll` | **`c400ab1638e0c3d2`** | `src/WpfGfx.Linux/bin/Debug/net10.0/WpfGfx.Linux.dll` |

⇒ 探针 `build/MilBridge/tests/ResolverGuardProbe/`（现 sha16 待读）**设计上就是"对任意两份目标件取证"**（`Assembly.LoadFrom(绝对路径)` + 反射、**零 HintPath**、不引任何产品工程）⇒ **同一份探针二进制可以测两棵树**，读数可逐字对拍。**不需要任何重建。**

### §1.3 要回答的问题（**必须逐条给读数，不许只给结论**）
1. **判据①（`realcall`）在修前件上的读数是什么？** 与修后件是否**相同**？
   - **相同** ⇒ ① **对 `D-R3` 这个缺陷零判别力** ⇒ 必须**改判为"正常路径回归锁"**（并登记，不许继续当"守卫的判据"）。
   - **不同** ⇒ ① 有判别力 ⇒ 记录"修前红、修后绿"的**两极读数**，① 保持判据身份。
2. **判据④ 同样要取修前/修后两读**（`#18` 记载"④ 退回修前同款行为" ⇒ 它**可能**是恒定的，必须实测）。
3. **真正有判别力的那一条是哪条？** `#18` 的两极红证走的是 **(a) 抢先者映射同名 ⇒ 无害** / **(b) 抢先者不映射我们的名字 ⇒ 响亮且点名**。
   ⇒ 请把 **(a)/(b) 也在修前件上各跑一次**，回答"**修前件在 (b) 下是响亮失败，还是静默降级/崩溃？**" —— **这条才是 `D-R3` 的缺陷本体**；
   若修前件在 (b) 下**本来就响亮**，那么 `#18` 的守卫**没有修任何可观测的东西**（那是重大结论，必须如实写）。
4. **`variant=none` 的含义要写准**：探针的 `ReportForeignInstall` 对 `variant=="none"|"self"` 是 `SKIPPED`（不装抢先者）⇒ **`variant=none` 不是"修前对照"**。修前对照只能是 §1.2 的那两份**旧产物**。

### §1.4 反极性（**缺一即本件作废**）
- 本件的"判据"= 探针的每一条读数。**必须给出至少一条在修前/修后之间真的不同的读数**；
- 若**所有**读数在两棵树上**完全相同** ⇒ 结论是"**探针当前对 `D-R3` 零判别力**"，并**登记为发现**（不许把它读成"守卫没问题"）。
- 留档：两棵树的每个读数 + 探针自身 sha16 + 两份目标件的 sha16（纪律 15/18）。

---

## §2 P2 —— `D-G1`：把 `Start`/`lineStartOffsetsDip` 接进 `CoverageProbe`

### §2.1 现状（`#21` 已实测）
三支 tab 臂的宿主 `build/MilBridge/tests/CoverageProbe/Program.cs` 里 `lineStartOffsetsDip` 与 `TextLine.Start` 出现 **0** 次；
它实际比较的字段只有 `lineText` / `startChar` / `newlineLength` / `trailingWhitespaceLength` / `width` / `maxWidth` / `modifierStart` / `visibleText`。
⇒ **语料里 615 个真值（171 行非零）从来没进过门禁的射程**。`#21` 只把判据接进了 `PcLineOracle`/`verify-all` 第 11 步，**门禁的臂仍然瞎**。

### §2.2 要做的事
把 **逐行 `TextLine.Start` vs 语料 `lineStartOffsetsDip[k]`** 的比较加进 `CoverageProbe` 的 tab-anchor 臂判据，**顺带评估同族**：
`height` / `baseline` / `hasOverflowed` 是否同样"在语料里有真值、而比较表里没有"（**逐个给"语料里有/无"与"比较了/没比较"的实测**，不许一概而论）。

要求：
- **只许加强**：新列**必须能决定红**（不能只打印）；必须有**可点名的计数器**；反极性 = 用 §1.2 式的**旧 shim 产物**？不行 —— 本臂编的是**源**，所以反极性用 `-p:HbShimSrc=<旧 shim 源>`（`HbTextLineParity`/`CoverageProbe` 都有这个旋钮）指向 `$HOME/w21a-pre/PresentationCore.HbTextLine.cs.pre`（`fe1b7ed8fa3ed231`）⇒ **新列必须红 138 行**。
- **仪器变更披露（纪律 40）**：`CoverageProbe/Program.cs` 的 before/after sha16 + `CoverageProbe.dll` 的 before/after sha16 都要记；**并说明"重取的臂日志是在新仪器上取的"**。
- **不许动** `build/MilBridge/known-red.json`、`tline-gate.sh`、`verify-all.sh`（主控写域）。
- **不许**为了让门禁保持绿而把新红压成"已登记"；新列若出现**未登记红**，**如实报告并等主控裁决**。

### §2.3 预测（**表外位移 ⇒ 停**）
| 项 | 预测 |
|---|---|
| `tab-anchor` 臂的**既有判据行** | **逐字不动**（只**新增**列；`结构=`/`位置=` 的既有口径一个字节不许改） |
| 新列（`Start`） | **绿**（shim 已修：`Start => _paragraphIndentDip`）——**若红 ⇒ 停并报告**（那意味着"源直调"与"产品 pc"两侧不一致，是**重要发现**） |
| `tab-zero`/`tab-rtl`/`textlineproto`/`tline` 四支日志 | **逐字节不变**（它们不吃 tab-anchor 语料） |
| 门禁 | `TLINE_GATE` 仍 `PASS`、`generation=#21 tree_gen=same`（`CoverageProbe` **不在**世代绑定三项内 ⇒ **不需要重钉**） |
| 九位 / `inputs_fp` | **逐位不变** |

---

## §3 P3 —— `D-T6-b`：判据 + 红证 + 落地方案

### §3.1 机制（`#21` 已静态定完；**⚠️ 行号已由主控按 `#21` 后的 shim 现场重读更正**）
> ⚠️ **纪律 4 的现场（一行更正）**：本节的锚点原先引自 `#21` 之前那一版 shim（`fe1b7ed8fa3ed231`）；`#21` 的修法让 shim 从 4,719 行长到 **4,769 行** ⇒ **旧行号全部漂了**（`#21` 车道 W21C 报的 `shim:4442`/`:4531-4536`/`:4554` 都**不再成立**）。下面是**现场重读**的锚点。

- **帧 = `_lineStart`** = 产生该行时 `HbLineRange.Start` **相对"调用方递进来的那个 `text` 串"**的偏移（`HbTextLine` 私有 ctor：**`shim:2744` `_lineStart = lineStart;`**，值来自 `HbTextLineFactory.FormatLine(... range ...)` 的 `range.Start`）。
- 而**两档的收集都从 `cpFirst` 起** ⇒ **`text` 的原点 = `cpFirst`**：
  - **严格档**：`shim:4572` `TryFormatLine(TextSource textSource, int cpFirst, …)` → `shim:4487` `TryCollect(TextSource src, int cpFirst, out string text, out List<CollectedRun> runs)`（`shim:4492` `int cp = cpFirst;`）→ `FormatParagraph(text, …)`。
  - **宽松档**：**生成物** `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:101` `CollectLenient(TextSource src, int cpFirst, …)`（`:117` `int cp = cpFirst;`）→ `:264` **`return lines[0];`** ⇒ 该行 `range.Start = 0`。
- ⇒ **宽松档的 `_lineStart` 恒 0，而真值应当是 `cpFirst`**；严格档靠段落缓存持住 `0,1,2`，**缓存未命中时退化成同一形状**。

- **⭐⭐ 本波新增的"源码内自证"（主控读码，比"两条腿实测"更硬的一条）**：`shim:4030-4044` 的 `ParaCache` 里
  ```csharp
  public bool Contains(int cp) { int pos = Start; foreach (HbTextLine L in Lines) { if (pos == cp) return true; pos += L.Length; } … }
  public HbTextLine LineAt(int cp) { int pos = Start; foreach (HbTextLine L in Lines) { if (pos == cp) return L;    pos += L.Length; } … }
  ```
  而 `shim:4604` `s_cache = new ParaCache { Source = textSource, Start = cpFirst, Lines = lines };`、`shim:4582` 用 `c.Contains(cpFirst)` 命中。
  ⇒ **缓存是按"绝对（段落系）位置"给行编址的**：第 0 行在 `cpFirst`，第 1 行在 `cpFirst + len₀`，……
  **而同一批行对象里的 `_lineStart` 却是"相对收集串"的偏移**（第 0 行 = 0，第 1 行 = len₀，……）。
  ⇒ **同一个量（第 k 行的起点）在同一个类里存在两套相差 `cpFirst` 的坐标系** —— 这**不需要跑任何东西**就能看出是缺陷，并且**直接给出修法**：`_lineStart = paragraphOrigin + range.Start`（`paragraphOrigin = cpFirst`）。
  ⇒ 这条也让判据的**期望值**变硬：真机 `cases[].lines[].startChar` 落的就是**绝对系**（= 传进 `FormatLine` 的 `index`）⇒ 与 `ParaCache` 同一套系。
- ⇒ 定性仍为"**帧原点 = 最近一次重新收集的 `cpFirst`**"（两档共有）；**缓存是帧的唯一来源**。

### §3.2 判据（要写进臂里，**必须能红**）
逐行比较 **我们的帧** 与真机 **`cases[].lines[].startChar`**（真机臂 `tests/parity/windows/tab-anchor/src/Program.cs:556` 落盘、= 传进 `FormatLine` 的 `index` 的真值），**精确相等**。
- **帧怎么取**：`PcLineOracle` 的 `--guard` 已经在算「行帧（逐行扫描：最小的、能取到边界的段落系下标）」（`#21` 的日志里就有 `=[0,1,2]`）⇒ **优先复用**；若该扫描不可靠，**新开一列**直接暴露 `_lineStart`（`internal` 可见性够不够要实测）。
- **分母口径（纪律 39）**：语料 436 例 / 615 行，其中臂可判定的 = `script==latin` 的 **288 例 / 421 行/138 行非零** ⇒ **预测数只能按 421 行口径写**。
- **反极性**：`--tier strict` 与**宽松档**两条腿**都要取**。预测：**宽松档腿每行 `startChar>0` 必红**；严格档**大部分绿**（缓存持住帧），**缓存未命中处红**。
  ⚠️ **`#22` 主控更正（数字用错了字段）**：原文写「≥171 行、latin 折算 138 行」—— **171/138/88 是 `Start` 那一列的口径，不是 `startChar` 的**。主控已独立重算：**`startChar != 0` = 全域 179 行 / latin 133 行**（另 `hasOverflowed=True` **22** 行、`dependentLength != 0` **179** 行；而 `height`/`baseline`/`stoppedEarlyBecauseLineLengthWasZero` **恒为常数** ⇒ **拿它们当红判据 = 零判别力的假判据**）。

### §3.3 红证（本件的**交付物**）
不许只有"我读代码觉得会红"：**必须跑出红的读数**（点名 `id` + 行号 + 我方帧 + 真值帧），并与主控的期望集口径对账。

### §3.4 落地方案（**要写清爆炸半径**）
`#21` 已定：给 `HbTextLineFactory.FormatParagraph` 加**带默认值**的段落原点形参（`paragraphOrigin`），透传到 `FormatLine` 的 `_lineStart`（**`_lineStart = paragraphOrigin + range.Start`**）与 `_glyphRunCharStart`。
必须逐处列出**受影响的成员**并**逐成员给预测**：
- **受影响**（`#21` 已静态定）：`GetTextBounds`（`shim:3022-3023` **返回空表** —— 真机是**夹取**，`upstream …/FullTextLine.cs:1495-1504` → `CreateDegenerateBounds()`）、`GetIndexedGlyphRuns`、`Collapse`/`GetTextCollapsedRanges`，另 `BuildCollapsedLine` **硬写帧 0**（`shim:3625` 一带）。
- **不受影响**：`Length`/`Width`/`WidthIncludingTrailingWhitespace`/`NewlineLength`/`TrailingWhitespaceLength`/`Height`/`Baseline`/`HasOverflowed`/`GetTextRunSpans`/`Draw` 几何、以及 **`Start`**（它只吃 `_paragraphIndentDip`）。
- **两个构造点**都要透传（`shim:2905` 行构造 + **`BuildCollapsedLine`**）——这是 `#21` 踩过的坑，**不许再漏**。
- **⚠️ 真机侧后果要说清**：真机消费者 `MS/Internal/Text/Line.cs:167` 之后紧跟 **`:171 Invariant.Assert(textBounds.Count > 0)`**（另见 `TextBoxLine.cs:259/:496`、`PtsHost/Line.cs:501/505/995/999`、`TextBlock.cs:2314`）⇒ **空表在真机侧是断言失败**，不是"读数偏一点"。

### §3.5 世代成本（**要付，如果修法落地**）
`build/shims/PresentationCore.HbTextLine.cs` 是世代绑定的三项之一 ⇒ **五臂重取 + `known-red.json` 重钉 + 两极化重做**。
**建议与 `D-F2` 合并**（`SegmentFaceUnresolved` / `RunFaceSlotMissing` / `ScanCapped` 三个"**只写不读**"的计数器一起接出口：`SummaryFragment()`（`shim:1344-1379`）里一个都没有，而 `ScanCapped` 的注释**自称**"诊断行报 `capped=`"却**零打印点**）—— 两者**都动 shim ⇒ 只付一笔世代成本**；且 `D-F2` 只是往诊断串里**加字段**，**不改变任何几何**。

### §3.6 **条件性落地（预登记的判据，不是事后合理化）—— 主控修订：本波默认「只登记不落地」**
**本波 P3 的交付物 = 判据 + 红读数 + 落地方案**（`W22C` **不得修改 `build/shims/**`**）。
**为什么把默认改成"不落地"**（在取任何读数之前写下，故不是事后合理化）：`D-T6-b` 的修法是**给 `FormatLine` 加段落原点并改 `_lineStart` 的语义**，
爆炸半径覆盖 `GetTextBounds`/`GetIndexedGlyphRuns`/`Collapse`；而本波 **P2 要在同一时间重取 `tab-anchor` 臂**。
**两者一起动 ⇒ 臂日志的变化归因不清**（`#21` 的教训：一次只让一个东西动，读数才可归因）。
⇒ **落地需要主控在看过红读数之后明确点头**，且落地时**必须单独占一趟波**（不与任何臂仪器变更同趟），并与 `D-F2` 合并只付一笔世代成本。
**落地仍需同时满足三条**（供 `#23` 用）：
1. `FormatParagraph` 的段落原点形参**带默认值**且**既有调用点零改动**（与 `D-T2`(C)/`#19` 的 `indentDip`/`paragraphIndentDip` **同款先例**）；
2. 爆炸半径**逐成员**有预测，且**修后每条都有读数**（尤其 `GetTextBounds` 的**空表→夹取**这一条要单独取读数）；
3. **不连带**改动 `Width`/`Length` 等**已冻结**的记账（`#21` 已证这些与帧无关）。

---

## §4 P4 —— 只读盘点（**零 dotnet**）

1. **`D-A2` 未判副本盲区**：`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh:97-104` 的 `ITEMS` 只有 6 项，`PresentationCore.dll` **不在其中** ⇒ 它的副本**再陈旧也不会有读数**；`wpfgfx_cor3.so` 的**权威串是空的**且**显式写明不覆盖**（`:103`，交给发布脚本的并排 sha 打印）。
   ⇒ 请**枚举**"当前仓内所有 `PresentationCore.dll` / `wpfgfx_cor3.so` / `WpfGfx.Linux.dll` 副本"并逐份判"**有没有任何判据盯它**"（含 `bin/`、`obj/`、`.artifacts/`、app-local）。
   ⚠️ **`#21` 主控已更正一条**：`SCAN_ROOTS`（`:93`）**包含** `$REPO/build` ⇒ `.artifacts/**` **在扫描范围内**；上一波"`SCAN_ROOTS` 不含 `.artifacts`"的说法**是错的**。**不许**把那条错机制再抄一遍。
2. **`D-T5` 的"保质期"问题**：`Length ≥ 1` 的 `TextModifier`/`TextEndOfSegment` 段落回退到 LS ⇒ `LoCreateContext`。要回答**一条**（`W21D` 建议的、`KNOWN-DEFECTS.md` 自己列为未测的）：**异常会不会传到应用层？**（读代码给出路径 + 若需要运行期证据就**如实标"未测"**）⇒ **若会传到应用层 ⇒ 立即升为下一波第 1**。
3. `D-F2` 的三计数器普查：确认 `SummaryFragment()` 里确实一个都没有，并给出"+3 个字段"的**精确改法**（行号级）。

---

## §5 位移预测表（**本波预期为零位移**）

| 位 | 现（`#21`） | 预测 |
|---|---|---|
| 九位（`bridge`/`pc`/`pf`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`hbtextline`/`dwf`） | 见 §0 | **逐位不变**（P1/P2/P4 **不动产品件**；P3 若不落地也不动） |
| `BRIDGE_SRC_FP` / `inputs_fp` | `b6acdba4f01599d8` / `a2b74537427ecc4a…` | **不变**（P2 改的是 `build/MilBridge/tests/**`，不在 `inputs_fp` 覆盖面内；**必须现场复算证明**） |
| 门禁 | `TLINE_GATE=PASS generation=#21 tree_gen=same` | **仍 PASS**（P2 若使 `tab-anchor` 臂日志变化 ⇒ **`drift`/`gone`/`unregistered` 必须仍为 0**，否则**停**） |
| `verify-all` | rc=0 / **11 步** / 871 通过 2 跳过 | **同前**（P2 不改 `verify-all.sh`） |
| 应用门禁 | 6/6 `PASS` | **同前** |

**P3 若落地** ⇒ 九位里**只** `hbtextline`/`pc`/`pf` 三位变 + `inputs_fp` 变 + 门禁需**重取五臂 + 重钉 `known-red.json`**（世代 → `#22`）+ `verify-all` 第 10/11 步重取读数。**其余位一律不变**（与 `#21` 同形）。

---

## §6 停条件（**触发即停**）

1. 任何位移落在 §5 之外。
2. P2 使门禁的 `drift`/`gone`/`unregistered` 非 0（先归因，再决定是否登记）。
3. P2 的新列**红**（⇒ "源直调"与"产品 pc"不一致，是发现，停下来报告）。
4. P1 出现"两棵树所有读数完全相同"⇒ **不许**读成"守卫没问题"，**必须**登记为"探针零判别力"。
5. P3 的三条落地条件任一不满足 ⇒ **只登记不落地**。
6. 任何"把红判据放松"或"把未登记红压成绿"的动作。

---

## §7 收官清单

- [ ] P1：修前/修后两树的**逐条**读数 + 探针与两份目标件的 sha16 + ①/④/(a)/(b) 四条各自的裁定
- [ ] P2：`CoverageProbe` before/after（`Program.cs` + 产物）+ 新列能决定红（含用旧 shim 源 `-p:HbShimSrc=` 的反极性）+ 既有判据行逐字不动 + 四支无关臂日志逐字节不变 + 门禁与九位/`inputs_fp` 复算
- [ ] P3：判据 + **红读数**（宽松档/严格档两条腿）+ 逐成员爆炸半径 + 三条落地条件的逐条裁定
- [ ] P4：副本盲区逐份表 + `D-T5` 的"是否传应用层" + `D-F2` 精确改法
- [ ] 九位 / `inputs_fp` / 门禁 / `verify-all` / 应用门禁 **逐项复算并与 `#21` 对照**
- [ ] 文档：`CURRENT-STATE.md`（新登记 + 纪律）+ `handoff.md` + `KNOWN-DEFECTS.md` + 本文件 §8
- [ ] **若 P3 落地**：重取五臂 + 重钉 `#22` + 重冻基线（否则**不重冻**，`#21` 仍是当前基线）


---

# §8 P1 收官 —— `D-R3` 残项 (iii)：判据① 的修前对照（车道 W22A，报告 `72586d4a85883022`）

## §8.1 裁定表（四条 + 一条新登记）

| 项 | 修前读数 | 修后读数 | 裁定 |
|---|---|---|---|
| **① `realcall`** | `REAL_DLLIMPORT=NOINFO method-absent` | `REAL_DLLIMPORT=OK value=1` | **改判为「正常路径回归锁」**（**零判别力**）—— 但差异的**成因是仪器，不是产品**，见 §8.2 |
| **④（缺件不变式）** | `TRIGGER=natural NO_THROW` / `RUNMODULECTOR=NO_THROW` | **逐字相同** | **改判为「缺件不变式锁」**（**实测证实** `#18` 的"④ 退回修前同款行为"） |
| **(a) 抢先者映射同名** | **`THROW`**：`TRIGGER=natural THROW` + `POISON_RECHECK=THROW` + `RUNMODULECTOR=THROW … A resolver is already set for the assembly.` | `NO_THROW` + `SelfCheckShimVersion=1` | **两极真实**（修前**硬失败**、修后无害）⇒ **`D-R3` 的守卫在这一极上修了实打实的东西** |
| **(b) 抢先者不映射我们的名字** | `RUNMODULECTOR=THROW TypeInitializationException … inner=IOE: A resolver is already set for the assembly.`（rc=0） | 响亮且**点名** | 修前**"响亮但不点名"**：**非静默、非崩溃**，只是成因句把责任指向"重复安装" |

**新登记**：`realcall` 对 **V2 目标**（`WpfGfx.Linux.dll`）抛 **`NullReferenceException`**（`FindShimResolverType` 返 null，探针 `Program.cs:198`）—— **那看着像产品失败，其实是探针自己崩了**；两棵树**逐字相同** ⇒ **零判别力**。⇒ 记一条"**仪器崩了会被读成产品崩了**"的实例。

## §8.2 ⭐ 本件**最值钱的一条**（比预登记更锐，是"缺陷本体"的重新表述）

修前件对三类抢先（`replica` 映射同名 / `different` 映射别的 / `broken` 映射坏的）给出 **6/6 对逐字 `IDENTICAL`** 的读数（V1 三对 + V2 三对）；修后 **6/6 对 `DIFFERENT`**。
⇒ **修前连"无害抢占"与"有害抢占"都分不开** —— 因为**抢占一律致命、且成因一律归到"重复安装"**。
⇒ **`D-R3` 的缺陷本体 = "抢占一律致命 + 成因误归 + 三类不可区分"**，**不是**"会不会静默"。
⇒ 这条把 `#18` 那句"③ 非空泛 ✓"从**主张**升级为**可复算的读数**（"三类可分"本身就是判据）。

## §8.3 主控**自我更正**两处（原文在 §1.1 / §1.3 保留不删）

1. **§1.1 那句"① 的修前对照**没测过**"应改为"**测不到**（本仪器测不到）"。**
   我照抄了 `#18` 的措辞，而**实测给出的是第三态**：`NOINFO method-absent`。
   **机制（主控已独立复核）**：探针的调用点 `ShimVersionViaUser32` **本身就是 `#18` 加的方法** ——
   产物级 `grep -aoc` = **修前 `0` / 修后 `1`**；源码级 = `Win32ShimResolver.cs.before` **0** / `.after-narrow` **3**。
   ⇒ **修前件里根本没有那个方法可调** ⇒ "①在修前是红还是绿"这个问题**问不出来**，不是"没问"。
2. **§1.3 第 1 问的"相同 / 不同"两分支不覆盖实况**：**第三态 `NOINFO` 存在**。
   照字面读会把**仪器差异**（方法不存在）当成**产品差异**（行为不同）—— 这正是纪律 41 的"仪器"一侧的镜像。
   ⇒ 补进纪律候选：**判"某判据有没有判别力"时，必须先排除"仪器在修前件上根本量不了"这一态**。

## §8.4 本件**推翻/收窄**的句子（逐条留档）

| 我/旧文档写的 | 实测 | 来源 |
|---|---|---|
| 主控任务书 Q3 后半句"**守卫没有修任何可观测的东西**" | **只对 (b) 成立**；对全局**不成立** —— (a) 修前**硬失败**、修后无害，是实打实位移 | W22A §5 |
| `#18` 的"**(a) 抢先者映射同名 ⇒ 无害**" | 必须**带世代**：修前 (a) 是**有害**的（会**毒化**模块） | W22A §5 |
| `#18` §10.5 / 预登记 §1.1 的"① 的修前对照**没测过**" | 应为"**测不到**"（见 §8.3） | 主控复核 |
| （本件不作废） | **有 8 条读数在修前/修后之间真的不同**：`realcall`、V1(a)、V2(a)、V2(b)、点名文案、`order3`（修前 `RUNCTOR_THROW` 无 `FOREIGN_HIT` → 修后 `RUNCTOR=OK` + `FOREIGN_HIT=user32.dll`）、**三类可区分性**、DIAG 属性由无到有 | W22A §3 |

**地基复核**：`order1/2/3` 那条"**模块初始化器不是加载期跑的**"**仍成立**（实测 `FOREIGN_INSTALL=OK variant=replica`，PC 与 WB 各一次）⇒ `#18` 用来论证"外部安装者能抢先"的地基没被动摇。

## §8.5 一条口径备注（免得后来人误用）
`$HOME/w21a-pre/PresentationCore.dll.pre`（`f4a454c8fe69cdfe`）**不是 `#18` 的"修前件"** —— 它**带守卫**（`SelfCheckShimVersion=1`）；它只是 **`D-T6-c` 的"修前件"**（`#21` 之前那一趟 pc）。
⇒ 同一个名字 `*.pre` 在两条线索里指**不同世代**的东西；**引用时必须连"相对哪一次改动"一起写**（纪律 15/18 又一例）。

## §8.6 主控**独立复现**（"每条结论必须可重算"的现场兑现）
W22A 的 **最值钱那条（(a) 两极）**由主控用**自己的调用**复现过，**逐字一致**：

```
PROBE=$PWD/build/MilBridge/tests/ResolverGuardProbe/bin/Release/net10.0/ResolverGuardProbe.dll   # 38abcc97017e65a6
dotnet "$PROBE" v1 <目标 WindowsBase.dll> replica --loadstream
```
| 侧 | `TRIGGER` | `POISON_RECHECK` | `RUNMODULECTOR` | `DIAG_SelfCheckShimVersion` |
|---|---|---|---|---|
| **修前** `e6216fe961a2bfb9` | `natural **THROW**` | **THROW** | **THROW** … `inner=IOE: A resolver is already set for the assembly.` | `NOINFO property-absent` |
| **修后** `1114a28ec5a03ab7` | `natural NO_THROW IsWicMappingEnabled=True` | `NO_THROW` | `NO_THROW` | **`1`** |

⇒ 修前 (a) **确实是硬失败**（模块初始化器抛），修后无害。**不是"静默"。**
⇒ **主控自己踩了一次的坑（留档）**：不带 **`--loadstream`** 时 `LoadFromAssemblyPath` 会报
`FileLoadException: … manifest definition does not match the assembly reference` —— **我一度以为探针坏了**，
其实是我**调用姿势错**（`--loadstream` 这个选项**不在** `switch(mode)` 里，走的是 `TakeOption` ⇒ **光读 `Main` 的 switch 看不出来**）。
⇒ 建议（下波随手改）：探针文件头补一行"**完整用法含 `--loadstream`**"。**这不是缺陷，是可用性缺口** —— 但它正好说明
"**同一件东西，两个人的调用姿势不同就得到'失败'**"（与 `#21` 的 `--guard off` 同族：**照 sha 比输出前先对齐旋钮**）。


---

# §9 P4 收官 —— 只读盘点（车道 W22D，报告 `44461001f9d10eaa`）

## §9.1 ⭐ `D-T5` **升为下一波第 1**（按派单规则：会传到应用层 ⇒ 升）

**逐层静态追踪（每层都无 catch ⇒ 一路到进程）**：
严格档 shim `:4500-4513` bail 返 null（**有 catch，吞成 null**）→ 宽松档 PC `:235-272`（**有 catch，返 null**）→
**LS 回退 `TextFormatterImp.Linux.cs:615-625` 是裸构造、`try` 都没有** → `FullTextLine` → `TextFormatterContext.cs:113` `LoCreateContext` →
`LineServices.cs:1407` 的 `[DllImport(PresentationNative…)]`（resolver 映射到 `libwpfwin32.so`，`Win32ShimResolver.cs:91`），
而 **`nm -D` 实测该符号 = 0**（**主控独立复核**：`LoCreateContext` 命中 **0**、正对照 `GetWindowLongPtrWrapper` **1**、总导出 **472**）
⇒ `EntryPointNotFoundException` → `FormatLineInternal`（`:512-630` **无 catch**）→ `Line.cs:83`（**无 catch**）→
`TextBlock.MeasureOverride`（生成物 `TextBlock.Linux.cs:1247-1350`：**有 `try` / 无 `catch`**，只做清理）→
`LayoutManager.UpdateLayout`（try/finally）→ `MediaContext`（`grep catch` = **0**）→
**Dispatcher `:2700` 只在有人订阅 `UnhandledException` 时才 catch，而 `WpfTextDemo` 订阅数 = 0** ⇒ 重抛 ⇒ **进程级 abort**。
**在册实测同形**：`T1b-report.md:500-506` 逐字 —— WpfTextDemo `LoCreateContext` **27 次查找 ⇒ MISS**、**`exit=134`**、`blocker=lineservices:LoCreateContext`（同装置 HelloWpf 全 0 ⇒ **阳性对照有效**）。

**⚠️ 升级理由必须写准（不许写成"今天有红"）**：冻树里 **0 载体** —— `samples/**` 没有 `<Run>/<Underline>/Inlines`、WpfTextDemo 没有 TextBox，
全部走 `SimpleLine`，而 `SimpleLine.GetTextRun` **只产** `TextCharacters`（`:53`）与 `TextEndOfParagraph`（`:57`）。
**升它的理由是"失败模式 = 进程级 abort"＋"上游常规写法就会命中"**，不是"已经踩到"。

**⚠️ 本波新发现：这一族比在册**更宽**（`KNOWN-DEFECTS.md` 的 `D-T5` 欠登记）**：
`TextHidden`（`:44-47`，**默认空 CBR、ctor 强制 ≥1**）**机制完全相同**，而**上游 pf 自己在每个内联元素边缘就产它**
（`ComplexLine.cs:404/477/499`、`LineBase.cs:219`）；`TextSpanModifier(1)`（= `Length ≥ 1` 的 `TextModifier`）也**由 pf 自产**（`ComplexLine.cs:424/433/449`、`LineBase.cs:198/207/223`）。
⇒ **`<Run>/<Bold>/<Span>`（走 `TextHidden`）与 `<Underline>/<Hyperlink>`（走 SpanModifier/EndOfSegment）都会命中。**

**判据草案（带**两极化**）**：`PcLineOracle` 新造 `TextSource`（`TextEndOfSegment(1)`，另造 `TextHidden(1)` 变体）⇒ 断言
"**必须交出 TextLine**（两条腿 + 层级来源自证）／**不得出现 `LoCreateContext`**／行 `Length` 一致"。
- **反极性（现状必红）**：`W17D-report.md` 实证 `MINEX CASE mod1 EXCEPTION …`、`relaxedFailed=1 relaxedHandled=0`、`GetTextRun` **只调 1 次**。
- **第二极性（防作弊）**：把 `ExtractRun` 的 `buf==null⇒null` 改成像"修好" ⇒ **判据①会绿、③必须仍红**。

**顺带核对**：`D-T5` 在册描述**与现场相符**（行号逐条复核 ✓；仅 `shim:3810` 漂到 `:3872` 一带）；`D-T4` **相符**（生成物里 `defaultIncrementalTab` **0 命中**；`shim:643/:1745/:2852` 的 `NaN ⇒ 4×em`）。

## §9.2 `D-A2`：**"陈旧也不会红"的副本 = 34 份（口径 α）/ 49 份（含分支豁免）**，且**判据今天就红**

| 口径 | 份数 | 组成 |
|---|---|---|
| **α = 连 sha 都不打印** | **34** | `PresentationCore.dll` 非权威副本 **32**（共 33 含权威）+ `wpfgfx_cor3.so` **2** |
| β = 含"分支豁免" | **49** | α + `WpfGfx.Linux.dll` **15**（`NO-AUTHORITY` 5 ／ `SKIP(obj)` 3 ／ `SKIP(ref)` 6 ／ **漏扫 1**） |

- **机制（主控已独立复核）**：`check-applocal-sync.sh:97-104` 的 `ITEMS` **根本没有 `PresentationCore.dll`** ⇒ `:201` 的逐件循环不为它执行；
  `applocal-expect.py` 的期望集也不含它 ⇒ **删一份连 `MISSING` 都不报**。`wpfgfx_cor3.so` 的**权威串为空**（`:103`）⇒ `:205` 早退。
- **其中 PC 的 17 份今天已经是旧世代**（8 个不同旧 sha）。
- **⭐ 本波新查出的漏扫实例**：`tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll`（`16baacfccfcf1df0`，288,768 B，**是启动宿主**）——
  而 **`tools/` 根本不在 `SCAN_ROOTS`**（**主控独立复核**：`:93` = `build:tests:samples:src`）⇒ **连枚举都没枚举到**。
- **判据草案的"反极性"是实测的，不是声明**：用 `applocal-expect.py` 的**私有拷贝**（`$HOME/w22d-scratch/expect-pc.py` `faa01dd7a5e713cc`，只加一行 PC 项；**仓内 0 改动**）
  模拟"PC 进 `ITEMS`" ⇒ 期望 **55 → 86** 条 ⇒ **接线后立刻 17 份红**（全 `STALE`/`NEWER-DIFF`）、12 份 OK、**0 份 MISSING**，另 3 份走豁免分支
  （`CycleStub×2` 被 `is_stub()` **按路径**豁免 —— 而**它们的内容就是权威件**；`PresentationCore.Linux/obj/Debug/` 走 `SKIP(obj)`）。
  ⇒ **这条判据今天就红，不是"接了也永远绿"。**
- **两条最小加项**：① `SCAN_ROOTS` 补 `$REPO/tools`；② 给 `wpfgfx_cor3.so` 配**非 Debug 权威**（因为 ④ 豁免要求"权威是 Debug"）。

## §9.3 `D-F2` 改法 = **`+3` 行**（推荐 `+4`）（**与 `D-T6-b` 合并 ⇒ 只付一笔世代成本**）

- 插在 `SummaryFragment()` 的 **`:1377`（`candidates=`）之后**、`:1378` `return` 之前；字段名 `scanCapped`/`segmentFaceUnresolved`/`runFaceSlotMissing`。
- **⚠️ 顺序陷阱（必须写进落地单）**：**必须在 `candidates=` 之后** —— 那行的 `HbFontCandidates.Count` getter 会触发 **`EnsureScan()`**，而 `:1147` 正是 `ScanCapped` 的**唯一自增点**。
- 推荐 **`+4` 行**：`PlanCalls == 0` 的**早退分支**会把这几个一起吞掉 ⇒ 早退串里也要补 `scanCapped=`（另两个自增点都在 plan 路径内 ⇒ 恒 0）。
- **另需同步改 3 处注释伪证**（`:1067`/`:1146`/`:1271` 自称"诊断行报 `capped=`"），否则伪证留着。
- **对判据行的影响 = 无（机器核过）**：`grep -n "HB_TEXTLINE|SummaryFragment|multifont=" build/MilBridge/tools/tline-gate.sh` = **0 命中**（门禁取的是臂的**判据状态行**）；`verify-all` 第 11 步、`run-wpfprobe.sh:511-515`、`t1b-d3-acceptance.sh:74-76` **都只取整行**。

## §9.4 车道**推翻/更正**的在册陈述（5 条，逐条留档）

| 在册原文 | 实测 | 判定 |
|---|---|---|
| `KNOWN-DEFECTS.md`（`D-A2`）"全部 `.so` 副本（含已发布的桥）… **不可能变红**" | **只说对一半**：逐份确实判不了，**但它在"跨副本一致性"分组里**（实测 `CONSISTENT wpfgfx_cor3.so [Release] 2 份副本同 sha d567c26f197ec1e3`）⇒ **两份不一致会 `DIVERGENT` + `rc=1`（那是红）**；残留洞只剩"两份一起旧" | **更正** |
| 同处 "`ITEMS` 只含 **5** 个件" | 现盘是 **6** 项（`:97-104`，第 6 项 = 权威为空的 `wpfgfx_cor3.so`） | **更正** |
| 同处 "`.artifacts/**` 不在 `SCAN_ROOTS`" | 错（主控 `#21` 已更正）；**车道补了主控没点名的**：真正漏扫的是 **`$REPO/tools`** | 已更正 + **补一条** |
| `docs/CURRENT-STATE.md`（`D-G4`）"全仓 `capped=` 的命中**全是注释、零打印点**" | **字面不成立**：`invisible_capped=`（`applocal-expect.py:485`，**今天 = 2 且真在打印**）也会被 `capped=` 匹配到 ⇒ 准确写法 = **`[^_]capped=`** | **主控已在 `#22` 内更正 `CURRENT-STATE.md`**（`a51ffc49fe5f71a7`） |
| `D-T5` 家族 | **欠登记**：`TextHidden` 机制相同且由上游 pf 自产（见 §9.1） | **登记为欠宽** |

**未做 / NOINFO（不猜）**：本件**零运行期读数** ⇒ `D-T5` 的"传到应用层"是**静态追踪 + 在册读数引证**（同层无 catch 的**实例**是 RTL/空段落那次，**不是 `D-T5` 本人的触发** —— 不许混读）；`+3 行`**没有编译证据**（纪律 33）；`TextBox` 路径是否产本族 run = **NOINFO**；`TextEmbeddedObject`/`TextShapeableSymbols` 的 CBR = **NOINFO**。


---

# §10 P2 收官 —— `D-G1`：把 `Start` 接进 `CoverageProbe`（车道 W22B，报告 `c98c71f106fec8d7`）

## §10.1 四条必答读数（全部按 §2.3 预测兑现）

| 项 | 读数 | 判定 |
|---|---|---|
| **新列（修后）** | `TAB_LINES START 红=0 绿=421 判定行=421 NOINFO=194 红例=0 NOINFO例=148 对齐=Left`，且 `对账 … ⇒ 与汇总一致` | **绿** ✅（与预测一致） |
| **反极性（旧 shim 源 `-p:HbShimSrc=…cs.pre` = `fe1b7ed8fa3ed231`）** | **`红=138 绿=283 判定行=421 红例=88`**、`rc=1`；138 条 `START-RED` **全部** `实得=0.000000`、Δ 全为 **−真值** | **红 138 行 / 88 例 —— 与预测逐位吻合** ✅ ⇒ **新列不是恒绿** |
| **门禁** | `TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#21 tree_gen=same saved_shim=76089e1de586ac91`、`GATE_REASON=all-as-registered`、`rc=0` | ✅ **不需要重钉**（与 §2.3 预测一致） |
| **九位 / `inputs_fp`** | 逐位不变（`a2b74537427ecc4a…`） | ✅ **§5 表外位移：无** |

## §10.2 "只新增"的**机器证**（比"我保证没改别的"强）
- `CoverageProbe/Program.cs` `a8727a5bed6bf049`(108,127 B) → **`421fe394bea93fe2`**(116,496 B)；产物 `PresentationCore.Tests.dll` `c74a53c5f0ada1d0` → **`5baf3616723c4625`**（0 error）。
- `tab-anchor.log` **469 → 907 行**；`diff` = **0 条 `<`**、**438 条 `>` 且全部以 `TAB_LINES START` 开头**；**剔掉新增行后与 `#21` 原日志 `cmp` 逐字节相同**。
- 新红走**同一张登记表 / 同一个 `failures` 通道** ⇒ `rc` 如实反映（单例两极化：无表 `rc=1` / 有表 `rc=0`）。
- 主控的 `known-red.json` 与 `CoverageProbe/known-red.txt`(`e37603a8825d85ae`) **一个字节未碰**。
- 五臂：**只重链 `tab-anchor`**（`99d72b385fe23a90 → 1a5bc7181d0155c3`；inode `5141091→5142560`）；**四支无关臂 inode/mtime/sha 三位全未动**。⚠️ **如实收窄**：`tab-zero`/`tab-rtl` 车道**重跑过并逐字节复现**；`textlineproto`/`tline` **未重跑** ⇒ 对那两支只有"**文件未被触碰**"的证据，**不是"重跑仍相同"**。

## §10.3 ⭐ 同族普查：**还有哪些真值躺在语料里没人看**（本件价值最高的一条）
| 真值字段 | 有真值的量 | 有没有判据 | 处置 |
|---|---|---|---|
| **`startChar`** | **179 行非零**（latin 133） | **无** | 见 §3（`D-T6-b` 的判据） |
| **`hasOverflowed`** | **22 行为 True** | **无** —— **而 `D-O1`（`#16`）刚把它从"恒假"改成真实现** | **必须补**（"刚动过却无判据"是最该补的一类） |
| `dependentLength` | 179 非零 | 无 | 评估 |
| `widthIncludingTrailingWhitespace` / `inkRightDip` / `lineCount` / `tabCount` | 有 | 无 | 评估 |
| `height` / `baseline` / `stoppedEarlyBecauseLineLengthWasZero` | **恒为常数**（`height` 只有 `27.596667` 一个值、`baseline` 只有 `22.12`、`stoppedEarly` 恒 `False`） | 无 | **⛔ 不许加**：加了就是**零判别力的假判据**（纪律 41 的反面：**它永远不可能红**） |
- 另：`lineStartOffsetsDip ≡ paragraphStartOffsetDip ≡ paragraphIndentDip` 对**全部 615 行**成立（**真值三字段互证**，与 `#21` 的独立重算一致）。

## §10.4 车道的**仪器事故**（建议登记：`-p:BaseOutputPath` 隔离红构建**不可靠**）
用 `-p:BaseOutputPath=`/`-p:BaseIntermediateOutputPath=` 做"隔离红构建"时，它把**陈旧 `pc` `9adac6b8d8e285c3`**（2026-09-15 10:58，`cmp` 证明 **= 本工程 `bin/Debug/PresentationCore.dll` 副本**）拷进了输出目录（权威是 `e7cabff9417ed380`）⇒ **436 例全抛 `DllNotFoundException`**。
- 机制锚：**两份 RAR 缓存记录的解析路径不同**（真构建走 `HintPath` 权威；私有 obj 走本工程 `bin/Debug` 的陈旧副本）；**为何改选 = `NOINFO` 未归因**。
- **⚠️ 它与 `D-A2` 同族**：这正是"**工程 `bin/` 里的陈旧副本会被当成权威**"的活体实例 —— 而且**是构建系统自己选的**。
- **好消息（不许漏报）**：那趟**没有给假绿**（`红=0 绿=0 判定行=0 NOINFO=615`）—— 因为覆盖闸要求"判定行 > 0"。⇒ 这条**印证了 `#21` 那个"防恒绿退化"的设计是必要的**（如果只看"红=0"，那一趟会被读成 **PASS**）。
- **纪律**：反极性构建**必须原地取**，或**必须校验输出目录里的 `pc` sha == 权威**（`build/MilBridge/tools/pc-line-step.sh` 就是这么做的 —— 它内置了这条断言）。

## §10.5 车道**更正主控**的两处（都要连读数一起读）
1. **§2.1 的字段清单不成立**（见上文 `CURRENT-STATE.md` 的 `D-G1` 更正）：本径**只比 4 个字段**，另 4 个属 b34 `--layout` 臂。
2. **§3.2 的预测数用错了字段**：`startChar` 与 `Start` 是**两个量**（179/133 vs 171/138）。⇒ `startChar` 的口径进 §3.2 更正，`Start` 的口径留在 `#21`。

## §10.6 `verify-all.sh` 的 sha 记账（车道提请注意，主控已核 = **不是漂移**）
车道报"`verify-all.sh` 现 `279b958dda238447`，而 `#21`/W19A 记录的是 `a68823631e8f8919`"。
**裁定：这是 `#21` 波内的正常变更，不是漂移** —— `279b958dda238447` 就是 **`#21` 收官时**的值（`#21` 加了第 [5] 步 + 更正了"符号链接"错话），且**已记在 `ACCEPTANCE-BASELINE.md` 的 `#21` 块与预登记 §16.1**（`a68823631e8f8919 → 279b958dda238447`）。
⚠️ 但车道提的**道理成立**：凡引用"某脚本的 sha"必须点明**世代**，否则"文档里那个数 ≠ 现场这个数"会被当成漂移追。⇒ 见纪律 40 同族。


---

# §11 P3 收官 —— `D-T6-b`：判据 + 红读数 + diff 草案（车道 W22C，报告 `93d66fa348ddbb3a`）

> **本件是本波最值钱的一件：它阻止了一次"按预登记字面落地就会打断折叠路径"的事故。**

## §11.1 红读数（分母 = `script==latin` **288 例 / 421 行**；`--leg b`）

| 腿 | 红行 | **帧红** | 结构红 | 说明 |
|---|---|---|---|---|
| **宽松档** | **133** | **133**（帧恒 0） | 0 | ⇒ **帧红 = 真值口径 133 逐位命中** |
| **严格档** | **3** | **0**（帧 **421/421 正确**） | 3 | 严格档帧在本语料上**是对的** |
| 严格档 + `--fresh-source` | **133** | 133 | 0 | ✅ **实证"缓存是帧的唯一来源"**（退化成同一形状） |
| 严格档 + **`--prefix 40`** | **421** | **421** | 0 | ✅ **实证 `cpFirst≠0` 时的分叉** |

- **真值口径**：`startChar > 0` = **latin 133**（`@default` 117 + `@tab0` 16）／**全域 179**。
  ⚠️ 主控给的 **138 是 `lineStartOffsetsDip` 那一列** ⇒ 帧口径应为 **133**（车道按 133 写预测、**实测 133**）。
- **车道自己的预测错了并如实登记**：它预测"严格档红 0"，实测 **3**（那 3 条**是结构红**，`帧 == cpFirst ≠ 真值`，全 `@tab0/@w40`）。

## §11.2 ⚠️⚠️ 车道**推翻**的一件**要命**的事：`_lineStart` 是**双用字段**

**主控已独立复核（逐行读源码）**：

| 行 | 代码 | 语义 |
|---|---|---|
| `shim:3044` | `int localFirst = firstTextSourceCharacterIndex - _lineStart;` | **绝对**段落系 |
| `shim:3621` | `_lineStart + visibleLen,   // 段落系索引` | **绝对** |
| `shim:3732` | `int lineEnd = _lineStart + _visibleLength;` | **绝对** |
| `shim:3612` | `char.IsWhiteSpace(_text[_lineStart + visibleLen - 1 - prefixTrailingWs])` | **相对**（索引进 `_text`） |
| `shim:3645` | `string prefix = _text.Substring(_lineStart, visibleLen);` | **相对** |
| `shim:3652` | `cp = _plan.Sub(_lineStart, _lineStart + visibleLen);` | **相对** |

⇒ **预登记 §3.4 字面的 `_lineStart = paragraphOrigin + range.Start` 会打断折叠路径**（`_text.Substring` / `_plan.Sub` / `_text[...]` 会**切错串或越界**），
而 `Collapse` **在真机消费路径上**（`PresentationFramework/MS/Internal/Text/Line.cs:165`）。
⇒ **推荐 Option 1（车道给，主控采纳）**：**新增 `_paragraphOrigin` 字段**，**`_lineStart` 的语义不变**，
只改 **3 个绝对消费者**（`GetTextBounds` / `GetIndexedGlyphRuns` / `_collapsedRange`）+ **折叠行透传**。
⇒ **Option 2（预登记字面）= 不安全，禁止落地。**

**主控的另一处引注更正**：预登记 §3.4 写"真机断言含 `TextBlock.cs:2314`" —— **错**：那是 **`if (Invariant.Strict)`**（一个**守卫**，不是断言）。
**真的断言只有 3 处**（**主控已独立复核**，`Invariant.Assert(textBounds.Count > 0)`）：
`PresentationFramework/MS/Internal/Text/Line.cs:173`、`…/MS/Internal/documents/TextBoxLine.cs:260`、`…/MS/Internal/PtsHost/Line.cs:507`。

## §11.3 对主控口径插话的回答（都是读数，不是推理）
1. **`cpFirst` 不恒 0**：客户端就是真机宿主形状（`index` 从 0 按 `Length` 累加）⇒ 第 k 行 `cpFirst_k`；实测 `truth − cpFirst` 分布 = **`{0: 418, 1: 3}`**。
2. **判据的正确形式 = A（`我方帧 == corpus.startChar`）**，**不是** B（`帧 − cpFirst == startChar`）。
   判别读数在 **leg A**：**A 判 114 红，B 判 133 红** ⇒ **B 会把 19 行"帧本来是对的"（上游 `SimpleTextLine` 快路径）误判成红**。
3. **`cpFirst≠0` 的必做读数已做**（`--prefix 40`）：**`cpFirst − 帧 == 40` 在 421/421 行成立**；且**帧值分布与不加 prefix 时逐位相同**（`{0:288,1:69,2:47,3:17}`）⇒ **帧 = 收集串内部的相对偏移，与段落绝对原点无关**。
   ⇒ **主控的源码自证成立**（`ParaCache` 走绝对系、`_lineStart` 走相对系，两者相差 `cpFirst`）。
   ⇒ **消费者可见后果**：真机读法 `GetTextBounds(cpFirst, 1)` **在 421/421 行读到空**（不加 prefix 时 **0/421**）⇒ **严格档一样中招**。

## §11.4 逐成员预测（修法 = Option 1）
- **受影响**：`GetTextBounds`（修后 **133 帧红 → 0**）、`GetIndexedGlyphRuns`（+origin）、`GetTextCollapsedRanges`、`BuildCollapsedLine`（折后帧 = 原行帧）。
- **不受影响**：`Collapse` **几何**、`Length`/`Width`/`WidthIncludingTrailingWhitespace`/`NewlineLength`/`TrailingWhitespaceLength`/`Height`/`Baseline`/`HasOverflowed`/`GetTextRunSpans`/`Draw`、以及 **`Start`**。
  ⚠️ **后四项未取读数 = `NOINFO`**（修法未施加 ⇒ 不许写成"已证不变"）。

## §11.5 本件另登记的三条欠账（**都要在 `#23` 里处置**）
1. **未登记红**：133 帧红里 **117 条在 `@default` 族**（**不在** `known-red` 登记范围内）⇒ **需要主控裁决**（登记 or 先修）。
2. **⭐ 既有臂结构性看不见的一条**：**60 例（全 `@tab0`）我方分行多于真机**（**多 101 行、无真值对应**）——
   而既有臂**按真值数组迭代** ⇒ **这类"多出来的行"永远不会被判**。⇒ 这是"**判据按真值迭代 ⇒ 看不见多出来的东西**"的一个**新机制**（与 `D-G1` 同族，但更隐蔽）。
3. **缺陷不完全"响亮"**：133 帧错里**只 55 行读到空**、**78 行读到"别人"的边界**（**静默错**）。⇒ "读空"与"读错"是两种后果，判据必须两种都覆盖。

## §11.6 落地裁定（主控）
- **`D-T6-b` 的修法可以落地，但必须按 Option 1**（新增 `_paragraphOrigin`），**禁止**用预登记 §3.4 的字面形式。
- **世代成本 = 一笔**（`build/shims/**` 变 ⇒ 五臂重取 + `known-red.json` 重钉 + 两极化重做 + `inputs_fp` 变）。
- **与 `D-F2` 合并**（三个"只写不读"的计数器进 `SummaryFragment()`，见 §9.3；⚠️ **必须同时处理 `shim:1346-1347` 的 `PlanCalls==0` 提前返回**，否则照样不打印）。
- **本波不落地**（原因见 §3.6：本波 W22B 已在动臂仪器，两件同趟会让臂日志的变化**归因不清**）。
- **车道新建件零位移**：九位 **9/9**、`BRIDGE_SRC_FP=b6acdba4f01599d8`、`inputs_fp=a2b74537…` 全同（`tests/` 在指纹覆盖面里是 prune）。


---

# §12 收官（`#22` 波完成记录，主控，2026-09-16 20:3x）

## §12.1 本波定性与一条最重要的结论
**这是一趟"零位移"波** —— 四件工作动的全是**仪器与登记**，**产品件一个字节未动**。
⇒ **`#21` 仍是当前冻结基线，未重冻。**
⇒ **本波的价值不在产物，而在判据**：它把四条"看起来有判据、其实判不了"的东西**逐个查清**，其中**一条推翻了主控预登记的修法字面（否则会打断折叠路径）**。

## §12.2 位移表：**预测 = 实测 = 零位移**（§5 逐条兑现）

| 位 | 预测 | 实测 | 判定 |
|---|---|---|---|
| 九位（9 位） | 逐位不变 | **9/9 逐位不变** | ✅ |
| `BRIDGE_SRC_FP` | 不变 | `b6acdba4f01599d8` 未变 | ✅ |
| `inputs_fp` | 不变 | `a2b74537427ecc4a987edbe52a59c5d01d4817d54de58f445833c33dfb0e78e0` 未变（**现场用 `close-wave.sh` 的 `fp_inputs()` 复算**） | ✅ |
| 门禁 | 仍 `PASS`、`generation=#21 tree_gen=same` | `TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#21 tree_gen=same saved_shim=76089e1de586ac91`、`GATE_REASON=all-as-registered`、`rc=0` | ✅ |
| `verify-all` | 同前（11 步） | **rc=0 / 11 步 / 871 通过 2 跳过**（第 [4] 五臂 ✅、第 [5] `Start` 列 ✅） | ✅ |
| 应用门禁 | 同前 | **未重跑**（`pc`/`bridge`/`pf` 一个字节未动 ⇒ 读数不可能变；**如实记为"未取读数"而非"已证同前"**） | ⚠️ **NOINFO** |

**表外位移：无。**

## §12.3 四件的收官读数（逐条）

| 件 | 结论 | 读数锚 |
|---|---|---|
| **P1 `D-R3` ③** | ① **改判「正常路径回归锁」**（修前 `NOINFO method-absent` ⇒ **测不到**，不是没测过）；④ **改判「缺件不变式锁」**（两侧逐字相同）；**(a) 两极真实**（修前**硬失败**） | `W22A-report.md 72586d4a85883022`；§8 |
| **P2 `D-G1`** | **补齐**：新列修后绿（`红=0 绿=421 判定行=421 NOINFO=194`）、**反极性红 138/88**、**"只新增"机器证**（`diff` 0 条 `<`、剔新增行后 `cmp` 逐字节相同） | `W22B-report.md c98c71f106fec8d7`；§10 |
| **P3 `D-T6-b`** | **判据落成读数**：宽松档 **133** 红、严格档帧 **421/421 正确**、`--fresh-source` **133**、`--prefix 40` **421/421**；**推翻修法字面**（`_lineStart` 双用） | `W22C-report.md 93d66fa348ddbb3a`；§11 |
| **P4 只读** | **`D-T5` 升为下一波第 1**（进程级 abort，家族更宽）；`D-A2` = **34/49 份**未判副本、**判据今天就红**；`D-F2` = `+3`/`+4` 行含顺序陷阱 | `W22D-report.md 44461001f9d10eaa`；§9 |

## §12.4 收官清单核对（对 §7）

- [x] **P1**：修前/修后两树逐条读数 + 探针与四份件的 sha16；①/④/(a)/(b) 四条各自裁定（§8.1）
- [x] **P2**：`CoverageProbe` before/after（`Program.cs` + 产物 dll）+ 新列能决定红（反极性 138）+ 既有判据行**逐字不动**（`diff` 0 条 `<`）+ 四支无关臂日志未动 + 门禁与九位/`inputs_fp` 复算（§10）
- [x] **P3**：判据 + **红读数**（两条腿 + 两个旋钮）+ 逐成员爆炸半径 + 落地裁定（§11）
- [x] **P4**：副本盲区逐份表 + `D-T5` 裁定 + `D-F2` 精确改法（§9）
- [x] 九位 / `inputs_fp` / 门禁 / `verify-all` 逐项复算并与 `#21` 对照（§12.2）
- [x] 文档：`CURRENT-STATE.md`（`#22` 复核块 + **纪律 44/45**）、`handoff.md`（`#22` 完整记录）、`KNOWN-DEFECTS.md`（`D-T5` 补"传应用层"+**家族欠宽**、`D-T6-b` 补判据+双用陷阱+三条欠账）、`ACCEPTANCE-BASELINE.md`（**零位移注记**）、本文件 §8–§12
- [x] **不重冻**（零位移 ⇒ `#21` 仍是当前基线）

## §12.5 本波**未做**（不许当绿）

1. **`D-T6-b` 的修法未落地**（按 §3.6 的裁定，也与"别与臂仪器变更同趟"有关）；且落地**必须用 Option 1**。
2. **`D-T5` 没有任何判据**（只有草案）；冻树里 0 载体 ⇒ **今天不会红**。
3. **117 条 `@default` 族的帧红 = 未登记红**（需要主控裁决"先登记还是先修"）。
4. **60 例多分行**（全 `@tab0`）**结构性不可见** ⇒ **没有任何判据盯它**（纪律 45）。
5. **`D-A2` 的判据未落地**（草案 + 实测反极性已有；`ITEMS` 与 `SCAN_ROOTS` 一个字节未改）。
6. **`hasOverflowed`（22 行 True）仍无判据**。
7. **应用门禁本波未重跑**（§12.2 末行，如实记 `NOINFO`）。
8. **`cpFirst≠0` 那一半的修法**（`GetTextBounds` 空表 vs 真机**夹取**）**未动**：真机 3 处 `Invariant.Assert(textBounds.Count > 0)` 的位置已核实，但**我们没有对应判据**。

## §12.6 下一波（`#23`）建议（按价值，**含本波产出的三条欠账**）

1. **`D-T5` 的判据**（进程级 abort；先判据后修法；`PcLineOracle` 新造 `TextEndOfSegment(1)` + `TextHidden(1)` 变体，两极化已备）。
2. **`D-T6-b`（**Option 1**）+ `D-F2` 合并** ⇒ **只付一笔世代成本**（三个计数器进 `SummaryFragment()`，须同时处理 `PcLineCalls==0` 早退）。
   落地后**同一趟**取：`GetTextBounds` 的 **133 帧红 → 0**、折叠行帧、以及**本波欠账 ③（静默错 78 行）是否随之消解**。
3. **`D-A2`**：`ITEMS` 补 `PresentationCore.dll` + `SCAN_ROOTS` 补 `$REPO/tools`（**判据今天就红 ⇒ 需先定"17 份旧件是登记还是刷新"的口径**）。
4. **`hasOverflowed`（22 行）补判据**（`D-O1` 刚动过它 ⇒ 最该补的一类）；**同时把"集合基数相等"补进各臂**（纪律 45 的落地：**断言行数相等**，让"60 例多分行"变成可红）。
5. **`#22` 欠账 ①**：117 条 `@default` 帧红裁决。

## §12.7 元结论（本波三条）
1. **"判据存在"有三种强度，本波又抓到两个新的第 ② 种**：`CoverageProbe` 不看 `Start`（已补）、以及 **`_lineStart` 的绝对/相对双用**（**同一个字段，两个消费群用两种语义** ⇒ 只读一个消费群就会写错修法）。
2. **"按真值数组迭代"的判据，结构性看不见"多出来的东西"**（60 例多 101 行）—— 这是比"不看某个字段"更隐蔽的一层（**射程由真值的形状决定**）。
3. **主控自己的三处引注/口径错误**（`D-G1` 字段清单、`D-T6-b` 预测数、`TextBlock.cs:2314`）**全部由车道用实测打掉** —— 与 `#21` 同形：**预登记不是免责，是待证伪的假设清单**。

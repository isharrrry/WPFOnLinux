# `D-T2` boundary audit（`:309` min/max asymmetry + "no arm consumes `minWidth`"）

> **lane = TDT2**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **结论先说**：登记里那条"`maxWidth` 含 indent 而 `minWidth` 不含"**在本棵树上不成立**（它只存在于一个**从未编译通过**的草稿态，随后被 T1c 自己以 CS0103 为由**撤掉**）；但 `:309` 处**确实**有一处 min/max 不对称，只是量不是 indent，而是 **`TextModifier` 作用域参数** ⇒ 判 **DEFECT（不是照抄真机）**。第二条"没有臂消费 `minWidth`"**成立**，而且比登记写的更强：**没有任何一支臂驱动 PC 的 `TextFormatter`**（五支臂全部直接调 shim 工厂）。
>
> **本报告是只读审计**：`build/MilBridge/**` 里只写了本文件（TDT2 写域由主控派单显式授予，其余一律只读）。
> **未运行任何仪器**（五支臂、`run.sh`、门禁、`verify-all` 一次都没跑）⇒ **不可能扰动树**。前后两次实读 PC 权威产物 **`c0763fc10173e7ff`** 逐位相同（§5）。
> 全部读数、命令、`sha16`/字节数/mtime 见 §5；引用行号一律给"文件 + 行号 + 逐字原文"，且**不孤立引用**（都在上下文里读过）。

---

## 1. 逐条判决（一行）

| 声明 | 判决 | 一句话理由 |
|---|---|---|
| **Claim 1**：`D-T2` boundary = "`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:309` 的 min/max 不对称"，且形态为"`ParagraphIndent ≠ 0` 时 **maxWidth 含 indent 而 minWidth 不含**" | **PARTLY CONFIRMED / 登记描述 REFUTED** | **不对称确实存在**于 `:309`（min 探针）相对 `:302`（max 探针）；但**量是 `TextModifier` 作用域参数，不是 indent**。indent 那一半：全文件 `indentDip` 只出现 **1 次**（`:256`），min/max 两个探针**都没有**它 ⇒ "max 含 / min 不含"在当前树上是**假陈述**；它只存在于 T1c 那个被 CS0103 打回并**主动撤回**的草稿（`T1c-report.md:2765`）。**不对称本身判 DEFECT**（真机 min/max 与 `FormatLine` 同一管线，没有 min/max 专属偏差）。 |
| **Claim 2**："no arm consumes `minWidth`" | **CONFIRMED（并已加强）** | 13 支臂宿主逐个 `grep` ⇒ **全 0 命中**；`minWidth`/`maxWidth` **在真机 oracle 里根本不存在**（`tests/parity/windows/**/*.json` 30 份逐个键扫描，无 min/max 段落宽输出字段；`maxWidth` 那个键是**输入**容器宽）。更强的一条：**五支臂全部直接调 `HbTextLineFactory.FormatParagraph`**，**没有任何一支走 PC 的 `TextFormatter`** ⇒ `FormatMinMaxParagraphWidth` 这条链在**本地零覆盖**，`FormattedText.MinWidth`（PC 内唯一消费者）也是零覆盖。 |

**额外发现（不在两问之内，但对"冻 `pc`"这件事是硬信号，见 §3.4）**：刚落的 `D-T2` PC 半把 **`settings.Pap.ParagraphIndent` 接到了 shim 的 `indentDip` 槽**（`TextFormatterImp.Linux.cs:575` → `:256`），而 shim 的 `indentDip` 语义是 **`TextParagraphProperties.Indent`**；**`Pap.Indent` 被整条丢弃**，而真正该收 `ParagraphIndent` 的 `paragraphIndentDip` **从未被传**。**五支臂都看不见它**（它们绕过 PC；b34 语料 614/614 例 `Indent = paragraphIndent = 0`）⇒ 这是"注册了但没生效"族的一个**新实例**，且**现有读数对它全盲**。

---

## 2. Claim 1：`:309` min/max 不对称

### 2.1 `:309` 到底指哪个文件的哪一行（先把歧义钉死）

`:309` 这个坐标在本仓**同时**落在三处，必须写清楚（否则引用会串）：

| 出处 | `:309` 是什么 | 依据（逐字） |
|---|---|---|
| **上游** `upstream/.../TextFormatterImp.cs` | `FormatMinMaxParagraphWidth` 里那条 **LS 回退**的 `new TextMetrics.FullTextLine(` | applier 顶注 `patch-presentationcore-textline-fallback.py:23`：`第二个同类站点：`TextFormatterImp.cs:309`（`FormatMinMaxParagraphWidth`）⇒ 现场读上游 `:309` 逐字是 `TextMetrics.FullTextLine line = new TextMetrics.FullTextLine(` |
| **生成物** `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | **`minWidth` 探针**那次 `FormatParagraph(` 调用 | 现场实读 `:308-311`（§2.2） |
| **应用器** `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` | 同上一段的**原文**，在 `:452`（偏移 −143，字节级证明见 §2.3） | `:451-454` |

登记（`docs/CURRENT-STATE.md:153`）的措辞是"`:309` 那处 `TryMinMaxParagraphWidth` 的 `minWidth` 探针" ⇒ **它指生成物 `:309`**。本报告此后一律用"生成物 `:309`"，并在引用原文时同时给应用器行号。

> 顺带一条**登记口径的技术性更正**（不是纠错、是防串）：`:309` 在上游**恰好**是 LS 站点行号，而在生成物里**恰好**是 min 探针行号 —— 两者**同号不同物**，纯属巧合（生成物 = 上游逐字 + 两处注入 + 头注释）。以后凡写 `:309` 必须带文件名。

### 2.2 生成物原文（含上下文，不孤立引用）

`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（`sha16 f86198dfdd349332`，51,594 B，2026-09-15 17:10:55），宽松兜底类的整个 min/max 函数：

```
273:        /// <summary>宽松版 `TryMinMaxParagraphWidth`：与 shim 同构（宽=∞ 取 Max，宽=0 取 Min）。</summary>
274:        internal static bool TryMinMaxParagraphWidth(TextSource textSource, double pixelsPerDip,
275:                                                     out double minWidth, out double maxWidth)
...
300:                int c1, c2;
301:                System.Collections.Generic.List<WpfLinux.Shims.PresentationCore.HbTextLine> wide =
302:                    WpfLinux.Shims.PresentationCore.HbTextLineFactory.FormatParagraph(
303:                        text, fontPath, props.FontRenderingEmSize, double.MaxValue, gt, (float)pixelsPerDip,
304:                        props, false, false, 0, out c1,
305:                            modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2);
306:                for (int i = 0; i < wide.Count; ++i) if (wide[i].Width > maxWidth) maxWidth = wide[i].Width;
307:
308:                System.Collections.Generic.List<WpfLinux.Shims.PresentationCore.HbTextLine> narrow =
309:                    WpfLinux.Shims.PresentationCore.HbTextLineFactory.FormatParagraph(
310:                        text, fontPath, props.FontRenderingEmSize, 0.0, gt, (float)pixelsPerDip,
311:                        props, false, false, 0, out c2);
312:                for (int i = 0; i < narrow.Count; ++i) if (narrow[i].Width > minWidth) minWidth = narrow[i].Width;
```

两个分支对照（**这就是"不对称"的全部内容**）：

| 量 | max 分支（宽=∞） | min 分支（宽=0） | 差 |
|---|---|---|---|
| 宽度实参 | `double.MaxValue`（`:303`） | `0.0`（`:310`） | **intentional（口径本身）** |
| 聚合方向 | `> maxWidth ⇒ maxWidth = …`（`:306`） | `> minWidth ⇒ minWidth = …`（`:312`） | **同一方向 `>`，无 min/max 反转** |
| `modifierOpenIndex` / `modifierCloseIndex` | **传了**（`:305`：`modOpen2` / `modClose2`） | **没传**（`:311` 到 `);` 结束） | **← 不对称在此** |
| `modifierScopeEnd` | 没传（默认 `-1`） | 没传 | 同样缺（且默认值语义是"到段末"） |
| `indentDip` | **没传**（默认 `0`） | **没传**（默认 `0`） | **对称** |
| `paragraphIndentDip` | 没传（默认 `0`） | 没传（默认 `0`） | **对称** |

**"clamped with max where min is used"这一形态在本函数里不存在**：`:306` 与 `:312` 都用 `>`（都在取"行宽的极大值"）。`:306` 取"单行长段落的最宽行"= `MaxWidth`；`:312` 取"宽=0 强制断后每行各自的最宽行"= 对 **MinWidth** 的**代理**（真机的 `MinWidth` 不是"逐行宽的极大值"，见 §2.5 —— 那是**另一个**待核的口径差，且**今天不可测**）。所以"不对称"若按字面理解成"某处用 `max` 而该用 `min`" ⇒ **不成立**；存在的只是**可选具名实参的缺项**。

### 2.3 应用器侧出处（字节级证明"生成物的这段 = 应用器里的那段"）

应用器同段（`patch-presentationcore-textline-fallback.py`，`sha16 07dc7627f609e031`，37,625 B，2026-09-15 17:10:55）：

```
443:                int c1, c2;
444:                System.Collections.Generic.List<WpfLinux.Shims.PresentationCore.HbTextLine> wide =
445:                    WpfLinux.Shims.PresentationCore.HbTextLineFactory.FormatParagraph(
446:                        text, fontPath, props.FontRenderingEmSize, double.MaxValue, gt, (float)pixelsPerDip,
447:                        props, false, false, 0, out c1,
448:                            modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2);
449:                for (int i = 0; i < wide.Count; ++i) if (wide[i].Width > maxWidth) maxWidth = wide[i].Width;
450:
451:                System.Collections.Generic.List<WpfLinux.Shims.PresentationCore.HbTextLine> narrow =
452:                    WpfLinux.Shims.PresentationCore.HbTextLineFactory.FormatParagraph(
453:                        text, fontPath, props.FontRenderingEmSize, 0.0, gt, (float)pixelsPerDip,
454:                        props, false, false, 0, out c2);
455:                for (int i = 0; i < narrow.Count; ++i) if (narrow[i].Width > minWidth) minWidth = narrow[i].Width;
```

映射与证明（可复算）：

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
sed -n '300,312p' build/PresentationCore.Linux/TextFormatterImp.Linux.cs > /tmp/t2_gen_region.txt
sed -n '443,455p' src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py > /tmp/t2_app_region.txt
diff /tmp/t2_gen_region.txt /tmp/t2_app_region.txt && echo REGION_IDENTICAL
sha256sum /tmp/t2_gen_region.txt /tmp/t2_app_region.txt
```
逐字输出：`REGION_IDENTICAL`，两份 `sha256 = 24fe0d9e9d766fd835e8da5e9e91fd32738bac3617b4017253382d5270bac385`。
⇒ 行号映射 **生成物 L ↔ 应用器 L−143**：生成物 `:302`↔应用器 `:445`、`:305`↔`:448`、`:309`↔`:452`、`:311`↔`:454`。**要改 `:309` 就得改应用器的 `:451-454`**（本报告只给文本，不落地，纪律：写域外）。

### 2.4 登记那半（indent）为什么是**假**的 —— 三条硬读数

**(a) 全文件 `indentDip` 只有一处。**
```bash
grep -n 'indentDip' build/PresentationCore.Linux/TextFormatterImp.Linux.cs
```
输出（唯一命中）：
```
256:                            modifierOpenIndex: modOpen, modifierCloseIndex: modClose, indentDip: paragraphIndent);
```
⇒ min/max 两个探针（`:302-305` / `:309-311`）**都不含** `indentDip`，"max 含而 min 不含"**不成立**。

**(b) 两个历史快照里也没有**（排除"曾经有、被谁删了"的猜测）：
```bash
grep -n 'indentDip: paragraphIndent\|modifierOpenIndex: modOpen2' \
  /home/links-dev/t1c-16-backup/TextFormatterImp.Linux.cs
```
- `/home/links-dev/t1c-16-backup/TextFormatterImp.Linux.cs`（`sha16 5dedc21f5f372c78`，51,491 B，2026-09-14 22:14:58）= `#16` 之前的生成物 ⇒ **唯一命中 `:305`，形态是 `modifierOpenIndex: modOpen2, modifierCloseIndex: modClose2);`**（即：**modifier 参数早就有、indentDip 从来没有**）。
- `/home/links-dev/t1c-13-backup-221419/TextFormatterImp.Linux.cs`（`sha16 569fefc718340086`，49,801 B，2026-09-11 23:07:42）= `#13` 之前 ⇒ **该段两个探针一个具名实参都没有**（`minmax` 区里 `modifierOpenIndex` 零命中）⇒ **modifier 参数是 #13～09-14 之间加的，且只加到了 max 分支**。

**(c) 那条 indent 曾经以"草稿态"存在过，且当场被 CS0103 打回、随后被撤**（一手证据，出自己方车道）：
- `build/MilBridge/T1c-report.md`（`sha16 04422985ebba1f58`，272,131 B）`:2764-2765`：
  > `- **留**：A TextFormatterImp.Linux.cs:230-231 签名加 double paragraphIndent = 0；B :253 出行那处 FormatParagraph(…, indentDip: paragraphIndent)；E **:575** 调用点传 settings.Pap.ParagraphIndent。`
  > `- **撤**：C :305（TryMinMaxParagraphWidth 的 maxWidth 探针，作用域内无 paragraphIndent ⇒ CS0103 根因）；D :559（我错误地把同一补丁串套到另一个类的同名方法上 ⇒ CS1739 根因）。`
- 同一现场在 `docs/CURRENT-STATE.md:233` 逐字记着：`TextFormatterImp.Linux.cs(305,46) … CS1739` ＋ `(305,100) error CS0103（在 TryMinMaxParagraphWidth 里引用了该作用域不存在 的 paragraphIndent）` ⇒ **那个"max 探针带 indent"的形态从未进入任何可编译的树，也没有进过任何读数**。
- `build/MilBridge/T1c-report.md:2777` 的自检计数与现树一致：`grep -cF ParagraphIndent` = **1**｜`indentDip: paragraphIndent` = **1**（现场复核：现树 `grep -c 'indentDip: paragraphIndent'` = 1，正是 `:256`）。

⇒ **判决**：`docs/CURRENT-STATE.md:153` 与 `docs/WAVE16-PREREGISTRATION.md:79`（":305（min-width 探针）维持不接（五臂不消费 minWidth，已成结论）"）里那条"indent 不对称"**是陈旧登记**，应改为"**min/max 两探针都不接 indent（对称缺项）**，真正的缺项是 `Indent` 从未进入 min/max 路径"。

### 2.5 剩下来的真不对称：`TextModifier` 作用域参数 —— **判 DEFECT**

**机制**（逐字、含上下文）：

1. 缺项本身：`modifierOpenIndex`/`modifierCloseIndex` 只给了 max 分支（生成物 `:305` vs `:311`）。
2. shim 侧"缺省的后果"是**已知错的跨度**：`build/shims/PresentationCore.HbTextLine.cs`（`sha16 bc04c05ab6d8d82a`，275,765 B，2026-09-15 18:25:25）`FormatParagraph` 签名与消费点：
```
3859:            int modifierOpenIndex = -1, int modifierScopeEnd = -1, int modifierCloseIndex = -1,
...
1729:            if (modifierOpenIndex >= 0)
1730:            {
1731:                int kl = Math.Max(0, modifierOpenIndex - start);
1732:                int kh = (modifierScopeEnd < 0 ? len : Math.Min(modifierScopeEnd - start, len));
```
   即：**`modifierScopeEnd = -1` ⇒ 零宽跨度 = `[open, 段末)`**。shim 自己在 `:3855-3858` 把这个语义标成**实测错的**：
```
3855:            //      `modifierScopeEnd`（半开；`-1` ⇒ 到段末）。它**不等于** `closeIndex`：
3857:            //      b34 语料 `open=6, close=-1, 覆盖终点=45`（`cases.json` 的 `modifierEnd=45`），
3858:            //      若拿 `close<0` 当"到段末"，会把 [6,63) 全零宽 ⇒ 实测 `w=43.59`，而真值 `156.9167`
```
   ⇒ **max 分支传了 `open`+`close` 但没传 `scopeEnd`** ⇒ 在 PC 这条路上，max 走的是"`open` → 段末全零宽"（shim 自述 `w=43.59` 那一支）；**min 分支连 `open` 都不传** ⇒ **完整宽度**。**两个分支各自都错，而且错法不同**。
3. 可达到性（这条链不是死的）：严格 shim 对非 `TextCharacters` 的 run **原样 bail**，`TextModifier` 正是这类 run：
```
4442:                TextCharacters tc = run as TextCharacters;
...
4455:                Bail(ref BailRunType, "run 类型 " + run.GetType().Name + " 不支持");
```
   而 `HbTextFallback.TryMinMaxParagraphWidth`（shim `:4572-4597`）用的就是同一套 `TryBuildPlan` ⇒ 含 `TextModifier` 的段落**必然**落到 PC 的 `WpfLinuxLenientTextFallback.TryMinMaxParagraphWidth`（生成物 `:652-668` 的回落链第二路）：
```
652:            if (WpfLinux.Shims.PresentationCore.HbTextFallback.TryMinMaxParagraphWidth(
...
664:            if (WpfLinuxLenientTextFallback.TryMinMaxParagraphWidth(textSource, textSource.PixelsPerDip,
```
   ⇒ `:309` 的不对称**在"含 `TextModifier` 的段落"上是活路径**。

**与真机比（reference，逐字）** —— 真机 min/max **没有**任何"与 `FormatLine` 不同的管线"：

```
upstream/.../TextFormatting/TextFormatterImp.cs:204-220   （FormatLineInternal）
            FormatSettings settings = PrepareFormatSettings(
                textSource, firstCharIndex, paragraphWidth, paragraphProperties, previousLineBreak, textRunCache,
                (lineLength != 0),  // Do optimal break if break is given
                true,    // isSingleLineFormatting
                _textFormattingMode );
upstream/.../TextFormatting/TextFormatterImp.cs:295-315   （FormatMinMaxParagraphWidth）
            // prepare formatting settings
            FormatSettings settings = PrepareFormatSettings(
                textSource, firstCharIndex,
                0,      // infinite paragraphWidth
                paragraphProperties, null, textRunCache,
                false,  // optimalBreak
                true,   // isSingleLineFormatting
                _textFormattingMode );
            // create specialized line specifically for min/max calculation
            TextMetrics.FullTextLine line = new TextMetrics.FullTextLine(
                settings, firstCharIndex, 0, 0, (LineFlags.KeepState | LineFlags.MinMax) );
            MinMaxParagraphWidth minMax = new MinMaxParagraphWidth(line.MinWidth, line.Width);
```
两者**同一个 `PrepareFormatSettings`、同一份 `settings`、同一个 `TextRunCache`**；`TextModifier` 作用域是在**run 属性管线**里生效的（`TextProperties.cs:245-251`：`if (_modifierScope != null) _properties = _modifierScope.ModifyProperties(_textRun.Properties);`，由 `TextStore.cs:427` 维护的 `_modifierScope` 栈驱动）⇒ 真机的 min 与 max **不可能**一个带作用域、一个不带。

⇒ **判决 `DEFECT`（defect, not a deliberate mirror）**。理由两条、都可复算：
- ① 真机没有 min/max 专属偏差（上面两段 `PrepareFormatSettings` 逐字同参数）；
- ② 本项目自己已经把"作用域内字符零宽"用真机真值钉死过（`#13`：`M_modifier_winf 行#0` 由 `439.1360 → 156.9280`，真值 `156.9167`；`docs/CURRENT-STATE.md:34`）⇒ 既然**行**路径的口径是"零宽"，**min/max 也该是同一口径**；现在一条零宽（且跨度错）、一条不零宽，两条都不能自称对齐真机。

**可观测行为差（worked numeric example，给出输入 / 两个候选结果 / 真机应给哪个）**

用一条**合法且最小**的输入（构造性，不是从语料里挑的）：
- `TextSource` = 一段 `TextModifier` run 在**下标 0**、其后是 `"WWWW"`（em = 24 DIP，Liberation Sans 本地替身）；
- 于是 `CollectLenient` 记下 `modifierOpenIndex = 0`、`modifierCloseIndex = -1`（无 `TextEndOfSegment`），`modifierScopeEnd` 未给 ⇒ **跨度 = `[0, len)` = 全段**。

| 分支 | 输入给 `FormatParagraph` 的东西 | 零宽跨度 | 该分支读出的值 |
|---|---|---|---|
| **max**（`:302-305`） | `paragraphWidth = double.MaxValue`，`modifierOpenIndex: 0, modifierCloseIndex: -1`，`scopeEnd = -1`(默认) | `[0, len)` ⇒ **全段零宽** | `maxWidth = 0.00`（4 个 `W` 的 advance 全被置零） |
| **min**（`:309-311`） | `paragraphWidth = 0.0`，**不给任何 modifier 参数** | 无（`open = -1`） | `minWidth = 单个最宽字符的 advance`（`W`@em24 ⇒ 约 22 DIP 量级；精确值由仪器给） |
| **真机**（reference） | 同一条段落在同一个 `settings` 下算 `line.MinWidth` / `line.Width`（`TextFormatterImp.cs:309-319`） | 作用域**两侧一致**生效 | `MinWidth ≤ MaxWidth`，且**都不是这两支**：`MaxWidth` = 整段一行宽（含 `Indent`，不含 `ParagraphIndent`，见 §3.3 的实测量级），`MinWidth = _textMinWidthAtTrailing + _textStart`（`FullTextLine.cs:2573-2576`） |

⇒ **我方这条链会给出 `MinWidth (≈22) > MaxWidth (0.00)`**，而真机的契约（`TextFormatterImp.cs:257-258` 逐字："Client to ask for the **possible smallest and largest** paragraph width that can fully contain the passing text content"）**排除了 `min > max`**。**这是一个应用侧可观测的契约违反**，不是"内部口径之争"。**标注**：上表的 `0.00` / `≈22` 是**推演值（predicted, not measured）**——本报告没跑任何仪器；`W`@em24 的精确 advance 与 `MinWidth` 的真机值都要靠 §4 的新臂给出。**"两个分支的行为不同"这一条是 proven（代码级）**；**"差多少个 DIP"是 not measured**。

### 2.6 顺带核掉的两条相邻口径（写清楚，免得后人引错）

- **`:306` / `:312` 的聚合方向没问题**：max/min 两边都取"行宽极大值"。真机 `MinWidth` 的形态**不是**这个（`FullTextLine.cs:2573-2576`：`MinWidth = IdealToReal(_textMinWidthAtTrailing + _metrics._textStart)`），所以 `:312` 是**代理式近似**；它是否与真机逐位相等 ⇒ **今天不可测**（oracle 里没有 min 真值，§3）。**不许**把它读成"已对齐"。
- **`modifierScopeEnd` 在 PC 这条路线上从来没被传过**（`:256` 的行路径也一样：只有 `modifierOpenIndex` + `modifierCloseIndex`）⇒ 这是**同一个缺项**在两条路径上各出现一次（`#13` 起的既有形态，`t1c-16-backup` 已证）。**min/max 的不对称**与**scopeEnd 缺项**要分开登记（前者是"两分支不一致"，后者是"两分支都用了错的跨度"）。

---

## 3. Claim 2：`minWidth` 有没有被任何臂消费

### 3.1 我搜了什么（文件 + 模式，逐条可复算）

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux

# ① 13 支臂宿主（CoverageProbe/HbTextLineParity/TextLineProto/ContractProbe/FallbackCriteria 之外的其余宿主…）
for f in $(find build/MilBridge/tests -maxdepth 2 -name Program.cs | sort); do
  printf '%s  %s\n' "$(grep -c -i 'MinMaxParagraphWidth\|minWidth\|MaxParagraphWidth\|FormatMinMax' "$f")" "$f"; done

# ② 整棵自有树（排除 bin/obj/refs/staging 存档）：**放宽到大小写不敏感**，避免漏掉局部变量/输入字段
grep -rn -i --include=*.cs -E 'minwidth|maxwidth|minmaxparagraph' build src samples tests \
 | grep -v '/bin/\|/obj/\|/refs/\|/staging/' | cut -d: -f1 | sort | uniq -c
# ②b 非 .cs 宿主（py/sh/ps1）
grep -rn -i -E 'FormatMinMaxParagraphWidth|MinMaxParagraphWidth' --include=*.py --include=*.sh --include=*.ps1 \
 build src samples tests | grep -v '/bin/\|/obj/\|/refs/\|/staging/' | cut -d: -f1 | sort | uniq -c

# ③ 真机 oracle 场景数据（30 份 json，逐个键扫 min|max）
python3 - <<'EOF'
import json,glob,re,os
pat=re.compile(r'min|max',re.I); keys=set(); n=0
for p in sorted(glob.glob('tests/parity/windows/**/*.json',recursive=True)):
    n+=1
    d=json.load(open(p,encoding='utf-8'))
    def walk(o,depth=0):
        if depth>3: return
        if isinstance(o,dict):
            for k,v in o.items():
                if pat.search(k): keys.add((os.path.basename(p),k))
                walk(v,depth+1)
        elif isinstance(o,list) and o and isinstance(o[0],(dict,list)): walk(o[0],depth+1)
    walk(d)
print('json files scanned:',n)
for f,k in sorted(keys): print('  ',f,'::',k)
EOF

# ④ 臂日志 + 在册红表 + 门禁工具：有没有 min/max 读数位
grep -a -c -i 'minwidth\|maxwidth\|minmax' build/MilBridge/arm-logs/*.log
grep -c -i 'minwidth\|minmax' build/MilBridge/known-red.json
grep -n -i 'minwidth\|minmax' build/MilBridge/tools/tline-gate.sh

# ⑤ 谁走 PC 的 TextFormatter（自有 Linux 侧测试/样例）
grep -rn --include=*.cs -E 'TextFormatter|TryFormatLine|TryMinMaxParagraphWidth|FormatParagraph' tests | grep -v '/bin/\|/obj/\|tests/parity/' | wc -l
grep -rn --include=*.cs -E 'TextFormatter|TryFormatLine|FormatParagraph|FormattedText' samples | grep -v '/bin/\|/obj/' | wc -l
```

### 3.2 我找到了什么（逐字输出）

**① 13 支臂宿主：全 0。**
```
0  build/MilBridge/tests/BboxProbe/Program.cs
0  build/MilBridge/tests/ClosedLoop/Program.cs
0  build/MilBridge/tests/CompositeFontProbe/Program.cs
0  build/MilBridge/tests/ContractProbe/Program.cs
0  build/MilBridge/tests/CoverageProbe/Program.cs
0  build/MilBridge/tests/FamilyCoverageSelfTest/Program.cs
0  build/MilBridge/tests/HbTextLineParity/Program.cs
0  build/MilBridge/tests/IcuBreakParity/Program.cs
0  build/MilBridge/tests/InputTraceProbe/Program.cs
0  build/MilBridge/tests/LsProbe/Program.cs
0  build/MilBridge/tests/T2eLineHeight/Program.cs
0  build/MilBridge/tests/T2Repro/Program.cs
0  build/MilBridge/tests/TextLineProto/Program.cs
```
⇒ 登记写的"`HbTextLineParity/Program.cs` **仅注释命中**"这一句要**收紧**：那两个命中是模式里的 `TextFormatter` 一词（`:21`、`:23` 是注释，讲"真机 `TextFormatter.FormatLine`"），**`minWidth`/`MinMaxParagraphWidth` 在该文件里 0 命中**。⇒ 五支门禁臂（`tline` / `tab-zero` / `tab-anchor` / `tab-rtl` / `textlineproto`）**一个都不消费 min/max**，**Claim 2 成立**。

**② 自有树里"提到 min/max"的只有生产者自己**（不是消费者）。**放宽到大小写不敏感**后逐文件命中与逐条判读：

```
      1 build/DirectWrite.Linux/FallbackCriteria/Program.cs     ← :26 注释里的 "maxWidth 40"（**输入**容器宽）
      1 build/MilBridge/tests/CoverageProbe/Program.cs          ← :1164 c.GetProperty("maxWidth")（**输入**容器宽）
      2 build/MilBridge/tests/HbTextLineParity/Program.cs       ← :400 / :946 c.GetProperty("maxWidth")（**输入**容器宽）
      1 build/MilBridge/tests/T2eLineHeight/Program.cs          ← :74 c.GetProperty("maxWidth")（**输入**容器宽）
      1 build/PresentationCore.Linux/SR.g.cs                    ← 无关（DrawingAttributes 的资源串）
     19 build/PresentationCore.Linux/TextFormatterImp.Linux.cs   ← 生产者本体（:273-323 宽松实现、:605/:629 上游两个 override）
     58 build/PresentationFramework.Linux/FrameworkElement.Linux.cs ← 无关（FrameworkElement.MinWidth/MaxWidth 布局属性）
      2 build/PresentationFramework.Linux/TextBlock.Linux.cs    ← 无关（:3839/:3846 注释里的 Width/Min/MaxWidth 属性名）
      8 build/shims/PresentationCore.HbTextLine.cs              ← 生产者本体（:4568-4594）
     22 tests/parity/windows/layout-b34/src/LayoutOracle/Cases.cs   ← Windows oracle 源码（`maxWidth`/`maxLines` 输入）
      5 tests/parity/windows/layout-b34/src/LayoutOracle/Runner.cs   ← 同上（Windows 专用，本地不编译）
      4 tests/parity/windows/shaping/src/LayoutOracle/Dw.cs          ← 同上
      1 tests/parity/windows/shaping/src/LayoutOracle/Program.cs     ← 同上
```
**②b 非 `.cs` 宿主**（`*.py`/`*.sh`/`*.ps1`，整棵自有树）：只有应用器自己（`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`，18 行）—— **它是生产者**，不是消费者。
⇒ **没有任何一处是"读 `minWidth`/写判据"的消费者**。特别注意：`CoverageProbe` 那 1 处命中是 **`maxWidth` 的输入读取**（`Program.cs:1164`，b34 oracle 模式的容器宽），**不是** min/max 段落宽的读数 ⇒ 我先前"`CoverageProbe` 0 命中"的口径要**写清楚**：按 `minWidth|MinMaxParagraphWidth` 是 0，按大小写不敏感的 `maxWidth` 是 1 且为**输入**。
**③ 真机 oracle 场景数据：没有 min/max 段落宽真值。** 30 份 json 扫描结果里，`min|max` 只命中这些键：`maxLines` / `maxWidth` / `textTrimming`（`layout-b34` 的 `cases*.json`、`results-*.json`、`windows-results.json`）/ `maxBidiReorderingDepth` / `maxAdvanceDeltaDip` / `modifier-close-oracle.json` 的两个统计键 / `probe.json` 的字体名 —— **没有一个是"段落 min/max 宽"的输出字段**。其中 `maxWidth` 是**输入**：`layout-b34/cases.json` 的 `maxWidth` 在本地被当容器宽读进去（`build/MilBridge/tests/HbTextLineParity/Program.cs:400`：`double width = c.GetProperty("maxWidth").GetDouble();`，另一处 `:946`）。`tab-anchor` 用另一个键名（`paragraphWidthDip`）**同理也是输入**。
**④ 臂日志 / 在册红 / 门禁**：`arm-logs/*.log` 五份 `grep -a -c -i 'minwidth|maxwidth|minmax'` **全 0**；`known-red.json` **0**；`tline-gate.sh` **0 命中**。
**⑤ 更强的一条（登记没写）**：**没有任何一支臂驱动 PC 的 `TextFormatter`**。
- 自有 Linux 侧测试/样例里 `TextFormatter|TryFormatLine|TryMinMaxParagraphWidth|FormatParagraph` 命中数 = **`tests/` 0（排除 `tests/parity/` 的 Windows oracle 源码）+ `samples/` 0**；
- 五支臂走的都是 **shim 工厂直调**：`CoverageProbe:1352-1355`（tab 三臂）、`HbTextLineParity:229`/`:459`/`:952`/`:1567`（`tline` 臂）、`TextLineProto:150`（`textlineproto` 臂）。
⇒ 生成物 PC 那半（`TextFormatterImp.Linux.cs` 的注入段）**在全部臂读数之外**；`FormatMinMaxParagraphWidth`（`:605/:629`）与 `FormattedText.MinWidth`（真机唯一消费者，`FormattedText.cs:1510-1526`）在本地**零覆盖**。

### 3.3 后果（精确写）

1. **我们的 min/max 处理完全未测**：min 与 max 两条分支、PC→shim 的两级接线（`:652` 严格 shim、`:664` 宽松兜底）都只有"代码存在"这一条证据，**没有任何读数**。
2. **两个分支今天的行为可以互相矛盾**（§2.5 的构造例：`min > max`），而臂**读不出来**。
3. **`Indent` 从未进入 min/max 路径**，而真机的 min/max **都含 `Indent`**（reference：`FormatSettings.cs:60-62`/`:125-146` 把 `Pap.Indent` 存进 `_textIndent`；`LineServicesCallbacks.cs:376` `lsLineProps.durLeft = settings.TextIndent;`；`TextMetrics.cs:131` `_textStart = lineWidths.upStartMainText;`、`:372-375` `Width = _textWidthAtTrailing + _textStart`、`FullTextLine.cs:2575` `MinWidth = IdealToReal(_textMinWidthAtTrailing + _metrics._textStart)`）。**并且这条不是推断 —— oracle 自己的行宽已经把它测出来了**（同一文件、同一字体、text `'ab'`、em 24、Arial、dpi 96）：

| 用例（`tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`） | `indentDip` | `paragraphIndentDip` | 真机行宽 |
|---|---|---|---|
| `B-indent/notab-control@w80@LTR@i0@default` | 0 | 0 | `26.693333` |
| `B-indent/notab-control@w80@LTR@i24@default` | 24 | 0 | `50.693333`（= 26.693333 **+ 24**） |
| `B-indent-extra/notab-control@w80@LTR@i0p24@default` | 0 | 24 | `26.693333`（`ParagraphIndent` **+0**） |
| `B-indent-extra/notab-control@w80@LTR@i24p24@default` | 24 | 24 | `50.693333`（只加 `Indent`） |
| `B-indent/notab-control@w40@LTR@i24@default` | 24 | 0 | `[37.346667, 37.346667]`（每行 = 13.346667 + 24） |

   ⇒ **"行宽 + `Indent`、不含 `ParagraphIndent`"是实测**（不只是读上游代码推出来的）。
4. **`FormattedText.MinWidth`**（本仓唯一 in-repo 消费者，`FormattedText.cs:1510-1526`）拿到的会是"**少了 `Indent`**"的值；任何走公开 API `TextFormatter.FormatMinMaxParagraphWidth` 的应用同理。**注意**：`TextBlock` 不消费 min/max（上游 `PresentationFramework/**` 里 `FormatMinMaxParagraphWidth` **0 命中**）⇒ 这条缺口**不会**被 `WpfTextDemo` 门禁抓到（门禁只看渲染帧）。

### 3.4 相邻发现：PC 半把 `ParagraphIndent` 接进了 `Indent` 的槽（**对冻 `pc` 是硬信号**）

`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（现树，`f86198dfdd349332`）三行链条逐字：

```
231:                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight, double paragraphIndent = 0)
...
256:                            modifierOpenIndex: modOpen, modifierCloseIndex: modClose, indentDip: paragraphIndent);
...
575:                    settings.Pap.LineHeight, paragraphIndent: settings.Pap.ParagraphIndent
```
对应应用器 `:399`（同 `:256`）与 `:490`（同 `:575`，即 `T1c-report.md:2764` 的 "E"）。

而 shim 对这两个参数的语义是**排他的**（`PresentationCore.HbTextLine.cs`）：
```
3843:            double indentDip = 0,                 // 真机 `TextParagraphProperties.Indent`（只作用首行）
...
3860:            double paragraphIndentDip = 0)   // D-T2/(C)：尾随可选，默认 0 ⇒ 既有调用点零改动
...
1765:                double lineContentStart = indentDip + paragraphIndentDip;
1771:                                                  indentDip, out tabClamped);   // 件 1a：网格锚 = indentDip
2866:            double witw = shaped.TotalWidthPx + indentDip;   // ③ 行尾空白占区间（+ Indent：真机把 Indent 算进行宽）
```
⇒ **`ParagraphIndent` 被送进了 `Indent` 的槽**（网格锚 + 行宽都按 `Indent` 处理），**`Pap.Indent` 一个字节都没送**，而 `paragraphIndentDip`（该收 `ParagraphIndent` 的那个）**从未被传**。
**证据强度**：
- **proven（代码级）**：映射如上，逐字；`grep -cF 'Pap.Indent' build/PresentationCore.Linux/TextFormatterImp.Linux.cs` = **0**（该文件里只有 `Pap.ParagraphIndent` 一处、`Pap.LineHeight` 一处）。
- **可观测差（按 §3.3 的实测量级推）**：对 `i0p24` 类段落（`Indent=0, PI=24`），真机行宽**不加 PI**（实测 `26.693333`），而我方会按 `indentDip=24` 算 ⇒ **行宽多 24**；对 `i24p0`（`Indent=24, PI=0`），我方 `indentDip=0` ⇒ **行宽少 24**。⇒ 误差符号随族**反转**，而正确接线（`indentDip: Pap.Indent` + `paragraphIndentDip: Pap.ParagraphIndent`）在两类上**都对**。
- **为什么现在没人发现**：五支臂**绕过 PC**（§3.2⑤），而 `tline` 的语料 `tests/parity/windows/layout-b34/cases.json` **614/614 例** `indent = 0` 且 `paragraphIndent = 0`（逐例统计命令见 §5 注）⇒ 这条接线在**当前所有读数上恒等（惰性）**，这正是 `#16` 里 "`tline` 数值不变" 的原因之一。
- **对我判决的影响**：这**不是** Claim 1/2 的一部分，我**不把它写成已证缺陷的最终定性**（还差"设计意图"的一手证据：可能有人说 `paragraphIndent:` 这个**形参名**就是给 PI 用的、而 shim 侧 `indentDip` 只是历史命名）。但它的**语义冲突是硬的**，且 `WAVE16-PREREGISTRATION.md:26`（(C)：`lineBoxWidth = container − ParagraphIndent`）要的正是 `paragraphIndentDip` 这一路 ⇒ 建议**冻 `pc` 前**先由 T1c/T1d 各自只读复核一次（`indentDip` 的定义到底认哪一个），并把它**登记**（哪怕判"命名问题、行为待测"）。

---

## 4. 关闭本边界项的**预登记计划**（给下一波，含红证明）

> 预登记格式照本仓惯例：**先写死判据 + 位移预测 + 红则停条件**；本节的"我方现值"一律标注 **predicted（未测）**，因为本节**没有跑仪器**。

### 4.1 新臂（两条腿，腿 1 便宜、腿 2 是契约面）

| 腿 | 仪器 | 形态 | 覆盖什么 |
|---|---|---|---|
| **L1（工厂级）** | `build/MilBridge/tests/CoverageProbe/Program.cs` 新 `--minmax-oracle <json>`（**不在世代绑定三项里** ⇒ 改它不会把门禁打成 `NOINFO`，但**纪律 34** 要求：改探针 ⇒ **重取三支 tab 臂 + 重钉 `known-red.json` 的 `generation`**，并在 `changelog` 记探针新 sha） | 逐例：`FormatParagraph(text, font, em, double.MaxValue, gt, 1.0f, props, false, false, 0, out c1, defaultIncrementalTab: arm0?0:NaN, wrap: wrap, indentDip: c.indentDip, paragraphIndentDip: c.paragraphIndentDip)` 取 `max(Width)`；再 `paragraphWidthDip = 0.0` 取 `max(Width)` ⇒ 对比 oracle 新字段 | **min/max 的数学/口径**：`Indent` 进不进宽度、`ParagraphIndent` 进不进宽度、min 的代理是否成立 |
| **L2（契约级，必须做）** | 同上探针（它已具备四件套：`MockTextSource : TextSource` `:43-79`、`using System.Windows.Media.TextFormatting` `:36`）＋ **新增一个 `TextParagraphProperties` 子类**（照 oracle 侧 `tests/parity/windows/tab-anchor/src/Program.cs:642-662` 的 `Para` 逐项搬：`Indent`/`ParagraphIndent`/`FirstLineInParagraph`/`DefaultIncrementalTab`/`TextWrapping`/`FlowDirection`） | 逐例调 **真 API**：`TextFormatter.Create().FormatMinMaxParagraphWidth(src, 0, pap)` ⇒ 比 `.MinWidth` / `.MaxWidth` | **PC→shim 接线**（`:652` 严格 shim、`:664` 宽松兜底）＋ §2.5 的 `min > max` 契约违反 ＋ §3.4 的接线错位 |

**输入形态（用例从哪来）**：**不新造语料** —— 直接用现成的 `tab-anchor` oracle（436 例），它**已经**逐例带 `indentDip ∈ {0,24}`、`paragraphIndentDip ∈ {0,24,48}`、`firstLineInParagraph`、`incrementalTabArm`、`paragraphWidthDip`、`emSizeDip`、`textWrapping:"Wrap"`、`text`（`'ab'` / `'a\tb'` / `'\ta'` / `'ab\t\tc'` …）。**非 0 缩进的用例有 208 条**（`B-indent` 144 + `B-indent-extra` 72 − 重叠，见 `docs/WAVE16-PREREGISTRATION.md:1308-1310` 的现场计数口径）；`paragraphIndentDip ≠ 0` 的族是 `B-indent-extra/*p24*` 与 `D-paraindent`。
**另需 1 条"构造例"**（只为 §2.5 的 `min > max`）：`TextSource` 里 run#0 = `TextModifier`（长度 1）、run#1 = `TextCharacters("WWWW")`，`modifierOpenIndex = 0`、无 `TextEndOfSegment` ⇒ 触发"跨到段末"的零宽跨度。

### 4.2 oracle 一侧的真值源（**今天不存在，必须去真机重录**）

- **能不能在现有 oracle 里表达 `minWidth`？不能。** 依据：`tests/parity/windows/**/*.json` 30 份逐个键扫描（§3.2③）**没有任何 min/max 段落宽输出字段**；`layout-b34/probe.json:36-44` 只是**反射 dump 的 API 表面**（`MinMaxParagraphWidth FormatMinMaxParagraphWidth(TextSource textSource, Int32 firstCharIndex, TextParagraphProperties paragraphProperties)` 两个重载），**不是真值**。
- **真值怎么来（cheap，且同一趟就够）**：Windows 侧 `tests/parity/windows/tab-anchor/src/Program.cs` 的 `Measure(...)`（`:423-478`）里，`formatter` / `para` / `source` **已在作用域内**（`:431-435`）⇒ 在取完行之后加**一次**调用，并把两个字段写进 `rec`（`:456-478`）：
  ```csharp
  MinMaxParagraphWidth mm = formatter.FormatMinMaxParagraphWidth(source, 0, para);   // 与 :443 同一个 source/para
  rec["minWidthDip"] = mm.MinWidth;      // 真机 FormattedText.MinWidth 走的就是这一条（FormattedText.cs:1520）
  rec["maxWidthDip"] = mm.MaxWidth;
  ```
  然后照 `src/run.ps1` 的既有流程重跑（它已经带"跑两遍 + 去掉 `generatedUtc` 后比 sha"的确定性检查）、重提交 JSON。**代价 = 1 次 Windows 趟 + 2 个字段**；`PROVENANCE.md §1` 的元组表要补一行"新增测量 = `FormatMinMaxParagraphWidth`"（纪律 15/18：读数 = 件 sha + 仪器版本 + 口径 + artifact/字段）。
- **一致性预言（可用 oracle 自己的数据先自检）**：真机 `MaxWidth` 与"同一段落按一行铺开的 `FormatLine` 行宽"**应当是同一量**（`TextMetrics.cs:372-375` 与 `FullTextLine.cs:2258` 是同一个 `_textWidthAtTrailing + _textStart`）⇒ 对 `B-indent/notab-control@w80@LTR@i24@default`，`maxWidthDip` **应 = `50.693333`**（该值已经在 oracle 里作为行宽逐字存在）；`@i0p24` **应 = `26.693333`**。若真机给出别的值 ⇒ 说明"含 `Indent`、不含 `ParagraphIndent`"这条链在我的读码里断了 ⇒ **停下来重新读 reference**，不许改判据去迎合。
- **`MinWidth` 的真值形态我不预判数值**（`MinWidth = _textMinWidthAtTrailing + _textStart`，`_textMinWidthAtTrailing` 由 LS 的 `upMinStartTrailing` 起算并在每个 symbol 上累加，`FullTextLine.cs:329-334`/`:457`）⇒ 对 `'ab'`@`i24` 它**可能**是 `37.346667`（按字符断点，与同例 `w=40` 的实测行宽同值）**也可能**是 `50.693333`（按词不可断）——**这正是新臂要读的东西**，两条备选都写死在登记里，读到哪条就是哪条，**不许事后挑**。

### 4.3 预期读数（先写死，含"今天必红"与"阴性对照"）

以 `B-indent/notab-control@w80@LTR@i24@default`（text `'ab'`，`Indent=24`，`PI=0`，em 24）为例：

| 侧 | `minWidth` | `maxWidth` | 依据 |
|---|---|---|---|
| **oracle（待录）** | `37.346667` 或 `50.693333`（二选一，§4.2） | **`50.693333`** | 该值 = oracle 已测行宽（§3.3 表） |
| **我方 L2 今天（predicted）** | `13.346667` | `26.693333` | `Indent` 从未进入 min/max 路径（`indentDip` 默认 0，shim `:3843`）；内容宽 = oracle `@i0` 行宽 `26.693333`、单字符 `13.346667` ⇒ **两支都短 `24.000` = `Indent`** |
| **判据** | `L1`/`L2` 逐例 `abs(ours − oracle) ≤ 0.05`（与 tab 臂同容差；本地字体是 Liberation Sans 替身 Arial，`CoverageProbe:1282`）；逐族给计数（不许只给总数） | — | — |

**两极性（这个臂天生自带阴性对照，不用另造牙）**：
- `indentDip = 0` **且** `paragraphIndentDip = 0` 的用例（`A-anchor`/`A-contrast`/`B-indent` 的 `i0` 支）⇒ **今天必须 PASS**（否则说明臂本身坏了/字体不可比）；
- `Indent ≠ 0` 或 `PI ≠ 0` 的用例（`i24*`、`*p24*`）⇒ **今天必须 FAIL，且差值恰好是缩进项**（`Indent` 那类应短 24.00；`i0p24` 那类若走 L2 且接线如 §3.4 ⇒ **应长 24.00**，方向相反）。
  ⇒ **"同一条命令里既有 PASS 又有 FAIL，且 FAIL 的差等于一个可解释的常数"** = 这条臂**可判红、不是恒红也不是恒绿**（纪律 3）。

### 4.4 红证明（"什么单点改动必须让新臂变红"）

1. **落地前**：新臂在 `Indent ≠ 0`/`PI ≠ 0` 的族上**必须红**（上面 predicted 的 `24.000` 差值）——如果它今天就是绿的 ⇒ **说明判据没读到 min/max（口径错了）**，按纪律 21/27 处理（空集/假绿），**不许当达成**。
2. **修法落地后必须全绿**（含 `i0p24` 的反向族）。
3. **单点回退 ⇒ 必须重新红**（两条独立牙，各一次）：
   - 牙 A（min/max 侧）：把 PC 的 min/max 接线**退回"不传缩进"**（即现树形态）⇒ `i24` 族必须再红，差值回到 `24.000`。
   - 牙 B（不对称侧）：把 `:305` 的 `modifierOpenIndex/modifierCloseIndex` **删掉**（让 max 与 min 一样"无作用域"）⇒ §2.5 的构造例必须**从"min > max"变成"min = max"**（即该例的读数**必须随这一处改动而变化**）；若不变 ⇒ **那条不对称在宽度上不可观测**，则 §2.5 的"可观测差"判决要**当场撤回**、降级为"仅参数形态不一致"。
     > 这条正是本项目要的形态：**修法/断言都要能被自己的实验否掉**，所以牙 B 的结果**可能否掉我 §2.5 的推演** —— 请把它当**判决性实验**跑，并把两种结果都留档。
4. **越界即停**：新臂只许新增模式与读数；**不许**改 `:302`/`:309` 之外的既有分支语义；`tab-*` 三臂与 `tline` 的既有读数**任一位移动 ⇒ 停、报主控**（`tline` 的 b34 语料 `Indent=PI=0` ⇒ 预期**逐字节不变**，这同时是"新臂没有踩到别的路径"的证据）。

### 4.5 接线/登记的同步动作（不落地本报告，只列清单）

1. `docs/CURRENT-STATE.md:153` 的 `D-T2` 边界行**改写**：删掉"max 含 indent / min 不含"（**陈旧**，§2.4），改为两条**在册项**：
   - `D-T2-a`：**`Indent` 从未进入 min/max**（PC `:652` → shim `:4572` 无缩进入参；两分支**对称**缺项）——判据 = §4.3；
   - `D-T2-b`：**`:309` 与 `:305` 的 modifier 作用域参数不对称**（min 无、max 用了 `open→段末` 的已知错跨度）——判据 = §4.4 牙 B。
2. `docs/WAVE16-PREREGISTRATION.md:79` 那句"`:305` 维持不接（五臂不消费 `minWidth`，已成结论）"要**加限定**：结论仍真，但理由是"**五臂不驱动 PC 的 TextFormatter，且 oracle 里没有 min/max 真值**"，**不是**"min/max 不重要"。
3. 若 §3.4 复核成立 ⇒ 同一波里给 PC 半补 `indentDip: settings.Pap.Indent` + `paragraphIndentDip: settings.Pap.ParagraphIndent`（应用器 `:490` 一处 + `:399`/`:256` 的透传命名同步），并**把它列进"位移集合"**（预期位移：只有 `Indent/PI ≠ 0` 的段落，符号按 §3.4；`tline`/`tab-*` 应**零位移**）。

---

## 5. 读数表（lane=TDT2）

**环境（开头，2026-09-15 18:43:41 +08:00 / 10:43:41Z 那一次）**：`uname -r = 6.8.0-138-generic`｜`loadavg = 1.49 2.02 1.66`｜`mem_available = 3560 MB`（`free -m`：total 7923 / used 3924 / free 553 / buff/cache 3445 / swap used 1238）。
**环境（收尾，2026-09-15 18:49:17 +08:00）**：`loadavg = 2.15 2.03 1.75`｜`mem_available = 3532 MB`（used 4005）。**两趟之间我没有跑任何仪器**（只有 `read`/`grep`/`sha256sum`/`stat`/`python3` 读 JSON），所以 `loadavg` 的上升**不是本条车道造成的**（本机同时有别的车道活动；按纪律 2/8，凡"读数"都要在静树取 —— 本报告不含任何由此产生的性能/并发类结论）。

| 文件 | `sha256` 前 16 | 字节 | mtime |
|---|---|---|---|
| `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（生成物，本报告主对象） | `f86198dfdd349332` | 51,594 | 2026-09-15 17:10:55.196375214 +0800 |
| `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`（应用器） | `07dc7627f609e031` | 37,625 | 2026-09-15 17:10:55.155374812 +0800 |
| `build/shims/PresentationCore.HbTextLine.cs` | `bc04c05ab6d8d82a` | 275,765 | 2026-09-15 18:25:25.142184898 +0800 |
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`（**权威 `pc`；跑前跑后各读一次，逐位相同**） | `c0763fc10173e7ff` | 4,194,816 | 2026-09-15 18:38:14.829263117 +0800 |
| `build/MilBridge/tests/CoverageProbe/Program.cs`（tab 三臂仪器） | `a8727a5bed6bf049` | 108,127 | 2026-09-15 17:24:40.722715499 +0800 |
| `build/MilBridge/tests/HbTextLineParity/Program.cs`（`tline` 臂仪器；**世代绑定三项之一**） | `2e458928fc1577c2` | 128,190 | 2026-09-15 10:24:06.297070579 +0800 |
| `build/MilBridge/tests/TextLineProto/Program.cs`（`textlineproto` 臂） | `34e31d95b29a1bd1` | 25,312 | 2026-09-15 11:15:13.686425965 +0800 |
| `build/MilBridge/run.sh`（**世代绑定三项之一**） | `3e513e88a4fa4ec9` | 16,450 | 2026-09-15 16:53:13.196912948 +0800 |
| `build/MilBridge/known-red.json`（在册红表，`generation #16`） | `391c907c7d114e01` | 23,648 | 2026-09-15 18:31:33.137622051 +0800 |
| `build/MilBridge/tools/tline-gate.sh` | `b37a5c9f55ae71a4` | 40,181 | 2026-09-15 16:44:01.143525352 +0800 |
| `build/MilBridge/arm-logs/README.md`（臂命令出处） | `6924605fab87660e` | 6,880 | 2026-09-15 16:52:15.962157117 +0800 |
| `build/MilBridge/arm-logs/tab-anchor.log`（`#16` 全绿那趟） | `99d72b385fe23a90` | 43,563 | 2026-09-15 18:27:55.857491813 +0800 |
| `build/MilBridge/arm-logs/tline.log` | `ad07ead4022539d2` | 21,474 | 2026-09-15 18:30:20.540612133 +0800 |
| `build/MilBridge/T1c-report.md`（"撤 C :305" 的一手出处） | `04422985ebba1f58` | 272,131 | 2026-09-15 17:12:05.280020130 +0800 |
| `tests/parity/windows/tab-anchor/out/tab-anchor-oracle.json`（§3.3 实测行宽表） | `a31a813114256faf` | 1,251,441 | 2026-09-14 19:33:26.982061754 +0800 |
| `tests/parity/windows/tab-anchor/src/Program.cs`（oracle 宿主；§4.2 落点） | `e6651272200f7fb6` | 40,998 | 2026-09-14 19:26:52.277103203 +0800 |
| `tests/parity/windows/layout-b34/cases.json`（`tline` 语料；614/614 `indent=0`/`paragraphIndent=0`） | `597b99158285befc` | 800,499 | 2026-09-11 14:07:47.299714742 +0800 |
| `tests/parity/windows/layout-b34/probe.json`（只是 API 表面 dump） | `8c27e8b9c9ebe2e4` | 26,313 | 2026-09-11 14:01:36.953611840 +0800 |
| `docs/CURRENT-STATE.md`（`:153` 陈旧登记） | `806d7861d70450c5` | 109,257 | 2026-09-15 17:26:05.078921609 +0800 |
| `docs/WAVE16-PREREGISTRATION.md`（`:79` 结论、§4.6 流水） | `d86906c33f4c0cee` | 54,304 | 2026-09-15 18:31:54.595619472 +0800 |
| `verify-all.sh`（第 10 步 = 五臂门禁） | `a68823631e8f8919` | 9,847 | 2026-09-15 16:44:49.096268028 +0800 |
| **真机 reference（上游，只读）** | | | |
| `upstream/.../MS/internal/TextFormatting/TextFormatterImp.cs` | `1ae4a4bfe3f9da2b` | 32,156 | 2026-08-31 09:35:23 +0800 |
| `upstream/.../MS/internal/TextFormatting/FormatSettings.cs` | `7f158048978f82b7` | 9,461 | 2026-08-31 09:35:23 +0800 |
| `upstream/.../MS/internal/TextFormatting/FullTextLine.cs` | `5ea6777beca0bfae` | 113,842 | 2026-08-31 09:35:23 +0800 |
| `upstream/.../MS/internal/TextFormatting/TextMetrics.cs` | `ff25161b14f3c46c` | 22,680 | 2026-08-31 09:35:23 +0800 |
| `upstream/.../MS/internal/TextFormatting/TextProperties.cs` | `b0b0fbfa9b0a6747` | 12,436 | 2026-08-31 09:35:23 +0800 |
| `upstream/.../MS/internal/TextFormatting/LineServicesCallbacks.cs` | `612c19e675b7ad30` | 151,469 | 2026-08-31 09:35:23 +0800 |
| `upstream/.../System/Windows/Media/FormattedText.cs`（`:1510-1526` 唯一消费者） | `424f02137f498441` | 82,853 | 2026-08-31 09:35:23 +0800 |
| `upstream/.../textformatting/TextParagraphProperties.cs` | `d8553b9face9860b` | 3,794 | 2026-08-31 09:35:23 +0800 |
| **历史快照（`$HOME`，用于否掉"曾经有过"的猜测）** | | | |
| `/home/links-dev/t1c-16-backup/TextFormatterImp.Linux.cs`（`#16` 之前） | `5dedc21f5f372c78` | 51,491 | 2026-09-14 22:14:58.597266457 +0800 |
| `/home/links-dev/t1c-13-backup-221419/TextFormatterImp.Linux.cs`（`#13` 之前，min/max 两探针**连具名实参都没有**） | `569fefc718340086` | 49,801 | 2026-09-11 23:07:42.708014402 +0800 |

**注（§3.4 的 614/614 依据，可复算）**：`python3 -c "import json,collections;d=json.load(open('tests/parity/windows/layout-b34/cases.json'));c=d['cases'];print(len(c), collections.Counter((x['indent'],x['paragraphIndent']) for x in c))"` ⇒ `614 Counter({(0, 0): 614})`。

**写域与副作用声明**：本报告只新建 `build/MilBridge/TDT2-boundary-report.md`；scratch 只写在 `$HOME/wfp-runs/w17-laneDT2/`（`README.md` `sha16 774ef96d64189500` ＋ §2.3 的两个 13 行文本，两份 `sha256 = 24fe0d9e9d766fd835e8da5e9e91fd32738bac3617b4017253382d5270bac385`）；**未运行任何仪器**（没有 `run.sh`、没有五臂、没有 `verify-all`、没有门禁、没有 `dotnet build`）；**未改动** `build/shims/**`、应用器、`build/PresentationCore.Linux/**`、`docs/**`、`verify-all.sh`、`known-red.json`、`arm-logs/**`。生成物/权威产物的 sha16 前后一致（`pc c0763fc10173e7ff`；生成物源码 `f86198dfdd349332`；应用器 `07dc7627f609e031`；shim `bc04c05ab6d8d82a`；`run.sh 3e513e88a4fa4ec9`；`Parity/Program.cs 2e458928fc1577c2`；`known-red.json 391c907c7d114e01`）。

---

## 6. 用现有东西**测不出来**的，以及需要什么仪器

| # | 测不出来的东西 | 为什么今天测不出来 | 需要什么 |
|---|---|---|---|
| 1 | **真机 `MinWidth` / `MaxWidth` 的数值**（含 §4.3 那句"37.346667 还是 50.693333"） | `tests/parity/windows/**` 30 份 oracle JSON 里**没有** min/max 段落宽字段（§3.2③）；oracle 只测了 `FormatLine` | Windows 侧 `tab-anchor` oracle 宿主加 1 次 `FormatMinMaxParagraphWidth` + 重跑 `run.ps1`（§4.2） |
| 2 | **我方 min/max 的现值**（§4.3 的 `13.346667` / `26.693333` 是 predicted） | 13 支臂宿主 **0 命中** min/max；五支臂都绕过 PC（§3.2①②⑤） | §4.1 的 L1/L2 臂（探针新模式；L2 还需一个 `TextParagraphProperties` 子类） |
| 3 | **`:309` 不对称在"宽度"上到底可不可观测**（§2.5 构造例的 `min > max`） | 同 #2：没有能读 min/max 的仪器；本条**只**由代码级推演支撑（`modifierScopeEnd = -1 ⇒ [open, 段末)`） | §4.4 的**牙 B**（删 `:305` 的两个具名实参 ⇒ 读数必须变）；**这是判决性实验，可能否掉我的推演** |
| 4 | **PC 半缩进接线（§3.4）是否真的产生 24 DIP 位移** | 臂绕过 PC；b34 语料 `Indent=PI=0` 614/614 ⇒ 惰性；样例/测试里 `TextFormatter` 0 命中 | `L2` 臂即可（它走真 `TextFormatter` + 非 0 `Indent/PI`）；要**端到端**证据则需一个"用 `Indent`/`ParagraphIndent` 的应用用例"（`TextBlock` 不消费 min/max，且 PF 的 `LineProperties.ParagraphIndent` 未覆写 ⇒ 应用面可能是空白，需另查） |
| 5 | **`Extent` 与 min/max 的相互作用**（真机对 `GlyphRun` 边界 `Inflate(min(em/7,1))`，在册 `D-E1`） | 本项**只**涉及宽度量；但若将来 min/max 臂顺带读 ink box，就会撞上 `D-E1` 的系统偏置 | 无需新仪器；**登记**：min/max 臂**只比宽度**，不引入 ink 判据（否则两条在册项互相污染） |
| 6 | **`FormattedText.MinWidth` 的端到端读数** | 本仓 `samples/**`、`tests/**` **0 命中** `FormattedText`；PC 内唯一消费者没有本地用例 | 若要端到端：`samples/` 加一个用 `FormattedText.MinWidth` 的小样例（属 T3 写域，**不在本报告建议的第一步里**） |

**一条自纠纪律（我自己）**：本报告里凡是 **proven**（代码级、逐字引证）与 **predicted**（推演数）的地方都逐处标了；**若 §4.4 的牙 B 或 §4.2 的 oracle 一致性预言给出相反读数，我 §2.5/§4.3 的推演应当被当场撤回并留档**——这正是本项目"断言必须以改完之后的读数收尾"的要求。

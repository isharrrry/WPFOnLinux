# W19A —— 落地 `#19` 的 **A（`P4` 过期注释）+ B（严格档 indent 缺口）**

> **lane = W19A**（纪律 32：谁跑的这趟 + 件 sha + 时刻）
> **时刻（开工）**：`2026-09-16T15:22:29+08:00`｜`uname -r = 6.8.0-138-generic`｜`/proc/loadavg = 0.56 0.88 1.34`｜`MemAvailable = 3128 MB`
> **时刻（收尾）**：`2026-09-16T15:33:11+08:00`｜`loadavg = 11.66 6.67 3.72`｜`MemAvailable = 2780332 kB`
> **写域**：`build/shims/PresentationCore.HbTextLine.cs`｜`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`｜生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`｜本文件｜`$HOME/wfp-runs/w19-laneW19A/`
> **未改**（逐件现场 sha16 复核，见 §6.4）：`build/MilBridge/tests/PcLineOracle/**`（另一车道在改，我只读）｜`CoverageProbe/**`（`a8727a5bed6bf049`）｜`known-red.json`｜`tline-gate.sh`｜`verify-all.sh`｜`integration-wave.sh`｜`docs/**`｜`samples/**`｜`src/WpfGfx.Linux/**`｜`build/shims/Win32ShimResolver.cs`
> **未用** `pkill -f` / `pgrep -f`；本轮未需要止损。

---

## 1. 一行判决

**A、B 两件都已落地，编译通过（`error CS = 0`、`warning CS = 0`，三个消费者工程各自单独编过），应用器的 6 条新牙齿**逐条两极化证过**（每条注错都会当场 `rc=1` 并打出对应的具名失败）；**行为读数我一件都没取** —— 严格档腿归 W19B、权威产物归主控，本报告不对任何行为下判决。**

**A** 只改注释、**逐字节零代码改动**（§3.1 用"只剔 `///` 行后 `diff` 为空"证明）。
**B** 给 `HbTextFallback.TryFormatLine` 加两个**带默认值**的缩进形参并透传到工厂；PC 侧严格档调用点由应用器改成传 `paragraphProperties.Indent` / `.ParagraphIndent`（**原始 DIP**）。
**默认形参保既有调用点逐位等价**这件事**不是推断**：反编译级读回元数据证明两个新形参 `optional=True default=0`（§4.4 正控），且权威 `pc`（修前产物）同法读回是 **6 形参**、无缩进形参（同节负控）。

**三条我推翻/更正的东西**（§7）：① 预登记说"改注释 ⇒ shim 变、pc 因重建而变，**所有判据读数逐位不变**"—— 前半对，**但"注释不进产物"在 PC 上不成立**（`HbTextLineShimSha.targets` 把 shim 的**整文件 sha** 编进 `AssemblyMetadata` ⇒ **一行注释也改 dll 字节**），这条我在现场实测到并更正；② 应用器原有的一条 P2 计数牙齿（来源要求 `1/1`）在本件后**必然变成 `2/2`**，它当场报红拦下了我的改动（牙齿是好的，口径要跟着改）；③ 我自己写的牙齿**连错三版**（两次假绿一次假红），三次都是牙齿抓住我自己，全部留档在 §4.2。

---

## 2. 前/后 sha16 + 字节 + mtime（每一个我编辑过的文件 + 备份）

纪律 16：**先备份再改**。备份用 `cp -p`（保 mtime），落在 `$HOME/wfp-runs/w19-laneW19A/backup/`。

| # | 文件 | before sha16 | before 字节 / mtime | after sha16 | after 字节 / mtime | 备份（sha16 / 字节 / mtime） |
|---|---|---|---|---|---|---|
| 1 | `build/shims/PresentationCore.HbTextLine.cs` | **`bc04c05ab6d8d82a`** | 275,765 / 09-15 18:25:25.142184898 | **`fe1b7ed8fa3ed231`** | 278,692 / 09-16 15:30:15.645713935 | `backup/PresentationCore.HbTextLine.cs.before` = **`bc04c05ab6d8d82a`** / 275,765 / 09-15 18:25:25.142184898 |
| 2 | `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` | **`188f75a67294138f`** | 44,274 / 09-16 12:15:51.854764681 | **`daa1fe2a32d454cf`** | 52,168 / 09-16 15:31:55.755185512 | `backup/patch-presentationcore-textline-fallback.py.before` = **`188f75a67294138f`** / 44,274 / 09-16 12:15:51.854764681 |
| 3 | 生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | **`56a5b4a5be1c6bcc`** | 53,783 / 09-16 12:18:00.217709951 | **`799e0366b312ec65`** | 55,223 / 09-16 15:31:51.807238383 | `backup/TextFormatterImp.Linux.cs.before` = **`56a5b4a5be1c6bcc`** / 53,783 / 09-16 12:18:00.217709951 |

**before 值与上游报告逐位吻合**：件 1 = `W17B-report.md §7` 与 `#18` 冻结表头里的 shim sha；件 2/3 = `W17B-report.md §2.2/§2.3` 的 after 值。⇒ **我是从 W17B 收尾的那一版改起的**（`proven`）。

**权威产物（我一次都没写）**：

| 件 | sha16 | 字节 / mtime | 备注 |
|---|---|---|---|
| `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | **`663114436443d2de`** | 4,196,864 / 09-16 15:09:34.759810754 | 开工前 = 收尾后 **逐位未变**（§6.5 逐次留档） |
| 其内嵌 `HbTextLineShimSha` | `bc04c05ab6d8d82a…` | — | = **修前 shim 的整文件 sha** ⇒ 该产物确系修前源所出 |

**⚠️ 这个"内嵌 sha"是本波的关键机制，也是我必须更正预登记的地方**（§7.1）：

```
build/PresentationCore.Linux/HbTextLineShimSha.targets:58
  <_HbTextLineShimShaLine Include="[assembly: System.Reflection.AssemblyMetadata(&quot;HbTextLineShimSha&quot;, &quot;$(HbTextLineShimSha256)&quot;)]" />
```
`AnyHash` 取的是 **shim 源文件的整文件 sha** ⇒ **一句注释就改 `pc` 的 dll 字节**。所以"改注释 ⇒ 判据读数逐位不变"这半句要**分成两层读**：**行为**读数应不变，**产物 sha** 一定变（且 `ShimShaReader` 会随之报 `SHIM_SHA=yes`）。

---

## 3. 精确 diff（A 与 B 分开）

### 3.1 A —— `HasOverflowed` 上方的过期文档注释（**只改文字**）

`build/shims/PresentationCore.HbTextLine.cs:3409-3424`（**改后行号**）。修前原文（`backup` 逐字）：

```csharp
        /// <summary>
        /// 真机实测：**3222/3222 行全为 false**（含被强制断开的行）⇒ 本实现恒 false。
        /// "这一行是不是被强制断出来"这条信息不丢：见 `forcedBreakLines` 计数 + `Diagnostics`。
        /// </summary>
```

改后：

```csharp
        /// <summary>
        /// ⚠️ **本注释曾在 `#16` 的 `D-O1` 落地后变成与实现相反的陈述**（`#19`/W19A 只改文字，未动语义）。
        ///
        /// 真机实测：**3222/3222 行全为 false** —— 那是**真机语料**的分布，**不是**本实现的取值域。
        /// `D-O1` 已把这里改成**三分支真实现**（见 getter 体内的逐行注释）：
        ///   ① 未给段落宽（`_paragraphWidth == 0`，旧调用点）⇒ `false`（老路径逐位不变）；
        ///   ② `_startPenX >= _paragraphWidth` ⇒ `true`（退化族 `Indent + ParagraphIndent ≥ container`）；
        ///   ③ `_boxOriginX + _width > _paragraphWidth + 1e-9` ⇒ `true`（**严格 `>`**，恰好到达边缘 ⇒ `false`）。
        /// ⇒ 本实现**不再恒 false**：旧注释的"本实现恒 false"是**过时**的，若照它读会把③分支的溢出行读成"不可能"。
        ///
        /// "这一行是不是被强制断出来的"这条信息不丢：见 `forcedBreakLines` 计数 + `Diagnostics`。
        /// </summary>
```

**为什么这么写（三个分支逐条对实现，不凭记忆）**：`PresentationCore.HbTextLine.cs:3425-3430` 的 getter 本体逐字为

```csharp
                if (!(_paragraphWidth > 0)) return false;
                if (_startPenX >= _paragraphWidth) return true;
                return _boxOriginX + _width > _paragraphWidth + 1e-9;   // **严格 >**（相等 ⇒ false）
```
—— 与注释里 ①②③ 一一对应；`正文行号 3417-3419` 的既有行内注释也逐字提到 `D-O1`/Q11/"相等不算溢出"。
**并且我保留了原文没写错的那半边**："3222/3222 全 false"是**真机语料**的读数（`shim:3410` 的出处），它**没有错** —— 错的是把语料分布 **⇒ 推断成"本实现恒 false"** 那半句。改法是**把两个命题分开**，不是把数字删掉。

**"只改注释、零代码改动"的机器证据**（纪律 33 的对照实验）：

```bash
# 把 A 所覆盖的那个属性整段取出来，剔掉所有 /// 行后逐字节比较
diff <(sed -n '/public override bool HasOverflowed/,/^        }/p' backup/…before | grep -v "^\s*///") \
     <(sed -n '/public override bool HasOverflowed/,/^        }/p' build/shims/PresentationCore.HbTextLine.cs | grep -v "^\s*///")
⇒ 无输出（IDENTICAL：只有 /// 行不同 ⇒ A 没动一行代码）
```

整个 shim 的 diff 里，**非注释改动行只有 4 行**，全部属于 B：

```
$ diff -u backup/…before build/shims/PresentationCore.HbTextLine.cs | grep '^[+-]' | grep -v '^\(+++\|---\)' | grep -v '^\s*[+-]\s*//'
-                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight)
+                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight,
+                                              double indentDip = 0, double paragraphIndentDip = 0)
-                    plan, faces, runProps);
+                    plan, faces, runProps,
+                    indentDip: indentDip,
+                    paragraphIndentDip: paragraphIndentDip);
```
（最后一块共 4 个 `+` / 1 个 `-`；上面 2 行属于签名。全 shim diff 共 63 行，其余全是注释。）

### 3.2 B · shim —— 形参 + 转发

`build/shims/PresentationCore.HbTextLine.cs:4522-4524`（改后）：

```csharp
        internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth,
                                              double pixelsPerDip, bool alwaysCollapsible, double lineHeight,
                                              double indentDip = 0, double paragraphIndentDip = 0)
```

转发点 `:4549-4553`：

```csharp
                List<HbTextLine> lines = HbTextLineFactory.FormatParagraph(
                    text, primaryRun.FontPath, emSize, paragraphWidth, primaryRun.Typeface, (float)pixelsPerDip,
                    primaryProps, alwaysCollapsible, false, lineHeight, out consumed,
                    plan, faces, runProps,
                    indentDip: indentDip,
                    paragraphIndentDip: paragraphIndentDip);
```

**我现场核对了"要调哪个重载"**（派单特意提醒"有不止一个 `FormatParagraph` 重载，其中一个不收 indent"）：

| 重载 | 位置 | 收不收 indent |
|---|---|---|
| `FormatParagraph(string text, string fontPath, double emSize, double paragraphWidthDip, GlyphTypeface, float, TextRunProperties, bool, bool, double lineHeight, out int consumedLength, HbFontPlan plan = null, GlyphTypeface[] segmentFaces = null, TextRunProperties[] runProps = null, **double indentDip = 0**, **double defaultIncrementalTab = double.NaN**, bool wrap = true, int modifierOpenIndex = -1, …, **double paragraphIndentDip = 0**)` | `:3828-3868`（改后行号） | **收**（`indentDip` 在第 14 槽、`paragraphIndentDip` 在**尾槽**） |
| `FormatParagraph(text, fontPath, emSize, paragraphWidth, glyphTypeface, pixelsPerDip, runProperties, alwaysCollapsible, lineHeight, out consumed, plan, faces)`（`TryMinMaxParagraphWidth` 用的那个，`:4619-4621` 的 `wide` 与 `:4623-4625` 的 `narrow`） | 同上签名但**不传 indent** | 形参存在、**实参不传** ⇒ 默认 0 |

⇒ 严格档原来落的是**"形参存在但一个都不传"**的形态；**修前 shim 的 `TryFormatLine` 形参表里没有 indent（`bc04c05a:4496-4497` 逐字）** ⇒ 它**连传都传不了**。这与预登记 §0.1 B 的描述一致（`proven`）。

**为什么默认值必须是 `= 0` 而不是"新形参无默认"**：现有调用点**只有 6 个实参**，一个都不改：
- `build/MilBridge/tests/CoverageProbe/Program.cs:207/228/243/442`（`HbTextFallback.TryFormatLine(src, 0, width, 1.0, false, lhOverride)`）—— **我一个字没改**（纪律 34）；
- `PcLineOracle`（另一车道，我只读）；
- 生成物 `:565`（由应用器写）。

**"默认 0 恰好是中性值"不是猜的，是数出来的**——`indentDip`/`paragraphIndentDip` 在工厂内的每一处用法都是**加法或直接赋值**（`shim:1765 / 2836 / 2840-2842 / 2866 / 2884`），即 `0` 是**加法单位元**：

| 用法（改后行号） | 表达式 | 传 0 时 |
|---|---|---|
| `:1765` | `double lineContentStart = indentDip + paragraphIndentDip;` | `0`（原值） |
| `:1771` | `startPenX = indentDip`（网格锚） | `0`（原值） |
| `:1774` | `if (wb + paragraphIndentDip > width + 1e-9) break;` | `wb > width + 1e-9`（原判据） |
| `:2866` | `shaped.TotalWidthPx + indentDip` | `TotalWidthPx`（原值） |
| `:2884` | `indentDip + paragraphIndentDip` / 末参 `paragraphIndentDip` | `0` / `0`（原值） |

⇒ 既有调用点走的是**与修前逐位相同的算术**（`proven`，非推断）。

### 3.3 B · 应用器 `REPL_1`（PC 侧严格档调用点）

`src/…/patch-presentationcore-textline-fallback.py:92-126`。生成的只有**一处 hunk**（生成物 `:568-586`）：

```diff
@@ -568,7 +568,22 @@
                     settings.Pap.AlwaysCollapsible,
-                    settings.Pap.LineHeight      // 0 = 未设 ⇒ 托管侧用字体自然行高（真机口径）
+                    settings.Pap.LineHeight,     // 0 = 未设 ⇒ 托管侧用字体自然行高（真机口径）
+                    // ── WAVE19 §0.1 B（`P4` 的同波兄弟件）：**严格档也要收缩进** ──
+                    …（注释 11 行，见 §3.4 的"为什么"）…
+                    indentDip: paragraphProperties.Indent,
+                    paragraphIndentDip: paragraphProperties.ParagraphIndent
                     ) as TextLine;
```

**为什么取 `paragraphProperties.*`（原始 DIP）而不是 `settings.Pap.*`**：后者是**理想整数 ×300**。

| 来源 | 生成物行 | 单位 | 24 DIP 会变成 |
|---|---|---|---|
| `paragraphProperties.Indent` / `.ParagraphIndent`（本件、宽松档同源） | `:585-586`、`:610-611` | **原始 DIP** | **24** |
| `settings.Pap.Indent` / `.ParagraphIndent`（**禁用**） | 不出现（负断言挡） | 理想整数 = `RealToIdeal(DIP)` | **7200** |

**`paragraphProperties` 在不在作用域**：在 —— 它是 `FormatLineInternal` 的形参，生成物 `:519` 声明、`:524` 是 `TextParagraphProperties paragraphProperties,`，而严格档调用点在 `:565`（同一方法体内）。这也正是 W17B §2.2 对宽松档用同一手法时的依据；**同一来源、同一口径**两条腿都对（`proven`：编译通过 + 应用器正断言）。

### 3.4 应用器牙齿（正向 / 负向 / 计数），以及**它们的三次自我更正**

派单要求"positive assertions that the wiring is present, a negative assertion that the ×300 form is absent, and a count assertion on the number of sites"。我落的是：

**正向（`REQUIRED_IN_OUTPUT`，2 条新增）**
```python
("W19-B：站点1（**严格档**）从宿主对象取**原始 DIP** 的 Indent",
 "                    indentDip: paragraphProperties.Indent,\n"
 "                    paragraphIndentDip: paragraphProperties.ParagraphIndent\n"
 "                    ) as TextLine;"),
("W19-B：站点1 的 `settings.Pap.LineHeight` 仍逐字在位（没有被顺手改写/删除）",
 "                    settings.Pap.LineHeight,     // 0 = 未设 ⇒ 托管侧用字体自然行高（真机口径）"),
```

**负向（`generate()` 内，2 条）**
```python
if (_LH_LINE_OLD + "\n" + "                    ) as TextLine;") in out:   # ① 退回修前收尾形态
if _LH_LINE_OLD in out:                                                   # ② 无逗号形态（半接线）
```
其中
```python
_LH_LINE     = "                    settings.Pap.LineHeight,     // 0 = 未设 ⇒ 托管侧用字体自然行高（真机口径）"
_LH_LINE_OLD = "                    settings.Pap.LineHeight      // 0 = 未设 ⇒ 托管侧用字体自然行高（真机口径）"
```
**×300 缺席**这条由**既有的 P2 负断言**覆盖（我没有重复造）：应用器 `:672-680` 已有
```python
for bad, why in (("indentDip: paragraphIndent", "回退成坏接线：PI 又落进 `indentDip`（网格锚）槽"),
                 ("paragraphIndent: settings.Pap.ParagraphIndent", "回退成 v1 坏修法：`Pap.*` 是理想整数 ×300"),
                 ("indentDip: settings.Pap", "回退成 v1 坏修法：ideal 单位直传锚点槽（×300）"),
                 ("double paragraphIndent = 0", "旧形参名残留 ⇒ 半接线")):
```
⇒ 我的严格档实参一写成 `settings.Pap.Indent` 就会被它抓住（§4.3 T5 实测）。

**计数（3 条）**
```python
if (n_block, n_indent, n_para, n_args, n_lh_comma) != (1, 2, 2, 2, 1): …报错退出
```
|---|---|
| `n_block` | 站点1 专属整段（`LineHeight,` + W19-B 注释头）**恰好 1** |
| `n_indent` / `n_para` | `indentDip: paragraphProperties.Indent,` / `paragraphIndentDip: paragraphProperties.ParagraphIndent` 各 **恰好 2**（严格档 + 宽松档） |
| `n_args` | 缩进实参对收尾 `…\n) as TextLine;` **恰好 2** |
| `n_lh_comma` | `settings.Pap.LineHeight` 的**逗号形态** **恰好 1** |

**P2 的既有计数牙齿我按现场改了口径（留档，因为它是抓到我的那一条）**：原为
`if (n_indent_slot, n_para_slot, n_src_indent, n_src_para) != (1, 1, 1, 1)` —— `#19` B 之后 `n_src_indent/n_src_para` **必然是 2**（两条腿各一处），所以改成 `(1, 1, 2, 2)` 并在注释里写明**为什么**、以及"这不是牙齿坏了，是它按设计把'接线站点数变了'逼出来了"（它当时输出 `来源 indent/para=2/2（要求 1/1）` 并 `rc=1`）。

**我自己的三版错牙齿（纪律 3/25 要求的形状：牙齿必须能真红 —— 这里三次都是它抓住了我）**

| 版本 | 我写的判据 | 实测行为 | 结论 |
|---|---|---|---|
| v1 | 「`settings.Pap.LineHeight\n … ) as TextLine;` 必须 0 处」 | **恒不出现**（修前形态的 `LineHeight` 后面跟着**行尾注释**，不是裸换行）⇒ 这条**永远绿** | **假牙齿**，作废 |
| v2 | 缩进实参对（3 行、**不带站点锚**）恰好 **1** 处 | 实测 **2** —— **宽松档那一段的结尾逐字相同**（`REPLACEMENT_4` 同缩进、同 `) as TextLine;`）⇒ 当场报红 | **假红**，作废 |
| v3 | `LineHeight,` 逗号形态恰好 **2** 处（"两个站点各一"） | 实测 **1** —— 站点2（min/max 兜底）**根本不传 `LineHeight`**（`generated:700-701` 的宽松 min/max 调用结尾是 `out lenientMin, out lenientMax))`）⇒ 我是**从"两个站点"推断出来的数字，不是数出来的** | **假红**，作废；数字改成现场数出来的 1 |
| v4（在用） | 见上 §3.4 三条 | 6 条注错全部报红（§4.3） | 采用 |

---

## 4. 编译证据（**私有输出目录**，纪律 33）+ 牙齿两极化

### 4.1 主工程

```bash
export PATH="$HOME/.dotnet:$PATH"          # ⚠️ SDK 不在默认 PATH（dotnet 10.0.111 @ ~/.dotnet）
dotnet build -m:1 build/PresentationCore.Linux/PresentationCore.Linux.csproj \
  -p:BaseOutputPath=$HOME/w19a-build/bin/ -p:BaseIntermediateOutputPath=$HOME/w19a-build/obj/
```
```
WPF-on-Linux: HbTextLineShimSha=fe1b7ed8fa3ed23144326740f41227e53cf1a772c7b48f4d8b27b4a972b7068f （源 …/build/shims/PresentationCore.HbTextLine.cs）→ …/HbTextLineShimSha.g.cs
已成功生成。  0 个警告  0 个错误        已用时间 00:00:33.97
BUILD_RC=0     error CS = 0     warning CS = 0
```
私生产物 `$HOME/w19a-build/bin/Debug/PresentationCore.dll` = **`55d1846ac9a4bba4`**（4,196,352 B）。
**内嵌 sha 自证**：`strings -a` 读到 `HbTextLineShimSha@fe1b7ed8…b7068f`，与当前 shim 的整文件 sha **逐字符相同** ⇒ **我这一版产物确实含 W19A 的 shim**（正控，不是"我以为编进去了"）。

### 4.2 两个非 DIRECT 宿主 + CoverageProbe

| 工程 | 命令差别 | 结果 | 产物 |
|---|---|---|---|
| `CoverageProbe` | 只用 `-p:BaseOutputPath/…IntermediateOutputPath` | **0 错误 0 警告** | `…/CoverageProbe/bin/Debug/PresentationCore.Tests.dll` |
| `TextLineProto` | 需多传 `-p:CustomAfterMicrosoftCommonProps=…/excl.props` | **0 错误**（52 警告 CS0436，**既有**类型冲突噪声） | `…/TextLineProto/bin/Debug/MilBridge.TextLineProto.dll` (93,184 B) |
| `HbTextLineParity` | 同上 | **0 错误 0 警告** | `…/HbTextLineParity/bin/Debug/MilBridge.HbTextLineParity.dll` (159,232 B) |

**⚠️ 我一开始对后两个报了 `16 × CS0579`，并已查明这与本件无关（proven，不是"归因于环境"的搪塞）**：

```bash
# 拿**修前的 shim 备份**做同一个私有重定向构建 —— 错误**完全一样**
dotnet build …/TextLineProto.csproj -p:HbShimSrc=$S/backup/PresentationCore.HbTextLine.cs.before \
  -p:BaseOutputPath=$HOME/w19a-probe/bin/ -p:BaseIntermediateOutputPath=$HOME/w19a-probe/obj/
⇒ 32 error CS0579（**全是 CS0579，无其它错误码**）
```
根因（现场查出）：这两个 csproj **没有** `EnableDefaultCompileItems=false`（`CoverageProbe` 有，`:33`），而它们的 `BaseIntermediateOutputPath` 是**项目内**字面量（`TextLineProto.csproj:17` `$(MSBuildThisFileDirectory)obj\`），于是**项目里那份陈旧的 `obj/Debug/*.AssemblyInfo.cs` 被默认 glob 收进编译**，与 SDK 生成的那份撞车：

```bash
dotnet msbuild …/TextLineProto.csproj … -getItem:Compile | grep AssemblyInfo
⇒ obj/Debug/TextLineProto.AssemblyInfo.cs、obj/Release/TextLineProto.AssemblyInfo.cs … 共 6 项
```
⇒ **`CS0579` 是"私有 obj 重定向 + 这两个工程缺 `EnableDefaultCompileItems=false`"的产物，与 W19A 的改动无关**（同一个命令、同一套参数、只换 shim 源，错误码与条数不变）。我**没有改这两个 csproj**（不在写域），改用**只对 glob 生效**的注入（不碰任何仓库内文件）：

```xml
<!-- $HOME/wfp-runs/w19-laneW19A/excl.props （只在命令行注入，不落进仓库） -->
<Project><PropertyGroup>
  <DefaultItemExcludes>$(DefaultItemExcludes);obj\**;bin\**</DefaultItemExcludes>
</PropertyGroup></Project>
```
```bash
dotnet msbuild … -p:CustomAfterMicrosoftCommonProps=$S/excl.props … -getItem:Compile | grep -c AssemblyInfo  ⇒ 0
dotnet msbuild … 同上 | grep -c "Program.cs"                                                                  ⇒ 2（入口没被误删）
```
自证有效后两个工程才编过。**注**：`EnableDefaultCompileItems=false` 单独用**不行**（会把 `Program.cs` 一起剔掉 ⇒ `CS5001: 不包含适合于入口点的静态 Main`，我实测到并放弃该写法）。

### 4.3 牙齿两极化（正/负两趟，逐条注错都报红）

`$S/teeth/mutate.py` 在 **`REPL_1` 字面量区域内**（区域外一律不动）做定点注错，并且**注错失败就中止**（我第一次实现了"注错失败但脚本继续跑"，于是一条陈旧突变被当成结果 —— 已修掉，见 §7.3）：

| 注错 | 注的是什么坏形态 | 应被哪条牙齿抓 | 实测 | rc |
|---|---|---|---|---|
| **T1** | 删光缩进实参、保留行尾注释 ⇒ **修前收尾形态** | 正断言（`LineHeight,` 形）+ 负断言① | `[失败] 生成物缺少结构断言：W19-B：站点1 的 settings.Pap.LineHeight 仍逐字在位` | **1** |
| **T2** | 只把逗号去掉、实参留着 ⇒ **半接线** | 同上 | 同 T1 的具名失败 | **1** |
| **T3** | 删掉站点1 专属注释块 | **计数牙齿③** `n_block=0` | `[失败] W19-B 计数牙齿③：站点1 专属整段 = 0（要求 1）…` | **1** |
| **T4** | 站点1 的来源改成常量 `0.0` | **P2/W19-B 来源计数** | `[失败] P2/W19-B 接线计数不对：…来源 indent/para=1/2（要求 2/2…）` | **1** |
| **T5** | 站点1 写成 `settings.Pap.Indent`（**×300 坏修法**） | **既有 P2 负断言** | `[失败] 生成物里出现**被禁用**的写法：回退成 v1 坏修法：ideal 单位直传锚点槽（×300）（indentDip: settings.Pap）` | **1** |
| **T8** | **新形态与修前形态并存**（尾巴残留） | **负断言①**（唯一能走到它的路径） | `[失败] W19-B 负断言①：站点1 又退回**不收缩进**的修前形态…` | **1** |

**为什么需要 T8**：T1/T2 都**先被更早的 `REQUIRED_IN_OUTPUT` 挡住**（`_LH_LINE` 的逗号形态消失），走不到负断言①。T8 在**保留**新形态（所有 REQUIRED 串都在）的同时插入修前形态的尾巴 ⇒ **只有负断言①能看见它**，实测报红 ⇒ ①**不是死代码**。
**两极化对照（不注错）**：
```
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py --check   ⇒ rc=0
python3 … （无参，应用）                                                                     ⇒ rc=0
```
**改前 `--check` 的形态留档**（免得把"改前也 rc=0"当证据）：改应用器后**第一次** `--check` 是 **`rc=1`**，输出 `[失败] P2 接线计数不对：透传 indent/para=1/1（要求 1/1）、来源 indent/para=2/2（要求 1/1）` + `[检查] …：缺失/与上游不同步（需要重新生成）` —— **这条既有牙齿当场拦下了我的改动**。
**应用器恢复**：`cmp` 逐字节 + sha16 双证：`daa1fe2a32d454cf == daa1fe2a32d454cf`，`cmp: identical`。

### 4.4 默认形参 = "既有调用点逐位等价"的**机器证明**（反编译级读回）

`$S/DefaultArgProbe/`（我自己的 scratch 工程，命名 `PresentationCore.Tests` + 公钥签名借 IVT）用**反射读元数据**，再**同一个探针二进制、就地换掉同目录的 `PresentationCore.dll`** 做正/负控：

| 读法 | 载入的 pc | `TryFormatLine` 形参表 | 2 个新形参 |
|---|---|---|---|
| **正控**（我的私生 `55d1846ac9a4bba4`） | `…/DefaultArgProbe/bin/Debug/net10.0/PresentationCore.dll` | `paramCount = 8`；`TryFormatLine(TextSource, Int32, Double, Double, Boolean, Double, Double, Double)` | `6 indentDip : Double optional=True default=0`、`7 paragraphIndentDip : Double optional=True default=0` ⇒ `ASSERT last-two-optional-double-default-0.0 = PASS` |
| **负控**（**权威** `pc` `663114436443d2de`，修前产物） | 同上（就地换成权威件后重跑） | `paramCount = 6`；`TryFormatLine(TextSource, Int32, Double, Double, Boolean, Double)` | **没有第 7/8 个形参** ⇒ `ASSERT … = FAIL` |

⇒ ① 我的改动**确实进了产物**（正控 8 形参）；② 权威 `pc` 是**修前形态**（负控 6 形参，**无任何缩进形参**）⇒ §1 那句"默认形参保既有调用点逐位等价"有**元数据级**证据，而不是"我认为默认值会让它等价"。`optional=True` 也直接证明"既有 6 实参调用点**不需要改**就编得过"（这正是 `CoverageProbe` 4 处调用点一个字节没动却能编过的原因）。

### 4.5 确定性（同 obj 路径复现；纪律 `D-R6`）

```
rm -rf $HOME/w19a-build/obj && rebuild（同一 BaseOutputPath/BaseIntermediateOutputPath）
run A sha16 = 55d1846ac9a4bba4
再 rebuild（同路径）                      run B sha16 = 55d1846ac9a4bba4   ⇒ PASS
另一 obj 路径（$HOME/w19a-build2）         sha16 = 0d9f6391a6f889f1          ⇒ 与 A 不同
```
⇒ 同 obj 路径可复现；**跨 obj 路径不可比**（obj 路径嵌进产物）—— 与 `D-R6` 登记口径一致。**报告里任何私生 sha 只在本车道的 `$HOME/w19a-build/` 路径下有效。**

---

## 5. 预测表（**在取任何测量之前写下**）+ 我没取的读数

### 5.1 本件应当改变的（预测）

| # | 量 | 预测 | 依据 |
|---|---|---|---|
| P1 | `shim` 源 sha | **必变**（`bc04c05ab6d8d82a` → 新） | A、B 都改这个文件 |
| P2 | 生成物 sha | **必变** | 应用器 `REPL_1` 改了（+20 行） |
| P3 | 权威 `pc`（重建后）sha | **必变**，且**与行为无关** | `HbTextLineShimSha.targets:58` 把 **shim 整文件 sha** 编进 `AssemblyMetadata` ⇒ 注释也改字节（§2 的实测） |
| P4 | 权威 `pc` 内嵌 `HbTextLineShimSha` | **必变成新 shim sha** | 同上 |
| P5 | `ShimShaReader` 的读数 | 应从 `SHIM_SHA=no`（相对权威产物）**变**为"与源一致" | 上述机制跟着重建走（预登记 §3.7 的预期） |
| P6 | **严格档腿**（`WPF_LINUX_TEXTLINE_FALLBACK` **不设** ⇒ 默认先走严格档）的非 0 缩进例 | **应当由红转绿**：`Indent`/`ParagraphIndent` 不再被丢 ⇒ 网格锚与内容起点都对上 oracle | B 的接线；`W17B §7.6` 的同形 |
| P7 | 零缩进例 | **逐位不动**（默认 0 = 加法单位元，§3.2） | §3.2 的用法表 |
| P8 | 严格档的接手计数（`Handled/Bailed`） | **不应下降**（本件只多传 2 个实参，不改接管条件） | `TryFormatLine` 的 bail 判据一行未动 |
| P9 | 应用门禁 6/6 `result=PASS`、`drawn/colors/frames/cross_ae/leftover_after` | **逐位不变** | 前提：`samples/**` 对 `Indent`/`ParagraphIndent` 全 0 命中（`#17` 实测过，**本波须复读一次** —— 预登记 §1 B 点名） |
| P10 | 其余七支臂 / `tline` 六项 | **逐位不变** | 同上 |

### 5.2 本件**不许**改变的（预测）

- **既有调用点的行为**：`CoverageProbe` 的 4 处 6 实参调用（`:207/228/243/442`）、`PcLineOracle`、生成物里 **min/max**（`TryMinMaxParagraphWidth`，`:688`/`:700`）—— 一律走默认 0 ⇒ 逐位等价（§3.2 的算术证明 + §4.4 的元数据证明）。
- **宽松档**（生成物 `:596-611`）—— 一个字未动（`generated.diff` 只有 1 个 hunk，落在 `:568`）。
- **`new TextMetrics.FullTextLine(` 站点数 = 2**、`throw` 条数 = 4（应用器既有断言，两趟都过）。
- **`D-T2-c`**：min/max 两探针的 `modifierScopeEnd = -1` 已知错**未被顺手改**（我没碰那段）。

### 5.3 ⚠️ 我**没有**取的读数，以及为什么（不许读成"已验"）

| 没取 | 为什么 |
|---|---|
| **严格档腿的红证/绿证（P6/P8）** | **`build/MilBridge/tests/PcLineOracle/**` 归 W19B 车道**（`docs/CURRENT-STATE.md:370` 明确列了 W19B + 该路径），且它在我作业期间**正在被改**（`Program.cs` mtime `09-16 15:26:10`，72,948 B，**晚于我的改动**）。派单也明说"you cannot run the arm (another lane owns it)"。⇒ **本件对行为零读数**，P6/P8 是**预测**，不是结论。 |
| **权威产物（pc 重建、五臂重取、登记表重钉、门禁两极化、`verify-all`）** | 派单禁止我写权威产物；而且另一车道正在拿权威 `pc 663114436443d2de` 取**修前**读数 ⇒ 我一旦重建就把它的读数作废。 |
| **应用门禁 6/6（P9）** | 需要重建权威 `pc`（同上）+ 常驻 `Xvfb :97`；属主控的 `close-wave.sh`。 |
| **`tline` 六项 / 其余七支臂（P10）** | 需要权威产物 + 五臂重取装置。 |

---

## 6. 读数表

### 6.1 环境

| 项 | 值 |
|---|---|
| lane | **W19A** |
| 开工 | `2026-09-16T15:22:29+08:00`｜`loadavg 0.56 0.88 1.34`｜`MemAvailable 3128 MB` |
| 收尾 | `2026-09-16T15:33:11+08:00`｜`loadavg 11.66 6.67 3.72`｜`MemAvailable 2780332 kB` |
| kernel | `6.8.0-138-generic`（`uname -r`） |
| SDK | `dotnet 10.0.111` @ `/home/links-dev/.dotnet/dotnet`（**不在默认 PATH**，已 `export`） |
| 构建方式 | 全部 `-m:1` + **私有** `BaseOutputPath/BaseIntermediateOutputPath` |

### 6.2 件 sha / 字节 / mtime（最终形态）

| 件 | sha16 | 字节 | mtime |
|---|---|---|---|
| `build/shims/PresentationCore.HbTextLine.cs` | `fe1b7ed8fa3ed231` | 278,692 | 2026-09-16 15:30:15.645713935 +0800 |
| `src/…/patch-presentationcore-textline-fallback.py` | `daa1fe2a32d454cf` | 52,168 | 2026-09-16 15:31:55.755185512 +0800 |
| 生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` | `799e0366b312ec65` | 55,223 | 2026-09-16 15:31:51.807238383 +0800 |
| 权威 `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` | `663114436443d2de`（**未变**） | 4,196,864 | 2026-09-16 15:09:34.759810754 +0800 |
| 私生 `$HOME/w19a-build/bin/Debug/PresentationCore.dll` | `55d1846ac9a4bba4` | 4,196,352 | 2026-09-16 15:33 前 |
| 上游 `TextFormatterImp.cs`（只读） | — | — | 应用器 `[锚点]` 5 处各 1 次 |

### 6.3 本车道的读数产物（`$HOME/wfp-runs/w19-laneW19A/`）

| 路径 | 内容 |
|---|---|
| `backup/PresentationCore.HbTextLine.cs.before` | `bc04c05ab6d8d82a` / 275,765 |
| `backup/patch-presentationcore-textline-fallback.py.before` | `188f75a67294138f` / 44,274 |
| `backup/TextFormatterImp.Linux.cs.before` | `56a5b4a5be1c6bcc` / 53,783 |
| `applier.W19A.py` | **权威 W19A 应用器** `daa1fe2a32d454cf`（牙齿的恢复基准） |
| `shim.after.cs` / `generated.after.cs` / `applier.after.py` | 中间快照（`applier.after.py` = `21460e9f3a997415`，**行号注释更正前**） |
| `shim.diff` / `applier.diff` / `generated.diff` | 逐字 diff（63 / 131 / 26 行） |
| `teeth/mutate.py` + `mutate T1..T8` | 牙齿两极化的注错装置（区域限定、注错失败即中止） |
| `excl.props` | 只命令行注入的 glob 排除（**不落进仓库**） |
| `DefaultArgProbe/` | 元数据读回探针（`P.cs` + csproj，`PresentationCore.Tests` + 公钥签名） |
| `nc2/`、`nc3/` | 我**失败/作废**的负控尝试（§7.4 留档，防止有人把它们的输出当证据） |

### 6.4 写域边界（逐件复核，**我都没碰**）

`CoverageProbe/Program.cs` = `a8727a5bed6bf049`（09-15 17:24）｜`CoverageProbe.csproj` = `ca59c52fb12a050c`｜`known-red.json` = `f9843bde351029dc`｜`tline-gate.sh` = `b37a5c9f55ae71a4`｜`verify-all.sh` = `a68823631e8f8919`｜`integration-wave.sh` = `1172784c38fb8e31`（09-16 15:06，**他车道**）｜`Win32ShimResolver.cs` = `0735327b6ca3ae4b`（09-16 15:06，**他车道**）。
`PcLineOracle/**` 我**只读**：`Program.cs` mtime 09-16 **15:26:10**（72,948 B）晚于我的 shim 改动（15:23）⇒ 是**另一车道**写的。

### 6.5 权威产物"全程未动"的逐次留档

开工前 `663114436443d2de`；PC 私有构建前后各一次、三次确定性构建前后、最终构建前后、报告收尾 —— **每次都是 `663114436443d2de`**，mtime 恒为 `09-16 15:09:34.759810754`。

---

## 7. 我推翻 / 更正的东西（含我自己的三条错）

### 7.1 预登记 §1 A 的判据有一半**在本波不可能成立**（`proven`，已实测更正）

预登记 §1 A 写：「`shim` 的 sha **变**、`pc` 因重建而变；**所有判据读数逐位不变**（依据 = `#17` 的实测：**注释不进元数据** —— 纯注释短语与局部变量名在 DLL 里**处处 0 命中**）」。
**"注释不进元数据"这条依据本身是对的，但被用错了范围**：`build/PresentationCore.Linux/HbTextLineShimSha.targets:58` 会把 **shim 源文件的整文件 sha256** 写成 `[assembly: AssemblyMetadata("HbTextLineShimSha", …)]` ⇒ **一行注释也会改 `pc` 的字节**。
**实测证据**（同一 obj 路径、同一命令、只差 shim 里一句注释 `见下方 getter 的逐行注释` → `见 getter 体内的逐行注释`）：
```
改前私生 pc sha16 = 32533cae0dcb50c3
改后私生 pc sha16 = 4fb7baada9d22a3f      ← 只改了一句注释，dll 就变了
```
⇒ 结论要**分成两层**：**行为**读数应逐位不变（这是纪律要保的），**产物 sha 一定变**（且 `ShimShaReader` 会因此报"与源一致"）。**不要把"pc sha 变了"读成"行为被改动了"**，也不要用"注释不该动产物"去反推 §7.2 的位移。

### 7.2 应用器既有的一条 P2 计数牙齿**必须改口径**（它当场拦住了我）

`#17` 时"缩进来源"只有**宽松档一处** ⇒ 牙齿要求 `n_src_indent == n_src_para == 1`。本件给**严格档**也接上同一来源 ⇒ **必然是 2**。`--check` 当场输出
`[失败] P2 接线计数不对：透传 indent/para=1/1（要求 1/1）、来源 indent/para=2/2（要求 1/1）` 并 `rc=1`。
⇒ 我**没有**把这当成"牙齿坏了"而删掉它，而是改成 `(1, 1, 2, 2)` 并注明这是设计行为（"接线站点数变了"就该被逼出来）。

### 7.3 我自己的仪器事故：**注错失败却继续跑 ⇒ 一条陈旧突变被当成结果**（已修）

牙齿两极化第一版脚本里，我做的是 `python3 mutate.py … ; cp mut.py $APPLIER` —— **`mutate.py` 因断言失败退出时，`cp` 仍然执行**，把**上一轮**留下的突变文件当成"这一轮"的输入 ⇒ 我一度看到"T1/T2 报红"其实是 **T3 遗物造成的**（两轮的报红行**逐字相同**，正是破绽）。
**修法**：把注错与执行分开，**注错失败就 `continue`**，并在注错器里加 `assert r != region`（"突变必须是真突变"）。修后 6 条注错的报红行**各不相同**（§4.3 表），不再是同一行。

### 7.4 我作废的两轮负控尝试（**留档，防止有人把它们的输出当证据**）

- `$S/nc2/`：我用 `-p:PcPath=<权威件>` 指了权威 `pc`，但**探针输出目录里落下的仍是 `32533cae`（我的私生件）**，而权威那份**根本没被拷进输出目录**（`sha256sum` 报"没有那个文件"）；那次运行 `rc=134`。
  ⇒ 结论：**那个 `PcPath` 手法不可靠**（`Reference`/`HintPath` 的解析被别的东西接管），**不许用它取负控读数**。我最终改用"**同一个探针二进制、就地换同目录的 `PresentationCore.dll`**"（§4.4），这才是可靠的负控 —— 并在同一个探针里**印 `pc.Location`** 自证读的是哪一个文件（这条"读哪一份"的自证是 `#17`/W18 那类事故的直接对策）。
- `$S/nc3/`：我用 `ForcePc` target 强制把指定 pc 拷进输出目录，拷是拷对了（`663114436443d2de`），但探针在 `pc.GetType("WpfLinux.Shims…HbTextFallback")` 之前就被 `PresentationCore` 的**模块初始化器**打死：`TypeInitializationException → FileNotFoundException: DirectWrite.Linux.Provider`（provider 虽在目录里、但不在 `deps.json` 里 ⇒ 探针的宿主不认它）。
  ⇒ 结论：**平台探针要读 PC 的内部类型，必须让 PC 由正常的 `Reference` 机制进入输出目录**（这套 `deps.json` 是必需的，不能靠手工 `Copy` 伪造）。

### 7.5 一条**我确认预登记写对了**、值得记下的现场事实

预登记 §0.1 B 说"严格档形参表里根本没有 indent" —— 现场重读修前 shim `bc04c05ab6d8d82a:4496-4497` 逐字为
`internal static TextLine TryFormatLine(TextSource textSource, int cpFirst, double paragraphWidth, double pixelsPerDip, bool alwaysCollapsible, double lineHeight)` ⇒ **成立**；并且 §4.4 的负控**在产物级**再证一次（权威 `pc` 读回 6 形参）。**预登记这条没有漂。**

### 7.6 一处**行号漂移**（纪律 4 的现场，供后续车道取锚点用）

派单/预登记引的"生成物 `:565-572`"改成"`:575` 那条宽松兜底"等锚点，在**本件落地后**全部漂了。最终形态：

| 锚点 | 最终行号 |
|---|---|
| `HbTextFallback.TryFormatLine(` 调用（严格档） | **`:565`**（未漂） |
| 严格档缩进实参 | **`:585-586`** |
| `WpfLinuxLenientTextFallback.TryFormatLine(`（宽松档） | **`:596`** |
| 宽松档缩进实参 | **`:610-611`** |
| min/max 兜底（严格档 / 宽松档） | **`:685-693`** / **`:700-701`** |
| `FormatLineInternal` 声明 / `paragraphProperties` 形参 | **`:519`** / **`:524`** |
| shim `TryFormatLine` 签名 / 转发 | **`:4522-4524`** / **`:4549-4553`** |
| shim `HasOverflowed` | **`:3421`**（getter 体 `:3425-3430`） |

（我在生成物注释里写的 `:524`/`:610` 是**改后**的行号，已现场核过；`applier` 里曾写 `:595` 是漂移值，已在收尾前更正为 `:610`。）

---

## 8. 主控必须验的（**不是我的读数的替代品**）

1. **重建权威产物**（我**没有**执行，命令原文如下）：
   ```bash
   export PATH="$HOME/.dotnet:$PATH"
   dotnet build -m:1 build/PresentationCore.Linux/PresentationCore.Linux.csproj   # 写 build/PresentationCore.Linux/bin/Debug/
   dotnet build -m:1 build/WindowsBase.Linux/WindowsBase.Linux.csproj            # shim 是 [ModuleInitializer]，编进 4 个程序集
   dotnet build -m:1 build/UIAutomationTypes.Linux/… / build/UIAutomationProvider.Linux/…
   ```
   且按预登记 §3.2 用 `close-wave.sh`（**预期 `native_rebuilt=0`、`bridge_republished=0`** —— `src/WpfGfx.Linux/**` 本件未动）。
2. **⚠️ 重建后 `pc` 的 sha 必变、且内嵌 `HbTextLineShimSha` 必等于 `fe1b7ed8fa3ed231…`** —— 若内嵌值不是这个，说明 `pc` 不是用本件的 shim 出的（§4.1 有我私生件的正控可照抄：`strings -a … | grep HbTextLineShimSha`）。
3. **五臂重取**（`ln -f` 硬链接，**绝不 `cp`**）；**登记表重钉到 `generation.id=#19`**；**门禁两极化重做**（删 1 条 ⇒ `rc=1`；恢复 ⇒ `rc=0`）。**本件可预测的位移**（§5.1 P1–P5）：`shim`/`pc`/`windowsbase`/`uiatypes`/`uiaprovider`/`inputs_fp` **变**；所有**行为**读数**不变**。
4. **严格档腿的两极化（P6/P8）** —— 归 **W19B** 的 `PcLineOracle`（去掉 `WPF_LINUX_TEXTLINE_FALLBACK` ⇒ 默认先走严格档）。**本件落地后我预期**：非 0 缩进例由红转绿、零缩进例逐位不动、严格档接手计数不下降。**若仍红 ⇒ 说明严格档这条路对缩进仍不可观测**（那是 `WAVE19 §1 B` 的"红则停"条款要处理的分支，**不许**把红读成"已修"）。
5. **应用门禁 6/6 + `verify-all` 10 步**；并**复读一次** `samples/**` 对 `Indent`/`ParagraphIndent` 的命中数（预登记 §1 B 点名"本波须复读一次"；`#17` 的实测是 0 命中 —— 我**没有**取这条读数）。
6. 若发现我上面任何一条与现场不符，**以现场为准**并回告。

---

## 9. 口径与纪律自查

| 纪律 | 本件状态 |
|---|---|
| 3（红检测只许加强） | 牙齿 6 条全部两极化证过；**没有任何一条是"永远绿"**（v1 那条假牙齿已被我自己识别并作废，§3.4） |
| 4（锚点会漂，现场重读） | 所有 `:NNNN` 都现场重读；§7.6 列出漂移后的真值 |
| 16（先备份再改） | 3 个文件全部 `cp -p` 备份 + before sha16/字节/mtime 记录在 §2 |
| 21/27/28（缺数据 ⇒ NOINFO，不许绿；不可测须如实登记） | §5.3 逐条列出**我没取的读数与原因**；本报告**不报任何行为绿** |
| 22（量不出来报 `NA(source=…)`） | §5.3 + §4.4 的负控"6 形参"即 `NA` 的产物级形态 |
| 25（计数要有正控） | 牙齿计数各配一条注错正控（§4.3）；§4.1 内嵌 sha 自证"产物确实含本件" |
| 31（门禁形态可能是设计而非缺陷） | 未碰门禁；§8 说明重取前的 `tree_gen=advanced` 是设计 |
| 32（读数记录谁跑的） | 表头 lane/时刻/loadavg/MemAvailable/kernel 齐 |
| 33（`--check` rc=0 **不是**"能编译"） | 编译证据独立给出（§4.1/§4.2，`error CS = 0`），且**明确不把 `--check` 当编译证据** |
| 34（不许动 `CoverageProbe/**`） | `Program.cs` = `a8727a5bed6bf049` **未变**（§6.4）；我只是**编译**了它 |
| `proven`/`not proven`/`not measurable` | 逐条标注；§5.3 的 P6–P10 全部标为**预测/未取** |

**一句话交底**：**A、B 落地且各自有机器证据，编译通过；但本件的行为效果（严格档那条腿）我一个字都没量 —— 那是 W19B 的臂与主控的权威重建要回答的问题。**

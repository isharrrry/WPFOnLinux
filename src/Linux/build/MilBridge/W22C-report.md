# W22C · `D-T6-b` 帧判据 + 红读数 + 落地方案（`docs/WAVE22-PREREGISTRATION.md` §3 P3）

> **lane=W22C**｜时间 **2026-09-16 19:41 → 20:30 +0800**｜`kernel` **6.8.0-138-generic**｜`loadavg` 3.12→1.07（区间 0.22–3.12）｜`MemAvailable` 3,555,156 → 3,218,720 KiB｜`nproc=3`
> `DISPLAY=:97` = **UP**（`xdpyinfo` 实测，未自起 Xvfb）｜全程**未** `pkill -f`（只按 PID）
> **本件只交三样**：**判据** + **红的读数** + **落地方案（diff 草案，未施加）**。**未修改任何既有文件**：`build/shims/**`、`build/PresentationCore.Linux/**`、`PcLineOracle/**`、`known-red.json`、`verify-all.sh`、`arm-logs/` **逐一未动**（见 §9 的逐件自证）。
> 新建件只有两个：`build/MilBridge/tests/FrameProbe/{Program.cs,FrameProbe.csproj}` + 本报告。

---

## §0 一句话结论

**帧缺陷为真、可点名、两档都能红，且它的"准法律形式"不是预登记写的那条。**

| 腿（`--leg b` = `AlwaysCollapsible=true`，与 `PcLineOracle` 汇总腿同层） | 判定行 | **红行** | 绿行 | 其中**帧红** | 其中**结构红** |
|---|---|---|---|---|---|
| **宽松档**（缺省行为） | 421 | **133** | 288 | **133** | 0 |
| **严格档**（`--tier strict`） | 421 | **3** | 418 | **0** | **3** |
| 严格档 + `--fresh-source`（缓存必不命中） | 421 | **133** | 288 | 133 | 0 |
| 严格档 + **`--prefix 40`**（`cpFirst≠0` 的源，**本件新增的必做读数**） | 421 | **421** | 0 | **421** | 0 |
| 宽松档 + `--prefix 40` | 421 | **421** | 0 | 421 | 0 |

**分母口径（纪律 39）**：语料 `tests/parity/windows/tab-anchor/out/tab-anchor-raw.json` sha16 **`88559d670f1bb955`**（1,196,289 B）共 436 例 / 615 行；**本件可判定的 = `script==latin` 的 288 例 / 421 行**（与 `PcLineOracle` 既有「421 判定行」同一口径）。全部预测数**按 421 行口径**写。
**注意**：报告里一律**不**把 `Start`（`paragraphStartOffsetDip`）的红算作帧的红 —— 那是**另一列**（`#21` 已修，只吃 `_paragraphIndentDip`）。

---

## §1 探针设计（`build/MilBridge/tests/FrameProbe/`）

### §1.1 它量什么

逐行比较两侧**同一套坐标系**里的量：

| 侧 | 量 | 出处 |
|---|---|---|
| **我方帧** | 该行自己的**段落系帧原点** = 最小的、能取到非空 `TextRunBounds` 的段落系下标 `a` | 扫描 `line.GetTextBounds(a,1)`，`a = 0,1,…,cpFirst+16` |
| **真机真值帧** | `cases[].lines[].startChar` | 真机臂 `tests/parity/windows/tab-anchor/src/Program.cs:556` `["startChar"] = lineStart`，而 `lineStart` 就是 `:443` 传进 `FormatLine(source, index, …)` 的 **`index`** ⇒ **绝对段落系**下标 |

**为什么"最小可用 `a`"恒等于 `_lineStart`**（仪器等价性，不是我拍的）：`shim:3043-3045`
```
3043: // ⭐ 真机口径（oracle `indexFrames.GetTextBounds_firstArg`）：第一个参数是**段落系**索引，
3044: int localFirst = firstTextSourceCharacterIndex - _lineStart;
3045: if (localFirst < 0 || localFirst > _visibleLength) return new List<TextBounds>();  // 与本行不相交
```
⇒ `GetTextBounds(a,1)` 非空 **⟺** `a ∈ [_lineStart, _lineStart+_visibleLength]` ⇒ 最小值 = `_lineStart`。

**⚠️ 这条等价性依赖我方"不相交 ⇒ 返回空表"这个行为**，而**真机是夹取**（`upstream/…/MS/internal/TextFormatting/FullTextLine.cs:1493-1501`）：
```
1493:  if(firstTextSourceCharacterIndex < _cpFirst)
1494:  {
1495:      textLength += (firstTextSourceCharacterIndex - _cpFirst);
1496:      firstTextSourceCharacterIndex = _cpFirst;
1497:  }
1499:  if(firstTextSourceCharacterIndex > _cpFirst + _metrics._cchLength - textLength)
1500:  { textLength = (_cpFirst + _metrics._cchLength - firstTextSourceCharacterIndex); }
```
⇒ **本扫描是我方专用仪器**（在真机上任何 `a` 都能拿到 bounds，扫不出帧）。故探针**同时**用 `HbTextLine.LineStartForDiag`（`shim:3283` `internal int LineStartForDiag => _lineStart;`，走 IVT 名额）**+ 反射**做**三方交叉验证**，并把"扫描 == 私有字段"当**仪器自证**逐例计数（见 §2 的「仪器自证」行）。

### §1.2 调用姿势（与既有臂同形，刻意不发明新姿势）

`TextFormatter.Create()` + `FormatLine(src, index, pw, para, brk)` 循环 + `index += (int)line.Length` + `GetTextLineBreak()`；宿主 = **逐字抄自 `PcLineOracle/Program.cs:95-113`** 的 `MockTextSource`（单 run `TextCharacters` → `TextEndOfParagraph`，与 oracle 宿主 `StringSource` 同形）；字体面 = `Liberation Sans`（**与 `PcLineOracle:176` 同一个面** ⇒ 读数可对拍）；覆盖闸 = 已解析 `GlyphTypeface.CharacterToGlyphMap`（`PcLineOracle:1511-1519` 口径）。
`D-R8`：本工程用**默认 glob**（不开 `EnableDefaultCompileItems=false`）⇒ 按 `BuildHygiene.props:47` 加了**一行** `<Import Project="$([MSBuild]::GetPathOfFileAbove('BuildHygiene.props'))" />`。

### §1.3 两个档位旋钮 + 一个**新**旋钮

| 旋钮 | 做法 | 出处 |
|---|---|---|
| `--tier lenient` | 进程内置 `WPF_LINUX_TEXTLINE_FALLBACK=0` | 抄 `PcLineOracle` 的 `TierSelect` 段 |
| `--tier strict` | 把该 env **清掉** | 同上 |
| `--fresh-source` | **每次 `FormatLine` 新建 `TextSource`** ⇒ 严格档 `ParaCache` 的 `ReferenceEquals(c.Source,…)` **必不命中** | 抄 `StrictTierProbe:256` |
| **`--prefix <N>`（W22C 新增）** | 源串 = `'M'×N + 用例文本`，**首调下标 = N** ⇒ **段落原点 ≠ 0**；真值帧 = `N + startChar` | 主控口径插话 ②③ 要求的必做读数 |

**档位来源自证**（每趟都印，两档都印）：严格档 `HbTextFallback.{Enabled,Calls,Handled,Bailed,lastBail}`（IVT，命名空间 `WpfLinux.Shims.PresentationCore`）＋ 宽松档 `MS.Internal.TextFormatting.WpfLinuxLenientTextFallback.Diagnostics`（IVT，**命名空间不同，必须现场读**）＋**逐例**「哪一档接手的」增量归因。两档增量都为 0 ⇒ `rc=2 NOINFO`（不许读成绿）。

**rc 词表**：`0` 全绿｜`1` 有红行｜`2` NOINFO（语料/字体取不到、没有一行可判定、两档都没接手）。

---

## §2 两条腿的红读数（原样）

**命令形态**（绝对路径；`D` = `build/MilBridge/tests/FrameProbe/bin/Release/PresentationCore.Tests.dll`，`C` = `tests/parity/windows/tab-anchor/out/tab-anchor-raw.json`）：
```
dotnet "$D" --corpus "$C" --tier lenient --leg b --json $HOME/w22c-laneW22C/run/v2lenB.json
dotnet "$D" --corpus "$C" --tier strict  --leg b --json $HOME/w22c-laneW22C/run/v2strB.json
```

### §2.1 宽松档腿 —— **红 133 / 421**

`rc=1`｜日志 `$HOME/w22c-laneW22C/run/v2lenB.log` sha16 **`4b81fa172a95fabe`**（86,218 B）。原样摘录（头部 + 首 3 条红 + 汇总 9 行）：
```
FRAMEPROBE lane=W22C（`#22` §3 P3：`D-T6-b` 帧判据 + 红读数）
FRAMEPROBE 时间=2026-09-16 20:13:16 +08:00 kernel=6.8.0-138-generic loadavg=2.22 2.11 2.05 1/734 260011 mem_available=3202336KiB
FRAMEPROBE TierSelect 请求档=lenient｜臂动作**之前**环境里的 WPF_LINUX_TEXTLINE_FALLBACK = <null>
FRAMEPROBE TierSelect 动作之后 WPF_LINUX_TEXTLINE_FALLBACK = 0
FRAMEPROBE TierSelect 产品侧 HbTextFallback.Enabled = false ⇒ **本腿生效档** = 宽松档 WpfLinuxLenientTextFallback
FRAMEPROBE leg=B（AlwaysCollapsible=true；偏离 oracle 语料记录的 false）
FRAMEPROBE prefix=0（源串 = 用例文本；首调下标 = 0）
FRAMEPROBE 被测件 本机副本=…/FrameProbe/bin/Release/PresentationCore.dll sha16=e7cabff9417ed380｜权威路径=…/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll sha16=e7cabff9417ed380
FRAMEPROBE 语料=…/tab-anchor-raw.json sha16=88559d670f1bb955 bytes=1196289
FRAMEPROBE font=family=Liberation Sans → /usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf#0 cmap.count=668
FRAMEPROBE RED A-anchor/lat-a-t-b@w96@LTR@i0@default 行#1 我方帧(扫描)=0 我方帧(_lineStart)=0(反射 0) 真值帧(startChar)=1 我方cpFirst=1 Length=1 行类型=HbTextLine
FRAMEPROBE RED A-anchor/lat-a-t-b@w96@LTR@i0@default 行#2 我方帧(扫描)=0 我方帧(_lineStart)=0(反射 0) 真值帧(startChar)=2 我方cpFirst=2 Length=2 行类型=HbTextLine
FRAMEPROBE RED A-anchor/lat-a-t-b@w100@LTR@i0@default 行#1 我方帧(扫描)=0 我方帧(_lineStart)=0(反射 0) 真值帧(startChar)=1 我方cpFirst=1 Length=1 行类型=HbTextLine
FRAMEPROBE 汇总 tier=lenient leg=B freshSource=0 判定行=421 红行=133 绿行=288 NOINFO行=101 红例=80 判定例=288 真值非零行=133
FRAMEPROBE 口径 语料例=436｜非latin跳过例=148｜覆盖闸跳过例=0｜--case 过滤掉=0（分母口径 = script==latin 的 288 例 / 421 行）
FRAMEPROBE 仪器自证 扫描帧 vs _lineStart(IVT) 不一致行=0｜我方 cpFirst vs 真值 startChar 不一致行=3｜驱动中断例=0｜**我方行数 != 真值行数 的例=60**｜**真值行没有对应我方行的（未判真值行）=0**｜**真机读法 GetTextBounds(cpFirst,1) 读到空的行=104**
FRAMEPROBE 越界读法现场 探了=288 例，其中 GetTextBounds(-1,1) 与 (+7) **都返回空表**的=288（真机在 FullTextLine.cs:1493-1499 **夹取**，不返回空表）
FRAMEPROBE 层级来源 严格档接手例=0 宽松档接手例=288 两档都没接手=0
FRAMEPROBE 严格档计数 fallbackCalls=810 fallbackHandled=0 fallbackBailed=810 lastBail="回退开关关（WPF_LINUX_TEXTLINE 或 WPF_LINUX_TEXTLINE_FALLBACK=0）"
FRAMEPROBE 严格档缓存 cache=空
FRAMEPROBE 宽松档计数 relaxedCalls=810 relaxedHandled=810 relaxedFailed=0 relaxedSkippedRuns=0 relaxedBlankParagraphs=0 lastSkip="-" lastSkippedRange="-" lastFail="-"
FRAMEPROBE 被测件 本机副本 sha16 前=e7cabff9417ed380 后=e7cabff9417ed380｜权威路径 后=e7cabff9417ed380
FRAMEPROBE_EXIT=RED rc=1 原因=133 / 421 判定行的**帧**与真机 startChar 不等
```
**逐条点名**：全 133 条 `FRAMEPROBE RED …` 行都在日志里（每行给出 `id` + 行号 + 我方帧 + 真值帧 + `cpFirst` + `Length`）。
**红/绿的结构**（从 `v2lenB.json` 全量重算，不抽样）：
- 红线 **133 条**，**每一条的 `我方帧` 都是 `0`**（`Counter({0: 133})`）；真值帧 ∈ {1,2,3}。
- 绿线 **288 条**，**每一条的真值帧都是 `0`**（`绿行且真值>0` = **0** 条）⇒ **宽松档就是把帧恒写成 0**，红 ⟺ `startChar>0`。
- 家族分布：`@default` **117** + `@tab0` **16** = 133（⚠️ `@default` 那 117 条**不在** `known-red.txt` 登记范围内 —— 那是**未登记红**，等主控裁决）。

### §2.2 严格档腿 —— **红 3 / 421，且这 3 条全是"结构红"不是"帧红"**

`rc=1`｜日志 `$HOME/w22c-laneW22C/run/v2strB.log` sha16 **`176bdb3a6f53dc56`**（16,376 B）：
```
FRAMEPROBE TierSelect 请求档=strict｜臂动作**之前**环境里的 WPF_LINUX_TEXTLINE_FALLBACK = <null>
FRAMEPROBE TierSelect 动作之后 WPF_LINUX_TEXTLINE_FALLBACK = <null>
FRAMEPROBE TierSelect 产品侧 HbTextFallback.Enabled = true ⇒ **本腿生效档** = 严格档 HbTextFallback
FRAMEPROBE 汇总 tier=strict leg=B freshSource=0 判定行=421 红行=3 绿行=418 NOINFO行=101 红例=3 判定例=288 真值非零行=133
FRAMEPROBE 仪器自证 扫描帧 vs _lineStart(IVT) 不一致行=0｜我方 cpFirst vs 真值 startChar 不一致行=3｜驱动中断例=0｜…｜**真机读法 GetTextBounds(cpFirst,1) 读到空的行=0**
FRAMEPROBE 层级来源 严格档接手例=288 宽松档接手例=0 两档都没接手=0
FRAMEPROBE 严格档计数 fallbackCalls=288 fallbackHandled=288 fallbackBailed=0 lastBail="-"
FRAMEPROBE 严格档缓存 cache=段起点0 行数1 总Length6      ← 末次调用后的缓存内容（`CacheInfo()`）；本腿 288 例全部由**严格档**接手、`relaxedHandled` 增量 0
FRAMEPROBE_EXIT=RED rc=1 原因=3 / 421 判定行的**帧**与真机 startChar 不等
```
**关键拆分**（`v2strB.json` 全量重算）：`我方帧 == 我方cpFirst` 在 **421/421** 行成立（严格档帧**正确**）；红的那 3 条满足 `帧 == cpFirst ≠ 真值` ⇒ **它们的红来自"我方分行与真机分行不同"，不是帧错**：
```
B-indent/lead-tab-b-t-c@w40@LTR@i24@tab0        行#1 帧=1 cpFirst=1 真值=2
B-indent-extra/lead-tab-b-t-c@w40@LTR@i0p24@tab0 行#1 帧=1 cpFirst=1 真值=2
B-indent-extra/lead-tab-b-t-c@w40@LTR@i24nl@tab0 行#1 帧=1 cpFirst=1 真值=2
```
⇒ **严格档的帧在本语料上是绿的**（对预登记"严格档大部分绿"是印证，但**不是**我原本预测的"0 红" —— 见 §3 与 §7.5）。
**严格档帧值分布**：`{0: 288, 1: 69, 2: 47, 3: 17}` = **绝对段落系**（第 k 行 = `cpFirst_k`），与宽松档的 `{0: 421}` 形成跨档反极性。

### §2.3 两档的"消费者看得见"读数（v2 新列，`真机读法 GetTextBounds(cpFirst,1)`）

真机宿主读法就是 `tab-anchor/src/Program.cs:512-514` 的 `int gi = lineStart + i; line.GetTextBounds(gi, 1)`（`i=0` ⇒ 首字）。逐行实测：

| 腿 | 帧红行 | 其中 `GetTextBounds(cpFirst,1)` **读到空** | 其中**读到非空但那是"别人"的边界**（**静默错**） |
|---|---|---|---|
| 宽松档 | 133 | **55** | **78** |
| 严格档 | 0（3 条结构红） | 0 | 3（结构红的副产品） |
| 严格档 + `--fresh-source` | 133 | 55 | 78 |
| 严格档 + `--prefix 40` | **421** | **421** | 0 |

⇒ **这个缺陷在宽松档上不是"一律读空"**：133 条帧错里只有 55 条读到空，**78 条会读到"另一个字符"的边界** —— 后者是**静默错**，比读空更难发现（纪律 41② 的现场）。

**⚠️ 计数口径（防止有人拿两个数打架）**：日志汇总行里的 `读到空的行=104` 计的是**全部 522 条产出行**（421 判定行 + 101 NOINFO 行；104 = 55 + 49）；本表的 **55** 是**只在 421 判定行内**的口径。`--prefix 40` 两趟的 `522` 同理 = 421 + 101 **全部**读到空。

### §2.4 结构差（帧判据之外，但必须登记）

- **60 例**（**全部是 `@tab0`**）「我方行数 ≠ 真值行数」，**全部是我们多分行**（`ours>truth` 60/60，`ours<truth` **0**），多出 **101 行**无真值对应 ⇒ 计 `NOINFO行`（**不混进 421 分母**）。
  例（原样）：`A-anchor/lat-a-t-b@w96@LTR@i0@tab0 我方行数=3 真值行数=1 text=[a\tb] pw=96 我方各行长=[1,1,2] 真值各行长=[4]`
- **未判真值行 = 0** ⇒ 不存在"真机有而我方没有"的行（这一半是干净的）。
- **`cpFirst ≠ 真值 startChar` = 3 行**（就是 §2.2 那 3 条，全 `@tab0/@w40`）。
- ⚠️ **既有臂对这一族结构性失明**：`PcLineOracle` 的逐行/逐字循环都是**按真值数组迭代**（`foreach (JsonElement E in exp.EnumerateArray()) { … if (li >= our.Count) break; }`，`:1244-1246`、`:1357-1359`）⇒ **多出来的我方行永远不进比较**（纪律 41②「在射程内但不看」）。本探针按**我方行**迭代，所以看得见。

---

## §3 预测 vs 实测（预测写在**跑之前**：`$HOME/w22c-laneW22C/PREDICTIONS.md` sha16 `beb5eadb719f03e7`，时间戳 19:43:33）

### §3.1 我的独立分母重算（python3，全量不抽样）

| 量 | 实测 | 预登记 §3.2 的说法 |
|---|---|---|
| 全域例/行 | 436 / 615 | 同 |
| `script==latin` | 288 例 / **421 行** | 同 |
| **`startChar > 0`** | **全域 179 行；latin 133 行**（`@default` 117 + `@tab0` 16） | **写的是"≥171 行、latin 折算 138 行"** ⇒ **字段用错**（171/138/88 是 `Start`/`ParagraphIndent` 那一列） |
| `lineStartOffsetsDip != 0`（latin） | 138 | （这才是 138 的出处） |
| 真值自洽 | `startChar == Σ 前面各行 lengthWithNewline`：**615/615，0 反例** | — |

### §3.2 逐条对照

| # | 预测 | 实测 | 判 |
|---|---|---|---|
| P1 | 宽松档红行 = **133** | **133** | ✅ 逐位命中 |
| P2 | 宽松档绿行 = **288** | **288** | ✅ |
| **P3** | 严格档红行 = **0** | **3**（**全是结构红**；帧 421/421 正确） | ❌ **预测错**（误差来源：我只算了帧，没算分行结构差） |
| P4 | 严格档 + `--fresh-source` 红 = **133** | **133** | ✅ |
| P5 | 扫描帧 vs `_lineStart`(IVT) 不一致 = **0** | **0** | ✅ |
| P6 | `cpFirst` vs 真值 `startChar` 不一致 = **0** | **3** | ❌（就是 `@tab0/@w40` 那 3 条） |
| P7 | NOINFO 行 = **0** | **101**（extra produced lines，全 `@tab0`） | ❌（"无真值对应"的行比我预想的多） |
| P8 | 越界读法 `(-1)`/`(+len+7)` 都返回空表 | **288/288 例**如此 | ✅（真机是夹取 ⇒ 两侧行为**不同**，已锚） |
| P9 | 驱动中断例 = **0** | **0** | ✅ |
| P10（未预登记，v2 才有的推论） | hostRead 空 = 133（红行一一对应） | **55 空 + 78 静默错** | ❌ 见 §2.3 |

### §3.3 `--fresh-source` 专项（核实"缓存是帧的唯一来源"）

| 腿 | 帧值分布 | 红行 | 判 |
|---|---|---|---|
| 严格档（缓存命中） | `{0: 288, 1: 69, 2: 47, 3: 17}`（绝对系） | 3 | 帧正确 |
| 严格档 + `--fresh-source` | **`{0: 421}`** | **133** | 退化成"帧恒 0" |

日志 `$HOME/w22c-laneW22C/run/v2strBfresh.log` sha16 **`30d3143e3ddb97a2`**。⇒ **"缓存是帧的唯一来源"成立**：同一份 shim、同一条用例，**只**让 `ReferenceEquals(c.Source, textSource)` 恒假，帧就从"持住的绝对系"塌成"恒 0"。这与 W20A 的 `0,1,2 → 0,0,0` 形状**逐字吻合**（本件是 421 行全量口径的重取，不引用旧读数）。

### §3.4 主控口径插话 ②③：**`cpFirst≠0` 的源**（本件新增的必做读数）—— 这是最硬的一条

**命令**：`dotnet "$D" --corpus "$C" --tier strict --leg b --prefix 40 --json …/v2strBpre40.json`
日志 sha16 **`a1f357e04ea362cf`**。源串 = `'M'×40 + 用例文本`，**首调下标 = 40**（即"这一段在该 `TextSource` 里的原点 = 40"），真值帧 = `40 + startChar`。

```
FRAMEPROBE CASE A-anchor/lat-a-t-b@w96@LTR@i0@default 首调cpFirst=40 我方各行cpFirst=[40,41,42] 真值各行startChar(绝对)=[40,41,42] 行数我方=3 真值=3 判定行=3 红行=3 接手档=strict（Δ严格Handled=4 Δ宽松Handled=0）
FRAMEPROBE 汇总 tier=strict leg=B freshSource=0 判定行=421 红行=421 绿行=0 NOINFO行=101 …｜真机读法 GetTextBounds(cpFirst,1) 读到空的行=522
```
全量重算（`v2strBpre40.json`）：
- **`cpFirst − 我方帧 == 40`，在 421/421 行成立**（`Counter({40: 421})`）。
- **帧值分布与不加 prefix 时逐位相同**：`{0: 288, 1: 69, 2: 47, 3: 17}`。
- 行数、`Length`、`绿/红`结构在加/不加 prefix 之间**不变**（判定行都是 421、NOINFO 行都是 101）⇒ 填充串**没有**进入被测段落。
- **真机读法 `GetTextBounds(cpFirst,1)` 在 421/421 行读到空**（不加 prefix 时是 0/421）。

⇒ **三层结论，全是读数不是推理**：
1. 我方帧 = **"收集串内部"的相对偏移**（原点是最近一次重新收集的 `cpFirst`），**与段落在 source 里的绝对原点无关**；
2. 真值（= 真机 `startChar`，与 `ParaCache.Contains/LineAt` 同一套**绝对系**，`shim:4034/4040`）比它大**恰好一个 `paragraphOrigin`**；
3. 因此**帧缺陷确实可以用 `cpFirst≠0` 的源观测到**（主控最担心的"看不见"**不成立**），而且**严格档也一样中招**（421/421 红、消费者 421/421 读空）—— 严格档在本语料上"绿"只是因为**本语料的每段原点恰好是 0**。

**判据的正确形式（主控问题 2）**：**`我方帧 == corpus.startChar`**（= 形式 A）。**不是** `帧 − cpFirst == startChar`（形式 B）。判别读数（**leg A**，`AlwaysCollapsible=false` = oracle 语料记录的同口径）：

| 形式 | leg A 上判成"红"的行数 | 说明 |
|---|---|---|
| A：`帧 == truth` | **114** | 与"真值>0 的 133 行"差 19 |
| B：`帧 − cpFirst == truth` | **133** | **多判 19 行为红** |

那 19 行是**上游 `SimpleTextLine` 快路径**接走的行（`IVT` 强转失败 ⇒ `lineStart=-999`），它们的**帧是对的**，例如：
```
A-anchor/lat-a-t-b@w96@LTR@i0@default       行#2 帧=2 cpFirst=2 真值=2（绿）
B-indent/lead-tab-a@w40@LTR@i0@default     行#1 帧=1 cpFirst=1 真值=1（绿）
```
⇒ **形式 B 会把 19 行正确的帧判成红** ⇒ **形式 B 错**。（形式 B 在严格档上更糟：会把 130 行 `帧==cpFirst==truth` 的正确行判红。）
**为什么形式 A 在我的装置上量得出来**：我的客户端**就是**真机宿主那个形状 —— 一个 `MockTextSource(text)`，`index` 从 0 起按 `Length` 累加，**第 k 行传进去的 `index` 就是 `cpFirst_k`**（`truth − cpFirst` 实测分布 `{0: 418, 1: 3}` ⇒ **`cpFirst` 不是恒 0**，只有每例第 0 行是 0）。两侧同系，故直接相等即可判。

---

## §4 逐成员爆炸半径与预测

`_lineStart` 的**全部**读取点（`grep -n "_lineStart" build/shims/PresentationCore.HbTextLine.cs`，现行修订 `76089e1de586ac91`）：

| 行号 | 代码（节选） | 它用的是**哪一套系** |
|---|---|---|
| `:3044` | `int localFirst = firstTextSourceCharacterIndex - _lineStart;` | **绝对**（对面是宿主的段落系下标） |
| `:3612` | `char.IsWhiteSpace(_text[_lineStart + visibleLen - 1 - prefixTrailingWs])` | **相对**（下标进 `_text`） |
| `:3621` | `_lineStart + visibleLen,  // 段落系索引` | **绝对**（`TextCollapsedRange.CharacterIndex`） |
| `:3645` | `string prefix = _text.Substring(_lineStart, visibleLen);` | **相对**（下标进 `_text`） |
| `:3652` | `cp = _plan.Sub(_lineStart, _lineStart + visibleLen);` | **相对**（下标进 `_plan`） |
| `:3655` | `if (s.Start <= _lineStart && _lineStart < s.End)` | **相对** |
| `:3732` | `int lineEnd = _lineStart + _visibleLength;` | **绝对**（`GetIndexedGlyphRuns` 吐出的字符下标） |
| `:3735` | `int startChar = (…) ? _glyphRunCharStart[i] : _lineStart;` | **绝对**（`_glyphRunCharStart` 由 `:2814` `starts.Add(lineStart + ch.CharStart)` 构造） |
| `:3177/:3188-3190/:3283/:3298/:3313-3315/:3510` | `HbLineTrace.*` / `LineStartForDiag` / dump 串 | 诊断（缺省关） |

⇒ **⚠️ 本轮最重要的技术结论：`_lineStart` 是"双用字段"** —— 它同时是 (a) `_text`/`_plan` 的**相对**下标、(b) 对外吐出的**绝对**段落系下标。**预登记 §3.4（与主控 diff 形态）写的 `_lineStart = paragraphOrigin + range.Start` 会打断 (a)**：`Collapse`（`:3612`）与 `BuildCollapsedLine`（`:3645`/`:3652`）会拿绝对下标去切**相对串** ⇒ `ArgumentOutOfRangeException` 或切到错误文本，而 `Collapse` 是**真机消费路径**（`upstream/…/MS/Internal/Text/Line.cs:165`、`PtsHost/Line.cs:495` 都调它）⇒ **不是理论风险**。

### 逐成员预测（**修法 = §5 的 Option 1**，即"**新增 `_paragraphOrigin`，`_lineStart` 语义不变**"）

| 成员 | 受影响？ | 预测（修后） | 本件是否已取读数 |
|---|---|---|---|
| **`GetTextBounds`**（`shim:3037`） | **是** | `GetTextBounds(paragraphOrigin+…,1)` 由**空**变**非空**；帧判据 133 → **0 帧红** | **是**（§2.3 量化了修前） |
| **`GetIndexedGlyphRuns`**（`shim:3726`） | **是** | 每个 run 的 `TextSourceCharacterIndex` 整体 **+paragraphOrigin** | ❌ **未测 ⇒ NOINFO** |
| **`GetTextCollapsedRanges`**（`shim:3630`） | **是（间接）** | `_collapsedRange.CharacterIndex` **+paragraphOrigin**（值来自 `:3621`） | ❌ **未测 ⇒ NOINFO** |
| **`Collapse`**（`shim:3528`） | **否**（Option 1） | 几何/`_text`/`_plan` 索引**逐位不变**（相对系保留） | — |
| **`BuildCollapsedLine`**（`shim:3643`） | **是（透传）** | 折后行的**绝对帧 = 原行绝对帧**（修前硬写 `0`，`shim:3670`） | ❌ 未测（`#21` 已登记"折叠行在 `PI≠0` 下的真值语料未覆盖"） |
| `Length`/`Width`/`WidthIncludingTrailingWhitespace`/`NewlineLength`/`TrailingWhitespaceLength`/`Height`/`Baseline`/`HasOverflowed`/`GetTextRunSpans`/`Draw` 几何 | **否** | 逐位不变（都不读 `_lineStart`，或只读相对系） | — |
| **`Start`**（`TextLine.Start`） | **否** | 只吃 `_paragraphIndentDip`（`#21` 已修）；本件**不碰** | 是（本件全程没把它当帧） |

### ⚠️ 顺带一条：不相交读法 —— 我方**空表** vs 真机**夹取**

- **我方**（`shim:3045`）：`if (localFirst < 0 || localFirst > _visibleLength) return new List<TextBounds>();` ⇒ **`Count=0`**。
- **真机**（`FullTextLine.cs:1493-1501` 夹取下标；另 `:1443-1453` 的 `CreateDegenerateBounds()` 返回**1 元素**数组 `new Rect(0,0,0,Height)`，调用点 `:1508/:1532/:1557`）⇒ **永不因"不相交"给空表**。
- **本件读数**（探针内单独取）：288/288 例 `GetTextBounds(-1,1)` 与 `GetTextBounds(len+7,1)` **都返回空表**（`FRAMEPROBE 越界读法现场` 行）。
- **真机侧后果锚点（核实，含对预登记的更正）**：真正"空表 ⇒ 断言失败"的是 **3 处** `Invariant.Assert(textBounds.Count > 0)`：
  `upstream/…/PresentationFramework/MS/Internal/Text/Line.cs:173`、`…/documents/TextBoxLine.cs:260`、`…/PtsHost/Line.cs:507`。
  ⚠️ **预登记引的 `TextBlock.cs:2314` 不是断言** —— 那是 `if (aryTextBounds.Count > 0)` **守卫**（且调的是 `GetRangeBounds`，另一个成员）⇒ 它**静默跳过**、不崩。
- **未测**：真机上"夹取"的**运行期**读数（无 Windows 机）⇒ **NOINFO**，只有源码锚点。

---

## §5 diff 草案（**行号级；未施加**）

### Option 1 —— **推荐**：新增 `_paragraphOrigin`，`_lineStart` 的**相对语义不变**

**(A) `build/shims/PresentationCore.HbTextLine.cs`**

1. 字段（`:2628` 旁）：
```
     2628:  private readonly int _lineStart;            // 行起始（段落系）
     +      private readonly int _paragraphOrigin;       // ★D-T6-b：本行所属段落在**调用方 TextSource** 里的原点
     +                                                   //   （= 收集时的 cpFirst；**帧的绝对系 = _paragraphOrigin + _lineStart**）
```
2. 私有 ctor 形参（`:2717-2725` 末，尾随可选 ⇒ 既有调用点零改动）：
```
     -      double startPenX = 0, double boxOriginX = 0, double paragraphIndentDip = 0)
     +      double startPenX = 0, double boxOriginX = 0, double paragraphIndentDip = 0,
     +      int paragraphOrigin = 0)
```
   赋值（`:2744` 之后一句）：
```
     2744:  _lineStart = lineStart;
     +      _paragraphOrigin = paragraphOrigin;
```
3. **行构造点**（`:2901-2908`，现在第 6 个实参就是 `range.Start`）：末尾加一个具名实参
```
     2906:      length, newlineLength, trailingWhitespaceLength, w, witw, segmentFaces, plan,
     …
     2908:      paragraphIndentDip);   // 末三=…
     +      , paragraphOrigin: paragraphOrigin);
```
4. `FormatParagraph` 签名（`:3886` 起、`:3919` 收尾）：在 `double paragraphIndentDip = 0` **之后**加尾随可选
```
     3919:      double paragraphIndentDip = 0)   // D-T2/(C)：尾随可选，默认 0 ⇒ 既有调用点零改动
     +      , int paragraphOrigin = 0)         // ★D-T6-b：段落在调用方 TextSource 里的原点（默认 0 ⇒ 既有调用点零改动）
```
5. **`GetTextBounds`**（`:3044`）：唯一一处改成绝对系
```
     -      int localFirst = firstTextSourceCharacterIndex - _lineStart;
     +      int localFirst = firstTextSourceCharacterIndex - (_paragraphOrigin + _lineStart);
```
   （`:3045` 的空表判据**不动** —— 那是本件 §4 顺带登记的另一条（空表 vs 夹取），**不并入本修法**，避免混账。）
6. **`GetIndexedGlyphRuns` 的绝对系来源**（`:2814` / `:2822` / `:3732` / `:3735`）：
```
     -          if (ch.Run.Glyphs.Length > 0) { starts.Add(lineStart + ch.CharStart); slots.Add(ch.RunSlot); }
     +          if (ch.Run.Glyphs.Length > 0) { starts.Add(_paragraphOrigin + lineStart + ch.CharStart); slots.Add(ch.RunSlot); }
     -      if (_glyphRunCharStart == null)
     -          _glyphRunCharStart = _glyphRuns.Count > 0 ? new List<int> { lineStart } : new List<int>();
     +      if (_glyphRunCharStart == null)
     +          _glyphRunCharStart = _glyphRuns.Count > 0 ? new List<int> { _paragraphOrigin + lineStart } : new List<int>();
     -          int lineEnd = _lineStart + _visibleLength;
     +          int lineEnd = _paragraphOrigin + _lineStart + _visibleLength;
     -          int startChar = (i < _glyphRunCharStart.Count) ? _glyphRunCharStart[i] : _lineStart;
     +          int startChar = (i < _glyphRunCharStart.Count) ? _glyphRunCharStart[i] : (_paragraphOrigin + _lineStart);
```
7. **折叠路径**（`:3621` 的"段落系索引" + `:3670` 的 `BuildCollapsedLine` 构造）：
```
     -              collapsed._collapsedRange = HbInternalsFactory.CreateCollapsedRange(
     -                  _lineStart + visibleLen,                       // 段落系索引
     +                  _paragraphOrigin + _lineStart + visibleLen,     // 段落系索引
```
```
     3670:  var collapsed = new HbTextLine(run, shaped, _glyphTypeface, _pixelsPerDip, collapsedText, 0,
     …
     3684:      paragraphIndentDip: _paragraphIndentDip);
     +      , paragraphOrigin: _paragraphOrigin + _lineStart);   // ★折后行文本 = "原行起点起的可见前缀 + 省略号"
     +                                                          //   ⇒ 它的**绝对帧 = 原行的绝对帧**（修前这里硬写 0）
```
   ⚠️ **`lineStart` 仍传 `0`** —— 因为 `collapsedText` 的下标系原点**就是原行起点**，而 `_text[_lineStart + …]`（`:3612`）/`_text.Substring(_lineStart, …)`（`:3645`）/`_plan.Sub(_lineStart, …)`（`:3652`）都作用在**原行**上、**不受本修法影响**。
8. **严格档接线**（`HbTextFallback.TryFormatLine`，签名 `:4572`；`FormatParagraph` 调用 `:4595-4604`）：
```
     4603:      indentDip: indentDip,
     4604:      paragraphIndentDip: paragraphIndentDip);
     +      , paragraphOrigin: cpFirst);      // ★严格档：本段落在 textSource 里的原点
```

**(B) 生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（宽松档接线）**

`CollectLenient(textSource, cpFirst, …)` 在 `:242`；`FormatParagraph` 调用在 `:254-258`：
```
     257:              indentDip: indentDip, paragraphIndentDip: paragraphIndentDip);
     +              , paragraphOrigin: cpFirst);
```
`-- MinMax` 路径（`:288` `CollectLenient(textSource, 0, …)`）**原点本就是 0** ⇒ **零改动**。

### Option 2 —— **预登记 §3.4 字面写法：拒绝**

`_lineStart = paragraphOrigin + range.Start`（在 `FormatLine` 里改字段语义）⇒ 见 §4 的表格：`Collapse`/`BuildCollapsedLine` 的 `_text`/`_plan` 下标**全部错位**。若坚持走这条，**必须**同时把 `_text` 与 `_plan` 重新基线化（= 把 `FormatParagraph` 收进来的整段串补上 `paragraphOrigin` 个前导字符、并平移 plan 的所有 `Start/End`），**爆炸半径从"3 个成员"扩大到"整段收集 + 计划 + 折叠"**，且要重新证明 `Width`/`Length` 记账不动。⇒ **不推荐**。

### 掩码/省略号路径另有一条**未测**风险（如实登记）

`Collapse`（`:3595-3620`）里 `_charAdvances`、`cells` 都是**行内**下标（相对），与 `_lineStart` 无关 ⇒ Option 1 下不受影响。但**我没有为折叠路径取任何修后读数** ⇒ 见 §8。

---

## §6 世代成本与 `D-F2` 合并改法

### §6.1 修法落地的世代成本（**若落地**）

- `build/shims/PresentationCore.HbTextLine.cs` 是门禁**三项世代绑定之一**（`tline-gate.sh:137` 的 `SH_SHIM` 只绑这一个文件）⇒ **五臂重取 + `known-red.json` 重钉 + 两极化重做 + 世代号 → `#22`**。
- `inputs_fp` **会变**：它收 `build/shims/**/*.cs`（`close-wave.sh:76`）⇒ 与本波"逐位不变"不同。
- 九位里 **`hbtextline` / `pc` / `pf`** 三位变（`pf` 是环成员），其余六位不变（同 `#21` 的形态）。
- **本件新增的 133 条未登记帧红**（其中 **117 条在 `@default` 族**）在重钉 `known-red.json` 之前**必须**由主控裁决 —— **我没有**把任何红压成已登记（本件不碰 `known-red.json`）。
- 修完必须补的读数（本件**没测**）：`GetIndexedGlyphRuns` / `GetTextCollapsedRanges` / 折叠行帧 的修前/修后，以及 `CoverageProbe` 门禁臂上的新列（预登记 P2 那件）。

### §6.2 与 `D-F2` 合并（只付**一笔**世代成本）

三个"只写不读"的计数器，**本件独立复核成立**：
- 写点：`shim:1272` `internal static long ScanCapped;`（`NoteScanCapped` `:1273`，调用点 `:1147`）、`shim:1275` `SegmentFaceUnresolved`（`:1276`，调用点 `:3881`）、`shim:1278` `RunFaceSlotMissing`（`:1279`，调用点 `:2803`）。
- **`HbFallbackDiag.SummaryFragment()`（`shim:1344-1379`）里三者出现次数 = `0`**（`sed -n '1344,1380p' | grep -c …` 实测 `0`）。
- `capped=` 在整份 shim 里**只出现在注释里**（`:1067`、`:1146`、`:1271`）—— **零打印点** ⇒ 注释自称的"诊断行报 `capped=`"是**假陈述**。

**精确改法（行号级）**：在 `SummaryFragment()` 里 `:1363-1364`（`chunkedLines=` / `faceResolve=` 之间）插入三行：
```
     sb.Append(" chunkedLines=").Append(ChunkedLines);
     +      sb.Append(" scanCapped=").Append(ScanCapped);
     +      sb.Append(" segmentFaceUnresolved=").Append(SegmentFaceUnresolved);
     +      sb.Append(" runFaceSlotMissing=").Append(RunFaceSlotMissing);
     sb.Append(" faceResolve=").Append(FaceResolveCalls)…
```
**⚠️ 一个会让人白跑一趟的坑（必须一并改）**：`SummaryFragment()` 开头 `:1346-1347` 有**提前返回**
```
     if (PlanCalls == 0)
         return "multifont=未使用(plan=0) 覆盖/回退各项=**无信息**（不是 0：本进程还没走过 run 感知路径）";
```
⇒ 若只按上面插三行，则**`PlanCalls==0` 的进程里三个计数器仍然一行都不打印**（而 `ScanCapped` 只在多面扫描路径上自增 ⇒ 恰好最可能出现在 `PlanCalls>0`，但 `SegmentFaceUnresolved` 在 `:3881` 的单面路径上也会自增）。**正确改法**：把这三行放进**提前返回的那个字符串**里（或把提前返回改成"先拼这三项再加前缀说明"）。
**为什么合并划算**：两者**都动同一个 shim 文件** ⇒ 只付一笔世代成本；且 `D-F2` **只往诊断串里加字段、不改任何几何**（`SummaryFragment()` 与 `:2216` 的汇总行是纯读），与 `D-T6-b` 的几何改动**互不干扰、可分别判红**。

---

## §7 我推翻/更正了哪句话

1. **预登记 §3.2 的预测数用错了字段**（主控已自认，此处给**可复现**的现场）：`171 / 138 / 88` 是 `Start`（`lineStartOffsetsDip`）那一列 —— latin `lineStartOffsetsDip!=0` 实测 **138**；而帧判据的真值是 **`startChar>0` = 全域 179 / latin 133**（`@default` 117 + `@tab0` 16）。**我的预测按 133 写，实测 133。**
2. **预登记 §3.4（与主控 diff 形态）的 `_lineStart = paragraphOrigin + range.Start` 不安全**。`_lineStart` **双用**：`:3612`/`:3645`/`:3652` 把它当 `_text`/`_plan` 的**相对**下标。证据是行号级的读码锚点 + `Collapse` 在真机消费路径上（`Text/Line.cs:165`）。⇒ 正确形态是**新增 `_paragraphOrigin`**（§5 Option 1）。
3. **预登记 §3.1/§3.4 的行号是 `#21` 之前那一版的**（主控插话已认，我独立复核并补全）：`shim:3022-3023` → 现 **`:3043-3045`**；`shim:2905` → **`:2901`**；`shim:3625`（`BuildCollapsedLine` 硬写帧 0） → **`:3670`**；`shim:4531-4536`/`:4554` → **`:4030-4044`**/`:4604`；`shim:4442` → **`:4487`/`:4492`**；`shim:4572`（严格档入口）与主控表一致。
4. **预登记 §3.4 的「`TextBlock.cs:2314`」不是断言锚点**：`:2314` 是 `if (aryTextBounds.Count > 0)` **守卫**，且调 `GetRangeBounds`（另一个成员）⇒ **不崩、静默跳过**。真正的 3 处 `Invariant.Assert(textBounds.Count > 0)` 是 `Text/Line.cs:173`、`TextBoxLine.cs:260`、`PtsHost/Line.cs:507`（预登记的 `:171`/`:496`/`:501,:505` 是近似值）。
5. **我自己的 P3 预测（严格档红 0）错**：实测 **红 3**，但**这 3 条是结构红**（`帧 == cpFirst ≠ 真值`），**严格档帧 421/421 正确**。⇒ 结论应写成"**严格档的帧在本语料上是对的，本语料的每段原点恰好是 0**"，而不是"严格档也帧错"。**主控那条源码自证（`ParaCache` 绝对编址 vs `_lineStart` 相对偏移）成立**，但它预测的是"存在两套系"，**不等于**"在原点 0 的语料上会红"—— 这一点我用 `--prefix 40` 补上了（§3.4）。
6. **我自己的 v1 推论（hostRead 空 == 红行）错**：133 条帧错里只有 **55** 条读到空，**78 条读到"别人"的边界**（静默错）。
7. **`W21C` 的「可红的行数至少 171」按帧口径应为 133（latin）/ 179（全域）** —— 171 是 `lineStartOffsetsDip` 口径，跨列了。
8. **新登记的盲区（不是推翻某句话，但是发现）**：**60 例（全 `@tab0`）我方分行多于真机**（多 101 行），而**既有臂结构性看不见**（按真值数组迭代，多出的行永不进比较）。这些行我计 `NOINFO`，**不混进 421 分母**。

---

## §8 未测 / NOINFO 清单

| # | 项 | 状态 | 卡在哪 |
|---|---|---|---|
| 1 | 修后读数（`GetTextBounds`/`GetIndexedGlyphRuns`/`GetTextCollapsedRanges`/折叠行帧/`Collapse` 几何）**全部** | **未测** | 本波**禁止改 shim**（预登记 §3.6）⇒ 无修后件可测。§4 的"预测"栏**是预测，不是读数** |
| 2 | 真机"夹取"的**运行期**读数（`CreateDegenerateBounds` 是否真的被走到、退化 bounds 的 `Count`） | **NOINFO** | 无 Windows 机；只有源码锚点（`FullTextLine.cs:1443-1453`/`:1493-1501`） |
| 3 | **真正的多段落 `TextSource`**（含 `TextEndOfLine` 边界）里"第二段 `cpFirst≠0`" | **未测** | 我的 `--prefix` 是"同 source 里前置填充 + 首调下标 ≠ 0"，**语义等价于**原点 ≠ 0 但**没有**段落边界 run；差别未测 |
| 4 | leg A 那 57 行 `SimpleTextLine` 的帧"为什么是对的" | **未取该书读数** | 只从 `IVT` 强转失败（`-999`）+ `帧==真值` 两个侧面推出；未去读 `SimpleTextLine.Linux.cs` 的 `_lineStart` 等价物（**那是另一个实现，不在本件射程**） |
| 5 | 折叠行在 `PI≠0` 下的**真值** | **NOINFO** | 语料没有覆盖（`#21` 已登记，`shim:3680-3683` 自述） |
| 6 | 哪个**产品级宿主**会以 `cpFirst≠0` 起排一段 | **未盘点** | 本件只造装置、不盘宿主 |
| 7 | `--prefix` 那 522 行"读到空"里的 **101 行 NOINFO** 的逐行真值 | **NOINFO** | 那些行**在真机语料里没有对应行**（§2.4 的结构差） |
| 8 | `Draw` 在帧修后是否有位移 | **未测**（预测：无） | 修法未施加；静态上 `Draw` 只经 `HbLineTrace` 读 `_lineStart`（`:3177`/`:3188-3190`） |
| 9 | 越界读法"夹取 vs 空表"是否**已被任何宿主触发** | **NOINFO** | 需要宿主盘点（不在本件写域） |

**`NOINFO` 一律不许读成绿**：§8 里 1、2、5、7 四项若有人当"绿"用，本判据即被滥用。

---

## §9 读数表与"零位移"自证

### §9.1 读数表（纪律 32）

| 项 | 值 |
|---|---|
| **lane** | **W22C** |
| 时间 | **2026-09-16 19:41:07 → 20:30 +0800**（开工复算 19:41:07；末次读数 20:26:58） |
| `kernel` | **6.8.0-138-generic** |
| `loadavg` | 开工 **3.12 0.96 0.47**；全程区间 **0.22–3.12**；末次 **1.07 2.09 2.18** |
| `MemAvailable` | 开工 **3,555,156 KiB** → 末次 **3,218,720 KiB** |
| `nproc` | 3（本波另有两条车道在跑构建） |
| `DISPLAY` | `:97` = **UP**（未自起 Xvfb） |
| **`pc` sha16（开工）** | **`e7cabff9417ed380`**（4,196,864 B，mtime 2026-09-16 18:47:26.817748341 +0800） |
| **`pc` sha16（收工）** | **`e7cabff9417ed380`**（逐位不变；每趟运行头尾各印一次，5 趟共 10 次读数全同） |
| `hbtextline` shim sha16 | `76089e1de586ac91`（283,557 B）——**未动** |
| 语料 | `tab-anchor-raw.json` sha16 `88559d670f1bb955`（1,196,289 B）——**未动**（另一车道的 `tab-anchor-oracle.json` 我**没用**） |

### §9.2 仪器（纪律 35/40：读数前后都记）

| 件 | sha16 | 大小 | mtime |
|---|---|---|---|
| `build/MilBridge/tests/FrameProbe/Program.cs` | **`c6a66724ad56760a`** | 37,216 B | 2026-09-16 20:13:07.138586034 +0800 |
| `build/MilBridge/tests/FrameProbe/FrameProbe.csproj` | **`9be882d85aac2ad4`** | 4,603 B | 2026-09-16 19:42:41.142172939 +0800 |
| 仪器产物 `bin/Release/PresentationCore.Tests.dll`（**v2 = 记录在案的仪器**） | **`6b65924a52a59d89`** | 26,624 B | 2026-09-16 20:13:12.219471230 +0800 |
| 仪器产物 **v1**（存档 `$HOME/w22c-laneW22C/run/FrameProbe-v1.dll`） | `c9829f1eec8f9f21` | 26,112 B | — |
| 构建 | `dotnet build … -c Release` ⇒ **`0 个警告 0 个错误`**（纪律 33：真构建，非 `--check`） | | |

**仪器变更披露（纪律 40）**：v1 → v2 的改动**逐条列出**（不隐瞒）：① **新增一列** `真机读法 GetTextBounds(cpFirst,1)`；② 新增 `--leg a|b` 与 `--prefix <N>` 两个旋钮（缺省 `b` / `0` ⇒ **缺省行为不变**）；③ 新增"我方行数 ≠ 真值行数"与"真机读法读到空"两个诊断计数器（**只印不加判**）；④ ⚠️ **扫描上界收窄**：v1 扫 `a = 0…text.Length`，v2 扫 `a = 0…max(cpFirst+16,16)`（既有臂 `FrameScan` 用 `cpFirst+4`）。**判据本身（`我方帧 != 真值 startChar` ⇒ 红）一个字节未变**；④ 的安全性由**仪器自证**兜住 —— **5 趟 v2 读数的「扫描帧 vs `_lineStart`(IVT) 不一致行」全部为 0**（若上界截断，扫描会返回 −1 而 IVT 给出真值 ⇒ 该计数器必红）。

**仪器不变性实测**：v1 与 v2 在**同一腿**上的汇总**逐位相同** —— lenient leg B：v1 `红行=133 绿行=288 判定行=421 NOINFO行=101`，v2 **同左**；strict leg B：v1 `红行=3 绿行=418`，v2 **同左**。
`INSTRUMENT dll sha16` 在 5 趟 v2 读数**头尾相同**（`6b65924a52a59d89`）⇒ 5 趟是**同一件仪器**。

### §9.3 日志与机器可读件（全在 `$HOME/w22c-laneW22C/run/`）

| 腿 | 日志 sha16 | 大小 | json |
|---|---|---|---|
| lenient leg B（**判据主读数**） | `4b81fa172a95fabe` | 86,218 B | `v2lenB.json` |
| strict leg B | `176bdb3a6f53dc56` | 16,376 B | `v2strB.json` |
| strict leg B + `--fresh-source` | `30d3143e3ddb97a2` | 86,077 B | `v2strBfresh.json` |
| strict leg B + `--prefix 40` | `a1f357e04ea362cf` | 245,811 B | `v2strBpre40.json` |
| lenient leg B + `--prefix 40` | `d666be1af7bdc926` | 246,159 B | `v2lenBpre40.json` |
| lenient **leg A**（`AlwaysCollapsible=false`，用于判据**形式**的两极化） | `cf573b14db79a017` | 67,454 B | `lenient-lega.json`（`25eb2cb0e989bc04`） |

（v1 五趟日志同目录 `lenB/strB/strBfresh/strBpre40/lenBpre40.log`，sha16 依次 `4c34661d04adfe22`/`773cd92d6114512c`/`9344e4913edf929e`/`36f7beb22af58ff9`/`e4b6f8d2d64684b9`。）

### §9.4 位移自证（预登记 §5「本波预期为零位移」）

| 位 | `#21` 冻结值 | 本件末次复算 | 判 |
|---|---|---|---|
| `bridge` | `d567c26f197ec1e3`（4,987,840 B） | `d567c26f197ec1e3`（4,987,840 B，`build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`） | ✅ |
| `pc` | `e7cabff9417ed380` | `e7cabff9417ed380` | ✅ |
| `pf` | `2fb1a896f8277647` | `2fb1a896f8277647` | ✅ |
| `windowsbase` | `1114a28ec5a03ab7` | `1114a28ec5a03ab7` | ✅ |
| `provider` | `9aa0d744802aaa31` | `9aa0d744802aaa31` | ✅ |
| `win32shim` | `0098234982391bbf` | `0098234982391bbf` | ✅ |
| `wic_shim`(= `libwpfwic.so`) | `03b67fbcd7c385b6` | `03b67fbcd7c385b6` | ✅ |
| `hbtextline` | `76089e1de586ac91` | `76089e1de586ac91` | ✅ |
| `dwf` | `0ed422ef2dd46445` | `0ed422ef2dd46445` | ✅ |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | **`b6acdba4f01599d8`**（`BRIDGE_SRC_N=78`） | ✅ |
| `inputs_fp` | `a2b74537427ecc4a987edbe52a59c5d01d4817d54de58f445833c33dfb0e78e0` | **同左** | ✅ |

**为什么新建工程不动指纹（实测不是推理）**：`build/bridge-src-fp.sh:39-43` 的 `src_list()` 里 `-o -path 'build/MilBridge/tests'` 是 **prune** ⇒ `build/MilBridge/tests/**` **不进** `BRIDGE_SRC_FP`；`close-wave.sh:76` 的 `fp_inputs()` 只收 `build/shims/**/*.cs` + `src/WpfGfx.Linux/**/*.cs` + 脚本 ⇒ 本件两个新文件**都不在覆盖面内**。⇒ **九位 / 两个指纹 / 门禁 世代 = 全不变**（本件**未**落地修法，故 §5 的"零位移"成立）。

### §9.5 既有文件"未动"自证

本件**没有**对任何既有文件执行过写操作（只 `read`/`grep`/`sed -n`/`sha256sum`/`stat`/`dotnet build` 我的新工程）。禁改清单的末次读数：`build/shims/PresentationCore.HbTextLine.cs` `76089e1de586ac91`｜`build/PresentationCore.Linux/**`：`pc` `e7cabff9417ed380`、`TextFormatterImp.Linux.cs`（只读，见 §5(B) 引文）｜`PcLineOracle/Program.cs` `a787a9db23c3302c`、`known-red.txt` `89324f1f643167e5`｜`build/MilBridge/known-red.json`、`verify-all.sh`、`arm-logs/` **未列为我写域，未触碰**。

---

## §10 给主控的裁决请求（三件）

1. **判据是否按 §3.4 的形式落地**（`我方帧 == 真机 startChar`，**按 `paragraphOrigin` 归一化之后**）⇒ 请确认形式 A、否掉形式 B（`帧 − cpFirst`），并说明它进 `CoverageProbe` 时用哪种取数（扫描 vs `LineStartForDiag`；我建议**扫描**：它不依赖 IVT 名额，且已用 IVT 自证 421/421 一致）。
2. **修法形态**：请裁决 §5 **Option 1**（新增 `_paragraphOrigin`，`_lineStart` 语义不变）—— 我**反对**预登记字面的 Option 2（会打断 `Collapse`/`BuildCollapsedLine` 的 `_text`/`_plan` 下标）。
3. **两笔"欠账"的归属**：① 117 条 `@default` 族的**未登记帧红**（宽松档腿）；② 60 例 `@tab0` 的**分行结构差**（101 行无真值对应，既有臂结构性看不见）—— 二者都**不在**本件写域（不许改 `known-red.json` / `arm-logs`），请裁决登记方式。

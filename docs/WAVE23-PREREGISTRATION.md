# 波 `#23` 预登记（**落地之前先登记**）

> 生成：主控，基于**当前冻结基线 `#21`**（权威 = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`，**`#21` 重冻时该文件整份的 sha = `0d048e6e8808c4e7`**）。
> ⚠️ **`#23` 主控更正（W23D 提出）**：早先各波写"**表头** `<sha>`"是**措辞不准** —— 那个 sha 量的是**整份文件**，不是某一行；且**该文件在本波开工时已是 `4f4bfe732c097a77`**（`#22` 波尾追加了"零位移 ⇒ 本次不重冻"的复核注记）。⇒ 今后引用一律写「**该文件在 `<世代>` 重冻时的整份 sha**」，并**另给现场值**。
> `#22` 已复核**零位移** ⇒ 未重冻。
> 冻结九位（开工前现场复算**逐位一致**）：`bridge d567c26f197ec1e3` | `pc e7cabff9417ed380` | `pf 2fb1a896f8277647` | `windowsbase 1114a28ec5a03ab7` | `provider 9aa0d744802aaa31` | `win32shim 0098234982391bbf` | `wic_shim 03b67fbcd7c385b6` | `hbtextline 76089e1de586ac91` | `dwf 0ed422ef2dd46445`；`BRIDGE_SRC_FP=b6acdba4f01599d8`；`inputs_fp=a2b74537427ecc4a987edbe52a59c5d01d4817d54de58f445833c33dfb0e78e0`；`known-red.json=2fdc02931c2af796`（`generation=#21`）。
> 纪律：**先登记后落地**｜红判据**只许加强**｜**表外位移 ⇒ 停**｜缺数据 ⇒ `NOINFO`｜**分母口径必须写清**（纪律 39）｜**仪器输入也算仪器**（纪律 40）｜**"在射程内"≠"真的看了"**（纪律 41）｜**改字段语义前逐消费点读语义**（纪律 44）｜**判据必须断言集合基数**（纪律 45）。

## §0 本波四件 + 一条已裁决的口径

| 件 | 题目 | 类型 | 世代成本 |
|---|---|---|---|
| **P1** | `D-T5`：**判据 + 红读数 + 修法设计**（**只测不修**） | 判据先行 | 无（独立探针，零产品件改动） |
| **P2** | `D-T6-b`（**Option 1**）+ `D-F2` **落地** | 修法 | **要付一笔**（动 shim） |
| **P3** | `D-A2`：`ITEMS` 补 `PresentationCore.dll` + `SCAN_ROOTS` 补 `tools`，**17 份旧件登记为在册红** | 检查器补强 | 无 |
| **P4** | 只读设计：`hasOverflowed` 判据草案 + "集合基数相等"落地草案 + 117 条 `@default` 帧红的登记口径分析 | 只读 | 无 |

**用户已裁决的口径（P3）**：「`ITEMS` 补上 `PresentationCore.dll` 后**今天就有 17 份旧副本会红**」⇒ **先登记为在册红、判据立刻上线**（符合"登记 ≠ 已容忍"；不先把 17 份刷绿）。**本波按此执行。**

---

## §1 P1 —— `D-T5` 判据 + 红读数 + 修法设计（**不许改任何产品件**）

### §1.1 为什么它排第一
`D-T5` 是**唯一"失败模式 = 进程级 abort"**的缺陷：`TextModifier`/`TextEndOfSegment`（以及 `#22` 新查出的 **`TextHidden`**）段落的 `CharacterBufferReference` 默认空 ⇒ `ExtractRun` 返 null ⇒ 宽松档 `CollectLenient` **必然 false** ⇒ 交回 LineServices ⇒ `LoCreateContext`（`libwpfwin32.so` **实测无该符号**）⇒ 逐层无 catch ⇒ **abort**。
**而 `pf` 自己在每个内联元素边缘就产 `TextHidden`**（`ComplexLine.cs:404/477/499`、`LineBase.cs:219`）⇒ **`<Run>`/`<Bold>`/`<Span>`/`<Underline>`/`<Hyperlink>` 都会命中**。

### §1.2 为什么"只测不修"
冻树里 **0 载体**（样例全走 `SimpleLine`）⇒ **"到底多严重"目前是推断不是读数**。本件的交付物 = **把推断变成红读数**，并把修法设计到"可落地"的程度（**不落地**）。

### §1.3 要做的事
在 `build/MilBridge/tests/` 下**新建独立探针**（**不许改 `PcLineOracle`** —— 它是 `verify-all` 第 [5] 步的仪器；**不许改 `CoverageProbe`** —— 它在 P2 的臂重取里）。要求：
- 造 **至少两种** `TextSource`：`TextEndOfSegment(1)` 与 **`TextHidden(1)`**（`#22` 新查出的更宽的那一族）；**并造一个"正常字符"的阳性对照**（证明装置活着）。
- **两条腿都跑**：宽松档（缺省）与严格档（`--tier strict` 式旋钮）；**逐例归因**（层级来源自证：谁接手的）。
- 断言（**草案，按它实现**）：「**必须交出非 null 的 TextLine**」∧「**不得出现 `LoCreateContext`**」∧「行 `Length` 与输入一致」。
- **反极性（现状必红）**：`W17D-report.md` 已实证 `MINEX CASE mod1 EXCEPTION …`、`relaxedFailed=1 relaxedHandled=0`、`GetTextRun` **只调 1 次** ⇒ 本件要把它**重取成可复算的读数**。
- **第二极性（防作弊）**：说明"如果只把 `ExtractRun` 的 `buf==null ⇒ null` 改成假装修好"时，**哪一条仍必须红**。
- **⚠️ 要回答一个"会不会 abort"的问题**：探针进程自己**可能被 abort 带走**（`exit=134`）。⇒ **必须为自己的崩溃留证据**：把每次调用包在可分辨的日志里（先落盘再调用），并在报告里区分 **"探针自己 abort"** 与 **"产品返回 null"** —— **这两者今天在读数上长得一样，是 `D-R3` 那条"仪器崩了被读成产品崩了"的同族**。

### §1.4 修法设计（**只写方案，不许施加**）
给出**逐层**的修法选项与代价：`ExtractRun`/`CollectLenient`（生成物，属应用器写域）/ 严格档 `TryCollect`（shim）/ 以及"是否应该让**真机也这么干**"（即上游对空 CBR 的行为是什么 —— **要引上游源码行号，不许猜**）。
标出**哪一部分要动 shim**（⇒ 与 P2 同族，可考虑合并付世代）、哪一部分动生成物（应用器）、以及**判据在哪一层取**。

### §1.5 停条件（本件）
- **不许**修改任何产品件、`CoverageProbe`、`PcLineOracle`、`known-red.json`、`verify-all.sh`。
- 探针若**无法区分**"自身 abort"与"产品返 null" ⇒ **如实写 `NOINFO` 并说明卡点**，不许编一个读数。

---

## §2 P2 —— `D-T6-b`（**Option 1**）+ `D-F2` 落地（**动 shim ⇒ 付一笔世代成本**）

### §2.1 修法**必须用 Option 1**（`#22` 已推翻预登记字面）
`_lineStart` 是**双用字段**（主控已逐行复核）：
- **绝对**（段落系）消费者：`shim:3044`（`GetTextBounds` 的 `first - _lineStart`）、`shim:3621`、`shim:3732`、以及 `_collapsedRange` 相关；
- **相对**（`_text`/`_plan` 索引）消费者：`shim:3612`、`shim:3645`（`_text.Substring`）、`shim:3652`（`_plan.Sub`）—— `Collapse`/`BuildCollapsedLine`。
⇒ **`_lineStart` 的语义与赋值保持不动**；**新增 `_paragraphOrigin`**，**只改 3 个绝对消费者**（`GetTextBounds`/`GetIndexedGlyphRuns`/`_collapsedRange`），**并把 `_paragraphOrigin` 透传到折叠行**（`BuildCollapsedLine` 的构造点）。
⇒ **禁止**落地 `_lineStart = paragraphOrigin + range.Start`（会切错串/越界）。**落地前必须先证明**：折叠相关 4 处（`:3612`/`:3645`/`:3652` + 折叠构造）**逐字节未变**。

### §2.2 `D-F2` 一并落地（同一笔世代成本）
三个"只写不读"的计数器接出口：`scanCapped` / `segmentFaceUnresolved` / `runFaceSlotMissing`。
- **落点**：`SummaryFragment()` 内，**必须在 `candidates=` 之后**（那行的 `Count` getter 会触发 `EnsureScan()`，而 `ScanCapped` 的唯一自增点在其中）；
- **推荐 `+4` 行**：`PlanCalls == 0` 的**早退分支**也要带 `scanCapped=`（否则那三个照样不打印）；
- **同步改 3 处注释伪证**（自称"诊断行报 `capped=`"）；
- **对判据行零影响**（`#22` 已机器核过：门禁完全不读 `HB_TEXTLINE`）。

### §2.3 判据与读数（**P2 自己的交付物**）
- **主判据 = `FrameProbe`**（`#22` 建的，`Program.cs c6a66724ad56760a`、dll `6b65924a52a59d89`）：修前读数已知 = **宽松档红 133 行**（帧恒 0）／**严格档帧 421/421 正确**／`--fresh-source` 133／`--prefix 40` 421/421。
  ⇒ **修后预测**：宽松档 **133 → 0**；`--prefix 40` **421 → 0**；严格档**仍 421/421 正确**（且那 3 条**结构红不应变**）；`--fresh-source` 133 → 0。
  ⚠️ **`--prefix 40` 那一格是本修法的正极性核心**（它构造的正是 `cpFirst≠0` 的分叉场景）。
- **`GetTextBounds` 的"空表 vs 真机夹取"**：单独取一条读数。真机 3 处断言已核实（`MS/Internal/Text/Line.cs:173`、`MS/Internal/documents/TextBoxLine.cs:260`、`MS/Internal/PtsHost/Line.cs:507`）。⚠️ **本轮若不同时实现"夹取"，就如实标 `NOINFO`**（不许把"帧对了"当成"夹取也对了"）。
- **零射程机器证**（照 `#21` 的做法）：修前/修后同版 `FrameProbe` 与 `PcLineOracle` 日志**按列对比** ⇒ 除预期列外**逐字相同**。
- **`D-F2` 的读数**：修后 `HB_TEXTLINE` 串里**确实出现**那三个字段（`grep -c`），且**修前一个都没有**（两极化）。

### §2.4 ⚠️ 已知的一个**必须处理的登记问题**
`#22` 实测：`D-T6-b` 的 **133 帧红里 117 条在 `@default` 族**，**不在 `known-red` 登记范围**。修后它们应变绿 ⇒ **不需要新登记**。但若**修后仍有残留红** ⇒ **如实报告并等主控裁决**（不许自行登记、不许压成绿）。

### §2.5 世代成本（**本波唯一的世代成本**）
`build/shims/PresentationCore.HbTextLine.cs` 变 ⇒ **五臂重取 + `known-red.json` 重钉到 `#23` + 两极化重做 + `inputs_fp` 变**。
**车道只负责**：改 shim + 重建 `pc` + 跑自己的判据读数。**五臂重取、登记表重钉、`verify-all`、应用门禁、重冻基线 = 主控**（与 `#21` 同分工）。

### §2.6 主控的**逐点审计清单**（Option 1 必须动哪几处、必须**不**动哪几处 —— 现场重读，行号为 `76089e1de586ac91`）

**必须改（3 个绝对消费者 + 1 处透传）**：

| # | 位置 | 现状 | Option 1 后 |
|---|---|---|---|
| 1 | `shim:3044`（`GetTextBounds`） | `int localFirst = firstTextSourceCharacterIndex - _lineStart;` | 用 `_paragraphOrigin` 参与换算（`_lineStart` 不动） |
| 2 | `shim:3732` + `:3735`（`GetIndexedGlyphRuns`） | `int lineEnd = _lineStart + _visibleLength;`；`startChar = _glyphRunCharStart[i] : _lineStart` | 同上；且 `_glyphRunCharStart` 的**播种点**（`:2814` / `:2822` 的 `lineStart`）要一并处理 |
| 3 | **`shim:3619-3622`**（`Collapse` 里建 `_collapsedRange`） | `HbInternalsFactory.CreateCollapsedRange(_lineStart + visibleLen, // 段落系索引 …)` | 用 `_paragraphOrigin` 参与换算（注：注释**自己写着"段落系索引"**） |
| 4 | `BuildCollapsedLine`（`:3643` 起）的构造点 | 新 `_paragraphOrigin` 要**透传到折叠行**（`#21` 曾漏折叠路径被拦下） |

**⛔ 必须逐字节不动（相对消费者 —— 动了就会切错串/越界）**：

| # | 位置 | 现状 |
|---|---|---|
| a | `shim:3612` | `char.IsWhiteSpace(_text[_lineStart + visibleLen - 1 - prefixTrailingWs])` |
| b | `shim:3645` | `string prefix = _text.Substring(_lineStart, visibleLen);` |
| c | `shim:3652` | `cp = _plan.Sub(_lineStart, _lineStart + visibleLen);` |

> **⚠️ 为什么这份清单必须存在**：**`:3612`（相对）与 `:3620`（绝对）在同一个方法里、相隔约 8 行** —— 这正是 `_lineStart` 双用最危险的地方：
> 只读一个消费群就会写出**编译能过、看起来对、却在特定输入下越界**的代码（`#22` 的预登记就是这么错的）。
> ⇒ **收官时主控按本表逐点核对**：4 处改到位、3 处**逐字节未变**（给 `diff`/`cmp` 证据）。
> ⇒ ⚠️ 本表行号取自 `76089e1de586ac91`；**`D-F2` 的改动会让 `SummaryFragment()` 之后的函数位移** ⇒ **审计时要现场重读，不许照抄本表行号**（纪律 4）。

---

## §3 P3 —— `D-A2`：检查器覆盖面（**用户已裁决：先登记，判据立刻上线**）

### §3.1 要做的事（**零 `dotnet`**）
1. `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` 的 `ITEMS` **补一项 `PresentationCore.dll`**（权威 = `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`）。
2. `SCAN_ROOTS`（`:93`）**补 `$REPO/tools`**（今天 `tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll` 是**启动宿主**却**连枚举都没有**）。
3. **17 份旧副本登记为在册红**（用户的裁决）：按该检查器自己的**在册红机制**登记，**每一条都要点名**（路径 + sha + 权威 + 差异类别），并保留"**登记 ≠ 已容忍**"的语义（不许把它们刷绿、不许把它们从报告里去掉）。
4. 给出**逐份表**（`#22` 的 W22D 已给 34/49 份的口径表；本件要把它变成**判据上线后的真实读数**）。

### §3.2 两极化（**必须实测**）
- **正极性**：接线后**立刻 17 份红**（`#22` 已用私有拷贝预演过：期望 55 → 86 条 ⇒ 17 份红、0 份 MISSING）⇒ 本件要在**真文件**上复现这个读数。
- **反极性（防作弊）**：把其中**一份**刷成权威 ⇒ **必须变绿**；再改回 ⇒ **必须又变红**。
- ⚠️ **`NOINFO` 不许算绿**；缺件/无权威的分支要**点名**。

### §3.3 停条件
- 不许改 `known-red.json`（那是五臂门禁的登记表，**与本检查器的在册红机制不是同一份**）—— 若该检查器的在册红需要新的存放位置，**报告并等主控裁决**。
- 不许为了让读数好看而**放宽**任何判据（`NO-AUTHORITY`/`SKIP(obj)`/`SKIP(ref)` 的既有豁免**一个都不许扩大**）。
- **`#22` 的一条更正不许再抄错**：`SCAN_ROOTS`（`:93`）**包含** `$REPO/build` ⇒ `.artifacts/**` **在扫描范围内**；**不要**再把"`.artifacts` 不在 `SCAN_ROOTS`"写进去。

### §3.4 这条改动的**爆炸半径**（主控已查清，**P3 不需要再查**）
- `build/close-wave.sh:159-160`：`APPSYNC` 是**告警不是硬闸**（`if … then ✅ else ⚠️`）⇒ 红 17 份**不会**让波中止。
- `build/publish-milbridge.sh:100-112`：注释**逐字**写着「非 PASS 时**大声报（不改退出码**：发布动作本身是否成功由上面的 rc 决定……）」⇒ **不影响桥发布**。
⇒ 本改动的**唯一后果** = "`APPSYNC` 长期红、且逐条点名" —— **这正是用户裁决要的状态**（登记 ≠ 已容忍；不许静默）。
⇒ **必须在报告与文档里写明**：本波之后 `close-wave.sh` 会**长期**打印 `⚠️ APPSYNC 非 PASS`，那是**登记在册的**、不是新问题（否则下一个人会去追它）。

### §3.5 ⚠️ 主控**开工后更正**：`17` 这个数的前提（**不是判据，是预报**）
`#22` 的预演（期望条数 55 → 86、17 份红、0 份 `MISSING`）是在**旧权威 `pc`（`e7cabff9417ed380`）**上做的。而：
- 本波 **P2 正在重建 `pc`** ⇒ 权威 sha 一变，**所有 PC 副本的"陈旧"判定全部改变** ⇒ 红数**合法地**会变；
- `close-wave.sh` 第 1 步的 `integration-wave.sh` 内建 **`refresh_applocal`（3.6 副本刷新）** ⇒ 每趟波**收敛一部分** app-local 副本 ⇒ 该数**本来就不是常量**。
⇒ **正确口径**：报红数时必须同时给 ① **权威 `pc` 的 sha16（现场取）** ② **时刻** ③ **红数**；红数 ≠ 17 **不是失败**，但要**逐条分类**差在哪（pc 变了 / 已收敛 / **判定式或豁免分支不一致**）。**只有第三种才算停条件。**
⇒ **与 `pc` 无关的那一格** = **`MISSING=0`**（期望集是声明式算出来的）⇒ **这一格才适合当稳定判据用**。
⇒ 记法教训（与 `#21` §15.2、`#22` §10.6 同族）：**预报必须写清"它依赖哪个变量"**，否则"没兑现"与"前提变了"分不开。

---

## §4 P4 —— 只读设计（**零 `dotnet`，零既有文件改动**）

1. **`hasOverflowed` 判据草案**：语料里 **22 行 `True``（主控已独立复核），而**本臂没有判据**，且 `D-O1`（`#16`）**刚把它从"恒假"改成真实现**。给出：判据怎么取数、期望值来源、**反极性**（现状红在哪、红多少）、以及**放在哪一层**（`CoverageProbe` 臂 / `PcLineOracle` / 新探针）。
2. **"集合基数相等"落地草案**（**纪律 45**）：`#22` 实测 **60 例（全 `@tab0`）我方分行多于真机**（多 **101** 行、无真值对应），而既有臂**按真值数组迭代 ⇒ 结构性看不见**。给出：把"**行数相等**"补进哪几个臂、断言形式、**反极性**、以及**会不会因此产生新的未登记红**（要预估条数）。
3. **117 条 `@default` 帧红的登记口径分析**：`#22` 实测这些红**不在 `known-red` 范围**。分析：`P2` 修完后它们会怎样（预期变绿）；若不全绿，**哪几条需要裁决**、按什么口径（`.json` 还是 `PcLineOracle/known-red.txt` —— 说明两份表的分工）。
4. **`#22` 三条欠账的排期建议**：本条只给建议，不动手。

---

## §5 位移预测表（**表外位移 ⇒ 停**）

| 位 | 现（`#21`） | 预测 |
|---|---|---|
| **`hbtextline`** | `76089e1de586ac91` | **变**（本波唯一实质源改） |
| **`pc`** | `e7cabff9417ed380` | **变** |
| **`pf`** | `2fb1a896f8277647` | **变**（环成员，**由波尾重编引起、不在车道射程内**） |
| `bridge` | `d567c26f197ec1e3` | **不变**（不动 `src/WpfGfx.Linux/**` ⇒ 不重发桥） |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | **不变** |
| `windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` | 见 §0 | **均不变** |
| `inputs_fp` | `a2b74537…` | **变**（`build/shims/**/*.cs` 在覆盖面内） |
| 五臂门禁 | `PASS generation=#21 tree_gen=same` | **先 `NOINFO/advanced`（设计）⇒ 重取 + 重钉 `#23` 后 `PASS`** |
| `verify-all` | rc=0 / 11 步 | 重钉后**同前** |
| **应用门禁** | 6/6 `PASS`、`drawn=260/144`、`colors=3960/2828`、`frames=14/14` | **预测逐位不变**；**⚠️ 但本波有一个命名候选**（见 §5.1） |
| 等号读者 | `SHIM_SHA=no` | **`no`** |

### §5.1 应用门禁的**命名候选**（主控开工前查清，**不许只用"应该不变"搪塞**）
`D-T6-b` 改的成员里，**渲染路径实际消费的只有 `Collapse` 一族**（`GetTextBounds`/`GetIndexedGlyphRuns` 在 `build/PresentationFramework.Linux/*.cs` 里**零消费者**，主控已 `grep` 核实）：
- 样例 `samples/WpfTextDemo/MainWindow.xaml:64-65` 的 **`TrimText`**（`Width=380`、`TextWrapping=NoWrap`、**`TextTrimming="CharacterEllipsis"`**）**就是省略号路径**；
- `MainWindow.xaml.cs:238-243` 的 `ApplyDiagnosticDegraded()` 把它设成 `None`，但那是**诊断降级档**（自述"**主验收档不使用本模式**"）⇒ **主验收档里 `CharacterEllipsis` 是活的**。
⇒ **若应用门禁读数变化 ⇒ 首选归因 = `TrimText` 的省略号路径经 `GetTextCollapsedRanges`/`_collapsedRange`**；**那是发现、不是失败**，必须归因后再动。**变与不变都要写进报告。**

---

## §6 停条件（**触发即停，不许"顺手修好"**）

1. 任何位移落在 §5 表外。
2. `P2` 修完 **`FrameProbe` 的 `--prefix 40` 不是 421 → 0**（修法没修到核心场景）。
3. `P2` 修完**严格档的 3 条结构红**发生变化（说明动了不该动的地方）。
4. `P2` 的折叠相关 4 处（`:3612`/`:3645`/`:3652` + 折叠构造）**不是逐字节未变**。
5. 应用门禁读数变化且**归因不到 `TrimText`**。
6. ~~`P3` 出现"接线后**不到 17 份红**"~~ —— **⚠️ 本条已由主控在开工后撤回并更正（见 §3.5）**：`17` 只是**相对于某个"权威 `pc` sha"**才有意义，而本波 P2 **正在重建 `pc`**，且 `close-wave.sh` 第 1 步内建 **`refresh_applocal`（3.6 副本刷新）** ⇒ 红数**本来就不是常量**。
   ⇒ **成立的是更窄的一条**：`P3` 若红数与预演不同，**必须逐条分类说明差在哪**（pc 变了 / `refresh_applocal` 已收敛 / **判定式或豁免分支与预演不一致**）；**只有第三种才算停条件**。
7. 任何"把红判据放松"或"把未登记红压成绿"的动作。
8. **内存**：见 §7。

---

## §7 ⚠️ 资源与内存纪律（**本波强制；用户明确要求控制内存占用**）

开工前实测：**`MemTotal` 7,923 MB，`MemAvailable` 3,330 MB，`SwapFree` 仅 1,057 MB** ⇒ **余量小**。因此：

1. **同一时刻只允许一个重构建**：`PresentationCore`/`WindowsBase`/`pf`/五臂 harness **只有 P2 车道可以构建**；P1 只许构建**它自己新建的探针工程**；P3/P4 **零 `dotnet`**。
2. **所有 `dotnet` 命令必须带 `-m:1`**（禁并行 MSBuild 节点）+ **`DOTNET_gcServer=0`**（工作站 GC）。
3. **构建前自检**：`MemAvailable < 1200 MB` ⇒ **等 20 s 重试**（最多 5 次）；仍不足 ⇒ **报告 `NOINFO` 并停**（不许硬上）。
4. **报告里必须写** `MemAvailable` 的**开工/最低/收工**三个值 + `loadavg`。
5. **禁止**：`verify-all`（主控的活）、`dotnet build wpf-linux.sln`（全解决方案，内存最贵）、任何 `-m` 缺省的多节点构建、以及**并发跑两个重构建**。
6. 每个车道**收工前复核** `MemAvailable` 并确认**没有留下自己的 `dotnet`/MSBuild 进程**（按 PID 查，**不许 `pkill -f`**）。

---

## §9 本波开工后**追加的两条裁决与一条新发现**（都在取读数之前/期间写下）

### §9.1 裁决一：`DISPLAY=:97` 死了 ⇒ **批准车道不停**，但要求机器证
- **事实**：开工后实测 `:97` **DOWN**（`pgrep -a Xvfb` 为空、`/tmp/.X11-unix` 只有 `X0/X1/X10`）⇒ 我在派单里写的"DOWN 就报告并停"**触发了**（W23B 主动来问，**它做对了**）。
- **裁决**：P1/P2 的读数（`FrameProbe`/`PcLineOracle`/`D5CbrProbe` = **托管文本排版对 JSON 语料**）**没有渲染面** ⇒ **X 不是仪器输入** ⇒ **继续**。
  **但"我认为不是"不算数** ⇒ 要求：**同一单例分别在 `:0` / `unset` / `:97` 下各跑一次，stdout 的 `sha16` 逐字节相同**（这才是"X 不是输入"的机器证）。
  **常规读数一律 `unset DISPLAY`**；`:0`/`:1`/`:10` **只在这一次证明里碰**（那是**宿主自己的** display，不是本项目的装置）。
- **主控已修**：`:97` 已重启并**实测验证**（`Xvfb :97 -screen 0 1280x1024x24`，PID **303561**，`xdpyinfo` 通过 —— 确认过**结果**才落笔，这是纪律 30 的要求）。

### §9.2 🆕 新发现 `D-G7`：**常驻 `:97` 会死，而且它死了不会让任何判据变红**（**第 3 次**了）
- **历史**：`:97` 至少死过三次（`#15` 波那次让门禁 `exit=134`/全空 ⇒ 立了纪律 30"用常驻 Xvfb"；此后又死过两次，每次都是**靠人偶然发现**——本次是车道打印了 DOWN）。
- **为什么危险（要写准，不许夸大）**：应用门禁 runner（`tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh:401-419`）在 `:97` 不在时会**自起一个 Xvfb**，并且**现在有就绪自检**（`:409`/`:413`/`:419` 三次 `xdpyinfo`）⇒ **`#15` 那个就绪竞态已被 runner 侧缓解**。
  ⇒ 所以真正的危害**不是**"会假红"，而是：**装置悄悄从"复用常驻 `:97`"变成"自起 Xvfb"**，而波形文档里"**两趟都跑在常驻 `:97`（复用分支）**"这句话**就变假了**，且**没有任何东西会红**。
- **判据草案（最小）**：跑应用门禁**之前**断言 `xdpyinfo -display :97` 通过；并把 runner 自报的**装置行**（`复用已存在的 X server：:97` vs `启动自己的 Xvfb :97`）**逐字抄进波形记录**（`#18`/`#19` 已经这么做过，要**变成强制**而不是可选）。
- **本波处置**：`:97` 已修；**波尾两趟应用门禁必须逐字记录装置行**（见 §8 收官清单）。**登记为 `D-G7`，不修**（修法 = 那一条断言）。

### §9.3 裁决二：`D-T6-b` 的**宽松档接线在生成物里** ⇒ **必须改 patcher，不许手改生成物**（**批准**）
- **车道查出的口径冲突**：预登记 §2.3 预测"**宽松档 133 → 0**"，而宽松档的类 **`WpfLinuxLenientTextFallback` 不在 shim 里**，它在**生成物** `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（文件头自述"由 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` **生成**，不要手改"；`build/integration-wave.sh:161` 每波重跑该脚本）。
  ⇒ 车道给的写域（只写 report + `build/shims/**`）**不足以兑现预测**。
- **裁决：改 patcher**。理由 = **手改生成物正是纪律 38 的原案**（`#17` 事故：手加内容被下一趟波**静默抹掉**，而**所有绿判据都没红**，唯一红它的是 P1 自己的等号读者）。
- **四条硬要求**（已下发给车道）：
  1. **只改 patcher，不碰生成物**；改完证明 patcher 自己的 `--check` **rc=0**（生成物 == 脚本产物），并报 before/after 两个 sha16。
  2. **同步 needle/计数牙齿**，并**证明注入仍然生效** ⇒ `bash build/check-appliers.sh` 必须仍是 **`miss=0 red=0 rc=0`**。
     **为什么这条最要紧**：`#17` 的教训就是"**注册了但没生效**"这一族 —— **needle 写错 ⇒ 注入静默不发生 ⇒ 所有绿判据照绿** ⇒ "`--check` rc=0" **不够**，必须有 `miss=0` 这条**独立**读数。
  3. **⛔ 不许改 `build/MilBridge/tools/applier-audit-expected.txt`**（**登记表，主控写域**）；若判断它必须跟着改 ⇒ **停下报告**，由主控落。
  4. **纪律 38 的红线判据（主控做）**：波尾**再跑一次 patcher**，核对注入的 `paragraphOrigin: cpFirst` **还在** ⇒ 所以改动**必须活在 patcher 里**。
- **`inputs_fp` 会因此变两个原因**（报告里必须两个都点名）：① `build/shims/**/*.cs`（Option 1）② **`src/WpfGfx.Linux.Native/tools/patch-*.py`（patcher，在覆盖面内）**。

### §9.4 主控**第三次**自我更正（口径混用，撤回给车道的数）
我给 W23B 写「W22C 报的是 **133 行 / 88 例**」—— **那个 `88` 很可能是我把两列混了**：
- `88` 是 **`#21` 那一波 `Start` 列**红证的口径（**138 行 / 88 例**，`W21A-report.md`）；
- **`D-T6-b` 的帧列**，W22C 报的是 **133 行**，**我没有**可靠来源说它的"红例"是 88。
⇒ 已发更正：**不要把 88 当"W22C 的数"去对它**；只要求车道**报出帧列自己的"红例"数与"例"的口径**（是否把 `行数不等` 的 60 例算进"红例"）。
⇒ **与 `#22` 的两次同类错（`D-G1` 字段清单、`D-T6-b` 预测数）合起来**：**"两个不同的列/口径被当成同一个"已经是本项目的第三次同类错误** ⇒ 这条值得进纪律（纪律 39 的加强版：**不仅"分母"要写清，"是哪一列"也要写清**）。

---

## §10 P3 收官 —— `D-A2` 检查器覆盖面（车道 W23C，报告 `b6601b828475a636`）

### §10.1 判决读数（主控**独立复跑**过检查器）
- **`APPSYNC=MISMATCH（MISMATCH=13[STALE=13 NEWER-DIFF=0] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=3 RETIRED=0）`**、**`rc=1`**。
- 主控另跑一遍得 `计数：OK=51 MISMATCH=13（STALE=13） MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1] DIVERGENT=3 NO-AUTHORITY=39 SKIP(obj)=7 SKIP(stub)=6 SKIP(ref)=10`。
- ⚠️ **主控自己踩了一次本项目的在册陷阱**：我第一次写"`checker rc=0`" —— 那是 **`grep` 的 rc**（`$?` 写在管道后）。**重新正确测量 = `rc=1`**。
  ⇒ 与项目方法学里那条"`RC=$?` 写在管道后"**逐字同族**；**记我头上**（这也是本波主控的第 4 处自我更正）。

### §10.2 ⚠️ `17` 与 `13` 的差 = **口径差异，不是失败**（车道的分类正确）
按 §3.5 要求逐条分类后**三条都排除到只剩一条**：
- **不是** `pc` 变了（本件 6 次读数 before/after 全同 = `e7cabff9417ed380`）；
- **不是** 3.6 `refresh_applocal` 收敛（12 份旧副本**一份都没被刷**）；
- **是**「预演与真分支顺序不一致」—— 但那**不是判据坏了**：差的 **5 份**全部落在**既有豁免分支 ④**（`is_release_path && is_debug_auth` ⇒ **`NO-AUTHORITY`「判不了≠一致」**）。
⇒ `#22` 的 W22D 报的 **17 = "内容≠权威"的份数（含 5 份 Release 路径）**；**真检查器的口径是 13**。**两个数在各自口径下都对**。
⇒ **车道的推演（未实测，如实标注）**：**`pc` 重建后**，现在 == 权威的那 5 份 Debug 副本会翻成 `STALE` ⇒ **12+5 = 17**。**不许为验这个数去碰权威产物** ⇒ 记为 `NOINFO`，由 P2 的 `pc` 重建**自然兑现**（波尾复核）。
⇒ **真实收获（要写进本波结论）**：这次改动**把 PC 的"陈旧也不会红"从 32 份降到"13 份点名红 + 5 份被豁免（且豁免是设计、不是漏判）"** —— 也就是**把 12 份静默陈旧变成了点名红**。

### §10.3 登记形态（**完全符合用户裁决**）
- 该检查器**确无任何既有的在册红机制**（`known-red|registry|在册` 改前 **0** 命中；退出码只有 `0/1/3`）⇒ **新建书面登记** `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md`（`e5946a8a7ce1cfe0`，13 条逐份记 `路径 / 副本 sha / 当时权威 sha / 类别 / 日期 / 处置`）。
- 检查器新增 `show_registry()`（**只读只打印**）。主控**已实跑并逐字读到**它的自述：
  > `--- 在册红（书面登记 …；**登记≠已容忍**：本段不参与判定，rc 仍由上面五个计数器决定）`
  > `    [在册红] build/DirectWrite.Linux/FontEntryClosedLoop/bin/Debug/PresentationCore.dll 23567d420f0dbbaa（现权威 e7cabff9417ed380；登记时权威 e7cabff9417ed380；类别 STALE；处置 刷新（重编该工程即收敛））`
- **`rc` 一字未动** ⇒ `APPSYNC=MISMATCH` 长期红、**但是登记过、点了名的红**。`[在册红·已转绿]` 会**自证该删**。

### §10.4 两极化实测（**车道做了，且做得很硬**）
- **正极性**：接线后 `MISMATCH 0→13`、`DIVERGENT 0→3`。
- **反极性**：把一份红副本刷成权威 ⇒ `OK`、`MISMATCH 13→12`、登记段出现「已转绿 1」；**`cp -p` 复原** ⇒ `cmp IDENTICAL`、**sha/size/mtime 逐位相同**、`MISMATCH` 回 13，且**复原那趟日志与复原前那趟 `sha16` 完全相同（`3f3b8ab31dcf1f84`）**。
- **`tools/` 那条用"只换 `SCAN_ROOTS`"的对照证明**：四根 ⇒ `MISMATCH=12`、该件判定行 **0 次**；五根 ⇒ 13、`DIVERGENT 3`。
- **`--selftest` rc=0、16 项全 PASS、0 FAIL**。

### §10.5 改动（before → after）
| 件 | before | after |
|---|---|---|
| `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` | `aad23482f84bdf44` | **`013df358c0bed2a3`**（删 1 行旧 `SCAN_ROOTS`、加 93 行：注释 + 1 条 `ITEMS` + 两个**只打印**块；**判定分支/谓词/计数器/退出码零改动**） |
| `…/applocal-expect.py` | `6eafbea14e7ea41e` | **`7becc5266636c405`**（+1 条 `ITEMS`，走**声明式来源**，不手写清单） |
| `…/known-red-PC-copies.md` | —— | **新** `e5946a8a7ce1cfe0` |
⇒ 这三件**都不在 `inputs_fp` 覆盖面内**（`inputs_fp` 只覆盖 `patch-*.py`/`port-lib.py`/两个波脚本/`build/shims/**/*.cs`/`src/WpfGfx.Linux/**/*.cs`）⇒ **本件不改 `inputs_fp`**（与 P2 的 patcher 不同）。

### §10.6 🆕 新登记 `D-G8`：**`scan()` 的 `rc` 被丢弃** ⇒ **权威整份不见时 `rc` 可能仍 0**（真缺陷，本波**未修**）
- **主控独立复核**：`check-applocal-sync.sh:654` `scan; scanrc=$?`，而 **`grep -c scanrc` = 1**（**全脚本只出现这一次**）⇒ **`scanrc` 赋值后从未被读**。
- **后果**：某个**权威文件整份不见**时，只印告警，而**退出码可能仍是 0** ⇒ 与 `D-A2` 同族（"看不见的洞"），但**更糟**：它让 `APPSYNC=PASS` 变成**可以骗人的绿**。
- **为什么本波没修**：补它会让 `--selftest` 的 **`SELFTEST_E` 沙箱立刻红**（沙箱里没有 `ReachFramework`/`PC` 的权威件）⇒ **修它必须同步改自检的期望**（两件必须同趟改，否则自检变成假红）。
- **裁决**：**登记为 `D-G8`，本波不修**；排进 `#24`（**修法与自检的同步改动写成一条**，并给两极化：删掉一份权威 ⇒ 必须 `rc≠0`）。

### §10.7 车道**推翻/发现**的四条（逐条留档）
| 项 | 内容 | 判定 |
|---|---|---|
| ① | **接线前 `APPSYNC` 就已经是 `MISMATCH`**（`UNEXPECTED-EQ=1`，`FallbackCriteria/bin/Debug/WpfGfx.Linux.dll`）⇒ **"接线前是绿的"是错的**（**主控**在本波与 `#20`/`#21` 文档里都这么写过） | **更正**；该条 = **`D-A1`**（在册），**归入登记集**，**不因本件新增** |
| ② | **`scan()` 的 `rc` 被丢弃**（见 §10.6） | **新登记 `D-G8`** |
| ③ | `AFTER1` 里出现过的 `MISSING=2` 是 **P1 车道 `D5CbrProbe` 的建设中间态**（csproj mtime `23:56:58`、目录 `23:57:47`，落在它两趟读数之间的 **91 秒窗口**）；`FINAL` 同命令 **`MISSING=0`** | ✅ **主控点名要单独当判据的那一格（`MISSING=0`，与 `pc` 无关）实测仍成立**；期望副本 `56→88`（+30 PC、+2 该新工程）、工程数 `81→82` |
| ④ | `.artifacts/**` **本来就在扫描范围内**（改后日志 **15 次命中**）；**真漏扫的是 `$REPO/tools`**，已补 | ✅ 与主控在 `#22` 的更正一致 |

### §10.8 残留（`NOINFO` / 未测，不许当绿）
- `pc` 重建后红数回到 **17** = **推演未实测**（不许碰权威产物 ⇒ 波尾由 P2 的 `pc` 重建自然兑现，届时复核）；
- `--list-items` 的"python 不可用"分支**未实测**；
- **`wpfgfx_cor3.so` 仍是 `EXPECT=UNKNOWN`**（2 份只有**互比**）⇒ **"两份一起换成旧件"仍然静默**（`#22` 的 W22D 已指出这一半，本波**未堵**）；
- `tools/` **之外**的整目录漏扫**未穷举**；
- `close-wave.sh` **未重跑**（"波不中止"引的是主控对 `:159-160` 的核查，**不是本件的实测**）。
⇒ **波尾必须实测**：跑 `close-wave.sh` 时确认它只**告警**、`verify-all` **不受影响**（`verify-all` 不跑 APPSYNC）。

---

## §11 P4 收官 —— 只读设计（车道 W23D，报告 `91e98f471efed019`）

### §11.1 ⭐ 最重要的一条：**它推翻了我刚在 `#22` 立的纪律 45**（主控已独立复核）
见 `CURRENT-STATE.md` 纪律 45 的**替换版**。要点：两支臂**都在断言"我方行数 == 真值行数"**
（`CoverageProbe:1391` `bool structOk = lines.Count == exp.GetArrayLength()`；`PcLineOracle:905` `bool structOk = (driveErr == null) && our.Count == exp.GetArrayLength()`）
⇒ **那 60 例今天就在红，而且 60/60 已在 `PcLineOracle/known-red.txt`**。
⇒ **机制不是"产品多分行"**，而是 **`D-T4`（`DefaultIncrementalTab` 到不了工厂）这条臂姿势限制**（证据 = **60/60 我方行数 == 其 `@default` 孪生真值行数**）。
⇒ **元教训**：**"结构性看不见"这类断言必须先 `grep` 判据本身** —— 我这次只读了车道报告就立纪律，**立纪律同样要证伪**。

### §11.2 `hasOverflowed` 判据草案（**主控已独立复核真值侧规律**）
- **真值 = 22 行 / 8 例，全部落在 `script==latin` 可判定集内**（`B-indent-extra` × `i24p24` × `w40`；4 个 textId × {default,tab0}）⇒ **不是**"躺在不可比子集里"。
- **真值侧规律（主控现算，逐位吻合）= `paragraphStartOffsetDip + width > paragraphWidthDip`**：**命中 22 / 假阳 0 / 漏 0（615 行全覆盖）**。
  而我方分支③（`_boxOriginX + _width > _paragraphWidth + 1e-9`，`_boxOriginX = PI`）**逐字同构** ⇒ **接线后预测红 = 0 行 / 0 例**。
- **反极性四档（全部现算）**：`HasOverflowed => false` ⇒ 红 **22 行/8 例**（首选）｜`=> true` ⇒ 红 **593 行/428 例**｜**错驱动量**（内容起点 `_startPenX+_width>W`）⇒ 红 **89 行/54 例**｜**去掉严格 `>`（改 `>=`）⇒ 红 74 行/63 例（latin 58/47）** ← **这 74 行坐在"恰好到达边缘"（余量 = 0）的发丝扳机上 ⇒ 判据必须写死严格 `>`**。
- **放哪层**：**`CoverageProbe --tab-lines-oracle`**（在门禁里、语料自带真值、**已断言行数**、已喂 `pw`/`indent`/`PI`）；**不建议新探针**（`D-G2`：别再加"只在车道里跑过"的仪器）。
- **`NOINFO`**：我方 `HasOverflowed` 的**真实读数本波未取**（本件零 `dotnet`，且**没有任何仪器打印它**）⇒ 上面全是**预测**，接线时才算数。

### §11.3 「行数相等」的预估：**新增未登记红 = 0 条**
两支臂**已经在断言**行数（见 §11.1）⇒ 我原本要"补"的这条**已经存在**。
- `PcLineOracle` 今天红 **60 例**（全 `@tab0`）⇒ **60/60 已在册**；
- `CoverageProbe` 那侧 **红 0**（它能表达该输入，`:1380`）。
⇒ **纪律 45 的"落地"从"补断言"变成"不用补"**；`#24` 只花 **1 行**把 TWIN 的"只印不判"（`PcLineOracle:1354`）升成判据。

### §11.4 两份登记表的分工（**这是本波最实用的一张表**）
| 表 | sha | 只被谁读 | 语义 | 绑世代？ | 有无 `unlocated`/`carrier` |
|---|---|---|---|---|---|
| `build/MilBridge/known-red.json` | `2fdc02931c2af796` | **只被 `tline-gate.sh`**（`:125`） | **五臂门禁**的登记表 | **绑世代**（`instr_*` 三个 sha） | **有** |
| `build/MilBridge/tests/PcLineOracle/known-red.txt` | `89324f1f643167e5` | **只被 `PcLineOracle`**（`:228`/`:371`/`:1594-1622`） | "**本臂表达不出来的输入**"表 | 不绑 | 无 |
另：**探针自带的 `KNOWN-RED` 行在门禁里等于未登记**（`tline-gate.sh:511-514`）。
⇒ 未登记红在门禁侧 ⇒ `unregistered>0` ⇒ `rc=1`；在 `PcLineOracle` 侧走例级吸收，且**在 `verify-all` 里不产生判决**（`pc-line-step.sh` 只读 `PCLINE START` 行）。

### §11.5 ⚠️ 三处**读数语义**更正（会影响以后读臂日志的人）
1. **`shim:3453` 的"真机实测：3222/3222 行全为 false"未背书**（`hasOverflowed`）：唯一含 "3222" 的语料 `layout-b34/windows-results.json` 里 **`hasOverflowed` 出现 0 次**；仓内三份语料**合计 66 行 true**（`tab` 36 / `tab-anchor` 22 / `modifier-scope` 8）⇒ **与 `D-T6-c` 同族的第三落点**（改它 = 换世代 ⇒ **建议搭下一次动 shim 的车**，与 `D-F2`/`D-T6-b` 同趟）。
2. **`TAB_LINES 最大差=0.0000` 的语义 = "最大违规量"，不是"最大偏差"**（`CoverageProbe:1402` 的 `worst` **只在 `dW>0.05` 分支更新**）⇒ **不能当"宽度精确相等"的证据**。
   ⚠️ **范围要写准**：这条**只对 `CoverageProbe` 的 `TAB_LINES 最大差` 成立**；`PcLineOracle` 的 `PCLINE START … 最大Δ` 是它自己算的，**不可混用**（这正是本波第 3/4 次同类错的温床）。
3. 帧列/`Start` 列/行数 三条的**红例口径互不相同**（W23D 现算收口）：**帧列 133 行 / 80 例**｜**`Start` 列 138 行 / 88 例**｜**行数不等 60 例**，且**帧 ∩ 行数 仅 6**。
   ⇒ 把 `88` 套到帧列就是**第四次同类错**（`#22` 两次 + `#23` §9.4 一次）⇒ **纪律 39 的加强：不仅"分母"要写清，"是哪一列"也要写清。**

### §11.6 `#22` 三条欠账的排期（车道结论，主控采纳）
| 欠账 | 处置 | 排期 |
|---|---|---|
| ① 帧红 **117 行 / 67 例**（+ 16 行 / 13 例 `@tab0` **在册**） | **随 P2 自动消解**（不重复计工作量） | `#24` 的真活 = **把帧列接进一个门/步**（`FrameProbe` 五处 grep 全 0 ⇒ 那 67 例**今天无处可登记**；**欠的是接线，不是登记**） |
| ② **60 例多分行** | **不排修**（在册 + 臂姿势 + `D-T4` 真值缺口） | `#24` 只花 **1 行**把 TWIN 的"只印不判"升判据；`D-T4` 本体排到**需要 Windows 重录**的波 |
| ③ **78 行静默错** | 与 ① **同一批行、同一件工作** ⇒ **不许重复计** | 随 ① |

### §11.7 车道**自己的**一处更正（如实留档）
它把 `0d048e6e8808c4e7` 误读为"**表头行 sha**"，当场更正为"**`#21` 重冻时整份文件**的 sha"，现行值 `4f4bfe732c097a77`。
⇒ **主控采纳并已改本文件 §0 的措辞**（早先各波的"表头 `<sha>`"写法是措辞不准；以后一律写"该文件在 `<世代>` 重冻时的**整份** sha"+ 现场值）。

### §11.8 纪律 35 披露（车道主动做）
`docs/WAVE23-PREREGISTRATION.md` 在它工作期间被追加（`72215b0f5ed741b3`(167 行) → `6e2bb9a9e1d930ab`(305 行)）；**它的任务 §4 逐字未变**，§6 第 6 条被撤回、新增 §9/§10 ⇒ **本件读数有效，仅"配对"变了**。

---

## §12 P1 收官 —— `D-T5` 判据 + 红读数 + 修法设计（车道 W23A，报告 `4eb5c407d5d0948a`）

### §12.1 红读数（**已做出来**；`pc=7b47a7b3d69ad62f`、`unset DISPLAY`）
见 `KNOWN-DEFECTS.md` 的 `D-T5` 表。要点：`eos1`/`mod1`/三个 `hidden*` 在**两条腿**都是 **`RED-EXC-LS`**（有 catch）/ **`ABORT 134`**（无 catch）；
`control`（阳性对照）与 `mod0`（`Length=0`）**GREEN**。
**快路径开（= 产品缺省）**：`eos1`/`mod1` **仍红 + 134**；三个 `hidden*` 变 **GREEN**。
⇒ **`D-T5` 在产品缺省配置下确实可达，且失败模式是 `ABORT 134`** —— 与派单的判断一致，**但从"推断"变成了"读数"**。

### §12.2 ⚠️ 它**推翻**了预登记 §1.1 的"家族更宽"（**主控已独立复核**）
`SimpleTextLine.Linux.cs:1703-1707`（= 上游 `SimpleTextLine.cs:1559-1563`）把 `TextHidden` **当 Ghost run** 处理 ⇒ **默认配置下被快路径吸收、不命中 `D-T5`**。
⇒ **「`<Run>`/`<Bold>`/`<Span>` 都会命中」是错的**；成立的是 **`TextModifier`/`TextEndOfSegment` 在默认配置下就命中**（`TextSpanModifier(1)` 由 pf 自产那一半仍成立）。
⇒ **主控已据此更正 `KNOWN-DEFECTS.md`**。另它修正 `W17D:160`「零长 modifier 是唯一可达形态」**只成立于 `FormatMinMaxParagraphWidth`**（在 `FormatLine` 上零长 run 被快路径抛 `ArgumentOutOfRangeException`）。

### §12.3 ⭐ **修法成本被改写：主路不必动 shim**（这会改 `#24` 的计划）
- ① `ExtractRun`（patcher `REPLACEMENT_3` `:241-250`，关键 `:246`）与 ② `CollectLenient`（`:261+`）**都在应用器里** ⇒ **主修法零世代成本**；
- ③ 只有**严格档 `TryCollect`**（shim `:4487-4520`、`:4513` bail）要付世代 ⇒ 建议**与 `D-T6-b` 同族合并、后置**；
- ⛔ 不许手改生成物；牙齿同步改 4 条；**不许加 `throw`**（`:811` 上游 4 == 生成物 4 守恒）、**不许加调用点**（`:803` 各恰好 1）。

### §12.4 `abort` 与 `null` **已可分辨**（本波对 `D-R3` 那条"仪器崩了被读成产品"的直接补强）
规则 = `rc=134` ∧ 标记文件**无 `T3` 收尾行` ⇒ 被 abort；`rc∈{0,1,2}` ∧ 有 `VERDICT` ⇒ 探针活着。
**判读逻辑自己先过两极化**（`--selftest abort` ⇒ 134、`--selftest null` ⇒ 1）。
现场：`eos1 --nocatch` `rc=134` + stderr `EntryPointNotFoundException … 'LoCreateContext' … @ TextFormatterContext.cs:113` + 标记停在 **`T1 before FormatLine#1`** ⇒ **死在第一次调用**。

### §12.5 车道自纠 3 条仪器缺陷 + 撤回 1 条（**判决对、归因错**）
见 `KNOWN-DEFECTS.md`。最重要：**`GetTextRun` 非幂等** ⇒ 严格档 bail 后宽松档在**同一下标**拿到**下一个 run** ⇒ 走"空段落"分支而**不是** `D-T5`；
修后产品自己的诊断行**逐字吻合在册机制**（`CharacterBuffer 取不到（run 类型 TextEndOfSegment）`）。
⇒ 它**撤回**了一处一度要登记为"产品双计"的发现（`relaxedFailed=2`，那是该缺陷的假象）；**保留**一条独立低 severity 观察（生成物 `:191`+`:244` 对"空段落且无 props"同一次失败计两次）**供主控裁决**。

### §12.6 ⚠️ `pc` 在它读数期间**变过**（纪律 35 的现场，处理正确）
`e7cabff9417ed380` → **`7b47a7b3d69ad62f`**（P2 于 `00:13:09` 落树；`hbtextline` → `e89fed55fd8e32bc`）。
车道**已重取**：探针本地副本刷新到新 `pc`，两趟矩阵 **128/128 采样全为一个值**（读数期间未再变），且**新旧 `pc` 的 verdict 逐行相同** ⇒ **"与 `_lineStart` 正交"的预测实测兑现**。开工基线当时与 `#21` 逐位一致。

### §12.7 X 不变性（主控硬要求）**已兑现**
`:0` / `unset` / `:97` × 3 例 ⇒ 归一化 stdout `sha16` **逐字节相同**（`X_INVARIANT=YES`）；归一化**只动 `pid=`**，且原始逐行 diff **只出现 pid 差异**。主判据一律 `unset DISPLAY`；它**没有**自起 Xvfb。

### §12.8 残留 `NOINFO`（8 条，见报告 §⑩）
要点：真 XAML 是否会走到（`<Run>`/`<Bold>` 走 `TextHidden` ⇒ **不命中**；`<Underline>`/`<Hyperlink>` 那一路**会**）、`AlwaysCollapsible` 在真实控件里的分布、RTL/多段/`lineLength>0`/`RecreateLine` **未测**、**真·假修的端到端读数未做**（要改产品件 ⇒ 已给可执行方案）。

---

## §13 P2 收官 —— `D-T6-b`（Option 1）+ `D-F2` 落地（车道 W23B，报告 `1e65c548ac3d0ad7`）

### §13.1 新 sha（本波唯一的世代成本）
| 位 | `#21` | **`#23`** |
|---|---|---|
| `hbtextline` | `76089e1de586ac91`（283,557 B） | **`e89fed55fd8e32bc`**（**290,825 B**） |
| `pc` | `e7cabff9417ed380` | **`7b47a7b3d69ad62f`**（4,197,376 B；`0 警告 0 错误`，32 s） |
| `patcher` | `daa1fe2a32d454cf` | **`00c2179b87fc0509`** |
| 生成物 | `799e0366b312ec65` | **`fef2cfb47f882a82`** |
| `inputs_fp` | `a2b74537…` | **`6146f364…ca0ca`**（**两个原因**：shim + **patcher** —— 两个子组 sha 都确实变了） |
| `bridge` / `BRIDGE_SRC_FP` / 其余六位 / `known-red.json` | —— | **全未变** ⇒ **§5 表外位移：无** |

### §13.2 四条腿（分母 = `script==latin` 288 例 / 421 行）
| 腿 | 修前 | **修后** |
|---|---|---|
| 宽松档 | 红 133 | **红 3** |
| 严格档 | 红 3 | **红 3**（**日志逐字节相同**） |
| `--fresh-source` | 红 133 | **红 3** |
| `--prefix 40` | 红 421 | **红 3** |

另：`GetTextBounds(cpFirst, 1)` **读空的行**：宽松 **104 → 0**、`--prefix 40` **522 → 0**。
**主控独立复跑确认**：宽松 `红行=3`、严格 `红行=3`、`--prefix 40` `红行=3`、`判定行=421`、`真值非零行=133` —— **与车道逐位吻合**。

### §13.3 🔴 裁决：**预测写 0 是我的口径错，不是修法没做完**（**主控第 5 次同类错**）
车道**如实上报而没有改判据**（`FrameProbe/Program.cs` 仍 `c6a66724ad56760a`），**这是对的**。它的全量机器证（421 行、不抽样）：
- **`frame == cpFirst` 421/421**；
- **`cpFirst == truth` 的 418 行里，帧错 = 0**；
- **`cpFirst ≠ truth` 恰 3 行，且全红**（那 3 行就是 `#22` 已登记的"**我方分行 ≠ 真机分行**"结构族）。
⇒ **帧族红 = 0/418**。
**主控独立复核那 3 条**：全是 `@tab0`（`B-indent/lead-tab-b-t-c@w40@LTR@i24@tab0`、`B-indent-extra/…@i0p24@tab0`、`B-indent-extra/…@i24nl@tab0`），且**每条自报 `行数我方=4 真值=2`** ⇒ **是"行数不等"结构族，不是帧错**。
⇒ **正确口径 = "帧族红 → 0"**；我原来写的"宽松 133→0 / prefix40 421→0"**把结构红混进了帧数**。
⇒ **这是同一类错的第 5 次**（`#22` 两次：`D-G1` 字段清单 / `D-T6-b` 预测数；`#23` 三次：§9.4 的 `88`、把我以为是别人跑的 `FrameProbe`、以及本条）⇒ **纪律 39 再加强：报数必须写"是哪一列 / 哪一族 / 分母是哪一档"，三者缺一不可。**

### §13.4 主控**逐点审计**（按 §2.6 的表；**全部通过**）
**必须改的 4 处（绝对消费者）全部改到位**：
| # | 修后位置 | 形态 |
|---|---|---|
| 1 | `shim:3093` | `int localFirst = firstTextSourceCharacterIndex - (_paragraphOrigin + _lineStart);` |
| 2 | `shim:2852`/`:2862` + `:3789`/`:3792` | `starts.Add(_paragraphOrigin + lineStart + ch.CharStart)`、兜底 `new List<int> { _paragraphOrigin + lineStart }`、`lineEnd = _paragraphOrigin + _lineStart + _visibleLength` |
| 3 | **`shim:3670`** | `_paragraphOrigin + _lineStart + visibleLen,   // 段落系索引（★`#23` P2：加段落原点）` |
| 4 | **`shim:3736`** | 折叠行透传 `paragraphOrigin: _paragraphOrigin + _lineStart`（**`#21` 漏的就是这处**） |
另：`_paragraphOrigin` 字段 `:2661`、ctor 形参 `:2762`（**带默认值 0** ⇒ 既有调用点零改动）、赋值 `:2783`（在**两处播种之前**，注释写明）、`FormatLine` 形参 `:2890`/转发 `:2952`。

**必须逐字节不动的 3 处（相对消费者）—— 主控 `cmp` 逐字节确认**：
`_text[_lineStart + visibleLen - 1 - prefixTrailingWs]`（`:3661`）｜`_text.Substring(_lineStart, visibleLen)`（`:3694`）｜`_plan.Sub(_lineStart, _lineStart + visibleLen)`（`:3701`）—— **三处与 `#21` 版本完全相同**。
⇒ 车道另报 `:3612`/`:3645`/`:3652`/`:3655` + 赋值 `_lineStart = lineStart;`**五处 `cmp` IDENTICAL**；且 `--prefix 40` 的同一行**同时印 `扫描=41` 与 `_lineStart=1`** ⇒ **Option 1 的形状可现场看到**（绝对被扫描到 41、相对仍是 1）。

**`D-F2` 也落到位**：`SummaryFragment()` `:1353-1355` 加 `scanCapped=`/`segmentFaceUnresolved=`/`runFaceSlotMissing=`；`:1391` 的 **`PlanCalls==0` 早退分支**也带了 `scanCapped=`（= 推荐的 `+4` 行版）；**3 处注释伪证**（`:1067`/`:1146`/`:1271`）已改成"出口 = `HB_TEXTLINE` 汇总行的 `scanCapped=`"。

### §13.5 主控**自己跑的**三条硬判据（全部通过）
1. **patcher `--check` rc=0** ⇒ `[检查] … 内容已是最新`、`[接线] csproj 已就位（幂等）`、`退出码 0`。
2. **纪律 38 红线（真跑重生成）**：`python3 <patcher>` ⇒ 生成物 **`fef2cfb47f882a82 → fef2cfb47f882a82`（逐字节不变）**，注入行 `paragraphOrigin: cpFirst` 仍在 **`:268`** ⇒ **改动活在 patcher 里，能活过重生成**。
3. **needle 仍生效**：`bash build/check-appliers.sh` ⇒ **`APPLIER_AUDIT_SUMMARY appliers=22 ok=80 miss=0 red=0 rc=0`**（与 `#21` **同数**）⇒ 没有落进"**注册了但没生效**"那一族。

### §13.6 零射程（机器证）
- **严格档腿日志剥掉时间戳后逐字节相同**；**`PcLineOracle` 日志逐字节相同**（`db37ce865e8b91b1`，连时间戳都没有）；
- 宽松 / `--prefix 40` **只变预期列**：`LINECOUNT` **60/60 全同**、`CASE` 行只变 `红行`；
- **`D-F2` 两极化**：修前运行时 `HB_TEXTLINE` 三字段 `grep -c` = **0/0/0** → 修后**各 2 处**（`candidates=371(扫描1次) scanCapped=0 segmentFaceUnresolved=0 runFaceSlotMissing=0`）；pc 二进制里的 **UTF-16 用户串** `0/0/0 → 2/1/1`。

### §13.7 车道提请注意的两条（主控逐条回应）
1. **"00:25 起另一条车道在跑 `FrameProbe --leg b --tier lenient`（PID 339398/339401）"** ⇒ **那是我**（主控的独立复跑，**在新 `pc` 上取的修后读数**，不是"别人的修前读数"）⇒ **无需重取**。
   ⚠️ 但这条提醒**本身很有价值**：**同一台机器上两个人跑同一个探针时会互相看不见**（与 `#21` 的"照 sha 比输出前先对齐旋钮"同族）⇒ 进纪律：**并发跑同一仪器必须在报告里标 PID 与时刻**。
2. **"本件动了 `_collapsedRange.CharacterIndex`（省略号路径）⇒ 应用门禁若有位移，首选归因 `TrimText` 的 `CharacterEllipsis`"** ⇒ **与 §5.1 的命名候选一致，采纳**。

### §13.8 残留 `NOINFO`（车道的四条，不许当绿）
1. **`GetTextBounds` 的"夹取"未实现** ⇒ 无修后读数（288/288 仍返回空表）；
2. **`PlanCalls==0` 早退分支的运行期读数取不到**（所有 try 路径都经 `FormatParagraph`；唯一绕开的 `TextLineProto/bin` 里的 `pc` 是 **`#19` 旧件 `f4a454c8fe69cdfe`** ⇒ 弃用）⇒ 只有静态证 + pc 里 `scanCapped` 出现 2 次；
3. **`D-F2` 三计数器的非零极性逼不出来**（本机 371 面 < `MaxScanFaces=4096`）；
4. 折叠行几何、`GetIndexedGlyphRuns`/`GetTextCollapsedRanges` 的真值、**RTL 半边**、**应用门禁** —— 均未测（**应用门禁 = 波尾主控跑**）。

---

## §8 收官清单

- [ ] P1：两种 `TextSource`（`TextEndOfSegment(1)` + `TextHidden(1)`）+ **阳性对照**的两条腿读数；`LOCCREATECONTEXT`/异常/返回 null 的**逐例归因**；**"探针自己 abort"与"产品返 null"可分辨**；修法逐层方案（含"要动 shim 还是应用器"）
- [ ] P2：Option 1 落地 + `D-F2` `+4` 行 + 3 处注释更正；`FrameProbe` **133→0（宽松）/421→0（prefix40）**、严格档 3 条结构红不变；折叠 4 处**逐字节未变**；`GetTextBounds` 夹取一条（或 `NOINFO`）；零射程机器证；`D-F2` 字段修前无修后有
- [ ] P3：`ITEMS` + `SCAN_ROOTS` 改动 + **17 份在册红逐条点名** + 正/反极性实测 + 逐份表
- [ ] P4：`hasOverflowed` 判据草案 + 集合基数相等草案 + 117 条登记口径分析 + 排期建议
- [ ] **主控**：五臂重取（`ln -f`）+ `known-red.json` 重钉到 `#23` + `verify-all` + 应用门禁两趟 + **重冻 `#23`** + 文档（`CURRENT-STATE`/`handoff`/`KNOWN-DEFECTS`/`ACCEPTANCE-BASELINE`）
- [ ] 纪律 38 的红线：**再跑一次 `port-lib.py` 后人工加的东西还在**（本波不新增手加件，但要复核）


---

# §14 收官（`#23` 波完成记录，主控，2026-09-17 00:5x）

## §14.1 波已**重冻**：`#23` 是当前冻结基线
权威 = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（**`#23` 重冻时整份 sha = `5ccdf74a56955096`**，48 条 `BASELINE` 行 = 8 世代 × 6）。

| 位 | `#21` | **`#23`** |
|---|---|---|
| `bridge` | `d567c26f197ec1e3` | **未变**（4,987,840 B） |
| `pc` | `e7cabff9417ed380` | **`7b47a7b3d69ad62f`**（4,197,376 B） |
| `pf` | `2fb1a896f8277647` | **`1c3fe23261c22bc6`**（环成员，**波尾重编**引起） |
| `windowsbase` | `1114a28ec5a03ab7` | 未变 |
| `provider` | `9aa0d744802aaa31` | 未变 |
| `win32shim` | `0098234982391bbf` | 未变 |
| `wic_shim` | `03b67fbcd7c385b6` | 未变 |
| `hbtextline` | `fe1b7ed8fa3ed231` | **`e89fed55fd8e32bc`**（290,825 B） |
| `dwf` | `0ed422ef2dd46445` | 未变 |
| `BRIDGE_SRC_FP` | `b6acdba4f01599d8` | 未变 |
| `inputs_fp` | `a2b74537…` | **`6146f3641b87a5a7d74e182ab9ca3f6f72299377bbfce2993843cb56ccbca0ca`**（**两个原因**：shim + 应用器） |

## §14.2 位移表核对（§5 vs 实测）
| 位 | 预测 | 实测 | 判定 |
|---|---|---|---|
| `hbtextline` | 变 | 变 | ✅ |
| `pc` | 变 | 变 | ✅ |
| `pf` | 变（环成员，**由波尾引起**） | 变（**波尾**引起；车道重建后 `pc` 未再动） | ✅（前提在 `#22` §15.2 已更正） |
| `bridge` / `BRIDGE_SRC_FP` | 不变 | 未变 | ✅ |
| `windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf` | 不变 | 未变 | ✅ |
| `inputs_fp` | 变 | 变（**两个原因**都点名了） | ✅ |
| 五臂门禁 | 先 `NOINFO` 再 `PASS` | 逐字如预测；重钉后 **`PASS generation=#23 tree_gen=same drift=0 gone=0 unregistered=0 caliber=OK`**（**一次成功**） | ✅ |
| `verify-all` | 同前（11 步） | rc=0 / 11 步 / 871 通过 2 跳过 | ✅ |
| 应用门禁 | 逐位不变（**有命名候选**） | **六条机读行与 `#21` 逐字相同**；**候选没有兑现** | ✅ |
| 等号读者 | `no` | `SHIM_SHA=no`（`cmp=full64`） | ✅ |

**表外位移：无。**

## §14.3 本波**未做**（不许当绿）
1. **`D-T5` 的修法未落地**（判据 + 红读数 + 方案已交；**主路在应用器 ⇒ 零世代成本**，严格档那半建议与下一次动 shim 的波合并）；
2. **`GetTextBounds` 的"夹取"未实现**（仍返回空表）；
3. **帧列仍无门/步可登记**（`FrameProbe` 在 `verify-all`/`tline-gate.sh`/`pc-line-step.sh`/`run.sh`/`arm-logs/README.md` **五处 grep 全 0**）⇒ 残余 3 条与 67 例**今天无处可登记**；
4. **`hasOverflowed`（22 行真值）仍无判据**；`startChar`(179)/`dependentLength`(179) 同；
5. **`D-G8`（`scanrc` 被丢弃）未修**（与 `SELFTEST_E` 必须同趟改）；
6. **`D-A2` 的"两份 `wpfgfx_cor3.so` 一起换旧仍静默"** 未堵；`tools/` 之外的整目录漏扫未穷举；
7. **`D-F2` 三计数器的非零极性逼不出来**（371 面 < `MaxScanFaces=4096`）；
8. **RTL 半边、折叠行几何、`GetIndexedGlyphRuns`/`GetTextCollapsedRanges` 的真值** 均未测。

## §14.4 收官清单核对（对 §8）
- [x] **P1**：两种 `TextSource`（`TextEndOfSegment(1)` + `TextHidden(1)`）+ **阳性对照**的两条腿读数；**abort 与 null 已可分辨**（且判读逻辑自身过两极化）；修法逐层方案（**主路零世代成本**）；X 不变性机器证
- [x] **P2**：Option 1 落地 + `D-F2` **`+4` 行**（含早退分支）+ 3 处注释更正；四条腿读数；**折叠 4 处 `cmp` 逐字节未变**；零射程机器证；`D-F2` 两极化
- [x] **P3**：`ITEMS` + `SCAN_ROOTS` + `applocal-expect.py` 改动 + **13 份在册红逐条点名** + 正/反极性实测 + 书面登记 + `show_registry()`
- [x] **P4**：`hasOverflowed` 判据草案（含**发丝扳机**警告）+ 两份登记表分工 + 三处读数语义更正 + `#22` 三条欠账排期
- [x] **主控**：**`close-wave.sh`（顺序修正）** → 五臂重取 → 重钉 `#23` → `verify-all` → 应用门禁两趟 → **重冻 `#23`** → 文档
- [x] **纪律 38 红线**：真跑重生成 ⇒ 生成物逐字节不变、注入仍在；`appliers=22 ok=80 miss=0 red=0`

> ⚠️ **顺序教训（已立纪律 46）**：本波我**第一次收官时漏了 `close-wave.sh`** ⇒ 读数取在规范波尾**之前**，而波尾重建动了 `pf` ⇒ 应用门禁基线作废 ⇒ **重取了一遍**。**正确顺序 = `close-wave.sh` → 五臂 → 重钉 → `verify-all` → 应用门禁 → 重冻。**

## §14.5 元结论（本波三条）
1. **"改字段语义"前必须逐消费点读语义**（纪律 44）：`_lineStart` 的双用让**字面修法**会打断折叠路径，而**编译器不会拦**（类型一样）、多数消费点**看起来仍对**。本波靠车道**读源码**拦下 —— 这是 `#22` 建立"预登记是待证伪的假设清单"之后的**又一次兑现**。
2. **"更宽 / 看不见 / 恒为 X"这三类元断言，采纳前必须核机制**（纪律 47）：本波我**两次**栽在这上面（纪律 45 被推翻、`TextHidden` 扩宽被推翻）。**它们不改代码 ⇒ 没有任何自动环节会红**。
3. **收官顺序本身是判据的一部分**（纪律 46）：`pf` 这种"环成员"会在**波尾**才变 ⇒ **在波尾之前取的一切对外读数都不算数**。这与 `#21` §15.2 的"位移表要标由谁的动作引起"是同一族，本条补的是"**由哪一阶段引起**"。

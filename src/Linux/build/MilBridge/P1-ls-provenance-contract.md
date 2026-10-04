# P1-W106 **草案（未实现，本波不做）**：LS↔PTS 锚点表 C1–C4 绑定契约 ＋ 共现 5 件收口

> 🔴 **本件是草案**：**未实现、本波不做**、**不接实现**。用途＝供将来"内容层那一波"**直接当验收面**。
> 本件只读：未构建／未跑腿／未占显示／未 `git add/commit/push`；写入面**仅本件载体**；行号一律整行取；引他人读数带代际并标「未独立复算」。

---

## §0 身份、边界与在飞件

- 载体：`build/MilBridge/P1-ls-provenance-contract.md`（**新建**，`temp+rename`）。写入面**仅本件**。
- 来源件：`t190` 载体 `build/MilBridge/P1-ls-provenance-recon.md`（167 行／自证 `27a1ea496c79f08f`，**本席未独立复算其内部读数**）——它立 **`PRECOND-LS-PROVENANCE-BRIDGE`** 并给出 C1–C4 四列。
- 读取时刻：**2026-09-29 22:42–22:52**；HEAD＝`14f5421`；`src/WpfGfx.Linux.Native/src/win32_pts.c` 现取 **`02d4c89fa432d4d2`**（与 `t190`/`t191` 同代）。

---

## §1 台账（件＋sha16／行数，现取）

| 件 | 行数 | 用途 |
|---|---|---|
| `PresentationCore/…/TextFormatting/TextStore.cs` | 2737 | C3 本体（`_cpFirst`／`_lscpFirstValue`／`LscpFirstMarker`） |
| `PresentationCore/…/TextFormatting/FullTextState.cs` | — | C3 的**两个**构造点 |
| `PresentationCore/…/TextFormatting/FullTextLine.cs` | 2765 | 共现收口（`lsdcpSubLine`／`lsdcpRun`） |
| `PresentationCore/…/TextFormatting/LineServicesCallbacks.cs` | 3503 | 共现收口（`EnumText` 的 `cpFirst`/`dcp`） |
| `PresentationCore/…/TextFormatting/LineServices.cs` | 1620／`8b2bc2167f5c0bd3` | 共现收口（`dcpDepend`／`dcpMaxContent`／字段声明） |
| `PresentationCore/…/TextFormatting/TextMetrics.cs` | 436 | 共现收口（`dcpDepend`） |

---

## §2 C3 现取复核（**本席自取，不复述 `t190`**）—— 并**修正**一处口径

### §2.1 构造签名与初始化（现取）
- `TextStore` 构造：`TextStore.cs:101-106 public TextStore(FormatSettings settings, int cpFirst, int lscpFirstValue, int formatWidth)`；初始化 `:111 _cpFirst = cpFirst;`、`:112 _lscpFirstValue = lscpFirstValue;`。
- **全仓仅 2 个构造点**（`grep -rn 'new TextStore('` 于 `PresentationCore/MS/internal/TextFormatting/*.cs` ⇒ 2 处）：
  1. `FullTextState.cs:72-77`（**主 store**）：`settings, cpFirst, 0, settings.GetFormatWidth(...)` ⇒ **`lscpFirstValue = 0`**。
  2. `FullTextState.cs:87-102`（**marker store**）：`:99 0,  // marker store always started with cp == 0`、**`:100 TextStore.LscpFirstMarker,   // first lscp value for marker text`** ⇒ **`lscpFirstValue = TextStore.LscpFirstMarker`**。
- 常量现取：`TextStore.cs:2376 internal const int LscpFirstMarker = (-0x7FFFFFFF);`

### §2.2 判词：**「`lscpFirstValue = 0`」**不**恒成立**
| 构造路径 | `cpFirst` | `lscpFirstValue` | 成立/不成立 |
|---|---|---|---|
| `FullTextState.cs:72-77`（主 store） | 调用方 `cpFirst` | **`0`** | 「＝0」**成立** |
| `FullTextState.cs:87-102`（marker store，条件见 `:82-84`：段落首行 ∧ 有 `TextMarkerProperties.TextSource`） | **`0`**（`:99` 注释「marker store always started with cp == 0」） | **`-0x7FFFFFFF`** | 「＝0」**不成立**（⇒ 是**负哨兵**） |
⇒ **修正 `t190` 的表述**：它写「构造处**显式传 0**」——**只对主 store 成立**；**marker store 传负哨兵**。⇒ 契约里 **C3 必须写成"两参数对"**，**不得**把「0」当常量写死（否则 marker 段落会**差一个常数**⇒ 正是 §5 反腿 (a) 的形态）。
- ⚠️ **本席未核对的**：`lscp` 与 `cp` 的**精确换算公式**（只现取到 `:151 lscpFetch -= _lscpFirstValue;` 与 `:153 Invariant.Assert(lscpFetch >= _cpFirst);` 两句）⇒ 具名 **`NOINFO-LSCP-CP-FORMULA`**（存在换算、方向可判；**逐行公式未核**）。

---

## §3 `NOINFO-COOCURRENCE-SEMANTICS` 收口（逐件核完，结论写死）

**口径对齐**：本件与 `t190` 同口径（**子串 `dcp`**，非词边界），逐件计数：`FullTextLine.cs` **7**、`LineServicesCallbacks.cs` **12**、`LineServices.cs` **7**、`TextMetrics.cs` **4**、`TextStore.cs` **4**。

| 件 | 命中形态（现取） | 是不是「LS↔PTS 的 dcp 桥」 |
|---|---|---|
| `TextStore.cs` | `:1922/:1943/:1945/:1964` —— **方法内局部循环变量** `dcp` | ❌ 不是（与 PTS `dcp` 无关） |
| `FullTextLine.cs` | 全部是**复合名** `lsdcpSubLine`／`lsdcpRun`（`:1646`／`:1782`／`:1803`／`:1810`／`:1832-1833`／`:1843`） | ❌ 不是（LS 子行/run 的字符计数） |
| `TextMetrics.cs` | `dcpDepend`（`:161`／`:163`／`:167`／`:170`）＝**LS 报告的依赖计数** | ❌ 不是 |
| `LineServices.cs` | 声明/字段：`lsdcpSearch`(`:147`/`:156`)、`int dcp`(`:261`)、`dcpDepend`(`:991`)、`dcpMaxContent`(`:1097`)、`lsdcpSubLine`(`:1157`)、`lsdcpRun`(`:1165`) | ❌ 不是 |
| `LineServicesCallbacks.cs` | `:2581-2585 EnumText(… int cpFirst, // first cp of the ls dnode ; int dcp, // dcp of the dnode …)`；上游注释 `:2570-2580`（"Line enumeration methods through Line Services LsEnumLine callbacks … **map cp in backing store onto its GlyphRun** …")；`:2672`（"using the cpFirst/dcp pair as index"）；`:2760`（"dcp is 1 for a Tab character"） | ❌ **不是**：此 `dcp` 是**LS dnode 的 dcp**（与 `cpFirst` 成对，用于 dnode 内索引），**量种**与 PTS 的**文档级 `dcp`** 不同 |

**⇒ 收口判词（写死）：5 件共现里**没有任何一件**把 LS 侧的量与 PTS 的 `dcp`／`nmp` 连起来；5 件全部是**同名不同义**（LS 的 `dcp` 系＝dnode/子行/run 的字符计数与依赖计数；PTS 的 `dcp`＝文档字符位置）。⇒ `NOINFO-COOCURRENCE-SEMANTICS` **解除**（已逐件核完），其结论**并入** `PRECOND-LS-PROVENANCE-BRIDGE`（桥仍缺，且现在**连"看起来像桥"的候选也被排除**）。**
（射程：`PresentationCore/MS/internal/TextFormatting/` 下这 5 件逐件核完；`plsrun ∩ nmp`／`lscp ∩ nmp` 的 0 件结论沿用 `t190`，本件**未重跑**整仓共现。）

---

## §4 锚点表 C1–C4：责任方（**谁填／何时填／本侧能否复算校验**）

| 列 | 内容 | ① 由谁填 | ② 哪个调用点/时机（现取；无则明写"不存在"） | ③ 本侧能否**复算校验**（可否做成一票红反腿） |
|---|---|---|---|---|
| **C1** | `nmp`（段落名） | **宿主** | ✅ **存在**：`+136 GetFirstPara` 的 out（`PtsHost.GetFirstPara` → `ISegment.GetFirstPara(out fSuccessful, out nmp)`）；本侧在**回调内**收下并保管（`win32_pts.c` 的 `drive_nmp`） | ✅ **能校"值"**（本侧有认领谓词＋来源证据）；❌ **不能校"语义身份"**（`t190` 已立 `NOINFO-NMP-SEMANTIC-IDENTITY`） |
| **C2** | LS 会话标识（`plsrun` 起点 或 `LoCreateContext` 的 `ploc`） | **宿主 + LS** | ❌ **不存在于我们的链上**：托管在 `TextFormatterContext.cs:113 LoCreateContext(…)` 拿到 `ploc`；`plsrun` 由 `LineServicesCallbacks` 分配 ⇒ **须新立**（本侧今天不在该调用链上） | ❌ **不能**（本侧既非作者也不在该会话内）⇒ 只能**接收并保管** |
| **C3** | `lscp ↔ cp`（**两参数对**：`_cpFirst` ＋ `_lscpFirstValue`） | **托管**（`TextStore`，构造时一次性绑定，之后只读） | ✅ **存在（托管侧）**：`FullTextState.Create`（`:65-102`）内两处 `new TextStore(...)`（`:72-77` 主 store＝`0`；`:87-102` marker store＝`LscpFirstMarker=-0x7FFFFFFF`）；使用点 `TextStore.cs:151`／`:153` | ✅ **能**（拿到两参数即可复算一致性；**公式**见 §2.2 的 `NOINFO-LSCP-CP-FORMULA`） |
| **C4** | `cp ↔ dcp` 偏移 | **宿主**（只能宿主，`t190` 已判本侧无 `dcp`） | ❌ **不存在**：全仓无填点 ⇒ **须新立**；建议时机＝**LS 会话创建时**一次性绑定并留痕 | ⚠️ **只能"复算校验"，不能自算**：宿主给出偏移后，本侧可校验**自洽性**（同段落内加减守恒、不同段落偏移不得混用、`dcp` 不越界），**不得**自行推导 |

---

## §5 两条**必红反腿**（写死）

| # | 夹具形态 | 期望机器读数（必红条件） | 今天能不能跑 |
|---|---|---|---|
| **(a)** **偏移错一**（"看起来对齐"） | 宿主给出的 `cp↔dcp` 偏移**故意 ±1**；同段落内取**段落首字符**的 `dcp` 与 `cp` 各一，走契约校验器 | 校验器**必须报红**（判据须给出**可区分**的取证量，例如"首字符处 `dcp(cp)` 与 `cp(first)` 之差 ≠ 声明偏移"）；**若 ±1 也判绿 ⇒ 判据无判别力 ⇒ 该判据作废** | ❌ **不能**（无 LS 会话、本侧无 `dcp` 值）⇒ 标**"随内容层那一波"** |
| **(b)** **跨段落复用同一 `plsrun` 表** | 构造**两个不同 `nmp`**（两段落）指向**同一张** `plsrun` 表 | 校验器**必须报红**（C1↔C2 必须**一一对应**；同一 `plsrun` 表不得服务两个 `nmp`） | ❌ **不能**（同因：无 `plsrun` 面）⇒ 标**"随内容层那一波"** |

**读法纪律**：两条反腿**今天都不可执行** —— 但**必须写进契约**（它们是"那一波"的**准入反腿**）；**不许**把它们的存在当成本波已做；也**不许**在"无读数"的情况下把契约判绿（`P10`＋恒真断言族：*没有读数 ≠ 读数相同*）。

---

## §6 契约草案本体（供队长／那一波直接用）

- **objective**：在**同一段落**内建立并维持「LS 位置 ↔ PTS 位置」的**双向可验证**对应：任取一个 LS 侧位置与一个 PTS 侧位置，**映射后指向同一字符**。
- **acceptance（六条合取，缺一不绿）**：
  1. **C1↔C2 一一对应**：每个 `nmp` 恰有一个 LS 会话标识，**无第二关联**（= 反腿 (b) 的否定面）；
  2. **C3 两参数对**齐备且**现取**一致（**不得**把 `0` 当常量：marker store 为负哨兵，见 §2.2）；
  3. **C4 由宿主给定**并留痕（本侧**不得**自算）；
  4. **双向**验证：任取 `lscp` 与 `dcp` 各一，映射后指同一字符（**≥2 独立样本**，且**先证样本非空**）；
  5. **反腿全红**：(a) 偏移错一 **必须**被判红；(b) 跨段复用 **必须**被判红；
  6. 每条读数带纪律三十三格 ＋ 探针闸状态。
- **verify**：`<leg> >out 2>err; echo $?`（**不许从管道尾巴取 `rc`**）；C3 两参数用 `awk` 现取并记 sha16；两样本逐格比对。
- **inScope**：契约本体（锚点表责任方／六条合取／两条反腿）＋只读取证。
- **outOfScope**：任何实现（LS 会话、`FsQueryTextDetails`、`dcp` 计算）；任何由本侧自算 `dcp`／`plsrun` 的做法；`upstream/**`／`.cs`／csproj 改动。
- **判词粒度（写死）**：契约的成立粒度＝**单段落**；**不得**由它宣布跨页/整页排版结论。

---

## §7 纪律落地与验收

- 🔴 **`P9`**：`t190` 判"本侧 0 持有"**不**等于"映射不存在"——本件**逐件核完 5 件共现**后，结论是**"同名不同义"**（不是"没查过"）；且 C3 的一半**确实存在于托管侧**。
- 🔴 **`P10`**：每条否定附**射程**（构造点 `grep -rn`＝2 处；5 件逐件计数与行号；`LscpFirstMarker` 常量行）。
- 🔴 **恒真断言族**：本件读数全来自**读取**；两条反腿**今天不可跑**已明写（**"无读数"不等于"读数相同"**）。
- **验收**：新件、首部**明标"草案，未实现，本波不做"**、`mode 644`、首记号 `# P1-W106 `、末行自证并当场复算 MATCH、`temp+rename` 落盘。

---

## §8 附录：现取原文摘录（整行取，仅本次有效）

`TextStore.cs`：
```
:101        public TextStore(
:102            FormatSettings          settings,
:103            int                     cpFirst,
:104            int                     lscpFirstValue,
:105            int                     formatWidth
:106            )
:111            _cpFirst = cpFirst;
:112            _lscpFirstValue = lscpFirstValue;
:151            lscpFetch -= _lscpFirstValue;
:153            Invariant.Assert(lscpFetch >= _cpFirst);
:2376        internal const int LscpFirstMarker = (-0x7FFFFFFF);
```
`FullTextState.cs`：
```
:72            TextStore store = new TextStore(
:73                settings, 
:74                cpFirst, 
:75                0, 
:76                settings.GetFormatWidth(finiteFormatWidth)
:77                );
:87                markerStore = new TextStore(
:99                    0,                           // marker store always started with cp == 0
:100                   TextStore.LscpFirstMarker,   // first lscp value for marker text
```
`LineServicesCallbacks.cs`：
```
:2570        // Line enumeration methods through Line Services LsEnumLine callbacks 
:2572        // We want to map cp in backing store onto its GlyphRun. …
:2581        internal unsafe LsErr EnumText(        
:2584            int                         cpFirst,                        // first cp of the ls dnode
:2585            int                         dcp,                            // dcp of the dnode
:2672                    // Note that we are using the cpFirst/dcp pair as index.
:2760                           1,       // dcp is 1 for a Tab character
```

---

**判词（本席）**：① **C3 口径修正（本件最重要的一条）**：`TextStore` 只有 **2 个构造点**，**`lscpFirstValue` 不恒为 0** —— 主 store＝`0`（`FullTextState.cs:75`），**marker store＝`TextStore.LscpFirstMarker = (-0x7FFFFFFF)`**（`:100` ＋ `TextStore.cs:2376`）⇒ 契约里 **C3 必须写成"两参数对"**，**不得**把 0 当常量（否则 marker 段落恰差一个常数 ⇒ 正是反腿 (a) 的形态）。② **共现 5 件已逐件核完并收口**：全部是**同名不同义**（`TextStore` 局部变量；`FullTextLine` 的 `lsdcpSubLine`/`lsdcpRun`；`TextMetrics`/`LineServices` 的 `dcpDepend`/`dcpMaxContent`/`lsdcpSearch`/`lsdcpRun`；`LineServicesCallbacks.EnumText` 的 **dnode dcp**）⇒ **无桥**，`NOINFO-COOCURRENCE-SEMANTICS` 解除并并入 `PRECOND-LS-PROVENANCE-BRIDGE`。③ **责任方表**：C1 宿主（本侧可校值、不可校语义）；**C2 今天不存在，须新立**；C3 托管侧**已有**（构造时一次绑定、之后只读）；**C4 今天不存在，须新立**，且本侧**只能复算校验、不得自算**。④ **两条必红反腿已写死**（偏移错一／跨段复用同一 `plsrun` 表），并**如实标注今天都不可跑**（随内容层那一波），**不得**因此判绿或判红。⑤ 契约本体（objective／六条合取 acceptance／verify／inScope／outOfScope／粒度＝单段落）已成形，**本波不做**。
`P1-ls-provenance-contract 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ cae7e9aea21b57b9（末行＝本行）`

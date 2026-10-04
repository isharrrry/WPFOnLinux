# P1-W104 只读侦察：`plsrun`/`lscp` ↔ `nmp`/`dcp` 映射件（`LS-INBOUND-PROVENANCE`）

本件是**只读侦察**（`work` 类）：**不接实现、不跑腿、不构建、不占显示位、不 git 写**。靶心＝`t186` 具名的 `LS-INBOUND-PROVENANCE`。
所有读数来自**读取**（`grep`/`awk`/`wc` 计数），**行号一律整行取、不用 `cut` 截列**；引他人读数带代际并标「未独立复算」。

---

## §0 身份、边界与在飞件

- 载体：`build/MilBridge/P1-ls-provenance-recon.md`（**新建**，`temp+rename` 落盘）。写入面**仅本件**；`$N` 内其余件**一件未改**。
- ⚠️ **在飞件**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 开工现取 **`sha16=02d4c89fa432d4d2`**（330477 B，与 `t181` 交出同代）。本件靶心在**托管侧上游**，native 换代不影响引用；实现者仍须重取。
- HEAD＝`d7830c9`（新增 `P1` 派单模板）。

---

## §1 台账（读取时刻＝2026-09-29 20:03–20:12，本席本地，仅本次有效）

| 件 | sha16／行数 | 用途 |
|---|---|---|
| `PresentationCore/…/TextFormatting/TextStore.cs` | 2737 行 | **LS 侧锚点**：`_cpFirst`／`_lscpFirstValue`（`lscp ↔ cp`） |
| `PresentationCore/…/TextFormatting/FullTextState.cs` | — | `TextStore` 的构造点（`cpFirst` 来源、`lscpFirstValue = 0`） |
| `PresentationCore/…/TextFormatting/LineServices.cs` | `8b2bc2167f5c0bd3`（1620 行） | `Plsrun`/`lscp` 类型面（`t186` 已给 28 槽） |
| `PresentationFramework/…/PtsHost/PtsHost.cs` | `d1976dcc8362c8f9` | `dcpFirst` 的**唯一**上游落点（作为**入参**，来自引擎） |
| `PresentationFramework/…/PtsHost/ContainerParagraph.cs` | `1d0128592496706d` | `nmp` 的生产者原文（`nmpBeforeChange = …Handle`） |
| `PresentationFramework/…/PtsHost/Segment.cs` | — | `nmp` 的参数面 |
| `build/PresentationFramework.Linux/PtsCache.Linux.cs` | `48cf0d8d7d1a90dd`（1658 行） | **我方**对 `nmp` 的唯一源码命中（注释＋`Pair(ctx, nms, nmp)` 仪器） |
| `build/PresentationFramework.Linux/TextBlock.Linux.cs` | `6067276d0fc3a8da`（4143 行） | **我方**对 `dcp` 的唯一源码命中（TextBlock 布局的 `dcp` 游标） |
| `build/MilBridge/P1-ls-callback-face-recon.md`（`t186`，本席前件） | 189 行；自证 `8796763b3ae3cb15`（MATCH） | 本件的来源件 |

**扫描射程（Q4 的"无"判定必须附）**：
- 上游托管 `.cs`：**4188 件／2 055 597 行**（`upstream/wpf/src/Microsoft.DotNet.Wpf/src`，`find`＋`xargs wc -l` 计数现取）。
- 我方源码（`build/PresentationFramework.Linux`／`build/shims`／`src/WpfGfx.Linux*`）：**116 件／85 806 行**。

---

## §2 逐名命中（Q1）

| 名 | 上游 `.cs` 命中件数 | 我方**源码**命中 | native（`win32_pts.c`） | 语义（现取） |
|---|---|---|---|---|
| `plsrun` | **8** 件（全在 `PresentationCore/MS/internal/TextFormatting/`：`LineServices.cs`／`FullTextLine.cs`／`TextStore.cs`／`LineServicesRun.cs`／`FullTextState.cs`／`TextRunCacheImp.cs`／`LineServicesCallbacks.cs`／`TextProperties.cs`） | **0**（仅编译产物 `PresentationCore.dll`／`.pdb` 命中） | **0** | LS 侧的 **run 身份**（`Plsrun`） |
| `lscp` | **6** 件（`TextMetrics.cs`／`LineServices.cs`／`FullTextLine.cs`／`TextStore.cs`／`FullTextState.cs`／`LineServicesCallbacks.cs`） | **0**（同上） | **0** | LS 侧**字符位置** |
| `nmp` | **4** 件（`PtsHost.cs`／`Pts.cs`／`ContainerParagraph.cs`／`Segment.cs`） | **1** 件＝`PtsCache.Linux.cs` | **98** | PTS 侧**段落名**（＝托管句柄） |
| `dcp` | **34** 件（`MS/Internal/Text/*`、`MS/Internal/documents/*`、`MS/Internal/PtsHost/*`、`TextBlock.cs` 等） | **1** 件＝`TextBlock.Linux.cs` | **0** | **文档字符位置** |

**代表性原文（整行取）**：
- `TextStore.cs:48-50`：`private int _lscpFirstValue; // first lscp value`／`private int _cpFirst; // store first cp (both cp and lscp start out the same)`／`private int _lscchUpTo; // number of lscp resolved`
- `ContainerParagraph.cs:300`：`nmpBeforeChange = lastPara.Handle;`（另有 `:309 _ur.FirstPara.Previous.Handle`、`:314 IntPtr.Zero`）
- `PtsHost.cs:1914`：`int dcpFirst, // IN:  dcp at the beginning of the range`

---

## §3 现有对象身份：本侧今天持有 `nmp`／`dcp` 的**什么**（Q2，准入铁律逐项）

| 项 | 本侧现值 | 是谁的字段 | 谁写 | **本侧能否作为作者产出** | 判定依据 |
|---|---|---|---|---|---|
| **`nmp`** | `win32_pts.c` 的 **`drive_nmp`**（`:213` 字段；`:1465/:1468/:1486/:1598/:1611` 等处使用；值形态 `0x3`） | 本侧 doc 上下文里**存下来的宿主句柄**（来自托管 `+136 GetFirstPara` 的 **out**） | **宿主**（`PtsHost.GetFirstPara` → `ISegment.GetFirstPara(out fSuccessful, out nmp)`） | ❌ **不是作者**：它是**入站给的**；本侧只**保管＋原样回传**（`t155`/`t156` 在册） | `PtsCache.Linux.cs:1453-1456`（t155 仪器自述：`+136→+168` 吃下的 `nmp` "在托管侧到底是什么东西"）；`PtsHost.cs:596` `HandleToObject(nms) as ISegment` |
| **`nmp` 的语义身份** | 本侧**只知道"它是宿主给的一枚句柄"**；**无法自行解释它是哪个 `TextParagraph`** | — | — | ❌ | 具名 **`NOINFO-NMP-SEMANTIC-IDENTITY`**（`t155` 的仪器给出过**读数**，但读数不是本侧资产；本侧无托管类型知识） |
| **`dcp`** | native **0 命中**；我方源码唯一命中 `TextBlock.Linux.cs`（`dcp` 是**TextBlock 布局循环的游标**：`:1266 int dcp = 0;`…`:1330 dcp += line.Length;`） | **不是**本侧 doc 上下文里的字段 | 该游标由**托管 TextBlock 布局**自增 | ❌ **不是作者、也没有保管值** | 具名 **`NOINFO-DCP-VALUE`**（本侧上下文内无 `dcp` 任何形态） |
| **`plsrun`／`lscp`** | native **0**、我方源码 **0**（仅编译产物命中） | 归 LS 会话（宿主的 `TextStore`/`FullTextState`） | **宿主** | ❌ | `TextStore.cs:48-49`／`FullTextState.cs:72-77` |

⇒ **准入铁律小结（§A-5）**：这四个名字，**本侧一个都不是作者**；其中 `nmp` 是**入站句柄（可保管）**，`dcp`/`plsrun`/`lscp` **连保管值都没有** ⇒ 任何"本侧自造 dcp/run 身份"的实现都是 **native 自造**（红 `P3`）。

---

## §4 映射件到底缺什么（Q3）

**判词：缺的是「运行期对应关系」＋「责任方与时机」；**不**缺类型定义。**

| 候选 | 结论 | 现取依据 |
|---|---|---|
| **类型定义** | ❌ **不缺** | 两端类型都在：LS 侧 `Plsrun`／`lscp:int`（`LineServices.cs`）；PTS 侧 `nmp:IntPtr`／`dcp:int`（`Pts.cs`／`PtsHost.cs:1914`） |
| **运行期对应关系** | ✅ **缺**（本件核心） | 🔴 **同件共现排查（整仓 `.cs` 4188 件）**：`plsrun ∩ nmp` ＝ **0 件**；`lscp ∩ nmp` ＝ **0 件** —— **没有任何一件同时提到 LS 侧的键与 PTS 侧的段落名** |
| **谁在什么时候填** | ✅ **缺** | 全仓无承担该职责的件；`dcpFirst` 的唯一上游落点 `PtsHost.cs:1914/:1947/:2006/:2060` 是**入参**（引擎→宿主），**不是** LS 会话建立时的绑定 |
| （对照）**LS 内部锚点** | ✅ **已有**（只覆盖一半） | `TextStore` 维护 `lscp ↔ cp`：`:48-49` 两个字段、`:111-112` 初始化、`:151 lscpFetch -= _lscpFirstValue;`、`:153 Invariant.Assert(lscpFetch >= _cpFirst);`；构造时 **`lscpFirstValue` 显式传 0**（`FullTextState.cs:72-77`） |

**可证伪判据草案（下一波用它干活时当契约）**
- **`objective`**：建立并维持一张**锚点表**，使任取一个 LS 侧位置与一个 PTS 侧位置，**指向同一字符**。
- **`acceptance`（五条合取）**：① 同一段落内 `nmp`（本侧可认领）与 LS 会话标识（`plsrun` 起点，或 `LoCreateContext` 的 `ploc`）**一一对应，无第二关联**；② `lscp ↔ cp` 用 `_cpFirst`／`_lscpFirstValue` 复算一致（**现取**，不沿用）；③ `cp ↔ dcp` 的偏移**由宿主给出**并留痕（本侧不得自算）；④ **双向**验证：任取 `lscp` 与 `dcp` 各一，映射后指同一字符（**≥2 独立样本**，先证样本非空）；⑤ 每条读数带纪律三十三格。
- **必红反腿（至少一对）**：**(a) 偏移错一**：伪造"看起来对齐"的映射（差 1 个字符）⇒ 必须被判红（否则该判据无判别力）；**(b) 跨段复用**：让两个不同 `nmp` 共用同一 `plsrun` 表 ⇒ 必须被判红。

---

## §5 托管侧有没有现成答案（Q4）

**判词：有一半，缺另一半。**
- **有的一半**：`TextStore` 的 `lscp ↔ cp`（`TextStore.cs:48-49/:111-112/:151/:153`；构造处 `FullTextState.cs:72-77`，其中 `lscpFirstValue` **显式传 0**）⇒ **LS 会话内部的坐标锚点在托管侧已存在**。
- **缺的另一半**：`cp`（store 内）↔ `dcp`（文档级）——**没有任何件把两者连起来**；`dcpFirst` 在上游只作**入参**出现（`PtsHost.cs:1914` 等 4 件、均为 `PtsHost`）。
- **`plsrun` 与 `nmp` 的桥**：**无**（§4 的 0 件共现，射程 4188 件／2 055 597 行）。
- ⚠️ **口径边界（如实记）**：`lscp ∩ dcp`／`plsrun ∩ dcp` 各 **5 件**共现，全部在 **LS 侧**（`FullTextLine.cs`／`LineServicesCallbacks.cs`／`LineServices.cs`／`TextMetrics.cs`／`TextStore.cs`）；本席**只逐一核对了 `TextStore.cs`**（其 4 处 `dcp` 是**局部循环变量**：`:1922/:1943/:1945/:1964`），其余 4 件**未逐一核对** ⇒ 具名 **`NOINFO-COOCURRENCE-SEMANTICS`**（不许把那 5 件共现读成"桥已存在"）。

---

## §6 判词与下一步（Q5）

**判词：这条映射件「本波**不能**备齐」**（不是 `NOINFO`，而是**有据的"不能"**）：
- 依据：① 对应关系的**两端都在宿主**（`plsrun`/`lscp` 属 LS 会话、`nmp`/`dcp` 属 PTS/文档），**本侧对四者一个都不是作者**（§3）；② **桥不存在**（0 件共现，§4）；③ 要"备齐"必须先有**LS 会话 + 文本段落进链**，而这两样已被 `t185` 列为越级前置（`PRECOND-NEW-CALLBACK-FACE`／`NO-TEXT-PARA-IN-CHAIN`）。

**具名前置（本件补齐）**
- **`PRECOND-LS-PROVENANCE-BRIDGE`**（映射件本体）：`plsrun`/`lscp` ↔ `nmp`/`dcp` 的**运行期对应关系与责任方**在仓内**不存在**，须由"内容层那一波"**新立**；且**本侧不能作为作者**，只能**保管并复算**。
- **`NOINFO-NMP-SEMANTIC-IDENTITY`**：本侧只持有 `nmp` 的**值**，不持有其**语义身份**（哪个 `TextParagraph`）。
- **`NOINFO-DCP-VALUE`**：本侧上下文内**无 `dcp` 任何形态**。
- **`NOINFO-COOCURRENCE-SEMANTICS`**：`lscp ∩ dcp`／`plsrun ∩ dcp` 的 5 件共现**未逐一核对**（已核 `TextStore.cs`＝局部变量）。
- （沿用 `t185`/`t186`）：`PRECOND-NEW-CALLBACK-FACE`／`NO-TEXT-SOURCE`／`NO-LINE-BREAKER`／`NO-TEXT-PARA-IN-CHAIN`／`PRECOND-LS-SESSION-DRIVER`。

**最小可辩护形态（下一波要用它干活时的最小集）＝「锚点表四列 + 责任方」**
| 列 | 内容 | 今天的状态 |
|---|---|---|
| C1 | `nmp`（段落名，本侧**可认领**） | ✅ 本侧已持有（`drive_nmp`） |
| C2 | LS 会话标识（`plsrun` 起点 或 `LoCreateContext` 的 `ploc`） | ❌ 无（LS 会话尚不存在） |
| C3 | `lscp ↔ cp`（`_cpFirst`／`_lscpFirstValue`） | ✅ **托管侧已存在**（可引用，但须现取复核） |
| C4 | `cp ↔ dcp` 偏移 | ❌ 无（**必须由宿主填**） |
| — | **谁填 / 何时填** | ❌ 无（建议时机＝LS 会话创建时，由宿主一次性绑定并留痕） |

**下一步（仍只读/判据，不接实现）**：把 C1–C4 的**"谁填/何时填"**写成**绑定契约草案**（含 §4 的两条必红反腿），供将来那一波直接当验收面；**不要**在本波提出任何"本侧自算 dcp"的实现。

---

## §7 纪律落地与验收

- 🔴 **`P9`**：本件**不**把"本侧 0 实现/0 持有"推广成"映射不存在" —— 恰恰相反：**LS 内部的 `lscp ↔ cp` 锚点在托管侧已存在**（`TextStore` 现取），本件只判"**跨子系统的那一半没有桥**"。
- 🔴 **`P10`**：每条否定/存在性判定都附**前置与射程** —— "0 件共现"＝整仓 `.cs` **4188 件／2 055 597 行**；"本侧无 `dcp`"＝native `grep -c`＝0＋我方源码 116 件扫描；"`dcpFirst` 只作入参"＝4 件清单（全 `PtsHost.cs`）。
- 🔴 **恒真断言族**：本件读数**全部来自读取**（`grep`／`awk`／`wc`）；**未**使用"两样本一致"类证据（故无需证样本非空）；凡"0 件/0 命中"类**否定**均标了扫描射程。
- **验收**：新件、`mode 644`、首记号 `# P1-W104 `、末行自证并当场复算 MATCH、`temp+rename` 落盘。

---

## §8 附录：现取原文摘录（整行取，仅本次有效）

`TextStore.cs:48-50`：
```
        private int                     _lscpFirstValue;            // first lscp value
        private int                     _cpFirst;                   // store first cp (both cp and lscp start out the same)
        private int                     _lscchUpTo;                 // number of lscp resolved
```
`FullTextState.cs:72-77`（`TextStore` 构造，`lscpFirstValue` 显式传 0）：
```
            TextStore store = new TextStore(
                settings, 
                cpFirst, 
                0, 
                settings.GetFormatWidth(finiteFormatWidth)
                );
```
`TextStore.cs:151-153`：
```
            lscpFetch -= _lscpFirstValue;
            
            Invariant.Assert(lscpFetch >= _cpFirst);
```
`ContainerParagraph.cs:300`（`nmp` 的生产者原文）：
```
                    nmpBeforeChange = lastPara.Handle;
```
`PtsHost.cs:1914`（`dcpFirst` 的**唯一上游落点形态**：入参）：
```
            int dcpFirst,                       // IN:  dcp at the beginning of the range
```
`TextBlock.Linux.cs:1266`／`:1330`（我方唯一 `dcp` 源码命中，是**布局游标**）：
```
                int dcp = 0;
                        dcp += line.Length;
```

---

**判词（本席）**：① 四名分属**两个互不相通的子系统**——`plsrun`/`lscp` 只在 `PresentationCore/MS/internal/TextFormatting/`（8／6 件），`nmp` 只在 `PtsHost`（4 件），`dcp` 广布（34 件）；② **本侧对四者一个都不是作者**：`nmp` 是**入站句柄**（现取 `win32_pts.c:213 drive_nmp`，98 处使用），`dcp`/`plsrun`/`lscp` 在 native **0 命中**、我方**源码 0 命中**（仅编译产物含字符串）⇒ 自造即红 `P3`；③ **映射件缺的是「运行期对应关系＋责任方/时机」，不缺类型定义**——铁证是 **`plsrun ∩ nmp`＝0 件、`lscp ∩ nmp`＝0 件**（射程 4188 件／2 055 597 行）；④ **托管侧只有一半答案**：`TextStore` 的 **`lscp ↔ cp`**（`_cpFirst`/`_lscpFirstValue`，构造时 `lscpFirstValue=0`）已存在，**`cp ↔ dcp` 没有**，`dcpFirst` 在上游只作**入参**；⑤ **判「本波不能备齐」**（有据的不能），补齐具名 `PRECOND-LS-PROVENANCE-BRIDGE` ＋三条 `NOINFO`；⑥ **最小可辩护形态＝锚点表四列（`nmp` / LS 会话标识 / `lscp↔cp` / `cp↔dcp`）＋「谁填/何时填」**，配**两条必红反腿**（偏移错一／跨段复用）；⑦ **下一波要用它干活**时，直接以该四列当验收面，**不得**由本侧自算 `dcp`。
`P1-ls-provenance-recon 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 27a1ea496c79f08f（末行＝本行）`

# `P1-tail2` `TASK-0302` · 行模型**段末安全收束**（`PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS`）—— 实现报告（`T-A30`）

- **读时**：`2026-09-30T16:0x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=55ad709cbbb85c3a3e7f80becc4df10b715bd06b`（现取，**未换代**）。
- **改前件备份（仓外 `~/tA30-work/bak/`，`cp -p` 取自 `git show HEAD:`，逐字节复算 = 记录值）**：
  `PresentationCore.HbTextLine.cs.921ba9c6.bak`（`921ba9c65e9fb3be`）／
  `patch-presentationcore-textline-fallback.py.pre.bak`（`6c5707169950fcab`）／
  `TextFormatterImp.Linux.cs.fa058b13.bak`（`fa058b134c64e068`，生成件）／
  `PresentationCore.dll.fa058b13.bak`（`b80627500ee1639d`，由**改前件**重建现取，反极性腿用）。
- **只改**：`build/shims/PresentationCore.HbTextLine.cs`（`T-A30` 本体）＋ 生成器 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` ＋ 其**重产**的生成件 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs` ＋ 本载体。**未动** `src/**`／native／`bin/exports.txt`／任何复述位件（无产品计数变化 ⇒ 无可复述）。
- **黑名单遵守**：未动 `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`；**未跑**整趟 `verify-all`；重活（两趟构建 ＋ 12 趟腿）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID；禁 `sleep` 轮询；生成件 `temp+rename` 重产；模式守恒。
- **行号纪律**：本件行号**仅本次有效**（内容锚原文一并给出）。

---

## §0 结论速览（自包含）

1. **承重机制（本件现取证伪）**：`Line.FormattingResult`（`upstream/…/PtsHost/Line.cs:928-936` 逐字）
   `TextRun run = ((TextSpan<TextRun>)_runs[_runs.Count - 1]).Value as TextRun; if (run is ParagraphBreakRun) formatResult = ((ParagraphBreakRun)run).BreakReason;`
   —— **只认** `ParagraphBreakRun`／`LineBreakRun`（两者都是 `PresentationFramework` 的 **internal** 类型，**shim 编在 `PresentationCore` 造不出来**）。
   而 shim 的段末行**修前恒就地造** `new TextEndOfParagraph(1)`（shim `:3106` 旧形态）
   ⇒ 末行恒报 `fsflres=0`（`fsflrOutOfSpace`）⇒ **驱动收不到"段末"**。
2. **越界量恰为 1**：`dcpLine = line.SafeLength = _line.Length`（`TextParagraph.cs:711` → `Line.cs:860-866`），而本 shim 的 `Length` **含**那 1 个合成段末位（`int length = visibleLen + range.HardBreakLen + eop;`）
   ⇒ `ΣdcpLine = 段内符号位 + 1`（`0x8` 段现取 = **`956`**）⇒ 驱动下一跳探的偏移 = **段内符号位 + 1 = 段尾之后一格 = 下一个 `Block` 的 `ElementStart`**
   ⇒ `LineBase.HandleElementStartEdge`（`:137`）`Invariant.Assert(!(element is Block), …)` ⇒ **`Invariant.FailFast`（不可捕获）** ⇒ `app_rc=134`。
3. ⇒ **修法（唯一最小改动，且语义正确）＝「段末行的末 span **交回源自己的那个** EOL run」**：收集层在段末把那个对象存下来，透到 `FormatParagraph` → `HbTextLine`，`GetTextRunSpans()` 用它（而不是新造一个）。
   ⇒ 段末行 `Line.EndOfParagraph` 成立、`FormattingResult` 报 **`fsflrEndOfParagraph`(2)** ⇒ **驱动在段末收束，不再越界**。
4. **现取机读**（同一跑器、同一 `.so`、只换 `PresentationCore.dll`）：
   - 闸开＋改后：`[FORMATLINE-LINE]` **42** 行、其中 **`fsflres=2` 7 行**（每段末行一条）、`[FORMATLINE] … complete=1 v=LINES-RECORDED` **7/7**、`gap=0 incomplete=0`、**`failfast=0 unrec=0`、`app_rc=143 alive=yes`**。
   - 闸开＋改前（**单变量反腿**）：第 8 行 `fsflres=0` 之后**立刻** `FailFast`；`[FORMATLINE]` 汇总行**缺失**；**`failfast=4 unrec=2`、`app_rc=134 alive=no`** ⇒ **该红必红**。
   - 闸关（改后 5 样本 ＋ 改前 4 样本）：**帧 `sha16` 全程 `ef3fd6765f18f51b` 逐字节相同**；症状门六项逐格相同；两个**跑次敏感**计数（`no-text-line-model`／`[HC-UNHANDLED]`）两态**区间重叠** ⇒ 判"**缺省路径无产品差异**"（§3.4）。
5. 🔴 **产品面零进展（如实判红）**：内容区**仍无任何非空态像素** —— 具名色锚（`Beige`/`GhostWhite`/`LightGoldenrodYellow`/`LightGray`）**全 0**，且改后帧与改前**逐字节相同**。⇒ 本件**不**声称"页面可用"。
6. ⇒ **判决：合法终点（成功解除该具名前置，但产品面仍为降级态）**：`A29 §A` 的 4 条判据**逐条现取**（§5），`PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS` **在"行模型写域"内已解除**；**下一跳 ≠ 页面可用**（`PTS` 本体仍是占位降级，`FsQueryTextDetails` 回填**仍未实现**）。

---

## §1 机制取证（现取，逐跳）

### 1.1 契约（上游逐字）

| 面 | 件:行（现取） | 原文 |
|---|---|---|
| **判据（本件要保住的那条）** | `upstream/…/PtsHost/LineBase.cs:137` | `            Invariant.Assert(!(element is Block), "We do not expect any Blocks inside Paragraphs");` |
| 只认两种 run | `upstream/…/PtsHost/Line.cs:928-936` | `            TextRun run = ((TextSpan<TextRun>)_runs[_runs.Count - 1]).Value as TextRun;` ／ `            if (run is ParagraphBreakRun)` ／ `                formatResult = ((ParagraphBreakRun)run).BreakReason;` |
| `EndOfParagraph` | `Line.cs:841-853` | `                if (_line.NewlineLength == 0) { return false; } … return (((TextSpan<TextRun>)_runs[_runs.Count-1]).Value is ParagraphBreakRun);` |
| **`dcpLine` 的来源** | `upstream/…/PtsHost/TextParagraph.cs:711` ＋ `Line.cs:860-866` | `            dcpLine = line.SafeLength;` ／ `        internal int SafeLength { get { return _line.Length; } }` |
| **段末 run 的类型层级** | `upstream/…/PtsHost/RunClient.cs:203-209` | `    internal sealed class ParagraphBreakRun : TextEndOfParagraph` |
| 造它的两处（**都带 `fsflrEndOfParagraph`**） | `Line.cs:159`／`LineBase.cs:252` | `                    run = new ParagraphBreakRun(_syntheticCharacterLength, PTS.FSFLRES.fsflrEndOfParagraph);` |
| 合成位长度 | `LineBase.cs:373` | `        protected static int _syntheticCharacterLength = 1;` |
| **`fsflr` 枚举取值** | `upstream/…/PtsHost/Pts.cs:1094-1106` | `fsflrOutOfSpace = 0,`／`fsflrEndOfParagraph = 2,`／…／`fsflrSoftBreak = 8,` |
| 段末行的其它消费者（**类型安全**的根据） | `upstream/…/documents/TextBoxLine.cs:362-371` | 判 `((TextSpan<TextRun>)runs[runs.Count - 1]).Value is TextEndOfParagraph` ⇒ `ParagraphBreakRun : TextEndOfParagraph` **照样成立** |

### 1.2 shim 侧真身（逐字，改前）

| 面 | 件:行（改前现取） | 原文 |
|---|---|---|
| 段末 span **恒新造** | `build/shims/PresentationCore.HbTextLine.cs:3105-3106` | `            if (_hasEop)` ／ `                spans.Add(new TextSpan<TextRun>(1, new TextEndOfParagraph(1)));` |
| `Length` 含合成位 | 同上（`HbTextLine.FormatLine`） | `            int eop = range.HasEop ? 1 : 0;` ／ `            int length = visibleLen + range.HardBreakLen + eop;` |
| 收集层在段末**丢弃**那个 run | 同上 `TryCollect`（改前） | `                if (run is TextEndOfLine) break;                       // EOL / EOP（TextEndOfParagraph : TextEndOfLine）` |
| 生成件（宽松档）同病 | `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（改前 `fa058b13…`）`CollectLenient` | `                    break;                            // EOL / EOP（它的字符不属于段落正文）`（同样**不带走**那个 run） |

⇒ **判词**：**不是**"探测偏移算错了"，也**不是**"行模型把行断错了" —— 行断（`0,88,186,284,386,489,588,681` 与改前**逐字相同**）是对的；错的是**段末行没有把"段末"这件事交出去**，于是驱动把行宽里那 1 个合成位也累加成 `dcp`，**必然**多探一跳（`A29` §5 `NOINFO-SHIM-LINEBOUNDARY-VS-SYMBOL` 由此**消掉**）。

---

## §2 实现（逐处）

### 2.1 `build/shims/PresentationCore.HbTextLine.cs`（`921ba9c65e9fb3be` → **`e2fa9ec9be1a6cf1`**，293165 B → **300974 B**）

| 落点 | 内容（要点） |
|---|---|
| `HbTextLine` 新字段 | `private readonly TextRun _eopRun;` —— 段末行的末 span 用**源自己的**那个 EOL run（`null` ⇒ 退回旧行为，逐位相同）。 |
| 私有 ctor | 尾随可选形参 `TextRun eopRun = null` ⇒ `_eopRun = eopRun;`（既有调用点零改动）。 |
| `HbTextLine.FormatLine`（静态工厂） | 尾随可选形参 `TextRun eopRun = null` ⇒ 透给 ctor（**唯一行构造点**）。 |
| **`GetTextRunSpans()`** | 末 span 改为 `(_eopRun != null && _eopRun.Length == 1) ? _eopRun : new TextEndOfParagraph(1)`；`Length != 1` **不用**（本行 `Length` 记账按 `eop=1` 算 ⇒ 保守退回，**绝不静默改字长**）。 |
| `HbTextLineFactory.FormatParagraph` | 尾随可选形参 `TextRun eopRun = null`；**只有 `range.HasEop` 的那一行**带上它（其余行无 EOP span，传了也用不上）。 |
| 具名留痕 ＋ 计数 | 新增 `NoteParagraphEndRun(...)`：`ParagraphEndRuns` 计数 ＋（`WPF_LINUX_TEXTLINE_LSEM=1`）**有界**（前 12 条）具名行 `[TEXTLINE_LSEM] … eopRunType=<运行时类型名> … paraEndRuns=<n>` —— 防"形参加了、站点没传"（本项目 `#17` 族）。 |
| **严格档（`HbTextFallback`）** | `TryCollect` 增 `out TextRun eolRun`；`TryBuildPlan`／`TryFormatLine` 透传；取值判据 `eolRun = (run is TextEndOfParagraph) ? run : null;`（**硬断 `LineBreakRun` 不算段末**，免"提前收束 = 假成功方向"）。`TryMinMaxParagraphWidth` 只量宽，取到即弃。 |

### 2.2 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py`（**生成器**，`6c5707169950fcab` → **`65bbb96081299c72`**）

| 落点 | 内容 |
|---|---|
| `CollectLenient` 形参 | 新增 `out TextRun eolRun`（在 `out int modifierCloseIndex,` 之后）；函数头 `eolRun = null;` |
| 段末取值 | `EOL` 分支内、`break;` **之前**：`eolRun = (run is TextEndOfParagraph) ? run : null;` |
| 三个 `FormatParagraph` 站点 | 宽松档 `eopRun: eolRun`／max 探针 `eopRun: eolRun2`／min 探针 `eopRun: eolRun2`（**三站点同尺**，与既有 `modifierScopeEnd` 口径同源） |
| **生成件写盘** | 由 `open(GENERATED,"w")` 改为 **`temp+rename`**（`os.replace`，同目录原子）—— 就地截断写会留**半件** |
| **新牙齿（计数 ＋ 顺序）** | `n_eop_def/out1/out23/arg1/arg23/cap`＝`1/1/1/1/2/1`、`eopRun:` 合计 **3**；顺序断言「段末取值 下标 < `break;` 下标」。**另**：因实参表尾追加，`W23-B` 与 `P3` 两条既有 needle 的**收尾**从 `…);` 改为 `…,`（射程**一字未减**：仍是"段落原点 = `cpFirst`"／"同一组三个 modifier 实参"），并在原地注明。 |

### 2.3 生成件（**重产**，非手改）

`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`：`fa058b134c64e068`（69432 B，1319 行）→ **`6dff240b006b25e8`**（72014 B，**1334 行**，`+15` 行）。
`python3 …textline-fallback.py --check` ⇒ **全部牙齿通过**（含新增 6 条 T-A30 断言）；`python3 …textline-fallback.py` ⇒ `[生成] …已从上游重生成（2 处 D3 修改；temp+rename）`，**无 `.tmp-*` 残留**。
`diff` 改前/改后**只有 6 处**（`CollectLenient` 形参/取值/初始化 ＋ 3 个站点实参 ＋ 文件头注释），**无一字**落在度量/整形/断行算法上。

### 2.4 构建（现取）

`dotnet build -m:1 build/PresentationCore.Linux/PresentationCore.Linux.csproj -c Release --nologo` ⇒ **`0 警告 0 错误`**（13.9 s）；**复算可重现性**：同内容再建一次 ⇒ `sha16` **`e47c4b4521c54cb2`** 逐字相同。
构建期自报：`HbTextLineShimSha=e2fa9ec9be1a6cf15736c97712721110f732a4e9c45466b010e71fc0cd3d33c0（源 …/PresentationCore.HbTextLine.cs）`（= 新 shim 的**完整** sha256）。

---

## §3 成对机读读数（**同一跑器 ＋ 同一 `.so`**，只换 `PresentationCore.dll`）

**装置（四趟腿逐字同值）**：`LEGS_TOOLS runner_sha16=330a90f1f0ac28e4 session_sha16=f1a582d9ea9788c9 guard_sha16=962fec114b2d0692`；
`AUTHORITY:/APPDIR: shim=8ad9376305404ca2 pf=1757d610a687777c`（A 臂四件除 PC 外**全同**）；
五件（现取）：`libwpfwin32.so=8ad9376305404ca2`／`wpfgfx_cor3.so=941e69902d82ef02`／**`PresentationCore.dll=e47c4b4521c54cb2`（改后）｜`b80627500ee1639d`（改前）**／`PresentationFramework.dll=1757d610a687777c`／`WindowsBase.dll=3886f61b0251140e`。
`APPSYNC: SYNC-APPLOCAL=PASS … drift=0 rc=0`（**装置自己核过"应用目录里的件 == 权威件"**）。

### 3.1 症状门 ＋ 帧面（逐腿，现取）

| 腿 | PC | 闸 | `app_rc` | `alive` | `failfast` | `unrec` | `magenta` | `colors` | `ink` | `ns`（k24） | `fr_sha`(k24/k23) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `legs-eon` | 改前 | **开** | **134** | **no** | **4** | **2** | 0 | **1** | **0** | `…PracticalDemo` | `2a60a00fc582e97d`（残帧；k23 无） |
| `legs-aon` | 改后 | **开** | 143 | yes | **0** | **0** | 0 | 383 | 480000 | `…FlowDocumentDemo` | `ef3fd6765f18f51b`／同 |
| `legs-aon2` | 改后 | **开** | 143 | yes | **0** | **0** | 0 | 383 | 480000 | `…FlowDocumentDemo` | `ef3fd6765f18f51b`／同 |
| `legs-eoff` | 改前 | 关 | 143 | yes | 0 | 0 | 0 | 383 | 480000 | `…FlowDocumentDemo` | `ef3fd6765f18f51b`／同 |
| `legs-eoff3` | 改前 | 关 | 143 | yes | 0 | 0 | 0 | 383 | 480000 | `…FlowDocumentDemo` | `ef3fd6765f18f51b`／同 |
| `legs-off-oldB`／`oldC` | 改前 | 关 | 143 | yes | 0 | 0 | 0 | 383 | 480000 | `…FlowDocumentDemo` | `ef3fd6765f18f51b`／同 |
| `legs-off-newA`／`newB`／`newC` | 改后 | 关 | 143 | yes | 0 | 0 | 0 | 383 | 480000 | `…FlowDocumentDemo` | `ef3fd6765f18f51b`／同 |
| `legs-aoff`／`aoff2` | 改后 | 关 | 143 | yes | 0 | 0 | 0 | 383 | 480000 | `…FlowDocumentDemo` | `ef3fd6765f18f51b`／同 |

`k23`（`RichTextBoxDemo`）：`ae=0`／`colors=383`／`ink=480000`／`fr_sha=ef3fd6765f18f51b`，改前/改后/开/关**逐格同值**。

### 3.2 驱动面（`[FORMATLINE]`／`[FORMATLINE-LINE]`，`grep -c` 现取）

| 面 | `legs-eon`（改前·开） | `legs-aon`（改后·开） | `legs-aon2`（改后·开） | 闸关（任意腿） |
|---|---|---|---|---|
| `[FORMATLINE-LINE]` 行数 | **8**（然后 abort） | **42** | **42** | 0 |
| 其中 **`fsflres=2`**（段末收束） | **0** | **7** | **7** | 0 |
| `[FORMATLINE] … v=LINES-RECORDED`（`complete=1`） | **0**（该段汇总行**不存在**） | **7/7** | **7/7** | —（`gate=0 v=GATE-OFF calls=0`） |
| `… v=NO-COMPLETE-LINES` | 0（未及打印） | **0** | **0** | 0 |
| 窗级汇总 | **无**（进程死） | `attempted=3 ok_n=3 … calls=20 ok=3 gap=0 incomplete=0 nopara=0 v=DRIVEN`（bottomless）＋ `attempted=3 … calls=40 ok=6 gap=0 incomplete=0`（finite）＋ `attempted=1 ok_n=1 … calls=42 ok=7 gap=0 incomplete=0` | 同 | `v=GATE-OFF calls=0 ok=0 gap=0` |

**改后·闸开：逐段（`where` ＋ `para` ＋ 行数 ＋ `ΣdcpLine` ＋ `complete`）**

```
[FORMATLINE] where=FsCreatePageBottomless nmp=0x8 nlines=8 dcp_sum=956 last_rc=0 complete=1 truncated=0 v=LINES-RECORDED
[FORMATLINE] where=FsCreatePageBottomless nmp=0x9 nlines=6 dcp_sum=571 last_rc=0 complete=1 truncated=0 v=LINES-RECORDED
[FORMATLINE] where=FsCreatePageBottomless nmp=0xa nlines=6 dcp_sum=595 last_rc=0 complete=1 truncated=0 v=LINES-RECORDED
[FORMATLINE] where=FsCreatePageFinite     nmp=0x8 nlines=8 dcp_sum=956 …   ｜ nmp=0x9 nlines=6 dcp_sum=571 ｜ nmp=0xa nlines=6 dcp_sum=595
[FORMATLINE] where=FsCreatePageBottomless nmp=0x4 nlines=2 dcp_sum=43  last_rc=0 complete=1 truncated=0 v=LINES-RECORDED
```
**每段末行（7 条，逐字摘下 3 条）**：
```
[FORMATLINE-LINE] … para=0x8 i=7 dcp=681 rc=0 pfsline=0x13 dcpLine=275 fsflres=2 fforced=0 ascent=3342 descent=849 urbbox=0 durbbox=31359
[FORMATLINE-LINE] … para=0x9 i=5 dcp=482 rc=0 pfsline=0x19 dcpLine=89  fsflres=2 … durbbox=158903
[FORMATLINE-LINE] … para=0xa i=5 dcp=536 rc=0 pfsline=0x1f dcpLine=59  fsflres=2 … durbbox=101362
```
而**改前·闸开**同一位置：`… i=7 dcp=681 … dcpLine=275 fsflres=0 …`（**唯一差别就是这一格**），紧接着 `Unrecoverable system error.: We do not expect any Blocks inside Paragraphs`

### 3.3 行起点（D1 的正面读数）

改后·闸开、`para=0x8` 的 8 个行起点偏移 = **`0, 88, 186, 284, 386, 489, 588, 681`**（与改前**逐字相同**）；这 8 个偏移**全部被 `Line.GetTextRun` 真探过**（每行一条台账），**0 次撞 `HandleElementStartEdge` 的 Block 分支**（否则 `FailFast` 不可捕获 ⇒ 进程必死）。⇒ 驱动的**每一行起点**都在**元素安全位**上；**第 9 跳（`dcp=956`）不再发生**（末行 `fsflres=2` 即收束）。

### 3.4 缺省路径（闸关）**无产品差异** —— 判据 ＋ 跑次漂移区间

| 面 | 改前（4 样本） | 改后（5 样本） | 判词 |
|---|---|---|---|
| `reason=no-text-line-model` | `108,109,108,105` | `107,105,106,108,108` | **区间重叠**（`105..109`）⇒ 跑次敏感计数，**不作差异** |
| `[HC-UNHANDLED]` | `112,113,112,108` | `111,108,110,112,112` | **区间重叠**（`108..113`）⇒ 同上 |
| 帧 `fr_sha`（k24/k23） | 全 `ef3fd6765f18f51b` | 全 `ef3fd6765f18f51b` | **逐字节相同** ⇒ 产品面**零差异** |
| 症状门六项 ＋ `ae` | 全同 | 全同 | **逐格相同** |

> ⚠️ **如实记**：本件**先**跑的两趟（`legs-aoff`／`aoff2`）多导出了 `WPF_LINUX_TEXTLINE_DIAG/LINEDIAG` ⇒ 两边 env **不同源**，会把跑次漂移读成产品差异（第一版读数里改后 107/111 而改前 108/112 **看似**分开）。**已当场纠正**：加 `run-leg.sh`（**同源 env**：只导 `WPF_LINUX_TEXTLINE_LSEM`［＋按需 `WPF_PTS_FL_DRIVE`］）重取 **改后 3 样本 ＋ 改前 3 样本** ⇒ 区间重叠（本表）。旧读数保留在 `legs-aoff`／`aoff2` 作为"env 不同源 ⇒ 不可比"的**反例腿**。

---

## §4 反极性（**同一构建 ＋ 同一跑器 ＋ 同一 `.so`**，只差**一个件**：`PresentationCore.dll`）

| 判据（`A29 §A`） | 正极性（改后·闸开） | **反极性（改前 PC·闸开）** |
|---|---|---|
| **D1 元素安全** | `0` 次 `HandleElementStartEdge` 撞 Block（`failfast=0` ∧ 8 个行起点被真探过） | **第 9 跳探到 Block** ⇒ `FailFast` 栈逐字含 `LineBase.HandleElementStartEdge` |
| **D2 账守恒** | 7/7 段 `complete=1`（末行 `fsflres=2`） | **无任何段**收束（`fsflres=2` 行数 `0`）⇒ 账**不守恒**（驱动多走一格） |
| **D4 反腿** | `alive=yes / app_rc=143 / failfast=0` | **`alive=no / app_rc=134 / failfast=4 / unrec=2`** ⇒ **该红必红** |
| 帧面 | `ef3fd6765f18f51b`（与闸关同） | `2a60a00fc582e97d`（**abort 后残帧**：`colors=1`／`ink=0`） |
| `k23` 样本 | 有（`RichTextBoxDemo` 正常） | **无**（`converter-rc=1`：进程已死 ⇒ 转换器拒写） |

⇒ **两条独立证据**：① **机械面** —— 只把 `PresentationCore.dll` 从 `e47c4b4521c54cb2` 换回 `b80627500ee1639d`，`fsflres` 由 `2` 变 `0`、`failfast` 由 `0` 变 `4`；② **判词面** —— 改后的 `fsflres=2` **只可能**来自 `ParagraphBreakRun.BreakReason`（`fsflrEndOfParagraph=2` 与 `fsflrSoftBreak=8` 不同值 ⇒ **排除** `LineBreakRun`）⇒ **"段末行真的带上了源自己的那个 run"** 这一条**被机器钉死**，不是推理。

---

## §5 验收逐条（对 `T-A30` ③）

- **① `A29 §A` 的 4 条判据逐条现取 ＋ 每条带反极性**
  | # | 判据（可证伪） | 现取读数 | 反极性（该红必红） |
  |---|---|---|---|
  | **D1 元素安全** | 每一行起点的前向上下文 ∈ {Text／Inline 的 ElementStart/End／本段 ElementEnd}；**0** 次撞 Block | §3.3：`0,88,…,681` 八点被真探过 ∧ `failfast=0` | §4：改前件**撞 Block**（栈逐字）⇒ **红** |
  | **D2 账守恒** | `ΣdcpLine == 该段符号位` ∧ 末行 `fsflres ∈ {2,3,4,5}` | §3.2：`para=0x8 dcp_sum=956` ∧ 末行 `fsflres=2`；**7/7 `complete=1`** | 改前件 `fsflres=2` 行数 **0** ∧ **无汇总行** ⇒ **红** |
  | **D3 零假值／零回归** | 缺省路径（闸关）产品读数不变；断行语料不变 | §3.4：帧 sha **逐字节相同**、症状门逐格相同；§2.3：**diff 只有 6 处**，**无一字**落在断行/度量算法上 | 若"用断行变了换不 abort" ⇒ `legs-aon` 的行起点应与改前**不同**；实测**逐字相同** ⇒ 未走那条路 |
  | **D4 ≥2 独立样本 ＋ 反腿** | ≥2 独立样本同判；反腿（闸开 ＋ 未修件）必红 | `legs-aon`／`legs-aon2` **两样本同判**（`failfast=0`／`7/7 complete`／帧同 sha） | `legs-eon`：`app_rc=134`／`failfast=4` ⇒ **红** |
- **② 关键：闸开时 `pfnFormatLine` 驱动不再撞 `FailFast`（`app_rc≠134`、`failfast=0`）且给 `[FORMATLINE]` 行读数**：§3.2 —— **`failfast=0`、`app_rc=143`**；`[FORMATLINE-LINE]` 42 行 ＋ `[FORMATLINE]` 段级 7 行 ＋ 窗级 3 行**逐条现取**。**闸关时回改前**：§3.4（`gate=0 v=GATE-OFF calls=0 ok=0 gap=0`；帧/症状门与改前逐格相同）。
- **③ 帧面成对（不得把空白读成绿）**：§3.1 —— **内容区仍无任何非空态像素**：具名色锚 `Beige=0 GhostWhite=0 LightGoldenrodYellow=0 LightGray=51`（`LightGray` 是 UI 边框色，仅 51 px，且**改前后逐字同值**）；`colors=383`、帧 sha 与改前**逐字节相同** ⇒ **如实判红（产品面零进展）**。
- **④ 导出面／门禁**：**未动** native ⇒ `nm -D --defined-only libwpfwin32.so` 行数 **677** == `bin/exports.txt` 行数 **677**（逐名 `diff` **零差异**）；`PTSGAP=PASS tool=82 dead=11 artifact=1 ops=70 impl=73 so16=8ad9376305404ca2 exports=677`（rc=0，`PTSGAP_FRONTIER_STATE=NAMED`）；`DEFREG=PASS declared=225 route_ids=225`（rc=0，`DEFREG_DECLDRIFT=0 keys=-`）；`REPORTID=PASS files=314 ids=2222 declared=225`（rc=0；**本件落地前**现取 —— 本载体属该 glob，落地后 `files=315`，见 §6-4）。
- **⑤ 症状门成对**：§3.1（闸关 9 样本六项逐格相同；反极性腿 `alive=no/app_rc=134`）。

---

## §6 边界 · `NOINFO` · 主动披露

1. **改动面（`git status --porcelain` 现取）**：`M build/shims/PresentationCore.HbTextLine.cs`／`M src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` ＋ **本载体**（untracked）＋ **先于本件**的四项 untracked（`build/MilBridge/P1-tail2-tpcm-recon.md`／`build/MilBridge/tasks-tail2/T-A29.md`／`T-A30.md`／`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`）。`build/PresentationCore.Linux/TextFormatterImp.Linux.cs` 与 `bin/**` 是**生成/构建件**（每次由生成器/构建重产）⇒ 不在"手改面"内。
2. **`NOINFO-EXACT-SEG-SYMBOLCOUNT`（承 `T-A28` §6-4 `NOINFO-FORMATLINE-PARALEN`，**未消**）**：`D2` 的"`ΣdcpLine == 该段符号位`"这一半**只有自证级**证据（末行 `fsflres=2` ⇒ 排到段尾）；**独立**对账（`Paragraph.SymbolCount`）**无源** —— 托管侧 `SymbolCount` 在 `PresentationFramework` 内，本件写域**不含** `upstream/**`／PF。**口径如实写死**：驱动记的是 `SafeLength = _line.Length`（**含**那 1 个合成段末位）⇒ `ΣdcpLine = 段内符号位 + 1`（`0x8` 段现取 `956`）；`ActualLength`（`Line.cs:871-877`）才减去它。**消掉需要**：驱动点同趟打印该段 `SymbolCount`（native 侧只读插桩）。
3. **`RESID-LSEM-BUDGET-CONSUMED-BY-STARTUP`（具名）**：`[TEXTLINE_LSEM]` 有界预算（12 条）被**应用启动期**的普通段落（`eopRunType=TextEndOfParagraph`）**先耗尽** ⇒ **驱动那几段（宿主 `ParagraphBreakRun`）在该行里不显形**。**不影响结论**：`fsflres=2` 与 `fsflrSoftBreak=8` 不同值 ⇒ 段末 run **必然**是 `ParagraphBreakRun`（§4 的②）。**消掉需要**：把"非 `TextEndOfParagraph`"那一族单列预算（另一趟构建）。
4. **`ARTIFACT_SRC_FP` 的 `state=stale`（**先于本件**存在，已用只读探针证伪归因）**：`bash build/artifact-src-fp.sh --check` 现取 `rc=2`，`proj=PresentationCore fp=653c89f71484626d（改后）／dca259d86d8202ff（**把两件临时换成改前**再算）` vs 记录 `2f3e458da268e872` ⇒ **两态都 stale**，note 点名的漂移源是 `DirectWrite.Linux.Provider/bin/Debug/*` 与 `WindowsBase/bin/Debug/*`（**本件从未触碰**）⇒ **归因：先前既有**；本件的位移是**预期内**的（shim ＋ 生成件都是该投影的指纹源）。**本件不写** `ARTIFACT-SRC-FP.txt`（在 `T-A30` ② 的写域之外 ⇒ 留给波次；`--write` 是构建/发布口径）。
5. **`REPORTID` 计数（**落地后现取**）**：`REPORTID=PASS files=315 ids=2223 declared=225`（rc=0）。本载体属 `glob=build/MilBridge/*report*.md` ⇒ 落地前 `files=314 ids=2222` ⇒ **只差本载体这一件**；`ids` 由 `2222 → 2223` 的 **+1** 就是**本行这一处** `D-G56` 的引用（该牙的 `D-G[0-9]+` 口径），**该编号是既有已声明项**（故仍 `PASS`，零 `undeclared-id-in-route`）。⚠️ **本件不新增登记编号**（§5-① 的四条判据用 `D1..D4` 自名，**不**占用 `D-G*` 命名空间）。
6. **自伤／装置缺陷（如实登记，均已当场纠正）**：① 首版 `run-legs.sh` 把 `WPF_LINUX_TEXTLINE_DIAG/LINEDIAG` 也导出 ⇒ 两态 env **不同源**（§3.4 的 ⚠️）；② `run-legs-oldpc.sh` 第一版的输出目录**不带参数** ⇒ **第二趟把第一趟的 `legs-eoff` 覆盖掉**（第一趟读数 `108/112`、`6039` 行**只存在于本席会话打印**）⇒ 已加 `outdir` 形参并重取（现取 4 份改前关样本，**与结论无关**：区间重叠）。
7. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；未跑既有 parity 语料（`HbTextLineParity`/`CoverageProbe` 需另建应用件——本件以"**diff 逐处现取 ∧ 行起点逐字相同 ∧ 缺省帧逐字节相同**"替代，**并如实登记该替代为弱于跑语料**）；**未实现回填**（`FsQueryTextDetails` 等一字未改 —— 见 §0-6，那是**下一跳**）；未改任何复述位件（`docs/**`／`HANDOFF-NEXT.md`／`samples/**`）—— **无产品计数变化 ⇒ 无可复述**（`DEFREG_DECLDRIFT=0 keys=-`）。
8. **前提边界（写死）**：本件解除的是 **`PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS`**（行模型**段末安全收束**）；`WPF_PTS_FL_DRIVE` **缺省仍关**（`WPF_PTS_FL_DEFAULT 0` 未动）⇒ **产品缺省路径行为逐格不变**（§3.4）。**"从洋红占位变成真实排版"不在本件射程内**（内容区仍空 ⇒ §3.1 判红）；`PTS` 本体（`FsCreatePage*`）仍是**占位降级**。
9. **代际**：`build/shims/PresentationCore.HbTextLine.cs` = **`e2fa9ec9be1a6cf1`**（300974 B；改前 `921ba9c65e9fb3be`／293165 B）｜生成器 = **`65bbb96081299c72`**（91874 B；改前 `6c5707169950fcab`）｜生成件 = **`6dff240b006b25e8`**（72014 B；改前 `fa058b134c64e068`）｜`PresentationCore.dll` = **`e47c4b4521c54cb2`**（改前 `b80627500ee1639d`）｜`libwpfwin32.so` = `8ad9376305404ca2`（**未变**）｜`HEAD=55ad709cbbb85c3a3e7f80becc4df10b715bd06b`（**未换代**）。
10. **侧效（如实披露，**未进仓**）**：`~/tA30-work/`（`bak/` 五份改前件 ＋ `legs-*/` **12 趟腿**证据 ＋ 6 个跑腿/汇总/探针脚本）；`~/w67-work/app` 现**已同步回改后权威件**（`SYNC-APPLOCAL=PASS drift=0`；反极性腿临时把**权威** `PresentationCore.dll` 换回改前并**逐字节复算换回**：`AUTH_BEFORE=e47c4b4521c54cb2 → AUTH_RESTORED=e47c4b4521c54cb2`）。

SELF-SHA16 （口径 = `sed '$d' build/MilBridge/P1-tail2-lsem-impl-report.md | sha256sum | cut -c1-16`）= `c5fc91934a056a4a`

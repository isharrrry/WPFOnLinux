# P1-tail2 `T-A27` · 宿主侧「行模型」可得性（行断器／字符源／度量）—— 只读侦察

- **读时**：`2026-09-30T15:2x+0800`（本席现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=74a444cf32166130d85076627ab88636afc0fa96`（现取）。
- **现件代**（`sha256` 前 16 位，现取）：`bin/libwpfwin32.so`＝**`3795777128d29995`**（430240 B，与 `T-A26` 交出同代）｜`bin/exports.txt`＝`c561dda4eca311c5`（**677** 行）｜`src/WpfGfx.Linux.Native/src/win32_pts.c`＝`22a3503e37a703b6`（5802 行）｜`build/shims/PresentationCore.HbTextLine.cs`＝`921ba9c65e9fb3be`（4865 行）｜`build/PresentationFramework.Linux/PtsCache.Linux.cs`＝`e5b399fdb8742092`（1658 行，**生成件**）｜`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`＝`fa058b134c64e068`（**生成件**）｜`upstream/…/PtsHost/Pts.cs`＝`1a8575a18767a956`｜`PtsHost.cs`＝`d1976dcc8362c8f9`｜`PtsHelper.cs`＝`f2ed9552e983fed1`｜`TextParagraph.cs`＝`332b782b842e307e`｜`Line.cs`＝`f4b62971e881d247`｜`TextParaClient.cs`＝`be3e7a145113dca5`｜`…/TextFormatting/LineServices.cs`＝`8b2bc2167f5c0bd3`｜`LineServicesCallbacks.cs`＝`612c19e675b7ad30`。
- **边界（照 `T-A27` ②）**：**只读**；除本载体外**未改任何仓内文件**；**未改 `src/**`／`build/**`**（除本件）、**未构建**、**未跑整趟 `verify-all`**、**未跑 `static-jaws-check.sh`**；进程只按 PID；**未占任何显示位**；大件只用 `wc`／`head`／`tail`／`grep`（`sed -n` 只取原文行）；未 `git add/commit/push`。
- **行号纪律**：本件所有行号**仅本次有效**（内容锚原文一并给出，供下一位现取复核）。引他人读数**一律标注「未独立复算」**。
- **两处现取更正（先写在前面）**：
  1. 🔴 **`T-A26` 的"越级"判定被本件收窄**：`T-A26` 判"行盒要「行断器＋字符源＋度量」三样，源在宿主侧（越级），取它要**新开一条与 LineServices 同规模的链**"—— 前半句**现取成立**（三源确实在托管侧），**后半句现取不成立**：宿主侧行排版的那条链**已经接好且经既有回调可驱动**（`FSCBK.cbktxt.pfnFormatLine`，`PtsCache.Linux.cs:659` 已装配）⇒ **不需要** native `Lo*`（LS）一族（§1.4／§3）。
  2. **"宿主侧"＝托管侧**：本件一律指 `upstream/wpf/**` 的托管代码 ＋ `build/shims/**` ＋ `build/**/*.Linux/**`（生成件）；**不是** native `src/WpfGfx.Linux.Native/**`。

---

## §0 结论速览（自包含）

1. **三源现落点全部在宿主（托管）侧，且已在 PtsHost 链上**（§1）：**行断器**＝shim `HbBreakEngine`（`build/shims/PresentationCore.HbTextLine.cs:1580`）／上游真机＝native LineServices（声明 `LineServices.cs:1419` `LoCreateLine`）；**字符源**＝托管 `TextSource`（shim `TryCollect`，`:4578`）／上游回调 `LineServicesCallbacks.cs:59 FetchRunRedefined`；**度量**＝HarfBuzz advance（shim `:108 CharAdvances`）／上游回调 `LineServicesCallbacks.cs:447 GetRunCharWidths`。
2. **决定性信道（本件核心发现）**：`FSCBK.cbktxt.pfnFormatLine`（`Pts.cs:676`，`FSCBKTXT` 第 9 槽）—— **托管实现** `PtsHost.cs:1341` → `TextParagraph.FormatLine`（`TextParagraph.cs:664`）→ `Line.Format`（`Line.cs:255`）→ `_host.TextFormatter.FormatLine(...)`（`Line.cs:271`）。而 `TextFormatter` 在本移植**已被 patch 接 shim**（生成物 `TextFormatterImp.Linux.cs:692/723`）⇒ **行盒的全部字段（`pfsline`/`dcpLine`/`fsflres`/`dvrAscent`/`dvrDescent`/`urBBox`/`durBBox`）都诞生在托管侧**（`TextParagraph.cs:710-737`）。
3. **本移植现状**：宿主侧行模型**能跑且在链上**；缺口是 **native 侧从不驱动 `pfnFormatLine`** —— 现取 `grep -n 'cbktxt\.' src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **0 命中**（只有 `_Static_assert` 的**偏移常量**，`:834/:845-846`）⇒ native 无行记录可回填 ⇒ `FsQueryTextDetails` 恒拒（`reason=no-text-line-model 109`，现取 §2.3）。
4. **候选路（§3）**：**(甲)** 走 `build/shims/**` —— **可及**（`HbTextLine` 已在位）∧ **无事可做**（shim **就是**行模型，无缺口可补）∧ 代价＝0 ∧ `P8` 落点＝无；**(乙)** 走 `upstream/wpf/**` 的 LineServices（native `Lo*` 一族）—— 可及∧**不必要**（行排版已由托管 `pfnFormatLine` 承担）∧ 代价**极高** ∧ `P8` 落点＝`win32_pts.c`；**(丙)** native 侧**驱动既有 `pfnFormatLine`＋行记录缓存＋回查** —— **可及∧可行∧代价中∧`P8` 落点＝`src/WpfGfx.Linux.Native/src/win32_pts.c`（本仓写域内）**。
5. **结论 ＝ 判「可行」**（与 `T-A26` 收窄）：缺口**不在**"三源"，而在 **native 侧的格式化驱动＋缓存**，属本仓写域。⇒ **设计草案 ＋ 判据草案（6 条）＋ 反极性**（§4）。粒度＝**静态结构判定**（本件**未**跑腿，未实测 `pfnFormatLine` 真调能否成功 ⇒ §5 `NOINFO`）。
6. **本件自带两条反腿**（§5-P）：① 不把"宿主侧有行模型"读成"行盒今天可得"（缺 native 驱动 ⇒ 今天仍恒拒）；② 不把"`pfnFormatLine` 已装配"读成"已被调用"（grep 现取 0 调用）。

---

## §1 ① 三源各自现落点（件:行 ＋ 原文）

### 1.0 现取口径（可复跑）

```
$ grep -rn "LoCreateLine" upstream/wpf/src/…/PresentationCore/MS/internal/TextFormatting/LineServices.cs
$ grep -n  "FetchRunRedefined\|GetRunTextMetrics\|GetRunCharWidths" upstream/…/LineServicesCallbacks.cs
$ grep -n  "class HbBreakEngine\|class HbTextFallback\|TryCollect\|CharAdvances" build/shims/PresentationCore.HbTextLine.cs
$ grep -n  "pfnFormatLine\|pfnGetTextProperties\|pfnCreateParaBreakingSession" build/PresentationFramework.Linux/PtsCache.Linux.cs
$ grep -n  "^Lo" src/WpfGfx.Linux.Native/bin/exports.txt
```

### 1.1 源 A —— **行断器**

| 面 | 件:行 | 原文（整行现取） |
|---|---|---|
| 真机（native LS） | `upstream/…/TextFormatting/LineServices.cs:1419` | `        [DllImport(DllImport.PresentationNative, EntryPoint="LoCreateLine")]` |
| 同上（签名首行） | `…/LineServices.cs:1420-1422` | `        internal static extern LsErr LoCreateLine(` ／ `            IntPtr                  ploc,` ／ `            int                     cp,` |
| 本移植**真身** | `build/shims/PresentationCore.HbTextLine.cs:1580` | `    internal static class HbBreakEngine` |
| 本移植 native 侧 | `src/WpfGfx.Linux.Native/src/win32_pts.c`（`Lo*` 骨架） | `exports.txt` 现取仅 **8** 条 `Lo*`（`:309/:324-330`）：`LoAcquirePenaltyModule`／`LoCreateContext`／`LoDestroyContext`／`LoDisposePenaltyModule`／`LoGetEscString`／`LoGetPenaltyModuleInternalHandle`／`LoSetBreaking`／`LoSetDoc` —— **无 `LoCreateLine`** |

⇒ **落点判词**：真机上"行断算法"在 **native LineServices**（仓外 `PresentationNative_cor3.dll`；上游只有声明）；**本移植把它换成了 shim `HbBreakEngine`**（ICU 断点集＋贪心填宽）；**native `src/WpfGfx.Linux/**` 侧没有断行**（`LoCreateLine` 未导出）。
⚠️ **但对 PtsHost 而言，"行断器"不是通过 `Lo*` 被取用的** —— 见 §1.4。

### 1.2 源 B —— **字符源**

| 面 | 件:行 | 原文 |
|---|---|---|
| 上游托管回调 | `upstream/…/TextFormatting/LineServicesCallbacks.cs:59` | `        internal unsafe LsErr FetchRunRedefined(` |
| 本移植**真身** | `build/shims/PresentationCore.HbTextLine.cs:4578` | `        private static bool TryCollect(TextSource src, int cpFirst, out string text, out List<CollectedRun> runs)` |
| 生成物接线 | `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:170` | `        private static bool CollectLenient(TextSource src, int cpFirst,` |
| 同上（严格档调用点） | `…/TextFormatterImp.Linux.cs:692` | `                textLine = WpfLinux.Shims.PresentationCore.HbTextFallback.TryFormatLine(` |
| 消费者（PtsHost） | `upstream/…/PtsHost/Line.cs:271` | `                    _line = _host.TextFormatter.FormatLine(_host, dcp, _wrappingWidth, lineProps, textLineBreak, ctx.TextRunCache);` |

⇒ **落点判词**：字符源＝托管 `TextSource`（`src.GetTextRun(cp)`）；真机上由 LS 经回调 `FetchRunRedefined` 向宿主**取**；**本移植里 shim 自己 `TryCollect` 取**。

### 1.3 源 C —— **度量（字宽/字体度量）**

| 面 | 件:行 | 原文 |
|---|---|---|
| 上游托管回调（宽） | `upstream/…/TextFormatting/LineServicesCallbacks.cs:447` | `        internal unsafe LsErr GetRunCharWidths(` |
| 上游托管回调（度量） | `…/LineServicesCallbacks.cs:400` | `        internal LsErr GetRunTextMetrics(` |
| 本移植**真身** | `build/shims/PresentationCore.HbTextLine.cs:108` | `        internal double[] CharAdvances()` |
| 同上（advance 赋值） | `…/PresentationCore.HbTextLine.cs:304` | `                    r.AdvancesPx[i] = gp.XAdvance * scale;` |

⇒ **落点判词**：度量＝HarfBuzz `XAdvance`（shim）；真机上由 LS 经 `GetRunCharWidths`／`GetRunTextMetrics` 向宿主**取**。

### 1.4 🔴 **行盒的真源**：`pfnFormatLine`（本件核心）

> **总判词**：`FsQueryLineList*` 的行盒**不是** native LS 的产物，而是**托管 `Line`／`TextLine` 的产物**；native PtsHost 只**驱动**（回调）并**缓存**。

| 跳 | 件:行 | 原文 |
|---|---|---|
| H1 回调槽声明 | `upstream/…/PtsHost/Pts.cs:676` | `             internal FormatLine pfnFormatLine;` |
| H2 槽位（`FSCBKTXT` 第 9 槽，相对 `+328`／绝对 `+368`） | `Pts.cs:665-698`（`FSCBKTXT` 结构）；`P1-fscbk-slot-recon.md` §（表 #41） | `    internal struct FSCBKTXT` |
| H3 装配（**本移植生成件**） | `build/PresentationFramework.Linux/PtsCache.Linux.cs:659` | `            contextInfo.fscbk.cbktxt.pfnFormatLine = new PTS.FormatLine(ptsHost.FormatLine);` |
| H4 托管实现 | `upstream/…/PtsHost/PtsHost.cs:1341` | `        internal int FormatLine(` |
| H5 转派 | `…/PtsHost/TextParagraph.cs:664` | `        internal void FormatLine(` |
| H6 建 `Line` | `…/PtsHost/TextParagraph.cs:704` | `            Line line = new Line(StructuralCache.TextFormatterHost, paraClient, ParagraphStartCharacterPosition);` |
| H7 走 `TextFormatter` | `…/PtsHost/Line.cs:271` | `                    _line = _host.TextFormatter.FormatLine(_host, dcp, _wrappingWidth, lineProps, textLineBreak, ctx.TextRunCache);` |
| H8 **行盒字段全来自托管 `Line`** | `…/PtsHost/TextParagraph.cs:710-737`（逐字） | `            lineHandle = line.Handle;` ／ `            dcpLine = line.SafeLength;` ／ `            fsflres = line.FormattingResult;` ／ `            dvrAscent = line.Baseline;` ／ `            dvrDescent = line.Height - line.Baseline;` ／ `            durBBox = line.Width;` |
| H9 本移植 shim 接手 | `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:692` | `                textLine = WpfLinux.Shims.PresentationCore.HbTextFallback.TryFormatLine(` |

⇒ **H7＋H9**：`Line` → `TextFormatter.FormatLine` → （本移植）shim `HbTextFallback` ⇒ **行断器＋字符源＋度量三源同时在此链上闭环**。

---

## §2 ② 本移植里三源今天的状态（现取证据）

### 2.1 行断器 —— **有，能跑，且在 PtsHost 链上**（静态结构判定）

- 件：`build/shims/PresentationCore.HbTextLine.cs`（`921ba9c65e9fb3be`，4865 行），自陈 `:19-21`：断行引擎**「从 `build/MilBridge/tests/IcuBreakParity/` 原样搬进本文件 —— 从此**规则只有这一份**」**。
- 接线：`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（生成件）`:692`（严格档）／`:723`（宽松档）—— 两处都在 `new TextMetrics.FullTextLine(` **之前**（patch 脚本 `patch-presentationcore-textline-fallback.py` 的 `REP_1`／`REPLACEMENT_4` 现取，**未独立复算其生成结果**）。
- ⇒ 任何走 `TextFormatting.TextFormatter.FormatLine` 的调用者（含 PtsHost 的 `Line.Format`）都经此。

### 2.2 字符源／度量 —— **有，能跑**（同上链）

- 字符源：shim `TryCollect`（`:4578`）→ `src.GetTextRun(cp)`；度量：`CharAdvances`（`:108`）。
- ⚠️ **射程**：本席**未**在 PtsHost 调用点插桩，**无** "shim 在 PtsHost 链上真的接手了多少次" 的运行期读数（当代日志 `HB_TEXTLINE=0`，见 §2.3 ⇒ 该 app 腿未打印 shim 汇总行）⇒ 见 `NOINFO-HOSTLINE-SHIM-ON-PTSHOST`。

### 2.3 缺口 —— **native 侧从不驱动 `pfnFormatLine`**（现取，决定性）

```
$ grep -n 'cbktxt\.' src/WpfGfx.Linux.Native/src/win32_pts.c
（无输出 ⇒ 0 命中：本侧**从不调用 cbktxt 任何槽**）
$ grep -n 'CBKTXT' src/WpfGfx.Linux.Native/src/win32_pts.c
834:#define WPF_PTS_FSCBK_CBKTXT_OFF     256
845:_Static_assert(WPF_PTS_FSCBK_CBKTXT_OFF  == WPF_PTS_FSCBK_CBKGEN_OFF + WPF_PTS_CBKGEN_SLOTS * 8, "cbktxt base != cbkgen base + 32*8");
846:_Static_assert(WPF_PTS_FSCBK_CBKOBJ_OFF  == WPF_PTS_FSCBK_CBKTXT_OFF + WPF_PTS_CBKTXT_SLOTS * 8, "cbkobj base != cbktxt base + 31*8");
（⇒ 本侧**知道** cbktxt 在哪（31 槽／相对 `+256`），但**从不驱动它的任何槽**）
```
对照：native 侧**真调**的是 `cbkgen` 一族（`_Static_assert` 钉死 `+136 pfnGetFirstPara`／`+144 pfnGetNextPara`／`+168`／`+176`／`+192`，`:854-858`）—— 即"枚举子段／建客户端"，**不含行排版**。

**当代运行期读数**（现取；件＝`T-A26` 车道产物 `/home/links-dev/tA26-work/evidence-after/app_g1.log`，**仓外**，本席**只读**其 `grep -c`／`wc` 输出，**未独立复算**整腿）：
```
$ wc -l app_g1.log                                  ⇒ 6086
$ grep -c 'entry=FsQueryTextDetails' app_g1.log     ⇒ 109
$ grep -o 'reason=[a-zA-Z-]*' app_g1.log | sort | uniq -c
    109 reason=no-text-line-model
     17 reason=handle-zero
      4 reason=null-subtrack
      1 reason=need-real-format-frame
   1785 reason=ok
$ grep -c 'FsQueryLineList' app_g1.log              ⇒ 0   （托管走不到三入口：前置 cLines 拿不到）
$ grep -c 'HB_TEXTLINE' app_g1.log                  ⇒ 0   （该腿未打印 shim 汇总行；**不能**据此判"shim 没跑"）
```
⇒ 与 `T-A26` §3 成对读数一致（`no-text-line-model 109`）。

### 2.4 现状小结（写死）

| 源 | 本移植今天 | 证据 |
|---|---|---|
| 行断器 | **有（shim）**，在 `TextFormatter` 链上 | `0HbTextLine.cs:1580`／生成物 `:692` |
| 字符源 | **有（托管 `TextSource`）** | `0HbTextLine.cs:4578` |
| 度量 | **有（HarfBuzz）** | `0HbTextLine.cs:108/:304` |
| **native 行记录（行盒回填源）** | **无** —— 从不驱动 `pfnFormatLine` | `win32_pts.c` `grep cbktxt.` **0**；`FsQueryTextDetails` 恒拒 **109** |

---

## §3 ③ 候选路（甲／乙／丙）逐条：可及 ∧ 可行 ∧ 代价 ∧ `P8` 落点

### （甲）走 `build/shims/**`（`HbTextLine` 等既有 shim）补齐行/run

| 维度 | 现取判词 |
|---|---|
| **可及性** | **可及** —— `HbTextLine`／`HbBreakEngine`／`HbTextFallback` **已在位且已在链上**（生成物 `:692` 现取）。 |
| **可行性** | **无事可做**：本件现取的结论是 **shim 就是行模型本身、没有缺口可补** —— 三入口要的行盒在**托管侧已由 shim 产出**，缺的是 native **驱动**（§2.3）。⇒ 在 `build/shims/**` 内**没有**能改变 `FsQueryLineList*` 可得性的改动（shim 已最大化）。 |
| **代价** | **0**（若强行改 shim，只会在**已验证**的行模型上引入回归）。 |
| **`P8` 落点** | **无**（本路不需改任何件）。 |
| **判定** | **本路不成立**（不是"不可及"，是"**无事可做**"）。 |

### （乙）走 `upstream/wpf/**` 的 LineServices（需 native `Lo*` 一族）

| 维度 | 现取判词 |
|---|---|
| **可及性** | **可及** —— `Lo*` 声明齐（27 条 `[DllImport]`，`LineServices.cs:1407-1551` 现取）；本侧已导出 **8** 条（§1.1）；`cbktxt` 偏移已钉（`:834`）。 |
| **可行性** | 🔴 **不必要** —— 行排版**已由托管 `pfnFormatLine` 承担**（§1.4 H4-H9）；native LS 只在**托管 `TextFormatter` 内部**才被用到（`TextFormatterContext.cs:113/:288/:354`，**引自 `P1-ls-callback-face-recon.md`，未独立复算**），而**那一层已被 shim 替换**（生成物 `:692/723`）⇒ 在 native 侧重建 LS **不会**给 `FsQueryLineList*` 多带来任何行盒（它在托管侧已全有）。 |
| **代价** | **极高** —— 需 native 重实现 LS 排版算法 ＋ 回调面（`P1-ls-callback-face-recon.md` 28 槽／最小集 9 槽，**引自该件，未独立复算**）＋ **重入口径**（`PRECOND-LS-SESSION-DRIVER`）。 |
| **`P8` 落点** | `src/WpfGfx.Linux.Native/src/win32_pts.c`（**本仓写域内**）。 |
| **判定** | **不可取**（代价极高 ∧ 与本件现取的"行盒真源"不符 ⇒ 病急乱投医）。 |

### （丙）native 侧**驱动既有 `pfnFormatLine`**（＋行记录缓存＋回查）—— **本件推荐路**

| 维度 | 现取判词 |
|---|---|
| **可及性** | **可及** —— ① `pfnFormatLine` **已装配**（`PtsCache.Linux.cs:659` 现取）；② 入参三身份**已在位**：`pfsclient`（client opaque）／`nmp`（托管段句柄，来自 `+136/+144` 枚举）／`pfsparaclient`（托管客户端句柄，来自 `+176`）；③ 配套槽（`pfnGetTextProperties` `:652`／`pfnCreateParaBreakingSession` `:650`／`pfnGetTextParaCache` `:672`／`pfnSetTextParaCache` `:673`）**全装配**（现取）。 |
| **可行性** | **可行** —— 行由**托管**算（shim），native 只**驱动＋保管返回值**（与 `(甲)`／`(乙)` 的区别：本路**不自造**任何行/字符/宽度 ⇒ 不触 `P3`）。 |
| **代价** | **中** —— native 侧一条链：格式化会话（`GetTextProperties`→`CreateParaBreakingSession`→循环 `FormatLine`→`DestroyParaBreakingSession`）＋ 每段行台账（有界＋计数＋成环守卫，可扩既有 `wpf_pts_sub_enum` 形制）＋ 三入口回填。 |
| **`P8` 落点** | **`src/WpfGfx.Linux.Native/src/win32_pts.c`（＋ `bin/exports.txt` 若增导出）** —— **不涉任何生成件**（⇒ 不触 `P8` 的"生成件只许改生成器"分支）。 |
| **判定** | **可行**（本仓写域**内**；§4 给设计草案＋判据草案）。 |

---

## §4 ④ 结论 ＝ 判「可行」＋ 设计草案 ＋ 判据草案（≥3 条 ＋ 反极性）

### 4.1 判词（写死）

> **就「宿主侧行模型能否在本仓写域内被提供」作答：宿主侧行模型**已经存在**（shim `HbTextLine`／`HbBreakEngine`：行断器＋字符源＋度量三合一），**且已经接在 PtsHost 的行排版链上**（`pfnFormatLine` → `TextParagraph.FormatLine` → `Line.Format` → `TextFormatter.FormatLine` → shim）。
> ⇒ `FsQueryLineList*` 的"出参无源"**不是**三源缺失，而是 **native 侧从不驱动 `pfnFormatLine`**（`grep cbktxt.` ⇒ **0**）⇒ native 无行记录可回填 ⇒ `FsQueryTextDetails` 恒拒（`no-text-line-model 109`）。
> ⇒ **判定：可行**，解除条件 = **native 侧的"格式化驱动 ＋ 行记录缓存 ＋ 回查"**（路 `(丙)`），**属本仓写域**。
> ⚠️ **粒度**：本判词是**静态结构判定**（读件 ＋ `grep`），**不含**任何"`pfnFormatLine` 真调可成功"的运行期读数（§5 `NOINFO`）。
> ⚠️ **与 `T-A26` 的关系**：**收窄**，非推翻 —— `T-A26` 的"三源在宿主侧"**现取成立**；其"取它要新开与 LineServices 同规模的链"**现取不成立**（§1.4）。

### 4.2 设计草案（3 步，一步一判；**本波不做**，仅登记供排期）

1. **窗内驱动**：在 `FsCreatePage*` 窗内（`wpf_pts_sub_enum` 现成骨架），对每个枚举出的**文本段落**（`nmp`／`pfsparaclient`）依次调 `cbktxt` 槽：`pfnGetTextProperties`（取 `FSTXTPROPS`）→ `pfnCreateParaBreakingSession`（取断行记录 `pbrLineIn`）→ **循环** `pfnFormatLine`（累计 `dcp`，页几何 `urStartLine`／`durLine`／`urStartTrack`／`durTrack`／`urPageLeftMargin`）→ 收 `pfsline`／`dcpLine`／`fsflres`／`dvrAscent`／`dvrDescent`／`urBBox`／`durBBox`／`pbrlineOut`；**有界**（行数上界）＋**成环守卫**（`dcpLine<=0` ⇒ 停并具名）。
2. **行记录台账**：每段的行序落进本侧 doc 台账（与 `sub_children[]` 同形；段落身份用**来源证据**，不用数值相等）。
3. **回查**：`FsQueryTextDetails` 从台账回填 `cLines`／`dcpFirst`／`dcpLim`／`fsktdFull`；`FsQueryLineListSingle`／`…Composite` 回填行盒（`pfslineclient = pfsline`）；`FsQueryLineCompositeElementList` 回填元素表（`pLine` 用台账里的行句柄认领）。**未驱动／未造型／认不出身份 ⇒ 拒**（出参**一字不写**）。

### 4.3 判据草案（6 条可证伪 ＋ 反极性必红腿）

| # | 判据（可证伪） | 反极性（必红腿） |
|---|---|---|
| **D1 零假值／出参纪律** | 拒绝路径出参**一字不写**（承 `FsQueryTextDetails` 现状 `out=UNWRITTEN bytes=0`）。 | 为让 `rc=0` 好看写常量 `cLines` ⇒ **必红**（写 `0` ⇒ 消费者读成"0 行"⇒ **静默丢整段**，裁定四十八 (c)）。 |
| **D2 永不假成功** | `rc=0` **仅当**：行记录真来自 `pfnFormatLine` 返回值 ∧ `dcpLine` 账守恒（Σ`dcpLine` == 段长）∧ 几何有源。 | 返 `rc=0` ＋ 常量／估算 ⇒ 伪成功 ⇒ **必红**。 |
| **D3 失败必留痕** | 任何拒绝**必**打具名行（`entry=` ＋ `reason=` ＋ `calls/ok/gap`）且 `gap` **恰涨 1**（承 `[FSQLL]`／`[FS_PAGE_GAP]` 现状）。 | 静默 stub（返非 0 零痕迹）⇒ 与"真 0 次调用"**不可分** ⇒ **必红**。 |
| **D4 驱动计数（"接了但没生效"的唯一防线）** | `pfnFormatLine` **真被调** ⇒ 计数 ≥1 且出现在具名汇总行；**未驱动** ⇒ 计数 **0**。 | 只加接线、窗口没到 ⇒ `pfnFormatLine` 恒 0 调用却"看起来接上了" ⇒ **必红**（半接线假修，承 `D-T5-R` 一族教训）。 |
| **D5 窗内／窗外分开报** | **窗内驱动数**与**窗外汇总数**分开判词；**不**把"窗内可得"读成"查询期可得"（`CurrentFormatContext` 只在 `FsCreatePage*` 内可用，承 `P1-tail2-hostface-recon.md` §3.3）。 | 把窗内 `[FORMATLINE]` 读成"查询期已可答" ⇒ **必红**。 |
| **D6 ≥2 独立样本** | ≥2 独立 PID／启动时刻，判词**相同**。 | 单样本当机制 ⇒ **必红**。 |

---

## §5 边界 · `NOINFO` · 主动披露

1. **未改任何仓内文件（除本载体）**；**未构建**；**未跑整趟 `verify-all`**／`static-jaws-check.sh`；**未占显示位**；未 `git add/commit/push`。
2. **引他人读数（标「未独立复算」）**：§1.1 的 `Lo*` 27 条声明与 §3(乙) 的 28 槽／9 槽最小集，**引自 `P1-ls-callback-face-recon.md` 与 `P1-ls-family-recon.md`**（本席**只**现取它们的目标文件名与结论，**未复跑**其全表）；§1.4 H2 的"第 9 槽／相对 `+328`／绝对 `+368`"**引自 `P1-fscbk-slot-recon.md`**（本席**独立**现取了基址断言 `win32_pts.c:834/845-846` 与槽名序 `Pts.cs:674-680`，**未逐一复算 103 槽**）；§2.3 的运行期计数取自 `T-A26` 车道产物 `/home/links-dev/tA26-work/evidence-after/app_g1.log`（**仓外**，本席**只**现取 `wc`／`grep -c` 输出，**未复跑腿**）。
3. **`NOINFO`（逐条给消掉条件）**：
   - **`NOINFO-HOSTLINE-FORMATLINE-RUNTIME`**：`pfnFormatLine` 在本移植里**从未被调用过**（`grep cbktxt.` 现取 0）⇒ "真调能否成功"**无运行期读数**（本席未跑腿）⇒ 消掉需 native 侧一次**具名驱动腿**（窗内真调 `pfnFormatLine` ＋ 打 `[FORMATLINE]` 留痕）。
   - **`NOINFO-HOSTLINE-SHIM-ON-PTSHOST`**：shim `HbTextFallback` 在 **PtsHost 链**（`Line.Format` → `TextFormatter`）上**是否真的接手**（本席只有**静态**接线证据：生成物 `:692/723`；当代腿日志 `HB_TEXTLINE=0` 不足以判"没跑"）⇒ 消掉需在 PtsHost 调用点插桩。
   - **`NOINFO-HOSTLINE-NATIVE-BACKFILL-SEMANTICS`**：真机 `FsQueryTextDetails`／`FsQueryLineList*` 在 native PtsHost 内"从行记录回填"的**确切字段映射**（`pfslineclient`↔`pfsline`／`dcpFirst`↔累计 `dcp`）本席**未实测**（只有 `FSLINEDESCRIPTIONSINGLE` 结构面 ＋ `TextParagraph.cs:710-737` 的**结构对应**）⇒ 消掉需一条**真机**（Windows）对拍或 native 侧真实现后自证。
   - **`NOINFO-HOSTLINE-WINDOW-AT-DRIVE-SITE`**：`pfnFormatLine` **只能在 `FsCreatePage*` 窗内**调（`CurrentFormatContext`）—— 本席仅有**同族**证据（承 `P1-tail2-hostface-recon.md` §3.3 的 `-100002 ×576`，**引自该件，未独立复算**）⇒ 消掉需在**驱动点**直接插桩。
4. **前提不符（如实记）**：派单 `T-A27` ① 设问"三源落点：`upstream/wpf/**` 的 LineServices/`TextFormatter` 面？`build/shims/**`？`src/WpfGfx.Linux/**`？"—— 现取答案：**行断器／字符源／度量的"真身"都在 `build/shims/**`（＋托管 `upstream/**` 的回调声明面）；`src/WpfGfx.Linux/**` 侧一条都没有**（§1）。
5. **代际**：`.so`＝`3795777128d29995`；`win32_pts.c`＝`22a3503e37a703b6`；`PtsCache.Linux.cs`＝`e5b399fdb8742092`；全部托管上游件指纹见件头（**本件未改它们**）。
6. **本件自带的两条反腿**：① §4.1 —— 不把"宿主侧有行模型"读成"行盒今天可得"（缺 native 驱动 ⇒ 今天仍恒拒）；② §2.3 —— 不把"`pfnFormatLine` 已装配"读成"已被调用"（`grep` 现取 0 调用）。
7. **未做**：未判相位；未动任何牙本体；未跑任何门禁；未改 `src/**`／`build/**`（除本件）。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-hostline-recon.md | sha256sum | cut -c1-16`）= `5d02d562c8a22c84`

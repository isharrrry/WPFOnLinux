# P1-W41 · W8 **重新定靶**（`t110`／`t114` 之后）—— 下一跳是谁（**台账已空 ⇒ 换口径**）＋ `TASK-0302` 剩余清单 ＋ 相位翻转包

> **本件是只读侦察＋盘点件**：**不做**实现、**不构建**、**不跑腿**、**不占显示位**，供**队长排期**与随后的**实现件／判据件**当依据。
> **一切读数由我现取**（命令与输出原样贴出）；**未引任何既有报告当证据**（`t107` 的载体只作**对照**引用且**状态已现取重判**；其余报告一条读数未抄）。
> **边界（硬）**：只读仓树；唯一写入 ＝ 本件；**未** `dotnet build`、**未**跑腿、**未**占显示位、**未**跑整趟门禁、**未** `git add/commit/push`；未改任何判据件／产品件／装置件／`ROUTES.md`／`HANDOFF-NEXT.md`／`tools/**`／`src/**`。
> **读取时刻**：`ts=2026-09-29T03:21:40.189+0800`（起点）→ `2026-09-29T03:23:23.150+0800`（末取）。

---

## §0 快照与现取读数

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`fdd8917`**（`docs(#81): t115 字体栈降级独立复核载体入账（§A 崩进程修复面成立 / §B C6 红面归因成立=判据相位位）`） | `git log --oneline -8` |
| 工作树 | 5 项：`M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/{device.txt,leg_23.env,leg_24.env}` ＋ `?? …/arm_A/app_g1.log` ＋ `?? src/tests/` —— **全属他人** | `git status --porcelain` |
| 导出面 | `nm … \| grep -c .` ＝ **572** ＝ `wc -l …/exports.txt` ＝ **572**（`exports.txt` sha16 `b1996a77bfbf869d`） | `nm`／`wc -l` |
| 权威 `.so` | `a131ea4e6f5cc4f5` | `sha256sum` |
| PTS 桩件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`ec5c877c897d2b7f`**；名册 `k_pts_entries[]` 现取 **13** 名；**真 stub 字面 ＝ 3**（`GetFloaterHandlerInfo:353`／`GetTableObjHandlerInfo:360`／`LoDisposePenaltyModule:749`；`grep -c` 得 4，其中 1 行是注释 `:69`） | `sed`／`grep -n` |
| 缺口面 | `check-shim-coverage.py --tier mapped` ⇒ `rc=0`；**`[PresentationNative_cor3.dll] 96 条`**；其中 **`Fs*` ＝ 66 条** | 现跑（§2.1） |
| 三格 | `PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=87 so16=a131ea4e6f5cc4f5 exports=572` | 现跑 |
| **探针前沿** | `PTSGAP_FRONTIER before=LoCreateContext@3 after=@0 carrier_sha16=1ad94ad71f59e6fb carrier_mtime=2026-09-29 03:14:39.174582733 +0800 ts=2026-09-29 03:23:00.144497935 +0800`｜**`PTSGAP_FRONTIER_STATE=UNNAMED`** | 同上 |
| **台账面** | `app_g1.log`（sha16 `1ad94ad71f59e6fb`，461567 B，`mtime 03:14:39`）里 `^PTS_GAP entry=` ＝ **0 行**、`PTS-UNAVAILABLE` ＝ **0 行**、`Invariant.FailFast` ＝ **0 行** | `grep -c` |
| 两页症状（在册腿） | `leg_23.env`（**`f192ff72370bac64`**）：`LEG k=23 alive=yes app_rc=143 magenta=0 colors=383 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=0 ink=480000`｜`leg_24.env`（**`985786434ef2672a`**）：`… k=24 … magenta=0 colors=383 ns=…FlowDocumentDemo ae=15386 ink=480000`｜两腿 `NAMED managed_unavail=0 err=- native_gap=0 native_err=-`｜两腿 `DEV … shim=a131ea4e6f5cc4f5 pf=2988f5154ecac5dd`（⇒ **同趟性 ＝ yes**） | `cat`／`sha256sum` |
| **`[HC-UNHANDLED]` 面（本件最重要的新读数）** | 总数 **1081**，**全部 `EntryPointNotFoundException`**；按入口名：**`FsCreatePageBottomless` × 1080**、**`FsCreatePageFinite` × 1** | `grep -c`／`grep -o … \| sort \| uniq -c` |
| `FONT_FALLBACK` 面（`t114` 诊断，现取全 11 行） | `requested=DEJAVU fallback=no resolved=none`／`requested=GLOBAL USER INTERFACE fallback=yes resolved=none`／`requested=NOTO SANS CJK JP fallback=no resolved=NOTO SANS CJK JP`（×2）… `:30-32 requested=DEJAVU fallback=no resolved=none`／`requested=ARIAL fallback=yes resolved=none`／`requested=DEJAVU SANS fallback=no resolved=DEJAVU SANS`… `:691-692 requested=GEORGIA fallback=no resolved=none`／`requested=ARIAL fallback=yes resolved=none` | `grep -n` |
| 守卫 | `bash build/MilBridge/tools/pts-pages-guard.sh --legs <evidence>` ⇒ **`rc=1`**；`PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=degraded`；`PTS_G10_NAME=PASS form=unnamed` | 现跑 |
| 截图面 | `shots/g1/{k23,k24,last}.png` **三件 sha256 完全相同**（`ef3fd6765f18f51bc443ad0eb8e2185f75549936c120c0589cbfad264e9d3915`，各 189716 B，`mtime 03:14`）；`boot.png` 不同（`b21eb530afd3c66c…`）；`shotstat.py` 三件现跑：`boot 386/0/480000`、`k23 383/0/480000`、`k24 383/0/480000`（`colors/magenta/ink`） | `sha256sum`／现跑 |

---

## §1 ① **下一跳是谁**（本件最重要的产出）

### 1.1 现取：**台账面已经空了**，探针面也空了

```
grep -cE '^PTS_GAP entry='   app_g1.log   ⇒ 0
grep -c  'PTS-UNAVAILABLE'   app_g1.log   ⇒ 0
两腿 NAMED native_gap=0
PTSGAP_FRONTIER … after=@0 ／ PTSGAP_FRONTIER_STATE=UNNAMED
```
⇒ **旧口径（`^PTS_GAP entry=`）今天给不出任何名字**。**这不是"判据失灵"，是三个结构性原因叠加**（逐条现取）：

| # | 原因 | 现取证据 |
|---|---|---|
| R1 | **`Fs*` 根本不在名册里** | `k_pts_entries[]`（`win32_pts.c`）现取 13 名：`CreateInstalledObjectsInfo`／`DestroyInstalledObjectsInfo`／`CreateDocContext`／`DestroyDocContext`／`GetFloaterHandlerInfo`／`GetTableObjHandlerInfo`／`LoCreateContext`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle`／`LoDestroyContext`／`LoSetDoc`／`LoSetBreaking`／`LoDisposePenaltyModule` —— **一个 `Fs*` 都没有** |
| R2 | **`Fs*` 一个都没导出** ⇒ 异常在 **CLR 里**抛，**native 一行都进不去** | `nm … \| grep -cx 'FsCreatePageBottomless'` ＝ **0**（同 face 里 `Fs*` 在 `EntryPointNotFoundException` 面里 **66 条**，见 §2.1） |
| R3 | 台账 `wpf_pts_gap()` **只在"已导出但未实现"的 stub 里被调** | `grep -n 'return wpf_pts_gap("'` 现取只剩 3 处（名册里其余 10 名已是真实现 ⇒ 它们走 `g_pts_seen[]` 而不走 `g_pts_calls[]`，**而 `g_pts_seen[]` 只活在进程内，日志里不带出来**） |

⇒ **口径必须换**，且换法不能是"按静态调用序假装是运行期读数"。

### 1.2 **换什么口径**（写死；含代价）

| 项 | 旧口径 | **新口径（本件采用）** |
|---|---|---|
| 面 | native 台账 `^PTS_GAP entry=`（按 `seq=` 排序） | **托管具名异常面**：`^\[HC-UNHANDLED\] #<n> EntryPointNotFoundException: Unable to find an entry point named '<入口名>' in shared library '<dll>'` |
| 域名册 | `k_pts_entries[]`（13 名） | **上游声明面** `upstream/wpf/…/PresentationNative` 的 `Pts.cs` 声明名（现取 `Pts.cs` 的 `DllImport` 行 **73** 条） |
| 为什么换 | 对 **ENFE**（符号不存在）**结构性失明**：① 名册不含 `Fs*`；② 没导出 ⇒ 进不了 native ⇒ 台账无法记账 | 该面**自带入口名**（异常文本里逐字给出）**且天然带次数**（同一入口抛几次就几行） |
| **代价（必须一并记住）** | — | ① 它**只能给"名字 ＋ 次数"**，给不出 native 侧状态（`g_pts_calls`／`g_pts_seen`／`live` 面全无）；② 它的**捕获方是应用自己的钩子**（现取：`~/hc-linux/src/Shared/HandyControlDemo_Shared/App.xaml.cs` 里发 `[HC-UNHANDLED]`）⇒ **它是否常开、会不会截断**由**第三方应用**决定，**不在我方写域**；③ 该面**混入任何** `EntryPointNotFoundException`（不只 PTS 族）⇒ 归因必须**按入口名过滤**，不许只看总数 |

### 1.3 **下一跳（现取运行期读数，点名）**

```
grep -c 'HC-UNHANDLED'                                    ⇒ 1081
grep -o "entry point named '[A-Za-z0-9_]*'" | sort | uniq -c | sort -rn
  ⇒ 1080  'FsCreatePageBottomless'
  ⇒    1  'FsCreatePageFinite'
grep -oE '\[HC-UNHANDLED\] #[0-9]+ [A-Za-z]+' | awk '{print $3}' | sort | uniq -c
  ⇒ 1081  EntryPointNotFoundException     （**没有第二种异常**）
```
> **⇒ 下一跳 ＝ `FsCreatePageBottomless`（1080 次），紧随其后的是 `FsCreatePageFinite`（1 次）。**

**上游声明与调用点（现取原文）**：
```
upstream/wpf/…/PresentationFramework/MS/Internal/PtsHost/Pts.cs:3128
        internal static extern int FsCreatePageBottomless(
            IntPtr pfscontext,                  // IN:  ptr to FS context
            IntPtr fsnmsect,                    // IN:  name of the section to start from
            out FSFMTRBL pfsfmtrbl,             // OUT: formatting result
            out IntPtr ppfspage);               // OUT: ptr to page, opaque to client

调用点（上游，唯一）：
upstream/wpf/…/PtsHost/PtsPage.cs:295
            int fserr = PTS.FsCreatePageBottomless(PtsContext.Context, _section.Handle, out formattingResult, out ptsPage);

同族对照：
Pts.cs:3110 FsCreatePageFinite(...)   ← 调用点 PtsPage.cs:397
FlowDocumentFormatter.cs:99  _documentPage.FormatBottomless(pageSize, pageMargin);   ← 为什么 bottomless 是主路
```
**为什么是 bottomless 而不是 finite（现取）**：`FlowDocumentFormatter.Format` 走的是 `_documentPage.FormatBottomless(...)`（`FlowDocumentFormatter.cs:99`，在 `:90 ComputePageMargin()` 之后）⇒ **文档页用 bottomless 通路** ⇒ 1080∶1 的分布与代码一致（那 1 次 finite 来自另一条通路，例如非 `FlowDocumentView` 的固定页测量）。

### 1.4 ⚠️ **本件的第二发现（与"下一跳"同等重要）：两页现状**不是**"真排版"**

现取三条，互相独立：

1. **三张截图逐字节相同**：`k23.png` ＝ `k24.png` ＝ `last.png`（同一个 `sha256`，各 189716 B）⇒ **两页给出的画面完全一样**。
2. **画面内容是 demo 的"敬请期待"空态页，不是 `FlowDocumentDemo` 的内容**：
   - `~/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Main/UnderConstruction.xaml:16` 逐字：`<TextBlock … Text="{ex:Lang Key={x:Static langs:LangKeys.ComingSoon}}" …/>`（`LangKeys.ComingSoon` ＝ **敬请期待**，现取 `LangProvider.cs:1613`）。
   - 同一件 `:11-15` 是 `hc:GifImage Width="400" Height="300"` 指向 `Resources/Img/under_construction.gif` ⇒ **画面里那张插图 ＋ 下面那行"敬请期待"就是它**（行号仅本次有效）。
   - 而 `FlowDocumentDemo.xaml` 的内容（现取 `:101-113`：`:101 hc:TransitioningContentControl`／`:102 TabControl`／`:103-111` 三个 `TabItem`）是 **`TabControl` ＋ 三个 tab**（`FlowDocumentScrollViewer`／`FlowDocumentPageViewer`／`FlowDocumentReader`）承载 Neptune 长文档（含 `<Figure>`／`<Floater>`／`<Table>`／`<Hyperlink>`）—— **画面里一个都没有**。
   - 且现取 `grep -ci 'neptune' app_g1.log` ＝ **0**。
3. **像素位移极小**：`AE`（点击前后像素差）k=24 ＝ **15386**（≈ 全屏 1.2%）、**k=23 ＝ 0**。
   ⚠️ **`leg23-AE=0` 的语义有一处歧义（如实写清）**：它只能证明"**点击前后像素没变**"，**分不开**（i）"两页内容本来就长得一样" 与（ii）"第 23 页根本没重绘、画面是上一页留下的"。**要分开需要改点击次序**（例如 `clicks=[23,24]`，或中间夹一次第三个页面）——**这是现成的、便宜的判别实验**（见 §2.3-N3）。

> **⇒ 结论（写死）**：**现取的在册证据不支持「两页真排版」**。它支持的是：**进程活了、我方洋红占位消失、字体栈能画出真汉字**（那行"敬请期待"是真字形）；**不支持**"Neptune 文档与富文本框内容被排版出来了"。
> ⚠️ **机制（谁把 `UnderConstruction` 放上去的）＝ `NOINFO`**（见 §5-N1）：现取到 `PracticalDemo.xaml:9` **内嵌** `<userControl:UnderConstruction …/>`（而 `PracticalDemo` 正是**首屏**，`MainWindow.xaml.cs:38` 送 `MessageToken.PracticalDemo`），因此"画面是首屏残留"与"内容区失败后落到空态"**两种可能本件分不开**。**这正好是 §1.1-R2 那 1080 次 ENFE 的直接后果面**，两条读数互相印证。

---

## §2 ② `TASK-0302` 的**剩余面**（可执行清单）

### 2.1 `Fs*` 族 **66 条**（现取条数 ＋ 清单来源）

```
python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped > /tmp/t112cov.out; echo rc=$?
grep -E '^  \[PresentationNative_cor3\.dll\] [0-9]+ 条' /tmp/t112cov.out     ⇒   [PresentationNative_cor3.dll] 96 条
grep -cE '^  PresentationNative_cor3\.dll  Fs' /tmp/t112cov.out              ⇒   66
grep -oE '^  PresentationNative_cor3\.dll  Fs[A-Za-z0-9_]*' /tmp/t112cov.out | awk '{print $2}'
```
**清单来源**：该工具的明细行**同时给出声明位 `file:line`**（每行形如 `PresentationNative_cor3.dll  <名>  探测 …  upstream/wpf/…/Pts.cs:<行>`）⇒ **每一条都能回源到 `Pts.cs` 的声明**，不是凭名字前缀猜的。
**前 20 名（现取，按工具输出顺序）**：`FsClearUpdateInfoInPage`／`FsClearUpdateInfoInSubpage`／`FsClearUpdateInfoInSubtrack`／`FsCompareSubpages`／`FsCompareSubtrack`／`FsCreatePageBottomless`／`FsCreatePageFinite`／`FsCreateSubpageBottomless`／`FsCreateSubpageFinite`／`FsDestroyPage`／`FsDestroyPageBreakRecord`／`FsDestroySubpage`／`FsDestroySubpageBreakRecord`／`FsDestroySubtrack`／`FsDestroySubtrackBreakRecord`／`FsDuplicatePageBreakRecord`／`FsDuplicateSubpageBreakRecord`／`FsDuplicateSubtrackBreakRecord`／`FsFormatSubtrackBottomless`／`FsFormatSubtrackFinite`。

| 项 | 内容 |
|---|---|
| **现状现取读数** | `[PresentationNative_cor3.dll] 96 条` 中 `Fs*`＝**66**；**`FsCreatePageBottomless` 运行期被撞 1080 次**、`FsCreatePageFinite` 1 次（§1.3）；`nm` 命中 **0** |
| **入口原文** | `Pts.cs:3128-3132`（bottomless，见 §1.3 原文）、`Pts.cs:3110`（finite） |
| **判据草案（verify 单行）** | `cd $N && python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped >/tmp/fs.out 2>/tmp/fs.err; echo rc=$?; grep -cE '^  PresentationNative_cor3\.dll  Fs' /tmp/fs.out; nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| grep -c '^.* T Fs'; grep -c 'Unable to find an entry point named' <evidence>/app_g1.log` |
| **期望形状（本增量）** | `Fs*` 缺口条数**真降**（每补一条降 1）；`nm` 的 `T Fs*` **真升**；`[HC-UNHANDLED]` 里 **`FsCreatePageBottomless` 计数归零**（**这是"真被补上了"的行为面证据**，比条数更硬） |
| **是否触覆盖面** | **触**：新增 C 源在 `src/WpfGfx.Linux.Native/src/**` ⇒ 在 `fp_inputs()` 的 `*.c/*.h` 那行里 ⇒ **移动 `inputs_fp`**（流程上必须排在 `IN_FP_0` 采样前） |
| **依赖** | ① `g_pts_seen[]` 面（若要给"被问过"留痕）；② `FSFMTRBL`／`FSFMTR` 结构（`Pts.cs` 现取有声明，**布局权威只有托管侧那一份**——与 `t110` 的 `FSCONTEXTINFO` 同族风险）；③ 收尾对端（`FsDestroyPage` 等）是否须同趟补 |
| **代价量级（只给结构）** | **不是一次一跳**：66 条里与"两页能排版"直接相关的是一小簇（`FsCreatePageBottomless`／`FsCreatePageFinite`／`FsFormatSubtrack*`／`FsDestroyPage*`，**具体簇大小本件未定** ⇒ 见 §5-N2）；**每一簇都要"创建 ＋ 收尾对端 ＋ 计数 ＋ 镜像"四件套**（照 W8 各步形制）；**且必须先解决"出参结构布局"这一关**（否则会把 `-10000` 换成越界写） |

### 2.2 两条仍在的诊断（各自是什么、怎么清零）

| 诊断 | 它是什么（现取原文） | 为什么今天在 | **怎么清零** |
|---|---|---|---|
| **`leg24-colors-out-of-band=383`／`leg23-…=383`** | `pts-pages-guard.sh:393-394`：`if [ "$colors" -lt 800 ] \|\| [ "$colors" -gt 1200 ]; then diags+=("leg$k-colors-out-of-band=$colors")` —— **`diags` 不进 `rc`**，只是登记 | 该带 `[800,1200]` 是**洋红占位期**的经验值（当时占位帧 `colors` 现取 843/844/851/852）；今天真渲染帧是 **383**（`boot=386`）⇒ **带子过时** | 两条路（**判据件写者域，本件只列**）：① 该带**重定**（改用"与 boot 帧的差"或"与占位期带的互补判据"）；② **随相位翻转一并重划**（`realized` 期本就该换证据位）。**不许**为了消诊断把带子放宽到"永远不会红"（那等于删掉这条牙） |
| **`leg23-AE=0(点击前后无像素差)`** | 同件 `:395`：`if [ "${ae:-}" = "0" ]; then diags+=("leg$k-AE=0(点击前后无像素差)")` —— 同样只进 `diags` | 现取 k=23 的 `ae=0`（k=24 是 15386） | **不是把它消掉，而是把它变成承重判据**：先做 §1.4-3 的**判别实验**（换点击次序）分清"两页同貌"与"没重绘"；分清之前**它必须保持在场**（它是"这一页到底画没画"的唯一在手信号） |

### 2.3 「两页真排版」的判据**还缺哪些可判证据**（本件新拟 N1–N4；全部来自上现取读数）

| # | 缺口 | 现取证据（今天的值） | 拟判据（可跑 verify） |
|---|---|---|---|
| **N1** | **`ink` 没有区分力** | `ink=480000` **在 `boot`／`k23`／`k24` 三帧上完全相同** ⇒ `pts-pages-guard.sh:385` 的 `realized` 期要件 `ink -gt 0` **在今天的读数上恒真**（它是 `total − magenta − 众数色` 的**帧常量**，不是"排了多少内容"） | 换证据位：要求"**与同趟 boot 帧的像素差**"或"**该页专有内容的存在性**"（如 Neptune 文档特有的长文本区域）；至少**禁止**把 `ink>0` 单独当排版证据 |
| **N2** | **"ENFE 被静默吞"没有判据** | `[HC-UNHANDLED]` **1081** 行（1080×`FsCreatePageBottomless`）而守卫**一个字都不读它** | 新格：`grep -c 'Unable to find an entry point named' <evidence>/app_g1.log` **必须 ＝ 0**（`realized` 期）；且按入口名点名 |
| **N3** | **两页"是否各自画过"没有判据** | `k23.png` ＝ `k24.png` **逐字节相同**；`ae` k23=0／k24=15386 | 新格：**要求两页帧不相同**（`sha256` 不等）**或**给出"两页内容确实同貌"的独立证据；并强制点击次序至少包含"某页作为**首击**"的一趟（消 `AE` 歧义） |
| **N4** | **"内容是不是该页的"没有判据** | 画面现取是 demo 的 **敬请期待** 空态（`UnderConstruction.xaml:16`），且日志里 `neptune` 命中 **0** | 新格：**内容身份**读数（例如"该页专有字符串出现"或"截图与 boot 帧的差落在内容区"）；**不许**只按 `ns=` 判（`ns` 现取只证明"加载了那个类型"，不证明"画出了它的内容"—— t110 那趟 `ns=FlowDocumentDemo` 与本次画面**同时成立**就是反例） |

---

## §3 ③ **相位翻转包**（裁定二十）；**本件只列清单，不改任何件**

### 3.1 要改的位（逐条现取）

| # | 位置 | 现取原文/形态 | 翻转要做什么 |
|---|---|---|---|
| F1 | `build/MilBridge/tools/pts-pages-guard.sh:51`（件头机读行） | `# PTS-DIRECTION: absent="magenta=0" present-floor=20000 red-when="magenta=0 AND no-named-line AND native_gap=0" source=TASK-0741 phase=degraded` | `phase=degraded` → **`phase=realized`**（**这一位就是相位开关**，见 F2） |
| F2 | 同件 `:195-199`（解析＋校验） | `PHASE="$(printf '%s' "$line" \| sed -n 's/.*phase=\([a-z]*\).*/\1/p')"`；非法 ⇒ `PTS_DIRECTION=FAIL reason=phase-missing-or-invalid` | **不动**（它是"取不到就响亮失败"的牙）；翻转后它仍须在（`:585` 有"phase 位缺失 ⇒ 判词必红"的自检例） |
| F3 | 同件 `:378-391`（腿级绿条件） | `realized` 支：`magenta -eq 0` ∧ 无具名行 ∧ `ink>0`；`degraded` 支：`magenta ≥ 20000` ∧ `err=-10000` | 翻到 `realized` 支后 **必须同时**按 §2.3-N1 换掉 `ink>0` 单要件 |
| F4 | 同件 `:405-409`（台账要件） | `realized`：`ngap_total -eq 0`；`degraded`：`ngap_total -ge 1` | 翻到 `realized` 支（今天 `ngap_total=0` ⇒ 会绿）；**但须补 N2**（否则"ENFE 吞掉"也绿） |
| F5 | 同件 `:555`（自检里的 realized 副本） | `sed 's/^\(# PTS-DIRECTION: .*\)phase=degraded$/\1phase=realized/' "$0" > "$_rz"` | **不动**（它是两极化装置）；但 **c15–c19 那 5 例**的期望值须随 §2.3 的新格**同趟重划**（见 3.2） |
| F6 | 同件 `:393-395`（诊断带 `colors`） | `-lt 800 \|\| -gt 1200 ⇒ diags+=…` | 见 §2.2 第 1 行（重定带 or 随相位重划） |
| F7 | 复核位（**另一族**） | `PTS_G10_NAME=PASS form=unnamed`（现取） | 相位翻转**不影响**它（它是名字归属判据）⇒ **不需要动**；但 §2.3-N4 的新格与它**口径不同**，不许混 |

### 3.2 「10 条 degraded 正控」（**逐条现取原文**；本件给的是**完整自检清单**，不是转述）

自检共 **24 条 `chk` 断言**（`grep -c 'chk '` 现取 ＝ 24）。**degraded 期的前 10 例（c1–c10）**，逐条原文：

| 例 | 现取原文（期望） | 相位相关性 |
|---|---|---|
| c1 | `good c1; chk PASS … "全好(54454/49864)"` | **相位相关**：翻转后 `magenta=54454≠0` ⇒ **期望必须反过来（FAIL）** |
| c2 | `chk FAIL … "rc=134/alive=no"` | 相位无关（活/死两期都红） |
| c3 | `chk FAIL … "alive 但洋红 0"` | **相位相关**：`magenta=0` 在 realized 期正是**绿**条件 ⇒ 期望要改（这正是"反转"的本意） |
| c4 | `chk FAIL … "洋红 19999(<门槛)"` | **相位相关**（`MAGENTA_FLOOR` 只在 degraded 支用） |
| c5 | `chk PASS … "洋红 =20000(边界必过)"` | **相位相关**（同上） |
| c6 | `chk NOINFO … "ns=BrushDemo(点错对象)"` | 相位无关 |
| c7 | `chk FAIL … "无具名行"` | **相位相关**：realized 支要求"无具名行"是**绿**，degraded 支缺具名行是**红** ⇒ 期望反向 |
| c8 | `chk PASS … "native err=0 ⇒ PASS+DIAG"` | **相位相关**（依赖具名行要件） |
| c9 | `chk NOINFO … "x_up=no"` | 相位无关（装置自证） |
| c10 | `chk NOINFO … "空证据目录"` | 相位无关 |

**realized 侧既有 5 例（c15–c19，现取原文）**：`rz c15 PASS "realized·真实形态"`／`rz c16 NOINFO "realized·缺 ink ⇒ NOINFO"`／`rz c17 FAIL "realized·占位仍在 ⇒ FAIL"`／`rz c18 FAIL "realized·具名行仍在 ⇒ FAIL"`／`c19 … chk FAIL … "I1/N2-b：只降级不画 ⇒ 必红"`。
⇒ **翻转包必须同趟做**：把 c1/c3/c4/c5/c7/c8 的**期望值按 realized 支重写**，**并把 §2.3 的 N1–N4 加成 c2x 新例**（每题都要有"正极必绿 ＋ 反腿必红点名"成对）。

### 3.3 翻转后**会变语义**的既有读数（逐条点名）

| 读数 | degraded 期语义（今天） | realized 期语义 |
|---|---|---|
| `magenta` | `≥20000` ＝ 占位还在 ＝ **绿** | `=0` ＝ 占位消失 ＝ **绿**（`≠0` ⇒ 红） |
| `NAMED … err=` | 必须是 `-10000`（具名失败行在位） | 必须是 `-`／空（**不许**再有具名失败行） |
| `native_gap` | `≥1`（台账非零） | `=0`（`≥1` ⇒ 红） |
| `ink` | **不被读** | 被读（`>0`）——⚠️ 见 §2.3-N1：**今天它没有区分力** |
| `PTS-DIRECTION` 行 | `absent="magenta=0"` ⇒ `magenta=0` 是**缺席**语义 | 同一句在 realized 期**变成"应然"语义** ⇒ 该句的**文字**必须同趟重写（否则件头自相矛盾） |
| `direction=in-file`／`phase=degraded` 判词尾 | 登记相位 | 相位字符串变 ⇒ **所有引用该串的文档/牙都要同趟跟**（"逐字相同"型对拍会红） |

### 3.4 🔴 **翻转的硬前置（本件新加；不满足则翻转＝假绿）**
**现取反证（本件实测）**：把今天的两腿读数喂给 `realized` 支，要件是
`magenta=0`（**现取 0 ✔**）∧ 无具名行（**现取 `-` ✔**）∧ `ink>0`（**现取 480000 ✔**）∧ `native_gap=0`（**现取 0 ✔**）
⇒ **今天直接翻相位，守卫会 `PASS`**，**而**：`[HC-UNHANDLED]` 仍有 **1081** 条（1080×`FsCreatePageBottomless`）、两页截图**逐字节相同**、画面是 demo 的**敬请期待**空态、日志里 `neptune` 命中 **0**。
⇒ **结论（写死）**：**「翻转」必须以 §2.3 的 N1–N4 同趟落定为前置**；否则这次翻转就是一次**判据放松**（把"没排版"判成"排版了"）。裁定二十那句"前置 ＝ 两页真排版"**在今天的现取读数上不成立**。

---

## §4 ④ **本会话净进展**（成对读数；每条给命令与两个值）

**"会话开始"取值 ＝ 本会话 `t108` 的现取读数（`ts=2026-09-29T02:33:45–02:35:50`）**；**"现在" ＝ 本件现取（`ts=03:21–03:23`）**。

| # | 面 | 命令 | 会话开始 | 现在 |
|---|---|---|---|---|
| P1 | 名册条数 | `sed -n '/k_pts_entries\[\] = {/,/^};/p' src/WpfGfx.Linux.Native/src/win32_pts.c \| grep -c '"'` | **13** | **13**（**未动**） |
| P2 | 真 stub 字面数 | `grep -c 'return wpf_pts_gap("' …/win32_pts.c`（减去 1 行注释） | **5** | **3** |
| P3 | 导出面 | `nm -D --defined-only …/libwpfwin32.so \| awk '{print $3}' \| grep -c .` ／ `wc -l …/exports.txt` | **567 / 567** | **572 / 572** |
| P4 | 权威 `.so` | `sha256sum …/libwpfwin32.so \| cut -c1-16` | **`a2de5ff2b667f33f`** | **`a131ea4e6f5cc4f5`** |
| P5 | 工具三格 | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567`** | **`… impl=87 so16=a131ea4e6f5cc4f5 exports=572`**（`tool/dead/artifact/ops` 四位**未动**） |
| P6 | **台账面** | `grep -cE '^PTS_GAP entry=' <evidence>/app_g1.log` | **2**（`seq=5 CreateDocContext`／`seq=6 LoDisposePenaltyModule`） | **0** |
| P7 | 托管具名面 | `grep -c 'PTS-UNAVAILABLE' …` ／ `grep -o 'entry=[A-Za-z0-9_]*' … \| sort \| uniq -c` | **2 行**（两行都 `LoDisposePenaltyModule`） | **0 行** |
| P8 | `native_gap` | `grep -h '^NAMED ' <evidence>/leg_*.env` | **2 / 2** | **0 / 0** |
| P9 | 两页存活面 | 同上 `LEG` 行 | `k23 alive=yes app_rc=143`；`k24 alive=yes app_rc=143` | `k23 alive=yes app_rc=143`；`k24 alive=yes app_rc=143`（**不变**） |
| P10 | 两页占位面 | 同上 | `magenta=49923`（k23）／`54513`（k24），`colors=844`／`852` | **`magenta=0`／`0`**，`colors=383`／`383` |
| P11 | 两页像素位移 | 同上 `ae=` | `ae=141323`（k23）／`221857`（k24） | **`ae=0`（k23）／`15386`（k24）** |
| P12 | k24 **渲染面** | `python3 …/shotstat.py <evidence>/shots/g1/k24.png` ＋ `sha256sum` | 会话开始**未取**该件 sha（**如实**）；`t112` 那趟现取过：`colors=1 magenta=0 ink=0`（＝崩溃那趟的 `.env` 口径） | `colors=383 magenta=0 ink=480000`；**sha256 `ef3fd6765f18f51bc443ad0eb8e2185f75549936c120c0589cbfad264e9d3915`，且与 `k23.png`／`last.png` 逐字节相同** |
| P13 | 同趟性 | `grep -h '^DEV ' leg_*.env` | **NO**（`leg23 shim=a2de5ff2b667f33f` ≠ `leg24 shim=a131ea4e6f5cc4f5`） | **yes**（两腿均 `shim=a131ea4e6f5cc4f5 pf=2988f5154ecac5dd`） |
| P14 | 守卫判词 | `bash build/MilBridge/tools/pts-pages-guard.sh --legs <evidence>` | `rc=1`；`fails` 四条全点名 `leg24-*`（`not-alive`／`abort`／`placeholder-missing`／`named-line`） | `rc=1`；`fails` 五条：`leg24/leg23-placeholder-missing(magenta=0<20000)`、`leg24/leg23-named-line`、**`native-ledger-absent(PTS_GAP n=0)`** |

⇒ **净进展一句话**：**"PTS 族全部让位（台账/具名/占位三面同时归零）＋ 崩进程治好 ＋ 同趟性修好"是真进展**；**但"引擎换了另一族把两页挡住"（`Fs*`，1080 次）与"两页并未画出各自内容"是本轮必须接管的现实**。

⚠️ **一处必须登记的**证据面不一致**（本件现取，机制 `NOINFO`）**：`t112`（`ts=03:03:58`）现取仓库内 `shots/g1/k24.png` 的 `shotstat` 已经是 `colors=383 … ink=480000`、且 sha256 与 `03:14` 那趟**逐字节相同**；**而** `02:48` 那趟自己的 `session.txt`／`leg_24.env` 写的是 `colors=1 magenta=0 ink=0`。⇒ **仓库内截图当时并不是那次崩溃跑的原样产物**（成因：复制未发生／被确定性重渲染覆盖，**本件分不开**）⇒ **任何以截图为承重件的判据，必须像 `C7` 那样先自证"截图与日志同趟"**。

---

## §5 ⑤ `NOINFO` 预期（逐条给"消掉需要什么"）

1. **谁把 `UnderConstruction` 放到内容区**（首屏残留 vs 内容区失败落空态）：`NOINFO(reason=两条链都现取成立：`PracticalDemo.xaml:9` 内嵌 `UnderConstruction`，而 `FlowDocumentDemo` 又被 `[NS] loaded` 记为已加载；本件不跑腿，分不开)`. **消掉需要**：一趟"**首击 k=23**"的腿（`clicks=[23,…]`）＋ 一次 boot→k24 的**内容区截图切分**读数；或应用侧一行"当前内容控件类型"诊断。
2. **`Fs*` 里与"两页能排版"直接相关的最小簇有多大**：`NOINFO(reason=本件只取了 66 条的总数与前 20 名；"哪几条是必经"只能由运行期逐次试跑得到)`. **消掉需要**：补一跳后重跑一趟，读 `[HC-UNHANDLED]` 的**入口名分布变化**（这正是 §1.2 新口径的用途）。
3. **`[HC-UNHANDLED]` 的捕获语义**（是否被吞、有无条数上限、是否常开）：`NOINFO(reason=发射方在第三方应用 `~/hc-linux/…/App.xaml.cs`，不在我方写域；本件只现取到 1081 行的存在与分布)`. **消掉需要**：读该件的捕获分支并给出"是否只记不吞/有条数上限"的原文；或我方加一条**自己的**计数器。
4. **`FONT_FALLBACK` 行的 `resolved=none` 语义**（`requested=DEJAVU fallback=no resolved=none`：为什么"没回退也没解析"仍不崩）：`NOINFO(reason=本件只现取到行与其三字段；未逐条追该分支)`. **消掉需要**：`FamilyCollection.Linux.cs` 那三处 `EmitFontFallbackDiag` 调用点的**分支原文**逐条对照（现取该件 sha16 `19a42240f59af073`，行号仅本次有效）。
5. **两页截图逐字节相同的成因**（"两页同貌" vs "第 23 页没重绘"）：`NOINFO(reason=与第 1 条同因：需要换点击次序的对照腿)`. **消掉需要**：同上。
6. **`colors` 带 `[800,1200]` 当初的依据是否还有效**：`NOINFO(reason=本件未取该带的出处与历史样本)`. **消掉需要**：找到该带的引入记录与其样本帧；否则重定带时必须**同时给新样本**（占位期与实现期各 ≥2 帧）。
7. **`Fs*` 出参结构（`FSFMTRBL`／`FSFMTR`）的**字节布局**权威**：`NOINFO(reason=本仓只有托管侧声明；与 `t110` 的 `FSCONTEXTINFO` 同族，本件未取得 native 侧规格)`. **消掉需要**：一条"逐字段读回"的成对读数（照 `t110` 的 `field_readback_ok` 形制），或一份具名布局声明。
8. **门禁里 `MAGENTA_FLOOR` 的实际注入值**：`NOINFO(reason=本件只现取到缺省 `20000`（`pts-pages-guard.sh:75`）；未跑整趟门禁)`. **消掉需要**：跑腿者给出同趟该变量现值。

---

## §6 ⑨ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-w8-retarget-recon.md`（新建；UTF-8；模式 **644**；**首记号不是 `# ⏪ `**；末行自带可复算自报口径）。
- **只读**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`nm`／`sha256sum`／`wc`／`stat`／`od`／`sort`／`uniq`／`git log`／`git status` ＋ 三个**纯读**件（`pts-gap-count-check.sh`／`check-shim-coverage.py`／`pts-pages-guard.sh --legs`／`shotstat.py`（只读 PNG））＋ `read_image`（只读截图）。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
  ⚠️ **仓外只读**：为定位"画面是哪个页面"曾对**第三方安装**做窄范围**只读** `grep`／`sed`（`~/hc-linux/src/Shared/HandyControlDemo_Shared/**`），**未写入、未运行**；相关读数在 §1.4 逐条标注为"仓外现取"。
- **未改任何其它件**：`git status --porcelain` 原样 ——
```
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_23.env
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_24.env
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log
?? src/tests/
```
  ⇒ **五项全属他人**（`arm_A` 组、`src/tests/`）；**本件是本次唯一新增件**。
- **未引既有报告当证据**：`t107` 的载体只作**对照**且其状态**已由本件现取重判**（§4 的 P1–P14 两列都是我自己取的）；其余报告一条读数未抄。§1.4 的画面判定是**我自己**从截图字节 ＋ 三件 XAML 原文推出来的。
- **末行自报口径当场可复算**：见末行。

---

### 结语（自包含）

- **① 下一跳（口径已换，理由与代价已写死）**：`^PTS_GAP entry=` **已空**（0 行）⇒ 旧口径对 **ENFE** 结构性失明（名册 13 名**不含任何 `Fs*`**；`Fs*` **未导出** ⇒ 异常在 CLR 抛、进不了 native）。**换用托管具名异常面** `[HC-UNHANDLED] … Unable to find an entry point named '<名>'`（现取 1081 行、全 `EntryPointNotFoundException`）⇒ **下一跳 ＝ `FsCreatePageBottomless`（1080 次）**，随后 `FsCreatePageFinite`（1 次）；上游声明 `Pts.cs:3128-3132`，调用点 `PtsPage.cs:295`，文档页走 `FormatBottomless`（`FlowDocumentFormatter.cs:99`）。
- **② 第二发现（同等重要）**：**两页现状不是"真排版"** —— `k23/k24/last` 三张截图**逐字节相同**，画面是 demo 的 **敬请期待**空态（`UnderConstruction.xaml:16` ＋ `PracticalDemo.xaml:9` 内嵌），`neptune` 在日志里命中 **0**，`ae` 仅 0／15386。
- **③ `TASK-0302` 剩余面**：`Fs*` **66 条**（清单来源、前 20 名、verify 单行、触 `fp_inputs()`、依赖、结构代价）；两条诊断（`colors-out-of-band=383` ＝ 洋红期遗留带 `[800,1200]`；`leg23-AE=0` ＝ 点击前后无像素差，**歧义未消、须换次序判别**）；**「两页真排版」还缺 N1–N4 四条可判证据**（`ink` 无区分力／ENFE 被吞无判据／两页帧相同／内容身份无判据）。
- **④ 相位翻转包**：要改的位 F1–F7、**10 条 degraded 正控逐条原文与相位相关性**（c1–c10）＋ realized 侧 c15–c19、翻转后**会变语义**的六类读数；**硬前置**：**今天就翻 ⇒ 守卫会 PASS（现取四要件全满足）而两页并未排版** ⇒ **翻转必须与 N1–N4 同趟**，否则就是判据放松。
- **⑤ 本会话净进展**：P1–P14 成对读数（名册 13→13／stub 5→3／导出 567→572／`so16` `a2de5ff2b667f33f`→`a131ea4e6f5cc4f5`／三格 `impl 89→87`／台账 2→0／具名 2→0／`native_gap` 2→0／`magenta` 49923·54513→**0·0**／`ae` 141323·221857→**0·15386**／同趟性 **NO→yes**），并登记**一处证据面不一致**（截图与日志不同趟）。
- **⑥ `NOINFO` 8 条**，各带"消掉需要什么证据"。

### §6-bis 落盘期间的环境位移（**只增不改，如实追加**；`ts=2026-09-29T03:25:43.256417633+0800`）

- **`HEAD` 未动**：仍是 **`fdd8917`**（本件起点与落盘时同值）⇒ §0／§4 的读数都在同一提交上取的。
- **工作树变了（全是他人）**：起点 5 项 → 落盘时 **11 项**（新增 `M build/MilBridge/HANDOFF-NEXT.md`／`M build/MilBridge/P1-fontstack-fallback-criteria.md`／`M …-report.md`／`M …-verify.md`／`M build/MilBridge/tests/PtsPagesProbe/legs-to-env.py`／`M …/session_inner.sh`／`M docs/ROUTES.md`）⇒ **另有车道正在落地**；本件仍是**唯一由我新增**的件。
- 🔴 **一件必须点名的**读数归属**问题**：本件引用的**装置件**在我取读数的窗口内被他人改过 ——
```
277241f33bb94a58  2026-09-29 03:23:10.313837456 +0800  build/MilBridge/tests/PtsPagesProbe/legs-to-env.py
a54d63bac8c17084  2026-09-29 03:22:36.300268478 +0800  build/MilBridge/tests/PtsPagesProbe/session_inner.sh
e9688aaa11a1b9f4  2026-09-29 02:39:47.488148528 +0800  build/MilBridge/tools/pts-pages-guard.sh
cc1ca161504ef1dc  2026-09-28 07:35:39.530720595 +0800  build/MilBridge/tests/PtsPagesProbe/shotstat.py
1ad94ad71f59e6fb  2026-09-29 03:14:39.174582733 +0800  build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log
```
  ⇒ 我引用的**产物**是 `03:14` 那趟落的（早于上述两件的改动时刻 `03:22:36`／`03:23:10`）⇒ **产物属于"改前"那版仪器**；而**读数本身是文件内容**（`sha16` 已逐个给出），**不受后续仪器改动影响**。
  ⇒ **但复跑者必须重取仪器 `sha16`**：`legs-to-env.py`／`session_inner.sh` 换代 ⇒ 复跑产物与 `03:14` 那趟**不保证同口径**（这正是本仓"证据必须同趟"那条纪律的同一件事，`C7` 已经把它写成牙）。
`P1-W8-RETARGET-RECON 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ dafbb01d36308c68（口径＝末行之前的全文；末行＝本行）`

# `P1` hc demo 两缺陷侦察（流文档文字重叠／第三个 tab 崩溃）—— 只读侦察 ＋ 选靶（`T-B1`）

- **读时**：`2026-10-02T10:00+0800 … 10:20+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=faf0c7314a3bbfdb4b0c403fb8c742a16b5ace40`（现取）。
- **件指纹（现取，`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c 31964874821daae4`（`842641 B`）｜`src/WpfGfx.Linux.Native/bin/libwpfwin32.so df27801beb222f05`（`553936 B`，`mtime 2026-10-02 00:19:57`）｜`build/PresentationFramework.Linux/PtsHelper.Linux.cs`（生成件）｜`build/PresentationFramework.Linux/TextParaClient.Linux.cs 1a70c5168393b0ea`（生成件，`212968 B`）｜`build/PresentationFramework.Linux/reapply-patches.py bdc71ac713a9a925`｜`upstream/…/PtsHost/PtsContext.cs c91e3f94d1188ece`｜`upstream/…/PtsHost/PtsHelper.cs f2ed9552e983fed1`。
- **装置件指纹（现取）**：demo 自身 `HandyControlDemo.dll 1ac5e587cda3fb20`（构建 `09-21 00:17`；**比 `App.xaml.cs` 源旧 2 分钟** —— `run-hc.sh --check-only` 现取自报）。
- **边界（照 `T-B1` ②）**：**只读**（唯一可写件＝本文件）；未跑 `verify-all`；未跑 `static-jaws-check.sh`；**未构建**；进程只按 PID（主用 `pgrep -f 'Handy[C]ontrolDemo.dll'` 取号）；显示位只用空闲 `:233`／`:234`，**未占用 `:10`**（一趟误开见 §1.5-⑥，已即时收）；大件只用 `wc/head/tail/grep -c`。
- **行号纪律**：下文所有行号**仅本次有效**，一律附**内容锚原文**供下一位现取复核。

---

## §0 前提核对（三条在册声明**已过期**，先报，免得照陈旧前提动手）

| 声明（出处） | 现取 | 结论 |
|---|---|---|
| `~/run-hc.sh` 使用须知「⛔ 暂时别点：左侧「富文本」「流文档」…本移植尚未实现（在册 `D-G70`）…`EntryPointNotFoundException: CreateInstalledObjectsInfo` ⇒ 未处理异常 ⇒ abort(134)」 | 现取三条本机日志（§1.3）**逐字**：异常类型是 `MS.Internal.PtsHost.UnsafeNativeMethods.PTS+PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'`，**不是** `EntryPointNotFoundException`；`PTS-UNAVAILABLE`／`EntryPointNotFoundException` 命中数**全 0** | **前提已失效**：`EntryPointNotFound` 那条已被 `#50` 止损；现在的失败面变了。该「使用须知」段落须同趟更正 |
| 同上「有没有守护都一样死（`rc=134`）…守护只接住第一个异常，WPF 随后 `Environment.FailFast`」 | 现取：**守护能接住的腿，进程不死**（本席 9 趟：`HC-UNHANDLED #1..#3` 皆被接住、`alive=yes`、`rc≠134`，见 §1.5）；**只有**在册三件里那种**不可捕获**的 `FailFast` 才死 | 半对半错：**守护并非"救不了"** —— 它救得了 `PtsException`（切页不再杀进程）；它救不了 `Invariant.FailFast`。原文那一句把两件事混成一件 |
| 在册 `KNOWN-DEFECTS.md:2260`「本页上驱动零效果…页盒 `39.81x39.17` DIP；`visbounds=empty`」 | 现取本机渲染：`流文档` 页**滚动视图**（tab1）**已渲染出正文＋图＋表**，四具名色齐（`GhostWhite=14331｜Beige=1161｜DarkGreen=51｜LightGoldenrodYellow=5932`，见 §2.2） | **前提已失效**：与 `T-A41` 那趟"`k24` 四色仅 1 命中"的代不同（`so` 已换代 `df27801beb222f05`） |

---

## §1 复现

### 1.1 装置（本席私有，未占 `:10`）

- `:233` = `Xvfb :233 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（WM 支）。
- `:234` = `Xvfb :234 -screen 0 1440x900x24`（**无 WM** 支；窗口落在 `(240,212)`）。
- 应用：`cd /home/links-dev/hc-linux/…/net10.0 && dotnet HandyControlDemo.dll`；**缺省档**（`run-hc.sh`，不设任何 `WPF_LINUX_*`／`HC_*`），窗口 **`800x600`**（`xdotool getwindowgeometry` 现取）。
- **同步面**（现取）：`bash ~/run-hc.sh --check-only` ⇒ `SYNC-APPLOCAL=PASS target=…/net10.0 items=5 ok=5 drift=0 rc=0`；五件：`libwpfwin32.so df27801beb222f05｜wpfgfx_cor3.so 941e69902d82ef02｜PresentationCore.dll ba162811e97e4484｜PresentationFramework.dll 93f0368dac89f9c2｜WindowsBase.dll 7f1c38f90e916718`。

### 1.2 复现步骤（点到哪里／哪一页）

1. `DISPLAY=:233 bash ~/run-hc.sh`（等窗口约 6–8 s）。
2. 左侧列表**滚到底**（指针 `(127,360)`，滚轮下 40 格）⇒ 点 **`FlowDocument`**（第 `24` 项；滚到底后其行盒 `scr=28,410 203x27`，点 `(127,355)`）。
   - 判"确已进页"：日志里 `[FORMATLINE-LINE]` 从 `0` 变为 `122`。
3. **缺陷①**：看 **tab1「流文档滚动视图」**（默认选中，页签 `scr=268,82 165x27`）。
4. **缺陷②**：点 **tab2「流文档单页视图」**（`scr=440,82`，点 `(522,95)`）→ 点 **tab3「流文档查看器」**（`scr=611,82`，点 `(693,95)`）。
   - 页签坐标取自**仪器档**（`HC_INPUT_DIAG=1 HC_GEO_EVERY=1`）的 `[GEO] TabItem#- … hdr=流文档滚动视图/单页视图/查看器` 现取；缺省档窗口同在 `(0,0)`、坐标逐字相同。

### 1.3 日志路径与现场三件（**在册现场**，非本席产出）

| 件（`/tmp/`） | `sha256` 前 16 | 字节 | 行 | 结果 |
|---|---|---|---|---|
| `hc-run-092614.log` | `90c51588989b8efd` | `57577854` | `296062` | **`FailFast` 死**（`rc=134`）：3×`PtsException`＋`FailFast` |
| `hc-run-094401.log` | `ed5e969e40e8c12f` | `18841372` | `97738` | **`FailFast` 死**：`HC-UNHANDLED=0`、`PtsException=0` |
| `hc-run-094259.log` | `36e0bde7e44ec085` | `106849877` | `545283` | `HC-UNHANDLED #1` 后 **`Unhandled exception`／`Dispatcher.ShutdownImpl`** |

> 三件的 `[G147_WORKAREA] … mon=0,0,1728,1080` ⇒ 是**用户 `:10` 上的 `run-hc.sh`** 现场（本席私有位是 `1280x1024`／`1440x900`）。

### 1.4 崩溃原文（**逐字**，不许转述）

**(甲) 缺陷②的崩溃（`092614` 末 3 行 ＋ 栈）** —— 直前一行是 `[FSPARALIST-FILL]`：

```
[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=1 n=1 h0=0x5 src=managed-176 run=site=probe-in win=in gen=1 quad=4 hold=0 off16=16 bytes0_32=00 00 00 00 00 00 00 00 94 69 82 b0 a0 5d 00 00 05 00 00 00 00 00 00 00 03 00 00 00 00 00 00 00  ok=1645 gap=0 cur_tid=127825028126528 win_tid=127825028126528
Unrecoverable system error.: Handle has been already released.
Process terminated.
   at System.Environment.FailFast(System.Runtime.CompilerServices.StackCrawlMarkHandle, System.String, System.Runtime.CompilerServices.ObjectHandleOnStack, System.String)
   at System.Environment.FailFast(System.Threading.StackCrawlMark ByRef, System.String, System.Exception, System.String)
   at System.Environment.FailFast(System.String)
   at MS.Internal.Invariant.FailFast(System.String, System.String)
   at MS.Internal.PtsHost.PtsHelper.ArrangeParaList(MS.Internal.PtsHost.PtsContext, FSRECT, FSPARADESCRIPTION[], UInt32)
   at MS.Internal.PtsHost.PtsPage.ArrangePage()
   at MS.Internal.Documents.FlowDocumentPaginator.FormatPage(Int32)
   at MS.Internal.Documents.FlowDocumentPaginator.OnBackgroundPagination(System.Object)
   at System.Windows.Threading.ExceptionWrapper.InternalRealCall(System.Delegate, System.Object, Int32)
   at System.Windows.Threading.ExceptionWrapper.TryCatchWhen(System.Delegate, System.Object, Int32, System.Delegate)
   at System.Windows.Threading.DispatcherOperation.InvokeImpl()
   at MS.Internal.CulturePreservingExecutionContext.CallbackWrapper(System.Object)
   at System.Threading.ExecutionContext.RunInternal(System.Threading.ExecutionContext, System.Threading.ContextCallback, System.Object)
   at System.Windows.Threading.DispatcherOperation.Invoke()
   at System.Windows.Threading.Dispatcher.ProcessQueue()
   at System.Windows.Threading.Dispatcher.WndProcHook(IntPtr, Int32, IntPtr, IntPtr, Boolean ByRef)
```

> `bytes0_32` 逐字解：`FSPARADESCRIPTION` 前 32 B ⇒ `pfspara(+8)=0x5da0b0826994`、**`pfsparaclient(+16)=0x5`**、`nmp(+24)=0x3`。`h0=0x5` 与 `+16` 槽**同值**（＝同一次 `FsQueryTrackParaList` 交出的那个句柄）。
> **`rc`**：`Environment.FailFast` ⇒ 进程 `SIGABRT`；`run-hc.sh` 打印 `rc=134`（本机无 core）。

**(乙) 缺陷②的**先导**异常（`092614:2500`／本席 `100723:126866` 同形）**：

```
[FS_PAGE_GAP] rc=-10000 reason=unknown-breakrec entry=FsDestroyPageBreakRecord ctx=0x5d174831a2d0 p=0x5d1748265c68 ok=0 gap=1 out=NO-OUTPUT
[HC-UNHANDLED] #1 PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'. ｜ 首帧 at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.Error(Int32 fserr, PtsContext ptsContext)
```

**(丙) 第三件（`094259:545261`）**：`Unhandled exception. MS.Internal.PtsHost.UnsafeNativeMethods.PTS+PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'.`（末栈落在 `Dispatcher.ShutdownImpl`）。

### 1.5 本席现取复现读数（**9 趟**，诚实划界）

| # | 装置 | 日志 | 载入 `FORMATLINE` | `PtsException`(=`HC-UNHANDLED`) | `FailFast`／`Unrecoverable` | 存活 |
|---|---|---|---|---|---|---|
| 1 | `:233` 仪器档 | `/tmp/tb1/app-diag.log` | 122 | 2 | 0 | yes |
| 2 | `:233` 缺省 tab1→tab2→tab3 | `hc-run-100723.log`(`badedbba9eb1d4ec`) | 122 | 1 | 0 | yes |
| 3 | `:233` 缺省 tab3 直点 | `hc-run-100837.log` | 183 | 0 | 0 | yes |
| 4 | `:233` 缺省 5 轮循环＋文档内滚动＋改窗 | `hc-run-101213.log`(`86e25579b33b05a2`) | 122 | 3 | 0 | yes |
| 5–7 | `:233` 缺省 三趟独立复跑 | `101429`/`101453`/`101517` | 122 | 2/1/1 | 0 | yes |
| 8–9 | `:234` 无 WM 支 | `101705`/`101737` | 0/122 | 0/1 | 0 | yes |

⇒ **结论（`NOINFO`）**：**缺陷②的 `FailFast` 本席 9 趟未现取到**；现取到的稳定面是 **tab2 触发 `PtsException`（被守护接住）＋ 该页视觉空白**，**tab3 空白但不死**。
- 归因（如实）：`FailFast` 的抛点在 **`DispatcherOperation`（后台分页 `OnBackgroundPagination`）** 上，日志里 `[FSPARALIST-FILL]`／`[WINDOW-SPLIT] …OUT-WINDOW-REFUSED` 的**同一 `track`/`client` 成对行**成千上万次重复（`092614` `ok=24672`、`094401` 达 `24716`）⇒ 是**跑次敏感的竞态**（本仓在册同族："跑次敏感计数"）。
- **不成画面**：本席 9 趟皆**同一 `so`（`df27801beb222f05`）**；现场三件时间的 `so` 无法反查（`run-hc.sh` 的 sha 行只落终端 stdout，未落 `hc-run-*.log`）⇒ 现场是否同件 **`NOINFO`**。
- ⑥ **装置自伤（如实登记）**：首版驱动脚本未 `export DISPLAY`，`run-hc.sh` 继承了会话的 `:10` ⇒ **在 `:10` 上误开了一趟窗口**（日志 `101015`，`[G147_WORKAREA] mon=1728x1080`）；**当场按 PID 收净**，此后一律显式 `export DISPLAY=:23x`。

---

## §2 缺陷① 「流文档」视图文字重叠

### 2.1 第一处断点（件:行 ＋ 原文）

**根因位（native，缺省路径）**：`src/WpfGfx.Linux.Native/src/win32_pts.c:126-130`

```
126:#ifndef WPF_PTS_FSP_PL_DVR
127:/* ⏪ `t198`（P1-W107 重修）：(甲) **描述符字段求真值** —— `FSPARADESCRIPTION.dvr_used(+36)`／
...
130:#define WPF_PTS_FSP_PL_DVR 0
```

⇒ 缺省 **0** ⇒ 下方全填块 **不进主链产物**；`FsQueryTrackParaList` 里那句

```
9142:                        memset((void *)&rg[i], 0, sizeof(rg[i]));
...
9147:#if WPF_PTS_FSP_PL_DVR            ← 缺省 0 ⇒ 本块**被编掉**
```

⇒ 描述符 `dvr_used(+36)`／`dvr_top_space(+60)` **恒 0**。

**第二跳（托管，消费该 0）**：`build/PresentationFramework.Linux/PtsHelper.Linux.cs:186,204-208`（＝生成件；上游对位 `PtsHelper.cs:158,176,180`）

```
186:                BaseParaClient paraClient = ptsContext.HandleToObject(arrayParaDesc[index].pfsparaclient) as BaseParaClient;
...
204:                rcPara.v += dvrPara + dvrTopSpace;
205:                rcPara.dv = arrayParaDesc[index].dvrUsed - dvrTopSpace;
...
208:                dvrPara += arrayParaDesc[index].dvrUsed;
```

⇒ `dvrPara` 恒 **0** ⇒ **同一 track 内每个段落都拿到同一个 `rcPara.v`** ⇒ 段落互相压在同一 v 上。

**第三跳（行视觉落位）**：`build/PresentationFramework.Linux/TextParaClient.Linux.cs:3332`（生成件；生成器 `reapply-patches.py:1895 TPC_EDITS`）

```
3332:                    lineVisual.Offset = new Vector(TextDpi.FromTextDpi(lineDesc.urStart), TextDpi.FromTextDpi(lineDesc.vrStart));
```

其 `vrStart` 来自 `win32_pts.c:7654-7659`（**本侧自累加**，非上游 ABI 几何）：

```
7654:static int wpf_pts_fl_vr_start(const wpf_pts_subtrack *o, int idx)
7655:{
7656:    int vr = 0;
7657:    for (int k = 0; k < idx && k < o->fl_nlines; k++)
7658:        vr += o->fl_line[k].dvr_ascent + o->fl_line[k].dvr_descent;
7659:    return vr;
```

⇒ **段内**行不重叠（自累加正确）；**段落之间**因 `dvrUsed=0` 而共 v ⇒ 重叠。

### 2.2 几何证据（现取，能取多少取多少）

**(a) 行盒（native 真返回值，`hc-run-100723.log`）** —— 主文本段 `para=0x8`，8 行**个个同尺**：

```
[FORMATLINE-LINE] where=FsCreatePageFinite para=0x8 i=0 dcp=0 rc=0 pfsline=0xc dcpLine=88 fsflres=0 fforced=0 ascent=3342 descent=849 urbbox=0 durbbox=170000 dep=0 rfmt=0
[FORMATLINE-LINE] where=FsCreatePageFinite para=0x8 i=7 dcp=681 rc=0 pfsline=0x13 dcpLine=275 fsflres=2 fforced=0 ascent=3342 descent=849 urbbox=0 durbbox=31359 dep=0 rfmt=0
```

⇒ 行盒 = `3342+849 = 4191` `TextDpi` = **13.97 DIP**（`TextDpi` 300 单位/DIP）；`urbbox=0` ⇒ `urStart=0`（`win32_pts.c:7687` 的约定：`urStartLine=0 ⇒ =urBBox`）。

**(b) 段落盒 v 高 = 0（`[TPCL]` 台账，缺省开；`WPF_TPCL_PROBE=0` 才关）**：

```
[TPCL] site=RenderSimpleLines.Geom parah=0x5d174cf363c4 cLines=8 ... urStart=0 vrStart=0 dur=180000 asc=3342 desc=849 rectU=0 rectV=0 rectDU=768 rectDV=0 NOINFO=tpcl-entry-readonly
```

⇒ 8 行的主段：`rectDU=768, rectDV=0`（**段盒 v 高 0**，`TextDpi`）；对照单行段（图/表的内容段）：`rectDU=37810…88800, rectDV=4191`（恰一行盒）。

**(c) 重叠量（渲染帧现取；窗 `(0,0) 800x600`，取 `/tmp/tb1/d-tab1.png`）**：

| 对象 | 像素盒（root 帧） | 面积 | 盒内暗像素（＝文字） | 与文本行带的 y 关系 |
|---|---|---|---|---|
| 文本段 8 行行带 | `y=147..258`，`x≥304` | — | 行带 6 段：`147-157｜161-174｜176-203｜205-216｜218-244｜250-258` | 基准 |
| `Figure`（`Beige` 底） | `x=422..747`，`y=161..180` | `6520` | `361`（5.5%） | **与行带 `161-174` 同 y** |
| `Floater` 表（`LightGoldenrodYellow` 行） | `x=526..747`，`y=181..234` | `11988` | `1007`（8.4%） | **与行带 `176-203／205-216／218-244` 同 y** |

⇒ **重叠量**：`Figure` 与文本行 `161-174` **整段共 y**；`Floater` 表与 `176-244` 的 4 段行带共 y。即**图／表段落**与**正文段落**落在同一 v。四具名色现取：`GhostWhite=14331｜Beige=1161｜DarkGreen=51｜LightGoldenrodYellow=5932`。
⇒ 另：`x=799` 整列恒有 1 暗像素 ＝ 窗口右缘裁切；`dur=180000`（=600 DIP，起点 `x≈288`）⇒ 文档右缘 `≈888 > 800` ⇒ **右侧被窗口裁掉**（次生现象，非本缺陷主因）。

**(d) 覆盖面注记**：`[FS_TLB] entry=FsQueryTextDetails parah=0x5d174cf363c4 cLines=8 … attached-objects=present queried=8 gap=0 figure=1 floater=1 NOINFO=fsgeometry-layout(vrStart=self-accum)` ⇒ 该段**附着 1 图 ＋ 1 表**（正是上表两个共带对象）。

### 2.3 归因

**native／shim 侧**（`src/WpfGfx.Linux.Native/src/win32_pts.c`）：缺省路径**不填** `FSPARADESCRIPTION` 的 v 几何（`dvr_used`／`dvr_top_space` 恒 0），使上游 `PtsHelper` 的段落 v 堆叠（`dvrPara += dvrUsed`）**退化为 0 推进**。
- **不是装置侧**：同一 `so` 下，行内几何（`ascent/descent`）与非 0 段盒（单行段 `rectDV=4191`）都在 ⇒ 渲染链通。
- **不是托管侧作者性缺陷**：`PtsHelper/TextParaClient` 是**上游逐字＋生成器补丁**，其消费逻辑与上游同形（`PtsHelper.cs:176,180` 一字未改）。
- **不是 demo 侧**：`FlowDocumentDemo.xaml` 只是声明 `ColumnWidth/Figure/Floater`；`hc` 仓外工程**不在写域**。
- 交叉证：native 自己在**出参行**里具名 `NOINFO=fsgeometry-layout(vrStart=self-accum,urStart=urBBox,dur=self-page-width)`（`win32_pts.c:8038`）⇒ 它**自认**无真几何。

### 2.4 判据草案（缺陷①；≥2 条可证伪 ＋ 反极性）

| # | 判据（可证伪） | 反极性腿（该红/该绿必现） |
|---|---|---|
| **D1-1** | 缺省档日志必含 `[TPCL] site=RenderSimpleLines.Geom … cLines≥2` 的行且 **`rectDV=0`**；同段 `[FS_TLB]` 必带 `NOINFO=fsgeometry-layout(vrStart=self-accum)` | 副本以 `-DWPF_PTS_FSP_PL_DVR=1` 重建：同段 `rectDV` **必须 ≠ 0**（＝`4191·nlines` 量级）；若仍 `0` ⇒ D1-1 的因果被证伪 |
| **D1-2** | 渲染帧里 `Figure`(Beige) 盒与**文本行带**共 y（交集 > 0），且 `Floater`(LGY) 盒同理；**给定**"共带像素 > 0" | 同上反极腿：图/表盒的 y 区间**必须移出**所有文本行带（交集 = 0）；若不动 ⇒ 归因不成立 |
| **D1-3** | 同 track 的 `rcPara.v` 逐段**互异**（可由 `[TPCL] … rectV` 或 `GEO` 现取） | 缺省档现取 `rectV` 逐段**同值**（＝0）⇒ 该格必"红"；反极腿下必须逐段递增 |
| **D1-收** | 任一条取不到 ⇒ **`NOINFO`**，不许拿"看起来像重叠"顶绿（本仓"帧存在性 ≠ 内容正确"） | — |

---

## §3 缺陷② 「第三个 tab（流文档查看器）」崩溃

### 3.1 第一处断点（件:行 ＋ 原文）

**抛点（不可捕获）**：`upstream/…/MS/Internal/PtsHost/PtsContext.cs:243-249`

```
243:        internal object HandleToObject(IntPtr handle)
...
248:            Invariant.Assert(_unmanagedHandles[handleLong].IsHandle(), "Handle has been already released.");
```

（同件 `:206-211` 的 `ReleaseHandle` 是**同文本**的第二处；§1.4 栈里 `FailFast` 的**直接下层帧**是 `ArrangeParaList` ⇒ 命中的是 **`:248`** 这一句。）

**调用点（托管）**：`build/PresentationFramework.Linux/PtsHelper.Linux.cs:186`（生成件；上游对位 `PtsHelper.cs:158`）

```
186:                BaseParaClient paraClient = ptsContext.HandleToObject(arrayParaDesc[index].pfsparaclient) as BaseParaClient;
```

**句柄来源（native，真断点）**：`src/WpfGfx.Linux.Native/src/win32_pts.c:9145`

```
9145:                        rg[i].pfsparaclient = (void *)dp->fsp_pl_cur;
```

⇒ `FsQueryTrackParaList` 把 `dp->fsp_pl_cur`（**跨窗缓存**的一个 `managed-176` 造出的 ParaClient 句柄）直接当 `pfsparaclient` 交出去（同一 `h` 也打进 `[FSPARALIST-FILL] ... h0=%p`，`win32_pts.c:9213`）。**该句柄在托管侧已被 `PtsContext.ReleaseHandle` 回收**时，`ArrangeParaList` 的 `HandleToObject` 就撞 `:248` ⇒ `Invariant.FailFast` ⇒ `Environment.FailFast`（**不可捕获**）⇒ `rc=134`。

**为何不是 `:211`／`:247`**：栈里 `PtsContext.HandleToObject` 的那句是 `:248`；`:247`（`Invalid object handle.`）是**另一类**（本仓在册 T1 类），`:211`（`ReleaseHandle`）栈形不同。本件按 `:248` 定靶。

### 3.2 崩溃原文

见 §1.4(甲)(乙)(丙)（逐字，含 `[FSPARALIST-FILL] … h0=0x5 … bytes0_32=…05 00 00 00…` ＋ `Unrecoverable system error.: Handle has been already released.` ＋ `Process terminated.` ＋ 全栈）。`rc=134`。

### 3.3 归因

**native／shim 侧**（`win32_pts.c:9145` 交句柄的**代**问题）：`FsQueryTrackParaList` 交出的是**跨窗缓存**句柄（`dp->fsp_pl_cur`），而托管 `PtsContext` 的那张 `_unmanagedHandles` 表**已把该槽回收**。
- **不是托管侧的 bug**：`ArrangeParaList` 与上游**逐字同形**（只是照 `pfsparaclient` 反查）。
- **不是 demo 侧**：`App.xaml.cs:68-79` 的守护 `DispatcherUnhandledException` 只接**可捕获**异常（它确实接住了先导 `PtsException` ⇒ `[HC-UNHANDLED] #1`），对 `FailFast` **无能为力** ⇒ "有没有守护都一样死"这一半是对的，但**只对 `FailFast` 成立**。
- **旁证（native 自记）**：`[WINDOW-SPLIT] where=FsQueryTrackParaList window=out … v=OUT-WINDOW-REFUSED(handles-released/page-destroyed)` ⇒ shim 自己把"句柄已释放"写进了窗口分裂台账，但**同一入口的填充支仍按 `ok` 交句柄**。

### 3.4 判据草案（缺陷②；≥2 条可证伪 ＋ 反极性）

| # | 判据（可证伪） | 反极性腿 |
|---|---|---|
| **D2-1** | 崩溃日志里 `Unrecoverable system error.: Handle has been already released.` 的**紧邻上一行**必是 `[FSPARALIST-FILL] … h0=0x<k> …`，且 `bytes0_32` 的 `+16` 槽＝同一个 `<k>`（本席在 `092614:296029` 逐字核过） | 若把 `FsQueryTrackParaList` 的填充支**拒发**（照 `win32_pts.c:9122 reason=no-legal-pfspara-in-this-run` 体例加 `no-legal-pfsparaclient`）⇒ 该行必须变成 `cParaDesc=0`／具名拒，且**不再 FailFast**；若仍死 ⇒ D2-1 证伪 |
| **D2-2** | `[FSPARALIST-FILL]` 的 `h0` **逐次可得且互异**（"每次新建"）；连续两次填充**不得**给同一 `h0` | 现取：`092614` 里同一 `h0=0x5`／同一 `track,client` 成对行**成千上万次重复**（`ok=24672`）⇒ 该格现取**必红**；反极腿（每次 `+176` 新造）下必须逐次各异 |
| **D2-3** | 正极性"点 tab3 ⇒ `rc=134`"（现场三件）；反极性"点 tab3 ⇒ `alive=yes` 且 `rc≠134`" | ⚠️ **本席 9 趟只取到反极性**（§1.5）⇒ 该腿**现取不成立**，如实记 `NOINFO`（不许拿"不死"冒充"已修"） |
| **D2-收** | 若"拒发 ⇒ 无崩溃"与"发陈旧句柄 ⇒ `FailFast`"**不能在同一 `so` 上成对取到** ⇒ 判 `NOINFO`，唯一合法终点＝**诚实拒绝**（宁可 `cParas=0`／整页空白，也不许交陈旧句柄） | — |

---

## §4 候选路（逐条 可及性 ∧ 可行性 ∧ 代价 ∧ `P8` 落点）＋ 选靶

| 路 | 落点（件:行） | 可及性 | 可行性 | 代价 | `P8` 落点 | 评 |
|---|---|---|---|---|---|---|
| **甲 · native** | ① 缺陷①：`src/WpfGfx.Linux.Native/src/win32_pts.c:126-130`（`WPF_PTS_FSP_PL_DVR` 缺省）＋ `:9147-9166`（描述符填充块）；② 缺陷②：同件 `:9145`（交句柄处）＋ `:9122`（既有"拒发"先例） | 高：源件在手；两处**同一函数体内**（`FsQueryTrackParaList`）；段账 `g_pts_lm1_led[]` 已在册；"拒发"先例已在 | 中：需证"段账条数 ≥ `cParas`"，`led_n<cParas` ⇒ 保持 0 并**具名降级**（`win32_pts.c:9164` 已有 `NOINFO(lm1-ledger-short)` 形态）；句柄代需按"**本窗新造 ∧ 在册 live**"挑，旧 handle 一律拒填 | 一次 `.so` 重建（`build-shim.sh --symbols`）＋ `tools/pts-gap-decl.txt` 的 `so16` 重锚＋`exports` 逐名对拍（现取 `exports=846`）；`win32_pts.c` 是**源件** ⇒ 直改合法 | 源件直改 | **选** |
| **乙 · 托管（含生成器）** | `build/PresentationFramework.Linux/TextParaClient.Linux.cs:3332`（行视觉落位）／`:3398-3402`（`IntersectsWithRectOnV` 只算 v 维）／`PtsHelper.Linux.cs:204-208` | 高（件在手、有生成器） | 低：**会把 native 的 0 几何在托管侧"贴膏药"**（自算段高），与 `T-A42` "几何须可辩护、可复算"相悖；且**不改根因** | 改**生成件** ⇒ 必须同趟改 `reapply-patches.py`（`TPC_EDITS:1895` / `PtsHelper` 条目 `:2827`）＋重产（`temp+rename`）；回归面大（`TextParaClient` 是 `[TPCL]`／`W` 族的投影面） | `reapply-patches.py` | 不选（治标且违"几何须可辩护"） |
| **丙 · demo 侧止损** | `~/hc-linux/…/App.xaml.cs:68-79`（守护）／`FlowDocumentDemo.xaml:9,21,26,104-110` | ⚠️ **仓外工程** | 低：守护救不了 `FailFast`（`094401`：`HC-UNHANDLED=0` 也死）；关掉 `Figure/Floater` 是**改需求** | 违 `T-B1` 边界（"不许改 hc demo 仓外工程"） | 无（不在写域） | **不可选** |
| **合法终点** | — | — | 若甲的必要前置（段账条数／句柄代）**取不到** ⇒ 唯一合法终点＝**诚实拒绝 ＋ 具名 `NOINFO`**（`cParaDesc=0`／具名拒因），**绝不许**用 0 填描述符或交陈旧句柄换"不崩" | — | — | 备选 |

**唯一选靶（本波）**：**甲 · native**，一处两改（同函数体）——
1. **缺陷①**：让 `FsQueryTrackParaList` 的 `FSPARADESCRIPTION` **带真 v 几何**（`dvr_used`／`dvr_top_space`），使 `PtsHelper.Linux.cs:208` 的 `dvrPara` 真推进；缺段账 ⇒ 保持 0 **并具名**（`NOINFO(lm1-ledger-short)`）。
2. **缺陷②**：`win32_pts.c:9145` 交出的 `pfsparaclient` **只许**是"**本窗新造 ∧ 台账在册 live**"的句柄；否则**照 `:9122` 体例具名拒发**（不交陈旧句柄）。
两者**同趟**：因为都长在 `FsQueryTrackParaList` 的填充支上，且②的"陈旧句柄"与①的"0 几何"都源自**跨窗缓存被当现值用**（同源代码）。

---

## §5 边界与 `NOINFO`（如实划界）

1. **未跑**整趟 `verify-all`、**未跑** `static-jaws-check.sh`、**未构建**（照 `T-B1` ②）。
2. **`NOINFO-1`（缺陷②本席复现）**：`FailFast`（`Handle has been already released.`）**本席 9 趟未现取到**；现取的稳定面只有 `tab2` ⇒ `PtsException`（被守护接住）＋空白页。现场三件（`092614`／`094401`／`094259`）的 `FailFast` 原文照录；**能否在本机确定性触发＝`NOINFO`**（疑跑次敏感竞态）。
3. **`NOINFO-2`（现场件世代）**：三件现场日志**不含**五件 `sha16` 行（`run-hc.sh` 只把 sha 印到终端，未落 `hc-run-*.log`）⇒ 现场跑的 `so` 是否＝现权威 `df27801beb222f05` **取不到**（不猜）。
4. **`NOINFO-3`（缺陷①的 OriginX/OriginY）**：native **无**真行几何入站源（`win32_pts.c:7654` 明写 `vrStart`＝**自累加**、`:7687` `urStart=urBBox`）⇒ 题面点名的 `OriginX/OriginY` **本移植取不到**；本件给的是**行盒（ascent/descent＝4191 TextDpi）＋段落盒（`rectDV`）＋渲染帧像素盒**。`NOINFO=fsgeometry-layout`（native 自记）。
5. **`NOINFO-4`（`rectDV=0` 的分布）**：现取只核了 `tab1` 期（`100723:529`）的 8 行主段 `rectDV=0`；**其余段是否也 0** 未逐段普查 ⇒ `NOINFO`（判据 `D1-3` 须补这一普查）。
6. **装置自伤**：见 §1.5-⑥（一趟误开在 `:10`，已按 PID 收净）。
7. **未做**：缺陷①的 `-DWPF_PTS_FSP_PL_DVR=1` 反极副本重建、缺陷②的"拒发"反极腿 —— 均属**落地方**，本件是**只读侦察**。
8. **大件口径**：`/tmp/hc-run-101213.log` 达 `475 MB`／`2351811` 行（本机）；只按 `wc/grep -c/tail/head/sed -n` 读，未全量载入。

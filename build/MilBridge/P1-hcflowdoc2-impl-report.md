# P1-hcflowdoc2 报告 —— `T-B9` hc 流文档页 `tab2`／`tab3` 空白：从「句柄生命周期过度拒发」角度**重攻** —— **实现（判：假设证伪 ＋ 合法终点）**

> 任务：`build/MilBridge/tasks-tail2/T-B9.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T00:5x–01:1x+0800`（各格另注；所有数值**现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=330f9b7`（现取）。
> 权威件：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`5e0d7b807c2fc220`**（现取；＝ `T-B8` 在册值）；`exports=846`。
> 装置：私有 `Xvfb :236 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §8）；应用 ＝ 仓外 hc demo（`cwd=$APP`，`DOTNET` 走 `$HOME/.dotnet`）。**未占 `:10`、未占 `:235`**。
> ⚠️ 本机 `DISPLAY` 为空；所有腿都在 `:236` 上、**只按 PID 收净**。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① 假设（T-B3 的收严对"合法新页"也拒发）** | **证伪**。205 次拒发的**逐条理由**现取为 **`stale-paraclient-across-page-destroy(...)`**（件:行 `win32_pts.c:9243`，内容锚见 §2.1）；**拒发对象**现取为 `is_src_in=1`（`h=0x5`／`site=probe-in`／`h_epoch=0`／`page_destroy_n=1`）⇒ 它是**探针窗内为第一个页造的缓存代（跨窗）**，**不是**「本窗合法新建」⇒ 假设不成立（§2）。 |
| **① 补充（T-B8 的 205 次本身）** | **当前树不可复现**：四趟权威件腿现取**均为 2 次**拒发（＋1 条断页记录 gap ＝ 3 条 `PtsException`）。**197 次形态**只在**移除断页记录 gap 之后**出现（§3.2）—— 即 T-B8 的「205」是**分页引擎真跑起来**之后的伴生现象，**不是空白的成因**。 |
| **② 三方案（逐个真跑）** | **(甲) 精确化＝"本窗现造"** ⇒ **结构上不可用**：拒发点现取 `in_win=0`（`wpf_pts_qtp_create_safe(dp)` ＝ 0）⇒ 这些填充调用**全在窗外（查询期）**，`+176` 不可发（T-A33）⇒ 无法"本窗新造"（§3.1）。**(乙) 断页记录"已摘表页"认领**（实验件 `553f1e1ecb3714bd`）⇒ **分页引擎真前进**（`[FSPAGE-DESTROY]` 7→**202**、`[FSPARALIST-FILL-SP]` 260→**7250**），但**帧面回退**（`tab2` 由"自己的空白帧"变成**停在 `tab1` 的画面**）⇒ **不落**（§3.2）。**(丙) 真断点 ＝ 页视觉链**（`[QPD] vis_built` 恒 0）⇒ **具名第三方案**（§3.3）。 |
| **③ 帧面成对（同一权威件，只差 env／只差实验件）** | **两处收严都不是空白的成因**：`br_rev`（断页记录认领 **＋** 两处句柄收严全关）⇒ `[HC-UNHANDLED]=0`／`Unrecoverable=0`／`alive=yes`，而 `tab2`／`tab3` 帧**逐字节等于基线**（`1fb95eab89966441`／`0c51d1ad6fa46543`）⇒ **全链零异常，画面一字未变**（§4）。 |
| **④ T-B3 的反极性（放回跨窗陈旧句柄 ⇒ 必红）** | **`NOINFO`（本装置不可复现）** —— `WPF_PTS_HANDLE_STRICT=0` 两腿（`rev1`／`br_rev`，含 `264`／`231` 次页销毁 ＋ `1095`／`955` 次填充）**均无 `FailFast`**、`alive=yes`／`app_rc=143`。与 `T-B3` 自报的 `NOINFO-1` **同形**（§4.2）。 |
| **⑤ 门禁（现取）** | `nm==exports`（**846==846**，`diff` 空）｜`PTSGAP=PASS`（`so16=5e0d7b807c2fc220 exports=846`，`tool=54 dead=11 artifact=1 ops=42 impl=42`）｜`PTS_GUARD=PASS legs=2/2`｜`PTS_COLORANCHOR=PASS k=24 hits=3`｜`DEFREG=PASS declared=225 route_ids=225` rc=0｜`REPORTID=PASS files=356 ids=2265 declared=225` rc=0（§6） |
| **⑥ 症状门（成对）** | 三条基线腿 `alive=yes`／`app_rc=143`（本席按 PID 收）／`magenta=0`／`Unrecoverable=0`；`[HC-UNHANDLED]=3`（＝2 条 `stale` ＋ 1 条 `unknown-breakrec` 两处 gap，逐条可对账）（§7） |
| **⑦ 边界（未违）** | **仓内零产品件改动**（`git status --porcelain` 现取只有三件未跟踪 md，见 §9）；**未改仓外 hc 工程**、**未改 `upstream/**`**、**未改 `verify-all.sh`／`close-wave.sh`／`build/MilBridge/tools/**`**；**未跑整趟 `verify-all`**；显示位与进程**按 PID 收净** |

**一句话**：T-B9 的假设 —— 「T-B3 的收严把**合法新页**也拒发 ⇒ `tab2/tab3` 空白」 —— **证伪**：拒发对象是**探针窗内为第一个页造的跨窗缓存代**（不是本窗新页），而且**把两处收严全部关掉、`[HC-UNHANDLED]` 降到 0，画面仍逐字节不变**（`tab2=1fb95eab89966441`／`tab3=0c51d1ad6fa46543`）；**空白的真断点在页视觉链（`[QPD] vis_built` 恒 0）**，其前置是「分页页窗口生命周期」（`T-B8` 的 `PRECOND-FINITE-PAGE-WINDOW-LIFECYCLE`／`PRECOND-FINITE-PAGE-VISUAL-CHAIN`）。本轮**仓内零产品件改动**，如实判**合法终点（失败）**，不假成功。

---

## §1 ① 复现（步骤 ＋ 日志路径 ＋ "确已进页"标记）

### 1.1 装置与步骤（可复算）

```bash
# 装置（自起自收；PID 记 ~/tb9-work/{xvfb,wm}.pid）
Xvfb :236 -screen 0 1280x1024x24 &   DISPLAY=:236 xfwm4 --compositor=off &
APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0
cd "$APP"; DISPLAY=:236 HC_NO_SPLASH=1 HC_INPUT_DIAG=1 HC_GEO_EVERY=1 dotnet HandyControlDemo.dll >app.log 2>&1 &
# 进「流文档」页（左侧导航 item 24，`[GEO]` 现取坐标点击）
python3 build/MilBridge/tests/PtsPagesProbe/navclick.py --log app.log --pid <PID> --display :236 \
        --out <shots> --item 24 --expect FlowDocumentDemo
# 逐 tab（默认 `tabs.py`：tab1→tab2→tab3；`order.py`：按给定序，截 t1／t6 两张）
```

装置件（仓外私有，`~/tb9-work/`）：`leg.sh`（腿跑器）／`tabs.py`／`order.py`（`T-B8` 同款）／`docink.py`（只读 PNG 的文档区色数/具名色）。**重活走槽**：`bash ~/heavy-slot.sh --min-avail 2500 --max-hold 900 --wait 900 -- <腿>`。

页签现取几何（两腿逐字相同）：

```
[GEO] TabItem#- scr=268,82 wh=165x27 en=True vis=True htv=True hdr=流文档滚动视图 sel=True
[GEO] TabItem#- scr=440,82 wh=165x27 en=True vis=True htv=True hdr=流文档单页视图 sel=False
[GEO] TabItem#- scr=611,82 wh=165x27 en=True vis=True htv=True hdr=流文档查看器   sel=False
```
⇒ 点中心 `(350,95)`／`(522,95)`／`(693,95)`；点后 `sel_after` 三条**逐条翻对** ⇒ **输入命中无误**。

### 1.2 日志路径与件指纹（都在仓外私有目录）

| 腿 | 仪器／件 | 日志 | 日志 `sha16` | 字节 |
|---|---|---|---|---|
| `base`（权威件、`1,2,3`） | — | `~/tb9-work/logs/base/app.log` | `6742c9a1b2ad37be` | 1,886,976 |
| `base2`（权威件、再跑一趟） | — | `~/tb9-work/logs/base2/app.log` | `1e9531939e46751d` | 2,071,149 |
| `ord321`（权威件、`3,2,1`） | — | `~/tb9-work/logs/ord321/app.log` | `2df0d23dbae9c9ea` | 1,981,170 |
| `ord23`（权威件、`2,3`） | — | `~/tb9-work/logs/ord23/app.log` | `2581a75f8a4609e6` | 2,113,681 |
| `diag1`（**仪器件**） | `.so 28ef793d6873b3f9` | `~/tb9-work/logs/diag1/app.log` | `2551aa0f61e7cd0d` | 2,072,430 |
| `rev1`（仪器件 ＋ `WPF_PTS_HANDLE_STRICT=0`） | `.so 28ef793d6873b3f9` | `~/tb9-work/logs/rev1/app.log` | `73a799d61c5c5f32` | 51,546,037 |
| `br1`（**断页记录实验件**） | `.so 553f1e1ecb3714bd` | `~/tb9-work/logs/br1/app.log` | `fe839c7b09e3e907` | 2,287,311 |
| `br1ord`（同件，`order 2,3`） | `.so 553f1e1ecb3714bd` | `~/tb9-work/logs/br1ord/app.log` | `7d0216bb32855da5` | 3,001,324 |
| `br_rev`（同件 ＋ `STRICT=0`） | `.so 553f1e1ecb3714bd` | `~/tb9-work/logs/br_rev/app.log` | `4c07e5665c15998b` | 45,242,706 |
| `recom1`（断页记录 ＋ 窗内现造实验件） | `.so cbd4156726ea5a9a` | `~/tb9-work/logs/recom1/app.log` | `f04370d503dac188` | 2,644,440 |

（截图 `*.png` 与其 `sha16` 见 §4；日志体积按纪律 39 只用 `grep -c`／`wc`／`stat` 读。）

### 1.3 「确已进页」标记 ＝ `[FORMATLINE-LINE]` 计数（现取）

```
所有腿：FORMATLINE_LINE_after_nav=76 ；逐 tab 后 = 114 ；NS_TAIL … [NS] loaded HandyControlDemo.UserControl.FlowDocumentDemo
```
⇒ **确已进页**。**故"空白"不是"没进去"，是"进去了但画不出来"**（与 `T-B8` 一致）。

---

## §2 ① 逐条拒发：理由、判据、**拒发对象出处**（件:行 ＋ 现取读数）

### 2.1 承重判据的件:行（现取，均附内容锚）

| # | 件:行（现取） | 内容锚原文 | 作用 |
|---|---|---|---|
| P1 | `src/WpfGfx.Linux.Native/src/win32_pts.c:2953-2955` | `static int wpf_pts_handle_epoch_stale(const wpf_pts_doc *d)` ／ `return (d && d->fsp_pl_epoch != d->page_destroy_n) ? 1 : 0;` | `T-B3` 的收严判据本体的**唯一实现** |
| P2 | `…win32_pts.c:7320` | `{ wpf_pts_doc *ddp = wpf_pts_doc_ptr(pfscontext); if (ddp) { ddp->drive_handles_live = 0; ddp->page_destroy_n++; } }` | 页销毁代**只增**的**唯一**自增点 |
| P3 | `…win32_pts.c:9243` | `reason = "stale-paraclient-across-page-destroy(not-this-window-live;HandleToObject-would-FailFast)";` | `FsQueryTrackParaList` 填充支的**具名拒发**（＝ 205／197／189 次那一族） |
| P4 | `…win32_pts.c:10633` | `if (!pg) reason = "unknown-breakrec";` | `FsDestroyPageBreakRecord` 的**具名拒发**（本轮新点名的**第二条** gap） |

### 2.2 205／197 次拒发的**逐条理由**（现取机读，`diag1`）

```
# 逐理由计数（`grep -o 'reason=[^ ]* entry=[A-Za-z0-9_]*' … | sort | uniq -c`，非 `ok` 者）
      2  reason=stale-paraclient-across-page-destroy(not-this-window-live;HandleToObject-would-FailFast) entry=FsQueryTrackParaList
      1  reason=unknown-breakrec entry=FsDestroyPageBreakRecord
# 对应失败出口（同一份日志）
[FS_PAGE_GAP] rc=-10000 reason=stale-paraclient-across-page-destroy(...) entry=FsQueryTrackParaList ctx=… track=… cParas=1 owned=1 ok=15 gap=1 cur_tid=… win_tid=…
[FS_PAGE_GAP] rc=-10000 reason=unknown-breakrec entry=FsDestroyPageBreakRecord ctx=0x604850f7aef0 p=0x604850f7a9d8 ok=0 gap=1 out=NO-OUTPUT
[HC-UNHANDLED] #1 PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'. ｜ 首帧 at …PTS.Error(Int32 fserr, PtsContext ptsContext)
```
⇒ **3 条 gap（2 条 P3 ＋ 1 条 P4）＝ 3 条 `PtsException`**（逐条可对账）。

**⚠️ 口径（如实）**：`T-B8` 报告里的「`[FS_PAGE_GAP] rc=-10000` **×205**」**在当前树不可复现** —— 四趟权威件腿（`base`／`base2`／`ord321`／`ord23`）现取**均为 2 次** `stale` ＋ 1 次 `unknown-breakrec`，`tab2`／`tab3` 帧**四趟逐字节相同**（§4.1）。`197` 次形态只在**把断页记录 gap 修掉之后**出现（§3.2 `br1`：`stale=197`）⇒ **「205」是"分页引擎真跑起来"之后的伴生读数**，不是空白的成因（§3.2／§4.2 两处成对证据）。

### 2.3 **拒发对象是不是「本窗合法新建」？**（现取，`diag1`）

```
[FSSTALE] entry=FsQueryTrackParaList h=0x5 site=probe-in gen=1 quota=16 h_epoch=0 page_destroy_n=1 src_in=0x5 src_out=(nil) drive_nmp=0x3 is_src_in=1 is_src_out=0 is_drive_nmp=0 win=in in_win=0 live=0 refused=1 v=STALE-ACROSS-PAGE-DESTROY
[FSSTALE] entry=FsQueryTrackParaList h=0x5 site=probe-in gen=1 quota=12 h_epoch=0 page_destroy_n=1 … is_src_in=1 … in_win=0 live=0 refused=2 v=STALE-ACROSS-PAGE-DESTROY
```
（`[FSSTALE]` 为 `T-B9` 临时插桩行；其四处写点／读数口径逐字见 §3.0。）

| 判据要问的 | 现取答案 |
|---|---|
| 拒发对象是**哪一枚**？ | `h=0x5`，`site=probe-in`，`gen=1`，`is_src_in=1` ⇒ **探针窗内 `+176` 造出的 `fsp_pl_src_in`** |
| 它是「**本窗**新造」吗？ | **否** —— 它在**第一个页**的 `FsCreatePage*` 窗内造出（`site=probe-in`），而本次填充发生在**第 N 次页销毁之后**（`h_epoch=0 ≠ page_destroy_n=1`）⇒ 属**跨窗缓存代** |
| 它「已销毁」吗（＝判据的真实指控）？ | **取不到成立证据**：本侧**从不**对它发 `+192`；`WPF_PTS_HANDLE_STRICT=0` 真把它交出去后**无 `FailFast`**（§4.2）|
| 本次填充在**窗内**吗？ | **否** —— `in_win=0`（`win=in` 只是"用的是窗内造的源"）⇒ 本次是**查询期**调用（§3.1）|

⇒ **假设「T-B3 的收严对合法新页也拒发 ⇒ 空白」＝ 证伪**（拒发对象**不是**本窗合法新建；且它也不是可证的"已销毁"）。

---

## §3 三方案（逐个真跑；**最多 3 方案**已用满）

### 3.0 插桩（只读观测行；**本轮未落仓**）

为得到 §2.3 的逐条出处，本席在副本上加了**三条只读观测行**（`[FSSTALE]`／`[FSPAGE-DESTROY]`／`[FSBREAKREC]`，写点分别紧跟 P3 拒发、`FsDestroyPage` 成功出口、P4 拒发），并单独编出实验件 **`28ef793d6873b3f9`**。**零行为改动**：该件的四条权威件腿帧／症状门与权威件 `5e0d7b807c2fc220` **逐字节相同**（`diag1`：`boot b21eb530afd3c66c`／`tab1 b440033da8b2a9e6`／`tab2 1fb95eab89966441`／`tab3 0c51d1ad6fa46543`）。`FS_PAGE_GAP` 的**逐理由**则**权威件本身就有**（`diag1` 与 `base` 逐条同值）。

### 3.1 方案（甲）· "收严改精确 ＝ 允许本窗现造" —— **结构上不可用（现取证伪）**

判据要求的收严改法是：**窗内**时丢弃跨窗缓存代、交 ④ 在**本窗现造**一枚（"本窗新造"）。本席把这条真写了（实验件 **`cbd4156726ea5a9a`**）并真跑（`recom1`）：

```
# 现取（recom1）：189 条拒发**全部**落在 else 支（＝窗外），DISCARD 支命中 0
      189 v=STALE-ACROSS-PAGE-DESTROY     # 期望的 v=STALE-REPLACED-BY-IN-WINDOW-CREATE 一条都没有
      744 action=                         # 空 action（＝未进 DISCARD 支）
```
⇒ **`wpf_pts_qtp_create_safe(dp)` 在拒发点现取恒为 0**（`[FSSTALE] … in_win=0`，两处拒发逐条如此）⇒ 这些填充调用**全部发生在格式窗之外（查询期）**（承 `T-A33`：窗外发 `+176` 必撞 `PtsContext` 的不可捕获断言）⇒ **"本窗新造"这条路在本入口上结构上不存在**。**(甲) 判死**。

### 3.2 方案（乙）· 断页记录"**已摘表页**"认领 —— **引擎真前进，但帧面回退 ⇒ 不落**

**动机（本轮新点名）**：P4（`win32_pts.c:10633` 内容锚 `if (!pg) reason = "unknown-breakrec";`）把**已摘表页**的断页记录句柄拒成 `unknown-breakrec`。现取对象出处：

```
[FSBREAKREC] reason=unknown-breakrec p=0x586de86469c8 ctx=0x586de86b6d60 live_n=3 retired=3 destroy_n=3 live_brs=0x586decd3d578,0x586de86b9ac8,0x586de866aa38,
[FSPAGE-DESTROY] ctx=0x586de86b59e0 page=… live_n=… destroy_n=… ok=… retired=…   （diag1 共 7 条，两个 ctx：3＋4）
```
⇒ 入参 `p` **不在**任何在册页的断页记录句柄里，但它是**已摘表页**的（页内存**永不 `free`**，`T-A33`）⇒ 该拒发是**过严**：托管 `PtsPage.OnBeforeFormatPage` **先** `DestroyPage()`、**后**才回收旧 `PageBreakRecord`（上游 `PtsPage.cs` 的 `Dispose`／`OnBeforeFormatPage`／`DestroyPage`）。

**实验（件 `553f1e1ecb3714bd`；副本先行，仓内零写）**：在 `FsDestroyPage` 摘表**前**把页对象登记进一张"已摘表"清单，`FsDestroyPageBreakRecord` 在**在册页之外**再按**字段地址**认领该清单（**仍拒不认得的未知值**）。

现取成对（权威件 `5e0d7b807c2fc220` vs 实验件 `553f1e1ecb3714bd`；同装置同流程）：

| 面 | 权威件 | 实验件（乙） | 说明 |
|---|---|---|---|
| `[FSPAGE-DESTROY]` | （无仪器）7（`diag1`） | **202** | **分页引擎真跑起来**（页销毁 ×29） |
| `[FSPARALIST-FILL]`（页轨主路径） | 29 | 29 | 不变 |
| `[FSPARALIST-FILL-SP]`（子页轨路径） | 260 | 7250 | ×27.9 |
| `[FS_PAGE_GAP] reason=stale…` | 2 | **197** | **T-B8 的「205 形态」在此首次复现**（＝引擎跑起来的伴生现象） |
| `[HC-UNHANDLED]` | 3 | **197** | 其中 **197 条全为 `stale` 那一族** |
| `Unrecoverable`／`alive`／`app_rc` | 0／yes／143 | 0／yes／143 | **无 `FailFast`** |
| **`tab2` 帧** | **`1fb95eab89966441`**（自己的空白帧） | **`b440033da8b2a9e6`**（`tabs 1,2,3`） | **回退：画面停在 `tab1`** |
| **`tab2` 帧（`order 2,3`）** | — | **`ec40be7a64c60d03`** | 其文档区＝ `ink=17135 colors=764 GhostWhite=10084 Beige=924 DarkGreen=49 LightGoldenrodYellow=5884` ⇒ **与 `tab1` 逐格相同** |
| `tab3` 帧 | `0c51d1ad6fa46543` | `0c51d1ad6fa46543`〔`tabs`〕／`40dbbd1703f3e360`〔`order`〕 | 无改善 |

⇒ **(乙) 让分页引擎真前进，但把 `tab2` 从"自己的空白帧"变成"停在上一 tab"** ⇒ 用户可见**净负** ⇒ **本席不落此改**（如实记，供后续波次决定）。**(乙) 判"正确但不落"**。

### 3.3 方案（丙）· 真断点 ＝ **页视觉链**（具名第三方案）

**(丙-1) 两处收严**（P1／P3 与 `FsQuerySubtrackParaList` 的同族条）**都不是空白的成因** —— 现取铁证（§4.2）：把两处收严**全部关掉**并**同时**落 (乙)，`[HC-UNHANDLED]=0`／`PtsException=0`／`Unrecoverable=0`／`alive=yes`，而 `tab2`／`tab3` 帧**逐字节等于基线**。

**(丙-2) 真断点** —— 页视觉链的**下游见证恒不翻转**：

```
[QPD] rc=0 fskupd=2 first=1 adj=0 page=… page_qpd=1 vis_built=0 qpd_ok=1 qpd_gap=0 new_n=1 nc_n=0 vis_n=0 seq=6 NOINFO=fspagedetails-page-change-tracking
# 现取分布（br_rev，全链零异常那一趟）：vis_built=0 ×1194 ； vis_built=1 ×1
```
`vis_built` 的判据（`win32_pts.c` 内容锚 `if (pg && pg->qpd_new_pending && pg->qpd_fstd_since == 1) { … pg->qpd_vis_built = 1; … }`，即 `[VIS]` 的唯一发点）在本跑里**几乎从不成立** ⇒ 分页页的**轨视觉未建起**（上游链：`PtsPage.UpdatePageVisuals` → `PtsHelper.UpdateTrackVisuals` → `ParaListFromTrack` → `FsQueryTrackParaList`）。

**(丙-3) 为什么它不是一个"一跳可修"** —— 与 `T-A17`／`T-A47` 同族的**根因**：本移植把「页窗」的句柄生命周期读成了「整 doc 一次性」（`drive_nmp`／`src_in` 只在**第一个页**的窗内造出），而分页路径是**多页生命周期**（`FsCreatePage*`／`FsDestroyPage` 交替）。⇒ 要让 `tab2/tab3` 真出内容，须**同时**：

1. `PRECOND-FINITE-PAGE-WINDOW-LIFECYCLE`：让**每个页窗**自持一份**合法** `paraclient`（现模型是"跨调用缓存 ＋ 页销毁代收严"），**且不动** `T-B3` 的 `FailFast` 防护；
2. `PRECOND-FINITE-PAGE-VISUAL-CHAIN`：让 `[QPD] vis_built` 那条链真走通（`UpdatePageVisuals` → `UpdateTrackVisuals`）；
3. （承 `T-B8` 缺陷②）`PRECOND-FLOAT-AVOIDANCE`：`pfnFormatLine` 要**知道浮动盒几何**。

⇒ 三条都动**分页窗口与视觉链**（面大、且**极易**打坏已工作的 `tab1` 与 `FailFast` 防护）⇒ **本增量判合法终点（失败）**，**不假成功**。

---

## §4 ②③ 帧面成对 ＋ 反极性（现取）

### 4.1 权威件：四趟腿**逐字节相同**（复现稳定性）

| 面 | `base`（`1,2,3`） | `base2`（`1,2,3`） | `ord321`（`3,2,1`） | `ord23`（`2,3`） |
|---|---|---|---|---|
| `boot` `sha16` | `b21eb530afd3c66c` | 同 | 同 | 同 |
| `tab1` `sha16` / 全屏 `colors` | `b440033da8b2a9e6` / 1078 | 同 | 同 | 同 |
| **`tab2` `sha16` / `colors`** | **`1fb95eab89966441` / 551** | 同 | 同 | 同 |
| **`tab3` `sha16` / `colors`** | **`0c51d1ad6fa46543` / 562** | 同 | 同 | 同 |
| `[HC-UNHANDLED]` | 3 | 3 | 3 | 3 |

**文档区（`x∈[250,795] ∧ y∈[100,600]`，`docink.py` 只读 PNG；具名色容差 ±3）**：

| 面 | `ink` | `colors` | `GhostWhite`／`Beige`／`DarkGreen`／`LightGoldenrodYellow`／`LightGray` |
|---|---|---|---|
| **`tab1`（滚动视图）** | **17135** | **764** | **10084／924／49／5884**／4077 |
| **`tab2`（单页视图）** | **1662** | **125** | **0／0／0／0**／7 |
| **`tab3`（查看器）** | **1679** | **149** | **2／0／0／0**／12 |

⇒ `tab2`／`tab3` **具名色全 0**（`LightGray=7/12` 是空态帧就有的 44/51 px 那一族）、`ink` 只有 `tab1` 的 **1/10**。

### 4.2 反极性／证伪腿（同一 `.so`，**只差一个 env**；`br_rev` 另加 (乙)）

| 面 | `base`（权威件） | `rev1`（仪器件 ＋ `WPF_PTS_HANDLE_STRICT=0`） | `br1`（(乙) 件） | **`br_rev`（(乙) ＋ `STRICT=0`）** |
|---|---|---|---|---|
| 两处句柄收严 | 开 | **关** | 开 | **关** |
| 断页记录"已摘表页"认领 | 无 | 无 | **有** | **有** |
| `[FSPAGE-DESTROY]` | （无仪器） | 264 | 202 | 231 |
| `[FSPARALIST-FILL]`／`-SP` | 29／260 | **1095／8259** | 29／260 | **955／7250** |
| `[FS_PAGE_GAP] stale…` | **2** | **0** | **197** | **0** |
| `[FS_PAGE_GAP] unknown-breakrec` | 1 | 4 | **0** | **0** |
| `[HC-UNHANDLED]`／`PtsException` | **3／3** | 2／2 | 197／197 | **0／0** |
| `Unrecoverable`／`alive`／`app_rc` | 0／yes／143 | **0／yes／143** | 0／yes／143 | **0／yes／143** |
| **`tab2` 帧** | `1fb95eab89966441` | `b440033da8b2a9e6` | `b440033da8b2a9e6` | **`1fb95eab89966441`（＝基线）** |
| **`tab3` 帧** | `0c51d1ad6fa46543` | `0c51d1ad6fa46543` | `0c51d1ad6fa46543` | **`0c51d1ad6fa46543`（＝基线）** |

⇒ **两条铁证**：① **哪一极都无 `FailFast`**（`STRICT=0` 真把跨窗句柄交出去，含 264／231 次页销毁 ＋ 1095／955 次填充，`Unrecoverable=0`）⇒ **T-B3 的反极性（放回跨窗陈旧句柄 ⇒ 必红）在本装置不可复现** ⇒ 记 **`NOINFO`**（与 `T-B3` 自报的 `NOINFO-1` 同形）。② **把两处收严全关＋(乙)，`[HC-UNHANDLED] 3→0`，而 `tab2/tab3` 帧逐字节等于基线** ⇒ **空白的成因不在句柄生命周期**。

### 4.3 反极性（本增量"可给者"）

**本增量仓内零产品件改动** ⇒ **无"撤修"腿可给**；已给的是：**(a)** 上表**同一权威件、只差 env／只差实验件**的四极；**(b)** `(乙)` 实验件的"帧面回退"成对读数（§3.2）。⇒ 具名 `NOINFO(reason=no-shipped-fix-to-revert)`。

---

## §5 归因（托管源码，`upstream/**` **只读**）

`T-B3` 收严判据的**前提**是「`FsDestroyPage` ⇒ 托管 `PtsContext` 已回收该页造的 paraclient 槽」。现取托管源码（只读，附内容锚）：

| 件 | 内容锚 | 说明 |
|---|---|---|
| `upstream/…/PtsHost/PtsContext.cs` | `internal IntPtr CreateHandle(object obj)` ／ `_unmanagedHandles[handle].Obj = obj;` | `CreateHandle`（`+176` 的落点）把对象**强引用**存进 `_unmanagedHandles` |
| 同上 | `internal void ReleaseHandle(IntPtr handle)` ／ `Invariant.Assert(_unmanagedHandles[handleLong].IsHandle(), "Handle has been already released.");` | 槽**只**在 `ReleaseHandle` 里清（＝ `UnmanagedHandle.Dispose`） |
| 同上 | `private void OnDestroyPage(IntPtr ptsPage, bool enterContext)` ／ `PTS.Validate(PTS.FsDestroyPage(_ptsHost.Context, ptsPage));` | **页销毁**只清页自己的句柄；**不**清 paraclient 槽 |
| 同上 | `internal object HandleToObject(IntPtr handle)` ／ `Invariant.Assert(…IsHandle(), "Handle has been already released.");` | 抛出点：**只有槽真被清**才炸 |
| 同上 | `internal int DestroyParaclient(IntPtr pfsclient, IntPtr pfsparaclient)` ／ `BaseParaClient paraClient = PtsContext.HandleToObject(pfsparaclient) as BaseParaClient; … paraClient.Dispose();` | `+192` **是** paraclient 槽的主要释放者（`BaseParaClient : UnmanagedHandle` ⇒ `Dispose` ⇒ `ReleaseHandle`） |

**全树现取的"释放者"清点**（`grep -n 'Dispose' *.cs` 后按"谁在释放 paraclient"逐条判）：`PtsHost.DestroyParaclient`（＝`+192`）／`PtsContext` 整体销毁 ／ `CellParagraph.Dispose`（**单元**客户端，`CellParagraph.cs` 内容锚 `cellParaClient.Dispose();`）。**未见**第四条 —— 尤其**未见**"页销毁 ⇒ 释放该页的 paraclient" 这条链（`PtsPage.cs` 的 `Dispose(bool)` 内容锚 `_ptsPage = IntPtr.Zero; _breakRecord = null; _visual = null;` **不含**任何客户端释放）。

⇒ 在**托管源码层面**，页销毁**不**释放 `+176` 造出的 paraclient 句柄（`BaseParagraph` 亦**不**持有/释放它 —— `BaseParagraph.cs` 现取零 `Dispose`／零 `_paraClient` 字段）。这与 §4.2 的**现场读数**一致（`STRICT=0` 无 `FailFast`）。

⚠️ **如实划界（本席不据此下"判据是错的"结论）**：`T-B3` 现场那条历史 `FailFast`（`h0=0x5` ＋ `ok=1645`）其**真正的释放路径**本席**取不到**（那一趟的 `ok=1645` 形态在当前树不可复现；`0x5` 当时是哪条支造的、被谁释放，**无件可考**）⇒ 记 `NOINFO(reason=T-B3-历史FailFast-的释放路径不可考)`。⇒ 本席**维持收严逐字不动**（§8-2／§8-6）。

**但本席据此不改判据**（如实划界）：① 判据要的是"跨窗陈旧 ⇒ 必红"的**反极性**，本装置**取不到**（§4.2 ③＝`NOINFO`）；② 任务硬边界明写「**不许**放宽到一律放行」；③ `WPF_PTS_HANDLE_STRICT=0` 之下 `tab2` 反而**回退**成"停在上一 tab"（§4.2）⇒ 放宽**没有净收益**。⇒ 维持 `T-B3` 的收严**逐字不动**，把"前提待证伪/重审"作为**具名下一靶**交回。

---

## §6 门禁（逐条现取，本席跑的；**因为仓内零产品件改动，这些读数即 `HEAD=330f9b7` 的在册值**）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only …/libwpfwin32.so \| awk '{print $3}' \| sort` vs `bin/exports.txt` | **846 == 846**，`diff -q` 空 |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5e0d7b807c2fc220 exports=846`**；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`；`PTSGAP_CITED=PASS refs=1`；rc=0 |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg24-colors-out-of-band=1220,leg23-colors-out-of-band=636 direction=in-file phase=realized`**；`PTS_G10_NAME=PASS observed=FsQueryTextDetails`；`PTS_ENFE=PASS total=0`；rc=0 |
| `PTS_COLORANCHOR` | 同上（`k=24`） | **`PTS_COLORANCHOR=PASS k=24 hits=3`**（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`，`min=200`，基线全 0）**未回退**；`k=23` `NOINFO(no-anchor-registered-for-k23)`（照在册口径） |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0 keys=-`，**rc=0** |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=356 ids=2265 declared=225`**，rc=0（本载体落地**前**现取；落地后 ＋1 ＝本件） |

**未跑**：整趟 `verify-all`（照 `T-B9` ②）。

---

## §7 ④ 症状门（成对）

| 症状门 | 权威件（四趟） | `rev1`（`STRICT=0`） | `br1`（(乙)） | `br_rev`（(乙)＋`STRICT=0`） |
|---|---|---|---|---|
| `alive` | `yes` | `yes` | `yes` | `yes` |
| `app_rc` | `143` | `143` | `143` | `143`（＝本席 `kill`，非应用自退） |
| `magenta`（页级占位） | `0` | `0` | `0` | `0` |
| `Unrecoverable system error` | `0` | `0` | `0` | `0` |
| `[HC-UNHANDLED]` | `3`（＝2 `stale` ＋ 1 `unknown-breakrec`） | `2` | `197` | `0` |
| `colors`（全屏） | `boot=386／tab1=1078／tab2=551／tab3=562` | `tab2=1078` | `tab2=1078` | `tab2=551／tab3=562` |
| `[FORMATLINE-LINE]` | `76`→`114` | `114` | `114` | `114` |

⚠️ **口径（如实）**：本报告**不**用"`FailFast` 字样计数"当症状门（`grep -c FailFast` 会把**守护接住的异常栈帧**也数进去）——**唯一可信的"没死"读数是 `Unrecoverable=0 ∧ alive=yes`**（四腿全成立）。

---

## §8 具名 `NOINFO` / 前置 / 边界（如实划界）

1. **`NOINFO(reason=T-B8 的 205 次拒发在当前树不可复现)`**：四趟权威件腿现取均 **2 次** `stale`；`197` 次形态只在**移除断页记录 gap 之后**出现（§3.2）。
2. **`NOINFO(reason=T-B3 反极性不可复现)`**：`STRICT=0`（`rev1`／`br_rev`，含 264／231 次页销毁）**无 `FailFast`**；与 `T-B3` 的 `NOINFO-1` 同形。**不拿"不死"冒充"反极性已证"**。
3. **`NOINFO(reason=[QPD] vis_built 恒 0 的机制)`**：只读到"见证恒 0"（`br_rev` 现取 `0×1194 / 1×1`），**未**定位到 `UpdatePageVisuals`→`UpdateTrackVisuals` 为何不建起（须渲染面插桩）。
4. **`NOINFO(reason=本增量无"撤修"反极性腿)`**：仓内零产品件改动 ⇒ 无修可撤（§4.3）。
5. **具名前置（本增量写域外／面过大，不在本轮做）**：`PRECOND-FINITE-PAGE-WINDOW-LIFECYCLE`／`PRECOND-FINITE-PAGE-VISUAL-CHAIN`／`PRECOND-FLOAT-AVOIDANCE`（§3.3）。
6. **候选改（**已真跑、**不落**）**：`(乙)` 断页记录"已摘表页"认领（件 `553f1e1ecb3714bd`）—— 引擎真前进（`[FSPAGE-DESTROY]` 7→202、`-SP` 260→7250）但**帧面回退**（`tab2` 停在上一 tab）⇒ 按"每一行改动都能追溯到请求且带来净收益"**不落**（§3.2）。
7. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑整趟 `verify-all`**。
8. **`app-local` 逐件复原（任务点名的硬边界）**：实验腿把 (乙) 件刷进过应用目录，收尾已 `sync-applocal.sh` **逐件复原** ⇒ 现取 `SYNC-APPLOCAL=PASS … items=5 ok=4 synced=1 drift=0 rc=0`（`libwpfwin32.so 553f1e1ecb3714bd → 5e0d7b807c2fc220`，回读断言通过）。

---

## §9 边界 · 收净 · 自证

- **写域**：**仓内仅新增本载体** `build/MilBridge/P1-hcflowdoc2-impl-report.md`。`git status --porcelain` 现取：
  ```
  ?? build/MilBridge/P1-hcflowdoc-impl-report.md   （T-B8 载体，非本席所建）
  ?? build/MilBridge/tasks-tail2/T-B8.md           （主控派单件，非本席所建）
  ?? build/MilBridge/tasks-tail2/T-B9.md           （主控派单件，非本席所建）
  ?? build/MilBridge/P1-hcflowdoc2-impl-report.md  （本载体）
  ```
  `git diff --stat` 现取**为空**（`src/win32_pts.c`／`bin/exports.txt`／`tools/pts-gap-decl.txt` 与 `HEAD` 逐字节相同；`libwpfwin32.so` 现取 `5e0d7b807c2fc220` ＝ 在册值）。
- **副本先行／写前备份**：`~/tb9-work/bak/{win32_pts.c,exports.txt,libwpfwin32.so,pts-gap-decl.txt}`（`cp -p`，取在**任何写之前**；`win32_pts.c` 备份 = `edaf0bf17ede9bb9` ＝ `HEAD` 侧现读值）；实验后已 `cp -p` 回填并复编，复编产物 `so16=5e0d7b807c2fc220`（＝ 在册值，可复算）。
- **仓外私有件（不在仓内）**：`~/tb9-work/{leg.sh,tabs.py,order.py,docink.py,logs/,bak/}` 与三枚实验 `.so`（`28ef793d6873b3f9`／`553f1e1ecb3714bd`／`cbd4156726ea5a9a`）。
- **进程/显示收净**：`:236` 的 `Xvfb`（`~/tb9-work/xvfb.pid`＝3052111）与 `xfwm4`（`~/tb9-work/wm.pid`＝3052115）**按 PID 收净**；所有 `HandyControlDemo` 进程按 PID 收（`app_rc=143` 即本席所杀，现取 `ps -eo pid,comm | grep -i handy` 无输出）；`/tmp/.X11-unix/` 现取只剩 `X0/X1/X11`（非本席）。
- **纪律自证**：重活走 `~/heavy-slot.sh --min-avail 2500 --max-hold 900 --wait 900`；显示位只用空闲 `:236`；`temp+rename`（本载体）；**报数一律现取**（纪律 40）；`T-B3` 的收严**一字未动**（`git diff` 空）。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hcflowdoc2-impl-report.md | sha256sum | cut -c1-16`）＝ **`7269670ca6375c63`**（本行下方无内容，取该行之前全文的哈希）。

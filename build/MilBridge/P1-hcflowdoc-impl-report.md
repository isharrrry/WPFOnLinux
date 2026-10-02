# P1-hcflowdoc 报告 —— `T-B8` hc demo「流文档」页三缺陷（单页视图打不开／tab1 遮挡／tab3 空白）定位＋修 —— **实现（判：合法终点）**

> 任务：`build/MilBridge/tasks-tail2/T-B8.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T00:3x–01:2x+0800`（各格另注；所有数值**现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=330f9b7`（现取）。
> 装置：私有 `Xvfb :235 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §8）；应用 ＝ `bash ~/run-hc.sh` 的等价调用（`cwd=$APP`，`DOTNET` 走 `$HOME/.dotnet`）。**未占 `:10`**。
> ⚠️ 本机 `DISPLAY` 为空；所有腿都在 `:235` 上、**只按 PID 收净**。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① 逐条复现** | 三条**全部复现**（同一装置、同一权威件五件）：`tab1`（滚动视图）**有内容**（`colors=1078`、具名色齐）；`tab2`（单页视图）**空白**（`colors=551`、具名色全 0）；`tab3`（查看器）**空白**（`colors=562`、具名色全 0）。§1／§2 |
| **① `FORMATLINE-LINE`（"确已进页"标记）** | 进页前 `0` → 进页后 **76** → 逐 tab 后 **114**（§1.3） |
| **② 第一处断点（缺陷①③，同一根因族）** | **`src/WpfGfx.Linux.Native/src/win32_pts.c`** 内容锚 `reason = "stale-paraclient-across-page-destroy(not-this-window-live;HandleToObject-would-FailFast)";`（现取 `:9243`；判据在 `:9241`）⇒ 分页页格式**中止**（`[FS_PAGE_GAP] rc=-10000` ×205 ⇒ `PtsException('-10000')` ×206）；**第二见证**：`[QPD] … vis_built=0` **640/641**（页视觉链见证恒不翻转） |
| **② 第一处断点（缺陷②）** | **`win32_pts.c`** 内容锚 `0 /*fAllowHyphenation*/, 0 /*fClearOnLeft*/, 0 /*fClearOnRight*/,`（现取 `:2559`）＋同调用 `durLine = du = 180000`（全宽）⇒ 行断器**不知道** `Figure`/`Floater` 的矩形 |
| **③ 修** | **两方案各跑一趟真实实验，均被帧面否证**（§4）：**(甲)** 页矩形 `768×576`→`600×2000 DIP`（实验 `.so 8bdf1da66d2636e2`）⇒ **帧逐字节不变**；**(乙)** 陈旧 paraclient「丢弃并现造（仅窗内）」（实验 `.so 4d5a883d9a42fc81`）⇒ **帧仍为上一 tab 的画面、`PtsException 3→415`**。**方案（丙）＝浮动绕排 ＋ 分页视觉链**，属**具名前置**、**本增量不在写域内可做** ⇒ **判合法终点（失败）**，§4.3／§7 |
| **④ 反极性** | **可得者给出（tab1 的既有机制）**：`WPF_PTS_LINE_ABS_V=0` ⇒ 帧 `b440033da8b2a9e6 → 1a875e30e7b32b0c`、文档区 `ink 17135→9443`、`AE(content)=30276`（§4.4）。**缺陷②③的"撤修"腿不存在**（无修可撤）⇒ 具名 `NOINFO`（§7-2） |
| **⑤ 门禁** | `nm==exports`（**846==846**）｜`PTSGAP=PASS`（`so16=5e0d7b807c2fc220 exports=846`）｜`DEFREG=PASS declared=225 route_ids=225` rc=0｜`REPORTID=PASS files=355 ids=2265` rc=0（§5） |
| **⑥ 症状门（成对）** | 三条腿 `alive=yes`／`app_rc=143`（本席按 PID 收）／`[HC-UNHANDLED]` 具名（1／3／206，见 §6）／`magenta=0`／`Unrecoverable=0` |
| **⑦ 边界（未违）** | **未改仓外 hc 工程**、**未改 `upstream/**`**、**未改 `verify-all.sh`／`close-wave.sh`／`build/MilBridge/tools/**`**；**未跑整趟 `verify-all`**；**仓内仅新增本载体**（`git status` 见 §8） |

**一句话**：hc「流文档」页的**底流页签（tab1）已能画**（其**残留遮挡**＝「浮动绕排」未实现，`pfnFormatLine` 从不带 `fClearOnLeft/Right` 与浮动几何）；**分页页签（tab2／tab3）空白**的**直接断点**是 native 侧「跨窗 paraclient 代」的**具名拒发**把页格式打成 `-10000`（＋页视觉链见证恒 0）；**两趟真实实验**（页几何／陈旧句柄现造）**都改变不了帧**，说明它**不是一跳可修**，须**同时**动「分页页的窗口生命周期」与「分页视觉链」——属**具名前置**，本轮**如实判合法终点**，不假成功。

---

## §1 ① 复现（步骤 ＋ 日志路径 ＋ "确已进页"标记）

### 1.1 装置与步骤（可复算）

```bash
# 装置（自起；PID 记 ~/tb8-work/{xvfb,wm}.pid）
Xvfb :235 -screen 0 1280x1024x24 &   xfwm4 --display :235 --compositor=off &
APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0
cd "$APP"; DISPLAY=:235 HC_NO_SPLASH=1 HC_INPUT_DIAG=1 HC_GEO_EVERY=1 dotnet HandyControlDemo.dll >app.log 2>&1 &
# 进「流文档」页（左侧导航滚到底 ⇒ item 24）：装置件按 [GEO] 现取坐标点击（含"坐标稳定才点 + 拥有者核对 + [NS] 身份"三道牙）
python3 build/MilBridge/tests/PtsPagesProbe/navclick.py --log app.log --pid <PID> --display :235 \
        --out <shots> --item 24 --expect FlowDocumentDemo
# 逐 tab（按 [GEO] 现取的 TabItem 矩形点其中心，点后 2s／1s+6s 各截一张）
python3 ~/tb8-work/order.py --log app.log --pid <PID> --display :235 --out <shots> --order <序>
```

**本席两条腿的点击序**：`order` 腿 ＝ 先点 tab1 → `3,2,1`；`base` 腿 ＝ `1,2,3`（装置件 `tabs.py`）。页签现取几何（`[GEO]`，两腿逐字相同）：

```
[GEO] TabItem#- scr=268,82 wh=165x27 en=True vis=True htv=True hdr=流文档滚动视图 sel=True
[GEO] TabItem#- scr=440,82 wh=165x27 en=True vis=True htv=True hdr=流文档单页视图 sel=False
[GEO] TabItem#- scr=611,82 wh=165x27 en=True vis=True htv=True hdr=流文档查看器   sel=False
```
⇒ 点中心 `(350,95)`／`(522,95)`／`(693,95)`；点后 `sel_after` 三条**逐条翻对**（`{…单页视图 True}`／`{…查看器 True}`）⇒ **输入命中无误**（不是"点空了"）。

### 1.2 日志路径（都在仓外私有目录，非仓内）

| 腿 | 日志 | `sha16` | 字节 |
|---|---|---|---|
| `base`（`1,2,3`） | `~/tb8-work/logs/base/app.log` | `194c73d54998a1ef` | 1,864,268 |
| `order`（`3,2,1`） | `~/tb8-work/logs/order/app.log` | `ea76d3cee877c203` | 1,981,170 |
| `hook`（带起动钩子，`2,3`） | `~/tb8-work/logs/hook/app.log` | `f19507f9e1b6c83b` | 1,924,745 |
| `exp1`／`exp2`（实验件） | `~/tb8-work/logs/exp{1,2}/app.log` | `8d79543864b05b41`／`4784da73f646df08` | — |
| `pol0`（`WPF_PTS_LINE_ABS_V=0`） | `~/tb8-work/logs/pol0/app.log` | `3a64188d8451df26` | 1,441,035 |

（截图 `*.png` 与其 `sha16` 见 §2；日志体积按纪律 39 只用 `grep -c`／`wc`／`head` 读。）

### 1.3 「确已进页」标记 ＝ `[FORMATLINE-LINE]` 计数（现取）

```
base 腿：FORMATLINE_LINE_after_nav=76   （进页前 = 0；`[NS] loaded …FlowDocumentDemo` 确认页身份）
        逐 tab 后  FORMATLINE-LINE=114
order 腿：FORMATLINE_LINE_after_nav=76 ；逐 tab 后 = 114
```
⇒ **确已进页**（`[FORMATLINE-LINE]` 76 → 114），且 `[NS] loaded HandyControlDemo.UserControl.FlowDocumentDemo`（应用自报页身份）。**故"空白"不是"没进去"，是"进去了但画不出来"**。

---

## §2 逐 tab 帧面成对（`sha16` ＋ 内容区色数/像素）

**口径**：全屏 `import -window root`（`1280x1024`，窗口 `800x600@(0,0)`）；"文档区"＝ `x∈[250,795] ∧ y∈[100,600]`（脚本 `~/tb8-work/docink.py`，只读 PNG）；具名色容差 ±3。

| 面（同一装置、同一权威件 `so=5e0d7b807c2fc220`） | 帧 `sha16` | 全屏 `colors` | **文档区 `ink`** | **文档区 `colors`** | `GhostWhite`／`Beige`／`DarkGreen`／`LightGoldenrodYellow` (px) |
|---|---|---|---|---|---|
| `boot`（未进页） | `bbf01ec483127d62`／`b21eb530afd3c66c` | 388／386 | 9107 | 293 | `0／0／0／0` |
| **tab1「流文档滚动视图」** | **`b440033da8b2a9e6`** | **1078** | **17135** | **764** | **10084／924／49／5884** |
| **tab2「流文档单页视图」** | **`1fb95eab89966441`** | **551** | **1662** | **125** | **0／0／0／0** |
| **tab3「流文档查看器」** | **`0c51d1ad6fa46543`** | **562** | **1679** | **149** | `2／0／0／0` |
| `pol0` 反腿的 tab1（§4.4） | `1a875e30e7b32b0c` | 1123 | 9443 | 814 | `9952／924／49／5884` |

**逐 tab 对照（两两 `AE`，文档区）**：`AE(tab1,tab2)=58638`（order 腿）／`AE(tab1,tab3)=58638`／`AE(tab2,tab3)=3796`。
⚠️ **跑次相关（如实）**：`base` 腿里 **tab2 的帧 ＝ tab1 的帧**（`AE=0`，`sha16` 同为 `b440033da8b2a9e6`）——即"点了 tab2、`sel_after=True`、但画面**仍是上一 tab**"。`order` 腿（先 tab3 再 tab2）则给出 tab2 **自己的**空白帧（`1fb95eab…`，`colors=551`）。⇒ **复现"不切换"**：分页页的**上一帧是否被换掉**取决于跑次（旧视觉是否仍在树上），但**两条腿都证"tab2 没有自己的文档内容"**。

**截图件（`sha16`，只报路径＋哈希，不贴二进制）**：`~/tb8-work/logs/{base,order,pol0,exp1,exp2}/shots/*.png`。

---

## §3 ② 第一处断点（件:行 ＋ 原文）与归因

### 3.1 缺陷①③（分页视图 tab2／tab3 空白）—— 第一处断点

**（A）格式中止（唯一具名的失败出口）** —— `src/WpfGfx.Linux.Native/src/win32_pts.c`

```c
// 内容锚（现取 :9241-9244）：
if (!reason && dp->fsp_pl_cur && wpf_pts_handle_strict() && wpf_pts_handle_epoch_stale(dp)
    && !WPF_PTS_HANDLE_STRICT_REVERSE) {
    reason = "stale-paraclient-across-page-destroy(not-this-window-live;HandleToObject-would-FailFast)";
    g_pts_handle_stale_refused++;
}
```
现取机读行（`base` 腿）：
```
[FS_PAGE_GAP] rc=-10000 reason=stale-paraclient-across-page-destroy(not-this-window-live;HandleToObject-would-FailFast) entry=FsQueryTrackParaList ctx=… track=0x… cParas=1 owned=1 ok=11 gap=1 cur_tid=… win_tid=…     ×205
[HC-UNHANDLED] #1 PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'. ｜ 首帧 at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.Error(Int32 fserr, PtsContext ptsContext)     ×206
```
⇒ 上游 `PTS.Validate`（`PtsContext`）抛 ⇒ 页格式**中止**。**这一句是本增量之前（`T-B3`）为避免"交陈旧句柄 ⇒ `HandleToObject` 的 `Invariant.Assert` ⇒ 不可捕获 `FailFast`"而立的具名拒发**：**拒得对，但代价是分页路径整条中止**。

**（B）第二见证：分页页的视觉链见证恒不翻转** —— `[QPD]`
```
[QPD] rc=0 fskupd=2 first=1 adj=0 page=0x… page_qpd=1 vis_built=0 qpd_ok=1 qpd_gap=0 new_n=1 nc_n=0 vis_n=0 seq=6 NOINFO=fspagedetails-page-change-tracking
（base 腿：vis_built=0 ×640、vis_built=1 ×1）
```
`vis_built`（"页视觉帧真建起轨视觉"的下游见证，见 `win32_pts.c` 该字段的判据注释）**640/641 恒 0** ⇒ 分页页视觉**不建起**。

**（C）页几何（**可疑但已被实验否证**）** —— `win32_pts.c` 内容锚
`p->pg_w = WPF_PTS_FSP_FIN_DU; p->pg_h = WPF_PTS_FSP_FIN_DV;`（现取 `:8971`；`FIN_DU/DV = 768/576`）
⇒ `d->r_du = pg->pg_w; d->r_dv = pg->pg_h;`（现取 `:7277`）⇒ 托管 `PtsPage.cs` 内容锚 `_calculatedSize.Width = Math.Max(TextDpi.MinWidth, TextDpi.FromTextDpi(rect.du));`（生成件 `PtsPage.Linux.cs:787-788`）⇒ 页尺寸 **`2.56×1.92 DIP`**（`[CHAIN] site=PTSP.UpdatePageVisuals size=2.56x1.92`）。⚠️ **§4.1 的 exp1 把这条否证了**。

**归因（托管／native／装置）**：**native 侧**（`win32_pts.c`）。**不是装置**（同帧里左栏 ListBox／窗口框／tab1 的文档都画得出）；**不是托管侧作者性缺陷**（`PtsHelper`／`PtsPage`／`TextParaClient` 是上游逐字＋生成器补丁，消费逻辑与上游同形）；**不是 hc demo**（`FlowDocumentDemo.xaml` 只声明三个 `TabItem`）。**机制**：T-B3 的「句柄造出代 == 当前页销毁代」是**跨窗**判据，而**分页路径是多页生命周期**（每页 `FsCreatePageFinite`/`FsDestroyPage` 交替）⇒ 页销毁一代就把上一页造的 paraclient 判成"陈旧" ⇒ 分页期间**几乎每次填充都被拒**。

### 3.2 缺陷②（tab1 遮挡）—— 第一处断点

**（A）`pfnFormatLine` 驱动从不带浮动几何/清位** —— `win32_pts.c`

```c
// 内容锚（现取 :2554-2560）：
int rc = fl((const void *)d->p_fsclient, (const void *)cli, (const void *)leaf->nmp,
            0 /*iArea 恒 0…*/,
            dcp, (const void *)pbrin, 0u /*fswdir*/,
            0, du /*urStartLine,durLine*/, 0, du /*urStartTrack,durTrack*/,
            0 /*urPageLeftMargin*/,
            0 /*fAllowHyphenation*/, 0 /*fClearOnLeft*/, 0 /*fClearOnRight*/,
            (i == 0) ? 1 : 0 /*fTreatAsFirstInPara*/, 0 /*fTreatAsLastInPara*/,
            0 /*fSuppressTopSpace*/, …);
```
⇒ 每一行都以**全宽 `du=180000`（600 DIP）**、`fClearOnLeft=0`／`fClearOnRight=0` 驱动 ⇒ **行断器不知道 `Figure`/`Floater` 的矩形**。**归因＝native 侧**（浮动绕排未实现，与 `T-B4` §2.6「丙」同判；`NOINFO=float-avoidance-not-implemented`）。

**（B）几何证据（像素级，现取）** —— `~/tb8-work/overlap.py`（只读 PNG）

| 对象 | 像素盒 | 与正文行带的关系（正文列 `x∈[300,420]` 现取的 15 条文本行带） |
|---|---|---|
| `Figure`（`Beige` 底） | `bbox=(422,160,747,180)`，`924 px` | **与 2 条正文行带共 y**（`[147,174]`／`[176,187]`），相交 **40 像素行** |
| `Floater` 表（`LightGoldenrodYellow`） | `bbox=(430,164,747,234)`，`5884 px` | **与 5 条正文行带共 y**（`[176,187]…[234,261]`），相交 **77 像素行** |
| `DarkGreen`（Figure 内文字） | `bbox=(428,163,516,171)`，`49 px` | 同 Figure 盒 |

⇒ **可见遮挡＝浮动盒（图/表）与正文行带共 y**；且 `pol0` 反腿（§4.4）里两盒 `bbox` **逐像素不变** ⇒ 该遮挡**与 T-B4 的段落 v 机制无关**，是另一条机制。

---

## §4 ③ 修（三方案；甲乙已真跑并被否证，丙具名前置）

### 4.1 方案（甲）· 分页页矩形 —— 实验件 `8bdf1da66d2636e2` ⇒ **被帧面否证**

只改 `win32_pts.c:8971` 的一行（副本先行，scratch `~/tb8-work/exp1`，**仓内零写**）：
```
p->pg_w = WPF_PTS_FSP_FIN_DU; p->pg_h = WPF_PTS_FSP_FIN_DV;   →   p->pg_w = 180000; p->pg_h = 600000;
```
同一装置、同一腿（`order 2,3`）现取：
```
[CHAIN] site=PTSP.UpdatePageVisuals size=2.56x1.92   →   [CHAIN] site=PTSP.UpdatePageVisuals size=600x2000
帧：tab2 = 1fb95eab89966441（colors=551）   tab3 = 0c51d1ad6fa46543（colors=562）   ← 与权威件**逐字节相同**
```
⇒ **页尺寸从 `2.56×1.92 DIP` 改到 `600×2000 DIP`，帧一个字节没变** ⇒ **页几何不是分页视图空白的断点**（该候选**被否证**）。

### 4.2 方案（乙）· 陈旧 paraclient「丢弃并现造（仅窗内）」 —— 实验件 `4d5a883d9a42fc81` ⇒ **被帧面否证**

在 `win32_pts.c` 的「③ 配额到点 ⇒ 换代」**之前**插入（副本 `~/tb8-work/exp2`；**仓内零写**）：
```c
/* T-B8 实验2：陈旧代（epoch != page_destroy_n）⇒ 丢弃并现造（仅窗内） */
if (!reason && dp->fsp_pl_cur && wpf_pts_handle_strict()
    && wpf_pts_handle_epoch_stale(dp) && wpf_pts_qtp_create_safe(dp)) {
    dp->fsp_pl_cur = NULL; dp->fsp_pl_quota = 0; g_pts_handle_stale_refused++;
}
```
现取：
```
tab2 帧 = b440033da8b2a9e6（＝**tab1 的画面**，colors=1078）   tab3 帧 = 0c51d1ad6fa46543（不变）
PtsException 3 → **415**；alive=yes／app_rc=143／Unrecoverable=0（未 FailFast）
```
⇒ **既没让分页页出现自己的内容、（异常面反而涨）** ⇒ **该候选也被否证**（且**未**把"陈旧句柄"重新交出去 ⇒ 未复发 `FailFast`）。**两个单变量实验一起说明**：分页空白**不是一跳可修**。

### 4.3 方案（丙）· 真正的两条前置（**本增量不在写域内可做**）—— 具名前置

1. `PRECOND-FINITE-PAGE-WINDOW-LIFECYCLE`：分页路径**多页生命周期**下，使每个页窗**自持**一份合法 paraclient（现模型是"跨调用缓存 + 页销毁代收严"）—— 这要**重做 `FsQueryTrackParaList` 的句柄代模型**，且必须**不动** T-B3 的 `FailFast` 防护（`App_rc=134` 是硬的：`PtsContext.HandleToObject` 的 `Invariant.Assert` **不可捕获**）。
2. `PRECOND-FINITE-PAGE-VISUAL-CHAIN`：分页页视觉链见证 `[QPD] vis_built` **恒 0** ⇒ 即使格式过，页视觉仍可能不建起（`PtsPage.UpdatePageVisuals` → `UpdateTrackVisuals` 那一支）。
3. （缺陷②）`PRECOND-FLOAT-AVOIDANCE`：`pfnFormatLine` 要**知道浮动盒几何**并按行传 `fClearOnLeft/Right`／收窄 `durLine`（`T-B4` §2.6「丙」同判）。

⇒ 三条都要动**分页/浮动的窗口与视觉链**（面大、且**极易**把已工作的 tab1 与 `FailFast` 防护打坏）⇒ **本轮判合法终点（失败）**，**不假成功**。

### 4.4 反极性（**可得者给足**：tab1 的既有机制）

同一权威件（`so=5e0d7b807c2fc220`），只差 `WPF_PTS_LINE_ABS_V=0`：

| 腿 | 帧 `sha16` | 全屏 `colors` | 文档区 `ink` | 文档区文本行带 |
|---|---|---|---|---|
| 正腿（缺省，闸=1） | `b440033da8b2a9e6` | 1078 | 17135 | 15 条（`[147,174]…[409,436]`） |
| **反腿**（`WPF_PTS_LINE_ABS_V=0`） | **`1a875e30e7b32b0c`** | 1123 | **9443** | **5 条**（`[147,174]…[234,261]`，段间行带合并） |

⇒ `AE(content)=30276`、`ink 17135→9443`、行带 `15→5` ⇒ **同一份件、只差一个 env，帧面双向成立**；且两腿的 `Figure`/`Floater` 盒 `bbox` **逐像素相同**（`(422,160,747,180)`／`(430,164,747,234)`）⇒ 缺陷②**独立于**该机制。
**缺陷①③无"撤修"腿**（无修可撤）⇒ 记 `NOINFO(reason=no-fix-to-revert)`（§7-2）。

---

## §5 门禁（逐条现取，本席跑的）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only …/libwpfwin32.so` vs `bin/exports.txt` | **846 == 846**，`diff -q` 空 |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5e0d7b807c2fc220 exports=846`**；`PTSGAP_FRONTIER_STATE=NAMED` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0 keys=-`，**rc=0** |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=355 ids=2265 declared=225`**，rc=0（本载体落地**前**现取）；**本载体落地后**现取 ＝ **`files=356 ids=2265 declared=225`**，rc=0（＋1 ＝ 本件） |

（**本增量仓内零产品件改动** ⇒ 上述四牙的读数即 `HEAD=330f9b7` 的在册值，**不是**"改后复取"。）

---

## §6 ④ 症状门（成对）

| 症状门 | 权威件（缺省） | `pol0` 反腿 | 说明 |
|---|---|---|---|
| `alive` | `yes` | `yes` | 本席按 PID 收（`rc=143`） |
| `app_rc` | `143` | `143` | ＝本席 `kill`，非应用自退 |
| `magenta`（页级占位） | `0` | `0` | 无"不支持"占位 |
| `Unrecoverable system error` | `0` | `0` | **无 `FailFast`** |
| `[HC-UNHANDLED]` | `base=206`／`order=3`／`hook=3` | `1` | **全部**为 `PtsException('-10000')`（`grep` 现取：`PtsException` 与 `did not complete formatting operation` 同数）**被应用侧守护接住**（`alive=yes`） |
| `colors`（全屏） | `boot=386／tab1=1078／tab2=551／tab3=562` | tab1 `1123` | 见 §2 |
| `[FORMATLINE-LINE]` | `76`（进页）→`114`（逐 tab） | `76` | "确已进页"标记 |

⚠️ **口径（如实）**：本报告**不**用"`FailFast` 字样计数"当症状门（`grep -c FailFast` 会把**守护接住的异常栈帧**也数进去，`base` 腿的 `205` 即此族）——**唯一可信的"没死"读数是 `Unrecoverable=0 ∧ alive=yes`**。

---

## §7 具名 `NOINFO` / 前置 / 边界（如实划界）

1. **`NOINFO(reason=缺陷①③未修，无"撤修"腿可给反极性)`**：三条中缺陷①③**没有落地修法** ⇒ 其"反极性（撤修⇒回原状）"**不存在**；已给的成对读数是"**同件三次独立跑**的形态稳定"与"**两趟实验件 vs 权威件**帧逐字节相同"（§4.1／§4.2）。
2. **`NOINFO(reason=tab2 帧跑次相关)`**：`base` 腿 tab2 ＝ tab1 帧（`AE=0`）、`order`／`hook`／`exp` 腿 tab2 ＝ 自己的空白帧（`1fb95eab…`）——两形态都证"tab2 无自己的文档内容"，但"旧视觉是否被换掉"**跑次相关**（旧视觉是否仍在树上），本席**未**把该机制读穿（须渲染侧"旧子树是否摘除"的读数）。
3. **`NOINFO(reason=分页视觉链 640/641 vis_built=0 的机制)`**：只读到"见证恒 0"，**未**定位到 `UpdateTrackVisuals` 为何不建起（须渲染面插桩）。
4. **具名前置（本增量写域外／面过大，不在本轮做）**：`PRECOND-FINITE-PAGE-WINDOW-LIFECYCLE`／`PRECOND-FINITE-PAGE-VISUAL-CHAIN`／`PRECOND-FLOAT-AVOIDANCE`（§4.3）。
5. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑整趟 `verify-all`**、**未构建仓内产品件**（两趟实验都在 `~/tb8-work/exp*` 的 scratch 里编）。
6. **副本先行／写前备份**：本增量**仓内零产品件改写** ⇒ 无需备份；app-local 五件在实验腿后被 `sync-applocal.sh` **逐件复原**（`SYNC-APPLOCAL=PASS items=5 ok=5 drift=0`，现取 `libwpfwin32.so=5e0d7b807c2fc220`）。
7. **`app-local` 逐件一致（任务点名的硬边界）**：现取 `sync-applocal.sh --check` ⇒ `items=5 ok=5 drift=0`；且**非五件**逐件现取版本（`verprobe`）：`PresentationUI`／`ReachFramework`／`System.Printing`／`UIAutomation{Provider,Types}`／`DirectWriteForwarder`／`System.Windows.Input.Manipulations`／`PresentationFramework.Classic`／PF／PC／WB／System.Xaml **全部 `4.0.0.1`**（**无 `10.0.0.0` 残留件**；`System.Windows.Extensions=9.0.0.0`＝替身身份，预期）⇒ 三缺陷**不是** app-local 身份错造成。

---

## §8 边界 · 收净 · 自证

- **写域**：**仓内仅新增本载体** `build/MilBridge/P1-hcflowdoc-impl-report.md`。`git status --porcelain` 现取：
  ```
  ?? build/MilBridge/tasks-tail2/T-B8.md      （主控派单件，非本席所建）
  ?? build/MilBridge/P1-hcflowdoc-impl-report.md （本载体）
  ```
- **仓外私有件（不在仓内）**：`~/tb8-work/{leg.sh,tabs.py,order.py,analyze.py,overlap.py,docink.py,hook2/,exp1/,exp2/,logs/}` 与两份实验 `.so`（`exp1=8bdf1da66d2636e2`／`exp2=4d5a883d9a42fc81`）。
- **进程/显示收净**：`:235` 的 `Xvfb`（`~/tb8-work/xvfb.pid`）与 `xfwm4`（`~/tb8-work/wm.pid`）**按 PID 收净**；所有 `HandyControlDemo` 进程按 PID 收（`app_rc=143` 即本席所杀）；`/tmp/.X11-unix/` 现取只剩 `X0/X1/X11`（非本席）。
- **纪律自证**：重活走 `~/heavy-slot.sh`（`--min-avail 2500 --max-hold 900 --wait 900`）；显示位只用空闲 `:235`；`temp+rename`（本载体）；**报数一律现取**（纪律 40）。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hcflowdoc-impl-report.md | sha256sum | cut -c1-16`）＝ **`472727eb43801159`**（本行下方无内容，取该行之前全文的哈希）。

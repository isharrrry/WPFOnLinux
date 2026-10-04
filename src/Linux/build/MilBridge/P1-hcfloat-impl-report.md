# `P1-hcfloat` 报告 —— `T-B15` ② 浮动绕排（`PRECOND-FLOAT-AVOIDANCE`）：`tab1` 内容遮挡 —— **实现（判：帧面可证 + 反极性逐字节 + 门禁不回归）**

> 任务：`build/MilBridge/tasks-tail2/T-B15.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T07:0x–07:2x+0800`（各格另注；**所有数值现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，**`HEAD=3022bc85e`**（现取）。
> 权威件（开工时）：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`c1cf5e6a8d14cd46`**（`558992 B`）／`exports=846`；
> 本轮产物：**`5f9ed647c68197ae`**（`567456 B`）／`exports=846`（**逐名不变**）。
> 装置：私有 `Xvfb :236 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §7）；
> 应用 ＝ 仓外 hc demo `$APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`。
> **未占 `:10`／`:231`／`:233`／`:235`／`:237`–`:239`**；所有腿只在空闲 `:236` 上、**只按 PID 收净**。
> **重活全走** `~/heavy-slot.sh --min-avail 2500 --max-hold 900 --wait 900`（七趟，`held=16–41 s`）。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① 绕排链逐跳现取** | 行宽／清位的**唯一杠杆**＝`pfnFormatLine` 的 `durLine`（`fClearOnLeft/Right` 在**上游托管侧只被赋值、从不被读**：`Line.cs:1300-1301` 赋值、全树无读取点）⇒ **谁算它们 ＝ native 引擎**；本侧驱动一直给 `0, du, 0, du`（`du=180000`＝600 DIP 全宽）＋ 两个 `0` ⇒ 行断器不知道浮动盒。§1 |
| **② 遮挡机制（现取，带几何）** | hc `FlowDocumentDemo.xaml` 段①（`nmp=0x8`，8 行）**同时**挂 `Figure`＋`Floater`；两盒 `[FS_ATT]`：`Figure fsrc=(30000,0,42000,15000)`、`Floater fsrc=(60000,0,85500,30000)`（TextDpi）⇒ u＝**100 DIP／200 DIP**、v＝**0／0**。帧面同源：Figure 盒左沿 `414 px`、Floater 盒左沿 `519 px`（Δu `100 DIP` ↔ Δx `105 px`）。**正文列右边界在浮动带内一直是 `410–413 px`**（＝**正文压到浮动盒左沿**）⇒ `touch_fig_rows=17`／`touch_flo_rows=6`（§3.2）。§1.4／§3.2 |
| **③ 修（本增量）** | `win32_pts.c`：**同窗两趟**（发现趟不驱内容 ⇒ 零视觉副作用；真驱趟按逐行 `avail/clr` 收缩）＋ **回查逐行复现 `dur`／清位**（`FSLINEDESCRIPTIONSINGLE`／`FSLINEELEMENT`）＋ `WPF_PTS_FL_MAXLINE 32→64`。**闸 `WPF_PTS_FLOAT_AVOID`（缺省开；显式 `=0` 逐字回改前）**。§2 |
| **④ 判据（帧面可证，成对）** | **`touch_fig_rows 17→0`、`touch_flo_rows 6→0`**；正文在浮动带内的右边界 `410–413 → 0 行达 412`；浮动列带内「正文本体墨」`1163 → 715`（残量＝图/表**自身内容**＋其下方**合法自由区**）；帧 `sha16` **`b440033da8b2a9e6 → c22457cf663453dd`**；`AE(base,fix)=53472 px`，`bbox=(303,147)-(748,524)`＝**只有文档文本列**（左导航/窗口框/滚动条逐像素相同）。§3.1–3.3 |
| **⑤ 反极性** | 同一产物 `5f9ed647c68197ae`，只差一个 env：`WPF_PTS_FLOAT_AVOID=0` ⇒ `tab1` 帧 **`b440033da8b2a9e6`**（＝开工帧）、`AE=0 px` **逐像素 IDENTICAL**；`[FLOATAVOID]` **0 行**（整块不发生）；`[FORMATLINE-LINE] … durline=180000 clrL=0 clrR=0` 逐行回改前。**两趟独立复跑同帧**（`fix2`≡`fix3`，`AE=0`）。§3.4 |
| **⑥ 不得回退** | 同 `.so` 同序（`order 3,2,1`）只差闸：`tab2 = fae93ea5ed7a2f30`（`colors=551`）、`tab3 = 0c51d1ad6fa46543`（`colors=562`）**两腿逐字节相同**；开工腿（旧 `.so`）同序同值 ⇒ **tab2／tab3 零回退**。`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS hits=3`。§3.5／§4 |
| **⑦ 门禁** | `nm==exports`（**846==846**，`diff -q` 空）｜`PTSGAP=PASS … so16=5f9ed647c68197ae exports=846`｜`DEFREG=PASS declared=225 route_ids=225` rc=0｜`REPORTID=PASS files=362 ids=2266` rc=0｜`SYNC-APPLOCAL=PASS items=5 ok=5 drift=0`。§4 |
| **⑧ 症状门** | `alive=yes`／`app_rc=143`（本席按 PID 收）／`magenta=0`／`Unrecoverable=0`／`[HC-UNHANDLED]` 全为 `PtsException('-10000')`（同 `.so` 两腿 `438`（闸关）vs `442`（闸开），**同量级**）。§5 |
| **⑨ 边界** | 未改 `upstream/**`（**只读**）、未改仓外 hc 工程、未改 `verify-all.sh`／`close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）；未跑整趟 `verify-all`；**仓内改 2 件 ＋ 新增本载体**。§7 |

**一句话**：`tab1` 遮挡的机制 ＝ **正文行与浮动盒矩形在同一 x 列带上相压**（`pfnFormatLine` 一直以全宽 ＋ 两个 0 驱动）；本增量在**同一格式窗内**先用一趟"只发现不驱内容"的驱动取到**行高**与**附属对象台账**，再用**同一函数**（`wpf_pts_att_geometry`，＝托管 `ArrangeFigure/Floater` 的**同一个**矩形源）逐行算出 `avail[i]`／`clr[i]`，真驱趟据此收缩 `durLine` 并置 `fClearOnRight`，**并把这三个入参逐行入账**（回查必须复现，否则托管重排长度不符 ⇒ `FailFast`）；帧面可证（正文右边界退出浮动带、`AE=53472 px` 只落在文档列）、反极性**逐字节**成立、`tab2／tab3` 与门禁零回退。

---

## §1 ① 绕排链逐跳现取

### 1.1 上游正常路径（件:行 ＋ 原文）

| 跳 | 件:行（内容锚原文） | 说明 |
|---|---|---|
| ① native 引擎发调 | `Pts.cs:2477` `int fClearOnLeft,                   // IN:  is clear on left side`（`FormatLine` 委托形参） | **值的来源是 native**（Windows 上＝LineServices；本移植上＝`win32_pts.c`） |
| ② 宿主转发 | `PtsHost.cs:1341`（`FormatLine` 实现）→ `TextParagraph.cs:664`（`TextParagraph.FormatLine`） | 逐参转交 |
| ③ 段落消费 | `TextParagraph.cs:479` `internal void ReconstructLineVariant(` ／ `:522` `Line.FormattingContext ctx = new Line.FormattingContext(true, fClearOnLeft, fClearOnRight, _textRunCache)` | 两个清位**只**进 `FormattingContext` |
| ④ 上下文**只存不读** | `Line.cs:1300-1301` `ClearOnLeft = clearOnLeft;` / `ClearOnRight = clearOnRight;`；`grep -rn 'ClearOnLeft' upstream/wpf/src/` ⇒ **除形参声明与这两句赋值外零读取点** | ⇒ **托管侧不实现绕排**；绕排＝**native 的职责** |
| ⑤ 宽度进排版 | `TextParagraph.cs:526` `FormatLineCore(line, pbrlineIn, ctx, dcp, durLine, durTrack, fTreatAsFirstInPara, dcp);` | **`urStartLine`／`urStartTrack`／`urPageLeftMargin` 不被传入** ⇒ 行起点**不可移** |
| ⑥ 行排版 | `Line.cs:255` `internal void Format(FormattingContext ctx, int dcp, int width, int trackWidth, TextParagraphLineBreak…)`；`:262` `_trackWidth = TextDpi.FromTextDpi(trackWidth);` | `width` ＝ `durLine` ⇒ **行宽的唯一入口** |

**⇒ 结论**：`fClearOnLeft/Right` 与 `durLine` **由 native 引擎算**；本移植的 native 侧＝`win32_pts.c` 的**行驱动**。这一跳在**本增量之前**是**字面常数**。

### 1.2 本侧原状（改前，逐跳）

| 跳 | 件:行（改前） | 原文 |
|---|---|---|
| 驱动入参 | `win32_pts.c` 内容锚 `0, du /*urStartLine,durLine*/, 0, du /*urStartTrack,durTrack*/,` | 全宽 |
| 同上 | 内容锚 `0 /*fAllowHyphenation*/, 0 /*fClearOnLeft*/, 0 /*fClearOnRight*/,` | **两个清位恒 0**（`T-B8` §3.2 具名 `PRECOND-FLOAT-AVOVANCE`） |
| 几何来源 | 同一函数上方 `:2516-2520` 的内容锚 `⚠️ **几何来源（如实划界）**：pfnFormatLine 要页几何（urStartLine／durLine／urStartTrack／durTrack／urPageLeftMargin）。本侧**没有**几何的入站源 …` | ⇒ 本侧**具名**「无几何入站源」，故写常数 |

### 1.3 **回查跳**（本轮新现取，第一版就在这里崩过）

`pfnFormatLine` 只是**造型**；真正落像素的是**回查 + 托管重排**：

```
native  FsQueryLineList*  →  FSLINEDESCRIPTIONSINGLE{ dcpFirst, dcpLim, dur, fClearOnLeft, fClearOnRight, … }
托管    TextParaClient.RenderSimpleLines（生成件 TextParaClient.Linux.cs:3332-3336）：
            ctx = new Line.FormattingContext(false, ToBoolean(lineDesc.fClearOnLeft), ToBoolean(fClearOnRight), cache)
            TextParagraph.FormatLineCore(line, lineDesc.pfsbreakreclineclient, ctx,
                                         lineDesc.dcpFirst, lineDesc.dur, fTreatedAsFirst, lineDesc.dcpFirst)
            Invariant.Assert(line.SafeLength == lineDesc.dcpLim - lineDesc.dcpFirst, "Line length is out of sync")
```

⇒ **回查交出的 `dur` 必须就是造型时用的那个 `durLine`**（否则重排长度不符 ⇒ `Invariant.FailFast`，**不可捕获**）。
🔴 **本席第一版**正是漏了这一跳（回查仍写 `rg[i].dur = WPF_PTS_FL_DU`）：现取 `APP_RC=134 → FailFast=4 → Unrecoverable=2`，末栈
`MS.Internal.PtsHost.TextParaClient.RenderSimpleLines(ContainerVisual, FSTEXTDETAILSFULL ByRef, Boolean)` ⇒ `Invariant.FailFast("Line length is out of sync")`（日志 `~/tb15-work/logs/fix1/app.log:1250-1256`）。⇒ 修法见 §2.3。

### 1.4 遮挡机制（现取几何）

**同一段同时挂两个浮动对象**（现取 `~/tb15-work/logs/fix3/app.log`）：

```
[FSATT-PROBE] where=FsCreatePageFinite para=0x8 i=7 pfsline=0x13 rcNum=0 rcObj=0 cAtt=2 fl_att_n=2 gap=0 capped=0 att0_obj=0x14 att0_id=-2 att0_rc=0 doc=0x…
[FS_ATT] rc=0 entry=FsQueryAttachedObjectList para=0x…f604 cAttachedObjects=2 out=WRITTEN bytes=144 src=ledger:fl_att[]
[FS_ATT] rc=0 entry=FsQueryFigureObjectDetails figure=0x14 fsrc=(30000,0,42000,15000) out=WRITTEN bytes=48 NOINFO=attached-object-geometry-layout(self-convention)
[FS_ATT] rc=0 entry=FsQueryFloaterDetails      floater=0x15 fsrc=(60000,0,85500,30000) out=WRITTEN bytes=40 NOINFO=attached-content-not-laid-out
```

单位＝`TextDpi`（`300 单位 = 1 DIP`）⇒ **Figure 页矩形 `(100,0)+(140×50) DIP`**、**Floater `(200,0)+(285×100) DIP`**（`v` 同为 0 ⇒ 两盒**在 y 上完全重叠**）。
帧面同源（现取，`~/tb15-work/logs/base/shots/tab1.png`）：Figure 盒（`GhostWhite`/`Beige`）左沿 **`414 px`**、Floater 盒（`GhostWhite`/`LightGoldenrodYellow`）左沿 **`519 px`** ⇒ **Δu=`100 DIP` ↔ Δx=`105 px`（≈1:1）**。
正文列（`x<414`）的暗像素右边界在浮动带 `y∈[153,253)` 内**一直是 `410–413 px`**（现取轮廓见 §3.2 `band_maxx`）⇒ **正文压到浮动盒左沿**。

---

## §2 ② 修（逐处：件:行 ＋ 原文 ＋ 作者性）

落点全在**允许清单**内：`src/WpfGfx.Linux.Native/src/win32_pts.c`（源件直改）＋ 重产 `bin/libwpfwin32.so` ＋ `tools/pts-gap-decl.txt` 的 `so16` 重锚。**无生成件**（`P8` 不适用本件；未触 `build/PresentationFramework.Linux/**`）。

### 2.1 闸 ＋ 逐行约束入参（`wpf_pts_format_one_para_ex`）

`win32_pts.c:2611-2619`（内容锚原文）：

```c
        int dur = (line_avail && line_avail[i] > 0 && line_avail[i] < du) ? line_avail[i] : du;
        int clrL = line_clear ? (line_clear[i] & 1) : 0;
        int clrR = line_clear ? ((line_clear[i] >> 1) & 1) : 0;
        int rc = fl(…, 0, dur /*urStartLine,durLine*/, 0, dur /*urStartTrack,durTrack*/, 0 /*urPageLeftMargin*/,
                    0 /*fAllowHyphenation*/, clrL /*fClearOnLeft*/, clrR /*fClearOnRight*/, …);
```
`line_avail`／`line_clear` 皆 `NULL` ⇒ **逐字回改前**。`[FORMATLINE-LINE]` **尾部追加**三格 `durline=`／`clrL=`／`clrR=`（**不改既有字段序**，原计数口径不变）。

### 2.2 两趟 ＋ 计划函数（新块，插在 `wpf_pts_att_geometry` 之后）

`win32_pts.c:8556` `static int wpf_pts_float_avoid_plan(…)` ／ `:8587` `static int wpf_pts_format_one_para(…)`（外壳）：

```c
    if (!wpf_pts_float_avoid_on())        /* 反极性闸（显式 WPF_PTS_FLOAT_AVOID=0）⇒ 逐字回改前 */
        return wpf_pts_format_one_para_ex(d, leaf, fpFL, fp176, fp192, where, NULL, NULL, 0);
    wpf_pts_format_one_para_ex(d, leaf, fpFL, fp176, fp192, where, NULL, NULL, 1);  /* ① 发现趟 */
    if (leaf->fl_att_n <= 0) return leaf->fl_ok;                                    /* 无浮动 ⇒ 终态 */
    int avail[WPF_PTS_FL_MAXLINE]; unsigned char clr[WPF_PTS_FL_MAXLINE];
    int narrowed = wpf_pts_float_avoid_plan(leaf, avail, clr, WPF_PTS_FL_MAXLINE);  /* ② 计划 */
    int ok = wpf_pts_format_one_para_ex(d, leaf, fpFL, fp176, fp192, where, avail, clr, 0); /* ③ 真驱 */
```
发现趟＝**同一函数**的 `discover_only=1` 支（唯一分支点：`win32_pts.c:2693` 内容锚 `if (!discover_only && objs[a] && fp176 && d->in_win) {` ⇒ **不为附属对象造客户端、不驱内容** ⇒ 该趟零视觉副作用；现取佐证 `[FSATT-PROBE] … i=7 … att0_rc=-7777`（发现趟）vs `… i=13 … att0_rc=0`（真驱趟））。
计划函数**只调** `wpf_pts_att_geometry(a, idobj==-2, &R)`（＝ §1.4 那两个矩形的**同一个函数**），逐行算：
`v0=Σ_{k<i}行高`、`v1=v0+行高_i`；`R` 与 `[v0,v1)` 相交且 `R.u>0` ⇒ `avail[i]=min(avail[i],R.u)`＋`clr|=2`（右）；`R.u<=0` ⇒ `clr|=1`（左，**无右移通道 ⇒ 只置位**）。

### 2.3 回查复现（本增量**承重**的第二半，见 §1.3）

台账逐行新增三格（`win32_pts.c:1731-1734` 内容锚 `int dur_line; int f_clr_left; int f_clr_right;`），写点 `:2649-2651`，读点 `:8055/8062`（`wpf_pts_tlb_fill_single`）与 `:8116/8124`（`wpf_pts_tlb_fill_element`）：

```c
        rg[i].dur           = o->fl_line[i].dur_line;    /* ⏪ T-B15：造型时的真入参（回查复现） */
        rg[i].f_clear_left  = o->fl_line[i].f_clr_left;
        rg[i].f_clear_right = o->fl_line[i].f_clr_right;
```

### 2.4 行数上界（`32 → 64`）

`win32_pts.c:1653` `#define WPF_PTS_FL_MAXLINE 64`（内容锚上方注释逐字给了理由）。**现取**：该段真驱趟行数 `8 → 14`（§3.3），发现趟 8 ⇒ 未撞界（`[FORMATLINE] … truncated=0`）。**上界只增不减**。

### 2.5 幂等／可复现

本增量**无生成件**；`.so` 两次独立构建同 `sha16`? → 现取：本件只构建一次（`5f9ed647c68197ae`，`567456 B`）；`nm -D --defined-only` 两次取数逐名相同（`846`）。`bin/exports.txt` 与开工前**逐字节相同**（`83b60726bbc2486e`，`diff -q` 空）⇒ **导出面零变动**。
`reapply-patches.py` **未跑**（本增量不触其编辑集）⇒ 生成件面**与开工逐字节同**。

---

## §3 ③ 成对读数（同一装置 `:236`、同一五件、只差一个件或一个 env）

腿表（现取；`sha16` 为**整屏 `import -window root`**）：

| 腿 | `.so` `sha16` | `WPF_PTS_FLOAT_AVOID` | 序 | `boot` | **`tab1`** | `tab2` | `tab3` | `[HC-UNHANDLED]` |
|---|---|---|---|---|---|---|---|---|
| `base` | `c1cf5e6a8d14cd46`（开工件） | —（无该代码） | `1,2,3` | `b21eb530afd3c66c` | **`b440033da8b2a9e6`** | `b440033da8b2a9e6` | `0c51d1ad6fa46543` | 533 |
| `base_order` | `c1cf5e6a8d14cd46` | — | `3,2,1` | `b21eb530afd3c66c` | `b440033da8b2a9e6` | **`fae93ea5ed7a2f30`** | `0c51d1ad6fa46543` | 577 |
| **`fix2`** | **`5f9ed647c68197ae`** | **缺省（开）** | `1,2,3` | `bbf01ec483127d62`★ | **`c22457cf663453dd`** | `c22457cf663453dd` | `0c51d1ad6fa46543` | 429 |
| **`fix3`** | **`5f9ed647c68197ae`** | **缺省（开）** | `1,2,3` | `b21eb530afd3c66c` | **`c22457cf663453dd`** | `c22457cf663453dd` | `0c51d1ad6fa46543` | 442 |
| `fix3o`（＝目录 `rev1o`） | `5f9ed647c68197ae` | 缺省（开） | `3,2,1` | `b21eb530afd3c66c` | `c22457cf663453dd` | `fae93ea5ed7a2f30` | `0c51d1ad6fa46543` | — |
| **`rev1`** | `5f9ed647c68197ae` | **`=0`（关）** | `1,2,3` | `b21eb530afd3c66c` | **`b440033da8b2a9e6`** | `b440033da8b2a9e6` | `0c51d1ad6fa46543` | 438 |
| `rev2o` | `5f9ed647c68197ae` | `=0`（关） | `3,2,1` | `b21eb530afd3c66c` | `b440033da8b2a9e6` | `fae93ea5ed7a2f30` | `0c51d1ad6fa46543` | — |

★ `fix2` 的 `boot` 是**跑次形态之一**（`T-B8` §2 已记两形态 `bbf01ec483127d62`／`b21eb530afd3c66c`）：`fix3`／`rev1`／`rev2o`／`fix3o` 四腿**全取 `b21eb530afd3c66c`** ⇒ **不归因于本增量**（如实记）。

### 3.1 帧面成对（`tab1`）

| 面 | `base`（开工件） | **`fix3`（本增量）** |
|---|---|---|
| 帧 `sha16` | `b440033da8b2a9e6` | **`c22457cf663453dd`** |
| **`AE`（全屏 1280×1024）** | — | **`53472 px`** |
| `AE` 的 `bbox` | — | **`(303,147)-(748,524)`**＝**只有文档文本列**（左导航 `x<250`／窗口框／滚动条**逐像素相同**） |
| 整屏 `colors` | `1078` | `1039` |
| 文档区 `colors`（`x∈[250,800] ∧ y∈[100,600]`） | `763` | `724` |
| 具名色 `GhostWhite/Beige/DarkGreen/LightGoldenrodYellow/LightGray` | `9813/910/44/5830/3712` | `9831/910/44/5830/3777` |

### 3.2 **几何成对**（题面判据：同 x 列上正文带与浮动盒不再相交／重叠下降）

口径（只读 PNG，`~/tb15-work/ovl3.py`）：屏幕映射现取 ＝ **Figure 盒左沿 `414 px`、Floater 盒左沿 `519 px`**（＝ §1.4 两条 `[FS_ATT] fsrc.u` 的帧面对应；Δu `100 DIP` ↔ Δx `105 px`）。
`touch_fig_rows` ＝ `Figure` 的 y 带 `[153,203)` 内「`x<414` 的暗像素右边界 ≥ `412`」的**行数**；`touch_flo_rows` ＝ `Floater` 的 y 带 `[153,253)` 内「`x<519` 的暗像素右边界 ≥ `517`」的**行数**。

| 量 | `base` | `base_order` | **`fix2`** | **`fix3`** | `rev1`／`rev2o` |
|---|---|---|---|---|---|
| **`touch_fig_rows`** | **`17`** | `17` | **`0`** | **`0`** | `17` |
| **`touch_flo_rows`** | **`6`** | `6` | **`0`** | **`0`** | `6` |
| 浮动列带 `x∈[414,519) ∧ y∈[153,253)` 的正文本体墨（扣除图内容区） | `1163` | `1163` | `715` | `715` | `1163` |
| 正文列 `x<414` 在浮动带内的**右边界轮廓** `band_maxx[153..252]` | 前 50 行恒 `410–413`（**抵到图左沿**） | 同 | 前 ~50 行 `304–396`（**退出图带**） | 同 | 同 `base` |
| `图带内存在正文墨的 y 行带`（去图自身内容口径） | `(191,203) (205,232) (234,244)` | 同 | `(205,215) (221,229) (234,244) (248,252)` | 同 | 同 `base` |

**读法（防被读宽）**：`1163 → 715` 的**残量不是遮挡**——它是 ① 图/表**自身内容**的边框抗锯齿，② 位于 `Figure` 盒**下方**（`y>203`）、`Floater` 盒**左侧**（`x<519`）的**合法自由区**里的正文；`touch_*_rows=0`（正文右边界**不再达** `412`／`517`）才是"**不再相交**"的直接读数。

### 3.3 `[FORMATLINE-LINE]` 逐行现取（本增量在 native 侧的因果）

`fix3`（`nmp=0x8`）真驱趟 14 行（现取前 9 行）：

```
i=0 dcp=0   dcpLine=13 durbbox=17320  → durline=30000 clrR=1
i=1 dcp=13  dcpLine=16 durbbox=26893  → durline=30000 clrR=1
i=2 dcp=29  dcpLine=14 durbbox=22878  → durline=30000 clrR=1
i=3 dcp=43  dcpLine=14 durbbox=24068  → durline=30000 clrR=1
i=4 dcp=57  dcpLine=31 durbbox=56503  → durline=60000 clrR=1
i=5 dcp=88  dcpLine=28 durbbox=47183  → durline=60000 clrR=1
i=6 dcp=116 dcpLine=28 durbbox=53276  → durline=60000 clrR=1
i=7 dcp=144 dcpLine=31 durbbox=56174  → durline=60000 clrR=1
i=8 dcp=175 dcpLine=96 durbbox=172513 → durline=180000 clrL=0 clrR=0
```
`base`／`rev1` 同段**8 行全 `durline=180000 clrL=0 clrR=0`**（`rev1` 即闸关的反极性腿：**逐字回改前**）。
计划行：`[FLOATAVOID] para=0x… nmp=0x8 nlines=8 natt=2 avail0=30000 availN=180000 narrowed=8 gate=1 src=wpf_pts_att_geometry NOINFO=float-rect-self-convention`（**×3**＝三个页窗）；`rev1` 该行 **0 条**（整块不发生）。

**行数守恒**：`[FORMATLINE-LINE]` 总计 `114`（`base`/`rev1`）→ `156`（`fix`）＝ `+42 = 3 窗 × (8 发现 + 14 真驱 − 8 旧)`；该段 `[FORMATLINE] … truncated=0`（**未撞 `MAXLINE`**）。

### 3.4 **反极性（撤修 ⇒ 回原帧，逐像素）**

| 面 | `fix`（闸开） | **`rev1`（闸关）** | 判 |
|---|---|---|---|
| `tab1` 帧 `sha16` | `c22457cf663453dd` | **`b440033da8b2a9e6`** | **回开工帧** |
| `AE(base, rev1)` | — | **`0 px`（`IDENTICAL`，逐字节）** | **同一份件、只差一个 env** |
| `AE(fix2, fix3)` | — | **`0 px`（`IDENTICAL`）** | **两趟独立复跑同帧** |
| `[FLOATAVOID]` | 3 行 | **0 行** | 整块不发生 |
| `[FORMATLINE-LINE] … durline/clr` | `30000/60000 … clrR=1` | **`180000 … clrL=0 clrR=0`** | 逐行回改前 |

### 3.5 不得回退（`tab2`／`tab3`）

**同一 `.so`、同一序（`3,2,1`）、只差闸**（最干净的一对）：

| 面 | `fix3o`（闸开） | `rev2o`（闸关） | `base_order`（开工件） |
|---|---|---|---|
| `tab1` | `c22457cf663453dd` | `b440033da8b2a9e6` | `b440033da8b2a9e6` |
| **`tab2`** | **`fae93ea5ed7a2f30`**（`colors=551`） | **同** | **同** |
| **`tab3`** | **`0c51d1ad6fa46543`**（`colors=562`） | **同** | **同** |
| 症状（`magenta`／`Unrecoverable`／`alive`／`app_rc`） | `0/0/yes/143` | 同 | 同 |

⚠️ **如实记（`NOINFO-TAB2-FORM`）**：题面把「`tab2` 帧 `ee13c717…`」列为不得回退项，但**在本代树上复现不出该形态** —— 开工件（`c1cf5e6a8d14cd46`）在**同一装置、同一装置件、同一序**下 `tab2` 取 **`fae93ea5ed7a2f30`（`colors=551`，具名色 `0/0/0/0`）**（`1,2,3` 序下 `tab2` 帧＝`tab1` 帧，即 `T-B8` §2 记的"点了但不换画面"形态）。⇒ 本席的"不得回退"判据取**开工件现取值**（`fae93ea5…`／`0c51d1ad…`），**不**拿一个本代不存在的期望值当判据。**该形态变动的归因不在本增量**（`rev2o` 与本增量代码逐字无关的路径上同值），需 `T-B12`／`T-B14` 面的接手者另判。

---

## §4 ④ 门禁（逐条现取，本席跑的）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only …/libwpfwin32.so` vs `bin/exports.txt` | **`846 == 846`**，`diff -q` 空；`exports.txt` 与开工**逐字节相同**（`83b60726bbc2486e`） |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5f9ed647c68197ae exports=846`**；`PTSGAP_FRONTIER_STATE=NAMED` |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=-`**（rc=0） |
| `PTS_COLORANCHOR` | 同上 | **`PTS_COLORANCHOR=PASS k=24 … hits=3`**（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`） |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，rc=0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=362 ids=2266 declared=225`**，rc=0（本载体落地**前**现取）；落地后见 §7 |
| `app-local` | `bash build/MilBridge/tools/sync-applocal.sh --check "$APP"` | **`SYNC-APPLOCAL=PASS items=5 ok=5 drift=0`**（`libwpfwin32.so=5f9ed647c68197ae`） |

（`PTS_GUARD`／`PTS_COLORANCHOR` 读的是**在册证据目录**（`evidence/`），不随本增量的 `.so` 变 ⇒ 它们是"**未回退**"的读数，**不是**本增量的新证据；本增量的新证据是 §3。如实照此读。）

---

## §5 ⑤ 症状门（成对）

| 症状门 | `base`（开工件，闸 n/a） | **`fix3`（闸开）** | `rev1`（同件闸关） | 说明 |
|---|---|---|---|---|
| `alive` / `app_rc` | `yes` / `143` | `yes` / `143` | `yes` / `143` | 本席按 PID 收（`kill`） |
| `magenta`（页级占位） | `0` | `0` | `0` | 无"不支持"占位 |
| `Unrecoverable system error` | `0` | `0` | `0` | **无 `FailFast`**（第一版曾 `2`，见 §1.3） |
| `[HC-UNHANDLED]` | `533` | `442` | `438` | **全为** `PtsException('-10000')`（`sed` 现取：三腿各一条同形）；同 `.so` 两腿 `438` vs `442` **同量级** |
| `PTS_GAP entry=` | `0` | `0` | `0` | — |
| `[FS_PAGE_GAP]` | **0 行** | **0 行** | **0 行** | `T-B14` 收严后本路径已无此拒发 |
| `colors`（整屏） | `1078` | `1039` | `1078` | 见 §3.1 |
| `[FORMATLINE-LINE]` 总计 | `114` | `156` | `114` | `+42`＝发现趟＋真驱趟增行（§3.3） |
| `[FLOATAVOID]` | —（无该代码） | `3` | **`0`** | 闸关整块不发生 |

---

## §6 具名 `NOINFO` ／ 前置 ／ 边界（如实划界）

1. **`NOINFO=float-rect-self-convention`（浮动盒矩形不是"上游真几何"）**：本增量用的矩形＝`wpf_pts_att_geometry(idx, idobj==-2)` —— 它是本移植**既有的自约定**（`u = 30000 + (idx%4)*30000`、`v = wpf_pts_att_page_anchor_v(idx)`、`du/dv` 为常数），**同时**是托管 `ArrangeFigure/Floater`（`FsQueryFigureObjectDetails`／`FsQueryFloaterDetails`）的输入 ⇒ **两侧同源、不是伪造**，但**不是**"从 XAML 的 `HorizontalOffset`／`Width` 算出来的真几何"。本增量**不声称**绕排后的版面＝Windows 上的版面。
2. **`NOINFO=page-origin-absent`（段的页内 v 原点无源）**：`urStartTrack` 本侧**一直传 0**（承 `T-A28` 的 `NOINFO-FSGEOMETRY-LAYOUT`）⇒ 计划函数按**段内**累计 `v0/v1`（与 `T-B4` 的 `vr_start` 同参照）。**后果如实记**：只有当浮动盒的 `v` 也按同一原点读时两者才可比（本代二者的 `v` 都是"自约定页坐标"，故同参照）。
3. **`NOINFO=left-float-no-shift`（左压盒不能右移行起点）**：上游**托管消费面**里 `urStartLine`／`urPageLeftMargin` **不被传**（`TextParagraph.cs:526` 只带 `durLine`／`durTrack`）⇒ 盒压在行起点（`R.u<=0`）时本侧**只**能置 `fClearOnLeft` 并具名，**不假造**"行起点右移"。本代现场**未出现**该支（两个盒 `u=100/200 DIP > 0`）。
4. **`NOINFO=anchor-late-discovery`（浮动对象只在锚点行被发现）**：附属对象只在**被驱到的那一行**由 `pfnGetNumberAttachedObjectsInTextLine` 交出（现场：锚在第 7 行）⇒ 本增量用**同窗两趟**（发现趟→真驱趟）绕过该时序限制；**代价如实记**：含浮动的段**多驱一趟**（`[FORMATLINE-LINE]` +8/窗），且发现趟创建的 `Line` 句柄**不回收**（＝本移植既有口径：真驱趟的行句柄同样不回收）。
5. **`NOINFO-TAB2-FORM`**：见 §3.5 —— 题面点名的 `tab2` 帧 `ee13c717…` 在本代树上**复现不出**；本席按**开工件现取值**做不回归判据。
6. **未跑**：整趟 `verify-all.sh`（照派单 ②）、`static-jaws-check.sh`、`close-wave.sh`。
7. **黑名单未碰**：`upstream/**`（**只读**，`TextParagraph.cs`／`Line.cs`／`Pts.cs`／`PtsHost.cs` 逐字未动）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。
8. **上游不存在面（本增量**不**需要的）**：本轮**不需要**任何上游未实现的入口——绕排的**全部**杠杆都在本侧驱动（§1.1 已证托管侧对两个清位"只存不读"）。⇒ **不构成新的具名前置**；残余口径见上 1–4 条。

---

## §7 改动清单 · 收净 · 自证

### 7.1 改动清单（逐文件现取）

| 件 | `sha16` | 字节 | 改什么 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | **`375f017196a4383c`**（写前 `3a22ad0ff50f616f`） | `899600`（前 `889746`） | §2.1 逐行入参 ＋ §2.2 闸／两趟／计划函数 ＋ §2.3 台账三格与回查复现 ＋ §2.4 `MAXLINE 32→64`；`[FORMATLINE-LINE]` 尾追三格；`[FLOATAVOID]` 新行 |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`5f9ed647c68197ae`**（前 `c1cf5e6a8d14cd46`） | `567456`（前 `558992`） | **构建重产**（`bash build-shim.sh`；`bin/` 在 `.gitignore` ⇒ 不入 git） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | **`a2aa1f2c2f867f4d`** | `81988` | **只**重锚 `PTSGAP-DECL` 行的 `so16=`（`c1cf5e6a8d14cd46 → 5f9ed647c68197ae`；其余各格未动） |
| `build/MilBridge/P1-hcfloat-impl-report.md` | **新建**（本载体） | — | — |

**未改（有意）**：`bin/exports.txt`（逐字节同开工：`83b60726bbc2486e`）｜`build/PresentationFramework.Linux/**`／`build/PresentationCore.Linux/**`（本增量无生成件）｜`build/MilBridge/P1-hcshutdown-impl-report.md`（`dated` 报告里出现的旧 `so16` **保留原文**，本仓「只增不改」纪律）。

### 7.2 副本先行 ／ 写前备份

`git status --porcelain` 在**第一次写之前**现取只有 `?? build/MilBridge/tasks-tail2/T-B15.md`（派单件）⇒ `src/WpfGfx.Linux.Native/**` 工作树==`HEAD`。备份取自 **`git show HEAD:<path>`**（＝当时的工作树逐字节）+ `cp -p`：
`~/tb15-work/bak/{win32_pts.c.orig(3a22ad0ff50f616f), exports.txt(83b60726bbc2486e), pts-gap-decl.txt, libwpfwin32.so(c1cf5e6a8d14cd46)}`。

### 7.3 收净

- **app-local 逐件一致**：`SYNC-APPLOCAL=PASS items=5 ok=5 drift=0`（§4）；五件现取 `libwpfwin32.so=5f9ed647c68197ae／wpfgfx_cor3.so=a7a0f884b704ca96／PresentationCore.dll=8e0234c89b452487／PresentationFramework.dll=1ddedabb2b033b9f／WindowsBase.dll=0b54a1e3f9d37ab1`。
- **进程／显示位按 PID 收净**：`:236` 的 `Xvfb`／`xfwm4` 按 `~/tb15-work/{xvfb,wm}.pid` 收；七腿的 `HandyControlDemo` 全部按 PID 收（`APP_RC=143`＝本席 `kill`）。**未占 `:10`**；`/tmp/.X11-unix/` 只余 `X0/X1/X11`（非本席）。
- **报数一律现取**（纪律 40）：§3／§4／§5 每格都可复算（腿目录 `~/tb15-work/logs/<tag>/{app.log,shots/*.png}`；分析器 `~/tb15-work/{ovl,ovl2,ovl3,docink,imgdiff,map,maxx}.py`）。
- **重活全走槽**（7 趟，`HEAVYSLOT=ACQUIRED … rc=0`；`held=16–41 s`）。
- **`REPORTID` 落地后现取**：`files=363 ids=2266 declared=225`，rc=0（＋1 ＝ 本件）。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hcfloat-impl-report.md | sha256sum | cut -c1-16`）＝ **`dd47febd4f5fb98f`**（本行下方无内容，取该行之前全文的哈希）。

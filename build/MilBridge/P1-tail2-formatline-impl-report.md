# `P1-tail2` `TASK-0302` · native 驱动 `cbktxt.pfnFormatLine`（宿主侧行模型接线）—— 实现报告（`T-A28`）

- **读时**：`2026-09-30T15:2x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=74a444cf32166130d85076627ab88636afc0fa96`（现取）。
- **现件代**（`sha256` 前 16 位，现取）：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`8ad9376305404ca2`**（430736 B；改前 **`3795777128d29995`**／430240 B）｜`bin/exports.txt` ＝ **`c561dda4eca311c5`**（**677** 行／**逐字节未变**）｜`src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`bcd6a00bce9f67a2`**（461075 B；改前 `22a3503e37a703b6`／443526 B）｜`tools/pts-gap-decl.txt` ＝ **`b74f6609e489b4cd`**（改前 `af577ccfad68672e`）。
- **改前件备份（仓外，`cp -p`，取在**任何写之前**）**：`~/tA28-work/bak/{win32_pts.c.22a3503e.bak, libwpfwin32.so.37957771.bak, exports.txt.c561dda4.bak, pts-gap-decl.txt.af577ccf.bak}`。
- **只改**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（本增量本体）＋ `tools/pts-gap-decl.txt`（`D-G70` 声明行 `so16` 重锚）＋ 本载体。**未动** `bin/exports.txt`（构建后逐字节相同）、**未动** 任何复述位件（无产品计数变化 ⇒ 无可复述）。
- **黑名单遵守**：未动 `build/*.Linux/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`；**未跑**整趟 `verify-all`；重活（构建 ＋ 跑腿）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID；写盘无 `temp+rename` 需求（仅改两件、均 `cp -p` 备份在写之前）。
- **行号纪律**：本件行号**仅本次有效**（内容锚原文一并给出）。

---

## §0 结论速览（自包含）

1. **实现已落地（`win32_pts.c`，`P1-tail2` 指定写域内）**：`cbktxt` 槽 `pfnFormatLine` 的**唯一偏移定义**（槽 9／相对 `+328`／绝对 `+368`／快照下标 `41`，两条 `_Static_assert` 钉死）＋ 回调签名 `wpf_pts_fn_format_line`（逐参照抄上游 `Pts.cs:2312-2341`）＋ **窗内驱动格** `wpf_pts_formatline_drive`（挂在 `wpf_pts_drive_probe` 的 `FsCreatePage*` 调用期内）＋ **每段行记录台账** ＋ 具名留痕 `[FORMATLINE]`／`[FORMATLINE-LINE]`（§1／§2）。

2. 🔴 **决定性读数（本件的核心发现）**：`pfnFormatLine` **机械上真能调通** —— `rc=0`、真 `pfsline` 句柄（`0xc…0x13`）、真 `dcpLine`（88…275）、`dvrAscent=3342`／`dvrDescent=849`（＝ `11.14`／`2.83` DIP，**字号正常**）逐行可读（§3.6）。
3. 🔴 **但它在"正确几何"下必然 abort**：托管侧 `Line.GetTextRun` 走到该段落的**块边界**时撞
   **`Invariant.FailFast("We do not expect any Blocks inside Paragraphs")`**（`LineBase.cs:137`）
   ⇒ **不可捕获** ⇒ `app_rc=134`（§3.6 的 8 行台账后即 abort）。⇒ **不能进主链**。
4. ⇒ **运行期闸 `WPF_PTS_FL_DRIVE` 缺省 ＝ `0`（关）**；缺省路径**产品行为逐字不变**：
   `reason=no-text-line-model` **108 → 107/108**（两次独立样本）、`[HC-UNHANDLED]` **112 → 111/112**、
   帧 `sha16` **`ef3fd6765f18f51b` 逐字节不变**、`alive=yes/app_rc=143`（§3）。
5. ⇒ **回填故意未实现**（`FsQueryTextDetails`／`FsQueryLineList*` 一字未改）：台账的"可用"谓词
   `fl_ok` **恒 0**（行记录**从不收束于段尾** `fsflrEndOfParagraph*`；`fsflres=0` ＝ `fsflrOutOfSpace` 贯穿全部 8 行）
   ⇒ **无可信行源 ⇒ 不许回填**（`T-A27` §4 判据 `D1`／`D2` 的"零假值／永不假成功"照办）。
6. ⇒ **判决：合法终点（失败）** —— `T-A27` §4.1 的判词「缺口 ＝ native 侧从不驱动，只要把驱动接上就行」
   **被现场证伪**：缺口不是"没接上"，是**接上以后立刻撞到一条更硬的前置**（该 `TextParagraph` 的
   内容模型／段落边界与 `pfnFormatLine` 的期望不符）。真前置**具名**：`PRECOND-TEXTPARA-CONTENT-MODEL`
   （本件不解除，属**下一跳**）。
7. **反极性（该红必红，同一构建、同一跑器）**：`gate=1` ⇒ `alive=no`／`app_rc=134`／`failfast=4`／
   `unrec=2`；`gate=0` ⇒ `alive=yes`／`app_rc=143`／`failfast=0`（§4）。**D4 的对偶**也现取：
   `gate=0` ⇒ `[FORMATLINE] … gate=0 v=GATE-OFF calls=0`（**接线在、调用 0，且有具名行 ⇒ 不静默**）。
8. **门禁**：`nm -D --defined-only == exports.txt`（**677==677**，逐名零差异）｜`PTSGAP=PASS`（`so16` 重锚后；rc=0、零 `SITE-DRIFT`）｜`DEFREG=PASS declared=225 route_ids=225`（rc=0；`DEFREG_DECLDRIFT=0 keys=-`）｜`REPORTID=PASS files=314 ids=2222 declared=225`（rc=0；**本件落地后**现取）。

---

## §1 现取：契约（偏移 ＋ 签名 ＋ 调用窗）

### 1.1 槽位（上游逐字）

| 面 | 件:行（现取） | 原文 |
|---|---|---|
| 槽声明 | `upstream/…/PtsHost/Pts.cs:676` | `             internal FormatLine pfnFormatLine;` |
| 所在结构（第 10 字段 ⇒ **索引 9**） | `Pts.cs:665-698` | `        internal struct FSCBKTXT` |
| 装配（本移植生成件） | `build/PresentationFramework.Linux/PtsCache.Linux.cs:659` | `            contextInfo.fscbk.cbktxt.pfnFormatLine = new PTS.FormatLine(ptsHost.FormatLine);` |
| 托管实现 | `upstream/…/PtsHost/PtsHost.cs:1341` | `        internal int FormatLine(` |
| 转派 | `upstream/…/PtsHost/TextParagraph.cs:664` | `        internal void FormatLine(` |
| 走 `TextFormatter` | `upstream/…/PtsHost/Line.cs:255`／`:271` | `internal void Format(FormattingContext ctx, int dcp, int width, int trackWidth, …)`／`                    _line = _host.TextFormatter.FormatLine(_host, dcp, _wrappingWidth, lineProps, textLineBreak, ctx.TextRunCache);` |

**偏移（本件**编译期**钉死，唯一定义处）**：`fscbk(+40)` ＋ `cbktxt 组基(+256)` ＋ `9×8` ＝ **`+368`**；
快照下标 ＝ `328/8` ＝ **`41`**（`fscbk_snap` 起点即 `fscbk`）。
```c
#define WPF_PTS_CBKTXT_IDX_FORMATLINE   9
#define WPF_PTS_SNAP_IDX_FORMATLINE     (WPF_PTS_FSCBK_CBKTXT_OFF / 8 + WPF_PTS_CBKTXT_IDX_FORMATLINE)  /* 41 */
_Static_assert(WPF_PTS_SNAP_IDX_FORMATLINE == 41, "pfnFormatLine 快照下标 != 41");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_FORMATLINE * 8 == 368, "…");
```

### 1.2 签名（逐参照抄 `Pts.cs:2312-2341`）

18 入参 ＋ 11 出参，**全是 ≤8 B 标量**（`int`／指针）；`out FSFLRES` 是 `int` 枚举（`Pts.cs:1092`）
⇒ 出参是 `int *`。本件以 `typedef int (*wpf_pts_fn_format_line)(…)` 照抄（`win32_pts.c` 的
`wpf_pts_fn_get_next_para` 定义块之后）。

### 1.3 调用窗（本件**只在**此窗内驱）

`FlowDocumentPage.FormatBottomless`／`FormatFinite` 在 `using(_structuralCache.SetDocumentFormatContext(this))`
里调 `_ptsPage.CreateBottomlessPage()`／`CreateFinitePage()`（`upstream/…/PtsHost/FlowDocumentPage.cs:136`／`:199`）
⇒ 该 native 调用期内 `StructuralCache.CurrentFormatContext != null` ⇒ `TextParagraph.FormatLine` 的
`StructuralCache.CurrentFormatContext.OnFormatLine()`（`TextParagraph.cs:697`）**有对象**。
⇒ 本件的驱动格挂在 **`wpf_pts_drive_probe`**（由 `FsCreatePageBottomless`／`FsCreatePageFinite` 两处调用窗进入），
**窗外（查询期）一格不驱**（承 `T-A27` §4 判据 `D5`）。

### 1.4 `nmp`／`pfsparaclient` 的可得性（现取，`[NMP-TYPE]` 现场）

| 跳 | 现取读数（`~/tA28-work/legs-base` 腿日志，本席现取） |
|---|---|
| `+80 GetMainTextSegment(sect)` | `nmSeg1=0x2`（`ContainerParagraph`，`MAINTEXTSEG-LIVE-HANDLE`） |
| `+136 GetFirstPara(0x2)` | `fserr=0 fSucc=1` ⇒ `nmp1=0x3`，`TYPE=MS.Internal.PtsHost.ContainerParagraph` |
| 窗内递归枚举（`wpf_pts_sub_enum_into`） | `0x3`→`{0x4,0x6,0x7}`（皆 `ContainerParagraph`）；`0x4`→`0x8`／`0x6`→`0x9`／`0x7`→`0xa`，`TYPE=MS.Internal.PtsHost.TextParagraph` |
| 叶谓词（本件用） | `enum_ok==0`（⇒ `+136` 对该段**不成立** ⇒ 非 `ISegment` ⇒ 即 `TextParagraph` 那一类；`+: for 0x8/0x9/0xa → nms_isISegment=0`） |

---

## §2 实现（逐处；`win32_pts.c`）

| 落点 | 内容 |
|---|---|
| 常量 ＋ 断言 | `WPF_PTS_CBKTXT_IDX_FORMATLINE`／`WPF_PTS_SNAP_IDX_FORMATLINE` ＋ 两条 `_Static_assert`（偏移 `+368`／下标 `41`）。 |
| 回调签名 | `typedef int (*wpf_pts_fn_format_line)(…)`（§1.2）＋ `_Static_assert(sizeof == 8)`。 |
| 台账字段 | `struct wpf_pts_subtrack_s` 新增：`fl_calls`／`fl_last_rc`／`fl_nlines`／`fl_dcp_sum`／`fl_ok`／`fl_complete`／`fl_truncated`／`fl_paraclient_rc`／`fl_geo_src` ＋ `fl_line[WPF_PTS_FL_MAXLINE=32]`（逐行：`dcp_first`／`dcp_lim`／`dvr_ascent`／`dvr_descent`／`ur_bbox`／`dur_bbox`／`fsflres`／`f_forced`／`pfsline`）。 |
| 窗内驱动格 | `wpf_pts_formatline_drive(d, where)`（**只**从 `wpf_pts_drive_probe` 调），逐段：`wpf_pts_fl_walk` 找叶 ⇒ `wpf_pts_format_one_para`：①`+176 pfnCreateParaclient(nmp)`（本侧造）②循环 `pfnFormatLine`（`dcp` 累计；`pbrlineIn` 取上一行 `ppbrlineOut`）③`+192 pfnDestroyParaclient`（本侧回收）。 |
| 有界 ＋ 成环守卫 | `WPF_PTS_FL_MAXLINE=32`（撞界 ⇒ `fl_truncated=1`）／`WPF_PTS_FL_MAX_PARA=8`／`dcpLine<=0` 即停。 |
| 运行期闸 | `WPF_PTS_FL_DRIVE`（缺省 **`0`＝关**）＋ `[FORMATLINE] … gate=0 v=GATE-OFF` 具名行。 |
| 几何 | `WPF_PTS_FL_DU/DV = 180000`（**PTS 单位**：`300 单位 = 1 DIP` ⇒ `600 DIP`；`TextDpi.cs:201` 的 `_scale=28800/96`）＋ 具名 `NOINFO-FSGEOMETRY-LAYOUT`（**本侧无几何入站源**，见 §6-3）。 |

**没有改动**：`FsQueryTextDetails`／`wpf_pts_line_reject`／`FsQueryLineList*` 三入口**一字未改**（回填未实现，理由见 §0-5）。

---

## §3 成对机读读数（**同一跑器**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；同一显示流程 A 臂、`:231`、`1280x1024x24`）

四趟腿（`~/tA28-work/legs-{base,c,c2,d}`）：
- `legs-base` ＝ **改前** `.so` `3795777128d29995`（`cp -p` 自备份还原后跑，**用毕已换回改后件**）；
- `legs-c`／`legs-c2` ＝ **改后** `.so` `8ad9376305404ca2`，`gate` **关**（缺省＝出货态）—— **两个独立样本**；
- `legs-d` ＝ 同改后件，`WPF_PTS_FL_DRIVE=1`（**反极性腿**）。

### 3.1 装配自证（逐趟现取）

```
legs-base: SYNC-APPLOCAL=PASS target=/home/links-dev/w67-work/app items=5 ok=5 synced=0 created=0 drift=0 noauth=0 same=0 rc=0
           AUTHORITY: shim=3795777128d29995 pf=1757d610a687777c ｜ APPDIR: shim=3795777128d29995 pf=1757d610a687777c
legs-c/c2 : SYNC-APPLOCAL=PASS … items=5 ok=4 synced=1 created=0 drift=0 noauth=0 same=0 rc=0
           AUTHORITY: shim=8ad9376305404ca2 pf=1757d610a687777c ｜ APPDIR: shim=8ad9376305404ca2 pf=1757d610a687777c
legs-d    : 同 legs-c/c2；POSTSHIM: shim=8ad9376305404ca2 pf=1757d610a687777c（== authority ⇒ 读数可归因）
all       : LEGSCOUNT requested=2 obtained=2 refused=0 display=:231 session_rc=0（legs-d: obtained=1 refused=1 reasons=converter-rc=1）
```

### 3.2 靶面成对（现取 `app_g1.log` 逐字计数）

| 面（`grep -c`，现取） | legs-base（改前件） | legs-c（改后·gate 关） | legs-c2（改后·gate 关） | legs-d（改后·gate 开） |
|---|---|---|---|---|
| `reason=no-text-line-model` | **108** | **107** | **108** | —（`0`，**早早 abort**） |
| `entry=FsQueryTextDetails` | 108 | 107 | 108 | 0 |
| `[HC-UNHANDLED]` | **112** | **111** | **112** | 0 |
| `[FORMATLINE] … gate=0` | 0（**该行本不存在**） | **3** | **3** | 0 |
| `[FORMATLINE-LINE]`（**真调留下的逐行台账**） | 0 | **0** | **0** | **8** |
| `FailFast` 行数 | 0 | 0 | 0 | **4** |
| `Unrecoverable` 行数 | 0 | 0 | 0 | **2** |
| 日志行数 | 6036 | 6010 | 6060 | 821（**早停**） |

> ⚠️ **如实记两处**：① `legs-c` 与 `legs-c2` 同件同体制、`no-text-line-model` 差 **1**（107 vs 108）、
> `[HC-UNHANDLED]` 差 **1**（111 vs 112）⇒ **跑次计数漂移**（本仓纪律 18：跑次戳／仪器计数漂移
> **不算差异，但必须点名并列出实际数**）；`legs-base` = 108/112 与 `legs-c2` **逐字相同** ⇒
> 判词「**缺省路径与改前无产品差异**」**成立**（D6 两样本＋改前对照共 3 样本同判）。
> ② `legs-base` 的 108/112 与 `T-A26` 报告里的 109/113 **差 1**，同为跑次漂移（不同趟、不同显示号租借时刻）。

### 3.3 帧面成对（**不把空白读成绿**）

| 面 | legs-base | legs-c | legs-c2 | legs-d |
|---|---|---|---|---|
| `leg_24.env` 的 `fr_sha` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` | **`2a60a00fc582e97d`**（**abort 后的残帧**） |
| `leg_23.env` 的 `fr_sha` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` | `ef3fd6765f18f51b` | （无该腿） |
| `AE(boot,k24)`／`AE(boot,k23)` | 15386／0 | 15386／0 | 15386／0 | 480000／—（整屏无内容） |
| 具名色锚（`GhostWhite/Beige/…`） | 全 0 | 全 0 | 全 0 | 全 0 |

⇒ **改后（出货态）两页内容区与改前逐字节相同**（**仍无任何非空态像素**）⇒ **本件明确判红**：
产品面**零进展**，**不以"帧没变"读成绿**。

### 3.4 症状门成对（`leg_24.env`／`leg_23.env` 逐字）

| 面 | legs-base | legs-c | legs-c2 | legs-d |
|---|---|---|---|---|
| leg24 `alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns` | `yes`／`143`／`0`／`383`／`480000`／`…FlowDocumentDemo` | 同 | 同 | **`no`／`134`／`0`／`1`／`0`／`…PracticalDemo`** |
| leg23 `alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns` | `yes`／`143`／`0`／`383`／`480000`／`…RichTextBoxDemo` | 同 | 同 | （无该腿） |
| `FAILLINE … failfast=`／`unrec=`（leg24） | `0`／`0` | `0`／`0` | `0`／`0` | **`4`／`2`** |
| `DEV x_up`／`five_stable` | `yes`／`yes` | `yes`／`yes` | `yes`／`yes` | `yes`／`yes` |

### 3.5 驱动计数（`T-A27` 判据 `D4` 的两个方向）

```
【未驱动（缺省）】legs-c 逐字：
[FORMATLINE] where=FsCreatePageBottomless window=in gate=0 v=GATE-OFF（缺省；`WPF_PTS_FL_DRIVE=1` 才驱） calls=0 ok=0 gap=0
[FORMATLINE] where=FsCreatePageFinite     window=in gate=0 v=GATE-OFF（…）                                     calls=0 ok=0 gap=0
[FORMATLINE] where=FsCreatePageBottomless window=in gate=0 v=GATE-OFF（…）                                     calls=0 ok=0 gap=0
【真驱动】legs-d 逐行（8 行台账 ＋ 末行即 abort 前最后一条）：
[FORMATLINE-LINE] where=FsCreatePageBottomless para=0x8 i=0 dcp=0   rc=0 pfsline=0xc  dcpLine=88  fsflres=0 fforced=0 ascent=3342 descent=849 urbbox=0 durbbox=170000 dep=0 rfmt=0
[FORMATLINE-LINE] … i=1 dcp=88  rc=0 pfsline=0xd  dcpLine=98  … durbbox=178794 …
[FORMATLINE-LINE] … i=2 dcp=186 rc=0 pfsline=0xe  dcpLine=98  … durbbox=176794 …
[FORMATLINE-LINE] … i=3 dcp=284 rc=0 pfsline=0xf  dcpLine=102 … durbbox=177680 …
[FORMATLINE-LINE] … i=4 dcp=386 rc=0 pfsline=0x10 dcpLine=103 … durbbox=175440 …
[FORMATLINE-LINE] … i=5 dcp=489 rc=0 pfsline=0x11 dcpLine=99  … durbbox=177986 …
[FORMATLINE-LINE] … i=6 dcp=588 rc=0 pfsline=0x12 dcpLine=93  … durbbox=161571 …
[FORMATLINE-LINE] … i=7 dcp=681 rc=0 pfsline=0x13 dcpLine=275 … durbbox=31359 …
```
⇒ `pfnFormatLine` **真被调**（`calls=8` 且**每行都是回调真返回值**）：`rc=0`、真 `pfsline` 句柄、真 `dcpLine`、
`dvrAscent/dvrDescent` 换算成 **`11.14`／`2.83` DIP**（＝**正常字号的行高**，证明几何单位选对了）。

### 3.6 🔴 abort 取证（`legs-d`，逐字）

```
[FORMATLINE-LINE] where=FsCreatePageBottomless para=0x8 i=7 dcp=681 rc=0 pfsline=0x13 dcpLine=275 fsflres=0 …
Unrecoverable system error.: We do not expect any Blocks inside Paragraphs
Process terminated.
Unrecoverable system error.: We do not expect any Blocks inside Paragraphs
   at System.Environment.FailFast(…)
   at MS.Internal.Invariant.FailFast(System.String, System.String)
   at MS.Internal.PtsHost.LineBase.HandleElementStartEdge(System.Windows.Documents.StaticTextPointer)
   at MS.Internal.PtsHost.Line.GetTextRun(Int32)
   at MS.Internal.PtsHost.TextFormatterHost.GetTextRun(Int32)
   … at MS.Internal.PtsHost.PtsHost.FormatLine(…)
   … at MS.Internal.PtsHost.PtsPage.CreateBottomlessPage()
   … at MS.Internal.PtsHost.FlowDocumentPage.FormatBottomless(System.Windows.Size, System.Windows.Thickness)
   … at MS.Internal.Documents.FlowDocumentView.MeasureOverride(System.Windows.Size)
```
**根因（现取，逐字）**：`LineBase.HandleElementStartEdge` 的第一条硬断言就是
`Invariant.Assert(!(element is Block), "We do not expect any Blocks inside Paragraphs")`
（`LineBase.cs:130` 之后的那一行）；`Line.GetTextRun(dcp)` 用
`textContainer.CreateStaticPointerAtOffset(_cpPara + dcp)` 取位（`Line.cs:134-160`）——
**`dcp` 累计越过了该 `TextParagraph` 自己的内容边界**（第 8 次调用落在 `dcp≈956`）⇒ 位置落在**下一个块元素**的
`ElementStart` 上 ⇒ 断言失败 ⇒ `FailFast`（**不可捕获**，`P6`：主链出现 `FailFast` 即红）。

⇒ **两种方案都读过了**（本件的 3 种方案配额用了 2）：
- **方案①**（窄几何 `768` ＝ `2.56 DIP`）：**不 abort**，但每行只吃 **1 个字符**（`fsflres=0` `fsflrOutOfSpace` 贯穿），
  32 行撞界 ⇒ `fl_truncated=1`／`fl_complete=0` ⇒ **行记录不完整**（`fl_ok=0`，**拒绝回填**）⇒ 无产品价值。
- **方案②**（正确几何 `180000` ＝ `600 DIP`）：**行断得对**（88–275 字符/行，行高 `13.97 DIP`），
  但第 8 行起撞**块边界** ⇒ **`FailFast`／`app_rc=134`** ⇒ 不可用。

**⇒ 判合法终点**：`T-A27` §4 的处方（"窗内驱动 `pfnFormatLine` 即可"）在实践中**不成立**；
真前置**具名 `PRECOND-TEXTPARA-CONTENT-MODEL`**（该 `TextParagraph` 经 `+136`／`+144` 枚举出来的内容
**含 Block 元素**，而 `pfnFormatLine` 的契约要求段内**只有 inline**）—— 解除它要么需要**先修内容模型**
（改托管，越级），要么需要**在 native 侧精确求段落长度／边界**（本件**未**做，属下一跳）。

---

## §4 反极性（**同一构建** ＋ **同一跑器**，只差一个环境变量 ⇒ 单变量）

| 判据（`T-A27` §4） | 正极性（`gate=0`，legs-c/c2） | 反极性（`gate=1`，legs-d） |
|---|---|---|
| **D4 驱动计数** | `calls=0`（**且具名** `gate=0 v=GATE-OFF`，**不静默**） | `calls=8` ∧ `[FORMATLINE-LINE]` ×8（每行回调真返回值） |
| **D5 窗内／窗外** | `window=in gate=0`（**构图：窗内**；窗外**零发调**） | `where=FsCreatePageBottomless window=in`（**两腿都在窗内**，`FsCreatePageFinite` 那窗未到） |
| **症状门** | `alive=yes／app_rc=143／failfast=0` | **`alive=no／app_rc=134／failfast=4／unrec=2`** ⇒ **该红必红** |
| **帧面** | `fr_sha=ef3fd6765f18f51b` | `fr_sha=2a60a00fc582e97d`（**残帧**） |
| **D2 永不假成功** | `no-text-line-model` 逐字保留（**无一行 `rc=0`**） | 台账 `fl_ok=0`（`complete=0`）⇒ **无回填、零假值** |

⇒ **该红必红的两条独立证据**：① 机械面 —— 把闸打开，`app_rc` 由 `143` 变 **`134`**、`failfast` 由 `0` 变 **`4`**，
**同一构建、同一跑器、只差一个 env**；② 判词面 —— `[FORMATLINE-LINE]` 的 8 行**逐行可读**（`rc/dcpLine/pfsline/ascent`），
紧接着就是 `FailFast` 的**具名断言串**（不是"没反应"，是"**打上去了、它抛了**"）。

---

## §5 验收逐条（对 `T-A28` ③）

- **① `T-A27` §4 的 6 条判据逐条现取 ＋ 每条带反极性**：§4 表（`D1`＝§0-5／§4 末行的"回填一字未写"；
  `D2`＝§3.5 的"`fl_ok=0` ⇒ 无回填"；`D3`＝§3.5 的 `[FORMATLINE]`／`[FORMATLINE-LINE]` 具名行 ＋ `gate=0` 具名行；
  `D4`＝§3.5 的 `calls=0 ↔ calls=8`；`D5`＝§4 表的 `window=in` 两腿；`D6`＝`legs-c`／`legs-c2` 两独立样本 ＋ `legs-base` 对照）。
- **② `no-text-line-model`／`[FS_PAGE_GAP]`／`[HC-UNHANDLED]` 成对；`pfnFormatLine` 调用面现取**：§3.2（`108→107/108`；
  `[HC-UNHANDLED] 112→111/112`；`call>0` 见 §3.5）。⚠️ `pfnFormatLine` 的**驱动格是新增的**（改前 `grep -n 'cbktxt\.'`
  现取 **0** 命中；改后走**快照下标 41**，不靠文本 deref）。
- **③ 帧面成对（不得把空白读成绿）**：§3.3（**改后与改前逐字节相同**、色锚全 0 ⇒ **如实判红**）。
- **④ 导出面 `nm==exports`；`PTSGAP=PASS`；`DEFREG`／`REPORTID` rc=0**：`nm -D --defined-only` 行数 ＝ `exports.txt` 行数 ＝ **677**（逐名零差异；**零新增零消失**）；`PTSGAP=PASS tool=82 dead=11 artifact=1 ops=70 impl=73 so16=8ad9376305404ca2 exports=677`（`so16` 已重锚；零 `SITE-DRIFT`；rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS files=314 ids=2222 declared=225`（rc=0）。
- **⑤ 症状门成对**：§3.4（缺省路径六项逐字相同；反极性腿 `alive=no/app_rc=134`）。

---

## §6 边界 · `NOINFO` · 主动披露

1. **未改任何其它仓内文件**：`git status --porcelain` 现取 ＝ `M src/WpfGfx.Linux.Native/src/win32_pts.c`／`M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` ＋ 本件（untracked）＋ 两项**先于本件**的 untracked（`build/MilBridge/tasks-tail2/T-A28.md`／`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`；**`P1-tail2-hostline-recon.md`／`T-A27.md` 亦为本件之前既有**）。`bin/libwpfwin32.so`／`bin/exports.txt` 是**构建生成件**（`git ls-files` 现取 0 ⇒ 不入库），不计入改动面；`exports.txt` **逐字节未变**。
2. **`DEFREG_DECLDRIFT`**：现取 `DEFREG_DECLDRIFT=0 changed-route-files-since-DECL-GEN keys=-` ⇒ **本件未改任何 route 件** ⇒ **不需**主控重发 `declared.tsv`（与 `T-A26` 不同）。⇒ 本件**不登记**新 `D-G<digits>` 编号（避免造出 `undeclared-id-in-route`）；本件的发现以**具名 token** 承载（`PRECOND-TEXTPARA-CONTENT-MODEL`／`NOINFO-FSGEOMETRY-LAYOUT`）。
3. **`NOINFO-FSGEOMETRY-LAYOUT`（具名，射程逐条）**：`pfnFormatLine` 要 `urStartLine/durLine/urStartTrack/durTrack/urPageLeftMargin`。
   **本侧没有几何的入站源** —— `FsCreatePageFinite`／`FsCreatePageBottomless` 的几何形参**全是 `out`**
   （`Pts.cs:3110-3132`；真机由 native 引擎**自算**）；`FSPAP`（`+168`）只有 4 个 `int`、无几何；
   `GetSectionProperties`（`+64`）给的也只有列数/方向。⇒ 本件用**本侧页几何约定**（`180000 PTS 单位` ＝ `600 DIP`）
   **具名降级**，**不**声称与上游 ABI 几何可比。
4. **`NOINFO-FORMATLINE-PARALEN`（具名）**：本件**没有**独立求得该段落的**真段长** ⇒ `ΣdcpLine == 段长`
   这条**无法独立对账**（只有"末行是否为 `fsflrEndOfParagraph*`"这一个**自证**判据）。⇒ 因此 `fl_ok`
   用的是**自证判据**（收束于段尾）而**不是**无源的外部长度 ⇒ 严格说 `D2` 的"账守恒"这一半**只做到自证级**。
   **消掉条件**：拿到段长（须托管侧或 native 真实现 `FsQueryTextDetails` 的 `dcpLim` 源）。
5. **侧效（如实披露，**未进仓**）**：`~/tA28-work/`（改前备份 ＋ 四趟腿证据 `legs-{base,c,c2,d}/` ＋ 两个跑腿封装脚本）；`~/w67-work/app` 现**已同步回改后权威件**（`SYNC-APPLOCAL=PASS drift=0`）。
6. **本件**未**做的**（防被读宽）：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；
   **未实现回填**（理由 §0-5）；**未**在 `HANDOFF-NEXT.md`／`docs/ROUTES.md` 等复述位件里写任何**新数**
   （无产品计数变化 ⇒ **无可复述**；见 §6-2 的 `DECLDRIFT=0`）。
7. **代际**：`.so` ＝ `8ad9376305404ca2`（430736 B）；`win32_pts.c` ＝ `bcd6a00bce9f67a2`（461075 B）；
   `pts-gap-decl.txt` ＝ `b74f6609e489b4cd`；`exports.txt` ＝ `c561dda4eca311c5`（677 行，**未变**）。
   改前：`3795777128d29995`（430240 B）／`22a3503e37a703b6`（443526 B）／`af577ccfad68672e`。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-formatline-impl-report.md | sha256sum | cut -c1-16`）= `63ecd8afa5084fdd`

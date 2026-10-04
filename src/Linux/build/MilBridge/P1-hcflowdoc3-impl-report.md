# P1-hcflowdoc3 报告 —— `T-B10` hc 流文档页 `tab2`／`tab3` 空白：`[QPD] vis_built` 的**形成链** —— **实现（判：`T-B9` 的"真断点"证伪 ＋ 合法终点）**

> 任务：`build/MilBridge/tasks-tail2/T-B10.md`（实现子代理；本轮唯一写者）。
> 读时：`2026-10-03T01:1x–01:3x+0800`（各格另注；**所有数值现场现取**）。
> 树：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=330f9b7`（现取）。
> 权威件：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`5e0d7b807c2fc220`**（现取；＝ `T-B8`／`T-B9` 在册值）；`exports=846`。
> 源码件：`src/WpfGfx.Linux.Native/src/win32_pts.c` = **`edaf0bf17ede9bb9`**（现取；＝ `T-B9` 备份侧现读值）。
> 装置：私有 `Xvfb :236 -screen 0 1280x1024x24` ＋ `xfwm4 --compositor=off`（自起自收，PID 记账见 §8）；应用 ＝ 仓外 hc demo（`$APP=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，`DOTNET` 走 `$HOME/.dotnet`）。**未占 `:10`、未占 `:231`、未占 `:236` 之外任何位**。
> ⚠️ 本机 `DISPLAY` 为空；所有腿都在 `:236` 上、**只按 PID 收净**。
> **行号纪律（纪律 31）**：下文行号**仅本次有效**，一律附**内容锚原文**。

---

## §0 结论速览（一页）

| 项 | 结果 |
|---|---|
| **① `vis_built` 形成链（件:行 ＋ 现取）** | **谁置它**：**唯一置位点** ＝ `win32_pts.c:9035`（`FsQueryTrackParaList` 的判别器分支，内容锚 `pg->qpd_vis_built   = 1;`，同处发 `[VIS]`）。**谁该置它**：托管**页视觉帧**（`build/PresentationFramework.Linux/PtsPage.Linux.cs:1013`→`:1060` → `PtsHelper.Linux.cs:260` → `FsQueryTrackParaList`）—— **它确实在置**。**为何读数恒 0**：`[QPD]` 打印的 `vis_built=` 是**函数入口的读前值**（`win32_pts.c:7259`／`:7294`），而 `OnAfterFormatPage` 每趟 `_section.StructuralCache?.ClearUpdateInfo(false)`（`PtsPage.Linux.cs:820`）⇒ `FsClearUpdateInfoInPage` 把 `qpd_vis_built` **归 0**（`win32_pts.c:7404`）⇒ **每个 `[VIS]` 后紧跟一个 `[CLRUPD]`**（现取 **1:1**，见 §3）⇒ 读到的自然是 0（§2／§3）。 |
| **② 第一处断点（**不是** `vis_built`）** | `T-B9` 判的"真断点 ＝ `[QPD] vis_built` 恒 0" **证伪**：**单变量**（同一权威件，只差 `WPF_PTS_HANDLE_STRICT=0`）⇒ `[VIS]` **8 → 239**、`[HC-UNHANDLED]` **3 → 1**，而 `tab2`／`tab3` 帧**逐字节不变**（`1fb95eab89966441`／`0c51d1ad6fa46543`，§3／§5）。真正停在**页视觉已建 → 上屏帧**这一跳：`tab1`（滚动／`FlowDocumentView`）画得出、`tab2`／`tab3`（分页／`DocumentPageView`＋`DocumentPageHost`）画不出（§4.4）。 |
| **③ 两处既有候选（逐个真跑）** | **(甲) 页几何**（`T-B8` 旧案）：本席在**同形**（212 形态）双腿里改 `WPF_PTS_FSP_FIN_DU/DV` `768/576`→**`244800/316800`**（＝ 816×1056 DIP），`[CHAIN] size=` 现取证明**改动真落到托管侧**（`2.56x1.92`→`816x1056`），而帧**逐字节不变** ⇒ **仍被否证**（§4.1）。**(乙) 陈旧句柄收严**：`WPF_PTS_HANDLE_STRICT=0`（＝撤该闸）⇒ `[VIS]` 8→239、异常 3→1，帧**逐字节不变** ⇒ **也被否证**（§3／§4.2）。 |
| **④ 帧面成对 ＋ 反极性** | 成对（同一权威件、四处只差一个开关／一个件）：`boot=386`／`tab1=b440033da8b2a9e6 colors=1078`（具名色齐）／`tab2=1fb95eab89966441 colors=551`（具名色 **0**）或 `=b440033da8b2a9e6`（**跑次相关**，见 `NOINFO-2`）／`tab3=0c51d1ad6fa46543 colors=562`（具名色 **0**）。**反极性**：唯一可控单变量 `WPF_PTS_HANDLE_STRICT` `0/1` ⇒ `[VIS]` `8↔239`、`[HC-UNHANDLED]` `3↔1`，**帧不变**（§5）。 |
| **⑤ 门禁（现取）** | `nm==exports`（**846==846**，`diff` 空）｜`PTSGAP=PASS`（`so16=5e0d7b807c2fc220 exports=846`，`tool=54 dead=11 artifact=1 ops=42 impl=42`）｜`PTS_GUARD=PASS legs=2/2`｜`PTS_COLORANCHOR=PASS k=24 hits=3`｜`DEFREG=PASS declared=225 route_ids=225` rc=0｜`REPORTID=PASS files=357 ids=2265 declared=225` rc=0（§6） |
| **⑥ 症状门（成对）** | 四腿 `alive=yes`／`app_rc=143`（本席按 PID 收）／`magenta=0`／`Unrecoverable system error=0`；`[HC-UNHANDLED]`＝`212`／`3`／`212`／`1`（**跑次相关**，见 `NOINFO-1`）；`[FORMATLINE-LINE]` 恒 `114`（§7） |
| **⑦ 边界（未违）** | **仓内零产品件改动**（`git status --porcelain`／`git diff --stat` 现取见 §8）；**未改仓外 hc 工程**、**未改 `upstream/**`**、**未改 `verify-all.sh`／`close-wave.sh`／`build/MilBridge/tools/**`**；**未跑整趟 `verify-all`**；显示位与进程**按 PID 收净**；实验件只在**仓外 scratch** `~/tb10-work/exp1`；app-local 五件已复原（`libwpfwin32.so=5e0d7b807c2fc220`） |

**一句话**：`T-B9` 的"真断点 ＝ `[QPD] vis_built` 恒 0"**被本席的现取证伪** —— `vis_built` 是**每趟 `ClearUpdateInfo` 就归 0 的"帧内见证"**（`[VIS]`↔`[CLRUPD]` 现取 **1:1**），把 `WPF_PTS_HANDLE_STRICT` 一关，`[VIS]` **8→239** 而 `tab2/tab3` **一像素未动**；本席又把 `T-B8` 的**页几何**候选在**同形腿**里重跑（`[CHAIN] size` 证明改动落到托管侧）**仍逐字节不变**。⇒ 真断点在**页视觉已建 → 上屏帧**这一跳（分页路径 `DocumentPageView`＋`DocumentPageHost`；滚动路径 `FlowDocumentView` 正常）⇒ **本轮如实划界 ＋ 具名前置 ＋ 给可实施替代**，**仓内零产品件改动**，不假成功。

---

## §1 ① 复现（装置 ＋ 步骤 ＋ 四腿指纹）

### 1.1 装置与步骤（可复算）

```bash
# 装置（自起自收；PID 记 ~/tb10-work/{xvfb,wm}.pid）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 300 --wait 900 -- bash ~/tb10-work/leg.sh <tag> [ENV=VAL ...]
# leg.sh：Xvfb :236 → xfwm4 → 起 app → navclick.py 进 item 24（流文档）→ tabs.py 逐 tab 1,2,3 截图
# 实验件腿：leg.sh 支持 TB8_SHIM_SRC=<scratch>/bin/libwpfwin32.so（腿前覆盖 app-local，腿后本席复原）
```

页签现取几何（四腿逐字相同）：

```
[GEO] TabItem#- scr=268,82 wh=165x27 en=True vis=True htv=True hdr=流文档滚动视图 sel=True
[GEO] TabItem#- scr=440,82 wh=165x27 en=True vis=True htv=True hdr=流文档单页视图 sel=False
[GEO] TabItem#- scr=611,82 wh=165x27 en=True vis=True htv=True hdr=流文档查看器   sel=False
```

⇒ 点中心 `(350,95)`／`(522,95)`／`(693,95)`；三条 `sel_after=True` ⇒ **输入命中无误**。`FORMATLINE_LINE_after_nav=76`→逐 tab 后 = **114**；`[NS] loaded HandyControlDemo.UserControl.FlowDocumentDemo` ⇒ **确已进页**。

### 1.2 四腿指纹（`app.log` 与帧，现取）

| 腿 | 仪器／开关 | `app.log` `sha16` | 日志字节 | `boot` | `tab1` | `tab2` | `tab3` |
|---|---|---|---|---|---|---|---|
| `b10base`（权威件） | — | `bc1ab893e2c2dfe9` | 1,887,502 | `b21eb530afd3c66c` | `b440033da8b2a9e6` | **`b440033da8b2a9e6`** | `0c51d1ad6fa46543` |
| `b10base2`（权威件、再跑） | — | `95a3c31ca6716ba1` | 1,886,976 | `b21eb530afd3c66c` | `b440033da8b2a9e6` | **`1fb95eab89966441`** | `0c51d1ad6fa46543` |
| `e1_geo`（**页几何实验件** `d8c1bde109e962fb`） | `FIN_DU/DV=244800/316800` | `6bb1c85434a66b20` | 2,065,402 | `b21eb530afd3c66c` | `b440033da8b2a9e6` | **`b440033da8b2a9e6`** | `0c51d1ad6fa46543` |
| `b10rev`（权威件 ＋ 收严关） | `WPF_PTS_HANDLE_STRICT=0` | `4e076004c32aece6` | 44,877,984 | `b21eb530afd3c66c` | `b440033da8b2a9e6` | **`1fb95eab89966441`** | `0c51d1ad6fa46543` |

`boot`／`tab1`／`tab3` 三帧四腿**逐字节相同**；`tab2` **两形态**（`b440033…`＝tab1 的画面／`1fb95eab…`＝自己的空态）—— **跑次相关**（`NOINFO-2`）。所有腿 `FIVE_PRE libwpfwin32.so=…` 与所声明件一致（`b10base`/`b10base2`/`b10rev`＝`5e0d7b807c2fc220`；`e1_geo`＝`d8c1bde109e962fb`，`SHIM_OVERRIDE` 行现取）。

### 1.3 文档区色数（`docink.py`，`x∈[250,800] ∧ y∈[100,600]`，具名色容差 ±3）

| 帧 | 腿 | `ink` | `colors` | `GhostWhite`／`Beige`／`DarkGreen`／`LightGoldenrodYellow`／`LightGray` |
|---|---|---|---|---|
| `tab1` | 四腿同 | 17135 | 764 | 10084／924／49／5884／4077 |
| `tab2`（＝tab1 画面形态） | `b10base`／`e1_geo` | 17135 | 764 | 10084／924／49／5884／4077 |
| `tab2`（自己的空态形态） | `b10base2`／`b10rev` | 1662 | 125 | **0／0／0／0**／7 |
| `tab3` | 四腿同 | 1679 | 149 | **2／0／0／0**／12 |

⇒ `tab3` **四腿逐字节相同的空态**；`tab2` 要么与 `tab1` 逐字节相同、要么是自己的空态 —— **从不出现自己的文档内容**。

---

## §2 ① `[QPD] vis_built` 的形成链（逐跳，件:行 ＋ 现取读数）

### 2.1 链的逐跳（承重件:行，均附内容锚）

| # | 件:行（现取） | 内容锚原文 | 作用 |
|---|---|---|---|
| P1 | `src/WpfGfx.Linux.Native/src/win32_pts.c:444-447` | `int qpd_calls;` / `int qpd_new_pending;` / `int qpd_vis_built;` / `int qpd_fstd_since;` | 四格状态（`calloc` ⇒ 新页恒 0 起） |
| P2 | `…win32_pts.c:7259` | `const int qpd_vis_built = pg->qpd_vis_built;` | **函数入口的"读前值"**（`[QPD]` 印的就是它） |
| P3 | `…win32_pts.c:7265-7266` | `const int fskupd = (qpd_vis_built \|\| qpd_adjacent) ? WPF_PTS_FSKUPD_NOCHANGE : WPF_PTS_FSKUPD_NEW;` | `fskupd` 的**唯一取值律**（`New` 只发给"组首且未见见证"） |
| P4 | `…win32_pts.c:7270-7271` | `pg->qpd_fstd_since = 0;` / `pg->qpd_new_pending = (fskupd == WPF_PTS_FSKUPD_NEW) ? 1 : 0;` | 判别器窗口**起算** ＋ 挂"待见证" |
| P5 | `…win32_pts.c:7290-7295` | `fprintf(stderr, "[QPD] rc=0 fskupd=%d first=%d adj=%d page=%p page_qpd=%d vis_built=%d …` | 机读留痕（`vis_built=`＝**P2 的读前值**） |
| P6 | `…win32_pts.c:8927` | `g_pts_fsp_live[i]->qpd_fstd_since++;` | `FsQueryTrackDetails` 的成功支**只增**（判别器第二格） |
| P7 | `…win32_pts.c:9033-9036` | `if (pg && pg->qpd_new_pending && pg->qpd_fstd_since == 1) {` / `pg->qpd_new_pending = 0;` / `pg->qpd_vis_built   = 1;` | **`vis_built` 的唯一置位点**（同处发 `[VIS]`） |
| P8 | `…win32_pts.c:7404-7406` | `pg->qpd_vis_built   = 0;` / `pg->qpd_new_pending = 0;` / `pg->qpd_fstd_since  = 0;` | **`FsClearUpdateInfoInPage` 归 0 点**（＝唯一复位点） |
| P9 | `build/PresentationFramework.Linux/PtsPage.Linux.cs:820` | `_section.StructuralCache?.ClearUpdateInfo(false);` | 上游 `OnAfterFormatPage` 收尾：**每趟格式后必清** ⇒ 必打 P8 |
| P10 | `…PtsPage.Linux.cs:1016` | `if (pageDetails.fskupd == PTS.FSKUPDATE.fskupdNoChange) { return; }` | 页视觉帧的**消费者闸**（`NoChange` ⇒ 零工作返回） |
| P11 | `…PtsPage.Linux.cs:1060` → `PtsHelper.Linux.cs:260` → `PtsHelper.Linux.cs:652` | `PtsHelper.UpdateTrackVisuals(…);` / `ParaListFromTrack(…);` / `PTS.Validate(PTS.FsQueryTrackParaList(…));` | **该置它的人**（页视觉帧 → 段列表 → `FsQueryTrackParaList`） |

### 2.2 四跳现取（`b10base`；同一页对象 `0x5b13422e4190`）

```
[QPD]   rc=0 fskupd=2 first=1 adj=0 page=0x5b13422e4190 page_qpd=1 vis_built=0 … seq=1456   ← P3/P5：给 New，挂 pending
[QPD]   rc=0 fskupd=1 first=0 adj=1 page=0x5b13422e4190 page_qpd=2 vis_built=0 … seq=1457   ← 组内后续 ⇒ NoChange
[QPD]   rc=0 fskupd=1 first=0 adj=1 page=0x5b13422e4190 page_qpd=3 vis_built=0 … seq=1458
[QPD]   rc=0 fskupd=2 first=0 adj=0 page=0x5b13422e4190 page_qpd=4 vis_built=0 … seq=1470   ← 新组首 ⇒ New（pending=1）
[VIS]   children=1 page=0x5b13422e4190 page_qpd=4 fstd_since_qpd=1 vis_n=5 seq=1472          ← P7：qpd_vis_built 0→1 ★真置位
[CLRUPD] rc=0 page=0x5b13422e4190 vis_built_before=1 new_pending_before=0 … seq=1482         ← P8/P9：★归 0（清前值现取=1）
[QPD]   rc=0 fskupd=2 first=0 adj=0 page=0x5b13422e4190 page_qpd=5 vis_built=0 … seq=1483   ← P2：读前值 ⇒ 0
```

⇒ **链是通的**：`QPD` 发 `New` → `QTD` 计一次（`qpd_fstd_since==1`）→ `QTPL` 认到页轨句柄 ⇒ **`[VIS]` 真发出**（`b10base` `vis_n` 至 6、`b10rev` 至 **239**）。**`[QPD]` 那句 `vis_built=0` 只是因为它在**同一次格式收尾**被 `CLRUPD` 清了**（`seq 1472` 置位、`seq 1482` 复位，中间只隔 10 个 seq）。

### 2.3 第一处断点（**不在 `vis_built`**）

`vis_built` 的置位**确已发生**（§2.2）⇒ 它**不是**断点。真断点在**其下游**：**页视觉已建 → 上屏帧**这一跳。四跳现取（`b10base`）：

| 跳 | 现取读数 | 判 |
|---|---|---|
| 分页器格式页 | `[CHAIN] site=DRIVE.EnsurePageVisuals site=FDPaginator.FormatPage page=…` ×4 | **到了** |
| 页视觉帧 | `[CHAIN] site=PTSP.UpdatePageVisuals size=…` ×5–6；`[CHAIN] site=PH.UpdateTrackVisuals` ×55 | **到了** |
| 段视觉 | `[CHAIN] site=PH.UpdateParaListVisuals n=…` ×170；`[CHAIN] site=RenderSimpleLines` ×60 | **到了**（行视觉对象已建） |
| **上屏帧** | 帧面：`tab2`／`tab3` **零具名色**（§1.3） | 🔴 **在这里断** |

⚠️ **如实划界**：第 3 跳的读数**归谁**（在屏页／后台预分页的**非在屏**文档）本侧**不可判**（承 `P1-tail2-linevis-impl-report.md` 的 `NOINFO-LINEVIS-NOT-ON-SCREEN`／`NOINFO-CHAIND-OWNER-OF-PAGINATOR`，本席**未独立复算**其读数）⇒ 记为 `NOINFO-3`。

---

## §3 ② `T-B9` 的"真断点"**证伪**（`[VIS]`↔`[CLRUPD]` 现取 **1:1**）

`T-B9` 报「`[QPD] … vis_built` 恒 0（`vis_built=0 ×1194 ； vis_built=1 ×1`）」并据此判「页视觉链不建起」。本席现取：**这是读法假象**。

**（a）`[VIS]` 与 `[CLRUPD]` 是一对一**（`b10rev` 现取）：

```
$ grep -c '^\[VIS\]'    app.log   ⇒ 239
$ grep -c '^\[CLRUPD\]' app.log   ⇒ 238
$ grep -o 'vis_built=[0-9]*' app.log | sort | uniq -c
   1190 vis_built=0
      1 vis_built=1        ← 唯一那次是"置位后、复位前"恰好插进一条 QPD
```

⇒ 每一个 `[VIS]`（置 1）后**紧跟**一个 `[CLRUPD]`（复位 0）⇒ `[QPD]` 读前值**必然**是 0。**"恒 0"不是链断，是`ClearUpdateInfo` 的正常语义**（`fskupd` 的稳态本来就要 `ClearUpdateInfo` 才重建；见 `win32_pts.c:7365-7374` 的口径注释）。

**（b）把"读数"推到 239，帧一字未动**（单变量：同一权威件 `.so 5e0d7b807c2fc220`，只差一个 env）：

| 面 | `b10base2`（缺省） | `b10rev`（`WPF_PTS_HANDLE_STRICT=0`） | 判 |
|---|---|---|---|
| `[VIS]` | **8** | **239** | **×29.9**（现取） |
| `[QPD]` | 42 | 1191 | ×28.4 |
| `[FS_PAGE_GAP]` | 3（`stale` 2 ＋ `unknown-breakrec` 1） | 1（`unknown-breakrec`） | ↓ |
| `[HC-UNHANDLED]` | 3 | 1 | ↓ |
| `Unrecoverable`／`alive`／`app_rc` | 0／yes／143 | 0／yes／143 | **不変** |
| **`tab2` 帧** | `1fb95eab89966441` | `1fb95eab89966441` | **逐字节相同** |
| **`tab3` 帧** | `0c51d1ad6fa46543` | `0c51d1ad6fa46543` | **逐字节相同** |

⇒ **`vis_built` 置位 239 次，画面仍空** ⇒ `vis_built` **不具备**"页视觉建起"的判别力（它是一个**帧内见证**，且被 `ClearUpdateInfo` 每趟清）；`T-B9` 把它读成"恒 0 ＝ 真断点"，**证伪**。

---

## §4 ③④ 修：两处候选**逐个真跑**（同一权威件；**最多 3 方案**）

### 4.1 方案（甲）· 页几何（`T-B8` 旧案）—— **在"同形腿"里重跑 ⇒ 仍被否证**

**为什么必须重跑**：`T-B8` 当年用 `order 2,3` 单腿比较，而本席现取证实 **`tab2` 帧跑次相关**（§1.2）⇒ 跨跑比较**不可靠**。本席改为**同形腿比较**（`b10base` 与 `e1_geo` 都是 212 形态：`[HC-UNHANDLED]` 均 **212**、`[FS_PAGE_GAP]` 均 **212**、`[CHAIN] size` 分布同族）。

改法（副本先行，scratch `~/tb10-work/exp1`，**仓内零写**）：

```
src/win32_pts.c:8948-8949
  #define WPF_PTS_FSP_FIN_DU  768            →  244800     （768 DIP × 300/96… 即以"文本 DPI 单位"表达 816 DIP）
  #define WPF_PTS_FSP_FIN_DV  576            →  316800
```

实验件 `d8c1bde109e962fb`。**改动真落到托管侧**（现取，同一读法）：

```
[CHAIN] site=PTSP.UpdatePageVisuals size=2.56x1.92   （b10base，×5）
[CHAIN] site=PTSP.UpdatePageVisuals size=816x1056    （e1_geo，×13；2.56x1.92 归零）
```

**帧面成对**：

| 面 | `b10base`（权威件） | `e1_geo`（页几何件） |
|---|---|---|
| `tab1` 帧 | `b440033da8b2a9e6` | `b440033da8b2a9e6` |
| **`tab2` 帧** | **`b440033da8b2a9e6`** | **`b440033da8b2a9e6`**（**逐字节相同**） |
| **`tab3` 帧** | **`0c51d1ad6fa46543`** | **`0c51d1ad6fa46543`**（**逐字节相同**） |

⇒ **页尺寸从 `2.56×1.92 DIP` 改到 `816×1056 DIP`（托管侧现取出证），上屏帧一字未变** ⇒ **(甲) 否证**（页几何**不是**分页视图空白的断点）。

### 4.2 方案（乙）· 陈旧 paraclient 收严（`T-B9` 案）—— **在现树重跑 ⇒ 也被否证**

见 §3(b)：`WPF_PTS_HANDLE_STRICT=0` ⇒ `[FS_PAGE_GAP] stale` **2→0**、`[HC-UNHANDLED]` **3→1**、`[VIS]` **8→239**，而 `tab2`／`tab3` 帧**逐字节不变** ⇒ **(乙) 否证**（收严**不是**空白的成因；且**撤它也没有净收益**）。

### 4.3 方案（丙）· 真断点 ＝ **页视觉已建 → 上屏帧** —— **本侧（现写域内）一跳不可修**

**现取结构对照（同一份 `.so`、同一帧内）**：

| 路径 | 控件 | 视觉宿主（件:行） | 帧面 |
|---|---|---|---|
| `tab1` 滚动 | `FlowDocumentScrollViewer` → **`FlowDocumentView`**（**移植件**） | `build/PresentationFramework.Linux/FlowDocumentView.Linux.cs:248` `AddVisualChild(_pageVisual);`（内容锚） | **画得出**（`colors=1078`、具名色齐） |
| `tab2` 单页 | `FlowDocumentPageViewer` → **`DocumentPageView`**（**上游件、无双侧补丁**） | `upstream/…/Controls/Primitives/DocumentPageView.cs:356` `this.AddVisualChild(_pageHost);` → `MS/Internal/documents/DocumentPageHost.cs:96` `this.AddVisualChild(pageVisualHost);` | **画不出** |
| `tab3` 查看器 | `FlowDocumentReader` → 同上 | 同上 | **画不出** |

⇒ **同帧同 `.so`**：**移植件那条链上屏；上游那条链不上屏**。⇒ 断点**落在"上游 `DocumentPageView`／`DocumentPageHost` 的视觉宿主在本移植的成帧面（composition）里没上去"这一跳**；其**前置** ＝ `PRECOND-FINITE-PAGE-ONSCREEN-COMPOSITION`（§8-5）。

**如实划界（为什么本席不就此改 `DocumentPageView`／`DocumentPageHost`）**：
1. 这两个件**不在本轮写域**：任务白名单是 `src/WpfGfx.Linux.Native/**`／`build/PresentationFramework.Linux/**`（**生成器与生成件**）／`build/PresentationCore.Linux/**`（同）。而 `DocumentPageView.cs`／`DocumentPageHost.cs` **既非上游生成件、也非本侧件**（现取：`ls build/PresentationFramework.Linux/*.Linux.cs` **无**二者；生成件命名律为 `<名>.Linux.cs`）。要动它们须**新增生成器改写面**（`reapply-patches.py` 的新补丁族）—— 那已越过"修一个断点"，是**给整条分页视觉宿主做移植**（面＝视觉树/布局/成帧三层的联调）。
2. 本侧**取不到**"该子树有没有进在屏树"的只读面（承 §2.3 的 `NOINFO-3`）⇒ **改完也无法在本轮内证成"真建起"**（只会又变成"计数前进 ≠ 可见前进"，正是 `T-A23`／本仓反复登记的那一族）。
3. `tab2` 帧的**跑次两形态**（`=tab1 画面`／`自己的空态`）说明**旧视觉摘除**这一环本身也是**竞态**（`NOINFO-2`）⇒ 即便把宿主接上，还得同趟解掉"旧子树摘除"。

⇒ **本增量判合法终点（失败）**，**不假成功**；具名前置与可实施替代见 §8-5／§8-6。

---

## §5 ② 帧面成对 ＋ 反极性（现取）

### 5.1 成对（同一权威件；四个单变量）

| 面 | `b10base` | `b10base2` | `e1_geo`（几何件） | `b10rev`（`STRICT=0`） |
|---|---|---|---|---|
| 单变量 | — | — | `FIN_DU/DV` | `WPF_PTS_HANDLE_STRICT` |
| `boot` | `b21eb530afd3c66c`／386 | 同 | 同 | 同 |
| `tab1` | `b440033da8b2a9e6`／1078 | 同 | 同 | 同 |
| **`tab2`** | **`b440033da8b2a9e6`／1078** | **`1fb95eab89966441`／551** | **`b440033da8b2a9e6`／1078** | **`1fb95eab89966441`／551** |
| **`tab3`** | **`0c51d1ad6fa46543`／562** | 同 | 同 | 同 |
| `[VIS]` | 6 | 8 | 7 | **239** |
| `[HC-UNHANDLED]` | 212 | 3 | 212 | 1 |
| `alive`／`app_rc` | yes／143 | yes／143 | yes／143 | yes／143 |
| `Unrecoverable` | 0 | 0 | 0 | 0 |

⚠️ **可比性（纪律 31/32）**：`b10base`↔`b10base2` 是**同件同装置两跑** ⇒ 只报"结果同／异"，**不相减**；`e1_geo` 只在**与 `b10base` 同形（均 212 形态）**时作单变量对照；`b10rev` 与 `b10base2` 均为 3/1 形态 ⇒ 可作单变量对照。**唯一可用作"反极性"的成对是 §3(b) 与 §4.1**。

### 5.2 反极性（可给者）

**（a）`vis_built` 极性（同一权威件，只差 env）**：`[VIS]` `8↔239`（+231）⇒ 帧**逐字节不变** ⇒ **"该绿不绿"**（证明 `vis_built` 不是可见面的判据）。
**（b）页几何极性（同形腿，只差实验件）**：`[CHAIN] size` `2.56x1.92↔816x1056` ⇒ 帧**逐字节不变** ⇒ **"该红不红"**（证明页几何不是断点）。
**（c）本增量仓内零产品件改动** ⇒ **无"撤修"腿可给** ⇒ 具名 `NOINFO(reason=no-shipped-fix-to-revert)`（同 `T-B9` §4.3 体例）。

---

## §6 ⑤ 门禁（逐条现取，本席跑的；仓内零产品件改动 ⇒ 即 `HEAD=330f9b7` 在册值）

| 牙 | 命令 | 读数 |
|---|---|---|
| `nm == exports` | `nm -D --defined-only …/libwpfwin32.so \| awk '{print $3}' \| sort` vs `bin/exports.txt` | **846 == 846**，`diff -q` 空 |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=5e0d7b807c2fc220 exports=846`**；`PTSGAP_CITED=PASS refs=1`；`PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTextDetails`；rc=0 |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2 fails=- cannot=- direction=in-file phase=realized`**；`PTS_G10_NAME=PASS`；`PTS_ENFE=PASS total=0`；rc=0 |
| `PTS_COLORANCHOR` | 同上（`k=24`） | **`PTS_COLORANCHOR=PASS k=24 hits=3`**（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`，`min=200`，基线全 0）**未回退**；`k=23` `NOINFO(no-anchor-registered-for-k23)` |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`**，`DEFREG_DECLDRIFT=0`，rc=0 |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=357 ids=2265 declared=225`**，rc=0（本载体落地**前**现取；落地后 ＋1 ＝本件） |

**未跑**：整趟 `verify-all`（照 `T-B10` ②）。

---

## §7 ④ 症状门（成对）＋ 具名 `NOINFO`

### 7.1 症状门

| 症状门 | `b10base` | `b10base2` | `e1_geo` | `b10rev` |
|---|---|---|---|---|
| `alive`／`app_rc` | yes／143 | yes／143 | yes／143 | yes／143（均**本席按 PID 收**） |
| `magenta` | 0 | 0 | 0 | 0 |
| `Unrecoverable system error` | 0 | 0 | 0 | 0 |
| `[HC-UNHANDLED]` | **212** | **3** | **212** | **1** |
| `[FS_PAGE_GAP]` | 212（`stale` 211 ＋ `unknown-breakrec` 1） | 3（2＋1） | 212（211＋1） | 1（`unknown-breakrec`） |
| `[FORMATLINE-LINE]` | 114 | 114 | 114 | 114 |
| `colors`（全屏） | boot=386／tab1=1078／tab2=1078／tab3=562 | …／tab2=551／tab3=562 | boot=386／tab1=1078／tab2=1078／tab3=562 | …／tab2=551／tab3=562 |

⚠️ **口径**：本报告**不**用"`FailFast` 字样计数"当症状门（`grep -c FailFast` 会把**守护接住的异常栈帧**也数进去：`b10base` 现取 `FailFast=211` 而 `Unrecoverable=0`／`alive=yes`）—— **唯一可信的"没死"读数是 `Unrecoverable=0 ∧ alive=yes`**（四腿全成立）。

### 7.2 具名 `NOINFO`（逐条给"消掉需要什么"）

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-1` | **"205／212 形态"跑次不可复现** | 同一权威件两跑：`b10base2` `[HC-UNHANDLED]=3`／`GAP=3`；`b10base` `212`／`212`。⇒ `T-B8` 的"205"与 `T-B9` 的"2"**都是同件的合法抽取**（不是"不可复现"，是**跑次相关**） | 找出发射侧的非确定性源（线程／GC／分页时序）并固化；本席**只报抽取** |
| `NOINFO-2` | **`tab2` 帧两形态（＝tab1 画面／自己的空态）的机制** | 同件两跑：`b10base`＝`b440033…`（tab1 画面）、`b10base2`＝`1fb95eab…`（空态） | 需一帧**"旧子树是否已从树摘除"**的只读见证；本席**未**读穿 |
| `NOINFO-3` | **第 3 跳（段视觉）归谁 ＋ `vis_built` 见证的"在屏性"** | 本侧**无**"在屏文档身份"面（承 `P1-tail2-linevis-impl-report.md` 两条 `NOINFO`，**未独立复算**） | 加一条"`FlowDocumentPaginator` 实例 ＝ 在屏 `DocumentPageView` 的那一个"的只读身份行 |
| `NOINFO-4` | **`[FSVIEW] visbounds=empty` 的语义** | `b10base` 现取：`[FSVIEW] site=ArrangeOverride … visbounds=empty` 仅 **1** 条（滚动腿）；对分段页无此面 | 给出 `visbounds` 的生产者定义 |
| `NOINFO-5` | **本增量无"撤修"反极性腿** | 仓内零产品件改动 ⇒ 无修可撤（§5.2-c） | 本轮不适用 |

---

## §8 ⑤ 边界 · 具名前置 · 收净 · 自证

1. **写域**：**仓内仅新增本载体** `build/MilBridge/P1-hcflowdoc3-impl-report.md`。`git status --porcelain` 现取：
   ```
   ?? build/MilBridge/P1-hcflowdoc-impl-report.md    （T-B8 载体，非本席所建）
   ?? build/MilBridge/P1-hcflowdoc2-impl-report.md   （T-B9 载体，非本席所建）
   ?? build/MilBridge/tasks-tail2/T-B8.md            （主控派单件，非本席所建）
   ?? build/MilBridge/tasks-tail2/T-B9.md            （主控派单件，非本席所建）
   ?? build/MilBridge/tasks-tail2/T-B10.md           （主控派单件，非本席所建）
   ```
   `git diff --stat` 现取**为空**；`win32_pts.c` 现取 `edaf0bf17ede9bb9`（＝ `HEAD` 侧现读值）；`libwpfwin32.so` 现取 `5e0d7b807c2fc220`（＝在册值）。
2. **副本先行／写前备份**：`~/tb10-work/bak/{win32_pts.c.orig,libwpfwin32.so.orig,exports.txt.orig}`（`cp -p`，取在**任何写之前**；`win32_pts.c.orig` ＝ `edaf0bf17ede9bb9`）。**实验件只在仓外 scratch** `~/tb10-work/exp1`（`d8c1bde109e962fb`），**未写仓内产品件**。
3. **仓外私有件（不在仓内）**：`~/tb10-work/{leg.sh,tabs.py,order.py,docink.py,analyze.py,overlap.py,collect.sh,logs/,bak/,exp1/}`；`leg.sh` 由 `~/tb9-work/leg.sh`（`sha16=d8f0e9c7fc428d87`）**逐字节复制**（`cp -p`）后**仅改一行**（`W=$HOME/tb9-work`→`W=$HOME/tb10-work`，`diff` 现取**仅此一处**）⇒ 本席件 `sha16=97c042b545b5b6ab`。
4. **重活走槽／收净**：四趟腿全在 `~/heavy-slot.sh --min-avail 1500 --max-hold 300 --wait 900` 内（`HEAVYSLOT=ACQUIRED … RELEASED rc=0`）；显示位只用空闲 `:236`（`~/tb10-work/xvfb.pid`＝`3087282`、`~/tb10-work/wm.pid`＝`3087286`，**按 PID 收净**）；`ps -eo pid,comm | grep -i handy` 现取无输出；`/tmp/.X11-unix/` 现取只剩 `X0/X1/X11`（非本席）。
5. **具名前置（本轮写域外／面过大）**：
   - **`PRECOND-FINITE-PAGE-ONSCREEN-COMPOSITION`**（本席新立，＝ §4.3 的真断点）：使 `DocumentPageView` → `DocumentPageHost` → 页 `ContainerVisual` 那条**上游**宿主链在本移植的**成帧面**上真上屏（同帧内 `FlowDocumentView` 那条**移植**链上屏正常 ⇒ 这是**两条链的差**，不是"渲染层全坏"）。
   - **`PRECOND-PAGE-VISUAL-IDENTITY`**（消 `NOINFO-3`）：一条"格式／分页的那份文档 ＝ 在屏 `DocumentPageView` 的那一份"的只读身份面 —— **否则任何"链前进"都不能据以判"可见前进"**。
   - **`PRECOND-FLOAT-AVOIDANCE`**（承 `T-B8` 缺陷②，本席**未复核**）：`tab1` 的浮动盒遮挡仍在（`Figure`／`Floater` 与正文行带共 y）。
6. **可实施替代（若有）**：
   - **(i) 先做 `PRECOND-PAGE-VISUAL-IDENTITY`**（低成本、只加只读面）：在 `FlowDocumentPaginator` 与 `DocumentPageView` 上各打一行"实例身份 ＋ 当前文档身份"，**同趟**与帧面并取。**判据可证伪**：若两侧身份**不等** ⇒ 断点在"谁在被分页"（不是宿主链）；若**相等**且帧仍空 ⇒ 断点**锁定**在宿主链 ⇒ 才轮到 (ii)。
   - **(ii) 移植 `DocumentPageView`／`DocumentPageHost` 的视觉宿主**（`P8`：须在 `reapply-patches.py` 新增补丁族，产出二者 `.Linux.cs`），**照 `FlowDocumentView.Linux.cs:248` 的既有可用形态**做最小对齐（`AddVisualChild` ＋ `Offset`／显式 `Measure/Arrange`），**同趟**给反极性腿（关补丁 ⇒ 帧回退）。
   - ⚠️ **不要**再走"页几何／句柄收严"两条（本席已各真跑一次、均**逐字节不变**）。
7. **黑名单未碰**：`upstream/**`（**只读**）／仓外 hc 工程（**只读**）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只调不改**）。**未跑整趟 `verify-all`**、**未跑 `static-jaws-check.sh`**。
8. **app-local 逐件复原（任务点名的硬边界）**：实验腿用 `TB8_SHIM_SRC` 刷过 app-local 的 `libwpfwin32.so`，腿后已 `cp -p` **复原** ⇒ 现取五件：`libwpfwin32.so=5e0d7b807c2fc220`／`wpfgfx_cor3.so=a7a0f884b704ca96`／`PresentationCore.dll=1bcc64cfe83ff77b`／`PresentationFramework.dll=48daaeb326c4aa8b`／`WindowsBase.dll=a4ef8af0ccccb247`，其中 `libwpfwin32.so` **＝仓内权威件现读值**。
9. **纪律自证**：重活走槽；显示位只用空闲 `:236`；`temp+rename`（本载体）；**报数一律现取**（纪律 40）；`T-B3` 的收严**一字未动**（`git diff` 空）；**未跑整趟门禁**。

SELF-SHA16（口径 ＝ `head -n -1 build/MilBridge/P1-hcflowdoc3-impl-report.md | sha256sum | cut -c1-16`）＝ **`e50aa72613b3e701`**（本行下方无内容，取该行之前全文的哈希）。

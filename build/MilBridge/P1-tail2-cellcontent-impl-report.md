# `P1-tail2` · `T-A56` · 表单元内容排版（`pfnFormatCellFinite`／`FSTABLECBKCELL` 单元槽）—— 实现报告（**判决：判据 ① 已达 —— 开闸腿（`WPF_PTS_TABLECELL=1`）单元格内容真落像素（表区 `dark(<140)` `+1449 px`，其中新 goldenrod 行带内 `+1223 px`）∧ 缺省腿逐字节零回归 ∧ 门禁全绿 ∧ 反极性该红必红**）

- **读时**：`2026-10-01T10:5x–11:2x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=2e08b27`（＝ `T-A55` 收尾那笔；**未换代**）。
- **改前件备份（仓外 `~/tA56-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`a40e5b86bdfa0011`）／`exports.txt`（`c7a1298c812e4e31`）／`pts-gap-decl.txt`（`d000c8c41565e7fa`）／`reapply-patches.py`（`b6a3a24137a77ddf`）。
  ⚠️ **纪律 6 的如实自纠**：本趟**只**对上面四件做了"写前 `cp -p`"；**复述位现值位六件**（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）的"写前副本"**当时未取**——本席事后用 `git show HEAD:<path>` **补取真改前件**（`HEAD=2e08b27` 未被换代、工作树无他人改动 ⇒ 那六枚即真改前值；落在 `~/tA56-work/bak/HEAD/`）。**这不是"备份成功"，是"备份补取"**，如实记。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**七处**：闸 ＋ cell 槽/原型 ＋ 窗内单元驱动 ＋ 内容台账高 ＋ 行高派生 ＋ `FsQueryTableObjRowDetails`／`FsQueryTableObjCellList`（**ABI 修正**）＋ 新增导出 `FsClearUpdateInfoInSubpage`）／`bin/exports.txt`（**由 `build-shim.sh --symbols` 重产**；`bin/` 在 `.gitignore` ⇒ **非仓内件**，见 §5.6）／`tools/pts-gap-decl.txt`（DECL 行 ＋ dated 追注）／**复述位现值位**（上列六件）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（**生成器一字未动**；`sha16` 仍 `b6a3a24137a77ddf`）⇒ 其重产件亦未动（`PresentationFramework.dll` 仍 `1c6c58df6d757f3f`）—— 本增量全在 native（托管链 `T-A52`／`T-A53` 已备，**无需托管改动**）。
- **黑名单遵守**：未动 `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**8 趟 native 构建**（各 `< 5 s`）＋ **9 趟跑器**（共 **20 条腿**；全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`）；进程只按 PID；显示位只用空闲 `:23x`（`DISPLAY_PICK :231`，逐趟 `DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p`；temp+rename；模式守恒。**收尾现取**：重活槽 `SLOT=FREE`；`/tmp/.X231-lock` 一处**本席自己**被 `timeout` 杀趟留下的残锁已按 PID 核死后清除（**不**用 `pkill`）。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`grep -c`／只读 `python3`＋`PIL` 解 PNG／`compare -metric AE`／`bash build/MilBridge/tools/{pts-pages-guard,pts-gap-count-check,defect-registry-check,report-id-domain-check,handoff-machine-values-check,sentinel-spec-check}.sh`／`bash ~/w153a/bin/infp.sh`）。

---

## §0 结论速览（自包含）

1. ✅ **判据 ① 已达（关键）**：**开闸腿**（`WPF_PTS_TABLECELL=1`）`k=24` 的**表区**（`x410..750,y150..250`）里 `dark(<140)` 像素 **`2869 → 4318`（+1449）**，其中**新 goldenrod 行带**（`y181..234`）内 **`1735 → 2958`（+1223）**（＝ `Mean Distance from Sun`／`4,504,000,000 km`／`Approximate Mass`／`1.0247e26 kg` 四条单元文本）；`colors 910 → 1220`、`LightGoldenrodYellow 1998 → 5830`（行高由单元内容高派生 ⇒ 行带 `y166..180`→`y181..234`）；`PTS_GUARD=PASS`、`PTS_COLORANCHOR=PASS k=24 hits=3`。
2. ✅ **单元内容真排版（逐格真发调三托管回调）**：`pfnGetCells`（槽 17）取 `nmCell` ⇒ `pfnFormatCellFinite`（槽 20）**真造**单元内容子页 ⇒ `pfnSetCellHeight`（槽 25）把行高告知单元。现取（`[FSTABLECELL]` **16** 条＝2 窗 × 8 格）：`row=… i=0 nmCell=… cell=… subpage=… rc=0 v=CELL-SUBPAGE`；行高 `[FSTABLEOBJ-ROW] … cCells=1/2/2/2/1 nCells=1/2/2/2/1 dvr=5691/5691/5691/5691/4992`（＝ `Σ(ascent+descent)` 台账 ＋ `dvrAboveRow+dvrBelowRow`，**非**本侧旧约定值 `1500`）。
3. ✅ **缺省路径零回归（新增闸缺省关）**：新增运行期闸 `WPF_PTS_TABLECELL` **缺省 `0`（关）** ⇒ 缺省腿与改前**逐字节同**：`k24 fr_sha=64603fc1d8e23e39 colors=910`（`GhostWhite=18945`／`Beige=910`／`DarkGreen=44`／`LightGoldenrodYellow=1998`）、`k23 fr_sha=10d0b9d54e649c10`、`boot fr_sha=b21eb530afd3c66c`；`[FSTABLECELL]=0`／`FS_CLRUPD=0`／`[FSTABLEOBJ-ROW] … nCells=0 dvr=1500`／`FsQueryTableObjRowDetails … cCells=0`；`PTS_GUARD=PASS`、`PTS_COLORANCHOR=PASS hits=3`、`[HC-UNHANDLED]=0`、`entry point named=0`。
4. ✅ **两处 native 真缺陷同趟修好（都是"单元真排版后才暴露"）**：
   - **①`FsQueryTableObjCellList` ABI 错位**：改前本侧是 **6 参**且顺序不同（`…, void *rgCell, int *pcCellsActual, void *rgCellMerge`），上游（`Pts.cs:3843-3850`）是 **7 参**（`…, FSKUPDATE* rgfskupd, IntPtr* rgpfscell, FSTABLEKCELLMERGE* rgkcellmerge, out int pcCellsActual`）。该错位**从未触发**（行详情恒报 `cCells=0` ⇒ 托管不调本入口）⇒ 本增量让行详情报真 `cCells` ⇒ **必须先把 ABI 对齐**。
   - **②`FsClearUpdateInfoInSubpage` 未导出**：调用点 `CellParaClient.Arrange:119`（单元真排版后**必调**）。首趟开闸腿现取 `entry point named 'FsClearUpdateInfoInSubpage'` **335** 条 ⇒ `ArrangeOverride` 抛 ⇒ **整页空白**（`colors=383`／`fr_sha=ef3fd6765f18f51b` ∈ 空态集）。**已导出并真实现**（`exports 688→689`）。
5. ✅ **`pfnSetCellHeight` 只许窗内发调（实测逼出）**：首版把它放在**查询期** `FsQueryTableObjRowList` 里 ⇒ 撞 `PtsHost.get_PtsContext()` 的 `Invariant.FailFast` ⇒ `app_rc=134`／进程死（现取证：栈 `PtsHost.SetCellHeight ← PTS.FsQueryTableObjRowList ← TableParaClient.QueryTableDetails ← … GetTextContentRange`）。改法：**窗内**先把单元内容子树**真驱一次 `pfnFormatLine`**（`wpf_pts_fl_walk_c`）拿到真台账 ⇒ 定行高 ⇒ 同窗内 `pfnSetCellHeight`。查询期只**只读回填**同一台账值。
6. ✅ **反极性（该红必红）**：`WPF_PTS_TABLEOBJ=0`（`polT`）⇒ 无表模型 ⇒ `FsQueryTableObjDetails` 诚实拒 ⇒ 整页空白（`colors=383 fr_sha=ef3fd6765f18f51b`）⇒ **`PTS_GUARD=FAIL`／`PTS_COLORANCHOR=FAIL hits=0`**。`WPF_PTS_TABLECELL=0`（`pol0`）⇒ 与缺省**逐字节同**（`fr_sha=64603fc1d8e23e39`）。`WPF_PTS_FLOATER_CBK=0`（`polF`）⇒ 第 4 色回 `0`（`hits=2`，与 `T-A52`／`T-A54` 同值）。
7. ✅ **门禁**：`nm -D --defined-only` ＝ `exports.txt` ＝ **689**（逐名 `diff` 零差异）｜`PTSGAP=PASS tool=70 dead=11 artifact=1 ops=58 impl=59 so16=193e20c8b483ea3d exports=689`（`rc=0`）｜`DEFREG=PASS declared=225 route_ids=225`（`rc=0`；`DECLDRIFT=1 keys=KD`）｜`REPORTID=PASS`（`rc=0`）｜`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`（`rc=0`）。
8. 🔴 **具名下一靶（本趟如实划界，见 §5）**：① **行高只是"内容子页高"的**本侧**派生**（`Σ` 行 `av+desc` ＋ 行上下距），**不**等同于上游 PTS 的行距/边界模型；② **单元框线的边界**（`FSTABLEROWDETAILS.fskboundaryAbove/Below` 恒报 `Outer`、`dvrAbove/Below=0`）未按真实行边界填；③ **`WPF_PTS_TABLECELL` 的缺省翻转**留待"① ② 落地且无回归"后按 `T-A28→T-A31` 体例做。

---

## §0.5 三方案（逐趟读数驱动的收敛；**上限 3**，未超）

| 方案 | 形态 | 现取读数 | 判决 |
|---|---|---|---|
| **1** | 只在窗内调 `pfnGetCells`＋`pfnFormatCellFinite`，行高用其 `dvrUsed`；`FsQueryTableObjRowDetails` 报真 `cCells`；`FsQueryTableObjCellList` 修 ABI | `[FSTABLECELL] v=CELL-SUBPAGE` ×16 **成功**，但 `entry point named 'FsClearUpdateInfoInSubpage'` **335** ⇒ 整页空白（`colors=383`） | ❌ **受阻**（缺符号）|
| **2** | ＋导出 `FsClearUpdateInfoInSubpage`；行高＝`dvrUsed`（＝30000）⇒ `dvr=31500`；`pfnSetCellHeight` 在**查询期**补调 | 页面活了，但 `LightGoldenrodYellow 1998→0`（行高 105 DIP ⇒ goldenrod 两行被挤出窗口）；且查询期 `SetCellHeight` 撞 `PtsHost.get_PtsContext()` **`FailFast`（`app_rc=134`）** | ❌ 两处不成立 |
| **3** | 行高改由**单元内容台账**派生（窗内先 `wpf_pts_fl_walk_c` 真排行 ⇒ `Σ(av+desc)`）；`pfnSetCellHeight` **只窗内**发调；查询期只只读回填 | `dvr=5691/5691/5691/5691/4992`；`PTS_GUARD=PASS`、`hits=3`、表区 `dark +1449 px`、`AE(k23)=0` | ✅ **达** |

---

## §1 断点逐跳（从 `T-A53` 的具名前沿到本趟）

| 跳 | 件:行（内容锚） | 现取 |
|---|---|---|
| ① `T-A53` 的具名前沿 | `P1-tail2-tableobj-impl-report.md` §6：**表单元内容排版**（调 `pfnFormatCellFinite`（槽 20）为每格真造内容子页；把 `cCells`／`CellList` 填真值） | 本趟落地 |
| ② 取单元句柄 | 托管 `PtsHost.GetCells`（`PtsHost.cs:3765`）→ `RowParagraph.GetCells`（`RowParagraph.cs:216`，`_cellParagraphs[j].Handle`） | ✅ 本侧窗内 `pfnGetCells`（槽 17）真发调 |
| ③ 单元内容排版 | 托管 `PtsHost.FormatCellFinite`（`PtsHost.cs:3862`）→ `CellParagraph.FormatCellFinite`（`CellParagraph.cs:51`）→ `CellParaClient.FormatCellFinite` ⇒ **`CellParagraph.FormatParaFinite` ⇒ `PTS.FsCreateSubpageFinite`**（`SubpageParagraph.cs:206`） | ✅ 本侧 `FsCreateSubpageFinite` **真造**单元内容子页（`[FSTABLECELL] … v=CELL-SUBPAGE` ×16） |
| ④ 单元高告知 | 托管 `PtsHost.SetCellHeight`（`PtsHost.cs:4015`）→ `CellParaClient.ArrangeHeight` | ✅ 本侧**窗内** `pfnSetCellHeight`（槽 25）；行高＝单元内容台账派生值 |
| ⑤ 行详情（`cCells`） | `TableParaClient.QueryRowDetails`（`TableParaClient.cs:1420`）→ `FsQueryTableObjRowDetails` | ✅ 现取 `cCells=1/2/2/2/1 v=cells-laid-out`（改前恒 `0`） |
| ⑥ 单元列 | 同上 → `FsQueryTableObjCellList`（上游 **7 参**） | ✅ **ABI 修正**后真填；现取 `asked=1 filled=1`／`asked=2 filled=2` |
| ⑦ 单元视觉 | `TableParaClient.ValidateRowVisualSimple/Complex`（`:1523`／`:1629`）⇒ `CellParaClient.ValidateVisual`／`Arrange` | ✅ 现取 `[HC-UNHANDLED]=0`、`FS_PAGE_GAP=0`、`entry point named=0`；`FS_CLRUPD`（`CellParaClient.Arrange:119`）**1832** 条全成功 |
| ⑧ 单元内容绘出 | `SubpageParaClient.ValidateVisual` ⇒ 内容轨 ⇒ 文本行 | ✅ 表区 `dark(<140)` `+1449 px`（判定见 §3.3） |

⇒ `T-A53` 的诚实前沿（**表单元内容排版**）**在本趟解**；单元内文本**真达像素**。

---

## §2 改动（逐处；全部在 `win32_pts.c`，附导出面重产）

### 2.1 单元槽／原型（内容锚「`T-A56`：`FSTABLECBKCELL`（14 槽）余槽号」块）
照 `Pts.cs:1736-1752` 逐槽：`20 pfnFormatCellFinite`／`25 pfnSetCellHeight`（`FSTABLECBKCELL` 基址 ＝ `FSTABLEOBJCBK(5)+FSTABLECBKFETCH(15)` ＝ 20）。三个托管回调的 C 侧原型照 `Pts.cs:2953-2958`／`:2973-2987`／`:3012-3019` **逐参**（`FSFMTR`＝3×int＝12 B）。

### 2.2 本侧表模型的**单元槽**（`wpf_pts_tbl_cell`）
每格记：`nm_cell`（`CellParagraph` 句柄，`pfnGetCells` 真返回）／`pfscell`（`CellParaClient` 句柄，`pfnFormatCellFinite` 真返回）／`sub_obj`（**本侧**单元内容子页对象）／`kcellmerge`／`fskupd`／`fmt_rc`／`dvr_used`（⚠️ 本侧 `FsCreateSubpageFinite` 恒报 `dvrUsed=lHeight` ⇒ **不是**内容真高，**只作诊断**）。行结构新增 `dvr_above`／`dvr_below`（`FSTABLEROWPROPS` 原值）与 `n_cells`（**真排出的**单元数；未排／失败 ⇒ `0`）。

### 2.3 运行期闸（**新增 ⇒ 缺省关**）
`wpf_pts_tablecell_gate()`：`WPF_PTS_TABLECELL_DEFAULT 0`（关）；显式 `=1` 才开。硬边界「新增/变更闸缺省按已验证状态定」⇒ 本闸是**新增行为** ⇒ **缺省关**，缺省路径与改前**逐格相同**（§3.1 成对读数给出证据）。

### 2.4 窗内单元驱动（`wpf_pts_tableobj_drive` 的行循环内）
`gate ∧ cCells>0 ∧ 两槽在位` 时逐格：① `pfnGetCells(fsclient, row, cCells, rgnmCell, rgkcellmerge)`；② `pfnFormatCellFinite(fsclient, tclient, NULL, nmCell, NULL, fEmptyOk=1, fswdir=0, dvrExtraHeight=0, dvrAvailable=30000, fsfmtr[3], &pfscell, &brkout, &dvrUsed)`；③ 记 `sub_obj`（`g_pts_sp_created` 增量 ＋ 栈顶）。**零假值**：`pfnGetCells rc≠0`／任一格 `rc≠0` 或 `pfscell==NULL` ⇒ **本行 `n_cells=0`**（**不记**，行详情仍报 `cCells=0` 的**诚实的空**）。

### 2.5 行高**由单元内容台账派生**（新 `wpf_pts_tbl_cell_tree_dv`／`wpf_pts_tbl_row_dvr`）
单元内容子页的**内容树**逐**叶段**（`enum_ok==0`，即 `TextParagraph` 类）按 `pfnFormatLine` **真台账**（`fl_ok==1 ∧ fl_nlines>0 ∧ fl_complete ∧ !fl_truncated`）累加 `Σ(dvrAscent+dvrDescent)`（**同** `FsQuerySubtrackParaList` 对内容段的口径）；行高 ＝ `max(单元内容高)+dvrAboveRow+dvrBelowRow`（不足本侧下界 `200` 取下界）。**零假值**：台账不可用 ⇒ **退回**旧约定值并**具名** `v=NO-LINE-LEDGER action=row-height-fallback`（**不**假造高）。

### 2.6 `FsClearUpdateInfoInSubpage`（**新导出**；2 参）
按**本侧对象身份**认领（`wpf_pts_sp_claim_track`）后返 `rc=0` ＋ `[FS_CLRUPD]` 行；空／未知句柄 ⇒ **诚实拒**（`-10000` ＋ 具名 `[FS_PAGE_GAP]`）。⚠️ **语义边界**：本侧 `FsQuerySubpageDetails` **恒报首态** `fskupd=New` ⇒ "清更新信息"在这里**无需改状态**（下次查询仍是 `New` ⇒ 托管重建视觉；**不**冒充稳态 `NoChange`，行尾具名 `NOINFO=query-always-first-state(New)`）。

### 2.7 `FsQueryTableObjRowDetails`／`FsQueryTableObjCellList`
- 行详情：`c_cells` 由恒 `0` 改为 **`r->n_cells` 真值**（`v=cells-laid-out|cells-not-laid-out` 两态具名）。
- 单元列：**ABI 修正为 7 参**（见 §0.4）＋ 逐格填 `rgfskupd`（`fskupdNew`）／`rgpfscell`（真 `CellParaClient` 句柄）／`rgkcellmerge`（`pfnGetCells` 原值）／`*pcCellsActual`。无模型／无该行 ⇒ 诚实拒。

### 2.8 复述位现值位（只读改数；**无新增 D-G 编号**）
`D-G70` 在册数随权威件跟随：`tool 71→70`／`ops 59→58`／`impl 60→59`（＝ `FsClearUpdateInfoInSubpage` 由"会 `EntryPointNotFoundException` 的缺口"变"已导出可用"）、`exports 688→689`、`so16 →193e20c8b483ea3d`。逐件：`docs/ROUTES.md`（3 处）／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（2 处）／`build/MilBridge/HANDOFF-NEXT.md`（现值位 ＋ `cell=#1` 指纹更正行）／`src/WpfGfx.Linux.Native/src/win32_classification.c`。**历史 dated 行原文保留**（判据件的"自引旧代锚 ＋ dated 措辞"分类法）。

### 2.9 为什么**不是**改生成器
本轮**一个字节都没碰** `reapply-patches.py` 与其重产件 —— 本增量全在 native（托管的 `FormatCellFinite`／`SetCellHeight`／`CellParaClient` 链在上游就有，本侧只是**开始用**它们）。

---

## §3 成对读数（**同一 `.so 193e20c8b483ea3d`／同一 `pf 1c6c58df6d757f3f`／同装置 `:231`／同批工具**）

| 腿 | env | 证据目录 |
|---|---|---|
| `default2`（缺省） | 不设 env（`TABLECELL` 缺省 `0`） | `~/tA56-work/legs/default2/` |
| `cell1`（开闸） | `WPF_PTS_TABLECELL=1` | `~/tA56-work/legs/cell1/` |
| `pol0`（新闸反极） | `WPF_PTS_TABLECELL=0` | `~/tA56-work/legs/pol0/` |
| `polT`（旧闸反极） | `WPF_PTS_TABLEOBJ=0` | `~/tA56-work/legs/polT/` |
| `polF`（旧闸反极） | `WPF_PTS_FLOATER_CBK=0` | `~/tA56-work/legs/polF/` |

### 3.1 逐腿现取计数（`grep -c`，`app_g1.log`）

| 量 | `default2`（缺省） | **`cell1`（驱动）** | `pol0` | `polT` | `polF` |
|---|---|---|---|---|---|
| `[FSTABLEOBJ-CBK]` | 2 | **2** | 2 | 0 | 2 |
| `[FSTABLEOBJ-DRV]` | 2 | **2** | 2 | 0 | 2 |
| `[FSTABLECELL] … v=CELL-SUBPAGE` | **0** | **16**（2 窗 × 8 格） | 0 | 0 | 0 |
| `[FSTABLEOBJ-ROW]` | 10（`nCells=0 dvr=1500`） | **10**（`nCells=1/2/2/2/1 dvr=5691…`） | 10 | 0 | 10 |
| `[FSTABLEOBJ-Q]` | 9111 | **10965** | 9111 | 0 | 9111 |
| `FS_CLRUPD`（`CellParaClient.Arrange` 入口） | **0** | **1832** | 0 | 0 | 0 |
| `FS_PAGE_GAP` | 0 | **0** | 0 | 0 | 0 |
| `[HC-UNHANDLED]` | 0 | **0** | 0 | 0 | 0 |
| `entry point named` | 0 | **0** | 0 | 0 | 0 |

### 3.2 帧面（逐腿现取：`leg_*.env` ＋ 只读 PNG）

| 腿 | `alive` | `app_rc` | `magenta` | `colors`(k24) | `ink` | `k24` `fr_sha` | `k23` `fr_sha` | `boot` `fr_sha` |
|---|---|---|---|---|---|---|---|---|
| **`default2`** | yes | 143 | 0 | **910** | 480000 | **`64603fc1d8e23e39`** | `10d0b9d54e649c10` | `b21eb530afd3c66c` |
| **`cell1`** | yes | 143 | 0 | **1220** | 480000 | **`0bdb2dfd05952bc9`** | `10d0b9d54e649c10` | `b21eb530afd3c66c` |
| `pol0` | yes | 143 | 0 | `910` | 480000 | `64603fc1d8e23e39` | `10d0b9d54e649c10` | `b21eb530afd3c66c` |
| `polT` | yes | 143 | 0 | **383** | 480000 | `ef3fd6765f18f51b`（空态参照成员） | `10d0b9d54e649c10` | `b21eb530afd3c66c` |
| `polF` | yes | 143 | 0 | `905` | 480000 | `791696291d51470b` | `10d0b9d54e649c10` | `b21eb530afd3c66c` |

**帧差（本席自算，只读 PNG）**：`AE(default2_k23, cell1_k23)=0`、**`AE(default2_k24, cell1_k24)=15831`**、`AE(default2_k24, pol0_k24)=0` ⇒ 位移**只落在被驱动的那一页**，且**新闸关 ⇒ 逐字节同**。

**跨代零回归（本席自算，只读 PNG；`default2` ↔ `T-A54` 的缺省腿 `~/tA54-work/legs/default/`）**：**`AE(k24)=0`／`AE(k23)=0`／`AE(boot)=0`** ⇒ 缺省路径三帧与**改前（`T-A54` 收尾那一代）**逐字节相同。

### 3.3 帧面四色锚 ＋ 单元文本像素（**本席自算**，只读 PNG；锚集 `GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`）

| 帧 | 腿 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `ncolors` |
|---|---|---|---|---|---|---|
| `k24` | `default2` | **18945** | **910** | **44** | **1998** | **910** |
| `k24` | **`cell1`** | **9794** | **910** | **44** | **5830** | **1220** |
| `k24` | `polT` | 0 | 0 | 0 | 0（反极） | 383 |

**单元文本像素（本席自算；判据①的承重读数）**：

| 区（`k24`，`x410..750`） | `default2` | **`cell1`** | 位移 |
|---|---|---|---|
| 新 goldenrod 行带 `y181..234` 的 `dark(<140)` | 1735 | **2958** | **+1223** |
| 第 1 行带 `y153..181` 的 `dark(<140)` | 262 | **486** | **+224** |
| 整表区 `y150..250` 的 `dark(<140)` | 2869 | **4318** | **+1449** |
| `LightGoldenrodYellow` 行带 | `y166..180`（15 px 高） | **`y181..234`（54 px 高）** | 行高由单元内容高派生 |
| `LightGray`（同区） | 1126 | **3548** | 行 3 背景随行高变大 |

> ⚠️ **归因（逐条）**：`GhostWhite↓`／`LightGoldenrodYellow↑`／`LightGray↑` 三条 ⇒ **行高由单元内容高派生**（`dvr 1500→5691/4992`）；`dark(<140) +1449` ⇒ **单元内文本真绘**；`colors 910→1220` ⇒ 上述两者的抗锯齿新色。**不许**把"空白"读成绿：`polT` 那趟 `ink=480000` 但四色全 `0` ⇒ 判据件按 `COLOR-ANCHOR-ABSENT` **判红**（§3.4）。

### 3.4 判据件读数（`pts-pages-guard.sh --legs`；纯读、零 `dotnet`）

```
# default2（缺省）
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=18945 Beige=910 DarkGreen=44 LightGoldenrodYellow=1998 hits=3 …
PTS_ENFE=PASS total=0 …
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=realized
# cell1（开闸）
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830 hits=3 …
PTS_ENFE=PASS total=0 …
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg24-colors-out-of-band=1220,leg23-colors-out-of-band=636 direction=in-file phase=realized
# polT（旧闸反极 —— 该红必红）
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 … reason=declared-color-anchor-absent
PTS_GUARD=FAIL legs=2/2 fails=leg24-n1-frame-unestablished(frame-identity(sha16=ef3fd6765f18f51b∈{…})),leg24-color-anchor-absent(hits=0<2,…) …
```

### 3.5 门禁（现取）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **689** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=70 dead=11 artifact=1 ops=58 impl=59 so16=193e20c8b483ea3d exports=689` | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`（`DECLDRIFT=1 keys=KD`：复述位件已随动，**`declared.tsv --emit` 落在黑名单 `build/MilBridge/tools/**` ⇒ 未重发**，如实记） | 0 |
| `REPORTID` | `PASS`（本件落盘后重跑，`rc=0`） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0 uncomparable=0`（本趟追写 `cell=#1` 指纹更正行） | 0 |
| `SSC` | **`FAIL`**（`SSC_VALUE=FAIL key=WIN32SHIM got=642019f680d75d87 want=193e20c8b483ea3d`）—— 哨兵件在 `$HOME/wfp-runs/`／`/tmp`（**仓外**）且其唯一写入路径是 `build/MilBridge/tools/wave-push.sh`（**本任务黑名单**）⇒ 本趟**不手改**；**如实留痕**（`T-A56` 验收 ④ 不含 `SSC`） | 1 |

---

## §4 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `a40e5b86bdfa0011` | **`3727a8df1399a337`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `642019f680d75d87`（462648 B） | **`193e20c8b483ea3d`**（467240 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `c7a1298c812e4e31`（688 行） | **`005b16e0cd5b95b2`**（689 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `d000c8c41565e7fa` | **`491d439b4e509450`** |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `088300256ed9139d` | **`74b5247e5ee6c4d0`** |
| `docs/ROUTES.md` | `a9bf09ad6ef9dff7` | **`8e29067012871734`** |
| `README.md` | `7566fb24e0dd8d72` | **`3415d52fad3cba90`** |
| `docs/unimplemented.md` | `19b9cc16a237a827` | **`fdb221d64f8b8b69`** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `e47d8967e27366cc` | **`b867c2eac90dde81`** |
| `build/MilBridge/HANDOFF-NEXT.md` | `a7ea1137f49d078c` | **`8a920ee23c358591`** |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `b6a3a24137a77ddf` | **未变** |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `1c6c58df6d757f3f` | **未变** |

---

## §5 诚实边界（防读宽，逐条）

1. **"单元内容落像素"只证"表区里多出 1449 px 深色（<140）像素"，不证"与上游 PTS 的排印完全一致"**：本侧单元内容走的是**本侧** `FsCreateSubpageFinite` ＋ 本侧行台账；行高、断开、行距都是本侧派生。**不**声称 ABI/几何与上游可比。
2. **行高是"内容子页高"的派生值**：`max(单元内容高) + dvrAboveRow + dvrBelowRow`（`dvrAboveRow=dvrBelowRow=dvrAboveBelow`，`RowParagraph.GetRowProperties:130-131` 逐字——**两者同值**是本侧读数，不是本侧自造）。台账不可用 ⇒ **退回** `1500` 并具名（**不**假造）。⚠️ **未**声称与上游 `dvrRow` 语义等同。
3. **`pfnFormatCellFinite` 的 `dvrUsed` 被本侧**弃用**（只进诊断字段）**：本侧 `FsCreateSubpageFinite` 恒报 `dvrUsed=lHeight`（= 传入 `dvrAvailable`）⇒ 它**不是**内容真高。这是**本侧子页实现的既有约定**（`T-A37` 起），本席**如实**改用它处而不当行高源。
4. **`pfnSetCellHeight` 的调用时机是本侧为该移植选定的**（**窗内**）。真因是实测：查询期调它撞 `PtsHost.get_PtsContext()` 的 `Invariant.FailFast`（**进程死**，`app_rc=134`）。本侧**不**声称与上游 PTS 的 `SetCellHeight` 时机相同。
5. **单元边界面未做**：`FSTABLEROWDETAILS.fskboundaryAbove/Below` 仍恒报 `fsktablerowboundaryOuter(0)`、`dvrAbove/Below=0`（未按真实行边界填）；`fForcedRow=0`。⇒ 分页/断行场景**未验证**（本页是有限窗、不跨页）。
6. **`bin/exports.txt` 非仓内件**：`src/WpfGfx.Linux.Native/bin/` 在 `.gitignore` ⇒ 该件由 `build-shim.sh --symbols` **每次重产**；`nm==exports` 是**构建不变量**（不是"我们手工对齐了一份表"）。
7. **缺省腿的**帧面可变性**（如实记，非本增量引入）**：本批第一趟 `run-legs5` 的 `default` 腿现取 `fr_sha=14725a95dcd4427f colors=909`（`k23` 亦为 `94933b5a37d1c537`），与规范值不同；差异 bbox ＝ `(28,169)-(240,572)`（**两页同 bbox** ＝ 左侧导航列表区，非页面内容）⇒ 属既定"帧面不可复现"现象（`P1-frame-determinism2-report.md`）。**同批** `pol0`／`polT`／`polF` 三腿均给规范值；**单独重跑** `default2` 腿复现规范值 `64603fc1d8e23e39 colors=910`。⇒ 本席**不**用它当"本增量引入"的归因，也**不**掩盖它。
8. **`SSC` 现取 `FAIL`**（见 §3.5）：差异量是**权威件换代**（`.so`），刷新路径在黑名单 ⇒ 留待收波（`wave-push.sh`／`close-wave.sh`）。
9. **`DEFREG_DECLDRIFT=1`** 如实记：复述位件（`KNOWN-DEFECTS.md`＝键 `KD`）已随动，而 `declared.tsv` 的 `--emit` 落在黑名单 `build/MilBridge/tools/**` ⇒ 本趟**不重发**（`DEFREG=PASS` 不受影响）。

---

## §6 遗留（下一增量具名靶）

- **单元边界面**：`FsQueryTableObjRowDetails` 的 `fskboundaryAbove/Below` ＋ `dvrAbove/Below` 按**真实行边界**（首/末行 `Outer`、断行 `Break`、行间 `Inner` ＋ `dvrAboveRowBreak`／`dvrBelowRowBreak`）填；`fForcedRow` 按 `FSKROWHEIGHTRESTRICTION` 派生。
- **行高与单元高的自洽**：现取行高由 `max(单元内容高)` 定；若上游语义是"`SetCellHeight` 用**行高**（含行距）而单元矩形取行高"，则需把 `dvrAboveRow/dvrBelowRow` 的**归属**写清（本侧今天是"加在行高里、单元矩形＝行高"）。
- **`WPF_PTS_TABLECELL` 的缺省翻转**：本闸**缺省关**；当上面两条落地且无回归后，才按 `T-A28→T-A31` 体例翻缺省并给成对腿（届时缺省路径即含单元文本）。
- **`SSC`／`declared.tsv` 的收波随动**：由不在本任务黑名单内的收波步骤完成。

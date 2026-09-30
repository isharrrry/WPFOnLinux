# `P1-tail2` `TASK-0302` · native「附属对象内容排版」（`NATIVE-PTS-ATTACHED-CONTENT-LAYOUT`）—— 实现报告（`T-A37`）

- **读时**：`2026-09-30T17:3x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=22dcd4393f661d9cf57dd88a65234fb2cc5db3fa`（现取，**未换代**）。
- **改前件备份（仓外 `~/tA37-work/bak/`，`cp -p` 取在**任何写之前**）**：`win32_pts.c.22dcd439.bak`（`205b2df3f123a05a`／`520070` B）／`libwpfwin32.so.22dcd439.bak`（`21ad5f39ef3c4034`）／`exports.txt.bak`（677→681 代）／`pts-gap-decl.txt.bak`。
- **只改**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（子页对象 ＋ 新增两导出 ＋ 四处查询支 ＋ 内容排版驱动 ＋ 内容行驱动）／**随动**：`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`PTSGAP-DECL` 重锚 ＋ `T-A37` 记录块）／`src/WpfGfx.Linux.Native/bin/exports.txt`（构建生成，`681→683`）／**复述位现值位**（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）／**新建**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2f/`（`sample1/`＋`sample2/`＋`sample3/`＋`polar/`）／本载体。
- **黑名单遵守**：未动 `build/*.Linux/**`（生成件）／`build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`；未改相位；未 `git add/commit/push`。重活（**2 趟构建 ＋ 4 趟腿**）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID；禁 `sleep` 轮询；写前 `cp -p` 备份；`temp+rename`（编辑器原子替换）；模式守恒。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。
- **口径**：一切读数**本席现取**（`sha256sum`／`grep -c`／`nm`／`diff`／只读 `python3`＋`PIL` 解 PNG／`bash build/MilBridge/tools/pts-pages-guard.sh --legs …`）；`T-A33`／`T-A35`／`T-A36` 载体**只作对照**，其读数**逐格由本席现取复算**、**未抄**。

---

## §0 结论速览（自包含）

1. **实现已落地（`win32_pts.c`，`T-A37` 指定写域）**：**窗内驱动附属对象内容排版**（照 `T-A33` 回填体例）。关键事实链（**现取**，`sample1`／`sample2`／`sample3`）：
   - `[SUBPAGE] rc=0 entry=FsCreateSubpageFinite seg=0x17 w=37810 h=10810 cParas=1 cont_children=1 cont_client=0x1a hand=0x…18 tok=in-window-enum(+136/+144)+managed-176`
   - `[FSATT-CONTENT] where=FsCreatePageFinite figure=0x14 client=0x16 rc=0 dur=8381 dvr=19190 … subpage=0x…18 v=SUBPAGE-CREATED`
   - `[FSPARALIST-FILL-SP] rc=0 … pfspara=0x…f4 client=0x1a src=owned-subpage(cont_obj+managed-176)`
   - `[FSQSTD] rc=0 entry=FsQuerySubtrackDetails … cParas=1 true_cParas=1`／`[FSQSPL] rc=0 … made=1`／`[FSQTD] rc=0 … cLines=1`（内容段文本行**真回填**）
2. 🔴 **判决：部分成功（链已通 ∧ 无回归 ∧ 反极性成立），但判据 ② 未达** —— `k=24` 帧上**余 3 具名色（`Beige`／`DarkGreen`／`LightGoldenrodYellow`）仍 `0 px`**，`PTS_COLORANCHOR=FAIL hits=1`（与 `T-A36` 同）；**帧 `sha16` 与 `T-A36` 代际逐字节相同**（`1487caf78fd88886`）⇒ 本增量**未产出任何像素**。
3. 🔴 **本增量改前的前沿阻塞已解**：内容排版回调（`pfnGetFigureProperties`）改前**必然**失败 —— 它**无条件** `PTS.Validate(PTS.FsCreateSubpageFinite(...))`（`FigureParagraph.cs:168/211`），而 `FsCreateSubpageFinite` **本侧未导出** ⇒ 托管抛 `EntryPointNotFoundException` ⇒ 回调返 `-100002`。本增量**新增该 native 入口**（＋配对 `FsDestroySubpage`），使回调**返 `rc=0`**、`SubpageHandle` **首次真被设**。
4. ⚠️ **本增量的射程（写死，防被读宽）**：**只驱动 `Figure` 的内容排版**（`idobj==-2`）；**`Floater` 支未驱**（需 `pfnGetObjectHandlerInfo`（`cbkobj` 第 8 槽／`+600`）＋ native `GetFloaterHandlerInfo` 构造 `FSFLOATERCBK`，本增量**未实现**）⇒ `LightGoldenrodYellow`（在 `Floater` 的 `Table` 行）**本轮无路径**。
5. ✅ **症状门无回归**：`alive=yes app_rc=143 failfast=0 magenta=0 colors=724 [HC-UNHANDLED]=1 ns=…FlowDocumentDemo`（与 `T-A36` 逐格同；`[HC-UNHANDLED]=1` ＝ 承 `T-A33` 的残留诚实拒绝，**未增**）。
6. ✅ **反极性（该红必红）**：同一 `.so` ＋ 显式 `WPF_PTS_ATT_CONTENT=0` ⇒ `[SUBPAGE]=0`／`[FSATT-CONTENT]=0`／`[FSPARALIST-FILL-SP]=0`（**子页链全零**；`[FSATT-PROBE]` 仍在，证 `T-A36` 台账面未受影响）。
7. **门禁（④）**：`nm -D --defined-only` ＝ `exports.txt` ＝ **683**（逐名 `diff` 零差异）；`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=67 so16=606dad49ae7b34a1 exports=683`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS files=318 ids=2230 declared=225`（rc=0）。

---

## §1 改动（逐处，`win32_pts.c`）

### 1.1 回调偏移的**唯一定义处**（`cbkfig`）
```c
#define WPF_PTS_SNAP_IDX_GETOBJHANDLERINFO    (WPF_PTS_FSCBK_CBKOBJ_OFF / 8 + 7)   /* 70 → 绝对 +600 */
#define WPF_PTS_SNAP_IDX_GETFIGUREPROPERTIES  (WPF_PTS_FSCBK_CBKFIG_OFF / 8 + 0)   /* 71 → 绝对 +608 */
```
（照 `Pts.cs:562` `FSCBKFIG.pfnGetFigureProperties`（第 1 槽）／`Pts.cs:659` `FSCBKOBJ.pfnGetObjectHandlerInfo`（第 8 槽）；`_Static_assert` 四条钉死；`wpf_pts_fn_get_figure_properties` 原型照 `PtsHost.GetFigureProperties` 逐参。）

### 1.2 **子页对象**（`wpf_pts_subpage`，本增量核心载体）
`magic`／`ctx`／`nseg`／`c_paras`（**句柄 ＝ 本字段地址**，承 `FsQueryTrackDetails` 范式）／`brk`／`dvr_used`／`fsrc_*`／`cont_client`（窗内 `+176` 真造的**内容容器客户端**）／`cont_obj`（内容树的**本侧子轨根**）＋ 表 `g_pts_sp_live[]`（上界 64）＋ `sp_new`／`sp_handle`／`sp_claim_track`／`sp_destroy`。

### 1.3 **窗内驱动**（`wpf_pts_format_one_para`，附属对象循环内）
`+176` 造 `obj_client` 之后，**同窗内**（`win_finite`＝`where=="FsCreatePageFinite"`；`FigureParagraph.cs:113` 有 `Invariant.Assert(CurrentFormatContext.FinitePage)` ⇒ **禁**在 Bottomless 窗发调）调
`pfnGetFigureProperties(pfsclient, obj_client, nmp_obj, fInTextLine=1, fswdir=0, fBottomUndefined=0, out…)`，
记 `fl_att[].content_rc`／`sub_obj`，并打 `[FSATT-CONTENT]`。**零假值**：`rc≠0` ⇒ 不记子页。

### 1.4 **新增两导出**
- `FsCreateSubpageFinite`（声明 `Pts.cs:3169`，**29 参**；`FSFMTR`＝3×int／`FSBBOX` 出参按 `memset` 清零）：真造 `wpf_pts_subpage`；**窗内** `+136`／`+144` 枚举 `nSeg` 的内容段序（`wpf_pts_sub_enum_into`）＋**窗内** `+176` 造内容容器客户端；`*ppSubPage = ` 本侧对象句柄；`*ppBRSubPageOut = NULL`（⇒ 托管不调 `FsDestroySubpageBreakRecord`）；`fsBBox.fDefined = 0`（⇒ 托管跳过二次排版与 `FsDestroySubpage` 支，`FigureParagraph.cs:185/193`）。
- `FsDestroySubpage`（声明 `Pts.cs:3268`）：按**对象身份**认领后销毁（未命中 ⇒ 拒）。

### 1.5 四处查询支（**只增不改**）
| 入口 | 新增支 | 内容 |
|---|---|---|
| `FsQuerySubpageDetails` | **内容子页支** | 认到本侧子页句柄 ⇒ `fSimple=1` ＋ `trackdescr.pfstrack=&sp->c_paras` ＋ `fsupdinf.fskupd=New`（`FigureParaClient.ValidateVisual:346` 据此走 simple 支） |
| `FsQueryTrackDetails` | 子页轨支 | 按对象回答 `cParas` |
| `FsQueryTrackParaList` | 子页轨支 | 真填 1 条：`pfspara=wpf_pts_sub_handle(sp->cont_obj)`／`pfsparaclient=sp->cont_client`／`nmp=sp->nseg` |
| `FsQuerySubtrackDetails` | 几何 | `in_subpage` 树取**子页声明几何**（`sp_du/sp_dv`），否则逐字沿用 `768×576` 页约定 |

### 1.6 内容子树行驱动
`wpf_pts_fl_walk_c`（预算与主树**分开**，上界 24）＋ `wpf_pts_sub_mark_subpage`（整棵内容树打标）＋ `wpf_pts_formatline_drive` 出口新增 `[FORMATLINE-CONTENT]`。使内容段的文本行进台账 ⇒ `FsQueryTextDetails` 可回填。

### 1.7 构建（现取）
`bash build-shim.sh --symbols`（经 `heavy-slot`，两趟）⇒ **0 错误**（既有 `-W*` 警告与本增量无关）；产物 `bin/libwpfw32.so` ＝ **`606dad49ae7b34a1`**（`448688` B）；`bin/exports.txt` ＝ **`683`**（`--symbols` 由 `nm` 重生成；`FsCreateSubpageFinite`／`FsDestroySubpage` 逐名新增，**无消失**）。

---

## §2 成对机读读数（**同一跑器**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`；A 臂 `:235`）

| 腿 | `.so` | 闸 | 证据目录 |
|---|---|---|---|
| `sample1`（**方案 1**·首版） | `d3b6478cfb425ffa` | 缺省 | `…/evidence-tail2f/sample1/` |
| `sample2`（**方案 2**·内容树几何） | `606dad49ae7b34a1` | 缺省 | `…/evidence-tail2f/sample2/` |
| **`sample3`（方案 2·第二独立样本）** | **`606dad49ae7b34a1`** | 缺省 | **`…/evidence-tail2f/sample3/`** |
| `polar`（**反极性**） | `606dad49ae7b34a1` | **显式 `WPF_PTS_ATT_CONTENT=0`** | `…/evidence-tail2f/polar/` |

### 2.1 症状门 ＋ 帧面（逐腿，现取）

| 腿 | `app_rc` | `alive` | `failfast` | `magenta` | `colors`(k24) | `ink` | `ns`(k24) | `fr_sha`(k24/k23) |
|---|---|---|---|---|---|---|---|---|
| `sample1` | 143 | yes | 0 | 0 | 724 | 480000 | `…FlowDocumentDemo` | `1487caf78fd88886`／`10d0b9d54e649c10` |
| `sample2` | 143 | yes | 0 | 0 | 724 | 480000 | `…FlowDocumentDemo` | `1487caf78fd88886`／`10d0b9d54e649c10` |
| **`sample3`** | **143** | **yes** | **0** | **0** | **724** | 480000 | `…FlowDocumentDemo` | **`1487caf78fd88886`**／`10d0b9d54e649c10` |
| `polar` | 143 | yes | 0 | 0 | 724 | 480000 | `…FlowDocumentDemo` | `1487caf78fd88886`／`10d0b9d54e649c10` |

⇒ **症状门六项逐格现取**、四腿**逐格相同**；`k23` 的 `ns=HandyControlDemo.UserControl.RichTextBoxDemo`（四腿同）。`boot.png` `sha16=b21eb530afd3c66c`（四腿同）。

### 2.2 计数成对（`grep -ac`，现取）

| 计数 | **改前（`T-A36`，在册 `evidence-tail2e/`，只作对照）** | `sample1` | `sample2` | **`sample3`** | `polar` |
|---|---|---|---|---|---|
| `[SUBPAGE]` | ——（无此探针） | 1 | 1 | **1** | **0** |
| `[FSATT-CONTENT]` | —— | 1 | 1 | **1** | **0** |
| `[FSPARALIST-FILL-SP]` | —— | 174 | 476 | **698** | **0** |
| `[FSATT-PROBE]` | 42 | 43 | 43 | 43 | **42** |
| `[FSQSTD] rc=0` | ——（无子页支） | 1407 | 3823 | **5599** | 2283 |
| `[FSQSPL] rc=0` | —— | 1407 | 3823 | **5599** | 2283 |
| `[FSQTD] rc=0` | —— | 1314 | 3579 | 5244 | 2466 |
| `[FSQLL] rc=0`（**内容段 `cLines=1` 恒 0**） | —— | 353 | 957 | 1401 | 761 |
| `[HC-UNHANDLED]` | 1 | **1** | **1** | **1** | 1 |
| `[FS_PAGE_GAP]` | —— | 1 | 1 | 1 | 1 |

**逐字样本（`sample3`）**：
```
[SUBPAGE] rc=0 entry=FsCreateSubpageFinite seg=0x17 w=37810 h=10810 cParas=1
          cont_children=1 cont_client=0x1a hand=0x…18 tok=in-window-enum(+136/+144)+managed-176
[FSATT-CONTENT] where=FsCreatePageFinite figure=0x14 client=0x16 rc=0 dur=8381 dvr=19190
                cPolygons=0 cVertices=0 subpage=0x…18 sp_created=1 v=SUBPAGE-CREATED
[FORMATLINE-CONTENT] where=FsCreatePageFinite c_driven=1 c_paras=1 sp_live=1 v=CONTENT-LINES-DRIVEN
[FORMATLINE] where=FsCreatePageFinite para=… nmp=0x19 du=180000 nlines=1 dcp_sum=41 complete=1 v=LINES-RECORDED
[FSPARALIST-FILL-SP] rc=0 reason=ok entry=FsQueryTrackParaList track=0x…18 cParas=1
                     pfspara=0x…f4 client=0x1a src=owned-subpage(cont_obj+managed-176)
[FS_ATT] rc=0 entry=FsQuerySubpageDetails subpage=0x…18 fSimple=1 cParas=1 track=0x…18
         fsrc=(0,0,37810,10810) src=owned-subpage NOINFO=subpage-geometry-declared(lWidth/lHeight)
[FSQTD] rc=0 reason=ok entry=FsQueryTextDetails … parah=0x…94 fsktd=1 cLines=1 dcpFirst=0 dcpLim=41 fl_ok=1
        out=WRITTEN bytes=112 src=ledger:fl_line[](pfnFormatLine+fsflres-end)
```
⚠️ **跨样本计数不逐格相同**（`sample2` 3823 vs `sample3` 5599 等）⇒ 这些计数**不是**帧面确定性的证据；**只有帧 `sha16` 跨样本相同**。本席如实记，不作"两样本逐格相同"的断言。

---

## §3 帧面（**本席自算**，只读 PNG；判据 ③）

| 腿 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `ncolors` | `fr_sha` |
|---|---|---|---|---|---|---|
| `boot.png`（**活锚基线**） | **0** | 0 | 0 | 0 | 386 | `b21eb530afd3c66c` |
| **`sample3 k24.png`** | **`29637`** | **`0`** | **`0`** | **`0`** | **724** | **`1487caf78fd88886`** |
| `sample3 k23.png` | 0 | 0 | 0 | 0 | 636 | `10d0b9d54e649c10` |
| `sample2 k24.png`（第二样本） | `29637` | 0 | 0 | 0 | 724 | `1487caf78fd88886` |
| `polar k24.png`（反极） | `29637` | 0 | 0 | 0 | 724 | `1487caf78fd88886` |

- **判据 ② 现取**：`PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=29637 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=1 expect_min=200 expect_hits=2 … phase=degraded reason=declared-color-anchor-absent`（判词全文见 `evidence-tail2f/guard-degraded.txt`）。⇒ **`hits` 仍 `1`**（＝ `T-A36` 的值）⇒ **判据 ② 未达**。
- ⚠️ **不得把空白读成绿**：`GhostWhite` 是 `Figure`/`Floater` 的 **`Background`**（`DrawBackgroundAndBorder` 所绘），**不是**"内容真绘出"；三内容色**全 0**。
- **两页帧分离**：`k24=1487caf78fd88886 ≠ k23=10d0b9d54e649c10`；`k24` 与 `T-A36` **同值** ⇒ **本增量零像素**。

---

## §4 反极性（**同一 `.so` ＋ 同一跑器 ＋ 同一装置**，只差**一个 env**：`WPF_PTS_ATT_CONTENT`）

| 判据 | 改后（缺省，`sample3`） | **显式 `=0`（`polar`）** | 改前（`T-A36` 现场） |
|---|---|---|---|
| `[SUBPAGE]` | **1** | **0**（子页**未造**） | ——（无此入口） |
| `[FSATT-CONTENT]` | **1**（`rc=0 v=SUBPAGE-CREATED`） | **0**（内容回调**未发**） | —— |
| `[FSPARALIST-FILL-SP]` | **698** | **0** | —— |
| `[FSATT-PROBE]` | 43 | **42**（`T-A36` 台账面**逐字不变**） | 42 |
| 帧 `fr_sha`(k24)／`colors` | `1487caf78fd88886`／724 | `1487caf78fd88886`／724 | `1487caf78fd88886`／724 |

⇒ **反极性成立**：「**内容排版链不驱 ⟺ 子页／内容回调／子页轨填全零**」钉死（`gate=0` ⇒ 三条具名探针**全 0**）。
⚠️ **但帧面不随之变**（两腿帧逐字节相同）——这**正好**是"链已通但**未落像素**"的**成对证据**：本增量对帧面**无副作用**（既无正作用也无副作用）。

---

## §5 验收逐条（对 `T-A37` ③）

- **① `A35 §4`／`A36` 判据逐条现取 ＋ 反极性**：
  - **`D1` 台账实名化／零假值**：✅ **未回归**（`[FSATT-PROBE]` 43／42 成对；`attached-objects` 面逐字承 `T-A36`）。
  - **`D2` 色锚转 `PASS`**：❌ **未达** —— `hits=1`（`GhostWhite=29637`），`expect_hits=2`。**反极**：`polar` 仍 `hits=1`（因本增量**零像素**，反极性只能在本增量**自己的探针面**上成立）。
  - **`D3` 块状几何落位**：⚠️ **无新增**（内容**未落像素**）。
  - **`D4` 失败必留痕 ＋ 计数恰涨 1**：✅ —— 子页四支的每条拒绝都走既有具名 `reason=`／`[FS_PAGE_GAP]` 形态；新成功路径**逐条打** `[SUBPAGE]`／`[FSATT-CONTENT]`／`[FSPARALIST-FILL-SP]`／`[FSQSTD]`；`polar` ⇒ 全 0（与"真 0 次"可分）。
- **② 计数成对 ＋ **关键**（`k24` 四具名色各 ≥200px）**：§2.2 ＋ §3 —— `GhostWhite` ✅；`Beige`/`DarkGreen`/`LightGoldenrodYellow` ❌（**0**）⇒ **未达**。
- **③ 帧面成对**：§3（`boot`/`k24`/`k23` 三帧 `sha16`；两独立样本 `sha16` 相同；**不把空白读成绿**）。
- **④ 导出面 `nm==exports`；`PTSGAP=PASS`；`DEFREG`/`REPORTID` rc=0**：✅ —— `683==683`（逐名 `diff` 零差异）；`PTSGAP=PASS`（rc=0）；`DEFREG=PASS`（rc=0）；`REPORTID=PASS`（rc=0）。
- **⑤ 症状门**（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）：§2.1（四腿逐格相同，**无回归**）。

---

## §6 边界 · `NOINFO` · 主动披露

1. **改动面（`git status --porcelain` 现取）**：`M README.md`／`M build/MilBridge/HANDOFF-NEXT.md`／`M docs/ROUTES.md`／`M docs/unimplemented.md`／`M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`M src/WpfGfx.Linux.Native/src/win32_classification.c`／`M src/WpfGfx.Linux.Native/src/win32_pts.c`／`M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` ＋ **本载体** ＋ **新建** `evidence-tail2f/` ＋ **先于本件**的两项 untracked（`build/MilBridge/tasks-tail2/T-A37.md`／`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`）。`bin/libwpfwin32.so`／`bin/exports.txt` 是**构建生成件**（不入库），不计入手改面。
2. 🔴 **中间腿（如实披露，防被读成"一次成型"）：本席共跑 2 趟构建 / 4 趟腿、2 种方案**：
   - **方案 1（`sample1`）**：子页子系统 ＋ 内容回调驱动 ＋ 四处查询支。**现取**：全链 `rc=0`（`[SUBPAGE] 1`／`[FSATT-CONTENT] 1`／`[FSPARALIST-FILL-SP] 174`），**帧与 `T-A36` 逐字节相同**。
   - **方案 2（`sample2`／`sample3`）**：加**内容树几何**（`in_subpage` ＋ `sp_du/sp_dv` ＋ 内容段 `dvr_used = Σ(ascent+descent)`）。**现取**：`[FSPARALIST-FILL-SP] 476→698`（链更活跃），**帧仍逐字节相同** ⇒ **几何不是缺像素的因**。
   - ⚠️ **方案数 = 2**（`sample2`／`sample3` 是**同一方案的两独立样本**；`polar` 是反极性腿）。
3. 🔴 **`NOINFO`（逐条给"消掉需要什么"）**：
   - `NOINFO-attached-content-visual-not-pixels`（**新读出，本轮核心边界**）：内容排版**链**已通（子页造出、子页轨被填、内容段的 `FSTEXTDETAILS`（`cLines=1`）与段句柄均被托管取到、无异常），但**托管侧未为内容段产出任何像素**。**现取旁证（可判）**：`FsQueryLineListSingle` 对**内容段**（`cLines=1`）**从未被调**（全趟 `[FSQLL] rc=0` 的 `cLines` 只有 `6`／`8`／`2`）⇒ 内容段的文本行**未经 `RenderSimpleLines` 落视觉**；`TextParaClient.ValidateVisual` 在 `IsDeferredVisualCreationSupported()` 为真时走**延迟视觉**支（`SyncUpdateDeferredLineVisuals`），而行视觉的实际创建依赖**视口更新**（`UpdateViewport`）——本侧 `FsQuerySubpageDetails` 给出的 `fsrc`／`fsupdinf` 是否足以让托管对**子页轨**发起视口更新，**本席未验证**。**消掉需要**：在**渲染面**（`FigureParaClient.UpdateViewport` → `PtsHelper.UpdateViewportTrack` 链）接旁证，或与"延迟视觉"路径对拍（下一增量）。
   - `NOINFO-floater-content-not-driven`（**新边界**）：本增量**只**驱 `Figure`（`idobj==-2`）；`Floater` 的 `FormatFloaterContentFinite` 需 `FSFLOATERCBK`（经托管 `pfnGetObjectHandlerInfo`（`+600`）→ native `GetFloaterHandlerInfo` 构造）⇒ 本侧**未实现**。**消掉需要**：实现 `GetFloaterHandlerInfo`／`GetTableObjHandlerInfo` 的 handler 构造 ＋ 对 `FloaterParagraphId` 发 `pfnFormatFloaterContentFinite`。
   - `NOINFO-subpage-geometry-declared`（**新具名**）：子页／内容树几何**取入参**（`lWidth`／`lHeight` ＝ 托管按 `Figure.Width/Height` 算出的值），**非**上游 ABI 几何。
   - `NOINFO-FSGEOMETRY-LAYOUT`／`NOINFO-SUBTRACK-PARA-GEOMETRY`／`NOINFO-attached-object-geometry-layout`／`NOINFO-TLB-ATTACHED-OBJECTS`／`NOINFO-ATTACHED-ABSENT-CAUSE`：**逐字承** `T-A33`／`T-A36`，本增量**未消**。
4. **本增量的射程边界（写死，防被读宽）**：本增量解的是 **"附属对象内容排版这一层的驱动 ＋ 子页台账 ＋ 查询支"**，**不是**"附属对象内容真绘出"，**不是**"PTS 真实现"，**不是**"色锚转绿"。`[HC-UNHANDLED]=1` 的残留（`FsQueryTrackParaList` 的 `drive-handles-released(page-destroyed)` 诚实拒绝）**未动**。
5. **导出面代价（如实登记）**：新增 2 导出 ⇒ `exports 681→683`、`so16 21ad5f39ef3c4034→606dad49ae7b34a1`；缺口计数**下降** `ops 66→64`／`impl 69→67`／`tool 78→76`（`tool = ops + dead + artifact` 恒式保持）。**计数下降 ≠ 能力前进**（件头第 ① 条）——本增量**前沿跳在链**（回调首次返 0），**不在帧面**。
6. **正文复述位随动面（现取）**：`docs/ROUTES.md`（`T-A36` 行后新增 `T-A37` dated 落地行 ＋ 四处现值位）／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（新增 `T-A37` 现值位行；且对 `t104` 那行**只加自引旧代锚**使其按本牙口径归为**历史行**）／`build/MilBridge/HANDOFF-NEXT.md`（§3 dated 对齐新增行）／`src/WpfGfx.Linux.Native/src/win32_classification.c` —— 全 **只增不改**（现值位数字随动除外）⇒ `PTSGAP=PASS`。
7. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；**未**新增任何 `D-G<digits>` 登记编号；未跑 `--all-arms`（只跑 A 臂 `24,23`）；未驱 `Floater` 支。
8. **侧效（如实披露，未进仓）**：`~/tA37-work/`（`bak/` 改前件 ＋ `app/` 私有应用安装 ＋ `legs-*/` 四趟腿证据 ＋ 跑腿脚本 `legs.sh`／`legs-slot.sh`）；仓内应用安装**一字未动**（`sync-applocal.sh --check … drift=0` 逐腿现取）。
9. **跨代／跨装置不可比（纪律 31/32）**：§2／§3 的"改前"列取自 `T-A36` 的**在册** `evidence-tail2e/`（**另一代 `.so`**）⇒ 只报**结果**（`colors 724`／帧同值等），**不做减法**承重；"改后"列＝本席**同趟新取**（`evidence-tail2f/`）。
10. 🔴 **`T-A37-addendum`（本席现取，`sample3`，只增不改）—— 残差的**机读**定位**：
   - `[FSQTD] rc=0` 的 `cLines` 直方图：**`cLines=1` × 698**（＝内容段，与 `[FSPARALIST-FILL-SP] rc=0` 的 **698** 逐数吻合）｜`cLines=2`×2｜`cLines=6`×2796｜`cLines=8`×1748。
   - `[FSQLL] rc=0` 的 `cLines` 直方图：`cLines=2`×1｜`cLines=6`×700｜`cLines=8`×700 —— **`cLines=1` 恒缺席**；且 `entry=FsQueryLineListSingle` 全趟 2802 次**零拒绝**（`rc=-10000` × 0）。
   ⇒ **可算出的结论**：图元取数（`[FSQTD]`）到了内容段，但**行列表取数**（`[FSQLL]`）**从不到内容段** ⇒ 内容段的**行视觉从未被创建**。托管侧两条路径（现取 `TextParaClient.UpdateViewport:152`／`ValidateVisual:75`）都要求 `IsDeferredVisualCreationSupported(ref full)` 为**真**时走**延迟视觉**支：`ValidateVisual` 支（`SyncUpdateDeferredLineVisuals:1389`）在 `fUpdateInfoForLinesPresent=0`（本侧**如实**填 0 ⇒ 无更新信息可报）时**只 `Clear()`**；真正的引导创建在 `UpdateViewportSimpleLines:3359`（`IntersectsWithRectOnV` ∧ `LineListSimpleFromTextPara`）。⇒ 本侧**能**提供的**唯一**诚实杠杆是"**让托管对子页轨发起 `UpdateViewport`**"（链路：宿主 `TextParaClient.UpdateViewport:179` → `FigureParaClient.UpdateViewport` → `PtsHelper.UpdateViewportTrack` → 本侧子页轨 → `ContainerParaClient.UpdateViewport` → `FsQuerySubtrackParaList` → 内容段 `UpdateViewport`）。**该链路为何未达（下一增量的第一问）**：本侧**只**能观测到"`[FSPARALIST-FILL-SP]` 698 次"（无法分辨其中多少来自 `UpdateViewportTrack` 而非 `UpdateTrackVisuals`）；⇒ 需在**渲染面**加旁证（或与设备端对拍）。
   ⚠️ **不得用假值绕过**：把内容段的 `fLinesComposite` 置 1 可绕开延迟支（走 `RenderCompositeLines`），但那**语义是假**（该段并无合成行）⇒ 本侧**不做**（零假值铁律）。
11. 🔴 **合法终点判读（如实）**：本增量按 `T-A37` 允许的"**最多 3 种方案；失败即如实报停止（允许判合法终点）**"——本席用 **2 种方案**（＋1 条反极性腿）把前沿从"**内容排版回调注定失败**"推进到"**链全通、托管侧内容行视觉未落**"，并在 §6.3／本条**具名**给出下一增量所需的**唯一诚实杠杆**。⇒ 本增量判 **部分成功（链 × 帧面未达）**，**不是**"假绿"，也**不是**"不可做"。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-attachcontent-impl-report.md | sha256sum | cut -c1-16`）= c0f6dc6751b879c9

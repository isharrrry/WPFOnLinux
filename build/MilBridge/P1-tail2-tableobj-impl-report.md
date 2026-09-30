# `P1-tail2` · `T-A53` · 第 4 色 `LightGoldenrodYellow`（native `NATIVE-PTS-TABLEOBJ`：Table 族五入口 ＋ `GetTableObjHandlerInfo`／`FSTABLEOBJCBK`）—— 实现报告（**判决：判据 ① 已达 —— 开闸腿 `LightGoldenrodYellow = 1998 px ≥ 200` ∧ 缺省路径逐格零回归 ∧ 反极性该红必红 ∧ 门禁五件全绿**）

- **读时**：`2026-10-01T07:4x–07:5x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=bf81676`（＝ `T-A52` 收尾那笔；**未换代**）。
- **改前件备份（仓外 `~/tA53-work/bak/`）**：`win32_pts.c.HEADpre`（`4d0767892092cb55`＝ `git show HEAD:…` 的真改前件）／`pts-gap-decl.txt.HEADpre`（`f62bce16f135c244`）／`exports.txt.pre`（`860a3abe4a64f1c5`）。
  ⚠️ **纪律 6 的一处如实自纠**：本趟第一次备份**取在第一次写之后**（`cp` 落到新建目录的 `pre-edit.c` ＝ `bb8ed9a2fe8a0ccd`，非真改前值）⇒ 本席**当场用 `git show HEAD:<path>` 重取真改前件**（两件 `sha16` 与 `T-A52` 报告 §4 的"改后值"**逐位相同** ⇒ 证明确是改前态）并保留原 `pre-edit.c` 不删。**这不是"备份成功"，是"备份补取"**，如实记。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**五处**：T-A53 形状/偏移定义 ＋ `GetTableObjHandlerInfo` 真实现 ＋ 闸 ＋ 窗内表模型驱动 ＋ `FsQuerySubtrackParaList` 补调 Autofit ＋ Table 族五入口 ＋ 自检成对断言）／`bin/exports.txt`（**由 `build-shim.sh --symbols` 重产**；`bin/` 在 `.gitignore:24` ⇒ **非仓内件**，见 §5.6）／`tools/pts-gap-decl.txt`（DECL 行 ＋ dated 追注）／**复述位现值位**（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（**生成器一字未动**；`sha16` 仍 `b6a3a24137a77ddf`）⇒ 其重产件亦未动（`PresentationFramework.dll` 仍 `1c6c58df6d757f3f`）—— 本增量全在 native（托管链 `T-A52` 已备，**无需托管改动**）。
- **黑名单遵守**：未动 `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**6 趟 native 构建**（各 `< 5 s`）＋ **7 趟跑器**（共 **14 条腿**；全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`，逐趟 `HEAVYSLOT=RELEASED rc=0 held=27–35 s`）；进程只按 PID；显示位只用空闲 `:23x`（`DISPLAY_PICK :231`，逐趟 `DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p`；temp+rename（复述位件由只读脚本改，见 §2.7）；模式守恒。**收尾现取**：重活槽 `SLOT=FREE`。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`grep -c`／只读 `python3`＋`PIL` 解 PNG／`compare -metric AE`／`bash build/MilBridge/tools/{pts-pages-guard,pts-gap-count-check,defect-registry-check,report-id-domain-check}.sh`／`python3 ~/tA15-work/selfcheck.py`）。

---

## §0 结论速览（自包含）

1. ✅ **判据 ① 已达（关键）**：**开闸腿**（`WPF_PTS_FLOATER_CBK=1 WPF_PTS_TABLEOBJ=1`）`k=24` 上 **`LightGoldenrodYellow = 1998 px`（≥ 200）**；**基线（缺省）仍 `0 px`**。`PTS_COLORANCHOR=PASS k=24 hits=**3**`（off 腿 `hits=2`）。
2. ✅ **`GetTableObjHandlerInfo` 由具名缺口 stub 升为真实现**：入参即 `FSTABLEOBJINIT*` ⇒ **逐槽只读捕获**（45 槽／360 B）到持有位 `g_pts_tableobj_cbk[]`；出参非空时**逐槽原样转写**；`NULL` init ⇒ **拒**（`-10000` ＋ 具名 `[FS_PAGE_GAP] reason=null-init`）。现取 `[FSTABLEOBJ-CBK] rc=0 … slots=45 getTableProps=0x…240 autofit=0x…258 firstRow=0x…300 nextRow=0x…318 rowProps=0x…3a8 cells=0x…3c0 fmtCellFinite=0x…408 out=WRITTEN bytes=360 src=managed-FSTABLEOBJINIT`（**2 次**，gate-on 腿）。
3. ✅ **Table 族五入口导出且真服务**：`FsQueryTableObjDetails`／`…TableProperDetails`／`…RowList`／`…RowDetails`／`…CellList` ⇒ 缺口名单 `tool 76→71`／`ops 64→59`；`exports 683→688`（`nm==exports` 逐名 `diff` 零差异）。gate-on 腿 `[FSTABLEOBJ-Q]` **8903** 条、`entry point named` **0**、`[HC-UNHANDLED]` **0**。
4. ✅ **窗内真建表模型**：`[FSTABLEOBJ-DRV] where=FsCreatePageFinite nmTable=0x1d client=0x1f rch=0 autofit_rc=0 wtbl=92100 first_rc=0 nrows=**5** built=1 v=TABLE-MODEL-BUILT`（**2 次**＝两窗；行句柄 `0x20/0x22/0x25/0x28/0x2b` 逐窗一致 ⇒ **换代重建**）＋ `[FSTABLEOBJ-AUTOFIT] para=0x1d client=0x3f rc=0 wtbl=92100 v=AUTOFIT-ON-REAL-CLIENT`（**2 次**）。
5. ✅ **缺省路径零回归（闸缺省关）**：新增运行期闸 `WPF_PTS_TABLEOBJ` **缺省 `0`（关）** ⇒ 缺省路径与改前**逐格相同**：`k24 fr_sha=791696291d51470b colors=905`（`GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=**0**`）、`FSTABLEOBJ-*=0`、`FSFLOATER-CONTENT=0`、`entry point named=0`、`[HC-UNHANDLED]=0`、`PTS_GUARD=PASS`、`PTS_COLORANCHOR=PASS hits=2`、`PTS_ENFE=PASS total=0`。
6. ✅ **反极性（该红必红，同一 `.so 3ff91579e7ea3efa`／同装置 `:231`／只差 env）**：`off2`（缺省）↔ `on4`（`FLOATER_CBK=1,TABLEOBJ=1`）↔ `pol1`（`FLOATER_CBK=1,TABLEOBJ=0`）。`pol1` ⇒ 无模型 ⇒ `FsQueryTableObjDetails` **诚实拒**（`rc=-10000 reason=no-table-model` ×409）⇒ 整页空白（`colors=383 fr_sha=ef3fd6765f18f51b`）⇒ **`PTS_GUARD=FAIL`／`PTS_COLORANCHOR=FAIL hits=0`／`[HC-UNHANDLED]=314`**（**该红必红**）。
7. ✅ **门禁五件**：`nm -D --defined-only` ＝ `exports.txt` ＝ **688**（逐名 `diff` 零差异）｜`PTSGAP=PASS tool=71 dead=11 artifact=1 ops=59 impl=60 so16=3ff91579e7ea3efa exports=688`（`rc=0`）｜`DEFREG=PASS declared=225 route_ids=225`（`rc=0`）｜`REPORTID=PASS files=330→331 ids=2238+ declared=225`（`rc=0`；本件落盘后 `+1`）｜自检面 `PtsGapSelfCheck=1`／`PtsGapSelfCheckDiag=0`／`PtsGapSelfCheck(2nd)=1`（幂等）。
8. 🔴 **具名下一靶 ＝ 表**单元内容**排版**（`cCells=0` 的**诚实的空**，见 §5.1）：本增量只让**行背景**（＝第 4 色所在层）落像素；`FsQueryTableObjRowDetails` 一律报 `cCells=0`（本侧确未排单元）⇒ 单元内文本仍不绘出。

---

## §1 断点逐跳（从 `T-A52` 的具名前沿到本趟）

| 跳 | 件:行（内容锚） | 现取 |
|---|---|---|
| ① `T-A52` 的具名前沿 | `P1-tail2-floatercbk-impl-report.md` §6：Table 族五入口 ＋ `GetTableObjHandlerInfo`／`FSTABLEOBJCBK` | 本趟落地 |
| ② 驱动 Floater 内容子页 | `FloaterParagraph.FormatFloaterContentFinite`（`Pts.cs:2581`）→ `FsCreateSubpageFinite` | ✅ 本侧真造子页（`T-A52` 已落地） |
| ③ 子页内容树里的段 | `wpf_pts_sub_enum_into`（`+136`／`+144` 窗内枚举） | ✅ 现取 `[SUBPAGE] … cParas=1 cont_children=1`；本侧用 `+168 pfnGetParaProperties` 读 `FSPAP.idobj` ⇒ **`idobj==3`（`TableParagraphId`）** 命中 `nmTable=0x1d` |
| ④ 索表 handler | `PtsHost.GetObjectHandlerInfo`（`PtsHost.cs:1096`，`idobj==TableParagraphId`）→ `PtsCache.GetTableObjHandlerInfoCore`（`:353`）→ `PTS.GetTableObjHandlerInfo` | ✅ 本侧 `+600` 发调 ⇒ `[FSTABLEOBJ-CBK]`（**真实现**，见 §2.2） |
| ⑤ 取行 | `FSTABLECBKFETCH.pfnGetFirstRow`／`pfnGetNextRow`（槽 9／10） | ✅ 现取 `nrows=5`（行句柄真返回值） |
| ⑥ 行属性 | `FSTABLECBKFETCH.pfnGetRowProperties`（槽 16） | ✅ `cCells=1/2/2/2/1`、行距 `1500` |
| ⑦ 置 `_calculatedColumns` | `TableParaClient.Autofit`（`PtsHost.cs:3299` → `TableParaClient.cs` `ValidateCalculatedColumns`） | ✅ 在**真客户端**上补调（§2.5）⇒ `Invariant.Assert(CalculatedColumns != null)` 成立 |
| ⑧ 查询面 | `TableParaClient.QueryTableDetails`（`TableParaClient.cs:1373`）⇒ 五个 `PTS.FsQueryTableObj*` | ✅ **本趟导出且真服务** ⇒ `ArrangeOverride` **不再抛** ⇒ 整页绘出 |

⇒ `T-A52` 的诚实前沿（Table 族）**在本趟解**；第 4 色**真达**。

---

## §2 改动（逐处；全部在 `win32_pts.c`，附导出面重产）

### 2.1 形状/偏移（内容锚「`T-A53`（`NATIVE-PTS-TABLEOBJ`）：Table 族（`FSTABLEOBJINIT`／`FSTABLEOBJCBK`）的**唯一形状/偏移定义处**」块）
`FSTABLEOBJINIT`（`Pts.cs:1852`）＝ `{FSTABLEOBJCBK(5); FSTABLECBKFETCH(15); FSTABLECBKCELL(14); FSTABLECBKFETCHWORD(11);}` ⇒ **45 槽／360 B**；槽号逐字（`0 pfnGetTableProperties`／`1 pfnAutofitTable`／`9 pfnGetFirstRow`／`10 pfnGetNextRow`／`16 pfnGetRowProperties`／`17 pfnGetCells`／`20 pfnFormatCellFinite`／…）。C 侧原型照 `Pts.cs` 逐参（`FSTABLEROWPROPS`＝11×int＝44 B）。驱动入口 `TableParagraphId`（`PtsHost.cs:86`）＝ **3**。

### 2.2 `GetTableObjHandlerInfo`（由 `return wpf_pts_gap("GetTableObjHandlerInfo");` 改为真实现）
入参即 `FSTABLEOBJINIT*` ⇒ **只读捕获** 45 个函数指针值（**不 deref** 托管结构；同 `GetFloaterHandlerInfo` 体例）＋ 出参非空时逐槽转写；`NULL` init ⇒ 拒（出参一字不写）。两条都可复核（`[FSTABLEOBJ-CBK]` 行；自检成对断言见 §2.8）。

### 2.3 运行期闸
新增 `wpf_pts_tableobj_gate()`：**缺省 `WPF_PTS_TABLEOBJ_DEFAULT 0`（关）**；显式 `=1` 才开（反极性腿用）。缺省关 ⇒ `wpf_pts_tbl_find()` 恒空 ⇒ 表驱动／Autofit 补调／五入口真服务**全部不发生**（逐格零回归）。

### 2.4 窗内表模型驱动（`wpf_pts_tableobj_drive`，从 `wpf_pts_format_one_para` 的 Floater 支末尾调）
`rcf2==0 ∧ sub_obj ∧ gate` 时，对新建内容子页：① 在内容树里找 `idobj==3` 的段（`+168`）；② `+600` 索 handler；③ 窗内 `+176` 现造 `TableParaClient`（保留不回收，同 `t160` 体例）；④ `pfnAutofitTable`；⑤ 循环 `pfnGetFirstRow`／`pfnGetNextRow` 取行，逐行 `pfnGetRowProperties`；⑥ 入册 `g_pts_tbl[]`（键＝`nmTable`）。**零假值**：任一 `rc≠0` ⇒ 该跳不记账（具名留痕）。行高只由 `pfnGetRowProperties` 原值派生（`dvrRowHeightRestriction>0` 取之，否则 `dvrAboveRow+dvrBelowRow`，不足下界 `200` textdpi 则取下界并**具名** `NOINFO=row-height-self-convention`）。
⚠️ **换代（实测逼出）**：首版"同表已有模型就不重建"⇒ 旧一代 `RowParagraph` 句柄被托管回收后**回收成别类对象**（`[HC-UNHANDLED] InvalidCastException: Line → RowParagraph` @ `TableParaClient.UpdateChunkInfo`）⇒ 改为**每次窗进入都重建行**（`m->nrows=0; m->autofit_done=0`），行句柄**逐窗一致**（`0x20…0x2b`）。

### 2.5 `FsQuerySubtrackParaList` 填充分支**补调 Autofit**
🔴 **真因（实测）**：`TableParaClient.ValidateVisual` 的 `Invariant.Assert(… CalculatedColumns != null)` 判的是**该客户端实例**的 `_calculatedColumns`；而视觉树里的 `TableParaClient` 是 `FsQuerySubtrackParaList` 用 `+176` 现造的**另一个实例**（`[FSQSPL] … made=3`）—— 窗口内那个 `tclient` 是**另一个实例** ⇒ 对它 Autofit **不生效**。修法：在填 `FSPARADESCRIPTION` 时，对**本侧表模型的表段落**用**真客户端句柄**补调一次 `pfnAutofitTable`（`tm->autofit_done` 保证每模型一次）。**零假值**：`rc≠0` ⇒ 具名 `[FSTABLEOBJ-AUTOFIT] … v=AUTOFIT-FAIL`（不冒充成功）。

### 2.6 Table 族**五入口**（`win32_pts.c` 新块）
`FsQueryTableObjDetails`（按 `_paraHandle` 认模型；⚠️ 托管 `_paraHandle` 来源 ＝ `FsQueryTableParaList` 的 `pfspara` ＝ **本侧子轨对象句柄** ⇒ 先用 `wpf_pts_sub_claim` 按对象身份还原成 `o->nmp` 再查模型）／`…TableProperDetails`（按表 token 认，报 `dvrTable`／`cRows`）／`…RowList`（逐条填 `FSTABLEROWDESCRIPTION`：`fsupdinf.fskupd=New`、`fsnmRow`＝行句柄真值、`pfstablerow`＝本侧 token、`u.dvrRow`）／`…RowDetails`（按行 token 认；**`cCells=0` 的诚实的空**）／`…CellList`（本侧未排单元 ⇒ 列恒空）。布局含 `_Static_assert` 钉死（`FSTABLEOBJDETAILS`＝56 B／`FSTABLEROWDESCRIPTION`＝48 B／`u@28`／`FSTABLEROWDETAILS`＝24 B）。**无模型 ⇒ 诚实拒**（`-10000` ＋ 具名 `[FS_PAGE_GAP]`，出参一字不写）。

### 2.7 复述位现值位（只读改数；**无新增 D-G 编号**）
`D-G70` 在册数随权威件跟随：`tool 76→71`／`ops 64→59`／`impl 66→60`（＝ `stubs` 少 1 的**事实**）、`exports 683→688`、`so16 →3ff91579e7ea3efa`。逐件：`docs/ROUTES.md`（3 处）／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`。**历史 dated 行原文保留**（判据 `pts-gap-count-check.sh` 的"自引旧代锚 ＋ dated 措辞"分类法）。

### 2.8 自检成对断言
旧断言 `GetTableObjHandlerInfo(sb, sp) != -10000 ⇒ rc=7/8`（**已随真实现作废**）改为**成对断言**：`GetTableObjHandlerInfo(NULL, sp) != -10000 ⇒ rc=8`（NULL 必被拒）＋ `GetTableObjHandlerInfo(sb, NULL) != 0 ⇒ rc=73`（有效 init、空 out ⇒ 真实现必须成功）。**同趟把夹具 `sb`／`sp` 由 256 B 加到 512 B** —— 真实现按契约读 `FSTABLEOBJINIT`（45×8＝360 B），旧 256 B 夹具上那次调用**越界**（本步堵掉）。

### 2.9 导出面重产
`bash src/WpfGfx.Linux.Native/build-shim.sh --symbols` ⇒ `bin/exports.txt`（**688 行**）＝ `nm -D --defined-only` 逐名 `diff` 零差异。**`build-shim.sh` 一字未动**（`+5` 的新符号由 `-fvisibility=default` 自然导出）。

### 2.10 为什么**不是**改生成器
本轮**一个字节都没碰** `reapply-patches.py` 与其重产件 —— 本增量全在 native（托管的 `FormatFloaterContentFinite`／`FsCreateSubpageFinite`／`TableParaClient` 链在 `T-A37`／`T-A52` 已备）。

---

## §3 成对读数（**同一 `.so 3ff91579e7ea3efa`／同一 `pf 1c6c58df6d757f3f`／同装置 `:231`／同批工具**；证据 `~/tA53-work/legs/{off2,on4,pol1}`；三腿 `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`）

| 腿 | env | 证据目录 |
|---|---|---|
| `off2` | 缺省（两闸皆关） | `~/tA53-work/legs/off2/` |
| `on4` | `WPF_PTS_FLOATER_CBK=1 WPF_PTS_TABLEOBJ=1` | `~/tA53-work/legs/on4/` |
| `pol1` | `WPF_PTS_FLOATER_CBK=1 WPF_PTS_TABLEOBJ=0`（反极） | `~/tA53-work/legs/pol1/` |

### 3.1 逐腿现取计数（`grep -c`，`app_g1.log`）

| 量 | `off2`（缺省） | **`on4`（驱动）** | `pol1`（反极） |
|---|---|---|---|
| `[FSTABLEOBJ-CBK]` | **0** | **2** | 0 |
| `[FSTABLEOBJ-DRV]` | **0** | **2**（`TABLE-MODEL-BUILT nrows=5`） | 0 |
| `[FSTABLEOBJ-ROW]` | **0** | **10**（2 窗 × 5 行） | 0 |
| `[FSTABLEOBJ-AUTOFIT]` | **0** | **2**（`AUTOFIT-ON-REAL-CLIENT`） | 0 |
| `[FSTABLEOBJ-Q]` | **0** | **8903**（`ok`） | 0 |
| `FSFLOATER-CONTENT` | **0** | **2** | 2 |
| `entry point named` | **0** | **0** | 0 |
| `[HC-UNHANDLED]` | **0** | **0** | **314**（`PtsException '-10000'`＝`no-table-model` 的**诚实拒**） |
| `app_g1.log` 行数 | 57632 | 70961 | 13161 |

### 3.2 帧面（逐腿现取：`leg_*.env` ＋ 只读 PNG）

| 腿 | `alive` | `app_rc` | `magenta` | `colors`(k24) | `ink` | `ns`(k24) | `k24` `fr_sha` | `k23` `fr_sha` | `boot` `fr_sha` | `fr_ae_boot` |
|---|---|---|---|---|---|---|---|---|---|---|
| **`off2`** | yes | 143 | 0 | **905** | 480000 | `…FlowDocumentDemo` | **`791696291d51470b`** | `10d0b9d54e649c10` | `b21eb530afd3c66c` | 220019 |
| `on4` | yes | 143 | 0 | **910** | 480000 | 同 | **`64603fc1d8e23e39`** | `10d0b9d54e649c10` | `b21eb530afd3c66c` | 220019 |
| `pol1` | yes | 143 | 0 | **383** | 480000 | 同 | `ef3fd6765f18f51b`（空态参照成员） | `10d0b9d54e649c10` | `b21eb530afd3c66c` | 15386 |

**帧差（本席自算，只读 PNG）**：`AE(boot_off, boot_on)=0`、`AE(k23_off, k23_on)=0`、**`AE(k24_off, k24_on)=3791`** ⇒ 两极的差**只落在被驱动的那一页**（`k23`／`boot` 逐字节同值）；`off2↔on4` 的 `fr_sha` 不同、`k24` 色数 `905→910`。

### 3.3 帧面四色锚（**本席自算**，只读 PNG；锚集 `GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`；`LightGray` **不入集**）

| 帧 | 腿 | `GhostWhite` | `Beige` | `DarkGreen` | **`LightGoldenrodYellow`** | `ncolors` |
|---|---|---|---|---|---|---|
| `boot` | 三腿同值 | 0 | 0 | 0 | **0** | 386 |
| **`k24`** | **`off2`** | **22736** | **910** | **44** | **0**（baseline） | **905** |
| **`k24`** | **`on4`** | **18945** | **910** | **44** | **1998**（**≥200**） | **910** |
| `k24` | `pol1` | 0 | 0 | 0 | 0（反极） | 383 |
| `k23` | 三腿同值 | 0 | 0 | 0 | 0 | 636 |

### 3.4 判据件读数（`pts-pages-guard.sh --legs`；纯读、零 `dotnet`）

```
# off2（缺省）
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=12 roster=24 …
PTS_N1_POS=phase=realized positive=n4(support=color-anchor:2colors>=200),differ(via=compare) …
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200 base=…all-0 phase=realized
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=…/off2/app_g1.log log_sha16=5622e87891aff9db
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=realized
# on4（驱动）
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=18 roster=24 …
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=18945 Beige=910 DarkGreen=44 LightGoldenrodYellow=1998 hits=3 min=200 … phase=realized
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=…/on4/app_g1.log log_sha16=7995ef27e381b3dc
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=realized
# pol1（反极）
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 … reason=declared-color-anchor-absent
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=…/pol1/app_g1.log log_sha16=0c777c3b943180e0
PTS_GUARD=FAIL legs=2/2 fails=leg24-n1-frame-unestablished(frame-identity(sha16=ef3fd6765f18f51b∈{…})),leg24-color-anchor-absent(hits=0<2,…) … phase=realized
```

### 3.5 门禁五件（现取）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **688** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=71 dead=11 artifact=1 ops=59 impl=60 so16=3ff91579e7ea3efa exports=688` | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`（`DECLDRIFT=0`；**本趟改的复述位件无需重发 `declared.tsv`** —— 无新增/删减 D-G 编号） | 0 |
| `REPORTID` | `PASS files=330 ids=2238 declared=225`（本件**落盘前** 330 ⇒ 落盘后 331，`+1` 即本件） | 0 |
| 自检面 | `PtsGapSelfCheck=1`／`Diag=0`／`(2nd)=1`（幂等） | — |

---

## §4 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `4d0767892092cb55` | **`17b1aacb19dbfa53`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `1067da454b7ef114`（457840 B） | **`3ff91579e7ea3efa`**（462648 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `860a3abe4a64f1c5`（683 行） | **`c7a1298c812e4e31`**（688 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `f62bce16f135c244` | **`905c7b751aa62c26`** |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `478cc0fe61728c88` | **`088300256ed9139d`** |
| `docs/ROUTES.md` | `61cb492bbda0b530` | **`d29674e451c2ebc8`** |
| `README.md` | `ccbfcf3a1228b05a` | **`cef87d5db843e92a`** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `1483ff5bcbd52ed8` | **`2725ccc1aa9c8c51`** |
| `build/MilBridge/HANDOFF-NEXT.md` | `cba86d1e49ec8a66` | **`dc2facca3db2f4dc`** |
| `docs/unimplemented.md` | `9e15a186890f7ca5` | **`ec6b342e96a2d319`** |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `b6a3a24137a77ddf` | **未变** |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `1c6c58df6d757f3f` | **未变** |

---

## §5 诚实边界（防读宽，逐条）

1. **只让"行背景"落像素，未排单元内容**：模型来自托管 `pfnGetFirstRow`／`pfnGetNextRow`／`pfnGetRowProperties` 的**真返回值**（5 行、`cCells=1/2/2/2/1`），但本侧**不调** `pfnFormatCellFinite` ⇒ `FsQueryTableObjRowDetails` 一律报 **`cCells=0`**（**诚实的空**）；`FsQueryTableObjCellList` 恒填 0 条。⇒ **`LightGoldenrodYellow` 是 `TableRow Background`（行层）**，**不**证"表单元文本已绘出"。行内文本/单元几何**不在本增量射程**（具名下一靶，§6）。
2. **行高是本侧约定**：`pfnGetRowProperties` 的 `dvrRowHeightRestriction` 恒 0 ⇒ 取 `dvrAboveRow+dvrBelowRow`（＝`1500` textdpi）并**具名** `NOINFO=row-height-self-convention`。**不**声称与上游 ABI 几何可比。
3. **表几何是本侧约定**：`fsrcTableObj = (0,0,autofit_wtbl,ΣdvrRow)`（`autofit_wtbl=92100` 来自托管 `pfnAutofitTable` 真返回；原点本侧取 0）⇒ 具名 `NOINFO=table-geometry-self-convention`。
4. **Autofit 在**真客户端**上补调，是本侧为满足托管 `Invariant.Assert` 的**必要**动作**；它在 `FsQuerySubtrackParaList`（查询期）发起 —— 现取 `rc=0`（`[FSTABLEOBJ-AUTOFIT]`），**不**声称它与上游"在排版期由引擎调"时序相同。
5. **换代重建是被现场逼出的**：首版幂等 ⇒ 旧 `RowParagraph` 句柄回收成 `Line` ⇒ `InvalidCastException`（已消）。本侧如实记该过程（§2.4），**不**声称一次就对。
6. **`bin/exports.txt` 非仓内件**：`src/WpfGfx.Linux.Native/bin/` 在 `.gitignore:24` ⇒ 该件由 `build-shim.sh --symbols` **每次重产**；`nm==exports` 是**构建不变量**（不是"我们手工对齐了一份表"）。⇒ 本增量的"导出面 ＋5"**落在 `.so` 与 `exports.txt` 的现取读数**上。
7. **`pol1` 的 `[HC-UNHANDLED]=314` 是**反极性腿**的**有意红**（`no-table-model` 的诚实拒），**不是**缺省路径症状；缺省（`off2`）与驱动（`on4`）两腿 `[HC-UNHANDLED]=0`、`entry point named=0`。
8. **`D-G70` 在册数的三点跟随**：`tool 76→71`（**5 条 `DllImport` 离开缺口名单**）／`ops 64→59`／`impl 66→60`（**`stubs` 少 1**）—— 与 `check-shim-coverage.py` ＋ `wpf_pts_gap(...)` 条数两条**独立**路径现取一致（`PTSGAP=PASS`）。

---

## §6 遗留（下一增量具名靶）

- **表**单元内容**排版**：调 `pfnFormatCellFinite`（槽 20）为每个单元真造内容子页（照 `T-A37` 对 `Figure` 同形），并把 `FSTABLEROWPROPS.cCells`／`FsQueryTableObjRowDetails.cCells`／`FsQueryTableObjCellList` 填成**真值** ⇒ 表内文本落像素（现取 `[FSTABLEOBJ-Q] … src_cCells=1/2` 已指明单元数，但本侧未排）。
- **行高改由单元高派生**：`dvrRow = max(cell dvrUsed) + dvrAboveRow + dvrBelowRow`（取代本侧下界约定）。
- **`WPF_PTS_FLOATER_CBK` 与 `WPF_PTS_TABLEOBJ` 的缺省翻转**：两者**缺省关**；当"表单元内容排版"落地且无回归后，才按 `T-A28→T-A31` 体例翻缺省并给成对腿。

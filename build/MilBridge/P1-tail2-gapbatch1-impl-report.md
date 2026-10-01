# `P1-tail2` · `T-A61` · `Fs*` 族缺口首批（8 条）—— 实现报告（**判决：8 条可诚实实现者已真实现并导出；诚实拒绝留在缺口面；两极化（正极真值 ∧ 反极必拒）现取 `mask=0xff`、反腿副本 `mask=0xfd`；在册数 `tool 70→62／ops 58→50／impl 59→51／exports 689→701` 逐字段现算对账 `PTSGAP=PASS`；`nm==exports` 零差异；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3` **未回退**；两腿帧 `AE=0`**）

- **读时**：`2026-10-01T17:5x–18:0x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`（**未 `git add/commit/push`**）。
- **改前件备份（仓外 `~/tA61-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`1eb3408fc4567d53`）／`bin/exports.txt`（`005b16e0cd5b95b2`）／`bin/libwpfwin32.so`（`d406f243cdc2c402`）／`pts-gap-decl.txt`（`94ecbd53b08d3885`）／`docs/ROUTES.md`（`47c26e80e5d93fd3`）／`README.md`（`168c190a1c020bbe`）／`docs/unimplemented.md`（`fdb221d64f8b8b69`）／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`48f5f5030518b132`）／`HANDOFF-NEXT.md`（`6c9b1fa586518fa1`）／`win32_classification.c`（`74b5247e5ee6c4d0`）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**新增一段：8 条 `Fs*` 真实现 ＋ 逐条两极化自检 ＋ 4 个只读桥接 + struct 加一字段**）／`src/WpfGfx.Linux.Native/bin/exports.txt`（**构建重产**，非手改）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（DECL 行五数 ＋ `so16` ＋ `exports` ＋ dated `T-A61` 重锚追注）／**复述位现值位**（`docs/ROUTES.md` 三处／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 两处 ＋ `T-A52..A57` 归因段末追 `T-A61`／`build/MilBridge/HANDOFF-NEXT.md`：`§3` 新增 `T-A61` 收口行 ＋ 文件尾机器值契约 `cell=#1／#3` 追写／`src/WpfGfx.Linux.Native/src/win32_classification.c` 注释现值位）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（生成器一字未动）⇒ 其重产件亦未动（`PresentationFramework.dll` 仍 `1c6c58df6d757f3f`）；`docs/WAVE66-PREREGISTRATION.md`（**冻证据**）`w66pre16=bf6b683d94549087` 未动。
- **黑名单遵守**：未动 `build/MilBridge/tools/**`（**只读跑**判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`build/PresentationFramework.Linux/**`／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**1 趟 native 构建**（槽内 `<5 s`）＋ **2 趟跑器**（共 **4 条腿**）＋ **1 趟反腿副本构建**，全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`（逐趟 `HEAVYSLOT=RELEASED rc=0`）；进程只按 PID；显示位只用空闲 `:23x`（逐趟 `DISPLAY_PICK :231`／`DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p`；`temp+rename`；模式守恒。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`diff`／`grep -c`／dlopen 探针 `gcc` 编译的 `~/tA61-work/probe`／只读 `python3`＋`PIL` 自算 `AE`／`bash build/MilBridge/tools/{pts-gap-count-check,pts-pages-guard,defect-registry-check,report-id-domain-check,handoff-machine-values-check}.sh`）。

---

## §0 结论速览（自包含）

1. ✅ **8 条真实现（非恒 `-10000`）＋ 该红必红**：新增导出 `FsDestroySubtrack`／`FsClearUpdateInfoInSubtrack`／`FsGetSubtrackColumnBalancingInfo`／`FsTransferDisplayInfoSubtrack`／`FsTransferDisplayInfoSubpage`／`FsCompareSubtrack`／`FsCompareSubpages`／`FsSynchronizeBottomlessSubtrack`（语义逐字照 `Pts.cs`／`PtsHost.cs`，逐条见 §1）。**两极化（dlopen 探针现取）**：改前 8 名 `present=0/8`（缺符号）；改后 `present=8/8` 且 `[FSBATCH1-SELFTEST] mask=0xff`＝8/8「正极真值 ∧ 反极必拒」；**反腿副本**（去掉 `FsClearUpdateInfoInSubtrack` 的对象身份认领）⇒ `mask=0xfd`（**该位必红**）。
2. ✅ **诚实准入铁律**：只收**无几何出参**（生命周期/状态搬运/位移累积）或出参**可由本侧真台账导出**（行计数/行高来自 `fl_line[]` 行记录，`T-A28`）者；出参含**真几何**而无源者**一律不冒充**（`FsUpdateBottomlessSubtrack/Subpage`／`FsFormatSubtrack*`／`FsQuery*ColumnList`／`FsGet*FootnoteInfo`／`*BreakRecord` 生命周期／`FsTransform*` 等）——**保持原样并如实划界**（见 §5）。
3. ✅ **在册数逐字段现算对账**：`PTSGAP=PASS tool=62 dead=11 artifact=1 ops=50 impl=51 so16=2852242a1c946d1f exports=701`（`rc=0`）；`dead/artifact/w66pre16` 未动；`nm -D --defined-only` ＝ `exports.txt` ＝ **701**（逐名 `diff` **零差异**）。**8 条 = 缺口下降的条数**（`ops 58→50`）**逐字段一致**。
4. ✅ **门禁未回退**：`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS k=24 hits=3`（两腿同）／`PTS_ENFE=PASS total=0`；`DEFREG=PASS`／`REPORTID=PASS`／`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`。
5. ✅ **症状门 ＋ 帧面成对（只差 `.so`）**：腿 `before`（旧 `.so d406f243cdc2c402`）与 `after`（新 `.so 2852242a1c946d1f`）三帧**逐字节相同**（`AE=0`：`boot`／`k23`／`k24`）、症状门逐格同（`alive=yes／app_rc=143／magenta=0／ink=480000／colors 386/636/1220／ns=…FlowDocumentDemo`／`[HC-UNHANDLED]=0`／`entry point named=0`）。
6. 🔴 **计数下降 ≠ 能力前进**（件头第 ① 条同口径）：8 条在**现产品路径未被调用**（两腿 `[FSBATCH1]` 命中 **0**；`k24 fr_sha` 均 `0bdb2dfd05952bc9`）⇒ 本增量把**缺符号**变成**有符号的真实现**，**页仍未被全绘**（症状门由腿读数给）。**具名下一靶**：其余 `Fs*` 缺口里"出参可由本侧台账导出"者（`FsGet*ColumnBalancingInfo` 的 subpage 支／`FsQuerySubpageBasicColumnList` 等）。

---

## §0.5 方案（本趟**单方案**；未做多方案试探，上限 3 未用满，如实记）

| 方案 | 形态 | 现取读数 | 判决 |
|---|---|---|---|
| **1** | 只收**无几何出参**或出参**可由本侧真台账导出**的 8 条；每条先认领后动作，反极必拒；附 native 逐条两极化自检 ＋ dlopen 探针 | `mask=0xff`（正极＋反极 8/8）；反腿副本 `mask=0xfd` | ✅ **达** |

> 「出参含真几何而无源者」被**显式排除**（不是"没来得及"）：本侧**不是** PTS 排版引擎的作者，几何是托管引擎的产物；本侧只作**自持对象**（子轨/子页）的作者 ⇒ 凡"要交出几何"的入口，本侧**无源** ⇒ 保持缺口、不冒充。**故无「方案 2／3」**。

---

## §1 逐条（件:行语义出处 ＋ 实现前后成对读数）

> 「实现前」＝ dlopen 探针 `present=0`（缺符号 ⇒ 托管一旦到达即 `EntryPointNotFoundException`）；「实现后」＝ `present=1` ＋ 自检正极真值（真返回值可现取）＋ 反极必拒（`-10000` ＋ 具名 `[FS_PAGE_GAP]`）。

| # | 入口（声明 件:行 → 调用点 件:行） | 诚实语义（逐字） | 实现前 | 实现后（正极 ⇒ 真值／反极 ⇒ 拒） |
|---|---|---|---|---|
| ① | `FsDestroySubtrack` `Pts.cs:3412-3414` → `PtsHost.cs:2887-2891 SubtrackDestroyPara` | **真销毁**该子轨对象（**递归**整棵 `child_objs[]` 子树；销毁前 `wpf_pts_b1_detach` 清掉所有指向它的引用位 ⇒ **不留悬垂**） | `present=0` | 正极：`rc=0 v=DESTROYED-RECURSIVE` ∧ 之后 `wpf_pts_sub_claim` 不再认领；反极：`NULL`／`0xDEAD` ⇒ `rc=-10000 reason=null-subtrack/unknown-subtrack` |
| ② | `FsClearUpdateInfoInSubtrack` `Pts.cs:3407-3409` → `PtsHost.cs:2881-2885` | 按**对象身份**认领后清该子轨增量更新状态；本侧 `FsQuerySubtrackDetails` 的 `fsupdinf` 是**恒报值**（成功分支写死 `fskupd=Inherited`、`dvrShifted=0`，并已具名 `NOINFO-FSUPDINF-SEMANTICS`）⇒ "清更新信息"**无需改状态**即与查询面自洽（承 `T-A56` `FsClearUpdateInfoInSubpage` 先例，**不**冒充稳态） | `present=0` | 正极：`rc=0 NOINFO=fsupdinf-constant-consumer`；反极：`0xDEAD` ⇒ `rc=-10000 reason=unknown-subtrack` |
| ③ | `FsGetSubtrackColumnBalancingInfo` `Pts.cs:3428-3434` → `PtsHost.cs:2912-2919 SubtrackGetColumnBalancingInfo` | `nlines`＝`fl_nlines`；`dvrSumHeight`＝`Σ(dvrAscent+dvrDescent)`；`dvrMinHeight`＝`min(...)`；**唯一来源＝本侧真行台账**（`fl_line[]`，`T-A28` 由 `pfnFormatLine` 真返回值入账）；可用性判据＝`wpf_pts_fl_usable`（已录 ∧ 收束段尾 ∧ 未撞界 ∧ ≥1 行） | `present=0` | 正极：`nlines=2 dvrSumHeight=31 dvrMinHeight=15 src=fl_line[]`；反极：无台账对象 `⇒ reason=no-line-ledger`（出参**先清 0**）、`0xDEAD ⇒ unknown-subtrack`、`NULL` 出参 `⇒ null-out` |
| ④ | `FsTransferDisplayInfoSubtrack` `Pts.cs:3469-3472` → `PtsHost.cs:2949-2953 SubtrackTransferDisplayInfoPara` | 把 **old** 子轨自持的显示信息（行台账 `fl_line[]` ＋ `fl_*` 计数 ＋ `sync_vr`）逐字段搬到 **new**；两对象均须在册 | `present=0` | 正极：`rc=0` ∧ `same(A,C)=1`；反极：`0xDEAD`（old／new 各一）⇒ `unknown-old/unknown-new` |
| ⑤ | `FsTransferDisplayInfoSubpage` `Pts.cs:3309-3312` → `PtsHost.cs:3248-3252 SubpageTransferDisplayInfoPara` | 把 **old** 子页自持显示信息（`dvr_used`／`fsrc`／`c_paras`）搬到 **new**；两对象均须在册 | `present=0` | 正极：`dvrUsed=31 fsrc=(5,7,100,200)` ∧ `same(S1,S2)=1`；反极：`0xDEAD` ⇒ `unknown-old/unknown-new` |
| ⑥ | `FsCompareSubtrack` `Pts.cs:3398-3404` → `PtsHost.cs:2871-2879 SubtrackComparePara` | 结果**只**取自本侧两对象**自持数据**的逐字段比较（`Pts.cs:823` 值域）：等价 ⇒ `fscmprNoChange(0)`，否则 `fscmprChangeInside(1)`；**位移**本侧无源 ⇒ `dvrShifted=0`（**不**冒充 `fscmprShifted`，具名 `NOINFO-FSCOMPRESULT-SHIFT`） | `present=0` | 正极：同数据 `fscmpr=0`／异数据 `fscmpr=1`；反极：`0xDEAD ⇒ unknown-old`、`NULL` 出参 `⇒ null-out` |
| ⑦ | `FsCompareSubpages` `Pts.cs:3256-3260` → `PtsHost.cs:3174-3179 SubpageComparePara` | 同 ⑥，作用在**子页**对象上（比较 `dvr_used`／`fsrc`／`c_paras`） | `present=0` | 正极：`fscmpr=0`；反极：`0xDEAD ⇒ unknown-old`、`NULL` 出参 `⇒ null-out` |
| ⑧ | `FsSynchronizeBottomlessSubtrack` `Pts.cs:3390-3395` → `PtsHost.cs:2843-2861 SubtrackSynchronizeBottomlessPara` | 按对象身份认领后把 `vrShift` **真累加**到本侧该子轨的位移累积位（`sync_vr`）；**无出参** ⇒ 不伪造几何/bbox（具名 `NOINFO-FSGEOMETRY-LAYOUT`） | `present=0` | 正极：`+7` 再 `+5 ⇒ sync_vr=12`（字段可现取）；反极：`0xDEAD ⇒ unknown-subtrack` |

> 语义出处铁律：每个入口的**行为形状**由 `Pts.cs` 的 `DllImport` 声明（行号见表）＋ `PtsHost.cs` 的**唯一调用点**（行号见表）共同界定；本侧不发明协议（值域常量逐字照 `Pts.cs:823`／`1147`／`1934`）。

---

## §2 改动（逐处）

### 2.1 `win32_pts.c`：8 条真实现 ＋ 自检 ＋ 只读桥接
- **struct 加一字段**：`struct wpf_pts_subtrack_s` 增 `int sync_vr;`（`FsSynchronizeBottomlessSubtrack` 的位移累积位；`calloc` 初值 0 ⇒ 无副作用）。
- **8 条导出**：置于文件 `Fs*` 段末（`WpfLinuxWin32_PtsGapSelfCheck` 之前），共用一个具名失败面助手 `wpf_pts_b1_gap()`（`[FS_PAGE_GAP] rc=-10000 reason=… entry=… out=UNWRITTEN bytes=0`）与成功面 `[FSBATCH1] rc=0 …`；每条的认领谓词复用既有 `wpf_pts_sub_claim`／`wpf_pts_sp_claim_track`（**按对象身份**，NULL／外来值／已销毁值一律拒）。
- **逐条两极化自检** `WpfLinuxWin32_PtsFsBatch1SelfCheck()`：自造 5 子轨 ＋ 2 子页夹具，跑「正极真值 ∧ 反极必拒」，返回 8-bit `mask`；**收尾真销毁全部夹具对象并断言活数回 base**（泄漏 ⇒ `-1`，**不算绿**）；自检只改自己的对象与自己的计数，**不碰应用状态**。
- **只读桥接**（导出，供探针/判据现取）：`WpfLinuxWin32_PtsFsBatch1SelftestMask/Ok/Gap`。
- **反腿开关**：**无**（反腿以**副本 sed** 构造，主链产物**一个字节不带**反腿分支 —— 见 §3.3）。

### 2.2 登记面 `tools/pts-gap-decl.txt`
DECL 行 `tool/ops/impl/so16/exports` 五格更新（`62/50/51/2852242a1c946d1f/701`）；其下**只增**一段 `⚠️ 波 T-A61 重锚` 追注（照 `T-A57` 重锚体例）：述 8 条、诚实准入铁律、计数逐字段、`so16` 换代、字节数变化、判据 ① 成对读数、两极化（探针 mask）。

### 2.3 复述位现值位（只读改数）
`docs/ROUTES.md`（`:262` 一处／`:402` 一处／`:549` 一处）／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（两处现值位 ＋ `T-A52..A57` 归因段末追 `T-A61`）／`src/WpfGfx.Linux.Native/src/win32_classification.c` 的现值位 `58/59/70` ⇒ **`50/51/62`**（`impl`／`ops`／`tool`；`exports 689→701` 只落在 `pts-gap-decl.txt`／`KNOWN-DEFECTS.md`／`HANDOFF-NEXT.md`）。
- `build/MilBridge/HANDOFF-NEXT.md`：`§3` **只增**一行 `T-A61` 收口记录（承 `T-A57` 行）；文件尾**只增**一行机器值契约 `cell=#1／#3`（`inputs_fp` 现取 `bd2e70b2…`，因写域件 `win32_pts.c`／`pts-gap-decl.txt` **在覆盖面内** ⇒ 必然位移）。
- **历史行原文保留**（`docs/ROUTES.md:291`／`:1001`／`KNOWN-DEFECTS.md` 的 `2026-09-24`／`t104`／`T-A37` 行等）—— 它们**自引旧代锚 ＋ dated 措辞**，判据件按裁定九**不参与现值判定**（现取 `PTSGAP_HISTORICAL=n=11`）。

### 2.4 为什么**不是**改生成器
本轮**一个字节都没碰** `reapply-patches.py` 及其重产件 —— 本增量全在 native（**零托管改动**）。

---

## §3 成对读数（**同装置 `:231`**；证据 `~/tA61-work/`）

### 3.1 探针（dlopen ＋ dlsym ＋ 自检；`present` 与 `mask` 本席现取）

| 读数 | **改前**（旧 `.so d406f243cdc2c402`） | **改后**（新 `.so 2852242a1c946d1f`） |
|---|---|---|
| 8 名 `present` | **0/8**（缺符号） | **8/8** |
| `WpfLinuxWin32_PtsFsBatch1SelfCheck` 符号 | 0 | 1 |
| `PROBE SELFTEST_MASK` | （无符号） | **`0xff`**（`destroy/clear/balancing/xfer_sub/xfer_sp/cmp_sub/cmp_sp/sync = 1`） |
| 判词 | — | `[FSBATCH1-SELFTEST] mask=0xff … legs=8/8(POS+REJECT)` |

**正极真值（`mask` 的承重读数，逐条可现取）**：`FsGetSubtrackColumnBalancingInfo` ⇒ `nlines=2 dvrSumHeight=31 dvrMinHeight=15 src=fl_line[]`；`FsCompareSubtrack` ⇒ 同数据 `fscmpr=0`／异数据 `fscmpr=1`、`dvrShifted=0`；`FsSynchronizeBottomlessSubtrack` ⇒ `sync_vr 7→12`；`FsTransferDisplayInfoSubpage` ⇒ `dvrUsed=31 fsrc=(5,7,100,200)`；`FsDestroySubtrack` ⇒ 销毁后不可再认领。

### 3.2 反极性（该红必红）
每条入口的**反极腿**在自检内**同一谓词**判（§1 表"反极"列）：`NULL`／外来值（`0xDEAD`）／已销毁值 一律 `rc=-10000` ＋ 具名 `[FS_PAGE_GAP]`，出参**一字不写**（`out=UNWRITTEN bytes=0`）；`FsGetSubtrackColumnBalancingInfo` 另加「**无台账对象**必拒（出参先清 0）」与「**NULL 出参**必拒」两条。

### 3.3 反腿副本（**证明自检真有牙**）
以 `sed` 造**仓外副本** `~/tA61-work/badrepl/`：仅去掉 `FsClearUpdateInfoInSubtrack` 的**对象身份认领**（对任意句柄也返 0）⇒ 同一探针现取 **`mask=0xfd`（`clear=0`）** ⇒ 该位**必红**、自检**不是恒真**。**主链产物不含任何反腿分支**（一个字节不受影响）。

### 3.4 腿（`run-pts-pages-legs.sh`；两条腿**只差权威 `.so`**，其余全同）

| 腿 | 权威 `.so` | 证据目录 | `LEGS_RUNNER` |
|---|---|---|---|
| `before` | `d406f243cdc2c402`（改前） | `~/tA61-work/legs/before/` | `PASS requested=2 obtained=2 refused=0` |
| `after` | `2852242a1c946d1f`（改后） | `~/tA61-work/legs/after/` | `PASS requested=2 obtained=2 refused=0` |

**症状门（逐腿现取）**：

| 量 | `before` | `after` |
|---|---|---|
| `k24` | `alive=yes app_rc=143 magenta=0 colors=1220 ns=…FlowDocumentDemo ae=220019 ink=480000` | **同** |
| `k23` | `alive=yes app_rc=143 magenta=0 colors=636 ns=…RichTextBoxDemo ae=136292 ink=480000` | **同** |
| `boot` | `colors=386 magenta=0 ink=480000` | **同** |
| `[HC-UNHANDLED]` / `entry point named` / `[FSBATCH1]` | `0` / `0` / `0` | `0` / `0` / **0**（8 条**未被调用**） |
| `PTS_COLORANCHOR` | `PASS k=24 hits=3`（`GhostWhite=9794 Beige=910 DarkGreen=44 LightGoldenrodYellow=5830`） | **PASS hits=3**（同值） |
| `PTS_GUARD` | `PASS legs=2/2 fails=- cannot=-` | **PASS legs=2/2** |
| `PTS_ENFE` | `PASS total=0` | **PASS total=0** |

**帧面成对（本席自算，只读 PNG）**：`AE(before,boot)=0`／`AE(before,k23)=0`／`AE(before,k24)=0`（`fr_sha` 逐格相等：`boot`／`k23=10d0b9d54e649c10`／`k24=0bdb2dfd05952bc9`）⇒ **8 条入口在现产品路径未被调用 ⇒ 逐字节零位移**（这正是本节要证的事，不是"没测"）。

### 3.5 门禁五件（现取）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **701** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=62 dead=11 artifact=1 ops=50 impl=51 so16=2852242a1c946d1f exports=701` | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`（`DECLDRIFT=1 keys=KD`：本趟改 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 现值位 ⇒ 该 route 件离开 `defect-registry-declared.tsv` 的 `DECL-ANCHORS KD=`；而 `declared.tsv` 在**黑名单** `build/MilBridge/tools/**` 内 ⇒ **未重发**，如实记） | 0 |
| `REPORTID` | `PASS files=337 ids=2246 declared=225`（本件落盘前 `337` ⇒ 落盘后 `338`，`+1` 即本件） | 0 |
| `HANDOFF_MV` | `PASS cells=9 equal=8 manual=1 mismatch=0`（本趟追写 `T-A61` 收口行 ＋ `cell=#1／#3` 机器值） | 0 |

---

## §4 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `1eb3408fc4567d53` | **`002f9e04264d123c`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**非仓内件**） | `d406f243cdc2c402`（467240 B） | **`2852242a1c946d1f`**（480488 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt`（**非仓内件**） | `005b16e0cd5b95b2`（689 行） | **`7853a5c88214957a`**（701 行） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `94ecbd53b08d3885` | **`2aeb72ccd9bf9dc2`** |
| `docs/ROUTES.md` | `47c26e80e5d93fd3` | **`f36b2dac2b4e7cb9`** |
| `README.md` | `168c190a1c020bbe` | **`b1c87df9833c849c`** |
| `docs/unimplemented.md` | `fdb221d64f8b8b69` | **`d44bb36a473d65ab`** |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `48f5f5030518b132` | **`e93f43d3436d085a`** |
| `build/MilBridge/HANDOFF-NEXT.md` | `6c9b1fa586518fa1` | **`22117579a30516ff`** |
| `src/WpfGfx.Linux.Native/src/win32_classification.c` | `74b5247e5ee6c4d0` | **`2c62ceccc8db156c`** |
| `docs/WAVE66-PREREGISTRATION.md`（**冻证据**） | `bf6b683d94549087` | **未变** |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | — | **未变** |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `1c6c58df6d757f3f` | **未变** |

---

## §5 诚实边界（防读宽，逐条）

1. **"8 条真实现"只主张"符号在册 ＋ 按在册语义真动作 ＋ 反极必拒"，不主张"排版能力前进"**：8 条在现产品路径**未被调用**（§3.4，`[FSBATCH1]` 两腿命中 0、三帧 `AE=0`）⇒ 页仍**未全绘**。**计数下降 ≠ 能力前进**（件头第 ① 条）。
2. **几何一律不冒充**：`FsGetSubtrackColumnBalancingInfo` 的**行高**是**本侧约定**（`dvrAscent+dvrDescent`，与 `fl_vr_start` 同源），且**只在** `wpf_pts_fl_usable` 成立（真行台账）时才给 ⇒ 已具名 `NOINFO=FSGEOMETRY-LAYOUT`；`FsSynchronizeBottomlessSubtrack` **无 bbox 出参**、只累积 `sync_vr`（**不**声称与上游几何可比）。
3. **比较结果只对"本侧自持数据"成立**：`FsCompareSubtrack`／`FsCompareSubpages` 的 `fscmpr` 是**我们两对象数据的比较**（同 ⇒ `NoChange`；异 ⇒ `ChangeInside`），**不**等价于上游"排版是否变化"的判据；`dvrShifted` 恒 0（**不**报 `fscmprShifted`）。
4. **"清更新信息"不改状态**：`FsClearUpdateInfoInSubtrack` 返 0 的依据是**本侧 `fsupdinf` 恒报值**（`FsQuerySubtrackDetails` 成功分支，见 `win32_pts.c` 的 `NOINFO-FSUPDINF-SEMANTICS`）——**不**冒充"稳态 `NoChange`"（与 `T-A56` `FsClearUpdateInfoInSubpage` 同形态）。
5. **被排除的入口是"如实划界"不是"遗漏"**：`FsUpdateBottomlessSubtrack`／`FsUpdateBottomlessSubpage`／`FsFormatSubtrackFinite`／`FsFormatSubtrackBottomless`／`FsQuery{Page,Section,Subpage}*ColumnList`／`FsGet*FootnoteInfo`／`FsDuplicate*BreakRecord`／`FsDestroy*BreakRecord`／`FsTransformRectangle`／`FsTransformBbox` 等**仍留在缺口名单**（出参含真几何/断页记录/变换语义本侧**无源**）。
6. **`bin/*` 非仓内件**：`src/WpfGfx.Linux.Native/bin/` 在 `.gitignore` ⇒ 该件由 `build-shim.sh --symbols` **每次重产**；`nm==exports` 是**构建不变量**（不是"我们手工对齐了一份表"）。
7. **`DEFREG_DECLDRIFT=1 keys=KD`（如实记，非门禁）**：本趟改了 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（现值位）⇒ 该 route 件离开声明锚；`defect-registry-declared.tsv` 在**黑名单**内 ⇒ **本席未重发**（`--emit`）。`DEFREG=PASS`／`rc=0`（该行是**非门禁诊断**）。
8. **自检只改"自己的对象与自己的计数"**：`WpfLinuxWin32_PtsFsBatch1SelfCheck()` 收尾真销毁全部夹具对象并**断言活数回 base**（否则返 `-1` ＝**不算绿**）；它**不**改任何产品状态／台账／计数。
9. **反腿以副本构造**（`~/tA61-work/badrepl/`，仓外）：主链源码**不含**反腿宏/分支 ⇒ 反向不引入产品面分支。

---

## §6 遗留（下一增量具名靶）

- **其余 `Fs*` 缺口（29 − 8 = 21 条可操作）**：凡出参可由**本侧台账**导出者优先（如 `FsGetSubpageColumnBalancingInfo`：可从内容子树的行台账递归汇总）；凡出参含**真几何/断页记录/变换**者，须先有**真源**（本侧无）⇒ 保持缺口。
- **`Fs*` 之外的族**（`Lo*` 19／`Nl*` 6／文本分析 4／`*Wrapper` 4）不在本波射程。
- **`declared.tsv` 的收波随动**：由不在本任务黑名单内的收波步骤完成。

# P1-tail2 · `T-A23` · 重取臂（链推进后）—— 两页是否真排版 ／ 相位评估（测量/侦察件）

> **本件 `T-A23`（测量/侦察子代理）交付**。**写域**：新建新鲜证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2c/`（**新建，未覆盖在册 `evidence/` 与 `evidence-tail2*/`**；无 WM 腿落其**子目录** `evidence-tail2c/nowm/`）＋ 本载体。**未碰** `src/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`／在册证据目录；**未改相位**（本任务只评估）；未 `git add/commit/push`。私有工作区 `W=/home/links-dev/tA23-work`（**仓外**，应用目录 `$W/app` 由 `sync-applocal.sh` 灌成权威五件）。
> **口径引用（不是证据）**：队长**裁定二十**（`P1-ptsname-result.md` 内容锚 `裁定二十（承 t114 回执）`）／**裁定二十一**（同件内容锚 `裁定二十一（承 t117 回执）`）／**裁定三十五**（同件内容锚 `裁定三十五（承 t142 全面回执）`）／**裁定三十六**（同件内容锚 `裁定三十六（承 t146 全面回执）`）作口径；另**旁引**裁定三十八 (a)（撤销三十六 (b) 常开）／三十九／四十二（帧面冻结线）。**它们的读数一条未抄** —— 本件所有读数**现取**（腿跑器同趟新取；守卫现跑）。
> **行号纪律**：本件行号**仅本次有效**；引件一律给内容锚。

---

## §0 结论速览（自包含）

1. **重取说明**：在**新 `.so` `e09c8d739c179966`**（`T-A19/A20/A22` 增量后；`exports 674`，较 `T-A18` 的 `9c19dc0fef35cf4a`／`672` 再进一步）上跑**两页真腿**（`k=23`／`k=24`，A 臂，`run-pts-pages-legs.sh`，私有 `W=/home/links-dev/tA23-work`，私有 display `:231`）：**有 WM 腿**（在册口径，`Xvfb 1280x1024` ＋ `xfwm4`）落 `evidence-tail2c/`；**无 WM 腿**（私有补丁副本，**不改仓内件**）落子目录 `evidence-tail2c/nowm/`。两条腿各 `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`。
2. **两页是否真排版 ＝ 否**（现取）：两腿 `alive=yes`／`app_rc=143`／`magenta=0`／`colors=383`／`ink=480000`／`failfast=0`；但 **`k23`＝`k24`＝`last` 三帧逐字节相同**（有 WM 腿 `sha16=ef3fd6765f18f51b`，各 `189716` B）且**与在册 `evidence/` 的三帧逐字节相同**（`cmp` 现取）⇒ **`N3` 红**（两页帧相同、`AE(k23,k24)=0`）；`k=24` 色锚 `hits=0`（基线全 0 标定）⇒ **`N4`／`C-A` 红**。⇒ **`T-A19/A20/A22` 未改变可见帧面**（症状门逐字段不变）。
3. **链推进的面现取（本趟真进展」）**：新 `.so` 上缺省路径**确实驱到更深、且补掉上一代新增的两条缺口**——`ENFE`（`entry point named`）**2 → 0**（`FsQueryTextDetails`／`FsUpdateBottomlessPage` 均已导出，`nm=exports=674`）；`[VIS]` 3 → **56**、`[CLRUPD]` 1 → **55**、`[FSQSPL]` 355 → **535**、`[FSQSTD]` 707 → **909**（`rc=0 reason=ok` **535**）、`[QPD]` 914 → **708**、`[FS_PAGE_GAP]` 550 → **53**、`[HC-UNHANDLED]` 904 → **427**（**全为 `PtsException`，`EntryPointNotFoundException` 归零**）⇒ **但**帧面＋症状门**一格未动** ⇒ **"计数／留痕前进 ≠ 可见排版前进"**（与 `T-A18` 同一结论，本趟再证）。
4. **相位评估 ＝ 不可翻**（判词＋逐条依据见 §5）。现取 `realized` 副本判词（**只改相位位、不改仓内件**）：有 WM 腿 `PTS_GUARD=FAIL … fails=leg24-n1-frame-unestablished(frame-identity(…)),leg23-n1-frame-unestablished(…),leg24-color-anchor-absent(…)`；无 WM 腿 `PTS_GUARD=FAIL … fails=n1-only-necessary-condition-no-positive-evidence(…),leg24-color-anchor-absent(…)`。⇒ **翻相位＝当场红**（红来自 `N1` 帧身份／正证据闸 ＋ 色锚；**上一代的 `ENFE` 红已消**），且翻的**语义**（"宣布两页真排版成立"）**与事实相反**。
5. **两条"跨代／跨装置"对照（很有价值）**：① **跨代**：旧代 `ef3fd6765f18f51b` 与**新代**（链推进后）**同值**，三帧均 `cmp` 逐字节相同 ⇒ 链推进**没有**引起帧面位移；② **跨装置**：同一新 `.so`，**换"有 WM／无 WM"** 即把两页帧换成 `9ddd25ab947d0efb`（∉ 参照集），而**两页仍是空态页**（`magenta=0`／`colors=383`／色锚 `hits=0`／两帧仍相同）⇒ **"`fr_sha` ∉ 参照集"可纯由装置差达成**（裁定三十六 (c) 点名的假绿通道的具体路径）。

---

## §1 装置 · 代际 · 口径（现取）

| 项 | 有 WM 腿（在册口径） | 无 WM 腿（私补丁副本） |
|---|---|---|
| 证据目录 | `build/MilBridge/tests/PtsPagesProbe/evidence-tail2c/` | `build/MilBridge/tests/PtsPagesProbe/evidence-tail2c/nowm/` |
| 装置 | `Xvfb :231 1280x1024x24` ＋ `xfwm4 --compositor=off` | `Xvfb :231 1280x1024x24`，**不启 WM** |
| WM 自证（现取） | （在册口径；`device.txt` = `X_UP=yes display=:231`） | `X_UP=yes display=:231 WM_PRESENT=_NET_SUPPORTING_WM_CHECK:  no such atom on any window.`（`nowm/runner-stdout.log` 现取） |
| 腿跑器 | 仓内 `run-pts-pages-legs.sh`（`sha16=330a90f1f0ac28e4`） | 私有副本（`sha16=4056e97b2e591a88`；**仅删 `xfwm4` 启动块＋加 `WM_PRESENT` 自证行**，其余逐字节同源） |
| 会话件 | `session_inner.sh`（`sha16=f1a582d9ea9788c9`） | 同 |
| 判据件 | `pts-pages-guard.sh`（`sha16=962fec114b2d0692`） | 同 |
| 腿/计数 | `LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231` | 同 |
| 显示位规则 | `lowest-free(base=:231 span=9)`（`DISPLAY_PICK`） | 同 |
| 槽 | `~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`（`HEAVYSLOT=ACQUIRED`／`RELEASED rc=0`，`held=37s`） | 同（`held=32s`） |
| 探针闸（裁定三十六 (c)） | **`WPF_PTS_DRIVE_PROBE` 缺省＝开**（`win32_pts.c` 现取 `wpf_pts_drive_probe_enabled`：仅显式 `"0"` 才关）⇒ **本趟帧面读数均为"探针开"状态** | 同 |

**代际四元组（现取）**：

| 趟 | 主链 `.so`（`shim16`） | `pf16` | `app_g1.log`（`sha16`／字节） | 帧（`sha16`／字节） |
|---|---|---|---|---|
| **旧（在册 `evidence/`）** | `5ddc9d63b5232f96` | `c52d9191feb5ba7c` | `84db0eb62d15e0b2`／`551555` | `boot=b21eb530afd3c66c`／`190413`；`k23=k24=last=ef3fd6765f18f51b`／`189716` |
| **`T-A18` 臂（`evidence-tail2b/`）** | `9c19dc0fef35cf4a` | `1757d610a687777c` | `156e9e9a6e1d9c9a`／`1259182` | `boot=b21eb530afd3c66c`／`190413`；`k23=k24=last=ef3fd6765f18f51b`／`189716` |
| **新·有 WM（`evidence-tail2c/`）** | `e09c8d739c179966` | `1757d610a687777c` | `ad64b4f88dc6fc73`／`1373015` | `boot=b21eb530afd3c66c`／`190413`；`k23=k24=last=ef3fd6765f18f51b`／`189716` |
| **新·无 WM（`evidence-tail2c/nowm/`）** | `e09c8d739c179966` | `1757d610a687777c` | `bbb2c7c2c158c0f3`／`1402017` | `boot=b8b881d85afcf38d`／`191698`；`k23=k24=last=9ddd25ab947d0efb`／`190932` |

> ⚠️ **跨代不可比（纪律 31/32）**："旧"（`5ddc9d63…`）与"新"（`e09c8d73…`）是**两代 `.so`** ＋ **两趟不同时刻**；下表"逐字段相同"只报**结果相同**，**不得**读成"可相减的同一条件"。`FRAME_EMPTY_SET`（判据件件头唯一登记处，现取）＝ `{1a76488aa4a790b3, ef3fd6765f18f51b, b273ebecc332fc03}`。
> ⚠️ **代际面（导出）**：`nm -D --defined-only` 行数 **674** == `bin/exports.txt` 行数 **674**（现取）；`T-A18` 两处缺口的入口 `FsQueryTextDetails`／`FsUpdateBottomlessPage` 现取 `nm=1`／`exports=1`（各）。

---

## §2 ① 两页新旧**成对**读数表（`magenta`／`colors`／`ink`／`ENFE`／`failfast`／`alive`／`app_rc`）

`LEG`／`FAILLINE`／`FRAME` 行取 `leg_<k>.env`；`ENFE`／`failfast`／`[HC-UNHANDLED]` 取现算（命令见 §7）。

| 字段 | 旧（在册 `evidence/`）`k23`／`k24` | `T-A18` 臂 `k23`／`k24` | 新·有 WM `k23`／`k24` | 新·无 WM `k23`／`k24` | 判（旧 vs 新·有WM） |
|---|---|---|---|---|---|
| `alive` | `yes`／`yes` | `yes`／`yes` | `yes`／`yes` | `yes`／`yes` | **不变** |
| `app_rc` | `143`／`143` | `143`／`143` | `143`／`143` | `143`／`143` | **不变** |
| `magenta` | `0`／`0` | `0`／`0` | `0`／`0` | `0`／`0` | **不变** |
| `colors` | `383`／`383` | `383`／`383` | `383`／`383` | `383`／`383` | **不变** |
| `ink` | `480000`／`480000` | `480000`／`480000` | `480000`／`480000` | `480000`／`480000` | **不变** |
| `ns` | `…RichTextBoxDemo`／`…FlowDocumentDemo` | 同 | 同 | 同 | **不变** |
| `ae` | `0`／`15386` | `0`／`15386` | `0`／`15386` | `0`／`15386` | **不变** |
| `failfast`／`unrec` | `0`／`0` | `0`／`0` | `0`／`0` | `0`／`0` | **不变** |
| `ENFE_TOTAL`（`entry point named`） | `0` | `2` | **`0`** | **`0`** | **变（缺口归零）** |
| `[HC-UNHANDLED]` 行数 | `1117` | `904` | `427` | `445` | **变（同族，行数随运行）** |
| `[PTS-UNAVAILABLE]` 行数 | `0` | `0` | `0` | `0` | **不变** |
| `PTS_GAP entry=` 行数（`native_gap`） | `0` | `0` | `0` | `0` | **不变** |
| `[FS_PAGE_GAP]` 行数（`reason`） | `1117`（`paraclient-table-not-native`） | `550`（`drive-handles-released(page-destroyed)`） | `53`（`unclaimable-para`） | `53` | **变（拒绝面大幅收窄）** |
| `[FSQSTD]` 行数 | `0` | `707` | `909` | `945` | **变（链推进深化）** |
| `[FSQSPL]` 行数 | `0` | `355` | `535` | `553` | **变** |
| `[QPD]` 行数 | `0` | `914` | `708` | `726` | **变** |
| `[VIS]` 行数 | `0` | `3` | `56` | `56` | **变** |
| `[CLRUPD]` 行数 | `0` | `1` | `55` | `55` | **变** |
| `[SUBENUM]` 行数 | `0` | `3` | `3` | `3` | **不变** |

**`leg_<k>.env` 成对原文（有 WM，旧 vs 新）**：

```
旧（在册 evidence/leg_23.env）     新（evidence-tail2c/leg_23.env）
LEG k=23 alive=yes app_rc=143 magenta=0 colors=383 ns=HandyControlDemo.UserControl.RichTextBoxDemo ae=0 ink=480000   （逐字相同）
NAMED managed_unavail=0 err=- native_gap=0 native_err=-                                                              （逐字相同）
DEV x_up=yes five_stable=yes shim=5ddc9d63b5232f96 pf=c52d9191feb5ba7c   ←→  shim=e09c8d739c179966 pf=1757d610a687777c   （**唯一差异＝换代**）
FAILLINE k=23 failfast=0 unrec=0 src=app_g1.log:FailFast|Unrecoverable                                                （逐字相同）
FRAME k=23 fr_file=k23.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386                        （逐字相同）
```
（`k=24` 同形，`ns=…FlowDocumentDemo`、`ae=15386`。）

⇒ **判**：`T-A19/A20/A22` 把缺省路径驱到**更深、并补掉上一代新增的两条 `ENFE` 缺口**（`ENFE 2→0`；`[VIS]`／`[CLRUPD]`／`[FSQSPL]`／`[FSQSTD]` 面大幅增长，`[FS_PAGE_GAP]`／`[HC-UNHANDLED]` 大幅收窄），**但症状门逐字段不变**（`magenta`／`colors`／`ink`／`alive`／`app_rc`／`failfast`／`unrec`／`ns`／`ae`／`PTS-UNAVAILABLE`／`PTS_GAP` 全同），且帧面**与旧代逐字节相同** ⇒ **`T-A19/A20/A22` 未推进"两页真排版"**。上一代的**唯一新增缺口面 `ENFE 2`** 本趟**已消**。

---

## §3 ② 机读面现取（`[PTS-UNAVAILABLE]`／`[HC-UNHANDLED]`／`PTS_GAP`／`[FSQSTD]`／`[FSQSPL]`／`[QPD]`／`[VIS]`／`[CLRUPD]`／`[SUBENUM]`）

**逐面行数（现取 `grep -c`；四趟并列）**：

| 面 | 旧 `evidence/` | `T-A18` `evidence-tail2b/` | 新·有 WM `evidence-tail2c/` | 新·无 WM `evidence-tail2c/nowm/` |
|---|---|---|---|---|
| `[PTS-UNAVAILABLE]` | `0` | `0` | `0` | `0` |
| `[HC-UNHANDLED]` | `1117` | `904` | `427` | `445` |
| `PTS_GAP entry=` | `0` | `0` | `0` | `0` |
| `[FSQSTD]` | `0` | `707` | `909` | `945` |
| `[FSQSPL]` | `0` | `355` | `535` | `553` |
| `[QPD]` | `0` | `914` | `708` | `726` |
| `[VIS]` | `0` | `3` | `56` | `56` |
| `[CLRUPD]` | `0` | `1` | `55` | `55` |
| `[SUBENUM]` | `0` | `3` | `3` | `3` |
| `entry point named`（ENFE） | `0` | `2` | **`0`** | **`0`** |
| `[FS_PAGE_GAP]` | `1117` | `550` | `53` | `53` |
| `[FSPARALIST*]` | `0` | `725` | `1095` | `1132` |

**分布现取（新·有 WM；均按标记行现算）**：
- **`[QPD]`**（708）：`fskupd` 直方图 **`1`×594／`2`×114**、**`fskupd=0` 0 次**；`first/adj` 直方图 **`first=0 adj=0`×590／`first=0 adj=1`×115／`first=1 adj=0`×3**；`qpd_gap=0` **708/708**。
- **`[FSQSTD]`**（909）：`reason=ok` **535**（`rc=0`／`out=WRITTEN`）／`reason=unclaimable-subtrack` **370**（`rc=-10000`／`out=UNWRITTEN`）／`reason=claimed-by-provenance-no-content-model` **2**／`reason=null-subtrack` **2**。
- **`[FSQSPL]`**（535）：`rc=0 reason=ok` **535/535**。
- **`[SUBENUM]`**（3）：`where=FsCreatePageBottomless` 2／`where=FsCreatePageFinite` 1，均 `v=ENUM-OK ok=1 gap=0 window=in`。
- **`[VIS]`**（56）：均 `basis=fmtrackparalist-after-qpdnew-with-1-trackdetails`。
- **`[CLRUPD]`**（55）：均 `rc=0`，均 `basis=reset-page-owned-incremental-state`。
- **`[FS_PAGE_GAP]`**（53）：**同一 reason** `rc=-10000 reason=unclaimable-para entry=FsQueryTextDetails … unclaim=1 out=UNWRITTEN`（上一代 `drive-handles-released(page-destroyed)` 已消，代之以 `unclaimable-para`）。
- **`[HC-UNHANDLED]`**（427）：**全部 `PtsException`**（`Page formatting engine did not complete formatting operation. Error code: '-10000'`）；**`EntryPointNotFoundException` 归零**（上一代 2）。
- **`entry point named`**（ENFE）：**0**（`FsQueryTextDetails`／`FsUpdateBottomlessPage` 均已在导出面）。

**原文（现取，首行）**：

```
[QPD] rc=0 fskupd=2 first=1 adj=0 page=0x5c0e2c23f540 page_qpd=1 vis_built=0 qpd_ok=1 qpd_gap=0 new_n=1 nc_n=0 vis_n=0 seq=6 NOINFO=fspagedetails-page-change-tracking
[SUBENUM] where=FsCreatePageBottomless container=0x3 first=0x4 cparas=3 ok=1 rc136=0 rc144=0 child_max=32 v=ENUM-OK calls=1 ok_n=1 gap=0 window=in
[FSQSTD] rc=0 reason=ok entry=FsQuerySubtrackDetails ctx=0x5c0e30e7cfb0 psub=0x5c0e31e2b1f4 calls=1 ok=1 gap=0 null=0 unclaim=0 unformatted=0 out=WRITTEN bytes=40 cParas=3 true_cParas=3 nms=0x2 src=SUBENUM(+136/+144)
[FSQSPL] rc=0 reason=ok entry=FsQuerySubtrackParaList ctx=0x5c0e30e7cfb0 psub=0x5c0e31e2b1f4 cParas=3 made=3 cli_total=3 src=SUBENUM(+136/+144)+managed-176 calls=1 ok=1 gap=0 NOINFO=subtrack-para-geometry(dvrUsed/dvrTopSpace/bbox=0)
[VIS] children=1 page=0x5c0e2c23f540 page_qpd=4 fstd_since_qpd=1 vis_n=1 seq=12 basis=fmtrackparalist-after-qpdnew-with-1-trackdetails NOINFO=fspagedetails-page-change-tracking
[CLRUPD] rc=0 page=0x5c0e3085fac0 vis_built_before=1 new_pending_before=0 fstd_since_before=0 group_adjacent_before=1 page_qpd=6 clr_ok=1 clr_gap=0 seq=776 basis=reset-page-owned-incremental-state NOINFO=fsclearupdateinfo-scope-native-owned-state
[FS_PAGE_GAP] rc=-10000 reason=unclaimable-para entry=FsQueryTextDetails ctx=0x5c0e2bedf1e0 para=0x4 calls=1 gap=1 nullout=0 nullpara=0 unclaim=1 unknown_ctx=0 nomodel=0 out=UNWRITTEN bytes=0
[HC-UNHANDLED] #1 PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'. ｜ 首帧 at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.Error(Int32 fserr, PtsContext ptsContext)
```

⇒ **判**：链面（`QPD`／`VIS`／`SUBENUM`／`FSQSTD`／`FSQSPL`／`CLRUPD`）**继续增长且 `rc=0 reason=ok` 占多数**；`ENFE` 归零、`[FS_PAGE_GAP]` 大幅收窄，**但**下游仍有 `[FSQSTD]` 的 `unclaimable-subtrack 370`（`out=UNWRITTEN`）与 `[FS_PAGE_GAP]` 的 `unclaimable-para 53`（诚实拒绝留痕），且 `[HC-UNHANDLED]` 427 全为 `PtsException`（格式化未完成）⇒ **下游仍未合成可见内容**（帧面见 §4）。

---

## §4 ③ 帧面（三帧 `sha256`、`AE`、`FRAME` 机读行）

**帧 `sha256` 前 16 位 ＋ 字节（现取 `sha256sum`／`stat`）**：

| 帧 | 旧（在册） | `T-A18` 臂 | 新·有 WM | 新·无 WM |
|---|---|---|---|---|
| `boot.png` | `b21eb530afd3c66c`／`190413` | `b21eb530afd3c66c`／`190413` | `b21eb530afd3c66c`／`190413` | `b8b881d85afcf38d`／`191698` |
| `k23.png` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | `9ddd25ab947d0efb`／`190932` |
| `k24.png` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | `9ddd25ab947d0efb`／`190932` |
| `last.png` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | `ef3fd6765f18f51b`／`189716` | `9ddd25ab947d0efb`／`190932` |

**逐字节核对（`cmp` 现取）**：`evidence-tail2c/shots/g1/{boot,k23,k24,last}.png` **与在册 `evidence/shots/g1/` 四帧逐字节相同**（`cmp` 全 IDENTICAL）；亦与 `evidence-tail2/shots/g1/`／`evidence-tail2b/shots/g1/` 四帧逐字节相同。`evidence-tail2c/nowm/` 四帧与 `evidence-tail2b-nowm/` 四帧逐字节相同。⇒ **`T-A19/A20/A22` 对帧面零位移**。

**`AE`（`compare -metric AE`；`N1`／`N3` 口径）**：

| 比较 | 旧 | `T-A18` 臂 | 新·有 WM | 新·无 WM |
|---|---|---|---|---|
| `AE(boot,k23)` | `15386` | `15386` | `15386` | `15386` |
| `AE(boot,k24)` | `15386` | `15386` | `15386` | `15386` |
| **`AE(k23,k24)`**（`N3` 要件②） | **`0`** | **`0`** | **`0`** | **`0`** |
| `AE(新·有WM k24, 新·无WM k24)` | — | — | — | **`712401`**（**装置差**，见 §0-5） |

**`FRAME` 机读行（`leg_<k>.env` 第五段原文，照 `N1`／`N4` 口径）**：

```
旧（在册 evidence/）:
FRAME k=23 fr_file=k23.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386
FRAME k=24 fr_file=k24.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386

新·有 WM（evidence-tail2c/）:  ← 与"旧"**逐字相同**
FRAME k=23 fr_file=k23.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386
FRAME k=24 fr_file=k24.png fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386

新·无 WM（evidence-tail2c/nowm/）:
FRAME k=23 fr_file=k23.png fr_sha=9ddd25ab947d0efb fr_lsha=9ddd25ab947d0efb fr_ae_boot=15386
FRAME k=24 fr_file=k24.png fr_sha=9ddd25ab947d0efb fr_lsha=9ddd25ab947d0efb fr_ae_boot=15386
```

`shotstat`（与 `leg_*.env` 的 `colors`／`magenta`／`ink` **逐格相等** ⇒ 截图同趟自证成立）：

```
新·有 WM:  boot colors=386 magenta=0 ink=480000 ｜ k23=k24=last colors=383 magenta=0 ink=480000
新·无 WM:  boot colors=386 magenta=0 ink=480000 ｜ k23=k24=last colors=383 magenta=0 ink=480000
```

**`N1`／`N3`／`N4` 现取判**：
- **`N1` 要件①**（`fr_sha` ∉ `FRAME_EMPTY_SET`）：有 WM 腿 `ef3fd6765f18f51b` **∈ 集** ⇒ **不成立**；无 WM 腿 `9ddd25ab947d0efb` **∉ 集** ⇒ 成立（**但这是装置差，见 §0-5**）。
- **`N1` 要件②**（`fr_ae_boot>0`）：两腿 `15386>0` ⇒ 成立。
- **`N3`**（两页帧必须不同／`AE(k23,k24)>0`）：**四趟全 `AE=0`、两页帧逐字节相同** ⇒ **红**（且按裁定三十九 (b)，该红**同样不可归因**于"两页同貌 vs 恰好同变体"）。
- **`N4`**（内容正身份）：`PTS_N4_POSITIVE_FP` **未登记** ⇒ `NOINFO(no-registered-positive-identity)`；内容锚 `neptune` 命中 **0**（四趟皆 0）；色锚 `k=24` `hits=0`。
- ⚠️ **探针闸状态（裁定三十六 (c)）**：本趟片帧面均在 **`WPF_PTS_DRIVE_PROBE` 缺省＝开** 状态下取 ⇒ **跨闸状态不可比**；`N1` 要件① 之成立**应在闸关闭的那一代上取**（本件未另跑"闸关"腿，见 `NOINFO-8`）。

---

## §5 ④ 相位评估 ＝ **不可翻**（`PTS-PHASE-ASSESSMENT=NO-FLIP`）

### 5.1 现取判词原文

**A. `degraded` 相（仓内判据件原样，`--legs evidence-tail2c`；`rc=1`）**：

```
PTS_G10_NAME=PASS observed=FsQuerySubtrackDetails names=6 roster=24 domains=pts-declared（形态判据：具名行**在在册名单内**；PTS 域不写死任何名字）
PTS_N1=INFO k=24 file=k24.png fr_sha=ef3fd6765f18f51b in_empty_set=yes fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} phase=degraded（止损期不据此判红；相位翻转后本条生效 —— 口径见 t124 段）
PTS_N1=INFO k=23 file=k23.png fr_sha=ef3fd6765f18f51b in_empty_set=yes fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} phase=degraded（止损期不据此判红；相位翻转后本条生效 —— 口径见 t124 段）
PTS_COLORANCHOR_BASE=frame=boot.png scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 min=200 all_zero=yes dead=none（**阈值由本基线标定**：基线全 0 ⇒ 该计数能分开有该色/没该色；`LightGray` 不入集——它在空态帧里已有 44/51 px）
  COLOR-ANCHOR-ABSENT k=24 expect>=200px&hits>=2 measured=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 baseline(boot.png)=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=degraded（`FlowDocumentDemo` 的具名色**应有而未现** ⇒ 该页**没绘出内容**）
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 expect_min=200 expect_hits=2 baseline=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=degraded reason=declared-color-anchor-absent
PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23 phase=degraded（`RichTextBoxDemo.xaml` 无具名色 ⇒ **本页无锚**；**严禁**用 k=24 的锚推广。⏪ `t145`：本支**只印具名 NOINFO 行、不折 `cannot`** —— 否则任何没有 k=24 帧的证据目录都会被整体读成不可判；**本面不给绿**这一点不变）
PTS_ENFE=INFO total=0 by_name=none allow=none non_allow=none phase=degraded log=build/MilBridge/tests/PtsPagesProbe/evidence-tail2c/app_g1.log log_sha16=ad64b4f88dc6fc73（止损期不据此判红；相位翻转后本条生效 —— 口径见 t122 段；**引用必须连 log ＋ log_sha16 一起引**，见 t136 F-2）
PTS_GUARD=FAIL legs=2/2 fails=leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-),leg23-placeholder-missing(magenta=0<20000),leg23-named-line(missing-or-err=-),leg24-color-anchor-absent(hits=0<2,scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0),native-ledger-absent(PTS_GAP n=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=degraded
```
（全文见 `evidence-tail2c/guard-degraded.txt`。）

**B. `realized` 副本（`sed 's/…phase=degraded/…phase=realized/'`；**只改相位位、不改仓内件**；`--legs evidence-tail2c`；`rc=1`）** —— **本趟最要紧的一条**：

```
PTS_N1=FAIL k=24 file=k24.png fr_sha=ef3fd6765f18f51b in_empty_set=yes fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criterion=frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03}) phase=realized reason=frame-identity-not-established
PTS_N1=FAIL k=23 file=k23.png fr_sha=ef3fd6765f18f51b in_empty_set=yes fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criterion=frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03}) phase=realized reason=frame-identity-not-established
PTS_N1_POS=phase=realized positive=none n4=absent anchor_hits=0 differ=0 via=compare n4_unregistered=1 exception_proof= exception_applies=0（三源口径见 t136 段；「∉ 参照集」单独**不给绿**）
PTS_N1_GATE=NOINFO phase=realized reason=necessary-not-satisfied(nec23=no,nec24=no) sha23=ef3fd6765f18f51b sha24=ef3fd6765f18f51b
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 expect_min=200 expect_hits=2 baseline=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 phase=realized reason=declared-color-anchor-absent
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=build/MilBridge/tests/PtsPagesProbe/evidence-tail2c/app_g1.log log_sha16=ad64b4f88dc6fc73
PTS_GUARD=FAIL legs=2/2 fails=leg24-n1-frame-unestablished(frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03})),leg23-n1-frame-unestablished(frame-identity(sha16=ef3fd6765f18f51b∈{1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03})),leg24-color-anchor-absent(hits=0<2,scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0) cannot=n1-gate(necessary-not-satisfied=nec23:no,nec24:no) diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=realized
```

**C. 无 WM 腿（`realized` 副本，`--legs evidence-tail2c/nowm`；`rc=1`）** —— **假绿通道被拦下的读数**：

```
PTS_N1=NECESSARY k=24 file=k24.png fr_sha=9ddd25ab947d0efb in_empty_set=no fr_ae_boot=15386 set={1a76488aa4a790b3,ef3fd6765f18f51b,b273ebecc332fc03} criteria-satisfied=frame-identity,frame-displacement phase=realized（⏪ t136：**必要非充分** …）
PTS_N1=NECESSARY k=23 file=k23.png fr_sha=9ddd25ab947d0efb in_empty_set=no fr_ae_boot=15386 set={…} criteria-satisfied=frame-identity,frame-displacement phase=realized
PTS_N1_POS=phase=realized positive=none n4=absent anchor_hits=0 differ=0 via=compare n4_unregistered=1 exception_proof= exception_applies=0（三源口径见 t136 段；「∉ 参照集」单独**不给绿**）
  N1-ONLY-NECESSARY positive=none n4=absent anchor_hits=0 differ=0 reason=only-necessary-condition-no-positive-evidence（realized 期**两腿必要件都成立**、**只有必要条件、缺正证据** ⇒ 不许给排版绿）
PTS_N1_GATE=FAIL phase=realized positive=none sha23=9ddd25ab947d0efb sha24=9ddd25ab947d0efb nec23=yes nec24=yes reason=only-necessary-condition-no-positive-evidence
PTS_ENFE=PASS total=0 by_name=none allow=none non_allow=none phase=realized log=build/MilBridge/tests/PtsPagesProbe/evidence-tail2c/nowm/app_g1.log log_sha16=bbb2c7c2c158c0f3
PTS_GUARD=FAIL legs=2/2 fails=n1-only-necessary-condition-no-positive-evidence(sha23=9ddd25ab947d0efb,sha24=9ddd25ab947d0efb,anchor=0,n4=absent),leg24-color-anchor-absent(hits=0<2,scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0) cannot=- diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0(点击前后无像素差) direction=in-file phase=realized
```
（全文见 `evidence-tail2c/nowm/guard-{degraded,realized}.txt`。）

### 5.2 逐条前置依据（前置 ＝ `magenta=0 ∧ 无具名降级行 ∧ 真排版` ＋ `N1`／`N3`／`N4` 同趟）

| # | 前置 | 现取读数（新·有 WM，主口径） | 判 |
|---|---|---|---|
| `P-1` | **`magenta=0`** | `leg23`／`leg24` 均 `magenta=0` | **成立**（但见 `P-2′`／`P-3`：这一条**在空态页上也成立**，本身不指向排版） |
| `P-2` | **无具名降级行**（**判据窄口径**＝`[PTS-UNAVAILABLE] site=…`） | `[PTS-UNAVAILABLE]=0`、`NAMED managed_unavail=0 err=- native_gap=0` | **成立**（窄口径） |
| `P-2′` | **无具名降级行**（**更广口径**＝"页面未完成格式化"的具名行） | `[HC-UNHANDLED] … did not complete formatting operation … '-10000'` **427** 行；`ENFE_TOTAL=0`（上一代 2 已消） | **不成立**（**仍有具名未完成行**）⇒ `P-2` 的成立**只对窄口径** |
| `P-3` | **真排版** | （a）`k23=k24=last` **逐字节相同**（`ef3fd6765f18f51b`）⇒ `AE(k23,k24)=0`；（b）`k=24` 色锚 `hits=0`（基线 `boot` 四色实算全 0 ⇒ 活锚，缺席即红）；（c）内容锚 `neptune` 命中 `0`；（d）帧身份 **∈** 空态参照集；（e）`ink=480000` 是裁定三十五 (c) **入册禁用**的恒真量 | **不成立** |
| `P-4a` | **`N1` 同趟** | 要件①（`fr_sha` ∉ 参照集）**不成立**（`∈` 集）⇒ `realized` 判 `PTS_N1=FAIL … reason=frame-identity-not-established`；正证据三源 `positive=none`（`n4` 未登记／`anchor_hits=0`／`differ=0`） | **不成立**（红） |
| `P-4b` | **`N3` 同趟** | 两页帧相同、`AE=0` ⇒ 红；且按裁定三十九 (b) 该红**不可归因** | **不成立**（红） |
| `P-4c` | **`N4` 同趟** | `PTS_N4_POSITIVE_FP` **未登记**；无"该页专属期望指纹"载体 | **`NOINFO`**（裁定三十五 (a) 另禁"登记即算"） |

### 5.3 逐条裁定依据（裁定二十／二十一／三十五／三十六）

- **裁定二十一 ②** ＝「**相位翻转的新硬前置 ＝ 与 `N1–N4` 同趟落定**」⇒ 现取 `N1` 红、`N3` 红、`N4` `NOINFO` ⇒ **前置未落定**。裁定二十一 ② 另写死「**`leg23-AE=0` 不该消、该升为承重判据**」⇒ 现取 `leg23-AE=0` 仍为 `diag`，若翻相位该诊断**应升为承重** ⇒ 更**不该**翻。
- **裁定三十五 (d)** ＝「**不准翻相位（今天）**；准许的下一步 ＝ 色锚读数（`C-A`）＋ 登记加固，两者都是**判据面**」⇒ 现取 `C-A`（色锚）**已落成且今天必红**（`hits=0`）、`N4` 登记**仍缺独立支撑**（`n4_unregistered=1`）⇒ **两个准许项未完成，翻转项仍禁**。
- **裁定三十五 (a)** ＝ `N4` 登记**必须附独立可证伪读数**（否则 `N4-DECLARED-ONLY`、不给绿）⇒ 本件**不**擅自登记（见 `NOINFO-1`）。
- **裁定三十六 (c)** ＝ 三条口径照旧：① **帧面读数必须带探针闸状态**（本件已带，见 §1／§4）；② **`N1` 要件① 之成立必须在闸关闭的那一代上取**（本件未另跑"闸关"腿 ⇒ 见 `NOINFO-8`）；③ 帧面绿**永不**单独支撑排版结论。（注：裁定三十六 (b) 的"闸默认关"已由裁定三十八 (a) 撤销，现取探针**缺省开**。）
- **裁定二十** ＝「维持 `degraded`；翻转是**协同动作**（判据件写者**同趟**改相位位 ＋ 同步改那 10 条 degraded 正控期望 ＋ 独立复核），**一次做完**」⇒ 本件是**测量/侦察件**，**无权改相位**（且改了即与事实相反）。
- **旁引裁定三十九 (a)／(c)／四十二 (b)（冻结令）** ＝「`fr_sha`／帧内容类要件在 `PRECOND-FRAME-DETERMINISM` 取得读数前**不得单独支撑绿、也不得单独支撑红**」⇒ 本件**不**据任一帧面读数**单向**下判。

⇒ **`PTS-PHASE-ASSESSMENT=NO-FLIP`**：现取 `realized` 副本两趟均 `PTS_GUARD=FAIL`、`rc=1`；且"翻相位"的**语义**＝"宣布两页真排版成立"，**与现取事实相反**；**翻的后果＝当场红**（红来自 `N1` 帧身份／正证据闸 ＋ 色锚；**上一代的 `ENFE 2` 红本趟已消**）。

### 5.4 反腿／反证（"该红必红"与"不该绿"）

1. **`realized` 副本 ≠ 绿**：两趟（有 WM／无 WM）现取均 `PTS_GUARD=FAIL`、`rc=1` ⇒ 裁定二十一 ② 警告的"翻相位会让守卫 `PASS`（判据放松）"路径已被堵死（有 WM 腿红来自 `N1` 帧身份 ＋ 色锚；无 WM 腿红来自 `N1` 正证据闸 ＋ 色锚）。
2. **有 WM／无 WM 成对**：同一 `.so`、同一装置号，**单变量 ＝ WM 有无** ⇒ 帧身份 `∈集`→`∉集`，而两页**仍未排版** ⇒ **证明"`fr_sha` ∉ 参照集"是必要非充分**（该红／该绿都不单独成立）—— 这正是裁定三十六 (c) 点名的**假绿通道**被正证据闸**就地堵住**的读数。
3. **跨代反证**：旧代 `ef3fd6765f18f51b` 与**链推进后新代**同值（`cmp` 逐字节相同）⇒ **链推进（`QPD`／`VIS`／`SUBENUM`／`FSQSTD`／`FSQSPL`／`CLRUPD` 增长、`ENFE 2→0`）未引起帧面位移** ⇒ 进一步印证"计数／留痕前进 ≠ 可见排版前进"。

---

## §6 ⑤ 具名 `NOINFO` 清单

| # | `NOINFO` | 现取依据 | 消掉条件 |
|---|---|---|---|
| `NOINFO-1` | **`N4` 正身份载体** | `PTS_N4_POSITIVE_FP` 未登记；无"该页专属期望指纹"；裁定三十五 (a) 禁"登记即算" | 两页**首次各自绘出内容**后，由当趟实现件写者同趟登记**带独立可证伪支撑**的正身份（裁定三十五 (a)）；本件**不**擅自登记 |
| `NOINFO-2` | **帧面确定性 `PRECOND-FRAME-DETERMINISM`** | 旁引裁定四十二 (b) 记仍未满足；本趟仅得"装置差"（有/无 WM）＋"跨代同值"对照，**未**取同装置内变体分布 | 按裁定四十 (a) 族级纪律取 ≥20 独立样本、逐趟记代际指纹、批内代际守卫 |
| `NOINFO-3` | **`k=23` 色锚** | 守卫现取 `PTS_COLORANCHOR=NOINFO k=23 reason=no-anchor-registered-for-k23`（`RichTextBoxDemo.xaml` 无具名色） | 为 `k=23` 另立"活锚"（**严禁**用 `k=24` 的锚推广） |
| `NOINFO-4` | **链推进对"排版"的可观察变化** | 现取 `[QPD]`／`[VIS]`／`[SUBENUM]`／`[FSQSTD] rc=0`／`[FSQSPL]`／`[CLRUPD]` 面增长、`ENFE` 归零，但症状门＋帧面全不变 ⇒ "计数下降／留痕前进 ≠ 能力前进" | 待 `[FSQSTD]` 的 `unclaimable-subtrack 370`（`out=UNWRITTEN`）与 `[FS_PAGE_GAP]` 的 `unclaimable-para 53` 清零、`[HC-UNHANDLED]` 归零、且帧面出现真内容 |
| `NOINFO-5` | **旧／`T-A18` 臂各面 vs 新代的"同一条件相减"** | 三代 `.so` ＋ 三趟不同时刻 ⇒ 跨代不可比（纪律 31/32） | 不适用（本件只报"逐字段相同／逐字节相同"这一**结果**） |
| `NOINFO-6` | **无 WM 腿的"在册口径"归属** | 该腿用**私有补丁副本**（`sha16=4056e97b2e591a88` ≠ 在册 runner `330a90f1f0ac28e4`）⇒ 只作**装置差**证据 | 若要把"无 WM"立为在册口径 ⇒ 须由装置件写者正式落成 runner 的一支（**本任务不改 `tools/**`／装置件**） |
| `NOINFO-7` | **下游拒绝面（`unclaimable-subtrack 370`／`unclaimable-para 53`）的归属与后果** | 现取新代首次出现 `reason=unclaimable-para entry=FsQueryTextDetails`（上一代 `drive-handles-released(page-destroyed)` 550 已消）；本件**只测**、不实现、不判"谁该补" | 由实现件写者按裁定二十三 (c)① 铁律（诚实形态：导出符号 ⇒ `ENFE` 归零；出参不伪造；失败必留痕）同趟落地 |
| `NOINFO-8` | **"探针闸关闭"状态下的帧面读数** | 现取探针缺省**开**（裁定三十六 (b) 已由裁定三十八 (a) 撤销）；裁定三十六 (c)② 要求 `N1` 要件① 之成立**在闸关闭的那一代上取** ⇒ 本件**未**另跑"闸关"腿 | 以 `WPF_PTS_DRIVE_PROBE=0` 跑一趟反极性腿取帧面（**本任务未要求**；若要则须同趟记代际指纹） |
| `NOINFO-9` | **无 WM 腿 BM 自证的仪器归属** | `WM_PRESENT=_NET_SUPPORTING_WM_CHECK:  no such atom on any window.` 由**私有副本**（非在册 runner）产出 ⇒ 与 `NOINFO-6` 同源，只作装置差证据 | 同 `NOINFO-6` |

---

## §7 可复跑单行命令原文（现取）

```sh
# 代际 / 导出面
cd /home/links-dev/netTest/GitProj/WPFOnLinux
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16                      # ⇒ e09c8d739c179966
nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | wc -l                # ⇒ 674
wc -l src/WpfGfx.Linux.Native/bin/exports.txt                                          # ⇒ 674

# 跑腿（重活槽；私有 W=/home/links-dev/tA23-work，A 臂 k=24,23）
bash /home/links-dev/tA23-work/legs-slot.sh      $PWD/build/MilBridge/tests/PtsPagesProbe/evidence-tail2c
bash /home/links-dev/tA23-work/legs-nowm-slot.sh $PWD/build/MilBridge/tests/PtsPagesProbe/evidence-tail2c/nowm

# 帧面
D=build/MilBridge/tests/PtsPagesProbe
sha256sum $D/evidence-tail2c/shots/g1/{boot,k23,k24,last}.png | cut -c1-16
compare -metric AE $D/evidence-tail2c/shots/g1/k23.png $D/evidence-tail2c/shots/g1/k24.png null:   # ⇒ 0
compare -metric AE $D/evidence-tail2c/shots/g1/boot.png $D/evidence-tail2c/shots/g1/k24.png null:  # ⇒ 15386
cmp $D/evidence/shots/g1/k24.png $D/evidence-tail2c/shots/g1/k24.png                               # ⇒ 无输出（逐字节相同）

# 面现取（逐面行数并列四趟）
bash /home/links-dev/tA23-work/faces3.sh
bash /home/links-dev/tA23-work/dist3.sh

# 判词
bash build/MilBridge/tools/pts-pages-guard.sh --legs $D/evidence-tail2c                              # rc=1（degraded）
bash build/MilBridge/tools/pts-pages-guard.sh --legs $D/evidence-tail2c/nowm                          # rc=1（degraded）
# realized 副本（只改相位位；不改仓内件）
sed 's/^\(# PTS-DIRECTION: .*\)phase=degraded$/\1phase=realized/' build/MilBridge/tools/pts-pages-guard.sh > /home/links-dev/tA23-work/guard-realized.sh
PTS_G10_ROSTER_SRC=$PWD/src/WpfGfx.Linux.Native/src/win32_pts.c PTS_G10_DECL_TREE=$PWD/upstream/wpf \
  bash /home/links-dev/tA23-work/guard-realized.sh --legs $D/evidence-tail2c                           # rc=1（realized）
```

---

## §8 边界 · 纪律 · 主动披露

1. **写域**：仅一个新证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2c/`（**新建**；无 WM 腿落其**子目录** `nowm/`）＋ 本载体。**未覆盖**在册 `evidence/` 与 `evidence-tail2*/`；**未碰** `src/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`。证据目录内除腿产物外另落：`runner-stdout.log`（腿跑器/Runner 同趟 stdout 副本，含 `WM_PRESENT` 自证）与 `guard-{degraded,realized}.txt`（判词全文），均为本趟现取、供复核。
2. **无 WM 腿落成子目录的取舍（如实披露）**：任务写域只点名 `evidence-tail2c/` 一个新建目录，而 ③ 又要求"有/无 WM 两腿"帧面 ⇒ 本件把无 WM 腿落成 `evidence-tail2c/nowm/`（**子目录**，仍在被许可的新目录之下），**未**另建 `evidence-tail2c-nowm/` 兄弟目录。**若队长要求两腿平级目录，请指名**。
3. **不改相位**：本件**未**改 `pts-pages-guard.sh` 的 `PTS-DIRECTION` 行；`realized` 判词取自**仓外副本**（`/home/links-dev/tA23-work/guard-realized.sh`，`sed` 只改相位位，`sha16=fdf0d401a3ba720d`）—— 与守卫自带 `--selftest` 造副本的形态相同。
4. **无 WM 腿的装置件**：为造"无 WM"这一支，本件用**仓外私有副本**（`/home/links-dev/tA23-work/probe-nomw/`，`sha16=4056e97b2e591a88`；**仅删 `xfwm4` 启动块 ＋ 加 `WM_PRESENT` 自证行**；与在册 runner `330a90f1f0ac28e4` 逐字节同源）；**仓内装置件一字未动**。该腿的 runner `sha16` 与在册不同 ⇒ 已在 `NOINFO-6`／`NOINFO-9` 如实划界。
5. **重活全走槽**：`~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID（腿跑器自收 `Xvfb`／`xfwm4`，`DEVICE_REAP state=clean`）；显示位只用空闲 `:23x`（`lowest-free(base=:231 span=9)`）；未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`。
6. **辅助脚本**：`/home/links-dev/tA23-work/{faces3.sh,dist3.sh,frames3.sh,firstlines.sh,legs*.sh,guard-realized.sh}`（均**仓外**，不属仓内件）。
7. **跨代不可比（纪律 31/32）**：§2／§3 的"旧 vs 新"含**三代 `.so`** 与**三趟时刻** ⇒ 只报"逐字段相同／逐字节相同"这一结果，**不做相减**（见 `NOINFO-5`）。
8. **帧面冻结令（旁引裁定三十九／四十二）＋ 探针闸状态（裁定三十六 (c)）**：本件**不**据任一帧面读数**单向**下判；`N1`／`N3`／`N4` 的结论均带"不可归因"边界，并已带**探针闸状态**（本趟探头开）。本件**未**新增判据、仅测量与评估。
9. **旧（在册）读数的性质**：§2／§3／§4 的"旧"列与"`T-A18` 臂"列取自**在册 `evidence/`** 与**在册 `evidence-tail2b/`＋`evidence-tail2b-nowm/`**—— 性质＝**在册证据的现核**（本席同趟未重取那两代腿），**非同趟绿**；"新"列＝本席**同趟新取**。
10. **ENFE 口径解耦（承 `t144`／`t139` `F-2`）**：本件 `ENFE_TOTAL` ＝ 日志里 `entry point named '<名>'` 的**行数**；`[HC-UNHANDLED]` ＝ 同名标记行数 —— 二者**各自定义、不得互折**（现取 `ENFE=0`、`[HC-UNHANDLED]=427`）。
11. **本趟较 `T-A18` 的面位移（具名）**：`ENFE 2→0`（上一代唯一新增缺口面已消）；`[FS_PAGE_GAP]` 的 `reason` 由 `drive-handles-released(page-destroyed)`（550）换成 `unclaimable-para`（53）；`[HC-UNHANDLED]` 由 `PtsException 902 ＋ EntryPointNotFoundException 2` 变为**全 `PtsException` 427**。**帧面／症状门零位移**。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-rearm3-recon.md | sha256sum | cut -c1-16`）= `51c98c9b435e93c8`

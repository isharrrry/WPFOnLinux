# `P1-tail2` `TASK-0302` · native「PTS 附属对象回填」（`NATIVE-PTS-ATTACHED-OBJECTS-BACKFILL`）—— 实现报告（`T-A36`）

- **读时**：`2026-09-30T17:2x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=a8397a21bd317a2d28339c6da36e5f697597c7d4`（现取，**未换代**）。
- **改前件备份（仓外 `~/tA36-work/bak/`，`cp -p` 取在**任何写之前**）**：`win32_pts.c.04f6d354.bak`（`fa5183d53f263123`／491139 B）／`libwpfwin32.so.04f6d354.bak`（`04f6d354b0a71888`／435192 B）／`exports.txt.bak`（677 行）／`pts-gap-decl.txt.bak`／另六件复述位现值位原件。
- **只改**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（台账 ＋ 回填 ＋ 四入口 ＋ 两处偏移钉死）／**随动**：`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`PTSGAP-DECL` 重锚 ＋ `T-A36` 记录块）／`src/WpfGfx.Linux.Native/bin/exports.txt`（构建生成，`677→681`）／**复述位现值位**（`docs/ROUTES.md`／`README.md`／`docs/unimplemented.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）／**新建**证据目录 `build/MilBridge/tests/PtsPagesProbe/evidence-tail2e/`（含 `sample2/`＋`polar/`）／本载体。
- **黑名单遵守**：未动 `build/*.Linux/**`（生成件）／`build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）；**未跑**整趟 `verify-all`；**未跑** `static-jaws-check.sh`；未改相位；未 `git add/commit/push`。重活（**3 趟构建 ＋ 7 趟腿**）全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`；进程只按 PID；禁 `sleep` 轮询；写前 `cp -p` 备份；`temp+rename`（编辑器原子替换）；模式守恒。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。
- **口径**：一切读数**本席现取**（`sha256sum`／`grep -c`／`nm`／`diff`／只读 `python3`+`PIL` 解 PNG）；`T-A33`／`T-A34`／`T-A35` 载体**只作对照**，其读数**逐格由本席现取复算**、**未抄**。

---

## §0 结论速览（自包含）

1. **实现已落地（`win32_pts.c`，`T-A36` 指定写域）**：为 `Figure`/`Floater`（PTS 附属对象）**建台账** —— 窗内（`FsCreatePage*` ⇒ `wpf_pts_formatline_drive`）对**每一行**调托管回调
   `pfnGetNumberAttachedObjectsInTextLine`（`cbktxt` 索引 27／绝对 `+512`）取**该行附属对象数**，
   有 >0 再调 `pfnGetAttachedObjectsInTextLine`（索引 28／`+520`）取**对象名／`idobj`／锚点 dcp**，
   并为每个附属对象段落**窗内**造 `FigureParaClient`/`FloaterParaClient`（`+176`，承 `T-A33`（丙）窗内纪律）；
   **查询期**由 `FsQueryTextDetails` 回填 `cAttachedObjects`（＝台账真值）。
2. ✅ **台账真值来自回调（零假值）**：`[FSATT-PROBE]` 现取 `rcNum=0 rcObj=0 cAtt=2 att0_obj=0x14 att0_id=-2/-…`（`para=0x8 i=7`）⇒ **附属对象确实可达**（`att_id=-2` ＝ `fsidobjFigure`）⇒ 解除 `T-A35` §5 的 `NOINFO-ATTACHED-ABSENT-CAUSE` 之"本侧无此概念"一支。
3. ✅ **`[FS_TLB]` 的 `attached-objects(none)` 形状归零（判据 D1）**：改报 `attached-objects=present … figure=N floater=M`（现取 `present 1008`／`not-present(true-queried) 1614`／**`none` 形状 0**）。
4. ✅ **同趟新增 4 个真导出（此前缺失的 PTS 入口）**：`FsQueryAttachedObjectList`／`FsQuerySubpageDetails`／`FsQueryFigureObjectDetails`／`FsQueryFloaterDetails`（`nm==exports==681`，逐名 `diff` 零差异）。
5. 🔴 **产品面首次出「具名色块」（本波的核心新事实）**：`k=24` 帧上 **`GhostWhite 0 → 29637 px`**（`≥200` 阈值），`PTS_COLORANCHOR hits 0 → 1`；`colors 654 → 724`；帧 `sha16 fa7df9222ebb199f → 1487caf78fd88886`；**两独立样本（`:235`／`:236`）逐格相同**。
6. ✅ **症状门无回归**：`alive=yes app_rc=143 failfast=0 magenta=0 ink=480000 ns=…FlowDocumentDemo`，`[HC-UNHANDLED]=1`（＝`T-A33` 的残留诚实拒绝，**未增**）。
7. ✅ **反极性（该红必红）**：同一 `.so` ＋ 显式 `WPF_PTS_FL_DRIVE=0` ⇒ `GATE-OFF`／`[FSATT-PROBE]=0`／四入口 **0** 次／`GhostWhite=0`／帧 `ef3fd6765f18f51b`（**逐格回改前**）。
8. **门禁（④）**：`nm==exports==681`；`PTSGAP=PASS tool=78 dead=11 artifact=1 ops=66 impl=69 so16=21ad5f39ef3c4034 exports=681`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS`（rc=0）；`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`。
9. ⚠️ **判决：部分成功**（**附属对象已落位 ∧ 1/4 具名色出 ∧ 无回归 ∧ 反极性成立**）。**如实划界**：`k=24` 的**四具名色只出 1 个**（`GhostWhite`）；`Beige`／`DarkGreen`／`LightGoldenrodYellow` **未**出 —— 三者都在 `Figure`/`Floater` 的**内容**里，需「附属对象**内容**排版」驱动（`SubpageHandle` 由托管在 `FormatFigure/FloaterContent*` 回调里设，本侧**未驱动**）⇒ 判据 `D2`（`hits≥2`）**未达**，占位/命名行两条红仍在。

---

## §1 改动（逐处，`win32_pts.c` ＋ 随动）

### 1.1 上游逐字镜像（`+`结构，`_Static_assert` 钉死）
`wpf_pts_fsupdateinfo`（8）／`wpf_pts_fsrect`（16）／`wpf_pts_fspoint`（8）／`wpf_pts_fsbbox`（20）／
`wpf_pts_fsattachedobjectdescription`（**72**）／`wpf_pts_fstrackdescription`（**64**）／
`wpf_pts_fssubpagedetailssimple`（**72**）／`wpf_pts_fssubpagedetailscomplex`（**64**）／
`wpf_pts_fssubpagedetails`（**80**）／`wpf_pts_fsfiguredetails`（**48**）／`wpf_pts_fsfloaterdetails`（**40**）。
（照 `upstream/…/PtsHost/Pts.cs`：`FSATTACHEDOBJECTDESCRIPTION:1416`／`FSSUBPAGEDETAILS*:1535/1546/1552`／
`FSFIGUREDETAILS:1351`／`FSFLOATERDETAILS:1082`／`FSTRACKDESCRIPTION:1517`／`FSKUPDATE:1934`。）

### 1.2 回调偏移（唯一定义处 ＋ 编译期断言）
```c
#define WPF_PTS_CBKTXT_IDX_GETNUMATTACHLINE   27     /* Pts.cs:694（FSCBKTXT 第 28 字段） */
#define WPF_PTS_SNAP_IDX_GETNUMATTACHLINE     (256/8 + 27)  == 59  @ 绝对 +512
#define WPF_PTS_CBKTXT_IDX_GETATTACHLINE      28     /* Pts.cs:695（第 29 字段） */
#define WPF_PTS_SNAP_IDX_GETATTACHLINE        (256/8 + 28)  == 60  @ 绝对 +520
```
（与既有 `pfnFormatLine` 索引 9／`+368`／下标 41 同形；`_Static_assert` 三条钉死。）

### 1.3 台账扩列（`wpf_pts_subtrack`）
`fl_att_n`／`fl_att_calls`／`fl_att_gap`／`fl_att_capped`／`owner_doc` ＋ `fl_att[WPF_PTS_FL_ATT_MAX=8]`
（每项：`nmp_obj`／`obj_client`／`obj_rc`／`idobj`／`dcp_anchor`／`line_idx`）。

### 1.4 窗内驱动（`wpf_pts_format_one_para`，行循环内）
对每行：① `num`（`+512`）；② `cAtt>0` ⇒ `objects`（`+520`）；③ 每个附属对象段落 `+176` 现造 client；
④ 记 `leaf->fl_att[]`。**零假值**：任一 `rc≠0` ⇒ 该行不记账（`fl_att_gap++`）；`rc=0 ∧ cAtt==0` ＝ **真 0**。
入口处**重置** `fl_att_*`（防跨趟累加）并记 `owner_doc`（**消歧用**）。

### 1.5 查询期回填
- `FsQueryTextDetails`：`e->full.c_attached_objects = o->fl_att_n`（**真值**，原恒 `0`）。
- `FsQueryTextDetails` 的 `[FS_TLB]` 行：`attached-objects(none)` ⇒ **具名真值**：
  `fl_att_n>0` ⇒ `attached-objects=present … figure=N floater=M`；`=0 ∧ 查过` ⇒ `not-present(true-queried)`；`未查` ⇒ `not-queried`（**三者不混同**）。

### 1.6 新增四入口（照上游逐字契约；诚实形态）
| 入口 | 认领 | 成功条件 | 几何 |
|---|---|---|---|
| `FsQueryAttachedObjectList` | 文本段落（`wpf_pts_sub_claim`） | 计数 == 台账 ∧ 全项 `obj_client` 非空 ∧ 出参非空 | 本侧约定（`wpf_pts_att_geometry`） |
| `FsQuerySubpageDetails` | 附属对象句柄（`wpf_pts_att_claim`）；**`pSubPage==NULL` 亦受理** | —— | **空子页**（`fSimple=0`／`cBasicColumns=0`，**真值**） |
| `FsQueryFigureObjectDetails` | 同上 ∧ `idobj==-2` | 同 | `fsrcFlowAround` |
| `FsQueryFloaterDetails` | 同上 ∧ `idobj!=-2` | 同 | `fsrcFloater` |

- **诚实形态**：认领**只**按台账真值；未命中／歧义／计数不符／出参 NULL／缺 paraclient ⇒ **返 `-10000` ＋ 出参一字不写**；`rc=0` **只**在语义成立时给。
- **`wpf_pts_att_claim` 消歧（有据）**：同一逻辑段落可有两代本侧对象（两趟窗），其附属对象**托管句柄相同** ⇒ 优先取 `owner_doc == ctx` 的那一代；无 doc 可依时取**最新代**（`seq` 最大）；多命中共计 `g_pts_att_ambig`（**具名，不静默**）。
- **`pSubPage==NULL` 为何如实返回空子页**：托管 `FigureParaClient.SubpageHandle`（＝`_paraHandle`）**由托管在"附属对象内容排版"回调里**设（`FigureParagraph.cs:284`／`FloaterParagraph.cs:355/523` 的 `SubpageHandle = pfs*Content`）；本侧**未驱动**该内容排版 ⇒ 该句柄**恒 0**。此**不是**错误入参，而是"内容未排 ⇒ **子页确实为空**"的**真值** ⇒ 本入口对 `NULL` **返回空子页**并**具名** `src=handle-unset(attached-content-not-laid-out)`；**非空但不可认领 ⇒ 仍拒**。

### 1.7 构建（现取）
`bash build-shim.sh --symbols`（经 `heavy-slot`）⇒ **0 错误**（既有 `-W*` 警告与本次无关）；产物
`bin/libwpfwin32.so` ＝ **`21ad5f39ef3c4034`**；`bin/exports.txt` ＝ **681**（`--symbols` 由 `nm` 重生成）。

---

## §2 成对机读读数（**同一跑器**：`runner_sha16=330a90f1f0ac28e4`／`session_sha16=f1a582d9ea9788c9`／`guard_sha16=962fec114b2d0692`；A 臂 `:235`／`:236`）

| 腿 | `.so` | 闸 | 证据目录 |
|---|---|---|---|
| `legs-probe`（方案 1） | `6cfa683cb18ee97a` | 缺省（**只读探针**） | `~/tA36-work/legs-probe` |
| `legs-1`（方案 2·首版） | `0b0cb6e91f40b8fa` | 缺省 | `~/tA36-work/legs-1` |
| `legs-2`（方案 2·消歧） | `02cb89c8020f3413` | 缺省 | `~/tA36-work/legs-2` |
| **`legs-3`（方案 3·空子页）** | **`21ad5f39ef3c4034`** | 缺省 | **`build/…/evidence-tail2e/`** |
| `legs-3b`（**第二独立样本**） | `21ad5f39ef3c4034` | 缺省（`:236`） | `…/evidence-tail2e/sample2/` |
| `legs-polar3`（**反极性**） | `21ad5f39ef3c4034` | **显式 `WPF_PTS_FL_DRIVE=0`** | `…/evidence-tail2e/polar/` |

### 2.1 症状门 ＋ 帧面（逐腿，现取）

| 腿 | `app_rc` | `alive` | `failfast` | `magenta` | `colors`(k24) | `ns`(k24) | `fr_sha`(k24/k23) |
|---|---|---|---|---|---|---|---|
| `legs-probe` | 143 | yes | 0 | 0 | 654 | `…FlowDocumentDemo` | `fa7df9222ebb199f`／`10d0b9d54e649c10` |
| `legs-1` | 143 | yes | 0 | 0 | **383**（回退） | `…FlowDocumentDemo` | **`ef3fd6765f18f51b`**／`10d0b9d54e649c10` |
| `legs-2` | 143 | yes | 0 | 0 | **383**（回退） | `…FlowDocumentDemo` | `ef3fd6765f18f51b`／`10d0b9d54e649c10` |
| **`legs-3`** | **143** | **yes** | **0** | **0** | **724** | `…FlowDocumentDemo` | **`1487caf78fd88886`**／`10d0b9d54e649c10` |
| `legs-3b` | 143 | yes | 0 | 0 | 724 | `…FlowDocumentDemo` | `1487caf78fd88886`／`10d0b9d54e649c10` |
| `legs-polar3` | 143 | yes | 0 | 0 | **383** | `…FlowDocumentDemo` | `ef3fd6765f18f51b`／`10d0b9d54e649c10` |

⇒ **症状门六项逐格现取**；改后仅 `colors` **增**（383→724）；`k23` 的 `ns=HandyControlDemo.UserControl.RichTextBoxDemo`（各腿同）。

### 2.2 计数成对（`grep -c`，现取；`evidence-tail2e/app_g1.log` `sha16=35ad72f5f81a13a7`）

| 计数 | 改前（`T-A34` 现场，**只作对照**） | **改后（`legs-3`）** | `legs-polar3` |
|---|---|---|---|
| `[FS_TLB]` | 7632 | 3431 | ——（`FsQueryTextDetails` 全拒 ⇒ 0 行） |
| **`attached-objects(none)`** | **6104（100%）** | **0（形状归零）** | 0 |
| `attached-objects=present` | 0 | **1008** | 0 |
| `attached-objects=not-present(true-queried)` | 0 | 1614 | 0 |
| `[FSATT-PROBE]` | ——（无此探针） | 42（`cAtt=2 distinct`） | **0**（`GATE-OFF`） |
| `Figure`／`Floater` 字样 | 0／0 | 见下（四入口名） | 0 |
| `[HC-UNHANDLED]` | 1 | **1**（**无回归**） | 108（＝`T-A33` 改前行为） |
| `reason=no-text-line-model` | 0 | 0 | 0（`FsQueryTextDetails` 全拒走 `nomodel`） |
| `FsQueryAttachedObjectList`（`[FS_ATT] rc=0`） | —— | **405** | 0 |
| `FsQuerySubpageDetails`（`rc=0`） | —— | **810**（`src=handle-unset`，全部） | 0 |
| `FsQueryFigureObjectDetails`（`rc=0`） | —— | 201 | 0 |
| `FsQueryFloaterDetails`（`rc=0`） | —— | 203 | 0 |
| 四入口 `[FS_PAGE_GAP]`（拒） | —— | **0** | 0 |

**逐字样本（`legs-3`）**：
```
[FSATT-PROBE] where=FsCreatePageBottomless para=0x8 i=7 pfsline=0x13 rcNum=0 rcObj=0 cAtt=2
              fl_att_n=2 gap=0 capped=0 att0_obj=0x14 att0_id=-2 att0_rc=0 doc=0x6176dbfbc460
[FS_TLB] entry=FsQueryTextDetails parah=0x… cLines=8 … attached-objects=present queried=8 gap=0
         capped=0 figure=1 floater=1 NOINFO=fsgeometry-layout(vrStart=self-accum)
[FS_ATT] rc=0 entry=FsQueryAttachedObjectList para=0x… cAttachedObjects=2 out=WRITTEN bytes=144 src=ledger:fl_att[]
[FS_ATT] rc=0 entry=FsQuerySubpageDetails subpage=(nil) fSimple=0 cBasicColumns=0
         src=handle-unset(attached-content-not-laid-out) out=WRITTEN bytes=80 NOINFO=attached-content-not-laid-out
[FS_ATT] rc=0 entry=FsQueryFigureObjectDetails figure=0x14 fsrc=(30000,20000,42000,15000) out=WRITTEN bytes=48
         NOINFO=attached-object-geometry-layout(self-convention)
```

---

## §3 帧面（**本席自算**，只读 PNG；判据 ③）

| 腿 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `ncolors` | `fr_sha` |
|---|---|---|---|---|---|---|
| `boot.png`（**活锚基线**） | **0** | 0 | 0 | 0 | 386 | `b21eb530afd3c66c` |
| **`legs-3 k24.png`** | **`29637`** | 0 | 0 | 0 | **724** | **`1487caf78fd88886`** |
| `legs-3 k23.png` | 0 | 0 | 0 | 0 | 636 | `10d0b9d54e649c10` |
| `legs-3b k24.png`（第二样本） | **`29637`** | 0 | 0 | 0 | 724 | `1487caf78fd88886` |
| `legs-polar3 k24.png`（反极） | **0** | 0 | 0 | 0 | 383 | `ef3fd6765f18f51b` |

- **判据 D2 现取**：`PTS_COLORANCHOR=FAIL k=24 … GhostWhite=29637 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=1 expect_min=200 expect_hits=2 … phase=degraded reason=declared-color-anchor-absent`（判词全文见 `evidence-tail2e/guard-degraded.txt`）。⇒ **`hits 0→1`（首色落位）**，但 `hits=1 < 2` ⇒ **D2 未达**。
- **判据 D3（块状几何落位）**：`GhostWhite=29637 px`（**块状**，`≥` 单个 `Figure 140×50`＝7000 px ＋ `Floater` 285 宽）⇒ **块状元素已落位且其像素 ∈ 具名色**；`AE(boot,k24)`（`legs-3` `220546`，> `T-A33` 的 `219340`）。
- **两页帧分离**：`k24=1487caf78fd88886 ≠ k23=10d0b9d54e649c10`；且 `k24 ∉ FRAME_EMPTY_SET`。
- ⚠️ **不得读宽**：`GhostWhite` 是 `Figure`/`Floater` 的 **`Background`**（`DrawBackgroundAndBorder` 所绘），**不是**"内容真绘出"；`Beige`/`DarkGreen`/`LightGoldenrodYellow`（内容色）**全 0**。

---

## §4 反极性（**同一 `.so` ＋ 同一跑器 ＋ 同一装置**，只差**一个 env**：`WPF_PTS_FL_DRIVE`）

| 判据 | 改后（缺省） | **显式 `=0`（`polar`）** | 改前（`T-A33` 现场） |
|---|---|---|---|
| `[FORMATLINE]` 窗级 | `gate=1 … v=DRIVEN` | **`gate=0 v=GATE-OFF`**（**回改前**） | `gate=1`（`T-A33` 同驱） |
| `[FSATT-PROBE]` | 42 | **0**（未驱 ⇒ 无台账） | ——（无此探针） |
| `attached-objects` | `present`×1008 | **0**（`FsQueryTextDetails` 全拒） | `attached-objects(none)`（旧形状） |
| 四入口调用 | 1619（全 `rc=0`） | **0** | 0 |
| `[HC-UNHANDLED]` | **1** | **108** | 1（`T-A33` 代） |
| `colors`／`fr_sha`(k24) | **724**／`1487caf78fd88886` | **383**／`ef3fd6765f18f51b` | 654／`fa7df9222ebb199f` |
| `GhostWhite`(k24) | **29637** | **0** | 0 |

⇒ **反极性成立**：「**台账空 ⟺ 附属对象不落位**」钉死（`GATE-OFF` ⇒ 无探针／无回填／`GhostWhite` 回 0 ∧ 帧逐格回改前 `ef3fd6765f18f51b`）。
（`polar` 的 `[HC-UNHANDLED]=108` ＝ `WPF_PTS_FL_DRIVE=0` 的**回改前**行为，与 `T-A33` 的 `legs-polar0` 同族。）

---

## §5 验收逐条（对 `T-A36` ③ 与 `T-A35` §4.2 判据 `D1–D4`）

- **① `A35 §4` 的 4 条判据逐条现取 ＋ 每条带反极性**：
  - **`D1` 台账实名化／零假值**：✅ —— `attached-objects(none)` **形状归零**（0），改报 `present … figure=N floater=M`（`idobj` 取自回调原值：`-2`＝Figure）；**未写出参 ≠ 写 0**（`not-present(true-queried)` 与 `not-queried` 分立）。**反极**：`polar` ⇒ 台账空 ⇒ `num` 未发调 ⇒ 无 `attached-objects` 行（`FsQueryTextDetails` 全拒）。
  - **`D2` 色锚转 `PASS`（可证伪）**：❌ **未达** —— `hits=1`（`GhostWhite=29637 px`），`expect_hits=2` ⇒ `PTS_COLORANCHOR=FAIL`。**但方向成立**（`0→1` 首色落位）；`baseline(boot.png)` 四色**仍全 0**（活锚）。**反极**：`polar` ⇒ `GhostWhite=0`。**另**：未把 `k=24` 的锚推广到 `k=23`（`k23` 仍 `NOINFO`）。
  - **`D3` 块状几何落位（可证伪）**：✅（部分）—— `GhostWhite=29637 px` **块状**且 ∈ 具名色；`AE(boot,k24)` 差异落在内容区。**反极**：`polar` ⇒ 无块（`383`）。
  - **`D4` 失败必留痕 ＋ 计数恰涨 1**：✅ —— 四入口的**每条**拒绝**必**打具名 `[FS_PAGE_GAP] rc=-10000 reason=… entry=… ok= gap=`（`gap` 恰涨 1）；与"真 0 次"可分（`polar` ⇒ 0 行）。本次**成功路径 1619 条、拒绝 0 条**（真实 0 次拒绝，非静默）。**反极**：`polar` ⇒ 四入口 0 次（`FsQueryTextDetails` 拒在前）。
- **② 计数成对 ＋ 关键（`k24` 四具名色各 ≥200px）**：§2.2 ＋ §3 —— `GhostWhite` ✅；`Beige`/`DarkGreen`/`LightGoldenrodYellow` ❌（**0**）。`[FSQTD]`／`[FSQLL]`／附属对象台账计数**成对**（§2.2）。
- **③ 帧面成对**：§3（`boot`/`k24`/`k23` 三帧 `sha16` ＋ `AE`；`k24 ∉ FRAME_EMPTY_SET`；两独立样本逐格相同）。
- **④ 导出面 `nm==exports`；`PTSGAP=PASS`；`DEFREG`/`REPORTID` rc=0**：✅ —— `nm -D --defined-only` ＝ `exports.txt` ＝ **681**（逐名 `diff` 零差异）；`PTSGAP=PASS tool=78 dead=11 artifact=1 ops=66 impl=69 so16=21ad5f39ef3c4034 exports=681`（rc=0）；`DEFREG=PASS declared=225 route_ids=225`（rc=0）；`REPORTID=PASS`（rc=0）；另 `HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`。
- **⑤ 症状门**（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）：§2.1（**逐格现取**；改后仅 `colors` 增）。

---

## §6 边界 · `NOINFO` · 主动披露

1. **改动面（`git status --porcelain` 现取）**：`M README.md`／`M build/MilBridge/HANDOFF-NEXT.md`／`M docs/ROUTES.md`／`M docs/unimplemented.md`／`M samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`M src/WpfGfx.Linux.Native/src/win32_classification.c`／`M src/WpfGfx.Linux.Native/src/win32_pts.c`／`M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` ＋ **本载体** ＋ **先于本件**的两项 untracked（`build/MilBridge/tasks-tail2/T-A35.md`／`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`）＋ `T-A35` 载体 ＋ **新建** `evidence-tail2e/`。`bin/libwpfwin32.so`／`bin/exports.txt` 是**构建生成件**（`git ls-files` 现取 0 ⇒ 不入库），不计入手改面。
2. 🔴 **中间腿（如实披露，防被读成"一次成型"）：本席共跑 3 趟构建 / 7 趟腿，三处新前沿逐个暴露并修复**（每步都从"现取读数"推进）：
   - **方案 1（`legs-probe`）**：**只读探针**（只调 `num`，不改语义）⇒ 现取 `cAtt=2`（`para=0x8 i=7`）**首证附属对象可达**；**帧面逐格与 `T-A34` 相同**（探针**零副作用**）。
   - **方案 2 首版（`legs-1`）**：`FsQueryTextDetails` 回填 `cAttachedObjects` ＋ 四入口 ⇒ **回归**：`k24 colors 654→383`（帧回退 `ef3fd676`）、`[HC-UNHANDLED] 1→352`，因 `FsQueryFloaterDetails` 全 `unclaimable-floater`（＝附属对象托管句柄在两代本侧对象间**歧义**）。⇒ 加 `owner_doc` 归属 ＋ `att_claim` 消歧。
   - **方案 2 消歧版（`legs-2`）**：`unclaimable-floater` 消失，但 `FsQuerySubpageDetails` 全 `null-subpage`（`pSubPage==NULL`）⇒ 仍回归（`colors=383`、`[HC-UNHANDLED]=439`）。⇒ 落「`NULL` 亦受理、如实返回**空子页**」（见 §1.6）。
   - **方案 3（`legs-3`）**：✅ 成（本报告读数）——`GhostWhite=29637`、`[HC-UNHANDLED]=1`、帧 `1487caf78fd88886`。
   - ⚠️ **方案数 = 3**（`legs-3b`／`legs-polar3` 是**同一方案的第二样本／反极性腿**，非另一方案）。
3. **`NOINFO`（逐条给"消掉需要什么"）**：
   - `NOINFO-attached-content-not-laid-out`（**新读出，本轮核心边界**）：`Figure`/`Floater` 的**内容**（`Beige`/`DarkGreen`/`LightGoldenrodYellow` 所在）**未排版** ⇒ 仅**背景**色（`GhostWhite`）落位。**消掉需要**：native 驱动"附属对象内容排版"（`pfnFormatFloaterContentFinite`／`Bottomless`／`pfnGetFloaterProperties` 等，使托管 `FloaterParagraph.cs:355/523`／`FigureParagraph.cs:284` 回填 `SubpageHandle`）⇒ 下一增量。
   - `NOINFO-attached-object-geometry-layout`：附属对象几何（`fsrcFlowAround`／`fsrcFloater`）＝**本侧约定**（`Figure 140×50 DIP`／`Floater 285×100 DIP` × 300 单位，按序错开），**非**上游 ABI 几何。消掉需真机对拍或驱动点直插几何入站源。
   - `NOINFO-TLB-ATTACHED-OBJECTS`（承 `T-A33`，**本轮部分消**）：`FSTEXTDETAILSFULL.cAttachedObjects` 由恒 `0` ⇒ **真值**；但附属对象**内容**仍不产出。
   - `NOINFO-ATTACHED-ABSENT-CAUSE`（承 `T-A35` §5，**本轮部分消**）：现取**证伪**其"本侧无此概念"一支（`cAtt=2` 可达），但"页面未完成格式化"一支与"内容未排版"并存 ⇒ 仍具名。
4. **本增量的射程边界（写死，防被读宽）**：本增量解的是 **PTS 附属对象这一层**的"**台账 ＋ 落位**" —— **不是**"PTS 真实现"，**不是**"该页内容真绘出"（四具名色**只出 1 个**，且是背景色）；`[HC-UNHANDLED]=1` 的残留（`FsQueryTrackParaList` 的 `drive-handles-released(page-destroyed)` 诚实拒绝）**未动**。
5. **导出面代价（如实登记）**：新增 4 导出 ⇒ `exports 677→681`、`so16 04f6d354b0a71888→21ad5f39ef3c4034`；缺口计数**下降** `ops 70→66`／`impl 73→69`／`tool 82→78`（`tool = ops + dead + artifact` 恒式保持）。**计数下降 ≠ 能力前进**（件头第 ① 条）—— 本增量的前沿跳在**帧面**（`GhostWhite 0→29637`）。
6. **正文复述位随动面（现取）**：`docs/ROUTES.md`（§15x 树内 `T-A36` dated 落地行 ＋ 四处现值位）／`README.md`（"已知问题"表 dated 更正＋现值位）／`docs/unimplemented.md`（现值位）／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`D-G70` 段现值位）／`build/MilBridge/HANDOFF-NEXT.md`（§3 dated 对齐行 ＋ `cell=#1` 输入指纹机器值更正行）／`src/WpfGfx.Linux.Native/src/win32_classification.c`（注释现值位）—— 全 **只增不改**（现值位数字随动除外）⇒ `PTSGAP=PASS`／`HANDOFF_MV=PASS`。
7. **未做的（防被读宽）**：未跑整趟 `verify-all`；未跑 `static-jaws-check.sh`；未判相位；未动任何牙本体；**未**新增任何 `D-G<digits>` 登记编号；未跑 `--all-arms`（只跑 A 臂 `24,23`）；未跑 `WPF_PTS_DRIVE_PROBE=0` 腿（探针闸缺省开）。
8. **侧效（如实披露，未进仓）**：`~/tA36-work/`（`bak/` 改前件 ＋ `app/` 私有应用安装 ＋ `legs-*/` 七趟腿证据 ＋ 跑腿脚本 `legs.sh`／`legs-slot.sh`）；仓内应用安装**一字未动**（`sync-applocal.sh --check … drift=0` 逐腿现取）。
9. **跨代／跨装置不可比（纪律 31/32）**：§2／§4 的"改前"列取自 `T-A34` 的**在册** `evidence-tail2d/`（**另一代 `.so`**）⇒ 只报**结果**（`colors 654→724` 等），**不做减法**承重；"改后"列＝本席**同趟新取**（`evidence-tail2e/`）。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-attach-impl-report.md | sha256sum | cut -c1-16`）= `fe39f741b30b336e`

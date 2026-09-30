# `P1-tail2` · `T-A52` · 第 4 色 `LightGoldenrodYellow`（native `FSFLOATERCBK`／`GetFloaterHandlerInfo`）—— 实现报告（**判决：`GetFloaterHandlerInfo` 已由具名缺口 stub 升为真实现 ∧ Floater 内容真造出（子页 `SUBPAGE-CREATED`）∧ 反极性成立 ∧ 缺省路径零回归；但判据 ① `LightGoldenrodYellow ≥200px` 未达 —— 真前沿被本趟定为 `Table` 族**）

- **读时**：`2026-10-01T07:2x–07:4x+0800`（本席现取，各条另注）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=25ba835`（＝ `T-A51` 收尾那笔；**未换代**）。
- **改前件备份（仓外 `~/tA52-work/bak/`，`cp -p`，取在**任何写之前**）**：`win32_pts.c`（`4cff4a6d44934757`）／`exports.txt`（`860a3abe4a64f1c5`）／`pts-gap-decl.txt`（`f8bc1b7ab62efe36`）／`reapply-patches.py`（`b6a3a24137a77ddf`）。
- **写域（逐件）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**四处**：定义/持有位 ＋ `GetFloaterHandlerInfo` 真实现 ＋ 窗内 Floater 驱动 ＋ 自检成对断言）／其登记面 `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`impl`＋`so16` 锚 ＋ dated 追注）／复述位现值位（`docs/ROUTES.md`×3／`README.md`／`docs/unimplemented.md` 未动值／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`）／**新建载体** 本件。
- **未改**（如实体例）：`build/PresentationFramework.Linux/reapply-patches.py`（**生成器一字未动**）⇒ 其重产件亦未动（`git status` 只列 native 一件 ＋ 复述位件 ＋ 本件）；`src/WpfGfx.Linux.Native/bin/exports.txt`（**导出面一字未动**，见 §3）。
- **黑名单遵守**：未动 `build/shims/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**只读跑**判据件）／`upstream/**`（只读）；**未跑**整趟 `verify-all`；未改相位位；未 `git add/commit/push`。
- **重活**：**3 趟 native 构建**（各 `3 s`）＋ **3 趟跑器**（共 **6 条腿**；全走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`，逐趟 `HEAVYSLOT=RELEASED rc=0 held=3/34/33s`）；进程只按 PID；显示位 `:231`（装置自取；逐趟 `DEVICE_REAP state=clean`）；禁 `sleep` 轮询；写前 `cp -p`；模式守恒。
- **行号纪律**：本件行号**仅本次有效**；引件一律给**内容锚**。
- **口径**：一切读数**本席现取**（`sha256sum`／`nm -D --defined-only`／`grep -c`／只读 `python3`＋`PIL` 解 PNG／`compare -metric AE`／`bash build/MilBridge/tools/{pts-pages-guard,pts-gap-count-check,defect-registry-check,report-id-domain-check}.sh`／生成器与自检**只读**）。

---

## §0 结论速览（自包含）

1. ✅ **`GetFloaterHandlerInfo` 由具名缺口 stub 升为真实现**（上游语义 `Pts.cs:3065`；`PtsHost.GetObjectHandlerInfo`（`:1092`，`idobj==FloaterParagraphId`）→ `PtsCache.GetFloaterHandlerInfoCore`（`:248`）→ `PTS.GetFloaterHandlerInfo(ref FSFLOATERINIT, pObjectInfo)`）。本侧**逐槽只读捕获**托管交出的 `FSFLOATERCBK`（16 槽／128 B）到持有位 `g_pts_floater_cbk[]`（后续发调源）＋ 出参非空时**逐槽原样转写**；`NULL` init ⇒ **拒**（`-10000` ＋ 具名 `[FS_PAGE_GAP] reason=null-init`）。现取 `[FSFLOATER-CBK] rc=0 … slots=16 fmtFinite=0x… fmtBottomless=0x… out=WRITTEN bytes=128 src=managed-FSFLOATERINIT`（**2 次**，gate-on 腿）。
2. ✅ **Floater 内容真造出**：照 `T-A37` 对 `Figure` 的同形体例，在**窗内**（`FsCreatePageFinite`）对 `idobj==FloaterParagraphId(2)` 调 `pfnGetObjectHandlerInfo` ＋ `pfnFormatFloaterContentFinite`（`FSFLOATERCBK` 槽 1）。现取 `[FSFLOATER-CONTENT] where=FsCreatePageFinite floater=0x15 client=0x1b rch=0 rc=0 kstop=0 durW=8381 dvrH=30000 cPoly=0 cVert=0 pfsFloatContent=0x… subpage=0x… sp_created=2/4 v=SUBPAGE-CREATED`（**2 次**）⇒ 托管 `FloaterParagraph.CreateSubpageFiniteHelper` 内 `FsCreateSubpageFinite` **本侧真造内容子页**（托管 `FloaterParaClient.SubpageHandle` ⇒ `_paraHandle`）。
3. 🔴 **判据 ① 未达（如实划界）**：驱动 Floater 内容后，托管 `FloaterParaClient.ValidateVisual` ⇒ `PtsHelper.UpdateTrackVisuals` **下到 Table 段落** ⇒ `TableParaClient.QueryTableDetails` ⇒ `PTS.FsQueryTableObjDetails`（本移植**未导出**）⇒ `EntryPointNotFoundException` ⇒ `FlowDocumentView.ArrangeOverride` 抛 ⇒ **整页空白**。现取（gate-on 腿）：`entry point named 'FsQueryTableObjDetails'` **394 条**、`[HC-UNHANDLED]=394`、`[FSVIEW] site=ArrangeOverride.Arrange outcome=exception type=System.EntryPointNotFoundException`、`k24 fr_sha=ef3fd6765f18f51b colors=383`（**空态参照集成员**）。⇒ `LightGoldenrodYellow` 仍 **0 px**。
4. ✅ **缺省路径零回归（闸缺省关）**：新增运行期闸 `WPF_PTS_FLOATER_CBK` **缺省 `0`（关）**；⇒ 缺省路径与改前**逐格相同**：`k24 fr_sha=791696291d51470b colors=905`（`GhostWhite=22736`／`Beige=910`／`DarkGreen=44` 未退）、`[HC-UNHANDLED]=0`、`entry point named=0`、`PTS_GUARD=PASS`、`PTS_COLORANCHOR=PASS hits=2`。
5. ✅ **反极性（同一 `.so`／同装置／只差 env）**：`off1`（缺省）↔ `on1`（显式 `WPF_PTS_FLOATER_CBK=1`）—— `AE(boot)=0`、`AE(k23)=0`、`AE(k24)=210578`（**差只落在被驱动的那一页**）；`PTS_GUARD` `PASS` ↔ `FAIL`（红行点名 `leg24-n1-frame-unestablished(...)`／`leg24-color-anchor-absent(...)`／`enfe-unhandled(total=394,non_allow=FsQueryTableObjDetails)`）⇒ **该红必红**。
6. ✅ **门禁四件**：`nm -D --defined-only` ＝ `exports.txt` ＝ **683**（逐名 `diff` 零差异）｜`PTSGAP=PASS tool=76 dead=11 artifact=1 ops=64 impl=66 so16=1067da454b7ef114 exports=683`（`rc=0`）｜`DEFREG=PASS declared=225 route_ids=225`（`rc=0`）｜`REPORTID=PASS files=329 ids=2238 declared=225`（`rc=0`）。
7. 🔴 **具名下一靶 ＝ `NATIVE-PTS-TABLEOBJ`**（`FsQueryTableObjDetails`／`FsQueryTableObjTableProperDetails`／`FsQueryTableObjRowList`／`FsQueryTableObjRowDetails`／`FsQueryTableObjCellList` 五入口 ＋ `GetTableObjHandlerInfo`／`FSTABLEOBJCBK`）。`WPF_PTS_FLOATER_CBK` 的**缺省翻转**必须等它落地（`T-A28→T-A31` 同体例）。

---

## §1 为什么 `LightGoldenrodYellow` 不在 `FSFLOATERCBK` 这一层（断点逐跳）

| 跳 | 件:行（内容锚） | 现取 |
|---|---|---|
| ① 该色属谁 | `P1-tail2-coloranchor-recon.md`（口径表）：`LightGoldenrodYellow(250,250,210)` ＝ **`Floater` 内 `<Table>` 的两个 `<TableRow Background="…" FontSize="12">`** | —— |
| ② Floater 内容排版入口 | `FloaterParagraph.cs` `FormatFloaterContentFinite`（`Pts.cs:2581` 委托；槽 1） | ✅ 本趟驱动（`[FSFLOATER-CONTENT] rc=0 v=SUBPAGE-CREATED`） |
| ③ 内容子页 | `FloaterParagraph.CreateSubpageFiniteHelper` → `PTS.FsCreateSubpageFinite`（`Pts.cs:3169`） | ✅ 本侧**真造**（`FsCreateSubpageFinite`，`T-A37` 已落地） |
| ④ 视觉下潜 | `FloaterParaClient.ValidateVisual`（`_paraHandle` 被 `SubpageHandle` setter 设为**子页句柄**）→ `PtsHelper.UpdateTrackVisuals` | ✅ 走到（`FsQuerySubpageDetails` 内容子页支认出 ⇒ `fSimple=1`） |
| ⑤ **Table 段落** | `TableParaClient.QueryTableDetails` → `PTS.FsQueryTableObjDetails`（`Pts.cs:3815`） | 🔴 **未导出** ⇒ `EntryPointNotFoundException` ⇒ **Arrange 抛 ⇒ 整页空白** |
| ⑥ 后续还需 | `FsQueryTableObjTableProperDetails`／`FsQueryTableObjRowList`／`FsQueryTableObjRowDetails`／`FsQueryTableObjCellList`（`TableParaClient.cs` 内 5 条 `PTS.Fs*`，现取 `grep -o 'PTS\.Fs*' Table*.cs`）＋ `GetTableObjHandlerInfo`／`FSTABLEOBJCBK` | 🔴 全**未实现** |

⇒ **本任务的具名前置（`FSFLOATERCBK`）已解，但第 4 色的真前沿在它**后面**：`Floater` 的内容本页是一个 `<Table>`**（见 §3.3 成对读数）。

---

## §2 改动（逐处；全部在 `win32_pts.c`）

### 2.1 形状/定义处（`WPF_PTS_FLOATERCBK_SLOTS` 等；内容锚「`T-A52`（`NATIVE-PTS-FLOATERCBK`）」块）
`FSFLOATERCBK` 16 槽（`Pts.cs:1028-1046`）／`FSFLOATERINIT`（`Pts.cs:1074`）＝ `{FSFLOATERCBK}`（**只此一字段**，128 B）；槽序逐字 `0 pfnGetFloaterProperties`／`1 pfnFormatFloaterContentFinite`／`2 pfnFormatFloaterContentBottomless`／…；驱动入口 `FloaterParagraphId`（`PtsHost.cs:81`）现取 ＝ **2**（与 `[FSATT-PROBE] … att0_id=2` 同值）。C 侧原型：`wpf_pts_fn_get_object_handler_info`／`wpf_pts_fn_format_floater_content_finite`（照 `Pts.cs:2581-2603` 逐参；`FSFMTR`＝12 B／`FSBBOX`＝20 B）。

### 2.2 `GetFloaterHandlerInfo`（由 `return wpf_pts_gap("GetFloaterHandlerInfo");` 改为真实现）
入参即 `FSFLOATERINIT*` ⇒ **只读捕获** 16 个函数指针值（**不 deref** 托管结构；同 `pfnFormatLine` 体例）＋ 出参非空时逐槽转写；`NULL` init ⇒ 拒（出参一字不写）。**这两条都可复核**（gate-on 腿的 `[FSFLOATER-CBK]` 行；自检成的对断言见 §2.4）。

### 2.3 窗内 Floater 驱动（`wpf_pts_format_one_para` 的附属对象循环）
在既有 `Figure`（`idobj==-2`）驱动之后，新增 `else if (… idobjs[a] == WPF_PTS_FLOATER_ID && fpObjHandler)` 支：① `pfnGetObjectHandlerInfo(fsclient, 2, objinfo[128])`；② `pfnFormatFloaterContentFinite(fsclient, oc, NULL, 0, objs[a], NULL, fEmptyOk=1, fSuppressTopSpace=0, fswdir=0, fAtMaxWidth=1, durAvailable=85500, dvrAvailable=30000, fsksuppress=0, fsfmtr[3], &pfsc, &pbrk, &durw, &dvrh, fsbbox[20], &cpoly, &cvert)`；`rc=0 ∧ 新子页` ⇒ 记 `sub_obj`（**零假值**：`rch≠0` 或槽 1 空 ⇒ 不发调，具名留痕；`rc≠0` ⇒ 不记子页）。`fpObjHandler` ＝ 快照下标 **70**（`cbkobj` 第 8 槽／绝对 `+600`，`T-A37` 已钉）。

### 2.4 运行期闸 ＋ 自检同趟
- 新增 `wpf_pts_floater_cbk_gate()`：**缺省 `WPF_PTS_FLOATER_CBK_DEFAULT 0`（关）**；显式 `=1` 才开（**反极性腿**）。
- 自检 `WpfLinuxWin32_PtsGapSelfCheck` 里旧断言 `GetFloaterHandlerInfo(sb, sp) != -10000 ⇒ rc=7`（**已随真实现作废**）改为**成对断言**：`GetFloaterHandlerInfo(NULL, sp) != -10000 ⇒ rc=7`（NULL 必被拒）＋ `GetFloaterHandlerInfo(sb, NULL) != 0 ⇒ rc=72`（有效 init、空 out ⇒ 真实现必须成功）。**同趟把夹具 `sb`／`sp` 由 64 B 加到 256 B** —— 真实现按契约读 `FSFLOATERINIT`（16×8＝128 B），旧 64 B 夹具上那次调用**越界**（本步顺手堵掉）。

### 2.5 为什么**不是**改生成器／不是改导出面
- 本轮**一个字节都没碰** `reapply-patches.py` 与其重产件 —— 本增量全在 native（**无需托管改动**：托管的 `FormatFloaterContentFinite`／`FsCreateSubpageFinite` 链在 `T-A37` 已备）。
- 亦**未新增导出**：`GetFloaterHandlerInfo` 早在 `exports.txt` 内（**改的是实现、不是导出面**）⇒ `nm==exports==683` 逐名零差异。

---

## §3 成对读数（**同一 `.so 1067da454b7ef114`／同装置 `:231`／同批工具**；证据 `~/tA52-work/legs/{off1,on1}`；`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`）

| 腿 | env | 证据目录 |
|---|---|---|
| `off1` | 缺省（闸 **关**） | `~/tA52-work/legs/off1/` |
| `on1` | `WPF_PTS_FLOATER_CBK=1`（闸 **开**） | `~/tA52-work/legs/on1/` |

### 3.1 逐腿现取计数（`grep -c`，`app_g1.log`）

| 量 | `off1`（缺省） | **`on1`（驱动）** |
|---|---|---|
| `[FSFLOATER-CBK]` | **0** | **2** |
| `[FSFLOATER-CONTENT]` | **0** | **2**（`v=SUBPAGE-CREATED` ×2） |
| `v=SUBPAGE-CREATED`（合计） | 2（＝`Figure` 支） | **4**（`Figure` 2 ＋ `Floater` 2） |
| `[FSATT-CONTENT]`（`Figure` 支） | 2 | 2（**未退**） |
| `entry point named` | **0** | **394**（全部 `'FsQueryTableObjDetails'`） |
| `[HC-UNHANDLED]` | **0** | **394** |
| `[FSVIEW]` | 2 | 3（含 `outcome=exception` 1） |
| `app_g1.log` 行数 | 58028 | 15648 |

### 3.2 帧面（逐腿现取：`leg_*.env` ＋ 只读 PNG）

| 腿 | `alive` | `app_rc` | `magenta` | `colors`(k24) | `ink` | `ns`(k24) | `k24` `fr_sha` | `k23` `fr_sha` | `boot` `fr_sha` | `fr_ae_boot` |
|---|---|---|---|---|---|---|---|---|---|---|
| **`off1`** | yes | 143 | 0 | **905** | 480000 | `…FlowDocumentDemo` | **`791696291d51470b`** | `10d0b9d54e649c10` | `b21eb530afd3c66c` | 220019 |
| `on1` | yes | 143 | 0 | **383** | 480000 | 同 | `ef3fd6765f18f51b`（**空态参照成员**） | `10d0b9d54e649c10` | `b21eb530afd3c66c` | 15386 |

**帧差（本席自算，只读 PNG）**：`AE(boot_off, boot_on)=0`、`AE(k23_off, k23_on)=0`、**`AE(k24_off, k24_on)=210578`** ⇒ 两极的差**只落在被驱动的那一页**（`k23`／`boot` 逐字节同值）。

### 3.3 帧面四色锚（**本席自算**，只读 PNG；锚集 `GhostWhite=248,248,255`／`Beige=245,245,220`／`DarkGreen=0,100,0`／`LightGoldenrodYellow=250,250,210`；`LightGray` **不入集**）

| 帧 | 腿 | `GhostWhite` | `Beige` | `DarkGreen` | `LightGoldenrodYellow` | `ncolors` |
|---|---|---|---|---|---|---|
| `boot` | 两腿同值 | 0 | 0 | 0 | 0 | 386 |
| **`k24`** | **`off1`** | **22736** | **910** | **44** | **0** | **905** |
| `k24` | `on1` | **0** | **0** | **0** | **0** | **383** |
| `k23` | 两腿同值 | 0 | 0 | 0 | 0 | 636 |

⇒ `off1` 即**在册现值**（`PTS_COLORANCHOR=PASS hits=2`）；`on1` 把整页打回**空态**（**不得把空白读成绿**）。

### 3.4 判据件读数（`--legs`；纯读、零 `dotnet`）

```
# off1
PTS_G10_NAME=PASS observed=FsQueryTextDetails names=12 roster=24 domains=pts-declared,dllimport-entry decl=…/Pts.cs:3168
PTS_N1_POS=phase=realized positive=n4(support=color-anchor:2colors>=200),differ(via=compare) n4=10d0b9d54e649c10,791696291d51470b …
PTS_COLORANCHOR=PASS k=24 scan=GhostWhite=22736 Beige=910 DarkGreen=44 LightGoldenrodYellow=0 hits=2 min=200 base=…all-0 phase=realized
PTS_ENFE=PASS total=0 by_name=none … log=…/off1/app_g1.log log_sha16=8e7d576479c909aa
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=leg23-colors-out-of-band=636 direction=in-file phase=realized
# on1
PTS_COLORANCHOR=FAIL k=24 scan=GhostWhite=0 Beige=0 DarkGreen=0 LightGoldenrodYellow=0 hits=0 … reason=declared-color-anchor-absent
PTS_GUARD=FAIL legs=2/2 fails=leg24-n1-frame-unestablished(frame-identity(sha16=ef3fd6765f18f51b∈{…})),leg24-color-anchor-absent(hits=0<2,…),enfe-unhandled(total=394,non_allow=FsQueryTableObjDetails) … phase=realized
```

### 3.5 门禁四件（现取）

| 门 | 读数 | rc |
|---|---|---|
| `nm==exports` | `nm -D --defined-only` ＝ **683** ＝ `exports.txt` 行数；**逐名 `diff` 零差异** | 0 |
| `PTSGAP` | `PASS tool=76 dead=11 artifact=1 ops=64 impl=66 so16=1067da454b7ef114 exports=683` | 0 |
| `DEFREG` | `PASS declared=225 route_ids=225`（`DECLDRIFT=1 keys=KD`：复述位件已随动，**`tools/**` 属黑名单 ⇒ 不重发 `declared.tsv`**，如实记） | 0 |
| `REPORTID` | `PASS files=330 ids=2238 declared=225`（本件**落盘前** 329 ⇒ 落盘后 330，`+1` 即本件） | 0 |

---

## §4 逐件 `sha16`（现取）

| 件 | 改前 | 改后 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `4cff4a6d44934757` | **`4d0767892092cb55`** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `1dbea9026dd7d3d7`（430… B） | **`1067da454b7ef114`**（457840 B） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `860a3abe4a64f1c5` | **`860a3abe4a64f1c5`（未变）** |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `f8bc1b7ab62efe36` | **`f62bce16f135c244`** |
| `build/PresentationFramework.Linux/reapply-patches.py`（生成器） | `b6a3a24137a77ddf` | **未变** |
| `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `1c6c58df6d757f3f` | **未变** |

---

## §5 诚实边界（防读宽，逐条）

1. **判据 ① 未达** —— `LightGoldenrodYellow` 仍 `0 px`（`PTS_COLORANCHOR=PASS hits=2`，与改前同）。本趟**没有**产出该色。
2. **不回归是缺省关换来的**，不是"驱动无害"：gate-on 腿整页空白（§3.2/§3.3）；⇒ 闸**只许**在 `Table` 族落地后翻缺省（`T-A28→T-A31` 同体例）。
3. **"Floater 内容真造出"只证"内容子页已建"** —— **不**证"内容绘出"（gate-on 腿四色全 0）；也**不**替代 `N1`／`N3`（`pts-pages-guard.sh` 的口径句）。
4. **未驱动 Bottomless 支**：`pfnFormatFloaterContentBottomless`（槽 2）**未发调** —— 本页在屏走**有限窗**（`T-A45` 的 `WPF_LINEVIS_ONSCREEN`），其内 `<Floater>` 恒为 Floater（只有**非有限页**才把 `<Figure>` 改判成 Floater）；且该支还需 `FsCreateSubpageBottomless`（**未导出**）⇒ 同属下一增量。槽 2 指针已**捕获在案**（`[FSFLOATER-CBK] … fmtBottomless=0x…`），不冒充"已驱动"。
5. **`GetFloaterHandlerInfo` 的真实现只在 gate-on 路径被调**（缺省路径托管不会主动索 handler）⇒ 缺省路径**逐格未变**（§3.1/§3.2）。
6. **`DEFREG_DECLDRIFT=1`** 如实记：复述位件（`KNOWN-DEFECTS.md`＝键 `KD`）已随动，而 `declared.tsv` 的 `--emit` 落在黑名单 `build/MilBridge/tools/**` ⇒ 本趟**不重发**（`DEFREG=PASS` 不受影响）。

---

## §6 遗留（下一增量 `NATIVE-PTS-TABLEOBJ` 的射程）

- **五入口 ＋ 一表**：`FsQueryTableObjDetails`（`Pts.cs:3815`）／`FsQueryTableObjTableProperDetails`（`:3823`）／`FsQueryTableObjRowList`（`:3829`）／`FsQueryTableObjRowDetails`（`:3837`）／`FsQueryTableObjCellList`（`:3843`）＋ `GetTableObjHandlerInfo`（`:3071`，现取仍是具名 GAP）／`FSTABLEOBJCBK`（`:1828`）。
- **前置**：`TableParagraph` 的**内容对象模型**（行／单元 ＋ 各自内容子页）—— 与 `T-A36/T-A37` 对 `Figure`/`Floater` 的路径同形，但需先在窗内**建表对象并格式化**。⚠️ **现取（本席，gate-on 腿）**：`Floater` 内容子页只有 **1 个**子对象（`[SUBPAGE] … seg=0x1c w=77120 h=21620 cParas=1 cont_children=1 cont_client=0x1e`）⇒ **行／单元在内容树里不可枚举**（`+136`/`+144` 只到 Table 段落这一层）⇒ 表模型**不能**只靠既有内容树拼出来，必须走 `FSTABLEOBJCBK` 的真表格排版（这就是它**不是**一次"照抄 `T-A37`"的原因）。
- **翻转条件**：`NATIVE-PTS-TABLEOBJ` 落地且 `entry point named` 归 0 ⇒ 才准把 `WPF_PTS_FLOATER_CBK` 缺省翻 `1`（届时按 `T-A31` 体例改缺省常量并给成对腿）。

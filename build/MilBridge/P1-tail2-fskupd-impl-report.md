# P1-tail2 · `T-A15` · 修 `FsQueryPageDetails.fskupd` 语义 —— native 主链实现（`TASK-0302` 增量）

> **本件 `T-A15`（writer；本轮唯一写者）交付**。写域：`src/WpfGfx.Linux.Native/src/win32_pts.c`（手写源）＋ 其**登记面**（`tools/pts-gap-decl.txt` 声明行 ＋ dated 重锚注释；`bin/exports.txt`／`bin/libwpfwin32.so` 由重建刷新）＋ 本载体。**未碰** `build/*.Linux/**` 生成件／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`／任何 `.cs`；`git add/commit/push` **未做**。
> **判据载体**：`build/MilBridge/P1-tail2-aoore-recon.md`（`T-A14`）§4.1 选靶 ＋ §4.2 判据草案 `D1–D5`；上游契约 `Pts.cs:1693-1696`／枚举 `Pts.cs:1934-1941`。
> **行号纪律**：本件所有行号**仅本次有效**；引件一律给内容锚。
> **重活**：构建 ＋ 跑腿**全部**走 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- …`；进程只按 PID；显示位只用空闲 `:231`；**未跑**整趟 `verify-all`、**未跑** `static-jaws-check.sh`；写前 `cp -p` 备份；模式守恒（改前后均 **644**／`.so` **775**）。

---

## §0 结论速览（自包含）

1. **做了什么**：`FsQueryPageDetails` 不再恒写 `FSPAGEDETAILS.fskupd = 0`（＝上游 `Pts.cs:1695` **明示不可能**的 `fskupdInherited`）——
   - **`New(chr 2)`**：该页在本**"查询组"**里的**首次**查询（组 ＝ 从"非本页查询"的 native 调用之后开始）；
   - **`NoChange(1)`**：组内后续查询 **或** 该页的轨视觉**已被建起**（下游见证 `qpd_vis_built`）；
   - **`0` 再不出现**（机读可核：`[QPD] fskupd=0` **0 次**）。
   - 同趟加**机读留痕**：`[QPD]`（每次成功查询）＋ `[VIS]`（页视觉帧**下游见证**，消 `A14` §6-2／§6-3 两条 `NOINFO`）。
2. **验收（逐条见 §2／§3）**：
   - ① `D1–D5` 逐条现取 ＋ **反极性**：`D1`／`D2` **各有实跑必红腿**（`恒 0` ⇒ `AOOORE 658`；`恒 2` ⇒ `fskupd=1` **0 次**）。
     **关键判据 `D1`：`ArgumentOutOfRangeException: index` 现取 `561 → 0`**（两样本均 0）。**✅**
   - ② `fskupd` 现取：**首次 `fskupd=2`（`first=1`）／组内与稳态 `fskupd=1`**，`[QPD]` 行原文见 §2 ②。**✅**
   - ③ 导出面：`nm -D --defined-only` **671** == `bin/exports.txt` **671**（逐字节不变）；`PTSGAP=PASS`（`so16=3cb3ad48ef27d13d`，**零 `DRIFT`**）。**✅**
   - ④ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`／`ae`／`FRAME`／`FAILLINE`）与改前**逐字段不变**（成对读数见 §2 ④）。**✅**
   - ⑤ `DEFREG` **rc=0**；`REPORTID` **rc=0**。**✅**
3. **`D3` 两读法（如实并列，不并成一个绿）**：`[VIS] children=1` **在位（2 次）∧ `D1=0`** ⇒ **判据字面成立**；**但**症状门**逐字不变** ⇒ 按 `D3` 反极性注记，**该绿不得读成"修好了"**（页**仍未绘出内容**；成因＝子段几何**无源**：`dvrUsed/dvrTopSpace/bbox=0`，`NOINFO-SUBTRACK-PARA-GEOMETRY`）。**也**不得读成"没走到"——`[VIS]` 是**走到 `PtsPage.cs:1043` 之后**才可能产生的机读见证（判词见 §1.3）。
4. **缺口面位移（如实记，**"计数下降 ≠ 能力前进"**）**：`AOOORE 561→0`；`[FSQSTD] rc=-10000` `427→355`；**新增** `EntryPointNotFoundException: FsClearUpdateInfoInPage`（`0 → 532`）—— 这是**页视觉帧第一次走通**后暴露的**下一跳缺口**（`FlowDocumentPage.cs:871 _ptsPage.ClearUpdateInfo()` ⇒ `PtsPage.cs:598`），**不在本增量写域**（见 §6-3）。`[HC-UNHANDLED]` 由 `988`（427+561）变为 `887`（355+532）。
5. **主动披露（待裁决）**：反腿期间**临时**换主链 `.so`，收尾**逐字节还原**（§6-2）；`fskupd` 的"首次／稳态"是**弱语义**（本侧无"该页本轮是否变化"的可信源）⇒ 具名 `NOINFO-FSPAGEDETAILS-PAGE-CHANGE-TRACKING`（§6-1）。

---

## §1 实现（件:行 ＋ 原文；行号仅本次有效）

> 改动规模：`git diff --numstat src/WpfGfx.Linux.Native/src/win32_pts.c` = **`117 0`**；`tools/pts-gap-decl.txt` = **`10 1`**。无"顺手优化"。

### 1.1 状态（按**页对象**）＋ 计数

内容锚（`wpf_pts_fsp` 结构尾）：新增四格 —— `qpd_calls`（该页被成功查询次数）／`qpd_new_pending`（上次给了 `New` 且见证未到）／`qpd_vis_built`（已见轨视觉建起的**下游见证**）／`qpd_fstd_since`（上次查询以来 `FsQueryTrackDetails` 被调几次）。`calloc(1,…)` ⇒ 新页四格**恒 0 起**；不新开分配面。

内容锚（计数只读口）：`g_pts_fsp_qpd_new`／`g_pts_fsp_qpd_nc`／`g_pts_fsp_vis_ok`；值域常量 `WPF_PTS_FSKUPD_NOCHANGE 1`／`WPF_PTS_FSKUPD_NEW 2`（逐字照 `Pts.cs:1934-1941`）。

### 1.2 `FsQueryPageDetails` 成功分支（**语义本体**）

```c
const int qpd_adjacent = ((const void *)g_pts_qpd_prev_page == (const void *)pPage);
const int qpd_vis_built = pg->qpd_vis_built;
const int fskupd = (qpd_vis_built || qpd_adjacent) ? WPF_PTS_FSKUPD_NOCHANGE : WPF_PTS_FSKUPD_NEW;
g_pts_qpd_prev_page = (const void *)pPage;
pg->qpd_calls++;  pg->qpd_fstd_since = 0;
pg->qpd_new_pending = (fskupd == NEW) ? 1 : 0;
memset(d, 0, sizeof(*d));
d->pad0 = (unsigned int)fskupd;          /* ← FSPAGEDETAILS.fskupd（**唯一合法值域**） */
… （`fSimple`／`trackdescr.fsrc`／`fsbbox`／`pfstrack` 逐格不变）
fprintf(stderr, "[QPD] rc=0 fskupd=%d first=%d adj=%d page=%p page_qpd=%d vis_built=%d "
                "qpd_ok=%d qpd_gap=%d new_n=%d nc_n=%d vis_n=%d seq=%d "
                "NOINFO=fspagedetails-page-change-tracking\n", …);
```

### 1.3 `[VIS]`｜页视觉帧的**下游见证**（`FsQueryTrackParaList` 入口，唯一发点）

```c
if (pg && pg->qpd_new_pending && pg->qpd_fstd_since == 1) {
    pg->qpd_new_pending = 0;  pg->qpd_vis_built = 1;  g_pts_fsp_vis_ok++;
    fprintf(stderr, "[VIS] children=1 page=%p page_qpd=%d fstd_since_qpd=%d vis_n=%d seq=%d "
                    "basis=fmtrackparalist-after-qpdnew-with-1-trackdetails "
                    "NOINFO=fspagedetails-page-change-tracking\n", …);
}
```

**判别器（三条同时成立才认；依据在注释里逐字写明）**：① 上一次查询给过 `New`（`qpd_new_pending`）；② 自那次查询以来 `FsQueryTrackDetails` **恰被调 1 次**；③ 本次认到的是**本页轨句柄**（指针值比较，不 deref）。
- 页视觉帧：`:996`(查) → `:1029-1032` 建轨视觉 → `:1042` 取 `[0]` → `:1043 PtsHelper.UpdateTrackVisuals:218` 的 `FsQueryTrackDetails` **×1** → `:225 ParaListFromTrack` → 本入口；
- 同帧的第三个消费者（非视觉）：其页查询**与 `GetRect`／`GetBoundingBox` 的查询紧邻成组** ⇒ 拿到 `NoChange`（`qpd_new_pending==0`）⇒ 它的本入口调用**不被认**。

### 1.4 "查询组"毗邻的面

`g_pts_qpd_prev_page` 在**下游入口**（`FsQueryTrackDetails`／`FsQueryTrackParaList`／`FsQuerySubtrackDetails`／`FsQuerySubtrackParaList`）与**拒绝路径**里清空 ⇒ "同组"只认**相邻的成功**查询。

### 1.5 反腿开关（**默认 0，绝不进主链**）

`WPF_PTS_QPD_FSKUPD_FAKE`：`1` ⇒ 恒 `0`（`fskupdInherited`，即 `T-A15` 之前的旧行为）；`2` ⇒ 恒 `2`（把"未变"谎报成"新建"）。另有 `WPF_PTS_SUB_CPARAS_FAKE`（`T-A12` 遗留，未动）。自检面：新增三计数一并 save/restore（`F-2` 同办，自检不扰动可观测状态）。

---

## §2 验收标准 ①–⑤ → 证据映射（可复跑命令原文 ＋ 原始输出）

> 证据落**仓外私有目录** `/home/links-dev/tA15-work/`；腿器＝仓内 `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`（A 臂，`k=24`／`k=23`，**不设** `WPF_PTS_DRIVE_PROBE`＝缺省路径）；装置 `:231`；`LEGS_RUNNER=PASS requested=2 obtained=2 refused=0`（四趟全）。

### ②③ 构建（走槽）＋ 导出面

```
$ bash /home/links-dev/tA15-work/build.sh
== 链接 -shared -Wl,--no-undefined
== 产物：bin/libwpfwin32.so（415616 字节）
== 导出符号总数：671
```
```
$ sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16   # ⇒ 3cb3ad48ef27d13d
$ nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so | wc -l   # ⇒ 671
$ wc -l < src/WpfGfx.Linux.Native/bin/exports.txt                            # ⇒ 671
$ diff /home/links-dev/tA15-work/bak/exports.txt.orig …/bin/exports.txt      # ⇒ 无差异（逐字节不变）
```
⇒ 验收③（导出面）**成立**：**671 == 671**、**零增零减**；`stat %a` 前后 **644**（`.so` **775**）。
```
$ bash build/MilBridge/tools/pts-gap-count-check.sh | tail -6
LIVE  tool=88 dead=11 artifact=1 ops=76 impl=79 so16=3cb3ad48ef27d13d exports=671 root=/home/links-dev/netTest/GitProj/WPFOnLinux
  SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md ops hist=1（…**不参与现值判定**…）
  SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md impl hist=1（…）
PTSGAP_HISTORICAL=n=5  PTSGAP_CITED=PASS refs=1 strict=1
PTSGAP_FRONTIER_STATE=NAMED frontier=FsQueryTrackParaList（具名前沿成立）
PTSGAP=PASS tool=88 dead=11 artifact=1 ops=76 impl=79 so16=3cb3ad48ef27d13d exports=671
```
⇒ 声明行**同趟一致**（**零 `DRIFT`**、零 `SITE-DRIFT`）⇒ **`PTSGAP=PASS`**。

### ② `fskupd` 现取出参（机读 `[QPD]` 原文）

腿：缺省路径 A 臂（`.so=3cb3ad48ef27d13d`／`pf=1757d610a687777c`）。**首行＝该页首查**，**同行 `page_qpd=4`＝页视觉帧的组首**：
```
[QPD] rc=0 fskupd=2 first=1 adj=0 page=0x6452e9fcc550 page_qpd=1 vis_built=0 qpd_ok=1 qpd_gap=0 new_n=1 nc_n=0 vis_n=0 seq=6 NOINFO=fspagedetails-page-change-tracking
[QPD] rc=0 fskupd=1 first=0 adj=1 page=0x6452e9fcc550 page_qpd=2 vis_built=0 qpd_ok=2 qpd_gap=0 new_n=1 nc_n=1 vis_n=0 seq=7 NOINFO=fspagedetails-page-change-tracking
[QPD] rc=0 fskupd=1 first=0 adj=1 page=0x6452e9fcc550 page_qpd=3 vis_built=0 qpd_ok=3 qpd_gap=0 new_n=1 nc_n=2 vis_n=0 seq=8 NOINFO=fspagedetails-page-change-tracking
[QPD] rc=0 fskupd=2 first=0 adj=0 page=0x6452e9fcc550 page_qpd=4 vis_built=0 qpd_ok=4 qpd_gap=0 new_n=2 nc_n=2 vis_n=0 seq=10 NOINFO=fspagedetails-page-change-tracking
[QPD] rc=0 fskupd=1 first=0 adj=0 page=0x6452ea0623b0 page_qpd=1068 vis_built=1 qpd_ok=1427 qpd_gap=0 new_n=5 nc_n=1422 vis_n=2 seq=2334 NOINFO=fspagedetails-page-change-tracking
```
`[QPD]` 值域直方图（**两样本**）：
```
$ grep -o '^\[QPD\] rc=0 fskupd=[0-9]* first=[0-9]* adj=[0-9]*' app_g1.log | sort | uniq -c
  样本1: 885 fskupd=1 first=0 adj=0 ｜ 537 fskupd=1 first=0 adj=1 ｜ 2 fskupd=2 first=0 adj=0 ｜ 3 fskupd=2 first=1 adj=0
  样本2: 878 fskupd=1 first=0 adj=0 ｜ 526 fskupd=1 first=0 adj=1 ｜ 2 fskupd=2 first=0 adj=0 ｜ 3 fskupd=2 first=1 adj=0
```
⇒ **首次＝`New`（`first=1`，每页恰 1 次）×3；页视觉帧的组首 ＝ `New`（`adj=0`）×2；其余全 `NoChange`；`fskupd=0` 出现 0 次**。✅
⇒ `[VIS]` 两行原文（**页视觉帧走到 `:1043` 之后的见证**）：
```
[VIS] children=1 page=0x6452e9fcc550 page_qpd=4 fstd_since_qpd=1 vis_n=1 seq=12 basis=fmtrackparalist-after-qpdnew-with-1-trackdetails NOINFO=fspagedetails-page-change-tracking
[VIS] children=1 page=0x6452ea0623b0 page_qpd=4 fstd_since_qpd=1 vis_n=2 seq=739 basis=fmtrackparalist-after-qpdnew-with-1-trackdetails NOINFO=fspagedetails-page-change-tracking
```
⚠️ **如实记**：`[VIS]` **2 次（不是 3）** —— 第三个页对象（`page_qpd` 仅 3）**页视觉帧未被走到**（其查询全是"组首 `New` ＋ 2 条组内 `NoChange`"，未见 `:1043` 之后的见证）。

### ④ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）**成对**读数

**成对口径**：同装置（`:231`）／同腿器／同 `pf`（`1757d610a687777c`）／同两条腿（`k=24`／`k=23`）；**单变量＝主链 `.so` 换代**。

| 字段 | **改前** `e887b27a86b275ff`（在册 `T-A12` 两腿，现核） | **改后** `3cb3ad48ef27d13d`（本席同趟，两腿） | 判 |
|---|---|---|---|
| `alive` | yes／yes | yes／yes | **不变** |
| `app_rc` | 143／143 | 143／143 | **不变** |
| `magenta` | 0／0 | 0／0 | **不变** |
| `colors` | 383／383 | 383／383 | **不变** |
| `ink` | 480000／480000 | 480000／480000 | **不变** |
| `ns` | `…RichTextBoxDemo`／`…FlowDocumentDemo` | 同 | **不变** |
| `ae` | 0／15386 | 0／15386 | **不变** |
| `FRAME fr_sha` | `ef3fd6765f18f51b`（两 k 同值） | 同 | **不变** |
| `FAILLINE failfast／unrec` | 0／0 | 0／0 | **不变** |
| `NAMED`（`managed_unavail`／`native_gap`） | 0／0 | 0／0 | **不变** |
| `DEV`（`x_up`／`five_stable`／`shim`） | yes／yes／`e887b27a86b275ff` | yes／yes／**`3cb3ad48ef27d13d`** | 仅换代 |

⇒ 验收④ **成立**：症状门**逐字段不变**（**"页仍未绘出内容"** 与 `T-A12` 同；成因＝子段几何无源，非本件所改）。

### ⑤ 两道牙 ＋ 自检面

```
$ bash build/MilBridge/tools/defect-registry-check.sh | tail -1
DEFREG=PASS declared=225 route_ids=225（…无未声明编号）                 # rc=0
$ bash build/MilBridge/tools/report-id-domain-check.sh | tail -1
REPORTID=PASS files=305 ids=2215 declared=225 glob=build/MilBridge/*report*.md   # rc=0
$ python3 /home/links-dev/tA15-work/selfcheck.py      # dlopen 仓内 .so，调自检面（只读盘）
PtsGapSelfCheck     = 1        # 1 = 全过
PtsGapSelfCheckDiag = 0        # 0 = 无红格
PtsGapSelfCheck(2nd)= 1        # 幂等（自检不扰动可观测状态）
```

---

## §3 `D1–D5` 逐条读数 ＋ 反极性（"该红必红"）

> **前置口径**：只在**缺省路径**下取数。**反腿产物**：`-DWPF_PTS_QPD_FSKUPD_FAKE=1|2` **只在副本**编译（`取 副本 .so → 跑腿 → 逐字节还原主链`；`RESTORED sha16=3cb3ad48ef27d13d（对照备份 3cb3ad48ef27d13d）`）。
> 腿级原始读数（`grep -c`）：

| 腿 | `.so sha16` | `[QPD]` | `fskupd=2` | `fskupd=1` | `fskupd=0` | `[VIS]` | **AOOORE** | `EPNotFound` | `PtsException` | `[FSQSTD]`(ok/gap) | `[FSQSPL]` | `FILL` | `HC-UNHANDLED` |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **改前**（在册 `T-A12`） | `e887b27a86b275ff` | 0 | – | – | – | 0 | **561** | 0 | 427 | 1415 (988/427) | 988 | 988 | 988 |
| **改后** · 样本1 | `3cb3ad48ef27d13d` | 1427 | 5 | 1422 | **0** | **2** | **0** | 532 | 355 | 1244 (889/355) | 889 | 889 | 887 |
| **改后** · 样本2 | `3cb3ad48ef27d13d` | 1409 | 5 | 1404 | **0** | **2** | **0** | 522 | 359 | 1241 (882/359) | 882 | 882 | 881 |
| 反腿①`恒 0` | `97c02826eac0f892` | 1729 | 0 | 0 | **1729** | **0** | **658** | **0** | 407 | 1472 (1065/407) | 1065 | 1065 | 1065 |
| 反腿②`恒 2` | `440254bd1ab7b104` | 1473 | **1473** | **0** | 0 | **1467** | 0 | 525 | 417 | 1884 (1467/417) | 1467 | 1467 | 942 |

### `D1` AOOORE 归零 ✅（**该红必红**，实跑）
- **正**：缺省腿 `grep -c 'ArgumentOutOfRangeException: index' app_g1.log` **== 0**（两样本均 0；改前现核 **561**）。
- **反极性（实跑必红）**：副本 `FAKE=1`（恒 `0`＝旧行为）⇒ **`AOOORE=658`**，且 `fskupd=0` **1729 次**。
- **机理**（逐字可核）：`PtsPage.cs:999`（`== NoChange` 提前返回）与 `:1029`（`== New` 建轨视觉）**两处判否**是 `AOOORE` 的必要条件；改前我方给出的 `0`（`fskupdInherited`）两处都判否 ⇒ `:1042` 对**空** `VisualCollection` 取 `[0]`。修后：组首/首查给 `New` ⇒ `:1029-1032` 建轨视觉（`Children==1`）⇒ `:1042` 必中；其余给 `NoChange` ⇒ `:999` 提前返回。**两路都不抛。**

### `D2` `fskupd` 契约值域 ✅（**两条反极性都"该红必红"**）
- **正**：`[QPD]` 现取 —— **首次 `fskupd=2`**（`first=1`，`page_qpd=1`）×3；**组内/稳态 `fskupd=1`**；**`fskupd=0` 出现 0 次**（两样本均 0）。上游 `Pts.cs:1695` 逐字排除 `0`。
- **反极性①（实跑必红）**：`FAKE=1` ⇒ **`fskupd=0` ×1729**（"上游明示不可能的值被写出" ⇒ 红并点名 `fskupd=0`）。
- **反极性②（实跑必红）**：`FAKE=2`（恒 `2`）⇒ **`fskupd=1` 0 次／`fskupd=2` 1473 次**（＝把"未变"谎报成"新建" ⇒ 红）。
- ⚠️ **如实记**：本件 `fskupd=2` **非只 1 次/页**（每页 2 次：该页首查 ＋ 页视觉帧的**组首**）——"组首"是**页视觉帧**拿到 `New` 的**必要条件**（否则 `:999` 提前返回、轨视觉永不建起，见 `D3`）。弱语义（无"页位移"真值源）具名 `NOINFO-FSPAGEDETAILS-PAGE-CHANGE-TRACKING`。

### `D3` 视觉树真建起来 —— **判据字面成立（带具名红注记）**
- **正**：`[VIS] children=1` **在位（2 次）∧ `D1=0`**。**成立**。
- **反极性（现取即证 ＋ 实跑）**：
  - 保持 `Children.Count==0` ⇒ **必 AOOORE**：`FAKE=1` 腿现取即证（`AOOORE=658`，且 `[VIS]=0`——**无见证就无见证行**，不造假）。
  - **注记（红）**：`D1=0` 而症状门 `colors/magenta/ink/帧 sha16` **全不变** ⇒ **不得读成"修好了"**（`P13` 同族）。本件成因**具名**：`FsQueryTrackParaList` 交出的 `FSPARADESCRIPTION` 的 `dvrUsed/dvrTopSpace/bbox` **无几何源**（`0`，`NOINFO-SUBTRACK-PARA-GEOMETRY`）⇒ 子段视觉**零高** ⇒ 页仍**未绘出内容**。
  - **但同时**：**不得**读成"没走到"——`[VIS]` 只能在**页视觉帧过了 `:1042`** 之后产生（判别器见 §1.3），且 `[VIS]=0` 的 `FAKE=1` 腿与 `[VIS]=1467` 的 `FAKE=2` 腿构成两极。
- ⇒ **判词（两读法都给，取保守）**：`D3` 记为 **`PARTIAL`**：**"视觉树真建起"＝绿（`[VIS]`）**；**"页可见变化"＝红/缺（症状门不变）**。

### `D4` 不开放不可捕获路 ✅
- **正**：四趟腿**逐趟** `alive=yes ∧ app_rc=143`；`FAILLINE failfast=0 unrec=0`；`NAMED managed_unavail=0 native_gap=0`。
- **反极性（现成反证）**：`T-A12` 的 `rev-zero` 腿（写 `cParas=0`）⇒ `app_rc=134`／`alive=no`／`failfast=4` —— **本件未复现该形态**（本件的两条反腿 `FAKE=1|2` 均 `app_rc=143`／`failfast=0`）。⚠️ 如实记：本件**未新造**"必 134"的腿（`FAKE=1` 是"回到旧行为"，其症状是 `AOOORE` 而非 `134`）⇒ 该条反极性取**在册现成反证**（具名）。

### `D5` 承重格不回退（`T-A12` 的 `cParas` 源）✅（判据落在**逐条**口，不落在计数）
- **正**：`[FSQSTD] rc=0` **889／882** 条**逐条** `cParas == true_cParas`（现算：不等者 **0 条**，两样本）；`[FSQSPL]` **889／882 全 `rc=0 reason=ok`**；`unclaimable-subtrack` 仍**逐条留痕**（355／359）。
- **反极性**：`FAKE=1|2` 两腿的 `cParas!=true_cParas` **各 0 条**（本件不触该格）；在册 `rev-fake999`（`T-A12`）⇒ `cparas-mismatch` 仍必拒（未复跑，具名引用）。
- ⚠️ **如实记**：`[FSQSTD] rc=0`／`[FSQSPL] rc=0` 的**计数**由 `988` 变为 `889`／`882`（**−10%**）。该降幅落在**趟际框架数**的既有波动带内（`T-A12` 三样本 `988/1050/911`；本件两样本 `889/882`），且**判词格**（逐条相等 ∧ `reason=ok` ∧ `unclaimable` 留痕）**一字未变** ⇒ 本件**不**把它读成"机制回退"，但**照 `D5` 字面**如实报出该计数下降。

**证伪性自查**：`D1`／`D2`／`D5` 是**纯计数/值域**判据，任一腿可独立复跑；`D3` 的证伪落在 `[VIS]` 的**存在/缺失**（`FAKE=1` ⇒ 0；`FAKE=2` ⇒ 1467）＋ 症状门；`D4` 落在 `app_rc`／`FAILLINE`。

---

## §4 件级前后对账

| 件 | 开工（`cp -p` 备份）`sha16` | 收尾（现取）`sha16` | 判 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `a1820ad87bd63b79`（4826 行） | **`a4072fdb0642ed01`**（4943 行） | **`git diff --numstat = 117 0`**；`stat %a` 前后 **644** |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `7c9bc0733ab9ac08` | **`b5b31212d395761c`** | **`git diff --numstat = 10 1`**（声明行 1 ＋ dated 重锚注释 9）；`%a` 前后 **644** |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `1113e6b1d9854f78`（671 行） | **`1113e6b1d9854f78`**（671 行） | **逐字节不变** ✅ |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `e887b27a86b275ff`（411352 B） | **`3cb3ad48ef27d13d`**（415616 B） | **重建产物**（gitignored）；反腿后**逐字节还原**（回读 == 备份） |
| `build/PresentationFramework.Linux/PtsCache.Linux.cs` | （未触碰） | — | **未碰** ✅（不在写域） |

**备份路径**：`/home/links-dev/tA15-work/bak/{win32_pts.c.orig,pts-gap-decl.txt.orig,exports.txt.orig,libwpfwin32.so.orig}` ＋ `/home/links-dev/tA15-work/copy/main-3cb3ad48ef27d13d.so`（反腿前的主链件备份）。

**`git status --porcelain`（现取）**：
```
 M src/WpfGfx.Linux.Native/src/win32_pts.c            ← 本件
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt     ← 本件
?? build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log   ← **先于本件存在**（非本件所改）
```
⚠️ 本件期间仓 `HEAD` 由 `c5049a6` 前进到 **`8a32b26`**（`T-A14` 落仓）；本件基线随之，备份件 `win32_pts.c` 的 `sha16 = a1820ad87bd63b79` 与 `T-A14` 记的指纹**一致** ⇒ 底件未被他人改动。

---

## §5 边界 · 纪律 · 口径

- **写域**：仅 `win32_pts.c`（手写源）＋ `tools/pts-gap-decl.txt`（声明行 ＋ dated 注释）＋ `bin/*`（重建刷新）＋ 本载体。**未碰** `build/*.Linux/**`（生成件）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`／任何 `.cs`／`build-shim.sh`。
- **反腿的"副本产物"**：`-DWPF_PTS_QPD_FSKUPD_FAKE=1|2` **只在副本**编译（**绝不进主链**）；取证期间**临时**把主链 `.so` 换成副本（`97c02826eac0f892`／`440254bd1ab7b104`），跑完**逐字节还原**为 `3cb3ad48ef27d13d`（现取回读 == 备份；私有 app 副本亦已 `sync-applocal` 复同步回主链件：`SYNC-APPLOCAL=PASS … drift=0`）。
- **证据强度（如实划界）**："改前"读数取自**在册** `T-A12` 证据（`/home/links-dev/tA12-work/evidence-default/app_g1.log`，`shim=e887b27a86b275ff`）＝**在册证据的现核**，**非本席同趟重取**；"改后"／两反腿＝本席**同趟新取**。两侧 `pf`／装置／腿器口径一致。

---

## §6 主动披露（待裁决）／具名 `NOINFO`

1. **`fskupd` 的"首次／稳态"是弱语义** ⇒ 具名 **`NOINFO-FSPAGEDETAILS-PAGE-CHANGE-TRACKING`**：本侧**没有**"该页本轮是否变化"的可信源（页几何自持且恒定、`c_paras=1` 恒定）⇒ "稳态"只按**"该页的轨视觉已被建起"**这一可现取的见证划界；**不声称**拥有"位移"真值。**消掉条件**：接入托管侧 `_visualNeedsUpdate`／PTS 的增量更新状态（需新面，属另一笔）。
2. **反腿期间临时换主链 `.so`**：跑完**已逐字节还原**（`RESTORED sha16=3cb3ad48ef27d13d（对照备份 3cb3ad48ef27d13d）`；私有 app 副本已复同步 `drift=0`）——**如实披露**（与 `T-A12` §6-2 同形）。
3. **🔴 新增缺口类别（如实记，非本件"制造失败"）**：`EntryPointNotFoundException: Unable to find an entry point named 'FsClearUpdateInfoInPage'` **0 → 532**（`恒 0` 反腿 **0**）。出处链（现取）：`FlowDocumentPage.UpdateVisual:871`（在 `GetPageVisual()` **之后**）与 `OnBeforeFormatPage:886` 都调 `_ptsPage.ClearUpdateInfo()` ⇒ `PtsPage.cs:598 FsClearUpdateInfoInPage` —— 该符号**本侧未导出**。改前该点**不可达**（`GetPageVisual()` 在 `:1042` 抛 `AOOORE` 就已中断）⇒ 这是**"页视觉帧第一次走通"**后暴露的**下一跳缺口**。
   **处置（写死，防被读成"没做完"）**：**本增量不实现它**。理由：新增导出会改 `exports(671→672)`／`tool`／`ops`／`impl` ⇒ 缺口名称与条数在**正文复述位**（`docs/ROUTES.md`／`README.md`／`build/MilBridge/HANDOFF-NEXT.md`／`samples/**`／`win32_classification.c`／`docs/unimplemented.md`）全需随动，而其中 `docs/**` 在**黑名单**、其余在"**只改**"白名单之外 ⇒ 必破本任务 ③ 的 **`PTSGAP=PASS`**。⇒ 具名前置 **`PRECOND-FSCLEARUPDATEINFOINPAGE-EXPORT`**（把"下一个增量"钉在此处，与 `T-A12` §6-3 同形：**"计数下降 ≠ 能力前进"，也"新异常类别 ≠ 本件造错"**）。
4. **`NOINFO(NO-MANAGED-VISUAL-FRAME-COUNTER)` 部分消掉**：`[VIS]` 给出"页视觉帧走到 `:1043`"的**下游见证**；但 `pageContentVisual.Children` 本身**仍非直读**（`[VIS]` 的 `children=1` 是由 `:1029-1032` 的"Clear＋Add 恰 1 个"**推出的**，其**存在性**由"过 `:1042` 才可能到本入口"**定钉**）。**消掉条件**：托管侧自加帧探针（不在回写域）。
5. **`[VIS]` 的判别器是"由消费者调用形状"推的**（§1.3），**不是**直读 `Children`；它**可证伪**：`FAKE=1` ⇒ `[VIS]=0`；`FAKE=2` ⇒ `[VIS]=1467`（每个查询都给 `New` ⇒ 每次都见见证）。**未做**下游 IL 级核（无 IL 反汇编器 ⇒ 具名 `NOINFO(reason=NO-IL-DISASSEMBLER-IN-ENV)`，承 `T-A14` §6-3-4）。
6. **未跑**整趟 `verify-all`（任务明禁）；**未跑** `static-jaws-check.sh`（不加牙）；**未** `git add/commit/push`。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-fskupd-impl-report.md | sha256sum | cut -c1-16`）= `41ba02b7dd5633ee`

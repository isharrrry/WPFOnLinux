# P1-tail2 `TASK-0302` 增量 · 下一跳选靶 —— 只读侦察 ＋ 判据先写

- **读时**：`2026-09-30T11:49+0800`（本席现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=0aab811`（现取；`P1 尾波2 (#82)：TASK-0302 增量落地——FsQuerySubtrackDetails 诚实拒绝导出 + 复述位随动`）。
- **现件代**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`a1403ea71c2bf487`**（现取）。
- **件指纹（现取，`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`＝`e0b5a3a4a21e2275`（4590 行）｜`bin/exports.txt`＝`f61b9b1e55fdc600`（670 行）｜`tools/pts-gap-decl.txt`＝`32b303148aca23a9`｜`PtsHelper.cs`＝`f2ed9552e983fed1`｜`ContainerParaClient.cs`＝`0d2e6aa79fdc035a`｜`Pts.cs`＝`1a8575a18767a956`｜`build/MilBridge/P1-tail2-fsqsub-impl-report.md`＝`28873cd8228d7f46`。
- **边界（照 T-A6 ②）**：只读；除本件外**未改任何仓内文件**；**未改 `src/**`、未构建、未跑整趟 `verify-all`、未跑 `static-jaws-check.sh`**；进程只按 PID；显示位只用空闲 `:231`（规范腿器自配、非手占）；大件只用 `wc/head/tail/grep`；未 `git add/commit/push`。
- **行号纪律**：本件所有行号**仅本次有效**（内容锚原文一并给出，供下一位现取复核）。

---

## §0 结论速览（自包含）

1. **现件代应用前沿（现取）**：本席**新跑一趟短腿**（规范腿器 A 臂 `k=24/k=23`，**缺省路径**；`LEGS_RUNNER=PASS`）⇒ 缺省路径下**唯一**被撞的 PTS 缺口入口 ＝ **`FsQueryTrackParaList`（1054 次）**；`ENFE=0`（`PTS_ENFE=INFO total=0`）；`[PTS-UNAVAILABLE]`＝0；`[FSQSTD]`＝0；`PTS_GAP`（旧格式）＝0。
2. **候选判定**：`FsQueryTrackParaList` **入参有源**、**出参无源**（`pfsparaclient`／`nmp` 需**托管句柄表**索引；真填块整块在 `wpf_pts_drive_probe_enabled()` 内、缺省 `drive_nmp=NULL`）⇒ **只能诚实拒绝**（且它**已经是**诚实拒绝）⇒ **不满足②「依赖可得」**。
3. `FsQuerySubtrackDetails`（`T-A4` 已落地诚实拒绝）在**缺省路径不被撞**（`pfspara` 恒 0）⇒ **不满足①「应用真会撞到」**；其下游 `FsQuerySubtrackParaList` 被 `cParas` 门控 ⇒ **补它 ＝ 补死码**。
4. **选靶判定 ＝ 在当前写域内无有源可做项（合法终点）**；唯一候补（**仅在阻塞解除后**成立）＝ `FsQueryTrackParaList` 缺省路径真填，判据草案见 §3.2。
5. **具名阻塞前置清单**见 §5。

---

## §1 现件代应用前沿（按次数排序表）

### 1.1 现取方式（自证）

**新跑一趟短腿**（`bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- bash /home/links-dev/tA6-work/legs.sh`）→ 仓内规范腿器 `build/MilBridge/tests/PtsPagesProbe/run-pts-pages-legs.sh`（A 臂；私有 `W67_WORK=/home/links-dev/tA6-work`）：

```
AUTHORITY: shim=a1403ea71c2bf487 pf=1757d610a687777c ｜ APPDIR: shim=a1403ea71c2bf487 pf=1757d610a687777c
shim_sha16=a1403ea71c2bf487 pf_sha16=1757d610a687777c
CLICK k=24 alive=yes expect=FlowDocumentDemo AE=15386 pts_unavail=0 pts_gap=0 guard=183 fatal=0 unh=0 ns_last=…FlowDocumentDemo
CLICK k=23 alive=yes expect=RichTextBoxDemo  AE=0     pts_unavail=0 pts_gap=0 guard=800 fatal=0 unh=0 ns_last=…RichTextBoxDemo
POSTSHIM: shim=a1403ea71c2bf487 pf=1757d610a687777c（== authority ⇒ 读数可归因）
LEGSCOUNT requested=2 obtained=2 refused=0 reasons=none display=:231 rc=0 session_rc=0 conv_rc=0
LEGS_RUNNER=PASS requested=2 obtained=2 refused=0 display=:231
```

**证据件**（现取；落**仓外私有目录** `/home/links-dev/tA6-work/evidence/`，**不写仓内**）：`app_g1.log`＝`2cc957c72ea6f186`／**3870 行**｜`leg_24.env`＝`646684ebecbf79e1`｜`leg_23.env`＝`2750c417772459fb`｜`session.txt`＝`bd191fba4935d17b`。

### 1.2 缺口入口按次数排序（现取真腿日志）

| # | 入口 | 次数 | 出处行（现件代真腿，本席新跑；行号仅本次有效） |
|---|---|---|---|
| 1 | **`FsQueryTrackParaList`** | **1054** | `app_g1.log:820`（首）＝`[FS_PAGE_GAP] rc=-10000 reason=paraclient-table-not-native entry=FsQueryTrackParaList ctx=0x5fe7895b5f60 track=0x5fe78a56eb18 cParas=1 owned=1 ok=0 gap=1`；`:3869`（尾）＝同行但 `track=0x5fe789a5cff8 … gap=1054` |
| — | （`CreateDocContext`） | 3 | `app_g1.log:703/:840/:2149`＝`[FSCBK-SNAP] entry=CreateDocContext ctx=… bytes=824 words=103 nonzero=71 state=VALUE … taken=1/2/3 allzero=0 gap=0`（**非缺口**：`CreateDocContext` 是**真实现**入口的回调快照，`gap=0`） |

**同趟交叉（证实"真撞到"）**：
- `grep -c 'FS_PAGE_GAP' app_g1.log` ＝ **1054**；`gap` 最大序号 ＝ **1054**（与行数同）。
- `grep -c 'HC-UNHANDLED' app_g1.log` ＝ **1054**（托管侧 `PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'. ｜ 首帧 at …PTS.Error(Int32 fserr, PtsContext ptsContext)`，`app_g1.log:821` 首）。
- `grep -c 'entry=' app_g1.log` ＝ **1057** ＝ `FsQueryTrackParaList` 1054 ＋ `CreateDocContext` 3（**无第三个具名**）。
- **反面（防假绿）**：`[PTS-UNAVAILABLE]`＝**0**；`[FSQSTD]`＝**0**；`PTS_GAP`（旧格式 `^PTS_GAP entry=`）＝**0**；`ENFE`（`PTS_ENFE=INFO total=0`）＝**0**；`EntryPointNotFound`／`Unable to load DLL`＝0。
- **闸面**：`[DRIVE-PROBE-SKIP] reason=gate-off`＝3（`app_g1.log:819/:954/:2263`）⇒ 探针门**关**（**缺省路径**的现场印证）。

> **口径（写死）**：本节"缺口入口"＝**真腿日志里带具名 `entry=` 的拒绝台账行**（`[FS_PAGE_GAP]`）。**不**把"未被撞到的缺口"计入**前沿**（那是"缺口条数"，不是"前沿"；照 `pts-gap-count-check.sh` 件头第①条）。

**代际无关的交叉证**：另一份**非现件代**真腿日志（`build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log`，`shim=5ddc9d63b5232f96`）同面为 `[FS_PAGE_GAP]`＝**1117**／`entry=FsQueryTrackParaList`＝**1117** ⇒ 入口名**同**、仅计数随帧数漂移 ⇒ 与代际无关，**是一致的"应用前沿"**。

---

## §2 候选池 × 有源/无源判定（含现取证据）

> 候选池 ＝ 前沿①名 ＋ 其**门控下游** ＋ `T-A4` 已落地项 ＋ 未导出缺口池；逐条给现取证据。

| 候选 | 真腿被撞（现件代·缺省路径） | 入参有源？ | 出参有源？ | 判 |
|---|---|---|---|---|
| **`FsQueryTrackParaList`** | **1054**（§1.2） | **有**：`pfscontext`（在册 doc）／`pTrack`（`wpf_pts_track_owned` 可认领）／`cParas` | **无**：① `pfsparaclient` 被 `PtsHelper.cs:158/255/346/410/489/745` 拿去 `PtsContext.HandleToObject(...)`（＝**托管表 `_unmanagedHandles` 的索引**）；② `nmp` 同族；③ `dvrUsed`／`dvrTopSpace` 需 LM-1 段账；④ 真填块**整块**在 `wpf_pts_drive_probe_enabled()` 内，缺省 `drive_nmp=NULL` ⇒ `win32_pts.c:3639 reason=no-legal-nmp-in-this-run` ⇒ 落到 `:3920 reason=paraclient-table-not-native`（现场 `reason=` 逐字即此） | **只能诚实拒绝**（**且已是**：`win32_pts.c:3615-3618` 注释写死"返 0 就是假成功"） |
| `FsQuerySubtrackDetails`（`T-A4` 落地） | **0**（缺省；`pfspara` 恒 0）／1002（**探针**路径，`T-A4` 现取） | 有（`wpf_pts_sub_claim`） | 无（`cParas`／`nms`；`P1-tail2-fsqsub-recon.md` §3.3） | **`T-A4` 已落地诚实拒绝**；缺省路径**不进前沿** ⇒ **不满足①** |
| `FsQuerySubtrackParaList` | **0**（被 `FsQueryTrackParaList` 的 `cParas` 门控：`ContainerParaClient.cs:66/277`） | 有 | 无（`PRECOND-PARADESC-SOURCE-MISSING(scope=subtrack-path)`） | **补它 ＝ 补死码**（`P1-tail2-t0307-recon.md` §2.2） |
| 未导出缺口池（`D-G70`：`tool=89 dead=11 artifact=1 ops=77 impl=80`） | **0**（`ENFE=0`，`PTS_ENFE=INFO total=0`） | — | — | **不满足①**（应用**未撞**） |
| 其余已导出 PTS 入口（`CreateInstalledObjectsInfo`／`CreateDocContext`／`FsQueryTrackDetails`／`FsCreatePageFinite`／`LoCreateContext` 等） | 成功**不打点**（故不在 `entry=` 面） | — | 有（`FsQueryTrackDetails` 按对象回答 `c_paras`，`win32_pts.c:3527`；`FsCreatePageFinite` 造本侧页对象，`:3574`） | **已实现**，无增量可做 |

**关键判词**：候选池里**只有** `FsQueryTrackParaList` 满足①（**真会撞到**，1054 次现取）；但它的**出参无源** ⇒ **不满足②**；⇒ **无"有源可做项"**。

---

## §3 选靶 ＝ 合法终点 ＋ 判据草案

### 3.1 选靶判定（唯一结论）

**判定：在当前写域内无有源可做项 ⇒ 合法终点（不选靶、不落地）。**

据三条现取：

1. **唯一真撞项出参无源**（§2）：`FsQueryTrackParaList` 的 `pfsparaclient`／`nmp` 属**托管句柄表**（`HandleToObject` 索引），native **无合法来源**（写指针 ⇒ `Invariant.FailFast` 不可捕获；写 0 ⇒ 同族；写小整数 ⇒ 槽里非 `BaseParaClient` ⇒ `as` 得 null ⇒ NRE，**比 NULL 更危险** —— `win32_pts.c:3593-3598`）⇒ 返 0 ＝ **假成功**。
2. **唯一候补在上游门控下游**：`FsQuerySubtrackParaList` 被 `cParas` 门控，且其源 `arrayParaDesc` 无源（`S-2b`）⇒ 补它 ＝ **死码**；`FsQuerySubtrackDetails` 在缺省路径**不被撞**（**不满足①**）。
3. **不得把"再写一个拒绝 stub"当进展**（T-A6 ②）：候选池里的拒绝项（`FsQueryTrackParaList`／`FsQuerySubtrackDetails`／`FsQuerySubtrackParaList`）**要么已是诚实拒绝、要么是死码** ⇒ 再写一遍＝**零能力前进**。

### 3.2 判据草案（针对"唯一候补" —— **仅在阻塞解除后**照抄；本波**不实现**）

> **候选**：`FsQueryTrackParaList` **缺省路径真填**（当前恒 `reason=paraclient-table-not-native`）。
> **前置口径（写死）**：本候选**成立的前提**是 §5 的 `PRECOND-MANAGED-HANDLE-TABLE` 被解除（托管侧能给出**可经 `HandleToObject` 反查**的 `pfsparaclient` 与合法 `nmp`）。**未解除 ⇒ 本判据一律 `NOINFO`，不得判绿、不得据以返 0。**

| # | 判据（可证伪） | 反极性（必红腿） |
|---|---|---|
| **D1 零假值／出参纪律** | 拒绝路径 `rgParaDesc` **一字不写**、`*cParaDesc=0`（现状 `win32_pts.c:3608`）；真填路径**先 `memset` 清零再逐字段写**（`:3778`），未初始化内存**不许**交给上级。 | 为让 `rc=0` 好看而填**伪句柄**（`0x1000`／小整数／栈地址）⇒ 消费者 `HandleToObject` 撞 `Assert` ⇒ `FailFast`／NRE ⇒ **必红**。 |
| **D2 永不假成功** | `rc=0` **仅当**同时给出：可经 `HandleToObject` 反查为 `BaseParaClient` 的 `pfsparaclient` ∧ `nmp` 合法 ∧ `cParaDesc==cParas`。今天是**不满足** ⇒ **必须返非 0**。 | 返 `rc=0` ＋ 常量 `cParaDesc`／伪造句柄 ⇒ **伪成功** ⇒ **必红**（会让 `PtsHelper.cs:158` 静默取到错对象）。 |
| **D3 失败必留痕** | 任何拒绝**必**打具名 `[FS_PAGE_GAP] rc=<int> reason=<具名> entry=FsQueryTrackParaList ctx=… track=… cParas=… owned=… ok=… gap=…`，且 `gap` 恰涨 1。 | **静默 stub**（返非 0 零痕迹）⇒ 与"真 0 次"不可分 ⇒ **必红**（照裁定二十三 ①：留痕做在 native 侧）。 |
| **D4 身份只许靠来源证据** | `track`／`pfspara` 必须能被本侧台账**唯一认领**（`wpf_pts_track_owned`／`wpf_pts_sub_claim`），且与同 run 产出行**同值**。 | 靠 `rc`／数值大小判身份 ⇒ **必红**（`t160` ABA 反腿：`rc` 与数值都无法辨身份）。 |
| **D5 闸关与闸开分开报** | **缺省路径**（门关）与**探针路径**（门开）**分开判词**：门关恒 `reason=paraclient-table-not-native`；门开才可能 `[FSPARALIST-FILL] rc=0 reason=ok`。**不**把"闸开时可得"读成"缺省路径已可得"。 | 把探针路径的真填读成"产品路径已通" ⇒ **必红**（`P13` 反腿）。 |
| **D6 症状门不变** | 落地后症状门**逐字段不变**：`alive=yes`／`app_rc=143`／`magenta=0`／`colors=383`／`ink=480000`／`ns=…FlowDocumentDemo`（本席现取基线，§1.1）。 | 症状门任一字段漂移（如 `magenta` 抬头／`app_rc=134`）⇒ **必红**。 |
| **D7 ≥2 独立样本** | ≥2 独立 PID／启动时刻，判词**相同**（裁定三十八）。 | 单样本当机制 ⇒ **必红**（`P9`）。 |

---

## §4 上下游 ＋ "实现后可观察变化"

### 4.1 上下游（现取逐跳）

**track-path（唯一真撞链）**：
```
PtsHelper.cs:137 ArrangeParaList 消费
  → :134 ParaListFromTrack(ptsContext, trackDesc.pfstrack, ref trackDetails, out arrayParaDesc)
  → :614 PTS.Validate(PTS.FsQueryTrackParaList(ptsContext.Context, track, trackDetails.cParas, rgParaDesc, out paraCount))   ← 前沿入口
  → :158 BaseParaClient paraClient = ptsContext.HandleToObject(arrayParaDesc[index].pfsparaclient) as BaseParaClient            ← 消费者（出参 pfsparaclient 无源处）
  → :179 paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack)
```
- **谁调它**：`PtsHelper.ParaListFromTrack`（`PtsHelper.cs:604`）→ 宿主 `ArrangeParaList`（`:137`／`:225`／`:327`／`:387`／`:464`／`:739` 六个 body）。
- **被谁门控（上游）**：入参 `track` 来自 `trackDesc.pfstrack` ⇒ 上游是 **track 详情**链（`FsQueryTrackDetails`，**已真实现**，`win32_pts.c:3516-3539`）。
- **它门控谁（下游）**：其出参 `cParaDesc`／`arrayParaDesc` 门控 ① `ContainerParaClient`／`ListParaClient` 的 `pfsparaclient` 反查（`ContainerParaClient.cs:249/289/342/386`）与 ② `FsQuerySubtrackDetails` 的入参 `pSubTrack ← pfspara`（`FsQueryTrackParaList` 在 `win32_pts.c:3780` 填 `pfspara`）。
- **缺符号/缺实现面**：`FsQueryTrackParaList` **已导出**（`exports.txt:107`／`k_pts_entries[]` 第 19 名，`win32_pts.c:90`）⇒ **不是**缺符号项（`ENFE=0`）⇒ 它的失败形态是**运行期拒绝**（`[FS_PAGE_GAP]`），**不是**封送期异常。

### 4.2 "实现后可观察变化"（可判据）

**若 §3.2 候选真做（前置已解）**，可观察变化**只准**读成**这三条**（**不得**读成"两页真排版打通／`TASK-0007` 可绿"）：

1. **该入口的缺省路径拒绝面消失**：`[FS_PAGE_GAP] … entry=FsQueryTrackParaList` 计数从 **1054 → 0**（同腿同装置、单变量对比）。
2. **`[HC-UNHANDLED]`（＝`PtsException … -10000`）计数同步下落**（当前 1054，与①同源）。
3. **症状门逐字段不变**（`magenta=0`／`colors=383`／`ink=480000`／`ns=…`，见 `D6`）—— **"计数下降 ≠ 能力前进"**（照 `pts-gap-count-check.sh` 件头第①条）。

**今天（本波）可观察变化 ＝ 无**（不实现）。

---

## §5 具名阻塞前置清单（因判"无有源可做项"）

| 前置 | 射程 | 状态／归属（现取） |
|---|---|---|
| **`PRECOND-MANAGED-HANDLE-TABLE`** | `FsQueryTrackParaList` 出参 `pfsparaclient`／`nmp`；`FsQuerySubtrackDetails.nms` | **成立**：native **无合法来源**（`win32_pts.c:3593-3598`）⇒ 挡 `rc=0` |
| `PRECOND-PFSPARA-ONLY-IN-PROBE` | 缺省 `pfspara` 恒 0（填充块整块在 `wpf_pts_drive_probe_enabled()` 内，`:3626`） | **成立**（`P1-tail2-fsqsub-recon.md` §3.2；现取 `[DRIVE-PROBE-SKIP] reason=gate-off`＝3） |
| `PRECOND-PARADESC-SOURCE-MISSING`（`scope=subtrack-path`） | `PtsHelper.cs:174-180` 的 `rcPara.dv` 计算 | **未解除**；需实现 `FsQuerySubtrackParaList`（`S-2b`） |
| `PRECOND-NO-LAYOUT-CONTENT-MODEL` | `FsQuerySubtrackDetails.cParas`（托管孩子数真值） | **成立**（内容层无源） |
| `PRECOND-NMS-UNOWNED` | `FsQuerySubtrackDetails.nms`（需托管句柄） | **成立** |
| `PRECOND-NO-MANAGED-SIDE-WRITER` | 托管 `.cs`；粒度＝单次调用 | **未解除**（托管侧协作者无落点） |
| `PRECOND-FRAME-DETERMINISM` | 帧面类要件 | **未满足**（冻结令维持，裁定四十二 (b)） |

---

## §6 边界 · `NOINFO` · 主动披露

1. **未构建**；**未跑整趟 `verify-all`**；**未跑 `static-jaws-check.sh`**；**未改 `src/**`**；**未占共享显示位**（仅规范腿器自配的 `:231`）；**未 `git add/commit/push`**；唯一写入＝本件。现取 `git status --porcelain` 只有两项 untracked（`build/MilBridge/tasks-tail2/T-A6.md` 与 `build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`），**均先于本件存在**。
2. **本席新跑的一趟短腿**（§1.1）落**仓外** `/home/links-dev/tA6-work/`（`app` 副本 ＋ `evidence` ＋ `logs` ＋ `legs.sh`），**未写仓内**；进程只按 PID；以 `heavy-slot` 包住（`HEAVYSLOT=ACQUIRED…RELEASED held=37s`）。
3. **引他人读数（标"未独立复算"）**：`P1-tail2-fsqsub-impl-report.md` §2 的探针路径成对读数（`ENFE 1177→0`／`[FSQSTD] 1002`）、`P1-tail2-fsqsub-recon.md` §3、`P1-tail2-t0307-recon.md` §2.2 —— 均**引自其载体**；本件**自算**的只有 §1／§2 的现件代真腿读数（`grep -c`／逐行现取）＋ §件指纹（`sha256sum`）。
4. **口径面（本席现取，如实记；不在本件写域）**：转换器 `legs-to-env.py:138` 以 `PTS_GAP entry=`（**旧格式**）计 `native_gap`，而现件代 native 台账格式为 `[FS_PAGE_GAP] … entry=<名>`（**新格式**）⇒ 转换器产出的 `leg_*.env` 记 `native_gap=0`，`pts-pages-guard.sh` 因而报 `native-ledger-absent(PTS_GAP n=0)` 与 `PTS_C4_LEDGER=NOINFO`。**本席不判**这是"口径缺口"还是"预定行为"（需持该件的写者裁决），只如实记：**任一以 `native_gap` 为输入的面，今天读不到本节 §1.2 的 1054 次**。**不影响**本件结论（本席**直接**从日志取 `[FS_PAGE_GAP]`／`entry=`，不经转换器）。
5. **`NOINFO`（逐条给消掉条件）**：① `FsQueryTrackParaList` **缺省路径真填后**的读数（**今天结构性不可达** —— 无源、且真填块在探针门内）；② 托管侧能否产出可反查的 `pfsparaclient`（**本侧不可判**）。
6. **代际**：`.so`＝`a1403ea71c2bf487`；`win32_pts.c`＝`e0b5a3a4a21e2275`；`exports.txt`＝`f61b9b1e55fdc600`／670 行。
7. **本件自带的两处反腿**：① **`D5`**（§3.2）—— 不把"闸开（探针）可得"读成"缺省路径可得"；② **§1.2 口径句** —— 不把"缺口条数"读成"前沿位移"。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-next-recon.md | sha256sum | cut -c1-16`）= `227a4a26edfcee72`

# P1-tail2 缺省路径三级链可驱动性 —— 只读设计侦察 ＋ 判据先写

- **读时**：`2026-09-30T11:58+0800`（本席现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=87efb58`（现取；`P1 尾波2 (#82)：P4 修复——PtsCache.Linux.cs 生成件归位（t133/t155 编码进 PTSCACHE_EDITS）`）。
- **现件代**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` ＝ **`a1403ea71c2bf487`**（现取）。
- **件指纹（现取，`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`＝`e0b5a3a4a21e2275`（4590 行）｜`bin/exports.txt`＝`f61b9b1e55fdc600`｜`tools/pts-gap-decl.txt`＝`32b303148aca23a9`｜`build/PresentationFramework.Linux/PtsCache.Linux.cs`＝`e5b399fdb8742092`（1658 行）｜`build/PresentationFramework.Linux/reapply-patches.py`＝`（未复取；`PTSCACHE_EDITS` 在 `:1101`，应用在 `:1355`）`。
- **证据件（本席现读，**仓外私有目录**，非本席新跑）**：`/home/links-dev/tA6-work/evidence/app_g1.log`＝`2cc957c72ea6f186`（3870 行；`shim_sha16=a1403ea71c2bf487` ＝ 现件代）｜`leg_23.env`／`leg_24.env`／`session.txt`（同目录）。**本席未新跑腿**（只读；T-A6 那一趟即现件代缺省路径样本，见 §6-3）。
- **边界（照 T-A8 ②）**：只读；除本件外**未改任何仓内文件**；**未改 `src/**`、未构建、未跑整腿、未跑整趟 `verify-all`、未跑 `static-jaws-check.sh`**；**未占显示位**；大件只用 `wc/head/tail/grep`；未 `git add/commit/push`。现取 `git status --porcelain` 只有两项 untracked（`build/MilBridge/tasks-tail2/T-A8.md` 与 `build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`），**均先于本件存在**。
- **行号纪律**：本件所有行号**仅本次有效**（内容锚原文一并给出，供下一位现取复核）。

---

## §0 结论速览（自包含）

1. **缺省路径里"车"在位**：`CreateDocContext`（**缺省路径**，非探针门）就把整个 `FSCBK` 表**值拷贝**进 doc（`[FSCBK-SNAP] … bytes=824 words=103 nonzero=71 slot56=nonzero slot80=nonzero state=VALUE` ×3）⇒ 三级链的三个回调槽**都在**：`[FSCBK-SLOT] name=pfnGetMainTextSegment abs=80 val=0x…b060`／`name=pfnGetFirstPara abs=136 val=0x…acb8`／`name=pfnGetNextPara abs=144 val=0x…acd0`／`name=pfnCreateParaclient abs=176 val=0x…b0f0`（`app_g1.log:810-816`，**全部非零**）。
2. **缺省路径里"发车点"也在跑**：`FsCreatePageBottomless`／`FsCreatePageFinite` **是缺省路径**（`FlowDocumentFormatter.Format → FlowDocumentPage.FormatBottomless → PtsPage.CreateBottomlessPage`），且**在 `SetDocumentFormatContext` 窗内**；两处**都**调 `wpf_pts_drive_probe` ⇒ 缺省路径留 **3** 条 `[DRIVE-PROBE-SKIP] reason=gate-off`（`app_g1.log:819/954/2263`）。
3. **唯一挡住三级链的是"一道运行期闸"**：`win32_pts.c:1769` `if (!wpf_pts_drive_probe_enabled()) { … "gate-off"); return; }`；再有一道**填充闸** `:3626` `else if (wpf_pts_drive_probe_enabled())` 挡住 `pfspara`/`pfsparaclient` 回填。⇒ **缺省路径今天 `DRIVE-PROBE-ENTER`＝0、`FSPARALIST-FILL`＝0**（现取）⇒ `FSPARADESCRIPTION.pfspara`／`pfsparaclient` **恒 0**（`reason=paraclient-table-not-native` ×1054）。
4. **甲路（native 在缺省路径自发起入口）：可及 ∧ 可行** —— 摘／改上述两道闸即可把"探针机制"升为"产品路径"，**复用** `t160`/`t198` 已有的代数／配额／延迟回收机器；**代价 ＝ 须先拿裁定撤销「裁定三十六 (b)：缺省关」**，且必须同判**下游位移**（填了列表 ⇒ `ContainerParaClient.OnArrange` 走到 ⇒ 撞 `FsQuerySubtrack*`）与**副作用面**（`+80` 懒创建 ContainerParagraph；`t148` §3 判其帧面影响 `NOINFO`）。
5. **乙路（托管侧在不撤闸前提下自备 `pfspara`/`pfsparaclient`）：不可行** —— `rgParaDesc` 是 `PtsHelper.ParaListFromTrack` 内 `fixed` 局部指针，**唯一写者＝native**；`pfsparaclient` 的**唯一产地＝native 唤起 `+176` 回调**（`PtsCache.Linux.cs:625` 装配、`PtsHost.CreateParaclient` 实现）⇒ 托管侧单独"备好"既无处落笔、也无从产生句柄。
6. **结论**（照 T-A8 ④ 二分）：**可行（仅甲路）⇒ 给设计草案 ＋ 判据草案**（§4，D1–D7，含**零假值／永不假成功／失败必留痕／症状门不变** 四要件与逐条反极性）；**并**给具名前置（§4.4）—— 因甲路的第一步＝**改政策**，非纯实现。
7. **⑤ 生成件落点**：本设计**不碰**托管生成件（回调已装配在 `PtsCache.Linux.cs:605/608/617/619/625`）；**若日后**要改装配／落点 ⇒ **改生成器 `build/PresentationFramework.Linux/reapply-patches.py`（`PTSCACHE_EDITS`，现 `E1–E8`），不改生成件 `PtsCache.Linux.cs`（铁律 `P8`）**。详见 §5。

---

## §1 ① `PRECOND-PFSPARA-ONLY-IN-PROBE` —— 现取逐字条件 ＋ 缺省路径 `pfspara` 恒 0 证据

### 1.1 闸的**逐字**条件（三道）

**闸定义**（`win32_pts.c:922-930`，现取逐字）：
```c
static int wpf_pts_drive_probe_enabled(void)
{
    static int cached = -1;                      /* −1 未取；0 关；1 开（本进程内取一次） */
    if (cached < 0) {
        const char *v = getenv("WPF_PTS_DRIVE_PROBE");
        cached = (v && v[0] && strcmp(v, "0") != 0) ? 1 : 0;
    }
    return cached;
}
```
⇒ **缺省关**（未设／空／`"0"` 皆关；与本进程内**取一次后缓存**）。

**闸 1（驱动）**（`win32_pts.c:1764-1770`，现取逐字）：
```c
static void wpf_pts_drive_probe(wpf_pts_doc *d, const void *sect, const char *where)
{
    if (!d) { wpf_pts_drive_probe_skip("null-doc"); return; }
    if (d->fscbk_snap_state == WPF_PTS_FSCBK_SNAP_NONE) { wpf_pts_drive_probe_skip("no-snapshot"); return; }
    /* ⏪ `t148`：**运行期闸**（缺省关）—— 闸关 ⇒ **一次都不调**，并留一条具名行 */
    if (!wpf_pts_drive_probe_enabled()) { wpf_pts_drive_probe_skip("gate-off"); return; }
```
⇒ **闸关 ⇒ 三级链一次都不调**（`+80`／`+136`／`+176` 全在此函数体内，`1841-1844`／`1860-1861`／`1903-1905`）。

**闸 2（回填）**（`win32_pts.c:3626`，现取逐字）：
```c
        else if (wpf_pts_drive_probe_enabled()) {
```
⇒ `pfspara`／`pfsparaclient` 的**整块填充体**（`:3724-3892`）都在这一个 `if` 内 ⇒ **闸关 ⇒ 落到 `:3920 reason = "paraclient-table-not-native"`，永不返 0**。

**闸 3（窗外腿）**（`win32_pts.c:1463`）：`if (!wpf_pts_drive_probe_enabled()) return;`（`FsDestroyPage`／`FsQueryTrackParaList` 头部的窗外腿，同族）。

### 1.2 `pfspara`／`pfsparaclient` 的**唯一写入点**（现取）

`grep -n 'pfspara *=|pfsparaclient *=|\.nmp *='`（`win32_pts.c`）⇒ **唯一真填块**：
```c
3780:                        rg[i].pfspara       = (void *)para_val;
3781:                        rg[i].pfsparaclient = (void *)dp->fsp_pl_cur;
3782:                        rg[i].nmp           = (void *)dp->drive_nmp;
```
（另 `:1227 o->nmp = nmp; o->pfsparaclient = client;` 是**子轨对象内部字段**，非 `FSPARADESCRIPTION`。）

**`dp->drive_nmp` 的唯一赋值**（`win32_pts.c:1982`，在 `wpf_pts_drive_probe` **体内**）：
```c
            if (d->drive_nmp == NULL) d->drive_nmp = (const void *)nmp1;  /* 窗外腿复用**合法** nmp */
```
⇒ **闸关 ⇒ `drive_nmp` 恒 `NULL`**（连 `:3639 reason=no-legal-nmp-in-this-run` 都走不到，因为 `:3626` 已短接）。

### 1.3 缺省路径 `pfspara` 恒 0 的**现取证据**（现件代 `a1403ea71c2bf487`，缺省路径样本）

| 读数（`grep -c`，`/home/links-dev/tA6-work/evidence/app_g1.log`，3870 行，`sha16=2cc957c72ea6f186`） | 值 |
|---|---|
| `[DRIVE-PROBE-ENTER]` | **0** ⇒ 三级链**一次都没被调** |
| `[DRIVE-PROBE-SKIP] reason=gate-off` | **3**（`:819/954/2263`，两处调用点的**唯一**留痕） |
| `[FSPARALIST-FILL]` | **0** ⇒ 真填块**从未进入** |
| `[FSPARALIST-PARA]` | **0** |
| `[FS_PAGE_GAP] … entry=FsQueryTrackParaList` | **1054**；`reason=` **唯一项 ＝ `paraclient-table-not-native`**（＝ `:3920`，**闸关短接的现场指纹**） |
| `[FSCBK-SNAP] entry=CreateDocContext … state=VALUE … slot80=nonzero` | **3**（`:703/840/2149`） |
| `[FSCBK-SLOT] name=pfnGetMainTextSegment/…FirstPara/…NextPara/…CreateParaclient` | 全**非零**（`:810-816`） |

**首／末逐字**（同一趟）：
```
:820  [FS_PAGE_GAP] rc=-10000 reason=paraclient-table-not-native entry=FsQueryTrackParaList ctx=0x5fe7895b5f60 track=0x5fe78a56eb18 cParas=1 owned=1 ok=0 gap=1
:3869 [FS_PAGE_GAP] rc=-10000 reason=paraclient-table-not-native entry=FsQueryTrackParaList ctx=0x5fe78940ecf0 track=0x5fe789a5cff8 cParas=1 owned=1 ok=0 gap=1054
```
⇒ **判定**：`PRECOND-PFSPARA-ONLY-IN-PROBE` **现取成立** —— 缺省路径 `pfspara`／`pfsparaclient` **恒 0**，与 `P1-tail2-fsqsub-recon.md` §3.2 的收窄判定**一致**（本件**独立现取复核**：口径＝"缺省路径真腿日志的 `[FSPARALIST-*]`＝0 ＋ `reason=paraclient-table-not-native`"）。

---

## §2 ② 缺省路径里谁在跑 —— 实际驱动链（件:行）＋ 是否可能驱动 `fscbk` 回调表

### 2.1 应用正常布局时的**托管链**（现取逐字，`upstream/**`）

```
FlowDocumentFormatter.cs:51  Format(Size constraint)
  → :99   _documentPage.FormatBottomless(pageSize, pageMargin)
  ── FlowDocumentPage.cs:120-164 FormatBottomless(...)
  → :136  using(_structuralCache.SetDocumentFormatContext(this))     ← ★ **窗内**
  → :148     _ptsPage.CreateBottomlessPage()
  ── PtsPage.cs:280-295 CreateBottomlessPage()
  → :295  int fserr = PTS.FsCreatePageBottomless(PtsContext.Context, _section.Handle, out …, out ptsPage)
```
（有限页并行一条：`FlowDocumentPage.cs:175-199 FormatFinite` → `:199 using(SetDocumentFormatContext)` → `PtsPage.cs:397 FsCreatePageFinite`。）

⇒ **`FsCreatePageBottomless`／`FsCreatePageFinite` 是缺省路径的入口，且两处都在 `using(SetDocumentFormatContext)` 窗内**（＝ `t151` 判据所指的"窗内"）。

### 2.2 native 侧**实际被调到的入口**（现取可归因面）

| 入口 | 缺省路径次数 | 证据 |
|---|---|---|
| `CreateDocContext`（**真实现**，非缺口） | **3** | `[FSCBK-SNAP] entry=CreateDocContext …` ×3（`:703/840/2149`） |
| `FsCreatePageBottomless`／`FsCreatePageFinite`（**真实现**） | **≥3**（不精确：成功路径不打点） | 由 `[DRIVE-PROBE-SKIP] reason=gate-off` ×**3** 反推 —— 该两处是 `wpf_pts_drive_probe` 的**唯一**两个调用点（`:410`／`:3569`；`grep` 全树现取） |
| `FsQueryTrackParaList`（**诚实拒绝**） | **1054** | `[FS_PAGE_GAP] … entry=FsQueryTrackParaList` ×1054 |
| `FsCreatePageBottomless/FsCreatePageFinite/FsQueryTrackDetails/FsQueryPageDetails/FsDestroyPage/Lo*`（真实现，**成功不打点**） | **日志取不到** | 函数体现取：成功 `return` 前**无 `fprintf`**（如 `:3581`／`:426`／`:3531`） ⇒ 次数 `NOINFO` |

**口径（写死）**：本表**只**列"日志可归因"的入口；**不**把"成功不打点"读成"没被调"。

### 2.3 这些调用点**是否可能驱动 `fscbk` 回调表** —— 现取：**可能，且只由一道闸拦着**

- **表在位**（`§1.3`）：`[FSCBK-SNAP] state=VALUE nonzero=71 slot80=nonzero` ⇒ doc 内**已有**回调表值拷贝（`t141` 的 `PRECOND-FSCBK-SNAPSHOT-IN-DOC` **在缺省路径已成立**）。
- **唯一调用者** ＝ `wpf_pts_drive_probe`（`grep` 现取：三级链的 `+80`／`+136`／`+176` 调用**只**出现在 `:1843`／`:1860`／`:1903`／`:1936`，**全在该函数体内**）；而该函数**唯一**由 `:410`（`FsCreatePageBottomless`）／`:3569`（`FsCreatePageFinite`）调用。
- **窗**：两处调用点已在 `SetDocumentFormatContext` 窗内（§2.1）⇒ 若发调，**不会**落 `t151` 的"窗外 `-100002`"（`ContainerParagraph.cs:151` 读 `CurrentFormatContext.IncrementalUpdate` 的 NRE 支）。
- ⇒ **判定**：缺省路径**具备**驱动三级链的**全部要件**（入口在缺省路径 ∧ 窗内 ∧ 表在位 ∧ 回调已装配 `PtsCache.Linux.cs:605/608/617/619/625`）；**唯一未做的** ＝ 第一步（发调）被运行期闸挡住（`DRIVE-PROBE-ENTER`＝0）。

---

## §3 ③ 甲／乙两路的 **可及 ∧ 可行 ∧ 代价**（逐条）

### 3.1 甲路 —— **native 在缺省路径自己发起入口**（例：`FsCreatePageBottomless` 内补驱动）

| 面 | 现取判定 |
|---|---|
| **可及（谁改）** | **native 写域**：`src/WpfGfx.Linux.Native/src/win32_pts.c`（**手写源**，非生成件）；登记面 `bin/exports.txt`／`tools/pts-gap-decl.txt`。**不越域**。 |
| **可行（怎么改）** | **两处小改**即可让三级链＋回填在缺省路径生效：<br>① **`win32_pts.c:1769`** —— 取消（或按 doc 记账后放宽）`if (!wpf_pts_drive_probe_enabled()) { …"gate-off"); return; }`，使 `FsCreatePage*` 恒定驱 `+80→+136` 把 `drive_nmp` 落进 doc；<br>② **`win32_pts.c:3626`** —— 把 `else if (wpf_pts_drive_probe_enabled())` 改为无条件 `else`，使 `FsQueryTrackParaList` 走**已有**真填块（`:3724-3892`，复用 `t160`/`t198` 的**代数 `fsp_pl_gen`／配额 `fsp_pl_quota`／延迟回收 `fsp_pl_prev`** 机器）。<br>预算面：`WPF_PTS_DRIVE_PROBE_N`（`wpf_pts_drive_probe_n()`，**缺省 1**）须改为"≥ doc 数"或按 doc 记账（否则只有第 1 个 doc 拿到 `drive_nmp`）。 |
| **代价（结构面）** | ① **政策**：与**裁定三十六 (b)**「探针闸**缺省关**」**直接冲突** ⇒ 甲路第一步 ＝ **改裁定**，非纯实现（**具名前置** `PRECOND-RULING-REVOKE-DEFAULT-OFF`，见 §4.4）。<br>② **副作用**：`+80` 的托管实现**懒创建** `ContainerParagraph`（`ContainerParagraph.cs:142 _firstChild = GetParagraph(...)`）。`t148` §3 现取：**开/关探针在本代帧面相同**（`fr_sha=ef3fd6765f18f51b`／`ae_boot=15386`／`colors=383`）⇒ 该副作用对帧面的影响判 **`NOINFO`**（`t146` 那一趟 `b273ebecc332fc03`／`391` 是**离群**，成因未定）；⇒ **不得**把"帧变了"读成进度（裁定三十六 (c)），也**不得**把"帧没变"读成"无副作用"。<br>③ **下游位移**：列表**真填后**，`ContainerParaClient.OnArrange`（`:47`）等 10 处会走到 ⇒ 撞 `FsQuerySubtrackDetails`／`FsQuerySubtrackParaList`（**未实现／诚实拒绝**）⇒ 缺口面从 `FsQueryTrackParaList` **位移**到 `FsQuerySubtrack*`（**"计数下降 ≠ 能力前进"**，`pts-gap-count-check.sh` 件头第①条）。<br>④ **语义上界**：填进 `rg[i]` 的 `pfsparaclient`／`nmp` 是**同一枚**（`fsp_pl_cur`／`drive_nmp`）**灌满所有 i** ⇒ 对 `cParas=1`（现取本应用即 `cParas=1`，`:820`）自洽，对 `cParas>1` **不是**"轨道→段落序"映射 ⇒ 仍受 **`PRECOND-NATIVE-OWNS-A-PARAGRAPH-MODEL`** 挡（`P1-managed-handle-report.md` §2）。<br>⑤ **句柄生命周期**：`+176` 每次建**真** `BaseParaClient`（入托管表）；「不回收交出去的、延迟回收上一代」的纪律由 `fsp_pl_prev` 机器承担（`t160`/`t198` 已有）；缺省路径须重跑一遍 `LMWIT` 见证（`S2A-4-WITNESS-OK`）确认无泄漏。 |

### 3.2 乙路 —— **托管侧在不撤闸的前提下把 `pfspara`／`pfsparaclient` 备好**

| 面 | 现取判定 |
|---|---|
| **可及（谁改）** | 托管 `.cs`：落点必是 **`build/PresentationFramework.Linux/**`**（**生成件**，见 §5）。 |
| **可行（怎么改）** | **不可行**（三条，逐条封死）：<br>① **无处落笔**：`rgParaDesc` 是 `PtsHelper.cs:604-620 ParaListFromTrack` 内的 `fixed (PTS.FSPARADESCRIPTION* rgParaDesc = arrayParaDesc)` **局部指针**（`:612`），**只有 native 能写**（托管全树 `grep '\.pfsparaclient *=[^=]'` **命中 0**）⇒ 托管侧"手里有值"也写不进去。<br>② **无从产生值**：`pfsparaclient` 的**唯一产地** ＝ `PtsContext.CreateHandle`（表内槽号），只被 `new *ParaClient(...)` 触发，只被 `PtsHost.CreateParaclient` 触发，而它的**唯一**触发者 ＝ **native 唤起回调槽 `+176`**（装配 `PtsCache.Linux.cs:625`；实现 `PtsHost.cs:724/734`）⇒ **native 不发车，表里就没有值**。<br>③ **无事可查**：托管侧表只记「槽 ↔ 对象」，**没有**「轨道 → 段落序」映射（`P1-managed-handle-report.md` §3-路③）⇒ 就算能写，也不知道该填哪个。 |
| **代价** | ——（不可行 ⇒ 无代价可言）。 |

**关键判词**：**甲路可及且可行（代价＝改政策＋下游位移＋副作用面）；乙路不可行。** 承 `P1-managed-handle-report.md` 的三段前置，本件**归位**其中"承重两段"＝**甲路**（native 发车＋native 承载），而**托管侧半件已就绪**（回调已装配）。

---

## §4 ④ 结论 ＝ **可行（甲）** ⇒ 设计草案 ＋ 判据草案

### 4.1 设计草案（甲）：「撤闸常开 ＋ 列表真填」＝ 把现有探针机器升为**产品路径**

> **口径（写死）**：本设计**不改**任何托管件、**不改**上游；全部落点 ＝ `src/WpfGfx.Linux.Native/**`（**手写源**）。

| # | 落点 | 动作 | 判据面 |
|---|---|---|---|
| **S1** | `win32_pts.c:1769` | 取消闸关早退（或改为"每 doc 首窗恒驱"）；`FsCreatePageBottomless`／`FsCreatePageFinite`（**窗内**）恒驱 `+80→+136`，把 `drive_nmp`／`drive_nmseg` 落进 doc | `[DRIVE-PROBE-ENTER]` 计数 ≥ doc 数（缺省路径） |
| **S2** | `win32_pts.c:935-944` | 预算 `WPF_PTS_DRIVE_PROBE_N` 缺省由 `1` 提到"≥ doc 数"，或改**按 doc** 记账（每 doc 恰好驱一窗） | `drive_nmp != NULL` 的 doc 数 ＝ doc 总数 |
| **S3** | `win32_pts.c:3626` | `else if (wpf_pts_drive_probe_enabled())` ⇒ 无条件 `else`（走已有真填块 `:3724-3892`） | `[FSPARALIST-FILL] rc=0`（缺省路径） |
| **S4** | 只读口 | `WpfLinuxWin32_PtsDriveProbeGate()` 语义随动（恒报 1），或**新增**一只读口（如 `…PtsDefaultChainOn()`）；新增须同趟 `bin/exports.txt`／`tools/pts-gap-decl.txt` **逐名对拍零消失** | `nm=exports` 相等 |
| **S5** | 台账 | 保留 `[DRIVE-PROBE*]`／`[FSPARALIST-*]`／`[LMWIT*]` 具名行（它们是判据载体），但**不得**让其改变症状门 | §4.2 D6 |

**非目标（写死）**：不实现 `FsQuerySubtrackDetails`／`FsQuerySubtrackParaList`（→ 下游位移如实记，见 §4.2 D7）；不宣布"两页真排版／`TASK-0007` 可绿"；不动帧面判词（裁定三十六 (c)／四十二 (b) 冻结令维持）。

### 4.2 判据草案（D1–D7；**≥3 条可证伪 ＋ 逐条反极性**；含四要件）

> **前置口径（写死）**：D1–D7 **只在"缺省路径"（**不设** `WPF_PTS_DRIVE_PROBE`）**下取数；读数一律带**纪律 30 三格**（进程新鲜度 ＋ 关键前置量 ＋ 判词）＋ **代际三元组**（载体 ＋ `ts` ＋ `shim=/so16/pf=`）。**任何绿只准**读成"该入口在缺省路径不再拒绝、且行为可读"，**不得**读成"排版打通"。

| # | 判据（可证伪） | 反极性（必红腿） | 要件归属 |
|---|---|---|---|
| **D1 零假值／出参纪律** | 拒绝路径 **`rgParaDesc` 一字不写**、`*cParaDesc=0`（现状 `:3608`）；真填路径**先 `memset` 清零再逐字段写**（`:3778`），未初始化内存**不许**交给上级。 | 为让 `rc=0` 好看而填**伪句柄**（`0x1000`／小整数／栈地址）⇒ 消费者 `HandleToObject` 撞 `Assert` ⇒ `FailFast`／NRE ⇒ **必红**。 | **零假值** |
| **D2 永不假成功** | `rc=0` **仅当**同时给出：可经 `HandleToObject` 反查为 `BaseParaClient` 的 `pfsparaclient` ∧ `nmp` 合法 ∧ `cParaDesc==cParas`。缺一 ⇒ **必须返非 0**。 | 返 `rc=0` ＋ 常量 `cParaDesc`／伪造句柄 ⇒ **伪成功** ⇒ **必红**（会让 `PtsHelper.cs:158` 静默取到错对象）。 | **永不假成功** |
| **D3 失败必留痕** | 任何拒绝**必**打具名 `[FS_PAGE_GAP] rc=<int> reason=<具名> entry=FsQueryTrackParaList ctx=… track=… cParas=… owned=… ok=… gap=…`，且 `gap` **恰涨 1**（承现状 `:3922-3926`）。 | **静默 stub**（返非 0 零痕迹）⇒ 与"真 0 次"不可分 ⇒ **必红**（裁定二十三 ①：留痕做在 native 侧）。 | **失败必留痕** |
| **D4 身份只许靠来源证据** | `pfsparaclient`／`nmp` 必须来自**本 run** 的 `+176`／`+136` 回调返回（`fsp_pl_src_in` ∕ `drive_nmp` 来源行）；`track`／`pfspara` 必须能被本侧台账**唯一认领**（`wpf_pts_track_owned`／`wpf_pts_sub_claim`），且与同 run 产出行**同值**。 | 靠 `rc`／数值大小判身份 ⇒ **必红**（`t160` ABA 反腿：`rc` 与数值都无法辨身份）。 | （身份纪律） |
| **D5 撤闸前后**分开报****（本设计新立） | **改前**（缺省）恒 `reason=paraclient-table-not-native`；**改后**（缺省）★仍缺省★ 才可出现 `[FSPARALIST-FILL] rc=0`。取数**必须**在"不设 `WPF_PTS_DRIVE_PROBE`"的腿上；**并**给"改前那一代"的对拍行。 | 把"**闸开（探针）**可得"读成"缺省路径已通" ⇒ **必红**（`P13` 反腿；`P1-tail2-fsqsub-recon.md` §4 同族）。 | （防假绿） |
| **D6 症状门不变** | 缺省路径改后两腿**逐字段不变**（现取基线，`tA6-work/leg_{23,24}.env`，`shim=a1403ea71c2bf487`）：`alive=yes`／`app_rc=143`／`magenta=0`／`colors=383`／`ink=480000`；`ns=…RichTextBoxDemo`（k23）／`…FlowDocumentDemo`（k24）；`FRAME fr_sha=ef3fd6765f18f51b`／`fr_ae_boot=15386`（两腿同值）；`FAILLINE … failfast=0 unrec=0`；`ENFE=0`／`unavail=0`／`^PTS_GAP entry=`＝0。 | 任一字段漂移（如 `magenta` 抬头／`app_rc=134`／`Invariant.FailFast≥1`）⇒ **必红**。⚠️ **并**：`+80` 侧效应导致的"帧变"属 `NOINFO`（`t148` §3），**任何方向都不得读成进度**（裁定三十六 (c)）。 | **症状门不变** |
| **D7 ≥2 独立样本 ＋ 下游位移如实记** | ≥2 独立 PID／启动时刻，判词**相同**（裁定三十八）；**并**如实记"缺口面**位移**"：`entry=FsQueryTrackParaList` 计数下落、`entry=FsQuerySubtrackDetails`（若已导出）计数上升 ⇒ **不得**把这写成"能力前进"。 | 单样本当机制 ⇒ **必红**（`P9`）；把"计数下降"当能力前进 ⇒ **必红**（`pts-gap-count-check.sh` 件头第①条）。 | （纪律） |

### 4.3 可观察变化（**只准**读成这三条）

1. **该入口缺省路径拒绝面消失**：`[FS_PAGE_GAP] … entry=FsQueryTrackParaList` 计数 **1054 → 0**（同腿同装置、单变量对比）。
2. **缺口面位移**：`entry=FsQuerySubtrack*` 计数由 0 上升（**这是位移，不是能力**）。
3. **症状门逐字段不变**（D6）。

### 4.4 具名前置清单（甲路第一步 ≠ 纯实现）

| 前置 | 射程 | 状态／归属（现取） |
|---|---|---|
| **`PRECOND-RULING-REVOKE-DEFAULT-OFF`**（本件新立） | `win32_pts.c:922-930`／`:1769`／`:3626` 的"缺省关" | **成立**：与**裁定三十六 (b)** 直接冲突 ⇒ 甲路须**先拿裁定**（非实现者权限） |
| `PRECOND-PFSPARA-ONLY-IN-PROBE` | `pfspara`／`pfsparaclient` 填充体整块在闸内 | **成立**（§1，本件现取复核）；＝ 甲路的**拆除对象** |
| **`PRECOND-NATIVE-OWNS-A-PARAGRAPH-MODEL`** | `cParas>1` 时的"轨道→段落序"映射 | **成立**（`P1-managed-handle-report.md` §2）⇒ 甲路对 `cParas>1` **仍不诚实**（本应用 `cParas=1`，暂无碍） |
| `PRECOND-MANAGED-HANDLE-TABLE` | `pfsparaclient`／`nmp` 的出参来源 | **在甲路上被解除**（来源＝native 唤起 `+176`／`+136`）；**在乙路上仍成立** |
| `PRECOND-NO-LAYOUT-CONTENT-MODEL` | `FsQuerySubtrackDetails.cParas`（下游） | **成立**（下游位移的落点） |
| `PRECOND-FRAME-DETERMINISM` | 帧面类要件 | **未满足**（冻结令维持，裁定四十二 (b)） |

---

## §5 ⑤ 生成件落点 —— 「改生成器、不改生成件（`P8`）」

- **本设计（甲）落点全部在手写源** `src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **不碰任何生成件**。
- **桥接面已在生成件里就位**（**本设计无需改动**）：`build/PresentationFramework.Linux/PtsCache.Linux.cs:605/608/617/619/625` 已装配 `pfnGetNextSection`／`pfnGetMainTextSegment`／`pfnGetFirstPara`／`pfnGetNextPara`／`pfnCreateParaclient`。
- 🔴 **若日后**要改这条装配／托管侧落点 ⇒ **必须改生成器，不改生成件**：`PtsCache.Linux.cs` 件头**逐字**自述
  > `// ⚠️ 本文件由 build/PresentationFramework.Linux/reapply-patches.py **生成**，不要手改。`
  其内容 ＝ 上游 `…/PtsHost/PtsCache.cs` **逐字复制 ＋ `PTSCACHE_EDITS`（`reapply-patches.py:1101` 定义、`:1355` 应用；现 `E1–E8`）**。
  ⇒ **落点 ＝ `build/PresentationFramework.Linux/reapply-patches.py`（新增／修改 `PTSCACHE_EDITS` 条目）**，**不是** `PtsCache.Linux.cs`（手改＝下次重生成即静默回退 ⇒ 铁律 `P8` 必红：`reason=generator-drift`）。
- **登记件**（native 面，随实现同趟）：`src/WpfGfx.Linux.Native/bin/exports.txt`（若新增只读口，须逐名对拍零消失）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`so16=`／`exports=` 两个 token 随动）。

---

## §6 边界 · `NOINFO` · 主动披露

1. **只读**：本件全部命令为 `grep`／`sed`／`cat`／`head`／`wc`／`sha256sum`／`git log`／`git status`；**未构建、未跑腿、未改 `src/**`、未跑整趟 `verify-all`、未跑 `static-jaws-check.sh`、未占显示位、未 `git add/commit/push`**；唯一写入 ＝ 本件。
2. **未改任何其它件**：现取 `git status --porcelain` 仅两项 untracked（`build/MilBridge/tasks-tail2/T-A8.md`、`build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/app_g1.log`），**均先于本件存在** ⇒ **本件是本次唯一新增件**。
3. **本席未新跑腿（主动披露）**：§1／§2 的缺省路径读数取自**现件代**样本 `/home/links-dev/tA6-work/evidence/app_g1.log`（`shim=a1403ea71c2bf487` ＝ 现盘 `.so`，**同代**），性质是「**在册证据的现核**」而**非本席同趟重取** ⇒ **不得当同趟绿**（照 `P1-managed-handle-report.md` §C10 同族限制）。**未跑腿的理由**：本件是只读设计侦察，且现件代缺省路径样本已在手、`shim` 与现盘逐位相等。
4. **引他人读数（标"未独立复算"）**：`P1-tail2-next-recon.md` §1（1054／1057／`gate-off`＝3）、`P1-tail2-fsqsub-recon.md` §3.2（闸的收窄）、`P1-managed-handle-report.md` §2／§3（三段前置）、`P1-drive-probe-gate-report.md` §3（帧面离群 `NOINFO`）、`P1-pfspara-report.md`（`t162` 运行期读数）—— 均**引自其载体**；本件**自算**的只有 §1.3／§2.2 的 `grep -c`／`grep -m1`／整行现取 ＋ §件指纹（`sha256sum`）。
5. **`NOINFO`（逐条给消掉条件）**：① **甲路缺省路径真填后的读数**（**今天结构性不可达** —— 闸未撤）；② **`cParas>1` 时的映射正确性**（需 `PRECOND-NATIVE-OWNS-A-PARAGRAPH-MODEL`）；③ **`FsCreatePageBottomless/FsCreatePageFinite` 的精确次数**（成功路径不打点 ⇒ 只能反推 ≥3）；④ **`t146` 帧面离群（`b273ebecc332fc03`／`391`）的成因**（`t148` §3 已判 `NOINFO`，本件未复跑）；⑤ **`Lo*` 在缺省路径的实际调用面**（成功不打点 ＋ 本件未跑腿）。
6. **代际**：`.so`＝`a1403ea71c2bf487`；`win32_pts.c`＝`e0b5a3a4a21e2275`；`exports.txt`＝`f61b9b1e55fdc600`；`pts-gap-decl.txt`＝`32b303148aca23a9`；`PtsCache.Linux.cs`＝`e5b399fdb8742092`；`HEAD=87efb58`。
7. **本件自带的三处反腿**：① **D5**（§4.2）—— 不把"闸开（探针）可得"读成"缺省路径可得"；② **D6** 末句 —— 不把"帧变了／帧没变"任一方向读成进度（裁定三十六 (c)）；③ **§4.3** —— 不把"缺口计数下降"读成"能力前进"。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-default-chain-recon.md | sha256sum | cut -c1-16`）= `9efdc109fb649ca0`

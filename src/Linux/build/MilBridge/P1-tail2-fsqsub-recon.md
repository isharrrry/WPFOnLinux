# P1-tail2 `TASK-0302` 增量 · 钥匙 `FsQuerySubtrackDetails` —— 只读侦察 ＋ 判据先写

- **读时**：`2026-09-30T11:20+0800`（本席现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=e42b812`（现取）。
- **件指纹（现取，`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`＝`57a80e0bb51d17ea`（342451 B／4529 行／mtime `2026-09-29 22:59:12`）｜`src/WpfGfx.Linux.Native/bin/exports.txt`＝`3942a1aafa41e1ca`（669 行）｜`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`＝`26da177686acb1f0`（gitignored）｜`upstream/…/PtsHost/Pts.cs`＝`1a8575a18767a956`｜`PtsHelper.cs`＝`f2ed9552e983fed1`｜`ContainerParaClient.cs`＝`0d2e6aa79fdc035a`｜`BaseParaClient.cs`＝`e48fc11de3f65d09`｜`build/MilBridge/P1-subtrack-criteria.md`＝`01b00c39ad6f1e84`｜`P1-tail2-t0307-recon.md`＝`c14686c6572d1427`｜`P1-pfspara-report.md`＝`0e546bea6156f282`。
- **边界（照 T-A3 ②）**：只读；除本件外**未改任何仓内文件**；未改 `src/**`、未构建、未跑整腿、未跑整趟 `verify-all`、未跑 `static-jaws-check.sh`；未占显示位；大件只用 `wc`／`head`／`tail`／`grep`；未 `git add/commit/push`。
- **行号纪律**：本件所有行号**仅本次有效**（内容锚原文一并给出）。

---

## §0 结论速览（自包含）

1. **靶心 ＝ 钥匙**（承 `P1-subtrack-criteria.md` §2；本件现取复核成立）：`FsQuerySubtrackDetails` 是 10 处调用 body 里「`Assert` 之后的**第一个实招**」，其出参 `cParas` **门控**其后的 `FsQuerySubtrackParaList`（`ContainerParaClient.cs:66/95/146/193/221/278/330/377` 等）。
2. **签名契约（现取逐字）**：`Pts.cs:3735-3739`，`int FsQuerySubtrackDetails(IntPtr pfsContext, IntPtr pSubTrack, out FSSUBTRACKDETAILS pSubTrackDetails)`；出参结构 `Pts.cs:1526-1533`＝`{ FSUPDATEINFO fsupdinf; IntPtr nms; FSRECT fsrc; int cParas; }`。
3. **native 现状 ＝ 缺符号**：`nm -D --defined-only` 计数 **0**；`exports.txt` **0 命中**；源内**仅 1 处注释**（`win32_pts.c:3802`）⇒ 失败形态是 CLR **ENFE**（封送阶段抛，`PTS.Validate` 根本不执行）。
4. **入参可得性：较 `t161` 判据 §4 已发生实质变化** —— `FSPARADESCRIPTION.pfspara` 现取**已被填充**（`win32_pts.c:3779`），值是**本侧自有的子轨对象字段地址**（`wpf_pts_sub_handle(dp->sub)`，`:3746`）。但**有闸**：该填充整块在 `wpf_pts_drive_probe_enabled()` 内（`:3625`，缺省关）⇒ **闸关时 `pfspara` 仍恒 0**（新具名前置，见 §5）。
5. **M1「诚实无进展」＝ 可行，但只等于"诚实拒绝"**（本入口**无** `kstop` 字段；其"改控制流的缺省值"是 `cParas`）。**必备形态 ＝ 只导出符号 ＋ 认领入参 ＋ 出参一字不写 ＋ 失败必留痕**；`rc=0` **永不可给**（`cParas` 真值属内容层，今天无源）。
6. **本增量本波：不做实现**（本件＝只读侦察＋判据先写，即上限）。若做的最小落地步骤见 §5.3（仅登记供排期）。

---

## §1 契约与调用点现取（件:行 ＋ 原文）

### 1.1 托管声明（唯一靶心声明）

`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs`（`sha16=1a8575a18767a956`）`:3735-3739`：
```
        [DllImport(DllImport.PresentationNative)]
        internal static extern int FsQuerySubtrackDetails(
            IntPtr pfsContext,                  // IN:  ptr to FS context
            IntPtr pSubTrack,                   // IN:  ptr to subtrack
            out FSSUBTRACKDETAILS pSubTrackDetails);// OUT: subpage details
```
> 注：T-A3 ①写的「`build/PresentationFramework.Linux/Pts.cs` 声明」**现取不成立** —— 该目录下**无 `Pts.cs`**（只有 `PtsCache.Linux.cs` 等 Linux 端口件）；靶心声明在 **`PtsHost/Pts.cs`**（`Glob` 全树 `**/Pts.cs` 现取仅 1 件）。此为对任务书文字的现取更正。

### 1.2 出参结构 ＋ 相邻声明

`Pts.cs:1526-1533`：
```
        [StructLayout(LayoutKind.Sequential)]
        internal struct FSSUBTRACKDETAILS
        {
            internal FSUPDATEINFO fsupdinf;
            internal IntPtr nms;
            internal FSRECT fsrc;
            internal int cParas;
        }
```
`Pts.cs:1942-1947`：`struct FSUPDATEINFO { public FSKUPDATE fskupd; public int dvrShifted; }`（`FSKUPDATGE : int`，`Pts.cs:1934-1941`）。
`Pts.cs:3741-3747`（**紧随其后**，即"其后"那枚）：
```
        [DllImport(DllImport.PresentationNative)]
        internal static extern unsafe int FsQuerySubtrackParaList(
            IntPtr pfsContext,                  // IN:  ptr to FS context
            IntPtr pSubTrack,                   // IN:  ptr to subtrack
            int cParas,                         // IN:  size of array of para descriptions
            FSPARADESCRIPTION* rgParaDesc,      // OUT: array of para descriptions
            out int cParaDesc);                 // OUT: actual number of paragraphs
```

### 1.3 调用点（谁调它）—— 现取逐字

`ContainerParaClient.cs`（`sha16=0d2e6aa79fdc035a`）**9 处**，全部形如 `PTS.Validate(PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails));`：

| # | 行 | 所属 body | 门控其后（`cParas`） |
|---|---|---|---|
| 1 | `:47` | `:41 OnArrange()` | `:66 if (subtrackDetails.cParas != 0)` → `:70 ParaListFromSubtrack` → **`:72 ArrangeParaList`** |
| 2 | `:89` | `InputHitTest` | `:95` |
| 3 | `:142` | `GetRectangles` | `:146` |
| 4 | `:177` | `ValidateVisual` | `:193` |
| 5 | `:218` | `UpdateViewport` | `:221` |
| 6 | `:240` | `CreateParagraphResult`（**在 `/* … */` 注释块内**，`PtsHelper.ParaListFromSubtrack` 掉了一个参数 ⇒ 死码，不在册调用） | — |
| 7 | **`:271`** | **`GetTextContentRange()`** | `:277 if (subtrackDetails.cParas == 0 \|\| (_isFirstChunk && _isLastChunk))`（**叶子分支、不递归**）`else` → `:283 ParaListFromSubtrack` → `:289 HandleToObject(pfsparaclient)` |
| 8 | `:325` | `GetChildrenParagraphResults` | `:330` |
| 9 | `:375` | `GetFirstTextLineBaseline` | `:377` |

`ListParaClient.cs:46`（同族，`sha16=5e7…` 未复取）另一处同形调用（`ValidateVisual`）。⇒ **调用点合计 ≥10 处**（`ContainerParaClient` 9 ＋ `ListParaClient` 1），入参一律 `_paraHandle`。

### 1.4 native 落点（现取）

`win32_pts.c`（`sha16=57a80e0bb51d17ea`）：
- `:3802-3803`（**唯一命中，且是注释**）：`/* 🔴 下游接受者：本件无（判据 §5.5 的在册接受者＝ FsQuerySubtrackDetails（:271）与 FsQuerySubtrackParaList（PtsHelper.cs:633），二者都属 (b)、尚未实现）。`
- `grep -c 'FsQuerySubtrackDetails' src/WpfGfx.Linux.Native/src/win32_pts.c` ⇒ **1**（注释）；`nm -D --defined-only bin/libwpfwin32.so | grep -c FsQuerySubtrackDetails` ⇒ **0**；`exports.txt`（669 行）⇒ **0 命中**。
- 对照：`FsQueryTrackParaList` 在 `nm -D` ⇒ **1**、在 `exports.txt:106` 在册、在 `k_pts_entries[]:90` 在册；`FsQueryTrackDetails` 在 `exports.txt:105`＋`k_pts_entries[]:88` 在册。⇒ 入口名表 `k_pts_entries[]`（`win32_pts.c:71-91`，`WPF_PTS_ENTRY_COUNT`）**不含** `FsQuerySubtrack*`。

---

## §2 钥匙 vs 其后链（现取逐跳，仅本次有效）

**链（subtrack 路径）**：
```
消费入口（例：FlowDocumentPage.cs:549 paraClient.GetTextContentRange()）
  → ContainerParaClient.cs:260 GetTextContentRange()
  → :271 PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails)   ← 钥匙（本件靶心）
  → :277 if (subtrackDetails.cParas == 0 || (_isFirstChunk && _isLastChunk)) 叶子分支（不递归）
     else
  → :283 PtsHelper.ParaListFromSubtrack(PtsContext, _paraHandle, ref subtrackDetails, out arrayParaDesc)
       → PtsHelper.cs:629 arrayParaDesc = new FSPARADESCRIPTION[subtrackDetails.cParas]   ← 用 cParas 开数组
       → :633 PTS.Validate(PTS.FsQuerySubtrackParaList(..., subtrackDetails.cParas, rgParaDesc, out paraCount))   ← 其后
       → :636 ErrorHandler.Assert(subtrackDetails.cParas == paraCount, …)
  → :289 HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient
```
（并行一条：`OnArrange` 也走同一对 `:47`→`:66`→`:70`→`PtsHelper.cs:633`。）

**另一条上游（`_paraHandle` 从哪来）**：
```
PtsHelper.cs:179 paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack)
  → BaseParaClient.cs:65 _paraHandle = pfspara      （:61 internal void Arrange(IntPtr pfspara, …)）
```
⇒ **钥匙的入参 `pSubTrack` ＝ `_paraHandle` ＝ `FSPARADESCRIPTION.pfspara`**。

**判词（照裁定二十六 (a) 体例）**：
- **钥匙 ＝ `FsQuerySubtrackDetails`**：`Assert` 之后第一个实招；`rc` 非 0（今天＝ENFE）⇒ `PTS.Validate` 抛 ⇒ **其后的 `FsQuerySubtrackParaList` 一次都不会被调**。
- **其后 ＝ `FsQuerySubtrackParaList`**：被 `cParas` 门控（`:277`／`:330`／`:66` …），且在钥匙下游 ⇒ **只补其后 ＝ 补死码**。
- **钥匙未通是"其后不可达"的直接原因**；**钥匙通了也不保证其后可通**（其后还有 `PRECOND-PARADESC-SOURCE-MISSING(scope=subtrack-path)`）。

---

## §3 入参可得性判定（含 `pfspara` 现取状态）

### 3.1 `pfspara` 现取：**已被填**（较 `t161` 判据 §4 的"恒 0"是实质变化）

`win32_pts.c` 现取（填充体）：
```
3746:  const void *para_val = wpf_pts_sub_handle(dp->sub);
3747:  const char *para_src = "native-owned-subtrack";
3777:  memset((void *)&rg[i], 0, sizeof(rg[i]));
3779:  rg[i].pfspara       = (void *)para_val;
3780:  rg[i].pfsparaclient = (void *)dp->fsp_pl_cur;
3781:  rg[i].nmp           = (void *)dp->drive_nmp;
```
`wpf_pts_sub_handle`（`:1244-1247`）现取：`return o ? (const void *)&o->c_paras : NULL;`（**句柄＝本侧对象内 `c_paras` 字段的地址**，承 `FsQueryTrackDetails` 范式）。
`wpf_pts_sub_claim`（`:1249-1258`）现取：`p` 必须**等值于**某在册对象的 `&o->c_paras`；`NULL`／栈地址／外来值一律拒。

⇒ **判定 ①（`pfspara` 可认领）＝已成本侧真对象**：`pfspara` 现取**非零**且可被 `wpf_pts_sub_claim` 唯一认领（`[FSPARALIST-PARA] … src=native-owned-subtrack same_value=1 form=native-owned-subtrack`，`P1-pfspara-report.md` 在册，**本席未独立复算其运行期读数**）。⇒ 「钥匙入参可得性」**已不因 `pfspara=0` 而挡**。

### 3.2 但**有闸**（本件新现取，收窄 A3 ③ 的"是否已写它"）

`win32_pts.c:3625`：`else if (wpf_pts_drive_probe_enabled()) {`（填充块整块在此 `if` 内）。
`win32_pts.c:921-929`：`wpf_pts_drive_probe_enabled()` 读 `WPF_PTS_DRIVE_PROBE`，**缺省关**（`裁定三十六 (b)`）。
⇒ **收窄判定**：`pfspara` **非零仅在 `WPF_PTS_DRIVE_PROBE=1` 时成立**；**缺省（生产）路径 `pfspara` 仍恒 0** ⇒ 钥匙入参在**缺省路径**上仍为 `NULL`。
⇒ **新具名前置 `PRECOND-PFSPARA-ONLY-IN-PROBE`**（§5）。本件**不**把 §3.1 的"已可得"当成"缺省路径已可得"（`P13` 反腿，见 §4）。

### 3.3 入参可得性总判

| 入参 | 现取来源 | 可得性 |
|---|---|---|
| `pfsContext` | 本侧 doc 上下文（`wpf_pts_doc`） | **可得**（在册） |
| `pSubTrack` | `_paraHandle` ← `FSPARADESCRIPTION.pfspara` ← `wpf_pts_sub_handle(dp->sub)` | **闸开时可得且可认领；闸关时＝NULL** |
| `nms`（出参） | 需**托管句柄**（`PtsHost.cs` 该族"名"参数＝句柄） | 🔴 **native 无合法来源** ⇒ `PRECOND-NMS-UNOWNED` |
| `fsrc`（出参） | 本侧页几何（可作者） | 可得（但不属"内容"，不足以支撑 `rc=0` 的 §8 八条） |
| `cParas`（出参） | 需＝**托管孩子数真值** | 🔴 **无源**（属内容层 `S-2b`）⇒ `PRECOND-NO-LAYOUT-CONTENT-MODEL` |

⇒ **结论**：**入参面（`pSubTrack`）已通（闸开时）**；**出参面（`cParas`／`nms`）仍无源** ⇒ 钥匙**只能诚实拒绝**，不能给 `rc=0`。

---

## §4 M1「诚实无进展」判据草案（≥3 条可证伪 ＋ 反极性）

> **前置口径（写死）**：M1 的"无进展"在本入口**不等于**"合法 no-progress 输出"（那是 `FsFormatSubtrackFinite` 的 `FSFMTR` 形态，`kstop=no-progress`）；**本入口无 `kstop` 字段**（`FSSUBTRACKDETAILS` 只有 `fsupdinf/nms/fsrc/cParas`）。本入口的"改建制流的缺省值"是 **`cParas`**。⇒ **M1 的唯一诚实形态 ＝ 诚实拒绝**（返非 0 ＋ 具名留痕）。

| # | 判据（可证伪） | 反极性（必红腿） |
|---|---|---|
| **D1 零假值／出参纪律** | M1 拒绝路径 **`pSubTrackDetails` 一字不写**（不写 `cParas`／`nms`／`fsrc`／`fsupdinf`）。**禁**写任何"看起来像答案"的缺省值。 | **写 `cParas=0` 让 `rc=0` 好看** ⇒ `ContainerParaClient.cs:277` 走叶子分支、**静默丢整棵嵌套内容** ⇒ **必红（P8）**。 |
| **D2 永不假成功** | `rc=0` **仅当**能同时给出：与托管真值一致的 `cParas` ∧ `nms` 可认领 ∧ `fsrc` 非零。今天**不满足** ⇒ **必须返非 0**。 | 返 `rc=0` ＋ `cParas=0`／`cParas=1`／任何常量 ⇒ 伪成功 ⇒ **必红**。 |
| **D3 失败必留痕** | 任何拒绝返非 0 **必**打具名行（承判据 §8 拒绝行）：`[FSQSTD] rc=<int> reason=<具名> entry=FsQuerySubtrackDetails ctx=<hex> psub=<hex> calls=<n>`；并让该入口 `gap=` 恰涨 1。 | **静默 stub**（返非 0 但零痕迹）⇒ 与"真 0 次调用"不可分 ⇒ **必红**（照裁定二十三 ①：留痕做在 native 侧）。 |
| **D4 身份只许靠来源证据** | `psub` 必须能被本侧台账 `wpf_pts_sub_claim` **唯一认领**，且与同 run 产出行（`[FSPARALIST-FILL].h0` 或 `[FSPARALIST-PARA].psub`）**同值**。 | 靠 `rc`／数值大小判身份 ⇒ **必红**（`t160` ABA 反腿：`rc` 与数值都无法辨身份）。 |
| **D5 闸关与闸开分开报** | 闸关 ⇒ `reason=null-subtrack`（`psub=(nil)`）；闸开未造型 ⇒ `reason=no-layout-content-model`；**`calls=0` 与 `calls>0` 分开报**。 | 把闸关的"没走到"记成"拒绝成功"／把 `calls=0` 当"跑过" ⇒ **必红**（P10／P12）。 |
| **D6 ≥2 独立样本** | ≥2 独立 PID／启动时刻，判词**相同**（裁定三十八）。 | 单样本当机制 ⇒ **必红**（P9）。 |

> **P13 反腿（本件新立，针对 §3.2）**：把"**闸开时** `pfspara` 非零可得"读成"**缺省路径**入参可得" ⇒ **必红**（混淆探针副作用与产品行为，与 `N4`／帧面假绿同族）。

**必备形态（逐项）**：
1. **符号导出**：`nm -D`／`exports.txt` 命中 ≥1（否则到不了实现，仍 ENFE）。
2. **入参**：读 `pfsContext`（在册 doc）；`pSubTrack` 用 `wpf_pts_sub_claim` 认领（拒 `NULL`／栈地址／外来值）。
3. **出参**：`pSubTrackDetails`（`fsupdinf/nms/fsrc/cParas`）—— 拒绝路径**一字不写**（D1）。
4. **计数**：`calls=`（该入口被调次数，另立 `g_pts_calls[]` 项）／`ok=`／`gap=`／`reason` 计数。
5. **`kstop`**：**不适用**（本入口无该字段）；对 T-A3 ④ 的"`kstop` 等"照此写死 —— 本入口对应的"改建制流缺省值"是 `cParas`（D1）。
6. **收尾同侪**：本入口是**查询**，无配对销毁入口；但**导出即改 `exports.txt`**（生成件，须同趟对拍逐名无消失，照裁定二十三 ⑤）。

---

## §5 阻塞前置清单 ＋ 本波做/不做 ＋ 若做的最小落地

### 5.1 具名阻塞前置（逐条，带射程）

| 前置 | 射程 | 状态／归属 |
|---|---|---|
| `PRECOND-NATIVE-ENTRY-MISSING(FsQuerySubtrackDetails)` | `nm -D`＝0／`exports` 0 命中 | **本波可解**（导出即解），**但解了 ≠ 通**（见下） |
| `PRECOND-NO-LAYOUT-CONTENT-MODEL` | `cParas` 需＝托管孩子数真值 | **成立**（`t185`：内容层无源）⇒ 钥匙只能诚实拒绝 |
| `PRECOND-NMS-UNOWNED` | `nms` 出参要求**托管句柄** | **成立**（native 无合法来源）⇒ 挡 `rc=0` |
| **`PRECOND-PFSPARA-ONLY-IN-PROBE`（本件新立）** | `FSPARADESCRIPTION.pfspara` 的填充体整块在 `wpf_pts_drive_probe_enabled()` 内（`:3625`，缺省关） | **成立**：缺省路径 `pfspara` 仍恒 0（探针副作用 vs 产品行为） |
| `PRECOND-PARADESC-SOURCE-MISSING`（`scope=subtrack-path`） | `PtsHelper.cs:174-180` 那条 `rcPara.dv` 计算 | **未解除**；需实现 `FsQuerySubtrackParaList`（属 `S-2b`） |
| `PRECOND-HOST-CONSUME-OBSERVATORY-OUT-OF-DOMAIN` ＋ `PRECOND-NO-MANAGED-SIDE-WRITER` | 托管 `.cs`；粒度＝单次调用 | **未解除**（托管侧协作者无落点） |
| `PRECOND-FRAME-DETERMINISM` | `fr_sha` 类要件 | **未满足**（冻结令维持，裁定四十二 (b)） |

### 5.2 「本增量本波做/不做」结论 ＝ **本波不做实现**

据以下五条现取理由：
1. **本件即上限**：T-A3 ① 明写本任务「**只写判据与可行性（不实现）**」⇒ 载体（本件）＝不改产品能得到的**全部**。
2. **只补其后 ＝ 补死码**（承 T-A30 7-recon §5.1-1）；**补钥匙也仍只能拒绝**（`cParas`／`nms` 无源，§3.3）。
3. **属 `S-2b`（内容层）一族**：`HANDOFF §5` 现取「`S-2b` 判**本波不做**」。
4. **导出即改生成件 `exports.txt`**，且托管侧协作者无落点（§5.1 后两条）⇒ 不属本增量写域。
5. **帧面冻结令未解** ⇒ 任何"排版结论"类读数不可判。

### 5.3 若日后做 —— 最小落地步骤（**本波不做，仅登记供排期**）

**M1 ＝ 只导出 ＋ 认领入参 ＋ 诚实拒绝 ＋ 留痕**（照 §4 D1–D6）：
1. **先立判据**（本件 §4）→ 实现 → 独立复核。
2. **实现**：`win32_pts.c` 加 `int FsQuerySubtrackDetails(void *ctx, void *pSubTrack, void *out)`：① `pSubTrack==NULL` ⇒ `reason=null-subtrack`；② `wpf_pts_sub_claim` 失败 ⇒ `reason=unclaimable-subtrack`；③ 认领成功但未造型（`o->formatted==0`）⇒ `reason=no-layout-content-model`；④ **三路都返 `WPF_PTS_ERR_NOT_IMPLEMENTED` ＋ 出参一字不写 ＋ 具名 `[FSQSTD]` 行 ＋ 计数**；**永不给 `rc=0`**（D2）。
3. **同趟**：`bin/exports.txt` 逐名对拍零消失（＋1 名）；**不宣布排版成功**；窗内外两腿／`≥2` 独立样本佐证。
4. **判据面把"钥匙被调"与"其后被推开"严格分成两个判词**（`P5`）：前者＝本入口 `calls>0`；后者＝`[FSPARALIST-FILL].entry=FsQuerySubtrackParaList` 出现（**今天恒 0**）。

---

## §6 边界 · `NOINFO` · 主动披露

1. **未跑**构建／腿／整趟 `verify-all`／`static-jaws-check.sh`；未占显示位；未 `git add/commit/push`；唯一写入＝本件。
2. **`NOINFO`（逐条给消掉条件）**：① 钥匙运行期真腿读数（**今天结构性不可达** —— ENFE 在封送阶段抛，取不到）；② `pfspara` 在现件真值（本件未跑腿；`P1-pfspara-report.md` 的读数**引自该件，本席未独立复算**）；③ `nms` 出参的合法来源（`NOINFO-NMS-UNOWNED`）；④ `cParas` 真值来源（属内容层）。
3. **前提不符（如实记）**：T-A3 ① 写「`build/PresentationFramework.Linux/Pts.cs` 声明」**现取不成立**（该目录无 `Pts.cs`）⇒ 靶心声明在 `PtsHost/Pts.cs`（§1.1）。
4. **引他人读数（标"未独立复算"）**：`P1-pfspara-report.md`（`t162`）的 `[FSPARALIST-PARA]`／`[FSPARALIST-SUB-SELFTEST]` 运行期读数、`P1-subtrack-criteria.md`（`t161`）的 `t160` 引读数均**引自其载体**；本件**自算**的只有 §0／§1／§3 的 `sha16`／`nm -D`／`grep -c`／整行现取。
5. **代际**：`win32_pts.c`＝`57a80e0bb51d17ea`（与 `P1-tail2-t0307-recon.md` **同代**）；`.so`＝`26da177686acb1f0`；`exports.txt`＝`3942a1aafa41e1ca`／669 行。
6. **本件自带的两处反腿**：① `P13`（§4）—— 不把"闸开可得"读成"缺省可得"；② `P5` —— 不把"钥匙被调"读成"其后已推开"。

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-fsqsub-recon.md | sha256sum | cut -c1-16`）= `9349b344e80b809a`

# P1-tail2 `TASK-0302` 增量 · 再评 `FsQuerySubtrackDetails` 真填可行性（链驱动后）—— 只读侦察 ＋ 判据先写

- **读时**：`2026-09-30T12:20+0800`（本席现取）。
- **树**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`HEAD=727b3d1`（现取）。
- **件指纹（现取，`sha256` 前 16 位）**：`src/WpfGfx.Linux.Native/src/win32_pts.c`＝**`c0dda70160ff1dc6`**（349884 B／4605 行／mtime `2026-09-30 12:02:38`）｜`src/WpfGfx.Linux.Native/bin/exports.txt`＝`f61b9b1e55fdc600`（**670 行**）｜`bin/libwpfwin32.so`＝**`33c3bb7e8365835d`**（406824 B）｜`upstream/…/PtsHost/Pts.cs`＝`1a8575a18767a956`｜`PtsHelper.cs`＝`f2ed9552e983fed1`｜`ContainerParaClient.cs`＝`0d2e6aa79fdc035a`｜`ListParaClient.cs`＝`d3de181c357a9458`｜`tools/pts-gap-decl.txt`＝`c963dc79e234278a`。
- **边界（照 `T-A11` ②）**：**只读**；除本载体外**未改任何仓内文件**；未构建、未跑腿、未占显示位、未跑整趟 `verify-all`、未跑 `static-jaws-check.sh`；`git status --porcelain` 现取仅两处 `??`（`tasks-tail2/T-A11.md` 任务书 ＋ 在册既有 `evidence/arm_A/app_g1.log`，**均先于本件存在**）。
- **行号纪律**：本件所有行号**仅本次有效**（内容锚原文一并给出）。

---

## §0 结论速览（自包含）

1. **上游状态已换代**：`T-A9` 已让**缺省路径三级链驱动**落地并把 `FsQuerySubtrackDetails` **导出**（`exports.txt:105`／`nm -D` 命中 **1**，T-A3 的"缺符号"已解）——但只到**诚实拒绝**（`[FSQSTD] rc=-10000 reason=no-layout-content-model`，`T-A10` 现取 **1217** 行）。**本件＝在链已驱动之后重估"出参四格是否有源"**。
2. **调用点与入参现取**：调用点 ≥10 处（`ContainerParaClient.cs` 9 ＋ `ListParaClient.cs` 1），入参一律 `_paraHandle`；**链驱动后**该值**非零且可被本侧台账唯一认领**（`psub=0x…6514`／`src=native-owned-subtrack`／`claim=ok`）⇒ **入参面已通**（`T-A3` §3.3 的"闸关时＝NULL"在缺省路径已因 `T-A9` 翻闸而不复成立）。
3. **出参四格逐格判（链驱动后）**：
   - `fsrc`＋（透传）`nms` —— **有源**（`fsrc`＝本侧几何作者；`nms`＝本 run `+80` 的 live `nmSegment` 句柄透传）；
   - `fsupdinf` —— **无源**（`dvrShifted` 无源；`fskupd` 未造型下无诚实取值；且**全树无消费者**）；
   - **`cParas` —— 仍无源**（承重格）：链驱动的是"**取首段＋建客户端**"，**不是造型**；`dp->sub->c_paras` 恒 0、`formatted` 恒 0；链**未枚举孩子数**。
4. **结论 ＝ `只能部分`**：四格中 **2 格有源、1 格半/无源（无消费者）、1 格（`cParas`，门控下游的承重格）无源** ⇒ **`rc=0` 仍不可给**（写 `cParas=0` ⇒ `ContainerParaClient.cs:277` 走叶子支、**静默丢整棵嵌套**＝`P8` 必红；写非零常量＝伪装真值）。⇒ **本波诚实形态＝维持 `T-A9` 的"诚实拒绝"**；真填的**唯一前置**＝`cParas` 的源（具名 `PRECOND-NO-SUBTRACK-CHILD-COUNT-SOURCE`）。判据草案见 §4，`P8` 落点见 §5。

---

## §1 调用点与入参现取

### 1.1 出参结构（现取逐字）

`upstream/…/PtsHost/Pts.cs`（`sha16=1a8575a18767a956`）`:1526-1533`：
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
`:1942-1947` `struct FSUPDATEINFO { public FSKUPDATE fskupd; public int dvrShifted; }`；`:1934-1941` `enum FSKUPDATE : int { fskupdInherited=0, fskupdNoChange=1, fskupdNew=2, fskupdChangeInside=3, fskupdShifted=4 }`；`:849-855` `struct FSRECT { int u; int v; int du; int dv; }`。
⇒ 布局：`fsupdinf`@+0（8 B）／`nms`@+8（8 B）／`fsrc`@+16（16 B）／`cParas`@+32（4 B），`sizeof=40`。**native 侧已编译期钉死同布局**（`win32_pts.c:3960-3970` 的 `wpf_pts_fssubtrackdetails` ＋ 4 条 `_Static_assert`：`sizeof==40`／`nms==8`／`u==16`／`c_paras==32`）⇒ **偏移面本件不需要新实测**（`T-A3` §4 的"只许实测"已由 `T-A9` 落地件完成）。

### 1.2 调用点（谁调它，现取逐字；`ContainerParaClient.cs` `sha16=0d2e6aa79fdc035a`）

| # | 行（整行锚） | body | 门控其后（`cParas`） |
|---|---|---|---|
| 1 | `:47 PTS.Validate(PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails));` | `:41 OnArrange()` | `:66 if (subtrackDetails.cParas != 0)` → `:70 ParaListFromSubtrack` → `:72 ArrangeParaList(…, subtrackDetails.fsrc, …)` |
| 2 | `:89` | `InputHitTest` | `:95` → `:102 InputHitTestParaList(…, ref subtrackDetails.fsrc, …)` |
| 3 | `:142` | `GetRectangles` | `:146` |
| 4 | `:177` | `ValidateVisual` | `:193` |
| 5 | `:218` | `UpdateViewport` | `:221` |
| 6 | `:240` | `CreateParagraphResult`（注释块内，死码） | — |
| 7 | **`:271`** | **`GetTextContentRange()`** | `:277 if (subtrackDetails.cParas == 0 \|\| (_isFirstChunk && _isLastChunk))`（叶子支）`else` → `:283 ParaListFromSubtrack` → `:289 HandleToObject(arrayParaDesc[i].pfsparaclient)` |
| 8 | `:325` | `GetChildrenParagraphResults` | `:330` |
| 9 | `:375` | `GetFirstTextLineBaseline` | `:377` |

`ListParaClient.cs`（`sha16=d3de181c357a9458`）`:45-46` 同形（`ValidateVisual`），`:65 if (subtrackDetails.cParas != 0)`，`:78 for(int index=0; index<subtrackDetails.cParas; index++)`。
⇒ **调用点合计 ≥10 处**，入参一律 `_paraHandle`。`:271` 仍是 `:268 Invariant.Assert(elementOwner != null, "Expecting TextElement as owner of ContainerParagraph.")` 之后的**第一个实招**（`T-A3` 判词在本代**复核成立**）。

### 1.3 入参 `pSubTrack` 的现取来源（链驱动后）

链（同 `T-A3` §2，现取复核）：
```
PtsHelper.cs:179 paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack)
  → BaseParaClient.cs:65 _paraHandle = pfspara
  → ContainerParaClient.cs:47/271 FsQuerySubtrackDetails(ctx, _paraHandle, out …)
```
`FSPARADESCRIPTION.pfspara` 的现取填充（`win32_pts.c`）：
```
3762:  const void *para_val = wpf_pts_sub_handle(dp->sub);
3795:  rg[i].pfspara       = (void *)para_val;
3796:  rg[i].pfsparaclient = (void *)dp->fsp_pl_cur;
3797:  rg[i].nmp           = (void *)dp->drive_nmp;
```
`wpf_pts_sub_handle`（`:1255-1258`）＝`&o->c_paras`（**本对象内字段地址**）；`wpf_pts_sub_claim`（`:1260-1271`）＝指针等值于某在册对象的该字段地址（NULL／栈地址／外来值**必拒**）。
**现取运行期读数**（`T-A9`／`T-A10` 在册，**本席未独立复算其运行期值**）：
```
[FSPARALIST-PARA] psub=0x627332fd6514 … src=native-owned-subtrack same_value=1 … v=ACCEPT-OTHER
[FSQSTD] rc=-10000 reason=no-layout-content-model entry=FsQuerySubtrackDetails ctx=0x6273325cd160 psub=0x627332fd6514 calls=1 ok=0 gap=1 null=0 unclaim=0 unformatted=1 out=UNWRITTEN bytes=0
```
⇒ 判定：**入参面已通** —— `pfspara` **非零**、**可被本侧台账唯一认领**（`claims=1 rejected=0`）、且 `[FSQSTD].psub` **逐字等于** `[FSPARALIST-FILL]` 的 `pfspara`（值流到了消费者）。⇒ `T-A3` §3.2 的 `PRECOND-PFSPARA-ONLY-IN-PROBE` **在缺省路径上已解除**（`T-A9` 翻闸 + 驱动链）；本件**不再重开**该前置。

---

## §2 出参可得性重估 —— 四格逐格（链驱动后）

> **判据口径（写死）**：一格"**有源**"＝存在**本侧为作者**的字段/计数、或**本 run 内由托管产出、原样转交**的值（透传），且能给出**现取证据**（件:行 ＋ 内容锚）；"**无源**"＝本侧既非作者、本 run 也无产出，**必须具名前置**。
> **消费者事实（现取，全树）**：`grep -rn 'subtrackDetails\.'` **只命中两类** —— `.cParas`（门控）与 `.fsrc`（几何）；**`FSSUBTRACKDETAILS.nms`／`.fsupdinf` 全树０消费者**。

| 格 | 偏移 | 托管消费者 | **链驱动后是否有源** | 现取证据 / 具名前置 |
|---|---|---|---|---|
| `fsrc` | +16 | **有**（`:72`／`:102`） | **✅ 有源（本侧为作者）** | 本侧页几何＝`768×576`：`win32_pts.c:3563 #define WPF_PTS_FSP_FIN_DU 768`／`:3564 …FIN_DV 576`；`:3586 p->pg_w = WPF_PTS_FSP_FIN_DU; p->pg_h = WPF_PTS_FSP_FIN_DV;`；同形先例 `FsQueryPageDetails` `:3421 d->r_u=0; d->r_v=0; d->r_du=pg->pg_w; d->r_dv=pg->pg_h;`。⚠️ 属**本侧自定几何**（`NOINFO-FSGEOMETRY-LAYOUT`，`t165`）⇒ 不与上游 ABI 可比。 |
| `nms` | +8 | **无**（全树０） | **✅ 有源（透传）** | `T-A9` 链的 `+80` 交出 live `nmSegment`（`ContainerParagraph` 句柄），本侧原样存：`win32_pts.c:232 const void *drive_nmseg;`／`:1886 if(!((const void*)d->drive_nmseg)) d->drive_nmseg=(const void*)nmSeg1;`；原生注释直接点名为 `nms`：`:1862 …\`nms\` ＝ 第一跳 \`+80\` 交出的 \`nmSegment\`…`。⚠️ 本侧**无能力校验**托管句柄（`NOINFO-HANDLE-VERIFY-AT-ENGINE`，`t173`）—— 与 `pfsparaclient` **同族**（本 run 托管产出、原样转交）。⚠️ **无消费者** ⇒ 无独立验证。 |
| `fsupdinf` | +0 | **无**（全树０） | **❌ 无源**（半：`fskupd` 可声明但无独立读数；`dvrShifted` 无源） | 本侧**不记录**任何"更新/位移"状态（无 `fskupd`／`dvrShifted` 相关字段或计数）。⇒ 具名 **`PRECOND-NO-UPDATE-TRACKING`**；另具名 **`NOINFO-FSUPDINF-CONSUMER`**（无消费者 ⇒ 即便取值也无可证伪面）。 |
| **`cParas`** | +32 | **有（承重）**（`:66/:95/:146/:193/:221/:243/:277/:330/:377` 门控 ＋ `PtsHelper.cs:629 new FSPARADESCRIPTION[cParas]`） | **❌ 无源（链驱动后仍无源）** | 子轨对象有该字段但**恒 0、`formatted` 恒 0**：`win32_pts.c:1236 o->magic=…; o->c_paras = 0; o->formatted = 0;`；设计注释自己写死：`:1206 ⚠️ \`formatted\` **今天恒 0**：本对象**未被造型** ⇒ \`c_paras\` 不是"0 个孩子"的断言`。链**只驱动到"首段"**（`+136` 的 `nmp1`＝first para，`:1875`），**未枚举孩子数**；`FSIMETHODS` 17 槽**无"数孩子"之槽**（`t163` 现取）。⇒ 具名 **`PRECOND-NO-SUBTRACK-CHILD-COUNT-SOURCE`**。 |

**四格小结**：**`cParas`（承重格）无源**是唯一挡住 `rc=0` 的格；另三格中 `fsrc` 有源（本侧作者）、`nms` 有源（透传）但**无消费者**、`fsupdinf` 无源且无消费者。**"部分有源"成立**。

> **反腿（本件自用，`P13` 同族）**：把 `nms`／`fsrc` 的"有源"读成"整入口可返 `rc=0`" ⇒ **必红**（承重格 `cParas` 无源 ⇒ 无 `rc=0`）。

---

## §3 最小可行 —— 诚实实现形态（部分有源）

> **前置口径（写死）**：`cParas` 是**唯一门控下游**的格（`:277` 的 `cParas==0` ⇒ 叶子支、**静默丢整棵嵌套**；`cParas!=0` ⇒ `ParaListFromSubtrack`）。⇒ **本入口的"改建制流缺省值"是 `cParas`**（承 `T-A3` §4）。

| 面 | 判定 |
|---|---|
| **可填（若真填）** | `fsrc`（本侧几何，作者＝本侧）＋ `nms`（透传 `+80` 段句柄）。**但二者都不承重**（`nms` 无消费者；`fsrc` 仅在 `cParas!=0` 的分支才被读）。 |
| **必须拒绝** | **`cParas` 无源** ⇒ 因此 **`rc=0` 不可给**；**禁**写 `cParas=0`（骗 `rc=0` ⇒ `:277` 叶子支、静默丢嵌套 ⇒ `P8` 必红）；**禁**写非零常量（伪真值 ⇒ `:629` 开错长数组、下游 `FsQuerySubtrackParaList` 撞 ENFE／`PtsHelper.cs:636` 的 `Assert(cParas==paraCount)` 必炸）。 |
| **零假值／永不假成功／失败必留痕** | 拒绝路径 `pSubTrackDetails` **一字不写**（含**不得**"半填三格" —— 返 `rc≠0` 时消费者虽不读，但半填是"看起来像答案"的缺省值）；一律返非 0；必打具名 `[FSQSTD]` 行 ＋ `gap` 恰涨 1。 |
| **`fsupdinf`** | 无源 ⇒ **不写**（无消费者、无可证伪面 ⇒ 具名 `NOINFO-FSUPDINF-CONSUMER`）。 |
| **最小落地形态（本波）** | **＝ `T-A9` 现状**（`win32_pts.c:3979-4003` 的"认领入参 ＋ 三路拒绝 ＋ 出参零写"）**一字不改**。**本波不新增实现**：三格"有源"**不构成**返 `rc=0` 的条件（承重格仍无源），单独把 `fsrc`／`nms` 填进**拒绝路径**无收益且违 `D1`。 |

> **真填（`rc=0`）的候选路（本波不做，仅登记）**：唯一能把 `cParas` 变"有源"的路＝**本侧段账**（`LM-1`／`M2` 的 `wpf_pts_lm1_led[]`，今天在 `#if WPF_PTS_FSP_PL_DVR`／`_M2` 内、缺省 0 ⇒ **编译期不在产物**）由**同一权威**写 `dp->sub->c_paras`／`formatted`，且**粒度写明为"本侧驱动计数"（一次驱动＝一段）而非托管真值**；**并须同步**实现 `FsQuerySubtrackParaList`（否则 `:283` 一进去就在 `PtsHelper.cs:633` 撞未实现的入口／`PtsHelper.cs:636` 的 `Assert` 必炸）。⇒ **"推进一格"＝两个入口（`FsQuerySubtrackDetails` ＋ `FsQuerySubtrackParaList`）＋ 一条段账权威**，本波不做。

---

## §4 结论 ＋ 判据草案

### 4.1 结论 ＝ **`只能部分`**

**边界（写死）**：出参四格中 **2 格有源**（`fsrc`＝本侧作者；`nms`＝透传）、**1 格无源且无消费者**（`fsupdinf`）、**1 格无源且承重**（`cParas`）⇒ **`rc=0` 仍不可给**；`T-A9` 的"诚实拒绝"是**本波唯一诚实形态**。⇒ 本波**不动实现**；真填的**唯一前置**＝`cParas` 的源（`PRECOND-NO-SUBTRACK-CHILD-COUNT-SOURCE`）＋ 下游入口（`FsQuerySubtrackParaList` 仍缺符号）。

### 4.2 判据草案（`D1–D6`，可证伪 ＋ 反极性；只准在**缺省路径**取数）

| # | 判据 | 反极性（该红必红） |
|---|---|---|
| **D1 承重格无源 ⇒ 整入口拒绝** | 缺省路径下 `FsQuerySubtrackDetails` 现取**必返非 0**（`cParas` 无源 ⇒ 无 `rc=0`）；`[FSQSTD] ok=0` 恒 0。 | 返 `rc=0` ＋ `cParas=0` ⇒ `ContainerParaClient.cs:277` 走叶子支、**静默丢整棵嵌套内容** ⇒ **必红（`P8`）**；`cParas=` 任一常量 ⇒ 伪真值 ⇒ **必红**。 |
| **D2 零假值／出参纪律** | 拒绝路径 `pSubTrackDetails` **一字不写**（`out=UNWRITTEN bytes=0` 可机读）；**禁**"半填三格后返非 0"。 | 给拒绝路径补一句 `*(int*)((char*)out+32)=0`（或写 `fsrc`／`nms`）⇒ 反腿必红（把"没答案"伪装成"有答案"）。 |
| **D3 失败必留痕** | 任何拒绝**必**打具名 `[FSQSTD] rc=<int> reason=<具名> … calls= ok= gap= null= unclaim= unformatted= out=UNWRITTEN bytes=0`，且 `gap` **恰涨 1**。 | **静默 stub**（返非 0 零痕迹）⇒ 与"真 0 次调用"不可分 ⇒ **必红**（裁定二十三 ①）。 |
| **D4 有源格只许靠来源证据** | 若（将来真填）写 `nms`／`fsrc`：`nms` 必须**逐字等于**同 run `[DRIVE-PROBE2] … nms136=<hex>` 或 `[DRIVE-PROBE-T3] … seg=<hex>` 产出的值；`fsrc` 必须**逐值等于**本侧声明几何（`[FSQSTD-SRC] du=768 dv=576`）。 | 靠 `rc`／数值大小／"看起来像句柄"判身份 ⇒ **必红**（`t160` ABA 反腿：`rc` 与数值都无判别力；句柄本身是小整数 `0x1..0x5` 形态）。 |
| **D5 闸关与闸开分开报（`P13`）** | 显式 `WPF_PTS_DRIVE_PROBE=0` ⇒ 链不驱、`pSubTrack==NULL` ⇒ `reason=null-subtrack`；缺省（链驱）⇒ 认领成功但未造型 ⇒ `reason=no-layout-content-model`。**两路判词不同**。 | 把闸关的"没走到"记成"拒绝成功"／把 `calls=0` 当"跑过" ⇒ **必红**（`P10`／`P12`）。 |
| **D6 ≥2 独立样本 ＋ 幂等双调** | ≥2 独立 PID／启动时刻，判词**相同**；本入口**查询**语义 ⇒ 双调现取（禁沿用非幂等结论）。 | 单样本当机制 ⇒ **必红**（`P9`）。 |

**（`D4` 的 `[FSQSTD-SRC]` 行为本件建议：若日后真填，把 `nms`／`fsrc` 的来源值同趟打进该行 —— 但本波不实现。）**

---

## §5 生成件 `P8` 落点（若涉）

- **符号面**：`FsQuerySubtrackDetails` **已在册**（`bin/exports.txt:105`＝`f61b9b1e55fdc600`／670 行；`nm -D --defined-only` 命中 **1**；源内名表 `win32_pts.c:91 "FsQuerySubtrackDetails",`）⇒ 本件**不动导出面**。
- **若日后真填涉**：`FsQuerySubtrackParaList`（现取 `exports.txt`／`nm -D` **均 0**）需成为**新导出** ⇒ **`P8` 落点＝`bin/exports.txt`（重建刷新；由 `build-shim.sh --symbols` 生成）＋ 声明面 `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（`c963dc79e234278a`）＋ 源内 `k_pts_entries[]`／`WPF_PTS_ENTRY_COUNT`**（同趟逐名对拍零消失）。
- **托管侧生成件**：`FsQuerySubtrackParaList` 的消费者 `PtsHelper.cs` 是**上游逐字件**（`git ls-files` 跟踪，`f2ed9552e983fed1`）⇒ 若需改托管侧，**禁手工改**，`P8` 落点＝生成器 `build/MilBridge/tools/reapply-patches.py` 的 needle 批次／`PTSCACHE_EDITS`（照 `T-W1`／`PtsCache.Linux.cs` 形制）。（本件**不改**任何 `.cs`／生成件。）

---

## §6 边界 · `NOINFO` · 主动披露

1. **未跑**构建／腿／整趟 `verify-all`／`static-jaws-check.sh`；未占显示位；未 `git add/commit/push`；**唯一写入＝本件**。
2. **`NOINFO`（逐条给消掉条件）**：`NOINFO-FSUPDINF-CONSUMER`（`fsupdinf` 全树０消费者；消掉条件＝消费者出现）；`NOINFO-HANDLE-VERIFY-AT-ENGINE`（本侧无能力校验托管句柄；`t173` 在册）；`NOINFO-FSGEOMETRY-LAYOUT`（`fsrc` 是本侧自定几何，不与上游 ABI 可比）；`NOINFO-FSUPDINF-SEMANTICS`（未造型下 `fskupd` 无诚实取值）。
3. **引他人读数（标"未独立复算"）**：`T-A9` 载体 `P1-tail2-default-chain-impl-report.md`（自证 `48567d93603a3ad6`）与 `T-A10` 载体 `P1-tail2-rearm-recon.md`（自证 `0e82d531591014d1`）的运行期读数（`[FSPARALIST-FILL]`／`[FSQSTD]` 值）**引自其载体**；本件**自算**的只有 §1／§2／§5 的 `sha16`／`grep`／`nm`／整行现取。
4. **代际**：`win32_pts.c`＝**`c0dda70160ff1dc6`**（＝`T-A9` 交付态，**与 `T-A3` 件内 `57a80e0bb51d17ea` 不同代** —— `T-A3` 判词在其代有效，本件按现取复核）；`.so`＝`33c3bb7e8365835d`；`exports.txt`＝`f61b9b1e55fdc600`／670 行。
5. **本件自带反腿**：① §2 —— 不把"`nms`／`fsrc` 有源"读成"整入口可返 `rc=0`"（`P13` 同族）；② §4-`D1` —— 不把"三格有源"当成"`cParas` 有源"。
6. **对 `T-A3` 判词的两处现取更新**：① `PRECOND-PFSPARA-ONLY-IN-PROBE` **已解除**（缺省路径链已驱、`pfspara` 非零可认领，§1.3）；② `PRECOND-NATIVE-ENTRY-MISSING(FsQuerySubtrackDetails)` **已解除**（`exports.txt:105`／`nm -D` 命中 1）；**新增** `PRECOND-NO-SUBTRACK-CHILD-COUNT-SOURCE`（承重格 `cParas` 无源）。

---

SELF-SHA16 （口径 = `head -n -1 build/MilBridge/P1-tail2-fsqstd2-recon.md | sha256sum | cut -c1-16`）= `8e89742b42de3f11`

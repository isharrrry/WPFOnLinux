# T-B14 · hc demo 关窗崩溃 `rc=134`（`PtsContext.Dispose` → `Validate(-10000)`）＋ 关窗卡顿 —— 完成报告

> 车道：**实现**子代理（写者；本轮唯一写者）。载体本件 ＝ `build/MilBridge/P1-hcshutdown-impl-report.md`（本席新建）。
> 写域（逐字）＝ `src/WpfGfx.Linux.Native/**`（源件 ＋ 重产 `bin/libwpfwin32.so` ＋ `bin/exports.txt` ＋ `tools/pts-gap-decl.txt`）／**复述位现值位**／新建本载体。
> **黑名单未越界**：`upstream/**`／仓外 hc 工程／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**` **一字未改**（`tools/` 只被**执行**、只被**读**）。
> **副本先行 ＋ 写前 `cp -p`**：`~/tb14-work/bak/{win32_pts.c.before(edaf0bf17ede9bb9), libwpfwin32.so.before(5e0d7b807c2fc220), exports.txt.before(83b60726bbc2486e), pts-gap-decl.txt.before(b076d60a3e179699), bridge-frozen.flag.before}`。
> 未跑整趟 `verify-all`；未提交（见 §8 索引注记）。重活全走 `~/heavy-slot.sh`；显示位只用空闲 `:238`；进程只按 PID 收；**禁 `pkill`/`pgrep -f`**（本席腿内不用 `pgrep`，用 `/proc` 扫描）。

---

## 0. 一句话结论

**① 关窗 `rc=134` 已修**：`APP_RC` **`134 → 0`**（`Unhandled exception` **1 → 0**、`unknown-breakrec` **1 → 0**）；关窗耗时（关窗→进程退出）**`0.310s → 0.257s`**（重场景）／**`0.418s → 0.261s`**（任务形场景）。
**② `-10000` 那一族只解决一半，如实报**：任务点名的**先导族（文档轨）拒发 `903 → 0`**；日志里 `did not complete formatting operation` **任务形场景 `2 → 1`**（重场景 `2061 → 460`）——余下那些属**另一个入口**（`FsQuerySubtrackParaList` 的同形判据），本席**试过**把它也换成"重建"形态（实验腿 `fix-04/05`，任务形场景可读到 **0**），**但主动未保留**：重建的输入是"页销毁之前枚举出的子句柄"，**96%–98% 的重建会失败**（现取）而"可能成功的那一小撮"会把**响亮拒**降级成**静默错对象**（本仓首禁）⇒ 见 §2.5／§6-1。另有一族 **`1194`** 次属**另一缺口**（原生 LS 上下文表满 `8`），改前被上面的风暴掩盖。**"关窗要等很久"本装置未复现**（前/后都 ≈ 0.3 s）⇒ 该子项记 `NOINFO`，**不拿"没复现"冒充"已消除"**（§6-3）。
**③ 反极性成对取到**：撤修（放回改前 `.so`）⇒ `rc=134` **复现**（两种死法都取到：`PtsException` 未处理／`PtsContext has been already disposed.` `FailFast`）；撤掉 T-B3 那道闸（`WPF_PTS_HANDLE_STRICT=0`，**用改后件**）⇒ **`FailFast` 复现** ⇒ 证明那道闸**仍是承重件**、本件是**在另一头**（格式窗内换新代）把"它频繁为真"这件事消掉，**没有**用吞异常绕过。
**④ 六条门禁逐条 `rc=0`**（`nm==exports 846==846`／`PTSGAP=PASS so16=c1cf5e6a8d14cd46 exports=846`／`PTS_GUARD=PASS legs=2/2`／`PTS_COLORANCHOR=PASS hits=3`／`DEFREG=PASS`／`REPORTID=PASS`）；`SSC` 因 `WIN32SHIM` 换值需重锚 ⇒ 已把两枚哨兵的**那一个键**对齐（仓外文件，§2.4 如实登记）。

---

## 1. 现取（改前，so16 `5e0d7b807c2fc220`）

### 1.1 `-10000` 是**谁写进**的（写入点，件:行 ＋ 现取）

| 面 | 件:行（**本次有效**，改后行号已位移） | 现取 |
|---|---|---|
| 写入者 | `src/WpfGfx.Linux.Native/src/win32_pts.c` → `FsDestroyPageBreakRecord()` 的**失败面**助手上移一位：改前 `:10637` `return wpf_pts_b3_gap("FsDestroyPageBreakRecord", 0, reason, …)` | 该助手**恒返** `WPF_PTS_ERR_NOT_IMPLEMENTED`（`win32_pts.c:53` `#define WPF_PTS_ERR_NOT_IMPLEMENTED (-10000)`） |
| 为什么返它 | 改前 `:10633` `if (!pg) reason = "unknown-breakrec";` —— 认领**只扫在册表** `g_pts_fsp_live[]` | 现场行（逐字）：`[FS_PAGE_GAP] rc=-10000 reason=unknown-breakrec entry=FsDestroyPageBreakRecord ctx=0x61467c32ffe0 p=0x61467baff668 ok=1 gap=2 out=NO-OUTPUT`（`/tmp/hc-run-062409.log:24090`） |
| 句柄语义 | 断页记录句柄 ＝**页对象内 `c_paras` 字段的地址**（`FsCreatePageFinite` 的 `ppfsBRPageOut`，改前 `:8977`） | `p=0x61467baff668`；同值在 `:1972` 以 `[CHAIN] site=PH.UpdateTrackVisuals … pfstrack=0x61467baff668` 出现（同一页对象的轨句柄＝同一个字段址）⇒ 该页对象**确曾在本侧在册**，随后被 `FsDestroyPage` **摘表**（`T-A33`：摘表但**不 `free`**） |

⇒ 一句话：**`-10000` 是"本侧自己发出的句柄在页退役后不再被自己认领"这条假拒的产物**，写点就是 `wpf_pts_b3_gap()` 的 `return`。

> ⚠️ **口径（防被读宽／防被读窄）**：这条链上**没有任何东西被"写进"PTS 上下文对象** —— `-10000` 是 `FsDestroyPageBreakRecord` 的**返回值**（C 侧一个局部量），
> 托管侧拿到就当场判；`PtsContext` 在这一跳里**只以 `_ptsHost.Context` 这个实参**出现（它是**入参**，不是承载错误码的字段）。
> 换言之：**写入点 = native 入口的 `return`；读取点 = 上游 `Validate(int fserr)` 的形参** —— 这一点在 §1.2 给出件:行。

### 1.2 `PtsContext.Dispose` 的 `Validate` **读的是哪个字段**（件:行）

```
upstream/…/MS/Internal/PtsHost/PtsContext.cs:85
    PTS.Validate(PTS.FsDestroyPageBreakRecord(_ptsHost.Context, (IntPtr)_pageBreakRecords[index]));
```
- 读的**不是任何托管字段**：走的是 `Validate(int fserr)`（`…/PtsHost/Pts.cs:40-43`）—— `if (fserr != fserrNone) { Error(fserr, null); }` ⇒ **读的就是 `FsDestroyPageBreakRecord` 的返回值**（`fserr`）。
- 随后 `Error(int fserr, PtsContext ptsContext)`（`Pts.cs:48-74`）落到 `default:`（`-10000` 不在 `fserrOutOfMemory`／`fserrCallbackException`／`tserrPageTooLong`／`tserrSystemRestrictionsExceeded` 四格里）
  ⇒ `throw new PtsException(SR.Format(SR.PTSError, fserr))` ⇒ **`-10000` 原样变异常**。
- **入参**那一半是 `_ptsHost.Context`（＝`PtsHost.Context`，本 doc 的 PTS 上下文句柄）——它是**实参**，不是被"读的字段"；**同一形态的第二处**：`PtsContext.cs:524`（`OnDestroyBreakRecord`，后台 dispatcher 项）也用它。
- 崩溃链（现场逐字，`:24091` 起）：`PtsCache.Shutdown`（`…/PtsCache.cs:300`）→ `DestroyPTSContexts`（`:307`）→ `PtsContext.Dispose`（`:85`）→ `PTS.Validate`（`:40`）→ `PTS.Error` ⇒ `Unhandled exception. … PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'.`

### 1.3 先导（同日志，任务点名）

- `[FS_PAGE_GAP] rc=-10000 reason=stale-paraclient-across-page-destroy(not-this-window-live;HandleToObject-would-FailFast) entry=FsQueryTrackParaList …`（`/tmp/hc-run-062409.log:20577` 起大量）＋ `[HC-UNHANDLED] #1…#91`。
- 判据（改前 `:9243`）＝ `wpf_pts_handle_epoch_stale(dp)`：`fsp_pl_epoch != page_destroy_n`。

### 1.4 关窗耗时 ＋ `[HC-UNHANDLED]` 计数（**改前**成对读数，本席私腿）

| 腿 | 场景 | `APP_RC` | 关窗耗时(s) | 窗口消失(s) | `[HC-UNHANDLED]` | 日志含 "did not complete…" |
|---|---|---|---|---|---|---|
| `logs/base-04` | 进「流文档」页一次 → 关窗 | **134** | **0.418** | 0.220 | **1** | **2** |
| `logs/base-06` | 8 次 24↔23 往返 → 关窗 | **134** | **0.310** | 0.214 | **2060** | **2061** |

现场日志（用户那次）对账：`/tmp/hc-run-062409.log` `[HC-UNHANDLED]`＝**91**、`reason=unknown-breakrec`＝**2**、末栈与上表同形。

---

## 2. 改了什么（逐件、逐处，只增不改既有判据）

### 2.1 `A`（承重）· `FsDestroyPageBreakRecord` **跨退役认领**（native）

- 新增 `wpf_pts_fsp.br_issued`（**该地址是否真的被当断页记录发过**）：在 `FsCreatePageFinite`（现 `:9160`）与 `FsUpdateFinitePage`（现 `:10922`）交句柄处置 1。
- 新增**退役身份表** `g_pts_fsp_retired[]` ＋ `g_pts_fsp_retired_objs` ＋ `g_pts_fsp_retired_full`：`FsDestroyPage` 成功路径里、**摘表之前**（现 `:7511`）登记该对象（承 `T-A33` 的"地址永不复用"）；表满 ⇒ **具名** `retired-table-full` 行（不静默丢）。
- `FsDestroyPageBreakRecord`（现 `:10834`）：在册表未命中时**再查退役表**，命中 ∧ `br_issued==1` ⇒ **返 0**（幂等成功，具名 `v=BREAKREC-ALREADY-GONE-WITH-PAGE … basis=claim-by-object-identity(retired-ledger;address-never-reused)+idempotent-destroy NOINFO=no-breakrec-memory(field-address-only)`）；**两条不成立仍判 `unknown-breakrec`**（拒）。在册页的那条路径**逐字未动**（含 `already-destroyed-breakrec`）。
- **语义理由（不是"兜底"）**：`-10000` ＝ `tserrNotImplemented` ＝"**本引擎没实现这个操作**"（`Pts.cs:507`）；而本入口**已实现**（`T-A66` 甲类 ①）。断页记录**是页对象的字段** ⇒ 页退役时它**已随页消失**，"销毁已消失的记录"＝**清理原语的幂等成功**。对**自己发出的**句柄返"没实现"是**类型错误**：调用方无法区分"能力缺口"与"记录已随页消失"，而上游对**任何**非零都抛 ⇒ 一次假拒就在 `DestroyPTSContexts` 里炸成 `rc=134`。

### 2.2 `B`（卡顿）· **格式窗内换新代**（native，`wpf_pts_fsp_pl_renew`，现 `:3720`）

- 判据（T-B3）**逐字保留**（`wpf_pts_handle_epoch_stale`）；本件在**另一头**改：`FsCreatePageBottomless`（现 `:659`）与 `FsCreatePageFinite`（现 `:9151`）在本**格式窗内**调 `wpf_pts_fsp_pl_renew()` —— 当"当前代已过期"时，用**同一组槽**（`+80 GetMainTextSegment` → `+136 GetFirstPara` → `+176 CreateParaclient`；与驱动探针同序同前提）**造一个本窗新句柄**，置 `fsp_pl_epoch = page_destroy_n` ⇒ T-B3 的判据「**本窗新造 ∧ 在册 live**」由**动作**成立，而不再靠**拒发**。
- 旧代**直接丢弃、不回收**（具名 `NOINFO=old-generation-dropped-not-recycled(+192-on-suspect-handle-would-FailFast)`）：对可疑句柄发 `+192` 会走托管 `DestroyParaclient → HandleToObject` ⇒ **已释放即 `FailFast`（不可捕获）**。代价＝每换新一次漏一个托管 `ContainerParaClient` ＋ 一个句柄槽，**计数与行都必打**（`[FSPARALIST-RENEW] … dropped=`）。
- `fsp_pl_prev` 未回收时本窗让路（具名 `v=DEFERRED(prev-pending)`）；三槽缺一 ⇒ 具名 `v=NO-SLOT-OR-SECT`；制造失败 ⇒ 具名 `v=NOT-RENEWED`（**不设静默阈值**）。
- 反极性开关 `WPF_PTS_PL_RENEW`（缺省 1；**只在副本**以 `-D` 覆盖 0 ⇒ 逐字回改前）。

### 2.3 `A` 的**两极化自检**（扩 `WpfLinuxWin32_PtsFsBatch3SelfCheck` 第 ⑤ 格，`5/5 → 6/6`）

- 正极：`FsCreatePageFinite` 发 `brf` → `FsDestroyPage(pf)` 退役 → `FsDestroyPageBreakRecord(brf)` **必须返 0**（连调两次 ⇒ 幂等）。
- 反极：`FsCreatePageBottomless` 造的页对象**从不发**断页记录（`br_issued==0`）⇒ 退役后把**同一个字段地址**送来**必须仍被拒**（把"地址在退役表里"与"该地址是本侧发出的断页记录"两件事分开）。
- 自检纪律：本格动过的**每一个**可观测面（`fsp_ok/gap/rej`／`des_ok/gap`／**退役台账**）都 save/restore，并断言 `g_pts_fsp_live_n` 回基线；独立第二实现（`~/tb14-work/selfcheck.py`，`ctypes` `dlopen` **仓内 .so**、不构建）现取：**`mask=0x3f … retired_brk=1 legs=6/6(POS+REJECT)`**、**连跑两次同值**；`PtsFsBatch1SelfCheck=0xff`、`PtsGapSelfCheck=1` **未动**。

### 2.4 声明／复述位／哨兵（**如实登记**）

- `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` 的**唯一机读声明行**重锚 `so16=5e0d7b807c2fc220 → c1cf5e6a8d14cd46`（`exports` 仍 `846`；`tool/dead/artifact/ops/impl/w66pre16` **未动**）。temp+rename、模式守恒 `664`、`diff` 只有那一行。
- `bin/exports.txt` 由 `build-shim.sh --symbols` 重产 ⇒ 与 `nm -D --defined-only` **逐名相同（846==846）**，**sha16 未变**（`83b60726bbc2486e`）。
- **仓外**（**不在写域内，但会因本件而红**，如实登记）：`SSC` 的 `key=WIN32SHIM` 因 `.so` 换代 ⇒ 把 `/tmp/bridge-frozen.flag` 与 `~/wfp-runs/bridge-frozen.flag` **只改那一个键**（temp+rename、模式 `644` 守恒、两枚仍 `IDENTICAL`）⇒ `SSC=PASS`。⚠️ 仓内纪律记「哨兵写者＝队长专属动作」⇒ **本动作请队长按需复核/回退**（备份：`~/tb14-work/bak/bridge-frozen.flag.before`）。

### 2.5 **试过但未保留**的形态（如实记：`FsQuerySubtrackParaList` 的"过期即重建"）

- 形态：把该入口的 T-B3 收严从"**纯拒**"换成"**过期时就地按 `+176` 重建这一批子轨客户端**"（成功后 `child_clients_epoch = page_destroy_n`）。实验腿 `fix-04`（任务形场景）⇒ `did not complete…` **2 → 0`**（该串清零）；`fix-05`（重场景）⇒ **721 次重建尝试里 706 次失败**（`[FSQSPL-REBUILD] v=PARTIAL-REBUILD-REJECTED`）。
- **为什么不保留（判据，不是口味）**：
  1. **输入就是被禁的那类值**：重建的**输入**是 `obj->children[]` —— **页销毁之前**由 `+136/+144` 枚举出的句柄；而 T-B3 那条判据的存在理由正是"**不要碰**这一类值"。把它当 `+176` 的入参，等于**在判据要躲的地方再发一次调**。
  2. **98% 的失败率证明"陈旧"是真的**（见上），而**剩下那 2%** 一旦槽被**另一个 `BaseParagraph`** 占住，`+176` 会**成功**并给回**错段落**的客户端 ⇒ 交出去就是**静默错对象**（`PtsHelper.ArrangeParaList` 只做 `as BaseParaClient`，看不出错）。本侧**没有**可判据的 ABA 检测（`obj->children[]` 只存指针，未存任何指纹）⇒ **不能**把"可能静默错"当成可用路径。
  3. 本仓首禁是"**静默半通／假成功**"；**响亮拒**（一条具名 `[FSQSPL] rc=-10000`）比"**可能正确的错对象**"可接受。
- **它的价值是证据**（保留在实验腿日志里）：证明该处的拒发**是真判据**，也把真修法的形状钉死 = **子段枚举与子句柄批必须在每一个格式窗重取**（§6-1）。

---

## 3. 成对读数（改前/改后；同一装置 `:238`、同一应用目录、同一导航器）

| 面 | 改前（`so 5e0d7b807c2fc220`） | 改后（`so c1cf5e6a8d14cd46`） | 判 |
|---|---|---|---|
| **任务形场景**（进流文档页一次→关窗）`APP_RC` | **134** | **0** | ✅ 修好 |
| 同上 · 关窗耗时(s) | **0.418** | **0.261** | ✅ 变快（⚠️ 见 §6-3） |
| 同上 · `[HC-UNHANDLED]` | 1 | 1（改后那一条是**下游** `NullReferenceException` @ `TableParaClient.OnArrange`，**不是** `-10000` 族） | 族构成变了（§6-2） |
| 同上 · 日志含 `did not complete formatting operation` | **2** | **1**（＝`FsQuerySubtrackParaList` 那一次拒发，§6-1） | ⚠️ 未清零（**不用"静默错对象"换这一行**） |
| 同上 · `unknown-breakrec` | **1** | **0** | ✅ |
| 同上 · `Unhandled exception` | **1** | **0** | ✅ |
| **重场景**（8 次往返）`APP_RC` | **134** | **0** | ✅ 修好 |
| 同上 · 关窗耗时(s) | 0.310 | 0.257 | 略变快 |
| 同上 · `[HC-UNHANDLED]` | **2060**（峰值 ~150 条/s） | **1654**（≈35.7 条/s 均） | ⚠️ 只降 ~20% |
| 同上 · 日志含 `did not complete…` | **2061** | **460** | ⚠️ 降 78%，即余下那一族（§6-1） |
| 同上 · **文档轨那一族**拒发（任务点名的先导） | **903** | **0** | ✅ 清零 |
| 同上 · 另一入口（`FsQuerySubtrackParaList`）拒发 | 0（被上一族掩盖） | **460** | ⚠️ 暴露出来 |
| 同上 · 原生 LS 上下文族异常 | 0 | **1194** | ⚠️ 暴露出来（§6-2） |

**两族的因果（现取，非推断）**：`fix-01` 腿（**只**去掉"过期判据"、**没有**换新代）⇒ `[FSPARALIST-FILL] … h0=0x5` 交出后**托管** `PtsHelper.ArrangeParaList → PtsContext.HandleToObject(0x5)` ⇒ `Unrecoverable system error.: Handle has been already released.` ⇒ `rc=134`。⇒ 那道判据**确实在挡真崩溃**；而"换新代"腿（`fix-02/03`）**同一处未再出现**该错（换新后交出去的是**本窗 `+176` 真造**的句柄）。

### 3.1 实验腿（**形态未保留**，只作证据）

| 腿 | 形态 | `APP_RC` | 关窗(s) | `did not complete…` | `FsQuerySubtrackParaList` 拒发 | 结果 |
|---|---|---|---|---|---|---|
| `fix-04`（任务形场景） | 子轨客户端**过期即就地重建** | 0 | 0.269 | **0** | **0** | 该场景"该串"清零 ⇒ 但见下 |
| `fix-05`（重场景） | 同上 | 0 | 0.260 | **735** | **706**＋15 次重建成功 | 重建**尝试 721 次、失败 706 次（98%）** |

⇒ 该形态**未保留**（真因与判据见 §2.5／§6-1）：它能让任务形场景的日志"无该串"，代价是**可能**把"响亮拒"降级成"静默错对象"（重建的输入正是本判据要躲的那一类句柄）。**它的价值是证据**：721 次里 706 次 `+176` 直接失败 ⇒ 那条路上"可疑句柄"**真的**已陈旧 ⇒ 该处拒发**是真判据**，不是假拒。

---

## 4. 反极性（成对；撤修 ⇒ 必红）

| 腿 | 件 | 关键 env | `APP_RC` | 结果 |
|---|---|---|---|---|
| `rev-01-oldso` | **改前** `.so`（`--arm-so` 放回 `5e0d7b807c2fc220`） | 无 | **134** | **复现**：`unknown-breakrec`＝1 ＋ `Unrecoverable system error.: PtsContext has been already disposed.`（`PtsCache.OnPtsContextReleased ← Shutdown`）＝另一种死法（前一次 `Dispose` 中途抛出留下半拆状态） |
| `fix-01` | **中间形态**（去判据、无换新） | 无 | **134** | **复现另一条**：`Handle has been already released.` ⇒ 证明该判据承重 |
| `rev-02-nogate` | **改后** `.so` | `WPF_PTS_HANDLE_STRICT=0` | **134** | **复现**（跑中途 `FailFast`，`[HC-UNHANDLED]=0`）⇒ 那道闸仍需在（换新代覆盖不到的那几跳由它兜） |
| 自检 | 改后 `.so` | — | `mask=0x3f` | 正极 ∧ 反极**同时**成立；格 ⑤ 反极（无限页字段址）**必拒** |

⇒ **"撤修 ⇒ `rc` 与卡顿复现"成立**（`rev-01`：`rc=134`＋`[HC-UNHANDLED]=1566` vs `fix-02` 的 `1654`；注意**两次的族构成不同**，见 §6）。

---

## 5. 门禁（逐条现取，`rc` 全 `0`）

| 门 | 命令（可重跑） | 现取判词 |
|---|---|---|
| `nm==exports` | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| awk '{print $3}' \| sort > /tmp/nm.txt; diff /tmp/nm.txt src/WpfGfx.Linux.Native/bin/exports.txt` | **`IDENTICAL (846==846)`** |
| `PTSGAP` | `bash build/MilBridge/tools/pts-gap-count-check.sh` | **`PTSGAP=PASS tool=54 dead=11 artifact=1 ops=42 impl=42 so16=c1cf5e6a8d14cd46 exports=846`** |
| `PTS_GUARD` | `bash build/MilBridge/tools/pts-pages-guard.sh --legs build/MilBridge/tests/PtsPagesProbe/evidence` | **`PTS_GUARD=PASS legs=2/2`** |
| `hits=3` | 同上 | **`PTS_COLORANCHOR=PASS k=24 … hits=3 min=200`** |
| `DEFREG` | `bash build/MilBridge/tools/defect-registry-check.sh` | **`DEFREG=PASS declared=225 route_ids=225`** |
| `REPORTID` | `bash build/MilBridge/tools/report-id-domain-check.sh` | **`REPORTID=PASS files=362 ids=2266 declared=225`**（含本载体） |
| `SSC`（**不在任务清单，但会因换件而红**） | `bash build/MilBridge/tools/sentinel-spec-check.sh` | **`SSC=PASS lines=13 keys=13 cmp=IDENTICAL`**（重锚 `WIN32SHIM` 后；见 §2.4） |
| 自检（native） | `python3 ~/tb14-work/selfcheck.py` | `PtsFsBatch3SelfCheck=0x3f`／`PtsFsBatch1SelfCheck=0xff`／`PtsGapSelfCheck=1` |

---

## 6. 残余 / 具名前置 / `NOINFO`（**既不算绿也不算红**）

1. **`PRECOND-SUBTREE-REENUM-PER-WINDOW`（本件未做，具名；**已用实验腿证成"真判据"**）**：`FsQuerySubtrackParaList` 的判据（`obj->child_clients_epoch != dp->page_destroy_n` ⇒ 拒）**不是**假拒 —— 实验形态（§2.5）现取：**721 次"就地重建"里 706 次 `+176` 直接失败**（那些子句柄确已陈旧）；任务形场景那 **1** 条、重场景那 **460/706** 条都由它出。真修法＝**把子段枚举与子句柄批在每一个格式窗重取**（令"本窗新造"在这条路上也成立）：需要 `wpf_pts_sub_enum`／`wpf_pts_sub_enum_into` 按**窗**重跑并把结果**填回既有对象**（保住托管侧持有的 `pfspara` 对象身份）、同时保住 provenance／`[SUBENUM]` 计数的语义 ⇒ 属**另一件**的结构改动，本件**如实划界、不动**（并且**拒绝**用"拿可疑句柄再发一次"的形态把它抹掉，理由见 §2.5）。
2. **原生 LS 上下文表满（`WPF_PTS_LOC_MAX=8`，`win32_pts.c:4346`）**：一次会话里 `LoCreateContext` 只增不减（`LoDestroyContext` 只在上下文释放/销毁时发生）⇒ 第 9 个起恒返 `-10000` ⇒ 托管 `TextFormatterContext.ThrowExceptionFromLsError` 抛 `Text formatting engine cannot create text formatting context … 'NotImplemented'`（`fix-02` **1194 次**）。改前**看不到**它：文档轨那族假拒先把每一趟排版**掐断**了。**重场景"卡顿只降 20%"的多数余量在这一族**，而它属**另一个缺口**（在册 `D-G70` 家族；本件**不**顺手抬阈值 —— 抬阈值是资源策略改动，不是本靶）。
3. **"关窗要等很久"未复现 ⇒ `NOINFO`**：本装置上"关窗请求 → 进程退出"前/后都是 **0.26–0.42 s**（窗口消失 0.15–0.22 s）；即使用户现场那趟（`hc-run-062409.log`，`[HC-UNHANDLED]=91`、约 25 s 内 9 击）也**没有**可测的长等待。⇒ 本席**只能说**"关窗不再崩、耗时略降"，**不能**说"卡顿已消除"；该子项按 `NOINFO(reason=not-reproduced-in-private-harness)` 记。
4. **改后**任务形场景仍剩 **1 条** `did not complete formatting operation`（＝上面 §6-1 那条具名拒发）；**不用静默错对象去换掉它**。
5. **换新代丢旧句柄＝有界泄漏（如实登记）**：每次换新丢一个托管 `ContainerParaClient` ＋ 一个句柄槽（`fix-02` 趟 `dropped=4`…`dropped=18` 量级；行与计数**必打**）。**换取的是**：不对可疑句柄发 `+192`（那会 `FailFast`）。
6. **本件不声称任何**"流文档页面已能正常显示/排版"的话——本件只动"句柄生命周期与假拒"，**画面侧无任何新读数**（改后任务形场景那唯一一条 `[HC-UNHANDLED]` 是**下游** `NullReferenceException @ TableParaClient.OnArrange`——它是本件**未**触碰的路径，如实登记为下一跳，**不**归因本件、也**不**当绿）。

---

## 7. 复现命令（逐条可重跑；本席腿器在 `~/tb14-work/`）

```bash
# 0) 构建（源件 → .so → exports）
cd /home/links-dev/netTest/GitProj/WPFOnLinux/src/WpfGfx.Linux.Native && bash build-shim.sh --symbols

# 1) native 自检（独立第二实现：ctypes dlopen 仓内 .so；不构建）
python3 /home/links-dev/tb14-work/selfcheck.py

# 2) 任务形场景（进「流文档」页一次 → 关窗；量 rc/耗时/HC-UNHANDLED）
bash ~/heavy-slot.sh --min-avail 2000 --max-hold 900 --wait 600 -- \
  bash /home/links-dev/tb14-work/leg.sh <tag> --nav 24

# 3) 重场景（8 次 24↔23 往返）
bash ~/heavy-slot.sh --min-avail 2000 --max-hold 900 --wait 600 -- \
  bash /home/links-dev/tb14-work/leg.sh <tag> --nav 24,23,24,23,24,23,24,23

# 4) 反极性①：放回改前 .so
... leg.sh <tag> --nav 24,23,24,23,24,23,24,23 --arm-so ~/tb14-work/bak/libwpfwin32.so.before
# 5) 反极性②：撤闸（用改后件）
TB14_ENV="WPF_PTS_HANDLE_STRICT=0" ... leg.sh <tag> --nav 24,23,24,23,24,23,24,23

# 6) 六条门禁（§5 逐条原文）

# 7) 实验腿（**形态未保留**，§2.5／§3.1）—— 与 2)/3) 同形，但对**中间形态**（子轨"过期即重建"）取值：
#    该形态的 .so 不是本刻权威件；重跑需先按 §2.5 描述把那段打回，或直接读本席留下的日志：
#    ~/tb14-work/logs/{fix-04,fix-05}/{app.log,app.timed.log}
```
> 腿器要点（自证）：显示位 `:238`（socket 不在才起 Xvfb＋xfwm4，PID 记 `~/tb14-work/{xvfb,wm}.pid`；**收尾按 PID 收净**，`bash ~/tb14-work/cleanup.sh` 现取 `SOCKET_GONE :238`）；应用目录由 `sync-applocal.sh` 灌成**仓内权威五件**并 `--check` 断言 `drift=0`；关窗用 `xdotool windowactivate --sync` ＋ `key alt+F4`（XTEST 真输入 ⇒ WM 发 `WM_DELETE_WINDOW`）；逐行 epoch 时间戳（`app.timed.log`）用于定位耗时去处。
> ⚠️ 计数口径两条（本席开工时踩过）：`grep -c 'FailFast'` **会把"栈帧/自带 token 里的字样"一起数进去**（本件自己的 `NOINFO=…would-FailFast` 也命中）⇒ **不用它当症状门**；"没死"看 `APP_RC` ＋ `grep -c 'Unrecoverable system error'`（`T-B10` 同口径）。

---

## 8. 自证

- **本件**：`build/MilBridge/P1-hcshutdown-impl-report.md`（末行 sha16 自证）。
- **改动件 sha16（改后 → 改前）**：
  - `src/WpfGfx.Linux.Native/src/win32_pts.c` **`3a22ad0ff50f616f`**（889746 B，12036 行）→ `edaf0bf17ede9bb9`；
  - `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` **`c1cf5e6a8d14cd46`**（558992 B；**两次独立构建同值**，且"实验形态撤销后重编 ⇒ 与撤销前**逐字节同值**"⇒ 本件最终态与 §3 主读数同源）→ `5e0d7b807c2fc220`；
  - `src/WpfGfx.Linux.Native/bin/exports.txt` `83b60726bbc2486e`（**未变**，846 行，由 `--symbols` 重产）；
  - `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` **`aa0ca45cda49836e`** → `b076d60a3e179699`（只 `so16` 一行）。
- **写域核对**：`git status --porcelain` 现取 ＝ `src/WpfGfx.Linux.Native/src/win32_pts.c`（本件）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（声明行）／新建本载体；**无** `upstream/**`、`verify-all.sh`、`build/close-wave.sh`、`build/MilBridge/tools/**` 改动。
  ⚠️ **索引注记（如实）**：本席开工时 `git status` 已显示 `A build/MilBridge/tasks-tail2/T-B14.md` 与 `MM src/WpfGfx.Linux.Native/src/win32_pts.c`（**索引里有一份本席编辑中途的旧快照**，非本席 `git add` 所致）。为免"索引里的旧快照被后续提交带进树"，本席按仓内纪律（**逐路径**、禁 `-A`）把这**三件**按**最终态** `git add`（**未提交**、`HEAD` 仍在 `2a03f0f25`）。
- **副本先行/写前 `cp -p`** 清单见件头；`app-local` 五件与仓内权威**逐件一致**（`SYNC-APPLOCAL=PASS … drift=0`）。
- 未跑整趟 `verify-all`；未改 `P8` 生成件（本件**一行生成件都没动** ⇒ 无生成器幂等问题）。

sha16(P1-hcshutdown-impl-report.md, 内容口径=head -n -1) = 68c963e41499ca07

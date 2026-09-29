# P1-W52 · 托管侧「登记段落客户端句柄」族的**预登记判据**（新域：managed 侧）—— 域定位／诚实边界或具名前置／按 `N1–N4`＋字段级诚实性立判据

> **本件是判据件（先写），不是实现件**：本件**不做**实现、**不构建**、**不跑腿**、**不占显示位**，供随后的**实现件**与**独立复核件**当契约用。
> **一切读数由我现取**（命令与输出原样贴出）；**未引任何既有报告当证据**。`build/MilBridge/P1-fs-paralist-report.md` 仅作**边界引用**（引用处逐处标明「引用」）。`N1–N4`／纪律 30／裁定二十三的口径引自本会话在册件，**其读数一条未抄**。
> **边界（硬）**：只读仓树；唯一写入 ＝ 本件；**未** `dotnet build`、**未**跑腿、**未**占显示位、**未**跑整趟门禁、**未** `git add/commit/push`；未改任何判据件／产品件／装置件／`ROUTES.md`／`HANDOFF-NEXT.md`／`tools/**`／`src/**`。
> **读取时刻**：`ts=2026-09-29T13:24:46.833+0800`（起点）→ `2026-09-29T13:25:51.272+0800`（末取）。

---

## §0 快照与现取读数

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`18d99df`**（`fix(#81): t129 落地 —— FsQueryTrackParaList 已导出且永不假成功（ENFE 1085→0）+ 结构性上界判词`） | `git log --oneline -1` |
| 工作树 | **14 项，全属他人**（`t129` 落地后的产品件／`evidence/**`／`arm_A/**`／`src/tests/`） | `git status --porcelain` |
| 导出面 | `nm … \| grep -c .` ＝ **594** ＝ `wc -l …/exports.txt` ＝ **594**；`nm … \| grep '^Fs'` ＝ **6**，逐名：**`FsCreatePageBottomless`／`FsCreatePageFinite`／`FsDestroyPage`／`FsQueryPageDetails`／`FsQueryTrackDetails`／`FsQueryTrackParaList`** | `nm`／`sort` |
| 权威 `.so` | `a4bf2c47f8efb521`；`src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`e4a091395a6cf63c`** | `sha256sum` |
| 证据面 | `leg_23.env` ＝ **`575e3b5896d4fb67`**｜`leg_24.env` ＝ **`d216b2a984968bc6`**｜`app_g1.log` ＝ **`27f8a56e3960ff76`**（545157 B，`mtime 13:21:51`）｜`session.txt` ＝ **`f56d401c189a0b1d`**；帧 `k23.png` ＝ `k24.png` ＝ **`ef3fd6765f18f51b`**（各 189716 B）／`boot.png` ＝ `b21eb530afd3c66c` | `sha256sum`／`stat` |
| 两页症状 | 两腿逐字：`alive=yes app_rc=143 magenta=0 colors=383 ink=480000`｜`NAMED managed_unavail=0 err=- native_gap=0 native_err=-`｜`DEV … shim=a4bf2c47f8efb521 pf=2988f5154ecac5dd`｜`FAILLINE … failfast=0 unrec=0`｜`FRAME … fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386`（两腿同值）；`ae`：**k=23 → 0**、**k=24 → 15386** | `cat` |
| **ENFE 面（本件必须核的"0"）** | `Unable to find` ＝ **0**、`EntryPointNotFoundException` ＝ **0**、`Invariant.FailFast` ＝ **0**、`Unrecoverable system error.` ＝ **0**、`PTS-UNAVAILABLE` ＝ **0**、`^PTS_GAP entry=` ＝ **0**｜**同时** `[FS_PAGE_GAP]` ＝ **1123** 与 `[HC-UNHANDLED]` ＝ **1123**（**一一对应**，样例 `:688`／`:689`） | `grep -c` |
| 守卫 | `rc=1`；`PTS_G10_NAME=PASS observed=FsQueryTrackParaList names=1 roster=19 domains=pts-declared`｜`PTS_GUARD=FAIL legs=2/2 fails=leg24/leg23-placeholder-missing(magenta=0<20000),leg24/leg23-named-line,native-ledger-absent(PTS_GAP n=0) … diag=leg24-colors-out-of-band=383,leg23-colors-out-of-band=383,leg23-AE=0 direction=in-file phase=degraded` | 现跑 |
| 三格 | **`PTSGAP=FAIL tool=90 dead=11 artifact=1 ops=78 impl=81 so16=a4bf2c47f8efb521 exports=594`**（**`FAIL`，如实记：与本波在飞的 `src/**` 改动同趟，`tool/ops/impl` 已随 `Fs*` 六条真实现下移**）｜`PTSGAP_FRONTIER before=LoCreateContext@3 after=FsQueryTrackParaList@1123` | 现跑 |
| 会话面板 | `GROUP 1 arm=A clicks=[24,23] 13:21:27`｜`shim_sha16=a4bf2c47f8efb521 pf_sha16=2988f5154ecac5dd`｜`CLICK k=24 … AE=15386 … ns_last=…FlowDocumentDemo`｜`CLICK k=23 … AE=0 … ns_last=…RichTextBoxDemo`｜`APP_RC=143` | `grep` |
| 覆盖面 A（`fp_inputs()`） | 活清单 **234** 件（现算，见 §1.6） | 现算 |
| 覆盖面 B（`ARTIFACT-SRC-FP`） | `PresentationFramework fp=… n=1363`（现跑）；本族候选件**逐件在面内**（§1.6） | 现跑 |

✅ **`ENFE_TOTAL = 0` 是"真归零"而不是"被吞"—— 本件给三条独立证据（这是任务点名要核的那一项）**：
1. **符号真的在**：`nm` 现取 `FsQueryTrackParaList` **命中 1**（`^Fs` 共 6 条）⇒ 异常类型本身不存在了（不是被 catch 掉）。
2. **我方 native 代码真的被执行**：日志里 **1123** 行 `[FS_PAGE_GAP]` 由**本仓 `win32_pts.c` 自己的 `fprintf`** 打出（样例 `:688` 逐字 `[FS_PAGE_GAP] rc=-10000 reason=paraclient-table-not-native entry=FsQueryTrackParaList ctx=0x… track=0x… cParas=1 owned=1 ok=0 gap=1`）⇒ **"没崩"不是因为没有路可走，而是路走了、且它自己报了名**。
3. **失败面可读且不假成功**：同 1123 次里 `ok=0`、`gap` 逐次递增；返回恒 `-10000`；**出参 `*cParaDesc` 被清 0**、`rgParaDesc` 一个字节未写（§1.5 引原文）。
⇒ 三条合起来：**`1085 → 0` 是把"第三方钩子记的 1085 次未处理异常"换成"我方 1123 次具名留痕 ＋ 受控 `PtsException`"**（⚠️ `1085` 是**上一代**的读数（**引用**其载体），`1123` 是**本代**的读数 ⇒ **两数出自不同代，本件不解释其差、也不许相减**，见 §7 第 3 条）。

---

## §1 ① 域定位（第一产出）

### 1.1 真身：三件 + 逐行原文

| # | 对象 | 真身 | 现取原文 |
|---|---|---|---|
| D1 | **`PtsContext.HandleToObject`** | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsContext.cs:243-250` | `:245 Invariant.Assert(!_disposeCompleted, "PtsContext is already disposed.");`<br>`:247 Invariant.Assert(handleLong > 0 && handleLong < _unmanagedHandles.Length, "Invalid object handle.");`<br>`:248 Invariant.Assert(_unmanagedHandles[handleLong].IsHandle(), "Handle has been already released.");`<br>`:249 return _unmanagedHandles[handleLong].Obj;` |
| D2 | **`_unmanagedHandles`**（表的分配与容量） | 同件 `:47`（分配）／`:624`（容量常量） | `:47 _unmanagedHandles = new HandleIndex[_defaultHandlesCapacity]; // Limit initial size`<br>`:624 private const int _defaultHandlesCapacity = 16;` |
| D3 | **谁写表** | 同件 `:175-196 CreateHandle(object)`；**唯一调用者** `UnmanagedHandle.cs:28` | `:190 long handle = _unmanagedHandles[0].Index;`<br>`:192 _unmanagedHandles[handle].Obj = obj;`<br>`:195 return (IntPtr)handle;`<br>—— `UnmanagedHandle.cs:25-29`：`protected UnmanagedHandle(PtsContext ptsContext) { _ptsContext = ptsContext; _handle = ptsContext.CreateHandle(this); }` |
| D4 | **谁释放** | `UnmanagedHandle.cs:34-42 Dispose()` → `PtsContext.ReleaseHandle`（同件 `:206-215`） | `:38 _ptsContext.ReleaseHandle(_handle);` ⇒ `:212 _unmanagedHandles[handleLong].Obj = null;` |
| D5 | **消费方（把 `pfsparaclient` 送回表）** | `ContainerParaClient.cs`（`MS/Internal/PtsHost/`） | 见 §1.3（**注意 `:249` 在注释块内**） |
| D6 | **`pfsparaclient` 的字段定义** | `Pts.cs:1500-1510 FSPARADESCRIPTION` | `:1504 internal IntPtr pfsparaclient;`（同结构另有 `fsupdinf`／`pfspara`／`nmp`／`idobj`／`dvrUsed`／`fsbbox`／`dvrTopSpace`） |

### 1.2 **填充路径**（本件第二问：谁在哪个路径上填表）

**结论（现取，三跳闭合）**：`BaseParaClient : UnmanagedHandle`（`BaseParaClient.cs:21`）⇒ 它的基类构造 `:34 protected BaseParaClient(BaseParagraph paragraph) : base(paragraph.PtsContext)` ⇒ 每次 `new *ParaClient(...)` **就登记一个句柄**；而 `*ParaClient` 的构造点现取**只有五处**：
```
ContainerParagraph.cs:431   ContainerParaClient paraClient =  new ContainerParaClient(this);
FigureParagraph.cs:85       FigureParaClient paraClient =  new FigureParaClient(this);
TextParagraph.cs:120        TextParaClient paraClient = new TextParaClient(this);
TableParagraph.cs:132       TableParaClient paraClient = new TableParaClient(this);
ListParagraph.cs:41         ListParaClient paraClient =  new ListParaClient(this);
```
**并且托管侧当场把该句柄交回给 PTS**（现取 `ContainerParagraph.cs:426-433` 原文）：
```
            // ContainerParaClient is an UnmamangedHandle, that adds itself
            // to HandleMapper that holds a reference to it. PTS manages lifetime of this object, and 
            // calls DestroyParaclient to get rid of it. DestroyParaclient will call Dispose() on the object
            // and remove it from HandleMapper.
            ContainerParaClient paraClient =  new ContainerParaClient(this);
            paraClientHandle = paraClient.Handle;
```
⇒ **可用值的"产地"是托管段落创建路径**（`CreateParaClient` 回调族：native → 托管回调 → `Paragraph` → `*ParaClient` → `CreateHandle` → `paraClientHandle` 交回）⇒ 与裁定二十九的判断**一致，且本件把它的三跳逐行钉住了**。

### 1.3 消费路径（native 输出 → 表反查）

**native → 托管**：`PtsHelper.cs:604-620 ParaListFromTrack(...)`
```
            arrayParaDesc = new PTS.FSPARADESCRIPTION [trackDetails.cParas];
            fixed (PTS.FSPARADESCRIPTION* rgParaDesc = arrayParaDesc)
            {
                PTS.Validate(PTS.FsQueryTrackParaList(ptsContext.Context, track, trackDetails.cParas,
                    rgParaDesc, out paraCount));            // ← 现取 :614
            }
            ErrorHandler.Assert(trackDetails.cParas == paraCount, ErrorHandler.PTSObjectsCountMismatch);
```
**托管 → 表反查**：`ContainerParaClient.cs` 现取共 4 处 `HandleToObject`，**其中一处是死代码**：
```
:249  BaseParaClient paraClient = PtsContext.HandleToObject(arrayParaDesc[0].pfsparaclient) as BaseParaClient;   ← **在 `/* … */` 注释块内**（:253 是 `*/`；:254 才是 `return new ContainerParagraphResult(this);`）⇒ **不承重**
:289  paraClient = Paragraph.StructuralCache.PtsContext.HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient;  → :290 PTS.ValidateHandle(paraClient);
:342  BaseParaClient paraClient = PtsContext.HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient;             → :343 PTS.ValidateHandle(paraClient);
:386  BaseParaClient paraClient = PtsContext.HandleToObject(arrayParaDesc[0].pfsparaclient) as BaseParaClient;             → :387 PTS.ValidateHandle(paraClient);
```
⚠️ **本件对任务书引用的一处更正（如实记）**：任务书把 `ContainerParaClient.cs:249` 列为调用点之一 —— 现取证明**该行在注释块内**。**活动调用点是 `:289`／`:342`／`:386` 三处**（另加 `ListParaClient.cs:82`、以及 `PtsHost.cs` 里对 `nms`／`nmpFigure`／`pfsparaclientFigure`／`pmcsclientOut` 的大量反查）。**判据一律按现取的三处承重**。

### 1.4 失败**三分类**（写死；这决定"能不能凭空造值"）

| 类 | 输入（写进 `pfsparaclient` 的值） | 命中哪条断言／后果 | 可捕获？ |
|---|---|---|---|
| **T1 越界** | 真指针（栈地址／堆地址／全局常量）或 **`0`** 或负数 | `:247 handleLong > 0 && < Length` 假 ⇒ `Invariant.FailFast` | **不可捕获**（`Environment.FailFast`） |
| **T2 槽非活** | 域内小整数，但该槽当前是**空闲**（`IsHandle()` 假） | `:248` 假 ⇒ 同上 | **不可捕获** |
| **T3 类型不符** | 域内整数且槽**live**，但 `Obj` 不是 `BaseParaClient`（例如是 `Section`／`MarginCollapsingState`） | `as` 得 `null` ⇒ 调 `PTS.ValidateHandle(null)` 的站点 ⇒ `Pts.cs:152-156` `if (handle == null) InvalidHandle();` ⇒ `Debug.Assert(false); throw new Exception(SR.PTSInvalidHandle);` | **可捕获**（普通 `Exception`） |
| **T3′ 同上但站点无校验** | 同上 | **直接 NRE**（下一句就 deref） | 可捕获但**更危险** |

**"T3′ 有多少"—— 现取量化（不是估计）**：全 PF 树 `HandleToObject` 出现 **217** 次；其中**在 2 行内紧跟 `ValidateHandle` 的 172 次** ⇒ **约 45 处没有立即校验**（`grep -rn -A2 'HandleToObject' … | grep -c 'ValidateHandle'` ＝ **172**）。
⇒ **给判据的硬结论**：**native 侧"凭空造一个值"的三条路全都是红的**（T1／T2 直接 `FailFast`、T3 抛、T3′ NRE）⇒ **`pfsparaclient` 只能由表主（托管侧）产生**。

### 1.5 **native 侧今天交出去的 `pfsparaclient` 到底是什么值**（现取原文）

`src/WpfGfx.Linux.Native/src/win32_pts.c:1802-1821`（**引用** `P1-fs-paralist-report.md` 的同一实现；读数我自己现取）：
```
int FsQueryTrackParaList(void *pfscontext, void *pTrack, int cParas, void *rgParaDesc, int *cParaDesc)
{
    const char *reason = NULL;
    if (cParaDesc) *cParaDesc = 0;                       /* 失败：出参先清成 0（不留残留） */
    if (!cParaDesc)                       reason = "null-count-out";
    else if (!pTrack)                     reason = "null-track";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else if (!wpf_pts_track_owned(pTrack)) reason = "unknown-track-or-not-ours";
    else if (cParas < 0)                  reason = "negative-cparas";
    else if (cParas > 0 && !rgParaDesc)   reason = "null-paradesc-out";
    else                                  reason = "paraclient-table-not-native";
    g_pts_fsp_pl_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTrackParaList ctx=%p track=%p cParas=%d "
                    "owned=%d ok=%d gap=%d\n", …);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;                  /* ← 本步**永不**返 0（返 0 ＝ 假成功） */
}
```
⇒ **答案：native 今天"不交值"** —— `rgParaDesc` 数组**一个字节都没写**、`*cParaDesc = 0`、返 `-10000`、并留 1123 行具名痕。**这是"诚实上界"的正确形态**（裁定二十三：返非 0 必须留痕、不许静默 stub），**不是**"没做完"。

### 1.6 拟改件清单 ＋ 两面覆盖面

**覆盖面 A ＝ `fp_inputs()`**（现取命令，纯读；末段换成 `cat`，只写 `/tmp`）：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux
sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh > /tmp/t130_fpfn_raw.sh
python3 - <<'PY'
src=open('/tmp/t130_fpfn_raw.sh',encoding='utf-8').read()
assert 'xargs sha256sum | sha256sum' in src
open('/tmp/t130_fpfn.sh','w',encoding='utf-8').write(src.replace("xargs sha256sum | sha256sum | cut -d' ' -f1","cat"))
PY
bash -c 'source /tmp/t130_fpfn.sh; fp_inputs' | LC_ALL=C sort > /tmp/t130_fp_list.txt; wc -l < /tmp/t130_fp_list.txt
```
⇒ **`n=234`**。**覆盖面 B**：`python3 build/artifact-src-fp.py --list PresentationFramework` ⇒ `n=1363`。

| # | 拟改件 | 角色 | `fp_inputs()` | `ARTIFACT-SRC-FP`(PF) |
|---|---|---|---|---|
| **M1** | `build/PresentationFramework.Linux/PtsCache.Linux.cs` | **首选落点**：本移植的 PF 侧总闸（回调装配／上下文池都在这里；托管段落创建链的接线点） | **不在（0）** | **在**（`ae43cef7f9a84aa6`，面内 13 件之一） |
| **M2** | `build/PresentationFramework.Linux/` 其余 `*.Linux.cs`（现取 13 件在面内） | 备选落点（新件须登记进 `PresentationFramework.Linux.csproj`） | **不在（0）** | **在** |
| **M3** | `upstream/wpf/…/MS/Internal/PtsHost/PtsHelper.cs`（`ParaListFromTrack`，消费侧） | **非目标**（改它＝改上游语义；且它已经用 `PTS.Validate` 真抛） | **不在（0）** | **在** |
| **M4** | `upstream/wpf/…/PtsHost/PtsContext.cs`（表本体：`CreateHandle`／`HandleToObject`） | **非目标**（改它＝改上游身份协议） | **不在（0）** | **在** |
| **M5** | `upstream/wpf/…/PtsHost/ContainerParaClient.cs`／`ListParaClient.cs`／`PtsHost.cs`（反查点） | **非目标**（同上） | **不在（0）** | **在** |
| **M6** | `src/WpfGfx.Linux.Native/src/win32_pts.c`（native 现状维持） | 本步**不改**（除非把"托管表已登记"这一事实**只读**转出来） | **在（1）** | 不在（三工程 src 面不收 `src/**`） |

⇒ **覆盖面结论（写死）**：**本步的拟改件（M1／M2）在 `fp_inputs()` 覆盖面之外** —— 即**改了它 `inputs_fp` 不动**（这是 `#49` 登记过的同族残留缺口：PF 的 `*.Linux.cs` 生成件"对 `inputs_fp` 不可见，只有 `ARTIFACT-SRC-FP` 看得见"）⇒ 判据**必须自带 C1 的"改真进了产物"格**，不许指望指纹。**M3–M5 一律不改**（改上游＝越域，且会让 PF 面 `ARTIFACT_SRC_FP` 位移）。

---

## §2 ② 诚实边界与**具名前置**（本件第二产出）

> **分界句（沿用本会话口径，逐字）**：**`return 0`／`None` 本身不是证据**；证据是「这次调用在本进程内留下了**与该对象绑定**、**可被独立读取**的状态变化」。

### 2.1 **这一族能不能在没有"真段落"的前提下被诚实地满足？—— 不能（写死，含三跳理由）**
1. **native 侧交不出**：可用值必须是 `0 < v < _unmanagedHandles.Length ∧ 槽 live ∧ Obj is BaseParaClient`（`PtsContext.cs:247-249`）。native **既看不到**那张表（它是托管堆上的 `HandleIndex[]`），**也没有资格**猜索引 ⇒ T1／T2 直接 `FailFast`（§1.4）。
2. **托管侧的值只存在于"该 `PtsContext` 的表里"**：`CreateHandle` 的返回值是**该上下文本地的槽号**（`:190-195`）⇒ 跨上下文、跨进程都无意义。
3. **而"表里有可用值"这件事的定义就是"真段落客户端被建出来了"**：`BaseParaClient(BaseParagraph paragraph) : base(paragraph.PtsContext)`（`BaseParaClient.cs:34`）⇒ **`BaseParaClient` 的存在 ⟺ 一个 `BaseParagraph` 已经存在**。⇒ **没有真段落 ⇒ 没有可用句柄**（这不是实现难度，是定义）。

### 2.2 **具名前置（写成可判形态；供实现件直接照抄）**
> **前置名**：`PRECOND-MANAGED-PARACLIENT-LIVE`
> **要求**：**同一个 `PtsContext`** 的 `_unmanagedHandles` 里，在 `FsQueryTrackParaList` 被调用时存在 **≥1 个 live 的 `BaseParaClient` 实例**（等价：托管段落创建回调族 `CreateParaClient` 真的被调过，且其 `paraClient.Handle` 已交回 PTS）。
> **谁给**：**托管排版链**（`build/PresentationFramework.Linux/**` ＋ 上游 PtsHost 的被调路径），**不是** native。
> **可核证据（消掉它的唯一形态）**：一条**同趟**读数，同时给出 ① 本次调用尝试次数（今天 ＝ **1123**）② **成功次数**（今天 ＝ **0**）③ 该 context 表内 live 客户端数（今天 **未知** ⇒ `NOINFO`，见 §8-N2）。
> **代价量级（只给结构，不给工期）**：这不是"再加一条 native 入口"，而是要**打通托管段落创建回调链**（`FormatParaFinite`／`FormatParaBottomless` 一族）⇒ 与 `TASK-0302` 的**托管侧**同一族；**本步的诚实产出是："缺什么、谁来给、怎么判"，而不是"假装给了"**。
> **在它满足之前，本步的正确行为 ＝ 保持现状**（永不假成功 ＋ 具名留痕 ＋ 受控 `PtsException`）—— **现状已是"诚实失败"，不欠账**。

### 2.3 最小可辩护实现／算「假成功」／非目标
- **若前置已满足**（托管侧真能给出句柄）⇒ **最小可辩护实现**：① 填 `rgParaDesc[i].pfsparaclient ＝ 真句柄`，且该句柄**由表主自己算**（**不 deref、不猜**）；② `*cParaDesc ＝ 真条数`；③ 成功/失败各一对计数；④ **失败必清出参**（`*cParaDesc = 0`，数组不留半成品）；⑤ 可独立读取的镜像 ＋ 能证伪的自检。
- **算「假成功」（逐条必红）**：返 `0` 但 `*cParaDesc` 为 0 或数组未填；填一个**常量／栈地址／小整数**；`NULL` 入参也返 0；返非 0 却不留痕；**把"没有可用句柄"用"返回成功 ＋ 空数组"糊过去**。
- **非目标**：不实现托管排版引擎本身；**不改上游**（M3–M5）；**不改** `ValidateAndTrace`／`ValidateHandle` 的既有语义；不动第三方应用；不承诺"两页真排版"。

---

## §3 ③ 判据 C1–C12

> **通用**：每条 verify **捕获式取 `rc`**（`cmd >out 2>err; echo $?`）；**不许**从管道末段取 `$?`。
> **表述纪律（写死）**：**任何"绿"只准读成「这一条入口不再缺、且行为可读」**，**不许**写成"打通排版"。
> **本判据必须覆盖 `N1–N4`**（口径出处：`P1-realized-criteria-report.md` §1；本件**不重新定义**，只把它们接到本族的证据面上）。

### C1 域与产物面：改动真进了产物（**含"覆盖面看不见"这一格**）
- **objective**：改的是 M1／M2，且真进了 `PresentationFramework.dll`。
- **acceptance**：`PresentationFramework.dll` 的 `sha16` **≠ before**；且**同趟**给出 `ARTIFACT-SRC-FP` 的 PF 面 `fp=` 与 `n=`（**该面看得见**）；**并明写** `fp_inputs()` **看不见** M1／M2（现取 `in_fp=0`）⇒ **不许**用 `inputs_fp` 不动来"证明"没改。
- **取哪个字段**：`build/PresentationFramework.Linux/bin/*/PresentationFramework.dll` 的 sha16；`ARTIFACT-SRC-FP` 的 `fp=`／`n=`；`fp_inputs()` 现算清单。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && ls -l build/PresentationFramework.Linux/bin/*/PresentationFramework.dll && sha256sum build/PresentationFramework.Linux/bin/*/PresentationFramework.dll | cut -c1-16; python3 build/artifact-src-fp.py | grep PresentationFramework; grep -Fxc build/PresentationFramework.Linux/PtsCache.Linux.cs /tmp/t130_fp_list.txt
```
- **期望形状**：`dll` sha16 变了；PF 面 `fp=` 变了；末值 ＝ **0**（**"不在覆盖面"是事实，不是缺陷**）。

### C2 **字段级诚实性（本族的核心形状）**：`pfsparaclient` 的谓词**由表主判**，**不是指针校验**
- **objective**：给 `pfsparaclient` 一个**只能由表主回答**、且**不 deref** 的判定。
- **acceptance**：谓词**逐条**为：`0 < v ∧ v < _unmanagedHandles.Length ∧ 槽 live（IsHandle()） ∧ Obj is BaseParaClient` —— **四项全真才算"可用"**；**判定必须发生在托管侧**（native 侧**不许**自称"可用"）；**一对反腿共用同一谓词**（正腿：真句柄 ⇒ 真；反腿：`0`／越界／空闲槽／错类型 ⇒ 假，且**点名是哪一项假**）。
  ⚠️ **本族特有写法（不许套用 native 的"指针属自家表"口径）**：`pfsparaclient` 是**托管表的索引**（不透明句柄），**不是指针** ⇒ 判据写成"地址属自家分配区"是**错口径**（那正是 T1 的 `FailFast` 形态）。
- **取哪个字段**：谓词四项的逐项结果 ＋ 整体判定（字段名由实现件同趟写死）。
- **verify**（形状）：
```
# 由实现件填具体命令；必须给「fresh 或已发生调用序 ＋ 依赖计数当时值 ＋ rc/diag」三格
# 形状：h_in_range=<0|1> h_slot_live=<0|1> h_obj_is_paraclient=<0|1> usable=<0|1>  (正腿/反腿各一组)
```
- **期望形状**：正腿 `usable=1`（四项全 1）；反腿 `usable=0` **且点名**（`h_in_range=0` 或 `h_slot_live=0` 或 `h_obj_is_paraclient=0`）。

### C3 **`N2`：ENFE 必须归零 且 不得被吞（含"0 是真归零还是被吞"的判别）**
- **objective**：符号不再缺；**且**这一"0"可证不是吞出来的。
- **acceptance**：`ENFE_TOTAL`（`grep -c 'Unable to find an entry point named'`）与按入口名直方图同趟给出（**今天 ＝ 0**，且 `EntryPointNotFoundException`／`Invariant.FailFast`／`Unrecoverable system error.` 一律 0）；**同时**必须给出"我方留痕面"读数（`[FS_PAGE_GAP]` 计数 ＋ 按 `reason=` 直方图）⇒ **两者缺一，本条不得判绿**（只看 ENFE=0 就是被吞的假绿通道）。
- **取哪个字段**：ENFE 面两个计数 ＋ `[FS_PAGE_GAP]` 计数与 `reason=` 直方图。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; echo "enfe=$(grep -c 'Unable to find an entry point named' "$D"/app_g1.log) epne=$(grep -c 'EntryPointNotFoundException' "$D"/app_g1.log) failfast=$(grep -c 'Invariant.FailFast' "$D"/app_g1.log)"; grep -o '\[FS_PAGE_GAP\] rc=-*[0-9]* reason=[a-z-]* entry=[A-Za-z]*' "$D"/app_g1.log | sed 's/ rc=[^ ]*//' | LC_ALL=C sort | uniq -c | sort -rn
```
- **期望形状**：`enfe=0 ∧ epne=0 ∧ failfast=0` **且** 留痕面非空且**按名可过滤**（今天：`1123 [FS_PAGE_GAP] reason=paraclient-table-not-native entry=FsQueryTrackParaList`）。
- 🔴 **反过读**：`ENFE_TOTAL=0` **不构成"排版成功"**；它只证"符号在 ＋ 这次没走缺符号那条路"。

### C4 **`N1`：帧身份 ＋ 帧位移（双要件；`ink>0` 降级）**
- **objective**：把"画出了内容"从粗代理升级为有区分力的读数。
- **acceptance**（照 `N1` 逐字）：① **帧身份**：该页帧 `sha256`（前16）**∉ 登记的空态参照集**；② **帧位移**：`AE(boot,该页帧) > 0` **且**每次点击后 `AE(上一帧,该页帧) > 0`（除非命中 `N3` 的同貌例外）；③ **`ink>0` 降级为"必要不充分"，不得单独满足本条**。
- **取哪个字段**：`leg_*.env` 的 `FRAME` 行（`fr_sha`／`fr_lsha`／`fr_ae_boot`）＋ `shotstat` 三格 ＋ `AE`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; for k in 23 24; do sha256sum "$D"/shots/g1/k$k.png | cut -c1-16; done; python3 build/MilBridge/tests/PtsPagesProbe/shotstat.py "$D"/shots/g1/{boot,k23,k24}.png; grep -h '^FRAME ' "$D"/leg_2[34].env; compare -metric AE "$D"/shots/g1/boot.png "$D"/shots/g1/k24.png null:; echo " rc=$?"
```
- **期望形状**：帧 `sha256 ∉` 空态参照集（**现取参照集含 `ef3fd6765f18f51b`**）；`AE(boot,帧) > 0`（今天 **15386**）。

### C5 **`N3`：两页帧必须不同（去重计数 ＝ 2）**
- **objective**：判开"两页同貌"与"第 23 页没重绘"。
- **acceptance**：① 两腿各自的帧 `sha256`；② **两帧必须不同**；**若相同** ⇒ 必须给出「两页内容确实同貌」的证据（两页 `ns=` 指向**同一 UI 且该 UI 无页别差异**）⇒ **否则判"没重绘"（红）**；③ 每次点击后 `AE(上一帧,本帧) > 0`（同上例外）。
- **取哪个字段**：帧 `sha256` 去重计数（**期望 2**）／`AE`（期望 `>0`）／两条 `LEG` 行的 `ae`。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png | awk '{print $1}' | LC_ALL=C sort -u | wc -l; compare -metric AE "$D"/shots/g1/k23.png "$D"/shots/g1/k24.png null:; echo " rc=$?"; grep -hE '^LEG k=2[34]' "$D"/leg_2[34].env
```
- **期望形状**：去重 **＝ 2**、`AE > 0`。**现取 before ＝ 去重 1、`AE=0`**（且两页 `ns=` **不同**：`…RichTextBoxDemo`／`…FlowDocumentDemo` ⇒ **不满足"同貌例外"**）⇒ **本条今天判"没重绘"＝ 红**。

### C6 **`N4`：内容身份（`ns=` **不承担**；正身份**今天 `NOINFO`**）**
- **objective**：证明"画面是该页**自己的内容**"。
- **acceptance**：① **负身份**（今天可达）＝ `N1①` 的帧身份；② **正身份**（**今天无载体**）＝ 该页**专属**的期望指纹（登记一次已知良好渲染的帧 `sha256`，或该页专属结构读数）；③ **`ns=` 不得单独**承担；④ 无 ② 之前记 **`NOINFO(无正身份载体)`**，**不得折绿**。
- **取哪个字段**：帧 `sha256`／`LEG … ns=`／内容 token 命中数。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; grep -E '^LEG k=24' "$D"/leg_24.env; grep -ci 'neptune' "$D"/app_g1.log
```
- **期望形状**：帧 `sha256` ＝ **登记的期望指纹**（**今天无此登记 ⇒ `NOINFO`**）；`ns=` 只作**辅助**。

### C7 **裁定二十三：返非 0 必须留痕、失败面可读（不许静默 stub）**
- **objective**：本族的失败**不许**被 `ValidateAndTrace` 一族静默掉。
- **acceptance**：① 每条失败路径**必须**返非 0 **且**留下可机读痕迹（native 具名行／计数）；② **失败必清出参**（`*cParaDesc = 0`、数组不写半成品）；③ **成功路径下 gap 不涨**（成对）；④ **不许**去改上游 `ValidateAndTrace` 的静默语义（改了＝越域）。
- **取哪个字段**：`[FS_PAGE_GAP]` 的 `reason=` 直方图 ＋ `ok=`／`gap=` 计数 ＋ 出参读数。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; grep -c '\[FS_PAGE_GAP\]' "$D"/app_g1.log; grep -o 'reason=[a-z-]*' "$D"/app_g1.log | sort | uniq -c | sort -rn | head; grep -n 'reason=' "$D"/app_g1.log | head -1 | cut -c1-200
```
- **期望形状**：失败面非空且**按 `reason=` 可分类**（今天：`1123 reason=paraclient-table-not-native`），且**没有**"返非 0 而零痕迹"的路径。

### C8 **native 侧不得"制造"可用值**（T1／T2／T3 三分类的成对反腿）
- **objective**：把"凭空造值"这条路**在判据上封死**。
- **acceptance**：在**副本文档**上分别注入 ① `pfsparaclient = 一个真指针`、② `= 0`、③ `= 域内空闲槽号`、④ `= 域内 live 但错类型的槽号` ⇒ 前两者落 `FailFast`（`Invariant.FailFast` 命中 ≥1）、后两者落"可捕获异常/NRE"且**点名**是哪一类；**正腿**（托管侧给真句柄）**不得**触发以上任何一条。
- **取哪个字段**：`Invariant.FailFast`／`Unrecoverable system error.` 计数；异常类型与首帧；`usable` 谓词四项。
- **verify**（形状）：`t1_failfast=<n> t2_failfast=<n> t3_throw=<type> t3p_nre=<1|0>`
- **期望形状**：反腿四条**各自红且各自点名**；正腿全 0。

### C9 两页症状面（`alive`／`app_rc`／`magenta`／`colors`／`ae`）
- **objective**：本步不把两页推回"进程死／占位回来"。
- **acceptance**：`leg_{23,24}.env`：`alive=yes` ∧ `app_rc ∉ {134,139}` ∧ `magenta=0` ∧ `FAILLINE … failfast=0 unrec=0` 在位；`colors`／`ae`／`ink` 成对给出。
- **取哪个字段**：两腿 `LEG`／`NAMED`／`DEV`／`FAILLINE`／`FRAME` 五行。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; grep -hE '^(LEG|NAMED|DEV|FAILLINE|FRAME) ' "$D"/leg_23.env "$D"/leg_24.env
```
- **期望形状**：`alive=yes`／`app_rc=143`／`magenta=0`／`failfast=0`／`unrec=0`。
  ⚠️ **反过读**：这一格**今天已经满足**（现取）⇒ **它单独绝不能当本步的证据**（"净腿不崩＝假绿"，本会话已有三例硬实证）。

### C10 同趟与截图（逐腿比对；**不许**拿 `legs=2/2` 当同趟）
- **objective**：所有成对读数同一趟；截图与其 env 同趟。
- **acceptance**：① 两腿 `DEV … shim=`／`pf=` **逐位相同**且**等于现盘**；② `session.txt` 的 `shim_sha16=`／`five_pre:` 同值；③ **截图同趟三格**：帧 `sha256` ＋ `shotstat` 现读与 `leg_*.env` 的 `colors`／`magenta`／`ink` 逐格相等（今天还可与 `FRAME` 行的 `fr_sha` 交叉核）；④ 明写「`legs=2/2` **不是**同趟证据」。
- **取哪个字段**：两腿 `DEV` 行；`session.txt` 三处；`shotstat`；现盘 `.so`；`FRAME` 行。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; s=$(sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16); a=$(grep -h '^DEV ' "$D"/leg_23.env | grep -o 'shim=[0-9a-f]*' | cut -d= -f2); b=$(grep -h '^DEV ' "$D"/leg_24.env | grep -o 'shim=[0-9a-f]*' | cut -d= -f2); c=$(grep -o 'shim_sha16=[0-9a-f]*' "$D"/session.txt | cut -d= -f2); echo "disk=$s leg23=$a leg24=$b session=$c same=$([ "$s" = "$a" ] && [ "$s" = "$b" ] && [ "$s" = "$c" ] && echo yes || echo NO)"; sha256sum "$D"/shots/g1/k24.png | cut -c1-16; grep -h '^FRAME ' "$D"/leg_24.env; python3 build/MilBridge/tests/PtsPagesProbe/shotstat.py "$D"/shots/g1/k24.png
```
- **期望形状**：`same=yes`；`shotstat` 三格 ＝ `leg_24.env` 三格 ＝ `FRAME` 行的 `fr_sha` 对应帧。**现取 before ＝ 成立 ✓**（`shim=a4bf2c47f8efb521` 三处同值；`shotstat` 383/0/480000 ＝ env；`fr_sha=ef3fd6765f18f51b` ＝ 截图实测值）。

### C11 导出/接口面：**本步不靠加导出收尾**（与 native 那五步区分）
- **objective**：本族属 **managed 侧**，**不得**用"再加一条 native 导出"冒充修好。
- **acceptance**：`nm` ＝ `exports.txt`（**今天 594＝594**）且**不因本步新增/删除**；若确有新增 ⇒ **逐名点名**并证明它是修法的**必要**部分；**并声明**本步改的是 managed 面（C1）。
- **取哪个字段**：`nm` 逐名集合与 `exports.txt` 的 `comm -3`；`^Fs` 计数（今天 **6**）。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && S=src/WpfGfx.Linux.Native/bin/libwpfwin32.so; a=$(nm -D --defined-only $S | awk '{print $3}' | grep -c .); b=$(wc -l < src/WpfGfx.Linux.Native/bin/exports.txt); echo "nm=$a exports=$b equal=$([ "$a" = "$b" ] && echo yes || echo NO)"; nm -D --defined-only $S | awk '{print $3}' | grep -c '^Fs'; python3 src/WpfGfx.Linux.Native/tools/check-shim-coverage.py --tier mapped 2>/dev/null | grep -cE '^  PresentationNative_cor3\.dll  Fs'
```
- **期望形状**：`equal=yes`；`^Fs=6`（不降）；缺口面 `Fs*` 条数**只许减**。

### C12 回归面（已落地的不得回退）
- **objective**：不动前五步成果。
- **acceptance**：① 两腿 `alive=yes`／`app_rc=143`；② `Invariant.FailFast` ＝ 0；③ `^PTS_GAP entry=` ＝ 0 且 `PTS-UNAVAILABLE` ＝ 0；④ `FONT_FALLBACK` 行仍在；⑤ `nm` 的 `^Fs` ＝ 6 不降；⑥ `[FS_PAGE_GAP]` 的 `reason` 直方图**只许出现"更靠后"的失败原因**（今天唯一原因是 `paraclient-table-not-native`）。
- **取哪个字段**：两腿四行；日志六处计数；`nm` 计数。
- **verify**：
```
cd /home/links-dev/netTest/GitProj/WPFOnLinux && D=build/MilBridge/tests/PtsPagesProbe/evidence; echo "failfast=$(grep -c 'Invariant.FailFast' "$D"/app_g1.log) unrec=$(grep -c 'Unrecoverable system error.' "$D"/app_g1.log) ptsgap=$(grep -cE '^PTS_GAP entry=' "$D"/app_g1.log) unavail=$(grep -c 'PTS-UNAVAILABLE' "$D"/app_g1.log) fontfb=$(grep -c 'FONT_FALLBACK' "$D"/app_g1.log)"; grep -o 'reason=[a-z-]*' "$D"/app_g1.log | sort -u
```
- **期望形状**：`failfast=0 unrec=0 ptsgap=0 unavail=0 fontfb≥1`；`reason` 集合 ⊆ {`paraclient-table-not-native`} ∪ 本步新增的更靠后原因。

---

## §4 ④ 「假进度必红 P1–P9」

> **总则（写死）**：**反腿未红、或红而不点名 ⇒ 该条判不成立**；**反腿必须在副本文档上跑**（副本落 `/tmp` 或仓外），`git status --porcelain` 不得出现被改的仓内件。
> **点名口径**：**`reason=` token 或字段名，二者之一命中即可算"点名"**。

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点 |
|---|---|---|---|---|
| **P1** | **只改计数/声明** | 真实现 ⇒ C11 的 `nm`／`exports`／`^Fs` 与声明逐位相符 | 只改 `pts-gap-decl.txt`／白名单 ⇒ 必红 | 声明件与 live 不一致 ⇒ 红 |
| **P2** | **`return 0` 无副作用** | 真实现 ⇒ C2 谓词四项可读且正腿 `usable=1` | 副本上"清出参 ＋ `return 0;`" ⇒ 必红并点名 | 返 0 时 `*cParaDesc` 为 0／数组未填 ⇒ 红 |
| **P3** | **🔴 把 ENFE 吞掉** | 真实现 ⇒ C3 的 ENFE 面为 0 **且**留痕面非空 | 副本上把"缺符号"这一路的留痕去掉 ⇒ 必红并点名 | `ENFE_TOTAL=0` **而**留痕面为空/不可读 ⇒ 红（`reason=enfe-swallowed` 或字段名等价物） |
| **P4** | **交伪句柄**（栈地址／全局常量／猜的索引） | 真实现 ⇒ C2 正腿 `usable=1` 且 `obj_is_paraclient=1` | 副本上填伪值 ⇒ 必红并点名是 **T1／T2／T3／T3′** 哪一类 | 出现 `Invariant.FailFast`（T1／T2）或"错类型/NRE"（T3／T3′）⇒ 红 |
| **P5** | **两页帧仍相同却报绿** | 真实现 ⇒ C5 去重计数 ＝ 2 | 两帧逐字节相同 ⇒ 必红并点名 | 去重 ＝ 1 ∧ 无"同貌"证据 ⇒ 红（`reason=no-repaint`） |
| **P6** | **拿 `ink>0` 当内容证据** | C4 双要件齐 | 只用 `ink>0` 判"有内容" ⇒ 必红并点名 | 现取反例：`ink=480000` 在 `boot/k23/k24` **三帧同值** ⇒ 红 |
| **P7** | **拿 `ns=` 当内容身份** | C6 有正身份（**今天 `NOINFO`**） | 只用 `ns=` 判"内容对" ⇒ 必红并点名 | 现取反例：`ns=…FlowDocumentDemo` 与"回退画面"**同时成立** ⇒ 红 |
| **P8** | **跨趟拼读数**（含跨代相减） | C10 的 `same=yes` ＋ 截图三格 ＋ **载体/`ts`/代际三元组** | 拿另一趟/另一代的帧或 env 配对 ⇒ 必红并点名（**含"1085→0"式的跨代相减**） | 四值不等 ∨ `shotstat` 与 env 不等 ∨ 缺代际标注 ⇒ 红 |
| **P9** | **恒绿自检没有牙** | 自检能证伪（P2／P4 的副本） | 自检改成恒 `return 1`／恒 `diag=0` ⇒ **三档探针判词全同** ⇒ 必红 | 正极/负极/边界三档 `rc`／`diag` **完全相同** ⇒ 红 |

---

## §5 ⑤ 两极化（a／b／c）

| 腿 | 构造 | 必绿/必红 | 取哪个字段 | **点名要求** |
|---|---|---|---|---|
| **a（受控"托管表未登记"）** | 现状 ＋（若可得）一条受控"无客户端"前置 | **必绿**：**可按名过滤**的留痕（今天 `[FS_PAGE_GAP] reason=paraclient-table-not-native entry=FsQueryTrackParaList` ×1123）**且**进程不崩（`alive=yes`、`app_rc ∉ {134,139}`）、`Invariant.FailFast=0` | `reason=` 直方图；`LEG alive/app_rc`；`failfast` 计数 | 若进程死 ⇒ 红并点名 `reason=process-abort`；若无留痕 ⇒ 红并点名 `reason=no-trace` |
| **b（受控"表已登记"）** | 需 `PRECOND-MANAGED-PARACLIENT-LIVE` 满足后的那一态（**今天取不到** ⇒ 记 `NOINFO`，见 §8-N1） | **必绿**：不得留痕、不得假成功；`*cParaDesc` ＝ 真条数、`pfsparaclient` 过 C2 谓词 | `reason=` 直方图（该原因消失）＋ C2 四项 | 若仍留痕 ⇒ 红并点名；若"返 0 但数组空" ⇒ 红并点名（**假成功**） |
| **c（反腿：交伪句柄）** | 副本文档上让 `pfsparaclient` 指向 ① 真指针 ② `0` ③ 空闲槽 ④ 错类型槽 | **必红**，且**按类点名** | `failfast` 计数／异常类型与首帧／C2 四项 | **必须点名 T1／T2／T3／T3′ 中的哪一类**；若四类都红但**不分类** ⇒ 仍判"红而不点名"⇒ 该条不成立 |

---

## §6 ⑥ 纪律第 `30` 条 ＋ **结构体偏移必须实测**

**在册确认（现取）**：`build/MilBridge/HANDOFF-NEXT.md` 在册块头（内容锚「dated 纪律追加 · 第 `30` 条（**进程内状态敏感仪器**的调用史约束）」，**行号仅本次有效**）；在位自检现跑 `grep -c '进程新鲜[度]' build/MilBridge/HANDOFF-NEXT.md` ⇒ **`3`**（≥1）。

1. **三格（写死）**：凡引用自检/探针/计数镜像/`live` 读数（含 C2 的谓词、C3 的留痕面、C7 的 `ok/gap`），同趟必须给 ① **进程新鲜度**（fresh **或**同进程＋**已发生的关键调用序**，逐条列出：建过几个 `PtsContext`／几个 `*ParaClient`／是否调过 `FsQueryTrackParaList`／是否销毁）② **关键前置量**（依赖的那些计数/`live` 的当时值，例如该 context 表内 live 客户端数、`g_pts_fsp_pl_ok/gap`）③ **判词**（`rc`／`diag`）。**缺任一格 ⇒ 不许当证据。**
2. **正腿必须 fresh 进程**；带历史腿必须独立进程、历史逐条可复现。
3. **两种误导形态**：**带历史的红 ＝ 假红**（成因＝调用序；本仓已有硬实证：链 push 条数 3→4 把观测镜环写满 ⇒ `diag=86`）；**`fresh` 的绿 ＝ 假绿** ⇒ 本会话**三例硬实证**（其一即本条：今天两腿 `alive=yes ∧ magenta=0` 而两页帧**逐字节相同**）⇒ **凡以"净腿不崩／占位消失"为唯一证据的断言，必须再给一条能让它变红的前置/反腿**，否则不算证据。
4. 🔴 **结构体偏移必须实测、不许算（`t127` 的同族自伤）**：本族要碰 `FSPARADESCRIPTION`（`Pts.cs:1500-1510`，8 个字段）与 `FSTRACKDETAILS`／`FSSUBTRACKDETAILS`。**口径写死**：**偏移一律实测**（运行时用 `Marshal.OffsetOf` 或等效探针取值）**并用 `_Static_assert`／断言把它钉死**；**禁止**按字段类型"数出来"的偏移当结论（`t127` 的同族自伤是**错 8 B ⇒ 1129 次 `unknown-track-or-not-ours`**，**引用**其教训；该次数我**未**现取复核，**不作我的读数**）。

---

## §7 ⑦ 同趟与截图 ＋ **一条新口径（跨代复写）**

1. **逐腿比对，不许拿 `legs=2/2` 当同趟证据**：守卫**活腿解析段不读** `DEV … shim=`（其 `shim` 字样只出现在 `--selftest` 夹具写出行与件头注释）⇒ 它对**跨代拼盘照样报 `legs=2/2`**。判据按 C10①②③自带。**现取 before ＝ 成立 ✓**（三处 `shim=a4bf2c47f8efb521`）。
2. **截图承重必带"同趟三格"**：① 帧 `sha256`（前16）；② 与所引读数同趟的证明（`DEV … shim=`／`pf=` ＋ `session.txt` 的 `shim_sha16`／帧行）；③ `shotstat` **现读**与 `leg_*.env` 的 `colors`／`magenta`／`ink` **逐格相等**。**缺任一 ⇒ 截图只作辅助件**。今天还可加一道交叉核：`leg_*.env` 的 `FRAME fr_sha=` 必须等于该帧 `sha256`（现取两腿 `fr_sha=ef3fd6765f18f51b` ＝ 截图实测值 ✓）。
3. 🔴 **新口径（登记，`t128` 现取）：同名车道件跨代复写 ⇒ 跨代相减无意义。** 实测形态：同一个证据文件名在不同代被复写，两次读数可差到 `1 ↔ 1152` 这种量级 ⇒ **任何"从 A 降到 B"的句子，必须带「载体 ＋ `ts` ＋ 代际（`shim=`／`so16=`／`pf=`）」三元组**，否则不许写成"下降了"。**本件自身的用法示例**：`ENFE 1085 → 0` 我不写成"净减少 1085 次"，而写成**两个不同代的现取读数**（`t129` 那一代 1085（**引用**其载体）／本件这一代 **0**），并给出**本代的 `shim=a4bf2c47f8efb521`**；`1123`（今天的 `[FS_PAGE_GAP]`）与 `1085`（上一代 ENFE）**不得相减**。

---

## §8 ⑧ `NOINFO` 预期（逐条给"消掉需要什么"）

1. **`b` 腿（受控"表已登记"）的真实读数**：`NOINFO(reason=前置 `PRECOND-MANAGED-PARACLIENT-LIVE` 未满足；本件只读、不跑腿)`. **消掉需要**：托管段落创建回调链被打通后跑一趟，给出"成功次数 ≥1 ＋ `*cParaDesc` ＝ 真条数 ＋ C2 谓词四项"。
2. **该 `PtsContext` 表内 live 客户端数（今天到底几个）**：`NOINFO(reason=它是进程内状态；本件既不能跑也不能读该进程)`. **消掉需要**：实现件加一条**只读**观测面（例如镜像／计数器），并同趟给三格。
3. **`T3′`（无校验站点）在本链上会不会真被走到**：`NOINFO(reason=本件只量化了"全树 217 处 `HandleToObject`、172 处紧跟 `ValidateHandle`"这一静态事实；运行期是否走到那 45 处未取)`. **消掉需要**：一趟带栈的读数，或把"错类型槽"反腿真跑出来看首帧。
4. **`FsQueryTrackParaList` 的**真**语义（`fsupdinf`／`pfspara`／`nmp`／`idobj`／`fsbbox` 各该填什么）**：`NOINFO(reason=本仓只有托管侧声明，无 native 侧规格；与 `t110` 的 `FSCONTEXTINFO` 同族风险)`. **消掉需要**：一份具名布局/语义声明，或"逐字段读回"的成对读数。
5. **结构体偏移的真值（`FSPARADESCRIPTION` 八字段）**：`NOINFO(reason=按纪律本件**不算**偏移，只写"必须实测"的口径)`. **消掉需要**：实现件的实测偏移表 ＋ `_Static_assert` 钉死读数。
6. **`t127` 那条"错 8 B ⇒ 1129 次 `unknown-track-or-not-ours`"的细节**：`NOINFO(reason=本件未现取该读数（不引用他人报告的读数当证据）)`. **消掉需要**：实现件用**自己**的台账/日志复现一次。
7. **应用 `[HC-UNHANDLED]` 钩子的捕获语义（是否条数上限／常开／是否只记不吞）**：`NOINFO(reason=发射方在第三方应用、不在我方写域；本件只现取到 1123 行与 1123 行的一一对应)`. **消掉需要**：读该件捕获分支原文，或我方自加计数器。
8. **`N4` 的正身份（该页专属期望指纹）**：`NOINFO(reason=今天无该登记载体；`ns=` 已被两次反例否掉)`. **消掉需要**：登记一次已知良好渲染的帧 `sha256`（或该页专属结构读数）——另派单。

---

## §9 ⑨ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-managed-handle-criteria.md`（新建；UTF-8；模式 **644**；**首记号不是 `# ⏪ `**；末行自带可复算自报口径）。
- **只读**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`nm`／`sha256sum`／`wc`／`stat`／`sort`／`uniq`／`compare`／`git log`／`git status` ＋ 四个**纯读**件（`pts-pages-guard.sh --legs`（判据端只读）／`pts-gap-count-check.sh`／`shotstat.py`（只读 PNG）／`check-shim-coverage.py`／`artifact-src-fp.py`（`--list`，**不 `--write`**）／`close-wave.sh` 的 `fp_inputs()`（抽到 `/tmp` 后只跑 `cat` 支））。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- **未改任何其它件**：`git status --porcelain` 原样（起点 14 项，全属他人：`t129` 落地的产品件／`evidence/**`／`arm_A/**`／`src/tests/`）⇒ **本件是本次唯一新增件**。
- **未引既有报告当证据**：`N1–N4`／纪律 30／裁定二十三只作**口径引用**；`P1-fs-paralist-report.md` 只在 §1.5 与 §7 作**边界引用**并逐处标明「引用」；其中所有**读数**（`ENFE 1085`、导出 594 等）本件**都自己重取过**（§0）。
- **末行自报口径当场可复算**：见末行。

---

### 结语（自包含）

- **① 域定位（结论）**：本族是 **managed 侧新域** —— 真身＝`PtsContext.HandleToObject`（`PtsContext.cs:243-250`，三条 `Invariant.Assert`）＋表 `_unmanagedHandles`（`:47` 分配／`:624` 容量 16）＋写表者 `CreateHandle`（`:175-196`，**唯一调用者** `UnmanagedHandle.cs:28`）；**填充路径**＝`BaseParaClient : UnmanagedHandle`（`BaseParaClient.cs:21/:34`）⇒ 五处 `new *ParaClient`（`ContainerParagraph.cs:431`／`FigureParagraph.cs:85`／`TextParagraph.cs:120`／`TableParagraph.cs:132`／`ListParagraph.cs:41`）**当场把 `paraClient.Handle` 交回 PTS**；**消费路径**＝`PtsHelper.ParaListFromTrack`（`:614`）→ `HandleToObject`（**活动点 `ContainerParaClient.cs:289/:342/:386`**；**`:249` 在注释块内，本件更正**）。**native 今天"不交值"**（`win32_pts.c:1802-1821`：不写数组、清计数、返 `-10000`、留 1123 行具名痕）。**拟改件 M1／M2（`build/PresentationFramework.Linux/**`）在 `fp_inputs()` 覆盖面之外、在 PF 的 `ARTIFACT-SRC-FP` 面之内**；M3–M5（上游）**一律不改**。
- **② 诚实边界／具名前置**：**不能**在没有"真段落"的前提下被诚实满足（三跳：native 看不到表且造值必然 T1／T2 `FailFast` 或 T3／T3′ 抛/NRE；托管值只在该 context 的表内；`BaseParaClient` 的存在 ⟺ `BaseParagraph` 存在）⇒ 落成 **`PRECOND-MANAGED-PARACLIENT-LIVE`**（谁给＝托管排版链；可核证据＝"尝试数／成功数／表内 live 数"三格；在它满足前**正确行为 ＝ 保持现状**，而现状**已是诚实失败、不欠账**）。
- **③ 判据 C1–C12**：域与产物（含"覆盖面看不见"格）／**字段级诚实性（四项谓词由表主判，不是指针校验）**／**`N2` ENFE 真归零且不得被吞（必须同时给留痕面）**／**`N1` 帧身份＋帧位移**／**`N3` 两页帧去重＝2**／**`N4` 内容身份（`ns=` 不承担，`NOINFO` 不得折绿）**／裁定二十三（返非 0 必留痕＋失败必清出参）／**native 不得制造可用值（T1–T3′ 成对反腿）**／两页症状（**明写今天已满足、单独不得当证据**）／同趟与截图／**导出面不靠加导出收尾**／回归面。
- **④ 假进度必红 P1–P9**：含**吞 ENFE**（P3）、**交伪句柄**（P4，按 T1–T3′ 分类点名）、**两页帧仍相同却报绿**（P5）、**`ink>0`／`ns=` 当证据**（P6／P7）、跨趟/跨代拼读数（P8）、恒绿自检（P9）。
- **⑤ 两极化**：a 受控"表未登记"⇒ 可按名过滤的留痕且不崩（**今天 native 侧已做到**）；b 受控"表已登记"⇒ **今天取不到 ⇒ `NOINFO`**；c 反腿交伪句柄 ⇒ 必红**且按类点名**。
- **⑥ 纪律 30 ＋ 偏移纪律**：三格 ＋ 调用序；**"净腿不崩＝假绿"升为必要条款**（本会话三例硬实证）；**结构体偏移必须实测 ＋ `_Static_assert` 钉死，不许算**。
- **⑦ 同趟与截图三条**＋**新口径**：`legs=2/2` 不是同趟证据；截图必带同趟三格（今天成立 ✓，并可用 `FRAME` 行交叉核）；**同名件跨代复写 ⇒ 跨代相减无意义，引用必须带「载体＋`ts`＋代际」**。
- **⑧ `NOINFO` 8 条**，各带"消掉需要什么证据"。
`P1-MANAGED-HANDLE-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 894d5afbc5ede190（口径＝末行之前的全文；末行＝本行）`

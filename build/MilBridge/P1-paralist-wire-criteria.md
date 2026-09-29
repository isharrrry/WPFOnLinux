# P1-W78 判据（先写）：把 `pfsparaclient` 接进段落列表（`FsQueryTrackParaList` 出参 → `PtsHelper.ParaListFromTrack` 入参）

本件是**判据先写**件（`work` 类）：先立判据、先立红榜、先立「做不到」的具名前置，**再把实现交给别人做**。
本件**不含**任何本次运行的腿读数（本席不跑腿、不占显、不 build）；凡本席现取到的**静态**证据一律带「件＋字段＋行＋sha16＋读取时刻」。

---

## §0 本件身份、使用方式与硬边界

- 载体：`build/MilBridge/P1-paralist-wire-criteria.md`（新件）。写者＝`scout`（只读侦察＋判据先写）。
- 本件**唯一**允许的写者动作就是本文件本身；`$N` 内其余件（尤其 `docs/ROUTES.md`、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`、`build/MilBridge/HANDOFF-NEXT.md`、`build/MilBridge/tools/defect-registry-declared.tsv`、`src/**`、`build/shims/**`）本席**一件未动**。
- 判据**只许收紧**：后续任何一件想改本件某条判据，只能「改窄／加严／加证据」，不许放宽；放宽须由队长出裁定并在册。
- 本件不是实现件，也不是复核件：实现由 runner 侧另起件；对实现的**独立复核**另起 `review` 件。

---

## §1 现取证据台账（读取时刻＝2026-09-29 17:55–17:57，本席本地，仅本次有效）

主树 HEAD＝`a7eb52c`（`git log --oneline -1`，读于 17:56），`git status --porcelain` 显示 6 项改动**全部属于他人**（`PtsPagesProbe/*` 与 `tools/pts-pages-guard.sh`），与本件无关。

| 件 | sha16 | 行 | 本席读到的字段/事实（原文摘录见 §10） |
|---|---|---|---|
| `PtsHost/BaseParaClient.cs` | `e48fc11de3f65d09` | `:21`,`:34` | `internal abstract class BaseParaClient : UnmanagedHandle`；`protected BaseParaClient(BaseParagraph paragraph) : base(paragraph.PtsContext)` |
| `PtsHost/UnmanagedHandle.cs` | `824adb562d83f63c` | `:25-29`,`:28`,`:34-45`,`:38` | 构造器即建句柄：`_handle = ptsContext.CreateHandle(this);`；`Dispose()` 中 `_ptsContext.ReleaseHandle(_handle);` |
| `PtsHost/PtsContext.cs` | `c91e3f94d1188ece` | `:175-178` | `CreateHandle(object obj)`：`:177 Assert(obj != null)`、`:178 Assert(!this.Disposed, "PtsContext is already disposed.")` |
| 同上 | 同上 | `:206-215` | `ReleaseHandle(IntPtr)`：`:209/:210/:211` 三条 `Invariant.Assert`（原文见 §10）；`:212-214` 释放三步＝**把索引压回自由链** |
| 同上 | 同上 | `:243-250` | `HandleToObject(IntPtr)`：`:246-248` 三条 `Invariant.Assert`；`:249 return _unmanagedHandles[handleLong].Obj;` |
| 同上 | 同上 | `:645-648`,`:624` | `internal bool IsHandle() { return (Obj != null && Index == 0); }`；`_defaultHandlesCapacity = 16` |
| `PtsHost/PtsHost.cs` | `d1976dcc8362c8f9` | `:724-749` | `CreateParaclient(...)`：`:734 para.CreateParaclient(out pfsparaclient);`，异常一律 `pfsparaclient = IntPtr.Zero` ＋ `fserr = fserrCallbackException` |
| 同上 | 同上 | `:776-798` | `DestroyParaclient(...)`：`:783 HandleToObject(pfsparaclient) as BaseParaClient`、**`:785 paraClient.Dispose();`** |
| 同上 | 同上 | `:750-775` | `TransferDisplayInfo(...)`（两个句柄都在，各自 `ValidateHandle`） |
| `PtsHost/Pts.cs` | `1a8575a18767a956` | `:1500-1510` | `FSPARADESCRIPTION` 字段序：`fsupdinf, pfspara, pfsparaclient, nmp, idobj, dvrUsed, fsbbox, dvrTopSpace` |
| 同上 | 同上 | `:1943-1947`,`:1934` | `FSUPDATEINFO { FSKUPDATE fskupd; int dvrShifted; }`；`FSKUPDATGE`-族枚举 `FSKUPDATGE : int` |
| 同上 | 同上 | `:989-993` | `FSBBOX { int fDefined; FSRECT fsrc; }` |
| `PtsHost/PtsHelper.cs` | `f2ed9552e983fed1` | `:117`,`:134`,`:197`,`:225` | `ArrangeTrack`（`:134` 调 `ParaListFromTrack`）＋ `UpdateTrackVisuals`（`:225` 调）——两个**在排版/更新帧内**的消费者 |
| `PtsHost/FlowDocumentPage.cs` | `cd4d1c09c3edef3f` | `:51`,`:199` | `FormatFinite`；其体内 `using(_structuralCache.SetDocumentFormatContext(this))`（本次 `sed -n '125,205p'` 内第 75 行 ⇒ `:199`）＝**在册窗口** |
| 同上 | 同上 | `:529`,`:541`,`:547` | `GetTextContentRangeFromColumn`：`:541` 调 `ParaListFromTrack`，`:547 HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient` |
| 同上 | 同上 | `:564`,`:578`,`:583` | `GetParagraphResultsFromColumn`：`:578` 调 `ParaListFromTrack`，`:583` 同上反查 |
| 同上 | 同上 | `:410`,`:412` | `GetColumnResults`：方法体起 `:410`，其前 35 行内 `grep` 仅命中 `:412 Invariant.Assert(!IsDisposed);`，**未见** `SetDocumentFormatContext`（**局部观察**，见 §2.2 的诚实边界） |
| `PtsHost/ContainerParaClient.cs` | `0d2e6aa79fdc035a` | `:289`,`:342`,`:386` | 三处 `PtsContext.HandleToObject(arrayParaDesc[i].pfsparaclient) as BaseParaClient`（`:249` 位于注释块内，**非活点**） |
| `PtsHost/ListParaClient.cs`（引 §1 同批读取） | — | `:82` | 同上形态的反查 |
| `PtsHost/FigureParaClient.cs` `FloaterParaClient.cs` `SubpageParaClient.cs`（引 §1 同批） | — | `:581/:621`、`:590/:630`、`…/:617/:651` 族 | 同上形态：`arrayParaDesc[i].pfsparaclient → HandleToObject` |
| `documents/ColumnResult.cs` | `5d9bdf5d9e783398` | `:151/:157/:161/:165`、`:228/:234/:238/:242` | 查询 API 路径：按页/图/浮动/子页分别调 `GetParagraphResultsFromColumn` 与 `GetTextContentRangeFromColumn` |
| `PtsHost/StructuralCache.cs` | `1ecca9f7d0b6cce9` | `:181`,`:184` | 在册注释：`ReleaseHandle` 会抛异常 ⇒ 必须先判 `!_ptsContext.Disposed`；`:184 if (_section != null && !_ptsContext.Disposed)` |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `6d967d8843bd902b`（**在飞**，mtime 17:48:56，256008 B） | `:2700-2720` | `FsQueryTrackParaList` 现实现：`*cParaDesc = 0`，reason 阶梯含 `paraclient-table-not-native`，**一律返 `-10000`（`WPF_PTS_ERR_NOT_IMPLEMENTED`）**，不写 `rgParaDesc` 一个字节 |

⚠️ `win32_pts.c` 是**在飞件**（本席读取时刻与摘要时刻 sha16 已不同）⇒ 本件对它的引用一律标注「本席读取时刻的生成」，实现者开工前须重新取 sha16；若已变，本件对应条目按 §9 走追加（只增不改）。

### §1.1 `FSPARADESCRIPTION.pfsparaclient` 的偏移：**必须实测**

按 `Pts.cs:1500-1510` 的字段序 ＋ `FSUPDATEINFO`＝8 B（`FSKUPDATGE:int` 4 B ＋ `int` 4 B）＋ 64 位 `IntPtr`＝8 B，**计算值**为 `pfsparaclient @ +16`、`pfspara @ +8`、`nmp @ +24`、`sizeof(FSPARADESCRIPTION) = 64`。
**这些只是预期值，不许当依据**：`t127` 前例（偏移算错 8 B ⇒ 1129× `unknown-track-or-not-ours` 自伤）在册。实现件必须给出**实测**读数（`offsetof`/`_Static_assert` 打印，或等价字节级读回），并与上式比对；不一致时以实测为准并记「计算值错在哪」。

---

## §2 四个设计问的判词（本席据 §1 现取证据给出；可被**同代**台账反驳）

### §2.1 ① 句柄生存期 vs 持有期：**对象生存期**，不是调用窗口

**判词（本席）**：`pfsparaclient` 的值是**托管 `BaseParaClient` 对象自己的句柄**，其有效期的口径是**该托管对象的存活状态**，与「哪一次 native 调用窗口」无关。

**据（三段闭合链，全部为本席现取）**：
1. `BaseParaClient.cs:21` ⇒ 每个段落客户端**是** `UnmanagedHandle`；`:34` 构造器把 `paragraph.PtsContext` 交给基类。
2. `UnmanagedHandle.cs:28` ⇒ 构造器里 `_handle = ptsContext.CreateHandle(this);` ⇒ **句柄在建对象时产生**（而建对象发生在托管 `+176` 回调 `CreateParaclient` 内，见 `PtsHost.cs:734`）。
3. `UnmanagedHandle.cs:38` ⇒ `Dispose()` 里 `_ptsContext.ReleaseHandle(_handle);`；而**全仓 `ReleaseHandle` 的唯一调用点就在这里**（`grep -rn 'ReleaseHandle' …/PtsHost/*.cs`：仅 `PtsContext.cs:206` 定义、`UnmanagedHandle.cs:38` 调用；`StructuralCache.cs:181` 是注释）⇒ **回收由该对象的 `Dispose()` 触发**。
4. `PtsHost.cs:776-798` ⇒ `DestroyParaclient` 体内 `:785 paraClient.Dispose();` ⇒ **native 侧 `+192` 就是那个触发者**。

⇒ 结论：**持有期 ＝ 从「`+176` 建出该对象」到「`+192` 销毁该对象」**。跨不跨帧、在不在窗口内，都不改变有效性。

**两套判据（任务要求的两问）**：

- **Case I（本案走这条）「对象存活即有效」**：判据＝有效性谓词只用对象存活状态。
  - I-1 活证：同一次运行内，`+176` 产出的值 `h` 被填进 `rgParaDesc` 后，消费者 `HandleToObject(h) as BaseParaClient` **非 null**，且**同一 run 内**其身份与 `+176` 那次的产出**同值**。
  - I-2 死证（**只作回收证据，不作有效性主体**）：`+192` 之后再用同一个 `h` ⇒ 必须**不再**解析成同一对象。⚠️ 死证的表现有**两种**且必须具名区分（见 §2.1.1）：`-100002`/FailFast（未被复用）与 `resolve=wrong-object`（已被复用）。**不许**把「死后的表现」反过来当「活着的证据」。
  - I-3 反例门：`resolve=wrong-object` 出现**任一次** ⇒ 本条判红（P4）。
- **Case II（「只在本次调用期内有效」）**：判据＝实现者必须证「**所有**消费者都在**同一个** native 调用返回后的**同一帧内**完成消费」，且不存在跨帧消费。
  - 本席现取证据**反证 Case II**：消费者共 4 类 6 处 —— `PtsHelper.ArrangeTrack:134`（排版帧）、`PtsHelper.UpdateTrackVisuals:225`（更新帧）、`FlowDocumentPage:541`/`:578` 与 `FigureParaClient`/`FloaterParaClient`/`SubpageParaClient` 同族（**查询帧**，驱动者为 `ColumnResult.cs:151-165`/`:228-242`），以及 `ContainerParaClient.cs:289/:342/:386`、`ListParaClient.cs:82` 的递归反查。
  - 其中查询帧**不是**排版帧：`ColumnResult` 的构造点在 `FlowDocumentPage.cs:410 GetColumnResults`（`:444`/`:497`）与 `FigureParaClient.cs:641` 族，与 `FormatFinite`（`:51`）不是同一方法；且 `:410-445` 内**只见** `Assert(!IsDisposed)`、**不见**窗口。
  - ⇒ **Case II 与在册证据冲突**。若实现者仍选 Case II（例如「返回前先把句柄释放／把表项回收」），须提交台账**逐条推翻**上列锚点；否则**判红**（按 P1/P4）。

#### §2.1.1 为何「已释放但未被复用」能查、而「已释放且已被复用」查不到（本席现取，ABA 缺口）

- 活槽判据：`PtsContext.cs:645-648`＝`Obj != null && Index == 0`。
- `IsHandle()` 为假 ⇒ `HandleToObject:248` 或 `ReleaseHandle:211` 的 `Invariant.Assert` 命中 ⇒ **FailFast，不可捕获**（`PtsHost` 的 `try/catch` **接不住**它；`catch` 只能接托管异常）。
- `ReleaseHandle:212-214` 把该索引**压回自由链**（`_unmanagedHandles[0].Index = handleLong`），而 `CreateHandle` 从自由链**取用** ⇒ **同一个索引会被下一个新对象拿走**；此后再拿旧值反查：槽里 `Obj＝新对象`、`Index＝0` ⇒ `IsHandle()` **为真** ⇒ `HandleToObject` **静默返回另一个对象**；若新对象也是 `BaseParaClient`，`as BaseParaClient` **还会成功**。
⇒ **这是本跳最危险的失败面**：不报错、不崩、拿错对象继续排版。它是 P4 红项的机制依据，也是本件要求「消费者行必须打印身份＋解析结果类别」的原因。

### §2.2 ② `FsQueryTrackParaList` 的窗口约束：**窗口既非有效性的必要条件，也不构成充分条件**

**判词**：填充**不必**发生在 `SetDocumentFormatContext` 窗口内；窗口只影响两件事：①`CreateHandle` 会在上下文已 dispose 时 `Assert(!this.Disposed)`（`PtsContext.cs:178`）；②回调可入性（窗口外调用常伴 `-100002`，见 `t149` 在册的两因不分问题）。**句柄是否可用，只看对象是否活着。**

**诚实边界（不许越读）**：本席只做了**局部**观察——`FlowDocumentPage.cs:410-445` 内未见窗口；**未**证明其全部调用链都在窗口外（上游调用者仍可能外裹窗口）。⇒ 因此本判词**不写成公理**，而落成**两腿实验判据**：

- **W-1 窗内腿**：在排版帧内到达的调用（`+80 → +136 → +176 → FsQueryTrackParaList` 同链）⇒ 期望 `rc=0`。
- **W-2 窗外腿**：使用在册的窗外装置（`t151` 的 `wpf_pts_drive_probe2_oow` 对应腿）⇒ 期望 `rc=0` **且与 W-1 同值解析成功**。
- **判定**：两腿都绿 ⇒ 「窗口无关」**有据**；**只有一腿可跑 ⇒ 该格 `NOINFO`**，禁止把单腿读成「窗口无关」；两腿结论不一致 ⇒ 判「窗口敏感」，并把差异具名到 reason/异常文本。
- **不许**用 `[DRIVE-PROBE-SKIP] reason=gate-off` 的**缺席**当「窗外腿已跑」（失败/跳过专用行，P7）。

### §2.3 ③ 谁回收 `+192`、什么时候回收

**判词**：**回收责任在托管侧对象自己的 `Dispose()`，触发点在 native 的 `+192`（`DestroyParaclient`）；`FsQueryTrackParaList` 自己不许回收，也不许在返回前回收。**

**据**：§2.1 的 1–4 条 ＋ `PtsHost.cs:785`。

**可伪判据**：
- R-1 **单次性**：同一个 `h` 的 `+192` **只许成功一次**。第二次 ⇒ `ReleaseHandle:211` 的 `Assert(…IsHandle(), "Handle has been already released.")` ⇒ **FailFast**（不是错误码）。⇒ 因此**双重销毁不可作为可观测读数**，只能作**红项**：凡日志/设计里出现「同一 `h` 被销毁两次」⇒ 判红。
- R-2 **上下文已 dispose 后回收**：`ReleaseHandle:209` `Assert(!_disposeCompleted, "PtsContext is already disposed.")` ⇒ 同为 FailFast。在册同族注释：`StructuralCache.cs:181`。⇒ 回收**不得晚于**上下文销毁。
- R-3 **每次 `+176` 建新对象**（在册 `t156`：`PARACLIENT-NEW-PER-CALL`、10 处 override 各 `new *ParaClient(this)`）⇒ 持有期与**那一次** `+176` 绑定；把上一轮的值留到下一轮用，属于 P3/P4 域。
- R-4 **回收正确性不可由 native 单侧证明**：自由链在托管 `_unmanagedHandles[0].Index` 内。若实现件无法取得该链的可观测读数 ⇒ 该格记 **`PRECOND-NO-HANDLE-ACCOUNTING`** 并落 `NOINFO`；**严禁**用 `rc=0` 冒充「回收正确」。

### §2.4 ④ 绿读数：逐字（本件承诺的验收字符串）

实现件必须让装置**逐字**打印下面这族行（token 顺序固定、`=` 两侧无空格；允许在行尾追加新 token，**不许**删除或改名；确需改名须先由队长改本件，判据只许收紧）。

**成功行（填充路径）**
```
[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=<N> n=<M> h0=<hex> src=managed-176 run=<标记> ok=<n> gap=<m>
```
**拒绝行（失败专用，只在拒时出现）**
```
[FSPARALIST-FILL] rc=<int> reason=<具名> entry=FsQueryTrackParaList … ok=<n> gap=<m>
```
**消费者行（每个被反查的条目一行）**
```
[FSPARALIST-CONSUME] i=<i> h=<hex> resolve=ok|wrong-object|failfast|exception type=<托管类名或 none> via=<调用点>
```
**「绿」＝同时满足全部下列 7 条**（缺一即不绿）：
1. `rc=0`（`fserrNone`）；
2. `n >= 1` 且 `n == cParas`（当真填；`n < cParas` 视为部分填充 ⇒ 不绿）；
3. `src=managed-176`（句柄来源受控，见 §6）；
4. 消费者行 `resolve=ok`，且 `h0` 与**同一 run** 的 `+176` 产出**同值**；
5. 本腿中 `resolve=wrong-object`、`resolve=failfast`、`rc=-100002`、`rc=-10000` 各自出现 **0** 次；
6. **≥2 个独立样本**（不同 PID/不同启动时刻，裁定 38）判定一致；不一致 ⇒ 判「不稳定」⇒ 结论降 `NOINFO` 并在册；
7. 每条读数带齐 §7 的三格 ＋ 门状态。

> 第 2 条的 `entry=` 与 `h0` 的 hex 形态（`0x` 前缀、小写）也必须一致；`h0=0` 一律视为**未填**，不是「零号句柄」。

---

## §3 成功语义（`fserr` 四分类，禁双向滑移）

| 值 | 名（在册） | 本件口径 |
|---|---|---|
| `0` | `fserrNone` | **成功**（仍须过 §2.4 的 7 条，`rc=0` 本身不是内容证据） |
| `-100002` | `fserrCallbackException` | **托管回调内抛异常**：真因在 `PtsContext.CallbackException`，**必须**把其 `ToString()` 摘要留痕；不得只说「-100002」 |
| `-10000` | `tserrNotImplemented` | **诚实未实现**（**这就是本跳开工前的现状**，`win32_pts.c:2719` 现取）。开工后本入口**再出现 `-10000` ⇒ 未完成** |
| 其它 | 未在册 | **非成功且未分类** ⇒ 必须**具名**报出并单列，**不许**归入上三类（既不许当成功，也不许当「已知失败」） |

⚠️ `-100002` **有两个不可区分的原因**（在册 `t149`：错型句柄 vs 窗外 NRE）⇒ 凡出现 `-100002`，本件要求同时给出窗内/窗外**成对**对照读数，否则该格 `NOINFO`。

---

## §4 下游承接者（acceptor）与**禁用件**

**在册承接者（必须有一个真绿）**
- `PtsHelper.ArrangeTrack`（`PtsHelper.cs:117`，调用点 `:134`）→ `ArrangeParaList`：排版帧内消费 `arrayParaDesc[i].pfsparaclient`。
- `PtsHelper.UpdateTrackVisuals`（`:197`，调用点 `:225`）。
- 查询路径：`FlowDocumentPage.cs:541/:578`、`FigureParaClient`/`FloaterParaClient`/`SubpageParaClient` 同族（驱动 `ColumnResult.cs:151-165`/`:228-242`）。
- 递归反查：`ContainerParaClient.cs:289/:342/:386`、`ListParaClient.cs:82`。
⇒ 验收要求：**至少一个承接者给出「真取到内容/几何」的读数**，且该读数与 §2.4 的 `h0` 同值同 run。

**禁用件（永真/结构性恒绿，一律不得进判据）**
1. `+200 FInterruptFormattingAfterPara`：在册 stub，**不读任何字段** ⇒ 常量绿陷阱，**禁用**（`t154` 已禁）。
2. `+56`（`GetNextSection`）：在册 by-design 返回 `fSuccess=0, nmsNext=0` ⇒ **恒绿**，禁用。
3. `FSPARADESCRIPTION` 尾巴的 `fsbbox`/`dvrTopSpace`：在「内容被真排版」之前一律 `NOINFO`（它们由排版方法填，本跳不负责），**不许**用它们「非零」当填充成功。
4. 账面上的 `alive=yes` / `magenta=0` / `FRAME_EMPTY_SET` / 行带指标＝1 这类**今天已满足**的网症格与**死锚**：单独**永不**构成证据（在册 `t142` 已测：色锚 0 px、行带指标恒 1）。

**与「长持有」的冲突（必须在实现里显式处理）**：`+192` 是**销毁**（`PtsHost.cs:785` → `Dispose` → `ReleaseHandle`）⇒ **「长持有」与「按时回收」不可兼得于同一对象**。本件的口径是：持有期＝对象存活期（§2.1），因此实现**不得**为了让句柄「活得更久」而阻止 `+192`；延长持有期的唯一合法形态是**让对象本身活得更久**（即不调 `+192`），而那是排版流程的决定，**不是本跳能自选的口径** ⇒ 若实现者自选「延迟销毁」，须走队长裁定并在册。

---

## §5 假进度红榜 P1–P10（命中任一 ⇒ 判红，不判绿）

- **P1** 把 `FsQueryTrackParaList` 的返回值改成 `0` 而**没有真句柄**（假成功）。现状件已明写「永不返 0」`（win32_pts.c:2712-2719）`，改回 0 必须伴随 §2.4 全部 7 条。
- **P2** 先置 `*cParaDesc = cParas` 再（或干脆不）填 `rgParaDesc`：⇒ 上级读未初始化内存。**`*cParaDesc` 只许在真填完成后置**，且值＝**实际**条数。
- **P3** native **自造句柄**：写指针 → 越界 ⇒ FailFast；写 `0`/小整数 → 槽内非 `BaseParaClient` ⇒ `as` 得 null ⇒ NRE/`-100002`。**唯一合法来源＝本 run 内托管 `+176` 回调真返回的值**。
- **P4** **use-after-recycle**：`+192` 之后再读同一值（或把上一轮的值留到下一轮）⇒ 见 §2.1.1 ⇒ **静默错对象**。命中即红。
- **P5** 「句柄非零」＝「列表内容可用」（`t127` 同族字段级诚实性）。必须证**内容侧**：解析成功 **且** 身份与 `+176` 同值 **且** 承接者真取到内容/几何。
- **P6** 跨代相减／搬上一代列印读数（纪律 30）：每条读数必须带当次三格；同名件跨代复写 ⇒ 相减无意义。
- **P7** 用**失败专用行**的缺席当「没被调用」（`[FS_PAGE_GAP]`、`[HC-UNHANDLED]`、`[DRIVE-PROBE-SKIP] reason=gate-off`）。
- **P8** 采**今天已满足**的网症格（`alive=yes`、`magenta=0`、净腿不崩）当证据；在册三例「净腿不崩＝假绿」。
- **P9** **常量绿／永真器**：见 §4 禁用件 1–4；以及「只跑一条腿就宣布窗口无关」（§2.2 W-3）。
- **P10** **单样本**（裁定 38：机制级断言须 ≥2 个独立样本）；以及把 `NOINFO` 写成绿。

---

## §6 T3 夹具与**零假值**

**T3 夹具（装置自检，不产出内容判词）**：以在册的 `WPF_PTS_DRIVE_PROBE_FAKE_NMS=-2` 进入 T3 模式，链上各格使用**已知哨兵**：

| 格 | 哨兵 | 含义 |
|---|---|---|
| `sect` | `0x1` | 真 `doc` 上下文（**真值**，非哨兵：由 `wpf_pts_doc_find` 在册） |
| `nms` | `0x2` | `+80` 产出（`t151` 在册） |
| `nmp` | `0x3` | `+136` 产出（`t155` 在册，已证＝`ContainerParagraph._firstChild`） |
| `h1` | `0x4` | `+176` 第一次产出 |
| `h2` | `0x5` | `+176` 第二次产出（非幂等证据） |

**T3 判词只能判「管线通」**：T3 腿出现的任何「填充成功」**不得**升级为内容判词；内容面在 T3 腿一律 `NOINFO`。

**零假值铁律**：
- **真腿（非 T3）内出现任何哨兵值（`0x2/0x3/0x4/0x5` 作为句柄/`nms`/`nmp`）⇒ 该读数作废**，并在册具名。
- 反向：**假值必须证「∉ 值域」**。本件口径：假值只许取**明显大于**当次 `_unmanagedHandles.Length` 上界的形态（例如 `0x5EED_0001` 级），且**只许注入到不会到达 `HandleToObject` 的路径**——因为到达即 `Assert(handleLong < _unmanagedHandles.Length)` ⇒ **FailFast 不可捕获**。**不许**用「小整数」当假句柄去试（那是 P3 自伤，`t127` 前例）。
- `src=managed-176` 是「来源受控」的唯一在册标记；凡 `src≠managed-176` 的成功行一律不绿。

---

## §7 逐格命令表 ＋ 纪律 30 三格（**每条读数**都要带）

| 格 | 命令（由 runner 执行；本席不跑） | 期望 | 备注 |
|---|---|---|---|
| G1 装置门状态 | `env \| grep -E '^WPF_PTS_DRIVE_PROBE'`（或在腿日志内打印） | `WPF_PTS_DRIVE_PROBE=1`、`_N=<n>`、`_FAKE_NMS=<值或未设>` | 门**关**时本跳全部格 ≡ `NOINFO`（`[DRIVE-PROBE-SKIP] reason=gate-off`） |
| G2 真腿（窗内） | `<在册腿命令> >out 2>err; echo $?` | `rc=0` ∧ §2.4 七条 | 必须 `cmd >out 2>err; echo $?`，**不许**从管道尾巴取 `rc`（本席历史自伤） |
| G3 真腿（窗外） | 在册 OOW 腿（`t151` 装置） | 同 G2 | 见 §2.2 W-2 |
| G4 T3 自检 | `WPF_PTS_DRIVE_PROBE_FAKE_NMS=-2 …` | 管线通；内容面 `NOINFO` | §6 |
| G5 第二独立样本 | 重跑 G2/G3（新 PID／新时刻） | 与首样本**判定一致** | 裁定 38 |
| G6 承接者读数 | `grep -c 'FSPARALIST-CONSUME' <out>` ＋ 逐行 `resolve=` | 至少 1 行 `resolve=ok`；`wrong-object`＝0 | §4 |
| G7 制品面 | `pts-pages-guard.sh --legs <dir>`（在册） | 本跳**不要求**它转绿；只作在册对照 | guard 的 `NOINFO` 不算红 |

**纪律 30 三格（每条读数必附）**：
1. **进程新鲜度**：PID ＋ 启动时刻 ＋ 完整命令行；
2. **所依赖计数器**：`ok=`/`gap=`（`g_pts_fsp_pl_ok`/`g_pts_fsp_pl_gap`）＋门三个变量；
3. **`rc`·`diag` 原文**：不是转述、不是摘要，是原始行（含 `reason=` 与 `CallbackException` 文本若有）。

**禁**：把上一代列印当本次读数；把 stdout 与 stderr 混读（`inner.sh` 类装置的既有陷阱）；`pkill`/`pgrep -f`（只许按 PID）。

---

## §8 `NOINFO` 面与「做不到」的具名前置

**`NOINFO` 既不算绿也不算红**。取不到 ⇒ 具名原因，不许留空、不许填 `rc=0`。

**允许判「本跳做不到」的具名 `PRECOND-*`（命中任一即可成立，但必须带现取证据）**：
- `PRECOND-NO-HANDLE-SOURCE`：本 run 内托管 `+176`（`CreateParaclient`）**一次都没被调** ⇒ 不存在可合法填入的句柄值（`FsQueryTrackParaList` 的唯一合法来源缺失）。证据＝同 run 的 `+176` 调用/产出迹为 0。
- `PRECOND-CONSUMER-NOT-REACHED`：§4 全部承接者在本 run 内均未被到达（**须用计数/成功行存在性证，不许用失败专用行的缺席证**）。
- `PRECOND-WINDOW-LIFETIME-CONFLICT`：若同时证明「填充必须在窗口内生成」∧「消费只在窗口外」∧「窗口退出即回收句柄」三者 ⇒ 结构冲突。（**本席现取证据倾向此条不成立**：§2.2 反证 Case II。）
- `PRECOND-DOUBLE-DESTROY`：若观测到同一 `h` 被 `+192` 两次 ⇒ FailFast 不可捕获 ⇒ 该腿不可跑。
- `PRECOND-NO-MANAGED-SIDE-WRITER`：托管侧在本波写域内无可写点（须具名到件与行）。
- `PRECOND-NO-HANDLE-ACCOUNTING`：取得不到自由链/句柄表的可观测读数 ⇒ R-4 落 `NOINFO`。

**反面**：`NOINFO` 与 `PRECOND-*` **不许**被用来替代一条本可跑但没跑的腿（那是 P10）。凡「本可跑而未跑」，判红。

---

## §9 本件自身的验收（本件如何被复核）

1. 本件为**新件**，末行＝自证行（`head -n -1 <本件> | sha256sum | cut -c1-16`），模式 `644`，首 token 非 `# ⏪ `。
2. 复核者须**独立重取** §1 表中至少 6 件的 sha16 与引用行（`sed -n` 打原文），并比对；不一致处按追加（**只增不改**）。
3. 本件**未被授权**改写任何判据为「更宽」；任何实现件若与本件冲突，冲突本身要进裁定，不许就地解释。
4. 本件不含腿读数 ⇒ 不存在「本席实测 vs 引述」混淆；凡本席引述他人件的数字，本件**一律未引**（§1 全为本席直接读取的静态件）。

---

## §10 附录：现取原文摘录（仅本次有效，读取时刻 2026-09-29 17:55–17:57）

`PtsContext.cs:206-215`（sha16 `c91e3f94d1188ece`）：
```
        internal void ReleaseHandle(IntPtr handle)
        {
            long handleLong = (long)handle;
            Invariant.Assert(!_disposeCompleted, "PtsContext is already disposed."); // May be called from Dispose.
            Invariant.Assert(handleLong > 0 && handleLong < _unmanagedHandles.Length, "Invalid object handle.");
            Invariant.Assert(_unmanagedHandles[handleLong].IsHandle(), "Handle has been already released.");
            _unmanagedHandles[handleLong].Obj = null;
            _unmanagedHandles[handleLong].Index = _unmanagedHandles[0].Index;
            _unmanagedHandles[0].Index = handleLong;
        }
```
`PtsContext.cs:243-250`（同件）：
```
        internal object HandleToObject(IntPtr handle)
        {
            long handleLong = (long)handle;
            Invariant.Assert(!_disposeCompleted, "PtsContext is already disposed."); // May be called from Dispose.
            Invariant.Assert(handleLong > 0 && handleLong < _unmanagedHandles.Length, "Invalid object handle.");
            Invariant.Assert(_unmanagedHandles[handleLong].IsHandle(), "Handle has been already released.");
            return _unmanagedHandles[handleLong].Obj;
        }
```
`PtsContext.cs:645-648`（同件）：`internal bool IsHandle()` ⇒ `return (Obj != null && Index == 0);`
`UnmanagedHandle.cs:25-29`／`:34-45`（sha16 `824adb562d83f63c`）：构造器 `_handle = ptsContext.CreateHandle(this);`；`Dispose()` 内 `_ptsContext.ReleaseHandle(_handle);`、`finally { _handle = IntPtr.Zero; }`、`GC.SuppressFinalize(this);`
`PtsHost.cs:776-785`（sha16 `d1976dcc8362c8f9`）：`DestroyParaclient(...)` ⇒ `BaseParaClient paraClient = PtsContext.HandleToObject(pfsparaclient) as BaseParaClient; PTS.ValidateHandle(paraClient); paraClient.Dispose();`
`Pts.cs:1500-1510`（sha16 `1a8575a18767a956`）：`FSPARADESCRIPTION { FSUPDATEINFO fsupdinf; IntPtr pfspara; IntPtr pfsparaclient; IntPtr nmp; int idobj; int dvrUsed; FSBBOX fsbbox; int dvrTopSpace; }`
`win32_pts.c:2700-2720`（sha16 `6d967d8843bd902b`，**在飞**）：现实现 `*cParaDesc = 0` 后按 reason 阶梯拒绝，最后 `reason = "paraclient-table-not-native"`、`return WPF_PTS_ERR_NOT_IMPLEMENTED;`（注释自述「本步**永不**返 0（返 0 ＝ 假成功）」）。

---

**判词（本席）**：本跳的四个设计问均已给出**可执行**判据；其中 ① 由 §2.1 的三段闭合链**判定为对象生存期口径**、② 落成两腿实验、③ 判定回收责任在托管 `Dispose()`／触发点 `+192` 并给出三条可伪判据与一条 `PRECOND-*`、④ 给出逐字绿读数与七条合取。本席**不主张**本跳已成绿：在册现状是 `-10000`（`win32_pts.c:2719` 现取），本件只负责把「绿」定义到能被独立复核的程度。
`P1-paralist-wire-criteria-自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 2e7c9d4613e7d658（口径＝末行之前的全文；末行＝本行）`

# P1-W60 · W8「**最小驱动探针**」预登记判据 —— native 真调 `pfnGetNextSection`(+56)／`pfnGetMainTextSegment`(+80)：**在今天的托管态下这两个回调真能返回活句柄吗**

> **本件是判据件（先写），不是实现件**：**不做**实现、**不构建**、**不跑腿**、**不占显示位**、**不跑整趟门禁**、**不 `git add/commit/push`**；**不碰任何源件**（`runner` 的下一件会写 `src/**`）。
> **唯一写入** ＝ 本件 `build/MilBridge/P1-drive-probe-criteria.md`。
> **一切读数由我现取**（命令与输出原样贴出）；引他人载体处**逐处标注**「引自 X 载体，本席未独立复算」＋**取值时刻**；**不预填任何运行期读数**（探针要产出的那些格，本件全部留空／记 `NOINFO`）。
> **读取时刻**：`ts=2026-09-29T14:22:57.937+0800`（起点）→ `ts=2026-09-29T14:23:40.728+0800`（末取，见 §8）。

---

## §0 现取快照 ＋ 一处**代际更正**

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`32b810a`**（`feat(#81): t133 FSCBK 槽偏移实测（三条独立仪器+九腿两极化）+ t138 声明序全表 —— 双路径 8/8 交叉闭合，PRECOND-MEASURED-FSCBK-SLOT-OFFSETS 解除；裁定三十三`） | `git log --oneline -3` |
| 导出面 | `nm … \| grep -c .` ＝ **594** ＝ `wc -l …/exports.txt` ＝ **594** | `nm`／`wc -l` |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | **`26af5a26b984b99e`**（另一车道在飞；本件**只读**它） | `sha256sum` |
| 证据面 | `evidence/app_g1.log` ＝ **`84db0eb62d15e0b2`**（551555 B，`mtime 2026-09-29 14:12:09.729130105 +0800`） | `sha256sum`／`stat` |
| 🔴 **代际更正（写死，供引用）** | 任务书引 `t138` 载体为「319 行／`614d60178dc44692…`」，那是**上一代**；**现盘 `build/MilBridge/P1-fscbk-slot-recon.md` ＝ 365 行／`1d1e46bb31a97aa8b9977a8c1326ebf6eab5a1e40a4baf7822372d3e420aded8`**（我按队长追加指令把 §5 占位填成真对照之后）。⇒ **引用必须带代际**（本件按 §7 第 3 条的"同名件跨代复写"纪律执行） | `stat`／`sha256sum` |

---

## §1 ① 可行性前置（**本件第一产出**；逐跳 `文件:行` 原文照抄）

### 1.1 两个回调的**签名与"读什么入参"**（现取原文，**这决定前置**）

```
Pts.cs:2029  internal delegate int GetNextSection(
2030:            IntPtr pfsclient,                   // IN:  client opaque data
2031:            IntPtr nmsCur,                      // IN:  name of current section
2032:            out int fSuccess,                   // OUT: next section exists
2033:            out IntPtr nmsNext);                // OUT: name of the next section
Pts.cs:2051  internal delegate int GetMainTextSegment(
2052:            IntPtr pfsclient,                   // IN:  client opaque data
2053:            IntPtr nmsSection,                  // IN:  name of section
2054:            out IntPtr nmSegment);              // OUT: name of the main text segment for this section
```
**托管实现**（现取原文，两份都在 `PtsHost.cs`）：
```
PtsHost.cs:312-338  GetNextSection:
    Section section = PtsContext.HandleToObject(nmsCur) as Section;      // :321
    PTS.ValidateHandle(section);                                        // :322
    section.GetNextSection(out fSuccess, out nmsNext);                  // :323
    catch (Exception e) { fSuccess = 0; nmsNext = IntPtr.Zero; PtsContext.CallbackException = e; fserr = PTS.fserrCallbackException; }   // :325-330
PtsHost.cs:408-433  GetMainTextSegment:
    Section section = PtsContext.HandleToObject(nmsSection) as Section;  // :416
    PTS.ValidateHandle(section);                                        // :417
    section.GetMainTextSegment(out nmSegment);                          // :418
    catch (Exception e) { nmSegment = IntPtr.Zero; … fserr = PTS.fserrCallbackException; }  // :420-425
```
🔴 **两条硬事实（本件现取，判据建在它们上）**：
1. **两处实现都不读 `pfsclient`** —— 它们只用 `nmsCur`／`nmsSection`。（⇒ `pfsclient` 传什么都不影响这两条的成败；但**判据仍要求把它如实记下**，见 §2.4。）
2. **两张"入场券"是同一张：一个活 `Section` 句柄**（见 §1.2）。
3. `Section : UnmanagedHandle`（`Section.cs:25`）⇒ `nmsCur`／`nmsSection` 是**托管表 `_unmanagedHandles` 的索引**（承 `t130` 的结论，**引用**我自己的 `P1-managed-handle-criteria.md`）⇒ **只许比较、绝不许 deref**。

### 1.2 **这两条回调的返回形状是"结构性已知"的 —— 其中一条根本产不出句柄**

```
Section.cs:171-177  internal void GetNextSection(out int fSuccess, out IntPtr nmsNext)
                    {
                        fSuccess = PTS.False;        // ← 恒 0
                        nmsNext  = IntPtr.Zero;      // ← 恒空
                    }
Section.cs:234-242  internal void GetMainTextSegment(out IntPtr nmSegment)
                    {
                        if (_mainTextSegment == null)
                            _mainTextSegment = new ContainerParagraph(Element, _structuralCache);   // ← 懒创建
                        nmSegment = _mainTextSegment.Handle;                                        // ← 真句柄
                    }
（常量现取：`Pts.cs:317 internal const int True = 1;`／`:318 internal const int False = 0;`）
```
⇒ **判定（写死）**：
- **`pfnGetNextSection`（+56）在今天的托管态下**永远**不会返回活句柄** —— 它的托管实现**无条件**答"没有下一节"（`fSuccess=0`、`nmsNext=0`）。这**不是缺陷**，是**单节文档的上游语义**。⇒ 它作为"能否拿到活句柄"的探针**没有信息量**；它只能当**"回调管道是否通"的对照腿**。
- **`pfnGetMainTextSegment`（+80）是唯一有信息量的那一条**：它**懒创建** `ContainerParagraph` 并返回**真句柄**（`.Handle`）。⇒ **本探针的真正未知量只有这一个。**

### 1.3 逐级前置（**具名前置链**；每级给"谁给／可核证据／代价结构"）

> **`PRECOND-0 · PRECOND-MEASURED-FSCBK-SLOT-OFFSETS` —— 已闭合（本件只引用，不复算）**
> 两条独立路径一致（**引自** `t133` 载体 `P1-fscbk-offsets-report.md`（`94ec8e09efd75e60…`，205 行）与 `t138` 载体 `P1-fscbk-slot-recon.md` 现盘代（`1d1e46bb31a97aa8…`，365 行）；**本席未独立复算它们的值**，读取时刻 `ts=2026-09-29T14:2x+0800`）：`fscbk=+40`、`pfnGetNextSection` 绝对 **+56**、`pfnGetMainTextSegment` 绝对 **+80**（＝帧 B，`FrameB = 40 + 8k`）。

> 🔴 **`PRECOND-FSCBK-SNAPSHOT-IN-DOC`（本件**新立**，第一条必修）**：**native 必须在 `CreateDocContext` 的调用期内，把 `FSCONTEXTINFO+40..+864` 的 103 个 8 B 字拷进我们自己的 doc 对象**。
> **为什么必须这么做（三条现取，不是推理）**：
> 1. **那个指针只在调用期内有效**：调用点是 `PTS.CreateDocContext(ref _contextPool[index].ContextInfo, out context)`（`PtsCache.Linux.cs:548`），而 `internal PTS.FSCONTEXTINFO ContextInfo;` 是 **`ContextDesc` 的字段**（`PtsCache.Linux.cs:965`；上游同形 `PtsCache.cs:788`）⇒ CLR 只保证**封送期间**该地址有效，**返回后 GC 可搬移** ⇒ **跨调用持有该指针就是 use-after-return**。
> 2. **今天的 doc 对象里没有这张表**：现取 `wpf_pts_doc`（`win32_pts.c:115-129`）只存 `info_addr`／`version`／`fsffi`／`c_installed_objects`／`p_installed_objects`／`p_fsclient`（+24）／`pts_penalty_module`（+32）—— **没有 `fscbk`**。
> 3. **今天的回读仪器不留存**：`wpf_pts_fscbk_probe`（`win32_pts.c:~485-520`）把 103 个字读进**栈上局部数组 `w[]`**、打印 `[FSCBK-WORD]`，**函数返回即丢弃**（它的用途是**测量/指纹**，不是"留一条可调用的通路"）。
> **谁给**：**native 侧自己**（纯 native、**零托管改动**、**只读拷贝**）；**代价结构**：一条 `memcpy`（824 B）＋ 一个结构字段；**风险**：无新增越界（窗口 `40..864` 对真结构 872 B 在界内，且夹具结构已按同窗加宽 —— 该"加宽"事实**引自** t133 载体）。
> **可核证据**：一条只读口报"本 doc 快照的字节数/非零槽数"，＋ 快照里 `+56`／`+80` 两槽**非零**（即"装好了"）。

> 🔴 **`PRECOND-LIVE-SECTION-HANDLE`（本件新立，第二条必修）**：**要给这两个回调传 `nmsCur`／`nmsSection`，必须拿到一个属于**同一个 PtsContext**、且**当时还活着**的 `Section` 句柄**（承 `t130`：`HandleToObject` 的三条断言 ⇒ 越界/空闲槽 ⇒ **`Invariant.FailFast` 不可捕获**；错类型 ⇒ 抛 ⇒ `fserr=-100002`）。
> **今天唯一在带的来源 ＝ 入站调用的实参**（现取三处，全部是 `_section.Handle`）：
```
PtsPage.cs:295  int fserr = PTS.FsCreatePageBottomless(PtsContext.Context, _section.Handle, out formattingResult, out ptsPage);
PtsPage.cs:347  int fserr = PTS.FsUpdateBottomlessPage(PtsContext.Context, _ptsPage, _section.Handle, out formattingResult);
PtsPage.cs:397  int fserr = PTS.FsCreatePageFinite(PtsContext.Context, brIn, _section.Handle, out formattingResult, out ptsPage, out brOut);
```
> **而 native 已经在存它**（现取 `win32_pts.c:181`：`const void *sect; /* 本次调用的 fsnmsect（原样存，不 deref） */`，在 `FsCreatePageBottomless` 里 `p->sect = fsnmsect;`）⇒ **载体已在**。
> ⚠️ **但"是否已发生"＝`NOINFO`（本件不预填，且**日志判不了**）**：`[FS_PAGE_GAP]` 是**失败才打**的（现取其函数体：成功路径**一行都不打**）⇒ 现取日志里 `sect=` 命中 **0**、`entry=FsCreatePageBottomless` 命中 **0** **不能**证"没被调"。⇒ 这一格**必须由探针自己的 L1 格回答**（既有只读口 `WpfLinuxWin32_PtsFsPageCreated()`／`…PageGap()`／`…PageLive()` 正是为此存在的，现取 `win32_pts.c:1115-1119` 已导出）。

> 🔴 **`PRECOND-CALL-WINDOW`（本件新立，第三条 —— 它把前两条"为什么要合起来"讲清楚）**：
> **今天没有任何一个入站调用同时持有"回调表"与"section 句柄"**：
> - `CreateDocContext`（`win32_pts.c:545+`）：**有** `FSCONTEXTINFO*`（且此刻回调已装好 —— 装配 `InitGenericInfo` 在 `PtsCache.Linux.cs:523`，**早于** `CreateDocContext` 的 `:548`），**但没有**任何 section 句柄（该 context 刚建）；
> - `FsCreatePageBottomless`／`FsCreatePageFinite`／`FsUpdateBottomlessPage`：**有** section 句柄（`fsnmsect`／`fsnmSectStart`），**但**只有 `pfscontext`（＝我们的 `wpf_pts_doc` 对象指针），**没有** `FSCONTEXTINFO*`。
> ⇒ **把两条凑齐的唯一办法就是 `PRECOND-FSCBK-SNAPSHOT-IN-DOC`**：快照存在 doc 对象里 ⇒ **在 `FsCreatePage*` 内即可取用回调指针**，探针的**调用点**由此确定。

### 1.4 **可行性判定（写死）：能做到，但必须先落 `PRECOND-FSCBK-SNAPSHOT-IN-DOC`（纯 native 一处）**
- **不是"结构性做不到"** ⇒ 本件**不**判"做不到"。
- **但今天直接发起回调是**做不到**的**（没有可持有的回调表）⇒ 若不做 §1.3 第一条前置就发起，只能靠"在 `CreateDocContext` 内当场发调"，而**那一刻没有 section 句柄** ⇒ 必然 `nms=0` ⇒ `HandleToObject(0)` ⇒ `:247` 断言 ⇒ **`FailFast`**。
- ⇒ **判据把这一条写成硬前置**：**在前置未满足时，探针必须诚实失败**（具名留痕、返非 0、**不得伪造** `nms`），**不许**为了"有读数"而在 `CreateDocContext` 里拿 `0`／栈地址硬试。

---

## §2 ② 成功语义：`fserr` ＋ **句柄身份** 的可证伪判据

### 2.1 `fserr` 检查（哪一格、合法值域）
- 取值来自**回调的返回 `int`**（两回调的签名第一维就是 `int`）。
- **合法值域（现取常量）**：`0` ＝ `PTS.fserrNone`（`Pts.cs:422`←`:428 tserrNone=0`，**唯一成功值**）；`-100002` ＝ `tserrCallbackException`（`:425`←`:511`，由两处 `catch` 支置位）；`-10000` ＝ `tserrNotImplemented`（`:507`）；其余 PTS 码亦**一律非成功**。
- 🔴 **`fserr != 0` ⇒ 判词 `CALLBACK-ERR(fserr=<v>)`，且**不许**记成功**（这是 P1-② 的牙）。

### 2.2 **两条回调各自的"成功形状"（写死；这是本件最要紧的一条设计决定）**

| 回调 | 绝对偏移 | 上游实现（现取） | **成功形状（绿）** | **判词名** | 反过读（必红或必解释） |
|---|---|---|---|---|---|
| **`pfnGetNextSection`** | **+56** | `PtsHost.cs:312-338` → `Section.cs:171-177`（**恒** `fSuccess=0`、`nmsNext=0`） | `fserr=0 ∧ fSuccess=0 ∧ nmsNext=0` | **`NEXTSECTION-ABSENT(by-design)`** | **`nmsNext≠0` 反而必须点名解释**（单节文档不该有"下一节"）；**`fSuccess=0` **不是**失败**；**`fserr=0` **不等于**"拿到活句柄"** |
| **`pfnGetMainTextSegment`** | **+80** | `PtsHost.cs:408-433` → `Section.cs:234-242`（懒创建后返 `.Handle`） | `fserr=0 ∧ nmSegment≠0` **且**该值满足 §2.3 的身份口径 | **`MAINTEXTSEG-LIVE-HANDLE(nmSegment=<v>)`** | `nmSegment=0` ⇒ **红或 `NOINFO`**（**除非**给出"该 Section 无主文本段"的具名依据）；`fserr≠0` ⇒ 见 §2.1 |

### 2.3 句柄**身份**口径（**承 `t130`，本件不重新定义**）
- **谓词**（四项）：`0 < v ∧ v < 表长 ∧ 槽 live ∧ Obj is <期望类型>`；**判定者是表主**。
- 🔴 **本探针**自己证不了**"在表内且 live"**：native 只有 `v` 一个数、看不到托管表 ⇒ **它最多能给三条弱证据**：① `v ≠ 0`；② **与调用前同一值**（连调幂等）；③ 若 `fserr=0`，**反推**托管侧那两句（`HandleToObject` ＋ `ValidateHandle`）**都没抛** ⇒ 这是"托管侧**接受**了这个句柄"的**间接**证据。
- ⇒ **判据写死**：**"该句柄在表内且 live 且类型对"这一句，必须由托管侧读数承担**（另一件或托管探针）；**本探针的绿只到"托管侧接受了它并且它非零"**。这条是 §6 的第一条 `NOINFO`。

### 2.4 `pfsclient` 的处理（现取结论）
- 两处实现**都不读**它（§1.1）⇒ 参数值不影响成败；**但判据要求把它如实记下**（从快照 `+24` 取，或直接记"传了 X"）—— 因为**将来别的回调可能读它**，且"不读"这个事实本身要留档。

### 2.5 **连调两次**（决定性）
- `pfnGetMainTextSegment`：**必须同值**（`_mainTextSegment != null` 后走同一支 ⇒ 幂等）。
- `pfnGetNextSection`：**必须同值**（恒 `0/0`）。
- **不同值 ⇒ 红并点名**（`reason=non-deterministic`）。

---

## §3 ③ 「假进度必红 P1–P8」

> **总则（写死）**：**反腿未红、或红而不点名 ⇒ 该条判不成立**；**反腿必须在副本文档上跑**；点名认 **`reason=` token 或字段名二者之一**。

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点 |
|---|---|---|---|---|
| **P1** | **伪造 `nms`／`nmp`**（拿 `0`／栈地址／猜的整数去调） | 真实现只传**捕获到的真句柄** | 副本上改用伪值 ⇒ 期望落 **`Invariant.FailFast`**（`Unrecoverable system error.`）或 `fserr=-100002`（错类型）⇒ **必红** | 出现 `failfast` 行（**主链不许**）或出现"伪句柄被当成功" ⇒ 红 |
| **P2** | **把 `fserr` 非零读成成功** | 真实现：`fserr≠0` ⇒ 判 `CALLBACK-ERR` | 副本上把判据改成"只看出参不看 fserr" ⇒ 必红 | `fserr<0 ∧ 判词=成功` ⇒ 红（`reason=fserr-ignored`） |
| **P3** | **把"回调被调用"读成"链路已通"** | 真实现：判词只到"该回调返回了 X" | 副本上把 `calls>0` 当"段落模型已成" ⇒ 必红 | 判词含"链路/模型/排版 已通/已成"且无独立证据 ⇒ 红（`reason=call-equals-chain`） |
| **P4** | **零句柄当活句柄** | `pfnGetMainTextSegment` 的绿要求 `nmSegment≠0` | 把 `nmSegment=0` 判绿 ⇒ 必红 | `nmSegment=0 ∧ 判词=绿` ⇒ 红（`reason=zero-handle-as-live`） |
| **P5** | **🔴 反向误读（本件特有，必红）**：把 `pfnGetNextSection` 的 `fSuccess=0/nmsNext=0` **当成探针失败** | 真实现：按 §2.2 判 `NEXTSECTION-ABSENT(by-design)` | 副本上把该形状判红 ⇒ 必红 | `fSuccess=0 ∧ nmsNext=0 ∧ 判词=失败/红` ⇒ 红（`reason=bydesign-read-as-failure`） |
| **P6** | **在主链上制造 `FailFast`** | 主链只跑**非破坏性**探针 ⇒ 主链 `failfast=0` | 把破坏性试调放进主链 ⇒ 必红 | 主链日志出现 `Invariant.FailFast`／`Unrecoverable system error.` ⇒ 红（`reason=main-chain-破坏`） |
| **P7** | **错偏移 `±8` 仍绿** | 正偏移 ⇒ 该槽可识别 | `±8` ⇒ 读到**别的槽**（`pfnGetSectionProperties`(+64)／`pfnGetFirstPara`(+136)）⇒ 必红/或明显不是同一函数 ⇒ 必红 | `±8` 与正偏移**同判词** ⇒ 红（`reason=offset-polarity-dead`） |
| **P8** | **恒绿自检** | 自检能证伪（P1／P2／P4／P5 的副本） | 把自检改成恒 `return 1` ⇒ **三档判词全同** ⇒ 必红 | 正极/负极/边界三档 `rc`／`diag` **完全相同** ⇒ 红（`reason=selfcheck-no-teeth`） |

---

## §4 ④ `FailFast` 反腿的**副本执行口径**（主链零破坏）

| 项 | 写死的口径 |
|---|---|
| **副本怎么造** | **只读拷贝**：把**现盘** `libwpfwin32.so`（＋同期 `PresentationFramework.dll`／`libwpfwin32` 五件套那一组）复制到一个**独立的应用副本目录**（**不得**覆盖权威件；路径与 manifest 按装置既有体例）。副本上**只**改"传伪 `nms`"这一处**行为**（最小改法：把捕获到的 `sect` 换成常量/栈地址）。 |
| **跑什么** | 那条**最小驱动探针**（正腿的正常路径）＋ 反腿（伪 `nms`）。**不跑整趟门禁**；是否跑页腿由派单决定（本件不预设）。 |
| **期望终止形态**（反腿） | 出现 `Invariant.FailFast` 的**终止文本**（`Unrecoverable system error.`）＋ 进程**非正常退出**（`app_rc` **`134`/`abort` 家族**）；`FAILLINE … failfast>0`。**这些格今天全部 `NOINFO`**（不预填）。 |
| **主链零破坏的判据** | ① 主链那一趟**不出现** `Invariant.FailFast`／`Unrecoverable system error.`；② 主链导出面 `nm=exports` **不变**；③ 主链两页症状面（`alive`／`app_rc`／`magenta`／`colors`）与**探针前同趟**取值**逐格相同**；④ 主链**不因探针**新增 `[FS_PAGE_GAP]` 失败原因；⑤ 探针**只读**既有只读口，**不改**任何产品件。 |
| ⚠️ **"非破坏性"≠"零副作用"** | 见 §6 第 4 条：`pfnGetMainTextSegment` 的托管实现会**懒创建** `ContainerParagraph` ⇒ **它会向托管表新增一个活条目**。判据要求把"调前/调后表内活条目数（若可得）"成对读出；**必须**在判词里如实写"本探针有托管侧副作用（懒创建）"。 |

---

## §5 ⑤ 成对读数清单（探针**前/后**）＋ 纪律 30 三格

### 5.1 成对读数（**每条给"取哪个字段"与"期望形状"**；今天的值**一律 `NOINFO`**，不预填）
| # | 面 | 取哪个字段（现取已存在的口／文件） | 探针前 vs 探针后 |
|---|---|---|---|
| R1 | **导出面** | `nm -D --defined-only …/libwpfwin32.so \| awk '{print $3}' \| grep -c .` ／ `wc -l …/exports.txt` | 两值相等；**探针只在副本上加"行为"不改导出** ⇒ 期望**不变**（今天 `594=594`） |
| R2 | `^Fs=` | 同 `nm` 的 `grep -c '^Fs'` | 期望**不变**（若探针需要新增**只读口** ⇒ 逐名点名） |
| R3 | **两页症状面** | `evidence/leg_{23,24}.env` 的 `LEG`／`NAMED`／`DEV`／`FAILLINE` | `alive=yes`／`app_rc ∉ {134,139}`／`magenta`／`colors` 前后一致；`failfast=0` |
| R4 | **`ENFE_TOTAL`** | `grep -c 'Unable to find an entry point named' <log>` | 期望 `0`（**且**必须同时给留痕面，见 C3 形制） |
| R5 | **`failfast`** | `grep -c 'Invariant.FailFast' <log>` ／ `grep -c 'Unrecoverable system error.' <log>` | 主链前后**都 0**；副本上**必须 >0**（§4） |
| R6 | **`unrec`** | `FAILLINE … unrec=` | 主链前后**都 0** |
| R7 | **`native_gap`** | `NAMED … native_gap=` | 如实给（**不得**为凑数制造非零；该值今天与本族**不是**同一量，见 §7 第 3 条） |
| R8 | **探针自身的三格** | 见 §5.2 | 见 §5.2 |

### 5.2 **纪律第 `30` 条**：三格（**缺任一格 ⇒ 该读数不许当证据**）
1. **进程新鲜度**：**fresh 进程**，**或**同进程＋**已发生的关键调用序**（逐条列：建过几个 `PtsContext`（`WpfLinuxWin32_PtsDocCreates()`）／入站 `FsCreatePageBottomless` 调用过几次（`…PtsFsPageCreated()+…PtsFsPageGap()`）／是否捕获到 section 句柄／是否已快照回调表／探针调用过几次）。
2. **关键前置量**（**该读数依赖的当时值**）：快照状态（字节数／非零槽数）、`+56`／`+80` 两槽**非零**、捕获到的 `sect` 值（**只作为值记，不 deref**）、`pfsclient` 值、表内活条目数（若可得）。
3. **判词**：`rc` ＋ `diag`（自检格号，**红时必须点名是哪一格**）。
> ⚠️ **"净腿不崩＝假绿"**：本会话已有三例硬实证（最近一例即本族上游：两页 `alive=yes ∧ magenta=0` 而帧逐字节相同）⇒ **本探针的证据是 §2 的形状判定**，**不是**"腿没崩"。

---

## §6 ⑥ 绿的正确读法（**写死**）＋ 本探针的 `NOINFO` 面

### 6.1 绿只准读成这一句（逐字）
> **「在今天的托管态下，`pfnGetMainTextSegment` 被 native 真调时返回了一个**非零、且托管侧接受了**的句柄；`pfnGetNextSection` 被真调时按上游语义如实回答『没有下一节』。」**

**不得**读成：❌"段落模型已成"／❌"排版打通"／❌"`pfsparaclient` 可用"／❌"`nms→nmp→pfsparaclient` 三级链已存在"／❌"该句柄在表内且类型正确"（后者**本探针证不了**，见 §2.3）。

### 6.2 本探针**回答不了**的问题（`NOINFO` 面，逐条给"谁才能答"）
| # | 问题 | 为什么答不了 | 谁才能答 |
|---|---|---|---|
| 1 | `nmSegment` 是否**在表内且 live、`Obj is ContainerParagraph`** | native 看不到托管表（§2.3） | 托管侧探针／`t130` 那类只读口 |
| 2 | `nms→nmp→pfsparaclient` 三级链是否成 | 本探针**不调** `pfnGetFirstPara`/`pfnGetNextPara`/`pfnCreateParaclient` | 下一跳（分步探针） |
| 3 | `pfsparaclient` 是否可用 | 那是 `FsQueryTrackParaList` 的**输出**语义（现取它仍返 `-10000`） | 该入口的后续步 |
| 4 | 两页是否**真排版** | 与本探针无关（`N1`/`N4` 的判据面） | 页面症状面 ＋ `N4` 正身份（**今天 `NOINFO`**） |
| 5 | 探针是否会**新增**托管表条目（懒创建） | 只能由托管侧计数观察 | 托管侧读数 |
| 6 | "native→managed 方向的调用"在**今天的进程里**是否还有别的先例 | 现取：在 `src/WpfGfx.Linux.Native/src/*.{c,h}` 里 `pfn*` 字样**只出现在三处** —— 6 条 `_Static_assert` 偏移断言（`win32_pts.c:452-458`）、只读探针的目标槽名字表（`:514+`）、以及 `win32_core.c:387` 的 `c->wndproc = wc->lpfnWndProc`（窗口过程指针，与 PTS 回调无关）⇒ **本文件内没有任何 `FSCBK` 回调的调用点**；**但**这只覆盖 native 源这一面（别的进程/native 库、以及 `pfnAssertFailed` 等槽**未查**）⇒ 本格记 `NOINFO(面不完整)` | 一次全槽 ＋ 全 native 库的调用点普查（另派单） |
| 7 | `FsCreatePageBottomless`／`FsCreatePageFinite` **今天到底被调过没有** | `[FS_PAGE_GAP]` 失败才打；成功路径不打日志 | **探针的 L1 格**（读 `WpfLinuxWin32_PtsFsPageCreated()` 等只读口） |

---

## §7 ⑦ 两极化设计（a／b／c／d）

| 腿 | 构造 | 期望 | **点名要求** |
|---|---|---|---|
| **(a) 正极** | 前置满足后，在 `FsCreatePage*` 的调用窗内、用**快照里的** `+56`／`+80` 真调两条回调，入参 ＝ 捕获到的真 `sect` | 按 §2.2 判：`+56` ⇒ `NEXTSECTION-ABSENT(by-design)`；`+80` ⇒ `MAINTextSEG-LIVE-HANDLE(非零)`；`fserr=0` | 若 `fserr≠0` ⇒ 红并点名 `CALLBACK-ERR(fserr=<v>)` |
| **(b) 反极（错偏移 `±8`）** | 用快照的 `+48`／`+64`／`+88` 发调 | 读到**别的槽**（`pfnGetPageDimensions`(+48)／`pfnGetSectionProperties`(+64)／`pfnGetSectionColumnInfo`(+88)…）⇒ **判词必须不同**，且**不崩**（该槽若是合法回调，被以错误参数调用可能返回 `fserr=-100002` 或产生错误出参） | **必须点名"偏移极性有分辨力"**；若与正极**同判词** ⇒ P7 红 |
| **(c) 前置未满足** | **不做** `PRECOND-FSCBK-SNAPSHOT-IN-DOC`（或捕获不到 `sect`）就发调／或干脆**拒绝发调** | **必须诚实失败**：① 若拒绝发调 ⇒ 判词 `PRECOND-UNMET(<具名>)` ＋ 一行具名留痕；② 若强行传 `0` ⇒ 期望 **`FailFast`**（**那就证明"不许伪造"这条纪律是对的**） | **两种都必须具名**；**不许**出现"没拿到句柄但仍报绿"⇒ 红（`reason=precond-unmet-but-green`） |
| **(d) 副本上的 `FailFast`** | §4 的副本 ＋ 伪 `nms` | 期望 `Invariant.FailFast`（`Unrecoverable system error.`）＋ `app_rc` 落 `134`/`abort`；**主链零破坏**（§4 五条） | 主链若出现 `failfast` ⇒ 红并点名 `reason=main-chain-dirty` |

---

## §8 ⑧ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-drive-probe-criteria.md`（新建；UTF-8；模式 **644**；**首记号 `# P1-W60 …`（不是 `# ⏪ `）**；末行自带可复算自报口径）。
- **末行自证口径当场复算**：口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`；**末行所载值 == 当场重算值 ⇒ MATCH**（值见末行）。
- **本件命令的末次执行时刻**：`ts=2026-09-29T14:25:17,224360660+08:00`（`date -Ins` 现取；与下方 `git status` 同趟）。
- **只读**：本件全部命令为 `grep`／`sed`／`awk`／`cat`／`sha256sum`／`stat`／`wc`／`sort`／`nm`／`git log`／`git status`。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- **未改任何其它件（含在飞件）**：对 `src/WpfGfx.Linux.Native/src/win32_pts.c`（`26af5a26b984b99e`，另一车道在飞）与 `build/PresentationFramework.Linux/PtsCache.Linux.cs` 均**只读**；`git status --porcelain` 现取 —— 工作树里的 `M`／`??` **全部属他人**（`t133`／`t138` 落地件、证据面、`arm_A` 组），**本件是本次唯一新增件**。
- 🔴 **引用纪律（逐处遵守）**：`t133` 载体（`94ec8e09efd75e60…`）与 `t138` 载体（现盘代 `1d1e46bb31a97aa8…`，**上一代 `614d60178dc44692…`**）的值**一律标注「引自…，本席未独立复算」**＋读取时刻；本件**没有**任何一句把自己的推算写成别人的实测。

---

### 结语（自包含）

- **① 可行性判定（本件第一产出）**：**能做到，但必须先落一条纯 native 的前置**。逐跳原文见 §1.1／§1.3。**三条具名前置**：
  **`PRECOND-0 · MEASURED-FSCBK-SLOT-OFFSETS`**（**已闭合**，本件只引用不复算：`+56`／`+80` 绝对偏移）；
  🔴 **`PRECOND-FSCBK-SNAPSHOT-IN-DOC`**（**本件新立**：必须在 `CreateDocContext` **调用期内**把 `+40..+864` 的 103 字**拷进自己的 doc 对象** —— 三条现取理由：入参是**托管对象字段**地址（`PtsCache.Linux.cs:548`／`:965`）⇒ **只在调用期内有效**；现取 `wpf_pts_doc`（`win32_pts.c:115-129`）**没有**这张表；`wpf_pts_fscbk_probe` 只读进**栈上局部**、**不留存**）；
  🔴 **`PRECOND-LIVE-SECTION-HANDLE`**（**本件新立**：句柄只能从入站 `_section.Handle` 捕获 —— `PtsPage.cs:295`／`:347`／`:397`；native **已在存**它（`win32_pts.c:181`）⇒ 载体已在；**但"是否已发生"＝`NOINFO`**，因为 `[FS_PAGE_GAP]` 失败才打、成功路径不打日志）；
  🔴 **`PRECOND-CALL-WINDOW`**（**本件新立**：今天**没有**任何入站调用同时持有"回调表"与"section 句柄" —— `CreateDocContext` 有表无句柄、`FsCreatePage*` 有句柄无表 ⇒ **这正是第一条前置存在的理由**）。
- **② 成功语义**：`fserr`（`0`＝成功／`-100002`＝回调异常／`-10000`＝未实现／其它一律非成功）＋ **两条回调各自的成功形状** —— 🔴 **`pfnGetNextSection(+56)` 的成功形状是 `fserr=0 ∧ fSuccess=0 ∧ nmsNext=0`（上游**恒**如此：`Section.cs:171-177`）⇒ 它**永远产不出活句柄**，只能当"管道通不通"的对照腿；**唯一有信息量的是 `pfnGetMainTextSegment(+80)`**（懒创建 ⇒ 真句柄）；**反向误读（把 by-design 读成失败）立为 P5**。句柄身份的四项谓词**由表主判**，本探针只到"非零 ＋ 托管侧接受 ＋ 连调幂等"。
- **③ 假进度必红 P1–P8**（含**伪造 `nms`**、`fserr` 误读、**"被调用"当"链路已通"**、**零句柄当活句柄**、**反向误读**、**主链 `FailFast`**、**偏移极性死掉**、**恒绿自检**）；**④ `FailFast` 副本口径**（怎么造／跑什么／终止形态／主链零破坏五条 ＋ **"非破坏性≠零副作用"**）；**⑤ 成对读数 R1–R8 ＋ 纪律 30 三格**；**⑥ 绿的正确读法 ＋ 7 条 `NOINFO` 面**；**⑦ 两极化 (a)(b)(c)(d)**。
- **⑧ 载体**：路径／行数／全文 sha16／自报口径值 ⇒ 见交件消息；**末行自证当场复算 MATCH**。
`P1-DRIVE-PROBE-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 8a1a5d37c745103f（口径＝末行之前的全文；末行＝本行）`

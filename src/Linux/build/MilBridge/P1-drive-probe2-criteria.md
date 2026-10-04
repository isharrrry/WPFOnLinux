# P1-W69 · 驱动链**第二跳**预登记判据 —— 拿到 `nms` 之后，调哪一槽能拿到 `nmp`

> **本件是判据件（先写），不是实现件**：**不实现、不构建、不跑腿、不占显示位、不跑整趟门禁、不 `git add/commit/push`**；**不碰任何源件与 `.cs`**、**不碰** `build/MilBridge/tools/**`。
> **唯一写入** ＝ 本件 `build/MilBridge/P1-drive-probe2-criteria.md`。
> **一切读数由我现取**（命令与输出原样贴出）；**引他人载体逐处带代际（`sha16`）＋取值时刻**并标注「引自 X，本席未独立复算」；**不预填任何运行期读数**。
> **读取时刻**：`ts=2026-09-29T16:50:45.710+0800`（起点）→ `ts=2026-09-29T16:51:51.055+0800`（末取）。

---

## §0 现取快照

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`16ba3a2`**（`feat(#81): t148 探针运行期闸（缺省关、零调用）+ ENTER 入口留痕（归因升强）+ T3 按类点名；五样本表推翻「探针改帧」的因果（t146 离群）`） | `git log --oneline -3` |
| 上游源（本件唯一的声明依据） | `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/` 下的 `Pts.cs`／`PtsHost.cs`／`ContainerParagraph.cs`／`Segment.cs`／`Section.cs`／`FlowDocumentPage.cs`／`StructuralCache.cs` | 只读 |
| 在册载体（**本席现取**，与任务书所给值**逐位相符**） | `P1-drive-probe-report.md` ＝ **`010dd16aac3b74561a7e…`／175 行／`mtime 16:41:19.674915253`**｜`P1-drive-probe-gate-report.md` ＝ **`da0436c69988946dea6d…`／117 行／`mtime 16:49:37.913856161`**｜`P1-fscbk-slot-recon.md` ＝ **`1d1e46bb31a97aa8b997…`／365 行／`mtime 14:22:23.457429473`** | `sha256sum`／`wc -l`／`stat` |

---

## §1 ① 候选排序与理由（**签名层面就已经分出高下**）

### 1.1 三条候选的委托声明（现取原文，`Pts.cs`）

```
2102:  internal delegate int GetFirstPara(
2103:      IntPtr pfsclient,                   // IN:  client opaque data
2104:      IntPtr nms,                         // IN:  name of segment
2105:      out int fSuccessful,                // OUT: does segment contain any paragraph?
2106:      out IntPtr nmp);                    // OUT: name of the first paragraph in segment
2107:  internal delegate int GetNextPara(
2108:      IntPtr pfsclient,                   // IN:  client opaque data
2109:      IntPtr nms,                         // IN:  name of segment
2110:      IntPtr nmpCur,                      // IN:  name of current para      ← ★ 需要 nmp
2111:      out int fFound,                     // OUT: is there next paragraph?
2112:      out IntPtr nmpNext);                // OUT: name of the next paragraph in section
2124:  internal delegate int GetParaProperties(
2125:      IntPtr pfsclient,                   // IN:  client opaque data
2126:      IntPtr nmp,                         // IN:  name of paragraph          ← ★ 吃 nmp
2127:      ref FSPAP fspap);                   // OUT: paragraph properties       ← ★ 不吐句柄
```
⇒ 🔴 **签名层面的结论（先于任何实现细节）**：**三条里只有 `GetFirstPara` 是「吃 `nms`、吐 `nmp`」**。
`GetNextPara` **入参里有 `nmpCur`**（要一个已存在的段落句柄）；`GetParaProperties` **入参是 `nmp`、出参是属性结构**（既不吃 `nms`，也不吐句柄）⇒ **它俩在签名上就不可能回答"拿到 `nms` 后怎么拿到 `nmp`"**。

### 1.2 **候选 #1 ＝ `pfnGetFirstPara`（绝对偏移 `+136`）—— 唯一可行，且今天只靠 `nms` 可到**

**托管实现（原文，`PtsHost.cs:586-612`）**
```
586:  internal int GetFirstPara(
587:      IntPtr pfsclient,                   // IN:  client opaque data
588:      IntPtr nms,                         // IN:  name of segment
589:      out int fSuccessful,                // OUT: does segment contain any paragraph?
590:      out IntPtr nmp)                     // OUT: name of the first paragraph in segment
591:  {
592:      int fserr = PTS.fserrNone;
593:      try
594:      {
595:          ISegment segment = PtsContext.HandleToObject(nms) as ISegment;      // ★ 认 ISegment（不是 Section！）
596:          PTS.ValidateHandle((object)segment);
597:          segment.GetFirstPara(out fSuccessful, out nmp);
598:      }
599:      catch (Exception e)
600:      {   fSuccessful = 0; nmp = IntPtr.Zero; PtsContext.CallbackException = e;
601:          fserr = PTS.fserrCallbackException; }
••      …
611:      return fserr;
612:  }
```
**为什么"只靠 `nms` 可到"（逐跳现取，不是推断）**
```
Segment.cs:14      internal interface ISegment { … GetFirstPara(out int, out IntPtr); … }
ContainerParagraph.cs:19   internal class ContainerParagraph : BaseParagraph, ISegment     ← ★
Section.cs:234-242         GetMainTextSegment:  _mainTextSegment = new ContainerParagraph(Element, _structuralCache);
                                             nmSegment = _mainTextSegment.Handle;        ← 第一跳 +80 产出的就是它
```
⇒ **第一跳 `+80` 交出来的 `nms`（在册读数 `0x2`）** 是一个 **`ContainerParagraph`** 的句柄，而 `ContainerParagraph` **显式实现 `ISegment`** ⇒ `:595` 的 `as ISegment` **能命中**，`:596` 的 `ValidateHandle` **不会抛** ⇒ **第二跳只靠 `nms` 就能到**。

**`+136` 内部到底做什么（原文，`ContainerParagraph.cs:72-159`，节选关键行）**
```
 72:  void ISegment.GetFirstPara(out int fSuccessful, out IntPtr firstParaName)
 76:      if (_ur != null) { …同步点处理… }                      ← 首次调用 _ur 为 null ⇒ 跳过
100:      if (_firstChild != null) { …更新模式/失效处理… }        ← 首次调用 _firstChild 为 null ⇒ 跳过
138:      if (_firstChild == null)
139:      {
141:          ITextPointer textPointer = TextContainerHelper.GetContentStart(StructuralCache.TextContainer, Element);
142:          _firstChild = GetParagraph(textPointer, false);      ← ★ 懒创建第一个段落
149:      }
151:      if (StructuralCache.CurrentFormatContext.IncrementalUpdate)   ← ★★ 读 CurrentFormatContext（可为 null！见 §8.2）
153:          _firstParaValidInUpdateMode = true;
157:      _lastFetchedChild  = _firstChild;
158:      fSuccessful        = PTS.FromBoolean(_firstChild != null);    ← ★ 出参①：有段落实 ⇒ 1
159:      firstParaName      = (_firstChild != null) ? _firstChild.Handle : IntPtr.Zero;   ← ★ 出参②
```
⇒ **成功形状**：`fserr=0 ∧ fSuccessful=1 ∧ nmp≠0`（`PTS.True=1`／`PTS.False=0`，`Pts.cs:317/:318` 现取）；
⇒ **"无段落"也是合法回答**：`fSuccessful=0 ∧ nmp=0`（**不得读成失败** —— 与第一跳 `pfnGetNextSection` 的 by-design 形态同族，见 §2.2）。

### 1.3 候选 #2 ＝ `pfnGetNextPara`（`+144`）—— **排除**（它是"段落游走"的**后续**跳，不是拿到第一个 `nmp` 的路）

```
613:  internal int GetNextPara(IntPtr pfsclient, IntPtr nms, IntPtr nmpCur, out int fFound, out IntPtr nmpNext)
620:      try {
623:          ISegment segment = PtsContext.HandleToObject(nms) as ISegment;            ← 要好书①：nms
624:          PTS.ValidateHandle((object)segment);
625:          BaseParagraph currentParagraph = PtsContext.HandleToObject(nmpCur) as BaseParagraph;  ← 要好书②：nmpCur
626:          PTS.ValidateHandle(currentParagraph);
627:          segment.GetNextPara(currentParagraph, out fFound, out nmpNext);
628:      }
```
⇒ **它需要两个已在册对象**，其中 `nmpCur` 恰恰是**本件要产出的那个东西** ⇒ **循环依赖** ⇒ **作为"第二跳"排除**；它属于**第三跳及以后**（拿到 `nmp` 之后**走遍**段落表）。
⚠️ **但它有诊断价值，写进判据**：它的两个 `HandleToObject`＋`ValidateHandle` 是**检验 `nmp` 真伪的现成工具** —— 见 §2.3。

### 1.4 候选 #3 ＝ `pfnGetParaProperties`（`+168`）—— **排除**（吃 `nmp`、吐属性）

```
700:  internal int GetParaProperties(IntPtr pfsclient, IntPtr nmp, ref PTS.FSPAP fspap)
708:      BaseParagraph para = PtsContext.HandleToObject(nmp) as BaseParagraph;
709:      PTS.ValidateHandle(para);
710:      para.GetParaProperties(ref fspap);
FSPAP（Pts.cs:639-645）＝ struct { int idobj; int fKeepWithNext; int fBreakPageBefore; int fBreakColumnBefore; }  → 4×int = 16 B
```
⇒ **不产出任何句柄** ⇒ 排除；**但**它同时是 §2.3「下游接受性」的**首选判别器**（它是**扁平 4×int 结构**，比 `FSPAP` 更复杂的结构风险低，且**它成功 ⇔ `nmp` 被当作 `BaseParagraph` 接受**）。

### 1.5 可达性总表 ＋ **调用窗（本件第二重要的发现）**

| 候选 | 偏移 | 只靠 `nms` 可达？ | 产出 `nmp`？ | 判定 |
|---|---|---|---|---|
| **`pfnGetFirstPara`** | **`+136`** | ✅ **可以**（`nms` = `ContainerParagraph` : `ISegment`，现取类声明） | ✅ `out IntPtr nmp` ＋ `out int fSuccessful` | **候选 #1（唯一）** |
| `pfnGetNextPara` | `+144` | ❌ 还需 `nmpCur` | ✅ 但要先有 `nmp` | **排除**（第三跳起） |
| `pfnGetParaProperties` | `+168` | ❌ 入参就是 `nmp` | ❌ 吐 `FSPAP` | **排除**（改用为判别器） |

🔴 **调用窗：`pfnGetFirstPara` 必须在 `SetDocumentFormatContext` 的 `using` 块内被调**（现取原文）：
```
StructuralCache.cs: 75  internal IDisposable SetDocumentFormatContext(FlowDocumentPage currentPage) { … return (new DocumentFormatContext(this, currentPage) as IDisposable); }
StructuralCache.cs:676-679  DocumentFormatContext(…) { _owner._documentFormatContext = this; }     ← 进窗
StructuralCache.cs:684-686  void IDisposable.Dispose() { _owner._documentFormatContext = null; … } ← 出窗
StructuralCache.cs:290  internal DocumentFormatContext CurrentFormatContext { get { return _documentFormatContext; } }   ← 窗内非 null，窗外 **null**
FlowDocumentPage.cs:136  using(_structuralCache.SetDocumentFormatContext(this)) { … _ptsPage.CreateBottomlessPage(); … }   ← ★ 我们的入站 hook 在这里面
FlowDocumentPage.cs:199  using(_structuralCache.SetDocumentFormatContext(this)) { … _ptsPage.CreateFinitePage(breakRecord); … }
PtsPage.cs:295  PTS.FsCreatePageBottomless(PtsContext.Context, _section.Handle, …)   ← 探针现有 hook ⇒ **已在窗内**
```
⇒ **今天已有的 hook（`FsCreatePageBottomless`／`FsCreatePageFinite` 内）就已经在窗内** ⇒ **第二跳不需要新的入站管道**（只需 `t140` 那条 `PRECOND-FSCBK-SNAPSHOT-IN-DOC` 把回调表带进那个窗口）。

---

## §2 ② 成功语义（可证伪；给**最小证据串**）

### 2.1 `fserr` 检查（值域现取）
`0` ＝ `PTS.fserrNone`（唯一成功）；`-100002` ＝ `tserrCallbackException`（`Pts.cs:511`，由 `:599`／`:605` 两个 `catch` 支置位）；`-10000` ＝ `tserrNotImplemented`（`:507`）；**其它一律非成功**。

### 2.2 **`pfnGetFirstPara` 的"成功形状"（写死；两种都合法）**
| 形状 | 判词 | 说明 |
|---|---|---|
| `fserr=0 ∧ fSuccessful=1 ∧ nmp≠0` | **`FIRSTPARA-HANDLE(nmp=<v>)`** | **本件要的那个**（`_firstChild` 真被建出／已缓存） |
| `fserr=0 ∧ fSuccessful=0 ∧ nmp=0` | **`FIRSTPARA-ABSENT(by-design)`** | **合法回答**：该 segment 此刻**没有段落**（`_firstChild` 为 null）⇒ **不得读成失败**（与 `+56` by-design 同族） |
| `fserr=-100002` | **`CALLBACK-ERR(-100002)`** | 句柄/类型/前置出问题 —— ⚠️ **成因有两种，见 §8.2（本件的关键陷阱）** |
| `fserr=-10000` | **`NOT-IMPLEMENTED`** | 非成功 |

### 2.3 **"能被下游接受"（本件要求的第 4 条，且必须给最小证据串）**
> **口径**：拿到 `nmp` 后，**再喂给一个"只接受 `BaseParagraph`"的槽**，若**不得 `-100002`** ⇒ 说明托管侧 `HandleToObject(nmp) as BaseParagraph` ＋ `ValidateHandle` **都通过了**。
> **首选判别器**：`pfnGetParaProperties`（`+168`，`FSPAP` 是**扁平 4×int**，结构风险最低）——现取其实现（`:708-710`）**正是** `as BaseParagraph` ＋ `ValidateHandle`。
> **最小证据串（逐格可机读，四条同时成立才算"拿到 `nmp`"）**：
```
① rc136a=0                     （+136 首调 fserr=0）
② fSucc1=1  nmp1=<非零>        （首调出参形状）
③ rc136b=0  nmp2=nmp1  idem136=1（连调两次同值 ⇒ 幂等：_firstChild 已缓存）
④ rc168=<非 -100002>           （把 nmp1 喂给 +168 ⇒ 下游接受；-100002 ⇒ 拒收 ⇒ 判红）
```
⚠️ **③ 的幂等口径要写清楚**：`+136` **首次调用会创建**（`:142 _firstChild = GetParagraph(...)`），第二次走 `:100-133` 的缓存支 ⇒ **两次必须同值**；**不同值 ⇒ 红并点名**（`reason=non-deterministic`）。

### 2.4 **"某槽被调用"与"`nms` 被接受"要分开证**
- "被调用"＝`[DRIVE-PROBE-ENTER]` 在日志里（现取该行 `where=…` 由 `t148` 引入，**引自 `P1-drive-probe-gate-report.md`（`da0436c69988946dea6d…`／117 行／读时 `16:51:51`），本席未独立复算**）。
- "被接受"＝`fserr=0`（托管侧两条闸都没抛）。
⇒ **两者都不得单独读成"拿到 `nmp`"**（见 P3）。

---

## §3 ③ **强制**复用 `t148` 的 **T3 安全试错模式**

### 3.1 为什么必须走 T3（现取三类对照，**引自 `t148` 载体，本席未独立复算**）
| 类 | 伪值形态 | 命中哪条断言 | 终态 |
|---|---|---|---|
| **T1** | 越界值（如 `0x1000`） | `HandleToObject` 的 `>0 && <Length` ⇒ `:247` | **`FailFast` 不可捕获** |
| **T2** | **空闲槽**（如某时刻的 `0x2`） | `:248 IsHandle()` ⇒ "Handle has been already released." | **`FailFast` 不可捕获** |
| **T3** | **live 但类型不对**（用**真** `sect` 调 `+80` 造出的 `ContainerParagraph` 句柄） | `as X` ⇒ null ⇒ `ValidateHandle` 抛 | **`fserr=-100002`，可捕获**，进程活（`unrec=0 failfast=0`） |

### 3.2 **最小可复用配方（逐步；本件写死）**
```
步 0  开闸：env `WPF_PTS_DRIVE_PROBE=1`（非空且 ≠ "0"；缺省关 ⇒ 闸关走 `[DRIVE-PROBE-SKIP] reason=gate-off`，一次都不调）
步 1  用**真** `sect`（来自入站实参 `fsnmsect`）调 `+80`（`pfnGetMainTextSegment`）⇒ 拿到 **live 的 `ContainerParagraph` 句柄**
      （在册读数：`rc80=0`、`nmSeg=0x2`；**引自 t148 载体，本席未独立复算**）
步 2  把它当 **live 的错类型句柄**（对任何"只认 `Section`/`ISegment`/`BaseParagraph` 的槽"而言它类型不对）
步 3  喂给**被测槽**：`rc = slot(..., <该句柄>, ...)`
步 4  期望：**`rc=-100002`（可捕获）** ∧ 进程活 ∧ `unrec=0` ∧ `failfast=0`
步 5  若得到 `0` ⇒ **该槽接受了这个类型** ⇒ 说明它不是"只认 X"的槽（**这条信息本身要如实记**）
```
🔴 **伪值域纪律（写死）**：**凡"试错"一律禁止伪值**（T1/T2 ⇒ `FailFast`）；**且伪值必须避开真值域** —— 现取真 `nms` ＝ **`0x1`**、真 `nmSegment` ＝ **`0x2`**（**引自 t148 载体，本席未独立复算**）⇒ 用 `0x1`/`0x2` 当"伪值"会**撞上真对象**，反腿**空转**（变成"正路"而不是反腿）。**判据要求：反腿必须显式声明所用值、并证明它 ∉ 真值域（逐趟给出真值域的现取读数）。**

### 3.3 本件里 T3 的**两个具体用途**
1. **反腿**：把 `+80` 造出的 live 错类型句柄喂给 **`pfnGetFirstPara`（`+136`）** ⇒ 期望 `-100002`（`as ISegment` 落空）⇒ **证明 `+136` 的成功不是"任何句柄都行"**。
2. **候选排除的实证**：把**真 `nms`**（`0x1`）喂给 **`pfnGetParaProperties`（`+168`）** ⇒ 期望 `-100002`（它 `as BaseParagraph`，而 `nms` 是 `ContainerParagraph`；`ContainerParagraph : BaseParagraph` ⇒ **⚠️ 其实它能命中！**）——
   ⇒ **本件据此更正一条容易犯的错**：`ContainerParagraph` **继承 `BaseParagraph`**（`ContainerParagraph.cs:19`）⇒ **`+168` 会接受 `nms`**！⇒ **`+168` 作为"`nmp` 接受性判别器"是有条件的**：它能区分"是 `BaseParagraph`"，但**不能区分"是段落本身"还是"是容器段落"** ⇒ **判据要求：`+168` 的绿必须与 `+136` 的 `nmp` 值成对给出，并声明"它证的是 `BaseParagraph` 族、不证是 first para"**。

---

## §4 ④ 「假进度必红 P1–P8」

> **总则（写死）**：**反腿未红、或红而不点名 ⇒ 该条判不成立**；**反腿必须在副本文档上跑**；点名认 **`reason=` token 或字段名二者之一**。

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点 |
|---|---|---|---|---|
| **P1** | 把 `-100002`／`-10000` 读成成功 | 真实现：`fserr=0` 才叫成功 | 副本上把判据改成"只看 `nmp≠0`" ⇒ 必红 | `fserr<0 ∧ 判词=成功` ⇒ 红（`reason=fserr-ignored`） |
| **P2** | **零句柄当活句柄** | 绿要求 `nmp≠0` | 把 `fSuccessful=0 ∧ nmp=0` 判绿 ⇒ 必红 | `nmp=0 ∧ 判词=FIRSTPARA-HANDLE` ⇒ 红（`reason=zero-handle-as-live`） |
| **P3** | **"某槽被调用"读成"链已通"** | 判词只到"该槽返回了 X" | 只用 `[DRIVE-PROBE-ENTER]` 在场就判绿 ⇒ 必红 | 判词含"链/三级/模型 已通/已成"而**无** §2.3 的四格 ⇒ 红（`reason=call-equals-chain`） |
| **P4** | **用伪值代替 T3 模式** | 反腿走 T3（live 错类型）＋**声明值 ∉ 真值域** | 用伪值（`0x1000`／`0x1`／`0x2`）当反腿 ⇒ **必红并点名是哪一类**：`0x1000` ⇒ 期望 `FailFast`（T1）；`0x1`/`0x2` ⇒ **撞真值域 ⇒ 反腿空转 ⇒ 判"反腿无效"** | 反腿未给出"值 ∉ 真值域"的证明 ⇒ 红（`reason=fake-in-real-domain`）；反腿**不红** ⇒ 红 |
| **P5** | **在主链制造 `FailFast`** | 主链只跑**非破坏性**探针 | 把破坏性试错放进主链 ⇒ 必红 | 主链日志出现 `Invariant.FailFast`／`Unrecoverable system error.` ⇒ 红（`reason=main-chain-dirty`） |
| **P6** | **单样本当机制**（承裁定三十八） | 每候选 **≥2 趟独立样本**同名同判词 | 用 1 趟读数写"机制"⇒ 必红 | 样本数 < 2 而判词用"机制/恒/总"类措辞 ⇒ 红（`reason=single-sample-as-mechanism`） |
| **P7** | **反过读 by-design**（本族特有） | `fSuccessful=0 ∧ nmp=0 ∧ fserr=0` ⇒ 判 `FIRSTPARA-ABSENT(by-design)` | 把该形状当失败 ⇒ 必红 | `fserr=0 ∧ fSuccessful=0 ∧ 判词=失败/红` ⇒ 红（`reason=bydesign-read-as-failure`） |
| **P8** | **恒绿自检** | 自检能证伪（P1/P2/P4/P7 的副本） | 自检改成恒 `return 1` ⇒ 三档判词全同 ⇒ 必红 | 正极/负极/边界三档 `rc`／`diag` **完全相同** ⇒ 红（`reason=selfcheck-no-teeth`） |

---

## §5 ⑤ 成对读数清单 ＋ 纪律 30 三格 ＋ **闸状态必须随读数给**

### 5.1 成对读数（**每条给字段与期望形状；今天的值一律 `NOINFO`，不预填**）
| # | 面 | 取哪个字段 | 期望 |
|---|---|---|---|
| R1 | **探针闸状态** | `[DRIVE-PROBE-SKIP] reason=gate-off` 行数／`[DRIVE-PROBE-ENTER]` 行数／`…PtsDriveProbeGate()`（若在册） | 闸关 ⇒ 两行分别为 `≥1`／`0`（**零调用**）；闸开 ⇒ `ENTER ≥1`。**裁定三十六 (c)：跨闸不可比 ⇒ 每个读数必须带闸状态** |
| R2 | 探针读数 | `[DRIVE-PROBE]` 行的 `rc136a/fSucc1/nmp1/rc136b/nmp2/idem136/rc168/rc56…` | 按 §2.2／§2.3 形状判；**首次落地时该行字段名由实现件写死** |
| R3 | T3 留痕 | `[DRIVE-PROBE-T3] stage=create-live-wrong-type rc80=… seg=…` | 在场（T3 反腿那趟） |
| R4 | 导出面 | `nm … \| grep -c .` ＝ `wc -l exports.txt`；`^Fs=` | 相等；**本步不靠加导出收尾**（若新增只读口 ⇒ 逐名点名） |
| R5 | 两页症状面 | `leg_{23,24}.env` 的 `LEG`／`NAMED`／`DEV`／`FAILLINE`／`FRAME` | `alive=yes`／`app_rc ∉ {134,139}`／`failfast=0`／`unrec=0` |
| R6 | `ENFE_TOTAL` | `grep -c 'Unable to find an entry point named' <log>` | 如实给（**必须同时给留痕面**，缺一不得判绿） |
| R7 | `native_gap` | `NAMED … native_gap=` | 如实给；**不得为凑数制造非零** |
| R8 | 同趟性 | 两腿 `DEV … shim=`／`pf=`；`session.txt` 的 `shim_sha16`／`pf_sha16`；现盘件 | 四值同；**不许拿 `legs=2/2` 当同趟证据** |
| R9 | 帧面（**只作辅证**） | `FRAME` 行的 `fr_sha`／`fr_lsha`／`fr_ae_boot` | 如实给；**`N1`／`N3`／`N4` 的口径不变**（本件不重定义） |

### 5.2 纪律第 `30` 条：三格（缺一 ⇒ 该读数不许当证据）
1. **进程新鲜度**：**fresh 进程**，或同进程＋**已发生的关键调用序**（逐条列：`PtsContext` 建过几个／入站 `FsCreatePageBottomless` 几次／`+80` 调过几次／`+136` 调过几次／是否走过 T3）。
2. **关键前置量**：`nms`（现取真值域 `0x1`）、`nmSegment`（`0x2`）、快照是否就位（承 `t140` 的 `PRECOND-FSCBK-SNAPSHOT-IN-DOC`）、**当前是否在 `SetDocumentFormatContext` 窗内**、表内活条目数（若可得）。
3. **判词**：`rc` ＋ `diag`（自检格号，红时点名）。
> ⚠️ **"净腿不崩＝假绿"**本会话已有三例硬实证 ⇒ 本件的证据是 **§2 的形状判定 ＋ §2.3 的下游接受**，**不是**"腿没崩"。

---

## §6 ⑥ **≥2 独立样本**（承裁定三十八，写死）

- **每候选至少两趟独立样本**（独立进程／独立运行，**同闸状态**）；**单样本只能记「观测」，不得记「机制」**（据：`t146` 单趟离群读数曾被当作机制，`t148` 五样本表把它推翻 —— **引自 `t148` 载体（`da0436c69988946dea6d…`／117 行／读时 `16:51:51`），本席未独立复算**）。
- 判据要求：两趟的**同名同判词**（`v136=`／`nmp` 值**允许不同**，因为槽号依赖当时表占用 ⇒ **值可不同、判词必须相同**）；**判词不同 ⇒ 记 `NOINFO(样本不稳)`**，**不得**挑一趟当结论。
- **建议样本表形状**：`sample=1..n | gate=on | rc136a | fSucc1 | nmp1 | idem136 | rc168 | 判词`。

---

## §7 ⑦ 绿的正确读法（**逐字写死**）＋ `NOINFO` 面

### 7.1 绿只准读成这一句
> **「在今天的托管态下，`pfnGetFirstPara`（`+136`）对第一跳交出的 `nms` 返回了一个**非零、连调同值、且被下游槽接受（未得 `-100002`）**的段落句柄。」**

**不得**读成：❌"段落模型已成"／❌"排版打通"／❌"`pfsparaclient` 可用"／❌"三级链已存在"／❌"该句柄就是该页文档的第一个段落"（后者要**结构面**证据，见 §7.2）。

### 7.2 本探针**回答不了**的问题（`NOINFO` 面）
| # | 问题 | 为什么答不了 | 谁才能答 |
|---|---|---|---|
| 1 | 该 `nmp` 在表内**确为 `BaseParagraph` 族**且**是第一个段落**（不是容器/其它） | `+168` 只证"是 `BaseParagraph` 族"（而 `ContainerParagraph` 也是）⇒ **族内区分不了** | 托管侧读数（类型名）或结构面仪器 |
| 2 | `nms`→`nmp`→`pfsparaclient` **三级链已存在** | 本件只做第二跳；第三跳是 `pfnCreateParaclient`（`+176`） | 第三跳探针 |
| 3 | 段落**内容**是否正确／是否排版出可见结果 | 与本探针无关（`N1`／`N3`／`N4` 的判据面） | 页面症状面 ＋ `N4` 正身份（**今天 `NOINFO`**） |
| 4 | 首次调用**是否真的创建**了 `_firstChild`（而不是命中缓存） | 探针看不到 `_firstChild` 的内部状态 | 托管侧计数器（或"同趟先查缓存再调"的两次成对读数） |
| 5 | `-100002` 的**具体成因**（句柄类型 vs 调用窗 vs 别的 NRE） | 两处 `catch` **都把成因吞进 `PtsContext.CallbackException`**，探针只读得到 `rc` | 托管侧（读 `CallbackException` 的类型/消息）或 §8.2 的成对实验 |

---

## §8 ⑧ 可行性判定 ＋ 具名前置

### 8.1 判定：**能做到，且第二跳比第一跳更省事**（**不判"做不到"**）
两条现取理由：① **候选唯一**（§1.1 签名层排除另两条）；② **调用窗现成**（§1.5：`FlowDocumentPage.cs:136/:199` 的 `using(SetDocumentFormatContext)` **已经**把我们的入站 hook `FsCreatePageBottomless`／`FsCreatePageFinite` 包在里面）。

### 8.2 🔴 **本件的关键陷阱（必须写进判据）：`-100002` 有**两种**成因，只看 `rc` 分不开**
`ContainerParagraph.GetFirstPara`（`:151`）**无条件**读 `StructuralCache.CurrentFormatContext.IncrementalUpdate`，而 `CurrentFormatContext`（`StructuralCache.cs:290`）**窗外为 `null`**（`:678` 进窗置位／`:686` 出窗清空）⇒ **窗外调用 ⇒ NRE ⇒ 被 `catch` 吞 ⇒ `fserr=-100002`** —— 与"句柄不对"**同一个 `rc`**。
⇒ **判据硬要求（成对实验）**：
- **正腿**：在**窗内**（＝我们的入站 hook 内）调 `+136` ⇒ 期望 `0`（或 by-design 的 `0/0`）。
- **反腿（新）**：在**窗外**（副本文档上，例如从 `CreateDocContext` 里调 —— 那时 `SetDocumentFormatContext` **还没进**）调同一个 `+136` ⇒ 期望 `-100002`。
⇒ **两条都拿到，才准下"`nms` 被接受／不被接受"的机制级结论**；只拿到一条 ⇒ 记 `NOINFO(成因未分)`。
（该反腿**天然落在已有的 hook 上**（`CreateDocContext` vs `FsCreatePageBottomless`），**不需要新管道**。）

### 8.3 具名前置链
| # | 前置 | 现状 | 谁给／代价 |
|---|---|---|---|
| **P0** | `PRECOND-MEASURED-FSCBK-SLOT-OFFSETS` | **已闭合**（`+136` 绝对偏移；**引自 `t133`／`t138` 载体，本席未独立复算**） | — |
| **P1** | **`PRECOND-FSCBK-SNAPSHOT-IN-DOC`**（承 `t140`）：回调表必须在 `CreateDocContext` 调用期内快照进 doc 对象（`FSCONTEXTINFO*` 只在调用期内有效） | **属 `t140` 那条，本件不重复其论证** | native 一处（只读拷贝） |
| **P2** | **`PRECOND-WINDOW-FORMAT-CONTEXT`**（**本件新立**）：调用必须在 `SetDocumentFormatContext` 窗内 | **代码级认为已满足**（入站 hook 就在 `using` 内）；**运行期仍必须验**（§8.2 的成对实验） | 验＝一对读数；不改产品件 |
| **P3** | **`PRECOND-LIVE-SECTION-HANDLE`**（承 `t140`）：`nms` 只能从入站 `_section.Handle` 捕获 | 已在 `t146`／`t148` 达成第一跳（**引自其载体，本席未独立复算**） | — |
| **P4** | **`PRECOND-DOWNSTREAM-ACCEPTOR`**（**本件新立**）：要证"下游接受"，需要一个**只接受 `BaseParagraph`** 的槽且其结构风险低 | **`+168` 可用**，但**它不区分"段落"与"容器段落"**（§3.3）⇒ 若要求"确实是 first para"，需**托管侧类型读数** | 另派单（若要更强的身份） |

---

## §9 ⑨ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-drive-probe2-criteria.md`（新建；UTF-8；模式 **644**；**首记号 `# P1-W69 …`（不是 `# ⏪ `）**；末行自带可复算自报口径）。
- **末行自证口径当场复算**：口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`；**末行所载值 == 当场重算值 ⇒ MATCH**（值见末行）。
- **本件命令的末次执行时刻**：`ts=2026-09-29T16:52:43,508212546+08:00`（`date -Ins` 现取；与下方 `git status` 同趟）。
- **只读**：命令为 `grep`／`sed`／`awk`／`cat`／`sha256sum`／`stat`／`wc`／`git log`／`git status`。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- **未改任何其它件**：`git status --porcelain` 现取 —— 工作树里的 `M`／`??` **全部属他人**（`t141`／`t146`／`t148` 落地件与在飞 `src/**`），**本件是本次唯一新增件**。
- **引用纪律（逐处遵守）**：`P1-drive-probe-report.md`（`010dd16aac3b74561a7e…`／175 行）、`P1-drive-probe-gate-report.md`（`da0436c69988946dea6d…`／117 行）、`P1-fscbk-slot-recon.md`（`1d1e46bb31a97aa8b997…`／365 行）的值**一律标注「引自…，本席未独立复算」＋读取时刻 `2026-09-29T16:50–16:51`**；本件的**候选排序与全部入口条件**都是**我自己从上游源码现取**的（`文件:行` 逐条可回溯）。

---

### 结语（自包含）

- **① 候选排序（结论）**：**唯一候选 ＝ `pfnGetFirstPara`（`+136`）** —— **签名层面**它吃 `nms`、吐 `nmp`＋`fSuccessful`（`Pts.cs:2102-2106`）；**可达性**由"第一跳交出的 `nms` 是 `ContainerParagraph`（`Section.cs:234-242`）而 `ContainerParagraph : BaseParagraph, ISegment`（`ContainerParagraph.cs:19`）"闭合 ⇒ `PtsHost.cs:595` 的 `as ISegment` 命中。**`pfnGetNextPara`（`+144`）排除**（入参含 `nmpCur` ⇒ 循环依赖；它是第三跳起的"段落游走"）；**`pfnGetParaProperties`（`+168`）排除**（吃 `nmp`、吐 `FSPAP`），但**改用作"下游接受性"判别器**（附一条更正：`ContainerParagraph` 也继承 `BaseParagraph` ⇒ 它**不区分**"段落"与"容器段落"）。
- **② 成功语义**：`fserr` 值域 `0/-100002/-10000/其它`；两种合法形状 `FIRSTPARA-HANDLE(1,≠0)` 与 `FIRSTPARA-ABSENT(0,0)`（**后者不得读成失败**）；幂等＝**连调同值**；**最小证据串四格**（`rc136a=0`／`fSucc1=1 ∧ nmp1≠0`／`rc136b=0 ∧ nmp2=nmp1 ∧ idem136=1`／`rc168≠-100002`）。
- **③ T3 强制**：**试错一律走 T3**（真 `sect` → `+80` → live 错类型句柄 → 喂被测槽 ⇒ 期望 `-100002` 且可捕获）；**禁止伪值**（T1/T2 ⇒ `FailFast`）；**伪值必须避开真值域**（现取真值 `nms=0x1`／`nmSegment=0x2`）；给出**五步最小配方**与**两个具体用途**（`+136` 的反腿／候选排除的实证）。
- **④ 假进度必红 P1–P8**（含 **`fserr` 误读**／**零句柄当活**／**"被调用"当"链已通"**／**伪值代替 T3（且反腿空转要判红）**／**主链 `FailFast`**／**单样本当机制**／**by-design 反过读**／恒绿自检）。
- **⑤ 成对读数 R1–R9 ＋ 纪律 30 三格 ＋ **闸状态必须随读数给****（裁定三十六 (c)：跨闸不可比）。
- **⑥ ≥2 独立样本**（裁定三十八；同闸状态；值可不同、**判词必须相同**，否则 `NOINFO(样本不稳)`）。
- **⑦ 绿的正确读法（逐字）＋ 5 条 `NOINFO` 面**。
- **⑧ 可行性**：**能做到，且比第一跳省事**（调用窗现成）；**四条具名前置**（P0 已闭合／P1 承 `t140`／**P2 本件新立 `PRECOND-WINDOW-FORMAT-CONTEXT`**／P3 承 `t140`／P4 本件新立），并**点名本件最大的坑**：**`-100002` 有两种成因（句柄类型不对 vs 窗外调用触发 NRE），只看 `rc` 分不开 ⇒ 必须做"窗内 vs 窗外"成对实验**（该反腿天然落在已有 hook 上，不需新管道）。
`P1-DRIVE-PROBE2-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ ecae0481dbb0b3aa（口径＝末行之前的全文；末行＝本行）`

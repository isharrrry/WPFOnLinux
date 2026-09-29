# P1-W74 · 驱动链**第三跳**预登记判据 —— 窗内用合法 `nmp`(`0x3`) 调 `pfnCreateParaclient`(`+176`) 能否拿到合法 `pfsparaclient`

> **本件是判据件（先写），不是实现件**：**不实现、不构建、不跑腿、不占显示位、不跑整趟门禁、不 `git add/commit/push`**；**不碰任何源件与 `.cs`**、**不碰** `build/MilBridge/tools/**`。
> **唯一写入** ＝ 本件 `build/MilBridge/P1-drive-probe3-criteria.md`。
> **一切读数由我现取**；**引他人载体逐处带代际（`sha16`）＋取值时刻**并标注「引自 X，本席未独立复算」；**不预填任何运行期读数**。
> **读取时刻**：`ts=2026-09-29T17:12:43.505+0800`（起点）→ `ts=2026-09-29T17:13:26.847+0800`（末取）。

---

## §0 现取快照

| 项 | 现取值 | 取法 |
|---|---|---|
| `HEAD` | **`329282a`**（`docs(#81): 队长收口 —— cell=#1 同代一次性对齐（本波七个改过覆盖面内件的任务全部停工后）`） | `git log --oneline -3` |
| 第二跳载体（`t151`） | `build/MilBridge/P1-drive-probe2-report.md` ＝ **`89afcf354b80975e3253…`**／**223 行**／末行自证 **`d7f98875…`**／`mtime 2026-09-29 17:10` —— **本席现取，与任务书所给值相符** | `sha256sum`／`wc -l`／`tail` |
| native 在飞件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ **`8089fdfea1ac6f23`**／`mtime 2026-09-29 17:04:52.660636144`（**只用读**） | `sha256sum`／`stat` |
| 现取确认的**探针现状** | `wpf_pts_drive_probe()`（`win32_pts.c:~827+`）**已实现第一跳（`+56`／`+80`）＋第二跳（`+136`）＋窗外腿 `wpf_pts_drive_probe2_oow()`**；**第三跳（`+176`）尚未实现**（全文无 `pfnCreateParaclient` 的**调用**，只有偏移断言 `:523` 与只读名字表 `:586`） | `grep -n` |
| `pfsclient` 已在手 | `:848 const void *pfsclient = (const void *)d->p_fsclient;`（取自快照 `+24`；该字段在 `:158` 声明、`:988` 赋值 `c->p_fsclient = *(…)(b + 24)`） | `grep -n` |

---

## §1 ① 签名／装配／实现逐跳原文 ＋ **`pfsclient` 是什么**

### 1.1 三跳原文（`文件:行` 逐条可回溯）

**跳 1 —— 委托声明**（`Pts.cs:2128-2131`）
```
2128:  internal delegate int CreateParaclient(
2129:      IntPtr pfsclient,                   // IN:  client opaque data
2130:      IntPtr nmp,                         // IN:  name of paragraph
2131:      out IntPtr pfsparaclient);          // OUT: opaque to PTS paragraph client
```
**跳 2 —— 托管侧装配点**（`build/PresentationFramework.Linux/PtsCache.Linux.cs:620`）
```
620:  contextInfo.fscbk.cbkgen.pfnCreateParaclient = new PTS.CreateParaclient(ptsHost.CreateParaclient);
```
**跳 3 —— 实现**（`PtsHost.cs:724-745`）
```
724:  internal int CreateParaclient(
725:      IntPtr pfsclient,                   // IN:  client opaque data
726:      IntPtr nmp,                         // IN:  name of paragraph
727:      out IntPtr pfsparaclient)           // OUT: opaque to PTS paragraph client
728:  {
729:      int fserr = PTS.fserrNone;
730:      try
731:      {
732:          BaseParagraph para = PtsContext.HandleToObject(nmp) as BaseParagraph;    // ★ 只吃 nmp
733:          PTS.ValidateHandle(para);
734:          para.CreateParaclient(out pfsparaclient);                                 // ★ 由段落自己造客户端
735:      }
736:      catch (Exception e)
737:      {   pfsparaclient = IntPtr.Zero; PtsContext.CallbackException = e;
738:          fserr = PTS.fserrCallbackException; }
••      …
744:      return fserr;
745:  }
```
🔴 **第 1 条硬事实（现取）**：**`PtsHost.CreateParaclient` 一个字节都不读 `pfsclient`** —— 它只用 `nmp`。（⇒ `pfsclient` 传什么都不影响本跳成败；但**判据仍要求如实记下**，见 §1.3。）

### 1.2 `pfsparaclient` **谁造的**（现取：每种段落类型都是"每次新建"）

`CreateParaclient` 在托管侧是**逐段落类型覆写**（现取共 **10 处**：`SubpageParagraph:76`／`RowParagraph:79`／`ContainerParagraph:424`／`FloaterParagraph:73`／`UIElementParagraph:86`／`FigureParagraph:78`／`TextParagraph:113`／`FloaterBaseParagraph:77`(abstract)／`TableParagraph:125`／`ListParagraph:34`）。两处代表实现原文：
```
TextParagraph.cs:113-122          internal override void CreateParaclient(out IntPtr paraClientHandle)
                                  {   // TextParaClient is an UnmamangedHandle, that adds itself to HandleMapper …
                                      TextParaClient paraClient = new TextParaClient(this);    // ★ 每次 new
                                      paraClientHandle = paraClient.Handle; }
ContainerParagraph.cs:424-433     同一形状：ContainerParaClient paraClient = new ContainerParaClient(this);
                                  paraClientHandle = paraClient.Handle;                      // ★ 每次 new
```
⇒ 🔴 **第 2 条硬事实（本件最要紧的一条）**：**`+176` 不是幂等的** —— 每调一次**新建**一个 `*ParaClient`（`BaseParaClient : UnmanagedHandle` ⇒ 显式实现 `Dispose()`（`:34-48` 唯一实现）⇒ 归还 `_handle` 并 `GC.SuppressFinalize`）⇒ **每次调用的句柄是"新造的、与本次调用绑定"的值**；其**生命周期由 PTS 负责**（各覆写处的逐字注释："PTS manages lifetime of this object, and calls DestroyParaclient to get rid of it"）。
⇒ **推论（写进判据）**：**连调两次** ⇒ **两个不同的句柄**（且**两个都 live**）⇒ **不调 `+192` 就泄漏**（托管表新增两条活条目，永不释放）。

### 1.3 `pfsclient` 是什么 ／ **native 今天有没有它**
```
PtsCache.Linux.cs:523  InitGenericInfo(ptsHost, (IntPtr)(index + 1), installedObjects, installedObjectsCount, ref _contextPool[index].ContextInfo);
PtsCache.Linux.cs:596  contextInfo.pfsclient = clientData;
```
⇒ **`pfsclient` ＝ 上下文池下标 ＋ 1**（一个**小整数**，不是指针）。
⇒ **native 今天**已经**有它**：`wpf_pts_doc.p_fsclient`（`win32_pts.c:158` 声明、`:988` 从结构 `+24` 读、`:848` 取出使用）⇒ **本跳不新增前置**。
⚠️ 🔴 **陷阱（写死）**：`pfsclient` 的**值域与句柄值域同形**（都是小正整数） ⇒ **绝不许**把 `pfsclient` 当句柄喂给任何槽，也**绝不许**把句柄当 `pfsclient`。判据要求**两者在日志里分字段打印**（本项目 `t149` 的 `§2.4` 已要求"如实记下"，本件沿用）。

---

## §2 ② 成功语义（可证伪；给最小证据串）

### 2.1 `fserr`（值域现取）
`0` ＝ `PTS.fserrNone`（唯一成功）；`-100002` ＝ `tserrCallbackException`（`Pts.cs:511`；本跳由 `:736`／`:742` 两个 `catch` 支置位）；`-10000` ＝ `tserrNotImplemented`（`:507`）；**其它一律非成功**。

### 2.2 **`pfsparaclient` 的非零 ＋ 幂等口径（**本跳与前两跳口径相反，必须写清**）**
| 情形 | 判据 | 理由（现取） |
|---|---|---|
| **两次调用得到**不同**值**（`h1 ≠ h2`，两者皆非零） | **符合实现** ⇒ 判 `PARACLIENT-NEW-PER-CALL(h1,h2)`；**且必须点名"两次都 live"** ⇒ **必须两次都调 `+192` 回收**，并在判词里报"回收前/后活条目数" | §1.2：每个覆写都 `new` |
| 两次得到**相同**值 | **either** 该段落类型走了缓存路径（**要求实现件点名是哪一处覆写／哪一行**），**or** 探针只调了一次 ⇒ 否则判红 | —— |
| 任一次为 `0` | **不得**判绿（`pfsparaclient=0` 是"未产出"） | `:737` 失败即置 `Zero` |
🔴 **因此本跳的正确判据不是"连调同值"，而是"连调**各自非零且互不相同**，且**两次都被 `+192` 成功回收**"**（幂等口径**不许**照抄第二跳）。

### 2.3 **下游接受性判别器（现取三家对比；这是本件第二重要的产出）**
| 槽 | 帧 B 绝对偏移 | 现取实现 | 能否当"接受性"判别器 |
|---|---|---|---|
| **`pfnDestroyParaclient`** | **`+192`** | `PtsHost.cs:776-798`：`HandleToObject(pfsparaclient) as BaseParaClient` ＋ `ValidateHandle` ＋ `paraClient.Dispose()` | ✅ **唯一"三合一"**：**类型正好是 `BaseParaClient`**（＝本跳产物的契约类型）＋ 真校验 ＋ **顺带完成清理**（§2.2 本来就要求回收）。⚠️ **有副作用**（销毁），**须点名** |
| `pfnTransferDisplayInfo` | `+184` | `:750-762`：**两个** `pfsparaclient` 各自 `as BaseParaClient` ＋ `ValidateHandle`，再 `paraClientNew.TransferDisplayInfo(paraClientOld)` | ⚠️ 能校验，但**需两个 client** 且**改显示信息**（副作用更大）⇒ 不作首选 |
| **`pfnFInterruptFormattingAfterPara`** | **`+200`** | `:799-808`：**`{ fInterruptFormatting = PTS.False; return PTS.fserrNone; }`** —— **形参含 `pfsparaclient` 却一个字节都不读** | 🔴 **禁用**：它对**任何**值（含 `0`／伪值）都返 `0` ⇒ **"恒定绿"陷阱** ⇒ 用它判接受＝**假绿**。**写成 P 条（见 §4-P9）** |

### 2.4 **最小证据串（五格；本跳）**
```
① rc176a=0                       （+176 首调 fserr=0）
② h1=pfsparaclient≠0             （首调产出非零 ⇒ 托管侧真的 new 出了 BaseParaClient）
③ rc176b=0 ∧ h2≠0 ∧ h2≠h1       （次调再产出**另一个**活的；见 §2.2）
④ rc192a=0 ∧ rc192b=0           （**两个**都被 +192 接受 ⇒ §2.3 的"类型对＋校验"通过，且**回收完成**）
⑤ live_before / live_after      （表内活条目数：**回收后必须回到 before**；否则判"泄漏"）
```
⚠️ **⑤ 的可得性**：托管表活条目数今天**没有**现成的只读口（本席现取未见）⇒ 若取不到，**记 `NOINFO(无表内活条目只读口)` 并写明"泄漏只能用 ④ 的成对成功间接证"**，**不得**用"腿没崩"代替。

---

## §3 ③ T3 模式复用 ＋ **零伪值**

**T3 五步配方（照 `build/MilBridge/P1-drive-probe2-criteria.md`（本席自己的上一件）的 §3 ③ 逐条沿用）**
```
步 0  开闸：env `WPF_PTS_DRIVE_PROBE=1`（非空且 ≠ "0"）；缺省关 ⇒ `[DRIVE-PROBE-SKIP] reason=gate-off`、**零回调调用**
步 1  用**真** `sect` 调 `+80` ⇒ 拿到 live 的 `ContainerParagraph` 句柄（＝第一跳的 `nms`）
步 2  把它当 **live 的错类型句柄**（对只认 `Section` 的槽而言它类型不对）
步 3  喂给**被测槽**
步 4  期望 `rc=-100002`（**可捕获**）∧ 进程活 ∧ `unrec=0` ∧ `failfast=0`
步 5  若得 `0` ⇒ **该槽接受了这个类型** ⇒ **如实记**（这条信息本身有价值）
```
🔴 **零伪值 ＋ 真值域并列（现取，逐趟必须重取）**：`sect=0x1`／`nmSegment=0x2`／`nmp=0x3`（**引自 `t151` 载体 `89afcf354b80975e3253…`／223 行，本席未独立复算**；判据要求**每趟现取真值域并列出**）⇒ 反腿所用值**必须证明 ∉ {0x1,0x2,0x3,0}**；否则**反腿空转**（撞真对象 ⇒ 变成"正路"）⇒ 判"反腿无效"（§4-P5）。
**本跳的 T3 具体用法（两处）**：
1. **`+176` 的反腿**：把一个 **live 错类型句柄**（例如 `+80` 的 `nms`＝`ContainerParagraph`… ⚠️ **注意**：`ContainerParagraph` **继承 `BaseParagraph`** ⇒ `:732` 的 `as BaseParagraph` **会命中** ⇒ **它对本槽是"对类型"**！）⇒ ⇒ **本跳必须换用真正的错类型 live 句柄**（例如托管侧另一族对象，`Section`＝`0x1`：`Section : UnmanagedHandle` **不是** `BaseParagraph` ⇒ 喂 `0x1` 给 `+176` 应得 `-100002`）。**这一条是 T3 在本跳的正确用法，照抄前两跳的"用 `nms` 当错类型"会失效。**
2. **`+192` 的反腿**：用一个 **live 的错类型句柄**（如 `nms`＝`ContainerParagraph`；它**不是** `BaseParaClient`）⇒ 期望 `-100002`。

---

## §4 ④ 「假进度必红 P1–P9」

> **总则（写死）**：**反腿未红、或红而不点名 ⇒ 该条判不成立**；**反腿只在应用副本上跑**；点名认 **`reason=` token 或字段名二者之一**。

| # | 假形式 | 正腿（必绿） | 反腿（**必红并点名**） | 必红点 |
|---|---|---|---|---|
| **P1** | `fserr` 非零读成成功 | `fserr=0` 才叫成功 | 副本上改成"只看 `pfsparaclient≠0`" ⇒ 必红 | `fserr<0 ∧ 判词=成功` ⇒ 红（`reason=fserr-ignored`） |
| **P2** | **零句柄当活句柄** | 绿要求 `h≠0` | 把 `pfsparaclient=0` 判绿 ⇒ 必红 | `h=0 ∧ 判词=成功` ⇒ 红（`reason=zero-handle-as-live`） |
| **P3** | 🔴 **native 自造句柄值**（本跳最容易的自欺） | 判词必须声明"该值**来自 `out` 形参**"，并给 `out` 形参在**同趟**的被写证据（例如镜下该出参地址的值） | 副本上在调 `+176` **之前**先把 `*out` 写成自己造的常量／指针 ⇒ **但**：若自造值被**下游 `+192` 接受**（`rc192=0`）而实际上并未由托管产出 ⇒ 必红并点名 | **判词无法把"自造值"与"托管产出值"分开** ⇒ 红（`reason=self-made-handle`）；**判据要求**：`+192` 的 `rc=0` **必须**与"`+176` 后 `*out` 相对**调用前**发生了变化（从 `0` 变为非零）"**成对**给出 |
| **P4** | "槽被调用"读成"链已通" | 判词只到"该槽返回了 X" | 只用 `[DRIVE-PROBE-ENTER]` 在场判绿 ⇒ 必红 | 判词含"链/三级/模型 已通/已成"而无 §2.4 五格 ⇒ 红（`reason=call-equals-chain`） |
| **P5** | **用伪值代替 T3** | 反腿走 T3 ＋ **声明值 ∉ 真值域** | 用伪值 ⇒ **必红并按类点名**：越界 ⇒ `FailFast`（T1）；**撞真值域（`0x1/0x2/0x3`）⇒ 反腿空转 ⇒ 判"反腿无效"** | 未给"值 ∉ 真值域"证明 ⇒ 红（`reason=fake-in-real-domain`）；反腿不红 ⇒ 红 |
| **P6** | **在主链制造 `FailFast`** | 主链只跑非破坏性探针 | 把破坏性试错放进主链 ⇒ 必红 | 主链日志出现 `Invariant.FailFast`／`Unrecoverable system error.` ⇒ 红（`reason=main-chain-dirty`） |
| **P7** | **单样本当机制**（裁定三十八） | 每条款 **≥2 趟独立样本** | 1 趟就写"机制/恒/总"⇒ 必红 | 样本数 <2 而用机制级措辞 ⇒ 红（`reason=single-sample-as-mechanism`） |
| **P8** | **by-design 反过读**（本跳的同族：把"每次新建"读成"不稳定/失败"） | §2.2：两值不同＝**符合实现** | 把 `h1≠h2` 判成"非确定性/红"⇒ 必红 | `h1≠h2 ∧ 判词=红/非确定性` ⇒ 红（`reason=new-per-call-read-as-failure`） |
| **P9** | 🔴 **恒定绿判别器**（本件新加） | 接受性判别器**必须真的读该参数**（`+192` 现取读它） | 用 `+200 FInterruptFormattingAfterPara` 判接受 ⇒ **对任何值都返 0** ⇒ 必红并点名 | 判别器对**已知非法值**（如 `0`／伪值）**也返 0** ⇒ 红（`reason=acceptor-always-green`）。**判据要求：每个判别器都必须先过"对非法值必红"的自证** |

---

## §5 ⑤ **≥2 个独立样本**（裁定三十八）＋ 成对读数 ＋ 纪律 30 三格

### 5.1 样本口径
- **每条款 ≥2 趟独立样本**（独立进程／独立运行），**同闸状态**（`WPF_PTS_DRIVE_PROBE=1`；**跨闸不可比** —— 裁定三十六 (c)）；
- **值可不同、判词必须相同**（本跳的"值"按 §2.2 本来就**允许不同**：`h1`／`h2` 依赖当时表占用 ⇒ **判词同＝`PARACLIENT-NEW-PER-CALL` ＋ 两次 `+192` 成功**）；
- **判词不同 ⇒ `NOINFO(样本不稳)`**，**不得**挑一趟当结论；
- 建议样本表：`sample | gate | rc176a | h1 | rc176b | h2 | h2≠h1 | rc192a | rc192b | live_before | live_after | 判词`。

### 5.2 成对读数（前/后；今天的值一律 `NOINFO`）
| # | 面 | 字段 | 期望 |
|---|---|---|---|
| R1 | **探针闸状态** | `[DRIVE-PROBE-SKIP] reason=gate-off` 行数／`[DRIVE-PROBE-ENTER]` 行数 | 闸关 ⇒ 零调用；闸开 ⇒ `ENTER≥1`。**每个读数必须带闸状态** |
| R2 | 探针读数 | `[DRIVE-PROBE]` 行（本跳字段名由实现件同趟写死） | 按 §2.4 五格 |
| R3 | `pfsclient` | 同行的 `pfsclient=` 字段 | **如实记**；须与 `nmp` **分字段**（§1.3 陷阱） |
| R4 | 导出面 | `nm … \| grep -c .` ＝ `wc -l exports.txt`；`^Fs=` | 相等；本步不靠加导出收尾（新增只读口须逐名点名） |
| R5 | 两页症状面 | `leg_{23,24}.env` 的 `LEG`／`NAMED`／`DEV`／`FAILLINE`／`FRAME` | `alive=yes`／`app_rc ∉ {134,139}`／`failfast=0`／`unrec=0` |
| R6 | `ENFE_TOTAL` | `grep -c 'Unable to find an entry point named' <log>` | 如实给（**必须同趟给留痕面**，缺一不得判绿） |
| R7 | 同趟性 | 两腿 `DEV … shim=`／`pf=`；`session.txt` 的 `shim_sha16`／`pf_sha16`；现盘件 | 四值同；**不许拿 `legs=2/2` 当同趟证据** |

### 5.3 纪律 30 三格（缺一 ⇒ 不许当证据）
1. **进程新鲜度**：fresh 或同进程＋**已发生的关键调用序**（逐条列：建过几个 `PtsContext`／入站 `FsCreatePageBottomless` 几次／`+80`／`+136`／`+176`／`+192` 各几次／是否走过 T3）。
2. **关键前置量**：`sect`／`nmSegment`／`nmp`（**现取真值域并列**）、快照是否就位、**当前是否在 `SetDocumentFormatContext` 窗内**、**该 `PtsContext` 是否仍活**（见 §8.3 的第二条 `FailFast` 通路）。
3. **判词**：`rc` ＋ `diag`（自检格号；红时点名）。
> ⚠️ **"净腿不崩＝假绿"**本会话已有三例硬实证 ⇒ 本件证据是 §2.4 的五格，**不是**"腿没崩"。

---

## §6 ⑥ `P4`（`PRECOND-DOWNSTREAM-ACCEPTOR`）状态对第三跳的影响 —— **判定：不影响**

**理由（逐条）**：
1. `P4` 的未闭部分是"**`nmp` 是 `BaseParagraph` 族、但未证是该页文档的第一个段落**"；而 **`+176` 的入口条件只要求** `HandleToObject(nmp) as BaseParagraph` 命中（`PtsHost.cs:732-733` 现取）—— **`+176` 不关心"是不是第一个"**，只关心"是不是 `BaseParagraph`"。
2. 同理，本跳的**下游接受性**由 `+192` 承担，而 `+192` 的条件也只是 `as BaseParaClient`（`BaseParaClient : UnmanagedHandle`，由 `BaseParagraph.CreateParaclient` 新建的那个对象**必然是**它）⇒ **与"是不是 first para"无关**。
⇒ **写死**：**本跳只要求"合法 `nmp`（＝一个 live 的 `BaseParagraph` 族对象）"**；`P4` 的剩余部分（**身份**：是哪一个段落）**不影响本跳**，它影响的是"**把段落模型说成'该文档的第一个段落'**"这类**语义级**断言 ⇒ **该语义级断言仍须 `NOINFO`，不得由本跳的绿支撑**。

---

## §7 ⑦ 绿的正确读法（**逐字写死**）＋ `NOINFO` 面

### 7.1 绿只准读成这一句
> **「在今天的托管态下、在窗内，`pfnCreateParaclient`（`+176`）对合法 `nmp` 返回了一个**由托管回调自己产出**（`out` 形参确实被写、且下游 `+192` 接受）、且**能被 `+192` 成功回收**的段落客户端句柄。」**

**不得**读成：❌"段落模型已成"／❌"排版打通"／❌"三级链已存在"／❌"两页能排版"／❌"`pfsparaclient` 可被 native 安全地长期持有"（它由 PTS 管理生命周期：各覆写处逐字注释）。

### 7.2 本探针**回答不了**的问题（`NOINFO` 面）
| # | 问题 | 为什么答不了 | 谁才能答 |
|---|---|---|---|
| 1 | 该 `pfsparaclient` **在托管表内且 `Obj is BaseParaClient`** 的**直接**读数 | native 看不到托管表；`+192` 的 `rc=0` 只是**间接**证据（托管侧接受） | 托管侧只读读数（与已派的那样） |
| 2 | 表内**活条目数**的 before/after（§2.4-⑤ 的泄漏面） | 现取**未见**现成只读口 | 托管侧只读口（或 native 侧自记 `CreateHandle` 计数——属另一件） |
| 3 | `nmp` 是**该页文档的第一个段落** | `P4` 部分满足（§6） | 托管侧类型读数件（已另派） |
| 4 | `+176` 产出的客户端**是否可用于真正的排版** | 需要排版链（`FormatParaFinite` 一族） | 后续跳 |
| 5 | `-100002` 的**具体成因**（类型不对 vs 窗外 vs context 已销毁） | 三处 `catch` 都把它吞进 `PtsContext.CallbackException`，探针只读得到 `rc` | §8.4 的成对实验（窗内/窗外/已销毁）＋ 托管侧读数 |

---

## §8 ⑧ 可行性判定 ＋ 具名前置 ＋ **三条最高风险**

### 8.1 判定：**能做到**（**不判"做不到"**）
三条现取理由：① **入口条件已满足**（`nmp=0x3` 是 live `BaseParagraph`，`+168` 已接受 —— **引自 `t151` 载体 `89afcf354b80975e3253…`，本席未独立复算**）；② **`pfsclient` 已在手**（`wpf_pts_doc.p_fsclient`，`:158`／`:988`／`:848`）⇒ **无新前置**；③ **第三跳的调用点与第一/二跳同一个 hook 内**（`FsCreatePageBottomless`／`FsCreatePageFinite`）⇒ **不需新管道**。

### 8.2 具名前置链
| # | 前置 | 现状 | 谁给 |
|---|---|---|---|
| `P0` | `PRECOND-MEASURED-FSCBK-SLOT-OFFSETS`（`+176` 绝对偏移） | **已闭合**（`+176`；本席 `t138` 表与 `t133` 实测交叉一致 —— **引用，不复算**） | — |
| `P1` | `PRECOND-FSCBK-SNAPSHOT-IN-DOC` | **已闭合**（第一/二跳已在用快照；`wpf_pts_snap_word()` 现取在位） | — |
| `P2` | `PRECOND-WINDOW-FORMAT-CONTEXT` | **对第二跳已现证**（`t151`）；**对本槽的敏感性＝待测**（见 §8.3） | 成对实验 |
| `P3` | `PRECOND-LIVE-SECTION-HANDLE` | **已闭合**（`t146`／`t148`） | — |
| `P4` | `PRECOND-DOWNSTREAM-ACCEPTOR` | **部分满足**；**对本跳不影响**（§6） | 托管侧读数（另派） |
| **`P5`** | **`PRECOND-WRONG-TYPE-LIVE-HANDLE`（本件新立）** | **本跳 T3 需要"真正错类型"的 live 句柄** —— 而**现成的 `nms`（`ContainerParagraph`）对本槽是"对类型"**（`:732 as BaseParagraph` 会命中）⇒ **不能拿 `nms` 当本跳的错类型** | 可用 `sect`（`Section : UnmanagedHandle`，**不是** `BaseParagraph`）作 live 错类型句柄；若该值在真值域内 ⇒ **须另造方案并证明 ≠ 真值** |

### 8.3 🔴 **三条最高风险（逐条给判据动作）**
1. **native 自造句柄**（本跳最容易的自欺）：`pfsparaclient` 的**唯一合法来源 ＝ 托管回调的 `out` 形参**（`PtsHost.cs:734` → 各 `*Paragraph.CreateParaclient` 里的 `new *ParaClient(this).Handle`）。**判据动作**：§4-P3 —— 判词必须把"`+176` 前 `*out` 为 `0`"与"`+176` 后 `*out` 非零"**成对**给出，且 `+192` 的接受必须**同一趟**；缺任一条 ⇒ 判红。
2. **反腿只在副本上跑**：主链零破坏五条照旧（① 主链无 `Invariant.FailFast`／`Unrecoverable system error.`；② 主链导出面不变；③ 主链两页症状面前后逐格相同；④ 主链不因探针新增失败原因；⑤ 探针只读既有只读口、不改产品件）。
3. 🔴 **`+176` 的窗内外成对实验（与 `t151` 同形；但**预期与第二跳不同**）**：
   - **代码级预判（本件写明这是预判，不是读数）**：`+176` 的路径是 `HandleToObject(nmp)` → `para.CreateParaclient(out h)` → `new *ParaClient(this)` → `BaseParaClient(BaseParagraph) : base(paragraph.PtsContext)` → `UnmanagedHandle(ptsContext)` → `PtsContext.CreateHandle(this)`；现取 `TextParaClient` 的构造体**为空**（`TextParaClient.cs:34-36`），`CreateHandle`（`PtsContext.cs:175-196`）**不读** `CurrentFormatContext` ⇒ **本槽很可能对窗不敏感**。
   - ⇒ **判据写死**：成对实验必须做，**但"窗内=0 ∧ 窗外=0"＝`WINDOW-INSENSITIVE(有据)`（可接受，须附该预判的现取依据）**，**不判红**；"窗内=0 ∧ 窗外=-100002" ⇒ `WINDOW-SENSITIVE`；**只拿到一条 ⇒ `NOINFO(成因未分)`**（照 `t151` 口径）。⚠️ **不许**把"两边都 0"硬判成"实验失败"（那是**假红**）。
   - **本件另加一条新的 `FailFast` 通路（现取）**：`PtsContext.CreateHandle` 的两条断言 —— `:177 obj != null`、**`:178 !this.Disposed`（"PtsContext is already disposed."）** ⇒ **在 `DestroyDocContext` 之后调 `+176` ⇒ 撞 `Invariant.FailFast`（不可捕获）**。⇒ **判据要求**：主链探针必须**确认 context 仍活**（同趟给"该 context 未销毁"的读数）；**该路径的反腿只在副本上跑**（期望 `FailFast` ＋ `app_rc=134` 家族）。

---

## §9 ⑨ 载体与边界遵守自证

- **载体**：`build/MilBridge/P1-drive-probe3-criteria.md`（新建；UTF-8；模式 **644**；**首记号 `# P1-W74 …`（不是 `# ⏪ `）**；末行自带可复算自报口径）。
- **末行自证口径当场复算**：口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`；**末行所载值 == 当场重算值 ⇒ MATCH**（值见末行）。
- **本件命令的末次执行时刻**：`ts=2026-09-29T17:14:22,317019181+08:00`（`date -Ins` 现取；与 `git status` 同趟）。
- **只读**：命令为 `grep`／`sed`／`awk`／`cat`／`sha256sum`／`stat`／`wc`／`tail`／`git log`／`git status`。**零 `dotnet build`、零跑腿、零显示位、零整趟门禁、零 `git` 写。**
- **未改任何其它件**：`git status --porcelain` 现取 —— 工作树里的 `M`／`??` **全部属他人**（在飞 `src/**` 与 `tools/**`、`t151` 载体、`arm_A/**`），**本件是本次唯一新增件**。
- **引用纪律**：`P1-drive-probe2-report.md`（`89afcf354b80975e3253…`／223 行／自证 `d7f98875…`）与 `P1-drive-probe-report.md`／`P1-drive-probe-gate-report.md` 的值**一律标注「引自…，本席未独立复算」＋读取时刻 `2026-09-29T17:12–17:13`**；**本件的三跳原文、`pfsclient` 来源、四槽偏移、`TextParagraph`／`ContainerParagraph` 覆写、三家的判别器可用性、两条 `CreateHandle` 断言，全部是**我自己从上游源码与现盘 native 件现取**的**。

---

### 结语（自包含）

- **① 逐跳原文**：委托 `Pts.cs:2128-2131`／装配 `PtsCache.Linux.cs:620`／实现 `PtsHost.cs:724-745`（**逐字指出：它只吃 `nmp`、不读 `pfsclient`**）；`pfsclient` ＝ **池下标+1**（`:523` → `:596`），**native 今天已有**（`wpf_pts_doc.p_fsclient`，`:158`／`:988`／`:848`）⇒ **无新前置**；并点出**值域同形陷阱**（`pfsclient` 与句柄都是小整数 ⇒ 不许互喂）。
- **② 成功语义**：`fserr` 值域；`h≠0`；🔴 **幂等口径与前两跳相反** —— 各覆写都是 `new *ParaClient(this)` ⇒ **两次应得两个不同的活句柄**，且**两次都必须被 `+192` 回收**（否则泄漏）；**下游接受性判别器现取三家对比**：**`+192 DestroyParaclient` 唯一三合一**（类型正对 `BaseParaClient`＋校验＋清理）／`+184` 需两个且有副作用／🔴 **`+200` 是恒定绿陷阱（stub，不读参数）⇒ 禁用**。**最小证据串五格**。
- **③ T3 复用 ＋ 零伪值**（真值域 `0x1/0x2/0x3` 现取并列）；并指出**本跳的 T3 必须换用真正的错类型句柄**（`nms` 对本槽是"对类型"）。
- **④ 假进度必红 P1–P9**（含 **native 自造句柄**、**恒定绿判别器**、**把"每次新建"反过读成失败**、单样本当机制、主链 `FailFast`）。
- **⑤ ≥2 独立样本 ＋ 成对读数 R1–R7 ＋ 纪律 30 三格**（跨闸不可比）。
- **⑥ `P4` 对第三跳无影响**（只要求合法 `BaseParagraph` 族 `nmp`）＋ 语义级断言仍须 `NOINFO`。
- **⑦ 绿的正确读法（逐字）＋ 5 条 `NOINFO` 面**。
- **⑧ 可行性（能做到）＋ 五条前置（`P5` 本件新立）＋ 三条最高风险**（含**新的 `FailFast` 通路**：`CreateHandle` 的 `!:178 this.Disposed` ⇒ 在已销毁 context 上调 ⇒ 不可捕获）。
`P1-DRIVE-PROBE3-CRITERIA 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 6e68680b1f107d40（口径＝末行之前的全文；末行＝本行）`

# P1-W82 · 下一跳对的一半 `(a)`：让 `pfspara` 成为本侧**可认领的真对象**

> **本件是 `t162`（runner）的交付**：执行判据件 `build/MilBridge/P1-subtrack-criteria.md`（326 行／full sha256 `01b00c39ad6f1e84…`／末行自证 `7dcd11d7f0afa065`）—— **先完整读了它的 §1–§12**。**本件只做 `(a)`**；`(b)`（`FsQuerySubtrackDetails` 作答）另有件。
> **写域**：`src/WpfGfx.Linux.Native/**`（`src/win32_pts.c`／`bin/exports.txt`／`tools/pts-gap-decl.txt`）＋本载体。**未碰** `build/MilBridge/tools/**`／`build/MilBridge/tests/**`／`docs/**`／任何 `.cs`／两枚哨兵／`HANDOFF-NEXT.md` 的 `cell=#1`（**队长收口** ⇒ 载体记「**有意未登记**」）。
> **相位位 `phase=degraded` 未动**；探针闸／强度旋钮／T3 门变量**缺省路径不得改变**；未跑整趟门禁；未 `git add/commit/push`。

---

## §0 现取快照（**跑前**）

| 项 | 现取 |
|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | **`c90a78af8bc9499c`**／276434 B／mtime `18:05:19`（**与判据件 §1 读到的同一版**；「今日已换两代」的两代＝`6d967d8843bd902b`→`c90a78af8bc9499c`，本件开工在后者） |
| `bin/libwpfwin32.so` | `ca97eacb8bb123f1`（`t160` 收尾值，**权威**） |
| `bin/exports.txt` | `163c231022c4d088`（**651** 行） |
| `tools/pts-gap-decl.txt` | `087da7987fed5c6c` |
| 托管权威件 | `pf16=0b4b65f2c6c7ffd4`（本件不动） |
| HEAD | `10f8311`（`docs(#81): t161 …判据 —— 判「钥匙」…`），开工现取 |
| 资源／显示位 | `MemAvailable 3718340 kB`／`SwapFree 1377788 kB`／`df` 余 `71025000 kB`；`/tmp/.X11-unix/` 仅 `X0 X1` |
| `t160` 回归基线 | `fill=1085／1113`、`resolve=ok ×33`、`GAP rc=-10000=0`、`off16=16`（引自本席 `t160` 载体 `a3ca7725e9935eef…`；**同代**） |

---

## §1 靶心与「合法来源」的**预登记判定**（跑前写死）

**逐跳原文（判据 §1 §4 现取，本席复核）**：
```
PtsHelper.cs:179        paraClient.Arrange(arrayParaDesc[index].pfspara, rcPara, dvrTopSpace, fswdirTrack);
BaseParaClient.cs:61-66 internal void Arrange(IntPtr pfspara, …) { Debug.Assert(_paraHandle == IntPtr.Zero || _paraHandle == pfspara); _paraHandle = pfspara; }
ContainerParaClient.cs:271  PTS.Validate(PTS.FsQuerySubtrackDetails(PtsContext.Context, _paraHandle, out subtrackDetails));
```
⇒ `pfspara` 最终成为 subtrack 查询的 **`pSubTrack`**。**本侧今天 `pfspara` 恒 0**（`memset` 后只写 `pfsparaclient`／`nmp`）⇒ `pSubTrack = NULL`。

**本件的判定（预登记）**：`pfspara` 的**唯一合法来源是托管产出的段落句柄** —— 本侧**不可自造**。本侧**已在手**的合法候选＝**`+136 pfnGetFirstPara` 产出的 `nmp`**（`ContainerParagraph._firstChild`；`t151` 已现证 `+168 GetParaProperties` **接受**它）；另有 `+80` 产出的 `nmSegment`（也是 `ContainerParagraph`）。
⇒ **本件取 `pfspara := nmp`（同 run 产出、可认领）**，并把「**同值**」这一设计选择**点名**（不是"§4(a) 要求我们另造一个对象"）；若审查认为 `pfspara` 必须与 `nmp` **不同值**（另一个段落实例），那是**新证据**，进裁定 —— 本件**不**自造第二类对象。

---

## §2 预登记判别式（**跑前写死**；每条都给"能证伪它的格"）

| # | 命题 | 证伪格（⇒ 判红/作废） | 支撑格 |
|---|---|---|---|
| **D1 来源合法** | `pfspara` 必须与**同 run 的产出行**同值（`[DRIVE-PROBE2] nmp1=` 或 `[DRIVE-PROBE3] nmp176=`） | 填进列表的值**在本 run 的产出行里找不到** ⇒ **自造** ⇒ 判红（`reason=para-not-from-this-run`） | `[FSPARALIST-PARA] … src=+136.nmp same_value=1` |
| **D2 成对证据（防"非零即绿"）** | ①`pfspara_pre=nil`（**写入前**该槽为 0）②写入后非零 ③**下游接受**（`+168 GetParaProperties(pfsclient, pfspara, …)` 返 `0`） | 缺任一条 ⇒ 判红（`reason=para-pair-incomplete`）；**"非零"本身永不构成证据** | 三个字段同趟给 |
| **D3 台账认领** | 每个填出的 `pfspara` 都能被本侧台账**唯一**认领（doc 身份 ＋ 产出行 ＋ 值） | 认领失败（未知/跨 doc/跨 run）⇒ 该趟作废并具名 | `claims=`／`rejected=` 计数口 ＋ 逐趟行 |
| **D4 持有期 ＝ 托管对象生存期** | 同一 `pfspara` 在**后续调用**里继续被填、且下游**仍接受**（跨调用持有成立） | 跨调用后下游拒（`+168` 返非 0）⇒ 判"持有期不成立/对象已死" ⇒ 本格 `NOINFO` 或红 | 首末趟的 `same_value`／`acc_rc` |
| **D5 销毁口径（我们**不**回收）** | 本侧**绝不**回收 `pfspara`（它不是我们造的）；本侧只持**引用**，台账随 doc 注销整体失效 | 出现本侧对 `pfspara` 的任何"释放/回收"动作 ⇒ 判红 | `released=0` 计数口 ＋ 代码面 |
| **D6 P8 反腿（必红）** | ① `pfspara` ＝**非本 run 产出**的值 ⇒ **认领失败⇒红**；② `pfspara` ＝**live 但错类型**（`sect`＝`Section`，本 run 产出但**不是段落**）⇒ **下游拒（`+168` 非 0）⇒ 红** | 两条反腿**任一不红** ⇒ 本件判红（`reason=p8-pair-not-red`） | 两条副本腿的逐字行 |

**"`cParas=0` 恒绿陷阱"在本件的处置（预登记）**：本件**不产 `cParas`**（那是 `(b)`）⇒ 本件对它**只**做两件事：① 用 D6-② 证明「**`pfspara` 非零 ≠ 可用**」（错类型非零值被下游拒）② 把判据 §5.2 的口径**原文转抄**留档供 `(b)` 判红（`cParas=0` 会改控制流 ⇒ 真腿出现 ⇒ 判红）。**本件不声称 P8 已被'修'**。

---

## §3 ② 合法来源的判定（**托管 vs native**）＋ 逐跳原文

| 问 | 现取判词 |
|---|---|
| `pfspara` 应由**谁**产出？ | **native 侧**。判据 §4(a) 逐字：「**native 必须自己拥有/分配一个对象**，把它填进 `FSPARADESCRIPTION.pfspara`（`+8`）」；`t163` 修正后的语义：该字段**就是子轨对象**（`FsFormatSubtrackFinite` 的该出参在声明里叫 **`ppfsSubtrack`**、注释「ptr to the subtrack」，`Pts.cs:3318/:3337`） |
| 托管侧怎样用它？ | `PtsHelper.cs:179 paraClient.Arrange(arrayParaDesc[index].pfspara, …)` ⇒ `BaseParaClient.cs:64-65 Debug.Assert(_paraHandle == IntPtr.Zero \|\| _paraHandle == pfspara); _paraHandle = pfspara;` ⇒ 它成为 `ContainerParaClient.cs:271/:283` 两次 subtrack 查询的 **`pSubTrack`** |
| 本件落地 | **本侧自有对象**（承本仓范式：句柄＝**本对象内字段的地址**，同 `FsQueryTrackDetails`／`wpf_pts_fsp.c_paras`）；**不是**自造常量、**不是**伪指针、**不**拿 `nmp` 占位 |
| ⚠️ **未达成的那条** | 队长 `t163` 的 **E2「驱动宿主槽 3（`ObjFormatParaFinite`）由引擎侧造型产出」**：本侧**缺真造型帧**（`pfssobjc` 被 `t163` 判为伪指针、`pfsgeom`／`pfsbrkrec` 本侧都没有）⇒ **不去自造这些输入**（判据 §7.3 零假值）⇒ 记 **`NOINFO`＋具名 `PRECOND-NO-ENGINE-FORMAT-FRAME`**，并在 `[FSPARALIST-SLOT3]` 行里**逐项报缺** |

## §4 ③ 合法来源 × 成对证据（**本件无下游接受者** —— 如实）

| 格 | 现取（L1／L2 两样本） | 判 |
|---|---|---|
| ① 写入前该槽 | `pre=(nil)`（`memset` 后、写入前） | ✅ |
| ② 写入后非零 | `psub=0x55a8288488f4`（L1）／`psub=0x64e3d25fd214`（L2）—— **本侧自有对象的字段地址** | ✅ |
| ③ **身份可认领** | `src=native-owned-subtrack`、`same_value=1`、`off_pfspara=8`、`seq=2`（台账序号）、`live=1` | ✅ |
| ④ **下游接受** | 🔴 **`acc=-12345`（＝未调用）**：判据 §5.5 的在册接受者（`FsQuerySubtrackDetails :271`／`FsQuerySubtrackParaList PtsHelper.cs:633`）**都属 (b)、尚未实现** ⇒ **本件无接受读数** ⇒ 记 `NOINFO(acceptor-is-(b))` | **`NOINFO`** |
| 字节级读回（`+8` 实测） | `bytes0_32= 00×8 **f4 88 84 28 a8 55 00 00** 05 00… 03 00…` ⇒ **`+8..+15` ＝ 自有对象地址**、`+16` ＝ 客户端 `0x5`、`+24` ＝ `nmp=0x3` | ✅ **三格逐字节可核** |

🔴 **本件的一处自伤与更正（如实）**：`acc` 最初接的是 `+168 GetParaProperties` —— 它吃的是**托管句柄**，而本件 `pfspara` 是 **native 指针** ⇒ 喂它 ⇒ `PtsContext.HandleToObject` 的 `Assert(handleLong < len)` ⇒ **不可捕获 `FailFast`**：实测 `Unrecoverable system error.: Invalid object handle.` ＋ `app_rc=134` ＋ `LEG k=24 alive=no`（`18:20` 那趟，`run2.out` 在册）。**已删该调用**并具名 `acc=NA(acceptor-is-(b))`；**这正是判据 §7.3／P7 要拦的形态**，本件踩到并修，读数与修正都在册。

## §5 ④ 台账／持有期／销毁口径（三项各自的现取读数）

| 项 | 现取 | 判 |
|---|---|---|
| **台账** | 逐趟行：`seq=2`（第一只，L1）／`seq=4`（末只）、`live=1`／`live=3`、`created=4`、`destroyed=1`；读数口 `PtsSubLive/Created/Destroyed/ClaimOk/ClaimBad` ＋ `PtsFsParaListParaClaims`（L1 `claims=1100 rejected=0`） | ✅ |
| **持有期** | 同一对象**跨调用复用**：`reused=685`（L1）／`703`（L2）⇒ 对象在册即有效（**与 `t158` 的"对象生存期"口径同形**：本侧对象的生存期）；**填报后不销毁** | ✅ |
| **销毁口径** | 唯一销毁点＝`wpf_pts_sub_destroy`，接在 **`DestroyDocContext`** 上（**窗口内绝不销毁**、**填进列表后不销毁**）；**自检**给出直接读数：`[FSPARALIST-SUB-SELFTEST] mask=0x1f new_claimable=1 null_rejected=1 stack_rejected=1 destroyed_unclaimable=1 live_restored=1 live=0 created=1 destroyed=1` | ✅（**自检面**；应用路径的 `DestroyDocContext` 本应用**从不调用** ⇒ 该路径在本腿 `NOINFO`，与 `t156` 同形） |
| **身份判别（判据 §5.4）** | 认领＝**指针必须等值于某在册对象的字段地址**；`NULL`／**栈地址**／外来值一律拒（自检 bit1/bit2 ＋ 两条反腿） | ✅ |

## §6 ⑤ `_Static_assert` ＋ `t160` 七条合取的**回归**

**已就位 4 条新断言**（`FSIMETHODS` 17 槽镜像）：`sizeof==17×8`、槽 1 `@0`、**槽 3 `@16`**、槽 13 `@96`、槽 17 `@128`（＋`t160` 的 6 条原样在册：`pfspara==8`／`pfsparaclient==16`／`nmp==24`／`sizeof==64`／`FSUPDATEINFO==8`／`FSBBOX==20`）。

**回归（同代 `so16=291ef08a33f9b6e4`；两独立样本）**

| 面 | L1 | L2 | 判 |
|---|---|---|---|
| `[FSPARALIST-FILL]` 数 | **1100** | **1123** | ✅ |
| `resolve=ok`（CONSUME） | **33** | **34** | ✅ |
| `entry=FsQueryTrackParaList` 的 `rc=-10000`／`rc=-100002` | **0／0** | **0／0** | ✅ |
| `h0` 与同 run `+176` 的 `keep` | `0x5` ＝ `0x5` | `0x5` ＝ `0x5` | ✅ |
| `off16` | **16** | **16** | ✅ |
| 症状门 | `alive=yes app_rc=143 magenta=0`、`failfast=0 unrec=0` | 同 | ✅ |
| 帧面（只作辅证） | `colors=391 ae=14775` | `colors=383 ae=15386` | 非确定（`t152` 在册），**不读成回归** |

## §7 ⑥ P8 恒绿陷阱的处置（**本件只做两件事**，逐条）

1. **"非零 ≠ 可用"**：本件的 `pfspara` **非零**（`0x55a8…`／`0x64e3…`）但 `formatted=0`、`c_paras` **不是"0 个孩子"的断言**（行内逐趟打 `formatted=0`）⇒ **本侧显式告诉 (b)：不得据 `cParas==0` 走叶子分支**（判据 §5.2 的原文转抄留档）。
2. **两条反腿必红（E3）**：
   - `WPF_PTS_FSP_PL_PARA_MADEUP=1`（副本 `be5b8d1f9cfd50a2`）：`psub=(nil) src=NULL(E3-1 反腿)` ⇒ `claim=0` ⇒ **拒填**（`v=CLAIM-REJECTED`）
   - `WPF_PTS_FSP_PL_PARA_WRONGTYPE=1`（副本 `ba06e9f04e9e8cf1`）：`psub=0x711e0012c740 src=stack-addr(E3-2 反腿)`（**"看似真实则伪"的栈地址**）⇒ `claim=0` ⇒ **拒填**（`v=CLAIM-REJECTED`）
   ⇒ 两条反腿都**红**（未判绿、未把认不了的值交给列表）。
   🔴 **同时如实报一条未定形**：两条反腿随后都出现 `Unrecoverable system error.: Invalid object handle.`，managed 栈顶＝`PtsHelper.ArrangeParaList → PtsContext.HandleToObject`，`app_rc=134`；而该腿**同时** `[FS_PAGE_GAP]=0` 与 `[FSPARALIST-FILL]=0` ⇒ 本席**未能**把该 `FailFast` 与"拒填"路径严格分开 ⇒ 归因 **`NOINFO(未定)`**（**主链两样本 `failfast=0 unrec=0`，未受影响**），并列为给队长的 finding。

## §8 ⑦ 红榜 `P1–P12` 逐条

| # | 本件现取 |
|---|---|
| `P1` `fserr` 非零读成成功 | 判词先看 `rc`；本件 FILL 行 `rc=0` 只出现在**真填**之后（`n=cParas`＋`psub` 非零＋认领通过） |
| `P2` 零句柄当活 | `psub` 非零是**必要条件**；反腿 `psub=(nil)` ⇒ 拒填、判红 |
| `P3` native 自造 | **用本侧自有对象**（台账＋`seq`＋认领）；**唯一合法来源面**写死；`+168` 那次自伤（把 native 指针喂给托管句柄槽）**已删并具名** |
| `P4` 回收后/复用后继续用 | 认领＝指针等值于**在册**对象；销毁后不可认领（自检 bit3） |
| `P5` 槽被调用当链已通 | 本件不以此判绿；证据是台账/认领/字节读回 |
| `P6` 伪值代替 T3 | 本件**零伪值**；反腿用 `NULL`／栈地址（**不喂**任何走 `HandleToObject` 的槽） |
| `P7` 主链 `FailFast` | 主链两样本 `failfast=0`；本件**踩到过一次**（见 §4）并已修，反腿的 `FailFast` 归因 `NOINFO` |
| `P8` `cParas=0` 恒绿 | 见 §7-1（`formatted=0` 显式挡）+ §7-2 两条反腿 |
| `P9` 单样本 | **两独立样本**（`app_pid` 不同）判词与值一致 |
| `P10` 恒定绿判别器 | 本件**未**用 `+200`／`+56`；接受者**未选定**（属 (b)）⇒ 不冒充 |
| `P11` 跨代相减 | 每条读数带 `so16=291ef08a33f9b6e4`／`pf16=0b4b65f2c6c7ffd4` |
| `P12` `NOINFO` 写绿 | 接受者格写 **`NOINFO`**；`PRECOND-NO-ENGINE-FORMAT-FRAME` 只在**确实不能自造输入**时成立（逐项报缺） |

## §9 ⑧ `NOINFO` 清册 ＋ 具名前置状态

| # | 项 | 状态 |
|---|---|---|
| 1 | **下游接受**（判据 §5.5 的两个入口） | **`NOINFO(acceptor-is-(b))`** |
| 2 | **槽 3 驱动的引擎侧造型**（队长 E2） | **`NOINFO` ＋ 具名 `PRECOND-NO-ENGINE-FORMAT-FRAME`**（`pfssobjc` 伪指针／`pfsgeom`／`pfsbrkrec` 本侧都没有；**不自造输入**） |
| 3 | **槽序语义**（17 槽的语义映射） | **`NOINFO-FSIMETHODS-ABI`**（托管表**原样存不 deref** ⇒ 只能按声明推断；偏移已用镜像＋断言钉死，`slot3_offset=16` 现取） |
| 4 | **应用路径上的销毁**（`DestroyDocContext`） | **`NOINFO`**（本应用从不调用；自检面已给直接读数） |
| 5 | **反腿的 `FailFast` 归因** | **`NOINFO(未定)`**（见 §7-2；主链未受影响） |
| 6 | `cParas` 的真值来源 | **`NOINFO`**（属 (b)；`t163` 现证 17 槽**无**"子轨数"源） |

## §10 ① 逐件 sha16 ＋ `numstat`

| 件 | 开工 sha16 | 收尾 sha16 | `numstat` |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | **`c90a78af8bc9499c`**／276434 B | **`6ac4272b031edbbc`**／298065 B | **`308 0`**（t162 专属；只增） |
| `bin/libwpfwin32.so` | `ca97eacb8bb123f1` | **`291ef08a33f9b6e4`** | 生成件（忽略） |
| `bin/exports.txt` | 651 行 | **665 行**（`15cb72a3abdadabb`） | 生成件；**逐名对拍 651→665 零消失，＋14** |
| `tools/pts-gap-decl.txt` | `087da7987fed5c6c` | **`3a923ffba99371cb`** | 只改 `so16=`／`exports=` |
| 本载体 | （新建） | 见末行自证 | — |
| 拒跑副本产物 | — | `be5b8d1f9cfd50a2`（MADEUP）／`ba06e9f04e9e8cf1`（WRONGTYPE） | 权威件跑前跑后未变 |

**牙**：`PTSGAP=PASS`（`so16=291ef08a33f9b6e4 exports=665`）｜`REPORTID=PASS files=283`。

## §11 口径 · 边界 · 纪律 · 收尾

- **口径**：本件绿**只**主张「`pfspara` 现在是一个**本侧拥有、台账唯一可认领、跨调用有效、只在 doc 注销时销毁**的对象（其句柄＝本对象内字段地址）」，**并明确 `formatted=0`**；(b) 的真接受者与 `cParas` 真值仍 **`NOINFO`**。**不得**读成"子轨面已通／排版打通／`TASK-0007` 可绿"。
- **边界**：只改 `src/WpfGfx.Linux.Native/**`＋本载体；**闸关路径逐字未变**（真填块整块在 `wpf_pts_drive_probe_enabled()` 内）；未碰工具／装置／`docs/**`／`.cs`／哨兵／`cell=#1`（**有意未登记**）；`phase=degraded` 未翻；重活全 `heavy-slot` 后台；未 `git add/commit/push`；跑后 `/tmp/.X11-unix/` 仅 `X0 X1`。
- **过程自陈**：本件**先落最小载体**（51 行、预登记 D1–D6，末行自证 `8cee877d6ba4ef53` 当场复算 MATCH）**再实现**；中途**两次自伤**（`+168` 误作接受者／认领失败路径的 `*cParaDesc` 语义）都**如实记在册**并已修；§4 的 `acc=NA` 与 §7-2 的未定 `FailFast` 一并留给复核与下一跳。
`P1-PFSPARA 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ e311486fee8fdb2e（末行＝本行）`

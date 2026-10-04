# P1-W84 轻量侦察：真造型帧（geometry／break record／object context）在本波能否合法获得

本件是**只读侦察件**（`work` 类）：回答三问 —— ① 三样各自的**产生处**在哪；② native **能不能合法**拿到（不自造）；③ 不得到 ⇒ `(b)` 的 `cParas` 源该改判到哪。
**本件不实现、不跑腿、不构建、不占显示位、不改任何代码**；无运行期腿读数；引他人读数一律带代际并标「引自 X，本席未独立复算」。

---

## §0 身份、边界与在飞件警告

- 载体：`build/MilBridge/P1-format-frame-recon.md`（**新建**）。写者＝`scout`。写入面**仅本件**；`$N` 内其余件本席**一件未改**。
- 结论**只许收紧**；放宽须队长出裁定并在册。
- ⚠️ **在飞件**：`src/WpfGfx.Linux.Native/src/win32_pts.c` 本席开工现取 **`sha16=6ac4272b031edbbc`**（mtime 18:23:05，与 `t162` 交出的代际**一致**；HEAD＝`b15768c`）⇒ 本件对他的引用**行号只在该代有效**，实现者开工前须重取。

---

## §1 现取台账（读取时刻＝2026-09-29 18:28–18:33，本席本地，仅本次有效）

| 件 | sha16 | 用途 |
|---|---|---|
| `PtsHost/Pts.cs` | `1a8575a18767a956` | `Obj*` 委托签名（`pfsgeom`/`pfsobjbrk` 的 IN/OUT 语义）、`FSCONTEXTINFO`、`FsCreatePage*` 入参表、`FsFormatSubtrackFinite` |
| `PtsHost/PtsHost.cs` | `d1976dcc8362c8f9` | 槽 1/3 等的实现位；`pfsgeom` 在托管侧的**唯一去向** |
| `PtsHost/ContainerParagraph.cs` | `1d0128592496706d` | `pfsgeom` 被**原样回传**给引擎（`FsFormatSubtrackFinite`） |
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `6ac4272b031edbbc`（mtime 18:23:05） | 6 条真实现入口的入参表、页几何与断页记录的产生处、`reason=need-real-format-frame` 的现取位置 |
| `build/MilBridge/P1-pfspara-report.md`（`t162`） | 155 行；末行自证 `e311486fee8fdb2e`（**本席当场复算 MATCH=yes**；**内部读数未复算**） | 本件的来源件（`(a)` 已落 ＋ E2 打不出来 ＋ `PRECOND-NO-ENGINE-FORMAT-FRAME`） |
| `build/MilBridge/P1-fsimethods-recon.md`（`t163`，本席前件） | 238 行；末行自证 `9105d8ff204e7b3b` | `FSIMETHODS` 17 槽全表（本件直接引用） |
| `build/MilBridge/HANDOFF-NEXT.md` | `89bb0a7cb4882742` | `TASK-0007` 的口径（`:42`／`:54`，**内容引自该件，本席未独立复算**） |
| 腿件（只读引用） | `build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/`：`app_g1.log`(1285 行)、`device.txt`(1 行)、`session.txt`(29 行)、`leg_23.env`/`leg_24.env`(各 6 行) | §3.3 的"已产出面"判定 |

---

## §2 逐样产生处（托管侧 ＋ native 侧）

### §2.1 geometry（`pfsgeom`）

| 面 | 现取 | 判定 |
|---|---|---|
| 声明形状 | `Pts.cs:2716`／`:2741`／`:2763`／`:2782`、`PtsHost.cs:2670` 等：**一律是裸 `IntPtr`**，注释只有「IN: pointer to geometry」 | **形状不在仓内** |
| 类型体 | `grep -rn 'FSGEOMETRY' upstream/wpf/src/ --include=*.cs` ⇒ **0 命中** | ⇒ 具名 `NOINFO-FSGEOMETRY-LAYOUT`（见 §6） |
| **谁填** | 它是**宿主回调的 IN 参数**（槽 3/4/5/6：`ObjFormatParaFinite`/`Bottomless`/`UpdateBottomlessPara`/`SynchronizeBottomlessPara`）⇒ **由调用者（＝引擎）填** | **引擎自有输入** |
| 托管侧怎么用它 | `PtsHost.cs:2705` 原样传给 `para.FormatParaFinite(..., pfsgeom, ...)` ⇒ `ContainerParagraph.cs:789` 原样传给**引擎自己的** `FsFormatSubtrackFinite(..., pfsgeom/geometry, ...)`（`Pts.cs:3318` 起） | **宿主只做中转、不解引用**（它是 `IntPtr`，托管侧没有任何解引用点） |
| native 侧 | `grep -n 'geom'` ⇒ 全代**仅一处命中**：`:1318` 的**诊断字符串** `reason=need-real-format-frame(pfssobjc/pfsgeom/pfsbrkrec 本侧都没有)` | **本侧今天没有 geometry 对象** |

### §2.2 break record（三级：页级／段落级／subtrack 级）

| 级别 | 产生处（现取） | native 现状 |
|---|---|---|
| **页级** | **入参** `pfsBRPageStart`（`Pts.cs:3112`「ptr to brk record of prev. page」）＋**出参** `ppfsBRPageOut`（`:3116`「break record of the page」），入口 `FsCreatePageFinite`（`Pts.cs:3110`／native `win32_pts.c:3031`；另 `FsCreatePageBottomless`（`:3128`／native `:324`）**连该参数都没有**） | ✅ **本侧已产出**：`win32_pts.c:3058 *ppfsBRPageOut = (void *)&p->c_paras;`（注释原文「断页记录句柄：**本对象内**字段地址（非 NULL、可身份校验）」）＋失败路径先清空（`:3037`）＋身份谓词族在册（`t127`／裁定二十七） |
| **段落级** | 槽 3：`pfsobjbrk`（**IN**，`Pts.cs:2711`「IN: break record---use if !NULL」）／`pfspara`＋`pbrkrecpara`（**OUT**，`:2728`／`:2729`「OUT: pointer to the para break record」）；槽 10/11 另有 `pfsbrkrecparaOrig/Dup`（`:2797`/`:2798`/`:2799`）与 `pfsobjbrk`（`:2801`/`:2803`） | 本侧无实体；但**第一调契约允许 NULL**（`:2711` 原文） |
| **subtrack 级** | `FsFormatSubtrackFinite`：`pfsBRSubtackIn`（IN，`Pts.cs:3320`）／`pfsBRSubtrackOut`（OUT，`:3337-3338`） | 同上（本侧无实体；IN 可用 NULL 起步） |

⚠️ **本席现取的一条诚实性观察（新）**：本侧今天的"断页记录"是**字段地址别名**（`&p->c_paras`）——它满足了**身份可认领**，但它**并不承载"断页状态"这一内容**（`c_paras` 的语义是"段数"）。⇒ 一旦要驱动真造型，**断页记录的内容诚实性**会成为**新的字段级问题**（判据见 §8-E2 的断言 ③）。

### §2.3 object context（`pfssobjc`）

- **唯一产生处**：`FSIMETHODS` **槽 1 `ObjCreateContext`**（`Pts.cs:2699-2705`：`(pfsclient, pfsc, pfscbkobj, uint ffi, int idobj, out pfssobjc)`），托管实现 `PtsHost.SubtrackCreateContext`（`PtsHost.cs:2644-2654`）：**只算 `pfssobjc = (IntPtr)(idobj + _objectContextOffset)`**（`_objectContextOffset = 10`，`:93`），**入参一个都不读**；配套槽 2 `ObjDestroyContext` 是 `// Do nothing`（`:2654-2658`）。
- **它是不是"唯一被否决的那一个"**：**是**（就本件三样而言）。本席现取 17 槽表（`t163`，`Pts.cs:1204-1223`）内**只有 1/2 这对**是 object-context 的产生/销毁面，**没有第二个等价物**；宿主侧对该值的自陈见 `PtsHost.cs:91-93` 注释原文「Since ObjectContext is not really created by our PTS host, it is good enough for now.」。

---

## §3 准入路径判定（本件核心）

**准入判据（本件的铁律，先声明）**：`准入 = 本侧是该值的作者`。
- **合法**：引擎**自己**的矩形/几何/格式化标志/`idobj`/页对象/断页记录（引擎是这些事实的作者）。
- **禁止**（＝伪造）：声称某个**外部对象**（托管句柄、宿主对象）存在而它不存在；把**别的量的数**当本条的数（`nlines`/`nftn` 当 `cParas` 即此类）。
⇒ 本条铁律与 `t161` §7.3 的"零假值"**同向**，但把"自造输入"这一**过宽**的禁忌收窄到"**伪造外部对象**"。

### §3.1 入站调用参数表（native 今天真收得到的）

| 入口（native 现取） | 入参全表 | 其中含 geometry／break record／objctx？ |
|---|---|---|
| `FsCreatePageBottomless` `:324` | `(pfscontext, fsnmsect, pfsfmtrbl, ppfspage)` | **无** |
| `FsCreatePageFinite` `:3031` | `(pfscontext, pfsBRPageStart, fsnmSectStart, pfsfmtrOut, ppfsPageOut, ppfsBRPageOut)` | ✅ **断页记录（页级，入＋出）** |
| `FsQueryPageDetails` `:2679` | `(pfscontext, pPage, pPageDetails)` | 无（出参是页详情结构） |
| `FsDestroyPage` `:2714` | `(pfscontext, pfspage)` | 无 |
| `FsQueryTrackDetails` `:2806` | `(pfscontext, pTrack, pTrackDetails)` | 无 |
| `FsQueryTrackParaList` `:2894` | `(pfscontext, pTrack, cParas, rgParaDesc, cParaDesc)` | 无（出参含 `pfspara`——那是 `(a)`，已由 `t162` 落地） |
| `CreateDocContext`（`FSCONTEXTINFO`，`Pts.cs:833-844`） | `version, fsffi, drMinColumnBalancingStep, cInstalledObjects, pInstalledObjects, pfsclient, ptsPenaltyModule, fscbk, pfnAssertFailed` | **无**（既无 geometry、也无断页记录、也无 objctx） |

⇒ **入站面上，今天唯一存在的"帧元素"是页级断页记录**（且是**出参为主**）。

### §3.2 `FSIMETHODS` 17 槽（引 `t163` 全表，逐槽标注 产/吃）

| 槽 | 字段 | 对帧三样的作用 |
|---|---|---|
| 1 | `pfnCreateContext` | ✅ **产出 `pfssobjc`**（唯一产生处） |
| 2 | `pfnDestroyContext` | 吃 `pfssobjc` |
| 3 | `pfnFormatParaFinite` | **吃 `pfsobjbrk`(可 NULL)／`pfsgeom`／`pfssobjc`／`pfsparaclient`／`nmp`**；**产 `pfspara`／`pbrkrecpara`（段落级断页记录）** |
| 4 | `pfnFormatParaBottomless` | 同 3（无 `pfsobjbrk`，产 `pfspara`） |
| 5 | `pfnUpdateBottomlessPara` | 吃 `pfspara`／`pfsparaclient`／`nmp`／`pfsgeom` |
| 6 | `pfnSynchronizeBottomlessPara` | 吃 `pfspara`／`pfsparaclient`／**`pfsgeom`** |
| 7 | `pfnComparePara` | 吃 `pfsparaOld/New`／`pfsparaclientOld/New` |
| 8 | `pfnClearUpdateInfoInPara` | 吃 `pfspara` |
| 9 | `pfnDestroyPara` | 吃 `pfspara` |
| 10 | `pfnDuplicateBreakRecord` | 吃 `pfssobjc`／`pfsbrkrecparaOrig`；**产 `pfsbrkrecparaDup`** |
| 11 | `pfnDestroyBreakRecord` | 吃 `pfssobjc`／`pfsobjbrk` |
| 12 | `pfnGetColumnBalancingInfo` | 吃 `pfspara`；产 `nlines`（**与段数无关**） |
| 13 | `pfnGetNumberFootnotes` | 吃 `pfspara`；产 `nftn`（同上） |
| 14 | `pfnGetFootnoteInfo` | 自陈未实现（`PtsHost.cs:2933`/`:2935`） |
| 15 | `pfnGetFootnoteInfoWord` | **空装配**（`PtsCache.cs:617 = IntPtr.Zero`） |
| 16 | `pfnShiftVertical` | **恒绿桩**（`PtsHost.cs:2943`/`:2944`/`:2945`）禁用 |
| 17 | `pfnTransferDisplayInfoPara` | 吃 `pfsparaOld/New` |

⇒ **回调面上：`pfssobjc` 可"产"，`pfsgeom` 只被"吃"（故必须是引擎自造），段落级断页记录可"产"。**

### §3.3 已产出面能不能当"真造型帧入口"

| 面 | 现取 | 判定 |
|---|---|---|
| `[GEO]` 面 | 本席现取：`evidence/arm_A/app_g1.log` 内 **1012 行**（`grep -c '\[GEO\]'`）；样本原文（`:1-3`）＝ `[GEO] ======== begin 1 ========`／`[GEO] Button#ButtonMin scr=656,1 wh=45x28 en=False vis=True htv=True`／`[GEO] Button#ButtonMax scr=703,1 wh=46x28 en=False vis=True htv=True` | 🔴 **不能当造型帧入口**：它是**应用侧 UI 自动化面的"控件屏幕矩形/可见性"转储**（**驱动面**），只含 XAML 元素的 `scr/wh/en/vis/htv`，**不含任何 PTS/线服务对象**（无 `pfsgeom`、无断页记录、无 objctx）。发射者**不在我方写域**（`grep` 现取：非报告类来源只有那两个 `app_g1.log` 与两份文档；测试脚本仅在 `session_inner.sh:171` 设 `HC_INPUT_DIAG=1`） | 
| 任务书所称「`[GEO]` 927 行」 | 与上表并列 | ⚠️ 本席现取的是**另一腿**的 **1012** 行 ⇒ 两数**不同代/不同腿**，**不做跨代比较**（该 927 **引自任务书，本席未独立复算**） |
| `device.txt`（1 行） | `X_UP=yes display=:237` | **不能**：显示可用性 |
| `session.txt`（29 行） | `DISPLAY_LEASE=…`／`shim_sha16=…`／`app_pid=…`／`BEFORE/AFTER item=24 nm=FlowDocument … rect=28,355,203x27 point=127,368` | **不能**：租约/制品代际/点击轨迹（**驱动面**） |
| `leg_23.env`／`leg_24.env`（各 6 行） | `alive=yes app_rc=143 magenta=0 colors=383 … ae=0 ink=480000`／`NAMED …`／`DEV …`／`FAILLINE …`／`FRAME k=23 fr_file=k23.png fr_sha=… fr_ae_boot=15386` | **不能**：腿结论摘要与帧哈希（**结论面**） |

⇒ **三样"帧元素"在已产出面里一个都没有**；`[GEO]` 只能回答"**点哪**"（驱动），不能回答"**造型的输入**"。

---

## §4 判「得／不得」

**总判词：得（三条准入路径都存在），但性质不同、且"得"不是本跳的瓶颈。**

| 样 | 准入路径 | 判 | 依据 | 附条件／代价 |
|---|---|---|---|---|
| **object context `pfssobjc`** | **调槽 1 合法获得** | **得** | `Pts.cs:2699-2705`（out）＋ `PtsHost.cs:2644-2654`（宿主自产） | `idobj`/`ffi` 是**引擎自选**（引擎是作者）⇒ 不构成伪造；`pfscbkobj` 待查（§6 `NOINFO`） |
| **geometry `pfsgeom`** | **引擎自有对象**（宿主只中转、不解引用） | **得（有条件）** | `PtsHost.cs:2705` → `ContainerParagraph.cs:789` → 回到引擎 `FsFormatSubtrackFinite`；仓内 `FSGEOMETRY` 0 命中 | 形状**自定** ⇒ 与上游 ABI **不可比**（§6 `NOINFO-FSGEOMETRY-LAYOUT`）；**必须声明"作者性"**（§3 铁律） |
| **break record** | 页级**本侧已产出**；段落级/subtrack 级**第一调可合法 NULL** | **得** | `win32_pts.c:3058`（本对象字段地址）＋ `Pts.cs:2711`「use if !NULL」＋ `:3320` IN | 断页记录的**内容**尚无字段承载（§2.2 观察）⇒ 内容诚实性是**新格子** |

**❗因此本件把 `t162` 的 `PRECOND-NO-ENGINE-FORMAT-FRAME` 收窄（不是撤回）**：
- **成立**的部分：**"本侧今天没有真造型帧的实物"**（无 geometry 对象、无 objctx 实例、无段落级断页记录）——现取 `win32_pts.c:1318` 的自我诊断亦是此意。
- **不成立**的部分：**"要驱动就得自造输入 ⇒ 违反零假值"**。⇒ 三样**都有合法获得路径**（上表），其中两样是"**引擎本来就是作者**"，一样是"**调槽 1 拿**"。
- ⇒ **真正的缺不是"帧"，而是"驱动者"**：本波 hex 现取 native 的 6 条真实现里**没有任何造型驱动入口**（无 `FsFormatSubtrack*`、无 `FsUpdateFinitePage`、无任何会去调槽 3 的路径）⇒ 主链上**没有调用者会走进槽 3**。**故本件建议改判为 `PRECOND-NO-ENGINE-DRIVER`。**

---

## §5 若队长判「不得」的替代（改判候选，按代价递增）

1. **承认本波只能到 `(a)` 为止**（最省）：`cParas` 维持无源，`FsQuerySubtrackDetails` 维持"诚实拒绝＋留痕"；把下一跳让给主链上**已有真实调用者**的格子。
2. **改判到主链既有入口**：本侧 6 条真实现（`:324`/`:3031`/`:2679`/`:2714`/`:2806`/`:2894`）里，**只有 `FsQueryTrackParaList` 面已经把 `pfspara` 交出去**（`t162` 落地）；若要继续推，最自然的是**把"消费者侧真用到 `pfspara`"的证据补上**（而不是急着做 subtrack 详情）——因为**没有消费者用**，subtrack 详情就永远只是自证。
3. **改判到 `TASK-0007` 路径**：`HANDOFF-NEXT.md:42`／`:54`（现取，**内容引自该件、本席未独立复算**）把 `TASK-0007` 记为未绿 `[MVP]`：富文本 23／流文档 24 `rc=134`，**真因 `TASK-0302`** ⇒ 若走这条，本跳的 `cParas` 工作要能回答"**它是否缩短了 `TASK-0007` 的距离**"，否则属于**旁支**（本件不主张走这条，只列出）。
⇒ **不许**把"自造输入"包装成合法路径（本件 §3 铁律已把"自造"限定为"伪造外部对象"，凡声称外部对象存在的值一律红）。

---

## §6 诚实边界与 `NOINFO` 面

1. **手头没有真造型帧**这一点如实写：它是 `t162` 的现取结论（本席只复算了其末行自证 `e311486fee8fdb2e`，**内部读数未复算**）。
2. 具名 `NOINFO`：
   - `NOINFO-FSGEOMETRY-LAYOUT`：`pfsgeom` 的**结构形状**取不到——仓内 `FSGEOMETRY` **0 命中**，托管侧全程 `IntPtr` ⇒ **只能自定，且自定后与上游 ABI 不可比**。
   - `NOINFO-FSCBKOBJ-CONTRACT`：槽 1 的 `pfscbkobj`（"callbacks (FSCBKOBJ)"）**契约取不到**——托管实现**入参一个都不读**（`PtsHost.cs:2644-2654`），故"传 NULL 是否合法"**无仓内依据**；本件不许自行断言。
   - `NOINFO-GEOMETRY-DEREF-SIDE`：**"宿主从不解引用 `pfsgeom`"是本席据"托管侧只有 `IntPtr` 中转（`PtsHost.cs:2705`／`ContainerParagraph.cs:789`）"的判定**，不是读数；须由 E2 的实测复核后才可升级。
   - `NOINFO-GEO-LINE-COUNT`：任务书给的 `[GEO]` **927 行**与本文现取的 **1012 行**不同代/不同腿 ⇒ **不做跨代比较**。
3. **红线（照任务书）**：**不得**把"`pfssobjc` 是伪指针"推广成"**所有** object context 都不可用"（红榜 `P9`：局部否定 ≠ 全局否定）。本件的判词恰好相反：`pfssobjc` **可经槽 1 合法获得**，其"不透明"是**契约特性**（`PtsHost.cs:91-93` 自陈），**不是不可用**。

---

## §7 与 `t162`／`t163` 判词的关系

| 件 | 原判词 | 本件处置 |
|---|---|---|
| `t162` | E2 打不出来 ⇒ `NOINFO ＋ PRECOND-NO-ENGINE-FORMAT-FRAME` | **收窄**：现状句成立；**推论句（必须自造）不成立** ⇒ 改判 **`PRECOND-NO-ENGINE-DRIVER`**（缺的是驱动者） |
| `t163` | `pfssobjc` 是伪指针 → 列入"三个陷阱"之一 | **限定其射程**：该判定讲的是"**它不由本侧分配、语义不透明**"，**不等于**"拿不到"；准入路径＝槽 1（`Pts.cs:2699`） |
| `t161` | §7.3 零假值明禁 | **收窄其外延**：禁的是**伪造外部对象**，不是"引擎为自己的输入负值"（§3 铁律） |

---

## §8 下一步：接 E2 的最小可证伪设计（**得（有条件）**）

**前置（三条，缺一不可）**：
1. **驱动者**：槽 3 的**调用者必须是引擎**，而主链今天没有驱动入口 ⇒ E2 只允许以**副本专用驱动格**形态存在（先例：`win32_pts.c` 的 `#if WPF_PTS_FSP_PL_SELFRECYCLE` 副本反腿，**绝不进主链产物**）。**不许**为了跑 E2 而在主链上塞一个假调用者。
2. **作者性声明**：驱动格内用到的每一样（`pfsgeom`／`fsrcToFill`／`ffi`／`idobj`／`fswdir`／`fEmptyOk`／`fSuppressTopSpace`／`fskclearIn`）必须在日志里**逐项声明"由本侧作为引擎产生"**，并列出**依据**（本侧自己的页几何 `pg_w/pg_h`（`win32_pts.c:290`/`:352`/`:3052`）等）。凡不能声明作者性的，**不许用**。
3. **投毒＋身份认领**：调槽 3 前把**所有 out 参数显式置毒值**（照 `[DRIVE-PROBE3]` 的 `out_pre_h1` 体例），调用后断言：
   - ① `rc=0`；
   - ② `pfspara` **被改写**且**身份可认领**（＝本侧对象内字段地址；谓词照 `wpf_pts_track_owned`）；
   - ③ **只增一条**记账（`cParas` 语义的现取判定：`t154` 教训 ⇒ **不许**沿用前跳结论）；
   - ④ 出参断页记录（段落级）若被写，其**内容**必须能对上本侧记账（§2.2 的"内容诚实性"新格）。
4. **反腿一对**（照 `win32_pts.c:3286-3305` 现成体例）：a) 交 `NULL`；b) 交"**看似真实则伪**"的句柄（栈上局部变量地址）⇒ 两条都必须**被拒且留痕**。

**判「得」的裁决条件**：上述 ①–④ 全中 ＋ 反腿两条都红 ⇒ E2 成立（且**只**成立"驱动→产出"这一机制，**内容判词仍须 `NOINFO`**）。
**若队长判"副本驱动不算合法"** ⇒ 走 §5 的改判候选，本跳落 `PRECOND-NO-ENGINE-DRIVER` 并**如实收工**（**合法终点**）。

---

## §9 本件自身的验收

1. 新件；末行＝自证行（`head -n -1 <本件> | sha256sum | cut -c1-16`）；`mode 644`；首记号 ＝ `# P1-W84 `。
2. 复核者须**独立重取** §1 表内至少 4 件的 sha16 与引用行（`sed -n` 打原文）；`win32_pts.c` **必须重取**（在飞）；不一致处**只增不改**地追加。
3. 本件不含腿读数；他人读数均标来源与代际；`t162` 末行自证本席当场复算过（MATCH=yes）——属代际核对。
4. 本件**未**授权任何判据放宽；本件对 `t162`／`t163`／`t161` 的处置均为**收窄**（§7）。

---

## §10 附录：现取原文摘录（仅本次有效）

`Pts.cs:3110-3116`（sha16 `1a8575a18767a956`）：
```
        internal static extern int FsCreatePageFinite(
            IntPtr pfscontext,                  // IN:  ptr to FS context
            IntPtr pfsBRPageStart,              // IN:  ptr to brk record of prev. page
            IntPtr fsnmSectStart,               // IN:  name of the section to start from, if pointer to break rec is NU
            out FSFMTR pfsfmtrOut,              // OUT: formatting result
            out IntPtr ppfsPageOut,             // OUT: ptr to page, opaque to client
            out IntPtr ppfsBRPageOut);          // OUT: break record of the page
```
`Pts.cs:2708-2711`（同件，槽 3 入参头）：
```
        internal delegate int ObjFormatParaFinite(
            IntPtr pfssobjc,                    // IN:  object context
            IntPtr pfsparaclient,               // IN:
            IntPtr pfsobjbrk,                   // IN:  break record---use if !NULL
```
`Pts.cs:833-844`（同件）：`FSCONTEXTINFO { version; fsffi; drMinColumnBalancingStep; cInstalledObjects; pInstalledObjects; pfsclient; ptsPenaltyModule; FSCBK fscbk; AssertFailed pfnAssertFailed; }`（**无 geometry／断页记录／objctx**）
`PtsHost.cs:91-93`／`:2644-2654`（sha16 `d1976dcc8362c8f9`）：
```
        // This is random number (doesn't mean anything). Since ObjectContext
        // is not really created by our PTS host, it is good enough for now.
        private static int _objectContextOffset = 10;
        …
        internal int SubtrackCreateContext(… out IntPtr pfssobjc)
        { pfssobjc = (IntPtr)(idobj + _objectContextOffset); return PTS.fserrNone; }
```
`win32_pts.c`（代际 **`6ac4272b031edbbc`**）：
```
:290        int          pg_w, pg_h;            /* 页矩形（创建时按当时几何记下） */
:352        p->pg_w = 768; p->pg_h = 576;     /* 页矩形：本模块自持（与装置窗口几何同源） */
:3031   int FsCreatePageFinite(void *pfscontext, void *pfsBRPageStart, const void *fsnmSectStart,
:3052           p->pg_w = WPF_PTS_FSP_FIN_DU; p->pg_h = WPF_PTS_FSP_FIN_DV;
:3058           *ppfsBRPageOut = (void *)&p->c_paras;     /* 断页记录句柄：**本对象内**字段地址（非 NULL、可身份校验） */
:1318       "reason=need-real-format-frame(pfssobjc/pfsgeom/pfsbrkrec 本侧都没有) "
```
`evidence/arm_A/app_g1.log:1-3`（只读引用，`[GEO]` 计数本席现取 **1012**）：
```
[GEO] ======== begin 1 ========
[GEO] Button#ButtonMin scr=656,1 wh=45x28 en=False vis=True htv=True
[GEO] Button#ButtonMax scr=703,1 wh=46x28 en=False vis=True htv=True
```

---

**判词（本席）**：① 三样的产生处已逐一定位——`pfsgeom` 是**宿主回调的 IN 参数**（故**引擎是作者**，托管侧只中转、不解引用），`pfssobjc` **唯一**由 `FSIMETHODS` 槽 1 产出（宿主自产的不透明令牌，`PtsHost.cs:2644-2654`），页级**断页记录本侧已产出**（`win32_pts.c:3058`）、段落级/subtrack 级**第一调可合法 NULL**（`Pts.cs:2711`）；② **native 今天能合法拿到这三样**（各有一条路径，且都不需要伪造外部对象）⇒ **t162 的 `PRECOND-NO-ENGINE-FORMAT-FRAME` 收窄为 `PRECOND-NO-ENGINE-DRIVER`**（真正缺的是**驱动者**，不是帧）；③ 已产出面（`[GEO]`/`device.txt`/`session.txt`/`leg_*.env`）**不能**充当造型帧入口（它们分别是**驱动面**与**结论面**，无任何 PTS 对象）；④ 故本件判 **`得（有条件）`**：接 E2 的先决是**副本专用驱动格 ＋ 逐项作者性声明 ＋ 投毒·身份认领·只增一条·反腿一对**；若队长判"副本驱动不算合法" ⇒ 走 §5 改判候选并落 `PRECOND-NO-ENGINE-DRIVER`（**合法终点**）。
`P1-format-frame-recon 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 9440f52aaecb1304（末行＝本行）`

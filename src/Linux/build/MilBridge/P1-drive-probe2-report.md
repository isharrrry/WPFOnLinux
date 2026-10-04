# P1-W71 · 驱动链**第二跳**：`pfnGetFirstPara`(+136) 取 `nmp`（窗内 vs 窗外成对实验）

> **本件是 `t151`（runner）的交付**：执行判据件 `build/MilBridge/P1-drive-probe2-criteria.md`（315 行／`856882db8a8af617…`／末行自证 `ecae0481dbb0b3aa`）—— **先完整读了它的 §1–§8**。
> **边界（硬）**：写域 ＝ `src/WpfGfx.Linux.Native/**` ＋ 本件。**未碰** `build/MilBridge/tools/**`／`docs/**`／任何 `.cs`／两枚哨兵／判据件／`HANDOFF-NEXT.md` 的 `cell=#1`（**队长收口**）⇒ 本件**有意未登记** `cell=#1`。**相位位 `phase=degraded` 未动**；未跑整趟门禁；未 `git add/commit/push`。
> **口径（判据 §7.1 逐字）**：本件绿**只准**读成「**在今天的托管态下，`pfnGetFirstPara`（`+136`）对第一跳交出的 `nms` 返回了一个非零、连调同值、且被下游槽接受（未得 `-100002`）的段落句柄**」；**不得**读成"段落模型已成／排版打通／`pfsparaclient` 可用／三级链已存在／该句柄就是该页文档的第一个段落"。
> **落盘顺序**：先落最小载体（本节 ＋ §1 ＋ §2 ＋ 自报口径行）⇒ 其后**原地追加**读数（§3 起）。

---

## §1 靶心与判据要点（照判据件，不放松）

**唯一候选**：`pfnGetFirstPara`（帧 B `+136`）。三条对照里的另两条在**签名层面**就被排除（`GetNextPara` 入参含 `nmpCur` ⇒ 循环依赖；`GetParaProperties` 吃 `nmp` 吐 `FSPAP` ⇒ 不产句柄，**改用为"下游接受性"判别器**）。

**可达性三跳闭合（现取）**：`Section.cs:234-242` 第一跳 `+80` 产出的就是 `new ContainerParagraph(...)` 的 `.Handle`；`ContainerParagraph.cs:19 : BaseParagraph, ISegment`；`PtsHost.cs:595 HandleToObject(nms) as ISegment` ⇒ 命中。

**成功语义（两种都合法）**：`fserr=0 ∧ fSuccessful=1 ∧ nmp≠0` ⇒ **`FIRSTPARA-HANDLE`**；`fserr=0 ∧ fSuccessful=0 ∧ nmp=0` ⇒ **`FIRSTPARA-ABSENT(by-design)`**（**不得读成失败**）。`-100002`／`-10000`／其它一律非成功。

**最小证据串四格**：① `rc136a=0` ② `fSucc1=1 ∧ nmp1≠0` ③ `rc136b=0 ∧ nmp2=nmp1 ∧ idem136=1` ④ **`rc168≠-100002`**（下游接受）。

**🔴 本件最大的坑（判据 §8.2）**：`-100002` 有**两种成因**，只看 `rc` 分不开 —— (i) 句柄类型不对；(ii) **窗外调用**（`ContainerParagraph.cs:151` 无条件读 `StructuralCache.CurrentFormatContext.IncrementalUpdate`，窗外为 `null` ⇒ NRE 被 `catch` 吞成同一个 `-100002`）⇒ **必须做"窗内 vs 窗外"成对实验**；只拿到一条 ⇒ `NOINFO(成因未分)`。

---

## §2 实现点（纯 native，五处）

| # | 改动 | 说明 |
|---|---|---|
| **A** | 快照下标 `GETFIRSTPARA=12`（`+136`）／`GETPARAPROPERTIES=16`（`+168`）＋ **2 条 `_Static_assert`** | 把判据的偏移钉进编译期（与 `t133`/`t141`/`t146` 同族，**不重复定义常量**） |
| **B** | 两个函数指针 typedef（`get_first_para` 4 参／`get_para_properties` 3 参）＋ 大小断言 | 签名按 `Pts.cs:2102-2106`／`:2124-2127` 原文 |
| **C** | **窗内腿**：在 `wpf_pts_drive_probe` 的 `+80` 之后调 `+136` **两次**（幂等）＋ 把 `nmp1` 喂 `+168`（`FSPAP` = 16 B 栈缓冲）；打 `[DRIVE-PROBE2] … window=in …`；把 `nmSeg1` 缓存进 doc（供窗外腿用**同一个**句柄） | 判据 §2.3 的最小证据串四格 |
| **D** | **窗外腿**：在 `FsDestroyPage` 入口（页拆除在 `using` 窗**关闭之后**）拿**同一个** `nms` 调 `+136` 一次；打 `[DRIVE-PROBE2-OOW] … window=out …` | 判据 §8.2 的成对实验反腿；**"窗外"归类＝代码结构推断**，实验本身即检验 |
| **E** | **T3 模式**（编译期 `WPF_PTS_DRIVE_PROBE2_T3=1`，**只在副本产物**）：喂 **真 `sect`**（`Section : UnmanagedHandle`，**不是** `ISegment`）当 `nms` ⇒ 期望 `-100002` **且可捕获**；＋ 9 个只读口逐名点名 | 判据 §3；**本件不使用任何伪值**（T1/T2 一律 `FailFast`） |

**只读口（9 条，逐名）**：`WpfLinuxWin32_PtsDriveProbe2{Fserr136,Fserr136b,Success136,Nmp136,Idem136,Fserr168,OowFserr,OowCalls,T3Value}`。


---

## §3 同代两样本逐趟读数（`authority_so=db3c9d5c857ff376`，闸开）

```
[DRIVE-PROBE2] where=FsCreatePageBottomless window=in nms136=0x2 t3=0
  rc136a=0 fSucc1=1 nmp1=0x3  rc136b=0 fSucc2=1 nmp2=0x3  idem136=1  rc168=0
  v136=FIRSTPARA-HANDLE  v168=BASE-PARA-ACCEPTED          ← 样本 1 与样本 3 **逐字相同**
[DRIVE-PROBE2-OOW] where=FsQueryTrackParaList window=out nms136=0x2
  rc136=-100002 fSucc=0 nmp=(nil) idem136=- v136=CALLBACK-ERR(-100002) calls=1…N
```

| 样本 | 闸 | `nms136` | `rc136a` | `fSucc1` | `nmp1` | `rc136b` | `nmp2` | `idem136` | `rc168` | **判词** |
|---|---|---|---|---|---|---|---|---|---|---|
| **s1** | on | `0x2` | **0** | **1** | **`0x3`** | **0** | `0x3` | **1** | **0** | **`FIRSTPARA-HANDLE` / `BASE-PARA-ACCEPTED`** |
| **s3** | on | `0x2` | **0** | **1** | **`0x3`** | **0** | `0x3` | **1** | **0** | **同上（判词相同；值也相同）** |

**最小证据串四格（判据 §2.3）——两样本都满足**：① `rc136a=0` ② `fSucc1=1 ∧ nmp1=0x3≠0` ③ `rc136b=0 ∧ nmp2=nmp1 ∧ idem136=1`（⇒ `_firstChild` 已缓存，**幂等**）④ `rc168=0 ≠ -100002`（⇒ 下游**接受**）。
**OOW 腿**：`where=FsQueryTrackParaList`（该入口日志可证被调；本趟 OOW 行数 s1=455／s3=409）⇒ **同一个 `nms=0x2`**、`rc136=-100002`、`fSucc=0`、`nmp=(nil)`。
**症状门（两样本逐格同）**：`alive=yes app_rc=143 magenta=0 colors=383 ink=480000`、`enfe=0 failfast=0 unrec=0 unavail=0`、`DEV shim=db3c9d5c857ff376 pf=c52d9191feb5ba7c`（＝现盘／authority）。

---

## §4 🔴 判别式结论：**`-100002` 的两个成因已被分开**（判据 §8.2 的硬要求达成）

| 腿 | `nms` | 窗口 | `rc136` | 读法 |
|---|---|---|---|---|
| **窗内 · 正腿**（`FsCreatePageBottomless`） | `0x2`（第一跳交出的 `ContainerParagraph`，**类型对**） | **in** | **`0`** ⇒ `nmp=0x3` | 句柄被接受 ⇒ **窗内 + 类型对 ⇒ 成功** |
| **窗外 · 反腿**（`FsQueryTrackParaList`） | **同一个 `0x2`** | **out** | **`-100002`** | **同一个句柄**在窗外被拒 ⇒ **该 `-100002` 的成因＝窗口**（`CurrentFormatContext == null` 引发 NRE 被 catch 吞） |
| **T3 · 反腿**（副本 `.so 5e4fa5651ad14d19`） | `0x1`（**真 `sect`**＝`Section`，**类型不对**） | **in** | **`-100002`** | **窗内**、类型不对 ⇒ 同一个 `rc` ⇒ **该 `-100002` 的成因＝类型** |

⇒ **三格对照把两种成因分开**：`窗内+类型对 = 0`、`窗外+类型对 = -100002`、`窗内+类型不对 = -100002` ⇒ **判据 §8.2 要求的「窗内 vs 窗外」成对实验完成**（**不是** `NOINFO(成因未分)`）。
⚠️ **归类声明（如实）**：`FsCreatePageBottomless` 在窗内是**代码级**确定（`FlowDocumentPage.cs:136` 的 `using(SetDocumentFormatContext)`）；`FsQueryTrackParaList` 的"窗外"是**代码结构推断**（它经 `PtsHelper.ParaListFromTrack` 被列/段落结果查询路径调用）—— **但本件不依赖该推断**：实验已证明**同一句柄在两处的 `rc` 不同**，而 T3 又在窗内复现了同一种 `-100002` ⇒ 二分成立。

---

## §5 T3 腿（判据 §3；**五步配方**＋**值域声明**）

| 步 | 现取 |
|---|---|
| 0 开闸 | `WPF_PTS_DRIVE_PROBE=1`（`[DRIVE-PROBE-ENTER]` 在场＝1） |
| 1 用真 `sect` 调 `+80` | 主链同趟已有 `rc80a=0 nmSeg1=0x2`（第一跳，`t146`/`t148`/`t150` 在册） |
| 2 取"live 错类型"句柄 | **`nms136=0x1`** ＝ 入站 `fsnmsect`（**真 `Section` 句柄**）—— `Section : UnmanagedHandle`（`Section.cs:25`）**不是 `ISegment`**（唯一实现者是 `ContainerParagraph.cs:19`） |
| 3 喂被测槽 | `+136(pfsclient, nms=0x1, &fSucc, &nmp)` **两次** |
| 4 期望/实测 | **`rc136a=rc136b=-100002`、`idem136=1`、`fSucc=0`、`nmp=(nil)`** ⇒ `v136=CALLBACK-ERR(-100002)`；**可捕获**：`app_alive_during=yes`、终态 `app_rc=143`（**我发的 SIGTERM**）、`unrec=0`、`failfast=0` |
| 5 若得 0 | **未发生**（得 `-100002`）⇒ `+136` **不是"任何句柄都行"的槽** |

**🔴 值域声明（判据 §3.2 硬要求）**：**本件不使用任何伪值**（T1 越界／T2 空闲槽都会 `FailFast`，主链禁）。T3 腿所用值 ＝ **`0x1`**，它**就是** `sect` 本身（真句柄）—— 因此不受"伪值必须避开真值域"约束；本件对"真值域"的现取读数为：`sect=0x1`（第一跳入参）、`nmSegment=0x2`（第一跳产出）、`nmp=0x3`（第二跳产出）⇒ **本件从未把这三个值当伪值**。
**副本口径**：T3 腿在**应用副本**（`~w67-work/app` 整目录 `cp -a` 到车道 ＋ 放入车道内编译的 `-DWPF_PTS_DRIVE_PROBE2_T3=1` 产物）上跑；**权威件前后同 sha16**（`db3c9d5c857ff376`）✓。

---

## §6 成对读数 `R1–R9` ＋ 纪律 30 三格

| # | 面 | 现取 |
|---|---|---|
| **R1 闸状态**（跨闸不可比） | 本件读数**全部闸开**；闸关路径在册 `t148`/`t150`（`probe=0`、`reason=gate-off`） |
| **R2 探针读数** | 见 §3（`rc136a/fSucc1/nmp1/rc136b/nmp2/idem136/rc168` ＋ `rc56/rc80` 同趟） |
| **R3 T3 留痕** | T3 腿有 `[DRIVE-PROBE2] … t3=1 …`（`t3lines` 记 0 是 grep 用了 hop-1 的 token 名 `DRIVE-PROBE-T3`，**如实记该 grep 口径错**；T3 在场由 `t3=1` 字段证明） |
| **R4 导出面** | `nm=exports=**620**`（611→620，**＋9 逐名**，**无消失**）；`^Fs=**6**` 不变；`Probe2` 族 9 名 |
| **R5 两页症状面** | 两样本 `alive=yes app_rc=143 magenta=0 colors=383`；`failfast=0 unrec=0` |
| **R6 `ENFE_TOTAL`** | **0**（＋留痕面：`[DRIVE-PROBE2]=1`、`[DRIVE-PROBE2-OOW]=409/455`；`[FS_PAGE_GAP]` 唯一原因仍是 `paraclient-table-not-native`） |
| **R7 `native_gap`** | `NAMED … native_gap=0`（如实给） |
| **R8 同趟性** | 两样本 `DEV shim=db3c9d5c857ff376 pf=c52d9191feb5ba7c` ＝ 现盘 ＝ authority（`sync-applocal --check` `drift=0`） |
| **R9 帧面（只作辅证）** | `fr_sha=ef3fd6765f18f51b`、`fr_ae_boot=15386`（**如实给**；`N1`/`N3`/`N4` 口径不变；⚠️ 按 `t150`：帧面**同代不可复现** ⇒ 只作辅证） |

**纪律 30 三格**：① **进程新鲜度**：两样本均 fresh；调用序（日志现取）＝ doc 上下文 3 个、`FsCreatePageBottomless` 1 窗（`ENTER=1`）、`+80` 2 次、**`+136` 窗内 2 次 ＋ 窗外 409/455 次**、T3 腿 `+136` 2 次；② **关键前置量**：快照 `state=VALUE nonzero=71`（承 `t141`）、`nms=0x1`／`nmSegment=0x2`／`nmp=0x3`、闸开、**窗内**（正腿）；③ **判词**：`rc136a=0`、`idem136=1`、`rc168=0`（正腿）／`-100002`（窗外、T3）。
> ⚠️ **"净腿不崩＝假绿"**：本件证据是 §3 的四格 ＋ §4 的三格对照 ＋ §5 的 T3，**不是**"腿没崩"。

---

## §7 「假进度必红 P1–P8」逐条处置

| # | 假形式 | 本件处置 |
|---|---|---|
| **P1** | `-100002`/`-10000` 读成成功 | 判词**先看 `fserr`**：非 0 一律 `CALLBACK-ERR`/`NOT-IMPLEMENTED`；本件 `rc168=-9999`（未喂）也**不**读成成功 |
| **P2** | 零句柄当活句柄 | 绿的四格**要求 `fSucc1=1 ∧ nmp1≠0`**；by-design 形态单列 `FIRSTPARA-ABSENT(by-design)` |
| **P3** | "被调用"当"链已通" | 判词只到"该槽返回了 X"；`ENTER` 在场**不**构成绿（§3 的四格才是） |
| **P4** | 用伪值代替 T3 | **本件零伪值**；T3 用**真 `sect`**≠`0x2`/`0x3`，且已声明值域（§5）⇒ 反腿**不空转** |
| **P5** | 主链制造 `FailFast` | 主链两样本 `failfast=0 unrec=0`；破坏性试验（T1/T2）**一律不做** |
| **P6** | 单样本当机制 | **两样本**（s1／s3，同代同闸）**判词相同**（值也相同）⇒ 未违反裁定三十八 |
| **P7** | by-design 反过读 | 判词表里 `FIRSTPARA-ABSENT(by-design)` 单列，**不读成失败** |
| **P8** | 恒绿自检 | **T3 腿即其反证**：同一 `+136`、同窗、不同 `nms` ⇒ `-100002`（若判据恒绿，T3 也会"成功"）；另有窗内/窗外对照 |

---

## §8 逐件成对读数

| 件 | 改前 sha16 | 改后 sha16 | `numstat` |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `607dbaf29474c6af` | **`8089fdfea1ac6f23`** | **`138 0`**（**纯增**） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `1eb2ab9aa211f4ac` | **`db3c9d5c857ff376`** | （构建产物） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `565acb646840e894` | **`1b161f0513ffb8a8`** | `9 0`（＋9 名） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `8f79a4b95255661c` | **`67613d98c1d1a7e7`** | `1 1`（只改 `so16=`／`exports=`） |
| 本件载体 | （新建） | 见末行自证 | — |

**新导出逐名（9 条）**：`WpfLinuxWin32_PtsDriveProbe2Fserr136`／`…Fserr136b`／`…Success136`／`…Nmp136`／`…Idem136`／`…Fserr168`／`…OowFserr`／`…OowCalls`／`…T3Value`。
**顺带**：`PTSGAP=PASS`(0)｜`REPORTID=PASS files=276`｜`SYNC-APPLOCAL=PASS drift=0`。

---

## §9 `NOINFO` 清册 ＋ 具名前置状态

| # | 项 | 状态 |
|---|---|---|
| **1** | 该 `nmp`（`0x3`）在表内**确为 `BaseParagraph` 族且是第一个段落**（族内区分） | **`NOINFO`**（`+168` 只证"是 `BaseParagraph` 族"；`ContainerParagraph` 也在该族）⇒ 需托管侧**类型读数**（`PRECOND-DOWNSTREAM-ACCEPTOR`，见下） |
| **2** | `nms→nmp→pfsparaclient` **三级链已存在** | **`NOINFO`**（本件只做第二跳；第三跳＝`+176 pfnCreateParaclient`） |
| **3** | 首次调用**是否真的创建** `_firstChild`（而非命中缓存） | **`NOINFO`**（探针看不到 `_firstChild` 内部状态；只能给"同趟两次同值"） |
| **4** | `-100002` 的**具体异常类型**（本件只做了"成因分类"，未读托管侧 `CallbackException`） | **`NOINFO`**（要托管侧读数） |
| **5** | 段落**内容**是否正确／是否排版出可见结果 | **`NOINFO`**（属页症状面 ＋ `N4` 正身份，今天 `NOINFO`） |
| **6** | `FsQueryTrackParaList` 的"窗外"归类（代码结构推断） | **已由实验旁证**（同一句柄两处 `rc` 不同）但**未独立确证**该处的窗口状态 ⇒ 记"推断 + 实验旁证" |

**具名前置状态**
| # | 前置 | 状态 |
|---|---|---|
| **P0** | `PRECOND-MEASURED-FSCBK-SLOT-OFFSETS`（`+136`/`+168` 绝对偏移） | ✅ **已闭**（本件把 `12`/`16` 下标用 `_Static_assert` 钉死：「`40+12*8==136`」「`40+16*8==168`」） |
| **P1** | `PRECOND-FSCBK-SNAPSHOT-IN-DOC`（承 `t140`） | ✅ **已闭**（`t141` 落地；本件现取 `nonzero=71`） |
| **P2** | **`PRECOND-WINDOW-FORMAT-CONTEXT`（`t149` 新立）** | ✅ **本件现证满足**：窗内正腿 `rc=0`，窗外（同句柄）`-100002` ⇒ 窗是有效变量 |
| **P3** | `PRECOND-LIVE-SECTION-HANDLE`（承 `t140`） | ✅ **已闭**（`sect=0x1` 被 `+80` 接受 ⇒ `rc80=0`） |
| **P4** | **`PRECOND-DOWNSTREAM-ACCEPTOR`（`t149` 新立）** | ⚠️ **部分**：`+168` 可用且**接受了** `nmp`（`rc168=0`），但**它不区分"段落"与"容器段落"** ⇒ 若要更强的身份，需**托管侧类型读数** ⇒ 仍未满足的一半记 `NOINFO`（§9-1） |

---

## §10 齐尾：边界／纪律／收尾牙／口径

- **边界**：改动面 ＝ `src/WpfGfx.Linux.Native/{src/win32_pts.c, bin/exports.txt, tools/pts-gap-decl.txt}` ＋ 本件 ⇒ **全部在写域内**；**未碰** `build/MilBridge/tools/**`／`docs/**`／`samples/**`／任何 `.cs`／两枚哨兵／判据件／`HANDOFF-NEXT.md`；**相位位 `phase=degraded` 未动**；未跑整趟门禁；未 `git add/commit/push`。
- **纪律 28**：改了覆盖面内件 ⇒ 触发成立；派单**明确** `cell=#1` 由**队长收口** ⇒ 如实记「**有意未登记**」。
- **纪律 29**：备份面 ＝ `~/t123-runner/bak/win32_pts.c.pre-t151`；T3 产物只在车道（`t151/t3so`）；**权威件前后同 sha16**；无 `cp -p` 回拷。
- **纪律 30／显示位／进程**：重活（构建 ×2、两样本腿、T3 副本腿）全部 `heavy-slot` **后台**；显示位 `:232`／`:236`／`:238`（**每样本独占号** —— 承 `t150` 的教训：同号连跑会被闸判 `display-occupied`；本件 s2 正是被该闸拒过一次，已重跑为 s3）；`/tmp/.X11-unix/` 现取仅 `X0`/`X1`；未用 `pkill`／`pgrep -f`。
- **资源线**：`MemAvailable 4228152 kB`、`SwapFree 1390588 kB`（另见起点 4.1 GB）⇒ 未越停手线。
- **收尾牙（现取）**：`PTSGAP=PASS`(0)｜`REPORTID=PASS files=276`(0)｜`SYNC-APPLOCAL=PASS drift=0`(0)｜`HANDOFF_MV=DIVERGED`（预期，`cell=#1` 由队长收口）｜`SSC=FAIL`（`WIN32SHIM` 哨兵陈旧，**哨兵由队长写**）。
- **口径（判据 §7.1 逐字）**：本件绿**只准**读成「**在今天的托管态下，`pfnGetFirstPara`（`+136`）对第一跳交出的 `nms` 返回了一个非零、连调同值、且被下游槽接受（未得 `-100002`）的段落句柄**」；**不得**读成"段落模型已成／排版打通／`pfsparaclient` 可用／三级链已存在／该句柄就是该页文档的第一个段落"。

---

## §11 R1–R9 **逐格现取数值**（可核；每条都带闸状态）

| # | 面 | s1 现取 | s3 现取 | 判定 |
|---|---|---|---|---|
| **R1** | 闸状态 | `[DRIVE-PROBE-ENTER]=1`；`[DRIVE-PROBE-SKIP]=2`（**全为** `reason=budget-exhausted`） | 同（`ENTER=1`／`SKIP=2`／`budget-exhausted`） | **闸开**（`WPF_PTS_DRIVE_PROBE=1`）；窗预算 `N=1` ⇒ 第一窗用掉后其余窗 `budget-exhausted`（**预期**，非异常）。闸关对照在册 `t148`/`t150`（`reason=gate-off`） |
| **R2** | 探针读数（**逐字**） | `[DRIVE-PROBE] where=FsCreatePageBottomless nms=0x1 pfsclient=0x1 slot56=0x7eda0071ac28 slot80=0x7eda0071ac58 fake=0 t3mode=0 rc56a=0 fSuccess1=0 nmsNext1=(nil) rc56b=0 fSuccess2=0 nmsNext2=(nil) idem56=1 rc80a=0 nmSeg1=0x2 rc80b=0 nmSeg2=0x2 idem80=1 v56=NEXTSECTION-ABSENT(by-design) v80=MAINTEXTSEG-LIVE-HANDLE` | 同，仅 `slot56=0x7f73bd84ac28 slot80=0x7f73bd84ac58`（ASLR） | 第一跳面与 `t146`/`t148`/`t150` 同形；第二跳面见 §3（含 `slot136=`／`slot168=`） |
| **R3** | T3 留痕 | —（正腿 `t3=0`） | T3 副本腿：`[DRIVE-PROBE2] … nms136=0x1 t3=1 … v136=CALLBACK-ERR(-100002)` | **在场**；⚠️ 判据 §5 R3 示例 token 名写作 `[DRIVE-PROBE-T3]`，**本件实现里 T3 由 `[DRIVE-PROBE2]` 行内字段 `t3=1` 标记**（字段名由实现件写死）⇒ **按 `t3=1` 认在场**，并如实记该 token 名与判据示例**不同名** |
| **R4** | 导出面 | `nm -D --defined-only \| wc -l` ＝ **620** ＝ `wc -l exports.txt`（`T=617`＋`B=3`）；`^Fs=`＝**6**；`PtsDriveProbe2` 族＝**9** | 同 | **相等**；611→620 **＋9 逐名**（§8），**无消失**（逐名比对） |
| **R5** | 两页症状面 | `LEG k=23 alive=yes app_rc=143 magenta=0 colors=383 ns=RichTextBoxDemo ae=0 ink=480000`；`LEG k=24 … ns=FlowDocumentDemo ae=15386`；`NAMED managed_unavail=0 native_gap=0 native_err=-`；`FAILLINE k=23/24 failfast=0 unrec=0` | 同（`ns`／`colors`／`ae` 逐格相同） | 满足（`app_rc=143` ＝ 我发的 SIGTERM；`failfast=0 unrec=0`） |
| **R6** | `ENFE_TOTAL` | `grep -c 'Unable to find an entry point named'` ＝ **0**；留痕面 `[DRIVE-PROBE2]=1`／`[DRIVE-PROBE2-OOW]=455`／`[FS_PAGE_GAP]=1164` | **0**；`[DRIVE-PROBE2]=1`／`-OOW=409`／`[FS_PAGE_GAP]=1106` | 全绿；`[FS_PAGE_GAP]` 逐行皆为 `rc=-10000 reason=paraclient-table-not-native entry=FsQueryTrackParaList`（**唯一原因未变**；两样本计数不同＝页面枚举次数不同，**不是新面**） |
| **R7** | `native_gap` | `NAMED … native_gap=0` | 同 | 如实给，**未为凑数制造非零** |
| **R8** | 同趟性 | `session.txt`：`shim_sha16=db3c9d5c857ff376`／`pf_sha16=c52d9191feb5ba7c`；`five_pre`：`libwpfwin32.so=db3c9d5c857ff376 wpfgfx_cor3.so=941e69902d82ef02 PresentationCore.dll=02f158868aa99df4 PresentationFramework.dll=c52d9191feb5ba7c WindowsBase.dll=9e860cbeecb352e1`；`DEV x_up=yes five_stable=yes shim=… pf=…` | 逐值相同 | **四值同（＝现盘）**；**未**拿 `legs=2/2` 当同趟证据 |
| **R9** | 帧面（**只作辅证**） | `FRAME k=23/24 fr_sha=ef3fd6765f18f51b fr_lsha=ef3fd6765f18f51b fr_ae_boot=15386` | 同 | 如实给；`N1`/`N3`/`N4` 口径**不变**；⚠️ 承 `t150`：帧面**同代不可复现** ⇒ **只作辅证**，本件任何判词**不依赖** `fr_sha` |

**显示位（承 `t150`：每样本独占号）**：s1 `DISPLAY_LEASE=official-caller-owned display=:232 xvfb_pid=3705242 owner_pid=3704656`；s3 `… display=:236 xvfb_pid=3711919 owner_pid=3711300`；几何 `1280x1024x24`。**s2 曾被显示位闸拒**（`display-occupied`，剩 `:233` 的上一趟 `Xvfb` 未退）⇒ **已重跑为 s3**（如实记：这是"样本数悄悄变少"这一风险的现场实例）。

**收尾牙（现取，真名）**
```
pts-gap-count-check.sh          → PTSGAP=PASS tool=90 dead=11 artifact=1 ops=78 impl=81 so16=db3c9d5c857ff376 exports=620   rc=0
report-id-domain-check.sh       → REPORTID=PASS files=276 ids=2208 declared=224                                                        rc=0
sync-applocal.sh --check ~/w67-work/app → SYNC-APPLOCAL=PASS items=5 ok=5 drift=0 noauth=0 same=0                                      rc=0
handoff-machine-values-check.sh → HANDOFF_MV=DIVERGED cells=9 equal=7 manual=1 mismatch=1 uncomparable=0 reasons=,#1:covered-file-changed-since-ts
                                  HANDOFF_MV_NOTE lane-activity=0                                                                        rc=0
SSC（哨兵一致性）                → FAIL：`WIN32SHIM` 哨兵陈旧（仍指旧 so16），哨兵**由队长写** ⇒ 我方**不改**（越域即停手）
```
⚠️ **口径自纠**：我在 §10 里写的 `pts-gap-domain-check.sh` 是**错名**（该脚本不存在）；真名是 `pts-gap-count-check.sh`，上表已给真名与真读数。

---

## §12 收尾必交 ①–⑧ 对照 ＋ **各腿终止形态**

| 必交项 | 落在 | 结论 |
|---|---|---|
| ① 逐件 sha16 ＋ `numstat` | §8 | 四件成对给；`win32_pts.c` `138 0` **纯增** |
| ② **窗内 vs 窗外**成对 + `NOINFO(成因未分)` 判定 | §3／§4 | **不落 `NOINFO(成因未分)`**：三格对照把两成因分开（见 §4） |
| ③ `+136` 最小证据串四格（含 `idem136`）＋ 下游接受性（带射程声明） | §3／§6 | 四格全中；`+168` 射程＝**仅"是 `BaseParagraph` 族"** |
| ④ ≥2 样本判词一致性表 | §3／§11 | s1＝s3（**判词同，值也同**） |
| ⑤ T3 五步逐腿读数 ＋ 伪值域声明 | §5 | 五步逐格给；**值域声明：本件零伪值，T3 用真 `sect=0x1`** |
| ⑥ `nm` 逐名 ＋ 症状门逐格 | §8／§11 | `620`／`^Fs=6`／＋9 无消失；症状门两样本逐格同 |
| ⑦ 逐条 `NOINFO` ＋ 具名前置状态 | §9 | 6 条 `NOINFO` ＋ `P0–P4`（`P2` 本件**现证满足**；`P4` **部分**） |
| ⑧ 口径（逐字） | §10 | 已逐字给，禁读清单同列 |

**各腿终止形态（判据 ② 要求）**

| 腿 | 入口 | 窗 | 终止形态 | 读数 |
|---|---|---|---|---|
| 正腿（s1／s3） | `FsCreatePageBottomless` | **in** | 应用**跑满 200s 预算**后由**我**发 `SIGTERM` ⇒ `app_rc=143`；**非**崩溃、**非** `134/139`、`failfast=0 unrec=0`；两页症状面全绿 | `rc136a=0 nmp1=0x3 idem136=1 rc168=0` |
| 反腿·窗外（s1／s3 同趟，**同进程**） | `FsQueryTrackParaList` | **out** | 同趟内联触发（`-OOW` 行 455／409 次），**不额外起进程**；随后同正腿一起被 `SIGTERM` | `rc136=-100002 fSucc=0 nmp=(nil) v136=CALLBACK-ERR(-100002)` |
| 反腿·T3（副本） | `FsCreatePageBottomless`（窗内） | **in** | 应用跑完后由**我**发 `SIGTERM` ⇒ `app_rc=143`；`unrec=0 failfast=0`；`app_alive_during=yes` ⇒ **`-100002` 可捕获，未 `FailFast`** | `rc136a=rc136b=-100002 idem136=1 fSucc=0 nmp=(nil) rc168=-9999 v168=NO-NMP(未喂)` |

> **注**：反腿没有独立进程 ⇒ 本件对"窗外"的**过程证据**是"—OOW 行在 `FsQueryTrackParaList` 入口在场" ＋ "同句柄窗内 `0` / 窗外 `-100002`"；`FsQueryTrackParaList` 的窗口状态是**代码结构推断**（已在 §4 声明，且**本件不依赖该推断**）。
`P1-DRIVE-PROBE2 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ d7f98875343d4e16（末行＝本行）`

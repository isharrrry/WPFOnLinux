# P1-W8-STEP4-VERIFY（`t111` 独立复核 · W8 第四步「`CreateDocContext` 真实现」· `t110` 的件）

> **本席只读仓树、只写本件。** 对拍标准 ＝ **先写好的判据件** `build/MilBridge/P1-w8-step4-criteria.md`（**`833fe885f1411a04`**／409 行，本席现取；其自证行 `7040687d9bbea1f0` 未复算）；队长裁定 ＝ `build/MilBridge/P1-ptsname-result.md`（`82d575c07634485f`）§8 的十二／十二补／十三／十四。
> **复核对象** ＝ `t110` 的**在飞产出**（`HEAD=52c509a`；`porcelain` 现取显示其件多为 `M`／`??`，**提交归队长**）：`src/WpfGfx.Linux.Native/src/win32_pts.c` **`ec5c877c897d2b7f`**（mtime `02:47:21`）｜`libwpfwin32.so` **`a131ea4e6f5cc4f5`**（**仓内＋部署件同值**，`02:47:39`）｜`exports.txt` `b1996a77bfbf869d`（**572** 行）｜载体 `build/MilBridge/P1-w8-step4-report.md` `baaadb2b673c577c`（mtime `02:50:19`）。托管件 `PtsCache.Linux.cs` `ae43cef7f9a84aa6`／Release＝部署件 `2988f5154ecac5dd`（`t109` 那条车道，本步未动）。**判据工具**：`pts-pages-guard.sh` `e9688aaa11a1b9f4`（`t106` 改过，本席现取）、`pts-gap-count-check.sh`（现取 `sha16` 随手记）。
> ⏪ **落盘期间位移（只增不改，如实追加；`ts=2026-09-29 02:54:39.680000755 +0800`）**：队长裁定件 `build/MilBridge/P1-ptsname-result.md` 在本席读取（`02:51:39`，读到 `82d575c07634485f`）之后**已被改写**为 **`3992ffc8a7e4cb00`** ⇒ 本件引用的裁定**文字**以 `README`/`HANDOFF` 里的**同一裁定句**为准；`t110` 的四个件与判据件 `833fe885f1411a04` **未动**。
> **仪器全部本席自造、仓外、零构建**：`python3`＋`ctypes` 直读现盘 `.so`（`CreateDocContext`／`DestroyDocContext`／`PtsDoc*` 只读口／`PtsJmpProbe`／`PtsJmpProbePtr`／自检／`mmap(PROT_NONE)` 夹具）；判据侧只跑**纯读**自检器；反腿一律在**仓外副本文档**上跑。

---

## §A 靶心达标面（正面判定）＝ **成立**

**判据 C3／C4／C8 的三条面，本席**分开**现取（定名只按台账面）**：

| 面 | 现取读数（本席 `grep`，`evidence/app_g1.log` `eeb96339eebd35a6`） |
|---|---|
| **台账面**（定名唯一依据，`^PTS_GAP entry=`） | **0 行**（before ＝ 2 行：`seq=5 CreateDocContext` ＋ `seq=6 LoDisposePenaltyModule`）⇒ `CreateDocContext` **1 → 0**，且**一个缺口都没被打印** |
| **托管面**（只作粗证，`[PTS-UNAVAILABLE]`） | **0 行**（before ＝ 2 行）⇒ `entry=unknown` 亦 **0** |
| **stub 面（C8）** | `grep -c 'return wpf_pts_gap("CreateDocContext")'` ＝ **0**（before ＝ 1）；`DestroyDocContext` ＝ **0**（**已升级为真实现**，与 C5 声明需一致）；`LoDisposePenaltyModule` ＝ **1** |
| **构建面（C1）** | `nm -D --defined-only \| grep -c .` ＝ **572** ＝ `exports.txt` 行数 **572**（相等 ∧ ≥567）；`.so` `sha16 a131ea4e6f5cc4f5` ≠ before `a2de5ff2b667f33f`；**新增 7 名逐名点名**（vs `t103` 期备份）：`WpfLinuxWin32_PtsDocCreates`／`…PtsDocDestroys`／`…PtsDocFieldAt`／`…PtsDocLive`／`…PtsDocRejected`／`…PtsPenaltyInternalGets`／`…PtsPenaltyInternalHandleAt`（**消失 0 个**） |
| **缺口面（C2）** | `check-shim-coverage.py --tier mapped` 现取 `rc=0`、**`[PresentationNative_cor3.dll] 96 条`**（＝ before，**不变**）；**两个候选（`CreateDocContext`／`DestroyDocContext`）在该面命中 0** |
| **探针前沿（C3）** | `pts-gap-count-check.sh`（工具件 `920326e9242f5fdd`）现取 `rc=0`：**`PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=87 so16=a131ea4e6f5cc4f5 exports=572 root=…`**；`PTSGAP_FRONTIER before=LoCreateContext@3 **after=@0** carrier_sha16=eeb96339eebd35a6 carrier_mtime=2026-09-29 02:48:33.596321283 ts=2026-09-29 02:54:16.792996226`；**`PTSGAP_FRONTIER_STATE=UNNAMED`（工具原文：「载体里**没有具名前沿**…**这不是绿**」）** ⇒ **探针脸 `after=` 空、且自报 UNNAMED** ⇒ 该脸**不构成"具名前进"证据**（只说明它 ≠ `CreateDocContext`）；`PTSGAP_CITED=PASS refs=1 strict=1`、`PTSGAP_HISTORICAL=n=1` |

**「链上真的离开了缺口路径」的独立判据（本席自证，不靠探针脸、也不靠托管面）**：
1. 台账面 **0 行** ⇒ `wpf_pts_gap("CreateDocContext")` 在整趟里**一次都没被调用**（该 stub 是唯一会给它打行的路径）✓；
2. 崩溃栈（本席现取，`app_g1.log` 全文 **`DocContext` 命中 0 次**）显示进程已经跑到 **`FlowDocumentFormatter.Format` ← `FlowDocumentView.MeasureOverride` ← `UIElement.Measure`** —— 这条链**只有拿到真 PTS 上下文之后才可能被走到**（before：`:548 PTS.Validate(CreateDocContext)` 必抛 ⇒ 毒池项清除 ⇒ 页级占位）✓；
3. 托管面 0 行 ⇒ 页级占位**没有再画**（before 的 2 行就是画占位时打的）✓。
⇒ **靶心达标面 ＝ 成立**（`CreateDocContext` 真的不再是缺口；页级占位消失为真）。**⚠️ 反过读**：这**不**等于"两页真排版"——本趟 `leg_24` 是**崩溃腿**（见 §B）。

## §B C6 红面（红面判定）＝ **归因成立**（字体族 `FailFast`，与本步实现**无因果**）

- **现场（本席现取）**：`leg_24.env`（`9c229380a3659c01`）：`LEG k=24 alive=no app_rc=134 magenta=0 colors=1 ns=HandyControlDemo.UserControl.PracticalDemo ae=480000 ink=0`；`NAMED managed_unavail=0 err=- native_gap=0 native_err=-`；`DEV … shim=a131ea4e6f5cc4f5 pf=2988f5154ecac5dd`。`session.txt`：`CLICK k=24 alive=no … fatal=2 unh=0`、`c4_unrecoverable=796`、`alive_after_seq=no`、`app_pid` 被 `timeout` 记 "已中止"。
- **崩溃栈（本席逐帧现取，`app_g1.log:797-812`）**：`System.Environment.FailFast` ← **`MS.Internal.Invariant.FailFast`** ← **`System.Windows.Media.FontFamily.get_FirstFontFamily()`** ← `FontFamily.get_LineSpacing()` ← `MS.Internal.Text.DynamicPropertyReader.GetLineHeightValue` ← `MS.Internal.Documents.FlowDocumentFormatter.ComputePageMargin()` ← **`FlowDocumentFormatter.Format`** ← `FlowDocumentView.MeasureOverride` ← … ⇒ **字体族**（`get_FirstFontFamily` 的 `Invariant.FailFast`），**不是本步的那一族**。
- **因果判据（三条）**：① 崩溃栈里 **`CreateDocContext`／`DestroyDocContext` 帧 0 个**（全文 `DocContext` 命中 0）；② 崩点在**托管字体栈**，本步改的**全部在 `src/WpfGfx.Linux.Native/**`**（我只看到 `win32_pts.c` 一族的改动面）⇒ 二者**无调用关系**、无共享状态；③ 该字体栈缺陷**早在册**（`docs/ROUTES.md` 逐字点名，本席现取命中在位）。
  ⇒ **C6 红面归因 ＝ 成立**：这条 `rc=134` 是**另一族的阻断性缺陷**，**不是**本步实现回归；`FailFast` 不可捕获（`Invariant` 走 `Environment.FailFast`，绕过 `DispatcherUnhandledException`）⇒ 腿必然 `alive=no`。
- **两页成对（现取）**：`leg_23` 仍是**上一代**（`shim=a2de5ff2b667f33f`，`alive=yes app_rc=143 magenta=49923`）｜`leg_24` 是本代（崩）。⇒ **只有一腿换代** ⇒ 两腿不是同趟的一对（见 ② 的 C7）。
- **守卫（本席现取，`rc=1`）**：`PTS_G10_NAME=PASS form=unnamed reason=frontier-unnamed`（具名面已空 ⇒ 形态通过）｜**`PTS_GUARD=FAIL legs=2/2 fails=leg24-not-alive(alive=no),leg24-abort(app_rc=134),leg24-placeholder-missing(magenta=0<20000),leg24-named-line(missing-or-err=-) cannot=leg24(ns=HandyControlDemo.UserControl.PracticalDemo≠HandyControlDemo.UserControl.FlowDocumentDemo) diag=leg24-colors-out-of-band=1 direction=in-file phase=degraded`** ⇒ **C6 的"不劣化"面判据端就是红**，且红点**逐条点名**（`leg24-abort(app_rc=134)` 与我 §B 的归因同一现场）。

## ① 诚实性（第二实现直读）＝ **成立**，但**点出两处**（`F-1`／`O-1`）

| 面 | 本席现取读数 |
|---|---|
| 两次调用绑定 | `CreateDocContext(s1,&h1)`／`(s2,&h2)` ⇒ `rc=0/0`，`h1=0x6278aae73330` ≠ `h2=0x6278aae0cd40`（毒值 `0x91/0x92` 被覆写） |
| **入参结构只读（形状约束）** | 64 B 入参缓冲 **调用前后逐字节相同**（`SHAPE 入参结构未被改写=True`）⇒ 是**逐字段按真实类型读**（`b+0/4/12/16/24/32`，见源码现取），**不是整块 `memcpy`**，也没有回写 ✓ |
| **字段读回（C9）** | `PtsDocFieldAt(0,i)`：`i=0..2` ＝ `0x11111111/0x22222222/0x33333333`（＝ 我传入的 `version/fsffi/cInstalledObjects`）✓；`i=4/5` ＝ `0x4444…/0x5555…`（＝ 我传入的 `pInstalledObjects/pfsclient`）✓；**`i=3` 是另一个量（指数量级，非我传入值）** ⇒ 端口的下标映射与托管侧结构字段序**不完全对齐**（见 `O-1`）。⇒ 判据 C9"至少两项"**满足**（我核到 5 项逐项相等） |
| 镜像对拍 | `PtsJmpProbe("CreateDocContext", s1, …)` ⇒ `rc=1`、`addr_ok=1`；**镜里 `int` 域 `a0..a3` ＝ `version/fsffi/cInstalled/0`（指针未被塞进 `int`）**；`PtsJmpProbePtr(...)` ⇒ `rc=1`、`ptr0 == h1`、`ptr1 == 入参结构地址` ✓ |
| 拒绝面 | `fscontextinfo=NULL` ⇒ `-10000` 且出参清空 ✓；`pfscontext=NULL` ⇒ `-10000` ✓；`DestroyDocContext(NULL/未知/重复)` ⇒ 全 `-10000` ✓ |
| **`PROT_NONE` 入参页** | **🔴 进程段错误**（`timeout 60 python3 pn.py` ⇒ shell 记 `段错误`、退出码 **139**；夹具在调用前已打印 `BEFORE_CALL` 但**调用内**死亡）⇒ **非 NULL 而不可读的入参指针会被 deref 并崩**（`F-1`） |
| 计数与调用序 | `PtsDocLive/Creates/Destroys/Rejected` ＝ `2/2/0/2`（两次成功创建 ＋ 两次 NULL 拒绝）逐项吻合；`DestroyDocContext(h1) ⇒ rc=0`、`live=1`、`destroys=1`、重复/未知/NULL ⇒ `-10000`、`rej` 递增 ✓ |
| 「假装成功」 | **构造不出**：`rc=0` 只在写盘链末；每次 `rc=0` 都同时满足"出参非 NULL ∧ 是本次 `calloc` 的对象 ∧ 与镜像 `ptr0` 相等 ∧ 入参字段逐项读回相等"；`NULL` 入参走拒绝支并清空出参 |

## ② C1–C10 逐条（本席自算）

- **C1 成立**：`nm`＝`exports`＝**572**，`.so` 换代，新增 7 名逐名点名、消失 0（见 §A 表）。
- **C2 成立（按判据写死的"按实际归因、不硬凑"）**：`check-shim-coverage.py --tier mapped` 现取 **`[PresentationNative_cor3.dll] 96 条`**（＝ before，**不变**）；`CreateDocContext`／`DestroyDocContext` 在该面命中 **0** ⇒ **纯行为补全、不动缺口面**。
- **C3（字面成立，但**该面为 `UNNAMED`、不构成具名前进证据**）**：`rc=0`；`PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=87 so16=a131ea4e6f5cc4f5 exports=572`（`so16` ＝现盘 `.so` ✓；`impl 89→87` 属 `t110` 的 STUB/账目同趟更新，本席只记读数）；`PTSGAP_FRONTIER before=LoCreateContext@3 **after=@0**`（**空名**）＋ `PTSGAP_FRONTIER_STATE=**UNNAMED**`；`carrier_sha16=eeb96339eebd35a6` ＝ 现取 `app_g1.log` ✓（同趟）。⇒ 判据的"`after ≠ CreateDocContext` ∧ `STATE=` 行在位"**字面满足**，但工具自报"**这不是绿**"⇒ 本席按判据自己写死的反过读**只把它当探针脸读数**；**"链上离开"另由 §A 的台账面独立判** ✓。
- **C4 成立（台账口径）**：台账面 **0 行**（before 2 行）⇒ `CreateDocContext` 行数与计数**降到 0**（最理想形态）；托管面**如实记录为 0 行**并**明写**"多缺口态下该面会指错人 ⇒ 不作定名依据"；`unknown` **不增**（0→0）。**本席未使用混读直方图**（判据红线）。
- **C5 成立**：`nm … grep -cx DestroyDocContext` ＝ **1**、`LoDisposePenaltyModule` ＝ **1**（都未回退）；**二选一声明**（我现取对拍）：`DestroyDocContext` **升级为真实现**（stub 字面 0、`destroy` 真释放并 `free`、重复/未知被拒）｜`LoDisposePenaltyModule` **维持诚实 stub**（字面 1、`ctypes` 实测返 `-10000`、不 deref）。**次序约束**：源码/注释逐字 `DestroyDocContext → TextPenaltyModule.Dispose`（本席现取该注释在位）；腿证据里**没有**反序证据（本趟腿没走到收尾面，见 C5③）。
- **C6 见 §B**：`alive`／`app_rc`／`magenta≥20000`／`shim=` 各面中，`leg_24` **`alive=no app_rc=134 magenta=0`** ⇒ **不劣化面不成立**（红面），归因成立；`native_gap` 按实际归因（见 ⑥）。
- **C7 同趟性（内容口径）＝ **不成立**（本席现取）**：现盘 `.so` ＝ `a131ea4e6f5cc4f5` ＝ `leg_24.env` 的 `DEV shim` ✓，但 **`leg_23.env` 仍是上一代 `a2de5ff2b667f33f`** ⇒ **两腿不是同一代**（`leg_23` 未换代）；且 `carrier_sha16` ＝ `app_g1.log` ✓（`eeb96339eebd35a6`）。⇒ "三者逐位相同"**只在 k=24 这一腿上成立**，`leg_23` 那一路**不同趟** ⇒ 本条**判不成立并点名**（这也是 §B 两页对比只能是"上代 vs 本代"的原因）。
- **C8 成立**：`CreateDocContext=0` ✓；`DestroyDocContext=0`（与 C5 声明"已升级"**一致**）；`LoDisposePenaltyModule=1`（与声明"未升级"一致）。
- **C9 成立**：见 ① 表（两次 `rc=0/0`、两句柄不同、**5 个字段逐项读回相等**、两个 NULL 拒绝非 0）。
- **C10 成立（认两种形态）**：新具名（`CreateDocContext`）—— 形态① `EntryPoint="CreateDocContext"` 现取 **0**（事实）；**形态② 命中**：`Pts.cs:3091 internal static extern int CreateDocContext(`，其上 `[DllImport(DllImport.PresentationNative)]` **无 `EntryPoint`** ⇒ 回溯成立 ✓（`Pts.cs` 的 `DllImport` 行 73、`EntryPoint` 0 次，本席现取同意判据的硬事实）。

## ③ C6 红面的独立归因（不靠"看起来像"）

见 §B 的三条判据。补充两条**本席自算**的二值读数：
- **`DestroyDocContext` 到底走到没走到（C5③）**：**在册腿证据里没有任何 `doc_*` 读数**（`grep 'doc_des\\|doc_live' evidence/*` 现取 **0**）⇒ **腿面 = `NOINFO`（没有机器读数）**；**本席进程面**：`DestroyDocContext` 真实现已就位且 `destroys` 计数在工作（我实测 `destroys=1`）⇒ "**本步把它变成了可达且可用**"成立，而"**腿里实际走到了没有**"**没有读数**（不是失败，是这一格本趟没打开/没登记）。
- **`doc_des=` 现取**：报表串里**在位**（`doc_live=%d doc_sets=%d doc_rej=%d doc_des=%d doc_desrej=%d`，源码现取）；本席进程面读数 `doc_live=2 → 1`、`doc_des=0 → 1`、`doc_desrej=0 → 3`（逐次吻合我的调用序）✓；**在册腿面同样无此读数** ⇒ 腿面 `NOINFO`。

## ④ P11（收尾面新可达）＝ **本步没打开到那一格（如实说，不是失败）**

- 判据 C5③/P11 要求：`DestroyDocContext` 若被走到必须有**台账行**（stub 形态）或**摧毁计数 ≥1** 的机器证据。现取：**在册腿证据里既无台账行也无 `doc_*` 字段**（该件是**崩溃腿**的日志，进程在字体栈 `FailFast`，**没有走到收尾面**）；`nm` 位与 stub 字面、以及"升级为真实现"的**声明**都在册（C5 ✓）。
- ⇒ **结论（二值）**：**腿里"没走到"**（`doc_destroy` 面 0 读数 ＋ 进程在收尾之前就死了）⇒ **那是"本步没打开到那一格"，不是失败**；P11 的"新可达却无读数"**不成立**（无"被走到"的证据可对拍）。**机器证据缺位**如实记 `NOINFO`。

## ⑤ P1–P11 反腿（仓外副本文档；「未红或红而不点名 ⇒ 不成立」）

| # | 本席夹具／读数 | 判 |
|---|---|---|
| **P1** | 副本改声明件 `tool=96→97`（`DECL=<副本>`）⇒ **`DRIFT tool decl=97 live=96`** ＋ `PTSGAP=FAIL …` ＋ **`rc=1`**；正腿（真声明件）⇒ `PTSGAP=PASS`／`rc=0` | **成立**（红＋点名：字段名 `tool` ＋ 两值） |
| **P6** | 我自造 stuck 载体＋`PTSGAP_FR_BEFORE_NAME` 对名＋`PTSGAP_FR_BASELINE_IMPL=999` ⇒ `FAKE-PROGRESS … reason=ledger-nonzero-frontier-unchanged` ＋ `PTSGAP=FAIL` ＋ `rc=1` | **成立**（token 逐字在位） |
| **P10** | **仓外合成件**（2 台账行 ＋ 2 托管行，`ccf8e6c42f3b5c29`）：**混读直方图** ⇒ `1 entry=CreateDocContext ＋ 3 entry=LoDisposePenaltyModule`（**正是判据点名的那种读不出真相的合成**）；**台账面分离** ⇒ `CreateDocContext seq=5`／`LoDisposePenaltyModule seq=6`；**托管面分离** ⇒ `2 × LoDisposePenaltyModule` ⇒ **定名结论完全不同** | **成立**（红＝混读会给出误导性定名；点名＝定名源必须是 `^PTS_GAP entry=`） |
| **P9** | 判据要求"夹具自身要有牙"（`t103` 格 85 教训）。本席在同一支夹具里实测到**牙**：`PROT_NONE`（非 NULL 而不可读）⇒ **段错误**；而 `NULL` ⇒ 干净拒绝 ⇒ 两者**可区分**（不是"两前置都绿"） | **部分成立**（我的夹具两向可区分；**t110 自家夹具的牙**需其构建 ⇒ 见下条） |
| **P2／P3／P7／P8** | 反腿均需**重编译副本**（禁构建）⇒ 未跑。**正腿侧**：`NULL` 入参被拒（P3 正腿 ✓）、`int` 域未被塞指针＋指针走 `ptr0/ptr1`（P8 正腿 ✓）、自检**非恒绿**（见 ⑦ 的三档判词不同 ⇒ P7 正腿方向 ✓） | **`NOINFO`**（反腿缺位；按判据写死条款**不声称成立**） |
| **P4／P5** | `reason=` token 在 `tools/**` 现取多数**无载体**；`P4` 正腿＝C10 双形态回溯 ✓；`P5` 正腿＝`so16`＝现盘 ✓，跨趟反例＝`leg_23`（上代 `a2de…`）配现盘 `.so` ⇒ **三值不等**（这就是本趟 C7 的真实形态） | **`NOINFO`（无检测器）／P5 现场即红** |

**`t110` 自称修的四条「仪器自身」缺陷，本席能独立对上的部分**：
- **「观测镜环满」（换代改变链的 push 条数）＝ 我在现盘复现了同类效应**：同一进程内依次 push 4 条（`LoCreateContext`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle`／`CreateDocContext`）后，**只有最后两条可检索**（`rc=1`），前两条 ⇒ **`rc=0`（被覆盖/驱逐）** ⇒ "链变长会把旧条目挤出镜环"是**真实存在的**（容量有限；本席未测精确容量）⇒ **该条自我修复的方向合理**（但"修得对不对"需其夹具 ⇒ `NOINFO`）。
- 其余三条（重复销毁断言次序／长度纪律量错对象／夹具断言看错变量）**都需要其构建与夹具** ⇒ `NOINFO`（本席只证"现盘端口行为与声明自洽"）。

## ⑥ 队长裁定十三的落地判 ＝ **遵守**

- 裁定十三：`native_gap` ＝ **台账打印行数**（`legs-to-env.py` 的 `len(findall("PTS_GAP entry="))`，受打印预算 64 与 `ledger=truncated` 影响）⇒ 本趟 `2→0` **不许当前进读**。
- **本席现取**：`leg_23`（**上一代** `.so`）`native_gap=2`；`leg_24`（本代、**崩溃腿**）`native_gap=0`、`NAMED managed_unavail=0 native_err=-`；`app_g1.log` 台账行 **0**、`PTS_GAP ledger=truncated` **0**。
- **判**：① 该 `2→0` **只在崩溃腿上**出现、**不是同趟成对** ⇒ **本身就不构成"前进"读数**；② **载体文本**（`baaadb2b673c577c` 的 `:122`／`:251`／`:295`）**逐字写着** "`native_gap` 从 2 变 0 —— 必须先点名归因，不许当'前进'"／"本趟 0 是崩在打出第一行之前，不是补完" ⇒ **遵守了裁定十三**（本席按文档面判；其数值我一律用**自取**读数）✓。**不判红。**

## ⑦ 纪律第 `30` 条（三格；正腿 fresh；两种误导形态）

**本席自取三档（同一 `.so`、各自独立进程）**：

| 前置（第①格） | 依赖计数当时值（第②格） | 判词（第③格） |
|---|---|---|
| **fresh**（什么都没建） | `doc live=0 creates=0 destroys=0 rej=0 loc_live=0 calls=0` | `selfcheck=1 diag=0` |
| 建 **1 个 doc context**（不销毁） | `doc live=1 creates=1 destroys=0 loc_live=0 calls=1` | **`selfcheck=0 diag=30`**（**带历史的红**） |
| 建 1 个 doc context **后销毁** | `doc live=0 creates=1 destroys=1 loc_live=0 calls=1` | `selfcheck=1 diag=0` |

- **"带历史的红＝假红"本席**又一次实测到**（`diag=30`，与 `t105` 的 `diag=25` 不同格）⇒ 该误导形态**现盘可演示**（判据 §5.3 第一条要求写清 ⇒ **在册**）。
- **"fresh 的绿＝假绿"**：本席另给"能让断言变红的前置" —— 上表第 2 行就是；此外 `PROT_NONE` 一格把"入参只做 NULL 判定"这条假绿**当场打红**（段错误）⇒ **不是只靠净腿绿**。
- **自检不再扰动**：连续两次 `PtsGapSelfCheck()` ⇒ `doc live/creates/destroys` **保持 0**、判词 `1/0`（`t102` 的 F-2 修在**本步新增的 doc 计数面上也成立**）✓。

## ⑧ 不变量 / 指纹 / 哨兵 / `D-G189`

- **覆盖面**：`infp.sh list` 现取 **234** 条。
- **`inputs_fp`**：`ts=2026-09-29 02:53:28.791693358 +0800` ⇒ **`c086995a786ac10697e73c83ef942d39a355d4d1f381c9725099d7be29ebefba`**；`HANDOFF-NEXT.md` 末条 `cell=#1`（`ts=2026-09-29T02:50:15.831937851+0800`）登记 **同值** ⇒ **一致** ✓。
- **两哨兵**：`cmp /tmp/bridge-frozen.flag ~/wfp-runs/bridge-frozen.flag` ⇒ **IDENTICAL**；字段现取 `PF=2988f5154ecac5dd`（**＝现盘托管件** ✓）、**`WIN32SHIM=a2de5ff2b667f33f`（≠ 现盘 `.so` `a131ea4e6f5cc4f5`）** ⇒ **`WIN32SHIM` 轴未随本代 `.so` 更新**（见 `F-2`）；`WAVE=w80-freeze`／`BASELINE=#80` 未变。`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0`。
- **`D-G189`**：注册表现取 `D-G189` 出现 **3** 次 ＝ `git show HEAD:` 版 **3** 次 ⇒ **未被虚假扩大**。

## Findings（不改 `t110` 任何件；要改的以「夹具＋读数」给出）

- **`F-1`（medium）`CreateDocContext` 对"非 NULL 而不可读"的入参**deref 并段错误**：本席夹具（`~/wv88y/t111/h/pn.py` 形态，仓外）：`PROT_NONE` 页当 `fscontextinfo` ⇒ 进程 `段错误`、**退出码 139**（`NULL` 已能干净拒绝）。判据 §1.6① 只写了 `NULL` 一格，故**按判据字面不构成红**；它与同族端口（`LoSetDoc`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle` 都是"先比指针身份、不 deref"）**不对称**。**托管调用点今天不可能递进这种指针**（恒为 `ref FSCONTEXTINFO` 实参）⇒ 今天不可达；**修法建议**：要么在判据里把该格写死为"不可判/不承诺"（`NOINFO` 诚实划界），要么 native 侧只读**调用方声明过的字段长度**并接受"指针不可验"的事实（无法在 C 里先验指针可读性）。
- **`F-2`（low）哨兵 `WIN32SHIM` 轴滞后一代**：`bridge-frozen.flag` 仍写 `a2de5ff2b667f33f`，而现盘 `.so`（仓内＋部署）＝ `a131ea4e6f5cc4f5` ⇒ `.so` 换代未同趟入哨兵（`t110` 的件尚在飞、提交归队长 ⇒ 收尾时须一次性对齐）。**夹具**：`grep WIN32SHIM= ~/wfp-runs/bridge-frozen.flag` 与 `sha256sum …/libwpfwin32.so` 两条现取（本席已给）。
- **`F-3`（low）同趟性只在一条腿上成立**：`leg_24` 换了代（`a131ea4e6f5cc4f5`），**`leg_23` 仍是 `a2de5ff2b667f33f`** ⇒ C7 的"三者逐位相同"**不成立**；两页成对因此只能是"上代 vs 本代"（做对照可以，**不许**读成同趟成对）。
- **`O-1`（观察）`PtsDocFieldAt` 的下标映射与托管结构字段序不完全对齐**：`i=0/1/2` ＝ `version/fsffi/cInstalledObjects`，`i=4/5` ＝ `pInstalledObjects/pfsclient`，**`i=3` 不是第四个字段**（是别的量）⇒ 该端口**下标语义未在源码注释里写清**；判据 C9"至少两项"仍满足（我核到 5 项），但用该端口做逐字段对拍的人会踩到 `i=3`。
- **`O-2`（观察）报表 `doc_sets=` 与端口口径不一致**：现取报表字段 `doc_live=2 doc_sets=0 doc_rej=2 doc_des=0 doc_desrej=0`（两次成功 create 之后 `doc_sets` 仍 **0**），而端口 `PtsDocCreates()` ＝ **2** ⇒ **只看报表 `doc_sets=` 会把"创建数"读成 0**；建议把该字段绑定到 `g_pts_doc_sets_c` 或改名，避免判据误读。
- **`O-3`（观察）镜环容量有限、链变长会驱逐旧条目**：同进程 push 4 条后只有**最后两条**可检索（前两条 `rc=0`）⇒ 任何"用 `PtsJmpProbe` 追链"的判据都必须先说明**容量与覆盖序**（与 `t110` 自报的"环满"同一机制；本席未测精确容量）。

## `NOINFO`（不折绿、不折红）

1. **`P2`／`P3`／`P7`／`P8` 的反腿**（需重编译副本）⇒ 禁构建未跑；正腿侧读数已在 ⑤ 给出。
2. **`t110` 自报的四条仪器缺陷"修得对不对"**：需其构建与夹具（本席只独立复现了"环满/驱逐"这一支的**现象**）。
3. **腿里的收尾面读数**（`doc_des=`／`doc_live=`／`DestroyDocContext` 台账行）：在册证据**无此字段**（`P4`／`P11` 的机器证据）⇒ 本席进程面读数不能替代腿面。
4. **`PtsDocFieldAt` 下标 3 的语义**：源码注释未写 ⇒ 不猜。
5. **`_contextPool.Count > 4` 门与 `:488` 的实际可达性**（判据 §6-N2）：需运行期池读数。
6. **`FSCONTEXTINFO` 的 native 侧布局权威**（判据 §6-N5）：本仓无 native 规格（结构权威只在托管侧 `Pts.cs:833-844`；本席**未**读那具未入索引的 `abi-layout` 产物）。
7. **"两页真排版"／整趟门禁／显示位／跑腿面**：本任务禁跑整趟门禁、禁占显示位、禁跑腿 ⇒ 未跑；本件**不**把任何绿读成排版成功。

---

SELF-SHA16 （口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ ca87d36e14e091ff

---

## ⏪ `t113` dated 追加 —— 本席（`scribe`）对 `t111` 余项的**独立现取**与关账处置（读时 `2026-09-29T03:0x+0800`；本件上方原文**一字未删**；本段只加行，末行给出新的自报口径值）

**仪器与产物（现取）**：`.so` ＝ `a131ea4e6f5cc4f5`（`nm -D --defined-only … | wc -l` ＝ **572** ＝ `bin/exports.txt` 行数）；`.dll`（Release／部署件）＝ `2988f5154ecacdd`；夹具**全部仓外**（`python3`＋`ctypes` 直调现盘 `.so`，逐例**独立进程**），**用完删**。

### ① `F-1` 成对读数（我自造，不复用复核者的夹具）
- **`NULL`** ⇒ `rc=-10000`、`*out` 清成 `NULL`、`PtsDocCreates()=0`、`PtsDocLive()=0`、报表 `doc_rej=1` ⇒ **干净拒绝**（一个字节都不读）✓ 与复核者一致。
- **`PROT_NONE` 页** ⇒ **段错误 `rc=139`**（`BEFORE_CALL` 已印、死在调用内）✓ 与复核者一致。
- **机理与不对称**：本席自读现盘原文 —— `CreateDocContext` 按偏移读入参结构（`b+0/+4/+12/+16/+24/+32`），而 `LoSetDoc`／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle` 一律**先按指针身份查在册表**（`wpf_pts_loc_find(ploc)` 一类）**不 deref** ⇒ 不对称**来自职责差**（`CreateDocContext` 要"带走入参里的可判定量"）。
- **处置＝（甲）判据补格（落点：`P1-w8-step4-criteria.md` 的 `t113` dated 段）**：只承诺 `NULL` 拒绝；「非 `NULL` 而不可读」记 **`NOINFO(前置不可先验)`**、**不构成红**（形态今日不可达：托管恒传 `ref FSCONTEXTINFO`；且要升成"可判前置"属**产品面**改动 ⇒ 另派单）。**未**把它写成"必须修否则红"，**未**静默抹掉。

### ② `O-1` 成对读数：`PtsDocFieldAt(idx, field)` 的**下标语义**
```
FIELDAT idx=0 i=0 => 0x11111111     (version)
FIELDAT idx=0 i=1 => 0x22222222     (fsffi)
FIELDAT idx=0 i=2 => 0x7            (cInstalledObjects)
FIELDAT idx=0 i=3 => 0x7c02be7e9000 (info_addr ＝ 记下的"入参结构地址"，**记账槽**)
FIELDAT idx=0 i=4 => 0x4444444444444444 (pInstalledObjects)
FIELDAT idx=0 i=5 => 0x5555555555555555 (pfsclient)
FIELDAT idx=0 i=6 => 0x6666666666666666 (ptsPenaltyModule)
```
⇒ 映射表（`0,1,2` 然后**跳一格** `4,5,6`；`field=3` 不是第四个字段）已按 `t113` 段写进**判据件**；并重申它**是位置读**（与 `…PtsPenaltyModuleHandleAt` 同族，**不得跨销毁缓存 `idx`**）。

### ③ `O-2` 成对读数：**我现取不能复现「与端口不一致」**
```
CREATE#1 rc=0 handle=0x…   CREATE#2 rc=0 handle=0x…
PORT   creates=2 live=2 destroys=0
REPORT doc_live=2 doc_sets=2 doc_rej=0 doc_des=0 doc_desrej=0     ⇒ doc_sets == PtsDocCreates() == 2
```
- **字段映射（自读 `snprintf` 实参表）**：`doc_sets=` ← **`g_pts_doc_sets_c`**（＝ `CreateDocContext` 成功数 ＝ 端口 `PtsDocCreates()` 的同一个变量）；**`setdoc_sets=`** 才是 `LoSetDoc` 成功数。
- ⇒ 处置：**在册写死该格语义与端口对应**（判据件 `t113` 段），并把你（复核者）读到的 `doc_sets=0` 记 **`NOINFO(复现失败，最可能成因＝跨进程/跨快照对拍；未验证)`**；**本件不改 `src/**`**（该格现取一致；若仍要与端口逐字段绑定，属产品面改动 ⇒ 另派单）。

### ④ `O-3` 成对读数：观测镜环**容量 ＝ 4、覆盖序 ＝ 最近 4 条**
```
PUSH#1..#6 （6 次 push，ploc 各不同）
PROBE push#1 => rc=0   （已驱逐）
PROBE push#2 => rc=0   （已驱逐）
PROBE push#3..#6 => rc=1（可检索）
另：先有 2 条（两次 create）再 push 4 条 ⇒ 最早那 2 条探不到
```
⇒ 口径句（并入**纪律第 `30` 条族**，**不新立号**）：凡用 `PtsJmpProbe` 追链的判据**必须**写明**环容量**与**覆盖序假设**，且 `rc=0` **不等于**"该调用没发生"（只是**已被驱逐**）。`t110` 自报的"环满"＝**本机制的第一个实例**。**落点**：判据件 `t113` 段 ＋ `HANDOFF-NEXT.md` 的纪律族**索引行**（`t113` 一行，指向第 `30` 条，不复制条本体）。

### ⑤ `F-3` 同趟性（如实记）
`leg_23.env` ＝ `shim=a2de5ff2b667f33f pf=6893d1d3fb1ee110`（**上一代**，`alive=yes app_rc=143`）｜`leg_24.env` ＝ `shim=a131ea4e6f5cc4f5 pf=2988f5154ecacdd`（**本代**，`alive=no app_rc=134`）⇒ **两轴都不同代** ⇒ `C7` 的"三者逐位相同"**今日不成立**（成因：`leg_24` 崩在字体栈／`leg_23` 未跑完）⇒ 在册写明「**完整的同趟换代排在字体栈阻断解除之后**」，此前两页成对只能记作**上代 vs 本代**。

### ⑥ 本席同趟复核（与 `t111` 的靶心达标面无冲突）
- 台账 `^PTS_GAP entry=` 行 **0**；托管 `[PTS-UNAVAILABLE]` **0**；现盘 `.so` `nm` ＝ `exports.txt` ＝ **572**（本席现取）。
- ⚠️ **仪器在动**：`docs/ROUTES.md`／`HANDOFF-NEXT.md`／判据件等**均不在覆盖面内**（本席现算：各 `0`）⇒ 本件**不产生** `cell=#1` 登记义务（见交付回执的指纹读数）；若他者在本席作业期改覆盖面内件，位移归其所有。

SELF-SHA16 （`t113` dated 追加后；口径 ＝ `head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 56ceaa3893245704（原自报行 `ca87d36e14e091ff` 系**追加前**全文值，原样保留）

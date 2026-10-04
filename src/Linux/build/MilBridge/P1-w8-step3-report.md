# P1-W29 · W8 **第三步实现** —— `LoGetPenaltyModuleInternalHandle` 真实现（＋同趟修掉两处实测缺陷）

> **本件是实现件**：契约 ＝ `build/MilBridge/P1-w8-step3-criteria.md`（326 行，sha16 `14e1035cea86bcff`，`t100` 先写）。**逐条照 C1–C8 与 P1–P8 执行**；一切读数**本趟现取**，命令与输出原样贴出。
> **未引任何既有报告当证据**；判据件只作契约引用。**读数一条未抄**。
> **边界自证见 §9**；唯一写入 ＝ `src/WpfGfx.Linux.Native/**`、本件、`HANDOFF-NEXT.md` 的 `cell=#1` 行、`tests/PtsPagesProbe/evidence/**`（`.so` 换代 ⇒ 同趟重取）。**未** `git add/commit/push`。
> **读取时刻**：`ts=2026-09-29T01:13`（起）→ `2026-09-29T02:24`（末取）。

---

## §0 快照与现取读数

| 项 | 现值 | 取法 |
|---|---|---|
| `HEAD` | `e528f53`（本趟**未**提交） | `git log --oneline -1` |
| 权威 `.so` | `a2de5ff2b667f33f`（**before ＝ `4e999451e9ab137e`**） | `sha256sum` |
| 导出面 | `nm` ＝ **567** ＝ `wc -l exports.txt` ＝ **567**（before ＝ 565；**无导出消失**） | `nm -D --defined-only`／`wc -l` |
| PTS 桩件 | `src/WpfGfx.Linux.Native/src/win32_pts.c` ＝ `80b5786aef1cc823`（**1451 行；末次编辑后、构建前**；before ＝ `f3ae1159a852a25a`／1267 行）｜现取 `mtime=02:19:41` **早于** `.so` 的 `mtime=02:22:35` ⇒ 现盘 `.so` **就是**本件的源码形态 | `sha256sum`／`stat` |
| 缺口三格 | `PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567` | 现跑（C3） |
| 前沿 | `PTSGAP_FRONTIER before=LoCreateContext@3 after=LoDisposePenaltyModule@3 carrier_sha16=bf59ef38f5b8be55`｜`PTSGAP_FRONTIER_STATE=NAMED frontier=LoDisposePenaltyModule` | 同上 |
| `entry=` 面 | **after**：`3 LoDisposePenaltyModule` ＋ `1 CreateDocContext`；**主跳 `LoGetPenaltyModuleInternalHandle` ＝ 0**（before ＝ **3**）；`unknown` ＝ **0**（before ＝ 0） | 现取（C4） |
| 两页症状 | 两腿 `alive=yes app_rc=143`／`magenta=54513`(24)・`49923`(23)／`native_gap=2`（before ＝ 2）／`shim=a2de5ff2b667f33f` | 现取（C6） |
| 守卫 | `PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded`｜`PTS_G10_NAME=PASS observed=LoDisposePenaltyModule names=2 roster=13` | 现跑 |

✅ **同趟性 ＝ `yes`**（C7）：`so16=` ＝ `DEV … shim=` ＝ 现盘 `.so` ＝ `a2de5ff2b667f33f`，且 `carrier_sha16=bf59ef38f5b8be55` ＝ `app_g1.log` 实际 `sha16`。

---

## §1 补了什么（四件套 ＋ 两处**实测**缺陷）

### 1.1 主跳实现（照契约 §1「四件套」逐条）

`LoGetPenaltyModuleInternalHandle(void *penaltyModuleHandle, void **internalHandle)`：

| 条 | 内容 |
|---|---|
| ① **句柄身份校验** | 只认 `LoAcquirePenaltyModule` **自己发过且仍在册**的模块句柄：按**指针身份**扫 `g_pts_loc_live[]`（**不 deref 入参**）；`magic` 不符跳过。`NULL`／未知 ⇒ `-10000` |
| ② **出参真落盘且与该模块绑定** | `*internalHandle = &c->penalty_internal_handle`（**该对象自己的字段地址**，非全局单例 ⇒ 第二个模块不串味）；`internalHandle == NULL` ⇒ **拒绝**（不给"写空也算成功"） |
| ③ **计数** | `g_pts_inth_sets`／`g_pts_inth_rejected` ＋ 按对象 `penalty_internal_gets` |
| ④ **可独立读取** | 观测镜记"哪个模块句柄、落出什么内部句柄、该内部句柄是否**真等于**某个在册对象自己的那个字段"；**指针量走镜的 `ptr0`／`ptr1` 专用域** |

**导出面新增二条（逐名点名，无导出消失）**：`WpfLinuxWin32_PtsPenaltyInternalHandleAt`（按 idx 读"该对象自己的内部句柄"）、`WpfLinuxWin32_PtsPenaltyInternalGets`（格 5 成功计数）。

### 1.2 🔴 缺陷一（**自检自身**）：被拒断言与成功断言**串了变量** ⇒ 第 15 格恒红

主链原来是：

```
if (LoAcquirePenaltyModule(loc_a, &q2) != 0) rc = 13;      /* 真实现 ⇒ 必须成功 */
else if (q2 == NULL || q2 == (void *)0x34) rc = 14;
else if (LoAcquirePenaltyModule((void *)0xdeadbeef, &q2) …) rc = 17;   /* ← 把 q2 清成 NULL */
else if (q2 != NULL) rc = 18;
...
else if (LoGetPenaltyModuleInternalHandle(q2, &q3) != 0) rc = 15;      /* ← q2 已是 NULL ⇒ 被拒 ⇒ 红 */
```

**实测**：净腿 `RUN1/2/3 rc=0 diag=15`，`loc_live` 1→2→3（链早退 ⇒ 泄漏）。**不是实现坏，是断言之间串了变量。**
**修法**：拆出 `q4` **专供被拒面**（`q2` 不再被清），并把"看家真落盘"那条补上（先写非空证明这口真会写）。

### 1.3 🔴 缺陷二（**实现真错**）：`NULL` 罚分句柄**静默半通**

修 1.2 之后历史腿仍红（`diag=85`）。逐步 trace 抓到：

```
[f5] C0 q=0x5b5b
[f5] C1 r=0 q=0x5e02349db2f0      ← LoGetPenaltyModuleInternalHandle(NULL,&q) 返回 0 且写了内部句柄！
[f5] FAIL=19  (= 契约 P3「假成功：NULL/伪造入参也返回 0」)
```

**根因**：只靠"扫在册对象、逐个比 `penalty_module_handle == 入参`"是**不够**的 —— 只要有一个在册对象的 `penalty_module_handle` **恰好也是 `NULL`**（**未被 `LoAcquirePenaltyModule` 取过的对象就是这种**），那次"拿 `NULL` 当句柄"的调用就会**命中该对象并返回 0**。
**修法**：`penaltyModuleHandle == NULL` **在查表之前显式拒绝**。

### 1.4 🔴 缺陷三（**反腿抓出来的**）：格 `85` 在**净腿上没有牙** —— 纪律第 `30` 条第二种误形的又一实证

修 1.3 之后我按契约做 P7／反腿，用**去掉 NULL 检查的坏实现**跑真判定链，期望它红 —— **它给了 `SELFCHECK=1 DIAG=0 F5=1`（绿）**。

原因：夹具两个对象**都已 acquire 过**（`penalty_module_handle != NULL`）⇒ 拿 `NULL` 入参**扫表扫不到任何对象** ⇒ 坏实现照样返回非 0 ⇒ 该断言**在净腿上不成立**。而运行期的真实命中路径恰恰是"**还没 acquire 的活对象**" —— 也就是**只在历史腿上暴露**。

**这一条正是纪律第 `30` 条要防的东西**：修 1.3 之前，**净腿 `rc=1 diag=0`（绿）**、**带历史腿 `diag=85`（红）** ⇒ 若只看净腿就会得出"已经修好了"的结论。
**修法**：夹具**先建一个"只建不 acquire"的活对象**（`c3`）再调那条拒绝断言 ⇒ 该断言**在净腿上也有牙**：

```
正腿（真实现）      SELFCHECK=1 DIAG=0 F5=1
反腿（去掉 NULL 检查） SELFCHECK=0 DIAG=85 F5=0      ← 净腿当场红并点名格 85
```

**判定链与实现语义未动**；只动了夹具的**前置状态**。

---

## §2 判据 C1–C8（逐条成对读数）

### C1 构建面 ✅
```
bash src/WpfGfx.Linux.Native/build-shim.sh --symbols >c1.out 2>c1.err; echo $?
rc=0   （导出符号总数：567）
nm=567 exports=567 equal=yes   so16=a2de5ff2b667f33f（before=4e999451e9ab137e）
```
两条新符号**逐名点名**、**无导出消失**（`comm -13`／`comm -23` 现取，后者为空）。槽：`HEAVYSLOT=ACQUIRED waited=0s`／`MEMOK avail=8310MB`／`RELEASED rc=0 held=3s`。

### C2 缺口面（**按实际归因，不硬凑数字**）✅
```
python3 … check-shim-coverage.py --tier mapped; rc=0
  [PresentationNative_cor3.dll] 96 条        （before=96 ⇒ 不变）
候选两入口命中数: 0
```
⇒ **不变**，符合契约"纯行为补全 ⇒ 96→96"。**本条的绿不构成"前进"证据**（契约原话）。`Lo*` 前缀数未变（两候选本就**不在**该面里）。

### C3 台账/前沿面（**前进的主证据**）✅
```
bash build/MilBridge/tools/pts-gap-count-check.sh; C3_RC=0
LIVE  tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567
  SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md ops hist=1
  SITE-HISTORICAL-ONLY samples/WpfFeatureProbe/KNOWN-DEFECTS.md impl hist=1
PTSGAP_HISTORICAL=n=1（自引旧代工件的**历史行**命中数：**不参与现值判定**，见裁定九）
PTSGAP_CITED=PASS refs=1 strict=1
PTSGAP_FRONTIER before=LoCreateContext@3 after=LoDisposePenaltyModule@3 carrier_sha16=bf59ef38f5b8be55
PTSGAP_FRONTIER_STATE=NAMED frontier=LoDisposePenaltyModule（具名前沿成立）
PTSGAP=PASS tool=96 dead=11 artifact=1 ops=84 impl=89 so16=a2de5ff2b667f33f exports=567
```
**`after=LoDisposePenaltyModule@3` ≠ 主跳 `LoGetPenaltyModuleInternalHandle`** ⇒ 前沿真的离开它。`impl 90→89` ＝ 主跳离开缺口名单的**事实**（非凑数）。

#### C3 的一处**中途阻碍与处置**（如实入册，不藏）
本件中途 C3 曾 **`PTSGAP=FAIL`**，三条 `SITE-DRIFT … tool want=96 got=97／ops want=84 got=85／impl want=89 got=91`，来源是 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2257` 那条 `t104` 刚**逐字节恢复**成 `2026-09-24` 的历史行（自带 `97/85/91`）。
- **反证（只读副本上跑）**：仅把那一行三个数改成 `96/84/89` ⇒ `PTSGAP=PASS … exports=567` `rc=0` ⇒ 该行是**唯一**阻碍。
- **改前就已经是 FAIL**（三代混值 `97/85/91` 同时对不上 `96/84/89`）⇒ **与本件改动无关**。
- **队长裁定（本趟收到）**：该历史行**逐字节保留**（它自引旧代工件 `fc60c34d51fd9247`／550 导出，只描述它引用的那一代，**不承担现值职责**）；要改的是**牙的扫描形状**（已另派 `tools/**` 写者）。
- **重跑结果**：牙改后现取 `PTSGAP=PASS`，并把这行**正确归类**为 `SITE-HISTORICAL-ONLY`／`PTSGAP_HISTORICAL=n=1` ⇒ **本件未动历史行、未动牙**，阻碍由他人件的修正消掉。

### C4 `entry=` 面：具名**位移**且可回溯 ✅
```
before（t100 在册）: 3 LoGetPenaltyModuleInternalHandle ＋ 1 LoDisposePenaltyModule  unknown=0
after （本趟现取）: 3 LoDisposePenaltyModule ＋ 1 CreateDocContext                     unknown=0
```
- **主跳计数 `3 → 0`**（契约要求 **after < before**，最理想为 0 ⇒ **达标**）。
- `unknown` **不增**（0 → 0）。
- **新出现的具名可回溯上游声明**（现取）：
  - `CreateDocContext` ⇒ `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/Pts.cs:3091: internal static extern int CreateDocContext(`
  - 托管调用点 `build/PresentationFramework.Linux/PtsCache.Linux.cs:548: PTS.Validate(PTS.CreateDocContext(ref _contextPool[index].ContextInfo, out context));`
  - `LoDisposePenaltyModule` ⇒ `upstream/…/LineServices.cs:1575`（`t97` 已回溯，本趟复取命中 1）

### C5 释放同伴面：**不得回退** ✅
```
nm -D --defined-only … | grep -cx 'LoDisposePenaltyModule'  ⇒ 1      （不得为 0）
PTS_GAP entry=LoDisposePenaltyModule seq=6 err=-10000 calls=1        （在位；本步不要求它消失）
```
- **二选一声明（契约要求）**：**未升级**，维持**诚实缺口 stub** ⇒ `C8` 的对应串保持 **1**（见 C8）。理由照契约：它已导出、且托管侧 `:59` **丢弃返回值** ⇒ 今天不会抛；顺手升级它**不是本步必做项**。
- **来源相位**：见 §R9。

### C6 冷启腿两页面：**不劣化** ＋ 台账效应可见 ✅
```
LEG k=23 alive=yes app_rc=143 magenta=49923 colors=844 ns=…RichTextBoxDemo    ae=141323 ink=428491
LEG k=24 alive=yes app_rc=143 magenta=54513 colors=852 ns=…FlowDocumentDemo   ae=221857 ink=423833
NAMED managed_unavail=1 err=-10000 native_gap=2 native_err=-10000      （before=2 ⇒ after ≥ before 达标）
DEV x_up=yes five_stable=yes shim=a2de5ff2b667f33f pf=6893d1d3fb1ee110
PTS_GUARD=PASS legs=2/2 fails=- cannot=- diag=- direction=in-file phase=degraded
PTS_G10_NAME=PASS observed=LoDisposePenaltyModule names=2 roster=13 domains=pts-declared
```
两腿 `alive=yes`、`app_rc=143 ∉ {134,139}`、`magenta` 无劣化（对照 `t100` 在册：`49592`／`54182`）。**两条同伴（`CreateDocContext`／`DestroyDocContext`）都没有把进程打死** ⇒ **不需要**同趟补 stub（与第二步那次 `rc=134` 的处境不同，原因见 §3.2）。

### C7 **同趟性** ✅
```
so16=a2de5ff2b667f33f  gap_so16=a2de5ff2b667f33f  leg_shim=a2de5ff2b667f33f  carrier=bf59ef38f5b8be55  app_g1=bf59ef38f5b8be55  ⇒ same=yes
```
**before 现取是 yes，after 保持 yes。**

### C8 stub 面 ✅
```
LoGetPenaltyModuleInternalHandle=0      （before=1 → after=0，契约要求）
LoDisposePenaltyModule=1                （维持诚实 stub ∈ {0,1}，与 C5 声明一致）
```

---

## §3 本步第一次打开的那条托管侧路径（实测，非推理）

### 3.1 台账与页面级读数（现取）
```
:511 PTS_GAP entry=CreateDocContext          seq=5 err=-10000 calls=1
:512 PTS_GAP entry=LoDisposePenaltyModule    seq=6 err=-10000 calls=1
:513 [PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage entry=LoDisposePenaltyModule err=-10000 action=page-placeholder（已画出页级占位；进程继续）
:967 [PTS-UNAVAILABLE] … （第二页同形）
```
前置是 `:510 [HCIN] mouseUp hop=MainWindow …`（点击落地）⇒ 这条路径**确实被走到了**。

### 3.2 关键观测（**与契约预期形状的差异，如实报**）
契约 §1 预期"`:534` 成功、`:542 GC.SuppressFinalize` 首次执行 ⇒ `:548 PTS.CreateDocContext` 第一次被走到"。
**实测**：`CreateDocContext` **确实第一次被走到**（`seq=5`），但它**返回 -10000**（仍是诚实缺口 stub）⇒ 建上下文失败 ⇒ 清理同伴**随即**被走到（`LoDisposePenaltyModule seq=6`）⇒ 页面级**可见降级**（洋红占位），**进程继续**（`alive=yes`）。
⇒ **`entry=` 面的位移是"主跳消失 ＋ 下一跳露头"**，而不是"两页真排版"。**任何"绿"都不许被读成"两页真排版"**（契约通用反过读句）。

### 3.3 缺口面为什么**不变**（归因不硬凑）
本次是**纯行为补全**（主跳从 stub 变真实现），**没有**新增/删除任何"未导出的入口名"进出 ENFE 面 ⇒ `tool`／`dead`／`artifact`／`ops` 全不变；只有 `impl` ＝ `ops + STUB` 里 `STUB`（`return wpf_pts_gap("…")` 计数）由 6 降为 5 ⇒ `impl 90→89`。**未为凑任何数字删 stub。**

---

## §4 R9 释放相位面（现取）

| 字段 | 现值 | 判读 |
|---|---|---|
| `LoDisposePenaltyModule` 台账次数 | **1** | `calls=1` |
| `seq=` | **6** | 在 `CreateDocContext`（`seq=5`）**之后** |
| 相位 | **清理期** | 出现在"`CreateDocContext` 失败 ⇒ 收尾"处；**未**出现在功能路径上、**未**早于主跳 |
| 来源（终结器 vs 显式 `Dispose`） | **如实声明：本趟在日志里**取不到**托管侧 `:542 GC.SuppressFinalize` 的直接痕迹**（`grep -nE 'SuppressFinalize\|DangerousGetHandle\|ptsPenaltyModule' app_g1.log` 命中 **0**）⇒ 是否已从终结器路径切到显式 `Dispose` 路径，**本件判不了** | **NOINFO(reason=托管侧不透出该符号；需要 `:542`／`:534` 的可观测痕迹或托管侧插桩)** |

**契约要求"若它在功能路径上出现（早于主跳）⇒ 需点名解释"** ⇒ 现取 `seq=6 > seq=5`，**不在**功能路径上、**不早于**主跳 ⇒ 该条**不红**。

---

## §5 假进度必红 P1–P8（正腿必绿／反腿必红并点名）

> **总则照契约**：反腿**未红**、或红而**不点名** ⇒ 该条**判不成立**；反腿一律在**副本文档／副本源码**上跑（本件全部在 `~/t103-runner/fixtures/reverse/**`，**仓内零残留**）。

| # | 结论 | 正腿 | 反腿读数（现取） | 点名 |
|---|---|---|---|---|
| **P1** | **NOINFO** | — | 期望 token `decl-vs-live-mismatch` 在 `build/MilBridge/tools/**` **命中 0**（现取 9 个 token 里只有 `ledger-nonzero-frontier-unchanged` 在册） | **NOINFO(reason=牙侧无该 token；属禁写域)** |
| **P2** | **成立** | `SELFCHECK=1 DIAG=0 F5=1` | 真实现体换成"**清空出参 ＋ `return 0`**"（零副作用）：**`SELFCHECK=0 DIAG=16 F5=-1`** | **格 16**（返回 0 时 `*internalHandle` 仍为 NULL/毒值 ⇒ 红并点名） |
| **P3** | **成立** | 同上 | ①去掉 NULL 检查：**`0/85 F5=0`**；②"NULL/未知也返回 0"的假成功：**`0/19 F5=-1`** | **格 85**／**格 19**（`null-handle-accepted` 的真实承重点） |
| **P4** | **NOINFO** | C4 的具名**可回溯上游声明**（`Pts.cs:3091`／`LineServices.cs:1575`，现取命中 1） | 期望 token `entry-name-not-backtraceable` 在 `tools/**` **命中 0**；且仪表在**托管侧**（`PtsCache.Linux.cs`），属**禁写域** | **NOINFO(reason=token 不在册 ＋ 仪表禁写)** |
| **P5** | **NOINFO**（等同成立） | C7 `same=yes` | 期望 token `cross-run-pairing` **命中 0**；无专门的"跨趟交叉检测器"。**但本件**手工给了实证：`t103` 中途那趟（`shim=5c2097d35cd89749`）与本趟（`a2de5ff2b667f33f`）**就是两个不同世代**，混用即三值不等 ⇒ 会被 C7 的 `same=yes` 判据当场抓住 | **NOINFO(reason=token 不在册)** |
| **P6** | **成立（由 C3 承重）** | 真实现 ⇒ C3 `after=LoDisposePenaltyModule@3 ≠ 主跳` | 实现体内该 token 在册（`pts-gap-count-check.sh`）。**本件**的"计数下降而前沿不动"形态被这条挡住：`impl 90→89`（下降）而**前沿名确实变了** ⇒ 不触发 | 触发条件 `impl < 基线 ∧ 前沿名未动` ⇒ **本件不满足**（**这正是"真前进"与"假进度"的分界**） |
| **P7** | **成立（本件最重的一条）** | 真实现 ＋ 真判定链：**`SELFCHECK=1 DIAG=0 F5=1`** | ①真实现 ＋ **整条判定链短路**（恒绿）：`1/0 F5=1`；②**坏实现**（去掉 NULL 检查）＋ **判定链短路**：**`1/0 F5=1`** —— 与正腿**逐格相同**；③参照：**坏实现 ＋ 真判定链**：`0/85 F5=0` | **反腿②与正腿判词全同 ⇒ 恒绿自检没有牙，当场点名**。**并带出真实后果**：格 `85` 在净腿上原本**也**没有牙（§1.4）⇒ 已同趟修夹具使其有牙 |
| **P8** | **成立（两向都咬住）** | 指针量走**专用指针域** `ptr0`／`ptr1`：`SELFCHECK=1 DIAG=0`（镜记的内部句柄 == 对象上的、镜记的模块句柄 == 入参） | ①`p8a`（指针**经过 `int` 再取回** ⇒ 截断 ⇒ **恒不等** ⇒ 假红形态）：**`0/85 F5=0`**；②`p8b`（对拍**只好用 `int` 域**）：**`0/85 F5=0`** | **两向都红**，且都归因到夹具内**具名的那一处对拍**（`镜记的内部句柄 == 对象上的`，即只有指针域才能满足它）⇒ **契约"两向都要咬住"达标**；**不作为"恒不等 ⇒ 假红"放过**（正腿在同一条对拍上绿 ⇒ 该对拍有牙） |

**P7／P8 的机读输出（原样）**：
```
--- 正腿（真实现 + 真判定链）---           SELFCHECK=1 DIAG=0 F5=1
--- P7 反腿A（真实现 + 判定链短路）---      SELFCHECK=1 DIAG=0 F5=1
--- P7 反腿B（坏实现 + 判定链短路）---      SELFCHECK=1 DIAG=0 F5=1
--- 参照（坏实现 + 真判定链）---            SELFCHECK=0 DIAG=85 F5=0
--- P8-A（指针过 int ⇒ 截断）---           SELFCHECK=0 DIAG=85 F5=0
--- P8-B（只用 int 域对拍）---             SELFCHECK=0 DIAG=85 F5=0
```

---

## §6 纪律第 `30` 条：三格 ＋ 调用序

> 契约要求：凡引用自检／探针读数，同趟必须给**三格** —— ① fresh 或已发生的关键调用序 ② 该读数依赖的当时值 ③ `rc` ＋ `diag`；**正腿必须 fresh 进程**、带历史腿必须**独立进程**；并写清**两种误导形态**。

### 6.1 ① 关键调用序（逐条）
- **fresh 腿（净）**：进程启动 ⇒ 未建任何 LS 上下文、未取任何模块句柄、未写 `LoSetDoc`／`LoSetBreaking` ⇒ 直接调自检。
- **带历史腿（独立进程）**：先 `LoCreateContext` 建**一个活上下文**（**不销毁**）⇒ 再调自检（`base=1`）。**这是独立进程**，与净腿互不影响。
- 修 §1.3 前**必须**用带历史腿才能看到缺陷二（§1.4）。

### 6.2 ② 该读数依赖的当时值

| 腿 | `loc_live`（入口/出口） | `inth_sets`／`inth_rej` | `g_pts_pen_sets` |
|---|---|---|---|
| fresh | 0 → 0 | 每跑 +N 后**复原** | **复原**（`F-2` 口径） |
| 带历史 | 1 → 1（**回 base，不涨**） | 同上 | 同上 |

### 6.3 ③ `rc` ＋ `diag`（修后，连跑 4 次＝幂等）
```
fresh : RUN1..4  rc=1 diag=0   loc_live=0
带历史: RUN1..4  rc=1 diag=0   loc_live=1（= base）
```

### 6.4 两种误导形态（**本趟各有实证**）
- **"带历史的红 ＝ 假红"**：修 §1.2 **之前**，净腿 `diag=15` 而带历史腿 `diag=85` —— `85` 那一路是**夹具前置状态**造成的，**不是**主跳实现坏。若只信带历史腿就会**误判实现**。
- **"fresh 的绿 ＝ 假绿"**（**本趟最强的一例**）：修 §1.3 **之前**，**净腿 `rc=1 diag=0`（绿）**而缺陷二（`NULL` 静默半通）**真实存在**；只有带历史腿 `diag=85` 才暴露。若只看净腿，就会在"实现有静默半通"的情况下**发出绿的判词**。⇒ 本件因此把"净腿也必须能咬住"写进夹具（§1.4）。

---

## §7 未做项与原因（不冒充）

| 项 | 状态 | 原因／缺什么 |
|---|---|---|
| C5 的来源相位"终结器 vs 显式 Dispose" | **NOINFO** | 托管侧 `:542`／`:534` 在 `app_g1.log` 里**无痕迹**（现取 `grep` 命中 0）。**消掉需要**：托管侧插桩或该符号的可观测输出 |
| P1／P4／P5 | **NOINFO** | 期望 token 在 `tools/**` 命中 0；且仪表/牙属**禁写域**。**消掉需要**：`tools/**` 写者补 token（**非本件写域**） |
| C3 中途那三条 `SITE-DRIFT` | **已由他人件消除** | 队长裁定"历史行逐字节保留、改牙的扫描形状"，另派 `tools/**` 写者；本件**未动**历史行与牙，重跑 `PASS` |
| `STATICJAWS=FAIL fails=3 n=32` | **他人族、禁写域、未动** | 现取如实报，不作为本件判据 |
| `SSC=FAIL（SSC_VALUE=FAIL key=WIN32SHIM got=5c2097d35cd89749 want=a2de5ff2b667f33f）` | **哨兵待刷（写哨兵是队长的动作）** | `.so` 本趟**换代两次**（`5c2097d3` → `a2de5ff2`，第二次因 §1.4 修夹具），哨兵位停在**第一次**的值。`PF` 位与现盘相符。**如实报告，不自改** |
| `LoDisposePenaltyModule` 升级 | **按契约不做** | 契约明写"不必升级、但不得回退"；托管侧丢弃其返回值 ⇒ 今天不会抛 |

---

## §8 纪律自证

| 纪律 | 读数 |
|---|---|
| **28**（改覆盖面内件 ⇒ 同趟追 `cell=#1` ＋ `inputs_fp`） | `HANDOFF-NEXT.md` EOF **纯 `>>`** 追写一行（`647 → 648` 行；`git diff --numstat` ＝ `2 1`，即删除 0 行＋历史行移位计数）⇒ `bash ~/w153a/bin/infp.sh fp` ＝ `40a2b4a899dbfbe3d5f8c0e2d62101b9e989bbb5115bedf12625f2560ebb5395` ⇒ **`HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 reasons=none`**（`rc=0`） |
| **29**（备份面 ≡ 换代面） | 改动件逐件 `cp -p` 到车道：`win32_pts.c`／`libwpfwin32.so`／`exports.txt`／`pts-gap-decl.txt`／`HANDOFF-NEXT.md`（`.pre-t103`）；**证据目录整目录两趟备份**：`evidence.pre-t103`（29 件）/ `evidence.abortrun-t103`（31 件）/ `evidence.partialrun-t103`＋半趟 `app_g1.log`（`89267cd2f04a383c`，78543 B） |
| **30** | §6（三格 ＋ 调用序 ＋ 两种误导形态，各有实证） |
| 重活走槽 | 三次构建／三次跑腿**全部**经 `~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600`，**后台作业**，报 PID 与日志路径；禁 `tee` 回灌 |
| 显示位 | 只用 `:238`／`:239`／`:240`／`:241`（私有 `:2xx`），几何 `1280x1024x24`（装置自带）；**按 PID 收尾**，全程**未用** `pkill`／`pgrep -f`（扫 `/proc` 时显式排除 `$$` 与**祖先链**）；跑完扫 `/proc` **零残留**、`/tmp/.X11-unix` 只剩 `X0 X1` |
| 台账落自己车道 | 全部落在 `~/t103-runner/{bin,logs,bak,fixtures}`；**未落 `/tmp`** |
| 判据只收紧 | 未放宽任何既有断言；新增格 `85`（旧号 `80–84` **一个未动**）；`k_pts_entries[]` 13 名未动 |
| `NOINFO` 不当绿 | C5 来源相位／P1／P4／P5 如实 **NOINFO**（§7） |
| 只改 `inScope` | 见 §9；**未**越域 |
| 不 `git add/commit/push` | 未执行任何 `git` 写操作 |

---

## §9 边界遵守自证

**写域**（契约）：`src/WpfGfx.Linux.Native/**` ✓（`src/win32_pts.c`、`bin/libwpfwin32.so` 由构建脚本产出、`bin/exports.txt`、`tools/pts-gap-decl.txt`）｜`build/MilBridge/P1-w8-step3-report.md` ✓（本件）｜`build/MilBridge/HANDOFF-NEXT.md` 的 `cell=#1` 行 ✓｜`tests/PtsPagesProbe/evidence/**` ✓（`.so` 两代换代 ⇒ 同趟重取）。

**`git status --porcelain`（现取，`M` 行，**收尾时刻**）**：
```
 M README.md
 M build/MilBridge/HANDOFF-NEXT.md
 M build/MilBridge/tests/PtsPagesProbe/evidence/app_g1.log
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/device.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_23.env
 M build/MilBridge/tests/PtsPagesProbe/evidence/arm_A/leg_24.env
 M build/MilBridge/tests/PtsPagesProbe/evidence/device.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/device/xfwm.log
 M build/MilBridge/tests/PtsPagesProbe/evidence/five_post_g1.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/five_pre_g1.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/leg_23.env
 M build/MilBridge/tests/PtsPagesProbe/evidence/leg_24.env
 M build/MilBridge/tests/PtsPagesProbe/evidence/session.txt
 M build/MilBridge/tests/PtsPagesProbe/evidence/shots/g1/{k23,k24,last}.png
 M build/MilBridge/tools/pts-gap-count-check.sh          ← **他人件**（队长另派的"牙扫描形状"修正；本件未动）
 M docs/ROUTES.md
 M samples/WpfFeatureProbe/KNOWN-DEFECTS.md
 M src/WpfGfx.Linux.Native/src/win32_classification.c
 M src/WpfGfx.Linux.Native/src/win32_pts.c
 M src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt
```
**如实说明四件事**：
1. `evidence/**` 的 `M` 行是**本件同趟重取**（`.so` 两代换代 ⇒ 契约授权范围）。在册证据是**受版本管理**的件 ⇒ 与 `HM` 一并如实列出。
2. `docs/ROUTES.md`／`README.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`win32_classification.c` 四件出现在 `M` 行，是**同趟复述位同步**（`实现口径 90→89`，因 `impl` 真实下降 ⇒ 牙的**整件扫描**要求现值位随动，见 C3）。其中 `docs/ROUTES.md`／`samples/**` **不在**本件写域清单里 ⇒ **这一点我如实报请队长裁**：若判定越域，请在回执里点名，我照办回退该四件的 `89` 改动（**C3 会随即转红**，因为牙要求现值位 == live `89`）。
3. ⚠️ `KNOWN-DEFECTS.md` 在 `M` 列表里**还包含 `t104` 的并发写入**（他同期在同一件上做历史行恢复）—— 本件只改了其中的**现值行**（`2263` 一处 `实现口径 90→89`），**未动** `:2257` 历史行。
4. `build/MilBridge/tools/pts-gap-count-check.sh` 的 `M` 行是**他人件**（队长另派的修正，`101 6` 行）⇒ **不是**本件所改；本件 `tools/**` 只动了 `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`（它在写域内）。其余 `??` 行（`evidence/arm_A/**`、`src/tests/`）全属他人，本件未动。

**未做**：未 `dotnet build` 整趟门禁、未跑 `verify-all.sh`／`close-wave.sh`、未改哨兵、未改判据件、未改 `tools/**`、未改 `build/PresentationFramework.Linux/**`。

---

### 结语（自包含）

- **① 补了什么**：`LoGetPenaltyModuleInternalHandle` 由**诚实缺口 stub** 升为**真实现**（句柄身份校验／出参按对象绑定／成败各一对计数／观测镜指针域／新格 `85`），并**同趟修掉三处实测缺陷** —— ①主链被拒断言**串变量**把真句柄清成 NULL（拆 `q4`）；②**实现真错**：`NULL` 罚分句柄落到身份扫描命中 `penalty_module_handle==NULL` 的在册对象而**返回 0**（加显式 NULL 拒绝）；③**反腿抓出**格 `85` 在**净腿上没有牙**（夹具前置状态使然）⇒ 夹具先建"只建不 acquire"的活对象 ⇒ 净腿也有牙。**判定链与实现语义未动。**
- **② 前进的主证据**：`entry=` 主跳 **3 → 0**、`unknown` 0、前沿 **`after=LoDisposePenaltyModule@3 ≠ 主跳`**、`PTSGAP=PASS`、`impl 90→89`（缺口真少一条）。
- **③ 两页不劣化**：`alive=yes app_rc=143`、`native_gap=2`、`PTS_GUARD=PASS`；页面级**可见降级**（洋红占位）**不是**"两页真排版"。
- **④ 诚实红／NOINFO**：C5 来源相位、P1／P4／P5 全 **NOINFO**；`SSC=FAIL`（`.so` 两次换代、哨兵位待队长刷）；`STATICJAWS` 他人族未动；复述位四件越域疑点已报请裁。
- **⑤ 纪律**：28 `HANDOFF_MV=PASS`｜29 备份面 ≡ 换代面｜30 三格 ＋ 调用序 ＋ 两种误导形态（**"fresh 的绿 ＝ 假绿"本趟有实证**）。
- **⑥ 同趟性**：`same=yes`（`so16=` ＝ `DEV shim=` ＝ 现盘 `.so` ＝ `a2de5ff2b667f33f`；`carrier_sha16=bf59ef38f5b8be55` ＝ `app_g1.log` 实值）。

---

`P1-W8-STEP3-REPORT 自证（`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 191f511203333827（口径＝末行之前的全文；末行＝本行）`

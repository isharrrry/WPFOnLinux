# P1-W37 · `t111` 余项关账报告（`t113`／`scribe`）—— `F-1` 判据补格 ＋ `O-1`/`O-2`/`O-3` 口径 ＋ `F-3` 同趟性如实记

写者 `scribe`（`t113` attempt 2／`3b32fd81-969f-4d61-9089-6bf93fcb3fd8`）｜仓根 `/home/links-dev/netTest/GitProj/WPFOnLinux`（分支 `feat-Linux`）｜读时 `2026-09-29T03:0x+0800`
**一切读数现取自算**（`t111` 的复核只当线索；本席**重建了自己的夹具**）。本件**不构建、不跑腿、不占显示位、不跑整趟门禁**；**判据/口径面**为主，**未碰产品件实现**。
**写域** ＝ `build/MilBridge/P1-w8-step4-criteria.md`（dated 追加）＋ `build/MilBridge/P1-w8-step4-verify.md`（dated 追加）＋ `docs/ROUTES.md §15af`（追一行）＋ `build/MilBridge/HANDOFF-NEXT.md`（纪律族**索引行**一行）＋ 本载体（新建）。**未**动 `src/**`（`O-2` 的路线见 §3）、`build/PresentationFramework.Linux/**`、`verify-all.sh`／`close-wave.sh`／哨兵／`samples/**`／`tests/PtsPagesProbe/evidence/**`。

## §0 一句话

`F-1` 按**（甲）** 处置：判据 `§1.6①` **补一格**「**只承诺 `NULL` 拒绝**；非 `NULL` 指针可读性**不可先验** ⇒ 记 `NOINFO(前置不可先验)`、**不构成红**」，并把我现取的**成对读数**（`NULL` ⇒ 干净拒绝 `rc=-10000`；`PROT_NONE` 页 ⇒ **段错误 `rc=139`**）与「**与同族三端口的不对称来自职责差**」写清；`O-1` 落**下标映射表**；`O-2` **我现取不能复现**「报表与端口不一致」（`doc_sets=2 == PtsDocCreates()=2`）⇒ 仍按派单**在册写死该格语义**并记 `NOINFO(复现失败)`；`O-3` 落「环容量 ＝ 4、覆盖序 ＝ 最近 4 条」并入**纪律第 `30` 条族**（不新立号）；`F-3` 如实记「**两轴都不同代**、完整的同趟换代排在字体栈阻断解除之后」。

## §1 `F-1`（medium）—— 判据补格（**成对读数 ＋ 机理 ＋ 不对称**）

**成对读数（本席自造夹具、仓外、`python3`＋`ctypes` 直调现盘 `.so` `a131ea4e6f5cc4f5`；两例各**独立进程**）**：

| 入参形态 | 现取读数 |
|---|---|
| **`NULL`** | `CreateDocContext(NULL,&out)` ⇒ **`rc=-10000`**、`*out` 被清成 `NULL`、`PtsDocCreates()=0`、`PtsDocLive()=0`、报表 `doc_rej=1` ⇒ **干净拒绝（一个字节都不读）** |
| **非 `NULL` 而不可读**（`libc.mmap(PROT_NONE)` 一页） | 夹具先印 `BEFORE_CALL PROT_NONE page=0x…` ⇒ **调用内**死亡 ⇒ shell `段错误`、**`rc=139`** |

**机理（我自读现盘原文）**：`CreateDocContext` 在两条 `NULL` 检查之后**按偏移读入参结构**：`b+0`＝`version`、`b+4`＝`fsffi`、`b+12`＝`cInstalledObjects`、`b+16`／`b+24`／`b+32` 三个指针**只当值取、不 deref** ⇒ **"入参可读"是隐含前置**，`NULL` 只是"可读性最平凡的特例"。
**不对称（我自读现盘原文）**：`LoSetDoc`（`wpf_pts_loc_find(ploc)`）／`LoAcquirePenaltyModule`／`LoGetPenaltyModuleInternalHandle` 都是**先按指针身份在在册表里查**、**不 deref** 入参 ⇒ 它们对"非 `NULL` 但不可读"**安全**；`CreateDocContext` 是**唯一**把入参结构**读内容**的入口 ⇒ 不对称**来自职责差**（它要"带走入参里的可判定量"），**不是实现疏漏**。
**处置（甲）＋理由**：**只承诺 `NULL` 拒绝**；该形态**今日不可达**（托管调用点恒传 `ref FSCONTEXTINFO`）⇒ 记 `NOINFO(前置不可先验)`、**不构成红**；**不许**写成"必须修否则红"（把关口前移到不可达形态＝判据不诚实），**也不许**静默抹掉（要升成"可判前置"须由 native 侧声明契约或加句柄/长度校验 ＝ **产品面**改动 ⇒ **另派单**，本件不改 `src/**`）。
**落点**：`build/MilBridge/P1-w8-step4-criteria.md` 的 `t113` dated 段（`F-1` 小节；原文**一字未删**，段末给出新的自报口径值）。

## §2 `O-1`（观察）—— `PtsDocFieldAt` 的**下标语义**（现取）

```
FIELDAT idx=0 i=0 => 0x11111111        version
FIELDAT idx=0 i=1 => 0x22222222        fsffi
FIELDAT idx=0 i=2 => 0x7               cInstalledObjects
FIELDAT idx=0 i=3 => 0x7c02be7e9000    info_addr ← **记账槽（"哪个入参结构地址"）**，不是第四个托管字段
FIELDAT idx=0 i=4 => 0x4444444444444444 pInstalledObjects
FIELDAT idx=0 i=5 => 0x5555555555555555 pfsclient
FIELDAT idx=0 i=6 => 0x6666666666666666 ptsPenaltyModule
```
⇒ **映射表（自读现盘 `switch`）**：`0,1,2` 之后**跳一格**到 `4,5,6`；**引用该读口必须按此表**，**禁止**"第 N 个字段"读法；且它**是位置读**（`idx` 是**当前**登记表位置）⇒ **不得跨销毁缓存 `idx`**（与 `…PtsPenaltyModuleHandleAt` 同族，`t102` 已在册）。落点：判据件 `t113` 段（`O-1` 小节）。

## §3 `O-2`（观察）—— 报表 `doc_sets=` 的口径：**我现取不能复现**不一致，但口径写死如下

**现取（两次成功 create、同进程同表）**：
```
CREATE#1 rc=0 handle=0x…    CREATE#2 rc=0 handle=0x…
PORT   creates=2 live=2 destroys=0
REPORT doc_live=2 doc_sets=2 doc_rej=0 doc_des=0 doc_desrej=0      ⇒ doc_sets == PtsDocCreates() == 2
REPORT_len=343   （< 256? 否 —— 现取 343 B：托管侧 256 B 缓冲必 `-1` ⇒ `t87` 的放大重试正是为此）
```
**字段映射（自读现盘 `snprintf` 实参表）**：`doc_live=%d doc_sets=%d doc_rej=%d doc_des=%d doc_desrej=%d` 依次吃 `g_pts_doc_live_n`／**`g_pts_doc_sets_c`**／`g_pts_doc_rejected_c`／`g_pts_doc_destroys`／`g_pts_doc_destroy_rej` ⇒ **`doc_sets=` 就是 `CreateDocContext` 的成功数**（＝ 端口 `WpfLinuxWin32_PtsDocCreates()` 返回的**同一个变量**）。
**口径（逐字，防读错）**：**`doc_sets=` ＝ `CreateDocContext` 成功数（＝ `PtsDocCreates()`）**；**`setdoc_sets=` 才是 `LoSetDoc` 成功数** —— 两者**同族不同名**，只看报表者**务必按字段名分辨**。
**`t111` 的 `doc_sets=0` 本席未复现** ⇒ 记 **`NOINFO(复现失败)`**；最可能成因（**假设，未验证**）：用**另一进程**（夹具）的 `PtsDocCreates()` 对**另一处**的报表读数，或报表读数取自 create**之前**的快照。
**为什么本件不改 `src/**`**：该格**现取一致**（无缺陷可修）；若后人仍要把"报表那一格与端口逐字段绑定"，那是**产品面**改动 ⇒ 须另派单，并**同趟跟随** `nm`／`exports.txt`／`pts-gap-decl.txt`（本件禁构建 ⇒ 改了也**不可验证**）。落点：判据件 `t113` 段（`O-2` 小节）＋ `verify` 的 `t113` 段。

## §4 `O-3`（观察）—— 观测镜环的**容量与覆盖序**（现取）→ 并入纪律第 `30` 条族

**现取（同进程，6 次 push、`ploc` 各不同）**：**push#1／#2 ⇒ `rc=0`（已被驱逐）**；**push#3..#6 ⇒ `rc=1`（可检索）** ⇒ **环容量 ＝ 4**（自读原文：`#define WPF_PTS_JMP_MAX 4`；`g_pts_jmp[4]`），**覆盖序 ＝ "最近 4 条"**（检索 `idx=0` 最新、向前追）。另：同进程**先有 2 条**（两次 create）再 push 4 条 ⇒ **最早那 2 条探不到** ✓。
**口径（逐字）**：凡用 `WpfLinuxWin32_PtsJmpProbe` 追链的判据，**必须**同时写明 ①**环容量**（今天 ＝ 4）②**覆盖序假设**（只覆盖**最近 4 条**；更早条目**已被驱逐** ⇒ **`rc=0` ≠ "该调用没发生"**）。**缺任一项 ⇒ 该读数不许当证据**。
**归属**：**并入纪律第 `30` 条族**（**不新立条号**；它约束的是同一类仪器同一类误读：30 条管**进程史**、本条管**环容量**）；`t110` 自报的「环满」（该入口由 stub 变真后链 push 从 3 条变 4 条、正好写满 4 格环）＝**本机制的第一个实例**。**落点**：判据件 `t113` 段 ＋ `HANDOFF-NEXT.md` 纪律族索引的一行（指向第 `30` 条，**不复写条本体**）。

## §5 `F-3`（low）—— 同趟性如实记

```
leg_23.env  shim=a2de5ff2b667f33f  pf=6893d1d3fb1ee110   alive=yes app_rc=143   （上一代）
leg_24.env  shim=a131ea4e6f5cc4f5  pf=2988f5154ecacdd   alive=no  app_rc=134   （本代）
```
⇒ **两轴都不同代** ⇒ `C7` 的"三者逐位相同"**今日不成立**（成因：`leg_24` 崩在**字体栈**（`C6` 红面、与本步无因果）、`leg_23` **未跑完**）⇒ 在册写明「**完整的同趟换代排在字体栈阻断解除之后**」；此前两页成对**只能**记作**上代 vs 本代**，**不得**当"同趟成对"引用。

## §6 本席同趟复核 ＋ 不变量/指纹/牙（现取）

```
靶心达标面（与 t111 无冲突）：在册台账 `^PTS_GAP entry=` 行 **0** ｜ 托管 `[PTS-UNAVAILABLE]` **0** ｜ `.so` `nm -D` ＝ `bin/exports.txt` ＝ **572**
产物（现取）：`libwpfwin32.so` ＝ a131ea4e6f5cc4f5 ｜ Release／部署件 ＝ 2988f5154ecacdd（**t109 那代，本件未重建**）
不变量：`^run_step "` ＝ 62 ｜ 覆盖面 ＝ 234 ｜ `62 gen=#81` ＝ 1 ｜ `--expect 234` ＝ 1 ⇒ 四条未变
覆盖面成员（本席现算）：本件五件（`P1-w8-step4-criteria`／`…-verify`／`…-close-report`／`docs/ROUTES.md`／`HANDOFF-NEXT.md`）**各 0** ⇒ **无 `cell=#1` 登记义务**（本件未改任何覆盖面内件）
指纹：fp 现取 c086995a786ac10697e73c83ef942d39a355d4d1f381c9725099d7be29ebefba（ts=2026-09-29T03:06:28.387274185+0800）—— 只作"本席读数时刻"记录，**不追写**
牙：REPORTID=PASS files=248 ids=2202 declared=224（本载体落盘前）｜HANDOFF_MV=PASS cells=9 equal=8 manual=1 mismatch=0 ｜ DEFREG=PASS declared=224 route_ids=224
    **DEFREG_DECLDRIFT=1 changed-route-files-since-DECL-GEN keys=KD**（他者面：KD 的声明锚与 route 面位移 ⇒ 须持 `--emit` 权限者同趟刷新；本件写域不含它）
    SENTINEL-SPEC：**SSC=PASS**（现取 13 个 key 全 `SSC_VALUE=PASS`；哨兵现取 `PF=2988f5154ecacdd`／`WIN32SHIM=a131ea4e6f5cc4f5` ＝ **现盘两件** ⇒ 与队长刚做的合规重写一致）
    SHELL_QUOTE_TRAP=PASS traps=0 ｜ PIPEFAIL_SIGPIPE=PASS undeclared_hit=0 ｜ **STATICJAWS=PASS n=32 excluded=30 noinfo=1 n_total=62（0 HIT）**
```

## §7 未做项 / `NOINFO` ＋ 边界自证 ＋ 备份面

- **未做①（`O-2` 的"报表格与端口逐字段绑定"）**：见 §3（现取一致 ⇒ 无缺陷可修；真要改＝产品面改动且**本件禁构建**⇒不可验证）⇒ 如需，请另派单并同趟跟随 `nm`／`exports.txt`／`pts-gap-decl.txt`。
- **未做②（`F-1` 的 native 侧前置契约）**：派单**明禁**改 `src/**`；已在判据里写明"**升成契约**"的路径（native 声明"入参可读"或加句柄/长度校验），交队长排。
- **`NOINFO`（`O-2` 的复现失败）**：`t111` 的 `doc_sets=0` 本席**未复现**（我现取 `doc_sets=2 == PtsDocCreates()=2`）；成因**未验证**（最可能是跨进程/跨快照对拍）⇒ 如实记，**不折绿**（该格今天仍**没有**"与端口不一致"的已证缺陷，也**不能**凭我一次读数就宣布复核者错）。
- **`NOINFO`（`F-1` 的"今日不可达"证明）**：我以**签名/调用点**（托管恒传 `ref FSCONTEXTINFO`）为据，**未**把应用真跑起来验证"没有别的调用点"（禁跑腿）⇒ 该"不可达"是**代码面论证**，非运行面实测。
- **边界自证**：`git status --porcelain` 里属于**本席**的改动只有 ` M build/MilBridge/P1-w8-step4-criteria.md`、` M build/MilBridge/P1-w8-step4-verify.md`、` M docs/ROUTES.md`、` M build/MilBridge/HANDOFF-NEXT.md`（**仅纪律族索引一行**）、`?? build/MilBridge/P1-w8-step4-close-report.md`；`src/**`、`build/PresentationFramework.Linux/**`、`verify-all.sh`／`close-wave.sh`／哨兵／`samples/**`／`tests/PtsPagesProbe/evidence/**` **零碰**；**未**跑整趟门禁／**未**构建／**未**跑腿／**未**占显示位／**未** `git add|commit|push`；**夹具全在仓外**（`~/w281-scribe/t113/probe.py` 等），**收尾删净**。
- **备份面 ≡ 改动面（第 `29` 条）**：改动面 4 件（+1 新建无前像）≡ 备份面 `~/w281-scribe/bak/{P1-w8-step4-criteria.md,P1-w8-step4-verify.md,ROUTES.md,HANDOFF-NEXT.md}.pre-t113`（写前逐件 `stat -c %h` ＝ **1** ＋ `cp -p`）；**只增不改机器证**：逐件 `diff <备份> <现值> | grep -c '^<'` ＝ **0**。
- **第 `30` 条**：本件引用的"环容量/覆盖序"读数**同趟给出**：进程新鲜度（每条夹具**独立进程**）＋ 关键前置量（`push` 次数与顺序）＋ 判词（`rc`），**不混淆 fresh 与带历史**。

**本件自证**：`head -n -1 build/MilBridge/P1-w8-step4-close-report.md | sha256sum | cut -c1-16` ＝ b225beed48a45613（本行系末行；上列各节即被哈希的全文）

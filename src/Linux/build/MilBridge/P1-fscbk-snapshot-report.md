# P1-W61 · 承重前置 `PRECOND-FSCBK-SNAPSHOT-IN-DOC` —— native 侧持有一张**值拷贝**的回调表快照

> **本件是 `t141`（runner）的交付**：只做判据件 `build/MilBridge/P1-drive-probe-criteria.md`（243 行／`09a09b557fd4551f`／末行自证 `8a1a5d37c745103f`）里那一**条**承重前置 —— 在 `CreateDocContext` 的**调用期内**把 `FSCONTEXTINFO+40..+864`（**103 个 8 B 字**）**值拷贝**进 native 自己的 doc 对象。
> **边界（硬）**：写域 ＝ `src/WpfGfx.Linux.Native/**`（`src/win32_pts.c`／`bin/exports.txt`／`tools/pts-gap-decl.txt`）＋本件 ＋ `build/MilBridge/P1-realized-probe-report.md`（第 8 条小事）。**未碰** `build/MilBridge/tools/**`／`docs/**`／`samples/**`／任何 `.cs`／两枚哨兵／判据件；**相位位 `phase=degraded` 未动**；未跑整趟门禁；未 `git add/commit/push`。
> **明确不做（判据 ⑨ 排期含义）**：**不做**驱动探针本体（不调 `pfnGetNextSection`／`pfnGetMainTextSegment`）；**不在** `CreateDocContext` 里拿 `0`／伪值**硬试**任何回调（那只会换来一次**不可捕获的** `FailFast`）；**不动托管侧任何 `.cs`**（`PtsCache.Linux.cs` 的 `[FSCBK-CANARY]` 保持现状）。
> **契约引用**：判据件（上引）与 `t133` 载体 `P1-fscbk-offsets-report.md`（`94ec8e09efd75e60…`）／`t138` 载体 `P1-fscbk-slot-recon.md`（现盘代 `1d1e46bb31a97aa8…`）只作**口径/偏移值**引用；**它们的读数一条未抄**，本件所有值现取。
> **表述纪律（判据 ⑨，写死）**：本件的绿**只准**读成「**native 已能持有一张与调用期内逐字相等的回调表快照**」；**不得**读成"回调链已通／段落模型已成／排版打通"。
> **落盘顺序**：先落最小载体（本节 ＋ §1 ＋ §2 ＋ 自报口径行）⇒ 其后**原地追加**读数（§3 起）。

---

## §0 本件要立的那一条（照判据件原文，不放松）

> **`PRECOND-FSCBK-SNAPSHOT-IN-DOC`**：**native 必须在 `CreateDocContext` 的调用期内，把 `FSCONTEXTINFO+40..+864` 的 103 个 8 B 字拷进我们自己的 doc 对象**。

**为什么必须"拷"而不能"存指针"**（判据件 §1.3 现取的三条，本件**自己复核过**）：

| # | 现取事实 | 现取位 |
|---|---|---|
| ① | 入参是**托管对象字段的地址**：`PTS.CreateDocContext(ref _contextPool[index].ContextInfo, out context)`，而 `internal PTS.FSCONTEXTINFO ContextInfo;` 是 **`ContextDesc` 的字段** ⇒ CLR 只保证**封送期间**有效 ⇒ 跨调用持有 ＝ **use-after-return** | `build/PresentationFramework.Linux/PtsCache.Linux.cs:548`／`:965` |
| ② | 现取 `wpf_pts_doc` **没有**这张表（只存 `info_addr`／`version`／`fsffi`／`c_installed_objects`／`p_installed_objects`／`p_fsclient`(+24)／`pts_penalty_module`(+32)） | `src/WpfGfx.Linux.Native/src/win32_pts.c`（`wpf_pts_doc`，本件改前的形状） |
| ③ | 今天的回读仪器 `wpf_pts_fscbk_probe` 把 103 字读进**栈上局部 `w[]`**、打印后**不留存**（它是测量/指纹仪器，不是"可调用的通路"） | 同件（`t133` 落的函数） |

⇒ **判据 ⑨ 的排期含义**：`CreateDocContext` 有表无 **section 句柄**、`FsCreatePage*` 有句柄无表 ⇒ **本前置正是"把两者凑齐"的那一步**（判据件 §1.3 `PRECOND-CALL-WINDOW`）；但**本件只落这一段**，探针本体不在本件。

---

## §1 实现点（本件落下的四处改动，全部纯 native）

| # | 改动 | 作用 |
|---|---|---|
| **A** | `wpf_pts_doc` 新增三个字段：`unsigned char fscbk_snap[824]`（**值副本**）＋ `int fscbk_snap_state`（`0 NONE`／`1 ALLZERO`／`2 VALUE`）＋ `int fscbk_snap_nonzero` | 快照的**存区**；三态让「未快照」与「已快照但全 0」**不同形**（判据 2／6(d)） |
| **B** | `wpf_pts_fscbk_snapshot(c, info)`：`memcpy(c->fscbk_snap, (const unsigned char *)info + 40, 824)` ＋ 逐 8 B 字统计非零数 ＋ 判词行 `[FSCBK-SNAP] … state=… slot56=… slot80=…`；`info==NULL` ⇒ `[FSCBK-SNAP-GAP] reason=null-info` | **值拷贝**本体；**响亮失败＋具名留痕** |
| **C** | `CreateDocContext` 四条**拒绝**路径各补一行具名留痕（`null-out-param`／`null-info`／`table-full`／`alloc-fail`）；快照**失败即 `free(c)` 并拒绝**（**绝不**登记"看起来有表、其实没拷"的对象）；快照调用放在 `t133` 探针**之前** | 判据 2 的"不许静默 stub／假成功" |
| **D** | 六个**只读口**：`…PtsDocFscbkSnapState(idx)`／`…SnapNonzero(idx)`／`…SnapGap()`／`…SnapTaken()`／`…SnapAllZero()`／`…PtsDocFscbkWordAt(idx,k,out)`（按**8 B 无符号整数**给单个槽，失败**一个字节都不写**） | 判据 3 的"按真实类型逐字段给形状"；跨调用期读回的入口 |

**编译期钉死（判据 5）**：新增 7 条 `_Static_assert`（快照区大小＝824／字数＝103／起点＝40／起点对齐／`40+824 ≤ 872`／＋夹具结构 `fscbk` 偏移与起点同源）——与 `t133` 那 13 条**同族、不重复定义任何常量**（`WPF_PTS_FSCBK_OFF`／`SIZE` 的**唯一定义处**上移到 `wpf_pts_doc` 之前）。

**硬纪律**（判据件 §1.4）：本件**只读拷贝**、**一个回调都不调**、**不 deref** 任何入参指针、**不硬试**任何槽。

---

## §2 判据 1 的成对读数：**值拷贝**（能证伪的那一条）

**取法（车道夹具 `~/t123-runner/logs/t141/fixture_snap.c`，fresh 进程，`dlopen` 现盘 `.so`）**：
① 造形状合法的合成 `FSCONTEXTINFO`，窗口 103 字填**可辨识**值 ⇒ 夹具**自己留一份真值 `truth[103]`**（＝**调用期内**的窗口）；
② `CreateDocContext(base,&ctx)` ⇒ 快照发生；
③ **把源缓冲区整段改写**（`0xD0D0…`）—— 这一步是关键：**若 native 存的是指针，读回必变**；
④ 用只读口 `…PtsDocFscbkWordAt(idx,k,&w)` 逐字读回快照 103 字，与 `truth` 比。

| 读数 | 值 |
|---|---|
| 调用期内（夹具真值，窗口首字） | `0x4000000000000000` |
| 源缓冲区改写后（**与调用期内不同**） | `0xd0d0d0d000000000` |
| **调用期后**读回（逐字比对） | **`equal=103/103`**、`first_mismatch_word=-1` |
| 判词 | **`LEG=A_valuecopy_verdict PASS`** ⇒ **真拷贝**（存指针则此处必 `<103`） |

**app 侧那一半（同趟，真实上下文）**：日志 `[FSCBK-SNAP] entry=CreateDocContext … bytes=824 words=103 **nonzero=71** state=VALUE slot56=nonzero slot80=nonzero taken=1..3 allzero=0 gap=0`（**3 个真实 doc 上下文各一行**；`gap=0` ⇒ 主链上**没有**任何"未快照"）。
⚠️ **交叉核对（非本轮同源）**：`nonzero=71` 与 `t133` 独立测得的整窗 `nonnull=71`（`nulls=32 pred_nulls=32`）**相同** ⇒ 两台仪器对同一张表给出一致的非零槽数。
⚠️ **如实记（限制）**：**app 侧只有"调用期内"那一半**（`[FSCBK-SNAP]` ＋ `t133` 的 `[FSCBK-WORD]`）—— 因为**app 里没有任何代码会调用新增只读口** ⇒ "调用期后逐字相等"这一对**由夹具提供**（见 §7 的 `NOINFO` 面）。

---

## §3 判据 2：**三态可分**（不许"看起来有表、其实全 0"）

| 态 | 现场构造 | 现取读数（机器可读） | 说 明 |
|---|---|---|---|
| **「未快照」（响亮拒绝）** | `CreateDocContext(NULL,&ctx)`／`(base,NULL)` | `rc=-10000`、`ctx=NULL`、`…PtsDocLive()` **不变**（0→0）、具名行 `[FSCBK-SNAP-GAP] … reason=null-info … state=NONE`（另一次 `reason=null-out-param`）；`…SnapState(-1) = -1`、`…SnapNonzero(-1) = -1` | **对象根本没登记** ⇒ 外部看到的是"**没有这个对象**"＋一行具名拒绝；**不是**静默 0 |
| **「快照了但全 0」** | 窗口整段 0（形状字段合法） | `rc=0`、`state=**1**`、`nonzero=**0**`、`allzero=1` | 表**在册**、但**空** ⇒ 与上一态**不同形** |
| **「快照非全 0」** | 窗口 103 字全非 0 | `rc=0`、`state=**2**`、`nonzero=**103**`（app 侧真实上下文为 **71**） | 正常态 |

**四条拒绝路径全部具名**（判据 2 的"响亮失败"）：`null-out-param`／`null-info`／`table-full`／`alloc-fail`（后两条在夹具里未逐条构造 ⇒ 见 §7 `NOINFO`-3；**代码路径已具名**，夹具只覆盖了前两条）。
**快照失败即拒收**：`if (c->fscbk_snap_state == WPF_PTS_FSCBK_SNAP_NONE) { free(c); return …; }` ⇒ **绝不**登记半成品。

---

## §4 判据 6：**四腿**成对读数（车道夹具，`SNAP_FIXTURE=PASS`）

| 腿 | 构造 | 现取读数 | 判词 |
|---|---|---|---|
| **(a) 正极** | 真形状结构（窗口全非 0） | `rc=0`、`state=2`、`nonzero=103`、**源改写后 `equal=103/103`** | **PASS**（值拷贝 ＋ 逐字相等） |
| **(b) 反极 A（错形状）** | `NULL` 入参／空出参 | `rc=-10000` ×2、`ctx=NULL`、`live` 不变、具名 `[FSCBK-SNAP-GAP]` 行、`state(-1)=-1` | **必红并点名**（**不是**静默 0） |
| **(c) 反极 B（窗口起点 ±8）** | 入参基址改 `base±8` | `rc=0`（**不崩**）、`state=2`、**`equal_vs_truth=0/103`**（`first_mismatch_word=0`） | **有分辨力**（与真值**全不相同**） |
| **(d) 反极 C（三态判词不同）** | 见 §3 | 未快照 ⇒ `-1` ＋具名行 ＋无对象；全 0 ⇒ `1/0`；非全 0 ⇒ `2/103` | **判词三者互不相同** |

纪律 30 三格（夹具，fresh 进程）：① **进程新鲜度** ＝ fresh（`CELL1 live=0 taken=0 gap=0 allzero=0`；调用序：A 建/毁 → D 建/毁 → B1/B2 拒绝 → C±8 建/毁）；② **关键前置量** ＝ `taken=4 gap=2 allzero=1 live=0`（末态，**出参全部回收、无残留**）；③ **判词** ＝ 各腿 `rc` 见上＋ `SNAP_FIXTURE=PASS`。
⚠️ **夹具自伤一处（如实记）**：首版把 `state/nonzero` 放到**对象已回收之后**的判词表达式里取 ⇒ 得到 `SNAP_FIXTURE=FAIL`（**夹具缺陷、非产品缺陷**）；改为**存活期取数**后 `PASS`（`t127` 同族教训的镜像面）。

---

## §5 同趟读数：导出面／症状面／留痕面

- **导出面**：`nm = exports.txt = **600**`（改前 `594`）⇒ **+6**，逐名：`WpfLinuxWin32_PtsDocFscbkSnapState`／`…SnapNonzero`／`…SnapGap`／`…SnapTaken`／`…SnapAllZero`／`WpfLinuxWin32_PtsDocFscbkWordAt`（**全部为新增**；`git diff` 对 `bin/exports.txt`）——**无导出消失**（`^Fs=6` 不变）。
- **`SRCS`**：**未新增源件** ⇒ `build-shim.sh` 的 `SRCS` **10 条 ＝ `src/*.c` 实际 10 件**（差集 0，未动该数组）。
- **症状面（零回归）**：本趟车道腿（落 `~/t123-runner/logs/t141/legs/`，**不覆盖在册 `evidence/**`** —— 本件写域不含它）：两腿 `alive=yes`／`app_rc=143`／`magenta=0`／`colors=383`／`ink=480000`；`NAMED managed_unavail=0`；`FAILLINE failfast=0 unrec=0`；`DEV shim=73cd9bacd610cbe8`（＝现盘）`pf=c52d9191feb5ba7c`。与**在册上一代**（载体 `evidence/**`，代际 `shim=5ddc9d63b5232f96`）**逐格相同**。
- **`ENFE` 面 ＋ 留痕面（缺一不得判绿）**：`enfe=0`、`failfast=0`、`unrec=0`、`unavail=0`、`PTS_GAP entry=0`、`fontfb=6`；留痕面 `[FS_PAGE_GAP]=**1067**`、`[HC-UNHANDLED]=**1067**`、`[FSCBK-SNAP]=**3**`、`[FSCBK-SNAP-GAP]=**0**`。⚠️ **跨代不相减**：`1067`（本代）与 `1117`（`t133` 那一代）**并列**，差不解释。
- **`sync-applocal --check`**：`SYNC-APPLOCAL=PASS items=5 ok=5 drift=0`。

---

## §6 `_Static_assert` 清单（判据 5）

**本件新增 7 条**（与 `t133` 那 13 条**同族、不重复定义任何常量**）：
1. `sizeof(((wpf_pts_doc *)0)->fscbk_snap) == WPF_PTS_FSCBK_SIZE`（快照区大小 = 824）
2. `WPF_PTS_FSCBK_SNAP_WORDS == 103`
3. `WPF_PTS_FSCBK_OFF == 40`
4. `WPF_PTS_FSCBK_SIZE == 824`
5. `WPF_PTS_FSCBK_OFF % 8 == 0`（起点对齐）
6. `WPF_PTS_FSCBK_OFF + WPF_PTS_FSCBK_SIZE <= WPF_PTS_FSCONTEXTINFO_SIZE`（**40+824=864 ≤ 872** ⇒ 窗口在界内）
7. `offsetof(wpf_pts_fsctx_probe, fscbk) == WPF_PTS_FSCBK_OFF`（夹具结构的 `fscbk` 偏移与快照窗口起点**同源**）

**唯一定义处**：`WPF_PTS_FSCBK_OFF`／`WPF_PTS_FSCBK_SIZE` 已**上移**到 `wpf_pts_doc` 之前（doc 的快照字段要用到）；`t133` 那一块处只留一行说明、**不再重复定义**（避免宏重定义/双源）。`_Static_assert` 只能钉**本文件自己的声明**；"封送方的布局确实如此"仍由 `t133` 的现场回读承担（本件未改其仪器）。

---

## §7 逐件成对读数 ＋ 第 8 条小事 ＋ `NOINFO`

**① 逐件 sha16 ＋ `numstat`**

| 件 | 改前 sha16 | 改后 sha16 | `numstat` |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `26af5a26b984b99e` | **`ce0a759491b3b2f0`** | `168 6` |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `5ddc9d63b5232f96` | **`73cd9bacd610cbe8`** | （构建产物） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `5293609825fc3d66` | **`5abbcaf5a06cc4f8`** | `6 0`（＋6 名） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `5f05b6c1db4a60ee` | **`918dbaf15581438f`** | `1 1`（只改 `so16=`／`exports=` 两个 token） |
| `build/MilBridge/P1-realized-probe-report.md`（第 8 条） | `186c918f2937d355` | **`7249ccc0146782b1`** | `1 1` |
| 本件载体 `P1-fscbk-snapshot-report.md` | （新建） | 见末行自证 | — |

**② 第 8 条（`t119` 欠账）成对读数**：末行原为字面 `PLACEHOLDER` ⇒ 填 **`ab2a7748b54a7b7b`**（`t136` 给的值）；当场复算 `head -n -1 <本件> | sha256sum | cut -c1-16` ＝ **`ab2a7748b54a7b7b`** ⇒ **MATCH**（**与我现算一致**，不是照抄）。⚠️ 件内仍有 **1** 处 `PLACEHOLDER` 字样 ＝ **第 178 行 `t136` 的历史陈述句**（"本件末行自证仍是字面 `PLACEHOLDER`…"）—— 本件**未改它**（改动面最小；改它会使末行自证重算：任何追加/插入都会改变 `head -n -1` 的哈希）。**该句现已过期**，如需对齐请由件主按 dated 追加处理。
**③ 顺带**：`pts-gap-decl.txt` 的两个 token 同步后，`pts-gap-count-check.sh` **`PTSGAP=PASS`（rc=0）** —— `so16`／`exports` 两条 `DRIFT` 由本件消掉，且**先前那条 `SITE-DRIFT docs/ROUTES.md` 已由他者修复**（本件未碰该件）。

**④ `NOINFO` 清册（本件回答不了的）**

| # | 问题 | 为什么答不了 | 消掉需要 |
|---|---|---|---|
| 1 | **app 侧**"调用期后读回快照"的成对读数 | app 里**没有任何代码**会调用新增只读口（本件只加口、不加调用点） | 一个托管/装置侧的读回调用点（另派单） |
| 2 | 快照里 **`+56`／`+80` 是否"就是"那两个回调** | 本件只按**8 B 值**给形状，**不 deref、不试调**（判据件 §1.4 的硬纪律）⇒ "是哪条回调"由 `t133` 的对照（canary/指纹）承担，本件**不重复主张** | 驱动探针（下一件） |
| 3 | `table-full`／`alloc-fail` 两条拒绝路径的**现场构造** | 夹具只造了 `null-info`／`null-out-param`（`table-full` 需先占满 8 个上下文；`alloc-fail` 不可控） | 夹具扩充（另派单）；**代码路径已具名**（不是静默） |
| 4 | 快照与**托管侧**`_unmanagedHandles` 的任何关系 | 那是托管表状态，native 看不到（承 `t130`） | 托管侧只读口 |
| 5 | "回调链是否已通／段落模型是否已成／排版是否打通" | **本件根本没碰回调调用**（判据 ⑨ 明确不做） | 驱动探针 ＋ 后续波 |

---

## §8 齐尾：假进度必红／纪律／边界

- **P1–P9 处置**：P1（伪造 `nms`）**本件不调任何回调** ⇒ 不适用；P2／P3／P4／P5 属**探针**面 ⇒ 本件未做；**P6（主链 `FailFast`）**：主链 `failfast=0`、`[FSCBK-SNAP-GAP]=0`（`state=NONE` 出现的次数为 0）；**P7（错偏移仍绿）**：本件正面回答 —— 窗口起点 `±8` ⇒ `equal_vs_truth=0/103`（**判词不同**）；**P8（恒绿自检）**：夹具 `SNAP_FIXTURE` 有牙（见 §4 的四腿，且首版因**夹具缺陷**一度 `FAIL` ⇒ 证明它不是恒绿）；**P9（静默）**：四条拒绝路径全部具名。
- **纪律 30**：见 §4 三格；**"净腿不崩＝假绿"**：两页症状面**逐格相同**这件事**在本件里只是"零回归"的证据，不是"快照成功"的证据** —— 后者的证据是 §2／§3 的**逐字相等与三态**。
- **纪律 28**：本件改了**覆盖面内件**（`src/**` 与 `bin/exports.txt` 均在 `fp_inputs()` 面内）⇒ 触发**成立**；但派单**明确**：`HANDOFF-NEXT.md` 的 `cell=#1` **由队长收口**、本件**不得登记** ⇒ 如实记「**有意未登记**」；现取 `HANDOFF_MV=DIVERGED reason=cell-mismatch #1:covered-file-changed-since-ts`（**预期**，由队长收口）。
- **纪律 29**：备份面 ＝ `~/t123-runner/bak/{win32_pts.c.pre-t141, pts-gap-decl.txt.pre-t141, P1-realized-probe-report.md.pre-t141}`；无 `cp -p` 回拷（源件按正常路径修改、构建按 `build-shim.sh`）。
- **重活走槽**：构建（`held=3s`）与两页腿（`held=31s`）均 `heavy-slot` **后台**（`logs/t141/{build,legs}.out`），未 `tee` 回灌。
- **资源／显示位**：跑前 `MemAvailable 4556000 kB`／腿前 `3848164`／收尾 `4079192 kB`；`SwapFree ≥ 1390844 kB`；`df` 可用 ≈ 69 GB。显示位只用 `:237`；`/tmp/.X11-unix/` 仅 `X0`／`X1`（非本件所起）；未用 `pkill`／`pgrep -f`。
- **边界**：改动面 ＝ `src/WpfGfx.Linux.Native/{src/win32_pts.c,bin/exports.txt,tools/pts-gap-decl.txt}` ＋ 本件 ＋ `build/MilBridge/P1-realized-probe-report.md`（第 8 条）⇒ **全部在写域内**；**未碰** `build/MilBridge/tools/**`／`docs/**`／`samples/**`／任何 `.cs`／两枚哨兵／判据件／`HANDOFF-NEXT.md`；**相位位未动**；未跑整趟门禁；未 `git add/commit/push`。
- **一处代际后果（如实报，不由本件改）**：`.so` 换代后两枚哨兵的 `WIN32SHIM` 位不一致 —— 现取 `SSC_VALUE=FAIL key=WIN32SHIM got=5ddc9d63b5232f96 want=73cd9bacd610cbe8`（哨兵**不在本件写域**）⇒ 连带 `sentinel-spec-check.sh` `rc=1`、`static-jaws-check.sh` 的 2 条 `HIT` ＝ `SENTINEL-SPEC` ＋ `HANDOFF-MV`（**均预期、均在写域外**）。
- **表述纪律（判据 ⑨）**：本件的绿**只准**读成「**native 已能持有一张与调用期内逐字相等的回调表快照**」；**不得**读成"回调链已通／段落模型已成／排版打通"。
`P1-FSCBK-SNAPSHOT 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ b54633f65641c06d（末行＝本行）`

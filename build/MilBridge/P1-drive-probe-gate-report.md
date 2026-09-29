# P1-W68 · 驱动探针的**运行期闸**（缺省关）＋ `[DRIVE-PROBE-ENTER]` 入口留痕 ＋ T3 反腿

> **本件是 `t148`（runner）的交付**，执行**裁定三十六 (b)(c)**：`t146` 量出"两代唯一源码差＝探针 ⇒ 帧面变了（`+80` 懒创建改了渲染）"，故 **不保留常开** —— 加**运行期闸、缺省关**；并新立口径：**`in_empty_set=no`／"帧变了"绝不能读成进度**（否则打开探针这一纯副作用就能把 `N1` 要件①凑成"成立" ⇒ 与 `N4`「登记即算」**同族**的第二个假绿通道）。
> **边界（硬）**：写域 ＝ `src/WpfGfx.Linux.Native/**` ＋ 本件。**未碰** `build/MilBridge/tools/**`（`t147` 在飞）／`docs/**`／任何 `.cs`／两枚哨兵／判据件／`HANDOFF-NEXT.md` 的 `cell=#1`（**队长收口**）⇒ 本件**有意未登记** `cell=#1`。**相位位 `phase=degraded` 未动**；未跑整趟门禁；未 `git add/commit/push`。
> **口径（写死，判据 ⑦）**：本件绿**只准**读成「**探针在被显式打开时才产生副作用；缺省关闭时零调用**」；**不得**读成"驱动链已通／段落模型已成／排版打通"，**也不得**把"帧变了"读成进度。
> **落盘顺序**：先落最小载体（本节 ＋ §1 ＋ §2 ＋ 自报口径行）⇒ 其后**原地追加**读数（§3 起）。

---

## §0 靶心（三条，照裁定）

| # | 要做的事 | 判据 |
|---|---|---|
| **1** | **运行期闸**：`WPF_PTS_DRIVE_PROBE=1`（非 `0`、非空）才开；**缺省关** | 闸关 ⇒ **一次都不调**（机读"调用计数 = 0"＋`reason=gate-off` 具名行）；闸开 ⇒ 读数与 `t146` 一致 |
| **2** | **`[DRIVE-PROBE-ENTER]` 入口留痕**：打在**首次回调调用之前** | 反腿日志里**必须**出现该行（`probe>0`）⇒ 归因强度由 `t146` 的**中**升为**强** |
| **3** | **T3 反腿**：用**live 但类型不对**的句柄去调 | 合法做到 ⇒ 给成对读数；做不到 ⇒ **具名 `NOINFO`**（**不许**拿 T2 冒充 T3） |

**为什么必须加闸（`t146` 的现取事实）**：`+80` 的托管实现**懒创建** `new ContainerParagraph` ⇒ 改了托管段落树 ⇒ 改了渲染：`fr_sha ef3fd6765f18f51b → b273ebecc332fc03`、`fr_ae_boot 15386 → 14775`、`colors 383 → 391`（症状门逐格未变）。⇒ 常开＝把"帧变了"这一个人为副作用**混进** `N1`/`N3` 的读数面。

---

## §1 实现点（纯 native，三处）

| # | 改动 | 说明 |
|---|---|---|
| **A** | `wpf_pts_drive_probe_enabled()`：**取一次并缓存**（`static int cached = -1`）读 `getenv("WPF_PTS_DRIVE_PROBE")`；`非空 ∧ ≠ "0"` ⇒ 开 | 缺省（未设/空/`0`）⇒ **关**；闸关时 `wpf_pts_drive_probe_skip("gate-off")` ⇒ **具名行＋计数**，**一次回调都不调** |
| **B** | `[DRIVE-PROBE-ENTER] where=… nms=… pfsclient=… slot56=… slot80=… fake=… t3mode=… window=…`，位置＝**所有前置检查之后、首次调用之前** | 反腿的 `FailFast` 发生在首调内 ⇒ 该行仍在日志里 ⇒ **归因强** |
| **C** | **T3 模式**（编译期 `-DWPF_PTS_DRIVE_PROBE_FAKE_NMS=-2`，**只在副本产物**）：先用**真** `sect` 调 `+80` 拿到 **live 的 `ContainerParagraph` 句柄**（打印 `[DRIVE-PROBE-T3] stage=create-live-wrong-type …`），再拿它（**live 但类型不对**）去调 `+56` ⇒ 期望托管侧 `as Section` 得 null ⇒ `ValidateHandle(null)` 抛 ⇒ **可捕获** ⇒ `fserr = -100002` | 与 T1（越界 `0x1000` ⇒ `:247` FailFast）／T2（空闲槽 `0x2` ⇒ `:248` FailFast）**按类分开** |
| **D** | 新只读口 `WpfLinuxWin32_PtsDriveProbeGate()`（1 开／0 关） | 闸状态的**机读**面（与 `…Calls()`／`…Skips()` 并列） |

**非目标（照裁定）**：不改判据件／阈值；不翻相位位；不改托管侧一个字节；不动 `t147` 在飞的 `tools/**`。


---

## §2 闸关／闸开两态读数（判据 ②）

| 代际 | `.so` shim | `colors` | `ae_boot` | `fr_sha` | **探针调用** | 说明 |
|---|---|---|---|---|---|---|
| `t141`（**探针引入前**） | `73cd9bacd610cbe8` | **383** | **15386** | **`ef3fd6765f18f51b`** | n/a（无探针） | 基准代 |
| `t146`（**探针常开**） | `4618f9f2be1c7682` | **391** | **14775** | **`b273ebecc332fc03`** | 1 窗／4 调 | **唯一的异常样本**（见 §3） |
| `t148` `legs-off`（**缺省关**） | `980a00d41320227e` | **383** | **15386** | **`ef3fd6765f18f51b`** | **0** | **逐格回到基准代** |
| `t148` `legs-on`（**显式开**） | `980a00d41320227e` | **383** | **15386** | **`ef3fd6765f18f51b`** | **1** | **帧面与"关"完全相同** |
| `t148` `legs-off2`（关，第二样本） | `980a00d41320227e` | **383** | **15386** | **`ef3fd6765f18f51b`** | **0** | 确定性抽样 |

**闸关（缺省）的机读读数**：`[DRIVE-PROBE]` 命中 **0**、`[DRIVE-PROBE-ENTER]` 命中 **0**、`[DRIVE-PROBE-SKIP] reason=**gate-off**` × **3**（`skips=3`，打印上限 3）⇒ **一次回调都没调**，且**闸关状态在日志里可见**（不是静默）。`…PtsDriveProbeGate()` 新口报 `0`。
**闸开的机读读数**：`[DRIVE-PROBE-ENTER] where=FsCreatePageBottomless nms=0x1 pfsclient=0x1 slot56=0x7ad6fae7ac10 slot80=0x7ad6fae7ac40 fake=0 t3mode=0 window=0` ＋ `[DRIVE-PROBE] … rc56a=0 fSuccess1=0 nmsNext1=(nil) … idem56=1 rc80a=0 nmSeg1=**0x2** rc80b=0 nmSeg2=**0x2** idem80=1 v56=NEXTSECTION-ABSENT(by-design) v80=MAINTEXTSEG-LIVE-HANDLE` ⇒ **与 `t146` 逐项一致**（`+80` ⇒ `0x2`、`fserr=0`、`idem=1`；`+56` ⇒ by-design）⇒ **可复现**。
**症状门（三趟全同）**：`alive=yes app_rc=143 magenta=0`、`failfast=0 unrec=0`、`enfe=0 unavail=0`、`ink=480000`。

---

## §3 🔴 **一处由本件推翻的结论（诚实优先，必须上报）**

`t146` 的 `F-1` 断言：**"帧变 ＝ `+80` 懒创建的副作用"**（依据：两代之间唯一源码差＝探针）。**本件实测推翻它**：
- **闸开**（探针运行、`+80` 真返回 `0x2`、即真发生了懒创建）⇒ 帧面 **`ef3fd6765f18f51b`／`15386`／`383`**＝与**闸关**、与**探针引入前那一代**逐格相同；
- **闸关**两次独立抽样 ⇒ 帧面同样 `ef3fd6765f18f51b`／`15386`／`383`。
⇒ **"开/关探针"在本代里不改变帧面** ⇒ `t146` 那次的 `b273ebecc332fc03`／`391`／`14775` 是**该趟的离群**，**探针不是已证成因**。⇒ 严记 **`NOINFO(reason=t146 帧面离群成因未定；本代 5 个样本里 4 个一致、仅 t146 一趟不同)`**。
⚠️ 但这**不推翻闸的政策本身**（判据 ⑦ 的绿也**不**读成"闸把帧改回来了"）：① 一个**纯副作用**探针本就**不该常开**；② 按裁定三十六 (c)，**"帧变了／`in_empty_set=no`"在任何方向上都不得读成进度** —— 本件同样**不**把"帧回到基准"读成任何进展。

---

## §4 反腿（三条，副本、闸显式打开；判据 ③④）

| 副本 `.so` sha16 | 伪值／模式 | `[DRIVE-PROBE-ENTER]` | `[DRIVE-PROBE-T3]` | 终态 | **断言／`fserr`（点名）** |
|---|---|---|---|---|---|
| `0b4a6b76f2e5c6d8` | `0x1000`（越界） | ✅ **在场**（`nms=0x1000 fake=4096`） | — | `app_rc=**134**`、`unrec=2`、`failfast=1` | **`Invalid object handle.`**（`:247`）＝**T1** |
| `b71b7994200d0ffc` | `0x2`（空闲槽） | ✅ 在场（`nms=0x2 fake=2`） | — | `app_rc=**134**`、`unrec=2`、`failfast=1` | **`Handle has been already released.`**（`:248`）＝**T2** |
| `9bec75d54b4e6570` | **T3 模式**（`-2`） | ✅ 在场（`nms=0x1 fake=-2 t3mode=1`） | ✅ `stage=create-live-wrong-type rc80=0 seg=**0x2** nms_substitute=0x2` | **`app_rc=124`（timeout，进程活着）**、`unrec=**0**`、`failfast=**0**` | `[DRIVE-PROBE] … nms=0x2 … rc56a=**-100002** fSuccess1=0 nmsNext1=(nil) rc56b=-100002 idem56=1 v56=**CALLBACK-ERR**` |

- **判据 ③（`ENTER` 承重）达成**：两条 `FailFast` 反腿的日志里 **`enter=1`**（`probe=0`，因为 `FailFast` 在首调内 ⇒ 四次调用后的 `[DRIVE-PROBE]` 行来不及打）⇒ **归因强度由「中」升为「强」**：该行自证"`nms=<伪值>` 这一调确实发生了"。
- **判据 ④（T3）达成（不是 `NOINFO`）**：T3 模式先用**真** `sect` 调 `+80` 造出一个 **live 的 `ContainerParagraph` 句柄（`0x2`）**，再拿它去调 `+56` ⇒ 托管侧 `as Section` 得 null ⇒ `ValidateHandle(null)` 抛 ⇒ **可捕获** ⇒ **`fserr=-100002`（`tserrCallbackException`）**，**进程不死**（`unrec=0 failfast=0`）⇒ **三类（T1/T2/T3）现已全部按类点名**。
- **权威件前后不变**：`authority_so` 前 `980a00d41320227e`／后 `980a00d41320227e` ✓；副本各自独立 sha16 点名；Xvfb `:238` **按 PID 收尾**（`xvfb_reaped_by_pid=…`，`/tmp/.X11-unix/` 仅 `X0`／`X1`）。
- **主链零破坏五条**：①主链三趟 `failfast=0 unrec=0`；②导出面只增；③症状门逐格相同；④未新增 `[FS_PAGE_GAP]` 失败原因；⑤探针只读快照／只读口（`+80` 的懒创建是**被调方**既定语义）。

---

## §5 零行为改动面 ＋ 逐件成对读数

- **导出面**：`nm=exports=**610**`（改前 `609`，**＋1 逐名**：`WpfLinuxWin32_PtsDriveProbeGate`，**无导出消失**）、`^Fs=**6**`（不变）、`PtsDriveProbe` 族共 **10** 名。
- **两页症状门**：三趟逐格相同（见 §2 末行）。

| 件 | 改前 sha16 | 改后 sha16 | `numstat` |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | `4d9d7dad41274b31` | **`4ced3a697b3bcabc`** | `61 15`（新增闸／ENTER／T3 段；被替换的函数体记 15 删） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `4618f9f2be1c7682` | **`980a00d41320227e`** | （构建产物） |
| `src/WpfGfx.Linux.Native/bin/exports.txt` | `206db9dedf1f917a` | **`b38eef23f2673e7a`** | `1 0`（＋1 名） |
| `src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt` | `e077bfdfc7f9868a` | **`526ad8400b6bb434`** | `1 1`（只改 `so16=`／`exports=`） |
| 本件载体 `P1-drive-probe-gate-report.md` | （新建） | 见末行自证 | — |

**顺带**：`pts-gap-decl.txt` 两 token 同步后 **`PTSGAP=PASS`（rc=0）**；`REPORTID=PASS files=273`；`SYNC-APPLOCAL=PASS drift=0`；`PIPEFAIL_SIGPIPE=PASS`。

---

## §6 `NOINFO` 清册（判据 ⑥：主动点名"没跑／没核／取不到"）

| # | 项 | 为什么 | 消掉需要 |
|---|---|---|---|
| **1** | `t146` 那趟**帧面离群（`b273ebecc332fc03`／`391`／`14775`）的真实成因** | 本代 5 个样本里 4 个一致（含**闸开**），探针**不是已证成因** | 一个受控的"同代同环境、只改一样东西"的实验，或对 app 渲染做确定性排查（另派单） |
| **2** | app 渲染是否**本身不确定**（跨趟帧变） | 本件只采到 3 趟本代样本（全同）；`t119`/`t124` 在册曾见过别的帧值 ⇒ 怀疑但**未证** | 同一 `.so` 多趟重复采样 ＋ 逐趟环境记录 |
| **3** | `+80` 的懒创建**是否**在任何条件下改渲染 | 本件只证"开/关探针在**本代本环境**下帧面相同"；**不**证"永不影响" | 更多环境/次序样本 |
| **4** | 闸的**旁路**面（若有别的调用点／别的进程路径会绕过闸） | 本件只查 `FsCreatePageBottomless`／`FsCreatePageFinite` 两处调用点（本族） | 全库调用点普查（另派单） |
| **5** | `±8` 错偏移探针 | 本件**不做**（判据未要求；`t146` 已记 `NOINFO`） | 下一件 |
| **6** | T3 里 `nms_substitute` 是否**恒为** `0x2` | 本件只采到 1 次（`seg=0x2`）；槽号依赖当时表占用 | 多趟采样 |
| **7** | `WPF_PTS_DRIVE_PROBE` 的取值语义（`=true`／`=on` 等写法） | 本件口径＝"非空 ∧ ≠ `"0"`" ⇒ 这些写法都会**开**；**未**逐个实测 | 逐个取值实测（低成本，未跑） |

---

## §7 齐尾：边界／纪律／收尾牙／口径

- **边界**：改动面 ＝ `src/WpfGfx.Linux.Native/{src/win32_pts.c, bin/exports.txt, tools/pts-gap-decl.txt}` ＋ 本件 ⇒ **全部在写域内**；**未碰** `build/MilBridge/tools/**`（`t147` 在飞）／`docs/**`／`samples/**`／任何 `.cs`／两枚哨兵／判据件／`HANDOFF-NEXT.md`；**相位位 `phase=degraded` 未动**；未跑整趟门禁；未 `git add/commit/push`。
- **纪律 28**：改了覆盖面内件 ⇒ 触发成立；派单**明确** `cell=#1` 由**队长收口** ⇒ 如实记「**有意未登记**」；现取 `HANDOFF_MV=DIVERGED reason=cell-mismatch #1:covered-file-changed-since-ts`（**预期**）。
- **纪律 29**：备份面 ＝ `~/t123-runner/bak/{win32_pts.c.pre-t148, pts-gap-decl.txt.pre-t148}`；副本腿用 `cp -a` 整目录复制，**权威件未被伪值覆盖**（前后皆 `980a00d41320227e`）；无 `cp -p` 回拷。
- **纪律 30／显示位／进程**：重活（构建＋三趟腿＋三副本腿）全部 `heavy-slot` **后台**；显示位 `:237`（腿）／`:238`（副本）；**Xvfb 按 PID 收尾**；未用 `pkill`／`pgrep -f`。
- **资源线**：起点 `MemAvailable 5821116 kB`／收尾 `6197948 kB`；`SwapFree ≥ 1388540 kB` ⇒ 未越停手线。
- **收尾牙（现取）**：`PTSGAP=PASS`(0)｜`REPORTID=PASS files=273`(0)｜`SYNC-APPLOCAL=PASS drift=0`(0)｜`PIPEFAIL_SIGPIPE=PASS`(0)｜`HANDOFF_MV=DIVERGED`(1，预期)｜`SSC=FAIL`(1)：`SSC_VALUE=FAIL key=WIN32SHIM`（**哨兵由队长写**）。
- **口径（判据 ⑦，逐字）**：本件绿**只准**读成「**探针在被显式打开时才产生副作用；缺省关闭时零调用**」；**不得**读成"驱动链已通／段落模型已成／排版打通"，**也不得**把"帧回到基准"或"帧变了"读成进度。
`P1-DRIVE-PROBE-GATE 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ 8eebbf7bd0e6fdef（末行＝本行）`

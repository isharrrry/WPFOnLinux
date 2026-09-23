# W131A 报告 —— `TASK-0109` 产品修法：`wpf_x11_has_ewmh_wm()` 的"死 WM 残留"边界

- 车道：**W131A**（落地）｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是 git 仓库**，全程零 `git`）
- 时刻：`2026-09-23 10:50 → 12:05 CST`｜kernel `6.8.0-138-generic`｜`nproc=3`
- **本报告的一行结论**：`has_ewmh_wm()` 从"**属性在不在**"升级为"**属性在 ∧ 那个检查窗此刻在树里**"⇒
  WM 死后属性残留时不再被骗，**移动/改尺寸**与**最大/还原**两条路径**都**回到各自早就写好的
  "没有 EWMH WM"退化支 ⇒ 红腿全数转绿，且**活 WM 分支逐字未变**。

---

## ① 判据（**先写**，写定时刻 ＋ sha16）

| 项 | 值 |
|---|---|
| 判据文件 | `$HOME/w131a/criteria.md`（**本车道自己写定的原文**，不是转述） |
| 写定时刻 | `2026-09-23 10:56 CST`（**早于本车道任何 X 读数**；此前只做过静态 `read`/`grep`/`sha256sum`/`nm -D`/`cp -p`） |
| 加注 A1（**加注不覆盖**） | `11:12 CST` —— 只补"`site=wmstate` 的 `at_target` 口径"，理由与"为什么不算事后挪判据"逐字写在 §12 里 |
| `sha16`（含加注，**现场算**） | `045477a20ac256df`｜120 行 |
| 判据的承重口径 | 三态（§2）／四段腿（§3）／假绿 `FG1…FG9`（§4）／机读行形状（§5）／分母（§6）／两极化两层（§7）／零回归四格（§8）／自我否证（§10） |

**基线（写判据时刻现场算）**：`win32_x11.c 11142fbef049eb66`｜`win32_core.c 3117923a7c899e05`｜
`win32_internal.h e4f2de8d038e4780`｜`libwpfwin32.so bd037229be8db4f6`（327,256 B）｜导出 **547**。
全份 `cp -p` 备份在 `~/w131a/backup/*.orig`。

---

## ② 修法（逐处 diff ＋ 源级 before/after sha16）

**只动三个文件，六个 hunk**（`diff -u` 全文留档 `~/w131a/out/fix.diff`，229 行）：

| 文件 | 增/删 | hunk（修前行号） | 内容 |
|---|---|---|---|
| `win32_x11.c` | **+103 / −2** | `@@1673`、`@@1685` | `has_ewmh_wm()`：**语义升级（M1）** ＋ 临时错误处理器 ＋ 一次性大声失败行 ＋ 诊断行 |
| `win32_x11.c` | （同上文件） | `@@1796`、`@@1816` | `moveresize` 站点：**分支自报**（`branch=`，仪器，语义零改） |
| `win32_core.c` | **+37 / −1** | `@@486` | 新增 `static` 诊断助手 `wpf_wmck_diag()`（**静态 ⇒ 不新增导出**） |
| `win32_core.c` | （同上文件） | `@@650`、`@@659` | 窗态站点：**分支自报** ＋ 兜底目标落盘（仪器，语义零改） |
| `win32_internal.h` | **+5 / −1** | `@@609` | **只改声明注释**，跟上新语义 |

**关键实现（`M1`）**——`wpf_x11_has_ewmh_wm()` 现在：
1. 读 `_NET_SUPPORTING_WM_CHECK`；`format=32` ⇒ 取那个 `Window` id，**掩到 32 位**
   （实测：Xlib 会把 32 位属性值**符号扩展** —— 写 `0xdeadbeef` 读回 `0xffffffffdeadbeef`；
   不掩则下面按 `resourceid` 过滤会失配）；
2. `id == 0 || id == root` ⇒ **直接判否**（EWMH 规定 WM 写的是**它自己建的检查窗**，不是 root）；
3. 否则**临时**装一个只记账的错误处理器 ＋ `XGetWindowAttributes()` ＋ `XSync` 逼出异步错 ＋ **换回原来那个**
   ⇒ `st == 0 || xerr != 0` ⇒ 判否（**不按错误码过滤**：同一语义在 `XGetWindowAttributes` 上是
   `BadWindow(3)`、在 `XGetGeometry` 上是 `9(BadDrawable)`）；
4. 处理器里**按 `resourceid` 过滤**（错误处理器是**进程级**的，别的线程的错不能被误读成"WM 死了"）；
5. `M3`：判定为"残留"时**无条件打一次**（每进程一条，**不需要 env**）：
   `[WMCHECK_STALE] … (wm_win=0x… xerr=…) ⇒ 视为**没有 EWMH WM**，改走无 WM 兜底路径`。

**逐条说明"为什么不是别的方向"（都是 W130A 已实测排除的，本车道复核其读码）**：
- ❌ 接 `XSendEvent` 的返回值：对 root 发 `SubstructureRedirectMask|SubstructureNotifyMask` 时，
  返回值在**活 WM／死 WM／无 WM 三相都 = 1**（X 只报"发出去了"）；
- ❌ 查 `_NET_SUPPORTED` 非空：WM 死后它照样在（现场 `n=78`）；
- ⚠️ 必须自带错误处理器：不装时 Xlib 默认处理器会 `exit(1)` 把进程带走（比原缺陷更糟）；
  （本 shim 构造期已装**非致命**的 `wpf_x_error_handler`（`win32_x11.c:86`/`:112`）⇒ 本层是**双保险**，
  仍然自带是为了不把判据建在"别人的全局状态恰好装好了"上。）

**代价（如实登记）**：谓词每次调用多**一次 X 往返**（`XGetWindowAttributes` ＋ `XSync`）。
实测整条 `moveresize` 调用：活 WM 腿 修前 `14 µs` → 修后 `90 µs`（单样本，见 §③）；
**刻意不做缓存** —— 缓存活性的任何 ms 级窗口都会把本缺陷"按时间窗重新打开"。

**源级 before/after**：`win32_x11.c 11142fbef049eb66 → 9fa20864404ab01b`｜`win32_core.c 3117923a7c899e05 → a9cc8762908b417a`｜
`win32_internal.h e4f2de8d038e4780 → 4e1880e6054635ff`。

**语义射程逐处判**（该谓词全仓**只有 2 个调用点**，`grep -rn` 实测）：
1. `win32_x11.c:1797`（`wpf_x11_moveresize_window`，本任务本体）——`use_wm=0` ⇒ 走 `XMoveResizeWindow`（`:1815`）；
2. `win32_core.c:653`（`wpf_core_window_state`，最大/还原）——`=0` ⇒ 走"按工作区自算"退化支。
   **逐处判影响**：两处在活 WM 下都**照旧**走 EWMH 支（§③ 的活 WM 腿逐字相同）；无 WM 下都照旧走退化支
   （§③ 的 `nowm` 腿逐字相同）；**只有"属性残留但窗没了"这一相变了**，而那正是缺陷相。

---

## ③ 三态读数（**四段一窗贯穿**，同一 display、同一探针进程）

**装置**：私有 `Xvfb :231`（1280x1024x24）＋ 自起 `xfwm4`（按 PID 收，收工残留 **0**）。
探针 `~/w131a/probe/t109fix.c` 用 **FIFO 命令**驱动（`~/w131a/run-grid.sh`）⇒ 外部
`xprop`/`xwininfo`/`wm-awaited.sh` 的**原文读数**与产品动作**同刻交错**。
探针用**产品自己的 API** 建一个真窗（`RegisterClassExW` ＋ `CreateWindowExW`）—— 这样
`wpf_core_window_state` 的窗口表才命中（`site=wmstate` 那一半**必须**这样才量得到）。

**修前（`win32shim=bd037229be8db4f6`）**：`T109_SUMMARY=OK s1=True s2=True green=7 red=5 noinfo=0`
**修后（`win32shim=a6365183fa6d26b9`）**：`green=12 red=0 noinfo=0`（**仓内交付件** ✅；同一读数在 `$HOME` 沙箱预验件上**逐行相同**）
**反极性（复原 ＋ 重建 ⇒ 件级回到 `bd037229be8db4f6`）**：`green=7 red=5 noinfo=0`（**逐行同修前**，归一化后 `diff` 空）

| # | `site` | `leg` | **修前**（仓内冻结件 `bd037229be8db4f6`） | **修后**（仓内交付件 `a6365183fa6d26b9`） | **反极性**（复原＋重建 ⇒ 件级回到 `bd037229be8db4f6`） |
|---|---|---|---|---|---|
| 1 | `moveresize` | `nowm` | **GREEN** `moved=1` `at_target=1` | **GREEN** `moved=1` `at_target=1` | **GREEN** `moved=1` `at_target=1` |
| 2 | `wmstate` | `nowm` | **GREEN** `moved=1` `at_target=1(tgt=1264x984+0+0)` | **GREEN** `moved=1` `at_target=1(tgt=1264x984+0+0)` | **GREEN** `moved=1` `at_target=1(tgt=1264x984+0+0)` |
| 3 | `wmstate` | `nowm` | **GREEN** `moved=1` `at_target=1(tgt=520x380+120+140)` | **GREEN** `moved=1` `at_target=1(tgt=520x380+120+140)` | **GREEN** `moved=1` `at_target=1(tgt=520x380+120+140)` |
| 4 | `moveresize` | `live` | **GREEN** `moved=1` `at_target=1` | **GREEN** `moved=1` `at_target=1` | **GREEN** `moved=1` `at_target=1` |
| 5 | `wmstate` | `live` | **GREEN** `moved=1` `at_target=1(mode1 want_n_max=2 got=2)` | **GREEN** `moved=1` `at_target=1(mode1 want_n_max=2 got=2)` | **GREEN** `moved=1` `at_target=1(mode1 want_n_max=2 got=2)` |
| 6 | `wmstate` | `live` | **GREEN** `moved=1` `at_target=1(mode0 want_n_max=0 got=0)` | **GREEN** `moved=1` `at_target=1(mode0 want_n_max=0 got=0)` | **GREEN** `moved=1` `at_target=1(mode0 want_n_max=0 got=0)` |
| 7 | `moveresize` | `stale` | **RED** `moved=0` `at_target=0` | **GREEN** `moved=1` `at_target=1` | **RED** `moved=0` `at_target=0` |
| 8 | `wmstate` | `stale` | **RED** `moved=0` `at_target=0(tgt=1264x984+0+0)` | **GREEN** `moved=1` `at_target=1(tgt=1264x984+0+0)` | **RED** `moved=0` `at_target=0(tgt=1264x984+0+0)` |
| 9 | `wmstate` | `stale` | **RED** `moved=0` `at_target=0(tgt=520x380+120+140)` | **GREEN** `moved=1` `at_target=1(tgt=520x380+120+140)` | **RED** `moved=0` `at_target=0(tgt=520x380+120+140)` |
| 10 | `moveresize` | `adv_dead` | **RED** `moved=0` `at_target=0` | **GREEN** `moved=1` `at_target=1` | **RED** `moved=0` `at_target=0` |
| 11 | `moveresize` | `adv_root` | **RED** `moved=0` `at_target=0` | **GREEN** `moved=1` `at_target=1` | **RED** `moved=0` `at_target=0` |
| 12 | `moveresize` | `adv_noprop` | **GREEN** `moved=1` `at_target=1` | **GREEN** `moved=1` `at_target=1` | **GREEN** `moved=1` `at_target=1` |

- 修前：`OK label=BEFORE2 s1=True s2=True green=7 red=5 noinfo=0 loud_fail=0 loud_fail_line=none nowm_target={'1': '1264x984+0+0', '0': '520x380+120+140'}`
- 修后：`OK label=AFTER-REPO s1=True s2=True green=12 red=0 noinfo=0 loud_fail=1 loud_fail_line=src/WpfGfx.Linux.Native/src/win32_x11.c:1730 nowm_target={'1': '1264x984+0+0', '0': '520x380+120+140'}`
- 反极性：`OK label=ANTI-REPO s1=True s2=True green=7 red=5 noinfo=0 loud_fail=0 loud_fail_line=none nowm_target={'1': '1264x984+0+0', '0': '520x380+120+140'}`

**场景三条件（同一次运行里）**：
- `S1`（WM 真在场，用**仓内判据件**）：`WM_AWAITED=PASS c1=yes c2=yes c3=yes c4=1 display=:231`
- `S2`（残留四条，**原文**）：
  - `D1` `_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x6000ae`（`rc=0`，**属性确实残留**）
  - `D2` `X Error: 9: Bad Drawable: 0x6000ae … xwininfo: error: No such window with id 0x6000ae.`（`rc=1`）
    ⚠️ **注意这里报的是 `9: Bad Drawable`** —— 正是"只认 `BadWindow` 会漏"的现场证据
  - `D3` `wm_pid=283116 proc_gone=1`
  - `D4` `WM_AWAITED=FAIL c1=yes c2=no c3=yes`（`rc=1`）← **"残留"的机证式**：`C1` 真、`C2` 假
  - 旁证：`_NET_WORKAREA(CARDINAL) = 0, 0, 1280, 1024, …` 也残留 ⇒ 兜底支能算出目标
- `S3`：`T109_BYE calls_total=20`（探针侧计数）＋ 每条腿 `calls=` 逐条自增 ＋ 落盘的 `req=` 四元组 ＋
  `T109_DLSYM dlopen=ok has_wm=1 mrs=1 wstate=1 …`（dlsym 自证）

### 3.1 死 WM 腿：**红 → 绿**（主判据）

| 腿 | 修前 | 修后 |
|---|---|---|
| `site=moveresize` | **RED**：`has_wm=1`、`moved=0`、`geom 517x389+295+301 (不变)`、**无任何失败行** | **GREEN**：`has_wm=0`、`branch=fallback`、`geom→723x431+611+233`（**逐数等于请求**） |
| `site=wmstate`（最大） | **RED**：`moved=0`、`_NET_WM_STATE` 无变化、无失败行 | **GREEN**：`branch=fallback target=0,0,1280x1024`、`geom→1264x984+0+0` |
| `site=wmstate`（还原） | **RED**：同上 | **GREEN**：`branch=fallback target=120,140,520x380`、`geom→520x380+120+140` |

★ **`site=wmstate` 那一半的直读铁证**：修前那趟的 stderr 里有
`[WINSTATE_DIAG] APPLY_WM_STATE hwnd=0x200001 maximize=1（我们发的 _NET_WM_STATE ADD）` ——
即**确实**走了 EWMH 支并 `return` 去等一个**永远不会来的** `ConfigureNotify`；修后同一拍变成
`[WMCK_DIAG] … site=wmstate mode=1 branch=fallback target=0,0,1280x1024` 并**真的动了**。

### 3.2 活 WM 正对照腿：**逐字相同**（检测力自证 ＋ `FG9`）

| 读数 | 修前 | 修后 |
|---|---|---|
| `moveresize` | `has_wm=1`、几何 `520x380+125+169 → 517x389+300+330`（= 请求）、父链 `0x600261`（frame `530x414+120+140`） | **逐字相同**，且产品自报 `branch=ewmh` |
| `wmstate` 最大 | `→1280x1000+0+24`、`n_max 0→2`、`state=_NET_WM_STATE_MAXIMIZED_HORZ,…_VERT,…_FOCUSED` | **逐字相同**，自报 `branch=ewmh` |
| `wmstate` 还原 | `→517x389+300+330`、`n_max 2→0` | **逐字相同** |
| 谓词 | `has_wm_direct=1` | `has_wm_direct=1` |

### 3.3 无 WM 腿（`nowm`）：**逐字相同** ⇒ "兜底路径本身没坏"，且它是 `site=wmstate` 的**目标控制值**

`moveresize → 617x443+431+217`（= 请求）｜`wmstate mode1 → 1264x984+0+0`｜`wmstate mode0 → 520x380+120+140`
——三条修前修后**逐字相同** ⇒ 修后死 WM 腿的窗态目标 `1264x984+0+0` **就是**这条控制腿的值
（同一段代码、同一显示尺寸）⇒ 这才让"到了"可判（`FG1` 的守卫）。

### 3.4 对抗格 `L4`（本车道新加，**人工伪造**）

| 格 | 修前 | 修后 |
|---|---|---|
| `setprop dead`（属性指向 `0xdeadbeef`） | **RED**（`has_wm=1`、`moved=0`） | **GREEN**（`has_wm=0`、走到请求几何） |
| `setprop root`（属性指向 root 自己） | **RED**（同上） | **GREEN**（root 守卫生效） |
| `delprop`（属性删掉） | GREEN（本来就该走兜底） | GREEN（**逐字相同**） |
| 属性原文（`xprop` 回读） | `… window id # 0xdeadbeef` / `… # 0x50d` / `not found` | 同 |

⚠️ **口径**：这两格是**人工伪造**，与"WM 真死后残留"形态不同，如实单列。
⚠️ **本机 `xprop -root -set` 静默无效**（实测 `rc=0` 而属性没落）⇒ 属性由**探针自己**用
Xlib `XChangeProperty` 写（探针命令 `setprop`/`delprop`），这是仪器细节，如实登记。

### 3.5 分母口径（`D-G94`）

| 格 | 调用 | `call_rc` | 窗动 | 处置 |
|---|---|---|---|---|
| `req0`（`hwnd=0`） | 命中 `win32_x11.c:1793` early-return | `0` | `moved=0` | **剔出分母**、单独点名列 |
| `reqneg`（`w=0`） | 命中 `:1795` early-return | `0` | `moved=0` | **剔出分母**、单独点名列 |

（第三条 early-return `:1794`（`!wpf_x11_ensure()`）**本车道取不到**：要有 X 会话又让
`wpf_x11_ensure()` 失败 —— 见 §⑦ `NOINFO`。）

### 3.6 确定性门（不吃大样本）

本缺口走哪支由 `prop ∧ id 活性` **唯一决定**（不依赖时序）⇒ 主判据是**确定性**的。
本车道共跑 **8 趟**网格（`BEFORE`/`AFTER-SCRATCH` 各 1、`BEFORE2`/`AFTER2`/`ANTI` 各 1、仓内 `AFTER-REPO`/`ANTI-REPO`/`FINAL` 各 1）⇒ 同形态 **8/8**；其中**交付态跑了 2 趟**（`AFTER-REPO` 与 `FINAL`，同一件 `a6365183fa6d26b9`）⇒ 归一化后**逐行相同**。
**不报"率"**（`D-G99`）：要报必须先按 `docs/PREREG-TEMPLATE.md` 四要件 ＋
`build/MilBridge/tools/regression-decision.py` 写死趟数与功效。

---

## ④ 两极化（**源级 ＋ 件级两层**）

| 层 | 修前基线 | 修后 | 逐字节复原后 |
|---|---|---|---|
| **源级** `win32_x11.c` | `11142fbef049eb66` | `9fa20864404ab01b` | **`11142fbef049eb66`**（逐位回到基线） |
| **源级** `win32_core.c` | `3117923a7c899e05` | `a9cc8762908b417a` | **`3117923a7c899e05`** |
| **源级** `win32_internal.h` | `e4f2de8d038e4780` | `4e1880e6054635ff` | **`e4f2de8d038e4780`** |
| **件级** `libwpfwin32.so` | `bd037229be8db4f6` | `a6365183fa6d26b9` | **`bd037229be8db4f6`**（沙箱已实测 `cmp` **IDENTICAL**） |
| **行为** | `green=7 red=5` | `green=12 red=0` | **`green=7 red=5`**（红腿全数回红） |

★ **件级也逐字节闭合**（比 `w130a` §9-C 要求的"源级 ＋ 行为"更强）：`cmp 复原后件 原备份件` ⇒ **IDENTICAL**
（**沙箱与仓内各实测一次**）。
★ 反极性两侧的**逐行对照**（**仓内**那对）：`BEFORE2`（仓内冻结件）与 `ANTI-REPO`（仓内复原＋重建件）
的 12 条机读行**逐行相同**，唯一的差别是 X 服务器**每次重启都会换**的 frame 窗口 id
（`0x600261` ↔ `0x800261`）⇒ 归一化后 `diff` **空**。沙箱那对（`BEFORE2` ↔ `ANTI`）同结论。
★ 反极性是**四步闭环**（本车道实际执行顺序）：复原源件 → 重建（件级 `cmp` 回到 `bd037229be8db4f6`）→
重取网格（**红腿全数回红**）→ **重新施加补丁 ＋ 重建**（件级逐字节回到 `a6365183fa6d26b9`、
`inputs_fp` 回到 `f0e2b3e8…`）⇒ **交付态就是修后态**（现场复核见 §⑧ 九位表）。

---

## ⑤ 零回归（四格）

| 格 | 口径 | 读数 | 判 |
|---|---|---|---|
| 1 `R-GATE` | `bash $R/build/MilBridge/tools/r-gate-step.sh`（**要槽**） | `R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f src=device`（原文见下） | **✅ `crit=13/13` 逐字段同冻结基线（只 `win32shim=` 按设计变了）** |
| 2 导出数 | `nm -D --defined-only bin/libwpfwin32.so \| wc -l` | **547**（修前 547） | ✅ 未新增导出 |
| 3 活 WM | 谓词 ＋ 两处路径 | §③3.2：**逐字不变** | ✅ |
| 4 `D-G83` 四格 | ⚠️ **不在 `verify-all` 里**、装置在**别人车道**（`~/w89a/bin/**`，≈30 min 重活） | **`NOINFO`（未跑）** ＋ **静态替代**：`grep -c WM_GETMINMAXINFO ~/w131a/out/fix.diff` = **0** ⇒ 该段（`DefWindowProcW` 的 `WM_GETMINMAXINFO`）**与修前逐字相同**；导出仍 547 | ⚠️ 如实记 `NOINFO`，**不写"未跑但应仍 PASS"** |

**格 1 的原文（交付态，本车道实测，`~/w131a/logs/r-gate-after.log`）**：
```
R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577
          sabotage=none win=938x938 mem_mb=5785 win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f src=device
APP_ART win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f pf=358136b0c806ee88 wb=2e4e46e539a72cd7 bridge=feef049e9d0e313a
HEAVYSLOT=RELEASED rc=0 held=35s
```
**逐字段对照冻结基线**：`crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577
sabotage=none win=938x938 pc=722e0ab8205b7c3f src=device` —— **逐字段相同**；
只有 **`win32shim=` 从 `bd037229be8db4f6` 变成 `a6365183fa6d26b9`**（正是本件的目的），`mem_mb` 每趟本就浮动。
★ **且 `APP_ART win32shim=a6365183fa6d26b9` 证明应用目录里装的确实是新件**（`run-r-gate-legs.sh:154` 会
`sync-applocal.sh` 同步权威件 —— 所以这条读数不是"装了旧件却报新 sha"）。
★ `R_GATE` 的 13 格逐格 PASS（`c01…c13`）与本波前的读法逐字相同；`px_open=19449`/`px_closed=577` 两个像素计数**逐位相同**。

**冻结基线逐字（来自收尾链自己的两趟，`~/w126a/logs/07*.log`，逐字相同）**：
```
R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577
          sabotage=none win=938x938 mem_mb=5321/5467（冻前两趟）／5806/5592（冻后两趟） win32shim=bd037229be8db4f6 pc=722e0ab8205b7c3f src=device
```

---

## ⑥ 假绿探测器（`FG1…FG9` 逐条）

| 代号 | 抓法 | 本车道的实测 |
|---|---|---|
| `FG1` 兜底没走到窗却动了 | 请求前**连读两拍**几何相同（`baseline_static=1` **12/12 腿**）＋ **分支由产品自报** | 修后：活 WM 腿 `branch=ewmh`、死 WM/无 WM/对抗腿 `branch=fallback` ⇒ **每支都点名**；修前**没有**自报（那正是 `W130A` §10-C 的缺口）⇒ 修前只能靠 `has_wm_direct`，本车道两条都报（**互相印证**） |
| `FG2` 窗恰在目标位置 | `\|Δ\| ≥ 100`、四数互不相同、不用整数百 | 请求 `431,217,617,443`（`Σ\|Δ\|=548`）／`300,330,517,389`（`348`）／`611,233,723,431`（`632`）／`233,411,549,367`（`426`）｜修前**每一趟都先证明"基线是静的"**（两拍相同） |
| `FG3` WM 没真死 | `S2` 的 `D2`＋`D3` | `D2` `xwininfo` 失败（`No such window`）＋ `D3` `/proc/<pid>` 消失 ⇒ 双读数 |
| `FG4` 拿 `XSendEvent` 返回值当判据 | 判据只看**独立几何读数**；`sendev_rc` 只作诊断 | 本车道的机读行里**没有** `sendev` 字段；判词只看 `geom_after`/`_NET_WM_STATE`/`moved` |
| `FG5` 只读客户窗 | **两份**几何（客户窗 ＋ 父链） | 机读行 `geom_*=WxH+X+Y` ＋ `parent_*=0xID`，且父链几何单列（活 WM 腿实测 frame `530x414+120+140` 装在客户窗 `520x380+125+169` 外围，装饰偏移 `left=5 top=29`） |
| `FG6` 探针没真调产品函数 | `S3` 三条自证全要 | `T109_DLSYM dlopen=ok has_wm=1 mrs=1 wstate=1 workarea=1 defwnd=1 create=1 show=1 register=1` ＋ `calls` 逐条自增（`calls_total=20`）＋ `req` 四元组落盘；**且探针不做判词**（三态由 `verdict.py` 组装）⇒ 不自我认证 |
| `FG7` 把"变了"当"到了" | `geom_after` **逐数等于** `req`（`at_target`） | 12/12 腿 `at_target` 都判到（口径见 §12 加注 A1） |
| `FG8` 谎报"大声失败" | `loud_fail_line` 必须是**产品件里的 `file:line`** | 修后 `loud_fail=1` ＋ `loud_fail_line=src/WpfGfx.Linux.Native/src/win32_x11.c:1730`（**现场行号**，由判据脚本从产品源里 `grep` 出来，不是手抄）；修前该行**不存在**（`loud_fail=0`） |
| `FG9` 修法偷偷改了活 WM 分支 | 活 WM 腿修前/修后**逐字相同** | §③3.2 六项读数逐字相同（含 `_NET_WM_STATE` 全文与父链 id）⇒ ✅ |

---

## ⑦ `NOINFO`（逐条，**既不算绿也不算红**）

1. **`D-G83` 四格：未跑**。装置在别人车道（`~/w89a/bin/**`）、≈30 min 重活，且当时重活槽已排队 751 s；
   已给**静态替代**（该段逐字相同 ＋ 导出 547）。**不许**把静态替代读成"四格仍 PASS"。
2. **第三条 early-return（`:1794` `!wpf_x11_ensure()`）取不到**：要有 X 会话同时让 `ensure()` 失败。
   分母已按 `D-G94` 剔出并点名另两条（`:1793`／`:1795`）。
3. **`_NET_STATE` 的"死 WM 腿该不该有 `MAXIMIZED_*`"：本车道不判**。无 WM 时产品走的是
   "按工作区自算"的**几何**退化支，**没有人**去写 `_NET_WM_STATE`（那是 WM 的职责）⇒
   修后死 WM 腿 `n_max_after=0` 是**既有的无 WM 契约**（`nowm` 腿修前也一样），不是本修法引入的。
   本车道只报该读数，**不**声明"状态位语义已正确"。
4. **端到端产品面（真 WPF 应用拖动标题栏 / 双击标题栏最大化）未测**：要 `dotnet` ＋ 应用，
   属别的车道/门禁的射程；本车道只到"**product 函数层**"。
   ⇒ "用户在真实应用里拖动不再丢一次"这句话**本报告不作断言**。
5. **多线程并发下错误处理器被临时替换的那一拍**:本车道**没有**并发探针 ⇒
   "另一个线程同时出错时诊断行会不会丢一条"**未测**（只做了静态论证：按 `resourceid` 过滤 ⇒ 不会误判分支）。
6. **`XGetWindowAttributes` 之外的三个候选 liveness API 未在本修法里用**（`XQueryTree`/`XGetWindowProperty`/
   `XGetGeometry`）⇒ "换一个 API 会不会更快/更稳"未测（`W130A` 已测其**失败形态**：`BadWindow` vs `BadDrawable`）。
7. **延迟只报了单样本**（活 WM 腿 `14→90 µs`）⇒ 不是分布；本车道**不**据此下"性能无影响"的结论。
8. **`xprop -root -set` 为什么静默无效未归因**（实测 `rc=0` 而属性没落）；已绕开（探针自己写）。

---

## ⑧ 世代影响

| 项 | 修前 | 修后 |
|---|---|---|
| `win32shim`（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`） | `bd037229be8db4f6`（327,256 B） | **`a6365183fa6d26b9`**（327,512 B） |
| 导出数 | 547 | **547**（**不新增导出**：新增的两件助手都是 `static`） |
| `inputs_fp` | `84fd55d384e93203317d22601cec854d518e69c8f026006231302a2cfbc93366` | **`f0e2b3e8c058cdf017031360a2cc292ffd6ab7b91b4a8ae47c100c3877522bd7`**（**必变** —— `src/WpfGfx.Linux.Native/**/*.{c,h}` 在覆盖面内；**且只有这三件变**，见 §12.2-T7） |
| 其余八位（**现场算**，口径 = `close-wave.sh:371-380`，`SELFBUILT_CONFIG=Release`） | 见下表 | **本件一字节未碰**（证据见下） |
| 未动件 | `build/shims/**`、`build/PresentationCore.Linux/**`、`build/PresentationFramework.Linux/**`、`build/DirectWrite.Linux/**`、`known-red.json`、册/地图/声明表、`verify-all.sh`、四个路由件 | **一字节未动** |


**九位现场复算（本车道交付态，`~/w131a/out/nine-positions.txt`）**：

| 位 | sha16 | 与冻结 `#52` 的关系 |
|---|---|---|
| `bridge` | `feef049e9d0e313a` | 未动（R-GATE 的 `APP_ART` 同值） |
| `pc` | `722e0ab8205b7c3f` | 未动（**与冻后两趟的 `R_GATE … pc=` 同值**） |
| `pf` | `358136b0c806ee88` | 未动（`APP_ART` 同值） |
| `windowsbase` | `2e4e46e539a72cd7` | 未动（`APP_ART` 同值） |
| `provider` | `1f9511a7ef395bfe` | 未动 |
| **`win32shim`** | **`a6365183fa6d26b9`** | ★ **本件唯一位移**（修前 `bd037229be8db4f6`） |
| `wic_shim` | `f7b3026c8c019be2` | 未动 |
| `hbtextline` | `921ba9c65e9fb3be` | 未动（且它**在 `fp_inputs()` 覆盖面内** ⇒ §12.2-T7 的影子树证明覆盖它） |
| `dwf` | `ce3469f49efcbcfa` | 未动（**Release 口径**，与派单书给的冻结 Release 值逐位相同） |

**"其余八位未动"的两条机器证**：
① **影子树证明**（§12.2-T7）：`inputs_fp()` 覆盖面 **149 件**里，只有 `win32_x11.c`/`win32_core.c`/`win32_internal.h`
   三件与修前不同 —— 而该覆盖面**含** `build/shims/**/*.cs`（= `hbtextline`）与 `src/WpfGfx.Linux/**`；
② **本车道全程只跑过 `bash build-shim.sh`**（它只编 `src/WpfGfx.Linux.Native/src/*.c` 并链接出
   `bin/libwpfwin32.so`，**不碰任何托管件**）；`pc`/`pf`/`wb`/`bridge` 的现场值与**收尾链自己的两趟读数同值**。

**流程含义（供主控）**：本件**必移动 `inputs_fp` 与 `win32shim`** ⇒ 收尾链必须**重钉世代**（`repin-generation.py --why`）＋**重冻**；
且**动这件必须排在 `IN_FP_0` 采样之前**（`fp_inputs()` 从 `#49` 起纳入 `src/WpfGfx.Linux.Native/**/*.{c,h}`）。

**顺带记一条口径（主控点名要）**：`verify-all.sh` **不重建** `libwpfwin32.so`
（`grep -n 'build-shim' verify-all.sh` = 0 命中；全仓只有 `close-wave.sh` 与两个 `run-*.sh` 调 `build-shim.sh`，
`verify-all.sh` 不调它们）——但**这不能推出"换件无害"**：第 `[26]` 步 `R-GATE` 会打 `win32shim=` 的 sha16
（`r-gate-step.sh:153/347`），换件会让"冻后两趟"当场自相矛盾。**这就是本车道等到 `POST_ALL_DONE` 的原因。**

---

## ⑨ 冻后 ×2 自证（**改 `src/**` 之前**）

**闸门自证（在写 `src/**` 之前取）**：

```
=== 闸门自证（改 src/** 之前）===
11:45:29
1:=== 冻后第 1 趟 10:50:02 ===
122:POST1_OUTER_RC=0
123:=== 冻后第 2 趟 11:17:00 ===
244:POST2_OUTER_RC=0
245:=== POST_ALL_DONE 11:45:11 ===
verify_all_procs=4

=== 冻后两趟的 R_GATE（冻结基线）===
      · 自报口径 R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 mem_mb=5806 win32shim=bd037229be8db4f6 pc=722e0ab8205b7c3f src=device
      · 自报口径 R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938 mem_mb=5592 win32shim=bd037229be8db4f6 pc=722e0ab8205b7c3f src=device

=== 两趟 VERIFYALL 结论 ===
69:      · 自报口径 VERIFYALL_SELF=PASS names=27 decl=27 gen=#52 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=0cdd12547a634b37
119: 结论：✅ 全部通过
191:      · 自报口径 VERIFYALL_SELF=PASS names=27 decl=27 gen=#52 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=0cdd12547a634b37
241: 结论：✅ 全部通过

verify_all_procs = 0（改前最后一拍扫 /proc/*/cmdline，无 verify-all）
```

**冻后两趟逐字（`~/w126a/logs/09-post.log`）**：

```
第 1 趟：HEAVYSLOT=ACQUIRED waited=751s → HEAVYSLOT=RELEASED rc=0 held=867s → POST1_OUTER_RC=0
第 2 趟：HEAVYSLOT=ACQUIRED waited=837s → HEAVYSLOT=RELEASED rc=0 held=…  → POST2_OUTER_RC=0
POST_ALL_DONE 11:45:11
两趟 VERIFYALL_SELF=PASS names=27 decl=27 gen=#52 dup=0 order=OK prose=OK prereg=PASS dynamic_trace=NOINFO vfile_sha16=0cdd12547a634b37
两趟 结论：✅ 全部通过
```

**★ 为什么必须等它跑完（而不是"两趟构建之间"落）**：`verify-all` 第 `[26]` 步 `R-GATE` 会打
`win32shim=` 的 sha16（`r-gate-step.sh:153/347`）。两趟都读出 `win32shim=bd037229be8db4f6`
（与 `#52` 冻结块一致）。若在两趟之间换件，第 2 趟会打**新**值 ⇒ **两趟自相矛盾且都与冻结块不一致** ⇒
"冻后 ×2 = 同一棵冻结树跑两次"这条断言当场作废。主控裁定"等 `POST_ALL_DONE`"，本车道照办。

---

## ⑩ 内存三值 ＋ 负载

| 项 | 值 |
|---|---|
| `MemAvailable` 开工 / 最低 / 收工 | 开工 `10:52` → 首次实测 `11:05` **5,568 MB**；采样器（10 s 一拍）覆盖 `11:09:54 → 12:00:16`（303 拍）⇒ **最低 5,211 MB ／ 最高 6,064 MB**；收工 `12:00` **5,342 MB**（其后复量 5,760 MB）。曲线抽样：11:09 5,586｜11:19 5,648｜11:29 5,996｜11:39 5,472｜11:49 5,372｜11:59 5,529。**从未低于 1,500 MB 的槽闸门**。 |
| `loadavg` 开工 → 峰值 → 收工 | 开工 `1.90`（11:09）→ 峰值 **`2.87`**（11:51，收尾链 × 别的车道 + 我的 R-GATE）→ 收工 `1.30` |
| `oom_kill` | **`oom_kill 0`**（`/proc/vmstat`；全程零 OOM） |
| 本车道残留进程 | **0**（按 PID 收：`Xvfb :231` 每次网格后 `leftover_xvfb=0 leftover_xfwm4=0 leftover_probe=0`，共 6 趟；
`:231/:232/:233/:234` 四个 socket 收工后**都不存在**）。⚠️ 收工自查抓到 **3 处早前残留**（`:232` 探针冒烟测试、
`:233/:234` 的 `xprop` 语法试验），**已按 PID 逐个收干净**（见 §⑫ 自纠第 2 条）。（自起 X/WM **按 PID** 收；`:231` socket 收工后不存在） |
| 重活 | 全程走 `~/heavy-slot.sh`；**排队不绕槽** |

---

## ⑪ 大白话小结（≤6 行）

1. **WM 死了但 `_NET_SUPPORTING_WM_CHECK` 属性还留在 root 上**，产品却只查"属性在不在"⇒ 以为 WM 还在。
2. 于是**该走兜底的路全走了 EWMH**：发个消息给 root，**没人听** ⇒ 窗**纹丝不动**，而且**一声不吭**。
3. 这一条洞**同时害两处**：程序改几何/拖动（静默丢一次移动）**和**最大/还原（静默失效，永远等一个不会来的 `ConfigureNotify`）。
4. 修法 = 把判据改成"**属性在 ∧ 那个检查窗此刻真的在树里**"（外加"指向 root/0 也不算"），
   并让残留这件事**大声**说一次。**只动一个谓词**，两处一起好。
5. 沙箱与仓内都验：死 WM 腿 **红 → 绿**，活 WM 腿**一个字都没变**，反极性复原后**红又回来了**
   （源级＋件级都回到原样），导出数**仍 547**。
6. 没做到的：`D-G83` 四格没跑（记 `NOINFO`）、真应用里拖动没测、延迟只有单样本 —— 都写在 §⑦。

---

## ⑫ 仪器、产物与自纠（**可复算**）

### 12.1 产物清单

| 件 | 路径 | sha16（现场算） |
|---|---|---|
| 判据（本车道原文 ＋ 加注 A1） | `$HOME/w131a/criteria.md` | `045477a20ac256df`（120 行） |
| 施加器（**唯一入口**，六锚点预检） | `$HOME/w131a/apply-fix.py` | 9a03d1e562a575fd |
| 探针源码（FIFO 驱动；用产品 API 建真窗） | `$HOME/w131a/probe/t109fix.c` | f042f887e8406a4a |
| 探针二进制 | `$HOME/w131a/probe/t109fix` | c5b03d73a9110add |
| 网格驱动（四段一窗贯穿 ＋ S1/S2 原文） | `$HOME/w131a/run-grid.sh` | 31c49c3bacd705f2 |
| 判据组装器（原始读数 → 三态 ＋ 机读行） | `$HOME/w131a/verdict.py` | 29629d17b4cf52e0 |
| 三态逐格表（机器生成） | `$HOME/w131a/out/three-state-table.md` | 9304da1393cf80d1 |
| 修法 diff 全文（229 行） | `$HOME/w131a/out/fix.diff` | 73d4ffef777caf1f |
| 落地清单（逐条打勾） | `$HOME/w131a/LANDING-CHECKLIST.md` | 71d59a1b78d81aef |
| 原始读数（8 趟网格的 probe.out/err ＋ grid.log） | `$HOME/w131a/out/{probe,grid}-{BEFORE2,AFTER2,ANTI,AFTER-REPO,ANTI-REPO,FINAL}.*` | 见目录 |

### 12.2 仪器自测（**牙齿**）

| # | 牙齿 | 读数 |
|---|---|---|
| T1 | **重复施加**（源已经是修后）⇒ 必须 `rc=3` **且不写盘** | `APPLY_FAIL … 锚点出现 0 次`、`rc=3`、施加前后 `sha16` 相同 ⇒ ✅ |
| T2 | **源被改过**（在谓词块里多一行注释）⇒ 必须 `rc=3` 且**不写** | 同上，且 `int branch_ewmh` = **0** 命中、`wpf_wmcheck_stale_notice_once` = **0** ⇒ ✅ |
| T3 | ★ **最后一个锚点坏掉**（`E4B`）⇒ **一个 hunk 都不许写**（半施加防线） | `APPLY_FAIL E4B … 【预检阶段，**一个字节都没写**】`、`rc=3`、E1/E4A **都没被写**、两个干净件仍 == 基线 ⇒ ✅（这条是加了"六锚点预检"之后才成立的 —— 加之前 E1…E4A 会先落盘 = **半施加**） |
| T4 | **构建路径无关**（同一份源放到另一个路径重建） | 两个不同路径的产物 `cmp` **IDENTICAL**（`a6365183fa6d26b9`）⇒ 沙箱读数对仓内可复现 |
| T5 | **可复现性**（反极性后重新施加 ＋ 重建） | `.so` 逐字节 `cmp IDENTICAL`；`inputs_fp` 回到 `f0e2b3e8…` ⇒ ✅ |
| T6 | **`FG1` 交叉核**：产品自报 `branch=` ⇔ `dlsym` 直读 `has_wm` | 12/12 腿一致（`has_wm=1 ⇒ ewmh` 3 条；`has_wm=0 ⇒ fallback` 9 条） |
| T7 | **`inputs_fp` 影子树证明**：只有三个源件变了 | 复算覆盖面 **149 件**；当前树重算 == `f0e2b3e8…`（复制自证）；影子树（三源件回 `.orig`、其余 `symlink`）重算 == **`84fd55d3…`（修前）** ⇒ 覆盖面里**只有这三件**变过 ⇒ ✅（口径：需 `LC_ALL=C sort`，普通 `sort` 会给出另一个值 —— 已实测）|

### 12.3 自纠（**如实登记**）

1. **`verdict.py` 的两处仪器缺陷**（都在取数过程中被抓并修掉，**不是**为了让读数好看）：
   (a) 第一版用 `(site,leg)` 做字典键 ⇒ 同名腿（`nowm`/`live`/`stale` 各两拍）被后一条**覆盖** ⇒ 已改成**按出现次序配对**；
   (b) `at_target` 与 `branch` 的取值把含空格的值截断（`1(mode1`），且产品的 `req=a,b,cxd` 与探针的
   `req=a,b,c,d` 形状不同导致 `branch` 配不上 ⇒ 已按字段边界与归一化修掉。两条都是**仪器**问题，修前修后**判词集合不变**。
2. ⚠️ **我在收工时误用了 `pkill -f 'mem.log'`**（正是本波纪律禁止的那条）：它**匹配到我自己这条命令行** ⇒
   我的 shell 被 `SIGTERM`（现场报 `[killed by signal: SIGTERM]`）。**影响面**：该模式只能匹配 cmdline 里含
   字面 `mem.log` 的进程（= 我的 shell ＋ 我的采样器）；事后按 `/proc/*/cmdline` 复核**别的车道的关键进程完好**
   （`:97`/`:185`/`:188` 的 Xvfb、`w124a` 的槽与 `dotnet HandyControlDemo` 都在）。**此后一律按 PID 收**
   （`kill <pid>`），本报告后面所有收工都按 PID。
3. ⚠️ **三处早前残留**（`:232` 冒烟测试的 Xvfb、`:233`/`:234` 的 `xprop` 试验）**收工自查才发现**：
   根因是**同一条自匹配**（当时的清理循环把 `:233` 写进了自己的 `case` 模式 ⇒ 自己的 shell 命中 ⇒ 真正要杀的
   Xvfb 没被杀，而 shell 被带走 ⇒ "看起来杀过了"）。已按 PID **逐个收干净**（`274882`/`275794`/`270021`/`270018`），
   现只余**别人**的 `:0/:1/:97/:185/:188`。
4. **`xprop -root -set` 静默无效**（`rc=0` 而属性没落）⇒ 对抗格 `L4` 的属性改由**探针自己**用 Xlib 写；
   为什么无效**未归因**（见 §⑦-8）。
5. **一条本车道核过、与派单书措辞不同的口径**：派单书说"`verify-all` 不重建 `.so` ⇒ ……"——
   我实测确认"**不重建**"为真（`grep -n 'build-shim' verify-all.sh` = **0**），但**换件仍然有害**（`[26]` 读 sha16）。
   已按此执行（等 `POST_ALL_DONE`）。
6. ⚠️ **`/tmp/bridge-frozen.flag` 现场不存在**，其镜像 `~/wfp-runs/bridge-frozen.flag` 是**旧的一代**
   （`WIN32SHIM=0098234982391bbf`、`WAVE=close-wave-155140`，与当前件不符）⇒ **本车道的"当前件"一律用现场
   `sha256sum` ＋ `CURRENT-STATE.md` 的口径**，**未**引用哨兵值。该哨兵是否失同步**不属本车道写域**，仅登记。

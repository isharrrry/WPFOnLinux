# W101A · `TASK-0108` —— `D-G88` 的 `H2` 落地：**让"运行期改尺寸提示"真的到得了 X**

> 车道 **W101A**｜波 **`#51`** 第一条产品车道｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> 开工 `19:09`（`~/w101a/STATUS.md`）｜收工 `19:5x`
> **判据先写**：`~/w101a/criteria.md`（`5126a08c12c2801e`）＋ `docs/WAVE51-PREREGISTRATION.md`（`af21bdf95b848eb9`）
> —— 两者都写于本车道**第一次动产品源之前**（顺序在 `STATUS.md` 的 STEP ①/③ 之间可见）。
> 前序取证件：`build/MilBridge/W93A-report.md`（`TASK-0107`，零产品改动；§5 的 `P1`–`P4` 是本件的技术依据）。
> ⚠️ 该件在我读它之后被**别的车道**改过（我开工时全文件 sha16 = `ea7eb63bed9e3f25`，收工时 = `8228314623797d43`）⇒
> 本报告**只按我开工时读到的那一版**引用（其 §5 的 `P1`–`P4` 与 §2.2 的 4 个 `FAIL` 格）。

---

## §0 一句话结论（三态，先给判决再给证据）

| 问题 | 判决 | 一句话 |
|---|---|---|
| **`P1`＋`P2`＋`P4` 落地了吗** | **落地，且 4 格中 3 格转绿** | "终态 ＋ 次数上限"换成"**值变了才发**"（幂等）＋改尺寸真变时补一拍 ⇒ `W1-TIGHTEN`／`W2-DECLARE`／`W2-TIGHTEN` **由 `FAIL` 转 `PASS`**（两腿一致）。 |
| **4 格是否**都**转绿** | **否（3/4）** | 剩 `W3-DECLARE` **仍 `FAIL`**；`A3` 的反极性格 `W1-REVERT` 也仍红 ⇒ 两者是**同一件事**："应用改了声明但**当时没有 resize**"⇒ 没有任何触发器可打。**这一半必须由托管侧通知（`P3-a`）解决。** |
| **`P3-a`（派单书那一版）可行吗** | **不可行（决定性实测）** | `OverrideMetadata(typeof(Window), …)` **会毒死 `Window` 的类型初始化器**：它抢在 `Window..cctor()` 之前占掉"同类型 metadata"那个**唯一**槽位 ⇒ `Window.cs:50` 抛 `ArgumentException: PropertyMetadata is already registered for type 'Window'`（`DependencyProperty.cs:566`）⇒ 进程 `rc=134`。**但**合法替代（`DependencyPropertyDescriptor.AddValueChanged`）**实测可用**：调高 `MaxWidth` 也收到通知、原回调零回归。 |
| **幂等（无风暴）** | **`I1`：`W2`/`W3` 两腿 `PASS`；`W1` 两趟里红一趟** | 如实报：`W1` 的 X 侧出现过**相邻同值两次**。机制已定位（`wpf_x11_apply_wm_hints` 的 `max<min` **钳制**会把"内部元组变了"渲染成"X 属性没变"）⇒ **不许把它读成"没有风暴"**：真正的判据（X 调用次数 == 值变化次数）对 `W1` **未成立**。 |
| **零回归** | **`D-G83` 四格 `PASS`**；`0104` 四入口`26/26` = **`NOINFO`（我没跑）** | 四格在**新件**上逐字重取全绿（`667 by 500`／`521 by 417`／缺席／`reg58=0`）；26 条腿因时间与装置位置（在**别人车道**的 `~/w89a/bin/**`，每次 ≈30 min）**未跑**，如实记 `NOINFO` 并给出我做到哪一步。 |
| **反极性** | **成立，且双向逐位可复算** | 源逐字节复原 ⇒ `win32shim` 回 **`33352e5797031999`**（逐位相等）＋那 4 格回 `FAIL`（`PASS=5 FAIL=4`）＋`I3` 的冗余发布**重现**（`W3` 3 次调用/1 个值）；把修后源放回重建 ⇒ 回 **`2a297d6fee8be389`**（逐位相等）。 |

---

## §1 判据（**先写**，逐字位置）

- 全文：`~/w101a/criteria.md`（`5126a08c12c2801e`，9,147 B）＝本件**唯一**判据件；仓内预登记 `docs/WAVE51-PREREGISTRATION.md`（`af21bdf95b848eb9`）是它的收窄版（并登记波 `#51` 的世代/位预期）。
- 判决**不自己算**：正极性/反极性格一律由 **W93A 的 `judge.py`（`743286f14e0b318e`，一字未改）**按它**先写**的口径机械算
  （期望值 = 同一 stage 的**应用侧自查答案** `W93A_SELF` 的 `maxtrack`；`changed=no` ⇒ 期望"X 侧缺席"）。
- 三态 `PASS`/`FAIL`/`NOINFO`；`NOINFO` 既不算绿也不算红；`HEAVYSLOT=NOINFO`/`MAXHOLD_KILL` 那趟**作废**。
- **本件新增的两路装置**（都是"读数"不是"判据"，且都已留痕）：
  1. `~/w101a/run-w101a-legs.sh`（`cd9e2b30bca4ddf7`）＝ `run-w93a-legs.sh`（`534bde7643f03faf`）的**复制件 ＋ 一路 `xprop -spy` 打印**；探针（`~/w93a/probe/Program.cs` `df9feabcd296b950`）与 `judge.py` **一字未改**。
  2. `~/w101a/xtest-hints-spy.c`（纯 Xlib）＝"`xprop -spy` 能不能数出**每一次** `XSetWMNormalHints`"的**装置自证**（判据 `I1` 的前提）。

---

## §2 修前基线：4 个 `FAIL` 格**当场复现**

件：`win32shim` = **`33352e5797031999`**（＝冻结 `#50` 值，现场核对通过）。
两腿：`nowm`（裸 `Xvfb :183`）＋ `wm`（`Xvfb :184` ＋ `xfwm4 --compositor=off`）；各 `rc=0`，`W93A_APP rc=0`。

```
SUMMARY  A1_informative=29 PASS=5 FAIL=4 VACUOUS=20        ← 两腿**逐字相同**
SUMMARY  A3=W1-REVERT:VACUOUS                              ← 两腿相同（= W93A 先写死的那条）
```

| # | 格 | 判据行原文（`nowm` 腿；`wm` 腿同） |
|---|---|---|
| `FAIL-1` | `W1-TIGHTEN` | `expected=521x417 actual=667 by 500 app=521x417 changed=YES geo=417x313` |
| `FAIL-2` | `W2-DECLARE` | `expected=521x417 actual=<缺席> app=521x417 changed=YES geo=521x417` |
| `FAIL-3` | `W2-TIGHTEN` | `expected=313x260 actual=521 by 417 app=313x260 changed=YES geo=313x260` |
| `FAIL-4` | `W3-DECLARE` | `expected=469x365 actual=<缺席> app=469x365 changed=YES geo=438x333` |

⇒ 与 W93A §2.2 **逐格相同**（含 `geo`）⇒ 修前基线**可复现**，可以动产品。

**`I3`（幂等判据的判别力自证）在此成立**（两腿同）：

```
SPY_COUNT leg=nowm role=W1 blocks=1 distinct=1 adjacent_repeats=0
SPY_COUNT leg=nowm role=W2 blocks=2 distinct=2 adjacent_repeats=0
SPY_COUNT leg=nowm role=W3 blocks=3 distinct=1 adjacent_repeats=2      ← 冗余发布**可见**
```

`spy.W3.log` 的 3 个块**逐字相同**（`program specified minimum size: 1 by 1`）⇒ 修前件上"值没变也发 X"是真的、且**在 X 面上可观测** ⇒ `I1` 不是恒真读数。

---

## §3 改了哪几处（文件:行 ＋ diff 摘要）

**只动两个 native C 源**（不在任何 applier 的重放集里：`grep -l win32_core src/WpfGfx.Linux.Native/tools/*.py` = 空 ⇒ 手改不会被波覆盖）。

| 文件 | 修前 sha16 | 修后 sha16 | 内容 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `9aa0d2d1b1ed8d55` | **`3fb8a1c165fccdbd`** | 5 个 hunk（`diff` 变更行 145，含注释） |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `c3dbf6b936a36239` | **`06acdcae4da6b9fd`** | 1 个 hunk（变更行 20） |

**改动清单（逐条 ↔ 判据）**

| # | 判据 | 位置 | 逐字内容 |
|---|---|---|---|
| `P1` | 幂等发布 | `win32_core.c:759-812` 新 `wpf_hints_publish()` | 入口取锁 → 守谓词（非 message-only ∧ 顶层 ∧ 非 `WS_CHILD` ∧ `!hints_in_refresh`）→ **解开锁再问**（问会同步回调托管代码）→ 回锁比较 `hints_pub_{min,max}_{w,h}`：相等则 `changed=0`，**只有 `changed` 才 `wpf_x11_apply_wm_hints`** |
| `P1'` | 只问只算 | `:714-741` `wpf_ask_minmaxinfo_apply_hints()` | 签名改 `static void (HWND, const char *where, int*,int*,int*,int*)`：**不再自己写 X**（"只发应用真的改过的上限"这段语义**逐字保留**） |
| `P1''` | 删两个停止条件 | `:820-826`（注释）＋整段删除 `wpf_minmaxinfo_reask_after_map` ＋ `#define WPF_HINTS_REASK_MAX 3` | 残留引用**只在注释里**（`grep` 实证：`.c/.h` 中零个代码引用） |
| `P2` | 运行期触发器 | `:1146-1147`（`MoveWindow`）／`:1210-1212`（`SetWindowPos`） | 记 `old_w/old_h`，在 `wpf_x11_move_resize` **之后**：`if (w != old_w \|\| h != old_h) wpf_hints_publish(hwnd, "after-MoveWindow"/"after-SetWindowPos")`（`SetWindowPos` 另加 `!(flags & SWP_NOSIZE)`） |
| `P4` | 重入闸 | `win32_internal.h:326-338`（字段）＋ `:770/:787/:800`（置/清） | `hints_in_refresh` 在**问之前**置位、**比较完成后**清零 ⇒ 嵌套 `SetWindowPos` 不会递归（`hints_pub_valid`＋4 个值取代旧的两字段） |
| 调用点 | 三处**同一段代码** | `:951`（建窗，Win32 顺序不变）／`:1112`（`ShowWindow(map=1)`）／`P2` 两处 | `wpf_hints_publish(...)`；首拍 `hints_pub_valid==0` ⇒ 必发一次 |

**"不许动"的三条都对拍过**：① `D-G83` 修法本体（`app_declared` 语义）**逐字保留**；② `DefWindowProcW` 的 `case WM_GETMINMAXINFO` **no-op 一个字节没动**（我的 diff 不覆盖 `:1675-1751`）；③ 本件只动 native C ⇒ **一个 `Invariant.Assert` 都不在射程内**（那些在托管侧，零改动）；④ 波 59 语义（未声明 ⇒ 不发 `PMaxSize`）由 `max_w=0,max_h=0` 表示，**保留**。

---

## §4 修后读数（两腿）

件：`win32shim` = **`2a297d6fee8be389`**（327,240 B；原 327,248 B）。两腿各 `rc=0`、`W93A_APP rc=0`。

```
SUMMARY  A1_informative=29 PASS=8 FAIL=2 VACUOUS=19        ← **两腿逐字相同**
```

### 4.1 正极性 4 格（逐格）

| # | 格 | 修前 | **修后** | 修后判据行原文（`nowm`/`wm` 同） |
|---|---|---|---|---|
| `P-a` | `W1-TIGHTEN` | `FAIL` | **`PASS`** ✅ | `expected=521x417 actual=521 by 417 app=521x417 changed=YES geo=417x313`（wm 腿 geo=521x417，被 WM 顶回） |
| `P-b` | `W2-DECLARE` | `FAIL` | **`PASS`** ✅ | `expected=521x417 actual=521 by 417 app=521x417 changed=YES geo=521x417`（从**缺席**→**出现**） |
| `P-c` | `W2-TIGHTEN` | `FAIL` | **`PASS`** ✅ | `expected=313x260 actual=313 by 260 app=313x260 changed=YES geo=313x260` |
| `P-d` | `W3-DECLARE` | `FAIL` | **仍 `FAIL`** ❌ | `expected=469x365 actual=<缺席> app=469x365 changed=YES geo=438x333` |

### 4.2 保持不变的格

| 格 | 修前 | **修后** | 读法 |
|---|---|---|---|
| `W1-SHOW` | `PASS` | **`PASS`** ✅ | `667 by 500` 仍在（启动那一拍没坏） |
| `W2-SHOW`／`W3-SHOW` | `PASS` | **`PASS`** ✅ | 未声明 ⇒ `maximum size` **仍缺席**（**波 59 语义保住**） |
| `W2-TOGGLE`（原**正对照**） | `PASS` | **`VACUOUS`**（既非绿也非红） | ⚠️ **如实报**：修后 `W2-DECLARE` 那一拍**已经把 `521 by 417` 发出去了** ⇒ 到了 `TOGGLE` 这一步"值没变"⇒ `judge.py` 按先写口径判"本格无信息"。**这不是回归**（该格原本要证的"通道能带运行期的值"现在由 `W2-DECLARE` 自己证了），但它**不再**是正对照 ⇒ 记账时必须写明。 |
| `reg58` | `0` | **`0`** ✅ | 任何一格都没出现 `1280 by 1024`（§5 的 `D-G83` 四格另有一遍独立复算） |
| `A3` `W1-REVERT` | `VACUOUS` | **`FAIL`** ❌ | `expected=667x500 actual=521 by 417`（"提示在本窗**全程未移动**：移动过"）⇒ 撤回那一步**没发出去**（撤回 = 把 `MaxWidth` **调高**回 `640x480` ⇒ 上游不 resize ⇒ 无触发器）。**与 `P-d` 同一根因。** |

### 4.3 幂等判据 `I1`／`I2`（先写，逐窗逐腿报）

| 窗 | `nowm`（重取趟） | `wm` | `I1` 判决 |
|---|---|---|---|
| `W1` | `blocks=4 distinct=2 adjacent_repeats=1` | `blocks=4 distinct=3 adjacent_repeats=0` | **`FAIL`（2 趟里红 1 趟）** —— 不许当绿 |
| `W2` | `blocks=5 distinct=5 adjacent_repeats=0` | `blocks=5 distinct=5 adjacent_repeats=0` | **`PASS`**（两腿） |
| `W3` | `blocks=2 distinct=2 adjacent_repeats=0` | `blocks=2 distinct=2 adjacent_repeats=0` | **`PASS`**（两腿） |

`W1` 那一趟的 `spy.W1.values` 原文：
```
max=667 by 500
max=521 by 417
max=521 by 417      ← 相邻同值（I1 违规）
max=667 by 500      ← 撤回终于发出去（由后面的 HIDE/SHOW 触发）
```
**机制（已定位，不是猜）**：全仓 `wpf_x11_apply_wm_hints` 的调用者**只有一个**（`win32_core.c:808`，就在 `wpf_hints_publish` 里 —— `grep` 实证），所以重复块不可能来自第二个写点；而 `win32_x11.c:1865-1866` 对 `max` 做了 **`max = max(max, min)` 钳制** ⇒ 内部元组从 `(min 521x417, max 521x417)` 变成 `(min 521x417, max 469x365)` 这类"**max < min**"的形态时，**两次都渲染成同一个 X 属性**。⇒ `I1`（按 **X 可见值**判相邻重复）比"内部幂等"**更严**；本件**不因此放宽判据**，如实记 `W1` 未通过。
- `I2`（发布值可归因）：`667x500`／`521x417`／`313x260`／`469x365` 都能对上同 stage 的应用侧自查答案 ⇒ 该子项 `PASS`；`wm` 腿出现过一个**中间值** `max=521 by 500`（发生在两个 stage 之间）⇒ 无 stage 采样可对 ⇒ 该子项 **`NOINFO`**（不拿"看起来合理"当已归因）。

### 4.4 "不风暴"的正面证据（有界，不是次数上限）

`asks_shim`（探针自己的 `HwndSource` 钩子，**无截断**，W93A 口径）逐窗**末值**：

| 件 | `W1` | `W2` | `W3` |
|---|---|---|---|
| 修前（反极性趟，同码） | **0** | **1** | **2** |
| **修后**（两腿**相同**） | **3** | **8** | **6** |

⇒ 一个 14-stage 的生命周期里，每窗的 "问" 是**个位数**、且两腿**可复现**；同时 X 写次数（spy 块数）**≤** 值变化次数＋1。
⚠️ **旁证位移（如实登记）**：我把 `where` 前缀同时留在了"问"那一行与"发布决定"那一行 ⇒ `app.log` 的 `[WMSIZE_DIAG]` **每问两行**（`grep -c 'WM_GETMINMAXINFO:'` 会翻倍：`create 7→12`、`aftermap 6→5` 且**40 行封顶照旧打满**）⇒ 该计数**不可跨修前/修后对比**；逐窗归因只用钩子（上表）。

---

## §5 零回归

| # | 项 | 判决 | 读数 |
|---|---|---|---|
| `R-a` | **`D-G83` 四格** | **`PASS`** ✅ | 在**新件**（`2a297d6fee8be389`）上重取：`CELL declared ⇒ 'program specified maximum size: 667 by 500'`／`CELL minonly ⇒ 'program specified minimum size: 521 by 417'`／`CELL undeclared ⇒ '<缺席>'`／`CELL reg58(1280 by 1024 出现次数) ⇒ 0` ⇒ `W89A_0106 VERDICT=PASS` |
| `R-b` | `0104` 四入口＋`N1` = **26/26** | **`NOINFO`** | **我没跑**。做到哪一步：仓内 `build/MilBridge/tests/*/run-*.sh` **只有两个**（`RGateClickProbe/run-r-gate-legs.sh`、`W81AWindowProbe/run-w81a-legs.sh`；后者只有 `--leg pmax\|a0` **两条**腿）；`ROUTES.md:355` 记的 `26/26` 出自 `TASK-0205`（W89A），其装置在**别人车道的目录** `~/w89a/bin/hc-arm.sh` 等（每条腿要起真 hc 应用、`WARM≈6.5 s`，26 条 ≈30 min 起）⇒ **未跑**，不拿 `R-a` 顶替。⚠️ **这一格是收尾链的第一优先**：`P2` 正好落在 `MoveWindow`/`SetWindowPos` 上，而那**正是**最大化/还原路径（`0104` 面）。 |
| `R-c` | 裸 `Xvfb`（无 WM）启动路径声明仍正确 | **`PASS`** ✅ | `nowm` 腿就是裸 `Xvfb`；该腿上 `W1-SHOW`=`667 by 500`、`W2-SHOW`/`W3-SHOW`=缺席 ⇒ 逐格 `PASS` |
| `R-d` | 守卫/断言零删除 | **`PASS`** ✅ | `D-G83` 修法语义逐字保留、`DefWindowProcW` 的 `WM_GETMINMAXINFO` no-op 未触及、托管侧零改动（⇒ 一个 `Invariant.Assert` 不在射程） |

**另有一条顺带读数（新，登记用）**：`R-a` 的 `late` 窗（**`Show()` 之后**才声明 `MaxWidth`）X 侧**仍是 `<absent>`** ⇒ 与 `P-d`/`A3` **同一根因**（声明时没有 resize ⇒ 无触发器）。这是"缺托管侧通知"的**第三个**独立现场，可作为 `P3-a` 落地后的验收格。

---

## §6 反极性（**成对**，双向逐位）

| 步 | 读数 |
|---|---|
| ① 备份 | `cp -p` 三件：`win32_core.c.orig 9aa0d2d1b1ed8d55`／`win32_internal.h.orig c3dbf6b936a36239`／`libwpfwin32.so.orig 33352e5797031999` |
| ② **逐字节复原**源 ＋ 重建 | `src core=9aa0d2d1b1ed8d55 internal=c3dbf6b936a36239` ⇒ **`win32shim=33352e5797031999`（期望值，逐位相等）** |
| ③ 同腿（`nowm`）、同探针、同判据重取 | **`PASS=5 FAIL=4 VACUOUS=20`** ＋ **`A3=W1-REVERT:VACUOUS`** ⇒ 4 格**回到 `FAIL`**（`W1-TIGHTEN` `actual=667 by 500`／`W2-DECLARE` `<缺席>`／`W2-TIGHTEN` `521 by 417`／`W3-DECLARE` `<缺席>`）⇒ 与修后那趟构成**成对** |
| ③' 同趟的 `I3` | `W3 blocks=3 distinct=1 adjacent_repeats=2` ⇒ **冗余发布重现** ⇒ `I1` 的判别力在**复原件**上再次自证 |
| ④ 把修后源放回 ＋ 重建 | `src core=3fb8a1c165fccdbd internal=06acdcae4da6b9fd` ⇒ **`win32shim=2a297d6fee8be389`（逐位相等）** |

⇒ **反极性成立**（两侧都是"同一份源 ⇒ 同一个 sha16"，不是"大概回得去"）。**最终留在盘上的是修后态。**

---

## §7 `P3` 结论（"改**大**那一半"）

### 7.1 `P3-a` 派单书那一版：**不可行**（决定性实测 ＋ 代码行）

```
P3_OVERRIDE LEGAL=yes（竟然装上了；baseMd 的 callback=True）
Unhandled exception. System.TypeInitializationException: The type initializer for 'System.Windows.Window' threw an exception.
 ---> System.ArgumentException: PropertyMetadata is already registered for type 'Window'.
   at System.Windows.DependencyProperty.ProcessOverrideMetadata(...)  DependencyProperty.cs:line 566
   at System.Windows.DependencyProperty.OverrideMetadata(...)         DependencyProperty.cs:line 507
   at System.Windows.Window..cctor()                                  Window.cs:line 50
   at System.Windows.Window..ctor()                                   Window.cs:line 7221
（rc=134，core dumped）
```
- **为什么第一次竟然"成功"**：探针写的是 `Window.MaxWidthProperty` —— 那是**继承来的静态字段**（真正的声明者是 `FrameworkElement`）⇒ 触发的是 **`FrameworkElement` 的 `cctor`，不是 `Window` 的** ⇒ 那一刻 `typeof(Window)` 的槽位**还空着**，探针的 `OverrideMetadata` 就把它占了。
- **后果比"抛异常"更严重**：等到 `new Window()` 触发 `Window..cctor()`，它自己在 `Window.cs:50` 的 `OverrideMetadata(typeof(Window), …)` **抛 `ArgumentException`** ⇒ `TypeInitializationException` ⇒ **整个 `Window` 类型不可用**。⇒ 这个槽位是**单写者**，**shim 从外面赢不了这场竞态**（shim 的模块初始化只会**更早**，同样会毒死它）。
- ⇒ `P3-a`（`OverrideMetadata` 版）＝ **`FAIL`（不可行）**，W93A 记的 `NOINFO` **就此结案**。

### 7.2 `P3-a` 的**合法替代**：机制 `PASS`，**挂点**仍 `NOINFO`

第二臂（`W101A_P3_SKIP_OVERRIDE=1`，只验替代机制）：
```
P3_WAIT t=0.5s/2.5s/4.5s attachOk=0
P3_ATTACH_DIRECT t=6.0s ok（类处理器没到；实例挂载可用）
P3_NOTIFIED dp=MaxWidth  n=1 tid=1
P3_NOTIFIED dp=MaxHeight n=2 tid=1
P3_SET raise MaxWidth=900 t=6.5s notify=2      ← **调高**也收到通知（P3 关心的那一半）
P3_NOTIFIED dp=MaxWidth  n=3 tid=1
P3_SET tighten MaxWidth=400 t=8.0s notify=3
P3_KEEPUPSTREAM geom_after_tighten=400.32x500.16   ← 上游 `_OnMaxWidthChanged` **仍在工作**（零回归）
P3_SUMMARY override=SKIPPED(第二臂) attachOk=0 direct=1 notified=3   → rc=0
```
- **`NOTIFIED` = `PASS`**：`DependencyPropertyDescriptor.FromProperty(dp, typeof(Window)).AddValueChanged(win, …)` 在**真 `Window` 实例**上可用，**调高**与改紧**都**同步收到通知（`tid=1` ⇒ 与 DP 改动同线程）。
- **零回归 = `PASS`**：改到小于当前宽 ⇒ 应用自己缩到 `400.32`（原回调没被我碰 —— 本臂根本没改元数据）。
- **挂点 = `NOINFO`**：`EventManager.RegisterClassHandler(typeof(Window), FrameworkElement.LoadedEvent, …)` 在 **6 s** 内**一次都没触发**（本移植启动慢是已知的：TASK-0104 实测自绘 chrome 在 map 后 4.2–4.7 s 才进视觉树）⇒ "每个 `Window` 自动入册"的那个钩子**没验成**；替代挂点（`HwndSource`/`ComponentDispatcher`／PF 侧 needle 补丁点）**未验**。
- ⇒ 结论：**路是通的**（机制合法且能收到"调高"），**缺的只是"在哪把每个 `Window` 入册"这一个挂点**；这是波 `#51` 下一条车道的**明确起点**。

### 7.3 `P3-b`（保守兜底）**今天的实际状态**

- **已经实际达成的部分**：`P1` 的 `ShowWindow(map=1)` 那一拍**就是**"下一次窗口活动就发布"。**spy 实证**：`W3` 的 `max=469 by 365` **真的发到了 X**、`W1` 撤回后的 `max=667 by 500` 也**真的发回去了** —— 只是**晚一步**（`W3-DECLARE` stage 读的时候还没到，到 `W3-TOGGLE2` 才落）⇒ 这正是判据 `P-d`／`A3` 读红的原因。
- **未做的部分（逐字登记，未冒充"已修"）**：把 `wpf_hints_refresh` 再挂到 `WM_SIZE`／`WM_WINDOWPOSCHANGING` 上（`win32_x11.c:1068` 的 `ConfigureNotify ⇒ push(WM_SIZE)` 是天然挂点）。**没做的理由**：时间预算 ＋ "改完必须能重验"的纪律（每一处产品改动都要重跑两腿＋反极性），**不拿未验证的改动收尾**。
- **残留边界（逐字，必须带进登记件）**：
  > **"调高上限（或任何一次不伴随 resize 的声明）且此后不产生任何窗口活动 ⇒ X 侧仍旧值。"**
  现场实例：`W3-DECLARE`（`469x365` 迟到一步）、`W1-REVERT`（`667x500` 迟到一步）、`W81AWindowProbe` 的 `late` 窗（`Show()` 后声明 ⇒ 至今 `<absent>`）。
- `P3-c`（只把上限 `3` 改大）**没做**（明令禁止冒充修好；且旧上限已随 `P1` **删除**）。

---

## §8 件 sha16 与九位

**新 `win32shim` = `2a297d6fee8be389`**（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`，327,240 B；修前 `33352e5797031999`，327,248 B）。

**九位（现场算 sha16，与 `#50` 冻结值逐位比）**：

| 位 | live（本件收工） | 冻结 `#50` | 判定 |
|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | `feef049e9d0e313a` | 同 |
| `pc` | `722e0ab8205b7c3f` | `722e0ab8205b7c3f` | 同 |
| `pf` | `f34bc297d19778fd` | `f34bc297d19778fd` | 同 |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | 同 |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | 同 |
| **`win32shim`** | **`2a297d6fee8be389`** | `33352e5797031999` | **变了（本件唯一动的位）** |
| `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | 同 |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | 同 |
| `dwf` | `ce3469f49efcbcfa` | `ce3469f49efcbcfa` | 同 |

`BASELINESHA=PASS live=1f4189c1257737a9 decl=1f4189c1257737a9`／`BASELINEGEN=PASS decl_gen=#50`（`build/MilBridge/tools/baseline-sha-check.sh`）。

**仓内改动（审计）**：产品 = 上述 2 个源 ＋ 1 个 `.so`；`bin/exports.txt`／`bin/abi-layout` 是 `build-shim.sh --all` 的**重生成产物**（导出仍在 **546**、ABI 自检"全部一致"；**未与旧值逐字节对拍**，如实登记）；新增 = `docs/WAVE51-PREREGISTRATION.md` ＋ 本报告。
⚠️ 审计同时看到**别的车道**在动的件（`W93A/W96A/W98A/W100A/W102A-report.md`、`defect-registry-declared.tsv`、`wm-awaited.sh`、`KNOWN-DEFECTS.md`、`ROUTES.md`）—— **不是本车道写的**，列出来是免得被误记到我头上。

**件 sha16 一览**：判据 `~/w101a/criteria.md 5126a08c12c2801e`｜预登记 `af21bdf95b848eb9`｜腿脚本(我的复制件) `cd9e2b30bca4ddf7`｜W93A 原腿脚本 `534bde7643f03faf`（未改）｜`judge.py 743286f14e0b318e`（未改）｜探针 `Program.cs df9feabcd296b950`（未改）｜`win32_core.c 3fb8a1c165fccdbd`｜`win32_internal.h 06acdcae4da6b9fd`｜`libwpfwin32.so 2a297d6fee8be389`。

⚠️ **本报告自身的 sha16（两种口径都给，免得再出现 W93A 那种"两值并存"的误会）**：W93A 那件的末行自述用
`head -n -2 本文件 | sha256sum | cut -c1-16`，而主控当时按**全文件** sha16 引用 ⇒ 差异已由 W96A §214 查明是**口径**不是件被改。
本件**末行同时给出**那个口径的值（自洽：末两行本身不参与计算），全文件的值在 `~/w101a/STATUS.md` 末段。

---

## §9 作废趟／纪律偏离／自伤清单

| # | 项 | 如实登记 |
|---|---|---|
| 1 | **自伤：`sed` 注释吞掉 `mkdir`** | 我把 `w8106-copy.sh` 的 `OUT=` 行改成"带注释"时，把**同一行**的 `rm -rf "$OUT"; mkdir -p "$OUT"` 一起注释掉了 ⇒ 第一趟 `R-a` 报 `W89A_0106=NOINFO reason=probe-not-ready`（`rc=9`，`app.log` 不存在）⇒ **该趟作废**（不是产品的红）。修好后重跑 `VERDICT=PASS`。 |
| 2 | **自伤：`xprop -spy` 挂晚了** | 装置自证第一版里，探针把 `xid` **在 5 次调用之后**才印出来 ⇒ spy 只看到终值 ⇒ 那一趟**不能**用来判"一次调用=一次 PropertyNotify"。改成"**先印 xid 再调用**"后重跑：5 次调用（含 2 次值不变）⇒ 5 个块 ⇒ 判据前提成立。（这次自伤**没有**变成错误结论 —— 它只是让第一趟作废。） |
| 3 | **仪器损失：`out/nowm` 与 `out/wm` 的 `rows.tsv` 被后续趟覆盖** | 腿脚本对同一 `leg` 名 `rm -rf $OUT` ⇒ 修前 `nowm`/`wm` 的 `rows.tsv` 先后被"修后趟"和"反极性趟"覆盖。**修前那两趟的判词**（`PASS=5 FAIL=4`）与逐格原文已当场写入本报告与 `STATUS.md`，且 `logs/base-*.log`（含全部 `READ` 行）**保留**；反极性趟本身就是同码的**新**基线读数（`out/anti-nowm/`）。**修后 `nowm` 我重跑了一趟**并另存 `out/postfix-nowm/`。 |
| 4 | **作废趟：`P3-a` 第一臂 `rc=134`** | 那是**发现**不是自伤（`OverrideMetadata` 毒死 `Window` 的 `cctor`）；但它**连带**让第二臂（合法替代）跑不到 ⇒ 加了 `W101A_P3_SKIP_OVERRIDE=1` 才取到 §7.2 的读数。 |
| 5 | **一次 P3 探针第一版跑空** | 第一版的 tick 太快（250 ms × 5）⇒ `Loaded` 还没到就结束了（`attachOk=0`）⇒ 该趟**作废**，改成"等够 6 s ＋ 退回实例直挂"后取到读数。 |
| 6 | **纪律偏离：`R-a` 用了 W89A 脚本的复制件** | 原脚本把产物写进 `~/w89a/run/w8106/`（**别人车道的取证目录**）⇒ 我复制成 `~/w101a/w8106-copy.sh`（只改 `OUT`）后运行，**没有覆盖任何别的车道的件**。 |
| 7 | **`pkill -f` 次数 = 0** | 全趟按 PID 收工（`Xvfb :183/:184/:185/:186`、`xfwm4`、`xprop -spy`、`dotnet`）；**未碰** `:0/:1/:10/:97/:99` 与用户真实会话（`:10` 的 `xfwm4` 646945 只读观察）。 |
| 8 | **槽台账** | 每条重活各自入槽（`--min-avail 1500 --max-hold 300 --wait 900`）；`MAXHOLD_KILL` **0 次**、`HEAVYSLOT=NOINFO reason=low-memory` **0 次**；槽内最低 `avail` 见各 `logs/*.log` 的 `MEMOK` 行（最低一次 2706 MB）。 |
| 9 | **没跑的** | 完整 `verify-all.sh`（收尾链）、五臂重取、冻结、推送、`integration-wave.sh` —— 按任务书都不在本件射程。**我没有跑 `integration-wave.sh`**，理由（证据）：本件只改 **native C**，而 `grep -n 'build-shim\|gcc\|\.so' build/integration-wave.sh` 的**输出为空**（该脚本只重放 `src/WpfGfx.Linux.Native/tools/*.py` 里的**托管侧** applier，从不编译 native）⇒ 对"我的这一件"它是**空转**；native 的正确重建入口是 `src/WpfGfx.Linux.Native/build-shim.sh`（`close-wave.sh` 的 `[2/6]` 用的就是它）。**这一处偏离已在此写明**，若收尾链要求"整波重建"，请照常跑（appliers **不含** `win32_core.c`：`grep -l win32_core src/WpfGfx.Linux.Native/tools/*.py` = 空 ⇒ 我的手改**不会**被重放覆盖）。 |

---

## §10 大白话小结（8 行）

1. **改好了主因**：以前 shim 只在"第一次显示窗口"时问一次应用"你的最大/最小尺寸是多少"，问出来就**永远不再问**；被无意义的显示/隐藏刷 3 次后连问都不问了。现在改成**每次都问、但值真变了才写 X**（幂等），并在**窗口尺寸真变了**时补问一拍。
2. 结果：**4 个红格转绿 3 个** —— "改小/第一次声明"这一半（`W1-TIGHTEN`、`W2-DECLARE`、`W2-TIGHTEN`）两腿都绿了，`D-G83` 老四格仍全绿。
3. **剩下一格红 + 一个反极性格红是同一件事**：应用把上限**调高**（或声明后没触发缩放）时，它自己**什么都不做** ⇒ 我方没有可以搭的触发器 ⇒ X 侧要等**下一次窗口活动**才更新。
4. 修这一半必须从**托管侧**通知（`P3`）。派单书里那一版（`OverrideMetadata`）**实测不可行**：它会把 `Window` 类型初始化器毒死，进程直接 `rc=134`（`DependencyProperty.cs:566` / `Window.cs:50`）。
5. **但合法替代实测能跑**：`DependencyPropertyDescriptor.AddValueChanged` 在真窗口上，**调高也收到通知**，且原行为零回归 ⇒ 路是通的。
6. **还没找到"每个窗口自动入册"的挂点**（我试的 `Loaded` 类处理器 6 s 内没触发）⇒ 这是下一车道的第一步，不是"机制不行"。
7. **幂等（无风暴）如实报**：`W2`/`W3` 两腿干净；`W1` 两趟里有一趟出现"同一个值发了两次"—— 原因是 X 侧的 `max<min` 钳制会让"内部值变了"看起来一样，**我没有放宽判据**。
8. **反极性严格成立**（复原源 ⇒ shim 逐位回 `33352e5797031999` 且 4 格回红；放回修后源 ⇒ 逐位回 `2a297d6fee8be389`），**九位里只有 `win32shim` 动了**；`0104` 的 26 条腿我**没跑**（`NOINFO`，登记为收尾链第一优先 —— 因为 `P2` 正落在最大化/还原那条路上）。

W101A-report.md sha16 = 30ab2a51a8716711（口径：`head -n -2 本文件 | sha256sum | cut -c1-16` —— 排除末行本行与上一行空行；本值由现场复算填入，未手抄）

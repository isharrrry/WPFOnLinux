# W93A · `TASK-0107` —— `D-G83` 的后续 `H2`：**运行期改提示** ＋ **有 WM 时约束是否生效**

> 车道 **W93A** ｜ 本件**零产品改动**（取证 + 设计；落地留给波 `#51`）
> 日期 2026-09-22 ｜ 开工 `14:41:43`（`~/w93a/START.txt`）｜ 收工 `15:1x`
> 判据**先写**：`~/w93a/CRITERIA.md`（sha16 `3e15b945b4cbf87a`，写成于 **14:41:43**，早于本车道第一次构建/第一行读数）
> 报告件 sha16 见末节（现场算，未手抄）

---

## §0 一句话结论（三态，先给判决再给证据）

| 问题 | 判决 | 一句话 |
|---|---|---|
| **`H2-a`** 运行期改 `MaxWidth/MaxHeight`，`WM_NORMAL_HINTS` 会不会重发？ | **`FAIL`（4 个信息格全红）** | **不会**。修法 `H1` 只在**首次 map 那一拍**问一次，之后 `hints_map_declared=1` 被当成**终态** ⇒ 运行期改动**永不重发**；`WPF_HINTS_REASK_MAX=3` 计的是"**问**"不是"**改**"，花光之后**连第一次真声明都发不出去**。 |
| **`H2-b`** 有 WM 时那些约束是否真生效？ | **`PASS`（本机**有** WM：私有 `Xvfb`＋`xfwm4`）** | **真生效**：`PMaxSize/PMinSize` 同时管住①**客户请求**（`xdotool windowsize 1000x800` → 被压回 `667x500`）②**交互拖边框**（对照窗被拖大、受限窗纹丝不动）。⇒ 与 `H2-a` 合起来的**产品可见后果**是：WM **严格**执行一份**过期的**约束。 |

> ⚠️ 两个问题**都不需要改任何产品件**就能答；本件因此**一个产品字节都没动**。

---

## §1 判据（先写、读数后取）与被测件

### 1.1 判据来源
判据全文 = `~/w93a/CRITERIA.md`（sha16 **`3e15b945b4cbf87a`**，62 行）：
`A1`（机械面，逐 stage）／`A2`（产品面）／`A3`（反极性，含**先写死**的 `VACUOUS` 一条）／`A4`（正对照＋预算）／`B1..B4`（WM 在场证据、同腿两遍、约束是否生效两法、点击共变量）。
三态 `PASS`/`FAIL`/`NOINFO`；**`NOINFO` 既不算绿也不算红**；**装置判别力不自证 ⇒ 该格 `NOINFO`**。

### 1.2 被测件（**只读**，现场算 sha16；本件**未重建任何产品件**）

| 件 | 路径 | sha16 |
|---|---|---|
| shim（`win32shim` 位） | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`33352e5797031999`** |
| WIC shim | `build/DirectWrite.Linux/wic-shim/libwpfwic.so` | `f7b3026c8c019be2` |
| MIL（`wpfgfx_cor3.so`） | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/` | `feef049e9d0e313a` |
| PC / PF / WB（`Release`） | `build/*/bin/Release/` | `5aa6361a5ba02991` / `2a5b7641f6fba0fb` / `2e4e46e539a72cd7` |
| 探针（**仓外**） | `~/w93a/probe/bin/Release/W93AHintsProbe.dll` | `5330fd17f6d31434` |

**app-local == 权威，逐位相同**（4 件全对比，`W93A_APPLOCAL` 行）⇒ 读数落在**冻结/权威那一代**件上。

### 1.3 观测面（三个独立通道，互印）
1. **X 服务器自己的属性**：`xprop -id <xid> WM_NORMAL_HINTS` ＋ `xwininfo`（几何 / Map State / 父窗）。
2. **应用侧（自变量）**：探针印 `Window.MaxWidth/MaxHeight` 公开 DP ＋ 探针**自己**发一遍
   `SendMessage(hwnd, WM_GETMINMAXINFO)`（预填 shim 默认值）印回填后的 `maxtrack`（`W93A_SELF`）
   ＋ 反射读 `_trackMaxWidthDeviceUnits`。
3. **shim 侧计数**：① 应用内 `HwndSource` 钩子计数（`ask*=shim|probe` 分开，**无截断**）
   ② shim 的 `[WMSIZE_DIAG]` 行（`WPF_LINUX_CREATE_DIAG=1`）。
   ⚠️ **②有硬截断**：`win32_core.c:475-484` 每进程 **40 行**封顶 —— 本件两趟**恰好打满 40 行**
   （最后一行在日志第 189/248 行）⇒ **②只能当旁证**，逐窗归因一律以 ① 为准（见 §7 `NOINFO` 与缺陷草案 #2）。

### 1.4 装置判别力自证（**先做**）
仓内既有裸 X 装置 `build/MilBridge/tests/W81AWindowProbe/xprobe-hints.c`（与 WPF/shim 无关）成对：
```
W93A_DEVICE_ARM mode=max   max='program specified maximum size: 640 by 480'
W93A_DEVICE_ARM mode=nomin max='<缺席>'
W93A_DEVICE=PASS（成对：设了 PMaxSize 的窗读得到、没设的读不到）      ← 两趟腿各一次，均 PASS
```

---

## §2 `H2-a` 读数

### 2.1 三窗一台、14 个 stage（同一进程、逐 stage 取 X 读数）
| 窗 | 构造 | 自变量序列 |
|---|---|---|
| `W1` | 建窗**前**声明 `MaxWidth=640/MaxHeight=480`、`MinWidth=500/MinHeight=400` | **运行期**改成 `400x300` → 撤回 `640x480` → `HIDE/SHOW` 一次 |
| `W2` | `Show()` **之后**才在运行期声明（600x500 起步） | 运行期 `MaxWidth=500`（< 当前宽 ⇒ 应用**自己**缩窗）→ `HIDE/SHOW` → 再改 `300x250` → `HIDE/SHOW` ×3 |
| `W3` | **从不**在建窗前声明 | `HIDE/SHOW` ×4 先把补问预算花掉 → 运行期**第一次**声明 `MaxWidth=450` → `HIDE/SHOW` ×2 |

（`Stage()` 的全部读数都在 UI 线程上取；阶段机在后台线程 sleep ⇒ **消息泵不冻**，`xdotool` 的改尺寸/点击才有的可谈。）

### 2.2 机械面（`A1`）：**逐格判决**（`~/w93a/judge.py` 按先写判据机械算，两张表**逐位相同**）

判据口径（先写死）：**期望值 = 同一 stage 应用侧自查答案**（`W93A_SELF` 的 `maxtrack`）；`changed=no` ⇒ 期望是"X 侧**缺席**"。

| stage | 窗 | 应用侧答案 | X 侧 `maximum size` | 判决 |
|---|---|---|---|---|
| `W1-SHOW` | W1 | `667x500` | `667 by 500` | **`PASS`** ← 修法 `H1` 在**启动那一拍**是好的 |
| `W1-TIGHTEN`（运行期 640x480→**400x300**） | W1 | `667x500`→**`521x417`** | 仍 `667 by 500` | **`FAIL`**（且应用**自己**把窗缩到了 `417x313`） |
| `W1-REVERT`（撤回 640x480） | W1 | 回到 `667x500` | `667 by 500` | 与上同值 ⇒ `A3` 判 **`VACUOUS`**（见 2.4） |
| `W2-SHOW` | W2 | `1280x1024`（= 默认值，`changed=no`） | **`<缺席>`** ＋ `min 1 by 1` | **`PASS`**（未声明 ⇒ 不发 `PMaxSize`，波 59 语义保住） |
| `W2-DECLARE`（运行期 `MaxWidth=500` < 当前 600） | W2 | **`521x417`**（`changed=YES`） | **`<缺席>`** | **`FAIL`** ← **本件最值钱的一格**：应用**自己**缩了窗（几何 `625x521 → 521x417`），**X 侧连 `maximum size` 都没有** |
| `W2-TOGGLE`（`HIDE/SHOW` 一次） | W2 | `521x417` | **`521 by 417`**（**出现**） | **`PASS` = 正对照**：通道**能**带运行期的值 —— 缺的是**触发器** |
| `W2-TIGHTEN`（再改 `300x250`） | W2 | **`313x260`** | 仍 `521 by 417` | **`FAIL`**（`declared` 已落终态 ⇒ 不再问） |
| `W2-TOGGLE3`（`HIDE/SHOW` ×3） | W2 | `313x260` | 仍 `521 by 417` | 无位移（行内 `VACUOUS`）⇒ **`HIDE/SHOW` 也救不回来** |
| `W3-SHOW` | W3 | `1280x1024`（`changed=no`） | **`<缺席>`** | **`PASS`** |
| `W3-TOGGLE4`（`HIDE/SHOW` ×4，预算花光） | W3 | 未声明 | `<缺席>` | — |
| `W3-DECLARE`（补问预算**已用尽**后的**第一次**真声明 `450`） | W3 | **`469x365`**（`changed=YES`） | **`<缺席>`** | **`FAIL`** |
| `W3-TOGGLE2`（再 `HIDE/SHOW` ×2） | W3 | `469x365` | `<缺席>` | 无位移 ⇒ **永不恢复** |

```
SUMMARY  A1_informative=29  PASS=5  FAIL=4  VACUOUS=20
SUMMARY  A3=W1-REVERT:VACUOUS
```
→ **4 个 `FAIL` 全部是"运行期改动"格**；5 个 `PASS` 是"启动那一拍 / 未声明就不发 / 唯一的既有触发器"。
两趟腿（裸 `Xvfb` `:181` 与 `Xvfb`＋`xfwm4` `:182`）的 29 行 `rows.tsv`：**判据输入列**（`self_max`／`changed`／`prop_max`／`prop_min`／`map`／`asks_shim`）**逐格相同**；
差异**只在两列**：`geom` 与 `dp`（后者是"应用自己的 `Width/Height` DP"，它跟着**实际几何**走 —— 见 §2.3 的 WM 顶回现象）。两份表 sha16：`d06ede67a8e508fe`（nowm）／`9e70b1c73c93ac23`（wm）。

### 2.3 产品面（`A2`）：约束在**自己的代码里**生效，在 X/WM 侧**完全不可见**
- `W2-DECLARE`：上游 `Window.cs:5864-5884` 的 `OnMaxWidthChanged` 判定 `maxWidth(500) < logicalSize.X(600)`
  ⇒ 走 `UpdateHwndSizeOnWidthHeightChange` ⇒ `SetWindowPos` ⇒ **几何真的从 `625x521` 变成 `521x417`**（两趟腿都读到）。
  同一刻 X 侧 `WM_NORMAL_HINTS` **只有 `min 1 by 1`、没有 `maximum size`** ⇒ 应用已经按 500 DIP 约束自己，而 WM 一无所知。
- **有 WM 时这一格的后果**（`wm` 腿 `INTERACT`）：同一个 `W2` 的窗口，用 `xdotool windowsize 1000x800` 请求 ⇒
  **`521x417`**（= 那次 `HIDE/SHOW` 之后落下的**旧**值）—— 也就是说 WM 执行的是**过期**的约束；
  而 `W3`（运行期声明了 `450`，X 侧什么都没有）请求 `1000x800` ⇒ **`1000x800`** —— 应用以为上限 `469x365`，**WM 直接给了 1000x800**。
- 顺带一个**新读数**（两臂对照，`W1-TIGHTEN`）：裸 X 下几何被应用缩到 `417x313`；**有 WM** 时同一个请求被 WM **顶回 `521x417`**
  （因为 X 侧那份**过期**的 `min 500 DIP = 521 by 417` 还挂着）⇒ 「有 WM 时连**下限**都真生效」的正面证据，同时也是"过期提示会**反向**干预应用"的现场。

### 2.4 反极性（`A3`）：**`VACUOUS`（先写死的那条，如实报）**
`W1-REVERT` 撤回改前值后，X 侧提示 == 应用侧答案（都是 `667x500`）—— 但 **`W1` 的 X 侧提示在整个生命周期里**（`W1-SHOW`…`INTERACT`，14 个 stage）
**一次都没移动过**（恒为 `667 by 500`）⇒ "回到旧值"与"从来没有跟过"**不可分**。
⇒ 按判据先写的口径，本格判 **`VACUOUS`**：**不构成反极性证据，不许当绿**。
（真正的反极性只能等修法落地后重造：`改紧 → 提示跟到新值 → 撤回 → 提示跟回旧值`。本件的 `W2-TOGGLE` **正对照**已证明"跟得动"这一半成立。）

### 2.5 重问上限 `3` 的**实际后果**（逐窗计数，`A4`）

| 窗 | `create` 那一问 | 首次 `Show` 补问 | `HIDE/SHOW` 补问 | 合计补问 | 之后还问得动吗 | 证据（**无截断**的钩子计数 ＋ 旁证 diag） |
|---|---|---|---|---|---|---|
| `W1` | 1（问不出，`_swh` 未就位） | **1**（问出 `667x500`）⇒ **落"已声明"终态** | **0** | **1** | **不能**（`hints_map_declared=1` 是死锁） | 钩子 `W1[shim=0]` 全程 0（`Show` 那一问在钩子装上之前，由 diag 覆盖） |
| `W2` | 1（问不出） | **1**（`changed=no`，预算剩 2） | **1**（问出 `521x417` ⇒ 终态） | **2** | **不能**（终态） | 钩子 `W2[shim=1]`：只在 `W2-TOGGLE` 那一格 +1，其后 `W2-TIGHTEN`/`W2-TOGGLE3` **+0** |
| `W3` | 1（问不出） | **1**（`changed=no`，预算剩 2） | **2**（×4 次 `HIDE/SHOW` 只问出 2 次 ⇒ `asks` 撞到上限 3） | **3 = 上限** | **不能**（预算耗尽） | 钩子 `W3[shim=2]`：`W3-TOGGLE4` 里 +2，其后 `W3-DECLARE`/`W3-TOGGLE2` **+0** |

```
W93A_DONE … W1[shim=0 probe=14] W2[shim=1 probe=10] W3[shim=2 probe=5]       ← 两趟腿**计数部分逐字相同**（`pid=` 与 `clicks=` 外）
W93A_ASKS  diag_aftermap=6 diag_createwin=7                                  ← 旁证：6=1+1+1+1+2（与上表加法一致）
```
- **机制一句话**：`hints_map_asks` 计的是"**问了几次**"，不是"**应用改了几次**"。
  `W3` 用 4 次无意义的 `HIDE/SHOW` 把 3 次预算花光 ⇒ 之后**第一次**真声明也永久发不出去。
  `W1/W2` 则相反：一旦问出过一次声明就落**终态**，之后**任何**再问的路径都被 `!w->hints_map_declared` 挡死。
- **第 4 次改被吞掉的形式**因此有两种，且**都**在本件里取到了读数：
  ① "已声明终态"型（`W1` 的第 1 次运行期改、`W2` 的第 2 次改）；
  ② "预算耗尽"型（`W3` 的**第 1 次**声明）。
- ⚠️ **`diag=6` 是旁证不是判据**：diag 每进程 40 行封顶（本件打满），尾段无 diag 行；
  逐窗归因以钩子（无截断）为准，两者在重叠区**一致**。

---

## §3 `H2-b` 读数（**本机有 WM**）

### 3.1 WM 在场的**现场证据**（`B1`）
```
W93A_WMPROOF check=PASS  raw='_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x4000ae '
W93A_WMSUP   n=75        workarea='_NET_WORKAREA(CARDINAL) = 0, 0, 1280, 1024, …'  wm_pid=1956849
REPARENT win=W1 client=0x200004 parent=0x400486 root=0x50d      ← 父窗 ≠ root ⇒ WM **重定父**
xfwm4 的 cmdline = 'xfwm4 --display=:182 --compositor=off '（我起的，按 PID 收工）
```
- **本机 WM 清单**：`command -v` 只命中 **`xfwm4`**（`/usr/bin/xfwm4`）；`openbox/fluxbox/metacity/mutter/i3/twm` 全无。
- ⚠️ **`:10` 是用户真实会话**（xrdp Xorg ＋ `xfwm4` PID 646945，已跑 21 h）——**只读观察，未在上面开我们的应用**（`W53A`/`W54A` 的既有纪律）。
  本件两趟腿全部跑在**私有** `Xvfb`（`:181` 裸 / `:182` ＋ `xfwm4`），按 PID 收工（收工 `pgrep -a Xvfb` 空；用户那只 `xfwm4` **未碰**）。
- 配方**照抄**既有腿（`W53A/cell3.sh:20-30`：私有 `Xvfb 1280x1024x24` ＋ `dbus-launch` ＋ `xfwm4 --compositor=off`），未自己发明。

### 3.2 约束是否 **真生效**（`B3`）—— 两法、两臂、带对照

**法① 客户请求法**（`xdotool windowsize <xid> …`）：

| 窗 | X 侧提示（**过期的真值**） | 请求 `1000x800` | 请求 `300x200` | 请求 `667x500` |
|---|---|---|---|---|
| `W1` | `min 521 by 417` / `max 667 by 500` | **`667x500`**（压在 `PMaxSize`）✓ | **`521x417`**（顶在 `PMinSize`）✓ | `667x500` ✓ |
| `W2` | `min 1 by 1` / `max 521 by 417` | **`521x417`**（压在**旧** `PMaxSize`）✓ | `300x200` ✓ | `521x417`（压在旧上限）✓ |
| `W3` | **无 `maximum size`**（运行期声明到不了 X） | **`1000x800`**（**无约束**）✗ | `300x200` ✓ | `667x500` |

**裸 `Xvfb` 对照臂**（同一条腿、同一份探针）：三个窗**一律照做** —— `1000x800`→`1000x800`、`300x200`→`300x200`、`667x500`→`667x500`
⇒ **无 WM 时 `WM_NORMAL_HINTS` 只是建议，没有任何东西执行它**（`max 667x500` 也拦不住 `1000x800`）。

**法② 拖边框法**（`xdotool` 在**框架右下角**按下、外拖 6 步 ×(+45,+32)；`wm` 腿）：

| 窗 | 提示 | 拖前 → 拖后 | 读法 |
|---|---|---|---|
| **对照** `W3`（**无** `maximum size`） | `min 1 by 1` | `667x500` → **`937x692`**（+270/+192，与拖拽位移**逐格吻合**） | **装置有判别力**：能大就真的大 |
| **处理** `W1`（`max 667 by 500`） | `min 521 by 417`/`max 667 by 500` | `667x500` → **`667x500`**（**纹丝不动**） | **`PMaxSize` 在交互拖拽里被 WM 严格执行** |
| 纯 X 装置对照（`xprobe-hints.c`，与 WPF 无关） | `max 640 by 480` / 无 | 对照 `1000x800` → **`1002x802`**（+2/+2，只因已贴屏边）／ 处理 `640x480` → **`640x480`** | 同一结论，**不依赖我们的 shim/WPF** |

⇒ **`B3` 判决 `PASS`：有 WM（`xfwm4`）时，我们发布的 `WM_NORMAL_HINTS` **真生效**（客户请求 ＋ 交互拖拽，两法互印，且有能自证判别力的对照）。**
⇒ 与 `H2-a` 合起来的产品结论：**WM 严格执行的是一份过期的约束**（`W2` 压 `521x417`、`W3` 完全不压）。

### 3.3 「有 WM 时点击会被吞」这个历史变量（`B4`）
两趟腿都在 `INTERACT` 里对 `W1` 的客户区中心点了 2 次、并读应用侧计数：
```
W93A_CLICKTESTS tried=2 at=333,250 (W1 几何 667x500@0,0)     ← 无 WM 腿
W93A_CLICKTESTS tried=2 at=712,565 (W1 几何 667x500@379,315) ← 有 WM 腿
W93A_DONE … clicks=0     （两趟**都是 0**）
```
⇒ 我的合成点击在**基线臂（无 WM）也没落地** ⇒ **该装置对"点击能不能落地"没有判别力**
⇒ 这条共变量本件记 **`NOINFO`**，**不说**"有 WM 时点击被吞"（那需要一条能自证落地的点击装置，本件没有）。
（历史口径见 `W53A`/`W54A`：那里用的是应用自己的事件计数与坐标拾取，不是本件的 `xdotool` 合成点击。）

### 3.4 另外两处 `NOINFO`
- `xdotool windowstate --add MAXIMIZED_HORZ/VERT` 两臂**都无效果**（`_NET_WM_STATE` 空、几何不变；
  `xdotool` 只改属性、不发 EWMH client message）⇒ 「WM 驱动的最大化"那一格 `NOINFO`，不作为判据。
- 裸 X 腿的"拖边框"按定义不适用（客户父窗就是 root，没有框架边框）⇒ 该腿该格 `NOINFO reason=no-wm-no-frame`（**不是**红）。

---

## §4 机制（代码行级，为什么必然如此）

| # | 位置 | 事实 |
|---|---|---|
| 1 | `src/WpfGfx.Linux.Native/src/win32_core.c:714-748` `wpf_ask_minmaxinfo_apply_hints()` | 一拍 = 填默认值 → 派发 `WM_GETMINMAXINFO` → 比对回填 ⇒ 只把"应用真的改过的上限"发给 X（`app_declared`）。**这是唯一**写 `WM_NORMAL_HINTS` 的地方。 |
| 2 | `:763` `#define WPF_HINTS_REASK_MAX 3` ＋ `:765-790` `wpf_minmaxinfo_reask_after_map()` | 两个停止条件：`hints_map_declared`（**已声明 = 终态**）与 `hints_map_asks < 3`。**计的是"问"，不是"改"**。 |
| 3 | `:1074` `if (map) wpf_minmaxinfo_reask_after_map(hwnd);`（`ShowWindow` 内） | 全仓**唯一**的运行期触发点 ⇒ 只有 `ShowWindow(map=1)` 能引发重问。 |
| 4 | `:1078-1100` `MoveWindow` / `:1108-1172` `SetWindowPos` | 两条改尺寸路径**都不派发** `WM_GETMINMAXINFO`、也不重发提示 —— 只做自己的 `clamp_toplevel_extent`（那是**我方**的屏幕钳制，与应用的声明无关）。 |
| 5 | 上游 `Window.cs:5864-5889` `OnMaxWidthChanged` | 只有 `maxWidth < logicalSize.X` 时才 `UpdateHwndSizeOnWidthHeightChange` ⇒ `SetWindowPos`（**缩**窗）；**调高**时**什么也不做**。 |
| 6 | 上游 `Window.cs:3446-3475` `GetWindowMinMax`（按 `_trackMax*` 缓存算 `mm.maxWidth`）＋ `:4875-4879` `WmGetMinMaxInf` 写缓存 | 应用侧的"答案"**一直是对的**（本件 `W93A_SELF` 每格都读到新值）；缺的**不是值，是触发器**。 |
| 7 | 上游 `Window.cs:4272-4298` `WindowFilterMessage` | `WM_GETMINMAXINFO` 在**最前面**处理（`_swh == null` 也处理）⇒ 谁来问就答谁；**没人问就没有任何机制**。 |
| 8 | `XSetWMNormalHints` 语义（`win32_x11.c:1849-1868`） | **允许**在 map 之后重复设 ⇒ 修法在 X 侧**没有障碍**（`H1` 已经这么做过）。 |

⇒ 结论：**通道能力齐备**（①的值对、⑧能重发、④的钳制与提示不冲突），**唯一缺的是"运行期按需再问一次"的触发器**
（以及把 ② 那个"终态/次数"判据改成按**值变化**触发）。

---

## §5 逐字补丁草案（**留给波 `#51`**；本件不落）

> 目标：`H2-a` 的 4 个 `FAIL` 全部转绿，且**不引入消息风暴**、不动波 59 的语义（未声明就不发 `PMaxSize`）。
> 反极性装置已经就绪（本件的 `W1/W2/W3` 三窗一台 ＋ `xprop` 判据 ＋ `judge.py`）。

### `P1`（必做，`win32_core.c`，最小改动）把"终态/次数"换成"**值变了才重发**"

```c
/* 现状（:757/:773/:784-788）：hints_map_declared 是 bool 终态；hints_map_asks < 3 */
/* 改成：缓存"上次真的发出去的 (min,max)"，每次重问后比对 —— 相等就什么都不做（幂等），不等才 XSetWMNormalHints */

/* win32_internal.h 的 wpf_window 里，把两个字段换成四个（+1 有效位）： */
-    int hints_map_asks;        /* 已补问次数（上限 WPF_HINTS_REASK_MAX） */
-    int hints_map_declared;    /* 已问出应用声明的上限（终态） */
+    int hints_pub_valid;               /* 上次发布是否已经有值 */
+    int hints_pub_min_w, hints_pub_min_h;
+    int hints_pub_max_w, hints_pub_max_h;   /* 0,0 = "未发 PMaxSize" 也是**一种已发布状态** */
+    int hints_in_refresh;              /* ★ 重入闸（见下方"必须带"） */
```

```c
/* win32_core.c: 用 wpf_hints_refresh 取代 wpf_minmaxinfo_reask_after_map 的语义（触发点见 P2/P3） */
static void wpf_hints_refresh(HWND hwnd, const char *where)
{
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    int skip = (!w || w->is_message_only || w->parent != NULL
                || (w->style & WS_CHILD) != 0 || w->hints_in_refresh);
    if (w) w->hints_in_refresh = 1;              /* ★ 重入闸：本函数会**回调托管代码**，可能再进 SetWindowPos */
    pthread_mutex_unlock(&g_wpf.lock);
    if (skip) return;

    int declared = wpf_ask_minmaxinfo_apply_hints(hwnd, /*cls*/ NULL, where);   /* 内部已有 diag */
    /* ↑ 让 wpf_ask_minmaxinfo_apply_hints 把 (min_w,min_h,max_w,max_h) 通过出参带出来 */

    wpf_lock();
    wpf_window *w2 = wpf_window_find(hwnd);
    int changed = 0;
    if (w2) {
        changed = !w2->hints_pub_valid
               || w2->hints_pub_min_w != min_w || w2->hints_pub_min_h != min_h
               || w2->hints_pub_max_w != max_w || w2->hints_pub_max_h != max_h;
        if (changed) { w2->hints_pub_valid = 1;
                       w2->hints_pub_min_w = min_w; w2->hints_pub_min_h = min_h;
                       w2->hints_pub_max_w = max_w; w2->hints_pub_max_h = max_h; }
        w2->hints_in_refresh = 0;
    }
    pthread_mutex_unlock(&g_wpf.lock);
    /* ★ 只有"值真的变了"才落 X（相等则**不**调 XSetWMNormalHints）⇒ 幂等、无风暴 */
    if (changed) wpf_x11_apply_wm_hints(hwnd, clsbuf, min_w, min_h, max_w, max_h);  /* 与现状同一函数 */
    (void)declared;
}
```
**替换点**：
1. `:1074` 的 `wpf_minmaxinfo_reask_after_map(hwnd)` → `wpf_hints_refresh(hwnd, "WM_GETMINMAXINFO(after-map)")`（**删掉 `WPF_HINTS_REASK_MAX` 与 `hints_map_declared` 两个停止条件**）。
2. `:914` 建窗那一拍**保持原样**（Win32 顺序不变）。

### `P2`（必做，**这就是"运行期改"的触发器**）改尺寸路径上补一拍
```c
/* MoveWindow (:1094 之后) / SetWindowPos (:1148 之后)：仅当"调用方真的改了尺寸"时才补 */
if (!(flags & SWP_NOSIZE) && (nw != 旧宽 || nh != 旧高))
    wpf_hints_refresh(hwnd, "after-SetWindowPos");
```
**为什么这样就能救 `W2`/`W1` 的"改紧"**：上游 `Window.cs:5879-5884` 在 `MaxWidth` 变**小**时**一定**会走
`UpdateHwndSizeOnWidthHeightChange` → `SetWindowPos`（本件 `W2-DECLARE` 的几何 `625x521→521x417` 就是它）⇒ 这一拍一定到得了。
**为什么救不了"改大"**：调高 `MaxWidth` 时上游**什么都不做**（同文件 `:5871-5875` 的注释）⇒ 见 `P3`。

### `P3`（二选一，**必须由主控裁定**）"调高但没有 resize"的那一半
- **`P3-a`（推荐，需托管侧通知）**：新增一个 PF 侧 shim（本仓做法：`build/shims/*.shims.txt` 的**新增文件**形态，
  上游"零改动"的纪律不破），在模块初始化时对 `MaxWidthProperty/Min*Property` 用
  `OverrideMetadata(typeof(Window), …)` **链式**挂一个回调 ⇒ 任何 DP 变化都通知 shim（新导出，例如
  `WPFLinux_NotifyMinMaxChanged(HWND)`）去 `wpf_hints_refresh`。
  ⚠️ 我**没有**验证"在 shim 里 `OverrideMetadata` 覆盖 `Window` 的元数据"在本移植里的合法性与顺序（是否被 `_OnMaxWidthChanged` 抢跑/丢回调）
  ⇒ 这一格我记 **`NOINFO`**，落地前必须自己做一次**最小探针**（判据：改 DP ⇒ 通知到了；且原来的 `_OnMaxWidthChanged` 行为**零回归**）。
- **`P3-b`（保守兜底）**：接受"**下一次窗口活动**才发布"——把 `wpf_hints_refresh` 也挂在
  `WM_SIZE`（X 发起的、含 WM 拖拽后的 `ConfigureNotify`）与 `WM_WINDOWPOSCHANGING` 上，并在**报告/登记件**里
  写清残留边界："调高上限且此后不产生任何尺寸活动 ⇒ X 侧仍旧值"。
- **`P3-c`（不推荐）**：把 `WPF_HINTS_REASK_MAX` 从 3 改大 —— **这不治病**：它计的是"问"不是"改"（本件 `W3` 已证），
  只是把"第 4 次被吞"推迟成"第 N 次被吞"。

### `P4`（必须与 `P1` 同趟）重入闸与"不风暴"的证据
- `hints_in_refresh` 闸：`wpf_ask_minmaxinfo_apply_hints` **同步回调托管代码**（`WmGetMinMaxInfo`），
  而托管回调里可能再次 `SetWindowPos` ⇒ 没有闸就是**递归**（本仓 `D-G54` 同族教训：跨层标记要在最内层兑现）。
- "不风暴"的新判据（写进波 `#51` 的先写判据）：**同一进程里 `XSetWMNormalHints` 的调用次数
  == "值发生变化的次数"**，而不是 `asks <= 3`；用一条改 N 次的探针腿量（N 次改 ⇒ 恰 N 次 X 调用 ＋ 每次 `xprop` 与自查答案相等）。

### `P5` 反极性（波 `#51` 的装置已经写好：`~/w93a/run-w93a-legs.sh` ＋ `judge.py`）
1. **正**：`W1` 改紧 ⇒ `xprop` 从 `667 by 500` 跟到新值；`W2` 运行期首次声明（**不再需要 `HIDE/SHOW`**）⇒ `maximum size` 出现；
   `W3` 的**第一次**声明（预算概念已废）⇒ 出现。
2. **反（本件记 `VACUOUS` 的那条要重造）**：修后 `改紧 → 跟到新值 → 撤回 → 跟回旧值`（两向都移动过才成立）。
3. **`reg58` 守门**：任何一格出现 `1280 by 1024` 即点名（波 58 的错法）。
4. **未声明窗**：`maximum size` **仍必须缺席**（波 59 语义）。

---

## §6 省/用槽台账与纪律

| 项 | 读数 |
|---|---|
| 重活入槽 | **3 次**，全部 `--min-avail 1500 --max-hold 300 --wait 900`，**每条各自**入槽 |
| ① 构建探针（仓外） | `HEAVYSLOT=ACQUIRED waited=0s` → `MEMOK avail=3108MB` → `RELEASED rc=0 held=5s` |
| ② 腿 `nowm`（`:181`） | `MEMOK avail=2886MB` → `RELEASED rc=0 held=107s`；`W93A_APP rc=0` |
| ③ 腿 `wm`（`:182`） | `MEMOK avail=2803MB` → `RELEASED rc=0 held=107s`；`W93A_APP rc=0` |
| `MAXHOLD_KILL` / `NOINFO low-memory` | **0 次**（`grep` 全趟无） |
| 内存 | 开工 `available 3201MB` → 槽内最低 **2803MB** → 收工 `3106MB`（`used 4519MB`）；`SwapFree` 1241MB |
| `loadavg` | 开工 `0.35` → 收工 `0.21 0.31 0.32` |
| `pkill -f` | **0 次**（`grep -c pkill` 全趟 = 0）；`Xvfb`/`xfwm4` **按 PID** 收工；**用户会话 `:10` 的 `xfwm4`(646945) 未碰** |
| 收工残留 | `pgrep -a Xvfb` / `pgrep -a dotnet` **全空**（我起的 `:181/:183/:184/:185/:186/:187` 都已按 PID 清掉） |
| 仓内写入 | **只有本报告一个文件**：`find $R -newermt '-90 minutes' -type f` 的**输出恰好就是这一行本身**（`count=1` = 本报告）；全趟未写第二个仓内件 |
| 未跑 | `verify-all.sh` / `close-wave.sh` / `integration-wave.sh` / 任何 applier / 任何产品构建 |

---

## §7 `NOINFO` 清单（既不算绿也不算红）

| # | 项 | 为什么没取到 |
|---|---|---|
| 1 | 运行期**调高** `MaxWidth` 之后的产品面读数 | 调高时上游 `OnMaxWidthChanged` **什么都不做**（`Window.cs:5871-5875`）⇒ 没有任何触发器可打；我只能读"X 提示不变"，不能造"调高后拖大"的读数（那正是 `P3` 要解决的格子） |
| 2 | 「有 WM 时点击会不会被吞」 | 我的合成点击在**基线臂（无 WM）也没落地**（`clicks=0` 两臂同）⇒ 装置无判别力（§3.3） |
| 3 | EWMH 最大化（`xdotool windowstate --add`）在两臂都无效果 | `xdotool` 只改属性、不发 client message ⇒ 那一格无信息 |
| 4 | `[WMSIZE_DIAG]` 的**逐窗归因**（尾段） | 该 diag 每进程 **40 行硬截断**（`win32_core.c:475-484`，本件打满），尾段无行 ⇒ 逐窗归因一律改用无截断的应用内钩子（两者在重叠区一致） |
| 5 | `P3-a`（shim 侧 `OverrideMetadata` 链式挂钩）的可行性与顺序安全 | 我**没有**验证本移植里"新增 PF shim 覆盖 `Window` 元数据"是否合法、会不会把 `_OnMaxWidthChanged` 挤掉 ⇒ 落地前必须自建最小探针 |
| 6 | 真实第三方应用（HandyControl / `WpfFeatureProbe`）里"运行期改 `MaxWidth`"的端到端 | 本件用的是**探针**（加载**权威** `.so`），没跑应用；托管级链路的动态跟踪也未做（只静态读了上游两段） |
| 7 | `dpi ≠ 1.041667` 的机器 | 只有这一台；判据按"现场读比例"写，但没在第二种比例上取过读数 |
| 8 | 有 WM 时的**渲染/画面**是否正常 | 本件只判尺寸与提示（`xprop`/`xwininfo`），没验画面（那要另一台仪器） |
| 9 | `W3` 在 WM 下被 `windowsize 1000x800` 拉到 `1000x800` 之后，应用侧是否"察觉" | 我只读了 X 几何；应用侧 `Width/Height` DP 与 `WM_SIZE` 的后续行为未跟踪 |
| 10 | 无 WM 时"用户拖拽" | 裸 X 下没有 WM 就没有"框架边框"⇒ 该格**按定义不适用**（`NOINFO reason=no-wm-no-frame`），不是红 |

---

## §8 新发现（草案在 `~/w93a/defect-draft.md`，sha16 `6c67bff3e7d5b785`；**登记由主控落**）

| # | 类型 | 一句话 | 现场证据 |
|---|---|---|---|
| 1 | **既有装置的真缺陷** | `xprop -root _NET_SUPPORTING_WM_CHECK \| grep -q window` **恒真**（失败文案是 `no such atom on any **window**.`）⇒ 任何"等 WM 起来"的循环第一次就 break，`W53A/cell3.sh:26` 就是这一行 | 逐 0.25 s 计时：`atom appeared at iteration 1`，而同刻 `xprop` 输出仍是 `no such atom on any window.`；真上位要 ~1–5 s |
| 2 | **既有仪器的局限** | `wpf_wmsize_diag` **每进程 40 行**截断（`win32_core.c:475-484`）⇒ `[WMSIZE_DIAG]` 不能当"派发总数"；本件打满 40 行、尾段无行 | 两趟腿 `grep -c '[WMSIZE_DIAG]'` **恰好 40**，最后一行在 189/248 行 |
| 3 | **产品缺陷（`H2`）** | 运行期改提示到不了 X（终态死锁 ＋ 预算计"问"不计"改"），且**有 WM 时 WM 严格执行过期约束** | §2 的 4 个 `FAIL` ＋ §3.2 的 `W2` 压 `521x417`、`W3` 放任 `1000x800` |
| 4 | **我自己的仪器自伤（4 处，如实入册）** | UI 线程亲和（`VerifyAccess` 整趟死在 `W1-PRE`）／`xwininfo` 行序（几何恒空）／`Parent window id` 要 `-tree`／仓外工程必须显式钉 `WPF_LINUX_WIN32_SHIM`＋`MILBRIDGE_MILCORE_SO`（否则 `Show()` 当场 `DllNotFoundException: wpfgfx_cor3.dll`） | 全部落在 `~/w93a/out/*/app.log` 与本报告 §8 |

---

## §9 复现命令 ／ 件 sha16

```bash
# ① 构建探针（**仓外**工程；唯一一次 dotnet build）
cd ~/w93a/probe && export PATH="$HOME/.dotnet:$PATH"
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 300 --wait 900 -- timeout 280 \
     dotnet build W93AHintsProbe.csproj -c Release -m:1 --nologo -v q

# ② 两条腿（各自 ~107 s；裸 Xvfb / Xvfb+xfwm4；**所有 .so 由装置显式钉死**）
bash ~/w93a/run-w93a-legs.sh nowm :181      # ⇒ ~/w93a/out/nowm/{rows.tsv,app.log,run.log}
bash ~/w93a/run-w93a-legs.sh wm   :182      # ⇒ ~/w93a/out/wm/{rows.tsv,app.log,run.log}

# ③ 机械判决（按先写判据）
python3 ~/w93a/judge.py ~/w93a/out/nowm/rows.tsv
python3 ~/w93a/judge.py ~/w93a/out/wm/rows.tsv

# ④ 纯 X 的 H2-b 对照（零 dotnet，几秒一趟）
bash ~/w93a/x-wm-test.sh :191 wm            # ⇒ ~/w93a/out/xwm-wm/run.log
bash ~/w93a/x-wm-test.sh :183 nowm          # ⇒ ~/w93a/out/xwm-nowm/run.log
```

| 件 | sha16 |
|---|---|
| 判据（先写）`~/w93a/CRITERIA.md` | `3e15b945b4cbf87a` |
| 探针源码 `~/w93a/probe/Program.cs` | `df9feabcd296b950` |
| 探针工程 `~/w93a/probe/W93AHintsProbe.csproj` | `3d7bc3701e203c16`（＋`global.json` `49307341ea4847e8`）|
| 装置 `~/w93a/run-w93a-legs.sh` | `534bde7649f03faf`（**两趟腿跑的就是这一版**，含 WM 谓词修补）|
| 装置 `~/w93a/x-wm-test.sh` | `ee507abd5c99533e` |
| 判决器 `~/w93a/judge.py` | `743286f14e0b318e` |
| 缺陷草案 `~/w93a/defect-draft.md` | `6c67bff3e7d5b785` |
| 读数表 `out/nowm/rows.tsv` / `out/wm/rows.tsv` | `d06ede67a8e508fe` / `9e70b1c73c93ac23` |
| 探针日志 `out/nowm/app.log` / `out/wm/app.log` | `3205492af27c1784` / `2fe98913935a0cfd` |
| 装置日志 `logs/leg-nowm.log` / `logs/leg-wm.log` | `45c792009cf1fa1d` / `a7b831676cf66ab2` |
| 纯 X 腿 `out/xwm-wm/run.log` / `out/xwm-nowm/run.log` | `413b955a74a68744` / `0abc44212868ff15` |
| 本报告 `build/MilBridge/W93A-report.md` | **见末行**（口径：`head -n -1 本文件 | sha256sum | cut -c1-16`）|

---

## §10 大白话小结（6 行）

1. **`H2-a` 答：不会跟。** 运行期改 `MaxWidth`，X 侧那份提示一动不动 —— 四次改动的格子**全红**。
2. 原因不是"值算错了"：应用那边每次都答对（`W93A_SELF` 每格都读到新值），**缺的是"再问一次"的那一拍**。
3. `WPF_HINTS_REASK_MAX=3` 数的是"**问**"不是"**改**"：`W3` 用 4 次 `HIDE/SHOW` 把预算花光 ⇒ **第一次真声明也永远发不出去**；`W1/W2` 则是"问出过一次就锁死"。
4. **唯一的既有触发器是 `HIDE/SHOW`**：`W2` 一按，运行期的值**立刻**正确落到 X（正对照 ⇒ 通道本身没坏）。
5. **`H2-b` 答：有 WM 时真生效。** 私有 `Xvfb`＋`xfwm4` 下，`xdotool` 请求 `1000x800` 被压回 `667x500`、**拖边框也拖不大**（对照窗同装置能拖大，判别力自证）⇒ **WM 严格执行的是一份过期的约束**（`W3` 声明了 450 却被放任到 1000x800）。裸 Xvfb 下则**毫无约束**（提示只是建议）。
6. 本件**零产品改动**（探针在仓外、仓内只新增本报告）；顺带抓到两条**既有装置/仪器**的真缺陷（`grep -q window` 恒真、diag 40 行截断），登记草案在 `~/w93a/defect-draft.md`。

---
W93A-report.md sha16 = 092c44b3bca27cdd（口径：`head -n -2 本文件 | sha256sum | cut -c1-16` —— 排除末行本行与上一行分隔线；本值由现场复算填入，未手抄）

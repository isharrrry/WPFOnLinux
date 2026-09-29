# `TASK-0009` · E3 真重放夹具 —— **判据件**（`E3ReplayProbe`）

> **写域**：`build/MilBridge/tests/E3ReplayProbe/**`（本目录）。**未碰** `verify-all.sh`／
> `build/close-wave.sh`／`build/MilBridge/tools/**`／`src/**`／`docs/**`／`HANDOFF-NEXT.md`。
> 本夹具**不入** `fp_inputs()` 覆盖面（不改指纹）。
> 行号／`x_time`／PID 一律「仅本次有效」；**判据只认本目录三件的读数**。

---

## ① 入口命令（可复跑单行）

```bash
bash build/MilBridge/tests/E3ReplayProbe/run-e3replay-probe.sh --out=/tmp/e3replay
```

装置自足：建私有 `Xorg :23N`（vmware 驱动＋libinput 热插拔）→ 临时放开 `/dev/uinput`
→ 三条腿各跑一次探针（`dlopen` 产品 `.so`，走它的 Win32 ABI 建窗、走它的
`wpf_x11_pump_into_queue` 翻译事件）→ 收尾（`/dev/uinput` 复原 `600`、Xorg **按 PID** 关）。

**出口读数**（机器可读行，逐条）：

| 行 | 含义 |
|---|---|
| `E3_REPLAY_PRE  lib_sha16=… win32_x11_sha16=…` | 作业前主链代 |
| `E3_REPLAY_BTN  leg=… raw_ButtonPress_lines=N（原样：[KEY_DIAG] BTN type=Press … send=… time=…）` | 产品**原样**打出的抓到的 `ButtonPress` 原始字段（含 `send=`／`time=`） |
| `E3_REPLAY_READ leg=… press=… deliver=… cand=… drop=… dt=… live_button=… b=…` | 从产品 `[E3-REPLAY]` 行抽出的核心读数 |
| `E3_REPLAY_LINE leg=… [E3-REPLAY] …` | 产品 `[E3-REPLAY]` 读数行**原文** |
| `E3_REPLAY_MAINCHAIN_UNCHANGED=…` | ④ 主链逐字节不变 |

---

## ② 判据（可证伪）＋ 反极性（必红）

| # | 判据 | 反极性 |
|---|---|---|
| **P-1（正腿·闸被行使）** | 腿 `R`（`grab`＋`WPF_E3_REPLAY_DEDUP=1`）末条 `[E3-REPLAY]`：`press=2 ∧ deliver=1 ∧ cand=1 ∧ drop=1 ∧ dt=0 ∧ live_btn=1 ∧ b=1`，且 `e3=DROP(replay:same-button+no-release+ordered)` | 腿 `F`（`nograb`＝**去掉重放源**）：`press=1 ∧ deliver=1 ∧ cand=0 ∧ drop=0` ⇒ **`cand` 必翻转** |
| **P-2（丢弃集合合法 ＋ 成对臂）** | 腿 `R`：`drop=1 ∧ (drop_set & ~replay_set)==0`（`subset_ok=1`）；腿 `D`（`grab`＋`WPF_E3_REPLAY_DEDUP=0`）：`cand=1 ∧ drop=0 ∧ deliver=2` | `D` 与 `R` 只有 `dedup` 开关不同 ⇒ **`drop` 必翻转**（`1→0`）且 `deliver` 恰多 1（`1→2`） |
| **P-3（样本非空·拒平凡真）** | 腿 `R`／`D`：`press>0 ∧ deliver>0 ∧ cand>0 ∧ replay_set≠0`（`0x2`） | 只跑无重放腿（`F`）⇒ `replay_set==0` ⇒ `subset_ok=1` 也是**平凡真**，**不得当绿** |
| **P-4（时间戳真实性·禁替身）** | 腿 `R`：产品原样打出的两条 `[KEY_DIAG] BTN type=Press` 行**同为** `send=0`（= 服务器自产）且 `time` **相同**（序关系不倒退，`dt=0`） | 用 `XSendEvent` 替身（`time` 置 1）⇒ `send=1` 且 `dt<0` ⇒ 闸按设计走 `DELIVER(other-button-or-dt-too-big)`、`cand=0` ⇒ **该腿必红** |
| **P-5（主链不变）** | `E3_REPLAY_MAINCHAIN_UNCHANGED=1`：`libwpfwin32.so ≤16` 与 `win32_x11.c ≤16` 作业前后**相同** | 一旦触碰主链 ⇒ 红（本波写域＝本目录） |

**红线（照抄 `build/MilBridge/P1-tail2-e3-recon.md` §④）**：**不得**为让夹具命中而放宽判据
（例如接受 `time=0/1` 的替身、或把 `bound` 放宽到吞掉真点击）。`dt` 判据是
**序关系（`dt>=0`）**，不是「时间戳相等」；本夹具命中的 `dt=0` 是**服务器重放同一条事件**
的自然结果，非人为构造。

---

## ③ 三条腿的定义

| 腿 | `mode` | `WPF_E3_REPLAY_DEDUP` | 重放源 | 期望（产品读数） |
|---|---|---|---|---|
| `R` | `grab` | `1`（缺省口径） | **有**（产品自身 X 连接上同步被动抓取 + `XAllowEvents(ReplayPointer)`） | `press=2 deliver=1 cand=1 drop=1 dt=0`；应用只见 **1** 条 `WM_LBUTTONDOWN` |
| `D` | `grab` | `0` | 有 | `press=2 deliver=2 cand=1 drop=0 dt=0`；应用见 **2** 条 `WM_LBUTTONDOWN` |
| `F` | `nograb` | `1` | **无** | `press=1 deliver=1 cand=0 drop=0 dt=-1` |

**装置侧旁证**（探针自打）：腿 `R` `down_msgs=1`、腿 `D` `down_msgs=2`、腿 `F` `down_msgs=1`
⇒ 「丢弃**真的没交付**」不只是计数器，而是**应用侧消息数**。

---

## ④ 重放怎么来的（本夹具的关键机制，写死防漂移）

1. **同步被动按钮抓取**：`XGrabButton(dpy, Button1, AnyModifier, xwin, False,
   ButtonPressMask|ButtonReleaseMask, **GrabModeSync**, GrabModeAsync, None, None)`，
   挂在**产品自己的 `Display*`**（`WpfLinuxWin32_GetX11Display()`）上。
   ⚠️ **必须 `Sync`**：`Async` 不冻结 ⇒ `XAllowEvents(ReplayPointer)` 无事可做（本仓
   `P1-tail2-e3-recon.md` §③-附 负向 4 就是栽在这里）。
2. **`uinput` 一条真按下**（服务器自产、真实时间戳）⇒ 抓取激活，投递第 1 条
   `ButtonPress`（`send=0`）。
3. 收到该条后调 `XAllowEvents(dpy, ReplayPointer, CurrentTime)` ⇒ 服务器**重放**同一条
   事件给"正常收件人" = 同一个窗口 ⇒ 第 2 条 `ButtonPress`（**同一 `time`、`send=0`**）。
4. ⇒ 闸看到「同 button ∧ 无中间 release ∧ `dt=0∈[0,bound]`」⇒ `cand++` ⇒（缺省）`drop++` 且 `break`。

**为什么抓取必须挂产品自己的连接**：抓取投递只给**抓取者**，重放才给"正常收件人"。
抓取者＝第三方客户端 ⇒ 产品只看到 1 条；抓取者＝产品自己 ⇒ 产品看到 2 条。

---

## ⑤ 主动披露（待裁决）

- **D-1 · 装置侧构造重放源**：本夹具**由探针在产品的 X 连接上挂抓取**来造重放源（真实
  重放，但触发者是夹具而非 WPF 下拉自身的捕获抓取）。本仓 `P1-e3-grab-recon.md` §3 已判
  「触发重放的那次抓取**不由本侧掌握**」⇒ 在**不改产品**、**不造第三方抓取**的前提下，
  这是唯一能让产品**自己**看到第二条 press 的路径。**待裁决**：这是否算"真重放"。
- **D-2 · 产品侧既存缺陷（本件撞到、未改）**：`WpfLinuxWin32_PumpOnce(timeout_ms>0)` 在
  `wake_read` 与 `xfd` 双双有效时，会往 `struct pollfd fds[1]` 写第 2 项 ⇒ glibc
  `__poll_chk` 判 "buffer overflow detected" 并 `abort()`（fortify 构建，本机实测核心转储）。
  本夹具**绕开**该入口（改用自己的 `poll(xfd)` ＋ `PeekMessageW`）。**未改产品**。
- **D-3 · `dt=0`**：重放事件与原事件**同 `time`** ⇒ 命中时 `dt=0`（判据是 `dt>=0`）。
  若上游认为"重放必须 `dt>0`"，本机制不满足——但 `win32_x11.c` 现取条件的字面是 `dt >= 0`。

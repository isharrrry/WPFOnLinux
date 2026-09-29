# `T-A2` 完成报告 · E3 真重放夹具（`TASK-0009`）—— **`cand>0` 已真跑出来**

> **角色**：实现子代理（写者）。**写域**＝`build/MilBridge/tests/E3ReplayProbe/**`（新建目录，
> 3 件：`e3replay-probe.c`／`run-e3replay-probe.sh`／`criteria-e3-replay-probe.md` ＋ 本报告）。
> **未碰** `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`src/**`／`docs/**`／
> `HANDOFF-NEXT.md`；**未改**产品 `.so`；**未**把夹具加进 `fp_inputs()`；**未**跑整趟 `verify-all`。
> 读时 `2026-09-30T01:0x+0800`；分支 `feat-Linux`；行号「仅本次有效」。

---

## ① 验收项 → 证据映射（逐条｜可复跑单行命令原文 ＋ 原始输出）

### ① 夹具脚本落仓（路径 ＋ sha16）＋「入口命令 ＋ 出口读数」

| 件 | 路径 | `sha256 ≤16` |
|---|---|---|
| 探针源码 | `build/MilBridge/tests/E3ReplayProbe/e3replay-probe.c` | `0c7209403a9d0f26` |
| 装置脚本 | `build/MilBridge/tests/E3ReplayProbe/run-e3replay-probe.sh` | `40585fd895291aa9` |
| 判据件 | `build/MilBridge/tests/E3ReplayProbe/criteria-e3-replay-probe.md` | `431a27d3fc51b41b` |
| 编译产物（**落在作业目录，不在仓内**） | `$OUT/e3replay-probe` | `f942069bc4892943` |

**入口命令（可复跑单行原文）**：
```bash
bash build/MilBridge/tests/E3ReplayProbe/run-e3replay-probe.sh --out=/tmp/e3replay-final
```
**出口读数**：`E3_REPLAY_BTN …`（原始 `ButtonPress` 字段）／`E3_REPLAY_READ leg=… press=… deliver=…
cand=… drop=… dt=… live_button=… b=…`／`E3_REPLAY_LINE leg=… [E3-REPLAY] …`（产品原文）／
`E3_REPLAY_MAINCHAIN_UNCHANGED=…`。见 §②。

### ② 核心读数：一条 `[E3-*]` 机读行，**同给** `cand`／`drop`／`dt`／`live_button`／`b`；样本非空

**原始输出逐字**（`/tmp/e3replay-final.driver`，腿 `R`＝抓取+去重开）：
```
E3_REPLAY_READ leg=R mode=grab dedup=on press=2 deliver=1 cand=1 drop=1 dt=0 live_button=1 b=1
E3_REPLAY_LINE leg=R [E3-REPLAY] ev=press btn=1 win=0x200001 x_time=20046985 click=1 press=2 deliver=1 drop=1 cand=1 replay_set=0x2 drop_set=0x2 subset_ok=1 dt_ms=0 bound_ms=250 bound_declared=0 dedup=on live_btn=1 e3=DROP(replay:same-button+no-release+ordered) gran=single-click via=client-path(motion+release-grab-out-of-range) noinfo=REPLAY-SOURCE,TOUCHPAD-SYNTH
```
⇒ **`cand=1>0`、`drop=1`、`dt=0`、`live_button=1`、`b=1`**，`e3=DROP(replay:same-button+no-release+ordered)`
⇒ 去重闸**被真正行使**（不是"没丢真点击"的假绿）。

**时间戳真实性（禁替身）**——产品原样打出的两条抓到的 `ButtonPress`（`WPF_LINUX_KEY_DIAG=1`）：
```
E3_REPLAY_BTN leg=R raw_ButtonPress_lines=2（原样：[KEY_DIAG] BTN type=Press btn=1 win=0x200001 state=0x0 time=20046985 send=0 subwin=0x0 xy=200,150 same_screen=1|[KEY_DIAG] BTN type=Press btn=1 win=0x200001 state=0x0 time=20046985 send=0 subwin=0x0 xy=200,150 same_screen=1）
```
⇒ 两条 **同 `time=20046985`、`send=0`**（服务器自产，**非** `XSendEvent` 替身）；原始 press 由
`evdev/uinput` 注入（`Xorg` 日志确认 libinput 认领设备；`E3_REPLAY_LEG … device_claimed=1`）。

### ③ 反极性（必红）—— **两对成对读数**

**对 A（去掉重放源 ⇒ `cand` 翻转）**：腿 `F`＝`nograb`：
```
E3_REPLAY_BTN leg=F raw_ButtonPress_lines=1（原样：[KEY_DIAG] BTN type=Press btn=1 win=0x200001 state=0x0 time=20053665 send=0 subwin=0x0 xy=200,150 same_screen=1）
E3_REPLAY_READ leg=F mode=nograb dedup=on press=1 deliver=1 cand=0 drop=0 dt=-1 live_button=1 b=1
```
⇒ `cand: 1 → 0`、`press: 2 → 1`（＝今日 12 腿形态）。

**对 B（把去重条件拆掉 ⇒ `drop`／`deliver`／应用侧消息数翻转）**：腿 `D`＝`WPF_E3_REPLAY_DEDUP=0`：
```
E3_REPLAY_READ leg=D mode=grab dedup=off press=2 deliver=2 cand=1 drop=0 dt=0 live_button=1 b=1
E3_REPLAY_LINE leg=D [E3-REPLAY] … cand=1 replay_set=0x2 drop_set=0x0 subset_ok=1 dt_ms=0 … dedup=off live_btn=1 e3=DELIVER(replay-cand-but-dedup=off) …
```
⇒ `drop: 1 → 0`、`deliver: 1 → 2`，且**应用侧消息数**同样翻转（装置侧旁证，见 §③）。

### ④ 主链 `.so`／`win32_x11.c` 逐字节不变（作业前后相同）

```
E3_REPLAY_PRE lib_sha16=26da177686acb1f0 win32_x11_sha16=4576fc68bcbbf329
E3_REPLAY_MAINCHAIN_UNCHANGED=1 lib_before=26da177686acb1f0 lib_after=26da177686acb1f0 src_before=4576fc68bcbbf329 src_after=4576fc68bcbbf329
```
独立复算（现取）：`sha256sum … | cut -c1-16` ⇒ `26da177686acb1f0`（`.so`）／`4576fc68bcbbf329`（`win32_x11.c`）。

### ⑤ 「造不出 `cand>0`」的路径 —— **未触发**（已造出，故无具名 `PRECOND-*`）

---

## ② 三条腿矩阵（**同一装置、同一注入路径**，只换一个变量）

| 腿 | `mode` | `WPF_E3_REPLAY_DEDUP` | 产品读数（`press/deliver/cand/drop/dt`） | 产品 `e3=` | 应用侧 `WM_LBUTTONDOWN` |
|---|---|---|---|---|---|
| `R` | `grab` | `1`（缺省） | `2/1/1/1/0` | `DROP(replay:same-button+no-release+ordered)` | **1**（重放那条被闸吞掉） |
| `D` | `grab` | `0` | `2/2/1/0/0` | `DELIVER(replay-cand-but-dedup=off)` | **2** |
| `F` | `nograb` | `1` | `1/1/0/0/-1` | `DELIVER(first-press)` | **1** |

**应用侧消息数旁证**（探针自打，`R.out`／`D.out`／`F.out`）：
`PROBE_RESULT mode=grab dedup=on down_msgs=1`／`mode=grab dedup=off down_msgs=2`／`mode=nograb dedup=on down_msgs=1`
⇒ 「丢弃**真的没交付**」不只靠闸的计数器，**应用侧真少了一条**。

---

## ③ 机制（本件最吃劲的一条发现）

`build/MilBridge/P1-tail2-e3-recon.md` §③-附四条负向读数之所以都没造出第二条 press，
**两处都可复现的错**：
1. 抓取用了 **`GrabModeAsync`** ⇒ 不冻结 ⇒ `XAllowEvents(ReplayPointer)` **无事可做**；
   必须是 **`GrabModeSync`**（本件已实测：`Async` 1 条、`Sync` 2 条）。
2. 抓取挂在**另建的第三方客户端**上 ⇒ 抓取投递给第三方、只有**重放**给产品 ⇒ 产品只见 1 条。
   抓取必须挂在**产品自己的 `Display*`**（`WpfLinuxWin32_GetX11Display()`）上，
   这样「抓取投递 ＋ 重放」**两条都到产品**。

⇒ 本夹具的形态：探针 `dlopen` 产品 `.so` → 用它的 Win32 ABI（`RegisterClassExW`／
`CreateWindowExW`／`ShowWindow`／`PeekMessageW`／`DispatchMessageW`）把**真产品窗口**摆上私有
`Xorg` → 在它的连接上 `XGrabButton(…, GrabModeSync, …)` → `uinput` 注入**一条**真按下 →
抓到抓取投递那条（`WM_LBUTTONDOWN`）后 `XAllowEvents(ReplayPointer)` ⇒ 服务器**重放**
（同 `time`、`send=0`）⇒ 闸命中。

**为什么 `dt=0`**：重放的是**同一条事件**（`time` 原样），故 `dt=0`；判据字面是 `dt>=0`，命中成立。

---

## ④ 收尾／纪律对账

| 项 | 读数 |
|---|---|
| `/dev/uinput` | 作业中 `crw-rw-rw-`（临时 `chmod 666`）⇒ 收尾 `E3_REPLAY_UINPUT_RESTORED perms=crw-------`（= `600`） |
| Xorg | `E3_REPLAY_XORG_STOPPED pid=581423 alive=0`；**只按 PID kill**（收尾闸 `trap` 兜底，含 sudo 包装进程） |
| 显示位 | 只用空闲 `:23x`（本次 `:230`）；`/tmp/.X11-unix/` 收工 ＝ `X0 X1 X10`（**无残留**） |
| 禁则 | 未用 `pkill`／`pgrep -f`；未 `sleep N` 盲等（一律**有界等待**：socket／`xdpyinfo`／设备认领／读数行） |
| 备份／写法 | 本件**只新增** 3 件（`e3replay-probe.c`／`run-e3replay-probe.sh`／`criteria-e3-replay-probe.md`）；**无既有件被改** ⇒ 无需 `cp -p` 备份。编译器产物落在 `$OUT`（**不在仓内留可执行件**）。 |

---

## ⑤ 自包含结论 ＋ 主动披露（待裁决）

**结论**：`TASK-0009` 的实质缺口——「使 `cand>0` 的第二条同 button press」——**已解**：
在私有 `Xorg`（vmware＋libinput）上，用 `evdev/uinput` 注入一条**真按下**，并在**产品自身
X 连接**上挂**同步被动抓取**＋`XAllowEvents(ReplayPointer)` ⇒ 服务器**重放**出第二条
`ButtonPress`（同 `time`、`send=0`），去重闸**被真正行使**：`cand=1 ∧ drop=1`；两对反极性
（去重源／去重开关）读数**按设计翻转**；主链 `.so` 与 `win32_x11.c` **逐字节不变**。

**主动披露（待裁决）**：
1. **D-1 装置侧构造重放源**：重放是**真的**（服务器自产、同 `time`），但**触发者是夹具**
   （探针在产品的连接上挂抓取），不是 WPF 下拉自身的捕获抓取。本仓 `P1-e3-grab-recon.md` §3
   已判「触发重放的那次抓取**不由本侧掌握**」⇒ 在**不改产品**的前提下，这是唯一能让产品自己
   看到第二条 press 的路径。**待队长裁决**：是否算"真重放夹具"。
2. **D-2 产品侧既存缺陷（本件撞到、如实报、未改）**：`WpfLinuxWin32_PumpOnce(timeout_ms>0)`
   在 `wake_read` 与 `xfd` 双双有效时会往 `struct pollfd fds[1]` 写第 2 项 ⇒ glibc
   `__poll_chk` 判 `*** buffer overflow detected ***` 并 **`abort()`**（本机 fortify 构建，
   实测核心转储；`bt`：#8 `__poll_chk` ← #9 `WpfLinuxWin32_PumpOnce`）。探针改用自己的
   `poll(xfd)` ＋ `PeekMessageW` **绕开**该入口。**本件未改产品**，只把读数挂账。
3. **D-3 `dt=0`**：现取闸条件字面为 `dt >= 0`，故 `dt=0` 合法；若上游要求「重放须 `dt>0`」，
   本机制（重放同一条事件）不满足——**判据本身未改**。
4. **D-4 `bound` 反极性不可用**：`dt=0` 对任何 `bound>=1` 都成立（`WPF_E3_REPLAY_DT_MS` 下界为 1），
   故反极性改用「去重源」与「去重开关」两条**真正会翻转**的腿（§①-③）。
5. **D-5 未跑整趟 `verify-all`**（出题边界），未入 `fp_inputs()`（不顶开另一写者的指纹面）。

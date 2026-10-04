# P1-tail2 · E3 组合框下拉「真重放夹具」只读侦察 ＋ 判据预登记（`T-A0`）

> **角色**：只读侦察子代理。**写域＝本件一行**（`build/MilBridge/P1-tail2-e3-recon.md`，唯一可写仓内文件）；`src/**`、`docs/**`、其它 `build/**` 一律**只读未改**。
> **环境**：`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`，`uid=1000(links-dev)`；队长 `sudo`（密码 `links`）仅用于探测／临时放权。
> **读时**：2026-09-30T00:3x+0800。**行号「仅本次有效」**，跨代必须重取。
> **目标**：为 `docs/ROUTES.md §13` 的 `TASK-0009`（E3 真重放夹具）回答：两条候选通道（`XI2`／`evdev/uinput`）的可及性＋可行性；去重闸现取定位；`PRECOND-E3-REPLAY-FIXTURE-MISSING` 可否解除。

---

## ① 通道对照表

| 通道 | 可及性判定（执行权） | 证据（命令＋输出） | 可行性判定 | 具体手段 |
|---|---|---|---|---|
| **`evdev/uinput`** | **需 root**（或设备写权）。设备节点 `crw------- root:root`，非 root 用户**不在 `input` 组**、无写权 | `ls -l /dev/uinput` ⇒ `crw------- 1 root root 10, 223`（初始）；`id` ⇒ `uid=1000 … 无 input 组`；`modinfo uinput` ⇒ `filename: (builtin)`（**内核内置，无需 `modprobe`**）⇒ 本任务经 `sudo chmod 666` 临时放权后 `crw-rw-rw-` | **✅ 实测可行（本次真跑通）**：uinput 虚设备被 X 服务器经 **libinput 热插拔**认领 ⇒ **press 以服务器自产事件（`synthetic NO`）到达，带真实递增服务器时间戳** | 建 `/dev/uinput` 设备（`UI_SET_EVBIT`=`EV_KEY/EV_REL/EV_SYN`、`UI_SET_KEYBIT`=`BTN_LEFT`、`write(uinput_user_dev)`、`UI_DEV_CREATE`）→ 需要**一个吃 evdev 的 X 服务器**（`Xorg`+`libinput`，**`Xvfb` 不吃 evdev**）→ 标量命令：`Xorg :231 -config <vmware/libinput>` ＋ `write EV_KEY/BTN_LEFT=1,+EV_SYN` |
| **`XI2`** | **无需 root**（客户端扩展：任何有 display 访问权者即可） | `id` ⇒ `uid=1000` 直接跑：`DISPLAY=:231 xinput --version` ⇒ `xinput version 1.6.3／XI version on server: 2.4`；`xdpyinfo` ⇒ `number of extensions: 28 … XInputExtension` | **❌ 不可行（作为"注入"通道）**：`libXi` **无任何事件注入原语**（`nm -D libXi.so.6 \| grep ' T '` 只有 `XGrabDevice*/XIGrab*/XIUngrab*/XIAllowEvents/XSendExtensionEvent`，**无 `XISendEvent`／`XIFake*`**）⇒ `XI2` 只能"选取／查询／抓取／放行"，**不能自产带真实服务器时间戳的 press**。**注**：带真时间戳的注入原语在 **XTEST**（`libXtst`：`XTestFakeButtonEvent`／`XTestFakeDeviceButtonEvent`），不在 `XI2`；而 `XTest` 第二条 press 已被本仓实测服务器忽略 | 若硬用：`XIGrabButton`(passive)＋`XIAllowEvents(XIReplayDevice)` 试图触发**服务器侧重放**；本次以 core 版 `XGrabButton`+`XAllowEvents(ReplayPointer)` 探测，**未复现第二条 press**（见 §③-附） |

### 补：设备／头文件齐备度（影响 `TASK-0009` 落地手段）
- **在位**：`Xorg`／`Xvfb`／`xdotool`／`xinput`／`xev`／`xdpyinfo`／`xfwm4`／`python3`／`gcc`／`setsid`。
- **缺失**：`/usr/include/X11/extensions/` **整目录不存在** ⇒ **无 `XInput2.h`／`XTest.h` 头**（本仓前件 `P1-e3-replay-report.md` §8-2 已记同一坑）⇒ 任何 `XI2`／`XTest` 夹具须**自带头声明**或用 `ctypes`／`dlsym` 直调 `libXi.so.6`／`libXtst.so.6`。
- **无 root 依赖**：`XI2`／`XTest` 路径均不需 root；`uinput` 需 root。

---

## ② 去重闸**现取行原文**（`src/WpfGfx.Linux.Native/src/win32_x11.c`，**行号仅本次有效**）

**现取件代**：`sha256`(16)＝`4576fc68bcbbf329`／`wc -l`＝`2189`（＝`P1-e3-replay-report.md` §6 所载收尾代，逐位相符）。
**取法**：`sed -n '1357,1395p' src/WpfGfx.Linux.Native/src/win32_x11.c`（整行取，逐字）。

```c
            /* ⏪ 【波 59 · E3】客户区路径的**抓取重放去重闸**（三项合取 ③′＋②＋①；见文件头注释） */   /* :1357 */
            {                                                                                          /* :1358 */
                const int is_btn123 = (b == Button1 || b == Button2 || b == Button3);                  /* :1359 */
                if (is_btn123 && down) {                                                               /* :1360 */
                    const int dt = (g_x_e3_live_button == (int)b)                                      /* :1361 */
                                 ? (int)(ev.xbutton.time - g_x_e3_live_time) : -1;                     /* :1362 */
                    g_x_e3_press++;                                                                    /* :1363 */
                    if (g_x_e3_live_button == 0) {          /* 新点击：② 开窗（首条 press 即将交付） */ /* :1364 */
                        g_x_e3_click_no++;                                                             /* :1365 */
                        g_x_e3_live_button = (int)b; g_x_e3_live_time = ev.xbutton.time;               /* :1366 */
                        g_x_e3_deliver++;                                                              /* :1367 */
                        wpf_e3_note("press", (int)b, (unsigned long)(uintptr_t)h, ev.xbutton.time,     /* :1368 */
                                    dt, 0, 0, "DELIVER(first-press)");                                 /* :1369 */
                    } else if (g_x_e3_live_button == (int)b && dt >= 0 && dt <= wpf_e3_dt_bound_ms()) { /* :1370 */
                        /* ③′ 命中：同 button ∧ 无中间 release ∧ 序关系（time 不倒退）∧ 间隔 ≤ 界 */    /* :1371 */
                        g_x_e3_cand++; g_x_e3_replay_set |= (1UL << (b & 31));                         /* :1372 */
                        if (wpf_e3_dedup_on()) {                                                       /* :1373 */
                            g_x_e3_drop++; g_x_e3_drop_set |= (1UL << (b & 31));                       /* :1374 */
                            wpf_e3_note("press", (int)b, (unsigned long)(uintptr_t)h, ev.xbutton.time, /* :1375 */
                                        dt, 1, 1, "DROP(replay:same-button+no-release+ordered)");      /* :1376 */
                            break;                          /* ← **不交付**：本条的 `produced` 不涨 */    /* :1377 */
                        }                                                                              /* :1378 */
                        g_x_e3_deliver++;                                                              /* :1379 */
                        wpf_e3_note("press", (int)b, (unsigned long)(uintptr_t)h, ev.xbutton.time,     /* :1380 */
                                    dt, 1, 0, "DELIVER(replay-cand-but-dedup=off)");                   /* :1381 */
                    } else {                                                                           /* :1382 */
                        /* ③′ 不成立（异 button／间隔过大／无活窗）⇒ **照常交付**并重置基准 */           /* :1383 */
                        g_x_e3_live_button = (int)b; g_x_e3_live_time = ev.xbutton.time;               /* :1384 */
                        g_x_e3_deliver++;                                                              /* :1385 */
                        wpf_e3_note("press", (int)b, (unsigned long)(uintptr_t)h, ev.xbutton.time,     /* :1386 */
                                    dt, 0, 0, "DELIVER(other-button-or-dt-too-big)");                  /* :1387 */
                    }                                                                                  /* :1388 */
                } else if (is_btn123 && !down) {            /* 抬起：关窗（②的窗口在 release 处结束） */ /* :1389 */
                    if (g_x_e3_live_button == (int)b) g_x_e3_live_button = 0;                          /* :1390 */
                    wpf_e3_note("release", (int)b, (unsigned long)(uintptr_t)h, ev.xbutton.time,       /* :1391 */
                                -1, 0, 0, "DELIVER(release)");                                         /* :1392 */
                }                                                                                      /* :1393 */
            }                                                                                          /* :1394 */
            push(t, h, m, mk, xy_lparam(ev.xbutton.x, ev.xbutton.y),                                   /* :1395
                 ev.xbutton.x, ev.xbutton.y);                                                          /* :1396 */
```
> ⚠️ 上方行号为**我本次加注**，原文无行号；`push` 落在 `:1395-1396`（`produced++;` 在 `:1397`）。

### 判定条件逐字（现取 `:307-316` 文件头注释 ＋ `:340-353` 读数行 ＋ `:324-336` 两个环境读取器）
- **③′ 命中（候选）**＝ `g_x_e3_live_button == (int)b` **∧** `dt >= 0` **∧** `dt <= wpf_e3_dt_bound_ms()`（`:1370`）。
- **`dt` 定义**＝ 同 button 时 `(int)(ev.xbutton.time - g_x_e3_live_time)`，否则 `-1`（`:1361-1362`）。
- **② 限窗**＝ `g_x_e3_live_button` **仅在「首条 press 已交付且尚未 release」期间非 0**（`:311`、`:1364`、`:1390`）。
- **① 仅作排除**＝ **只作用于客户区路径**（NC 按下在 `:1286` 区已 `break`，不在射程；本侧唯一显式抓取 `wpf_x11_pointer_grab()` 用途＝NC 拖动）。
- **界**＝ `WPF_E3_REPLAY_DT_MS` 缺省 `250`，`v<1 ⇒ 1`（`:329-336`）。
- **开关**＝ `WPF_E3_REPLAY_DEDUP`：**缺省开**；`0` ⇒ 关（反腿对照）（`:324-328`）。
- **分界**＝ `subset_ok ⇔ (drop_set & ~replay_set) == 0`（`:350`）。
- **禁则（逐字，`:314`）**：「🔴 **不得以"丢弃真点击"换"下拉不被关"**：三条任一不满足 ⇒ **照常交付**并打 `e3=DELIVER(…)`」；`:315`：「🔴 读数行**无条件**打印（`t196` §6 条款「读数类静默阈值」）」。

---

## ③ `uinput` 实测**成对读数**（`/dev/uinput` 可写 ⇒ 两态）

**可复跑单行命令原文**（脚本 `/tmp/e3recon/repro.sh`，自包含：建私有 `Xorg :231` → 临时放权 → `xev` 监视 → `uinput` 一条 press → 收尾）：
```bash
bash /tmp/e3recon/repro.sh
```

**态 A —— 设备创建成功**（原始输出，逐字）：
```
### [4] 设备在位读数（id 应为 e3recon-mouse）
⎜   ↳ Virtual core XTEST pointer              	id=4	[slave  pointer  (2)]
⎜   ↳ VirtualBox mouse integration            	id=9	[slave  pointer  (2)]
⎜   ↳ ImExPS/2 Generic Explorer Mouse         	id=11	[slave  pointer  (2)]
⎜   ↳ e3recon-mouse                           	id=12	[slave  pointer  (2)]
### [6] Xorg 日志：libinput 认领该设备
[ 18213.975] (II) config/udev: Adding input device e3recon-mouse (/dev/input/mouse1)
[ 18214.002] (II) config/udev: Adding input device e3recon-mouse (/dev/input/event5)
[ 18214.002] (**) e3recon-mouse: Applying InputClass "libinput pointer catchall"
[ 18214.002] (II) Using input driver 'libinput' for 'e3recon-mouse'
```
**态 B —— 一条 press 确实到达 X 服务器**（`xev`；原始输出，逐字）：
```
### [5] xev 收到的 press（synthetic NO = 服务器自产）
ButtonPress event, serial 28, synthetic NO, window 0x200001,
    root 0x541, subw 0x0, time 18216056, (148,98), root:(200,150),
    state 0x0, button 1, same_screen YES
```
**XI2 raw 佐证**（独立第二通道验；`xinput test-xi2 --root` 原始输出，逐字）：
```
EVENT type 15 (RawButtonPress)
    device: 2 (12)
    detail: 1
EVENT type 4 (ButtonPress)
    device: 12 (12)
    detail: 1
```
**三态合判**：`synthetic NO` ⇒ 事件**由服务器自产**（非客户端 `XSendEvent` 替身）；`time 18216056` 为**服务器单调时间**（同趟 `ButtonRelease` `time` 更大 ⇒ **有序**）；设备 id 12 ＝ `e3recon-mouse`。⇒ **`uinput` 通道满足"带真实服务器时间戳、有序"这一实质要求**。

**态 A'/B' 收尾（按 PID）**：`sudo kill <Xorg :231 PID>`；`sudo chmod 600 /dev/uinput` ⇒ `crw------- root root`（**已复原**）；`ls /tmp/.X11-unix/` ⇒ `X0 X1 X10`（**无残留**）。

### 附：三条**负向**读数（供 `TASK-0009` 定"重放触发点"，本次均**未**产生第二条 press）
> 脚本：`bash /tmp/e3recon/run_uinput_test3.sh`（同设备连发两次）、`run_uinput_test4.sh`（双 uinput 设备各发一次）、`run_grab_test.sh`（按住时 `XGrabPointer`）、`run_grab_test2.sh`（passive `XGrabButton`+`XAllowEvents(ReplayPointer)`）。
1. **同设备连发 `down;down`（无 release）** ⇒ `xev` `ButtonPress` 计数＝**1**（内核 input 核对同值 `EV_KEY` 去重）。
2. **两个 uinput 设备各发一次 `BTN_LEFT`（Δ≈50 ms）** ⇒ 核心 `ButtonPress` 计数＝**1**（主指针 bit 聚合）。
3. **按住 button 时本 client `XGrabPointer(同窗口, owner_events=True)`** ⇒ 抓取后**无重放**（`ButtonPress` 仍只有原始 1 条，`send_event=0`）。
4. **passive `XGrabButton`+`XAllowEvents(ReplayPointer)`**（`owner_events`=True／False 各一趟）⇒ 各得 `ButtonPress` **1**／`ButtonRelease` **1**。
⇒ **在本探针设置下，"第二条同 button press（无中间 release）"形态未复现** —— 该"重放触发点"属 `TASK-0009` 的夹具设计问题（见 §⑤ 主动披露）。

---

## ④ 判据预登记草案（供 `TASK-0009` 实现件照抄；≥3 条可证伪 ＋ 反极性）

> 由本件提出、**未落地**；`TASK-0009` 落地前须按 `PORT-SPEC §1` 写死器件代与命令。

| # | 判据（可证伪） | 反极性（必红） |
|---|---|---|
| **P-1** | **真重放腿 `cand>0`**：在 `uinput` 建真设备的点击腿，读数行 `cand>=1` 且 `replay_set != 0`（**判据③逐字：`cand>0 ∧ drop≥0`**） | 去掉重放源（不触发抓取重放／不建设备）⇒ `cand=0`（＝今日 12 腿形态） |
| **P-2** | **丢弃生效且集合合法**：`DEDUP=on` 时该腿 `drop>=1 ∧ (drop_set & ~replay_set)==0`（`subset_ok=1`） | 同装置同序列仅换 `WPF_E3_REPLAY_DEDUP=0` ⇒ `drop=0` 且 `deliver` 恰多 1（成对臂） |
| **P-3** | **样本非空（禁空集平凡真）**：`press>0 ∧ deliver>0 ∧ cand>0`；且 `replay_set≠0`（拒"两集合皆空的 `subset_ok=1`"） | 只跑真点击不含重放 ⇒ `replay_set==0` ⇒ 判 **`NOINFO`／不得当绿** |
| **P-4** | **时间戳真实性（禁替身）**：重放事件 `x_time` 必须**服务器自产**（采集侧 `synthetic NO`／`send_event=0`）且 `dt>=0`（**序关系，非"时间戳相等"**） | 用 `XSendEvent` 替身（`time` 置 1）⇒ `dt<0` ⇒ 闸按设计 **`DELIVER(other-button-or-dt-too-big)`**、`cand=0` ⇒ **该腿必红** |
| **P-5** | **主链不变**：`src/WpfGfx.Linux.Native/src/win32_x11.c` 与 `bin/libwpfwin32.so` 在本夹具波内**逐字节不变**（代际位现取比对） | 一旦触碰主链 ⇒ 该判据红（写域＝`build/MilBridge/tests/**`＋判据件） |

> ⚠️ 预登记**红线**（照抄 `:52`）：**不得**为让夹具命中而放宽判据（例如接受 `time=0/1`）——那正是"退化到不可靠签名"的老路。

---

## ⑤ 结论行

- **`PRECOND-E3-REPLAY-FIXTURE-MISSING` ⇒ 判 `可解(通道=evdev/uinput)`** —— 该前置的实质缺口（"**能携带有序服务器时间的事件注入通道**"）已由 `uinput` 通道**实测填上**（§③：设备建立 ＋ press 到达服务器，`synthetic NO`＋真实递增 `time`）。
- **配套约束（`TASK-0009` 必读）**：① `uinput` 路径**需 root／设备写权**，且**必须有一个吃 evdev 的 X 服务器**（`Xorg`+`libinput`；**`Xvfb` 不吃 evdev ⇒ 用 `Xvfb` 腿跑不出本通道**）；② `XI2` **不能**作注入通道（无注入原语，§①），只能作**观测量**（`xinput test-xi2`／`XRecord`）；③ 头文件 `XInput2.h`／`XTest.h` **本机缺失**（§① 补）。
- **⚠️ 待裁决（不改变上面的 `可解` 判定，但 `TASK-0009` 必须先解决）**：本次§③-附**四条负向读数**显示，`uinput`/`XGrabPointer`/`ReplayPointer` 在本探针设置下**都未复现"第二条同 button press"** ⇒ 使 `cand` 真正 `>0` 的**"抓取重放触发点"仍未定位**（本条属**夹具设计**，非通道可及性）。

---

## §完成报告

### 验收项 → 证据映射
| 验收项 | 证据（可复跑单行命令原文 ＋ 原始输出） |
|---|---|
| ① 通道对照表 | §① 两行；命令原文：`ls -l /dev/uinput`／`id`／`modinfo uinput`／`DISPLAY=:231 xinput --version`／`DISPLAY=:231 xdpyinfo \| grep -i XInputExtension`／`nm -D /usr/lib/x86_64-linux-gnu/libXi.so.6 \| grep ' T '`（输出见 §①） |
| ② 现取行原文 | §②：`sed -n '1357,1395p' src/WpfGfx.Linux.Native/src/win32_x11.c`；`sha256sum …\|cut -c1-16`⇒`4576fc68bcbbf329`；`wc -l`⇒`2189` |
| ③ uinput 成对读数 | §③：`bash /tmp/e3recon/repro.sh`（态 A：`xinput list` id 12 ＋ Xorg 日志 libinput 认领；态 B：`xev` `ButtonPress … synthetic NO, time 18216056` ＋ XI2 `RawButtonPress device 12`） |
| ④ 判据预登记草案 | §④ 五条（P-1…P-5）＋各反极性 |
| ⑤ 结论行 | §⑤：`可解(通道=evdev/uinput)` |
| 边界：只读／临时放权已复原／按 PID 收尾 | 全趟仅写本件；`sudo chmod 666 /dev/uinput` → 收尾复原 `600`；`Xorg :231` `sudo kill <PID=438887>`；`/tmp/.X11-unix/`＝`X0 X1 X10`；**未碰** `/etc`／任何仓内文件；**未** `pkill`／`pgrep -f` |

### 自包含结论
- **背景**：`TASK-0009` 需一个"真重放夹具"让 E3 去重闸（`win32_x11.c` 客户区路径，`:1357-1394` 闸、`:1395` push）在真点击下被行使（`cand>0`）。今日 `cand=0`（支路未行使）。
- **做了什么**：探测两条候选通道的可及性／可行性；现取闸判定条件；在**私有 `Xorg :231`（vmware 驱动＋libinput 热插拔）**上真跑 `uinput` 注入。
- **验证了什么**：`uinput` 设备被 X 服务器认领（id 12），其 press **以服务器自产事件到达**（`synthetic NO`、真实递增 `time`）⇒ **注入通道成立、时间戳真实**；`XI2` **无注入原语**（`libXi` 导出清单为证），只能观测。
- **遗留什么**：使 `cand>0` 的"**第二条同 button press**"触发点**未复现**（四条负向读数）；`TASK-0009` 须先定位该触发点，再照 §④ 落地判据。

### 主动披露（规格与事实不符／待裁决）
1. **规格与事实不符**：任务表述将 `XI2` 列为与 `uinput` 并列的"候选通道"，但 `XI2` **协议本身不含事件注入原语**（`libXi.so.6` 导出无一可用于合成 press）；带真时间戳的注入原语实际在 **XTEST**（`libXtst`）与 **`uinput`**。⇒ 本件把 `XI2` 判为**仅可观测**（用于 `xev`／`xinput test-xi2`／`XRecord` 验证），**不作注入通道**。**待队长裁决**。
2. **`Xvfb` 不能承载本通道**（关键装置约束）：`Xvfb` 无 evdev 输入层 ⇒ `uinput` 事件**到不了** `Xvfb`；须 `Xorg`+`libinput`。本件已用 `Xorg :231`（vmware 驱动）验证。⇒ 若 `TASK-0009` 沿用 `Xvfb` 腿，`uinput` 通道**结构性失效**。
3. **"重放触发点"仍未定位**（§③-附四负向）：`D-G50` 注释所称"抓取激活时重放当前按住键"在**本探针设置下未复现** ⇒ 该机理表述**待现取复核**（可能是别源，如触控板合成／应用自身二次派发）。本件**不宣称**该注释错，只如实记"本设置下未复现"。
4. **为探测临时放开了 `/dev/uinput`（666）**，收尾**已复原为 600**；**未**改任何持久系统配置。
5. **`/etc` 未写**；本件未触碰 `/etc` 下任何文件（无需声明持久写）。

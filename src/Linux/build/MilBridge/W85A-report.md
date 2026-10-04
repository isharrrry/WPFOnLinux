# W85A 报告 —— `TASK-0203`：静默 `rc=139`＋0 字节日志的**两极化长跑**

车道 W85A ｜ 任务书：两臂各 **N≥15** 趟，把"静默 `139`＋0 字节"的上界压到 **≤20%**；
拿到两极化 ⇒ 判决点到"我们引入的那一处"；都不命中 ⇒ 如实 `NOINFO`＋新上界＋再压到 `≤5%` 的代价。
前序：W63A `REPORT.md`（阳性对照 `C101`、无 WM 腿）｜W77A `build/MilBridge/W77A-report.md` `af9987e29f761e78`（6+6 趟、两臂签名逐字段相同、0 命中）。
判据**先写死**：`$HOME/w85a/criteria.md`，sha16 **`95d23c292007a5e9`**（在第一条样本之前写成）。

---

## 0 一句话判决

**用户那个签名（静默 `rc=139`＋0 字节）本趟跑了 80 趟有效样本仍然 0 命中 —— 但本趟拿到了真两极化，而且它比预期值钱：
"崩不崩"跟着「点击能不能落地」走，"点击能不能落地"跟着「**有没有窗口管理器**」走。**

| | 无 WM（`:38`） | 有 WM（`:37`，xfwm4） |
|---|---|---|
| **修前件** `abf6879c027c5e73` | 9 击**全落地**（`tab3 AE≈182k–480k`）⇒ **15/15 趟全在"点页签"那一击整进程死**：`rc=134`＋`Stack overflow.`（13 趟 6.4–6.5 MB 全量形／2 趟 19 KB 折叠形，见 §5.1） | 点击**从第 2 击起全被吞**（`AE=0`；落地 2/13 击）⇒ 全程 `alive` |
| **修后件** `3e4390c9ec07f621` | 同一套 9 击**全落地**（落地 16/18 击），页签真的换页 ⇒ **15/15 活满窗口**（`rc=124`） | 活满窗口（`rc=124`） |

⇒ **判决点拿到了**（对"两 `.so` 的改动集"可归因）：回声环 `D-G66` 的修法在修后件里**确实关掉了环**
（修前件日志里 `SetFocus` 14,676 行、`FilterMessage` 5,872 行，栈顶闭合在
`HwndKeyboardInputProvider.FilterMessage ← OnSetFocus ← ReportInput ← … ← NativeMethodsSetLastError.SetFocus`）。
**这就是 W77A「两臂签名逐字段相同」的真因：它的修前臂点击腿是死的**（见 §3 仪器缺陷 F2）。

**同时必须说清一件事**：本趟两极化的是 **`134`（响亮、托管）**那一族，**不是**用户报的 **`139`＋0 字节**。
`139` 那一族本趟 0 命中（见 §8），判决只能到 `NOINFO`（见 §9）。

---

## 1 装置与世代位（全部现场 `sha256sum`，不手抄）

- 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**本趟只写报告一个文件**，见 §11）。
- **私有显示**：`:37` = `Xvfb :37 -screen 0 1024x768x24` ＋ `xfwm4 --compositor=off`（**有 WM**，`xprop -root _NET_SUPPORTING_WM_CHECK` 非空已核）；
  `:38` = `Xvfb :38 -screen 0 1024x768x24`（**无 WM**，同一探针现场为 `no such atom on any window`）。两者 `xdpyinfo` 均 `1024x768`。
- **三棵私有 app 副本**（`cp -a` 全量；换 `.so` 用"先 `rm` 再 `cp`"，不用硬链接以免连带改源）：

| 代号 | 路径 | `HandyControlDemo.dll` | `wpfgfx_cor3.so` | `libwpfwin32.so` |
|---|---|---|---|---|
| `T-post` | `$HOME/w85a/app` | `1ac5e587cda3fb20` | `79e45aed26487045` | **`3e4390c9ec07f621`**（= 仓内权威件 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 现场值） |
| `T-pre` | `$HOME/w85a/app-pre` | `1ac5e587cda3fb20`（同树） | `79e45aed26487045`（同树） | `abf6879c027c5e73`（W63A `D-G66` 修前件） |
| `T-oldpre` | `$HOME/w85a/app-old` | `9f747a504356d26a` | `e3ea092010734f44` | `abf6879c027c5e73` |

⇒ **`T-post` 与 `T-pre` 唯一变量 = `libwpfwin32.so`**（每趟 `meta.txt` 里现场算的 `SHIM/BRIDGE` 字段即证）。
- **两 `.so` 的差（现场 `nm -D` 现算）**：导出 **532 → 518**，**修前少 14 个、反向 0 个**：
  `wpf_x11_apply_wm_state`／`wpf_x11_apply_wm_hints`／`wpf_x11_set_decorations`／`wpf_x11_client_size_limit`／
  `wpf_x11_iconify`／`wpf_x11_moveresize_window`／`wpf_x11_pointer_grab`／`wpf_x11_workarea`／`wpf_x11_screen_size`／
  `wpf_x11_has_ewmh_wm`／`wpf_core_window_state`／`wpf_core_custom_chrome`／`wpf_core_nc_hit_test`／`wpf_core_note_framechanged`。
  ⇒ **判决点最多下到"这 14 项所在的改动集"**，不许再往下点单一函数（§6 边界）。
- ⚠️ **树的外在效度边界**：本趟三棵树里的托管件/桥取自 hc app-local（`1ac5e587cda3fb20` / `79e45aed26487045`），
  而仓内**现行权威**件是 `pc 56ee75ced8d6aece`／`pf 6375fabf89ac7fef`／`bridge feef049e9d0e313a`（现场算）；
  app-local 相对它们**已陈旧**（即路线图记的 `APPSYNC MISMATCH=9[STALE=9]` 状态）。
  本趟两臂**共用同一棵树**⇒ 两极化结论对该树成立；"换成 #49/#50 权威树还成不成立"**本趟没测**。
- 内存纪律：每条重活 `bash ~/heavy-slot.sh --min-avail 1500 --max-hold 260 -- timeout ≤150 <命令>`；
  同时只跑一个重活（实测本趟被别的车道排队多次，见 §12）；`MAXHOLD_KILL`／`NOINFO low-memory` 的趟**不进分母**。
- 全程**未** `pkill -f`（一律数字 PID）；收工现场 `Xvfb :37/:38` 与 `xfwm4` 按 PID 收（见 §12）。

---

## 2 判据（先写死；原文 `$HOME/w85a/criteria.md` sha16 `95d23c292007a5e9`）

**一次样本**：机级槽内、`cwd=<私有 app 副本>`、仪器全关（`HC_*`/`WPF_*` 现场计 0）、私有显示上启动
`dotnet HandyControlDemo.dll`（`ARM=gdb` 时外套故障循环），完整记录 `rc`／日志字节／故障／致命性／`oom`。
**命中"用户签名"（四条合取，缺一不算）**：① `rc=139`；② `app.log+app.err` 字节 **= 0**；③ `Unhandled exception` **= 0**；
④ gdb 判该 SIGSEGV **致命**（`APP_DIED=yes` ∧ `DIED_SIG` 含 `SIGSEGV`）。
**无效样本**（不进分母）：`HEAVYSLOT=TIMEOUT/MAXHOLD_KILL/NOINFO low-memory`、`rc=127`、45 s 内无窗口、`oom=1`。
**频率上界**：0 命中用规则 of three（`3/N`）；`N=15 ⇒ 18.1%`（本题目标 ≤20%）。
**阳性对照判据**：`rc=134` ∧ `STACKOVF≥1` ∧ 日志 ≥ 1 MB（= W63A `C101` 的签名）。
**先写死的归因规则**：阳性对照只有 `T-pre`（只换 shim）成立时，两臂才有归因力；若只在 `T-oldpre` 成立 ⇒ 崩属旧树、两臂无检测力。

---

## 3 仪器自检（**先做，否则 0/N 无意义**）＋ 两处仪器缺陷

### 3.1 自检读数（`$HOME/w85a/bin/selftest-gdb.sh`；同一份模板＋同一个 `classify.py`）

| 合成件 | 期望 | 实测 |
|---|---|---|
| `segv/recur`（原生深递归） | 抓深栈、判 `stack_exhaust`、跑到底 | `bt` **100 帧**、`kind=stack_exhaust`、`period=2500`、`COMMANDS-RAN-TO-END=yes` |
| `segv/wild`（原生野指针） | 抓浅栈、判 `other_native`、跑到底 | `bt` **1 帧**、`kind=other_native`、`COMMANDS-RAN-TO-END=yes` |
| **两趟都** | `APP_DIED` 通路**必须亮** | `APP_DIED_PATH=yes`、`DIED_SIG: Program terminated with signal SIGSEGV, Segmentation fault` |

⇒ 仪器**有判别力**，且"致命 SIGSEGV 会被认出来"这条**本趟新加的断言**已点亮（这是下面所有 `0/N` 能被信任的前提）。

### 3.2 仪器缺陷 **W85A-F1**（W77A 的副本里，`APP_DIED` 结构性恒假）

W77A 的 `bin/gdb.cmds.tmpl` 被它自己 sed 成 `W77A-*` 标记（`669a8a372ef55c2d`），
但它的 `bin/one.sh`（`4938db46e2279b53`）第 149 行仍是 `grep -aq 'W63A-TERMINATED'`
⇒ **`APP_DIED` 永远 `no`**、`FATAL` 永远是 `no(handled->alive)`。
**影响范围（不许读宽）**：W77A 的 `rc=124`（`timeout` 收走 = 窗内一直活着）**不受影响**；
但它报告里 `FATAL`／`APP_DIED` 两列**没有检测力、不许引用**。
本车道把标记统一成 `W85A-*` 并用 §3.1 的 `wild` 趟**点亮**验证。

### 3.3 仪器缺陷 **W85A-F2**（从 W77A 的原始读数里读出来的；这是它"两臂同签名"的真因）

W77A 的 `run/Dpre01/clicks.txt` 与 `run/Ngpre1/clicks.txt`（**修前臂**）：`nav1 AE=347304` 之后
`nav9/ctrl_tb/nav10/ctrl_cb/nav2/tab3/nav3 **AE=0**`；而同一条腿的**修后臂** `Dpost01/Ngpost1` 每一击 `AE` 都很大
（`nav9 AE=209400`、`ctrl_cb AE=36213`、`POPUP_AFTER_OPEN new=0x2014c5`、`tab3 AE=182159`）。
⇒ **修前臂的点击腿在第 1 击之后就没再落地**（本趟 `CAL` 腿把机制收窄了：**不是坐标失效** —— 几何逐击不变；
是**输入被吞，而且跟着 `shim` 走**：同一 WM 上修后件 4/4 落地、修前件第 1 击后 0/3 落地，见 §7.3），
而 W77A 把这一格读成"只差 `ENTRY_N` 8 vs 9，属点击腿节拍差"（它 §5.3 的原话）——
`ENTRY_N` 数的是**脚本走了几步**，不是**点击落了几次**。**本趟自己的读数是同一形状**（§4 的 WM 两格）。

---

## 4 阳性对照：`C101` 今天还成立吗（2×2，各 2 趟；`nogdb`+`click`+`TO=60`）

**腿与判据**（先写死，`criteria.md` §5）：`PC-A`=`T-oldpre` 无 WM；`PC-B`=`T-pre` 无 WM；`PC-C`=`T-oldpre` 有 WM；`PC-D`=`T-pre` 有 WM；
"复现" ⇔ `rc=134` ∧ `STACKOVF≥1` ∧ 日志 ≥1 MB。

| tag | batch | shim | rc | 日志字节 | stackovf | UNH | app_died | fatal | verdict | oom | device | 命中139 | 命中134 | 窗口 | 点/落 | 末击 | 死时s |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `PCA1` | PC | `abf6879c027c5e73` | **134** | 6481832 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav3 | 32 |
| `PCA2` | PC | `abf6879c027c5e73` | **134** | 6589464 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav3 | 32 |
| `PCB1` | PC | `abf6879c027c5e73` | **134** | 6489014 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav3 | 31 |
| `PCB2` | PC | `abf6879c027c5e73` | **134** | 6482785 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav3 | 34 |
| `PCC1` | PC | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | 61 |
| `PCC2` | PC | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | 60 |
| `PCD1` | PC | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 122,142 800x600 | 2/8 | nav3 | 60 |
| `PCD2` | PC | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | 60 |

**读数**（全部现场算，见 `$HOME/w85a/collect.tsv`）：

| 条件 | `C101` 签名（`134`＋`Stack overflow.`＋≥1 MB） | 点击落地（`AE>1000` 的击数/总击数） | 窗口几何 | 死在第几击 |
|---|---|---|---|---|
| **`PC-A` 旧树＋修前件・无 WM** | **2/2**（6,481,832／6,589,464 B） | **8/9、8/9** | `112,84 800x600` | 第 8 击（`tab3`）→ `nav3` 跳过 |
| **`PC-B` 现树＋修前件・无 WM** | **2/2**（6,489,014／6,482,785 B） | **8/9、8/9** | `112,84 800x600` | 同上 |
| **`PC-C` 旧树＋修前件・有 WM** | **0/2**（`rc=124`、0 B、活满 60 s） | 1/8、1/8 | `122,142 800x600` | —— |
| **`PC-D` 现树＋修前件・有 WM** | **0/2**（`rc=124`、0 B、活满 60 s） | 2/8、1/8 | `122,142 800x600` | —— |

**这一格回答了三个问题**（而且每个都有成对读数）：

1. **W63A 的阳性对照 `C101` 今天仍成立，且不依赖它那棵旧树**：`PC-A`（原树）与 `PC-B`（**只换树、shim 不变**）**同样 2/2 复现**
   ⇒ **这个崩是"修前 `libwpfwin32.so` 单独"带来的，不是托管件/桥**。
   于是**两臂（唯一变量 = `.so`）对这个崩是有检测力的** —— 与 W77A §5.4「这套装置不能归因」的结论**相反**，差别在条件（见 3）。
2. **`PC-A` 与 W63A `C101` 逐字段吻合**：`800x600@+112+84`、`ENTRY_N=8`、
   `ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3`、死在第 8 击（`tab3`）、`rc=134`、日志量级 6.5 MB
   （W63A：6,515,265 B；本趟：6,481,832／6,589,464 B）。
3. **崩不崩跟着"WM 在不在"走**：同一棵树、同一套点击、同一 `TO=60`，只把无 WM 的 `:38` 换成有 WM 的 `:37`
   ⇒ 从 **2/2 崩** 变成 **0/2 活**。**而"活"不是因为环被关掉，是因为点击根本没落地**：
   `PC-C/PC-D` 的第 1 击之后 `AE=0`（`PC-C` 只有 1 击 `AE>1000`）。
   这正是 **W77A 修前臂的同一形状**（§3.3 F2），也就是它"两臂签名逐字段相同"的真因。
   ⚠️ 机制方向（已登记 `D-G64`"有 WM 时点击被吞"）本趟**只做定性**：本趟的读数是"**有 WM ⇒ 修前件第 2 击起 `AE=0`**"，
   **没有**去定位"是窗口被 WM 移动、还是输入被吞"（本趟没跑 `CAL` 腿）⇒ 这一点如实记为 `NOINFO`。

---

---

## 5 臂 2：**无 WM** 两臂（本趟的主读数；`nogdb`＋`click`＋`TO=60`，两臂**交错**取值，各 15 趟）

**为什么先跑这条腿**：§4 的 2×2 说明"崩"只出现在**无 WM**（点击能落地）这一格，
而任务书指定的配方（有 WM＋gdb＋90 s）正好是"点击被吞"的那一格。
两臂唯一变量仍是 `libwpfwin32.so`；每趟的 `SHIM` 字段现场算（见下表的 `shim` 列，全部 `sha256sum` 现读）。

| tag | batch | shim | rc | 日志字节 | stackovf | UNH | app_died | fatal | verdict | oom | device | 命中139 | 命中134 | 窗口 | 点/落 | 落地末击 | 崩于 | 死时s |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `A2post01` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post02` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post03` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 7/9 | nav3 | - | 60 |
| `A2post04` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post05` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post06` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post07` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post08` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post09` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 61 |
| `A2post10` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post11` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post12` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 61 |
| `A2post13` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post14` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2post15` | A2 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 60 |
| `A2pre01` | A2 | `abf6879c027c5e73` | **134** | 6449034 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 32 |
| `A2pre02` | A2 | `abf6879c027c5e73` | **134** | 6517465 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 32 |
| `A2pre03` | A2 | `abf6879c027c5e73` | **134** | 6516252 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 31 |
| `A2pre04` | A2 | `abf6879c027c5e73` | **134** | 6520250 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 32 |
| `A2pre05` | A2 | `abf6879c027c5e73` | **134** | 6487935 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 32 |
| `A2pre06` | A2 | `abf6879c027c5e73` | **134** | 6415617 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 31 |
| `A2pre07` | A2 | `abf6879c027c5e73` | **134** | 6518024 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 31 |
| `A2pre08` | A2 | `abf6879c027c5e73` | **134** | 19332 | 1 | 0 | no | na | crash-abort | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav2 | tab3 | 31 |
| `A2pre09` | A2 | `abf6879c027c5e73` | **134** | 6479549 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 31 |
| `A2pre10` | A2 | `abf6879c027c5e73` | **134** | 19097 | 1 | 0 | no | na | crash-abort | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav2 | tab3 | 33 |
| `A2pre11` | A2 | `abf6879c027c5e73` | **134** | 6416369 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 31 |
| `A2pre12` | A2 | `abf6879c027c5e73` | **134** | 6516563 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 30 |
| `A2pre13` | A2 | `abf6879c027c5e73` | **134** | 6514434 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 31 |
| `A2pre14` | A2 | `abf6879c027c5e73` | **134** | 6447204 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 31 |
| `A2pre15` | A2 | `abf6879c027c5e73` | **134** | 6481575 | 1 | 0 | no | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 8/9 | nav2 | tab3 | 31 |

**读数与判读**

| 臂 | 有效 N | `rc=124`（活满 60 s） | `rc=134`（响亮托管爆栈） | 命中"静默 `139`＋0 字节" | 点击落地 | 末击 |
|---|---|---|---|---|---|---|
| `T-post`（`3e4390c9ec07f621`） | **15** | 15 | 0 | **0** | 9/9~10/10（每击 `AE` 大） | `nav3` |
| `T-pre`（`abf6879c027c5e73`） | **15** | 0 | 15 | **0** | 8 击后进程已死（`tab3` 那击 `runner_alive=no`） | `tab3` |

- **两极化成立（`134` 族）**：修前 **13/15** 趟在**"点页签"那一击**整进程死，
  签名逐字段一致（`rc=134`／`Stack overflow.`×1／日志 6.4–6.6 MB／`SetFocus` 行数 **14,671–14,755**）；
  修后 **0/15** 趟**同一条点击腿**走完并**活满窗口**，而且 `tab3` 真的换了页
  （`A2post01 tab3 AE=182269`，与修前件"死在那一击"对照）。
- **修后臂的日志不是 0 字节，是 242 B**，内容是**已处理的**非致命异常
  `[HC-UNHANDLED] #1 EntryPointNotFoundException: … 'SHAppBarMessage' in shared library 'shell32.dll'`（首帧路径）
  ⇒ 它**不满足**用户签名的第 ② 条（日志字节 = 0），**不许**当成"静默 `139`"（这正是判据里第 ② 条存在的意义）。
- **崩的那一击逐趟都是同一个**：修前臂 `tab3`×15 全部死在**点页签**（`210,106`）那一击
  （机器口径：`collect.tsv` 的 `killed_at` 列 = 该趟第一条 `runner_alive=no` 的 `CLICK` 行；修后臂这一列**全为空**）。
- 无 `oom=1`、无 `MAXHOLD_KILL`、无 `NOINFO low-memory`、无装置无效趟（`collect.tsv` 的 `oom`/`device` 两列全 `0`/`ok`）。

---

## 6 臂 3：**任务书配方**（有 WM `:37`＋`gdb` 故障循环＋`click`＋`TO=90`，两臂交错，各 15 趟）

这是任务书 §"装置与判据"指定的配方，也是**唯一接近用户现场（`:10` xrdp＋xfwm4，有 WM 的会话）**的腿。
`gdb` 故障循环按 W63A §1.5 口径：`SIGSEGV` 停下即打 `si_signo`／寄存器／`x/12i $pc-32`／`bt 100`／映射，然后 `continue`（最多 6 次）；
`SIG33..SIG40`／`SIGUSR1/2`／`SIGPIPE` 一律 `nostop noprint pass`。**"抓到的第一个 SIGSEGV"不算崩溃**。

| tag | batch | shim | rc | 日志字节 | stackovf | UNH | app_died | fatal | verdict | oom | device | 命中139 | 命中134 | 窗口 | 点/落 | 落地末击 | 崩于 | 死时s |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `A3post01` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 91 |
| `A3post02` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post03` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post04` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post05` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post06` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post07` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post08` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post09` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post10` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post11` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post12` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post13` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 0,0 800x600 | 3/8 | nav3 | - | 90 |
| `A3post14` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3post15` | A3 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 112,84 800x600 | 8/9 | nav3 | - | 90 |
| `A3pre01` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre02` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 91 |
| `A3pre03` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre04` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre05` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre06` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre07` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre08` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre09` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 91 |
| `A3pre10` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre11` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 91 |
| `A3pre12` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre13` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 91 |
| `A3pre14` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |
| `A3pre15` | A3 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | no | no(handled->alive) | alive-window-after-1-handled-fault | 0 | ok | no | no | 122,142 800x600 | 1/8 | nav3 | - | 90 |

| 臂 | 有效 N | `rc=124` | `rc=134` | `rc=139` | 命中"静默 `139`＋0 字节" | 启动期被处理的 SIGSEGV | 点击落地（`AE>1000`） |
|---|---|---|---|---|---|---|---|
| `T-post` | **15** | 15 | 0 | 0 | **0** | 15/15 趟有故障、其中致命 0 | 115/134 |
| `T-pre` | **15** | 15 | 0 | 0 | **0** | 15/15 趟有故障、其中致命 0 | 15/120 |

**两条必须写在前面的边界**：

1. **这一格对"回声环族"没有检测力**（这是 §10.2 那个仪器缺陷的重演，本趟**自己的读数**）：
   有 WM 时修前件的点击**从第 2 击起 `AE=0`**（`PC-C`/`PC-D` 与本腿的 `T-pre` 逐趟一致），
   ⇒ `SetFocus` 回声环**不会被走到** ⇒ 这一格 0 崩**不代表**"修前件不崩"。
2. 因此本腿对**用户签名（静默 `139`）**的意义是"**在用户那种有 WM 的会话下、按配方点的这一组动作，没复现**"，
   而上界就是 §8 里那一行（`15`/`15` 趟）。

---

## 7 定向腿：**冲用户那个"静默 core dump"签名**的三条附加腿

### 7.1 `ST` 快速连点腿（无 WM；目标 = 用户签名；本趟唯一"按预登记的后续线索"设计的腿）

**为什么要这条腿**：本项目自己留下的线索写得很具体 —— `docs/WAVE49-PREREGISTRATION.md` §11.1：
`D-G66` "两种签名：托管 `Stack overflow.`（…**点页签后**）与**静默 core dump**（`preMouseDown=152` 后）"；
§11.2 又说这条"也解释了 W53A 早先那次 **1/3 概率的静默 SIGSEGV**"。
⇒ 既然"静默"那一支与**同一条点击路径**有关、而线索里的计数是 **152 次按下**，
本趟就把点击密度提上去：同一批坐标上**快速连点（间隔 0.25 s，上限 150 击）**，`TO=45`，无 WM，两臂交错。

| tag | batch | shim | rc | 日志字节 | stackovf | UNH | app_died | fatal | verdict | oom | device | 命中139 | 命中134 | 窗口 | 点/落 | 落地末击 | 崩于 | 死时s |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `STpost01` | ST | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | na | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 0/0 | - | - | 45 |
| `STpost02` | ST | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | na | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 0/0 | - | - | 46 |
| `STpost03` | ST | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | na | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 0/0 | - | - | 45 |
| `STpost04` | ST | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | na | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 0/0 | - | - | 45 |
| `STpre01` | ST | `abf6879c027c5e73` | **134** | 5675537 | 1 | 0 | na | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 0/0 | - | - | 26 |
| `STpre02` | ST | `abf6879c027c5e73` | **134** | 5667910 | 1 | 0 | na | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 0/0 | - | - | 7 |
| `STpre03` | ST | `abf6879c027c5e73` | **134** | 5665194 | 1 | 0 | na | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 0/0 | - | - | 8 |
| `STpre04` | ST | `abf6879c027c5e73` | **134** | 5665349 | 1 | 0 | na | na | crash-abort | 0 | ok | no | yes | 112,84 800x600 | 0/0 | - | - | 7 |

| 臂 | 有效 N | `rc=124` | `rc=134` | **`rc=139`** | 命中"静默 `139`＋0 字节" | 日志字节（各趟） |
|---|---|---|---|---|---|---|
| `T-post` | **4** | 4 | 0 | 0 | **0** | 见 `collect.tsv` |
| `T-pre` | **4** | 0 | 4 | 0 | **0** | 见 `collect.tsv` |

**读数与判读**

- **修后件：4/4 活满窗口**，每趟都吃下了 **147、147、148、148 击**（间隔 0.25 s）⇒ 点击密度提到 16 倍也不崩。
- **修前件：4/4 崩**，`rc=134`＋`Stack overflow.`＋5.67 MB，死在 **第 76 击（`nav10`）、第 5 击（`nav9`）、第 6 击（`tab3`）、第 5 击（`nav9`）**。
  ⚠️ 注意：**它不在同一个控件上死**（慢速 9 击腿 15/15 都死在 `tab3`；快速连点腿第 5/6 击就死了，落点是 `nav9`/`tab3`/`nav10`）
  ⇒ **触发条件不是某个控件，而是"点击持续进得来"这件事本身**：环一旦被打破，就该由上游那条
  "已拥有焦点的 HWND 不会再收到 `WM_SETFOCUS`"的不变式兜住 —— 修前件没有兜（`D-G66`），修后件有。
- 本腿**没有**拿到用户那个"静默 `139`＋0 字节"（4/4 崩的都是**响亮**的 `134`）；如实记 `NOINFO`。

### 7.2 `S0` 零点击反极性腿（无 WM，`mode=start`，`TO=45`）

**用途**：把"崩跟着**点击**走"这条**反极性**做实 —— 同条件同件，只是**一次都不点**。

| tag | batch | shim | rc | 日志字节 | stackovf | UNH | app_died | fatal | verdict | oom | device | 命中139 | 命中134 | 窗口 | 点/落 | 落地末击 | 崩于 | 死时s |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `S0post1` | S0 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | na | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 0/0 | - | - | 45 |
| `S0post2` | S0 | `3e4390c9ec07f621` | **124** | 242 | 0 | 0 | na | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 0/0 | - | - | 45 |
| `S0pre1` | S0 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | na | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 0/0 | - | - | 45 |
| `S0pre2` | S0 | `abf6879c027c5e73` | **124** | 0 | 0 | 0 | na | na | alive-window | 0 | ok | no | no | 112,84 800x600 | 0/0 | - | - | 45 |

### 7.3 `CAL` 标定腿（**非样本**；有 WM，逐击回读几何）

**用途**：把 §10.2 的"有 WM 时修前件第 2 击起 `AE=0`"从"结论"降级成"带机制的读数" ——
逐击记录"点之前/点之后的窗口几何"，看是**窗口被 WM 挪走**（坐标失效）还是**输入被吞**。
**本腿不进任何统计**（它的 tag 前缀是 `CAL`，`summary.py` 里单独成组）。

| 腿 | shim | 窗口几何（第 1 击前 → 第 1 击后 → 末击后） | 逐击 `AE` |
|---|---|---|---|
| `CALpost` | `3e4390c9ec07f621` | `112,84 800x600` → **不变** → **不变** | `341659 / 209559 / 75027 / 182269`（4/4 全落地） |
| `CALpre` | `abf6879c027c5e73` | `117,113 800x600` → **不变** → **不变** | `347304 / 0 / 0 / 0`（第 1 击之后**全被吞**） |

⇒ **机制收窄（本趟的读数，直接把这格从"结论"变成"带机制的读数"）**：

- **不是坐标失效**：修前件的窗口在 WM 下**逐击几何完全不动**（`117,113 800x600` 常量）⇒ W77A 那种"点了但窗口挪了"的解释**不成立**；
- **是"点击不再落地"，而且跟着 `shim` 走**：同一个 WM、同一套坐标、同一次会话，修后件 **4/4** 落地、修前件**第 1 击之后 0/3** 落地。
  ⇒ 这是**产品侧差异**（修前件缺的那 14 个导出里就有 `wpf_x11_pointer_grab`／`wpf_x11_client_size_limit`／`wpf_x11_set_decorations` 这一族），
  **不是**单纯"WM 都会吞点击"（本项目 `D-G64` 的原有说法）——**同一台 WM 上修后件不吞**。
- ⚠️ **机制只到这一步**：本趟**没有**继续定位"是残留的 X 指针抓取、还是输入被丢"（没抓 `xev`／没查 grab 状态）⇒ 这一层如实记 `NOINFO`，
  建议另立一条登记（本报告只给读数与建议，**不写仓内登记表**）。

---

## 8 统计与 95% 上界（**判据口径**：`oom=1`／`MAXHOLD_KILL`／`NOINFO low-memory`／`rc=127`／45 s 无窗口 一律不进分母）

### 8.1 用户签名（静默 `rc=139`＋0 字节，四条件取合取）

| 条件 | 有效 N | **命中** | 95% 上界（0 命中 ⇒ 规则 of three） |
|---|---|---|---|
| 无 WM＋`nogdb`＋点击＋60 s（臂 2） | `15`＋`15` | **0+0 = 0** | post `18.1%`／pre `18.1%` |
| 有 WM＋`gdb`＋点击＋90 s（臂 3，任务书配方） | `15`＋`15` | **0** | post `18.1%`／pre `18.1%` |
| 无 WM＋快速连点 150 击（定向腿） | `4`＋`4` | **0** | post `52.7%`／pre `52.7%` |
| 无 WM＋零点击（反极性） | `2`＋`2` | **0** | —— |
| 阳性对照 2×2（起对照作用） | `8` | 0（但 4 趟是 `134`＋6.5 MB） | —— |
| **合计（全库，全部腿）** | **`80`** | **0** | **`3.7%`** |

⇒ **用户那个签名本趟整体 0 命中**，全库上界 **`3.7%`**（`N=80`；口径 `1-0.05^(1/N)`，与"规则 of three ≈ 3/N"同量级）。
**这不是"已排除"**：`rc=124` 只说"窗口内没死"（W63A §1.2），0 命中只给上界。

### 8.2 响亮 `134` 族（**本趟真正的两极化**）

| 条件 | 修后件 `3e4390c9ec07f621` | 修前件 `abf6879c027c5e73` |
|---|---|---|
| **无 WM**（点击落地） | **0/15** | **15/15** 崩（其中 13/15 满足预登记的"≥1 MB"判据、2 趟是 19 KB 折叠形，见 §5.1）；+ 阳性对照 2×2 的 4/4 |
| **有 WM**（点击被吞） | 0/15 | 0/15（+ `PC-C/PC-D` 的 0/4） |

### 8.3 到 `≤5%` 还需要多少（**用本趟实测速率算，不算感觉**）

- 本趟每趟样本的取数速率：臂 2（60 s 窗）**≈ 0.67 趟/分钟**（实测 45 分钟走完 15×2 趟），
  臂 3（90 s 窗＋gdb）**≈ 0.43 趟/分钟**（实测 70 分钟走完 15×2 趟）。
- 规则 of three：`≤20% ⇒ N ≥ 15/臂`（本趟已达）；`≤5% ⇒ N ≥ 60/臂`。
  ⇒ 按上列速率，再补到 **60/臂** 需要 **≈ 3.0 小时槽时间**（不含被别的车道排队的时间；本趟实测排队占比见 §12）。

---

## 9 判决点 / `NOINFO` / 代价

### 9.1 判决点（**拿到了**，但对的是 `134` 族）

**修前 `abf6879c027c5e73` ⇒ 修后 `3e4390c9ec07f621` 之间那一组改动，把"点页签"触发的 `SetFocus` 回声环关掉了。**
证据三件（缺一不可）：
1. **条件可复现**：无 WM＋9 击，修前件 **15/15 崩**（其中 13 趟满足预登记的"≥1 MB"判据、2 趟是 19 KB 折叠形）、
   阳性对照 2×2 里 4/4 崩（**两种树都崩** ⇒ **不是托管件/桥**）；
2. **反极性**：修后件同条件 0/15 **不崩且页签真的换页**；有 WM 时两臂都不崩（因为点击没落地）；
3. **机制**：崩的那一趟日志顶层 12 帧是同一个环，环上唯一原生边是我们的 `SetFocus`／`WM_SETFOCUS` 派发
   （`HwndKeyboardInputProvider.FilterMessage ← OnSetFocus ← ReportInput ← … ← NativeMethodsSetLastError.SetFocus`），
   `SetFocus` 行数 **14,671–14,755**（与 W63A `C101` 的 14,755、本趟 `PCA1` 的 14,676 相差 ≤0.6% ⇒ 同一个环、同一套帧成本）。
   ⇒ 与已登记 `D-G66`（`win32_core.c` 的 `WM_SETFOCUS` 缺 `old != hwnd` 守卫）**同一根因**，本趟是它的**独立复现**。
4. **判决力上限（先声明）**：两 `.so` 差 **14 个导出**（§1）⇒ 只许说"**这组改动**关掉了环"，**不许**再往下点单一函数。

### 9.2 `NOINFO`（用户签名那一半，如实记）

- **`NOINFO(TASK-0203 的静默 rc=139＋0 字节)`**：全库 **80** 趟有效样本、**0 命中**，
  上界 **`3.7%`**；其中"有 WM（≈用户会话）＋点击＋90 s"这一格 `15`/`15` 趟也 0 命中。
- 本趟**没有**、也**不能**说"静默 `139` 不存在/已修"。能说的只有两条：
  ① 在**本装置、本条件**下它的频率上界是 `3.7%`；
  ② 本趟**证明了这个签名的近邻族（`134` 托管爆栈）确实跟着 shim 走**，而"静默"那一支（WAVE49 §11.1 记的第二签名）
     本趟**一次都没抓到** —— 它需要的条件本趟**没找到**（`NOINFO`）。

### 9.3 三条边界（不许读宽）

1. 两臂树是 hc app-local（相对 #49/#50 权威件**已陈旧**，§1）⇒ 结论对"这套树＋这两个 `.so`"成立。
2. `:37/:38`（Xvfb 1024×768＋xfwm4）与用户现场（`:10` xrdp＋xfwm4）**不同构**。
3. `139` 那一族本趟 0 命中，**只给上界**。

---

## 10 我推翻 / 更正了什么（含推翻前序车道的结论）

### 10.1 推翻 W77A「这套装置不能归因」的结论 —— **它的阳性对照条件被贴错了标签**

W77A `W77A-report.md` §5.1 写：*"W63A `C101`：修前 shim `abf6879c027c5e73` ＋ 8 击 ⇒ `rc=134`＋`Stack overflow.`＋6,515,265 B（响亮）……
⇒ 修前件在**有 WM 且有点击**时是'响亮的 134'"*。**这句里的"有 WM"是错的**，三条独立证据：

1. W63A 自己 `run/C101/meta.txt` 第 1 行：`TAG=C101 ARM=nogdb MODE=click TO=60 **DISP=:196**`；
2. W63A `REPORT.md` §2.4 装置清单：`私有显示 Xvfb :196`，而 **WM 腿是 `:198`**（§3.4 明写"`:198` = Xvfb 1024×768 ＋ xfwm4"）⇒ **`:196` 无 WM**；
3. 本趟 `PC-A`（旧树、无 WM）与 `C101` **逐字段复现**（几何 `112,84 800x600`、8 击、末击 `tab3`、`rc=134`、6.48/6.59 MB），
   而同条件的 **有 WM 两格 0/2 全活**。

⇒ W77A 拿"有 WM"的条件去复刻一个"无 WM"的阳性对照，当然 0/2（它 §5.4），于是把结论写成"操纵没起作用 ⇒ 装置不能归因"。
**更正**：**装置能归因**，前提是条件选对（无 WM）。本趟 §4 的 2×2 就是这条更正本身的读数。

### 10.2 更正 W77A「两臂签名逐字段相同，只差 `ENTRY_N` 8 vs 9」—— 那一格是**死仪器**

`ENTRY_N` 数的是**脚本走了几步**，不是**点击落了几次**。W77A 自己留下的 `clicks.txt` 里，
修前臂（`Dpre01`、`Ngpre1`）从第 2 击起 **`AE=0`（全 0）**，而修后臂（`Dpost01`、`Ngpost1`）每击 `AE` 都很大、弹窗也开了。
⇒ 它修前臂的 6 趟**几乎没点进去**。**更正**：两臂不是"同签名"，而是**修前臂的仪器坏了**（§3.3 F2）。

### 10.3 顺带更正本项目"有 WM 时才像用户现场"的默认倾向

本工程有硬教训 `D-G64`（有 WM 时点击被吞）⇒ 车道们倾向"验收必须有 WM"。
本趟的读数是**反过来的一半**：**有 WM 时，`SetFocus` 回声环根本不会被走到**（因为点击没落地），
所以"**必须有 WM**"的验收装置**永远测不到 `D-G66` 这一族**；而 `D-G66` 是**已登记、已修、已两极化**的真产品缺陷。
⇒ 两条腿（有 WM／无 WM）**都要**，缺一条就会把"环没被触发"读成"缺陷不存在"。

### 10.4 本趟**没有**推翻的、如实保留的两条边界

1. **`139`＋0 字节 ≠ `134`＋6.5 MB**：本趟两极化的是后者。前者的判决仍只到 `NOINFO`（§9）。
2. 两 `.so` 之间**不止一处**改动（14 个导出差）⇒ 即使将来 `139` 两极化成立，也**不许**归因单一函数。

---

## 11 本批动了哪些件（**应为 0**）

**本车道仓内只写入本报告一个文件**（`$R/build/MilBridge/W85A-report.md`）。
（⚠️ 现场核过：同一时段仓内还有**别的车道**的写入 —— `W84A/W86A/W87A/W88A-report.md`、`tools/r-gate-step.sh`、
`tools/defect-registry-declared.tsv`、若干 `tests/**/obj` 生成物 —— 那些**不是本车道写的**，本车道一行都没碰。）
未改任何产品件／路由件／`defect-registry-declared.tsv`／世代位；**未构建**（没有 `dotnet build`、没有 `build-shim.sh`）；
未 `pkill -f`（一律数字 PID）。全部私有工件在 `$HOME/w85a/**` 与三份 `$HOME/w85a/app*` 副本里。

**仪器（私有只读复用副本，逐件现场算）**

| 件 | 来源 | 原件 sha16 | 本车道副本 sha16 | 我改了什么 |
|---|---|---|---|---|
| `one.sh` | W77A（v3 仪器） | `4938db46e2279b53`（W63A 原版 `9b1f2dc49cb7f744`） | `96d4a52b06b37ecb` | ① `$HOME/w77a`→`$HOME/w85a`；② `W63A_APP`→`W85A_APP`；③ **`grep 'W63A-TERMINATED'`→`'W85A-TERMINATED'`（修 §3.2 的 F1）** |
| `gdb.cmds.tmpl` | W77A | `669a8a372ef55c2d`（W63A 原版 `16e655317dd0dde1`） | `f5215b415891dad1` | 标记统一 `W77A-*`→`W85A-*`（**与上面那条配对**，F1 就是它们没配对造成的） |
| `classify.py` | W63A | `347e05893a2b6a43` | `347e05893a2b6a43`（**未改**） | —— |
| `gate.sh` | W77A 修正版 | —— | —— | 只把 `--max-hold` 150→**260**（任务书要求） |
| `stress.sh`／`stressbatch.sh`／`s0batch.sh`／`arm2.sh`／`arm3.sh`／`collect.sh`／`table.sh`／`cal.sh` | **本趟新写** | —— | —— | 见 §7／§14；`collect.sh` 是"从 `result.env` 现算"的汇总器（**杜绝手抄**） |

---

## 12 内存三值与收尾现场（纪律要求）

| 项 | 读数 |
|---|---|
| 进槽前的 `MemAvailable`（全库 80 趟，取 `MEMAVAIL_BEFORE`） | 最小 **1658 MB**／中位 **2464 MB**／最大 **2762 MB** |
| 每趟跑后（`MEMAVAIL_AFTER`） | 见 `collect.tsv` 末两列（逐趟现算） |
| 收工时 | `MemTotal 7923 MB / MemAvailable 2652 MB (used ~5271 MB)` |
| `oom_kill` 增量 / `oom=1` 剔除 | **0 / 0**（`/proc/vmstat` 每趟跑前跑后各读一次，逐趟记在 `result.env`） |
| `MAXHOLD_KILL` / `NOINFO low-memory` / `rc=127` / 无窗口 | **0 / 0 / 0 / 0** |
| 被别的车道排队 | 本批共等 **4048 s**（`GATE=wait`／`HEAVYSLOT=ACQUIRED waited=` 两类现场记录相加；别的车道含 W84A 的 R-GATE 腿与一次 `dotnet build PresentationFramework`） |
| 收工残留 | `Xvfb :37`／`xfwm4`／`Xvfb :38` 按 PID 收 ⇒ 残留 **0** |
| 全程 `pkill -f` | **0 次**（一律数字 PID） |

---

## 13 给用户看的大白话小结（≤6 行）

1. 你报的那个"**一声不响就死（`139`、日志 0 字节）**"，这一趟跑了 **80 次**样本，**一次都没再出现** —— 这只是"上界压到 `3.7%`"，**不等于它不存在**。
2. 但它有个"响亮的近亲"被我们**稳稳地**抓住了：**点页签那一击**会让进程带着 `Stack overflow.` 死（`134`，15/15 趟；日志大部分 6.5 MB、有 2 趟只有 19 KB —— 同一个崩溃的两种打印形状）。**这跟"点不点得进去"走，跟"有没有窗口管理器"走**：没有 WM 时点击能落地 ⇒ 必死；有 WM 时点击从第 2 击起就被吞 ⇒ 反而活着。
3. **这就是前一条车道读错的根子**：它拿"有 WM"的条件去复刻一个**本来就是无 WM** 的阳性对照，还把它那条"修前臂"读到"点击全没落地"的坏数据当成了"两臂一模一样"。
4. **好消息**：现行件（`3e4390c9ec07f621`）在"能点进去"的条件下**同一条点击腿走完还换了页、活满窗口**，而修前件（`abf6879c027c5e73`）15/15 趟全在那一击死掉 ⇒ **这个环已经被我们的改动关掉了**（登记 `D-G66`，本趟是独立复现）。
5. **要记住的一条验收教训**：本项目一直觉得"验收必须带窗口管理器"（因为有"有 WM 时点击被吞"的教训）—— 但**有 WM 时这个环根本不会被走到**，光靠它验收**永远测不到这一类**。两条腿都要。
6. **我没做到的**：`139` 那一支今天一次也没抓到（快连点 150 击、零点击反极性、90 s 长窗、gdb 故障循环都试了）；也**没能**在"有 WM"那一格让点击真正落地（所以那一格的 0 崩不算数）；两臂之间差 14 个导出，**判不到具体是哪一处改动**。

### 5.1 ⚠️ **同一个崩溃有两种输出形状** —— 这是本趟对"判据本身"的一处发现（先把判据的洞登记，再给读数）

本趟预登记的 `134` 判据是"`rc=134` ∧ `STACKOVF≥1` ∧ 日志 ≥1 MB"（照抄 W63A `C101` 的签名）。
**真读数里，修前臂的崩趟有 2/15 趟只写了 ~19 KB**（不是 6.5 MB），
而**这一族的崩趟其实是 15/15** ⇒ 这条判据会把那 2 趟判成"不是同一签名"。
把它们打开看，**它们是同一个环**，只是 coreclr 换了**输出形状**：
**折叠形**（`Stack overflow.` ＋ `Repeated 2949 times:` ＋ 168 行）vs **全量形**（6.4–6.5 MB、61,417–62,797 行）。

| tag | shim | rc | 日志字节 | 输出形状 | `Repeated N times` | 总行数 | `SetFocus` 行数 | 末击 |
|---|---|---|---|---|---|---|---|---|
| `A2pre01` | `abf6879c027c5e73` | 134 | 6449034 | 全量展开 | （无：全量展开） | 61738 | 14671 | nav3 |
| `A2pre02` | `abf6879c027c5e73` | 134 | 6517465 | 全量展开 | （无：全量展开） | 62111 | 14760 | nav3 |
| `A2pre03` | `abf6879c027c5e73` | 134 | 6516252 | 全量展开 | （无：全量展开） | 62100 | 14756 | nav3 |
| `A2pre04` | `abf6879c027c5e73` | 134 | 6520250 | 全量展开 | （无：全量展开） | 62137 | 14766 | nav3 |
| `A2pre05` | `abf6879c027c5e73` | 134 | 6487935 | 全量展开 | （无：全量展开） | 62111 | 14760 | nav3 |
| `A2pre06` | `abf6879c027c5e73` | 134 | 6415617 | 全量展开 | （无：全量展开） | 61417 | 14595 | nav3 |
| `A2pre07` | `abf6879c027c5e73` | 134 | 6518024 | 全量展开 | （无：全量展开） | 62112 | 14760 | nav3 |
| `A2pre08` | `abf6879c027c5e73` | 134 | 19332 | **折叠** | Repeated 2949 times | 168 | 11 | nav3 |
| `A2pre09` | `abf6879c027c5e73` | 134 | 6479549 | 全量展开 | （无：全量展开） | 61748 | 14671 | nav3 |
| `A2pre10` | `abf6879c027c5e73` | 134 | 19097 | **折叠** | Repeated 2951 times | 167 | 11 | nav3 |
| `A2pre11` | `abf6879c027c5e73` | 134 | 6416369 | 全量展开 | （无：全量展开） | 61424 | 14596 | nav3 |
| `A2pre12` | `abf6879c027c5e73` | 134 | 6516563 | 全量展开 | （无：全量展开） | 62101 | 14756 | nav3 |
| `A2pre13` | `abf6879c027c5e73` | 134 | 6514434 | 全量展开 | （无：全量展开） | 62081 | 14751 | nav3 |
| `A2pre14` | `abf6879c027c5e73` | 134 | 6447204 | 全量展开 | （无：全量展开） | 61440 | 14600 | nav3 |
| `A2pre15` | `abf6879c027c5e73` | 134 | 6481575 | 全量展开 | （无：全量展开） | 61768 | 14676 | nav3 |
| `PCA1` | `abf6879c027c5e73` | 134 | 6481832 | 全量展开 | （无：全量展开） | 61771 | 14676 | nav3 |
| `PCA2` | `abf6879c027c5e73` | 134 | 6589464 | 全量展开 | （无：全量展开） | 62797 | 14921 | nav3 |
| `PCB1` | `abf6879c027c5e73` | 134 | 6489014 | 全量展开 | （无：全量展开） | 62121 | 14761 | nav3 |
| `PCB2` | `abf6879c027c5e73` | 134 | 6482785 | 全量展开 | （无：全量展开） | 61780 | 14681 | nav3 |
| `STpre01` | `abf6879c027c5e73` | 134 | 5675537 | 全量展开 | （无：全量展开） | 55413 | 15366 | - |
| `STpre02` | `abf6879c027c5e73` | 134 | 5667910 | 全量展开 | （无：全量展开） | 53008 | 10566 | - |
| `STpre03` | `abf6879c027c5e73` | 134 | 5665194 | 全量展开 | （无：全量展开） | 52983 | 10561 | - |
| `STpre04` | `abf6879c027c5e73` | 134 | 5665349 | 全量展开 | （无：全量展开） | 52984 | 10561 | - |

**两条推论（都可复算，见 §14）**

1. **环的迭代次数是确定的**：折叠形直接打出 `Repeated 2949/2951 times`；
   全量形的 `SetFocus` 行数 **14,595–14,921** ÷ 每轮 5 帧 ≈ **2,919–2,984 次** —— 两种形状互相印证，
   而且与 W63A `C101`（14,755）同一量级。⇒ **是同一个环，不是两种缺陷。**
2. **"日志体积"不是可靠的签名判别量**（登记为**判据缺陷 W85A-F3**，与 W77A 的 `>800 色` 阈值同类）：
   同一个托管爆栈，coreclr 可以写 6.5 MB，也可以只写 19 KB。
   ⇒ W63A §2.1 用"`139`＋**0 字节** = 原生层故障"这条**成对标定**在本趟看来**前半段仍成立、后半段不严密**：
   "托管一定有大日志"是**不成立**的（本趟 2/15 趟只有 19 KB），
   所以**不能**反过来用"日志 0 字节"单独判定"故障在原生层"。
   本批里"日志 **0 字节**"一共出现 **21 趟**（占 80 趟），而且**全部是活着的趟**（`rc=124`）
   ⇒ 单看"日志是不是 0 字节"，本批**完全没有判别力**（它连"崩没崩"都分不出来）。
   ⚠️ 这**不改变** W63A 的结论（它那 7 种合成故障形状的成对读数是实测的），只是把这条判据的**射程**收窄：
   它证明的是"原生故障**不会**留日志"，**不是**"没留日志**必然**是原生故障"。
   本趟**没有**抓到 `139`＋0 字节（§8），所以这条只是**判据层面的更正**，不是对用户那次事件的重新归因。

## 14 复算命令（照抄即可复现，全部现算）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"

# 0) 判据与世代位
sha256sum $HOME/w85a/criteria.md | cut -c1-16                    # 95d23c292007a5e9
sha256sum $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16   # 3e4390c9ec07f621（修后）
sha256sum $HOME/w85a/app-pre/libwpfwin32.so | cut -c1-16               # abf6879c027c5e73（修前）
nm -D --defined-only $HOME/w85a/app/libwpfwin32.so | awk '$2=="T"{print $3}' | sort -u > /tmp/post.exp
nm -D --defined-only $HOME/w85a/app-pre/libwpfwin32.so | awk '$2=="T"{print $3}' | sort -u > /tmp/pre.exp
comm -13 /tmp/pre.exp /tmp/post.exp        # 修前缺的 14 个导出

# 1) 仪器自检（合成件 recur/wild）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 120 -- timeout 110 bash ~/w85a/bin/selftest-gdb.sh

# 2) 两条腿的显示（私有；收工按 PID 收）
Xvfb :37 -screen 0 1024x768x24 -nolisten tcp &        # 有 WM
DISPLAY=:37 xfwm4 --display=:37 --compositor=off &    # 现场核：xprop -root _NET_SUPPORTING_WM_CHECK
Xvfb :38 -screen 0 1024x768x24 -nolisten tcp &        # 无 WM（同一探针必须报 no such atom）

# 3) 一趟样本（槽 + 波链闸门），例：修前件 + 无 WM + nogdb + click + 60 s
BATCH_ID=A2 bash ~/w85a/bin/gate.sh 130 ~/w85a/bin/inner.sh A2pre01 $HOME/w85a/app-pre nogdb click 60 :38

# 4) 汇总（不手抄；直接从每趟 result.env+clicks.txt 现算）
bash ~/w85a/bin/collect.sh          # → $HOME/w85a/collect.tsv（29 列，含 hit139/hit134 两列）
bash ~/w85a/bin/table.sh A2         # → markdown 表（batch 过滤）

# 5) 单趟判读
cat $HOME/w85a/run/A2pre01/result.env      # RC/LOGBYTES/STACKOVF/VERDICT/OOM/SHIM…
grep -a 'CLICK' $HOME/w85a/run/A2pre01/clicks.txt   # 逐击 AE（判"点击到底落没落地"）
grep -a -m1 -A24 'Stack overflow' $HOME/w85a/run/A2pre01/app.log   # 回声环的闭合栈
```


---

## 15 附：逐趟原始 TSV（29 列；列名见第一行，`$HOME/w85a/collect.tsv` 原样）

```tsv
tag	batch	arm	mode	TO	disp	shim	bridge	rc	lb	unh	stackovf	faults	app_died	died_sig	fatal	verdict	oom	device	entry_n	geo	dead_at_s	clicks_total	clicks_landed	last_click	hit139	hit134	mab	maa	killed_at
A2post01	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	2465	2456	-
A2post02	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	1955	2062	-
A2post03	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	7	nav3	no	no	2153	2254	-
A2post04	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	2318	2373	-
A2post05	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	1782	2589	-
A2post06	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	2664	2620	-
A2post07	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	1658	2509	-
A2post08	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	1686	2121	-
A2post09	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	61	9	8	nav3	no	no	2270	2412	-
A2post10	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	2329	2413	-
A2post11	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	2761	2777	-
A2post12	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	61	9	8	nav3	no	no	2673	2671	-
A2post13	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	2299	2370	-
A2post14	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	2367	2429	-
A2post15	A2	nogdb	click	60	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	60	9	8	nav3	no	no	2367	2414	-
A2pre01	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6449034	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	32	9	8	nav2	no	yes	2449	2399	tab3
A2pre02	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6517465	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	32	9	8	nav2	no	yes	2099	2148	tab3
A2pre03	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6516252	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	yes	2206	2259	tab3
A2pre04	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6520250	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	32	9	8	nav2	no	yes	2541	2571	tab3
A2pre05	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6487935	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	32	9	8	nav2	no	yes	2726	2660	tab3
A2pre06	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6415617	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	yes	2548	2592	tab3
A2pre07	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6518024	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	yes	2556	2526	tab3
A2pre08	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	19332	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	no	2247	2272	tab3
A2pre09	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6479549	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	yes	2408	2473	tab3
A2pre10	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	19097	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	33	9	8	nav2	no	no	2303	1653	tab3
A2pre11	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6416369	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	yes	2762	2726	tab3
A2pre12	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6516563	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	30	9	8	nav2	no	yes	2611	2618	tab3
A2pre13	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6514434	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	yes	2377	2362	tab3
A2pre14	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6447204	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	yes	2559	2482	tab3
A2pre15	A2	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6481575	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	yes	2360	2379	tab3
A3post01	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	91	9	8	nav3	no	no	2390	2416	-
A3post02	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2395	2451	-
A3post03	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2324	2374	-
A3post04	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2696	2643	-
A3post05	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2423	2432	-
A3post06	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2408	2436	-
A3post07	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2480	2494	-
A3post08	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2702	2690	-
A3post09	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2752	2718	-
A3post10	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2682	2704	-
A3post11	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2688	2697	-
A3post12	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2696	2660	-
A3post13	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	0,0 800x600	90	8	3	nav3	no	no	2686	2638	-
A3post14	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2709	2649	-
A3post15	A3	gdb	click	90	:37	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=9_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3,nav3	112,84 800x600	90	9	8	nav3	no	no	2635	2620	-
A3pre01	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2413	2384	-
A3pre02	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	91	8	1	nav3	no	no	1982	2387	-
A3pre03	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2410	2603	-
A3pre04	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2664	2652	-
A3pre05	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2309	2343	-
A3pre06	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2432	2466	-
A3pre07	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2687	2728	-
A3pre08	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2720	2750	-
A3pre09	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	91	8	1	nav3	no	no	2715	2689	-
A3pre10	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2703	2689	-
A3pre11	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	91	8	1	nav3	no	no	2678	2695	-
A3pre12	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2655	2717	-
A3pre13	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	91	8	1	nav3	no	no	2645	2682	-
A3pre14	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2655	2662	-
A3pre15	A3	gdb	click	90	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	1	no	none	no(handled->alive)	alive-window-after-1-handled-fault	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	90	8	1	nav3	no	no	2459	2536	-
PCA1	PC	nogdb	click	60	:38	abf6879c027c5e73	e3ea092010734f44	134	6481832	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	32	9	8	nav2	no	yes	2426	2379	tab3
PCA2	PC	nogdb	click	60	:38	abf6879c027c5e73	e3ea092010734f44	134	6589464	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	32	9	8	nav2	no	yes	2382	2393	tab3
PCB1	PC	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6489014	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	31	9	8	nav2	no	yes	2412	2351	tab3
PCB2	PC	nogdb	click	60	:38	abf6879c027c5e73	79e45aed26487045	134	6482785	0	1	0	no	none	na	crash-abort	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,popitem,nav2,tab3	112,84 800x600	34	9	8	nav2	no	yes	2357	2342	tab3
PCC1	PC	nogdb	click	60	:37	abf6879c027c5e73	e3ea092010734f44	124	0	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	61	8	1	nav3	no	no	2351	2368	-
PCC2	PC	nogdb	click	60	:37	abf6879c027c5e73	e3ea092010734f44	124	0	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	60	8	1	nav3	no	no	2379	2427	-
PCD1	PC	nogdb	click	60	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	60	8	2	nav3	no	no	2433	2349	-
PCD2	PC	nogdb	click	60	:37	abf6879c027c5e73	79e45aed26487045	124	0	0	0	0	no	none	na	alive-window	0	ok	L1_ENTRY_N=8_ENTRY_DETAIL=nav1,nav9,ctrl_tb,type,nav10,ctrl_cb,nav2,tab3,nav3	122,142 800x600	60	8	1	nav3	no	no	2342	2468	-
S0post1	S0	nogdb	start	45	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	NA	na	none	na	alive-window	0	ok	L1_ENTRY_N=0_ENTRY_DETAIL=-	112,84 800x600	45	0	0	-	no	no	2575	2616	-
S0post2	S0	nogdb	start	45	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	NA	na	none	na	alive-window	0	ok	L1_ENTRY_N=0_ENTRY_DETAIL=-	112,84 800x600	45	0	0	-	no	no	2620	2584	-
S0pre1	S0	nogdb	start	45	:38	abf6879c027c5e73	79e45aed26487045	124	0	0	0	NA	na	none	na	alive-window	0	ok	L1_ENTRY_N=0_ENTRY_DETAIL=-	112,84 800x600	45	0	0	-	no	no	2632	2585	-
S0pre2	S0	nogdb	start	45	:38	abf6879c027c5e73	79e45aed26487045	124	0	0	0	NA	na	none	na	alive-window	0	ok	L1_ENTRY_N=0_ENTRY_DETAIL=-	112,84 800x600	45	0	0	-	no	no	2585	2580	-
STpost01	ST	nogdb	stress	45	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	NA	na	none	na	alive-window	0	ok	L1_ENTRY_N=147_ENTRY_DETAIL=nav2	112,84 800x600	45	0	0	-	no	no	2535	2489	-
STpost02	ST	nogdb	stress	45	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	NA	na	none	na	alive-window	0	ok	L1_ENTRY_N=147_ENTRY_DETAIL=nav2	112,84 800x600	46	0	0	-	no	no	2451	2466	-
STpost03	ST	nogdb	stress	45	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	NA	na	none	na	alive-window	0	ok	L1_ENTRY_N=148_ENTRY_DETAIL=nav10	112,84 800x600	45	0	0	-	no	no	2471	2484	-
STpost04	ST	nogdb	stress	45	:38	3e4390c9ec07f621	79e45aed26487045	124	242	0	0	NA	na	none	na	alive-window	0	ok	L1_ENTRY_N=148_ENTRY_DETAIL=nav10	112,84 800x600	45	0	0	-	no	no	2606	2610	-
STpre01	ST	nogdb	stress	45	:38	abf6879c027c5e73	79e45aed26487045	134	5675537	0	1	NA	na	none	na	crash-abort	0	ok	L1_ENTRY_N=76_ENTRY_DETAIL=nav10	112,84 800x600	26	0	0	-	no	yes	2478	2465	-
STpre02	ST	nogdb	stress	45	:38	abf6879c027c5e73	79e45aed26487045	134	5667910	0	1	NA	na	none	na	crash-abort	0	ok	L1_ENTRY_N=5_ENTRY_DETAIL=nav9	112,84 800x600	7	0	0	-	no	yes	2464	2482	-
STpre03	ST	nogdb	stress	45	:38	abf6879c027c5e73	79e45aed26487045	134	5665194	0	1	NA	na	none	na	crash-abort	0	ok	L1_ENTRY_N=6_ENTRY_DETAIL=tab3	112,84 800x600	8	0	0	-	no	yes	2521	2482	-
STpre04	ST	nogdb	stress	45	:38	abf6879c027c5e73	79e45aed26487045	134	5665349	0	1	NA	na	none	na	crash-abort	0	ok	L1_ENTRY_N=5_ENTRY_DETAIL=nav9	112,84 800x600	7	0	0	-	no	yes	2618	2576	-
```

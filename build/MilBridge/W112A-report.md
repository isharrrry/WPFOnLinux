# W112A 报告 —— `TASK-0110`／`D-G98`：**退出最大化后窗态掉了、几何没回来**（间歇残留）的真因取证 ＋ 判据

> lane = **W112A** ｜ 2026-09-22 **21:45 → 22:4x +0800**（中途被运行时挂死一次，**22:06 起按主控指示从断点续跑**，见 §8）｜ kernel `6.8.0-138-generic` ｜ `nproc=3`
> 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**本机 `R` 不是 git 仓库 ⇒ 推送不在本件射程**）｜ 冻结基线 `#51 = 38e67e834430d75c`
> **判据先写**：`~/w112a/criteria.md` = **sha16 `d98380adfb2efce7`**（18,401 B，mtime `2026-09-22 21:52:05 +0800`）⇒ 早于本件**任何**跑动与**任何**件替换；**一个字没改**（判据里的两处错值**故意保留**并登记，见 §8.1）
> 写域 = `~/w112a/**` ＋ 本报告 ｜ **产品件一个字节未动**（九位逐位未动，见 §6.3）
> 前序：`W105A-report.md`（`ae61f7f0dc5f25f5`，口径 `head -n -2`）｜`W89A-report.md`（`675779b2fc2c30ee`）｜`W77A-report.md`（`af9987e29f761e78`）｜`W110A-report.md`（`d0fd37b8f74ac684`）｜ 册内 `D-G98`（**由 W111A 登记**，本件**只读引用**、**不改册**）

---

## §0 一句话判决（**结论在前**）

| 问题 | 判决 | 一句话 |
|---|---|---|
| **真因是否定位** | **是（`D-G98` ③ 类的真因＝"我方 shim 把一次**应当无副作用**的 `SetWindowPos` 落成了一次**真实的几何写**，写的是**窗口表缓存** —— 缓存里那时还是**最大化矩形**）** | 链路有**三条独立证据**：①**符号级 backtrace**（`SetWindowPos → wpf_x11_move_resize → XMoveResizeWindow`，见 §5.4）②**外部事件级观测器**（WM **确实**先收回了几何，**70–80 ms 后**又被设回最大化，见 §5.3）③**判词与"写的内容"的相关**（写＝最大化矩形 ⇒ 红 `1/1`；写＝基准矩形 ⇒ 绿 `0/14`）。 |
| **候选 (c)「WM 自己没收几何」** | **排除**（纯 X 装置：负臂 **0/40**，95% 上界 **7.2%**；正对照 **4/4 必红**） | 裸 `_NET_WM_STATE ADD→REMOVE` 上 `xfwm4` **从不出错**；应用腿上才有 ⇒ **必须应用参与**（Fisher `0/40 vs 2/16 ⇒ p=0.078`；与 W105A 的 `R2` 率比 `0/40 vs 4/30 ⇒ p=0.030`）。 |
| **候选 (d)「`WM_NORMAL_HINTS` 把还原几何钳住」** | **排除**（该必要条件不成立） | 10 趟应用腿 + 40 趟纯 X 腿**逐趟逐采样**的 hints 并集**只有** `flags=0x10 PMaxSize=0 min=1x1 max=0x0`（＝**只有** `min 1x1`、**没有** `maximum size`）。 |
| **判据第一目标（三类可分开）** | **达成**：三类判别式 ＋ `SUB=i/ii/iii`（frame/client 时序分离）**已在两条真红腿上机械命中 ③-ii** | 判据 §1 的三类（①落地失败／②窗态未还原／③本族）**不需要人读**；本件新加的**事件级**中间拍把 `SUB=i`（WM 从未还原）与 `SUB=ii`（还原后又被打回）**分开**（`D-G98` 条目点名要求的那一条）。 |
| **是否落产品改动** | **没有，一个字节都没改**（按任务书边界：真因已定位 ⇒ **停手报主控**，修法属下一波） | 修法方向与**必须带的两极化／零回归**要件见 §6.5。 |
| **本件读数绑的是哪一份件** | `SHIM=2a297d6fee8be389`＋`pf=2a5b7641f6fba0fb`（＝ **W105A 的被测件**，装置读的是 `~/w89a/app`；权威件今天已是 `8392fc09564779a1`／`pf bc2c47ac7b067bad`） | 每趟 `probe.txt` **现场印**五件 sha16 ⇒ 读数**绑件**（`D-G80` 教训）；⚠️ 权威件在别的车道手里会动（W105A §2.3）⇒ 本件**故意**用**同一份冻结副本**与 W105A 的 74 趟台账可比。 |

---

## §1 判据（**先写**、逐字，`~/w112a/criteria.md` = `d98380adfb2efce7`）

### 1.1 三类现象的**机读判别式**（本件第一目标）
记 `BASE`＝进最大化前的 client 几何、`MAXG`＝屏幕几何、`S(t)`＝`_NET_WM_STATE`、`G(t)`＝client 几何、`F(t)`＝WM 的 frame 几何、`L`＝**落地证据**（§1.2）。

| 类 | 机读判别式 | 三态 |
|---|---|---|
| **① 接受/落地失败** | `¬L` ∧ `S`／`G` 全程未变 | 红（**不是本族**） |
| **② 窗态未还原** | `L` ∧ `is_max(S_settle)` | 红（**不是本族**） |
| **③ 本族** | `L` ∧ `¬is_max(S_settle)` ∧ `G_settle == MAXG`（`WAIT_R` 与 `SETTLE` **两拍都要**） | 红（**本族**） |

⚠️ **旧判据的缺陷（本件 C1 要修的正是它）**：W105A 的 `r_ok` **定义**＝`¬is_max(S) ∧ G==BASE` ⇒ 它是**结果计数**、**不是**落地计数 ⇒ `r_ok=0` 在字面上**分不开** ①②③（W105A §5 写"判词**就是**落地计数"，**这句在字面上不成立**：要人把 `state=`／`geom=` 两列一起读才能分类）。

### 1.2 `L`（落地证据，必须**独立于判词**）
`L = (1∨2∨3)`：①`INSTR=1` 的 HC `[GEO] Button#…` 行；②`WPF_LINUX_WINSTATE_DIAG=1` 的 `APPLY_WM_STATE … maximize=0`（**应用确实把还原请求发出去了**）；③动作后 `S` 至少变过一次。**只读结果不算 `L`**。

### 1.3 `SUB`：③ 的细分（`D-G98` 条目要求"抓 frame/client 时序分离 ⇒ 加中间拍"）

| `SUB` | 判别式 | 含义 |
|---|---|---|
| **③-i** | `t_REM→t_end` **一次都没**出现 `G==BASE` 或 `F==FRAME_BASE` | WM 从未还原 |
| **③-ii** | 存在 `t1`∈(t_REM,t_end) 使 `G(t1)==BASE` 或 `F(t1)==FRAME_BASE`，且 `G(t_end)==MAXG` | 还原后**又被打回** |
| **③-iii** | `G(t_end)==BASE` ∧ `F(t_end)==MAXG`（或反之） | 只回来一个 |

仪器：`~/w112a/bin/xeventwatch`（**外部只读**、事件级 `ConfigureNotify/PropertyNotify` ＋ 25 Hz 轮询兜底 ＋ `transient_mismatch` 计数）。

### 1.4 写者归因（③-ii 成立时必须指名）
`WPF_LINUX_CREATE_DIAG=1` 的 `[SHOW_DIAG] SetWindowPos a=<flags> b=<cx<<16|cy>`（谁在改尺寸）｜`WPF_LINUX_WINSTATE_DIAG=1` 的 `CONFIGURE/PROPERTY/ADOPT`（谁在改客户区）｜本件新增的 `LD_PRELOAD` 拦截器（§5.4，**直接给 backtrace ⇒ 符号名**）。
⚠️ 判据同时写死两条**禁用**：**不许**用"日志体积"当判别量（`D-G87`）｜**不许**把 `timeout: 被监视的命令已核心转储` 那 43 B 当应用输出（`W98A-F7`）。

### 1.5 先写的候选预测（(a)/(b)/(c)/(d)，逐条 6 条）＋ 分母口径 ＋ 先算好的样本量
- **候选 (c) 预测**：若成立 ⇒ `N` 臂红率应与应用腿同量级（8–27%）且 `SUB=i`；**不成立** ⇒ `0 红`，且（先写死）**`N≥20` 才够判显著**（`0/20 vs 4/15 ⇒ p=0.026`）。
- **正对照 `P` 先写死**：`REMOVE` 后 0.15 s 客户自己写回最大化几何 ⇒ **必须 100% 红**；**若 `P` 不红，则 `N` 臂的 0 红无意义**。
- **分母口径（`D-G94` 教训）**：进分母＝窗口起来 ∧ 有 `L` ∧ 观测器打了 `XWATCH=DONE`；`NOINFO_WINDOW`／`APP_DEAD`／`HEAVYSLOT=NOINFO`／`MAXHOLD_KILL`／`rc=124` ⇒ **`VOID`，既不算绿也不算红**。
- **先算好的样本量（`bin/power.py` 现算，非手抄）**：10% vs 0% ⇒ **88 趟/臂**；10% vs 2.5% ⇒ **176 趟/臂**；10% vs 5% ⇒ **>250**（n=250 时 power 仅 0.51）；`0/N` 的 95% 上界：`0/20⇒13.9%`、`0/30⇒9.5%`、`0/40⇒7.2%`。

---

## §2 只读取证（①）—— 74 趟台账的**不变量**（W105A 的读数，只读）

**来源**：`~/w89a/run/W105A-*/probe.txt`（74 份）经 `bin/legs-table.sh` 抽成 `out/legs-table.tsv`（sha16 `3e5fa5cb1e701d10`）。

### 2.1 不变量（**红绿都一样** ⇒ 只看终态**分不开**机制）
| 不变量 | 读数 |
|---|---|
| `BASE` | **74/74 恒为 `800x600@+240+212`** |
| `m_ok`（最大化落地） | **74/74 恒为 1** ⇒ **不是"点击被吞"** |
| `START_MAX` | **74/74 恒为 0** |
| 终态 `state` | **74/74 恒为 `_NET_WM_STATE_FOCUSED`**（红绿同值 ⇒ **窗态确实还原了**） |
| `fgeom == geom` | **74/74 成立**（frame 与 client 同尺寸 ⇒ 该应用**无装饰**） |

⇒ **两条硬结论**：①本族**不是** ①②，是 ③；②`fgeom==geom` 恒成立 ⇒ "WM 没收几何"与"有人把几何写回去"在**终态上无法区分** ⇒ **判据必须加中间拍**（本件 §1.3 就是为这条写的）。

### 2.2 分布（红腿全部落在 `R2`，但**判不出显著**，不许当机制）
| 分组 | 读数 | Fisher |
|---|---|---|
| `R2`（应用自带还原按钮） | **5/52** | `5/52 vs 0/20 ⇒ p=0.313` |
| `R1`（双击标题栏还原） | **0/20** | — |
| `N1`（最小化） | 0/2（`r_ok=na`） | — |
| 只看 26 腿 A/B 两臂 | `R2 4/30`｜`R1 0/20` | `p=0.140` |

### 2.3 A 臂 26 腿逐字段表（`PASS` 口径＝W105A 判据 §4 C1 的 8 字段逐字相等）
| # | 腿 | `m_ok` | `r_ok` | `r_ok2` | 终态 `state` | 终态 `geom` | `fgeom` |
|---|---|---|---|---|---|---|---|
| 1–5 | `C-m1r1-1…5` | 1 | 1 | 1 | `FOCUSED` | `800x600@+240+212` | `800x600@+240+212` |
| 6 | `C-m2r2-1` | 1 | 1 | 1 | `FOCUSED` | `800x600@+240+212` | `800x600@+240+212` |
| **7** | **`C-m2r2-2`** | 1 | **0** | **0** | `FOCUSED` | **`1280x1024@+0+0`** | **`1280x1024@+0+0`** |
| 8–9 | `C-m2r2-3`／`-4` | 1 | 1 | 1 | `FOCUSED` | `800x600@+240+212` | 同 |
| **10** | **`C-m2r2-5`** | 1 | **0** | **0** | `FOCUSED` | **`1280x1024@+0+0`** | **同** |
| 11 | `C-m1r2-1` | 1 | 1 | 1 | `FOCUSED` | `800x600@+240+212` | 同 |
| **12** | **`C-m1r2-2`** | 1 | **0** | **0** | `FOCUSED` | **`1280x1024@+0+0`** | **同** |
| 13–26 | 其余 14 条（`C-m2r1-*`／`F-*`／`I-*`／`V3-N1`） | 1 | 1 | 1 | `FOCUSED` | `800x600@+240+212` | 同 |

⇒ 三条红的**不一致字段只有 `r_ok`／`r_ok2`**（其余 8 字段逐字相等）⇒ **不是"很多项一起坏"**。

### 2.4 归因臂 20 趟的外部观测器（0.15–0.2 s 采样）分段（`bin/segments.py` ⇒ `out/c2-segments.txt`）
- **19 趟绿**：`800x600@+240+212` → `1280x1024@+0+0(MAX)` → `800x600@+240+212`，**状态与几何在同一拍内一起变**（≤0.17 s）。
- **1 趟红**（`W105A-C2-p09-old`）：`t=14.17` 状态掉了、**几何没动**（`1280x1024@+0+0`），**没有**看到 800x600 的回跳。
  ⚠️ 0.17 s 分辨率**不足以**排除"回跳后 <0.17 s 又被打回"⇒ 这是**线索**、**不是** `SUB` 判定（本件因此自建**事件级**观测器）。

---

## §3 纯 X 装置（②）—— 候选 (c) 的判别器（**不跑 WPF、零 dotnet、不入重活槽**）

### 3.1 装置（`~/w112a/bin/xmimic`，`sha16 f914d88f5c87c3ca`）
逐字照抄被测应用的**X 可见面**（现场逐条对齐 `win32_x11.c`）：窗口 `800x600@+240+212`｜`WM_NORMAL_HINTS` **只有** `PMinSize 1x1`（＝`wpf_x11_apply_wm_hints:1857-1868`，应用**未声明上限**）｜`WM_CLASS`／`WM_HINTS(InputHint)`／`_NET_WM_WINDOW_TYPE=NORMAL`／`_NET_WM_PID`（`:1870-1893`）｜`_MOTIF_WM_HINTS={2,0,0,0,0}`（装饰 0，`:1696-1702`）｜`PropertyChangeMask`（`:419`）＋ **与 `wpf_x11_apply_wm_state:1716-1748` 逐字同形**的 `_NET_WM_STATE` ClientMessage（`format=32, l[0]=1/0, l[1]=MAX_HORZ, l[2]=MAX_VERT, l[3]=1`，发往 root、`SubstructureRedirectMask|SubstructureNotifyMask`）。
三个相位：`addrem`（负臂 `N`）／`quick`（负臂 `N2`：`REMOVE` 紧跟 `ADD` 0.2 s）／`reassert`（**正对照 `P`**：`REMOVE` 后 0.15 s **客户自己** `XMoveResizeWindow(0,0,1280,1024)`）。
世界 = 私有 `Xvfb :186` ＋ `xfwm4`（`bin/xup-186.sh`）。观测器 = `bin/xeventwatch`（`sha16 e5ddb1440c284ddc` → 修 DONE 后 `a398b0c3dcd2b0de`）。

### 3.2 读数（`run/purex-20260922T222458/purex.log`，**44 趟全跑完**，`22:24:58 → 22:31:43` ＝ 6 min 45 s）
```
30 addrem  OK            ← 负臂 N：只 ADD→REMOVE，客户自己不动几何
10 quick   OK            ← 负臂 N2：REMOVE 紧跟 ADD 0.2 s
 4 reassert STUCK-GEOM   ← 正对照 P：SUB=ii-returned-then-back（4/4）
```
- **负臂合计 `0/40` 红**（95% 上界 **7.2%**）；**正对照 `4/4` 全红** ⇒ **装置灵敏度成立**（`4/4 vs 0/40 ⇒ p=7.4e-06`）。
- **候选 (c) 排除**：`0/40` vs 应用腿 `2/16 ⇒ p=0.078`；vs W105A 的 `R2` 率 `0/40 vs 4/30 ⇒ p=0.030` ⇒ **"WM 单独就会这样"按应用那个速率发生，判据上不成立**（先写死：`N≥20` 即够，本件做了 40）。
- **正对照逐字**（`P-001`）：
  `XMIMIC tag=P-001-reassert phase=reassert VERDICT=STUCK-GEOM SUB=ii-returned-then-back screen=1280x1024 t_ADD=2.00 t_REM=6.00 last_client=1280x1024@+0+0 last_state_max=0 … segs=0.00:0:800x600@+240+212|2.02:0:1280x1024@+0+0|2.06:1:1280x1024@+0+0|6.04:0:800x600@+240+212|6.16:0:800x600@+0+0|6.20:0:1280x1024@+0+0`
- **负臂逐字**（`N-001`）：`VERDICT=OK SUB=na … segs=0.08:0:800x600@+240+212|2.11:0:1280x1024@+0+0|2.15:1:1280x1024@+0+0|6.14:0:800x600@+240+212`

### 3.3 顺带取到的**WM 自己的次序**（事件级，`xeventwatch`；**纯 X 单客户端**，无我方代码参与）
```
最大化：EV frame ConfigureNotify(send_event=0) → EV client ConfigureNotify(send_event=0)
        → EV client ConfigureNotify(send_event=1, 合成) → EV PropertyNotify(_NET_WM_STATE)
还原：  EV _NET_FRAME_EXTENTS/_NET_WM_ALLOWED_ACTIONS → EV frame ConfigureNotify(send_event=0) 800x600@+240+212
        → EV client ConfigureNotify(send_event=0) 800x600@+0+0 → EV client ConfigureNotify(send_event=1)
        → EV PropertyNotify(_NET_WM_STATE)   ← **几何先、属性后**（相差 ~1–2 ms）
```
⇒ 两条**独立于应用**的事实：①`xfwm4` 的还原次序是**先改几何、后摘属性**（与 `win32_x11.c:1038-1041` 的注释一致，本件独立复现）；②整个第 `③` 类**做不出来**（0/40）。

---

## §4 各候选的**先写预测 vs 实测**

| 候选 | 先写的预测 | 实测 | 判定 |
|---|---|---|---|
| **(a) frame/client 时序分离 ⇒ 客户端回写旧值** | `t_REM` 后 `F` 变过而 `G` 没跟；`SUB=iii`；`SHOW_DIAG` 无尺寸写 | `SUB=ii`（**两个都真的回到了基准**，`G` 与 `F` 同步，`mism=0`；`transient_mismatch=0/15` 趟）；回写**确实存在**但来自 `SetWindowPos`（§5） | **部分成立**（分离**不是**原因；**回写是**） |
| **(b1) `rc_*` 还原矩形污染** | 只在**无 EWMH WM** 退化路径（`win32_core.c:664`）能成事 ⇒ 有 WM 时该路径**不可达** | 本件装置**有** WM（`_NET_SUPPORTING_WM_CHECK` 每趟在场）⇒ 该路径不可达；**没有任何读数**指向它 | **排除**（有 WM 时） |
| **(b2) `RestoreBounds`／`UpdateHwndRestoreBounds` 污染** | 红腿里 `t_REM` **之后**出现**不带 `SWP_NOSIZE`** 的 `SetWindowPos` | 16 趟应用腿**没有一趟**出现不带 `SWP_NOSIZE` 的 `SetWindowPos`（`SHOW_DIAG` 全量：`a=20/55/567`，**9 条/趟、无截断**） | **排除为本族主因** |
| **(b3) shim "以旧值发 `WM_SIZE`"** | `PROPERTY x_maximized=0` 紧跟着 `sizecode=1`／`sizecode=0` 却带 `1280x1024` 的自相矛盾对 | **出现了**（红腿 `pilot01` 第 74-75 行：`PROPERTY … x_maximized=0` → `CONFIGURE 1280x1024@+0+0 ⇒ WM_SIZE sizecode=0`，＝把**陈旧的最大化几何**配 `SIZE_RESTORED` 送上去；`pilot01` 里也确有 `CONFIGURE 800x600@+0+0 ⇒ sizecode=2` 的**反向矛盾**（最大化的 sizecode 配基准尺寸）） | **成立（真，但不是"几何没回来"的成因）**：它污染的是**托管侧 DP**，本身不写几何 ⇒ 与 (b4) 同族、值得并案处理 |
| **(c) WM 自己没收几何** | 纯 X 负臂应复现 8–27% 且 `SUB=i` | 纯 X 负臂 **0/40**（上界 7.2%）；正对照 4/4；且**红腿里 WM 确实收回了**（`SUB=ii`） | **排除** |
| **(d) hints／min-max 交互把还原几何钳住** | 红趟的 `WM_NORMAL_HINTS` **必然**出现 `maximum size`（或 min≠`1 by 1`） | 40 趟纯 X ＋ 16 趟应用腿逐采样只有 `flags=0x10 PMaxSize=0 min=1x1 max=0x0`（**无 `maximum size`**）；`n_pmax_seen=0` | **排除**（必要条件不成立） |
| **(b4)★「无副作用的 `SetWindowPos` 被落成真实几何写、且写的是**陈旧缓存**」 | 红腿应出现"`SetWindowPos(NOSIZE|NOMOVE)` 之后写出的矩形 == 最大化矩形"，且该写发生在 WM 还原**之后** | **命中**：`T-05` 的写＝`(0,0 1280x1024)`（红）｜14 趟绿的写＝`(0,0 800x600)`；符号级 backtrace＝`SetWindowPos → wpf_x11_move_resize → XMoveResizeWindow`；观测器证明几何"先回基准、70–80 ms 后被设回最大化" | **真因（本件结论）** |

---

## §5 应用诊断腿（③，最小复现）—— 真因取证

### 5.1 装置与**全部公告差异**（相对 `~/w89a/bin/hc-arm-inner.sh`，`sha16 ca7ef5d23ab5a032`）
`~/w112a/bin/leg-diag.sh`（`sha16 061d0ec73c4b57cf`）＝ 原件**逐字节相同 ＋ 5 处**（`diff` 全文可验）：
1. 输出目录改 `~/w112a/run/`；2. `export WPF_LINUX_WINSTATE_DIAG=1`；3. `export WPF_LINUX_CREATE_DIAG=1`；
4. 挂事件级观测器 `xeventwatch`（按 PID、自然退出、写 `watch.txt`）；5. `XTRACE=1` 时 `LD_PRELOAD=libxgeomtrace.so`（§5.4）。
`INSTR` 仍默认 **0**；私有世界 `:187`（`Xvfb 1280x1024x24` ＋ `xfwm4`）。
件（每趟 `probe.txt` 现场印）：`SHIM=2a297d6fee8be389`｜`BRIDGE=feef049e9d0e313a`｜`PC=56ee75ced8d6aece`（原文见各 `probe.txt`）｜`PF=2a5b7641f6fba0fb`｜`WB=2e4e46e539a72cd7`｜`APPEXE=1ac5e587cda3fb20`。

### 5.2 趟数／落地计数／复现率／分母口径
| 项 | 读数 |
|---|---|
| 趟数 | **16 趟**（`W112A-pilot01` 无 tracer ＋ `W112A-T-01…T-15` 带 tracer），腿型一律 **`M2×R2`** |
| **`VOID`** | **0 趟**（16/16 窗口起来、有 `RESULT`、`START_MAX=0`、`m_ok=1`） |
| **落地证据 `L`** | **16/16** 都有 `[SHOW_DIAG] ShowWindow a=9`（`SW_RESTORE`）＋ `APPLY_WM_STATE … maximize=0（我们发的 _NET_WM_STATE REMOVE）` ⇒ **不是类①** |
| 红 | **2/16 ＝ 12.5%**（`pilot01`、`T-05`）；带 tracer 的子集 **1/15**（6.7%） |
| 绿 | 14/16；红绿**只有** `geom`／`fgeom`／`r_ok`／`r_ok2` 四项不同，其余字段逐字相等 |
| 分母口径 | 进分母 = 16（无 `NOINFO_WINDOW`／`APP_DEAD`／`HEAVYSLOT=NOINFO`／`MAXHOLD_KILL`／`rc=124`）⇒ **分母干净** |

### 5.3 两条红腿的**逐字**读数（观测器 = 外部、只读、事件级）
**（甲）`W112A-pilot01`（无 tracer，`BASE=800x600@+240+212`）——红**
```
probe.txt: AFTER_R2 state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok=0 (基准=800x600@+240+212 最大化=1280x1024@+0+0)
           AFTER_R2_SETTLED state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok2=0 frame=0x200264 fgeom=1280x1024@+0+0
watch.txt : (t=5.772) PropertyNotify _MOTIF_WM_HINTS
            (t=5.773) ConfigureNotify client send_event=1 geom=1280x1024@+0+0
            (t=5.775) ConfigureNotify frame  send_event=0 geom=800x600@+240+212   ← WM 把 frame 收回基准
            (t=5.816) ConfigureNotify client send_event=0 geom=800x600@+0+0      ← WM 真改客户区到基准
            (t=5.816) ConfigureNotify client send_event=1 geom=800x600@+240+212
            (t=5.816) PropertyNotify _NET_WM_STATE                                ← 属性在此摘掉（几何先、属性后）
            (t=5.886) ConfigureNotify frame  send_event=0 geom=1280x1024@+0+0     ← ★ 70 ms 后 frame 回到最大化
            (t=5.887) ConfigureNotify client send_event=0 geom=1280x1024@+0+0     ← ★ 客户区也被改回最大化
            (t=5.888) ConfigureNotify client send_event=1 geom=1280x1024@+0+0
            (t=5.898) SAMPLE client=1280x1024@+0+0 frame=1280x1024@+0+0 state_max=0
```
**（乙）`W112A-T-05`（带 tracer，`BASE=800x600@+0+0`）——红**
```
geomtrace.log: XT t=113037.006 fn=XMoveResizeWindow win=0xa00004 a=0 b=0 c=1280 d=1024   ← 最大化那一拍（应用自己写的）
               XT t=113042.285 fn=XMoveResizeWindow win=0xa00004 a=0 b=0 c=1280 d=1024   ← ★ 还原那一拍：**应用自己又把最大化矩形写了一遍**
watch.txt   : 5.715 PropertyNotify _MOTIF_WM_HINTS｜5.715 client synthetic cfg 1280x1024
               6.005 frame cfg(send_event=0) 800x600@+0+0｜6.005 client cfg(send_event=0) 800x600@+0+0
               6.005 client synthetic cfg｜6.005 PropertyNotify _NET_WM_STATE
               6.084 frame cfg(send_event=0) **1280x1024@+0+0**｜6.084 client cfg(send_event=0) **1280x1024@+0+0**   ← ★ 79 ms 后被打回
（本趟**没有** `XWATCH=DONE` 行：`T-05` 跑在观测器修好**之前**，目标窗被销毁后观测器被 `BadDrawable` 带走
 ⇒ 这正是 §8.1 第 4 条登记的自伤；上表事件取自窗口存在期间**已 flush** 的读数，最后一条 `EV t=14.698 DestroyNotify(frame)`）
```
⇒ 两条红腿**都是 `SUB=ii`**（"WM 从未还原"`SUB=i` **被排除**：WM 明确把 frame 与 client 都收到了基准）。

### 5.4 ★**写者归因**（`LD_PRELOAD` 拦截 Xlib 几何写 ＋ `backtrace()` ⇒ 符号名；`sha16 8f23232cb3dc53a8`）
`~/w112a/src/xgeomtrace.c` → `bin/libxgeomtrace.so`：拦截 `XMoveResizeWindow`／`XMoveWindow`／`XResizeWindow`／`XConfigureWindow`，逐次记 `t`／参数／`backtrace`／各模块装载基址（`dl_iterate_phdr`）。**只加环境变量、不改任何产品件、不重建**。事后用 `nm`（该 `.so` **not stripped**）把地址翻成**函数名**：

```
XT t=113344.122 fn=XMoveResizeWindow win=0xa00004 a=0 b=0 c=800 d=600
   bt: libxgeomtrace.so+0x159c (XMoveResizeWindow)
       libwpfwin32.so+0x176c7  (wpf_x11_move_resize)        ← win32_x11.c:476-485
       libwpfwin32.so+0x11d44  (SetWindowPos)               ← win32_core.c:1154-1225（:1210 无条件写）
```
`T-05`（红）的同两条 write 的 `bt` 偏移**逐位相同**（`+0x176c7`／`+0x11d44`）⇒ **红绿两态的这一次写来自同一个调用点**。

**机械链条（每一跳都有现场读数）**：
1. 应用点"还原"⇒ `[SHOW_DIAG] ShowWindow a=9`（`SW_RESTORE`）⇒ `APPLY_WM_STATE … maximize=0`（**`L` 成立**）⇒ shim `wpf_core_window_state(NORMAL)`（`win32_core.c:626-667`）发 `_NET_WM_STATE REMOVE`。
2. 同一拍的**下一次** `[SHOW_DIAG] SetWindowPos a=567`（`0x237` ＝ `SWP_NOSIZE|SWP_NOMOVE|SWP_NOZORDER|SWP_NOACTIVATE|SWP_FRAMECHANGED|SWP_NOOWNERZORDER`）⇒ shim 把 `nx,ny,nw,nh` **全部取自窗口表缓存**（`win32_core.c:1184-1189`）**却仍无条件**调 `wpf_x11_move_resize`（`:1210`）⇒ `XMoveResizeWindow`（`win32_x11.c:481`）⇒ **一次"本应无副作用"的调用被落成一次真实的几何写**。
3. 写的**内容**＝**缓存里的矩形**：`T-05` 红腿那次＝`(0,0,1280,1024)`（**还是最大化矩形**）；14 趟绿腿那次＝`(0,0,800,600)`（**已是还原后的矩形**）。
4. 这条写是**客户端 ConfigureRequest**，而它排在 `REMOVE` **之后** ⇒ WM 先完成 unmaximize（几何回基准），**再**顺从这条请求把窗口改回 `1280x1024@+0+0`（frame 跟着改）⇒ `state` 已 `FOCUSED`、几何与 frame 双双卡在最大化 ＝ **`D-G98` 的逐字形态**。
5. **间歇性**＝**缓存值的竞态**：谁先到 —— UI 线程上这次"无副作用的 `SetWindowPos`"，还是 X 泵把 WM 的还原 `ConfigureNotify` 采纳进缓存（`win32_x11.c:1047-1059`）。

### 5.5 判词与"写的内容"的**相关**（本件最硬的量化判别）
| 还原那一拍的客户自写（`geomtrace`） | 趟数 | 判词 |
|---|---|---|
| **`1280x1024`（陈旧缓存＝最大化矩形）** | **1/1** | **红（`r_ok=0`／`r_ok2=0`）** |
| **`800x600`（缓存已是还原矩形）** | **0/14** | **绿** |

⇒ `1/1 vs 0/14 ⇒ Fisher 双尾 p=0.067`（**样本小**：单看它不够判显著；它的作用是**与 §5.3／§5.4 的机制读数互相独立、方向一致**）。
`W112A-pilot01`（无 tracer）**没有** writer 读数，但它与 `T-05` 的 `SHOW_DIAG` 序列**逐行相同**、且终态正是**最大化矩形**（`1280x1024@+0+0`）⇒ 与"陈旧缓存写"**形态自洽**（**不算独立证据**，如实并列）。

---

## §6 结论

### 6.1 真因（**定位**，三条独立证据）
> **`D-G98` 的真因 = 我方 `win32shim` 的 `SetWindowPos` 语义缺陷 ＋ 一次**缓存值竞态**：**
> 应用在"还原那一拍"会调一次 **`SetWindowPos(SWP_NOSIZE|SWP_NOMOVE|…|SWP_FRAMECHANGED)`（本意只是"重算窗框/自绘 chrome"的无副作用调用）**，而 shim **无条件**把它落成一次真实的 `XMoveResizeWindow`，写的是**窗口表缓存**里的矩形；
> 若这一拍缓存里**还是最大化矩形**（X 泵尚未采纳 WM 的还原 `ConfigureNotify`），这条**客户端请求就排在 `REMOVE` 之后** ⇒ WM 先完成 unmaximize、**再**把窗口改回最大化 ⇒ **窗态 `FOCUSED`（已还原）＋ client 与 frame 双双卡在 `1280x1024@+0+0`** ＝ `D-G98`。

**三条独立证据**：①`backtrace` 符号链 `SetWindowPos → wpf_x11_move_resize → XMoveResizeWindow`（§5.4）；②外部事件级观测器：**几何先真的回到基准、70–80 ms 后被打回**（§5.3，`SUB=ii`）；③写的内容与判词相关 `1/1 vs 0/14`（§5.5）。
**两条排除**：候选 (c)（纯 X `0/40` ＋ 正对照 `4/4`）与 (d)（hints 全程无 `maximum size`）；**(b1)／(b2) 也排除**（(b1) 有 WM 时不可达；(b2) 预测的"不带 `SWP_NOSIZE` 的 `SetWindowPos`"在 16 趟里**一次都没出现**）。

### 6.2 判据成果（本件第一目标）
- 三类判别式 ＋ `L`（独立落地证据）＋ `SUB=i/ii/iii` **已给出并命中**：两条红腿机械判为 **③-ii**；`SUB=i` 被**排除**。
- **现有判据的缺口**（要并进预登记模板）：`r_ok` 是**结果计数**、不是落地计数（①③会混）；**两拍采样不够**（`D-G98` 条目已点名）；本件补：**事件级观测器 ＋ 写者归因**两件必备仪器。

### 6.3 世代位（本件**一位未动**）
`win32shim`（权威）现场 `sha256sum` = **`8392fc09564779a1`**；`pf` = **`bc2c47ac7b067bad`**；`pc` = **`722e0ab8205b7c3f`**（均为**现场现算**，与本件读数**无关**——本件全部读数绑的是 `~/w89a/app` 的冻结副本 `SHIM=2a297d6fee8be389`／`pf=2a5b7641f6fba0fb`，每趟 `probe.txt` 印出）。**本件只写了 `~/w112a/**` ＋ 本报告**。

### 6.4 `NOINFO`（既不算绿也不算红）
1. **"哪一次 DP 写／哪个上游调用点让缓存**仍是**最大化矩形"未用托管侧仪器直接证到** —— 我读到的候选是 `Window.cs` 的 `_updateHwndSize` 是**布尔量（非深度计数）**＋ shim 自己的 `SetWindowPos` 会**再派发一条 `WM_SIZE`**（`win32_core.c:1220` ⇒ **嵌套** `WmSizeChanged`）⇒ 内层 `finally` 会把守卫**提前恢复**，使外层剩下的 `SetValue(Width/Height)` 泄漏进 `OnWidthChanged → UpdateWidth`（`Window.cs:5799／3040+`）。**这是代码级推断，不是读数** ⇒ 记 `NOINFO`。
2. **两臂速率差的显著性**：本件 `2/16`（95% CI 宽）与 W105A `R2 4/30` 判不出差别 ⇒ 要 ≤5% 置信区间需**每臂数百趟**（`bin/power.py` 先算：10% vs 5% ⇒ >250/臂）。
3. `R2` 比 `R1` 更易红（`0/20 vs 5/52 ⇒ p=0.313`）**判不出** ⇒ 机制上**不许**据此下结论。
4. 本件**未测**当前权威件 `8392fc09564779a1` 与 `#51` 的新 `pf bc2c47ac7b067bad`（登记差异正是为了避免第二个自变量）。

### 6.5 修法方向（**本件不落**，按边界交主控；下一波必须带两极化＋零回归）
- **首选（最小、最窄）**：`win32_core.c:1184-1210` —— 当 `SWP_NOSIZE|SWP_NOMOVE` **同时**置位时，**不要**再调 `wpf_x11_move_resize`（Win32 语义下这是一次"什么都不改"的调用）；若为"保证窗框同步"仍要落 X，则必须先**用 X 现场几何**（`wpf_x11_query_geometry`）而不是用**缓存**。
- **次选（同族一并处理）**：`win32_x11.c:1435-1437`（`PROPERTY` 路径用 `adopt_maximized` 抓的**陈旧** `w->width/height` 发 `WM_SIZE`）＋ `:1047`（`CONFIGURE` 先采纳再算 `sizecode` 的次序）⇒ 把"发 `WM_SIZE` 用的几何"改成**这一次事件自带的几何**（`ev.xconfigure`）。
- **必需的两极化**：①修后**必须**能构造"写＝最大化矩形"的场景而**不再**产生几何回写（可用 `LD_PRELOAD` 仪器直接读 backtrace 断言"NOSIZE|NOMOVE 路径不再调 `XMoveResizeWindow`"）；②**反极性**＝把该守卫撤掉 ⇒ 红族**回到**可复现（本件已有 `2/16` 的复现率读数可直接当反极性分母）。
- **零回归**：W105A 的 26 腿（`0104` 四入口＋`N1`）＋ `0106` `D-G83` 四格；并注意 `0104` 里 `R2` 腿的 `r_ok` 判词**本来**就会间歇红 ⇒ **判据要先改**（§6.2）再判零回归，否则会把既存间歇又算成回归。

---

## §7 槽／耗时台账 ＋ 作废趟

| 批次 | 命令（入槽） | 读数 |
|---|---|---|
| 纯 X（**不入槽**：零 `dotnet`、单核、`nice -n 15`，判据 §3.4 先写） | `bash ~/w112a/bin/purex-run.sh 30 10 4` | `22:24:58 → 22:31:43`（**6 min 45 s**／44 趟）；`Xvfb :186` PID `3811332`、`xfwm4` PID `3811345` |
| 应用腿 1（pilot） | `WDISP=:187 bash ~/heavy-slot.sh --min-avail 1500 --max-hold 300 --wait 900 -- timeout 290 bash bin/leg-diag.sh W112A-pilot01 M2 R2` | `HEAVYSLOT=ACQUIRED waited=0s` / `MEMOK avail=2820MB` / **`RELEASED rc=0 held=26s`** ⇒ **红** |
| 应用腿 2（10 趟＋tracer） | `WDISP=:187 bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1500 --wait 1800 -- timeout 1490 bash bin/appbatch2.sh 10 W112A-T` | `MEMOK avail=2780MB` / **`RELEASED rc=0 held=246s`**（≈24.6 s/趟）⇒ 红 **1**（`T-05`） |
| 应用腿 3（3 趟，观测器修好后） | 同上，`appbatch3`（`max-hold 600`） | 红 **0**（`T-11/12/13`），`XWATCH=DONE` **在场** |
| 应用腿 4（2 趟，tracer 修好后） | 同上，`appbatch4` | 红 **0**（`T-14/15`） |

- **作废趟**：**0**（无 `HEAVYSLOT=NOINFO`／`MAXHOLD_KILL`／`TIMEOUT`／`rc=124`／`NOINFO_WINDOW`／`APP_DEAD`）；**无一条读数进不了分母**。
- 内存：16 趟腿内 `MemAvailable` 观测 **2,467–2,820 MB**；`OOMKILL_BEFORE/AFTER` 逐趟 **0/0**；`oom_kill`（`/proc/vmstat`）全程 0。
- 收工：`Xvfb :186`／`:187` 与 `xfwm4` **按 PID 收**（**零 `pkill -f`**）；我方残留进程 **0**（`pgrep -a -f "w112a/bin/(xmimic|xeventwatch)"` 空）。

---

## §8 自伤／纪律偏离／`NOINFO`（**不辩解**）

### 8.1 自伤（全部在读数前或读数外被发现，逐条影响评估）
0. **🔴 被运行时挂死一次（21:57）**：会话中断、**先前未落盘的中间结论全部丢失**，`:186` 被带走。**影响**：无读数作废（此前只有装置自检与只读取证）；**22:06 起按主控指示续跑**并**先建 `~/w112a/STATUS.md`**（此后每步追加）。
1. **`xmimic` 第一版把 `XGetGeometry` 的第 2 个出参当成 parent（它其实是 `root`）** ⇒ 坐标恒报 `+0+0`。**修法**：自己 `XQueryTree` 取 parent 再 `XTranslateCoordinates`。**影响**：自检两趟作废（`out/dbg.out`），**不进任何分母**。
2. **纯 X 装置第一版没有"基准矩形真的到位"的守卫** ⇒ `xfwm4` 按自己的策略把窗放在 `+0+0`，而真应用在 `+240+212`。**修法**：显式申请基准矩形并**等到到位**才起相位计时。**影响**：自检趟作废；**正式 44 趟全部"基准到位"**。
3. **`dlinfo(RTLD_DEFAULT,…)` 写错** ⇒ 第一版 tracer **一行 `XTLIB` 都没写** ⇒ 前面的 `bt` 地址**无法翻符号**。**修法**：改 `dl_iterate_phdr`；**影响**：`T-05` 的 `bt` 靠**偏移相同**（`+0x176c7`／`+0x11d44`）与 `T-14` 对齐后才翻出来 ⇒ **属于"事后补证"，已如实标注**（§5.4 用的是 `T-14` 的模块基址）。
4. **观测器 `xeventwatch` 在目标窗被销毁后自杀**（轮询触发 `BadDrawable`，**Xlib 默认错误处理器直接 `exit()`**）⇒ 前 **10 趟** `XWATCH=DONE` **缺**。**修法**：装不退出的错误处理器（`xerr_ignored` 计数进 DONE 行）；`T-11…T-15` 五趟 **DONE 在场**。**影响**：按判据 §1.3 的**严格**读法，前 10 趟的 `SUB` 应记 `NOINFO`（**我已如实标注**）；但这两条红腿的 `SUB` 判定**不依赖 DONE 行**（用的是窗口存在期间**已 flush** 的事件），且 `T-05` 的**写者归因**另有 `geomtrace`（**逐趟独立文件**，收工时自然 `fclose`）⇒ 实质结论不受影响。
5. **`LD_PRELOAD` 拦截器改动了装置的**基准位置**（仪器自伤）：带 tracer 的 15 趟里 **BASE=800x600@+0+0**（不带 tracer 的 `pilot01` 是 `+240+212`，W105A 74 趟也全是 `+240+212`）⇒ **本件把"带 tracer 的腿"当**独立一批**看（红绿都在这一批内对比）**；`T-05` 的红在**这一批内**复现（`1/15`），而**不带** tracer 的 `pilot01` 也红（`1/1`）⇒ 两种配置下**都**能出现本族。**这是本件最需要读者警惕的一处**。
6. **判据 `criteria.md §3.3` 的分母写错了**（我写 `4/15 vs 0/10 ⇒ p=0.27`；26 腿里 `R2` 实为 **30** 趟、`R1` **20** 趟 ⇒ 正解 `4/30 vs 0/20 ⇒ p=0.140`）。**判据不追改**（先写的价值高于好看），**结论方向不变**（仍判不出）。
7. 判据 §1.3 要求"每趟必须打 `XWATCH=DONE`，缺则 `SUB` 记 `NOINFO`" —— 见第 4 条，**前 10 趟违反**；本报告**同时**给出严格判定与实质判定，**不合并**。
8. `leg-diag.sh` 的 `say` 行把 `OBS` 默认值写成 30、实际传 28（文案与取值差 2 s）—— 只影响可读性，**不影响读数**。

### 8.2 纪律核对（如实）
`重活全部入槽` ✓｜`--min-avail 1500` ✓｜纯 X 臂**不入槽**并**已先写在判据 §3.4 里说明理由** ✓｜私有 X 只用 `:186`／`:187`（**未碰** `:0/:1/:10/:95/:96/:97/:99` 与别人在用的显示号）✓｜X/WM **按 PID 收、零 `pkill -f`** ✓｜**未跑** `verify-all.sh`／`close-wave.sh`／`integration-wave.sh` ✓｜**未碰**产品件／四个路由件／册／`defect-registry-declared.tsv`／冻结基线／`~/w111a/**`（只读 `dg98-dg99.md`）／`~/w105a/**`（只读）✓｜**未**手抄哈希（判据/件/报告全部现场 `sha256sum`）✓。

---

## §9 大白话小结（≤6 行）
1. **真因找到了**：点"还原"的那一拍，应用会顺带调一次"什么都不改"的 `SetWindowPos`，而我们 shim 把**这种空调用也真的写了一次窗口几何**——写的是**自己缓存里的矩形**；那一瞬缓存里**还留着最大化矩形**，于是这条"改回最大化"的请求**排在"取消最大化"后面**送进 WM：WM 先老老实实把窗口收回 800×600，随后又顺从这条请求把它改回 1280×1024 ⇒ **窗态对了、尺寸和边框都卡在最大化**。
2. **三条独立证据**：反汇编级(符号)调用链 `SetWindowPos→wpf_x11_move_resize→XMoveResizeWindow`；外部只读观测器看到"**先收回、70–80 ms 后被打回**"；以及"写的是最大化矩形 ⇒ 红 1/1、写的是基准矩形 ⇒ 绿 0/14"。
3. **不是 WM 的错**：纯 X 装置（不跑 WPF）跑 40 趟 `ADD→REMOVE` **一趟都没红**，而正对照（客户自己写回最大化）**4/4 全红** ⇒ 装置有牙、WM 清白。
4. **不是提示(hints)的错**：40＋16 趟逐采样，X 侧提示**全程只有 `min 1x1`、没有 `maximum size`**。
5. **判据也补齐了**：三类现象（点击没落地／窗态没还原／窗态还原了几何没回来）现在**机器可分**，并加了"中间拍"与"写者归因"两件仪器；旧判据把 `r_ok` 当落地计数是**错的口径**。
6. **我没做到的**：**没改产品**（按边界停手报主控，修法建议在 §6.5）；"缓存为何还是最大化矩形"的最内层（上游 `_updateHwndSize` 布尔守卫＋shim 自己嵌套派发 `WM_SIZE`）只到**代码级推断**；我的 `LD_PRELOAD` 仪器把基准位置从 `+240+212` 挪成了 `+0+0`（**已登记**，红绿在同一批内对比）；`2/16` 的复现率**不足以**谈两臂速率差。

---

## §10 复现（命令级）＋ 件 sha16 一览
```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 判据（先写）      cat ~/w112a/criteria.md                       # sha16 d98380adfb2efce7
# 只读取证          bash ~/w112a/bin/legs-table.sh > ~/w112a/out/legs-table.tsv
#                   python3 ~/w112a/bin/segments.py                # W105A 观测器分段
# 私有世界（纯X）   bash ~/w112a/bin/xup-186.sh                    # Xvfb :186 + xfwm4（按 PID 收）
# 纯 X 臂           bash ~/w112a/bin/purex-run.sh 30 10 4          # 负臂30+10 / 正对照4
# 私有世界（应用）  bash ~/w112a/bin/xup-187.sh
# 应用诊断腿        WDISP=:187 bash ~/heavy-slot.sh --min-avail 1500 --max-hold 1500 --wait 1800 -- \
#                     timeout 1490 bash ~/w112a/bin/appbatch2.sh 10 W112A-T     # XTRACE=1 已写在脚本里
# 写者归因          gcc -O2 -shared -fPIC -o ~/w112a/bin/libxgeomtrace.so ~/w112a/src/xgeomtrace.c -ldl
#                   nm -C --defined-only ~/w89a/app/libwpfwin32.so | sort      # 地址→函数名
```
| 件 | sha16 |
|---|---|
| `~/w112a/criteria.md`（判据，先写） | **`d98380adfb2efce7`** |
| `bin/xmimic`（纯 X 客户模仿器） | `f914d88f5c87c3ca` |
| `bin/xeventwatch`（事件级观测器；修 DONE 前/后） | `e5ddb1440c284ddc` → **`a398b0c3dcd2b0de`** |
| `bin/libxgeomtrace.so`（写者归因；修 XTLIB 前/后） | `47d8d6b30b809534` → **`8f23232cb3dc53a8`** |
| `bin/leg-diag.sh`（应用腿装置，5 处公告差异） | `061d0ec73c4b57cf` |
| `bin/purex-run.sh` / `bin/appbatch2.sh` / `bin/power.py` | 现场 `sha256sum`（见 `~/w112a/bin/`） |
| `out/legs-table.tsv` / `out/c2-segments.txt` / `logs/final-fisher.txt` | `3e5fa5cb1e701d10` / `7172c63fc693ccbc` / 现场 |
| 被测件（装置读的副本） | `SHIM=2a297d6fee8be389`（327,240 B）／`pf=2a5b7641f6fba0fb` |
| 现场权威件（**本件未用**） | `win32shim 8392fc09564779a1`／`pf bc2c47ac7b067bad`／`pc 722e0ab8205b7c3f` |

W112A-report.md sha16 = **`3e1223d42b8f23a4`**（口径：**本文件正文** = `head -n -2 本文件`（去掉末行的本行与它上面那个空行）｜现场 `sha256sum` 复算，**未手抄**）

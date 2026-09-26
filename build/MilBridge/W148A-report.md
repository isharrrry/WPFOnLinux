# W148A 报告 —— `TASK-0110`「几何还原残留」**只读侦察 ＋ 中间拍设计 ＋ 判据先行**

> 车道 `W148A`｜目录 `~/w148a/**`｜`R = /home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（**不是** git 仓库）
> **纪律**：本车道**未跑任何应用腿**（0 腿）｜**未跑任何重活**（未调 `~/heavy-slot.sh`、未动 `~/heavy.lock`）｜**未跑** `dotnet`／`verify-all.sh`／`close-wave.sh`／`integration-wave.sh`｜`$R` **零写入**。
> 一切读数标 `RECON`（= 只读复算既有台账，**不是**本车道跑的判决读数）或 `DESIGN`（= 交付给落地车道的设计）。
> 报告 sha16 见 §5（**现场现算**）。

---

## §0 一句话判决（结论在前）

> **`TASK-0110` 的标题前提被推翻**：**WM 确实执行了"退出最大化的几何还原"**。
> 既有台账里"WM 没收回几何"这个结论是**欠采样伪影** —— 现行两拍落在事件后 **~4.5 s / ~9.0 s**，
> 而"真还原 → 被顶回"的驻留只有 **41–86 ms**（median 81 ms）⇒ **错位约 100 倍**，把那一对事件整对吞掉。
> **中间拍的正确形态不是"再睡短一点"，而是把拍位改成事件锚定**（`B_link` 与 `Δ_push`），
> 并把"frame/client 分离"判在**时刻**上、不判在**值**上（值与值之间在还原那一跳**从来不分离**）。

**三条附带判决**：
1. **"两拍不够"这句话要改写**：第一拍（`AFTER_R`）**根本不读 frame**（`hc-arm-inner.sh:127-129`；frame 只在 `:144` 才算）
   ⇒ `TASK-0110` 要的"时序分离"**在结构上就缺一列**，不是精度问题。
2. **一条既有仪器把红读成"几何从未回来"**：150 ms 观测器在同一条红腿上 **132 个样本里 `800x600` 出现 0 次**（`RECON-R2`）。
3. **`TASK-0110` 要求的第 ③ 格 `_NET_FRAME_EXTENTS` 在本装置上是恒真谓词**（233/233 = `0,0,0,0`）⇒ **不许进判据**（假牙）。

---

## §1 我实际跑过的命令与关键输出（逐条）

### 1.1 冻前硬闸（`⛔` 只读判据）—— **未开，本车道全程只读**

```
$ mkdir -p ~/w148a/logs && date -u +'%Y-%m-%dT%H:%M:%SZ' && uptime
2026-09-23T15:14:53Z
 23:14:53 up 13:29,  1 user,  load average: 2.87, 3.98, 3.82

$ R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
$ grep -o 'gen=#[0-9]*' <(sed -n '9p' $R/docs/CURRENT-STATE.md)
gen=#55
$ ls -l ~/w21-verify/w56-record.txt
-rw-r--r-- 1 links-dev links-dev 24937  9月 23 23:13 /home/links-dev/w21-verify/w56-record.txt
$ sed -n '9p' $R/docs/CURRENT-STATE.md
> BASELINE-FROZEN gen=#55 sha16=38320d5e377a0dc8 file=samples/WpfTextDemo/ACCEPTANCE-BASELINE.md
```
**判据** = `gen=#56` **∧** `w56-record.txt` 存在 ⇒ **只满足了一半**（记录文件在，`gen` 仍是 **`#55`**）。
⇒ 按派单书的硬闸，本车道**全程只做静态阅读与仓外写作**（`$R` 零写入、不跑应用腿）。
**收工前末次复读仍为 `gen=#55`**（同一命令，23:3x）⇒ **本车道自始至终在只读档位**。**如实记**。

### 1.2 现场（`TASK-0110`／`D-G98`）

```
$ grep -n 'TASK-0110' $R/docs/ROUTES.md
401:  - `TASK-0110` [Next] 🟡 **几何还原残留：查"WM 为什么不把退出最大化的几何收回去"**（`D-G98` 的落地；来源 = 车道 W105A 报告 §4.2／§9.1 的 26 腿零回归复核 ＋ W89A §5.3 的首次登记）：
413:  - 🔁 **`TASK-0110` 追加一行（车道 WC02，2026-09-23…）**…**但未归因**（**属 `NOINFO`**）⇒ **状态位仍 🟡**（**不许**转 ✅）。
$ grep -n 'D-G98' $R/samples/WpfFeatureProbe/KNOWN-DEFECTS.md
2624:### `D-G98`（**产品/装置界面缺陷 · 几何还原残留**）：退出最大化后 `_NET_WM_STATE` **已还原**、而 **client 几何与 WM 的 frame 几何双双卡在 `1280x1024@+0+0`**（**间歇**）
$ sed -n '395,420p' $R/docs/ROUTES.md          # TASK-0110 §13 树行全文（含"两拍不够、要加中间拍"、四格要求、N 拍先写死、反极性、NOINFO）
$ sed -n '2624,2700p' $R/samples/WpfFeatureProbe/KNOWN-DEFECTS.md   # D-G98 全部追加段
$ sed -n '170,215p' $R/build/MilBridge/W105A-report.md              # §4.2 三条红腿原文 ＋ 家族特征四条的来源
$ sed -n '/^### 9\.1/,/^### 9\.2/p' $R/build/MilBridge/W105A-report.md  # §9.1（红腿落在无 P2 旧件上）
```

**关键原文（`D-G98`，`:2627-2628`）**：
```
AFTER_R2          state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok=0  (基准=800x600@+240+212 最大化=1280x1024@+0+0) mapstate=IsViewable
AFTER_R2_SETTLED  state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok2=0 frame=0x2003bc fgeom=1280x1024@+0+0
```
**`W105A` §4.2 家族特征第 3 条原话**：`几何没收回…且 WM 的 frame 也还在最大化（fgeom=1280x1024@+0+0）⇒ 是 WM 没执行"退出最大化的几何还原"，不是"应用没请求"`。
—— **这句就是本件要翻的那句。**

### 1.3 "现行两拍"在哪（§2 要求的 `grep`）

```
$ grep -rn 'AFTER_R2' $R ~/wc03 ~/wc05 2>/dev/null
```
**结果**：`$R` 里**只有报告与登记册**（`build/MilBridge/W105A-report.md:177-181,208-211`｜`W111A:44,69`｜`W112A:173-174`｜`W114A:85-86,206-207`｜`W124A:60,215`｜`W116A:86`｜`W89A:198-199,319`｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2627-2628`）
⇒ **`$R` 里没有任何生产者**（`grep -rln 'AFTER_R2' $R --include=*.cs --include=*.sh --include=*.c` = **空**）。
`~/wc03` 命中 = `bin/leg.sh`（**副本**）＋ `logs/*.log`（**读数**）；`~/wc05` = **0 命中**。

⇒ **真正的生产点（权威拍位）** = `~/w89a/bin/hc-arm-inner.sh`
（sha16 **`ca7ef5d23ab5a032`**｜10948 B｜mtime 2026-09-22 11:41:03）。依据：`W124A` 报告 §2 自述"**只读复用、一个字节未改**"，且 `W105A`／`W124A` 的腿产物都落在 `~/w89a/run/<TAG>/` 下。

**逐处给拍位 ＋ 读什么 ＋ 什么时候读**（`file:line` 逐条核过）：

| 拍 | `hc-arm-inner.sh` 行 | 读什么 | 什么时候读 |
|---|---|---|---|
| `AFTER_M` | `:99-121` | client 几何(`:60` `geom()`)／`_NET_WM_STATE`(`:64` `st()`)／`mapstate`(`:65`) | `act "$M"`（`:99`）后 `sleep $WAIT_M`（默认 **4.5 s**，`:29`） |
| **`AFTER_R`** | **`:126-129`** | **只有** client 几何 ＋ state ＋ mapstate（`:127`） | `act "$R"` 后 **`sleep $WAIT_R`＝4.5 s**（`:126`） |
| **`AFTER_R_SETTLED`** | **`:135-149`** | 上面那些 **＋ `frame=`／`fgeom=`**（`:144` `xwininfo -id "$WID" -tree` 取父窗；`:140-143` 有"`-tree` 必需、否则 `-id ''` 退化成交互式选窗挂死"的血案注释） | 第一拍后**再** `sleep ${SETTLE:-4.5}`（`:135`） |
| `AFTER_R_LATE` | `:150-157` | 同上 | `SETTLE2 ≠ 0`（**默认 0 = 不采样**） |

**读数工具**：全部是 `xprop`／`xwininfo`（**每格一次 `fork`**），**没有任何 X 协议层／`xwrap.so` 成分**（该装置里 `LD_PRELOAD` 尚未接入）。

### 1.4 既有台账挖掘（**本件最重的证据，全部只读**）

```
$ python3 ~/w148a/logs/mine_obs2.py     # ~/w124a/obs_logs/*/xhints.log（25 Hz 变更台账，70 腿）
$ python3 ~/w148a/logs/mine_xobs.py     # ~/w134a/run/*/xobs.log（server 侧 µs 时间轴，39 腿）
```
（两个脚本都在 `~/w148a/logs/` 下，可复现；口径全部"现算、不手抄"。）

**输出 A —— 25 Hz 台账（`xhints`，`5a0526b3b421c6ee`）**：
```
== 台账 70 腿 ｜ 含还原动作(R)的腿 67 ｜ 其它 3
   还原腿：红(r_ok2=0) 32 ｜ 绿 35 ｜ 其它 0
== A. 红腿：WM 的 frame 曾回到过基准吗？
   frame 回到基准 = 27 / 32 红腿
   未回到基准 = 5 / 32 ['W124A-MINONLY-01','W124A-MINONLY-02','W124A-PCTL-01','W124A-PCTL-02','W124A-PCTL-03']
== B. 红腿：回到基准 → 又被推回 的间隔（秒）
   n=27  min=0.041  median=0.081  max=0.086
== C. 推回时 client 与 frame 是否同拍同形
   推回那拍 client == frame：27 ｜ 不等：0
== D. 全台账 'client != frame' 的瞬间（真·时序分离）总数 = 1   ← ⚠️ **这只是 `xhints` 一个台账**的 P1 计数，见紧随其后的更正
```
> ### 🔴 更正（主控复核发现；**本段由 W148A 于 2026-09-23 追加，上文一字未动**）
> 上面那行脚本输出**只是 `xhints`（25 Hz、70 腿）一个台账**的 P1 计数 = **1**；而紧接的结论句里我写了"**3 个**"＋"**全部落在最大化那一跳**" —— **两处都错**。
> **错因两条**：(a) **把两个不同谓词混计**：**P1 = `client != frame`**（真·frame/client 分离）、**P2 = `state` 含 `MAXIMIZED` 而 client 未到屏尺寸**（state vs 几何分离）—— 我把 P2 的 2 条与 P1 的 1 条相加成 "3"；
> 其中 `W134A-F1-M1R2-3` @8.055 **client == frame**，**根本不属于 P1**。
> (b) **按瞬时 `state` 分段** ⇒ 把 `W124A-M2R2b-20` @13.257 错分成"最大化那一跳"：该拍 `state` 仍是 `MAXIMIZED`（因为它**正处在还原过程中**），raw 行逐字 = `t=13.257 client=0xc00004 cgeo=1280x1024@+0+0 frame=0x200608 fgeo=800x600@+0+0 state=[MAXIMIZED_HORZ,MAXIMIZED_VERT,FOCUSED]`
> ⇒ **frame 已回基准、client 还没跟上 = 还原段**（**主控判断正确**）。
>
> **现算口径**（可复现脚本 `~/w148a/logs/mine_sep.py`，sha16 **`4baf262828d4e5e9`**；**按"谁先把几何变了"分方向，不按瞬时 state 分**）：
> - **P1 合计 62 条**，其中 **启动窗口 60 条**（`t≈0.8–1.1`、`frame=0x50d` = **WM 尚未 reparent 的陈旧父窗 ⇒ 伪读数，必须剔除**）
>   ⇒ **装置准备完成后的真·frame/client 分离瞬间 = 2 条**，且**两条分属不同段**：
>
>   | 瞬间 | 台账 | 形状（client / frame） | 段 | client 滞后 |
>   |---|---|---|---|---|
>   | `W124A-M2R2b-20` @**13.257** | `xhints`(25 Hz) | 1280x1024 / 800x600 | **还原段**（frame 先回基准） | 13.257 → 13.306 = **+49 ms** |
>   | `W134A-A1-OLD-12` @**8.026** | `xobs`(µs) | 800x600 / 1280x1024 | **最大化段**（frame 先最大化） | 8.026 → 8.033 = **+7 ms** |
> - **P2 另计 2 条**（`W134A-A1-OLD-12` @8.026 ＋ `W134A-F1-M1R2-3` @8.055）—— **不许与 P1 相加**。
>
> **对设计的影响（结论方向不变，论据反而更强）**：既有台账里"**frame 先动、client 后动**"**两个方向都观察到了**，
> 而且 **"还原"那一跳确实存在时序分离（frame 领先 client **49 ms**）** —— 这正是 `TASK-0110` 要抓的东西；
> 但它在**两个台账合计 109 腿里只出现 1 次**、且出现在**绿**腿 ⇒ **样本量不足以当承重判据**。
> ⇒ **承重仍是事件锚定的 `Δ_push`**（见 §3），并把 **`Δ_lead` = frame 回基准 → client 回基准** 增列为**旁证格**（不承重）。
⇒ **`RECON-R1`**：**27/27 真还原腿的 frame 都回到过基准**（另 5 腿是 `MINONLY`／`PCTL` 臂，**根本没做还原动作** ⇒ **口径陷阱，已剔除**，不许算进分母）。
⇒ **`RECON-R3`**：`Δ_push` = **41–86 ms**，median **81 ms**。
⇒ **`RECON-R4`（已按上表更正）**：**推回那一拍 27/27 `client == frame`**（推回是"客户区改尺寸、WM 跟着重算 frame"）；
真正的 frame/client **分离瞬间装置准备完成后只有 2 条**（上表），**不是 3 条、也不是"全在最大化那一跳"**。

**输出 B —— µs 时间轴（`xobs`，`fb3fe379eb943994`）**，修前臂单腿全文（`W134A-A1-OLD-1`）：
```
EVT  t=13.430   1280x1024    send_event=1
EVT  t=13.767   800x600      send_event=0     ← WM 真还原
EVT  t=13.767   800x600      send_event=1
SEG  t=13.767   800x600      fgeo=800x600     ← client 与 frame 同一刻都回到基准
EVT  t=13.852   1280x1024    send_event=0     ← +85 ms 被顶回
SEG  t=13.852   1280x1024    fgeo=1280x1024
```
修后臂同刻（`W134A-A1-NEW-1`）：
```
SEG  t=13.752   800x600      fgeo=800x600
EVT  t=13.759   800x600      send_event=0
EVT  t=13.759   800x600      send_event=1     ← 之后没有任何 1280x1024
```
⇒ 与 `WC03` 报的 `+85 ms`（FULL `4d279f76…`／去行口径 `1fa17dc1461a774f`，**本件现场两口径复算逐位相符**）**独立吻合**。

**输出 C —— 两条确定性红线（本件现场复算）**：

| 桥件 sha16 | `PROTO` 命中/腿 | `GEOWRITE-SUPPRESSED`/腿 | `r_ok` | 腿数 |
|---|---|---|---|---|
| `4e25e4b27d4d5ae1`（修后） | **0** | **≥1** | 1（绿） | **19** |
| `feef049e9d0e313a`（修前） | **1** | 0 | 0（红） | **16** |
| `feef049e9d0e313a`（修前） | **0** | 0 | 1（绿） | **1** ← **反例，如实报** |
| `292e9532d093fbd9`（中间态） | 1 | 0 | 0（红） | **3** |

⇒ `命中=1 ⟺ 红` 共 **19 腿，反例 0**。**修后方向是确定性的**（19/19）；**修前方向不是**（1/17 腿绿）。
⚠️ **命名陷阱**：`W134A-POL-OLD-1/2` 名字带 `OLD`，但 `BRIDGE=4e25e4b27d4d5ae1`（**修后件**）⇒ **一律按趟印的 `BRIDGE=` 分组，不许按腿名分组**（`D-G104` 家族）。

### 1.5 `RECON-R2`：分辨率血案（**"WM 没收回"是怎么被造出来的**）

```
$ cat ~/w105a/watch/W105A-C2-p09-old.watchlog
WATCH_DONE samples=132
$ grep -n 'sleep' ~/w105a/bin/hints-watch.sh
14:  sleep 0.15
25:  ... && break
26:  sleep 0.15
$ python3 - <<'PY'   # 解析 raw 轨迹（见本件 §1.4 的口径）
```
**红腿 `W105A-C2-p09-old`（`SHIM=33352e5797031999`、`BRIDGE=feef049e9d0e313a`）的 176 ms 观测器**：
```
132 样本 ｜ t 跨度 23.06 s ｜ 实测周期 176.0 ms
   t=   0.00  geo=800x600@+240+212 state=[_NET_WM_STATE_FOCUSED]
   t=   8.92  geo=1280x1024@+0+0   state=[MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED]
   t=  23.06  geo=0x0@+0+0         state=[_NET_WM_STATE]
   → 最大化之后出现 800x600 的样本数 = 0
```
同刻逐样本（跨过那一对事件的两格）：
```
t=  13.82  geo=1280x1024@+0+0  state=[MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED]
t=  13.99  geo=1280x1024@+0+0  state=[MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED]
t=  14.17  geo=1280x1024@+0+0  state=[FOCUSED]     ← 观测器看到的唯一形态："窗态掉了、几何没收回"
```
**同装置绿腿对照**（`W105A-C2-p09-new`，128 样本）：
```
   t=   0.00  geo=800x600@+240+212 state=[_NET_WM_STATE_FOCUSED]
   t=   8.22  geo=1280x1024@+0+0   state=[MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED]
   t=  13.40  geo=800x600@+240+212 state=[_NET_WM_STATE_FOCUSED]
   → 最大化之后出现 800x600 的样本数 = 52        ← 仪器有牙（C4 正对照）
```
⇒ **红腿那对事件（还原 + 推回）整体落在一个 176 ms 采样空档里** ⇒ 观测器**必然**得出"几何从未回来"。
⇒ 这正是 `W105A` §9.1 写下的那句 `t=14.17 … ← 最大化态掉了，几何没收回` 的**成因**。

### 1.6 `RECON-R5`：`_NET_FRAME_EXTENTS` 是恒真谓词

```
$ grep -ah 'extents=' ~/w124a/obs_logs/*/xhints.log | grep -o 'extents=[-0-9,]*' | sort | uniq -c
    233 extents=0,0,0,0
```
⇒ **233 个 `SEG` 行、取值去重后只有 1 个** ⇒ `TASK-0110` 要求的第 ③ 格在本装置上**不能判别任何东西**。
⚠️ **不能判定是"读器瞎"还是"属性本来就是 0"**：`~/w124a/bin/` 里**只有二进制** `xhints`（26032 B），
`grep -A22 'read_frame_extents' ~/w124a/bin/xhints.c` ⇒ **`没有那个文件或目录`** ⇒ 该格记 **`NOINFO`**。

### 1.7 `RECON-R7`：修法的正控（具名台账）

```
$ for d in W134A-A1-OLD-1 W134A-A1-NEW-1; do printf '%-22s %s\n' "$d" "$(grep -ac 'GEOWRITE-SUPPRESSED' ~/w134a/run/$d/mil.log)"; done
W134A-A1-OLD-1         0
W134A-A1-NEW-1         1
$ grep -a -m1 'GEOWRITE-SUPPRESSED' ~/w134a/run/W134A-A1-NEW-1/mil.log | cut -c1-120
NOTE [GEOWRITE-SUPPRESSED] HWND 0xc00004 接窗路径**不回写 X 几何**：MIL 侧 1280x1024（来源=WindowRect）≠ X 侧 800x600 ⇒ 以 X 为准渲染（几何归窗口主人 HwndWra…
```
⇒ 这条行是"**真的到达了被测分支**"的正控（修后 19/19 腿 ≥1、修前 17/17 腿 0）—— 本件把它写进 `C1` 的第二半。
⚠️ 依主控口径 (B)：**具名台账行会让"应用输出 0 字节"不再等于"应用没说话"** ⇒ 若同趟要数应用输出，**必须先剔掉具名台账行**。

### 1.8 装置件现场核对（sha 一律现算，不手抄）

```
$ for f in ~/wc03/bin/xwrap.so ~/wc03/bin/xobs ~/w124a/bin/xhints ~/w89a/bin/hc-arm-inner.sh \
           ~/wc03/bin/leg.sh ~/w134a/bin/leg.sh ~/w89a/app/wpfgfx_cor3.so \
           ~/w134a/app/wpfgfx_cor3.so ~/w89a/app/libwpfwin32.so ~/w134a/app/libwpfwin32.so; do
    printf '%s  %8s  %s  %s\n' "$(sha256sum "$f"|cut -c1-16)" "$(stat -c%s "$f")" "$(stat -c%y "$f"|cut -c1-19)" "$f"; done
b5c1c1dbc4c0f13d     76488  2026-09-23 14:22:20  /home/links-dev/wc03/bin/xwrap.so
fb3fe379eb943994     46424  2026-09-23 13:26:53  /home/links-dev/wc03/bin/xobs
5a0526b3b421c6ee     26032  2026-09-23 12:29:17  /home/links-dev/w124a/bin/xhints
ca7ef5d23ab5a032     10948  2026-09-22 11:41:03  /home/links-dev/w89a/bin/hc-arm-inner.sh
1147fad981f6a8d7      9271  2026-09-23 14:19:40  /home/links-dev/wc03/bin/leg.sh
324b7e5384495cef      8526  2026-09-23 17:17:04  /home/links-dev/w134a/bin/leg.sh
feef049e9d0e313a   5028208  2026-09-22 09:30:36  /home/links-dev/w89a/app/wpfgfx_cor3.so
4e25e4b27d4d5ae1   5028208  2026-09-23 17:39:12  /home/links-dev/w134a/app/wpfgfx_cor3.so
2a297d6fee8be389    327240  2026-09-22 20:16:37  /home/links-dev/w89a/app/libwpfwin32.so
a6365183fa6d26b9    327512  2026-09-23 12:25:58  /home/links-dev/w134a/app/libwpfwin32.so
```
⇒ **两臂桥件现场都在盘上、同尺寸（5028208 B）不同内容** ⇒ 确定性反极性**不需要重编**。
⇒ **装置有**：协议层（`xwrap.so`）＋ server 侧 µs 时间轴（`xobs`）＋ 25 Hz 变更台账（`xhints`）＋ 腿脚本骨架（`leg.sh`）**四件齐**，全部只读复用。

### 1.9 现场占用（卫生判据的依据）

```
$ ls /tmp/.X11-unix/
X0 X1 X97 X99
$ for p in $(ls /proc | grep -E '^[0-9]+$'); do c=$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null); case "$c" in *Xvfb*|*xfwm4*|*dotnet*) echo "$p ${c:0:90}";; esac; done
1293973 Xvfb :99 -screen 0 1280x1024x24
1306360 Xvfb :97 -screen 0 1280x1024x24
… dotnet …/MSBuild.dll …
2107138 dotnet /home/…/build/MilBridge/tests/FrameProbe/bin/Release/PresentationCore.Tests.dll --corpus
```
⇒ `:0`／`:1` 是**用户的**、`:97`／`:99` 是**别的车道的** ⇒ 本判据写死**只用 `:2xx`**；
⇒ **现在有别的车道在跑重活**（`FrameProbe --corpus` ＋ 一排 MSBuild）⇒ 本车道**不占槽**（已遵守）。

---

## §2 三个**必须记的更正／推翻**（本件对派单书与既有登记的修正）

| # | 原说法 | 现场读数 | 出处 |
|---|---|---|---|
| 1 | `TASK-0110`／`D-G98`：**"WM 没执行退出最大化的几何还原"** | **推翻**：27/27 真还原腿的 **frame 回到过基准**，41–86 ms 后才被顶回 | `RECON-R1`／`RECON-R3` |
| 2 | `TASK-0110` 要求"逐拍读 `_NET_FRAME_EXTENTS`" | **该格在本装置上是恒真谓词**（233/233 = `0,0,0,0`）⇒ 进判据 = **假牙** | `RECON-R5` |
| 3 | 派单书说"现行 **两拍** 不够" | **更准确**：第一拍**根本不读 frame**（缺一列）＋ 两拍落点错位 **~100×** ＋ 每格两次 `fork`（拍内不一致） | `~/w89a/bin/hc-arm-inner.sh:126-149` ＋ §1.3 |

**没有推翻的**（照旧成立）：`WC03` 的归因终局（桥 `+85 ms` 裸 `ConfigureWindow`）、`W134A` 的修法与 12/12→0/12 读数、`K3`（提示族被排除）、`D-G99`（红率不许当唯一判据）、`D-G94`（分母口径）。

---

## §3 三件交付物

| 件 | 内容 | sha16（现算） | 行数 |
|---|---|---|---|
| `~/w148a/criteria.md` | **判据先行**（`C1` 承重确定性／`C2` 中间拍事件锚／`C3` 四格在场／`C4` 装置有牙／`C5` 反极性／`C6` 分辨率自检；三态；趟数与功效先写；卫生；七条 `NOINFO`） | `39f49fc04392a6cc` | 165 |
| `~/w148a/beat-design.md` | **承重交付**：现行两拍逐处 `file:line`＋读什么＋何时读；错位 100× 的量化；`t0…t4` 五拍（`B2`／`B3` 为新增**事件锚**）；"谁能看见"六候选逐条可判读数；装置清单与复用判决；具体接线；成本 | `9095a47a4dc56dd0` | 185 |
| `~/w148a/report.md` | 本件 | 见 §5 | — |

**中间拍设计一句话**：`B2 = 首次 ConfigureNotify(send_event=0) 且几何==基准`（`B_link`）→ `B3 = 之后首次同型事件且几何==屏尺寸`（`Δ_push = t3−t2`，判红界 **200 ms**，先写死）。
**"frame/client 时序分离"的正确判法** = 判**时刻**（`B_link` 与 `Δ_push`），**不判"某一拍 frame ≠ client"** —— 因为还原那一跳的值**在 27/27 腿里都同时改**（`RECON-R4`）。

---

## §4 我没做到的（逐条 `NOINFO`，不许当绿）

1. **一条应用腿都没跑** —— `$R` 冻前硬闸未开（现场 `gen=#55` ≠ `#56`）＋ 派单书禁止跑重活（另有车道在冻前链上、在槽里）。⇒ 中间拍的**实际接线与实测留给落地车道**。
2. **`xobs`／`xwrap` 外部仪器是否扰动装置**：`W134A` 41 腿已这么跑过、未见异常，但**本件没有独立做"有仪器 vs 无仪器"的成对对照** ⇒ `NOINFO`。
3. **`_NET_FRAME_EXTENTS` 读器是否瞎**：`xhints` 源码不在盘上（只有二进制）⇒ `NOINFO`。
4. **第二套 WM 的对照**（"换 WM 是否同形"）：本装置是单 WM 会话 ⇒ 判不了。
5. **WM 侧内部状态**（`xfwm4` 的 `maximized` 标志）：**无只读仪器** ⇒ 该候选只能反推，**不能**当承重。
6. **25 Hz 台账下的 frame/client 先后**：分辨率不够（`T=40 ms` > 驻留/4）⇒ `NOINFO`，**不硬下结论**。
7. **源级反极性**：本车道**不写 `$R`** ⇒ 不做（件级反极性已由现成两件支持）。
8. **`~/.X11` 相关**：无。

**自伤／存疑（如实记）**：
- 本件第一版挖掘脚本 `mine_obs.py` 的 `frame_back` **取错了索引**（取"第一个等于基准的 SEG"，而它本来就是基准 ⇒ 恒 = 0），并**把 `MINONLY`／`PCTL` 臂当成了红腿**（那 5 腿**根本没做还原动作**）⇒ **已用 `mine_obs2.py` 纠正并分臂**；**纠正前后结论方向不变**，但**分母从 32 变成了 27**（这一步正是 `D-G94` 家族的口径陷阱，本件自己踩了一次）。
- 本件一开始把 `W134A-POL-OLD-*` 按腿名当成了"修前件"，**被 `BRIDGE=` 字段当场打脸** ⇒ 已改为按 sha 分组。
- 23:2x 的 `timeout 120 grep -rln 'AFTER_R2' $HOME` **超时被 SIGTERM 杀死**（`$HOME` 过大）⇒ **该次搜索无结果、已作废**，改用逐个车道目录的定向 `grep` 重做（结果见 §1.3）。

---

## §5 读数表（纪律 32）

> ### 🔴 §5.0 `RECON-R4` 更正记录（**主控复核发现，2026-09-23 追加；本件其余部分一字未动**）
> **主控复核结论：核心判决接受，但两处子读数要更正 —— 主控两处都对，本件照改。**
> | # | 我原来写的 | **现算（改正）** | 错因 |
> |---|---|---|---|
> | ① | 全台账 `client != frame` **只有 3 个瞬间** | **装置准备完成后只有 2 条**（`xhints` 台账 1 条 ＋ `xobs` 台账 1 条；另有 **60 条启动窗口伪读数**必须剔除）—— 我自己的 v2 脚本现场打的本来也是 **`= 1`**（只管 `xhints` 一个台账），**是我在结论句里把它写成了 3** | **把 `P2` 谓词（`state` 含 `MAXIMIZED` 而 client 未到屏尺寸）与 `P1` 谓词（`client != frame`）相加** |
> | ② | 3 个"**全在"最大化"那一跳**" | **两条分属两段**：`W134A-A1-OLD-12` @8.026 = **最大化段**；`W124A-M2R2b-20` @13.257 = **还原段**（frame 先回基准、client 迟 **49 ms**） | **按瞬时 `state` 分段**：该拍 `state` 仍是 `MAXIMIZED`（因为它**正在还原过程中**）⇒ 分成"最大化段"是错的 |
> **更正依据（raw 行逐字，非推理）**：`~/w124a/obs_logs/W124A-M2R2b-20/xhints.log` =
> `t=13.257 client=0xc00004 cgeo=1280x1024@+0+0 frame=0x200608 fgeo=800x600@+0+0 state=[MAXIMIZED_HORZ,MAXIMIZED_VERT,FOCUSED]`，
> 下一拍 `t=13.306 cgeo=800x600 fgeo=800x600 state=[FOCUSED]` ⇒ **frame 先回基准、client 后跟 49 ms**。
> **可复现脚本**：`~/w148a/logs/mine_sep.py`（sha16 **`4baf262828d4e5e9`**；**P1／P2 永远分开打、段位按"谁先把几何变了"分**）。
> **判决与设计方向不变**：`TASK-0110` 标题前提**仍被推翻**（WM 收回了）；承重仍是事件锚定的 `Δ_push`；`Δ_lead` 只作旁证格。
> **该错必须在册**（不许缩小）：这是本件第三次口径失误（前两次 = `frame_back` 索引取错、把 `MINONLY`/`PCTL` 臂当红腿），三次都属 `D-G94`／`D-G104` 家族。

| 项 | 值 |
|---|---|
| 车道 | `W148A` |
| 时间戳 | 开工 `2026-09-23T15:14:53Z`（= 本地 23:14:53）／收工 ~23:4x 本地 |
| `loadavg` | `2.87 3.98 3.82`（开工） |
| `mem_available` | §1 未单独取（**未跑任何应用腿** ⇒ 无内存相关读数；现场有别的车道 `FrameProbe --corpus` 在跑） |
| `kernel` | 本件未单独取（沿用装置既有 `6.8.0-138-generic`，**标为引用而非自测**） |
| 冻前硬闸 | 开工 `gen=#55`／收工 `gen=#55`（**未开**）⇒ `R_touched=none` |
| 应用腿 | **0** ｜ 重活槽 **0** 次 ｜ `dotnet` **0** 次 |
| 挖掘的既有台账 | `~/w124a/obs_logs/*/xhints.log` **70 腿**｜`~/w134a/run/*/xobs.log` **39 腿**｜`~/w105a/watch/*.txt`（读数比较若干） |
| 交付件 sha16 | `criteria.md` **`39f49fc04392a6cc`**（181 行）｜`beat-design.md` **`9095a47a4dc56dd0`**（191 行）｜`report.md` 见**本件最后一行**（口径 = **去自身行**，见下） |
| **可审计清单（主控要求补）** | `~/w148a/legs.tsv` — sha16 **`a5e8baf89a4e77e6`**｜**68 行** = 表头 ＋ **27 真还原腿** ＋ **5 例外**（`W124A-MINONLY-01/02`、`W124A-PCTL-01/02/03`，`reason` 列 = "该臂无还原动作(口径陷阱,不入分母)"）＋ **35 绿对照**｜列 = `tag/verdict/r_ok/r_ok2/M/R/frame_back_to_base/push_dt_s/nseg/comp/label/reason`｜生成脚本 `~/w148a/logs/mine_obs2.py`（sha16 `1d32c147bfc46ed4`）｜口径 = 只读 `~/w124a/obs_logs/*/xhints.log` ＋ `~/w89a/run/<tag>/probe.txt` |
| **两臂桥件现场路径（主控要求补；`sha256sum` ＋ `stat -c%s` 现算）** | **修前 `feef049e9d0e313a`（5,028,208 B）** = `~/w89a/app/wpfgfx_cor3.so`（2026-09-22 09:30:36）／`~/w114a/app/`（同刻）／`~/wc03/app/`（同刻）／`~/wc11/app/`（2026-09-23 22:35:04）｜**修后 `4e25e4b27d4d5ae1`（5,028,208 B）** = `~/w134a/app/wpfgfx_cor3.so`（2026-09-23 17:39:12）｜**全盘普查**（`find ~ -name wpfgfx_cor3.so` 逐个现算）：修前件 **157 个副本、尺寸全部 = 5,028,208**（**单一尺寸值 ⇒ 无同名异构风险**）；修后件 **62 个副本、尺寸全部 = 5,028,208**。⚠️ 只有在 `~/w13xa|w14xa/gate-*` 里找会**看不到修前件**（它的副本主要分布在 `~/w89a`／`~/w114a`／`~/wc03`／`~/wc11` 及 `~/w76a`／`~/w95a`／`~/w126a`／`~/w133a` 的 `gate-*`）|
| 交付件 FULL sha256（第二个口径，`D-G104` 第三条） | `criteria.md` = `39f49fc04392a6cc1a29b2c945878ace4b912f6f3faef4e5c0ff202962a8a865`｜`beat-design.md` = `9095a47a4dc56dd0a0e966bc3cd3d0577466ff0e41808e4e987eff5180e41d07`（两者**现场现算、非自指**）｜`report.md` 的 FULL 值**属自指** ⇒ 记为 `NOINFO`（照 `WC02` 先例），其**去自身行**口径值在本件最后一行 |
| `report.md` 自身 sha16 的**口径** | 本件与工程惯例 `head -n -2` **不同**，理由：惯例的 `-2` 假设"倒数第二行才是自指行、最后一行是空行"；本件把自指行放在**最后一行** ⇒ 用 **`head -n -1 build/… | sha256sum | cut -c1-16`**（**去掉自指行本身**）⇒ **可复现、不循环**。复算命令：`head -n -1 ~/w148a/report.md | sha256sum | cut -c1-16` |
| `$R` 文件改动**归属**（如实记） | 本件**跑过零个 `dotnet`／零个构建命令**。但 `find $R -newermt '2026-09-23 23:14'` **不是空的**：命中 `samples/*/obj/Release/*.cache`（23:14:14–23:14:19）、`tests/artifacts/rendering/*.png`（23:14:26）、`tests/parity/linux/actual/*.png` 等 ⇒ 现场同时有**别的车道**在跑：「`MSBuild.dll` 服务器 PID 2103139/40/41（**23:14:05 起**）」＋「`timeout 180 dotnet PresentationCore.Tests.dll --case mod1 --tier lenient …`（**23:25:57**）」＋「`dotnet …/FrameProbe/bin/Release/PresentationCore.Tests.dll --corpus`（PID 2107138）」。⇒ 这些写入是**冻前验证链**的产物，**与本车道无关**；本车道的命令只有 `ls`／`grep`／`sed`／`awk`／`sha256sum`／`stat`／`find`／`python3`（全部读 `~/w1xx` 与 `~/wcx` 的日志），**没有任何一条会在 `$R` 落文件**。⚠️ 该格是**归属判断**（依据 = 命令清单 ＋ 进程观察），**不是**"我逐字节证明了我没写"。 |
| 🆕 **冻前闸在本轮末尾翻了（如实记，本件未据此行动）** | 开工时 `docs/CURRENT-STATE.md:9` = `gen=#55`；**本轮末尾复读 = `> BASELINE-FROZEN gen=#56 sha16=8edaf4f8c1e93eb0`**，`~/w21-verify/w56-record.txt`（mtime **23:22**）在位 ⇒ **闸已开**。**但主控明确指示"不要再跑任何应用腿或重活"** ⇒ 本件**未跑任何腿**，`gen=#56` 这条**只是观察**，**未据以行动**。⇒ 中间拍的落地现在**已具备前置**（`beat-design.md` §6 的第 1 条 `NOINFO` 可解除），但那是**落地车道**的事。 |
| ⚠️ **自伤第 4 条（如实记）** | 我用来数"有没有留着进程"的那条命令**把自己也匹配进去了**（命令行里含 `~/w148a`）⇒ 第一次打出 `1`（假阳性）。改用不匹配自身的写法后 = **0**。**这正是 `D-G103` 家族**（`pgrep -f`／`ps\|grep` 自匹配），也是 `TASK-0110` 那条 `D-G34` 的同族现场 —— **本件自己又踩了一次**，记在此处备查。 |

---

`W148A=DONE beats=5 site=/home/links-dev/w89a/bin/hc-arm-inner.sh:126-149 device=有(~/wc03/bin/xwrap.so b5c1c1dbc4c0f13d｜~/wc03/bin/xobs fb3fe379eb943994｜~/w124a/bin/xhints 5a0526b3b421c6ee｜~/w134a/bin/leg.sh 324b7e5384495cef) R_touched=none heavy=NO runs=0 reason=主控指示不跑(闸末尾已翻gen=#56但未据此行动) legs_tsv=~/w148a/legs.tsv:68行:a5e8baf89a4e77e6 prefix_bridge=~/w89a/app/wpfgfx_cor3.so:feef049e9d0e313a:5028208 corrected=2(sep计数/段位归属)`

`report.md` sha16（去自身行口径 `head -n -1`）= `91acdca014ce0a63`

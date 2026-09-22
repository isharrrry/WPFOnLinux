# W98A 报告 —— `TASK-0203`：把"静默 `rc=139`＋0 字节日志"的 95% 上界压到 **≤5%**

车道 **W98A** ｜ 任务：**长跑**（每臂 **60 趟**，两臂共 120 趟；**用户已拍板必须做**）
｜ 判据**先写死**：`$HOME/w98a/criteria.md`（sha16 见 §10；在第一条样本之前写成）
｜ 前序：W85A `build/MilBridge/W85A-report.md` `eb011130280cf295`（两臂配方、`D-G87`）
｜ W77A `build/MilBridge/W77A-report.md` `af9987e29f761e78` §10（自伤四处）｜ `docs/ROUTES.md` `TASK-0203` 各条
｜ 纪律：**只读产品**（仓内只写本报告一个文件）、不构建、逐趟单入槽、不许 `pkill -f`（一律数字 PID）、
私有显示 `:95`（无 WM）/`:96`（有 WM），**不碰** `:0/:1/:10/:97/:99`。

---

## 1 判据（**先写死、逐字**；原文 `$HOME/w98a/criteria.md`）

**本节是"读数之前"定下的规则，不是事后口径**（原文 sha16 见 §10；本节为节选，全量原文以该文件为准）。

### 1.1 一次样本 / 有效性（无效**不进分母**）
一次样本 = 一条**在机级槽内**（`~/heavy-slot.sh --min-avail 1500 --max-hold 180 --wait 1800`）、
`cwd=<私有 app 树>`、**仪器全关**（`HC_*`／`WPF_LINUX_*`／`WPF_WIN32_*` 全 unset）、
在私有显示上 `timeout 75 dotnet HandyControlDemo.dll`，并按**与 W85A 逐字相同**的 9 击坐标腿点击的命令。
**无效**当且仅当：`HEAVYSLOT=TIMEOUT`／`MAXHOLD_KILL`／`NOINFO reason=low-memory`；`rc=127`（`PATH` 无 `~/.dotnet`）；
45 s 内无窗口（`DEVICE=invalid:no-window`）；`oom=1`；**或五值（`SHIM/BRIDGE/PC/PF/WB`）漂移**。

### 1.2 命中"用户签名"（**四条合取，缺一不算**）
① `rc=139`；② `app.log+app.err` 字节 **= 0**；③ `Unhandled exception` 计数 **= 0**；④ `DIED_SIG` 含 `SIGSEGV`。
主判据腿用 `nogdb`（第④条不可得）⇒ 该腿另记**候选**（①②③三条），报告**单列候选数**并逐趟开日志核栈。
**"被处理掉、进程活到窗末"（`rc=124`）不算命中**；**"没崩" ≠ "修好了"**。

### 1.3 检测力闸门（W85A 仪器缺陷教训的硬要求）
逐趟记 `clicks_total`／`clicks_landed`（`AE>1000` 计落地）。
**"有检测力"** = `clicks_total ≥ 8` ∧ `clicks_landed ≥ ⌈0.8×clicks_total⌉`。
**点击不落地的趟不许算进分母**（W85A：有 WM 时修前臂点击从第 2 击起被吞 ⇒ 那一格 `0/15` 无检测力），单列并从该格分母剔除。

### 1.4 统计与上界（公式先写死）
目标 = 臂 A `0/60` ⇒ **95% 上界 = `1-0.05^(1/60) = 4.94% ≤ 5%`**（规则 of three `3/60 = 5.0%` 同量级）。
有命中的格用 **Clopper–Pearson 单侧 95% 上界**（`bin/ledger.py` 现算）。
**两极化**要求臂 B **≥1 命中**；臂 B 也 0/60 ⇒ 如实 `NOINFO`（无两极化）＋上界＋"再压到 ≤2%/≤1% 各需多少小时"。
**不许**把 `NOINFO` 写成绿或红。

### 1.5 阳性对照（**复现不出来 ⇒ 整套读数作废**）
`PC-B`（修前件＋无 WM＋9 击＋`TO=60`）：判据 = `rc=134` ∧ `Stack overflow.` ≥1
（⚠️ **不用日志体积当判别量**：`D-G87` 已证同一次真崩可只写 19 KB）。
`PC-A`（修后件同条件）：必须**不崩**。**复现判据 = `PC-B 2/2 崩` ∧ `PC-A 0/2 崩`**。

### 1.6 两腿（主次先写死）
- **腿 1（无 WM `:95`）＝ 主判据腿**，两臂各 **60 趟**。
- **腿 2（有 WM `:96`）＝ 对照腿**：先各 2 趟做"点击落地"标定；有检测力才各再加 4 趟（共 6 趟/臂），
  上界**单列**；**只有"有检测力"的趟才允许进合并分母**（合并用 `1-0.05^(1/N)`）。

---

## 2 装置（每项现场现算，不手抄）

### 2.1 显示（私有、自起、按 PID 收）
| 显示 | 内容 | WM 探针（`xprop -root _NET_SUPPORTING_WM_CHECK`） |
|---|---|---|
| `:95` | `Xvfb :95 -screen 0 1024x768x24 -nolisten tcp` | **`no such atom on any window`** ⇒ 无 WM（主判据腿） |
| `:96` | `Xvfb :96 -screen 0 1024x768x24` ＋ `xfwm4 --compositor=off` | `window id # 0x2000ae`（非空）⇒ 有 WM（对照腿） |

两者 `xdpyinfo` 均 `1024x768`。**未碰** `:0/:1/:10`（用户会话与 xrdp 的 xfwm4，PID 646945 属于别人）与 `:97/:99`（别的车道）。

### 2.2 仪器（私有只读复用副本；标记已统一，修掉 W77A 的结构性假）
| 件 | 来源 | 我改了什么 |
|---|---|---|
| `bin/one.sh` | W85A `96d4a52b06b37ecb` | ① `$HOME/w85a`→`$HOME/w98a`；② `W85A_APP`→`W98A_APP`；③ 标记统一 `W98A-*`；④ **删掉它往 `runs.tsv` 追 21 列旧格式那一行**（见 §6 装置缺陷 W98A-F2） |
| `bin/gdb.cmds.tmpl` | W85A `f5215b415891dad1` | 标记统一 `W98A-*`（含 `W98A-TERMINATED`／`W98A-END`，与 `one.sh` 的 `grep` **配对**） |
| `bin/classify.py` | W63A `347e05893a2b6a43` | **未改**（原样复用） |
| `bin/gate.sh`／`inner.sh`／`batch.sh`／`record.sh`／`waveprobe.py`／`selftest-gdb.sh` | **本车道新写** | 见 §2.3／§6 |

### 2.3 波链闸门（**本车道修掉的一处硬缺陷**）
W85A 的闸门用 `pgrep -af '[v]erify-all\.sh|…'` 判"波链在不在跑"。本车道实测（16:05–16:10）：
**别家自己的轮询器** `bash -c "for i in …; do pgrep -f 'bash verify-all.sh' …; done"` 的**整条命令行**里含该子串
⇒ 闸门**假死锁 300 s**，而当时波链早已 `HEAVYSLOT=RELEASED`（槽是空的）。
这正是 W77A §10.2 自伤过的同一族（**图案匹配打到自己的包装命令行**）。
⇒ 改用 `bin/waveprobe.py`：读 `/proc/*/cmdline`，**只认"真的把波链脚本当文件参数在跑"的进程**
（`argv[0]` basename ∈ 波链脚本名，或 shell 的**非 `-c`** 参数里出现该脚本名），**显式排除 `bash -c` 代码串**；
`gate.sh` 每次先跑它的**成对自检**（正例 3／负例 3，`WAVEPROBE-SELFTEST-ALL=PASS 6/6`），自检不过就拒绝启用并打 `NOINFO`。

### 2.4 闸门口径的一处**主动改动**（连同理由与代价，一并记账）
| 口径 | 处理 |
|---|---|
| 探测到"**波链正在跑**" | **保留**：等 60 s 重查（`waveprobe.py`；先跑成对自检 6/6） |
| "波链**刚结束**还要再静默 60 s" | **去掉**（W85A 版有这一条） |

理由三条：① 本批两臂树是**私有快照**（`$HOME/w98a/app-A`／`app-B`，94 件全文件清单差异恰好 1 件），
波链改的是**仓内权威件与 `hc-linux` 另一棵树**，**改不到我的树**；每趟 `result.env` 现场算五值并逐趟断言。
② 机器级"不许两个重活并跑"由 `heavy-slot.sh` 自己保证——**波链的重步也走同一个槽**，
所以"我的应用与波链的应用同时跑"在机制上已被排除，不需要我再加一层静默期。
③ 实测代价：旧口径下（16:05–16:53 共 48 min）本车道 130 趟**只走了 5 趟**（单趟平均等 840 s）⇒ 照那个口径跑完要几十小时。
⇒ **保留"波链进行中就等"、去掉"刚结束再静默 60 s"**；每趟等待时长逐趟写进 `logs/<tag>.gate.log` 的 `GATE=FREE waited=` 与 §5.2 台账。

### 2.5 记录层与并发：本车道四处自伤（**如实入册，不辩解**）
见 §7.2 的 `W98A-F1…F5`。其中 **F5 是本车道自己踩自己**：被挂死的旧链在我"按关键词收"时**没被收干净**
（`pkill`-style 匹配漏了 `bash bin/driver2.sh` 这种**相对路径**命令行），它继续推进到 `batch.sh B 1 16 …`，
与我新起的 `runall.sh` **并发抢同一个 `run/` 目录**（`heavy-slot` 保证不并跑**应用**，但两边会互相覆盖记录）。
处置：按**进程树**（读 `/proc/*/stat` 的 ppid 找根）收干净 ⇒ 现场 `LOCK-FREE`、我名下进程 0；
删掉 11 个**没有 `result.env` 的半截目录**；从零**回填重建** `runs.tsv`；新增 `bin/runall-guard.sh`（`flock` **单实例**守卫）。

---

## 3 两臂树：**先刷齐到当前权威树**，再只换一件（W85A 的未做项，本车道不许重犯）

### 3.1 树怎么造的（可复算）
1. `cp -a $HOME/w85a/app $HOME/w98a/app-A`（一份完整应用树；`cp -a` 不用硬链接，避免连带改源）。
2. 用**判据口径的唯一实现** `build/MilBridge/tools/sync-applocal.sh` 把**五件权威**同步进两棵树
   （`SYNC-APPLOCAL=PASS items=5 ok=1 synced=4`）：
   `libwpfwin32.so`／`wpfgfx_cor3.so`／`PresentationCore.dll`／`PresentationFramework.dll`／`WindowsBase.dll`。
   ⇒ **替掉了树里相对 `#49/#50` 陈旧的副本**（W85A 两臂树是陈旧 app-local，它自己如实记为未做项）。
3. `cp -a` 出第二棵树，把 `libwpfwin32.so` **只换这一件**为修前件（先 `rm` 再 `cp -p`，不用硬链接）：
   修前件 **`abf6879c027c5e73`**（W63A `D-G66` 修前件，取自 `$HOME/w85a/app-pre`，与 `$HOME/w77a-app-pre/` 同值）。
4. 两棵树里由同步器书写的簿记件 `.applocal-sync.tsv` **都已移出**（`$HOME/w98a/meta/`）——
   它是工具写的记录、不是应用件；留着会让"唯一变量"变成 2 件。

### 3.2 单变量验证（**全文件**清单比对，硬前置）
对两棵树做 `find . -type f -exec sha256sum {} +`（含子目录）并排序比对：
**差异件恰好 1 件**（`libwpfwin32.so`）；两棵树各 **94 个文件**。
差异清单（现场原样）见 `$HOME/w98a/tree-A.txt` 与 `tree-B.txt`；比对结论：
`diff tree-A.txt tree-B.txt` 输出 **2 行**（同一件的两侧），即 **1 件差异**。

### 3.3 两臂的件（现场 `sha256sum`）
| 件 | 臂 A（现场权威件） | 臂 B（修前件） |
|---|---|---|
| `libwpfwin32.so` | `33352e5797031999` | **`abf6879c027c5e73`** |
| `wpfgfx_cor3.so` | `feef049e9d0e313a` | 同左 |
| `PresentationCore.dll` | `722e0ab8205b7c3f` | 同左 |
| `PresentationFramework.dll` | `f34bc297d19778fd` | 同左 |
| `WindowsBase.dll` | `2e4e46e539a72cd7` | 同左 |
| 其余 89 件 | 同（见 `tree-A.txt`） | 同（见 `tree-B.txt`） |

### 3.4 两个 `.so` 的**导出差**（现场 `nm -D --defined-only`）
`post 543 T`／`pre 518 T` ⇒ **只在 post 有、pre 没有的导出 = 25 个**，反向 **0 个**：
`wpf_x11_apply_wm_state`／`wpf_x11_apply_wm_hints`／`wpf_x11_set_decorations`／`wpf_x11_client_size_limit`／
`wpf_x11_iconify`／`wpf_x11_moveresize_window`／`wpf_x11_pointer_grab`／`wpf_x11_workarea`／`wpf_x11_screen_size`／
`wpf_x11_has_ewmh_wm`／`wpf_core_window_state`／`wpf_core_custom_chrome`／`wpf_core_nc_hit_test`／`wpf_core_note_framechanged`／
`CreateDocContext`／`DestroyDocContext`／`CreateInstalledObjectsInfo`／`DestroyInstalledObjectsInfo`／
`GetFloaterHandlerInfo`／`GetTableObjHandlerInfo`／`WpfLinuxWin32_PtsGapCalls`／`WpfLinuxWin32_PtsGapCount`／
`WpfLinuxWin32_PtsGapEntryName`／`WpfLinuxWin32_PtsGapReport`／`WpfLinuxWin32_PtsGapSelfCheck`。
⇒ **判决力上限（先声明）**：判决点**最多**下到"这 25 项所在的改动集"，**不许**归因到单一函数（W85A 当时是 14 项，本批因 `#50` 落地 `A1`/`A2` 变成 25 项）。

### 3.5 快照与权威漂移的记账
本批两臂树是**私有快照**；测量期间别的车道（`W95A`：波 `#50` 收尾链）可能改权威件。
每趟 `result.env` 现场算 `SHIM/BRIDGE/PC/PF/WB` 五值，`record.sh` **逐趟断言**它们 ∈ {两臂期望值} 且 `BRIDGE/PC/PF/WB` 等于 §3.3 表值；
不符 ⇒ 该趟记 `void=5value-drift` 并从分母剔除。批前/批后各算一次权威现值作为记账（见 §6）。

---

## 4 仪器自检（**先做，否则 `0/N` 无意义**）

用本车道副本 `bin/gdb.cmds.tmpl`（标记 `W98A-*`，与 `one.sh` 的 `grep` 配对）打两个合成件
（`$HOME/w63a/segv/recur` = 原生深递归；`wild` = 原生野指针），同一份模板、同一个 `classify.py`：

| 合成件 | 期望 | 实测 |
|---|---|---|
| `recur` | 抓深栈、判 `stack_exhaust`、跑到底 | `bt` **100 帧**、`kind=stack_exhaust`、`period=2500`、**`COMMANDS-RAN-TO-END=yes`** |
| `wild` | 抓浅栈、判 `other_native`、跑到底 | `bt` **1 帧**、`kind=other_native`、**`COMMANDS-RAN-TO-END=yes`** |
| 两趟都 | **`APP_DIED` 通路必须亮**（这是 W77A 结构性恒假的那一列） | `APP_DIED_PATH=yes`（两趟都出现 `W98A-TERMINATED`）、`DIED_SIG: Program terminated with signal SIGSEGV, Segmentation fault` |

⇒ 仪器**有判别力**，且"致命 SIGSEGV 会被认出来"这条断言**本批已点亮** —— 这是后面所有 `0/N` 能被信任的前提。
（W77A 的 `grep 'W63A-TERMINATED'` 与它改名的模板不配对 ⇒ 它那两列**没有检测力**；W85A 修了 F1，本车道沿用并把标记改成 `W98A-*`。）

---

## 5 统计（全场现算：`bin/ledger.py`；判据口径见 §1 与 §2）

```
总行数 = 128

腿     臂      趟   有效   无检测力   作废   命中139   候选139   134族   124活     上界95%
-----------------------------------------------------------------------
:96   A      2    2      0    0       0       0      0      2    77.64%
:96   B      2    0      2    0       0       0      0      0         -
:95   A     62   62      0    0       0       0      0     62     4.72%
:95   B     62   62      0    0       0       1     61      0     4.72%

全库有检测力样本 N=126  命中139=0  候选139=1  95%上界=2.35%
作废分布: 无
有效样本 rc 分布: {'124': 64, '134': 61, '139': 1}
栈文本分布: {'-': 65, 'Stack overflow.': 61}

腿×臂 让路/耗时：
  :96 A: dead_at_s min=75 med=75 max=75
  :96 B: dead_at_s min=75 med=75 max=75
  :95 A: dead_at_s min=60 med=75 max=76
  :95 B: dead_at_s min=28 med=31 max=32
```

### 5.1 分组汇总与逐趟台账摘要

```
# 总行数 = 128（含表头故台账 128 行）

## 分组汇总
腿	臂	TO	趟	有效	无检测力	作废	命中139	候选139	134族	124活	其他rc	上界95%
:96	A	75	2	2	0	0	0	0	0	2	0	0.7764
:96	B	75	2	0	2	0	0	0	0	0	0	-
:95	A	75	60	60	0	0	0	0	0	60	0	0.0487
:95	B	75	60	60	0	0	0	1	59	0	1	0.0487
:95	A	60	2	2	0	0	0	0	0	2	0	0.7764
:95	B	60	2	2	0	0	0	0	2	0	0	0.7764

## 全库有检测力合计 N=126 命中139=0 上界95%=0.0235
## 作废分布: 无
## rc 直方图: {'124': 64, '134': 61, '139': 1}
## 栈文本直方图: {'-': 65, 'Stack overflow.': 61}
## detect_power 分布: {'yes': 126, 'no': 2}
## dead_at_s: min=28 p50=61 max=76
## clicks_landed 直方图: {7: 1, 8: 125}

## 紧凑台账（tag/臂/腿/rc/lb/unh/stackovf/app_died/died_sig/verdict/clicks/detect/hit139/cand139/dead_at/void）
tag	arm	disp	rc	lb	unh	stackovf	app_died	died_sig	verdict	clicks	last	killed	detect	hit139	cand139	dead_at	void
C2A1	A	:96	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
C2A2	A	:96	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
C2B1	B	:96	124	0	0	0	no	none	alive-window	1/8	nav3	-	no	no	no	75	-
C2B2	B	:96	124	0	0	0	no	none	alive-window	1/8	nav3	-	no	no	no	75	-
L1A001	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A002	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A003	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A004	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A005	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A006	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A007	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A008	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A009	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A010	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A011	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A012	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A013	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A014	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A015	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A016	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A017	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A018	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A019	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A020	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A021	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A022	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A023	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A024	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A025	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A026	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A027	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A028	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A029	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A030	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A031	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A032	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A033	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A034	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A035	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A036	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A037	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A038	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A039	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A040	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A041	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A042	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A043	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A044	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A045	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A046	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A047	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A048	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A049	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A050	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A051	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A052	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A053	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A054	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A055	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A056	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A057	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A058	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1A059	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	76	-
L1A060	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	75	-
L1B001	B	:95	134	6516065	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	32	-
L1B002	B	:95	134	6486559	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B003	B	:95	134	6477862	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B004	B	:95	134	19393	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B005	B	:95	134	6406738	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B006	B	:95	134	19393	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B007	B	:95	134	6443366	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B008	B	:95	134	6516837	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B009	B	:95	134	6483442	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B010	B	:95	134	6443938	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B011	B	:95	134	6448696	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B012	B	:95	134	6516079	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B013	B	:95	134	18325	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B014	B	:95	134	6514685	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B015	B	:95	134	6477346	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B016	B	:95	134	19332	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B017	B	:95	134	6478046	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	32	-
L1B018	B	:95	134	19121	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	32	-
L1B019	B	:95	134	19151	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B020	B	:95	134	18964	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B021	B	:95	134	6483020	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	32	-
L1B022	B	:95	134	6519978	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B023	B	:95	134	6478628	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B024	B	:95	139	43	0	0	no	none	crash-segv	7/9	popitem	nav2	yes	no	yes	28	-
L1B025	B	:95	134	6408690	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B026	B	:95	134	6443938	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B027	B	:95	134	6480249	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B028	B	:95	134	6487368	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B029	B	:95	134	6406337	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B030	B	:95	134	19151	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B031	B	:95	134	6478614	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B032	B	:95	134	6441661	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	32	-
L1B033	B	:95	134	6446480	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B034	B	:95	134	6479549	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B035	B	:95	134	6486052	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B036	B	:95	134	19363	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B037	B	:95	134	6479112	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B038	B	:95	134	6406413	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B039	B	:95	134	6517516	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	32	-
L1B040	B	:95	134	6516976	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	32	-
L1B041	B	:95	134	19151	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B042	B	:95	134	6449269	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B043	B	:95	134	6446819	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B044	B	:95	134	6479864	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B045	B	:95	134	6482402	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B046	B	:95	134	6480831	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B047	B	:95	134	6483592	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B048	B	:95	134	6478628	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B049	B	:95	134	19151	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B050	B	:95	134	6481752	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	32	-
L1B051	B	:95	134	6443366	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B052	B	:95	134	19151	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B053	B	:95	134	6514434	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B054	B	:95	134	6477346	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B055	B	:95	134	6478046	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B056	B	:95	134	6479525	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
L1B057	B	:95	134	6483442	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B058	B	:95	134	19393	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B059	B	:95	134	6514620	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
L1B060	B	:95	134	6516888	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	30	-
PCA1	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	60	-
PCA2	A	:95	124	242	0	0	no	none	alive-window	8/9	nav3	-	yes	no	no	61	-
PCB1	B	:95	134	6478046	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
PCB2	B	:95	134	19393	0	1	no	none	crash-abort	8/9	nav2	tab3	yes	no	no	31	-
```

### 5.1b 报告用表（`bin/tables.py` 现算）

```
### 表 A：各格命中与 95% 上界（分组按 腿/臂/观测窗）

| 腿 | 臂 | TO | 趟 | 有效(有检测力) | 无检测力 | 命中139 | 候选139 | 134族 | 124活 | 其他rc | 95%上界 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `:96` | A | 75 | 2 | 2 | 0 | 0 | 0 | 0 | 2 | 0 | 77.64% |
| `:96` | B | 75 | 2 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | - |
| `:95` | A | 75 | 60 | 60 | 0 | 0 | 0 | 0 | 60 | 0 | 4.87% |
| `:95` | B | 75 | 60 | 60 | 0 | 0 | 1 | 59 | 0 | 1 | 4.87% |
| `:95` | A | 60 | 2 | 2 | 0 | 0 | 0 | 0 | 2 | 0 | 77.64% |
| `:95` | B | 60 | 2 | 2 | 0 | 0 | 0 | 2 | 0 | 0 | 77.64% |

**全库（有检测力合计）N=126，命中139=0，候选139=1，95% 上界=2.35%**

### 表 B：rc 直方图 / 栈文本直方图（有效趟）

- rc：`{'124': 64, '134': 61, '139': 1}`
- 栈/日志首关键字（runs.tsv 的 `stack_line` 列）：`{'-': 65, 'Stack overflow.': 61}`
- 日志体积分桶：`{'<1k 字节': 65, '>=1M 字节': 47, '<1M 字节': 14}`
- 点击落地/总击数分布：`{'7/9': 1, '8/9': 125}`

### 表 C：无检测力 / 作废（不进分母）

| tag | 臂 | 腿 | rc | clicks 落地/总 | verdict |
|---|---|---|---|---|---|
| `C2B1` | B | `:96` | 124 | 1/8 | |
| `C2B2` | B | `:96` | 124 | 1/8 | |
```

### 5.2 槽与耗时台账

```
SLOT-LEDGER rows=128 total_waited=1020s total_held=6850s max_hold_seen=180s maxhold_kills=0 slot_timeouts=0 out=/home/links-dev/w98a/slot-ledger.tsv
```

### 5.3 槽台账逐趟（`~/w98a/slot-ledger.tsv`）

```
tag	gate_waited_s	slot_waited_s	held_s	maxhold	rc	verdict	memavail_before
C2A1	0		75	180	0	ok	2913
C2A2	0		75	180	0	ok	2940
…（共 128 行，全量见该文件）
```

---

## 6 结论（读数见 §5；本节只放判读，数字全部来自 §5 的现算表）

### 6.1 一句话
**把"静默 `rc=139`＋0 字节日志"的 95% 上界压到了目标：主判据腿（无 WM）两臂各 60 趟，臂 A `0/60`、臂 B 也 `0/60`（只出 1 次"候选"）**
⇒ **单臂上界 `4.87% ≤ 5%`（目标达成）、两臂合并 `2.47%`**。
**但"两极化"没拿到**：那唯一 1 次 `139`＋核心转储出现在**臂 B（修前件）**，臂 A 一次都没有 ——
**样本量只够说"方向对"，不够说"它就是修前件带的"** ⇒ 这一半如实记 **`NOINFO`**。

### 6.2 `139` 族：唯一一次命中候选（**本批最值钱的单点读数**）
| 项 | 读数 |
|---|---|
| tag | **`L1B024`**（臂 **B = 修前件 `abf6879c027c5e73`**、腿 1 无 WM `:95`、9 击腿、`TO=75`） |
| `rc` | **139**（SIGSEGV） |
| `app.log` | **43 B**，内容逐字 = `timeout: 被监视的命令已核心转储` ⇒ **是 GNU `timeout` 自己写的**，**应用一个字都没写** |
| 应用自己的字节数（`W98A-F7` 口径：剔掉 timeout 那一行） | **0** |
| `Unhandled exception` | **0** |
| 死在什么时候 | `DEAD_AT_S=28`、`ENTRY_N=7`：**7 击全部落地**（`nav1/nav9/ctrl_tb/type/nav10/ctrl_cb/popitem`），第 8 击 `nav2` 那一下**整进程死**（该击 `AE=480000` = 800×600 **满窗重绘**，`runner_alive=no`），后面 2 击被 `SKIP dead` |
| 与 W85A 那 61 趟 `134` 的关系 | 那些趟都是"托管爆栈"，**这一趟不是**：没有 `Stack overflow.`、日志 0 字节、裸 SIGSEGV |

**判读（不许读宽）**：
1. 这是本批 **126 趟有检测力样本里唯一一次** `139`；它**提供了直接证据**说明"静默 `139`"这个签名**在本机上活着**。
2. 它是"**139 ＋ 应用 0 字节**"，与用户那三份日志（`rc=139`、0 字节）**逐条对齐**（唯一差别：`timeout` 额外写了一行自己的通知）。
3. **它落在哪一臂**：只出现在**修前件**那一臂。但 **1 次**不能判定"两极化"（下界 0.08%），
   ⇒ W98A 的判决是：**方向与 `D-G66` 那条改动集一致，但本批样本量不足以归因**。
4. **不可归因到单一函数**：两 `.so` 差 **25 个导出**（§3.4）。

### 6.3 `134` 族：两极化**成立且极干净**（本批的确定性结论）
| 条件 | 臂 A（现场权威 `33352e5797031999`） | 臂 B（修前件 `abf6879c027c5e73`） |
|---|---|---|
| **腿 1（无 WM）9 击** | **0/60** 崩（60/60 `rc=124` 活满窗口） | **59/60** 崩：`rc=134`＋`Stack overflow.`（1 趟例外 = 上面那次 `139`） |
| **腿 1 阳性对照（`TO=60`）** | `PCA1/PCA2` **0/2** 崩 | `PCB1/PCB2` **2/2** 崩（6,478,046 B／**19,393 B**） |
| **腿 2（有 WM `:96`）** | 0/2 崩（2/2 活） | 0/2 —— **但这两趟无检测力**（见 6.4） |

- **崩溃那一击逐趟一致**：臂 B 全部崩在第 8 击 `tab3`（少数 `nav2`），`DEAD_AT_S` 集中在 **30–32 s**。
- **`Stack overflow.` 的两种输出形状本批又被独立复现**：61 趟崩里 **47 趟 ≥1 MB（全量形）、14 趟 ≈18–19 KB（折叠形）**
  ⇒ 复核了 W85A 登记的判据缺陷 **`D-G87`**：**日志体积不能当签名判别量**（本批折叠形占 **23%**，比 W85A 的 2/15 更高）。
- **结论**：**"点页签/点导航项"这条点击路径上的回声环（`D-G66`）确实被那组改动关掉了** ——
  本批是它的**第三次独立复现**，而且这次是在**刷新到当前权威树**（`#50`）的两臂上做的（W85A 的未做项，本批补上）。

### 6.4 两条腿的**互补失效**（本批对"验收必须有 WM"的又一次反证）
| | 无 WM `:95` | 有 WM `:96`（xfwm4） |
|---|---|---|
| **臂 A（修后件）** | 点击全落地（8/9）⇒ **活满窗口** | 点击全落地 ⇒ 活满窗口 |
| **臂 B（修前件）** | 点击全落地 ⇒ **59/60 崩（`134`）** | **点击被吞**：`C2B1/C2B2` 逐击 `AE` = `348243, 0, 0, 0, 0, 0, 0, 0` ⇒ **落地 1/8** |

⇒ **结论（机制级）**：**没有一条腿能在两臂上同时"有检测力"** ——
有 WM 时修前臂点击不落地（回声环走不到）⇒ 测不到 `134` 那一族；
而无 WM 时的读数又只覆盖"点击能落地"的世界。
**两条腿都要，而且要各自写明"这一格有没有检测力"**（`docs/WAVE49-PREREGISTRATION.md` §13.4-⑦ 的口径在本批得到第三次实测支持）。

### 6.5 判决点与代价
- **判决点（`134` 族，已拿到）**：两 `.so` 的改动集（25 个导出差）。
- **判决点（`139` 族，未达到）**：`NOINFO`；本批只给"**方向**＋**上界**"。
- **再压上界**：`≤2% ⇒ N ≥ 149/臂`、`≤1% ⇒ N ≥ 299/臂`；
  按本批实测 **75 s/趟**（含让路 1,020 s/128 趟）折算：**≤2% ≈ 3.1 h／臂、≤1% ≈ 6.2 h／臂**（单臂，不含让路）。
- ⚠️ **更该先做的不是加趟数，而是先把"触发条件"找对**：本批 1 次中的那 1 次是**趁 `134` 那一族崩溃时顺带出来的**，
  说明"`139` 与 `134` 同源、只是终止方式不同"这条假设**有直接支撑**；要把它坐实，应做
  **"在臂 B 上把点击密度/时长推到必崩点、并用 `gdb`/核心转储抓原生栈"**，而不是再平铺 300 趟。

---

## 7 我推翻 / 更正 / 没能做到什么（含对前序车道与本车道自己的更正）

### 7.1 对 W85A 的**用**与**不用**
- **照抄它验过的配方**：单变量 = `libwpfwin32.so`；**无 WM 腿才有检测力**（有 WM 时修前臂点击从第 2 击起被吞）；
  判别量用 **`rc` ＋ 首行/栈文本**，**不用日志体积**（它登记的 `D-G87`：同一次真崩可只写 19 KB 折叠栈）。
- **不照抄它的树**：它的两臂树是**陈旧 app-local**（它自己 §9.3 记为未做项）⇒ 本批先把五件权威刷进两臂树（§3.1）。

### 7.2 本车道自己抓到的两处**装置缺陷**（如实入册）
| 编号 | 症状 | 真因 | 修法 |
|---|---|---|---|
| **W98A-F1** | 闸门在**槽明明空着**时**假死锁 300 s**（16:05–16:10，`GATE=wait reason=wave waited=0/60/120/180/240s`） | `pgrep -af '…verify-all\.sh…'` 被**别家自己的轮询器** `bash -c "… pgrep -f 'bash verify-all.sh' …"` 的整条命令行匹配上（W77A §10.2 同族） | 换 `waveprobe.py`（只认真在跑波链的进程，排除 `bash -c` 代码串）＋**每次先跑成对自检 6/6** |
| **W98A-F2** | `runs.tsv` **每行被劈成两行**（主行 388 B ＋ "1 个值 + 31 个制表符"的空壳 35 B） | W85A 的 `one.sh` 里**同样往 `runs.tsv` 追一行 21 列旧格式**，与本车道 `record.sh` 的 33 列格式**一行两格式**混写 | ① 删掉 `one.sh` 那一行（一行一格式）；② 见 W98A-F3 |
| **W98A-F3** | 修完 F2 后仍劈行；**逐趟**看都是同一种形状 | `record.sh` 的 `printf` **格式串 32 个 `%s`、参数 33 个** ⇒ `printf` **静默复用格式**：尾巴那一个参数被按"整份格式"再印一遍（实测最小复现：33 参数 ⇒ 2 行、末行 = 值 ＋ 31 个制表符） | 格式串补足 33 个 `%s`；并加**写盘硬断言**：末行字段数 ≠ 33 ⇒ 记 `RECORD-DEFECT=TSV-MALFORMED` 并 rc=5 |
| **W98A-F4** | （预防性）`timeout` 到点被外层收走时 `result.env` 可能没写完 ⇒ 一行"半截记录" | 载荷被 `timeout -k` 掐断、`one.sh` 后面的汇总段没跑到 | `record.sh` 加**有效前言**：`result.env` 缺失或无 `RC=` ⇒ 写一行**完整 33 列**的 `void:` 行（并判 `MAXHOLD_KILL`／`slot-timeout`／`low-memory`），**绝不留空洞** |

⚠️ 这四条里有三条（F2/F3/F4）**都是"记录层"的错**，不是产品、也不是装置主体：
本批的读数**全部可以从 `run/<tag>/result.env` 现算**（`record.sh` 就是干这个的），
所以修法之后**逐条回填**了已跑的 8 趟（回填后 `runs.tsv` 无畸形行，见 §5.2/§5.3 的现算表）。

### 7.3 没能做到的（如实，不许读宽）
1. **两臂之间不止一处改动**（本批 25 个导出差，`#50` 落地 `A1`/`A2` 后又多了 PTS 那一族）
   ⇒ 即使将来 `139` 两极化成立，也**不许**归因到单一函数/单一改动。
2. 本机显示（`Xvfb 1024×768±xfwm4`）与用户现场（`:10` xrdp＋xfwm4）**不同构** ⇒ 结论只对本装置成立。
3. `rc=124` 只说"窗内没死"，**不说**"没有该缺陷"；长跑只给**频率上界**。
4. （其余未见项，见 §6 结论里的"未做到"清单）

### 7.4 报告要求的九项，逐项落在哪一节（自查表）
| 任务书要求 | 落在 |
|---|---|
| ① 判据（先写、逐字） | §1（全文见 `$HOME/w98a/criteria.md`，sha16 `c2aeeceffae9757e`） |
| ② 两臂树差异件验证（恰好 1 件） | §3.2（全文件 94 件 vs 94 件，差异 1 件） |
| ③ 逐趟台账摘要（不贴全量） | §5.1（`bin/ledger.py` 现算）＋原始行在 `$HOME/w98a/runs.tsv`（128 行 / 33 列） |
| ④ 两臂命中计数与 95% 上界（含公式） | §5.1b 表 A ＋ §6.1／§6.5 |
| ⑤ 阳性对照读数 | §5.1b 表 A（`PCA*`／`PCB*` 两行）＋ §6.3 表 |
| ⑥ 两臂/两腿对比表（含"点击落地计数"） | §6.4 |
| ⑦ `134`/`139` 分族计数 | §5.1b 表 B（`rc` 直方图）＋ §6.2／§6.3 |
| ⑧ 每趟耗时与总槽时间台账（含让路等待） | §5.2／§5.3 ＋ §11.3 |
| ⑨ 作废/`NOINFO`/纪律偏离清单 | §5.1b 表 C ＋ §6.2／§6.5 ＋ §2.5／§7.2／§7.3 |

---

## 9 给用户看的大白话小结（≤8 行）

1. **目标是"把上界压到 ≤5%"，做到了**：主判据腿（无窗口管理器）两臂**各 60 趟**，臂 A（现行件）`0/60` ⇒ 上界 **4.87% ≤ 5%**；两臂合并 `2.47%`。
2. **但"静默死"没有 0 命中** —— 抓到了 **1 次**：`L1B024` 那一趟 `rc=139`（真正的核心转储），应用自己**一个字节都没写**（日志里那 43 B 是 `timeout` 自己写的"被监视的命令已核心转储"）。
3. **那 1 次落在"修前件"那一臂，现行件那一臂 60 趟一次都没有** ⇒ 方向跟"我们那组改动关掉了回声环"一致；**但 1 次撑不起"两极化"**，所以这一半我如实记 **`NOINFO`**（能说的只是"它确实存在"＋"现行件侧上界 4.87%"）。
4. **真正稳的结论还是那个"响亮的近亲"**：点页签那一击会让**修前件**带着 `Stack overflow.` 死 —— **59/60**；**现行件 0/60**。本批是第三次独立复现，而且这次两臂树**刷到了当前权威树**（上一趟车道没做这一步）。
5. **一个必须记住的验收教训（第三次实测支持）**：**有窗口管理器时，修前件的点击会被吞**（本批逐击 `AE` = `348243, 0,0,0,0,0,0,0`，只落地 1/8）⇒ 那一格**测不到**这一类缺陷；**没有窗口管理器时**才测得到。**两条腿都要，并各自标明"这一格有没有检测力"。**
6. **判据本身被抓出两个洞（都是我自己先踩的）**：① **"日志体积 ≥1 MB"不能当判别量** —— 同一种真崩，本批 61 趟里 **14 趟只写 18–19 KB**（占 23%）；② **"应用日志 0 字节"必须先把 `timeout` 自己写的那行剔掉**，否则会把一次真命中判成不命中。
7. **我没做到的**：`139` 只抓到 1 次、判不到"是不是修前件带的"；两 `.so` 差 **25 个导出**，**判不到具体哪一处改动**；**有 WM 那一格对修前件完全没有检测力**（所以那格 `0/2` 不算数）；本机显示（`Xvfb±xfwm4`）与用户现场（xrdp＋xfwm4）**不同构**。
8. **我给下一条车道的建议**：别急着平铺 300 趟（那是 6 小时）；**先做的应该是"在修前件上把点击密度/时长推到必崩点、用 gdb 或核心转储抓原生栈"**，把"`139` 与 `134` 同源"这条坐实。

---

## 11 本批**动了仓内哪些件**（应为 0）与收尾现场

### 11.1 仓内写入清单
**本车道在仓内只写入一个文件**：`build/MilBridge/W98A-report.md`。
- **未**改任何产品件（`src/**`、`build/shims/**`、`build/*.Linux/**` 的权威产物）；
- **未**改四个路由件、`defect-registry-declared.tsv`、`known-red.json`、任何世代位；
- **未构建**（无 `dotnet build`、无 `build-shim.sh`）；
- 全部私有工件在 `$HOME/w98a/**`（`bin/`、`logs/`、`run/`、两份私有 app 树 `app-A`／`app-B`）。

### 11.2 权威件快照 vs 批前/批后（记账；本批只读）
| 时刻 | `libwpfwin32.so` | `wpfgfx_cor3.so` | `PresentationCore.dll` | `PresentationFramework.dll` | `WindowsBase.dll` |
|---|---|---|---|---|---|
| 批前（16:03，`~/w98a/authority-snapshot-t0.txt`） | `33352e5797031999` | `feef049e9d0e313a` | `722e0ab8205b7c3f` | `f34bc297d19778fd` | `2e4e46e539a72cd7` |
| 批中（16:22、16:45 两次现算） | 同上 | 同上 | 同上 | 同上 | 同上 |
| **两臂树（私有快照，整批未变）** | A=`33352e5797031999`／B=`abf6879c027c5e73` | 同左 | 同左 | 同左 | 同左 |

⇒ 整批 **128 趟的五值（`SHIM/BRIDGE/PC/PF/WB`）逐趟现场算并断言**，**0 趟漂移**（`runs.tsv` 的 `void` 列全 `-`）。
（期间别的车道 `W95A` 完成了波 `#50` 收尾链与**重冻**，但**没有**改动本表这五件的值 ⇒ 两臂快照与当前权威件**同代**。）

### 11.3 内存与资源（纪律要求）
| 项 | 读数 |
|---|---|
| 逐趟 `MemAvailable`（进槽前） | 最小 **2751 MB**／中位 **2912 MB**／最大 **3133 MB** |
| 逐趟 `MemAvailable`（跑后） | 最小 **2743 MB**／中位 **2916 MB**／最大 **3095 MB** |
| 收工时 | `MemTotal 7923 MB`／`MemAvailable 2919 MB` |
| `oom_kill` 增量（`/proc/vmstat`） | **0**（`oom=1` 的趟 **0**） |
| `MAXHOLD_KILL` | **0** |
| `HEAVYSLOT=TIMEOUT`／`NOINFO reason=low-memory` | **0 / 0** |
| `rc=127`（没跑） | **0** |
| 让路等待（gate 自等波链） | 合计 **1020 s** |
| 槽持有合计 | **6850 s**（128 趟） |
| 每趟时长（`DEAD_AT_S`） | min **28 s**／中位 **75 s**／max **76 s** |
| 壁钟 | 首趟 `L1A001` `16:10:55` → 末趟 `C2B2` `18:57:24` ⇒ 全程 **2 h 46 min**（128 趟） |
| 槽内占比 | 持有合计 6850 s ／ 壁钟 9991 s = **68.6%**；其余 3141 s = 让路 1020 s ＋ 闸门/记录开销 |
| 全程 `pkill -f` | **0 次**（一律数字 PID；收自己时按**进程树**读 ppid 找根再按 PID 收） |
| 收尾残留 | 收工前按 PID 收 `Xvfb :95`／`Xvfb :96`／`xfwm4 :96`（见 §11.4） |

### 11.4 私有显示与收尾
`:95`＝`Xvfb`（无 WM）、`:96`＝`Xvfb`＋`xfwm4 --compositor=off`（有 WM），全程**未碰** `:0/:1/:10`（用户会话与别人的 xfwm4）与 `:97/:99`（别的车道）。
收尾按 PID 收自己的三个进程，现场 `Xvfb`/`xfwm4` 残留 = 0（见 `~/w98a/STATUS.md` 末行）。

---

## 8 复算命令（照抄即可复现；全部现算，不手抄）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"

# 0) 判据与世代位
sha256sum $HOME/w98a/criteria.md | cut -c1-16
bash $R/build/MilBridge/tools/sync-applocal.sh --list        # 五件权威现值（批前/批后各一次）
for a in A B; do for n in libwpfwin32.so wpfgfx_cor3.so PresentationCore.dll PresentationFramework.dll WindowsBase.dll; do
  printf "%s %s %s\n" "$a" "$n" "$(sha256sum $HOME/w98a/app-$a/$n | cut -c1-16)"; done; done

# 1) 单变量验证（必须恰好 1 件差异）
( cd $HOME/w98a/app-A && find . -type f -exec sha256sum {} + | sed 's| \./| |' | sort -k2 ) > /tmp/A.txt
( cd $HOME/w98a/app-B && find . -type f -exec sha256sum {} + | sed 's| \./| |' | sort -k2 ) > /tmp/B.txt
diff /tmp/A.txt /tmp/B.txt                       # 期望：只有 libwpfwin32.so 一行两侧

# 2) 导出差（判决力上限）
nm -D --defined-only $HOME/w98a/app-A/libwpfwin32.so | awk '$2=="T"{print $3}' | sort -u > /tmp/A.exp
nm -D --defined-only $HOME/w98a/app-B/libwpfwin32.so | awk '$2=="T"{print $3}' | sort -u > /tmp/B.exp
comm -13 /tmp/B.exp /tmp/A.exp | wc -l           # 期望 25

# 3) 仪器自检
bash $HOME/w98a/bin/selftest-gdb.sh

# 4) 波链探测器自检（成对极性 6/6）
python3 - <<'PY'
import importlib.util, os
spec=importlib.util.spec_from_file_location("wp", os.path.expanduser("~/w98a/bin/waveprobe.py"))
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
cases=[(["bash","-c","pgrep -f 'bash verify-all.sh'"],False),(["bash","verify-all.sh"],True),
       (["timeout","1450","bash","verify-all.sh"],True),(["pgrep","-af","[v]erify-all.sh"],False)]
print("PASS %d/4" % sum(1 for av,e in cases if m.is_wave(av)==e))
PY

# 5) 一趟样本（槽 + 波链闸门；例：臂 A、腿 1 无 WM、TO=75）
bash $HOME/w98a/bin/gate.sh 160 180 $HOME/w98a/bin/inner.sh L1A060 $HOME/w98a/app-A nogdb click 75 :95

# 6) 统计（全现场现算）
python3 $HOME/w98a/bin/ledger.py        # 分组汇总 + 逐趟台账摘要
python3 $HOME/w98a/bin/summary.py       # 另一份口径（含 95% 上界与 Clopper–Pearson）
bash $HOME/w98a/bin/slotledger.sh       # 槽与耗时台账

# 7) 断点续跑（挂死时接力用）
bash $HOME/w98a/bin/batch.sh A 1 17 9 75        # 臂 A、腿 1、seq 17..25
bash $HOME/w98a/bin/driver2.sh                  # 全序列（含阳性对照与腿 2）

# 8) 单趟判读
cat $HOME/w98a/run/L1A001/result.env            # RC/LOGBYTES/UNHANDLED/VERDICT/OOM/DEVICE/SHIM…
grep -a 'CLICK' $HOME/w98a/run/L1A001/clicks.txt # 逐击 AE（判"点击落没落地"）
grep -a 'GATE=\|HEAVYSLOT' $HOME/w98a/logs/L1A001.gate.log
grep -a 'RECORD-DEFECT' $HOME/w98a/logs/record-defects.log   # TSV 畸形断言的记录（应为空）
```

---

## 10 附：报告自身指纹

本报告由 `bin/build-report.sh` 现场装配（静态节在 `$HOME/w98a/report/*.md`）。
判据 sha16 = `c2aeeceffae9757e`（先于第一条样本写成）。

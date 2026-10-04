# W46I 报告 —— 对 W46G「`D-G54` 弹窗内容已出画」的**独立复验**（复算 ＋ 主动证伪）

- 车道：**W46I**（**复验车道**：不构建、不改仓、只跑应用＋读日志）
- 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
- 时间窗：2026-09-19 20:49 → 20:57（本机时钟）｜kernel `6.8.0-138-generic`｜`nproc=3`
- 复验对象：`build/MilBridge/W46G-report.md` 对 `D-G54`（hc 组合框下拉弹窗「内容零渲染」）的修复声称
- 被测件：`wpfgfx_cor3.so` **新桥 `e3ea092010734f44`（5,019,968 B）** vs **旧桥 `6fac9e722299a768`（5,000,192 B）**
- 装置：`$HOME/w46-popup-verify.sh`（W46D 的判据臂）＋ **我自己的私有 app 目录** ＋ **我自己的 display**（`:71/:73/:75/:79`，X 自起自收按 PID）

---

## §0 一句话结论（四条）

1. **独立复算支持 W46G 的核心声称**：弹窗**真的出画了**。三趟独立复跑（不同 display、不同墙钟）都得到
   `HWND 0x200008 已呈现 413x274（skia 指令 29 条）` **2 条**、下半区色数 **66→152**、`AUX_flat_block=no`、
   `ROOTDIAG target.Root=0x893 … 从根可达=57`；**同装置换回旧桥 ⇒ 弹窗矩形 = 1 色纯白、0 个非白像素** ⇒
   这是"修好了"，不是"读数看起来像修好了"。
2. **三趟的像素级读数逐位相同**（`pre`/`post` 全屏 `AE=0`；`66→152`、`12220`、`28302` 逐位相同）⇒
   该判据臂在本形态上**可复算、零抖动**。
3. **主动证伪三条全部做了**（§3）：① 纯色块 **P2 拦得住**（A/B 两形态都红），**但 P2 有盲区**：
   形态 C「窗口在、几何对、一像素不画」时 **P2 会 PASS**（靠 P3 的 `AE=0` 才抓住）⇒ 承重的是 **P2∧P3 这个合取**，
   单看 P2 会假绿；② 主窗**没被动过**（`pre` 帧旧桥 vs 新桥**全屏 AE=0**）；③ 弹窗**不是空窗口**：
   色数 206、非白像素 14.31%、**9 行列表**（1 行蓝底选中 ＋ 8 行文本，逐行非白像素 34→153 **每行恰 +17**），
   我把图看过了（§3.3 有文字描述）。
4. **一处必须点名的口径问题（对今天的树）**：W46G 写"单窗口回归与冻结基线**逐字段相同**，唯一差别是 `config` 里的 `bridge`"——
   **行为/读数 14 个字段确实逐字段相同**（我复算得到同样 6 行），但 `config=` 元组今天有 **4 位**不同
   （`pc` / `bridge` / `pf` / `win32shim`），不是 1 位。差异来源有日期证据：**另一条车道的集成波在我复验期间
   重建了 `PresentationCore`（20:50:22）与 `PresentationFramework`（20:51:29）**（§4.3）。
   ⇒ 收尾重冻时**四位都要重钉**，只钉 `bridge` 会让 `[7] BASELINE-SHA` 在冻结点红。

---

## §1 装置、件与被测件指纹（跑前/跑后**逐位未动**）

### 1.1 我自己建的私有 app 目录（**共享 hc 目录只读、零写入**）

| 目录 | `wpfgfx_cor3.so` | `libwpfwin32.so` | `libwpfwic.so` | `PresentationCore.dll` | `libSkiaSharp.so` |
|---|---|---|---|---|---|
| `$HOME/w46i-app`（新桥） | **`e3ea092010734f44`** / 5,019,968 B | `e700c383ec1ecdc8` / 299,040 | `56278c14b4ecd672` / 70,728 | `b1d3d5f33618a3d7` / 3,601,408 | `a02cd03f1ebcbb97` / 9,244,960 |
| `$HOME/w46i-app-old`（旧桥） | **`6fac9e722299a768`** / 5,000,192 B | 同上 | 同上 | 同上 | 同上 |

- 建法：`cp -a /home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0/. <私有目录>/`（113 MB／份）。
- **跑前 = 跑后逐位相同**（`sha256sum` 现场算过两次，§5.2 有记录；`w46-popup-verify.sh` 的 `AUX_fp_*` 也在**判据时刻**又记了一遍，三处一致）。
- 旧桥取自 `$HOME/w46g-backup/wpfgfx_cor3.so.pre46g`（= W46G 这一轮**替换掉的那一件**，即"修前件"；
  `$HOME/w46c-backup/wpfgfx_cor3.so.installed-before46` = `496951adff86a557` 更早，含 W46A 的 ConfigureNotify 修复之前的状态，本件不用它做对峙）。

### 1.2 桥产物与"源→件"身份

| 项 | 读数 |
|---|---|
| 发布件 `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` | **`e3ea092010734f44`** / 5,019,968 B / mtime 20:33:12 |
| `bridge-src-fp.txt` | `BRIDGE_SRC_FP=f10b4b297b2358e6 BRIDGE_SRC_N=78`、`PUBLISHED_AT=2026-09-19T20:48:55+08:00`、`BRIDGE_SO_SHA256=e3ea092010734f44…` |
| 现树重算 `bash build/bridge-src-fp.sh` | `f10b4b297b2358e6` ⇒ **同源**（我跑的门禁也自报 `WPTD_BRIDGE_SRC_STALE=no basis=pub=f10b4b297b2358e6 now=f10b4b297b2358e6 so_file_match=yes`） |
| 共享 hc 目录 `wpfgfx_cor3.so` | 我开工时**已是新桥** `e3ea092010734f44`（mtime **20:48:16**） |

> ⚠️ **W46G §6 那句"共享 hc 应用目录零触碰…`wpfgfx_cor3.so 6fac9e722299a768`（仍是旧件，我没动它）"已经过期**：
> 该报告 mtime 20:47，而共享目录的 `.so` 在 **20:48:16** 被刷新成新桥。
> 我**没有**依赖共享目录（全用私有副本），所以读数不受影响；但这条提醒：**共享目录是活的**，任何"件指纹"都必须现场取。

### 1.3 我的跑趟清单（全部私有 display，X 按 PID 自起自收）

| 趟 | 目录 | display | 桥 | 用途 |
|---|---|---|---|---|
| run1 | `$HOME/w46i-run1` | `:71` | 新 | 主复算（另开 `WPF_LINUX_MIL_TRACE=1` 以复现"stderr 预算"陷阱） |
| run2 | `$HOME/w46i-run2` | `:75` | 新 | 可复算性（第二趟） |
| run3 | `$HOME/w46i-run3` | `:79` | 新 | 留**完整 stdout ＋ 脚本自身 rc**（前两趟我用 `| tail` 截断过输出） |
| run-old | `$HOME/w46i-run-old` | `:73` | **旧** | 修前对峙（"先咬"） |

---

## §2 三条 grep 的独立复算（含**原文行**；每趟都列）

装置：`HC_DROP_OPEN_AT=25` 程序化打开下拉；`WPF_LINUX_MIL_LOG=<out>/mil.log`、`WPFGFX_ROOTDIAG=1`、
`WPF_LINUX_CMDLOG=1 WPF_LINUX_CMDLOG_ID=0x35`；导航到组合框页（`[HCIN] FORCE-OPEN tick=25 open=True overlayChk=True`）。
弹窗窗口（`$HOME/w46i-run1/tree.txt`）：
```
7:     0x200008 (has no name): ()  413x274+559+356  +559+356
11:     0x200004 "HandyControlDemo": ()  800x600+240+212  +240+212
CREATE_DIAG MAP xid=0x200008 atom=49159 style=0xffffffff86000000 ex=0x8080088 xywh=559,356,413x274 msgonly=0 mapped=0
```

### 2.1 ① 弹窗**当过一次呈现目标**：`grep -c 'HWND 0x200008 已呈现'` = **2**（三趟都是 2；旧桥 0）

| 趟 | 计数 | 原文行 |
|---|---|---|
| run1 | 2 | `4210:  ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200008 已呈现 1x1（skia 指令 0 条，未画种类 0）  累计帧数 = 19`<br>`4372:  ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200008 已呈现 413x274（skia 指令 29 条，未画种类 0）  累计帧数 = 23` |
| run2 | 2 | `3653: … 已呈现 1x1…累计帧数 = 18` ／ `3810: … 已呈现 413x274（skia 指令 29 条，未画种类 0）  累计帧数 = 22` |
| run3 | 2 | `3655: … 已呈现 1x1…累计帧数 = 19` ／ `3812: … 已呈现 413x274（skia 指令 29 条）  累计帧数 = 23` |
| **run-old（旧桥）** | **0** | （无此行；旧桥唯一一条免采样行是主窗：`38: … 通道 2 → HWND 0x200004 已呈现 800x600（skia 指令 0 条）  累计帧数 = 1`） |

- run2 的 `累计帧数 = 18 / 22` 与 W46G §2.1 报的 **18 / 22 逐字相同**（run1/run3 是 19/23 —— 采样时刻差一帧，不影响判据）。
- 首帧 `1x1（0 条）` → 稳态 `413x274（29 条）` 与 W46G §1.2-D3 的"1×1 陷阱＋随后自纠"**逐字复现**。

### 2.2 ② 主窗口**没有**按弹窗尺寸出帧：`grep -c 'HWND 0x200004 已呈现 413x274'` = **0**（三趟 ＋ 旧桥都是 0）

- 主窗全运行**唯一**的免采样行：`通道 2 → HWND 0x200004 已呈现 800x600（skia 指令 0 条，未画种类 0）  累计帧数 = 1`。
- **词序敏感口径**（派单书原口径）：`grep -c '已呈现.*0x200008'` = **0**（新桥 0、旧桥也 0）⇒ **W46G 的"勘误"被独立证实**：
  真实行形是 `通道 N → HWND 0x… 已呈现 WxH`，`已呈现` 在 HWND **之后**，所以 `已呈现.*0x200008` **恒 0**，不能当判据。

### 2.3 ③ `[CMD] 派发 id=0x35` = **2**；`[preflight] … id=0x35` = **2**；`被拒` = **0**

| 项 | 新桥（run1／run2／run3） | 旧桥（run-old） |
|---|---|---|
| `grep -c '派发 id=0x35' app.log` | **2**（三趟） | **2** |
| 原文（run1） | `37:[CMD] ch=2 派发 id=0x35 handle=0x00000003 len=12`<br>`617:[CMD] ch=2 派发 id=0x35 handle=0x00000894 len=12` | `12:… handle=0x00000003` ／ `152:… handle=0x00000894` |
| `grep -c 'preflight.*id=0x35' mil.log` | **2**（三趟） | **1** |
| 原文（run1） | `25:[preflight] 通道 2 待提交 #4: id=0x35 (MilCmdTargetSetRoot) len=12 handle=0x00000003 在资源表里=True`<br>`4193:[preflight] 通道 2 待提交 #4: id=0x35 (MilCmdTargetSetRoot) len=12 handle=0x00000894 在资源表里=True` | `32:[preflight] 通道 2 待提交 #4: id=0x35 (MilCmdTargetSetRoot) len=12 handle=0x00000003 在资源表里=True` |
| `[CMD] … 被拒` 行 | **0** | **0** |
| 末次通道普查 | `通道#2: committed=3623 notimpl=0 failed=0 short=0 pending=0 … 资源=2295 root=有 窗口目标=0x200008 [MilHwndTarget×2]`<br>`通道#3: committed=13 … failed=0 … 资源=4 root=无 [MilHwndTarget×2]` | `通道#2 … root=有`；`通道#3 … root=无` |
| `无根视觉` 行数 | **22** | **12** |

⇒ **两条命令、两个不同句柄（`0x3` / `0x894`），新桥两条都在预检里；旧桥只有主窗那条** ⇒ W46G 的"预检盲区已闭"**成立**。

> **我复现到的一处仪器陷阱（必须点名，读法不对就会得出相反结论）**
> run1 里我**同时**开了 `WPF_LINUX_MIL_TRACE=1`：同一趟的 `app.log`（stderr）里 `preflight … id=0x35` 只有 **1** 条，
> 而 `mil.log`（文件汇）里有 **2** 条。原因是 stderr 汇有**固定 400 行预算**（`src/WpfGfx.Linux/Interop/MilPresentation.cs:104`），
> 现场证据：`app.log:484: [mil] …诊断预算用尽（已打 400 条），后续不再输出。`，`[mil 400]` 落在启动期的 `[create]` 流里，
> 弹窗那条（`mil.log:4193`）**根本没进 stderr**。
> ⇒ 谁只读 stderr 台账，谁就会得出「弹窗那条 SetRoot 没进预检」——这正是 `W46C` 当年追了一整轮的那个假象。
> **判据必须读文件汇（`WPF_LINUX_MIL_LOG`），或把 stderr 预算调高。**

### 2.4 `WPFGFX_ROOTDIAG=1` 的"从根可达"原文

```
run1: 4368:ROOTDIAG 通道2 target.Root=0x893 快照子=0 活投影子=1 镜像visual=1020 从根可达=57 孤立=964 资源=2302
run2: 3806:ROOTDIAG 通道2 target.Root=0x893 快照子=0 活投影子=1 镜像visual=1020 从根可达=57 孤立=964 资源=2302
run3: 3808:ROOTDIAG 通道2 target.Root=0x893 快照子=0 活投影子=1 镜像visual=1020 从根可达=57 孤立=964 资源=2302
旧桥: 含 0x893 的 ROOTDIAG 行 = 0 条（旧桥全运行 22 条 ROOTDIAG，全是 target.Root=0x2）
```
⇒ W46G 报的 `target.Root=0x893 … 从根可达=57` **逐字复现**（新桥三趟；run1 里含 `target.Root=0x893` 的 ROOTDIAG 共 **10 条**，
其中 **9 条** `从根可达=57`、**1 条**（设根之后第一次）`从根可达=1`）。

> **附一条口径（我比 W46G 多取的读数）**：`从根可达=57` **不是设根那一刻**的读数。
> 同一趟里，弹窗 `SetRoot` 之后**第一次** ROOTDIAG 是
> `4207:ROOTDIAG 通道2 target.Root=0x893 快照子=0 活投影子=0 镜像visual=963 从根可达=1 孤立=963 资源=2192`
> —— **从根可达=1**（活投影子=0，即"根子树还没被投影"那一步）；`57` 是**本目标首次呈现之后**的稳态读数。
> 引"从根可达>1"当"这棵树有内容"的判据时，**必须与"何时采样"一起写**，否则同一趟日志里能同时找到 `=1` 和 `=57`。

---

## §3 主动证伪（W46G 没做、派单书要求我做的三条）

### 3.1 反面①：**纯色块**能不能骗过判据？—— `--analyze` 合成目录（**不改被测件**）

做法：把 run1 的 `pre.png/post.png/tree.txt/app.log` 复制到合成目录，只**在 post 帧的弹窗下半区贴一整块纯色**
（`-draw 'rectangle 559,380 971,629'`），然后 `HC_PV_APP_DIR=$HOME/w46i-app bash $HOME/w46-popup-verify.sh --analyze <合成目录> <out>`。

| 变体 | 做法 | P1 | **P2** | **P3** | P4 | `AUX_flat_block` | VERDICT |
|---|---|---|---|---|---|---|---|
| **A 黑块** | 下半区贴**纯黑**（与 pre 全不同） | PASS | **FAIL `colors_post=1`** | **PASS `AE=103250`** | PASS `119332` | `yes` | FAIL |
| **B 白块** | 下半区贴**纯白**（≈修前那种形态） | PASS | **FAIL `colors_post=1`** | FAIL `AE=3779` | FAIL `19861` | `yes` | FAIL |
| **C 空窗口** | `post.png` **原样 = `pre.png`**（窗口在、几何对、一像素不画） | PASS | **PASS `colors_post=66`** | FAIL `AE=0` | FAIL `0` | `no` | FAIL |

原文（A）：
```
P2=FAIL colors_pre=66 colors_post=1 (判据 post>1)
P3=PASS ae_lowerhalf=103250 (判据 >20000；修前实测 3779)
AUX_hist_post_lowerhalf_top3=103250: (0,0,0) #000000 gray(0);
AUX_flat_block=yes  （post 下半区 色数=1 且 entropy=0 ⇒ 整块纯色，与'内容零渲染/白块'一致）
```
**结论（两条，方向相反，都有读数）**：
1. **"P2 拦得住纯色块"成立** —— A/B 两种纯色块 P2 都判红（且 B 的 `AE=3779` 与登记口径**逐位相同**，等于把修前读数机械复现了一遍）。
2. **但 `P2` 不是万能的，承重的是 `P2∧P3` 这个合取**：形态 C 下 `post` 区域色数 = **66**（因为弹窗**一像素没画**时透出的是底下页面内容）
   ⇒ **`P2` 会 PASS**，把它判红的是 `P3` 的 `AE=0`。
   ⇒ **单看 P2 会把"根本没画、只是透出底下的页面"这种假绿放过**；反过来 **单看 P3 又会被 A 骗过**（`AE=103250 > 20000` PASS）。
   两条判据**各有盲区、缺一不可** —— 这一条我建议写进判据页的"反面判据"节。

### 3.2 反面②：**主窗有没有被动过**（旧桥 vs 新桥逐像素）

装置：同判据臂、同 shim/pc、**只换 `wpfgfx_cor3.so`**（新 `:71` / 旧 `:73`）。`compare -metric AE`：

| 裁剪 | `pre` 帧（下拉未开） | `post` 帧（下拉已开） |
|---|---|---|
| 主窗左侧 `300x600+240+212`（W46G 用的那一档） | **0** | **0** |
| 主窗整块 `800x600+240+212` | **0**（色数 442 = 442） | 17185（色数 368 → 418） |
| 弹窗矩形 `413x274+559+356` | **0**（色数 66 = 66） | **17185**（**色数 1 → 206**） |
| 全屏 `1280x1024` | **0**（色数 443 = 443） | **17185**（色数 369 → 419） |

- 旧→新 `post` 差异的 bbox = `396x255+567+356` ⇒ **完全落在弹窗矩形 `413x274+559+356` 之内**；
  且 `弹窗矩形 AE = 全屏 AE = 17185` ⇒ **差异一个像素都没落在弹窗之外**。
- 应用自身 `pre→post` 的变化（左条，弹窗之外）：**新桥 5891 / 旧桥 5891**（逐位相同）⇒ 那部分变化是应用自己的状态变化（下拉开关），**两桥一致**。
- 同桥跨趟：run1/run2/run3 的 `pre`、`post` 两两 **全屏 `AE=0`** ⇒ 装置零抖动、可复算。

⇒ **支持 W46G「主窗没被动过」**。
> **但要更正一处口径**：W46G 把"主窗区 `AE=0`"和"全屏 `AE=17185` 全部落在弹窗矩形内"并列写；
> 实测"主窗**整块** 800x600"在 `post` 帧是 **17185**（因为弹窗矩形**落在主窗区域之内**）。
> 写"主窗区 AE=0"**必须写清是哪一块裁剪**（左侧 `300x600` 不含弹窗），否则会被读成"主窗整块没变"。

### 3.3 反面③：「弹窗其实是空窗口，只是尺寸对」—— 机械读数 ＋ **肉眼**

**(a) 色数与直方图前三**（弹窗矩形整块 `413x274+559+356`）：

| 趟 | 色数 | entropy | 非白像素 | 直方图前三 |
|---|---|---|---|---|
| 新桥 run1 `post` | **206** | 0.142136 | **16,189 / 113,162 = 14.31%** | `95977 #FFFFFF` / `11196 #326CF3`（**蓝底选中条**）/ `883 #5E5E5E`（正文灰） |
| 新桥 run1 `pre`（对照） | 66 | 0.0473022 | 3,079 / 113,162 = 2.72% | `99471 #FFFFFF` / `2855 #E0E0E0` / `475 #FDFDFD` |
| **旧桥 run-old `post`** | **1** | **0** | **0 / 113,162 = 0.00%** | `113162 #FFFFFF`（**整块纯白**） |

**(b) 逐行结构（我写的机器判据，不靠肉眼）**：把弹窗矩形转灰度、逐行数"非白像素 > 2"的连续行段：
```
新桥 post：行段数 = 10
  段高: [1, 29, 10, 11, 11, 11, 11, 11, 11, 11]
  峰值: [392, 392, 34, 51, 68, 85, 102, 119, 136, 153]
旧桥 post：行段数 = 0（非白像素 0）
新桥 pre ：行段数 = 10，非白像素 3079（底下页面的表格线/文字透出来）
```
- 段 1（高 1）＝ 弹窗顶边；段 2（高 **29**、宽 **392**）＝ **蓝底选中条**（`#326CF3` 的 bbox 实测 `392x29+10+3`，几乎满宽 ⇒ 选中项**整行**高亮）；
- 段 3…10 ＝ **8 条文本行**（各高 11、行距 29），峰值 **34, 51, 68, 85, 102, 119, 136, 153** —— **每行恰好 +17 个非白像素**，
  这正对应"每行比上一行多一个 `正文`"（一个汉字宽 17 px）⇒ **行内容确实各不相同**，不是同一行重复刷 8 次。

**(c) 我看到的画面**（`$HOME/w46i-run1/pop_full.2x.png`，826x548，2× 放大；**我看过了**）：
第 1 行是 **蓝底白字**的 `正文1`（整行蓝色高亮条，左端有圆角）；
其下 **8 行黑字**，依次为 `正文正文2`、`正文正文正文3`、`正文正文正文正文4`、…、
`正文正文正文正文正文正文正文正文正文9`（**每行"正文"个数递增，行尾数字 2→9 递增**），每行下方一条浅灰分隔线；
整体白底、有边框 —— 一幅**完整的 9 项下拉列表**。

⇒ **弹窗不是空窗口、不是纯色块、不是尺寸对而无内容**。W46G 说"8 项列表"是指**未选中的 8 项**，
合计**9 行**（含选中项 `正文1`）—— 我数到 9 行，与该表述一致，只是"项数"要连选中项一起算才不歧义。

### 3.4 （我额外加的第三条证伪）**修前状态在同装置下确实是红的**（"先咬后合"）

只换桥（其余件逐位相同），同判据臂：
```
旧桥 6fac9e722299a768：P1=PASS  P2=FAIL colors_pre=66 colors_post=1  P3=FAIL AE=3779  P4=FAIL 11630
                       AUX_flat_block=yes   AUX_hist_post=103250:(255,255,255)   VERDICT=FAIL
新桥 e3ea092010734f44：P1=PASS  P2=PASS colors_pre=66 colors_post=152 P3=FAIL AE=12220 P4=FAIL 28302
                       AUX_flat_block=no    AUX_hist_post=94690白/3120蓝/883灰     VERDICT=FAIL
```
⇒ **同一个读者在修前件上红、在修后件上绿（P2）**，且 `3779 / 11630` 与登记口径**逐位相同**。
这是"判据不是恒绿/恒红"的直接证据，比只看修后件的绿更强。

---

## §4 单窗口回归（`WpfTextDemo` 两档 × 3 rep）与冻结基线逐字段对照

### 4.1 我跑的命令与读数

```
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
WPTD_RUN_DIR=$HOME/w46i-wptd WPTD_DISPLAY=:77 WPTD_BASELINE_OUT=$HOME/w46i-wptd-rep/baseline.txt \
  timeout 1200 bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 45 --no-build
⇒ RUN_RC=0
   WPTD_SUMMARY=PASS tiers_passed=2/2
   WPTD_GATE=PASS acceptance=2/2 line_advance=PASS
   WPTD_BRIDGE_SRC_STALE=no basis=pub=f10b4b297b2358e6 now=f10b4b297b2358e6 so_file_match=yes
   INCONCLUSIVE 档（仪器抓不到帧）：无      脚本收尾：无孤儿
```
- `--no-build`：派单书禁构建，**我没有构建任何东西**；该开关只跳构建，仍会"装配运行目录"（把**权威产物**覆盖进 app-local），
  所以读数用的件是 `build/*.Linux/bin/Release/**` 的权威件（下表 `config=` 逐位记下）。
- 我跑出的 6 行 BASELINE 存在 `$HOME/w46i-wptd-rep/baseline.txt`（6 行 × 每行 23 字段）；判据臂原文件：`$HOME/w46i-run*/VERDICT.txt`。

### 4.2 逐字段对照（冻结 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:58-63`）

| 字段 | 冻结（`#44`，`:58-63`） | 我（20:52–20:53） | 相同？ |
|---|---|---|---|
| `tier`/`rep` | default 1/2/3 ＋ env 1/2/3 | 同 | ✅ |
| `config.pc` | `45e7e0a46f5912c0` | **`043eff4b1d8ecd7d`** | ❌ |
| `config.bridge` | `496951adff86a557` | **`e3ea092010734f44`** | ❌（**预期**：W46G 重发桥） |
| `config.pf` | `a93097f7a918597f` | **`366e9486536bc291`** | ❌ |
| `config.provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | ✅ |
| `config.win32shim` | `11f81eb9dfc60a12` | **`e700c383ec1ecdc8`** | ❌ |
| `config.wic_shim` | `56278c14b4ecd672` | `56278c14b4ecd672` | ✅ |
| `config.hbtextline_shim` | `e89fed55fd8e32bc(stale:no)` | `e89fed55fd8e32bc(stale:no)` | ✅ |
| `result` | `PASS` | `PASS` | ✅ |
| `exit` | `143` | `143` | ✅ |
| `drawn` | `260` / `144` | `260` / `144` | ✅ |
| `notdrawn` | `0` | `0` | ✅ |
| `frames_good/total/blank` | `14/14/0` | `14/14/0` | ✅ |
| `capture` | `ok` | `ok` | ✅ |
| `scroll` | `ok` | `ok` | ✅ |
| `shot_dims` | `938x938` | `938x938` | ✅ |
| `colors` | `3960` / `2828` | `3960` / `2828` | ✅ |
| `cross_ae` | `0` | `0` | ✅ |
| `max_concurrent_apps` | `1` | `1` | ✅ |
| `leftover_after` | `0` | `0` | ✅ |
| `rundir` | `/home/links-dev/w44-gate-e` | `/home/links-dev/w46i-wptd` | ❌（路径，本应不同） |

**结论**：**14 个行为/读数字段逐字段相同**（`result/exit/drawn/notdrawn/frames_*/capture/scroll/shot_dims/colors/cross_ae/max_concurrent/leftover`），
门禁自报 `tiers_passed=2/2`、`acceptance=2/2` ⇒ **本轮的桥改动没有把单窗口载体弄坏**。

**但 `config=` 元组有 4 位不同（pc / bridge / pf / win32shim），不是 W46G 写的 1 位（bridge）** ⇒
W46G §5.2 那句「与冻结基线**逐字段相同**（唯一差别是 `config` 里的 `bridge:…→…`，即本轮重发的桥）」**对今天的树不成立**。

### 4.3 那三位差异的来源（有日期证据，不是"猜"）

| 位 | 冻结 | 我跑到的权威件 | 权威件 mtime | 归因 |
|---|---|---|---|---|
| `bridge` | `496951adff86a557` | `e3ea092010734f44` | 20:33:12 | **W46G 本轮的修法**（预期位移） |
| `pc` | `45e7e0a46f5912c0` | `043eff4b1d8ecd7d` | **20:50:22** | **另一条车道的集成波在我复验期间重建了 `PresentationCore`** |
| `pf` | `a93097f7a918597f` | `366e9486536bc291` | **20:51:29** | 同一波重建 `PresentationFramework` |
| `win32shim` | `11f81eb9dfc60a12` | `e700c383ec1ecdc8` | 19:47:44 | 波内产品位移（E3 焦点回送那一族） |

- 旁证（不是我的动作）：`build/*.Linux/{SR.g.cs,PORT-CHANGES.md,*.csproj}` 的 mtime 集中在 **20:49:09–20:49:17**、
  `build/*/ARTIFACT-SRC-FP.txt` 在 **20:51:32**、`build/.wave-done` 在 **20:51:56**；我跑门禁是 **20:52:11** 之后；
  另有 `timeout 3600 bash build/MilBridge/run.sh tline`（PID 1575785）在 **20:55:28** 起跑（我读到时 etime 1 分 6 秒）。
- **我的读数有效性**：`PC`（20:50:22）与 `PF`（20:51:29）都**早于**我 20:52:11 开跑，且我跑完再取一次 sha**完全没变**（§5.2）
  ⇒ 我的 6 行读数是**同一个稳定件集**下取的，自洽有效。
- **W46G 那句话在它自己跑的时候（20:39–20:43）很可能是对的**（那时权威 `pc` 可能仍是 `45e7e0a4…`，20:50:22 才被重建）。
  我**无法回溯** 20:39 的权威 `pc` 值（没有留档），所以这条我只能说"**对今天的树不成立**"，不能说"W46G 当时报错了"。
  ⇒ 给收尾的**动作项**：重冻时 `pc/pf/win32shim/bridge` **四位一起重钉**；只钉 `bridge` 会让 `[7] BASELINE-SHA` 在冻结点红。

---

## §5 与 W46G 声称的逐条核对

| # | W46G 的声称 | 我的判定 | 依据 |
|---|---|---|---|
| 1 | 桥 `e3ea092010734f44` / 5,019,968 B；publish 与私有目录同 sha | **支持** | §1.2；两处逐位相同；源指纹同源（`BRIDGE_SRC_STALE=no`） |
| 2 | `grep -c 'HWND 0x200008 已呈现'` 0 → **2** | **支持** | §2.1（三趟各 2；旧桥 0） |
| 3 | 派单书口径 `已呈现.*0x200008` 词序敏感、恒 0 | **支持** | §2.2（新桥/旧桥都是 0） |
| 4 | `preflight id=0x35` 1 → **2**（`0x3` / `0x894`） | **支持** | §2.3（新桥 2、旧桥 1） |
| 5 | `ROOTDIAG 通道2 target.Root=0x893 … 从根可达=57` | **支持（附口径）** | §2.4；但"设根那一跳"是 `从根可达=1`，`57` 是呈现后稳态 |
| 6 | 判据 `P1=PASS` / `P2 66→152` / `P3 AE=12220 FAIL` / `P4 28302 FAIL` / `flat_block=no` | **支持（逐位相同）** | §3.4（三趟全同） |
| 7 | 截图肉眼见列表 | **支持** | §3.3（色数 206、非白 14.31%、9 行结构、我看了图） |
| 8 | 主窗没被动过（跨桥 `AE=0`） | **支持（口径需写清"哪块裁剪"）** | §3.2 |
| 9 | 单窗口回归与冻结基线**逐字段相同**，唯一差别 = `bridge` | **证伪（对今天的树）** | §4.2：行为字段 14 项相同，但 `config` 有 **4** 位不同；§4.3 给出归因与日期 |
| 10 | 共享 hc 目录仍是旧桥 `6fac9e722299a768` | **当时可能为真、现已过期** | §1.2：我开工时共享目录已是新桥（mtime 20:48:16 > 报告 20:47） |
| 11 | `P3` 阈值对本形态标定过高（口径问题，非产品问题） | **支持（并补强）** | 复现 `12220 < 20000`；且 §3.1-A 证明"纯色块也能 `AE=103250` 过关"⇒ `AE` 与"画没画内容"**不是单调关系**，`P3` 单独不可信 |
| 12 | 未改判定阈值、未改产品语义之外的东西 | **未复核**（超出本件：我只跑应用＋读日志，不做 diff 审计） | — |

---

## §6 件指纹（跑前／跑后）

```
$HOME/w46i-app（新桥，run1/run2/run3 共用）
  跑前 20:49:20 → 跑后 20:57：wpfgfx_cor3.so e3ea092010734f44/5019968、libwpfwin32.so e700c383ec1ecdc8、
    libwpfwic.so 56278c14b4ecd672、PresentationCore.dll b1d3d5f33618a3d7、libSkiaSharp.so a02cd03f1ebcbb97
  ⇒ 逐位未动（判据臂 `AUX_fp_*` 在判据时刻复记，三处一致）
$HOME/w46i-app-old（旧桥）
  跑前 = 跑后：wpfgfx_cor3.so 6fac9e722299a768/5000192（其余同上）
门禁权威件（20:52:11 记，20:56:42 复记）
  build/PresentationCore.Linux/bin/Release/PresentationCore.dll      043eff4b1d8ecd7d  mtime 20:50:22  （前后相同）
  build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll 366e9486536bc291 mtime 20:51:29 （前后相同）
  src/WpfGfx.Linux.Native/bin/libwpfwin32.so                        e700c383ec1ecdc8  mtime 19:47:44
  build/MilBridge/.artifacts/publish/.../wpfgfx_cor3.so             e3ea092010734f44  mtime 20:33:12
⇒ 我三个跑趟与门禁趟期间，**没有任何件被换掉** ⇒ 全部读数有效（没有触发派单书"读数作废"的那条）
```

---

## §7 我没做到 / 取不到的（`NOINFO`，逐条）

1. **`post` 帧是否"收敛帧"**：`w46-popup-verify.sh` 的 `settle_shot()` 把 `HC_PV SETTLE … stable_after=N` 打印到 stdout，
   但**调用点重定向到 `/dev/null`**（`:374`、`:385`）⇒ 该行被丢掉，读者**无法**从留档判断 `post.png` 是"两帧相同后采用"还是"6 轮未收敛取最后一张"。
   **补偿性证据（不是直接读数）**：三趟（不同 display、不同墙钟）`pre`/`post` 全屏两两 `AE=0` ⇒ 画面稳定、不是一闪而过。
2. **弹窗那条 `SetRoot` 走的是 `Commit()` 四条路径中的哪一条**（②`SameThreadPresent` / ③收尾 flush / ④`SyncFlush`）：
   本件只证明"预检下沉后**四条路径都覆盖**"（`preflight` 由 1 → 2），**没有**逐路径点名。
3. **弹窗目标 `WindowRect` 一度为 `1x1` 的上游归因**：只能看到桥侧读数（`候选 HwndTargetCreate=1x1 WindowRect=1x1 X11=413x274`），
   managed 侧为什么先给 1×1 未查。
4. **`FramesPresented +2 / PresentCalls +1` 的成对读数**：台账只在采样点与尺寸变化时打印，本件未抓到"同一次 Commit 里两个目标"的相邻帧号。
5. **诊断行流**（不是判据读数）**不可逐字节复算**：三趟 `mil.log` 行数 `4676 / 4047 / 4049`、`ROOTDIAG` `37 / 34 / 35`、
   run1 另有 `通道#` 普查 375 行（run2/run3 为 0，因 run1 开了 `MIL_TRACE`）。
   ⇒ **凡"数某类诊断行条数"当判据的读法都要先证明该行流可复算**；本件里**判据读数与像素**可复算，**行流**不可。
6. **W46G §4 的 `G1–G7` 逐条覆盖**（`CollectTargets` 排序、返回码口径、`_rootedTargets` 闸门等）：属**代码审计**，
   本件是运行态复验，**未复核**（`W46G` 报告里的 `文件:行` 我没打开逐条对照）。
7. **`P3` 阈值该改成什么**：本件只给"`AE` 与'画没画内容'非单调"的证据（§3.1）与"非白像素数 = 16189"这个候选读数，
   **不主张改口径**（判据页明令不许放宽阈值）。

---

## §8 纪律与零污染

- **未构建任何东西**：门禁用 `--no-build`；`run.sh build` 一次都没跑（另有车道在跑 `run.sh tline`，我**没碰**它）。
- **未跑** `integration-wave.sh` / `verify-all.sh` / 任何冻结或收尾脚本。
- **未改仓内任何文件**：本件**只新增** `build/MilBridge/W46I-report.md` 一个文件。
  （现场核查：`find $R -newermt '2026-09-19 20:48' -type f` 命中的**全是别的车道那趟集成波的产物**——
  `build/*.Linux/{SR.g.cs,*.csproj,PORT-CHANGES.md,ARTIFACT-SRC-FP.txt}`、`build/.wave-done`、
  `build/MilBridge/gen/t2d-family-baseline.txt`、`build/wave-audit.log`；**没有一件是我的**，我的产物全在 `$HOME/w46i-*` 下。）
- **未 `pkill -f`**、未用 `pgrep -x dotnet` 取别人的 PID；四个私有 display（`:71/:73/:75/:79`）与门禁的 `:77` 全部**按 PID 自起自收**。
  另：本机有一条**别的车道**遗留的 `Xvfb :97`（PID 68922，已跑 21 h）——**我一次都没碰**（我全程用私有显示号）。
- **共享 hc 应用目录只读**：`cp -a` 出 2 份私有副本再跑；共享目录的 `sha256sum` 前后未变（§6）。

---

## §9 给主控的三条动作项（不是结论，是"该做什么"）

1. **重冻时 `pc/pf/win32shim/bridge` 四位一起重钉**（§4.2/§4.3）——W46G 只点名了 `bridge`，今天的树已另有 3 位位移。
2. **判据页加一条反面形态**：`P2`（色数 >1）**挡不住**"弹窗一像素不画、透出底下页面"（合成变体 C 实测 `P2=PASS`）；
   承重的是 `P2∧P3`。同时 `P3`（`AE`）**挡不住**"纯色块"（变体 A 实测 `AE=103250` PASS）——两者互为补丁。
3. **`w46-popup-verify.sh` 的 `settle_shot` 收敛读数被 `>/dev/null` 丢弃**（`:374/:385`）⇒
   "post 是收敛帧还是未收敛兜底帧"在留档里**看不出来**；建议把该行改成同时写进 `VERDICT.txt`。

---

## §10 报告自身指纹

- 文件：`/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/W46I-report.md`
- 口径：指纹 = `head -n -2 <本文件> | sha256sum | cut -c1-16`（丢掉**末两行**＝下面的空行与指纹行，可当场复算）

- **sha16 = `9d4246598fbac9ef`**

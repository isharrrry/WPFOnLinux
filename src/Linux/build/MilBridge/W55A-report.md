# W55A 报告 —— `D-G66`（点击真落地之后崩）**驱动源＝产品**、**判定点＝`SetFocus` 无「已聚焦即空操作」短路**

> **一句话**：**驱动源定死了 —— 是产品缺陷，不是我们的仪器**。仪器**全关**（不设任何 `HC_*`／`WPF_LINUX_*`）的腿 A **3/3 全崩**，
> 而且**逐击 `AE` 与仪器全开的腿 C 逐位相同**（8 击里 7 击 `AE` 完全一致，第 8 击同点同崩）。
> **判定点**拿到了：崩溃是**一个闭合的托管递归环**，环上唯一的原生边就是**我们 shim 的 `SetFocus`**——
> `src/WpfGfx.Linux.Native/src/win32_core.c:953` 在 `old == hwnd`（**目标窗口已经持有焦点**）时**照样**同步派发
> `WM_SETFOCUS`；上游 WPF 在 `HwndKeyboardInputProvider.cs:114-124` 的注释里**逐字依赖**「已经拿到 Win32 焦点的窗口
> **不会**再收到一条 `WM_SETFOCUS`」这条 Win32 不变式 ⇒ 该短路缺失 ⇒ **环永远不终止**。
> 两条「不同签名」其实是**同一个环的两种终止方式**：运行时守卫页抓到 ⇒ 托管 `Stack overflow.` + `abort`（`rc=134`）；
> 守卫页自己没跑起来 ⇒ 裸 `SIGSEGV`（`rc=139`，**日志里什么异常都没有**）。
>
> **最小复现＝2 击**：先点**任一导航项**（换页），再点**页签 `TabItem`** ⇒ 必崩（`nav1+tab3` 2/2）。
> **只点页签不崩**（1 击 0/1、`tab3+tab1` 0/2、`tab1+tab3` 0/1）⇒ 前置条件是「**前面发生过一次换页的导航点击**」。
>
> **我推翻/修正了三句话**（详见 §3.4、§6）：(1) `D-G66` 登记里引的 `Panel.ClearChildren ← ItemContainerGenerator.OnRefresh ← CollectionView.Refresh`
> **不是**那个循环，它是 `Stack overflow.` 里**只出现一次**的外围入口路径；真正的循环是 `SetFocus` 回声环（原文见 §3.2）。
> (2) 任务书腿 B 与腿 C **构造上等价**（`GeoEvery()` 缺省就是 2）⇒ 我加了腿 B′ 才把「输入取证」与「`[GEO]`」分开。
> (3) `D-G65` 的签名**不是**并发两实例专有 —— 它在我这里**单实例、仪器全关**也发过（§5）。

`lane=W55A`｜2026-09-20 11:49→12:20（+0800）｜kernel `6.8.0-138-generic`｜`nproc=3`
`loadavg`（逐腿记于各腿 `marks.txt`）：起 0.36 → 矩阵期 0.48~1.21 → 收工 `0.41 0.80 0.90`
`MemAvailable`：开工 **2,562 MB** → 矩阵期最低 **2,655,560 kB ≈ 2,655 MB** → 收工 **2,828,860 kB**（全程 > 1,200 MB，无等待）
**收工自查**：`Xvfb`=0、`dotnet HandyControlDemo`=0，只剩用户自己的 `xfwm4`(1751373)；零 `pkill -f`（止损全部按 PID）。

---

## §0 环境、装置与件 sha16

### 0.1 装置

| 项 | 值 |
|---|---|
| 私有应用目录 | `$HOME/w55a/app`（`cp -a` 自 `/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，71 项 / 113 M） |
| **修前件**私有目录 | `$HOME/w55a/app-pre`（同上再 `cp -f` 换入 `$HOME/pre-DG64-libwpfwin32-abf6879c.so`） |
| 私有显示 | `:165`／`:166`／`:167`／`:168`／`:169`／`:170`——**全部自起自收（按 PID）**；**未碰** `:0`／`:1`／`:10` |
| X 服务器 | `Xvfb <disp> -screen 0 1280x1024x24`（每腿一台上新起的） |
| 窗口管理器 | **无**（本趟**全部**腿都是「无 WM」——点击能落地的那个环境） |
| 应用窗口真值几何 | `X=240 Y=212 WIDTH=800 HEIGHT=600`（每腿都用 `xdotool getwindowgeometry` 现场记；客户区 `768x576`） |
| 启动方式 | `env DISPLAY=… DOTNET_gcServer=0 [ENVS] timeout 300 dotnet HandyControlDemo.dll`（`cd $APP`） |
| 默认闪屏 | **保留**（不设 `HC_NO_SPLASH`）——所有腿一致 |

### 0.2 五件 sha16（现场算；四件全程＝冻结值）

| 件 | 实测 sha16 | 字节 | 期望 | 命中 |
|---|---|---|---|---|
| `libwpfwin32.so`（**修后**） | `867d96e7cb0cba36` | 299,120 | `867d96e7cb0cba36` | ✅ |
| `libwpfwin32.so`（**修前**，`$HOME/w55a/app-pre`） | `abf6879c027c5e73` | 299,040 | `abf6879c027c5e73` | ✅ |
| `wpfgfx_cor3.so` | `e3ea092010734f44` | 5,019,968 | `e3ea092010734f44` | ✅ |
| `PresentationCore.dll` | `9465f9dce39e2dfc` | 3,601,408 | `9465f9dce39e2dfc` | ✅ |
| `PresentationFramework.dll` | `1011da6390c3bf1e` | 6,119,424 | `1011da6390c3bf1e` | ✅ |
| `WindowsBase.dll` | `79740e9ba7fbf9ca` | 1,111,552 | `79740e9ba7fbf9ca` | ✅ |

### 0.3 我自己的仪器（全在 `$HOME/w55a/**`；sha16）

| 仪器 | sha16 | 作用 |
|---|---|---|
| `bin/leg.sh` | `96f477651ce30b3c` | 腿驱动（可 `W55A_STEPS` 覆盖步骤序列；逐击记命中链／`AE`／`alive`／`rc`） |
| `bin/probe.sh` | `61ba28d0081f432f` | 坐标探针（**已判为不可用**，见 §6.7） |
| `bin/geocal.py` | `27845890c4a64ecc` | 从 `[GEO]` 块里筛「落在窗口矩形内」的可点控件 |
| `bin/batch.sh` | `c4bf4eb2e2046437` | 腿矩阵（**严格串行**） |
| `bin/pair.sh` | `fe852c591c15eba8` | `D-G65` 成对（单实例／双实例） |
| 日志 | `$HOME/w55a/logs/`（**44 项** ＝ 40 个腿目录 + 5 个汇总日志；每腿含 `marks.txt`／`steps.txt`／`app.log`／`app.rc`） |

### 0.4 本报告自身 sha16

**口径 = 去掉文末最后一行**（那一行本身就是 sha 声明行 ⇒ 此口径**稳定可复算**）：

```bash
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
head -n -1 build/MilBridge/W55A-report.md | sha256sum | cut -c1-16
```

（下文命令里的 `$R` ＝ `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`。**声明值在文末最后一行。**）

---

## §1 复现（第几击、崩前事件行、签名、退出码）

### 1.1 复现的点击序列与坐标（**坐标由命中链自证**，见 §1.2）

窗口真值 `(240,212) 800x600`。导航 `ListBox#ListBoxDemo scr=268,378 wh=203x389 n=31`，项高 31 px；
`TabItem` 三个：`scr=258,305`（初始 `sel=True`）／`336,305`／`413,305`，各 `74x27`。

| 步 | 控件 | 绝对坐标 | 怎么来的 |
|---|---|---|---|
| S1 | 导航 `item[1]`（Button） | **(369,422)** | `[GEO] item[1] scr=268,409 wh=203x27` 的中心 |
| S2 | 导航 `item[9]`（TextBox 页） | **(369,670)** | `item[9] scr=268,657` 的中心 |
| S2a | 页内第 1 个 `TextBox` | **(809,340)** | `TextBox#- scr=619,327 wh=380x27` 的中心 |
| S3 | 导航 `item[10]`（ComboBox 页） | **(369,701)** | `item[10] scr=268,688` 的中心 |
| S3a | 页内第 1 个 `ComboBox` | **(809,340)** | `ComboBox#- scr=619,327 wh=380x27` 的中心 |
| S3b | 弹窗第 2 项 | 运行期算 | **X 真值**：新顶层窗口 `abs=(559,356) wh=413x274` ⇒ `(559+40, 356+274/9*3/2)=(599,401)` |
| S4 | 导航 `item[2]`（RepeatButton） | **(369,453)** | `item[2] scr=268,440` 的中心 |
| **S5a** | **`TabItem`#3（未选中）** | **(450,318)** | `TabItem scr=413,305 wh=74x27` 的中心 ← **触发点** |
| S6 | 导航 `item[3]`（ToggleButton） | **(369,484)** | `item[3] scr=268,471` 的中心 |

### 1.2 每一击都有命中链自证（这是「点击真的落地」的机器证）

仪器腿里 `leg.sh` 对每一击记 `[HCIN] preMouseDown src=<命中链>`，并与**预期控件类名**对判。
**三条仪器腿（`M-C1`／`M-Bp1`／`M-B1`）各 8/8 `HIT-OK`、0 `HIT-MISMATCH`**，`preMouseDown` 总数**都是 245**。
两条关键原文（`M-C1/marks.txt`）：

```
STEP S3a-open-Combo alive=yes AE=28302 XBTN=0 preMouseDown=29 GEO=1 nwin=8 HIT-OK(ComboBox)
  HIT src=Border(bg=#00FFFFFF) < ToggleBlock(bg=#00FFFFFF) < Grid(bg=-) < ComboBox(bg=#FFFFFFFF) < StackPanel(bg=-) < UniformSpacingPanel(bg=-) < ScrollContentPresenter#PART_ScrollContentPresenter(bg=-) …
STEP S5a-click-TabItem alive=no AE=480000 XBTN=0 preMouseDown=18 GEO=0 nwin=0 HIT-OK(TabItem)
  HIT src=TextBlock(bg=-) < ContentPresenter#contentPresenter(bg=-) < SimplePanel#templateRoot(bg=-) < TabItem(bg=#00FFFFFF) < UniformGrid#headerPanel(bg=#00FFFFFF) < Grid#templateRoot(bg=#00FFFFFF) < TabControl(bg=#00FFFFFF) < DockPanel(bg=-) < LeftMainContent#LeftMainContent(bg=#FFFFFFFF) …
```

`HIT-OK(ComboBox)` 那一击同时把下拉真开了：`nwin 7→8`、新顶层窗口 `0x200008 abs=(559,356) wh=413x274`、
`CB(- open=True sel=0/9 txt=正文1)`。**所以「点到了」不是推断。**

**另一条独立的正证（腿 A′，X 层，与 hc 仪器无关）**：`WPF_LINUX_KEY_DIAG=1` 让 **shim 自己**打出 8 条 `BTN type=Press`，
**一击一条**，`win=` 与**窗口相对** `xy=` 与我的意图**逐个精确对上**：

| 击 | 我的绝对坐标 | 期望相对 | shim 记下的 `win` / `xy` | 对上？ |
|---|---|---|---|---|
| 1 | (369,422) | (129,210) | `0x200004` / `129,210` | ✅ |
| 2 | (369,670) | (129,458) | `0x200004` / `129,458` | ✅ |
| 3 | (809,340) | (569,128) | `0x200004` / `569,128` | ✅ |
| 4 | (369,701) | (129,489) | `0x200004` / `129,489` | ✅ |
| 5 | (809,340) | (569,128) | `0x200004` / `569,128` | ✅ |
| 6 | (599,401)（**弹窗项**） | 弹窗 `0x200008`@(559,356) ⇒ (40,45) | **`0x200008` / `40,45`** | ✅ |
| 7 | (369,453) | (129,241) | `0x200004` / `129,241` | ✅ |
| 8 | (450,318) | (210,106) | `0x200004` / `210,106` | ✅ |

原文（第 6 击，逐字）：

```
[KEY_DIAG] BTN type=Press btn=1 win=0x200008 state=0x0 time=133783527 send=0 subwin=0x0 xy=40,45 same_screen=1
```

⇒ **8 击 8 条、win 与相对坐标零误差**。⚠️ **注意一处读数陷阱**：`marks.txt` 里**逐击**的 `XBTN=0` 是**假读数**——
shim 的 `wpf_key_diag` 写 **stderr** 且被缓冲，这些行是在进程崩掉时才整批刷进 `app.log` 的，
所以「按日志偏移量切段」的逐击统计看不见它们；**只有全日志口径的 `COUNTS XBTN=8` 才是真的**。

### 1.3 第几击崩：**第 8 击（`S5a-click-TabItem`）**，签名与退出码

- `preMouseDown` 总数 **245**（与 W54A 报告里 `L1/L2/L5` 的 **245 逐字相同** ⇒ 我的序列＝他们的序列）
- 崩前最后几条事件行（`M-C1`，`steps.txt` 的 `CRASH_TAIL` 原文）：最后一条 `[HCIN] mouseDown … < TabItem …`，
  之后 `app.log` **再无任何 hc 侧输出**；`nwin 7→0`（连窗口都没了）
- `AE=480000` —— **恰好等于窗口面积 800×600** ⇒ 整块窗口区域从「有内容」变成「没有窗口」
- **签名 ①（13/14 趟）**：托管 `Stack overflow.` + `rc=134`（`128+6=SIGABRT`，运行时 abort）
- **签名 ②（1/14 趟，`M-Bp3`）**：**静默**，`grep -c 'Stack overflow' = 0`、`grep -c 'Unhandled exception' = 0`，
  `app.log` 最后一行就是那条 `[HCIN] mouseDown … < TabItem`，`rc=139`（`128+11=SIGSEGV`）⇒ **裸 segfault**
- 两趟的**点击数、命中链、`preMouseDown`(=245)、`AE`(=480000)、崩溃步**全部相同 ⇒ **同一次崩溃的两种终止方式**

> `timeout` 的收尾语也确认了是信号死：`timeout: 被监视的命令已核心转储`。
> **注意**：本机 `ulimit -c = 0`、`core_pattern` 是 apport 管道 ⇒ **根本没有 core 文件落盘**。
> W54A 说的「core dump」是 `timeout` 对 `WCOREDUMP`／信号死的措辞，不是「拿到了 core」。

---

## §2 驱动源：**三腿成对表**（`仪器全关` vs `仪器开`）

### 2.1 我把腿拆开的原因（任务书的腿 B 与腿 C **构造上等价**）

`App.xaml.cs:472-477` 原文：

```csharp
private static int GeoEvery()
{
    var e = Environment.GetEnvironmentVariable("HC_GEO_EVERY");
    int v;
    return (!string.IsNullOrEmpty(e) && int.TryParse(e, out v) && v > 0) ? v : 2;   // ← 缺省 2
}
```

`DumpGeo()` 是在 `InstallInputDiag()` 的 1 Hz `DispatcherTimer` 里被无条件调用的（`App.xaml.cs:824-834`），
自己用 `if (++_geoCtr % GeoEvery() != 0) return;` 节流。
⇒ **只要 `HC_INPUT_DIAG=1`，`[GEO]` 就默认每 2 秒转储一次**：**任务书的腿 B「只有输入取证」是拿不到的**。
所以我加了 **腿 B′ ＝ `HC_INPUT_DIAG=1 HC_GEO_EVERY=100000`**（输入取证开、`[GEO]` 关）——**这一格才是真正的分离腿**。
`[GEO]` 不可能在没有 `HC_INPUT_DIAG` 的情况下单独打开（它的唯一调用点在 `InstallInputDiag` 的定时器里）。

各腿 env（**先 `unset` 掉所有继承来的 `HC_*`/`WPF_LINUX_*`**，并记 `hc_in_shell=0 wpf_in_shell=0` 自证）：

| 腿 | env |
|---|---|
| **A** | **（空）** —— 纯产品 |
| **A′** | `WPF_LINUX_KEY_DIAG=1`（**shim 侧**诊断，不是 hc 侧仪器；给腿 A 一点 X 层可观测性） |
| **B** | `HC_INPUT_DIAG=1 HC_DUMP_MAX=600`（**＝任务书腿 B**；⚠️ 同时开了 `[GEO]`@2） |
| **B′** | `HC_INPUT_DIAG=1 HC_GEO_EVERY=100000 HC_DUMP_MAX=600`（输入取证开、`[GEO]` 关） |
| **C** | `HC_INPUT_DIAG=1 HC_GEO_EVERY=2 HC_DUMP_MAX=600`（**＝任务书腿 C**，与 B 等价） |

### 2.2 成对读数表（每腿 3 趟；**严格串行**，绝不同时跑两条腿）

| 腿 | 趟 | 崩溃步 | **第几击** | `AE` | `alive` | `rc` | 签名 | `Stack overflow` | `preMouseDown` 总 | 命中链自证 |
|---|---|---|---|---|---|---|---|---|---|---|
| **A（仪器全关）** | A1 | S5a-click-TabItem | **8** | 480000 | **no** | **134** | `Stack overflow.` | 1 | 0（无仪器） | NS |
| | A2 | S5a-click-TabItem | **8** | 480000 | no | 134 | 同上 | 1 | 0 | NS |
| | A3 | S5a-click-TabItem | **8** | 480000 | no | 134 | 同上 | 1 | 0 | NS |
| **A′（只 shim 诊断）** | Ap1 | S5a-click-TabItem | 8 | 480000 | no | 134 | 同上 | 1 | 0 | NS |
| | Ap2 | S5a-click-TabItem | 8 | 480000 | no | 134 | 同上 | 1 | 0 | NS |
| | Ap3 | S5a-click-TabItem | 8 | 480000 | no | 134 | 同上 | 1 | 0 | NS |
| **B′（输入取证，GEO 关）** | Bp1 | S5a-click-TabItem | 8 | 480000 | no | 134 | 同上 | 1 | 245 | **8/8 HIT-OK** |
| | Bp2 | **（启动即死）** | **0** | — | no | 134 | `Win32Exception (50)` | 0 | 0 | — |
| | Bp3 | S5a-click-TabItem | 8 | 480000 | no | **139** | **静默 SIGSEGV** | **0** | 245 | **8/8 HIT-OK** |
| **B（＝任务书腿 B）** | B1 | S5a-click-TabItem | 8 | 480000 | no | 134 | `Stack overflow.` | 1 | 245 | **8/8 HIT-OK** |
| | B2 | S5a-click-TabItem | 8 | 480000 | no | 134 | 同上 | 1 | 245 | 8/8 |
| | B3 | S5a-click-TabItem | 8 | 480000 | no | 134 | 同上 | 1 | 245 | 8/8 |
| **C（＝任务书腿 C）** | C1 | S5a-click-TabItem | 8 | 480000 | no | 134 | 同上 | 1 | 245 | 8/8 |
| | C2 | S5a-click-TabItem | 8 | 480000 | no | 134 | 同上 | 1 | 245 | 8/8 |
| （先导） | V-C1 | S5a-click-TabItem | 8 | 480000 | no | 134 | 同上 | 1 | 245 | 8/8 |

**判据落点**（任务书写死的两分法）：

> 「若**腿 A 也崩** ⇒ **产品缺陷**（仪器只是加速）；若只有 B/C 崩 ⇒ 仪器缺陷」

⇒ **腿 A 3/3 全崩**（`A1`/`A2`/`A3`，第 8 击、`AE=480000`、`rc=134`、`Stack overflow.`）
⇒ **判定：`D-G66` 是产品缺陷。仪器不是驱动源。**

### 2.3 仪器**连行为都没改**：逐击 `AE` 逐位比对（腿 A vs 腿 C）

| 步 | `AE`（腿 A，仪器全关） | `AE`（腿 C，仪器全开） | 相同？ |
|---|---|---|---|
| S1-nav-item1 | 225596 | 225672 | ✗（差 **76 px**，唯一一格） |
| S2-nav-item9 | 73899 | 73899 | ✅ 逐位 |
| S2a-click-TextBox | 7647 | 7647 | ✅ 逐位 |
| S3-nav-item10 | 23419 | 23419 | ✅ 逐位 |
| S3a-open-Combo | 28302 | 28302 | ✅ 逐位 |
| S3b-click-popitem | 21112 | 21112 | ✅ 逐位 |
| S4-nav-item2 | 75531 | 75531 | ✅ 逐位 |
| **S5a-click-TabItem** | **480000（崩）** | **480000（崩）** | ✅ 同值同崩 |

腿 A 与腿 C 的 **`nwin` 轨迹也相同**（7→7→7→7→**8**→7→7→**0**）。
⇒ 仪器对这条缺陷的作用只剩两格：**终止方式**（`rc=134` 的托管报错 vs `rc=139` 的裸 SIGSEGV）与
**运行时来得及打印多少帧**（`M-A1` 展开了 6490 帧 `SetFocus`，`V-C1` 只打了 157 帧 + `Repeated 3266 times:`）。

### 2.4 修前件交叉（`D-G66` 早于 `D-G64`）

| 腿 | shim | 仪器 | 崩溃步 | 击 | `rc` | 签名 | `SetFocus` 帧数 |
|---|---|---|---|---|---|---|---|
| `PRE1-1` | **修前** `abf6879c027c5e73` | **全关** | S5a-click-TabItem | 8 | **134** | `Stack overflow.` | 6488 |

⇒ **修前件 + 点击能落地 ⇒ 同样崩、同一步、同一签名** ⇒ 与 W54A 的成对读数一致，**不是 `D-G64` 引入的**。

---

## §3 判定点：**闭合的 `SetFocus` 回声环**

### 3.1 循环原文（**腿 A3，仪器全关**——`grep` 出来的、没有任何 hc 插桩参与）

```
Stack overflow.
Repeated 3265 times:
--------------------------------
   at System.Windows.Interop.HwndKeyboardInputProvider.ReportInput(IntPtr, …, RawKeyboardActions, Int32, Boolean, Boolean, Int32)
   at System.Windows.Interop.HwndKeyboardInputProvider.OnSetFocus(IntPtr)
   at System.Windows.Interop.HwndKeyboardInputProvider.FilterMessage(IntPtr, MS.Internal.Interop.WindowMessage, IntPtr, IntPtr, Boolean ByRef)
   at System.Windows.Interop.HwndSource.InputFilterMessage(IntPtr, Int32, IntPtr, IntPtr, Boolean ByRef)
   at MS.Win32.HwndWrapper.WndProc(IntPtr, Int32, IntPtr, IntPtr, Boolean ByRef)
   at System.Windows.Threading.ExceptionWrapper.InternalRealCall(System.Delegate, System.Object, Int32)
   at System.Windows.Threading.ExceptionWrapper.TryCatchWhen(System.Object, System.Delegate, System.Object, Int32, System.Delegate)
   at MS.Win32.HwndSubclass.SubclassWndProc(IntPtr, Int32, IntPtr, IntPtr)
   at MS.Internal.WindowsBase.NativeMethodsSetLastError.SetFocus(System.Runtime.InteropServices.HandleRef)   ← ★ 原生边
   at MS.Internal.WindowsBase.NativeMethodsSetLastError.SetFocus(System.Runtime.InteropServices.HandleRef)
   at MS.Win32.UnsafeNativeMethods.TrySetFocus(System.Runtime.InteropServices.HandleRef, IntPtr ByRef)
   at MS.Win32.UnsafeNativeMethods.TrySetFocus(System.Runtime.InteropServices.HandleRef)
   at System.Windows.Interop.HwndKeyboardInputProvider.System.Windows.Input.IKeyboardInputProvider.AcquireFocus(Boolean)
   at System.Windows.Input.KeyboardDevice.TryChangeFocus(System.Windows.DependencyObject, …, Boolean, Boolean, Boolean)
   at System.Windows.Input.KeyboardDevice.Focus(System.Windows.DependencyObject, Boolean, Boolean, Boolean)
   at System.Windows.Input.KeyboardDevice.Focus(System.Windows.Input.IInputElement)
   at System.Windows.Input.KeyboardDevice.CheckForDisconnectedFocus()
   at System.Windows.Input.KeyboardDevice.PreNotifyInput(System.Object, System.Windows.Input.NotifyInputEventArgs)
   at System.Windows.Input.InputManager.ProcessStagingArea()
   at System.Windows.Input.InputProviderSite.ReportInput(System.Windows.Input.InputReport)
--------------------------------
   at System.Windows.Interop.HwndKeyboardInputProvider.ReportInput(…)
   …（同一段再重复 3264 次）
```

**环的闭合方式**（把上面这段读成一个圈）：
`SetFocus`（我们的 shim）**同步**调到 `HwndSubclass.SubclassWndProc`
→ `WndProc` → `HwndSource.InputFilterMessage` → `FilterMessage` → **`OnSetFocus`（WM_SETFOCUS）**
→ `ReportInput(RawKeyboardActions.SetFocus)` → `InputManager.ProcessInput` → `ProcessStagingArea`
→ `PreNotifyInput` → `CheckForDisconnectedFocus` → `KeyboardDevice.Focus` → `TryChangeFocus`
→ **`AcquireFocus`** → `TrySetFocus` → **`SetFocus`（我们的 shim）** → …

环上**唯一一条原生边就是 `NativeMethodsSetLastError.SetFocus`**（P/Invoke 进 `libwpfwin32.so`），
而它**同步回调**了 `SubclassWndProc`。外围（只出现一次、不重复）的入口是：

```
   at System.Windows.Controls.TabItem.SetFocus()
   at System.Windows.Controls.TabItem.OnMouseLeftButtonDown(System.Windows.Input.MouseButtonEventArgs)
   … at System.Windows.Interop.HwndMouseInputProvider.ReportInput(…)   →  … → HandyControlDemo.App.Main()
```

### 3.2 判定点 `文件:行`

**(a) 缺陷在 `src/WpfGfx.Linux.Native/src/win32_core.c:942-955`（原文逐字）**

```c
942: HWND SetFocus(HWND hwnd)
943: {
944:     wpf_global_init();
945:     wpf_lock();
946:     HWND old = g_focus_window;
947:     g_focus_window = hwnd;                                  // ← 无条件写，old==hwnd 也写
948:     pthread_mutex_unlock(&g_wpf.lock);
949:     // 补丁 F2：Win32 的 SetFocus 语义含"系统键盘输入焦点转到该窗口" ⇒ 同步到 X server。
951:     if (hwnd) wpf_x11_set_input_focus(hwnd);                // ← 无条件调 XSetInputFocus
952:     if (old && old != hwnd) wpf_dispatch_to_window(old, WM_KILLFOCUS, (WPARAM)hwnd, 0);   // ← 有 old!=hwnd 守卫
953:     if (hwnd) wpf_dispatch_to_window(hwnd, WM_SETFOCUS, (WPARAM)old, 0);                  // ★★ 没有守卫
954:     return old;
955: }
```

**同一对语义里，`WM_KILLFOCUS` 有「`old != hwnd`」守卫，`WM_SETFOCUS` 没有** —— 而正因为缺这个守卫，
`SetFocus` 在同一次调用链里被反复调到**同一个已经持有焦点的窗口**时，`WM_SETFOCUS` 被反复同步派发 ⇒ 环不终止。

**(b) 「同步」是可证的：`src/WpfGfx.Linux.Native/src/win32_msg.c:512-528`**

```c
512: LRESULT wpf_dispatch_to_window(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
513: {
514:     WNDPROC proc = NULL;
...
526:     if (!proc) return DefWindowProcW(hwnd, msg, wp, lp);
527:     return proc(hwnd, msg, wp, lp);      // ← 直接、同步、同线程回调 WndProc
528: }
```

**(c) 上游 WPF 明说它依赖的 Win32 不变式 —— `upstream/…/PresentationCore/System/Windows/InterOp/HwndKeyboardInputProvider.cs:110-136`（原文逐字）**

```csharp
110:                     // This is the normal case.  We want to keep WPF keyboard
111:                     // focus and Win32 keyboard focus in sync.
112:                     if(!checkOnly)
113:                     {
114:                         // Due to IsInExclusiveMenuMode, it is possible that an
115:                         // HWND keeps Win32 focus even though WPF has moved
116:                         // element focus somewhere else.  When the element focus
117:                         // moves somewhere else, this input provider will get
118:                         // deactivated.  If element focus is set back to an
119:                         // element within this provider, the HWND already has
120:                         // Win32 focus and so will not receive another
121:                         // WM_SETFOCUS, causing the provider to remain
122:                         // deactivated.  Now we detect that we already have
123:                         // Win32 focus but are not activated and treat it the
124:                         // same as getting focus.
125:                         if (!_active && focus == _source.Handle)
126:                         {
127:                             OnSetFocus(focus);
128:                         }
129:                         else
130:                         {
131:                             UnsafeNativeMethods.TrySetFocus(thisWindow);
134:                             // Fetch the HWND with Win32 focus again, to double
135:                             // check we got it.
136:                             focus = UnsafeNativeMethods.GetFocus();
```

> `:120-121` 那句 **「the HWND already has Win32 focus and so **will not receive another** `WM_SETFOCUS`」**
> 就是上游赖以成立的不变式。**我们的 shim 把它破坏了**（`:953`）。
> 而 `OnSetFocus` 里 `_active = false;` 后紧跟 `if (!_active)`（`HwndKeyboardInputProvider.cs:418-420`）恒真
> ⇒ 每一条 `WM_SETFOCUS` 都真的走完整条 `ReportInput` 路径。

**(d) 「同一个窗口被反复 SetFocus」是 shim 自己打出来的（正控）**

腿 `M-Ap1`（`WPF_LINUX_KEY_DIAG=1`）里 `wpf_x11_set_input_focus` 每次入口打一行 `SETFOCUS → XSetInputFocus(window=…)`：

```
SETFOCUS 行总数 = 358      ← 诊断行上限 WPF_KEY_DIAG_MAX=400（win32_x11.c:198）被打满，随后 42 行是别的诊断
其中 window=0x200004 的 = 357 行      （另 1 行 window=0x200008 ＝ 组合框弹窗）
末尾连续 6 行原文（逐字相同）：
[KEY_DIAG] SETFOCUS → XSetInputFocus(window=0x200004)
[KEY_DIAG] SETFOCUS → XSetInputFocus(window=0x200004)
[KEY_DIAG] SETFOCUS → XSetInputFocus(window=0x200004)
[KEY_DIAG] SETFOCUS → XSetInputFocus(window=0x200004)
[KEY_DIAG] SETFOCUS → XSetInputFocus(window=0x200004)
[KEY_DIAG] SETFOCUS → XSetInputFocus(window=0x200004)
```

而 `g_focus_window` 的**全部写入点**只有三处（`grep -rn g_focus_window src/WpfGfx.Linux.Native/src/`）：
`win32_core.c:947`（SetFocus 里）、`win32_x11.c:919`（FocusIn 非回声分支）、`win32_x11.c:937`（FocusOut）
⇒ **进入递归后 `g_focus_window` 恒等于 `0x200004`**，所以这 357 次里**除第 1 次外全部满足 `old == hwnd`**，
**而 `:953` 照样派发了 357-1 = 356 条 `WM_SETFOCUS`**。这正是环的动力。

### 3.3 环的**入口条件**：为什么需要先「换一次页」

| 计划 | 击数 | 结果 |
|---|---|---|
| `tab3` | 1 | **不崩**（1/1） |
| `tab3 tab1` | 2 | **不崩**（2/2） |
| `tab1 tab3` | 2 | **不崩**（1/1） |
| `nav1 tab3` | 2 | **崩**（2/2，`rc=134`，第 2 击） |
| `nav9 tab3` | 2 | **崩**（1/1） |
| `nav9 ctrl_tb type tab3` | 3 | **崩**（第 3 击） |
| `nav10 ctrl_cb pop tab3` | 4 | **崩**（第 4 击） |
| （8 击全序列） | 8 | **崩**（第 8 击） |

⇒ **最小复现＝2 击：`导航项` → `TabItem`**。第一击必须是**导航项**（换页），不能是页签。
**机制我只做到「现象级」**：与「先换一次页」强相关。**候选机制（not proven）**：首次从 `_focus == null` 起焦时
`KeyboardDevice.CheckForDisconnectedFocus()`（`KeyboardDevice.cs:1003-1014`）里
`GetRootVisual(null) == _focusRootVisual(null)` 成立 ⇒ 不进 `Focus(null)` 分支；而**换页之后** `_focus`/`_focusRootVisual`
已非空、且换页路径 `CollectionView.Refresh → ItemContainerGenerator.OnRefresh → Panel.ResetChildren → Panel.ClearChildren`
在崩溃栈里**恰好出现一次**（`V-C1/app.log:4241-4262`），怀疑它把 `_focusRootVisual` 弄成了与 `_focus` 的根不一致的值。
**我没有把这一格证死 ⇒ §6 记 `NOINFO(入口条件未定)`。**

### 3.4 我推翻的一句登记（`D-G66` 原文）

`docs/WAVE49-PREREGISTRATION.md:437` 把签名写成
「`Panel.ClearChildren` ← `ItemContainerGenerator.OnRefresh` ← … ← `HwndMouseInputProvider.ReportInput`」。
实测：`V-C1/app.log` 里 `Panel.ClearChildren`／`Panel.ResetChildren`／`ItemContainerGenerator.OnRefresh`／`CollectionView.Refresh`
**各只出现 1 次**（行 4241/4243/4247/4262），它们**不在** `Repeated 3266 times:` 的那一段里，而在**只出现一次的外围路径**上。
**真正的循环**是 §3.1 那段（`SetFocus ⇄ WM_SETFOCUS`）。⇒ **那句描述该改**：`Panel.ClearChildren` 是「点击的一次性正常后果」
（页签点击 ⇒ TabControl 选中项变 ⇒ ItemsPresenter 重建），**不是**栈溢出的成因。

---

## §4 最小复现（一条命令）

```bash
export PATH="$HOME/.dotnet:$PATH"; \
W55A_STEPS="nav1 tab3" bash $HOME/w55a/bin/leg.sh MINREPRO :168 A
```

- `nav1` = 点导航项 `item[1]`（绝对坐标 `(369,422)`）；`tab3` = 点第 3 个 `TabItem`（`(450,318)`）
- `A` = **仪器全关**（脚本自己 `unset` 所有 `HC_*`/`WPF_LINUX_*` 并记 `hc_in_shell=0 wpf_in_shell=0`）
- 期望读数（2/2 复现）：`CRASH_AT …click-TabItem click_n=2 rc=134`、`alive=no`、`AE=480000`、`nwin=0`、
  `SIGNATURE stackoverflow=1`
- 前置条件：**无 WM 的 Xvfb**（点击能落地）；窗口真值 `(240,212) 800x600`

**判据（修后应当变成什么）**：同一命令 ⇒ `rc` 为空、`alive=yes`、`nwin=7`、`SIGNATURE stackoverflow=0`，
且 `tab3` 那一击的 `AE` **不为 480000**（页面真的换了但不死）。

---

## §5 `D-G65`（并发两实例启动即死）成对读数

| 装置 | 读数 |
|---|---|
| **单实例**（我的腿矩阵全部是单实例；`nav1 tab3` 专门跑了 2 趟） | 启动**正常**：两趟都走到第 2 击才崩（`rc=134`，与 `D-G66` 同因）；`SIG Win32Exception (50) = 0` |
| **双实例**（`bin/pair.sh :170`：实例 1 起好后等 10 s、再起实例 2，同一 display 同时活） | 实例 1 `alive=yes`（`windows=1`）；**实例 2 启动即死**，`rc=134`，`Unhandled exception`=1 |

**但双实例这次的签名与登记的不同** —— 原文（`$HOME/w55a/logs/DG65-dual/app2.log`）：

```
Unhandled exception. System.InvalidOperationException: Cannot set ShutdownMode when application is shutting down or already shut down.
   at System.Windows.Application.set_ShutdownMode(ShutdownMode value) … PresentationFramework/…/Application.cs:line 840
   at HandyControlDemo.App.ApplyConfiguration() … /home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/App.xaml.cs:line 84
   at HandyControlDemo.App.OnStartup(StartupEventArgs e) … App.xaml.cs:line 46
```

机制是**单实例互斥生效**：`EnsureSingleton()`（`App.xaml.cs:123-144`）发现 `createdNew == false` ⇒ 调 `Shutdown()`；
随后 `ApplyConfiguration()` 第一行 `ShutdownMode = ShutdownMode.OnMainWindowClose`（`App.xaml.cs:84`）就抛。
⇒ **这是一条与 `D-G65` 不同、且尚未登记的新缺陷**（第二实例本该静默退出，实际是未处理异常 + `SIGABRT`）。
**建议**：`D-G65` 只记「`Win32Exception (50) @ WaitForMultipleObjectsEx`」；双实例这条**另立一条**。

**⚠️ 我另外推翻了 `D-G65` 的框定**：它**不是并发两实例专有**。我的 ~24 趟里有 **2 趟单实例、启动即死**，
签名**逐字就是 `D-G65`**：

| 腿 | 仪器 | 击数 | 签名 | 原文 |
|---|---|---|---|---|
| `M-Bp2` | `HC_INPUT_DIAG=1`（`[GEO]` 关） | **0** | `Win32Exception (50)` | `Unhandled exception. System.ComponentModel.Win32Exception (50): No CSI structure available` @ `WaitForMultipleObjectsEx` |
| `BIS-3` | **全关** | **0** | `Win32Exception (50)` | 同上，**逐字相同** |

两者的栈都是 `ResourceDictionary.GetValue:485 → Monitor.Enter_Slowpath → DispatcherSynchronizationContext.Wait:91
→ WaitForMultipleObjectsEx:137` ⇒ 这是「**托管锁在 UI 线程上被争用** + 那条等待路坏掉」，
而 `Monitor` 争用**不需要第二个进程**（同进程内另一个线程就够）。
**诚实边界**：我无法回溯证明那两趟时刻「本机没有别的车道在跑同一个应用」，所以我不说「并发无关」，
只说「**并发不是必要条件**」（`BIS-3` 是仪器全关的单实例，这一刻我自己的进程表里没有第二个实例）。

---

## §6 边界、未覆盖与 `NOINFO`

| # | 项 | 状态 |
|---|---|---|
| 1 | **`D-G66` 的入口条件**（为什么必须先换一次页才崩） | **`NOINFO(未定)`**：§3.3 只做到现象级（`tab3` 单点不崩、`nav+tab3` 2 击必崩），候选机制是 `CheckForDisconnectedFocus`/`_focusRootVisual`，**未证死**。 |
| 2 | **静默 SIGSEGV 的终止机制** | **`NOINFO(取不到原生栈)`**：本机 `ulimit -c = 0`、`core_pattern` 是 apport 管道 ⇒ **没有 core 文件**，`coredumpctl` **未安装**。我**没有**用 `gdb --batch` 重跑（用 gdb 会改时序、把这条读数变成另一种装置），所以只说「`rc=139` 且日志里零异常」＝**裸信号死**，不说原生栈。 |
| 3 | `W54A` 的「两种签名」 | **已收敛**：同一环的两种终止方式（`rc=134` 托管报错 / `rc=139` 裸 SIGSEGV），见 §1.3、§3。 |
| 4 | `[GEO]` 坐标／`W54A` 字面量在我的环境下**全部错位一格** | ✅ **复现并纠正**（§6.7）：我第一趟照抄 W54A 的字面量 ⇒ 5 次导航击落在 `item[k-1]`、页内击落在 `ScrollViewer`、页签击落在 `Border#contentPanel` ⇒ **那一趟读数作废**（`leg A1` 的「不崩」**不成立**，装置换了才成立）。 |
| 5 | 有 WM（`xfwm4`）的腿 | **未测**（本趟全部无 WM）。W54A 已证「有 WM ⇒ 点击被吞 ⇒ 不崩」，我不重复。 |
| 6 | 用户真实会话（`:0` mutter/Xwayland、`:10` xrdp+xfwm4） | **未测**（纪律：不碰用户会话）。 |
| 7 | **`bin/probe.sh` 判为不可用** | 它的收敛判据只等「两张截图相同」，比 `leg.sh` 短 ~4 s ⇒ 页内容尚未就绪时点击**静默落空**（`(809,340)` 连点两击 `AE=0`）。**它给出的三趟「不崩」是无效负例**（`BISA/BISB/BISC`），已全部改用 `leg.sh` 的 `W55A_STEPS`。 |
| 8 | `D-G65` 是否真的与并发无关 | **`NOINFO(不能回溯)`**：见 §5 末。 |
| 9 | 我自己的仪器自伤 | 见 §6.7 三条。 |

### 6.7 我自己的仪器自伤（如实入册）

1. **照抄 W54A 字面量**（第 1 趟 `leg A1`）：`(283,451)` 在我的窗口几何下落在 `item[2]`（不是 `item[1]`），
   `(592,364)` / `(632,368)` / `(371,344)` 分别落在 `ScrollViewer` / `ScrollViewer` / `Border#contentPanel`
   —— 而**当时的日志明明白白**没有一条 `ComboBox`／`TextBox`／`TabItem` 命中链，我是在**核对命中链时**才发现的。
   **那一趟的「不崩」是假读数**，已整趟作废并重做。**根因**：`[GEO]` 的 `scr=` 在同一份日志里对同一控件给出 `x=567` 和 `x=619` 两个值，
   而且页内控件会被报成 `scr=567,1345`（**窗口只有 600 px 高**，`vis=True`）⇒ 「`vis=True` 就当在视口内」是错的。
2. **`probe.sh` 的收敛判据太短**（§6.7-7）⇒ 三趟无效负例。
3. **`leg.sh` 的 `cleanup` 只杀子 shell、不杀 `timeout`/`dotnet` 孙进程**（收工自查时发现）：
   若某腿的应用**没崩**（活到趟尾），会留下一个孤儿应用最多 `timeout 300` 秒。
   本趟所有腿都在第 8 击崩了，所以**实际没留下孤儿**（收工 `ps` 里 `dotnet HandyControlDemo` 计数为 0），
   **但这是装置缺陷**，已记在此：`kill` 要用进程组或显式 `timeout` 的子进程。
4. **把「按日志偏移切段」的计数当成了全量**：`marks.txt` 里逐击 `XBTN=0` 是 stderr 缓冲造成的**假零**
   （真值 `COUNTS XBTN=8`，一击一条，见 §1.2 的 8 条原文）。**同一族**：任何「按偏移切段」的统计对
   **缓冲写 stderr 的诊断**都不可靠。我是核对 §1.2 那张表时才发现自己的逐击列是错的。
5. **`pgrep -f` 自匹配**（又一次踩到已登记的 `D-G34`）：`pgrep -c -f 'dotnet HandyControlDemo.dll'` 返回 **2**，
   而当时实际只有 **1** 个应用在跑 —— 匹配到的是**我自己那条含该字符串的命令行**。
   改用 `ps -eo … | grep -E 'HandyControlDemo[.]dll'` 才正确。**判据的输入包含调用者自己的命令行。**

---

## §7 复算命令逐条

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"

# 0) 件 sha16（五件；含修前件）
sha256sum $HOME/w55a/app/{libwpfwin32.so,wpfgfx_cor3.so,PresentationCore.dll,PresentationFramework.dll,WindowsBase.dll} | cut -c1-16
sha256sum $HOME/w55a/app-pre/libwpfwin32.so | cut -c1-16        # abf6879c027c5e73

# 1) 三条腿（每条自证 env 清空 + 五件 sha；输出 $HOME/w55a/logs/<tag>/）
bash $HOME/w55a/bin/leg.sh REPRO-A  :165 A      # 仪器全关  → 第 8 击崩 rc=134
bash $HOME/w55a/bin/leg.sh REPRO-Bp :166 Bp     # 输入取证、GEO 关
bash $HOME/w55a/bin/leg.sh REPRO-C  :167 C      # 任务书腿 C

# 2) 最小复现（2 击）
W55A_STEPS="nav1 tab3" bash $HOME/w55a/bin/leg.sh MINREPRO :168 A

# 3) 命中链自证（每条仪器腿应 8/8 HIT-OK、preMouseDown 总 245）
grep -a 'HIT-OK\|HIT-MISMATCH' $HOME/w55a/logs/REPRO-C/marks.txt | wc -l
grep -a '^COUNTS' $HOME/w55a/logs/REPRO-C/marks.txt

# 4) 崩溃签名与环（**腿 A 的日志就已经够了**）
grep -an 'Stack overflow'        $HOME/w55a/logs/REPRO-A/app.log
grep -a  'Repeated'              $HOME/w55a/logs/REPRO-A/app.log
awk '/Repeated/{f=1} f'          $HOME/w55a/logs/REPRO-A/app.log | head -24
grep -ac 'NativeMethodsSetLastError.SetFocus' $HOME/w55a/logs/REPRO-A/app.log
grep -an 'TabItem.OnMouseLeftButtonDown\|TabItem.SetFocus' $HOME/w55a/logs/REPRO-A/app.log | tail -3
grep -an 'Panel.ClearChildren\|ItemContainerGenerator.OnRefresh\|CollectionView.Refresh' $HOME/w55a/logs/REPRO-A/app.log

# 5) 「同一窗口被反复 SetFocus」的正控（腿 A′）
grep -ac 'SETFOCUS → XSetInputFocus' $HOME/w55a/logs/M-Ap1/app.log          # 358
grep -a  'SETFOCUS → XSetInputFocus' $HOME/w55a/logs/M-Ap1/app.log | sed 's/.*window=//' | sort | uniq -c

# 6) 判定点的源码原文
sed -n '926,956p'  $R/src/WpfGfx.Linux.Native/src/win32_core.c
sed -n '512,528p'  $R/src/WpfGfx.Linux.Native/src/win32_msg.c
sed -n '110,136p'  $R/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/InterOp/HwndKeyboardInputProvider.cs
sed -n '1003,1014p' $R/upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Input/KeyboardDevice.cs
grep -rn 'g_focus_window' $R/src/WpfGfx.Linux.Native/src/*.c

# 7) 仪器是不是驱动源（B vs C 等价性）
sed -n '472,477p' /home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/App.xaml.cs
sed -n '824,834p' /home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/App.xaml.cs

# 8) D-G65 成对
bash $HOME/w55a/bin/pair.sh :170 DG65-dual A
grep -a 'PHASE\|APP[12] ' $HOME/w55a/logs/DG65-dual/marks.txt
grep -a 'Win32Exception (50)' $HOME/w55a/logs/M-Bp2/app.log $HOME/w55a/logs/BIS-3/app.log

# 9) 本报告自身 sha16（口径 = 去掉本行）
cd $R && head -n -1 build/MilBridge/W55A-report.md | sha256sum | cut -c1-16
```

**W55A-report.md sha16（口径 = 去掉本行）= `5d550948ab17a55c`**

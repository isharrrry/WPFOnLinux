# W89A 报告 —— `TASK-0205`：修 **`D-G81`**（**WM 侧发起的最大化不被应用状态位采纳** ⇒ 双击/自带还原按钮都还原不了）

> lane = **W89A** ｜ 2026-09-22 **10:07 → 11:5x +0800** ｜ kernel `6.8.0-138-generic` ｜ `nproc=3`
> 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（全程绝对路径）
> **写域**：`src/WpfGfx.Linux.Native/src/win32_x11.c`（唯一产品件）＋ `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（构建产物）
> ＋ 仓外新探针 `$HOME/w89a/probe/`（`W89AStateProbe`）＋ 本报告。**仓内只写这一个文件。**
> 判据**先写**：`$HOME/w89a/criteria.md` = **`f9c343e42a7e6f7f`**（7,044 B，`2026-09-22 10:13:30 +0800`；早于任何读数）
> 复现依据（只读）：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2322-2327`（`D-G81` 条目）＋ `build/MilBridge/W77A-report.md` §3.4/§3.6/§3.7（成对读数）。

---

## 0 一句话判决

**假设被证实，缺陷已修**：外部 `_NET_WM_STATE` 最大化之后，应用侧状态位**确实没更新**（真 hc 应用 + 专用探针**两台仪器**各给一份逐字读数）；根因是 **shim 的窗口状态缓存只在"应用自己走 `ShowWindow`/`WM_SYSCOMMAND`"那条路上更新**，WM 单方面改状态时缓存不动，而 `PropertyNotify(_NET_WM_STATE)` 在本 shim 里被**当成"对 WPF 没有语义"丢掉**。
修法 = **在 `PropertyNotify` 上把 X 侧的权威状态采纳进窗口表（幂等），并派发等价 `WM_SIZE`**（只动 `win32_x11.c` 一个文件）。
**两极化三臂全部拿到**：外部最大化 ⇒ **双击还原 13/13**、**自带还原按钮窗态 15/15**（几何 13/15）；**反极性**（源逐字节复原＋重建 ⇒ `win32shim` 回到 `24e906c194903c8b`）⇒ **双击 3/3 ＋ 按钮 3/3 全还原不了**；**应用自发对照臂**（`M1×R1` 8/8、`M2×R2` 13/13）**未改坏**。**同时推翻了我自己判据里的一条机制断言**（"托管侧 `WS_MAXIMIZE` 守卫是堵点"——实测**不是**，见 §5.4）。
**新 `win32shim` = `33352e5797031999`（327,248 B）**，其余八位逐位未动。

---

## 1 装置与件（读数**绑件**；每趟现场 `sha256sum` 现算，无手抄）

| 项 | 值 |
|---|---|
| 私有显示 | `:39` = `Xvfb :39 -screen 0 1280x1024x24 -nolisten tcp`（PID 1658115）＋ `xfwm4 --display=:39 --compositor=off --replace`（PID 1658558）；`_NET_SUPPORTING_WM_CHECK` 每趟核对在场 |
| 第二显示（`0106` 专用，**裸 Xvfb 无 WM**，与 W81A/W82A 同形） | `:41` = `Xvfb :41 -screen 0 1280x1024x24 -nolisten tcp`（PID 1816947） |
| 被测应用 | `$HOME/w89a/app/` = 仓内权威 app-local 目录（`/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`）的**逐字节副本**，**只换 `libwpfwin32.so`** |
| 探针 | `$HOME/w89a/probeapp/` = 同一份应用目录，`HandyControlDemo.dll` 换成 `W89AStateProbe`（**AssemblyName 故意同名** ⇒ 直接复用那份 deps.json/runtimeconfig 与原生件路由）；探针 dll `6142c7299dfaa173` |
| 应用侧五件（**读数绑定的就是这几个 sha**） | `wpfgfx_cor3.so feef049e9d0e313a`｜`PresentationCore.dll 56ee75ced8d6aece`｜`PresentationFramework.dll 2a5b7641f6fba0fb`｜`WindowsBase.dll 2e4e46e539a72cd7`｜`libwpfwic.so 56278c14b4ecd672`｜`DirectWrite.Linux.Provider.dll 1f9511a7ef395bfe` |
| 槽 | 每条重活（应用/构建）整条包进 `bash ~/heavy-slot.sh --min-avail 1500 --max-hold 240 --wait 1800 -- timeout 230 <载荷>`；`HEAVYSLOT=MAXHOLD_KILL/TIMEOUT/low-memory` 那趟**不是读数**（本趟 0 条） |
| 判据件 | 仓内仪器**按原样调用**、不改一字：`build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg pmax`（`0106`；它自身会重建自己的探针产物 —— 写域偏离已登记在 §6.2）＋ W85A/W77A 时代的 hc 点击协议**照抄重写**到 `$HOME/w89a/bin/` |

**世代位（开工时现场复算，用于绑定"修前"）**：`win32shim` = **`24e906c194903c8b`**（323,008 B，含 `W86A` 的 `A1`/PTS 面；`W86A-report.md` §7 的"本件后"值）。其余八位见 §7。

---

## 2 判据（原文 `$HOME/w89a/criteria.md` `f9c343e42a7e6f7f`）与预测/实测对照

| 判据 | 预测（先写） | 实测 | 判 |
|---|---|---|---|
| **C1** 外部最大化后**应用侧** `WindowState` | `Normal`（状态位没更新） | `Normal`（探针逐字 + hc `[GEO]` 旁证） | ✅ 证实 |
| **C1'** shim 缓存 `w->maximized` / `style & WS_MAXIMIZE` | `0 / 0` | `0 / 0`（`PROPERTY … x_maximized=1 \| 缓存 maximized=0`） | ✅ 证实 |
| **C2** 外部最大化后的还原入口产生的**真还原动作**次数 | **0** | **0**（`apply_wm_state_REMOVE=0`，且 hc 终态逐字未变） | ✅ 证实 |
| **C4①A** 修后外部 ⇒ **双击标题栏还原** | 6/6 | **13/13**（v2b 6/6 ＋ v3 7/7） | ✅ |
| **C4①B** 修后外部 ⇒ **自带还原按钮** | 5/5 | **窗态 15/15**；几何同刻收回 **13/15** | ⚠️ 见 §5.3（**残留 2 趟**，如实登记） |
| **C4②** 反极性（源逐字节复原＋重建） | 回到 3/3＋3/3 全败 | **3/3＋3/3 全败**，终态恒带 `MAXIMIZED_*` | ✅ |
| **C4③** 应用自发对照臂 | 不许改坏 | `M1×R1` **8/8**、`M2×R2` **13/13**、`M1×R2` 2/2、`M2×R1` 2/2 | ✅ |
| **C4④** 半边修 | H1/H2 都该红 | **H1 绿、H2 红** ⇒ **推翻我自己的那条断言** | ⚠️ 见 §5.4 |
| **C5** `0104` 四入口 ＋ `N1` 最小化 | 仍全可用 | 四入口 25/25、`N1` 1/1（`HIDDEN`+`IsUnMapped`） | ✅ |
| **C5** `0106` 四格（`D-G83`） | 仍全绿 | `667 by 500`／`521 by 417`／`absent`／`reg58=0` ⇒ **PASS** | ✅ |
| **C5** `hbtextline`/`pc`/`wic_shim`/`bridge`/`pf`/`windowsbase` | 不动 | 逐位未动（§7） | ✅ |

---

## 3 ① 先定性读数：**应用状态位 vs shim 缓存**

### 3.1 应用侧：**两台独立仪器**都说"没更新"（修前）

**(a) 专用探针 `W89AStateProbe`（逐字读 `Window.WindowState`；`$HOME/w89a/probe/Program.cs`）**
`$HOME/w89a/run/W89A-pre-ext/wstate.txt`（探针行原文，`SHIM=69a8c3725efe6673`=只加仪器那版）：

```
[WSTATE] t=6.609  state=Normal style=0x12CF0000 ws_max=0 ws_min=0 vis=1 rect=833x625@+255+250   ← 最大化前
ACT t=8.0 EXTERNAL _NET_WM_STATE ADD MAXIMIZED_H|V
[WSTATE] t=8.367  state=Normal style=0x12CF0000 ws_max=0 ws_min=0 vis=1 rect=1280x1000@+0+24     ← 窗口**已经被 WM 拉满**…
[WSTATE] t=12.150 state=Normal style=0x12CF0000 ws_max=0 ws_min=0 vis=1 rect=1280x1000@+0+24     ← …而应用**仍以为自己是普通窗**
ACT --restore-at t=20 ⇒ WindowState = Normal（与自带"还原"按钮逐字同一条托管路）
[WSTATE] t=24.192 state=Normal style=0x12CF0000 ws_max=0 ws_min=0 vis=1 rect=1280x1000@+0+24     ← 还原动作**什么都没做**
```
⇒ **应用侧 `WindowState` 停在 `Normal`、`GWL_STYLE` 里没有 `WS_MAXIMIZE`**（`style=0x12CF0000`），而窗口**几何已经是最大化的**。

**(b) 真 hc 应用的 `[GEO]` 旁证（独立第二仪器；`HC_INPUT_DIAG=1`）**
HC 模板 `Themes/Styles/Window.xaml:113-120` 用 `<Trigger Property="WindowState" Value="Maximized|Normal">` 直接绑 `ButtonMax`/`ButtonRestore` 的可见性 ⇒ **`[GEO]` 的 `vis` 就是 `Window.WindowState` 的函数**。
`$HOME/w89a/run/R-geo2/probe.txt`（`SHIM=24e906c194903c8b` = **完全复原的修前件**）：

```
GEO_BTN_BASE     Button#ButtonMax scr=943,213  wh=46x28 vis=True   Button#ButtonRestore wh=0x0  vis=False
GEO_BTN_AFTER_M  Button#ButtonMax scr=1183,1   wh=46x28 vis=True   Button#ButtonRestore wh=0x0  vis=False   ← 外部最大化后
GEO_BTN_AFTER_R  Button#ButtonMax scr=1183,1   wh=46x28 vis=True   Button#ButtonRestore wh=0x0  vis=False   ← 还原动作后（逐字相同）
```
⇒ 外部最大化之后，应用**仍把"最大化按钮"显示着**（即 `WindowState == Normal`）；`R-geo3` 逐字相同。

### 3.2 shim 侧：缓存在 `PropertyNotify` 那一刻**确实是 0**（修前）

`$HOME/w89a/run/W89A-pre-ext/app.log`（`WPF_LINUX_WINSTATE_DIAG=1`，**只打印不改行为**的那一版）：

```
[WINSTATE_DIAG] CONFIGURE hwnd=0xa00003 1280x1000@+0+24 ⇒ WM_SIZE sizecode=0 (缓存 maximized=0 iconified=0)   ← 发的是 SIZE_RESTORED！
[WINSTATE_DIAG] PROPERTY _NET_WM_STATE window=0xa00003 read_ok=1 x_maximized=1 | 缓存(读属性后) maximized=0 style_WS_MAXIMIZE=0
```
⇒ **铁证**：属性读到"X 说已经最大化（`x_maximized=1`）"，而**窗口表缓存仍是 `0/0`**，且这一拍**什么都没做**（修前 `PropertyNotify` 走 `default:` 丢弃）。
另外两条**次序**读数（决定了修法形状，见 §4.3）：xfwm4 是 **先 `XConfigureWindow`、后写 `_NET_WM_STATE`**（上面两行 `CONFIGURE 1280x1000` 在 `PROPERTY` 那行**之前**）。

### 3.3 三个消费者为什么同时判错（根因，逐行）

| # | 消费者 | 文件:行 | 机制 |
|---|---|---|---|
| ① | `DefWindowProcW(WM_NCLBUTTONDBLCLK)`（**双击标题栏**） | `win32_core.c:1704-1712` | `was_max = wd->maximized` ⇒ 读到 0 ⇒ `wpf_core_window_state(MAX)` ⇒ **"还原"变成"再最大化一次"** |
| ② | `ConfigureNotify` 的 `WM_SIZE` wParam | `win32_x11.c:854-864`（修前行号） | 取 `w->maximized` ⇒ 恒 `SIZE_RESTORED` ⇒ 上游 `Window.WmSize` 的 `case SIZE_RESTORED`（`Window.cs:4734`）把 `WindowState` 掰回 `Normal` |
| ③ | 托管侧"还原"命令（**自带还原按钮**） | HC `Window.cs:299` ⇒ 上游 `Window.cs:5188` | `WindowState = Normal` 时 DP **根本没变**（本来就是 `Normal`）⇒ `OnWindowStateChanged` **不跑** |

⇒ 判定点 = **`wpf_core_window_state`（`win32_core.c:626`）是缓存唯一的更新入口，而 WM 单方面改状态不经过它**。

---

## 4 ② 修法（只动一个文件）

### 4.1 改动清单（before/after sha16，全部现场算）

| 件 | before | after | 字节 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `050f349638bbf87e` | **`6477af56fdcfdf20`** | 91,594 → **105,615** |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（= `win32shim`） | `24e906c194903c8b` | **`33352e5797031999`** | 323,008 → **327,248** |
| 备份（纪律 16） | `$HOME/w89a/backup/win32_x11.c.orig`（`050f349638bbf87e`）、`libwpfwin32.so.orig`（`24e906c194903c8b`）、`win32_x11.c.v3final`（`6477af56fdcfdf20`） | — | — |

`diff -u` 摘要（`$HOME/w89a/out/win32_x11.diff`，5 个 hunk、`+238/-2`）：

| hunk | 位置（新行号） | 内容 |
|---|---|---|
| `@@ -792,6 +792,189 @@` | `:795-980` | 新增：仪器 `wpf_wstate_diag*`、**权威状态读取** `wpf_x11_query_maximized`、缓存读点 `wpf_x11_peek_state`、顶层判据 `wpf_x11_is_toplevel`、**采纳** `wpf_x11_adopt_maximized`、一站入口 `wpf_x11_sync_window_state` |
| `@@ -851,6 +1034,17 @@` | `:1037-1047` | `ConfigureNotify`：**先采纳、再算 `WM_SIZE` 的 wParam**（只采纳、不自己派发） |
| `@@ -864,6 +1058,13 @@` | `:1058-1064` | `ConfigureNotify` 的 `WM_SIZE` 诊断行 |
| `@@ -1216,8 +1417,32 @@` | `:1417-1448` | **`case PropertyNotify`**（`atom==_NET_WM_STATE` ∧ `PropertyNewValue`）：读属性 → 采纳 → 变了才 `push(WM_SIZE)`；原来的 `default:` 注释同步更正（`-1` 行） |
| `@@ -1509,6 +1734,17 @@` | `:1734-1744` | `wpf_x11_apply_wm_state` 的"我们自己发了 ADD/REMOVE"诊断行（与应用自发那条路配对读） |

### 4.2 修法实质（三句话）

1. **EWMH 的 `_NET_WM_STATE` 是窗口状态的权威**：`MAXIMIZED_HORZ` 与 `MAXIMIZED_VERT` **同时在场**才判"最大化"（与 `wpf_x11_apply_wm_state` 的发送口径、判据侧 `is_max()` 同一口径）。
2. 读到权威状态后**采纳进窗口表**（`w->maximized` ＋ `w->style` 的 `WS_MAXIMIZE` 位），并**派发等价 `WM_SIZE`**（`SIZE_MAXIMIZED`/`SIZE_RESTORED`）——Win32 的 USER32 在状态真的变化时也是这么发的。
3. **幂等**：与本表缓存一致 ⇒ 一个字节都不改、一条消息都不发（应用自发那条路会收到**我们自己的 ADD 触发的** `PropertyNotify`，绝不能重复派发）。实测配对读数：

```
（外部最大化）ADOPT(CONFIGURE) … ⇒ 缓存(采纳后) maximized=1 style_WS_MAXIMIZE=1
              CONFIGURE 1280x1000@+0+24 ⇒ WM_SIZE sizecode=2 (缓存 maximized=1)
              PROPERTY … x_maximized=1 | 缓存(读属性后) maximized=1      ← 第二次读到，**没有 ADOPT、没有重复消息**
（应用自发）  APPLY_WM_STATE … maximize=1（我们发的 ADD）| 缓存 maximized=1
              APPLY_WM_STATE … maximize=0（我们发的 REMOVE）| 缓存 maximized=0
              （全程 **0 条 ADOPT** ⇒ 我们自己的动作触发的 PropertyNotify 什么都没做）
```
（`ADOPT(CONFIGURE)` 行里的 `sizecode=-1 -1x-1` 是**故意**：`ConfigureNotify` 那一处传 `NULL`（下面的 `WM_SIZE` 由既有那段自己发）⇒ 打印的是"没取"。）

### 4.3 为什么**两处**都要采纳（`ConfigureNotify` ＋ `PropertyNotify`）

因为实测**次序是"先改几何、后写属性"**（§3.2）：若只在属性事件上采纳，`ConfigureNotify` 那一拍发出去的 `WM_SIZE` 仍然是 `SIZE_RESTORED`（托管侧那一瞬仍被判成"普通"）。两处调**同一个幂等**函数 ⇒ 谁先到谁生效。
代价：每个 `ConfigureNotify` 多一次 `XGetWindowProperty` 往返——与**隔壁那行 `XTranslateCoordinates` 同量级**，且只对**顶层**窗口问。本件量到的应用启动/交互时间与修前无差别（每趟 `CONVERGED iters`、`WARM=6.5 s`、动作后 4.5 s 的读数结构逐趟相同）。

### 4.4 一次**收窄**（如实记：第一版写宽了）

第一版采纳时顺手清了 `w->iconified` 与 `WS_MINIMIZE`。**在本件落地前我把它删掉了**，理由是可证的：EWMH 里 `_NET_WM_STATE` 可以**同时**含 `MAXIMIZED_*` 与 `HIDDEN`（xfwm4 最小化一个已最大化窗口就是这样）⇒ 那样会**破坏"应用自己按最小化按钮"那条路**的状态。
⇒ 现在这一版**只碰最大化那两个位**；最小化态（`iconified`、`WS_MINIMIZE`、`UnmapNotify`/`MapNotify` 那条腿）**一个字节都不动**。`N1` 臂实测仍 `m_ok=1`（§6.1）。

---

## 5 ③ 两极化三臂 ＋ 半边修

> 全部读数落 `$HOME/w89a/run/<tag>/probe.txt`（每趟现场印五件 sha16 ＋ 本趟 `SHIM=`）。下表**按件分列**（不同 `libwpfwin32.so` 的读数不混算）。

### 5.1 ① 正极性：**外部** `_NET_WM_STATE` 最大化 ⇒ 还原入口

| 臂 | 件（shim） | 分母 | 判词 |
|---|---|---|---|
| **A 双击标题栏**（`M3×R1`） | `58a79b913e9ed8f4`（v2b）6 趟 ＋ `33352e5797031999`（**v3 定稿**）7 趟 | **13** | **13/13 还原**（终态 `_NET_WM_STATE` 只剩 `FOCUSED`、几何回到 `800x600@+240+212`） |
| **B 自带还原按钮**（`M3×R2`） | 同上 | **15** | **窗态 15/15 还原**（`MAXIMIZED_*` 全掉）；**几何同刻收回 13/15** ⇒ ⚠️ 残留 2 趟（§5.3） |

逐趟：`A-ext1..5`、`A-geo1`、`F-ext1..6`、`V3-geo`（13 趟全 `r_ok=1`）；`A-btn1..5`、`F-btn1..5`、`H-btn1..5`。

**修后机制读数**（`V3-sanity-ext`，`probe` 臂，`SHIM=33352e5797031999`）：
```
AFTER_MAX     geom=1280x1000@+0+24 probe=[t=12.127 state=Maximized style=0x13CF0000 ws_max=1 …]   ← 状态位跟上了
AFTER_RESTORE geom=833x625@+255+250 state=[_NET_WM_STATE_FOCUSED] r_ok=1 probe=[t=24.192 state=Normal …]
COUNTERS apply_wm_state_REMOVE=1（真还原动作**发出了**）
```
**修后 hc `[GEO]` 配对读数**（`V3-geo`，与 §3.1(b) 的修前读数**同格式**）：
```
GEO_BTN_AFTER_M  Button#ButtonMax wh=0x0 vis=False   Button#ButtonRestore wh=46x28 vis=True    ← WindowState==Maximized
GEO_BTN_AFTER_R  Button#ButtonMax wh=46x28 vis=True  Button#ButtonRestore wh=0x0 vis=False     ← 回到 Normal（面板也回到常态槽位）
```

### 5.2 ② 反极性：**撤销修法**（源逐字节复原 ＋ 重建）

```
cp -f $HOME/w89a/backup/win32_x11.c.orig src/WpfGfx.Linux.Native/src/win32_x11.c
   ⇒ 源 sha16 回到 050f349638bbf87e（与 .orig 逐字节相同）
./build-shim.sh ⇒ 产物 sha16 回到 24e906c194903c8b（= 开工时的权威件，逐字节相同）
```
| 臂 | 分母 | 读数 |
|---|---|---|
| `R-ext1..3`（外部 ⇒ **双击还原**） | 3 | **3/3 失败**（`r_ok=0`；终态恒 `[MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED｜1280x1024@+0+0]`） |
| `R-btn1..3`（外部 ⇒ **自带还原按钮**） | 3 | **3/3 失败**（同上） |

⇒ 与 W77A §3.4/§3.6 的修前形态**逐字同形**（"终态恒带 `MAXIMIZED_*`"）。
**往返闭合**：复原修法（`cp -f win32_x11.c.v3final`）⇒ 源 `6477af56fdcfdf20`、产物 **`33352e5797031999`**（与第一次构建逐位相同）。

### 5.3 ⚠️ 残留（**如实登记，未压绿**）：`M3×R2` 有 2/15 趟"窗态还原了、几何卡在最大化"

`F-btn3` / `F-btn4`（`SHIM=33352e5797031999`）原始行：
```
AFTER_R2          state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok=0     ← 两个 MAXIMIZED_* **已经掉了**
AFTER_R2_SETTLED  state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok2=0    ← 多等 4.5 s 仍未收回
```
即：**WM 侧状态已还原、应用侧状态位也已还原（`FOCUSED` only），但客户区几何停在 `1280x1024@+0+0`**。
- **不是**"还原没发生"（`_NET_WM_STATE` 与 `[GEO]` 都显示已回常态），**也不是**本修法引入的独有形态：W77A §3.6 在**应用自发**那条路上就见过同形（`AM1R2v4_a/_b`，那时**修前件**、`r_ok=0` 而"两个 `MAXIMIZED_*` 已经掉了"）。
- 同趟的 `H-btn1..5`（同件、同协议、`SETTLE=6`/`SETTLE2=12`）与全部 `M2×R2`（13 趟）**都 5/5、逐点收回** ⇒ 间歇性、~2/15。
- ⇒ 本件把它**登记为新待查项**（`D-G81` 的**残余**，不是判据放松）：判据原文（"终态无 `MAXIMIZED_*` ∧ 几何 = 基准"）**两列都保留**，B 臂按"窗态 15/15、几何 13/15"读。**不许**把它读成"5/5 全绿"，也不许读成"还原没发生"。

### 5.4 ④ 半边修：**H1 绿 / H2 红 ⇒ 我推翻了自己判据里的一条机制断言**

| 半修 | 定义 | 件 | 读数 |
|---|---|---|---|
| **H1** | **只**同步 `w->maximized` ＋派发 `WM_SIZE`；**不同步** `style` 位 | `bb53e0e79f30e562` | `probe-ext` **r_ok=1**、`probe-ext2` **r_ok=1**、hc `M3×R1` **r_ok=1**、hc `M3×R2` **r_ok=1** ⇒ **绿** |
| **H2** | **只**同步 `style` 位（不动 `w->maximized`、`sizecode` 恒 `RESTORED`） | `260853fb7e4cc7a1` | `probe-ext` **r_ok=0**、hc `M3×R1` **r_ok=0/r_ok2=0**、hc `M3×R2` **r_ok=0/r_ok2=0** ⇒ **红** |

⇒ **推翻**（我在判据 `criteria.md` §C2 里写的第 ③ 条）：
> 原话："③ 托管侧'还原'命令…**即便跑**，上游 `Window.cs:5188` 的 `if ((_Style & WS_MAXIMIZE) == WS_MAXIMIZE)` 也过不去 ⇒ `ShowWindow(SW_RESTORE)` 永不发。"

**实测不是这样**：H1（没有 style 位同步）下两条腿都绿。机制（`$HOME/w89a/run/H1-probe-ext/app.log` 配对读数）是：我们派发的 `WM_SIZE(SIZE_MAXIMIZED)` 让托管侧 `WindowState` 变成 `Maximized` ⇒ `OnWindowStateChanged(Maximized)` 里那句"**样式里没有 `WS_MAXIMIZE` 就 `ShowWindow(SW_MAXIMIZE)`**"（上游 `Window.cs:5231`）**自己把样式位补上了**（现场行：`APPLY_WM_STATE … maximize=1（我们发的 ADD）| 缓存(发送后) style_WS_MAXIMIZE=1`）⇒ 之后"还原"时那句守卫（上游 `Window.cs:5189`）**过得去**。
⇒ **必要且充分的那一半 = 同步 `w->maximized` ＋ 把状态告诉托管侧（`WM_SIZE`）**；`style` 位那一半**不是必需**，但它**正确且更省**（少一次 `_NET_WM_STATE` ADD 往返，且"最大化态样式含 `WS_MAXIMIZE`"与 Windows 同形）⇒ **保留**，并在代码注释里**标明它不是必要项**。

---

## 6 ④ 零回归

### 6.1 `0104` 四入口矩阵（正确预热 `WARM=6.5 s` ＋ **状态相关坐标**；每趟一个全新进程树）

| 入口组合 | 分母 | 读数 |
|---|---|---|
| `M1×R1` 双击最大化 ⇒ 双击还原 | 8 | **8/8 还原** |
| `M2×R2` 自带 Max ⇒ 自带还原按钮 | 13 | **13/13 还原** |
| `M1×R2` | 2 | 2/2 |
| `M2×R1` | 2 | 2/2 |
| `N1` 自带最小化按钮 | 1 | **1/1** `state=[_NET_WM_STATE_HIDDEN] mapstate=IsUnMapped`；装置复位后回 `[FOCUSED] 800x600@+240+212` |
| **合计** | **26** | **26/26**（`m_ok` 与 `r_ok` 全 1；`START_MAX=0` 每趟核对；`UNHANDLED=0`） |

件版本分布（逐趟 `probe.txt` 里的 `SHIM=` 可复核）：`58a79b913e9ed8f4`（v2b）11 趟 ＋ `33352e5797031999`（**v3 定稿**）15 趟。两版差别只有"要不要顺手清最小化位"（§4.4；最终版**不清**）⇒ 应用自发这条路上两版**行为等价**，实测也一致。

### 6.2 `0106` 的 `D-G83` 四格（**在定稿件上**；裸 Xvfb `:41`，读数面 = X 服务器自己的 `WM_NORMAL_HINTS`）

```
W89A_0106 SHIM 33352e5797031999  PROBE_DLL 8d658809c41fb9bb
ROLE declared    max='program specified maximum size: 667 by 500'
ROLE minonly     min='program specified minimum size: 521 by 417'
ROLE undeclared  max=<缺席>
CELL reg58（'1280 by 1024' 出现次数）⇒ 0
W89A_0106 VERDICT=PASS
```
⚠️ **仪器缺陷如实入册**：仓内 `run-w81a-legs.sh --leg pmax` 本趟报 `W81A_PMAX=NOINFO reason=probe-not-ready`，而**事后**同一个 `app.log` 里**确实有** `W81A_READY mode=pmax-pair windows=5` ⇒ 是**探针 stdout 被重定向后走块缓冲**导致的时序假 NOINFO（.NET 控制台重定向行为），**不是四格红**。我用自己的侧读（`stdbuf -oL` ＋ 自己 `xprop`，**判词与 W82A 同口径**）拿到上面四格。

⚠️ **写域偏离一处（如实登记）**：跑那条仓内仪器时它**按设计重建了自己的探针**（`build/MilBridge/tests/W81AWindowProbe/{obj,bin}/Release/**` 共 **9 个构建产物**文件被重写，探针 dll 现值 **`8d658809c41fb9bb`**，本报告读数已绑该值）。**源件一个字节未动**（`Program.cs`/`run-w81a-legs.sh`/`csproj` 都不在改动清单里），仪器语义与判据未变 ⇒ 只是构建产物换代（它引用的 `pc`/`pf` 也已被别的车道换过）。派单书写的是"不许碰 `build/MilBridge/**`"，这一处是**跑既有仪器**的副作用，点名在此。

### 6.3 其余世代位

见 §7：`hbtextline` / `pc` / `wic_shim` / `bridge` / `pf` / `windowsbase` / `provider` / `dwf` **逐位未动**（本件只写 `win32_x11.c`）。

---

## 7 ⑤ 新 `win32shim` sha16 · 世代位表 · `inputs_fp`

**新 `win32shim` = `33352e5797031999`**（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`，**327,248 B**；`build-shim.sh` 0 error；唯一告警是 `win32_misc.c:224` 的**既有** `-Wmisleading-indentation`，本件一字未碰那个文件）。

| 位 | 值（开工 → 收工） | 动？ |
|---|---|---|
| `bridge` | `feef049e9d0e313a` → 同 | — |
| `pc` | app-local（**读数绑的那份**）`56ee75ced8d6aece` → 同 | — |
| `pf` | `2a5b7641f6fba0fb` → 同 | — |
| `windowsbase` | `2e4e46e539a72cd7` → 同 | — |
| `provider` | `1f9511a7ef395bfe` → 同 | — |
| **`win32shim`** | `24e906c194903c8b` → **`33352e5797031999`** | **✅ 本件（唯一）** |
| `wic_shim` | `f7b3026c8c019be2` → 同 | — |
| `hbtextline_shim`（源件） | `921ba9c65e9fb3be` → 同 | — |
| `dwf` | `de2d555105b7d04b` → 同 | — |

⇒ **表外位移：无**（"`#50` 位移多一位"＝ `win32shim`）。
⚠️ **两条必须点名的旁证**（**不是本件**）：① 会话期间 `build/PresentationCore.Linux/bin/Release/PresentationCore.dll` 已被**别的车道**重建（`W86A` 收工时是 `eb452af9a1c1cfae`，本件 `0106` 那趟读到 `5aa6361a5ba02991`）——`0106` 的读数**绑的是后者**（探针 app-local 表已印）；② 同一条树上有 `W85A`/`W88A`/`W90A` 三条车道在跑（槽实测 `HEAVYSLOT=ACQUIRED waited=89s`），本件所有读数都**逐趟印五件 sha16**，可复核"没被换件"。
`inputs_fp` 与登记表**不在本车道写域**（派单书：登记表/冻结 = 主控）⇒ 本件只报件位，**不代跑 `close-wave.sh`/`verify-all.sh`/`integration-wave.sh`**（派单书禁止）。

---

## 8 ⑥ `NOINFO` 清单（既不算绿也不算红）

1. **`M3×R2` 的"几何卡在最大化"（2/15）真因**：只量到"窗态已还原、几何未收回"，**没有**做 frame/client 分离的归因（`H` 批加了 frame 几何读数但那 5 趟全绿 ⇒ 没抓到现场）⇒ `NOINFO`（已登记为新待查项）。
2. **`WM` 是否真按 `_NET_WM_STATE(MAXIMIZED)` 约束拖拽/贴边**：本件只判"状态与还原"，不判 WM 的其它行为。
3. **`windowsbase`/`pf`/`pc` 的"跨车道重建"对本件读数的影响**：`pc`（Release）在会话中被别人换过；本件的 hc 读数跑的是 **app-local 副本**（`56ee75ced8d6aece`，逐趟印），但**没有**做"同一趟换 pc"的 A/B ⇒ `NOINFO`。
4. **`0104` 的 `M3`×`N1`（外部最大化后最小化）**：本件未测（`N1` 只测了常态最小化）。
5. **外部** `_NET_WM_STATE` **最小化**（`_NET_WM_STATE_HIDDEN` 由外部写入）：本件只采纳"最大化"两位 ⇒ 未测、未改。
6. **多 WM 泛化**：只在 `xfwm4` 上实测（`--compositor=off`）；其它 WM 的次序/属性写法未测。
7. **`PropertyNotify` 的额外 X 往返对交互延迟的量化**：只做了定性判断（与既有 `XTranslateCoordinates` 同量级），**没有**帧时/输入延迟读数。
8. `0106` 的 `late` 臂语义（"只问一次 vs 问了不写回"）：沿用 W82A 的 `NOINFO`，本件**未重测**。

---

## 9 ⑦ 内存三值 ＋ `loadavg`（纪律要求）

| 项 | 值 |
|---|---|
| `MemAvailable` 开工（10:07） | **2,571 MB** |
| 最低观测 | **1,988 MB**（各臂 `MEMAVAIL_MB` 现算的最小值） |
| 收工（11:54，读数全部取完之后） | **2,572 MB** |
| 77/78 趟臂的 `MEMAVAIL_MB` 范围 | 1,988 – 2,744 MB |
| `loadavg` 开工 / 峰值 / 收工 | **2.80** / **2.80**（开工那一刻；本件自己的臂内观测范围 **0.20 – 2.12**） / **1.18** |
| `oom_kill`（`/proc/vmstat`） | **全程 0**；无一条样本被剔为 `oom=1` |
| `HEAVYSLOT=NOINFO low-memory` / `MAXHOLD_KILL` | **0 条**（一条 `rc=124` 是**我自己的仪器挂死**，见 §11，**不是**读数） |
| 收工残留 | 本车道的 `dotnet`/应用/Xvfb/xfwm4 **全部按 PID 收干净**（`:39` Xvfb 1658115、xfwm4 1658558、`:41` Xvfb 1816947）；**零 `pkill -f`** |

---

## 10 ⑧ 大白话小结（≤6 行）

1. **WM 单方面把窗口最大化，应用根本不知道**——它自己那份"我最大化了"的记录还是"普通窗"，所以"还原"这个动作在它看来是"没事发生"（双击那条路更糟：它把"还原"当成了"再最大化一次"）。
2. **根因在 shim**：`_NET_WM_STATE` 是 X 侧窗口状态的权威，WM 改它时**不走任何 Win32 入口**，而我们的 shim **收到了这条事件却当成"没用"丢掉**。
3. **修法**：收到 `_NET_WM_STATE` 变化时，**把 X 说的状态抄进我们自己的记录，并按 Win32 规矩补发一条 `WM_SIZE`**，让应用状态位跟上；**重复的就不做**（应用自己发起的最大化不会被重复处理）。
4. **结果**：外部最大化后 **双击 13/13 能还原**、**自带还原按钮 15/15 窗态还原**（几何 13/15，2 趟卡住=新登记的残余）；**把修法撤掉就回到 3/3＋3/3 全还原不了**；应用自己发起的 26/26 一点没坏。
5. **代价**：只动 `win32_x11.c` 一个文件、只换 `win32shim` 一位（`24e906c194903c8b → 33352e5797031999`），文本行/最小化/其它八位一位未动。
6. **诚实的两条**：我**推翻了自己**判据里"样式守卫是堵点"那句（实测那半不是必须的）；`0106` 的仓内仪器本趟报了**假 NOINFO**（探针 stdout 块缓冲），我用自己的侧读补上四格。

---

## 11 仪器自伤 / 违纪 / 推翻既有结论（如实入册，不辩解）

1. **仪器挂死（一条 `rc=124`，已定位）**：第一版批量臂在 `AFTER_R2` 之后挂住。`bash -x` 现场抓到根因：`xwininfo -id <wid>` 的**普通**输出里**没有** `Parent window id` 那一行（只有 `-tree` 才有）⇒ 我用来取"WM 的 frame"的 `PAR` **恒为空** ⇒ `xwininfo -id ''` 退化成**交互式选窗**（读 stdin，永不 EOF）⇒ 整批挂在那一行。**修法**：`-tree` ＋ 空值守卫。**该批的 5 趟不进分母**（`HEAVYSLOT released rc=124`）。
2. **第一版驱动把 `timeout` 放在槽外面** ⇒ 槽排队 40 s 时应用只活 8 s，被读成"窗口消失"⇒ 差一点变成一条**假读数**。改成"外层只负责进槽、内层计时"。
3. **判据里的一条机制断言被我自己的实验推翻**（§5.4）——`criteria.md` 原文保留，报告里点名更正。
4. **一次收窄**（§4.4）：第一版采纳会清最小化位，落地前删掉（会破坏"应用自己最小化"那条路）。
5. **未按仓内仪器判词出四格**（§6.2）：我**没有**把它读成红，而是点名"仪器假 NOINFO"＋自己侧读补上，两件事都留档。
6. **零 `pkill -f`**（全程按 PID）；Xvfb/xfwm4/应用按 PID 收。**别人的进程一个都没碰**（`ps` 里 `DISPLAY=:37/:38` 的 hc 应用属 `W85A`/`W90A`，只读不碰）。
7. **槽排队的等待**占了本件不少墙钟时间（实测最长 `waited=89s`），本件**不绕槽**（派单书纪律）。

---

## 12 复现（命令级）

```bash
# 判据（先写）      cat $HOME/w89a/criteria.md          # sha16 f9c343e42a7e6f7f
# 装置              bash $HOME/w89a/bin/xup.sh          # :39 = Xvfb + xfwm4（按 PID 收）
# 构建 shim         (cd $R/src/WpfGfx.Linux.Native && ./build-shim.sh)   # ⇒ 33352e5797031999
# 部署到两套件      cp -f bin/libwpfwin32.so $HOME/w89a/app/ $HOME/w89a/probeapp/
# ① 探针臂（外部）  bash $HOME/w89a/bin/probe-arm.sh <tag> ext 34     # STATE=Maximized + r_ok=1
# ① 探针臂（自发）  bash $HOME/w89a/bin/probe-arm.sh <tag> app 34     # 对照
# ① hc 点击臂       bash $HOME/w89a/bin/hc-arm.sh <tag> M3 R1         # 外部 ⇒ 双击还原
#                   bash $HOME/w89a/bin/hc-arm.sh <tag> M3 R2         # 外部 ⇒ 自带还原按钮
#                   bash $HOME/w89a/bin/hc-arm.sh <tag> M1 R1         # 对照（应用自发）
#                   bash $HOME/w89a/bin/hc-arm.sh <tag> N1 na         # 最小化（零回归）
#   批量（一次进槽跑 N 趟，每趟一个全新进程树）：
#                   bash $HOME/w89a/bin/hc-batch.sh t1:M3:R1:0 t2:M3:R1:1 …
# 反极性            见 §5.2（cp .orig ⇒ build ⇒ sha 回 24e906c194903c8b）
# 0106 四格         bash $HOME/w89a/bin/w8106-inner.sh :41        # 已在槽里调；裸 Xvfb
```
读数一律落 `$HOME/w89a/run/<tag>/`（`probe.txt` = 判词行、`app.log` = 应用与 shim 诊断、`wstate.txt` = 探针逐行）。

本报告 sha16 = `675779b2fc2c30ee`（口径：`head -n -2 W89A-report.md` 的全部字节 —— 即**不含**本行与其前那一个空行；现场 `sha256sum` 现算，无手抄）

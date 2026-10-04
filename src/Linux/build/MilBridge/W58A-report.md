# W58A 报告 —— 修「窗口比屏幕大 ⇒ WM 自动最大化 ⇒ 拖不动/缩不了」

> 车道 **W58A**｜2026-09-20 22:47→23:2x +0800｜kernel `6.8.0-138-generic`｜`nproc=3`
> 仓根 `$R = /home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> 写域：`src/WpfGfx.Linux.Native/src/{win32_x11.c,win32_core.c,win32_internal.h}` ＋ 本报告。
> **零 `upstream/**`、零 `build/**` 判据件、零 `verify-all.sh`、零 `docs/**`、零 `KNOWN-DEFECTS.md`、零仓外 hc 源码。**

## 结论在前

1. **缺陷已修**：800×600 屏上**修后** `_NET_WM_STATE` 只剩 `_NET_WM_STATE_FOCUSED`
   （修前 = `MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED`），客户区 **784×560 @ +13+49**（标题栏整个在屏内），
   `xdotool windowsize 740 510` **生效且 8/8 次采样保持**。
2. **反极性成立**：同一 display、同一 WM、同一应用，**只换回修前 `.so`**
   （`c2674871b09e8e0e`）⇒ `MAXIMIZED_*` 回来、改尺寸 8/8 无效、`windowmove` 无效。可归因。
3. **大屏不动**：1280×1024 上修后仍是 **800×600 @ 245,241**、`windowsize 900x700` 生效；
   `[WMSIZE_DIAG]` 里**一条钳制行都没有**（只有 `WM_GETMINMAXINFO` 行）⇒ 小屏逻辑没有误伤大屏。
4. **零回归**：W55A 最小点击腿 `alive=yes`、两步 `AE>0`；**完整 9 击腿修前/修后逐行相同**
   （唯一差异是 TextBox 那步 `AE 7647 vs 7677`，见 §3.2）；小屏上三次点击全部 `AE>1e5`；
   `--abi` 布局自检全通过；同一源码二次构建 `.so` sha16 **逐位相同**。
5. **推翻了派单书里的四句话**（§4.1）：`WM_PROTOCOLS` 其实早就设了；`WM_GETMINMAXINFO` 的
   `case` 修前是**死码**；**应用根本没请求 800×600**（那是本 shim 自己的 `CW_USEDEFAULT` 兜底值）；
   「高 ≤ 屏高 − 29」这个判据**不够**（xfwm4 实测阈值是 **−34**）。

---

## §0 环境与现场

| 项 | 读数 |
|---|---|
| 车道 / 时间 | `lane=W58A`｜2026-09-20 22:47:08 → 23:2x +0800 |
| kernel / `nproc` | `6.8.0-138-generic` / 3 |
| `MemAvailable` | 开工 **2434 MB**（22:47）／最低 **2174 MB**（22:58 首次试读；三格硬化后复跑的最低值是 `B_800_pre` 的 2636 MB）／收工 **2813 MB**（全程未触发 `<1200 MB` 等待，重活一次只跑一个） |
| `loadavg` | 开工 `0.51 0.40 0.36`／峰值 `1.74 1.27 0.86`／收工 `1.02 1.09 1.00` |
| 显示（**全部自建**） | `:191` = `Xvfb 800x600x24` ＋ `xfwm4 --compositor=off`；`:192` = `1280x1024` 同构；`:193` = WPF 无关对照件 `xctl` 用；`:194/:195/:196` = 建窗诊断/点击腿（用完即拆） |
| 用户桌面 | **未碰**。`:10` 是这台机的真实桌面（1920×1080），其 `xfwm4`（pid 5209）全程未动；收工时 `pgrep -x Xvfb` = 空、`pgrep -c -x dotnet` = 0 |
| 私有应用目录 | `$HOME/w58a/app`（`cp -a` 自 `/home/links-dev/hc-linux/.../bin/Debug/net10.0`）＋ 修前副本 `$HOME/w58a/app-pre` |

### 五件 sha16（开工 = 从共享 app 目录拷来的原样）

| 件 | 开工（$HOME/w58a/app，与共享目录同值） | 收工（$HOME/w58a/app） |
|---|---|---|
| `libwpfwin32.so` | `c2674871b09e8e0e`（299,120 B） | **`054037aadfd7d192`**（304,016 B） |
| `wpfgfx_cor3.so` | `e3ea092010734f44` | `e3ea092010734f44`（未动） |
| `PresentationCore.dll` | `9465f9dce39e2dfc` | `9465f9dce39e2dfc`（未动） |
| `PresentationFramework.dll` | `1011da6390c3bf1e` | `1011da6390c3bf1e`（未动） |
| `WindowsBase.dll` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7`（未动） |

⚠️ **交接项（不在我写域内，我没动）**：共享应用目录 `/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0/libwpfwin32.so`
仍是 **`c2674871b09e8e0e`（旧件）**；仓内 `build/MilBridge/tests/*/bin/**`、`samples/WpfFeatureProbe/bin/**` 的 4 份副本是更旧的 `abf6879c027c5e73`。
权威新件在 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = `054037aadfd7d192`。**同步与否由主控裁决。**

报告自身 sha16 = **`1a949ca152d11548`**
> **口径（可复算）**：删掉**上面那一行**（`报告自身 sha16 = …`）后的整份文件 sha256 取前 16 位小写十六进制。复算：
> `sed '/^报告自身 sha16 = /d' build/MilBridge/W58A-report.md | sha256sum | cut -c1-16`

---

## §1 改了什么

### 1.0 选了哪条落点：**shim**，不是 `src/WpfGfx.Linux/Windowing/**`

证据（不是偏好）：产品应用目录 `$HOME/w58a/app` 里**没有 `WpfGfx.Linux.dll`**
（`ls | grep -i wpfgfx` 只有 `wpfgfx_cor3.so`），窗口是 `libwpfwin32.so` 建的
—— 建窗日志 `[CREATE_DIAG] CREATE xid=0xa00004 … xywh=0,0,800x600` 就是 shim 打的，
且 `xprop` 里 `WM_CLASS` 出现前/后、`WM_PROTOCOLS` 的有无与 shim 代码逐行对应。
⇒ 托管 `Windowing/**` 那条路**不在本产品路径上**，改它等于修不着。

### 1.1 三处文件（before → after）

| 文件 | before sha16（B） | after sha16（B） | 增量 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `e3e1b3e10c88f6fe`（54,631） | **`4e6feb41158fcbcf`**（65,451） | +10,820 B |
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `e1edbd04113c9125`（78,481） | **`5a920e03b05f937d`**（90,874） | +12,393 B |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `472e6560024f758c`（24,241） | **`b22602c5e396c828`**（26,244） | +2,003 B |

落地前逐件 `cp -p` 备份在 `$HOME/w58a-backup/`（`win32_x11.c` 备份 sha16 = `e3e1b3e10c88f6fe`，与 B 相同）。
**未手改任何生成物**（这三份都是手写源码，本波不涉生成物）；**`win32_abi.h` 未动**（新增的 `WPF_MINMAXINFO`
按写域边界定义在 `win32_internal.h:503-529`，理由写在该处注释里，并带两条 `_Static_assert`）。

### 1.2 逐处改动与理由

#### （a）屏幕/工作区读数 ＋ 尺寸上限 ＋ X 提示 —— `win32_x11.c`

| 位置 | 内容 |
|---|---|
| `:134-141` | 新增 4 个原子：`_NET_WORKAREA`／`_NET_WM_WINDOW_TYPE`／`_NET_WM_WINDOW_TYPE_NORMAL`／`_NET_WM_PID` |
| `:175-179` | 在既有的 `wpf_x11_ensure()` intern 块里一起 intern |
| `:1113-1126` | `WPF_DECOR_RESERVE_W_DEFAULT 16` / `_H_DEFAULT 40` ＋ `wpf_decor_reserve()`（**`WPF_LINUX_DECOR_W/H` 可覆盖**；0/负/垃圾值 ⇒ 回默认，绝不静默变「不限制」） |
| `:1128-1161` | `wpf_x11_workarea()`：读 `_NET_WORKAREA` 第一格；无 WM/无该属性 ⇒ **退化为屏幕尺寸**（＝「没有 WM 就不会加装饰」）；无 X ⇒ 全 0 |
| `:1163-1180` | `wpf_x11_client_size_limit()` = 工作区 − 装饰余量；**返回 0,0 = 不限制**（无 X），调用方据此**不钳** |
| `:1198-1242` | `wpf_x11_apply_wm_hints()`：`XSetWMNormalHints(PMinSize|PMaxSize)` ＋ `XSetClassHint` ＋ `XWMHints(InputHint=True)` ＋ `_NET_WM_WINDOW_TYPE=NORMAL` ＋ `_NET_WM_PID` |

#### （b）钳制**策略** —— `win32_core.c:446-556`

- `clamp_toplevel_extent_flags()`（`:489-513`）：**只对顶层窗**（`is_message_only` 跳过、`parent != NULL` 跳过、
  `WS_CHILD` 跳过），**只缩不放**，**只把负原点抬到 0**（正方向一律不动 —— Windows 允许窗口故意伸出屏幕右边，
  拉回来是另一处行为改变）；上限来源**唯一** = `wpf_x11_client_size_limit()`。
- `clamp_toplevel_extent()`（`:515-532`）：改尺寸路径用，从窗口表快照顶层判定后**先解锁**再问 X
  （`wpf_x11_ensure` 内部要取 `g_wpf.lock` ⇒ 持锁调用会自锁）。
- `wpf_wmsize_diag()`（`:468-487`）：`WPF_LINUX_CREATE_DIAG=1` 下 ≤40 行 `[WMSIZE_DIAG]`，**只打印**。
- `fill_minmaxinfo_defaults()`（`:534-556`）：按 Win32 语义填 `ptMaxSize=工作区`／`ptMaxPosition=工作区原点`／
  `ptMinTrackSize=1×1`／`ptMaxTrackSize=钳制上限`。

**为什么钳在「建窗/改尺寸」这一层（而不是托管侧，也不是 X 层里各钳一半）**：

1. **必须早于 `XMapWindow`**：xfwm4 的自动最大化发生在 **map** 那一刻，判据是「帧装不进屏幕」。
   实测：窗口一旦以 800×600 被 map，WM 已经最大化，`windowsize`/`windowmove` 到那时**全无效**（§2 B 格）。
2. **必须同时改 shim 自己的窗口表**：`GetClientRect`/`GetWindowRect` 是托管侧布局的读数来源；
   只改 X 侧会变成「我们以为 800×600、实际 784×560」。⇒ 三条改尺寸入口（建窗 `:590-598`、`MoveWindow` `:839`、
   `SetWindowPos` `:873-879`）走**同一个**函数。
3. **`SetWindowPos` 只钳「调用方真的在改」的那一半**（`SWP_NOSIZE` ⇒ 不钳尺寸、`SWP_NOMOVE` ⇒ 不动原点）：
   `SWP_NOSIZE` 那条路上尺寸可能正是 **WM 自己**给的（最大化态下 ConfigureNotify 改过），去「纠正」会与 WM
   打架（我们缩、WM 再最大化 ⇒ 震荡）。
4. **取舍写在代码里（`:1097-1107`）**：本处钳制的**目的不是**把用户要的 800×600 改成 784×560，而是
   **别让 WM 认为这窗装不下**。Windows 上装饰由 USER32 画、窗口可以超出屏幕；Linux 上「超出屏幕」这个状态
   不存在，WM 只有两种做法：最大化（我们遇到的）或裁掉装饰（更糟）。代价（如实登记）：小屏上应用**客户区**
   比它请求的小（该拿 `WM_SIZE` 自适应），而 `Window.Width/Height` 属性仍是应用设的值 ——
   与 Windows 上「WM 改了窗口大小」同一形态（WPF 布局跟的是客户区）。
5. **装得下时一个像素都不动**：1280×1024 上 `[WMSIZE_DIAG]` **零条钳制行**（§2 C 格），读数与修前逐字相同。

**装饰余量 16/40 的来历**（不是拍的）：WPF 无关对照件 `xctl`（`$HOME/w58a/bin/xctl.c`）在
800×600 ＋ xfwm4 上实测阈值 —— 见 §2 D 格：`MAXIMIZED_HORZ ⟺ 客户区宽 ≥ 屏宽 − 10`、
`MAXIMIZED_VERT ⟺ 客户区高 ≥ 屏高 − 34`（xfwm4 实际装饰 = `_NET_FRAME_EXTENTS 5,5,29,5`）。
⇒ 安全余量必须 **>10 / >34**；取 **16/40** 给别的 WM/主题留余量。**建窗时没有帧可问**
（WM 是 map 时才 reparent），所以只能是保守常数 ＋ env 覆盖。

#### （c）`WM_GETMINMAXINFO`：**问一声** ＋ 填默认值 ＋ 落成 X 提示 —— `win32_core.c:642-676`、`:1413-1424`

- **建窗路径**（`WM_CREATE` 之后、**首次 map 之前**）：先填 Win32 默认值 → `wpf_dispatch_to_window(hwnd, WM_GETMINMAXINFO, 0, &mmi)`
  让窗口过程回填（上游 `Window.cs:2455-2457`/`4244-4252` 明确支持「CreateWindowEx 期间同步收到」）→
  把**结果**（钳到 X 合法区间：`min ≥ 1`、`max ≤ 上限`、`min ≤ max`）落成 `WM_NORMAL_HINTS`。
- **`DefWindowProcW` 的 `case WM_GETMINMAXINFO`**：由 `return 0;`（什么都不填）改成 `fill_minmaxinfo_defaults(lParam)`。
  **为什么「空返回」比修前更坏**：托管侧 `Window.WmGetMinMaxInfo`（upstream `Window.cs:4876-4888`）把收到的
  `ptMaxSize/ptMaxTrackSize` **无条件**存成 `_windowMaxWidthDeviceUnits`/`_trackMaxWidthDeviceUnits`，
  布局的最小/最大尺寸据它算 ⇒ 给它**全 0** 的结构体会把「窗口最大尺寸」缓存成 **0**。
- `_MOTIF_WM_HINTS` **故意不设**：它的语义是「请去掉装饰」，与本缺陷方向相反（我们要的是「装饰装得下」）。

---

## §2 四格读数表（每格 = 一次独立应用启动）

### A 格｜800×600 屏（**修后** `libwpfwin32.so 054037aadfd7d192`）

| 判据 | 读数 | 出处 |
|---|---|---|
| display / screen | `:191`｜`Xvfb 800x600x24` ＋ `xfwm4`｜`_NET_WORKAREA = 0,0,800,600` | `logs/A_800_post/rootprops.txt` |
| `_NET_WM_STATE` | `_NET_WM_STATE_FOCUSED`（**无 `MAXIMIZED_*`**） | `marks.txt` `NET_WM_STATE_BEFORE_SIZE/AFTER_SIZE` |
| 客户窗几何 | **784×560**，`Absolute upper-left (13,49)`（几何行：`784x560+5+29  +13+49`） | `tree.txt` / `geo.txt` |
| 帧（WM 装饰） | 父帧 **794×594 @ +8+20`**（≤ 800×600 ⇒ 装得下）；标题栏子窗在帧内 `+0+0` | `tree.txt` |
| **Y ≥ 0** | 客户窗 abs Y = **49**；帧 abs Y = 20 ⇒ 标题栏完整在屏内（截图可见三个按钮） | `xwininfo -id` / `before_size.png` |
| `xdotool windowsize 740 510` | **生效**：8/8 次采样 = `740x510`（`SIZE_HELD=yes`） | `marks.txt` `size_t=1…8` |
| `xdotool windowmove 12 20` | **生效**：帧 → `+8+20`，客户窗 `(17,49)` | `geo.txt AFTER_MOVE_12_20` |
| 新增 X 提示 | `WM_NORMAL_HINTS: min 1 by 1 / max 784 by 560`；`WM_CLASS(STRING) = "HwndWrapper[HandyControlDemo;;…]"`；`WM_HINTS: Client accepts input or input focus: True`；`_NET_WM_WINDOW_TYPE = _NET_WM_WINDOW_TYPE_NORMAL`；`_NET_WM_PID = 72875`；`WM_PROTOCOLS: WM_DELETE_WINDOW`（**修前就有**，见 §4.1） | `xprop.txt` |
| `_NET_WM_NAME` | `"HandyControlDemo"` | `marks.txt` |
| 截图 | `$HOME/w58a/logs/A_800_post/before_size.png`（帧内完整 UI）／`after_size.png`（740×510）／`after_move.png` | — |
| 钳制留痕 | `[WMSIZE_DIAG] CreateWindowEx: req=800x600@0,0 → sent=784x560@0,0 (limit=784x560)` ×5（5 个非 message-only 顶层窗）；每窗一条 `WM_GETMINMAXINFO: 默认 min=1x1 max=784x560 → 窗口过程回填 min=1x1 max=784x560 → X 提示 min=1x1 max=784x560 (limit=784x560)` | `logs/resize800/diag.log` |

### B 格｜800×600 屏（**反极性 = 修前** `libwpfwin32.so c2674871b09e8e0e`，同 display/同 WM/同应用）

| 判据 | 读数 |
|---|---|
| `_NET_WM_STATE` | `_NET_WM_STATE_MAXIMIZED_HORZ, _NET_WM_STATE_MAXIMIZED_VERT, _NET_WM_STATE_FOCUSED` |
| 客户窗几何 | **800×576 @ (0,24)**（`800x576+0+24  +0+24`），父帧 **800×600 @ +0+0**（＝屏大小） |
| 标题栏 | 帧内标题栏子窗在 `+0+-5` ⇒ **上边 5 px 在屏外**（按钮 `21x29+779+-5` … `21x29+0+-5`）；`_NET_FRAME_EXTENTS = 0,0,24,0` |
| `xdotool windowsize 740 510` | **无效**：8/8 次采样恒 `800x576`（`SIZE_HELD=no`），`AE_SIZE=0` |
| `xdotool windowmove 12 20` | **无效**：恒 `(0,24)`，`AE_MOVE=0` |
| X 提示 | `WM_NORMAL_HINTS`/`WM_CLASS`/`WM_HINTS`/`_NET_WM_WINDOW_TYPE`/`_NET_WM_PID` **五条全缺**（`grep -c` = **0**）；客户窗在 `xwininfo -root -tree` 里类名是空 `()` |
| 截图 | `$HOME/w58a/logs/B_800_pre/after_move.png`（内容被屏幕下边切掉、标题栏被上边切掉） |

### C 格｜1280×1024 屏（**修后**，同一件）

| 判据 | 读数 |
|---|---|
| `_NET_WM_STATE` | `_NET_WM_STATE_FOCUSED`（无 `MAXIMIZED_*`） |
| 客户窗几何 | **800×600 @ (245,241)**（`800x600+5+29  +245+241`）⇒ **没有因为小屏逻辑被改小** |
| `xdotool windowsize 900 700` | **生效**：8/8 次采样 = `900x700` |
| `xdotool windowmove 12 20` | 生效：客户窗 `(17,49)` |
| `[WMSIZE_DIAG]` | **零条钳制行**；只有 `WM_GETMINMAXINFO: … max=1264x984`（×5）⇒ 未钳 |
| `WM_NORMAL_HINTS` | `min 1 by 1 / max 1264 by 984`（= 1280−16 / 1024−40） |
| 截图 | `$HOME/w58a/logs/C_1280_post/*.png` |

### D 格｜WPF 无关对照（`xctl`，800×600 ＋ xfwm4）—— 阈值与「提示能不能防住」

同一份 6 秒窗口，只改请求尺寸：

| 请求客户区 | `_NET_WM_STATE` | 结果 |
|---|---|---|
| 800×600 | `MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED` | 客户区被改成 `800x576+0+24` |
| 800×576 | `MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED` | 同上 |
| 800×500 | `MAXIMIZED_HORZ, FOCUSED` | 宽被 WM 收到 `790`，仍标 HORZ 最大化 |
| 789×400 | `FOCUSED` | 不动 ✓ |
| **790×400** | `MAXIMIZED_HORZ, FOCUSED` | **阈值：宽 ≥ 790 = 屏宽−10** |
| 700×565 | `FOCUSED` | 不动 ✓ |
| **700×566** | `MAXIMIZED_VERT, FOCUSED` | **阈值：高 ≥ 566 = 屏高−34**（客户区被收到 566） |
| 800×600 **＋`PMaxSize=(32767,32767)` 提示** | `MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED` | ⇒ **`WM_NORMAL_HINTS` 的 max 提示挡不住自动最大化**；780×560 带提示则不最大化 |

⇒ 两条结论：① 修法的**必要部分**是「别把装不下的尺寸送出去」（钳制）；② 只补 X 提示**修不好**这个缺陷。

---

## §3 零回归

### 3.1 最小点击腿（判据 4 原文）

`W55A_APP=$HOME/w58a/app W55A_STEPS="nav1 tab3" bash $HOME/w55a/bin/leg.sh w58a-leg :195 A`
（mode A = 仪器全关；`:195` = 腿自建的无 WM `Xvfb 1280x1024`）：

- `WINGEOM … X=240 Y=212 WIDTH=800 HEIGHT=600`（**与 W55A 参考几何逐字相同** ⇒ 我改的东西没有挪窗/改窗）
- `STEP T1-nav1 alive=yes AE=225596`、`STEP T2-click-TabItem3 alive=yes AE=182274` ⇒ 两步 `AE>0` ✓
- `FINAL alive=yes clicks=2 nwin=7`、`SIGNATURE stackoverflow=0 unhandled=0 win32exc=0 clearchildren=0 setfocus=0`

### 3.2 完整 9 击腿 **A/B**（修后 vs 修前，同 display `:196`、同参数）

| 读数 | 修后 `054037aadfd7d192` | 修前 `c2674871b09e8e0e` |
|---|---|---|
| `WINGEOM` | `X=240 Y=212 WIDTH=800 HEIGHT=600` | 同 |
| T1-nav1 / T2-nav9 / T5-nav10 | `AE=225596 / 73899 / 23419` | **逐字相同** |
| **T3-click-TextBox** | `AE=7647` | `AE=7677`（**唯一差异**，Δ=30 px ≈ 800×600 的 0.006%，判为插入符闪烁相位噪声） |
| T6-ComboBox → 弹层 | `nwin 7→8`、`POP_GEOM abs=(559,356) wh=413x274` | **逐字相同** |
| T7-popitem / T8-nav2 / T9-TabItem3 / T10-nav3 | `21112 / 75531 / 182269 / 0` | **逐字相同** |
| `FINAL` | `alive=yes clicks=9 nwin=7 lines=0` | 同 |
| `SIGNATURE` | 全 0 | 全 0 |

### 3.3 小屏（800×600）可交互性抽查

`logs/click800/marks.txt`：三次点击 `AE = 199225 / 105766 / 103405`，`alive=yes` 到最后，`app.log` 0 字节（无异常）。
（⚠️ 坐标是我按截图估的：第三次本想去「组合框」页，实际选中了「文本框」页 —— 这不影响判据「能点」，但如实记录。）

### 3.4 弹出层（顶层窗里的 `WS_POPUP`）单测 A/B

同一 `:191`（带 WM），先导航到「组合框」页再点第 1 个 ComboBox：

| 读数 | 修后 | 修前 |
|---|---|---|
| 窗口数 | `17 → 18` | `17 → 18` |
| 弹出客户端 | `0xa00008`，`413x208`，其帧 `423x242` | **逐字相同** |
| 该客户端的 `_NET_FRAME_EXTENTS` | `5, 5, 29, 5` | `not found` |
| 其 `_NET_WM_WINDOW_TYPE` / `WM_CLASS` | `_NET_WM_WINDOW_TYPE_NORMAL` / `HwndWrapper[…]` | `not found` / `not found` |
| 存活 | `alive=yes`、`app.log` 0 字节 | 同 |

⇒ **尺寸零变化**（钳制没碰它，413×208 ≪ 784×560）；两条新提示现在也落在弹层上。
**另发现（修前就有，非本波引入）**：WPF 弹层被我们当普通顶层窗 map ⇒ **xfwm4 给它加了 29 px 标题栏**（两版都有）。
按 EWMH 它现在显式自称 `NORMAL`；要让它像 Windows 一样无边框，得给 `WS_POPUP` 窗另设
`_NET_WM_WINDOW_TYPE_POPUP_MENU` 或 override-redirect ⇒ **本波不做，登记为后续**（§4.3）。

### 3.5 器械与构建自证

- `bash src/WpfGfx.Linux.Native/build-shim.sh --abi` ⇒ `结果：全部一致（编译期 _Static_assert 亦已通过）`。
- 构建确定性：同一份源码**二次构建**（第二次由 `--abi` 触发）`.so` sha16 **逐位相同** = `054037aadfd7d192`。
- **仓内原生用例（零 `dotnet`）**：`src/WpfGfx.Linux.Native/tests/queue_invariant.c` 对新 `.so` 跑出末行 `QUEUE_INVARIANT=PASS`（命令见 §5-1b）⇒ 消息队列不变量未被本波改动破坏。
- 零位移（我这一侧）：四个 `.dll`/`wpfgfx_cor3.so` 未动；`upstream/**`、`build/**`、`docs/**`、`verify-all.sh`、
  `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 一字未改（写域外，未触碰）；仓外 hc 源码未改。

---

## §4 边界、`NOINFO` 与推翻的话

### 4.1 我推翻了派单书的四句话（都有现场证据）

1. **「`WM_PROTOCOLS`＋`WM_DELETE_WINDOW` 未设置」——错。** `win32_x11.c:356-360` 修前就在设，
   修前 `xprop` 逐字：`WM_PROTOCOLS(ATOM): protocols  WM_DELETE_WINDOW`。
   真正缺的是 `WM_NORMAL_HINTS`／`WM_CLASS`／`WM_HINTS`／`_NET_WM_WINDOW_TYPE`（这四条确实全缺）。
2. **「`win32_core.c:1225` 的 `case WM_GETMINMAXINFO: return 0;` ⇒ 尺寸约束从未生效」——只对一半。**
   全仓 `grep -rn WM_GETMINMAXINFO src/` 只有三处：`win32_internal.h:56`（宏）、`win32_msg.c:469`（调试名表）、
   `win32_core.c`（那个 `case`）——**没有任何东西发这条消息** ⇒ 那个 `case` 修前是**死码**，
   把它填对**单独不会改变任何行为**。缺的是「**问一声**」（我在 `WM_CREATE` 后补了）。
   另外「空返回」的后果不是「没有约束」而是「**约束 = 0**」（§1.2c）。
3. **「示例应用窗口本身 800×600」——归因错。** 应用**没有**请求 800×600：
   `MainWindow.xaml` 只有设计期 `d:DesignWidth/Height=1400/800`，没有 `Width/Height/SizeToContent`，
   code-behind 里也没有赋值；上游 `Window.CreateHwndSourceParameters()`（`Window.cs:2613`）用
   `new HwndSourceParameters(Title, CW_USEDEFAULT, CW_USEDEFAULT)`，而 `HwndSourceParameters.cs:34-51`
   把这两个值直接落成 `_width/_height`；`Window.cs:2455-2457` 的注释写死：
   「**若 Width/Height 都没设，就按默认尺寸建窗，之后不再 resize**」。
   **800×600 是本 shim 自己的兜底**（`win32_core.c:441-442` 的 `WPF_DEFAULT_WINDOW_W/H` 经
   `normalize_extent(CW_USEDEFAULT, …)` 得到）。旁证：隐藏窗 `Window.cs:6342-6345` 逐参数传 `CW_USEDEFAULT`，
   而我们的 `[CREATE_DIAG]` 对它打出 `xywh=0,0,800x600`。
   ⇒ 本修法更深一层的意义：`CW_USEDEFAULT` 的兜底值从此**是屏幕感知的**（大屏仍 800×600，小屏 784×560）。
4. **判据「客户区高 ≤ 屏高 − 29」不够。** xfwm4 实测阈值是 **屏高 − 34**（`_NET_FRAME_EXTENTS 5,5,29,5`：
   标题栏 29 ＋ 底框 5），宽是 **屏宽 − 10**；取 −29 会在 566…570 这一段仍然最大化（§2 D 格）。
   本修法留 16/40，比两个阈值都宽。

### 4.2 `NOINFO`（算不出/没测，不当作已证）

| 项 | 状态 |
|---|---|
| WPF 的窗口过程**是否真的回填**了 `MINMAXINFO` | **不可判别**。`WmGetMinMaxInfo` 只在组合目标可用时写回，而它写回的值与我们的默认值**同源**（`GetWindowMinMax()` 取 `max(MinWidth, 收进来的 trackMin)`）⇒ 两种情形读数**完全相同**（`默认 min=1x1 max=784x560 → 回填 min=1x1 max=784x560`）。**可证的只有**：消息已发出（5/5 顶层窗各一条）、结构体不是全 0、X 提示值 = 该结构体值。 |
| 其它 WM（metacity/mutter/kwin）的行为 | **未测**（本机只有 xfwm4）。16/40 是「xfwm4 实测 ＋ 余量」，换 WM 可用 `WPF_LINUX_DECOR_W/H` 覆盖而不用改代码。 |
| 多显示器 / 非零工作区原点 | **未测**。只用了 `_NET_WORKAREA` 第一格；`ptMaxPosition` 用工作区原点（Win32 语义），多屏未验。 |
| `WindowState.Maximized`（`SW_SHOWMAXIMIZED`） | **未测**，且**已知语义缺口**：`win32_core.c:646-647` 把 `SW_SHOWMAXIMIZED` 退化为「map」，不发 `_NET_WM_STATE` 客户端消息。修前它「看起来像最大化」是因为 **WM 的自动最大化**在兜；钳制之后小屏上它会**得到合身窗而不是最大化窗**。这是**既有缺口的症状变化**，不是本波引入的新行为，但**必须登记**（§4.3）。 |
| 钳制对 WPF 布局的量化影响 | 只做了「能渲染/能点/导航换页」层级的核验（截图 ＋ `AE`）；`ActualWidth` 与 `Window.Width` 属性之差的数值化读数**未取**。 |
| `xdotool windowsize` 生效的**上限** | 只测了 740×510 / 900×700 / 700×400；未测「超过钳制上限的请求会被谁拦」（预期：X 侧 `PMaxSize` 与 shim 钳制都会拦）。 |

### 4.3 登记为**后续**（本波不做，附证据）

1. **`WindowState.Maximized` 没有发 `_NET_WM_STATE_MAXIMIZED_{HORZ,VERT}` 客户端消息**（`win32_core.c:646-647`），
   修前被 WM 的自动最大化掩盖。判据建议：`ShowWindow(SW_SHOWMAXIMIZED)` 后 `_NET_WM_STATE` 出现 `MAXIMIZED_*`。
2. **WPF 弹层被加 WM 标题栏**（§3.4，修前就有）：需要给 `WS_POPUP` 窗另设窗口类型/override-redirect。
3. **`libwpfwin32.so` 的 app-local 副本同步**：共享 hc 应用目录与仓内 4 份探针副本仍是旧件（§0 交接项）。

### 4.4 我自己踩的坑（如实留档）

1. **第一版仪器把「改尺寸无效」测成了产品缺陷**：窗口刚出现就 `windowsize`，而 WPF 启动末段自己的布局会再设一次
   800×600（被钳成 784×560）⇒ 读数像「无效」。**真因是改得太早**，改用「画面有内容 ＋ 12 s 静置」后 8/8 保持。
2. **孤儿进程污染读数**：第一版 `cell.sh`/`probe-resize.sh` 用 `( cd … && timeout … dotnet … ) &` 起应用 ⇒
   cleanup 杀的是**子 shell**，`dotnet` 变孤儿留在同一 display 上，于是 `xdotool search | head -1` 量到了**上一个实例的窗口**
   （实测：一处 `SETTLED 700x400` 是前一次实验留下的尺寸）。⇒ 改成「直接起 `timeout`（TERM 会传给 dotnet）」＋
   「只认启动前不存在的那个窗口 id」＋ cleanup 里按「本 display ＋ 本 app 目录」点杀（**不用 `pkill -f`**）。
   受影响的**只有**第一次 A 格读数，**已作废并重跑**（本报告全部读数来自硬化后的复跑）。
3. 收工前核对：`pgrep -x Xvfb` = 空、`pgrep -c -x dotnet` = 0、用户桌面 `:10` 的 `xfwm4`(5209) 未动。

---

## §5 复算命令逐条

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
D=/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0
export PATH="$HOME/.dotnet:$PATH"

# 0) 现场与件
free -m; cat /proc/loadavg; uname -r
for f in libwpfwin32.so wpfgfx_cor3.so PresentationCore.dll PresentationFramework.dll WindowsBase.dll; do
  printf "%-26s %s\n" "$f" "$(sha256sum $HOME/w58a/app/$f | cut -c1-16)"; done

# 1) 重建（改后）
bash $R/src/WpfGfx.Linux.Native/build-shim.sh          # → bin/libwpfwin32.so 054037aadfd7d192
bash $R/src/WpfGfx.Linux.Native/build-shim.sh --abi    # → “结果：全部一致”
cp -p $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so $HOME/w58a/app/

# 1b) 仓内原生用例（零 dotnet，链接新 .so）
cd $R/src/WpfGfx.Linux.Native && gcc -std=gnu11 -O1 -Isrc tests/queue_invariant.c -o /tmp/queue_invariant \
  -Lbin -lwpfwin32 -Wl,-rpath,"$PWD/bin" -lX11 -ldl -lpthread && /tmp/queue_invariant   # → QUEUE_INVARIANT=PASS


# 2) 起格（我用的常驻件；cell.sh 自己也会按需起 Xvfb+xfwm4）
bash $HOME/w58a/bin/startdisp.sh :191 800x600     # Xvfb 800x600x24 + xfwm4 --compositor=off
bash $HOME/w58a/bin/startdisp.sh :192 1280x1024

# 3) 四格（A/B/C；每格自带 _NET_WM_STATE/几何/改尺寸/移动/截图）
bash $HOME/w58a/bin/cell.sh :191 800x600  A_800_post  $HOME/w58a/app        # 判据 1
bash $HOME/w58a/bin/cell.sh :191 800x600  B_800_pre   $HOME/w58a/app-pre    # 判据 2（反极性）
WSIZE=900x700 bash $HOME/w58a/bin/cell.sh :192 1280x1024 C_1280_post $HOME/w58a/app  # 判据 3
cat $HOME/w58a/logs/A_800_post/marks.txt   # …/geo.txt  tree.txt  xprop.txt  *.png

# 3b) 钳制留痕（每次钳制/问 MINMAXINFO 一条；1280 屏应**零条钳制行**）
export PATH="$HOME/.dotnet:$PATH"; cd $HOME/w58a/app
DISPLAY=:192 WPF_LINUX_CREATE_DIAG=1 timeout 40 dotnet HandyControlDemo.dll 2>&1 | grep WMSIZE_DIAG

# 4) WM 阈值对照（WPF 无关）：gate 上 8 组请求尺寸
gcc -O1 -o $HOME/w58a/bin/xctl $HOME/w58a/bin/xctl.c -lX11
for wh in "800 600" "800 576" "790 400" "789 400" "700 566" "700 565"; do
  set -- $wh; DISPLAY=:193 $HOME/w58a/bin/xctl $1 $2 --secs 5 & sleep 2.2
  id=$(DISPLAY=:193 xdotool search --name '^xctl$' | head -1)
  echo "$1x$2 → $(DISPLAY=:193 xprop -id $id _NET_WM_STATE)"; wait; done

# 5) 零回归：最小腿 ＋ 完整 9 击 A/B（W55A 的腿，仪器全关）
W55A_APP=$HOME/w58a/app     W55A_STEPS="nav1 tab3" bash $HOME/w55a/bin/leg.sh w58a-leg :195 A
W55A_APP=$HOME/w58a/app     bash $HOME/w55a/bin/leg.sh w58a-full-fix :196 A
W55A_APP=$HOME/w58a/app-pre bash $HOME/w55a/bin/leg.sh w58a-full-pre :196 A
diff <(grep -E 'WINGEOM|^STEP|FINAL' $HOME/w55a/logs/w58a-full-fix/marks.txt) \
     <(grep -E 'WINGEOM|^STEP|FINAL' $HOME/w55a/logs/w58a-full-pre/marks.txt)   # 仅 T3 的 AE 差 30 px

# 6) 小屏可用性 ＋ 弹层 A/B（带 WM）
bash $HOME/w58a/bin/click800.sh :191 $HOME/w58a/app click800
bash $HOME/w58a/bin/pop800.sh :191 $HOME/w58a/app     pop800-fix2
bash $HOME/w58a/bin/pop800.sh :191 $HOME/w58a/app-pre pop800-pre

# 7) 收工：只拆自建的 display（按 PID），不碰用户桌面
#   pgrep -a -x Xvfb / pgrep -x xfwm4  → 逐个 kill -TERM <pid>；:10 的 xfwm4(5209) 不动

# 8) 本报告 sha16
sha256sum $R/build/MilBridge/W58A-report.md | cut -c1-16
```

---

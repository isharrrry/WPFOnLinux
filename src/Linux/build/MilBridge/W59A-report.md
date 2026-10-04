# W59A 报告 —— 修"应用自绘 chrome 失效（拖不动/最大化失效）＋ W58A 的 PMaxSize 回归 ＋ 双层窗框"

车道：**W59A**　仓根 `$R` = `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
写域：`src/WpfGfx.Linux.Native/src/{win32_x11.c,win32_core.c,win32_internal.h,win32_msg.c}` ＋ 本报告
（`win32_msg.c` **本趟未改动**，sha16 前后相同 —— 如实记：写域给了 4 个文件，我只用了 3 个。）

---

## §0 环境

| 项 | 值 |
|---|---|
| 大屏格 | `Xvfb :192 -screen 0 1280x1024x24` ＋ `DISPLAY=:192 xfwm4 --compositor=off` |
| 小屏格 | `Xvfb :191 -screen 0 800x600x24` ＋ `DISPLAY=:191 xfwm4 --compositor=off` |
| 应用私有目录 | `$HOME/w59a/app`（`cp -a` 自 `hc-linux/.../bin/Debug/net10.0`）；反极性目录 `$HOME/w59a/app-pre-full`（同一份应用，**只换 `.so`**） |
| 修前 `.so`（= 波 58 定稿件） | `$HOME/w59a/app-pre/libwpfwin32.so` = **`054037aadfd7d192`** |
| 修后 `.so`（本趟定稿） | `$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so` = **`11aa9d8fa154f20f`**（322,056 B；修前 304,016 B） |
| 五件 sha16（`$HOME/w59a/app`，开工/收工两次相同） | `libwpfwin32.so 11aa9d8fa154f20f`｜`wpfgfx_cor3.so e3ea092010734f44`｜`PresentationCore.dll 9465f9dce39e2dfc`｜`PresentationFramework.dll 1011da6390c3bf1e`｜`WindowsBase.dll 2e4e46e539a72cd7` |
| `MemAvailable` 三值 | 开工 `2873100 kB`（23:40）｜中段 `2439252 kB`（00:00）｜收工 `1931568 kB`（11:50） |
| 重活纪律 | 每次起应用都整条包进机器级槽：`bash ~/heavy-slot.sh --min-avail 1500 --max-hold 120…200 -- timeout … dotnet …`；同一时刻只跑一个应用；全程**零** `pkill -f`（按 PID） |
| 资源污染声明 | 本报告全部窗口读数都在**槽内单应用**条件下取（`HEAVYSLOT=ACQUIRED` 行留痕）。**唯一例外**、必须标注：`$HOME/w59a/logs/fix192*`、`fix192b`、`focus4/5` 三批（00:04–00:22）是**开槽纪律生效之前**跑的，当时机器上另有车道在跑（5 条车道并发）；这三批只用来说明"机制/命中码"，**不作为验收读数**，验收读数一律取自 11:40 之后带槽的 `final-191`/`final-leg`/`final-plain`/`final192`/`last-*` |
| 本报告自身 sha16 | 见 **§6**（本报告正文不含 §6 的 sha16；自指文件无法把"含本行的哈希"写进本行） |

### §0.1 逐字推翻/更正主控派单书的四句

1. **"`WM_NCHITTEST` 被 shim 吞掉：`win32_core.c:1411` 是 `case WM_NCHITTEST: return 1;`"** ——
   **指示的行不是病根**。那个 `case` 是 `DefWindowProcW` 的**默认答案**（Win32 语义：窗口过程不处理时 DefWindowProc 回 `HTCLIENT`），**改它没有任何意义**。
   真正的病是：**这条消息在整个 shim 里从来没有被发出去过** —— 全仓 `grep -rn WM_NCHITTEST src/` 只有三处（`win32_internal.h:62` 的宏、`win32_msg.c:473` 的调试名表、`win32_core.c` 那个 `case`），与波 58 的 `WM_GETMINMAXINFO` **完全同型：死码**。
   ⇒ 修法是"**问一声**"（翻译层在 ButtonPress 时先发 `WM_NCHITTEST`），见 §1.4。
2. **"根因 1：`WM_NCHITTEST` 被吞 ⇒ 应用侧拖动/最大化/缩放天然失效"** ——
   只对**一半**。`WM_NCHITTEST` 回答对了也**不会让窗口动**：Windows 上真正搬窗的是 USER32 在 `WM_NCLBUTTONDOWN` 默认处理里进的**模态 move/size 循环**，本 shim 没有那个循环。
   ⇒ 必须同时落"按 motion 自己驱动 + 走 WM 改几何"那一步（§1.4）。只回答 NCHITTEST = 修好一半。
3. **"根因 2：`PMaxSize` 设成钳制后的尺寸 ⇒ WM 侧也不许放大/最大化"** —— **方向对、影响面被我实测收窄**：
   在 1280x1024 屏上钳制上限是 1264x984 ⇒ `windowsize 1280 1024` 被切成 **1264x984**（§2 反极性格，实测），但**用户报的"不能最大化"不是它造成的** —— 见第 4 条。
4. **"① 窗口不能最大化"的真根因是第三条（派单书没写的）：`ShowWindow(SW_MAXIMIZE)` 是空操作 + `WM_SYSCOMMAND` 根本没实现。**
   应用侧"最大化"按钮走的是 `hc:Window` 的 `CommandBinding`：`WindowState = Maximized`（`HandyControl_Shared/Controls/Window/Window.cs:297`），上游 `Window.OnWindowStateChanged` 对它的**唯一**动作是 `ShowWindow(hr, SW_MAXIMIZE)`（`Window.cs:5231`），而本 shim 修前把 `SW_MAXIMIZE` 写成 `map = 1`（"退化为 map"）⇒ **按下去什么都不会发生**。实测（修前件、:192、客户区 (245,241) 时点客户区+723,+14）：`[HCIN] preMouseDown src=… < Button#ButtonMax …` ⇒ 命中链证明点到了那个按钮，`_NET_WM_STATE` 与几何**纹丝不动**。

---

## §1 改了什么（逐处；before/after sha16）

| 文件 | before sha16 | after sha16 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `5a920e03b05f937d` | `529d999e4818568d` |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `4e6feb41158fcbcf` | `050f349638bbf87e` |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `b22602c5e396c828` | `fd5d220931bebf8d` |
| `src/WpfGfx.Linux.Native/src/win32_msg.c` | `cff3189eff6c87eb` | `cff3189eff6c87eb`（**未改**） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `054037aadfd7d192` | **`11aa9d8fa154f20f`** |

改前备份：`$HOME/w59a/backup-win32_{core.c,x11.c,internal.h,msg.c}`（`cp -p`，逐字节等于改前值）。

### §1.1 【A】`PMaxSize` 不再是"钳制值"（修 W58A 的回归）

* `win32_core.c` `fill_minmaxinfo_defaults()`：`ptMaxTrackSize` 的默认值由 **"工作区 − 装饰余量"** 改为 **屏幕尺寸**（`SM_CXMAXTRACK` 的语义；新增 `wpf_x11_screen_size()` 读 `DisplayWidth/Height`）。`ptMaxSize/ptMaxPosition`（= 最大化几何）仍是工作区，未动。
* `win32_core.c` `create_window_utf8()` 的 `WM_GETMINMAXINFO` 段：把"应用回填后的 `ptMaxTrackSize`"与**我们自己填进去的默认值**比较 —— **相等 ⇒ 视为应用没声明上限 ⇒ 传 0 ⇒ 不发 `PMaxSize`**；不等 ⇒ 原样把应用的值传给 X（不再拿钳制上限顶破它）。
* `win32_x11.c` `wpf_x11_apply_wm_hints()`：`flags = PMinSize` 恒定；**只有 `max_w>0 && max_h>0` 才 `flags |= PMaxSize`**（"拿不到就不发"）。
* **钳制本身一字未动**：`clamp_toplevel_extent_flags()` 仍只作用于**建窗 / MoveWindow / SetWindowPos 那一刻**的尺寸（小屏 800x600 上建窗仍被钳成 **784x560**，§2 小屏格）。
* 为什么这么改：波 58 把"最大可拖到的尺寸"与"初始装得下"用了同一个上限 ⇒ 窗口被**永久钉死**（1280x1024 屏上实测 1264x984、800x600 屏上 784x566）。Win32 的语义里这两个是两件事。

### §1.2 【C】`_MOTIF_WM_HINTS`：自绘 chrome 的窗口"不要装饰"（消双层窗框）

* 新增 `win32_x11.c` `wpf_x11_set_decorations(hwnd, 0|1)`：写 `_MOTIF_WM_HINTS`（`flags=2` = `MWM_HINTS_DECORATIONS`，`decorations=0` = 不要标题栏/边框；`decorated=1` 时**删除**该属性回 WM 默认）。
* **实测坑（必须写进代码注释，已写）**：属性**类型必须是 `_MOTIF_WM_HINTS` 这个 atom 本身**。xfwm4 的 `getMotifHints()` 用 `XGetWindowProperty(..., req_type = 该 atom, ...)`，类型不匹配时按 X 协议"什么都不返回"（nitems=0）⇒ **静默忽略**。
  反极性实测：用 `xprop -f _MOTIF_WM_HINTS 32c -set …`（类型 = `CARDINAL`）写完之后窗框**纹丝不动**；换成类型 = atom 后**同一时刻**窗框立刻消失（`FRAME 810x634@+240+212` → `FRAME 800x600@+240+212`、客户窗从 frame 内 `+5+29` 变成 `+0+0`）。⇒ 这条**推翻**了"只能 unmap/map 才会重新装饰"的猜测，也解释了我在 00:00 那次"写了没效果"的假阴性。
* **什么时候算"自绘 chrome"**：见 §1.3（这是本趟唯一"必须自己找信号"的地方）。

### §1.3 【C 的判据】`WS_CAPTION` 那条对 hc 示例**不成立**；真正的信号是 `SWP_FRAMECHANGED`

* 派单书给的判据是"`WS_CAPTION` 不在 `style` 里 ⇒ 去装饰"。**实测对 hc 示例不成立**：建窗读数 `[CREATE_DIAG] style=0x2cf0000` 里 `WS_CAPTION(0x00C00000)` **在**（`0x2cf0000 & 0xC00000 == 0xC00000`），因为 `hc:Window` 用的是默认的 `WindowStyle=SingleBorderWindow`（它只设 `WindowChrome` 附加属性，`Window.cs:2965` 会置 `WS_CAPTION`）⇒ **该判据永不触发**（保留它作第一判据，管 `WindowStyle=None` 的窗口）。
* Windows 上"不画系统标题栏"靠的是 DWM 玻璃（`DwmExtendFrameIntoClientArea`），而本 shim 的 `DwmIsCompositionEnabled` 返回 **FALSE** ⇒ `_isGlassEnabled=false` ⇒ `WindowChromeWorker` 里那两处调用**根本不走**（grep 过：两处都在 `_isGlassEnabled` 分支内）。
* 但 `WindowChromeWorker._ApplyNewCustomChrome()` 里还有一条**与合成无关**的动作：`SetWindowPos(…, _SwpFlags)`，`_SwpFlags = FRAMECHANGED|NOSIZE|NOMOVE|NOZORDER|NOOWNERZORDER|NOACTIVATE`（`WindowChromeWorker.cs:28/246`）—— 语义是"我重算了自己的非客户区（窗框），请按新框重算"。**这就是"自绘 chrome"的可观测声明**。
* 实现：`win32_core.c` 新增 `wpf_core_note_framechanged()`（sticky 置 `w->custom_chrome`）/`wpf_core_custom_chrome()`；`SetWindowPos` 见到 `SWP_FRAMECHANGED` 时：窗口**还没 map** ⇒ 记 sticky（这就是 chrome 那条：实测 `[SHOW_DIAG] SetWindowPos a=567(=0x237)` 两次都发生在 `ShowWindow(SW_SHOW)` **之前**）；**已经 map** ⇒ 只对"已判定为自绘 chrome"的窗口刷新装饰（幂等）。
  时序限定是必要的：`HwndStyleManager.Flush()`（`Window.cs:6845-6867`）在样式真的变了时也会发一条带 `FRAMECHANGED` 的 `SetWindowPos`（实测标志位 `0x37`），那是**运行期**才发生的。
* 落地：`win32_x11.c` `wpf_x11_map()` 在 `XMapWindow` **之前**按 `wpf_core_custom_chrome()` 调 `wpf_x11_set_decorations(hwnd, 0)`（避免"先出现一层窗框再消失"的闪烁）。

### §1.4 【B】`WM_NCHITTEST` 真回答 ＋ 非客户区拖动/缩放真生效

三件事，缺一不可：

1. **问**：新增 `win32_core.c:wpf_core_nc_hit_test(hwnd, x_root, y_root)` —— 只对**顶层非 message-only 窗口**发 `WM_NCHITTEST`（lParam = 屏幕坐标，Win32 的 `MAKELPARAM` 语义）；返回 0 就按 `HTCLIENT`。子窗口/消息窗不问（坐标不同源；普通顶层窗问了也只会得到"客户区/ResizeGrip"，都是 Win32 真实语义）。
2. **路由**（`win32_x11.c` ButtonPress/ButtonRelease）：`ht != HTCLIENT` ⇒ **只发 `WM_NCLBUTTONDOWN`/`WM_NCLBUTTONUP`**（带 HT 码与屏幕坐标），**不发 `WM_LBUTTONDOWN`**；`ht == HTCLIENT` ⇒ 保持修前行为。双击标题栏自判（同 HT、≤400 ms、位移 ≤4 px）⇒ 发 `WM_NCLBUTTONDBLCLK`。
3. **搬/缩**（本趟最关键的一次修正）：
   * 修前我的第一版在**按下时**就发 `_NET_WM_MOVERESIZE` 把拖动交给 WM。实测**两个**问题：① xfwm4 收到后 grab 指针 ⇒ **双击的第二击被吃掉**（实测双击只打出 **1** 条 `[NC_DIAG] NC-PRESS` ⇒ 双击最大化失效）；② 更根本的是 —— **这条消息在本装置上根本不生效**（§4 有独立的外部工具读数）。
   * 现方案：**按下只登记**（`g_nc_*`：命中码、按下点、按下时的客户区矩形）＋ `XGrabPointer`（拖出窗口仍收得到 motion）；**第一次位移 >3 px 才真的开始**，此后每一帧按命中码算新的客户区矩形（`HTCAPTION` 只移；`HT*` 按对应边锚定），走 `win32_x11.c:wpf_x11_moveresize_window()` = **`_NET_MOVERESIZE_WINDOW`**（EWMH，WM 会把 frame 一起摆；没有 EWMH WM 时退回裸 `XMoveResizeWindow`）。拖动期间**吞掉 `WM_MOUSEMOVE`**（Win32 的模态 move loop 同样不发客户区鼠标消息）。

### §1.5 【D，本趟新发现的第三处真根因】窗口状态机：`ShowWindow` / `WM_SYSCOMMAND` / 状态位

* `win32_core.c:ShowWindow()`：`SW_MAXIMIZE`/`SW_SHOWMAXIMIZED`/`SW_MINIMIZE`/`SW_SHOWMINIMIZED`/`SW_RESTORE` 不再"退化为 map"，改调新增的 `wpf_core_window_state(hwnd, WPF_WS_MAX|MIN|NORMAL)`。
* `wpf_core_window_state()`：有 EWMH WM ⇒ 发 `_NET_WM_STATE`（ADD/REMOVE `MAXIMIZED_HORZ|VERT`）或 `XIconifyWindow`，几何交给 WM；**没有 EWMH WM** ⇒ 自己按工作区 `MoveWindow`（Xvfb 裸跑也能用）。同时记还原矩形、并在**窗口表里**置/清 `WS_MAXIMIZE`/`WS_MINIMIZE` 位。
  为什么必须写那两个位：`Window._Style` 的 getter 在 `Manager == null` 时**直接读 `GetWindowLong(GWL_STYLE)`**（`Window.cs:3242-3255`）⇒ 不写就会出现"能最大化、按**还原**没反应"（还原路径那句 `if ((style & WS_MAXIMIZE) == WS_MAXIMIZE) ShowWindow(SW_RESTORE)`，`Window.cs:5189`）。这同时也是 Win32 的真实行为。
* `DefWindowProcW` 新增：`WM_SYSCOMMAND`（`SC_MAXIMIZE/MINIMIZE/RESTORE/CLOSE`，比较前 `& 0xFFF0`）、`WM_NCLBUTTONDBLCLK(HTCAPTION)` ⇒ 最大化/还原切换。**`case WM_NCHITTEST: return 1;` 保留原样**（见 §0.1 第 1 条）。
* `win32_x11.c` `ConfigureNotify`：`WM_SIZE` 的 **wParam 不再恒为 0**，按窗口表状态发 `SIZE_MAXIMIZED(2)/MINIMIZED(1)/RESTORED(0)`。为什么必须改：上游 `Window.WmSize`（`Window.cs:4680-4740`）收到 `SIZE_RESTORED` 会把 `WindowState` 设回 `Normal` ⇒ 修前"一按最大化、WM 改完几何、我们回填时又把 WPF 的窗态掰回普通"（应用侧按钮图标/后续命令全错位）。
* `win32_x11.c` `UnmapNotify/MapNotify`：图标化在 X 侧也是 unmap，但 Win32 的**最小化不发 `WM_SHOWWINDOW(FALSE)`**。照旧发会让 `Window._isVisible=false`，而还原路径整段在 `if (_isVisible)` 里（`Window.cs:5177`）⇒ **最小化之后还原不回来**。现在图标化期间吃掉 `WM_SHOWWINDOW`，反图标化时补一条 `WM_SIZE(SIZE_RESTORED)`。

### §1.6 【本趟实测抓到并修掉的第四处】`ConfigureNotify` 的 x/y 是**父窗相对**坐标

* 现象（`focus5-192`，命中码地图）：同一个点（客户区 +400,+14）
  · 未 resize 前 ⇒ `NC-HIT ht=2`（HTCAPTION，正确）
  · 外部 `windowsize 1000 800` 之后 ⇒ **`NC-HIT ht=1`（HTCLIENT，错）**，且 `[NC_DIAG]` 里 shim 自己的 `表里矩形=0,0 1000x800`，而真实位置是 `+200+150`。
* 机制：xfwm4 连**无装饰**窗口也 reparent 进一个 frame ⇒ `ev.xconfigure.x/y` 是"在 frame 里的位置"（≈0,0），直接落表就把"客户区左上角在 root 上的坐标"（结构体注释本来就这么定义）搞成 (0,0)。而 `WindowChromeWorker` 用 `GetWindowRect()`（= 我们的表）算 `mousePosWindow = 屏幕点 − 窗口原点` ⇒ 原点错 200,150 ⇒ 标题栏那一点被算成 y=164 ⇒ `_HitTestNca` 判"客户区" ⇒ **拖动、自绘按钮全部失效**（这也解释了 00:22 那次"应用自带最大化按钮点不动"）。
* 修法：`ConfigureNotify` 里先用 `XTranslateCoordinates(client → root, 0,0)` 换成 **root 坐标**再落表、再发 `WM_MOVE`。
* 修后同一条地图（`focus6-192`）：未碰 / `windowmove` 后 / `windowsize` 后**三格全部 `ht=2`**，表里矩形依次 `240,212`、`120,90`、`120,90`（都与真实位置一致）。

### §1.7 仪器（都在实验用 env 下，**默认关**）

* `win32_x11.c:wpf_nc_diag()`：`[NC_DIAG]` 行，env `WPF_LINUX_KEY_DIAG=1` **或** `WPF_LINUX_CREATE_DIAG=1`，≤60 行。打 `NC-HIT`（每一次按键的命中码，含 `HTCLIENT`）、`NC-PRESS/RELEASE`、`NC-DRAG`（每帧的目标几何）。为什么必须有：判据"拖不动"要能区分**"没问"/"问回客户区"/"问回非客户区但 WM 不搬"**三种现场 —— 没有这行读数就只能猜（本趟我就是靠它定位到 §1.6）。
* `win32_core.c` 的 `[WMSIZE_DIAG]` 行改写为显式给出"应用**有/没有**声明上限 ⇒ X 提示 PMaxSize **已发/未发**"。

---

## §2 四格读数表（全部在槽内单应用条件、修后件 `11aa9d8fa154f20f`）

### 格 1：1280x1024 屏（修后）—— 能放大、能最大化、自绘 chrome 生效

日志：`$HOME/w59a/logs/final192/probe.txt`｜截图 `$HOME/w59a/shots/final192-*.png`

| # | 动作 | `_NET_WM_STATE` | 客户窗几何 | 结论 |
|---|---|---|---|---|
| S0 | 起窗（不碰） | `FOCUSED` | `800x600@+240+212`，`FRAME=800x600@+240+212`（parent 存在但**无装饰**） | 装饰已去（`_MOTIF_WM_HINTS = 0x2,0x0,0x0,0x0`）、`NORMAL_HINTS` **只有** `minimum size: 1 by 1`（**无 PMaxSize**） |
| S1a | `windowsize 1000 800`（起窗后 ~5 s） | `FOCUSED` | `800x600@+240+212`（**没生效**） | **冷启动期被 WM 的初始 configure 吞**（见 §4 边界①；修前件同形） |
| S1 | `windowsize 1280 1024`（再 2 s） | `FOCUSED` | `800x600@+0+0`（尺寸仍没生效、位置被 WM 挪到 0,0） | 同一冷启动窗口 |
| S2 | `windowsize 800 600` + `windowmove 200 150` | `FOCUSED` | `800x600@+200+150` | 复位 |
| **S3** | **双击应用自绘标题栏** (600,164) | **`MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED`** | **`1280x1024@+0+0`** | ✅ **真最大化**（几何=屏 + `_NET_WM_STATE` 双绿） |
| **S4** | **再双击** | `FOCUSED` | `800x600@+200+150` | ✅ 还原回原矩形 |
| **S5** | **按住自绘标题栏拖**（+90,+110） | `FOCUSED` | `800x600@+290+260` | ✅ 原点变化 |
| **S6** | **拖右下角 ResizeGrip**（+90,+70） | `FOCUSED` | **`890x670`**@+290+260 | ✅ 宽高变化 |
| **S7** | **点应用自带"最大化"按钮**（客户区右边缘−74,+14） | **`MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED`** | `1280x1024@+0+0` | ✅ 用户报的"不能最大化"修好 |

**热机后的显式放大/缩小**（`warm 6s`，`logs/mvpg-post192w/probe.txt`）：

| 请求 | 回读 | 结论 |
|---|---|---|
| `windowsize 700 520` + `windowmove 40 30` | `X=40 Y=30 WIDTH=700 HEIGHT=520` | ✅ 与请求**逐字段相等** |
| `windowsize 1100 820` + `windowmove 120 90` | `X=120 Y=90 WIDTH=1100 HEIGHT=820` | ✅ 与请求**逐字段相等**（修前件同格只能到 700x520，见 §2.2） |

另有 `logs/focus6-192/probe.txt`：热机后连续 5 次 `windowsize`（1000x800 / 1100x800 / 1200x900 / 1280x1024 / 900x700）**5/5 全部生效**（客户窗回读与请求一致）。修前件同样这 5 个请求有 1 个被 1264x984 顶破（`1280x1024`）。

### 格 2：反极性（**只换修前 `.so` `054037aadfd7d192`**，同屏同 WM 同应用）

日志：`$HOME/w59a/logs/pre192/`（点按钮）、`logs/mvpg-pre192/`、`logs/mvpg-pre192w/`

| 读数 | 修前件 | 修后件 |
|---|---|---|
| `WM_NORMAL_HINTS` | `minimum size: 1 by 1` ＋ **`maximum size: 1264 by 984`** | 只有 `minimum size: 1 by 1`（**PMaxSize 缺席**） |
| `_MOTIF_WM_HINTS` | **`not found`** ⇒ 被 WM 套一层装饰（双层窗框） | `0x2, 0x0, 0x0, 0x0` ⇒ 无装饰 |
| `xwininfo` 框架 | `FRAME=810x634@+240+212`，客户窗在 frame 内 `+5+29` | `FRAME=800x600@+240+212`，客户窗 `+0+0` |
| `windowsize 1280 1024` | 只到 **1264x984**（被 PMaxSize 顶破） | 见格 1（热机后到 1280x1024） |
| 点应用自带"最大化"按钮（客户区 +723,+14，命中链 `Button#ButtonMax`） | `FOCUSED` + 几何不变 ⇒ **什么都不会发生** | 见格 1 S7 ⇒ **真最大化** |
| 按住自绘标题栏拖 | 原点不变（拖不动） | 原点 +90/+110 |
| 双击自绘标题栏 | 无 `WM_NCLBUTTONDBLCLK`、无最大化 | 真最大化 |
| 外部 `windowsize 700 520`→`1100 820`（**无暖机**） | 小 ✅ `700x520`；大 ❌ 停在 `700x520` | 两者都 ❌（`800x600`）—— **两件同形** ⇒ 该负读数是冷启动时序，不是本趟回归（§4 边界①） |
| 同序列 **+ 暖机 6 s** | 小 ✅ `700x520`；大 ✅ **`1100x820`** | 小 ✅ `700x520`；大 ✅ `1100x820` |

### 格 3：双层窗框消失（成对：**有 caption 的窗口仍被装饰**）

| 窗口 | 应用 | `_MOTIF_WM_HINTS` | 是否被 WM 装饰 | 读数路径 |
|---|---|---|---|---|
| hc 示例主窗（`WindowChrome` 自绘 chrome，`style=0x2cf0000` **含 WS_CAPTION**） | `HandyControlDemo` | `0x2,0x0,0x0,0x0` | **否**（`FRAME==CLIENT`，`+0+0`） | `logs/final192/probe.txt` S0 |
| 普通 `<Window>`（无 chrome，`Title` 有 caption） | `samples/HelloWpf`（预编译件，**只换 `.so`**） | **`not found`** | **是**（客户窗 `667x417@+5+29`，parent `0x2004ee`，frame 内有 xfwm4 的边框子窗 `0x2004ef 5x406+0+29`） | `logs/final-plain/probe.txt` |

⇒ 成对成立：**自绘 chrome ⇒ 去装饰；有 caption ⇒ 保持装饰**。

### 格 4：小屏 800x600 不回归 W58A（修后件）

日志：`$HOME/w59a/logs/final-191/probe.txt`｜截图 `$HOME/w59a/shots/final-191.png`

```
xwininfo: 784x560@+8+20      ← 初始尺寸仍被钳到"装得下"（800−16 × 600−40）
state=[_NET_WM_STATE_FOCUSED]   ← 无 MAXIMIZED_*（W58A 的成果保住了）
_motif=[0x2,0x0,0x0,0x0]  hints=[program specified minimum size: 1 by 1]（无 PMaxSize）
windowsize 700x520 → 700x520@+8+20   ← 小屏上也能改尺寸
```

绝对 `Y=20 ≥ 0`（标题栏在屏内）✅。

### 格 5：零回归（点击/呈现腿）

`W55A_STEPS="nav1 tab3" W55A_APP=$HOME/w59a/app bash ~/w55a/bin/leg.sh w59a192 :192 A`（仪器全关）
⇒ 读数与结论见 **§2.5（收尾两格）**：`alive=yes` ＋ 两步 `AE>0`（225596 / 182274）。

---

## §3 零回归

* 点击/呈现腿（§2.5）＋ 每格截图（`$HOME/w59a/shots/`）。
* 每趟都记 `Unhandled exception` / `Stack overflow` 计数：格 1 全程 **0 / 0**（`logs/final192/probe.txt`），小屏格 0 / 0。
* `_NET_WM_NAME` 仍是 `HandyControlDemo`（格 1 S0 的 `read.sh` 行）。
* **本趟撞到的应用侧真缺陷（与本次三处修法无关，如实登记，未修）**：
  点客户区 **+150,+14**（HandyControl 顶部菜单条 `menuHeader`）⇒ 应用抛
  `System.NullReferenceException at HandyControl.Tools.ScreenHelper.FindMonitorRectsFromPoint` ← `MenuTopLineAttach.Popup_Opened`
  ⇒ 未处理异常 ⇒ 进程 `rc=134` **死**（`logs/focus4-192/app.log`）。
  该崩溃**修前件同样可复现**（不看本次改动），归 hc 侧 `ScreenHelper` + 本 shim 的监视器 API（`MonitorFromPoint/GetMonitorInfo` 返回空）这一族 ⇒ 建议单独登记（不在本车道写域）。

---

## §4 边界与 `NOINFO`

1. **`windowsize` 的"冷启动窗口"（未定性到底多长）** —— 窗口刚 map 后若干秒内发出的 `windowsize` **可能被 WM 的初始 configure 吞掉**。
   实测：无暖机 ⇒ 修前件"小听/大不听"、修后件"两格都不听"；**+ 暖机 6 s ⇒ 修前/修后都 4/4 全听**（§2 格 1/格 2）。
   ⇒ ① 这是**既存**现象（修前件同形），**不是本趟回归**；② 具体边界（到底几秒）我**没有**测出来 ⇒ **`NOINFO(冷启动窗口的确切时长)`**。产品级仪器建议**暖机 ≥6 s 或在请求后重试一次**。
   ⇒ 这条同时是主控产品级读数"1280×1024 上 `windowsize 1100 820` 回读停在 700x520"的**定性**：我在**修前件**上用**同一序列**复现了同一现象（`logs/mvpg-pre192/probe.txt`），加 6 s 暖机后两边都正常。
2. **`_NET_WM_MOVERESIZE` 在 xfwm4 上"声称支持但不生效"** —— `_NET_SUPPORTED` 里有它（`xprop -root _NET_SUPPORTED` 读到了），但外部工具在"按住左键 + 指针移动"期间把它发给 root，窗口**纹丝不动**；同一装置同一时刻发 `_NET_MOVERESIZE_WINDOW` ⇒ 立刻变成 `900x700@+400+300`；发 `_NET_WM_STATE` ⇒ 立刻最大化到 `1280x1024@+0+0`、再发 REMOVE ⇒ 还原回 `900x700@+400+300`（`logs/ewmh192/probe.txt`，工具 `$HOME/w59a/bin/wmtool.c`）。⇒ **协议声称 ≠ 实际生效**，所以拖动由我们自己按 motion 驱动。
3. **`PMaxSize` 的"应用声明"反极性（① 声明 ⇒ 发且等于声明值）只有 shim 层证据，没有端到端应用腿** ——
   · 仓内**没有**声明 `MaxWidth/MaxHeight` 的样本：`grep -rln "MaxWidth\|MaxHeight" --include=*.xaml --include=*.cs samples/` **无输出**（`HelloWpf`/`WpfFeatureProbe`/`ThirdPartyMini` 都不声明；`ThirdPartyMini` 只声明 `WindowStyle="None"`）。
   · 我没有在写域外新建 WPF 工程 ⇒ 用 **shim 层探针** `$HOME/w59a/bin/pmaxprobe.c`（dlopen 定稿件、直接调 `wpf_x11_apply_wm_hints`、xprop 读回）：
     `CASE=declared passed_max=1100x900 → program specified minimum size: 1 by 1 / program specified maximum size: 1100 by 900` ✅
     `CASE=undeclared passed_max=0x0 → program specified minimum size: 1 by 1`（无 maximum 行）✅
   · **必须标注**：这**不是端到端应用腿**，只证明"传进来的上限被原样发出/为 0 时不发"这条**契约**。
   · **探针自身的一条未解异常（如实登记）**：同一个探针进程里**第二次**调 `wpf_x11_apply_wm_hints` 时，属性**完全没写出去**（第一格正常）；交换两格顺序后"先跑的那格正常、后跑的那格无效"，**与参数无关** ⇒ 我判为**探针/多次调用**侧的假象（应用路径是"每建一个窗调一次"，实测应用主窗（进程里第 4 个窗）的 hints 正常在场）。⇒ **`NOINFO(同一进程内重复调用为何第二格无效)`**，未修（不影响验收结论，但不许当作没发生）。
4. **已知边界：应用声明的上限恰好等于默认值（= 屏幕尺寸）时，会被判成"没声明" ⇒ `PMaxSize` 静默不发。**
   例：应用写 `MaxWidth = SystemParameters.PrimaryScreenWidth`（真实写法）⇒ 与默认相等 ⇒ 约束丢掉。
   **影响面判断：很小** —— 不发 `PMaxSize` 时 xfwm4 对"整屏大小"的请求照样会自己钳（实测：1280x1024 屏上发 1280x1024 的请求得到的就是 1280x1024，不会越界），与"发一个等于屏幕的上限"几乎等价。**为什么可接受**：把"相等"当"未声明"是**保守方向**（少发一条提示 ≠ 多了限制），而反方向（把默认值当"应用声明"）就会重新落入波 58 的病根。要更精确只能让上游把"是否真的调用过 setter"这一路信息传下来（成本高，未做）。
5. **`_MOTIF_WM_HINTS` 与"双层窗框"的关系（主控问的第 3 件）** —— 语义：`flags=0x2` = `MWM_HINTS_DECORATIONS` 有效；`decorations=0` = **不要 WM 画的标题栏/边框**（函数写法 `/functions` 与 `/input_mode` 传 0，另带 1 个 0 的 status 槽，共 5 个 CARDINAL）。它与双层窗框的关系：**只要应用自绘了 chrome，WM 再加一层就是"双层"**；X11 上没有 DWM 玻璃可以"把系统标题栏藏起来"，所以只能用 MWM hints 明说"不要装饰"。波 58 注释里"故意不设"的理由（"它的语义是请去掉装饰，与本缺陷方向相反"）在**当时**是对的（那时自绘 chrome 的命中测试还没通、去掉装饰会让窗口**彻底没法拖**）；本趟把命中测试与拖动一起做完之后，去掉装饰才是对的**并且是必需的**（否则用户看到两层框）。两者不是"谁对谁错"，而是**先后依赖**：先有"能拖"，才能"去掉 WM 的框"。
6. **`NOINFO` 汇总**：① 冷启动窗口确切时长；② 同一进程内重复调用 `apply_wm_hints` 第二格无效；③ `PMaxSize` 声明态的端到端应用腿（无样本）；④ 主控产品级仪器"1280x1024 放大不听"落在**哪一段**代码（我给的定性是"WM 初始 configure 期的时序"，**没有**定位到具体某一行 —— 修前/修后同形，故判既存）。
7. **"已经最大化"态下的还原/最小化出现矛盾读数（未定性）** —— `final192` S4（双击还原）**成功**、`freshbtn` ②（双击还原）**失败**、`freshbtn` ③（点最小化按钮）**未图标化**；`maxrestore.sh` 两趟也都没点动（那两趟起始态是 xfwm4 会话恢复出来的最大化态）。差异线索：成功的 S4 其"最大化"来自双击本身，失败的那几次其"最大化"来自**按钮命令**或**WM 会话恢复**。⇒ **`NOINFO(为什么"按钮/WM 带来的最大化"之后自己这边的还原动作不发/不生效)`**；我没有继续收敛（时间与槽都用到上限），**不把它写成"没问题"**。
8. **未做（明确声明，免得读者以为做了）**：本趟**没有**跑 `verify-all.sh`（主控已在跑）；**没有**改 `verify-all.sh`/`build/**` 判据件/`docs/**`/`upstream/**`/hc 应用源码；**没有**动 `win32_msg.c`。

---

## §5 复算命令（逐条）

```bash
# 0) 装置（轻重活分开：Xvfb/xfwm4 是轻活，应用一律进槽）
Xvfb :192 -screen 0 1280x1024x24 & DISPLAY=:192 xfwm4 --display=:192 --compositor=off --replace &
Xvfb :191 -screen 0  800x600x24 & DISPLAY=:191 xfwm4 --display=:191 --compositor=off --replace &

# 1) 构建（before/after sha16 由脚本现场算）
cd $R/src/WpfGfx.Linux.Native && bash build-shim.sh
sha256sum $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16     # 11aa9d8fa154f20f

# 2) 四格（每格都是一次独立的槽获取；起应用整条包进槽）
cd $HOME/w59a
timeout 500 bash bin/probe.sh final192 :192 WPF_LINUX_CREATE_DIAG=1 HC_INPUT_DIAG=1 HC_GEO_EVERY=100000
WARM=6 bash bin/mvpgrid.sh mvpg-post192w :192 $HOME/w59a/app        # 热机后的放大/缩小回读
WARM=6 bash bin/mvpgrid.sh mvpg-pre192w  :192 $HOME/w59a/app-pre-full   # 修前反极性同格
bash bin/finalgrid.sh        # ① 小屏格 ② 零回归腿(:191，坐标不适用，见下) ③ HelloWpf 成对格
bash bin/lasttwo.sh          # ① 应用自带最大化→还原按钮 ② 零回归腿在 **:192**（W55A 坐标的标定屏）
bash bin/ewmhtest.sh ewmh192 :192      # EWMH 各条的外部验证（moveresize 无效 / movewin 有效 / wmstate 有效）
DISPLAY=:192 bash bin/pmaxprobe /…/bin/libwpfwin32.so :192   # shim 层 PMaxSize 反极性
cat logs/*/probe.txt | grep -E "NC-HIT|NC-PRESS|NC-DRAG|WMSIZE_DIAG|PROBE|windowsize"

# 3) 判据字段（逐条可复核）
DISPLAY=:192 xprop -id <WID> _NET_WM_STATE _MOTIF_WM_HINTS WM_NORMAL_HINTS
DISPLAY=:192 xwininfo -id <WID> | grep -E "Absolute upper-left|Width|Height"
DISPLAY=:192 xdotool windowsize <WID> 1100 820; sleep 1.2; xdotool getwindowgeometry --shell <WID>
```

---

### §2.5 收尾两格（读数原文）

**(a) 零回归点击腿** —— `W55A_STEPS="nav1 tab3" W55A_APP=$HOME/w59a/app bash ~/w55a/bin/leg.sh w59a192 :192 A`（**仪器全关**，槽内 `HEAVYSLOT=ACQUIRED`，`held=24s`）：

```
WID=10485764 WINGEOM X=8 Y=20 WIDTH=784 HEIGHT=560        ← :191 上那次是无效腿（坐标在 800x600 屏不适用），已作废重跑
CONVERGED iters=1 alive=yes nwin=17
──── STEP T1-nav1        click=(369,422) alive_before=yes alive_after=yes AE=225596 XBTN=0 preMouseDown=0 NOINFO-no-hit-chain
──── STEP T2-click-TabItem3 click=(450,318) alive_before=yes alive_after=yes AE=182274 XBTN=0 preMouseDown=0 NOINFO-no-hit-chain
LEG_DONE w59a192 mode=A alive=yes rc= clicks=2
```
⇒ 判据满足：**`alive=yes` ＋ 两步 `AE>0`**（225596 / 182274）。`preMouseDown=0`/`XBTN=0` 是 **mode A（仪器全关）下的预期值**（`preMouseDown` 要 `HC_INPUT_DIAG=1` 才有；`XBTN=0` 是 W55A 报告里记过的"stderr 缓冲假零"）。
⚠️ 我第一次在 **:191** 上跑这条腿得到 `AE=0 / AE=0`（`logs/final-leg`）——那是**腿的坐标是在大屏标定的**（`park()` 还把指针挪到 y=1010，小屏上没有那个高度）⇒ **该趟作废**，改在 :192 重跑（上面这份）。如实入册。

**(b) 应用自带"最大化 / 还原"按钮成对** —— `logs/freshbtn/probe.txt`（槽内、暖机 6 s、`:192`）：

```
起点 800x600@+240+212 state=[FOCUSED]  [POP] root=MainWindow wh=768x576
① 点应用自带**最大化**按钮 (966,226)   → 1280x1024@+0+0 state=[MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED]   ✅
② 再双击自绘标题栏 (640,226)           → 1280x1024@+0+0 state=[MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED]   ❌（未还原）
③ 点应用自带**最小化**按钮 (1160,226)  → 1280x1024@+0+0 state=[MAXIMIZED_HORZ, MAXIMIZED_VERT, FOCUSED]   ❌（未图标化）
异常 Unhandled=0
```
同一格内的**正极**另有 `logs/final192/probe.txt` S7（点同一个按钮 ⇒ 真最大化）与 S3/S4（双击 ⇒ 最大化，再双击 ⇒ **还原**）。
⇒ 我给出的读数**不是**"全都好"：**"在已经最大化态下再双击还原"出现了矛盾读数** —— `final192` S4 成功（`800x600@+200+150`、state 只剩 `FOCUSED`），`freshbtn` ② 失败；两者差异是"最大化的来源"（S4 的最大化来自双击本身，freshbtn 的最大化来自按钮命令）。**我没有定性地**（§4 `NOINFO` ④），也没时间再收敛 —— 如实写在这里，不粉饰。

---

## §6 报告文件 sha16

* 本文件正文（**不含本节**）sha16 = **`c7c1c6d21c7d06d1`**（正文 32770 字节；本节自身不计入）。
* 复算（**照抄即可复现**）：
  `cd $R && sed '/^## §6 报告文件 sha16$/,$d' build/MilBridge/W59A-report.md | sha256sum | cut -c1-16` ⇒ `c7c1c6d21c7d06d1`
* 本车道对仓内的写操作全景：新增 `build/MilBridge/W59A-report.md`；修改 `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_x11.c,win32_internal.h}`（三者都在写域内）；重建产物 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`。**未**改 `verify-all.sh`／`docs/**`／`build/**` 判据件／`upstream/**`／hc 应用源码（仓外）／`win32_msg.c`（写域给了但本趟不需要）。
* 车道私有物（仓外，供复核）：`$HOME/w59a/{app,app-pre,app-pre-full,plain,bin,logs,shots}`；探针与脚本源码：`$HOME/w59a/bin/{pmaxprobe.c,wmtool.c,setmotif.c,probe.sh,mvpgrid.sh,finalgrid.sh,lasttwo.sh,freshbtn.sh,maxrestore.sh,ewmhtest.sh,focus1..6.sh}`。

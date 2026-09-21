# W60A 报告 —— demo 侧"未处理异常守护"的验证 ＋ 「会崩的页」清单

> 车道 **W60A**｜仓根 `$R = /home/links-dev/netTest/wpf-linux-20260906/wpf-linux`｜写域：仓外 `/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/**`（仅在必要时改，改前 `cp -p`）＋ 本报告。
> **仓内既有文件一个都没改**（`docs/**`、判据件、`src/**`、`verify-all.sh` 全未动）。

## 结论在前

1. **反极性复现成立**：注掉 `InstallUnhandledGuard();` 重建后，点第 23 项（富文本框）与第 24 项（流文档）**都**得到 `rc=134` ＋ `Unhandled exception. System.EntryPointNotFoundException: … CreateInstalledObjectsInfo …`，与用户现场 `/tmp/hc-run-232817.log` 的签名**逐字相同**。
2. 🔴 **正极性（守护生效）不成立**：守护**确实接住并打印**了 `[HC-UNHANDLED] #1 …`，但**进程仍然死**，`rc=134` — 因为下一遍布局撞上 PTS 的 `Invariant.Assert` ⇒ **`Environment.FailFast("Unrecoverable system error.")`**，`FailFast` **不可被 `DispatcherUnhandledException` 捕获**（日志里**没有** `Unhandled exception` 行）。 ⇒ 主控预登记 §12.5 的判据 1/2/3（"进程 `alive=yes`"）**被证伪**；**"别的页还能用"也不成立**（进程已死，谈不上换页）。
3. 逐页清扫见 §4：**31 页里会崩的是第 23、24 项**（两页同族：PTS/LineServices 未实现 `D-G70`）；其余 29 页被点开时进程存活（`alive=yes`、页面 `Loaded` 到达、帧差异 > 0）。**会崩这两页的退出类都是 `134`＋`EntryPointNotFound`**；本趟**没有**出现 `137`（OOM）样本，也**没有** `139`（静默 SIGSEGV）样本 ⇒ 两者记 `NOINFO`。
4. 附带更正两处**判据级**问题（§2.4）：`grep -c HC-UNHANDLED` 对任何 .NET 产物都是 **0（假阴性）**；而且**任何静态判据**都分不出"守护在不在"——只有**行为读数**（日志有没有 `[HC-UNHANDLED]`）算数。

---

## §0 环境与现场

| 项 | 读数 |
|---|---|
| 车道/时间 | `lane=W60A`｜2026-09-20 23:38 → 2026-09-21 11:46 +0800（**中途被一次全机内存挤爆打断**，见 §6.3） |
| 私有显示 | `:195`（`Xvfb 1280x1024x24` ＋ `xfwm4 --compositor=off`）；`/tmp/.X11-unix` 里 `:195` 由我自建自收 |
| 私有应用目录 | `$HOME/w60a/app`（`cp -a` 自共享 bin）＋ 备份 `$HOME/w60a/app-backup`（**用户可跑的那份**）＋ `$HOME/w60a/dlls/{pos,neg}.dll` |
| 被测件（demo dll） | `pos.dll` = **`1ac5e587cda3fb20`**（2,932,224 B，守护生效）／`neg.dll` = **`275bcaff4dede9a5`**（2,932,736 B，`InstallUnhandledGuard();` 注掉） |
| 共享 bin 收工态 | `/home/links-dev/hc-linux/.../bin/Debug/net10.0/HandyControlDemo.dll` = **`1ac5e587cda3fb20`**（00:17:19 构建 = 守护生效；用户 `run-hc.sh` 拿到的就是它） |
| 五件（反极性/正极性腿） | libwpfwin32.so `054037aadfd7d192`｜wpfgfx_cor3.so `e3ea092010734f44`｜PresentationCore.dll `9465f9dce39e2dfc`｜PresentationFramework.dll `1011da6390c3bf1e`｜WindowsBase.dll `2e4e46e539a72cd7` |
| 五件（两趟复验 + 逐页清扫腿） | libwpfwin32.so `11aa9d8fa154f20f`｜wpfgfx_cor3.so `79e45aed26487045`｜PresentationCore.dll `9465f9dce39e2dfc`｜PresentationFramework.dll `1011da6390c3bf1e`｜WindowsBase.dll `2e4e46e539a72cd7` |
| `MemAvailable`（三值） | 开工 **2149 MB**／最低 **1726 MB**／收工 **2023 MB**（含槽的 `HEAVYSLOT=MEMOK` 读数） |
| 排程纪律 | 每次起应用**整条命令**都在机级重活槽 `~/heavy-slot.sh` 内（`--min-avail 1500 --max-hold 120`）；`HEAVYSLOT=MEMOK/ACQUIRED` 行见 §5 |
| 报告自身 sha16 | 见下面那一行（口径：**删掉该行**后整份文件的 sha256 前 16 位） |

报告自身 sha16 = `0dfd49ab332c317d`

> **复算**：`sed '/^报告自身 sha16 = /d' build/MilBridge/W60A-report.md | sha256sum | cut -c1-16`

> ⚠️ **两腿的五件版本不同（如实登记）**：反极性/正极性腿跑在 `libwpfwin32.so=054037aadfd7d192`、`wpfgfx_cor3.so=e3ea092010734f44` 上；逐页清扫腿（含 §2.5 的复验）跑在**隔夜被别的车道重建过的** `11aa9d8fa154f20f` / `79e45aed26487045` 上。**§2.5 用最新件把"守护接住→FailFast"复验了一遍**（结论不变）。

## §1 反极性：注掉守护 ⇒ 复现用户现场（abort）

改法（`cp -p` 备份 `/tmp/App.xaml.cs.before-hcguard` 之外，我又备了一份 `$HOME/w60a/backup/App.xaml.cs.guard-on`）：

```diff
--- App.xaml.cs (guard-on, sha16 2e07c8fe01e7272c)
+++ App.xaml.cs (neg,      sha16 a9860fbe91498d5e)   ← 只此一处、只此一行
@@ -62 +62,2 @@
-        InstallUnhandledGuard();
+        // [W60A 反极性] InstallUnhandledGuard();   ← 注掉这一行 = 还原"用户现场"（未处理 ⇒ 进程死）
+        // InstallUnhandledGuard();
```

| 腿 | dll | 点击 | rc | 逐字签名 |
|---|---|---|---|---|
| 反极性 | `neg.dll` | 第 23 项 富文本框 | **134** | `Unhandled exception. System.EntryPointNotFoundException: Unable to find an entry point named 'CreateInstalledObjectsInfo' in shared library 'PresentationNative_cor3.dll'.` |
| 反极性 | `neg.dll` | 第 24 项 流文档 | **134** | `Unhandled exception. System.EntryPointNotFoundException: Unable to find an entry point named 'CreateInstalledObjectsInfo' in shared library 'PresentationNative_cor3.dll'.` |

两腿都是 `guard_lines=0`、`fatal_lines=1` ⇒ **没有守护，异常直接杀进程**（与用户现场一致）。

## §2 正极性：守护接住了，但进程照样死（**本报告的核心证伪**）

### 2.1 守护确实生效（逐字）

```
[HC-UNHANDLED] #1 EntryPointNotFoundException: Unable to find an entry point named 'CreateInstalledObjectsInfo' in shared library 'PresentationNative_cor3.dll'. ｜ 首帧 at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.CreateInstalledObjectsInfo(FSIMETHODS& fssubtrackparamethods, FSIMETHODS& fssubpageparamethods, IntPtr& pInstalledObjects, Int32& cInstalledObjects)
```

### 2.2 紧接着的 FailFast（逐字，同一份日志）

```
Unrecoverable system error.
Process terminated.
Unrecoverable system error.
```

### 2.3 机制（仓内行号，可复算）

- 第一次异常被守护吞掉（`e.Handled = true`）时，**PTS context 根本没建起来**；
- 下一遍布局 `PtsPage.CreateBottomlessPage()` 又问一次 `Context` ⇒ `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsHost.cs:52-55` 的 `get { Invariant.Assert(_ptsContext != null); … }` **断言失败**；
- `Invariant.Assert` → `upstream/wpf/src/Microsoft.DotNet.Wpf/src/Shared/MS/Internal/Invariant.cs:192-204` `FailFast(...)` → **`Environment.FailFast(SR.InvariantFailure)`**（=`Unrecoverable system error.`）⇒ 立即 `abort`（`rc=134`），**绕过**所有托管异常处理 ⇒ 连 `Unhandled exception` 那行都不会打。

⇒ **demo 侧止损对 PTS 页无效**：它只把"未处理异常"换成了"不可捕获的 FailFast"，**进程死这一事实没变**。真修法仍在 R3（PTS/LineServices 实现）。

### 2.4 判据级更正（两条，都会让"假绿"发生）

| 判据 | 无守护的 09:18 dll `9f747a504356d26a` | 有守护的 `1ac5e587cda3fb20` | 反极性的 `275bcaff4dede9a5` | 结论 |
|---|---|---|---|---|
| `grep -c 'HC-UNHANDLED'`（ascii） | 0 | **0** | **0** | **假阴性**：用户字符串在 `#US` 堆是 **UTF-16LE** |
| `strings -el \| grep -c 'HC-UNHANDLED'` | 0 | 1 | **1** | 能分"有没有编译进去"，**分不出反极性** |
| `strings -a \| grep -c InstallUnhandledGuard` | 0 | 2 | **2** | 同上：注掉**调用**≠删掉**方法** |

⇒ 我**只注掉了调用**（照派单书要求），方法体仍在 ⇒ **静态判据一律给"有守护"**。**唯一算数的是行为读数**：日志里有没有 `[HC-UNHANDLED]` 行（本报告 §1/§2 用的就是它）。

### 2.5 用隔夜最新件复验（排除"只是件旧"）

隔夜后仓内 `libwpfwin32.so`／`wpfgfx_cor3.so` 被别的车道重建（`054037aa…→11aa9d8f…`、`e3ea0920…→79e45aed…`）。我重新 `sync-applocal.sh` 后**又跑了一趟正极性（第 23 项）**：读数与 §2.1/§2.2 **同形** —— `[HC-UNHANDLED] #1 …` 之后仍死，`rc=134`、`fatal_lines=0`、`Unrecoverable system error.` 仍在（`posrecheck/app_g1.log:398-403`）。

## §3 "别的页还能用" —— **不成立**

判据要求"崩过之后再点一个正常页 ⇒ 仍能换页"。**做不到**：那个"崩"不是"这一页渲染不出来"，而是**整个进程被 `FailFast` 打死**（§2.2/§2.3）⇒ **崩后没有进程可点**。我的 `session_inner.sh` 在这一刻记录的是 `PROCESS DEAD`、`APP_RC=134`，`pos:23,24,0` 这一组**在第 23 项就中止**，第 24、0 项根本没轮到（这是读数，不是我没点）。

⇒ 对用户的正确说法应是："**切这两页 = 整个应用退出**"，而不是"这一页打不开、别的页还能用"。

## §4 「会崩的页」清单（31 项逐页）

被测页签 = 导航第 1 页签 **Styles**（`Data/DemoInfo.json` 的 `demoItemList`，**恰好 31 项**，第 23 项 = `RichTextBoxDemo`/富文本框、第 24 项 = `FlowDocumentDemo`/流文档 ⇒ 与用户说的"富文本/流文档"对上）。

| # | 页（中文） | 导航名 | 目标控件 | 点后 alive | `[HC-UNHANDLED]` | 应用自报 `sel` | 退出类 | 页面身份 `[NS] loaded` | 崩溃签名 |
|---|---|---|---|---|---|---|---|---|---|
| 0 | 画刷 | `Brush` | `BrushDemo` | yes | 0 | 0 | - | BrushDemo | — |
| 1 | 按钮 | `Button` | `ButtonDemo` | yes | 0 | 1 | - | ButtonDemo | — |
| 2 | 重复按钮 | `RepeatButton` | `RepeatButtonDemo` | yes | 0 | 2 | - | RepeatButtonDemo | — |
| 3 | 切换按钮 | `ToggleButton` | `ToggleButtonDemo` | yes | 0 | 3 | - | ToggleButtonDemo | — |
| 4 | 单选按钮 | `RadioButton` | `RadioButtonDemo` | yes | 0 | 4 | - | RadioButtonDemo | — |
| 5 | 复选框 | `CheckBox` | `CheckBoxDemo` | yes | 0 | 5 | - | CheckBoxDemo | — |
| 6 | 滚动视图 | `ScrollViewer` | `NativeScrollViewerDemo` | yes | 0 | 6 | - | NativeScrollViewerDemo | — |
| 7 | 滑块 | `Slider` | `SliderDemo` | yes | 0 | 7 | - | SliderDemo | — |
| 8 | 文本块 | `TextBlock` | `TextBlockDemo` | yes | 0 | 8 | - | TextBlockDemo | — |
| 9 | 文本框 | `TextBox` | `NativeTextBoxDemo` | yes | 0 | 9 | - | NativeTextBoxDemo | — |
| 10 | 组合框 | `ComboBox` | `NativeComboBoxDemo` | yes | 0 | 10 | - | NativeComboBoxDemo | — |
| 11 | 密码框 | `PasswordBox` | `NativePasswordBoxDemo` | yes | 0 | 11 | - | NativePasswordBoxDemo | — |
| 12 | 展开框 | `Expander` | `ExpanderDemo` | yes | 0 | 12 | - | ExpanderDemo | — |
| 13 | 进度条 | `ProgressBar` | `NativeProgressBarDemo` | yes | 0 | 13 | - | NativeProgressBarDemo | — |
| 14 | 日历 | `Calendar` | `CalendarDemo` | yes | 0 | 14 | - | CalendarDemo | — |
| 15 | 日期选择器 | `DatePicker` | `NativeDatePickerDemo` | yes | 0 | 15 | - | NativeDatePickerDemo | — |
| 16 | 选项卡控件 | `TabControl` | `NativeTabControlDemo` | yes | 0 | 16 | - | NativeTabControlDemo | — |
| 17 | 数据表格 | `DataGrid` | `DataGridDemo` | yes | 0 | 17 | - | DataGridDemo | — |
| 18 | 树视图 | `TreeView` | `TreeViewDemo` | yes | 0 | 18 | - | TreeViewDemo | — |
| 19 | 列表框 | `ListBox` | `ListBoxDemo` | yes | 0 | 19 | - | ListBoxDemo | — |
| 20 | 列表视图 | `ListView` | `ListViewDemo` | yes | 0 | 20 | - | ListViewDemo | — |
| 21 | 分组框 | `GroupBox` | `GroupBoxDemo` | yes | 0 | 21 | - | GroupBoxDemo | — |
| 22 | 菜单 | `Menu` | `MenuDemo` | yes | 0 | 22 | - | MenuDemo | — |
| 23 | 富文本框 | `RichTextBox` | `RichTextBoxDemo` | **no**（进程死） | 1 | - | 134-ABORT | RichTextBoxDemo | `[HC-UNHANDLED]`→**FailFast** |
| 24 | 流文档 | `FlowDocument` | `FlowDocumentDemo` | **no**（进程死） | 1 | - | 134-ABORT | —（`Loaded` 未到达，见注②） | `[HC-UNHANDLED]`→**FailFast** |
| 25 | 工具条 | `ToolBar` | `ToolBarDemo` | yes | 0 | 25 | - | ToolBarDemo | — |
| 26 | 边框 | `Border` | `BorderDemo` | yes | 0 | 26 | - | BorderDemo | — |
| 27 | 标签 | `Label` | `LabelDemo` | yes | 0 | 27 | - | LabelDemo | — |
| 28 | 导航框架 | `Frame` | `FrameDemo` | yes | 0 | 28 | - | FrameDemo | — |
| 29 | 窗口 | `Window` | `NativeWindowDemo` | yes | 0 | 29 | - | NativeWindowDemo | — |
| 30 | 几何形状 | `Geometry` | `GeometryDemo` | yes | 0 | 30 | - | GeometryDemo | — |

> **注①** 判据口径：`alive` = 点击后 1.0 s 的进程存活；`sel` = 应用自己在 `[GEO]` 里报的 `ListBox#ListBoxDemo … sel=`（= "我确实选中了第 k 项"）；`[NS] loaded` = `App.xaml.cs:720` 的页面 Loaded 探针（**逐页身份**，每页都在点击后**新增一条**且类型与 `DemoInfo.json` 的 `target` 对上）；`退出类` 只在**该页杀死进程**时才有值（`134`=abort／`137`=OOM／`139`=静默 SIGSEGV）。
> **注②** 第 24 项（流文档）：进程在**布局期**就死了 ⇒ 页面 `Loaded` 事件**从未到达**（`[NS]` 最后一条仍是启动页 `PracticalDemo`）。它的身份由另外两条证据钉住：① 被点的项是应用自报的 `item[24] … nm=FlowDocument`（已滚进视口后点的，`scr=268,707`）；② 该趟的 FailFast 调用栈里有 `MS.Internal.Documents.FlowDocumentFormatter.ComputePageMargin()`。
> **注③** 第 30 项第一趟是 `UNREACHED`（**仪器够不着，不是页面点不到**）：该列表视口 y=378..767，第 30 项滚到 y=753 时其中心 766.5 被我的 4 px 余量卡掉 3.5 px ⇒ 列表在 753⇄878 之间来回滚。把判据改成"点**可视交集**的中心"后重取（`sweepD`）⇒ `sel=30 alive=yes`，第 30 页与其它页同族（不崩）。

**死页的复现次数**：第 23 项 **3/3**（`polarity` G3、`posrecheck`、`sweepC` 各 1 次）；第 24 项 **2/2**（`polarity` G2、`sweepC`）。两页每次都是 `rc=134`、同一签名 `EntryPointNotFoundException: CreateInstalledObjectsInfo`；有守护时先打 `[HC-UNHANDLED] #1` 再 `Unrecoverable system error.`（`FailFast`）。
**`139` 静默 SIGSEGV**：本趟 **0 次**（用户 2026-09-20 23:27/23:34 那两次 0 字节日志 `rc=139` **我没复现**）⇒ 按主控口径**只记"未复现"＋交 W63A**，我不下结论。**`137` OOM**：0 次（槽的 `--min-avail 1500` 每趟都 `MEMOK`）。

## §5 复算（一条命令一份读数）

所有脚本在 `$HOME/w60a/bin/`（**仓外**，不占写域）：`build_one.sh`（单次构建，`pos`/`neg`）、`deploy.sh`（装件＋`sync-applocal.sh`）、`session.sh`+`session_inner.sh`（多组点击，每组独立 timeout/日志/rc）、`sweep.sh`+`sweeprun.sh`（逐页清扫，**每死一次就重启续点**）、`navsweep.py`（按 `[GEO]` 自报坐标点击）。

```bash
# 反极性 dll（注掉守护 → 构建 → 立刻还原源码并把 pos.dll 放回共享 bin）
bash ~/heavy-slot.sh --max-hold 150 -- bash ~/w60a/bin/build_one.sh neg
# 反极性 + 正极性 会话（同一槽内 3 组；每组各自 timeout/日志/rc）
W60A_TMO=200 W60A_MAXHOLD=280 bash ~/w60a/bin/session.sh polarity neg:23 neg:24 pos:23,24,0
# 逐页清扫（3 批；--min-avail 1500 --max-hold 120）
W60A_MAXHOLD=120 W60A_MINAVAIL=1500 bash ~/w60a/bin/sweep.sh sweepA pos 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
W60A_MAXHOLD=120 W60A_MINAVAIL=1500 bash ~/w60a/bin/sweep.sh sweepB pos 16,17,18,19,20,21,22
W60A_MAXHOLD=120 W60A_MINAVAIL=1500 bash ~/w60a/bin/sweep.sh sweepC pos 23,24,25,26,27,28,29,30
# 第 30 项：第一趟 UNREACHED（视口余量差 3.5 px）⇒ 点击判据改成"点可视交集中心"后重取
W60A_MAXHOLD=120 W60A_MINAVAIL=1500 bash ~/w60a/bin/sweep.sh sweepD pos 30
# 判据复算：某个被点页有没有守护行／有没有 FailFast
grep -c "\[HC-UNHANDLED\]" ~/w60a/logs/posrecheck/app_g1.log; grep -c "Unrecoverable system error" ~/w60a/logs/posrecheck/app_g1.log
# 静态判据的盲区（★ 不要再用 ascii grep 判守护）
strings -el <dll> | grep -c HC-UNHANDLED; strings -a <dll> | grep -c InstallUnhandledGuard
```

槽读数（逐次获取）：

```
sweep_pos_0.txt  HEAVYSLOT=ACQUIRED waited=0s cmd=bash /home/links-dev/w60a/bin/sweeprun.sh sweep1 pos 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15  NOINFO
sweep_pos_0.txt  HEAVYSLOT=ACQUIRED waited=73s cmd=bash /home/links-dev/w60a/bin/sweeprun.sh sweepA pos 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15  HEAVYSLOT=RELEASED rc=0 held=44s max_hold=120s
sweep_pos_16.txt  HEAVYSLOT=ACQUIRED waited=23s cmd=bash /home/links-dev/w60a/bin/sweeprun.sh sweepB pos 16,17,18,19,20,21,22  HEAVYSLOT=RELEASED rc=0 held=26s max_hold=120s
sweep_pos_23.txt  HEAVYSLOT=ACQUIRED waited=0s cmd=bash /home/links-dev/w60a/bin/sweeprun.sh sweepC pos 23,24,25,26,27,28,29,30  HEAVYSLOT=RELEASED rc=0 held=70s max_hold=120s
sweep_pos_30.txt  HEAVYSLOT=ACQUIRED waited=31s cmd=bash /home/links-dev/w60a/bin/sweeprun.sh sweepD pos 30  HEAVYSLOT=RELEASED rc=0 held=14s max_hold=120s
```

## §6 边界、NOINFO 与我推翻的话

### 6.1 我推翻的三句

1. **§12.5 判据 1/2/3（"守护 ⇒ 进程 `alive=yes`"、"别的页还能用"）不成立** —— 守护接住第一个异常后，进程被 **`Environment.FailFast`** 打死（§2.2/§2.3），仍是 `rc=134`。
2. **`grep -c 'HC-UNHANDLED'` 不是"守护在不在"的判据**（§2.4）：ascii grep 对**任何** .NET 产物都给 0；`strings` 又分不出反极性（方法体还在）。
3. **"反极性腿必须重构建才能复现"这句话只对一半**：用户手上那份 09:18 的 dll 本来就是无守护的（`strings` 三项全 0），但它**没有 `[GEO]`/`[NS]` 仪器**（那批仪器是 23:38 才加进 `App.xaml.cs` 的）⇒ 要拿到带仪器的无守护件，**确实必须重构建**（我这么做了）。

### 6.2 NOINFO（算不出的，不许猜）

- **`137` OOM / `139` 静默 SIGSEGV**：本趟 0 样本 ⇒ `NOINFO`（不算缺陷，也不否认存在）。
- **第 30 项之后的页签**（Controls 72 项 / Tools 3 项）：**不在派单书要求的 31 项内**，未测 ⇒ `NOINFO`。注：`Controls` 页签里还有 `Dialog/RichTextBox` 等**疑似同族**页，**未取数**。
- **页面"渲染成功"与否**：本报告只判"进程存活 + 页面 Loaded 事件 + 帧差异">0，**不判渲染正确性**。
- **`139` 的用户两次复现**（`/tmp/hc-run-232731.log`、`-233418/-233427.log` 均 0 字节、`rc=139`）我**没复现**。

### 6.3 中断事实（影响完成度，如实登记）

2026-09-21 00:24 起，全机被一次内存挤爆打断（用户报"内存被挤爆、中断"）：我的第一趟清扫在**实例 1 启动后即被掐断**（`logs/sweep1/` 只有 boot 日志、TSV 只有表头）。11:35 复盘后我按主控新的内存闸门（`--min-avail 1500 --max-hold 120`）**重跑**了全部读数；§4 的表来自重跑后的 `sweepA/B/C`。**没有把被中断的那趟当读数用。**

### 6.4 未落地/未做的事

- 反极性腿**没有**在共享 bin 停留过无守护态（构建完立刻回拷 `pos.dll`；无守护窗口 ≈ 6.6 s 构建＋秒级回拷）。
- `App.xaml.cs` 现处于**守护生效**态（sha16 `2e07c8fe01e7272c`，第 62 行未注释），与主控备份 `App.xaml.cs.guard-on` `diff` **无差异**。
- **用户目录已恢复成可用状态**：`sync-applocal.sh -q <共享应用目录>` ⇒ `SYNC-APPLOCAL=PASS items=5 ok=5 drift=0 rc=0`；五件 = 仓内权威（`libwpfwin32.so 11aa9d8fa154f20f`／`wpfgfx_cor3.so 79e45aed26487045`／`PresentationCore.dll 9465f9dce39e2dfc`／`PresentationFramework.dll 1011da6390c3bf1e`／`WindowsBase.dll 2e4e46e539a72cd7`），`HandyControlDemo.dll` = **`1ac5e587cda3fb20`（守护生效）**。
- 未改仓内任何文件（本报告是唯一新增件）；未跑 `verify-all.sh`/`integration-wave`/冻结。
- ⚠️ **止损的效果要说清**：守护**修不好**这两页，它只是把"未处理异常"变成"不可捕获的 `FailFast`"；**用户看到的仍然是"切这两页 ⇒ 应用退出"**。要真正止损，只有 R3（PTS/LineServices）；demo 侧能做的替代方案（例如在 `SwitchDemo` 里对已知 PTS 页短路、不实例化那个 UserControl）**不在本趟写域/工作量内**，未做。


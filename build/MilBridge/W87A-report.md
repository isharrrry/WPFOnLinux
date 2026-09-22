# W87A 报告 —— `TASK-0206`：`D-G85` **只读诊断**（取「分界读数」）

> 车道 **W87A**｜2026-09-22 09:43 → 10:0x +0800｜kernel `6.8.0-138-generic`｜`nproc=3`｜`loadavg` 1.86→4.00
> 复现器 = **现成**判据件 `R-GATE`（`verify-all` 第 `[26]` 步，≈36 s），本件**不新增判据、不改产品件**。
> **仓内写入只有本报告一个文件**；所有读数落 `$HOME/w87a/**`。零 `pkill`（Xvfb/app 按 PID 收尾）。

---

## §0 一句话结论（**先说不好听的：两条假设的措辞都不成立，但真正的分界读数取到了**）

| 任务书里的假设 | 本件判定 | 硬证据 |
|---|---|---|
| ① **shim 侧**「没把 `WM_CAPTURECHANGED` 派发给弹窗窗口」 | **推翻** | 点选项那一刻 shim **确实派发**了：`app.log:639 [msg] hwnd=0x200005 msg=0x0215 wp=0x0 lp=0x0`。而**弹窗窗口从来不是捕获持有者** ⇒ "派给弹窗"这件事**没有对象**：全场 4 条 `0x0215` **全是** `ReleaseCapture` 产生的 `lp=0`，**零条**是 `SetCapture` 产生的 `lp≠0`；`captured=PopupRoot` 命中 **0 次**。 |
| ② **托管侧**「`ComboBoxItem` 的粘性捕获未清」 | **措辞推翻、族成立** | `ComboBoxItem.cs` 里 `Capture` 命中 **0 次**（`ListBoxItem.cs` 同为 0；`build/shims/*.cs` 里 `Mouse.Capture` 也 0）。捕获是 **`ComboBox`** 设的（`ComboBox.cs:220`）、也是 **`ComboBox`** 要求释放的（`ComboBox.cs:290`）。**但托管侧的捕获状态确实没被清掉**（下表）。 |

**真正的分界读数（受控 A/B，同一条腿型、同一个释放消息）**：

> **下拉"点外面"关 ⇒ 捕获释放；下拉"点选项"关 ⇒ 捕获不释放** —— 而两腿 **shim 侧逐字节相同**
> （同 hwnd `0x200005`、同 `wp=0x0`、同 `lp=0x0`）。**唯一差别 = 那一下按在哪个 X 窗口上**
> （`L7` 落在主窗口 / `L8` 落在弹窗窗口）。
> ⇒ 失败点在**托管侧对"活跃输入源是谁"的依赖**（`HwndMouseInputProvider.cs:730` + `MouseDevice.cs:1445` 两道门），
> **不在** shim 的消息派发。修法落点见 §5。

---

## §1 捕获时序原始读数（①）

### 1.1 命令与出口

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd $R
export PATH="$HOME/.dotnet:$PATH"
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 200 --wait 900 \
     -- timeout 260 env R_GATE_OUT=$HOME/w87a/rgate1 bash build/MilBridge/tools/r-gate-step.sh
```

`rc` 与槽读数（原文）：

```
HEAVYSLOT=ACQUIRED waited=58s cmd=timeout 260 env R_GATE_OUT=/home/links-dev/w87a/rgate1 bash build/MilBridge/tools/r-gate-step.sh
HEAVYSLOT=MEMOK avail=2523MB min_avail=1500MB
…
HEAVYSLOT=RELEASED rc=1 held=36s max_hold=200s
STEP_RC=1
```

> ⚠️ `rc=1` **在本件里是预期读数**（不是"没跑起来"）：第 `[26]` 步是**已登记判据**，未修的树上它**必须红**；
> `127`/`MSB1009` 那类"根本没跑"的 rc 语义在 §1.4 里逐条排除。

机读行（原文，`fails=` 里那串中文是判据格名被 shell 拆词，**判据件自身的格式问题，不影响红格识别**）：

```
R_GATE=FAIL crit=11/13 clicks=11 ok=11 red=2 noinfo=0 popup=1 px_open=19449 sabotage=none win=938x938 src=device fails=c06(L8_comboitem1,SEQ_lst0,SEQ_tb,…),c11(seq-lst0,seq-tb,…)
```

件 sha16（装置自报，非手抄）：`win32shim=24e906c194903c8b pc=56ee75ced8d6aece pf=0018b509567434df wb=2e4e46e539a72cd7 bridge=feef049e9d0e313a probe=2f4acc9a2f61769f wic=56278c14b4ecd672`。
证据目录 `$HOME/w87a/rgate1/`（`app.log` 775 行、`evidence.txt` 40 行）。

### 1.2 逐腿 `captured=` 时序（`app.log` 按 `evidence.txt` 的行区间切片）

| 腿 | 那一下按在哪个 X 窗口 | `captured=`（托管 `Mouse.Captured`，`GetType().Name`） | 判定 |
|---|---|---|---|
| `L4_tb` | 主 `0x200005` | `null → TextBox → null → null` | 抬起后释放 ✓ |
| `L6_combo`（开下拉） | 主 | `null → ComboBox → ComboBox` | 开着持有捕获 = **合法** |
| **`L7_combo_blank`**（开着时点**外面**） | **主 `0x200005`** | `ComboBox →` **`null` → `null`** | **释放了** ✓ |
| `L6b_combo_reopen` | 主 | `null → ComboBox → ComboBox` | 合法 |
| **`L8_comboitem1`**（**点选项**） | **弹窗 `0x200008`** | `ComboBox →` **`ComboBox` → `ComboBox`** | **没释放** ✗ |
| `SEQ_lst0`（点在 ListBox 行上） | 主 | `ComboBox, ComboBox` | 被误路由 ✗ |
| `SEQ_tb`（点在 TextBox 上） | 主 | `ComboBox, ComboBox` | 被误路由 ✗ |
| `SEQ_combo` | 主 | `ComboBox ×3` | ✗ |

普查（正控见 §1.4）：`grep -ao 'captured=[A-Za-z_.]*' app.log | sort | uniq -c` ⇒ **`15 captured=ComboBox` / `11 captured=null` / `1 captured=TextBox` / `0 captured=PopupRoot`**。

### 1.3 分界处的原始行（全文可复算，行号 = `$HOME/w87a/rgate1/app.log`）

**A 腿 `L7`（点外面关）—— 释放成功：**

```
527: EVT move root=483,160 src=ComboBox directlyover=ComboBox freshhit=Border captured=ComboBox
534: [msg] hwnd=0x200005 msg=0x0201 wp=0x1 lp=0xa701f8          ← 按下：落在【主窗口】
535: [msg] hwnd=0x200005 msg=0x0215 wp=0x0 lp=0x0               ← 释放回声派给主窗口
536: EVT move root=483,160 src=Border … captured=null            ← 托管捕获【已清】
551: EVT combo.closed
561: EVT move root=485,160 … captured=null
```

**B 腿 `L8`（点选项关）—— 释放失败：**

```
617: EVT move root=124,35 src=Border directlyover=Border freshhit=Border captured=ComboBox
629: [msg] hwnd=0x200008 msg=0x0201 wp=0x1 lp=0x250082          ← 按下：落在【弹窗窗口 0x200008】
636: [msg] hwnd=0x200008 msg=0x0202 wp=0x1 lp=0x250082
637: EVT combo.selection=1                                      ← 选项【选中成功】
639: [msg] hwnd=0x200005 msg=0x0215 wp=0x0 lp=0x0               ← 释放回声：同 hwnd/同 wp/同 lp
640: EVT combo.up state=Released
645: EVT move root=126,35 src=ComboBox … freshhit=Border captured=ComboBox   ← 托管捕获【没清】
650: EVT move root=290,216 … freshhit=null captured=ComboBox
658: EVT combo.closed
```

**之后第 1/2 次点击（承重腿）—— 路由与命中测试分叉：**

```
672: EVT move root=282,48 src=ComboBox … freshhit=Border captured=ComboBox   ← 点在 ListBox 行上，freshhit=Border
677: [msg] hwnd=0x200005 msg=0x0201 wp=0x1 lp=0x320126                       ← 点击确实到了窗口
687: EVT move root=284,48 … captured=ComboBox     （该腿收到 EVT combo.down，收不到 EVT lst.down）
696: EVT move root=282,129 … freshhit=TextBoxView captured=ComboBox           ← 点在 TextBox 上
701: [msg] hwnd=0x200005 msg=0x0201 wp=0x1 lp=0x870126
713: EVT move root=284,129 … captured=ComboBox     （该腿收不到 EVT tb.focus）
```

全场 `0x0215` 共 **4 条**（`222/254/535/639`），**全部** `hwnd=0x200005`、**全部** `lp=0x0`，分别落在这四腿区间内：

```
222 → L3_lst1 (203..228)      254 → L4_tb (228..331)
535 → L7_combo_blank (525..563)     639 → L8_comboitem1 (613..670)
```

### 1.4 正控与 rc 语义（纪律 25 / "非零 rc 不等于失败"）

* **判据有判别力（不是恒红）**：同一趟里 `c01..c05,c07..c10,c12,c13` = **11 格 PASS**（含 `c05` 选项选中 + `combo.closed`、`c13` 下拉像素 19449）；红只有 `c06/c11` 两格。
* **计数正控**：`grep -ao 'captured=[A-Za-z_.]*'` 在**同一份** `app.log` 上同时命中 `ComboBox`(15) / `null`(11) / `TextBox`(1) ⇒ 这个搜索不是恒零/恒同。
* **`rc=1` 分类**：`STEP_RC=1` 来自判据件（判据 `FAIL`），**不是** `127`（command not found；`dotnet` 经 `export PATH` 可见，装置自报 `APP_ART` 五件 sha 全部非 `MISSING`）、**不是** `MSB1009`（构建日志 `$HOME/w87a/rgate1/build.log` 60 B、无错误）；装置自报 `EVID device=OK`、`EVID appalive value=yes`、`EVID counts wm_lbuttondown=11 wm_lbuttonup=11`、`EVID applog lines=775`。
* **A/B 旁证（跨 pf 版本不变）**：W84A 那趟（09:40，`pf=78218dd1851d41e8`）与本趟（09:47，`pf=0018b509567434df`）**红格逐格相同**（`c06(L8_comboitem1,SEQ_lst0,SEQ_tb),c11(seq-lst0,seq-tb)`）⇒ 本缺陷**对这两个 `pf` 字节版本不敏感**。

---

## §2 shim 侧**只读**证据（②，全部 `file:line`，**一字节未改**）

### 2.1 派发点：它会派给谁

```
src/WpfGfx.Linux.Native/src/win32_core.c:1442  HWND SetCapture(HWND hwnd)
:1446      HWND old = g_capture_window;
:1447      g_capture_window = hwnd;
:1455      if (old && old != hwnd) wpf_dispatch_to_window(old, WM_CAPTURECHANGED, 0, (LPARAM)hwnd);

src/WpfGfx.Linux.Native/src/win32_core.c:1459  BOOL ReleaseCapture(void)
:1463      HWND old = g_capture_window;
:1464      g_capture_window = NULL;
:1468      if (old) wpf_dispatch_to_window(old, WM_CAPTURECHANGED, 0, 0);
```

⇒ **派发目标是"失去捕获的那个窗口"（`old`）**，`lParam` = 新捕获窗口（`ReleaseCapture` 时为 `0`）。
`WM_CAPTURECHANGED` 常量：`win32_internal.h:40 #define WM_CAPTURECHANGED 0x0215`。
派发实现：`win32_msg.c:512-528 wpf_dispatch_to_window()`（`wpf_window_find` 查不到就退 `DefWindowProcW`）。

**"有没有可能派给弹窗窗口"的答案：有条件，但本缺陷里不可能** —— 只有当弹窗**自己**调用过 `SetCapture(弹窗HWND)`（那会派给 `old=主窗口`、`lParam=弹窗`，即 `lp≠0`）或弹窗**持有**捕获后释放（派给弹窗、`lp=0`）才会。两者在本趟**都没有发生**：

* 全场 `lp≠0` 的 `0x0215` = **0 条** ⇒ `SetCapture` 从未把捕获**从别的窗口**拿过去（首次 `SetCapture(主窗口)` 时 `old==NULL`，按 `:1455` 的守卫**不派发**，与 `L6` 腿无 `0x0215` 相符）；
* 全场派给弹窗 `0x200007/0x200008` 的 `0x0215` = **0 条** ⇒ 弹窗从未持有过捕获。

### 2.2 捕获状态**不参与**输入投递（结构证据）

`g_capture_window` 的**全部**引用只有 6 处，**没有一处在事件投递路径上**：

```
win32_internal.h:435            extern HWND g_capture_window;
win32_core.c:1390               HWND g_capture_window = NULL;
win32_core.c:1437               (GetCapture 读)
win32_core.c:1446/1447          (SetCapture 读/写)
win32_core.c:1463/1464          (ReleaseCapture 读/写)
```

X 侧按键事件的**目标窗口取自 X 事件自身的 window 字段**，与捕获无关：

```
src/WpfGfx.Linux.Native/src/win32_x11.c:982-984   case ButtonPress/ButtonRelease:
                                                    HWND h = (HWND)(uintptr_t)ev.xbutton.window;
src/WpfGfx.Linux.Native/src/win32_x11.c:1098      push(t, h, m, mk, xy_lparam(ev.xbutton.x, ev.xbutton.y), …)
src/WpfGfx.Linux.Native/src/win32_x11.c:1104      case MotionNotify:（同型）
```

全 shim 唯一的指针抓取只有 NC 拖动那一处，且与 `SetCapture` 无关：

```
win32_x11.c:1573-1585  void wpf_x11_pointer_grab(HWND hwnd, int grab)  // XGrabPointer，掩码 PointerMotionMask|ButtonReleaseMask
win32_x11.c:1067       wpf_x11_pointer_grab(h, 1);   // 仅非客户区拖动
win32_x11.c:1084       wpf_x11_pointer_grab(h, 0);
```

> **这条结论很重要，但它不是本缺陷的成因（见 §4.3）**：Win32 的"软捕获"本来也不把**同线程弹窗窗口**上的点击抢回捕获者 —— 上游 `ComboBox.cs:1700-1703` 逐字依赖这一点（"捕获期间**弹窗上**的点击必须落到弹窗"），本机实测也正是"点击落到弹窗 ⇒ 选项选中"（`app.log:637`）。⇒ **不许**用"把输入重定向给捕获持有者"来修（§5 末）。

### 2.3 悬垂捕获（同族欠账，本趟**未触发**）

```
src/WpfGfx.Linux.Native/src/win32_core.c:946-984  BOOL DestroyWindow(HWND hwnd)
```

通读该函数：派发 `WM_DESTROY`/`WM_NCDESTROY`、清定时器、`wpf_x11_destroy_window`、`wpf_window_remove(hwnd)` —— **既不检查也不清 `g_capture_window`，也不派发 `WM_CAPTURECHANGED`**。
Win32 语义：捕获窗口被销毁 ⇒ 捕获清空并通知。今天没被触发（弹窗从未持有捕获），但这是**悬垂 HWND 通道**（`wpf_window_remove` 之后 `g_capture_window` 仍指旧 XID，XID 可复用）。

### 2.4 有没有现成的"捕获诊断开关"（任务书 ④ 的前置查询）

`grep -rn 'getenv' src/WpfGfx.Linux.Native/src/*.c` 全清单：

```
WPF_LINUX_CREATE_DIAG / WPF_LINUX_WIN_DIAG / WPF_LINUX_KEY_DIAG / WPF_LINUX_KEYSTATE_TRACE(_MAX)
WPF_LINUX_WFP_DIAG / WPF_LINUX_PTS_DIAG / WPF_LINUX_MSGFLOW_TRACE / WPF_LINUX_UI_FONT(_SIZE)
WPF_LINUX_DISPLAY / WPF_LINUX_WIC_SHIM / WPF_SHIM_LEGACY_DPI
WPF_WIN32_MSG_TRACE / WPF_WIN32_NO_DISPLAY_NOTIFY
```

* **没有**任何开关打"捕获状态/`g_capture_window`/`SetCapture` 调用者"。
* **但 `WPF_WIN32_MSG_TRACE=1` 就是本件要的那把刀**（`win32_msg.c:487-510`，在 `wpf_dispatch_to_window` 开头打 `hwnd/msg/wp/lp`）—— 而**装置本来就开着它**（`run-r-gate-legs.sh:166`：`exec env WPF_WIN32_MSG_TRACE=1 dotnet …`）⇒ **零产品件改动、零装置改动**就拿到了 §1.3 全部原始行。

---

## §3 托管侧**只读**证据（③，全部 `file:line`）

`build/shims/**` 里 `Mouse.Capture` 命中 **0**（捕获逻辑全在**上游源码**里，`PresentationCore`/`PresentationFramework` 直接编译上游件：`build/PresentationCore.Linux/PresentationCore.Linux.csproj` 与 `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` 用 `<Compile Include="$(UpstreamWpfRoot)…">`，`ComboBox.cs`/`Popup.cs` **没有任何生成物覆盖、没有任何应用器** ⇒ 下面这些行号**就是跑起来的那份代码**）。

### 3.1 谁设捕获、谁该释放

```
PresentationFramework/…/Controls/ComboBox.cs:204  OnIsDropDownOpenChanged
:220                  Mouse.Capture(comboBox, CaptureMode.SubTree);      ← 开下拉：捕获（SubTree）
:288-291              if (comboBox.HasCapture) { Mouse.Capture(null); } ← 关下拉：要求释放
:1896-1900            private bool HasCapture { get { return Mouse.Captured == this; } }
:1700-1703            // When we have capture, all clicks OFF the popup will have the combobox as the OriginalSource…
PresentationFramework/…/Controls/ComboBoxItem.cs  → `grep -c Capture` = 0
PresentationFramework/…/Controls/ListBoxItem.cs   → 无捕获代码
PresentationFramework/…/Controls/Primitives/Popup.cs:1134-1177 EstablishPopupCapture()
:1136-1137            if (!_cacheValid[CaptureEngaged] && _popupRoot != null && !StaysOpen)
:1139/1168            IInputElement capturedElement = Mouse.Captured;  …  if (capturedElement == null) { Mouse.Capture(_popupRoot, SubTree); … }
:1179-1202            ReleasePopupCapture()（只在 `Mouse.Captured == _popupRoot` 时才 `Mouse.Capture(null)`）
```

`Mouse.Capture(null)` 的落地（**关键**）：

```
PresentationCore/…/Input/MouseDevice.cs:275   public bool Capture(IInputElement element, CaptureMode captureMode)
:358-361              else if (_mouseCapture != null) { mouseInputProvider = _providerCapture; }
:386-394              else { mouseInputProvider.ReleaseMouseCapture();
                             // 注释逐字：If we had capture, the input provider will release it.  That will
                             // cause a RawMouseAction.CancelCapture to be processed, which will update our internal states.
                             success = true; }
```

⇒ **上游把"清 `_mouseCapture`"这件事完全托付给 `WM_CAPTURECHANGED` 回声**，`ReleaseMouseCapture()` 自己**不碰**托管捕获状态：

```
PresentationCore/…/InterOp/HwndMouseInputProvider.cs:178  void IMouseInputProvider.ReleaseMouseCapture()
:181                  _haveCapture = false;
:190                  SafeNativeMethods.ReleaseCapture();     ← 只有这一句到 shim
```

### 3.2 回声要起作用，必须**同时**过两道门

**门 (i)**（provider 侧，`HwndMouseInputProvider.cs:679-748`）：

```
:720      if(lParam != _source.Handle)          // 0x0 != 0x200005 ⇒ 通过
:723          _haveCapture = false;
:730          if(!IsOurWindow(lParam) && _active)       ← ★ 门(i) = _active
:732              ReportInput(hwnd, …, RawMouseActions.CancelCapture, 0,0,0);
:741-745      if(lParam != IntPtr.Zero || !_tracking) PossiblyDeactivate(lParam, true);
```

`IsOurWindow(0)` = **false**（`:1167-1211`：`hwnd == IntPtr.Zero` ⇒ `isOurWindow = false`）⇒ 门(i) 的唯一变量就是 `_active`。
`_active` 怎么会是 false：

```
HwndMouseInputProvider.cs:74-82   void IInputProvider.NotifyDeactivate() { if(_active){ StopTracking(…); _active = false; } }
MouseDevice.cs:1433-1441          else if (_inputSource != rawMouseInputReport.InputSource) {
                                      IMouseInputProvider toDeactivate = _inputSource.GetInputProvider(typeof(MouseDevice)) as IMouseInputProvider;
                                      _inputSource = rawMouseInputReport.InputSource;
                                      toDeactivate?.NotifyDeactivate();      ← ★ 把上一个 provider 打成 _active=false
                                  }
```

**门 (ii)**（MouseDevice 侧，**这是更硬的一道**）：

```
MouseDevice.cs:1408-1411   // Normally we only process mouse input that is from our
                           // active presentation source. The only exception to this is the activate report…
:1412                      if ((rawMouseInputReport.Actions & RawMouseActions.Activate) == RawMouseActions.Activate) { … 切换 _inputSource … }
:1444-1445                 // Only process mouse input that is from our active presentation source.
                           if ((_inputSource is not null) && (rawMouseInputReport.InputSource == _inputSource))
:1460-1464                     if ((actions & CancelCapture) == CancelCapture) ChangeMouseCapture(null, null, CaptureMode.None, …);
```

⇒ 报告是从**主窗口源**发出的（`InputSource` = 主窗口），而此刻活跃源是**弹窗源** ⇒ **整段被跳过**，`ChangeMouseCapture(null)` 根本不会跑。

### 3.3 "活跃源在释放那一刻是弹窗"，是**实测**（不是推断）

* `app.log:617`（`L8` 按下**之前**）已经是一条**弹窗源**产出的 `EVT move root=124,35 …`（坐标是弹窗客户区系），且它前面那条 motion 是 `[msg] hwnd=0x200008 msg=0x0200` ⇒ 弹窗的 `HwndMouseInputProvider` 正在报输入；
* `L6b` 腿（`app.log` 597-612）同样：`[msg] hwnd=0x200008 msg=0x0200` + `EVT combo.focus` ⇒ **弹窗源在按下之前就已接管**。

---

## §4 分界读数（④）

### 4.1 受控 A/B（同一趟、同一条腿型、同一个释放消息）

| | `L7_combo_blank`（点外面关） | `L8_comboitem1`（点选项关） |
|---|---|---|
| 下拉状态 | 开着 ⇒ 关 | 开着 ⇒ 关 |
| **按下落在哪个 X 窗口** | **主 `0x200005`**（`app.log:534`） | **弹窗 `0x200008`**（`app.log:629`） |
| shim 的释放回声 | `hwnd=0x200005 wp=0x0 lp=0x0`（`:535`） | `hwnd=0x200005 wp=0x0 lp=0x0`（`:639`） |
| 释放后托管捕获 | **`null`**（`:536`, `:561`） | **`ComboBox`**（`:645`, `:650`） |
| 之后窗口内点击 | 正常（`c01/c02` 绿） | 被路由给 ComboBox（`c06/c11` 红） |

**唯一自变量 = 按下落在哪个窗口**；shim 侧的自变量被**冻住**（同 hwnd / 同消息 / 同 wp / 同 lp）。
⇒ **失败点是托管侧"活跃源 == 报告源"这个前提**：`_active`（门 i）与 `InputSource == _inputSource`（门 ii）**都由"活跃源是弹窗"驱动**，两者在 `L8` 下都关着；`L7` 下打开（按下落在主窗口 ⇒ 主窗口 provider 保持/重新活跃）。

### 4.2 判定

* **假设 ①：推翻**（§2.1 的 `0x0215` 计数 + §1.3 的原始行）。
* **假设 ②：措辞推翻、族成立** —— 不是"`ComboBoxItem` 粘性捕获"（它一行捕获代码都没有），而是**托管侧捕获状态没被清**，机制见 §3.2 两道门。
* **本件的分界读数指向：托管侧。** shim 的派发**正确**（派给失去捕获的窗口、`lParam` 语义正确、可执行文件里真有这段 —— 反汇编 `SetCapture`/`ReleaseCapture` 各含 `mov $0x215,%esi; call wpf_dispatch_to_window@plt`）。
* ⚠️ **边界（不许把这条读成"shim 没问题"）**：shim 仍有一处**结构性**欠账（§2.2 "捕获不参与投递" + §2.3 "DestroyWindow 不清捕获"），只是**它们不是本缺陷的成因**；成因链是"按下落在弹窗 ⇒ 活跃源翻转 ⇒ 托管两道门关上"。

### 4.3 为什么**不**建议在 shim 侧"把输入重定向给捕获者"

`ComboBox.cs:1700-1703` 的注释逐字写着：**"When we have capture, all clicks off the popup will have the combobox as the OriginalSource"** —— 反过来说：**捕获期间"弹窗上"的点击本来就该落到弹窗**（否则选项点不中）。本机实测正是"落到弹窗 ⇒ `EVT combo.selection=1`"（`app.log:637`）。把按下重定向到主窗口会**打坏选项命中**（把 `c05` 弄红）⇒ 那是**反向**修法。

---

## §5 给修法车道的精确落点与判据（⑤）——本件**不落地**

### 5.1 首选 `M1`：在"我们主动要求释放"的那一处补齐状态变更（托管侧，最小、语义保全）

**落点**：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Input/MouseDevice.cs:386-394` 的 `else` 分支，在 `mouseInputProvider.ReleaseMouseCapture();`（`:388`）之后补一句：

```csharp
ChangeMouseCapture(null, null, CaptureMode.None, timeStamp);
```

**为什么是这里**：`:388` 是全进程**唯一**知道"我们刚刚主动要求了释放"的位置；门 (i)/(ii) 都依赖"回声必须来自活跃源"，而这个前提在**跨窗口**（弹窗）场景下**不成立**。
**语义保全（逐条核过，不是猜）**：

* **幂等**：`ChangeMouseCapture` 首行就是 `if(mouseCapture != _mouseCapture)`（`MouseDevice.cs:1032`）⇒ 回声若真来了，第二次调用是**空操作**；
* **不丢事件**：它与回声路径**同一个函数** ⇒ 一样会 `_providerCapture=null`（`:1043-1046`）、摘/挂三个 DP 回调、发 `LostMouseCapture`/`GotMouseCapture`（`:1121-1141`）、`Synchronize()`（`:1144`）；
* **生成方式照仓内惯例**：新增 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-*.py` 形态的应用器（`MouseDevice.cs` 今天**没有**任何应用器/生成物 ⇒ 锚点干净），照既有纪律：锚点必需命中 1 次、`throw` 条数与大括号盈亏与上游逐字相同、`--check` 只读自证。

**⚠️ 必须同趟检查的"再捕获"路径（否则可能把"粘在 ComboBox"换成"粘在已销毁弹窗"）**：
`Popup.cs:1209-1240 OnLostMouseCapture` 里 `reestablishCapture = e.OriginalSource != root && Mouse.Captured == null && SafeNativeMethods.GetCapture() == IntPtr.Zero` ⇒ 真则 `EstablishPopupCapture()` ⇒ 若 `StaysOpen==false` 且 `CaptureEngaged==false`，会在**弹窗窗口**上重取捕获（`Popup.cs:1168-1174`），而关下拉后弹窗随即被销毁、`DestroyWindow`（`win32_core.c:946-984`）**不清** `g_capture_window`。
⇒ 判据必须能分辨：修后 `captured=` 普查里若出现 **`PopupRoot`**（或捕获仍非 `null`）⇒ 就是这一支，需同时处理 `Popup` 路径或补 §5.3。

### 5.2 备选 `M2`（更窄，**我预测它不够** —— 这是可证伪的实验，请先跑它）

放宽 `HwndMouseInputProvider.cs:730` 的 `&& _active`（改成"本窗口是捕获持有者就报 `CancelCapture`"）。
**我的预测：单做 M2 不变绿** —— 报出来的 `RawMouseInputReport.InputSource` 仍是**主窗口源**，会被 `MouseDevice.cs:1445` 的 `InputSource == _inputSource` 整段丢掉（`:1408-1412` 的注释逐字支持）。
**判决方式**：改完 M2 直接跑 §1.1 那条命令（36 s）。**若单做 M2 就绿了 ⇒ 我对门 (ii) 的判读错了**（我不会为了让预测好看而保留它；请把那趟读数记回来）。

### 5.3 同族欠账（shim 侧，与本缺陷**无因果**，便宜，建议一并推进）

`win32_core.c:946-984 DestroyWindow`：捕获窗口被销毁时**清 `g_capture_window`**（并在有必要时派发 `WM_CAPTURECHANGED`）。判据形态：造一个"持有捕获的窗口被销毁"的用例 ⇒ 之后 `GetCapture()` 必须为 `NULL`。
⚠️ **不许**把它当成 `D-G85` 的修法：它与本缺陷的成因链无关（本趟弹窗从未持有捕获，§2.1）。

### 5.4 修法车道必须交的成对读数（判据）

1. **主判据**：§1.1 那条**同一命令**（≈36 s）⇒ 现在 `R_GATE=FAIL crit=11/13 … fails=c06(L8_comboitem1,SEQ_lst0,SEQ_tb),c11(seq-lst0,seq-tb)`；修后**必须** `R_GATE=PASS crit=13/13 red=0`。
   **不许**为了变绿去放宽 `c06` 的豁免（`r-gate-step.sh` 的"下拉仍开着"豁免只许覆盖"开着"那一档 —— W84A §3⑥ 已把该口径写进 `docs/WAVE50-PREREGISTRATION.md`）。
2. **逐腿 `captured=` 普查（本件用的同一条口径）**：`L8_comboitem1`/`SEQ_lst0`/`SEQ_tb`/`SEQ_combo` 四腿**全部** `null`；`grep -c 'captured=ComboBox'` 从 **15** 降到 **5**（合法残留 = `L6_combo` 2 条 + `L6b_combo_reopen` 2 条 + `L7` 首条 1 条），`captured=PopupRoot` 仍须 **0**（若变非 0 ⇒ §5.1 的再捕获支）。
3. **防过修（反向腿）**：`L7_combo_blank` 仍须 `captured=null`；`c01/c02/c04/c05/c13` 五格仍全绿；`EVT lst.selection=1`、`EVT tb.focus`、`combo.opened` 计数不许掉（第 2 条腿的 `SEQ_lst0` 必须收到 `EVT lst.down`、`SEQ_tb` 必须收到 `EVT tb.focus`）。
4. **反极性（假绿检测）**：`bash build/MilBridge/tools/r-gate-step.sh --selftest` 必须仍 `21/21`；把 `win32shim` 换回 W84A 的反极性件 `3e4390c9ec07f621` 那趟必须仍能红（判据不许恒绿）。
5. **件账**：`pc` 必变（托管改动）、`win32shim` **不该**变（除非同趟做 §5.3）、`hbtextline` **必须逐位不变**；`inputs_fp` 按 `close-wave.sh:68-79` 现场算（应用器在覆盖面内 ⇒ 必变）。

---

## §6 `NOINFO`（⑥，**既不算绿也不算红**）

1. **"哪一道门先挡住"未测**：门 (i)`_active` 与门 (ii)活跃源身份**都由同一件事驱动**，本机**没有任何**开关能直读它们（§2.4 的 `getenv` 全清单里没有）。**要哪一种读数**：`RawMouseInputReport.Actions` 里到底有没有 `CancelCapture`。**怎么取**：给现成插桩 `patch-presentationcore-inputsite-trace.py`（生成物 `InputProviderSite.Linux.cs`，插桩类 `WpfLinuxInputTrace.B2ReportInput`）的 P1 再补一个字段 —— 现在 `ReportOf()`（`patch-presentationcore-inputtrace.py:267-273`）**只打** `类型名/Type`、**不打** `Actions`，且非 Text 报告有采样上限 `MaxB2OtherLines`（Mouse 类会被上限吃掉，`:283-299`），两处都要动。**判决**：点选项后若出现 `Actions` 含 `CancelCapture` 的 P1 行而捕获仍在 ⇒ 门 (ii) 单独成立；若**一条都没有** ⇒ 门 (i) 先挡住。
   **本件未做**：那要改应用器 + 重建 `pc`（`DOTNET`/世代位移），**超出"只读"授权**。
2. **"真机 Windows 上这一刻谁是捕获持有者"不可测**（本机无 Windows）：这决定本缺陷是"移植偏差"还是"上游本来就有的行为"。间接旁证：`Popup.cs:1136-1137`+`:1168` 的 `EstablishPopupCapture` 被 `if (capturedElement == null)` 门住，而 `ComboBox.cs:220` 在开下拉时**先**拿了捕获 ⇒ 上游逻辑下 **Popup 不参与捕获**；本机实测 `captured=PopupRoot` **0 次**，与该推论**一致**（"一致"≠"证明"）。
3. **`g_capture_window` 的时序是"可复算推导"，不是直读 HWND**：依据是"`0x0215` 的唯一来源是 `SetCapture`/`ReleaseCapture`（`win32_core.c:1455`/`:1468`）"+"`ReleaseCapture` 必带 `lp=0`、`SetCapture` 必带 `lp≠0`"（§1.3 的 4 条全是 `lp=0`）⇒ 推定释放后 `GetCapture()==NULL`。**要直读**：在探针里 `[DllImport("user32.dll")] GetCapture()` 打进 `EVT move` 行（探针 = `samples/WpfFeatureProbe/FeatureBlocks.cs:1227`，加一个字段即可）—— 那会改样本 sha 且与另两条在跑的车道共用装置，**本件故意没动**。
4. **hc 真实应用上的同族现象**仍未测（W84A §7⑥ 已记）。
5. **整趟 `verify-all` 未跑**（任务书禁止）；第 `[26]` 步在整趟里的次序/耗时只有静态保证（`VERIFYALL_SELF` 那套本件没跑）。
6. **本趟装置顺带重建了样本**：`probe=2f4acc9a2f61769f`（09:47:21），W84A 那趟是 `e29e08cbfc26acc8` ⇒ **探针 sha 会随重建漂**，跨趟比 `probe=` 无意义（装置自报，本件未改一行探针源码：`FeatureBlocks.cs` = `1e8512c0692f350d`）。

---

## §7 读数表与内存三值（⑦）

**lane** `W87A`｜**时间** 2026-09-22 09:43:10 → 09:49:47 +0800｜**kernel** `6.8.0-138-generic`｜**nproc** `3`

| 量 | 读数（口径） |
|---|---|
| `loadavg` | 09:43 `2.14 2.15 1.99`；装置自报 `1.86 2.18 2.04`；收工 09:49 `4.00 2.66 2.21`（本机 3 条车道并发） |
| `MemAvailable` | 开工 **2256 MB** → 进槽前最紧 **1283 MB** → 槽内装置自报 **2522 MB**（槽门槛 1500 MB，`HEAVYSLOT=MEMOK avail=2523MB`）→ 收工 **1248 MB**（另两条车道在跑，见 §6 边界） |
| 重活 | 整条命令**都在** `~/heavy-slot.sh --min-avail 1500 --max-hold 200` 内（未出现 `MAXHOLD_KILL` / `NOINFO low-memory`）；`ACQUIRED waited=58s` / `RELEASED rc=1 held=36s` |
| 复现器 | `R_GATE_FAIL` 机读行见 §1.1；`rc=1`（判据 `FAIL`，**非** `127`/`MSB1009`） |

**产品件 sha16（跑前/跑后现场算，非手抄）**

| 件 | 本趟装置用的值 | 现在盘上的值 | mtime | 谁动的 |
|---|---|---|---|---|
| `win32shim` (`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`) | `24e906c194903c8b` | `24e906c194903c8b` | 09-22 09:30:24 | 不是我 |
| `pc` (`build/PresentationCore.Linux/bin/Release/PresentationCore.dll`) | `56ee75ced8d6aece` | `56ee75ced8d6aece` | 09-21 17:20:35 | 不是我 |
| `pf` | `0018b509567434df` | **`78218dd1851d41e8`** | 09-22 **09:49:21** | **另一条车道**（我 09:47 跑完之后） |
| `wb` / `bridge` | `2e4e46e539a72cd7` / `feef049e9d0e313a` | 同 | 09-21 | 不是我 |
| `probe`（样本，装置自建） | `2f4acc9a2f61769f` | `2f4acc9a2f61769f` | 09:47:21 | 装置（步 `[26]` 的常规行为） |

> **`pf` 位移不影响本件结论**：W84A 那趟（`pf=78218dd1851d41e8`）与本趟（`pf=0018b509567434df`）**红格逐格相同**（§1.4）。

**本件自己的读数件（现场算）**

| 件 | sha16 | 大小 | mtime |
|---|---|---|---|
| `$HOME/w87a/rgate1/app.log`（775 行，全部原始行） | `3642b118f5cf566a` | 93,563 B | 09-22 09:47:54 |
| `$HOME/w87a/rgate1/evidence.txt` | `a06a91e0ab064daa` | 2,966 B | 09-22 09:47:54 |
| `$HOME/w87a/rgate1.step.out`（含 `R_GATE=` 与槽读数） | `bb412c5435942501` | 3,187 B | 09-22 09:47:55 |
| 判据件 `build/MilBridge/tools/r-gate-step.sh` | `f263341ad376d51f` | —— | 09-22 09:38 |
| 装置 `build/MilBridge/tests/RGateClickProbe/run-r-gate-legs.sh` | `93f914d6c041c88d` | —— | 09-22 09:28 |
| 探针源码 `samples/WpfFeatureProbe/FeatureBlocks.cs`（**未改**） | `1e8512c0692f350d` | —— | —— |

**写域**：仓内**只新增** `build/MilBridge/W87A-report.md`；其余全部落 `$HOME/w87a/**`。**未跑** `integration-wave.sh` / `close-wave.sh` / `verify-all.sh`；**未** `pkill -f`；**未**改 `src/WpfGfx.Linux.Native/**`、`build/shims/**`、`build/PresentationCore.Linux/**`、`build/PresentationFramework.Linux/**`、`build/MilBridge/tools/**`、四个路由件、`defect-registry-declared.tsv`。

---

## §8 ≤6 行大白话小结（⑧）

1. **分界读数取到了**：点选项那一刻 shim **确实**派发了 `WM_CAPTURECHANGED`（派给**捕获持有者主窗口**、`lp=0`）—— 假设①「没派发给弹窗」**被推翻**：**弹窗从来没持有过捕获**，所以"派给弹窗"没有对象。
2. 假设②**措辞也不对**（`ComboBoxItem` 里一行捕获代码都没有），**但它指的那一侧是对的**：**托管侧的捕获状态没被清掉**。
3. **受控 A/B 是铁证**：同一条腿型、**同一个释放消息**（`hwnd=0x200005 / wp=0 / lp=0`），**点外面关就释放、点选项关就不释放**；唯一变量 = **那一下按在主窗口还是弹窗窗口**。
4. 机制两道门都在托管侧：`HwndMouseInputProvider.cs:730`（`_active`）与 `MouseDevice.cs:1445`（报告源必须 == 活跃源）—— 而活跃源在那一刻是**弹窗**（`app.log:617/629` 实测）。
5. **修法落点建议**：`MouseDevice.cs:386-394` 的释放分支补一句 `ChangeMouseCapture(null, null, CaptureMode.None, timeStamp)`（幂等、事件语义不变）；**别**在 shim 侧把输入重定向给捕获者（`ComboBox.cs:1700-1703` 证明那样会**打坏选项命中**）。
6. 我**没做到**的：哪道门先挡住（要报告级 `Actions` 插桩）、真机 Windows 的对照、`GetCapture()` 的**直读**时序（本件给的是**可复算推导**）；以及**没跑整趟 `verify-all`**。

---

**本报告自身 sha16**（口径：**`head -n -2 build/MilBridge/W87A-report.md | sha256sum | cut -c1-16`** —— 即"末两行（本行 + 下一行）之外的全文"，所以**读者可以现场复算并必须得到同一个值**）＝ **`f1fb2a8894486248`**（425 行，回填本值之前算的）。
⚠️ 回填这一行之后全文 sha 就变了（"报告自指"的老问题）⇒ 引用时**按上面这条命令现场重算**，别抄我这个数。

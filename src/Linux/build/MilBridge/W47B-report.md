# W47B 报告 —— 把"点击某控件有没有反应"变成**仓内可复算判据**

`lane=W47B`｜2026-09-19 22:34→22:50 +0800｜kernel `6.8.0-138-generic`｜`nproc=3`｜`loadavg` 0.77→1.23｜
`MemAvailable` 2,263→2,674 MB｜**未跑** `integration-wave`/`verify-all`/冻结｜**未改** `tests/**`、`src/**`、`known-red.json`、任何 `build/*.sh`

---

## 0. 一行结论

判据**立住了**，而且**当场判红**：

> 在冻结件 `#46`（`pc 043eff4b1d8ecd7d`／`pf 366e9486536bc291`／`bridge e3ea092010734f44`／`win32shim e700c383ec1ecdc8`）上，
> **点一次控件之后，`Mouse.Captured` 一直挂在那个控件上不被释放** ⇒ **鼠标再点到窗口内任何别的地方，事件都被送给上一个控件**
> （`e.OriginalSource` 与 `Mouse.DirectlyOver` 冻结在上一个控件，而**当场**算的 `VisualTreeHelper.HitTest` 报的是正确的元素）。
> ⇒ 表现为：**连点三个控件，只有第一个有反应；后两个"点了没反应"**（`EVT tb.focus` 0 行、`EVT combo.opened` 0 行）。
> 把指针**移出窗口再回来**才恢复（那是释放捕获的动作）⇒ 我第一版驱动"每步把指针停到窗口外"**因此全是假绿**。

`D-G49`（`GetKeyState` 恒 0）**确已修好**：本次每一条原始命中读数的 `e.ButtonState` 都是 `Pressed`（按下）/`Released`（抬起），逐条见 §3。
本波发现的是**另一个、独立的**缺陷（建议登记 `D-G55`，编号由主控定）。

---

## 1. 交付物与改动（写域内）

| 件 | before sha16 | after sha16 | 说明 |
|---|---|---|---|
|  `samples/WpfFeatureProbe/FeatureBlocks.cs` | `a24be8f2031a7319`（67,316 B） | **`1e8512c0692f350d`**（82,762 B） | 新增块 ⑬ `ClickProbeBlock`（`:1093-1336`） |
| `samples/WpfFeatureProbe/MainWindow.xaml.cs` | `f406b75397a1649c`（7,860 B） | **`1bd652e0dba3bd6b`**（8,150 B） | `:55` 注册 `new ClickProbeBlock()` |

备份（改动**前**，纪律 65）：`$HOME/w47b-backup/FeatureBlocks.cs`、`$HOME/w47b-backup/MainWindow.xaml.cs`（`cp -p`）。

### 1.1 块 ⑬ 的写法（文件:行）

- 类与名：`FeatureBlocks.cs:1112` `internal sealed class ClickProbeBlock : ProbeBlock`，`:1118` `Name => "clickprobe"`，`:1120` `NeedsLateCheck => true`。
- ① ListBox（3 项）：`:1159-1171`。语义行 `:1164` `Ev("lst.selection=" + _lst.SelectedIndex)`；焦点行 `:1165`；
  **原始命中** `:1166-1170`（`AddHandler(MouseLeftButtonDown/UpEvent, …, handledEventsToo: true)`，逐条打印 `e.ButtonState`）。
- ② TextBox：`:1173-1182`。`tb.focus` `:1174`、`tb.kbdgotfocus` `:1175`、`tb.text=<len>` `:1176`、`tb.down/tb.up` `:1177-1181`。
- ③ 标准 ComboBox（3 项）：`:1185-1205`。**项容器染测试色 `22D3EE`** `:1188-1193`（关着时屏上不该有它 ⇒ 独立像素判据）；
  `combo.opened` `:1197`（打开后 `ReportPopupItems()` 报项容器坐标）、`combo.closed` `:1198`、`combo.selection=` `:1199`。
- 卡片级兜底命中 `:1207-1209`（`card.down src=…`）：用来区分"整块收不到点击"与"某控件收不到"。
- **坐标自报**：`:1126-1141` `OffsetToRoot()` **逐级累加 `TransformToAncestor` 到根**（**不用** `PointToScreen`/`Window.GetWindow` —— 那三条在本移植上实测抛异常/返回 null，见 `KNOWN-DEFECTS.md` 的 `D-G50` 自伤记录）；
  `:1144-1156` `Pos()` 打 `POS <tag> relx= rely= w= h= loaded=`；`LateVerify()` `:1283` 报 `lst`/`tb`/`combo`/`lstitem0..2`；
  下拉打开后 `:1254-1265` 报 `POS comboitem0..2`（**相对弹窗根** ⇒ 外部驱动加弹窗 X 窗口原点即可点）。
- **坐标诚实性仪器**（本波为定位缺陷加的，留在块里）：`:1217-1228` 每次移动打印
  `EVT move root=<客户区坐标> src=<e.OriginalSource> directlyover=<Mouse.DirectlyOver> freshhit=<当场 HitTest> captured=<Mouse.Captured>`
  （有界 300 行）；`:1272-1281` 报 `POS bounds`（`ActualWidth/Height` vs `GetDescendantBounds` vs `RenderSize` vs `Clip`）；
  `:1302-1311` `POS hittest x=200|294 y=30..230`（机内命中梯子）。
- 块自报台账：`LateVerify()` 末尾 `:1318-1322` 记 **`INCONCLUSIVE`**（"载体已建，点击判据由外部驱动给"）——
  **不许**用"载体建好了"冒充"点击可用"（`D-G50` 假绿同族）。

### 1.2 驱动（`$HOME/**`）

| 脚本 | sha16 | 作用 |
|---|---|---|
| `$HOME/w47b-click.sh` | `7e86e3f105dc8778` | **主驱动**：私有 Xvfb(:93)＋私有 app 目录＋`xdotool` 真实节奏点击（`mousedown`→停 150 ms→`mouseup`）；§1–§3 逐类点击、§4 **序列判据** |
| `$HOME/w47b-seq.sh` | `fe382f3b8337eeb0` | 两趟对照：A 连做 / B 每次先把指针停到窗口外（**两极化**） |
| `$HOME/w47b-ovr.sh` | `22ae0ac1bda903e0` | 冷/热态指针梯子（`directlyover` vs `freshhit` vs `captured`） |
| `$HOME/w47b-hit.sh` | `66820b19cabf6ace` | 冷态/热态点击落点对照 |
| `$HOME/w47b-mapping.sh` | `d883c782c7105bfe` | 屏幕坐标 ↔ WPF 客户区坐标映射 + 机内命中梯子 |
| `$HOME/w47b-ladder.sh` | `02d3277c6834fa51` | 6 px 步长点击梯子（最早暴露"命中区域位移"的那一趟） |

用法：`bash $HOME/w47b-click.sh`（每次自建 `$HOME/w47b-out-<ts>/READING.txt`，件 sha 跑前/跑后各记一次）。

---

## 2. 判据（**先写死**，再取读数）

三层，全在块内自报、由外部驱动触发：

| # | 动作（外部真实点击） | 必须出现 |
|---|---|---|
| L | 点 ListBox 第 k 项 | `EVT lst.selection=k` |
| T | 点 TextBox | `EVT tb.focus`，且 `xdotool type` 后 `EVT tb.text=<len>` **增长** |
| C | 点 ComboBox，再点弹窗第 2 项 | `EVT combo.opened` → `EVT combo.selection=1` → `EVT combo.closed` |
| S | **序列**：L→T→C **连做**（指针只移动、不停到窗口外） | 三条同时成立（= 真实用户动作） |

反极性/阴性对照（**必须能红**）：

- N1：点卡片里**控件之外**的空白 ⇒ 只应有 `card.down`，**不得**出现 `lst.selection`/`tb.focus`；
- N2：改点 ListBox 第 0 项 ⇒ `lst.selection` 必须跟着变成 0（判据跟着**被点那一项**走，不是"点哪儿都过"）；
- N3：A（连做）与 B（先移出窗口）两趟必须给出**不同**结论 —— 否则这条判据咬不住状态。

---

## 3. 读数（逐条原文）

### 3.1 件与基线核对（跑前/跑后**逐位相同**）

```
ARTIFACTS before bridge=e3ea092010734f44(5019968) pc=043eff4b1d8ecd7d(3601408) pf=366e9486536bc291(6119424)
                 win32shim=e700c383ec1ecdc8(299040) wic_shim=56278c14b4ecd672 hbtextline=e89fed55fd8e32bc selfbuilt=Release
ARTIFACTS after  （与 before 逐位相同）
APP_ARTIFACTS bridge=e3ea092010734f44 pc=043eff4b1d8ecd7d pf=366e9486536bc291 win32shim=e700c383ec1ecdc8
WINDOW id=2097157 X=0 Y=0 938x938           ← 无窗口管理器（裸 Xvfb）
probe dll = fc388e1cfda9db62（61,952 B）
```
⇒ 与 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:40` 的**冻结 `#46` 九位**逐位一致（`bash build/MilBridge/tools/baseline-sha-check.sh` ⇒ `BASELINESHA=PASS`），**没有并发换件**。

结构（自报）：
```
POS lst   relx=164 rely=38  w=260 h=78 loaded=True     POS lstitem0/1/2 rely=40/53/66 h=12
POS tb    relx=164 rely=122 w=260 h=26 loaded=True
POS combo relx=164 rely=154 w=260 h=26 loaded=True
POS bounds lst actual=260x78 render=260x78 descendant=(0.0,0.0,260.0,78.0) clip=null     （tb/combo 同形）
```
⇒ 无"布局矩形 ≠ 渲染范围"的问题（`descendant` 与 `actual` 相等、`Clip=null`）。

### 3.2 三类点击 —— **绿的那一趟**（每一步之间把指针停到窗口外；`$HOME/w47b-out-0919-223739`）

```
1) ListBox 第 1 项 (294,59)：AE=28
   EVT lst.focus | EVT lst.selection=1 | EVT lst.down src=Border state=Pressed clicks=1 | EVT lst.up src=Border state=Released
2) TextBox (294,135)：AE=56
   EVT tb.focus | EVT tb.kbdgotfocus | EVT tb.down src=TextBoxView state=Pressed | EVT tb.up state=Released
   键入腿 `xdotool type --window 2097157 abc`：
   EVT tb.text=1 text='a' / =2 'ab' / =3 'abc' / =4 'abca' / =5 'abcab' / =6 'abcabc'   ← 两趟 type 都进了文本
3) ComboBox (294,167)：点击 ⇒ EVT combo.opened | combo.focus | combo.down src=DockPanel state=Pressed
   新 X 窗口：0x200007 X=171 Y=189 271x77 MapState=IsViewable        ← 下拉**真的建了独立 X 窗口**
   测试色 22D3EE（只有下拉项容器染它）：**19,449 px**（整屏直方图）  ← 下拉**真的画出来了**
   POS comboitem0/1/2 relx=1 rely=1/25/49 w=258 h=24
   点弹窗第 2 项 (301,226) ⇒ EVT combo.selection=1 | combo.focus | combo.closed
```
⇒ 三类**都能有反应**，而且 `e.ButtonState` 全程 `Pressed`/`Released` 正确（`D-G49` 已修好的正面证据）。

### 3.3 判据的**诚实口径**（序列连做）—— **红的那一趟**（`$HOME/w47b-out-0919-224552`）

```
--- 4) 序列判据（连做；指针只移动、不停到窗口外）---
S1 ListBox item1 (屏幕y=59)  ⇒ EVT move root=282,56  src=Border   directlyover=Border   freshhit=Border   captured=null
                                EVT lst.focus | EVT lst.down src=Border state=Pressed | EVT lst.up src=Border state=Released
S2 TextBox     (屏幕y=135) ⇒ EVT move root=282,129 src=ListBox  directlyover=ListBox  freshhit=TextBoxView captured=ListBox
                                EVT lst.down src=ListBox state=Pressed | EVT lst.up src=ListBox state=Released      ← **TextBox 一次都没收到**
S3 ComboBox    (屏幕y=167) ⇒ EVT move root=282,160 src=ListBox  directlyover=ListBox  freshhit=DockPanel   captured=ListBox
                                EVT lst.down src=ListBox state=Pressed | EVT lst.up src=ListBox state=Released      ← **ComboBox 一次都没收到**
判据读数：lst.selection=1（有） / tb.focus **0 次** / combo.opened **0 次** / tb.text **0 行**
MSG 计数：WM_LBUTTONDOWN=9 WM_LBUTTONUP=9   ← 点**确实到了窗口**（不是"没点到"）
台账行：[feat] clickprobe INCONCLUSIVE …（块自报 INCONCLUSIVE，未冒充通过）
app.log 异常行：0
```
同一进程内、同一坐标、只差"中间有没有把指针移出窗口"，结论就相反 —— 见 §5 的 A/B 对照。

### 3.4 阴性对照（判据**能红**的证明）

```
1b) 点卡片里控件之外的空白 (560,100) ⇒ 只有 EVT card.down src=Border（**无** lst.selection/tb.focus）
1c) 改点 ListBox 第 0 项 (294,44)   ⇒ EVT lst.selection 序列 = 1 → **0**（跟着被点那一项走）
```

---

## 4. 命中链 / 时序的原始证据 与 判定点

### 4.1 现象（proven，两趟独立复现）

冷态（**尚未点过任何控件**）指针梯子 —— 三个读数**完全一致**：

```
y=44  屏幕 ⇒ root=282,42  src=Border      directlyover=Border      freshhit=Border
y=135 屏幕 ⇒ root=282,129 src=TextBoxView directlyover=TextBoxView freshhit=TextBoxView
y=167 屏幕 ⇒ root=282,160 src=DockPanel   directlyover=DockPanel   freshhit=DockPanel
captured=null（每一行都是 null）
```
**点一次 TextBox 之后**，同一条梯子 —— 三个读数**分叉**：

```
y=44  屏幕 ⇒ root=282,42  src=TextBox directlyover=TextBox freshhit=Border      captured=TextBox
y=135 屏幕 ⇒ root=282,129 src=TextBox directlyover=TextBox freshhit=TextBoxView captured=TextBox
y=167 屏幕 ⇒ root=282,160 src=TextBox directlyover=TextBox freshhit=DockPanel   captured=TextBox
y=200 屏幕 ⇒ root=282,192 src=TextBox directlyover=TextBox freshhit=null        captured=TextBox
```
⇒ **`Mouse.Captured` 一直是那个 TextBox**；输入系统（`e.OriginalSource` / `Mouse.DirectlyOver`）**冻结在它身上**，
而**当场**重算的 `VisualTreeHelper.HitTest` 报的是正确元素 ⇒ 后续点击**必然**被送给捕获元素。

同一形态在 ListBox 上也复现（`$HOME/w47b-seq.sh` A 段）：
```
A1 点 ListBox item1 ⇒ captured=null，lst.selection=1    （第一次点击正常）
A2 点 TextBox      ⇒ captured=ListBox，src=ListBox，freshhit=TextBoxView    ⇒ 无 tb.focus
A3 点 ComboBox     ⇒ captured=ListBox，src=ListBox，freshhit=DockPanel      ⇒ 无 combo.opened（还把 ListBox 选择改成了 2）
```
B 段（每次点击前把指针停到**窗口外**再回来）：`captured=null` → 三次点击**全部命中正确控件**（`tb.focus`/`combo.opened` 都出现）。
⇒ **捕获只在"指针离开窗口"时被释放**；鼠标抬起**不释放**。

### 4.2 机制链（**源码级已闭合**，逐跳 `file:line`）

1. 上游在**鼠标抬起**时确实会请求释放：`upstream/.../Documents/TextEditorMouse.cs:364-371`
   `This.UiScope.ReleaseMouseCapture();`（另有 `Patch/Primitives/ButtonBase.cs:485-488` 的同一形态）。
2. `MouseDevice` 释放捕获的路径是**"让输入提供者去释放"**，并**依赖一条回送报告**才更新自己的状态：
   `upstream/.../Input/MouseDevice.cs:386-394` 逐字注释
   *"If we had capture, the input provider will release it. That will cause a **RawMouseAction.CancelCapture** to be processed, which will update our internal states."*
   （托管状态在 `MouseDevice.cs:1028-1047` 的 `ChangeMouseCapture()` 里，`_mouseCapture` 就是 `Mouse.Captured`）。
3. 提供者侧：`upstream/.../InterOp/HwndMouseInputProvider.cs:178-195`
   `void IMouseInputProvider.ReleaseMouseCapture() { … SafeNativeMethods.ReleaseCapture(); }` —— 只调 Win32 `ReleaseCapture()`。
4. **`RawMouseAction.CancelCapture` 的唯一来源** = `WM_CAPTURECHANGED` 的处理分支：
   `HwndMouseInputProvider.cs:679`（`case WindowMessage.WM_CAPTURECHANGED:`）⇒ `:735` `RawMouseActions.CancelCapture`。
5. 我方 shim 的 `ReleaseCapture` **只改自己的软状态、不派发任何消息**：
   `src/WpfGfx.Linux.Native/src/win32_core.c:980-987`
   `BOOL ReleaseCapture(void) { … g_capture_window = NULL; … return 1; }`；
   `SetCapture` 同形 `:970-978`。
   全仓 grep：`WM_CAPTURECHANGED`/`0x0215` 在 `src/WpfGfx.Linux.Native/**` **0 命中**。
   对照：**同一个文件**的 `SetFocus()` `:938-956` 是**会**派发 `WM_KILLFOCUS`/`WM_SETFOCUS` 的
   （连注释都写明了"Win32 的 SetFocus 语义含…"）⇒ 本仓早就知道这个"系统消息回送"的模式，只是**捕获这一路没做**。
6. ⇒ 链闭合：**释放请求发出去了 → shim 把软状态清了 → 但没有 `WM_CAPTURECHANGED` ⇒ 托管 `_mouseCapture` 永不清 ⇒
   之后所有鼠标输入都被路由到那个捕获元素 ⇒ "点了没反应"。**

### 4.3 判定点建议（修复车道的落点）

- **主判定点**：`src/WpfGfx.Linux.Native/src/win32_core.c:980` `ReleaseCapture()` —— 清软状态的同时，向**旧捕获窗口**派发
  `WM_CAPTURECHANGED`（`lParam = NULL`，即"没人接管"）。这个 `lParam` 选值有依据：上游分支 `HwndMouseInputProvider.cs:715-737`
  要求 `lParam != _source.Handle && !IsOurWindow(lParam) && _active` 才上报 `CancelCapture`，`lParam=0` 满足 `!IsOurWindow(0)`。
- **同族**：`SetCapture()` `:970`（Win32 语义：接管时也要给"上一个所有者"发 `WM_CAPTURECHANGED`）。
- **判定点属 shim = 九位里的 `win32shim`** ⇒ 修它**要成波**（重建 → 重取五臂 → 重钉 → 门禁 ×2 → `verify-all` → 冻结）。
- **验收判据就用本波的器械**：`$HOME/w47b-click.sh` 的 §4 序列段必须由红转绿
  （`tb.focus ≥1`、`combo.opened ≥1`、`combo.selection=1`），且 §3 的逐类读数与"下拉测试色 `22D3EE` 出现"不得回退。
- ⚠️ **未做**：我没有改 shim（不在本波写域）⇒ "这就是唯一原因"**未由我两极化证实**；上面是**源码级机制链 + 现象级一致**，
  修复车道必须用"改前红 / 改后绿"两趟坐实。

---

## 5. 反极性、自伤与"判据能红"的证明

| 项 | 读数 | 结论 |
|---|---|---|
| A 连做（不离开窗口） | `captured=ListBox`；C2/C3 的 `src=ListBox`，`tb.focus=0`、`combo.opened=0` | **红**（真实用户动作） |
| B 每步先把指针移出窗口再回来 | `captured=null`；三类**全部命中**（`lst.selection=1`/`tb.focus`/`combo.opened`） | **绿** |
| 同一趟内两极性 | `w47b-out-0919-224552`：§1b 前有一次 `shot()`（指针出窗）⇒ 那次点击正确；§2 无 `shot()` ⇒ 被 ListBox 吞掉 | 判据**两极化**成立 |
| N1 空白处点击 | 只有 `card.down src=Border` | 判据有特异性（不是"点哪儿都过"） |
| N2 改点第 0 项 | `lst.selection` 1 → 0 | 判据跟着**被点那一项**走 |
| 噪声底 | `AE(pre1,pre2)=0`（指针停远处、两次同态抓帧） | 像素读数有底 |

**我自己的仪器自伤（如实登记，两条）**

1. 🔴 **"每步把指针停到窗口外"是我第一版驱动给自己造的假绿**：`shot()` 里的 `xdotool mousemove 1270 1010`
   正好是**释放捕获**的动作 ⇒ 首趟"三类全绿"（`w47b-out-0919-223739`）**不代表判据成立**。
   ⇒ 判据已改成 §4 的**序列口径**（承重的那一条），并在驱动里写明理由（`w47b-click.sh:183-190`）。
2. 🔴 **像素通道（`compare -metric AE`）作为这一类缺陷的判据是弱的**：干净截图**必须**把指针移开，
   而移开就是释放捕获 ⇒ **像素腿会系统性地把缺陷藏起来**。本报告里 `AE` 只作旁证
   （同趟值：`AE(pre1,lst_after)=28`、`AE(pre1,tb_after)=28`、`AE(tb_after,tb_typed)=0`；下拉测试色 `22D3EE=19,449 px` 才是真有鉴别力的那一条）。
   **承重的是 `EVT` 语义行 + `captured` 字段**。
3. 🟡 早期一趟（`w47b-ladder.sh`）里"`y=122..206` 全落 `ListBox`"我先怀疑"命中区域溢出布局矩形"，
   用 `POS bounds` 与机内命中梯子**自己证伪**了（`descendant == actual`、`Clip=null`）⇒ 真因是上面那条捕获；
   该假说已如实作废（保留在报告里，不留在结论里）。
4. 🟡 `lstitem0..2` 自报 `h=12`（相邻 `rely` 步长 13）—— 与 `FontSize` 不匹配的观感值，
   **未查**（不影响本波判据：点击确实命中并改了选择）。登记为待查。

---

## 6. 与 hc 现象的异同

| | 仓内 `clickprobe`（标准控件） | 仓外 hc（HandyControl 第三方样式） |
|---|---|---|
| 载体 | 块 ⑬，**仓内**、自报 `EVT`＋`POS`＋`captured` | `$HOME/hc-linux`，样式层是 HandyControl 模板 |
| 已测到的现象 | **第一次点击有反应；之后窗口内再点别处没反应**（捕获未释放） | 用户报告"点击没反应，包括输入框和列表项"；主控独立复测 **TextBox 页点击是好的**（`focus=TextBox`，`type abc` ⇒ `len 4→7`） |
| 与本次缺陷的关系 | 本缺陷**足以解释**"点过一次之后、别处点不动"这一整类现象 | hc 是第三方样式 ⇒ 即使命中路径正确，模板层（透明覆盖层、`DropDownElement`、`ToggleBlock`）仍可能各自出问题（`D-G50` 的既有结论） |
| 不能推出的 | — | **不能**说"hc 的病根就是这个"：hc 的输入框点击**是好的**，说明捕获那条链在 hc 里至少有一次是通的；本波**没有**在 hc 上取过 `Mouse.Captured` 读数（见 §7）。 |

**可复算的下一步（建议给主控）**：把本波的探针器械形态（`EVT move … captured=` ＋ `Mouse.DirectlyOver` vs `freshhit`）搬到 hc 的只读诊断类处理器里
（hc 已有 `HC_INPUT_DIAG=1` 那条 env 门控通道），在同一进程里读 `Mouse.Captured` ⇒ 一次分清"hc 是这条产品缺陷"还是"第三方模板层"。

---

## 7. `NOINFO` / 未做 / 与门禁的关系

### 7.1 `NOINFO`（没取到的，不猜）

- **hc 应用上的 `Mouse.Captured` 读数**：未取（本波写域不含 hc，且要求"不大动干戈"）⇒ §6 的因果判断**未做**。
- **`WM_CAPTURECHANGED` 修复后的两极化**：未做（要我改 `src/WpfGfx.Linux.Native/**`，不在写域）。
- **键盘焦点链的旁支**：§3.3 的 S2 之后 `xdotool type` 打出 `WM_KEYDOWN=6` 但 `tb.text=0` 行 ——
  这与"TextBox 根本没拿到焦点"**一致**，但我**没有**单独证明"键到了窗口却没进任何控件"（要 `WPF_LINUX_KEY_DIAG=1` 的另一趟）。
- **`lstitem h=12`**：未查。
- **弹窗项点击在"捕获态"下的行为**：本次只有一次观测（弹窗是**独立 X 窗口**，主窗捕获不拦它）⇒
  "捕获不影响弹窗内点击"这条**只观测到一次**，未做极性对照。

### 7.2 ⚠️ 与 `run-wpfprobe.sh` 的关系（**必须由主控收口**）

第 ⑬ 块让**样例注册表**变成 13 块，而 runner 的块表仍是 12 ⇒ **runner 会判红**（这是表滞后，不是功能回归）。
机器证（用 runner 自己的比对逻辑离线复算，**未跑 runner**）：

```
$ python3 tests/WpfGfx.Linux.Tests/Presentation.Tests/probe-block-registry.py --count   ⇒ 13
$ grep -n '^BLOCKS=' tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh:325
  BLOCKS="popup anim opacitymask effects controls textbox-edit virtualize transforms text-rtl text-rtl-pure text-dp-min nativecombo"
⇒ registry=13 table=12 ⇒ MISMATCH(块表缺=clickprobe)
```
⇒ `WFP_BLOCK_REGISTRY=MISMATCH` ⇒ `REGISTRY_RC=1` ⇒ `WFP_GATE=FAIL`；另外端到端检查
（`WFP_MODE … count=13` ≠ `TOTAL=12`）也会判红。
**我无写域改它**（派单书明令不许动 `tests/**` 的 `BLOCKS`/`EXPECT`）⇒ 请主控同趟补两行：
`BLOCKS` 末尾加 ` clickprobe`；`EXPECT` 加一条 `clickprobe:` 规格（本块**下拉项容器色 `22D3EE` 只在打开时出现**，
建议用 `!22D3EE` 负向式：无人点击时不该有它）。
**在补上之前**：`run-wpfprobe.sh` 的全量趟会红，**不要**把它读成产品回归。

### 7.3 未做的判据腿（留给下一波）

- **键盘腿覆盖三类**：本波只做了 TextBox 的键入腿（→ 文本增长）；
  ListBox 的 `Up/Down` 选择、ComboBox 的 `Alt+Down`/`F4` 打开**未做**。
- **窗口外点击、双击、右键**：未做（双击要 `WM_LBUTTONDBLCLK`，本次 `=0`）。
- **把序列判据接进全量门禁**：未做（要 §7.2 的两行 + 一次 `verify-all` 的口径裁决）。

---

## 8. 读数环境（纪律 32）

`lane=W47B`｜`2026-09-19 22:34:42 → 22:50 +0800`（+0800）｜`kernel 6.8.0-138-generic`｜`nproc=3`｜
`loadavg` 起 `0.77 0.65 0.70` → 收 `1.23 0.99 0.85`｜`MemAvailable` 起 2,263 MB、最低 ≈2,263 MB、收 2,674 MB｜
`SwapFree` 全程 ≥ 846 MB｜自起 Xvfb 一律**按 PID 收**（`:93 :94 :95 :96 :88 :87 :89`），**未 `pkill -f`**｜
每次跑前看 `pgrep -a dotnet`（全程**无**别的车道在跑构建）｜`dotnet` 只跑了 `samples/WpfFeatureProbe` 的构建（`-m:1`），
**未碰任何权威件**（跑前跑后四件 sha16 逐位相同，见 §3.1）。

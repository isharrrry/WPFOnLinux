# W47A 报告 —— hc 示例应用「界面里点击没反应，包括输入框和列表项」：五类点击逐条读数 ＋ 两条定位到代码的真缺陷

- 车道：**W47A**｜仓根 `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（下称「仓」）｜hc 应用源 `/home/links-dev/hc-linux`（仓外）
- 时间：2026-09-19 22:34 → 2026-09-20 00:1x +0800｜`nproc=3`｜`dotnet` 一律 `-m:1` + `DOTNET_gcServer=0`
- **写域**：`$HOME/w47a/**`（装置）＋ `$HOME/w47a-app/`（私有应用副本）＋ `/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/App.xaml.cs`（只加**只读**仪器）＋ 本报告
- **未改仓内任何其它文件**（`win32_x11.c` / `src/WpfGfx.Linux/**` / `verify-all.sh` / `known-red.json` / `*.tsv` 全未动，见 §9 的 sha 自证）；**未跑** `integration-wave` / `verify-all` / 冻结

---

## 0. 一句话结论

1. **用户报告在冻结 `#46` 上不可复现**：我按应用自报的屏幕坐标（`[GEO]`）逐类点击，**页面内 ListBox 项、导航区搜索框、组合框弹窗里的项、DataGrid 行、TreeView 节点全部会激活**（含 `sel`/`len`/`focus` 与会话事件的成对读数，§2）。
2. **但抓到一条更严重的、能一击杀死进程的真缺陷（缺陷 A）**：**BAML 页面的 `NameScope` 从来没挂到页面根上** ⇒ 任何「`Loaded` 触发器 ＋ `Storyboard.TargetName`」的页面一加载就抛未处理异常 ⇒ **进程 abort**。复现：点左侧页签「工具」→ 点该页第 2 项 `MorphingAnimation` ⇒ 应用当场死（两次复现，§3）。
3. **缺陷 A 的判定点是一处「插桩把属性块打断」**：`build/WindowsBase.Linux/DependencyObject.Linux.cs:51-52` 的两条类属性（含 **`[NameScopeProperty("NameScope", typeof(NameScope))]`**）后面被插进了 `WpfLinuxDpValueTrace` 类（`:64`），于是这两条属性**挂到了插桩类身上**，而 `DependencyObject`（`:614`）变成**零属性**（实测 `attrCount=0`）。生成它的规则在 `src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py:832`（锚 = 类声明行 `:628`）。
4. **同族第二例**：`build/PresentationFramework.Linux/FrameworkElement.Linux.cs:100-102` 的三条属性同样被 `WpfLinuxMirrorTrace` 打断（生成规则 `patch-presentationframework-mirror-trace.py:283`，锚 `:252`）。
5. 附带一条**机器可量的观察**：「工具/控件/样式」**页签标题**与「实用示例」**按钮文字**在冻结 `#46` 上**根本没渲染**（页签行 `colors=1, stddev=0%`；按钮 `colors=8, stddev=0.15%`；对照导航项 `colors=69, stddev=10.47%`）⇒ 用户看到的顶部导航是**空白**，这本身足以造成「点了没反应」的主观感受（§5，根因未定位 = `NOINFO`）。

---

## 1. 装置与现场（可复算）

**跑应用的三条纪律**：私有目录 `$HOME/w47a-app/`（`cp -p` 整套）＋ **私有 display**（`:46/:47/…/:65`，被占则 `NOINFO display-busy` 退出，**绝不抢**）＋ 自起 X 按 PID 收（不用 `pkill`）。

每趟跑前现场算四件 sha16，**20 趟逐趟相同**（冻结 `#46` 期望值）：

| 件 | 实测 sha16（每趟现场算） | 期望（`#46`） |
|---|---|---|
| `libwpfwin32.so` | `e700c383ec1ecdc8` | ✅ 同 |
| `wpfgfx_cor3.so` | `e3ea092010734f44` | ✅ 同 |
| `PresentationCore.dll` | `043eff4b1d8ecd7d` | ✅ 同 |
| `PresentationFramework.dll` | `366e9486536bc291` | ✅ 同 |

**装置**（全在 `$HOME`，仓外）：

| 件 | 作用 |
|---|---|
| `$HOME/w47a/run.sh` | 私有 display + 私有目录 + 存活检查 + 分相位点击矩阵（`bash run.sh`，相位走 `W47A_PHASE`） |
| `$HOME/w47a/geo.py` | 解析应用自报的 `[GEO]` 块 → 给出**真实屏幕坐标**（控件中心 / 项容器中心 / 视口裁剪） |
| `$HOME/w47a-run/{geo,chain,assm,Q1b,Q2d,Q3,Q4,Q5,Q6,Q6b,Q7,Q8,scroll,navall,survey}/` | 逐相位的 `app.log`（原始读数所在） |
| `$HOME/w47a-backup/App.xaml.cs.before` | hc 侧仪器的落盘前全份备份（纪律 65） |

**为什么不用截图量坐标**：窗口是 `800x600` 而屏幕 `1400x1050`（`WindowStartupLocation=CenterScreen` 之后又被缩到 800×600），上一趟那套「按预览缩放图量像素」的坐标系统性偏差 ~30 px/项。本趟改成**应用自报 `PointToScreen`**：`[GEO] ListBox#ListBoxDemo scr=328,391 wh=203x389 n=31 sel=-1` ＋ `[GEO] item[i] ListBoxItem scr=328,391+31i wh=203x27 nm=<项名>`，探针按这些值点击 ⇒ 每一击都落在**应用自己认为**的位置上。

---

## 2. 五类点击逐条读数（原文行 ＋ 件 sha）

以下每条都是 `app.log` 原文（`app.log` 见 §1 的目录；四件 sha 见上表，逐趟一致）。窗口恒为 `id=2097156 X=300 Y=225 W=800 H=600`。

### 2.1 页面内 ListBox 项（导航 idx 19）——**有反应** ✅

先证明换页成功：`navname(ListBox)` 滚轮 2 格后点该项容器中心 `(429,743)`，随后

```
[STATE] t.. focus=ListBoxItem TG(off) LB(- sel=-1/20) LB(- sel=-1/20) TB(- len=0,caret=0,focus=False) TG(off) LB(ListBoxDemo sel=19/31)
[GEO] ListBox#- scr=602,341 wh=199x407 en=True vis=True htv=True n=20 sel=-1
[GEO] ListBox#- scr=843,341 wh=199x407 en=True vis=True htv=True n=20 sel=-1
```
（`LB(ListBoxDemo sel=19/31)` = 导航选中 19；页面换成 `ListBoxDemo.xaml` 的两个 20 项 ListBox）

逐项点击（项坐标取自 `[GEO]`，`mode=按下→停150 ms→抬起`）：

```
── [pageLB#1] 点 ListBox#- 的项 #1 @(701 388) mode=hold150
   after : focus=ListBoxItem ... LB(- sel=1/20) LB(- sel=-1/20) ...
   | EV LB.SelectionChanged ListBox# sel=1/20 added=1
── [pageLB#2] @(701 419) → after: LB(- sel=2/20) | EV LB.SelectionChanged sel=2/20
── [pageLB#3] @(701 450) → after: LB(- sel=3/20) | EV LB.SelectionChanged sel=3/20
── [pageLB#5] @(701 512) → after: LB(- sel=5/20) | EV LB.SelectionChanged sel=5/20
── [pageLB#7-fast] @(701 574) mode=fast（`xdotool click` 压抬背靠背）
   after : LB(- sel=7/20) | EV LB.SelectionChanged sel=7/20
```
⇒ **`sel` 逐项跟随点击（-1→1→2→3→5→7），fast 档同样生效**；`[KEY_DIAG] BTN type=Press state=0x0` / `type=Release state=0x100` 成对在场。

### 2.2 组合框下拉弹窗里的项（导航 idx 10）——**有反应** ✅

开下拉（点 `ComboBox#-` 中心 `(817,353)`）：

```
   after : focus=ComboBoxItem ... CB(- open=True sel=0/9 txt=正文1) ...
[POP] |[0] HwndSource root=MainWindow wh=768x576 vis=True ... |[1] HwndSource root=PopupRoot wh=396x263 vis=True hwnd=0x200008
[GEO] ComboBox#- scr=627,340 wh=380x27 n=9 sel=0 open=True txt=正文1
[GEO]   item[0] ComboBoxItem scr=629,372 ... nm=正文1
[GEO]   item[1] ComboBoxItem scr=629,401 ... nm=正文正文2
[GEO]   item[2] ComboBoxItem scr=629,430 ... nm=正文正文正文3
```
点弹窗第 3 项（`item[2]` 中心 `(817,443)`）：

```
── [popupItem#2] 点 ComboBox# 的项 #2 @(817 443) mode=hold150
   after : focus=ComboBox ... CB(- open=False sel=2/9 txt=正文正文正文3) ...
   | [KEY_DIAG] BTN type=Press btn=1 win=0x200008 state=0x0 time=86375548 ... xy=198,74
   | EV CB.SelectionChanged sel=2/9 open=True added=1 src=ComboBox(...) < StackPanel < UniformSpacingPanel < ... < NativeComboBoxDemo ...
   | EV DropDownClosed open=False cap=none
   | EV Popup.Closed open=False cap=none
   点后 4 s: ... CB(- open=False sel=2/9 ...)   ← 连续 5 次 1 Hz 采样全部稳定在 sel=2
```
⇒ **`SelectedIndex` 0→2、下拉关闭、弹窗源关闭**；点击落在**弹窗自己的 X 窗口**（`win=0x200008`）上。

### 2.3 导航区搜索框（`hc:SearchBar`）——**有反应** ✅

```
── [searchbox] 点控件 SearchBar# 中心 @(416 371) mode=hold150
   ctl   : [GEO] SearchBar#- scr=328,358 wh=176x27 en=True vis=True htv=True len=0 caret=0
   before: focus=null ... TB(- len=0,caret=0,focus=False) ...
   after : focus=SearchBar ... TB(- len=0,caret=0,focus=True) ...
   after type: focus=SearchBar ... TB(- len=3,caret=3,focus=True) ...   ← `xdotool type abc`
```
⇒ 点一下 ⇒ 内部 `TextBox` 拿到键盘焦点（`focus=True`）；打字 ⇒ `len 0→3, caret=3`。

### 2.4 DataGrid 行（导航 idx 17）——**有反应** ✅

```
after-nav: focus=ListBoxItem DG(sel=-1/20) ... LB(ListBoxDemo sel=17/31)
[GEO] DataGrid#- scr=576,345 wh=478x426 n=20 sel=-1
[GEO]   item[1] DataGridRow scr=583,437 wh=504x44 vis=True
── [DGitem#1] @(835 459) → after: focus=DataGridCell DG(sel=1/20) | EV DG.SelectionChanged sel=1 n=20
── [DGitem#2] @(835 509) → after: focus=DataGridCell DG(sel=2/20) | EV DG.SelectionChanged sel=2 n=20
```

### 2.5 TreeView 节点（导航 idx 18）——**有反应** ✅

```
✓ 已到 idx=18（state 含 LB(ListBoxDemo sel=18/31)）
[GEO] TreeView#- scr=602,341 wh=199x407 en=True vis=True htv=True
[GEO]   item[0] TreeViewItem scr=605,344 wh=193x27 vis=True
── [TVitem#0] @(701 357) → after: focus=TreeViewItem TV(sel=obj) | EV TV.SelectedItemChanged now=DemoDataModel
── [TVitem#1] @(701 388) → after: focus=TreeViewItem TV(sel=obj) | EV TV.SelectedItemChanged now=DemoDataModel
```

### 2.6 追加：ButtonBase 一族（用户说「点击没反应」的最强候选）——**有反应** ✅

```
── [sortToggle] 点控件 ToggleButton#ButtonStyleAscending 中心 @(524 371)
   before: ... TG(off) ...
   after : focus=ToggleButton#ButtonStyleAscending ... TG(on) ...
   | EV Click ToggleButton#ButtonStyleAscending cap=ToggleButton#ButtonStyleAscending
   导航前 3 项(排序前): item[0] nm=Brush  item[1] nm=Button  item[2] nm=RepeatButton
   导航前 3 项(排序后): item[0] nm=Border item[1] nm=Brush   item[2] nm=Button   ← 业务真的生效
── [ButtonMax] 点控件 Button#ButtonMax 中心 @(1026 240)
   | EV Click Button#ButtonMax cap=Button#ButtonMax
   | EV Executed cmd=RoutedCommand sender=Button src=Button handled=False cap=Button#ButtonMax ...
```
⇒ **`Click` 路由事件、`IsChecked` 翻转、命令执行、业务重排全部发生**。
⚠️ 只有一处**未生效**：点最大化后 `xdotool getwindowgeometry` 逐字未变（`WIDTH=800 HEIGHT=600` 点前点后相同）⇒ 最大化的**窗口动作**可疑（**`NOINFO`**：我没有把「窗口管理器缺席」与「移植缺陷」分开，未下结论）。

---

## 3. 缺陷 A（严重，已定位到代码）：BAML 页面 `NameScope` 没挂上 ⇒ 点击导航项 ⇒ 进程 abort

### 3.1 现象与复现（两次独立复现）

**复现命令**（读数在 `$HOME/w47a-run/Q6b/app.log`）：
```
W47A_PHASE=Q6 W47A_DISPLAY=:60 W47A_OUT=$HOME/w47a-run/Q6b bash $HOME/w47a/run.sh
# 相位内：取屏幕 x 最大的 TabItem（=「工具」页签）→ 点它 → 再点该页第 2 项 MorphingAnimation
```
**读数**：
```
── [tools#1-MorphingAnimation] 点 ListBox#ListBoxDemo 的项 #1 @(429 435) mode=hold150
   before: focus=SearchBar ... LB(ListBoxDemo sel=0/3)
   !!! APP DIED
   !! Unhandled exception. System.InvalidOperationException: 'PathDemo' name cannot be found in the name scope of 'HandyControlDemo.UserControl.GeometryAnimationDemo'.
   !!    at System.Windows.Media.Animation.Storyboard.ResolveTargetName(String, INameScope, DependencyObject)  …/PresentationFramework/…/Storyboard.cs:line 276
   !!    at System.Windows.Media.Animation.Storyboard.ClockTreeWalkRecursive(...)                                …/Storyboard.cs:line 430 / 510
   !!    at System.Windows.Media.Animation.Storyboard.BeginCommon(...)                                          …/Storyboard.cs:line 1258
   !!    at System.Windows.Media.Animation.BeginStoryboard.Begin(...)                                           …/BeginStoryboard.cs:line 209
   !!    at System.Windows.Media.Animation.BeginStoryboard.Invoke(FrameworkElement fe)                          …/BeginStoryboard.cs:line 197
   !!    at System.Windows.EventTrigger.EventTriggerSourceListener.Handler(...)                                 …/EventTrigger.cs:line 383
   !!    at System.Windows.FrameworkElement.OnLoaded(...)                    build/PresentationFramework.Linux/FrameworkElement.Linux.cs:5989
   !!    at System.Windows.BroadcastEventHelper.BroadcastLoadedSynchronously(...)
   !!    at System.Windows.Media.MediaContext.FireLoadedPendingCallbacks(...)
   !! last HCIN: EV LB.SelectionChanged ListBox#ListBoxDemo sel=1/3 added=1
   alive=no      （`timeout` 报「被监视的命令已核心转储」）
```
第一次是**无意撞到**（`survey` 相位竖扫时点到页签行，切到「工具」页后点第一项），同样 abort、同样栈。

**页面侧原文**（应用自己的 XAML，未改）：`/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/UserControl/Tools/GeometryAnimationDemo.xaml`
```
: 8  <Storyboard x:Key="StoryboardOnLoaded" RepeatBehavior="Forever" AutoReverse="True">
: 9      <hc:GeometryAnimationUsingKeyFrames Storyboard.TargetProperty="Data" Storyboard.TargetName="PathDemo">
:17      <ColorAnimationUsingKeyFrames ... Storyboard.TargetName="PathDemo">
:28  <UserControl.Triggers>
:29      <EventTrigger RoutedEvent="FrameworkElement.Loaded">
:30          <BeginStoryboard Name="BeginStoryboard" Storyboard="{StaticResource StoryboardOnLoaded}"/>
:37      <Path Name="PathDemo" Width="100" Height="100" .../>
```
**名字确实进了 BAML/生成件**（⇒ 不是编译期丢名）：`/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/obj/Debug/net10.0/GeometryAnimationDemo.g.cs`
```
: 64  internal System.Windows.Shapes.Path PathDemo;
:103  this.PathDemo = ((System.Windows.Shapes.Path)(target));
```
⇒ **名字在，运行时却查不到** —— 问题在「名字域」。

### 3.2 判定点（`文件:行` ＋ 原文）

**判定点 ①（生成件，属性挂错了类）** `build/WindowsBase.Linux/DependencyObject.Linux.cs`：
```
: 51      [System.ComponentModel.TypeDescriptionProvider(typeof(MS.Internal.ComponentModel.DependencyObjectProvider))]
: 52      [System.Windows.Markup.NameScopeProperty("NameScope", typeof(System.Windows.NameScope))]
: 53  // =====================================================================================
: 54  //  T1c 第 5 批（W1…W4）：**读路径为什么不解析 deferred**（`DependencyObject`）
          …（插桩横幅＋说明，共 11 行）…
: 64  internal static class WpfLinuxDpValueTrace
: 65  {
          …（插桩类本体 ~550 行）…
:614      public class DependencyObject : DispatcherObject
```
上游原文（对照）`upstream/…/WindowsBase/System/Windows/DependencyObject.cs`：
```
: 39      [System.ComponentModel.TypeDescriptionProvider(typeof(MS.Internal.ComponentModel.DependencyObjectProvider))]
: 40      [System.Windows.Markup.NameScopeProperty("NameScope", typeof(System.Windows.NameScope))]
: 41      public class DependencyObject : DispatcherObject
```
⇒ 上游是「**属性块紧贴类声明**」；我方插桩把 `TRACE_CLASS` 插在 **:41 那行的前面**，于是 51-52 两条属性归属变成了 `WpfLinuxDpValueTrace`，`DependencyObject` 自己的属性数掉到 **0**。

**判定点 ②（生成规则）** `src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py`：
```
:628  WB_CLASS_ANCHOR = '    public class DependencyObject : DispatcherObject\n'
:832  EDITS = [
:832      ("W0 插桩类本体", WB_CLASS_ANCHOR, TRACE_CLASS + WB_CLASS_ANCHOR),
```
⇒ 「把插桩类文本**拼在锚行前面**」这条规则，锚行恰好是属性块与类声明之间的那一行。

### 3.3 因果链（逐环，每环都有我方实测读数）

| # | 环节 | 读数 / 原文 |
|---|---|---|
| 1 | 类属性没挂到 `DependencyObject` 上 | `[NS] ATTRCOUNT DependencyObject=0 FrameworkElement=1 Control=0 TextBlock=2` |
| 2 | 被加载的确实是我方 `WindowsBase.dll` | `[NS] ASSM depObjAssm=WindowsBase, Version=4.0.0.1 … loc=/home/links-dev/w47a-app/WindowsBase.dll` |
| 3 | 属性**一条都没有**（不是"类型身份不符"） | 同一行：`attrCount=0 nameScopeHits=none nonInherit=False`（`nameScopeHits=none` = 扫遍该类型的全部属性都没有 `NameScope*`） |
| 4 | 名字域那条链的其余环节**都是好的** | `[NS] CHAIN attrOnDependencyObject=False attrOnRootType=False dpField=True dpNull=False dpOwner=NameScope dpName=NameScope attachableMember=NameScope` |
| 5 | `LookupNameScopeProperty` 因此返回 `null` | 上游 `System.Xaml/System/Xaml/Schema/TypeReflector.cs:406-432`（`GetCustomAttribute(typeof(NameScopePropertyAttribute), xamlType.UnderlyingType)`） |
| 6 | 根名字域**没被设到根对象上** | `System.Xaml/System/Xaml/Context/ObjectWriterContext.cs:900-940`：`nameScopeProperty is null` ⇒ 走「Otherwise we still need a namescope at the root … for `IXamlNameResolver()`」那条**本地兜底**（不挂到根） |
| 7 | 于是每个 BAML 页面/窗口都查不到名字 | `[NS] WINDOW HandyControlDemo.MainWindow scope=null FindName(ControlMain)=null`；`[NS] loaded …PracticalDemo scope=null isINS=False contentScope=null upHits=none FindName(PathDemo)=null`；同样实测于 `ButtonDemo` / `HatchBrushGeneratorDemo` / `GeometryAnimationDemo`（`upHits=none` = 视觉树向上 6 层**没有任何对象**挂着名字域） |
| 8 | `Storyboard.TargetName` 解析失败并**抛出** | 上游 `…/Animation/Storyboard.cs:276`（`SR.Storyboard_NameNotFound` = `'{0}' name cannot be found in the name scope of '{1}'.`） |
| 9 | `Loaded` 广播路径上无人接住 ⇒ 进程 abort | 栈：`MediaContext.FireLoadedPendingCallbacks` → `BroadcastLoadedSynchronously` → `FrameworkElement.OnLoaded`（`FrameworkElement.Linux.cs:5989`）→ `EventTrigger` → `BeginStoryboard.Invoke` ⇒ `Unhandled exception` |

**射程（静态，已核）**：hc 树里 `Storyboard.TargetName` 共 **24** 个 XAML；带 `RoutedEvent="Loaded"` 触发器的有 `UserControl/Tools/GeometryAnimationDemo.xaml`、`UserControl/Tools/EffectsDemo.xaml`、`Shared/HandyControl_Shared/Themes/Theme.xaml`、`Themes/Styles/Base/ProgressBarBaseStyle.xaml`、`Themes/Styles/Base/BadgeBaseStyle.xaml`（**后三者的实际后果未测 = `NOINFO`**）。名字域缺失还应当影响 `ElementName` 跨名字域绑定 —— **未测 = `NOINFO`**。

### 3.4 为什么既有仪器一条都没抓住

- 应用器审计只判「needle 在不在、命中数对不对」（`check-appliers.sh` / `applier-audit.py`）⇒ **纯插入、命中 1 次 ⇒ 全绿**；没有任何判据问「插到了哪一行、有没有把属性块与类声明分开」。
- 九位/指纹判据量的都是「源→产物」的一致性，不量**语义**。
- 全仓 `known-red.json` 里 `NameScopeProperty` / `NameScope` / `Storyboard` / `DpValueTrace` / `MirrorTrace` 命中数**全为 0**；`docs/CURRENT-STATE.md` 里 `NameScope|namescope|属性块` 命中数 **0** ⇒ **这条红没有任何登记**。
- 仓内既有的 hc 巡检（`hc-tour.sh` 一类）只点「样式」页的前 13 项，**从不进「工具」页**，所以这条一直没被撞到。

### 3.5 建议修法（**不属我写域**，只给判定点与建议）

两条路，任选其一，**都必须重跑生成器**（`--prove` 证明是纯插入）＋ 走波：

1. **改锚（最小）**：在 `patch-windowsbase-dpvalue-trace.py` 里把 `W0` 的锚从「类声明行」上移到**属性块之前**（例如锚 `namespace System.Windows\n{\n` 之后的第一行，或该类 `/// <summary>` 文档注释首行），使 `TRACE_CLASS` 插在**属性块之外**；`patch-presentationframework-mirror-trace.py:283` 的 `FE_CLASS_ANCHOR`（`:252`）同改。
2. **改插入方向（更稳）**：把插桩类改成**追加到文件末尾**（命名空间内、最后一个 `}` 之前）或**提到 `namespace` 之前**，从此与类声明/属性块的相对位置无关。

**加一条判据（防复发，只许加强）**：`attrCount(DependencyObject) ≥ 2 ∧ attrCount(FrameworkElement) ≥ 3`（值取上游原文的属性条数），或更一般的「**任何 `[` 开头的属性行与其后的 `class` 声明之间不得出现插入横幅**」——两者都能零 `dotnet` 或一次反射跑完，且能被本报告 §3.2 的原文精确复算。

**代价**：`WindowsBase` ＋ `PresentationFramework` 两个生成件变 ⇒ 属**九位里的 `wsh`/`pf`**（也可能带动 `pc`）⇒ 需要重建 ＋ 重取五臂 ＋ 重钉 ＋ 重冻，**必须发波**（不是车道自落）。

### 3.6 撤除条件（可反驳性）

修好之后，本条登记**当且仅当**下列读数同时成立时被撤掉：① `[NS] ATTRCOUNT DependencyObject≥2`；② `[NS] …scope=<非null>` 且 `FindName(ControlMain)≠null`；③ 点「工具」→ 该页 3 项（`HatchBrushGenerator` / `MorphingAnimation` / `Effects`）**逐项点一遍、进程存活**；④ 若届时仍 abort，则本条登记**判错**（真因另在）。

---

## 4. 缺陷 B（同族，第二例）：`FrameworkElement` 的三条属性也被插桩横幅打断

**判定点** `build/PresentationFramework.Linux/FrameworkElement.Linux.cs`：
```
:100      [StyleTypedProperty(Property = "FocusVisualStyle", StyleTargetType = typeof(Control))]
:101      [XmlLangProperty("Language")]
:102      [UsableDuringInitialization(true)]
:103  // =====================================================================================
:104  //  T1c · RTL 镜像读数：**实际推给视觉树的变换** vs `GetFlowDirectionTransform()` 的报告口径
          …（插桩横幅＋说明）…
:110  internal static class WpfLinuxMirrorTrace
:306      public partial class FrameworkElement : UIElement, IFrameworkInputElement, ISupportInitialize, IHaveResources, IQueryAmbient
```
生成规则 `src/WpfGfx.Linux.Native/tools/patch-presentationframework-mirror-trace.py`：
```
:252  FE_CLASS_ANCHOR = '    public partial class FrameworkElement : UIElement, IFrameworkInputElement, ISupportInitialize, IHaveResources, IQueryAmbient\n'
:283      ("M0 插桩类本体", FE_CLASS_ANCHOR, TRACE_CLASS + FE_CLASS_ANCHOR),
```
**读数**：`[NS] ATTRCOUNT … FrameworkElement=1 …`（上游 `FrameworkElement.cs` 的属性块在 `:90-92`，共 3 条，全部被横幅隔开）。
⚠️ **残留的那 1 条我没查出是谁**（可能是另一份 `partial` 声明带来的），**如实标 `NOINFO`**。
⚠️ 三条属性各自的**行为后果未测**（`[UsableDuringInitialization]` 关系到 XAML 初始化期语义、`[XmlLangProperty]` 关系到 `xml:lang`、`[StyleTypedProperty]` 主要是设计期/工具元数据）⇒ **不下结论**。

**全仓扫描（机器）**：`build/*.Linux/*.cs` 里「属性行后面紧跟插桩横幅」的只有 **2 个文件 5 行**（本节 3 行 ＋ §3.2 的 2 行）；`TextBlock.Linux.cs:53-54`、`TextBox.Linux.cs:40-41`、`ManagedSurface.cs:320`、`SystemResources.Linux.cs:1725` 是**正常**的属性紧贴类声明，**不在本族**。

---

## 5. 观察（机器可量，根因未定位）：页签标题与「实用示例」按钮**没有渲染文字**

同一帧截图（`$HOME/w47a-run/survey/shot-initial.png`，1400×1050）分区取「墨量」：

| 区域（屏幕坐标） | `colors` | `stddev` | 判读 |
|---|---|---|---|
| 页签行 `228x27+318+318` | **1** | **0 %** | **纯色一张、零墨** ⇒ 页签标题（样式/控件/工具）没画出来 |
| 「实用示例」按钮 `203x27+328+284` | 8 | 0.15 % | 约等于空 ⇒ 按钮文字没画出来 |
| 导航项第 1 行 `203x27+328+391` | 69 | 10.47 % | 有字（画刷） |
| 导航项 4 行 `203x120+328+391` | 195 | 12.67 % | 有字 |
| 搜索框 `176x27+328+358` | 19 | 2.71 % | 图标在 |

**命中测试仍是通的**（`[GEO] TabItem#- scr=318,318 wh=74x27 hdr=HandyControlDemo.Data.DemoInfoModel sel=True`；点最右页签真的会切到「工具」页）⇒ **看得见的东西没有、能点的东西在**。这两处的文案都走 `{ex:Lang …}` 标记扩展（`UserControl/Main/LeftMainContent.xaml:13` 的 `Content="{ex:Lang Key={x:Static langs:LangKeys.PracticalDemos}}"`，`:15-19` 的 `<TabControl.ItemTemplate>` → `:17` 的 `<TextBlock Text="{ex:Lang Key={Binding Title}}"/>`），而**导航项的 `{ex:Lang Key={Binding Name}}` 是渲染出来的** ⇒ 差异在「静态 Key / Binding Key ＋ `TextBlock.Text` / `Button.Content`」这一格。
⇒ **这是用户「点了没反应」的一个可信解释**（顶部导航看起来是空的），但**根因我没有量到底 ⇒ `NOINFO`**，建议单开一条车道。

---

## 6. 我改的 hc 侧仪器（逐处行号 ＋ before/after sha16）

- 件：`/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/App.xaml.cs`
- **sha16 `986aafa11ac4e5b0`（535 行）→ `4c7ad356dbf539a6`（840 行）**；落盘前全份备份 `$HOME/w47a-backup/App.xaml.cs.before`（`986aafa11ac4e5b0`）
- 纪律：**全部 env 门控（`HC_INPUT_DIAG=1`）、只读、有界**；默认路径零改动（不改任何既有断言语义，只**加**日志）
- 同步效应：`HandyControlDemo.dll` sha16 随仪器变化（末趟 `833630857e2fbc5d`）；**四件冻结壳（§1 表）逐趟逐字节未变**

| # | 现件行号锚 | 改动 |
|---|---|---|
| 1 | `:425` | 新增 `DumpPopups()`：遍历**全部** `PresentationSource`（弹窗是另一个 `HwndSource`，不在 `MainWindow` 的可视树里）⇒ 打 `[POP]` |
| 2 | `:458` | 新增 `DumpGeo()` / `GeoWalk()`：把每个可点控件的 `PointToScreen` 屏幕矩形、每个项容器的矩形、`en/vis/htv`、`n/sel/open/txt/len/chk/val`、`TabItem.hdr` 打成 `[GEO]` 行（每 `HC_GEO_EVERY` 秒一块，缺省 2 s） |
| 3 | `:496` | `GeoInteresting()` 增加 `TabItem`（要去「工具」页签） |
| 4 | `:554` | `[GEO]` 项容器补 `nm=`：`Content` 是字符串时用 `ToString()`（`ComboBoxItem` 的常态），限 20 字 |
| 5 | `:592` | 新增 `ButtonBase.ClickEvent` 类处理器 ⇒ `[HCIN] EV Click …`（**"激活"的最强判据**） |
| 6 | `:595` | 新增 `ListBox` / `DataGrid` / `TreeView` 的 `SelectionChanged`/`SelectedItemChanged` 类处理器 ⇒ `EV LB.SelectionChanged sel=/n=`、`EV DG.SelectionChanged`、`EV TV.SelectedItemChanged` |
| 7 | `:607` | 新增 `[NS]` 名字域探针（`UserControl.Loaded` ＋ `Window.Loaded`）：`scope=` / `isINS=` / `contentScope=` / `upHits=` / `FindName(PathDemo)` / `FindName(ControlMain)` |
| 8 | `:618` | `[NS] ATTRCOUNT`：`DependencyObject/FrameworkElement/Control/TextBlock` 的类属性条数 |
| 9 | `:628` | `[NS] ASSM` ＋ `[NS] CHAIN`：把 `LookupNameScopeProperty` 那条链逐环量出来（程序集身份、`NameScopeProperty` 字段、`GetAttachableMember("NameScope")`） |
| 10 | `:698` | `mouseDown`/`mouseUp` 补 `state=`（`ButtonState`）/`devLB=`/`bb=<ButtonBase>.IsPressed`/`handled=` |
| 11 | `:825` | `[STATE]` 的 1 Hz 预算由硬编码 90 改为 `HC_DUMP_MAX`（**原为静默停表，是上一趟"navto 19 不换页"的假读数来源**）；`[STATE]` 的 `LB/TB/CB/DG/TV` 补 `Name`/`items.Count`/`focus`；`focus=` 补元素名 |
| 12 | `:716`（ComboBox `SelectionChanged`） | 补 `sel=/n=`；`:582`（`preMouseDown`）补 `state=` |
| 13 | `:295`/`:298`（`POLL`） | 补时间戳 `t=` 与 `sel=`（**这条既存仪器本身有假信号，见 §7-④**） |

---

## 7. 我自己的仪器自伤（如实）

① **把死应用的最后一行 `[STATE]` 当活读数**：`survey` 竖扫时应用在 `y=180` 那次点击里已经 abort，我却继续读到 `y=980`（那些行全是崩溃前最后一次 dump）。⇒ 之后给探针装了 `alive()`（`kill -0` ＋ 查 `Unhandled exception`），**每次点击后先判存活**。

② **`geo.py` 把弹窗项的坐标"夹"回了控件矩形**：`ComboBox` 的项住在**另一个 X 窗口**里，我的「视口裁剪＋夹取」把「弹窗项 #2」的坐标从 `(817,443)` 夹成 `(817,363)`（= 组合框本体中心）⇒ 那一击实际点在组合框上、只把下拉**关掉**，于是我一度得出「**弹窗项点不动**」的**假读数**。修好后同一相位给出 `sel 0→2` 的真读数（§2.2）。

③ **`[GEO]` 项容器上限 16** ⇒ 导航第 19 项 `ListBox` 从来不进读数 ⇒ `navname(ListBox)`「滚 8 轮不可见」的假 `NAVFAIL`。改上限 40 ＋ 用滚轮把项滚进视口后正常。

④ **既存 `[POLL]` 仪器本身是假信号（不是我这趟加的，但我差点把它当成真缺陷报出去）**：备份件 `App.xaml.cs.before:230` 的 `_hcinLastOpen` 是**一个静态字段被整棵树的所有 `ComboBox` 共用**（`:284-287`），于是 30+ 个组合框互相把对方的 `open` 值当"上一次"⇒ 8 ms 采样定时器每拍都打印"变了"：
```
[HCIN] POLL open -> True  sel=0 t=22:49:19.134 cap=ComboBox
[HCIN] POLL open -> False sel=0 t=22:49:19.135 cap=ComboBox
开下拉后 5 s: POLL open 转变=1294        ← 看着像"下拉在疯狂闪烁"
```
算术互证：8 ms/拍 ⇒ 5 s ≈ 625 拍；树里约 36 个组合框 ⇒ 每拍约 2 行 ⇒ **≈1250 行 ≈ 实测 1294**。⇒ **那是仪器在被测对象之间"串味"，不是产品在闪**。本趟改用「弹窗 X 窗口是否存活 ＋ `SelectionChanged` 事件 ＋ 5 次 1 Hz 采样」三路互相印证。

⑤ **相位顺序自伤**：`scroll` 相位先用滚轮把导航列表滚下去 18 项，紧接着的"键盘腿"又去点 `item[0]`（此时它在 `y=-164`，**早已滚出视口**）⇒ `focus=null`、`sel=-1`，那一格的读数**无效**（`geo.py` 后来加的视口裁剪就是为了防这个）。

⑥ **`local` 用在函数外**（`scroll` 相位第一版）⇒ bash 报错；**`r=$(navto …)` 用命令替换吞掉整段输出**（`navall` 相位第一版）⇒ 那趟只剩一行 `alive=yes`。两处都是当场发现当场改。

⑦ **两次「点了没事件进来」我无法归因**：`Q4` 点导航项 `TreeView`（`(429,712)`）与 `Q7` 点导航项 `CheckBox`（`(429,528)`）之后，`app.log` 里**一条 `[HCIN] preMouseDown` 都没有**（不是"选中没变"，是**事件完全没到**）。而专门的投递探针 `Q8`（点搜索框数 `preMouseDown`）在 `Max`/`Min`/切页/排序/PracticalDemos 之后**每次都是 33 条**、逐次不变 ⇒ 说明「投递整体没坏」。**我区分不了「我的坐标过期（列表自动滚动/GEO 块最多 2 s 旧）」与「产品偶发不投递」⇒ 记 `NOINFO`**，并给出复算路径（`Q4/app.log`、`Q7/app.log` 对比 `Q8/app.log`）。

---

## 8. `NOINFO` / 未做到的 / 被推翻的假设

**`NOINFO`（没量到，不许当绿也不许当红）**
1. §5 的「页签标题/按钮文字不渲染」根因（只量到"没墨"，没定位到 `{ex:Lang}` / `TemplateBinding` / 字体哪一环）。
2. 缺陷 B 里 `FrameworkElement` **残留的那 1 条属性是谁**；三条属性的行为后果。
3. 名字域缺失对 `ElementName` 绑定、模板内 `Storyboard`、`HandyControl` 主题里 3 处 `Loaded` 触发器的实际影响。
4. 点最大化后窗口几何**逐字未变**（分不清"窗口管理器缺席"与"移植缺陷"）。
5. §7-⑦ 的两次"事件没进来"。
6. 「工具」页第 3 项 `Effects`（`EffectsDemo.xaml` 同样带 `Loaded`＋`TargetName`）**没点**（进程会在第 2 项就死，我未做"跳过崩溃项继续点"的装置）。

**我推翻/更正了什么**
1. **推翻「点击只给焦点、从不激活」这条上一趟的定性**（至少在冻结 `#46` 上）：`ListBoxItem`/`ComboBoxItem`/`DataGridRow`/`TreeViewItem`/`ToggleButton` 的 `sel`/`chk`/`Click` 全都真的变了（§2）。
2. **推翻「`xstate_to_mk` 无条件置位 MK 位会让 `ButtonState` 恒为 Pressed」这条推断**：`HwndMouseInputProvider` 的 `ButtonState` 来自**消息身份**（`WM_LBUTTONDOWN→RawMouseActions.Button1Press`、`WM_LBUTTONUP→Button1Release`，上游 `HwndMouseInputProvider.cs:483-520`），**不读 `wParam` 的 MK 位**；本趟实测抬起那刻 `state=Released devLB=Released`（含 `fast` 档压抬同 ms 的情形）⇒ 该假设与本现象无关。
3. **`[POLL] open` 的"闪烁"是仪器串味**（§7-④），不是产品行为。
4. **上一趟「导航列表滚不到第 19 项」是仪器预算假象**：`[STATE]` 1 Hz 在 90 次后**静默停表** ⇒ 不是"点不动"（§6-11）。
5. 上一趟那套「按截图/预览缩放量像素」的坐标在此窗口下**系统性偏移**（窗口 800×600 而非 1280×~1000）⇒ 本趟改为应用自报坐标。

---

## 9. 并发披露（⚠️ 必须与我的读数分开读）

我作业期间（22:34→00:1x）**仓内不是我一个人在动**：

- `build/UIAutomationTypes.Linux/**`（`bin/`/`obj/`/`SR.g.cs`/`*.csproj`/`PORT-CHANGES.md` 一批新写）⇒ **有别的车道正在跑构建**；
- `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/{libwpfwic.so,bridge-src-fp.txt}`、`build/MilBridge/tests/{CompositeFontProbe,ContractProbe}/bin/Release/libwpfwin32.so` ⇒ 发布/同步腿在动；
- `build/MilBridge/tools/defect-registry-declared.tsv`、`build/MilBridge/W46K-report.md`、`build/MilBridge/W47B-report.md`、`build/MilBridge/arm-logs/**`；
- 收工时另有一条车道 **W48B** 正在跑应用（`PID 1803100/1803103`，`DISPLAY=:35`，`cwd=$HOME/w48b-app-new`）—— **不是我**（我的 display 是 `:46`…`:65`，且收工时 `ls /tmp/.X11-unix/` 里**没有**我的任何一个，全部按 PID 收干净）。

**这些改动全部不是我**：我的写域只有**本报告** ＋ hc 侧 `App.xaml.cs`（仓外 `/home/links-dev/hc-linux/...`）。我的 20 趟跑读数**每趟都现场算四件 sha 且逐趟相同**（§1 表）⇒ 我的读数可归属；但**此刻**仓内九位可能已被别人的波改过，**引用我的四件 sha 前必须当趟现算**。

---

## 10. 收工读数（逐字机读）

```
W47A=OK 报告=build/MilBridge/W47A-report.md
APPSHA libwpfwin32=e700c383ec1ecdc8 wpfgfx_cor3=e3ea092010734f44 pc=043eff4b1d8ecd7d pf=366e9486536bc291   （20 趟逐趟相同）
CLICKS pageLB=RESPOND(sel -1→1→2→3→5→7) popupItem=RESPOND(sel 0→2) searchbox=RESPOND(focus=True,len 0→3)
       datagrid=RESPOND(sel 1,2) treeview=RESPOND(sel=obj, SelectedItemChanged) togglebutton=RESPOND(chk off→on, 业务重排) buttonmax=Click 有/窗口动作 NOINFO
RADAR  user-report="点击没反应" ⇒ 冻结 #46 上 NOT-REPRODUCED（五类全激活）
DEFECT-A=CONFIRMED 判定点 build/WindowsBase.Linux/DependencyObject.Linux.cs:51-52(属性)→:64(插桩类)→:614(类) / 规则 src/WpfGfx.Linux.Native/tools/patch-windowsbase-dpvalue-trace.py:832(锚:628)
DEFECT-B=CONFIRMED 判定点 build/PresentationFramework.Linux/FrameworkElement.Linux.cs:100-102→:110 / 规则 patch-presentationframework-mirror-trace.py:283(锚:252)
REGISTERED=no  （known-red.json 里 NameScopeProperty/NameScope/Storyboard/DpValueTrace/MirrorTrace 命中数全 0；docs/CURRENT-STATE.md 里 NameScope/属性块 命中数 0）
NOINFO=6 条（见 §8）
GIT-INREPO=1 件（本报告）；并发：UIAutomationTypes.Linux 构建 / MilBridge artifacts / defect-registry-declared.tsv / W46K·W47B-report / W48B 车道在跑（均非本车道）；受保护件 sha 未变：win32_x11.c=e3e1b3e10c88f6fe verify-all.sh=bde0bce61f2ffbac known-red.json=1fa4c4540fe1b69f close-wave.sh=411bb8e5d29bbe81
ZERO-DOTNET-BUILD-ON-REPO=yes（本趟 dotnet 只用于**仓外 hc 应用**的 Debug 构建：-m:1 + DOTNET_gcServer=0；未跑 verify-all/integration-wave/冻结）
```

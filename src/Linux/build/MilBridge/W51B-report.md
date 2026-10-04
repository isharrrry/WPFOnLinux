# 波 `#48` · 车道 `W51B` 报告 —— 冻结件（`gen=#48`）上的**交互验收重取**

> **任务**：车道 `W50A` 明确没重验 `D-G56` 的**行为面** ⇒ 本车道在**冻结件**上把它补上，并在同一棵树上复核用户报过的"点击没反应"（`D-G55`）。
> **仓库根**：`R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（全程绝对路径）；hc 应用源/产物在 `/home/links-dev/hc-linux`。
> **本报告的性质**：**读数记账**，不是判据、不替代预登记。凡"我以为"的地方一律写成 `NOINFO` 或"假说"。
> **纪律**：SDK 走 `export PATH="$HOME/.dotnet:$PATH"`；`nproc=3`；**全程零 `pkill -f`、零 `pgrep -x dotnet` 取别人 PID**；
> 私有 app 目录（`$HOME/w51b-app`／`$HOME/w51b-app-neg`）＋ 私有 display `:33`（**按 PID 收**，未碰 `:97`/`:66`/`:64`/`:37`/`:38`/`:39`/`:35`/`:36`）；
> **只写 `$HOME/w51b/**` 与本报告**（仓内足迹见 §8 的 `find -newermt` 实测）。
> 本机另有车道在跑冻后 `verify-all`（`$HOME/w51a/`，`loadavg` 期间 1.2–1.6、`MemAvailable` 2340–2450 MB）⇒ 本车道**只跑应用（轻）**，零构建、零 `verify-all`。

---

## 0 一句话

**`D-G56` 的行为面在冻结件上成立**：点「工具」页第 1 项 `MorphingAnimation` ⇒ **`alive=yes`、未处理异常 0 行、`'PathDemo' name cannot be found` 0 行**，且 `[NS] loaded …GeometryAnimationDemo scope=NameScope … FindName(PathDemo)=Path`；
**反极性成立**（只把 `windowsbase`/`pf` 换回修前两件 ⇒ 同一坐标 **`alive=no`** ＋ 逐字同一条 `InvalidOperationException`）。
**`D-G55` 四步连点全部通过**（含"指针全程不出窗口"这条口径，机器判据 `CALIB_VIOL=0`）——**但顺带抓出一条新的仪器自伤**：`HC_INPUT_DIAG=1` 且 `[GEO]` 转储开启时，点完弹窗项 **2 次/2 次 SIGSEGV**（`[GEO]` 关掉或仪器整个关掉 ⇒ 活满 20 s）⇒ **归仪器、不归产品**（§6）。

---

## 1 件 sha 表（跑前/跑后）

### 1.1 权威路径（开工 `00:52:11` 与收工 `01:02:58` 两次现场算，逐位相同）

| 件 | 权威路径 | 现场 sha16 | 期望（`#48` 冻结） | 大小 | mtime |
|---|---|---|---|---|---|
| `wpfgfx_cor3.so` | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/` | `e3ea092010734f44` | `e3ea092010734f44` ✅ | 5,019,968 | 2026-09-19 20:33:12 |
| `PresentationCore.dll` | `build/PresentationCore.Linux/bin/Release/` | `9465f9dce39e2dfc` | `9465f9dce39e2dfc` ✅ | 3,601,408 | 2026-09-20 00:12:56 |
| `PresentationFramework.dll` | `build/PresentationFramework.Linux/bin/Release/` | `1011da6390c3bf1e` | `1011da6390c3bf1e` ✅ | 6,119,424 | 2026-09-20 00:13:43 |
| **`WindowsBase.dll`**（本波改的位） | `build/WindowsBase.Linux/bin/Release/` | `79740e9ba7fbf9ca` | `79740e9ba7fbf9ca` ✅ | 1,111,552 | 2026-09-20 00:12:23 |
| `libwpfwin32.so` | `src/WpfGfx.Linux.Native/bin/` | `abf6879c027c5e73` | `abf6879c027c5e73` ✅ | 299,040 | 2026-09-19 22:48:30 |
| `libwpfwic.so` | `build/DirectWrite.Linux/wic-shim/` | `56278c14b4ecd672` | `56278c14b4ecd672` ✅ | 70,728 | 2026-09-19 12:16:15 |
| `DirectWrite.Linux.Provider.dll` | `build/DirectWrite.Linux/Provider/bin/Release/` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` ✅ | 103,936 | 2026-09-19 11:14:09 |
| `DirectWriteForwarder.dll` | `build/DirectWriteForwarder.Linux/bin/Release/` | `de2d555105b7d04b` | `de2d555105b7d04b` ✅ | 39,936 | 2026-09-19 11:14:13 |

⇒ **八件全部命中冻结值**；本车道**没跑任何构建**，权威件 mtime 全程未动。

### 1.2 私有 app 目录（`cp -a` 最新 hc 产物 + 权威件覆盖；**每趟跑前/跑后各记一次**）

装配脚本 `$HOME/w51b/prep-app.sh`（`08cf1870e490d76b`）；`FROZEN` 变体 `$HOME/w51b-app` 的 `ARTS before` 与 `ARTS after` **逐位相同**（去掉标签后 5 趟 md5 全等 `be8f7cad56`；`PREG56` 变体 = `8f64095957`）：

```
libwpfwin32.so=abf6879c027c5e73 wpfgfx_cor3.so=e3ea092010734f44 PresentationCore.dll=9465f9dce39e2dfc
PresentationFramework.dll=1011da6390c3bf1e WindowsBase.dll=79740e9ba7fbf9ca System.Xaml.dll=53a526ba16578bf6
ReachFramework.dll=be2d69ba02c76ef9 DirectWriteForwarder.dll=de2d555105b7d04b
DirectWrite.Linux.Provider.dll=1f9511a7ef395bfe libwpfwic.so=56278c14b4ecd672
HandyControlDemo.dll=c093294297e9b804 HandyControl.dll=978444ca5fc9337c
```

**app 源码侧取哪一份（诚实交代）**：基座 = `/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`
（`HandyControlDemo.dll` mtime **23:53** > `App.xaml.cs` 的仪器自伤修复 mtime **23:52** ⇒ 这份是**修后**的仪器）。
⚠️ **没有**用 `$HOME/w48d-src`（`HandyControlDemo.dll 833630857e2fbc5d`，22:57）—— 那份是**修仪器之前**的，§6 说明后果。

**两处现场发现（顺手记，非本车道判据）**：
1. `build/PresentationFramework.Linux/bin/Release/DirectWriteForwarder.dll` 是**陈旧副本**（`24e819debc1e5b13`，= `#40` 那代），权威是 `de2d555105b7d04b` ⇒ 装配时**从 DWF 自己的工程目录取**，否则"探针测到旧件"（与 `#47` 的 `R-APP`／`W50A` §2 的 `APPSYNC` 同族）。
2. hc 基座里 `ReachFramework.dll` 是 `f4836ae36cbe80e1`（旧代），已按权威刷成 `be2d69ba02c76ef9`。

---

## 2 判据 A：`D-G56` 的行为面（**主判据**）

**命令（逐字）**：

```bash
export PATH="$HOME/.dotnet:$PATH"
bash /home/links-dev/w51b/prep-app.sh /home/links-dev/w51b-app FROZEN       # rc=0
timeout 400 bash /home/links-dev/w51b/10-A.sh /home/links-dev/w51b-app :33 /home/links-dev/w51b/10-A-POS POS   # rc=0
```

**装置**：私有 Xvfb（`1400x1050x24`）＋ `HC_INPUT_DIAG=1` ＋ 私有 app 目录；**坐标全部来自应用自报的 `[GEO]`**，不猜像素；
本判据按 `W48D` 的先例**允许**把指针停到窗口外（为了拍干净帧）—— 注：`D-G55` 的"指针不出窗口"那条口径在 §3，两者别混。

### 2.1 步骤与读数（原文）

```
WINDOW id=2097156 X=300 Y=225 800x600
TABRIGHT（最右页签中心）= 510 331 ；依据 = [GEO] TabItem#- scr=473,318 wh=74x27 … sel=False
AE(s0,s1)=238109   ← 页签点击的位移帧差（与 W48D 的 238109 逐位相同）
after-tab [STATE] [STATE] t17 focus=SearchBar TG(off) CB(ComboBoxDemo open=False sel=0/53 txt=Horizontal) TG(off) TB(- len=0,caret=0,focus=True) LB(ListBoxDemo sel=0/3)
after-tab ListBoxDemo 项数=3（工具页应为 3；样式页为 31）
item[1] 中心 = 429 435 ；依据 = [GEO]   item[1] ListBoxItem scr=328,422 wh=203x27 vis=True nm=MorphingAnimation
AE(s1,s2)=40315    ← 点 MorphingAnimation 的位移帧差
after click [STATE] [STATE] t22 focus=ListBoxItem TG(off) TB(- len=0,caret=0,focus=False) TG(off) LB(ListBoxDemo sel=1/3)
```

**A 的判定三行（原样）**：

```
A_VERDICT stage=POS alive=yes unhandled=0 pathdemo_notfound=0
A_RESULT=PASS stage=POS
[NS] loaded HandyControlDemo.UserControl.GeometryAnimationDemo scope=NameScope isINS=False contentScope=null upHits= UP0=GeometryAnimationDemo FindName(PathDemo)=Path FindName(PART_EditableTextBox)=null
```

**命中链原文**（`10-A-POS/app.log:674` 起；同一击的 `731` 行是选择事件、`733–760` 是 mouseUp 跳）：
```
:674 [HCIN] preMouseDown src=Border#Bd(bg=#FFEEEEEE) < ListBoxItem(bg=#FFEEEEEE) < VirtualizingStackPanel(bg=-) < ItemsPresenter(bg=-) < ScrollContentPresenter#PART_ScrollContentPresenter(bg=-) < Grid#Grid(bg=-) < ScrollViewer(bg=-) < ContentPresenter#ContentPresenterChecked(bg=-) < SimplePanel(bg=-) < Border(bg=-) < ToggleBlock(bg=-) < Border#Bd(bg=#00FFFFFF) <  btn=Left state=Pressed cap=none
:675 [HCIN] mouseDown src=Border#Bd(bg=#FFEEEEEE) < ListBoxItem … btn=Left state=Pressed cap=none srcIsCombo=False
:731 [HCIN] EV LB.SelectionChanged ListBox#ListBoxDemo sel=1/3 added=1
:745 [HCIN] mouseUp hop=ListBox src=Border open=- btn=Left state=Released devLB=Released bb=- handled=False cap=none
```
⇒ 点击**确实落在这条导航项的 ListBoxItem 上**、选择真的变了（`sel=1/3`）、页面真的换到 `GeometryAnimationDemo`（`[NS] loaded` 行 ＋ `AE`），随后**进程活着**。

**"alive=yes 不告诉你点到哪儿"这条 W48D 自伤**在本趟用**三个独立读数**堵住：① 工具页导航项数 = **3**（样式页为 31）；② `AE(s0,s1)=238109` 与该波读数**逐位相同**；③ `[NS] loaded …GeometryAnimationDemo`。

### 2.2 附（**非 A 判据**，仅记账）：第 3 项 `Effects` 仍死 ⇒ `D-G58` 在冻结件上**仍然红**
```
── 再点第 3 项 item[2]=Effects（在册 D-G58，预期仍死）──
after Effects alive=no unhandled=1
!! Unhandled exception. System.NotImplementedException: The method or operation is not implemented.
!!    at System.Windows.Media.MediaContext.CommitChannel()
!!    at System.Windows.Media.MediaContext.Render(ICompositionTarget resizedCompositionTarget)
   [NS] loaded HandyControlDemo.UserControl.EffectsDemo scope=NameScope … FindName(PathDemo)=null
```
⇒ 与 `D-G56` **不是同一条**（异常类型/栈不同），且**不是** `D-G56` 复发；`W48D` 的 `R-W48D-1`（撤登记判据③"3 项逐项点"只能完成 2/3）**在冻结件上依旧成立**。

---

## 3 判据 B：`D-G55` 四步连点（**指针全程不出应用**）

**命令（逐字）**：

```bash
timeout 420 bash /home/links-dev/w51b/20-B.sh /home/links-dev/w51b-app :33 /home/links-dev/w51b/20-B        # rc=0（仪器开，判据本趟）
DIAGMODE=0 timeout 300 bash /home/links-dev/w51b/21-B-nodiag.sh /home/links-dev/w51b-app :33 /home/links-dev/w51b/21-B-nodiag2
DIAGMODE=1 HC_GEO_EVERY=100000 timeout 300 bash /home/links-dev/w51b/21-B-nodiag.sh /home/links-dev/w51b-app :33 /home/links-dev/w51b/22-B-geooff
```

**口径的机器判据（不是嘴上说说）**：每步点击前后现场读指针坐标并与主窗口矩形 `(300,225,800x600)` 比对 —
`PTR 导航前/①点击前/①点击后/①打字后/②点击前/②点击后/③点击前 = (…) ⇒ INSIDE`（7 行全 INSIDE）、`④` 的指针 `(817,414) ⇒ INSIDE`、
**`口径违规次数(CALIB_VIOL)=0`**。**全程无 `park()`**（本车道装置与 W47A/W48D 的关键差别：那两个装置每步把指针停到窗口外，那正好是释放捕获的动作）。

### 3.1 四步读数（原文）

**① 点页面 TextBox ＋ 键入（Styles/TextBox 页 idx=9；`DemoInfo.json` Styles 组 `[9] TextBox / NativeTextBoxDemo`）**
```
导航 item[9] 中心=429 683 ；依据 = [GEO]   item[9] ListBoxItem scr=328,670 wh=203x27 vis=True nm=TextBox
导航后 [STATE] … LB(ListBoxDemo sel=9/31)          ← 换页成功
目标控件行: [GEO] TextBox#- scr=627,340 wh=380x27 en=True vis=True htv=True len=4 caret=0     （目标中心 817 353）
①点击前 [STATE] 的 TB 取值分布:  5 TB(- len=0,…)  10 TB(- len=4,…)
①点击后 focus 字段: focus=TextBox
①点击后 [STATE] 的 TB 取值分布:  5 TB(- len=0,…)   9 TB(- len=4,…)   1 TB(- len=4,caret=0,focus=True)
── 键入腿：xdotool type --delay 120 abc ──
①打字后 [STATE] 的 TB 取值分布:  5 TB(- len=0,…)   9 TB(- len=4,…)   1 TB(- len=7,caret=3,focus=True)
① 位置键控读数（同一 scr=627,340）: [GEO] TextBox#- scr=627,340 … len=7 caret=3     ← 位置键控：就是被点那一条
① mouseUp 行末尾捕获态: cap=none
```
⇒ **焦点到手（`focus=TextBox`、`focus=True`）、文本从 `len=4` 涨到 `len=7`（`abc` 逐字进）、`caret=3`**。
（`[STATE]` 里 15 个 TextBox 同名 `-` ⇒ 单看 `TB(len)` **有歧义**；本车道用**位置键控**读数（`[GEO]` 里同一 `scr` 的那一条）把它钉死。）

**② 立刻点导航换页（Styles/ComboBox 页 idx=10）**
```
导航 item[10] 中心=429 714 ；依据 = [GEO]   item[10] ListBoxItem scr=328,701 wh=203x27 vis=True nm=ComboBox
②换页后 [STATE] [STATE] t22 focus=ListBoxItem … CB(- open=False sel=0/9 txt=正文1) CB(- open=False sel=0/9 txt=正文1) … TB(PART_EditableTextBox len=3,…) …
②换页判据: LB 选择=LB(ListBoxDemo sel=10/31)
② 换页后 mouseUp cap: cap=none
```
⇒ **换页成功**（`sel=9/31 → 10/31`；页面侧控件从 TextBox 族变成 ComboBox 族）；**TextBox 刚拿到的焦点没有把后续点击吃掉**。

**③ 点开下拉**
```
目标控件行: [GEO] ComboBox#- scr=627,340 wh=380x27 en=True vis=True htv=True n=9 sel=0 open=False txt=正文1
③点击前 X 窗口: 0x200001 0x200002 0x200003 0x200004 0x200005 0x200006 0x200007
③点击后 [STATE] … CB(- open=True sel=0/9 txt=正文1) …          ← 下拉真的开了
③点击后 X 窗口: … 0x200008
③新增 X 窗口: 0x200008
   win 0x200008:   Absolute upper-left X=619   Absolute upper-left Y=369   Width=413   Height=274   Map State=IsViewable
③ [POP] [POP] |[0] HwndSource root=MainWindow wh=768x576 vis=True … |[1] HwndSource root=PopupRoot wh=396x263 vis=True kids{} hwnd=0x200008 vis=root
[HCIN] EV DropDownOpened open=True cap=ComboBox
[HCIN] EV Popup.Opened open=True cap=ComboBox child=Decorator
```
⇒ **弹窗出现且有独立 X 窗口**（新 XID `0x200008`、几何 `619,369 413x274`、`IsViewable`、`[POP]` 里是**另一个 `HwndSource`/`PopupRoot`**）。

**④ 点弹窗第 2 项（0-based `item[1]`）**
```
弹窗项的坐标来源：ComboBox 自身（scr=627,340）的 item 行
   候选: [GEO]   item[1] ComboBoxItem scr=629,401 wh=376x27 vis=True nm=正文正文2
弹窗 item[1] 中心=817 414
④点击后指针=(817,414) 主窗口⇒INSIDE 弹窗⇒INSIDE
④点击后 [STATE] … CB(- open=False sel=1/9 txt=正文正文2) …        ← 选中项变了（sel=1/9）＋ 下拉关了（open=False）
④点击后 X 窗口: 0x200001 … 0x200007                              ← 0x200008 **消失**
[HCIN] EV CB.SelectionChanged sel=1/9 open=True added=1 src=ComboBox(bg=#FFFFFFFF) < StackPanel …
[HCIN] EV DropDownClosed open=False cap=none
[HCIN] EV Popup.Closed open=False cap=none
④ SELECTION_CHANGED=15  DROPDOWN_CLOSED=1  DROPDOWN_OPENED=1     ← 全趟只开/关过这一次 ⇒ 这几行无歧义地属于 ③/④
```
**`D-G55` 的捕获面同趟读数**（`mouseUp` 的 `cap=` 序列，去重计数）：
```
B 全程 mouseUp 行的 cap 序列:  12 cap=ListBox#ListBoxDemo   17 cap=none   12 cap=ListBox#ListBoxDemo   17 cap=none   30 cap=ComboBox
```
⇒ 每次抬起之后**都回到 `cap=none`**（按下那一瞬间才有捕获）——**这正是修前缺陷的反面**（修前 `Mouse.Captured` 恒不复位）。

**⚠️ 本趟末尾的真实现象（必须写出来，不许藏）**：`B alive=no unhandled=0` —— 第 ④ 步之后的**读数与判定全部如期**，但**进程在 ④ 之后 SIGSEGV**（§6）。因此判据 B 的结论由**三条腿**合成，而不是单靠这一趟：

| 腿 | 仪器 | 四步行为 | ④ 之后 20 s |
|---|---|---|---|
| 1 `20-B`（判据本趟，`[STATE]`/`[HCIN]` 读数来源） | `HC_INPUT_DIAG=1`＋`[GEO]` 开 | 四步全部如期（上表） | **死**（SIGSEGV，`app.log` 终行是 `[GEO] ======== end ========`） |
| 2 `21-B-nodiag2`（**产品级**） | **仪器整个关**（`HC_INPUT_DIAG=<unset>`，`app.log` 0 行） | 换页 `AE(p0,p1)=204172`、弹窗 `0x200008 619,369 413x274`、④后弹窗消失 `AE(p2,p3)=21112` | **活满 20 s，零异常** |
| 3 `22-B-geooff`（**bisect**） | 仪器开、**`[GEO]` 关**（`HC_GEO_EVERY=100000`，`[GEO]` 块数=0） | 同上（`AE` 三值逐位相同：`204172 / 28816 / 21112`） | **活满 20 s，零异常** |

⇒ **判据 B 在冻结件上成立**（四步：焦点＋键入、换页、下拉独立窗口、选择＋关闭）；**§6 的 SIGSEGV 归仪器**（腿 2/腿 3 两极化）。

---

## 4 判据 C：`D-G56` 静态形状在冻结件上的复核（启动即自报）

```
[NS] ATTRCOUNT DependencyObject=2 FrameworkElement=4 Control=0 TextBlock=2      ⇒ C① 2 ≥ 2 ✅
[NS] WINDOW HandyControlDemo.MainWindow scope=NameScope FindName(ControlMain)=ContentControl   ⇒ C② scope=NameScope ✅
[NS] CHAIN attrOnDependencyObject=True attrOnRootType=True dpField=True dpNull=False dpOwner=NameScope dpName=NameScope attachableMember=NameScope
[NS] ASSM … attrCount=2 nameScopeHits= HIT:System.Xaml nonInherit=True
```
（另两趟 `20-B`／`21-B-nodiag*` 的启动读数与上面逐字相同。）

---

## 5 反极性（`D-G56`）——**只换两件**，其余与冻结件逐位相同

**做法**：`bash prep-app.sh /home/links-dev/w51b-app-neg PREG56` ⇒ 把
`WindowsBase.dll` 换回 `84a2826c471e60ea`、`PresentationFramework.dll` 换回 `366e9486536bc291`（两件来自 `$HOME/w48b-app-old`，= `D-G56` 修前值），
**`pc` 仍是冻结的 `9465f9dce39e2dfc`**、`bridge`/`win32shim`/`wic`/`provider`/`dwf` 也都不动 ⇒ 两趟**只差两件**、可归因。
**命令**：`timeout 400 bash /home/links-dev/w51b/10-A.sh /home/links-dev/w51b-app-neg :33 /home/links-dev/w51b/10-A-NEG NEG`（rc=0，同一驱动、同一坐标）

| 读数 | FROZEN（`#48`） | PREG56（只换 `wb`+`pf`） |
|---|---|---|
| 页签点击 `AE(s0,s1)` | `238109` | `238109`（**逐位相同** ⇒ 点在同一处、同一页） |
| 工具页导航项数 | 3 | 3 |
| `item[1]` 中心 | `429 435` | `429 435` |
| **`after click alive`** | **yes** | **no** |
| **未处理异常行** | **0** | **1** |
| **`'PathDemo' name cannot be found`** | **0** | **1** |
| `[NS] ATTRCOUNT` | `DependencyObject=2 FrameworkElement=4` | **`DependencyObject=0 FrameworkElement=1`** |
| `[NS] WINDOW … scope=` | `NameScope FindName(ControlMain)=ContentControl` | **`null FindName(ControlMain)=null`** |
| `[NS] CHAIN` | `attrOnDependencyObject=True attrOnRootType=True` | **`False False`**（其余逐字相同） |
| `AE(s1,s2)` | `40315` | `480000`（整帧变 ⇒ 窗口没了） |

**异常原文（修前腿，逐字）**：
```
Unhandled exception. System.InvalidOperationException: 'PathDemo' name cannot be found in the name scope of 'HandyControlDemo.UserControl.GeometryAnimationDemo'.
   at System.Windows.Media.Animation.Storyboard.ResolveTargetName(String targetName, INameScope nameScope, DependencyObject element)
   at System.Windows.Media.Animation.Storyboard.ClockTreeWalkRecursive(…)
```
⇒ **判据能红**（`D-G56` 的修在冻结件上是**承重的**，不是"顺手通过"）；两极化在**同一驱动、同一坐标、只差两件**下成立。
（反证条件未触发：修后 `ATTRCOUNT=2`、`scope=NameScope`、`alive=yes`。）

---

## 6 仪器自伤（如实，逐条）＋ 新发现：`HC_INPUT_DIAG=1` 下的 **SIGSEGV**

### 6.1 🔴 新发现（**归仪器，不归产品**）：`[GEO]` 转储 × 弹窗销毁 ⇒ SIGSEGV

**现象**：`HC_INPUT_DIAG=1`（缺省 `HC_GEO_EVERY=2`）时，**点完弹窗项之后进程必死**，且**没有**任何 `Unhandled exception`（原生段错误）：

```
$HOME/w51b/20-B.stdout:121: w51b-lib.sh: 第 49 行： 2035855 段错误 （核心已转储） … dotnet HandyControlDemo.dll
$HOME/w51b/21-B-nodiag.stdout:28: 21-B-nodiag.sh: 第 25 行： 2036526 段错误 （核心已转储） …
```
两趟的 `app.log` 终行**都是** `[GEO] ======== end ========`（GEO 块走完、随后即死）；死前那一个 `[GEO]` 块里 ComboBox 的项容器已**脱离可视树**（仪器把 `PointToScreen` 的异常名打进了 `scr=` 字段）：
```
[GEO] ComboBox#- scr=627,340 … sel=1 open=False txt=正文正文2
[GEO]   item[0] ComboBoxItem scr=InvalidOperationException wh=376x27 vis=False nm=正文1
[GEO]   item[1] ComboBoxItem scr=InvalidOperationException wh=376x27 vis=False nm=正文正文2
```

**两极化（三条腿，机器判据）**：

| 腿 | 启动行里的 env（**逐字，由装置自己打进读数文件**） | 结果 |
|---|---|---|
| `20-B` | `HC_INPUT_DIAG=1 HC_DUMP_MAX=100000 HC_GEO_EVERY=2` | **SIGSEGV**（④后 ~2 s） |
| `21-B-nodiag`（首版，读数写错，见 6.2） | 同上（实际开了仪器） | **SIGSEGV**（④后 ~8 s） |
| `22-B-geooff` | `HC_INPUT_DIAG=1 HC_DUMP_MAX=100000 HC_GEO_EVERY=100000`（`[GEO]` 块数实测 **0**） | **活满 20 s**，四步行为不变（`AE` 三值逐位相同） |
| `21-B-nodiag2` | `<无仪器env>`（`HC_INPUT_DIAG=<unset>`，`app.log` 0 行） | **活满 20 s** |

**归属判词**：**仪器缺陷**（`DumpGeo` 那条转储路径在弹窗关闭后仍去遍历已脱离的项容器）——
① 关掉 `[GEO]` 即不复发（同一 `HC_INPUT_DIAG=1`、同坐标、同件）；② 仪器整个关掉也不复发；③ 栈顶落在 hc 侧仪器（仓外 `App.xaml.cs:479-496` 的 `DumpGeo`／`:510-575` 的 `GeoWalk`），不在产品里。
**我没有修它**（`/home/links-dev/hc-linux/...` 不在本车道写域），**具体是哪一行崩的 = `NOINFO`**（未反汇编；bisect 只把范围收到"GEO 转储路径"）。
**建议一句**：`GeoWalk` 里对 `ItemsControl` 的项容器先判 `cont is Visual v && v.IsDescendantOf(root)`（或把 `ContainerFromIndex` + `PointToScreen` 整段包 `try/catch` 并在弹窗源消失后直接跳过），纯仪器改动、零产品影响 —— **与主控刚修的那条 `Describe()`/`Run` 同族**（那次也是"仪器在**另一个对象状态**上触碰可视树"）。
**对后续车道的实际影响**：**用 `HC_INPUT_DIAG=1` 读下拉相关判据时，进程会在 ~2–8 s 后静默段错误**；若脚本不判存活，就会把"死前的读数"当绿 —— 本车道靠 `alive` 成对读才抓到。

### 6.2 主控已修的那条（`Describe()` 对 `Run` 调 `GetParent`）—— **本趟 0 命中**
```
is not a Visual 命中数：01-recon=0  10-A-POS=0  10-A-NEG=0  20-B=0  21-B-nodiag=0  21-B-nodiag2=0
```
⇒ 用**修后**的 hc 产物（`HandyControlDemo.dll c093294297e9b804`，23:53）跑，工具页/文本框/下拉全链**没有**再现"`…Run` is not a Visual"那类未处理异常。
（`10-A-NEG` 里的 1 处 `InvalidOperationException` 是 `D-G56` 修前的 `'PathDemo' name cannot be found`，不是仪器。）
注：`20-B` 日志里的 9 处 `InvalidOperationException` **不是异常**，是仪器把 `PointToScreen` 的异常**名字**打进 `[GEO]` 的 `scr=` 字段（见 6.1 引文）。

### 6.3 我自己的仪器自伤（逐条，含后果）

| # | 自伤 | 后果与处置 |
|---|---|---|
| ① | 把第一趟 `20-B` 用 `\| head -20` 接管道 ⇒ `head` 退出后 `tee` 收 SIGPIPE ⇒ **整趟半路夭折** | 该趟（`READING.txt` 只 12 行、无判词）**作废**；之后一律 `> file 2>&1` 再看文件 |
| ② | `hc_start()` 把 `HC_INPUT_DIAG=1` **硬编**在启动行里，而 `21-B-nodiag` 那趟的读数写着"不设 `HC_INPUT_DIAG`" | ⇒ 那一趟**不是**产品级第二腿，**整趟作废**（`21-B-nodiag.stdout` 的作业消息里留着真实启动行作证）；已改成 `DIAGMODE` 并把**逐字启动行打进读数文件**（`LAUNCH cmd: …`），重跑为 `21-B-nodiag2` |
| ③ | `hc_say "…（在册 \`D-G58\`…）"` 双引号里的反引号被 bash 当命令替换 | 打出 `10-A.sh: 行 88: D-G58: 未找到命令`（**不影响任何读数**）；已改成单引号 |
| ④ | `hc_ctl_at` 一开始传的是**中心点**而不是控件自身 `scr` | 位置键控读数一度为空；改成传控件 `scr` 后给出 `len=7 caret=3` 的钉死读数（§3.1） |
| ⑤ | 包装函数 `hc_since … \| grep '^\[HCIN\] \(EV \|mouseUp\)'` 在该步**静默零输出**，而 `app.log` 里那些行确实存在 | ⇒ 本报告**一律引用对 `app.log` 的原始 `grep`**，不引用包装器的输出（§3.1 ③/④ 的原文都是原始行） |
| ⑥ | 顺带一条**仪器字段**坑（不是我的代码）：`[GEO]` 的 `vis=True` 只表示元素自身 `IsVisible`，**不代表在视口内** —— 导航 ListBox 的 `item[15..30]` 也报 `vis=True`，但屏幕坐标已到 `y=856…1321`（窗口只到 `y=825`）⇒ **照着它点会点到窗口外**（正好会掩盖 `D-G55`） | 本车道的兜底是**每次点击前后现场读指针并与窗口矩形比对**（`PTR … ⇒ INSIDE`，`CALIB_VIOL=0`） |

---

## 7 `NOINFO`（不许当绿）

1. **`[GEO]` 段错误的具体行 = `NOINFO`**（bisect 只收到"`DumpGeo`/`GeoWalk` 路径"；未反汇编、未逐段二分）。
2. **`D-G57`（页签标题零墨）本趟未取读数**（本车道任务是 `D-G56`/`D-G55`）；只顺带看到页签 `hdr=` 打的是 `HandyControlDemo.Data.DemoInfoModel`（`ToString()` 没被模板化），**这与"零墨"的关系未查**。
3. **`D-G56` 撤登记判据③的"3 项逐项点"仍是 2/3**（第 3 项死于 `D-G58`）⇒ 那一格只能是 `NOINFO`。
4. **`[UsableDuringInitialization]`/`[XmlLangProperty]`/`[StyleTypedProperty]` 三条属性各自的行为后果**未逐条测（本趟只证了"`D-G56` 的行为面不再 abort"）。
5. **触摸/键盘路径未测**（本趟只用鼠标 `down→150 ms→up`；`WPF_LINUX_KEY_DIAG` 全程 =0）。
6. **`[GEO]` 关掉那条腿（`22-B-geooff`）里四步的"语义读数"不可得**（无 `[STATE]`/`[GEO]` 就没有控件级读数）⇒ 那条腿只用 `AE` ＋ X 窗口事实 ＋ 存活轮询，**不能**用它复述 ①的 `len` 增长。（① 的 `len` 增长只在腿 1 上有读数。）
7. **`D-G58` 的具体 `MilCmd` = `NOINFO`**（本趟只复现了异常与栈，未开桥诊断汇）。

---

## 8 读数表（每趟现场：`pc`/四件 sha ＋ loadavg ＋ mem ＋ 时间）

每趟应用侧 `app.log` 与读数文件的 sha16（**全部可复算**）：

| 趟 | 命令（要点） | `ENV`（现场） | `READING.txt` sha16 | `app.log` sha16 / 行数 | 判词 |
|---|---|---|---|---|---|
| `01-recon` | `00-recon.sh`（只读形状） | `00:54:59` 0.77/0.70/0.88 · 2451 MB | `68a26800c06b1e69` | `3770581781269c7a` / 426 | 装置可用（[GEO]/[STATE]/[NS] 三通道齐） |
| `10-A-POS` | `10-A.sh … POS`（**A 主判据**） | `00:55:38` 1.17/0.80/0.91 · 2393 MB | `58faabe22dfd5659` | `a8881c0ff5f24ac3` / 931 | **A=PASS** |
| `10-A-NEG` | `10-A.sh w51b-app-neg … NEG`（**反极性**） | `01:02:00` 1.17/1.23/1.09 · 2372 MB | `94cdf1ccd27f8747` | `3c649aacaa409771` / 765 | **A=RED**（`alive=no`＋`PathDemo` 异常） |
| `20-B` | `20-B.sh`（**B 判据本趟**） | `00:58:29` 1.60/1.18/1.04 · 2340 MB | `e98cc4c939161580` | `90b476f6bb35a123` / 3546 | 四步如期；④后**仪器 SIGSEGV** |
| `21-B-nodiag` | 首版（**作废**：声称无仪器、实际有） | `00:59:49` 1.45/1.25/1.08 · 2343 MB | `66dddb5e4240e8d5` | `06c73d37a81d80a5` / 4349 | **整趟作废** |
| `21-B-nodiag2` | `DIAGMODE=0 …`（**产品级第二腿**） | `01:00:51` 1.28/1.25/1.09 · 2347 MB | `9f1d06ce4c6144fa` | `e3b0c44298fc1c14` / 0 | 四步如期 ＋ **活满 20 s** |
| `22-B-geooff` | `DIAGMODE=1 HC_GEO_EVERY=100000 …`（**bisect**） | `01:03:10` 1.22/1.25/1.11 · 2377 MB | `14e1154fe927d15e` | `7f6b20938b762dfe` / 1643 | 四步如期 ＋ **活满 20 s**（`[GEO]` 块数=0） |

- `host=linksdev-VirtualBox`、`kernel=6.8.0-138-generic`、`nproc=3`、`lane=W51B`（每趟 `ENV` 行都记）。
- 每趟 app 目录的 `pc`/`pf`/`wb`/`bridge`/`win32shim` sha **跑前=跑后**（§1.2）；权威路径 8 件 **开工=收工**（§1.1）。
- **仓内足迹自检**（`find $R -newermt '2026-09-20 00:50' -type f -not -path '*/obj/*' -not -path '*/bin/*' -not -path '*/.artifacts/*'`）：
  命中的全部是**别的车道**的件（`build/MilBridge/W50A-report.md`、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`、`docs/CURRENT-STATE.md`、`tests/artifacts/rendering/*.png` ← 并发那条 `verify-all`）⇒ **本车道仓内只新增本报告一个文件**。
- 装置脚本 sha16：`w51b-lib.sh 1260bb018ff3bb13`／`geoq.py 732cd6b76e111477`／`00-recon.sh 9a610c35657ea003`／`10-A.sh d8a94f5052b76213`／`20-B.sh 6f10be6e60e84d8c`／`21-B-nodiag.sh 846d72c790a81c98`／`prep-app.sh 08cf1870e490d76b`（全在 `$HOME/w51b/`）。

---

## 9 给主控的一句话交接

1. **`#48` 的 `D-G56` 行为面已补上**：冻结件上点「工具」第 1 项 `MorphingAnimation` **活着、零异常**（`=PASS`），**反极性同坐标 `alive=no`＋同一条 `PathDemo` 异常** ⇒ 这条判据能红也能绿。
2. **`D-G55` 四步连点（指针不出窗口）在冻结件上通过**，`cap` 每次抬起后回到 `none`；本车道的 `PTR…INSIDE`／`CALIB_VIOL=0` 是这条口径的机器判据。
3. **要登记一条新的仪器缺陷（不是产品）**：`HC_INPUT_DIAG=1` ＋ `[GEO]` 开启时，点完下拉项后 **2–8 s 静默 SIGSEGV**；关 `[GEO]` 或关仪器都不复发 ⇒ 归 `DumpGeo`/`GeoWalk`（仓外 `App.xaml.cs:479-575`）。**在它修好之前，任何"下拉相关"的带仪器读数都必须成对判 `alive`**，否则会把死前读数读成绿。
4. **`D-G58`（Effects 页）在冻结件上仍然红**，`D-G56` 撤登记判据③ 的第 3 格**只能是 `NOINFO`**。
5. 顺手两条小账：`build/PresentationFramework.Linux/bin/Release/DirectWriteForwarder.dll` 是**旧副本**（`24e819debc1e5b13` vs 权威 `de2d555105b7d04b`）；`[GEO]` 的 `vis=True` **不代表在视口内**（照它点会点到窗口外，正好掩盖 `D-G55`）。

# W48B · hc 真实应用「界面里点击没反应」两极化复采

> **性质**：只读复采（仓内**只新增本文件**）＋ 仓外 `$HOME/w48b/**` 的量测件。
> **被测件**：`/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`
> 的**整份私有副本**（每趟新建，跑前跑后各记一次 sha）；X 私有 `:35`；按 PID 收尾（**未用 `pkill -f`**）。
> **被判的声称**：`D-G55`（`SetCapture/ReleaseCapture` 不派发 `WM_CAPTURECHANGED` ⇒ `Mouse.Captured` 恒不复位
> ⇒ 点过一次之后后续点击全被路由到那个控件）能否解释用户报的 hc 现象。
> **未跑** `dotnet`（无 build）、未跑 `integration-wave`/`verify-all`/冻结。

---

## 0. 结论（先行）

**是。用户报的「hc 能跑、但界面里点击没反应，包括输入框和列表项」在 hc 上被 `D-G55` 完整解释**，
且判据是**两极化的**：把 shim 从修后换回修前，同一套动作下**每一个**「点不动」症状都出现；
换回修后，**每一个**都消失（§3）。

**机制级读数是 `cap=` 与 `src=` 两列**（不是像素、不是猜）：

| 读数 | 修前 `e700c383ec1ecdc8` | 修后 `abf6879c027c5e73` |
|---|---|---|
| `preMouseDown` 顶层 `src=` | **`ListBox#ListBoxDemo` ×85** ＋ `Border#Bd` ×116（**这两组全部 `cap=ListBox#ListBoxDemo`**）＋ `Border#Bd` ×29 `cap=none` | `TextBoxView` ×108、`Border` ×29（`cap=none`）＋ `Border#Bd` ×179（`cap=none`）／ ×44（瞬时 `cap=ComboBox`） |
| `cap=` 分布（整趟） | **521 `ListBox#ListBoxDemo`** ／ 30 `none` | 448 `none` ／ 229 `ComboBox` ／ 60 `ListBox` ／ 12 `ListBox#ListBoxDemo` |
| `[STATE] focus=` 取值集合 | **只有 `ListBoxItem`(36) 与 `null`(4)** | `TextBox`(10)、`ComboBox`(2)、`ComboBoxItem`(1)、`ListBoxItem`(23)、`null`(4) |
| `TB(…focus=True)` 出现过吗 | **一次也没有** | 有（`len=4/7/10`） |
| `EV DropDownOpened` / `EV Executed` | **0 / 0** | **1 / 28** |
| 弹窗 `HwndSource` | **不存在** | `0x200008` `(619,369) 413x274` |
| 异常行 | 0 | 0 |

**为什么用户说「能跑」但又「点不动」**：修前，**第一次点导航项**（去任何页面都必经）就让导航的
`ListBox` 拿住捕获并且**永不放**；此后落在**导航以外**的点击（页面输入框、组合框、页面列表项）
全被路由到那个导航 `ListBox` ⇒ 输入框/列表项点不动，但**导航内部**的点击仍然生效
（因为命中目标本来就是被捕获的那个元素）—— 于是应用"能跑、能翻页，但界面里的控件全不理人"。
这与用户的原话逐字吻合。

---

## 1. 件（每趟跑前/跑后现场 `sha256sum`，全部一致 ⇒ 读数有效）

| 件 | sha16 | 字节 | 来源 |
|---|---|---|---|
| shim **修后** | `abf6879c027c5e73` | 299,040 | `R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so` |
| shim **修前** | `e700c383ec1ecdc8` | 299,040 | `/home/links-dev/w34-framepresence-203516/run/libwpfwin32.so` |
| bridge | `e3ea092010734f44` | 5,019,968 | `R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/` |
| `PresentationCore.dll` | `043eff4b1d8ecd7d` | 3,601,408 | `R/build/PresentationCore.Linux/bin/Release/` |
| `PresentationFramework.dll` | `366e9486536bc291` | 6,119,424 | `R/build/PresentationFramework.Linux/bin/Release/` |
| `libwpfwic.so` | `56278c14b4ecd672` | 70,728 | `R/build/DirectWrite.Linux/wic-shim/` |
| `libSkiaSharp.so` | `a02cd03f1ebcbb97` | 9,244,960 | 同上 |

整份 sha256：
`abf6879c027c5e731056d5c760efc8b058022fa5f63d61d23fa72ce805517424`（修后）、
`e700c383ec1ecdc8a0f24424216fc4298388b5625a7e1c7ee676b25ac5afea1a`（修前）。

**一个便利事实**：hc 的 app-local 副本里 `bridge`/`pc`/`pf` **本来就与权威件逐字节相同**
（`e3ea092010734f44`/`043eff4b1d8ecd7d`/`366e9486536bc291`），只有 `libwpfwin32.so` 是**修前**的
`e700c383ec1ecdc8`。⇒ 置换**只有 shim 一个变量**，两趟之间其余件零位移（每趟仍 `cp -f` 权威件复核）。

### 1b. 修法在**二进制层**的独立复核（不看别人的结论，直接反汇编）

```
修前 e700c383…:  SetCapture@0x10440 / ReleaseCapture@0x10480
                 —— 只有 wpf_global_init / wpf_lock / pthread_mutex_unlock，
                    **无 `$0x215`、无 `wpf_dispatch_to_window`**
修后 abf6879c…:  SetCapture@0x10440:  … mov $0x215,%esi ; call wpf_dispatch_to_window@plt
                 ReleaseCapture@0x104b0: … mov $0x215,%esi ; call wpf_dispatch_to_window@plt
```

`0x0215 = WM_CAPTURECHANGED`。⇒ 「修前一条消息都不派发、修后在易主/释放时派发」这一条
**在机器码层面成立**，与本轮的现象读数同向。

---

## 2. 方法与纪律

- **目标坐标不猜像素**：hc 自带的 `HC_INPUT_DIAG=1` 仪器会打 `[GEO]`——每个可点控件的
  `PointToScreen` **屏幕矩形**（`scr=x,y wh=WxH`）与每个项容器。点击坐标一律取自它自报的中心。
  （`HC_GEO_EVERY=2`、`HC_DUMP_MAX=900`。）
- **指针全程不出窗**：W47B 的教训是「每步把指针移出窗口」会**顺带释放捕获**、系统性藏住本缺陷。
  本轮的 5 步**连做**，中间只移动指针、不停到窗口外（唯一一次越界见 §4 自伤①，已修）。
- **导航索引**：`DemoInfo.json` 的 Styles 组 = 扁平 31 项；实测 `nm=` 用的是英文 `Name`
  ⇒ `TextBox`=idx9、`ComboBox`=idx10、`CheckBox`=idx5、`ListBox`=idx19，与派单书一致。
- 每一步前后切 `app.log` 行号，读数按段切片，不跨步取。
- 每趟一个私有 app 目录（`$HOME/w48b-app-{new,old}`）＋私有 Xvfb `:35`；跑前跑后 `sha256sum` 复核。
- 未碰 `:97`/`:93`/`:36`/`:38`/`:39`/`:58`、未碰 `$HOME/w47*`/`w48a*`；未改仓内任何文件（只新增本报告）。

**量测件**：`$HOME/w48b/run3.sh`（启动＋5 步＋收尾一体）、读数落在
`$HOME/w48b/out/0919-230145-new-v2/`（修后）与 `$HOME/w48b/out/0919-230238-old-v2/`（修前），
各自 `READING.txt` ＋ `app.log` ＋ 逐帧 `png`。

---

## 3. ① 五步逐条读数（两极化并排）

判据列写在左；两列分别是**修前**/`e700c383ec1ecdc8` 与**修后**/`abf6879c027c5e73` 的实测读数。

### 步 1：nav idx9（文本框页）→ 点页面 TextBox

| 读数 | 修前 | 修后 |
|---|---|---|
| nav 点击 `(429,683)` 原文 | `preMouseDown src=Border#Bd … state=Pressed **cap=none**` | 同 |
| 页面是否真的换了 | `页面 TB=14 CB=0 Chk=0 LB=1`、`LB(ListBoxDemo sel=9/31)` ✓ | 同 ✓ |
| 页面 TextBox 自报中心 | `[817 353]` | `[817 353]` |
| **点 TextBox 的 `src=`（原文）** | `preMouseDown src=ListBox#ListBoxDemo(bg=#00FFFFFF) < Grid < ContentPresenter#PART_SelectedContentHost < Border#contentPanel … **cap=ListBox#ListBoxDemo**` ❌ | `preMouseDown src=TextBoxView(bg=-) < ScrollContentPresenter#PART_ScrollContentPresenter < Grid#Grid < ScrollViewer#PART_ContentHost … **cap=none**` ✅ |
| `GOTFOCUS` 里出现 `TextBox` | **0** | **31** |
| `ButtonState` 分布（pre/bub） | `pre= 1 Pressed / 16 Released；bub= 17 Released` | `pre= 36 Pressed；bub= 5 Pressed` |

**逐字**：修前那一击**根本没落到 TextBox 上**——`OriginalSource` 是导航 `ListBox`（因为它持捕获），
而命中链里连一个 `TextBox`/`TextBoxView` 都没有。

### 步 2：**紧接着**点 nav idx5（复选框页）—— 修前应被吞

| 读数 | 修前 | 修后 |
|---|---|---|
| nav 点击原文 | `src=Border#Bd … **cap=ListBox#ListBoxDemo**` | `src=Border#Bd … **cap=none**` |
| 页面 | `Chk=6` ✓、`sel=5/31` ✓ | `Chk=6` ✓、`sel=5/31` ✓ |

**这一格两趟都"过"——而且这正是指向缺陷的钥匙**：修前的点击**落在被捕获元素自己身上**，
所以路由正确、页面照换。缺陷只在**点到捕获元素之外**时才现形（步 1/3/4/5）。

### 步 3：回 nav idx9 → 点 TextBox → `xdotool type abc`

| 读数 | 修前 | 修后 |
|---|---|---|
| TextBox 点击 `src=` | `ListBox#ListBoxDemo … cap=ListBox#ListBoxDemo` ❌ | `TextBoxView … cap=none` ✅ |
| **键入后 `[STATE]` 原文** | `focus=` 集合里**没有 TextBox**；`TB(…)` 全 `focus=False` | `[STATE] t14 **focus=TextBox** TG(off) **TB(- len=7,caret=3,focus=True)** TB(- len=4,…` ✅ |
| 文本框内容 | 不动（`len=4` 恒定；`focus=True` 出现次数 **0**） | **`len` 4 → 7**（"这是内容"＋`abc`），`caret=3` ⇒ **`abc` 真的进去了** ✅ |
| 键期内 `[HCIN]` 行数 | 2（无输入相关事件） | 有焦点/文本事件 |
| 步 3b：同样点 TextBox 但**按住 600 ms** | 仍 `src=ListBox#ListBoxDemo cap=ListBox#ListBoxDemo`；`GOTFOCUS` 里 TextBox = **0** | `src=TextBoxView cap=none`（`pre=36 Pressed; bub=5 Pressed`）；`GOTFOCUS` 里 TextBox = 0 **因为焦点已在步 3 拿到、无新事件** |

**步 3b 是一条排除腿**：把按压从 150 ms 拉到 600 ms **修不了修前那一格**
⇒ 「点击被吞」的原因**不是**按压太短，而是捕获路由。

### 步 4：nav idx10 → 点 ComboBox 开下拉 → 点弹窗第 2 项

| 读数 | 修前 | 修后 |
|---|---|---|
| ComboBox 点击 `src=` | `(869,353) src=ListBox#ListBoxDemo … cap=ListBox#ListBoxDemo` ❌ | `(817,353) src=Border … cap=none` ✅ |
| `nwin` | `1 → 1` | `1 → 1`（弹窗是**无 WM 下的 override-redirect 子窗**，`xdotool search --name` 数不到） |
| 下拉状态 | `★ STATE:` 空 ⇒ **`CB(- open=True…)` 一次都没出现过** | `CB(- open=True sel=0/9 txt=正文1)` ✅ |
| `EV DropDownOpened` | **0** | **1** `EV DropDownOpened open=True cap=ComboBox` ✅ |
| `EV Executed`（HandyControl 命令链） | **0** | **28** ✅ |
| 弹窗 X 窗口 | `NOINFO [POP] 里没有 PopupRoot（下拉没建窗）` | `[POP] … root=PopupRoot … hwnd=0x200008`；`xdotool getwindowgeometry` ⇒ `(619,369) 413x274` ✅ |
| 弹窗第 2 项点击 | 无弹窗可点（NOINFO） | 估位 `(825,414)` ⇒ `src=Border#Bd … cap=ComboBox` ✅ |
| **选中结果** | — | **`EV CB.SelectionChanged sel=1/9 open=True added=1 src=ComboBox…`**；`CB(- open=False **sel=1/9 txt=正文正文2**)` ⇒ **第 2 项被选中、文本跟着变、下拉关闭** ✅ |
| `EV DropDownClosed` | **0** | **1** `open=False cap=none` ✅ |

### 步 5（附加）：列表框页 idx19 → 点页面里的列表项

idx19 在导航**视口之外**（布局 `scr=328,980`，nav 视口只到 `y=780`）⇒ 滚轮腿**实测不滚**
（且疑似有副作用，见 §4⑥），改走**键盘腿**（点 nav 取焦点 → `Down`×10，全是真实用户动作）。

| 读数 | 修前 | 修后 |
|---|---|---|
| 到达 idx19 | `LB(ListBoxDemo sel=19/31)`、`页面 LB=3` ✓ | 同 ✓ |
| 页面第 2 个 `ListBox` 中心 | `[942 544]` | `[942 544]` |
| 点列表项 `src=` | `src=ListBox#ListBoxDemo … **cap=ListBox#ListBoxDemo**` ❌ | `src=Border#Bd … **cap=none**` ✅ |
| **页面 ListBox 的 `SelectionChanged`** | **0 条**（`EV LB.SelectionChanged ListBox# ` 计数 = **0**；日志里只有导航 `ListBox#ListBoxDemo` 的箭头键盘事件） | **`EV LB.SelectionChanged ListBox# sel=7/20 added=1`** ⇒ **页面列表项真的被选中** ✅ |

---

## 4. ② 结论：hc 现象是否由 `D-G55` 解释

**是（判据：拔掉 `D-G55` 的反极性 ⇒ 现象出现；装上 ⇒ 现象消失；且机制读数同向）。**

1. **症状覆盖面**：修前，**输入框**（步 1/3：点 `src` 全是导航）、**组合框**（步 4：下拉零次打开）、
   **列表项**（步 5：页面 `ListBox` 的 `SelectionChanged` 恰好 0 条）—— 用户点名的三类**全部复现**。
2. **为什么"能跑"**：修前导航内部点击仍然生效（步 2 两趟都过），所以应用**看起来活着**、
   还能翻页；只有导航以外的控件全哑。修前 `cap=` 分布 **521 : 30** 说明捕获是**钉死的常态**，
   不是偶发。
3. **单一变量**：两趟之间只有 `libwpfwin32.so` 一位不同（其余六件 sha 逐位相同，§1）；
   修法在机器码层面也被独立复核（§1b）。⇒ 差异**归因于该 shim**，不归因于负载/环境。
4. **一条排除腿**：把按压拉到 600 ms 修不好（步 3b）⇒ 不是「点太快」这类客户端时序问题。
5. **未观察到其它更简解释**：两趟 `异常行` 均为 **0**（无 `SIGSEGV`/`X connection broken`/未处理异常）；
   页面切换、下拉建窗、文本输入在修后都正常。

**一条我不能排除的残留项（如实登记，不作为结论）**：`e.ButtonState` 在**冒泡腿**读数不稳
（修前 `bub=17 Released`；修后步 3 是 `5 Pressed`，而修后步 5 又是 `34 Released`）。
它与**修/不修不同向**——修后也出现过 `Released`，而那一击**照样成功选中了列表项**
⇒ 它**不是**本缺陷的判别量。上游 `TextEditorMouse.OnMouseDown:175` 确有
`if (e.ButtonState == MouseButtonState.Released) return;` 这道闸，所以它**原则上**能吃掉一次
TextBox 聚焦；但本轮没有把它与「点不动」的因果关系建立起来（无成对实验）⇒ 列为 **NOINFO**。

---

## 5. ③ 两极化汇总（一句话版）

> **同一份 hc app、同一份 bridge/pc/pf、同一个私有 X、同一套 5 步连做；
> 只把 `libwpfwin32.so` 从 `abf6879c027c5e73` 换成 `e700c383ec1ecdc8`：
> `EV DropDownOpened` 1→0、`EV Executed` 28→0、`[STATE] focus=TextBox` 10→0、
> 页面 ListBox 选中 1→0、`preMouseDown src` 从 `TextBoxView` 变成 `ListBox#ListBoxDemo`、
> `cap=` 从「常态 `none`」变成「521 次钉在导航上」。**

---

## 6. ④ 我自己踩的仪器自伤（如实留档）

① **`[GEO]` 的 `vis=True` 不等于"在视口里"** —— 导航 idx19 的项容器被父 ScrollViewer 裁掉，
   但 `[GEO]` 仍报 `vis=True` 并给出**未裁剪的布局坐标** `scr=328,980`，而窗口只到 `y=825`。
   我照它点了 `(429,993)` ⇒ **点到了窗口外**，等于亲手破坏了自己"指针不出窗"的纪律（前两趟作废）。
   **修法**：`navxy` 改为用 nav `ListBox` 自报的视口矩形**裁剪**后才返回坐标；裁剪后 idx19 返回空
   （正确的"不可见"），于是键盘腿才被触发。相关读数已全部重取。

② **`PointToScreen` 对弹窗内容抛异常** —— `[GEO]` 对弹窗里的 `ComboBoxItem` 打的是
   `scr=InvalidOperationException`（第一趟我还把它当坐标去点，点到导航上、`cap=ComboBox` 把它关掉了）。
   ⇒ 弹窗项坐标**无法**从应用自报拿到；改为读 `[POP]` 里 `PopupRoot` 自报的 `hwnd`，
   再用 `xdotool getwindowgeometry` 取**弹窗 X 窗口的绝对几何**，按 9 项估第 2 项中心。
   结果自洽（`(825,414)` 落在 `(619,369) 413x274` 内 ⇒ `sel=1/9 txt=正文正文2`）。

③ **`[HCIN] POLL` 的"下拉抖动"是仪器假象，不是产品缺陷** —— 日志里 `POLL open -> True/False`
   在 ~9 ms 内翻 **186 / 187** 次，但真实的 `EV DropDownOpened`/`EV DropDownClosed` **各只有 1 次**。
   原因：8 ms 定时器遍历**全部 22 个 `ComboBox`**，而 `_hcinLastOpen` 是**单个共享静态**
   （`App.xaml.cs:230/295/297`）⇒ 相邻两次比较的是**不同实例**。**不要**把它读成"下拉在闪"。

④ **类处理器每元素触发一次** —— `RegisterClassHandler(typeof(UIElement), …)` 让一次点击产生
   ~29–36 行同内容日志（一次点击的 `preMouseDown` 行数=路由上的 UIElement 个数）。
   我一开始差点把 14 行同内容行读成"14 次点击"。计数必须按**块**聚合，不能按行数。

⑤ **harness 自身的两次作废**：(a) 第一版 v2 脚本有 shell 语法错误（未闭合 `if`）⇒ 空跑一趟；
   (b) 重写 `navrect` 时 awk 的动作花括号少写一个 ⇒ `navxy` 恒返回空、脚本在 `$1` 未绑定处退出
   ⇒ **两趟空跑**。两处都当场复算并修好；§3 的读数全部来自修好之后的趟次。

⑥ **滚轮腿（`xdotool click 5`）不滚，且疑似有副作用** —— 指针在导航上滚轮后
   `item[0]` 的 `scr` **逐位不变**（仍是 328,391）；而某一趟的 `navsel` 序列里出现了
   `9 → 8 → 7` 这种**非点击也非我预期的键盘**位移。我**没有**把它归因清楚，
   因此**弃用滚轮腿**、改用键盘腿到达 idx19（并在报告里保留这条"没弄明白"）。

⑦ **坐标解析踩坑**：`xwininfo` 的 `Absolute upper-left X:` 用 `awk -F'[ :]+'` 切会得到一个
   非数字字段（`upper-left`），在 `set -u` 下直接把脚本打死（第一次 pre-fix 跑）。改用
   `xdotool getwindowgeometry --shell`。

⑧ **自报坐标会互相覆盖**：`geowin` 会把全局 `X/Y/WIDTH/HEIGHT` 覆写成**弹窗**的几何；
   步 5 若还用 `$X/$Y` 就会把指针算到别处。已把主窗几何另存为 `WX/WY/WW/WH`。

---

## 7. ⑤ NOINFO 清单

| # | 项 | 为什么 NOINFO |
|---|---|---|
| 1 | **用"点击导航项"到达 idx19** | 导航视口只显示前 ~13 项，idx19 被裁掉；滚轮不滚（§6⑥）⇒ 改**键盘腿**到达。因此"点击翻到列表框页"这一格没取到，但"**页面内列表项的点击**"这一格**已取到**（步 5）。 |
| 2 | `ButtonState` 在冒泡腿读 `Released` 的**成因** | 与修/不修**不同向**（修后步 5 也读到 `Released` 却成功）。缺成对实验（同坐标 × 有/无 `HC_INPUT_DIAG`、× 多档按压时长 × 多档负载），**不归因**。上游 `TextEditorMouse.cs:175` 那道 `Released ⇒ return` 的闸**原则上**能吃掉一次 TextBox 聚焦，但本轮未建立因果。 |
| 3 | `mouseUp hop=TextBox` 的 `handled=` | 修后那趟该行**不存在**（`grep -c 'mouseUp hop=TextBox '` = **0**，而 `mouseUp hop=` 共 209 行）⇒ "TextBox 这一跳是否把 MouseUp 标记为已处理"没拿到读数。修前那趟**本来就不该有**（点击没落到 TextBox）。 |
| 4 | 弹窗第 2 项坐标的**精确**性 | `PointToScreen` 对弹窗内容抛异常（§6②）⇒ 只能按 X 窗口几何 ＋ "9 项"**估算**（`(825,414)`）。结果正确（`sel=1/9`）但**含估算成分**，不是应用自报。 |
| 5 | 修前 `nwin` 为何 `1 → 1` | `xdotool search --name '.'` 在无 WM 下数不到 override-redirect 弹窗；本轮用 `[POP]` 的 `PopupRoot` ＋ X 窗口几何替代，`nwin` **不是**本报告的承重读数。 |
| 6 | 负载敏感性 | 两趟 `loadavg` 起点分别 0.84 / 1.28，全程未做**成对**负载对照（本机另有车道在跑整波重建）。步 3b 只在修后跑了 600 ms 一档。 |

---

## 8. 复算命令（照抄可复得 §3 的每一格）

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 修后 / 修前各跑一趟（各约 4 分钟；私有 X :35，跑前跑后自记 sha）
bash $HOME/w48b/run3.sh new $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so :35
bash $HOME/w48b/run3.sh old /home/links-dev/w34-framepresence-203516/run/libwpfwin32.so :35

N=$HOME/w48b/out/0919-230145-new-v2     # 修后
O=$HOME/w48b/out/0919-230238-old-v2     # 修前
# 判别量①：捕获住哪儿了
grep -a 'preMouseDown' $O/app.log | sed 's/.*src=\([A-Za-z#]*\).*cap=\([^ ]*\).*/\1 cap=\2/' | sort | uniq -c
grep -a 'preMouseDown' $N/app.log | sed 's/.*src=\([A-Za-z#]*\).*cap=\([^ ]*\).*/\1 cap=\2/' | sort | uniq -c
# 判别量②：键盘焦点到过哪些控件
grep -a '^\[STATE\]' $O/app.log | sed 's/^\[STATE\] t[0-9]* focus=\([A-Za-z#-]*\).*/\1/' | sort | uniq -c
grep -a '^\[STATE\]' $N/app.log | sed 's/^\[STATE\] t[0-9]* focus=\([A-Za-z#-]*\).*/\1/' | sort | uniq -c
# 判别量③：下拉开过没有 / 命令链通没通
for d in $O $N; do echo "$d open=$(grep -ac 'EV DropDownOpened' $d/app.log) exec=$(grep -ac 'EV Executed' $d/app.log) pageLB=$(grep -ac 'EV LB.SelectionChanged ListBox# ' $d/app.log)"; done
# 判别量④：文本框真的收到字了吗
grep -a '^\[STATE\]' $N/app.log | grep -ao 'TB([^)]*focus=True)' | sort -u
# 独立复核修法在不在（二进制层）
objdump -d --section=.text $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so \
  | awk '/<(SetCapture|ReleaseCapture)>:/{p=1} p{print} p&&/^$/{p=0}' | grep -E '\$0x215|wpf_dispatch_to_window'
```

**三行判词**（供台账逐字引用）：

```
REPRODUCED=yes        # hc 上「点击没反应」在修前件上 100% 复现、在修后件上 100% 消失
REPO-WRITES=1         # 仅新增本文件 build/MilBridge/W48B-report.md（其余仓内文件零写入）
DOTNET-CALLS=0        # 全程零 dotnet（无 build / 无 verify-all / 无冻结）
```

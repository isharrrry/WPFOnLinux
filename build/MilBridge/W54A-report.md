# W54A 报告 —— `D-G64`（`WindowFromPoint` **下降判据**）验证：有窗口管理器时"点击全被吞"**治好了**

> **一句话**：**治好了**。四条腿（修后+有WM／修后+无WM／修前+有WM／单变量杀WM）全部按判据落到预期档位，
> 其中「修后+有WM」五步点击**全部生效**（9 击 `BTNpress=1`、`preMouseDown` 17~46、`AE` 7647~232434、
> `LB sel` −1→1/9/10/2/3、六个页面真的换过、`FINAL alive=yes`）；**反极性精确**（修前+有WM：同一坐标、
> 同一个 X 事件、`preMouseDown=0`、`AE=0`、`sel` 恒 −1/31、页面恒 PracticalDemo，而 `alive=yes`）；
> **单变量成立**（同一个进程、同一件修前 shim，只把 `xfwm4` 按 PID 杀掉 ⇒ X 把客户还给 root ⇒
> 下一击立刻恢复：`preMouseDown` 0→32、`AE` 0→232605、`sel` −1→5/31）。
> **`[WFP_DIAG]` 给出"机制对了"的直接机器证**：`top=0x400264`（WM 框架）`own_top=0` → **`ret=0x600004`（我方客户窗）** `depth=2`，40/40 行同值。
>
> **同时如实报三件不那么好听的事**：(1) 有一趟「修后+有WM」在**点页签**那一步之后**崩了**，
> 但**同一个崩溃用修前 shim 在无 WM 环境下同样发生**（L8）⇒ **不是这条修法带来的**，是既有缺陷被修法
> **暴露**出来；(2) 我给的四条腿里，③ 的 WM 证据链里 `_NET_SUPPORTING_WM_CHECK` **在 W53A 四格矩阵里是坏的**
> （见 §0.4）；(3) 我自己的仪器先犯了两个错（贪婪正则、`scr=InvalidOperationException` 当坐标），都已修好并留档。

`lane=W54A`｜2026-09-20 11:23→11:48（+0800）｜kernel `6.8.0-138-generic`｜`nproc=3`｜
`loadavg` 逐腿记于 §1.1（0.29~2.20）｜`MemAvailable` **2,479,368 kB（开工 11:23）→ 2,212,398 kB（11:44）
→ 2,630,488 kB（L11）→ 2,600,572 kB 级（全程 >2,200 MB，无等待；纪律要求 >1,200 MB）**

---

## §0 环境、装置与件 sha16

### 0.1 装置

| 项 | 值 |
|---|---|
| 私有应用目录 | `$HOME/w54a/app`（`cp -a` 自 `/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`，113 M / 72 项） |
| 私有显示 | `:151`（无 WM）／`:152`（`xfwm4`）——**全部自起自收（按 PID）**；**未碰**用户的 `:0`／`:1`／`:10` |
| 用户会话 | 只读观察：用户的 `xfwm4`(1751373) 全程存活，**我没动它**；收工 `pgrep -x Xvfb; pgrep -x dotnet; pgrep -x xmessage` **全空** |
| 每腿换的**唯一**件 | `$HOME/w54a/app/libwpfwin32.so`（腿驱动在 `cp -f` 之后**立刻断言 sha16**，不符即 `exit 2`，**绝不产出错读数**） |
| 每腿的应用 env | `HC_INPUT_DIAG=1 HC_GEO_EVERY=2 HC_DUMP_MAX=200 WPF_LINUX_KEY_DIAG=1 WPF_LINUX_WFP_DIAG=1` |
| 修后件（权威路径） | `$R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so` |
| 修前件（**抢存的私有副本**） | `$HOME/w54a/old/libwpfwin32.so`（原因见 §0.4-(2)） |

### 0.2 五件 sha16（本趟现场算；除 `libwpfwin32.so` 外**四件全程 = 冻结值**）

| 件 | 实测 sha16 | 字节 | 冻结/期望 | 命中 |
|---|---|---|---|---|
| `libwpfwin32.so`（**修后**） | `867d96e7cb0cba36` | 299,120 | `867d96e7cb0cba36` | ✅ |
| `libwpfwin32.so`（**修前**） | `abf6879c027c5e73` | 299,040 | `abf6879c027c5e73` | ✅ |
| `wpfgfx_cor3.so` | `e3ea092010734f44` | 5,019,968 | `e3ea092010734f44` | ✅ |
| `PresentationCore.dll` | `9465f9dce39e2dfc` | 3,601,408 | `9465f9dce39e2dfc` | ✅ |
| `PresentationFramework.dll` | `1011da6390c3bf1e` | 6,119,424 | `1011da6390c3bf1e` | ✅ |
| `WindowsBase.dll` | `79740e9ba7fbf9ca` | 1,111,552 | `79740e9ba7fbf9ca` | ✅ |

修后件**源码**：`src/WpfGfx.Linux.Native/src/win32_core.c` `sha16 9b1fd23be329ee6e`，76,853 B，
mtime `2026-09-20 11:22:36`。**修前源码 sha16 `4e054c88cc3f5fce` 我无法独立复核**
（本机**没有 `git`**：`bash: git: 未找到命令`；全盘只有一份 `win32_core.c`，即修后件）⇒ 见 §4 `NOINFO`。

### 0.3 我自己的仪器（全部在 `$HOME/w54a/**`，逐件 sha16）

| 仪器 | sha16 | 作用 |
|---|---|---|
| `bin/legrun.sh` | `7f8fe8b05ae152ee` | 腿驱动（五步 + 判据 + `alive` + `AE` + WM/重定父正证） |
| `bin/legrun_noTab.sh` | `88cefa13f56ffb5f` | 同上，仅把 ⑤ 强制走"顶部按钮"口径（见 §1.1 括注） |
| `bin/pick.py` | `b6129cb2ee3efa55` | 从最后一个完整 `[GEO]` 块取坐标；**拒绝非数字 `scr=`**（§0.4-(3)） |
| `bin/state_read.py` | `7a6e9005ada235d6` | 读最后一行 `[STATE]`，取**聚焦的那个** `TB`（§0.4-(3)） |
| `bin/wfp_probe2`（源码 `bin/wfp_probe2.c`） | `3447959641b916d8` | **复刻**修前/修后两种算法在**活**窗口树上对照（§2.3）；**这是复刻，不是 shim 本体** |
| `bin/l9_probe.sh` | `e8eac429be52b4b0` | L9 腿驱动 |
| `bin/l6_otherwin.sh` | — | L6 腿驱动（覆盖窗） |

`[GEO]` 坐标拾取一律取应用**自报**的 `scr=`；落点由 X 层 `[KEY_DIAG] BTN type=Press … xy=` **反证**（§1.3）。

### 0.4 我推翻／纠正的三件事（先说，因为读法依赖它们）

**(1) W53A 四格矩阵里那条 WM 证据是坏的 —— 它读到的 `0x2000ae` 是"杀了 WM 之后**残留**的属性"，不是活 WM 的证明。**
W53A 报告 §0 写「在 WM 腿 = `window id # 0x2000ae`」，但它的**四格矩阵每格** `marks.txt` 里那行原文都是：

```
WMPROOF _NET_SUPPORTING_WM_CHECK:  no such atom on any window.
```

（`C-wm-splash`、`D-wm-nosplash`、`C2-wm-splash`、`D2-wm-nosplash` 四格**逐字相同**；我逐格 grep 过。）
而 `0x2000ae` 唯一一次出现，是在 `WFP3-wm-killwm/report.txt` 的 **② 杀 WM 之后**那一行：

```
   WMPROOF_AFTER: _NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x2000ae  xfwm4_alive=no
```

⇒ **那是一个已经死掉的 WM 留在 root 上的**陈旧**属性**。我在本趟的 L4 腿上**独立复现**了同一现象
（`KILLWM_AFTER wm_alive=no atom=_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x4000ae` 而 `xfwm4` 已死）。
**影响**：W53A 的 WM 腿结论**不受影响**（它的**真**证据是重定父框架，见下），但那句"用原子证明 WM 在场"的**证法**是错的。
**我本趟改用三条活证据**（L11 原文）：

```
WMPROOF_ATOM   _NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x4000ae
WMPROOF_SUPNAME _NET_WM_NAME(UTF8_STRING) = "Xfwm4" WM_CLASS(STRING) = "xfwm4", "Xfwm4"
REPARENT_PROOF 6291460 parent:   Parent window id: 0x400264 (has no name)
ACTIVE_WINDOW  _NET_ACTIVE_WINDOW(WINDOW): window id # 0x600004, 0x0
```

我另测了原子上位的时间：`xfwm4` 起后 **t≈1.0 s** 就有（逐 0.5 s 记了 24 点）⇒ **原子本身可用**，
W53A 那几格是**检查时机/脚本**的问题，不是 `xfwm4` 的问题。

**(2) 我任务书里指定的"旧 shim 来源"在 11:30:01 被别的车道覆写成了修后件。**
任务书给的第一来源是 `$HOME/w53a/app/libwpfwin32.so`，兜底是 hc 应用目录。我的腿链 v1 在
`11:30:39` 打出的现场读数是：

```
    shim authority sha16(before)=867d96e7cb0cba36 old=867d96e7cb0cba36      ← "old" 也是**修后**件！
```

hc 目录里那件的 mtime 是 `2026-09-20 11:30:01.546943425`、sha16 = `867d96e7cb0cba36`（**修后**）。
⇒ **任何"从 hc 应用目录拿修前件"的做法现在都会静默拿到修后件**。
**后果全拦住了**：腿驱动在拷贝后立刻断言 sha16，L3／L4 因此**在 11:32:58 / 11:33:01 以 `rc=2` 失败**
（`marks.txt` 为 0 字节，`say` 行都没写出来 ⇒ 那两趟**没有产出任何读数**）。
**处置**：我在 `11:30` 抢存 `$HOME/w54a/old/libwpfwin32.so`（`abf6879c027c5e73`，299,040 B，
mtime 保留 `9月20 08:43`）并把腿驱动改成**源件自证 sha**（`SRC16 != OLD_AUTH_EXPECT ⇒ FATAL exit 2`），
五条主腿随后**重跑**（§1）。**建议登记**：`w53a/app` 那份是本机目前**唯一**稳定的修前件来源，别再被 sync 刷掉。

**(3) 我自己的两处仪器自伤（都已修好）**
- **贪婪正则**：`sed 's/.*TB(- len=\([0-9]*\)…/'` 里 `.*` 贪婪 ⇒ 取到一行里**最后**一个 `TB`，
  于是"点了 TextBox 后打字生效"这个判据被我读成 `len=0`（**假红**）。L1 首趟即栽在这里
  （`TB_before=[len=0 caret=0 focus=False] TB_after=[len=0 caret=0 focus=False]`，而同一段
  `[STATE]` 原文明明是 `t26 … TB(- len=7,caret=3,focus=True)`）。改用 `state_read.py`（按 `focus=True` 定位）后
  读数变成 `TB_before=[- len=4,caret=0,focus=True] → TB_after=[- len=7,caret=3,focus=True]`（4→7，正好 +3 = "abc"）。
- **把异常名当坐标**：`[GEO]` 的 dumper 对 `ComboBoxItem` 会把**坐标字段**打成
  `scr=InvalidOperationException`（本趟日志里 **36 次**，逐字：`[GEO]   item[2] ComboBoxItem scr=InvalidOperationException wh=376x27 vis=False nm=正文正文正文3`）。
  我的 `nav` 拾取器按 `item[N]` 首次命中 ⇒ 拿到这行 ⇒ 那一击点在**不存在的坐标**上（L1b 的 S4 因此空转）。
  已在 `pick.py` 里要求 `scr=` **必须是数字**且优先 `ListBoxItem`（`NUMSCR` 判据）。
  **这一条本身是个真缺陷**：一个坐标字段能携带非坐标 token，任何"看见 item 就点"的仪器都会中招。

---

## §1 四条腿 × 5 步读数表

### 1.1 汇总（每格一次运行；`AE=0` = 整屏逐位不变）

| 腿 | 装置 / shim | `BTNpress` | `preMouseDown` | `LB sel` 轨迹 | 页面轨迹 | 末态 `alive` | 判定 |
|---|---|---|---|---|---|---|---|
| **① 修后+有WM** `L11-postfix-wm-notab` | `:152`+`xfwm4`；**新** `867d96e7cb0cba36` | 9 | **273** | −1→1→9→10→2→−1→3 | Practical→Button→NativeTextBox→NativeComboBox→RepeatButton→Practical→ToggleButton | **yes** | **点击全活 ✅** |
| **①′ 修后+有WM（含点页签）** `L1-postfix-wm` | 同上 | 8 | **245** | −1→1→9→10→2 | …→RepeatButton | **no**（§3.3） | 点击全活至 S4；S5a 后崩（**非本修法**） |
| **② 修后+无WM** `L12-postfix-nowm-notab` | `:151`；**新** | 9 | **273** | −1→1→9→10→2→−1→3 | 与 ① **逐步同** | **yes** | **点击全活 ✅（无回归）** |
| **②′ 修后+无WM（含点页签）** `L2-postfix-nowm` | 同上 | 8 | **245** | −1→1→9→10→2 | …→RepeatButton | **no**（§3.3） | 与 ①′ 逐步同 ⇒ 崩溃与 WM 无关 |
| **③ 修前+有WM** `L3-prefix-wm` | `:152`+`xfwm4`；**旧** `abf6879c027c5e73` | 7 | **0** | 恒 −1/31 | 恒 PracticalDemo | yes | **点击全死 ✅（反极性成立）** |
| **④ 修前+有WM→杀WM** `L4-prefix-wm-killwm` | 同上，同一进程 | 8（前 7 击死、第 8 击活） | 前 7 击 **0** ／第 8 击 **32** | 恒 −1→**5/31** | Practical→**CheckBox** | yes | **单变量成立 ✅** |
| **④′ 修后+有WM→杀WM** `L5-postfix-wm-killwm` | **新** | 8 | 245 | −1→1→9→10→2 | …→RepeatButton | **no**（§3.3） | 杀 WM 前后**都能点**（对修法中性） |
| ⑤ 补：**修前**+无WM `L8-prefix-nowm` | `:151`；**旧** | 5 | **152** | −1→1→9→10 | Practical→Button→NativeTextBox→NativeComboBox | **no** | **归因腿**：修前件在"点击能落地"的环境里**同样崩** |
| ⑥ 补：覆盖窗（新/旧）`L6-otherwin-*` | `:152`+`xfwm4`+`xmessage` | 0（被截走） | 0 | 不变 | 不变 | yes（新）/ no（旧） | §2.3、§3.3 |

> **⑤ 的口径说明**：`L11/L12` 把第 ⑤ 步**强制**成"顶部按钮"（`S5_TABLINE NOINFO no-TabItem(L11/L12 forced: …)`），
> 为的是拿到一趟**走完全部步骤且 `FINAL alive=yes`** 的干净读数；**"点页签"那一条由 `L1/L2` 另计**（它们点了页签，
> 但那一击之后崩了 ⇒ 效果被掩盖，见 §3.3）。两条读数**不混用**。
> 逐腿 `loadavg`：L11 `0.29 0.68 0.88`｜L12 `0.21 0.55 0.78`｜L3 `0.49 1.05 1.06`｜L4 `0.42 0.94 1.02`｜L8 `0.20 0.60 0.80`。

### 1.2 逐腿 × 逐步（判据行**原文摘要** ＋ `alive` ＋ `AE`）

**① `L11`（修后+有WM，新 `867d96e7cb0cba36`，WID=6291460=0x600004，重定父进框架 0x400264）**

| 步 | 点击坐标 | `AE` | `BTNpress` | `preMouseDown` | `nsLoaded` | `LB sel`／`focus` | 页面 | `alive` |
|---|---|---|---|---|---|---|---|---|
| ① 点导航 `item[1]`（ListBox 的项）| (283,451) | **225596** | 1 | **29** | 1 | −1/31 → **1/31**／ListBoxItem | **ButtonDemo** | yes |
| ② 点导航 `item[9]` | (283,699) | **73899** | 1 | **29** | 1 | **9/31** | **NativeTextBoxDemo** | yes |
| ②b 点页面 `TextBox` | (592,364) | **7647** | 1 | **36** | 0 | 9/31／**TextBox** | NativeTextBoxDemo | yes |
| ②c `xdotool type abc` | — | — | — | — | — | `TB(- len=4 → **len=7**,caret=0→**3**,focus=True)` | — | yes |
| ③ 点导航 `item[10]` | (283,730) | **23419** | 1 | **29** | 1 | **10/31** | **NativeComboBoxDemo** | yes |
| ③b 点 `ComboBox` | (632,368) | **53155** | 1 | **29** | 0 | 10/31／**ComboBoxItem**；`CBLINE … CB(- open=True sel=0/9 txt=正文1)`；**顶层窗口 16→17** | NativeComboBoxDemo | yes |
| ③c 点弹窗项（X 真值几何）| (468,409) | **52903** | 1 | **46** | 0 | 10/31；`CB_AFTER=- open=False sel=0/9`；**窗口 17→16** | NativeComboBoxDemo | yes |
| ④ 点 `ListBox` 的另一项 `item[2]` | (283,482) | **75446** | 1 | **29** | 1 | 10/31 → **2/31** | **RepeatButtonDemo** | yes |
| ⑤ 点顶部按钮（备用口径）| (373,313) | **232434** | 1 | **17** | 1 | → **−1/31**／Button | **PracticalDemo** | yes |
| ⑥ 换页后**再**点导航 `item[3]` | (283,513) | **227343** | 1 | **29** | 1 | → **3/31** | **ToggleButtonDemo** | yes |
| — | **FINAL** | — | **9** | **273** | **7** | — | — | **yes** |

原文（①，第一击 —— **这就是"治好了"最直接的一格**）：

```
──── STEP S1-nav-item1 click=(283,451) alive_before=yes alive_after=yes AE=225596 BTNpress=1 preMouseDown=29 nsLoaded=1
     | [WFP_DIAG] pt=283,451 top=0x400264 own_top=0 ret=0x600004 depth=2
     | [HCIN] preMouseDown src=Border#Bd(bg=#FFEEEEEE) < ListBoxItem(bg=#FFEEEEEE) < VirtualizingStackPanel(bg=-) < … btn=Left state=Pressed cap=none
     | [STATE] t13 focus=null TG(off) TB(- len=0,caret=0,focus=False) TG(off) LB(ListBoxDemo sel=-1/31)
```
击后：`S1_PAGE ButtonDemo`、`sel=1/31`。

原文（③b，弹窗真开了）：

```
S3_WIN_BEFORE=16   →   S3_WIN_AFTER_OPEN=17
CBLINE=[POP] |[0] HwndSource root=MainWindow wh=768x576 vis=True kids{TG(off) CB(- open=True sel=0/9 txt=正文1) …} hwnd=0x600004 vis=root
      |[1] HwndSource root=PopupRoot wh=396x263 vis=True kids{} hwnd=0x600008 vis=root
```
原文（③c，弹窗项点击走的是 **X 真值**几何，因为 `[GEO]` **不给**弹窗项 —— W53A 已证，我复核一致）：

```
S3_POPITEM NOINFO no-popup-item aux_lines=1
S3b_XTRUTH NEWWIN=0x4002fd wins=[… 0x4002fd 0x400264 ]
S3b_XTRUTH_GEOM win=0x4002fd abs=(428,358) wh=423x308 item_h=34
STEP S3b-click-popitem click=(468,409) alive=yes AE=52903 BTNpress=1 preMouseDown=46
S3b_CB_AFTER_PICK - open=False sel=0/9 txt=正文1        ← 弹窗关了；**sel 停在 0/9 不是"选中项变了"的正证**（我点的第 1 项本来就 sel=0）
```

**② `L12`（修后+无WM，`:151`，`REPARENT_PROOF … Parent window id: 0x50d (the root window)`）**
九步的判据**与 ① 逐步同值**：`AE` 225596／73899／7647／23419／**28302**／**21112**／75531／232434／227343，
`preMouseDown` 29／29／36／29／29／46／29／17／29，`TOTAL_preMouseDown 273`、`TOTAL_BTNPRESS 9`、
`sel` 轨迹与页面轨迹**与 ① 完全相同**、`FINAL alive=yes`。
（**仅 ③b/③c 的 `AE` 不同**：53155/52903（有 WM，弹窗带框架）vs 28302/21112（无 WM）—— 那是**弹窗渲染**的差别，
不是"点击否生效"的差别；其余 7 步**逐位相同** ⇒ `HC_NO_SPLASH` 之外**没有回归**。）

**③ `L3`（修前+有WM，旧 `abf6879c027c5e73`，重定父进框架 0x400264）**

| 步 | 点击坐标 | `AE` | `BTNpress` | `preMouseDown` | `nsLoaded` | `LB sel` | 页面 | `alive` |
|---|---|---|---|---|---|---|---|---|
| ① nav `item[1]` | (283,451) | **0** | 1 | **0** | 0 | **−1/31** | **PracticalDemo** | yes |
| ② nav `item[9]` | (283,699) | **0** | 1 | **0** | 0 | −1/31 | PracticalDemo | yes |
| ③ nav `item[10]` | (283,730) | **0** | 1 | **0** | 0 | −1/31 | PracticalDemo | yes |
| ④ nav `item[2]` | (283,482) | **0** | 1 | **0** | 0 | −1/31 | PracticalDemo | yes |
| ④b 重试 `item[2]` | (283,482) | **0** | 1 | **0** | 0 | −1/31 | PracticalDemo | yes |
| ⑤ 点页签 `TabItem` | (371,344) | **0** | 1 | **0** | 0 | −1/31 | PracticalDemo | yes |
| ⑥ nav `item[3]` | (283,513) | **0** | 1 | **0** | 0 | −1/31 | PracticalDemo | yes |
| — | **FINAL** | — | **7** | **0** | **1** | — | — | **yes** |

原文（`S1` 判据行 ＋ 该击的 `[STATE]`）：

```
──── STEP S1-nav-item1 click=(283,451) alive_before=yes alive_after=yes AE=0 BTNpress=1 preMouseDown=0 nsLoaded=0
     | [STATE] t13 focus=null TG(off) TB(- len=0,caret=0,focus=False) TG(off) LB(ListBoxDemo sel=-1/31)
```
`TOTAL_WFP_DIAG 0` —— **不是"没打印"，是那件二进制里没有这段代码**（§2.2）。

**④ `L4`（修前+有WM，同一进程里 `kill -TERM` WM）** —— **本报告最强的一格**

```
STEP S6-nav-after-page   alive=yes AE=0 BTNpress=1 preMouseDown=0 nsLoaded=0 sel=-1/31 page=PracticalDemo   ← 第 7 击，仍然死
KILLWM by-pid 3190133
KILLWM_AFTER wm_alive=no atom=_NET_SUPPORTING_WM_CHECK(WINDOW): window id # 0x4000ae
KILLWM_REPARENT   Parent window id: 0x50d (the root window) (has no name)      ← X 把客户**还给 root**了
STEP S7-nav-after-wmkill click=(283,544) alive=yes AE=232605 BTNpress=1 preMouseDown=32 nsLoaded=1 sel=5/31 page=CheckBoxDemo
```

原文（第 8 击的命中链，**证明那一击真的打进了产品**）：

```
     | [HCIN] preMouseDown src=Rectangle(bg=-) < StackPanel(bg=-) < ContentPresenter(bg=-) < Border#Bd(bg=#FFEEEEEE) < ListBoxItem(bg=#FFEEEEEE) < … btn=Left state=Pressed cap=none
```

⇒ **同一个进程、同一件修前 shim、同一批坐标**，唯一变化是"root 与客户之间**有没有**那层框架"。

**④′ `L5`（修后+有WM→杀WM）**：杀 WM 前的 7 击**全部生效**（`preMouseDown` 29/29/36/29/29/46/29），
杀 WM 后仍生效 —— 即修法**既不依赖"没有 WM"，也不被 WM 的来去扰动**。（该趟末态 `alive=no`，原因同 ①′，§3.3。）

### 1.3 「同一批 X 事件、两种结果」—— 唯一的自变量是 shim（有WM 腿）

三趟用**同一脚本、同一坐标推导**发出点击，X 层记录到的**客户坐标逐条相同**：

| 第 n 击 | ① `L11`（新 shim） | ③ `L3`（旧 shim） | ⑤ `L8`（旧 shim，**无 WM**） |
|---|---|---|---|
| 1 | `xy=38,210` | `xy=38,210` | `xy=38,210` |
| 2 | `xy=38,458` | `xy=38,458` | `xy=38,458` |

原文（`L11`）：

```
[KEY_DIAG] BTN type=Press btn=1 win=0x600004 state=0x0 time=132878268 send=0 subwin=0x0 xy=38,210 same_screen=1
```
原文（`L3`，**同一个 `win`、同一个坐标，后面什么都没有**）：

```
[KEY_DIAG] BTN type=Press btn=1 win=0x600004 state=0x0 time=132375645 send=0 subwin=0x0 xy=38,210 same_screen=1
```
原文（`L8`，旧 shim 但**没有 WM** ⇒ **恢复**）：

```
[KEY_DIAG] BTN type=Press btn=1 win=0x200004 state=0x0 time=132727426 send=0 subwin=0x0 xy=38,210 same_screen=1
```
`L8` 同坐标的后续判据：`preMouseDown=29 nsLoaded=1 sel=1/31 page=ButtonDemo AE=225596` —— 与 `L11` **同值**。

⇒ **X 事件到达了我们的客户窗口、坐标也对**；差别只在 (a) 有没有 WM 框架（`L3` vs `L8`）、
(b) shim 是哪一件（`L3` vs `L11`）。

---

## §2 `[WFP_DIAG]` 关键行 —— `top` / `own_top` / `ret` / `depth` 对照

### 2.1 修后（**shim 本体**打印，`WPF_LINUX_WFP_DIAG=1`）

`L11` 全程 **40/40 行**（每进程上限 40）**同值**：

```
[WFP_DIAG] pt=283,451 top=0x400264 own_top=0 ret=0x600004 depth=2
```

对照关系（现场核对）：`top=0x400264` = 那层 **WM 框架**（`REPARENT_PROOF … Parent window id: 0x400264`）；
`ret=0x600004` = **我方客户窗**（`WID=6291460` = `0x600004`）；`own_top=0` = 框架不属于本进程；
`depth=2` = 从 root 直接子窗口**下沉了两层**（框架 → 客户）。
`L1`（含点页签那趟）同样是 `40/40` 行 `top=0x400264 own_top=0 ret=0x600004 depth=2`。
`L9`（无 `HC_INPUT_DIAG`，只有 shim 侧诊断）独立复现：`SHIM_WFP_DIAG_total=10`，前 3 行同值。

⇒ **"修前返回框架、修后返回客户窗"这个机制，被 shim 自己打出来了**，不是我从行为反推的。

### 2.2 修前：**没有这段代码**（不是"读数不同"，是"没有读数"）

| 件 | `grep -ac WFP_DIAG <二进制>` | `L3` 日志里的 `[WFP_DIAG]` 行数 |
|---|---|---|
| 修前 `abf6879c027c5e73` | **0** | **0** |
| 修后 `867d96e7cb0cba36` | **2** | 40（有界） |

⇒ 修前腿**不可能**有 `[WFP_DIAG]` 读数；`L3/L4/L8` 的 `TOTAL_WFP_DIAG 0` 是**"该代码不存在"**，
**不是**"该分支没走到"。这一格必须读成 `NOINFO(修前件无此诊断代码)`，**不许当成"修前也是 ret=客户窗"**。

### 2.3 补腿 `L9`：把**两种算法**都复刻出来 ＋ 覆盖「无本进程窗口」那一支

`wfp_probe2`（**复刻**，sha16 `3447959641b916d8`）在**活的**窗口树上逐点算；`L9` 原文：

| 情形 | `root_child` | 修前口径 `PREFIX ret` | 修后口径 `POSTFIX ret` | `depth` | `chain` |
|---|---|---|---|---|---|
| ① 未覆盖（点在我方客户窗上）| `0x400264` | `0x400264` **match_own=no** | **`0x600004` match_own=yes** | 2 | `0x400264 > 0x600004` |
| ③ 被 `xmessage` 盖住 | `0x4002fd` | `0x4002fd` match_own=no | **`0x4002fd` match_own=no** | 4 | `0x4002fd > 0xa00026 > 0xa00027 > 0xa00028` |
| ④ 覆盖窗拿掉（单变量）| `0x400264` | `0x400264` | **`0x600004`** | 2 | `0x400264 > 0x600004` |
| ⑤ 桌面上无 root 直接子窗口的点 `(1270,1014)` | **`0x0`** | `0x0` | `0x0` | 0 | — |

**正控（复刻算对了没）**：① 的 `POSTFIX ret=0x600004 depth=2` 与 **shim 本体**同一坐标打出的
`ret=0x600004 depth=2` **逐位相同**。
**诚实标注**：我复刻的 `own_top` 字段**是错的**（`WFP2 … own_top=1`，而 shim 本体同点是 `own_top=0`）——
因为我的 `is_own` 把"own 的**祖先**"也算成 own（框架是客户的父窗口 ⇒ 被误判为 own）。
**这个错误不影响 `ret`/`depth`**（① 与 ③ 的 `ret` 都与 shim 一致），但 `own_top` 一栏**以 shim 本体的读数为准**，不看我的复刻。

**③ 是这一腿的重点**：整条链上**一个本进程窗口都没有** ⇒ 修后算法走 `best=NULL ⇒ ret = top`
**原样返回顶层（别人的框架）**，**没有**把"别人窗口上的点"误认成自己的 ⇒ 修法的"下降"**不会过度接线**。
**⑤** 则覆盖 `if (!child) return NULL;` 那一支。

**L6（覆盖窗 + 真点击）的读数与限度**：`L6-otherwin-new` 里盖住时
`HIT covered alive=yes AE=35352 **BTNpress=0** preMouseDown=0 WFP_DIAG_in_seg=0 sel=1/31` ——
即**X 根本没把这一击投给我方**（`BTNpress=0`）⇒ 该窗口的 `WindowFromPoint` **压根没被调用**，
所以 **L6 本身覆盖不到 §2.3-③ 那一支**；那一支是由 `L9` 的复刻补上的。这一点我不含混。

---

## §3 结论

### 3.1 判定：**修法有效**（点击恢复），且**没有弄坏无 WM 腿**

| 判据 | 要求 | 实测 | 判定 |
|---|---|---|---|
| ① 修后+有WM：≥5 步 `preMouseDown>0` | 是 | 9 步**全部** >0（17~46） | ✅ |
| ① 修后+有WM：`AE>0` | 是 | 9 步**全部** >0（7647~232434） | ✅ |
| ① 修后+有WM：`LB sel` 从 −1/31 变 | 是 | −1→**1/31**（第 1 击） | ✅ |
| ① 修后+有WM：至少一次换页 | 是 | **6 个页面**真的加载过 | ✅ |
| ① 修后+有WM：`[WFP_DIAG]` 显示 `own_top=0` 且 `ret=` 客户窗 | 是 | `top=0x400264 **own_top=0** ret=**0x600004** depth=2`（40/40 行同值） | ✅ |
| ② 修后+无WM：**仍生效** | 是 | 9 步判据与 ① **逐步同值**（7 步 `AE` 逐位相同） | ✅ 无回归 |
| ③ 修前+有WM：**仍死** | `preMouseDown=0`、`AE=0`、`sel` 恒 −1/31、`alive=yes` | 7 击**全死**、`AE` 全 0、`sel` 恒 −1/31、`alive=yes` | ✅ 反极性精确 |
| ④ 单变量 | 差别只在 WM | 修前件：7 击死 → `kill -TERM` WM → **第 8 击活**（`preMouseDown` 0→32） | ✅ |

**唯一没落到预期档位的是"整趟 `alive=yes`"这一格**（①′/②′/④′），原因是**与修法无关的既有崩溃**（§3.3）——
不是修法"部分有效"：**点击生效的判据（①②③④）全部成立**。

### 3.2 修法的口径是否与 Win32 对齐（可证伪的那一条）

- `ret` 在"点在我方窗口上"时 = **我方客户窗**（§2.1，shim 自证）；
- `ret` 在"链上无本进程窗口"时 = **顶层**（§2.3-③，复刻 ＋ 与 shim 一致的 `ret/depth`）；
- `ret` 在"该点没有 root 直接子窗口"时 = `NULL`（§2.3-⑤）。
三条都与 `win32_core.c:1569-1571` 注释声明的口径一致 ⇒ **口径未被本次修法改动**。

### 3.3 与修法**无关**、但被修法**暴露**出来的既有缺陷（如实报，附原文）

**(A) 点击"真的生效"之后，应用会在某一击上崩掉 —— 用修前件在"点击能落地"的环境里**同样**崩。**
| 腿 | shim | WM | `preMouseDown` | 崩溃点 | 签名 |
|---|---|---|---|---|---|
| `L1`（①′）| 新 | 有 | 245 | `S5a` 点**页签**之后 | 托管异常 **`Stack overflow.`** ＋ core dump |
| `L2`（②′）| 新 | **无** | 245 | 同上 | 同上 |
| `L5`（④′）| 新 | 有 | 245 | 同上 | 同上 |
| **`L8`** | **旧** | **无** | **152** | `S4`（开完 ComboBox 之后的下一击）| **静默** core dump（**无**托管异常行） |
| `L6-otherwin-old` | **旧** | 有 | 0 | 启动后第一次 `[GEO]` 转储附近 | **静默** core dump |
| `L3`（③）| 旧 | 有 | **0** | **不崩**（`alive=yes` 到最后）| — |

⇒ **崩溃跟着「点击是否落地」走，不跟着「哪一件 shim」走**：修前件在无 WM 下点击能落地 ⇒ **也崩**（`L8`，`preMouseDown=152`）；
修前件在有 WM 下点击被吞 ⇒ **不崩**（`L3`）。**所以它不是 `D-G64` 引入的**。
`L1` 的崩溃原文（逐字）：

```
Stack overflow.
   at System.Windows.Controls.Panel.ClearChildren()
   at System.Windows.Controls.Panel.ResetChildren()
   at System.Windows.Controls.Panel.OnItemsChangedInternal(…)
   at System.Windows.Controls.ItemContainerGenerator.OnRefresh()
   at System.Windows.Data.CollectionView.Refresh() … (极深)
   at System.Windows.Interop.HwndMouseInputProvider.ReportInput(…)
   at System.Windows.Interop.HwndMouseInputProvider.FilterMessage(…)
   at HandyControlDemo.App.Main()
timeout: 被监视的命令已核心转储
```
**我没有把机制定死** ⇒ §4 记 `NOINFO(崩溃驱动源未定)`；与 W51B 已登记的"`HC_INPUT_DIAG`＋`[GEO]` 同开时控制台路径可静默 SIGSEGV"
（归 `DumpGeo`/`GeoWalk`，`App.xaml.cs:479-575`）**同族**，但**签名不同**（这里是托管 `Stack overflow.`），**我没有重测"仪器全关"那一格**。

**(B) 并发起两个以上本例时，应用会在**启动**阶段死掉。** `L8` 首跑（当时 `:152` 上还有一趟在跑）逐字：

```
Unhandled exception. System.ComponentModel.Win32Exception (50): No CSI structure available
   at MS.Win32.UnsafeNativeMethods.WaitForMultipleObjectsEx(Int32 nCount, IntPtr[] pHandles, Boolean bWaitAll, Int32 dwMilliseconds, Boolean bAlertable)
   at System.Windows.Threading.DispatcherSynchronizationContext.Wait(…)
```
单跑同一命令**正常**（`L8` 重跑 `STATE_AT_START=12 alive=yes`）⇒ 与并发/资源有关，**不是**修法相关。**建议登记**。

**(C) `[GEO]` 的坐标字段会携带异常名**（36 次，§0.4-(3)）：任何"看见 `item[N]` 就当坐标"的仪器都会点到不存在的点。

---

## §4 边界、`NOINFO` 与我没做到的

| # | 项 | 状态 |
|---|---|---|
| 1 | 修前 `win32_core.c` 源码 sha16 `4e054c88cc3f5fce` | **`NOINFO(不可复核)`**：本机无 `git`；全盘只有修后那一份 `.c`。任务书给的修前 sha16 我**既证实不了也证伪不了**。 |
| 2 | 修前件的 `[WFP_DIAG]` | **`NOINFO(该二进制无此代码)`**：`grep -ac WFP_DIAG` 修前 = **0**、修后 = 2（§2.2）。**不许**读成"修前也是客户窗"。 |
| 3 | 崩溃的**驱动源**（仪器 vs 产品） | **`NOINFO(未定)`**：我确认了它**与修法无关**（`L8` 修前件同样崩），但**没有**做"仪器全关 × 同样五步"那一趟 ⇒ 无法把 `[GEO]`/`HCIN` 仪器与产品分开。**这是本趟最该补的一格。** |
| 4 | 第 ⑤ 步「点页签」的**效果** | **`NOINFO(效果被崩溃掩盖)`**：`L1` 的 `S5a-click-TabItem` 一击**确实落地**（`BTNpress=1 preMouseDown=18`），但随后崩 ⇒ `nsLoaded=0`、页面未变；**不能**据此说"页签点不动"。 |
| 5 | ③c「点弹窗项 ⇒ 选中项变化」 | **部分**：弹窗**关了**（16→17→16、`CB(open=False)`），但 `sel` 停在 `0/9`（我点第 1 项，本来就 0）⇒ **不是**选中项变化的正证。 |
| 6 | `WindowFromPoint` 的**其它**调用方 | **未覆盖**。仓内/上游共 6 处调用：`HwndMouseInputProvider.cs:924`（`FilterMessage` 路径）、`:1305`（`ReportInput`，**本趟走到的就是这条**）、`MouseDevice.cs:2108`、`Wisp/WispLogic.cs:2951`、`Wisp/WispStylusDevice.cs:1541`、UIAutomation 的 `IntWindowFromPoint`（`UIAutomationClient/MS/Win32/UnsafeNativeMethods.cs:166`、`UIAutomationClientSideProviders/…:305`）。**本应用是鼠标应用、无触笔、未跑 UIA 客户端** ⇒ 后四类**没走到**，本次修法对它们的**未验证**。 |
| 7 | 用户真实会话（`:0` gnome/mutter+Xwayland、`:10` xrdp+xfwm4） | **未测**（纪律：不碰用户会话）。`xfwm4` 是**同类**重定父 WM，但 **mutter/Xwayland 是另一个实现** ⇒ 只能"同类推断"，**不是证明**。 |
| 8 | `L6-otherwin-old` 那一趟 | **作废**：它在第一次点击前就静默 core dump（`alive=no`、`state_lines=14`），**不产出判据**；覆盖窗那一支的结论改由 `L9` 的复刻承担。 |
| 9 | 腿链 v1 的 `L3/L4` | **作废**（`rc=2`，`marks.txt` 0 字节，**零读数**），原因 §0.4-(2)；有效读数来自重跑的 `L3/L4`。 |
| 10 | `own_top` 一栏 | 读 **shim 本体**的 `[WFP_DIAG]`，**不读**我的复刻（我的复刻 `own_top` 判据过宽，§2.3）。 |

**纪律自查**：零 `pkill -f`（止损全部按 PID：`KILLWM by-pid`、清理 `kill -TERM <pid>`）；零仓内写入（本报告是唯一新增件）；
未跑 `verify-all.sh` / `close-work*.sh` / `integration-wave.sh`；收工 `Xvfb`/`dotnet`/`xmessage` **全空**，只剩用户自己的 `xfwm4`(1751373)。

---

## §5 复算命令逐条

```bash
# 0) 件 sha16（五件；前两件是"换的那一件"的两个版本）
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
sha256sum $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16                 # 867d96e7cb0cba36
sha256sum /home/links-dev/w54a/old/libwpfwin32.so | cut -c1-16                       # abf6879c027c5e73
sha256sum $HOME/w54a/app/{wpfgfx_cor3.so,PresentationCore.dll,PresentationFramework.dll,WindowsBase.dll} | cut -c1-16

# 1) 修后件里有没有那段诊断代码（正控/负控）
grep -ac WFP_DIAG $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so                      # 2
grep -ac WFP_DIAG /home/links-dev/w54a/old/libwpfwin32.so                            # 0

# 2) 四条腿（每条自证 shim sha；输出在 $HOME/w54a/logs/<tag>/）
bash $HOME/w54a/bin/legrun_noTab.sh L11-postfix-wm-notab   :152 wm   new   # ①
bash $HOME/w54a/bin/legrun_noTab.sh L12-postfix-nowm-notab :151 nowm new   # ②
bash $HOME/w54a/bin/legrun.sh      L3-prefix-wm            :152 wm   old   # ③
bash $HOME/w54a/bin/legrun.sh      L4-prefix-wm-killwm     :152 wm   old killwm   # ④

# 3) [WFP_DIAG] 的 top/own_top/ret/depth
grep -a '^\[WFP_DIAG\]' $HOME/w54a/logs/L11-postfix-wm-notab/app.log | sort -u
grep -a '^\[WFP_DIAG\]' $HOME/w54a/logs/L11-postfix-wm-notab/app.log | sed 's/pt=[0-9-]*,[0-9-]* //' | sort | uniq -c
grep -ac 'WFP_DIAG' $HOME/w54a/logs/L3-prefix-wm/app.log                              # 0（该件无此代码）

# 4) 反极性与单变量
grep -a 'STEP\|KILLWM\|FINAL\|TOTAL' $HOME/w54a/logs/L3-prefix-wm/marks.txt
grep -a 'STEP\|KILLWM\|FINAL\|TOTAL' $HOME/w54a/logs/L4-prefix-wm-killwm/marks.txt

# 5) 「同一批 X 事件、两种结果」的 X 层原文（三腿坐标逐条相同）
for t in L11-postfix-wm-notab L3-prefix-wm L8-prefix-nowm; do grep -a 'BTN type=Press' $HOME/w54a/logs/$t/app.log | head -2; done

# 6) 补腿：机制与分支覆盖
bash $HOME/w54a/bin/l9_probe.sh :152 && grep -a 'WFP2\|SHIM ' $HOME/w54a/logs/L9-wfp-branch/marks.txt
grep -a 'HIT\|COVER' $HOME/w54a/logs/L6-otherwin-new/marks.txt

# 7) 既有崩溃（与修法无关）
grep -an 'Stack overflow' $HOME/w54a/logs/L1-postfix-wm/app.log
grep -an 'Win32Exception (50)' $HOME/w54a/logs/L8-prefix-nowm/app.log
grep -ac 'scr=InvalidOperationException' $HOME/w54a/logs/L1-postfix-wm/app.log        # 36

# 8) 本报告自身 sha16（口径 = 去掉本行）
cd $R && head -n -1 build/MilBridge/W54A-report.md | sha256sum | cut -c1-16
```

**W54A-report.md sha16（口径 = 去掉本行）= `2f3c1df6d5ad9b15`**

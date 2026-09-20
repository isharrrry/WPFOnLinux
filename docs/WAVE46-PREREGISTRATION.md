# 波 `#46` —— **抓取伪焦点事件**把 WPF 键盘焦点清空 ⇒ `ComboBox` 下拉"弹出即被关掉"（`D-G50` 产品修复）

> **本波性质**：**产品波**。改动落在 `src/WpfGfx.Linux.Native/src/win32_x11.c` ⇒ 翻 **`win32shim`** 位
> ⇒ 走完整收尾（整波重建 → 重取臂 → 重钉 → 闸门 ×2 → `verify-all` → 重冻 → 冻后 ×2）。
>
> **时机如实记**：本文件落仓**先于**产品改动；改动前没有任何 `src/**` 修改。仪器（hc 应用侧 env 门控诊断）
> 在仓外（`/home/links-dev/hc-linux`），**不进仓、不参与指纹**。

---

## §1 `D-G50` 的根因（一条链，每节都有读数）

`D-G50`：真实第三方应用（仓外 hc demo）`NativeComboBoxDemo` 页点"组合框"⇒ 下拉不开。前几波把嫌疑从
"命中测试/透明填充"（`D-G52`，**已被本波推翻**）一路收窄到事件链。本轮用三件不同层面的仪器把链条打通：

| 节 | 仪器 | 读数（原样） | 结论 |
|---|---|---|---|
| ① 命令链 | hc 应用内类处理器（`HC_INPUT_DIAG=1`） | `TBlkMouseDown cs=2 chk=False ges=LeftClick b=Active/RS:TemplatedParent` ⇒ `EV DropDownOpened open=True` ⇒ `EV Executed … sender=ToggleBlock handled=True` ⇒ 同一击内 `EV DropDownClosed open=False` | **不是"打不开"**：HandyControl 覆盖层收到了 MouseDown、命令送达、`IsDropDownOpen` **真的变成过 `True`**，随后被关掉 |
| ② 关闭者 | 同上，`DropDownClosed` 上打调用栈 | `ComboBox.OnDropDownClosed` ← `ComboBox.OnPopupClosed` ← `Popup.OnClosed` ← `Popup.DestroyWindow` ← `Popup.<HideWindow>b__130_0` | 是 **Popup 自己**拆窗，ComboBox 跟随 |
| ③ 触发条件 | `IsKeyboardFocusWithin` 焦点事件类处理器 | `GOTFOCUS ComboBox` ← `ListBoxItem`；`LOSTFOCUS ComboBox` → `ComboBoxItem`；`LOSTFOCUS ComboBoxItem` → **`null`**；`GOTFOCUS` → `PopupRoot` | 键盘焦点在弹窗打开途中被**清成 null** |
| ④ X 层 | shim 自带的 `WPF_LINUX_KEY_DIAG=1` | `SETFOCUS → XSetInputFocus(0x200008)`（弹窗窗口）→ `SETFOCUS → XSetInputFocus(0x200004)` → `FOCUSOUT 0x200004 mode=0 detail=3(NotifyUngrab)`＋`FOCUSIN 0x200008 detail=3`＋`FOCUSOUT 0x200008 detail=3`＋`FOCUSIN 0x200004 detail=5(NotifyPointer)` | 这些 FocusIn/FocusOut **是抓取(grab)生效/失效的伪事件**（`mode=NotifyGrab/NotifyUngrab`），真实输入焦点并未改变 |

**判定点（产品代码）**：`src/WpfGfx.Linux.Native/src/win32_x11.c` 的 `case FocusIn:` / `case FocusOut:`
**无条件**把每个 X 焦点事件翻成 `WM_SETFOCUS` / `WM_KILLFOCUS`。伪事件被翻译后：
`WM_KILLFOCUS` ⇒ WPF 键盘焦点置 `null` ⇒

```csharp
// PresentationFramework .../ComboBox.cs:1109 OnIsKeyboardFocusWithinChanged
if (IsDropDownOpen && !IsKeyboardFocusWithin) { ... if (currentFocus == null || ...) Close(); }
```

⇒ `Close()`。Win32 上不存在"抓取伪焦点"这类消息，所以这条翻译是**我方移植引入的语义偏差**。

## §2 修法（最小、贴着 Win32 语义）

只翻译**真实**焦点变化：`mode ∈ {NotifyGrab, NotifyUngrab, NotifyWhileGrabbed}` 的 FocusIn/FocusOut
**不产生消息**（真实变化若同时发生，X 另发一条 `mode=NotifyNormal` 的事件，不会丢）。保留
`detail=NotifyPointer` 那类"焦点为 PointerRoot 时指针进入"的路径（键盘输入靠它，见 `wpf_x11_set_input_focus`
上面的既有注释），也保留 `g_focus_window` 记账。

## §3 判据（**落地前写死**，改完逐条读）

- **P1**（主判据）同一次真实节奏点击内，`EV DropDownClosed` **不再出现**；`ComboBox.IsDropDownOpen` 在按住期间保持 `True`。
- **P2** 弹窗的 X 窗口在按住期间**存活**（`xwininfo -root -tree` 多出一个子窗口；此前按住期间恒为 7 个）。
- **P3** 点击后画面出现下拉列表：`compare -metric AE` 相对点击前**远大于**改前的 `7418`。
- **P4** 点击后 `ComboBox` 仍持有键盘焦点（`kbdFocus=True`），且**焦点不再出现 `null` 中转**。
- **P5** 键盘腿：组合框聚焦后 `alt+Down` 能开（`AE>0` 且出现 `DropDownOpened`）。
- **P6** 九位指纹：预测 **只有 `win32shim` 变**；`inputs_fp` **不变**（`src/WpfGfx.Linux.Native/src/*.c`
  不在 `close-wave.sh:fp_inputs()` 覆盖内 —— 这条本身就是一次可复算的预测）。
- **反证条件**：若改后同一击内仍出现 `DropDownClosed`（或 P1–P5 任一不成立）⇒ **根因判断错**，
  `KNOWN-DEFECTS.md` 如实记反证，撤回本波的因果结论（不硬凑）。

## §4 与既有可能冲突的地方（先声明）

- `D-G49`（鼠标 `ButtonState` 恒 `Released`）修的是**按键状态**读取，与焦点翻译无关 ⇒ 不预期回归；
  回归面由 `verify-all` ＋ 闸门 ×2 覆盖。
- 仪器波 `#45` 的第 ⑫ 块判据 `nativecombo:!7C3AED` 是"**无人点击时**测试色不应出现"，
  与本波"点击后应出现"不矛盾；本波若需要点击后的像素判据，另立。

---

## §5 记录（如实：预测被部分反证，补丁**未落仓**）

- **P1**：✅ 改后同一次点击内下拉**不再被关**（`CB.MouseUp … open=True`、`afterMouseDown chk=True`、
  四条 X 回送全被吃掉 `=6`、焦点不再出现 `null` 中转、`Exception` 行 8→4）。
- **P2**：❌ **反证** —— 按住期间 X 层根子窗口**恒为 7 个**，弹窗窗口始终不存在（与改前相同）。
- **P3**：❌ **反证** —— `post.png` 相对 `pre.png` 只有边框/焦点差异（`AE=7398`，改前 `7418`），**没有列表像素**。
- **P4**：✅ 焦点不再被清成 `null`（`kbdFocus` 仍在失焦后为 `False`，但 `null` 中转消失）。
- **P5**：❌ 键盘腿仍 `AE=0`（组合框未持有键盘焦点时 `alt+Down` 无对象，这条判据本身设得不好）。
- **P6**：✅ 位指纹预测正确方向 —— `win32shim` 变过（`11f81eb9dfc60a12` → `f12f850995525d0f` → …），
  且 `inputs_fp` 未动（`src/WpfGfx.Linux.Native/src/*.c` 不在 `fp_inputs()` 覆盖内）。

**为什么没落仓**：`P2/P3` 反证出一条**独立缺陷**（`D-G53`：`IsDropDownOpen=true` 时弹窗不建窗不出画）⇒
只落焦点补丁只能"让下拉开着但看不见"，达不到"必做项完成"；且本波预算不足以走完整收尾（整波 → 重取臂 →
重钉 → 闸门 ×2 → `verify-all` → 重冻 → 冻后 ×2）。⇒ **还原 `win32_x11.c` 到冻结字节**
（`sha16=11f81eb9dfc60a12`，`BASELINESHA=PASS live=ff3990dafa582831`），
把补丁与两处证据（焦点链、`D-G53`）留给下一波**一并落地**。

## §6 `D-G53` 的追加读数（本轮到此，下一步的仪已选定）

- 关掉尺寸过滤、按 300 ms 采**完整** `xwininfo -root -tree`：按住期间（含焦点补丁版）**始终只有 7 个窗口**
  （`0x200001`–`0x200007`），**弹窗窗口从不出现**。
- `WPF_LINUX_WIN_DIAG=1` 全程**零窗口诊断行**，而 `EV Popup.Opened open=True child=Decorator` 已触发
  ⇒ 断言：**弹窗在 WPF 侧"打开了"，但没走到建窗/映射**（不是"建了看不见"）。
- 下一件仪器（已选定、未跑）：`src/WpfGfx.Linux.Native/tools/patch-shared-hwndwrapper-diag.py` 是现成的
  `HwndWrapper` 窗口流插桩 ⇒ 在它上面把 `CreateWindowEx`/`ShowWindow` 两条腿都打出来，
  判据：`Popup.IsOpen=true` 之后**必须**出现一次 `CreateWindowEx`（弹窗类）＋一次 `ShowWindow(map=1)`；
  哪条腿缺，缺口就在哪条腿（`Popup.CreateWindow` 的 managed 侧 / shim 的 `CreateWindowEx` 翻译）。

## §7 `D-G53` 是不是 hc 特有？——**不是**（仓内第 ⑫ 块同形）

- 仓内 `nativecombo` 块（标准 `ComboBox`，冻结栈）同样给出成对的 `EVT nativecombo.DropDownOpened` / `DropDownClosed`
  （驱动 `$HOME/w45-nativecombo.sh`，本次输出 `$HOME/w46-nativecombo-a/app.log`：`DropDownOpened/`Closed` 交替
  出现，另夹 `KeyDown=Escape`）⇒ **"开了又被关"在仓内也复现**，与 hc 同形。
- 该驱动只存 `app.log`（不存帧），但门禁 runner 的 `EXPECT "nativecombo:!7C3AED"`（下拉项测试色）一直通过
  ⇒ 测试色**从未出现在任何帧里**；结合"`DropDownOpened` 确实触发"，与"下拉列表从不渲染"**一致**
  （注意：这条是**吻合**，不是证明 —— 要成证明得另立"点击后应出现 `7C3AED`"的正向判据）。
- ⇒ 结论：`D-G53` 是**全局**（我们端口的 Popup 建窗/呈现腿），不是 hc 特有 ⇒ 修它可以用**仓内**载体复算，
  不必依赖仓外 hc ⇒ 与 `§6` 选定的 `patch-shared-hwndwrapper-diag.py` 探针配套，判据仍是
  "`Popup.IsOpen=true` 后必须出现弹窗类 `CreateWindowEx` ＋ `ShowWindow(map=1)`"。

## §8 **更正 `D-G53`（第三次自我更正）**：弹窗窗口一切正常，"不建窗"是我读错终值

`WPF_LINUX_CREATE_DIAG=1` 把建窗/显示两条腿都打出来后，同一个弹窗窗口（`xid=0x200008`）的**完整腿迹**是：

```
CREATE 0x200008 style=0x86000000 ex=0x8080088 xywh=0,0,1x1
SetWindowPos flags=0x16      SetWindowPos flags=0x15
ShowWindow a=8 (SW_SHOWNA)            ← WPF 用 SW_SHOWNA 显示弹窗（不激活）
MAP 0x200008 xywh=559,356,413x274     ← **真的 map 了**，几何也对（下拉列表的真实尺寸）
ShowWindow a=0 (SW_HIDE)              ← 随即隐藏
UNMAP 0x200008 … DESTROY 0x200008
```

- ⇒ **`D-G53` 撤回**（降级为 `D-G50` 的同一条链）：没有"弹窗不建窗/不出画"这个独立缺陷；
  `Build → SetWindowPos → ShowWindow(SW_SHOWNA) → map → 几毫秒后 SW_HIDE + Destroy` 全在。
- 我此前两条读数的错在哪：① `mapped=0` 是**销毁后的终值**（不是"从未 map"）；② 每 300 ms 的
  `xwininfo` 采样**分辨力不足**（窗口只活几毫秒）⇒ "恒 7 个窗口"不能推出"没建窗"。
- ⇒ 必做项回到**一条**缺陷（`D-G50` 焦点链）＋其补丁（§5 的回送补丁）。修好后必须复采：
  判据 = `ShowWindow(SW_SHOWNA)` 之后**不得**紧跟 `SW_HIDE`，且 `post.png` 出现列表像素。
- 纪律教训（写进本波）：**看"是否发生过"要用事件日志，不要用低频轮询 + 终值字段**。

## §9 产品修复已落仓（**本波在飞**）：焦点回送 ⇒ 下拉在点击期间立得住；只剩"重放按键"

- **落仓内容**（`win32shim` 位）：①焦点回送的识别与吃掉（§5 的补丁，正式版）；②建窗/映射腿与显示腿的
  **env 门控有界诊断**（`WPF_LINUX_CREATE_DIAG=1`，≤40 行/进程，只打印）—— 留仓是为了"修好后的判据在冻结之后仍可复算"。
  `sha16 = d6c6e6bb9e534387`（改前冻结值 `11f81eb9dfc60a12`）。
- **已验证的读数（改后）**：`TBlkMouseDown cs=2` → `EV DropDownOpened open=True` → **`CB.MouseUp … open=True`**
  → **`dump t16 Combo( open=True ovChk=True …)`**（此前从未出现过 `open=True` 的快照）⇒ **下拉在整次点击期间立住了**。
- **弹窗三件事全部正常**（用**程序化打开**做干净判定，避开点击路径）：
  `HC_DROP_OPEN_AT=25` ⇒ `FORCE-OPEN open=True overlayChk=True`；`xwininfo` 里 `0x200008 413x274+559+356`；
  **弹窗区域像素 AE=4187**（全屏 11630）⇒ **建窗 ✓ 映射 ✓ 出画 ✓**。⇒ `D-G53` 彻底撤回。
- **仍差一步：同一次点击里的第二次 `Execute`**（X 在抓取生效时把"已按住"的按键**重放**一次，
  落到捕获元素上 ⇒ `ToggleBlock.OnMouseDown` 再翻转一次 ⇒ `IsDropDownOpen=false` ⇒ 关）。
  三个判据**都被反证**（如实记）：①窗口不同（抓取就落在本窗口，判不出）｜②X 时间戳相同（重放时间戳不同）
  ｜③`ButtonPress.state` 含本键掩码（**真按下也被丢**：`重放丢弃=4`、`Opened=0` ⇒ 会按坏正常点击，已撤）。
  ⇒ 三个实验均已从树里撤掉，只保留已验证有益的焦点修复。
- **下一步（唯一必做项）**：找到可靠的重放签名（候选：本 shim 自己知道"刚激活过抓取且按键仍按下"⇒
  用**自己的抓取状态 + 首条 press 的送达记录**做窗口；或用 `XQueryPointer` 的实时掩码对照事件时间戳），
  修好后判据：同一次点击内 `Executed` 路由**只有 1 条**、`DropDownClosed` **不出现**、弹窗区域 `AE>0`。

## §10 **必做项达成**（E3 组合框下拉：真实点击下打开且可见）

**关键更正（第四次自我更正，最值钱的一条）**：`D-G50` 的"第二次 `Execute`（把开关翻回去）"是**我自己的仪器**造成的 ——
hc 应用侧探针里那句 `ControlCommands.Toggle.Execute(null, tb)`（`manualExecute`）在**每次点击后**都会再翻一次。
把探针用 `HC_PROBE=1` 门控掉之后，同一个真实节奏点击的读数是：

| 判据 | 读数（无仪器干扰） | 说明 |
|---|---|---|
| 同一次点击内的 `Executed` 路由 | **1 条** | 一次点击只翻一次（此前 2 条＝点击 + 我的探针） |
| `Combo( open=True …)` 的 1 Hz 快照 | **5 次** | 下拉**持续开着**（不是"开完立刻关"） |
| 全屏 `compare -metric AE`（pre→post） | **11630** | 与"程序化打开"那次（`HC_DROP_OPEN_AT=25`，AE=**11630**）**完全一致** ⇒ 下拉**真的出画** |
| `DropDownOpened/Closed` | 2 / 2 | 腿A 点击打开；腿B 点导航（**点别处**）关闭＝**正常 WPF 语义** ✓ |
| 炮口 `鼠标重放` 去重实验 | 已全部撤除 | 三个判据都被反证；**产品侧不需要它** |

⇒ **`D-G50` 的唯一产品缺口就是焦点回送**（§9 已落仓并验证）。HC 组合框下拉：**真实点击 → 打开 → 可见 → 点别处才关**。
⇒ 本波（`#46`）现在可以收尾：整波重建 → 重取臂 → 重钉 → 闸门 ×2 → `verify-all` → 重冻 → 冻后 ×2。

## §11 `D-G54`（新登记）：必做项的最后一块 —— `WS_EX_LAYERED` 呈现腿不存在

E3（组合框下拉）**在"打开/关闭/焦点"这半条链上已经通了**（§10：一次点击一次翻转、`open=True` 快照 5 次、
点别处才关）。剩下的是**内容呈现**：

- 读数：程序化打开与真实点击两种情形下，弹窗下半区（避开组合框那一行）**像素逐位相同**，
  `色数 66 → 1`（那一个颜色 = 建窗时给的 X 背景色白）⇒ **内容零渲染**。
- 判定点：`HwndSource.Linux.cs:652` 给 `AllowsTransparency` 窗口加 `WS_EX_LAYERED`；
  shim 的 `UpdateLayeredWindow`（`win32_misc.c:525`）是失败桩且**没有回退**；
  上游 `WpfGfx` 见 `PresentUsingUpdateLayeredWindow` 就把呈现交给它 ⇒ 空操作。
- 修法 A（最小）：那处**不加** `WS_EX_LAYERED` ⇒ 走正常呈现腿、以不透明方式出画；
  代价（弹窗 alpha/阴影、`Window.Opacity`）作为**已知限制**登记。
- 修好后的判据：区域色数 > 1 ＋ 区域 `AE` ≫ 3779 ＋ 肉眼见列表。

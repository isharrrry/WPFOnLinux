# P1-W108 只读侦察＋判据草案：`E3`（组合框下拉）抓取重放去重的可行签名

> **只读**：未构建／未跑腿／未占显示位／未 `git add/commit/push`；写入面**仅本件**；**未碰** `src/WpfGfx.Linux.Native/**`（`t198` 在飞）与任何 `.cs`／`tools/**`。行号一律整行取；`grep -c` 均带射程。

---

## §0 身份与在飞件

- 载体：`build/MilBridge/P1-e3-replay-criteria.md`（**新建**，`temp+rename`）。
- 读取时刻：**2026-09-29 23:02–23:08**；HEAD＝`14f5421`。
- ⚠️ `src/WpfGfx.Linux.Native/src/win32_pts.c` 由 `t198` 在改，**本件未读未碰**（本件靶心在**输入层**，与 PTS 面无交集）。

---

## §1 历史留档（现取原文，**不照抄结论**）

`docs/WAVE46-PREREGISTRATION.md`（**171 行**）：
```
:1    # 波 `#46` —— **抓取伪焦点事件**把 WPF 键盘焦点清空 ⇒ `ComboBox` 下拉"弹出即被关掉"（`D-G50` 产品修复）
:21   | ④ X 层 | shim 自带的 `WPF_LINUX_KEY_DIAG=1` | `SETFOCUS → XSetInputFocus(0x200008)`（弹窗窗口）→ … ＋`FOCUSIN 0x200004 detail=5(NotifyPointer)` | 这些 FocusIn/FocusOut **是抓取(grab)生效/失效的伪事件**（`mode=NotifyGrab/NotifyUngrab`），真实输入焦点并未改变 |
:32   ⇒ `Close()`。Win32 上不存在"抓取伪焦点"这类消息，所以这条翻译是**我方移植引入的语义偏差**。
:36   只翻译**真实**焦点变化：`mode ∈ {NotifyGrab, NotifyUngrab, NotifyWhileGrabbed}` 的 FocusIn/FocusOut
:123  ## §9 产品修复已落仓（**本波在飞**）：焦点回送 ⇒ 下拉在点击期间立得住；只剩"重放按键"
:133  - **仍差一步：同一次点击里的第二次 `Execute`**（X 在抓取生效时把"已按住"的按键**重放**一次，
:135    三个判据**都被反证**（如实记）：①窗口不同（抓取就落在本窗口，判不出）｜②X 时间戳相同（重放时间戳不同）
:136    ｜③`ButtonPress.state` 含本键掩码（**真按下也被丢**：`重放丢弃=4`、`Opened=0` ⇒ 会按坏正常点击，已撤）。
:138  - **下一步（唯一必做项）**：找到可靠的重放签名（候选：本 shim 自己知道"刚激活过抓取且按键仍按下"⇒
:139    用**自己的抓取状态 + 首条 press 的送达记录**做窗口；或用 `XQueryPointer` 的实时掩码对照事件时间戳），
```
⇒ 在册事实（**引自该件，本席未独立复算**）：**三条候选判据已被反证并撤**（`:135`），其中第 ③ 条**属回归**（会丢真点击：`重放丢弃=4`、`Opened=0`）。
`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（3890 行）本席**只做了关键词扫描**（`grep -n '重放|去重|grab|抓取|Opened=0|E3'`，命中多为其它主题）⇒ **未定位到同一条 E3 条目**（`NOINFO-KNOWN-DEFECTS-E3-ENTRY`，**只报扫描面不报"无"**）。

---

## §2 Q1：现成的可判据状态 —— **本席的射程与结论**

| 探针 | 射程（现取） | 命中 |
|---|---|---|
| `XGrabPointer`／`XUngrabPointer`／`grab_active`／`pointer_grab`／`send_event`／`QueryPointer` | `build/shims`＋`build/PresentationCore.Linux`＋`build/PresentationFramework.Linux`＋`build/WindowsBase.Linux` 的 **`.cs`**（排除 `dll`/`pdb`） | **全部 0** ⇒ **托管侧 shim 面没有抓取态字段、也没有事件来源标记**（**射程＝这 4 个目录**） |
| 同上（整仓源码面） | `src/`＋`build/` 的 `*.c`/`*.h`/`*.cs` | `XGrabPointer` **47 文件**／`XUngrabPointer` **6**／`send_event` **54**／`XQueryPointer` **47** ⇒ ⚠️ **口径未细分**（大概率含 X 头文件/生成目录）⇒ 具名 **`NOINFO-GRAB-COUNT-CALIBER`**，**不得**读成"本侧自己有 47 处抓取状态" |
| **输入层定位** | `grep -rl 'WPF_LINUX_KEY_DIAG'`（`*.c`/`*.cs`/`*.h`） | **唯一命中**：`src/WpfGfx.Linux.Native/src/win32_x11.c` ⇒ **这就是 X 输入层（转译 Focus/键鼠事件处）** |

⇒ **判词**：**「本窗口是否处于 X 抓取态」与「首条 press 的送达记录」今天都不在托管面**；**唯一可能在册的位置是 `src/WpfGfx.Linux.Native/src/win32_x11.c`，而本席未逐行核它**（`t198` 在飞 + 本件预算）⇒ 具名 **`NOINFO-X11-GRAB-FIELD`**，并把下一件的**具体命令**给出（**只写不改**）：
```
grep -n 'Grab\|grab\|QueryPointer\|send_event\|ButtonPress\|WPF_LINUX_KEY_DIAG' src/WpfGfx.Linux.Native/src/win32_x11.c
```

---

## §3 Q2：可行签名候选（逐条可证伪性）

| # | 候选签名 | 能区分"重放"与"真点击"？ | 反例（误判场景） | 代价 / 要改 |
|---|---|---|---|---|
| ① | **shim 自持抓取态 ＋ 首条 press 送达记录**（历史首选，`:138-139`） | ✅ **能**（在"同一次抓取会话内"这个窗口里） | ⚠️ **必须有"按用途区分"的抓取态**：本仓另有 **X 指针抓取**用于拖动（`KNOWN-DEFECTS.md:2309` 现取：`_NET_WM_MOVERESIZE` 无效 ⇒ 改"自己按 motion 驱动…＋ X 指针抓取"）⇒ 若把"全局有抓取"当签名 ⇒ **拖动中的真点击会被误丢** | 中：需在 `win32_x11.c` 记录"**为谁/为何**抓取"＋**首条 press 已送达**标记；暴露为只读口 |
| ② | X **事件序列号**／**`send_event` 标志** | ❌ **`send_event` 不行**：抓取重放是**服务器在 ungrab/replay 时生成的正常设备事件**（非 `XSendEvent`）⇒ 该位**不置**；序列号单独用**不可判**（真点击也有自己的序号） | 若拿 `send_event` 当签名 ⇒ **恒不命中**（假签名，必然漏掉重放） | 低（但**无效**） |
| ③′ | **同 button ＋ 中间无 release ＋ 序号/时间相邻**（**与已被反证的"时间戳相同"不同**：用**序关系**而非**相等**，且**必须以「同 button 且无中间 release」为主条件**） | ✅ **大概率能**（X 不会在同 button 未 release 时再发一条真 press；重放恰是"同 button、无 release、紧邻"） | ⚠️ **多键同按（chord）**：press A 后 press B 也"无中间 release"，但 **button 不同** ⇒ 加"同 button"约束即可排除；⚠️ **事件积压**下"相邻"需以**序号**为准（不靠墙钟） | 低–中：只需**序号＋button＋无 release** 三项状态（不必新增用途区分） |
| ④ | `XQueryPointer` 实时掩码对照事件时间戳（历史候选，`:139`） | ⚠️ **弱**：掩码是**当前**值，**不是事件发生时刻**的值 | **事件积压/队列延迟**时：掩码已抬起而事件仍待处理 ⇒ **误判**（`XQueryPointer` 也**随抓取变化**，需先读 `win32_x11.c` 现状） | 低，但**判别力不足** |

⇒ **本席排序：③′ ≥ ① > ④ ≫ ②**。理由：③′ 只需**已在事件里的字段**（`button`／`sequence`／`state` 的**存在性**演化：是否见过同 button 的 release）＋**一条 shim 自持的"上一 press 是否已 release"状态**，**不需要**区分抓取用途；① 更强但要处理"本仓另有拖动抓取"的干扰；④ 有已知误判面；② 无效。
⚠️ **纪律**：①②③ 的**全部**都必须与"真点击不许被丢"**成对**验证（§4 反腿），否则重演 `:135-136` 的回归。

---

## §4 Q3：今天有没有「本次点击里 `Executed` 路由了几次」的现成读数？——**本席判：没有**

- 射程（现取）：`grep -rn 'Executed' build/shims build/PresentationCore.Linux build/PresentationFramework.Linux build/WindowsBase.Linux --include=*.cs` ⇒ 命中**全部是 `RoutedCommand` 处理器注册**（例：`build/PresentationFramework.Linux/Window.Linux.cs:3565 binding.Executed += new ExecutedRoutedEventHandler(OnDialogCommand);`、`TextEditorTyping.Linux.cs:522-523 var onEnterBreak = new ExecutedRoutedEventHandler(OnEnterBreak);`）⇒ **无**"路由次数"类读数。
- **最小形态（只写方案，不改）**：在**重放会被误当成点击**的那一层计数 —— 二选一：**(a)** 托管侧在 `ToggleBlock.OnMouseDown` 的**入口**（本仓补丁文件面）打**无条件**一行 `[E3-MSGD] click=… n_exec=<本次点击内该 handler 被调次数>`；**(b)** 输入层 `win32_x11.c` 在**投递 ButtonPress 时**打 `[X11-PRESS] seq=… button=… state=0x… replay_guess=…`。
  ⚠️ **必须遵守 `t196` 候选条款「读数类打印行禁静默阈值」**：**无条件打印**；取不到就打**具名缺省行**（把"没取到"与"没发生"分开）。

---

## §5 Q4：判据草案（给实现者直接用）

- **objective**：在**同一次点击**内，X 的**抓取重放** press **不得**产生第二次 `Execute`（`ToggleBlock` 只翻转一次），而**真点击**的开关行为**必须不变**。
- **acceptance（五条合取）**：① 组合框**一次点击后 `IsDropDownOpen` 由假变真且保持**（`Opened=1`）；② **重放被忽略**：本次点击内相应 handler 的调用次数 **= 1**（读数须为**无条件打印**的那一行现取）；③ **成对反腿不许丢真点击**：连续 N 次**真点击**（开→关→开…）全部生效，`重放丢弃` **恰好 = 重放的实际条数**、且**不误伤真 press**（即"丢弃集合 ⊆ 重放集合"须可验证）；④ 反腿②（**拖动抓取**场景）不得被误丢：拖动过程中产生的 press 仍按原语义处理；⑤ ≥2 独立样本同判 ＋ 纪律三十三格。
- **verify**：`<leg> >out 2>err; echo $?`（**不许从管道尾巴取 `rc`**）；`grep -c` 出**具名行**计数；**同配置两样本**逐格比对。
- **inScope**：实现者可在 `src/WpfGfx.Linux.Native/src/win32_x11.c`（输入层）与**本仓补丁文件面**新增**只读打印与去重判定**。
- **outOfScope**：`upstream/**`；改动"焦点伪事件"既有修复（`WAVE46` `:36` 口径）；**把"真点击丢弃"作为代价换取"下拉不被关"**（`t135-136` 的回归路径）。
- **反腿（至少一对，写死）**：**(a) 真点击仍须正常开合**（连续开→关→开… 全部生效）；**(b) 重放必须被忽略**（同一次点击内 handler 调用次数 = 1）。
- **粒度**：**单次点击**（不得外推到"整轮点击序列"或"整个腿"）。

---

## §6 Q5：判词与资源关系

- **本波可行性判词：`NOINFO`（本席不能判"能不能"）**——因为**决定性的在册位置（`win32_x11.c` 的抓取态与 press 送达记录）本席未逐行核**（`NOINFO-X11-GRAB-FIELD`），且 `grep` 的整仓口径未细分（`NOINFO-GRAB-COUNT-CALIBER`）。**但方法面已收敛**：**③′（同 button＋无中间 release＋序号相邻）** 是最可能站住、且**代价最低**的签名；`send_event` 一路**已证无效**。
- **具名前置（若走 ① 或 ③′）**：**`PRECOND-E3-NO-CROSS-GRAB-USER`** —— 必须先把"本仓另有**拖动用的 X 指针抓取**"（`KNOWN-DEFECTS.md:2309`）与"下拉捕获抓取"**分离**（否则签名会误伤拖动中的真点击）。
- **最小可辩护形态**：`shim 自持的"本次抓取的用途标识" ＋ "首条 press 已送达" ＋ "同 button 无中间 release"` 三项**合取**，并把**丢弃集合 ⊆ 重放集合**做成**机器可验**（这是与 `:135-136` 回归的唯一分界）。
- **与当前 P1 波（PTS 排版链）的资源关系（只给判断依据，不替队长排期）**：
  - **写域不重叠**：`E3` 在**输入层** `src/WpfGfx.Linux.Native/src/win32_x11.c` ＋托管补丁面；`P1` 在 `win32_pts.c`（`t198` 在改）＋ PTS 托管面 ⇒ **技术上可并行**，但**"一次一个写者"仍逐件适用**（尤其 `src/WpfGfx.Linux.Native/**` 文件级：**`win32_x11.c` 与 `win32_pts.c` 是不同件**，可各由一人持有）。
  - **收益面不同**：`E3` 直接改善**用户可见的 MVP 行为**（下拉可用）；`P1` 打的是"**3 条未绿 `[MVP]` 的真因**"（排版链）。
  - ⇒ **判断依据给队长**：若 MVP 验收看"**这条交互是否可用**"，`E3` 的收益更直接；若看"**未绿项的真因是否推进**"，`P1` 更贴题。两件**互不为前置**（本席未发现依赖关系）。

---

## §7 纪律与验收

- 🔴 **`P9`**：不把"托管面 0 命中"推广成"没有抓取态" —— **已定位输入层在 `win32_x11.c` 并如实标"未核"**。
- 🔴 **`P10`**：每条否定附射程（托管 4 目录 `.cs`；整仓口径未细分已具名；`KNOWN-DEFECTS` 扫描面已报并**不报"无"**）。
- 🔴 **恒真断言族**：本件读数全来自**读取**；凡"没有读数"处均标 `NOINFO`，**不写成 0**。
- **验收**：新件、`mode 644`、首记号 `# P1-W108 `、末行自证并当场复算 MATCH、`temp+rename`。

---

**判词（本席）**：① **历史条目已现取**（`docs/WAVE46-PREREGISTRATION.md:1/21/32/36/123/133/135/138-139`）：三条候选判据**已被反证并撤**，其中"`state` 含掩码"**属回归**（会丢真点击）；`KNOWN-DEFECTS` 里**未定位到同条 E3 条目**（只报扫描面）。② **可判据状态**：托管 4 目录 `.cs` 面 **0 命中**（射程已给），**输入层＝`src/WpfGfx.Linux.Native/src/win32_x11.c`**（由 `WPF_LINUX_KEY_DIAG` 唯一定位）但**本席未逐行核**（`NOINFO-X11-GRAB-FIELD`）；整仓 grab 计数口径未细分（`NOINFO-GRAB-COUNT-CALIBER`）。③ **签名排序：③′（同 button ＋ 无中间 release ＋ 序号相邻）≥ ①（抓取态＋首条 press 送达记录）> ④（实时掩码）≫ ②（`send_event` 无效）**；④ **今天没有"路由次数"读数**（`Executed` 命中全是 RoutedCommand 注册），最小加读数形态已给（**无条件打印**，遵 `t196` 条款）。⑤ **判词＝`NOINFO`**（决定性位置未核）＋具名前置 **`PRECOND-E3-NO-CROSS-GRAB-USER`**（必须与拖动用的指针抓取分离）；⑥ **与 P1 的关系**：写域不重叠、互不为前置，**收益面不同**，判断依据已给、**不替队长排期**。
`P1-e3-replay-criteria 自证（口径＝末行之前的全文：`head -n -1 <本件> | sha256sum | cut -c1-16`）＝ abc84baa197b1e78（末行＝本行）`

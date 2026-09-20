# 波 `#44` 预登记 —— 修 `D-G49`：**鼠标五键的 `GetKeyState` 恒 0 ⇒ 真实第三方应用里控件永不激活**

> **一句话**：HandyControl demo 能开窗、能把 13 个页面画对，但**点复选框不勾、点下拉不开、点滑块不动**，只拿到焦点。
> 根因在 shim：上游 `Win32MouseDevice` 判按钮状态的**唯一**来源是 `GetKeyState(VK_LBUTTON) & 0x8000`，
> 而本 shim 的键盘状态表里**从来没有鼠标五键** ⇒ 恒 `Released`。
>
> **本波目标**：让它真的能点。判据见 §2（先写死，跑完照判）。

---

## §0 现场与根因（代码级，可复算）

**现象（`#43` 后续实测，全部在 Release 权威件 + 声明档下）**

| 目标 | 读数 | 结论 |
|---|---|---|
| 导航项（正对照） | `AE=235769` | 换页 ✓ |
| 复选框 首项 | `AE=6144`，1:1 放大复核 = 只多了**虚线焦点框**，勾选态**不变** | 不激活 |
| 组合框 首项 | `AE=7418`，可见 X 窗口数 `1→1`（**下拉没开**） | 不激活 |
| 滑块 轨道中部 | `AE=0` | 不动 |
| 长按 2.5 s / 按住期间移指针 | 与 0.5 s 时**逐位相同**（`AE=0`） | 不是"事件被攒着" |

**根因（逐字引证）**：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/Input/Win32MouseDevice.cs`

```csharp
virtualKeyCode = NativeMethods.VK_LBUTTON;                       // :45
mouseButtonState = ( UnsafeNativeMethods.GetKeyState(virtualKeyCode) & 0x8000 ) != 0
                   ? MouseButtonState.Pressed : MouseButtonState.Released;   // :61
```

⇒ WPF 的 `MouseButtonEventArgs.ButtonState` **不看消息**，只看 `GetKeyState` 的高位。
本 shim 的 `GetKeyState`（`src/WpfGfx.Linux.Native/src/win32_core.c:1409`）只读 `g_wpf.key_state[256]`，
而那张表**只有键盘翻译层**（`win32_x11.c` 的 KeyPress/KeyRelease）在填 ⇒ `VK_LBUTTON/RBUTTON/MBUTTON/XBUTTON*` 恒 0
⇒ `e.ButtonState == Released` ⇒ 上游 `ButtonBase.OnMouseLeftButtonDown` 里
**`Focus()`（在判据之前）照样执行、而 `if (e.ButtonState == Pressed) { CaptureMouse(); SetIsPressed(true); }` 判假**
⇒ 焦点有、激活无；`OnMouseLeftButtonUp` 也就永不 `OnClick`。
（同一条链解释了 Thumb/滑块拖动、ComboBox 下拉、Expander 全都不动，而 ListBox 选择/文本框焦点**照样工作** ——
那两条都不查 `ButtonState`。）

**这条缺陷仓内从未登记**：`grep -rn "点不动\|ButtonState" docs/ samples/ handoff.md` = 0 命中；
仓内也**没有任何点击注入的测试**（`grep` 全仓无源级 `xdotool/ButtonPress` 调用点）。

---

## §1 修法（三处，全部在 shim）

| # | 文件 | 改动 |
|---|---|---|
| 1 | `src/WpfGfx.Linux.Native/src/win32_x11.c` | **新增** `short wpf_x11_mouse_keystate(int vk)`：用 `XQueryPointer` 取**真实指针按键态**（`Button1/2/3/4/5Mask`）⇒ 映射到 Win32 的五个鼠标 VK，按下返回 `0x8000` |
| 2 | `src/WpfGfx.Linux.Native/src/win32_core.c` | `wpf_keystate_read()` **最前面**加一条：仅对 `0x01/0x02/0x04/0x05/0x06` 五个 VK 走新函数；**键盘路径一字不动**（`from_snap`/`live` 逻辑对其它 VK 逐字保留） |
| 3 | `src/WpfGfx.Linux.Native/src/win32_internal.h` | 声明 `wpf_x11_mouse_keystate`（与 `wpf_x11_set_input_focus` 同处） |

**取值口径为什么用 `XQueryPointer`（而不是自己维护事件表）**：
① 它与 Win32 `GetKeyState` 同义 —— **物理键态**，不是"队列里那条消息"；
② 它天然免疫"按下/抬起被并成一批"这类时序问题（本波已实测：长按 2.5 s 也没用 ⇒ 时序不是本因，但新口径顺带把它排除）；
③ 一次 `XQueryPointer` 是本地 socket 往返，WPF 每个鼠标事件只问几次，代价可忽略。

---

## §2 判据（**先写死**；跑完照判，不许事后改口径）

**产品侧（hc demo，仓外，Release 权威件 + 声明档）**

| # | 判据 | 修前（实测） | 修后应为 |
|---|---|---|---|
| **P1** | 复选框：点完 **该控件自身包围盒内**的像素发生翻转（勾没了） | 盒内 **0** 变化、只有盒外虚线焦点框 | 盒内 **> 0**（勾选态翻转） |
| **P2** | 组合框：点完**可见 X 窗口数 +1**（下拉是独立窗口） | `1→1` | **`1→2`** |
| **P3** | 滑块：点轨道中部后 **thumb 位移**（帧变化 `AE > 2000`） | `AE=0` | `AE > 2000` |
| **P4** | **正对照**：导航点击仍换页（`AE > 100000`） | `235769` | 仍 `> 100000` |
| **P5** | **反极性**：什么都不点时页面保持 `AE=0`（不许到处冒变化） | `0` | 仍 `0` |
| **P6** | 应用不崩、`app.log` 无 `Exception`/`Assert` | 0/0 | 0/0 |

**仓内侧（不许回归）**

| # | 判据 | 通过条件 |
|---|---|---|
| **R1** | `verify-all` 25 步 | `rc=0`、`结论：✅ 全部通过` |
| **R2** | 应用门禁 ×2 | 两趟 `result=PASS`（6/6） |
| **R3** | `DEFREG` / `BASELINE-SHA` / `ARM-LOG-SHA` / `COLUMN-FLOOR` | 各自 `PASS` |

---

## §3 位移预测（**落地前写死**；跑完对账）

| 位 | 预测 | 依据 |
|---|---|---|
| `win32shim`（`libwpfwin32.so`） | **必变** | 改的就是 `win32_core.c`/`win32_x11.c`/`win32_internal.h` |
| `bridge` / `pc` / `pf` / `windowsbase` / `provider` / `wic_shim` / `dwf` / `hbtextline` | **不应变** | 它们不编译这三件 C 源；托管件不引用 shim 的符号（只 `DllImport` 运行期加载） |
| `GEN_KEYS`（`run.sh`／`HbTextLineParity/Program.cs`／`build/shims/PresentationCore.HbTextLine.cs`） | **不动** | 三件都不在本次改动里 ⇒ 世代键不变 |
| `inputs_fp` | **不动** | 覆盖面是 `src/WpfGfx.Linux.Native/tools/patch-*.py` ＋ `build/**` ＋ `build/shims/**/*.cs` ＋ `src/WpfGfx.Linux/**/*.cs` ＋ 点名清单；**`src/WpfGfx.Linux.Native/src/*.c` 不在里面** |

⚠️ 但 `win32shim` 是**九位之一** ⇒ **必须**：重建该位 → **重取五臂**（臂日志内容含位 sha）→ 重钉 → 门禁 ×2 → `verify-all` ×2 → **冻结 `#44`** → 冻后 ×2。

---

## §4 本波**不做**

1. 不动 `D-G47` 的"潜在真缺陷定性"（另立）；
2. 不动 `D-T4`/`D-G48` 的"透参"产品修（那是 `pc` ＋ shim 托管侧，另一波）；
3. 不顺手改键盘路径（`from_snap`/`live` 逐字保留）；
4. 不把 hc 的"第一帧/焦点视觉"等观感问题混进本波判据（它们不是本缺陷）。

---

## §5 诚实条款

- **本波的头号风险是"改完仍然点不动"**：若 P1–P3 修后仍不达标，**不许**把它写成"部分改善"；
  如实记"根因判断有误"，并把 `XQueryPointer` 读数（点与不点时 mask 的值）单独打出来再定性。
- 观测值一律**当场算**（`compare -metric AE` 的**局部包围盒**、`xdotool search` 的窗口数）；不许手抄。

---

## §6 记录（`#44` 收官读数）

### ① 判据表（对着 §2 的**预先写死**逐条读）

| 判据 | 修前 | 修后 | 判 |
|---|---|---|---|
| **P1** 复选框：**控件自身 24×24 盒内**像素 | `AE=0`（只有**框外**的焦点虚线） | **`AE=338`**；再点一次 **`276`**（可反复切换） | ✅ **达标** |
| **P2** 组合框：可见 X 窗口数 | `1→1` | `1→1`（`AE=7418`，≈仅焦点） | ⛔ **未达标**（另立条目查） |
| **P3** 滑块：点轨道中部 | `AE=0` | `AE=0` | ⚠️ **判据作废**（见 ③） |
| **P4** 正对照：导航换页 | `235769` | **`235937`** | ✅ |
| **P5** 反极性：静置 3 s | `0` | `0` | ✅ |
| **P6** 不崩、`app.log` 无 `Exception`/`Assert` | `0/0` | `0/0` | ✅ |

补充读数（`$HOME/w44-followup-1/`）：**第 1 次点复选框 `boxAE=338`、第 2 次 `276`、点导航换页 `235937`、再点同一导航项 `0`** ⇒
① 复选框**可反复切换**；② 第一次点击之后**导航照样工作**（没有"捕获没释放导致整应用卡死"这回事）。
⚠️ `w44-hc-accept.sh` 那趟里 `P4` 一度读到 `0`（同一条判据、同一二进制）⇒ 那是**该趟的局部现象**（极可能是 `navto 7`/`navto 10` 与 `settle` 的时序），**不是产品行为**；后续件用同法复测为 `235937` 已证。

### ② 位移对账（预登记 §3 写死过）

| 项 | 预测 | 实测 | 判 |
|---|---|---|---|
| `win32shim` | 必变 | `73c488a6aa0450e2` → **`11f81eb9dfc60a12`** | ✅ |
| `pc` / `pf` | **不应变** | `deb8e19265917814`→`45e7e0a46f5912c0`；`d160eaed711edb61`→`a93097f7a918597f` | ❌ **预测错了** |
| `bridge`/`windowsbase`/`provider`/`wic_shim`/`hbtextline`/`dwf` | 不应变 | 六位**逐位未变** | ✅ |
| `inputs_fp` | 不动 | `ee98113b…` → **`493551db…`** | ❌ **预测错了**（原因见下） |
| `GEN_KEYS`（三件） | 不动 | 未动；但位 sha 变 ⇒ **重取五臂**（`tline` 日志 `9746cbcb…`→`928b79e6…`，其余四支逐位相同）＋**重钉**（`repin_rc=0`、`--check` 四处一致） | ✅ |

**为什么 `inputs_fp` 会变（第二处预测错）**：本波按纪律**重钉** `build/MilBridge/known-red.json`（重取五臂后必须同趟钉齐四处），而**它在 `fp_inputs()` 覆盖面里**（「改登记表必须看得见」是设计）⇒ 属**设计性变更**。本波真正改的 `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_x11.c,win32_internal.h}`**不在**覆盖面里 —— 那半条预测成立。

**为什么 `pc`/`pf` 会变（不是因果耦合）**：`integration-wave` 会**整波重建**，而本工程是**非确定构建**（每次重建 MVID／内嵌时间戳都变）⇒ **重建即变字节**。
⇒ 教训：预登记里"某位不应变"这种预测，只有在**该位不参与本次重建**时才有意义；否则应写成"允许变（重建即变）"。**本波如实记这条预测错。**

### ③ `P3` 判据作废（我写错了，不许算产品红）

WPF 的 `Slider` 默认 **`IsMoveToPointEnabled = false`** ⇒ **点击轨道本来就不会移动 thumb**，必须**拖 thumb**。
⇒ 正确判据 = 在"已填充/未填充"分界处按下 → 拖动 → 抬起，比帧差（>2000）。本波**未重测**（判据是错的那条读数无效，不是产品红）。

### ④ 本波新增的三条仪器自伤（都留档）

1. **publish 目录里根本没有 `libwpfwin32.so`** ⇒ 早前几件 hc 仪器里那句 `[ -f "$src" ] && cp …` **静默什么都没做**，
   应用目录一直躺着 `#40` 世代的老 shim（`73c488a6aa0450e2`）⇒ 那些读数是**旧件上的读数**。
   本波验收件改为从**权威位路径** `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 取，并把两边 sha 一起印出来对账。
2. `integration-wave.sh` 在 `WAVE_OWNER` 未设时**拒绝运行**（结构性约束，`rc=9`）—— 那是约束，**不是构建失败**（我第一次误读成失败）。
3. 两个 hc 仪器件**共用 `:95`** ⇒ 后者收尾杀掉前者还在用的 X server ⇒ 那次 `SIGSEGV`／`X connection broken` 是**自伤**，不是产品崩溃（读数作废）。此后 hc 件一律**独占**显示号并 `export DISPLAY`。

### ⑤ 未做（写清楚，留给下一波）

1. **P2 组合框下拉**（`nwin 1→1`）：shim 里**完全没处理 `WS_POPUP`/`WS_EX_*`**（`grep` 无命中）⇒ 首要嫌疑；
   判别仪器已备（`$HOME/w45-diag.sh`：沿组合框行扫 x，逐点记 `all/visible/tree` 三口径 ⇒ 分清"窗口没建"与"建了没映射"）。
2. **P3 用正确判据重测**（拖 thumb）。
3. `D-T4`/`D-G48` 的"透参"产品修、`D-G47` 的潜在真缺陷定性：仍待。

### ⑥ 冻后复核（**两趟全绿**）

| 趟 | 读数 |
|---|---|
| post1 | `VA_POST1_RC=0`、`步骤通过 25  ❌ 失败 0`、`结论：✅ 全部通过` |
| post2 | `VA_POST2_RC=0`、`步骤通过 25  ❌ 失败 0`、`结论：✅ 全部通过` |

⚠️ **过程如实记**：这趟冻后 ×2 **重发过一次** —— 第一趟我主动停掉（按 PID），原因是当时预计还要改产品件，
"跑完即被作废"⇒ 改为在**稳定树**上重跑。重跑前已核对：仓内所有相关件 mtime ≤ 15:59（冻结/记录写入时刻），
跑动期间**没有**改任何仓内文件（只在 `$HOME` 下加仪器）。

### ⑦ `#44` 之后对 `D-G50` 的进一步定位（**下一波开工前必读**）

1. ⭐ **被测件被澄清**：demo 的导航是**分组的**，我一路点的"组合框"（Styles 组第 11 项）在 `DemoInfo.json:17` 映射到
   **`NativeComboBoxDemo`** —— 里面是**标准 WPF `ComboBox`**（HandyControl 只通过 `Theme.xaml` 给它套模板 ＋ `hc:DropDownElement` 附加属性）
   ⇒ **不是**"HandyControl 的私有控件"。⇒ 缺口在"**标准 ComboBox ＋ HandyControl 模板**"这条链上。
2. **机制侧**（上游 `ComboBox.cs:149-162`）：`!IsLoaded` 时 `IsDropDownOpen` 被 **coerce 成 `false`**（实测：`STATE … IsLoaded=False` 时置 true，台面上仍是 `False`）。
3. **但这不是 hc 的病根**（负结果）：**后加入可视树**的 ComboBox 1 s 后就 `IsLoaded=True`，且 `+1s/+3s/+6s` 三次都能开出下拉
   （`EVT lateCombo.DropDownOpened` ×3）⇒ `Loaded` 对后加元素照常触发。等待 2/10/25 s 再点 hc 的组合框**也都不开**。
4. ⚠️ **`D-G51` 挡住 `D-G50` 的探针**，而 `D-G51` 今天又被**收窄**到"呈现路径"：
   我的最小探针实测 `w.Actual=420×520`、`panel.Actual=388×488`、`combo.Actual=220×20.8`、`w.Template=ok`、
   `visualChildren(w)=1`、`visualChildren(panel)=4` ⇒ **布局/模板/可视树全正常**；**强制失效（`InvalidateVisual/Measure` ＋ 改宽）也不画**
   （截图仍 2 色）⇒ **不是布局问题，是"内容没被画/没被呈现"**。
   ⇒ 探针为此**不可点击**（点击落不到未呈现的内容上，实测点击只有程序化那条 `DropDownOpened` 事件）
   ⇒ **`D-G51` 是 `D-G50` 的唯一关键路径**：先定位并修 `D-G51`（或把探针做成 XAML 形态规避），D-G50 才测得动。

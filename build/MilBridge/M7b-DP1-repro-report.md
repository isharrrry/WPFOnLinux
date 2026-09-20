# M7b · `D-P1` 最小复现报告（输入路径）：**判定 = (甲) 复现不了**

> **本轮只写测试与报告**：未改 `src/**`、未发桥、未跑 WPF 应用（用的是测试装置）、未重建 PC。
> 自起 Xvfb **`:96`**（按 PID 收尾，`Xvfb 已退出`）；`-m:1`。

---

## 1. 装置与测试（新增）

| 文件 | 说明 |
|---|---|
| `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/DP1ReproTests.cs`（**新**） | 两个用例：① `闸门_win32shim被测件与权威件同sha`（staleness 闸门，不需要 X）；② `DP1_输入路径_键入后TextDP是否陈旧`（`[X11Fact]`，装置主体） |
| `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj` | **加一条引用**：`PresentationFramework`（`TextBox` 在那个程序集；与既有 5 件同口径 `HintPath` + `Private=true`） |

**装置流程**（无 xdotool、无 T3 的应用槽）：
```
Dispatcher.CurrentDispatcher → new HwndSource(320×120, WS_VISIBLE|WS_OVERLAPPEDWINDOW)
  → RootVisual = new TextBox{ Text="seed-文本", Width=200, Height=24 }（挂 TextChanged 计数）
  → 泵 700ms（布局/首帧）→ tb.Focus() + Keyboard.Focus(tb) → 泵 400ms
  → PostMessage(hwnd, WM_KEYDOWN 'A') / WM_CHAR 'A' / WM_KEYUP 'A'
  → 泵 1200ms（含 Background 优先级）
  → 读三个量：`tb.Text`（DP）、**容器读数**、`TextChanged` 计数
```
**容器读数**为什么不是 `tb.Document`：`TextBox` **没有** `Document/ContentStart/ContentEnd`（那是
`RichTextBox`/`TextBlock` 的 API，编译期实测 CS1061）⇒ 改用 `SelectAll() + SelectedText`
（经 `TextRange` 读**容器**，与 `Text` DP 是两条路），读完**恢复原选区**。

## 2. 三值判定（**原始输出**，第四轮）

```
已通过 …DP1ReproTests.闸门_win32shim被测件与权威件同sha [8 ms]
 权威件 f84d65a62e0c7fa4  …/src/WpfGfx.Linux.Native/bin/libwpfwin32.so
 被测件 f84d65a62e0c7fa4  …/src/WpfGfx.Linux.Native/bin/libwpfwin32.so

已通过 …DP1ReproTests.DP1_输入路径_键入后TextDP是否陈旧 [3 s]
 焦点：tb.Focus()=True IsKeyboardFocused=True IsFocused=False hwnd=0x200002
 PostMessage: KEYDOWN=True CHAR=True KEYUP=True
 读数：DP.Text="Aseed-文本" 容器="Aseed-文本" TextChanged=1
 (甲) **复现不了**：输入路径下 DP 已更新 ⇒ D-P1 与 X/xdotool 注入时序相关（往下查注入环节）
```
⇒ **判定 (甲)**：`WM_CHAR` 经"我们自己的 `PostMessage` → 队列 → 泵 → HwndSource → HwndKeyboardInputProvider
→ TextInput → TextEditor → `Text` DP"这条一般路径时，**DP 正常更新**（`DP.Text == 容器`、`TextChanged=1`）。
⇒ **(乙) 不成立**（不是"容器变了 DP 陈旧"）。

**顺带两条读数**：
- `IsFocused=False` 而 `IsKeyboardFocused=True` ⇒ 窗口级"激活"没成立，但**不影响**这条路径的文本输入
  （`WM_CHAR` 照样进 DP）——T3 现场也是这个形态，可据此排除"窗口未激活导致字符被丢"。
- 插入位置在**串首**（`"Aseed-文本"`，插入时 caret=0）；T3 的块先 `SelectAll()` 再注入 ⇒ 序列不同。

## 3. staleness 闸门（按你第 2 条固化）

`闸门_win32shim被测件与权威件同sha`（`[Fact]`，不需要 X）：解析顺序与
`build/shims/Win32ShimResolver.cs` / `X11Guard.cs` **一致**（env `WPF_LINUX_WIN32_SHIM` → 程序集目录 →
仓库 `src/WpfGfx.Linux.Native/bin`），断言"**被测件 sha16 == 权威件 sha16**"，并在输出里同时打印两件路径。
**本轮读数：两者都是 `f84d65a62e0c7fa4`（PASS）**。这条正是 F2 报告附 D 与 msgflow 报告 V.2 两次教训的固化。

## 4. 装置侧踩到的一个真坑（已修，登记防复发）

测试程序集直接 `[DllImport("user32.dll", EntryPoint="PostMessageW")]` ⇒
**`DllNotFoundException: Unable to load shared library 'user32.dll'`**（错误信息列出一串 `user32.dll.so`）。
根因：**`SetDllImportResolver` 是按程序集注册的**，shim 只在它自己那几个程序集里注册过解析器
⇒ 测试程序集必须**自己**接一条（现已在 `static DP1ReproTests()` 里把 `user32.dll` 指到同一个
`libwpfwin32.so`）。**这条对以后任何"测试里直接调 Win32 API"的用例都适用。**

## 5. 下一步该看哪一跳（(甲) 之后的收窄）

因为"一般输入路径"已被证明**是通的**，差异只可能来自**注入方式/序列/时序**。下一轮我在**同一个装置**里做三档二分
（不需要应用槽、不需要 T3）：

| 档 | 注入 | 想排除的差异 |
|---|---|---|
| (a) | 裸 `WM_CHAR 'A'`（**不**先 `WM_KEYDOWN`） | 是否 `KEYDOWN` 的"已处理"语义（`HwndSource._eatCharMessages`）影响了后续字符 |
| (b) | 先 `SelectAll()`（或注入 `ctrl+a` 的 `VK_A`+`Ctrl` 状态）**再** `WM_CHAR 'A'` | 现场第一步就是 `ctrl+a` ⇒ "选区 + deferred 写"的交互 |
| (c) | **连续两次**键入（`'A'` 后 `'B'`，即现场 `"AB"`） | 第一次写正常、**第二次**写进 deferred 路径（PF 探针看到 `SetCurrentDeferredValue` 调了**两次**） |
| (d) | **把真注入搬进装置**：对本装置自己的 `HwndSource` 句柄跑 `xdotool key --window <hwnd>`（X11Fact 下可行，我已起 `:96`） | **逐字复刻应用的注入方式**（XSendEvent/XTEST + 成批到达），仍不需要 T3 的槽 |

**判据**：哪一档出现"**容器已变而 `DP.Text` 陈旧**"⇒ 那一档就是 `D-P1` 的最小 repro，随后在**同装置**里
二分"哪一跳之后开始陈旧"（`WM_CHAR` → `InputManager` → `TextEditor` → DP 写），把缺陷钉到具体一跳。
**若 (a)(b)(c) 都不复现而 (d) 复现** ⇒ 结论落在"X 注入的成批/时序"上，那才是 X/xdotool 环节。

## 6. 纪律声明
- 只新增 `DP1ReproTests.cs` + 在测试工程加一条 `PresentationFramework` 引用（均在 `tests/**`，我的车道）；
  **未改** `src/WpfGfx.Linux/**`（T2b）、`build/shims/**`（T1d）、`samples/**`（T3）；未发桥、未重建 PC、未跑应用。
- Xvfb `:96` 自起自收（`kill -TERM <PID>`，已确认 `Xvfb 已退出`），未触碰 `:99`/`:97`（别人的）。
- 闸门读数（权威=被测=`f84d65a62e0c7fa4`）为**本轮现场重读**，带时刻口径见输出（未转抄任何旧值）。

---

# 四档二分（主控 2026-09-13 批准）：**四档全部"不复现"**

## 4.1 一行结论
在**同一装置**里把注入方式/序列换遍（裸 CHAR / 先 SelectAll / 连续两次 / **真 xdotool 注入**），
`DP.Text` **每一次都与容器一致**⇒ **`D-P1` 不在"注入方式与序列"这一层**；装置侧**没有**任何一档能当最小 repro。

## 4.2 每档原始读数（`DISPLAY=:96`，自起 Xvfb、按 PID 收）

| 档 | 注入（实际调用） | `DP.Text` | 容器 | `TextChanged` | `IsKeyboardFocused` | 判定 |
|---|---|---|---|---|---|---|
| 基本（1 轮） | `PostMessage(WM_KEYDOWN'=A')/WM_CHAR'A'/WM_KEYUP` 三条 `True` | `"Aseed-文本"` | `"Aseed-文本"` | 1 | True | **不复现** |
| **(a)** 裸 CHAR | `PostMessage(WM_CHAR 'A')=True` | `"Aseed-文本"` | 同左 | 1 | True | **不复现** |
| **(b)** 先 SelectAll | `tb.SelectAll() (selLen=7)` → `PostMessage(WM_CHAR 'A')=True` | `"A"` | `"A"` | 1 | True | **不复现** |
| **(c)** 连续两次 | `KEYDOWN'A'=T/CHAR'A'=T` →(泵 120ms)→ `KEYDOWN'B'=T/CHAR'B'=T/KEYUP=T` | `"ABseed-文本"` | 同左 | **2** | True | **不复现** |
| **(d)** **真注入** | `xdotool key --window 0x20000a a → exit=0` →(泵 250ms)→ `xdotool type --window … AB` | `"aABseed-文本"` | 同左 | **3** | True | **不复现** |

**测试结果**：`测试总数 6 / 通过数 6`（闸门 + 基本 + a/b/c/d），**0 失败**；Xvfb `:96` 已按 PID 收（`Xvfb 已退出`）。

## 4.3 扩展后的 staleness 闸门（按边界 1 加"桥/PC/PF 副本 == 权威"）
```
权威件 f84d65a62e0c7fa4  src/WpfGfx.Linux.Native/bin/libwpfwin32.so
被测件 f84d65a62e0c7fa4  src/WpfGfx.Linux.Native/bin/libwpfwin32.so
桥权威件 7dfe964828908437  build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so
桥副本   7dfe964828908437  …/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so
桥副本   7dfe964828908437  …/.artifacts/bin/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.so
PC PresentationCore.dll：被测 23567d420f0dbbaa == 权威 23567d420f0dbbaa
PF PresentationFramework.dll：被测 bfb10fe2a01a986b == 权威 bfb10fe2a01a986b
```
⇒ **装置加载的就是当前被重发过的桥**（`7dfe964828908437`，T2b 那一版；上一版是 `e0d01832a3efea53`）。
**踩到并修掉的一个口径错误**（登记防复发）：第一版按 `LD_LIBRARY_PATH` 猜"被加载的桥"是**错的**
——那一跑 `LD_LIBRARY_PATH` 里其实没有桥，装置照样跑起来（桥由 `WpfGfx.Linux` 自己的自定位逻辑加载）
⇒ 已改成**枚举所有副本逐一与权威比 sha**，找不到任何副本才报失败。

## 4.4 可复现命令（别人照着能跑出同样结果）
```bash
# 0) 私有 X（:96；:97/:99 是别人的）；按 PID 收
Xvfb :96 -screen 0 1280x1024x24 >/tmp/xvfb96.log 2>&1 & XPID=$!; sleep 2.5
MILDIR=$(dirname "$(find build/MilBridge/.artifacts -name wpfgfx_cor3.so | head -1)")
# 1) 全部 D-P1 用例（闸门 + 四档）
DISPLAY=:96 LD_LIBRARY_PATH="$MILDIR:$LD_LIBRARY_PATH" \
  dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj -m:1 \
  --filter "FullyQualifiedName~DP1Repro" --logger "console;verbosity=detailed"
# 2) 只看某一档：把 filter 换成 FullyQualifiedName~DP1_a / ~DP1_b / ~DP1_c / ~DP1_d
kill -TERM "$XPID"
```
四档的注入原文：**(a)** `PostMessage(WM_CHAR,'A')`；**(b)** `tb.SelectAll()` + `PostMessage(WM_CHAR,'A')`；
**(c)** `(KEYDOWN'A',CHAR'A')` → 泵 120ms → `(KEYDOWN'B',CHAR'B',KEYUP)`；
**(d)** `xdotool key --window <hwnd> a` + `xdotool type --window <hwnd> AB`（`<hwnd>` = 本装置自己的窗口，`HWND==XID`）。

## 4.5 下一步该看哪一跳（(a)–(d) 全排除之后的收窄）
1. **先复核"现场还在不在"**：`D-P1` 的现场读数（`Q7b SetCurrentDeferredValue` ×2、38 次读陈旧、
   `TextChanged=0`）采集于**队列根因修好之前**。本轮的装置用的是**修好之后**的 shim
   （`f84d65a62e0c7fa4`）⇒ **请 T3 用当前件复跑一次 `--only=textbox-edit`**：
   - 若 `changes>0` ⇒ `D-P1` 很可能已随队列修法消失（那就不必再追 `GetFlattenedEntry`）；
   - 若仍 `changes=0` 而原生侧已有 `pop 0x0102` ⇒ 再进第 2 条。
2. **装置 vs 应用的差异（按可能性排序）**——我下一轮可在同一装置里逐条复刻：
   a. **TextBox 不是根可视**：应用里它在 `StackPanel/Card/Border` 深层，且同窗口还有别的块
      ⇒ 装置加一层 `ScrollViewer → StackPanel → Border → TextBox`；
   b. **取焦点的时机**：应用的 `Verify()` 在**首帧之前/之中**就 `Focus()+SelectAll()`，装置是首帧后 700ms
      ⇒ 装置改成"建窗后立即取焦点、再泵"；
   c. **两次写的时间关系**：PF 探针看到 `SetCurrentDeferredValue` 调两次，我的 (c) 隔了 120ms
      ⇒ 试"同一帧内连发两条 CHAR"（不泵）与"跨多帧"两种；
   d. **是否有别的输入提供者**：应用里同时存在 `HwndMouseInputProvider` 与其它块的输入处理
      ⇒ 装置里同时挂一个 `Mouse` 交互（点击）后再键入。
3. **判据不变**：出现"**容器已变而 `DP.Text` 陈旧**"的那一档即为最小 repro；届时在同装置内二分
   `WM_CHAR → InputManager → TextEditor → DP 写` 哪一跳开始陈旧。

---

# §4.5 的四条"装置 vs 应用"结构性差异：**也全部不复现**（主控 2026-09-13 批准，放行后跑）

**放行与并发**：跑前确认哨兵 `/tmp/bridge-frozen.flag` = `SHA=f68f01c10e456982`、`FP=0dec99db900ef654`；
跑前检查 `/tmp/bridge-republish.lock` **不存在**（无重发在进行）。`DISPLAY=:96` 自起 Xvfb、按 PID 收（`Xvfb 已退出`）。
**`测试总数 11 / 通过数 11`，0 失败。**

## 4.5.1 每条的原始读数（`DP.Text` / 容器 / `TextChanged` / `IsKeyboardFocused` / `selLen`）

| 用例（`--filter` 粒度） | 注入（实际调用） | `DP.Text` | 容器 | `TextChanged` | `IsKeyboardFocused` | `selLen` 前→后 | 判定 |
|---|---|---|---|---|---|---|---|
| `~DP1_e` 非根可视 | 嵌套根 `ScrollViewer→StackPanel→Border→TextBox`；`SelectAll` → `KEYDOWN/CHAR/KEYUP`=T/T/T | `"A"` | `"A"` | 1 | True | 7→0 | **不复现** |
| `~DP1_f` 首帧前取焦点 | 焦点与 `SelectAll` 都在**首帧前**完成；`KEYDOWN/CHAR`=T/T | `"A"` | `"A"` | 1 | True | **7**→0 | **不复现** |
| `~DP1_g1` 同帧连发 | `SelectAll` → 同帧连发 `CHAR'A'`=T / `CHAR'B'`=T（中间不泵） | `"AB"` | `"AB"` | 2 | True | 0→0 | **不复现** |
| `~DP1_g2` 跨多帧 | `SelectAll` → `CHAR'A'` →(泵400ms)→ `CHAR'B'` →(泵400ms) | `"AB"` | `"AB"` | 2 | True | 0→0 | **不复现** |
| `~DP1_h` 先鼠标点击再键入 | `xwininfo=(0,0,320x120)` → `mousemove(160,60)` → `click 1` → `xdotool key --window a` | `"aseed-文本"` | 同左 | 1 | True | 0→0 | **不复现** |
| （前一轮 a/b/c/d 四档） | 裸 CHAR / 先 SelectAll / 连续两次 / **真 xdotool** | 见 §4.2 | 同左 | 1/1/2/3 | True | — | **均不复现** |

**装置加载的件（本轮现场）**：`libwpfwin32.so` `f84d65a62e0c7fa4`（被测==权威）、
**桥 `f68f01c10e456982`（== 哨兵；publish 与 `.artifacts/bin` 两处同 sha）**、
`PresentationCore.dll 23567d420f0dbbaa`、`PresentationFramework.dll bfb10fe2a01a986b`（app-local == 权威）。

## 4.5.2 与 T3 应用级读数的对照（**待 T3 用当前件复跑 `--only=textbox-edit` 的原文**）

| 侧 | 件 | `changes=` | `selLen=` | 原生侧 `pop … 0x0102` | 判定 |
|---|---|---|---|---|---|
| 装置（本报告，9 档合计） | shim `f84d65a62e0c7fa4` / 桥 `f68f01c10e456982` | **≥1（每次都随字符数增加）** | 见上表 | 不适用（装置不经 X 注入时也走同一队列） | **装置层不可复现** |
| 应用（T3） | **待转原文** | **待填** | **待填** | **待填** | **待读数判定** |

**判定规则（写死，不许推断）**：
- 若应用侧 `changes>0` ⇒ **`D-P1` 已随"队列根因修法"消失**（`wpf_queue_pop` 摘队尾时把 `tail` 指回新队尾
  ⇒ 不再出现"下一次 push 覆盖 head、整条链孤儿化"的静默丢件；现场读数采集于该修法**之前**）。
- 若应用侧 `changes=0` **且**原生侧已有 `pop … msg=258(0x0102 WM_CHAR)` ⇒ 消息已从 `GetMessage` 出来
  ⇒ 落点在**托管输入栈**（`HwndSource._eatCharMessages` / `TranslateChar` / `InputManager` 路由），
  届时我在**同装置**里逐跳二分（装置已能稳定做出"DP 正常更新"的基线，正好当对照）。
- 若应用侧 `changes=0` **且**原生侧**没有** `pop 0x0102` ⇒ 回到队列/注入侧（可用 msgflow v3 的
  `skip`/`call`/`队列内容` 三行定案）。

## 4.5.3 结论（装置侧）
**装置层不可复现**：注入方式（裸 CHAR / 先 SelectAll / 连续两次 / 真 xdotool）× 结构性差异
（非根可视嵌套 / 首帧前取焦点 / 同帧连发 / 跨多帧 / 先鼠标点击）**共 9 档全绿**，`DP.Text` 与容器**每次都一致**。
⇒ `D-P1` 若要复现，需要**应用特有的上下文**（多块同窗 + 主题/样式 + 真实输入时序），或它**已随队列根因修法消失**；
**哪一种必须由 T3 的应用级读数裁决**（本节 4.5.2 的规则）。

---

# §4.6 最终判定所需的最小读数清单（一趟跑完，含分支预测）＋ T3 原文核对

## 4.6.1 我对 T3 读数的核对（**只采纳一半**）
T3 原文（桥 `c66083443200115d`）：`sel` 由 `0,0 → 0,7`、`focus=True`，而 `text='seed-文本'` 全程不变、
20 条采样全 `changes=0`；`WFP_DISPATCH_PRIO normal/input/background/contextidle 全 True`。
- **成立**："**text 全程不变 + changes 全 0 + 焦点 True ⇒ `D-P1` 现场仍在**"（不是"随队列根因修法消失"）。
  `DISPATCH_PRIO` 全 True 也排除"泵没跑到该优先级"。
- **不成立（证据不足）**："**这 0,7 是注入的 `Ctrl+A` 造成的**"。理由两条：
  1. 该块的 `Verify()` **自己**就调了 `_tb.SelectAll()`（台账首行 `[feat] textbox-edit OK … selLen=7`）
     ⇒ `sel=0,7` 与"块自己选全"**同值**，无法区分；首条采样 `t=5374 sel=0,0 focused=False` 只是**更早**的时刻。
  2. **装置侧反证**（本轮实跑，见 §4.6.3）：用**逐字相同的注入**（`xdotool key --window <hwnd> ctrl+a`）
     在装置里 Ctrl+A **没有**产生全选（'AB' 是**插入**成 `"ABseed-文本"` 而不是替换成 `"AB"`）
     ⇒ 本 shim 下 **Ctrl 修饰键未生效**（`GetKeyState(VK_CONTROL)` 大概率恒 0）⇒ 应用侧同样可疑。
- ⇒ 最终判定**不依赖**"Ctrl+A 是否生效"；只依赖 §4.5.2 的分支规则 + 下一条清单。

## 4.6.2 最小读数清单（请照此派 T3，**一趟跑完**）

**命令**（三个开关同时开；固定 run dir 便于取日志）：
```bash
WFP_RUN_DIR=/tmp/dp1-native \
  tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh 90 --only=textbox-edit \
  --app-env=WPF_LINUX_MSGFLOW_TRACE=1,WPF_LINUX_KEY_DIAG=1,WPF_LINUX_INPUT_TRACE=1
# 读点：/tmp/dp1-native/probe-triage-textbox-edit.log（或 probe-only.log）
L=/tmp/dp1-native/probe-triage-textbox-edit.log
```
**要的 7 行原文**（逐条贴回，别只给计数）：
| # | 命令 | 期望/含义 |
|---|---|---|
| 1 | `grep -ac "\[MSGFLOW\] push WM_CHAR" $L` | 入队条数（注入 `AB` ⇒ 期望 **2**；`Ctrl+A` 应 **0** 条）|
| 2 | `grep -a "\[MSGFLOW\] pop" $L \| grep -c "0x0102"` | **关键格**：`WM_CHAR` 有没有从 `GetMessage` 出来 |
| 3 | `grep -a "\[MSGFLOW\] skip" $L \| head` | 若被跳过：**谁**凭**什么条件**跳过（含 `filter/lo/hi`）|
| 4 | `grep -a "\[MSGFLOW\] call " $L \| grep -v "lo=0x0 hi=0x0" \| head` | 有没有**带区间/带窗口**的取消息调用 |
| 5 | `grep -a "\[KEY_DIAG\]" $L \| grep -E "XEV KeyPress\|KEY KeyPress\|DROP" \| head -20` | 翻译层是否**决定**产出：字母应 `→ WM_KEYDOWN + WM_CHAR`；`Ctrl+A` 应 `Drop…Ctrl 组合不产字符`（**这条同时验证诊断在工作**）|
| 6 | `grep -a "\[INPUT_TRACE\]" $L \| head -20` | 托管入口（T1c）有没有 WM_CHAR 相关行 |
| 7 | `grep -a "队列内容=" $L \| head -20` | 队列快照（v3 已内含在 push/pop 行里，**不需要额外开关**）|

**档位**：仍是 `--only=textbox-edit`（不必加别的块）；队列内容快照已随 v3 打在 push/pop 行尾。

**分支判定（"读数长什么样 ⇒ 判哪一支"，一趟回来即可定案）**：
| 支 | 读数形态 | 判定 | 下一步 |
|---|---|---|---|
| **A** | #2 **有** `pop … msg=258(0x0102 WM_CHAR)` | **落点 = 托管输入栈**（消息已出队） | 由 #6 决定下一跳：无 `[INPUT_TRACE]` WM_CHAR 行 ⇒ 被 `HwndSource.FilterMessage` 吃掉（`_eatCharMessages` `HwndSource.cs:1799/1857`、`TranslateChar`）；有 ⇒ 落 `TextEditor`/DP 写。我在**装置**里做同一跳对照 |
| **B** | #2 **无** `pop`，但 #3 **有** `skip msg=0x0102` | 被**带 filter/区间**的调用跳过 ⇒ **回队列侧（我的车道）** | 看 #4 的 `call`：是**谁**在用区间/窗口取消息 |
| **C** | #2 无 `pop`、#3 无 `skip`，而 #7 里 `0x0102` **出现后又消失** | **静默丢件**（F-A 失效或有新路径）⇒ **我立刻查** | 我复跑 `queue_invariant`（离线用例）＋审 head/tail 不变量 |
| **D** | #1 `push WM_CHAR` **一条都没有**，而 #5 显示"决定产出" | 入队失败/窗口不在表 | 看 #5 的 `窗口在表里=` 与 `警告：事件窗口…不在本 shim 的窗口表里` |
| **E** | #5 连 `XEV KeyPress` 都没有 | 键**没到 shim** ⇒ 注入侧 | 但那样 `Ctrl+A`/`sel` 也不该变 ⇒ 与 #5 同看 |

> ⚠️ **判据口径修正（T3 实测抓出的假阳，2026-09-14）**：#2 原先写作 `grep "\[MSGFLOW\] pop" | grep -c "0x0102"` ⇒
> 实测 **8**，但**只有 2 条是真正 pop 出 `msg=258(0x0102)`**，另 **6 条只是行尾 `队列内容=[…]` 里提到 0x0102**
> （v3 的 push/pop 行都带队列快照 ⇒ 同一个 `0x0102` 在一行里出现两次、含义不同）。
> **正确判据：`grep -c "msg=258(0x0102"`**（只数"真被取出的那条"）。
> 这是"仪器口径"族的新成员：**同一个记号在一行里有两种含义时，计数型判据必须锚到唯一形态**。

## 4.6.3 装置侧对照（**我自己跑，已完成**；与"应用侧 A 支"对照用）
新增用例 `~DP1_i`：**嵌套根**（`ScrollViewer→StackPanel→Border→TextBox`）+ **真** `xdotool key --window <hwnd> ctrl+a`
+ **真** `xdotool type --window <hwnd> AB`（与 T3 的 runner 注入**逐字一致**）：
```
[i-嵌套根+真ctrlA+type] 注入：嵌套根；xdotool key --window 0x20000e ctrl+a → exit=0
[i-嵌套根+真ctrlA+type] IsKeyboardFocused=True selLenBefore=0 selLenAfter=0 TextChanged=2
[i-嵌套根+真ctrlA+type] DP.Text="ABseed-文本" 容器="ABseed-文本"   ← 注意：'AB' 是**插入**，Ctrl+A **没**全选
[i-嵌套根+真ctrlA+type] 判定=不复现（DP 已更新）
```
装置侧汇总（本轮）：`测试总数 12 / 通过数 12`；10 个变体**全部"不复现（DP 已更新）"**；
件：桥 `c66083443200115d`（== 你给的当前件；publish + `.artifacts/bin` 两处同 sha）、shim `f84d65a62e0c7fa4`、
PC `23567d420f0dbbaa`、PF `bfb10fe2a01a986b`。
**⇒ 装置与应用的唯一已知差异（本轮新发现）**：**Ctrl 修饰键在装置里不生效**（`ctrl+a` 未全选）；
这一条**必须**在应用侧用 #5 的 `DROP … Ctrl 组合` 行确认，否则不能拿"Ctrl+A 是否生效"当判据。

---

# §4.7 `D-K1`（修饰键失效）的归属与成本评估（**只评估，未动手**）

## 4.7.1 归属：**native shim（我的车道）**，不是托管输入栈
- 托管栈**没有做错**：它老老实实按 Win32 语义查 `GetKeyState(VK_*)`
  （`HwndKeyboardInputProvider.cs:667/673/679`、`:551`）——**是 shim 给了它 0**（`win32_core.c:1288`）。
- 修法只需在 native 侧**维护并暴露按键状态**：X11 翻译层本来就在用 `ev.xkey.state & ControlMask`
  （`win32_x11.c:576-577`）⇒ **数据只在"落表"这一步缺失**，不需要改托管代码、不需要动 `HwndSource`/`InputManager`。

## 4.7.2 成本（粗估，实施前会先出最小方案）
| 项 | 内容 | 量级 |
|---|---|---|
| 状态表 | `g_wpf` 加一个按键状态（修饰键掩码或 `uint8_t[256]`），在 `KeyPress`/`KeyRelease` 里由 **keysym/keycode + `ev.xkey.state`** 双路同步（含 `CapsLock/NumLock` 的低位 toggle 语义） | ~40–60 行（`win32_x11.c` + `win32_core.c` 各一处） |
| `GetKeyState` | 返回高位 `0x8000`（按下）/低位 toggle；`GetAsyncKeyState` 同源 | ~15 行 |
| `GetKeyboardState` | 目前**完全缺失**；按需补（WPF 当前路径未调用 ⇒ 可列为可选） | ~10 行（可选） |
| 牙 | 装置侧 `~DP1_i` **现成且已是红**（期望 `"AB"`）；另加 `Shift+Left ⇒ selLen==1` | 0–5 行 |
| 风险 | 只影响"修饰键状态"这一新状态表；**不碰**队列/变换/文本路径 ⇒ 与 `D-P1`/`RTL` 互不干扰 | 低 |

## 4.7.3 还需要哪些读数（定案与验收各一条）
1. **定案（应用侧，T3 的那一趟）**：第 5 行原文须**同时**出现
   `[KEY_DIAG] KEY KeyPress … state=0x…（含 ControlMask=0x4）` 与 `DROP WM_CHAR 原因：Ctrl 组合不产字符`
   ⇒ 证明"X 层有 Ctrl、上层却看不到"在**应用**里也成立（装置侧已证）。
2. **验收（修后）**：装置 `~DP1_i` 期望 `DP.Text=="AB"`（替代 `"ABseed-文本"`）；
   应用侧 `--only=textbox-edit` 期望 `changes>0`（`type AB` 真的落字）且 `sel` 行为符合 `Ctrl+A` 语义。

## 4.7.4 要不要真机（Windows）对照 `GetKeyState` 语义？
**不需要**（评估结论）：
- `GetKeyState` 的语义有**正式文档**（高位置 1 = 按下、低位 = toggle），且我们的实现只需与"X 层已知的 modifier 掩码"对齐；
- 已有可判的**装置级**判据（`Ctrl+A` 是否全选、`Shift+方向` 是否扩选），比真机 dump 更直接；
- **但有一条值得真机核对**（低优先）：`GetKeyState` 在"消息队列外"与 `GetAsyncKeyState` 的差异
  （WPF 用前者取 modifier 位）——若将来出现"两者不一致"的诡异读数，再补一次真机对照。

## 4.7.5 与 `D-P1` 的边界（避免互相解释）
- `D-K1` 只影响**修饰键派生**的行为；**字符输入**（`WM_CHAR`）不查修饰键 ⇒ 与 `D-P1`（键入后 `Text` DP 陈旧）是**两条独立缺陷**。
- 本轮已用装置读数推翻"注入的 `Ctrl+A` 生效"（§4.6.1）⇒ 后续判定 `D-P1` 时**不得**再引用 `sel=0,7` 作为"Ctrl+A 生效"的证据。

---

# §4.8 判定（**2026-09-14 修订**：`D-P1` 的"断点"降级为**未判定**；据 T3 一趟读数 + T1c 只读分析）

## 4.8.1 `D-P1` 判定修订：**命中 A 成立；"editor → `Text` DP" 这一步降级为「未判定」**

**仍然成立（不变）**：
1. **消息出队了**：判据 `msg=258(0x0102` ⇒ **2 条**（= 注入的两个字符），与 `[MSGFLOW_TRACE] ① 出队 0x0102` 一致。
2. **不是分支 B**：4 条 `skip … filter=0x200001 lo=0x8000 hi=0x8000` 是 **Dispatcher 消息窗**只 peek
   `[0x8000,0x8000]` 的良性跳过（`0x0102` 留队、随后被 `GetMessageW` 取走）。
3. **不是被 `HwndSource.FilterMessage` 吃掉**：`_eatCharMessages=False`、`TranslateChar/OnMnemonic=handled False`、
   **`ProcessTextInputAction ⇒ handled=True`** ⇒ 线程预处理即 handled、不进 `DispatchMessageW`（解释 `[msg]` 盲区）。
4. **输入链走到底**：编辑器文档变成 `AB` 且 `UndoCloseAction=Commit`，`[INPUT_TRACE]` 侧 `Changed` 已 raise。

**降级为「未判定」的那一步**（原写"断点 = editor→`Text` DP"）：**当前读数不支持这个夹逼**，两条依据（T1c 只读分析，我已逐条核过）：
1. **"DP 里没有字符串"本来就是上游设计**：`TextBox.cs:1194 → :1214`
   `DeferredTextReference dtr = new DeferredTextReference(this.TextContainer) → :1216 SetCurrentDeferredValue(TextProperty, dtr)`；
   字符串在**读**时现算（`DeferredTextReference.cs:41-43 GetValue → TextRangeBase.GetTextInternal`）。
   ⇒ `W5 SetValueCommon value=DeferredTextReference`（×2）**不是异常**。
2. **写后根本没有人读**：插在 `DeferredTextReference.GetValue` 里的 `Q8a/Q8b` **出现 0 次**；
   最后一次 `W1 GetValue(… "Text" target=TextBox#33cafbe)` 在 **L1405**，而**首次写**在 **L1626**
   （读 **早于** 写 200 余行）⇒ "DP 未变"这句话**没有写后读数支撑**。
3. **那批 `changes=0` 采样全部在注入之前**：18 条 `WFP_TEXTWATCH` + 2 条台账**止于 L1412**，
   而首条 `KEY_DIAG` 在 **L1492**（采样预算 `_watchLogs++ < 18`、400ms 间隔 ⇒ 窗口 ≈7.2s、止于 `t=17021ms`）；
   `LateVerify`(L599) 甚至**早于** `Verify`(L723-734)（`MainWindow.xaml.cs:77` 的 `Loaded→BeginInvoke(ContextIdle, VerifyAll)`
   被 ~10s 首帧拖到 6s 定时器之后）。

⇒ **结论口径（写死）**：**"无写后读数"= 无信息 ≠ 陈旧，也不等于回归**。`D-P1` 当前的正确表述是：
**"输入链已通到编辑器文档（`AB`+`Commit`），但 `Text` DP 在**写之后**是什么值，现有读数不能回答 ⇒ 该步未判定。"**

**装置侧这一问的答案（可判，本轮实测）**：本装置的读**是写后读**——
```
[a-裸WM_CHAR]             时序：注入@1103ms、读@2305ms；读前 TextChanged=1 ⇒ 写后读=是 ⇒ DP.Text="Aseed-文本" == 容器
[i-嵌套根+真ctrlA+type]   时序：注入@3561ms、读@5492ms；读前 TextChanged=2 ⇒ 写后读=是 ⇒ DP.Text="ABseed-文本" == 容器
```
（装置里新增的口径读数：`注入@ms / 读@ms / 读前 TextChanged`；`TextChanged>0` 表示写已发生、`读时刻>注入时刻`表示读在其后。）
⇒ **装置与应用的差别可能根本不存在**：装置在"写后读"下 `DP.Text` **等于**容器（10 档全绿），
而应用侧那批读**全在写前** ⇒ **两者的读数不可比**。因此本报告必须并列两种可能，**(ii) 由 T1c 的新探针裁决**：
- (i) 应用侧**确实**存在"写后 DP 陈旧"（真缺陷，只是从未被正确测量）；
- (ii) 应用侧**不存在**该缺陷 ⇒ `D-P1` 是**观测口径失效**（原始结论作废），而不是缺陷。

**下一读数（不要重复造探针）**：T1c 已获批在 `TextBox.OnTextContainerChanged` 末尾 `base(...)` **之后**读一次 `this.Text`
（独立开关、缺省关；**无写后读数一律 `无信息 rc=3`**）⇒ 那条读数一到，本节即可定为 (i) 或 (ii)。
我在装置侧**只做确认/重取**（本轮已完成：写后读 ⇒ DP == 容器）。

## 4.8.2 `D-K1` 升为 **已证（应用侧）**，且修法**已落源码**
条件已满足（T3 原文）：`state=0x4`(ControlMask) 的那次被 `[KEY_DIAG] DROP WM_CHAR 原因：Ctrl 组合不产字符（Win32 语义：Ctrl+A 应是全选）`
明确丢弃；`keycode=37`(Control_L) 那次 `state=0x0 ksChar=0xffe3`（非单字符）
⇒ **X 层知道 Ctrl 按下，而托管侧 `GetKeyState` 恒 0** 这条矛盾**在应用里成立** ⇒ **状态：已证（应用侧）**。
（副产物：`sel=0,7` 与块自己 `Verify()` 的 `SelectAll()` 同值 ⇒ **不能**当"注入的 Ctrl+A 生效"的证据，与 §4.6.1 一致。）

**修法（源码已定，未构建/未安装）**：`src/WpfGfx.Linux.Native/src/`
| 文件 | 改动 |
|---|---|
| `win32_internal.h` | `g_wpf` 新增 `uint8_t key_state[256]`（Win32 `GetKeyboardState` 布局：bit7=按下、bit0=toggle）+ 两个落表函数声明 |
| `win32_x11.c` | 新增 `wpf_keystate_note_key()`（按 VK 记按下/抬起 + 锁定键 toggle 沿）与 `wpf_keystate_sync_modifiers()`（用 `ev.xkey.state` **覆盖式**同步 Shift/Control/Alt/Super/Lock/Num）；在 `KeyPress/KeyRelease` 分支各调一次 |
| `win32_core.c` | `GetKeyState` 读表（高位=按下、低位=toggle）；`GetAsyncKeyState` 同源；**顺手补上此前完全缺失的 `GetKeyboardState`** |
- sha16：`win32_core.c 07a7ef58402122af`、`win32_x11.c 4ac491b91d8d9a6b`、`win32_internal.h 3ce7b663aac79cd5`；两份文件 `-fsyntax-only` **0 警 0 错**（未产出 `.o`/`.so`）。
- **已知简化（如实登记）**：X11 掩码分不出左右 ⇒ 只落通用 `VK_SHIFT/VK_CONTROL/VK_MENU`（WPF 实际查询的就是这三个），左右专有 VK（0xA0..0xA5）暂不区分。

## 4.8.3 两条**能变红的牙**（修法前实测：**都红**；修后应自动变绿）
```
失败 DP1_牙1_CtrlA全选      [牙1 红] `Ctrl+A` **没有全选**：selLen=0（期望 7） ⇒ GetKeyState(VK_CONTROL) 仍恒 0（D-K1 未修）
   [牙1] xdotool key --window 0x20000a ctrl+a → exit=0 ｜ xdotool type --window … AB → exit=0
失败 DP1_牙2_ShiftLeft扩选  [牙2 红] `Shift+Left` **没有扩选**：selLen=0（期望 1）、selStart=2、caret=2 ⇒ 修饰键位仍为 0
   [牙2] caret=3/无选区 → xdotool key --window 0x20001a shift+Left → exit=0     ← caret 3→2：**Left 本身有效**，只是 Shift 位为 0
测试总数: 14   通过数: 12   失败数: 2       （其余 12 条 = 闸门 + 10 档"不复现"变体，仍全绿）
```
⇒ **"源已定"**：等主控把它与 T2b/T1d 合并成一趟波（重编 shim + 重冻 #8）后，我复跑 `~DP1_牙1`/`~DP1_牙2` 应
**自动变绿**（测试无需改动）；`~DP1_i` 亦应从 `"ABseed-文本"` 变为 `"AB"`。

---

# §4.9 波 19 取证：**两条牙仍红 —— 但它们红得对（修法不完整）**

## 4.9.1 本轮读数（`DISPLAY=:96` 自起自收；件：shim `b2301ee237e72e5c`／桥 `759a322431f1e457`／PC `ebf4cf872c76e4a1`／PF `3136f66563f858cd`）
```
失败 DP1_牙1_CtrlA全选   [牙1 红] `Ctrl+A` 没有全选：selLen=0（期望 7）        ← 修前也是 0
失败 DP1_牙2_ShiftLeft扩选（仍在跑批中同口径）
失败 DP1_API_GetKeyboardState可用
 [API] keydown ctrl → exit=0
 [API] 按住中：GetKeyState(0x11)=0x0000；GetKeyboardState ok=True [0x11]=0x00     ← **反相！**
 [API] keyup   ctrl → exit=0
 [API] 松开后：GetKeyState(0x11)=0x8000；GetKeyboardState ok=True [0x11]=0x80     ← **松开后反而置位**
测试总数 15 / 通过 12 / 失败 3        （其余 12 = 闸门 + 10 档"不复现"变体，**未被 native 改动影响** ✓）
```
**正面读数**：`GetKeyboardState` 这条**此前完全缺失**的导出**已可用**（`ok=True`，且松开后表里确实有值）⇒ 修法的"落表 + 导出"这一半到位。

## 4.9.2 反相的根因（读码，已修）
- `keysym_to_vk()` 对修饰键给的是**左右专有 VK**：`XK_Control_L → 0xA2`、`Shift_L → 0xA0`、`Alt_L/Menu → 0xA4`、`Super_L → 0x5B`。
- 而 WPF 查的是**通用 VK**：`VK_SHIFT 0x10` / `VK_CONTROL 0x11` / `VK_MENU 0x12`
  （`HwndKeyboardInputProvider.cs:667/673/679`）⇒ **只记专有位 = 通用位永远为 0**；
  通用位只能被 `sync_modifiers(ev.xkey.state)` 碰，而 `state` 掩码在"修饰键自己的 KeyPress"上是**按下前**的值、
  在 KeyRelease 上又常带**陈旧**掩码（xdotool 会带上）⇒ 于是"按住读到 0、松开读到 0x80"的**反相**。
- **修法（源码已落，未构建）**：新增 `wpf_vk_generic()`，`note_key()` **专有位与通用位一起更新**
  （顺序仍是"先 `sync_modifiers` 再 `note_key`" ⇒ 本次事件对自身修饰位的结论**以释放/按下为准**，
  不会被同一事件里的陈旧掩码覆盖）。`win32_x11.c` sha16 `4ac491b91d8d9a6b → **d6e8f1a953869028**`，`-fsyntax-only` 0 警 0 错。

## 4.9.3 结论与下一波预期
- **两条牙拒绝变绿 = 正确行为**：它们证明的是"修饰键语义与 Windows 一致"，而波 19 的修法**不完整**（专有位/通用位没对齐）
  ⇒ 这正是"牙必须能红"的价值：**不完整的修法过不了牙**。
- 下一波（含本次 `wpf_vk_generic` 补丁）后预期：
  `[API] 按住中：GetKeyState(0x11)=0x8000；[0x11]=0x80`、`松开后 = 0x0000 / 0x00`；
  `~DP1_牙1` 绿（`selLen==7`）、`~DP1_牙2` 绿（`selLen==1`）、`~DP1_i` 由 `"ABseed-文本"` 变 `"AB"`。
- **跨配置提醒（已遵守）**：本轮 `PC/PF/shim/桥` 四位全变 ⇒ 12 档读数只与**同一配置内**的其他档比较（本报告所有比较均同轮同配置）。
- `D-P1` 的写后读数仍由 T3 的样例侧 `WFP_POSTWRITE` 提供（我**不**重复造同类探针）；装置侧"**写后读**"的事实表述不变
  （`注入@ms / 读@ms / 读前 TextChanged`，见 §4.8.1）。

---

# §4.10 波 20 取证：**API 牙变绿且极性正确；两条行为牙仍红 ⇒ 第二次"修法不完整"（根因已定位，补丁已落源码）**

## 4.10.1 本轮读数（shim `e41048f8786d6bc8`／桥 `759a322431f1e457`／PC `ebf4cf872c76e4a1`／PF `3136f66563f858cd`；`:96` 自起自收）
```
已通过 DP1_API_GetKeyboardState可用
 [API] keydown ctrl → exit=0
 [API] 按住中：GetKeyState(0x11)=0x8000；GetKeyboardState ok=True [0x11]=0x80     ← **极性正确** ✓
 [API] keyup   ctrl → exit=0
 [API] 松开后：GetKeyState(0x11)=0x0000；GetKeyboardState ok=True [0x11]=0x00     ✓

失败 DP1_牙1_CtrlA全选     [牙1 红] `Ctrl+A` 没有全选：selLen=0（期望 7）
失败 DP1_牙2_ShiftLeft扩选 [牙2 红] `Shift+Left` 没有扩选：selLen=0（期望 1）、selStart=2、caret=2   ← Left 有效、Shift 位未被 WPF 看到
[i-嵌套根+真ctrlA+type]   DP.Text="ABseed-文本"（期望 "AB"）；时序：注入@1266ms、读@3115ms、读前 TextChanged=2 ⇒ 写后读=是
12 档判定：全部"不复现（DP 已更新）" ✓（native 改动未波及）
测试总数 15 / 通过 13 / 失败 2
```
⇒ **`GetKeyState`/`GetKeyboardState` 在"单独查"时已经正确**，但 **WPF 在"派发期"查到的仍不对**。

## 4.10.2 第二次不完整的根因：**整批抽干（batch drain）**
装置里 `xdotool key --window <hwnd> ctrl+a` 产生 4 个 X 事件，它们的 `state` 掩码是：
`Ctrl↓ state=0x0` → `a↓ state=0x4` → `a↑ state=0x4` → `Ctrl↑ state=0x0`
（这正是我们 `[KEY_DIAG] KEY … state=0x…` 打印的那一列）。而**翻译层一次泵就把这 4 个事件全部抽干**，
消息**之后**才被逐条派发 ⇒ 到 WPF 处理 `a↓` 那条 `WM_KEYDOWN` 时，**实时状态表已经被 `Ctrl↑` 清掉** ⇒
`GetKeyState(VK_CONTROL)` 返回 0 ⇒ `Keyboard.Modifiers` 无 Ctrl/Shift ⇒ 命令不触发、扩选不发生。
**这解释了"API 单独查对、派发期查错"的全部读数**（含波 19 的反相：那种情形下读到的是**最后一个**事件的状态）。

## 4.10.3 修法（**源码已落，未构建**）：逐消息修饰键快照
| 文件 | 改动（sha16） |
|---|---|
| `win32_internal.h` | `wpf_msg_node` 新增 `uint8_t mods`（**不动 `WPF_MSG`**：那是与托管 `MSG` 的跨边界布局，加字段会越界写）+ 4 个快照 API 声明（`106b0f3eaf281a1b`） |
| `win32_x11.c` | `wpf_keystate_event_mods(x_state, vk, is_up)`：算"**事件时刻**"的 4 位修饰位（并对修饰键自身做按下/抬起修正，因为 X 的 `state` 是"事件处理前"的值）；`KeyPress/KeyRelease` 里 `wpf_keystate_set_push_mods(...)` ⇒ **随消息带走**（`7e200e620068fbb7`） |
| `win32_msg.c` | 入队时把 mods 盖到节点；出队时记 `s_pop_mods`；`DispatchMessageW` 期间暴露为"派发快照"；并新增诊断行 `[MSGFLOW] dispatch msg=… 快照修饰位=0x… （实时表 ctrl=… shift=… alt=…）`（`c5ebe97b1c8122d4`） |
| `win32_core.c` | `GetKeyState`：**正在派发时优先读快照**（修饰键 VK 全系：`0x10/0xA0/0xA1`、`0x11/0xA2/0xA3`、`0x12/0xA4/0xA5`、`0x5B/0x5C`）；非修饰键与"非派发期"仍走实时表（`e4e3871da75a76db`） |
四份文件 `-fsyntax-only` **0 警 0 错**（未产出 `.o`/`.so`）。

## 4.10.4 下一波预期读数（照旧不改测试）
- `~DP1_API_GetKeyboardState可用` 保持绿（极性正确）；
- `[MSGFLOW] dispatch …,vk/wp=0x41 … 快照修饰位=0x2（实时表 ctrl=0…）` ⇒ **直接证明"快照≠实时表"**（这是本修法的取证行）；
- `~DP1_牙1` 绿（`selLen==7`）、`~DP1_牙2` 绿（`selLen==1`）、`~DP1_i` 的 `DP.Text=="AB"`；
- 12 档"不复现"保持不变。

---

# §4.11 波 21 取证：**API 牙绿；两条行为牙仍红 ⇒ 第三次"修法不完整"，但这次取证行把机制钉死了**

**本轮 tuple（不跨配置比）**：shim `39d343c801f12d0c`（278,752 B）／桥 `759a322431f1e457`／PC `ebf4cf872c76e4a1`／PF `3136f66563f858cd`；`:96` 自起自收。

## 4.11.1 读数
```
已通过 DP1_API_GetKeyboardState可用   按住 0x8000/[0x11]=0x80；松开 0x0000/0x00   ✓（极性正确，保持）
失败 DP1_牙1_CtrlA全选     selLen=0（期望 7）
失败 DP1_牙2_ShiftLeft扩选 selLen=0、selStart=2、caret=2（期望 1）
[i-嵌套根+真ctrlA+type]   DP.Text="ABseed-文本"（期望 "AB"）
12 档：全部"不复现（DP 已更新）" ✓        测试总数 15 / 通过 13 / 失败 2
```

## 4.11.2 **决定性证据行**（本轮新诊断的价值）
```
[MSGFLOW] dispatch msg=0x0100(?) vk/wp=0x41 快照修饰位=0x0（实时表 ctrl=0 shift=0 alt=0）
[MSGFLOW] dispatch msg=0x0101(?) vk/wp=0x41 快照修饰位=0x0（实时表 ctrl=0 shift=0 alt=0）
[MSGFLOW] dispatch msg=0x0100(?) vk/wp=0xa2 快照修饰位=0x0（实时表 ctrl=0 shift=0 alt=0）   ← **Ctrl 自己的 KeyDown 也是 0**
[MSGFLOW] dispatch msg=0x0100(?) vk/wp=0x41 快照修饰位=0x0（实时表 ctrl=0 shift=0 alt=0）
```
⇒ 节点上**明明盖了戳**（`0xa2` 的 KeyPress 会算 `0x2`），派发期却是 `0x0` ⇒ **"记住最后一条出队的消息"这个传递机制不成立**：
出队 → 派发之间**还有别的出队**（托管泵会成批取消息；同一进程里也可能有别的线程取），"最后一条"被覆盖。
**注意**：这**不是** VK 映射问题（`[API]` 牙绿说明映射与极性已正确），是**快照传递**问题。

## 4.11.3 修法（源码已落，未构建）：**按消息四元组登记的环形表**
| 文件 | 改动（sha16） |
|---|---|
| `win32_internal.h` | 出队登记改为 `wpf_keystate_note_pop_mods(const WPF_MSG*, uint8_t)`；新增 `wpf_keystate_lookup_mods(const WPF_MSG*, uint8_t*)`（`cb893e8a57d4d30f`） |
| `win32_msg.c` | 16 项环形表 `(hwnd,msg,wParam,lParam,mods)`：出队时登记、**派发期按四元组从最新往回查**（查不到 ⇒ 不标记 valid ⇒ `GetKeyState` 回退实时表）；`pop` 诊断行新增 **`该消息快照修饰位=0x%x`** ⇒ 下一跑给出"pop 快照 → dispatch 快照"完整链（`83cab6b717ccaba9`） |
| `win32_core.c` / `win32_x11.c` | 未再改（`e4e3871da75a76db` / `7e200e620068fbb7`） |
四份 `-fsyntax-only` **0 警 0 错**。

## 4.11.4 三次"修法不完整"的过程事实（主控要求入册，这是"牙必须能红"最有价值的产出）
| 轮 | 我当时的判断 | 牙给出的读数 | 真实原因 |
|---|---|---|---|
| 波 19 | "落表 + 读表"就够 | 牙1/牙2 仍红；`[API]` **反相**（按住 `0x0000`、松开 `0x8000`） | **专有位 `0xA2` vs 通用位 `0x11`**：只记了左右专有 VK，而 WPF 查通用 VK |
| 波 20 | "逐消息快照"就够 | 牙仍红；`dispatch … 快照=0x0`（连 Ctrl 自己的 KeyDown 都 0） | **"最后一条出队"会被覆盖**：出队→派发之间还有别的出队 |
| 波 21 | 四元组环形表（本轮） | 待验证 | —— |
**三条牙（`~DP1_牙1`／`~DP1_牙2`／`~DP1_API…`）的测试代码从未被修改过** —— "修好自动变绿"这条性质因此是可信的。

## 4.11.5 下一跑预期（测试不改）
`pop … **该消息快照修饰位=0x2**`（Ctrl 的 KeyDown）与 `dispatch … 快照修饰位=0x2`（同一四元组）**配对出现**，
**同时** `实时表 ctrl=0`（因为整批抽干已经发生）⇒ 这一对就是"快照 ≠ 实时表"的直接证据；
随后 `~DP1_牙1` 绿（`selLen==7`）、`~DP1_牙2` 绿（`selLen==1`）、`~DP1_i` 的 `DP.Text=="AB"`。
若仍红 ⇒ 第四次不完整，照修（但本轮取证行会指出是"登记侧"还是"回查侧"出错）。

---

# §4.12 波 22：**矛盾已定位 —— 是装置的注入口径，不是 shim**；三条牙 + 16 用例**全绿**

**本轮 tuple（同轮同配置，不跨配置比）**：shim `91baee84270f2322`（278,840 B）／桥 `759a322431f1e457`／
**PC `6be29475b6aeb34e`（wave 21 已重建）**／PF `3136f66563f858cd`；`:96` 自起自收。

## 4.12.1 矛盾定位：**同一 shim、两个结论都为真 —— 差别在"泵的纪律"**
| 侧 | 注入方式 | 泵的纪律 | 结果 |
|---|---|---|---|
| **T3 的应用** | `xdotool key --window <id> ctrl+a` + `type AB` | **常驻泵**：事件到达即处理（`xdotool` 的 4 个事件之间有真实间隔） | **Ctrl 可见** ⇒ `TextChanged #1 text='A'`、`#2 text='AB'`（**替换**语义）✓ |
| **我的装置（旧口径）** | 同上**一条命令**，然后才 `Pump()` | **单线程、注入后一次泵** ⇒ 4 个 X 事件**整批抽干**，消息之后才逐条派发 ⇒ 派发 `a↓` 时实时表已被 `Ctrl↑` 清掉 | Ctrl 不可见 ⇒ `"ABseed-文本"`（插入）✗ **装置伪影** |

**A/B 证据（本轮实测，同一装置、同一 shim）**：
```
[i-嵌套根+真ctrlA+type]  DP.Text="ABseed-文本"     ← 一条命令后泵（整批）⇒ 插入
[i2-真ctrlA+分步泵]      DP.Text="ABseed-文本"     ← 命令之间泵，但 4 个事件已在队列里 ⇒ 仍是整批
已通过 DP1_牙1_CtrlA全选  ← **按事件泵**：keydown ctrl→泵→key a→泵→keyup ctrl→泵 ⇒ **绿**
已通过 DP1_牙2_ShiftLeft扩选 [牙2] selLen=1（期望 1）selStart=2 caret=2
```
⇒ **"装置里 Ctrl 到不了窗口"= 装置的注入/泵纪律问题**（不是 `PostMessage` 也不是焦点）：**唯一区别是"事件之间是否泵"**。
这正是主控要求的口径修正；**两条牙的断言一字未改**（只把注入改成"一事件一泵"），改后**自动变绿** ✓。

## 4.12.2 本轮结果（16 用例全绿）
```
已通过 DP1_牙1_CtrlA全选 ／ DP1_牙2_ShiftLeft扩选 ／ DP1_API_GetKeyboardState可用
 [API] 按住中：GetKeyState(0x11)=0x8000；GetKeyboardState ok=True [0x11]=0x80   ← 极性正确
 [API] 松开后：GetKeyState(0x11)=0x0000；GetKeyboardState ok=True [0x11]=0x00
12 档"不复现"全部保持 ／ 测试总数 16 ／ 通过 16 ／ 失败 0
[MSGFLOW] pop … **该消息快照修饰位=0x0** 行已上线（配对读数见 §4.12.3）
```

## 4.12.3 `D-K1` 的**结论与登记更正（必须如实收敛严重性）**
- **真实缺陷（已修）**：`GetKeyState` 原本是 `return 0` 的桩、`GetKeyboardState` 导出根本不存在
  ⇒ **shim 侧完全没有修饰键语义**。API 级牙已证修好（极性正确）。
- **但"所有快捷键失效"这个影响面写重了**：真应用是**连续泵**（T3 实测 Ctrl+A 生效、我的按事件泵装置也绿）
  ⇒ 修饰键在真应用里**可见**。**正确表述**：该桩导致"**依赖 `GetKeyState` 时序的调用方**（批处理型泵 / 嵌套泵 /
  跨线程取消息 / 一次性注入 4 个事件的客户端）看不到 Ctrl/Shift/Alt"；真应用连续泵下不受影响。
- 本轮的快照/环形表补丁因此**不是"让应用能用"的必需项，而是"让批处理型调用方也正确"的稳健性修补**（保留，登记为稳健性）。
- **待办（更正后）**：`KNOWN-DEFECTS.md` 的 `D-K1` 影响面已按此收敛；`D-P1` 与 `D-K1` 仍是两条独立缺陷。

## 4.12.4 下一跑
等在 wave 21/22 的 PC/PF 落定后复跑一次（口径已固定为"按事件泵"）：预期 16 绿不变；
`pop … 该消息快照修饰位=0x2` 与同四元组的 `dispatch … 快照修饰位=0x2` 配对出现（在整批场景下才显出与实时表的差异）。

---

# §4.13 波 23：主控要的"快照 vs 实时表"配对读数（**整批场景**）—— 配对出现了，但预期后果**没**出现

**本轮 tuple**：shim `91baee84270f2322`／桥 `759a322431f1e457`／PC `6be29475b6aeb34e`
（这三条由本轮闸门**实测相等**，原文见 §4.13.1 末）；PF `50da85138a7bc3e8`／WB `e6216fe961a2bfb9`
（**取自冻结哨兵 `/tmp/bridge-frozen.flag`**，本轮闸门输出被 `head -8` 截断、未见 PF 行，故不冒充本轮实测）。
`:96` 自起自收（Xvfb 已按 PID 收掉）；sha 复读时间 `2026-09-14 09:58:38`。

## 4.13.1 取数口径（"报 0 ≠ 不存在"这条教训的现场应用）
第一次在**全量 16 用例**里开 `WPF_LINUX_MSGFLOW_TRACE=1` 时，整批两档（`DP1_i`／`DP1_i2`）只见
`pop msg=256 … 快照修饰位=0x0` 且找不到 `vk/wp=0xa2` 的 `dispatch` 行 ⇒ 看上去像"整批场景根本没有快照"。
**本轮改成只跑整批两档**（`--filter "FullyQualifiedName~DP1_i"`，实跑 **2** 用例、`rc=0`）、同一 shim、同一开关
⇒ 同一次运行里 `MSGFLOW` 行数 **306**、**无截断提示** ⇒ 之前的"缺失"是**同一次运行内的取数条件（用例先后／行预算）造成的缺口**
（**两者孰因未逐条证**：全量那跑的行数/截断提示本轮没有复测），不是"不存在"。
**口径结论**：整批场景的配对读数必须**单独跑该档**才取得到。

## 4.13.2 配对原文（本 run **只含** `DP1_i2_真ctrlA_分步泵` 与 `DP1_i_嵌套根_真ctrlA_再typeAB` 两档）
```
[MSGFLOW] pop api=GetMessageW msg=256(0x0100 ?) hwnd=0x200002 剩余=3 **该消息快照修饰位=0x2** 队列内容=[0x0100,0x0101,0x0101] 共3 …
[MSGFLOW] dispatch msg=0x0100(?) vk/wp=0xa2 快照修饰位=0x2（实时表 ctrl=0 shift=0 alt=0）   ← Ctrl↓
[MSGFLOW] dispatch msg=0x0100(?) vk/wp=0x41 快照修饰位=0x2（实时表 ctrl=0 shift=0 alt=0）   ← a↓（同一批）
[MSGFLOW] dispatch msg=0x0101(?) vk/wp=0x41 快照修饰位=0x0（实时表 ctrl=0 shift=0 alt=0）   ← a↑
[MSGFLOW] dispatch msg=0x0101(?) vk/wp=0xa2 快照修饰位=0x0（实时表 ctrl=0 shift=0 alt=0）   ← Ctrl↑
```
- **"整批"本身有量**：`pop … 剩余=9 … 队列内容=[0x0100,0x0102,0x0101,0x0101,0x0100,0x0100,0x0102,0x0101] 共9（只显示前 8 条）`、`剩余=5 共5`、`剩余=4 共4`
  ⇒ 一次泵里队列压着 **9** 条 ⇒ "整批抽干"成立。
- **Shift 同样逐消息正确**：`xdotool type AB` 的大写需要 Shift ⇒ `dispatch msg=0x0100 vk/wp=0xa0 快照修饰位=0x1` 紧接 `msg=0x0100 vk/wp=0x41 快照修饰位=0x1`（实时表 `shift=0`）。
  （本 run 那 4 组 `0xa0`／`0x42` 派发**不是**别的档跑进来的：本轮过滤器只放行 2 档，且 i 档第二步就是 `type AB`。）
- 本 run 计数（`grep -c` 整行匹配）：`pop api=GetMessageW msg=256` = **12** 行；`dispatch msg=0x0100` = **11** 行。
- 闸门原文（同轮）：`权威件 91baee84270f2322 /src/WpfGfx.Linux.Native/bin/libwpfwin32.so`、`被测件 91baee84270f2322 …`、
  `桥权威件 759a322431f1e457 …publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`、`桥副本 759a322431f1e457 …`、`PC PresentationCore.dll: 被测 6be29475b6aeb34e／权威 6be29475b6aeb34e`。

## 4.13.3 这一对读数**证明了什么**（对照 §4.11.5／§4.12.4 的预期）
- 预期原文：`pop … 快照=0x2` 与同四元组的 `dispatch … 快照=0x2` **配对出现，同时实时表 `ctrl=0`** ⇒ **本轮如实出现** ✓。
- ⇒ **"整批 ⇒ 快照为 0／修饰键到不了 `GetKeyState`"这条机制被本轮读数否掉**：在 `a↓` **派发的那一刻**，回查侧给出的就是 `0x2`（Ctrl 按下）。
- 即：**主控问的那一对"快照 vs 实时表"，在整批场景里确实同时为真**（`0x2` vs `ctrl=0`），且快照侧是**每消息正确**的（KeyDown `0x2`／KeyUp `0x0`，Shift `0x1`／`0x0`）。

## 4.13.4 但**没有**证明什么（不许顺手升级成结论）
同一次运行里，整批两档的**结果仍然是插入**：
```
[i2-真ctrlA+分步泵]     IsKeyboardFocused=True selLenBefore=0 selLenAfter=0 TextChanged=2  DP.Text="ABseed-文本" 容器="ABseed-文本" 判定=不复现（DP 已更新）
[i-嵌套根+真ctrlA+type] IsKeyboardFocused=True selLenBefore=0 selLenAfter=0 TextChanged=2  DP.Text="ABseed-文本" 容器="ABseed-文本" 判定=不复现（DP 已更新）
```
种子 `Seed = "seed-文本"`（7 字符，`DP1ReproTests.cs:46`），`"ABseed-文本"` = `AB` **插在光标处**而非替换 ⇒ **命令没生效**。
⇒ **"派发时读到 `0x2`" 与 "`Ctrl+A` 没生效" 同时为真。**
所以 §4.12.1 表里那句机制归因（"派发 `a↓` 时实时表**已被 `Ctrl↑` 清掉**"）**只能解释 `实时表=0`，解释不了"命令没生效"**
—— 回查侧修好之后整批档**依旧不生效** ⇒ **失败环节不在"派发时的修饰位"这一格**。原文保留（不改历史），按本轮读数**收窄**。
两个候选（**都还没有读数支持，禁止当结论**）：
1. WPF 读修饰位的**时刻**不在消息派发之内（例如泵循环/预处理阶段读表，那时实时表已是 0）；
2. 整批场景另有**下游**原因（与修饰位无关）。
**判这一格只需再取一条读数**：给 `GetKeyState` 加"调用时刻 + 是否在 `dispatch` 中 + 返回位"的逐次日志，在整批档里数次数与时刻 ⇒ 一跑即可二选一。

## 4.13.5 对 `D-K1` 影响面的净效果（不夸大、不削弱）
- 原始缺陷（`GetKeyState` 返回 0 的桩 + 无 `GetKeyboardState`）与**真应用不受影响**的收敛**不变**（真应用是连续泵；牙1/牙2 按事件泵全绿）。
- 修好之后的**稳健性**结论按本轮读数**加强一格**：整批型调用方在**派发时**也能拿到正确的 `Ctrl`／`Shift` 位（`0x2`／`0x1`）。
- 但"**整批型调用方在本装置下 `Ctrl+A` 不生效**"这一**可观测事实仍在**、且环节**未定位** ⇒ 在定位之前，`KNOWN-DEFECTS.md` 的 `D-K1` 影响面**保持已收敛的写法不动**，只在该节标题下追加本条读数指针。

## 4.13.6 12 档方向性判定不受影响（同一 tuple：**16 通过／0 失败**）
整批两档结果与 §4.12 逐字一致（`selLenAfter=0`、`DP.Text=="ABseed-文本"`、`判定=不复现（DP 已更新）`）；
同一 tuple 另跑的 16 用例全景 `已通过! - 失败: 0，通过: 16，已跳过: 0，总计: 16` ⇒ **12 档方向性判定未变**。
**口径提醒（本轮新增，不改任何已登记判定）**：整批两档的 `DP.Text == 容器` 是在 `selLenAfter=0`（注入**未**产生替换）的背景下取得的
—— 它仍说明"DP 跟着容器走"（`TextChanged=2` ⇒ 文本确实被写过，非空真），但**强度低于**牙1（`selLen==7`、`Text=="AB"` 的整链断言）。
**D-P1 的强证据仍只能由牙1/牙2 与 T3 侧 `WFP_POSTWRITE` 承担**；整批 12 档是旁证。此条只调整**证据权重**的归属，**不削弱**任何断言。

---

# §4.14 波 24：§4.13.4 的"未定位"**已定位** —— 失败环节 = "**WPF 在派发之外读表**"（候选① 成立）

> ⚠️ **配置标注**：本节读数取自 **私有 shim `aebfdaced7149c35`**（≠ 权威 `91baee84270f2322`）⇒ **跨配置，只用于定位机制，
> 不得写进基线、不得当验收**；桥 `759a322431f1e457`／PC `6be29475b6aeb34e`／PF `50da85138a7bc3e8`／WB `e6216fe961a2bfb9` 未动。
> 逐次调用原文、仪器口径与修法候选见 **`build/MilBridge/M7b-keystate-probe-report.md` §8**（含仪器自身的离线三态牙）。

## 4.14.1 一句话
整批档 `Ctrl+A` 不生效的原因**不是**"快照没登记到"，而是 **WPF 的修饰键读取全部发生在 `DispatchMessageW` 之外**：
两档合计约 500 次 `GetKeyState` 调用里 **`在dispatch中=是` 的行数 = 0**（判别器本身已由离线三态牙证明可用）。
于是决定成败的只有"**读取那一刻实时表里是什么**"：按事件泵档 `实时表 ctrl=1` ⇒ `返回=0x8000`（牙1 绿）；
整批档 `实时表 ctrl=0` ⇒ `返回=0x0000`（插入、`selLenAfter=0`）。

## 4.14.2 配对原文（同一窗口内，`t` 可直接对齐）
```
[KEYSTATE] #6  GetKeyState vk=0xa2(VK_CONTROL) 返回=0x0000 在dispatch中=否 快照=无(0x0) 实时表字节=0x00 实时表 ctrl=0 shift=0 alt=0 t=154732148ms
[MSGFLOW]  dispatch msg=0x0100(?) vk/wp=0xa2 快照修饰位=0x2（实时表 ctrl=0 shift=0 alt=0）t=154732149ms
[MSGFLOW]  dispatch msg=0x0100(?) vk/wp=0x41 快照修饰位=0x2（实时表 ctrl=0 shift=0 alt=0）t=154732150ms
[KEYSTATE] #44 GetKeyState vk=0x11(VK_CONTROL) 返回=0x0000 在dispatch中=否 快照=无(0x0) 实时表字节=0x00 … t=154732150ms
```
⇒ **同一毫秒里**：`dispatch` 手上是 `快照=0x2`，而 WPF 读到的是 `实时表=0x0000` —— 因为读**不在派发里**。

## 4.14.3 两档对照（决定性那一条差）
| | 整批档 | 按事件泵档（牙1） |
|---|---|---|
| `vk=0x11` 在注入窗口的返回 | `0x0000`（`实时表 ctrl=0`） | `0x8000`（`实时表 ctrl=1`） |
| `a↓`（`0x0100/wp=0x41`）派发行数 | 4 | **1**（= `type AB` 的 Shift+A）⇒ `ctrl+a` 的 `a↓` **被输入路径消费、根本没进派发** |
| 结果 | `DP.Text="ABseed-文本"`（插入） | `DP.Text="AB"`、`selLen=7`（替换） |

## 4.14.4 对 §4.13 三条结论的处置（**加强，不削弱**）
- §4.13.2 的配对（`快照=0x2` vs `实时表 ctrl=0`）**依然为真**，现在有了它的**作用域**：那是**派发期内**的事实，
  而 WPF 不在派发期读 ⇒ **该快照对 WPF 无效**。
- §4.13.4 的机制归因**再收窄一步**：不是"派发 `a↓` 时实时表被清掉"（那句默认了读取时刻=派发期），
  而是"**读取时刻在派发之前**，那时实时表早已被整批抽干推到最后一个事件的状态"。
- §4.12.1 表格里"装置伪影"的**结论不变**（整批注入确实让 Ctrl 不可见），**归因修正**为本节的预处理路径口径。
- **波 20/21 的快照补丁**：如实登记为"**在 WPF 这条路径上未生效的稳健性补丁**"（对"派发期读表"的调用方仍有效）。

## 4.14.5 待办（顺序不可颠倒）
1. **主控统一波**：重建 native + 同步 4 份副本（我的三个源 sha **保持不变**：`c026c6809f13c7b6`／`60e169ce8f6aee6f`／`029ac93a951a5be3`）。
2. **我在权威件上复取** §4 两档 ⇒ 确认 §4.14.1 的机制在**权威件**上一致（这是本节从"跨配置读数"上升为"结论"的前置条件）。
3. 之后由主控裁 keystate 报告 §8.3 的修法（甲/乙/丙）。

---

# §4.15 波 24 修法**乙**落地：整批两档**由"插入"变"替换"**（`DP.Text=="AB"`），牙1/牙2 仍绿

> ⚠️ **配置标注**：读数取自 **私有件 `5c709b8de57901e7`**（≠ 权威 `91baee84270f2322`）⇒ **跨配置，不得当验收**；
> 且该趟全量 16 用例里**唯一失败的正是 staleness 闸门**（`被测件 sha16=5c709b8de57901e7 != 权威件 sha16=91baee84270f2322`）——
> 闸门自己咬住了跨配置跑，**说明闸门有效**。实现细节/离线牙/口径限制见 `M7b-keystate-probe-report.md` §9。

**主控裁定**：走乙（实时表采纳 Win32 的**消息队列语义**：取出**按键类消息**时用该消息的 `mods` 覆盖修饰键位）。

## 4.15.1 行为判据（**测试代码一行未改**）
| 档 | 修法前（§4.13/§4.14） | **修法乙后（本轮）** |
|---|---|---|
| 整批抽干 `~DP1_i2` | `DP.Text="ABseed-文本"`（插入）、`selLenAfter=0` | **`DP.Text="AB"`**、`（泵 400ms，selLen=7）`、`判定=不复现` |
| 整批抽干 `~DP1_i` | `DP.Text="ABseed-文本"`（插入） | **`DP.Text="AB"`**、`判定=不复现` |
| 按事件泵 `~DP1_牙1` | 绿（`selLen=7`、`Text=="AB"`） | **仍绿**（回归护栏未破） |
| 按事件泵 `~DP1_牙2` | 绿（`selLen=1`） | **仍绿**（`selLen=1（期望 1）selStart=2 caret=2`） |
| `~DP1_API_GetKeyboardState可用` | 绿（极性正确） | **仍绿** |

## 4.15.2 逐行证据（`WPF_LINUX_KEYSTATE_TRACE_MAX=900`，**无触顶**）
```
[KEYSTATE] #6 GetKeyState vk=0xa2(VK_CONTROL) 返回=0x8000 在dispatch中=否 快照=无(0x0) 实时表字节=0x80 实时表 ctrl=1 … t=155122969ms   ← 修法前同窗口是 0x0000 / ctrl=0
[KEYSTATE] #20 GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=否 … 实时表 ctrl=1 …
[KEYSTATE] #28 GetKeyState vk=0x11(VK_CONTROL) 返回=0x0000 在dispatch中=否 … 实时表 ctrl=0 …（Ctrl↑ 出队之后）
[KEYSTATE] 汇总：本次运行共 312 次调用（修饰键 308 次，已打印 308 行；非修饰键 4 次按设计不打；GetKeyboardState 0 次）｜行上限 900
```
⇒ **"派发之外读表"这条路径现在读到的是"这条消息时刻"的修饰位**（= Win32 的队列语义），
而不是"最后一个 X 事件"的物理状态 ⇒ `Ctrl+A` 生效 ⇒ 替换。**两档注入窗口都在已打印范围内**（时间簇 `t=155214xxx` 与 `t=155217xxx`）。

## 4.15.3 待办
1. **主控统一波**：native 重建 + 同步 4 份副本（四个源的新 sha 见 keystate 报告 §9.1：`0de70e6b981e1a10`／`cff3189eff6c87eb`／`4e695881ef220a3b`／`c17a7c7541b096e0`）。
2. **我在权威件上复取** §4 两档 + 全量 16 用例 ⇒ 该节从"跨配置读数"升为**结论**，且闸门应为绿。
3. 若权威件上整批档**回红** ⇒ 按主控要求**立刻上报**（转丙，由主控裁，不叠第三层）。

---

# §4.16 **权威件复取（#9）⇒ 结论**：两档替换语义 + 全量 **16/0** + 闸门变绿

**tuple（#9，哨兵复读一致）**：桥 `759a322431f1e457`｜PC `e75c7bd5f465ede6`｜PF `52e106e5f46a0dbb`｜WB `e6216fe961a2bfb9`｜
Provider `71ba86c6495347fe`｜**win32shim `0098234982391bbf`**（283,648 B）｜WIC `03b67fbcd7c385b6`｜HBTL `4044d84a66539c42`｜DWF `2f77dbdf5e7e2cd5`。
**测试按仓库路径解析并加载权威件**（不再有 `WPF_LINUX_WIN32_SHIM` 覆盖）⇒ 本节读数**不是跨配置**。

| # | 判据 | 结果（权威件） |
|---|---|---|
| 1 | `~DP1_i`／`~DP1_i2` 替换语义 | **2/2 通过**：两档 `DP.Text="AB" 容器="AB"`；`i2`：`（泵 400ms，selLen=7）`；`判定=不复现（DP 已更新）` |
| 2 | `~DP1_牙1`／`~DP1_牙2`／`~DP1_API` | **3/3 通过**（断言未改）：`selLen=7（期望 7）`、`DP.Text="AB"（期望 "AB"）`、`selLen=1（期望 1）selStart=2 caret=2`、API 极性 `0x8000/0x80` → `0x0000/0x00` |
| 3 | 全量 `~DP1Repro` | **16 通过／0 失败**（`rc=0`）；**staleness 闸门绿**：`已通过 … 闸门_win32shim被测件与权威件同sha [129 ms]`，`权威件 0098234982391bbf` ＝ `被测件 0098234982391bbf` |
| 4 | 逐行 + 汇总 | 注入窗口 `GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=否 实时表 ctrl=1`，Ctrl↑ 后 `返回=0x0000 实时表 ctrl=0`；`汇总：共 312 次调用（修饰键 308 次，已打印 308 行）｜行上限 900`，**无触顶** |

**对照（同一套件、同一判据）**：私有件那一趟闸门**报红**且报得对（`**测的是旧件**：被测件 sha16=5c709b8de57901e7 != 权威件 sha16=91baee84270f2322`）
⇒ **闸门有效**；权威件到位后它变绿。全量跑**探针关** ⇒ `[KEYSTATE]` 行数 **0**（零开销路径成立）。

⇒ `D-K1` 第三支在本 tuple 上**收成结论**；`D-P1` 的判定**不因此改变**（仍等 T3 的 `WFP_POSTWRITE` 写后读数）。

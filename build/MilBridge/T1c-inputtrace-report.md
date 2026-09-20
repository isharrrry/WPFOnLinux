# T1c · 输入链只读插桩（WM_CHAR → TextInput）—— 报告 **v2**

> ## ⚠️ 命题已在第 3 批实跑后**改写**（读本报告先看这条）
> **键入到了、容器改了、屏幕也画出来了**；坏的是 **`TextBox.Text` 这个 DP（与 `TextChanged`）一直停在旧值**。
> ——**不是**「打字到不了 TextBox」（本报告标题与 §8 前几节沿用旧措辞，仅作历史记录）。
> **「键入腿」的判据也换了口径**：`changes>0` **降为旁证**；主判据 = **注入前后 `WFP_BOXID` 矩形内的像素/字形差异**。
> T3 补了**注入后帧**（此前两趟 burst 都在注入之前）⇒ 它那条「屏幕还是旧文本」的读数**已作废**；
> 注入后帧里 TextBox 就是 `AB` 加光标。第 4 批（§10）钉的是 **Changed → Text DP** 这条推值链。
> **流程要求（第 5 批起生效）**：**预测 sha 只证「生成器确定」、`--prove` 只证「插入是纯插入」——两者都证明不了「能编过」。**
> 凡新增/改动 `WpfLinux*Trace` 调用点，必须过一遍 `build/MilBridge/tools/t1c-trace-args-scope.py`
> （机械审计「实参在调用点作用域内」），并在报告里写明「**仍未编译**」。第 5 批第一版就是被集成波的构建步骤抓住 CS0103 的。
> **键入腿口径（第 5 批时点，T3）**：像素键入腿的**三极性牙已 PASS**；但 `D-P1` 记为 **INCONCLUSIVE**（**不是 PASS**）
> —— 正好演示「**不许用画得对冒充读得对**」：渲染/像素对了，不代表 `.Text` 这个**读侧**对了（读侧由本报告 §10/§11 负责）。


> **v2 改了三点**（都在**源码**里，**本轮没有生成物、没有重建 PC、没有跑应用** —— 由主控统一重放）：
> 1. **新增 H0：`HwndSource.OnPreprocessMessage` 的所有早退门之前**（`HwndSource.Linux.cs:1927`，上游 `HwndSource.cs:1778-1781` 那段焦点门**之前**）。
>    `HasFocusWithin()` **惰性**求值（只在插桩开着时才问）⇒ 关掉时零代价、语义不变。
> 2. 原来那条"WM_CHAR 入口"改名成 **`入口(**过焦点门后**)`** —— 它其实在 `switch` 里、过了焦点门，**不能**用来回答"消息到底到没到"。
> 3. **新增 WindowsBase 应用器**：`Dispatcher.TranslateAndDispatchMessage` 的**托管侧出队读数**（`build/WindowsBase.Linux/Dispatcher.Linux.cs`，新文件 + csproj 接线）。
>
> **为什么必须加这两格**：`OnPreprocessMessage` 在 `switch` **之前**就有早退门 ⇒ 原来那条入口探针"没打印"有**三种**含义
> （没到 preprocess / 到了被焦点门挡 / 到了没进 switch），读数无法落格。加 H0 + 出队格后，"没字"被劈成**互斥四格**（§3）。
> `_eatCharMessages` 的**头号嫌疑降级**（§3.3）。

---

## 1. 交付物与 sha256（**重放前 / 重放后**分开写）

| 件 | 现在磁盘上 | **重放后应当是**（预测，见 §4.3） |
|---|---|---|
| 应用器 `tools/patch-presentationcore-inputtrace.py` **v2** | `4eac185d5ae049a8fca2a39d268b0cdb6272c11b4e29fd56f984570767fa1d34` | 不变（这就是要重放的那份） |
| **新**应用器 `tools/patch-windowsbase-msgflow.py` **v1** | `cf3c1d79312ccf34812a534749dcba1d302713af78768a50bdea1b0543817469` | 不变 |
| 生成物 `build/PresentationCore.Linux/HwndSource.Linux.cs` | `9408a44059ba5702c9e996fe4c1294696dbbe43599c1aba1da7d60ea8bb99eeb`（**v1，过时**） | `385a60142567785e4ff41b55998ad8f0c353a3ccbf343c05c1e9ee8cf916864f` |
| 生成物 `build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs` | `f56e647e21c29ef0211fe11f7cc6dfa7a8d43d48e1477d2fdf3d5cb3ba62ff95` | **不变**（v2 没动提供方任何一处） |
| **新**生成物 `build/WindowsBase.Linux/Dispatcher.Linux.cs` | 不存在 | `cbb971f5e18534434db7dc0256cd6db4f24ce0cf39dbf2219add252c44d43705` |
| csproj 接线 | `PresentationCore.Linux.csproj` `c9a5c8b5…` / `WindowsBase.Linux.csproj` `28e49ef1…` | PC：原 4 行不变；WB：**新注入 2 行**（§6） |

**重放命令**（各跑一次，均**幂等**）：
```
python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py     # --check 现在 rc=1（生成物是 v1）
python3 src/WpfGfx.Linux.Native/tools/patch-windowsbase-msgflow.py            # --check 现在 rc=1（生成物不存在 + 未接线）
```

**闸门（原始读数，`rc` 都不经管道取）**
```
PC 应用器 v2 --check（重放前）：rc=1；12 处锚点各**恰好 1 次**（含新增 H0）；结构断言 16/16；throw 8==8；大括号 329/329
PC 应用器 v2 行数        ：HwndSource 2843 → 2995（+152）
WB 应用器 --check（重放前）：rc=1；4 处锚点各 1 次；结构断言 14/14；throw 18==18；大括号 354/354；行数 2876 → 3101（+225）
WB 应用器 --prove        ：rc=0（§4.1）
假树里应用后 --check      ：rc=0；再跑一次 sha 不变（幂等 ✅）
```

---

## 2. 插桩点清单（**逐点核对表**：以**生成物里的调用点**为准，不以脚本里的 `EDITS` 表为准）

行号 = **重放后**生成物的行号（取自 §4.3 的预测产物，与重放逐字节相同 ⇒ 行号也是真值）。
> 📌 **行号会整体下移**：v2 的插桩类比 v1 多 ~22 行（新增 `PreprocessEarlyGate` 及其说明），而它插在文件**最前面**
> ⇒ H1…H7 一律下移。**焦点门**由 v1 的 `:1906-1909` 变成 v2 的 **`:1933-1936`**（H0 就插在它前面）。
> 审阅时请以本表行号为准，不要拿 v1 的行号找。

### 2.1 `build/PresentationCore.Linux/HwndSource.Linux.cs`

| 点 | 生成物:行 | helper | 定义行 | 调用点数 | 上游锚点 | **实跑是否出现过** |
|---|---|---|---|---|---|---|
| H0 | **:1927** | `PreprocessEarlyGate`（新） | :107 | 1 | `HwndSource.cs:1778-1781`（焦点门**之前**） | 未跑（离线不可证） |
| H1 | :1951 | `SourceKeyDown("置true前")` | :136 | 2（另一处 H2） | `:1799` | 未跑 |
| H2 | :1969 | `SourceKeyDown("复位后")` | :136 | ↑ | `:1814` | 未跑 |
| H3 | **:2011** | `PreprocessCharEntry`（**已改名：入口(过焦点门后)**） | :122 | 1 | `:1852` | 未跑 |
| H4 | :2018 | `PreprocessCharStep("TranslateChar")` | :130 | **3**（H5/H6） | `:1859` | 未跑 |
| H5 | :2023 | `PreprocessCharStep("OnMnemonic")` | :130 | ↑ | `:1863` | 未跑 |
| H6 | :2030 | `PreprocessCharStep("ProcessTextInputAction")` | :130 | ↑ | `:1868` | 未跑 |
| H7 | :2596 | `RestoreCharMessagesCalled` | :142 | 1 | `:2432` | 未跑 |
| — | :39 | 插桩类本体 `WpfLinuxInputTrace` | — | — | — | — |

### 2.2 `build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs`（**不变**；"提供方那三处"的落地情况）

| 点 | 生成物:行 | helper | 定义行（在 HwndSource.Linux.cs） | 调用点数 | 上游锚点 | 实跑是否出现过 |
|---|---|---|---|---|---|---|
| K1 | :204 | `ProviderKeyDown("入口")` | :148 | 1 | `HwndKeyboardInputProvider.cs:219` | 未跑 |
| K2 | :243 | `ProviderKeyDownReset` | :155 | 1 | `:226-231` | 未跑 |
| K3a | :279 | `ProviderChar("入口")` | :161 | 3（K3b/K3c） | `:255-266` | 未跑 |
| K3b | :284 | `ProviderChar("被 _eatCharMessages 门住 ⇒ 丢弃")` | :161 | ↑ | `:266` | 未跑 |
| K3c | :289 | `ProviderChar("ProcessTextInputAction 之后")` | :161 | ↑ | `:271` | 未跑 |

**结论（机械核对，可复核）**：`EDITS_HK` 的 **3 条**编辑产生了**5 个**调用点，**全部在生成物里**
（`grep -ac "WpfLinuxInputTrace\." build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs` ⇒ 5）。
⇒ 主控清单里"提供方那三处**没接上**"这一条**与生成物不符**：是**接了**的。三条编辑 → 五个点，不是三个点。
复核命令（只读）：
```
grep -an "WpfLinuxInputTrace\." build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs
grep -ac "ProviderKeyDown\|ProviderKeyDownReset\|ProviderChar" build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs
```

### 2.3 `build/WindowsBase.Linux/Dispatcher.Linux.cs`（**新**；托管侧第一个看见 `MSG` 的地方）

| 点 | 生成物:行 | helper | 定义行 | 调用点数 | 上游锚点 | 实跑是否出现过 |
|---|---|---|---|---|---|---|
| W1 | **:2430** | `Dequeued` | :189 | 1 | `Dispatcher.cs:2195`（方法体第一行后） | 未跑 |
| W2 | **:2435** | `ThreadPreprocessResult` | :218 | 1 | `:2199`（`RaiseThreadMessage` 返回处） | 未跑 |
| W3 | **:2441** | `DispatchToWndProc` | :233 | 1 | `:2203`（`TranslateMessage` 与 `DispatchMessage` **之间**） | 未跑 |
| — | :43 | 插桩类本体 `WpfLinuxMsgFlowTrace` | — | — | — | — |

**"实跑是否出现过"这一列全格是 `未跑`** —— 离线**证不了**"这行会被执行到"（要真来一条消息 + 真跑 WPF 应用；本轮由 T3 独占显示、主控统一重放）。
能给的机械证据是：①调用点在生成物里**在位**（§4.3 的 sha 预测）；②锚点命中数 == 1；③`--prove` 的"只插入"证明。
**我不把"应该会出现"写成绿格** —— 这正是上一轮出过的错（假绿）。

---

## 3. 判据（**先写死**，读数一到就落格）

### 3.1 开关：一条命令同时开原生 + 托管

```
--app-env=WPF_LINUX_MSGFLOW_TRACE=1     # 原生 [MSGFLOW]（win32_msg.c:117）+ 托管 [MSGFLOW_TRACE]（新）
--app-env=WPF_LINUX_KEY_DIAG=1          # 原生 [XEV]/[KEY]/[DROP]（win32_x11.c:203）
--app-env=WPF_LINUX_INPUT_TRACE=1       # PC 侧 [INPUT_TRACE]（H0…H7 / K1…K3）
```
> ⚠️ `WPF_LINUX_MSGFLOW_TRACE` **不是新名字**：原生侧早在用它（`win32_msg.c:117`，口径=「非空且非字面 `0`」）。
> 托管侧对这个名字**采用同一口径**（`IsOnNativeSwitch`），对 `WPF_LINUX_INPUT_TRACE` 用 PC 侧严格解析。
> 不同口径会造成"原生在打、托管一行没有"的**假象**，被误读成"托管泵没取消息" ⇒ 必须对齐。
> 三股输出的**前缀可分离**：`[MSGFLOW]` / `[MSGFLOW_TRACE]` / `[INPUT_TRACE]`。

### 3.2 四格（**互斥**，从上往下第一条命中即结论）

| 格 | 观察（原始读数） | 结论 | 下一步交给谁 |
|---|---|---|---|
| **① 上游丢** | `[MSGFLOW_TRACE] ① 出队` 里**没有** `0x0102(WM_CHAR)`（常常连 `0x0100(WM_KEYDOWN)` 也没有） | 消息**根本没到托管泵** ⇒ 不在 PC/托管逻辑里 | **原生侧（M7b）**：`[XEV]`/`[KEY]`/`[DROP]` + `[MSGFLOW] push/pop`。**现场证据偏向这一格**：`win32_x11.c:190-195` 记录 2026-09-12 现场 `[msg]` 只有 1 条 `WM_SETFOCUS`、**0 条 WM_KEYDOWN / 0 条 WM_CHAR** |
| **② 取不出来** | 原生 `[MSGFLOW] push WM_CHAR 入队` **有**，但托管 `① 出队` **没有** `0x102` | 队列里**有**、泵**没取到**（filter 不匹配 / 被别的取消息者拿走 / 跨线程进了**别人的队列**） | **原生侧**：`pop api=…` 行（是 `GetMessageW` 还是某个嵌套 `PeekMessageW(PM_NOREMOVE)` 拿走的）+ 两处 PM_NOREMOVE 告警（`win32_msg.c:551/559`）+「队列指针/tid」两侧对齐 |
| **③ 被预处理吃掉** | 托管 `①` 有 `0x102` 且 `② handled=True` | 被**线程预处理 filter** 处理掉 ⇒ **不进** `TranslateMessage/DispatchMessageW` | 看 PC 侧 **H0**：<br>· H0 **打了** ⇒ 是 `HwndSource.OnPreprocessMessage` 里某步置的 true（继续看 H4/H5/H6 谁置 true）<br>· H0 **没打** ⇒ 是**别的**注册者吃的 ⇒ 查 `ComponentDispatcher` 的 filter 表 |
| **④ 到了 `OnPreprocessMessage`** | H0 打了（说明 char 消息到了 preprocess） | 分两支 ↓ | ↓ |
| ④a 焦点门挡 | H0 打了、**H3 没打**；H0 行里直接读得到 `HasFocusWithin=False`（或 `IsInExclusiveMenuMode=True`） | 被 `if (!HasFocusWithin() && !IsInExclusiveMenuMode) return;` **挡回去** | 焦点链：`HwndSourceKeyboardInputSite` / 谁持有焦点 / TextBox 在不在焦点链上。**这一支正是 v2 加 H0 才能指认的** |
| ④b 进了 char 分支 | **H3 打了** | 进了 `case WM_CHAR:` | 看两件事：<br>· H3 行里的 `_eatCharMessages`：`True` ⇒ **静默丢弃**（联动 H1/H2/H7 + K1/K2）<br>· H4/H5/H6 三步里谁把 `handled` 置 true<br>· 三步全 `False` 仍无字 ⇒ 走 §5（`ReportInput → InputManager → TextCompositionManager`） |

**原三格判据（卡住 / restore 没跑 / TranslateChar 吞了）现在都是 ④b 的"子格"**，不再是入口判据 ——
因为它们的探针全都**在焦点门之后**。这是 v2 的主要修正。

### 3.3 `_eatCharMessages` 假设：**降级**

| 项 | v1 的说法（已撤回） | v2 的说法 |
|---|---|---|
| 地位 | "**头号嫌疑**：`_eatCharMessages` 长期为 true ⇒ WM_CHAR 被静默吃掉" | **降级为 ④b 的一个子格**（只有 H3 命中后才有意义） |
| 为什么降 | 入口探针在 `switch` 里、焦点门之后 ⇒ "没打印"**不能**证明 `_eatCharMessages=True`；三种含义混在一起 | 只有 **H0 命中且 H3 命中**时，`_eatCharMessages=True` 才等于"键到了、字符被吃掉" |
| 现有证据指向 | — | 原生日志记录的现场是 **0 条 WM_KEYDOWN / 0 条 WM_CHAR** ⇒ 连 char 都没产生 ⇒ **格 ① 更可能**；`_eatCharMessages` 只是"如果真来了 char、又没字"时的第一解释 |

**仍值得读**（成本几乎为零）：H1/H2/H7 + K1/K2 五格一起看，能直接判定"卡住"还是"清掉了"。

---

## 4. 自检（原始读数）

### 4.1 ①「只插入」机械证明（`--prove`，只读）

```
python3 src/WpfGfx.Linux.Native/tools/patch-windowsbase-msgflow.py --prove
[① 只插入] 取自 落盘生成物 build/WindowsBase.Linux/Dispatcher.Linux.cs
[① 只插入] 摘掉插桩后与上游**逐字节相同** ✓ sha256=c2c6ec15dccf6a9406d550afefff32d848ebcd0dac2e6d1beaef37c40430db53
[① 只插入] 上游 sha256=c2c6ec15dccf6a9406d550afefff32d848ebcd0dac2e6d1beaef37c40430db53
```
做法：从落盘生成物里按 `EDITS` **逆序**回代（`repl → anchor`，每处要求恰好命中 1 次），再与上游比 sha256。
生成物不存在时退化为"内存证明"，并**明写**"这还不是对落盘件取的真值"（不给假绿）。
PC 那两个生成物的同类证明仍在 `build/MilBridge/tools/t1c-inputtrace-verify.py`（v2 的 H0 也纳入了逆向回代表）。

### 4.2 ② 插桩类本体（探针装置，**未在本轮重跑**）
`build/MilBridge/tests/InputTraceProbe/` 用的还是**从生成物原样抽出**的类文本；v2 加了 `PreprocessEarlyGate` 与 W1…W3 之后
该装置的**两臂断言需要重跑一次**（缺省 0 输出 / 打开 N 行 + 封顶 200）—— 这件事**还没做**，登记为我的待办，
不假装它绿。**离线可先做的**：结构断言 16/16（PC）+ 14/14（WB）已覆盖"缺省关 / 有界 / 读数==输出行数 / 两开关取或 / 与原生同名开关语义对齐"。

### 4.3 ③ 重放对齐用：**预测 sha**（怎么来的，可复现）

在 `/tmp` 假树里跑同样的应用器（**只写 `/tmp`，没碰仓库里的生成物**）：
```
R=$PWD; rm -rf /tmp/t1c/pred; mkdir -p /tmp/t1c/pred/src/WpfGfx.Linux.Native/tools \
    /tmp/t1c/pred/build/PresentationCore.Linux /tmp/t1c/pred/build/WindowsBase.Linux /tmp/t1c/pred/upstream
ln -s "$R/upstream/wpf" /tmp/t1c/pred/upstream/wpf
cp src/WpfGfx.Linux.Native/tools/patch-{presentationcore-inputtrace,windowsbase-msgflow}.py /tmp/t1c/pred/src/WpfGfx.Linux.Native/tools/
cp build/{PresentationCore.Linux/PresentationCore.Linux.csproj,WindowsBase.Linux/WindowsBase.Linux.csproj} /tmp/t1c/pred/build/*/
cd /tmp/t1c/pred && python3 src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py \
                 && python3 src/WpfGfx.Linux.Native/tools/patch-windowsbase-msgflow.py && sha256sum build/*/*.Linux.cs
```
生成物内容**只**取决于「上游 + 应用器」⇒ 预测与重放应当**逐字节相同**。
**若重放后 sha 对不上**：先别信任何读数 —— 查上游是否被改、应用器是否被换过（这条就是防"读数与出处对不上"）。
行号同理：§2 的表用的就是这些预测产物的行号。

### 4.4 ④ 上一轮自检抓出的**我自己的缺陷**（继续登记）
- `LineCount` 曾记**调用次数**（261）而非**实际输出行数**（200）⇒ 已改为"只在真写成功时自增"；WB 侧额外加了"写失败则回退计数"。
- 逆向回代第一次跑**红**了：`--prove` 把**文件头**也一起回代 ⇒ 与上游不等。原因是"生成物 = 文件头 + 上游 + 插桩"，
  回代前必须先摘文件头（现已在代码里做，且**校验**文件头对得上，否则报"不是本脚本产出的"）。

### 4.5 ⑤ 离线**证不了**的三条（必须说清）
1. 插桩行**确会被执行到**（要真消息 + 真应用）。
2. `HasFocusWithin()` 的**返回值**（离线无窗口/焦点）。
3. **PC 与 WB 两份生成物能编过**：本轮**没编译**（"不要重建 PC"）。风险点已人工过一遍：
   - H0 调用点的 `msgdata`/`_eatCharMessages`/`IsInExclusiveMenuMode`/`(IKeyboardInputSink)this` 都在**同一方法作用域**内（锚点即那段焦点门）；
   - WB 三处调用点的 `msg` 是 `ref MSG` 形参，`msg.message/hwnd/wParam/lParam` 可直接读；插入处**不改变**任何原有语句顺序；
   - 两个插桩类都是**独立顶层类**（`internal static`，同 namespace），不引新 `using`（全部全限定名）。

---

## 5. 若 ④b 也正常 ⇒ 下一个该查谁（入口坐标不变）
```
WM_CHAR → HwndSource.OnPreprocessMessage → TranslateChar / OnMnemonic
        → HwndKeyboardInputProvider.ProcessTextInputAction      :541
            → new RawTextInputReport(...)                        :558-567
            → handled = _site.ReportInput(report);               :570   ← **下一个岔口**
        → InputManager.ProcessInput(InputEventArgs)              InputManager.cs:506
        → TextCompositionManager ⇒ TextComposition/TextInput → TextBox.OnTextInput
```
下一批插桩点（同一车道，落一个 applier 即可）：`ProcessTextInputAction` 入口/出口（`charcode`、`_site==null`、`ReportInput` 返回）、
`InputManager.ProcessInput` 入口（`input` 类型、`PrimaryKeyboardDevice`）、`TextCompositionManager` 的 `TextInput` 订阅者与 raise。

---

## 6. 给 **M7b** 的原生侧交接（**先查已有，别重做**；坐标均为只读复核所得）

出处 sha：`win32_msg.c` `7349d6584e2f808f99d16436f6efa6a97494a10f93d2dbd099edcb82f7d81a4d`、
`win32_x11.c` `1c9bbd60b8845402d950c838e4b658dd6e01301781ee12ac27a48592f332cfb1`。

**已有（`WPF_LINUX_MSGFLOW_TRACE=1` / `WPF_LINUX_KEY_DIAG=1`）**
| 位置 | 打什么 |
|---|---|
| `win32_msg.c:63-65`（push） | `push WM_CHAR 入队 码点=… 队列长度=… 队列=… tid=…`（**入队侧**） |
| `win32_msg.c:187-198`（pop） | `pop api=%s msg=… hwnd=… 剩余=… 队列=… tid=…`（**出队侧**；非关注类只采样 40 条） |
| `win32_msg.c:480/510/514` | 取消息者标注：`GetMessageW` / `PeekMessageW(PM_REMOVE)` / `PeekMessageW(PM_NOREMOVE)` |
| `win32_msg.c:551 / :559` | `PeekMessageW(PM_NOREMOVE)` 取到的**不是队首** / 回插 `malloc` 失败 ⇒ **该消息被吞** |
| `win32_x11.c:191-197`（`WPF_LINUX_KEY_DIAG`） | `XEV`（收到的每个 Key/Focus 事件 + `send_event` 合成位 + window id）/ `KEY`（翻译结果）/ `DROP`（**收到但没产出**的原因） |
| `win32_x11.c:596 / :610` | WM_CHAR 产生点 / `DROP WM_CHAR 原因：…（keycode/state）` |

**已定论、别再假设的一条**：`TranslateMessage`（`win32_msg.c:570-576`）是**故意空实现**、返回 0
（WM_CHAR 由 X11 翻译层**直接**产生，否则会重复）⇒ **"TranslateMessage 吞了字符"这条假设在本移植里不成立**。

**还缺的读数（建议补，且必须"在所有早退/过滤门之前"）**
1. `GetMessageW`（`:475` 起）的**返回路径**：`pop` 打了、托管 `①` 没打 ⇒ 断点就在 `pop` 与 `return` 之间的 wait/filter 逻辑
   （`wpf_queue_pop` 的 filter 不匹配 ⇒ 消息留在队列里、`GetMessage` 继续等 ⇒ **托管侧永远看不到**）。建议在 `return` 前打一条「返回给托管的 msg id + 是否被唤醒」。
2. `PeekMessageW(PM_NOREMOVE)` **回插成功之后**再打一行**队首 id**：现有 `:551` 只在"取到的不是队首"时打，
   看不到 WM_CHAR 有没有被反复"弹到尾再取"（PM_NOREMOVE 是 pop→re-push ⇒ **会改队列顺序**）。
3. X11 `push()`（`:475-487`）对 `WM_KEYDOWN/WM_SETFOCUS` 也打一行（现在 push 只对 WM_CHAR 打）
   ⇒ 否则"键根本没到进程"与"键到了但没产 char"分不开（后者才有 `DROP` 行）。
4. 纪律（我这轮踩过）：探针必须**在所有早退门之前**，否则"没打印"有好几种含义，读数无法落格。

**对齐用法**：`[MSGFLOW] pop … msg=258(0x0102 WM_CHAR)` **有** + `[MSGFLOW_TRACE] ① 出队` **没有** ⇒ 就是**格 ②**
（队列里有、托管泵没取到）—— 这一对读数是本条链路上**唯一**能机械指认"取不出来"的地方。

---

## 7. 落盘清单（重放后请核对 sha）
```
4eac185d5ae049a8fca2a39d268b0cdb6272c11b4e29fd56f984570767fa1d34  src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py      （v2）
cf3c1d79312ccf34812a534749dcba1d302713af78768a50bdea1b0543817469  src/WpfGfx.Linux.Native/tools/patch-windowsbase-msgflow.py             （新）
385a60142567785e4ff41b55998ad8f0c353a3ccbf343c05c1e9ee8cf916864f  build/PresentationCore.Linux/HwndSource.Linux.cs                       （预测；现为 v1 9408a440…）
f56e647e21c29ef0211fe11f7cc6dfa7a8d43d48e1477d2fdf3d5cb3ba62ff95  build/PresentationCore.Linux/HwndKeyboardInputProvider.Linux.cs        （不变）
cbb971f5e18534434db7dc0256cd6db4f24ce0cf39dbf2219add252c44d43705  build/WindowsBase.Linux/Dispatcher.Linux.cs                            （预测；新文件）
```

**⚠️ 两个"假绿"陷阱（都写进应用器输出了）**
1. `build/port-lib.py WindowsBase` 会**整份重写** csproj ⇒ WB 那 2 行接线会被抹掉，**不会报编译错**，
   只会"一行都不打"。**别把空输出读成"没消息"** —— 把空输出读成"格 ①"，就会去原生侧白查一轮。
2. 两个应用器的 `--check` 都会**在接线缺失时 rc=1**（而不是"看起来已应用"）—— 重放时请以 `rc` 为准，**不要经管道取 `$?`**。

**边界**：本轮只写
`src/WpfGfx.Linux.Native/tools/patch-presentationcore-inputtrace.py`（v2）、
`src/WpfGfx.Linux.Native/tools/patch-windowsbase-msgflow.py`（新）、
`build/MilBridge/T1c-inputtrace-report.md`（本文件）与 `build/MilBridge/T1c-report.md`（§21）；
**没有生成物、没重建 PC/WindowsBase、没发桥、没跑应用**，没动 `src/WpfGfx.Linux/**`（M7b）、`build/shims/**`（T1d）、
`samples/**`、`tests/…/Presentation.Tests/**`（T3）、`build/DirectWrite.Linux/**`（T2）、`build/MilBridge/**` 里别人的文件。

---

# 第 2 批（P1…P6）：`ProcessTextInputAction` **之后**发生了什么

> **第 1 批的实测已把判据改写**（见下），所以第 2 批不是"再撒一把探针"，而是**换一个问法**：
> 不问"字符被谁吃了"（已证：`_eatCharMessages` **所有描点都是 `False`**，那套判据**不成立**），
> 只问 **"`TextInput` 有没有被 raise、raise 给了谁、TextBox 的处理器跑没跑"**。
> 本轮**只写源码与报告**：没有生成物、没重建 PC/WindowsBase/PF、没发桥、没跑应用。

## 8.1 第 1 批的实测改写了什么（**原文登记**）

```
[MSGFLOW] push WM_CHAR 入队 码点=65(0x0041 'A') 队列长度=2
[MSGFLOW] pop api=GetMessageW msg=258(0x0102) hwnd=0x200005 剩余=1        ← 传输层已闭环（修前 0 行）
[INPUT_TRACE] PreprocessMessage 早退门之前 … HasFocusWithin=True IsInExclusiveMenuMode=False _eatCharMessages=False
[INPUT_TRACE] PreprocessMessage WM_CHAR 入口(过焦点门后) … _eatCharMessages=False
[INPUT_TRACE] PreprocessMessage WM_CHAR 步骤 TranslateChar ⇒ handled=False
[INPUT_TRACE] PreprocessMessage WM_CHAR 步骤 OnMnemonic ⇒ handled=False
[INPUT_TRACE] PreprocessMessage WM_CHAR 步骤 **ProcessTextInputAction ⇒ handled=True**
（托管）[MSGFLOW_TRACE] ② 线程预处理 0x0102 handled=True ⇒ **不进** TranslateMessage/DispatchMessageW
（样例）[feat] textbox-edit OK focus=True caret=0 selLen=7 text='seed-文本' **changes=0**
        ⚠️ 口径已更新：`changes>0` 只是**旁证**；「键入腿」主判据 = 注入前后 `WFP_BOXID` 矩形内的像素/字形差异（见顶部横幅）
```

| 第 1 批的假设 | 处置 | 依据 |
|---|---|---|
| "`_eatCharMessages` 卡在 true ⇒ WM_CHAR 被静默吃掉" | **作废**（三个描点全 `False`） | 上面第 2、3 行 |
| "`RestoreCharMessages` 没跑" | **作废**（不是因，字符根本没走到那一步） | 没有 restore 行 ⇒ 但 `_eatCharMessages` 已是 False，与"卡住"无关 |
| "`TranslateChar` 吞了" | **作废**（`handled=False`） | 第 5 行 |
| "`OnMnemonic` 吞了" | **作废**（`handled=False`） | 第 6 行 |
| **新事实**：`ProcessTextInputAction ⇒ handled=True` 而文本没变 | **第 2 批的出发点** | 第 7 行 + 样例 `changes=0` |

**注意**：`handled=True` **本身是正常的**（`TextCompositionManager` 处理完 `RawTextInputReport` 会把 report 标 handled）
⇒ 第 2 批**不把 `handled=True` 当结论**，只把它当"该往下查"的路标。

## 8.2 交付物与 sha256（应用器 = 要重放的东西；生成物 = 重放后应当等于的值）

| 件 | sha256 |
|---|---|
| `tools/patch-presentationcore-inputtrace.py`（**v3**：插桩类里加了 P1…P5 的 helper + 第 2 批独立预算） | `62a0822d5314a844df8a03a9c9a9b88a9e3d2af23da946a7502e00ebf0d88f4b` |
| `tools/patch-presentationcore-inputsite-trace.py`（**新**，P1） | `e257247a3dacdb6ec2c15aadad2e3363f4bab378b20717a165db50f141ce4721` |
| `tools/patch-presentationcore-apartment.py`（**扩展**：补丁 H 之外加 P2/P5；补丁 H **逐字未改**） | `0a52507b8acd350d7d91a028751cb113e39ccedf91efad08acef0731e2839c10` |
| `tools/patch-presentationcore-registry.py`（**扩展**：补丁 J 之外加 P3a/P3b/P4a/P4b；`?.` 逐字未改） | `13ee8456f32b660d9f3a859db98654930eaa5bf8cb64cfbb269a523729ac3373` |
| `tools/patch-presentationframework-texteditor-trace.py`（**新**，P6，PF 车道一次性授权） | `aba4933089fdea842037f4c87d2a0d0381e9da00d8476394fd75684a1b04979a` |
| 生成物（**重放后**）：`HwndSource.Linux.cs`（v3） | `47934329c6b2a47b0d74c66c5593472e9bb64e54ad12e6eb9ab1dffa1e64be28`（**上一批是 v2 = `385a6014…`，本轮插桩类长大 ⇒ 会变**） |
| 生成物：`HwndKeyboardInputProvider.Linux.cs` | `f56e647e21c29ef0211fe11f7cc6dfa7a8d43d48e1477d2fdf3d5cb3ba62ff95`（**不变**） |
| 生成物：`InputManager.Linux.cs` | `70a5d54ba859fdd7b870668d79b37a38c833f9d2cdc30b9197d7ae6203998a92`（现盘 `e9122986…` = 旧） |
| 生成物：`TextCompositionManager.Linux.cs` | `e56065a834a6e59357d3dec392ae93f00c049ca788421cafd755a8f0d591b9ef`（现盘 `1465dd1c…` = 旧） |
| 生成物：`InputProviderSite.Linux.cs`（**新文件**） | `3a079a8f23dbdc023923ca600f4dac7e8a0bcf086912540d396c571089661241` |
| 生成物：`TextEditorTyping.Linux.cs`（**新文件**，PF） | `1f8eb2958602be7f5970b0d5af86816352561c23cedb0a2c0a1a0e44287a084f` |
| `Dispatcher.Linux.cs`（WindowsBase，上一批的，本轮未动） | `cbb971f5e18534434db7dc0256cd6db4f24ce0cf39dbf2219add252c44d43705` |
| registry 的另两份生成物（**应当不变**） | `StylusLogic.Linux.cs` `fd57318a…` / `WispTabletDeviceCollection.Linux.cs` `18ef64f3…`（与现盘**一致**，已核） |

> ✅ **预测机制已被上一轮实测校准**：我上一批在 `/tmp` 假树里预测 `HwndSource.Linux.cs = 385a6014…`、
> 提供方 `f56e647e…`，**主控重放后的落盘 sha 与预测逐字节相同**（本轮开工时核对）。
> ⇒ 本节这些预测 sha 可以当作"重放正确性"的**验收判据**用。

## 8.3 逐点核对表（**"实跑是否出现过"全列 `未跑`**；本轮没跑，不写假绿）

`file:line` = **重放后**生成物的行号（取自 §8.5 的预测产物）。

| 点 | 生成物:行 | helper | helper 定义行 | 上游锚点 | 实跑是否出现过 |
|---|---|---|---|---|---|
| **P1** `InputProviderSite.ReportInput`（报告 + 返回 handled + `_inputManager`） | `InputProviderSite.Linux.cs:107` | `B2ReportInput` | `HwndSource.Linux.cs:254` | `InputProviderSite.cs:88-98` | 未跑 |
| **P2** `InputManager.ProcessInput` **入口**（报告/RoutedEvent/Source + **`KeyboardDevice.FocusedElement`**） | `InputManager.Linux.cs:543` | `B2ProcessInputEntry` | `HwndSource.Linux.cs:264` | `InputManager.cs:506-509` | 未跑 |
| **P2'** 同函数**返回** handled（只对 Text 类） | `InputManager.Linux.cs:564` | `B2ProcessInputResult` | `HwndSource.Linux.cs:291` | `:523-525` | 未跑 |
| **P3a** `TextCompositionManager` Raw 段**条件之前**（报告 + RoutedEvent） | `TextCompositionManager.Linux.cs:629` | `B2RawReport` | `HwndSource.Linux.cs:306` | `TextCompositionManager.cs:608-611` | 未跑 |
| **P3b** **进了** `Raw→StartComposition` 分支体（码点 + `IsControl/IsDead/IsSystem` + `StagingItem.Source`） | `TextCompositionManager.Linux.cs:636` | `B2RawBranch` | `HwndSource.Linux.cs:320` | `:614-615` | 未跑 |
| **P4a** 新建的 `TextComposition`（**Text + 目标元素 Source**） | `TextCompositionManager.Linux.cs:694` | `B2CompositionCreated` | `HwndSource.Linux.cs:340` | `:669` | 未跑 |
| **P4b** `UnsafeStartComposition` **返回值**（正常字符） | `TextCompositionManager.Linux.cs:705` | `B2StartComposition` | `HwndSource.Linux.cs:354` | `:678` | 未跑 |
| **P4b'** 同上（dead char 支路；**只有真来 dead char 才会出现**） | `TextCompositionManager.Linux.cs:680` | `B2StartComposition` | `HwndSource.Linux.cs:354` | `:657` | 未跑 |
| **P5** `ProcessStagingArea` 的 **`RaiseEvent` 之前**（事件名 + **目标元素** + Source） | `InputManager.Linux.cs:814` | `B2RaiseInput` | `HwndSource.Linux.cs:368` | `InputManager.cs:771-775` | 未跑 |
| **P5'** `RaiseEvent` **之后**的 `Handled`（只对文本事件） | `InputManager.Linux.cs:830` | `B2RaiseInputResult` | `HwndSource.Linux.cs:384` | `:781-783` | 未跑 |
| **P6a** `TextEditorTyping.OnTextInput` **入口**（sender/Text/OriginalSource/**进来时 Handled**） | `TextEditorTyping.Linux.cs:526` | `P6Entry` | `TextEditorTyping.Linux.cs:138` | `TextEditorTyping.cs:352` | 未跑 |
| **P6b1** **第一道门就 return**（`This==null / !IsEnabled / IsReadOnly / !IsSourceInScope` **四个条件各自真假**） | `TextEditorTyping.Linux.cs:533` | `P6BailScope` | `:157` | `:356-359` | 未跑 |
| **P6b2** **第二道门就 return**（空文本） | `TextEditorTyping.Linux.cs:550` | `P6BailEmptyText` | `:169` | `:367-371` | 未跑 |
| **P6c** 两道门都过了 + `e.Handled=true` | `TextEditorTyping.Linux.cs:559` | `P6ConsiderHandled` | `:177` | `:373-374` | 未跑 |
| **P6d** `ScheduleInput` **已排队插入** | `TextEditorTyping.Linux.cs:583` | `P6ScheduleInput` | `:188` | `:394-395` | 未跑 |

**跨命名空间**：P1…P5 的调用点**全部全限定**（`System.Windows.Interop.WpfLinuxInputTrace.…`）——
插桩类在 `System.Windows.Interop`，而这三个文件在 `System.Windows.Input`；**S1/S2/S3 是编译错误级**的坑，已按全限定写死。
P6 不跨程序集（PF 自带 `WpfLinuxPfInputTrace`，见 §8.6）。

**"只对 Text 类打"的三格（P1 / P2 / P3a）**：它们按 `InputReport.Type == InputType.Text` 过滤，
非 Text 报告只采样前 20 行（并打一行累计统计）。⚠️ **因此"P1 没看到"有两种含义**：
① 报告没到；② 它到了但 `Type != Text`（于是落进"非 Text 采样"里）。
**防这个坑**：P3b/P4/P5/P6 **不打 Type 过滤**，且 `B2Allow` 封顶时会打一行累计计数
⇒ 只要 P3b 或 P4 有、P1 没有，就说明是 **②**，不是 ①。

## 8.4 判据（**互斥**，从上往下第一条命中即结论）

| 格 | 观察（原始读数） | 结论 | 下一步 |
|---|---|---|---|
| **甲** | **P1 有、P3a 无** | 报告没走到 `TextCompositionManager` 的 Raw 段 | 查 `ProcessInput` 的 staging 与路由（P2 的 `RoutedEvent`：是不是 `PreviewInputReport` 而不是 `InputReport`） |
| **乙** | **P3a 有、P5 无** | `UnsafeStartComposition` 没把 `TextInput` raise 出来 | 看 P3a 的 `RoutedEvent`（条件要求 `InputReport`）、P4a 的**目标元素**、**P4b 的返回值** |
| **丙** | **P5 有，但目标元素 ≠ 你的 TextBox**（比 `Type#hash`：与 P4a 的 `目标(Source)`、P2 的 `FocusedElement` 三方对齐） | 焦点/路由问题 | 回看 P2 的 `KeyboardDevice.FocusedElement` |
| **丁** | **P5 目标对、P6a 没跑** | 事件 raise 了但 PF 的处理器没被调 | PF 侧（订阅/路由/`IsSourceInScope` 之外的层） |
| **戊** | **P6a 有、P6b1 有** | TextBox 的处理器**跑了但第一道门就 return** | 直接读 P6b1 行里四个条件的真假（`This==null` / `IsEnabled` / `IsReadOnly` / `IsSourceInScope`） |
| **己** | **P6c/P6d 有，文本仍不变** | 事件确实被 TextBox 处理并**排了插入** | 往 `TextEditor` 的插入路径查（调度 → `TextContainer`/`TextRange`），不在本批 |

**这六格互斥且穷尽**（`TextInput` 这条链上每一个"能 return 的门"两侧都有探针）——
这正是第 1 批教训的落地：**探针必须在所有早退门之前/两侧**，否则"没打印"有多种含义。

## 8.5 闸门（rc 都**不经管道**取；本轮重放前/后分开）

```
应用器 v3 --check（重放前）：rc=1（生成物是 v2/旧版）  12 锚点各 1 次；结构断言 28/28；throw 8==8；大括号 329/329
P1 新应用器 --prove：rc=0（内存证明，逐字节回代 ✓ 7c1f65fa…）；--check：rc=1（未生成+未接线）
P2/P5（apartment）--prove：rc=0（逆代后与上游逐字节相同 ✓ ba9bac1f…）；--check：rc=1（生成物过时）
P3/P4（registry）--prove：rc=0（落盘件是旧版 ⇒ 自动退化为**内存**证明并明说不背书 ✓ 534aa6e6…）
    ※ 顺手修了它的 `--check` 语义：原来生成物过时也返回 rc=0（会把"没应用"读成"已应用"）⇒ 现在过时 ⇒ rc=1
P6（PF）--prove：rc=0（✓ 9e62a288…）；--check：rc=1（未生成+未接线）
/tmp 假树里全部应用后 --check：**6 个应用器全部 rc=0**；再跑一次 sha 不变（**幂等 ✅**）
```

**「只插入」证明** = 把各 applier 的编辑**逆序回代**后与上游 sha256 **逐字节相同**（上面五个 sha 都是这条证据）。
对 apartment/registry 这两个"别人的"应用器，证明覆盖**它们的原有编辑 + 我的插入**（所以还原得回上游）。

## 8.6 单写者纪律：**为什么我没有另起 applier 去写这两个文件**

| 文件 | 原写者 | 我的做法 | 为什么 |
|---|---|---|---|
| `InputManager.Linux.cs` | `patch-presentationcore-apartment.py`（M7b 补丁 H） | **扩展它** | 若另起一个 applier 写同一路径，则"**谁后跑谁赢**"：另一个跑在后面就会**静默**抹掉这批探针（不报错、只是没输出）⇒ 正是本波最怕的假绿 |
| `TextCompositionManager.Linux.cs` | `patch-presentationcore-registry.py`（M7c 补丁 J） | **扩展它** | 同上 |
| `InputProviderSite.Linux.cs` | 无 | **新 applier** | 该文件此前直接编上游，没有写者 ⇒ 新写者不会撞车 |
| `TextEditorTyping.Linux.cs` | 无 | **新 applier** | 同上 |

**扩展是逐字保留的**：补丁 H 的 `OperatingSystem.IsWindows() &&`、补丁 J 的 `?.` 一个字节没动
（两个应用器的 `REQUIRED` 里都有"逐字在位"断言；且 `registry` 的另两份生成物 sha 与现盘**一致**可交叉验证）。

## 8.7 波表登记（**请主控处理**）

* `patch-presentationcore-inputsite-trace`、`patch-presentationframework-texteditor-trace`
  **名字落在 `patch-presentation*` 通配里** ⇒ `build/integration-wave.sh` 的**自动兜底会执行**，
  但会打 ⚠ 提示。建议按现有习惯加进 `APPLIERS_EXPLICIT`（**顺序无依赖**：它们只碰自己的 csproj 块与自己的生成物）。
* `patch-presentationcore-apartment` / `-registry` / `-inputtrace` **已在显式表里** ✓（本轮只是内容变了，名字没变）。
* `patch-windowsbase-msgflow` 已登记 ✓（上一批的）。
* ⚠️ 两个新 applier 都往**各自工程的 csproj** 注入 2 行：`port-lib.py <工程>` 会**整份重写** csproj
  ⇒ 接线被抹掉**不会报编译错**，只表现为"**一行都不打**"。重放顺序仍是"port-lib → 应用器"。

## 8.8 本轮**没做**（不假装绿）

1. **没生成物、没重建（PC/WindowsBase/PF 都没编）、没发桥、没跑应用**（按主控指令统一重放）。
2. **没编译** ⇒ "这 5 份生成物能编过"只有人工核对（作用域/形参/null 安全/跨命名空间全限定），**没有编译器证据**。
   已知的两个编译级风险点已按最保守写法处理：①跨命名空间**全限定**；②插桩类里所有 `as` 转换 + null 判断，
   调用点只传原有变量（`inputReport/handled/_inputManager`、`input/PrimaryKeyboardDevice`、`textInput/…`、
   `composition`、`eventSource`、`sender/e/This`）—— **没有引入任何新变量、没有改变任何原有语句顺序**。
3. **离线证不了**"这些行会被执行到"（要真消息 + 真应用 + T3 的显示）⇒ §8.3 那一列全写 `未跑`。
4. 探针装置 `tests/InputTraceProbe/` 的两臂断言**仍未重跑**（v3 又加了 9 个 helper）⇒ 登记为待办。

---

## 8.9 澄清（主控点名要写进报告）：`composition == (null)` **是预期的，不是缺陷**

`TextEditorTyping.OnTextInput` 上游 `:361`：

```csharp
FrameworkTextComposition composition = e.TextComposition as FrameworkTextComposition;
```

原始 `WM_CHAR` 走的是**非 Cicero/IME**那一支 ⇒ 这个 `as` **返回 `null`** ⇒ 进 `else` ⇒ `ScheduleInput`
⇒ 正是 P6c 那行写明的"走 ScheduleInput（普通输入）"。
**⇒ `composition=(null)` 不要当线索追**（它不是"丢了一个对象"，而是"本来就不该有"）。
只有带 IME/Cicero 的输入才会在这里拿到非 null 的 `FrameworkTextComposition`。

---

# 第 3 批（Q0…Q4）：插入**排队之后**到底跑没跑（**待重放**）

> 第 2 批六格命中"己"：`P6c`/`P6d` 全绿（`ScheduleInput` 已排队插入 `text="A"`），样例仍 `changes=0`。
> 第 3 批把 `ScheduleInput` **之后**那条路整条钉住，**最小必需集 = Q0**（判"到底有没有投递"），
> Q1…Q4 判"投了跑没跑 / 跑了哪一步没插 / 抛没抛"。
> 本轮**只写源码与报告**：没生成物、没重放、没重建、没发桥、没跑应用。

## 9.0 两条来自 T3 的新读数，以及**我自己那条假设的撤回**

```
WFP_DISPATCH_PRIO normal=True input=True background=True contextidle=True     ← 四个优先级**全执行**（含最低的 ContextIdle）
托管 [msg]  0x8000=74 0x8009=5 其余=0 ｜ 原生 [MSGFLOW]pop 0x8000=36 0x8009=5 其余=0
```

| 项 | 处置 |
|---|---|
| 我在上一版 §9.5 写的"**`DispatcherPriority.Background` 被 `IsInputPending()` 饿死**" | **撤回**（T3 实测：`background=True`）⇒ 本轮**不再依赖**任何"消息号 ↔ 优先级"的映射，也不再依赖"没有 `0x8004` 所以 Background 没投递"这种**编码假设**（shim 的进程队列通知**只用 `0x8000` 一个号**） |
| `_msgProcessQueue = RegisterWindowMessage("DispatcherProcessQueue")`（`Dispatcher.cs:24`）⇒ `0x8000` | 仍然成立，但它**只说明"泵在跑"**，**不能**用来判优先级 |
| `BackgroundInputCallback` 的两条 `Invariant.Assert` + 补丁 N 会打印 assert 原文 | 实跑**没有** assert 文本 ⇒ **两条互斥解释**：回调压根没跑 / 跑了且断言成立。**必须由 Q0/Q1 的读数来定**，不许用"没看到 assert"去推 |
| `Dispatcher.ProcessQueue`/`IsInputPending`/`CriticalRequestProcessing` 的坐标 | 仍列在 §9.5，但**降级为备用**（只有四格判到"投了但没跑"时才需要它们） |

## 9.1 交付物与 sha256（**只改 1 个文件**）

| 件 | sha256 |
|---|---|
| `tools/patch-presentationframework-texteditor-trace.py` **v3**（P6 五处 + **Q0 五处 + Q1 两处 + Q2 三处 + Q3 三处 + Q4 六处**） | `44456383ecabd7085dfdf5cb1fe7270093436f162b5bd70777dec3bfe3ed324b` |
| 生成物 `build/PresentationFramework.Linux/TextEditorTyping.Linux.cs`（**重放后**） | **`5430f349fc7912664d838aec075a9cc6bad673a4c616d2d4b50c146f3e983514`** |
| 其余生成物 | **一律不变**：`HwndSource` `47934329…`｜`InputManager` `70a5d54b…`｜`TextCompositionManager` `e56065a8…`｜`InputProviderSite` `3a079a8f…`｜`HwndKeyboardInputProvider` `f56e647e…`｜`Dispatcher.Linux.cs` `cbb971f5…` |

> ✅ 预测机制**连续两批逐字节命中**（第 2 批五个预测与落盘全同）⇒ 重放后请以
> `TextEditorTyping.Linux.cs == 5430f349…` 作为"这批插桩确实进去了"的验收判据；其余文件**必须不变**。
> 仓库里现在只有 `patch-presentationframework-texteditor-trace --check` 是 **rc=1**（其余五个应用器都 rc=0）⇒ **本批只需重放这一个应用器**。

## 9.2 逐点核对表（`file:line` = 重放后生成物行号；"实跑是否出现过"全列 `未跑`）

| 点 | 生成物:行 | helper | helper 定义行 | 上游锚点 | 实跑是否出现过 |
|---|---|---|---|---|---|
| **Q0a** `ScheduleInput` **入口**（item 类型 + `AcceptsRichContent`） | `:2063` | `Q0Entry` | `:289` | `TextEditorTyping.cs:1569-1571` | 未跑 |
| **Q0i** 走了**立即执行**支路（`!AcceptsRichContent \|\| IsMouseInputPending`） | `:2068` | `Q0Immediate` | `:300` | `:1573-1577` | 未跑 |
| **Q0b** ⭐ **`PendingInputItems == null` 的真假**（**决定性那一格**） | `:2082` | `Q0PendingBefore` | `:312` | `:1583` | 未跑 |
| **Q0c** **已投递**（`BeginInvoke(Background, BackgroundInputCallback)` 调过了） | `:2089` | `Q0Posted` | `:323` | `:1584-1586` | 未跑 |
| **Q0d** `Add(item)` 之后的 **count** | `:2095` | `Q0Added` | `:330` | `:1589` | 未跑 |
| **Q1** `BackgroundInputCallback` **入口**（在两条 `Invariant.Assert` **之前**）+ count | `:2130` | `Q1Entry` | `:337` | `:1617-1623` | 未跑 |
| **Q1'** 回调**出口**（`finally` 之后，条目已置 null） | `:2145` | `Q1Exit` | `:345` | `:1627-1633` | 未跑 |
| **Q2** `_FlushPendingInputItems` **入口**（**定义处**，覆盖全部 8 个调用点）+ count | `:590` | `Q2Entry` | `:355` | `:145-149` | 未跑 |
| **Q2b** 循环里**第 i 条 item 的类型** | `:599` | `Q2Item` | `:364` | `:157` | 未跑 |
| **Q2'** flush **出口**（入口时的条数） | `:615` | `Q2Exit` | `:371` | `:176` | 未跑 |
| **Q3** `TextInputItem.Do()` **入口**（text / `UiScope` / 编辑器状态） | `:2215` | `Q3Do` | `:379` | `:1698-1700` | 未跑 |
| **Q3b** **命中 `UiScope == null` 早退**（静默丢弃） | `:2220` | `Q3BailUiScope` | `:387` | `:1700-1704` | 未跑 |
| **Q3c** `DoTextInput` 正常返回 | `:2228` | `Q3Done` | `:395` | `:1706` | 未跑 |
| **Q4a** `DoTextInput` **入口**（文本 / 选区 / 文档长度 / 编辑器状态） | `:1976` | `Q4Entry` | `:402` | `:1505-1507` | 未跑 |
| **Q4b** `_FilterText` **之后**（长度 0 ⇒ 下一行 return） | `:1998` | `Q4Filtered` | `:410` | `:1524-1528` | 未跑 |
| **Q4c** **真正写进容器之前**（`SetSelectedText` 那行之前） | `:2016` | `Q4BeforeWrite` | `:421` | `:1534-1540` | 未跑 |
| **Q4d** **写完之后——文档变了没有** | `:2021` | `Q4AfterWrite` | `:429` | `:1540` | 未跑 |
| **Q4e** **异常捕获**（类型 + 消息 + 前 4 行栈） | `:2045` | `Q4Exception` | `:445` | `:1549-1557` | 未跑 |
| **Q4f** 出口（`UndoCloseAction`：`Rollback` ⇒ 刚写进去的会被撤掉） | `:2040` | `Q4Exit` | `:437` | `:1552-1557` | 未跑 |
| （第 2 批保留）P6a/P6b1/P6b2/P6c/P6d | `:800/:807/:824/:833/:857` | — | `:138` | — | 未跑 |

**正常一跑应当出现的顺序**（"链条是否断在哪一环"一眼可判）：
```
P6d（已排队） → Q0a（进 ScheduleInput） → Q0b（null?） → Q0c（已投递） → Q0d（count=1）
   → …（Background 操作执行）… → Q1（回调入口） → Q2（flush 入口 count=1） → Q2b（item=TextInputItem）
   → Q3（item 被 Do） → Q4a → Q4b → Q4c → Q4d（**文档变了没有**） → Q4f（出口）
   异常路径：Q4e（+ Q3c/Q4f 不出现）
```

**唯一一处"非纯插入"**：Q4 把 `DoTextInput` 的**整个方法体**包了一层
`try { … } catch (System.Exception __t1cEx) { 记录; throw; }` —— 原语句**逐字未动**，
`catch` 里是 **`throw;`（不是 `throw ex;`）** ⇒ 异常类型/栈/控制流都不变；
断言写死为"`throw` == 上游 0 + **1 处故意 rethrow**"（多一处少一处都报错），大括号盈亏 319/319 不变，
`--prove` 逆序回代后与上游**逐字节相同**（`9e62a288…`）。不设环境变量时 `catch` 只多一次 `if(!s_enabled) return;`。

## 9.3 判据

### 9.3.1 四格（**主判据**，互斥）

| 格 | 观察 | 结论 / 下一步 |
|---|---|---|
| **①** | **Q0b 显示 `False`**（`PendingInputItems` 非 null） | **从不投递**：上游那条 `if (PendingInputItems == null)` **不成立** ⇒ `BeginInvoke` 压根没调（不会有 Q0c/Q1）⇒ 根因在"**谁把 `PendingInputItems` 留成了非 null**"：查**上一次** flush 有没有把 `finally { PendingInputItems = null; }` 走到（Q1' 不出现就是它没走完）、以及有没有别的路径清了列表却没置 null |
| **②** | **Q0b = True**（有 Q0c）但 **Q1 从不出现** | **投了但回调没跑** ⇒ 问题在 `DispatcherOperation`（回 WB 侧查，§9.5 的坐标这时才需要） |
| **③** | Q1 有、**Q4f 出口文档长度不变** | **插入路径本身失败** ⇒ 看 Q3b（`UiScope==null` 早退）/ Q4b（`_FilterText` 吃掉）/ **Q4e（抛异常）** / Q4f（`Rollback`） |
| **④** | Q4f 出口文档长度**变了**，样例读回 `text` 却不变 | 插入成功但**两个对象不是同一个**（样例持有的 `TextBox` 与真正被插入的不是同一实例/同一容器）⇒ T3 侧核对对象身份（`hash` 比对） |

### 9.3.2 细分格（③ 内部，按顺序命中即结论）

| 格 | 观察 | 结论 |
|---|---|---|
| ③-1 | Q2 入口 `Count=0`（或 Q2b 里没有 `TextInputItem`） | item 没进/已被清出 `PendingInputItems` |
| ③-2 | Q2b 有 `TextInputItem` 而 **Q3 不出现** | item 在队列里却没被 `Do()` |
| ③-3 | Q3 有 + **Q3b 命中** | `UiScope == null` ⇒ **静默丢弃** |
| ③-4 | Q4b **过滤后长度 0** | `_FilterText` 吃掉（只读 / MaxLength / 过滤） |
| ③-5 | Q4c 有 + **Q4d 文档没变** + 无 Q4e | `SetSelectedText` 没写进容器 ⇒ 下一批查 `TextEditor.SetText`(`TextEditor.cs:431`→`:413`) / `TextContainer` |
| ③-6 | Q4d 变了但 Q4f 是 `Rollback` | 写进去了**又被 undo unit 回滚** |
| ③-7 | **Q4e 有** | **抛异常了**（类型/消息/栈在行里） |
| ③-8 | 全绿且 Q4d 文档确实变了 | 回到格 ④ |

## 9.4 闸门（rc 都不经管道取）

```
PF 应用器 v3 --check（重放前）：rc=1（落盘件是 v1 = 1f8eb295…）
锚点：13 处（P6 五处 + Q0/Q1/Q2/Q3/Q4a/Q4b/Q4c-d/Q4e-f 八处）上游各**恰好 1 次**
断言：结构断言 37/37；大括号盈亏 319/319；`throw` = 上游 0 + 1 处故意 rethrow（点名断言）
--prove：rc=0；逆序回代后与上游**逐字节相同** ✓ 9e62a288543195b6a26b43f7f48c1ea00a573e490939f99a8e40ad9b8acaee93
        （== 上游 sha；落盘件是上一版时自动退化为内存证明并明说不背书）
/tmp 假树（只写 /tmp）：apply rc=0 → --check rc=0 → 再跑一次 sha 不变（幂等 ✅）→ 预测 sha 5430f349…
```

## 9.5 「吞异常点」的答案：**这条插入路径上一个 `catch` 都没有**（附计数）

主控要求"PF 里那些 `catch(Exception)` 的地方，把吞掉的东西打出来" —— **实测这条路径上不存在这种地方**：

| 文件（插入路径上的全部） | `catch` 计数 |
|---|---|
| `TextEditorTyping.cs` | **0** |
| `TextEditor.cs`（含 `SetSelectedText:431` / `SetText:413`） | **0** |
| `TextSelection.cs` | **0** |
| `TextRange.cs` | **0** |
| `TextContainer.cs` | **0** |
| `TextPointer.cs` | 0（`grep` 的那 1 处只是注释里的 "catch all errors"） |

`System/Windows/Documents/` 下属实有 `catch` 的文件都在**别的子系统**：
`TextEditorCopyPaste.cs`(8)、`RtfToXamlReader.cs`(9)、`Speller*.cs`、`TextEditorDragDrop.cs`(2)、
`TextEditorContextMenu.cs`(1)、`FixedDocument.cs`(2) … —— 与 `WM_CHAR → TextInput → 插入` 无交集。
**⇒ 这条路上不存在"静默吞异常"，异常只会往上抛**；而 Q4e 已把 `DoTextInput` 内的异常**全部**留痕
（唯一可能"吞"的是更外层的 Dispatcher 操作异常路径 —— 那属于格 ② 的范畴，需要 §9.6 的坐标才看得到）。

## 9.6 备用坐标（**只有判到格 ② "投了但没跑"才需要**，先不写）

**托管侧**（`WindowsBase/…/Threading/Dispatcher.cs`）：`ProcessQueue()` `:1986-1995`
（`backgroundProcessingOK = !IsInputPending()`、`maxPriority = _queue.MaxPriority`、是否出队 + 出队 op 的 `Priority`；每次只出队 1 个）
｜`:2002-2008` 出队后再取 `maxPriority` + `RequestProcessing()`
｜`_foregroundPriorityRange = PriorityRange(Loaded..Send)` `:2819`
｜`IsInputPending()` `:2271-2314`（`MsgWaitForMultipleObjectsEx(…, QS_INPUT|QS_EVENT|QS_POSTMESSAGE, MWMO_INPUTAVAILABLE)`）
｜`CriticalRequestProcessing` `:2323-2360` / `TryPostMessage` `:2391`→`OnRequestProcessingFailure` `:2394`
｜`RequestBackgroundProcessing` `:2402-2420` / `TrySetTimer` `:2415`→`:`2418
｜WndProc `_msgProcessQueue` `:2225-2227`、`WM_TIMER/TIMERID_BACKGROUND` `:2229-2236`。

**原生侧**（M7b 车道，**本轮没动**）：`win32_msg.c:788`（`QS_POSTMESSAGE` 在"队列里任何一条消息"上就置位）、
`:804`（`due_timer` 不看 `wakeMask`）、`:810`（`wpf_x11_pending()`）—— 这些**仍是**"`IsInputPending()` 可能偏真"的来源，
但在 T3 已证"四个优先级全执行"之后，**它们不再是头号嫌疑**（只在与格 ② 同时成立时才需要看）。

## 9.7 本轮**没做**（不假装绿）

1. **没写第 4 批**（`TextEditor.SetText` → `TextContainer`）：等这批读数定性（③-5 命中才需要）。
2. **没写 WB/原生探针**（§9.6 只是备用坐标清单，等授权）。**没动** `src/WpfGfx.Linux.Native/**`、`samples/**`、`build/shims/**`、native shim、`build/MilBridge/**` 里别人的文件。
3. **没生成物、没重放、没编译、没跑应用** ⇒ §9.2 的"实跑是否出现过"整列 `未跑`；"PF 生成物能编过"仍只有人工核对（**没有编译器证据**）。
4. §8.9 已写明 **`composition == null` 是预期的**（非 IME 输入 ⇒ `as FrameworkTextComposition` 返回 null ⇒ 走 `ScheduleInput`），**不是线索**。

---

# 第 4 批（Q5…Q9）：`TextContainer.Changed` → `TextBox.Text` DP（**待重放**）

## 10.0 命题改写 + 第 3 批实跑原文

```
Q0a ScheduleInput 入口 item=TextInputItem#fd727f AcceptsRichContent=False
Q0i **立即执行支路**（`!AcceptsRichContent || IsMouseInputPending`）⇒ 不经过 Background 投递
Q3  TextInputItem.Do() 入口 text="A" UiScope=TextBox#2ce2184
Q4a DoTextInput 入口 选区[0,7]="seed-文本"
Q4b _FilterText 后 过滤后="A"
Q4c 即将 SetSelectedText("A") 之前 选区[0,7]="seed-文本"
Q4d **SetSelectedText 返回后 len=1 text="A"**      ← **容器真的被改了**
Q4f DoTextInput 出口 UndoCloseAction=Commit len=1 text="A"
Q3c TextInputItem.Do() 正常返回 len=2 text="AB"
（无 Q4e ⇒ 无异常；无 Q3b；过滤后长度 ≠ 0）
```

| 项 | 结论 |
|---|---|
| 第 3 批判据 | **六格全绿到 Q4f**，`Q0i` 顺手**否掉了我那条"Background 投递"的猜测**（实际走**立即执行支路**：`AcceptsRichContent=False`）—— 我上一版把注意力放在 `BackgroundInputCallback` 上，**方向错了**，这条登记在案 |
| 命题 | **键入到了、容器改了、屏幕也画出来了**；坏的是 **`TextBox.Text` DP（与 `TextChanged`）停在旧值** |
| 证据 | T3 的**注入后帧**：TextBox 里就是 `AB` 加光标；而 `WFP_TEXTWATCH` 的 18 个时间点里 `_tb.Text` 一直是 `'seed-文本'` |
| 旧读数作废 | T3 此前两趟 burst 都在**注入之前** ⇒ "屏幕还是旧文本"**作废**；`changes>0` 这条判据**降为旁证**（主判据改为注入前后 `WFP_BOXID` 矩形内的像素/字形差异） |

## 10.1 交付物与 sha256（**新增 4 个生成物；其余一律不变**）

| 件 | sha256 |
|---|---|
| `tools/patch-presentationframework-textbox-textdp-trace.py`（**新**） | `f4eca0065b7575adc7419c2308a50ee029b1d8a986590546764659a4b9878493` |
| 生成物 `build/PresentationFramework.Linux/TextContainer.Linux.cs`（**含 tracer 类**） | `5a5cb2e709697933a6fa09011b84180ca5b744c4142baf12b8d6048652a7545e` |
| 生成物 `build/PresentationFramework.Linux/TextBoxBase.Linux.cs` | `e316a49dc3b336760404fbf17c29012d1d358b92047c1d868851dff84753bef0` |
| 生成物 `build/PresentationFramework.Linux/TextBox.Linux.cs` | `704e7aea3ebb30b09c9ed96736b4be96d0a80d791e075498fa5ff7f53c45c243` |
| 生成物 `build/PresentationFramework.Linux/DeferredTextReference.Linux.cs` | `1f144da79c6a9071a92e6bec9e422439f4599bee610cd90493374ef8f4c42b4c` |
| 其余（第 2/3 批的） | **不变**：`TextEditorTyping.Linux.cs` `5430f349…`（第 3 批预测值，尚未重放）｜PC 侧 `47934329…`/`70a5d54b…`/`e56065a8…`/`3a079a8f…`｜WB `cbb971f5…` |

**csproj**：本应用器往 PF csproj 注入 **8 行**（4 × `Remove` 上游 + 4 × `Include` 生成物，放在同一个 marker 块里）。
⚠️ `build/port-lib.py PresentationFramework` 会整份重写 csproj ⇒ 必须重跑本应用器；接线丢失**不报编译错**，只表现为"一行都不打"。
**波表**：`patch-presentationframework-textbox-textdp-trace` 名字落在 `patch-presentation*` 通配里（自动兜底会跑、会打 ⚠）⇒ 建议登记进 `APPLIERS_EXPLICIT`（顺序无依赖）。

## 10.2 逐点核对表（`file:line` = 重放后生成物行号；"实跑是否出现过"全列 `未跑`）

| 点 | 生成物:行 | helper | helper 定义行 | 上游锚点 | 实跑是否出现过 |
|---|---|---|---|---|---|
| **Q9a** `TextContainer.BeginChange(bool)` 计数自增后 | `TextContainer.Linux.cs:3567` | `Q9Begin` | `TextContainer.Linux.cs:230` | `TextContainer.cs:3307` | 未跑 |
| **Q5a** `EndChange(bool)` **入口**（计数未减） | `:597` | `Q5Entry` | `:246` | `:345-349` | 未跑 |
| **Q9b** `EndChange` 计数**自减后**（`0` ⇒ 该 raise；≠0 ⇒ 本次不 raise） | `:602` | `Q9End` | `:237` | `:351-353` | 未跑 |
| **Q5b** **raise 之前**（`ChangedHandler==null?` / `skipEvents` / changes 条数） | `:622` | `Q5BeforeRaise` | `:253` | `:370-375` | 未跑 |
| **Q5c** **raise 之后**（`ChangedHandler(this, changes)` 调过了） | `:629` | `Q5Raised` | `:261` | `:375` | 未跑 |
| **Q6a** `TextBoxBase.OnTextContainerChanged` **入口**（**在早退门之前**） | `TextBoxBase.Linux.cs:1362` | `Q6Entry` | `:269` | `TextBoxBase.cs:1348-1350` | 未跑 |
| **Q6** **早退门命中**（`!HasContentAddedOrRemoved && !HasLocalPropertyValueChange`） | `:1369` | `Q6BailNoContent` | `:277` | `:1352-1356` | 未跑 |
| **Q6b** 走到 `OnTextChanged(...)`（→ `RaiseEvent(TextChangedEvent)`）之前 | `:1412` | `Q6BeforeOnTextChanged` | `:284` | `:1393-1395` | 未跑 |
| **Q6c** 出口 | `:1421` | `Q6Exit` | `:292` | `:1398-1400` | 未跑 |
| **Q7a** `TextBox.OnTextContainerChanged` **入口**（守卫/嵌套计数/`_newTextValue` 类型） | `TextBox.Linux.cs:1208` | `Q7Entry` | `:300` | `TextBox.cs:1194-1200` | 未跑 |
| **Q7b** **到达 `SetCurrentDeferredValue(TextProperty, dtr)`** | `:1232` | `Q7SetDeferred` | `:312` | `:1213-1216` | 未跑 |
| **Q7c** finally 出口（`resetText` / 嵌套计数 / `_newTextValue` 收尾） | `:1266` | `Q7Exit` | `:320` | `:1218-1246` | 未跑 |
| **Q8a** `DeferredTextReference.GetValue` 入口（容器 + **`Parent` 类型**） | `DeferredTextReference.Linux.cs:55` | `Q8Entry` | `:328` | `DeferredTextReference.cs:41-43` | 未跑 |
| **Q8b** **取到的字符串**（DP 解析出的 `.Text` 新值） | `:60` | `Q8Value` | `:337` | `:43` | 未跑 |

**设计上的两条硬约束（都写进代码注释与断言）**
1. **探针不读任何 DP**（不碰 `this.Text` / `GetValue(TextProperty)`）：读 DP 本身会触发 deferred 解析 ⇒ **观测者效应**。
   只读**容器**文本（`TextRange(container.Start, container.End).Text`）与 `_newTextValue` 的**类型**。
2. **入口探针都在早退门之前**（`Q6a` 在 `:1352` 那道门之前、`Q5a` 在 `if (_changeBlockLevel == 0)` 之前、
   `Q7a` 在 `_isInsideTextContentChange` 守卫之前）⇒ "没打印"不再有多种含义。

**正常一跑应当出现的顺序**（DP 被推的那一串）：
```
Q9a BeginChange … Q5a/Q9b EndChange(归零) → Q5b(ChangedHandler 有?) → Q5c **Changed 已 raise**
   → Q6a → Q6b（或 Q6 早退门）→ Q6c
   → Q7a → Q7b **已 SetCurrentDeferredValue** → Q7c
   → （DP 真来读时）Q8a → Q8b **取到新串**
```

## 10.3 判据（**互斥**，从上往下第一条命中即结论）

| 格 | 观察 | 结论 / 下一步 |
|---|---|---|
| **①** | **Q5b/Q5c 从不出现**（且 Q9b 的计数**不归零**） | `Changed` **压根没 raise**：变更块没关（计数 > 0）⇒ 追**谁多调了一次 `BeginChange` / 少调了一次 `EndChange`**（Q9a/Q9b 的配对序列直接可数） |
| **①'** | Q9b 归零了、`Q5b` 打了但 `ChangedHandler=null` | **没人订阅** `TextContainer.Changed`（`TextBoxBase.cs:1435` 那条订阅丢了/被覆盖）⇒ 查订阅时序（`_textContainer` 换过？`OnTextContainerChanged` 被谁摘了？） |
| **②** | **Q5c 有、Q6a 无** | raise 了但 `TextBoxBase` 没收到 ⇒ 订阅链断（同上那条订阅，或 sender 不是这个 `TextBoxBase` 实例） |
| **③** | **Q6a 有、Q6 早退门命中** | `TextChanged` 被 **`:1352` 那道门**挡回去（`!HasContentAddedOrRemoved && !HasLocalPropertyValueChange`）⇒ `TextContainerChangedEventArgs` 没标"内容增删"（这是**新出现**的读法：插入明明改了容器） |
| **④** | **Q6b 有、Q7a 无** | `TextBoxBase` 转发断了（PF 多态/`OnTextContainerChanged` override 未被调到） |
| **⑤** | **Q7a 有、Q7b 无** | `_isInsideTextContentChange` 守卫卡住（`Q7a` 行里直接读得到它是 `True`）⇒ 上一轮 change 没收尾（`_changeEventNestingCount` 不为 0） |
| **⑥** | **Q7b 有、Q7c 有、Q8 从不出现** | DP 被推成 deferred **但没人来读** ⇒ `.Text` 的 getter 路径/绑定没触发（下一批：`TextBox.Text` getter + `OnDeferredTextReferenceResolved`） |
| **⑦** | **Q8b 取到新串**（`len=2 "AB"`）而样例读回仍旧 | 问题在 **DP 值解析/缓存链**（下一批：`DeferredTextReference.OnDeferredTextReferenceResolved`、`TextBox.Text` getter、`GetValue` 的 value-source 分支） |
| **⑧** | **Q8a 的 `Parent=(null)`** | `tb?.OnDeferredTextReferenceResolved` **不会调**（容器没有 TextBox 父）⇒ DP 与容器**永不同步**（这条单独成格，因为它会静默） |
| **⑨** | **Q7c `resetText=True`** | 命中"DP 值与容器不一致 ⇒ 需要把容器拉回"的分支（`FrameworkCompatibilityPreferences.KeepTextBoxDisplaySynchronizedWithTextProperty`）⇒ 结合 Q8 一起读 |

## 10.4 闸门（rc 都不经管道取）

```
新应用器 --check（重放前）：rc=1（4 个生成物都不存在 + 未接线）
锚点：13 处（TC 5 / TBB 4 / TB 3 / DTR 1）上游各**恰好 1 次**
断言：每个文件 `throw` 条数逐字不变（3==3 / 10==10 / 3==3 / 0==0）；大括号盈亏一致（451 / 276 / 223 / 5）；
      结构断言 12+5+4+3 = 24/24 全中；行数 +247 / +10 / +8 / +6
--prove：rc=0；四个文件**逆序回代后都与上游逐字节相同** ✓
      72af0364…（TC）· f27c058d…（TBB）· 91c52a19…（TB）· 317e13af…（DTR）
/tmp 假树（只写 /tmp）：apply rc=0 → --check rc=0 → 再跑一次 sha 不变（**幂等 ✅**）
```

## 10.5 下一批的入口坐标（**先记下，等这批读数定性**）
`DeferredTextReference.OnDeferredTextReferenceResolved`（被 `GetValue` 回调的那一格）·
`TextBox.Text` 的 **getter 路径**（`GetValue(TextProperty)` 的 value-source 分支 / `DeferredTextReference` 的缓存与失效）·
`TextBoxBase.OnTextChanged`（`:1000`）→ `RaiseEvent(TextChangedEvent)`（`:1395` 之后那一段）。

## 10.6 本轮**没做**（不假装绿）
1. **没生成物、没重放、没编译、没跑应用**（按主控指令统一重放）⇒ §10.2 的"实跑是否出现过"整列 `未跑`。
2. **"能编过"没有编译器证据**：4 个生成物的探针全部用 `object` 形参 + 内部 `as`/try-catch；
   跨命名空间引用**全限定**（`System.Windows.Documents.WpfLinuxPfTextDpTrace.…`）；
   调用点只传**原有变量**（`this._textContainer` / `_changeBlockLevel` / `this.ChangedHandler` / `changes` /
   `_isInsideTextContentChange` / `_changeEventNestingCount` / `_newTextValue` / `dtr` / `s`），**没引入新变量、没改任何原有语句顺序**。
3. 我上一版把嫌疑押在 `BackgroundInputCallback` 上（`AcceptsRichContent=False` ⇒ 实际走立即执行支路）—— **方向错了**，已在上文登记。

---

# 第 5 批（W1…W4）：**读路径为什么不解析 deferred**（WindowsBase，**待重放**）

## 11.0 第 4 批实跑 + 断点收窄（**主武器换到 WB**）

```
Q9a/Q9b/Q5a 各 28 条 ⇒ 变更块计数**平衡**；Q9b ⇒ _changeBlockLevel=0（归零 ⇒ 该 raise Changed）
Q5b 即将 raise Changed：**ChangedHandler=有** … HasContentAddedOrRemoved=True
Q5c **Changed 已 raise**（订阅者被调）        Q6a TextBoxBase.OnTextContainerChanged 入口 ×3
Q6b 即将 RaiseEvent(TextChangedEvent) undoAction=Clear/Create/Merge ⇒ **:1352 那道门没挡**
Q7a … _isInsideTextContentChange=True(首次)/False(两次真编辑) _changeEventNestingCount=0
Q7b **已 SetCurrentDeferredValue(TextProperty, DeferredTextReference#…)** ×2（容器 len=1 "A" / len=2 "AB"）
Q7c 出口 resetText=False ×3                   **Q8a/Q8b = 0 行**（`DeferredTextReference.GetValue` 一次都没被调）
```

| 项 | 结论 |
|---|---|
| 第 4 批判据 | 命中**⑥格**：**PF 侧全链绿**，`TextProperty` 已被推成 `DeferredTextReference`，但**从来没人解析它** |
| T3 的口径修正（**采纳**） | 不是"没人读"——样例 `WFP_TEXTWATCH` 读了 **18 次** `_tb.Text`（外加 Verify/LateVerify）而 `Q8` 一次没触发 ⇒ **读路径从不解析 deferred**，读者一直拿到旧 local 值 |
| PF 侧处置 | **PF 可以停了**：只留 `Q8a/Q8b` 作**哨兵**（`DeferredTextReference.GetValue` 入口/取值），不再加别的 |

## 11.1 交付物与 sha256（**新增 1 个生成物**；其余一律不变）

| 件 | sha256 |
|---|---|
| `tools/patch-windowsbase-dpvalue-trace.py`（**新**，第 5 批主武器） | `3ed499887ac7279201f82b5d106f8762f8522969944e5a385b85220a33838a78` |
| 生成物 `build/WindowsBase.Linux/DependencyObject.Linux.cs`（含 tracer 类 `WpfLinuxDpValueTrace`） | **`f898a901c45e638d110a8c8e5e3317b9466668c8374ff436af4be7b9fe01b3ef`**（修 CS0103 之后；仓库里现在那件 `8909dd56…` 是**坏件**） |
| 其余 | **不变**：`Dispatcher.Linux.cs` `cbb971f5…`｜PF 侧 `TextEditorTyping.Linux.cs` `5430f349…`｜`TextContainer/TextBoxBase/TextBox/DeferredTextReference.Linux.cs`（第 4 批，已装）｜PC 侧五个不变 |

**csproj**：往 `build/WindowsBase.Linux/WindowsBase.Linux.csproj` 注入 **2 行**（`Remove` 上游 `DependencyObject.cs` + `Include` 生成物，独立 marker 块，与第 1 批 `Dispatcher` 那块并存）。
⚠️ `build/port-lib.py WindowsBase` 会整份重写 csproj ⇒ **两块都要靠重跑各自应用器恢复**；接线丢失**不报编译错**、只表现为"一行都不打"。
**波表**：`patch-windowsbase-dpvalue-trace` **不在** `patch-presentation*` 通配里 ⇒ **必须显式登记进 `APPLIERS_EXPLICIT`**（与 `patch-windowsbase-msgflow` 同理）。

## 11.2 逐点核对表（`file:line` = 重放后生成物行号；"实跑是否出现过"全列 `未跑`）

| 点 | 生成物:行 | helper | helper 定义行 | 上游锚点 | 实跑是否出现过 |
|---|---|---|---|---|---|
| **W1** `GetValue(dp)` **入口**（dp.Name/OwnerType，**在 VerifyAccess/ThrowIfNull 之前**） | `:429` | `W1GetValue` | `:199` | `DependencyObject.cs:156-158` | 未跑 |
| **W2** `GetEffectiveValue` **入口**（requests / `IsDeferredReference` / `HasModifiers` / `HasExpressionMarker` / `entry.Value`+`effectiveEntry.Value` 类型） | `:577` | `W2Entry` | `:207` | `:295-301` | 未跑 |
| **W3a** **提前返回（不解析）** ⇒ 判 **A/B**；B 再打**调用栈前 4 帧** | `:582` | `W3EarlyReturn` | `:224` | `:303-305` | 未跑 |
| **W3b** **真解析（经典路径** `!HasModifiers && !HasExpressionMarker`） | `:615` | `W3ResolvedLocal` | `:240` | `:321-336` | 未跑 |
| **W3c** 修改值分支 `reference == null` ⇒ 提前返回（C 的一种） | `:653` | `W3BailModifiedNull` | `:250` | `:370-373` | 未跑 |
| **W3d** 修改值分支**真解析**（expression / coerced 里带的 deferred） | `:682` | `W3ResolvedModified` | `:264` | `:375-399` | 未跑 |
| **W4a** `SetValueCommon` **`newEntry.Value = value`** 之后（**写侧留没留住 deferred 标记**） | `:1062` | `W4StoreLocal` | `:281` | `:773-777` | 未跑 |
| **W4b** `SetValueCommon` **出口**（`UpdateEffectiveValue` 之后 newEntry 最终形态） | `:1110` | `W4AfterUpdate` | `:296` | `:813-822` | 未跑 |
| （哨兵，PF 侧第 4 批）`DeferredTextReference.GetValue` 入口/取值 | `DeferredTextReference.Linux.cs:55/:60` | `Q8Entry/Q8Value` | — | `:41/:43` | 未跑 |

**三条硬约束**（都写进代码注释与断言）
1. **只对 `dp.Name == "Text"` 打**：`GetValue`/`GetEffectiveValue` 是全进程最热的 DP 路径，不过滤 200 行会被瞬间吃光（过滤在 `s_enabled` 之后、helper 内部）。
2. **入口探针在各早退门之前**：W1 在 `VerifyAccess`/`ThrowIfNull` 之前；W2 在 `:303` 那道提前返回**之前**。
3. **探针不读任何 DP**（读 DP = 观测者效应）；**字段读取全部在 helper 内部 try/catch**，
   **调用点只传已有局部变量/结构体副本**（不在调用点做数组下标或字段访问 ⇒ 不会在调用点抛异常、不改变控制流）。

**关于"W1 打返回值的类型"**：改成在 **W3 的四个出口**各打一行（W3a/W3b/W3c/W3d 都打"返回的值"）。
理由：① 那里既能拿到**类型**又能判**是哪条路径**；② 保持**纯插入**——若在 `GetValue` 里把 `return …Value;` 拆成"局部变量 + return"才能打类型，那就成了**等价改写**，会把"只插入"这条机械保证降级。⇒ 这是**故意保留纯插入**的取舍，读数能力不减。

## 11.3 判据（**互斥**，从上往下第一条命中即结论）

| 格 | 观察 | 结论 / 下一步 |
|---|---|---|
| **①** | W1 有、**W2/W3a/W3b/W3c/W3d 全无** | 读路径**根本没走到 `GetEffectiveValue`**（走了别的 getter，如 `GetValueEntry` 的其它重载 / `ReadLocalValue`）⇒ 查 T3 那边 `_tb.Text` 具体读的是哪条 API |
| **② = A** | **W3a** 有且 `原因=A：effectiveEntry.IsDeferredReference == false` | **写侧没留住 deferred 标记** ⇒ 看 **W4a/W4b** 的 `isDeferredReference` / `newEntry.Value` / `newEntry.IsDeferredReference`（若 W4a 显示 `newEntry.Value=DeferredTextReference` 而 W3a 显示 `IsDeferredReference=false` ⇒ **存进去后标记在别处被清/被替换**，追 `UpdateEffectiveValue` 与 `GetFlattenedEntry`） |
| **③ = B** | **W3a** 有且 `原因=B：requests 带了 DeferredReferences/RawEntry` | **读方主动要"原始 deferred"** ⇒ 直接读 W3a 打出的**调用栈前 4 帧**（谁读的、在哪一行）——那是 PF/上游别处的读法，不是 DP 引擎的锅 |
| **④ = C1** | **W3c** 有（修改值分支 `reference == null`） | `HasModifiers` 为真但拿不到 deferred ⇒ 它**不是** expression 也不是 coerced ⇒ 追"谁给 `Text` 加了 modifier"（`IsExpression`/`IsCoerced` 的值就在行里） |
| **⑤ = C2** | **W3b 或 W3d** 有 | **路径其实通了**（deferred 被解析、DP 拿到新值）⇒ 那么 `Q8` 哨兵**该有行**；若哨兵仍无行 ⇒ **矛盾**，回头查哨兵（`Q8` 是否被别的路径绕过、或 `GetValue` 的返回值被丢弃） |
| **⑥** | **W4a/W4b 有、W3a/W3b/W3c/W3d 全无** | 写侧有、读侧压根没进来 ⇒ 同 ① （读的不是这条路径） |

**注意**：本批**只判 A/B/C 与"读路径到没到"**；**不**判"为什么 `.Text` getter 返回旧值" —— 那要等本批读数落格（若落到 ⑤ 或 ①）。

## 11.4 闸门（rc 都不经管道取）

```
新应用器 --check（重放前）：rc=1（生成物不存在 + 未接线）
锚点：8 处上游各**恰好 1 次**（W0 插桩类 / W1 / W2+W3a / W3b / W3c / W3d / W4a / W4b）
断言：`throw` 16==16；大括号盈亏 530/530；结构断言 19/19；行数 3490 → 3767（+277）
--prove：rc=0；逆序回代后与上游**逐字节相同** ✓ edeb712d0bc7b4333e7f5cdde2061b029386f444c130d18574e28ec72a44da48（== 上游 sha）
/tmp 假树（只写 /tmp）：apply rc=0 → --check rc=0 → 再跑一次 sha 不变（**幂等 ✅**）→ 预测 sha 8909dd56…
```

## 11.5 下一批的入口坐标（**等本批读数定性**）
`EffectiveValueEntry.GetFlattenedEntry(requests)`（deferred 标记在"展平"时会不会被丢）·
`UpdateEffectiveValue` / `SetEffectiveValue`（落表时标记的去留）·
`DependencyObject.ReadLocalValue` / `GetValueEntry` 的**其它重载**（若判到 ①：读的根本不是这条路）。

## 11.6 本轮**没做**（不假装绿）
1. **没生成物、没重放、没编译、没跑应用**（按主控指令统一重放）⇒ §11.2 的"实跑是否出现过"整列 `未跑`。
2. **"能编过"没有编译器证据**：探针全用 `object`/结构体形参 + helper 内 try/catch；`RequestFlags`/`EffectiveValueEntry`
   都是同程序集类型（`System.Windows`，与本文件同 namespace）；调用点只传**已有局部变量或结构体副本**，
   **没引入新变量、没改任何原有语句顺序、没动任何 `if`/`return`**。
3. PF 侧按主控要求**停止加探针**，只留 `Q8a/Q8b` 哨兵。


## 11.7 第 5 批**修正记录**：CS0103（被集成波的构建步骤抓住）

```
build/WindowsBase.Linux/DependencyObject.Linux.cs(682,86): error CS0103: 当前上下文中不存在名称"referenceFromExpression"
682: WpfLinuxDpValueTrace.W3ResolvedModified(this, dp, entry, effectiveEntry, referenceFromExpression);
```

**根因**：`referenceFromExpression` 是在**修改值分支的内部作用域**里声明的（上游 `DependencyObject.cs:348-350`：
`ModifiedValue modifiedValue = …; DeferredReference reference = null; bool referenceFromExpression = false;`），
而 W3d 那一行落点在上游 `:396` 之后的 `_effectiveValues[...] = entry;` / `effectiveEntry.Value = value;` 段 —— **已经在那个 else 块之外** ⇒ 变量不可见。

**修法（取主控方案 (a)，**没有**为了好看动上游控制流）**：把 W3d **挪进 else 块之内**（插在 `effectiveEntry.Value = value;` 之后、块的 `}` 之前）。
⇒ 读数能力不减（"哪条腿解析的"照样可见），且**仍是纯插入**。**没有**采用 (b)"去掉实参"——因为那会白丢一个读数。

**同一坑的全量复查（不留第二处）** —— 新写了一把机械尺子：

    build/MilBridge/tools/t1c-trace-args-scope.py        # 机械审计"调用点实参在不在可见作用域"

做法：对每个 `WpfLinux*Trace.X(args)`，把**裸标识符实参**逐个核 ——
① 是否方法形参（含**多行形参**：上游 `GetEffectiveValue`/`SetValueCommon` 都是多行的）；
② 是否是**类作用域字段/属性**（类体内声明 ⇒ 任意深度可见）；
③ 其它局部变量 ⇒ **声明处的大括号深度必须 ≤ 调用处深度**（更深 ⇒ **CS0103**）；
④ 继承来的成员走显式白名单（如 `InputItem.TextEditor`）。

**牙齿测试（先红后绿）**
```
坏件（仓库里现在那件 8909dd56…）：  !! DependencyObject.Linux.cs  调用点 8  SUSPECT 1
                                      :682 W3ResolvedModified(…) 实参 `referenceFromExpression`
                                           **声明在更深的块里（深度 4 > 调用点 3）⇒ CS0103**      ⇒ rc=1
修好后的预测件（f898a901…）：        OK DependencyObject.Linux.cs  调用点 8  SUSPECT 0            ⇒ rc=0
全量（b2/b3/b4/b5/b7 五棵预测树）：   **109 个调用点，SUSPECT 0**                                  ⇒ rc=0
仓库已装好的各批生成物：             **68 个调用点，SUSPECT 1**（就是上面那件坏件；其余全绿）
```
⇒ 这一族（"变量在更深的块里声明"）**现在有机械闸门了**；但要说清局限：它是**启发式**，
**不查类型、不查 `using`/重载、不做同名遮蔽分析** ⇒ **仍不能替代编译器**。

**两条教训（已升级为流程要求，写进本报告顶部横幅）**
1. **预测 sha ≠ 能编过**：它只证明"生成器确定性"（同上游 + 同应用器 ⇒ 同字节）。第 5 批第一版的预测 sha 是对的，
   代码是错的 —— 这正是"**别拿一个读数当另一个读数的证据**"。
2. **`--prove` ≠ 能编过**：它只证明"插入是纯插入"（逆代后与上游逐字节相同）。两条**互相独立**。
   ⇒ 凡新增/改动调用点：① 过 `t1c-trace-args-scope.py`；② 报告里逐条核"实参在作用域内、类型匹配、不是 DP 读取"；③ 明写"**仍未编译**"。

**修正后的交付**
| 件 | sha256 |
|---|---|
| `tools/patch-windowsbase-dpvalue-trace.py`（**已修**） | `3ed499887ac7279201f82b5d106f8762f8522969944e5a385b85220a33838a78` |
| 生成物 `DependencyObject.Linux.cs`（**重放后应当是**） | **`f898a901c45e638d110a8c8e5e3317b9466668c8374ff436af4be7b9fe01b3ef`** |
| （仓库里现在那件 = 波失败时生成的坏件） | `8909dd56b31d44872431ecd2a89d854c88c2d224e323a8ced769fd8982cab3fe` |
| 机械审计器（**新**） | `build/MilBridge/tools/t1c-trace-args-scope.py` = `f63cf04c69f78a8f10dd6f8c79a353ec15bf6e9380868f43c6569d4003635116` |
闸门：`--check` 重放前 rc=1（生成物是坏件版）；锚点 8 处各 1 次；`throw` 16==16；大括号盈亏 530/530；结构断言 19/19；
`--prove` rc=0（逆代后与上游逐字节相同 `edeb712d…`）；/tmp 里 apply rc=0 → `--check` rc=0 → 幂等 ✅。
其余 **7 个应用器 `--check` 仍全 rc=0**（没把已装好的批次弄坏）。

---

# 第 6 批（W4 身份 / W5 写入口 / W6 有效值槽 / W7 flatten）：**谁把它换回去了**（**待重放**）

## 12.0 第 5 批实跑 → 命中 **A 格**，问题变成"两者之间谁把槽换回普通字符串"

```
（写侧，"Text"/TextBox）
W4a SetValueCommon newEntry.Value = value 写入的 value=DeferredTextReference isDeferredReference=True newValueHasExpressionMarker=False
W4b SetValueCommon 出口（UpdateEffectiveValue 之后）⇒ newEntry.Value=**ModifiedValue** IsDeferredReference=**True**
（读侧，每次 WFP_TEXTWATCH 都对应一组）
W1 GetValue 读 "Text" OwnerType=TextBox target=TextBox#13fa1bf requests=FullyResolved
W2 GetEffectiveValue 入口 effectiveEntry.IsDeferredReference=**False** entry.HasModifiers=False entry.HasExpressionMarker=False entry.Value=string(len=7) "seed-文本"
W3a 提前返回（不解析） 原因=**A：effectiveEntry.IsDeferredReference == false**
```

| 项 | 处置 |
|---|---|
| 观测缺口（主控点名） | 第 5 批 W4a/W4b 的 `target=` **在行尾**（易被截断）⇒ 本批把 `target=` 挪到**行首**并加 `dp.GlobalIndex` / `entryIndex`，与读侧 W1 的 `target=` 可直接对齐 |
| 候选（互斥） | **a** 写读不是同一个对象/属性 ｜ **b** deferred 写之后**还有一次 `value=string` 的写**（栈指人）｜ **c** 没有第二次写、但 `UpdateEffectiveValue` **出口**时有效值槽已非 deferred ｜ **d** 三者都不成立 ⇒ 读侧取错槽位/索引 |

## 12.1 交付物与 sha256（**两个生成物都会变**；其余一律不变）

| 件 | sha256 |
|---|---|
| `tools/patch-windowsbase-dpvalue-trace.py`（**第 5 批 + 第 6 批 + CS1503 修正**） | `a689691ce0b1308f154c842b9873ee0302524838cb7a778edf32e643e064b207` |
| **新** `tools/patch-windowsbase-entry-flatten-trace.py`（W7） | `901a2f92875256f1f5b54e7ecb07e8e319e98fbdf075cd9dd167111aa57c9906` |
| 生成物 `build/WindowsBase.Linux/DependencyObject.Linux.cs` | **`e2118ef2ecdb2e51e897a6b5ab643cbcb88a45098f80f641f2e10d39d667f8ac`**（CS1503 修正后；`fda25e29…` 是**编译失败的那一版**） |
| **新**生成物 `build/WindowsBase.Linux/EffectiveValueEntry.Linux.cs` | **`c53a2f1a27dc98c430e2a7ee0a9f0e1464207dfa3b97f23b8a72dbd9fcf51c0f`** |
| 其余 | **不变**（Dispatcher.Linux.cs `cbb971f5…`｜PF 四个第 4 批 + `TextEditorTyping 5430f349…`｜PC 五个） |

**波表（两个都要登记，名字都不在 `patch-presentation*` 通配里）**：`patch-windowsbase-dpvalue-trace`、`patch-windowsbase-entry-flatten-trace`。
**依赖**：`EffectiveValueEntry.Linux.cs` 用到的 tracer 类定义在 `DependencyObject.Linux.cs`（同 namespace/程序集）
⇒ **两个应用器必须同波应用**；B 的 `--check` 会**显式核对** A 的接线标记，缺了就报错（避免"只应用一个"时的 CS0103）。
csproj 各注入 2 行（4 行合计，两个独立 marker 块）。


> ⚠️ **sha 以 §12.8 为准**：§12.1/§12.7 里的第 6 批 sha 已被两次修正覆盖
> （① CS1503 的 `uint`→`int`；② 运行期"实参不惰性"的 NRE）。**当前生效**的应用器/生成物 sha 见 §12.8 末尾那张表。

## 12.2 逐点核对表（`file:line` = 重放后生成物行号；"实跑是否出现过"全列 `未跑`）

| 点 | 生成物:行 | helper | helper 定义行 | 上游锚点 | 实跑是否出现过 |
|---|---|---|---|---|---|
| **W5a** `SetValue(dp,value)` 入口 | `DependencyObject.Linux.cs:782` | `W5WriteEntry` | `:199` | `:407-413` | 未跑 |
| **W5b** `SetCurrentValue` 入口 | `:810` | ↑ | ↑ | `:434-438` | 未跑 |
| **W5c** `SetValueInternal` 入口 | `:854` | ↑ | ↑ | `:475-481` | 未跑 |
| **W5d** `SetCurrentValueInternal` 入口 | `:876` | ↑ | ↑ | `:495-501` | 未跑 |
| **W5e** `SetDeferredValue` 入口 | `:892` | ↑ | ↑ | `:512-515` | 未跑 |
| **W5f** `SetValue(key,value)` 入口 | `:944` | ↑ | ↑ | `:559-565` | 未跑 |
| **W5g** `CoerceValue` 入口 | `:1463` | ↑ | ↑ | `:1064-1070` | 未跑 |
| **W5h** `SetValueCommon` 入口（**在 `if (IsSealed)` 之前**） | `:1006` | ↑ | ↑ | `:616-625` | 未跑 |
| **W4a** 存值之后（**身份在行首** + `entryIndex`） | `:1161` | `W4StoreLocal` | `:315` | `:773-777` | 未跑 |
| **W6a** 进 `UpdateEffectiveValue` **之前**（operationType + new/old + **当前有效值槽**） | `:1199` | `W6BeforeUpdate` | `:371` | `:813` | 未跑 |
| **W6b** 出 `UpdateEffectiveValue` **之后**（**有效值槽**的 `IsDeferredReference`/`Value`） | `:1213` | `W6AfterUpdate` | `:391` | `:813-821` | 未跑 |
| **W7a** `GetFlattenedEntry` 无修饰 ⇒ `return this` | `EffectiveValueEntry.Linux.cs:336` | `W7Flatten` | `:341`（在 `DependencyObject.Linux.cs`） | `EffectiveValueEntry.cs:322-326` | 未跑 |
| **W7b** 只有表达式标记 ⇒ `return unsetEntry` | `:358` | ↑ | ↑ | `:329-343` | 未跑 |
| **W7c** 有修饰 ⇒ `return entry`（展开后的值） | `:442` | ↑ | ↑ | `:423-425` | 未跑 |

**W5 每次必打**（只对 `dp.Name=="Text"`），并各带 **调用栈前 4 帧** ⇒ "谁写的"直接指人
（嫌疑名单：PF 的 `TextBox.OnTextPropertyChanged` / `OnTextContainerChanged` 的 `resetText` 支路 / `CoerceValueCallback`…**但以栈为准**）。
**W6a 的下标安全性有上游依据**：上游自己在**同一个位置前 6 行**读过 `_effectiveValues[entryIndex.Index]`（`:807` 的 `EvaluateExpression(...)` 实参）
⇒ 我的插入与它同等安全；**W6b 的下标越界检查放在 helper 内**（调用点不做下标访问 ⇒ 调用点不抛异常、控制流不变）。
**W7 的有界性**：`GetFlattenedEntry` 对**每个 DP 读**都会走且**没有 `dp` 参数** ⇒ 不能用 `dp.Name` 过滤；
改用 `IsDeferredReference || requests 带了 DeferredReferences/RawEntry` 过滤（非 deferred 静默）✓ 不会刷屏。

## 12.3 判据（**互斥**，从上往下第一条命中即结论）

| 格 | 观察 | 结论 / 下一步 |
|---|---|---|
| **a** | W4a/W4b 的 `target=`/`dp.GlobalIndex=` **≠** 读侧 W1 的 | **写读不是同一个对象/属性** ⇒ D-P1 的归属要重写（"观测对象不是同一个"那一族） |
| **b** | 目标相同，且 deferred 写**之后**还有一次 `value=string` 的写（W5 行 + **栈前 4 帧**） | **谁把它换回去的就是根因**，栈直接指人 |
| **c** | 没有第二次写，而 **W6b** 显示 `有效值槽.IsDeferredReference=False`（或槽值已是旧串） | **有效值槽被写坏**（`UpdateEffectiveValue` 内部）⇒ 下一批进 `UpdateEffectiveValue`/`SetEffectiveValue` |
| **d** | 三者都不成立（W6b 显示槽里确实是 deferred，读侧却拿到非 deferred 的 effectiveEntry） | **读侧取错槽位/索引** ⇒ 下一批看 `LookupEntry`/`entryIndex`/`GetFlattenedEntry` 的 W7 读数 |

## 12.4 闸门（rc 都不经管道取）

```
A（patch-windowsbase-dpvalue-trace）--check 重放前：rc=1（生成物是第 5 批那件/坏件）
 锚点 16 处各**恰好 1 次**（W0/W1/W2+W3a/W3b/W3c/W3d/W4a/W6 + **W5 八个写入口**）；`throw` 16==16；大括号盈亏 543/543；
 结构断言 26/26；行数 3490 → 3847（+357）；--prove rc=0（逆代后与上游逐字节相同 edeb712d…）
B（patch-windowsbase-entry-flatten-trace）--check 重放前：rc=1（生成物不存在 + 未接线）
 锚点 3 处各 1 次；`throw` 0==0；大括号盈亏 132/132；结构断言 6/6；--prove rc=0（7c59ac37…）
/tmp 假树（只写 /tmp）：A→B 顺序 apply 均 rc=0；两个 --check 均 rc=0；再跑一次 sha 不变（**幂等 ✅**）
预测 sha：DependencyObject fda25e29… / EffectiveValueEntry c53a2f1a…
```

**机械尺子（上一批 CS0103 之后新增的流程要求，本次已跑）**
```
python3 build/MilBridge/tools/t1c-trace-args-scope.py <第6批两件生成物>
  OK DependencyObject.Linux.cs     调用点 17  SUSPECT 0
  OK EffectiveValueEntry.Linux.cs  调用点  3  SUSPECT 0
全量（b2/b3/b4/b5/b8 五棵预测树）：**121 个调用点，SUSPECT 0**（上一批是 109 个）
```
⇒ 本批**新增/改动的 20 个调用点**的实参全在可见作用域内；**但仍未编译**（预测 sha 只证生成器确定性、`--prove` 只证纯插入）。

## 12.5 顺带发现：上游那条断言**正是本族的断言**，但在 Release 下被编译掉

`EffectiveValueEntry.cs:423`：
```csharp
Debug.Assert(entry.IsDeferredReference == (entry.Value is DeferredReference),
    "Value and DeferredReference flag should be in sync; hitting this may mean that it's time to divide the DeferredReference flag into a set of flags, one for each modifier");
```
它说的就是"**flag 与 value 必须同步**"——正是我们 A 格（写侧 True / 读侧 False）违反的不变式。
`Debug.Assert` 是 `[Conditional("DEBUG")]` ⇒ **Release 下整句被编译掉** ⇒ 它没能替我们发现这个问题。
（登记在案：Linux 上"哪些断言还活着"值得单独清一遍；M7b 的 `Invariant` 补丁只覆盖了 `Invariant.Assert`。）

## 12.6 本轮**没做**（不假装绿）
1. **没生成物、没重放、没构建、没跑应用**（按主控指令统一重放）⇒ §12.2 的"实跑是否出现过"整列 `未跑`。
2. **未编译**：探针全用 `object`/结构体形参 + helper 内 try/catch；`_effectiveValues` 以**数组实参**传入、越界检查在 helper 内；
   调用点只传已有局部变量/字段；**没引入新变量、没改任何原有语句顺序**。机械尺子 121/0 只是"作用域"这一维的证据。
3. 第 5 批那件**坏件**仍在仓库里（`8909dd56…`）—— 重放时会被本次的 `fda25e29…` 覆盖。


## 12.7 第 6 批**修正记录**：两处 CS1503（`uint` → `int`）+ **自带编译证据**

```
build/WindowsBase.Linux/DependencyObject.Linux.cs(1161,132): error CS1503: 参数 7: 无法从"uint"转换为"int"
build/WindowsBase.Linux/DependencyObject.Linux.cs(1213,83):  error CS1503: 参数 5: 无法从"uint"转换为"int"
```

**根因**：`EntryIndex.Index` 是 **`uint`**（`EntryIndex.cs:39 public uint Index`；顺带核了 `DependencyProperty.GlobalIndex` 是 **`int`**），
而 `W4StoreLocal` / `W6AfterUpdate` / `Tgt` 的形参写的是 `int`。

**修法：取方案 (b)，但用 `long` 而不是 `uint`** —— 理由：`Tgt(...)` 除了接 `entryIndex.Index`（uint）还要接**哨兵 `-1`**（W5 的"没有 entryIndex"那几行），
`uint` 形参接不了 `-1` ⇒ 用 `long` 两边都容得下，**并且调用点一个表达式都不用加**（"只插入"的纯粹性完整保留）。
`W6AfterUpdate` 里的越界判断相应改成 `entryIndex >= 0 && entryIndex < (long)slots.Length`（helper 内，调用点仍不做下标）。

**全量扫了一遍形参类型 vs 实参类型**（不只是这两处）：本批新增的 `dp.GlobalIndex`(int)、`entryIndex`(uint)、`IsDeferred…`(bool)、`operationType`(enum)
与历史各批（PC 的 `IntPtr/int/bool`、PF 的 `int/bool/string`、WB msgflow 的 `int/IntPtr`）**逐条过**；唯一不一致就是这两处，已修。

**尺子升级（类型-lite）**：`build/MilBridge/tools/t1c-trace-args-scope.py` 现在做两件事 ——
① 作用域（原有）；② **形参类型 vs 实参类型**：认 `uint/int/long/bool/string` 字面量、`(int)` 这类强制转换、
以及**已知成员类型**（`EntryIndex.Index`=uint、`DependencyProperty.GlobalIndex`=int、`.Length`/`.Count`=int、`.Handled`=bool…）；
隐式转换表很小很保守（**不含 uint→int、long→int**）；**判不了的一律列出来**（本轮 91 条，不静默放过）。

**牙齿测试（先红后绿，坏件用的是波失败那一版 `fda25e29…`）**
```
坏件（fda25e29…，/tmp/t1c/b8）：
  !! DependencyObject.Linux.cs  调用点 17  作用域SUSPECT 0  类型SUSPECT 2
     :1161 W4StoreLocal(…)  实参 `entryIndex.Index` **类型不匹配：实参 uint → 形参 int（CS1503 那一族）**
     :1213 W6AfterUpdate(…) 实参 `entryIndex.Index` **类型不匹配：实参 uint → 形参 int（CS1503 那一族）**
修好后（仓库件 e2118ef2…）：OK 调用点 20  作用域SUSPECT 0  类型SUSPECT 0
全量（PC+PF+WB 所有已装好的生成物）：**调用点 80，作用域SUSPECT 0，类型SUSPECT 0，判不了 91 条（已列出）**
```
（顺带修掉尺子自己的两个假阳性：多行/单行签名要存**原始形参串**才能拿到类型；`for (int i…)` 的 `i` 曾被当成 `ref:for`。）

**✅ 已编译（自带编译器证据）**
```
export PATH="$HOME/.dotnet:$PATH"; export DOTNET_CLI_TELEMETRY_OPTOUT=1
dotnet build build/WindowsBase.Linux/WindowsBase.Linux.csproj -m:1 --nologo -v q \
    -p:BaseOutputPath=/tmp/t1c-verify/bin/ -p:BaseIntermediateOutputPath=/tmp/t1c-verify/obj/

    0 个警告
    0 个错误
已用时间 00:00:08.03          BUILD_RC=0
```
- **不污染仓库 `bin/obj`**：产物落在 `/tmp/t1c-verify/**`（`/tmp/t1c-verify/bin/Debug/WindowsBase.dll` 1234432 字节，
  `/tmp/t1c-verify/obj/Debug/WindowsBase.Linux.csproj.FileListAbsolute.txt` 里含 **3 个 `*.Linux.cs`** ⇒ 两份生成物确实参与了编译）。
- **时间线核对**：`DependencyObject.Linux.cs` 写盘 `18:41:18` ⇒ DLL `18:41:50`（先应用、后编译，编的是修好的那一版）。
- **范围**：本批只改 WindowsBase 的两个文件 ⇒ 编 WindowsBase 就能覆盖；PC/PF 各批的生成物本轮未动（由前期各波编译过）。

**流程升级（已落到我的流程里）**：从本批起，每批交付必须**二选一**写明 **`✅ 已编译（命令 + 0 错 0 警）`** 或 **`❌ 未编译（原因）`**，
并且**先过尺子**（作用域 + 类型-lite）；预测 sha 与 `--prove` 都只证"生成/插入的确定性"，**不证能编过**。

**修正后的交付**
| 件 | sha256 |
|---|---|
| `tools/patch-windowsbase-dpvalue-trace.py`（**已修**） | `a689691ce0b1308f154c842b9873ee0302524838cb7a778edf32e643e064b207` |
| `tools/patch-windowsbase-entry-flatten-trace.py`（未动） | `901a2f92875256f1f5b54e7ecb07e8e319e98fbdf075cd9dd167111aa57c9906` |
| 生成物 `DependencyObject.Linux.cs`（**重放后应当是**） | **`e2118ef2ecdb2e51e897a6b5ab643cbcb88a45098f80f641f2e10d39d667f8ac`** |
| 生成物 `EffectiveValueEntry.Linux.cs` | `c53a2f1a27dc98c430e2a7ee0a9f0e1464207dfa3b97f23b8a72dbd9fcf51c0f`（与上一版相同） |
| 尺子（类型-lite 版） | `9490484733dd147a7254e3f665cefa80d1b5d1136955424bf985c4ded810a49e` |

## 12.8 第 6 批**运行期修正**：实参不惰性 ⇒ 探针关着也求值 ⇒ 静态初始化期 NRE

**崩溃原文（`verify-all.sh` 红，`DISPLAY=:96`，换全新 Xvfb 仍复现）**
```
System.TypeInitializationException: The type initializer for 'System.Windows.UIElement' threw an exception.
 ---> 'System.Windows.Media.Transform' threw an exception.
 ---> System.NullReferenceException
   at System.Windows.DependencyObject.SetValueCommon(...) in build/WindowsBase.Linux/DependencyObject.Linux.cs:line 1200
   at MatrixTransform.set_Matrix(...) ← Transform..cctor → UIElement..cctor → HwndTarget..ctor → HwndSource.Initialize
```
`：1200` 就是我的 W6a 调用点：`W6BeforeUpdate(..., _effectiveValues[entryIndex.Index])`。
**根因**：**下标访问写在调用点上 ⇒ 探针关着也会求值**；静态初始化期 `_effectiveValues` 还是 null / `entryIndex` 还无效 ⇒ NRE。
我上一批用"上游 `:807` 也有同款下标"给它开的口子**站不住**：上游那处**在受保护的守卫分支里**，我的落点在守卫之外。
⇒ **"缺省零开销"必须包含实参求值**（这是本轮新增的第三条流程要求）。

**修法（按 W6b 的写法统一）**：调用点只传**原件**（`entryIndex` 结构体 + `_effectiveValues` 数组），
helper 内做 `null` + `idx >= 0 && idx < slots.Length` 判断，**越界/空数组一律打印"越界/不可用"，绝不抛**。

**全批自查（"实参必须惰性"）——本轮惰性化的全部位置**

| 文件 | 原实参 | 改成 | 风险 |
|---|---|---|---|
| `DependencyObject.cs` W6a | `_effectiveValues[entryIndex.Index]` | `entryIndex, _effectiveValues` | **就是这次崩的那处** |
| 同上 W6b | `entryIndex.Index` | `entryIndex` | 静态初始化期 `EntryIndex` 可能无效 |
| 同上 W4a | `entryIndex.Index` | `entryIndex` | 同上 |
| `TextEditorTyping.cs` Q2b | `threadLocalStore.PendingInputItems[i]` | `threadLocalStore.PendingInputItems` + `i` | T3 扫出的"唯一残留带下标"（循环中再入会真 NRE） |
| 同上 Q3 | `TextEditor.UiScope` | 只传 `TextEditor`（属性在 helper 内取） | 属性访问 |
| `TextBox.cs` Q7a/Q7b/Q7c | `this.TextContainer` | 只传 `this`（容器在 helper 内取） | 属性访问 |
| `TextBoxBase.cs` Q6b | `undoAction.ToString()` | 传枚举本身（字符串在 helper 内做） | 方法调用 |
| `TextCompositionManager.cs` P3b | `e.StagingItem.Input.Source` | 传 `e`（链在 helper 内取，try/catch 包住） | 属性链 |

**本轮我自己引入、并被自己的编译闸门抓住的一处（如实登记）**：PF 的 `ContainerOf` 里写了未全限定的 `TextBox`
（tracer 类在 `System.Windows.Documents`，`TextBox` 在 `System.Windows.Controls`）
⇒ `TextContainer.Linux.cs(310,13): error CS0246: 未能找到类型或命名空间名"TextBox"`。
**修法**：全限定 `System.Windows.Controls.TextBox` + 走同 namespace 的 `TextEditor._GetTextEditor(tb)` 拿容器。

**尺子新增第三条检查：实参形态（ARGSHAPE）**
> 探针调用实参**只允许**：`this`、普通局部变量、基元/枚举/结构体、字符串字面量、纯强制转换、已白名单的已知成员（`msgdata.msg.*`）。
> **不许**：下标 `x[i]`、属性链 `a.B.C`（≥2 个 `.`）、`new ...`、方法调用。判不了的照旧列出来。

**牙齿（红 → 绿）**
```
红：仓库修前的 TextEditorTyping（/tmp/t1c/b4 那一份，含 :599）
    !! 调用点 22  作用域 0  类型 0  **实参形态 1**
       :599 Q2Item(…) 实参 `threadLocalStore.PendingInputItems[i]` **实参里有下标 `[]`** ⇒ 挪进 helper
红：上一版坏件 DependencyObject（/tmp/t1c/b8，编译失败那一版）
    !! 调用点 17  作用域 0  类型 2  **实参形态 1**
       :1199 W6BeforeUpdate(…) 实参 `_effectiveValues[entryIndex.Index]` **实参里有下标 `[]`** ⇒ 挪进 helper
绿：修好后（仓库全部生成物）
    **调用点 80  作用域 0  类型 0  实参形态 0**（判不了 73 条已逐条列出）
```
（顺带修掉尺子自己两个假阳性：调用点匹配必须用**原始行**（否则字符串字面量被抹掉 ⇒ 首参变空串）；字符串标签里的括号不算方法调用。）

**两条闸门（本轮都自己跑，原文见下）**

① **编译**（私有输出目录，三个工程都过；rc 用 `PIPESTATUS`/直接 `$?` 取，不经管道）
```
dotnet build build/<P>.Linux/<P>.Linux.csproj -m:1 --nologo -v q \
    -p:BaseOutputPath=/tmp/t1c-verify/<P>/bin/ -p:BaseIntermediateOutputPath=/tmp/t1c-verify/<P>/obj/
PRIVATE_RC_WindowsBase=0      0 个警告 / 0 个错误
PRIVATE_RC_PresentationCore=0 0 个警告 / 0 个错误
PRIVATE_RC_PresentationFramework=0  0 个警告 / 0 个错误
```
② **运行时**（`ManagedLayer.Tests`，`DISPLAY=:96`，自起自灭 Xvfb）
```
Xvfb :96 -screen 0 1280x1024x24 &        # PID 自管，跑完按 PID kill
DISPLAY=:96 dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj -m:1 --nologo
已通过! - 失败:     0，通过:    58，已跳过:     0，总计:    58，持续时间: 33 s
TEST_RC=0        XVFB_KILLED=<自己的 PID>
```

**流程要求（第三条，与"预测 sha ≠ 能编过""`--prove` ≠ 能编过"并列）**
> **"关掉 ≠ 无副作用"**：探针**关着**时，调用点的**实参照样求值**。
> ⇒ 实参必须是惰性形态（裸原件），任何下标/属性链/分配/方法调用都要挪进 helper，并在 helper 内 try/catch。

**本轮改动的 sha（应用器 + 生成物）**
```
44c15aa0f74bf083dfe1f0400bde82ea7cc7f5b736b9f7ec69c01be87e3efe4a  patch-windowsbase-dpvalue-trace.py
91828203bf0e8f37236c3e1b739d17337fb8a240d23e8599ad1223b7530531e7  patch-presentationframework-texteditor-trace.py
fd773c66595f4cf23795923be71e3d2cbce37c8144319715501b9d3e47a1841c  patch-presentationframework-textbox-textdp-trace.py
d54e3ccc95fdb640bfaaa0428afb088311a5c8ebeeef1d296b0cffc9f9aad8cc  patch-presentationcore-inputtrace.py（B2RawBranch helper）
f1a8f73ff9a4e1f807a0d0d58a2ade21641b931706689bb4a5a442a0750b1a9e  patch-presentationcore-registry.py（P3b 调用点）
35b68f03d8a54f7180371c1a1d42086454efdfd224550e1ea4ea66a1ae95aa6f  tools/t1c-trace-args-scope.py（+ARGSHAPE）
d6b0838db0333b033b019f0c53fd892dd05788070112e0d7ec515e02d8e265c2  build/WindowsBase.Linux/DependencyObject.Linux.cs
1b79167c602df471e42ced51d345dd37c2ba37a8c4d46a8d56a726297ebefedf  build/PresentationFramework.Linux/TextEditorTyping.Linux.cs
c4212dad47cc903fa71f8ab5daa8390bc5c64cf3516cf2b831edfb162d72a9f9  build/PresentationFramework.Linux/TextContainer.Linux.cs
2c2e306e6025932a0245def3a0f047a29772b8d9ae2a39b1012ae194c84d8e89  build/PresentationFramework.Linux/TextBox.Linux.cs
900390c6c2baa7a1df3cc3e44891c979990287e1adb834c256d03fe23e580a1c  build/PresentationFramework.Linux/TextBoxBase.Linux.cs
0120b25993fedf736dd403486d694a67f1cb5b2cbcedb891e6dd32f180ade0dc  build/PresentationCore.Linux/HwndSource.Linux.cs
8c94b39877a62b52c5a8fad0e6c90058398baa2215106d88f42de12223f6e9c2  build/PresentationCore.Linux/TextCompositionManager.Linux.cs
c53a2f1a27dc98c430e2a7ee0a9f0e1464207dfa3b97f23b8a72dbd9fcf51c0f  build/WindowsBase.Linux/EffectiveValueEntry.Linux.cs（未变）
```

## 12.9 L12 修正：**额度触顶必须看得见** + W7 独立额度 + W7 收窄到 Text

**阻塞证据（T3 实测）**：WB 一趟 `W* = 199/200`，其中 **W7=144**、W5=40、W6a/W6b/W4a 各 4、W1/W2/W3a 各 1
⇒ 输入时刻的读数（含 deferred 写、`OwnerType=TextBox` 的读侧）**全被静默丢弃**；而 PF 侧（另一套预算）正常。
（第 5 批结论不受影响：那趟 `W*=176` 未触顶，含 deferred 写 `W4a`×2、读侧 `W2`×52 ⇒ A 格仍成立。）

**W7 过滤到底有没有生效（读码判定 + 依据）**：**生效，但"太宽 + 共用额度"才是真问题。**

| 依据 | 位置 |
|---|---|
| `IsDeferredReference = value is DeferredReference;`（结构体构造/赋值处） | `EffectiveValueEntry.cs:56`、`:246-247`（赋值 + `Debug.Assert`）、`:257`（属性） |
| `DeferredReference` 的子类不止"文本"这一族 | `DeferredResourceReference`（PF `SystemResources.cs:1700`，**资源/样式/模板**）、`DeferredRunTextReference`、`DeferredSelectedIndexReference`、`DeferredTextReference`（PF `Controls/*.cs`）、`DeferredMutableDefaultReference`（WB `DeferredReference.cs:43`） |

⇒ **任何"值来自资源/样式/模板查找"的 DP** 在启动期都会让 `IsDeferredReference == true` ⇒ 144 行是**预期行为**，
**不是过滤没生效**。真问题是：辅助格 W7 与主格 W5/W6 抢同一个 200 行额度，而且**触顶是静默的**。

**三条修法（都做了）**
1. **总上限 200 → 2000**；**触顶时打一行**（`NoticeBudget`，只打一次）：
   `**预算用尽**（MaxLines=2000，已打 2000 行）⇒ 之后不再打印；**「没打」≠「没发生」**：请调大额度或缩小过滤范围`。
2. **W7 独立小额度 16 行** + 自己的触顶通知（`W7 **已达独立额度 16 行** ⇒ 之后不再打 W7（其余 W 格不受影响…）`）
   ⇒ 辅助格再也不可能吃光主格的额度。
3. **W7 再收窄到 Text**（这一条比"限额"更根本）：`GetFlattenedEntry` 没有 `dp` 参数，但条目自带
   `PropertyIndex`，而上游构造里就是 `_propertyIndex = (short) dp.GlobalIndex`（`EffectiveValueEntry.cs:29/35`）
   ⇒ 我在 `IsTextDp` 里顺手记下 **TextProperty 的 GlobalIndex**，W7 只在
   `e.PropertyIndex == s_textPropIndex || requests 带 DeferredReferences/RawEntry` 时打印。
   ⇒ 启动期的 `DeferredResourceReference` 从此不再占用 W7 任何一行（判据：正常一趟里 W7 只剩"Text 这个 DP"上的少数几条）。

**同一模式推广到全部 5 个 tracer**（PC 第 2/3 批、WB msgflow、PF 第 3 批、PF 第 4 批、WB DPV）：
现在**每一个** tracer 触顶都会打一行。

**⚠️ 这一轮我自己又踩了一个坑，被编译器的 warning 抓住（如实登记）**：第一次加 `NoticeBudget` 时，
我是在原有的 `if (… > MaxLines) return;` **之后**追加了一个块 ⇒ 那个块是**不可达代码**（CS0162），
**通知根本不会打**（"看得见"这个修法本身变成了假的）。三个工程各报 1–2 条
`warning CS0162: 检测到无法访问的代码`（`HwndSource.Linux.cs:99`、`Dispatcher.Linux.cs:191`、
`TextEditorTyping.Linux.cs:120`、`TextContainer.Linux.cs:192`），我据此把那 4 处改写成"条件 + 块"（去掉残留的 `return`），
现在 6 次编译（3 工程 × 私有/仓库）**全部 0 警告 0 错误**。
⇒ 这也是"**闸门要自己跑**"的又一次正收益：**warning 是读数**，不是噪声。

**闸门（本轮最终跑，原文）**
```
PRIVATE_RC_WindowsBase=0       0 个警告 / 0 个错误
PRIVATE_RC_PresentationCore=0  0 个警告 / 0 个错误
PRIVATE_RC_PresentationFramework=0  0 个警告 / 0 个错误
REPO_RC_WindowsBase=0 / REPO_RC_PresentationCore=0 / REPO_RC_PresentationFramework=0   各 0/0
DISPLAY=:96 dotnet test …/ManagedLayer.Tests.csproj -m:1 --nologo
已通过! - 失败: 0，通过: 58，已跳过: 0，总计: 58，持续时间: 39 s     TEST_RC=0     XVFB_KILLED=636018
尺子全量：调用点 80  作用域 0  类型 0  实参形态 0（判不了 73 条已列出）
```

**流程要求（第四条，L12）**：**额度触顶必须看得见** —— 任何"有上限的探针"都要在触顶时打一行
（含"已打 N 行"），否则"没打"与"没发生"长得一模一样；辅助格要有**独立**额度，且优先用**过滤**（能收窄就别靠限额）。

**本轮最终 sha**
```
97b223152d1879ce750b7b5c7a64710cda8d320670a4627e88f60580fdfc9c47  patch-windowsbase-dpvalue-trace.py
19a2e6cafba38627a43c62fa39f002f03f095c39089cbeea2110ef144c2951f7  patch-presentationcore-inputtrace.py
c6cbd41cb29153fc6b9f02f8c9785c7fb23ed79876646f82132048ef35d8d342  patch-windowsbase-msgflow.py
f8dbac9ac4c5a5ea0048765875c7c2bb9bc0f1b87501efaf5ea148a9f7a3ddaf  patch-presentationframework-texteditor-trace.py
f4dbda6db716ee88997d0d81dab5a89cc5f552272f522b07ab1d984092ed0f87  patch-presentationframework-textbox-textdp-trace.py
c5106590d79402db7cace3eabbb183e36ed3388bcfad9ce30d6e2b1fa10e6f86  build/WindowsBase.Linux/DependencyObject.Linux.cs
ec8259ed4c14fd3a6e773cb02b317049cb1aaf0fb9f62e88cbdb3bc44cef7baa  build/WindowsBase.Linux/Dispatcher.Linux.cs
4b88cb1be27d41b54fe1f7b24b01099936d9808744899c9116c5a1d5f3d8adbb  build/PresentationCore.Linux/HwndSource.Linux.cs
bb4f98dc236d5e25facce6c64912f22337a4448329bcc7e08f811c0f1d972ff0  build/PresentationFramework.Linux/TextEditorTyping.Linux.cs
a01d9367c37b16e3b7db26a9a632c6f749782a22d6b70f4c1f987cccbdac1c58  build/PresentationFramework.Linux/TextContainer.Linux.cs
（未变：EffectiveValueEntry c53a2f1a…｜HwndKeyboardInputProvider f56e647e…｜TextBox 2c2e306e…｜TextBoxBase 900390c6…｜DeferredTextReference 1f144da7…）
```

## 12.10 第 7 批：**读侧把索引打出来** + `LookupEntry`/`CheckEntryIndex` 重查行为 + `EntryIndex` 编码判定

**第 6 批四格判死为 `d`**（写把 deferred 存进 `entryIndex=27`、读侧拿到的是槽 1 的旧内容）。
本批把"读侧到底用了哪个索引"变成**直接读数**，并把索引机制查清。

### 12.10.1 新增读数（`DependencyObject.Linux.cs` 行号）
| 点 | 行 | 打什么 |
|---|---|---|
| **W1** `GetValue` 入口 | `:664` | `dp.GlobalIndex/OwnerType` + **读侧 `LookupEntry` 得到的 `Index/Found`**（**惰性**：`LookupEntry` 在 helper 内调，调用点只传 `this/dp`，且 try/catch） |
| **W2** `GetEffectiveValue` 入口 | `:812` | **读路径实际传入的 `entryIndex`（Index/Found）** + 原有的 `effectiveEntry.IsDeferredReference` / `entry.Value` |
| **W3a** A 格提前返回 | `:817` | A 格那条上**直接带 `entryIndex`** |
| **W8/W8'** `LookupEntry` | `:3601 / :3607 / :3618 / :3638 / :3652` | 入口（含 `EffectiveValuesCount`）+ **四条出口**（`iHi<=0` / 二分命中 / 线性命中 / **未找到⇒插入位**）——索引**怎么算出来的** |
| **W9/W9'** `CheckEntryIndex` | `:3580 / :3586` | 入口（传入索引 + `targetIndex`）+ **出口[沿用旧索引]**；"重新查找"那一支由**紧随的 W8 读数**体现（故意不插，避免在实参里放 `LookupEntry(...)`） |

`W8/W9` 只对 `targetIndex == TextProperty 的 GlobalIndex` 打（`IsTextDp` 记下的那个），否则静默 ⇒ 有界。

### 12.10.2 `EntryIndex` 编码：**逐字依据**（回答了"W5 为什么打 `-1`"）
`WindowsBase/System/Windows/EntryIndex.cs` 逐字（`:17-45`）：
```csharp
internal struct EntryIndex
{
    public EntryIndex(uint index)          { _store = index | 0x80000000; }           // Found = true
    public EntryIndex(uint index, bool found)
    { _store = index & 0x7FFFFFFF; if (found) { _store |= 0x80000000; } }
    public bool Found { get { return (_store & 0x80000000) != 0; } }
    public uint Index { get { return _store & 0x7FFFFFFF; } }
    private uint _store;
}
```
- **`_store` 是打包的 `uint`**：**bit31 = `Found`**，**bit0-30 = `Index`**；`Index` 取值时掩掉 bit31
  ⇒ **`Index` 永远不可能是 `-1`**，也**没有**"local/effective"之类的标志位 —— 唯一的位就是 `Found`。
- `LookupEntry` 的注释也逐字写明了 `Found=false` 时 `Index` 的语义（`:3062-3065`）：
  > `return value has Index set to the index of the found entry (if Found is true) or the location to insert an entry for this dp (if Found is false)`

⚠️ **因此：`W5` 那行里的 `entryIndex=-1` 是"我自己造的假读数"** —— `W5` 的八个写入口**在调用点压根没有 `entryIndex`**，
我在 `Tgt(target, dp, -1)` 里传了 **`-1` 哨兵**，helper 又把它当数字打出来 ⇒ 看起来像"实测索引是 -1"。
**已修**：现在打 `entryIndex=(该点没有索引)`（`-1` 不再冒充运行时值）。这是**G 类假读数**（"把非读数打成读数"），登记在案。

### 12.10.3 "谁缓存了陈旧索引" —— 机制与逐字依据
1. **上游自己文档化了这个风险**（`DependencyObject.cs:3020-3026`，`CheckEntryIndex` 上方逐字）：
   > `//  This method`
   > `//  1. Is used to check if the given entryIndex needs any change. It`
   > `//  could happen that we have made a call out and thereby caused changes`
   > `//  to the _effectiveValues store on the current element. In that case`
   > `//  we would need to aquire new value for the index.`
2. **`CheckEntryIndex` 就是那道校验门**（`:3027-3040`）：若 `_effectiveValues[entryIndex.Index].PropertyIndex == targetIndex` ⇒ **沿用旧索引**；
   否则 `return LookupEntry(targetIndex);` ⇒ **重查**。两条出口现在都有读数（W9'/W8）。
3. **索引为什么会失效**：`InsertEntry`（`:3102`）在插入位插入 ⇒ 其后**所有条目整体后移**；
   数组**增长**（`:3120-3132`）与**压缩**（`:2854` 的 80% 阈值 → `:2861 _effectiveValues = destEntries`）同样搬动条目
   ⇒ **任何跨调用持有的 `EntryIndex` 都可能指向另一个 DP 的槽**（"槽还在、但主人换了"）。
4. **缓存点排查结论**：`DependencyObject` 里**没有** `EntryIndex` 字段（grep 只命中方法签名）⇒ 索引**只活在局部变量**里，
   跨调用传递处**必须**过 `CheckEntryIndex`；所以本批用 W9（沿用/重查）+ W8（怎么算出来的）把这条链钉住。

### 12.10.4 判据（本轮读数一回来即可判死）
| 观察 | 结论 |
|---|---|
| **读侧 `entryIndex`（W2 行）= 1，而写侧（W6b 行）= 27** | **读路径用了陈旧索引** ⇒ 追 12.10.3 的 2/3：谁在什么时候取的 1、有没有过 `CheckEntryIndex`（W9 行会显示"沿用"而不是"重查"） |
| **读侧 `entryIndex` = 27** | 索引没问题 ⇒ 是"槽 27 的 flatten/取值"问题（`GetFlattenedEntry` + `ModifiedValue`，回到 W7） |
| **W1 的 `LookupEntry` 结果 ≠ W2 传入的 `entryIndex`** | 读路径上**先查后传之间**发生了结构变化（数组增长/压缩/插入）⇒ 中间那次"call out"就是元凶 |
| **两条都打不出来** | 先解决探针（本轮已保证 W1/W2/W3a 都在早退门之前、且实参惰性） |

### 12.10.5 闸门（本轮最终件）
```
PRIVATE_RC_WindowsBase=0 / PRIVATE_RC_PresentationCore=0 / PRIVATE_RC_PresentationFramework=0   各 0 警告 0 错误
REPO_RC_WindowsBase=0 / REPO_RC_PresentationCore=0 / REPO_RC_PresentationFramework=0            各 0 警告 0 错误
DISPLAY=:96 dotnet test …/ManagedLayer.Tests.csproj -m:1 --nologo
已通过! - 失败: 0，通过: 58，已跳过: 0，总计: 58，持续时间: 49 s      TEST_RC=0     XVFB_KILLED=681548
尺子：调用点 87  作用域 0  类型 0  实参形态 0（判不了 80 条已逐条列出）
```
**本轮抓到的我自己的两处缺陷（登记）**：
① 中途一次脚本因为嵌套引号在断言处失败 ⇒ **helper 签名与 EDITS 只改了一半**（调用点传 5 个实参、helper 收 4 个）——
   被**我自己的尺子**（类型/实参个数）当场报出 6 条 `实参个数多于形参` / `引用类型不同`，**没走到编译器**；
② `-1` 哨兵冒充运行时读数（12.10.2）。两处都改了，改完才跑闸门。

**最终 sha**
```
2b5cee682ca16d183b4af6382d5ad3dc3ed74adbf59996a29acc9b871691330e  tools/patch-windowsbase-dpvalue-trace.py
4bf6dde4ed97289717951e7f6ed3cdc5bc0b30bc548707edd1f19f5a753f47ae  build/WindowsBase.Linux/DependencyObject.Linux.cs（**第 7 批预测值**）
c53a2f1a27dc98c430e2a7ee0a9f0e1464207dfa3b97f23b8a72dbd9fcf51c0f  build/WindowsBase.Linux/EffectiveValueEntry.Linux.cs（未变）
```

## 12.11 第 8 批：**原始槽 vs ModifiedValue vs 算出的 effectiveEntry**（并排）+ flatten 取值归属

**第 7 批结论**：索引假设**被排除**（`W1` 读侧 `LookupEntry → Index=27 Found=True`，`W2` 传入同为 27，52 次读里 35×27、3×24，
返回内容**全部**是 `effectiveEntry.Value=string(7) "seed-文本"`、`IsDeferredReference=False`、`HasModifiers=False`/`HasExpressionMarker=False`，
"读到过新文本"= **0 次**）。合起来 ⇒ 写入后槽 27 = `ModifiedValue`/`IsDeferredReference=True`（W6b），
而**读侧从槽 27 算出的 effectiveEntry 却是"非 deferred 的旧串"** ⇒ 断点在 **槽内容 → effectiveEntry（flatten）**这一步。

**主控的重点怀疑（本批直接验它）**：`SetCurrentDeferredValue` 走 `SetValueCommon(..., coerceWithCurrentValue: true, ...)`（`DependencyObject.cs:524-531`）
⇒ deferred 引用可能存进 `ModifiedValue` 的 **coerced/current** 槽、**基值仍是旧串**；而 `GetFlattenedEntry` 的"有修饰"那一支要负责把它取出来。

### 12.11.1 新增读数
| 点 | 位置 | 打什么 |
|---|---|---|
| **W2'** 原始槽 | `DependencyObject.Linux.cs`（W2 helper 内，**零新增实参**） | **`entry`（= 调用点的 `_effectiveValues[entryIndex.Index]`，上游 `:300` 逐字）** 的派生标志：`IsDeferredReference / IsCoerced / IsAnimated / IsExpression / IsCoercedWithCurrentValue`（`_source` 是 **private 且无访问器** ⇒ 打它的派生标志，报告里明说这处缺口） |
| **W2'** `ModifiedValue` | 同上 | 若 `HasModifiers`：**`BaseValue` / `CoercedValue` / `ExpressionValue` / `AnimatedValue` 四个字段各自的运行时类型**（只要有一个是 `DeferredTextReference` ⇒ 方向立刻定） |
| **W2''** 算出的 effectiveEntry | 同上 | `effectiveEntry.Value` 类型 + `IsDeferredReference`（**与上面两行并排** ⇒ 一眼看出标记是在槽里就没有、还是 flatten 之后丢的） |
| **W10** flatten **取值点** ×9 | `EffectiveValueEntry.Linux.cs:387/396/401/406/411/420/429/…` | `GetFlattenedEntry` 里**每一个 `entry.Value = …` 赋值点之后**各一行：`取值[CoercedValue/AnimatedValue/ExpressionValue/**BaseValue**/expressionValue]` + 采用值的类型 + entry 标志 + `ModifiedValue` 四字段 |
| **W8** 调用序号/时刻 | `DependencyObject.Linux.cs` | `W8` 行现在带 **`#seq (+Xms)`** ⇒ 判那 3 次 `Index=24` 是否出现在"输入之后" |

### 12.11.2 判据（互斥，读数回来即可落格）
| 格 | 观察 | 结论 |
|---|---|---|
| **①** | W10 打出 **`取值[**BaseValue**（Coerced 分支的兜底）]`**，而 W2' 的 `ModifiedValue.CoercedValue` 是 `DeferredTextReference` | **flatten 取值选择错/该分支没覆盖 `IsCoercedWithCurrentValue`** ⇒ 根因，且能指到 `EffectiveValueEntry.cs` 的具体行 |
| **②** | W2' 的 `ModifiedValue` 三字段**都不是** deferred | **写侧没把它放进 modifier** ⇒ 回看 `SetValueCommon` 的 `coerceWithCurrentValue` 分支 |
| **③** | W7a 打出 **"无修饰 ⇒ return this"** | 槽的 `_source` 认为没有修饰 ⇒ 与 `W6b` 的观感矛盾 ⇒ **`W6b` 的判读口径要修正**（不拿旧结论硬套） |
| **④** | W10 打出 `取值[CoercedValue（IsCoercedWithCurrentValue…）]` 且类型是 deferred，而 W2'' 仍非 deferred | flatten 取对了值但**构造 flattened entry 时没带 mark** ⇒ 查 `:345-355` 的 `IsDeferredReference = …` 赋值 |

### 12.11.3 闸门（本轮最终件）
```
PRIVATE_RC_WindowsBase=0 / PRIVATE_RC_PresentationCore=0 / PRIVATE_RC_PresentationFramework=0   各 0 警告 0 错误
REPO_RC_WindowsBase=0    / REPO_RC_PresentationCore=0    / REPO_RC_PresentationFramework=0      各 0 警告 0 错误
DISPLAY=:96 dotnet test …/ManagedLayer.Tests.csproj -m:1 --nologo
已通过! - 失败: 0，通过: 58，已跳过: 0，总计: 58，持续时间: 47 s     TEST_RC=0     XVFB_KILLED=753521
尺子：调用点 96  作用域 0  类型 0  实参形态 0（判不了 89 条已列出）
```
⚠️ **权威产物已被我的闸门构建改动，需主控整波重建**（`ManagedLayer.Tests` 加载仓库 `bin/`，这一步必须编仓库）。
我编完之后的仓库三个产物 sha（供你重放后核对）：
```
b5fc5ba10dc0bbd8fb1a232fa20f484e1efe7559f45f9b1b0ea0966c5f8a9ab0  build/PresentationCore.Linux/bin/Debug/PresentationCore.dll   (20:16:53)
8c073fab0da8816987a7cbae68d2b79328667d9592ac582a7bae913890a9f80a  build/WindowsBase.Linux/bin/Debug/WindowsBase.dll            (20:13:57)
b580c9234dde04d8e1c7e20cdec32bf22dc231da7d5a820da1ed63fef6d472c0  build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll (20:21:15)
```

**最终 sha**
```
6a32c4d82eef845720c8bdbce7d5c5b5cb4723b7bc86e39bb5d0c40a4586981e  tools/patch-windowsbase-dpvalue-trace.py
909df7198f6fafef76b42ed314b031e9e3a0b56fc9a010782e0ce4e356f4cceb  tools/patch-windowsbase-entry-flatten-trace.py
0a4a7ba5510a0b55624ea3e23ce7921703b8cfe77fb7f1c54aef2aacd2e57a77  build/WindowsBase.Linux/DependencyObject.Linux.cs（第 8 批预测值）
9854366f0ef5d747714c9666eacc5ad8e810b34aafc45cafe4c60be2cb0c570a  build/WindowsBase.Linux/EffectiveValueEntry.Linux.cs（第 8 批预测值）
```

# 第 9 批（M1…M6）：RTL 镜像 —— **实际推给视觉树的变换** vs `GetFlowDirectionTransform()` 的报告口径

> 只写 applier + 报告（**不重放、不跑应用**）。过滤：**先按类型名**命中 `TextBlock`（不读 DP），**再**读 `FlowDirection` 要求 `RightToLeft`；
> 有界 ≤200 行 + 触顶通知（L12）；实参全部惰性（ARGSHAPE）。

## 13.1 读码定位：**主控原先"`ApplyMirrorTransform` 有 offsetX"的假设要修正**
`ApplyMirrorTransform` 的签名是 **`internal static bool ApplyMirrorTransform(FlowDirection parentFD, FlowDirection thisFD)`**（`FrameworkElement.cs:4030`）——
**它只做方向判定，参数里没有 offsetX**。offsetX 出现在**另一处**：`GetFlowDirectionTransform()`（`:3940-3948`）里造的
`new MatrixTransform(-1, 0, 0, 1, **RenderSize.Width**, 0)`。
**真正"推给视觉树"的那条路**是（逐字 file:line）：
```
:3940 GetFlowDirectionTransform()                     ← 造镜像（OffsetX = RenderSize.Width）
:3950 ShouldApplyMirrorTransform(fe)                  ← 找 parent 的 FlowDirection（视觉父优先）
:4030 ApplyMirrorTransform(parentFD, thisFD)          ← 纯方向判定
:5171 SetLayoutOffset(offset, oldRenderSize)          ← **视觉变换的真正组装点**（:5197 additionalTransform = GetFlowDirectionTransform()）
                                                        方法上方注释逐字列了 VisualTransform 的依赖：Mirror / RenderSize.Width / FlowDirection / parent.FlowDirection
:5130 InternalSetLayoutTransform(element, transform)  ← :5135 additionalTransform = fe?.GetFlowDirectionTransform()（把变换推给元素）
:4862/4925 GetLayoutClip(...) 里的 rtlMirror          ← 裁剪路径
TextBlock.cs:1475 TextBlock.OnRender                  ← 宿主侧
```
⇒ 本批就把上面六条路都打上，**并排**比较"实推变换的 OffsetX"与"报告口径的 OffsetX"。

## 13.2 逐点（生成物:行）
| 点 | 生成物:行 | 打什么 |
|---|---|---|
| **M1** `GetFlowDirectionTransform` 入口 | `FrameworkElement.Linux.cs:4156` | 元素身份 + `FlowDirection` + `RenderSize`（**ActualWidth 不读**，避免多读一个 DP） |
| **M1'** 推了镜像 | `:4161` | **`M11/M22/OffsetX/OffsetY`** + 当时 `RenderSize.Width` ⇒ **报告口径的 OffsetX** |
| **M1''** 没推镜像 | `:4166` | `return null` 那一支 |
| **M2** `SetLayoutOffset` 组装点 | `:5427` | **传入 `offset`、`oldRenderSize`、`additionalTransform` 三者并排** + 元素状态 ⇒ **本任务的核心格** |
| **M3** `InternalSetLayoutTransform` | `:5363` | 推给视觉树那条路上的 `additionalTransform` |
| **M4** `GetLayoutClip` 的 `rtlMirror` | `:5151` | 裁剪路径用的镜像 |
| **M5** `ApplyMirrorTransform` 方向判定 | `:4253` | `parentFD/thisFD ⇒ 结果`（**纯插入**：probe 在 `return` 之前，`return` 逐字未动） |
| **M6** `TextBlock.OnRender` 入口 | `TextBlock.Linux.cs:1489` | **宿主侧**读数（`FlowDirection`/`RenderSize`） |

## 13.3 「重放后怎么读」——**能直接判"渲染变换与报告口径不同"的那个读数**
1. **把 M1' 的 `OffsetX` 与 M2 的 `offset`/`oldRenderSize` 并排看**：
   - **M2 的 `offset.X` == M1' 的 `OffsetX` == 当时 `RenderSize.Width`** ⇒ 实推变换与报告口径**一致** ⇒ 差异在别处（继续看 M3/M4 与后续 TransformGroup 组合）；
   - **M2 的 `offset.X` ≠ M1' 的 `OffsetX`** ⇒ **实推的镜像中心与报告口径不同**（本任务要钉的那一格）⇒ 由 M2 那一行的 `offset`/`oldRenderSize` 直接指出差多少；
   - **M1'' 打了（没推镜像）而墨迹仍然镜像** ⇒ 镜像**根本不在 FrameworkElement 这条路上**（那时按 M3/M4 是否命中判断是谁推的）。
2. **M3 与 M2 的 `additionalTransform` 是否同值**：不同 ⇒ 两条路用了**不同时刻**的 `RenderSize.Width`（布局前后尺寸变过）；
3. **M4 的裁剪镜像与 M2 的镜像是否同值**：不同 ⇒ 裁剪框与墨迹框按不同镜像算 ⇒ **"墨迹落在自己视觉框之外"**就是这里；
4. **M6 的 `RenderSize` 与 M1'/M2 时刻的 `RenderSize` 是否同值**：不同 ⇒ 渲染发生在尺寸变化之后 ⇒ 与 2/3 合起来就能指到具体那一次。

## 13.4 闸门（本轮最终件）
```
PRIVATE_RC_WindowsBase=0 / PRIVATE_RC_PresentationCore=0 / PRIVATE_RC_PresentationFramework=0   各 0 警告 0 错误
REPO_RC_WindowsBase=0    / REPO_RC_PresentationCore=0    / REPO_RC_PresentationFramework=0      各 0 警告 0 错误
DISPLAY=:96 dotnet test …/ManagedLayer.Tests.csproj -m:1 --nologo
已通过! - 失败: 0，通过: 58，已跳过: 0，总计: 58，持续时间: 38 s     TEST_RC=0     XVFB_KILLED=826934
尺子：调用点 103  作用域 0  类型 0  实参形态 0（判不了 97 条已列出）
```
⚠️ **权威产物已被我的闸门构建改动，需主控整波重建**（`ManagedLayer.Tests` 加载仓库 `bin/`）。我编完之后：
```
c43d351639856680f934ebb0f2657e76f97db1a089d0ddcf2ec3333b0f9337c8  build/PresentationCore.Linux/bin/Debug/PresentationCore.dll        (21:02:36)
8c073fab0da8816987a7cbae68d2b79328667d9592ac582a7bae913890a9f80a  build/WindowsBase.Linux/bin/Debug/WindowsBase.dll                 (20:32:59)
d9c875ce8095ba18c88e54790d69e4149f474f989a7642edd6b81c6133060ab0  build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll (21:05:14)
```

**最终 sha**
```
a4e6599a8f0a9e754487cd50adebe8177e6eea5b519058fa8a269db589f980c4  tools/patch-presentationframework-mirror-trace.py
61a5f1e45e6017fbe50dc3717d84faab3222023677c0946278e6fd13661c66ea  build/PresentationFramework.Linux/FrameworkElement.Linux.cs（第 9 批预测值）
6067276d0fc3a8da10ca7b0623431d0e51944ff89facf4df369f696ee41826f5  build/PresentationFramework.Linux/TextBlock.Linux.cs（第 9 批预测值）
```

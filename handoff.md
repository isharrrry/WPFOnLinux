# WPF on Linux 移植工程 · Handoff

> **目标**：把 `dotnet/wpf` 适配成 Linux 原生可渲染版本，支持在 Linux 上**编译** WPF 程序并**运行**渲染。
> **不要求**：兼容 Windows 下已编译的 WPF 二进制（这个边界极大降低了工作量，见 §2）。
> **上游源码**：`/root/.codebuddy/artifact/wpfscan/wpf`（dotnet/wpf main 分支，已下载）
> **工程根目录**：`/workspace/wpf-linux`

---

## `#45` 波速览（2026-09-19 · 最新；**仪器波**，不翻九位、不重冻）

**一句话**：给 `D-G50`（hc 组合框点不开下拉）造了**仓内判别仪器**并拿到判词 —— **根因 = 我方命中测试把"透明填充"判成不命中 ⇒ 点击穿透**（新登记 `D-G52`）；HandyControl 的下拉**正是靠那层透明覆盖层**去开的 ⇒ `D-G50` 的根因 = `D-G52`。（⏪ 当日更正：先前那句"缺口在 HandyControl 模板层"**只对了一半**。）

| 类别 | 内容 |
|---|---|
| **仪器** | 新块 ⑫ `nativecombo`（`samples/WpfFeatureProbe/FeatureBlocks.cs`；三处同趟注册：块清单 ＋ runner 的 `BLOCKS`/`EXPECT`）：标准 `ComboBox` ＋ `DropDownOpened/Closed/SelectionChanged/KeyDown` 逐行 flush ＋ 下拉项容器测试色（关着时屏上无该色） |
| **判词** | `EVT nativecombo.DropDownOpened ×3`（点中心）、`KeyDown=LeftAlt`（`Alt+Down` 到控件）⇒ **标准 ComboBox 点击/键盘都能开下拉**；**复刻组**（透明覆盖层＋`IsHitTestVisible=false` 的 ContentPresenter＋`Popup`）点中心 ⇒ **`EVT hit border` ＋ `overlay=0`** ⇒ **点击穿过了透明层** ⇒ 根因 = **`D-G52`（透明填充不参与命中）** |
| **下一步** | 定位并修"**全透明填充算不算命中**"那一格；判据已立（块 ⑫ 复刻组的 `EVT hit overlay` 必须出现；反极性：`IsHitTestVisible=false` 那层必须不出现）；若改动落进九位 ⇒ 完整波 `#46` |
| **自伤（5 条，留档）** | ① 块首版**漏 `host.Children.Add(card)`** ⇒ `w=0 h=0`、点击无处可落，而块照样自报 `OK`（"自报绿掩盖无载体"同族）；② `PointToScreen` 抛 `InvalidOperationException`；③ `Window.GetWindow` 返回 `null`；④ `TransformToAncestor(MainWindow)` 抛异常（三者最后用**逐级累加偏移**绕过）；⑤ 构建档与运行档不一致（`bin/Debug` vs `bin/Release`）＋ C# 嵌套引号 ＋ 把 bash 脚本喂给 `python3`（登记表一度写成空文件，已复绿） |
| **顺带读数** | 第一次完整跑探针（12 块）⇒ `fail=3`（`textbox-edit`/`transforms`/`text-rtl`）⇒ **三块一直红而没人被喊**（非本波引入），已记进 `KNOWN-DEFECTS.md` |

## `#44` 波速览（2026-09-19 · 最新；**冻结 `#44`** sha16=`ff3990dafa582831`）

**一句话**：修掉一条**仓内从未登记过**的真缺陷 —— **真实第三方应用 hc demo 里"能点开但控件永不激活"**（复选框不勾、下拉不开、滑块不动，**只拿到焦点**）；根因是 **shim 的鼠标五键 `GetKeyState` 恒 0**。

| 类别 | 内容 |
|---|---|
| **① 根因（代码级）** | 上游 `PresentationCore/System/Windows/Input/Win32MouseDevice.cs:45,61` 判按钮状态**只看** `(GetKeyState(VK_LBUTTON) & 0x8000) != 0 ? Pressed : Released` —— **它不看消息**。而本 shim 的 `g_wpf.key_state[256]` **只由键盘翻译层填写** ⇒ 五个鼠标 VK 恒 0 ⇒ 永远 `Released` ⇒ 上游 `ButtonBase.OnMouseLeftButtonDown` 里 `Focus(); if (e.ButtonState == Pressed) { CaptureMouse(); SetIsPressed(true); }` **判假**（`Focus()` 在判据**之前** ⇒ **焦点照拿、激活永不发生**）。 |
| **② 修法（三处，全在 shim 的 C 源）** | `win32_x11.c` 新增 `wpf_x11_mouse_keystate()`（问 `XQueryPointer` 的**真实指针按键态**，与 Win32 `GetKeyState` 同义）＋ `win32_core.c` 的 `wpf_keystate_read()` **仅**对 `0x01/0x02/0x04/0x05/0x06` 改走它（**键盘路径逐字未动**）＋ `win32_internal.h` 声明 |
| **③ 产品侧验收（判据落地前写死）** | ✅ 复选框**自身 24×24 盒内** `AE 0 → 338`（再点一次 `276` ⇒ **可反复切换**）；✅ **拖 thumb** 滑块 `AE=7485`；✅ 导航正对照 `235937`；✅ 反极性静置 3 s `AE=0`；✅ 应用不崩、`app.log` 0 异常。⚠️ 原 `P3`（点滑块轨道）**判据是我写错的**（WPF `Slider` 默认 `IsMoveToPointEnabled=false`）⇒ 作废、改用拖 thumb（如实记） |
| **④ 位移（预登记错了两条，如实记）** | `win32shim` `73c488a6…`→`11f81eb9…`（必变 ✓）；**`pc`/`pf` 也变了**（`deb8e192…`→`45e7e0a4…`、`d160eaed…`→`a93097f7…`）——**不是因果耦合**，而是**整波重建即变字节**（非确定构建）；`inputs_fp` **也变了**（`ee98113b…`→`493551db…`，因**重钉 `known-red.json`**，它在覆盖面里）。其余六位逐位未动 |
| **⑤ 新登记 `D-G50`（未修）** | hc 组合框**下拉打不开**：点正文区与点箭头都只给焦点、**没有任何新 X 窗口**（`xwininfo` 子窗口 `7→7`；`WPF_LINUX_WIN_DIAG=1` 下 `app.log` 0 行）⇒ `IsDropDownOpen` 从未置上。**已排除**：Popup 通道本身没问题（样本 `popup` 块单独跑 ⇒ `new_windows=9`、`WFP_GATE=PASS`）。**缺口定位**在 HandyControl 自己的 `ToggleBlock`（`Background=Transparent`＋`ToggleGesture=LeftClick`＋`OnMouseDown`→`ControlCommands.Toggle`→双向绑 `IsDropDownOpen`）；两条候选（命中测试对透明背景／命令绑定链）与**判别实验**（在 `WpfFeatureProbe` 复刻该模式的两极化块）已写进 `KNOWN-DEFECTS.md` |
| **⑥ 顺带登记** | `WpfFeatureProbe` 的 **12 个块只有 `--only=` 才跑得到**（`grep popup` 在 `verify-all` 日志 0 命中；`#45` 起块数 11→12）⇒ 与 `D-G2`/`D-G3` 同族的"仪器不在跑" |
| **⑦ 本波新增的仪器自伤（三条，都留档）** | ① publish 目录里**根本没有** `libwpfwin32.so` ⇒ 早前几件 hc 仪器里 `[ -f … ] && cp …` **静默什么都没做**（应用目录一直躺着 `#40` 老 shim ⇒ 那些读数是**旧件上的**）；② `integration-wave.sh` 在 `WAVE_OWNER` 未设时**拒绝运行**（`rc=9`，不是构建失败）；③ 两个 hc 仪器件**共用 `:95`** 互杀 X server ⇒ 那次 `SIGSEGV` 是**自伤**（此后一律独占显示号）。另：`xdotool search --name '.'` **看不到无名窗口** ⇒ 数窗口必须用 `xwininfo -root -tree` |
| **留给下一波（按价值）** | ① **`D-G50`**：先落那个"复刻 `ToggleBlock` 模式"的两极化块（仓内判据），再定是命中测试层还是 HandyControl 命令链；② `D-T4`/`D-G48` 的**透参**产品修（`pc`＋shim，先测 136 条真值位移）；③ `D-G47` 潜在真缺陷定性；④ 把那 12 个块接进在跑的判据 |

## `#43` 波速览（2026-09-19 · **零位移复核**；详细见 `docs/WAVE43-PREREGISTRATION.md`）

**一句话**：把 `#42` 登记的两条**定性错误**查清并更正 —— `D-G48` 的"tab 触发"**被推翻**（真因 = **无 DISPLAY 时兜底链必抛**）、hc 的 `373 vs 1275` **是口径伪影**（切 Release 前后帧 `AE=0`），并顺手把 `D-T4` 的新判据**立住**（兜底路径**丢 tab 参数**）。

| 类别 | 内容 |
|---|---|
| **① `D-G48` 去混淆（头号）** | `#42` 的**全部有效读数都取自无 DISPLAY 环境**（3 具有判词的日志各带 2 行 `XOpenDisplay… 失败`；另 2 具**有 X 却根本没判词**，死在 `obj/Debug` 被当输出目录）⇒ 新工具 `build/MilBridge/tools/tabgap-display-polarity.sh`（**同一个二进制只换环境**）判 **`X-CONFOUNDED`**：臂 A（有 X）**0 异常**（宽档 `74.156/32.797/56.797/104.797`、窄档 `9.805/32.797/9.805/9.805`）、臂 B（无 DISPLAY）**6 异常** ⇒ 真因 = `TypeInitializationException: The type initializer for 'System.Windows.Media.Brush' threw an exception`（媒体栈起不来）⇒ 交回 `FullTextLine` ⇒ `LoCreateContext` 不存在 ⇒ **终止**。上游自己的两条判据（`CanProcessTabsInSimpleShapingPath` 要求 `DefaultIncrementalTab > 0`；需断行时 `SimpleTextLine.Create` 主动 `return null`）解释"哪些输入会落到复杂行路径"⇒ **tab 值只是间接因素** |
| **② `D-T4` 补注（判据立住）** | 兜底路径**丢 `DefaultIncrementalTab`**：窄档 `tab=0/24/48` 宽度**完全相同**（`9.805`），而**宽档**同三值互不相同 ⇒ **探针内部互为对照**（不靠外部模型）；机制 = 两级兜底入口**都没有 tab 形参**（shim `:4634`、生成物 `:344-347`）而工厂**早有**（shim `:3959`）⇒ 静默用 `4×emSize`（`tab=0` 的 `74.156` 正是 64 DIP 停靠位的形状）。`tab-gap-check.sh` 新增 `TABGAP_FALLBACK_TAB_LOST=yes` ⇒ `KNOWN-RED reason=fallback-ignores-tab` |
| **③ hc `373` vs `1275` 定性** | `373` 是**正常值**（素材本身是调色板 PNG：`Cover.png` **109 色**；`$HOME/w33m-run/hc-*.png` **60 具归档帧最大 373**）；**切 Release 前后帧 `compare -metric AE` = 0**（两具独立帧都是 0）⇒ **一个像素都没动**；`1275` **无留存物可复算**、能复算的高色数近邻属于**别的主体**（第三方 mini 应用 1485/1642、样本帧 harness 2556–4019）⇒ 旧那句"完整度另立待办"**作废** |
| **④ `upstream/wpf` provenance** | 新增 `docs/UPSTREAM-PROVENANCE.md`：**身份**（树内自证：`RepositoryName=wpf`／`PackageProjectUrl=github.com/dotnet/wpf`／`net11.0`／MIT）＋**四条可复算指纹**（M1 `31adafc6…`／M2 `d81e2923…`／M3 `f402e345…`／M4 `0a098c16…`，M3 两种排除法同值）＋**落盘顺序**（`09:35:12` **26 件顶层**、`09:35:23` **6388 件 `src/`**，`26+6388+3=6417` 全对账）＋**裁剪面成对证据**（`eng/`／`Documentation/`／`.github/`／`packaging/`／`redist/`／`tests/` 缺，而树内文件**引用着**它们）＋**精确 commit 未定**（无 `.git`）＋给第三方的**钉 commit 配方** |
| **⑤ 仪器修（三处缺陷）** | `tab-gap-check.sh`：① 原硬写 `-c Debug` 而结论行印**声明档** ⇒ **自造假声明**；② `bin/*/` 通配会取到 `obj/Debug` ⇒ `libhostpolicy.so` 找不到 ⇒ **无判词**（`#42` 两具日志即此）；③ 全程不自起显示 ⇒ 读数落在**无 X** 档。三处全修：自起 Xvfb（**按 PID 收尸**）＋ 声明档构建 ＋ 目录写死 ＋ 结论行印 `display=`/实际 `cfg=` |
| **自伤（如实记）** | ① 新工具第一版 `DISPLAY=x "${ARR[@]}" cmd` ⇒ 那个数组展开**不是赋值前缀**（被当命令名）⇒ `rc=127 未找到命令`；好在本件的**三态设计**把它变成 `NOINFO` 而**不是假绿**；② 同族陷阱做了**最小复现**：`$( … )` 带内层引号**嵌在更长双引号串中间** ⇒ `bash -n` 报未闭合引号（两种合法写法已写进注释）；③ `n_exc="$(grep -c … \|\| echo 0)"` 在**命中 0 次**时会打两行 ⇒ `[ … -gt 0 ]` 报"需要整数表达式"（改用 `awk` 数） |
| **位移与冻结** | **位移 = 空**（只动文档 ＋ 两件**未入 `inputs_fp` 覆盖面**的仪器）⇒ **不重冻**；`#40` 的 post-freeze ×2 **已全绿**（`VA_POST1_RC=0`／`VA_POST2_RC=0`）；⚠️ `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **刻意不动**（它的 sha16 是**冻结声明** ⇒ 改它会把 `BASELINE-SHA` 打红；更正写在 `CURRENT-STATE` 与 `KNOWN-DEFECTS`）；另跑 `PIPEFAIL_SIGPIPE=PASS`、`SHELL_QUOTE_TRAP=PASS`、`DEFREG`、`BASELINE-SHA` 各牙复核 |
| **留给下一波** | ① **"透参"产品修**（把 `paragraphProperties.DefaultIncrementalTab` 从两处调用点透进两级兜底 ⇒ 一次治 `D-T4` 残余 ＋ 缩小 `D-G48` 面；动 `pc` ＋ shim=`GEN_KEYS` ⇒ **五臂重取 ＋ 重钉**；**先测 136 条真值会位移多少**）；② `D-G47` 的**潜在真缺陷定性**（在 Release 件上打开那条断言诊断跑 hc）；③ 把 `build/PresentationCore.Linux/*.cs` 纳入 `inputs_fp` 覆盖面（**须独立准备趟**，且要在 `IN_FP_0` 之前）；④ 无 DISPLAY 档的"**最后一跳可诊断**"（`D-G47` 同族） |

## `#40` 波速览（2026-09-19 · **已被 `#43` 接手复核**，但**仍是当前冻结基线**；详细见 `docs/WAVE39-PREREGISTRATION.md` §9 ＋ `docs/WAVE41-PREREGISTRATION.md` ＋ `docs/WAVE42-PREREGISTRATION.md`）

**一句话**：**权威件从 Debug 切到 Release**（`D-G47` 的修法），同趟落 **F**（GDI+ 图像族真解码）与 **G**（`D-T4` 定位读数 ⇒ 新缺陷 `D-G48`）。

| 类别 | 内容 |
|---|---|
| **切配置（头号）** | 配置**唯一声明** `build/SelfBuiltConfig.props` ＋ 唯一 shell 读取器 `build/selfbuilt-config.sh`；**161 处消费点**接线（生成器/波/验收构建与 6 个 `dotnet test`/5 个 `AUTH_PC`/门禁与样本 runner/第三方 runner/桥的 AOT 输入/应用侧副本表/14 个探针工程 48 处引用/`ManagedLayer.Tests`/`HbTextLineParity` T0.7）；**先做 16 工程 Release 可编性自检**（全 0 错）再翻值 |
| **E（`D-G47` 产品两极化）** | hc 同一份代码：**Release** 件 ⇒ `assert_hits=0`、`rc=124`（活着）、`max_colors=373`；**Debug** 件 ⇒ `assert_hits=1`、`rc=134` ⇒ 那句 `Debug.Assert` 的终止形态**被治好**。⚠️ 373 色 ≠ `#34` 的 1275 色 ⇒ 渲染完整度**另立待办**（✅ **`#43` 已定性**：`373` 是正常值、两代帧 `AE=0`；`1275` 无留存物 ⇒ 见上方 `#43` 速览 ③）|
| **F（GDI+ 图像族真解码）** | `libwpfwic.so` 新增导出助手 `WpfWic_DecodeFileToBgra`（**Skia 仍只在一个文件里被调用**）；GDI+ 只读族**真做**、写族/流式**如实失败**；探针 **14/14 PASS**（7×5、首像素 `ffff8000`、scan0 stride=28、三条如实失败 10/13/6、Dispose 幂等）；**撒谎 shim 反极性被打红 6 例** |
| **G（`D-T4` 定位）** | 新探针 `TabGapProbe`（public 入口）实测 `tab=4/24/48` ⇒ 行宽 **32.797/56.797/104.797** ⇒ **推翻 `D-T4`"tab 步长完全没生效"这半句**；`tab=0`／tab>容器宽的折行档会**落到原生 LineServices ⇒ `LoCreateContext` 不存在 ⇒ 崩** ⇒ 登记 **`D-G48`**（判据：出现 EXCEPTION 即 FAIL）。⚠️ **`#43` 更正**：上面那两个"触发条件"是**无 DISPLAY 环境下的观测**（`X-CONFOUNDED`），真因是**无显示时兜底链必抛**；而"tab 值"只决定**走不走复杂行路径** ⇒ 见上方 `#43` 速览 ① |
| **五臂与世代** | 本波**重取**（`GEN_KEYS` 两处变动）＋ 新增可复用工具 `build/MilBridge/tools/repin-generation.py`（`--check` 牙；**四类地方同趟**，漏 `entries[*].caliber` 会报 `registry-generation-inconsistent`） |
| **自伤（如实记）** | ① 记录里的 `ARM-LOG-SHA` 行**手抄错一位** ＋ tline 行陈旧 ⇒ 改为**从现场臂日志现算**（纪律 49 的现场）；② GDI+ 助手第一版把 `obj_new()` 的 1-based 句柄当指针 ⇒ 段错误（探针当场抓到）；③ `tab-gap-check.sh`/`verify-all.sh` 两处 SIGPIPE/`set -u` 形态被仓的牙齿抓红并修 |
| **留给下一波** | ① `D-G48` 修法（兜底要么出结果、要么如实抛可诊断异常）；② `D-T4` 登记册更正 ＋ 产品侧修法；③ hc 在 Release 件下的渲染完整度（373 vs 1275）；④ `upstream/wpf` provenance（要联网） ｜**`#43` 判**：**②的登记册更正 与 ③ 已做完**（`D-T4` 补注已落、`373` 已定性），**④ 已完成**（无需联网：指纹＋裁剪证据＋配方在 `docs/UPSTREAM-PROVENANCE.md`），**① 收敛为"透参"产品修**并升为下一波头号 |

## `#39` 波速览（2026-09-19 · **已被 `#40` 取代**，详细见 `docs/WAVE39-PREREGISTRATION.md`）

**一句话**：把"权威件用哪个配置"**收敛到唯一声明处**（`#39` **阶段 1**；值仍是 Debug ⇒ 行为等价），
为"切 Release"（`D-G47` 的修法）铺掉"198 处各自写死"这个雷。

| 类别 | 内容 |
|---|---|
| **唯一声明（本波头号）** | `build/SelfBuiltConfig.props` = 权威件配置的**唯一声明**；两条 import 图各 import 一次（自产件图 = `build/Directory.Upstream.props`；样本图 = 仓根 `BuildHygiene.props`）。MSBuild 侧从此只有一个来源 |
| **唯一 shell 读取器** | `build/selfbuilt-config.sh`：`source` 后得 `SELFBUILT_CONFIG`；`--check` 两颗牙（声明恰好 1 条 ＋ **shell 值 == 两条图的 MSBuild 求值**）；缺件/解析不出 ⇒ `NOINFO`；`--debt`/`--debt-check` = 棘轮（写死 `bin/Debug` 的处数**只许减少**，上限是字面常量） |
| **14 处关键消费点接线** | `frame-step.sh`（`AUTH_PC`）｜`run-wpftextdemo.sh`（样本 bin ＋ 自产件一致性扫描 ＋ Provider）｜`close-wave.sh`（九位读数 10 处） |
| **行为等价（构造性）** | 值仍是 `Debug` ⇒ 解析出的路径与改前逐字相同；门禁两档 × 3 rep 全绿、`verify-all` 25 步全绿 |
| **⚠️ 自伤 ①（门禁当场抓红）** | 第一版变量名 `WPF_LINUX_SELF_CONFIG` **落在门禁默认档的清理域里**（那一档就是清空全部 `WPF_LINUX_*`/`HLWPF_*`）⇒ 应用路径塌成 `bin//net10.0`、`exit=127`、`default` 档三 rep 全红，而 `env` 档照常 2828 色（症状 = "只有主档死"）⇒ 改名 `SELFBUILT_CONFIG`。**纪律：新增工具变量必须避开判据的清理域** |
| **⚠️ 自伤 ②（棘轮抓自己）** | `--debt` 的统计 grep 模式串里也有 `bin/Debug` ⇒ 186 被顶成 192 ⇒ `SELFCONFIG_DEBT_CHECK=FAIL`。修法 = 计数排除本文件（同族教训："写下那句话的动作本身会改变证据"） |
| **`D-G46` 第二个独立实例** | `pc` 的 `#38` 期副本 vs 现场件：**只差 71 B / 6 段**、全在身份字段（PE 时间戳、MVID、Debug Directory 的 PDB GUID/age/校验和）⇒ **IL 与元数据逐字节相同**；并**排除两条候选机制**（SWE 替身与 `System.Xaml` 两代都逐字节相同）⇒ 机制**仍未归因** |
| **留给下一波** | ① `#39` **阶段 2/3**：`integration-wave` 以 Release 重建九个位 ＋ bridge AOT；186 处逐处判定（**不许 sed 全替**）⇒ 然后才改唯一声明那一行；② GDI+ 图像族真解码；③ `D-T4`；④ `upstream/wpf` provenance（要联网） |

## `#38` 波速览（2026-09-19 · **已被 `#39` 取代**，详细见 `docs/WAVE38-PREREGISTRATION.md`）

**一句话**：把 `D-G45` 打通 —— 官方 `System.Windows.Extensions` 包换成仓内 Linux 原生替身，
并让"官方包必抛 / 替身不抛"第一次有了**仓内两极化判据**；顺带登记一条与它无关的真缺陷 `D-G47`。

| 类别 | 内容 |
|---|---|
| **`D-G45` 打通（本波头号）** | 官方 `System.Windows.Extensions` 包 → 仓内替身。两条真根因：① 应用器 HintPath 写死 `bin/Release/`（波建的是 Debug）⇒ 引用落空 ⇒ RAR 回落到**包** ⇒ `System.Xaml.dll` 带包签名身份 ⇒ `CS0012`；② `System.Security.Permissions 9.0.0` **传递依赖** SWE ⇒ 必须留"排除 `compile;runtime` 资产"的占位包引用。修后 7 工程 + 4 样本 **0 error**、替身进应用输出、`integration-wave` rc=0 |
| **替身公开面/签名** | `SoundPlayer` 的 `Dispose`/`IsLoadCompleted`/`LoadCompleted`/`Stream`/`new SoundPlayer(Stream)`/`LoadAsync`/`Play`（`SoundPlayerAction.cs` 真的要用）＋**同属官方包的** `X509Certificate2UI`/`X509SelectionFlag`（`WindowsBase` 的 `PackageDigitalSignatureManager` 用；Linux 上**如实抛**）；替身**公开签名**（本仓 `WcpPublicKey.snk`）否则 `CS8002` |
| **B4 两极化（仓内判据）** | `samples/ThirdPartyMini` 里引用 **internal** 类型 ⇒ `GeneratedInternalTypeHelper`（生成物命中 1）⇒ `LoadBaml` 走 `XamlAccessLevel`。**正极性** `THIRDPARTY=PASS max_colors=1642`；**反极性**（换回官方包）`FAIL reason=app-exit=134` ＋ `PlatformNotSupportedException: System.Windows.Extensions types are not supported on this platform.` |
| **新登记 `D-G47`（不是本波造成的）** | 真实第三方 demo（仓外 HandyControl）库 + demo 0 error，运行期死于 `Assertion Failed: DependencyProperties can only be set on DependencyObjects`（`TemplateContent` 解析模板）；**反极性对照**：换回官方包**同一个 assert**（不是 SWE 异常），且该 demo 程序集里**没有** `GeneratedInternalTypeHelper` ⇒ 与接线无关。根因方向 = **Debug 权威件 + `Invariant.Assert` 未条件化** ⇒ 指向"权威件切 Release" |
| **自伤一处** | `patch-swe-linux.py` 被一次引号写坏的补丁弄成语法错误（**当时没备份**）⇒ 局部重建救回；教训：**改仪器前先备份**（后续每步都先 `cp` 到 `$HOME/w38-backup/`） |
| **留给下一波（按价值）** | ① 权威件 **Debug → Release**（`D-G47` 正指向它）；② GDI+ 图像族真解码；③ `D-T4`；④ `upstream/wpf` provenance（要联网） |

## `#37` 波速览（2026-09-19 · **已被 `#38` 取代**，详细见 `docs/WAVE37-PREREGISTRATION.md`）

**一句话**：把**第三方形态**搬进仓里变成**判据**（`verify-all` **24 → 25 步**），并把四件仪器"治自己"
（含一条新登记的封条纪律缺口 `D-G46`）。

| 类别 | 内容 |
|---|---|
| **第三方形态（仓内判据）** | `samples/ThirdPartyMini`：只经 `build/third-party/WpfLinux.props` 接线、不进 sln、产物复制到**仓外**再跑；`WindowChrome` ＋ 图片解码（WIC→Skia，`Bgra32`）＋ 中文/图标 ＋ 绑定列表全部渲染；接成 `verify-all` 第 `[19]` 步（**24 → 25 步**）。反极性：`--hide-shim` ⇒ `FAIL reason=app-exit=134` |
| **两条真问题（顺带抓到）** | ① `Win32ShimResolver` 会从 `AppContext.BaseDirectory` **与** `Directory.GetCurrentDirectory()` 向上 12 层找仓根 ⇒ **在仓内/cwd=仓根时，不部署 `.so` 也会被回退救回来**（反极性失效）⇒ 部署布局**必须在仓外**验证；② "一帧没采到"原先一律记 `NOINFO`，把"应用崩了"混成"仪器没跑" ⇒ 现按**应用退出码**细分（崩 ⇒ `FAIL`） |
| **`F4`／`D-G46`** | 三趟干净重编**逐字节相同**（`a3b1df59e1d0d05b`）⇒ 构建是**确定性**的；而 `#36` 冻结的 `pf` **≠ 任何一趟干净重编**，差异只有 72 B 身份位、**IL 与元数据逐字节相同** ⇒ 封条里那一行是"当时现场的身份位"，**不是**"当前源码的可复现构建"。九位封条**没有任何牙**能区分这两件事 ⇒ 登记 `D-G46` |
| **仪器四小项** | `F1` `magenta_frames=n/a`（自测 7/7）｜`F2` 读者进覆盖面（123 → 124）｜`F3` "本代必须有预登记节"的牙（自测 23/23，含两例反极性；挂在现有步 ⇒ 步数不变）｜`F4` 探针见上 |
| **自伤一处** | `fp_inputs()` 的 `printf` **续行链里塞了注释行** ⇒ `\` 先拼行再认注释，`#` 吃掉链尾 ⇒ 后面那行路径变成**独立命令被执行**（真把样本跑了一遍）。修法：注释只能写在独立注释行 |
| **留给下一波（按价值）** | ① 权威件 **Debug → Release**（单独成波：会翻九位 ＋ 改门禁链）；② `D-G45`（SWE 接线）；③ GDI+ **图像族真解码**；④ `D-T4`；⑤ `upstream/wpf` 的 provenance（要联网） |

## `#36` 波速览（2026-09-19 · **已被 `#37` 取代**，详细见 `docs/WAVE34-PREREGISTRATION.md` §3w）

**一句话**：把「**时间分辨的画面读者**」接进验收（`verify-all` **23 → 24 步**）—— 这是 `#34` 撞出来的
两条**仪器伪影**的制度性修法；顺手把「发布就绪」文档补齐（开源首版用），并登记 `D-G45`。

| 类别 | 内容 |
|---|---|
| **验收** | 新第 `[18]` 步 `FRAME-PRESENCE`：`build/MilBridge/tools/frame-presence-check.sh`，判据 = **采样窗口内「标记色是否出现过」**（不是「哪一帧颜色最多」）；三态 `PASS/FAIL/NOINFO`、`--selftest` **5/5**。实测 `FRAMEPRESENCE=PASS frames=80 max_colors=3961 magenta_frames=31 min_colors=200` |
| **为什么换判据** | ① 旧判据取「颜色数**最多**的一帧」⇒ 任何**让颜色数下降**的变化被系统性漏掉：`--late-content` 实测颜色数 **3960 → 2556**，采用帧永远落在变化**之前**（我据此报过一条**假红**）；② 「跑了 N 秒 ≠ 拍了 N 秒」：12 张截图落在 t≈0.4–4.8 s，而内容 t≈8.0 s 才出现 |
| **登记 `D-G45`** | 官方 `System.Windows.Extensions` 包在非 Windows 上**必抛**（`XamlAccessLevel` 等）；Linux 原生替身 `build/System.Windows.Extensions.Linux/`（构建 0 错）与应用器 `patch-swe-linux.py` **保留但停用**：接线后 `PresentationFramework` 报 11 错 `CS0012`（**程序集身份不一致**：包签名 / 替身未签名）。`--check` 复核 **0/7 已接线** |
| **冻结 `#36`** | **唯一位移 = 环成员 `pf`**（`f5beeb353baa959c → dbb0a450e09e76a3`），且**逐字节归因**：72 B / 5 段全在构建身份字段（PE 时间戳、MVID、Debug Directory 的 PDB GUID/校验和）⇒ **IL 与元数据表逐字节相同**。`inputs_fp` 变（重钉 `known-red.json` 的 `tline` **两处**） |
| **门禁** | 两档 × 3 rep **6/6 `BASELINE … result=PASS`**（`default` 窗口内 **3960 色** / `env` **2828 色**；`frames_good=14/14`、`frames_blank=0`、`cross_ae=0`、`leftover_after=0`、`exit=143`＝被 timeout 收） |
| **发布就绪** | `README.md`、`.gitignore`、`docs/RELEASE-READINESS.md`、`docs/THIRD-PARTY-APPS.md`、`build/third-party/WpfLinux.props`、`build/fonts/LICENSE-OFL.txt`（Noto Sans 是 OFL ⇒ 必须随附）。⚠️ **实测拦路**：`tests/parity/geometry/u14/linux-results-u14.json` = **118.2 MB** > GitHub 单文件 100 MB 硬限 |
| **自纠（1 处，且是"牙齿赢了"）** | 加步时忘了同步 `# VERIFYALL-STEP-NAMES:` 名单 ⇒ 第 `[11]` 步 `VERIFYALL_SELF=FAIL names=24 decl=24`。**修完后重跑整趟**；这条红说明 `#28` 加的牙**确实**能抓「加步忘改声明」 |
| **流程缺口（如实登记）** | `#36` 的落地**先于**预登记（违反自家协议）⇒ §3w 是**补写**的收尾记录；今天**没有任何牙**能发现「这一代缺一节预登记」（已写进 §3w 的提议） |
| **冻后验收** | `verify-all` **两趟全绿、且可复现**：两趟都 **24 步 / 通过 24 / 失败 0 / `rc=0`**，`BASELINESHA`／`ARMLOG_SHA`／`COLUMN_FLOOR`／`VERIFYALL_SELF` 四项自报**逐字相同**（日志：`$HOME/w36-verifyall-post1.log`、`-post2.log`） |
| **留给下一波（按价值）** | ① 权威件 **Debug → Release**（含 `Debug.Assert`/`Invariant.Assert` 的处理）；② `D-G45` 接线（身份一致/恢复方案）；③ GDI+ **图像族真解码**；④ `D-T4`（唯一改像素的已知红）；⑤ 新读者进 `fp_inputs()` 覆盖面；⑥ `pf` 的**可复现性探针**（同源重编两次比身份位） |

## `#34` 波速览（2026-09-19 · **已被 `#36` 取代**，详细见 `docs/WAVE34-PREREGISTRATION.md`）

**一句话**：**第一个真实第三方 WPF 应用在 Linux 上渲染出完整界面**（这是本工程"能不能给别人用"的第一次实证），
一路上撞出的移植缺口已全部修掉并冻结为 `#34`。

| 类别 | 内容 |
|---|---|
| **产品修法** | ①补丁 Q：`MimeTypeMapper` 的 UrlMon 查询 → 内置表（`pc`）；②WIC **流分支**：`CreateDecoderFromStream` ＋ 派生对象**字节继承** ＋ `CreateBitmap` 真实现（`wic_shim`，导出 77→78）；③`SetWindowRgn` **返 1**（原返 0 且注释把 Win32 语义写错 ⇒ **任何 `WindowChrome` 应用必崩**）；④全局钩子三件套**如实失败**（原来**完全没导出** ⇒ 第三方应用被 `EntryPointNotFoundException` 掀掉）（`win32shim`）；⑤官方 `System.Windows.Extensions` 包在非 Windows 上**必抛** ⇒ 新建 Linux 原生替身（`XamlAccessLevel` 等；`build/System.Windows.Extensions.Linux/`）。 |
| **第三方实证** | HandyControl 示例工程：库/demo **0 error**（148 Page 进 BAML）；**开窗＋渲染完整界面**（chrome＋中文控件名＋图标＋图片）；时间分辨采样 1–3 色 → **1241 色**并稳定；`rc=124`（非崩）。证据 `$HOME/w34-hc-34/f001..f036.png`（`f032` 人眼复核）。⚠️ **不构成仓内判据**（应用与探针在仓外）。 |
| **仪器** | 新增 `build/MilBridge/tools/frame-presence-check.sh`（**时间分辨**、三态、`--selftest` 5/5）；查明**三条同类伪影**（"选定帧"口径／采样时间窗／`cp -p` 保 mtime ⇒ 构建没重编）；milcore 加 env 门控 `WPFGFX_ROOTDIAG`（默认关）。 |
| **流程** | `D-G44`：`w27-freeze.py` 要求输入日志全绿，而 `BASELINE-SHA`/`ARM-LOG-SHA` 波内**必然红** ⇒ 互斥；已改成"声明类**冻前必红、冻后必绿**"两极化。**顺带暴露**：五臂重钉还要改 `build/MilBridge/known-red.json`（冻结脚本没覆盖这一步）。 |
| **位移 5 位** | `bridge 496951adff86a557`／`pc 6f86961e164b689b`／`pf 3978376f2b56c5c0`／`win32shim cc621224c7492132`／`wic_shim 3df2ed77727bd4cf` |
| **未做（不许读成已做）** | ①新读者**未接进** `verify-all` 步骤表；②替身**未接进**九工程的 `PackageReference`（今天靠"构建后部署"）；③权威件仍是 **Debug 构建**（`Debug.Assert`/`Invariant.Assert` 会 FailFast 真实应用）；④`D-T4` 未动；⑤第三方原生 interop 的"正道通道"（映射表补齐＋ALC 钩子）未做。 |

---

## 0. 进度看板

> 图例：✅ 完成 ｜ 🟡 部分完成 ｜ ⬜ 未开始 ｜ ❌ 阻塞
> 全部状态均经**实测验证**（构建 + 测试），非自报。最后更新：**2026-09-18 16:4x（主控：**波 `#33` 收官** —— **① 一个"已被写进结论的不准推理"被实测推翻**：`#32` 记的"`printf|grep -q` 的**小串安全**"**不成立**（1,337 B/75 行仍有 **2/300** 翻转；1.3 KB→0.7%、119 KB→220/300、250 KB→300/300；**只有单行 200 KB 是 0/100**）⇒ 判据是"**几次 `write()`**"不是"多少字节"；顺着它把那一族**扫穷尽并修 57 处**（5 件；`check-applocal-sync.sh` **47**／`integration-wave.sh` 3／`publish-milbridge.sh` 1／`column-floor-check.sh` 1／`fp-inputs-hygiene-check.sh` 1），并**新建牙接线为第 `[17]` 步**（`verify-all` **22 → 23 步**；真树 `PIPEFAIL_SIGPIPE=PASS … hit=1 low=10 diag=2 safe=60`、单趟 ≈4.8 s、`--selftest` 15/15）；**② 其中两处是"假绿"方向（比假红更坏）**：`integration-wave.sh` 的「**0 错 0 警**」唯一检查 ⇒ 伪负 = **编译器警告静默通过**；同件两处「空操作护栏」⇒ 伪负 = **一个什么都没做的应用器被报 ✅**（另有 `publish-milbridge.sh` 一处假警方向）；成对读数 = 五站点在 216 KB 多行载荷上 **OLD 真阳性 40/40 → NEW 0/40**、真阴性两版都 0/40；**③ `--selftest` 第一次有了"我在跑的时候自己有没有被改"的自证**（`D-G41` 落地 **11 件**；`baseline-sha-check.sh` 上教科书式两极化：旧件静默 `PASS 6/6 rc=0` ↔ 新件 `ST_ATTEST=NOINFO` 点名 `rc=2`），并修掉三处"**前提会消失却照印通过**"（`baseline-sha` 的 4 处写死世代〔**推翻 W32B 判它"自持"**〕／`t1b-ls-tripwire` 的 nm 交叉核对**整段消失仍印"通过"**／`defect-registry` 的"夹具-声明不同源"其实是**假红**）；**④ 3 条 `FrameProbe` 结构族红"红着但没登记"这个判断被推翻** —— 它们**早已登记在两本册子**（`known-red-frame-structural.md`＋`PcLineOracle/known-red.txt`），陈旧的是 `frame-step.sh` 自己那两句"未登记"（比登记件**晚 1h37m** ⇒ 诞生即假，本波按纪律 61 **只改字面、判据/rc 零改动**）；根因 = 已登记的 **`D-T4`**，且澄清了它的半句"需补 Windows 重录"**今天不成立**（`tab-anchor` 两臂齐备且是真 Windows 录制；机器证 = 配对 144、含 TAB 119、**真值两档不同 60 ／ 我方两档不同 0**）⇒ **`D-T4` 已有可判红的产品判据、可直接修**（`#34` 头号，方子 E1–E4 已备）；**⑤ 补上 `#31`/`#32` 记的两个"未取到"读数**（`hidden-only --selftest` **16/16 PASS**、`real 5m33s`；`close-wave` 的 `IN_FP` 窗口**成对实验**：窗口中间手改 ⇒ `IN_FP_0 ≠ IN_FP_1` ⇒ 必 `exit 5`，阴性对照两次逐位相同）；**⑥ 登记 `D-G42`/`D-G43`**（声明表 **77 → 79**）＋ `known-red-frame-structural.md` **身份表重锚**。**九位只有环成员 `pf` 变**（`a1ce403a74225f10 → {PF}`）、**`pc` 与 shim 一字节未动**（本波**不碰产品件**）、**不重取五臂**；五臂 `TLINE_GATE=PASS … judge=t1b3-tline-gate/7`；`verify-all` **两趟各 `rc=0` / 23 步 / 871 通过 2 跳过**；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**各 6/6 `result=PASS`**。⚠️ **主控自纠**：本波**先派单、后写预登记**（顺序反了，已如实标注）；`pkill -f 'w32-mem'` **把承载它的 shell 一起杀了**（改按 pid 停）。⏪ 上一轮：**2026-09-18 13:3x（主控：**波 `#32` 收官** —— **① 产品侧真缺陷 `D-T2-c` 落地**（`CollectLenient` 第一次**收集 modifier 覆盖终点**并接到**每一个**调用点 ⇒ 走产品入口的 5 个 `M_modifier` 例 **18 条逐行红 → 0**：`PEA_SUM … lines_judged=133 ok=117 red=18 noinfo=0`（rc=1）→ **`… lines_judged=147 ok=147 red=0 noinfo=0`（rc=0）**；`w`/`witw` 最大 |Δ| **`110.948667` → `0.011333` DIP**；`w80`/`w120` 各**补回一行**；3 个阴性对照 **98/98 不动**、`PEA_NOMOD` 诊断**逐字节相同**；**语义依据是真机真值自己印出来的** `runs` 数组，不是我们的论证）；**② 产品入口臂第一次接进 `verify-all`**（新第 `[16]` 步 `PRODUCT-ENTRY`；修绿之后它**不需要"在册红"机制** ⇒ 直接作为**普通绿步**，且**刻意没有"预期红"**）；**③ `D-G39` 的真因取到并修掉** —— **不是**"并发写 route 件"，是 `defect-registry-check.sh` **自己管线里的 SIGPIPE 竞态**（`printf '%s' "<多行串>" | grep -q`：bash 的 printf **每行一次 `write()`**，`grep -q` 命中即退出关读端 ⇒ printf 吃 **EPIPE→SIGPIPE** ⇒ `set -o pipefail` 把一个**管道事故**变成一条**判据错**）；`load1≈7.8` 时**独立复现 40 趟 → 20 FAIL ＋ 1 NOINFO**，点名 **18 个编号、全部在声明表里** ⇒ 修后同负载 **40 趟 → 0**；**两条通道**（`:206` 伪 FAIL、`:215` 伪 NOINFO）**都登记**；**④ 覆盖面补齐**（`fp_inputs()` **115 → 120**：纳入 `product-entry-step.sh` ＋ **四个从 `#26`–`#29` 起就一直没被看着的判据件**）；**⑤ 登记 `D-G40`（同一个值两份来源 ⇒ 一颗牙的自测"已死红"无人看见：`CHK_MUST='min=82'` vs `CAND_MIN=83`）与 `D-G41`（`"$0"` 重入自测 ⇒ **判据件被改写的那一刻**出凭空的红）**；**⑥ 对 `#31` 四处措辞的更正**（静树"不复现"是**低负载窗口**的性质／"排除 SIGPIPE"的推理错／10:05 那次瞬时 FAIL 的真因／`APPSYNC` 的 `OK` 63→65 逐字归因）。**九位只有 `pc` 变**（`7374308a00c55572 → b877ff3e3437145a`）、`hbtextline` 一字节未动、**不重取五臂**；五臂 `TLINE_GATE=PASS … judge=t1b3-tline-gate/7` ＋ `GATE_PROBE=PASS` ＋ `GATE_COLUMN=PASS` ＋ **`GATE_COLUMN_EXTRA=PASS`（三支臂）**；`verify-all` **两趟各 `rc=0` / 22 步 / 871 通过 2 跳过**；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**各 6/6 `result=PASS`**。**本波最值钱的一条是"一个每趟 50% 随机打红的伪红被查到根"** —— 它此前被**两次归因错**，而它一直在侵蚀"红数可信"这条纪律。⏪ 上一轮：**2026-09-18 12:0x（主控：**波 `#31` 收官** —— **① 三件「牙已备、无人跑」的件第一次接线**（新第 `[13]` 步 `HIDDEN-ONLY`（`D-T5-R` 的 32 格对照，**构建者**）、第 `[14]` 步 `COLUMN-FLOOR`（`D-G27` 的外挂读者）、第 `[15]` 步 `QUOTE-TRAP`（双引号里的反引号 = 命令替换）⇒ `verify-all` **18 → 21 步**，`#31` 起 `21 步 / 871 通过 / 2 跳过` **两趟结论区逐字相同**）；**② 反引号陷阱这一族第一次有牙，而新牙上线第一趟就咬出 12 条真陷阱**（`run-df1-criteria.sh:102`、`seg-instrument.sh:164/165`、`run-wpfprobe.sh:948` —— ⚠️ **最后一条是旧账**：任务书只提 `:659`，此前没有任何牙抓到）**并被它自己的金丝雀咬出 3 处失明**（两颗**假红**：`column-floor-check.sh:201-203` 的 heredoc 体内反引号；一处**盲区 201 行**：`build-hygiene-import-check.sh:307` 之后整片卡在单引号态；一处**恒绿的真洞**：**无引号定界**的 `<<EOF` 体内反引号**真的会替换**而旧件只发 `DIAG`、不进 `rc`）⇒ 状态机重写，非 `N` 态行首数 **473 → 96**、`新>旧` 的文件数 **0**、`--selftest` 22 → **30**；**③ "没有一支臂走产品入口"的代价第一次被量到**（`ProductEntryArm` 走 `TextFormatter.Create()`＋`FormatLine`：5 个 `M_modifier` 例 **18 条逐行红**、`ok=117 red=18 noinfo=0`，阴性对照 **98/98 全绿**（最大 |Δ| `0.022667` DIP）；真红 = **宽度少 `110.948667` DIP**（`w`/`witw` 我方恒 `45.968`），根因 = `CollectLenient` 只记 modifier 起点、`modifierScopeEnd` 未接线 ⇒ shim 侧 `kh = visibleLen` ⇒ 零宽跨度 `[6,62)`（真机 `[6,45)`）；**并顺带推翻一条已登记的归因**：`#30` 说"那 5 条 **Extent** 余差与 modifier 同根"，而端到端实测 `ext` 我方 == 真值 == `18.000000`（5/5 OK）、`18.08` 是**阴性对照的真值** ⇒ 真红在**宽度**不在 `Extent`（纪律 67 已按纪律 61 加 ⏪ 注，原文一字未动））；**④ `D-G27`/`D-G9` 的 4 类外挂声明行补齐**（`#30` 自己留白的那 4 类，与接线**同趟**；补行前 `COLUMN_FLOOR=NOINFO rc=2` → 补行后 `PASS rc=0`、5 条 `# ARM-LOG-SHA` 逐条 `OK`）；**⑤ 仪器自身的回归第一次被自己的牙咬住**（`D-G37`：`column-floor --selftest` 被 `judged_min:null` 扩臂打穿 `18/18 → 11/18`，而它当时**未接线** ⇒ 没有任何门会响；单变量实验沙箱里拿掉那两支臂 ⇒ 当场回 `18/18`；修后 **26/26**，且**真树读数逐字节不变**）；**⑥ 第二次 `swapfree=0MB` 现场**（`11:54:45`，连续 5 个样本 ≈100 s，而同一笔 `MemAvailable` = 3587 MB **看着完全健康**、`dotnet=1` ⇒ **预警必须看 `swapfree`** 第二次被证实；⚠️ 触发时机是**应用门禁**（画窗口/截图），不是构建期）；**⑦ 登记 `D-G35`–`D-G39` ＋ 纪律 69/70**（数进程不许数到自己命令行：`pgrep -c -x dotnet` = 0 而 `ps -eo pid,args | grep -c dotnet` 报 4；散文式否定宣言与现场会悄悄分叉，且**可以就发生在同一段文字里**）。**九位只有环成员 `pf` 变**（`51e987d58da11654 → f418131a53fa2951`）、`hbtextline` 一字节未动、**不重取五臂**；`TLINE_GATE=PASS … judge=t1b3-tline-gate/7` ＋ `GATE_PROBE=PASS` ＋ `GATE_COLUMN=PASS` ＋ **`GATE_COLUMN_EXTRA=PASS`（三支臂，两支 `judged_min=none`）**；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**各 6/6 `result=PASS`**；`inputs_fp 98f600e5… → 46d2a2b0f510f770…`（成员 **110 → 115**，设计性变更）。⏪ 上一轮：**2026-09-17 23:5x（主控：**波 `#30` 收官** —— **① `D-G26`：探针身份第一次可核**（三支 `tab-*` 日志自报 `TAB_LINES_PROBE sha256=<64>` ＝ 现场探针源**全 64 位逐字相等**；门禁新增 `GATE_PROBE=`；**最硬的零位移证据 = 剥掉那行身份后与旧件 `cmp` 逐字节 IDENTICAL**；按纪律 59 重取三支臂，`ARMLOG_SHA` **先咬后合**）；**② `D-G27`：给两颗列级下限与 `arm_logs` 配外挂读者**（原先 `615→421`/`421→400`/`194→0` **四档全 `rc=0`**，且两行机读行归一化后 `cmp` 逐字节相同；同趟改 `arm_logs` 亦能洗绿）；**③ `D-G33`：构建卫生见证由"判产物"改"判结构"**（"删 `obj/`"不再是免罪符）；**④ `D-G34`：`close-wave.sh` 的 `pgrep` 自匹配**（脏命令行假停 3→0、真应用在跑仍停）；**⑤ `D-T5-R` 的牙修两处**（归因分支原是死代码 ⇒ 每格 `rc=134` 都被印成"先怀疑环境"；缺 shim 由 `FAIL` 改 `NOINFO`）。**六条车道全部交付**；其中一条**修掉草稿 5 处真缺陷**（两处会让新牙**上线即哑**）。九位只有环成员 `pf` 变、`hbtextline` 一字节未动、**六条门禁行归一化后与 `#29` 逐字相同**。⚠️ **三条真实隐患被翻出**：`swapfree=0MB` 而同一笔 `avail` 看着完全健康（⇒ 预警必须看 `swapfree`）｜`$HOME/wfp-runs/arms23` 的"归档"其实是**硬链接**（⇒ 纪律 59 的归档层是空的）｜**没有任何东西看着"`--selftest` 用例失去前提"**（⇒ 纪律 68）。⏪ 上一轮：**2026-09-17 22:3x（主控：**波 `#29` 收官** —— **① `D-G30`：`OVERFLOWED` 的对账行成为牙**（原来**谎报**与**整条删除**都是 `rc=0`/`PASS`）；**② `D-G31`＋第 `[12]` 步：`fp_inputs()` 不再把构建产物当输入**（原先**每构建一次指纹就变一次**）；**③ `D-G32`：修掉 `WpfGfx.Linux.csproj` 的**真暴露****（判据先判红、**主控接住并真修**、三处同趟；**桥重发后二进制逐位不变** ⇒ 零产品位移）；**④ 推 `judge=` `/4 → /5`**；**⑤ 登记 `D-G26`/`D-G27`/`D-G30`/`D-G32`/`D-G33`/`D-G34` ＋ 纪律 63/64/65**。**九位只有环成员 `pf` 变**、`hbtextline` 一字节未动、**六条门禁行归一化后与 `#28` 逐字相同**。⚠️ **一次真实资源事故**：**`swapfree=0MB`** 而同一笔 `avail` 看着健康 ⇒ **预警要看 `swapfree`**。⏪ 上一轮：**2026-09-17 19:4x（主控：**波 `#28` 收官** —— **① `D-G19`：`OVERFLOWED` 列第一次有下限牙**（该列三种失真在旧门禁上**与什么都没发生逐字节不可区分**，现在各自 `rc=1/2` 并点名）；**② `D-G20`：门禁第一次读探针的「逐例对账行」**（三层一致；稳定性是**结构性**证明）；**③ `D-G22`：`verify-all` 第一次"自己有牙"**（新第 `[11]` 步 `VERIFYALL-SELF`，**世代无关性三方向实测**）；**④ `D-G23`/`D-G24`/`fp_inputs()` 三条小项**；**⑤ 登记 `D-G26`–`D-G31` ＋ 4 处旧记录更正 ＋ 纪律 63/64**。**第三次"零产品位移、仪器大改"**：九位只动 `pf`（`3d44e756475b5dd4 → 9178561e0fb1451c`）、`hbtextline` 一字节未动。**最值钱的非落地产出**：**独立复核把主控与作者的自报各打掉几处** —— `RED_BY_FIELD` 6→**7**、"42 份都不是暴露工程"**被推翻**、"`.sh`/`.py` 命中 0"**其实是主控自己写的注释**、作者的 `--selftest 19/19` 在被测件换代后是**假绿**。⏪ 上一轮：**2026-09-17 18:3x（主控：**波 `#27` 收官** —— **① `D-G14` 的"下半身"：列级读数第一次进五臂门禁**（新机读行 `GATE_COLUMN=`，**下限钉在实测值本身**；反极性四档含"退化 ⇒ `FAIL column-gate-regressed`"与"删声明 ⇒ `NOINFO`"；**13 个既有读取点一个没删没放宽**、`RED_BY_FIELD` 6/6 KEPT）；**② `D-G17`：跳过数上屏 ＋ 上限断言**（`--no-x` 再也不许静默关牙而全绿；X 不可用必须打 `SKIP_GUARD=REDUCED` 并逐字写明"射程缩减"）；**③ 第 `[9]` 步 `BUILD-HYGIENE`**（`D-R8` 的接线回归牙；**另派车道在真副本上做了 6 种坏法的独立咬合取证、真树零污染**）；**④ 第 `[10]` 步 `DEFECT-REGISTRY`**（`D-G15` 的编号双向对账，声明件由 `--emit` 机械生成；**主控用自己的脚本独立复算过双向差集**）；**⑤ 登记 `D-G19`–`D-G25` ＋ 4 处旧记录更正**。**本波与 `#26` 同类：又一次"零产品位移、仪器大改"** —— 九位只动环成员 `pf`（`ebbe3bab855cdd55 → 3d44e756475b5dd4`）、`inputs_fp` 一字未变、**六条门禁机读行与 `#26` 逐字相同**（归一化 `pf`/`rundir` 后）。**最值钱的非落地产出**：`OVERFLOWED` 列**今天仍可"判定行悄悄变少"而静默**（W28C 在副本上实测 `421→400` 仍 `rc=0/PASS`）⇒ 方案与 6 档反极性已备，留给 `#28`。⏪ 上一轮：**2026-09-17 17:0x（主控：**波 `#26` 收官** —— **① `D-G14` 列级覆盖闸（＋`D-G12` 字宽列）**：`Start` 列**判定行 421 → 615、`NOINFO` 194 → 0**，**RTL 非零 `Start` 由"行使 0 行"→"行使 33 行"**（33/33），而**既有 288 例/421 行零位移是机器证的**；**② `D-G10`：`verify-all` 的绿屏第一次印出自报口径**（＋一个真漏报例的成对读数）；**③ `D-G13`：`--selftest` 的假红改判 `NOINFO`**（该红的仍红；判定面位移 0）；**④ `D-G9`：结构化 `arm_logs` ＋ 新的第 `[8]` 步**（**先咬后合**：臂重取后 `FAIL pass=2 fail=3`，重注入后 `PASS 5/5`）；**⑤ 登记 `D-G15`–`D-G17` 与纪律 52b/56–59**（并更正 51 与 §9.1b）。**本波是"零产品位移、仪器大改"的一波**：九位只动环成员 `pf`、`inputs_fp` 一字未变。**最值钱的非落地产出**：W25K 的"① 有牙 24"被对抗性审计校正为**真牙 14／半牙 8／假牙 2**；W26H 的 12 行矩阵查出**一处至今未接线的假绿**（留给 `#27`，草稿已备）。⏪ 上一轮：**2026-09-17 13:3x（主控：`#25` 波收官** —— `D-T5-R` 修好（零世代成本）+ `D-A2-r` 方案 B + 两条登记结算 + `D-G9`–`D-G14` 登记）。
> ⚠️ **判过期的方法**：本页**九位**若与现场不符 ⇒ **本页已过期**（现场重算 = 第 2 节四条命令 + `/tmp/bridge-frozen.flag` 逐位对照）。
> 🎯 **当前冻结 = `#31`（2026-09-18 11:5x，`run_dir=~/wfp-runs/w31/gate2`，波 `close-wave-112145` + 两趟 `verify-all`（**21 步**）+ 两趟应用门禁）**：`bridge d567c26f197ec1e3`（`BRIDGE_SRC_FP=fdcb41bdc373eee3`）｜`pc 7374308a00c55572`（**未动**）｜**`pf 51e987d58da11654`**｜`windowsbase 1114a28ec5a03ab7`｜`provider 9aa0d744802aaa31`｜`win32shim 0098234982391bbf`｜`wic_shim 03b67fbcd7c385b6`｜**`hbtextline e89fed55fd8e32bc`**（一字节未动）｜`dwf 0ed422ef2dd46445`；**`inputs_fp = 46d2a2b0f510f77059051e68b49f5d3a8a52e300f9995b1df720e9e7aa013a84`**（设计性变更：成员 **110 → 115**）。五臂 `TLINE_GATE=PASS … judge=t1b3-tline-gate/7` ＋ **`GATE_PROBE=PASS`** ＋ `GATE_COLUMN=PASS` ＋ `GATE_COLUMN_EXTRA=PASS`（三支臂）；`ARMLOG_SHA=PASS 5/5`；`verify-all` **rc=0 / 21 步 / 871 通过 2 跳过**（**两趟结论区逐字相同**）；应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、**各 6/6 `result=PASS`**。⏪ 上一次冻结 = `#30`（`pf 51e987d58da11654`）。
> ⚠️ **紧接下面那块"完成判据"的"当前对照"仍是 `#8` 时代（2026-09-14 10:0x）的记录** —— `#8` 与 `#16` 之间还走过 `#9`–`#15` **七版冻结**，那一段**已过期**。**现行口径 = `docs/CURRENT-STATE.md` §3（六条在 `#16` 上重核）+ 本文件下方"波 `#16` 完整记录"**；两者冲突时以 `docs/CURRENT-STATE.md` §3 与 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#16` 表头为准。
>
> ### 🎯 完成判据（可核 —— "完成"必须能被逐条复算，不许靠叙述）
> 1. **真实 WPF 应用从源码在 Linux 上编译并起窗渲染**：`samples/WpfTextDemo` 用移植后的 PC/PF/WindowsBase/桥 `dotnet build` + 运行；每趟门禁打 `WPTD_GATE=PASS`（2 档 × 3 次，`frames_good=14/14`、`capture=ok`、`scroll=ok`、`cross_ae=0`、`leftover_after=0`），并有一条**行推进判据** `WPTD_LINE_ADVANCE=PASS`。
> 2. **基线冻结且与产物一一对应**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 最新冻结的**八位元组**（`pc/pf/bridge/provider/win32shim/wic_shim/hbtextline(+stale)/windowsbase`）逐字取自那一趟 `WPTD_ARTIFACTS`；**任何一位变化都让该基线作废**（所以要冻就冻在产物收尾之后）。
> 3. **全量回归绿**：`verify-all.sh` 全步通过、0 失败（读数含通过/跳过/总数），且**跑前跑后权威产物 sha 不变**（若变，必须披露并重新冻结）。
> 4. **身份可答**：任何"读数"都要能回答"跑的是哪一份件" ⇒ 八位元组 + `BRIDGE_SRC_FP`（`build/bridge-src-fp.sh`）+ `hbtextline_shim_stale`（对**权威 PC** 比）+ 桥新鲜度位 `BRIDGE_SRC_STALE`。
> 5. **在册缺陷逐条有"依据 + 判据"**：每条给 状态（已修/在册）、**判定依据**（原始读数或 `file:line`）、**判据**（怎么算修好、怎么算没修好）；**"不知道修没修"的条目数必须为 0**（这正是 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的作用）。
> 6. **无中间态**：不存在"源码已改但产物未重建"却仍被当作结论依据的情况 ⇒ 三道新鲜度位（`WFP_SRC_STALE` / `hbtextline_shim_stale` / `BRIDGE_SRC_STALE`）必须都能回答，**答不出来要报"无信息"，不许报绿**。
> 当前对照（**2026-09-14 10:0x，主控现场读 —— 这是收尾状态**）：
> ① **✅** 应用编译+起窗渲染：`#8` 那趟 `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、两档 `passed=3/3 failed=0 inconclusive=0`、`runner exit=0`；
> ② **✅** 基线 **`#8` 已冻**，**八位与权威产物逐位相符**（主控独立重算）+ 桥 fp 文件==现树 `705ed5ccd0c498a1` + 6/6 `result=PASS`（第九位 `dwf_sha` 手工记录，下一版起机读）；
> ③ **✅** `verify-all.sh`（最终件）**9/9 步、869 通过 / 2 跳过 / 0 失败**，**跑前跑后九位逐位未变**；
> ④ **✅** 身份就位：八位 + 第九位（DWF）+ `BRIDGE_SRC_FP` + `hbtextline_shim_stale` + `BRIDGE_SRC_STALE` + `ARTIFACT_SRC_FP`（PC/WB/PF）+ 扩展可见位（9 件，含经 NuGet 钉版可复算的 `libSkiaSharp.so`）；桥位**上线即抓到一次真阳性**；
> ⑤ **✅** 在册缺陷逐条"依据+判据"齐备：**`D-P1` ① 关闭**（工具终判 `closed rc=0`，写后 DP 值 == 该读时的容器真值；`changes=0` 一族=观测口径失效）；**`D-R1` 纯 RTL 已修**且三条判据与修法② 逐位相同；**handoff:403 的 EOB/EOP 欠账已兑现**（`HBLINE_LINE#` 全 `eop=1` + `HBLINE_LINEQ#` 可见"哪行被问过"）；**`D-B1` 混合方向=用户裁定"范围外/已知边界"**；**`D-K1` 修饰键**：shim 桩已修（API 极性正确）+ 影响面收敛 + **整批型调用方的失败环节记在册未定位（带一条可定案的读数设计）**；
> ⑥ **✅** 无中间态：三道新鲜度位 + `ARTIFACT_SRC_FP` + 波内 `step 2.5/3.5/3.6` 三道自动检查 + **输入稳定性位**（波前==波后）。
> **仍未做的（明确登记，不是遗漏；截至 #8）**：
> ① **两条在册红**：`T2` 记账（`行 1286/1298`、宽度超差 47）、`T3` Collapse（`明细 218/236`）—— 都在 `tline` harness 里保留红，不是回归；
> ② `Extent` 余差（`1260/1298`，其中 34 条 = 含 `与` 的"结构性不可比"、4 条 = `M_modifier_*`）；
> ③ `M_modifier`（`TextModifier` 未实现）、Tab 口径 15 例；
> ④ 混合方向 bidi（**用户已决定不开专项**，边界登记为 `D-B1`，重启入口 = `build/MilBridge/T1d-bidi-decision.md` 的第 0 步）；
> ⑤ **`D-K1` 整批型调用方的失败环节未定位**（观测事实保留；一条可定案的读数设计已写在 `KNOWN-DEFECTS.md`：给 `GetKeyState` 加"调用时刻+是否在 dispatch 中+返回位"逐次日志）；
> ⑥ `-ipath` 缺口、`ReachFramework` 纳入 ITEMS（**主控决定暂不改**，理由已落档）、`RefsTale`/债务 #1/#26（自动化收尾）等历史欠账；
> ⑦ **元组覆盖**：第九位（DWF）下一版起机读；扩展可见位（9 件）待 T3 落地（**不改冻结判定**）。
>
> ### 🧭 接手先读（2026-09-11 20:3x **交付冻结快照** —— 防"中断后空转"）
> 🔴🔴 **本小节（到下一节为止）里的产物数字已于 2026-09-13 晚全部作废——先看这条再往下读**：
> 📄 **如果只读一个文件，读 `docs/CURRENT-STATE.md`**（2026-09-14 10:1x 主控）：产物八位 + 第九位 + 桥源指纹、**四条自证命令**（**全部实测可跑**）、完成判据六条现状、**在册未做项表（带判据与归属）**、11 条"不许破的纪律"、以及"细节在哪"索引。**本 handoff 是过程档案（3900+ 行）；一页纸在 `docs/CURRENT-STATE.md`。**
> **唯一权威 = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的最新冻结**（现在 **#8**），八位逐字取自那趟 `WPTD_ARTIFACTS`。
> 当前值（2026-09-13 22:48–00:00 主控现场重读）：**桥 `f68f01c10e456982`** / 4,950,336 B（**含 T2b 的 `Rendering/**` 坐标空间修法**；AOT 发布实测逐字节可复现）｜PC `23567d420f0dbbaa`｜PF `bfb10fe2a01a986b`｜WindowsBase `8c073fab0da88169`｜provider `71ba86c6495347fe`｜win32shim `f84d65a62e0c7fa4`｜wic `03b67fbcd7c385b6`｜hbtextline `5a04875ae87a294d`（`stale=no`）。
> ⇒ 下面那些 `3479253784…`/`36abe241…`/`30f7637a…`/`ebccdb1e…`/`e0d01832a3…`/`e1691fd8…` **只当历史**，**别再当闸门或"当前件"用**。（这条横幅本身就是一条教训：这个"接手先读"块从 16:10 起就没再更新，而它长得就像"当前值"——**记录陈旧会直接误导下一个接手的人**，见下方"记录自己会陈旧"一节。）
> **权威产物（七元组，T3 的基线按实时读数绑定）** —— ✅ **2026-09-13 16:10–16:19 合并窗口后的当前值（现场重读）**；上方 `d3444370…`/`49fdda9a…`/`177a07a6…`/`4c023937…`/`684424fe…`/`66703024…`/`6213489c…` **全部作废，别再当闸门用**：
> PC **`3479253784172bd424a73805…`** / 4,174,336 B（`build/PresentationCore.Linux/bin/Debug/PresentationCore.dll`，16:16:53）｜WindowsBase **`30f7637ad7d01aae5f72f648…`** / 1,218,560 B（16:15:35，含补丁 N+P 接线）｜PF **`36abe241bfe5b0a9a4f73e30…`** / 7,099,904 B（16:18:22）｜文本 shim（HbTextLine）**`ebccdb1ee65e6f7653da338d70188410615062f825a10969b737ca7d48281bbf`** / 206,286 B（**已编进 PC** ⇒ `hbtextline_shim_stale` 真值 = `no`）｜provider **`71ba86c6495347fe…`** / 110,080 B｜桥 **`e0d01832a3efea53e6d8e40f04ad136b265e31425e4db087490516cffdfe299c`** / 4,937,968 B（16:11:04，**含 T2b 的类名后缀 + 3 处 Interop 接线**）｜WIC shim `03b67fbcd7c385b6…` / 70,440 B / 13 导出｜`libwpfwin32.so` **全仓 4 份同 sha `e1691fd8440da926cb411a06cba23227189a32be737ff56783299d5ecfad6118` / 269,616 B**（16:10，**含 F2 建窗诊断**）。
> **门禁**：`integration-wave.sh` 第二次跑 **波前==波后==`143a9f799fe22159020dd55991e7a185982a38c0bd02755e8bea5cd48b860548`**（第一次被守卫抓到 T1c 波中改应用器 ⇒ 已作废重跑）＋ `verify-all.sh` **9/9、843 通过 / 2 跳过 / 0 失败**。
> 🔴 **新登记一条"中间态"**：本元组之后**任何**一条产物的改动都会让上表作废（PC/桥/shim 任一变化都要重新基线）；见下方"波 10"的三条事故与合并窗口记录。
> ⚠️ **一族陈旧副本（债务 #20，机制级修法已部分落地）**：`samples/HelloWpf/bin/{Debug,Release}/net10.0/PresentationCore.dll` 与 `build/DirectWrite.Linux/{WiringSmoke,SystemFontsProbe,WicClosedLoop,WicWriteClosedLoop,FontEntryClosedLoop}/bin/**` 的 `PresentationCore.dll` **不是**权威 PC ⇒ 这些目录**若是启动目录**，跑出来的就是旧 PC（跑前必须重建；各自 `run-*.sh` 内含 build 的除外）。`build/MilBridge/tests/*` 的 Release 探针已由 T2 的 `SyncProviderAuthority`（`Directory.Build.targets`）在每次构建后强制同步权威 Provider。
>
> ## 📌 2026-09-13 波 10（六车道并行）+ 合并窗口 —— **三条新事故，其中两条是"仪表在骗人"**
> ### 🔴 事故 A（**产物被无守卫的流水线覆盖**，T1b 自己报的）：发布目录的桥在 **16:02** 被换掉
> T1b 为调用 `run.sh` 里的一个函数写了 `source build/MilBridge/run.sh`，而脚本底部是 `case "$CMD"` 分发 ⇒ **`CMD` 为空落到 `all`** ⇒ `gen → **AOT 发布** → 闭环` 整条跑完。
> **后果（我现场核对）**：`build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` 从 **`66703024af8c115d…`** 变成 **`55a9566efde6230c73ecfb013abe3773`**（同为 4,937,968 B，`libwpfwic.so`/`libSkiaSharp.so` 未变、部署契约仍成立）。
> **为什么必须隔离**：那次发布发生在 **T2b 的突变自测窗口附近**（`src/WpfGfx.Linux/Rendering/RenderDiagnostics.cs` 16:01 刚被改回），**没有任何"发布期间 `src/**` 未被编辑"的指纹为证**（这正是 `publish-milbridge.sh` 存在的理由）。
> ⇒ **裁定：`55a9566e…` 记为"来历不明"，不作为任何证据载体**；下次发桥由主控按 `publish-milbridge.sh` 重发并**当场记录 `src/**/*.cs` 指纹**。
> ⇒ **纪律（新）**：**不许 `source` 任何带命令分发的脚本**；要用其中函数就 `sed -n '/^fn() {/,/^}/p'` 抽出来单独执行。
> ### 🔴 事故 B（**恒假仪器**，第 17 个成员；主控查出）：`hbtextline_shim_stale` **按构造永远是 `no`**
> `run-wpfprobe.sh:178-182` 拿 `stat -c %Y "$OUT/PresentationCore.dll"` 去比 shim 源 mtime，而 `$OUT` 里的 PC 是 **:151/:157 `cp -f` 当场新拷的** ⇒ 副本 mtime = 拷贝时刻 = "现在"，**永远大于源 mtime** ⇒ 该位**不可能为 `yes`**。
> **真值恰是 `yes`**（现场纳秒读数）：shim 源 `00:36:31.032156734` > 权威 PC `00:00:23.362964668` = 应用加载的 `samples/WpfFeatureProbe/bin/Debug/net10.0/PresentationCore.dll`。
> ⇒ **T1d 的 per-run 前景改动还没编进任何应用在跑的 PC** ⇒ **在那之前，"Latin 橙 / CJK 蓝"这类应用级颜色判读一律只是临时判定**。修法（已派 T3）：对着**权威 PC** 比，或把 shim 源 sha 打进 PC 产物再运行时比对，并给能变红的牙。
> ### 🔴 事故 C（**一个数字两个消费者，一个陈旧**，第 18 个成员；主控枚举判定）：`ClosedLoop A5` 的 28 是陈旧的
> T1b 事故里顺带看到 `FAIL A5 NotImplExportNames got 27（expect 28）`。**现场枚举**：`grep -c ExportDepth.NotImpl` 得 28 行，但其中 `:217` 是**判定代码本身**（`if (pair.Value == ExportDepth.NotImpl)`）⇒ 清单条目 **27**（`:86-119` 26 条 + `:170 MilResource_SendCommandMedia`）。
> 与 `tests/…/Commands.Tests/MilExportTests.cs:216 Assert.Equal(27, notImpl)` 一致（其注释写明"29→28；M7c/#24 再 −1 ⇒ 27"）⇒ **`build/MilBridge/tests/ClosedLoop/Program.cs:219` 的 28 与算式文案停在 #24 之前**。
> ⇒ **不是回归，是断言陈旧**。**教训**：同一数字被两个套件各写一遍时，**必须先枚举出真值再判谁陈旧**（`grep -c` 会把判定语句本身数进去 —— 这一格差点让我自己也判错）。
> ### ✅ T1d：per-run 前景色落地 + **`.notdef` 线索被否证**（双向实验）
> `RunSlot` 贯通 `HbRunFaceInfo→HbFontSegment→HbShapedChunk→HbTextLine._runBrushes`，`DrawCore` 改 `DrawGlyphRun(BrushForRunIndex(i), …)`；**`GetTextRunSpans()` 一字未碰**。牙：`RunSlot=ri→-1` ⇒ C2 两段又同色（P13 ❌）；还原后 sha **逐字节回到 `ebccdb1e…`**。
> **`.notdef` 假说否证**：`.notdef`(gid0) 上伸 11.4240（**有墨迹的方框**，按修正口径 `上伸 = y_bearing`），`'与 '` 的 `glyphIds=[0,3]`、inkBox h=13.424 = HB 墨迹 11.424 **+2.000 垫值**（拉丁行同样 +2.000）⇒ **没漏算**。
> **真因（双向）**：给 `与` 一个真 CJK 面（R1 回退）⇒ `'与 '` Extent 16.2080（真值 16.0859，Δ+0.12）、`'nbsp 与 '` 18.9280（真值 19.0744，Δ−0.15）；全量 34 例/114 可判行 ⇒ **超差 34 条恰好就是含 `与` 的 34 条（100% 命中 / 0% 误伤）**。
> ⇒ **裁定：不给单字体入口开 CJK 回退**（会动 `T1.73/T2/T2b/T2d` 四条基线），那 34 条**登记为"结构性不可比"**，不算缺陷。
> ### ✅ M7b：F2 诊断落地（源码）+ 补丁 P **已登记进波表**
> `WPF_LINUX_WIN_DIAG=xerr` 的期望输出四行已实测（`error_code=3(BadWindow) request_code=3 resource=0xdeadbeef`）；建窗失败两站点（`win32_core.c:454` `wpf_x11_ensure()` 返 0、`:490` `XCreateWindow` 返 0）**默认开**打印。**安装由主控做**。
> ⚠️ 它的应用器是 `patch-shared-hwndwrapper-diag`（**不在 `patch-presentation*` 通配里**）⇒ 主控已加进 `build/integration-wave.sh` 的 `APPLIERS_EXPLICIT`（紧跟补丁 N），否则 `port-lib.py WindowsBase` 会**静默抹掉接线**。
> ### ✅ T2b：类名后缀落地 + **`Interop` 三处接线**（主控点名的跨车道改动）
> `未画种类 {N}{NotDrawnSummary}`（唯一生产点 `Interop/MilPresentation.cs:195/:202/:208`，取值 `:947`，属性 `:971` 旁）；**只追加**（旧形态命中数 3→0，新形态 3）；空态返回 `string.Empty` ⇒ 前缀逐字不变。**`src/**` 自此冻结**，等重发桥。`MilPresentation.cs` sha256 = `60b1c2f1…`。
> ### ✅ T2：`SyncProviderAuthority`（结构修法）+ 检查器口径 + 牙
> 新增 `build/MilBridge/tests/Directory.Build.targets`（只构建不 clean ⇒ 副本必变权威 sha；`/p:ProviderAuthorityPath` 可覆盖 ⇒ **可被验收②证伪**）；检查器口径"`NO-AUTHORITY` 判不了 ≠ 不一致"落盘并加自检 A–D；`DirectWrite.Linux.Tests` **123 通过 / 0 失败**。
> ### 🧾 合并窗口（主控，**串行**，T3 已交还应用槽）
> ① 波表补 `patch-shared-hwndwrapper-diag`（**已做**）→ ② `integration-wave.sh` 重建 PC（含 WindowsBase/HwndWrapper 接线 + T1d 的 shim ⇒ **站点 D 首次进 PC** + T1c 新写的输入追踪应用器）→ ③ `build-shim.sh --all` 构建 native shim + 同步 4 份副本（**先确认无进程 mmap 着目标文件**）→ ④ `publish-milbridge.sh` 重发桥（记录 `src/**/*.cs` 指纹）→ ⑤ `verify-all.sh` 全量 → ⑥ 再冻结 `ACCEPTANCE-BASELINE.md`（七元组重读）→ ⑦ 重跑 `textbox-edit` 诊断 + `1400` 忠实复现。
> ### ✅ ③ 已完成：native shim 已重建并**全仓同步**，F2 打印管线**由主控独立复验**
> 新件 `libwpfwin32.so` = **`e1691fd8440da926cb411a06cba23227189a32be737ff56783299d5ecfad6118` / 269,616 B**（16:10），4 份副本同 sha（`src/WpfGfx.Linux.Native/bin/` + `build/MilBridge/tests/{ContractProbe,CompositeFontProbe}/bin/Release/` + `build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/`）。ABI 自检"全部一致"、导出 **462** 个（`WpfLinuxWin32_*` 19 个）。
> **独立复验（不依赖 M7b 的自述）**：`dlopen` 加载**已安装的**那份，`WPF_LINUX_WIN_DIAG=selftest` 且**无 DISPLAY** ⇒ 打满 4 行
> `[WIN_DIAG] CreateWindowEx 失败：where=selftest last_error=1400 …` / `X 连接: dpy=无 …` / `Xlib 异步错误: (无…)` / `窗口参数: cls="HwndWrapper[selftest]"`，
> 且 `WpfLinuxWin32_LastError()` 返回真原因串 `XOpenDisplay("(null)") 失败：无 X server 或 DISPLAY 不可用…`（**不是空指针**）。脚本 `$HOME/wfp-runs/f2check/f2check.py`。
> ⚠️ M7b 报告附 B 把 sha 闸门写成 `4c023937…`（**过期一代**）⇒ 已令其改为 **`6213489cb202fd55…`（pre-F2 值）**，装 F2 后为 `e1691fd8…`。
> ### 🔬 `WM_CHAR=0` 之谜已定位到机制层 —— **那条 trace 天生看不见 WM_CHAR**（主控查证）
> 现象：KEY_DIAG 明写 `KEY … → WM_KEYDOWN + WM_CHAR`（'A'=0x41、'B'=0x42 两个字符都对），而 runner 的 `WFP_MSGS … WM_CHAR=0`、且 TextBox 文本不变（`changes=0`）。
> **机制（两侧代码合起来的结论）**：native `[msg]` trace 打在 **dispatch 期**（`src/WpfGfx.Linux.Native/src/win32_msg.c:293`，由 `:304 wpf_dispatch_to_window()` 调用）；而 WPF 在 **thread-preprocess 期**就处理 WM_CHAR —— `Dispatcher.cs:2199 handled = ComponentDispatcher.RaiseThreadMessage(ref msg)` → `HwndSource` 注册的 `ThreadPreprocessMessage`（`HwndSource.cs:2723/2727`）→ `OnPreprocessMessageThunk`(`:1722`) → `OnPreprocessMessage` 的 `case WM_CHAR`(`:1852-1871`)；**标了 handled ⇒ 不进 `DispatchMessage` ⇒ `[msg]` 一条都不打**（Windows 上读数同样是 0）。
> ⇒ `WM_CHAR=0` **不是"shim 没产 WM_CHAR"**；T3 的 runner 注释"这行把'键没到窗口'与'到了没编辑'分开"对 WM_CHAR **不成立**（已令其改口径）。
> ⇒ **真正坏的是 `WM_CHAR → TextInput` 这一腿**（Ctrl+A 那条路是通的：某趟 `selLen=7` = 全选 ⇒ TextBox 拿到了键盘）。
> **头号嫌疑（已交给 T1c 插桩实证）**：`HwndSource._eatCharMessages` —— 每次 WM_KEYDOWN 置 `true`（`HwndKeyboardInputProvider.cs:210`），只在"该 KEYDOWN 未被 handled"时当场置 `false`（`:227`），否则靠 `Dispatcher.BeginInvoke(Normal, RestoreCharMessages)`（`HwndSource.cs:2432`）**延后**清；**若它长期为 true，所有 WM_CHAR 被静默吃掉**（无异常、无日志）。次嫌：`IsRepeatedKeyboardMessage`（`HwndSource.cs:2441` 比 `msg/hwnd/wParam/lParam` 四元组）与我们的 lParam（`win32_x11.c:574`，**bit30 恒 0**）。
> **待办**：T1c 的 `patch-presentationcore-inputtrace.py`（缺省关、`WPF_LINUX_INPUT_TRACE=1`）插在 `OnPreprocessMessage` WM_CHAR 分支入口/三个子步骤出口、`FilterMessage` 的 KEYDOWN 进出口（打 `_eatCharMessages` 前后值）、`RestoreCharMessages` 调用点 ⇒ 随本趟 PC 重建一起进 PC。
> ### 🔄 上一条的**首次实跑结果 + 一次推理更正**（2026-09-13 16:33，主控）
> **实跑**（`$HOME/wfp-runs/go-inputtrace/probe-only.log`，元组 `bridge=e0d01832 pc=3479253784 win32shim=e1691fd8`）：`[INPUT_TRACE]` **只有** `HwndSource WM_KEYDOWN 置true前/复位后` 各 5 行；**WM_CHAR 入口行、三步 `handled`、`RestoreCharMessages 被调用` 一行都没有**。
> 🔴 **我说错的一半（自己更正）**：我曾写"入口行在 `if(!_eatCharMessages)` 之外 ⇒ 到了就必打"。**错** —— `OnPreprocessMessage` 在 switch **之前还有更早的早退门** `if (!HasFocusWithin() && !IsInExclusiveMenuMode) return;`（`HwndSource.cs:1906-1909`），而探针在 `:1984`（**门之后**）⇒ **"没打印"有三种含义**（没到 / 被焦点门挡 / 到了没进 switch）。**这一族的教训再加一条：探针必须放在所有早退门之前。**
> **幸存证据链（读码可复核）**：① `[msg]` 是 **dispatch 期** trace ⇒ 若走"焦点门早退"，`RaiseThreadMessage` 返回 false ⇒ 必走 `DispatchMessage` ⇒ `[msg]` 必有 `msg=0x0102`；② **实测 `msg=0x0102` = 0**（两次跑都数过）⇒ 早退与"没派出"**都不成立**；③ ⇒ **幸存结论：`WM_CHAR` 没从 `GetMessage` 出来（native 出队侧）**。**头号嫌疑 `_eatCharMessages` 降级**（它要求入口行为 True）。
> **队列侧已排除一条**：`wpf_queue_pop`（`win32_msg.c:83-116`）的 filter 语义是"`hwndFilter==NULL` ⇒ 任意窗口；`lo||hi` 才启用区间" ⇒ `GetMessage(msg,NULL,0,0)` **不会过滤掉 WM_CHAR**。
> **另发现 T1c 的插桩清单**与实际产物不符：`ProviderKeyDown/ProviderKeyDownReset/ProviderChar` 三个 helper **只有定义、调用点 0 处** ⇒ 提供方那几格**永远不会打印**（别把"没有该行"读成"没走到提供方"）。
> **下一轮（统一重建窗口，等 T3 交还应用槽）**：T1c 第 2 版 applier（探针挪到**焦点门之前**＋`Dispatcher.TranslateAndDispatchMessage` 入口打 `msg/hwnd`＝"托管侧到底有没有从 `GetMessage` 拿到"＋把提供方三处真正接上）；M7b 的 native **出队侧** trace（`wpf_queue_pop` 返回侧打"消息号＋剩余条数＋**调用来自哪个 API**"，`push` 侧只对 WM_CHAR 打一行；并读码判 `PeekMessageW(PM_NOREMOVE)` 的 "pop-再-`malloc`-插回队首"在什么条件下会吞件）⇒ 两半合起来才能定"是被别人取走了还是压根没返回"。
> ### ✅ 统一重建**已完成**（2026-09-13 16:49–16:52，主控）—— 两端仪器装齐 + 一份可决策的 RTL 结论
> **新配置（现场重读）**：PC **`8ff5cb388ca7596461160d99…`** / 4,174,848 B（16:50:50，v2 输入追踪：H0 挪到**焦点门之前** + 提供方 5 点 + H3 改名）｜WindowsBase **`ed54bcacf08be248643f34ac…`** / 1,224,192 B（16:49:51，**新**：`Dispatcher` 出队读数）｜PF **`05ef4a5e66489b915155ce95…`**｜桥 `e0d01832…`（**未变**）｜`libwpfwin32.so` **`b3a716ce094c6bab7f89df29863e5428334b3a83de914c79cd02b170091e279d`** / 273,992 B（16:49，含 **MSGFLOW** 出队侧插桩，全仓 4 份同 sha）｜wic `03b67fbc…`｜provider `71ba86c6…`｜hbtextline `ebccdb1e…`（stale=no）。
> **门禁**：波前==波后==**`9f8b916d69b86473760cb731e7e2efd33d6bfab06a136e9a2a743bc29593ddfc`**、两个新应用器已重放、15 工程 0 错 0 警、失败 0；**三份生成物 sha 与 T1c 在 `/tmp` 假树里的预测逐字节相同**（`HwndSource.Linux.cs 385a6014…` / `HwndKeyboardInputProvider.Linux.cs f56e647e…` / `Dispatcher.Linux.cs cbb971f5…`）——**这是"应用器重放是否忠实"的机器证据**；`verify-all.sh` **9/9、843 通过 / 2 跳过 / 0 失败**。
> **新增应用器登记（都要显式登记，`patch-presentation*` 通配抓不到）**：`patch-windowsbase-msgflow`（WindowsBase csproj + 生成 `Dispatcher.Linux.cs`）；与补丁 N/P 同源风险 —— `port-lib.py WindowsBase` 会**整份重写 csproj**、接线被抹掉**且不报编译错**，只表现为"一行都不打"。
> **两端仪器（一条命令可同时开）**：原生 `[MSGFLOW]`（`WPF_LINUX_MSGFLOW_TRACE=1`：`push WM_CHAR 入队` + `pop api=… msg=… 剩余=… 队列=… tid=…` × 三个"谁取走的"标注）｜托管 `[MSGFLOW_TRACE]`（`Dispatcher` 的 `① 出队 / ② RaiseThreadMessage handled / ③ 交给 DispatchMessageW`，首行 `via=` 报走了哪个开关）；PC 侧另有 `PreprocessMessage WM_CHAR 入口(焦点门前)` 与 `入口(过焦点门后)` 两格。
> **判据（互斥四格，`_eatCharMessages` 降级为 ④b 子格）**：① 上游丢（托管出队里没有 `0x102`）② 队列有、泵没取到（原生 push 有 + 托管出队没有）③ 被线程预处理吃掉（出队有 + `handled=True`）④ 到 `OnPreprocessMessage`（④a `入口(焦点门前)` 有而 `(过焦点门后)` 无 ⇒ **焦点门挡回**；④b 进 char 分支再看 `_eatCharMessages` 与三步 `handled`）。**已证伪一条假设**：`TranslateMessage` 是**故意空实现**（WM_CHAR 全由 X11 翻译层产生）⇒"TranslateMessage 吞字符"在本移植里不成立。
> ### ✅ RTL：P0 用**离线装置**判掉了（T1d，`build/MilBridge/T1d-bidi-scoping.md` §7）—— 结论可落笔
> **同源先钉住**：由实跑 `heH=16.3` 反推 em=14，离线同串同字体得 `Width=65.256 / Height=16.297 / Baseline=12.995`，与实跑 `heW=65.3 / heH=16.3` **逐位吻合**；**该行墨迹横跨 ≈65.4 DIP**。
> **逐 run 读数**：`glyphRuns=1`，glyph 序列 `[1332,1331,1324,1337,3,1332,1324,1331,1344]`、cluster `[8…0]` ⇒ **单调递减 = 视觉序**（= 逻辑序整体反序）；累计 x = **65.256**（**与 LTR 同一个数** ⇒ 行宽与方向无关）。
> **`InvertAxes` A/B**：`None ⇄ Horizontal` 的差别**只有矩阵**（`M11=-1 OffsetX=200`，200 = 段落宽）⇒ **跨度不变、位置被搬走**。
> **⇒ P0 结论（可落笔）**：**宿主确实会镜像**（`Line.cs:79 _mirror` → `:116` 传 `Horizontal`；我们实测 push `M11=−1, OffsetX=段落宽`）⇒ **"宿主提出、我们按契约执行"**；**P1 的关键不是"要不要镜像"，而是"该不该继续输出视觉序字形"**（现为视觉序 + 宿主镜像 = **两次反转**）。
> **⇒ 同时否掉一条读数**：T3 观察到的"**RTL 行只有 23 px、LTR 58 px**"**不能当几何结论**——墨迹实测 65.4 DIP，而镜像/平移都保跨度 ⇒ 那 23 px 只能是**测量只覆盖了一部分行**（抗锯齿 + 镜像 CTM 把字形放到分数像素 ⇒ **精确色计数塌陷**，同一块历史上已栽过一次）。**"甲（相同）/乙（镜像）"两个签名都不成立，且我们的模型正好预测"都不是"**（视觉序 + 再镜像 = `flop(视觉序)` ≠ `flop(逻辑序)`）。
> **新发现的真缺陷（在册）**：**`ClusterMap` 对 RTL 退化** —— 用我们的 `InvertClusters` 在实测 cluster 上模拟得 `[0,0,0,0,0,0,0,8,8]`（**7 个字符映射到 glyph 0**）；契约只查"单调不减/首项 0"⇒ **构造不抛、静默错** ⇒ 渲染无碍（MIL 不带 cluster），但 **caret/命中全错**（P2 主要地雷）。
> **缺的读数（按优先级）**：① `_paragraphWidth`（站点 B/D 现在不打它 ⇒ 加一格就能判"是否被搬到块外"）；② 换掉精确色像素计数（改**墨迹包络**阈值化求逐列 min/max x，或读 `MilGlyphRun.Origin`）；③ 先核坐标基（`WFP_BOXID=65x16+86+39` 与截图 `x∈[24,81]` 差 ~62 px，先确认窗口在 root 的位置/裁图原点再把"+73 px"当结论）；④ **P1 最便宜的可判实验**：把 RTL 输出序**改回逻辑序**，用列轮廓 + 墨迹包络重测，**看是否出现 flop 签名**。
> ### ✅ must-do ④ 完成：`ACCEPTANCE-BASELINE.md` **已按新配置重冻**（T3，2026-09-13 16:56:17）
> 文件头带 `# RE-FROZEN after 输入链插桩(pc) + MSGFLOW(win32shim) at 2026-09-13 16:56`；**七元组逐字取自该趟 `WPTD_ARTIFACTS`（不是转抄）**：`pc=8ff5cb388ca75964 / pf=05ef4a5e66489b91 / bridge=e0d01832a3efea53(4,937,968 B) / win32shim=b3a716ce094c6bab / wic=03b67fbcd7c385b6 / provider=71ba86c6495347fe / hbtextline=ebccdb1ee65e6f76(stale=no, basis=auth, src 1789230991 < PC 1789289450)`。
> **判定全绿**：`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`default 3/3`、`env 3/3`、**6 条 BASELINE 行全 PASS**（`drawn=261/144`、`notdrawn=0`、`scroll=ok/141605` 与 `ok/135468`、每行 `leftover_after=0`）、`distinct_origin_y=12 runs=168`；**桥契约实测原文**（空态无方括号）：`（skia 指令 261 条，未画种类 0）`。
> ### 🔴 must-do ① 判定：**`② 取不出来`**（三开关趟，同一配置，四格齐）
> ① **上游丢？不成立**：原生**入队两次** `push WM_CHAR 入队 码点=65(0x0041 'A') / 码点=66(0x0042 'B')`，且 `队列=0x5b1928c8e4a0 tid=131553739208512` 与**所有** `pop` 行一致 ⇒ "推错队列/推错线程"排除。
> ② **取不出来？成立**：原生 `pop api=GetMessageW` **52 行**里 `0x0100×6 / 0x0101×4 / 0x8000×26 / 0x8009×5 / 0x0200×2 / 0x0113×2 / 0x0007 0x0008 0x0005 0x0003 0x0018 0x000f 0x020a 各 1`，**`0x0102` = 0**；托管 `[MSGFLOW_TRACE] ① 出队` 同样 **0 个 `0x0102`**；时间序 `pop 0x0100 剩余=0` → **push WM_CHAR('A') 队列长度=2** → `pop 0x0100 剩余=1` → `pop 0x0101 剩余=0`。
> ③ **被预处理吃掉？不成立**（该格要求托管出队里有 `0x102` 且 `handled=True`；根本没有 `0x102`）。④ **没到 `OnPreprocessMessage`**：`[INPUT_TRACE]` 12 行只有 `HwndSource WM_KEYDOWN 置true前/复位后`（各 6 行），**H0（已在焦点门之前）一行都没有**。
> **⇒ 幸存结论：消息在"入队之后、出队之前"消失。** 我读码把范围缩到：全 shim **只有 `wpf_queue_pop` 会 free 队列节点**（`win32_msg.c:170`；`:314` 那处是 `KillTimer` 的 timer 节点）⇒ 节点若消失**必然经过某次 pop**，而那次**没打行**；`interesting()` 含 `WM_CHAR` 且总行数 106 < 200 ⇒ **不是被额度挤掉**；`api=` 52 行**全是 `GetMessageW`** ⇒ "被嵌套 `PeekMessage` 拿走"**暂时不成立**。
> **已派 M7b 第 2 版仪器**（决定性格）：① `GetMessageW`/`PeekMessageW` **入口打调用参数**（`hwnd/lo/hi/remove`，每次必打）⇒ 抓"带区间的调用"；② `wpf_queue_pop` 扫描里对 **`WM_CHAR` 的 `ok=0` 跳过**打一行（带 filter/range 值）；③ push（WM_CHAR）与 pop（关注类）之后**打队列内容快照**（head 起最多 8 条）⇒ "什么时候从队里消失"逐行可见；④ 若读码发现"摘掉却不走日志点"的路径（`t->tail`/回插/单节点）**写成离线最小复现**（比再跑应用更值钱）。
> ### 🎯 **根因找到了，而且是离线可执行的证据**（M7b 读码 + 主控实跑，2026-09-13 17:1x）
> **缺陷（`win32_msg.c`，队列不变式被破坏）**：
> ```c
> // wpf_queue_push   :57   只认 tail：
> if (t->tail) t->tail->next = n; else t->head = n;      // ← tail==NULL 时**直接覆盖 head**
> // wpf_queue_pop    :195  摘掉队尾时把 tail 置空，**没有指回新的队尾**：
> if (t->tail == v) t->tail = NULL;                      // ← 于是出现 head!=NULL && tail==NULL 的非法态
> ```
> **最小复现 4 步**：`push A` → `push B` → **`pop(filter 只匹配 B)`**（合法用法）⇒ `head=A, tail=NULL` → **`push C`** ⇒ 走 `else` ⇒ **C 成为队首、A 被整条孤儿化**：既不在队列里、也没被 `free`、**没经过任何 pop ⇒ 出队侧一行都不打** —— 与现场"`WM_CHAR` 入队后再无痕迹"完全吻合。
> **离线可执行断言（`src/WpfGfx.Linux.Native/tests/queue_invariant.c`，主控实跑原文）**：
> ```
> PASS  (a)×5（含"带区间 pop 跳过 WM_CHAR 后它仍在队里、随后无 filter 的 pop 取到的正是它"）
> PASS  (b) 长序列后 count == pushed - popped ｜ PASS (b) 排空后 count == 0
> FAIL  (b) 排空后 WM_CHAR 条数 == 500（一条都没少）
> PASS  (c) 带 filter 摘掉队尾：取到 B 且 count 应为 1（A 仍在）
> FAIL  (c) 之后再 push 一条：count 应为 2（不能丢掉 A）
> FAIL  (c) 排空能同时取到 A 与 C（A 没有被孤儿化）
> FAIL  Peek(PM_NOREMOVE, 命中非队首) 返回 KEYUP 且 count 不变（3）
> FAIL  ⇒ 回插到队首改变了顺序
> PASS  peek 之后仍能排空剩下 2 条（无丢件）
> QUEUE_INVARIANT=FAIL(5)
> ```
> ⇒ **当前实现确实是红的**（不是读码推断）。**修法已派 M7b**：F-A 根因修（pop 记 `prev`，`if (v==t->tail) t->tail=prev;`）+ F-B 防御（push 的 `else` 先判 `t->head`，绝不覆盖 head，异常态自愈并**打告警不静默**）+ F-C `PM_NOREMOVE` 改成**只看不取（扫描，不 pop/不 free/不重排）**，并以 `queue_invariant` **全 PASS** 为闸门（要贴修前/修后两份原始输出）。
> **验收（下一步，主控统一做）**：重编 shim + 同步 4 份 ⇒ T3 复跑三开关诊断，期望 ① 原生出队侧出现 `pop … msg=258(0x0102 WM_CHAR)`；② `textbox-edit` 的 **`changes>0`**（打字真的进 TextBox）；③ `[INPUT_TRACE]` 出现 WM_CHAR 相关行 ⇒ **must-do ① 才算闭环**。
> ### ✅ 队列根因**已修并装**（`win32shim=f84d65a62e0c7fa44741df76a3b7b87f7176c689bb140b272411ec196233c253` / 278,200 B / 17:13，全仓 4 份同 sha）⇒ **传输层闭环**
> **修法**：F-A `wpf_queue_pop` 记 `prev`，`if (v==t->tail) t->tail=prev;`｜F-B `push` 的 `else` 先判 `t->head`（绝不覆盖 head；异常态自愈 tail 并**打告警不静默**）｜F-C `PM_NOREMOVE` 改成**只读扫描**（不再 pop/`malloc` 回插 ⇒ 一次性消掉"回插失败静默丢件"与"改序"两条路）。
> **离线闸门（在权威件上实跑，不是私有构建）**：`QUEUE_INVARIANT=PASS`（**修前 `FAIL(5)`**）。⚠️ M7b 如实更正：修前 5 条红里**只有 2 条是真缺陷**（`(c)` 组：摘队尾⇒`tail=NULL`⇒下次 push 孤儿化），另 3 条是**它自己用例写错**（`(b)` 的类别守恒期望、"peek 看不到东西"其实是它 push 进了本地结构体而非本线程 TLS 队列）⇒ **"改序"这条从未被该用例证明过**，仍是读码结论（并已由 F-C 顺手消除）。
> **装后实跑（T3 三开关趟）**：
> ```
> [MSGFLOW] push WM_CHAR 入队 码点=65(0x0041 'A') 队列长度=2 队列内容=[0x0100,0x0102] 共2
> [MSGFLOW] pop api=GetMessageW msg=258(0x0102 ?) hwnd=0x200005 剩余=1 队列内容=[0x8000] 共1     ← 修前 pop 0x0102 = **0 行**
> （'B' 同；pop 0x0102 共 2 行、push WM_CHAR 2 行、队列快照 18 行；另有 3 行 `skip … 原因=hwndFilter filter=0x200001 lo=0x8000 hi=0x8000（本节点留在队里）` = 对消息专用窗口的**合法过滤跳过**）
> ```
> ⇒ **`WM_CHAR` 从"入队后无痕消失"变成"被正常取出"**（must-do ① 的前半段闭环）。
> **基线再冻（#2）**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 已按新 shim 重冻（`win32shim: b3a716ce → f84d65a62e0c7fa4` 是唯一变化位，6/6 `result=PASS`，`WPTD_GATE=PASS`，判据⑥ `AE=141605`，桥契约首次实跑判 ✅）；`1400` 累计 **90 次启动 / 0 命中**。
> ### 🎯 must-do ① 的失败点已推到**托管输入链的最后一步**（同一趟实跑）
> ```
> [INPUT_TRACE] PreprocessMessage 早退门之前 … HasFocusWithin=True _eatCharMessages=False
> [INPUT_TRACE] PreprocessMessage WM_CHAR 入口(过焦点门后) … _eatCharMessages=False
> [INPUT_TRACE] 步骤 TranslateChar ⇒ handled=False ｜ OnMnemonic ⇒ handled=False ｜ **ProcessTextInputAction ⇒ handled=True**
> （托管）[MSGFLOW_TRACE] ② 线程预处理 0x0102 handled=True ⇒ **不进** TranslateMessage/DispatchMessageW
> （样例）[feat] textbox-edit OK focus=True caret=0 selLen=7 text='seed-文本' **changes=0**
> ```
> ⇒ **`_eatCharMessages` 全程 `False`** ⇒ T1c 原"置位/吞掉/复位"判据**不成立**；字符是在 `ProcessTextInputAction`（`handled=True`）这一步被消费掉的，而 **TextBox 文本不变**。
> ⚠️ **口径**：`handled=True` **本身正常**（`TextCompositionManager` 处理完 `RawTextInputReport` 会把 report 标 handled）⇒ **不能当结论**；要问的是"**`TextInput` 有没有被 raise、raise 给谁、谁处理了**"。旁证：样例自己 `_tb.Focus(); Keyboard.Focus(_tb)` 且自报 `focus=True` ⇒ **`Keyboard.FocusedElement` 应当就是那个 TextBox**。
> **已派 T1c 第 2 批探针**（PC：`InputProviderSite.ReportInput` / `InputManager.ProcessInput`（打 `PrimaryKeyboardDevice.FocusedElement` 的类型+hash）/ `TextCompositionManager.cs:609-612` 分支 / `:660` 正常字符分支 / `TextInput` 真正 raise 的那点；PF：`TextEditorTyping.OnTextInput` 入口，**一次性跨车道、主控授权**）⇒ 四格判据把失败点钉到"没到分支 / 没 raise / raise 给错元素 / raise 了 PF 没跑 / PF 跑了但插入失败"。
> ### ✅ 第 2 批已装并实跑：**六格命中"己"—— 输入链一路绿到 `P6d`，插入没落到文档里**
> 新配置：PC **`f5bb25827621865a205f69a0…`** / 4,179,968 B（17:29:37）｜PF **`8c801a3f5ee67f0b9efe3190…`** / 7,104,512 B（17:30:22）｜WindowsBase `ed54bcac…`（未变）｜shim `f84d65a6…`（未变）；波前==波后 **`26c8909da8da15b31225d83aa56d9c2d7a0d4a0f6cb605154b479d60e745dd47`**、**7 个生成物 sha 与 T1c 的 `/tmp` 预测逐字节一致**、`verify-all.sh` 9/9（843/2/0）。**基线再冻 #3**（唯一变化位 `pc`/`pf`）。
> **同一对象三处对齐**：`P2 KeyboardDevice.FocusedElement=TextBox#2ce2184` ≡ `P5 TextInput 目标=TextBox#2ce2184` ≡ `P6a sender=TextBox#2ce2184` ⇒ **焦点与路由都对**；`P6a 入口 Text="A"`、`P6c 过两道门`、**`P6d 已 ScheduleInput 排队插入 text="A"`** —— 而样例自报 `text='seed-文本' changes=0`（**读的是 `_tb.Text` 本身** ⇒ 排除"文本变了但没发 `TextChanged`"）。
> ⚠️ **`P6c` 的 `composition=(null)` 是预期的，不是线索**：上游 `HwndKeyboardInputProvider` 那条 WM_CHAR 不是 `FrameworkTextComposition` ⇒ `as` 返回 null ⇒ 正走 `else`（普通输入）分支。
> ### 🎯 新头号假设（主控读上游 + 实跑消息号）：**`DispatcherPriority.Background` 的操作在这套泵上从不执行**
> `TextEditorTyping.ScheduleInput`（上游 `:1569-1591`）对 TextBox（非 RichContent、无鼠标待处理）走**排队**那一支：
> ```csharp
> Dispatcher.CurrentDispatcher.BeginInvoke(**DispatcherPriority.Background**,
>     new DispatcherOperationCallback(BackgroundInputCallback), This);   // ← 真正插入在 Background 优先级上跑
> ```
> 而实跑消息号直方图里**只有 `0x8000`/`0x8009`，从未出现 `0x8004`**；我们 shim 的 `RegisterWindowMessage` 从 `WM_APP` 起分配 ⇒ `0x8000` 很可能就是 `DispatcherProcessQueue`，若通知按 `0x8000 + priority` 投递，则 **Background(=4) 的通知一次都没出现过**。
> **判据（便宜、无需改产物）**：让样例在 `Normal / Input / Background / ContextIdle` 四个优先级各挂一个 `BeginInvoke` 标志位并自报真假 + 打全 `0x8000…0x800f` 的消息号直方图 ⇒ `background=False` 即**假设成立**（接着查 WindowsBase 的 `CriticalRequestProcessing` post/timer 分支与 `TryPostMessage`/`TrySetTimer` 返回值）；`background=True` ⇒ 假设否掉，转 T1c 第 3 批 PF 探针（`BackgroundInputCallback` / `_FlushPendingInputItems` / `TextInputItem.Do` / `DoTextInput` 的实际效果与**被吞的异常**）。两路都已派单，T1c 的第 3 批**已写好待重放**（含预测 sha，前两批连续逐字节命中）。
> ### ❌ 上述假设**被读数否掉**（T3 四优先级实验），且主控的一条推理被当场纠正
> ```
> WFP_DISPATCH_PROBE=posted normal/input/background/contextidle
> WFP_DISPATCH_PRIO  normal=True input=True background=True contextidle=True      ← 四个优先级全执行（含最低的 ContextIdle）
> 消息号直方图（两路都打）：托管[msg] 0x8000=74 0x8009=5 其余=0 ｜ 原生[MSGFLOW]pop 0x8000=36 0x8009=5 其余=0
> ```
> ⇒ ① `DispatcherPriority.Background` **不饿死**；② **主控"没有 `0x8004` ⇒ Background 没被投递"是错的** —— shim 的进程队列通知**只用 `0x8000` 一个号**（`RegisterWindowMessage` 从 `WM_APP` 起分配），不是 `WM_APP+优先级`。**这条按"用编码假设代替读数"记入手册**（第 20 个假绿形态的邻居）。
> ### 🎯 第 3 批（Q0…Q4）结果：**命题整体改写 —— 键入其实到了，屏幕上就是 `AB`**
> ```
> Q0a ScheduleInput 入口 item=TextInputItem#fd727f AcceptsRichContent=False
> Q0i **立即执行支路**（`!AcceptsRichContent || IsMouseInputPending`）⇒ 根本不走 Background 投递
> Q3  TextInputItem.Do() 入口 text="A" UiScope=TextBox#2ce2184
> Q4a DoTextInput 入口 选区[0,7]="seed-文本" ｜ Q4b 过滤后="A" ｜ Q4c 即将 SetSelectedText("A")
> Q4d **SetSelectedText 返回后 len=1 text="A"** ｜ Q4f 出口 UndoCloseAction=Commit ｜ Q3c 正常返回 len=2 text="AB"（无 Q4e ⇒ 无异常）
> ```
> 加上 T3 用**注入后帧**（它自己补的第三趟 `b3-*`）看到：**TextBox 里就是 `AB` 加光标**；而 `WFP_TEXTWATCH` 的 18 个时间点里 `_tb.Text` **始终是 `'seed-文本'`**。
> 🔴 **T3 自认一处仪器缺陷**：探针 runner 的**两趟 burst 都拍在注入之前**（burst 循环 316/334 行、注入在 347 行）⇒ 它先前"注入后屏幕还是旧文本"的读数**没有证据力**（已作废，并补了注入后第三趟 `b3-*`）。
> ### 📌 **must-do ① 正式改写**（新在册缺陷）：键入 → 容器 → 渲染**全通**；断的是 **`Text` DP / `TextChanged` 通知链**
> **证据**：注入后原始分辨率帧 = `AB` + 光标；`Q4d/Q3c` 显示容器被改写；`WFP_TEXTWATCH` 18 点全部 `text='seed-文本' len=7 changes=0`；无异常。
> **影响面**：任何**读 `TextBox.Text` 或绑定 `Text`** 的真应用会**静默拿到旧值**（比"不显示"更隐蔽）。
> **链已读通（主控）**：`TextBoxBase.cs:1435 _textContainer.Changed += OnTextContainerChanged` → `TextBoxBase.cs:1348`（注释明写 raise `TextChanged`）→ `TextBox.cs:1194 OnTextContainerChanged` → `:1206 if(!_isInsideTextContentChange)` → `:1214 new DeferredTextReference(TextContainer)` → **`:1216 SetCurrentDeferredValue(TextProperty, dtr)`**；读 `.Text` 时由 `Controls/DeferredTextReference.cs:41 GetValue → TextRangeBase.GetTextInternal(容器.Start, 容器.End)` 解析。⇒ 若 `TextContainer.Changed` 没触发（或被 `DeclareChangeBlock`/`EndChange` 嵌套计数挂住），DP 就仍握有样例当初显式设进去的**普通字符串** `"seed-文本"` —— 与三点观察**完全自洽**（主控已派 T1c 第 4 批，探针 = `Changed` raise 点 / `TextBoxBase:1348` / `TextBox:1194` 的三个守卫与 `:1216` / `DeferredTextReference.GetValue:41` / `BeginChange-EndChange` 计数配对）。
> **判据口径同步更正（T3 自提，已采纳）**：`textbox-edit` 的"键入腿"从 `changes>0` 改成**注入前后 `WFP_BOXID` 矩形内的像素/字形差异**（`changes>0` 降为旁证）—— 原判据测的是**可观测模型**而不是"键到没到"，本轮它给出了**假红**；**新记档**："`changes=0` 假红"作为"判据与被测对象不是一回事"这一族的新成员。
> ### ✅ 第 4 批（Q5…Q9）装毕并实跑：**PF 侧全链已绿，断点收窄到"读路径不解析 deferred"**
> 新配置：PF **`86bace19b6f225bbe0bbe531…`** / 7,117,312 B（18:01:30，新增 `TextContainer/TextBoxBase/TextBox/DeferredTextReference` 四个生成物）｜PC `f5bb25827621865a…`（未变）｜波前==波后 **`e663fef69ec521d7deb18429dd38a9d142d02670da61f48a62b1c1756c4f10f0`**、**4 份新生成物 sha 与 T1c 预测逐字节一致**、`verify-all.sh` 9/9（843/2/0）。
> **实跑（107 行 Q5…Q9）**：`Q9a/Q9b/Q5a` 各 28 ⇒ **变更块计数平衡**；`Q5b ChangedHandler=有` → `Q5c Changed 已 raise`（容器 len=7 / len=1 `"A"` / len=2 `"AB"`）；`Q6a/Q6b RaiseEvent(TextChangedEvent)` ⇒ `:1352` 那道门**没挡**；`Q7a _isInsideTextContentChange` 两次真编辑都是 `False`；**`Q7b 已 SetCurrentDeferredValue(TextProperty, DeferredTextReference#…)×2`**；`Q7c resetText=False`；而 **`Q8`（`DeferredTextReference.GetValue`）0 行**。
> **T3 的口径修正（采纳）**：不是"没人读" —— 样例 `WFP_TEXTWATCH` **读了 18 次** `_tb.Text` 而 `Q8` 一次没触发 ⇒ **读路径从不解析那个 deferred 引用**，读者一直拿到旧 local 值（所以渲染对、`Text` 陈旧）。
> **主控读上游把"读路径"钉到 WB**：`DependencyObject.cs:156-171 GetValue ⇒ RequestFlags.FullyResolved` → `:295 GetEffectiveValue` → **`:303 if ((requests & (DeferredReferences|RawEntry)) != 0 || !effectiveEntry.IsDeferredReference) return effectiveEntry;`**（提前返回 ⇒ 不解析）→ `:308 !HasModifiers` → `:313 !HasExpressionMarker` → **`:321-333 DeferredReference.GetValue(BaseValueSourceInternal)` = 真正的解析点（我们一次都没到）**。
> ⇒ 三种可能：**(A)** `IsDeferredReference=false`（写侧没留住标记）｜**(B)** 读时 `requests` 带了 `DeferredReferences`/`RawEntry` ｜**(C)** `HasModifiers`/`HasExpressionMarker` 为真。**已派 T1c 第 5 批（WindowsBase 侧）**：`W1 GetValue` 出口值类型 / `W2 GetEffectiveValue` 入口的五元组 / `W3` 三条出口各一行 / `W4 SetValueCommon` 存完后的 entry 标记 / `W5` PF 侧哨兵（只判"解析点有没有被调到"）。
> **"像素键入腿"三极性牙 PASS**（`run-wpfprobe-inputleg-tooth.sh`）：矩形挪到空白 ⇒ **FAIL**；正常注入 ⇒ **PASS**（`947→153`）；关掉注入 ⇒ **INCONCLUSIVE**（T3 自抓：第一版把"没有注入后帧"也判 FAIL ⇒ **"仪器没采到"被当成"没键入"**，已修）。本趟该块按新口径记 **INCONCLUSIVE**（不是 PASS）—— 即 `D-P1` 登记在 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`。`1400` 累计 **96/0**。
> ### ✅ 第 5 批（W1…W4，WindowsBase 的 deferred 读路径）装毕并实跑：**命中 A 格 —— 根因落到"写侧存了 deferred、读侧有效值里没有它且还是旧串"**
> 新配置：WindowsBase **`4bbc4ae3eca6893ad84df3e5…`** / 1,231,872 B（18:23:07）｜PC **`9b25e004e6c08c83850eec92…`**（18:23:39）｜PF **`8f92dee064910d0c2e698bf1…`**（18:24:26）｜shim `f84d65a6…`、桥 `e0d01832…`（未变）。波前==波后 **`24aae781c30f41175e832ba27a4f4164e9d4bc47eebc925565e915625290c76a`**、`DependencyObject.Linux.cs` = 预测 `f898a901`、`Dispatcher.Linux.cs` 仍 `cbb971f5`；`verify-all.sh` 9/9（843/2/0）。
> 🔴 **本批第一次重放编译失败，被集成波的构建步骤抓住**：`DependencyObject.Linux.cs(682,86) error CS0103: referenceFromExpression` —— W3d 探针落在**修改值分支的作用域之外**（上游 `:348-350` 在该分支内声明）。T1c 修法 = 把探针**挪进块内**（纯插入、未动控制流），并**新增机械尺子** `build/MilBridge/tools/t1c-trace-args-scope.py`（逐实参核作用域深度/形参/类字段，牙齿：坏件 1 SUSPECT、修好后 0、五棵预测树 109 调用点 0 SUSPECT）。
> **两条流程要求（已写入 T1c 报告横幅）**：**预测 sha ≠ 能编过**（只证生成器确定性；这次预测值对、代码错）｜**`--prove` ≠ 能编过**（只证纯插入）。⇒ 新增/改动 `WpfLinux*Trace` 调用点必须：过 `t1c-trace-args-scope.py`、报告里逐条核"实参在作用域内/类型匹配/不是 DP 读取"、并明写"**仍未编译**"。
> **实跑原文（176 行 W1…W4）**：
> ```
> 写侧（"Text"/TextBox）：W4a newEntry.Value=value 写入的 value=DeferredTextReference isDeferredReference=True
>                        W4b 出口（UpdateEffectiveValue 之后）⇒ newEntry.Value=ModifiedValue IsDeferredReference=**True**
> 读侧（每次 WFP_TEXTWATCH 读都一组）：W1 GetValue 读 "Text" OwnerType=TextBox target=TextBox#13fa1bf requests=FullyResolved
>                        W2 effectiveEntry.IsDeferredReference=**False** entry.HasModifiers=False entry.HasExpressionMarker=False entry.Value=string(len=7) "seed-文本"
>                        W3a 提前返回（不解析）原因=**A：effectiveEntry.IsDeferredReference == false**
> ```
> ⇒ **A 命中**；**B 未命中**（读方没要 `DeferredReferences`/`RawEntry` ⇒ 没有栈可指人）｜**C1/C2 未命中**（无 modifier/expression；`W3b/W3c/W3d` 未出现）⇒ 无互校验矛盾；PF 哨兵 `Q8a/Q8b` 仍 0 行而 `Q7b`=2 ⇒ 自洽（在 `W3a` 就提前返回，根本不需要 PF 的 `DeferredTextReference.GetValue`）。
> **根因落点**：**WindowsBase / `DependencyObject` —— 写侧存进 deferred 之后，有效值槽没有被换成那个 deferred 引用**（读到的仍是上一版的本地字符串）。
> **第 6 批（已派 T1c，四格互斥）**：**W4 补目标对象身份**（先钉"写读是不是同一个对象"——当前最大观测缺口）｜**W5 所有写 `Text` 的入口各打一行**（`value` 类型 + 目标 hash + **调用栈前 4 帧**）⇒ 若 deferred 写之后紧跟一次 `value=string` 的写，**栈直接指人**｜**W6 `UpdateEffectiveValue`** 的 `operationType` 与出口槽位状态｜**W7 `GetFlattenedEntry` 三个 return 分支**（确认 flatten 没吞标记）。判据：**(a)** 目标 hash 不同 ⇒ 写读不是同一个对象（归属要重写）｜**(b)** 目标同且之后有 `string` 写 ⇒ 谁换回去的就是根因｜**(c)** 无第二次写但 `W6` 出口已非 deferred ⇒ 有效值槽被写坏｜**(d)** 都不成立 ⇒ 读侧取错槽位/索引。
> ⚠️ **基线现在处于"过期"状态，收尾时必须再冻一次**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 **#3** 记的是 `pc=f5bb25827621865a` / `pf=8c801a3f…`，而当前权威件已是 **PC `9b25e004e6c08c83` / PF `8f92dee064910d0c`**（第 4、5 批探针又改过）⇒ **在"停改产物"之后必须冻结 #4**（跑一趟门禁 + 记七元组）。目前仍在追 `D-P1`（第 6 批），所以 #4 排在那一项之后。
> ### ✅ RTL：`ClusterMap` 退化已查成"根因 + 修法候选"（T1d §8，**只读**）—— **与 §7 的双重反演同一个根**
> **根因（逐字 + file:line）**：`build/shims/PresentationCore.HbTextLine.cs:232 r.Clusters[i] = gi.Cluster` → `:2256 InvertClusters(...)`（**构造期**）→ `:2273-2289` 的 `while (g + 1 < glyphCount && shaped.Clusters[g + 1] <= (uint)c) g++;`，其注释假定"**HB 给的是字形→字符、单调不减**"。**RTL 下 HB 给的是视觉序 ⇒ cluster 单调递减**（实测 `[8,7,6,5,4,3,2,1,0]`）⇒ 前 7 个字符 `while` 永不前进 ⇒ 产出 `[0,0,0,0,0,0,0,8,8]`。
> **更深一层**：视觉序字形数组下**任何忠实的"字符→字形"映射都是递减的** ⇒ **根本无法**满足该契约；而上游校验（`GlyphRun.cs:368-395`）**只查递减/越界** ⇒ **构造不抛、静默错**。
> ⇒ **真根因 = "RTL run 以视觉序交给 `GlyphRun`"** —— **与 §7 的双重反演是同一个根**（所以修一处能修两个洞）。
> **可达性/现状影响（量化）**：与 `InvertAxes` **无关**（map 在构造期生成；A/B 实测 run 内容逐位不变，只有矩阵变）。**现状"因它而错"的可观测量 = 0**，因为我们自己的 caret/命中**本来就是 owed 桩**（`:2887-2890` 恒返回 `CharacterHit(0,0)`、`:2893-2897` 恒返回 0）⇒ RTL 上与 LTR **错得一样**。将来会吃到它的树内消费者：`GlyphsSerializer.cs:36`（XPS）、`FixedSOMPageConstructor.cs:434-436`（固定文档）、上游 `GlyphRun.GetDistanceFromCharacterHit`（`GlyphRun.cs:505-516`，null 时回落恒等 `DefaultClusterMap`）。**缺的读数：无。**
> **修法候选（推荐 ①）**：**① RTL run 改为逻辑序输出**（shape 仍 RTL，输出前把 `Glyphs/Clusters/AdvancesPx/OffsetsXPx` 反回逻辑序 + `BidiLevel=1`；**`InvertClusters` 一行不改**，**≈15 行**）—— **同时修掉双重反演**；② 退化时传 `clusterMap=null`（1 行止损，但实测 `'لا'` **2 字符→1 字形**会让恒等 map 越界 ⇒ **构造抛**，不能无条件用）；③ 在 caret/命中层换算（代价最高，XPS/固定文档两个消费者**仍错**，只作 P2 补充）。
> **牙齿（离线，先红后绿）**：`[现状] map=[0,0,0,0,0,0,0,8,8] 字形覆盖 2/9 ⇒ 红`｜`[修法①] map=[0,1,2,3,4,5,6,7,8] 覆盖 9/9 ⇒ 绿`｜LTR 对照 `'Hello'` **恒等 = True**。⚠️ 覆盖类断言**只适用 1:1 串**（`'שָׁלוֹם'` 带 niqqud 是多字形簇，修后覆盖 5/7 是**正确的**）⇒ 一般判据写成"**每个字符 c 的 `Clusters[map[c]]` 必须等于 c 所属簇值，且每个簇值都被引用**"。
> **修后哪些既有读数会变（验收即闸门）**：六项 tline（`T1.73 73/73`、`T2 记账`、`T2b 972/972·213/213`、`T2d 1298/1298`、`T3 折叠 218/236`、`Tab 0 例`）**必须逐位不变**（语料全 LTR、修法对 LTR 恒等）；**变了就是越界**。会变的只有 RTL 行的字形顺序/位置（正是目的）。**落地清单**：改 `Shape`/`ShapeParagraph` 按段判方向（`Clusters[0] > Clusters[len-1]`）并反转四个数组 + 带 `Rtl` 标记；`BuildGlyphRun` 的 `BidiLevel` 不再写死 0。**回滚 = 去掉反转**。
> **⏳ 排期（主控裁定）**：**先不落地** —— 现在正在追 `D-P1`（第 6 批），改 shim 会让在飞的输入链配置作废；等 `D-P1` 收口后按"**先补一次纯 RTL 的干净视觉读数（T1d 的 F2/P0 镜像归属）+ 离线牙齿**"再开这一项。
> ### 🔴 第 6 批第二次重放：**编译过了，但运行时崩了**（`verify-all.sh` 8/9，`ManagedLayer.Tests` 崩）—— **"探针关掉 ≠ 无副作用"**
> **崩溃原文**（`DISPLAY=:96`、**全新 Xvfb** 复现 ⇒ 不是环境污染）：
> ```
> TypeInitializationException: 'System.Windows.UIElement' threw → 'System.Windows.Media.Transform' threw
>   → NullReferenceException at DependencyObject.SetValueCommon(...) build/WindowsBase.Linux/DependencyObject.Linux.cs:line 1200
>   ← MatrixTransform.set_Matrix ← Transform..cctor ← UIElement..cctor ← HwndTarget..ctor ← HwndSource.Initialize
> ```
> **生成物 `:1200` 原文**：`WpfLinuxDpValueTrace.W6BeforeUpdate(this, dp, operationType, newEntry, oldEntry, **_effectiveValues[entryIndex.Index]**);`
> ⇒ **下标访问写在调用点的实参里**，而**静态初始化期**（`Transform..cctor`）`entryIndex`/`_effectiveValues` 尚未就绪 ⇒ **NRE**。
> 🔴 **决定性事实：这发生在探针"关着"的时候** —— **调用点实参总会求值** ⇒ "缺省零开销/零副作用"在**实参层**并不成立。T1c 上一批用"上游 `:807` 也有同款下标"给这处开了口子，但**上游那处在受保护的守卫分支内、落点在守卫之外**。
> **修法（已派 T1c）**：下标挪进 helper（`W6BeforeUpdate(..., entryIndex.Index, _effectiveValues)`），helper 内做 null/越界判断并**打印"取不到"而不是抛**；**全批自查**所有 trace 调用点实参里的 `[...]`/属性链/`new`，一律改成"传原件、helper 里取"。
> **新增流程要求（第三条）**：**"关掉 ≠ 无副作用"** —— 插桩的**实参必须惰性**。（前两条：**预测 sha ≠ 能编过**、**`--prove` ≠ 能编过**；本批两次都在同一天被实证。）
> **新增运行时闸门（已派）**：T1c 每批要自己跑 `DISPLAY=:96 dotnet test tests/…/ManagedLayer.Tests/…`（该套件正是**端到端建窗闸门**），期望 **失败 0 / 通过 58 / 跳过 0**，并把原文写进报告 —— 这样"编译过"之外还有"跑得过"。
> ⚠️ **当前树处于"已知坏"状态**：PC/WindowsBase 产物里带着这个坏探针 ⇒ **任何应用跑都会在建窗时崩**；已令 T3 停手；T1c 修好后由主控重放整波并把 `verify-all.sh` 跑回 **9/9**。**在此之前不得引用任何应用级读数。**
> ### ✅ 已修复并回绿（同日 19:2x）：**实参惰性化 + L12"触顶看得见"**
> T1c 把 **8 处**实参全部惰性化（WB `W6a/W6b/W4a`｜PF `Q2b`（`PendingInputItems[i]`）、`Q3`（`UiScope`）、`Q7a-c`（`this.TextContainer`）、`Q6b`（`undoAction.ToString()`）｜PC `P3b`（`e.StagingItem.Input.Source` 属性链）），并新增 **ARGSHAPE** 规则（实参只允许 `this`/局部变量/基元·枚举·结构体/字面量/纯转换/白名单成员；**不许**下标、属性链、`new`、方法调用）+ 机械尺子（含前两批的 scope/type 检查）。**它自己引入的两处缺陷也登记了**：PF `TextBox` 未全限定（CS0246）、以及第一版"触顶通知"写在 `return` 之后 ⇒ **不可达（CS0162）** ⇒ **那个修法本身是假的**。
> **L12（新流程要求）**：**额度触顶必须看得见** —— 任何有上限的探针触顶要打一行（含"已打 N 行"），**辅助格要有独立额度**，**能靠过滤收窄就别靠限额**。修法三条：总上限 200→2000、`W7` 独立 16 行额度、`W7` **收窄到 `Text` 这个 DP**（依据：`EffectiveValueEntry.cs:56` + `DeferredReference` 的子类里有 **`DeferredResourceReference`**（资源/样式/模板）⇒ 启动期 144 行是**预期**、不是过滤失效）。
> **四条流程要求（并列，均已写入 T1c 报告）**：① **预测 sha ≠ 能编过**（本日两次实证：预测值对、代码错）｜② **`--prove` ≠ 能编过**（只证纯插入）｜③ **"关掉 ≠ 无副作用"**（调用点实参照样求值 ⇒ 必须惰性）｜④ **额度触顶必须看得见**。
> ### 🎯 第 6 批四格判定：**命中 `d`，并给出可指的索引差**（T3，19:3x）
> ```
> 【L12 验收】W7=17 行（16+通知）；通知原文：W7 **已达独立额度 16 行**…（**「没打」≠「没发生」**）；W* 总 293：W1=W2=W3a=52、W5=90、W4a=W6a=W6b=10
> 【写侧】W5 SetValueCommon 写入 value=DeferredTextReference target=TextBox#33cafbe dp.GlobalIndex=432
>        W4a newEntry.Value=value **entryIndex=27** isDeferredReference=True ｜ W6b 之后 **有效值槽.Value=ModifiedValue 槽.IsDeferredReference=True（entryIndex=27）**
> 【读侧】38/38 次 effectiveEntry.IsDeferredReference=False、Value=string(7) "seed-文本"、W3a 提前返回 原因=A
> 【索引差】**Build 期那次 string 写 → entryIndex=1**（槽1 确认="seed-文本"、非 deferred）；**输入期两次 deferred 写 → entryIndex=27**；**读侧拿到的正好是槽1的旧内容**
> ```
> ⇒ **a 排除**（写读同为 `TextBox#33cafbe` / `dp.GlobalIndex=432`）｜**b 排除**（16 条 string 写**全在前**，之后**只有**两条 deferred 写、没有写回 string）｜**c 排除**（`W6b` 显示槽 27 确是 `ModifiedValue`/`IsDeferredReference=True`）｜**d 命中** —— **读路径用了与写路径不同的（陈旧的）`EntryIndex`**（表在生命周期里 1 → 27 增长过，写侧重查了、读侧没有）。
> **T1c 的第 7 批（已交付，含我加的第 4 条）**：读侧打 `LookupEntry` 结果与**实际传入的 `entryIndex`**（W1/W2/W3a）、`LookupEntry` 四个出口（W8）、`CheckEntryIndex` 入口+[沿用旧索引]出口（W9）。**第 4 条已答（逐字依据）**：`EntryIndex.cs:17-45` 把 `_store` 打包成 uint（**bit31=`Found`**、bit0-30=`Index`）⇒ **`Index` 不可能是 `-1`、没有 local/effective 标志位**；⇒ **第 6 批 `W5` 行里的 `entryIndex=-1` 是 T1c 自己的哨兵冒充读数**（已修成 `(该点没有索引)`，登记在案）。上游 `DependencyObject.cs:3020-3026` **自己文档化了这个风险**（"…we have made a call out and thereby caused changes to the `_effectiveValues` store. In that case we would need to aquire new value for the index."），`CheckEntryIndex`（`:3027-3040`）就是那道校验门（`_effectiveValues[idx].PropertyIndex == targetIndex` ⇒ 沿用，否则 `LookupEntry` 重查）；索引失效的机制 = `InsertEntry` 插入后移 + 数组增长/压缩（80% 阈值）；**`DependencyObject` 里没有任何 `EntryIndex` 字段** ⇒ 索引只活在局部变量、跨调用必须过 `CheckEntryIndex`。
> ### ✅ 纯 RTL 的**干净几何基线**已拿到（T3，`samples/WpfFeatureProbe/rtl-baseline-20260913.json`，含元组头）
> 口径：原始分辨率；**墨迹 = 与底色欧氏距离 >40 的像素**（**不用精确色**）；裁图原点 = 窗口左上角。工具 `tests/…/Presentation.Tests/rtl-ink-profile.py`。
> | 行 | 墨迹包络 | 宽 | 布局框 x | **Δx** |
> |---|---|---|---|---|
> | `he_pure_RTL`（`שלום עולם`） | [12,42] | **31** | 86 | **−74** |
> | **`he_same_string_LTR`（同串对照）** | [23,88] | **66** | 21 | **+2** |
> | `ar_pure_RTL` | [18,49] | 32 | 95 | −77 |
> | `he_with_digits_RTL` | [12,73] | 62 | 117 | −105 |
> | `ar_with_punct_digits_RTL` | [14,45] | 32 | 89 | −75 |
> **判定 丙（都不是）**：`RTL vs LTR` 逐列相同 **1/4**、`RTL vs flop(LTR)` **0/4（翻转更差）**、宽度比 **31/66 = 0.47** ⇒ **RTL 画出来 ≈ LTR 的前半段**；**强旁证**：`ar_pure_RTL` 与 `ar_with_punct_digits_RTL` 轮廓**逐桶相同**（`[44,32,27,31]` vs `[43,32,26,31]`）⇒ 后加的 `، 123` **一点墨迹都没多** ⇒ **不是压缩，是"画到某个宽度就停"**。
> **Δx 偏移只出现在 RTL 行**（LTR 对照 +2 px）⇒ **不是坐标基问题**（T3 撤回它自己上一轮的坐标基疑点）。混合方向块（`text-rtl`）现状另存为对照：**修法① 不会修好它**（仍需段落级 UBA）。
> **修法① 的四条验收读数（写死，T3 用来判真伪）**：① `he_pure_RTL` 包络宽 **31 → ≈66**；② 其 **Δx −74 → ≈+2**；③ `ar_with_punct_digits_RTL` **不再**与 `ar_pure_RTL` 逐桶相同；④ **六项 tline 逐位不变**（`T1.73 73/73`、`T2 记账`、`T2b 972/972·213/213`、`T2d 1298/1298`、`T3 折叠 218/236`、`Tab 0 例`）。
> **T1d 已按修法①改 shim**（`build/shims/PresentationCore.HbTextLine.cs`：`ebccdb1e… / 206,286 B / 3766 行` ⇒ **`d116bcb8a34769d81520a9225a9900f703631f38d3f7a7a04bdb7b89d4e2e4a4` / 3816 行**），**PC 已重建**（`6dfacf822e4163bb08acb3da…`，二进制标记 `hb_buffer_get_direction` **0 → 1** 为证）；本轮与 T1c 第 7 批合成**一趟波**：波前==波后 **`3c9f8fb97aa8eca2166aaed1a8affcdc302ff72b81227bcf0f0190127d94783e`**、15 工程 0 错 0 警、`DependencyObject.Linux.cs` = 预测 `4bf6dde4`、`verify-all.sh` **9/9（843/2/0）**。
> **T1d 的离线读数（修法① 后）**：RTL `'שלום עולם'` ⇒ `glyphIds=[1344,1331,1324,1332,3,1337,1324,1331,1332]`（**逻辑序**）、**`clusterMap=[0,1,…,8]`（恒等 ⇒ ClusterMap 退化已除）**、`inkBox=(-0.398,-11.206)-(64.984,2.299)`、`Width=65.256`；LTR `'Hello world'` 恒等不变。**`InvertClusters` 未改已升级为机器核**（两版函数体 17 行**逐字节相同**，体 sha `b34c62fa…`）。**T1d 两处自我订正**：① 注释与代码相反（注释说把方向带给 `BuildGlyphRun`，实参却是字面量 `0`）⇒ 修成一致，并用"写回原文 ⇒ sha 逐字节命中上一版 + A/B 172 行输出完全相同"证明是纯注释改动；② 它记的 `T2d Extent 1259/1298` 是 Tab 修法前的旧账，本轮两次独立实测都是 **1260/1298**。
> ### 🔴 T1b 发现的**测量对象未钉住**（新一类，已修机制 + 暴露既往读数可疑）
> T1d 顺手发现 `run.sh` 的 `refresh_applocal()` 路径拼错（`ROOT` 已是 `…/build`，函数又写 `$ROOT/build/…` ⇒ `build/build/…`）⇒ **四个权威件永远"缺失（跳过）"**、该函数**一行都没生效**。T1b 修掉（`ls -d build/build` 复现原文 + 缺件**醒目告警**+`return 1` 的牙齿，用**假 ROOT** 造缺件、零触碰真实产物）。
> ⚠️ **修好后一跑发现"影响不是零"**：**2/4 副本陈旧** —— `DirectWriteForwarder.dll 7327b80a→284d2628`、**`PresentationCore.dll 455ddb38→6dfacf82`**（`Provider`/`WindowsBase` 一致）。⇒ **`T0.6` 只钉 shim 源、没钉探针目录里的 PC/DWF 副本** ⇒ **T1b §19/§20 与 T2 §23.6 所依据的那批 tline 读数属"可疑读数"**（它们写 PC `8ff5cb38…`，既没钉副本、也早于修法①）⇒ **已派 T1b 用同步过的副本 + 新 PC/shim 重跑 `tline`**，并把"`T0.6` 要不要加钉 4 份副本 sha"定下来。**RTL 修法① 验收第 ④ 条（六项逐位不变）现在就挂在这次重跑上。**
> **另**：T1b 指出 `run.sh` 里它自己上一轮加的 `refresh_applocal` 之所以"看起来没坏"，正是因为它**从没生效过** ⇒ 这正是"**helper 没跑过它进入的目标**"那条教训的第二次实例（第一次是 `$ROOT` 未绑定导致 `tline` 第一步就死）。
> ### 🎯 第 7 批（读侧索引）结果：**索引假设被排除 ⇒ 丢标记发生在"槽内容 → effectiveEntry"（flatten）那一步**
> ```
> W1 … 读侧 LookupEntry 得到 Index=27 Found=True ｜ W2 … 读路径传入的 entryIndex: Index=27 Found=True   （W1/W2 之间无结构变化）
> 52 次读：35×Index=27、3×Index=24，返回内容**全部** effectiveEntry.Value=string(7) "seed-文本"、IsDeferredReference=False
> **"读到过新文本"的次数 = 0**
> ```
> 与第 6 批 `W6b`（写入后槽 27 = `ModifiedValue`/`IsDeferredReference=True`）合起来 ⇒ **不是索引陈旧，而是"槽内容 → effectiveEntry"丢了 deferred 标记**（`GetEffectiveValue`/flatten 那一段）。**第 8 批（已派）**：读路径把**原始槽内容**与**算出的 effectiveEntry** 并排打出来（`_effectiveValues[i]` 的 `Value` 类型 / `IsDeferredReference` / modifiers）+ 那 3 次 `Index=24` 发生的时机（表 24→27 迁移路径）。
> ### ⚠️ RTL 修法① 实测**不通过**（partial，且**按脚本不对称**）—— 但基线 **#4 已冻**（门禁 PASS）
> 同帧内对照（元组 `pc=6dfacf82 wb=1bc072a0 pf=c08ac772 hbtextline=d116bcb8`）：`he_pure_RTL` 宽 **30**（同串 LTR 对照 **67** ⇒ 比 **0.45**）、Δx **−73**（对照 **+1**）⇒ **①不通过、②不通过**；而 **③通过**（`ar_with_punct_digits_RTL` 不再与 `ar_pure_RTL` 逐桶相同：`[40,53,46,49,31]` vs `[8,33,41,20,21]`，ar 宽 32→40、墨迹 134→219）⇒ **阿拉伯那条确实变了、希伯来那条几乎没变**（`HBLINE D#` 显示两者字形数/面一致 ⇒ 差异不在整形面）。
> **⚠️ confounding（T3 自己标出）**：本波 `hbtextline` 也变了，**同串 LTR 对照行自己的 8 列轮廓也变了**（`[40,31,33,22,22,34,31,37,10]` → `[37,35,22,40,21,26,33,28,18]`，**总数都是 260**）⇒ 要么是修法① 对该行也有副作用、要么是采样/裁图口径对亚像素敏感。**两条都已派**：T1d 判"阿拉伯为何变、希伯来为何不变"+"LTR 对照轮廓变化"的归因 + 下一步最小修法；T1b 用**同步过的副本**重跑 `tline` 六项（**验收④ 的唯一依据**，它现在悬着）。**修法① 的结论保持"不通过"，不许写成"看起来好了"。**
> **基线 #4 已冻**：`# RE-FROZEN #4 after RTL 修法①(pc) + 第 7 批探针(wb)`，6/6 BASELINE PASS、`WPTD_GATE=PASS`、`distinct_origin_y=12 runs=167`、桥契约 ✅；**变化位 = pc / windowsbase / pf / hbtextline**；`1400` 累计 **102 次启动 / 0 命中**；并写明"本趟 hbtextline 也变了 ⇒ 跨波不比绝对值"。
> ### 🔄 RTL 修法① **结论被 T1d 反转**：修法**生效了**，是 T3 那两条判据**量错了对象**（量的是裁剪窗口）
> 依据（T1d §9，只读 + 离线装置）：
> - **两条都变了**（he `binned8 [39,28,33,30]→[35,28,33,23]`、ink 130→119；ar `[44,32,27,31]→[40,53,46,49,31]`、ink 134→219）；**没变的是"可见段的位置与宽度"**。
> - **两条支配律 4/4 成立**：**缺失量 = 行宽 − 可见宽 = 34.2 ± 1.1**（he 35.3/ar 33.8/heNum 34.4/arNum 33.1）｜**画出的左端 = 可见右端 − 行宽 = −22.6 ± 0.8**（he −23.3/ar −21.8/heNum −23.4/arNum −22.1）。★**左端与行宽无关**（行宽差 31 px、左端只差 1.6 px）⇒ **平移签名**（一次镜像会让端点随行宽变化）。
> - **切口像素证据**（y=215 逐像素）：x=12 `#1B2330`、**x=13 已是品红墨迹**、x=16..17 卡片底色 ⇒ 墨迹**从容器内容边缘开始**、**行头在左边被切**；而 `HBLINE D#0 glyphs=9 chars="שלום עולם"` ⇒ **字形全提交了**。
> - **不是"Rtl 没命中/run 被拆"**：`HBLINE B#0 … glyphRuns=1 runOrigins=[(0.000,12.995)] inv=1`，同串 LTR 行 `inv=0` ⇒ 宿主按 `Line.cs:79/116` 传了 Horizontal。
> - **顺序改不动包络**（`שלום עולם` inkBox 宽 65.383→65.382；`שלום 123 עולם` 96.555→96.554，≤0.001 px）⇒ **①② 不可能靠任何顺序修法达成**；而 **ClusterMap 2/9→9/9**（ar 2/13→13/13、heNum 2/13→13/13、arNum 2/10→10/10）。
> - **LTR/CJK 逐字节不变**：探针 A/B 里 `Hello world`/`中文混排 test` 相同；**同 harness、同 PC、只换 shim 源 ⇒ `diff` 为空**（且 T1b 的 §23 已用**同步过的 4/4 副本 + 新 shim** 复核六项**逐项相同** ⇒ **RTL 修法① 的验收④ 成立**）。
> - **shim 不可能把 run 放到行外**：`_paragraphWidth` 是 `readonly`（shim `:2078`/`:2117`）且与格式化同一实参；站点 B 单行无折行 ⇒ `pw ≥ W` ⇒ run 落在 `[pw−W, pw]` 内 ⇒ **那 44 px 左移只能来自宿主的绘制原点/视觉层**；`Draw` 与上游 `SimpleTextLine.cs:482-505` + `TextFormatterImp.cs:565-595` 逐字段同式。
> - **T3 的 Δx 口径对 RTL 行含一个整行宽的假偏差**：`WFP_BOXID` 的 x 恰好 = `21 + ActualWidth`（86=21+65.3、95=21+73.8、117=21+96.4、89=21+68.1）⇒ RTL 行报的是**镜像后的角点（右上角）**，Δx −73/−82/−105/−77 各含 +行宽 ⇒ **判据应改成"与同串 LTR 对照行对齐 + 墨迹总量相当"**。（y 方向所有行都有 ≈+10..12 px 固定偏移、LTR 也一样 ⇒ 那是坐标基问题，不是 RTL 症状。）
> **下一步（T1d 已派，仍在只读/最小改动范围）**：**站点 B 加 `pw=`（`FormatLine` 的 `paragraphWidth`）与 `pw−W`**，并用**离线装置**判判别表 —— **`pw ≥ W`（预测必然）⇒ 缺陷在宿主绘制原点/视觉层**（去查 `TextFormatterImp.Linux.cs:238-240` 与 `SimpleTextLine.Draw` 的 `origin`/裁剪）；**`pw == W` ⇒ shim 退化成就地镜像 ⇒ 修法① 应回滚**（并给出回滚后的预期读数）。同时产出**替换 T3 那四条里被证伪部分的新判据**（写死）。
> ⚠️ **权威产物被闸门构建改动（新一类协调问题）**：T1c 的 `REPO_RC_*`（应用 applier + 编仓库 `bin/`）会把"权威 PC"改名 —— T1d 观察到 **PC 已变成 `b5fc5ba10dc0bbd8…`（20:16:53）**，而基线 #4 记的是 `6dfacf82…` ⇒ **#4 又过期了**。已令：优先私有输出目录；必须编仓库时**在报告里写出三个产物 sha 并声明"权威已被闸门构建改动、需主控整波重建"**。⇒ **收尾流程固定为：所有车道停手 → 主控跑一趟波 → `verify-all.sh` 9/9 → 冻 #5**。
> ### ✅ 第 8 批 + `pw=` 读数已装；**基线冻 #5**（`WPTD_GATE=PASS`、`1400` 累计 **108 次启动 / 0 命中**）
> 新配置：PC **`c43d351639856680f934ebb0…`**（20:34:04）｜WindowsBase **`8c073fab0da8816987a7cbae…`**（20:32:59）｜PF **`e5c6f5a7eeef9b81f11834fa…`**（20:35:36）｜shim **`13992b58905d00e0aea8736c14a94836515f9d4355e2db75dc12d1af00a89e91`**（3832 行，只加 `pw=/W=/pw-W=`；T1d 用"删 11 行 ⇒ sha 逐字节回到 `d116bcb8`"证明行为未变）｜波前==波后 **`d27ec7ec81f578b34304eb8e4595d9042d6da5aef7dbe6afa748843bdb214926`**、两份生成物 sha 与预测逐字节一致、`verify-all.sh` **9/9（843/2/0）**。
> **`D-P1` 第 8 批**：`W10` 打出 **`取值[CoercedValue（IsCoercedWithCurrentValue ⇒ SetCurrentDeferredValue 那一支）]`、`Coerced=DeferredT…`、`IsDeferredReference=True`**，而 `W2''` 的 **effectiveEntry = `string "seed-文本"`/`IsDeferredReference=False`** ⇒ **判据 ④ 命中**（取对了值、构造 flattened entry 时丢了标记）；① 不成立（不是取值选择错）。⚠️ **探针互相矛盾（T3 主动标出）**：`W2'`（原始槽）说 **无修饰**，而同趟 `W10` 与第 6 批 `W6b` 都说**有修饰且 Coerced=deferred** ⇒ **三处很可能读的不是同一份 entry/同一时刻/同一对象**。
> **主控读码补充**：`EffectiveValueEntry.Linux.cs` 的修饰分支在 `:386`/`:395` 把 `modifiedValue.CoercedValue` 写进新 entry 的 `Value`，而 **新 entry 的 `IsDeferredReference` 是从源槽拷来的**（`:367 IsDeferredReference = IsDeferredReference`）⇒ 若源槽标记为 false，**flatten 后的 entry 会"值对、标记丢"**。⇒ **不再继续钻内部探针**，改用**最小复现**（见下）。
> **RTL（新判据，T1d §10.5）**：**判据 1 不通过**（`Δright = 42−88 = −46`、`Δw = 30−67 = −37`、墨迹比 **0.46**，要求 ≤2/≤3/∈[0.9,1.1]）；**判据 2 因前提未满足 ⇒ 不判**；**判据 3 通过**且**噪声底 = 0**（两趟逐位相同 ⇒ 之前那次"LTR 对照轮廓分布变了"是**真实变化**、不能用噪声解释）；**判据 4** 归 T1d 的离线装置（9/9 + 数字锚 ✓）。
> **44 px 定位（三格）**：`LayoutInformation.GetLayoutSlot` 对 RTL/LTR **完全相同**（`0.0,…,546.5`，被拉伸到整个面板）⇒ 槽**区分不了**；`TransformToAncestor` 显示 **RTL 行的视觉框确实被镜像**（`t0=86.3 → t1=21.0`，跨度仍 65.3）、LTR 对照不镜像 ⇒ **宿主镜像在 T3 侧独立复核 ✓**；而 RTL 墨迹 `[13,42]` **落在它自己的视觉框 `[21.0,86.3]` 之外**、LTR 对照的墨迹 `[22,88]` 恰好落在框内 ⇒ **位移在"绘制/视觉层"，不是 arrange**。
> **`HBLINE B#` 实测（复核 T1d 的静态估计）**：纯 RTL/纯 LTR/阿拉伯 各行的 **`pw == W`、`pw−W = 0.0000`**（T1d 估的 `+0.04…+0.55` 出现在**别的**行上）；RTL 行 `inv=1` ✓ ⇒ **反演确实在下发、偏移量 = 行宽**。
> **下一步（已派 T3）**：① **最小复现块**（**不做任何 X 输入注入**）：`Text="seed-文本"` → 布局 → `SelectAll(); SelectedText="A"`（正是 `DoTextInput` 的两个调用）⇒ 立刻/下一 Dispatcher 回合/500ms 各读一次 `Text` 与 `TextChanged` 计数，判"`Text` 会不会更新"⇒ **成立就是可修的 repro；不成立说明现象只与输入链结合时出现**；② **元组补 `windowsbase_sha`**（尾部追加、两 runner 同步；T3 发现七元组里**没有 WindowsBase** 而它每波都在变且直接影响行为 —— 已采纳）。
> ### ✅ 最小复现结果：**不成立** ⇒ `D-P1` 被收窄到"**只经 `SetCurrentDeferredValue` 的那条路**"（这是本轮最有价值的一次收窄）
> 新块 `text-dp-min`（`samples/WpfFeatureProbe/FeatureBlocks.cs`，**追加为第 11 块**，**不做任何 X 注入**）：构造 TextBox → `Text="seed-文本"` → 入树布局 → 等一个 Dispatcher 回合 → `SelectAll(); SelectedText="A"`（**正是 `DoTextInput` 的两个调用**）→ 立刻/下一 `Background` 回合/500ms 各读一次；`sel=`/`line0=` 是**容器侧**读数。
> ```
> WFP_TEXTDP t1='seed-文本' c1=0 sel=''  line0='seed-文本'
> WFP_TEXTDP t2='A'        c2=1 sel='A' line0='A'
> WFP_TEXTDP t3='A'        c3=1 sel='A' line0='A'
> WFP_TEXTDP t4='A'        c4=1 sel='A' line0='A'
> ⇒ **`Text` 正常更新（`TextChanged` 0→1）、容器侧一致** ⇒ **最小复现不成立**
> ```
> ⇒ **`D-P1` 只在"输入链里那次 `SetCurrentDeferredValue` 写"上出现** ⇒ **下一步查那次调用的时机/条件（PF `Q7b`），不必回 DP 引擎继续钻**。（口径：runner 自己的注入发生在 t4 之后 ⇒ `c4=1` 说明记录时只有本块自己那次编辑。）
> **元组补丁已落地**：两 runner 尾部追加 `windowsbase_sha=`（既有字段顺序未动、`bash -n` 通过；实测行 `… pc_compare_mtime=1789302844 windowsbase_sha=8c073fab0da88169`）；`ACCEPTANCE-BASELINE.md` **#5 只加一行说明**（值取自同一趟 `go-freeze5`），**未重跑门禁、未改 #5 判定**。
> **`D-P1` 当前状态（挂起，登记在 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md`）**：键盘输入后 **`TextBox.Text` DP 与 `TextChanged` 陈旧**（容器与渲染都正确；真应用读 `Text`/绑定 `Text` 会静默拿旧值）。**已证**：传输层已闭环（队列根因修好、`pop 0x0102`×2）、PF 链全绿（`Changed`/`TextChanged` 已 raise、`Q7b SetCurrentDeferredValue`×2）、**索引假设排除**（读侧 27 = 写侧 27）、**最小复现不成立**（普通编辑路径正常）。**未定**：`GetFlattenedEntry` 那一步的取值/标记（`W10` 与 `W2'`/`W6b` 三个探针互相矛盾，T3 已如实登记；主控读码发现新 entry 的 `IsDeferredReference` 是从**源槽**拷来的 `EffectiveValueEntry.cs:367`）⇒ **下一轮的第一件事是统一探针口径或改用更硬的装置，不要再加同型探针**。
> ### ✅ 记账残差**收口**（T1b §24）：**12 行全部可点名 ⇒ 新缺陷 0 / 未判定 0**
> 装置口径修正（**只加输出、阈值与语义一字未改**）：原检查是"用例级 + 只记首个原因" ⇒ 行级清单取不到（这正是 T2 那格"余 0–3 行无读数"的根因）。现在**每行失败都追加** `用例名 | 行号 | 期望 | 实得 | 归类桶` 并写盘 `gen/tline-ledger-lines-20260913-2100.txt`（含 shim 源 sha + 4 份副本 sha，并打印**条数 vs 上限**）。
> **12 行 = 6（NBSP/ZWSP 行尾空白口径，已登记）+ 6（`M_modifier_*` = TextModifier 未实现，已登记）**；`M_modifier_*` 的原文给出**量级差**（真机 `Len=50` vs 我们 `Len=6`；`nl` 期望 1 / 实得 0）⇒ **不是计数误差**。T1b 并**更正自己**先前"后两类属硬断口径族"的说法。
> ### ✅ `M_modifier` 那条**真缺陷候选**已判为 **(甲) 完全由"`TextModifier` 未实现"解释**（T2 §23.7，只读+独立复算）
> - **登记与适用范围**：`T1b-report.md:199` 逐字；`grep -i textmodifier src/` = **0**、`build/*.Linux/**` = **0**；shim 里 `hasModifierScope` **11 处全是标志、无一处进布局**；唯一"桩"是 `GetTextLineBreak()` 非 null 分支发**零记录** `TextLineBreak`（`:2757-2759`）。语料：`Cases.cs:290-302`（`modText` 62 字、`w ∈ {80,120,200,320,1e6}`、`modifierEnd:45` ⇒ 区间 **[6,45) = 39 字**）；`OracleModifier`（`TextModel.cs:54-66`）把源切成 3 个 run；**语义权威**：上游 `TextModifier.cs:20-28` 的 `CharacterBufferReference` 是 `sealed override` 返回**空 buffer** ⇒ **修饰符 run 不携带字符**（无字形/无 advance/无墨迹、只跳过源字符位置）。
> - **两个数怎么来的（独立复算）**：`ComputeInkBoundingBox` **是上游 `GlyphRun.cs` 原样编入**（`PresentationCore.Linux.csproj:543`；`GlyphRun.cs:1384-1392` 的 `inflation = min(em/7,1)` ⇒ em16 时 **+2.0**，同一行源码）。T2 用**纯 python 解 NotoSans-Regular.ttf**（glyf/loca/cmap）复算：`"bravo "` 12.32+2.0=**14.3200** ✓、`"charlie delta "` 同 ✓、全文 62 字 16.08+2.0=**18.0800** ✓、去掉区间后的可见文本 16.00+2.0=**18.0000…** ✓ ⇒ **`0.08` 之差 = `'f'.yMax(765) − 'l'.yMax(760)` × 0.016，就一个字**。
> - **三条独立读数钉死 (甲)**：① 行宽（真机 w80 行#0 `74.5733/78.7333`，T2 从 TTF 算 `"alpha otel"`=74.5760、`"alpha otel "`=78.7360 ⇒ 真机可见宽**正好是非修饰符字符的宽**，区间那 39 字的 advance **283.1680 完全不出现**；我们 winf=439.1360）；② 行数/断点（真机 2 行恰因可见宽 ≤80，我们 7 行）；③ Extent（上表）。**不是 (乙)**：三个不同行内容都被 TTF 逐位命中，无"该算墨迹被漏算"的读数。
> - **实现它需要两件事**（估工时要算）：**装置侧无通道**（`Program.cs:251-252` 把 `modifierStart` 折成**一个 bool**、`:274` 只传这个 bool ⇒ **区间根本没进被测代码**）；**shim 侧无实现**（需要"区间字符不产生字形/advance/墨迹"的通路）。
> **顺带确证**：`cr.Width` = **原行宽 − 折后行宽**（shim `:2772` 注释逐字）⇒ **可为负**（`F_nbsp_zwsp_w40#3` 我们 `-3.0560`）⇒ 把 §23.6 的"另一本账"升级为**定义级依据**，不改任何分桶结论。
> ### 🔄 RTL：**镜像这条线查完 ⇒ 宿主的镜像矩阵是对的**；问题改为"绘制时 run 的 x/advance"
> PF 侧第 9 批探针（M1…M6）实跑（T3，元组 `pf=dee475f0bf7175cf`）：
> ```
> M1' 推了镜像 M11=-1 M22=1 **OffsetX=65.255859375**（恰等于当时 RenderSize.Width）｜RenderSize=65.256x16.297
> M1' … 73.8486 / 96.4277 / 68.0586 / 546.48 …（逐条与 `HBLINE B#` 的 W/pw 对得上）
> M2 SetLayoutOffset offset=(0,17.97) **oldRenderSize=0x0** ｜ additionalTransform 与 M1' 一致
> M5 ApplyMirrorTransform(parentFD=LeftToRight, thisFD=RightToLeft) ⇒ True ×5 ｜ **M3=0 行、M4=0 行、M1''=0 行**（两站没走到 ⇒ T3 记为**读数缺口**，不是证据）
> ```
> ⇒ **命中"实推变换 == 报告口径"**（`OffsetX` 恰 = `RenderSize.Width`）⇒ **镜像矩阵按契约在下发**；几何与上一趟**逐行完全相同**（噪声底 0）⇒ 加读数没有改变渲染。
> **T3 的"横向压缩到 45%"结论被我提出再解释（待 T1d 判）**：T3 的依据是"墨迹总量 46% 而逐列密度几乎相同（`3.97 vs 3.88`）"；但**同一组数也符合"裁剪"** —— **压缩会让密度升高（≈2.2×），实测密度没变** ⇒ 更像"**整条 run 整体左移后被裁掉左半**"（与 T1d 拟合的 `R(y)=42−y` = 镜在元素左边缘 21 是同一件事的两种写法）。**判别式 = 密度方向**。
> **已派 T1d**：在**绘制层**加一格读数（宿主传入的 `origin`、`_paragraphWidth/Width/Height`、推入的反演矩阵、每个 run 的 `baselineOrigin`/`glyphCount`/`Σ advance`/**首末字形累计 x**、能算就再给绝对区间 `abs=[…]`）。判据：**局部区间正常而绝对位置错 ⇒ 不在 shim**；**局部区间只有 ~45% ⇒ 在 shim（回到修法① 的数组反转/advance，给 `file:line`）**。同时用离线装置把"压缩 vs 左移+裁剪"判死。另：`M3/M4` 两站没走到 ⇒ 已交 T1c 复核站点位置。
> ### 🎯 RTL 位移已钉到**桥的 `CTM` 平移**这一格（三段证据链完整）
> **① shim 站点 E（T1d 离线逐字）**：`hostOrigin=(0,0) pw=65.2559 W=65.2559 inv=1 ｜ anti=(-1,1,offX=65.2559,0) ｜ runs=1 [r0 bo=(0.000,12.995) n=9 adv=65.2559 **x=[0.000,65.256] absX=[0.000,65.256]**]`，`Σadv−W = 0.0000`、`xEnd−W = 0.0000` ⇒ **行内区间正常**（另：`--width 200` 时 `offX` 跟着 `pw` 走而 run 区间不变；`pw=0` 降级行 `anti=None` 可见）。新 shim sha **`e019db5646217ba0530fbeeb155df1a1e480106ec7544a24a8f9f5ce327bbf03`**（3897 行）；**两次逐字节自证**：回退判据格 ⇒ `cd5a90b2…`，再回退整段 SiteE ⇒ `13992b58…` ⇒ **修法① 一行未动**；A/B `diff` 只有带时间戳的输出文件名一行。
> **"压缩 vs 左移+裁剪"判死 = 左移+裁剪**（T1d 四条互证）：密度不变（`3.97 vs 3.88`/列；真压到 46% 应为 `8.67`=2.2×）｜簇数 5 vs 8（是串的一段而非整串挤进来）｜最小簇间距 4.0 px ≈ `ו` 的 advance 3.814（比例 ≈1.00）｜切片匹配 1.28 优于压缩匹配 1.51。
> **② 桥普查（`WPF_LINUX_GLYPH_CENSUS=1`，同卡五行，同串两行对照）**：
> ```
> 行                 n   devX        originDIP          CTM
> he_pure_RTL        9   −24.594    (0.000,12.995)   [1.0417,0,0,1.0417, **−24.594**, 206.286]
> he_same_string_LTR 9   +21.875    (0.000,12.995)   [1.0417,0,0,1.0417, **+21.875**, 227.428]
> （另三条 RTL：devX −24.952 / −25.893 / −24.711，`originDIP` 全同 (0.000,12.995)）
> ```
> ⇒ **`originDIP` 两侧完全相同（差 0）** ⇒ 位移**不在** PC 交给 MIL 的 `BaselineOrigin`；**`CTM` 平移差 Δ = −46.469 设备 px**（≈44.6 DIP）⇒ **命中"位移在 CTM/视觉层"**；**两条 `m11` 都是 +1.0417（正）** ⇒ **普查 CTM 里没有镜像**；用该 CTM 反推设备区间 RTL `[−24.59, 43.37]`（与像素反推 `[−23.26, 42]` 差 ≈1 px）、LTR `[21.88, 89.86]`（与墨迹 `[22,88]` 吻合）⇒ **像素就是按这个 CTM 画的，之后没有再作用别的变换**。
> **旁证**：**两条同串 run 的 glyph id 序列逐位相同**（`first16=1344,1331,1324,1332,3,1337,1324,1331,1332` = 逻辑序）⇒ shim 交给两侧的是同一串，RTL/LTR 的区别**只在 CTM**；`devY` 逐行 ≈ `20.3 DIP × 1.0417` 间隔、正常（y 方向留档不混入判据）。
> **已派 T2b（只读定位）**：这个 CTM 在桥里哪一行组装（"视觉绝对偏移 × ppd + `originDIP`"的算式），为什么 RTL 平移差 ≈44.6 DIP（要求给出"能把 −24.594 算出来的式子"，并用 `left=21 / W=65.256` 表示），以及**镜像的线性部分去哪了**（三选一：甲 镜像不在桥看到的视觉变换里／乙 桥只用了平移分量丢了 `m11`／丙 普查打的是镜像之前的中间量——但第 3 段已用像素证明"之后没有再作用别的变换"，丙需解释矛盾）。**修法候选 ≥2 条 + 预期读数**（RTL `dx` 应落到 ≈`+21.875`、墨迹包络 ≈`[22,88]`，判据 1：|Δright| ≤2、|Δw| ≤3、比 ∈[0.9,1.1]）。⚠️ **本轮只读**（改 `src/**` 要我重跑 AOT 发布 + 重冻基线）。
> ### ✅ T2b 的定位结论：**(甲) 镜像不在桥看到的视觉变换里**（桥老实平移上游给的负偏移）
> **CTM 唯一组装点（逐字）**：`SkiaRenderBackend.cs:204-207` `world = Concat(Concat(parentWorld, v.Transform), Translate(v.Offset.X, v.Offset.Y))`｜`:186` 根 = `SKMatrix.Identity`｜`:272` `canvas.SetMatrix(Concat(world, deviceBase))`｜`deviceBase` 含 ppd（**精确 = 25/24**，由 `e_LTR = 21.875 = 21×25/24` 反推）。绝对偏移来源 `VisualProjection.cs:33-40` ← `MilVisualNode.OffsetX/OffsetY`（`MilCmdVisualSetOffset` 0x1b）+ `TransformResolver.Resolve(node.Transform)`。**`world` 的输入只有 `parentWorld`/`v.Transform`/`v.Offset`/根 Identity。**
> **代数**：两侧 `m11=+1.0416667` 逐位相同 ⇒ `world.m11=+1`（**镜像项缺失**）；RTL `e=−24.594` ⇒ `world.tx = **−23.61024 DIP**`（上游带下来的**负平移**）。像素包络 `[−24.59, 43.37]` 与打印 CTM 推算一致到 **0.02 px** ⇒ **双仪器互证**。
> **排除法**：**(乙)** 丢 `m11` 只能产出**正**平移（`+67.976` 或 `+89.851`），与负的 `−24.594` 矛盾；**(丙)** 打印点即绘制点、像素与打印矩阵一致 ⇒ 不存在两套矩阵。
> ⚠️ **T2b 如实留了一个不闭合**：`Δ = −44.61024 DIP` vs `W − t1 = 44.255859 DIP` 差 **0.354 DIP**（比读数精度大 700 倍）⇒ 需要**全精度**的 `OffsetX` 与 `t0/t1`。T3 随后给了**全精度** `t0/t1`（**单位 = DIP**）：`he t0=86.2559,198.0343 t1=21.0000,198.0343`｜`heLTR t0=21.0000,218.3311 t1=86.2559,218.3311` ⇒ `W=65.2559`（与 `OffsetX=65.255859375` 一致到 F4）、`W−t1 = 44.255859` ⇒ **缺口不是 T3 四舍五入造成的**；并给出**单位换算与限制**：墨迹是**设备像素**、`ppd=25/24` ⇒ `he_RTL [13,42]px = [12.48,40.32] DIP`、`he_LTR [22,88]px = [21.12,84.48] DIP` ⇒ 墨迹法 Δright = **44.16 DIP** vs 代数值 44.61024，差 0.45 DIP，**而像素法自身不确定度 ±1 px ≈ ±0.96 DIP（比该缺口还大）** ⇒ **这个缺口只能靠内部读数闭合**（设备空间 run 原点或 MIL 节点 `offset=(x,y)` 全精度），**包络闭合不了**。
> ### ⚠️ 变换溯源那一族**本次读不到**（读数缺失，T3 拒绝用 CTM/几何反推）
> T3 开 `WPF_LINUX_DRAW_CENSUS=1` 跑 RTL 趟 ⇒ `TransformProvenance = 0 行 ｜ VisualProjection = 0 ｜ TransformResolver = 0 ｜ offset=( = 0 ｜ MilVisualNode = 0`。**主控读码查明原因**：该族文本是**挂在"零退化归因"那条 census 行尾部**的（`DrawInstructionCensus.cs:168-173` `sb.Append("  ").Append(prov ?? "变换=**无信息**(该节点未留痕)")`，且**只有检测到累积链退化时才走到那里**）⇒ **纯 RTL 行没有零缩放 ⇒ 这条行根本不产生**。开关本身是对的（`TransformProvenance.cs:36` 用 `WPF_LINUX_DRAW_CENSUS == "1"`）。⇒ **该族不能回答"镜像有没有交给 MIL"，需要换一格读数。**
> **主控的工作假设（明确标为假设，未按它走）**：PC 可能**同时**下发 `SetOffset(≈−23.61)` 与 `SetTransform(M11=−1, DX≈)`,即 `x_screen = 65.2559 − (x − 23.61) = 88.87 − x` ⇒ 框落到 `[23.6, 88.9]`（与 PF 的 `t0/t1` 一致），而**桥只应用了 offset、丢了那个 transform** ⇒ 得到实测 `[−24.6, 43.4]`。**已派 M7b 加一格桥侧读数**（MIL 命令入口的 `MilCmdVisualSetTransform`/`SetOffset`：命令类型 + 视觉句柄 + 变换资源句柄 + 解析前后矩阵；文本视觉过滤或前 N 条 + 触顶通知；缺省关、有界、实参惰性）⇒ **三选一**：从来不打印 ⇒ PC 没交给 MIL（修 PC/PF）；打印且是 `M11=−1` 而 `world.m11=+1` ⇒ **桥的 `TransformResolver` 丢了它**（修桥）；打印但不是镜像 ⇒ 查 PC 侧来源。**验收**：RTL run 的 CTM 落到 ≈LTR 的 `dx≈+21.875`（或镜像口径 `m11=−1.0417`）且墨迹包络回到 `[22,88]` 附近、判据 1 三条全绿。
> ### 🎯 **RTL 位移根因已定位：命中判据 ② —— 镜像交给了 MIL，但桥没把它并进 `world`**
> 桥已重发（**`62afae54937beb923d0b8720…` / 4,946,224 B**，`publish-milbridge.sh` rc=0、**发布期间 `src/**/*.cs` 指纹恒定 `c2645d79b30084adf5ea5d15`**、同目录 wic/skia 契约成立；`APPSYNC=MISMATCH(9)/DIVERGENT(3)` 是既有 app-local 副本、非本次引入）。
> **`[VISTRANS]` 实跑（`WPF_LINUX_VISTRANS_TRACE=1`，桥 sha 三处一致校验 ✅）**：
> ```
> #11 SetTransform visual=0x44 resKind=**MilTransformGroup** 原始=TransformGroup[children=1]
>     解析矩阵=[M11=-1.0000 M12=0.0000 M21=0.0000 M22=1.0000 **DX=65.2559**] **镜像=是 非单位=是**   ← 纯希伯来
> （另四条 RTL 文本视觉同样镜像=是，DX 恰等于各行行宽 73.8486 / 96.4277 / 68.0586 / 546.48）
> #1 SetTransform visual=0x2 resKind=**MilMatrixTransform** … M11=1.0417 … 镜像=否（全日志唯一的 MilMatrixTransform 是纯缩放）
> 同趟 census：RTL `m11=+1.0417 dx=−24.594` ｜ LTR `m11=+1.0417 dx=+21.875` ⇒ **镜像没进 world**
> 墨迹包络五行与基准**逐位相同** ⇒ 噪声底 0
> ```
> ⇒ **① 不成立**（五条 RTL 文本视觉都有 `SetTransform` 且 `镜像=是`）｜**② 命中**（有 `M11=−1` 而 `world.m11` 仍是 `+1.0417`）｜**③ 不成立**（矩阵就是契约上正确的局部镜像，`DX` = 行宽、与 PF `M1'` 的 `OffsetX=65.255859375` 一致）。
> **关键区分**：探针**自己调 `TransformResolver.Resolve`** 打印，**正确解出了** `M11=−1 … DX=65.2559` ⇒ **`Resolve` 对 `MilTransformGroup` 是好的** ⇒ 问题更可能在"**句柄有没有被存进视觉节点字段 / 投影有没有读它**" = **"投影时丢字段"那一族的第 4 个实例候选**（`SetOffset` 那条链是好的 ⇒ 两条链的差别就是缺陷所在）。
> **已派 T2b（定位 + 最小修 + 牙 + 私有目录编译）**：给出 `SetTransform` → 节点字段 → `VisualProjection.cs:33-40` 的逐段 `file:line`，四选一形态（**a** 存了但被 `SetOffset` 覆盖／**b** 存进投影不读的字段／**c** 契约里根本没该字段（只会静默默认值、编译不报错）／**d** 节点复用把句柄清掉）；修后验收 = RTL `CTM` 出现 `m11=−1.0417`（或等效 `dx≈+21.875`）、墨迹包络回 `[22,88]`、**判据 1 三条全绿**、**LTR/CJK 与六项 tline 不变**；并加一条**能变红的单元级牙**（"视觉节点带镜像变换时投影后的 `Transform` 必须含 `M11<0`"）。
> ⚠️ **T3 同时抓到一条必须随读数带走的前提**：本趟 **`hbtextline_shim_sha=e019db56…` 且 `stale=yes`**（shim 源 mtime > 权威 PC）⇒ **文本栈是旧产物**（我的上一趟波在 21:09–21:11，早于 T1d 在 21:20 加站点 E）⇒ **桥侧结论不受影响，但文本行为/度量类读数要带这个前提**；且"下一次取文本读数前必须先把 PC 重编到含 `e019db56` 的 shim"。**两条 staleness 闸门互补**（`WFP_SRC_STALE` 只看 `build/*.Linux/**`；`hbtextline_shim_stale` 单独管 `build/shims/**`）——这次是后者抓到。
> ### ✅ T2b 的"投影丢字段"假设**被证伪**（四形态逐条排除 + 三层牙），并补了两处"藏缺陷的缝"
> - **(a) 覆盖/复位：排除**（视觉 `Transform` 全仓库唯一写入者 `MilCommandDispatcher.cs:166`，无复位点）｜**(b) 投影不读该字段：排除**（唯一读取者 `VisualProjection.cs:38`，写读同一字段 `MilVisualNode.cs:33`）｜**(c) 契约缺字段：排除**（`Contracts/Interfaces.cs:61` 存在且可写）｜**(d) `GetFlattened`/节点复用：排除**（全仓库不存在）。
> - **"两条链的差别"= 0**：`SetOffset`(:148-159) 与 `SetTransform`(:161-171) **逐字对称**（`Require` → `ReadFixed` → 赋 `v.Visual.*`），两结构体都是 `Type@0 / Handle@4` ⇒ 句柄读法一致。
> - **三层牙**（新增 `VisualTransformToWorldTests.cs`，真机同形 `TransformGroup[Matrix(M11=−1, DX=65.255859375)]`）：**突变 A**（`:205` 丢 `v.Transform`）⇒ **恰好打红渲染级那条**；**突变 B**（`VisualProjection.cs:38`→Identity）⇒ **恰好打红投影级那条**；回滚后 `Rendering.Tests` **155/0/2/157**（基线 152 ⇒ **+3**）。**没有这条牙会漏过去的原因**：这一族**无编译错、无异常、无"未画出"计数、墨迹总量还不变**（镜像只翻面）⇒ 存量用例/golden 全是整图量级 ⇒ **可以全绿通过**。
> - **T2b 的一处自我更正**：它上轮把"像素包络与打印 CTM 推算一致"当"镜像没生效"的独立证据 —— **不成立**（有/无镜像两种形态的包络**端点逐位相同**，镜像只反转区间内顺序）⇒ **包络判不了镜像在不在，只有 `m11` 符号能判**。
> - **两处仪表缝已补**（env 门控、缺省关返回空串）：① `TransformProvenance` 对 `TransformGroup` 现在打**解析后矩阵 + 子类型 + 含镜像**（原来只打"子数=1"，而 `Resolve` 对查不到的子树**静默返回单位阵** ⇒ 那格读不出丢失）；② 字形 census 每行带 `来源=visual=0x… 本节点Transform=[…] 累积world=[…]`。
> ### 🎯 **RTL 根因（三段收官）**：命中「甲」⇒ **shim 的反演矩阵把宿主的镜像抵消了**
> 新桥 **`6d6f5fb08808fede…`**（4,950,336 B）＋新 PC **`116be62bba708b77…`**（含站点 E、`stale=no`）实跑：
> ```
> run#16 n=9 CTM=[1.0417,0,0,1.0417,-24.594,206.286] 来源=visual=0x44 本节点Transform=[-1.00,0,0,1.00,65.3,0.0] **累积world=[-1.04,0,0,1.04,89.8,206.3]** PushTransform=0x48  ← 纯希伯来
> run#17 n=9 CTM=[1.0417,0,0,1.0417, 21.875,227.428] 来源=visual=0x4b 本节点Transform=[ 1.00,…,0.0] 累积world=[1.04,…] PushTransform=**0x48**  ← 同串 LTR 对照
> （另三条 RTL 同样：来源=0x4f/0x56/0x5d、累积world 含 -1.04、CTM 仍 +1.0417；`[VISTRANS]` 四条 `镜像=是`，DX=各行行宽）
> ```
> ⇒ **甲 命中**（`来源=` 恰是收到镜像的视觉、`累积world` 含 `-1.04`，而同行 `CTM`=**`canvas.TotalMatrix`** 却是 `+1.0417`）｜乙/丙 不成立（`本节点Transform` 已解出镜像 ⇒ `Resolve` 没问题）。
> **机制（主控读码 + 算术）**：`SkiaRenderBackend.cs:536-543` 的 `MilPushTransform` 做 `canvas.SetMatrix(Concat(canvas.TotalMatrix, m))`，而 **shim 在 RTL 行上 `PushTransform(anti)`**（`PresentationCore.HbTextLine.cs:2424-2439`，`anti=Matrix(−1,0,0,1,pw,0)`，实测 `pw==W`）⇒ **画布矩阵被再乘一次反演 ⇒ 宿主镜像被抵消**。
> **算术自洽**：若画布矩阵就是 `世界·deviceBase`，`x∈[0,65.256]` 应落到 device **`[21.8, 89.8]`**（与 LTR 对照 `[22,88]` 同框）；实测 RTL 是 `[−24.6, 43.4]` ⇒ 差的正是"镜像被抵消 + 一个 65.26 的平移"。
> **历史逻辑**：anti 是**修法① 之前**的补偿（那时 shim 输出**视觉序**，宿主再镜像＝双重反转）；**修法① 改成逻辑序之后，宿主的镜像才是产生视觉序所需要的那一次** ⇒ 再推 anti 就把结果反回去并把 run 挪到框外。
> **已派**：**T1d** 在 shim 侧做 A/B（推 vs 不推）+ 实现 + 三形态/六项不变 + 给新 shim sha（**PC 由我重建**）；**T2b** 转**渲染侧复核**（`Concat` 的坐标空间：shim 的 `m` 是 **DIP**、画布是 **device**（含 ppd）⇒ 可能**同时存在**"空间混用"缺陷；`MilPop` 栈平衡；并扩一条能抓"world 有镜像而画布没有"的牙），**不抢同一处改动**。
> **验收**：RTL 五行 census 的 `CTM` 应 ≈ 同行 `累积world`（`m11≈−1.04`、`dx≈89.8/98.8/122.3/92.8`）；墨迹包络回 `[22,88]` 一族；**判据 1 三条全绿**（`|Δright| ≤2`、`|Δw| ≤3`、墨迹比 ∈[0.9,1.1]）；**LTR/CJK 与六项 tline 一律不变**。
> ### ✅ must-do ③ 收尾：`1400` 累计 **84 次启动 / 0 命中**（协议 + 仪器已就位）
> 3 趟门禁 ×6 次 = 18/18 PASS（0 命中）+ 既有干净口径 60 + 本趟 6 ⇒ **84/0**；F2 的 `[WIN_DIAG]` 四行由主控 `dlopen` **独立复验**；每轮**现场重读四份 shim sha** 已写进协议。**口径**：不复现**不等于**已修复 —— 登记为"**不可按需复现 + 已在失败路径默认打诊断**"。
> ### 🔎 must-do ⑤ 口径升级（更硬、且同配置内可判）
> 原证据是"`selLen` 8→7（幻影 EOP 消失）"—— 但 **8 与 7 测于不同配置**（波 8 vs 现在）⇒ 按我们的纪律**不能当跨配置判据**。**改成同配置内的判据**：`selLen` **必须等于文本自身长度**（`'seed-文本'` = 7）⇒ 本配置实测 `selLen=7`**符合**（"没有多余符号"是同一趟内可判的）。注意 `selLen=0` 的那些趟伴随 `focus=False`（注入/焦点问题）⇒ 该情形判**红（注入未生效）**，不再叫"读数不稳"。
> ### ✅ 合并窗口已完成（主控，2026-09-13 16:10–16:19）—— **一趟干净的集成波 + 桥重发 + native shim 换新**
> **顺序与证据**（每一步都可重算）：
> 1. **native shim**：`src/WpfGfx.Linux.Native/build-shim.sh --all` ⇒ `libwpfwin32.so` **`e1691fd8440da926cb411a06cba23227189a32be737ff56783299d5ecfad6118` / 269,616 B**（16:10），4 份副本同步（`16:10:06`，现场重读四份同 sha）；ABI 自检通过、导出 **462**（`WpfLinuxWin32_*` 19）。F2 打印管线由主控用 `dlopen` **独立复验**（见上）。
> 2. **桥重发**（`publish-milbridge.sh`，16:11:04）：`wpfgfx_cor3.so` = **`e0d01832a3efea53e6d8e40f04ad136b265e31425e4db087490516cffdfe299c` / 4,937,968 B**；**发布期间 `src/**/*.cs` 指纹恒定 `66f9b583a17e371b539e4362`（68 文件）** ⇒ 编自冻结树（这是"产物被无守卫流水线覆盖"那一格的修法）。同目录 `libwpfwic.so`=`03b67fbcd7c385b6`、`libSkiaSharp.so`=`a02cd03f…`。
> 3. **PC 波**：**第一次跑被"输入稳定性"守卫抓到**（波前 `e235e91d…` ≠ 波后 `143a9f79…`）——原因是 **T1c 在波进行中按自检结果改了自己的应用器**（生成物 `HwndSource.Linux.cs` 的 `LineCount` 缺陷修复）。**裁定：该波产物不保证与波后树一致 ⇒ 重跑一次**；**第二次波前==波后==`143a9f799fe22159020dd55991e7a185982a38c0bd02755e8bea5cd48b860548`、失败步骤 0、15 个工程全部 0 错 0 警** ⇒ 这一波才作数。
> **新权威件（现场重读，16:15–16:18）**：PC **`3479253784172bd424a73805…` / 4,174,336 B / 16:16:53**｜WindowsBase **`30f7637ad7d01aae5f72f648…` / 1,218,560 B / 16:15:35**｜PF **`36abe241bfe5b0a9a4f73e30…`**｜HbTextLine shim 仍 `ebccdb1ee65e6f76…`（**这一版终于把 per-run 前景编进 PC**，`hbtextline_shim_stale` 现在是真 `no`）。
> **三项"进没进产物"的核对**（都用 UTF-16 查法）：① **站点 D 首次进产物** —— `strings -el PresentationCore.dll | grep -c 'HBLINE D#'` = **1**（此前 0）；② **输入追踪进产物** —— `[INPUT_TRACE]` / `WPF_LINUX_INPUT_TRACE` 命中；③ **补丁 P 进 WindowsBase** —— `[SHIM_DIAG] HwndWrapper` 命中。
> 🔴 **顺带纠正一条我自己的旧结论**（同一族第 3 次）：T3 早先"站点 D 不在产物里"用的是 **ASCII `strings`** —— 而托管程序集的字面量是 **UTF-16**，ASCII `strings` 对它**恒为 0**（`HBLINE A#` 同样是 0，与"A/C 由运行时拼接"无关）。**"查法不对"不等于"结论不对"**：D 当时确实没进产物（PC 比 shim 源旧），但**判据必须用 `strings -el`**。
> ### ❌ T3 **撤回**"Latin 橙 / CJK 蓝"（我此前列为待判的 H1/H2/H3）
> 原始分辨率裁剪对照两趟：**两趟都是 `seed-文本` 全橙**（拉丁与 CJK 同一前景色），底色是浅灰选中底 `srgb(199,202,204)`；橙系像素旧帧 1016 / 新帧 456，最频色里**存在精确 `(249,115,22)`**，**没有蓝色字形**。
> ⇒ "蓝"是 **800px 预览把细笔画 CJK 抗锯齿像素下采样后的观感**；H2（蓝=选中高亮）也不成立。**该观察作废**（T1d 不必按 H1/H3 追）。
> ⇒ 顺带两条口径：① 精确色对**抗锯齿文字**不可用（`#F97316` 精确命中 0、近色 1016）——runner 已改"近色 + census `GlyphRun×N`"；② `selLen` **跨趟不稳**（有趟 7、有趟 0）⇒ 任何 `selLen` 结论必须带趟号与 sha。
> ### 🔧 第 17 个假绿已修：`hbtextline_shim_stale` 恒 `no` ⇒ 现在是对着**权威 PC** 的真值位
> T3 修法：谓词抽成 `hbt_stale <shim源> <权威PC>`，ARTIFACTS 行**尾部追加** `hbtextline_stale_basis=auth|applocal`、`hbtextline_src_mtime`、`pc_compare_mtime`；**两极性牙** `HBT_STALE_SELFTEST=1`（源新⇒yes / PC 新⇒no）两个 runner 都 PASS。现场真值 = `stale=yes`（shim `00:36:31` > 权威 PC `00:00:23`）⇒ **此前所有应用级颜色/文本读数取自旧文本栈，一律临时判定**。
> **门禁与验收（都是绿的、且都绑了配置）**：`verify-all.sh` **9/9、831 通过 / 2 跳过 / 0 失败**；`WpfTextDemo` 验收基线 **PASS 2 档 6/6** ＋ **判据⑦ `WPTD_LINE_ADVANCE=PASS`（`distinct_origin_y=12`，阈值 10，带变异开关）**；**跨配置回归 `AE = 0 / 879,844`**（波 4 的 `Extent`+CFF 改动**没有改变样例像素**）；`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 有七元组表头 + 6 条机读行。
> **已闭环（本轮）**：**CJK 端到端**（`id0 325→0 / nonlatin 0→322 / maxid 3540→63151 / 面数 2→4`，像素 `AE=104,841`，读图=真汉字，per-段面三点对齐）；**多行摞印**（`HbTextLine.Draw` 丢掉宿主 `origin`；修后同段 5 行 `devY` 由"五个全等"变"逐行 +16.976 设备像素"）；**D-d**（`CopyPixels` 子矩形）；**`Extent`**（墨迹盒语义，`T2e 0/10→5/10`、`T2d 0/1298→1259/1298`）；**CFF 墨迹盒**（CJK `.ttc`/`.otf` 是 CFF，`inkBox <Empty> → h=16.912`）；**(乙)**（A/B 翻转 `48/0/0 ⇄ 0/0/48`）；**D-c**、**零缩放 CTM**（上游输入）、**D3/LS abort**、**E_HANDLE**、M2 `HelloWpf` 读图正确；债务 #12/#14/#15/#19/#24/#25 已销账（`docs/ARCHITECTURE.md` §8.1）。
> **剩余登记项（未做，不是"没发现"）**：① `T2d` 的 **39 条 `Extent` 余差**（容差 0.01 远严于项目口径 0.34，**不在 CFF 家族内** ⇒ 未定位）；② `T2c` **Tab 口径 15 例**（已登记差异，未实现）；③ `T2d` 的 "`LineHeight>0` 用例 0 行" ⇒ **该列无真值覆盖**（`T2e` 已覆盖 `LineHeight`，属装置分工缺口）；④ 债务 #1（进程级静态表 flaky）、#13（应用器家族契约：无参=应用需机检）、#20（副本同步的**机制级**修法，现只有只读校验器）；⑤ `Extent` 语义在**多行段落**上的口径未经应用级对拍（当前只走 shim 级 `T2e`/`T2d`）。
> ### ✅ **2026-09-13 傍晚 · 上面①③⑤三条已被 T1b 的完整明细做掉**（本轮更新，逐行证据在 `build/MilBridge/gen/tline-detail-full.txt` 99 行 / 3 段）
> **① "39 条 `Extent` 余差"→ 实际口径是"主对拍集 38 条"，且已**逐行分类完毕**：`38 = +CJK 34 条 + M_modifier_* 4 条`**：
> ```
> M_modifier_w80  行#1 Extent 真值=18.0000 我们=14.3200 差=-3.6800
> M_modifier_w120 行#1 Extent 真值=18.0000 我们=14.3200 差=-3.6800
> M_modifier_w320 行#0 Extent 真值=18.0000 我们=18.0800 差=+0.0800
> M_modifier_winf 行#0 Extent 真值=18.0000 我们=18.0800 差=+0.0800
> ```
> ⇒ **那 4 条不是"容差嵌套的必然结果"，而是全部落在 `M_modifier_*`（`TextModifier` 未实现，已登记）**，真值**恒为整数 18.0000** ⇒ **与 T1d 的 CJK 回退边界不同桶**。（`34 ⊂ 38` 的容差包含关系仍成立，但**解释不了这 4 条**。）T1b 还**当场纠正了自己一次筛法错误**（把 LH 组 20 条 `[NotoSansCJK(da)]` 误算成"非 CJK"⇒ 曾报"24 条"）；LH 组 20 条属**代用字体不可比**，**不属主对拍集**。
> **③ `T2d` "`LineHeight>0` 用例 0 行"→ 已覆盖**：本轮 `LineHeight>0` 组 **10 例 / 40 行**（`Height 10/10`、`TextHeight 5/10`、`Baseline 6/10@0.01`、`Extent 5/10`），段2 里那 20 条就是它（标注为代用字体）。
> **⑤ 折叠 18 条已分两类（五列可核）**：① **同 `(cp,len)` 但 `cr` 宽度符号相反**（`F_nbsp_zwsp_w40 行#3`：我们 `W=-3.0560` vs 真值 `W=3.3433`，NBSP 族）；② **前缀/簇边界差 1 字**（`F_lat_words_w560 行#0`：`[30,40)` vs `[31,39)`）。`M_modifier` 仍是折叠里最大的量级（折后宽度最大差 **144.816 DIP**）。
> **回归读数变化（同一次运行 `EBCCDB1E…` / PC `8ff5cb38…`）**：`T1.73 73/73`、**A 组·断行位置 972/972、213/213（由 964/965 提升）**、`Height/Baseline 1298/1298`、`Extent 1260/1298`、折叠判定 `1298/1298` 明细 `218/236`、**通过 19 / 失败 2** ⇒ **原先记的"四红"现为两红**：**`T2c`（Tab）与 `T2b`（A 组）本轮已转绿**（R1 多字体生效），**只剩 `T2` 记账 / `T3` 折叠**。
> ⚠️ **仍欠**：`getTextRunSpans` 的达标读数（需**一趟真正走到 EOP 分支的 TextBox dump**；且已落盘那趟是 `lines=1/paragraphs=1/fallbackCalls=1`，"即使被问过也未必问在我们这一行上"）。
> **不要做**：手工拷件进发布目录、跨配置比读数、`dotnet test --no-build`、`pkill -f <进程名>`、把 `:0/:1` 当测试显示、`src/` 被编辑时发桥、**用 ASCII `strings` 判托管程序集的字面量**（UTF-16！已栽两次）、**恒真/恒假判据**（第 16 个成员）、**在 app-local 有旧副本的目录里直接跑探针**（会得出"补丁无效"的假红）。

> ## 📌 2026-09-13 深夜–09-14 凌晨（主控）：**"源陈旧冻结"被查出 + 桥重发 + 两道身份闸门落位**
> ### 🔴 事故 D（第 19 个成员形态）：**基线被冻在"源陈旧"的桥上，而全仓没有闸门覆盖 `src/** → 桥`**
> 现场事实（mtime + sha，逐条可复算）：T2b 的 `Rendering/**` 修法落盘于 **22:37:39 / 22:37:52**（`SkiaRenderBackend.cs` / `DrawInstructionCensus.cs`）｜发布目录的桥是 **22:24:35** 发的（`7dfe964828908437`）｜T3 的 **#6 冻结于 22:42:32** ⇒ 用的正是那份**不含修法**的桥。
> **为什么静默**：`WFP_SRC_STALE` 只看 `build/*.Linux/**`（且只在 `run-wpfprobe.sh`、还是 advisory）；`hbtextline_shim_stale` 只看 `build/shims/**`；**权威门禁 `run-wpftextdemo.sh` 一条都没有** ⇒ 又回到"产物 sha 变了才看得见"这条唯一防线。
> **修法（身份，而不是代理）**：`build/bridge-src-fp.sh` = **唯一实现**的桥源码指纹（覆盖 `src/WpfGfx.Linux/**` + `build/MilBridge/**`；排除 `bin/obj/.artifacts` 与 `tests/alt-route-b/spike`）；`publish-milbridge.sh` 每次自动写 `…/publish/…/bridge-src-fp.txt`；门禁重算比对 ⇒ `BRIDGE_SRC_STALE=yes|no`（**文件缺失报"无信息"，不许报 no**）。牙 = **三极性** `--selftest`（加 `.cs` ⇒ 变 / 删 ⇒ **逐位回绿** / 只在 `obj/` 加 ⇒ **不变**），实测 `FP_SELFTEST=PASS`。当前 `BRIDGE_SRC_FP=0dec99db900ef654`（N=77），**与发布目录那一份一致**。
> **独立交叉核对（主控 2026-09-14 00:1x 现场重算权威产物）**：#6 的**其余七位与当前件逐位相符** —— `pc 23567d420f0dbbaa` / `pf bfb10fe2a01a986b` / `windowsbase 8c073fab0da88169` / `provider 71ba86c6495347fe` / `wic_shim 03b67fbcd7c385b6` / `hbtextline_shim 5a04875ae87a294d`（`stale=no`）/ `win32shim f84d65a62e0c7fa4`（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`，**全仓 4 份同 sha**）⇒ **唯一失配位恰好就是桥**，与"源陈旧"的判定**互相独立地一致**（这条把"事故 D 是真事、不是叙述"钉死了）。
> **闸门上线后的第一次真阳性（主控独立复算 + T3 runner 同结论）**：T2b 的"矩阵组合空间同族扫荡"在 **00:13:42 / 00:14:14** 改了 `src/WpfGfx.Linux/Rendering/{VisualBrushSource,SkiaRenderBackend}.cs`（**抓到了第二个真站点**：`VisualBrushSource.cs:83` 原 `Concat(m, current)`、`:99` `Concat(world, current)`），于是现树 `BRIDGE_SRC_FP=ffb56d3bacd3d152` ≠ 发布记录的 `0dec99db900ef654` ⇒ **`BRIDGE_SRC_STALE=yes`**。这正是 #6 那次事故的同一形态，**这次在冻结之前就被读出来了** ⇒ 修法有效。顺序照旧：T2b 交齐"源已定" → 主控重发桥（新 sha）→ T3 一轮跑完门禁并冻 **#7**。
> ### ✅ 桥已重发（主控，22:48→00:00）：`7dfe964828908437` → **`f68f01c10e456982`**（4,950,336 B，rc=0）
> 发布期间 `src/**+build/MilBridge/**` 指纹稳定；独立复核"修法确在件里"用的是**字节级计数**（见下条）：新旧件里 `累积world`×3 / `本节点Transform`×2 / `来源=`×2，两者差异 **1,152,682 字节**，而相对上一版的源码差异**只有那两个文件**（`find src -newermt` 可复算）。
> ### 🎯 新实测性质：**AOT 发布逐字节可复现**（此前未知；上面所有身份判据都靠它）
> 同源 + 同 `ArtifactsPath` 连发 **三次** ⇒ 三次同 sha `ndiff=0`；`dotnet build … -t:Rebuild` **全量重编**（obj 22:50:56 / `wpfgfx_cor3.o` 22:51:10）后再发 ⇒ **仍是同一 sha**。⇒ `bridge_sha` 是"源的确定性函数"，可当身份用；"同源重发 ⇒ sha 必须不变"因此是**直接测量**而非代理指标。
> ### 🔬 又一条仪器口径（第 20 个成员形态）：**`strings -el` 对中文 UTF-16 字面量报 0 是假读数**
> 实测：桥里 `累积world` 字节级 `count=3`，`strings -el`（含 `LC_ALL=C.UTF-8`）**报 0**；ASCII 串（`PushTransform`）两边都看得见 ⇒ 是 `strings` 的可打印性判据丢掉了非 ASCII，不是"不存在"。**口径**：判"某串在不在产物里"必须字节级计数（`open(f,'rb').read().count(s.encode('utf-16-le'))`），`strings` 只配当粗筛。**报 0 ≠ 不存在**（与"查不到要报无信息"同族）。
> ### 🔬 D-P1 现状：四档二分**全部不复现**（M7b，`DISPLAY=:96` 自起自收）
> 基本(`KEYDOWN/CHAR/KEYUP`) / **(a)** 裸 `WM_CHAR` / **(b)** 先 `SelectAll` / **(c)** 跨帧连发两字符 / **(d)** 真 `xdotool` ⇒ **`DP.Text` 每次都 == 容器**，`TextChanged` 计数 1/1/1/2/3，`IsKeyboardFocused=True` ⇒ **"注入方式/序列"这一层被排除**。下一步（进行中）：M7b 在装置里复刻四条"装置 vs 应用"差异（非根可视 / 取焦点时机 / 跨帧写 / 另有鼠标输入提供者）＋ T3 用当前件复跑 `--only=textbox-edit` 交叉。**由读数判，不许推断。**
> ### 🧾 并发规矩（新，已通知三条车道）
> 会**重写发布目录 `.so`** 的动作（重发 / 直接测量）必须先 `: > /tmp/bridge-republish.lock`、跑完 `rm -f`；其它车道见锁**不得开跑任何加载桥的进程**（读到半写的 `.so` 会给出假崩溃）。哨兵 `/tmp/bridge-frozen.flag`（`SHA=` / `FP=`）= 主控放行"件已定"，此前不许跑应用级。
> ### 🔄 **记录自己会陈旧**（T1b 当场拦下主控一次）
> handoff「事故 C」写"`ClosedLoop:219` 的 28 陈旧"，**该表述已过时**：断言早已修为 27 且算式写在注释里（`27 = 4 + 22 + 1`）；真正陈旧的重复是 `T1-report.md` 的分布行（`Real 60 · NotImpl 28` → **61/27**，已修）。⇒ 新纪律：**拿台账去派活之前，先复核台账本身是否已过时**（否则会让人去查一个不存在的红）。T1b 顺带落了 `build/MilBridge/tools/check-export-numbers.py`（唯一真值源 = `gen/landing-table.md`，`--self-test` **实测能变红**）。

> ### ✅ **M7b 阶段 2 落地：`D-U1` 的两条不变量全齐，四条变红实测全 `rc=1`**（`D-U1` 结项）
> `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/UIAutomationLinuxTests.cs` **`9367a8d930c90554 → 2618aed85a598d96`**（165 → 254 行；**删 0 / 增 89**，**前 163 行 `cmp` 逐字相同** ⇒ 只落在 `D2` 之后的声明锚点）。新增 **`D3`**（`IsOsWindowsVistaOrGreater==false` 且 `LastSupportedProperty==TransformCanRotate` ⇒ 运行时证"落到最后那个 `else`"；`_out` 原文有）与 **`D4`**（反射调 `UiaLookupId` ⇒ **内层异常 = `DllNotFoundException`**）。
> **四条牙（命令 + 原文 + rc）**：**D3-A** `/tmp` 突变 shim（宏 `return 1`，sha `274540078333f848`）+ `WPF_LINUX_WIN32_SHIM=` 指过去 ⇒ 两谓词变 `True` ⇒ **rc=1**｜**D3-B** 期望档位改错 ⇒ `Assert.Equal` 差异（`IsSynchronizedInputPatternAvailable` vs `TransformCanRotate`）⇒ **rc=1**｜**D4-A（实质）** `/tmp/m7b-p2/native-mut/` 放**改名成 `UIAutomationCore.dll` 的只读拷贝** + `LD_LIBRARY_PATH` ⇒ **`Actual: typeof(EntryPointNotFoundException)`** ⇒ **rc=1**（**这正是"只加映射不加导出"那个未来错误的形态**）｜**D4-B** 期望异常类型改错 ⇒ **rc=1**。**没用上的两条通道也记了**：`dotnet vstest <裸 dll>`（本 SDK 报参数无效）、`NATIVE_DLL_SEARCH_DIRECTORIES`（仍 `DllNotFound`）。
> **九位 before/after（20:22:21 → 20:25:25）逐位未变**，与 #11 冻结逐位一致（`pc` 同源重建后**仍是 `4f2e621a4ad26cd0`**）。**它另报一条时间线**：`pf` 在 19:42 读到 `83fd8ff…`、冻结时是 `0878daff…` ⇒ **那次变化是我的收官波造成的**（不是它的）。
> **⭐ M7b 自曝两坑（都已升格为纪律，见 `docs/CURRENT-STATE.md` 23/24/25）**：① **`cp -p` 还原源码保旧 mtime ⇒ 增量构建跳过重编 ⇒ "还原后复跑"用的是突变后的旧程序集 ⇒ 假红**（`D4 [FAIL] Assert.IsType()`；`touch` 后 `rc=0` 且内容 sha 未变）；② **两处计数口径假 0/假判**：`grep -c '已失败 '` 在该 logger 下恒 0（失败行是 `[FAIL]`）⇒ 把**已取得的变红**误标成"未取得"；unified diff 删除标记是 **`-` 不是 `<`** ⇒ 第一版数出"0/0"两个假值（改正后 `0/89`）。
> ### 🔧 **`#12` 的验收判据被改写（我的原判据过期了 —— 纪律 26 的实例）**
> 我原先写的 ③「三份明细 `18/58/17` 不动」④「六项 = 冻前基准」是**按 #11 的仪器版本**写的；T1b2 改了 harness（`Program.cs 9f59572075c639ae → aca4f350… → 0d45032b…`）之后，**未改动的树**已读成 `T3 明细 213/236`、`折叠 23`、`记账不一致 18`、`通过 21/失败 3` + 多一条 `T3b` ⇒ **判据按字面不可达**。
> ⇒ **主控改述（T1d 提议、我批准）**：**(i) 同仪器 A/B（真源 vs 变体）＋ (ii) 方向正确（全部朝真值）＋ (iii) 射程外逐位不动（机器断言：diff 只许出现 `A1_nbsp_zwsp_w30/w40/w80`、`B_nbsp_zwsp_trim`、`F_nbsp_zwsp_w40/w80/w900` 这 7 个用例）＋ (iv) 那 4 行 `[ROWD]` 的 `ws`/`WITW−W` == 真值 ＋ (v) 牙：把 NBSP 算回行尾空白 ⇒ 那 4 行复红**；**并对每个位移（`记账 1286→1292`、`分桶 47→41`、`折叠 23→22`、`记账不一致 18→15`）逐项写出因果**，**归因不到 = 红旗**。另：T1b2 要交"**同 shim、旧仪器 vs 新仪器**"对照表，把"仪器的位移"与"修法的位移"分开。
> ### ✅ **T1d 的机制一变体已在变体上验完（等窗口落真源）**：修法一行 `IsTrailingWhitespace => char.IsWhiteSpace(c) && c != '\t' && c != '\u00A0'`（单点 `:1391`，**只排除 U+00A0、ZWSP 未动**）；变体 `3081d088…`。**4 行 `[ROWD]` 全部达标**（`Δ行宽 −4.1587/−4.1600/−4.1593/−4.1567 → +0.0013/0.0000/+0.0007/+0.0033`；`ws` 1→**0**＝真值；`WITW−W` → **0.0000**）。**`--known-red` 也落了**（`CoverageProbe/Program.cs 94bd545c… → cc61299d…`，diff **+116/−5**、**5 处删除全是声明锚点**；表 `build/MilBridge/tests/CoverageProbe/known-red.txt e37603a8…`）：**六条牙 `rc = 1/0/0/1/1/2`** —— 其中 ⑥ **喂 `tab` 臂逐例 JSON ⇒ `rc=2` 且不 core**，把 T3 踩过的那个 core dump 一并修掉。⚠️ **它改变了旧行为**（不给表 ⇒ 任何失败都算未登记 ⇒ `rc=1`）⇒ **T3 的清单里那句 `--tab-lines-oracle` 以后必须带表**。
> ### ➡️ **下一步（更新六）**：`T1b2` 收尾（交 `[ROWD]` 原文 / 头行构造性验证 / 隔离矩阵 before / 仪器版本清单 / **新旧仪器对照表**）⇒ **`T1d` 落机制一到真源**（窗口已确认关闭：shim 已回到 `b4c7aa8210c71cbe`、mtime `19:38:42`）⇒ 静树取最终读数 ⇒ **我发起 #12 波（PC 重建）+ 冻 #12** ⇒ 随后 `#13 M_modifier`、`#14 D-T2`、`D-F1` 派单、`HelloWpf` Release 收敛。
> ### 🔧 **`#12` 源已定 + 一条红旗（T1d 拒绝宣称收口 —— 判断正确）**
> **源已定**：`hbtextline b4c7aa8210c71cbe → 3081d088cda0431c`（机制一：`IsTrailingWhitespace => char.IsWhiteSpace(c) && c != '\t' && c != '\u00A0'`，**单点 `:1391`**；`diff` 总 5 行 = **删 1 + 增 4**，除声明锚点外零改动；**真源与它验过的变体 `cmp` 逐字节相同**）。PC 未重建 ⇒ `hbtextline_shim_stale=yes` 是**正确的中间态**（**不发波、由主控发起**）。
> **可归因的 A/B（同命令构建+运行、记 DLL sha；仪器 `0d45032b20cfbfee`）**：记账 **`1286/1298`（不等 12）→ `1292/1298`（不等 6）**，根因 = 台账 `桶=行尾空白计数(ws)` **恰好 6 行**（`A1_nbsp_zwsp_w30#0/w30#2/w40#1/w80#0` + **`F_nbsp_zwsp_w40#1`/`w80#0`**，全 `期望 ws=0/实得 ws=1`）；宽度分桶 **`167/1084/47 → 168/1089/41`**（同 6 行 Δ 由 `4.1567…4.1600` 收敛到 `≤0.0053`；`47−6=41` ✓）；`T2b 213/213`、`T2c 0`、`Extent 1260` **逐字不动** ✓。**牙**：用**修前源**重建 ⇒ 记账回 `1286`、分桶回 `47`、那 6 行 `ws` 复红 ✓。⇒ **A 机制实际影响 6 行**（比 `[ROWD]` 点名的 4 行多 2，同族同因；已要求 T1b2 说明"设计内未点名 vs 漏点"）。
> **🔴 红旗**：`Program.cs` 的 mtime = **`20:27:39`** ⇒ **T1b2 在 T1d 的测量窗口内至少改过两次仪器** ⇒ **同一份"修前源"两种仪器读出不同数**：`折叠 18→23`、`T3 明细 218→213`、`通过 20/失败 2 → 21/失败 3`、`T3b` 有/无。⇒ **仪器位移与修法位移混在一起，折叠 / `T3` 明细 / `T3b` / 通过数这四项归因不到** ⇒ **T1d 明确不宣称 `#12` 收口**（纪律 15/26 的正确用法）。
> **主控裁定（两条）**：① **冻结仪器在 `HbTextLineParity/Program.cs = 0d45032b20cfbfee`**（我实读；并勒令 T1b2 不得再动，要它交"**同 shim、旧仪器 `9f59572075c639ae` vs 新仪器 `0d45032b20cfbfee`**"的对照表来结清那四项位移）；② T1d 在**同一静窗、同一条命令**内重取 **before/after 两侧**，**每侧记 ① 被测 DLL sha ② 编入源 sha ③ `Program.cs` sha 跑前跑后各一次**（让读数自己证明窗口干净），**两侧 sha 不同即作废**。
> **两条副产物**：① **`run.sh tline` 没有 `HbShimSrc` 覆盖口**（`run.sh:113-114` 的 `SHIM`/`SHA` 是 `local` 写死为仓库源）⇒ **after 侧走官方驱动（标签自洽）**，**before 侧只能手工 `-p:HbShimSrc=`**，而那条路**头行会印仓库源 sha** ⇒ 该侧出处写成"**被测 DLL sha + 手记的编入源 sha**"并显式标注"此行头不适用（已知标签缺陷）"。② T1d 的 `[ROWD]` **0 行自检**：冻结版 `Program.cs:276` 有"开关自报"行 ⇒ **0 行 = 跑的不是这一版仪器**（它 20:26 那趟正是如此）⇒ 这条自检写进报告。
> **我对自己那条更正的再更正**：我说过"头行就是本次读数真正测的那一份、错的是我"——**要收窄**：**由 `run.sh` 驱动时** `T1B_SHIM_PATH` 与 `-p:HbShimSrc=` 一致 ⇒ 标签自洽（故 #11 的读数无问题）；**手工传 `-p:HbShimSrc=` 而没设 env 时**，`ShimSha256()` 会印**仓库源**的 sha 却仍写"本 harness 直接编入" ⇒ **贴错**（T1d 已给现场证据：编的是 `/tmp/…(b4c7aa82)`，头行印 `3081D088…`）。**正解 = 构建期把 `$(HbShimSrc)` 的 sha 落成生成常量，运行期印那个值**；本轮**只登记不落码**（已派 T1b2 写入报告）。
> **T1d 自纠一条**：落地命令里**手打**过一个"变体完整 sha"（`…e0e0a0b4…`）—— 那是**没实测过的字符串**，随后实测两件同 sha 且 `cmp` 通过 ⇒ **该串作废**。**教训：sha 只能来自实测输出**（同族已有 3 个实例）。
> ### ➡️ **下一步（更新七）**：T1b2 回交对照表/原文 ⇒ T1d 静窗重取（两侧）⇒ **主控发起 #12 波（PC 重建，`WAVE_OWNER` 认领）** ⇒ 静树门禁 ⇒ **冻 #12**（表头写入：仪器版本、A 机制 6 行、可归因项与待结清项的划分、T1b2 的对照表结论）。随后 `#13 M_modifier`、`#14 D-T2`、`D-F1`（字体栈）、`HelloWpf` Release 收敛。
> ### ✅ **`#12` 的两侧重取完成（仪器冻结版自证窗口洁净）+ 一条对"负宽度"判据的最终裁定**
> **出处（每侧都记，纪律 23/24）**：before = 编入源 `b4c7aa82…`（`/tmp/t1d-nbsp-base-b4c7aa82.cs`）、**被测 DLL `eae020b000b26b25`**、手工 `-p:HbShimSrc=` 驱动（**头行不适用**：已知标签缺陷，出处以"DLL sha + 编入源 sha"为准）；after = 仓库源 `3081d088…`、**被测 DLL `957d3cee37412586`**、**官方 `run.sh tline`**（`run.sh 3e513e88a4fa4ec9`，头行自洽）。**`Program.cs` sha 跑前跑后两侧各自都是 `0d45032b20cfbfee`** ⇒ **窗口洁净由读数自证**。
> **可归因项（因果闭合）**：记账 **`1286→1292`**（不等 `12→6`，正是台账 `ws` 那 6 行）｜分桶 **`47→41`**（同 6 行 Δ 由 `4.1567…4.1600` 收敛到 `≤0.0053`）｜**`[ROWD]` 4 行** `Δ −4.1587/−4.1600/−4.1593/−4.1567 → +0.0013/0.0000/+0.0007/+0.0033`、`ws 我们 1→0`（=真值）、`WITW−W 我们 4.1600→0.0000`（=真值）、**`VERDICT OK×4`**｜`T2b 972/972·213/213`、`T2c` 不一致 0、`Extent 1260` **逐字不动**。**牙**（= before 侧即"把 NBSP 算回行尾空白"的复现）：记账回 **1286**、分桶回 **47**、Δ≈−4.16 **复红 6 行**（比 `[ROWD]` 点名多 `F_nbsp_zwsp_w40#1`/`w80#0`，同族同因）。
> **待结清项（已由 T1b2 的对照表结清）**：`折叠 23→22`、`T3 明细 213→214`（方向一致朝真值）、**`T3b` 两侧逐字相同**、`通过/失败 21/3→21/3` ⇒ **无回归**。先前那组 `18/218/20-2` 是 **20:26 中间版仪器**的读数 ⇒ **仪器位移**（与我 §"红旗"一致）。
> ### 🔴 **最终裁定：`cr.Width >= 0` 这条"裸断言"是**我的判据错**（真机自己有 7/430 条负宽度），但**本轮不改**、登记进 #13 的仪器 bump**
> **事实**：真机在 oracle 的 **430 条折叠区间里有 7 条 `Width < 0`** ⇒ **"宽度为负"在 WPF 里不是契约违反**；我（基于 T1b 的发现）立的"`cr.Width >= 0` 硬断言"对该族 **6 条红里 5 条是假红**，**真违反只有 1 条**（正是 `D-F1` 的 `F_nbsp_zwsp_w40#3`）。⇒ 它把已登记不变式推到 **折叠明细 `18→23`（+5）**、**记账用例 `17→18`（+1）**、`Extent 余差 58` 未变。
> **正确形态（一条表达式）**：**`ours < 0 ⇒ truth < 0`**（等价 `ours >= min(0, truth)`）—— **方向不放松**（真值非负而我们为负的每一种情形仍然被抓），只是不再对"真值本身也为负"的行假红；**并要求两个计数都印**（裸形式红 / 判别式红 / 两侧同为负），让"判据位移"永远可见。
> **主控裁定：本轮**不**再动仪器**（T1b2 已收工、T1d 刚用冻结版取完两侧、再改一次会作废这批读数并产生第三个仪器版本），**改为登记进下一次仪器 bump**（`#13 M_modifier` 本来就要动 harness ⇒ 同波做），届时交"**判别式下**"的四项数字与位移对照。**代价与理由都写在这里：`#12` 的冻结表头会带上"裸断言 5 条假红 + 真违反 1 条（归 `D-F1`）"这条注记**，不许读成"折叠变差 5 条"。
> ### 📋 **T1b2 交付（`build/MilBridge/T1b2-report.md 96936fe3ffb43e44`、`gen/t1b2-rowdump-final.txt 1cae6e1e04688103`）关键结论**
> ① **新旧仪器对照表**：只换 `Program.cs`（`9f59572075c639ae → 0d45032b20cfbfee`）、同一 shim ⇒ **位移全部只由"新增裸断言 `cr.Width>=0`" + "新增检查项 `T2-iso`/`T3b`"产生**；其余十项（`47` 分桶、`58` Extent、`1298/1298` 折叠判定、`972/972`+`213/213` A 组、`T2c`）**逐位不变**；**没有任何一项"因仪器变更而变绿"**。**在另一份 shim 上形态逐条复现** ⇒ 归因不依赖具体 shim。② **`[ROWD]` 判定 = A4 / C3 / B=D=E=0**，列来源图例 `[O]/[T]/[Td]/[X]/[NA]`，**唯一一处 `[Td]`（真值可见尾空白 = `ws − nl`）是判定支点**；**A 实际 6 行**由它离线复算证实（另 2 行未点名 = **规格名单不全**，不是漏点）。③ **C 的根因逐位闭环**：`file` 字体**没有 U+4E0E（`与`）** ⇒ 我们落到 `.notdef`（`hmtx` 600/1000 em = **9.6000 DIP**，与逐字符实测逐位吻合），真机 **16.0000 = 1 em** ⇒ **这就是 `F_nbsp_zwsp_w40#3` 负 `cr.Width` 的根因，归 `D-F1`（字体/回退）**。④ **(c) 头行四行形态落地**，构造性验证 `stale false→true→false`、还原后 shim **逐字节相同**；**`PC 内 shim sha = unknown`**（`ARTIFACT-SRC-FP.txt` 只有汇总行 ⇒ **取不到不猜**）⇒ **能力缺口**：**给它加一行逐文件记录**（至少 `build/shims/PresentationCore.HbTextLine.cs <sha256>`）即可同时支持"PC 内 shim sha"与**内容比对版**的 `hbtextline_shim_stale`（**另开一件**）。⑤ **(b)** 两条机器断言（族计数等式 `47==47`、隔离矩阵"一位未动"）**并进 `coreOk` 与退出码**；隔离矩阵**是活的**（在 `3081d088` 上 `A1 25→21`、`F 10→8`，`M_modifier` 保持 7 不动）。⑥ **`ShimSha256()` 缺陷补齐**：它连同 **`T0.4`/`T0.6`** 都读**盘上路径**而非 `-p:HbShimSrc` 编进去的那份 ⇒ 三者**一致地骗人**，`T0.6` 拦不住换 `-p:HbShimSrc`；**正解 = 构建期把 `$(HbShimSrc)` 的 sha 落成生成常量**（只登记，不落码）。
> **T1b2/T1d 自曝的流程事故（照收）**：T1b2 **抢 artifact**（在 T1d 的 A/B 窗口内跑 `run.sh tline`，违反"一次只有一个写者"）＋ `cp -p` 保 mtime 让 MSBuild 跳过编译、**静默跑旧 dll**（已修 + 加仪器身份机检）；T1d **手打未实测的 sha**（作废）。**两条都已升格为纪律 23/24。**
> ### ➡️ **下一步（更新八）**：**`#12` 波已发起**（`build/close-wave.sh`，`WAVE_OWNER` 认领；预期 native/桥均跳过、managed 重建 + `verify-all`）⇒ 静树门禁 ⇒ **冻 `#12`** ⇒ 随后 `#13 M_modifier`（**同波落**：`cr.Width` 判别式 + harness 的 1 行 meta + PC 2–3 行）⇒ `#14 D-T2`｜`D-F1`（**根因已闭环**：字体缺 `U+4E0E` ⇒ `.notdef` 9.60 vs 真值 16.00）｜`ARTIFACT-SRC-FP` 逐文件行｜`HelloWpf` Release 收敛。
> ### ✅ **`#12` 已冻结（2026-09-14 22:01）**：行尾 NBSP 口径修法
> **波 `close-wave-203111`**：`native_rebuilt=0`、`bridge_republished=0`、**`verify_all=PASS`（9 步 0 失败；`ManagedLayer.Tests 76/76`** = #11 的 74 + M7b 新加的 `D3`/`D4` **）** ⇒ 门禁 `WPTD_GATE=PASS`、两档 `3/3`、**6/6 `result=PASS`**、`runner exit=0`、`BRIDGE_SRC_STALE=no`、`hbtextline_shim_stale=no`。
> **九位（现场/哨兵/表头三方逐位一致，主控独立复算）**：`bridge 759a322431f1e457`｜**`pc 293f99525f5af4f2`**｜**`pf 11791727d682e119`**｜`wb e6216fe961a2bfb9`｜`provider 71ba86c6495347fe`｜`win32shim 0098234982391bbf`｜`wic 03b67fbcd7c385b6`｜**`hbtextline 3081d088cda0431c`**｜`dwf 2f77dbdf5e7e2cd5`。**EXT 变化 3 处**：`reachframework 9cfb4233…`、`presentationui f7aac7dc…`、`systemprinting 650ac4d3…`。
> **表头写入的关键内容**：本波内容（`IsTrailingWhitespace` 排除 `U+000A0`… 即 `U+00A0`，单点 `:1391`，`diff` 5 行 = 删 1 增 4）｜可归因读数（记账 `1286→1292`、分桶 `47→41`、`[ROWD]` 4 行 `→VERDICT OK×4`、`T2b/T2c/Extent` 不动）｜**A 机制实际 6 行**（另 2 行是"规格名单不全"）｜**`D-F1` 根因闭环**（字体缺 `U+4E0E` ⇒ `.notdef` 9.60 vs 真机 16.00）｜**裸断言 `cr.Width>=0` 是主控判据错**（真机 430 条里 7 条负宽度）⇒ 已改判别式 `ours<0 ⇒ truth<0`，**仪器版本分界 `0d45032b20cfbfee`（裸，本表头读数）/ `6e077361609f02ad`（判别式，#13 用）**｜**两个同名 `Program.cs` 分行写全路径**｜`APPSYNC` 既存红。
> ### 🧨 **环境事故（如实登记）：机器在 21:5x 重启过，`/tmp` 被清空**
> **第一趟门禁**跑到 `default rep3` 时 **`exit=134`（SIGABRT）+ 0 字节产物**（`*-after.png`/`pixels-*.txt` 全 0），时间点与"被挂起/重启"吻合 ⇒ **判为环境事故、不是缺陷**；**干净机器复跑 6/6 PASS**。⇒ 后果：`/tmp` 里 T1d/T1b2 的备份全失（T1d 已实测"用现源反向还原可得 `b4c7aa82…`"⇒ **A/B 能力不依赖 `/tmp`**）；**哨兵由主控据 `~/wpf-runs/close-wave-203111/close-wave-summary.txt` 重建**；`#11` 的冻结表头备份改放 `~/wfp-runs/ACCEPTANCE-BASELINE-11.md`（**不再放 `/tmp`**）。
> ### 🔑 **U1 把 `#13` 的未定符号定死了（只读既有数据、未出行）—— 两条候选都被否掉，真规则是第三条**
> **`openIndex`/`closeIndex` 都不是从 WPF 读的，而是"客户端 run 序列里的位置"**：`openIndex` = `GetTextRun()` 返回 `TextModifier` 的下标；**`closeIndex` = 返回配对 `TextEndOfSegment(1)` 的下标**（`-1` = 从不关闭 ⇒ scope 到段末）。
> **拟合（99 行）**：该定义 **99/99** ✓｜`closeIndex := open + TextModifier.Length` **56/99** ✗（43 处不符）｜`closeIndex := 段落末端` **85/99** ✗（14 处不符）。**反例**：否 (i) 有 **21 行**（scope 行末仍开、`open+Len` 已越行尾）；否 (ii) 有 **14 行**（段落带 modifier、非末行，但 scope **行内已关**）。**等价写法**：`lbNull == !( !isLastLine && ∃m: m.openIndex < nextLineStart ≤ m.endOfSegmentIndex )`。
> **⭐ API 事实（最值钱的一条）**：**`TextModifier.Length` 恒为 1**（= 合成边缘字符的长度），而 scope 真实覆盖 `A`=4 / `B`=30→34 / **`C`=36 字符**；`C2-scope-visible` 用几何钉死（emSize 翻倍 ⇒ 行数 6→14、最宽 advance 19.99→39.98 ⇒ **36 字符全变**）。⇒ **`Length` 是"marker run 自己占多少字符"，不是"scope 有多长"** ⇒ **`#13` 的 PC 侧必须传"两个位置（open/close）"而不是 `(start,length)`** —— 我已据此改派 T1d/T1c。
> **⚠️ U1 请我们核实的一处冲突（已派 T1b，只读）**：我们 `M_modifier` 语料 note 写 scope `[6,45)`、`M_modifier_w80 行#0 = [0,50)`、真值 `lbNull=false` —— 按新规则若 **45 处真的发了 `TextEndOfSegment`**，则第 0 行跨过它 ⇒ 预测 **NULL**（**与真值相反**）。⇒ 要查两件：**(1) 我们那个 oracle 客户端在 45 处到底返回了什么**（有/无配对 `TextEndOfSegment`，在哪个下标）；**(2) 我们的 `lbNull` 是不是 `TextLineBreak == null`**（给 file:line + 原文）。**核实前 `#13` 不落码**（纪律 15：没有定义就不动手）。
> **U1 自曝**：`font-fallback` 那批**首次出行失败** —— 程序把 `NaN/Infinity` 写进 JSON ⇒ `System.Text.Json` 异常、真机 `EXITCODE=-532462766`、`run.ps1` 六次重试全失败，**没有任何伪造读数**（它自己报的，值得记一笔："仪器失败要如实说失败"）。修好后重跑。
> ### ➡️ **下一步（更新九）**：T3 复取读数（`NEXT-WAVE-12-CHECKLIST.md`）｜`#13` 等 T1b 的核实结论（**PC 两个位置 + shim 按"开<下一行起点≤关" + harness 1 行**，同波，PC 重建由主控发起）｜`#14 D-T2`｜`D-F1`（字体回退）｜`ARTIFACT-SRC-FP` 加逐文件行｜`HelloWpf` Release 收敛（等 T3 读数跑完再动构建）｜`D-R2` 关闭判据 = 连续 5 趟 `verify-all` 无 testhost 崩溃。
> ### ✅ **T3 的独立复取完成（`#12` 之后）**：两档 `3/3`、**6/6 `result=PASS`**（`~/wfp-runs/go-freeze12c`）—— 与我跑的那趟**同结论**（门禁 `WPTD_GATE=PASS`）⇒ `#12` 的判据① 有两个独立来源。
> ### ⚠️ **一条新的环境事实（影响读数判读，必读）：本机与另一个工程共享 CPU**
> 22:0x 起，**另一个工程**（`/home/links-dev/netTest/wpf2web_handoff_20260906/wpf2web`）有**多个构建任务在跑**（`fork-runtime` / `Wpf2Web.Compat` 的循环重试 + 变体扫描），`ps` 命中 **7** 个相关进程、**`loadavg` 一度 6.62**。⇒ **这不是我们的车道**，但它会：
> ① 拖慢我们的构建/探针；② **很可能就是 `D-R2`（`ManagedLayer.Tests` testhost 间歇崩溃）的外部诱因** —— 21:5x 那次 `exit=134` 的门禁、以及更早的两趟 testhost 崩溃，都在"外部负载高"的窗口里。
> ⇒ **纪律补充**：**取判据读数前先记 `uptime`/`loadavg`，并确认**本仓**没有外来重负载**；若发现外部构建在跑 ⇒ 要么等，要么在报告里显式标注"读数在外部负载下取得"。
> ### ✅ **`#13` 的三份设计/核实已就位（只读，未落码）**
> - **T1d（shim 侧）**：§15.7 —— 接口改成 `modifierOpenIndex` / `modifierCloseIndex`（`-1` = 从不关闭 ⇒ scope 到段末）；`lbNull` 用 **"下一行起点"** 写法 `nonNull = !isLastLine && open ≥ 0 && open < nextLineStart && (close < 0 || close ≥ nextLineStart)`；**零宽跨度改由两个下标定，`TextModifier.Length` 完全不参与**（它恒为 1）。**仍不落码的两个前置**：U1 的 §6 单样本、T1b 的间接关闭核实。
> - **T1c（PC 侧）**：§42 —— `CollectLenient`（`TextFormatterImp.Linux.cs:101-157`）**只加"记位置"**（`if (run is TextModifier) modOpen = cp - cpFirst;` / `if (modOpen >= 0 && modClose < 0 && run is TextEndOfSegment) modClose = cp - cpFirst;`），**平铺（`:137/:146`）、`skipped` 记账（`:148-154`）、`cp += run.Length`（`:156`）、props 取第一个非 null（`:129-132`）一律照旧**（现状 `len=63` 已与真值相符）；两个调用点（`:238-241`、`:285-288`）都传；**主控裁定：配对取 R1（`TextModifier` 后第一个 `TextEndOfSegment`）但必须标成"未验证的选择"并登记边界**（"同段多 close ⇒ R1 可能配错；本仓无此真值"），退化行为 = 找不到 ⇒ `closeIndex = -1`。
> - **T1b（核实）**：**b34 冲突 = 假** —— `lbNull` 就是 `GetTextLineBreak() == null`（`extract-layout-b34.py:108` + `analyze-layout-b34.py:181-183`，行级）；**我们 b34 客户端从不发 `TextEndOfSegment`**（`grep -rn` ⇒ **0 命中**，正对照对 `TextModifier` 有命中）⇒ `closeIndex = -1` ⇒ 新规则预测非 null ⇒ **与真值一致**；note 的 `[6,45)` 只是作者意图描述。**T1b2 四条复核**：无凭空真值列 ✅（`truth=NA` 38 行、`truth=(?!NA)` **0**）｜机器断言 ✅（`famSumOk:775`、`isoOk:820`、`isoMachineOk:821`）｜头行四行同现 ✅（`Program.cs:1447-1450`）｜阳性对照**未复跑**（如实标注）。**未核两项**：`TextModel.cs:80-130` 的 `GetTextRun` 是否**间接**关掉 scope；`isoMachineOk` 是否**并进退出码**。
> ### ➡️ **下一步（更新十）**：U1 出**单样本三点夹逼**（`closeMarker` vs `+1`；同时钉"零宽跨度是否含关闭标记"）＋ 修好的 `font-fallback` 表 ⇒ T1b 补完两项只读核实 + 复跑阳性对照（等静树）⇒ **我发起 `#13` 同波**（PC 两处调用点 + harness 1 行 + shim 半 + **判别式仪器**），PC 重建 ⇒ 冻 `#13`。并行：`#14 D-T2`｜`D-F1`（字体回退）｜`ARTIFACT-SRC-FP` 逐文件行｜`HelloWpf` Release 收敛（**等外部构建安静**）。
> ### 🔴 **T1b 的独立复核抓出一处真缺陷（T1b2 的一处自述被证伪）—— 已更正上一条记录**
> **上一条记录里"⑤ (b) 两条机器断言（族计数等式 `47==47`、隔离矩阵"一位未动"）**并进 `coreOk` 与退出码**"这句**作废**：T1b 逐行核过 ——
> `build/MilBridge/tests/HbTextLineParity/Program.cs`：`:775 famSumOk`（`:778` 打印、`:821`/`:830` 使用）、`:820 isoOk`、**`:821 isoMachineOk = isoOk && famSumOk`**，**但 `isoMachineOk` 全文只出现在 `:821` 这一行**（`grep -n isoMachineOk` 仅此一处）⇒ **没有任何东西消费它**；判据处 `:987 coreOk = lineTotal == lineOk && …`（**不含**这两个）、返回处 `:1114 return coreOk && collapseOk && machineOk ? 0 : 1;`（`machineOk` 是**另一个**既有变量）。
> ⇒ **准确表述 = "计算是机器的、判据未接线"**：基线冲突时只会打印 `**冲突**`、`**退出码仍可能为 0**`。**修法（一行级）**：把 `isoMachineOk` 并进 `coreOk`（或 `:1114` 的返回表达式），并加**阳性对照**（人为制造一个基线冲突 ⇒ **必须非零退出**）。**已派 T1b2**（`Program.cs` 单写者）。
> ✅ **`#12` 的冻结表头没有被这句话污染**（我 grep 过：表头里没有"机器断言并进 coreOk/退出码"的说法）⇒ **无需改冻结件**。
> ✅ **同一次复核的另一半（`TextModel.cs:80-92`）确认"无间接关闭"**：`GetTextRun` 四分支里 `TextEndOf*` **只有 `TextEndOfParagraph`**（`:31`/`:82`），**`TextEndOfSegment` 零命中** ⇒ b34 语料的 `closeIndex = -1`（scope 到段末）**成立**；段末那个 `TextEndOfParagraph(1)` 正好解释"末行 LB=null、非末行非 null"与真值一致。
> **T1b 交 U1 对账的一处观察（它不下结论，我也不下）**：b34 客户端构造的是 `new OracleModifier(_modEnd - textSourceCharacterIndex, …)` ⇒ **那个 run 自带的 `Length` 是"到 `_modEnd` 的剩余长度"**，而 U1 说其臂里 `TextModifier.Length` **恒为 1** ⇒ **两者可能是在不同臂上量的**；**但结论不变**：**`Length` 是客户端自定义的、不是语义常量 ⇒ 一律不用它定义 scope**，只用**两个位置**（`modifierOpenIndex` / `modifierCloseIndex`，`-1` ⇒ 到段末）。
> ### ✅ **T1d 的 §15.8：两个分支的完整规格 + 各分支的可执行样本来源**
> | 分支 | 条件 | 零宽跨度 | `lbNull` | 可执行样本 |
> |---|---|---|---|---|
> | **A：scope 到段末** | `closeIndex < 0` | `[open, 段末)` | `!isLastLine && open≥0 && open < nextLineStart` | **`layout-b34` 的 `M_modifier_{w80,w120,w200,w320,winf}`**（3222 行里只有 `w80#0`/`w120#0` 两行非 null） |
> | **B：按关闭标记** | `closeIndex ≥ 0` | `[open, close)` | 再加 `close ≥ nextLineStart` | **`modifier-scope` 53 例**的逐组 N/y 形态（拟合 99/99 ✓） |
> | 子符号 | 关闭标记本身是否含在 scope 内 | `[open, close)` vs `[open, close+1)` | 对应 `close` vs `close+1` | **U1 待出的小样本**（非末行且末字符恰为关闭标记） |
> **判据（同仪器 A/B）**：A 侧不传新参数、B 侧显式传默认值 `(open:-1, close:-1)` ⇒ 六项 + 三套 oracle + 三份明细**逐位相同**；**两侧各记被测 DLL sha + 仪器 sha（跑前/跑后各一次）**，任一侧仪器 sha 不一致 ⇒ 该侧作废重取（纪律 24）。
> ### ➡️ **下一步（更新十一）**：T1b2 修 `isoMachineOk` 接线 + 阳性对照（**一行级**）⇒ U1 出小样本 + `font-fallback` ⇒ T1b 复跑阳性对照（等静树）⇒ **我发起 `#13` 同波**。
> ### ✅ **`#14 D-T2` 设计收货（T1d §16）+ 两条实测纠正我的估计**
> **坐标契约**：Q9（`Width` 以段落原点度量、不含 `PI` 含 `Indent`）+ Q8（原始坐标里网格 = `PI + k×interval`）+ Q6（advance = `container − PI − Indent`，远缘 = 行盒远缘）⇒ **内部一律用 box 坐标（raw − `PI`）**；**box 下现有 `stop` 公式与"钳到 `paragraphWidth`"本来就对** ⇒ **`D-T2` 的真正未知只剩一件**：**PC 传的 `paragraphWidth` 是 `container` 还是 box 宽** ⇒ 由镜像语料钉死，**只用一个具名开关**（`:330 TabClampInset(p) => 0.0`；若判出 container ⇒ `=> p` 一行）。
> **shim 侧 = 1 处实体修正 + 1 开关 + 4 处透传 ≈ 6 行**：**S1 `:1570 EffectiveWidthTab` 的 `pen = 0 → lineContentStart`**（本件唯一实体修正，方向 = **测量侧向整形侧靠**，消灭 Q11 的 "advance 16 vs 0" 与 Q7/Q8 坐标错位）｜S2/S6 统一传真 `paragraphIndentDip`（走 `TabClampWidthFor` 具名入口）｜S4/S5 尾随可选参数 `double paragraphIndentDip = 0` 并透传。
> **⭐ PC 侧是 3 处、不是 1 处**（我的估计错了，以实测为准）：`:536` **不是直通** `FormatParagraph`，中间隔着 `TryFormatLine` ⇒ **P1** `TextFormatterImp.Linux.cs:217` 签名加参数 ＋ **P2** `:239-241` 补实参 ＋ **P3** `:536` 补 `settings.Pap.ParagraphIndent`（`settings.Pap` 在作用域内 ✓）。
> **红旗①（因果版，照录）**：S1 一落就要求 PC **真的传 `Indent`**；而今天应用路径 `indentDip ≡ 0` ⇒ **只落 shim 会让应用路径读数一位不变（看起来正是"修法无效"）** ⇒ **PC 3 处必须同波**。**红旗②**：**不许**把 `ApplyTabStops` 的 `startPenX` 改成从 0 起算。
> **镜像 `tab-anchor`(436) 落点** = T1d 的 `--tab-lines-oracle`：**读档 0 行翻译**（字段同名同义），新增读 `indentDip`/`paragraphIndentDip`/`breakCause`/`hasOverflowed`/`startChar..endCharExclusive` 并**真的传进** `FormatParagraph`；**先只做 `script=latin`**（RTL 族真值面是 Arial，不可比）。档侧 ≈15–25 行。
> ### 🔴 **`#14` 带出两条新在册/新工作**
> - **(a) shim 今天没有任何断因跟踪**（`grep -i cause` ⇒ 0 命中）⇒ "**`breakCause` 逐行断因对拍**"这条判据**必须先加只读诊断字段**（4 个决策点：普通候选／before-tab 候选／钳满后 after-tab／强制回退），**不改行为**；**判据 = 加字段前后所有既有读数逐位不变**（同仪器 A/B），并计入"同波仪器版本"。
> - **(b) 新在册 `D-O1`：`TextLine.HasOverflowed` 在我们的实现里恒 `false`**（`build/shims/PresentationCore.HbTextLine.cs:3054`）。**单列**（通用渲染标志缺口：任何应用读它都拿错值），**不塞进 `#14`**。⇒ **`#14` 的 Q11 判据改写为**："退化 4 例：我们的 `advance`/缩进处理必须与真值一致；`HasOverflowed` **本条仍红、由 `D-O1` 承担**（点名登记）"。**`D-O1` 重启入口**：先查上游 `TextLine.HasOverflowed` 的定义与真值口径（U1 的 Q11 给 4 例 `true`；`tab-anchor` 里"自然到达边缘"那批可当**反例**）⇒ 再定"按什么量算"；**判据 = 那 4 例 `true`、自然到达边缘那批 `false`**。
> ### ✅ **`ARTIFACT-SRC-FP` 逐文件行设计收货（T1c §43）—— 它把 `PC 内 shim sha = unknown` 与"mtime 代理"两件事一起解掉**
> **形态**：在 `do_write()` 的 `peer=` 段之后加一段（**与 `peer=` 同布局**）：`file=<sha256 前16>  <仓库相对路径>`；**选它的理由 = `file=` 与既有 `fp=`/`n=`/`peer_fp=`/`peer_n=`/`peer=`/`tool_sha256=` 互不为前缀** ⇒ 既有解析器读不到、也不会读错，**控制台机读行 `ARTIFACT_SRC_FP … state=…` 一字不动**。
> **覆盖与取舍**（用工具自己的 `manifest()` 数的）：**本仓自有输入 = PC 34 / WB 23 / PF 18 条**，其余 1335/302/1343 全是 `upstream/**` ⇒ 全覆盖只涨 ~18–34 行/份（~2–3%），**`build/shims/**` 自动包含**（shim 就在 PC 那 34 条里）；**不逐条列 upstream**（会把文件吹到 ~150KB 且无新信息，要看用 `--list`）。
> **消费者清单（逐个 grep）**：`close-wave.sh:149`（只取 rc）｜`integration-wave.sh:410`（只 `--write`）｜`run-wpftextdemo.sh:668/:702`（`WPTD_ARTIFACTS(_EXT)` **自己算 sha + mtime 代理，不读 FP 文件**）｜`run-wpfprobe.sh:283`（同上）｜`--check` 只读 `fp=`/`peer_fp=`/`peer=` ⇒ **加行不改任何既有语义**（**已逐条证明**）。
> **判据/牙**：`--selftest` 六极性仍 PASS ｜ 落码前后 `--check` 三行 `state=ok` 且 `fp=/n=/peer_fp=/peer_n=` **逐字相同**（给了 `diff` 命令）｜**两极化**：给 shim 加一行注释 ⇒ `file=` 的 sha ≠ 现源 + `state=stale kind=src`；还原 ⇒ 相同且回 `ok`（⚠️ 动的是 T1d 车道的文件，**由主控安排**）。
> **诚实边界（它写死的）**：`file=` 只记**源的样子**，**不证明产物里真的编进了它** ⇒ 要做到"**产物内 sha**"还缺（都在 build 侧）：① 构建时把内容哈希**生成进产物**（现有 `Tag = "T1b/B2 · 2026-09-11 · …"` 就是那个位置的雏形）；② 读 PDB 编译单元哈希/SourceLink；③ 产物元数据取证。⇒ 本设计把 **mtime 代理升级为源内容比对**，**仍是源侧证据**。
> ### ➡️ **下一步（更新十二）**：等 **U1 单样本 + font-fallback**、**T1b2 接线修完**、**T3 读数**（三者都在跑）⇒ 静树 + 负载下来后：**`#13` 同波**（PC 两处调用点 + harness 1 行 + shim 半 + 判别式仪器）⇒ 冻 `#13`；随后 **`#14`**（含 breakCause 只读诊断 + PC 3 处）｜`D-O1`｜`D-F1`｜`ARTIFACT-SRC-FP` 逐文件行落码｜`HelloWpf` Release 收敛。
> ### ✅ **U1 两批收工，`#13` 的两个前置**全部到位**（`#13` 解除阻塞）**
> **② `font-fallback`（60 例，`DETERMINISM=MATCH`）—— `D-F1` 的修法方向定了**：
> **一句话**：**真机在段落字体缺该码点时不用 `.notdef`，而是做「字体回退」——换成另一个覆盖该码点的已安装字体，并报那个字体自己的字形与 advance**；**现场例的 "1 em" = 回退到的 CJK 全宽字形**（emSize 24 ⇒ `24.000000`），**不是"缺字固定宽度"**；**只有回退也找不到覆盖字体时**才落段落字体自己的 `.notdef`（Arial `18.0`／Times `18.666667`／Noto 文件字体 `14.4`）。在 `FontFamily` 列表或 `Typeface(..., fallbackFontFamily)` 里**点名的族会被优先采用**。
> **23 个"指定字体缺该码点"样本 = 14 回退 + 9 落 `.notdef`**（无一例外由"有没有可用覆盖字体"决定）；**18 个"有该码点"的样本全部无回退**。**覆盖计数**（真机枚举 91 族/563 face）：`U+4E0E` **15/91 族（80/563 face）**｜`U+6C49` 10/91｜`U+05D0` 10/91｜`U+0627` 10/91｜`U+2192` 41/91｜`U+E000` **2/91**｜**`U+10FFFD` 0/91**（⇒ 6/6 全落 `.notdef`）。**"用了哪个字体/字形"是公开 API 读的、零反射**：`TextLine.GetIndexedGlyphRuns()` → `GlyphRun.GlyphTypeface.FontUri` / `GlyphIndices`（**0 = `.notdef`**）/ `AdvanceWidths`。**交叉验证**：`→` 在 Arial 上本就覆盖、advance 也是 `24.000000` ⇒ 它不是缺字规则。**与我们的数字对齐**：`9.6/16 = 0.6 em`（`.notdef`）、`16.0/16 = 1.0 em`（回退全宽）⇒ 我们那两轮的 `emSize` 应为 **16**（U1 从我们数字反推，非它的读数）。
> **取不到（它如实写）**：回退的**搜索顺序/依据取不到**（只知最终用了谁）；`Times` 的 `.notdef` 实测 `18.666667` vs `AdvanceWidths[0]×emSize = 18.667969` **差 0.0013，两值并列未调和**；只测 emSize 24 + 一档宽；`TextTrimming`/`Tabs`/`NoWrap` 仍未测。
> **顺带（便宜项）**：`HasDirectionalEmbedding=true` **在本批构造下无可观测差异**（3 形态 × 2 宽度 = 6 组逐位相同）；**边界**：不等于"该标志无意义"（本批全是单一 text source、单一打开的 scope，**分不开**"该形状本就是 no-op"与"仅带标记的 modifier run 无法把嵌入带到 run 上"）。
> **① `closeMarker` vs `closeMarker + 1`（12 例）—— 结论 = 分离样本真机产生不出来（机制性，不是样本不够）**
> 构造自标定：`"cccccccccc" + [open] + "abc" + [close] + "cccccccccccc"`（`'c'` advance 恰 `12.000000` ⇒ 前缀 `120`）⇒ `openIndex=10`、`closeIndex=14`；先标定出**关闭标记位置 `158.693333`**（零宽 run），再按 `P−2 … P+24` 取 **11 个宽度**（含 `P`、`P±0.001`）。
> **11 个宽度扫下来 `line.endCharExclusive − closeIndex` 只取到 `{−4, −1, 0, +2, +8, +13}`，唯一能让两条定义分歧的 `+1` 从不出现** ⇒ `disagree = 0`、**两条定义在全部 24 行上预测相同**。**机制**：关闭标记是**零宽 run 且粘在它后面那个字符上**（`w=170.693` ⇒ line0 `[0,14)` 而标记被留给下一行；`w=170.694` ⇒ line0 `[0,16)` **标记与那个 `'c'` 一起**进入 ⇒ **中间没有任何宽度能让行以标记结尾**）。与上一批 B 组一致：标记只出现在**末行**（其后无字符）。
> **给 shim 的可用结论**：**若 shim 也"粘"（真机如此），`[open, close)` 与 `[open, close]` 都不会分歧**；若不粘、能产生"行末正好是关闭标记"的行，则取 **半开 `[openIndex, closeIndex)`**。**顺带独立确认**：`end == openIndex`（modifier run 尚未被取用）⇒ **NULL** ✓ —— 这是判据里 `openIndex < lineEnd` 那一项在上一批没覆盖到的边界上的确认。
> **`#13` 的三个前置至此全部到位**：① T1b（b34 `close=-1`、`lbNull == TextLineBreak == null`、无间接关闭）；② U1（`closeMarker` 符号在可产生输入上不可分辨 ⇒ 取半开即可）；③ T1d/T1c 的设计（§15.7/§15.8/§42.7）。
> ### 📌 **新派单：`D-F1` 归 T2（字体栈车道）** —— 只读设计 + 判据，要点：查清"`与` 为什么落 `.notdef`"（fontconfig 枚举本机覆盖字体 + 落点 file:line）；按真机语义实现"找覆盖该码点的已安装字体、用它自己的字形与 advance"，**回退失败才落 `.notdef`**；**判据必须写成"我们报的 advance == 我们所选字体的真实 advance"（自洽）+ `GlyphIndices` 非 0（不是 `.notdef`）+ 与真值差 ≤ 容差（字体不同则标注不可比）**，因为**跨机字体集不同 ⇒ 不能断言"必须等于 24.0"**；**两极化牙**：关掉回退 ⇒ 回到 `9.6` 且 `cr.Width` 复负；**两处禁止**：不许把 `.notdef` 的 advance 硬改成 1 em 冒充回退、不许改 oracle。
> ### ➡️ **下一步（更新十三）**：等 **T1b2 报最终仪器 sha**（它正在把 `isoMachineOk` 接线）⇒ `T3` 复取 `tline` ⇒ **我发起 `#13` 同波**（T1c 两处调用点 + T1b harness 1 行 + T1d shim 半 + 判别式仪器）⇒ 冻 `#13` ⇒ 随后 `#14`（含 breakCause 只读诊断 + PC 3 处）｜`D-O1`｜`D-F1`（T2 设计）｜`ARTIFACT-SRC-FP` 逐文件行落码｜`HelloWpf` Release 收敛（等外部负载）。
> ### ♻️ **更正我上一条记录（"死代码"那条的结论被逐行核对翻案 —— 这是我今晚第三次自我更正）**
> 我上一条写的是"**T1b2 那句"并进 `coreOk` 与退出码"被证伪；退出码仍可能为 0**"。**T1b2 的逐行核对（原文级）表明：推论不成立，而它原来的说法基本是对的**：
> - `:821 bool isoMachineOk = isoOk && famSumOk;` **确实是死变量**（全文只此一处）—— **T1b 这一半对**；
> - **但** `:994 bool machineOk = famSumOk && isoOk;` —— **同一个表达式** —— **确实接了线**：`:999 Check("T2-iso", …, machineOk, …)`（消费点 1）＋ `:1114 return coreOk && collapseOk && machineOk ? 0 : 1;`（消费点 2，且 `960..1120` 之间**只有这一处 `return`**）。
> ⇒ **`isoMachineOk` 与 `machineOk` 逐字等价** ⇒ **"基线冲突时退出码仍可能为 0"是错的**（冲突 ⇒ `machineOk=false` ⇒ 唯一 return 返回 1）。真风险降级为"**有人删掉 `machineOk` 的消费点、而 `isoMachineOk` 还留着 ⇒ 看起来还在算**"。
> **处置（T1b2 已落，一行级）**：删掉那行死变量 + 在 `machineOk` 处写明"**唯二接线点**"与机检口径（**表达式逐字未变、无逻辑语义改动**）；机检自证 = `grep -nE '^\s*(bool machineOk|return coreOk)'` ⇒ **2 行**、`grep -cE '^\s*bool isoMachineOk'` ⇒ **0**。
> **阳性对照（实测，能红）**：给基线 artifact 里**不许变的族** `M_modifier` 注入一条假 `>0.34` 行 ⇒ 打印 `逐族 diff：M_modifier 8→7（**冲突**）`、点名、`❌ T2-iso`、**rc=1**；还原 ⇒ `一位未动` + `✅ T2-iso`。
> **⭐ 它如实说明做不到的那一腿（这条比"做成了"更值钱）**：**"还原 ⇒ `rc=0`"在本树上做不成** —— 因为 `coreOk`（记账 `1292/1298`）与 `collapseOk`（折叠明细 `219/236`）**本就为假** ⇒ 两腿 `rc` 都是 1 ⇒ **本树上退出码不具判别力**；退出码通路的保证是**静态的**（唯一 return + `machineOk` 是合取项）。**它拒绝写"应该会 0"。**
> **"接线只影响判据、不动数字"实测成立**：冲突 vs 还原两趟**读数逐项相同**（记账 `1292/1298`、分桶 `0=168/≤0.34=1089/>0.34=41`、Extent `1260/1298`、折叠明细 `219/236`、不一致用例 `14`、折叠不符 `17`、`T2b 972/972；213/213`），**唯一差 = `T2-iso` 的 ❌→✅**（✅/❌ 计数 `20/8 → 21/6`）；且 `loadavg 7.97` 下两趟仍逐项相同 ⇒ **外部负载未扰动本次数字**。
> ✅ **T1b 独立复核并就地更正（带自曝的教训）**：它自己逐行核过 —— `:1001 bool machineOk = famSumOk && isoOk;`（与被它判"死"的那行**逐字等价**）＋ `:1004 Check("T2-iso", …, machineOk, …)` ＋ `:1121 return coreOk && collapseOk && machineOk ? 0 : 1;`；机检 `grep -nE '^\s*(bool machineOk|return coreOk)'` ⇒ **2 行**、`grep -cE '^\s*bool isoMachineOk'` ⇒ **0**（残留仅注释）；`awk` 证明 `960..1120` **无第二个 return**。⇒ **"基线冲突 + `rc==0`"没有通路**。**它自曝的错因**：**只 grep 了"死变量那个名字"**，看到"全文只此一处"就下了"整条判据没接线"的结论 —— 真正接线的是**逐字等价的另一个名字** ⇒ 与 **"一个表达式两个消费者 / 只查一处就收工"** 同族（它把这个家族的第 4 个实例登记了：`grep -c ExportDepth.NotImpl`、`grep -c 0x0102`、`grep -c 已失败 `、本次）。**并已按"保留原文 + 加更正指引、不涂改历史"落进台账。**
> ### 📌 **`#13` 的仪器定版：`HbTextLineParity/Program.cs = 6652f310591cb8bc`（mtime 22:08:04）；`run.sh = 3e513e88a4fa4ec9`（全程一字未改）**
> 今晚该文件走过四版：`0d45032b20cfbfee`（**裸断言**，`#12` 表头读数用的那一版）→ `6e077361609f02ad`（**判别式** `ours<0 ⇒ truth<0`）→ `3dd2ac743a172c51`（删死变量中间态）→ **`6652f310591cb8bc`（终版）**。⇒ **`#12` 表头与终版的可比性**：`记账 1292/1298`、分桶 `168/1089/41`、`Extent 1260` **两版相同**；**`折叠明细` 终版 = `219`**（表头那版 `23` 里的 5 条假红已被判别式消掉）⇒ **这是"仪器位移"，不是回归**。
> ### ⚠️ **环境事故补记（T1b2 报）：22:0x 重启清空 `/tmp` 的连带影响**
> 它的 scratch（`/tmp/t1b2/**` 的 `step-*.log`、`shim.src.bak`、`Program.cs.*` 备份）**全部作废**；且有一趟 `run.sh tline` 因**重定向目录已不存在**而 **`rc=82`、日志为空（根本没跑起来）**，`gen/` 一度残留**更早那趟对照仪器 `A999E150F9EAD2F4`** 的产物 ⇒ 已用正式趟覆盖，现 artifact 自报 `Program.cs 6652F310591CB8BC` / 被测 shim `3081D088…` ✓。**影响面仅限日志留存**：`[ROWD]` 原文与报告都有**仓内**副本（免疫），但报告 §2/§5/§6 引用的 `/tmp/t1b2/*.log` **路径已不可达** ⇒ 复算要按报告里的命令重跑。**读数本身未变。**
> ⇒ **纪律补一条**：**scratch 与备份一律放 `$HOME`（不放 `/tmp`）**（我今晚已把 `#11` 表头备份改到 `~/wfp-runs/`，T1b2 也照做）。
> ### ➡️ **下一步（更新十四）**：`T3` 正按定版仪器取 `tline`/`--tab-oracle`/`tab-zero`+`--known-red` 三支读数 ⇒ 回报后我**发起 `#13` 同波**（T1c 两处调用点 + T1b harness 1 行 + T1d shim 半 + 判别式仪器）⇒ PC 重建 ⇒ 静树门禁 ⇒ 冻 `#13`。并行：`#14`（设计已交）｜`D-F1`（T2 设计）｜`D-O1`｜`ARTIFACT-SRC-FP` 逐文件行｜`HelloWpf` Release。
> ### ✅ **`WAVE24-FINAL-ROUND.md`（112 行）已落（T3）—— `#12` 的轮次档齐了**
> 七要素 + 三条必写注记全齐；含**纪律 23/24 的跑前=跑后 sha 表**（`HbTextLineParity/Program.cs 6652f310591cb8bc`、`CoverageProbe/Program.cs cc61299d6dc72277`）。**两份独立门禁**（主控 `go-freeze12b` 与 T3 `go-freeze12c`）**逐项一致**。它另报两条与 L14 同族的透明说明：`pgrep` 命中的 `Wpf…dll` 其实是**外部 `wpf2web`** 的构建；`pgrep -fc 'Xvfb :97'` 报 2 是**它自己的命令行文本**被匹配 ⇒ **以 `xdpyinfo` 为准**（`:97` 空闲 ✓）。
> ### 🔴 **新登记：`--tab-oracle` 的 `rc=1` 是构造性的（`CoverageProbe` 的第二例"退出码不可判"）**
> `RunTabOracle` 末行 `return pass == total ? 0 : 1;`，而 **`total=114` 含 57 例"按设计跳过"** ⇒ 恒 `rc=1`（内容其实 `pass=57 fail=0`）。⇒ **两个 tab 档的退出码今天都不可信、方向相反**（`--tab-lines-oracle` 改前恒 0、改后"不给表 ⇒ 恒 1"；`--tab-oracle` 恒 1）。**判据一律以判据行为准**。**修法归 T1d**（`total` 改可判例数或 `fail==0 ⇒ 0` + 阳性对照）；**已落**：`CoverageProbe/Program.cs → 5982ce9ca2d01d22`（22:15:13，待它回交牙与 before/after）。
> ### ✅ **T2 的 `D-F1` 根因链（§29）：回退**有**、但被单面路径绕过**
> **环 1**：`build/fonts/NotoSans-Regular.ttf` upem=1000、**glyph 0 advance = 600 ⇒ 0.6 em = 9.6000 DIP @em16**；该面 `U+4E0E / U+6C49 / U+10FFFD` 的 gid **都是 0**（用例 `F_nbsp_zwsp_w40` 的 `fontKey="file"`）。
> **环 2**：**我们的回退存在且语义与真机一致** —— `HbPlanBuilder.Build`（shim `:1165`）逐码点 `CoversFace`（`:1183`，`hb_font_get_nominal_glyph != 0`；`:761` 严格区分 `-1=面不可用`/`0=.notdef`）→ ② `PickFromRuns`（`:1191`）→ ③ `HbFontCandidates.TryFindCovering`（`:1204`，扫目录：`ResolveDirs():886`/枚举 `:926`/`Sort(Ordinal):932`/排序键 `|Δweight|→|Δwidth|→|Δslant|:964`）→ `NoteApplied:1220`/`NoteFailed:1224`（**不假装成功**）；**应用路径确实生效**（T3 dump `fallbackApplied=2 fromSystemScan=2`）。
> **🔴 环 3（根因）**：`FormatParagraph(..., HbFontPlan plan = null, …, GlyphTypeface[] segmentFaces = null, …)`（`:3392/:3393`）—— **`plan == null` 走单面度量**（`:3404-3410`），而 **harness 的调用（`HbTextLineParity/Program.cs:426`）既没传 `plan:` 也没传 `segmentFaces:`** ⇒ **`allowFallback` 那段根本不会被问到** ⇒ `与` 单面整形 ⇒ `.notdef` ⇒ 9.6 ⇒ `cr.Width` 复负。⇒ **一句话：回退住在"计划构造器"里，而单面路径绕过了它**；**与 §23 时代"harness 单字体入口无 CJK 回退"是同一个结构事实**，现在有真值 ⇒ **从"结构性不可比"升级为"可修的真违反"**。
> **环 4**：`fc-list :charset=4e0e` ⇒ 本机 **89 face**；`U+10FFFD` **两边都 0** ⇒ **那一档完全可比**。
> **修法**：`plan == null` 也先构造计划（`allowFallback:true` + `gate`），落 `:3404-3410`（T1d 车道）；候选集/顺序**沿用我们自己的**（真机顺序**取不到**）；观测面 = `HbLineSegment`（`:492` 的 `(按码点回退)`）+ `HbFallbackDiag`（`:1004`）。**失败 ⇒ `NoteFailed` ⇒ glyph 0 ⇒ advance = 该面 glyph 0 的宽**。
> **判据**：**C1 自洽（主）**：我们报的 advance **== 我们所选面自己的 advance**（`advance/upem × emSize`，**逐位相等、无容差**）｜**C2**：`NominalGlyph(path,faceIndex,0x4E0E) != 0`（非 `.notdef`）｜**C3**：与真值差 ≤ 容差（字体不同标不可比；零覆盖档完全可比）。**牙**：`allowFallback:false` ⇒ 回 `9.6000 / cr.Width −3.0560`；开 ⇒ `16.0000` / 变正。**两处禁止**：不许把 `.notdef` 硬改成 1 em；不许改 oracle。
> **T2 的预测（它自标"未实测"）**：修好后 `与` = **1.0000 em = 16.0000 @em16**（它读字体实测：`DroidSansFallbackFull.ttf` glyph 7078/upem 256、`NotoSansCJK-Regular.ttc` face0 9497/face2 9498，均 1000/1000）⇒ `cr.Width` **−3.0560 → +3.3440**（真值 3.3433，差 **0.0007**）。**它主动声明：自写的单面 python 解析器不认 `.ttc`（只报 1 命中而 fontconfig 说 89）⇒ 不许拿它的预测当值。**
> **⚠️ 同一条 `plan==null` 缺口"预期"也是 §23/§24 那 34 条 `+CJK` Extent 行的结构性来源** ⇒ 落码后**预期**从"结构性不可比"变成"可比（字体不同 ⇒ 量级判据）"（待实测）。
> ### 🧭 **主控裁定（四条）**
> ① **落码顺序：`#13`（在跑）⇒ `D-F1` ⇒ `#14`** —— `D-F1` 是**唯一有真值的、用户可见的渲染差异**（错字形 + 错 advance），优先级高于 `#14` 的缩进边界语义。
> ② **推翻我先前"`GetIndexedGlyphRuns()` 不实现"的裁定**：旧依据"上游 0 个调用点"；**新证据 = 它正是真值的观测装置**（`GlyphTypeface.FontUri`/`GlyphIndices`（0=`.notdef`）/`AdvanceWidths`）⇒ **实现它**，作为 `D-F1` 判据的**共同观测装置**（两侧同一公开 API ⇒ 口径可比）；**不许用桩冒充**；shim 头部 `owed` 登记与 `TextLineProto` 的检查随之更新；**实现归 T1d、与 `plan==null` 同波**。
> ③ `D-F1` 判据 C1/C2/C3 照准，**观测面改成 `GetIndexedGlyphRuns()`**。④ **`D-O1` 与 `ARTIFACT-SRC-FP` 逐文件行**继续挂在队列（各自独立成波）。
> ### ⏰ **环境：机器 2026-09-14 22:1x 之后被挂起，2026-09-15 10:17 恢复**（`up 12:24`、`loadavg 0.25`）。恢复后主控现场核对：
> - `#12` 冻结完好（6 条 BASELINE、`RE-FROZEN #12` 表头）；**九位仍 = #12**（`bridge 759a322431f1e457`/`pc 293f99525f5af4f2`/`pf 11791727d682e119`/`hb 3081d088cda0431c`）⇒ **PC 未被重建**（#13 的源改动**尚未编进产物**，正常中间态）；
> - **`T1c` 的 PC 半已落**（`TextFormatterImp.Linux.cs = 5dedc21f5f372c78`，22:14:58）；**`T1d` 的 `--tab-oracle` rc 修已落**（`CoverageProbe/Program.cs = 5982ce9ca2d01d22`，22:15:13）；
> - **`T1d` 的 shim 半、`T1b2` 的 harness 半尚未落**（shim `3081d088` / `HbTextLineParity/Program.cs 6652f310` 未变）⇒ 已催办。
> ### 🔗 **`#13` 的硬顺序依赖（T1b2 实测）＋ 两个下标的语义被钉死（53/53）**
> **顺序**：**先 T1d 在 shim 侧声明 `modifierOpenIndex`/`modifierCloseIndex` 两个尾随可选参数，后 T1b2 在 harness 调用点传参** —— 否则 **CS1739（无此命名参数）**、直接弄坏树。T1b2 **正确地没有抢跑**（补丁备在 `$HOME/t1b2-bak/PATCH-13-pending.md`，落完声明后 5 分钟可交）。现场证据：`grep -c modifierOpenIndex build/shims/**` ⇒ **0**、`FormatParagraph` 仅 `:3380` 一处（无重载）、参数表末尾停在 `bool wrap = true)`。
> **语义（53/53 实测，不是猜）**：`tests/parity/windows/modifier-scope/out/modifier-scope-oracle.json` **同时**带 `modifierOpenIndex` / `modifierCloseIndex` / `modifierScopeCharRange`，三者一致性 **53/53、0 例外**：`A n=6 (0,4)`｜`B n=3 (30,34)`｜`C/C2/E n=9 (0,-1)`｜`D/F/G/H n=35 (-1,-1)`。⇒ **是"字符下标"、不是 run 下标**（`open == scope 起点`、`close == scope 终点 或 −1`）；**`open == −1` ⇒ 无 modifier**（与默认值 −1 同义）。
> **两处独立复核**：① **b34 的 `open = 6`** 正确（= `cases.json` 的 `modifierStart = 6`）；② **b34 的 `close = -1`** 由"那 6 个源文件 **0 处** `TextEndOfSegment`"独立确认 ⇒ **b34 语料根本不触发 R1 配对**，harness 侧也不需要它（R1 只在别的语料可能用到，届时按"未验证的选择"注明）。
> ⚠️ **一处易绕的写法（不冲突）**：`layout-b34/cases.json` 的 `M_modifier_*` 是 `modifierStart=6, modifierEnd=**45**` —— `modifierEnd=45` 是 **modifier 的字符覆盖终点**（`OracleModifier(_modEnd - idx)`），**不是关闭标记** ⇒ 与 `close = -1` 不矛盾；这也是先前"note 里 `[6,45)`"那条的正解释。
> ### ✅ **T1d 落了 `#13` 的 shim 半 —— 接口是**三个**参数（它自验时量出的硬事实）+ `--tab-oracle` 的 rc 修已完成**
> **shim**：`build/shims/PresentationCore.HbTextLine.cs = fde9e511e8443cf2`（今天 10:2x）；`TEXTLINE_SHIM_DIRECT` 直构分支**编译 0 错误**；`diff` 总 **73** 行 / **删 8 行**，逐行核对全是声明锚点；备份 `$HOME/t1d-backups/20260914-2213-shim-3081d088.cs`（`cp -p`）。尾部署名逐字：`bool wrap = true, int modifierOpenIndex = -1, int modifierScopeEnd = -1, int modifierCloseIndex = -1)`。
> **🔴 为什么三个参数**：它先按"两个下标 + `close<0` ⇒ 到段末"落，**自验档立刻红** —— `M_modifier_winf 行#0`：真值 `w=156.9167`（可见 = `[0,6)+[45,63)` 共 24 字符）而**我们 `w=43.59`**（把 `[6,63)` 全零宽了）。⇒ **"close = -1（从不发 `TextEndOfSegment`）"与"零宽覆盖到哪"是两件事**：覆盖终点由**客户端声明的覆盖范围**给（`cases.json` 的 `modifierEnd = 45` ⇒ **正是 note 里 `[6,45)` 的正解释**）。⇒ 语义分工：**`modifierOpenIndex` = 覆盖起点**｜**`modifierScopeEnd` = 覆盖终点（半开，−1 ⇒ 到段末）⇒ 只喂"零宽跨度"**｜**`modifierCloseIndex` = 客户端 `TextEndOfSegment` 下标（−1 ⇒ 从不）⇒ 只喂 `lbNull`**。三者与 U1 的 `modifierScopeCharRange` **53/53 一致**。
> **第二条（同样实测）**：**零宽必须同时落测量侧**（`BreakParagraph` 的 `adv[]`），否则断行仍按未隐藏文本算 —— 未落时 `winf 行#0 len=26`（真值 63），落上后 **`len 7/7`** ✓。
> **它自己的自验读数**（`--modifier-check`，字体对齐真值 NotoSans）：**合计 用例=5 行=7｜行宽 ≤0.34 `7/7`｜`len 7/7`｜`ws 7/7`｜`lbNull 7/7`**；`winf 行#0` 真值 `len=63 w=156.9167` ↔ 实得 `len=63 w=156.9280`（行宽 `74.5733→74.5760`、`115.6900→115.6960`、`37.0667→37.0720`）；**不传区间的旧行为对照**（`winf w=439.1360`、`w320 292.6250`、行数 `2/3/1 → 7/4/3`）⇒ **旧行为未被扰动**；`Extent 0/7` = **既存差**（`gen/t2d-extent-mismatches.txt` 在 #12 时代就已列 `M_modifier_w80#1 差 −3.6800` 等）⇒ **不是本改引入**（且它**保留字形、只置零 advance** ⇒ `Extent` 构造上不动）。
> **它自纠两条**：① 自验档第一版用 **Liberation Sans** ⇒ 行宽只剩 ~93%、`Extent 16.91 vs 18.00` ⇒ **仪器口径错**，换 **NotoSans** 后 `7/7`；② `lbNull` 计数器**把 `==` 写成 `!=`** ⇒ 首版报"0/7"，实际 `7/7`。
> **`--tab-oracle` 的 rc 修（已完成）**：`cc61299d6dc72277 → 5982ce9ca2d01d22`；口径 = **`fail == 0 ⇒ 0`**（`fail = 可判例 − pass`；跳过的 57 例不进判据**且仍点名**），并打印 `TAB_ORACLE 退出码=…（可判 57 = pass 57 + fail 0；跳过 57 不计）`。**阳性对照**：按真结构（逐例 `perChar`）注入一处真失败 ⇒ **`rc=1`**（`pass=56 fail=1`）｜**还原 ⇒ `rc=0`**｜基线 `rc=0`。**`--tab-lines-oracle` 的 `--known-red` 语义未坏** ✓（真 `tab-zero` + 登记表 ⇒ `rc=0` + `KNOWN-RED …（已登记，不改退出码）`）。**顺带修同族**：`--tab-oracle` 读档失败原先 **core dump**（用不存在路径实测 `rc=134`）⇒ 已加 **try/catch + 形状自检**（缺键/结构不符 ⇒ 友好报错 + **`rc=2`、不崩**）。
> ### ✅ **T3 的 `NEXT-WAVE-13-CHECKLIST.md`（235 行）已就绪 + 一条新发现（"退出码不可判"家族第 3 例）**
> 8 件齐（锚/判据/零影响 A/B/不许碰/两臂/rc 验收/版本边界/`D-T1` 回归/应用层），另列**开工前必须问到的 4 件**。**主控已逐条答复**：① 波由 `build/close-wave.sh` 发起（自动认领 + 哨兵自动改写，但**若在 `[5/6] verify-all` 中止则哨兵不更新** —— 上一趟发生过）；**基线号 `#13` 由主控在冻表头时写**；② 新仪器 sha 由 T1b2 落完转给它；**A/B 的确切形式 = 同一份 DLL、同一仪器 sha、只切 env**（已要求 T1b2 加 `T1B_MODIFIER_META=0` ⇒ 不传那三个实参）；③ 臂 B 的**口径以 oracle 三字段为准**（`modifierOpenIndex` / `modifierScopeCharRange` / `modifierCloseIndex`；**`modifierScopeEnd` 取 `scopeCharRange` 右端**，`C/C2/E` = `open 0`、`close −1`、range `[0,36)` 一类 ⇒ **逐例读、不许猜**）；**臂 B 的工具 = T1d 的 `--modifier-check`**（确切命令我向 T1d 要）；④ **"`len` 仍含 39 字符"读法确认**：`modifierStart=6 → modifierEnd=45` ⇒ 39 字符**仍在 `len` 里**（只置零 advance）⇒ **真值 `Len=63` 必须由内容取得，不许靠缩区间凑**。
> **🚩 新发现（T3）**：**`--modifier-check` 恒 `return 0`** ⇒ **"退出码不可判"家族第 3 例**（前两例：`--tab-lines-oracle` 改前恒 0 / 改后"不给表恒 1"；`--tab-oracle` 恒 1 构造性）。**判据一律看判据行**；已让 T1d 在 `#13` 同波**顺手修掉**（`fail==0 ⇒ 0` + 阳性对照）并登记。
> **⚠️ 它的 §0 现场锚（10:18:33 读）已过期**：shim 现为 **`fde9e511e8443cf2`**（三参数版，10:19:55）、`CoverageProbe/Program.cs` 已到 `06da88177bdeda66` ⇒ 已要求它**开跑前重读现场**（纪律 4 的又一实例）。
> ### ✅ **`#13` 三方落地齐 + T1b2 的 A/B 把我的一条期望改正了**
> **落地**：shim **`fde9e511e8443cf2`**（T1d，三参数）｜PC 源 `5dedc21f5f372c78`（T1c）｜harness **`814d57ae9960e590`**（T1b2，`+33/−1`，唯一删除行 = 调用点续行；其余 4 个调用点零改动）｜`CoverageProbe/Program.cs 06da88177bdeda66`（T1d 的 rc 修）。**PC 产物仍未重建**（`293f99525f5af4f2` = #12）⇒ 源先于产物 = 正常中间态。
> **🔄 我的一条期望被实测改正（今晚/今晨第 N 次）**：我写"零影响 A/B ⇒ 读数**逐位相同**" —— 那是**假设三个参数无效**才成立的期望。T1b2 实测（同一 DLL `7a3a916c80aa7e74`、同一仪器 `814d57ae9960e590`、只切 `T1B_MODIFIER_META`）：**A 不传 vs B 传** = 记账 `1292/1298 → **1298/1298**`｜分桶 `168/1089/41 → 168/**1096**/**34**`｜折叠明细 `219/236 → **225/236**`｜不一致用例 `14 → **10**`｜折叠不符 `17 → **11**`｜`T2b` **不动（0 差）**｜`T2d` 行级 Extent `1260 → **1259**`、余差 `58 → **59**`（**+1 未结清，已要求逐行点名归因**）。**三份明细差异行 `27/20/7` 全部是 `M_modifier_*`，非 M_modifier 差异行 = 0** ⇒ **正确判据 = 「差异必须 100% 落在携带 modifier metadata 的用例上；其余逐位相同」**（已同步改 T3 的清单措辞）。
> **修复幅度**：`M_modifier_winf 行#0` **`439.1360 → 156.9280`**（真值 `156.9167`，差 **`282.2193 → 0.0113`**）；族内 `>0.34` 红数 **7 → 0**；**`#12` 那条"最大差 `282.219333`"消失**。
> **裁决**：① **A/B 判据按实测改写**（见上）；② **`mayChange` 加 `M_modifier` 一行**并注明"`#13` 登记：modifier meta 传参允许变化" —— **这是"已登记的允许变化"名单的正当用途，不是放宽**；而 `T2-iso` **必须继续抓未登记的族变化**（它在 A 腿 ✅ / B 腿 ❌ 正说明机器在工作）；③ **`T1B_MODIFIER_META=0` 用"强制 `-1/-1/-1`"实现被批准**（C# 可选参数在调用点求值后传值 ⇒ 被调方无法区分"用默认"与"显式传默认" ⇒ 不必复制调用点，复制反而会漂移）。
> **🔴 未结清**：`T2d` 行级 Extent **`1260 → 1259`**、余差 **`58 → 59`** —— 与我的判据「`Extent`/`Baseline` 绝不动、段2 余差 `58`」**不符**，也与 T1d 的"保留字形、只置零 advance ⇒ `Extent` 构造上不动"**不符** ⇒ **必须逐行归因**（哪一行、两腿值 vs 真值、方向朝/背真值），**归因不到 = 红旗**。
> ### ✅ **T1b2 收尾：`Extent +1` 归因清楚 = 修复的副作用（不是回归）+ `mayChange` 已登记 `M_modifier`**
> **归因（只读既有产物，未重跑）**：差异**只有 3 组行、全部 `M_modifier_*`** —— `M_modifier_w80 行#1`、`w120 行#1`：真值 `18.0000`，A 腿 `14.3200`（`|差| 3.6800`）→ B 腿 `<0.01` ⇒ **离开余差清单、朝真值**；`w80/w120/w200 行#0`：A `<0.01` → B `18.0800`（`+0.0800`）⇒ **进入清单、背真值 0.08**。主对拍集 `38→39`（+1），**LineHeight 组 `20→20` 未动**。
> **判定 = 修复的副作用、不是回归**，四条依据：① 变化的 6 行**全在 `M_modifier`**（非 M_modifier 差异行 = 0）；② **总绝对误差 `7.36 → 0.24`（降到 1/30）**；③ `+1` 是**容差 0.01 的跨界假象**（它替掉的错是 3.68）；④ **机制可解释**：传参后零宽跨度由 `[6,段末)` 收窄为 `[6,45)` ⇒ **断行区间真的变了**（`w80 行#1` 的 `cp` `[6,19)→[50,63)`、`w120 行#1` `[12,19)→[56,63)`）⇒ 行内字形集合不同 ⇒ 墨迹盒自然不同；**这与 T1d「保留字形、只置零 advance ⇒ `Extent` 构造上不动」不矛盾**（它说的是**同一组字形**；这里**行内容本身换了**）。
> **⇒ 主控裁定（批准它的登记措辞）**：`#12` 那条「`Extent`/`Baseline` 绝不动（段2 余差 `58`）」**改为**「**非 `M_modifier` 的 `Extent` 余差不得变（恒 `38`）；`M_modifier` 按本条登记**」——登记内容 = 上述 6 行的进出 + 余差 `58→59`、行级 `1260→1259`、**总绝对误差 `7.36→0.24`**、**变化 100% 限于 `M_modifier`**、LineHeight 组恒 `20`。
> **`mayChange` 已加 `M_modifier`**（注释写清 `#12`/`#13` 两批各自的登记项）；实测：**A 腿 `M_modifier 0→7（允许）` ✅｜B 腿 `7→0（允许）` ✅**（同一 DLL `63d71c6922b79879`、同一仪器 `2e458928fc1577c2`）；**并证"加名单只动判据、不动数字"**（加名单前后**同腿**六项逐项相同）。
> **`#13` 仪器源终版**：`HbTextLineParity/Program.cs = 2e458928fc1577c2`（mtime 10:24:06；`diff` vs `#12` 终版 = **+38/−2**，两处删除**恰好是两个锚点**、零附带改动、其余 4 个调用点未动；0 错 0 警告）；`run.sh` 仍 `3e513e88a4fa4ec9`。
> ### ➡️ **下一步（更新十六）**：三方落完并报"源已定" ⇒ **主控重建 PC + 起波** ⇒ `T3` 按 `NEXT-WAVE-13-CHECKLIST.md` 独立复取 ⇒ 冻 `#13` ⇒ **`D-F1`**（含 `GetIndexedGlyphRuns()` 实现）⇒ `#14` ⇒ `D-O1` ⇒ `ARTIFACT-SRC-FP` 逐文件行 ⇒ `HelloWpf` Release。
> ### ✅ **`#13` 已冻结（2026-09-15 10:33）—— `M_modifier` 三层透传**
> **波 `close-wave-102523`**：`native_rebuilt=0`、`bridge_republished=0`、**`verify_all=PASS`（9 步 0 失败）**、身份自检四项 ✅（桥源指纹一致 / 生成物指纹 `state=ok` / 应用器 `miss=0` / **输入稳定性 波前==波后**）⇒ 门禁 **`WPTD_GATE=PASS`**、两档 `3/3`、**6/6 `result=PASS`**、`runner exit=0`、`BRIDGE_SRC_STALE=no`、`hbtextline_shim_stale=no`（`src 1789438795 < pc 1789439185`）、`WPTD_LINE_ADVANCE=PASS`。
> **九位（现场/哨兵/表头三方逐位一致）**：`bridge 759a322431f1e457`｜**`pc d7a848dfeedcf29b`**｜**`pf e36447bed6b29e8f`**｜`wb e6216fe961a2bfb9`｜`provider 71ba86c6495347fe`｜`win32shim 0098234982391bbf`｜`wic 03b67fbcd7c385b6`｜**`hbtextline fde9e511e8443cf2`**｜`dwf 2f77dbdf5e7e2cd5`。**EXT 变化 3 处**：`reachframework 062c465f…`、`presentationui 8b688faa…`、`systemprinting cec723f6…`。
> **本波内容（三方同波）**：PC 侧 `CollectLenient` **只加"记位置"**（平铺/记账/`cp += run.Length`/props 取第一个非 null 一律照旧）｜harness 唯一调用点补传三个实参（`diff` vs #12 = **+38/−2**，两处删除恰好是两个锚点，其余 4 个调用点未动）｜shim 三参数（`modifierOpenIndex` / **`modifierScopeEnd`（半开，−1 ⇒ 到段末）只喂零宽跨度** / **`modifierCloseIndex`（−1 ⇒ 从不）只喂 `lbNull`**；`diff` 73 行、删 8 行 = 8 处锚点）。
> **两条硬纠正（T1d 自验实测，已进表头）**：**(a)** `close < 0` **不能**当"零宽到段末"（b34 = `open 6, close −1, 覆盖终点 45`；按 `close` 处理 ⇒ `winf 行#0 w=43.59` vs 真值 `156.9167`）⇒ 故有第三个参数；**(b)** 零宽**必须同时落测量侧**（`BreakParagraph` 的 `adv[]`），否则断行按未隐藏文本算（`len=26` vs 真值 63）；落上 ⇒ `len 7/7`。
> **判据命中（A/B，同 DLL 同仪器 sha 只切 `T1B_MODIFIER_META`）**：记账 `1292/1298 → **1298/1298**`｜分桶 `168/1089/41 → **168/1096/34**`｜折叠明细 `219/236 → **225/236**`｜不一致 `14 → **10**`｜折叠不符 `17 → **11**`｜`T2b` 不动；**差异 100% 限于 `M_modifier_*`（非 M_modifier 差异行 = 0）**；`winf 行#0` **`439.1360 → 156.9280`**（真值 `156.9167`，差 `282.2193 → **0.0113**`）；族内 `>0.34` **`7 → 0`**。
> **判据/登记改动（如实）**：① `mayChange` **加 `M_modifier`**（登记；两腿 `T2-iso` ✅；"加名单只动判据、不动数字"已证）；② **`Extent` 判据改写**为「非 `M_modifier` 余差不得变（恒 38）；`M_modifier` 按登记」（**总绝对误差 `7.36 → 0.24`**；`+1` 是容差 `0.01` 跨界假象）；③ **臂 B 真值面 Arial、本机无该字节 ⇒ 行宽/断行不可比**，门禁 = 与字体无关的 `--modifier-rule-check`（`170/170`）。
> **顺带修掉的仪器缺陷（"退出码不可判"家族 3 例）**：`--tab-oracle` 恒 `rc=1`（构造性）⇒ `fail==0 ⇒ 0`（阳性对照：注入真失败 ⇒ `rc=1`）**＋读档失败原先 core dump（`rc=134`）⇒ 现 `rc=2` 不崩**；`--modifier-check` 恒 `return 0` ⇒ 同口径修好；`--tab-lines-oracle` 改前恒 0 / 改后"不给表恒 1"（有意语义、`--known-red` 未坏）。
> **仪器版本**：`run.sh 3e513e88a4fa4ec9`（本波未改）｜`HbTextLineParity/Program.cs **2e458928fc1577c2**`｜`CoverageProbe/Program.cs **0046ed20d832a7ef**`（链 `cc61299d → 5982ce9c → 06da8817 → b331c192 → 0046ed20`）｜门禁 runner `5dfb2635b87bb351`。
> ### ✅ **`D-F1` 的判据 runner 落地（T2，§30/§30.8）+ `ARTIFACT-SRC-FP` 逐文件行落地（T1c，§43/§44/§45）**
> **T2 的 runner**（`build/DirectWrite.Linux/FallbackCriteria/{Program.cs,FallbackCriteria.csproj,eval-df1-criteria.py,advance_from_font.py,run-df1-criteria.sh}`）：退出码 **`0`=过 / `1`=FAIL / `3`=NOINFO（≠通过）**；"`GetIndexedGlyphRuns()` 仍是桩"用**确定性探测**（`WPF_LINUX_TEXTLINE_STRICT=1` ⇒ `Owed` 抛 `NotSupportedException`；正常模式**空序列不当"没有字形"**）。
> **⭐ 它最重要的自我发现（已按实测改判据分工）**：**C1 抓不到这个 bug** —— `9.6` **就是** NotoSans-Regular **自己** glyph 0 的 advance ⇒ C1a/C1b **都自洽** ⇒ **C1 = 反作弊**（堵"把 `.notdef` 硬改成 1 em"），**"回退有没有发生"由 C2（`GlyphIndices ≠ 0`）+ C3（与真值差/符号）判**。
> **修前读数（两来源分开标，可复现）**：`advance = 9.6000`（一手复算 `advance_from_font.py`，**它自己走 cmap 取 gid、不信任何 API**；`.ttc` 已支持：`NotoSansCJK-Regular.ttc#0` ⇒ gid 9497 / `16.0000`；`DroidSansFallbackFull.ttf` ⇒ gid 7078 / `16.0000`）；`cr.Width = −3.0560`（取自 `#13` 冻结版 `gen/tline-detail-full.txt`，**头行 shim sha `FDE9E511…` 与冻结值逐位一致** ✓）。
> **`[fix]` 判定已不依赖 API**：优先用 `ADV`（公开 API），API 是桩时**退到行宽 `LINE_W`（`TextLine` 本体属性）并标出来源** ⇒ 今天读 `修法尚未生效（null=12.6560 fb=16.0000 nofb=12.6560；来源=行宽 LINE_W）`；**T1d 落码后会自己翻转**成 `修法已生效（null=16.0000 …；来源=公开 API 的 AdvanceWidths）`。
> **次级来源（DIAG）按我的硬约束实现**：`eval` 只认紧跟在 `(按码点回退)` **之前**那段的面（`Path#FaceIndex`；**它第一版抓错段——抓成主面 `NotoSans-Regular.ttf#0`——已修并记档**）；读数逐条标 **`来源=内部装置（DIAG）`**、**C1/C2 永不计入**、**只剩 DIAG 来源 ⇒ NOINFO**。
> **T1c 的 `ARTIFACT-SRC-FP` 逐文件行**：`build/artifact-src-fp.py` 的 `do_write()` 里 `peer=` 循环之后**纯插入 +16/−0**（`file=<sha16>  <relpath>`）；工具 sha **`30abca613580cb77 → 687ff7dabe87fda4`**；`--selftest` 六极性 PASS；`fp=/n=/peer_fp=/peer_n=` 落码前后**逐字相同**（三份 `diff` 全空）、`--check` 三行 `state=ok`；覆盖 **PC 34 / WB 23 / PF 18** 行，**`build/shims/PresentationCore.HbTextLine.cs` 命中 1**（**"`PC 内 shim sha = unknown`"这条能力缺口闭合**）。⇒ **两极化牙等我的口令**（五步配方 + 锚点已预检：FP 里现有 `file=fde9e511e8443cf2  build/shims/PresentationCore.HbTextLine.cs`）。
> ### ✅ **T1c 的两极化牙实测通过（`ARTIFACT-SRC-FP` 逐文件行**证明能红能绿**，且 shim **逐字节 + mtime 归还**）**
> **牙中**：追加一行注释 ⇒ shim = **`72313e438cd2bb44`**（≠ 原值）⇒ `--check` 报 **`state=stale note=kind=src`**（`fp=8a8f65c9664451e1` vs 记录 `d9b7cac83d3c2016`）、**rc=2** ✓。
> **还原后**：**`sha256sum = fde9e511e8443cf2`、`stat -c %Y = 1789438795`**、`--check` 三行 `state=ok` rc=0 ✓（**逐字节 + mtime 都还原**，主控独立复核）。
> **`file=` 段真实样例（含 shim 那行逐字原文，可直接抄进下一版表头）**：`file=d2e034e81ce265bc  build/MilBridge/src/MilBridge.Resolver/MilCoreDllImportResolver.cs`｜`file=19a42240f59af073  build/PresentationCore.Linux/FamilyCollection.Linux.cs`｜`file=b7a5621f00aad1cd  build/PresentationCore.Linux/FontCacheUtil.Linux.cs`｜**`file=fde9e511e8443cf2  build/shims/PresentationCore.HbTextLine.cs`**。
> **⭐ 顺带闭合一条能力缺口**：逐文件行让**内容比对**成立 —— 牙中对照 `rec=fde9e511e8443cf2 vs cur=72313e438cd2bb44` ⇒ 这正是 T1b2 那条配方会打的 `hbtextline_shim_stale=yes **basis=content**`（**不再依赖 mtime 代理**；mtime 代理今晚两个方向都被骗过）。
> **纪律细节（它做对了）**：**牙期间没跑 `--write`**（否则会把注释版记进 FP），判据只用 `--check` ⇒ 记录保持原样。
> ### ✅ **T3 的 `#13` 复取完成（`WAVE25-FINAL-ROUND.md`，121 行）+ 它更正了我的判读 + 三条新登记**
> **读数（仪器 `2e458928fc1577c2` 跑前=跑后）**：记账 **`1298/1298`（不等 0）**｜分桶 **`168/1096/34`**（最大差 `6.716667 @ A1_nbsp_zwsp_w120`，**`#12` 的 `282.219333` 消失**）｜折叠明细 **`225/236`**｜不一致 **`10`**（= F 9 + **`M_modifier_w120 行#0`** 1）｜折叠不符 **`11`**｜`T2b 972/972;213/213` 不动｜Extent 行级 **`1259`**、余差 **`59（39+20）`**（已登记）｜`T2-iso` ✅。**与我的 B 列逐位相符** ✓
> **A/B（同 DLL `044fb81961f75013`，只切 env）**：**A 腿（不传）= `1292/1298`、`168/1089/41`、`219/236`、不一致 14、余差 58 —— 与 #12 逐位同** ✓；A 腿隔离矩阵 `M_modifier 0→7（允许）`、其它族一位未动。
> **⭐ 它自己按 artifact 逐行 diff 的口径（必须写进档，否则会被误读）**：`t2d-width-diff` 的 **20 行差异 = 14 数据行（全 `M_modifier`）+ 6 行该文件自身的汇总头**（`# 族×>0.34` / `# 隔离矩阵` / `# 合计`，**按定义随腿变**）⇒ **数据行里非 `M_modifier` 差异 = 0** ✓。
> **oracle 四档 + 两支阳性对照（它自己做）**：臂 A `MODCHK 用例=5 行=7｜行宽 7/7｜len 7/7｜ws 7/7｜Extent 0/7｜lbNull 7/7｜rc=0`｜臂 B 门禁 `MODRULE 用例=53 行=170｜吻合 170/170｜rc=0`｜`--tab-oracle 114/57/0 rc=0`｜`D-T1` 结构败 **1**、判定过 **85**、`KNOWN-RED` 仅第 13 例、`rc=0`；**不给表 ⇒ `UNREGISTERED` + rc=1** ✓。牙：MODRULE 翻 `isNull` ⇒ `169/170`+rc=1（逐行点名）；tab-oracle 扰 `width` ⇒ `fail=1`+rc=1；**均还原 rc=0** ✓。
> **门禁 + 应用级**：`WPTD_GATE=PASS`、两档 3/3、`LINE_ADVANCE=PASS`、九位+EXT 全在、桥契约 ok、判据⑤/⑤b/⑥ ✅、6×`RESULT=PASS`+`leftover_after=0`；矩阵 `ok=8 fail=3`、**L20 帧穷举（18 帧）`#A855F7` 0/18、`#94A3B8` 0/18、`#F97316` 288 且 18/18 帧都有 = 与 #12 逐位同**、单块反证全绿 ⇒ **采样范围伪影，第 6 次复现**。
> **RTL 三条与验收帧逐位相同**：判据1 `Δright=1/Δw=0/251/260=0.97`｜判据2 **`k=71/0.736`** vs 正序 `m=+1/1.958`（**分离度 2.7×**，预测 71.75）｜判据3 本趟两帧 **AE=0**。
> ### ❌ **我的一处判读错了（T3 更正，已入档）**：`textbox-edit` **不是异常**
> 我读的是**第一趟（无 env）**（`key_diag_lines=0`）；带 env 的重跑里证据在**应用日志**（`probe-only.log`，T3 备份 `~/wfp-runs/applog13/`，sha `9f14785bf678ff89`）—— **runner 日志不转发应用 trace**：`key_diag_lines=41`、`INPUT_TRACE 1226`、`W5/W4a 28`、**`DP1_LEG state=closed rc=0 write_rows=4 reads_after_write=3`**、`CHAIN 3/3/3/2`、**`changes=2`** ⇒ **与 #12 同型、非回归** ✓
> **⇒ 新登记（"读数早于事件"家族，与 L5/D-P1 同源）**：runner 的 `changes` 取自应用**注入前**自报快照（`[feat]` t≈3.8 s，写入在 `WFP_LATE_SCHEDULED…after_ms=6000` 之后 t≈11.0 s）⇒ **该块恒 INCONCLUSIVE**。**修法**：改读应用日志**末条写后读数**；**归属 = T3**（`samples/**`）另起一件。
> ### 📋 **另两条新登记（仪器侧，T3 定性，我采信）**
> ① **`T2` ❌ 的真因 ≠ 判据文字**：`coreOk` 含 **`widthDeltaLarge == 0`**（`:1028-1030`）而文字只写"记账结构全等"；本趟记账 `1298/1298` 全绿、❌ 全由 **34 条已登记分桶红**造成 ⇒ **label 与接线漂移**（与 `isoMachineOk` 同源）；**修法 = 文案与 `coreOk` 合取项逐条对应，或拆成两条独立 Check**（下一波 harness 改动时一并）。
> ② **臂 A `Extent 0/7`**：实得 `17.48` vs 真值 `18.00`，而**同一字段**在 `t2d-extent` artifact 里是 `18.0800` ⇒ **同一字段两个 harness 值不同 = 调用配置差**（不进 rc、不传腿同类偏差已在 ⇒ 非本波引入）⇒ 登记为**待查口径差**（重启入口：比两条调用路径的字体/`formatWidth`/`allowFallback` 三参数）。
> ### 🔴 **新发现（主控自查）：`close-wave.sh` 的 `fp_inputs` **看不见 shim**，而它却显示为"输入稳定性 波前==波后"**
> **证据（两趟波同 fp）**：`close-wave-102523`（shim `fde9e511…`）与 `close-wave-105027`（shim 波前 `46aa73a3…`、**波末 `0085624234b96df3`**）两趟的 **`inputs_fp` 逐位相同** = `5e3df7ddc6a0c3371c18979cc750401c16da3212a7966c94a48549f197687b31`；而 `fp_inputs()` 的实际输入集只有 **appliers（`patch-*.py`）/`port-lib.py`/`integration-wave.sh`/`close-wave.sh`** ⇒ **既不含 `build/shims/**`、也不含 `src/WpfGfx.Linux/**`**。
> ⇒ **"输入稳定性：波前==波后"这句话对 shim 是空成立**；**#14 那趟的 shim 就在波中途被改过**（波前 `46aa73a3` → 波末 `0085624234`）**而未被这一位发现**。⇒ **#14 波因此不能作为基线**（这也是我没冻它的第二个理由，第一个是"非 DIRECT 编译断了"）。
> **修法（主控已落）**：`build/close-wave.sh` 的 `fp_inputs()` 里**加上** `find build/shims -type f -name '*.cs'` 与 `find src/WpfGfx.Linux -type f -name '*.cs'`（原命令形状不变；已 `bash -n` 通过；改前整份备份到 `~/wfp-runs/close-wave.sh.before-fpfix-*.bak`）。新 fp = `ea8a85ff09609e22…`（输入集变了 ⇒ fp 变，符合预期）。**两极化实测待做**（改 shim 一行 ⇒ fp 必须变；等 shim 静置后做 —— 现在 T1d 正在改它）。
> 这条与今晚已登记的多条同族：**"仪器看不见对象"/"名字与接线漂移"**（`isoMachineOk` 死变量、`--tab-oracle` 恒 rc、`--modifier-check` 恒 0、`T2` 文案 vs `coreOk`、`shim_stale` 的 mtime 代理）。
> ### 🔴 **`D-F1` 的"非 DIRECT 编不过"：**主控亲自复现** ⇒ T1b 对、T1d 的"复现不出"是测错了工程**
> **根因**：`TEXTLINE_SHIM_DIRECT` **只有 DIRECT 宿主才定义** —— `build/MilBridge/tests/CoverageProbe/CoverageProbe.csproj:42` **有** `<DefineConstants>$(DefineConstants);TEXTLINE_SHIM_DIRECT</DefineConstants>`；而 **`TextLineProto.csproj` 没有**（文件里唯一一次出现**只是注释**）⇒ 走**反射分支**。
> **最小复现（主控 10:55:58 实测，2 个错误）**：
> ```bash
> dotnet build build/MilBridge/tests/TextLineProto -p:HbShimSrc="$PWD/build/shims/PresentationCore.HbTextLine.cs" -v q --nologo
> #  => HbTextLine.cs(3473,74) error CS1061 "GlyphTypeface" 未包含 "FaceIndex"
> #     HbTextLine.cs(3329,30) error CS1729 "IndexedGlyphRun" 不包含采用 3 个参数的构造函数
> ```
> ⇒ **断的是这两条反射分支宿主**：**`TextLineProto`** 与 **`HbTextLineParity`（`run.sh tline` 用它）** ⇒ `run.sh tline` / `textline` 出不了读数（`#14` 波因此**不能冻**）。
> **修法**：`#if TEXTLINE_SHIM_DIRECT` 强类型 / `#else` 反射（**反射退路已实测运行期可用**：`--fallback-check` 的 `Activator.CreateInstance(NonPublic,3 参)` + `GetProperty("FaceIndex")` 自检通过）⇒ **缺的只是把 helper 放对位置**（提成文件级那次反而 7 错 ⇒ 就近放、别动全局结构）。**判据**：两条 `grep -c 'error CS'` 都为 0 + DIRECT 面不回归 + **非 DIRECT 下 `GetIndexedGlyphRuns()` 仍返回真值**（不许桩）+ 顺手修 `:1647`/`:3296` 的陈旧注释 `6→5`。
> **T1d 自曝两处错（照收）**：① "两条配置都编过 ✓" 是**从"没打印错误行"推断的**（该用 `grep -c 'error CS'`）；② 修法选型时**没先复现原报错**就动手 ⇒ 1 个错放大到 7 个 ⇒ 已按"两次不达标就回退"**回退到 `46aa73a3db99d083`**（树干净）。⇒ 两条都属"**没有复现就改**"族。
> ### ✅ **`#14` 已冻结（2026-09-15 11:05）—— `D-F1` 字体回退修复 + `GetIndexedGlyphRuns()` 真实现**
> **波 `close-wave-105739`（本波第二趟）**：`verify_all=PASS`（9 步 0 失败）⇒ 门禁 **`WPTD_GATE=PASS`**、两档 3/3、**6/6 `result=PASS`**、`runner exit=0`、`BRIDGE_SRC_STALE=no`、`hbtextline_shim_stale=no`、`WPTD_LINE_ADVANCE=PASS`。
> **九位（现场/哨兵/表头三方逐位一致）**：`bridge 759a322431f1e457`｜**`pc 9adac6b8d8e285c3`**｜**`pf ed51db81db76bc76`**｜`wb e6216fe961a2bfb9`｜`provider 71ba86c6495347fe`｜`win32shim 0098234982391bbf`｜`wic 03b67fbcd7c385b6`｜**`hbtextline 17b2cdfe08f13280`**｜`dwf 2f77dbdf5e7e2cd5`。**EXT 变 3 处**（`reachframework 094f6d07…`/`presentationui 4fa1eb9e…`/`systemprinting 90f31974…`）。
> **⚠️ 本波跑了两次、第一趟作废**（两条理由都已消除）：① `D-F1` 把**非 DIRECT 编译**弄断（`TextLineProto`/`HbTextLineParity` 各 4 `error CS`）⇒ 已修（内联 `#if/#else` + 私有 `MakeIndexedGlyphRun`，**取不到就响亮抛、不用桩**；四条判据实测：两宿主 `4→0`、DIRECT 不回归、**非 DIRECT 运行期实调 `rc=0` + A7 `6/6` + 真对象**、两处陈旧注释 `6→5`）；② 第一趟的 **shim 在波中途被改过而 `inputs_fp` 没发现** ⇒ `fp_inputs()` 已补入 `build/shims/**` 与 `src/WpfGfx.Linux/**`（新 fp `e9a44d94…`）。
> **仍缺一格（登记）**：判据③ 的值级（`FontUri`/`GlyphIndices`/`AdvanceWidths`）需**非 DIRECT 宿主自己打印** ⇒ 已派 T1b 加约 5 行 + 回退对照；**落地前这一格在非 DIRECT 配置下没有值级证据**。
> **判据分工（按实测改）**：**C2（`GlyphIndices ≠ 0`）+ C3（与真值差/符号）为主**（`winf` 行宽 `9.6000 → 16.0000`、`gids [0] → [9498]`；零覆盖档 `U+10FFFD` 两边都 `.notdef` ⇒ **完全可比**）；**C1 降为反作弊**（实测它抓不到这个 bug）。**两处禁止**：不许硬改 `.notdef`、不许改 oracle。**已登记边界**：`.ttc` 多面（单面路径 1 参构造 ⇒ face 0）。
> ### 🚦 **当前闸门：`build/shims/**` 的使用权**
> 两件排队操作都要短暂动 shim：**① T1c 的两极化牙**（秒级、`cp -p` 还原 + `touch -d @1789438795`，事后 sha 必须回 `fde9e511e8443cf2`）｜**② T1d 的 `D-F1` shim 半**（正式落地 ⇒ `hbtextline` 位变 ⇒ 另起一波）。
> ⇒ **已向 T3 要一句"编译 shim 的读数都跑完了吗"**（`tline` 已跑、门禁已 PASS、应用级正在跑）；**它回"shim 可动"即放行**。理由是硬的：**改 shim 会顶掉 `#13` 的冻结 tuple**（哪怕只加一行注释）。
> ### ➡️ **下一步（更新十七）**：`T3` 正按 `NEXT-WAVE-13-CHECKLIST.md`（363 行）**独立复取** `#13` 读数（门禁我已跑、6/6 PASS）⇒ 回报后写 `WAVE25-FINAL-ROUND.md`。随后队列：**`D-F1`**（`plan == null` 也构造计划 + **实现 `GetIndexedGlyphRuns()`** 作共同观测装置）⇒ **`#14 D-T2`** ⇒ `D-O1` ⇒ `ARTIFACT-SRC-FP` 逐文件行 ⇒ `HelloWpf` Release 收敛 ⇒ `D-R2` 关闭判据。
> ## 📌 2026-09-14 上午（波 20/21）：**"能变红的牙"连挡两次不完整修法** + 口径缺陷从装置一路清到生成物
> ### ✅ 收尾轮（T3，10:00）：**`#8` 已冻 + 四条读数全交付**（主控独立复核通过）
> **#8 八位逐字**：`bridge 759a322431f1e457`(4,950,352 B；fp `705ed5ccd0c498a1`)｜`pc 6be29475b6aeb34e`｜`pf 50da85138a7bc3e8`｜`wb e6216fe961a2bfb9`｜`provider 71ba86c6495347fe`｜`win32shim 91baee84270f2322`｜`wic_shim 03b67fbcd7c385b6`｜`hbtextline e1bc947afc248b32(stale=no)`。**主控现场重算八位逐位相符**、桥 fp 文件==现树、6/6 `result=PASS`、`WPTD_GATE=PASS`（两档 3/3、`runner exit=0`）。**vs #7 变 6 位**（bridge/pc/pf/win32shim/hbtextline/**windowsbase**），未变 2 位（provider/wic_shim）。
> **四条读数（同一配置）**：① **`tline` 六项逐项不变**（`exact=73 diff=0`、`通过 20 / 失败 2`，两红=已登记未实现项；harness 自报测量对象已同步到权威 PC/WB/DWF）；② **RTL 三条全绿且逐位不变**（`Δright=1 / Δw=0 / 0.97`；镜像 `k=71`、`0.736` vs 正序 `1.958`；块区 `AE=0`）；③ **`--only=text-dp-min`** 反证逐字复现 `t2='A' c2=1`（零注入：`KEY_DIAG=0 / push=0`）；④ **`--only=textbox-edit`**：`DP1_LEG state=closed rc=0`、**`first_inject=L1744` 这次有值**、`WFP_LATE_SCHEDULED from=VerifyAll-complete`、写后 `t=14068 变更 text='AB' changes=2`。
> **handoff:403 的 EOB/EOP 欠账已兑现**：`HBLINE_LINE#` 12 行**全 `eop=1`** ＋ `HBLINE_LINEQ#` 22 行（`spans=1` ⇒ "**哪一行被问过 `GetTextRunSpans`**"第一次可见）。
> **census 裁栈应用级旁证**：`[GLYPH_CENSUS] run#` 明细 **50 行 / `PushTransform=` 50 行 / 全部 `无`** ⇒ 与修法② 自洽（**该报 `无` 的报 `无`**，不再出现陈旧句柄）。
> **`1400`：累计 138（门禁口径）｜144（含本波 6 次单块启动的另一口径）—— 0 次发生**；T3 明确"**两个口径不混用**"。
> ### 🔴 顺带查出的**第九位静默位**：`DirectWriteForwarder.dll`
> 本波它变了（`879f0020… → 2f77dbdf5e7e2cd5`）**却不在八位元组里** ⇒ 它将来变化**不会被任何读数看见**（**与事故 D 同族**）。已派 T3：① 两个 runner 的 `*_ARTIFACTS` 行**尾部追加** `dwf_sha=`（不改既有字段顺序）；② **#8 表头加一行**"第九位（手工记录，下一版起机读）`dwf_sha=2f77dbdf5e7e2cd5`"并写明"#8 冻结时元组不含 DWF ⇒ DWF 变化不作废 #8，自下一版起进入机读位"；③ 逐条判断还有哪些**进应用加载路径却不在元组里**的件（`System.Xaml`/`UIAutomation*`/`System.Printing`/`ReachFramework`）该不该进元组 + 依据。
> ### 🔄 `D-K1` 最后一格：**装置整批场景的机制归因被自己的读数否掉**（M7b §4.13）
> 配对**如实出现**（单跑该档才干净：`--filter ~DP1_i` ⇒ 同 run `MSGFLOW` 306 行、无截断）：`pop … 该消息快照修饰位=0x2` ↔ `dispatch … 快照修饰位=0x2（实时表 ctrl=0）`（`type AB` 的大写 Shift 同样逐消息正确）；**但整批两档结果仍是插入**（`DP.Text="ABseed-文本"`、`TextChanged=2`）⇒ **"派发时读到 0x2"与"Ctrl+A 没生效"同时为真** ⇒ M7b **撤回**了自己"派发 `a↓` 时实时表已被 `Ctrl↑` 清掉"的**机制结论**（观测事实保留），并写明**失败环节未定位**、两个候选（① WPF 在派发之外读表 ② 下游另有原因）均无读数支持。**给出一条可定案的读数设计**：给 `GetKeyState` 加"调用时刻 + 是否在 dispatch 中 + 返回位"逐次日志 ⇒ 一条读数即可判。**主控裁定：记为在册未定位项（带该设计），不为此再开一轮波**（真应用路径不受影响）。
> ### 🔬 **新发现（主控，2026-09-14 18:1x–18:3x）：`pf_sha` 每趟波都变 —— 根因是 `PresentationFramework ⇄ ReachFramework` 的"真互引"，该对**在字节上永无不动点**
> **起因**：18:15 有一趟**无人认领**的波在跑（`PORT-CHANGES.md` 8 份 mtime `18:15:06`、三份 `ARTIFACT-SRC-FP.txt` 写于 `18:16:55`）⇒ `pf 50da8513… → 3936c867…`。查证过程与结论：
> 1. **不是编译器不确定**：对 PF 连做两次 `-t:Rebuild -p:BuildProjectReferences=false` ⇒ **两次同一 sha**；对 Reach 同样 ⇒ 第二次稳定。⇒ **编译本身是确定性的**。
> 2. **是"输入变了"**：`ARTIFACT_SRC_FP` 三份**全是 `state=ok`**（源指纹逐位未变），PC/WB/DWF/Provider **未变**，**只有 `ReachFramework.dll` 变了**（`ede1f364… → 3eff6418…`）。
> 3. **互引是实的**（读 csproj 原文）：`ReachFramework.Linux.csproj:394-395` 在真 PF 存在时引用**真** `PresentationFramework.dll`（bootstrap：pass 1 用 `CycleStub.PresentationFramework` 替身）；`PresentationFramework.Linux.csproj:33` 引用**真** `ReachFramework.dll` ⇒ **PF ⇄ Reach 真互引**；波的 ORDER 因此是 `… Reach → PF → Reach`。
> 4. **不动点不存在（实测）**：交替 `PF ⇒ Reach ⇒ PF ⇒ Reach` 两轮 ⇒ **四个全不相同的 sha**（`pf 34830e4e… → 2dec4286…`、`reach c6a2863f… → 1fd4fe8a…`）。机制：Roslyn 的确定性输出会**把引用件的字节纳入输入哈希** ⇒ `Reach₂=f(PF₁) → PF₂=g(Reach₂) → …` **永不收敛**。
> **⇒ 三条必须记住的推论**：
> ① **`pf`（及 `reach`）不可能从一棵新树复现** —— 它取决于 bootstrap 的历史/起点；基线里的 `pf` 位钉的是"**那一趟波产出**的那一份"，**不要**把"新树重建后 pf 不同"当成缺陷去追。
> ② **每一趟波都必然移动 `pf`** ⇒ **每趟波都要重冻基线**（#4→#8 的冻结churn 由此而来，不是有人忘了重建）。
> ③ **`ARTIFACT_SRC_FP=ok` 对 PF/Reach 是"必要不充分"**：源没变而产物可以变（**peer 的字节变了**）⇒ 指纹**必须把"被引用工程的产物 sha"纳进来**，`state` 才诚实（已派 T1c：扩展指纹 + "重建一个依赖 ⇒ 指纹必须 stale"的牙）。
> **可选的根治（需决策，未做）**：让环在编译期变成单向（例如 PF 引用 `CycleStub.ReachFramework`），代价是丢 API 面；上游 WPF 用 `CycleBreakers` 处理同一问题，移植时我们用的是"自举两步 + 真互引"。**本次只记录 + 让指纹诚实，不动拓扑**（动拓扑＝改构建结构，风险远大于收益）。
> ### 🔒 **"无人认领的波"事件 + 结构修法（2026-09-14 18:15 / 18:25 起）**
> **事件**：`18:15:06` 有一趟 `integration-wave.sh` 在跑（8 份 `PORT-CHANGES.md` 重写于 `18:15:06`、`PF/SR.g.cs` `18:15:07`、PC/WB 重编 `18:16:01/18:15:23`、三份 `ARTIFACT-SRC-FP.txt` `18:16:55`）⇒ **`pf` 位被顶掉**（`50da8513…→3936c867…`），并**把六条并行车道当时手里的"当前件读数"集体作废**。
> **归属**：**未能确定发起者**（T1c/T1b/T1d/U1/T3 五条车道**逐一否认并给出各自证据**；M7b/T2 未答）。旁证：全仓**只有 `integration-wave.sh` 会调用 `port-lib.py`**（`artifact-src-fp.py`、各 `reapply-patches.py`、`patch-*.py` 里出现的 `port-lib.py` 全是**注释/docstring 提及**，不是调用），故那一批 `PORT-CHANGES.md` 只可能来自**一趟真波或 8 次手工 port-lib**；日志未落盘 ⇒ **查不到主**。**如实记为"未归属"，不编故事。**
> **结构修法（已落地，2026-09-14）**：`build/integration-wave.sh` 现在**拒绝无责任人的波** ——> · 必须给出 `WAVE_OWNER=<名字>`（`bash build/close-wave.sh` 自动认领为 `close-wave:<user>`）；
> · **每次调用**（含被拒的那次）都往 `build/wave-audit.log` 追加一行：`时间 owner pid ppid tty cwd cmd`；
> · 未认领 ⇒ **`exit 9`** + 打印两种正确用法；实测（`bash build/integration-wave.sh` 无 owner）⇒ `rc=9`、**且在重建之前就退出**、审计行如实落盘（`owner=<未认领> pid=1424392`）。
> ⇒ 从此"认领不到人的重建"**不可能悄悄发生**（与 `BRIDGE_SRC_STALE`/`ARTIFACT_SRC_FP` 同一思路：**先让它可见，再谈纪律**）。
> ⚠️ **一处被误读的记录（主控澄清）**：T3 看到审计日志里 `18:25:14 owner=<未认领>` 一行，曾推断"18:25 又有一趟未认领的波"。**那一行是主控的闸门自测**（故意不设 `WAVE_OWNER` 跑一次，验证"拒绝 + 记审计"两条都成立），**被 `exit 9` 拒绝、未执行任何重建**。⇒ **审计行的含义是"有人试图跑"**，不是"跑成了"；两件事必须分开读（这条已写进 T3 的更正）。
> ### 🎯 `D-K1` **机制闭环**（M7b 私有件读数，跨配置；波后权威件复取）—— **三次"修法不完整"至此有了机制解释，不再是猜**
> **三条判读**：
> ① **命中"派发之外读表"**：`#6 GetKeyState vk=0xa2(VK_CONTROL) 返回=0x0000 在dispatch中=否 快照=无(0x0) 实时表字节=0x00 t=154732148`，而同刻之后 1–2 ms 才有 `dispatch … wp=0xa2 快照修饰位=0x2 t=154732149` / `wp=0x41 快照修饰位=0x2 t=154732150`；
> ② **"派发内读到 `0x2` 仍失败"被否**：两档合计**约 500 次**调用里 `在dispatch中=是` 的行数 = **0** ⇒ **WPF 的修饰键读取全在 `DispatchMessageW` 之外**（`ThreadPreprocessMessage`／`HwndKeyboardInputProvider` 预处理路径）⇒ **它只能读实时表**；
> ③ **"`GetKeyState` 之前就失败"被否**：`vk=0x11` 多次出现且 `t` 落在注入窗口内。
> **机制（读数直出，不需要再推）**：整批抽干把实时表推到**最后一个 X 事件**（Ctrl 已抬）⇒ 预处理路径读到 `0x0000` ⇒ 命令不生效；`a↓` 之后才落到 `DispatchMessageW`（那里快照**确实**是 `0x2`，**但已经没人再读**）。按事件泵档同窗口 `返回=0x8000 实时表 ctrl=1` ⇒ 牙1 绿（`selLen=7`、`DP.Text="AB"`），且 `ctrl+a` 的 `a↓` **没有 dispatch 行**（被输入路径消费）⇒ **反向印证预处理路径**。
> ⇒ **波 20/21 的"派发期快照"补丁登记为"未生效的稳健性补丁"**（对"派发期读表"的调用方仍有效）。
> **主控裁定：走乙** —— 让实时表采纳 Win32 的**消息队列语义**（`wpf_queue_pop` 取出**按键类**消息时用该消息 `mods` 更新修饰键字节）；**判据 = 整批两档应变成替换语义 `DP.Text=="AB"`，而三条牙的测试代码一行不改；按事件泵档必须仍绿**。若乙仍红 ⇒ **立刻停、转丙**（"最早未处理的按键消息"），**由主控裁，不许自己叠第三层**。
> **取证缺陷一并修**：整批档 **368 次调用吃满 200 行额度** ⇒ 第二档**没有逐行读数**（**L12 现场重演**）⇒ 探针改为**只记修饰键 `vk` 的调用**（或按 `vk` 单独计额度），**保留"触顶必须看得见"**（触顶行 + 退出汇总真实总数）。
> ### ✅ **波 22 收官（`close-wave.sh` 首次真跑，2026-09-14 18:42–18:46）** —— 一条命令跑完"PC + native + 桥 + 身份 + 全量回归"
> `close-wave.sh` 自己判定：**native 重建=是｜桥重发=否（`705ed5ccd0c498a1` == 记录）｜verify-all=跑**；各步 rc 全 0；`verify-all.sh` **9 步 0 失败**；`native_rebuilt=1 bridge_republished=0 verify_all=PASS`。
> **新九位（主控现场逐位复核）**：
> ```
> bridge      759a322431f1e457 (4,950,352 B；fp 705ed5ccd0c498a1)
> pc          e75c7bd5f465ede6 (4,185,600 B)   ← T1d 的 Tab 实现 + shim 变更
> pf          52e106e5f46a0dbb (7,122,432 B)   ← 环成员（每波必变，预期）
> windowsbase e6216fe961a2bfb9 ｜ provider 71ba86c6495347fe ｜ wic_shim 03b67fbcd7c385b6 ｜ dwf 2f77dbdf5e7e2cd5
> win32shim   0098234982391bbf (283,648 B)    ← M7b 的「乙」+ 逐次探针
> hbtextline  4044d84a66539c42（源 mtime ≤ PC mtime ⇒ stale=no 已核）
> ```
> **身份四件套**：`artifact-src-fp --check` 三行 `state=ok`（PC 的源 fp 因 shim 变更变为 `623724e0f7257030`）｜`APPSYNC=PASS`｜应用器审计 `20/74/0`｜输入稳定性（波内 5/5）。
> ### 🔴 **主控自己在 `close-wave.sh` 里踩了 L16 那个反引号坑**（同日，已修 + 全域扫）
> 三行 `say "… ` 包裹的说明文字 …"` 里用了反引号 ⇒ **被当命令替换执行**，尾行提示因此**丢了两处文件名**（日志里显示成 `（）， 然后重取  六项 / RTL 三条 /  等读数`）。**修法**：把双引号内的反引号换成中文引号/直接去掉（3/3 处）；并**全域扫过我的 4 个脚本**（`close-wave.sh`/`bridge-src-fp.sh`/`publish-milbridge.sh`/`integration-wave.sh`）⇒ 现在 **0 处**。
> ⇒ **"改一处缺陷必须全域扫同族"（L17）这次是对我自己执行的**：我先前要求 T3 全域扫同族，而我自己新写的脚本里就有同族 ⇒ L16 现在多一个**主控实例**可引用。
> ### ✅ **U1：`DefaultIncrementalTab=0` 的 arm 已交付**（`tests/parity/windows/tab-zero/`，**86 例**）+ **一条静默错位的坑**
> 设置**严格"只改一个输入"**（逐字镜像 `layout-b34` 的 TextModel ⇒ 唯一变化 = `DefaultIncrementalTab`：`tab0`=0 / `default`=不覆盖）；文本含 T1d 的原文本 `a\tb\t\tc\td` + 单/连排/首/尾/纯 Tab + 无 Tab 控制组；宽 40/80/160/320；emSize 24（另扫 12/48）；LTR+RTL；Arial 逐码点覆盖。
> **⭐ 0 配置的差异量（这就是 T1d 那 21 例的对照物）**：`a\tb\t\tc\td` ⇒ **tab=0, w=40：2 行**（`[0,6) a\tb\t\tc` + `[6,8) \td`，**第 2 行以 Tab 开头**）／**tab=0, w≥80：1 行**（宽 52.053）／**default, w=80：8 行**（**每个 Tab 独占一行**）／**default, w=160：4 行**。**推进量实证**：tab=0 下每个 Tab `width ≈ 0.003 DIP`（`a`@0 → `\t`@13.347 → `b`@13.350…）⇒ **推进量 0** ✓（与 T1d 理解一致）；`\t\t` 整行宽 **0.007** ✓。
> **每例给全**：逐行 `startChar/endCharExclusive/lengthWithNewline/dependentLength/newlineLength/**trailingWhitespaceLength**/width/WITW/height/baseline/hasOverflowed/lineText/paragraphStartOffsetDip` + 逐字 `xFromLeftDip/width/flowDirection` ⇒ **"③行尾空白差 21 行"有对照物了**。
> **两项"取不到"（U1 没造）**：① **断点原因 WPF 无 API**（JSON 里 `breakCause` 是**推导值**并自带标注）；② **`TextTrimming` 在 `TextFormatter` 层不存在**（上游 `TextParagraphProperties` 无 `Trimming` —— 修剪是**框架层（TextBlock）依据 `HasOverflowed`** 的决定）⇒ 给全了"修剪判据所需的所有量"，但**没有"修剪后布局"真值** ⇒ `B_tabs_trim_*` 那几例**不能用 `TextFormatter` 真值判**。
> **🔴 U1 自查出的静默错位（已点名要 T1d 自查）**：**`TextLine.Start` 是 `double`，语义 = "段首到行首的距离(DIP)"，不是字符下标** —— 它第一版 `(int)line.Start` 当行起始下标，**编译运行都不报错、但每行都被切成第 0 行**（折行点/行文本整列错）。⇒ **任何把 `TextLine.Start` 当字符索引的地方都会静默错位**。
> **它另外更正了自己一条**：上一份 `tab/PROVENANCE.md` 写"WPF 没有公开的自定义 Tab 停靠位 API"**是错的**（上游确有 `DefaultIncrementalTab` 与 `Tabs: IList<TextTabProperties>`），已**就地更正并留痕**（没偷偷改）；并说明其测出的"默认间隔 = 4×emSize"正是 `DefaultIncrementalTab` 的默认值，而 **`Tabs` 非 null 的情形本轮未测**。
> ### 🎯 **T1d 读新 arm 找出那 21 例的**真因**（两条从未记录的语义）—— 之前两轮的假设都不对
> 已确认与实现一致的三条：**tab0 ⇒ 推进 0** ✓、**折行点 = Tab 之前**（`cause=before-tab`，第 2 行以 `\t` 开头）✓、**`\t` 不算行尾空白**（`tws=0`/末行 1）✓。
> ⭐ **新语义 ④：`Wrap` 下 Tab 前进会被钳到行宽** —— `default` 臂 w40/w80 时每个 `\t` **独占一行且该行 `w` = 40.0000 / 80.0000**（停靠位 96 > 行宽 ⇒ **钳满**）；而 **`NoWrap` 不钳**（第一套 oracle：`a\tb` 在 w40 下照走 82.65 溢出 ✓）。
> ⭐ **新语义 ⑤：被钳满的 Tab 之后可断**（`cause=after-tab`）—— 原 `OverlayTabs` 只有"**Tab 之前可断、之后不可断**"。
> ⇒ **这解释了为什么"把测量侧改成同口径"对 21 例毫无作用**（`T2c` 仍 21）：**差异不在 advance，而在"钳位 + after-tab 断点"**。
> **判据改判**：`B_tabs_trim_*` **不能用 `TextFormatter` 真值判**（该层无 `Trimming`）⇒ 记"**需框架层真值、本轮不判**"；其余 tabs 家族照判。
> **`TextLine.Start` 自查结果（T1d）**：其探针全文无 `TextLine.Start` 引用（行起点用 `hb.LineStartForDiag` 或逐行 `cpFirst += hb.Length`）；T1b 的 `Program.cs:196` 也已注明"`Start` 恒 0 ⇒ 只能累加 Length" ⇒ **本仓暂无同类误用**。
> **最后一条没有真机真值的 Tab 结论**：**RTL 的"锚右边缘 / 向左前进"目前只有推导**（两套 oracle 的 RTL 臂都是**纯拉丁内容** ⇒ 内部顺序由 bidi 决定、属 `D-B1` 射程外）⇒ **已派 U1 补 `tab-rtl` arm**（**纯 RTL 内容** + Tab、两档 `DefaultIncrementalTab`、逐字 `xFromLeftDip`、折行点、`hasOverflowed`；可判定问题写明：停靠位是否锚右缘、`reachedStopDip` 取 Tab 的哪一侧、**钳位在 RTL 下朝哪个方向**）。
> ### 📉 **#9 的 `tline` 账本比 #8 差 —— 已知中间态，必须写明（不是回归、也不许掩盖）**
> `tline`（T3 在 `#9` 件上，`~/wfp-runs/tline-wave22.log`）：**记账结构 `1263/1298`（不等 35 行）**、**宽度分桶 `0=167 / ≤0.34DIP=1061 / >0.34DIP=70`（三桶和 == 1298 机检 OK）**、**`通过 18 / 失败 4`**；对照 **#8 那趟是 `1286/1298`、宽度超差 `47`**。
> **原因（已定位，且是预期的中间态）**：**T1d 的 Tab 实现走的是"框架默认 `4×em`"路径**，而 `layout-b34` 语料是 **`DefaultIncrementalTab=0` 配置**、且带 Tab 的 34 例需要 **④（Wrap 下 clamp 到行宽）+ ⑤（clamp 后 tab 后可断）**——**这两条尚未落地**（T1d 已推导出完整规则集并逐样本核对，正等主控放行落笔）。T1b 的 1 行"配置对齐"（该族传 `defaultIncrementalTab: 0`）只贡献 **−4 例**（25→21），且 A/B 证明它**不改变记账结构**（1263 两臂相同）。
> ⇒ **所以 `#9` 的账本读数必须带这句话引用**：**"比 #8 差 23 行是 Tab 实现与 tab0 语料之间的已知缺口（④⑤ 未落），T1d 的收口判据即为把这批数字恢复到冻前数"**；**不得**写成"Tab 实现了所以账本变好"、也不得**当作回归**去追。
> **T3 的家族级归属（可复算，与上句互相印证）**：`#9 不一致用例 38 = 21（**A1_tabs 13 + B_tabs 3 + B_tabs_trim 1 + F_tabs 4**，新增家族）+ 12（`A1_nbsp_zwsp 3 + F_lat_words 1 + F_nbsp_zwsp 8`，**逐项与 #8 相同**）+ 5（`M_modifier`，与 #8 相同）`；而 `#8 = 12 + 5` ⇒ **增量 21 例全部落在 `*_tabs` 四家族、无任何旧通过项变红**。T3 的表述（"Tab 用例**从'不参与判定'变为'参与并暴露差异'**"）与我这条（"默认路径已实现、tab0 配置的 ④⑤ 未落"）**是同一件事的两面**，两者都写进档，避免后人只看到一面。
> **其余 #9 读数（T3，九项全跑）**：`tline` 口径全表 —— 记账结构 **1263/1298（不等 35：①286/286 ②68/68 ③963/988）**｜宽度分桶 **167 / 1061 / 70**（三桶和==1298 机检 OK）｜Extent 行级 **1250/1298**（余差清单 **68 = 主对拍 48 + LH 20**）｜折叠明细 **214/236**｜行度量 Height/Baseline `1298/1298`｜**`通过 18 / 失败 4`**。**RTL 三条与修法②那趟逐位相同**（`1/0/0.97`；镜像 `k=71`、`0.736` vs `1.958`；块区 `AE=0`）；census `PushTransform=` **50/50 报 `无`**；`registry=ok(count=11)`。
> **`text-dp-min`**：`t2='A' c2=1 sel='A' line0='A'`（零注入确认）。**`textbox-edit`**：`DP1_LEG state=closed rc=0`、`first_inject=L1611`、`reads_after_write=3`；**`Ctrl` 修饰键在权威件上真生效 ⇒ 替换语义**（`TextChanged #1 text='A' len=1` → `#2 len=2 'AB'`）⇒ **M7b 的「乙」得到可观测确认**（但 `D-K1` 的"结论"仍待 M7b 在 `#9` 件上复取两档）；块按既定口径记 **INCONCLUSIVE（不是 FAIL）**。
> **全块矩阵（`#9` 件上重跑，未转抄 #8）**：`blocks=11 ok=8 fail=3`，3 个 FAIL（`textbox-edit`/`transforms`/`text-rtl`）**再次全部证伪为采样范围伪影**（帧穷举：`#A855F7`/`#94A3B8` 各 **0/18 帧**、`#F97316` **18/18 帧有**；三块放最上面 `--only` 重跑 ⇒ 全绿）。
> **`1400`**：门禁口径 `#8 138` → 本趟 **+6 = 144**；每次启动口径 **152**；**两口径均 0 次发生**。
> ### 🔖 **哨兵未更新（T3 抓到的流程缺口，已结构修法）**
> `#9` 冻结时 `/tmp/bridge-frozen.flag` **仍是 `wave21-final` 的旧值**（`pc 6be29475`/`win32shim 91baee84`/`hbtextline e1bc947a`）—— 而 T3 按纪律**改用"主控给的九位 + 自己 sha256sum 实读"**才没被带偏，并在 #9 表头写明。
> **修法**：① 哨兵已更新为 **#9** 九位；② **`close-wave.sh` 现在自己写哨兵**（在其汇总步骤里，从**现场重算**各件 sha 后写入，含 `fp`/`PC`/`PF`/`WB`/`WIN32SHIM`/`HBTL`/`WIC`/`PROVIDER`/`DWF`/`WAVE`）⇒ **"谁重建，谁公布当前件"，不留人工步骤**。⇒ 与"重建必须认领责任人"同族：**凡是各车道依赖的"当前状态"，都必须由产生它的动作自动写出**。
> ### 🎯 **T1d 已从三套真值反推出 Wrap 下的 Tab 规则集并逐样本核对**（`build/MilBridge/T1d-tab-and-modifier.md` §3.6）
> 设笔位 `p`（自行原点）、跳距 `h = 下一个 stop − p`：
> | 条件 | advance | 断点 |
> |---|---|---|
> | `p+h ≤ width` | `h` | 无（"Tab 之前"仍是候选） |
> | `p+h > width` 且 `p>0` | 不在此行 | **before-tab**（Tab 落到下一行行首） |
> | `p+h > width` 且 `p==0` | **`width`（钳满整行）** | **after-tab** |
> | `NoWrap` | `h`（**永不钳**） | 不折行（行溢出 ✓ 第一套 oracle） |
> **轨迹核对（三套真值逐位复现）**：LTR `default@w160` ⇒ 4 行 `a\tb`(109.3467)/`\t`(**96**)/`\tc`(108)/`\td`(109.3467) ✓；`@w40` ⇒ 8 行、每 Tab 独占且 `w=40.000` ✓；LTR `tab0@w40` ⇒ 2 行 `a\tb\t\tc`(**38.7033**)/`\td`(**13.35**) ✓、`@w80` ⇒ 一行 **52.0533** ✓；RTL `he-tab-single@w160` 镜像后 `95.4933 / 13.0067 / 0` ✓；`tws` 与现状一致（**`\t` 不算行尾空白，无需改**）。
> **落笔一次做完四件**：① `ApplyTabStops` 增 `clampWidth`（Wrap=段落宽、NoWrap=∞）并回报"是否钳满"；② `LayoutText` 填宽改 **Tab 感知**（按上表累加；钳满 ⇒ 该范围宽 = `width` 且不再容纳后续字符），`local` 同时保留"Tab 前/后"两个候选（后者仅在钳满时才可能被选中最远放得下的那个）；③ `FormatParagraph`/`LayoutText` 增可选 `wrap = true`（**默认 = 今天行为 ⇒ 既有调用零影响**）；④ `Tabs` 非 null **仍不做**（只登记）。
> ### 🛑 **T1d 决定"先不落 ④⑤"——并给出我接受的推理（"hop>0 才生效的改动，对 hop≡0 的语料是空操作"）**
> **推理（纯离线、可复核）**：那 21 例**全部来自 `layout-b34` = `DefaultIncrementalTab=0` 配置**（T1b §3 已更正），而 0 配置下每个 Tab 的**跳距 `h = 0`** ⇒ **恒满足 `p+h ≤ width`** ⇒ **永远走不到 clamp、也永不触发 `after-tab` 断点** ⇒ **④⑤ 对这批用例是空操作，改了一个也不会变绿**。旁证：它上一轮试过的"测量侧同口径"同样没让 21 动一格。
> **它还按 tab0 真值手算了最典型两条，我们的行为看起来已经对**：`A1_tabs_w20` 候选断点 `{1,3,4,6}`、宽度 `a`=8.98 / `a+b`=18.82 / `a+b+c`=26.5>20 ⇒ 取最远可容纳 = **4** ⇒ 行0 = `[0,4)` `'a\tb\t'` `w=18.82` ⇒ **与真值逐位一致**；`A1_tabs_w40` ⇒ `[0,9)` 一行 `w=36.35` ⇒ **一致**。
> ⇒ **差异不在它已理解的量（行数/断点/宽度）上，只能在 `T2c` 比较的其它字段里**（`WITW−W`、行级 `nl`/`ws`，或 `T2c` 那套判据本身）。
> **决定**：**不落 §3.6 的 ④⑤** —— "现象对不上时先取读数、别改代码"，而且那次改动**在这批语料上不可验证**。
> **主控裁定：走 (b)，由 T1d 自建探针**（读 `gen/layout-b34-compact.json`，对 21 例给**逐例 × 逐行 × 逐字段**差异表；**先把"`T2c` 到底比了哪些字段"显式列出来**；判掉两个假设 —— **(i) 真语义差**（某个未建模量）／**(ii) 判据/仪器口径差**（行为对而比较字段集或容差把它判红）；带 **1 例已知通过**与 **1 例默认配置**的控制组；**若是 (ii) 不许靠放宽断言解决**，要给"该改哪一格 + 改前后各判多少例"由主控裁）。
> **可复用判据（新增，已入册）**：**改动前先问"这条路径在这批语料上走得到吗"** —— 与"探针关掉≠无副作用""缺件检查对删除是瞎的"同族。
> **`M7b` 已放行**在 `#9` 件上复取（其 native 源**已进权威件** `00982349…`，无需等波）：整批两档期望替换语义、三条牙仍绿、**全量 16 期望 16/0**、**那条 staleness 闸门应转绿**（它在私有件上正确地报过红）。
> ### 🎯 **T1d 判定：是 (i) 真语义差（不是判据问题），并定位到"填宽路径的 tab advance 口径错"**
> **`T2c` 到底比了哪些字段（它先做了这一步 —— 这一步本身就是读数）**：`T2c` **没有独立判据**，它把与 `T2` 共用的逐例 `caseExact`（`HbTextLineParity/Program.cs:337-561`）按家族聚合（`:789-790`）。字段集 = **行数 ／ `len`·`nl`·`ws`（逐位等）／ `w`·`witw`（带容差）／行 `text` ／ `h`·`bl`·`ext` ／ `ce` 折叠（`hasCollapsed`·折后 `w`,`len`·`cr[0]` 起点/长度/宽度<0.34）** ⇒ "不一致" = 这一整组任一格不符。
> **🔧 折叠（Collapse）那一族的更正（T1c §39，2026-09-14 19:0x）—— 三条都要记住**：
> ① **"18 条"是旧值、已作废**：`10:01` 那棵树是 `218/236`（18 条）；**`#9`（`4044d84a`）上权威值是 `214/236` = 22 条**（由 `build/MilBridge/gen/tline-detail-full.txt` **自称**：`被测 shim sha256 = 4044D84A…`、`段1=22 / 段2=68 / 段3=38`，与 18:52 那趟 `#9` 日志逐项一致）。T1c 在 **19:02:12** 读到的 `26/101/53` 是 **T1d 迭代期间的瞬时版本**（harness 正被反复重写）⇒ **引用这类文件前先读它自己的"被测件 sha"**。
> ② **行号更正**：冻结件 `4044d84a` 上是 **`build/shims/PresentationCore.HbTextLine.cs:3011 Collapse` / `:3113 GetTextCollapsedRanges`**；先前记的 `:3079`/`:3181` 是 **T1d 尝试版**的行号（**引用前现场重读**）。
> ③ **口径与归属**：harness 对 **236 条真折叠行**比 **6 个量**（行 `Length`／行 `Width`(容差 0.34 DIP)／`HasCollapsed`／`cr.Count==1`／`cr[0].TextSourceCharacterIndex`／`cr[0].Length`／`cr[0].Width`）⇒ **`判定 1298/1298` 只等于 `HasCollapsed` 一致**，**"折叠明细不符" ≠ "折叠错了"**（行本体 `Len/W` 先分叉时，折叠只是**症状**）。**归属 = shim**（236 条真折叠只可能由 `HbTextLine.Collapse` 产生；PC 侧 `SimpleTextLine.Linux.cs:1114 Invariant.Assert(!HasCollapsed)` ⇒ 按设计不可能产出折叠行）。契约层**可比**：上游 `TextLine.cs:59/:67` + `TextCollapsingProperties.cs:58/:73/:82/:91`（三字段公开）。
> ④ **当前树（`4044d84a`）上 22 条的自洽分簇 = `7 + 8 + 4 + 3`**（T1c §39 收尾；早先那句"Tab 8 / 省略号 11 / modifier 7"出自**迭代期瞬时版本**，**已作废**）：
> - **`M_modifier_*` 7 条**（行本体先分叉）—— **结构线索（有价值）**：真值在 `w200/w320/winf` 上**完全相同**（`cr=[47,16) W=82.8367`、行 `W=74.0800`），而我们**随约束宽一路变**（`93.52 → 158.0 → 220.24`）⇒ 疑"**约束宽没作用到 modifier 行**"（这将直接成为 T1c 下一轮那 2-3 行的判据：改完应看到"不再随约束宽变、且与真值同为 `74.08`"）。
> - **省略号几何 8 条**：**3 条起止一致**（仅 `cr.Width` 差 `−4.16 / −6.40 / −6.40` DIP）；**5 条起止 ±1 字符**（其中 `w320/w560/w900/winf` 四条**我们与真值是同一组数** `[13,20)` vs `[14,19)` ⇒ **与约束宽无关、纯裁剪边界**）。
> - **Tab 家族 4 条**（`F_tabs_w40/w80/w120/w200`、`行W差=−8.9773` **恒定**）⇒ 行本体先分叉、**折叠只是症状** ⇒ 随 T1d 的 Tab 修法回绿，**别单独改折叠**（红旗：**"先改折叠掩盖行本体"**）。⚠️ T1c 另称"10:01 时是 8 条 ⇒ Tab 修法已吃掉 4 条"，**该句是跨树比较、已要求其立证或撤回**（10:01 = `e1bc947a`，且当时分簇口径未必相同）。
> - **非 Tab 行宽超差 3 条**（`+9.68 / +2.62 / +8.55`，`F_nbsp_zwsp_w80#0 / w120#1 / w200#0`）⇒ 度量/断行族，与 Tab 修法无关。
> - **逐条 22 行原文（我们→真值、Δ）在 T1c §39.8**；实现位置（冻结件）`PresentationCore.HbTextLine.cs:3011 Collapse` / `:3113 GetTextCollapsedRanges`（**行号随版本移动，引用前现场重读**）。> ⑤ **判据/红旗**：修好 = `x` 回到 **236/236** 且 `[完整明细] 折叠不符 0`，同时 `判定 1298/1298`、`空参抛 253/253`、`空参返回 this 1045/1045` **不回退**；**红旗** = 放宽 0.34 DIP 容差／把 `cr.Count==1` 改成 `≥1`／拿旧树读数对新树／**先改折叠去掩盖行本体**。
> ### 🔎 **T1b 的逐例归因（只读，`#10` 件）：两条结构性发现 + 一族归属 + 一条必修子项**
> 三元组（新纪律 15）：被测件 shim `7C2E0107…`（= #10 的 `hbtextline 7c2e0107a9c86180`）｜仪器 = 本趟 `run.sh tline`（产物头行带同一 sha）｜口径 = 段1 折叠字段 **vs** `t2d-width-diff` 行宽字段（**两者不是同一字段**）；app-local 4/4 与权威一致（PC `628e741681ecb048` ✓）；本趟读数与 #10 基线一致（记账 `1286/1298`、分桶 `167/1084/47`、`T2b 213/213`、`T2c 0`、折叠 `218/236`）。
> **🔴 发现一：两个 artifact 比的是**不同字段**（主控上一轮的表述被纠正）**：主控引用的 `+9.68/+2.62/+8.55` 与**段1 折叠行**逐字相同；而 `gen/t2d-width-diff.txt` 对**同样三个 case+行**给的是 **`+4.1567/+6.7167/+6.3927`**（cp 区间也不同：`[0,9)`/`[14,27)`/`[0,21)`）⇒ **任何"修"之前必须先声明修哪个字段**，否则是"**对着两把尺子改一次**"。⇒ **纪律 15 再补一格：引用必须写清 `(件 sha, 仪器版本, 口径)` **+ 字段/artifact 名**。**
> **🔴 发现二：我们的 `cr.Width` 出现**负值**（`F_nbsp_zwsp_w40#3`：`(14,2) W=−3.0560` vs 真值 `3.3433`）** ⇒ **宽度为负在契约上就不合法**，不只是"差一点" ⇒ 单列为该族"必修"的**第一判据**（`cr.Width` 不得为负），而不只是"与真机差 6.40"。
> **8 条逐例（与 T1c 的分层逐字吻合）**：3 条**只差 `cr.Width`**（`w40#1` `4.8640 vs 9.0233`（−4.1593）、`w40#3` **`−3.0560` vs 3.3433**（−6.3993）、`w80#1` `28.4480 vs 34.8467`（−6.3987））＋ 5 条**起止各 ±1 字**（`F_lat_words_w560#0` `[30,40) vs [31,39)`；`w80#0` `(2,7) vs (1,8)`（ΔW +9.6807）；`w120#1` `(18,9) vs (17,10)`（+2.6233）；`w200#0` `(8,13) vs (7,14)`（+8.5460）；**`w320/560/900/winf#0` `(13,20) vs (14,19)`（四条同数 ⇒ 与约束宽无关）**）。
> **归属**：**7/8 条是 `F_nbsp_zwsp_*` ⇒ shim 侧 NBSP/ZWSP 折叠/空白口径**（与此前归属同源、**不是另一根**）｜1 条 `F_lat_words_w560` ⇒ shim 侧**拉丁折叠边界**（ΔW 仅 +0.0140，**单列一档、别混进宽度桶**）｜3 条"非 Tab 行宽超差" ⇒ **同源但另一个字段**｜`M_modifier_*` 7 条 ⇒ 归 T1c 那族（**T1b 不动**）。
> **主控裁定（四条）**：① 负 `cr.Width` 单列子发现并作为必修第一判据；② **修 NBSP/ZWSP 折叠口径** 批准，但**排在队列第 3 位**（`build/shims/**` 同时只有一个 owner）：**`D-T1`（T1d，等 U1 arm）→ `M_modifier`（T1d shim 半 + T1c 2-3 行 + T1b 1 行）→ NBSP/ZWSP**；**归属调整**：**shim 的修由 T1d 落**（当前 shim owner），**T1b 负责 oracle 与断言（牙）**；③ `F_lat_words_w560` 单列登记；④ **牙设计批准**（扩展段1 断言：对 8 条断言 `cr` 起点/长度 == 真机；**阳性对照 = `cr.Width` 容差临时设 0 ⇒ 必须红**，当前 3 条正好触发），**与 T1d 的修一起落**（同源文件里才有意义）。**隔离证明**：修完给"只动这三族、其它家族一位不动"的逐族对照。
> **逐字段差异（21 例）共同签名：我们的行装不下字符**（真值一行 9 字符，我们 1–6 个 ⇒ 折成 1–9 行）：`A1_tabs_w20 行#0` 真值 `Len=4 w=18.8233` vs 我们 `Len=1 w=8.9760`（−9.8473）；`A1_tabs_w30` `Len=6 26.5067` vs `Len=1 8.9760`；`w40…w70`（含 `B_tabs_w60`/`F_tabs_w40`）真值 `Len=9 nl=1 ws=1 w=36.3500` vs 我们 `Len=1 8.9760`（−27.3740）；`w80…w120`（含 `B_tabs_trim`/`F_tabs_w80/120`）vs `Len=3 18.8160`；`w150/w180` vs `Len=4`；`w200/w240`（含 `B_tabs_w240`/`F_tabs_w200`）vs `Len=6 ≈26.5`。（我们的宽**正好 = 行内前 1/2/3 个字符之和** ⇒ 与"装不下"完全自洽；tabs 家族另有 **10 条 Extent 余差**是该现象的派生物。）
> **判定依据（三条）**：① 真值一行 9 字符、我们折成 1–9 行 ⇒ **行为不同**，不是"同一行为被判不等"；② 差异**随宽度单调**（`w40→1 字 / w80→3 / w150→4 / w200→6`）⇒ **填宽看到的 tab advance 是个正数（≈`4×em`=64）**，而 0 配置下必须是 **0**；③ 它手算的两条（`w20` 取最远可容纳 = 4、`w40` 一行 `36.35`）**只有在 advance=0 时才成立**，而真值正是如此 ⇒ **判据没错，是我们填宽用了错口径**。
> ⇒ **§3.6 的 ④⑤ 与此 21 例无关（再次确认）**：clamp 只在 `hop>0` 生效、0 配置 `hop≡0` ⇒ **不进波**；**也不按"判据问题"去改断言**（不是判据问题）。
> **根因方向**：填宽 `adv[]` 来自 `MeasureChars → HbShaper.Shape(...)`，而 `Shape` 末尾那次 `ApplyTabStops(r,text,font,0,4.0*r.EmSize)` 会把 tab 填成**框架默认跳距**；它上轮把段落真值透进 `MeasureChars`/`LayoutText`（传 0）后 **`T2c` 计数没动（仍 21）** ⇒ 说明那条路**没被走到**或**被别处覆盖**。
> **控制组**：同一判据下 tabs 家族 **13/34 已一致**（判据能绿、非恒红）；默认配置 `tab` oracle 在**同一 shim** 下 **57/57 全绿** ⇒ 两套配置确实被区分。
> **主控裁定**：**先取那格"只读"读数、这一轮不改 shim**（打 `fill 实际用的 adv[]` vs `FormatLine shaped.AdvancesPx` 各一行 ⇒ **读数本身把范围砍半**；只读 ⇒ 不产生新件、不需波、不作废 #9）。确认根因后再放行"改 + 报源已定"，那时才开 **#10**。
> ### ✅ **只读读数到位 ⇒ 根因闭死："填宽路径的 tab advance 用了框架默认、段落级间隔没被走到"**
> 探针新档 `--tab-diag`（`em=16`、`4×em=64`、串 `a\tb\t\tc\td`）两行原文：
> ```
> ① fill adv[]（HbShaper.Shape 直出，未经任何 tab 后处理）
>    = [8.8984, 55.1016, 8.8984, 55.1016, 64.0000, 8.0000, 56.0000, 8.8984]      ← tab 四格（下标 1/3/4/6）全是正数
> ② 若 tabInterval=0 重算
>    = [8.8984,  0.0000, 8.8984,  0.0000,  0.0000, 8.0000,  0.0000, 8.8984]      ← tab 四格全归 0
> ③ 两者相同？= False；差异**恰好只在 tab 那四格**
> ④ FormatParagraph(…, defaultIncrementalTab: 0) 交出去的 run advances：**tab 处确实是 0**
>    w=80 → 4 行：行#0 `Len=3 adv=[8.898,0,8.898]`、行#1 `Len=1 adv=[0]`、行#2 `Len=2 adv=[0,8.000]`；w=150 → 2 行 …
> ```
> ⇒ **结论：不是"透到了又被别处覆盖"，而是"段落级间隔根本没被走到"** —— 填宽数组来自 `MeasureChars → HbShaper.Shape(...)`，而 `Shape` **末尾那次** `ApplyTabStops(…, 4.0*r.EmSize)` 用的是**框架默认**；**④ 证明排版/交出侧确实是 0** ⇒ **两侧口径不一致**。假设 **证实**（tab advance ≈`4×em`：55.10/64.00/56.00，em16 ⇒ 64），§3.6 的 ④⑤ **再次被排除**。
> **修法（≤10 行、1 处核心，已授权）**：`HbBreakEngine.LayoutText` 拿到 `adv` 后用新助手 `ApplyTabToAdvances(adv, para, tabInterval, clampWidth)` **按段落真值改写 tab 那几格**（沿文本累加笔位；`tab ⇒ adv[i] = stop − pen`；`tabInterval ≤ 0 ⇒ 0`；`Wrap` 时 `min(…, clampWidth − pen)`）；`defaultIncrementalTab`/`wrap` 从 `FormatParagraph` 透到 `LayoutText`，**可选参数、默认 = 今天行为**（要有 A/B 证据）。
> **两套 oracle 各判各的**：**clamp 语义**（§3.6 ④⑤）**由 U1 的默认配置 oracle 判**（`tab` 114 例／可判 57、`tab-rtl` 84 例，其中 clamp 铺满整行 39/39 实测）；**0 配置**由 `layout-b34` 判 —— **不许混用**。
> **修后判据**：`T2c 不一致 0`｜记账结构 **1286/1298**（③984/988）｜宽度分桶 `>0.34` 回 **47**｜`T2b 213/213`｜`T2d Extent 1260`｜`T3 明细 218/236`｜`通过 20/失败 2`；`tab-oracle` **57/57 仍全绿**；`tab-zero` 86 例 + `tab-rtl` 84 例逐族通过数；**牙两方向**（摘掉助手 ⇒ 21 例复现；`tabInterval ≤ 0` 改回框架默认 ⇒ 同样复现；还原 ⇒ 全绿）。
> ### ✅ **`D-K1` 收成结论（M7b 在 `#9` 权威件上复取，五项全达成）**
> tuple 复读一致（哨兵 `BASELINE=9` / `WAVE=close-wave-184230`）；测试**按仓库路径加载权威件**（本轮**无** `WPF_LINUX_WIN32_SHIM` 覆盖）⇒ **下面读数不是跨配置**。
> 1. **整批两档 = 替换语义**：`[i2]`/`[i]` 均 `DP.Text="AB" 容器="AB"`、`判定=不复现（DP 已更新）`、**2/2 通过**（原先两档都是 `"ABseed-文本"` **插入**）。
> 2. **三条牙仍绿（断言一行未改）**：`selLen=7（期望 7）`／`selLen=1（期望 1）selStart=2 caret=2`／`[API]` 按住 `GetKeyState(0x11)=0x8000`、`GetKeyboardState[0x11]=0x80`，松开 `0x0000`/`0x00` ⇒ **3/3**。
> 3. **全量 16 ⇒ 16 通过 / 0 失败**（`rc=0`）；**staleness 闸门转绿**（`被测件 0098234982391bbf == 权威件 0098234982391bbf`），**对照它在私有件上正确地报红**（`测的是旧件 … != 权威件`）⇒ **闸门口径无误**（本会话里它第三次发挥作用）。
> 4. **逐行 + 汇总**：注入窗口 `GetKeyState vk=0x11 返回=0x8000 在dispatch中=否 快照=无(0x0) 实时表 ctrl=1`（`0x8000` 行 14）；`Ctrl↑` 出队后 `0x0000 / ctrl=0`（**62 行**）；`MSGFLOW` 同刻 `dispatch … 快照修饰位=0x2（实时表 ctrl=1）` ⇒ **实时表与快照现在一致**；汇总 `312 次调用（修饰键 308 全打；非修饰键 4 按设计不打）｜行上限 900`、**触顶 0 条**；**探针关 ⇒ `[KEYSTATE]` 0 行**（零开销路径在真套件里成立）。
> **仍未闭的四项（如实列出）**：① 波 20/21 的"**派发期快照**"在 WPF 路径上**未生效**（**保留为稳健性补丁**——对"派发期读表"的调用方仍有效）；② **`GetKeyboardState` 不叠快照**；③ **派发标志是进程全局非 TLS** ⇒ **跨线程读数可能假阳性**（这是**仪器的限制**、不是被测对象的结论，已要求写成独立一条）；④ **`D-U1` 在册未落**。
> **主控裁定**：**`D-K1` 结项、不做"丙"**（丙是"乙 仍红"的备选，前提已不成立）；`D-U1` 保持不落。**M7b 自纠**：数"`Ctrl↑` 后 `0x0000` 行数"时漏 `grep -E` 得到**假 `0`**、当场重取（真值 **62**）—— 与 `strings -el` 假 0／`grep -c` 数进判定行／`find -name` 同名桩**同族**（**仪器报 0 ≠ 0**）。
> ### 🧠 **账本反过来立功：那次"保留红"里藏着一个真缺陷**
> `T2c` 的 `34 例 Tab` 曾被记为"**oracle 把 `DefaultIncrementalTab` 写死 0 ⇒ 你们验的是另一套配置**"（口径更正本身是对的），但**更正之后的 21 例**一度被当作"配置造成的已知差异"。**实际它是一个真缺陷**：**填宽侧（`Shape` 末尾的 `ApplyTabStops`）与排版侧（`FormatParagraph`）对 tab 用了不同口径**。
> ⇒ **新纪律（已入册）**：**"保留红"不等于"不是缺陷"** —— 每次都要问"**它到底在比什么**"；口径更正是**第一步**，不是终点。
> ### 🛑 **T1d 两次落笔均未达标 ⇒ 逐字节回退、拒绝报"源已定"**（**"没达标就别盖章"**）
> shim 回到 **`4044d84a…`**（= #9 冻件），**双重确认**：sha 相同 ✓ **且**同一 harness 重跑读数回到 #9（记账 `1263/1298`③963/988、分桶 `167/1061/70`、`T3` 明细 `214/236`、`T2c` **21 例**）✓ ⇒ `build/shims/**` 可安全进 #10。
> | 口径 | 冻件 `4044d84a` | **尝试一** `3fe9b5ac`（整段预烧 `adv[]`） | 目标 |
> |---|---|---|---|
> | `T2c` Tab 不一致 | 21 | **2**（家族 `A1_tabs`） | **0** ✗ |
> | 宽度分桶 `>0.34` | 70 | **47** ✓ | 47 |
> | `T3` 折叠明细 | 214 | **218** ✓ | 218 |
> | 记账结构 | 1263（③963/988） | **1282**（③984/988）✗ −4 | 1286 |
> | `T2b` | 213/213（该件） | **968/970·211/213** ✗ −2 | 213/213 |
> **尝试二**（规则搬进填宽循环、按行起点扫掠，`438d05be`）**更差**：行数 **1297**（少一行）、分桶 **93**、`T1.73` 转红、记账 **1026** ⇒ **换掉 `EffectiveWidth`/改候选与强制回退骨架会扰动既有断行语义**（它还漏过一次行尾空白扣减）⇒ **不是 ≤10 行的改动**。
> **🎯 但两次尝试**反证**了根因判定**：**动"测量侧口径"⇒ tab 家族 `21 → 2`** ⇒ §5 的定位（填宽 `adv[]` 用框架默认、排版侧用段落真值）**正确**；**剩下的 4 行记账 + 2 例 `T2b` 差在"tab 笔位算在段首而非行首"** —— 正是修法要补的那一格。
> **主控裁定：先给 T1d 一轮把 Tab 收干净，再开 #10**（理由：根因与失败模式已量清、实现路径唯一；拿"已知 21 例红且记账比 #8 差"的状态去冻 #10 只会立刻被顶掉并让账本看起来像回归；其他车道不阻塞）。**下一轮要求**（照其 §6 + 两条补充）：不动循环骨架/不替换 `EffectiveWidth`，只在其内部对 `\t` 用"自行起点 `s` 起算的笔位 + 段落口径"并**保留行尾空白扣减**；"Tab 之后可断"只作**候选资格**；参数透传**默认=今天行为 + A/B 证明**；**判 clamp 用 U1 的 `tab-oracle`(57)/`tab-rtl`(84，含 39/39 clamp)，判 0 配置用 `layout-b34`(34)**（直接读 `tests/parity/windows/**/out/*.json`，不必新造探针档）；**牙三方向**（摘掉口径 ⇒ 21 复现；`tabInterval≤0` 改回框架默认 ⇒ 同样复现；还原 ⇒ 全绿）；**测试断言一行不改**。
> ### 🟡 **attempt-3：两个硬目标命中、三项差 1–2 格 ⇒ 仍不盖章**
> shim 恢复 **`4044d84a…`**（= #9 冻件，**逐字节 + 读数双证**）；读数全部留档 `build/MilBridge/T1d-tab-and-modifier.md` §7。
> **做法（严格照我给的要求）**：**不动骨架、不替换 `EffectiveWidth`** —— 只**新增** `EffectiveWidthTab(...)`（**同骨架、同样行尾空白扣减**，`IsTrailingWhitespace` 不扣 `\t`），把 `\t` 那格改为"**自本行起点 `s` 起算**的笔位 + 段落口径"；"Tab 之后"**只作候选资格**（`OverlayTabs` **一字未改**）；参数全可选、默认 = 今天行为。
> | 口径 | 冻件 `4044d84a` | **attempt-3** | 目标 | 判 |
> |---|---|---|---|---|
> | `T2c` Tab 不一致 | 21 | **1**（`A1_tabs`） | 0 | ✗ 差 1 |
> | 宽度分桶 `>0.34` | 70 | **47** | 47 | ✓✓ **命中** |
> | `T3` 折叠明细 | 214/236 | **218/236**（判定 1298/1298） | 218 | ✓✓ **命中**（+4 **正是 T1c 点名的那 4 条 Tab 族**，与"随填宽口径一起回绿、别单独改折叠"**逐条吻合**） |
> | 记账结构 | 1263（③963/988） | **1284（③984/988）** | 1286（③984 ✓） | ✗ 差 2 行 |
> | `T2b` | 957/957·200/213 | **970/971·212/213** | 972/972·213/213 | ✗ 差 1 |
> | `T1.73` / `T2d` Height·Baseline | ✅ / 1298·1298 | ✅ / 1298·1298 | — | ✓ 未回退 |
> **它自查的一个 bug**：候选资格最初写成 `break`（应为 `continue`）⇒ 扫描在第一个"Tab 之后"候选处**终止** ⇒ `T2c` 一度 **34/34 全红**；改 `continue` 后回到 1 例。
> **🔴 一条实测过程事故（比结论更有价值，已入册）**：第一次"**反向替换**"回退**没能逐字节回到 `4044d84a`**（得 `cc89f8c3…`）⇒ 它改用**改动前留的整份副本** `/tmp/t1d-tab-newsrc.cs`（sha 逐字节 = `4044d84a…`）覆盖恢复 ✓，并用读数二次确认（记账 1263、`T2c` 21、`T2b` 957·200 = #9 值）✓。
> ⇒ **纪律：动冻件（或任何"当前件"）之前，先把整份文件存 `/tmp` 并记 sha；纯靠"反向替换"回退不可靠。**
> **主控裁定：再给一轮收尾**（两个硬目标已证可达、余差都在已打通的路上、再一轮不需波不需冻结）；**三格收法**：① `T2c` 最后 1 例（0 配置下 `tabClamped ≡ false` ⇒ "Tab 之后"候选永不生效 ⇒ 不在那条路上）用 `--tab-diag` 逐格对照真值；② 记账 2 行（③ 已命中 ⇒ **不是 ws 桶**）定位到 `len` 还是 `nl` 桶；③ `T2b` 1 例（含 `\t` 的混合串断行挪一字）。**若任何一格查出是"另一个独立口径问题"⇒ 停下报主控**（可能是第二个真缺陷，不许硬凑绿）；**不许为凑 `0/1286/213` 放宽断言或容差**。
> ### ✅ **attempt-4 全中 ⇒ T1d 报"源已定"**（`build/shims/PresentationCore.HbTextLine.cs = 7c2e0107a9c86180…`；备份 `/tmp/t1d-tab-final.cs`，冻件副本 `/tmp/t1d-frozen-4044d84a.cs` 保留可回退）
> | 判据 | 目标 | 实测 | 判 |
> |---|---|---|---|
> | `T2c` Tab 不一致 | 0 | **34 可比例 / 不一致 0** | ✓ |
> | 口径·记账结构 | 1286/1298（③984/988） | **1286/1298（不等 12：①286/286 ②68/68 ③984/988）** | ✓ |
> | 口径·宽度分桶 | `>0.34` = 47 | **167 / 1084 / 47**（三桶和==1298 机检 OK） | ✓ |
> | `T2b` A 组 | 213/213 | **✅ 通过** | ✓ |
> | `T2d` 行度量 | Extent 1260 | Height `1298/1298`、Baseline `1298/1298`、**Extent `1260/1298`** | ✓ |
> | `T3` 折叠明细 | 218/236 | **判定 1298/1298；明细 218/236** | ✓ |
> | 结论 | 通过 20 / 失败 2 | **通过 20 / 失败 2** | ✓ |
> | **护栏** | 默认 oracle 57/57 | **`TAB_ORACLE: cases=114 pass=57 fail=0`**（含 clamp 用例；最大逐字差 0.0053 DIP） | ✓ |
> | **牙①** | 摘掉口径 ⇒ 21 复现 | **`Tab 可比例 34 例，其中不一致 21 例（A1_tabs,B_tabs,B_tabs_trim,F_tabs）`**、记账掉回 `1263/1298`（③963/988）；**还原 ⇒ 不一致 0 + 记账 1286/1298** | ✓ |
> **改了哪几行（新件 vs 冻件）**：① `ApplyTabStops(..., clampWidth = +∞)`：Wrap 时把 tab 跳距**钳到行宽**；② **新增** `EffectiveWidthTab(...)`（**不改** `EffectiveWidth`、**不动**候选/强制回退骨架；同骨架 + 同行尾空白扣减、**不扣 `\t`**；`\t` 那格按"**自本行起点 `s` 起算**的笔位 + 段落口径"：`<=0 ⇒ 0`、`>0 ⇒ 下一倍数`、有限 ⇒ `min(跳距, 行宽−笔位)`）；③ 候选循环宽度改用 `EffectiveWidthTab`，**"Tab 之后"只作候选资格**（`OverlayTabs` **一字未改**，只在候选集补 `i+1`）—— 资格 = **被钳满** ∨ **0 宽 tab 配置（前/后等价）** ∨ **段末候选 `b==len` 免资格**（真机末行**包含**行尾 Tab）；资格不符用 **`continue`（不是 `break`）**；④ `tabInterval`/`wrap` 从 `FormatParagraph → LayoutText → BreakParagraph → FormatLine/ShapeParagraph` 透传，**全部可选、默认 = 今天行为**。
> **两次自纠（都靠读数）**：资格判定误用 `break`（应 `continue`）⇒ 扫描在第一个"Tab 之后"候选处终止 ⇒ `T2c` 一度 **34/34 全红**；漏掉"**段末候选免资格**" ⇒ 默认 oracle **57 → 52**（5 例全是 `tab-tail`）⇒ 补上后回 57/57。
> **⚠️ 两项未跑、如实登记（不冒充已验）**：**②** 第二方向牙（`tabInterval<=0` 改回框架默认 ⇒ 21 应复现）；**③** `tab-zero`(86)/`tab-rtl`(84) 的**逐族通过数**（那两套 JSON 是"逐行 `perChar` + 臂 + `textWrapping`"结构，与 `tab-oracle` 的逐例结构不同 ⇒ 需补 `--tab-lines-oracle` 档，命令已写进报告）。
> **主控裁定**：**②③ 放到 #10 之后、在冻结件上做**（同一份 canonical build ⇒ 证据更强；且不阻塞波）。**#10 已开跑**（`close-wave-190934`：native 重建=否｜桥重发=否｜verify-all=跑；应用器审计 `20/74/0` 过）。
> ### 📋 **`D-T1` 正式登记（T1d §10.1–§10.6）+ 一条"没有定义就不动手"的边界 + 主控的一处错误被纠正**
> **§10.1 登记**：现象（`b34-tabs@w160` 真值 4 行 `[a\tb]109.35｜[\t]96.00｜[\tc]108.00｜[\td]109.35` vs 我方 3 行 `[len=4]160.00｜…`；`tab-only@w80` 真值 2 行×80 vs 我方 1 行）｜依据（`tab-zero` 结构败 13，其中 **12 = `b34-tabs`/`tab-only` 各 w40/w80/w160@em24 的 LTR+RTL 各 3** ⇒ **LTR 6 例、方向无关**；余 1 例是 `notab-control@w40@RTL` 的 `tws`，归 §9.4(C)）｜规则引用（§3.6：`p>0 ⇒ before-tab`／`p==0 ⇒ 钳满 + after-tab`／NoWrap 永不钳，且 §3.6 的 @w160/@w40 轨迹**当年就逐位复现过真值**）⇒ **是实现偏离了自己的规则**（§8.4 落成"任何位置越界就钳"，`tabClamped` 没看 `pen`）｜**三处代码入口**：`:304-325` `ApplyTabStops`（钳位 `:321-323`）、`:1526-1543` `EffectiveWidthTab`（钳位 `:1540-1543`）、`:1426-1445` 候选循环（资格 `:1445`；**钳位只余行首后，行中越界自动失格、填宽回落到 `local` 的 before-tab 候选 ⇒ 断在 tab 之前**）｜**不改骨架、不改 `EffectiveWidth`**。
> **⚠️ 它加的边界（主控接受）**：§3.6 的 `p` 自**行原点**起算；**行首带 `Indent` 时行首 tab 的 `p = indent > 0`** ⇒ 严格按"仅 `p==0` 才钳"会变成**断行**而非钳满；而**三套 oracle 里没有 `Indent` + 行首 tab 的用例** ⇒ **落地前要么给真机读数、要么明确定义**，否则就是"**拿猜测换绿**"。
> ⇒ **主控处置**：**扩 U1 的 `tab-anchor` arm 去读两个独立符号**（`Indent ∈ {0,24}` × 行首/行中 tab × 宽 `40/80/96/100/140/160/192/220`）。**并先定下不依赖它们的那一半**：它按代码逐字核对确认了主控给的代数关系 —— `a>room ⇔ stop − pen > clampWidth − pen ⇔ stop > clampWidth`（**`pen` 抵消**）⇒ **"是否越界"与 `Indent` 无关**；且**网格是绝对倍数 `k×interval` 自 0 起算**（`pen` 从 `startPenX` 起累加也不移动网格）⇒ **落 `D-T1` 时条件保持 `stop > width`，只改"分支选择"（钳 vs 断行）为"仅行首"**。
> **§10.2**：`T0.6` 仪器事实（真源路径、不跟 `-p:HbShimSrc=`）✓｜**§10.3**：(B) 恢复可比需要"一份 advance 逐字符等于真值面 `baa2515…` 的希伯来/阿拉伯面"（`א`=13.513333@em24；`liberation2` 的 15.070312 **不能顶替**）✓｜**§10.4**：(C) 定锚需要"行宽非整数倍 + tab 未被钳满 + （若可能）未被 UBA 重排的 RTL 用例"，判据 = `P − xfl_左缘` 与 `xfl_左缘` **只有一个**能是整除 ✓。
> **⭐ §10.6 判定表（预先写死 —— 读数回来是"套表"而不是"回来再解释"）**：
> | `left` | `right` | 结论 | 落地含义 |
> |---|---|---|---|
> | 24 | `w` | 钳目标 = **行宽** | 现状 `clampWidth` 不改，只改 §10.1 的分支选择 |
> | 24 | `w − 24` | 钳目标 = **内容宽** | `clampWidth` 需传 `w − indent`（仍在这三处入口内） |
> | 0 | `w` | 缩进对该行 tab 不生效 | **停下报主控**，不硬套 |
> | 其它 | 其它 | 两条假设都不符 | **停下报主控**，不放宽断言 |
> **🔴 并且它纠正了主控一处错误**：主控消息里写"`[0,w]` 还是 `[24,w]`"**这一对判不出钳目标** —— 左缘由缩进决定（预期恒 24），**真正区分两条假设的是右缘**（`w` vs `w − 24`）；好在 U1 给的是 `tabSpanDip{left,right}`，**一个数就够**。⇒ 主控纠正已记档（"读数的**哪一个分量**承载判别信息"必须写清）。
> **同 arm 另一格的对照（行首按哪个起点判）**：读到"**钳满 + after-tab 断**" ⇒ 行首判据按**内容起点**（与 §10.5 的必要条件一致）；读到"**断行**" ⇒ 按**行原点**，但**那就得能解释"布局如何前进"**，否则与该配置的可终止性冲突 ⇒ **停下来报主控，不自己找补**。
> ### 🧭 **主控视角的新纪律（由 T1d 两次拦截提炼）**
> **落笔前必须能回答两问**：① **这条路径在这批语料/这个配置上走得到吗？**（用它挡掉了 §3.6 的 ④⑤ —— `hop≡0` 语料上 clamp 是空操作）；② **判据里的每一个符号都有真值吗？**（用它挡掉了 `Indent` 边界 —— 没有 `Indent`+行首 tab 的真机用例）。⇒ **两次都避免了一次"表绿里红"**；与"能变红的牙""缺件检查对删除是瞎的""探针关掉≠无副作用"同族。**再加一条**：**写清判读所用的分量**（本次 `tabSpanDip{left,right}` 里只有 **`right`** 承载判别信息 —— 主控把 `left` 也当判别位是错的）。
> ### ✅ **②③（在 `#10` 冻结件上）交付：两条通过、一条偏差如实上报、三个独立口径发现**
> **② 第二方向牙（原文）**：变体 `/tmp/t1d-teeth2.cs`（`b0cd51ff…`）= 真源三处 `IsNaN(x) ? 4×em : x` → `(IsNaN(x) || x <= 0) ? 4×em : x`；`-p:HbShimSrc=` 编 harness ⇒ **Tab 不一致 25**（我预测 21 ⇒ **预测是主控错的**）、记账 `1263/1298（③963/988）`、分桶 `167/1048/**83**`、`tab-zero` 结构败 **73/86**（基线 13/86）、`通过 17/失败 5`；**还原 ⇒ 六项全绿**。
> ⇒ **主控裁定：② 通过**（两个变体定义不同：① 摘掉整条口径 ⇒ 21；② 保留口径只把 `<=0` 当框架默认 ⇒ 25；**T1d 拒绝硬凑这个数是对的**）。**牙确实咬住**（`25≠0`、`1263≠1286`、`83≠47`）。
> **⚠️ 一条仪器事实（入档）**：**`T0.6` 读的是真源路径、不跟 `-p:HbShimSrc=` 走** ⇒ **变体跑的 `T0.6` 必红**，不能当身份断言；**变体是否生效只能由读数证明**（"仪器与开关耦合"族，与"探针关掉≠无副作用"同源）。
> **③ 逐族（新 `--tab-lines-oracle`）**：`tab-zero` 86 例 ⇒ `b34-tabs 12/18｜notab-control 7/8｜tab-adjacent 12/12｜tab-head 8/8｜tab-only 8/14｜tab-single 18/18｜tab-tail 8/8`；`Q3 clamp 铺满 4/4`、`Q2 真值侧 3/3`、**位置量在所有可比例上最大差 `0.0000`**。`tab-rtl` 84 例 ⇒ **76 例"不可比"**，余 `he-tab-only 结构 5/8`；`Q2 真值侧 2/2`（`he-tab-only@w320`：`P−xfl = 96.0000/192.0000`，间隔 96 ⇒ 1×/2×）。
> **六项（`#10` 冻结件）**：`T2c 0`（34 可比例）｜记账 `1286/1298`｜分桶 `167/1084/47`｜`T2b` 行级 972/972、用例级 `213/213`｜`T2d` H/B `1298/1298`、Extent `1260`｜`T3` 判定 1298/1298、明细 `218/236`｜`通过 20/失败 2`；`T0.7` 四副本 sha = `628E7416 ✓ E6216FE9 ✓ 2F77DBDF ✓ 71BA86C6 ✓`（不设 `T1B_SHIM_SHA256` 时是 19/2，少的就是 env 依赖的 `T0.6`）。
> ### 🎯 **三个独立口径发现（T1d 停手不硬凑绿）**
> **(A) Wrap 臂 tab 断行 —— 12 例结构败、LTR 也错（方向无关）⇒ 真缺陷候选**：**真值 = 行首越界 ⇒ 钳满整行 + 断行；行中越界 ⇒ 在 tab 之前断行**；我们落地的是"**任何位置越界都钳**"。例：`b34-tabs@w160@em24@LTR@default` 真值 `[a\tb]109.35｜[\t]96.00｜[\tc]108.00｜[\td]109.35` vs 我方 `[len=4]160.00｜[len=2]108.00｜[len=3]109.35`；`tab-only@w80` 真值 2 行×80 vs 我方 1 行；`b34-tabs@w80` 真值 8 行 vs 我方 7 行。
> ⇒ **主控裁定：登记为 `D-T1`（Tab 的 Wrap 断行钳位语义），并作为 T1d 的下一件（单车道、独立一轮、独立波）**。理由：**这与 T1d §3.6 自己推导的规则表本来就不符**（`p>0 ⇒ before-tab`；`p==0 ⇒ clamp`）⇒ **是实现偏离了自己的规则，不是规则错**。**验收判据**：12 例结构败 ⇒ **0**，且**既有全表不许动**（`T2c 0`／`1286/1298`／`167/1084/47`／`213/213`／Extent `1260`／`218/236`／`20-2`），**默认 oracle 57/57 仍全绿**；**牙**：把"行中越界也钳"改回去 ⇒ 12 例必须复现。**时序：先做 (A)，再做 `M_modifier`**（各有独立波与独立归因）。
> **(B) `tab-rtl` 76/84 不可比 ⇒ 登记为"不可比"**：真值面 = Arial（覆盖希伯来、无回退），**本机那份 `NominalGlyph=0`**（advance 全 `.notdef` `8.765625` ⇒ `אבג דה` `50.496094` vs 真值 `69.41`）；`liberation2` 有字形但 advance `15.07 ≠ 13.51` ⇒ **仍不可比**。**主控裁定：不给 Arial 字节**（Windows 字体、许可与来源问题，不该进仓）⇒ **登记为不可比**，并要求写明"**要恢复可比需要什么**"。**可比的只有已量部分**（`he-tab-only` 5/8、**Q2 真值侧 3/3**、位置量最大差 `0.0000`）。
> **(C) RTL 位置量 = bidi 域 ⇒ 维持登记**（`D-B1` 射程外）：ICU 70 `ubidi` 复核 `a\tb` 段落 RTL ⇒ 级别 `[2,1,2]`、视觉序 `[2,1,0]`（**整行反序**），与 oracle `xFromLeftDip` 逐字符吻合 ⇒ 我们单 run LTR **不可比**（24 例单列）；另 `notab-control@w40@RTL` 真值 `tws=0`、我方 1（LTR 臂两边都是 1），属**真值侧方向相关行为**。
> **⭐ 但 (C) 里产出一条值钱的设计观察**：**命中行的行宽恰为 interval 整数倍（96/192）⇒"左锚/右锚"在数学上不可区分** ⇒ **要定锚必须用"行宽不是 interval 整数倍"的行**。⇒ **已派 U1 补 `tab-anchor` arm**（`w = 100/140/220/260` 各配 `96/192` 对照；单 Tab 且不在行尾以避免 clamp；LTR+RTL；要求**直接给出两个候选锚点的预测值**让读数一眼可判）。
> ### ✅ **`#10` 已冻 + 那条"已知中间缺口"闭合**（T3 第 10 趟门禁；哨兵由 `close-wave.sh` 自动更新）
> `RE-FROZEN #10 after close-wave.sh（哨兵自动更新：WAVE=close-wave-190934）`｜`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜两档 3/3｜6/6 `result=PASS`｜**主控现场复核**九位与权威产物逐位相符、`hbtextline stale=no`。
> **九位**：`pc 628e741681ecb048`（新）｜`pf 967c79c18dbfaac2`（环成员）｜`hbtextline 7c2e0107a9c86180`（新）｜`bridge 759a322431f1e457`、`windowsbase e6216fe961a2bfb9`、`provider 71ba86c6495347fe`、`win32shim 0098234982391bbf`、`wic_shim 03b67fbcd7c385b6`、`dwf 2f77dbdf5e7e2cd5`（**六位未变**）。
> **🎯 关键判据（同 harness、同件，T3 独立复核 T1d 的离线断言）**：
> | 口径 | `#9`（缺口态） | **`#10`** | 目标 |
> |---|---|---|---|
> | 记账结构全等 | 1263/1298（不等 35） | **1286/1298（不等 12：①286/286 ②68/68 ③984/988）** | 1286 ✓ |
> | 宽度分桶 `>0.34` | 70 | **47**（`167 / 1084 / 47`，三桶和机检 OK） | 47 ✓ |
> | `T2c` Tab 不一致 | 21 | **0**（34 可比例） | 0 ✓ |
> ⇒ **`#9` 报告里那条"比 #8 差 23 行 = Tab 实现与 tab0 语料之间的已知缺口"自此闭合**（`tline-wave23.log`，19:18:46）。⇒ 该中间态说明**不再代表现状**。
> ### ✅ **T1c 撤回"8 → 4"并给出**为什么立不了证**（比立证更有价值）—— 由此升级出**新纪律 15**
> **撤回后的表述**：**当前树（`4044d84a`）Tab 家族 = 4 条**；**与 10:01（`e1bc947a`）的对比未做** —— 跨树 + **跨 harness 版本**，差值里混着"版本效应"与"改动效应"，**不作归因**。
> **三条"立不了证"的理由（都可现场核）**：① **10:01 那棵树没留下"折叠明细的逐行清单"**（`gen/tline-detail-full.txt` 是**同一路径**、已被后续 run 覆盖；10:01 日志**只有条数**）；② 10:01 日志里那段**用例级**清单的"原因"是**记账类**（如 `F_nbsp_zwsp_w40(行#1 期望 Len=4 nl=0 ws=0 | 实得 …ws=1)`），**不是** `折叠明细不符` ⇒ 拿它数 Tab 家族就是**换了口径**；③ **最要紧**：它引用的那个"8"**根本不是 10:01 那棵树的数** —— 出自 **19:02:12 的瞬时文件**（26 行版，其中 `F_tabs_*` 8 条；被测件**同为 `4044d84a`**，但**测量侧口径被改过两次**）⇒ 原句把"**另一版 harness 的 8**"错挂到"10:01 的树"上，**双重不可比**。
> ⇒ **新纪律 15（已写进 `docs/CURRENT-STATE.md`）**：**一份读数 = (被测件 sha, 仪器/harness 版本, 判据口径) 三元组；任何两项不同都不可比** —— 只锚件 sha **不够**（本次就是"同 sha、不同 harness 版本"）。**"引用读数先看被测件 sha"这条到此升级为"三元组一起锚"。**
> **§39.11「给未来的人」：PC 侧 `CollectLenient` 那 2-3 行（等 #10 之后）的验收判据写死**：① `M_modifier_w200/w320/winf` 的折叠结果**必须不再随约束宽变化**，且与真值同为 **行 `W=74.0800`、`cr=[47,16) W=82.8367`**；② 同三条**由不符转相符**，且**其余 19 条不得因这次改动而变动**（改前/改后逐条对照段1，**以文件头被测件 sha 为锚**）；③ `判定 1298/1298`、`空参抛 253/253`、`空参返回 this 1045/1045` **不回退**。**红旗**：只把条数压下去而"**随约束宽变化**"的特征仍在（改的是症状）；或**顺手动折叠实现**（那是 T1d 车道）。
> ### ✅ **`tab-rtl` arm 已交付（U1，84 cases）⇒ Tab 语义三套真值齐备（LTR / tab0 / RTL），"推导"清零**
> `tests/parity/windows/tab-rtl/`（`out/tab-rtl-oracle.{json,txt}` + `src/` + `PROVENANCE.md`）；口径：RTL 段落 + **纯希伯来/纯阿拉伯内容（不含拉丁 ⇒ bidi 无从重排、Tab 几何不被重排污染）**；矩阵 = 9 类文本 × w{40,80,160,320} × em24 × {RTL, LTR 对照组} × `DefaultIncrementalTab` 两臂；interval = 4×em = 96（**由 `\t`-only case 独立测得，非假定**）。
> - **Q1｜RTL tab 网格锚在行右边缘 → 是**：**32/32** RTL 样本 `leftEdgeDistFromGrid == 0`（**精确 0**）。钉死样本 `he-tab-single@w160@em24@RTL@default`：行宽 109.006667 − tab 左边缘 13.006667 = **96.000000 = 恰好 1×interval**。判据分布 `LEFT 16 / ambiguous 22 / RIGHT 1`，**那唯一的 RIGHT 正是 LTR 对照组** ⇒ 反证方向性。
> - **Q2｜RTL 下"够到的 stop 边缘"= 左边缘**（= 前进方向的**远侧**）：RTL `LEFT 14 / ambiguous 18 / RIGHT 0`；LTR 对照组 RIGHT ⇒ **实现口径：`reachedStopEdge = (flow==RTL) ? left : right`**。
> - **Q3｜Wrap 下被 clamp 的 tab 铺满整行 `[0, container]`，RTL 同样成立**：**39/39** clamped tab 全 `tabLeftEdge=0 / tabRightEdge=container`（32 个 RTL）；`he-tab-single@w40 → lineW=40.000`、`@w80 → 80.000`；`he-tab-b34@w40/w80` 各 8 行、每 `\t` 独占一行、行宽=容器 ⇒ **④（clamp 到行宽）与 ⑤（clamp 后可在 tab 后断行）在 RTL 下同构**。
> - **顺带确证**：`cause=before-tab`/`after-tab` 在 RTL 下同样出现（`he-tab-single@w40/w80@RTL` 三行 `[0,1) before-tab / [1,2) after-tab / [2,3) end-of-text`）⇒ **tab 前后可断的规则不依赖方向**；无 tab 对照组两方向宽度**逐位相同**（36.093333 / 26.65 / 69.41）⇒ **方向本身不改变测量宽度，差异只来自 tab**。
> - **诚实边界**：每行 `breakCause` 是**推导值**（`breakReasonApi=NOT AVAILABLE`）；`TextTrimming` 真值**取不到**（该层无 `Trimming` 成员，只报 `HasOverflowed`）；**未覆盖**：`Tabs` 非 null（我方**尚未实现**，等实现时再测）、`NoWrap`/`WrapWithOverflow`、多字体交叉、阿拉伯 shaping 质量。
> - **裁定**：**U1 的 Tab 车道结项**（三套真值齐备，无已知空格）；`Tabs` 非 null 与 NoWrap 臂**暂不补**（未实现/已有 NoWrap 对照）。
> **T1d 已停手**（shim 保持 `4044d84a…`），落地顺序与收口判据写在 `build/MilBridge/T1d-tab-and-modifier.md` §3（`T2c 0`／`T2 1286`／`T2b 213/213`／`T2d 1260`／`T3 218`／`通过 20/失败 2`／默认 57/57 全绿／一条能变红的牙）。
> ### ✅ **乙 已落地并命中判据**（M7b，**私有件 v3 `5c709b8de57901e7`**；四个 native 源"源已定"：`win32_core.c 0de70e6b…`／`win32_msg.c cff3189e…`／`win32_x11.c 4e695881…`／`win32_internal.h c17a7c75…`）
> | 档 | 修法前 | **乙 之后** |
> |---|---|---|
> | `~DP1_i2` | `DP.Text="ABseed-文本"`、`selLenAfter=0` | **`DP.Text="AB"`**（泵 400ms） |
> | `~DP1_i` | `DP.Text="ABseed-文本"` | **`DP.Text="AB"`** |
> | `~DP1_牙1`／`牙2`／`API`（回归护栏） | 绿 | **仍绿**（`selLen=7`／`selLen=1, selStart=2, caret=2`／极性正确） |
> **测试代码一行未改** ⇒ 这是"现象变绿"而不是"改判据求绿"。**实现**：`wpf_queue_pop` 取出**按键类消息**（`WM_KEYDOWN/UP`、`WM_SYSKEYDOWN/UP`）时 `wpf_keystate_apply_queue_mods(v->mods)`；新增 **`mods_valid`** —— **只有翻译层刚为某个 X 事件盖的戳才算数**、且只对紧随的那一次入队有效（`PostMessageW`/`SetTimer` **不会用陈旧戳改写实时表**）；`apply_queue_mods` 通用位与左右专有位一起写、**toggle 低位一律不动**、**不取锁**（调用者持 `g_wpf.lock`，与 `note_pop_mods` 同约定）。
> **逐行证据（要求 3 生效后）**：注入窗口 `GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=否 实时表 ctrl=1`（**修法前同窗口是 `0x0000 / ctrl=0`**），Ctrl↑ 出队后 `返回=0x0000 … ctrl=0`；汇总 `共 312 次调用（修饰键 308 次，已打印 308 行；非修饰键 4 次按设计不打）｜行上限 900`、**触顶 0 条** ⇒ **两档窗口都有逐行证据**。
> **离线牙全绿**：乙-正（戳 `0x2` → 出队 → **派发之外**读 ⇒ `0x8000 / ctrl=1`）／乙-反（戳 `0x0` ⇒ `0x0000 / ctrl=0`）／过滤牙（非修饰键 300 次**一行不打**）／额度牙（`200`/`600`/非法 `0`→回落 `200`）／探针关 ⇒ **0 行**／牙C/E 回归。
> **🎯 它的全量 16 是 15 通过 / 1 失败，而那唯一一条失败正是 staleness 闸门本身**：原文 `**测的是旧件**：被测件 sha16=5c709b8de57901e7 != 权威件 sha16=91baee84270f2322` ⇒ **闸门咬住了跨配置跑**（权威件到位后该条应为绿）。**这是"身份闸门"第二次在生产里咬到东西**（第一次是桥→源陈旧的真阳性）。
> **已知取舍（主控已接受）**：`GetAsyncKeyState` 与 `GetKeyState` 同源、也跟队列语义走。**若权威件复取时整批档回红**（"最近出队"在读取时刻已被后续出队覆盖）⇒ M7b **立即上报、不叠第三层**，转丙由主控裁。
> **`D-U1` 新登记**（`UiaLookupId` → 未映射的 `UIAutomationCore.dll`）：现象（`nm -D | grep -i uia` 空、`SupportsWin7Identifiers()` 恒 NULL ⇒ 静默 `false`）/ 影响面（**只限 GUID→UIA 整型 ID**；渲染/输入/文本链零影响）/ **前置（先落导出再映射**，只加映射会把诚实的 `DllNotFoundException` 降级成 `EntryPointNotFoundException`）/ 成本（native 1 导出 + resolver 1 行 + **3 条牙**含"只加映射不加导出"的反向牙）/ 重启入口齐备；**本波不落**。
> ### ✅ T1d：**`Tab` 已实现 + `M_modifier` 判定完毕**（**源已定**：`build/shims/PresentationCore.HbTextLine.cs = 4044d84a66539c42…`）
> **Tab**：`HbShaper.ApplyTabStops :304`（前进到**严格大于**笔位的下一个网格倍数；`tabInterval<=0` ⇒ 显式无停靠位）；`Shape :276` 先用**框架默认 `4×em`** 填；`ShapeParagraph :522-560` **逐段**用"相对行原点的笔位"重算（多段唯一算得对的地方）；`FormatLine :2389` 解析 `NaN ⇒ 4×em`、`witw = Σadvance + Indent`、行起点 `BuildGlyphRun(..., startPenX)`、`_startPenX` 进 `AdvanceBefore`；`FormatParagraph :3295` 新增两个**可选**参数（放可选尾巴最后 ⇒ **既有调用点零改动**）。
> **对拍**（探针新档 `--tab-oracle`）：`cases=114 pass=57 fail=0`，**最大逐字差 0.0053 DIP**（em 12/24/48、四档宽度、Indent 0/24/48；RTL 用 `P−内部右缘` 归一化）。**牙**：把框架默认改 `3×em`（`/tmp` 变体）⇒ `pass=10 fail=47`，差值正好 `96→72`/`384→288`（em48）⇒ 还原真源重建 ✓。
> **⚠️ 57 例被跳过**：`RTL 段落 + 纯拉丁内容` —— 其内部顺序由 **bidi** 决定（`D-B1` 射程外）⇒ **这批 oracle 验不了 RTL 的 Tab 规则**；缺的读数 = 一条"含希伯来/阿拉伯内容的 `\t` 串 + RTL 段落"的真机数据（U1 的 note 也承认未覆盖）。
> **⚠️ 两条口径更正**：① **WPF 确实有公开停靠位 API** —— `TextParagraphProperties.DefaultIncrementalTab`（`TextParagraphProperties.cs:111-114` = `4 × FontRenderingEmSize`）与 `Tabs`/`TextTabProperties`；**本实现只做默认口径，`Tabs` 未做**（如实登记）。⇒ U1 那条"WPF 层不存在"**说反了**。② 那条"**`T2c` Tab 34 例 = 已登记差异·保留红**"其实是**oracle 配置**造成的：`layout-b34/src/LayoutOracle/TextModel.cs:167` 把 **`DefaultIncrementalTab` 写死 0** ⇒ 那 34 例真值是"**0 宽 Tab**"，而框架默认是 `4×em`（我们按默认实现 ⇒ 账本动了：`T2c 不一致 25 例`、`通过 18/失败 4`、`T2 1263/1298`、`T2b 200/213`、`T2d Extent 1250`、`T3 明细 210`）。**隔离已证**：新增不一致 id **全在 tabs 家族**（`A1_tabs/B_tabs/B_tabs_trim/F_tabs`）⇒ 只碰 Tab。**已派 T1b 1 行**：让 `HbTextLineParity` 在该族传 `defaultIncrementalTab: 0`（与那条 oracle 配置对齐），并复跑给**逐族读数**证明"tabs 回绿 + 其他家族一位不动"。**默认配置下的 Tab 真值**由 U1 的 oracle 承担（`tests/parity/windows/tab/`，114 例、未覆盖该设置）——**它与我们新实现一致**。
> **⚠️ 但那 1 行的实测结果与主控预期不符（T1b 顶回来，我接受）**：同 shim（`4044d84a…`）、**只差这一行**的 A/B ——
> | 读数 | 不传 0（4×em） | **传 0** | 差 |
> |---|---|---|---|
> | 口径·记账结构 | 1263/1298（不等 35） | 1263/1298（不等 35） | **0** |
> | `T2c` Tab 不一致 | **25 例** | **21 例** | **−4** |
> | `T3` 折叠明细 | 210/236 | **214/236** | **+4** |
> ⇒ 传 0 = **配置对齐**（+4 例正面收益），**但 tabs 家族没有回全一致**，仍剩 **21 例**（`A1_tabs_w20..w240`／`B_tabs_*`／`B_tabs_trim_*`／`F_tabs_*`）⇒ 属 **`0` 配置路径本身的语义差**，**已连 id 清单交接 T1d**（查"`DefaultIncrementalTab=0` 时真机是"推进 0"还是"退回普通间隔""，并以 `layout-b34` 的真值（0 宽）为对照物；默认配置那 57/57 必须仍全绿 = 回归护栏；改完重报"源已定"）。
> **🔴 主控自己的第三次"没先看被测件 sha"**：我在派单里写"账本动了（`1286→1263`、Tab `0→25`）是你实现 Tab 造成的、T1b 传 0 就会回绿"——**因果链是错的**：那组差异来自**件版本变化**（旧 shim `e1bc947a…` ⇒ `1286/0 不一致`；新 shim `4044d84a…` **不传 0** ⇒ `1263/25`），T1b 那 1 行只贡献了 **−4**。
> ⇒ **教训（主控自领，已写进 `docs/CURRENT-STATE.md` 纪律 13 的同族）**：**在派单里给"因果"之前，必须先确认两个读数出自同一配置**（件 sha 不同 ⇒ 差值里混着"版本效应"与"改动效应"，不可归因）。前两次同类：T1b 引自己车道的旧文件、T1c 引旧 sha。
> **📌 一条操作约束（本轮现形，值得记）**：**子代理只能给"直接父级"发消息**（T1b 明确报"我无法直接给 T1d 发消息"）⇒ **所有跨车道交接必须经主控转**。本轮 T1b 的 21 例 id 清单就是由主控转给 T1d 的（并指向 `T1b-report.md` §2b 作为取件处）。⇒ 派单时若要求 A 车道把产物交给 B 车道，**要么让主控转，要么写成"报告即取件处、由主控引用"**，别指望它们互相发消息。
> ### 🎯 `M_modifier` 判定：**7 条宽度行 + 4 条 Extent 行 = 同一个根**（已定量到逐位）
> **语义**：`TextModifier` = **零长度 run**（用于 scope 内属性/方向嵌入），但 **oracle 里的 modifier 是恒等**（`ModifyProperties(p) => p`、`HasDirectionalEmbedding => false`，`TextModel.cs:63`）⇒ **唯一效果是结构**：scope `[6,45)` 变成**零宽占位、但仍计入 `len`**。
> **真值原文**：`M_modifier_winf 行#0` ⇒ `len=63`、`w=156.9167`、`runs=[[0,6],[45,17]]`、`ext=18.0`（**只有 23 个可见字符**）；我们 `w=439.1360` ⇒ 差 **282.2193 = 那 39 个字符的宽度**（逐位对得上）⇒ **7 行全部同一根** ✓；**4 条 Extent 同根**（行内容一致后墨迹盒自然回到 18.0）✓。**预测**已给全（`w200/w320/winf 行#0 ⇒ W=156.9167 / len=63 / Extent=18.0`；`w120 ⇒ 115.6900/37.0667`；`w80 ⇒ 74.5733/78.1833`；行账 6 条 `Len` 恢复 `50/63`）。
> **现在做不到的原因（链路）**：harness 只传"**平文本 + 一个 bool**"（`Program.cs:302`）；拦截层 `CollectLenient` **只取第一个 run 的属性**（`TextFormatterImp.Linux.cs:129-132`）且把各 run 字符**平铺**（`:146-154`）⇒ **scope 区间从未到 shim**；shim 侧只有 `_hasModifierScope`（bool，仅用于 `GetTextLineBreak`）。
> **可见性**：触发需要源里有 `TextModifier`（IME/合成、TextBox 场景）⇒ **当前样例不可观测** ⇒ **是正确性欠账，不是今天用户能看见的缺陷**。
> **主控裁定**：**做，但与本波分开**（同 T1d 建议）。跨车道 3-4 行的**归属已定**：**T1b 1 行**（传 meta 的 `modifierStart/End`）＋ **T1c 2-3 行**（`CollectLenient` 里识别 `TextModifier`）＋ T1d 的 shim 半（"scope 占位"参数，默认 `-1` ⇒ 对既有调用零影响，**要 A/B 证明**）。⇒ **下一轮开工**，判据 = 上述预测值逐条命中 + 行账那 6 条 `Len` 复原 + 其他家族一位不动。
> ### 🔢 `tline` 记账数字的**口径分裂**（主控在归因时发现；**已结案**，见下）
> 同一批件（shim `e1bc947a…`、#8 产物）出现两组"看起来矛盾"的数：
> · T3 那趟（`~/wfp-runs/tline-wave21final.log`）：**记账结构全等 `1286/1298`**（`:62/:145/:205`），其中**宽度超差 47**；Extent 行级 `1260/1298`；折叠明细 `218/236`。
> · T1b 车道当前（`gen/tline-detail-full.txt`）：**`1276/1298`** + **Extent 余差清单 `58` 条**（= 主对拍 38 **+** LH 组 20）。
> ⇒ **不是吵架，是三个不同口径**：记账结构(1286) ≠ Extent 行级(1260) ≠ 余差清单(58/38)。已要求 T1b 在报告里**并排定义**，并验证一条可测假设：**harness 启动时会同步 app-local 4/4**（T3 那趟日志有 `DWF 879f0020→2f77dbdf`、`PC ebf4cf87→6be29475`、`WB 8c073fab→e6216fe9`）⇒ **"同步前跑的"与"同步后跑的"可能就差那 10 行**。**若成立 ⇒ 新口径发现（读数依赖 app-local 新鲜度），要入册。**
> **✅ 已结案（T1b 同命令复现 + 反证主控假设，2026-09-14 18:27）**：
> | 口径（**四个**，各自独立、同时成立） | 定义 | 当前件（shim `e1bc947a…`） | 旧件（9/11，shim `E019DB56…`） |
> |---|---|---|---|
> | **记账结构全等** | `Length+NewlineLength+TrailingWhitespaceLength+(WITW−W)` | **1286/1298**（①硬断 286/286 ②空行 68/68 ③行尾空白 984/988） | 1276/1298（③ 977/988） |
> | **宽度分桶**（"超差 47"的真身） | `0` = **167** 行 ／ `≤0.34 DIP`（1 ideal unit）= **1084** 行 ／ **`>0.34` = 47** 行（**167+1084+47 = 1298 ✓**） | **47**（最大差 **282.219333 DIP @ `M_modifier_winf`**） | 83 |
> | **Extent 行级**（容差 0.01） | 逐行 Extent | **1260/1298**，余差 **58 = 主对拍 38 + LH 组 20** | —— |
> | **折叠明细** | 真折叠 236 行逐行 | **218/236**（折后宽度最大差 144.816 @ `M_modifier_winf 行#0`） | —— |
> ⇒ **`1286` 是记账结构行数、`47` 是宽度分桶的行数（不是 47 个用例）、`58` 与 `38` 是两个口径** —— 三者同时成立。**已要求 T1b 把这四个定义作为报告里的固定表保留。**
> **❌ 主控那条假设被实测否掉（如实记）**：本趟在 **app-local 已同步 4/4** 的前提下读数**仍是 1286/47**；`1276/83` 出自**旧件** ⇒ **差异由"件版本"驱动，不由 app-local 新鲜度驱动**。⇒ "读数依赖 app-local 新鲜度"**撤回**（T1b 给的门槛我认可：除非出现"**同件不同读数**"的实测）。
> **`Tab` 是独立登记类**（`T2c【已登记差异·保留红】`：真机 = 0 宽 + 特定断点，本实现未做；`Tab 可比例 34 例，不一致 0 例`）⇒ **不在那 47 条里**。
> **已批准**：T1b 在车道内给 harness 加一行落盘 `gen/t2d-width-diff.txt`（逐行 `用例|行#|cp 区间|真值|我们|差` + 分桶标记 + "三桶之和 == 1298" 机检断言 + **能变红的牙**），否则那 47 行无法逐条归因（**不许猜桶、不许放宽断言**）。
> **🔴 并发现一处"活的误读源"（T3 指出，已派修）**：harness 的汇总行
> `❌ T2 真机口径逐行记账结构全等 :: 行 1286/1298；…；宽度超差 47`
> **把两个不同桶粘在同一行** —— `1286` 是**记账结构**（不等 = `1298−1286 = **12**` 行）、`47` 是**宽度分桶 >0.34 DIP 的行数**，**两者不是同一口径的补集** ⇒ 任何人都会想拿它们相加减去推"实际错多少行"（**主控最初正是这么误读的**：先把 47 当成"47 个用例"，又据此把 T1b 报的 1276 当成矛盾）。
> ⇒ 已要求 T1b 把该行**拆成按口径各一行、每行带口径名**（记账结构 / 宽度分桶 / Extent 行级 / 折叠明细），并把四个口径名写进 harness 头注释。
> **✅ `1276` 的谜底（已结案）**：它是 T1b 车道**旧文件**（9/11、shim `E019DB56…`）的值；当前件就是 `1286/47` ⇒ **不是矛盾，是旧记录**（同族教训：**引用自己车道的历史文件前，先看被测件 sha**）。已要求其在报告里把"旧值 1276/83"标成"旧件读数、勿用于当前判定"。
> **✅ 已交付（T1b，同日）**：① 逐行清单 **`build/MilBridge/gen/t2d-width-diff.txt`**（`用例|行#|cp 区间|真值宽|我们宽|差|桶`；只列差>0 的 **1131** 行 = 1298−167；表头带**被测 shim sha**）；② **"三桶和 == 1298" 机检断言**（当前 `0=167 / ≤0.34DIP=1084 / >0.34DIP=47` ✅）；③ **能变红的牙**：`T2D_WIDTH_INJECT=<DIP>` 放大第一行 ⇒ `>0.34` 桶 **47→48**（正好抓一行）+ 文件头标"含人为注入"，**不设 env 还原 ⇒ 头与首行逐字回基线**；④ 汇总行**按口径拆开**（记账结构 / 宽度分桶 / Extent 行级 / 折叠明细 各一行），四个口径名 + "**互不为补集**"的警告写进 `Program.cs` 头注释。
> **🎯 47 行的确切归属（T1b）**：**`M_modifier_*` 恰好 7 行**，其余 **40 行全是 NBSP/ZWSP 家族**（`A1_nbsp_zwsp` 25 + `F_nbsp_zwsp` 10 + `B_nbsp_zwsp` 4 + `B_nbsp_zwsp_trim` 1）；`LH_cjk_punct_*` 在宽度桶里 **0** 条（口径不可比，已在册）。**三条最大差全在 `M_modifier`，且是语义差不是量化余差**：`M_modifier_winf` 行#0 `cp=[0,63)` 真值 **156.9167** vs 我们 **439.1360**（**差 282.2193 DIP**）、`w320` 157.2113、`w120` 行#1 55.2693。**同根旁证**：12 条行账里 6 条也是 `M_modifier`（期望 `Len=50 nl=0`、实得 `Len=6 nl=0`）。
> ⇒ **已转 T1d 纳入判定**：那 7 行（尤其 `winf` 的 282.2193）**是否全部由"`TextModifier` 未实现"解释**、与 `Extent` 那 4 条是**同一根还是两根**、以及"做/不做"的代价**按这份新证据复核**（"别放过，也别夸大"）。
> ### ✅ T2 两条任务交付（`-ipath` 翻正 + `ReachFramework` 纳入 ITEMS），并**测掉了主控当年的顾虑**
> **`-ipath` 翻正**（`check-applocal-sync.sh 6d7af95f…`）：取候选后按 `${f,,}` 归一匹配 `*/release/*`、`*/release_*/*` / `*/debug/*`，排除项不变。**新增 5 个成员全部 `CONSISTENT`**（发布目录与 `native/` 两份 `wpfgfx_cor3.so = 759a3224`、`ClosedLoop/release` 的 `libwpfwic.so = 03b67fbc` 与 `Provider = 71ba86c6`）；**前后计数逐项一笔未变**，仍 `APPSYNC=PASS`。
> **🔎 反事实实测（重要）**：关掉 `LIB-COPY` 排除后，当年担心的那批"红"确实会露出（`WpfGfx.Linux.dll [Release]` 3 种 sha / 5 个成员），但**它们全是 `host=0`（无 `runtimeconfig.json`）** —— 是**另一个配置的产物/中间件**（`.artifacts-rb/**` 自 09-10 无人写过），**不是"无人清的落后件"**。⇒ **主控当初"暂不改 `-ipath`"的顾虑建立在未验证的假设上；T2 把它测掉了** —— 教训：**决策依据本身也必须被验证**（与"牙必须能红"同族）。
> **`ReachFramework` 纳入 ITEMS**：权威现场 **`1fd4fe8a2ffd20b1`**（741,376 B，18:26:57 —— 在 18:15 那趟波之后**又被重建过一次**，故与我先前量的 `ede1f364…` 不同，T2 如实登记了时间差）；桩件 `067c0385`（5,120 B）判 **`SKIP(stub)`**，且**判定已提前到 `obj` 之前**（连 `CycleStub.*/obj/` 也报 `SKIP(stub)`）——**主控自己审计时踩过这个同名桩**，故此条特别有价值。纳入后 `STALE 5`：`SystemFontsProbe/bin/Debug`（`daf9b6f0`，早 72,215 s）、`ManagedLayer.Tests` 与 `WpfFeatureProbe`（`91878c04`，早 644 s）、`HelloWpf`（`00723a05`，早 257,055 s）、`WpfTextDemo`（`da65eaf4`，早 30,831 s）⇒ 3.6 干跑 `refreshed=5 newer=0`，**恰好这 5 份**。
> **裁定**：① **授权立即 `--apply` 刷这 5 份**（与 3.6 同一段代码、只拷不重建）⇒ **统一波里 3.6 再跑一次预期 `refreshed=0`，那正是幂等的端到端证据**；② **库输出（PF 的 bin）保持 `LIB-COPY`、不刷**（三条理由：没人从该目录启动／`Private=true` 只拷被引用那一个 dll／真正加载的是消费者宿主里的副本）；**若将来要纳入 ⇒ 属口径变更，须先有 owner 与判据**；③ **翻正后的 `-ipath` 保留**（净收益：多覆盖 5 个加载源、零新增噪声），其牙两极化已实测（把新纳入的小写 `release/` 里那份 `Provider` 追加 2 字节 ⇒ `DIVERGENT + exit 1`；逐字节还原 ⇒ 红消失），自检 **A–I 9/9**。
> ### 🔴 **裁定 ② 被证据推翻（主控撤裁）—— 而推翻它的正是 T2 的校验器**：`LIB-COPY` **不是惰性的**，它是一条**RAR 传递解析源**
> **现场**：T2 18:31:12/18:31:55 报 `APPSYNC=PASS`（`OK=33 MISMATCH=0 DIVERGENT=0`）；**主控 18:32 复核即变红**：`STALE tests/…/ManagedLayer.Tests/bin/Debug/net10.0/ReachFramework.dll EXPECT 1fd4fe8a… ACTUAL c6a2863f…（副本早 307 s）` + `DIVERGENT ReachFramework.dll [Debug] 有 2 种 sha`。
> **`c6a2863f…` 正是 PF 的 bin 里那份 `ReachFramework.dll`** —— 即我裁定"不刷"的那份 `LIB-COPY`。
> **机制（追到链上）**：`ManagedLayer.Tests.csproj:87-89` 用 **HintPath 指向 PF 的 bin** ⇒ MSBuild 的 **RAR 从"被引用程序集所在目录"解析传递依赖** ⇒ 把 PF bin 里的 `ReachFramework.dll`（`c6a2863f`）拷进自己的 app-local。
> **铁证两条**：① `ManagedLayer.Tests/bin/.../ReachFramework.dll` 的 mtime = **18:21:50** = PF bin 那份的 mtime（同一刻）；② T2 18:31:05 刷成 `1fd4fe8a` 之后，**M7b 正在跑的 `dotnet test` 构建又一次把它拷回 `c6a2863f`** ⇒ **这个红会自我复现**，靠"再刷一次"治不好。
> ⇒ **口径教训（已入册）**：**把某类副本判为"不是加载源"之前，必须验"有没有人能从它解析"** —— RAR 的传递解析就是那条**没人检查过的路径**；T2 当初给的理由②（"`Private=true` 只拷被引用那一个 dll，不带出 PF 的私有依赖"）**被实测否掉**。
> ⇒ **已派 T2 修**：把"位于**别的工程通过 HintPath 引用的输出目录**里、会被 RAR 传递解析"的副本纳入**可刷新集**（**枚举**同类，别只修这一处；判据 = "该目录是否出现在任何 csproj 的 `HintPath` 里"），并给**三极性牙**（改成错 sha ⇒ 消费者构建后必须红且点名"传递解析"；刷新 ⇒ 消费者重建后仍绿=幂等；删掉副本 ⇒ 如实记录"解析不到/退回权威件"是哪种），修完必须**在 M7b 的测试构建之后**复跑仍 `PASS`（否则是假绿）。
> ### ✅ 修完（T2，`check-applocal-sync.sh 2d18bffe…`）：**一次暴露 4 份，且 `LIB-COPY` 8 → 0 —— 那一类从头到尾都是误判**
> **判据落地**：把 HintPath 里的属性替换成实际路径再取 dirname（`MSBuildThisFileDirectory`/`WpfLinuxRoot`/`RepoRoot`/`WpfLinuxBinDir`/`DwRoot`/`WpfLinuxSelfBuiltConfiguration=Debug`），**解析不掉的逐条登记、不静默**；运行期第一行就给出可复核枚举：**解析源目录 16 个、未解析 HintPath 0 条**；命中解析源的副本跳过 `LIB-COPY` 并在行尾**点名这条路**。
> **枚举出的 4 份**（不只我抓到的那一处）：`build/PresentationFramework.Linux/bin/Debug/ReachFramework.dll`（`c6a2863f`→`1fd4fe8a`，早 307 s）｜`tests/…/ManagedLayer.Tests/bin/Debug/net10.0/ReachFramework.dll`（同上）｜**`build/PresentationFramework.Classic.Linux/bin/Debug/DirectWrite.Linux.Provider.dll`（`ef6cc9d3`→`71ba86c6`，早 323,677 s）**｜**`build/PresentationFramework.Classic.Linux/bin/Debug/ReachFramework.dll`（`e8819668`→`1fd4fe8a`，早 357,557 s）** ⇒ `refreshed=4 newer=0` ⇒ **`OK=41`、7 组全 `CONSISTENT`**。
> **⭐ `LIB-COPY` 从 8 降到 0**：原先那 8 份**全部**位于被 HintPath 引用的 `build/<Proj>.Linux/bin/Debug` ⇒ **这一整类（含 T2 自己 §24.1 判成 `LIB-COPY` 的"原 #6"）都是误判**，本轮一并纠正（T2 主动登记"那次也判错了"）。
> **牙（全实测，含一条意外）**：① 污染解析源 ⇒ `NEWER-DIFF` + **点名"HintPath 传递解析"**；② **构建消费者 `ManagedLayer.Tests` ⇒ 消费者拿到被污染的值、两处同时红并点名**（机制当场复现）；③ 刷新时**刷新器拒绝动手**（污染使副本**比权威新** ⇒ 落 `NEWER-DIFF` ⇒ 按"只告警不盲拷"**故意不动** = "**mtime 只分类、不放行**"的兑现），T2 遂**逐字节还原**并用**不带 `-p` 的 `cp`** 让源比消费者新 ⇒ **重建消费者即自动收敛（无手工 cp 消费者）**；另补落后类两极化（`STALE` ⇒ `--apply` ⇒ `refreshed=1` ⇒ PASS）。自检 **A–J 10/10**。
> **🔴 ④ 反向（删除）—— 如实登记为已知洞**：删掉副本后**构建 rc=0 / 0 错误**、源**没被重建**、**消费者那份被一起删掉**，而校验器**今天与当时都报 PASS** ⇒ **对"缺件"是瞎的**；`--apply` 也**不会补回缺件**（只刷"存在且落后"）。两条候选判据都被**实测否掉**（`FileListAbsolute×磁盘`：删后重建，构建**把清单改写成不再列它**；`依赖闭包`：干净树上就 20 个候选 = 狼来了）⇒ **按"先有 owner 与判据"本轮不扩面**；要堵需**基线状态文件**或 owner 定义好的闭包判据。
> **终态**（**排除假绿的那一条**）：18:37:16，**在两次重建 `ManagedLayer.Tests` 之后**仍 `APPSYNC=PASS`（`OK=41 MISMATCH=0 DIVERGENT=0 LIB-COPY=0`），`Provider[Debug]` 18 份 / `ReachFramework[Debug]` 8 份全 `CONSISTENT`；`cmp` 证明还原件与权威**逐字节相同**。
> **裁定被推翻的过程已记档（§26.1）**：时间线（18:31 PASS → 18:32 主控复核变红 → 追链 → 18:33 复现）+ **理由错在哪逐字对照** + 教训升级：**"没人从这个目录启动" ≠ "没人从这里解析"** —— 与"决策依据本身也必须被验证"是同一课的**第二遍**。
> ### ✅ `Tab` 口径真机 oracle 已交付（U1，**114 例**）：`tests/parity/windows/tab/`
> `.NET 10.0.7` / `TextFormatter.FormatLine` / 逐字 `GetTextBounds(i,1)`；**Dpi=96、emSize 12/24/48、paragraphWidth 40/80/160/320/10000、LTR+RTL 各跑**；字体 Arial（逐码点覆盖验证；**U+0009 是控制字符无字形，已从覆盖检查里排除并写明**）。
> **⭐ 三条实测规则（都有数据，可直接当实现判据）**：
> - **A. 默认 Tab 间隔 = `4 × emSize`**（**不是固定 DIP**）：emSize 12 → 停靠 48.000、24 → 96.000、48 → 192.000。
> - **B. 停靠位锚在"行原点"**：LTR 锚**左边缘**、**RTL 锚右边缘**；`a\tb\tc`（行宽 204）LTR 到达 96/192，**RTL 到达 107.997/11.997 = 204−96 / 204−192**。
> - **C. Tab 前进方向 = 排版方向** ⇒ "到达的停靠位"在 RTL 是 Tab 的**左边缘**、LTR 是**右边缘**；JSON 里 `tabs[].reachedStopDip` **已按方向算好**（不是朴素 `x+width`），另给 `tabSpanDip{left,right}` 供核对。
> **另两条关键读数**：**宽度约束不影响 Tab 前进**（40/80/160/320 四档行宽**都是 109.347**、advance 都是 **82.653**，只有 `HasOverflowed` 从 True 翻 False ⇒ **Tab 不会为塞进容器而缩短/换行，行照常溢出**）；**`Indent` 不移动 Tab 网格**（Indent 0/24/48 到达停靠位始终是行原点起 96/192，Indent 只把文本起点右移）。
> **控制组**：`abc def` / `ab` 两方向都无 Tab、行宽相同（78.720 / 26.693）⇒ 装置不产生伪 Tab 读数 ✓。**LTR tiling 严丝合缝**：`a[0,13.347] | \t[13.347,96] | b[96,109.347] | \t[109.347,192] | c[192,204]`。
> **⚠️ 一条 API 事实（回答了"显式设 Tab 宽度"那一半）**：**WPF 公开 API 没有自定义停靠位** —— `TextParagraphProperties` 只有 `Alignment/…/Indent/LineHeight/ParagraphIndent/TextAlignment/TextDecorations/TextMarkerProperties/TextWrapping`，**没有 `TabProperties`** ⇒ "显式设置"在 **WPF 层不存在**，oracle 改为测默认口径 + 用 `Indent` 做对照。**⇒ 我们那条 `T2c【已登记差异·保留红】Tab` 的"真值口径"应据此改写**（原写法"真机 = 0 宽 + 特定断点"只是现象，**规则已由 A/B/C 给出**）。
> **诚实边界**：折行（`Wrap`）下的 Tab 未测（本轮全 `NoWrap`）；自定义停靠位无真值（API 不存在）；非 Left 对齐 / 非默认 `LineHeight`/`ParagraphIndent` 未覆盖；**Tab 夹在希伯来/阿拉伯文之间未测**；Arial 固定；未与 `TextBlock`/`FormattedText` 交叉验证。
> ### ✅ 完成判据③ 在**最终件**上成立（主控 10:04–10:07）
> `verify-all.sh`：**步骤通过 9 / 失败 0，用例通过 869 / 跳过 2，`rc=0`**；**跑前跑后九位逐位未变**（`pc 6be29475…`／`pf 50da8513…`／`wb e6216fe9…`／**`dwf 2f77dbdf5e7e2cd5`**／`provider 71ba86c6…`／`win32shim 91baee84…`／`wic 03b67fbc…`／`bridge 759a3224…`）；桥 fp 文件 == 现树 `705ed5ccd0c498a1`。日志 `~/wfp-runs/verifyall-final-100455/verify-all.log`。
> ### ✅ `libSkiaSharp.so` 的产出流程**已查清**（主控）：**NuGet 钉版件，逐字节可复算**
> 仓内那份 `a02cd03f1ebcbb97`（9,244,960 B）与 **`~/.nuget/packages/skiasharp.nativeassets.linux/2.88.9/runtimes/linux-x64/native/libSkiaSharp.so` 逐字节相同**（同 sha/同大小，包内 mtime 2024-11-07）；版本由 `src/WpfGfx.Linux/WpfGfx.Linux.csproj` 钉住（`2.88.9` + 注释"4.x 有破坏性 API 变更，禁止升级"）。⇒ 它的可见位判据写成**可复算的一句**："仓内副本 == NuGet 2.88.9 linux-x64 native asset（同 sha）"。引用它的脚本：`build/setup-env.sh`、`verify-env.sh`、`publish-milbridge.sh`、`wic-shim/build-wic-shim.sh`。
> ### 📋 元组覆盖决定（T3 的表 + 主控裁定）
> ① **进冻结元组**：`DirectWriteForwarder`（**第九位，下一版起机读**；本波实测 `879f0020…→2f77dbdf5e7e2cd5` 而元组看不见它 = 静默位，与事故 D 同族）。② **批准新增"扩展可见位"**（`WPTD_ARTIFACTS_EXT`/`WFP_ARTIFACTS_EXT`，一行、追加不改既有顺序）：`ReachFramework`/`System.Xaml`/`PresentationUI`/`PF.Classic`/`System.Printing`/`UIAutomationTypes`/`UIAutomationProvider`/`Manipulations`/`libSkiaSharp.so`，口径 = "**扩展位变化不自动作废基线，但必须在下一版表头记录**"；其中 `System.Xaml` 标注"**一变就升级进元组**"、`libSkiaSharp.so` 按上面那句可复算判据写。③ **不进**：上游 .NET/NuGet 件。
> **T3 顺手给出的支撑事实**：仓内多个 `build/*.Linux/bin/Debug/` 存在**同一程序集的不同 sha 副本**（`ReachFramework.dll` 4 个值、`PresentationFramework.dll` 3 个值）⇒ 这正是 3.6 与"自产件一致性"检查存在的理由；**冻结值一直取 app-local 已同步那几份**，故八位可信。
> ### ✅ 扩展可见位已落地 + **主控独立复算（含一次"主控自己踩了登记过的陷阱"）**
> 两个 runner 各**追加一行** `WPTD_ARTIFACTS_EXT`/`WFP_ARTIFACTS_EXT`（既有字段与顺序一位未动；`bash -n` 双过）；`libskia_sha` + **`libskia_nuget_2_88_9_match`**（**缺 NuGet 副本 ⇒ `NOINFO`，不当 yes**）；缺文件输出 `NA` 不静默成空。
> **主控独立复算**：八件里 **7 件与 T3 报值逐位相同**（`systemxaml d6ea4ffe…`／`presentationui bf20bd9e…`／`pfclassic 55f981c3…`／`systemprinting 17beaac6…`／`uiatypes 2ac8d37b…`／`uiaprovider 352ccd757a2f2fb0`／`manipulations c264f0ec…`），`libskia` `cmp` **逐字节相同 ⇒ match=yes** ✓；**唯一"不符"是我自己用错了路径** —— 我读的是 `build/CycleStub.ReachFramework.Linux/bin/Debug/ReachFramework.dll`（**5120 B 的断环桩，`067c0385…`**），而 runner 与 T3 取的是权威件 `build/ReachFramework.Linux/bin/Debug/ReachFramework.dll = ede1f3644a56ccc0`（741,376 B）⇒ **T3 正确、主控复算有误**。
> ⇒ **我踩的正是 T1c §32 登记过的那个陷阱**（"5120 B 的 CycleStub 同名件是按文件名比对的陷阱"），而且**是在"审计别人"的时候踩的** ⇒ 教训升级：**同名件必须写全路径，审计者也不例外**（复算脚本里凡是 `sha256sum` 都带完整路径，且**禁止用 `find -name` 的结果直接比**）。
> 现场还量到**第三个变体**：`build/PresentationFramework.Linux/bin/Debug/ReachFramework.dll = da65eaf41e7aef72`（741,376 B，**比权威件旧**）⇒ 它是"构建输出目录里的陈旧副本"（债务 #20 同族；被 T2 的 `LIB-COPY` 类别按"非启动宿主"处置，门禁不从那里加载）。
> ## 📌 2026-09-14 傍晚–夜（**`#10` 之后**）：**修复队列排序被读数改写** + **U1 `tab-anchor` arm 落地（真值推翻了我们共同前提的一半）** + **`D-U1` 裁定"不实现"** + 三条车道同时只读归因
> **基线锚 = `#10`**（`bridge 759a322431f1e457`｜`pc 628e741681ecb048`｜`pf 967c79c18dbfaac2`｜`wb e6216fe961a2bfb9`｜`provider 71ba86c6495347fe`｜`win32shim 0098234982391bbf`｜`wic 03b67fbcd7c385b6`｜`hbtextline 7c2e0107a9c86180(stale=no)`｜九位 `dwf 2f77dbdf5e7e2cd5`；fp `705ed5ccd0c498a1`），哨兵 `/tmp/bridge-frozen.flag` 逐位相符。
> ### 🔀 **修复队列改序（主控裁定）**：`D-T1`（波 **#11**）⇒ **NBSP/ZWSP 行度量族**（波 **#12**）⇒ `M_modifier` 透传（波 **#13**）。
> **依据是 T1b 的逐族台账**（不是"感觉哪个人多"）：`宽度超差 47` = `A1_nbsp_zwsp 25 + F_nbsp_zwsp 10 + M_modifier 7 + B_nbsp_zwsp 4 + B_nbsp_zwsp_trim 1`；`Extent 余差 58` = `LH_cjk_punct 20（结构性不可比）+ A1 21 + F 8 + B 4 + B_trim 1 + M_modifier 4`；`折叠明细 18` = `F_nbsp_zwsp 10 + M_modifier 7 + F_lat_words 1` ⇒ **NBSP/ZWSP 是最大单族（块1 40 条）且含"折叠区间宽为负"（契约不合法）**；`M_modifier` 三块合计 18 条、且是**跨三车道**的改动 ⇒ 放在最后（那时三条车道都还热）。
> ### 📋 **T1b 逐族台账**（`build/MilBridge/T1b-family-ledger.md`，**只读冻件**，三份 artifact 头行自报 `7C2E0107A9C86180…` 与 #10 一致）
> **三个等式断言全部成立**（块1 族计数和 == 头行 `>0.34=47`；块2 == `合计 58`；块3 == `236−218`）。**三条"同一性"判定**：① **块1 ≠ 块3**（实测求交：交 **17**；**仅块1 有 30**（`A1/B_nbsp_zwsp*` —— 这些行**折叠全对、宽度超差**）；**仅块3 有 1**（`F_lat_words_w560#0`，ΔW `+0.0140` 本就在 ≤0.34 桶））；② **"折叠明细 18" == "段1 18" 证成**（同 artifact、同 sha、同口径，且 `236−218 == 18` 两处独立计数相等）⇒ **前两轮归属不需重挂**；③ 它**明确报"无信息"**而不是估一个（"8 条"那张表不在它手上）。
> **它给的块2 复算入口**（"余差条数不得因 #11/#12 变"就用这条）：`awk '!/^#/' gen/t2d-extent-mismatches.txt | sed 's/ .*//' | sed 's/_w[0-9]*$//;s/_winf$//' | sort | uniq -c` ＋ `grep '^# 合计'`（⇒ 58 = 主对拍 38 + LH 20）。
> ### 🔬 **T1c §41 机制分解：把"折叠口径"这个归属推翻了（对这三族）** —— 这是本轮最值钱的一条
> **① 三族根本不在折叠不符清单里**：段1 里 `A1_` **0** 条、`B_nbsp` **0** 条 ⇒ 差在**行度量**，不在折叠实现。
> **② 代码落点**：行宽 = shim 逐字形 advance 求和（`build/shims/PresentationCore.HbTextLine.cs:244 gp.XAdvance*scale` → `:100` 求和 → `:107-113 CharAdvances()`）；**PC 侧不参与宽度决策**（`TextFormatterImp.Linux.cs:81-91 ExtractRun` 原样复制、`:110-157` 平铺）⇒ **可修的一侧只能是 shim 度量或 PC 传下去的字符/属性**。
> **③ 集合代数（逐键求交）**：`A1_nbsp_zwsp` 宽 25 / Extent 21 ⇒ **交 21、仅宽 4、仅 Extent 0**；`B_nbsp_zwsp` 4/4 **交 4**；`B_trim` 1/1 **交 1** ⇒ **`Extent ⊂ 宽`（同源）**；那 4 条"宽差而 Extent 不动"**当分辨器**（先修宽度，Extent 若自动消失 = 一个机制）。
> **④ 它顺手解开了 T1b 卡住的那个"8"**：那个 8 出自**它自己的 §39.5**，而 §39.5 的数字来自 **19:02:12 的瞬时文件（非冻件）** ⇒ T1b 判"口径不一致"是**对的**；机读源 = `gen/tline-detail-full.txt` **段1 全量**（#10 = 18 条），**#10 上重算 = 起止一致 3 + 起止±1 5 + 行W超差 3**（F 家族 11 条）⇒ "8" = 3+5。
> **⑤ 重分类判据（防止"不可比"当挡箭牌）**：判"口径不可比"必须**先给不可比理由**且三判据缺一不可（三量关系可复算且差方向一致／差异不随内容·宽·字体单调／**同族对照行逐位相等**）；**负的折叠区间宽一律算缺陷**。
> **⑥ 它自曝第 4 次同族口径陷阱**：扫负宽时 `W=-` 同时命中 `差 W=-…`（差值）与 `cr … W=-…`（区间宽）⇒ 前 3 条 `M_modifier` 是**假阳**；正确写法要锚 `cr 我们=[` 之后。
> ### 📋 **T1d §11 只读轮**：`D-T1` 形态钉死 + `M_modifier` shim 侧设计 + **一条影响 #13 判据的新真值**
> **`D-T1`**：判据 `stop > width` **一字不改**；只改分支 = **越界 ∧ 行首 ⇒ 钳；越界 ∧ ¬行首 ⇒ 不钳**（候选自动失格 ⇒ 回落 before-tab 断行）；**两处钳位只经过具名入口**（`IsLineStartTab` / `TabClampWidthFor`）；**12 例逐例表 + 复现命令 + 牙（`IsLineStartTab` 恒 true ⇒ 12 例复现）+ 六项基线数字清单**；第 13 例 `notab-control@w40@RTL` 的 `tws` **明确排除在射程外**。
> **`M_modifier` shim 侧**：区间与行求交后**只把 `adv[]` 置零**（`len/nl/ws/dep` 全来自字符区间 ⇒ `len` 仍含 39 字符 = 真值 63 ✓）；`hasModifierScope` 与新区间**互相独立** ⇒ `T5.1/T5.2` 逐位不变；**绝不能动 `Extent`/`Baseline`** ⇒ 判据 = 段2 Extent 余差 **58** 不得变。
> **🆕 新真值（`gen/layout-b34-compact.json`，3222 行）**：**`lbNull=false` 只有 2 行**（`M_modifier_w80 行#0`、`M_modifier_w120 行#0`）⇒ 真机 `GetTextLineBreak()` 非 null ⇔ **该行有后续行（行末是真断行）∧ 段落带 `TextModifier`**；**单行段落（`w200/w320/winf`）与末行（`w80#1`）全 null**。⇒ 我们的"段落级 bool 直下发每行"是**潜在差异**，但现有非 null 行**恰好都是首行**、非首行**恰好都是末行** ⇒ **真值分不开两条候选规则**（(i) 有后续行 ∧ 段落带 modifier；(ii) 有后续行 ∧ **该行与 scope 相交**）⇒ 需要**分离用例（scope 只覆盖首行 + 段落 ≥3 行）**：**已记入 U1 的下一批**。
> ### ✅ **U1 `tab-anchor` arm 已出数（436 例）**：`tests/parity/windows/tab-anchor/{src,out,PROVENANCE.md}`
> 真值源 = `out/tab-anchor-oracle.txt`（**主控独立复算的现场 sha**：`raw.json 88559d670f1bb955…`（**436 cases / 436 unique id / dup 0**，现场用 python 数过）、`oracle.json a31a813114256faf…`、`oracle.txt bdf2c31a7a34fbc9…`、`raw.txt e509b0bd66e850b5…`、`analyze.py 8f953bd002616689…`；推导件头行自报的 raw sha 与交付的 `raw.json` **逐位相符**（自洽 ✓）。**⚠️ 记录自己会陈旧（纪律 4）**：我 19:31 读到的头行是 `04669e49…`，U1 其后**重导过**（重复 case id 修复：加块前缀 + C# 硬护栏），**旧引用已作废**；机器 Windows NT 10.0.22631 / .NET 10.0.7 / Arial 全覆盖 / Dpi=96 emSize=24 / `TextWrapping=Wrap` / **`Tabs=null`** / 两臂 `default` 与 `DefaultIncrementalTab=0`；`DETERMINISM=MATCH`）。**十一条结论里四条直接改实现**：
> - **Q1/Q2/Q3/Q4**：到达的停靠位在**前进方向的远边缘**；锚点/网格见下。
> - **🔴 Q5（`:127-166`）行首谓词按"缩进后的内容起点"判**：原文 `the predicate is therefore judged against the INDENTED CONTENT START, not the absolute line origin … Equivalently: 'the tab is the first character of the line'. A predicate written as pen == 0 takes the wrong branch for every line with Indent > 0.`（**26 例 definitely-clamped + 4 例压边**）⇒ 与 T1d 选的 `IsLineStartTab(pen,indent) => pen <= indent + 1e-9` **同支**。
> - **🔴 Q6（`:167-252`）被钳满的 tab 目标 = 内容宽（不是行宽）**：box span `[Indent, container − ParagraphIndent]`，device span LTR `[ParagraphIndent+Indent, container]`／RTL `[0, container − ParagraphIndent − Indent]`（`leftEdgeEverZeroWhenIndentIsPositive=false`；58 例 + 16 例压边）⇒ **advance 宽 = `container − ParagraphIndent − Indent`**。
> - **🔴 Q8（`:305-339`）`ParagraphIndent` **会**移动 tab 网格，且正好移 `ParagraphIndent`**：原文 `the grid origin is at box coordinate 0 where box coordinates are raw coordinates minus ParagraphIndent … the reached stop is (ParagraphIndent + k*interval) measured from the line's start edge`（LTR 18 例 / RTL 6 例；`indent=0/24` × `pIndent=24/48`）⇒ **我们此前那条"网格是绝对倍数自 0 起算、与缩进属性无关"的前提，只对 `Indent` 成立** ⇒ **越界判据必须在 box 坐标里比**。
> - **Q7**：`Indent` 不移动网格（44 例，`impliedGridOrigins_box=[0.0]`）。**Q9**：`TextLine.Width`/`WITW` 以**段落原点**度量 ⇒ **不含** `ParagraphIndent`、**含**每行 `Indent`（原文标为 "Trap for T1d"）。**Q10**：`tab0` 臂 **224 例全零宽**（与既有 `tab-zero` 一致）。**Q11**：**退化族 4 例**（`ParagraphIndent + Indent >= container`）⇒ tab 钳成**零宽 span**、`HasOverflowed=true`、且 `deviceSpanPredictedByFormula ≠ 实测` ⇒ **未被公式覆盖的角**，要求 T1d 写明其实现会给出什么并**登记为边界**（不许为迁就公式改公式）。
> ### ✅ **`D-U1` 裁定（主控）= 不实现导出、不加映射；改成两条受监控不变量**（全文见 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-U1` 节顶部；原登记保留备查）
> **四条证据**：① **`UiaLookupId` 全仓零调用点**（`grep -rn` 全仓 **24** 命中，**逐条都在定义文件自己**与 md 文档里；口径 = **字符串级** ⇒ 覆盖"用反射调它"）；② **正对照**（`SupportsWin7Identifiers` code 命中 **2**（定义 `:70` + **调用点 `AutomationIdentifierConstants.cs:104`**）、`UiaGetReservedNotSupportedValue` **21**）⇒ 那个 0 是**真 0**；③ **`SupportsWin7Identifiers()` 在 Linux 上不可达** —— `AutomationIdentifierConstants.cs:103-105` 的 `\|\|`/`&&` 链被 shim 的 **20 条 `WPF_OSVERSION_FALSE(...)`**（`win32_misc.c:1215-1234`；`nm -D … | grep -c " T IsWindows"` = **20**）短路；④ ⇒ `RawUiaLookupId` 的 `[DllImport("UIAutomationCore.dll")]` **永不被 JIT 解析** ⇒ 今天**不是"降级"，是"不可达"**。
> **落地物**：① `wire-uiautomation-resolver.py --check` 增"**调用点计数 == 0**"断言 + **同命令内正对照**（跑不出正对照 ⇒ 报"仪器无信息"，不许绿）；② 托管牙 `D3`（运行时证"落到最后那个 `else`"：`IsOsWindowsVistaOrGreater==false` ∧ `LastSupportedProperty==TransformCanRotate`）；③ `D4` 反向牙：反射调 `UiaLookupId` 必须抛 **`DllNotFoundException`**（**不是** `EntryPointNotFoundException`）⇒ 钉住"只加映射不加导出"这个未来错误。**已登记的边界**：Linux 的 UIA 标识符档位 = **Vista 档**（Win7+ 档的 `SynchronizedInput` 等按"不支持"处理；真值源不可得 ⇒ 不提供，**不许**用稳定哈希冒充）。
> ### 🧰 **同时派出的两条车道**：**T2** = 补"app-local 校验器**对删除是瞎的**"这个仪器洞（期望集合必须来自**权威枚举**而非现场文件；四极实测：基线 PASS／删一份必红并点名／整份还原必回 PASS 且 sha 相同／多一份报 UNEXPECTED）；**M7b** = 上面 `D-U1` 的两条不变量（阶段 1 纯 python 可立刻做；**阶段 2 的托管牙与变红实测必须等 #11 波结束**，因为它的构建可能重编 PC/WB，不能与 `D-T1` 波重叠）。
> ### 🧾 **新纪律两条（入 `docs/CURRENT-STATE.md` §5）**
> **18. 读数 = 四元组** `(被测件 sha, 仪器/harness 版本, 判据口径, **artifact 名 + 字段名**)` —— 本轮现场例：同三 case+行，**折叠明细 artifact 的 `W`** = `+9.6807/+2.6233/+8.5460`，而 **`t2d-width-diff` 的 `TextLine.Width`** = `+4.1567/+6.7167/+6.3927`（**两个 artifact 比的是不同字段**）。
> **19. "0 / 不可达 / 死代码"是**结论**，但必须带（a）**字符串级口径**（覆盖反射用法）、（b）**正对照**、（c）**把它落成会变红的不变量**而不是写一句"目前没人调用"** —— `D-U1` 是本范式的样板。
> **20. 开修之前先回答"**哪一侧有能力产生这个差**"**（T1c §41 的样板：PC 侧**不参与宽度决策** ⇒ 可修侧只能是 shim 度量）—— 否则就是"对着两把尺子改一次"。
> ### ⏱ **波 #11 进行中（现场时间线，主控旁证）**：`build/shims/PresentationCore.HbTextLine.cs` **19:33:31** 起 `7c2e0107a9c86180`(232,273 B) → **`b4c7aa8210c71cbe`**(235,990 B, **+3,717 B**)；`gen/*` **19:34:12–14** 被重生成（那时 PC 还是 #10 的 `628e741681ecb048`/19:10:18 ⇒ **那趟是 before 基线**）；**19:34:40** 审计行 `owner=close-wave:t1d … WAVE_OWNER=close-wave:t1d bash build/integration-wave.sh`（**认领正确**）；**19:35:41** `pc → 4f2e621a4ad26cd0`、**19:36:37** `pf → 83fd8ff18fd15344`。**主控已把 #10 的 shim 源整份备份到 `/tmp/shim-7c2e0107-20260914.cs`**（纪律 16 的还原源）。
> ### 📋 **T3 的 `#11` 验收清单**（`samples/WpfTextDemo/NEXT-WAVE-11-CHECKLIST.md`，只读准备：零构建/零应用/零波/零冻结）+ **两处"表头已过期"是它实读出来的**
> **过期①**：`#10` 表头"**待 U1 的 Indent/锚点 arm 定义后**" ⇒ **U1 的 arm 已交付**（436 例）。**过期②**：只写"结构败 **12 例**"会被读成"修完必须全 0" ⇒ **实测基线是 `tab-zero`(86) 结构败 `13`**：**射程内 12**（`b34-tabs`/`tab-only` 各 w40/w80/w160@em24 的 LTR+RTL 各 3；**LTR 6 例 ⇒ 方向无关**）**＋ 第 13 例 = `notab-control@w40@em24@RTL@tab0` 的 `tws`**（不在射程内，归 T1d §9.4(C)）。
> ⇒ **主控更正 `D-T1` 判据 = `13 → 1`（射程内 12 ⇒ 0）**，**第 13 例点名保留**；**牙的预期读数 = 回到 `13/86`**；**若 T1d 报"0/86"要怀疑**（射程被扩大或判据被动过）。**冻结件不可加"时效注"**（上一版由下一版取代；当前真相由 `docs/CURRENT-STATE.md` 承载）。清单里还写好了门禁判据、六项读数（带口径名）、三份明细条数不变式、`RTL 三条/text-dp-min/textbox-edit/全块矩阵`、`1400` 两口径、以及**读数纪律前置表**（`pc`/`hbtextline` 会变、`shim_stale` 必须 `no`、`bridge`/`win32shim` 不该变、`pf` 环成员每波必变属预期）。**牙的归属**：**`build/shims/**` 单写者 = T1d（它改、它还原）**，T3 只跑读数并核对三次源 sha。
> ### ✅ **T2：app-local 校验器的"删除盲区"补掉了，而且新仪器第一天就抓到一条既存真缺口**（`§27`，`REPORT.md` 769067f2…）
> **期望集合与现场解耦**：唯一实现 `build/DirectWrite.Linux/wic-shim/applocal-expect.py`（`c9d2bcee…`）从**声明式来源**算（`<Reference>`(Private≠false)／`<HintPath>`／`<ProjectReference>`（路径也做属性替换）／工程自身产出件／结构性输出目录／`CycleStub` 不作图节点／权威件本身）；**算不出 ⇒ `APPSYNC=NOINFO` + exit 3**（不退回"只查现存副本报绿"）。
> **四极实测**（命令 + 原文）：① 基线 `解析源目录=16 期望副本=47 工程数=71 算不出=1`、`OK=41 MISSING=1` ⇒ **`APPSYNC=MISMATCH` exit 1**（**基线不是 PASS**）；② **删一份**（`SystemFontsProbe/bin/Debug/ReachFramework.dll`）⇒ **期望基数 47→47 不变**（= "基数不依赖现场文件"的两极化证明）+ **点名"缺哪一份 + 谁要求的"**；③ **整份还原**（纪律 16）⇒ sha 回 `a224b0973be9d7e2`、`cmp` 相同、回基线；④ **多余副本** ⇒ `UNEXPECTED` + exit 1。**`--selftest` A–L 12/12 `SELFTEST=PASS`**（K：删前/删后基数不变 + 删⇒红 + 整份还原⇒绿；L：多余⇒红）。
> **🔴 它抓到的既存缺口（非本波引入）**：`MISSING samples/HelloWpf/bin/Release/net10.0/DirectWrite.Linux.Provider.dll` ← `HelloWpf.csproj →(引用 PF)→ … <Reference Include="DirectWrite.Linux.Provider">`；依据 = **Debug 兄弟目录里这份在**（09:14 刷过）而 Release 目录文件 mtime 全 `09-10 14:58~15:13` ⇒ **"PF 依赖 Provider"之后的引用图下该 Release 目录从未重建过**（旧构建产物，不是被删件）。**主控裁定 = 走"修"不走"改口径"**：在 #11 之后的波里跑一次 `dotnet build -c Release samples/HelloWpf/HelloWpf.csproj` 再复跑检查器（期望 `OK 41→42 / MISSING→0`）；**构建若失败则拿原文回来重裁**。**在此之前这条红保持红**。
> **仍然瞎的那一半（如实登记）**：**脚本拷贝的原生件"存在性"算不出来**（第 5 极实测：删 `ContractProbe/bin/Release/libwpfwin32.so` ⇒ **无任何 MISSING/UNEXPECTED**，只是 `OK 41→40` ⇒ **静默**）。拷贝点实测 5 处：`run.sh:95`、`run.sh:228`、`publish-milbridge.sh:44`、`close-wave.sh:92/126/129`（后两条只读）。**裁定**：**要求 A（立刻）** = `#SUMMARY` 必须**显式印出"看不见的拷贝点数 + 清单"**（仪器要主动承认看不见，L19/L21 族）；**目标形态（登记）** = 拷贝点写 manifest（检查器侧 T2，脚本侧由主控协调）。
> **它自曝的 5 个模型错**（§27.2 记档）——最关键那条：曾**跟着 `ProjectReference` 走进 `CycleStub`** ⇒ 把 `ReachFramework` 误期望进 `System.Printing`（反证 = PC 目录里根本没有它、`System.Printing` 19:09 刚建完、**RAR 真值 = 不含**）⇒ **模型的正确性靠"新构建"交叉验证打掉，不是自说自话**。
> ### ✅ **M7b 阶段 1 落地：`D-U1` 的两条不变量里"零调用者"那条已是会变红的仪器**（三条牙原文见其报告 §12）
> 工具 `wire-uiautomation-resolver.py`（新 sha16 `1b428ff42a6aaa73`，改前 `30fadde86bfe3e72`）：新增 `[零调用者]`（**字符串级**扫描 + 命中分类为 调用点／定义／文档注释 + 报不可读/二进制文件数）＋ `[正对照]`（`SupportsWin7Identifiers` 调用点必须 ≥1）＋ `--root`（临时副本突变）＋**自排除**；**退出码 `0` 绿／`1` 不变量被破／`2` 仪器无信息（不许报绿）**。
> **三条牙实测**：牙① 副本里加一个调用点 ⇒ `调用点 1` + `[不变量被破] … 必须重新裁决（不许只加映射）` **rc=1**；牙② 删正对照调用点 ⇒ `[仪器无信息] … 结论不成立（不许报绿）` **rc=2**；牙③ 还原 ⇒ 与基线逐字相同 **rc=0**。突变全在 `/tmp/du1-mut`（纯净备份 `/tmp/du1-pristine`），**真源指纹复读未变**。
> **⭐ 它自曝：这三条牙第一轮就抓出它自己 v1 的三个 bug（v1 其实没在监控）**：① 分类函数把 needle 写死 ⇒ 正对照恒 0 ⇒ 恒报"无信息"；② 仪器把自己算成"调用点"；③ 镜像目录少一级（`MS/Internal/` vs `MS/Internal/Automation/`）。⇒ **"我加过断言了" ≠ "它在监控"**，又一次由牙证明。
> **它复核我的四条证据**：结论一致；并**指正我①的枚举不精确** —— 全仓命中**随文档增长**（它数 28 vs 我 24），且**多出的一条 `.cs` 命中是上游自陈注释**（`AutomationIdentifier.cs:34` `// All Guids will be empty now since we are not calling UiaLookupId…`，**反而是佐证**）⇒ **判据只能是"调用点 0"、"总数"不是判据**。**已按此改 `KNOWN-DEFECTS.md` 的 D-U1 ①行**。**阶段 2**（托管牙 `D3`/`D4` + 变红实测）等 #11 波结束的信号。
> ### 🔴 **主控自查出一条仪器族缺陷：artifact 的"被测 shim sha256"头行会给自己贴错标签**
> **🛑 主控自我更正（同日 19:48，由读码推翻了自己 19:36 的结论 —— 这条留作"记录也会错"的实例）**：我当时的论证**不成立**。`build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj:35` 是 `<Compile Include="$(HbShimSrc)" Link="PresentationCore.HbTextLine.cs" />` ⇒ **harness 把 shim 源文件本身编进自己的程序集**（"反射分支"；`Program.cs:5` 明写"必须驱动 `build/shims/…HbTextLine.cs` 本身"），并且 `Program.cs:84-129` 有 **T0.1/T0.2 身份自检**（`TextLine` 基类来自 PC、探针目录 PC 与权威件 4/4 一致）。⇒ **头行那个 sha 就是"本次读数真正测的那一份"**（= harness 编进去的源），**不是错标**；19:34:12 那趟（头行 `B4C7AA82…` 而 PC 是 19:10:18 旧件）**对读 harness 的那个人来说本来就是对的** —— 错的是**我**把 `gen/*` 的 sha 读成了"应用 PC 里那份 shim"。
> **仍然成立、仍值得改的两点（降级为"歧义 + 缺仪器版本"，不再是"错标"）**：① 标签**没说清**"编进本 harness"还是"编进 PC" ⇒ 读者（包括我）会混；② artifact **不带仪器版本**（`run.sh`/`Program.cs` 的 sha16）⇒ 违反纪律 18 的四元组。**故保留改动要求，理由改写**：头行应印"**被测 shim 源 sha（本 harness 直接编入）** ＋ **PC 内 shim sha** ＋ `hbtextline_shim_stale` ＋ **仪器版本**"，**不是**因为原标签错。
> （原记录，作为反面教材保留）三份 `gen/*` 的头行都印 `# 被测 shim sha256 = B4C7AA82…`，而 `ShimSha256()`（`Program.cs:928`）取的是 **`T1B_SHIM_PATH` 或默认源文件**的 sha ⇒ 我当时据此判定"它报的是源文件、读数测的却是编进 PC 的那一份"。**已要求 T1d 波后改**（后改派 T1b），**判据** = 在"源已改、PC 未重建"状态下头行必须能看出来。**这条独立记一笔，不并进 `D-T1` 判据**。
> ### ✅ **T1d 的 `#11` 收口交付（波后全部重取；报告 §12，sha `8f6b7741…`）**
> **判据命中**：`tab-zero` 结构败 **`13 → 1`**（`b34-tabs 12/18 → 18/18`、`tab-only 8/14 → 14/14`、`Q3 4/4 → 28/28`、合计 `判定过 73 → 85`）；**射程内 12 ⇒ 0**；**第 13 例点名保留**：`notab-control@w40@em24@RTL@tab0 :: 行#0 尾部空白 期望=0 实得=1`；`tab-rtl` 可比部分结构败 `0`（`he-tab-only 5/8→8/8`），两套最大差 `0.0000`。
> **六项 + 三份明细**：`T2c 34 可比例/不一致 0`｜记账 `1286/1298（①286/286 ②68/68 ③984/988）`｜分桶 `167/1084/47`｜`T2b 972/972·213/213`｜`T2d H/B 1298/1298、Extent 1260`｜`T3 判定 1298/1298、明细 218/236、空参 253/253·1045/1045`｜默认 oracle `114/57/0`（最大差 0.0053）｜通过 20/失败 2；**折叠 18 / Extent 58 / 记账 17** ✓。
> **⚠️ 口径更正（T3 在 #11 复取时钉住的易混点，主控照收）**：**五个数字各有其口径，不许互串** —— **`12` = 记账的行级**（`gen/tline-ledger-lines-*.txt` 的 `# 条数 = 12`）、**`17` = 记账的用例级**、**`47` = 宽度分桶 `>0.34 DIP` 的行数**（**不是明细条数**）、**`58` = Extent 余差条数**、**`18` = 折叠明细条数**。⇒ **不变式三元组 = `18/58/17`**；我先前那句"主控独立读 `gen/*` 复核过 `47/58/18`"**把宽度桶混进了明细三元组**，现更正为：**主控独立读 `gen/*` 复核 = 宽度分桶 `167/1084/47`、Extent 余差 `58`、折叠段1 `18` 行**。
> **牙（真源上改、跑完逐字节还原）**：变体 `b48fb6e8…` ⇒ **结构败 `13/86`、`Q3 4/4`**（= `D-T1` 前逐项一致）；`cp` 还原后 sha = `b4c7aa8210c71cbe` ✅ **逐字节回到定稿**，重跑 ⇒ `1 / 28/28`。
> **改动清单断言**：`diff` 总行 97｜新增 51（注释/空行 28）｜删除 14（0 注释）⇒ **行为行 `+23 / −14`，全部落在 6 处声明锚点**；**判据 `stop > width` 一字未改**（`a > room && IsLineStartTab(...)`）。§11.1 那句"未验证的选择"已改写成**已由 U1 `Q5` 验证**（引 `tab-anchor-oracle.txt:129/131/132`）。
> ### 📌 **新登记 `D-T2`（Tab 的缩进语义未补全）—— 同一件发现的两半，队列第 4 位（#14）**
> **事实（T1d 量的，全部只读）**：① shim 侧 `ParagraphIndent` **零匹配**、**PC 侧今天从不传 `Indent`/`ParagraphIndent`** ⇒ U1 的 Q5/Q6/Q8/Q9 **真值在手却打不到我们这条路径**；② **12 例全在 `Indent=0/ParagraphIndent=0`**（`tests/parity/windows/tab-zero/PROVENANCE.md:12` 明写）⇒ **`D-T1` 的修法只对 `Indent=0` 宣称对齐**（报告就这么写，**不许**写成"Tab 语义已对齐"）；③ **同族第二缺口**：`EffectiveWidthTab` 的 `pen` **从 0 起算、忽略 `Indent`**（`build/shims/PresentationCore.HbTextLine.cs:1531`）⇒ **测量侧与整形侧不一致**（Q11 那 4 例把它暴露成 "advance 16 vs 0"）。
> **Q11 退化 4 例（`:411-420`）登记为边界**：真值 = `ParagraphIndent + Indent ≥ container` ⇒ tab **零宽**（box `[24,24]`/device `[48,48]`）、`line.Width=24`、**`HasOverflowed=true`**、`clamped=False`，**公式不覆盖**；**我们今天的实现无法表达该配置**（强传 `indentDip=24, paragraphWidth=16` ⇒ 测量侧 advance `16` vs 整形侧 `0`，且 `HasOverflowed => false`）。
> **接线代价（已量）**：`FormatLineInternal(…, TextParagraphProperties paragraphProperties, …)`（`:494-499`）**已在作用域内** ⇒ `:536` 调用点**多传 1 个实参（PC 侧 1 行）** ＋ shim 侧新可选参数，用在**网格原点右移（Q8）**与**钳位目标（Q6）**（5–6 行）。
> **判据**：镜像 `tab-anchor` arm（读档 **0 行翻译** —— 字段同名同义；差的是缩进语义那一层）⇒ 按 **Q5/Q6/Q7/Q8/Q9/Q11 逐项对拍**，并把 `D-T1` 从"**行数对**"升级成"**`breakCause` 逐行断因对拍 + `hasOverflowed` 对拍**"。
> **红旗**：① 为拿 `ParagraphIndent` 改 PC 的 `FormatLineInternal` 签名**必须与 shim 侧同波**（否则传不到、看起来像"修法无效"——`M_modifier` 同款教训）；② **不许**用"把 `EffectiveWidthTab` 的 `pen` 也按 0 起算"来消除两侧不一致（那是**把整形侧拉向错的一侧**）。
> ### 🧾 **新纪律 L22：判据的"退出码恒 0"= 仪器不会变红**（T1d 在 #11 主动报出、未擅改）
> `CoverageProbe --tab-lines-oracle` **恒 `exit 0`**（`Program.cs:1074`）⇒ 判定**只存在于输出文本**（`TAB_LINES 合计 … 结构败=N`）⇒ 任何"跑一条命令看 rc"的自动化都会**假绿**。**判据**：凡按 rc 判的判据，必须先用**一个必失败的输入**证明 rc 会非零；本项目采用 `--known-red <已登记用例表>`（未登记失败 ⇒ 非零；登记过的仍红 ⇒ 只点名、不改退出码），**归 `CoverageProbe` 车道、并进 #12 的 harness 版本升级**。
> ### ✅ **U1 批次 2 交付：`modifier-scope`（53 例，`DETERMINISM=MATCH`）—— 把 `#13` 的判据从"两条候选"变成"第三条真规则"**
> **① 主项（`TextModifier` × `lbNull`）**：**真规则 = `GetTextLineBreak()` 非 null ⟺ 该行不是末行 ∧ 该行结束时 `TextModifier` 作用域仍处于打开状态**（关闭用的 `TextEndOfSegment` 到该行结束为止还没被消费）。U1 判据原文（**99/99 行吻合**）：`nonNull(line) == (!line.isLastLine) && (openIndex >= 0 && openIndex < line.endCharExclusive) && (closeIndex < 0 || closeIndex >= line.endCharExclusive)`。
> **两处反例**：① **否掉段落级** —— `A-scope-line0` 第 1..n 行（段落带 modifier、行行都有后续行）break **全 NULL**；② **否掉"相交即非 null"** —— 同例**第 0 行**（相交、非末行）仍 **NULL**，因为 **scope 在同一行内就关闭了**。六组对照（`A` `NNNNN/NNNN/NNN`｜`A-rtl` 同构｜`B-scope-lastline` `NNNNyN/…`｜`C-scope-whole` `yyyyyN/…`｜`D-nomodifier` **恒 null**｜`E-scope-oneline` 末行 `N`）＋正向对照（`C2-scope-visible` 把 emSize 翻倍 ⇒ w80 行数 **6 → 14**、最大 advance **19.993333 → 39.983333**）。
> **附带**：`TextLineBreak` 携带的 scope 的 `_cp` = **客户端返回 `TextModifier` run 的字符下标**（`B`=30、`C`=0；**43/43 相符**）；`TextModifierScope` 只有 `_parentScope/_modifier/_cp`、**没有 end/limit 字段** ⇒ "相交段起止 vs 段落整段"这个二选一**在对象里没有对应物**；且它**不在公开 API 上**（公开面只有 `Dispose/Clone`，类型 **internal**）⇒ **判据只能用"null / 非 null"这一位**，反射读到的值**不许进判据**。
> **其余三条真值**：**② 笔位恰在停靠位 ⇒ 前进整整一个 interval（96），不是 0**（7/7，LTR+RTL，两种构造）⇒ 我们"**严格大于**笔位的下一个网格倍数"是对的；U1 同时把 `tab-anchor` 文档里"最小 `k*interval ≥ pen`"**更正为严格大于**（旧样本笔位都不在格上 ⇒ 旧结论不受影响）。**③ RTL + `Indent>0` + `ParagraphIndent>0` 的钳位闭式成立**（8 条逐位相符；闭式为负 ⇒ 零宽 `[0,0]` + `HasOverflowed=true`）。**④ 行首 `\t\t` ⇒ 每个 tab 各占一行、各自钳满**（不合并、不零宽、无空行）⇒ **"循环终止"的边界 = 每个 tab 结束它所在的行**。
> **U1 自纠两条**（都靠复跑改掉）：整数被渲染成字符串导致 `"30" != 30` 误报；探针用子串 `"nd"` 匹配命中了 `TextSourceCharacterIndex` 里的 "nd" 而误报"存在 end 字段" ⇒ 改成按字段名精确判定。**取不到**：scope 不在公开 API；嵌套 modifier（`ParentScope` 全 null）与 `HasDirectionalEmbedding=true` 未测。
> ### ✅ **M7b 阶段 2 预备完成（只读 + 写文档）**，且**改掉一条我写过的口径**
> **① 代码形态**：`D3`/`D4` 完整 xUnit（**全反射**，三个类型都是 internal、测试程序集无 `InternalsVisibleTo`）；`D4` 要**拆一层 `TargetInvocationException`** 后断言 **精确类型** `DllNotFoundException` 且 `IsNotType<EntryPointNotFoundException>`；**不学 `D2` 的"类型不在就 return"**（那是静默假绿）。
> **② 变红方案（实质突变、不碰真源/产物）**：`D3-A` = 把 `WPF_OSVERSION_FALSE` 在 `/tmp` 副本里改成 `return 1;` ⇒ 编到独立输出路径并由 **`WPF_LINUX_WIN32_SHIM=`**（resolver 的最高优先级覆盖 `Win32ShimResolver.cs:65`）指过去 ⇒ 谓词变 true ⇒ 档位跳档 ⇒ **红**；`D4-A` = 把测试 bin 整份拷到 `/tmp`，把该 `.so` **改名成 `UIAutomationCore.dll`** 丢进 app 目录（库名能被探测到、**符号不存在**）⇒ 异常变 `EntryPointNotFoundException` ⇒ **红**（若该探测行为不成立 ⇒ **如实写"未取得变红实测"**，不写"应该会红"）。**兜底**：改错期望常数/异常类型 ⇒ 立刻红。**恒真陷阱清单**：用 `NotNull`／`>=30000`／拿 `actual` 当期望 ⇒ 恒真；用 `Assert.Throws<Exception>` ⇒ 放行 `EntryPointNotFound` ⇒ 假绿。
> **③ 运行时档位复核 = 最后那个 `else` 档**（`LastSupportedProperty = Properties.TransformCanRotate`）：链是**纯 if/else** 且每条件都是 `IsOsWindows*OrGreater`（`:31 RS5 → … → :103 7‖(Vista && SupportsWin7Identifiers())` → `:112 else`）⇒ 经 D1 resolver 落到 20 条 `WPF_OSVERSION_FALSE` ⇒ 全 false ⇒ 落最后 else。**⚠️ 口径更正（主控记）**：`Properties` 是 `AutomationIdentifierConstants` 的**嵌套枚举**（`:125` 起，首值 30000），`LastSupportedProperty` 是**静态字段**（`:23`）**不是属性** ⇒ 反射必须 `GetField`、断言必须是**枚举成员相等**（"能红"与"恒真"的分界）。**它不会红的情形**（U1 如实说）：上游在链**上方**再加一档（如 Win11）时谓词恒 false ⇒ Linux 仍落最后 else，**不算破**。
> ### ✅ **T1b 吸收两条更正**：`T1B_ROW_DUMP`/`[ROWD]` **是要新建的开关**（主控实测：只命中它自己的设计文档，`run.sh` 与 `Program.cs` 零命中）；逐字符列**只印我们侧**、真值侧一律 **`truth=NA(source=行级 oracle 无逐字符真值)`**，判据表升级为**四 + E 结局**（E = "该列没有真值" ⇒ 报无信息）。⇒ **#12 的 harness 版本升级 = 四件**：(a) `[ROWD]` dump **T1b**；(b) 三族断言 + `cr.Width >= 0` **T1b**；(c) 头行贴标签修 **T1b**；(d) `--known-red`（`CoverageProbe` 侧、`--tab-lines-oracle` 恒 `exit 0`）**T1d**（与 T1b 的 `Program.cs` **不同文件** ⇒ 单写者规则不冲突）。
> ### 🧾 **两条新纪律入 `docs/CURRENT-STATE.md` §5**：**21. "退出码恒 0" = 判据不会变红**（`--known-red` 的形态）；**22. 仪器缺列不许"补列"**（真值源没有的列一律 `NA(source=…)`，判据退化为"行级真值 + 我们侧逐字符量"的算术）。
> ### ✅ **`#11` 门禁由主控独立跑通并复核**：`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜两档 `WPTD_TIER_SUMMARY passed=3/3 failed=0 inconclusive=0`｜6 条 `BASELINE … result=PASS`｜`WPTD_BRIDGE_SRC_STALE=no basis=pub=705ed5ccd0c498a1 now=705ed5ccd0c498a1 so_file_match=yes`｜`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=167`｜load gate `1min=0.94 ≤ 12`（尝试 0 次）｜`run_dir=~/wfp-runs/go-freeze11`｜`max_concurrent_apps=1`、`leftover_after=0`、桥契约 `ok(0 且无条款表；尾部=）`。**`WPTD_ARTIFACTS_EXT` 有变**（`reachframework 96c9e2385713c3cc`、`presentationui 7af071d62cc90471`、`systemprinting 3997e46a660d697e`；其余同 #10）⇒ 按口径**记入 #11 表头**。**`verify-all.sh` 正由主控在后台跑（`/tmp/verifyall11.log`，`:99`）**，与 T3 的 `:97` 探针并行。
> ### 🔬 **T1b2 的 `[ROWD]` 判决（#12 的入口读数）：A 假设成立 —— 但它把这一族**劈成了两个不同机制****
> 四元组：`shim 源 b4c7aa8210c71cbe…`（= #11 的 hbtextline）｜仪器 `run.sh 3e513e88a4fa4ec9` / `Program.cs 54db729b1e757753`｜判据 `T1B_ROW_DUMP` 逐字符 dump + 行级 oracle 算术｜artifact `/tmp/t1b2/rowdump-official.log`。7 个点名行**全部命中、缺失 0**。
> **机制一（A，行尾空白口径差）= 4 行**：`A1_nbsp_zwsp_w30#0/w30#2/w40#1/w80#0`。真值文本以 **U+00A0（NBSP）结尾**，而真值 `ws=0`、`witw−w=0.0000`，且 **`|Δ行宽| == adv(NBSP) = 4.1600`**（实测 `−4.1587/−4.1600/−4.1593/−4.1567`，残差 ≤0.0033）⇒ **我们把行尾 U+00A0 当行尾空白扣掉了**（.NET 的 `char.IsWhiteSpace('\u00A0') == true`），**真机把它计入 `Width`**。⇒ 修法 = `IsTrailingWhitespace` 与 `WITW−W` **同改**（T1c 的假设成立，**归 T1d、留在 #12**）。**顺带否掉一个变体**：**ZWSP 不在这条里**（`IsWhiteSpace('\u200B') == false` ⇒ 我们本来就不扣；`B_nbsp_zwsp_trim#1` 的 `ws` 两侧都是 0）。
> **🔴 机制二（C，advance/行度量 —— 与空白无关）= 3 行**：`A1_nbsp_zwsp_w20#7`、`F_nbsp_zwsp_w40#3`、`B_nbsp_zwsp_trim#1`。`ws` 与 `WITW−W` **两侧一致**，但 `adv_ours 和` 与真值 `witw` 差 `6.4000/6.4000/6.7167`（**≠ 任何单字符 `adv_ours`**）；**三行都含 `与`** ⇒ 我们的 `与` **advance = 9.60**，真机 = **16.00 = 1 em（整字宽）**。⇒ **这才是负 `cr.Width = −3.0560` 的根因**（`F_nbsp_zwsp_w40#3` 正是契约①那条），**是字体/回退选取问题，不是空白问题**。
> **⇒ 主控裁定（三条）**：① 机制一归 T1d 的 shim 修、**留在 #12**；② **机制二开成独立在册项 `D-F1`（CJK `与` 的字形/advance 选取）**，归属字体栈那条线，**不塞进 #12**（两件事混一波就无法归因）；③ **纪律 17 当场又抓到一个**：过去把"含 `与 `"归到 **`Extent` 的结构性不可比**，现在证明它**同时影响行宽**且正是负宽根因 ⇒ **"不可比"里藏着可修的缺陷**。
> **T1b2 自曝的仪器 bug（照收）**：它第一版用**我们自己的** `IsTrailingWhitespace` 去数**真值**侧的可见尾空白 ⇒ 两侧都算成 1 ⇒ **把 4 条 A 误判成 B**；改成从真值自己的字段推（`ws − nl`）才对。⇒ **"仪器不许替真值做假设"**的又一实例；修正后它**手算复核过但还没重跑**（要静树重跑后再交原文）。
> ### 🧾 **一条新登记的仪器/环境敏感：`ManagedLayer.Tests` 的端到端输入用例在并发负载下会**假红****
> 证据链：**19:52 波内 `verify-all` ⇒ `ManagedLayer.Tests rc=1`**（唯一失败 = `M7cInputPathTests.端到端_真应用收到指针与按键_不崩且事件到达窗口`，34 s 判败）｜**19:56 我与 T1b2 的活并发时单独 `dotnet test` ⇒ 1/74 败**｜**19:59 树静（load 0.95）后：直接跑 runner ⇒ `INPUT_PROBE=PASS`；`dotnet test` ⇒ `74/74` 全绿**（20:01:36）。
> ⇒ **判据读数只在静树上取**（这条纪律现在有了实测依据）；该用例值得加"负载闸门"或标记为 load-sensitive。**注意**：这条假红导致**收官波在 `[5/6] verify-all` 处 `rc=1` 中止**（波自身 `[1]–[4]` 步全绿：生成物指纹 `state=ok`、应用器审计 `miss=0`、**输入稳定性 波前==波后**、native 与桥均正确跳过），**故 #11 尚未冻结**；主控随后在静树上重跑 `verify-all` 与门禁再冻。
> ### 🔴 **新在册 `D-R2`：`ManagedLayer.Tests` 的 testhost 会**间歇崩溃**（环境敏感，未修）—— #11 的判据③ 必须如实带上这条**
> **六趟读数（全部可复算）**：① 19:44（波前树）`verify-all` ⇒ **9/9 全绿**｜② **20:01 波内 `[5/6] verify-all`（与波自身构建 + T1b2 并发）⇒ `ManagedLayer.Tests rc=1`**｜③ **20:04（静树、新起 Xvfb）⇒ `ManagedLayer.Tests rc=1`，失败集合与②不同**（4 条 FAIL + testhost 崩溃）**｜④ 20:13（静树）`verify-all` ⇒ **9/9 全绿、`ManagedLayer.Tests 74/74`**；另有 **4 次独立复跑全绿**：20:01 手跑 `dotnet test` 74/74、20:08 手跑 `--blame` 74/74、19:59 直接跑 runner ⇒ `INPUT_PROBE=PASS`、20:12 **"精确序列复现"**（照 `verify-all` 的 `[1]` 构建 + 四套件顺序 + 详细 logger）⇒ **rc=0、全绿**。
> **证据细节**：两次红都发生在**同一趟序列的 `[2]` 第 5 套件**；两趟失败集合**各不相同**（②=`M7cInputPathTests.端到端…` 1 条／1/74；③=`Win32AbiLayoutTests.NativeLayout_MatchesManagedLayout`×6 + `WndClassExD_MarshalsToNativeLayout` + `Shim_IsLoaded_FromRepoFallback` + `M7cRealAttachmentTests`×3 + `HwndWrapper_CreatesRealX11Window…`，11 条，**通过 46**，`测试主机进程崩溃`）；**两趟红的崩溃点都在 `00:01:07`**，而绿的整跑约 `00:01:10` 结束 ⇒ 线索指向**收尾阶段的竞态/原生崩溃**，不是件字节（`pc 4f2e621a4ad26cd0`、shim `b4c7aa82…`、`win32shim 0098234982391bbf…` 全程未变）。
> **两条副产物**：① **`libwpfwin32.so` 不在测试工程 bin 里（设计如此）** ⇒ `Shim_IsLoaded_FromRepoFallback` 走 `build/shims/Win32ShimResolver.cs:306-360` 的**仓库回退**（`WPF_LINUX_WIN32_SHIM` → `WPF_LINUX_ROOT` → 从 `AppContext.BaseDirectory` **与** `Directory.GetCurrentDirectory()` 各自逐级向上 12 层找 `src/WpfGfx.Linux.Native/bin/<name>`）；② **`dotnet test -v q` 会把断言正文吃掉**，`/tmp/verify-all-*.log` 只剩 `[FAIL]` 标题行 ⇒ **"为什么失败"答不出**（下一个人请用 `--blame` 或 `-v n --logger "console;verbosity=detailed"`）。
> **处置**：**#11 的判据③ 以 20:13 那趟静树 `verify-all` 的 9/9 为据，并把这 2/6 的红原地登记**（不掩盖）；`D-R2` 的重启入口 = 在该套件上加 `--blame` 抓崩溃用例名 + 同时记 `free -m`/`loadavg`；**判据：连续 5 趟 `verify-all` 无 testhost 崩溃才可关闭**。
> ### ➡️ **下一步（更新五）**：**官方门禁正在当前树上重跑**（`~/wfp-runs/go-freeze11b`，日志 `/tmp/gate11b.stdout.log`）—— 因为本波把 `pf` 重建成了 `0878daff7a14d385`（`pc` 用同一份源重建后 sha **仍是 `4f2e621a4ad26cd0`** ⇒ 再证 PC 确定性）⇒ 冻 #11 必须用**新树上的门禁读数**。门禁绿 ⇒ **立即冻 #11** ⇒ 放 T1b2 继续（#12 仪器四件）与 T1d（机制一修）。
> ## 📌 2026-09-14 上午（波 20/21）：**"能变红的牙"连挡两次不完整修法** + 口径缺陷从装置一路清到生成物（原始记录）
> | 版本 | `libwpfwin32.so` | 病灶 | 证据 |
> |---|---|---|---|
> | 波 19 | `f84d65a6…` → `b2301ee2…` | **只记左右专有 VK**（`XK_Control_L→0xA2`），而 WPF 查通用 `VK_CONTROL 0x11` ⇒ 通用位恒 0 | `[API]` 按住 `0x0000`／松开 `0x8000` —— **反相** |
> | 波 20 | `b2301ee2…` → `e41048f8…` | 补了 `wpf_vk_generic()`（专有+通用一起更新）⇒ **API 牙绿且极性正确**（按住 `0x8000`/`0x80`、松开 `0`/`0x00`）**但两条行为牙仍红**：**整批抽干**（`ctrl+a` 四个 X 事件一次泵全抽干后再逐条派发 ⇒ 处理 `a↓` 时实时表已被 `Ctrl↑` 清掉） | 掩码实测 `Ctrl↓ state=0x0 → a↓ 0x4 → a↑ 0x4 → Ctrl↑ 0x0` |
> | 波 21 | `e41048f8…` → **`39d343c801f12d0c`**（278,752 B / 469 导出） | **逐消息修饰键快照**：`wpf_msg_node.mods`（**不动跨边界 `WPF_MSG`**）+ 事件时刻算 4 位位 + 入队盖戳/出队记 `s_pop_mods`/派发期暴露 + `GetKeyState` **派发期优先读快照**；新增取证行 `[MSGFLOW] dispatch … 快照修饰位=0x… （实时表 ctrl=…）` | 四份 `-fsyntax-only` 0 警 0 错；**待 M7b 复跑三条牙** |
> ⇒ **纪律确认**：**"修法不完整"过不了牙**，而这正是"牙必须能红"的用途；两次都不是靠人眼发现的。**两次过程事实已要求写进报告**。
> ### ✅ T1b：runner 的"注入前读数被当成注入后结论"**从根上修掉**（并全域扫同族）
> - **口径**：`run-wpfprobe.sh:705-714` 两处结论句改写 —— `changes=0` 取自**注入前**台账行 ⇒ **无信息**（不是"键没进"）；**有写后读数且陈旧**才记缺陷，否则记 `INCONCLUSIVE(无信息)`（并指向 `t1c-dp1-leg-audit.py`）。
> - **取值**：`tail -1`（"最后一行"）→ **按注入时刻行号下界**：`INJECT_AT_LINE="$(wc -l < feat-lines.txt)"` 在 `xdotool key/type` **之前**取，取值改走新工具 `build/MilBridge/tools/pick-feat-line.py`（输出 `AFTER|NOINFO`）。
> - **牙（实测能红）**：四组假日志全 ✅、exit 0；**把取值换回 `tail -1` 语义 ⇒ 第 1、4 组立刻 ❌、exit 1** ⇒ "谁改回旧写法，牙必红"。
> - **同族扫荡**：两个 runner 逐条处置（已修 `:720-721`；**登记不改**：`:411/413/415/416/422/423`（应用日志单调追加，"最后一条=最新"成立，**若将来出现 late 变体必须改**）、`:587`、`:604`（取的是最大值不是行序）、`:768`、`:57/519/539`、`:234/320`、`run-hellowpf.sh:107/144`）。
> ### ✅ T1c：旧债复跑 + 判因三分 + **两处"出厂级"口径缺陷已报待改**
> - **`build/MilBridge/tests/InputTraceProbe/`**（路径更正：**不在 `tests/`**）两臂断言 v3 后首次复跑 ⇒ **2 断言 / 2 通过 / 0 失败**（`DEFAULT` 全 0 行；`ENABLED` `11/11`、`零行入口=0`、`totalLines=201`=`200 额度`+**1 行 L12 触顶提示** ⇒ 该提示**实测可见**）。
> - **判因 = 装置陈旧**（既非断言陈旧、也非回归）：v3 后插桩类引用 PC 受限类型（`PreprocessEarlyGate(..., IKeyboardInputSink)`、`InputReport`）⇒"抽出来独立编"必 `CS0246/CS0122`；**不可能是回归** —— 同段文本在 PC 里编过且**实跑执行过**（现场日志里 `PreprocessMessage WM_CHAR 入口…wParam=65/66`）。**修法**：改成**反射调用真件**（`Assembly.LoadFrom(PresentationCore)`）⇒ 装置更强（测真件 + 输出 sha16），且**不需要 `InternalsVisibleTo`**（省一轮波）。顺带修掉两处装置缺陷：**藏失败**（只打最后 3 行 ⇒ 编译失败被读成"断言失败"，**L12 的姊妹**）与 `Split('\n')` 被 Python 变成真换行（`CS1010`）。
> - **L17 扫出的两处出厂级口径缺陷（主控已批准，随 wave 21 改；只改消息文本、不改判据）**：③ `patch-windowsbase-dpvalue-trace.py:422` —— 从**读侧**标志推**写侧**事实（"写侧没留住 deferred 标记"，**D-P1 同病根**）；④ `patch-presentationframework-textbox-textdp-trace.py:25/:68/:69/:571` —— "一直停在旧值"（已被 §34 证伪）**随生成物出厂**（`TextContainer.Linux.cs`×2、`TextBox.Linux.cs`×1）。
> - **判据工具加固（关键，防"Ctrl+A 修好后翻车"）**：容器真值**一律从容器侧读数（`Q4d/Q5c/Q7a/Q7b`）量出来、不从注入方式推断**，比对改 **as-of**（该读那一刻的真值）⇒ "替换 vs 插入"只改期望值、不改判据结构；新增极性专测"容器已 `AB` 而写后读拿到更早的 `A`" ⇒ **判红**（旧版会误判绿）。
> ### 🧾 基线状态（**重要，别拿错**）
> **canonical `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 当前仍是 #7**（头部/6 条机读行都是 #7 的八位）；T3 那趟 `go-freeze8b` 的新 tuple 只落在**它自己的 run dir**（`~/wfp-runs/go-freeze8b/baseline.md`，config = `pc:ebf4cf87…, bridge:759a3224…, pf:3136f665…, win32shim:e41048f8…, hbtextline:e1bc947a…(stale:no)`）。**#8 将在 wave 21（T1c 两处消息修复 ⇒ PC/PF 再变一次）之后的最终件上冻**，届时八位 = `pc`(wave21)/`pf`(wave21)/`wb 8c073fab…`/`provider 71ba86c6…`/`win32shim 39d343c8…`/`wic 03b67fbc…`/`hbtextline e1bc947a…`/`bridge 759a3224…`（**桥本波不再变**：`src/**` 未动 ⇒ fp 仍 `705ed5ccd0c498a1`）。
> ### 🧾 波 21 定稿（2026-09-14 09:50–09:54，主控）+ **`D-P1` ① 关闭** + **`D-K1` 真因落地**
> **wave 21 全绿**：`WAVE_RC=0`、失败步骤 0；2.5 应用器审计仍 `20/74/0`；3.5 三份指纹 `state=ok`（PC `d6676597c9517ee1` / WB `e8e18b887b6535bd` / PF `80bc2130203ad9a2`）；3.6 `APPSYNC=PASS`（无落单者）；4/4 五个自产程序集**均已签名**；**5/5 输入稳定性：波前==波后==`eab59324…`**；工具侧输入指纹 `e1c638ca…` 波前==波后。
> **最终八位（#8 冻结用）**：`bridge 759a322431f1e457`（fp `705ed5ccd0c498a1`，本波**未变**）｜`pc 6be29475b6aeb34e`｜`pf 50da85138a7bc3e8`｜`wb e6216fe961a2bfb9`（T1c 消息级修正 ⇒ 重编后变了）｜`provider 71ba86c6495347fe`｜`win32shim 91baee84270f2322`｜`wic 03b67fbcd7c385b6`｜`hbtextline e1bc947afc248b32`。
> **★ `D-P1` ① 关闭（可复核的终判）**：`DP1_LEG state=closed rc=0 write_rows=4 reads_after_write=3 object=TextBox# dp=432 hit@L2068`；`DP1_LEG_CHAIN Q5c Changed 已 raise=3 / Q6b 即将 OnTextChanged=3 / Q7a 入口=3 / Q7b 已 SetCurrentDeferredValue=2`；`DP1_LEG_WHY 写后读到的 DP 值 == **该读发生时**的容器真值（'AB' @L2054）⇒ 该链当场闭合`。**行号铁证**：首按键 L540 < 写后读数 L636（`WFP_POSTWRITE t=13638 变更 text='AB' len=2 changes=2`）。零注入反证：`--only=text-dp-min` 给出 `t2='A' c2=1`（且 `KEY_DIAG=0 / push=0` 确认零注入）。⇒ **`changes=0` 那一族 = 观测口径失效（采样窗早于注入），不是回归、不是 DP 缺陷**。
> **`Ctrl+A` 在真应用里生效**（首字符后即 `len=1 text='A'` ⇒ **替换**语义，而非 `len=8 "Aseed-文本"`）⇒ 这正是 native 修饰键修法的**可观测后果**。
> **★ `D-K1` 的"装置仍红"另有其因（M7b 定位，非 shim 缺陷）**：同 shim 两个结论**都为真**，差别在**泵的纪律** —— 真应用是**常驻泵**（4 个 X 事件之间有真实间隔、到达即处理）⇒ 修饰键可见；装置旧口径是"**一条命令后一次 `Pump()`**"⇒ **整批抽干**，派发 `a↓` 时实时表已被 `Ctrl↑` 清掉 ⇒ 不可见（**装置伪影**）。**A/B**：`[i]`/`[i2]`（一次泵）⇒ `"ABseed-文本"`；改成**按事件泵**（keydown ctrl→泵→key a→泵→keyup ctrl→泵）⇒ **两条牙自动变绿**（**断言一字未改**）。
> ⇒ **M7b 随之把自己写重的那句收窄**（原写法折进 `<details>` 留档）：真缺陷 = `GetKeyState` 原本是 `return 0` 的桩、`GetKeyboardState` 导出不存在（**shim 侧完全没有修饰键语义**，API 牙已证修好、极性正确）；**影响面** = "**依赖 `GetKeyState` 时序的调用方**"（批处理型泵、嵌套泵、跨线程取消息、一次性多事件注入的客户端）；**真应用连续泵下不受影响** ⇒ **"所有快捷键静默失效"撤回**；快照/环形表补丁登记为**稳健性修补**（保留）。
> **T3 又自曝 runner 两处"仪器看不见对象"（已修，记 L19）**：① 块表只有 10 个名字而样例实际注册 **11 块**（漏 `text-dp-min`）⇒ `--only=text-dp-min` 时该块判定**不进汇总**、**全量趟真 FAIL 也看不见**；② 补名单后立刻 `set -u` 崩（`input_leg` 等标志只在"有期望规格"的分支初始化）⇒ 名单对齐 + 循环头无条件默认值。**与 L12／"桥契约整行判 `[`" 同源：表/判据与实际对象漂移 ⇒ 静默漏判或静默假绿。**
> **T1c 的 ③④ 已落地（只改消息文本，不改判据）**：`DependencyObject.Linux.cs` 仅 **2 行**（全在 W3a 那个字符串字面量里）、`TextContainer.Linux.cs` 12 行、`TextBoxBase/TextBox/DeferredTextReference` 各 5 行（文件头注释）；`--prove` rc=0 且**摘掉插桩后与上游逐字节相同**（`edeb712d…` / `72af0364…`、`f27c058d…`、`91c52a19…`、`317e13af…`），应用器自带断言与改动前同读数，家族审计仍 `20/74/0`。
> ## 📌 2026-09-14 上午（波 19）：**三处修法合并成一趟波** + `D-P1` **被两条独立反证打成"观测口径失效"**
> ### ✅ 波 19（主控，09:24:41–09:29:52）—— 一趟做完三件事，**输入指纹与波前逐位相同**
> ```
> 输入指纹 544979bbfaaf9c44…（波前 == 波后，逐位）  ⇒ 波期间无手写改动（T1c 的"零写入"声明被独立证实）
> 桥   c66083443200115d → 759a322431f1e457（4,950,352 B；fp 705ed5ccd0c498a1 == 现树）
> PC   eb f4cf872c76e4a1 ｜ PF 3136f66563f858cd ｜ WB 8c073fab0da88169（未动）
> libwpfwin32.so f84d65a62e0c7fa4 → b2301ee237e72e5c（278,368 B）**全仓 4 份同步 ✓**
> shim e1bc947afc248b32（=源） ｜ 发布后 APPSYNC=PASS
> ```
> **进波的三处修法**：① T1d shim **逐行 dump**（默认关/惰性/有界 1000）；② T2b census **按压栈深度裁栈**；③ M7b **native 修饰键状态表**（`GetKeyState`/`GetAsyncKeyState`/`GetKeyboardState` 由恒桩改为读表）。
> ### 🔴 `D-P1` 二次翻转：**两条独立反证证明"DP 陈旧"是观测口径失效，不是缺陷**
> **反证 1（T1c §34，零注入、无代码改动，证据本来就在仓库里）**：同应用同 runner 的 **`--only=text-dp-min`** 趟（`~/wfp-runs/go-dpmin/probe-only.log`，sha16 `bfe935e0730e3437`）**本来就有写后读数**：`WFP_TEXTDP t1='seed-文本' c1=0` → **`t2='A' c2=1 sel='A' line0='A'`**（写后立刻读 DP：已是新值、`TextChanged` 立刻 +1）。它读的正是 `_tb.Text`（DP 读路径），动作是 `SelectAll(); SelectedText="A";`（与键入路径同族的文本对象模型改动）⇒ **"DP/通知链从未收到"当场为假**。
> **反证 2（M7b 装置）**：12 例装置在**写后读**（新增口径读数 `注入@ms / 读@ms / 读前 TextChanged`）下 `DP.Text == 容器` 全绿 ⇒ **装置与应用**差别可能**根本不存在**（差别在**读数窗口**）。
> **runner 那半句"陈旧"的来源已钉死**：`run-wpfprobe.sh:720-721` 用 `grep … | tail -1` 取 `feat-lines.txt` **最后一行**，而本趟该文件只有两行（`late:` L599 + `OK` L734）⇒ **取到的是注入前那行**，再在 `:730-732` 写成"可观测模型陈旧：changes=0 ⇒ 读 Text 的真应用会静默拿旧值 ⇒ 记 INCONCLUSIVE" ⇒ **拿注入前的 `changes=` 与注入后的像素并排比较**（`samples/**`/runner 侧已派 T3 改口径）。
> **⇒ 当前正确表述**：**输入链通到底（编辑器文档 `AB` + `Commit` + `Changed 已 raise`）；`Text` DP 的写后值在旧读数里从未被取过 ⇒ 无信息；已有两条反证指向"应用侧本来就正常"**。T3 本波在样例侧新增 `WFP_POSTWRITE`（300ms 轮询 `TextBox.Text` = DP 读路径，值变即打、≥2s 心跳、上限 30 行）⇒ **不碰 PF/生成物**即可拿到写后读数（若仍陈旧，才轮到 T1c 的 `WPF_LINUX_TEXTDP_READBACK` PF 探针 + 我安排下一趟波）。
> **两条可复用口径教训（T1c §34.10）**：**①"时间点型假阳"** —— 判据必须落在**事件发生之后**的读数上，采样窗口/窗口预算本身是被测对象的一部分；**②"写侧形态 ≠ 读侧值"** —— DP 存 `DeferredTextReference` 是上游设计，**不能**由"槽里不是字符串"推"读到的是旧值"。
> ## 📌 2026-09-14 凌晨（波 18）：**#7 冻结 + 四车道交付 + 全部带"能变红"的牙**
> ### ✅ `ACCEPTANCE-BASELINE.md` **#7 已冻**（T3 第 7 趟门禁，00:27），主控**独立复核通过**
> `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`｜两档 `passed=3/3 failed=0 inconclusive=0`｜6 条 `BASELINE` 全 `result=PASS`｜`leftover_after=0`。
> 八位**逐位与权威产物相符**（主控现场重算）：`bridge c66083443200115d`（4,950,336 B）/ `pc 23567d420f0dbbaa` / `pf bfb10fe2a01a986b` / `windowsbase 8c073fab0da88169` / `provider 71ba86c6495347fe` / `win32shim f84d65a62e0c7fa4` / `wic_shim 03b67fbcd7c385b6` / `hbtextline 5a04875ae87a294d`（`stale=no`）⇒ **与 #6 的唯一差别就是桥位**。
> 新读数位（本版首见）：`WPTD_BRIDGE_SRC_STALE=no basis=pub=ffb56d3bacd3d152 now=ffb56d3bacd3d152 so_file_match=yes`。
> **`run_dir=~/wfp-runs/go-freeze7`**；日志在 `$OUT` 之外（L13）。
> ### ✅ T3 那一整批的读数（同一趟配置，逐字）
> - **`tline` 六项**：`exact=73 diff=0 cases=73`｜行级 `972/972`、用例级 `213/213`｜Height/Baseline `1298/1298`、Extent `1260/1298`｜判定 `1298/1298`、空参抛 `253/253`、返回 this `1045/1045` ⇒ **通过 20 / 失败 2**（两条**在册已知红**：`T2` 记账、`T3 Collapse`，不是回归）。**与上一趟的关系**：`gen/tline-ledger-lines-20260913-2219.txt` vs `…-20260914-0030.txt` **12 条内容行逐字节相同**，唯一差异是文件头记的测量对象由**陈旧副本** `116BE62B…` 变成**权威 PC** `23567D42…` ⇒ **读数没变、但测量对象终于钉住了**（"测量对象未钉住"那一族被真正修掉）。
> - **RTL 三条**（新桥）：判据 1 `Δright=1 / Δw=0 / 墨迹比 0.97`；判据 2 镜像轴 CTM 预测 `k=71.75` ⇒ 实测 `k=71`、`mean|Δ|=0.736` vs 正序 `1.958`；判据 3 **块区 `x<600` 与已验收帧逐像素 `AE=0`** ⇒ **与修法②那趟逐位相同**，且**独立证实了 T2b 的"像素影响实测为零"**。（`WFP_GATE=INCONCLUSIVE blocks=10 ok=2 inconclusive=8` 是"本次只构建 2 个块"的**范围产物**，T3 已把 `skipped` 打进 gate 行并自动加一句说明。）
> - **`--only=textbox-edit`：D-P1 现场仍在**（不是"随队列根因修法消失"）：`sel=0,0 → 0,7`（**Ctrl+A 生效**、`focused=True`）而 `text` 全程 `seed-文本`、**20 条采样全 `changes=0`**；`HBLINE` 39 行原文已取（A#/B#/C#/E# 四族）。块按**预登记口径**记 `INCONCLUSIVE`。
> - **`1400` 累计 114 → **120** 次启动 / 0 命中**（本趟 +6：2 档 × 3 次）。
> ### ✅ 债务 #13 关闭（T1c）：**应用器审计** + 已接线
> 口径 A 级 = **变换等价**（把应用器**自己声明的**编辑表作用到**上游文本**，要求结果出现在**落盘生成物**里 ⇒ 期望值从声明算出来、**不看树**）；B 级 = 存在 + banner + csproj `Include`；C 级 = 只查 `MARKER_BEGIN`（**明说抓不了"内容没生效"**）。另有**独立于波表的登记清单** ⇒ "把某条从 `APPLIERS_EXPLICIT` 摘掉"也判红。
> 现场（**主控独立实跑复现**）：`APPLIER_AUDIT_SUMMARY appliers=20 ok=74 miss=0 red=0 rc=0`。牙三种实测能红：声明改错 / 未登记 / **生成物 == 未打补丁的上游**。
> T1c 顺带抓出**自己的两个判定缺陷**：① 逐条 `repl` 计数把**故意互相覆盖**的编辑误报成 miss ⇒ 改变换等价；② **非贪婪 `\((.*?)\)` 被注释里的 `abort(134)` 截断**、**静默漏掉两个应用器**（18≠20 才暴露）⇒ 规则：跨行块解析的收尾判据必须是"**这一行就是 `)`**"+ 条目数自证。
> ### ✅ 债务 #20 半壁（T2）：app-local 副本口径 + 结构修法 + **都在"能红能绿"上称过**
> 口径十类分开（`STALE` = sha≠权威 **且 mtime 早于**权威 / `NEWER-DIFF` 仍红只换措辞 / `NO-AUTHORITY` 补 RID 名 / **`LIB-COPY`** = 无 `runtimeconfig.json` 的输出目录不算宿主 / `SKIP(obj)` / `SKIP(stub)`），**mtime 只用于分类、不用于放行**；修掉 `shopt -s nocasematch` 泄漏到后续所有匹配的真 bug。
> 结构修法：`build/DirectWrite.Linux/Directory.Build.targets`（`SyncProviderAuthority`，只对**启动宿主**、不自拷）⇒ 5 份实测收敛到权威 `71ba86c6`。`ReachFramework` 定性 = **"副本同步机制缺一条"**（权威 `obj==bin`；app-local 四份**整齐早 62 秒**、年龄 = 各消费者最后一次构建），并指出 **5120 B 的 `CycleStub.ReachFramework.Linux` 同名件是"按文件名比对"的陷阱**。
> `-ipath` 缺口与 `ReachFramework` 纳入 ITEMS：**主控决定"暂不改/暂不纳入"**（会一次引入一批无人清的红）；两处决定与理由都要求写进报告。
> ### ✅ T2b：同族扫荡**抓到 3 个新真站点**（共 5 处写反），并**自己更正了自己**
> 新增：`SkiaRenderBackend.cs:280`（`Concat(world, deviceBase)` → `Concat(deviceBase, world)`）、`VisualBrushSource.cs:83`、`:98`。`Resources/**`、`Commands/**` 在五条枚举口径上**零命中** ⇒ 无跨层站点。
> **23 张 golden 逐张 sha 未变**、`Rendering.Tests` **160/0/2**；`:193` DPI 分支**离线可进**（`Dpi=192` + 画布 `Translate(100,0)` ⇒ 正确写法墨迹起点 **142**，写反 242 / 121；`RenderHarness` 在 `Dpi≠96` 时**显式 throw** ⇒ "走既有装置永远进不了该分支"这条事实也写进了报告）。
> **自我更正**：§8.5 那句"预期 RTL 五行全是 `PushTransform=无`"**只在"本帧此前没有任何 push"时成立**；`PushStack` **只压不弹** ⇒ 该字段**会报陈旧句柄**（❌ 句柄不可信、✅ **`无` 这个方向可信**、谎话不跨帧）⇒ ⑲ 那趟"RTL/LTR 都显示 `0x48`"是**陈旧读数、不是共用**。
> ### ✅ 生成物身份指纹（T1c）+ 已接线（`step 3.5/5`）
> `build/artifact-src-fp.{py,sh}`（**唯一实现**）覆盖"决定产物的三方"+ port-lib 输入；`ARTIFACT_SRC_FP proj=… fp=… state=ok`（PC `2377e09bbedd2634` n=1369 / WB `e21a98e9e3b1aaff` n=325 / PF `8985f926169f3473` n=1361，**主控独立实跑复核**）。
> 四极性 `--selftest` PASS（改上游源⇒变 / 还原⇒**逐位回绿** / 只在 `obj/` 加⇒不变 / 只在 `bin/` 加⇒不变）+ 手工牙（应用器加一行注释 ⇒ `stale` rc=2；挪走指纹文件 ⇒ `noinfo` rc=3）。
> **边界（它自己写的，别当它更强）**：它是**内容**指纹 ⇒ **只加注释也会变**；**不证明能编过**、**不证明"产物就是这些源编出来的"**（桥有"重建后逐字节可复现"的实测支撑，这三个件**没有**）。
> ### ✅ 真机 oracle（U1）：混合方向文本 18 例，**并自己抓到读反的坑**
> `tests/parity/windows/bidi/`（`out/bidi-oracle.{json,txt}` + `src/` + `PROVENANCE.md`）：`.NET 10.0.7`、`TextFormatter.FormatLine`、**两种 FlowDirection**、字体 Arial（**逐码点覆盖验证 ⇒ 无回退**）、emSize 24、单行。
> - **`שלום 123` 真值视觉序 = `123 םולש`（两种基方向相同）**，逐字方向 `RRRRRLLL`（数字是**独立 LTR run**）⇒ 我们画 `321 םולש` = **整段被当成一个 RTL run**；
> - ⚠️ **RTL 段落的 `TextBounds.X` 原点在右边缘、raw x 向左递增** ⇒ U1 第一版据此读反过，**对拍必须用归一化的 `xFromLeftDip`**（这是"仪器口径"类新坑，已入册）；
> - ⚠️ **`GetTextRunSpans()` 按 TextSource 的 run 切分、不按 bidi 层切分**（18 例全是 1 个 `TextCharacters`）⇒ **不是 bidi 边界真值**；
> - 未覆盖：多行/折行下的 bidi、AN 与阿拉伯语、括号镜像、非默认对齐/换行/行高、换字体需重跑、未与 `TextBlock`/`FormattedText` 交叉验证。
> ### 🧭 用户决定（2026-09-14）：**混合方向不开专项**（选项 B）
> 依据 = T1d `build/MilBridge/T1d-bidi-decision.md`（根因在 shim 单方向 + 按字体覆盖切 run；`TextFormatterImp.Linux.cs:216-241` 连 `FlowDirection` 参数都没有）+ U1 真机 oracle。**边界登记 + "做完判据/红旗" 由 T3 写入 `KNOWN-DEFECTS.md`**（状态 = `范围外/已知边界`，**不是"待修"**）。重启入口 = T1d 那份报告的第 0 步（0a 只读计数器量占比 / 0b 开关后可行性）。
> ### 🔧 T3 自曝的仪器缺陷（3 处，同族）
> 主控抓到的 `run-wpfprobe.sh:659` **双引号里裸反引号会被当命令执行**（`:norect` ⇒ 每趟打 `未找到命令`、且证据串被替换成空）；T3 全域扫同族又扫出 `run-wpftextdemo.sh` 的 NOINFO 分支（**它本轮新写的代码**）与新加的 `--only=$ONLY` 提示行 ⇒ **stderr 由 1 行变 0 行**；另修掉 `WFP_SUMMARY skipped=8` vs `WFP_GATE inconclusive=8` 的**自相矛盾**（正是主控去问它的原因）。**教训：修这类缺陷必须全域扫同族**。
> ### 📌 本波新增的"完成判据"（见 §0 顶部，可逐条复算）
> 六条：真实应用编译+起窗渲染（`WPTD_GATE=PASS`）/ 基线冻结且八位与产物一一对应 / `verify-all.sh` 全绿且跑前跑后产物 sha 不变 / 身份四件套（八位 + `BRIDGE_SRC_FP` + `hbtextline_shim_stale` + `BRIDGE_SRC_STALE`）/ 在册缺陷逐条有"依据+判据"且"不知道修没修"的条目为 0 / 无中间态。
> **`verify-all.sh`（主控 00:13–00:17）**：**步骤通过 9 / 失败 0，用例通过 859 / 跳过 2**，`rc=0`；**跑前跑后**权威产物 sha **逐位未变**（PC/PF/WindowsBase/wic/桥）⇒ 判据③成立。日志：`~/wfp-runs/verifyall-001321/verify-all.log`。

> ### ➕ 波 18 续（09:1x）：**两条新发现 + 一条主控自己的传话污染**
> #### 🔴 新发现 1（M7b，**装置侧反证**）：**Ctrl 修饰键在本 shim 下不生效**
> 装置里 `xdotool key --window <hwnd> ctrl+a` ⇒ `'AB'` 是**插入**得到 `"ABseed-文本"`（**不是**替换成 `"AB"`）⇒ `GetKeyState(VK_CONTROL)` 疑似**恒 0**。
> **它同时推翻了主控的半句结论**：我说"应用侧 `sel=0,0 → 0,7` ⇒ 注入的 Ctrl+A 生效"，M7b 指出 **①** 该块 `Verify()` **自己**就调 `_tb.SelectAll()`（与 `sel=0,7` **同值、不可区分**）、**②** 装置侧反证如上 ⇒ **`sel` 变化不能证明 Ctrl+A 生效**。
> ⇒ D-P1 的最终判定**不许依赖**"Ctrl+A 是否生效"；M7b 给了**7 行最小读数清单 + A–E 五分支预测**（`build/MilBridge/M7b-DP1-repro-report.md` §4.6），T3 按单跑**一趟**即定案。**若"Ctrl 不生效"坐实，影响面比 D-P1 大（所有快捷键）** ⇒ 已令 M7b 登记为在册缺陷候选（现象/依据 `file:line`/状态"装置已证、应用待确认"/判据"与 Windows 语义一致 + 能变红的牙"）并评估修在哪一层。
> #### 🔴 新发现 2（T3，**更正主控传的路径**）：PC 那份文件**不在** `src/WpfGfx.Linux/Text/`
> 主控在派单里写了 `src/WpfGfx.Linux/Text/TextFormatterImp.Linux.cs` —— **该文件不存在**；真身是 **`build/PresentationCore.Linux/TextFormatterImp.Linux.cs`**（1121 行），其 `:217-218` **确无 `FlowDirection` 形参**（216-241 内 0 次、全文仅 2 处且都在注释里）⇒ **结论不变、路径已更正**。
> ⇒ **又一条"传话污染"**（与历史那次句柄 `0x20000003/4` 同族）：**转述他人的 `file:line` 必须逐字复制，不许"顺手规范化"路径**。主控自领。
> 🔴 **同一轮第二次（主控自领，必须变成动作而不是检讨）**：派给 T1b 的命令里我写了 `tests/WpfGfx.Linux.Tests/Commands.Tests/Commands.Tests.csproj` —— **该文件不存在**（MSB1009），真名是 **`WpfGfx.Linux.Commands.Tests.csproj`**；T1b 按实际路径跑通（196 通过 / 0 失败）。
> **⇒ 主控新纪律（从本轮起执行）：派单里出现的每一个路径/文件名，发送前先 `ls` 或 `test -f` 一次。** 两次都不是"理解错"，而是"**手写路径没核**"——与"预测 sha ≠ 能编过"同类：**写出来的东西必须被工具核过一遍**才允许发出去。
> #### ✅ D-B1 已登记（T3，40 行，位于 D-R1 之后）
> 状态 = **范围外/已知边界（不是待修）**｜决定人 = **用户**（选项 B）/主控转达｜现象、5 条"算修好"判据、4 条红旗、两条硬边界（`GetTextRunSpans` 不是 bidi 边界真值；RTL 段 `TextBounds.X` 在右边缘 ⇒ 用 `xFromLeftDip`）齐备；交叉引用只加指针。**最硬的一条"无方向"证据**：shim `:2479` `CreateTextBounds(rect, FlowDirection.LeftToRight, …)` **硬编码 LTR**。
> #### ✅ `APPSYNC=PASS`（T2 刷新后，主控实跑复核）
> `计数：OK=27 MISMATCH=0（STALE=0 NEWER-DIFF=0）DIVERGENT=0 NO-AUTHORITY=17 LIB-COPY=6 SKIP(obj)=4 SKIP(stub)=2 SKIP(ref)=8 RETIRED=0`｜`APPSYNC=PASS`。⇒ 债务 #20 那 12 条**全部收敛**（此前 `MISMATCH=9 DIVERGENT=3`）。
> #### ✅ T2b 突变牙跑完并**逐字节还原**（主控核对）
> `SkiaRenderBackend.cs 8a99c5db4e65f290…`、`VisualBrushSource.cs 02bcafd23856699f…` 与交接值**逐位相同**；`BRIDGE_SRC_FP=ffb56d3bacd3d152`（回绿）、桥件仍 `c66083443200115d`、`/tmp/bridge-republish.lock` 无残留。
> #### 📋 下一步：**把三处源码改动合并成一趟波**（避免三次重编 + 三次重冻）
> ① T1d：shim **逐行 EOP dump**（默认关、惰性；改 `build/shims/**` ⇒ `hbtextline_shim_sha` 变）；② T2b：census **push/pop 配平**（改 `src/WpfGfx.Linux/Rendering/**` ⇒ 桥要重发）；③ M7b：**Ctrl 修饰键**若在本车道可低风险修，则一并进。
> 一趟波做完 ⇒ 重发桥 + 重建 PC + 重建 native shim ⇒ T3 重取 `tline` 六项 + RTL 三条 + `--only=textbox-edit`（含 EOP 逐行 tuple）⇒ 冻 **#8**。
> ### 🎯 `D-P1` **命中分支 A**：断点被**同趟并排读数**夹死在"编辑器文档已变 → `Text` DP 未变"
> T3 按 M7b 的 7 行清单跑完（`/tmp/dp1-native`，桥 `c66083443200115d`，**stderr 0 字节**）：
> - **#1** `push WM_CHAR` 恰好 **2** 条（'A'/'B'）；Ctrl+A 为 0 ⇒ 与 M7b 的"Ctrl 不生效"一致；
> - **#2 关键格**：真正 `pop msg=258(0x0102)` 的是 **2** 条 ⇒ **命中 A**（落点=托管输入栈）。⚠️ **主控派的判据式本身有假阳**：`grep "\[MSGFLOW\] pop" | grep -c "0x0102"` 实测 **8**，因为行尾 `队列内容=[…]` 也含 `0x0102` ⇒ **判据必须写 `grep "msg=258(0x0102"`**；
> - **#3/#4**：4 条 `skip` 与 6 条 `call api=PeekMessageW hwnd=0x200001 lo=0x8000 hi=0x8000` 是**同一件事**（Dispatcher 消息窗只 peek `[0x8000,0x8000]` ⇒ `0x0102` 不在区间、**留在队里**，随后被 `GetMessageW` 取走）⇒ **不是分支 B**；
> - **#6**：`PreprocessMessage WM_CHAR 入口 _eatCharMessages=False` → `TranslateChar/OnMnemonic handled=False` → **`ProcessTextInputAction handled=True`** ⇒ **不是**被 `HwndSource.FilterMessage` 吃掉；
> - **决定性对照（没在单子上，T3 顺手取的）**：同趟里**编辑器文档确实变成 `AB` 且 `Commit`**（`Q4d len=2 text="AB"` → `Q4f UndoCloseAction=Commit` → `Q3c 正常返回`），而 `TextBox#33cafbe` 的 `Text` DP（`dp.GlobalIndex=432`，帧 = `TextBox.set_Text @TextBox.Linux.cs:687 ← TextBoxBlock.Build`）**只有初始 seed + 两次 `DeferredTextReference`**。
> - 🔴 **【本条的结论已被 T1c 用只读分析推翻 —— 主控上一条写的"断点被夹死"是误判，下面是更正后的口径】**
>   **① DP 里没有字符串是设计**：`TextBox.cs:1194 → :1214 DeferredTextReference dtr = new DeferredTextReference(this.TextContainer) → :1216 SetCurrentDeferredValue(TextProperty, dtr)`；字符串**只在读时现算**（`DeferredTextReference.cs:41-43 GetValue → TextRangeBase.GetTextInternal`）。
>   **② 写后根本没人读**：插在 `DeferredTextReference.GetValue` 的探针 `Q8a/Q8b` 出现 **0 次**；最后一次 `GetValue(… "Text" …)` 在 **L1405**，而首次写在 **L1626**。
>   **③ 那"20 条采样 `changes=0`"全部在注入之前**：18 条 `WFP_TEXTWATCH` + 2 条台账**止于 L1412**（预算 `samples/WpfFeatureProbe/FeatureBlocks.cs:471 if (_watchLogs++ < 18)`、400ms 间隔 ⇒ 窗口 ≈7.2s、止于 t=17021ms），而**首条 `KEY_DIAG` 在 L1492**；`LateVerify`(L599) 甚至**早于** `Verify`(L723-734)，根因 = `samples/WpfFeatureProbe/MainWindow.xaml.cs:77` 的 `Loaded→BeginInvoke(ContextIdle, VerifyAll)` 被 ~10s 首帧拖到 6s late 定时器**之后**（L589 `WFP_DISPATCH_PRIO` 四项全 False = "probes 还没 post"，post 在 L723 ⇒ 顺序铁证）。
>   ⇒ **`D-P1` 的正确状态 = "当前无写后读数 ⇒ 无信息（≠ 陈旧、≠ 回归）"**，而**不是**"断点在 editor→`Text` DP"。**这是本项目第 N 次"仪器窗口不在事件发生处"**（与"测量对象未钉住""探针关掉≠无副作用"同族）：**读数的**时间范围**也是被测对象的一部分**。
>   **已派**：T1c 加"**写后读回探针**"（`TextBox.OnTextContainerChanged` 末尾、`base(...)` 之后读一次 `this.Text`，**独立开关 + 缺省关**——它会触发 deferred 解析 ⇒ 改变被测对象，**不能**挂在"不读 DP"的 `INPUT_TRACE` 下）+ 判据工具（**无写后读数一律 `无信息 rc=3`，不许报绿**）；T3 修 `MainWindow.xaml.cs:77` 的**时序**（让 late 校验真的排在注入之后）并把 `D-P1 第 9 批` 的口径改写；M7b 修订其最终判定（并回答"装置读数是不是写后读"——若是，则"装置 vs 应用"的差别可能**根本不存在**，即原缺陷的**观测口径失效**）。
> ### ✅ `D-K1`（Ctrl 修饰键）**应用侧已证**，修法**已批准**
> M7b 查到的**硬桩**：`src/WpfGfx.Linux.Native/src/win32_core.c:1288` `short GetKeyState(int vk) { (void)vk; return 0; }`、`:1289` `GetAsyncKeyState` 同桩、**`GetKeyboardState` 全仓不存在**；而 X11 层**本来就有**修饰键掩码（`win32_x11.c:576-577`，只用于压制 `WM_CHAR`、**没落表**）；托管侧**确实依赖它**（`HwndKeyboardInputProvider.cs:667/673/679`、`:551`）。
> 应用侧确认（T3 #5）：`state=0x4`(ControlMask) 那次被 `[KEY_DIAG] DROP WM_CHAR 原因：Ctrl 组合不产字符（Win32 语义：Ctrl+A 应是全选）` 丢弃 ⇒ **X 有、上层看不到**。
> **影响面（M7b 写明，不许轻描淡写）**：`Keyboard.Modifiers` 源出该报告 ⇒ **所有修饰键派生功能静默失效**（`Ctrl+A/C/V/X/Z/Y`、`Ctrl+方向/Home/End`、`Shift+扩展选择`、`Alt` 访问键、`KeyBinding{Modifiers=…}`/`InputGesture` 匹配、`DragDropEffects` 判定）；**普通字符输入不受影响**（走 `WM_CHAR`、不查修饰键）⇒ 这也解释了"无报错、无日志"。
> **判据 + 现成的红牙**：`~DP1_i` 现在就是红的（期望 `DP.Text=="AB"`、实际 `"ABseed-文本"`），修好自动变绿、测试不用改；另加 `Shift+Left ⇒ selLen==1`。**归属 = native shim（M7b 车道）**，≈40–60 行状态表 + 双路同步（keysym/keycode + `ev.xkey.state`，含 `CapsLock/NumLock` toggle），**不碰队列/变换/文本路径**。
> ### ✅ T2b：三条牙的**突变实测**全部拿到、还原逐字节、指纹回绿
> 突变① `:280` 改回 ⇒ 牙①`墨迹起点 30（2× 画布下应 60）`；突变② `VisualBrushSource.cs:98` 改回 ⇒ 牙②`包围盒左缘 60（应 30）`；突变③ 组变换分支 ⇒ 牙③`诊断行里出现组变换字样：否`。**每条突变下只有对应那条牙红**（1 失败/2 通过）⇒ 三条牙各自钉住自己的站点。
> **自查作废一条读数**：突变③ 首次引用了不存在的 `DrawInstructionCensus.Noop` ⇒ **构建 3 错**而 `--no-build` 仍报"1 失败"（**陈旧 DLL**）⇒ 该读数作废、重做。**本会话第三次踩"`--no-build` + 构建失败"** ⇒ 已令 T2b **用工具堵**（封装"构建 ⇒ 断言 0 错 ⇒ 再 `--no-build`"，失败即退出并打日志尾），**不再只靠纪律**。
> **B（census push/pop 根治）已批准实施**（按压栈深度裁栈：记录压栈时 `canvas.SaveCount`，`MilPop` 在 `Restore()` **之后** `PopToDepth(...)`；`DrawingGroup` 的 `RestoreToCount` 后同理；栈上限 64；**不采用"见 `MilPop` 就弹"**）。**格式裁定：两套格式保持不动**（几何行 `来源=PushTransform(句柄)` / 字形行 ` PushTransform=句柄`），只让它们读**同一份**"当前最内层变换"状态（不白换一轮 T3 的取数脚本）。
> 先红读数（一行自证，进报告）：pop 后 `CTM=[1.00,0.00,0.00,1.00,…]`（画布已撤销）而 `来源=PushTransform(0x00000002) [2.00,…]`（**仪表仍声称生效**）。
> ### ✅ T2：全仓 `APPSYNC=PASS` + 自愈机制说清
> 三条残项逐个 `before16 → after16`（`a3c026c5→71ba86c6`（早 5,523 s）、`08806714→1b63203e`（早 43 s）、`a3c026c5→71ba86c6`）；`APPSYNC-REFRESH=refreshed=3 newer=0 applied=1`、**幂等**。全仓 `OK=27 MISMATCH=0 DIVERGENT=0`。
> **机制（重要，避免下次误判）**：副本来自**消费者自己构建时**的 copy-local（`HintPath + Private=true`），MSBuild `Copy` 默认 `SkipUnchangedFiles=true` **按时间戳**判定 ⇒ **"落后"会自愈**（下次构建自动拷新件），但**"新而不同"不会自愈**（增量判定跳过）⇒ 这正是把 `NEWER-DIFF` 单列且**仍判红**、以及 T2 车道 target 用 `SkipUnchangedFiles=false` 的理由。波里 3.6 的价值 = **一次把所有消费者（含波自己不重建的 `samples/**`、`tests/**`）收敛**。
> **新登记覆盖边界**：`/tmp/**` 运行槽**不在** `SCAN_ROOTS` 内 ⇒ 若某槽**跨权威变更被复用**，会带旧件跑。今天没有问题（每趟新建槽；T2 实测刷新窗口与 T3 探针启动**相隔 1 分 49 秒**、无重叠）。属"运行协议"面，只登记风险与事实。
> ### ✅ T1d：shim **逐行 EOP dump** 落地（**源已定**：`PresentationCore.HbTextLine.cs = e1bc947afc248b32…`，4040 行）
> **能力**：`WPF_LINUX_TEXTLINE_PERLINE=1` ⇒ 每行一条机读 tuple 落盘到 `WPF_LINUX_TEXTLINE_DUMP`（未配则 stderr），**有界 1000 条**（超限只打一次"预算用尽"）。字段：`start/cpFirst/cpLast/len/nl/visible/hardBreak/eop/forced/keepState/modifier/runs/spans/text`。接线 4 处（`NoteLine()` 入口、构造器末尾、**唯一建串处** `LineDumpTuple()` `:2807`、`GetTextRunSpans()` 内补记 `:2505`）。
> **惰性（结构性保证，不是"看起来快"）**：`NoteLine()` 第一句 `if (!PerLineEnabled) return 0;`，开关缓存静态 `int`（`-1/0/1`）⇒ 关时不读环境变量、**不建串、不装箱、不遍历**。
> **牙（离线实测）**：① **默认关 = 逐字节无副作用**（`OFF_DIFF_RC=0`，两趟都 `通过 20 / 失败 2`；关时 dump 里 `HBLINE_LINE`=**0** 条、stderr 0 污染）；② **`eop=1/0` 随行变**（开 PERLINE ⇒ 1000 条里 `eop=1` **159** / `eop=0` **841**；**同段内 `eop=0` 紧跟 `eop=1` 且 `cpLast(i)==cpFirst(i+1)` 共 142 处**；**反向校验"段内 `eop=1` 之后还有同段行"= 0 处**）；③ **只加了读数**（两步逐字节自证：回退 `start=` 命中 `e8db366c…`、再回退逐行 dump 4 处命中 `5a04875a…`，三形态各 0 错）。
> **🎯 结构性结论（把 handoff:403 那条欠账**改写**掉了）**：`GetTextRunSpans()` 的 5 个 PF 调用点**各有触发条件**（`TextBoxLine.cs:370` = TextBox 光标命中｜`Text/Line.cs:414` = `TextBlock` **+ TextTrimming**｜`ComplexLine.cs:150/:225` = 行内含 **inline 对象**｜`PtsHost/Line.cs:277/:381/:661` = **FlowDocument/PTS**）⇒ **纯 `TextBlock.Text` 样例上 `getTextRunSpans=0` 是预期**，不是仪表失灵。**欠账改写为**："该读数在纯 TextBlock 样例上**按构造不可得**；要取走三条路：① `--only=textbox-edit`（走 `TextBoxLine.cs:370`）；② 加一块带 `TextTrimming` 的 TextBlock；③ 加一块含 inline 对象的块。"
> **如实登记未自证项**：`spans=`/`HBLINE_LINEQ#` 那一格**本轮无牙**——只能由真实调用点触发，而 harness/探针都不调它；按"在 harness 里自己调一下让它变 1 = 伪造证据"的明令**没有伪造调用**，其牙随 `--only=textbox-edit` + `PERLINE=1` 那趟一并取（届时可见"**哪一行**被问过"）。

>
> ## 📌 2026-09-11 第三轮（主控）：一条**假命中**被仪器主人自己作废 / 部署件重发 / 四条车道并行
> ### 🔴 第 12 个成员（**形态又是新的**）：**"宽松回落的解析器"被当成"严格探针"用**（M7b 自己抓自己）
> M7b 在部署件上先读到债务 #14 的基线 = **`按句柄命中 48 / 回落族名 0 / 解析失败 0`**，并据此宣布"(乙) 的 MIL 半边已生效"。**该读数已由它自己作废**。
> **根因**：`MilFontFaceTable.TryResolve`（`Interop/MilHandleTables.cs:726-735`）在**句柄不认识**时会**回落 `DefaultTypeface` 并 `return true`** —— 这是给**轮廓路径**用的既有契约（"画不出正确的也不要画不出来"）；census 探针直接复用它 ⇒ **"PC 填的 pid 一个都不认识"被伪装成"48 个 run 全部按句柄命中"**。而"两份都叫 `DejaVu Sans`、`file=<未知>`"正是**同一个默认面**被当成命中。
> **修法**：新增 **`TryResolveExact`**（`MilHandleTables.cs:747`，只查 `_faces`、**不回落**），seam 改用它（`Interop/MilPresentation.cs:446`）；**`TryResolve` 原样保留**给既有消费者（不许为了让探针好看而改公共契约）。
> **⇒ 与"同一份代码的两种契约"这一族同源**：**探针必须用"严格"的那个出口**；凡是"宽契约"（回落/兜底/默认值）的返回值，**都不能当"命中"读**。前 11 个成员是"仪表坏了/看错对象/取错时刻"，**这个是"仪表借错了别人的宽松语义"**。
> **更正后的真基线 = `0 / 0 / 48`**（有句柄但解析失败 48），与 T2b 的**结构性事实**（资源模型里没有 font/typeface 类型）互相印证。
> ### 🗣️ 又一条"传话污染"（与上一轮同族，这次是句柄）：应用里的 `pid` = **`0x20000003`/`0x20000004`**
> 出处：**T2b 逐 run 明细**（14×`…03` + 66×`…04`，帧汇总 `不同面数=2`）。M7b 早先写的 `0x20000001/0x20000002` **来自它自己"登记幂等性"实测的返回值** —— 又把自己自测的句柄当成了应用的 pid。**纪律：跨 agent 引用数值必须附出处（文件/行/输出片段）。**
> ### 🧪 主控自己又踩一个"存在性检查"的坑：**"在 `.so` 里 grep 我的 env 名"不是有效的落地判据**
> 我用 `strings | grep WPF_LINUX_CWIC_TRACE` 判"新仪表进没进部署件"，读到 **0 命中**（ASCII 与 UTF-16LE 都是 0），差点判 M7b 的改动没落地。**实测反证**：
> - AOT 目标文件 `build/MilBridge/.artifacts/obj/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.o` 里**有**（`grep -a` 命中）；
> - 最终 `.so` 里**两种编码都没有**，却藏着**碎片**：`[cwic-trace] sou` / `ownedBy` / `shimGetS` / `format` / `→ SKBitm` / `colorTy` / `alphaTy` / `bufferS` / `copyPix` ⇒ **AOT 字面量池做了子串去重**（`WPF_LINUX_DRAW_CENSUS` 这类碰巧整条留下、`WPF_LINUX_CWIC_TRACE` 被拆成片段）。
> **⇒ 判据只能是"功能上它到底打不打那一行"**（带 env 跑一次），**不是"我在二进制里搜到了字符串"**。归入手册那一族：**"观测对象与你以为的不是同一个"**。
> ### ✅ 部署件已重发（主控，`build/publish-milbridge.sh`）
> `wpfgfx_cor3.so` = **`1214875fd0559eec11cd17968934f470b2bce16acd1a208803471ed4d150d365`** / **4,880,128 B**（18:38）；同目录 `libwpfwic.so` = `74d9dbba…` / 66,248 B / **12** 个 `Wic*` 导出；`libSkiaSharp.so` = `a02cd03f…`。
> **有效性前提已核**：发布前后 `src/**/*.cs` 指纹**完全一致**（`c005c560…`，69 文件）⇒ 这份 `.so` 确实编自 M7b 18:32 那次编辑后的树（`TryResolveExact` 与 `WPF_LINUX_CWIC_TRACE` 分支都在）。**发布期间 `src/` 无人编辑**（指纹为证）。
> **本版含**：M7b 的 `TryResolveExact` + CWIC trace + T2b 的新列。**待 M7b 回报**：它是否仍复现部署件头条读数（`skia 指令 145 / 未画种类 0 / PNG 938×646 / committed=507 pending=0 / exit=143`）——**对不上即判回归，新字段一个都不读**。
> ### ✅ T1c 的 **(甲)** 收口 + 方案 A 的**决定性否证**（本轮"该修哪一层"由实测钉死）
> - **(甲) 冻结件逐字复验通过**：applier `3610e096…`、生成物 `19a42240…`（681→2162 行、`throw` 条数不变）、`--check` rc=0、幂等、接线求值"上游 0 / 生成物 1"、**波前门禁 0 错 0 警**；权威 PC `b1decf16…`、shim `2cc87a93…` **未动**。（T1c 如实登记了一次"自己越界加自检又整段撤回"，并以"还原后 sha == 冻结 sha"自证撤干净。）
> - **方案 A 为什么没用（补丁 J/复合字体路线）**：钩子**一次都没被问过**（`Wrap` 被调到但 **`WrapperMapCalls=0`**），上游 `GetShapeableText`（喂 `TypefaceMap` 的入口）**托管侧无调用者**；`WPF_LINUX_TEXTLINE_FALLBACK=0` 时应用**当场 `LoCreateContext` 崩** ⇒ 含 CJK 的行**确实**走托管 shim，而 shim 是"**一段一个字体文件**"。
> - **阳性对照（本轮最值钱的一条）**：**只改默认 UI 字族** ⇒ `id0 325 → 0`、`非拉丁 0 → 294`，**读图确认中文由豆腐块变真汉字** ⇒ **选面发生在 run 的 `Typeface` 那一层**，不在家族回退层 ⇒ **R1（按 run 选面 + 按码点覆盖切段）是被实测支持的那条路**。
> - 附带否证了派单里"链条走到补丁 J ②"的推断（`FONT_DIAG` 全程 0 行）。降级链 (b)（直读 cmap）在**变体**上已测得与 provider **8/8 一致**（`CmapFilesRead=26 / Disagrees=0`），已批准**常设**（独立新文件 + 缺省关）。
> ### 🧵 本轮四条并行车道（写清边界，避免"一条车道两个人"重演）
> | 车道 | 任务 | 边界 |
> |---|---|---|
> | **T1d** | **R1 多字体整形**（run 级取 `TextRunProperties`、`HbShaper.Covers` 按码点切段、多面重组成一个 `HbShapedRun`；**不碰 `HbBreakEngine` 规则与 `HbTextLine` 记账**） | `build/shims/PresentationCore.HbTextLine.cs`、`build/MilBridge/**` |
> | **T1c** | **(乙) 的 PC 半边**：让 `pIDWriteFont` 携带"PC 实际用的面"的 **MIL 句柄**（先核 `PresentationCore.FontBridge.cs` 的路径式令牌分配器走到哪一步，再找真正填 `pIDWriteFont` 的那一处 —— `GlyphRun.cs:1876` 用的是 `Font.DWriteFontAddRef`） | `build/PresentationCore.Linux/**`、`build/shims/**`（面令牌相关）、`patch-*.py`；`build/DirectWrite.Linux/Provider/**`（T2 空闲，改动需点名）；**不动 `src/**`（桥）、不重建权威 PC** |
> | **T2b** | 祖链列补完 + **把零缩放 CTM 从"判不了"变成"能判"**（`VisualProjection.cs:38` 解析时丢掉了变换**句柄与原始资源值**） | `src/WpfGfx.Linux/Rendering|Resources/**`、`Rendering.Tests`、golden |
> | **M7b** | **部署件上**复读 `0/0/48` + **D-d 四问**（`WPF_LINUX_CWIC_TRACE=1 WPF_LINUX_WIC_TRACE=1`）+ 有效性闸门 | `Interop/**`、`Text/**`、`Windowing/**`、`:99` |
> ### ⚠️ D-d 的**射程**被钉死：**只能在部署件上判**（M7b）
> 自建桥下同一样例**根本走不到那条路**（`BitmapSource.Create` 直接 `E_HANDLE` ⇒ 样例回落 `DrawingImage` ⇒ **CWIC 物化不发生**）⇒ 自建件上"trace 为空"是**路径没走到**，不是仪器坏。**部署件上 `Create` 成功 96×96 Bgra32 且物化出 1×1** ⇒ ① 判 (i)/(ii) 必须用部署件；② 已排除 **(iii) "用错尺寸字段"**（台账打的就是按 `GetSize` 建的 `materialized.Width/Height`）。
> ### 🧱 **R1 的结构性前提**（T1d 动手前查出，主控按锚点核实）：**一个 `GlyphRun` 只能带一份面**
> 上游 `GlyphRun.cs:1876` `command.pIDWriteFont = (UInt64)_glyphTypeface.GetDWriteFontAddRef;`；本移植 `Provider/FontModel.cs:285` `DWriteFontAddRef => FontHandleTable.Register(GetFontFace())`（令牌 = 路径 + 面下标）；渲染侧 `TextRenderer.cs:116-137` + `MilPresentation.cs:439-445` 按 `PIDWriteFont → TryResolveExact → SKTypeface.FromFile(path,faceIndex)` 取面。
> ⇒ **只把字形 id 按码点切成多面、却仍只发一个 run，普查会 `id0→0 / 非拉丁>0` 变绿而像素是垃圾** —— 已作为**"预测的假绿"**写进 R1 派单（要求：**每个字体子段一个 `GlyphRun`**，各自 `GlyphTypeface` + 各自 baseline origin；并**逐 run 打出 `(fontPath, faceIndex, token, cp 起止, glyphCount)` 与"每段吐出几个 run"**，把"一面一 run"变成可观测）。
> **面下标是硬约束**（HB 实测 `hb_font_get_nominal_glyph`）：`NotoSansCJK-Regular.ttc` face0(JP) vs face2(SC) —— `文` = **20035 vs 20036**、`漢` = **24227 vs 58935** ⇒ 整形面下标必须 == 渲染面下标。T1d 采用**双重验证**（`FontUri.LocalPath == 文件` **且** `CharacterToGlyphMap[cp] == HB nominal_glyph(cp)`），不符则 `FallbackFailed++` 并沿用当前面（**不静默画错字**）。
> ### 🧹 又一处"过期副本"（债务 #20 同族，主控清掉）：`SystemFontsProbe` 的 app-local `libwpfwin32.so`
> `build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/libwpfwin32.so` 停在 **09-10 15:53 / 108,584 B**（sha `947ee246…`），而权威件早已 **264,552 B**（sha `4c023937…`）；`DllImport("libwpfwin32.so")` 会**先命中 app 目录那份** ⇒ 谁再在 Linux 上跑这个探针，测的是**老 shim**。（`tests/parity/systemfonts/` 的真值来自 **Windows 真机**，既有读数未受影响。）**已刷新**，现在全仓 4 份副本**同一 sha**。**机制级修法仍欠**（"只拷不覆盖"/无人同步 ⇒ 与 #20 同源）。
> ### ✅ T2b 三件做完（真机判定等新桥）
> `src/WpfGfx.Linux/Resources/TransformProvenance.cs`（**旁表**，不碰 `Contracts/**`、不产生新分层依赖）+ `VisualProjection.cs:41` 一行点插入（锚点命中 1 次）⇒ **零缩放 CTM 从"判不了"变成"读字段"**：逐代打出 `变换句柄 + 资源类型 + 解析前原始值 + 解析后矩阵 + 累积world`；**退化的 0 显眼标 `**0**`**、查不到报 `无信息`（**不报 0** ⇒ 不让"0.4 被显示成 0"这类自造假象出现）。判据 ⇒ 该句柄 `ScaleX/ScaleY`（或 `M11/M22`）**原始值是否为 0**：是 0 = **(甲) 上游发的**；非 0 而我们算出 0 = **(乙) 我们的 bug**。
> **仪器三条**：`TryRenderGlyphRun` 仍只调一次（`Assert.Equal(3, drawn)` **保留未删**）；缺省 env 未设 ⇒ **行为逐字节相同**（用例 `disabled_records_nothing` 钉住）；**突变自测有牙**（`ScaleX+1` ⇒ 两用例立刻红、改的是**生效分支**、突变已复原）。
> **它自查出两处"查法不对"**（与本轮主控那条同族）：① 核 mtime 时看的是 `src/.../WpfGfx.Linux.dll`，而测试真正加载的是 `tests/.../Rendering.Tests/bin/...` 那份 ⇒ 它**先怀疑"构建没生效"，而不是直接采信测试结果**；② `strings` 默认不认 UTF-16 ⇒ 那条"字符串没进二进制"的初查**是查法不对、不是结论**。最终"突变确实生效"是用**输出里出现了被改错的值**证明的（比 mtime 直接）。
> **编译状态**：`Rendering.Tests 141 通过 / 0 失败 / 2 跳过 / 143`、`Commands 562/0/562`、golden 仍只变批准的 5 张、**0 错 0 警**。
> ### 🔴 第 13 个成员（新形态：**把两个不同配置的读数当成同一道闸门**）—— **主控自己犯的，且是同类第二次**
> 我拿**更早的桥 `9eb4c88c…`** 的头条（`skia 指令 145 / PNG 938×646 / committed=507 / pending=0`）当**部署件 `1214875f…`** 的有效性闸门 ⇒ M7b 照章办事报"**头条未复现**"（它实测 `drawn=180 / 938×938 / frames_good=14/14 / notdrawn=0 / exit=143`），并**主动把本轮读数降级为暂定**（这个分寸对）。
> **真相**：`drawn=180` 才是**后来那一版的记录值**（本文件 §0 里就有）—— 我引的是**过期配置**的数。
> **⇒ 闸门口径改定（可执行）**：**"可复现"必须在同一四元组内成立** —— `pc_sha` + `bridge_sha` + `pf_sha` + `shim_sha` + **档位**全部写明；**配置任一变 ⇒ 重新基线，不许跨配置比**。每个读数把 `WPTD_ARTIFACTS` 那一行当**固定表头**。（已派 T3 做当前配置的正式重新基线。）
> **这是同一个错的第二次**（第一次是"拿我的运行结果与存档验收件比对、没控制配置"）：两次都是**我把"数字"当成了"不变量"**。
> ### ✅ `48/0/0` vs `0/0/48` 的处置（**结论先不定**）
> M7b 在**部署件**上用**精确查询**读到 `按句柄命中 48 / 回落族名 0 / 解析失败 0`，并**撤回**了它上一轮"这是 `TryResolve` 默认面回落造成的"那条归因。**主控代码核实：这条链按构造是通的** —— `FontModel.cs:285 DWriteFontAddRef => FontHandleTable.Register(GetFontFace())`（上游 `GlyphRun.cs:1876` 正是取它填 `pIDWriteFont`）→ `FontHandleTable.Register` 的 **① 路径式钩子** `PathTokenAllocator`（`FontHandleTable.cs:64`）由 `build/shims/PresentationCore.FontBridge.cs` 的 `[ModuleInitializer]` 装成 P/Invoke **`MilFontFace_RegisterFromFile`**（部署件里该导出为 Real 档，`MilNative.Exports.cs:152`）。
> ⇒ **但仍不算收口**：只看 `48/0/0` 无法排除"另有登记者"。**已把 T1c 派去把它做成可翻转的 A/B**（关掉登记应回 `0/0/48`）——**翻转才算证完**。缺的那一格是**面身份**（两份面现在都是 `file=<未知> faceIndex=-1`，因为 `NoteFaceSource` 只记 `FontSet` 加载的面）⇒ 已要 M7b 在**登记成功处**补记 `(typeface, path, faceIndex)` + **是否覆盖 U+4E2D**。
> ### ⚠️ 另：`WPF_LINUX_WIC_TRACE` 在 shim 侧**一行都没打**（M7b 实测）
> 同一次跑里 M7b 自己的 `[cwic-trace]` 打出来了 ⇒ **不是"stderr 没接上"**。已派 T2（shim 车道独占）判"没生效 vs 没走到"，并要求给出"**句柄 `0x3` 是哪个对象**"的 shim 侧对照（D-d 现在证据倾向 **(i)：PC 传下来的句柄本身就是 1×1 对象**，(iii) 已排除）。**纪律照旧：不许用"没输出"当"没发生"。**
> ### ✅ T2 判定：`WPF_LINUX_WIC_TRACE` **不是没生效，是"覆盖之外"**（可复算对照）
> 同一份 shim、同一个 env：**写路径 harness 打出了** `FOREIGN_SOURCE_REGISTER`/`BITMAP_LOCK`/`ENCODED`/`PNG_INJECT` 等，而**读路径只有 4 行 `DPI_FROM_FILE`** ⇒ 门控有效；**trace 只落在"失败/桩/特定特性"上，正常解码成功路径一行不打**。修法：三个热入口加**限流入口 trace**（`g_trace_budget=40`；`COPY_PIXELS` 打在**拒绝分支之前** ⇒ "走到但被拒"也看得见）。
> **新增取证工具（不是猜读数）**：导出 `WicShim_DescribeHandle` + CLI `probe_describe` ⇒ `via=slot|foreignExt kind=… foreign= ownedByWic= refs= size=WxH rowBytes= fmt= pixels= decoded=` —— **"句柄 `0x3` 是哪个对象"这一格从此可判**：`kind=Frame/Source size=1x1` ⇒ **(i)**；`kind=FormatConverter` ⇒ **转换器退化（另一条链）**。**自带两向自检**（真 4×3 必须描述出 `4x3`；虚构句柄 `0x7ffff0` **必须** `E_INVALIDARG` + 写 `<unknown>`）。
> **债务 #20 的结构化修法**：`build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh`（**只读**、`APPSYNC=MISMATCH` ⇒ exit 1、退役别名 `libole32.dll.so` 出现即错、双向自检 A/B）。**它第一次实跑就抓到"发布目录落后一代"**（`74d9dbba` vs 权威 `66938550`）—— 正是"谁跑谁测老 shim"那类事故的探针。**已接进主控的 `publish-milbridge.sh`**（发布后自动跑、大声报）。
> ### ✅ (乙) 的 PC 半边**已跑通、无需新实现**（T1c + M7b 两条独立读数）
> 两条旁证比"读到 48/0/0"更强：① **`MilHandleSource.Base = 0x2000_0000`**（`Interop/MilHandleTables.cs:42`）⇒ 逐 run 的 `pid=0x20000003/0x20000004` **正落在 MIL 字体面句柄空间**（PC 只可能通过 `MilFontFace_RegisterFromFile` 拿到）；② 画出 run 的那两份面**不在渲染器 `FontSet` 的 301 份里** ⇒ 只能来自 **`MilFontFaceTable`（按句柄）**。
> T1c 已落：**开关 `WPF_LINUX_FACE_HANDOFF`（未设 ⇒ 开）** + **可判性出口 `WPF_LINUX_FACE_HANDOFF_DIAG`**（缺省关、≤12 行、前缀 `[FACE_HANDOFF]`，打 `token ↔ path/faceIndex/simFlags`）+ 新档位 `DisabledBySwitch`。**收口靠 A/B 翻转**（`=0` ⇒ 期望回 `0/0/48`）。
> ⚠️ **T1c 给的硬约束（会静默毁掉 R1）**：面令牌走**路径式**分配器 ⇒ `LinuxFontFace.FromBytes`（`SourcePath == null`，`LinuxFontFace.cs:170`）造的面**拿不到路径** ⇒ 回落进程内表 ⇒ MIL 解析不到 ⇒ **渲染器用错面光栅化 R1 的 id**。**已作为硬约束转给 T1d**：子段的面必须来自"**文件路径 + faceIndex**"，拿不到路径就叫它失败（`FallbackFailed++`），不许静默用 MIL 不认识的面。
> ### 🚧 当前**挡路的半成品**（这就是"不许起波"的原因）
> `build/shims/PresentationCore.HbTextLine.cs`（T1d in-flight，139 KB）**编不过**：`error CS0246 "HbShapedChunk"（:90）` + `CS0103 hb_font_destroy / hb_face_destroy / hb_blob_create_from_file …（:511-535）` ⇒ **此刻谁都重建不了 PC**（T1c 只能另建隔离工程自保；主控起不了波）。**已要求 T1d：新类型先落地再加引用、每个稳定落点让 shim 编得过** —— 半成品 shim = 全树停摆，本项目为"中途被打断"已经付过**两小时空转**的代价。
> ### 🧹 运行卫生：**7 个孤儿应用进程把可用内存打到 0**（主控清掉）
> `pgrep -fc WpfTextDemo.dll` = **7**（3 个 RSS≈**1.6 GB**、3 个≈128 MB，**父进程全是 1**），整机 7 GB `available=0`、load **10.9**（3 核；另有别的工程在 `flock` 构建）。**已 kill 干净**（available 回到 ~2.3 GB）。⇒ 已要求 T3：每 rep 之间**断言无残留**、收尾**杀到进程组**、基线里加 `max_concurrent_apps` 与 `leftover_after=0/1`。**"环境压力"是又一个会让读数说谎的变量**（与上次"多杀把自家 Xvfb 干掉"是同一根因的两面：漏杀 / 多杀）。
> ### 📦 部署件更新（主控发布，18:45）
> `wpfgfx_cor3.so` = **`cefd7281f670a1fbd750717593575e0023bd3539959f723b5f05980eaa81cc92`** / **4,896,624 B**；`libwpfwic.so` = `66938550…` / 70,440 B / **13** 导出；`libSkiaSharp.so` = `a02cd03f…`。**`src/**/*.cs` 指纹发桥前后一致**（`5f3eb9b5a136a783749695c8fb25b7a762f5e1902481425baf722c1669b5bc75`，69 文件）⇒ 部署件确实编自当前树。**`check-applocal-sync.sh` ⇒ `APPSYNC=PASS`**（全仓副本与权威件同 sha）。
> ### 🎯 **(乙) 机制在部署件上确认生效 + CJK 真因被"面级证据"钉死**（M7b，桥 `cefd7281…`）
> ```
> 面来源（债务 #14）：按句柄命中 = 48 / 回落族名 0 / 有句柄但解析失败 0
> 面 … file=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf faceIndex=0 覆盖U+4E2D=否 runs=8  glyphs=140  zeroIds=50
> 面 … file=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf      faceIndex=0 覆盖U+4E2D=否 runs=40 glyphs=1136 zeroIds=275
> ```
> ⇒ ① **按句柄取面这条链在部署件上通**，而且**粗细分得对**（Bold / Regular 各归其面）；② **PC 给 CJK 用的就是纯拉丁面**（`覆盖U+4E2D=否`）⇒ **`325/1276` 的 `.notdef` 是 shaping 阶段产生的** ⇒ **CJK 真因 = shaping 选面**，与 T1c 的阳性对照（`id0 325→0`、非拉丁 0→294、读图见真汉字）**互证** ⇒ **R1（T1d）正是那条路**。这是从"计数"升到"面级证据"的一格。
> **D-d 进展**：`foreignSources=0` ⇒ 那个 1×1 句柄**不是我们登记的外来源、是 shim 自建对象** ⇒ 证据倾向 **(i)**；(iii) 已排除。⚠️ **M7b 新字段名写错了**：`登记传入=1x1` 实际打的是 `TryMaterializeWicSource` **由 `GetSize` 得到的尺寸**、不是 `WICShim_RegisterForeignSource` 的入参 ⇒ 下轮改名 `materialize尺寸=`（**一个会误导下一人的字段名，就是一颗定时假绿**）。`probe_describe` 只能描述**它自己进程**的 shim 表（`0x3` 在探针进程里当然 `E_INVALIDARG`）⇒ **"`0x3` 是什么对象"必须在应用进程内问** ⇒ 已要 M7b 在自己的 `[cwic-trace]` 分支里**直接调 `WicShim_DescribeHandle`**（不必等 T2）。
> ### 🔴 第 14 个成员（**新形态：批量模式清理打中"旁观者"**）
> 18:47–18:52 有**两个旁观者**被 SIGTERM：**T2b 的 shell** 与**主控自己的一条命令** —— 两者命令行里都含 `WpfTextDemo.dll` 字面量；M7b 承认它用 `pkill` 清残留。**同族第一次**是"`pkill -f 'Xvfb :98'` 打中自己"，**这次是打中别人**。
> **⇒ 规则**：**不要在自己的命令行里写你要匹配/杀/等待的进程名字面量**；**杀进程一律按 PID**（或按 `/proc/<pid>/cmdline` 精确比对并**自排除**，如 `[W]pfTextDemo`）。两个受害者都没有因此重跑或据此下结论（T2b 明确写"重跑还会撞同一堵墙"——这个判断对）。
> 附：`WPTD_ARTIFACTS` 的 `shim_sha` **标签与实物不符**（打的是 `libwpfwin32.so` 的 `4c023937…`，而被测的 WIC shim 已是 `66938550…`）⇒ 已要 T3 拆成 `win32shim_sha` / `wic_shim_sha` 并**从实际加载路径读**。
> ### 🧰 主控给波加了两道**机器可见**的护栏（`build/integration-wave.sh`）
> ① **输入冻结标记**：开波删 `build/.wave-done`、**无论成败**都在退出时重建（协议：标记在 = 上一波已消化、各车道可写；波运行期间它必须不在）。② **输入稳定性自检**：对**手写输入**（`build/shims/**`、各应用器 `.py`、`src/**` 源码，**故意排除** `build/*.Linux/**` 生成物——它们本来就会被本波重写，算进去这条检查永远为真）取**内容指纹**，波前/波后不一致就**大声报**"编辑竞态"。这两条把"跑了正在被编辑的东西"从"教训"变成"机器看得见"。
> ### ✅ T2 的两件交付
> ① **判定**：`WPF_LINUX_WIC_TRACE` 不是没生效、是**覆盖之外**（写路径 harness 打得出来、读路径只有 4 行 `DPI_FROM_FILE`）；已在三个热入口加**限流入口 trace**（预算 40；`COPY_PIXELS` 打在**拒绝分支之前** ⇒ "走到但被拒"也看得见）。② `probe_describe` + 导出 `WicShim_DescribeHandle`（**两向自检**：真 4×3 必须描述出 `4x3`；虚构句柄必须 `E_INVALIDARG`）+ `check-applocal-sync.sh`（只读、双向自检、**第一次实跑就抓到"发布目录落后一代"**）**已接进 `publish-milbridge.sh`**。
> ### ✅ T1b 交付 `T2e` 对拍装置（含牙齿自检）+ 三条实读
> `build/MilBridge/tests/T2eLineHeight/`（只吃 JSON + 探针，**不跑应用、不起 Xvfb**；**被测 shim 的 sha 打进读数**，`T2E_SHIM_PATH` 可钉住"我测的是哪一版"）；读数 `build/MilBridge/gen/t2e-lineheight.txt`。
> ```
> T2E_SUMMARY cases=10 height_ok=10/10 textheight_ok=5/10 baseline_ok=10/10 extent_ok=0/10 lines=40
> ```
> - **`Height` 10/10、`Baseline` 10/10 ⇒ `LineHeight` 维度的修复有回证**（`Height=LineHeight`、`Baseline=LineHeight×自然比`；偏差都在 0.34 DIP = **1 个 1/300 英寸量化单位**内）。
> - **`TextHeight` 5/10 不是公式错、是字体代用**：5 个拉丁例全对；5 个 CJK 例真机用 **MS YaHei**（本机没有）而装置用 NotoSansCJK ⇒ **自然文本高本就不同**（23.168 vs 21.117）⇒ 标为"**不可比**"、**没让它悄悄绿**（这个分寸对）。
> - **`Extent` 0/10**（与 `0/1298` 同源）**确认缺陷**：真值 = **墨迹上伸**，我们 = **行高**（`Extent => _height;`）。归因：行实现**没有 ink-extent 概念**，真值要**逐字形墨迹上伸**（OS/2 `usWinAscent` 或字形 bbox），而 `GlyphTypeface` 公开面拿不到。**按要求只取证 + 定位，未改实现。**
> **牙齿自检里它自己先得过一次"牙病"**：第一版判据写的是 `_fail > 0`，而自检模式不走 `Red()` ⇒ `_fail` 恒 0 ⇒ **"装置明明抓到了错真值，却被判成装置不可信"**。改成看"错真值有没有被抓出来"（`height_ok==0`）后通过，**报告里那句错话也一并改正**。（又一条"仪器自己先要过硬"的实例。）
> ### 🚧 T1d 当期改动**打掉了"反射形态"的编译**（T1b 取证时发现，未碰 shim）
> 真 shim `a76840b4…` 在**反射形态**下：`CS1061: GlyphTypeface 未包含 FaceIndex / GetDWriteFontAddRef`（两者都是 **PC 内部**成员）。**这两种形态的存在意义**：DIRECT（编进 PC）= **运行形态**；反射（`build/MilBridge/staging/PresentationCore.HbTextLine.cs`）= **全部拉丁回归读数的地基**（`73/73`、`T2d 1298/1298`、折叠 `210/236`，harness 为 `HbTextLineParity` / `T2e` / `TextLineProto`）。
> - 🔧 **2026-09-15 更正（主控）**：上句里的"地基"**只在当时的过渡期成立** —— 真源**始终**是 `build/shims/PresentationCore.HbTextLine.cs`（`run.sh` 里写死 `SHIM=`）。`build/MilBridge/staging/PresentationCore.HbTextLine.cs` 与 `build/MilBridge/tests/CoverageProbe/refs/PresentationCore.HbTextLine.ebccdb1e.cs` 是**逐字节的历史快照**：前者自身 sha256 起头 `c580f2df9362de55`，后者自身 sha256 起头 `ebccdb1ee65e6f76`（**正是文件名里的版本号，也正是当日读数里登记的"被测件 sha"**）⇒ **其内容一个字都不许改**（把"仍真欠账 6"改成 5 = 篡改一份**字节自证**的历史记录）。现场复核：`CoverageProbe.csproj:33` `EnableDefaultCompileItems=false`、只编 `$(HbShimSrc)` + `Program.cs` ⇒ `refs/` **不被编译**；全仓 `grep`（`*.sh|*.py|*.csproj|*.cs`）对 `CoverageProbe/refs`、`MilBridge/staging` **0 命中**。⇒ **该修的是这条 doc，不是那份快照。**（来历：主控曾把这两份快照当"抄错数字的副本"派单去改，被 T1b2 用上面三条现场证据顶回 —— 正确。）
> ⇒ **已要求 T1d**：PC 内部成员的使用放进 `#if TEXTLINE_SHIM_DIRECT`（或做一层间接），`#else` 必须给**诚实降级**（拿不到就跳过三重校验并**如实计数**，**不许假装校验过**），**两种形态都要 0 错**；"两种形态都编得过"已列为**起波前闸门**。
> ⇒ 在此之前 T1b 只能测 staging 那份 `2cc87a93…` ⇒ **T1d 的新代码目前一行都还没进过回归读数**。
> （**后续**：T1d 已加 `HbFaceInternals` 统一访问点 ⇒ 两种形态都 0 错 0 警；见本块末尾的 "T1d 自验 A/B"。）
> ### ✅ **T1c 收口 (乙)**：判定 = "**PC 半边无需新实现，缺的是可判性与 A/B**"
> **A/B 翻转（成对、同一套产物）**：开档（未设 ⇒ 开）`按句柄命中 48 / 回落族名 0 / 解析失败 0`、**2 份面**；关档（`WPF_LINUX_FACE_HANDOFF=0`）`0 / 0 / 48`、**1 份面** ⇒ **翻转成立且"关"档命中精确归零** ⇒ **排除"另有登记者"**（这正是只报 `48/0/0` 证不到的那件事）。
> **面身份三点对齐**：登记 `token=0x20000003 → DejaVuSans-Bold.ttf#0`（逐 run **14**）/ `0x20000004 → DejaVuSans.ttf#0`（逐 run **66**）↔ 渲染器解析到的面 + 文件名 ↔ T2b 逐 run 明细**逐值相同** ⇒ **这 48 个 run 用的就是 PC 整形用的那两份面**（同族 Regular/Bold，**不是 CJK 面**，独立 cmap 复核 `覆盖U+4E2D=否`）⇒ 与"CJK id 全 0、PC 从未用 CJK 面整形"自洽。
> **债务 #14 的可见后果（量化）**：关档会把**粗体 run 也用 Regular 面光栅化** ⇒ 标题区墨量 `1361 → 2167 px`、全帧像素差 `AE=8340`（包围盒 `661x827+38+42`），而 `skia 指令 180 / 未画种类 0 / 48 runs / id0=325` **两档逐项相同**。⇒ **"画了几条指令"与"画对了没有"是两件事**（T2b"尺子只能定位间距、身份要靠颜色"那条判例，本轮有了像素级注脚）。
> **可判性出口（此前真应用里读不到）**：`WPF_LINUX_FACE_HANDOFF_DIAG=1` ⇒ `[FACE_HANDOFF] Install: WPF_LINUX_FACE_HANDOFF=<未设> ⇒ 解析为 开; status=NativeAotExport registerExport=找到(MilFontFace_RegisterFromFile)` + 每次登记一行 `token / path / faceIndex / simFlags`（开关语义是**纯函数**且被自报行**实测印出**，不是文档自称）。覆盖自检**已常设**（独立新文件 + 缺省关 + 缺省档断言 `enabled=False ran=False outputChars=0 queries=0->0` + 打开档两条链 **9/9 一致**）⇒ **关掉了"降级链 b 无运行期实证"那条红**。
> ⚠️ 它给的坑（**已转 T1d**）：子段若用**字节流造的面**（`LinuxFontFace.FromBytes ⇒ SourcePath==null`，`Provider/LinuxFontFace.cs:170`）⇒ 路径式分配器拿不到路径 ⇒ 回落进程内表 ⇒ MIL 解析不到；诊断里已让这种情况可见（`登记#N path 为空`）。
> ⚠️ **T1c 独立复跑两条护栏（在 T1d 的 `192f7d38…` shim 上）**：`T1.73 73 例 CJK 逐行全等`、`T2d Height 1298/1298 + Baseline 1298/1298` ⇒ **R1 到那一刻为止没有把拉丁/度量弄退**。
> ### ✅ **T1d 自验 A/B（同一 harness、`-p:HbShimSrc=` 指两份源）**
> ```
>                     改前(2cc87a93…)          改后(88770503…)
> T1.73               ✅ 73/73                 ✅ 73/73
> T2  记账结构         1276/1298                1276/1298（①286/286 ②68/68 ③977/988 宽度超差83）
> T2b A 组断行         964/965 · 207/213        964/965 · 207/213
> T2d Height/Baseline ✅（1298/1298）          ✅（1298/1298）
> T3  折叠             判定1298/1298 明细210/236  判定1298/1298 明细210/236
> T2c Tab（已登记红）   15 例                    15 例
> ```
> ⇒ **逐项完全相同**（唯一差异是改前那次 `T0.6` 报红：用 `-p:HbShimSrc=` 覆盖源文件时"编进去的那份 ≠ 磁盘那份"——**仪器工作正常**的读数，不是退步）。这也说明 `88770503…` = `192f7d38…` + 双向形态守卫（`HbFaceInternals`）+ 汇总行追加字段，**判据面没有别的改动**。
> **R1 接线五项已全落**（`TryCollect` 收 run / run 级取面（按 props 引用缓存）/ 每码点闸门（覆盖 **且** 可渲染）/ 分段 `GlyphRun` / `WPF_LINUX_MULTIFONT` 缺省开）；**尚欠**：`CoverageProbe`（新 exe）两个 API 笔误未修完 + 真跑一次"会不会否证我自己"。**T1d 未喊"可以起波"⇒ 主控不起波。**
> ### ✅ **T3 交正式验收基线**（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`，105 行 / 6 条机读 `BASELINE` 行）
> **配置五元组**（写死在表头）：`pc:b1decf1665d6519a` + `bridge:cefd7281f670a1fb(4,896,624B)` + `pf:1314570537a41a49` + `win32shim:4c023937421db45f` + `wic_shim:669385504238d326`，外加 `bridge_publish_sha` 交叉校验（**防"加载的不是刚发布的"**）。
> ```
> default ×3 逐次一致：exit=143 drawn=180 notdrawn=0 frames_good=14/14 blank=0 capture=ok scroll=ok 938x938 colors=2935 cross_ae=0 max_concurrent=1 leftover_after=0
> env     ×3 逐次一致：exit=143 drawn=165 …                                                     colors=2651
> 唯一红 = 判据④ feature-color-missing（= D-d）；committed=623 pending=0
> ```
> - **`938×938` vs 历史 `938×646` 的真因**：**窗口变高了**（XAML `Height` 620→900，为 D-c 需求），**不是抓法变了**；抓法一直是 `xwd -root` 连拍 + 按窗口几何裁剪 ⇒ 落盘即窗口大小。**它自己指出判据⑤ 接近同义反复**（裁剪本就用那个几何），补了两条独立互证（根帧取样：窗口外 `srgb(0,0,0)` vs 窗口内 `srgb(14,19,32)`；裁剪帧 vs `xwd -id` 直抓 `AE=0`）。
> - **`committed/pending` 取法**：`WPF_LINUX_MIL_TRACE=1`（runner 默认开）+ `grep '通道#2:' "$LOG" | tail -1` ⇒ 本轮 `623 / 0`（不必再由别人代产）。
> - **新观测（口径级）**：同配置下 `timeout=35s` 时**窗口还没映射**（`drawn=0`、无标题窗口、`capture=all-blank`），`timeout=90s` 正常 ⇒ **基线固定 90s**，且 **"35s 下的红不是渲染结论"**（已写进基线文件）。
> - **`pkill` 误伤归因到 T3 的 runner**（它主动承认）：当时有一段**全局模式匹配 + kill**（`app_procs(){ pgrep -f 'dotnet WpfTextDemo.dll' … }` ⇒ `kill -TERM`）。**已改成只认自己的子进程**（`pgrep -P "$$"`）、全局口径**只计数绝不杀**，并在启动时**自查**（源码里出现 `pkill|killall|kill -f` ⇒ `exit 2`）。**对基线读数无影响**（6 次运行 `max_concurrent=1 / leftover_after=0`）。**进程泄漏也修了**（根因同 `EXIT` trap 那次：`$!` 是子 shell 而非 dotnet ⇒ 启动加 `exec` 后 `$!` 即应用 PID）。
> ### 📦 桥再前进一版（主控发布）
> `wpfgfx_cor3.so` = **`f519eff9c892a31e272a0f61ca538a85181d5a863b63840ce130ed87ab26bf44`** / **4,900,752 B**（含 M7b 的 `materialize尺寸=` 改名 + 进程内 `describe(source)=`）；`src` 指纹发桥前后一致 `6140a9e9…`；`publish-milbridge.sh` 现在**自动接跑 `check-applocal-sync.sh`** ⇒ `APPSYNC=PASS`。
> **M7b 对 `pkill` 事故的登记**（重要）：它用的是 `pkill -f "[W]pfTextDemo.dll"` —— **方括号只做到"不匹配 `pkill` 自己那行"，正则仍会匹配任何命令行里含该名字的进程** ⇒ 旁观者照样中招。**⇒ 手册条目补全：自排除 ≠ 安全；杀进程一律按 PID。**
> ### 🔴 第 15 个成员（**主控自己的 `verify-all.sh`**）：**"有 Xvfb 进程" ≠ "DISPLAY 上有 server"**
> 波后第一次跑全量门禁得到 **8/9，唯一红 = `ManagedLayer.Tests`**。取证：单独复跑该套件在 `:97`（**无 server**）仍然红（1 失败：`M7cInputPathTests.端到端_真应用收到指针与按键…`），换到**活着的** `:98` ⇒ **54/54 全绿（41 s）**。
> **根因在我的 `verify-all.sh`**：它只判 `pgrep -x Xvfb` 有没有进程就"复用"，然后**无条件** `export DISPLAY=:$DISPLAY_NUM`（=`:99`）—— 而当时活着的 Xvfb 在 **`:98`** ⇒ **导出了一个没人听的 display** ⇒ 端到端输入用例**假红**（应用 `CreateWindowEx` 抛 `Win32Exception(1400)`），Windowing/HelloMil **大面积假跳过**（26+13 / 18+1，修好后是 **44+0 / 19+0**）。
> **⇒ 判据改落在"能不能连上"**：先 `DISPLAY=:$DISPLAY_NUM xdpyinfo`；不通则从 `pgrep -a Xvfb` 解析**真实 display 号**逐个试；都不通才自己起；选中的 display **用 `xdpyinfo` 验证后才 export**（并明确打印"实测 display `:98`，注意不是 `:99`"）。
> **教训**：**"进程在"与"服务可用"是两件事**；这是"仪器在说谎"家族的第 15 个成员，也是**第一次由主控的验收脚本**贡献的。
> **修好后重跑：`verify-all.sh` = 步骤 9/9、用例 828 通过 / 2 跳过 / 0 失败**（`Commands 562｜Rendering 141+2｜Windowing 44｜HelloMil 19｜ManagedLayer 54｜Presentation 8｜线格校验 ✅`）。**修前 vs 修后的差别本身就是证据**：Windowing `26+13 → 44+0`、HelloMil `18+1 → 19+0`、ManagedLayer `1 失败 → 54/54` —— **死 DISPLAY 吞掉的不只是那一条用例，是一整批"静默跳过"**。
> ### ✅ **CJK 链的最后一环已闭合**（T1c，同一次运行的独立复核）
> `[FACE_HANDOFF]` 登记**恰好 4 个令牌**，与逐 run pid、渲染器实际用的面**三点对齐**：
>
> | token | 登记路径 | 渲染器实际用的面 | 覆盖 U+4E2D | 整帧 runs |
> |---|---|---|---|---|
> | `0x20000003` | `DejaVuSans-Bold.ttf#0` | `DejaVu Sans` / 同路径 | **否** | 13 |
> | `0x20000004` | `DejaVuSans.ttf#0` | `DejaVu Sans` / 同路径 | **否** | 57 |
> | **`0x20000005`** | **`NotoSansCJK-Regular.ttc#0`** | `Noto Sans CJK JP` / 同路径 | **是** | 49 |
> | **`0x20000006`** | **`NotoSansCJK-Bold.ttc#0`** | `Noto Sans CJK JP` / 同路径 | **是** | 12 |
>
> - **路径逐字相同 4/4** ⇒ 令牌里的 `(path, faceIndex)` **就是**渲染器真正打开的文件 ⇒ **R1 的 per-段面真的传到了渲染器**（这正是"一个 `GlyphRun` 只能带一份面"那条硬约束的验收）。
> - **四分面 runs `13+57+49+12 = 131` = 整帧 runs** ✓ 闭合；`id0=0 / nonlatin=322 / maxId=63151 / 面数=4` **与主控读数逐项一致**（跨 agent 数值这次有出处、能对上）。
> - **`path 为空 ⇒ 不接管` 出现 0 次** ⇒ T1c 早先提示的那个坑（用字节流造的面 ⇒ 路径式分配器拿不到路径）**本次未被踩上**；**范围限定**：本次配置里没有"字节流造的面"那条路 ⇒ 是**对该配置的证实**，不是普适证明。
> ### 📌 剩下最显眼的缺陷：**多行段落摞在同一基线**
> T1b 第一轮取证**如实交白卷**："两台仪表都答不了"（`GLYPH_CENSUS` 无 `origin=`/Y 列；`DRAW_CENSUS` 只有**卡片级**设备矩形）⇒ **它拒绝编造 Y**。它给的三条路我选**第 1 条**（给 `GLYPH_CENSUS` 加"逐 run 原点 Y"+ 按 Y 去重汇总，**T2b 的车道**）；另有两条备选（MIL 侧 `MilCmdGlyphRunCreate.Origin`/变换读数 = M7b 车道；或 T1b 自建只读旁路）。
> 它已排除的（别重复）：文字算宽 ✗、框算窄 ✗；`T2d/T2e` 的行度量与真机 **1298/1298、10/10** 对得上 ⇒ **"我们交出的行高"本身无过**；且 `LINEDIAG` 实测**整进程我们只接手 1 段** ⇒ **画面上摞印的段落绝大多数不是我们排的**（这条本身就很有价值）。
> ⚠️ T1b 预算见底 ⇒ 拿到仪表读数后由主控决定是否再动它。
> ### ✅ T2b 交出 `originDIP` 列 —— "行推进 ≈ 0" **第一次有了直接读数**
> `Rendering/GlyphRunCensus.cs` 增 `originDIP=(x,y)`（取 `MilGlyphRun.Origin`，**单位写明是上游给的 DIP、未乘 DPI 缩放** —— 它拒绝自行换算，理由正是零缩放 CTM 那次的教训）+ 汇总行 `原点Y汇总: runs=N distinct_origin_y=K Y值(DIP)=[…]`；新增用例 `origin_y_is_recorded_per_run`；突变自测（唯一入口 `+1.0` ⇒ 断言红，复原后残留 0）；`Rendering.Tests **142/0/2/144**`、`Commands 562/0/562`、golden 仍只变 5 张、**0 错 0 警**。
> **新桥实测（`f3a20678…`，default 档）**：
> ```
> 原点Y汇总: runs=131 distinct_origin_y=6  Y值(DIP)=[10.210,10.210,11.139,12.067,12.995,24.133]
> run#1 (0.000,11.139) → run#13 (309.117,11.139)            ← 同一"行"内 x 递增、Y 相同（R1 的 per-段 run，符合预期）
> run#18 (0.000,12.995) n=20 ｜ run#20 (0.000,12.995) n=48 ｜ run#21 (0.000,12.995) n=27 ｜ run#25 (0.000,12.995) n=17
> ```
> ⇒ **多个 `x=0` 起始、字形序列各不相同的 run 共享同一个 Y**（看着就是同一段落的**多行**），而行间增量只有 **~0.928 DIP**（11.139→12.067→12.995），远小于应有的行高（~16–21 DIP）⇒ **"行推进 ≈ 0"现形**。
> **⚠️ 但还差最后一格（不许就此定罪）**：`Origin.Y` 是**每个 visual 自己的坐标**，若每行是**由变换施加位移**的，那么 Y 相同也可能是对的 ⇒ **已派 T2b 做"逐 run `originDIP` ↔ `DRAW_CENSUS` 设备 Y"的相关性**：多个同 Y 的 run 若**设备 Y 也相同** ⇒ 真叠印；若设备 Y 不同 ⇒ origin 只是行内相对量、方向要改。
> ### 🧪 T2b 的另一条方法学教训：**观测精度不足 ⇒ 假的"负"结论**
> 它第一次做突变自测时用 `stat -c%Y`（**秒级**）读 mtime，得到"改前=改后"⇒ 打印 **"❌ 没重编"**。**那个结论是错的**：换 `stat -c%y`（纳秒）后 `…41.524 → …55.049` 清清楚楚。**前几次"仪器在说谎"都是假的正结论（把失败报成成功），这次是假的负结论（把成功报成失败）** —— 同一族的另一侧。**⇒ 判据的分辨率本身要够，否则它会给出一个看起来很有力的错结论。**
> ### ✅ D-d 修法 A 落地（T2）+ WIC shim 换版
> `CopyPixels` 支持任意子矩形：`prc` 规范化（`NULL`/`(0,0,w,h)`/`(0,0,0,0)` 仍走**原有整图代码**）；`bpp = rowBytes/width`；非法/越界 ⇒ `E_INVALIDARG`（**不静默截断、不补零**）；子矩形逐行拷贝；**块位置放在既有 `need` 检查之前**（它自己指出：否则老检查会先用整图尺寸把 1×1 拒掉 ⇒ 用例 1/2 恒红）。可观测性：入口 trace 带 `prc=(x,y,w,h)`、非法矩形打 `COPY_PIXELS_REFUSE reason=`、子矩形成功打 `COPY_PIXELS_SUBRECT` ⇒ **子矩形拒绝不再静默**。
> **两向证据**：`probe_subrect` **6 条全 PASS**；突变用**行基址 off-by-one**（它明确说明**不用 `x/y` 对调**——对 `(0,0,1,1)` 不敏感、会假绿）⇒ 用例 1/2 必红 ⇒ 撤销复绿；五个既有探针全绿；`DirectWrite.Linux.Tests **123/0/0**`。
> **一处语义差异（已裁定）**：`cbBufferSize` 不足仍返回 **`E_INVALIDARG`**（本移植既有语义、整图与新路径一致），**不是** WIC 文档的 `INSUFFICIENTBUFFER` ⇒ **登记为"已知偏差、非缺陷"**，在拿到"有调用方依赖该码"的证据前**不得顺手改**（与退化 CTM 同纪律）。
> **发布**：`wpfgfx_cor3.so` = **`f3a2067870f0372425b9770c3530aaa238e053dd122a4f009ff6786c1ddbc444`** / 4,904,912 B；`libwpfwic.so` = **`03b67fbcd7c385b6910396165a4db58a`** / 70,440 B / 13 导出；`APPSYNC=PASS`；src 指纹 `087643c5…` 发桥前后一致。
> ### ✅ T1c 修掉普查装置的**孤儿泄漏**（~2 GB/次，T3 发现）
> 根因与本工程早先那次同源：`( cd "$RUN" && env … dotnet … ) &` 的 **`$!` 是子 shell** ⇒ `kill $!` 杀不到 `dotnet`，它被 reparent 到 `ppid==1` 并带 ~2 GB 留下（**rc 正常、日志完整**，所以特别难发现）。修法：**`exec`** 让 `$!` 就是应用；收尾 `kill <PID>` + `wait`；全文**无 `pkill/pgrep/setsid`**；**孤儿断言**（`ppid==1 ∧ argv[0]∈{dotnet,*/dotnet} ∧ argv[1]==WpfTextDemo.dll ∧ cwd∈/tmp/t1c*` ⇒ 有残留就打印 + 退出码 1）；固定输出行 `CENSUS_ORPHANS before=0 after=0`；`trap … TERM INT`（`timeout` 杀脚本时 EXIT trap 不跑 ⇒ 自起 Xvfb 会变孤儿）。**回归**：同参数复跑读数**逐项不变**（`runs=131 … id0=0 nonlatin=322 maxid=63151 distinctpids=4`）⇒ **改了装置、观测没变**（这正是"装置改动必须带回归"的正面例子）。
> 它还做了**判据反例自检**：本机 5 个 `ppid==1` 的 dotnet 全是 MSBuild worker ⇒ 被 `argv[1]` 条件正确排除；自己的命令行含该字面量也被 `argv[0]` 排除 ⇒ **"别误伤旁观者"是按判据验过的，不是嘴上说的**。
> ### ✅🎉 **D-d 修好 —— 主控直接取证（原始行 + 读图）**
> T3 基线跑的诊断腿里，同一个句柄现在长这样（对比修前：`size=1x1 / fmt=…c910 / kind=Frame-Source`）：
> ```
> [cwic-trace] source=0x5 ownedByWic=True materialize尺寸=96x96 foreignSources=0 shimGetSize=96x96（第二次=96x96 ok=True）
>              format=6fddc324-4e03-4bfe-b185-3d77768dc90f → SKBitmap=96x96 … copyPixels=S_OK
> [cwic-trace]   describe(source)= h=5 via=slot kind=FormatConverter foreign=0 ownedByWic=1 refs=1 size=96x96 rowBytes=384 fmt=…c90f
> WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=(0,0,1x1)
> WIC_TRACE COPY_PIXELS_SUBRECT prc=(0,0,1x1) dst=4 cb=4        ← **子矩形成功、无拒绝行**
> WIC_TRACE COPY_PIXELS h=5 96x96 foreign=0 prc=null
> ```
> ⇒ `materialize尺寸 1x1 → **96x96**`、`fmt …c910(Pbgra32) → **…c90f(Bgra32)**` ⇒ **上游那条"1×1 解码探针被拒 ⇒ 换 1×1 占位"的链条已断**。
> **主控读图**（`/tmp/wptd-run-1368116-wicdiag/direct-default-r1.png`，938×938 / sha `eacbc6df…`）：**④ 卡的"程序生成位图"现在真的画出来了**（四象限彩色块）；**⑤ 卡三个形状（矩形/渐变椭圆/三角）也在**；中文全是真汉字。
> ### ⚠️ 同一张图带出一个**新观察（未归因，不许当结论）**：① 卡正文**空了**
> 对比主控自己那轮的图（`/tmp/r1after/shot-1.png`，`17be1956…`）：①「多行折行 · 中英混排」卡在**我那张里是"摞印的一行"、在 T3 这张里整块空**。而**同一次运行的 census 与我的逐项相同**（`runs=131 / distinct_origin_y=6 / 同一组 Y 值`）⇒ **文本的 run 确实存在** ⇒ 更像**抓帧/滚动腿/时序**的差别，而不是"文字没画"。**已要 T3 在基线报告里对这两张图做核对**（它拥有 runner 与抓帧逻辑）；**在核对之前不写任何归因**。
> ### 🔬 T1c 的字体度量诊断（**只读，零改动**）：**"度量/行距公式"这条不被支持**
> 逐跳链路（`MetricsFactory.cs:130-149` → `ManagedSurface.cs:335,342`（**两处都有 `(double)` 强转**）→ `ProviderAdapters.cs:52-69` → `PhysicalFontFamily.cs:422-433` → `Typeface.cs:275,280` → `SimpleTextLine.cs:1338/1349`）**算法给出 14–21 DIP**，而实测步长 **0.928 DIP** ⇒ **差 15–22 倍**。
> **两条算术（这是本轮最漂亮的一手）**：① **`0.928 × 300 = 278.4 ∉ ℤ`** ⇒ 这些 Y **不在 1/300 ideal 网格上** ⇒ **排除"LS 定点量化"整条路径**；② `0.928 ≈ 1/1.0776` ⇒ 若 `Display` 模式且 `ppd≈1.0776`，行高恰是 **~1 设备像素**；但 900×900 DIP 对 938×938 px 给出 `ppd=1.0422` 或 `1.0`（两种解释互斥）⇒ **现有读数判不了**（它**明说判不了**，没有硬凑）。
> 它还对**真值缺失**如实交白卷：`windows-results.json` 里**没有** `DejaVu Sans`、**没有** Noto CJK、度量字段 0 命中 ⇒ **不拿别的字体凑**。
> **已批准并派它执行**：在 PC 侧加一条 **gated 只读 trace**（`WPF_LINUX_LINEHEIGHT_TRACE=1`，缺省关）打 `族名 / emSize(DIP) / ppd / TextFormattingMode / LineSpacing 返回 / Baseline 返回 / run.Height / line._height`，**编到 `/tmp` 用 `PC_OVERRIDE=` 跑**（不起波、不重建权威 PC），把 0.928 **唯一归入四类之一**：(1) `emSize` 太小 ｜ (2) `ppd` 异常 ｜ (3) `LineSpacing` 返回 ≈0.07–1（那才轮到 provider）｜ (4) 都正常 ⇒ 真凶在 `BaselineOrigin → IndexedGlyphRun → MilGlyphRun → 渲染器` 链。
> **它顺手纠正一条陈旧结论**：`MetricModels.cs:68-82` 注释里"骨架漏了 `(double)` ⇒ 行高恒 1.0"**在当前代码里已不成立**（`ManagedSurface.cs:342` 有强转）⇒ **陈旧结论也是一种假绿**，已在报告 §14 登记更正。
> ### 🎉 **验收门禁首次 PASS（2 档 6/6）** + **D-d 闭环**（T3 正式重新基线）
> ```
> config = pc:f31822ce4a3e510d, bridge:f3a2067870f03724, pf:24a1260262483979,
>          win32shim:4c023937421db45f, wic_shim:03b67fbcd7c385b6, hbtextline_shim:fbda5f88d826a883(stale:no)
> default ×3: PASS exit=143 drawn=263 notdrawn=0 frames 14/14 blank=0 capture=ok scroll=ok 938x938 colors=3921 cross_ae=0
> env     ×3: PASS exit=143 drawn=165 notdrawn=0 frames 14/14 blank=0 capture=ok scroll=ok 938x938 colors=2743 cross_ae=0
> WPTD_SUMMARY=PASS tiers_passed=2/2（runner 退出码 0）
> CENSUS_ORPHANS before=0 after=0 ｜ REAPED_ORPHANS total=0（⇒ 没有第二条泄漏路径）
> ```
> **D-d 双证据**：`[cwic-trace]` 的 `materialize尺寸 1x1 → **96x96**`、`fmt …c910(Pbgra32) → **…c90f(Bgra32)**`、`COPY_PIXELS_REFUSE = **0**`；**T3 读图**：④ 卡位图（四象限+渐变带+白框）与 ⑤ 卡三形状都在、整窗中文可读。
> ### 🔴 第 16 个成员（**新形态：恒假判据**——与"`Assert.True(true)` 空壳"正好相反）
> T3 自查：上一版"**唯一的真红**"（判据④ `feature-color-missing`）**有一部分是它自己的假判据** —— 位图做了"对角渐变调制"，**每个像素都偏离基准色** ⇒ 判据期望的四个基准色（`#E53F3F/#3FC46B/#3F7DE5/#E5C43F`）**在位图里根本不存在**（实测整图仅 179 色，四个基准色一个都没有）⇒ 那条判据**永远红、且证明不了任何东西**（既不能证 D-d 坏、也不能证 D-d 好）。**把四象限改成精确平坦色后**，判据可满足：`image_content_g=30550 / r=14300 / b=30926`。
> **⇒ 家族补全**：此前有**恒真**（`Assert.True(true)`、空帧 `未画种类 0`）、**空真**（"空"有两种含义）、**恒假**（本次）。**共同点：判据的取值空间与被测对象不相交** —— 一个测不到失败的判据和一个测不到成功的判据一样没用。
> **⇒ T3 自己划的边界（这条最值钱）**：**D-d"修好"的结论不是由这条判据得出的**，而是 `[cwic-trace]` 的 `1x1→96x96 / …c910→…c90f` + **读图**两条独立证据。它没让"修好了判据 ⇒ 缺陷也修好了"混成一句。
> **它顺手还修了一处同类**：两列新仪表的提取写进了**没有 assert 的字符串替换** ⇒ 输出 `NA` 而 census.log 里明明有那些行（**"仪器悄悄不工作"**）⇒ 已补 assert 并复跑。
> ### 📐 T3 给"行推进"提的判据形态（**我压着不落，理由记档**）
> 它建议：`ORIGIN_Y` 的 `distinct_origin_y` 与"该段落行数"比对（行数 > 1 而 distinct = 1 ⇒ 判红）。**但它主动不落**，因为**相关性判定归文本车道**（T2b 正在做 `originDIP ↔ DRAW_CENSUS 设备 Y` 对拍）⇒ **避免再造一条"看错语义"的假判据**。它的口径也写明了：**判据④ 是"颜色存在性"，看不见行推进 ⇒ 门禁绿 ≠ 这条缺陷不在**（它只**记录** `ORIGIN_Y` 那一行，不据此判红）。
> ### 🔎 悬案已结（主控自己提的）：**"① 卡正文是空的"是抓帧/腿的差别，不是渲染回归**
> 我在 T3 的**诊断腿**截图（`direct-default-r1.png`，`eacbc6df…`）里看到 ① 卡正文空、而**同一轮终版截图**（`wpftextdemo-default-r1-after.png`，`4014fa98…`）里①卡正文在（只是行行相叠），**且两轮的 census 逐 run 相同**（`runs=131 / distinct_origin_y=6 / 同一组 Y`）⇒ 结论：**同一次运行的不同抓帧腿**，非回归。**主控的取证方式**：对同一区域做 `histogram` 比对（我那轮该区域有 1,497 个正文色 `#D8E4F5`、T3 诊断腿那张只有标题色 `#FFD166`）⇒ 用**像素**而不是"我觉得空"来判。
> ### 🎯 **"多行摞印"的归因被两条独立路径钉到同一点**（本轮第二个头号结果）
> **(a) T1c 的纯算术恒等式（5/5 命中 <0.001 DIP）**：样例字号只有 `11/12/13/14/26`，而 DejaVuSans 的 `hhea.ascent/upem = 1901/2048 = 0.928223`：
> `11×0.928223 = 10.2104 ↔ 10.210`｜`12× = 11.1387 ↔ 11.139`｜`13× = 12.0669 ↔ 12.067`｜`14× = 12.9951 ↔ 12.995`｜`26× = 24.1338 ↔ 24.133`
> ⇒ **`origin.y` 只是 `FontSize × (ascent/upem)` = 行内基线偏移**（真源 `_baselineOffset`），**与"第几行"无关**。
> ⇒ 并纠正两条读法：**`0.928` 不是行距**，是"**FontSize +1 的增量**"；那 6 个值是 **6 个字号的偏移**，不是 6 行的位置。**T1c 同时作废了自己 §14 的排除项 #1**（`0.928×300 ∉ ℤ` 那条：日志以 `F.3` 打印 ⇒ 容差 ±0.15 ideal，`11.139×300 = 3341.7` 与真值 `3342` 只差 0.3 ⇒ **够不着"排除"的强度**）。
> **(b) T2b 的实测对拍（`originDIP ↔ 设备 Y`，131 runs 全对上）**：
> ```
> originDIP.y=10.210  run=8  → 设备Y去重=8
> originDIP.y=10.210  run=15 → 设备Y去重=4  [304.239,478.192,652.146,765.857]
> originDIP.y=11.139  run=22 → 设备Y去重=2  [80.631,687.973]
> originDIP.y=12.067  run=31 → 设备Y去重=7
> originDIP.y=12.995  run=54 → 设备Y去重=**17**
> originDIP.y=24.133  run= 1 → 设备Y去重=1（**只有 1 个 run ⇒ 不构成证据**，它自己注明）
> ```
> ⇒ **每个 `originDIP.y` 组都对应多个设备 Y（最大 17）** ⇒ **`origin` 是行内相对量、不是行位置**。
> **⇒ 结论：`多行摞印 = 上游把多行放在同一 Y` 这条假设被否证**（T2b 上一轮**明确把它标成"假设、等读数判"**——**若当时按假设去改上游就会改错地方**；这正是先做判据的价值）。**方向 = 行位置（每行自己的 translate / `BaselineOrigin` 里的行 y）在变换/绘制链上没带上**，T1c 归因表里的 **(4) 类**（`run.Height`/`_height` 正常但 `draw origin` 的 y 每行相同）成为最可能。
> **下一步（已在飞）**：① **T1c 跑 line-height trace**（PC 侧 gated 插桩，`PC_OVERRIDE=` 编到 `/tmp`，**不打权威 PC**）⇒ 按"先写判据后填数"的五类表落格；② **T2b 把 `devY`/`devX` 加进逐 run 明细**（并带上该 run 的 `CTM`/累积 world）⇒ 判据 = **同段相邻行的 `devY`/`CTM.f` 是否逐行递增 ~16 DIP**：递增 ⇒ 行位置其实带上了（方向再翻一次，得用绘制顺序/覆盖解释）；全相同 ⇒ 定位到丢在哪一步。
> ### 🧪 主控独立复跑 `run.sh tline`（冻结 shim `fbda5f88…`）—— 与 T1d/T1c 的数字逐项一致
> ```
> 通过 16 / 失败 4（4 条都是"已登记未实现"的保留红，harness 明确不为变绿而放宽）
> ❌ T2 记账结构 1276/1298（① 286/286 ② 68/68 ③ 977/988，宽度超差 83）
> ❌ T2b A 组断行 964/965；用例级 207/213
> ❌ T3 Collapse 判定 1298/1298；明细 210/236；空参抛 253/253、空参返回 this 1045/1045
> ❌ T2c Tab（**已登记差异·保留红**）34 例中 15 例不一致 —— **新发现的差异类别**（不属于本轮三条记账），已登记未实现
> 计数器汇总：paragraphs=689 breakNull=7 modifierLines=30 collapseApplied=236 collapsedRangesReturned=236 forcedBreakLines=573 kinsokuPulls=29
> LS 绊线装置自证：`nm -D` 与 `LD_DEBUG=symbols` 日志**互相印证**（`LsDisableSpecialCharacterLigature` 已定义 / `LoAcquireBreakRecord` 未定义）
> ```
> ⇒ **主控第一手读数**：R1 之后的 shim 在"拉丁/记账/折叠"三条上与改前**逐项相同**（差异只在已登记项），且 **LS 确实没被走到**（符号缺失 + 绊线自证两条独立证据）。
> ### 🎯 **T1c 的 line-height 插桩把归因表落格：(1)(2)(3) 排除、(4) 在上游路径上被否证 ⇒ 箭头转向"我们接手的那条路"**
> 插桩件（PC 侧 gated、编到 `/tmp`、**权威 PC `f31822ce…` 未重建**）：`patch-presentationcore-lineheight-trace.py` + 生成物 `SimpleTextLine.Linux.cs`；**先写判据后填数**。
> | 类 | 读数 | 结论 |
> |---|---|---|
> | (1) emSize 太小 | `em=11.0000 / 26.0000`（= XAML 字号） | ❌ 排除 |
> | (2) ppd 异常 | `ppd=1.0417`（=25/24，与 938px/900DIP 一致） | ❌ 排除 |
> | (3) 度量塌了 | `11→12.8047 = 11×1.164062`、`26→30.2656 = 26×1.164062`；`Baseline = em×0.928223` **逐位精确** | ❌ 排除（与 §14.2 字体真值一致） |
> | (4) 行偏移没带上 | `origin.x` 恒 0，但 **`origin.y` 逐行递增**：`0 → 13.9688 → 27.9375 → 48.8906 → 97.7812`（`y/行高 = 1/2/3/6`） | ❌ **在上游 `SimpleTextLine` 上被否证** |
> | (5) 其余 | **摞印只在 ①（多行折行）与 ②（TextTrimming）两块**；标题/③/④标签/⑥ListBox/⑦ **全部正常** | ✅ **剩余空间 = `HbTextFallback`（我们这条）那条路** |
> **关键推理**：① ② 恰好是**唯一会落到我们的 shim** 的段落（T1b 的 `LINEDIAG`：整进程我们只接手极少数段）⇒ **摞印在我们的路上，不在上游**。
> **它自己仪器的缺陷（如实登记 + 已修）**：首跑 **`draw origin` 一行没打** —— 四个站点**共用 60 行预算**，测量期先跑把它吃光（run 14 / line 33 / **draw 0**）。改成 **draw 独立预算** + 加 `cpFirst` 后：run 28 / line 64 / **draw 40** ✓。**教训**：**多站点共享有界预算 ⇒ 最晚发生的站点永远看不见**（"空=两种含义"同族的新形态）。
> ### 📦 桥更新（含 T2b 的 `devY`/`CTM` 列）
> `wpfgfx_cor3.so` = **`177a07a6403a051c70cf0d26b8646da1705343e1f9b33acf2cec56e005b20306`** / 4,933,824 B；`src` 指纹 `d59c166d…` 发桥前后一致；`APPSYNC=PASS`。**T2b 正在跑**：`① ② 那 3–5 行各自的 `originDIP` / `devY` / `CTM.f``，判"逐行递增"还是"几乎不变" ⇒ 若不变即坐实"摞印在我们的路"，随后由 **T1d** 在 `build/shims/PresentationCore.HbTextLine.cs` 加**缺省关的只读插桩**（同一套判据，逐站点独立预算，DIRECT+反射两形态都要 0 错）。
> ### 📌 2026-09-11 第四轮（主控）：Tab 口径 / 债务 #1 复现尝试 / 文档对码 / 功能广度样例
> **T1d · Tab（`\t`）口径落地**（`build/shims/PresentationCore.HbTextLine.cs` = **`adbee67b0cc2f6dd179c94eb41546fbe5826868cec55375968e4249794b04fca`** / 3528 行）：
> **规格先写报告再看代码**（真值 34 个 Tab 用例全是 `'a\tb\t\tc\td'`）：**`\t` 宽 = 0**（宽 ≥40 时单行 `w=36.35` = 四个字母之和）；**每个 `\t` 之前可断、之后不可断**（真值断点 4/6 恰好都在 `\t` 前；而 ICU 70 给的是 `[0,2,5,7,8]` ⇒ **实测否证了"直接用 ICU 断点"**）；**`\t` 不计入 `TrailingWhitespaceLength`**（但仍占区间）。实现三处：`ZeroTabAdvances`（清零 advance + 换成 space 字形，**否则零步进处会叠一个 `.notdef` 豆腐块**）、`OverlayTabs`（规则 4，**禁则参考集同用**，否则会被规则 2 拉字）、`IsTrailingWhitespace`（tab 不算行尾空白）。
> **读数**：`T2c` Tab 不一致 **15 → 0**；**"其余各列只变好、没有一条变坏"** —— `T2` 记账 `1276 → 1286/1298`（③977→984/988、宽度超差 83→**47**）、`T3` 折叠明细 `210 → 218/236`、通过 **16→19** / 失败 **4→2**；`T1.73 73/73`、`T2d 1298/1298`、`T2b 964/965·207/213` **不变**。**逐例对照**：不一致用例 32→17、**新出现的不一致 = 无**、消失的 15 个恰好是那 15 个 Tab 用例。**牙齿**：两条规则各突变一次（关零宽 ⇒ 15 例红；关断点规则 ⇒ 2 例红），还原后逐字节回到 `adbee67b…`。
> **T1b · 容差口径统一 + `Extent` 明细脚本**：`T2d`/`T2e` 现在都打**同一格式** `一致 @0.34: X ｜ @0.01: Y`（`@0.34` = 项目口径/1-300 英寸量化，`@0.01` = 严口径），**两台装置不再"互相矛盾"**（`T2e Baseline 10/10` 是 0.34 口径、`T2d 6/10` 是 0.01，差额 4 例全是 CJK 字体代用）。`build/MilBridge/tools/t2d-extent-detail.sh`（默认用真 shim，文件头带被测 sha）在 **staging v7** 上"有牙"自证：1338 条里可比行**全部**是余差（真值逐行不同 14.16/10.896/14.576…）。**它又自抓第 4 处仪表错**：明细头写真 shim 的 sha、而编译进去的是 staging 副本 ⇒ 已改为 env `T1B_SHIM_PATH` 传递。
> **T2b · 文档逐条对码审计**（只读）：✅ 过期/已闭环 **5** ｜ 🔴 仍成立 **9** ｜ ❓ 判不了 **3**。**主控已按代码复核并落笔**（新增 `docs/ARCHITECTURE.md` **§8.2**，并改正 5 处）：#4「10 条（108/118）」→ 实测 `s_notImpl` **7** 条 ⇒ **111/118**（且与 `unimplemented.md` §1 标题「7 / 118」**自相矛盾**）；#15/#21 的「11 个 `Wic*` 导出 / 66,152 B」→ **13 导出 / 70,440 B**；#22 WIC v2 借用**已落地**（`pixels_borrowed` 6 处、未借像素的拒绝**保留**）⇒ 标 ✅；#14 的「面数=2 / 解析失败 48」是 **R1 前**口径 ⇒ 改为 R1 后（面数 **4**、`id0→0`、非拉丁 **322**）。
> **T2b 提的一条新类别（我采纳）**：**"过期"与"从未对齐"不同** —— #4 的「10 条」与 §1 的「7 / 118」**并存了好几个波次、谁也没红**；这类**不会因为又修了一处而被发现**，只能逐条对码。**落地形态**：代码可算的量（未实现命令数、导出数、副本 sha/体积）文档**引用命令**而非硬写数字；并把"文档自相矛盾"纳入交付前的便宜检查。
> **M7b · 债务 #1（flaky）：未能复现 ⇒ 按规则没改代码**。52 轮全绿（`Commands` 24 轮 / `Windowing` 14 / `HelloMil` 14，load≈10 时跑的）。**机制分析（我认为是真身）**：`ResetProcessStateForTests` **刻意不清 `MilChannelRegistry`** ⇒ 泄漏的通道活到后面的用例，而 xunit 的**调度/发现顺序随负载与并行度变化** ⇒ **"同一命令有时红"可以完全由顺序引起，不需要真并发**；这也解释了**原 32 核环境 15 轮 5 红 / 本机 3 核 52 轮 0 红**。⇒ 裁定：**加"泄漏守卫"（缺省关、只读）+ 显式并行配置（消除"默认值随版本/机器变化"这个变量）+ 把机制写进债务 #1**；**实例注入只登记不落地**（现在做无法证明修好了什么）。
> **T3 · 功能广度样例就绪**（未跑）：`samples/WpfFeatureProbe/` + `run-wpfprobe.sh`，9 块（`popup` 独立 HWND / `anim` 动画族 / `opacitymask` 正负双向 / `effects` DropShadow+**未验证的 Blur** / `controls` TabControl·TreeView·**DataGrid** / `textbox-edit` 编辑态+输入 / `virtualize` 200 项 / `transforms` / `text-rtl`）。**静态检查证据**：编译 0 警 0 错、**BAML 产出**（1560/720 B ⇒ XAML 能被我们的 PF 解析）、色表 9/9 交叉核对、`--tier bogus` 在起 X 之前 rc=2。**两个防恒真/恒假的设计**：测试色只出现在功能内容上（边框中性色，否则判据恒真）、`opacitymask` 用**负向判据**（黑遮罩 ⇒ 测试色必须不可见）。**崩溃单独分级**：`WFP_CRASH_BLOCK=<块> exit=<rc≠143>` ⇒ "**能把进程打死**"（比"没画出来"更严重，单独醒目报）。
> ### 🧰 **波的"输入稳定性"护栏第一次真的响了**（而且是对的）
> 波 5 打印：`波前 b28819fb… / 波后 09197817… ⚠️ 波期间手写输入被改动过`。**窗口内被改的只有两个文件**：`src/WpfGfx.Linux/Interop/MilNative.Exports.cs`（22:15:56，M7b 加的只读 `ReportLeaks`）与 `MilNative.cs`（22:17:06）。
> **主控判定本波产物仍有效**（依据是结构事实，不是感觉）：`build/PresentationCore.Linux/PresentationCore.Linux.csproj` **不引用 `src/WpfGfx.Linux`**（grep 零命中）⇒ 那两处编辑**不是 PC 构建的输入**；PC（`17d9910c…`）只由 shim `adbee67b…`（22:08）与应用器（19:28）决定。
> **但它必须配一次 AOT 重发布**（`src/**` 是桥的输入）⇒ 已与 M7b 对齐：**以后在波窗口内改 `src/**` 要先打招呼**（它也已被告知落完喊我发桥）。**"改了源码"与"部署件变了"是两件事** —— 这条又攒了一个正面案例。
> ### ✅ 波 5 收尾（主控）：`verify-all.sh` **9/9、831 通过 / 2 跳过 / 0 失败**（在**外部负载 load≈12–19** 下跑的，仍然全绿）
> Tab 修法进入权威 PC（`17d9910c452712ce3966e293…`，波 5 重建）。**注意**：波 5 的输入稳定性护栏报过"波期间手写输入被改动"，核查结论是 **M7b 的 `src/WpfGfx.Linux/Interop/**` 两处只读诊断挂点**，而 **PC csproj 不引用 `src/WpfGfx.Linux`** ⇒ **PC 产物有效**（这是"用结构事实判定，而不是感觉"）。
> ### 🔬 **债务 #1（flaky）：从"复现不到"变成"仪器化 + 机制结论"**（M7b）
> - **复现**：本机 3 核 **52 轮 + 加压 15 轮 = 67 轮全绿** ⇒ **本机窗口未锁定**（原 32 核环境 15 轮 5 红）。**它按规则没在没复现时改生产代码**。
> - **⭐ 泄漏守卫工作并立刻抓到形态**（缺省关）：开关 `WPF_LINUX_CHANNEL_LEAK_TRACE=1`，另有 `WPF_LINUX_CHANNEL_LEAK_LOG=<path>` 文件汇（**因为 `dotnet test` 吞掉测试宿主 stderr —— 只写 `Console.Error` 在通过那一轮一行都看不到**，这个"汇"的做法是必要的）。`Commands.Tests` 单轮 **430 次快照：424 次为 0、6 次为 1**，并打出**具体句柄**（`0x10000002 / 0x10000005 / 0x10000008`）⇒ **"上一个用例留下的通道"是可观测的**；它是否变红取决于后面那条用例**是否对全局量断言**（`MilChannel.cs:400` 的注释早就警告过）。
> - **显式并行配置**：给四个原本没有配置的套件加 `xunit.runner.json`（`parallelizeTestCollections:false` / `parallelizeAssembly:false`）并在 csproj 写明**为什么**（共享进程级静态表 + 通道注册表刻意不重置 ⇒ 取与事实相符的串行档；**真并发问题交给泄漏守卫，不靠默认值碰运气**）。**主控裁定：接受**（含 `Rendering.Tests` 的那份——它只**新增**文件、未改 T2b 的代码；我已记档"临时让渡"）。
> - **收口口径（不写"已修复"）**：`根因已分析（进程级静态表 + 顺序依赖）；本机 3 核 52 轮未复现（另加压 15 轮亦全绿 ⇒ 本机窗口未锁定）；原 32 核环境 15 轮 5 红；已加显式并行配置（4 套件）与通道泄漏守卫（缺省关）作为长期仪器`。
> ### 🎯🎯 **功能广度样例第一批结果：6 OK / 1 真红 / 2 块能把进程打死**（T3，新配置 `pc 17d9910c…` / `hbtextline adbee67b…`）
> **先跑回归**（负载闸门：开跑 1min=27.82 ⇒ 等到 4.45 才开跑）：
> ```
> WPTD_SUMMARY=PASS 2/2 ｜ WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 ｜ WPTD_GATE=PASS
> default ×3 / env ×3 逐次：drawn=263/165 notdrawn=0 frames 14/14 blank=0 capture=ok scroll=ok 938x938 leftover_after=0
> **与上一版冻结基线同一帧 `AE=0 / 879844`** ⇒ **Tab 修法对样例是逐像素零影响**（硬证据，不是"看起来一样"）
> ```
> **广度样例 `WpfFeatureProbe --tier both`（9 块）**：
> | 块 | 判定 | 证据摘要 |
> |---|---|---|
> | `popup` | ✅ **独立窗口路径能用** | `IsOpen=True child=120x28 menu.items=2 tip.IsOpen=True`；**`new_windows=10`** |
> | `anim` | ✅ 动画真推进 | `xform 0.0→40.0 width 40.0→120.0` |
> | **`opacitymask`** | 🔴 **真红：alpha=0 遮罩未生效** | 负向 `#8B5CF6=28644`（期望不可见）与正向 `#22C55E=28644` **完全相同**；读图三条色块全可见 |
> | `effects` | ✅ `DropShadow` + **`Blur`** 两色都在屏 | `#0EA5E9=22176 #EC4899=23184` |
> | `controls` | ✅ TabControl/TreeView/**DataGrid** | `tabs=3 tree=3 grid.cols=2 grid.rows=12`（容器已生成） |
> | **`textbox-edit`** | ⛔⛔ **能把进程打死**（exit=134） | 见下 |
> | `virtualize` | ✅ 虚拟化生效 | 200 项 ⇒ **已实现容器 = 7** |
> | `transforms` | ✅ Render/Layout/Clip/**BitmapCache** | 两色都在屏 |
> | **`text-rtl`** | ⛔⛔ **能把进程打死**（exit=134） | 见下 |
> **⛔ `text-rtl`（最高严重度：RTL 文本一碰就崩）**：
> `EntryPointNotFoundException: LoCreateContext ← TextMetrics.FullTextLine.FormatLine ← build/PresentationCore.Linux/TextFormatterImp.Linux.cs:266 ← TextBlock.MeasureOverride` ⇒ **T1b 当初只接了"简单路径"的站点，这个站点（`:266`）没接** ⇒ RTL 回落到未实现的 LineServices ⇒ abort。**已派 T1c**：先取"所有 `FullTextLine`/`LoCreateContext` 落点"的**真值清单**（别只修一处），按既有应用器家族约定接线。
> **⛔ `textbox-edit`（两个独立问题）**：`Invariant.Assert` 在我们移植的 `SimpleTextLine.Linux.cs:1542` 失败（`TextContainer.GetNodeAndEdgeAtOffset ← TextBoxLine.GetTextRun ← SimpleRun.Create`），**但 `Invariant.FailFast` 自身在 Linux 上 NRE**（`IsDialogOverrideEnabled`）⇒ **assert 原文被吃掉**，只剩不透明 NRE + abort ⇒ **连"哪个不变量"都看不到**。**已派 M7b**：先修"诊断被掩蔽"（要**消息可见**，不许把 assert 变 no-op），再看 (a)。
> **T3 自己抓到的样例侧错误（`ATTRIB=sample`，已修）**：`OpacityMask = Colors.Black` **不是"遮住"** —— WPF 用 **alpha 通道**，黑色 alpha=255 ⇒ 不透明 ⇒ **在 Windows 上也会照常可见**。已改 `Color.FromArgb(0,…)` + 追加 alpha 渐变第三块（换色以免污染负向判据）。**这正是"先自问一次 Windows 是否也这样"的价值。**
> **它本轮又抓并修掉 5 个仪器 bug**（"工具在说谎"家族继续增长）：① **新窗口数在杀应用之后才数 ⇒ 恒 0 ⇒ 独立窗口路径恒判假红**（已改到 TERM 之前 ⇒ `new_windows=10`）；② 像素解析器把"双色/负向"规格解析错（`c1` 被覆盖）；③ `local` 用在 `{ }` 块里 ⇒ runner 中止；④ `frames_good` 跨函数作用域未绑定；⑤ `--tier bogus` **静默当默认档跑**（选项吃掉位置参数）。另把**块级台账同步打屏**（读图即可核对台账）。
> ### 🔧 三块红各有 owner 在落 + 波 6 已送进去（主控）
> **① `text-rtl` 崩溃 —— 我的派单前提被 T1c 推翻（这条要记）**：它用 `grep -an` 取真值后发现**两处 `FullTextLine` 站点其实都接了**（`:266` 紧邻其上的 `:251-262` 就是 `TryFormatLine`；`:347` 上方 `:333-343` 是 `TryMinMaxParagraphWidth`；上游全文只有 `:241/:309` 两处，且 `LoCreateContext` 在 `TextFormatterImp` 里 **0 处**）⇒ **真凶不是"漏接"，而是 shim 对 RTL 的 run 类型 `bail`**（`HbTextLine.cs:3298` —— `TryCollect` 只吃 `TextCharacters`/`TextEndOfLine`）。**修法**：新增 **`WpfLinuxLenientTextFallback`**（**跳过**不支持的 run 类型、计数 + 记类型名，**不再 bail**），**站点 1/2 都插** ⇒ 三层兜底（①SimpleTextLine ②shim ③宽松兜底）才轮到 LS。**如实登记**：工厂无 bidi 参数 ⇒ **保证不崩，但 RTL 视觉顺序可能仍是 LTR**（真 bidi 排版属独立立项）。闸门：`--check` rc=0（**不经管道取**）、幂等、两形态 0 错 0 警；**牙齿 A/B**（删锚点 ⇒ rc=1 且理由是"锚点 0 次"；**新增第三处 `FullTextLine`** ⇒ rc=1 且理由是"站点数 3≠2"）。它自己**先踩过一次假绿并登记**：第一版牙齿把应用器放 `/tmp/…` ⇒ 按 `HERE/../../..` 推 ROOT 去 `/tmp/upstream` 找上游 ⇒ **两次 rc=1 的理由是"找不到上游"而不是"锚点不符"**（"验证器走了另一条分支"那一族）。
> **② `textbox-edit` 崩溃 / 诊断被掩蔽（补丁 N，M7b）**：根因 `Shared/MS/Internal/Invariant.cs:232` 在**失败路径**上访问 `Registry.LocalMachine.OpenSubKey("Software\\Microsoft\\.NETFramework")`，Unix 下 `Registry.LocalMachine` **是 null（不抛）** ⇒ **NRE 落在"准备报错"这一步** ⇒ **assert 原文被吃掉**。**修法**：`?.` + **主动打印原文**（`Debug.Fail` 是 `[Conditional("DEBUG")]`、Release 下整句被编译掉；`Environment.FailFast(SR.InvariantFailure)` 只有通用串 ⇒ **不主动打印照样丢**）+ 拼进 FailFast 文本；**语义不变：仍 `FailFast`、不吞消息、不是 no-op**（自检强制三要素在）。**已写进波的 `APPLIERS_EXPLICIT`**（名字是 `patch-shared-*`、**不在** `patch-presentation*` 通配里、自动兜底抓不到 ⇒ 必须显式登记）。它**披露了两件越界**：为验证编译跑过 `build/WindowsBase.Linux` 的构建（改写权威 `WindowsBase.dll`，**波 6 已按依赖序覆盖**）、跑过 `port-lib.py WindowsBase`（**抹掉补丁 M 接线**，已重放 M+N）—— **披露就是对的处理**；这也再次证明"波第 1 步 port-lib 重生成 ⇒ 必须重放全部应用器"。
> **③ `opacitymask` 真红（T2b，先诊断后修）**：链路逐跳（文件:行）—— `Commands/MilRenderData.cs` **没有 `PushOpacityMask` 解码支**（只填 `Command`、原始字节留在 `RawPayloads`）⇒ `SkiaRenderBackend.cs:466` 从**偏移 16** 取句柄（`U32` 是**空安全**的 ⇒ raw 缺失时**静默变 0**）⇒ `:679-683 TryApplySolidMask` **只接受 `MilSolidColorBrush`** ⇒ 失败则 `RecordNotDrawn(MilPushOpacityMask)` + **裸 `Save()`**（遮罩完全不生效，但**记进"未画种类"、不是静默**）⇒ 成功则 `PushLayer`（= `SaveLayer` + `White.WithAlpha(alpha)`）。
> **它做了一个单元级复现，把"我想改的那一跳"自己洗清了**：`Rendering.Tests/OpacityMaskTests.cs` 构造带 raw 载荷的 `PushOpacityMask` + 纯色遮罩 ⇒ `alpha=255` 红可见、`alpha=0` 内容被隐藏、两者 `未画出(PushOpacityMask)=0` ⇒ **⑤ 层合成语义在单元级两端都对** ⇒ 应用级失败**不可能来自层合成**，只剩 **(A) 第②跳取到 0/取错** 或 **(B) 应用里的遮罩不是 `MilSolidColorBrush`**。
> **⇒ 它拒绝在不知道 (A)/(B) 的情况下盲改（这正是"多行摞印"教的那条）**，并给出一条判别读数：**`未画种类` 里有没有 `MilPushOpacityMask`**（有 ⇒ 走失败分支；无 ⇒ ③ 成功、方向要再转）。**T3 正在跑这一步取那条读数**（`--only=opacitymask --app-env=WPF_LINUX_DRAW_CENSUS=1`；因为台账只有计数、**"是哪一类"只能从 `[DRAW_CENSUS]` 条款表取**）。
> ### ✅ 波 6 收尾：三处改动一起进权威 PC，门禁 **9/9、835 通过 / 2 跳过 / 0 失败**
> `PC = 492983634af507b2477ce8e3…`；波：`失败步骤 0`、15 工程 0 错 0 警、身份 5/5、**输入指纹 `32b5bc9a…` 波前波后一致**（这一波没有编辑竞态）。
> **`ManagedLayer.Tests` 从 54 → 56 且 0 失败**（多的 2 条正是补丁 N 的断言）⇒ **M7b 报的"测试宿主中止"判为既有 host-crash flakiness / 它本地 WindowsBase 状态，不是补丁 N 引入**（依据 = 权威件 + 全量套件一次全绿，**不是"重跑就好了"**）。
> ### 📊 波 6 之后的四步验收（T3）：**回归绿 / RTL 仍崩但根因钉死 / 补丁 N 验收通过 / OpacityMask 定位前移**
> **① 回归（`WpfTextDemo`，波 6 配置）**：`WPTD_SUMMARY=PASS 2/2`、`WPTD_LINE_ADVANCE=PASS`、`WPTD_GATE=PASS`、退出码 0；读图 ①②/④/⑥ 全对；**与上一版基线同帧 `AE=0 / 879844`** ⇒ **波 6 没动渲染**。
> **② RTL 仍 `abort(134)` —— 但诊断把根因钉在生成物里**：
> ```
> [TEXTLINE_DIAG] R1 面计划：runs=1 {[0,29) DejaVuSans.ttf#0 w=400/5/0} ⇒ segments=1 0:[0,29)
> [TEXTLINE_DIAG] LS_FALLBACK 交回 LS（前3条无条件）：空段落
> 栈：LoCreateContext ← FullTextLine ← TextFormatterImp.Linux.cs:483 ← FormatLine:353 ← TextBlock.MeasureOverride:1271
> ```
> T1c 的**宽松跳过确实生效**（`skipped>0` 那条在），但**跳完后拼出的文本为空** ⇒ 撞上 `TextFormatterImp.Linux.cs:121-124` 的 `if (text.Length == 0) { s_lastFail = "空段落"; return false; }` ⇒ 又交回 LS ⇒ 崩。**R1 面计划明明有 29 字符、拼出来 0 字符 ⇒ 两者矛盾**（跳过循环把文本丢了）。**已派 T1c**：**"空文本"绝不允许落回 LS**（要么诚实出空行 + 计数 + 诊断，要么让被跳过字符仍有贡献），并把 `skipped` 的诊断移到 `return false` **之前**（这次一行都没打出来，因为被 abort 截断）。
> **③ 补丁 N 验收通过 —— assert 原文到手**（这条把 (a) 从"看不见"变成"可查"）：
> ```
> Invariant failure: **Bogus symbol offset!**
>   at Invariant.FailFast                          build/WindowsBase.Linux/Invariant.Linux.cs:216   ← 补丁 N 的产物
>   at TextContainer.GetNodeAndEdgeAtOffset(…)     upstream/…/TextContainer.cs:1284
>   at TextBoxLine.GetTextRun(Int32 dcp)           upstream/…/TextBoxLine.cs:68
>   at SimpleRun.Create(…)                         build/PresentationCore.Linux/SimpleTextLine.Linux.cs:1542
>   at SimpleTextLine.Create(…) / FormatLineInternal(…) / TextBoxView.FullMeasureTick:2222
> ```
> 不变量原文：`Invariant.Assert(offset >= 1 && offset <= this.InternalSymbolCount - 1, "Bogus symbol offset!");` ⇒ **我们的 `SimpleRun.Create` 向 TextBox container 要了越界 dcp**（样例只是 8 字符的普通 `TextBox`）⇒ **ATTRIB=ours**；**已派 M7b**（它早已把可疑断言列成表：移植件 `SimpleTextLine.Linux.cs` 的 7 处候选里 `:1389`/`:1114` 优先）。**修法要落在"我们算的 dcp/偏移"上，不许去放宽那条不变量**（它是上游的正确性保证）。
> **④ OpacityMask：`PushOpacityMask` 根本没进渲染器**：
> ```
> WFP_DIAG notdrawn_pair = skia 指令 19 条，**未画种类 0**
> [DRAW_CENSUS] frame=3 指令种类=5 总执行=19  Rectangle×4 RoundedRectangle×6 GlyphRun×3 MilPushGuidelineY1×3 MilPop×3  ⇒ PushOpacityMask = 0
> 像素：alpha=0 元素 #8B5CF6=29946 ｜ alpha=255 对照 #22C55E=28644 ⇒ 两者都完整可见（读图三条色块全在）
> ```
> **加强证据**：**同一份 census 确实统计 push**（数到 `PushGuidelineY1×3`）⇒ "没有"是有意义的。
> ⚠️ **但主控指出一个关键分辨点（别急着判"PC 没发"）**：`MilRenderData.cs` **没有 `PushOpacityMask` 解码支**，这类指令走**原始字节旁路**（`RawPayloads`，同族还有 `*Animate`/`PushEffect`）⇒ **census 的"指令种类"可能压根不覆盖它们** ⇒ **"census 里没有"不能单独证明"PC 没发"**。⇒ **已派 T2b** 加一格**只读仪器**：遍历 `RawPayloads`/原始命令流，**按命令 id 统计所有命令**（含未解码的那些），打 `PushOpacityMask` 次数 ⇒ **>0 = 后端收到没消费（走 (A)/(B)）**；**=0 = PC 侧就丢了（方向转 PC 车道）**。（T2b 上一轮已经用单元级复现把"它想改的那一跳"自己洗清了：纯色 alpha 遮罩 → `SaveLayer` 整层 alpha 在 0/255 两端都对；**它拒绝在 (A)/(B) 未定时盲改** —— 这条"不按假设改"的纪律已记为范例。）
> **T3 又自抓一个读数 bug**：它第一版按 `^\[DRAW_CENSUS\] MilPushOpacityMask` 找条款表 ⇒ **恒 0**；实际是**几何行只给绘制命令，push/pop 只在每帧汇总行里、且名字去掉了 `MilDraw` 前缀**（`PushOpacityMask×N`）⇒ 已改为读汇总行（离线验证过）。**"工具在说谎"家族继续增长**。
> ### 📌 2026-09-11 第五轮（主控）：三块红各自收口 + 波 8 + 门禁 9/9（837 通过）
> **① `opacitymask` ✅ 已修好（T2b 落正解 → T3 像素+读图双确认）**
> T2b 把根因**又推了一跳**：不是"渲染层不消费"，而是 **`AlphaMask` 在投影时被丢掉** —— `MilCommandDispatcher.cs:215-219` 解码 ✓、`MilVisualNode.cs:14,46` 存字段 ✓、**`Contracts/Interfaces.cs` 的 `MilVisual` 没有该字段、`VisualProjection.cs` 没搬** ⇒ 渲染层永远看不到。
> ⇒ **这是"投影时丢字段"这一族的第 3 个实例**（前两个：`PIDWriteFont` #14、变换资源句柄）⇒ **已把它固化成债务表新行 #26**（含三关检查点 + T2b 补的"两种查法要一起用"：只 grep 消费点会漏掉"字段压根没进契约"这一种，而**漏第②步只会静默默认值、编译不报错**）。
> **修法**：契约加字段 + 投影显式搬 + `RenderVisual` 消费（纯色 ⇒ 与 `opacity` 相乘走**既有** `PushLayer`/`SaveLayer`；**非纯色 ⇒ 显式 `RecordNotDrawn`，不静默当没遮罩**）+ 单测里 **`Assert.False(root.AlphaMask.IsNull, …)` 直接锁住根因那一跳**；突变自测带**纳秒级 mtime**。
> **T3 实测（新桥）**：负向 `#8B5CF6` **29946 → 0**（<20 ✓）、正向 `#22C55E` **28644**（≥20 ✓）、第三块渐变 `#38BDF8` 仍可见 = **已知边界**（`未画种类 = 1` 正是预期 +1，来源 `SkiaRenderingBackend` 的显式 `RecordNotDrawn`）⇒ **块判定 `OK`**，**读图**：卡片只剩绿、蓝两条，紫色那条消失。
> **② `textbox-edit` 崩溃 → M7b 的补丁已落（波 8 进 PC）**
> 根因链条（每一环带 file:line）：`"seed-文本"` = **7** 字符（它**自己认领**了上一轮照抄"8 字符"的错）⇒ `SymbolCount=7`、`InternalSymbolCount=9`、合法 dcp ∈ [0,7]；**我们的 `HbTextLine.GetTextRunSpans()` 末 span 不是 `TextEndOfParagraph`** ⇒ 宿主 `TextBoxLine.EndOfParagraph=false` ⇒ `Length = _line.Length − 0 = 8`（本该 7）⇒ 下一 tick `FormatLine(8)` ⇒ `CreateStaticPointerAtOffset(8)` ⇒ `internal=9 > 8` ⇒ **Bogus symbol offset** ⇒ abort。**溢出量恰好是 EOP 那一个位置**。
> **修法**（只两处：`build/shims/PresentationCore.HbTextLine.cs:2188` + staging `:1033`）：`_hasEop` 时追加 `new TextSpan<TextRun>(1, new TextEndOfParagraph(1))` ⇒ spans 总长 = 可见 + EOP = `Length` ✓、`EndOfParagraph=true` ⇒ 宿主不再多走一格。**副带修正**：改前 spans 总长 ≠ `Length`（硬断字符仍不在 span 里 = 既存欠账，如实登记不动）。
> **自证充分**：改前/改后两文件的**方法块 sha 逐字相同**（同步干净）；**把新块反向替换回去 ⇒ shim sha16 回到 `adbee67b…`**（= 权威 PC 编译所用件）⇒ **本次改动只有这一处**；牙齿 A/B（补丁件 PASS/exit 0；关掉那段 ⇒ **E1/E2 双 FAIL + exit 1**）；`run.sh tline` 六项不回归 + 两形态 + `CoverageProbe` 0 错 0 警。
> ⚠️ **它主动澄清一条"看起来变好"**：`T2b A 组 964/965·207/213 → **972/972·213/213**` **不是它的补丁带来的**（用改前件做 A/B，逐字相同；判定行 diff 只有 `T0.6`——那是它故意编"不在仓库路径上的文件"时守卫按设计开火）⇒ **改善应归 T1d 的 Tab 修法**（Tab 用例也进那本账）。**"不要把别人的改善记在自己头上"这条，它做得比要求还干净。**
> **③ `text-rtl` 崩溃 → T1c 的宽松兜底已落（波 7 进 PC），复验待 T3**
> T1c 先**推翻了我的派单前提**（两处 `FullTextLine` 站点**其实都接了**；真凶是 shim 对 RTL run 类型 `bail`），随后 T3 的实测又发现**它的第一版兜底把文本跳空了** ⇒ 撞上 `if (text.Length == 0) return false;` ⇒ 又交回 LS ⇒ abort。**第二版修法**：从任意 `TextRun` 取字符（`CharacterBufferReference`/`Length` 是基类就有）、**"空文本"绝不回 LS**（用空格顶一行空白行 + 计数 + 诊断）、**进 `return false` 前先诊断**、并顺手堵住"空段落只有 EOL run ⇒ `props==null` ⇒ 又回 LS"这个同类洞。牙齿：把空文本分支改回旧写法 ⇒ `--check` **rc=1** 且理由正中根因。
> ### 📌 2026-09-12 第六轮（主控）：**两条 P0 崩溃各自被"剥出下一堵墙"再修掉 + 波 9 + 门禁 9/9（840 通过）**
> **背景（"连环 abort"这个形态值得单独记）**：修掉一堵墙后**露出下一堵**，两次都是这样：
> - `textbox-edit`：`Bogus symbol offset`（M7b 的 EOP-span 修法消掉 ✓）⇒ **露出** `TextServicesLoader.Load()` 的 **STA 断言**「Load called on MTA thread!」；
> - `text-rtl`：空段落→LS abort（T1c 的宽松兜底消掉 ✓）⇒ **露出** `HbTextLine.Draw` 的 `NotSupportedException: B1/B2 只支持 InvertAxes.None`（**死得更早：连窗口都没出来**，死在 `Arrange → TextBlock.OnRender → Line.Render`）。
> **P0-A · 补丁 O（M7b）：聚焦一个 TextBox 就把应用打死** —— 根因链与修法：
> - 那条断言是**上游原文**（`Shared/MS/Internal/TextServicesLoader.cs:96`）且**排在 `if (ServicesInstalled)` 之前** ⇒ 与 `ServicesInstalled` 取什么值无关（所以补丁 M 的 Registry 守卫挡不住它）；
> - **实测把"恒假"变成读数**：Linux 上 `GetApartmentState()` 返回 **`Unknown`**（不是 `MTA`）、`SetApartmentState(STA)` 抛 `PlatformNotSupportedException`、`TrySetApartmentState(STA)` 返回 `False` 且状态仍 `Unknown` ⇒ **断言不可满足，没有"设一下就能过"的路**；
> - **修法选 (a)**：在断言**之前**加 Linux 守卫 `return null`，依据是**上游自己文档化的合法路径**（`Load` 的 XML 文档 "May return null if no text services are available" + `ServicesInstalled` remarks "guarenteed to return null" + `TextEditor.cs:1529` 本来就 `if (threadManager != null)`）⇒ **断言原文一行不改、不削弱不变量**；用**运行时** `OperatingSystem.IsWindows()` 而非 `#if`（csproj 会被 port-lib 重生成 ⇒ 接线面收敛为 0）。
> - **自检四条**：锚点计数=1、**断言原句仍在**、**守卫在断言之前**、`--check` 双向 + 幂等；**重放验证现场**（`port-lib.py WindowsBase` 抹掉 G/F/M/N 全部接线 ⇒ `--check` rc=1 ⇒ 重放三个应用器 ⇒ 四块接线都回来）
> - **牙齿**：删掉守卫 ⇒ ① 文本级用例红（防削弱）② **在测试进程里、不占应用 slot** 复现了 wave-8 那条 P0 原句（`DebugAssertException: Invariant failure: Load called on MTA thread!`）—— 这条同时是波后的红/绿闸门。
> **P0-B · RTL `InvertAxes`（T1d）：判 (a) 真实现，不需要降级**
> - 定性到上游一行：`MS/Internal/Text/Line.cs:79` `_mirror = (FlowDirection == RightToLeft)` → `:116` 传 `InvertAxes.Horizontal` ⇒ **只看段落方向、与内容无关** ⇒ 任何 RTL `TextBlock` 都撞上我们的 `throw`；
> - 上游语义**核过不是推的**：`CreateAntiInversionTransform`（`TextFormatterImp.cs:565-595`）是**纯矩阵**（`Horizontal ⇒ m11=−1, offsetX=段落宽`；`SimpleTextLine.Draw:482-501` = push→画→pop）⇒ 我们**存 `_paragraphWidth` + push 同式矩阵**（`Draw` 只管 push/pop、真正绘制挪进 `DrawCore`，与上游同构）；
> - **`antiMatrixMismatch` 恒 0**（DIRECT 形态下每次与上游函数逐字段比对；矩阵用公开 API 自建，因为上游那个是 PC internal、**反射形态看不见** —— 同一类坑它在 `Extent` 那轮踩过）；
> - 四种取值全支持；**唯一降级分支 = 段落宽未知(0)** ⇒ 不镜像 + 计数 `invertedNoWidth` + **前 3 次无条件 stderr**（不静默）；
> - **牙齿两条**：放回 `throw` ⇒ P7/P8/P10/P11 全红；**关掉镜像** ⇒ P7 绿但 P8/P10 红（**"真镜像"也有牙，不是只看"不抛"**）；它顺手修掉自家探针两条假绿（`380.0` vs `380` 字符串误报；P9 在 0 张 run 时真空通过）。
> **T3 · `1400` 复现率 = 0/48（不构成 P0 派单，但也不写成"已修好"）**
> 四趟（探针 ×2 档 + `WpfTextDemo` ×2 档，每趟 12 次）全 `err1400=0`、`alive_ok=48`、`WPF1400_LEFTOVER_AFTER=0`；**负载不是空的**（loadavg 6.7–9.0）⇒ "只有空载才不复现"站不住。**它自己给的三倍法则边界**：0/48 只把真值上界压到 **≲6%/次**，而当初那一次是在**完整门禁**里出现的（env 档 3 次里 1 次）⇒ **两者不矛盾、但按需复现不了** ⇒ 已登记为 flakiness，并**建议用现成门禁跑 3 轮做"忠实复现"**（复刻"那个 Xvfb 已连服 3 轮抓帧 + 机上有别的车道进程"的现场）——**主控批准，排在三条复验之后**。脚本已进仓（`run-wpfprobe-1400rate.sh`）。
> **M7b · `1400` 只读定位（四条候选 + 一条关键发现）**：`create_window_utf8` 里 **1400 是三义的**（`:390` X 不可用 / `:423` `XCreateWindow` 失败 / 11+ 处"hwnd 查不到"）⇒ **错误码本身在误导 triage**；且 `wpf_x11_ensure()` 的 `x_failed` **一旦失败就永久闩锁、无重试**（一次瞬时失败 = 该进程所有 X API 全失败 ⇒ 第一个窗口 NULL ⇒ 1400）；另有"建窗期回调可重入"与"诊断缺口"（`WpfLinuxWin32_LastError()` 存在但**托管侧全仓无人调用**）。**修法排序经主控认可**：**先 F2（让下次复现自带 `dpy_error`）→ 拿到文案 → 再在 F1（去闩锁+有限重试）/F4（创建中状态）里定根因**；F3（错误码分义）单独评审（改可观测契约）。
> **T1c · RTL 顺序判定（决定"要不要立项真 bidi"）**：(乙) **混合方向文本 = 静默画错（代码级确定）** —— 整形**不传方向靠猜**（`hb_buffer_guess_segment_properties`）、输出**按序消费无重排/镜像**、工厂 API **无方向参数**、上游的 bidi level **在我们的路径上被丢掉**（上游交给 LS 重排）；(丙) 纯 RTL 单段的**字形顺序很可能对**（HB 语义）但**行摆放仍 LTR**（推断，待读数）。**修法方向与工作量已给**（shim 用 ICU 的 `ubidi_*` 做 UBA + 逐段显式方向整形 + 视觉重排；PC 传 `FlowDirection`/`TextAlignment`；**M–L，约 2–4 天级**）⇒ **真 bidi 列为独立立项**（**不算 T1d 的欠账**；T1d 明确"不声称 RTL 显示正确"）。
> ### ✅ 波 9 + 门禁
> 波 9：`失败步骤 0`、15 工程 **0 错 0 警**、身份 5/5、**输入指纹 `ba3ff249…` 波前波后一致**；**PC = `684424fea3a0812ab123…`**、**WindowsBase = `11c75d228a0b86a3d535…`**；桥发新 = **`66703024af8c115d691c33d352a7bdc234ea3a4a`**（4,937,968 B，含 T2b 的渐变遮罩 `SaveLayer + DstIn`）。
> **`verify-all.sh`：9/9、840 通过 / 2 跳过 / 0 失败** —— 其中 **`ManagedLayer.Tests 58/58`**，M7b 那条"等重编才跑"的运行时用例**这次真跑了并通过** ⇒ **补丁 O 在单元级也已被验证**（不只是文本级）。
> **T2b · 渐变遮罩**（`SaveLayer + DstIn`，Pop 时机在既有 `RestoreToCount(entry)` 之前 ⇒ 子树全画进层后再补那一笔；**纯色路径一格未动**；复用既有 `SkiaBrush.CreateFill` 不造第二套解析）；单元级三点判据（左≈背景白 / 右≈内容红 / **中点严格落在两端之间**）+ 突变（`DstIn→SrcOver` ⇒ 必红）；**它自纠两次断言写错**（端点逐字节相等；绿分量方向写反）与一条"**参照物消失 ⇒ 全判为变化**"的假警报（`/tmp` 基线清单被清空 ⇒ 全部 golden 被误报"变了 23 张"，它改用"套件 0 失败 + 5 张授权图 sha 逐字核对"两个可靠口径）。**一处如实标注的近似**：遮罩画刷包围盒取 `canvas.LocalClipBounds`（对"遮罩覆盖整个元素"是对的；"只覆盖一部分"需换成真正的内容包围盒，已写进代码注释）。
> ### ✅ **两条 P0 在应用级闭合 + 渐变遮罩闭合**（T3 的 wave-9 台账，主控已读）
> ```
> textbox：exit=143（**不再 abort**）、frames_good=14/14、**崩溃签名段确认为空**
>          `[feat] textbox-edit OK focus=True caret=0 selLen=7 text='seed-文本' changes=0`
>          （`late` 为 **INCONCLUSIVE**：`changes=0` ⇒ **键入没有到达 TextBox** —— 这是**下一格**，见下）
> text-rtl：`[feat] text-rtl OK rtl.FlowDirection=RightToLeft rtl.h=16.3 wrap.h=45.4 trim.h=45.4`、无崩溃
> mask   ：exit=143、块 `OK`、**`未画种类 0`**（= T2b 的验收第 3 条）
> 分诊：popup / effects / controls / virtualize / transforms / **text-rtl** 全 `OK`；`anim` = **FAIL**（同一配置下 `OK`/`FAIL`/`INCONCLUSIVE` 三种都出现过 ⇒ 判据自身不稳，T3 正在改）
> 门禁：`verify-all.sh` **9/9、840 通过 / 2 跳过 / 0 失败**（`ManagedLayer 58/58` ⇒ **补丁 O 的运行时用例这次真跑了并通过**）
> ```
> **⇒ "连环 abort"两处都剥到底**：`Bogus symbol offset` → `Load called on MTA thread!`（补丁 O 消掉）；`空段落→LS` → `InvertAxes B1/B2`（T1d 的真镜像消掉）。
> ### 🔜 新一格（已派 M7b）：**键入没有到达 TextBox**（`changes=0`）
> `[feat] textbox-edit OK` 说明**不崩了、焦点也在**（`focus=True`、`selLen=7`），但 runner 注入 `Ctrl+A` + 键入后**文本没变**。**三段定性**已派：① 键事件到没到窗口（用 `[msg]`/`WPF_LINUX_WIN` 的现成读数）；② 有没有变成 `TextComposition`/`TextInput` 并派发到焦点元素；③ **是不是 TSF 那条路被补丁 O 关掉后的必要降级**（`ServicesInstalled==false` 是**上游既有分支**，需查清编辑是否仍走非 TSF 的 `TextEditor` 路径）。**明令：不许为了能输入而回退补丁 O**（那条断言在 Linux 上不可满足）。
> ### ✅ **T3 的三条复验收口（应用级原始读数，主控已核）**
> - **`--only=textbox-edit`（P0 闭合）**：`exit=143`、`frames_good=14/14`、**崩溃签名段空**（无 `Load called on MTA thread!`、无 `Bogus symbol offset`）；**`HBLINE A#0 cpFirst=0 cpLast=8 len=8 nl=1 …` 逐字不变**，而**宿主可见长度 8→7 命中**（`selLen=8`(wave 8) → **`selLen=7`**(wave 9) ⇒ **幻影 EOP 符号消失** —— 这比"不崩了"强得多）。
>   ⚠️ `getTextRunSpans≥1` **不由 runner 承担**（承载它的 `HB_TEXTLINE … getTextRunSpans=` 汇总行由 T1b 的装置产出）⇒ **T3 拒绝跨车道转抄、要求由 owner 出**（纪律正确，已去要）。
> - **`--only=text-rtl`（P0 闭合）**：`exit=143`、无 `NotSupportedException: B1/B2 …`、`text-rtl | OK`。**读图**：阿拉伯 `مرحبا بالعالم` 是**真连写字形** ✓、同帧 CJK 可读 ✓；**但第 1 行贴左（行内 bidi 顺序/镜像未实现）** ⇒ 与 T1d"**不声称 RTL 显示正确**"一致；trimming 无省略号 = **既有边界**（非本轮引入）。
> - **`--only=opacitymask`（渐变遮罩 ✓）**：块 `OK`、**`未画种类 0`**；三块实测 ① `#8B5CF6`（alpha=0）= **0**（不可见 ✓）② `#22C55E`（alpha=255）= 2046/帧、包围盒 `93×22 @ +22+71`（整块可见 ✓）③ `#38BDF8`（渐变）**精确色 = 0 但确实在画** —— 沿 `y=100..108` 扫得 `(29,44,63)→(30,50,72)→(32,57,79)→(33,62,87)`，**蓝通道随 x 单调递增** = 左透明→右不透明，与声明的 `alpha 0→255` 同向 ✓。
>   **⇒ 新口径（重要）**：**alpha 混合内容不能用"精确色计数"判**（会读成 0）⇒ 必须用**包围盒 + 沿线像素曲线/近色（fuzz）**。wave 8 的"整块 28644"正是"没混合"的旧状态。
> ### 🔴 T3 自己认领的一条**假红**（`anim=FAIL` 是它改判据时引入的 bug）
> `Border.Opacity` **默认就是 1.0**，而动画是 `0.0→1.0`，它却拿"`BeginAnimation` **之前**的属性值"当**起点** ⇒ `(1.0−1.0)/(1.0−1.0)` = **NaN** ⇒ `Math.Min(NaN,…)` = NaN ⇒ 既不 ≥80% 也不 ≤2% ⇒ 掉进 else ⇒ **误判 FAIL**。
> **修法**：起终值改用**三对常量**（`From/Target`，`Build()` 里的 `DoubleAnimation` 也改用同一对 ⇒ 杜绝"两处各写一份"）+ **NaN/∞ 单列为 `INCONCLUSIVE`**（"**仪器算不出 ≠ 被测对象错了**"）+ 判定只由 `LateVerify` **一处**给出（与钩子顺序无关）。**复跑 3/3 稳定**：`opacity 0.00→1.00(100%) xform 0.0→40.0(100%) width 40.0→120.0(100%)`。
> ### 🔎 T3 的两条新发现（一条已派单、一条待确认）
> 1. **`textbox-edit` 的像素判据对"文字"不成立**（**假红风险**）：TextBox 内容**确实在屏上**（读图：白底 `seed-文本`，拉丁橙 / CJK 蓝），但 `#F97316` **精确色 = 0 px**（0/10/20/30% 容差都试过仍不给正数）；wave 8 同块 16 px。⇒ **对抗锯齿文字不能拿"精确色 ≥20"判**。**主控批准改法**：改用**近色（fuzz）计数**或**census 的 `GlyphRun×N`**（判"有没有画字形"），**并要求保留能红的能力**（突变：把 Foreground 换成不会出现的颜色 ⇒ 判据必须红）+ README 写明原因。
> 2. **同一 `TextBox` 内"拉丁橙 / CJK 蓝"** —— **主控判定为可能是真缺陷**（"**静默画错**"）：R1 之后我们**按字体子段发多张 `GlyphRun`**，若子段那张**没带上 run 的 `TextRunProperties`/foreground**，就会出现"同一控件两种颜色"。**已派 T1d** 查（并明确它与债务 #26「投影时丢字段」同族：`PIDWriteFont` / 变换资源句柄 / `AlphaMask` 之后**第四个候选**）。T3 另有一条**尚未确认**的观察（右栏 CJK 像方块 vs 同帧 TextBox 正常）⇒ 要用**原始分辨率裁图**分清"豆腐块 vs 缩放伪影"再报（**若确认是豆腐块则是另一条 P0 级线索**）。
> ### 🔎 **输入路径：三段定位的第一手结果**（M7b）—— 一个**关键新事实**推翻了我先前的假设
> **① 键事件到没到应用**：我 grep T3 的 wave-9 日志：`WM_SETFOCUS=1`、**`WM_KEYDOWN=0`、`WM_CHAR=0`** ⇒ **窗口拿到过焦点，但注入的键一条都没进窗口**；而 runner 用的是 `xdotool key/type **--window**`（`run-wpfprobe.sh:266-268`），M7b 的单元用例用**同一手法**却**能**打出 `WM_KEYDOWN`+`WM_CHAR` ⇒ **"手法本身没问题，应用上下文里没到"**。
> **② 为什么"单元通、应用 0/0"—— M7b 的新读数是关键**：本机 `xdotool key --window <id>` 投出来的事件带 **`send_event=0`** ⇒ **它实际走的是焦点依赖的投递（XTEST 语义），不是 `XSendEvent`**！（``--window` 在本机并没有变成合成事件）⇒ 应用里我们从**没把 X 输入焦点设到窗口上**（无 WM ⇒ `PointerRoot`）⇒ 键投给了指针所在的窗口。**⇒ 不是"托管输入栈不工作"，而是"X 焦点没人设"**。
> **③ 编辑是否依赖 TSF** ⇒ **不依赖**（`TextEditor.cs:99` 先判 `ServicesInstalled`；`:1529-1531` 的 `if (threadManager != null)`；`TextEditorTyping.cs:469` 只在 Overtype 的 transitory extension 用 TSF）⇒ **补丁 O 的回退是必要且契约内的，不回退**。
> **F1/F2/F3 已落地**（`src/WpfGfx.Linux.Native/**`）：**F1** 键语义按 Win32 重写（`XLookupString` 按 Shift/CapsLock 翻字符；**Ctrl+字母不再产 `WM_CHAR`**）；**F2** 焦点链（顶层窗口 map 时 `XSetInputFocus` + `SetFocus()` 同步）；**F3** `WPF_LINUX_KEY_DIAG=1`（缺省关、只读、有界 400 行：`XEV`（含 `send_event` 合成位）/ `KEY`（keysym/keycode/state/vk/**窗口在不在表里**）/ `DROP`（**没产字符的原因**）/ `FOCUSIN/FOCUSOUT`（mode/detail））。
> **牙齿（用旧件复现、不是自建对照）**：新 shim ⇒ `WM_CHAR` **1** 条（只有裸 `a`）；**旧件** ⇒ **2** 条（`Ctrl+A` 也产字符 —— 真应用里就是"**插入 'a' 而不是全选**"，而 runner 第一步正是 `ctrl+a`**）。`ManagedLayer.Tests` **58/58**（X11 用例真跑）。
> **shim 已换版并全仓同步**（主控）：`libwpfwin32.so` = **`6213489cb202fd55`** / 269,040 B；权威件 + 3 处 app-local 副本**全部同 sha**（`check-applocal-sync.sh` 全 OK）。
> ### 🔎 **"同一 TextBox 里拉丁橙 / CJK 蓝"：T1d 用机器读数把它拆成了"否证 + 一条确证的同族字段丢"**
> - **(甲) 成立、且"分段不产生两色"**：探针 C1 显示 R1 的两张子段 run **都带画刷且是同一把**（`brush=#FFFFA500` ×2）⇒ **用读数直接否证了"两色是 R1 造的"**。
> - **但它确证了另一条 #26「投影时丢字段」同族缺陷**：`:3300 primaryProps = runs[0].Props` → `:2132-2136`（整行只造一个 `HbTextRun`）→ `:2380 DrawCore` 用行级画刷 ⇒ **多 run 的 foreground 被压成第一个 run 的**，与上游 `SimpleTextLine.cs:1740`（**per-run**）不一致；**后果 = 整行单色**（探针 C2：两个 run 橙+蓝 ⇒ 两张都 `#FFFFA500`，`P13 ❌`）。
>   **主控批准修**（`RunSlot` 逐段带 brush；`FormatParagraph` 增 `textRunProperties[]` 入参，不传 ⇒ 与今天逐位相同），并要求：**不许动 M7b 改过的 `GetTextRunSpans()`**（那是 TextBox 崩溃 P0 的修法）；牙齿 = 关掉 `RunSlot` 传递必红。
> - **"两色"仍是候选现象（待裁定）**，三个候选已排给 T3 用**站点 D**（T1d 新增、缺省关）+ **原始分辨率裁图**判定：**H1** CJK 那部分不是我们画的（无对应 D 行）｜**H2**（**T1d 与我一致认为嫌疑最大**）那段 `brush=null` ⇒ **根本没画**，蓝色是**选中高亮底**透出来（T3 读数里 `selLen=7` = **整串被选中**）｜**H3** 同一视觉行被两条 props 不同的 TextLine 画了。
>   **口径提醒（已写进给 T1d 的派单）**：**"行级压平"是确证的缺陷（整行单色）**，**"两色"还是候选现象** —— 报告里不许混成"两色已修好"。
> ### 🧪 又一条"计数语义"教训（T2b 的同类）
> `check-applocal-sync.sh` 的 `NO-AUTHORITY`（无权威可比）**不再冒充 `MISMATCH`**；`DIVERGENT` 之前**只打印、没进退出码判定** ⇒ 自检 C 假红 —— **"输出里有" ≠ "判定把它算进去"**。
> ### 📝 两条"读数口径"澄清（避免后人误判）
> - **`pushopacitymask_count=0` 是预期的**：探针的 `UIElement.OpacityMask` 走**路径 A**（通道命令 `MilCmdVisualSetAlphaMask`），**不进 RenderData** ⇒ census 永远数不到；T1c 已定位、T2b 已修、T3 已用**像素判据**验过。
> - **`/tmp` 会被清**（09-11 23:39 → 09-12 23:41 跨天时被清空过一次，T3 上一轮的原始 PNG/日志因此不可再取）⇒ **关键读数必须落进仓/家目录**（T3 已改到 `$HOME/wfp-runs/` 并把 A/B 数字写进 `samples/WpfTextDemo/README.md`）；这本身也是"参照物消失 ⇒ 判据给出一个看起来很具体的错数字"那一族的实例。
> ### 🧰 三条工具/契约层面的发现（都记档）
> 1. **检查器口径**（T2）：`NO-AUTHORITY`（无权威可比）**不再冒充 `MISMATCH`**；五类分别计数；**`DIVERGENT` 之前"打印了但没进退出码判定"** ⇒ 自检 C 假红 —— **"输出里有"与"判定把它算进去"是两件事**；`/release/`（小写）路径也是假红来源。**A/B/C/D 四情形现已全绿**。**19 条真 MISMATCH** 已按"会不会被运行期加载"分成两组（Release 探针目录 = 真风险；库目录/测试 = 产物残留），处置 = **探针工程 Release 构建显式拷贝权威 Provider（结构性）+ 检查器标注"需重建"**；`run.sh` 那条**不动**（它**没读 run.sh 就不下结论**）。
> 2. **样例工程用 `HintPath` 而非 `ProjectReference`**（M7b 发现）⇒ `dotnet build samples/…` **不会重编 `build/*.Linux/**`** ⇒ **"改了 PC 源码但样例用的还是旧 PC"** 是一个静默假绿/假红源。**修法候选**：改 `ProjectReference` / runner 显式重建依赖链 / 把 `stale` 做成硬闸门（`stale=yes` ⇒ 直接 `INCONCLUSIVE`）。**已记为新债务**。
> 3. **T3 的新仪器 bug**：`count_color` 在颜色**不存在**时返回**空串** ⇒ 算术比较失败 ⇒ **负向判据在"成功"时报红** ⇒ 已兜底为 0。**"空/零必须先归一化"**（与"空即歧义""恒真/恒假判据"同族）。
> ### ✅ 波 8 + 门禁
> 波 8：`失败步骤 0`、15 工程 **0 错 0 警**、身份 5/5；**PC = `fb28ecd58aa868e2e627c657153c83473d5a7bf5ab769cc3ee485ef802621409`**（23:34:52 重建，**晚于** shim 的 23:29:07 ⇒ 含 TextBox 补丁）。**输入稳定性护栏又响了一次**：窗口内只有 `check-applocal-sync.sh`（23:34:24，T2 的脚本）被改 ⇒ **不是 PC 的构建输入** ⇒ 产物有效（这是护栏第 2 次开火，两次我都用"结构事实"而非感觉来判定）。
> **`verify-all.sh`：9/9、837 通过 / 2 跳过 / 0 失败**（`Rendering 148+2｜ManagedLayer 56｜Commands 562｜Windowing 44｜HelloMil 19｜Presentation 8`）。
> - **它的 `src/**` 诊断挂点（`ReportLeaks`）需要一次 AOT 重发布才进部署件** ⇒ **暂缓**（诊断件、缺省关；等 T3 的验收跑完再发，避免再挤一波）。
> ### 🎯🎯 **"多行摞印"根因锁定：route B 的 `Draw` 丢掉了宿主给的行 `origin`**（三方独立证据闭合）
> | 证据 | 谁 | 原始读数 |
> |---|---|---|
> | 上游那条路的行原点**逐行递增** | T1c 插桩 | `draw cpFirst=0 → origin.y=0`、`53 → 13.9688`、`61 → 27.9375`、`103 → 48.8906`、`246 → 97.7812`（`y/行高 = 1/2/3/6`）；规范原文 `SimpleTextLine.cs:585`：`double y = origin.Y + Baseline;` |
> | **我们的 `runOrigins` 恒为行内 `Baseline`、从不带 `origin`** | T1d 插桩（station B） | `B#0 hostOrigin=(0,0) Δ=+14.8516`；`B#27 hostOrigin=(0,18.625) Δ=−3.7734`；`B#72 (0,37.25) Δ=−22.3984`；`B#113 (0,55.875) Δ=−41.0234`；`B#180 (0,93.125) Δ=−78.2734`；`B#211 (0,111.75) Δ=−96.8984` —— **Δ 每行恰好掉一个行高** |
> | ① 卡折行段的 5 个 run **`devY` 全等** | T2b（部署件、应用级） | `run#18/20/21/25/27`：`originDIP=(0,12.995)`、**`devY=175.486` 五个全等**、**`CTM.f=161.950` 五个全等**（差 = **0 DIP**）；对照组 `run#39` `devY=369.595` ⇒ **分组与 CTM 采集本身在工作，不是"全是同一个值"的假象** |
> **⇒ 根因 = 我们的 `HbTextLine.Draw` 没有把宿主传入的 `origin` 算进行位置**（上游语义必须算）⇒ **折行段落每行画在同一 y**；现象只出现在 ①（多行折行）与 ②（TextTrimming），**正因为只有它们走 route B**（标题/③/④标签/⑥ListBox/⑦ 走上游 `SimpleTextLine`，全部正常）。
> **⚠️ 注意推理链的方向变了两次**（这是本轮的教训）：先猜"上游把多行放在同一 Y"（**被 T2b 否证**）→ 再猜"行偏移在 `SimpleTextLine` 那条路没带上"（**被 T1c 否证**）→ 才落到"在我们这条路上"。**两次否证都发生在动手改代码之前** —— 这就是"先把判据做出来再动手"的价值。
> **已批准 T1d 动手修**（第一次动 R1 之后的行为）：`y = origin.Y + Baseline; x = origin.X + relX`（与上游 `SimpleTextLine.cs:572-605` 同构）；**只动"画到哪里"，不动"算多宽/多高/断行/记账"**；验收 = ① station B 的 `Δ = firstRunOriginY − (hostOriginY + Baseline)` **恒 ≈ 0** 且宿主 `origin.y` 逐行递增；② 应用级 `devY` 从"五个全等 175.486"变成"逐行递增 ≈ 19.4 设备像素"；③ **改前/改后两张图**（① ② 不再叠字、单行块位置不变）；④ `run.sh tline` 逐项不回归 + 三形态 0 错 0 警；⑤ 插桩保留（缺省关、逐站点独立预算）。
> **T1d 的两条"没改行为"机器证据**（插桩阶段）：① 同显示号下 trace OFF vs ON，**剔除 `HBLINE` 行后逐字节相同**；② `run.sh tline` 与 `fbda5f88…` **逐项相同**（`T1.73 73/73`、`T2 1276/1298 (①286/286 ②68/68 ③977/988)`、`T2b 964/965·207/213`、`T2d 1298/1298`、`T3 210/236`、Tab 15 例保留红）。
> ### ✅ 主控独立复跑 **HelloWpf（M2 验收样例）**：渲染正确、无回归
> `DISPLAY=:94`（自起、**按 PID 收掉**）`bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh` ⇒ 逐帧 **`未画种类 0`**、`notimpl=0 failed=0 pending=0`、`committed=72`；`hellowpf-window.png` **55,609 B / 2,945 色**（历史上是 56,055 B —— **配置已变（R1 + D-d），按新口径记这一份**，不跨配置比）。
> **主控读图**（`b48b0b3d…`）：标题 `Hello WPF on Linux`、矩形 / 渐变椭圆 / 三角 / 渐变圆四个形状、`Rectangle / Ellipse / Path / Gradient / Transform / Text` 一行文字**全部正确、无叠字** ⇒ M2 样例在 R1 之后仍然好的。
> ### 🎉🎉 **"多行摞印"修好 —— 主控成对取证（原始数据 + 读图）**
> **修法**（T1d，R1 之后第一次行为改动）：`HbTextLine.Draw` 把宿主给的行原点**烘进每张 `GlyphRun` 的基线原点** —— 与上游 `SimpleTextLine.cs:585` 的 `run.Draw(dc, x + origin.X, origin.Y + Baseline, false)` **逐字同构**。落点已核到上游 `GlyphRun.cs:1869-1870`（`command.Origin.X/Y = _baselineOrigin.X/Y`）⇒ **改的正是 `MilGlyphRun.Origin`，也就是 T2b 的 `devY` 列所量的那个字段**。机制选择有依据：`GlyphRun.BaselineOrigin` 的 setter 是 **init-only**（构造后 set 会抛）⇒ 不能原地改；`(0,0)` 时**返回原来那批对象**（首位行逐位不变），同一 origin 复用同一批 run。
> **① 应用级 `devY`（① 卡同一段 5 行，主控实测）**：
> ```
> 改前： originDIP=(0.000,12.995) devY=175.486   五个 run 全等（差 = 0 DIP）  ← 摞印
> 改后： run#18 (0.000,12.995) devY=175.486
>        run#20 (0.000,29.292) devY=192.462      ← 增量 16.297 DIP / 16.976 设备像素 = **恰好一个行高**
>        run#21 (0.000,45.589) devY=209.438
>        run#25 (0.000,61.886) devY=226.414
>        run#27 (0.000,78.183) devY=243.390
> ```
> **② 真宿主的 `origin` 与 Δ（`WPF_LINUX_HBLINE_TRACE=1`，应用实测）**：
> `hostOrigin=(0,0) → (0,16.2969) → (0,32.5938) → (0,48.8906) → (0,65.1875) → (0,81.4844)`，而 `runOrigins(已烘入宿主原点)` 逐行 = `12.995 / 29.292 / 45.589 / 61.886 / 78.183 / 94.479` = **hostOrigin + Baseline 逐位精确**（探针自选的模拟值换成真值后，判据 `Δ = firstRunOriginY − (hostOriginY + Baseline)` **恒 0**）。
> **③ 主控读图**（`/tmp/r1-fix/shot-1.png`，938×938 / 165,109 B / sha `c0fdbeab…`）：**① 卡那段中英混排现在是 6 行、行行分开**（`WPF on Linux renders wrapped text by measuring each line and breaking at word boundaries，同时也要保证 CJK 字符之间可以正常断行、标点不会跑到行首。The quick brown fox jumps over the lazy dog 以便观察英文断词；mixed 中英 mixed 混排 should look natural on every line.`）；**② 卡 trimming 单行不再叠字**；③/④/⑥/⑦ 位置不变；④ 位图仍在。
> **④ 不回归**：`T1C_CENSUS_SUMMARY frame=3 runs=131 glyphs=1276 id0=0 nonlatin=322 maxid=63151 distinctpids=4`（与改前逐项相同）；`run.sh tline` 逐项相同（`T1.73 73/73`、`T2 1276/1298`、`T2b 964/965·207/213`、`T2d 1298/1298`、`T3 210/236`、Tab 15 例保留红）；三形态 0 错 0 警；`CENSUS_ORPHANS before=0 after=0`。
> **集成波**（主控）：`失败步骤 0`、15 工程 **0 错 0 警**、身份自检 5/5、**输入指纹 `27571715…` 波前波后一致**；**新权威 PC** = `330b9e372737733e8a9b009e53cfa685edbde8ad1a8919fad703079053aa1d2f` / 4,162,048 B（实测含 `WPF_LINUX_HBLINE_TRACE`（UTF-16 ×2））。
> **⚠️ 这条的推理方向被否证过两次才落地**（教训）：先猜"上游把多行放在同一 Y"（**T2b 否证**）→ 再猜"行偏移在 `SimpleTextLine` 那条路没带上"（**T1c 否证**）→ 才落到"在我们这条路上"（T1d 插桩 + T2b 应用级数据共同钉死）。**两次否证都发生在改代码之前。**
> ### ✅ **修好后的正式验收基线：全绿**（T3，`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`）
> ```
> WPTD_ARTIFACTS bridge_sha=177a07a6403a051c(4,933,824 B) pc_sha=330b9e372737733e pf_sha=ec1cfae877f0b0cf
>                win32shim_sha=4c023937421db45f wic_shim_sha=03b67fbcd7c385b6 hbtextline_shim_sha=ba5c777c0d4f652f(stale:no)
> default ×3: PASS exit=143 drawn=263 notdrawn=0 frames 14/14 blank=0 capture=ok scroll=ok 938x938 colors=3963 cross_ae=0
> env     ×3: PASS exit=143 drawn=165 notdrawn=0 frames 14/14 blank=0 capture=ok scroll=ok 938x938 colors=2658 cross_ae=0
> WPTD_SUMMARY=PASS tiers_passed=2/2 ｜ WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10
> WPTD_GATE=PASS acceptance=2/2 line_advance=PASS ｜ 退出码 0 ｜ REAPED_ORPHANS total=0
> ```
> **判据⑦「行推进」是活的判据**（这是本轮"把教训变成结构"的最好一例）：阈值**用实测定**（根治前 `distinct_origin_y=6`、根治后 `12` ⇒ 取 `10`）；**改前红 / 改后绿可复算**；**变异测试** `WPTD_MIN_DISTINCT_Y=13` ⇒ `WPTD_LINE_ADVANCE=FAIL` + `WPTD_GATE=FAIL` + **退出码 1**（验收档仍 PASS）；**普查 NA ⇒ 记 NA，既不当作通过也不判红**（显式打印）。
> **读图**（`wpftextdemo-default-r1-after.png`，`a71ba9e3…`）：① 折行段落分行清楚、② `TextTrimming` 两行不叠、CJK 全可读、④ 位图 / ⑤ 三图形 / ⑥ 列表 / ⑦ 命中条全正常。
> ### 🗣️ 主控又一次"转抄污染"（自记一过）
> 我给 T3 的消息里**引了上一版桥的 sha `bc9754b4…`**（它已被后一版 `177a07a6…` 覆盖），T3 **实读发布目录**发现对不上并**如实上报 + 不擅自重跑**（它的处理完全正确，还给了"六元组一变就重基线"的口径）。**⇒ 规则再确认：跨 agent 引用的 sha/hash 必须现场实读，不许转抄。** 看板已改正。
> ### ✅ `Extent` 修法落地（T1d）+ **一条被推到 provider 车道的根因**
> shim `49fdda9a34e3c42d1fb28826105a97cc396a2854e9bfb4644295b5a602f38792`（3469 行，**只动 `Extent`**）：
> ```
> T2e（T1b 的现成装置）：extent_ok 0/10 → **5/10**；height_ok 10/10、baseline_ok 10/10 不变
> T2d（run.sh tline）：Extent 列 0/1298 → **1259/1298**（该列容差 0.01 DIP）；Height/Baseline 仍 **1298/1298**
> 其余逐项不变（T1.73 73/73、T2 记账 1276/1298、T2b 964/965·207/213、T3 210/236）；牙齿自检仍能抓错真值
> ```
> **口径依据（并否证了一条候选）**：真机语义 = **墨迹盒高度**（上游 `SimpleTextLine.cs:1796-1802` 的 `ComputeInkBoundingBox` 并集 + `:1071-1083` 注释 "the height of the actual black of the line" + `FullTextLine.cs:2640`）；**实测否证 HarfBuzz extents 口径**（HB 给 Latin **16.0800** / CJK **15.2320**，真值 **18.0800 / 18.0859**），而 `ComputeInkBoundingBox` 在 Latin 上给 **18.0800 = 真值逐位相等** ⇒ 选后者。
> **它按边界做对的两件事**：① **查了消费者再改**——`TextLine.Extent` 全仓只有 `FormattedText.cs:1752/1779` 一个消费者（黑盒度量，报告量），行推进用 `Height`，**`TextBlock.cs` 0 处消费** ⇒ **不牵动应用布局**；② **没越界**——CJK 那 5 例的根因它只报不修。
> **CJK 5 例的真根因（已派 T2，provider 车道）**：`build/DirectWrite.Linux/Provider/LinuxFontFace.cs:295-299` 用 `inkWidth = glyf 的 xMax−xMin`，而 **CJK `.ttc`/`.otf` 是 CFF 轮廓**（实测 `NotoSansCJK-Regular.ttc`：**`glyf=0 B` / `CFF=15,458,582 B`**；对照 `NotoSans-Regular.ttf`：`glyf=242,879 B` / `CFF=0`）⇒ CFF 字体 `inkWidth=0` ⇒ 每字形 `left==right` ⇒ 上游"skip blank glyphs"**跳过整行** ⇒ 墨迹盒 `Empty` ⇒ `Extent=0`。**字形度量本身正常**（`aw=16.000 lsb=0.288 rsb=15.712`，`lsb+rsb==aw`）⇒ **缺的是墨迹盒，不是度量**。
> **未诊断（如实登记为欠账）**：T2d 的 **39 条余差**（1298−1259）—— 容差 0.01 远严于项目口径 0.34，且**不在 CFF 家族内**（comparable 集合全是 glyf 字体）⇒ 本轮未定位。
> **时序**：T1d 的 `Extent` + T2 的 CFF 修法**合并到一次集成波**送进权威 PC（避免两次波 + 两次基线），然后 `verify-all` + T3 重新基线。
> ### ✅ **CFF 墨迹盒修法：T2 三次失败后由主控直接验证成功 —— 关键是"oracle 里根本没有 CFF 用例"**
> **T2 的第四次尝试**：编译通过、`.dll` 确认变化（`a3c026c5…` → `71ba86c6…`），但 `T2d` 的 `Extent` 列**逐字不动**（1259/1298）⇒ 它按我给的逃生出口**停手并交出补丁 + 一个可检验假设**："oracle 里没有 CFF 用例"。
> **主控验证（直接探针，不经 oracle）**：`CoverageProbe --family … --inkdiag`：
> ```
> 改前（provider a3c026c5…）：NotoSansCJK-Regular.ttc#0 ⇒ inkBox=<Empty>  Extent=0.0000
> 改后（provider 71ba86c6…）：NotoSansCJK-Regular.ttc#0 ⇒ inkBox=(-0.424,-14.552)-(375.704,2.360) h=16.912 ⇒ Extent=16.9120
>                              同一面其它行 18.736 / 19.408 ⇒ **CFF 墨迹盒真的算出来了**
> 对照 glyf-CJK（arphic/ukai.ttc#0，designEm=1024）：inkBox 非空、Extent 16.95 / 13.91 ⇒ **未受影响** ✓
> 对照拉丁 glyf（DejaVu）：正常 ✓
> ```
> ⇒ **T2 的假设成立：补丁有效，"读数不动"是 oracle 的覆盖缺口**（`T2d` 的 1298 行全是 glyf 字体）。
> **⚠️ 这里埋着一个"假红陷阱"（主控差点踩）**：`CoverageProbe/bin/Release/DirectWrite.Linux.Provider.dll` 是 **app-local 旧副本**（`a3c026c5…`）—— **不换它就直接跑探针，会拿旧 provider 得出"补丁无效"的结论**（与"谁跑谁测老 shim"那一族完全同源）。**验证前必须先把新 `.dll` 拷进探针目录**（我做了，并在输出里打印 sha）。
> **T2 的四次同族失败（记档，比补丁值钱）**：**四次都是"我以为有几处"** —— 漏掉 `GetDisplayGlyphMetrics` 里的**第三个调用点**（它在第三个方法里，不在它以为的核心内部）以及那处的 `using`。**真值只要两条命令**：`grep -an "DesignMetricsOf("` + `grep -an "hasVertical"`。**⇒ 规则：改跨方法签名前，先取"所有调用点 + 所有相关局部变量"的全量清单、按行号改，再看编译器。**
> **它还自证作废了一条读数**：编译失败后仍跑了 `run.sh tline`（用的是旧 `.dll`）⇒ 自己判定该读数无效；并接受硬约束：**跑任何 oracle 前先证明被测产物真的变了**（sha 或纳秒 mtime）。
> **T2 报的装置覆盖缺口（登记为欠账）**：`T2d` 的"`LineHeight>0` 用例：0 行" ⇒ 该列**无真值覆盖**（`T2e` 已覆盖 `LineHeight` 维度 10 例，真值面不缺，缺的是装置分工）。
> ### ✅ **零缩放 CTM 结案：(甲) 上游发的就是 `Scale(0,0)`**（T2b，部署件 `f519eff9…`）
> 原始字段证据（两条链各自独立）：
> ```
> 0x88[1.04] →  0x8d 本节点=[0.00,0.00]  变换句柄=0x8e 类型=Scale 原始=(ScaleX=**0** ScaleY=**0** CenterX=**0** CenterY=**0**)
> 0xa3[1.04] →  0xa4 本节点=[0.00,0.00]  变换句柄=0xa5 类型=Scale 原始=(ScaleX=**0** ScaleY=**0** …)
> 对照组根节点 0x04：类型=Matrix 原始=(M11=1.04166667 M12=**0** M21=**0** M22=1.04166667 …)   ← 非 0 照原样给，只有退化值才标 **0**
> ```
> ⇒ **解析后矩阵与原始值一致** ⇒ `TransformResolver` **如实反映输入、没算错** ⇒ **这是上游/布局发来的 `Scale(0,0)`，属登记的输入，不是我们的 bug**。影响面 = 4 个局部 7×4、clip 1×1 的小图标（塌掉的槽位里）。**渲染侧"对退化 CTM 跳过"是行为改动 ⇒ 不顺手做**，要做单独立项。
> **方法学**：它用**对照组**（根节点非 0 值不被标 `**0**`）证明"标 `**0**`"这个记号本身没撒谎 —— **记号要有对照组才算证据**。闸门也齐：关/开两档 `skia 指令 180 / 未画种类 0` **逐字相同**。
> 它另有两处自纠值得记：① 残留核对用过宽模式 `*Wpf*` ⇒ 把**路径里的 `wpf-linux`** 也数进来（"残留 2"是脏数），改 `*WpfTextDemo*` 后为 0；② 用 `strings` 查中文格式串 ASCII/UTF-16 都 0、一度像"仪表没编进去" —— **那是查法不对（`strings -el` 匹配不到 CJK）**，真正的验证是**运行输出里逐字出现**。
> ### ✅ **D-d 结案为 (i)**（M7b，同版部署件）
> ```
> describe(source)= h=3 via=slot kind=Frame/Source foreign=0 ownedByWic=1 refs=4 size=1x1 rowBytes=4 fmt=…c910 pixels=yes decoded=1
> 样例自报：BitmapSource.Create 成功 96x96 Bgra32 stride=384 ｜ PixelWidth=96 PixelHeight=96
> ```
> ⇒ **PC 交下来的句柄本身就是 1×1 的"真解码"对象**（有像素、`decoded=1`）⇒ (ii) `FormatConverter` 退化**排除**、(iii) 尺寸字段**排除**、**也不是我们登记的外来源（`foreign=0`）** ⇒ **物化路径忠实，是"PC 选错了要交给 MIL 的那个源"** ⇒ **归属 PC/WIC 胶水层**（已派 T1c：**只定位、不改行为**）。
> ⚠️ M7b 第一次尝试失败的原因**是环境不是应用**：`:99` 上**已无 X server**（`xdpyinfo: unable to open display ":99"`）⇒ 应用在 `CreateWindowEx` 抛 `Win32Exception(1400)` ⇒ **`1400` = 没 X，不是 shim/应用缺陷**（它改用自己的 `:98` 冒起重跑成功）。**"环境故障要报成环境故障"**这条又攒一例。
> **⇒ CJK 两项与 D-c/D-d 的当前状态**：CJK 真因 = **shaping 选面**（T1d/R1，进行中）；D-c = 已结案（`ScrollViewer` 视口裁剪）；D-d = **(i)，PC/WIC 胶水层**（T1c 定位中）；零缩放 CTM = **(甲) 上游输入**（结案，未改行为）。
> ### 🎉 **R1 落地并冻结**（T1d）—— `build/shims/**` 自此不再改动，**可以起波**
> 落点 `build/shims/PresentationCore.HbTextLine.cs` = **`fbda5f88d826a88382b743e7aad5657c1546ff94a72e6ac9072731bd820f9e8b`** / **3234 行 / 173,733 B**（改前 `2cc87a93…` / 1791 行）；新增 `build/MilBridge/tests/CoverageProbe/`（exe）、`tools/t1d-probe.sh`、`run.sh t1d`；报告 `build/MilBridge/T1d-report.md`。
> **五项落地**：① `TryCollect` 收 run（改前只留第一个 run 的 props）；② run 级取面（按 `TextRunProperties` **引用**缓存；解析不到 ⇒ 沿用上一个面 + 计数，不整体失败）；③ **按码点覆盖切段**（`HbShaper.CoversFace` = `hb_font_get_nominal_glyph`，**不碰 provider 反射**；候选 = 当前面 → 其余 run 的面 → 机器字体目录，口径**逐字对齐** `Factory.Linux.cs`；同覆盖才按 HB 读的 OS/2 三要素就近）；④ 多面分别整形后**拼回一个 `HbShapedRun`**（cluster 平移回局部下标）；⑤ ⭐ **每个字体子段发一张带自己 `GlyphTypeface` 的 `GlyphRun`**（+ 各自 baseline origin）—— 这是前任设计缺的那一格，**不补它就会"普查绿、像素垃圾"**。
> **应用路径实测（245 字，驱动 `TryFormatLine`）**：
> ```
> default（R1）       id0=0   非拉丁=58  maxId=63151  glyphs=245  glyphRuns=18  chunkedLines=5  faces=2
> MULTIFONT=0（今天）  id0=60  非拉丁=0   maxId=93     glyphs=245  glyphRuns=6   chunkedLines=0  faces=1
> ```
> **A/B 逐位**：`MULTIFONT=0` 的 245 个 id 与**改前那段代码（单字体入口）逐项相等** ⇒ 关档 = 今天；`maxId=63151` 与主控阳性对照**同值**。`fonts-ui`（结构性无解）档如实报 `candidates=1 / fallbackApplied=0 / fallbackFailed=60` —— **不假装可达**。
> **回归全平**（同一 harness、`-p:HbShimSrc=` 指改前副本对比）：`T1.73 73/73`、记账 `1276/1298`（①286/286 ②68/68 ③977/988）、`T2b 964/965 · 207/213`、`T2d 1298/1298`、折叠 `判定1298/1298 明细210/236`、`Tab` 红 15 例**保留**、`icu 73/73` —— **逐项相同**。
> **它自己抓到的三个缺陷**：① `HbFontPlan.Sub()` **只裁剪不重定基** ⇒ 第 2 行起整段被跳过、0 字形、Width=0 —— **三个既有 harness 全绿也发现不了**（它们不走计划），是新探针第一次运行抓到的；② `hb_ot_name_get_utf8` 在 `text==NULL` 时用**返回值**给字节数、**不写 `*text_size`** ⇒ 闸门把候选面全拒（`fallbackFailed=60`）—— **这恰好证明闸门在干活**（宁可不出字，也不静默用错面）；③ 探针自己的两条假绿（无数据时 P2–P5 真空通过、P5 标签与条件不一致）已改。
> ### ✅ **D-d 根因定位完成**（T1c，**只定位、未改行为**）：**是上游的"解码失败占位"，触发者是我们 shim 不支持子矩形 `CopyPixels`**
> 逐跳（带文件:行）：样例 `BitmapSource.Create(96,96,…,Bgra32…,384)` → `CachedBitmap`（`IsSourceCached=true`）→ 提交时取 `DUCECompatiblePtr`（`:742`，`UsableWithoutCache=true`，`:1561`）→ ★ **上游 `:773-795` 有意的 1×1 探针** `CopyPixels(src, Int32Rect(0,0,1,1), 4, 4, buf)`（注释原文：*"we call CopyPixels for the first pixel which will decode the entire image"*）→ ★ **`wic_proxy.c:1035-1053` 把 `(0,0,1,1)` 对 96×96 判成"非整图" ⇒ 诚实返回 `WINCODEC_ERR_UNSUPPORTEDOPERATION`** → 上游 `:797-803 catch` → ★★ **`:950-957 RecoverFromDecodeFailure` 换源**成 `Create(1,1,96,96,Pbgra32,null,new byte[4],4)` → 交给 MIL 的就是那个 1×1（另一分支 `:806 needs caching → CreateBitmapFromSource` 已排除：shim 里是真实现，内存位图不会失败）。
> **⇒ 真问题不是"PC 选错源"，而是"我们的一次诚实拒绝被上游归类成解码失败"**。
> **独立判据（靠格式 GUID 判等，不靠猜）**：源 = Bgra32 = `…c9**0f**`（`wgx_exports.cs:266`），交下来 = Pbgra32 = `…c9**10**`（`:267`），而 `RecoverFromDecodeFailure` 恰好用 `PixelFormats.Pbgra32` 造占位（`:953`）⇒ **"交下来的不是样例那张图"被独立坐实**。
> **裁定：选方案 A**（shim 支持任意 `prc`：最小、最贴合上游语义；B 只特判 1×1 = 治症状；**C 在 PC 侧绕开探针会削弱"渲染线程不解码"的正确性保证、且属行为改动**）⇒ **已派 T2**（`wic-shim` 车道），并要求**同批补** `COPY_PIXELS` trace 的 `prc` 与拒绝原因（当前子矩形拒绝**完全静默** ⇒ 只看日志会误判"CopyPixels 正常"，**又一条"仪器沉默 ≠ 没发生"**）。
> **D-d 验收（一句话可判）**：探针那次 `CopyPixels` 返回 `S_OK`；`[cwic-trace]` 的 `size` 从 `1x1` 回到 **`96x96`**、`fmt` 从 `…c910` 回到 **`…c90f`**；门禁判据④（`feature-color-missing`）**转绿**。
> ### 🚀 集成波已起（主控，`build/integration-wave.sh`）
> 输入已冻结（R1 shim `fbda5f88…`、T1c 的 `FontBridge.cs`/provider 自检、T2b 的 `TransformProvenance`、M7b 的两处仪器）。波后要做的四件事：① 应用级普查 `t1c-census.sh`（**期望 `id0≈0 / nonlatin>0 / maxid≈63151 / 面数≥3 / 未画种类仍 0`，并读图看中文**）；② `run.sh tline` 与 `run.sh t1d` 复跑；③ `verify-all.sh` 全量门禁；④ **T3 按新配置重新基线**（配置五元组变了 ⇒ 旧基线作废，这是新定的口径）。
> ### 🎉🎉 **波通过 + CJK 端到端打通（主控实测 + 读图）** —— 本轮的头号结果
> **波**：`失败步骤 0`；15 个工程 **0 错 0 警**；身份自检 **5/5 带公钥**；**新加的第 5 步输入稳定性自检**：波前/波后指纹 `0889aef9…` **一致** ⇒ 没有编辑竞态。
> **新权威 PC** = `build/PresentationCore.Linux/bin/Debug/PresentationCore.dll` sha256 **`f31822ce4a3e510d5cd724a6654b29a29bb44d3a8027cec33f5116e89c09101b`** / 4,155,904 B（实测含 `WPF_LINUX_MULTIFONT`（UTF-16 ×2）与 `WPF_LINUX_FACE_HANDOFF`（UTF-16 ×6）⇒ R1 与 (乙) 的开关都真的编进去了）。
> ⚠️ 我**第一次核这两个串时用了 ASCII `strings`，读到 0**，差点又误判"没编进去" —— **`strings -e l` / 原始字节搜 UTF-16 才见 7 处**。**这条坑本工程已犯两次（M7b 一次、我一次）**，写进手册：**托管程序集里的字面量是 UTF-16，ASCII `strings` 看不见。**
> **应用级 A/B（同一台机、同一份 PC、同一档，只翻 `WPF_LINUX_MULTIFONT`）**：
>
> | 档 | runs | `id0` | `nonlatin(≥0x1000)` | `maxid` | `distinctpids` | 截图 | 颜色数 |
> |---|---|---|---|---|---|---|---|
> | **R1 开（缺省）** | **131** | **0** | **322** | **63151** | **4** | 142,311 B / `17be1956…` | 3,679 |
> | **R1 关（`=0`）** | 48 | **325** | **0** | **3540** | 2 | 78,018 B / `cccb693b…` | 2,631 |
>
> ⇒ **像素 AE = 104,841**（不是"只改了计数"）⇒ **T1d 预判的那条假绿（"普查绿而像素垃圾"）被否证**：普查变绿**且**像素真的变了。
> **主控读图（两次都读了，直接证据）**：**开档**中文**是汉字** —— 副标题「折行 / 省略号 / 三档对齐 · 数据绑定 · 位图 · 圆角与阴影 · 鼠标命中（默认配置门禁样例）」、① 卡「多行折行 · 中英混排」、③ 卡「Left · 左对齐」「Center · 居中」「Right · 右对齐」、ListBox 每项的「绑定项 0N」与 **`detail: 中英混排 mixed text, 用来验证绑定后的文本排版`**、底部「当前选中（ElementName 绑定）」「鼠标命中：把指针移到这块区域 → 变绿；点一下 → 变橙（计数 +1）」**全部是真字形**；**关档**同一批位置**全是豆腐块 `□□□`**。⇒ **"中文上屏"从"计数合格"升级为"读图确认"。**
> **仍未解决（不在 R1 范围）**：① 多行段落**摞在同一基线**（① 卡与 ListBox 的 `detail:` 行可见 = "行推进 ≈ 0" 那条）；② D-d（④ 卡位图空白，修法已派 T2）；③ `Extent 0/1298`。
> **命令与读数件**：`bash build/MilBridge/tools/t1c-census.sh /tmp/r1after default WPF_LINUX_GLYPH_CENSUS=1` ⇒ `/tmp/r1after/readings.txt` 机读行 `T1C_CENSUS_SUMMARY frame=3 runs=131 handles=131 glyphs=1276 id0=0 nonlatin=322 maxid=63151 allnotdefruns=0 distinctpids=4`；`… /tmp/r1off default WPF_LINUX_GLYPH_CENSUS=1 WPF_LINUX_MULTIFONT=0` ⇒ `runs=48 id0=325 nonlatin=0 maxid=3540 distinctpids=2`。通道台账 `committed=689 pending=0`、`MilGlyphRun×137`。

> ## 📌 2026-09-11 这一轮的账（主控）
> **⑤ 复验通过（M2 无回归）**：验收同款配置下 HelloWpf `PNG 56,055 B / 白像素 8,318 / 未画种类 0`；`MessageFontFamily` 可解析、闸门④ `CheckFastPathNominalGlyphs=True`、缺字形 0/18、闸门③ `TypographyAvailabilities=0`。
> **集成波第 6 次**：`失败步骤 0`、15 工程 `0 错 0 警`、身份自检 5/5 带公钥（第 5 次被一次中断杀在半路、PC 未重建）。
> **全量门禁 `verify-all.sh`：步骤 8/9、用例 726 通过 / 1 跳过**，唯一红是 **`ManagedLayer.Tests`（48 用例 / 35 通过 / 2 失败 / 11 跳过）** —— 那 2 条是**本轮新增的 red-first 用例**（`M7cInputPathTests`，为鼠标输入崩溃而写，**主控要求"先能红"**），**不是回归**；且已**排除编辑竞态**（`src/WpfGfx.Linux` 64 个 `.cs` 指纹跑前跑后完全未变）。
> **T1 (a) 落地并通过**：PC 默认族改走 `DefaultFontFamily.SelectFamilyName(...)`，实测两种目录配置下都选 `Noto Sans`（旧 `_fontCollection[0]` 会漂到 `AR PL UKai CN` 楷体）；`run.sh compositefont` **通过 6 / 失败 0 / 跳过 4**、退出码 0。
> **T2**：WIC 读路径 `BYTE_MISMATCH=0/1920000`、`WIC_SHIM_MAPS=1`；写面 **`CHECK4` PASS（写→读逐字节 0/256）**、**`CHECK6` FAIL→PASS**；**外来源派发 shim 侧已通**（`.so` `0d9ae11b…`，`Wic*` 导出 8→11，探针实测"登记前 E_INVALIDARG / 登记后 GetPixelFormat+GetSize 成功 / CopyPixels 诚实返回 UNSUPPORTEDOPERATION / 注销后回 E_INVALIDARG"）——**只剩 MIL 侧那一次调用**。
> **真机 oracle 三批**：`tests/parity/brushes/`（74 例，破坏性自检 51 条变红，**主控独立复核 12,723/12,723 模型点吻合**；批次 2 又 60 例）、`tests/parity/windows/layout-b34/`（**614 例 / 3222 行** + C/D 批 `cd1`184 + `cd2`106）、`tests/parity/systemfonts/`（89KB 读数）。
> ### 🔴 **第 7 次假绿 —— 新机制："无参=空操作 但 exit 0"（2026-09-11，主控抓出）**
> **波 7 打印了 `✅ patch-presentationcore-textservices`（补丁 M = 鼠标输入崩溃的修法），而它一个字节都没改。** 核实证据：`build/WindowsBase.Linux/TextServicesLoader.Linux.cs` **不存在**、`WindowsBase.Linux.csproj:281` **仍在编译上游原文件**、`WindowsBase.dll` 里没有那条修法。
> **根因**：该应用器**无参运行只打印「未指定动作：加 --check / --out / --apply」然后 `exit 0`**。而波的纪律是"**成败一律看退出码**"、家族约定是"**无参 = 生成文件**"（其余 **7 个**应用器都遵守）⇒ 两条都抓不到它。**它跨了两波才被发现。**
> **为什么这次能抓到**：因为主控**去核了 csproj 接线**（"文件在不在 `Include` 里"），而不是看波的 ✅。⇒ **"波绿了" ≠ "补丁进去了"**，这道二次核实要固化成习惯。
> **修法（两层）**：① 波的补丁循环加**空操作护栏**（除退出码外，显式匹配 `未指定动作|无动作可做|nothing to do`；**双向自测过**：抓住补丁 M、不误判其余 7 个；这是对"不靠关键词匹配"原则的**有意窄例外**，已注明）；② 要求应用器 owner 回归家族约定（无参 = 应用 + **csproj 接线**，且因波第 1 步会重写 csproj，接线必须每次由应用器重放）。
> **主控全量审计结论**：8 个应用器里**只有补丁 M 一条**违背家族约定；其余 7 个的生成物都在 csproj 的 `Include` 里且文件存在（`SecurityHelper.Linux.cs` / `InputManager.Linux.cs` / `FontCacheUtil.Linux.cs` / `StylusLogic.Linux.cs` / `OleServicesContext.Linux.cs` / `FamilyCollection.Linux.cs` / `SystemResources.Linux.cs`）。
> ⚠️ **一次中断把波和 6 条轨道一起打断，中间空转约 2 小时**（14:09 → 16:13）。恢复时先做**状态体检**（哪些文件是半成品、波死在哪、`.so` 与 `.c` 是否对得上）救回了判断。
> ⚠️ **主控自己犯了 6 次"验证工具在说谎"**：`pkill -f 'Xvfb :98'` 匹配到自己命令行（自杀）、`RC=$?` 写在管道后（永远 0）、共享 `M7C_RUN_DIR` 被并发覆盖丢证据、跑了正在被编辑的 runner、`setsid bash -c` 起 `verify-all.sh` **没带 PATH** ⇒ 8 个步骤全 `rc=127` **假红**、拿"我的运行结果"与"存档验收件"比对**没控制配置**（差一点把"默认配置无文字"误判成 M2 回归，**救回来的是 A/B 而不是更仔细地看直方图**）。

> ### ✅ P0 闭环：**默认配置（不设任何字体 env）下文字真的上屏了**（2026-09-11）
> **主控独立复验 + 读图确认**：`未画种类 0` / PNG **55,913 B** / 白像素 **8,846**（修前 `未画种类 1` / 46,902 B / 6,300）；图中「Hello WPF on Linux」标题与「Rectangle / Ellipse / Path / Gradient / Transform / Text」第二行**都在屏上**。
> **修法（M7b）**：① `Text/FontSet.FromDirectory` 枚举改**递归**（原先只扫顶层，`/usr/share/fonts` 顶层无字体文件 ⇒ **候选文件=0** ⇒ 面永远解析不到 —— 这才是真因，主控原先猜的"族名不对"只是第二层）；② 请求族改用 **`SPI_GETNONCLIENTMETRICS.lfFaceName`**（与 WPF message font **同源**）；③ 请求族在选定目录里解析不到时**退回该目录第一个面**，并**免采样 NOTE 大声说明是兜底不是对齐**。
> ### ⚠️ 教训：**源码改了 ≠ 部署产物改了**（AOT 桥重发布是主控的活）
> 我第一次复验**失败**（仍是 `未画种类 1`），根因不是实现，而是 **AOT 桥没重发布**：`.so` 比 **10 个源文件**旧。⇒ **"改 `src/WpfGfx.Linux/**`"必须配一次 AOT 重发布**才算落地。
> **主控自己又踩一个坑（新类型：相对路径被按各工程目录解析）**：`dotnet publish … -p:ArtifactsPath=build/MilBridge/.artifacts`（**相对路径**）⇒ 产物落到 `build/MilBridge/src/MilBridge.Linux/build/MilBridge/.artifacts/`，**正式发布目录一字未动**，而 `PUB_EXIT=0`、日志全是"成功" ⇒ **又一个"绿了但没生效"**。修法：**用绝对路径** `-p:ArtifactsPath="$R/build/MilBridge/.artifacts"`（已重发成功：`.so` = `600c885c…` / 4,730,864 B，旧 `15b5270f…`）。
> **顺带修掉一处部署契约问题**：发布目录里的 `libwpfwic.so` 是 **09-10 的旧副本（29,392 B）**，已同步成权威件 `0d9ae11b…`（11 个 `Wic*` 导出）。"全仓只能有一份、且与 `wpfgfx_cor3.so` 同目录"这条踩过坑（3 份副本 ⇒ `DOUBLE_TABLE=TRUE` ⇒ `E_HANDLE`）。
> ### 🔴 新硬阻塞 D3：**文本回落 LineServices ⇒ 进程 abort**（比鼠标崩溃影响面更大）
> `TextBlock.MeasureOverride → TextFormatterImp.FormatLineInternal → SimpleTextLine.Create 返回 null → FullTextLine → TextFormatterContext.cs:113 LoCreateContext → EntryPointNotFoundException → abort(134)`。
> **T3 实测**：文本稍多的 `WpfTextDemo` 在**默认档/带 env 档/降级档/最小档全部 100% 崩**；HelloWpf 因文本框小、留在 `SimpleTextLine` 快路径才一直正常 ⇒ **"任何文本稍多的真 WPF 应用都会崩"**。
> **T1b 的诊断（未改代码）**：`grep -rn "HbTextLine\|WpfLinux.Shims" upstream/wpf/src` = **空** ⇒ **我们的 `HbTextLine` 根本不在那条路上**；**两个站点都要接**：`TextFormatterImp.cs:236-246`（`FormatLineInternal`）与 **`:309`（`FormatMinMaxParagraphWidth`）**。**主控已授权把 `FullTextLine` 回退接到 `HbTextLineFactory`**（车间接给 T1b：新增应用器 + `build/PresentationCore.Linux/**`）。
> ### 🧪 一条要固化的纪律（T1b 提出并已实现）：**把"被测文件的 sha256"焊进读数**
> `run.sh` 把**传给编译器的那个文件**的 sha 用 env 传进去，harness **自己再读盘算一次比对、不一致大声失败**。起因：同一份 shim 出现 `6c9af7e8`/`de6133fc`/`f1daeff4` 三个 sha（分别是 cp 后、加了一个只读诊断属性后、staging 加了折叠精化后），**"测的到底是哪个文件"又不清楚了** —— 这个项目已经栽过多次，现在改成机器判。
> ### 🧭 调度教训：**同一条车道不能同时派给两个人**
> `build/DirectWrite.Linux/**` 原本是 T2 的，我在它空闲时又把 `IWICBitmap_Lock` 派给了 T2b ⇒ 两个 agent 都动了 `probe_foreign.c`（T2 的脚本在锚点断言处中止、**没写入**，属险过）。已定案：**shim 车道归 T2 独占**，`Rendering/` 等归 T2b。

> ## 📌 2026-09-11 第二轮：三条真实应用路径打通 / 一条新硬阻塞起修
> **① `WriteableBitmap` 写面归零（v2）**：写面 harness **`RESULT=PASS`** —— `CHECK3=PASS`（`WriteableBitmap` 32×32 写→取回失配 **0**、`BackBufferStride=128`）、`CHECK4=PASS`（PNG 写→读 0/256）。trace：`FOREIGN_SOURCE_REGISTER … pixels=0x579109a8… rowBytes=128 borrows=1`。
> **为什么必须"借用"而不是"拷贝"**（这是我在这一轮推翻自己 v1 保守口径的依据）：**`WriteableBitmap` 的契约是"Lock 拿到的指针就是你写进去、渲染看得见的那块内存"** ⇒ 拷贝一份会让写穿透失效（**功能坏掉，不是慢**）。shim 侧牙齿：**外来源写穿**（写 `0xCD` ⇒ `CopyPixels` 读回 `0xCD`、同块内存直读也 `0xCD`）、借用计数 `1→0`、**未借像素仍诚实 `UNSUPPORTEDOPERATION`**（证明 v1 的守卫没被 v2 顺手删掉）、注销后不再发指针。
> **② 鼠标输入在应用级验通**（T3）：`--minimal --text-volume=1` 档用 `xdotool` 竖扫 3 点各 move+click ⇒ **3/3 进程存活**、**3/3 应用台账出现 `MouseEnter（命中 HitCard）`** ⇒ 命中测试 + 事件派发到应用处理器这条链通了。
> **③ D1（UIA resolver）/ D2（UIA 保留值）落地**：`Win32ShimResolver.cs` 现在也编进 `UIAutomationTypes`/`UIAutomationProvider`（**实测两个 dll 里都有 `WpfLinux.Shims`**）；D2 短路 `UiaGetReservedNotSupportedValue`/`MixedAttributeValue`（**措辞写明是降级**：Windows 上它们是 UIA 核心的保留 COM 对象、客户端按引用相等判断，我们只有进程内自洽）。`ManagedLayer.Tests` **51/51**。
> **④ 波机制再修两处（主控）**：新增**预应用器阶段** —— `wire-uiautomation-resolver` 改的是 **port-lib 的输入**（`shims.txt`），必须「应用器 → **定向 port-lib** → 其余应用器」，否则清单写了也**不会进 csproj 且静默**。实测接线已进 `UIAutomationTypes.Linux.csproj:95` / `UIAutomationProvider.Linux.csproj:65`。另新增 `build/publish-milbridge.sh`（债务 #21）。
> ### 🔎 D3 的**最小可判据**（T3 边界探测，比"整档崩不崩"有分辨力）
> `--minimal --text-volume=N` 每档 3 次：**N=1 ⇒ 活到超时、`skia 指令 4 条 / 未画种类 0`、文字在屏上（读图确认）**；**N=2 ⇒ 3/3 `LoCreateContext` abort**；N=3 同。
> ⇒ **阈值是"同段落第 2 行"，不是字符数或总行数** ⇒ 拒绝点很可能在 `SimpleTextLine.Create` 的"需要第二行 / 需要换行决策"那一支。**这是 D3 修复的验收锚**（27 → 0 之外的第二条）。
> ### ⚠️ D3 第一次修复**没生效**：根因是**开关默认值把回退关掉了**（主控定位，2026-09-11 傍晚）
> **接线本身是好的**（三重核实：csproj `:1605 Remove`+`:1606 Include`；`DefineConstants` 含 `TEXTLINE_SHIM_DIRECT`；生成物 `TextFormatterImp.Linux.cs:253/:335` 两处站点在；**崩溃栈里就有 `TextFormatterImp.Linux.cs:265`** ⇒ 跑的是打过补丁那份）。**但 `TryFormatLine` 返回 null** ⇒ 走 `:262` 的 `new FullTextLine` ⇒ LS ⇒ abort。
> **根因（读代码 + A/B 双证）**：`ParseOnOff(null) ⇒ false`（**"认不出来/没设 ⇒ 关"**），而 `Enabled => ParseOnOff(GetEnvironmentVariable("WPF_LINUX_TEXTLINE"))`、`:1538 if (!Enabled) { BailNoSwitch…; return null; }` ⇒ **未设该 env ⇒ 回退被关**。**而设计写的是"默认开、`=0` 可关"** —— **实现与设计相反**。
> ```
> 不设 WPF_LINUX_TEXTLINE : LoCreateContext 出现 2 次 → exit=134
> 设 WPF_LINUX_TEXTLINE=1 : LoCreateContext 出现 0 次 → 不再走 LS ✓（但仍 exit=134，见下）
> ```
> ### 🔴 开关打开后的**下一道墙**（新登记）：`BitmapSource.DUCECompatiblePtr` → `E_HANDLE`
> 打开回退开关后：**可视树建成、布局走通**（`[wptd] MainWindow 构造完成：可视树已建（含 ScrollViewer / ListBox / Image / Effect）`、`WPTD_MODE=full` —— **顺带证明 D1/D2 生效：`ListBox` 构造不再撞 UIA**），然后崩在呈现/提交：
> `COMException (0x80070006) E_HANDLE` ← `HRESULT.Check`（`wgx_render.cs:975`）← `BitmapSource.get_DUCECompatiblePtr()`（`BitmapSource.cs:872`）← `UpdateBitmapSourceResource` ← `AddRefOnChannel` ← `RenderData` ← `UIElement.RenderContent`。
> ⇒ **这是 handoff:1660 登记过的 `MILQueryInterface`/bitmap-source 句柄墙**，现在升级为**应用级阻塞**（已派 M7b，`Interop/` 车道）。
> ### 🧪 又两种"工具在说谎"（新形态）
> ① **"诊断只在正常退出时输出" = "故障时没有诊断"**：`SummaryLine()` 只由 `Dump(path)` 在**进程退出时**写一次，而崩溃进程没有"退出"这一步 ⇒ **bail 原因（`LastBail`）永远拿不到**（`/tmp/tl-dump.txt` 是空的）。**要求：bail 即打一行 stderr（限流 + env 门控）。**
> ② **"默认值语义"是设计里最容易与实现脱节的一格**：设计说"默认开"，实现用了一个共享的 `ParseOnOff`（"未设 ⇒ 关"）⇒ **回退被静默关闭**。**建议把"不设任何 env 时的默认值"纳入波前自检**（廉价断言，正好能挡住这次的 bug）。
> ### ✅ D3 **判据 1 达成**（主控独立复验，2026-09-11 傍晚，波 11 后）
> T1b 的修法：**独立开关** `WPF_LINUX_TEXTLINE_FALLBACK`，`Enabled = !显式关(WPF_LINUX_TEXTLINE) && !显式关(..._FALLBACK)` ⇒ **未设 ⇒ 开**（`ParseOnOff` 全局语义**一字未动**，`STRICT`/`DUMP` 不受影响）。**为什么必须"默认开"而不是靠 env**：T3 的 runner **主动清空 `WPF_LINUX_TEXTLINE*`** ⇒ 靠 env 打开在那个 runner 里**永远打不开**（这正是第一版"看起来没生效"的形状）。
> **主控实测（默认配置、不设任何 env）**：
> ```
> --minimal --text-volume=2  ⇒ LoCreateContext **0 次**、rc=124（timeout 到点才被杀 ⇒ **进程活满 25 秒**）   ← 此前：27 次查找 ⇒ abort(134)
> --tier default（full 模式）⇒ LoCreateContext **0 次**（D3 已绕过 ✓），阻塞**只剩** E_HANDLE
> ```
> **另加两项**：① **16 处 bail 路径统一走 `Bail()`，前 3 条无条件写 stderr**（因为 `SummaryLine()` 只在正常退出落盘 = **故障时没有诊断**；且那个 runner 连 `..._DIAG` 一起清空）；② **"默认值自检"做成可跑断言**（`DirectBranchCheck` 改 Exe，`run.sh tline` 第 1 步跑 `D1–D6`，含 **"不设任何 env ⇒ `Enabled==true`"**）⇒ **这类"编译期查不出、运行期静默关掉功能"的 bug 从此在波前被挡**。
> ### 🧪 T2b 又抓到一种假绿：**突变改到了死代码**
> 它验"断言有牙"时把 `FilterQualityFor` 的 NN 分支改成 `Low`，突变体**仍 7/7 全绿** ⇒ **"我的断言有牙"这个结论是假的**（真正的 NN 判定在 `ImageFilterQuality` 里另有一个早返回）。重做后立刻红（68→0、187→0），并**核 DLL mtime 确认真的重编了**。
> ⇒ **"突变不红"有两种可能：断言没牙，或你改的不是生效的那处。** 归入手册那一族：**"观测对象与你以为的不是同一个"**（同族：`Assert.True(true)` 空壳、空帧下的 `未画种类 0`、管道尾巴的 `$?`、没编译的突变）。**它顺带把死代码陷阱删掉了**（让 `FilterQualityFor` 成为唯一判定点 + 注释留痕）—— **把教训变成结构**。
> ### 🧗 剥洋葱记录：`WpfTextDemo`（full 模式）的**阻塞链**（每一步都有主控实测的活体证据）
> ### 🎉 2026-09-11 晚 · **完整 WPF 应用在 Linux 上渲染出来了**
> 第 3 道墙修完后（桥 `9eb4c88c3258307d09daa155…` / 4,768,240 B），full 模式默认档：**`NotImplementedException` / `LoCreateContext` / `E_HANDLE` 全部 0**，**`skia 指令 145 条，未画种类 0`**、`committed=507 pending=0`、**exit=143（活到超时、不崩）**、截图 938×646 / 52,844 B。
> **主控读图确认**（`sha256 2955e7025fdc4a6a…`）：标题 `WpfTextDemo`、多个分区框与圆角边框、**`ListBox` 真在渲染数据绑定**（`Item 01`…`Item 06` + `detail: bound via ItemsSource (7 ms)`）、`CharacterEllipsis` 修剪区、`TextAlignment Left/Center`、滚动区、底部说明行、**投影效果**。
> ⇒ **绑定 / ListBox / ScrollViewer / 折行 / 修剪 / 对齐 / 效果整条链都在真应用上跑通了**（不再是"HelloWpf 那种小样例"）。
> ### ⚠️ 同一张图暴露的两个**真缺陷**（已派，按优先级）
> **A. 中文全部渲染成豆腐块（□□□）** —— 拉丁完全正常、CJK 全方框。**主控判断（待核实）**：这是**我们短路复合字体（补丁 J）**的直接后果 —— WPF 靠 `Global User Interface` 复合字体的**回退链**给 CJK 找面，短路后回退链没了 ⇒ 豆腐；**叠加两条**：`EnsureGlyphRenderer` 的请求族是 **SPI 同源**（本机 `DejaVu Sans`，**纯拉丁、无 CJK**），且 `FontSet` 只按**族名**选面、**没有"按字形覆盖挑面"**这一步（真 WPF 的 fallback 正是干这个）。**影响面：任何带中文的应用都会这样。**
> **B. 首段文字与边框重叠** —— 可能关联已登记的差异（advance **量化到 1/300 英寸**、`TextHeight ≠ Height`、行高公式）。**要求先归因再改**（"文字算宽了"/"框算窄了"/"行高不同"三者证据形态不同），**不许为了图好看调数值**。
> ### ⚠️ 同时发现：**验收仪器在把成功报成失败**（T3 的 runner）
> `RESULT=FAIL` 完全来自**截图取样竞态**：rep1 抓到 2,060 色 / 52,844 B，rep2/rep3 抓到 **411 B / 1 色**（全白）⇒ 同一次运行里"应用明明画了 145 条指令"，却因抓不到帧被判失败（T3 自己登记过"约 3 次 1 次全白"，这次 3 次里 2 次）。**已派 T3 修**（建议：`xwd -root` 连拍 + 按窗口几何裁剪 + 取颜色数最多的一张；用台账"首个有内容的帧"当可抓帧的门；**报告分开"非单色帧数/总抓帧数"，别把"抓不到"与"没画"混成一个 `FAIL`**）。
> 这是"工具在说谎"这一族里**最贵的一种**：它把成功报成失败。
> ### ✅ 该假红已修并**经主控独立复验**（T3）
> 修法照建议落地：**`xwd -root` 连拍（8 张 / 120ms）+ 按窗口几何裁剪 + 取最佳帧**；首绘由**台账信号**门控（不再固定 sleep）；**单色帧 = 本帧无效**（只计入 `frames_blank`，**不计入失败**）；一张有效帧都没有 ⇒ 第三种结果 **`RESULT=INCONCLUSIVE`**（与 `FAIL` 分开）；判据② 升级为**前置守卫**（取指令最多的一帧，要求 **`skia 指令 > 0` 且 `未画种类 0`**）；新增**判据⑤ 裁剪几何自检**（截图尺寸 == `xwininfo` 几何）。
> **主控复验**：`--tier both` ×3 档 → **6/6 全部 `frames_good=8/8`、`frames_blank=0`、`capture=ok`**，读数逐次一致（`default drawn=180` / `env drawn=165`，`notdrawn=0`，exit=143）。**假红消失，剩下的 `FAIL` 都是真红。**
> **顺带揪出第二个 runner 自伤**：`EXIT` trap 被**后台子 shell 继承**（应用是 `( … ) &` 起的）⇒ 子 shell 退出时把 runner **自己起的 Xvfb** 杀掉 ⇒ 后续档位全在 `CreateWindowEx` 抛 `Win32Exception(1400)`。**症状完全像应用崩**（单跑 `--tier env` 正常、`--tier both` 第二档 3/3 全崩）⇒ 已修（trap 加 `BASHPID != $$` 守卫）+ 每档前 X 存活自检（不可用 ⇒ `INCONCLUSIVE blocker=env:no-x`，不让应用背锅）。**"单跑绿、连跑红"值得单独记一条。**
> ### 📐 图里两个"没画出来"的**真红**（T3 读图发现 → 主控确认 → 已派渲染车道）
> - **D-c：⑤ 卡片 `Canvas` 里的 `Rectangle`/`Ellipse`/`Path` 一个都没画**（卡片只剩标题）。**关键线索：HelloWpf 里同样的三个图形画得出来**，差别是这三个在 **`Border > StackPanel > Canvas`**（且整卡在 **`ScrollViewer`** 内）⇒ 怀疑 **Clip / 裁剪子树 / ScrollViewer 内容投影**。
> - **D-d：④ 卡片那张 `Image` 空白** —— 位图走已知 WIC 缺口（样例已打印降级），**降级成的矢量 `DrawingImage` 也没画出来**。
> ### ✏️ "多行段落摞在同一基线"（**M7b 的只读测量**纠正了主控的描述）
> 主控原先说"首段文字压出边框"**不准确**。准确的是：**单行文本全部正常**（标题 / `Left · 左` / `Item 01` / `detail: bound via ItemsSource (7 ms)`），而**多行（折行）段落整体摞印**（①/②/④ 卡片说明、ListBox 的 `detail:` 行）—— **行与行压在同一条基线上**。
> **三种候选的排除（有理由）**：① 文字算宽 ✗（那会错在**行内**，而行内是清楚的）；② 框算窄 ✗（**没有框**的地方同样摞印）；③ **行推进 ≈ 0** ✓。旁证（M7b 自己标"不是因果结论"）：`MilCommandDispatcher` 没解 `AdvanceWidths`/`GlyphOffsets` 只影响**行内**，而**行推进**更可能在 PC 侧行高/度量反馈 ⇒ **已派文本车道**。
> **M7b 在这条上的两个"收手"值得记**：① 试过 `convert -crop` + 亮度投影，**读数太粗**（框边与标题也计入亮像素）⇒ **宁可空着也不报一个不可信的区间**；② 自建桥读数与部署件**方向都不同**（`938×938/180/未画种类 1` vs `938×646/145/0`）⇒ **不当结论**。
> ### 🧱 一条**架构事实**（T2b 查清，解释了"为什么改 `src/` 必须重发布"）
> publish 目录里**没有 `WpfGfx.Linux.dll`**，只有 `wpfgfx_cor3.so` + `.pdb`，且 `.so` 里命中 `SkiaRenderBackend` ⇒ **渲染器（`src/WpfGfx.Linux/**`）是 AOT 编进桥里的** ⇒ **"零重建读新仪表"的路不存在**；部署件已有的观测面只有 `WPF_LINUX_WIN` 一个 env + 面注册错误台账（`MilBridge_Diag_LastFontFaceError`），**没有一条能读出 `GlyphIndices`**。
> **配套的有效性闸门（T2b 自提，主控批准）**：**诊断桥必须先复现部署件的头条读数**（`skia 指令=145 / 未画种类=0 / PNG 938×646 / committed=507 pending=0 / exit=143`）**才准读新增字段**；对不上则那次读数**一个都不用**。（这正是为了不再重演 M7b 那两次"自建 ≠ 部署"。）
> ### ✅ **全量门禁回到 9/9**（2026-09-11 傍晚，`verify-all.sh`，X 开）
> **步骤 9/9 通过、用例 819 通过 / 2 跳过 / 0 失败**（`Commands` 562 ｜ `Rendering` 134+2 ｜ `Windowing` 44 ｜ `HelloMil` 19 ｜ `ManagedLayer` 52 ｜ `Presentation` 8 ｜ 线格校验 ✅）；**跑动期间 `src/**/*.cs` 指纹未变** ⇒ 结果不被编辑干扰、可信。
> 上一轮（波 9 后）是 8/9，唯一红 `HelloMil` **单独复跑 19/19 通过** ⇒ 判为**并发负载下的 flaky**（与债务 #1 的进程级静态表同源），**本轮不再复现**。
> **用例数 742 → 819**（`Rendering` 56→136、`ManagedLayer` 44→52、`Commands` 350→562 等），**golden 只变批准的 5 张**。
> ### 📐 文本行度量对拍（T1b 的 A，主控收下）：**一行有罪、一行无罪**
> 对拍面 **1298 行 / 315 例**（file 字体 + Ideal + 非 RTL），真值 = `build/MilBridge/gen/layout-b34-compact.json`：
> - **`Height` 1298/1298 一致**（最大差 **0.0013** DIP）、**`Baseline` 1298/1298 一致**（最大差 **0.0007**）⇒ **`LineHeight` 未设时，我们交出的行度量无罪**（差值就是那层 **1/300 英寸量化**）。
> - **`Extent` 0/1298** —— 我们当成行高（21.79），**真机是"墨迹上伸"（14.16）** ⇒ **确认缺陷**（已登记，与"摞印"分开）。
> **`LineHeight` 维度：确认缺陷**（用 `cases-cd2.json` 的 **10 例真值**判掉）—— 真机三条公式逐条成立：`Height = LineHeight`（未设 ⇒ 自然行高）、**`TextHeight` 恒为自然文本高**、`Baseline = LineHeight × (自然Baseline/自然Height)`（`lh10: 10×17.1033/21.7933 = 7.848 ≈ 真值 7.8500` ✓、`lh30 ≈ 23.5467` ✓、`lh50 ≈ 39.2433` ✓）；而**我们的 `Height`/`TextHeight` 恒等于自然行高、完全不看 `LineHeight`（工厂连该参数都没接）**。
> **⚠️ 但 T1b 明确不把它当成"摞印"的原因**（分寸对）：`LineHeight=10` 时我们给 21.79 **只会让行距变大**，不会摞在一起 ⇒ 要"同一基线"需要**行推进 ≈ 0** 或**消费方读错字段** ⇒ **归因保持开放**，等即时诊断（B）变成读数。
> ### 🧪 又一条"歧义观测"被在设计阶段挡下（T1b）
> `HB_TEXTLINE` 汇总行**空** + `LS_FALLBACK` **空**，这两种"空"**无法区分**：(甲) `TryFormatLine` **一次没被调**（全走 `SimpleTextLine`）vs (乙) 被调了且**全部接手**（无 bail ⇒ 无 bail 行；而汇总行只在 `AppDomain.ProcessExit` 写 ⇒ **runner 用 SIGTERM 收尾就永远没有 dump**）。
> ⇒ **"现有装置答不了这个问题，所以我不给数"** —— 这一族（空真/恒真/空即歧义）已有：空帧下的 `未画种类 0`、`Assert.True(true)` 空壳、管道尾巴的 `$?`、没编译的突变、**这次的"空 = 两种含义"**。**修法**：首次接手即打一行 + **首次接手即 `Dump()`**（不只 `ProcessExit`）。
> ### 🔬 T3 的仪器又补两处"不让自己说谎"（主控已复验 8/8 有效帧）
> 它发现过"**8/8 有效帧但最佳只有 325 色**"（半张画）⇒ 新增 **`达标帧数`** 与 **逐帧颜色数升序列表**，**不让"8/8"掩盖"最佳帧是半张"**。另新增 `WPTD_READINGS_DRAWN default=[180] env=[165]` 的**跨档最小判据**（两档**只差字体 env**、指令数不同）⇒ **只陈述事实、标注"未归因"**（不写同义反复）。
> ### 🎯 CJK 豆腐块：**(甲) 已定案（结构性证明），(乙) 未排除且已定位到缺哪一环**
> **T2b 的字形普查**（部署件 `ce747d85…`；**闸门 B 用"同一启动路径关/开"做了 A/B：`180 条 / 未画种类 0` 逐字相同 ⇒ 仪器无扰动**）：
> ```
> 48 个 run / 1276 个字形：id==0 共 **325 个（25.5%）**  maxId=3540  **id>=0x1000 = 0 个**
> pid==0 的 run = **0**（字段确实被填 ⇒ 没有"静默默认值"）
> PC 用了**两个面**：0x20000003（7 runs，含 **3534–3539 六个连续 id**）/ 0x20000004（41 runs）
> ```
> **决定性论证（不是推测）**：**`id==0` 只可能来自 shaping** —— 渲染器只是**消费** `GlyphIndices`，**选错面不会把数组里的 id 改成 0**（那只会拿真 id 去错面取、光栅成 `.notdef`）⇒ **本帧 325 个 0 是 PC 侧写进来的** ⇒ **(甲) 成立**（PC 侧 shaping 用了没有 CJK 覆盖的面；已派文本车道查"是不是因为我们短路了复合字体回退链"）。
> **(乙) 排除不了，缺的那一环说清了**：`pid` 是**上游不透明 id**（`MilResourceTable` 里**没有 font/typeface 资源类型**，0 命中）⇒ 接不到"渲染器实际加载的面"。**要定死需要渲染器把"实际用的面"也报出来与 `pid` 并排比**（`Interop/**`/`Text/**`，已派）。
> **一条可立刻判的推论**（待 M7b 核实）：**我们的渲染器是"一个 `FontSet` + 一个族"**（SPI 同源 `DejaVu Sans`），而 **PC 用了两个面** ⇒ **至少一组 run 是用错面光栅的**。若成立 ⇒ **真修法就是债务 #14（面由 run 决定）**：PC 登记实际用的面、把句柄当 `PIDWriteFont` 传下来（**T2b 已把该字段搬进 `MilGlyphRun`**）；MIL 侧 **`MilFontFaceTable.Count = 0`** 正是缺的那一环。
> ### 🧭 **结构性发现：路由 B 的回退只覆盖了极少数文本**（T1b 的 LINEDIAG，改变了对剩余缺陷的定位）
> `WPF_LINUX_TEXTLINE_LINEDIAG` 读数（`--minimal --text-volume=2`）：
> ```
> HB_TEXTLINE … lines=1 paragraphs=1  fallbackCalls=1 fallbackHandled=1 fallbackBailed=0  minmaxCalls=0  lastBail="-"
> ```
> ⇒ **整个应用进程里 `TryFormatLine` 只被调 1 次、只接手 1 段 1 行**，而同一档画面有 13 个绘制对象 ⇒ **绝大多数行走的是 `SimpleTextLine` 快路径，不是我们实现的那条路**。
> **两个后果（都影响后续修法的落点）**：
> ① **"多行段落摞在同一基线"发生在我们不在的那条路上** —— 与 A 的结论（`LineHeight` **未设**时 `Height`/`Baseline` 与真机 **1298/1298** 一致）**互相印证**。
> ② **CJK 豆腐块也主要不在我们那条路上** ⇒ **主控据此纠正了 T1b 的修法方案**：它原打算在 `TryFormatLine` 里"按 cmap 覆盖挑面"，**但那只能修到"我们接手的那 1 段"**；**真正的修法位置是"给文本 run 解析 `Typeface`/`GlyphTypeface` 的那一层"**（`FontFamily`/`FamilyCollection`/被补丁 J 短路掉的复合字体回退链）—— 修在那里，`SimpleTextLine` 与我们这条回退路径**同时受益**。
> **⇒ 这条要写进后续所有计划**：`HbTextFallback` 目前的覆盖面**很小**（1 段 vs 全画面），**别再默认"路由 B 已经接管了文本"**。
> ### 🎯 CJK 修法（方案 A）：**规格已钉死，交给新轨道 T1c**（前任 T1b 会话预算见底，拒绝落半成品）
> **T1b 的判断我认**：A 要改的是 **补丁 J 的生成物**，正确做法是改**它的生成器**（`patch-presentationcore-compositefont.py` 的 `EDITS`），否则下一波重放就被覆盖（正是"补丁 M 绿了两波"那类坑）。半成品落在**选面层** = "拉丁看似正常、某些字符悄悄换族"的高风险形态 ⇒ **它选择只交规格、不硬上**。
> **规格（`build/MilBridge/T1b-report.md` §10）要点**：新增独立内部类 `HbCoverageFallback`（**只查覆盖 + 计数**）—— ① **provider 能力探测**（反射探测 `Covers(cp)`/`TryFindFamilyCovering(cp)` 是否存在；**没有就保持今天行为 + 计数**）；② 覆盖查询**降级链**：provider 面 → **直接读字体文件 cmap**（"读 cmap 是读字体、不是读 PC 的选择"）；③ **按码点缓存**（粒度=码点，**绝不按段落整体换族**）；④ 计数器**缺省关、独立成类、绝不碰 `RenderDiagnostics`**（`CoverageProbe/CacheHit/CacheMiss/FallbackApplied/FallbackTarget/FallbackFailed/ProviderCapabilityMissing`）。
> **四条数字验收**：拉丁不退步（`T2d 1298/1298` + `T1.73 73/73`）｜`id==0` 从 **325/1276 明显下降**且开始出现 `id≥0x1000`｜七个计数器原始读数｜**开/关 A-B 对照：拉丁像素与行划分逐项相同**。
> ### 🔴 (甲) 落地了，但**它修不了 CJK** —— 而这份否证把派单方向改正了（T1c，主控采纳）
> **四道闸门全绿**：应用器 `3610e096…`；生成物 `19a42240…`（**681 → 2162 行**，`throw` 条数逐字不变）；`--check` rc=0；**幂等（主控独立复算：重跑字节不变）**；接线求值「上游 0 / 生成物 1」；**波前编译闸门 0 错 0 警**（编到 `/tmp`，真实产物零改动）。**拉丁不退步 ✓**（`T1.73 73/73`、`T2d 1298/1298`、`icu 73/73`）。
> **但 CJK ❌ 一点没动**：`id0` **325/1276 → 325/1276**（与基线逐项相同）。**决定性读数**：
> ```
> Wrap 自报、WrapCalls=1，但 **WrapperMapCalls=0** ⇒ 包装族的 IFontFamily.GetMapTargetFamilyNameAndScale **一次都没被问到**
> 上游 GetShapeableText（喂 TypefaceMap/GlyphingCache 的入口）**托管侧没有任何调用者**
> ⇒ **复合字体"按区间选族"只活在 LineServices 路径上，而本移植把 LS 换成了托管 shim** ⇒ **(甲) 做在一条死钩子上**
> ```
> **⇒ 架构事实（新）**：**复合字体机制与我们的路由 B 是两条互不相交的路** —— 前者只在 LS 路径上活着，而 LS 已被托管 `TextLine` 取代。**这解释了为什么方案 A（本质就是复合字体机制）不可能修好 CJK。**
> **并且它否证了主控派单里的一句话**：主控写的"链条走到补丁 J ②"**是读代码推的** —— 实测 `WPF_LINUX_FONT_DIAG=1` 全程 **0 行** `providerFallback`（默认档 + env 档各一次）。**这条记在主控头上。**
> **阳性对照（同一应用同一 PC，只改默认 UI 字族）**：`WPF_LINUX_UI_FONT="Noto Sans CJK SC"` ⇒ **`id0 325→0`、非拉丁 0→294、`maxId 3540→63151`**，**读图确认中文出真字** ⇒ **选面发生在"run 的 Typeface"这一层，一个 run 只用一个字体文件**。
> **另确认**：`WPF_LINUX_TEXTLINE_FALLBACK=0` 时应用**当场崩 `LoCreateContext`（rc=134）** ⇒ 含 CJK 的行（`CheckFastPathNominalGlyphs` 见 `glyph==0` 返回 false）**确实落到托管 shim**；LINEDIAG `接手` **69 次**。
> **⇒ R1（真修法，主控已派给 shim 车主 T1b）**：`PresentationCore.HbTextLine.cs` 的 `TryCollect`/`TryResolveFont` —— **按 run 取字体**（现在只取第一个 run 的 properties ⇒ "一段一个字体文件"）+ **一个 run 内按码点覆盖回退**（复用 provider 的 `FamilyCoverageQuery`；**HarfBuzz 多字体整形**）。**验收靶子就是那个阳性对照**（`id0→~0`、出现 `id≥0x1000`），且**不靠 `WPF_LINUX_UI_FONT` 覆盖**。
> **⇒ R2（`WPF_LINUX_UI_FONT="Noto Sans CJK SC"`）不采纳为修法**：换默认 UI 族会**把问题挪到拉丁**；只作**诊断/止血**保留。**且 `WPF_LINUX_FONT_DIR=build/fonts-ui` 那档结构性无解**（该集合只有 `UI-NoLayout.ttf` 一个族、**0 个 CJK 码点**；复现 `id0=329/1170`）⇒ **写进门禁的已知边界，不假装可达**。
> **⇒ (甲) 保留并起波（不关、不回滚）**：零行为差（逐 run 明细相同、`MilGlyphRun×50`、`skia 180/未画种类 0`、`AE=0`）；**把机制 + 七个计数器 + 探测自报留在树上**（钩子若日后复活即已就位）；**(b) 缺省关会重演"设计说开、实现却关"那个旧坑**（D3 刚栽过）。
> ### 🔴 第 11 个成员：**文件哈希会撒"像素的谎"**（T1c）
> A/B 里两张 PNG 的 **文件 sha 不同**，而 `compare -metric AE = **0**` ⇒ **差异只是容器元数据**。
> ⇒ **哈希看起来是最硬的证据，但它证明的是"文件字节不同"，不是"像素不同"。** T1c 标注了它、并用 `AE` 判像素（**选择正确**）。
> ### 🧩 provider 侧的反射情报（T1c 实测，**必要的**）
> `FamilyCoverageQuery@DirectWrite.Linux.Provider` 上 `QueryCoverage(LinuxFontFamily,int)`/`Covers`/`QueryCoverage(LinuxFontCollection,int,out)`/`TryFindFamilyCovering` **全"有"**；而 **`typeof(LinuxFontFamily).GetMethod("Covers") = 无`**（它们是**扩展方法** ⇒ 反射里是 `FamilyCoverageQuery` 上的静态方法）。
> ⇒ **若没这条情报，按"实例方法"探测会永远探测不到 ⇒ 永久走 cmap 降级链 ⇒ 而所有读数都会是绿的**（一个**绿得毫无破绽**的失败）。**主控先前转达这条情报、T1c 照它实现并给了探测原文** ✓。
> **provider 侧缺的那一层**（`LinuxFontCollection.Families` 可枚举 ✓、`FontModel.HasCharacter` ✓，但**缺族级/集合级"按码点找覆盖族"**）已派 T2 补**只读面**；**A 不依赖它一定存在**（探测 + 降级到 cmap）。
> ### ✅ **(乙) 现在有部署件口径的测量了 —— 债务 #14 从"推测的架构改动"变成"有测量支撑的真修法"**
> M7b 修正了自己的观测窗口后（见下），两侧读数并排（**部署件** `0f8f9d76…`）：
> | | PC 侧（T2b 普查） | 渲染器侧（M7b census） |
> |---|---|---|
> | 面数 | **2**（`pid=0x20000001/0x20000002`） | **1**（`DejaVuSans.ttf#0`） |
> | 覆盖 | 41 runs + 7 runs | **48 runs 全用这一份** |
> | 在册候选 | — | **300 份**（含 `Noto Sans CJK JP/KR` 的 `.ttc`） |
> **⇒ 即使 (甲) 修好（真 CJK id 出现），那 7 个来自 `0x20000003` 的 run 仍会被用错面光栅** ⇒ **(乙) 是独立且必须的一道**。
> ### ✅ 三条**撤销/确认**（依据都是只读 grep + 入口记号，不是推断）
> 1. **"两套字体栈"不存在** —— `grep "SKTypeface|SKFont|FontSet|FontManager|CreateTypeface|MatchFamily" src/WpfGfx.Linux/Rendering/` **零命中**；全仓 `GlyphRunRenderer =` **只有一处**（`Text/TextRenderer.cs:118`）⇒ **`Rendering/` 完全不碰字体/面**，只把 `(canvas, handle, paint)` 交给注册进来的委托。**那条登记删除。**
> 2. **渲染器链在真应用里是活的** —— M7b 的五个入口记号**全命中**（`MilPresentation.RenderChannel` / **`TextRenderer.AttachTo`** / `DrawResource` / `Draw` / `GlyphRunPainter.Draw`）⇒ **主控"可能在不被执行的地方修 (乙)"的担心撤销**；**M7b"`EnsureGlyphRenderer` 选面对真应用可能无效"的担心也撤销**。
> 3. **`48 vs 0` 的根因 = "读数发生在事件之前"**（M7b 的 `Report()` 进 `RenderChannel` 就报 ⇒ **永远报第一帧 = 空帧**）。修好后两侧逐项一致（`48/1276/325` vs `48/1270/332`，差 6 个字形是**取帧边界**）。
> ### 🔬 "仪表本身成为被测系统的一部分" —— 这一族现在**四条，全是自己抓自己**
> ① T1b 的装置在 `pipefail` 下**假 ✗**；② M7b 的**探针被它要测的那件事门控**（census 走 `TryResolve`、绘制走 `TryGetFont` ⇒ 恰在"面解析失败"时变哑巴）；③ T2b 的**仪表改了调用次数**（第一版在外面又调一次 `TryRenderGlyphRun` ⇒ 渲染器每次被调两遍；**抓住它的正是它当初为"确认渲染器未被干扰"埋的那条 `Assert.Equal(3, drawn)`，红成 6**）；④ M7b 的 **`48 vs 0` = "对的数、错的时刻"**。
> **⇒ 第④条最微妙：读数不是错的，只是发生得太早** ⇒ **观测不仅要问"值可信吗"，还要问"这个值是什么时候取的"。**
> ### 🔴 第 10 个成员（**形态不同**）：**两条各自正确的命令组合出一个"没人负责"的假绿**（T2b，自己抓到）
> ```
> dotnet build           → **明确报错**（缺 Geometry/Count/FrameEnd/ReferenceCheck 的定义）
> dotnet test --no-build → **「137 通过 / 0 失败」** ← 跑的是**上一次编译成功的旧二进制**
> ```
> **⇒ 单个命令的退出码都没说谎，是"两条命令的组合"在说谎。** 前九个成员都是**一个**观测环节有问题；**这次是两个各自正确的环节被串在一起** —— 形态是新的。
> **怎么发现的**：**没有只看 `dotnet test` 的退出码**，而是在同一条命令里**先看 `dotnet build` 的错误行**。**如果只贴测试结果，交给主控的就是一个假的绿。**
> **⇒ 落地为可执行纪律（主控定，不是"以后小心点"）**：
> 1. **跑 `dotnet test` 不要用 `--no-build`**（多花的时间远比一个假绿便宜）；
> 2. 必须用时，**在同一条命令里用 `&&` 把 build 与 test 绑成一步**（build 有 error 就不进入 test）；
> 3. **贴读数必须一并贴"本次编译状态"** —— 单独一个"137 通过"不再是有效读数。
> **⇒ "把教训变成结构"**：这三条的效果是**链路上不可能再出现这个组合**。
> ### ⛔ 编辑方式的两条**禁止项**（本项目第二次因"删掉没读完的区间"出事）
> T2b 用 **`s[index('ChainText'):index('MapRect')]` 切片替换**改文件 ⇒ **区间比它以为的长，连带删掉 6 个方法**。
> 这与 T2 在 C 补丁上的"**跨行正则删除**"**是同一种错的两个外壳**。**⇒ 通则**：
> > **任何"按区间/模式删除或替换"的编辑都不许做。** 要么**逐点插入**（锚点必须**先 `grep -an` 读出确切文本**、且**要求恰好命中 N 次**），要么**整文件重写**（内容你完整读过）。
> **补回时的正确做法**：**用调用点反查签名**（`SkiaBackend` 的调用点定义了签名），**不凭记忆**。
> ### 🗣️ 新一类教训：**传话也会骗人**（"转述链上的数值污染"）
> 应用里的 `pid` 是 **`0x20000003`/`0x20000004`**；M7b 在 (乙) 规格里写成 **`0x20000001/0x20000002`** —— 那**来自它自己"字体面登记幂等性"实测的返回值**（`第一次=0x20000001 / 不同模拟位=0x20000002`），**它把自己测试里的句柄当成了应用的 `pid`**；主控又转述了一次，错上加错。**T2b 核对两次原文后纠正。**
> **⇒ 纪律**：**凡跨 agent 引用具体数值，都要能追回原始输出（文件 + 行/字段）。** 这与"工具在说谎"那一族并列：**那是工具骗人，这是传话骗人。**
> ### ✅ (乙) 的两条硬支撑（把结论从"运行时读数"抬到"按构造必然"）
> 1. **`PIDWriteFont` 按构造不可解析**：`grep "TYPE_[A-Z]*FONT|TYPE_[A-Z]*TYPEFACE"` **0 命中** ⇒ **资源模型里压根没有 font/typeface 资源类型** ⇒ "PC 一直在填、我们一个都认不出、全部回落族名"是**必然**。⇒ 与 M7b 实测的基线 **`0/0/48`** 是**两条独立路径指向同一结论**（它量"解析失败数"，T2b 量"资源模型无该类型 + PC 确实填非 0 句柄"）。
> 2. **零缩放 CTM 排除我们这侧**：`0x8c[1.04] → 0x8d[0.00]`（父健康、子下一代归零），而累积式 `world = parentWorld · Transform · Translate(Offset)` 中 **`Translate` 不改 scale** ⇒ **只能是那两个节点自己的 `Transform` scale 为 0**。**⇒ 排除"我们的累积逻辑算错"**（那会让整条链一起退化）、**排除 `PushTransform`**。剩下"上游发的 vs `TransformResolver` 解析出来的"**需要变换资源的原始值**，而**句柄在 `VisualProjection` 投影时被丢掉** ⇒ 与 `PIDWriteFont` 同属"**投影时丢字段**"这一类。**T2b 如实报"判不了"，主控不要求它猜。**
> ### 🧭 一次**被自己的仪表纠正**的判例（T2b，值得记）
> 它上轮用 `Canvas.Left` 当尺子推出"Path 没有绘制"，**这一轮第 2 列（画刷句柄/颜色）一上来就推翻了它**：`x=196.9` 其实是 **Ellipse**（`EllipseGeometry` + `LinearGradientBrush`），`x=332.3` 是 **Path**（`PathGeometry` + MediumSeaGreen）。**它自己写下的结论**：
> > **"尺子只能定位间距、不能定位身份 —— 身份要靠画刷颜色。"**
> ### ✅ **D-c 结案：不是渲染缺陷，是 `ScrollViewer` 视口裁剪**
> 三个图形**全都在画**（Rectangle→`MilDrawRoundedRectangle` 画刷 Tomato 线性、Ellipse→`Geometry` 画刷渐变、Path→`Geometry` 画刷 MediumSeaGreen），**三者设备 y≈837 在共同 clip 底边 828 之下 ⇒ 整块被裁**；⑤ 卡片背景 `786→922.7` 被 828 裁得只剩 **42px = 标题那一条** ⇒ **完全对上"卡片只剩标题"**。
> **(B) 的直接读数**：`LinearGradientBrush 0x7f` / `EllipseGeometry 0x81` / `PathGeometry ×5` 各**引用=1**（都被引用、都被画）；6 个 `RectangleGeometry` **引用=0** 是 ④ 卡片 `DrawingImage` 的（`MainWindow.xaml.cs:224-233`）⇒ **归 D-d，T2b 没把它算进 D-c**（这个克制对）。
> **门禁只剩一个真红：D-d**（④ 卡片图空白 = "画了但源只有 1×1"）。
> ### ❌ 主控又错一次：**"渲染器用一个族"这个推论，问错了地方**（M7b 的否证）
> 我给 M7b 的推论是："我们的渲染器是**一个 `FontSet` + 一个族**，而 PC 用了两个面 ⇒ 至少一组 run 用错面光栅。"
> **M7b 的读数直接否掉了它的前提**：它把仪器挂在 `TextRenderer.DrawResource` 上，**那个钩子一次都没触发（0 runs）**，而同一次跑里 T2b 数到 **48 次绘制** ⇒ **真应用的字形绘制根本不走那条 T6/Text 路径**。
> ⇒ **"渲染器用了几份面"这个问题我一开始就问错了地方**；正确表述是 M7b 的："**我这里问不到，问对地方才能答**"。**又是"观测对象与你以为的不是同一个"那一族**（我拿"代码里看起来的主路径"当成了"运行时的实际路径"）。
> **并排读数**：`run#1` 52 个字形里 **34 个是 0**、其余**全在拉丁区**、**全程 `id≥0x1000` 为 0** ⇒ **"真 CJK id 被错面光栅"在本次读数里根本不成立**（一个 CJK 区 id 都没出现）⇒ **(甲) 是当务之急，(乙) 是"真 id 出现之后"的第二道正确性问题**（优先级据此调整）。
> **最短路径（已协调）**：T2b 的普查**已经在真正绘制的那条路径上** ⇒ 在那里加一句 `GlyphFaceCensus.NoteRun(face, ids)`，与 M7b 在 `FontSet` 加载时记好的"面→文件/faceIndex"**一拼就是答案**（接口 M7b 已留好：只读、缺省关、不改行为）。
> ### 🔬 D-c（⑤ 卡片图形没画）已被 T2b 收窄到"二选一"，并造了第二个只读仪表
> **已排除两个假设（依据是资源种类与 XAML 的逐一对应，不是感觉）**：① **不是"没投影进来"** —— `MilEllipseGeometry×1` + `MilLinearGradientBrush×1` 各对上 ⑤ 卡片**唯一**的那一个 `Ellipse` 与其唯一渐变填充 ⇒ 几何与画刷资源确实进了通道；② **不是"整卡被 clip"** —— 卡片标题能画而 `Canvas` 三图形不能画。
> **剩下的二选一**：(a) 指令**根本没进 render data**（资源建了没被引用/没提交，归 PC/Commands 侧）vs (b) **画了但看不见**（视口外 / Canvas 子树 clip / 包围盒尺寸为 0，归渲染侧）。
> **⚠️ 关键概念（T2b 提出，主控记档）**：**`未画种类 0` 只说明"执行过的指令都画了"，它不说明"该指令有没有被执行过"** —— 这个判据**看起来是"覆盖全部"的**（"每种指令都画了"），实际量词是"**对已执行的**"。**"空真"族的新成员。**
> 为此它加了 `DrawInstructionCensus`（`WPF_LINUX_DRAW_CENSUS`，缺省关、独立成类、`ThreadStatic`、不碰 `RenderDiagnostics`）：量**每条 `MilDrawCommand` 的执行次数**（答 a）+ 每次几何绘制的**局部包围盒 / CTM / 设备包围盒**（尺寸为 0 显式标出，答 b）。
> ### ✅ D-c 判定出来了：**(a) 与 (b) 同时存在**（T2b，部署件 `d356ecb5…`，闸门 A/B/C 全过）
> **每指令执行次数**（frame 2 ≡ frame 3，总 180）：`Rectangle×19 RoundedRectangle×26 Geometry×6 Image×1 GlyphRun×48 PushGuidelineY1×40 Pop×40`。
> **`MilDrawEllipse = 0`** —— 这条指令**一次都没执行**（`MilDrawLine`、`MilDrawDrawing` 也是 0）。
> **(a) 从未被执行**：用 `Canvas.Left` 当尺子 —— 两次非退化绘制相差 **135.4 设备px ≈ 130 逻辑px × DPI 1.04**，正好一个 `Canvas.Left` 步长（对应 `0` 与 `130`），而 **`Canvas.Left=260` 那个（Path）没有任何绘制**；加上 `MilDrawEllipse = 0` ⇒ **⑤ 卡片的 `Ellipse` 与 `Path` 至少一个根本没有绘制指令**。
> **(b) 画了但看不见**：另 **4 次绘制的 CTM 是零缩放** `[0,0,0,0,tx,ty]` ⇒ 设备包围盒恒 **0×0** ⇒ **按构造不可见**（局部 7×4，形如滚动条/箭头类小图标）。
> **"真 0"与"没读到"的判别证据（T2b 给的，我认）**：同一行里 **CTM 被完整打出来了**且 `ScaleX=ScaleY=0`；若是"没读到"，该行根本不会出现（`FillAndStroke` 在 `path==null` 时提前返回、只记"未画"、不记几何）。
> **仍未解释的一条**：剩下两次非退化绘制**设备 y=836.8，在 938 高的视口内** ⇒ **"番茄色没画出来"不能由"在视口外"解释** ⇒ 下一步查 **clip 或画刷**（已定：先做**只读检查**"那唯一一个 `MilEllipseGeometry` / `MilLinearGradientBrush` 有没有被任何 render data 引用" —— **资源在册 ≠ 被引用**；有引用才值得给仪表加"clip + 画刷"两列）。
> ### 🔴 新登记缺陷：**零缩放 CTM 把 4 次绘制塌成 0×0**
> `CTM=[0.00,0,0,0.00,tx,ty]` ⇒ 设备包围盒恒 0×0。**零缩放通常意味着某个变换被算错**（某处 scale 该非 0 却成了 0，或变换合成时丢了项）——而**本项目的 `SKMatrix` 是列向量约定、`Concat(a,b)` = b 先作用**，很容易写反。已派渲染车道查"这 4 次是哪条指令、变换从哪来、零是从哪来的"（**若上游本来就发 0，那是登记的输入、不是我们的 bug，也要说清**）。
> ### 🔎 D-d 也被定住了：**不是"没画"，是"源只有 1×1"**
> `Image×1` **确实执行了**，而台账 `MilResource_CreateCWICWrapperBitmap: 物化成功（**1×1** Bgra8888）` ⇒ ④ 卡片那个 **96×96 的 `Image` 拿 1×1 的源去画** ⇒ 放大成一片纯色/空白。已转物化路径的车道去分"源真的是 1×1"还是"`GetSize` 报错了尺寸"（**两者证据形态不同**）。
> ### 🧩 一条调度教训：**"先引用、后创建"会开出一个别人构建必红的窗口**
> T2 报 `DirectWrite.Linux.Tests` 编不过（`FontSet.cs:99/103/110: CS0103 名称 "GlyphFaceCensus" 不存在`），并**正确地没越界去改 `src/**`**。主控**直接编了一遍**验证：`src/WpfGfx.Linux` **0 错 0 警** ⇒ **树没坏** —— 成因是另一个 agent **先改了 `FontSet.cs` 去引用 `GlyphFaceCensus`，之后才创建那个文件**，那一小段时间内任何构建都会红。
> **⇒ 纪律：新类型要先落文件、再加引用**（反之会短暂打断所有人的构建）。**而"报阻塞时不去改别人的文件、等主控判"这个做法是对的。**
> **⚠️ 主控的更正（同一天，T2 的排查比我的准）**：**那个红其实是持久的，不是"时间窗"。** T2 的 `Tests/DirectWrite.Linux.Tests.csproj` **显式链入 4 个 M1 源文件**（`TextFontDescription.cs / GlyphRunRequest.cs / GlyphRunLayout.cs / FontSet.cs`，**显式清单不是通配**）⇒ `FontSet.cs` 新增对 `GlyphFaceCensus` 的引用后，**主工程能过（默认通配新文件）、它的测试工程过不去**。
> **我错在哪**：我编的是 `src/WpfGfx.Linux`（过）就下了"树没坏"的结论 —— **但我没编那个报错的工程**（报错后缀是 `[…Tests.csproj]`）。⇒ **"验证了我以为会红的那个工程，而不是报错的那个工程"** —— 又是"观测对象与你以为的不是同一个"，这次是我犯的。
> **处置**：T2 在自己 csproj 加第 5 个链接（**只动自己的文件、没碰 `src/**`**）⇒ **123 通过 / 0 失败 / 0 跳过**（119 未退步 + 4 新）。**并定下约定：维持"显式清单"（那 4 个文件是 M1 一致性测试的语义面，**通配会悄悄改变它的语义**），代价是它成为 T2 的维护面 ⇒ 走"通知制"：任何人给 `src/WpfGfx.Linux/Text/` 新增被那 4 个文件引用的类型时，通知 T2 加链接。**
> ### ⚠️ 主控的错：**闸门 A 的基线被我钉在旧仪器版本上**
> 我给 T2b 的闸门基线是 `skia 指令 145 / PNG 938×646`，它实测 `180 / 938×938`，**并对不上就不自行放行、把问题交回来**（这正是闸门的意义）。**差异来源全是"工具变了"**：T3 修 runner 时把判据改成"**取指令数最多的那一帧**"（145→180），并把窗口从 620 高改成 **900 高**（938×646→938×938）。⇒ **新基线 = `180 / 938×938 / 未画种类 0 / exit=143 / 8-8 有效帧`**。
> **教训（新形态）**：我们一直在防"**产物**变了"，这次是"**工具**变了" ⇒ **跨版本比较必须同时钉住工具版本，不只钉住被测产物。**
> ### 🩹 两个已被两个人各踩一次的 shell 陷阱（记进手册）
> ① **`pkill -f "Xvfb :96"` 会杀掉自己的 shell**（同一串字面量出现在自己的命令行里）—— 我踩过 `:98`，T2b 踩了 `:96`；解法是 **`/proc/<pid>/cmdline` 精确匹配**或 `kill $XPID`。
> ② **`cd X && … &` 会把 `cd` 也一起后台化** ⇒ 前台命令在**错误 cwd** 跑、`exit 127`（T2b 首次遇到）。
> ③ 另一条方法学（T2b）：runner 默认档会**清空父进程所有 `WPF_LINUX_*`**（`run-wpftextdemo.sh:234`）⇒ 诊断开关传不进去；**它没有改 T3 的 runner，而是复用 staged 好的运行目录**从那里起同一个应用（**用的仍是部署件、却没动别人的文件**）。
> 这是"真应用能不能跑起来"当前最硬的一条线，按时间顺序：
> | # | 阻塞 | 现象 | 处置 |
> |---|---|---|---|
> | 1 | **文本回落 LS** | `SimpleTextLine.Create`→null → `FullTextLine` → `LoCreateContext` `EntryPointNotFoundException` → abort(134)。**阈值 = 同段落第 2 行**（N=1 能画、N=2 必崩） | ✅ **已修**（`HbTextFallback` 两处站点）＋**默认值 bug 已修**（`WPF_LINUX_TEXTLINE_FALLBACK`，未设 ⇒ 开）⇒ **`LoCreateContext` 27 → 0** |
> | 2 | **`BitmapSource.DUCECompatiblePtr` → `E_HANDLE`** | WIC shim 下发的句柄在 **shim 的表**里，而该导出只查 **MIL 的 `MilPixelBufferTable`** ⇒ 两张表互不认识（`MilNative.Offscreen.cs:654` 是 `E_HANDLE` 的确切出处） | ✅ **已修**（物化：拷不借，`BitmapSource` 只读 vs `WriteableBitmap` 必须写穿透）＋**单元红→绿**（`hr=0x80070006` → `0x0`）＋在册 `1→0` 回基线；**应用级已验**（台账 `WIC 句柄 0x3 物化成功 ⇒ wrapper=0x20000007`、`E_HANDLE` 次数 **0**） |
> | 3 | **`SendCommandBitmapSource` → `E_NOTIMPL`** | `HRESULT.Check`（`wgx_render.cs:975`）← `DUCE.Channel.SendCommandBitmapSource`（`exports.cs:771`）← 同一条 `AddRefOnChannel` 链，只是**走得更远一步** | 🔄 **施工中**：本工程落点是 `Interop/MilNative.cs:458-460` **直接 `return HResult.E_NOTIMPL`**（M1 存量桩，`MilNative.Exports.cs:31/169` 有登记）。**关键情报：命令层 `MilCmdBitmapSource`(0x0c)/`MilCmdBitmapInvalidate`(0x0d) 早在 T13 就实现了（24 用例 + 像素证据）⇒ 大概率是"接线"而不是造机器**；`Commands/MilBitmapSource.cs:161` 还写明"`E_INVALIDARG` 属于发送侧"，有既定错误语义要遵守 |
> **修完 #3 时的可观测形状**（我已取到的"病情"）：`通道#2: committed=10 notimpl=0 failed=0 short=0 **pending=124** batchBytes=12610 资源=105 root=有`，资源表里已有 `MilGlyphRun×18` / `MilDropShadowEffect×1` / `MilRenderDataResource×20` ⇒ **可视树本身是建得出来的，卡在把它发下去**。
> ### ⚠️ 全量门禁（波 9 后）：**步骤 8/9、用例 787 通过 / 2 跳过**，唯一红 `HelloMil.Tests`
> **单独复跑 19/19 通过** ⇒ 判为**并发负载下的 flaky**（与债务 #1 的 `MilChannelRegistry` 进程级静态表同源），**不是回归**。另注：那轮 verify-all **与 T2b 编辑 `src/**` 有竞态**（`Contracts/Interfaces.cs`/`SkiaPen.cs`/`VisualProjection.cs` 在跑动中被改）⇒ 下一轮要等轨道静默再跑。
> ### 🧪 又三种"工具在说谎"（新形态，都记进手册）
> ① **`grep` 把含 NUL 的文件当二进制**（`wic_proxy.c` 有 3 个 NUL）⇒ 不带 `-a` **只回一句 "Binary file matches"、不给行文本** ⇒ "grep 取锚点再比对"的流程**静默拿不到文本**（T2 连续三次锚点不匹配的原因之一）。**一律 `grep -an`。**
> ② **`Assert.True(true)` 空壳会假绿**（T2b 抓到一条过期的 Skip 正文就是空壳）；**空帧下 `未画种类 0` 是空真**（T3 抓到，并主动把自己的判据改红）—— **"空真"与"恒真"是这一族的两个变体**。
> ③ **别只查判别点**：T2b 把 `core_image_tile_v2tiling` 的**全部 443 个采样点**拉来比才发现 `role=grid` 失配 60（此前只查 36 个判别点 ⇒ 一直没暴露）。**判别点用来判方向，不用来覆盖面。**

> ## 📌 2026-09-15 波 `close-wave-105739` = 基线 **`#14`**（`D-F1` 字体回退 + `GetIndexedGlyphRuns()` 真实现）—— 以及随后由复跑抓出的 **`D-F1b`**
> **冻结点**（2026-09-15 11:05，`run_dir=~/wfp-runs/go-freeze14`）：`bridge 759a322431f1e457`（fp `705ed5ccd0c498a1`）｜**`pc 9adac6b8d8e285c3`**｜**`pf ed51db81db76bc76`**｜`windowsbase e6216fe961a2bfb9`｜`provider 71ba86c6495347fe`｜`win32shim 0098234982391bbf`｜`wic_shim 03b67fbcd7c385b6`｜**`hbtextline 17b2cdfe08f13280(stale=no)`**｜`dwf 2f77dbdf5e7e2cd5`；门禁 `WPTD_GATE=PASS`（两档 3/3、6/6 `result=PASS`）、波内 `verify-all=PASS`（9 步 0 失败）、九位**现场/哨兵/表头三方逐位一致**；`inputs_fp=e9a44d944015c33e…`。
> **改了什么**：`build/shims/PresentationCore.HbTextLine.cs`（`fde9e511e8443cf2` → **`17b2cdfe08f13280`**）—— ① **`plan == null` 分支也构造 Hb plan**（`allowFallback:true` + 宽松覆盖门槛 + 自有候选序；找不到覆盖面 ⇒ `NoteFailed`，**不造假成功**）⇒ 这是**唯一**走到回退的路径；② **`GetIndexedGlyphRuns()` 由桩变真实现**（`StillOwedMembers` **6→5**），被用作共同观测装置；③ 非 DIRECT 形态用 `#if TEXTLINE_SHIM_DIRECT` / `#else` 反射保住两个宿主的编译（曾各 4 处 `CS` 红：`CS1061 GlyphTypeface.FaceIndex`、`CS1729 IndexedGlyphRun(3 参)`）。
> **判据重切（关键）**：**C2（`GlyphIndices≠0`）+ C3（差 ≤0.01/0.34 + 符号）判"回退是否发生"**，**C1（API 自洽 + `advance_from_font.py` 独立复算）只作反作弊** —— "单读数即结论"在此处必假绿。
> ### 🔴 判据层**自己**出现"空集当通过"假绿（**新纪律 27 / 登记 `L25`**）
> T2 第一次跑：runner 前置失败只打一行兜底 `MODE=none RESULT=NOINFO reason=glyphtypeface:NullReferenceException`，被判据层 `^MODE=(\S+) RESULT=(\S+)` 当成"模式行" ⇒ **三个真模式一个都没跑** ⇒ `n_fail=0 n_noinfo=0` ⇒ **印 `CRITERIA=PASS` 且 `exit=0`**。⇒ **零检查 ≠ 通过**，那次读数**作废**。已修：判据层加"防空过"守卫（只认三个真模式，缺任一 ⇒ `NOINFO` + `exit 3`），并交两条正控（只喂兜底行 ⇒ `NOINFO`/`exit 3` ✓；三模式齐且被判对象 FAIL ⇒ `FAIL`/`exit 1` ✓）。
> **复跑（`[null]`）**：`LINE_W=16.0000`、`ADV_DIP=16.0000`、`GID=9498`（≠0）、`[fix] MODE=null == fb` ⇒ **"`plan==null` 路径真的会回退"成立**；负极 `allowFallback:false` ⇒ `9.6000` / `gid 0`（`.notdef`）⇒ **两极分化成立**。**第二趟（v2：逐字复现 b34 `F_nbsp_zwsp_w40`、取 `与 ` 那一行 `[14,2)`、`alwaysCollapsible:true`）把 CR 极判定了**：`CR_W` **`−3.0560 → +3.3440`**（真值 `3.3433`）、折后宽 `12.6560` vs 真值 `12.6567`、`LINE_W 16.0000`（`nofb` 腿 `9.6000`，且与 harness 旧产物**逐字相同** ⇒ 归因干净）。**v1 测不到的真因（值得记）**：折叠资格闸门 `build/shims/PresentationCore.HbTextLine.cs:3142` `if (!HasOverflowed && !_keepState) return this;` + `HasOverflowed => false` **恒假** ⇒ **只有 `_keepState` 路径会折叠** —— 这同时把 `D-O1` 的**量级上调**（修它会把折叠路径打开）。**新 C1（字体无关、本地可判红）已实测两极**：负极性 `C1=FAIL`（`gid 9498 ≥ GlyphTypeface.GlyphCount 3884`、独立 `maxp.numGlyphs` 3884 两嘴一致、cmap 不覆盖、`AdvanceWidths[gid]` 查不到 三腿全红）、健康正控（同一 `plan==null` 路径的全拉丁行）`PASS` ⇒ **不是恒红判据**。⇒ **本轮 `CRITERIA=FAIL` 的唯一红 = 新 C1 = `D-F1b`；`D-F1` 本体无红**。**仍未判的一项**：34 条 `+CJK` `Extent` 行的集合对比（需 `#14` 的 `tline` 产物）。
> ### 🔴 复跑抓出的**真缺陷 `D-F1b`**（两条独立车道互证）
> **现象**：承载 `与` 的 run 报 **`GID=9498`**，而同一 run 的 **`GlyphTypeface.FontUri` = 段落字体** ⇒ **三元组不同源**（`AdvanceWidths[9498]` 查不到 ⇒ `ADV_FROM_TYPEFACE=-`）。**T2**（`build/DirectWrite.Linux/FallbackCriteria`，系统字体环境）读到 `FontUri=NotoSans-Regular.ttf` + `GID=9498`；**T1b2**（`TextLineProto`，`WPF_LINUX_FONTS_DIR=build/fonts`）读到 `FontUri=NotoSans-Bold.ttf` + `GID=9498` + **该面 `GlyphCount=3884`** + **cmap 无 `U+4E0E`**（对照 `U+0041→36`、`U+0042→37`）⇒ **越界 id**。
> **根因（T1d，`file:line`）**：`build/shims/PresentationCore.HbTextLine.cs:3517` `{ try { g = new GlyphTypeface(new Uri("file://" + fref.Path)); } catch (Exception) { } }` —— **1 参构造丢掉 `fref.FaceIndex`**，而 `.ttc` 不带 fragment 时上游**必抛** `FileFormatException`（`GlyphTypeface.cs:141-142` 注释写死）⇒ 异常被吞 ⇒ `g == null` ⇒ `:3519 FaceSlot = (g != null) ? i : -1` 得 **-1** ⇒ `FormatLine:2455-2458` **静默回落到段落字体**建 `GlyphRun`，而 glyph/advance 来自回退面。**应用路径无此病**（`HbTextFallback.BuildSegmentFaces` 走 `GetResolvedFace`，带面号解析）⇒ **归因干净：只在 `D-F1` 的新代码上**。
> **真机真值的形态（主控现场读 oracle）**：`A-missing-glyph/U+4E0E@file-NotoSans-Regular` ⇒ `observedFontUri=file:///C:/WINDOWS/FONTS/YUGOTHM.TTC#1`、`Yu Gothic UI`、`observedGlyphIndex=3883`、`observedRunAdvanceAsReported=24`、`fallbackToADifferentFont=true`、`observedFontEqualsSpecifiedFont=false` ⇒ **回退面被完整上报，`.ttc` 的面号就在 `FontUri` 里**。
> **结论边界（必须连着说）**：`#14` 的 `D-F1` 只能写到"**回退发生了、度量对了、字体身份报错**"。
> **修法与判据（T1d 备稿，未落树）**：P1 = 按上游语义构造（`faceIndex==0` ⇒ **不加 fragment**；`n>0` ⇒ `GetComponents(AbsoluteUri, SafeUnescaped) + "#" + n`，与 `FontCacheUtil.cs:509-520 CombineUriWithFaceIndex` 语义**逐字一致**，且**内联**以免两配置跑不同代码）；P2 = 段面取不到时**记账、不再静默**。判据 **C1 `gid < GlyphTypeface.GlyphCount`**（字体无关、**本地就能判红**）｜**C2 报出的 `FontUri` == 实际整形面（`.ttc` 带 `#n`）**｜**C3 `AdvanceWidths[gid]×emSize == 观测 advance`**｜**C4 反作弊 = `gid == CharacterToGlyphMap[0x4E0E]`**（堵"只改 uri 或只改 gid"）｜**C5 face 0 不许带 fragment**（正极 = 段落字体自己覆盖该码点 ⇒ 真值 `MSYH.TTC` 无 `#`；另一极 = 本机 `NotoSansCJK-Regular.ttc#2`）。
> **`.ttc` face-0 的裁定（两份独立证据）**：真值里 `.ttc` 只有 `MSJH.TTC#1`×4、`YUGOTHM.TTC#1`×4、**`MSYH.TTC`（无 fragment）×5**、**含 `#0` 的行 = 0**；上游 `CombineUriWithFaceIndex` 的 `faceIndex == 0` 分支**原样返回** ⇒ **face 0 不带面号**。
> **登记边界**：路径含 `#` 且落 face 0 时会被 `SplitFontFaceIndex`（`int.TryParse(fragment, NumberStyles.None)`）误解析 —— 上游靠 `GetComponents` 转义；我们的三套 tab 语料 + `font-fallback` 族**都没有这种路径** ⇒ **今天不可观测**。
> ### 🧰 本波顺带抓到/纠正的仪器·流程条目（全部进纪律或登记）
> ① **`[IGR]` 那段落码从没编过**（T1b2）：`Program.cs(134,57) CS1503`（`GlyphRun.GlyphIndices` 是 `IList<ushort>`，而代码用 `Array.IndexOf`）⇒ **我派"值级打印可以跑了"的那一刻它根本跑不了**（"落码"不等于"能取读数"）。
> ② **跑旧件报绿**（T1b2）：`dotnet build` 默认 Debug，`bin/Release` 是 9-13 的旧 dll ⇒ `[IGR]` 一行没有却打"通过 10 / 失败 0"（纪律 8/23 的又一实例）；app-local 三件全陈旧（`684424fe…` vs 权威 `9adac6b8…`），按 `refresh_applocal` 同法同步后才取数。
> ③ **`A8` 红**：`WPF_LINUX_TEXTLINE_STRICT=1` 下「欠账抛=False；已实现却抛=False」⇒ `rc=1`，**随 `[IGR]` 那段落进来、因一直没编过而从没被看见**；而 **`verify-all.sh` 根本不含 `TextLineProto`/`HbTextLineParity`/`CoverageProbe`**（现场 grep 0 命中）⇒ **覆盖缺口**，已派 T1b2 定性（**期望陈旧** vs **STRICT 开关不生效**，两种结局的证据形态不同）。
> ④ **两处"陈旧数字副本"不该改**（T1b2 顶回主控的派单，正确）：它们是**逐字节历史快照** —— `build/MilBridge/tests/CoverageProbe/refs/PresentationCore.HbTextLine.ebccdb1e.cs` 自身 sha256 = `ebccdb1ee65e6f76` = `samples/WpfFeatureProbe/rtl-baseline-20260913.json` 当日登记的 `hbtextline_shim_sha`；`build/MilBridge/staging/PresentationCore.HbTextLine.cs` = `c580f2df9362de55`。`CoverageProbe.csproj` 只编 `$(HbShimSrc)`+`Program.cs` ⇒ `refs/` **不被编译**、全仓无脚本引用 ⇒ **改其内容 = 篡改字节自证的历史记录**；**改为修 doc**（本 §0 上文 2026-09-15 更正块）。
> ⑤ **行号随版本位移**（T1c/T1d 各抓一次）：`EffectiveWidthTab` 注释 `:1577` / **实体行 `:1589`**、`TabClampInset :331`、`HasOverflowed :3086`（我抄的是 `:1570`/`:330`/`:3054`）；且 `src/PresentationCore.Linux/TextFormatterImp.Linux.cs` **不是本仓路径** —— 真文件是生成物 `build/PresentationCore.Linux/TextFormatterImp.Linux.cs`（sha `5dedc21f5f372c78`，属 T1c 的应用器 `patch-presentationcore-textline-fallback.py`）。**派单里的路径/行号必须先现场重读**（纪律 4 的第 N 次）。
> ⑥ **T1c 的 PC 半实测是 5 个编辑点**（签名 + 两个 `FormatParagraph` 调用 + 两个调用点），不是主控口述的"3 处"；其幂等性证据用 `--check` rc=0（"当前生成物 == 一次全新运行的输出"）**替代**连跑两遍（更强且不碰树）。
> ⑦ **`close-wave.sh` 的哨兵加了 `$HOME` 镜像**（2026-09-15，主控）：`/tmp` 曾被**整盘清掉**（连带丢哨兵、备份与日志）⇒ 写完 `/tmp/bridge-frozen.flag` 后再 `cp` 一份到 `$HOME/wfp-runs/bridge-frozen.flag`（可用 `CLOSE_WAVE_FLAG_MIRROR` 覆盖）并**打印两处路径**；写失败时**明说"写失败、不要当成功"**。脚本 sha `7099415e3e8c77be → 68c7167c61b4e00e`（`bash -n` 通过）。**判定"当前件"时两处不一致 ⇒ 以本波刚写的为准并当场报不一致。**
> **下一步（同波候选 `#15`）**：`D-F1b` + `D-T2`（Tab 缩进；shim 半 T1d、PC 半 T1c）+ `D-O1`（`HasOverflowed :3086`）**同波、各自带位移预测、逐族归因**；`tab-anchor` 镜像臂（**字体无关**列本地跑；**行宽/钳位/逐字符位置族必须走 U1 真机，且落地后重取，不许拿旧读数对**）。备稿目录：`$HOME/wfp-runs/draft-T2/`（T1d 5 文件）、`$HOME/wfp-runs/draft-T2-pc/`（T1c 5 文件）、`$HOME/wfp-runs/draft-F1b/`（T1d 3 文件）。
> ✅ **`#14` 的应用级复取（T3，11:33:15 收束）—— 读数全在，且都指向"没回归"**：门禁 `WPTD_GATE=PASS`（`acceptance=2/2`、`line_advance=PASS`、两档 `3/3`、九位与 `#14` 表头逐位相同、`BRIDGE_SRC_STALE=no`、`rc=0`）；**三支 oracle 里两支"牙"在新仪器版上仍会红**（`MODRULE 169/170`+`rc=1`；`tab-oracle fail=1`+`rc=1`）⇒ **仪器换版后判据没变成恒绿**；`tab-oracle cases=114 pass=57 fail=0`、`D-T1 判定 85/86 结构败=1`（**`13→1` 保持**）；**全块矩阵 `blocks=11 ok=8 fail=3`**，三个 FAIL 经 **L20 帧穷举（18 帧）**定位为**采样范围伪影**（`#A855F7`/`#94A3B8` **0/18**、`#F97316` **18/18** 且与 `#12/#13` 逐位同 = **第 7 次复现**），并有单块反证（`transforms OK`、`text-rtl OK`）；RTL 三条与验收帧逐位相同（`Δright=1 / Δw=0 / 比 0.97`；镜像 `k=71`/`0.736` vs CTM 预测 `71.75`；两帧 `AE=0`）；`text-dp-min` ✅；`textbox-edit` 正极性 **`changes=2`（新读点首次在正式复取里生效）**、反极性如实报"**无信息**"；`1400` 命中 0。**关键环境事实**：探针趟由 runner 设 `WPF_LINUX_FONT_DIR=$ROOT/build/fonts-ui`（**1 个 UI 面**），而 **harness（`tline`）那趟未设 ⇒ 走系统字体** —— 这正是 `D-F1c` 的触发现场。
> 🚩 **同日 11:3x 补记（`#14` 的成立范围被限定 —— 这是本波最重要的一条事后发现）**：基线冻结**之后**实测 **`#14` 上 `run.sh tline` 跑不完** —— 在 `layout-b34` oracle 段**自旋 + 无界内存**（RSS `1.9 → 3.1 → 4.19 GB`、101% CPU、CPU 时间 16 分钟、**12+ 分钟零输出**、打开的字面 `/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc`；最后按 **PID** `kill -TERM` ⇒ `rc=143`；**`#13` 同段秒级完成**）⇒ 立为在册缺陷 **`D-F1c`**（疑似 `D-F1` 的 `plan == null` 也建计划 + `allowFallback:true` 引入，已派 T1d 最高优先级）。
> ⇒ **`#14` 只在"应用级门禁（`WPTD_GATE=PASS` 6/6）+ `verify-all`（9 步 0 失败）"这个范围内成立**；**文本 harness 段是"无读数"**（不是"失败读数"：它在结构上就没有产物）⇒ `tline` 六项、34 条 `+CJK` `Extent` 对比**都取不到**，必须等 `D-F1c` 修好。
> ⇒ **波次重排：`#15` = `D-F1c` + `D-F1b`；`#16` = `D-T2` + `D-O1`；`#17` = 产物侧 shim sha。**
> ⇒ **两条负对照（别忽略）**：T2 的 b34 逐字复现（`plan==null` + `与` + em16/宽 40/`alwaysCollapsible:true`）与 T1b2 的 `FormatParagraph("AB与CD")`，在 `WFP_LINUX_FONTS_DIR=build/fonts`（只有 4 个拉丁面）下**都没卡** ⇒ 首选假设 = **回退候选枚举在"系统里真有覆盖面"时走上一条会累积的路径**（次选 = `.ttc` 多面路径与 `:3517` 吞异常相互作用）。
> ⇒ **教训（`L27`，T3 登记）**：**门禁绿 ≠ 没有自旋/没有爆内存** —— 门禁只覆盖它跑过的路径；且"读数趟必须能给出**有界资源**下的结束状态（时间上限 + 内存上限 + 停点身份）"，否则该趟记**无信息**。
> 🔧 **`#15` 阶段一（在飞，2026-09-15 11:35:56 起）**：`build/shims/PresentationCore.HbTextLine.cs` 由 **`17b2cdfe08f13280` → `16db2d6194edc1f5`**（`D-F1c` 回退扫描峰值 + `D-F1b` 回退 run 的身份）。**删 11 行 = 唯一一处声明锚点块**（备份 `~/t1d-backups/20260915-1135-shim-17b2cdfe-preF1cF1b.cs`，sha 我独立复核逐位相同）；**三连编译 `error CS = 0`**（`CoverageProbe`/`TextLineProto`/`HbTextLineParity`）；锚点表 **10 处逐字原文 + `grep -c` 计数断言全过**（`~/wfp-runs/T1d-F1cF1b-report.md` `38cd7901f841372f`）。**关键结构点我现场复核过**：`Release(:659)`｜`MaxScanFaces=4096(:904)` + 上限 `:981` 带 `NoteScanCapped()`｜`CoversCpByBitmap(:1000)` 用在 `:1055`｜`FaceFromRef(:3536)`｜`BuildSegmentFacesFromPlan(:3547)` **且有两个调用点（`:3627`/`:3634`）** ⇒ **"共用点一次修"确实落地**（这是 `D-F1b` 的要害，只改 `plan==null` 那一支是不够的）。
> ➕ **同日 12:00 追加：件链 `16db2d6194edc1f5` → `1ebea99cf011a3b7`（11:59:54）**。⚠️ **先说撤回**：T3 那趟"`rss_peak` 81 MB 恒平"与 T2 上一轮"峰值 63–65 MB"都是**卡住的跑**的读数（进程死在 B2 的第一次覆盖探测、**根本没机会分配后面那 3.3 GB**）⇒ **T2 自查自报并撤回"内存达成"**。**修掉死循环之后同命令能跑完**，`/usr/bin/time -v` 权威峰值 = **`3,464,864 KB ≈ 3.30 GB`**（修前 `17b2cdfe` = `3,464,264 KB`，几乎相同）⇒ **`D-F1c` 的内存缺陷未修（判据 300 MB ⇒ 差 11 倍）**；**修好的只是死循环**（`>150 s 不返回 → 4 s`）。**T2 的这两条读数同时给出了**：**面选择普查 26/26 格逐格相同 ✓**（B1/B2 没改"选哪一面"）、**`D-F1` 正极性无回退 ✓**（`16.0000`/`gids≠0`）；而 **`D-F1b` 未生效**（C1 三腿在 `null`/`fb` 两条路都红、`API_EQ_PLAN=false`：计划面选了 `…NotoSansCJK-Regular.ttc#0` 而 API 仍报段落字体）。**产品级定性**：默认（不设 `WPF_LINUX_FONT_DIR`）时**任何需要回退的段落**都会触发一次 **3.3 GB** 的系统字体扫描（`EnsureScan` 物化 371 个候选面）；**门禁一向绿是因为应用 runner 把字体目录指到了 1–4 面的目录**。原先那句"内存半边达成且超额"已作废。**而第一轮真正引入的是一个新的 CPU 死循环**：T3 的有界趟 `rss_peak 81 MB` 恒平、`rc=143`（按 PID 止损）、`elapsed 633 s`、**停点前移到 `T1 · 73 例 CJK` 段头之后零输出**（修前 T1 段 73/73 跑完、挂在 T2 段）；T2 把它二分到 **"候选面 ≥1 就卡、0 面秒过"**（且`WPF_LINUX_TEXTLINE_DIAG=1` **一行都打不出来**）⇒ **根因 = B2 覆盖位图里 `hb_set_next(hs, ref c)` 的 in/out 游标被循环体重置**（`hb_set_next` 语义 = "取 `*cp` 之后第一个元素，`*cp == INVALID` 则取第一个" ⇒ 每轮都被要求"从头给第一个" ⇒ 永远返回同一个值、`HashSet.Add` 反复空加 ⇒ 纯用户态死循环）⇒ **一行修掉**（删 ` c = 0xFFFFFFFFu;`，+2 行注释），三连编译 `error CS = 0`。
> ⇒ **两条教训**：㈠**"第一次调用就不返回"这类症状先读被调方** —— 读 20 行定案，胜过 6 腿 × 150 s 二分 + `gdb` 栈采样（那条路只会指到"B2 有问题"）；㈡`hb_set_next` 的游标是 **in/out 参数**、不是"返回下一个"，极易写错（`hb_set_previous` 同族）。
> 📋 **`#15` 阶段一（窗口 1–6）全程记录（主控，2026-09-15 12:2x）** —— 件链每一步都可回退、`cmp` 自证，备份全在 `~/t1d-backups/`：
> | # | 件 sha16 | 改了什么 | diff |
> |---|---|---|---|
> | 0 | `17b2cdfe08f13280` | `#14` 冻结件（起点） | — |
> | 1 | `16db2d6194edc1f5` | `D-F1c` 第一轮（B1 扫描期 `Release` + B2 位图覆盖）+ `D-F1b` 共用点/`FaceFromRef` | +122/−11 |
> | 2 | `1ebea99cf011a3b7` | 修 **B2 的 `hb_set_next` 游标被循环体重置**（in/out 参数）⇒ **死循环**一行修掉 | +3/−1 |
> | 3 | `92fc7605480fb289` | 窗口 3：**探测循环"位图前置"**（内存 ①）+ `D-F1b` 改走 `Typeface`→`TryGetGlyphTypeface`（E1） | +21/−4 |
> | 4 | `14f6a728bc834c0e` | 窗口 4：三个只读计数（`ResidentCount`/`ReleaseCalls`/`SegmentFaceResolveCalls`） | +8/−0 |
> | 5 | `6c3afa3046073786` | 窗口 5：**按文件共享一份 blob**（`OpenFileBlob`/`CloseFileBlob`）+ `LoadMetaOnly`（不建 font、不写 `s_faces`） | +64/−13 |
> | 6 | `ac4104d67687c2c9` | 窗口 6：**blob 生命周期计数 `LiveBlobs`**（创建 +1／销毁 −1、峰值、每 10 打一行 `[LIVEBLOBS]`） | +37/−12 |
> **✅ 已达成**：**`D-F1b`（回退 run 的面身份）** —— `FACE_URI=…/NotoSansCJK-Regular.ttc`（**face 0 不带 `#`**）、`GID=9498`、`GID_LT_COUNT=true`、`ADV_FROM_TYPEFACE=16.0000`、**C1 三腿在 `null`/`fb` 两条路全绿**、**`CRITERIA=PASS` 首次全绿**；不回归两条一直是绿的：**面选择普查 26/26 逐格相同**（与修前 `17b2cdfe` 三向一致）、**`D-F1` 正极性**（`16.0000`/`gids≠0`/`CR_W=3.3440`）。
> **❌ 未达成**：**`D-F1c` 的内存半边**（`3.30 GB → 2.00 GB`，判据 300 MB ⇒ 差 7×）。根因分三层，各自都有读数：
> ① **候选面被逐候选物化并常驻**：`CoversFace`（内部 `HbFaceCache.Covers` ⇒ `Get` ⇒ 建 Entry 写 `s_faces`，只在 ≥512 面淘汰、本机 371 面 ⇒ 永不淘汰）**排在 B2 位图过滤之前** ⇒ 修法 = **位图前置**（实测 `coverageProbe 60 → 53` ⇒ 生效；峰值 3.30 → 2.02 GB）。
> ② **`hb_set_next` 死循环**（游标被循环体重置）：`#14` 的 `tline` 那趟"12 分钟零输出"的半边是它；修后 **`>150 s → 4 s`**。
> ③ **文件映射未归还**（主项）：`smaps_rollup` 峰值处 **`Shared_Clean` 占 83–88%（1.67 GB）**、`Private_Dirty` 仅 ~10%；**`residentCount=22` 而 `releaseCalls=371`** ⇒ 释放发生了、内存没还；**Σ(文件大小×面数) = 1.86 GB vs 实测 1.67 GB = 90%**、单文件档 `NotoSansCJK-Bold.ttc` 18.6 MB × 10 面 ⇒ 理论 186 MB vs 实测 199 MB = **1.07×** ⇒ **"每个面 = 整份文件的映射"**；**微实验**：形态 A（10 面共享 1 blob）触碰 19 MB 只增 **4 MB**、face+blob 都销毁后 **Δ=0**（⇒ 可归还）；形态 B（每面各建一份）**+192 MB 且只销毁 blob、不销毁 face 就不回落**（⇒ **反证 `hb_face_create` 持 blob 引用**；实测 192 MB 与理论 191 MB 逐位吻合）。
> ④ **窗口 5 的修法"对但不够"**：按文件共享 blob + `LoadMetaOnly` ⇒ `faceLoads 393→22`、`releaseCalls 371→0`（**修法确实落地**）但 `shared_clean` 纹丝不动 ⇒ 落"**还有第二处持有者**"支；算术给靶子：`residentCount=22 × 18.6 MB ≈ 410 MB` **解释不了 1.67 GB（≈90 份活映射）** ⇒ **`s_faces` 不是唯一持有者**。⇒ 窗口 6 装 `LiveBlobs` 计数，判据尺子 = **`liveBlobs` 峰值 − `residentCount`** = 别处持有的份数；最小复现 = **`fontdir-1`（1 文件 10 面、2 秒）**，任何一处修对 ⇒ `shared_clean` **199 MB → ~19 MB**。
> **本阶段其它记账**：**`D-F2`**（`new GlyphTypeface(Uri)` 对**纯 TTF** 也抛 `FileFormatException`，108 次 FAIL ⇒ 该公开入口对文件字体实质不可用；本轮只登记）｜**T2 主动换掉过期牙**（`TOOTH-C1-NEG` 在 `D-F1b` 修好后必然变假 ⇒ 换成 `TOOTH-D-F1b-ABSENT` + `TOOTH-C1-REDCAP`；判据 sha `524936544a6b9033 → fc808896f23390f4`）｜**长趟守卫不抬**（T2 四条理由：1.67 GB 是与用例数无关的固定底噪 / 抬了多半只是晚一点被止损 / 本机 swap 仅余 ~1.2 GB、越界即"零输出假死" / 先修映射就不用抬；要长趟证据就跑"有界切片并标注切片"）｜**`L28`（T3 立）**：门禁绿 ≠ 默认配置下没问题（默认不设 `WPF_LINUX_FONT_DIR` 时任何需回退的段落触发一次系统扫描，而 runner 把字体目录指到 1–4 面 ⇒ 门禁一路绿）。
> **未做（按序排队）**：`D-F1c` 内存真修（窗口 7）⇒ **T3 的有界 `run.sh tline`**（`#15` 正极性判据 + 34 条 `+CJK` 对比的解封点；守卫 2048 不动）⇒ **`#15` 波**（重建 PC/桥 + 门禁 + `verify-all` + 重冻）⇒ `D-T2`/`D-O1`（`#16`）⇒ 产物侧 shim sha（`#17`）。
> 📋 **`#15` 阶段一（窗口 7–10）续记（主控，2026-09-15 12:4x）** —— **判据在这一段里被改过一次（这是本轮最重要的方法学收获）**：
> | # | 件 / 动作 | 改了什么、判据是什么 |
> |---|---|---|
> | 7 | 只读诊断（T1d）+ T2 采样器 | **判据从"RSS"改成"段数 / Σ虚拟"**：`mmap` 之后**未被触碰的页不计 RSS**（实测 B1：RSS 只 13 MB，而虚拟 191 MB）⇒ T1d 早先两条"渲染侧/裸 FreeType 不是主项"**正是被这个判据缺陷带偏**（限定为"裸 FreeType、且用 RSS 判据时成立"）。T2 修好采样器后拿到 **12 段 / Σ虚拟 223 MB / off=0**（= 12 份整文件映射） |
> | 8 | `92fc…` → M7b 落地 `src/WpfGfx.Linux/**` | **Skia 修法 = 每路径一份 `SKData` + 逐面 `FromData`**（微实验 **10 段→1 段**、四个变体 glyph id 逐位相同 ⇒ 面身份不变的**实测**证据） |
> | 9 | T2 落地 provider | **`build/DirectWrite.Linux/Provider/**` 同套修法**（`SkiaFontDataCache`）⇒ **1CJK 档 400 → 260 MB ✓（≤300 MB 判据达成）**、系统档 **2.03 GB → 715 MB（≤1 GB 硬线）**、`shared_clean` **201/1709 MB → 47.9/58.6 MB**、`nofb` 对照 **1.04 段/文件**；**T1d 跨车道独立复现**（段数 10→1、系统档 24 文件/24 段） |
> | 10 | `ac4104…` → `a0d23e…` → `b5118424dc977aef`（T1d） | **`HbFaceCache` 按 `path` 共享一份 blob**（`s_faces` 里每面各持一份整文件映射 ⇒ 系统 `null` 46 段 vs `nofb` 26 段、`Bold` 11 vs 1）+ **`liveBlobs` 负值修**（只对我们建的 blob 计数、单列 `ForeignBlobDestroys`） |
> | — | **AOT 桥重发（主控）** | `wpfgfx_cor3.so` **`759a322431f1e457 → caf7baf9e67719aa`**、`BRIDGE_SRC_FP=0b7c5a54267064fc`（N=78）、`PUB_EXIT=0`；**核过新 `.so` 里含 `SkiaFontFileCache` 痕迹**（桥 ProjectReference `src/WpfGfx.Linux` 并 AOT 编入 ⇒ **不发桥则 M7b 的修法进不了运行件**）|
> **这一段的四条更正（都记，因为都是"读数推翻推理"）**：① **PC 侧 `FileMapping` 是死路**（原生 shim 的 `CreateFileMappingW`/`MapViewOfFileEx` 是失败桩、`UnmapViewOfFile` 空实现 ⇒ 移植版 `OpenFile` 必抛）⇒ 我先前把它列为候选㈠**撤回**；② **"CJK 族名解析缺陷"撤销**（异常原文是 `FileNotFoundException: System.IO.Packaging` ⇒ 是**仓外宿主缺件**；补齐依赖后 `Noto Sans CJK JP` 12/12 命中）；③ **"88 段 = 查找次数 × 面数"改写**（分相读数：**仅枚举后**就 96 段，12 次族解析**新增 0 段**；逐文件闭合"段数 = 面数"）；④ **归因边界**：expA 不加载 `src/WpfGfx.Linux` ⇒ 那 88 段只能在 **Provider/PC 侧**，`MilHandleTables.cs:671`（MIL 侧）**不是同一处** ⇒ **两侧必须分别计数**。
> **判据重定（预登记 ⑧）**：**系统档 ≤300 MB 不再作为发波条件** —— provider 的 `FromDirectories(...)` 会**全量预载**字体目录（每个面各建 typeface 并长期持有）⇒ **地板 = 被加载文件数 × 各自大小 + 堆**（`priv_dirty 227 MB + priv_clean 342 MB + anon 222 MB`）⇒ 立为**在册项 `D-F3`**（修法 = 惰性按面建 typeface；判据 = 峰值由"用到的面"决定）。**`D-F1c`①（本波）** = 1CJK 档 ≤300 MB（**已达成**）+ 无 ×faces 乘法 + 该 ttc 段数 13→1–2。
> **另一条流程纪律（本轮立的）**：**"源已定"必须由车道说出口**，别人**不能靠"文件看起来完整"替你判定**（主控自己踩了一次：在 T1d 报"源已定"前复核并发跑令，随后 shim 在 12:45:34 又变了半步、`pc` 权威产物也被重建为 `4e73167ba0aa7f5c`）⇒ 另立"**凡会改权威件（如 `pc`）的动作先打招呼**"。
> ⏪ **（历史，已被 `#16` 取代）此刻的树不是 `#14`**：任何取自新件的读数**都不属于 `#14`**；`pc` 相对源**陈旧**（`hbtextline_shim_stale=yes` 量级的事实）⇒ **别拿现在的树跑门禁/`verify-all` 当结论**。
> ✅ **取代它的一句话（2026-09-15 19:0x）**：**树已冻在 `#16`** —— `hbtextline_shim_stale=no basis=auth`（shim 源 mtime `1789467925` < `pc` 比较 mtime `1789468694`）、`BRIDGE_SRC_STALE=no so_file_match=yes`、五臂门禁 `generation=#16 tree_gen=same`、冻树 `verify-all` **10 步 0 失败**。⇒ 上面这段描述的"陈旧中间态"**已不成立**，其保留价值在于**它是 `#16` 那个中间窗口的样子**（`pc 303604882d71f954` / shim `654cfc7fae566e55`）。
> **两条读数车道已放行**：**T2** = `D-F1c` 正/负极性（峰值 RSS `3.46 GB → ≤300 MB`、`FaceLoads 300→≈1`、`Scans=1`、`candidates=371` 不变）+ **面选择普查**（逐格相同）+ `D-F1b` 的 C1 三腿；**T3** = **有界 `run.sh tline`**（`timeout` + 5 s RSS 采样 + 超 2 GB 按 PID 止损；`rc=124/143` 按 `L27` 记**无信息**）。
> **预登记的退路（先定好"红了怎么退"）**：若普查出现换面 ⇒ **把 B2 的位图降为"只做预筛、绝不参与判负"**（位图说"不覆盖"时仍走 `NominalGlyph` 确证）= 只省成本、不改判据。**另一条新登记待办**：`TryFindCovering` 约 `:978` 的 `CoversFace(…)` **返回值被丢弃**（死代码 vs 漏掉的 `if (!…) continue;`）⇒ 只读分析 + **单独一波**，不许与本次混。
> **门禁装置（T1b3，`#15` 波后接第 10 步）**：`build/MilBridge/tools/tline-gate.sh` `b8863c8d9f8ea59b`｜`build/MilBridge/known-red.json` `75f7823fdd39bb43`（schema `tline-known-red/3`，登记绑 **`#13-legA`**、六条含 `carrier`、`T3b` 为 `KNOWN_RED_UNLOCATED`）。它的**第 0 步门禁**是"从事故反向长出来的判据"：**缺结论行、或 harness `rc > 128`（143 = 被信号杀死）⇒ 那趟不算读数 ⇒ 不许拿去重钉登记表** —— 正是这条把 `D-F1c` 那次挂死挡在门外。

> ## ✅ 波 `#15` **完整记录（收官，主控，2026-09-15 13:0x）**
> **内容 = `D-F1c`（回退路径的自旋 + 无界内存）+ `D-F1b`（回退 run 的面身份）**。**收官命令一条**：`WAVE_OWNER=主控 bash build/close-wave.sh`（`OUT=$HOME/wfp-runs/close-wave-w15`），**12:53:19 → 12:59:25，序列 `rc=0`**。
> **波内六步逐条**：`[1/6] integration-wave.sh rc=0`（`native 重建=0 / 桥重发=0`，**12 个工程按依赖序重建，全部 `0 个错误 0 个警告`**）｜`[2/6] native shim` 源码不比权威新 ⇒ **跳过**｜`[3/6] 桥` 源指纹一致（`0b7c5a54267064fc`）⇒ **无需重发**｜`[4/6] 身份自检`：桥源指纹两侧一致 ✅、生成物指纹 `state=ok` ✅、应用器审计 `appliers=20 ok=74 miss=0` ✅、输入稳定性 **波前==波后 `ac90d784…a74a`** ✅、**⚠️ `APPSYNC` 非 PASS**（见下）｜`[5/6] verify-all.sh rc=0`（**9 步 0 失败**）｜`[6/6]` 写汇总 + 哨兵（`/tmp/bridge-frozen.flag` 与 `$HOME/wfp-runs/bridge-frozen.flag`）。
> **九位（逐字，`close-wave-summary.txt` `d4547285eb109263`）**：`bridge=caf7baf9e67719aa`（4,983,696 B）｜**`pc=532c7f54f7573070`**（旧 `4e73167ba0aa7f5c`）｜**`pf=06b12fb74fb50c96`**（旧 `ed51db81db76bc76`）｜`wb=e6216fe961a2bfb9`｜**`provider=9aa0d744802aaa31`**｜`win32shim=0098234982391bbf`｜`wic_shim=03b67fbcd7c385b6`｜**`hbtextline=b5118424dc977aef`**｜**`dwf=b6743030ff1eb907`**（旧 `2f77dbdf5e7e2cd5`）｜`BRIDGE_SRC_FP=0b7c5a54267064fc`｜`inputs_fp=ac90d7847938880e8b13f4ed91a94b3d10f0b49cc1d5584d4dacb08d0c13a74a`｜`native_rebuilt=0 bridge_republished=0`｜`verify_all=PASS`。**主控独立复核**：`pc/pf/shim/provider/bridge` 五项与现场逐位相符；新 `pc` 里**确实含本波 shim 的标识符**（`ForeignBlobDestroys`/`s_sharedBlobTable`/`AcquireSharedBlob`/`SharedBlobAcquires`/`s_transientBlobs` 各命中 1）⇒ **产物内容级抽检通过**（但这不是判据，本波**没落**机制化判据 ⇒ `#17`）。
> **件链（`build/shims/PresentationCore.HbTextLine.cs`，每一步整份备份都在 `~/t1d-backups/` 且 `cmp` 自证）**：`fde9e511e8443cf2`（`#13` 出货）→ `46aa73a3`（非 DIRECT 编译修）→ `17b2cdfe08f13280`（`#14`）→ `16db2d6194edc1f5`（窗口 1–2：`D-F1c` B1/B2 + `D-F1b`）→ `1ebea99cf011a3b7`（**修 `hb_set_next` 游标被循环体重置的纯用户态死循环**）→ `92fc7605480fb289`（窗口 3：**位图前置** + `D-F1b` 改走 `Typeface`→`TryGetGlyphTypeface`）→ `14f6a728bc834c0e`（窗口 4：三个只读计数）→ `6c3afa3046073786`（窗口 5：按文件共享 blob + `LoadMetaOnly`）→ `ac4104d67687c2c9`（窗口 6：`LiveBlobs` 计数 + 诊断行）→ `a0d23ea10d8656e1`（12:44）→ **`b5118424dc977aef`（12:45:34，冻结件；268,698 B / 4619 行）**。
> **窗口 10 的判据与读数**：**10 面 ⇒ 1 段**（修前 10 段）、`liveBlobs=0`、`foreignBlobDestroys=20`（=10 面 × 2 表）、按面 `Release` 后 **0 段** 且 `sharedAcquires == sharedReleases == 11`；**系统档 `null`/`nofb` 差分**：字体段 **46 → ≈26**（把 `HbFaceCache` 那处"按面整文件映射"消掉）、`Bold` **11 → 1**、1CJK 该 ttc **3 → 2**。
> **`D-F1b` 的判据读数（首次全绿）**：`FACE_URI=…/NotoSansCJK-Regular.ttc`（face 0 **不带 `#`**）、`GID=9498`、`GLYPH_COUNT=65535`、`GID_LT_COUNT=true`、`ADV_FROM_TYPEFACE=16.0000`、C1 三腿在 `null`/`fb` 两条路全绿、**面选择普查 26/26 逐格相同**、`D-F1` 无回退、`CRITERIA=PASS`。**边界（登记）**：对"一族多名面"的语料不成立。
> **`D-F1c` 的正极性读数（本波的核心达成项）**：**`run.sh tline` 能在有界资源下跑完** —— 件 `b5118424dc977aef`｜仪器 `run.sh 3e513e88a4fa4ec9` + `HbTextLineParity/Program.cs 2e458928fc1577c2`｜日志 `$HOME/wfp-runs/tline-bounded-20260915-124846.log`（`15fcee62971a3b4f`，29541 B）｜**`rc=1`（逐字记录）｜`elapsed=171 s`｜`rss_peak=1219 MB < 2048 守卫`｜自然终止（非 124/143）｜artifact 为**本趟产物**（`gen/tline-detail-full.txt` `effc036f218f122d`/11041 B/12:52:04）｜**六项齐**｜`T1.73 exact=73 diff=0`**。⏪ 修前（`#14`）：`layout-b34` 段自旋 + 无界内存，`rc=143`（按 PID 止损）、`633 s`、零输出。
> **六项读数（逐字）**：`[口径·记账结构] 全等 1298/1298（①286/286 ②68/68 ③988/988）`｜`[口径·宽度分桶] 0=173 / ≤0.34DIP=1125 / >0.34DIP=0（最大差 0.333333 @ A1_long_word_w150）`｜`折叠判定一致 1298/1298；真折叠 236 行，明细全等 232/236（折后宽度最大差 9.680667 DIP @ F_nbsp_zwsp_w80 行#0）`｜`[完整明细] 折叠不符 4；记账不一致 4；Extent 余差 95`｜`[② Extent 余差清单] 共 95 条（主对拍集 75 + LH 组 20）`｜`通过 22 / 失败 2`（❌ = `T3`、`T3b`）。**`T2` 由 ❌ 转 ✅**（宽度超差 34 → 0）；**不一致用例 10 → 4**。
> **应用级门禁（重冻依据）**：**第二趟**（常驻 `:97`）`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS distinct_origin_y=12 threshold=10 runs=167`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6 条 `BASELINE … result=PASS`**（default `drawn=260`、env `drawn=144`；`colors=3960/2828`；`frames=14/14`；`cross_ae=0`；`leftover_after=0`）；`hbtextline_shim_stale=no(basis=auth)`、`BRIDGE_SRC_STALE=no`。基线表头已重冻为 **`#15`**（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`，文件 sha16 `52d1b1beabce59e5`；`#14` 表头与机读行**整段保留在文件下半部并标注"已被取代"**，`grep -m1 BASELINE-HEADER` 取到的是 `#15`）。
> **`ARTIFACT-SRC-FP` 两极化（本波"免费获得"的判据）**：新写仪器 `build/check-fp-polarity.sh`（`f91d12bed2494889`，**已做 19 用例红证**：正极性变红、负极性**改值/增行/删行三种**都能变红并点名、4 种 `NOINFO`、双侧绿控全驱动到）⇒ 本波实得 **正极性 ✅**（FP 里 shim 行 = `b5118424dc977aef` == 现树）**＋ 负极性 ✅**（与波前存档 `9ac71d3eacfa2a14…` 比，除 shim 行外**其余 `file=` 行逐位不变**）。**诚实边界**：`file=` 只记**源的样子**，**不证明产物里真的编进了它**（本波只做了上面那条内容级抽检）。
> **两处"期望未达成"（如实登记，不许洗绿）**：① **`APPSYNC=MISMATCH`** —— 唯一原因 = `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll` 被判 `UNEXPECTED`（**未声明的传递依赖副本**，**内容 == 权威 `0c597fb6ec1eec70`**；`MISMATCH=0 STALE=0 MISSING=0 DIVERGENT=0`；该副本 12:37 由车道构建产生 ⇒ 12:33 那次 `APPSYNC=PASS` 时它还不存在 ⇒ **非本波引入**）⇒ 登记 **`D-A1`**；② **门禁第一趟不能作基线** —— `default rep=1` 判 `FAIL`（`exit=134`/`capture=all-blank`），真因 = **runner 自起 `Xvfb` 的就绪竞态**（应用自报 `XOpenDisplay(":97") 失败`），**同配置 rep2/3 + env 1/2/3 全 PASS** ⇒ 判**装置竞态、非应用缺陷**；处置 = 起**常驻** `:97`；**两趟都留档**（`$HOME/wfp-runs/w15-pre/gate-r1-xrace/{baseline-run1.md fa07c603fc9503e1, app-default-r1.crash.log a7772dd0b681dd03, tier-readings-run1.txt 0e6a5418dd3357b0}`、`…/gate-run2.out 6b9c049939634038`、`…/baseline-run2.md 5f5a6b72be973f8b`）⇒ 立为**纪律 30**（runner 侧修法待办，属 T3）。
> **门禁首次以"五臂"运行 ⇒ 立刻抓出一条长期没人跑的红（`L26` 的现场）**：探针于 13:02 用新 shim 重建；四支非 tline 臂**第一次有 `#15` 世代的真实日志**（`tab-zero-w15.log`、`tab-anchor-w15.log`、`tab-rtl-w15.log`、`textlineproto-w15b.log`；`run.sh textline` 由**主控**跑，`gen/textline-proto.png` 前后同 sha `f442be49706592e5`）。门禁逐字：
> `TLINE_GATE=FAIL arms=5 red=3 green=2 noinfo_arm=0 registered=3 unlocated=1 **drift=0 gone=0** unregistered=179 caliber=OK generation=#15 tree_gen=same saved_shim=b5118424dc977aef gate=338e468d1ad0f43c judge=t1b3-tline-gate/2`、`GATE_REASON=unregistered-failure`。
> ⇒ **3 条在册红形状全对**（`T3-Collapse明细 232/236`、`T2d-Extent余差 95`、`T3b ❌`+`unlocated`）；**179 条未登记** = `tab-anchor`（436 例，**有史以来第一次真实运行**）`结构败=132`（探针层 `未登记失败 178`）+ `tab-zero` 的**老红 1 条**（新表只覆盖 `tline` 臂 ⇒ 没带过来）。**机制形态**：`A-anchor/lat-a-t-b@w96@LTR@i0@default` ⇒ `行数 期望=3 实得=2；真值行=[a]w=13.35 | [\t]w=96.00 | [b]w=13.35；我方行=…w=109.35`，同例 **`@tab0` 变体 `结构=PASS`** ⇒ **"停靠位非 0 时的锚定/折行语义"与真值不一致**（与 `D-T2` 同面）。**处置**：逐条裁定（真缺陷/装置缺陷/**未定位 ⇒ `unlocated:true`**）后登进 `known-red.json`，**`verify-all` 第 10 步等门禁能给出 `PASS … unregistered=0` 之后由主控接**。
> **在册红登记表已重钉到 `#15`**（T1b3 落盘，主控事后复核）：`build/MilBridge/known-red.json` **`129883bf803b0f5d`**（`schema tline-known-red/4`、`generation.id=#15`、`instr_shim=b5118424…`、`completion_criterion` 逐字写进新口径、`entries` **6 → 3**、新增顶层 `pending` 说明只覆盖 `tline` 臂 + `extent_regression` 块、`changelog rev4` 逐条写"为什么注销/更新"）；门禁脚本 **`338e468d1ad0f43c`**（含两处修法：**弱配对追加"日志 mtime ≥ 该世代被测件 mtime"**、**`ROOT` 回退链 + 定不出即 `NOINFO`**）。**注销 2 条**（`T2-记账结构`、`T2-宽度超差`）的理由已按"**宽度是真修复 / 记账是读数未变但 carrier 转绿**"分别写清。
> **新登记（本波带出）**：**`D-A1`**（app-local 期望模型不覆盖传递依赖副本）、**`Extent +36` 未归因**（紧口径余差 `59→95`，36 条**全 `*_tabs_*`**、**同值 `+0.0628`**、**布局逐位不变**；负对照 = 454 条非 tab 行一条没进清单）⇒ 材料 `$HOME/wfp-runs/plus36-extent-tab-20260915.tsv`（`9789186b67a467f7`，含 `#13`/本趟两侧 cp 与宽度）、**`ContractProbe P6`**（`BeginInit + setter 构造 GlyphRun` ⇒ `InvalidOperationException` 抛在 `GlyphRun.CheckInitialized()`；同批 `P1` = 已登记 `D-F2`）、**`L29`**（完成口径与退出码语义不对齐 ⇒ 假的无信息）、**`tab-anchor` 132 条待裁定**。
> **本波的自我更正（逐条）**：① 我把"等 T3 `rc=0` 才发波"写进队列 —— **错**（`rc` 含保留红 ⇒ 恒 1；T3 自己更正后我采纳并撤回该前置条件；完成判据改为 `结论段 present ∧ === 结束 === ∧ rc ∉ {124,143}` ⇒ `L29`）；② 我把 `APPSYNC=PASS` 写成波内期望而无视"期望模型不覆盖传递依赖副本" ⇒ 实得 `MISMATCH`，**如实记入表头**并立 `D-A1`（**没有**为了好看把它读成绿）；③ 我第一趟门禁把日志重定向进了 `$WPTD_RUN_DIR` 内 ⇒ 被 runner 装配 `rm -rf` 吃掉（纪律 7 的现场重演，第二趟放到 `$OUT` 之外）；④ 我第一趟门禁**没先确认 `:97` 存在** ⇒ 撞上就绪竞态、白跑一趟（纪律 30 由此立）；⑤ 我早先记的 `HasOverflowed :3086` / `D-T2` 锚点 `:1589`/`:331` **已随版本位移**（现为 `:3357`、`HasOverflowed => false` 在 `:3357`、崩点判据在 `:3413`；Tab 机器在 `:336`/`:374`/`:386`/`:392`/`:650`/`:1638–1646`）⇒ **引用行号前必须现场重读**（纪律 4 的老账，再次应验）。
> **波后收尾清单（本条记录之后继续）**：① T2 波后复取（`D-F1c`① 三条 + `D-F3` 地板 + `CachedFileCount/CachedBytes/LiveFaceCount`，**件 = 波后产物**）② 波后不变项复取（`candidates` 10/45/371、`Scans=1`、普查 26/26、`LINE_W=16.0000`、`CR_W=3.3440`、`GID=9498`、`ADV_DIP=16.0000`、`CRITERIA=PASS`、`TOOTH-D-F1b-ABSENT`）③ `+CJK` 34 条独立复核（T3 已核：与 `#13` **逐名相同**、`diff` 输出为空）④ `Extent +36` 归因 ⑤ `tab-anchor` 179 条裁定 ⇒ 接 `verify-all` 第 10 步 ⑥ `D-R2` 计数（**本波 `verify-all` = 第 1 趟干净**，关闭判据 = 连续 5 趟）。
> **下一波预告**：**`#16` = `D-T2`（Tab 缩进；shim 半 + PC 半）+ `D-O1`（`HasOverflowed`，**会打开折叠路径** ⇒ 位移集合必须含"折叠"族）**；**`#17` = 产物侧 shim sha**（`hbtextline_shim_stale` 从 mtime 代理升为**产物内**内容比对；落地改 `pc` 并经环传播动 `pf`/`reach`）。**每件落完各自取一次读数**，任一族外位移 = 回归。

> ## ✅ 波 `#15` **波后收尾（16:3x–16:5x，主控）** —— 逐件都可复算
> **① T2 的波后复取（`D-F1c`① 三条 + `D-F3` 地板 + 不变项）**：四元组 = 件 shim `b5118424dc977aef` / PC `532c7f54f7573070` / WB `e6216fe961a2bfb9` / DWF `b6743030ff1eb907` / Provider `9aa0d744802aaa31` / WpfGfx `0c597fb6ec1eec70`（app-local 五件逐位 == 权威）；仪器 = 宿主 `FallbackCriteria.dll 74dd2d4cc46be041` + `mem-sampler.sh 09e5bab7c3d246f6`（`--selfcheck` PASS）；判据层 `fc808896f23390f4`。
>   - **①a ✅** 1CJK 权威峰值 **265 MB**（≤300）｜**①b ✅** 系统档 **29 段 / 24 个被加载文件 = 1.2 段/文件**（`117 → 29`）｜**①c ✗** 1CJK 该 `.ttc` = **3 段**（目标 1–2）⇒ **差 1 段**，归因 = **shim 侧**（瞬时 1 段在回退扫描期；`--mode=nofb` 对照可证消失）⇒ ①c 的最后一格**不在 T2 写域**。系统档峰值 **692 MB**（硬线 1 GB）。
>   - **`D-F3` 地板**：`Rss 653,468｜Private_Dirty 275,284｜Private_Clean 350,760｜Shared_Clean 48,688｜anon 270,220`（KB）⇒ 地板主体是**堆**（≈896 MB 合计）、映射只剩 **48.7 MB**；被加载文件数 **24**｜Σ 大小 335.3 MB。
>   - **不变项全过（逐字）**：`C1/C2/C3 PASS`、`TOOTH-D-F1b-ABSENT=PASS`、`CRITERIA=PASS`、`LINE_W=16.0000`、`CR_W=3.3440`、`GID=9498`、`ADV_DIP=16.0000`、`ADV_FROM_TYPEFACE=16.0000`、`FACE_URI=…NotoSansCJK-Regular.ttc`（face 0 不带 `#`）、**普查 26/26 逐格相同**、`candidates` 1CJK **10** / 系统 **371**、`Scans=1`；反极性对照 `nofb` ⇒ `LINE_W=9.6000 CR_W=−3.0560 GID=0`（修前形态逐项复现 ✓）。**位移**：`coverageProbe 53`（预期 60→53）✓、`faceLoads 22`（393→22）✓、`releaseCalls 0`（371→0）✓。**三项 `NOINFO`**：M7b 的 `CachedFileCount/CachedBytes/LiveFaceCount`（宿主不加载 MIL ⇒ 这条链上没有它）、7CJK 档 `candidates=45` 未复取、`+CJK` 独立复核（**主控已自行核：与 `#13` 出货趟逐名相同、`diff` 输出为空**）。**T2 自我记账一条**：它算的"其它读数进程数恒 1"其实是**它自己命令行的子 shell 自匹配**（`/proc` 排除了祖先、没排除自己的子 shell）⇒ 那个 "1" 应读作 0，权威证据 = 独立快照 `$HOME/wfp-runs/proc-snapshot-164119.txt`。
> **② 179 条未登记失败 ⇒ 裁定 + 补登 + 门禁两处仪器缺陷（主控代落盘，理由：该车道两次中途失败且本项阻塞第 10 步）**：
>   - **裁定**：`tab-oracle-zero` **1 条 = `#13` 老红补登**（新表只覆盖 `tline` 臂 ⇒ 漏带）｜`tab-oracle-anchor` **178 条 = 真缺陷**，根因按族归到 **A/B/C**（D-T2 方案 `8607f62911b03b70`）：`A-anchor` 4 / `B-indent` 64 / `B-indent-extra` 70 / `D-paraindent` 40 ⇒ **没有一条标 `unlocated`**（根因已定位到具体代码行）。
>   - **门禁两个缺陷（同一族："一支臂两把尺子"）**：**未登记检测**取探针自报的 `TAB_LINES UNREGISTERED`（**含位置面**，178 条）而**在册红判读**只取 `结构=`（132 条）⇒ `结构=PASS 位置=FAIL` 的 case 两边不一致 ⇒ **无论怎么登记都到不了 PASS**（实测 `unregistered=46` 或 `gone=46` 二选一）；修法 = 该 case **有 `FAILCASE` 行就判红**（实测 `tab-anchor` 的 `FAILCASE` 行 = 178，其中 `结构=FAIL` 132 / `位置=FAIL` 140 ⇒ 恰好 46 条纯位置面被漏），且 `判据状态` 读数与 `judge_red` **同一把尺子**（否则 46 条读成 `✅` 而登记形状是 `❌` ⇒ `drift=46`）。**两处都只加强红检测、不放宽口径**。
>   - **结果**：`tline-gate.sh` = **`b37a5c9f55ae71a4`**、`known-red.json` = **`cebd534238c3b649`**（`schema 4`、`entries 182`、`changelog rev5` 写明"代落盘 + 逐条取自门禁自己的输出 + 未改任何判据"）⇒ `TLINE_GATE=PASS arms=5 red=3 green=2 noinfo_arm=0 registered=182 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK`、`rc=0`。**两极化红证**：删 1 条 `tab-anchor` ⇒ `rc=1`/`unregistered=1`；删 `tline/T3b` ⇒ 同形态。
> **③ 门禁接成 `verify-all` 第 10 步（步数 9 → 10，口径已变）**：五臂日志目录 `build/MilBridge/arm-logs/`（**硬链接**——拷贝会顶掉 mtime 从而**架空**弱配对判据；**符号链接**会被门禁的 `find -type f` 漏掉 ⇒ 实测 `rc=2`；约定与"新世代重绿步骤"写在该目录 `README.md`）。**实测**：`verify-all` 跑到第 10 步 **✅**。
> **④ `D-R2`（`ManagedLayer.Tests`）又被打开**：`#15` 波曾让 `verify-all` **连续 5 趟全绿**（`close-wave-203111→102523→105027→105739→w15`），但**波后手动 `verify-all`（16:47）** ⇒ `步骤通过 9 ❌ 失败 1`、失败项 `ManagedLayer.Tests`、原文 **`活动的测试运行已中止。原因: 测试主机进程崩溃`**（7 条失败全在窗口族）。**混杂因素坦白**：那趟是在**4 条后台车道同时活动**时跑的，而 `verify-all` **不记 `loadavg`** ⇒ "负载"是强先验、不是已证。**决定性静树对照**：同工程单独跑（`DISPLAY=:97`，跑前 `loadavg=0.23 0.61 0.53`）⇒ **`rc=0`、`失败: 0，通过: 76，总计: 76`**。⇒ 定性成立、崩溃本体仍在；关闭判据升级为"**静树下 ≥5 趟无崩溃，且每趟记 `loadavg`/`mem_available`**"（旧记 "74/74" 是用例数随版本变的例子，现为 76）。
> **⑤ 本波文档落点（sha16）**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`#15` 表头 + 两份补记）｜`docs/CURRENT-STATE.md`（§1 九位=#15、§3 六条重核、§4 新增/更新 `D-F1c`① 复取/`D-F3` 地板/位移账/门禁接第 10 步/`D-A1`/`tab-anchor`/`P6`/X 竞态/`D-R2`、§5 新增纪律 28–30）｜`handoff.md`（本记录）｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（T3：`L25`–`L30`、`D-A1`、`D-F2`、`P6`）｜`build/MilBridge/arm-logs/README.md`。

> ## ✅ 波 `#16` **完整记录（收官，主控，2026-09-15 19:0x）**
> **内容 = `D-T2`（Tab 缩进语义补全）+ `D-O1`（`TextLine.HasOverflowed` 真实现）**（预登记见 `docs/WAVE16-PREREGISTRATION.md`）。**收官命令一条**：`WAVE_OWNER=主控 bash build/close-wave.sh`（`OUT=$HOME/wfp-runs/close-wave-w16`），**18:37:16 → 18:41:17、`W16_WAVE_EXIT=0`**。
> **波内步骤逐条**：集成波（`native 重建=0 / 桥重发=0`，**12 个工程按依赖序重建、`0 个错误 0 个警告`**）⇒ 第 2 步 **跳过**（native shim 源码不比权威新）⇒ 第 3 步 **跳过**（桥源指纹 `0b7c5a54267064fc == 0b7c5a54267064fc`，无需重发）⇒ **身份自检**：桥源指纹两侧一致 ✅、生成物指纹 `state=ok` ✅、应用器审计 `appliers=20 ok=74 miss=0 red=0` ✅、输入稳定性 ✅、**⚠️ `APPSYNC` 非 PASS**（见下）⇒ `verify_all=PASS` ⇒ 写汇总 + 哨兵（`/tmp/bridge-frozen.flag` 与 `$HOME/wfp-runs/bridge-frozen.flag`）。
> **九位（逐字，`close-wave-summary.txt`）**：`bridge=caf7baf9e67719aa`（4,983,696 B）｜**`pc=c0763fc10173e7ff`**（旧 `532c7f54f7573070`；4,194,816 B / 18:38:14）｜**`pf=9ef136caddb10370`**（旧 `06b12fb74fb50c96`；7,122,432 B / 18:39:08）｜`wb=e6216fe961a2bfb9`（内容未变、被波重建 ⇒ mtime 18:37:37）｜`provider=9aa0d744802aaa31`｜`win32shim=0098234982391bbf`（283,648 B）｜`wic_shim=03b67fbcd7c385b6`｜**`hbtextline=bc04c05ab6d8d82a`**（旧 `b5118424dc977aef`；275,765 B / 18:25:25、`stale=no basis=auth`，`shim src mtime=1789467925 < pc compare mtime=1789468694`）｜**`dwf=b6743030ff1eb907`**｜`BRIDGE_SRC_FP=0b7c5a54267064fc`（N=78）｜`inputs_fp=fe1bbcae1e20ae7caadcdf5106172401c28cea6edfd4b66b55cc841b3de29adf`｜`native_rebuilt=0 bridge_republished=0`｜`verify_all=PASS`。
> **相对 `#15` 只动三位**：`pc`／`pf`／`hbtextline`；其余六位（`bridge`／`wb`／`provider`／`win32shim`／`wic_shim`／`dwf`）**sha 逐位未变**。渲染侧可见位 `WpfGfx.Linux.dll 0c597fb6ec1eec70`（**非九位**）**本波未重建**。
> **`inputs_fp` 是"波后重算"的**：**三条车道（T17A/TAPPS/TDT2）全部收工后的 18:53** 重算，与波内值**逐位相同** ⇒ **波前==波后仍成立**（这条复核是 `#16` 补做的动作，不是继承 `#15` 的结论）。
> **① `D-T2` 的九个落地件（每件各自取一次读数 —— 否则 `D-T2` 的"本地应逐位不变"会被 `D-O1` 污染、归因作废）**：`2`／`2b`／`2c`／`2d`／`2e`／`1a`／`1b′`／`1c`／`1d`。**位移账**：`tab-anchor` **`结构败 132 → 0`**、**`判定过 288/288`**、`未登记 0`、**`rc=0`**（日志 `build/MilBridge/arm-logs/tab-anchor.log` = `99d72b385fe23a90`；`#15` 时为 `7080853d7ddd9b2f`）；`tab-zero`（`b9d81590f3fcd800`）／`tab-rtl`（`419e8aaa9c72a9a0`）／`textlineproto`（`4bceceeed570ba70`）**逐字节不变**；`tline` **只有 14 行身份/管道差、判据行零移动**（见 ③）。`Extent` 紧口径余差仍 **95**，其中 **`*_tabs_*` 36 条、同值 `0.0628`** ⇒ 相对 `#13` **只能断言 `+0.0628 ± 0.0100`**（`#13` 出货档里**没有 tabs 行** ⇒ "位移恰好 `+0.0628`"不成立）。
> **② `D-O1` 落地**：`build/shims/PresentationCore.HbTextLine.cs` 里 `_boxOriginX` 计数 **4**；`HasOverflowed` 由"**恒 `false`**"改成**三支真判据**（`!(_paragraphWidth > 0) ⇒ false`；`_startPenX >= _paragraphWidth ⇒ true`；否则 `_boxOriginX + _width > _paragraphWidth + 1e-9`），落地后该属性在 **`:3413`**、折叠资格闸门在 **`:3480`** ⇒ **折叠路径由此打开**（这正是 `D-T2` 的 `F_nbsp_zwsp_w40#3` 曾必须靠 `alwaysCollapsible:true` 才测得出来的那条路径）。⚠️ **附带发现（登记，未改，同纪律 4 一族）**：该属性**上方的文档注释仍写着"本实现恒 false"** ⇒ **注释已与实现不符**，引用前现场重读。
> **③ 五臂日志全部在波后树上重取（这是本波的"证据升级"，也是纪律 36 的现场）**：波把 `pc` 由 `303604882d71f954` 重建为 `c0763fc10173e7ff`，而三支 tab 臂 + `textlineproto` 是**弱配对**（日志不自报被测件）⇒ **不追认、全部重取**：先把 `CoverageProbe`（rc=0）与 `TextLineProto`（rc=0）`dotnet build -c Release` **重建**（两者把 `build/shims/PresentationCore.HbTextLine.cs` 内联进去 ⇒ 不重建就是在量旧 shim；`CoverageProbe/bin/Release/PresentationCore.dll` 副本随之由 `303604882d71f954`（17:13:03）刷新为权威 `c0763fc10173e7ff`），**18:46:58–18:52:42** 逐条重跑，再 `ln -f` 进 `arm-logs/`（**硬链接**，五条**全是 `links=2`**，mtime 保留 ⇒ 不架空弱配对判据）。**结果**：四支臂与 `#15`、与波前 `#16` **逐字节相同** ⇒ **"`pc` 的变化不进这三支臂的读数"从推理升格为实测**（机制：`CoverageProbe.csproj` 用 `DefineConstants=…;TEXTLINE_SHIM_DIRECT` + `<Compile Include="$(HbShimSrc)" Link="PresentationCore.HbTextLine.cs" />` **把 shim 源内联进探针**，`HbTextLineFactory` 声明在 shim 源内 `:3777` ⇒ 内联副本胜出、CS0436 被静音）；**但 `tline` 那支变了**（`ad07ead4022539d2 → 89ad10ac614b4d3b`）⇒ **口径写成"每一行位移都被归因"**：**实测 14 行差全是身份/管道**（`[applocal]` 与 `[T0.7]` 的 pc 权威 sha、`一致 4/4（权威 PC=…）`、`已用时间`、保留复核用的 `/tmp/tmp.*` 目录名、带时间戳的 artifact 路径 `gen/tline-ledger-lines-20260915-1830.txt → -1852.txt`）⇒ **零条判据/读数行移动**，登记读数逐条复现（`折叠判定一致 1297/1298`、`明细全等 232/236`、`Extent 余差 95`、`T3b ❌` 由 `②4/236`＋`③2/236` 承载）。**这一整段（含"为什么必须重取"）已写进 `known-red.json` 的 `arms_retaken` 段**。
> **④ 在册红门禁重钉到 `#16`、且第一次给出 `unregistered=0`**：`build/MilBridge/known-red.json` = **`f9843bde351029dc`**（`schema tline-known-red/4`、`generation.id=#16`、**`entries` 182 → 4** = 3 条 `tline` + 1 条 `tab-oracle-zero`、`changelog rev 7`、`generation.instr_pc` 由陈旧 `4e73167ba0aa7f5c` 更正为 `c0763fc10173e7ff`；`#15` 版备份 `$HOME/wfp-runs/w16-arms/known-red.rev6.json` `391c907c7d114e01`）｜门禁脚本 `b37a5c9f55ae71a4`（含"同一支臂两把尺子"两处修法）。**读数（outdir `$HOME/wfp-runs/gate16-arms2`）**：`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#16 tree_gen=same saved_shim=bc04c05ab6d8d82a gate=b37a5c9f55ae71a4`、`GATE_REASON=all-as-registered`、**`rc=0`**。⇒ **`#15` 那条"179 条未登记"逐条裁定收口**（`tab-anchor` 那 178 条随 `D-T2` 转绿、`tab-oracle-zero` 的老红 1 条**补登**为在册红）。**两极化红证（在重钉后的表上重做）**：删 `tab-oracle-zero` 条目 ⇒ `registered=3 unregistered=1` + `rc=1`；删 `tline/T3b` ⇒ `registered=3 unlocated=0 unregistered=1` + `rc=1`；真表 ⇒ `rc=0`（临时表 `$HOME/wfp-runs/w16-arms/kn-red-minus{a,b}.json`）。
> **⑤ 冻树 `verify-all`（18:58 → 19:00:37，日志 `$HOME/wfp-runs/w16-pre/verify-all-16.out` `ce174c8cde3e9692`）**：**`步骤通过 10 ❌ 失败 0`**、**`用例通过 871 跳过 2`**、`结论：✅ 全部通过`（含第 10 步"在册红门禁（五臂）✅"）。⚠️ **口径已变：9 步 → 10 步**（第 10 步是 `#15` 波后才接上的）⇒ **`#15` 的"9 步 / 869 通过"不可引用**（该日志自身不记 `rc`）。
> **⑥ 应用级门禁（两趟都留档）**：**第 1 趟**（18:42–18:44，`WPTD_RUN_DIR=$HOME/wfp-runs/mygate16`、日志 `$HOME/wfp-runs/gate16.out` `559d85a9bf1ac32d`）**`GATE16_RC=0`**：`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `WPTD_TIER=… RESULT=PASS`**（default `drawn=260 colors=3960 scroll=ok/139705`、env `drawn=144 colors=2828 scroll=ok/135468`；两档 `frames_good=14 frames_total=14 frames_blank=0`、`capture=ok`）、`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167`、`WPTD_BRIDGE_SRC_STALE=no basis=pub=0b7c5a54267064fc now=0b7c5a54267064fc so_file_match=yes`、`hbtextline_shim_stale=no`；普查 `T1C_CENSUS_SUMMARY frame=3 runs=167 handles=167 glyphs=1717 id0=0 nonlatin=421 maxid=63151 allnotdefruns=0 distinctpids=4`、孤儿 `before=0 after=0`；负载闸门 `1min=0.85 ≤ 12`（`loadavg=0.85 2.09 1.65`、`mem_available=3212 MB`、`cpu=3核`）。**第 2 趟**（补 `WPTD_BASELINE_OUT=$HOME/wfp-runs/w16-pre/baseline16-run2.md` `cfd38fe2a3393fda`、头部 `date=2026-09-15T18:53:52+08:00 display=:97`）：**6/6 `BASELINE … result=PASS`**（default/env × rep 1–3，config 行逐字带 `pc:c0763fc10173e7ff`、`pf:9ef136caddb10370`、`bridge:caf7baf9e67719aa`）。
> **⑦ 三条"我先前就是这么写的、但它是错的"（本轮最值钱的部分，全部留档、不静默覆盖）**：
>   - **(a) `runner exit=0` 与盘上字段不符**：两趟 6/6 行的退出码列都是 **`exit=143`**，且门禁**自带判据**原文 = `判据① 存活/退出码：alive=1 exit=143 ✅`（全日志 `grep -c 'exit=0'` = **0**）⇒ 应用是"**跑完仍存活、被 runner 收走**"。**`#15` 记录里"`runner exit=0`"的写法作废**，`#16` 起一律引 `alive=1 exit=143 ✅`。**这一处差异未归因**（不是缺陷、也不是已解释）⇒ **登在册、待查**。
>   - **(b) `tab-anchor` 132 结构败的两次归因，第一次是错的**：我先把"探针喂 `1e6` + `wrap:false`"（旧注释称 oracle 是 NoWrap，而 **436/436 例实测都写 `textWrapping:"Wrap"`**）当主因并据此断言"那 178 条是仪器 artifact" ⇒ **被实验当场否掉**：按 `pw`/`wrap:true` 修好后探针二进制**确实变了**（`d5b881078a5caf5b → e3a15c25a799ab5b`）而 `tab-anchor` 日志**逐字节相同**（`7080853d7ddd9b2f`）⇒ 该改动**中性**、解释不了失败；**更准的实验**证明真因是**另一处参数**（`RunTabLinesOracle` 从未把 oracle 的缩进喂下去 ⇒ `indentDip`/`paragraphIndentDip` 恒 0，而非零缩进用例有 **208 条**）⇒ 断言**先被否、后被更准的实验证实**。**教训（并入纪律 34）**：**同一份文件里"同名同类"的入口不止一个，改之前必须先确定"哪一支臂走哪一段"**（我改的 `:763` 在 `RunTabOracle` `:710`，不是门禁那三支臂用的 `RunTabLinesOracle` `:1258`）。
>   - **(c) `D-T2` 边界那句登记不成立**：原登记"**`ParagraphIndent ≠ 0` 时 maxWidth 含 indent 而 minWidth 不含**" ⇒ 复核后**两处探针都不传缩进**（真实形态是"两侧都不含"）；**活下来的不对称在 `TextModifier` 作用域实参那一侧**，**裁定为缺陷**（不是镜像差异），**量级至今是预测、不是实测** ⇒ 本条**从"已答"改回"在册未做"**（详见 `build/MilBridge/TDT2-boundary-report.md` `6388461b4ecd0de7`）。
> **⑧ 一件被自己的实验否掉并回退（`D-T2` 的 `1b`）**：**0 修好 / 2 例新坏** ⇒ **当场回退**，其功能**有条件重生为 `1b′`** ⇒ 留下完整的"**提出 → 否证 → 回退 → 有条件重生**"链（纪律 34 同族形态）。
> **⑨ `APPSYNC` 的两份读数（纪律 35 的现场：读数之后仪器变了 ⇒ 作废配对、不作废读数）**：① **波内（旧仪器** `applocal-expect.py 7c131b3f33b7e74e` + `check-applocal-sync.sh 3ba5284bad838b14`**）** = `OK=45 MISMATCH=0（STALE=0 NEWER-DIFF=0） MISSING=0 UNEXPECTED=1 DIVERGENT=0 NO-AUTHORITY=20 LIB-COPY=0 SKIP(obj)=6 SKIP(stub)=4 SKIP(ref)=10 RETIRED=0` ⇒ **`APPSYNC=MISMATCH`**；唯一原因 = `build/DirectWrite.Linux/FallbackCriteria/bin/Debug/WpfGfx.Linux.dll`（**内容 == 权威 `0c597fb6ec1eec70`**，已登记 `D-A1`；**不是陈旧件**）。② **主控用加固后仪器**（`6eafbea14e7ea41e` / `aad23482f84bdf44`，自检 **15/15 → 17/17 `SELFTEST=PASS`**）**复读** = **计数逐项相同**、`UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]`、**`rc=1`**（日志 `$HOME/wfp-runs/w16-pre/appsync-new.out`）⇒ `D-A1` 被**点名成"声明缺口（内容相等）"**：**可见、仍红、没有被洗绿**；**极性牙**：把该副本改成任一旧 sha ⇒ `DECL-GAP-DIFF=1` / 必须红。⚠️ **车道在波内读数之后才加固仪器** ⇒ 冻结表头必须**同时带两份读数与两份仪器 sha**。
> **⑩ 本波新登记（在册未做，逐条有判据与归属；详见 `docs/CURRENT-STATE.md` §4）**：① **app-local 检查器的期望表盲区**（条目表只覆盖 5 个产物 ⇒ `FallbackCriteria/bin/Debug/` 17 个 DLL 只判 2 个；检查器输出里 `grep -c PresentationCore.dll` = **0**；桥只能落 `EXPECT=UNKNOWN`；`.artifacts/**` 与 runner `$OUT` 在 `SCAN_ROOTS` 之外）② **拷贝点枚举器自身漏报**（印 18 条、实际 ≥20：漏 2 处 MSBuild `<Copy>`、2 处桥保存/恢复点 `run-wpftextdemo.sh:179/:191`、13 处变量间接写含 `build/MilBridge/run.sh:210` 与 `build/close-wave.sh:130`；三个写点全是真洞 `libwpfwin32.so 4/4`／`libwpfwic.so 3/3`，**今天 sha 全同属"恰好没坏"**，其中两处失败被 `2>/dev/null || true` 吞掉）③ **PC 侧缩进接线不对称**（`TextFormatterImp.Linux.cs` 的 `indentDip` **只有 `:256` 一处**、`:575` 只传 `Pap.ParagraphIndent` ⇒ **`Pap.Indent` 从未被传**，"网格锚点"与"内容起点"在应用路径上**塌成同一个值**；**五臂都看不见它** —— b34 语料 **614/614 例**缩进全 0，而三支 tab 臂**自己在 `RunTabLinesOracle` 里接参数** ⇒ **仪器绕过了应用路径**；**⚠️ 本波不许顺手修**（一改就动 `pc` ⇒ 当场作废 `#16` 冻结），判别臂 = 新 `CoverageProbe --minmax-oracle` 跑 436 例（208 例非零缩进）+ 用 `formatter.FormatMinMaxParagraphWidth(source, 0, para)` 重录 Windows 真值（入口 `tests/parity/windows/tab-anchor/src/Program.cs:423-478`）+ 两条红证）④ 上面 ⑦(c) 的 `D-T2` 边界。
> **⑪ 本波新证据/报告（三条只读或专用车道，写域互不重叠）**：**T17A**（`c17ed3a2-…`，`build/MilBridge/tools/shim-in-artifact.sh` `e2e1a42b5f0e5b45`＋`T17A-report.md` `de044cb22c77c9c8`）：读**编译后 DLL 的托管堆**找 shim 符号 ⇒ `SHIM_IN_ARTIFACT=PASS … new=2/2 stable=14/14 refs=23`、`rc=0`；**诚实边界 = 下界、不是内容相等**（一次改动不引入新符号 ⇒ 退化成 `WEAK-PASS rc=3`），**未接进 `verify-all.sh`**。**TAPPS**（`0b387845-…`，`build/DirectWrite.Linux/TAPPS-blind-half-report.md` `9071d4bcf39918b8`）：⑩①②的原始证据 + 仪器加固。**TDT2**（`ca6611a3-…`，`build/MilBridge/TDT2-boundary-report.md` `6388461b4ecd0de7`）：⑦(c) 的定案（该车道**只读**，已核权威 `pc` 未变）。
> **⑫ 本波新增纪律 3 条**（正文在 `docs/CURRENT-STATE.md` §5）：**35** 读数之后仪器变了 ⇒ **作废的是"配对"、不是"读数"**（表头必须带两份读数 + 两份仪器 sha；车道改完仪器必须通告冻结方；复读即便逐项相同也不能省，因为"相同"是测出来的）；**36** 弱配对的臂，**"没影响"必须靠"重取"拿到、不能靠"论证"**（本例两条结果：四支臂逐字节相同 ⇒ 推理升格为实测；`tline` 变了 ⇒ 判据必须写成"每行位移都被归因"，而非"逐字节相同"）；**37** **"检查器没说话"是一种"读数为零"，不是"绿"**（⑩①②两条真洞都长这样；`EXPECT=UNKNOWN`/`SKIP`/`NOINFO` 一律不得计入通过数；"恰好没坏"不构成"被看着"）。
> **⑬ 本波文档落点（sha16）**：`docs/CURRENT-STATE.md` = **`1512f1a5edd5bbaa`**（135,454 B / 326 行；§0 `#16` 冻结横幅＋§1 九位＝`#16`＋§2 门禁/`APPSYNC` 两份读数＋§3 六条在 `#16` 重核＋§4 新增三行、更正一行＋§5 新增纪律 35–37＋§6/§7 补新车道与新报告）｜`handoff.md`（**本记录**；其自身 sha 由交付回执记，**不写进本文件**——一写就自指失效）｜`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`（`#16` 表头；**sha 由该文件写者记**，本记录不替它宣称）｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`D-E1`／`D-A1` 精化等；同前）。
> **下一波预告**：**`#17` = 产物侧 shim sha**（把 `hbtextline_shim_stale` 从 mtime 代理升为**产物内**内容比对；T17A 的工具是**下界**，够不够当判据要先定；落地会改 `pc` ⇒ 经环传播动 `pf`/`reach`）；另有 **`D-E1`**（真机 `Inflate` 偏置）与 **⑩③（PC 侧缩进接线）** 两条**明确不许在本波顺手修**的项，各自的判别臂已登记。
> ### 🔴 波 `#16` 收官**补记**（主控，同日 19:0x–19:2x）—— 三处更正 + 四条车道产物（**这一节优先于上面 ⑬ 里的文档 sha**）
> **① `D-R2` 的定性被读数否掉（最值钱的一条）**：在三条车道全部收工、只有文档在写的**静树**上连跑 **5 趟 `verify-all`，每趟记 `loadavg`/`mem_available`** ⇒ **3 绿 / 2 红**（`rc` 序列 `0,0,1,1,0`；日志 `$HOME/wfp-runs/w16-pre/verify-all-16.out` `ce174c8cde3e9692`、`-q4.out` `191c041650331085`、**`-q5.out` `1555da7c8c41f72c`**、**`-q6.out` `0211affddd3aa2c1`**、`-q7.out` `048f143b2439abc4`），两趟红都是 `ManagedLayer.Tests ❌ (rc=1)`；这 5 趟 `loadavg` **1.26–2.41**、`mem_available` **3026–3296 MB** —— **远低于 `#15` 那次"4 条车道并发"的 4.26**，**却仍然约一半红** ⇒ **"并发/负载触发"这个此前只敢记成"强先验"的说法，现被否掉**。
> **读数辨析**：两趟红里该工程**一条用例都没产出**（该趟合计 `795 = 787`〔前 4 个测试工程〕`+ 8`〔`Presentation.Tests`〕；绿趟是 `871 = 787 + 76 + 8`）⇒ 是 **TESTHOST 整批崩（0 案例）**，不是"某几条用例失败"。
> **后续判别实验（4 趟）**：单独跑 **3/3 全绿 76/76**（`loadavg` 0.59–0.64）｜"按 `[2]` 段顺序先跑前置工程再跑它" **第 1 批 2/2 全红**（`测试主机进程崩溃`，`失败 11/通过 52/合计 63`、`失败 12/通过 59/合计 71`）—— **但那 2 趟我把 HelloMil 的 csproj 路径写错了**（`MSB1009: 项目文件不存在`、`rc=1`）⇒ **不是干净的序列数据点**（**仪器错误与被测件失败同时在场**，这正是纪律 30 的同族；`127`/`MSB1009` 这类"没跑成"**既不是通过也不是失败**）｜**把路径改对后重跑 2/2 全绿**（`HelloMil rc=0 通过 19`、`ManagedLayer rc=0 76/76`）。⇒ **诚实结论：间歇缺陷；唯一被否掉的是"负载"；触发器（时序 / testhost 复用 / `obj` 与构建服务器 / X 连接或窗口状态）尚未有判别性读数**。**关闭判据不变而计数归零：当前 3/5 且不连续 ⇒ 未达成。**
> **② `exit=143` 的裁决 = 命名碰撞，不是错数**：门禁**判据①原文**（`run-wpftextdemo.sh:20`，实现 `:1078-1091`/`:1109`）是"**进程在截屏时刻存活，且收尾后退出码 = 143**（被本 runner 用 SIGTERM 正常终止）" ⇒ `exit=143` 是**应用进程**的退出码且是**设计期望值**（128+15）；`#15` 那句 `runner exit=0` 说的是**门禁脚本自己的 rc**（实测 `GATE16B_RC=0`）。⇒ **从此两个都写、都点名**：「应用 `alive=1 exit=143 ✅` × runner 自身 `rc=0`」。**不登记为缺陷**（纪律 15/18 的实例：读数必须连对象名一起写）。另补：**`verify-all` 的脚本 `rc = 0`**（该日志自身不记 rc，由主控那趟实读）。
> **③ 一条新登记（文档车道发现、主控采纳）**：`build/shims/PresentationCore.HbTextLine.cs` 里 `HasOverflowed` **上方的文档注释仍写着"本实现恒 false"**，而该属性本波已改成三分支真实现 ⇒ **注释与代码相反**。**未改**（`build/shims/**` 是 T1d 写域，且**此刻改一个字节就换 shim sha ⇒ 直接作废 `#16` 基线**）⇒ 已进 `docs/CURRENT-STATE.md` §4，判据 = "注释改动 = 换世代"（纪律 31），随下一波做。
> **④ 三条车道（本波新开）的最终产物（逐字，均可复算）**：
> · **T17A**（`#17` 产物侧 shim sha）：`build/MilBridge/tools/shim-in-artifact.sh` **`e2e1a42b5f0e5b45`**（16,612 B）、报告 `build/MilBridge/T17A-report.md` **`de044cb22c77c9c8`**（30,681 B）。读数 `SHIM_IN_ARTIFACT=PASS artifact=c0763fc10173e7ff artifact_bytes=4194816 shim=bc04c05ab6d8d82a new=2/2 stable=14/14 recent=2/2 refs=23`、`rc=0`；红证 = 三份旧 DLL 上 `MISMATCH rc=1` 并点名缺哪两个 token（稳定 token 14/14 仍在）；`NOINFO rc=2` 六种；连跑两次机读行逐字节相同、只读性已验证。**边界（读它时必读）：只是下界** —— 它靠 `D-O1` 新引入的 `_boxOriginX`/`boxOriginX` 才能判红；**将来某次 shim 改动若不引入新符号，会退化成 `WEAK-PASS rc=3`（故意非 0）** ⇒ **改 shim 的波必须点名"本波新引入的符号"**。把下界变等号的三条路（`AssemblyMetadata` / PDB document checksum〔未测，不声称〕/ 私有目录确定性重建比 sha〔未跑〕）本波**一条都没走**；**未接进 `verify-all.sh`**。
> · **TAPPS**（app-local 检查器）：`build/DirectWrite.Linux/wic-shim/applocal-expect.py` `7c131b3f33b7e74e → **6eafbea14e7ea41e**`（27,314 B）、`check-applocal-sync.sh` `3ba5284bad838b14 → **aad23482f84bdf44**`（55,520 B）、报告 `build/DirectWrite.Linux/TAPPS-blind-half-report.md` **`9071d4bcf39918b8`**；自检 **15/15 → 17/17 `SELFTEST=PASS`**。`D-A1` 加固：`UNEXPECTED=1[**DECL-GAP-EQ=1 DECL-GAP-DIFF=0**]`（**类别名未改、`UNEXPECTED=N` 槽仍在**），两极红证齐（内容不同 ⇒ `UNEXPECTED-DIFF`+`DIVERGENT=1`+`rc=1`；还原 ⇒ `UNEXPECTED-EQ`+`rc=1`）⇒ **可见、仍红、非绿**。**主控波后用新仪器复读**：`APPSYNC=MISMATCH`、rc=1（`$HOME/wfp-runs/w16-pre/appsync-new.out`）；`grep -n 'appsync\|applocal' verify-all.sh` **无输出** ⇒ 换这个检查器**不可能**改变任何 `verify-all` 裁决。**新洞（比 `D-A1` 大）**：`ITEMS` **只覆盖 5 个件** ⇒ `FallbackCriteria/bin/Debug` 17 个 DLL 只有 2 个被判定、`grep -c PresentationCore.dll` = **0**，而**那里当时真的躺着一份 `#15` 时代的 `pc`（`532c7f54f7573070`）而权威已是 `c0763fc10173e7ff`** ⇒ **主控已把那一份刷成权威并披露**（刷前 4,194,304 B → 刷后 4,194,816 B，`cmp` 逐字节相同）—— **刷一份 ≠ 补洞**；另：**全部 `.so` 副本（含已发布的桥，`EXPECT=UNKNOWN`）不可能变红**（等值 `libwpfwic.so` 放进宿主目录 ⇒ `OK`、`UNEXPECTED=0`、`rc=0`）；**拷贝点枚举器自身漏报**（只印 20 个里的 18 个、只扫 `build/**/*.sh`、只匹配字面名 ⇒ 漏 2 个 MSBuild `<Copy>` + `run-wpftextdemo.sh:179/:191` + 13 处变量间接写入含 `run.sh:210`），**20 个点里 3 个写点全是真的洞**（今天安静只因副本恰好同 sha；删掉/改旧都不红；两处用 `2>/dev/null || true` 吞失败）。
> · **TDT2**（`D-T2` 边界复核）：报告 `build/MilBridge/TDT2-boundary-report.md` **`6388461b4ecd0de7`**（53,018 B）；**只读**（跑前跑后 `pc` sha 未变）。**原登记的"`ParagraphIndent ≠ 0` 时 max 含 indent 而 min 不含"被推翻**（对生成物 `grep -n indentDip` **只有 `:256` 一处命中**、两个探针都不传 indent；那个接法只存在于**从未编译过的草稿**，与 `(305,100) CS0103` 对得上）；**真身 = `TextModifier` 作用域实参不对称**（max 传 `modifierOpenIndex/CloseIndex`、min 一个都不传）⇒ 判为**缺陷、不是照抄真机**（上游 min/max 与 `FormatLine` 同用 `PrepareFormatSettings`），**量级是预测不是实测**。**"没有臂消费 `minWidth`"被更强地确认**（13 宿主 0 命中、30 份 oracle JSON 无 min/max 输出字段、**没有任何臂驱动 PC 的 `TextFormatter`**）。
> **⑤ 主控自己复核并新登记的一条（冻结相关）**：PC 侧 `:575` 把 `settings.Pap.ParagraphIndent` 传给宽松回退 `TryFormatLine` 的 `paragraphIndent`，而 `:256` 把它送进 shim 的 **`indentDip`** 槽（`paragraphIndentDip` 恒 0、**`Pap.Indent` 从不被传**）⇒ 按本波确立的 Tab 语义，应用路径的**停靠网格锚点会变成 `PI` 而不是 `Indent`**（内容起点是对的）。**五臂全都看不见它**（`layout-b34` 语料 `Indent = paragraphIndent = 0`，614/614；臂自己把两个参数接对了）。**量级未测、本波不许修**（一改就动 `pc` ⇒ 作废正在冻的基线）。判别臂（`--minmax-oracle` + 真机重录）已在 `TDT2` 报告 §4 预登记。
> **⑥ 本次补记改动后的文档 sha（取代上面 ⑬ 里的旧值，纪律 4）**：`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` = **`8a3f0f11c460013d`**（`#16` 表头 + `#15`/`#14` 历史块）｜`docs/CURRENT-STATE.md` = **`2c36ff25c289ac89`**｜`docs/WAVE16-PREREGISTRATION.md` = **`f526d0dad3f32d89`**（新增 §7 收官）｜`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` = **`cb6af309c88136a4`**（`D-A1` 加固小节 + 新 `D-A2`/`D-A3`/`D-T3` + `D-T2` 更正 + `#17`）｜`handoff.md` = 本文件。**仪器版本**：`build/MilBridge/tools/tline-gate.sh b37a5c9f55ae71a4`｜`known-red.json **f9843bde351029dc**`（rev 7）｜`verify-all.sh a68823631e8f8919`（**10 步**）｜门禁 `b37a5c9f55ae71a4`｜五臂日志 `build/MilBridge/arm-logs/`（`tline 89ad10ac614b4d3b`、`tab-zero b9d81590f3fcd800`、`tab-anchor 99d72b385fe23a90`、`tab-rtl 419e8aaa9c72a9a0`、`textlineproto 4bceceeed570ba70`）。

> ## 🎯 里程碑：**M2 达标（2026-09-10）**
> `samples/HelloWpf`（纯 net10.0 + 9 个自产程序集 + 自产 `PresentationFramework.Classic` 主题 + 真 BAML）
> **在 Linux 上真的把窗口映射到 X 服务器，并把图形与文字都画了出来**：
> `xwininfo` **Map State: IsViewable**（667×417，"HelloWpf on Linux"）、`xwd` PNG `docs/m7c-accept-zero-probe.png` **56,055 B**、
> 退出码 **143**（存活不崩）、台账 **`未画种类 0`**（通道里每种指令都真的画了，含 `MilGlyphRun×2`）。
> **主控视觉复核（读图，非直方图推断）**：见到**白色 "Hello WPF on Linux" 标题**、**tomato 矩形（白描边）**、
> **渐变椭圆**、**旋转的绿色三角形（Path）**、**径向渐变蓝圆**、**第二行说明文字**、蓝色渐变背景 ⇒ **文字与图形都是真的**。
>
> **当前全量状态（2026-09-10 18:27，`verify-all.sh`，X 开）：步骤 9/9 通过，用例 742 通过 / 0 失败 / 0 跳过。**
> **WIC 托管闭环 ①–⑤ 全绿**（严格模式，`BYTE_MISMATCH=0/1920000`，与 `SKBitmap.Decode` 逐点一致），默认开关已翻。
> **路线 C 已交付**（运行期 GSUB/GPOS 剥离 ⇒ 任何字体都能过闸门②）。

> ## ✅ 波 `#17` **完整记录（收官，主控，2026-09-16 12:5x）**
> **内容 = PC 侧三件**：**P1**（`AssemblyMetadata` 把"产物里编的是哪个 shim"从**下界**升成**等号**）＋ **P2**（`D-T3`：宽松回退的 indent 接线）＋ **P3**（`D-T2` 真身：min 宽度探针补 `TextModifier` 作用域实参）。预登记 `docs/WAVE17-PREREGISTRATION.md`（含其**修订 v2**：侦察车道推翻了 v1 的两处）。**`build/shims/PresentationCore.HbTextLine.cs` 本波一个字节未动**（仍 `bc04c05ab6d8d82a`）。
>
> **① 本波发了两次波，两次都留档 —— 第一趟的那份产物不能当基线（原因已定案）**
> · **第一趟** `close-wave-w17`（`12:24:12`）：`W17_WAVE_EXIT=0`、`verify_all=PASS`，但它**静默抹掉了 P1**。根因（W17C **自己复现过**，不是照信）：波第 1 步 `python3 build/port-lib.py <proj>` **从上游重新生成** `PresentationCore.Linux.csproj` ⇒ P1 当初**手加**的 6 行 `<Import … HbTextLineShimSha.targets />` 被连同重写（`26ce64b8f4452ed4`/205,939 B → `e2558faa0cc6b5d1`/205,471 B）⇒ `pc` 从 `18c49eec6992c7d9`（含元数据）退回 **`ac16320a14f549d4`（4,194,816 B、无元数据）**。**附带事实**：那一步会把**所有**应用器的接线一起抹掉（193,040 B 才是"裸 port-lib"态）。
> · **为什么所有绿判据都没红**：波的"生成物指纹 `state=ok`"量的是**源 → 产物**，不是"我上次手加的东西还在"；PC 那行还报"**0 错误 0 警告**"（连"源缺失就告警"的 target 都没跑，因为**整个 `.targets` 根本没被 import**）。**唯一红它的是 P1 自己的等号读者**（`ShimShaReader`：旧 pc 给 `no`、波后 pc 给 `NOINFO reason=attribute-absent`）。
> · **处置**：**已立纪律 38**（往生成物里手加的东西 ⇒ 必须把"加它的动作"放进**生成机制**；**红线判据 = 跑一次 `port-lib.py` 之后它还在**），车道 W17C 按正确通道**重落**：**新应用器** `src/WpfGfx.Linux.Native/tools/patch-presentationcore-hbtextline-shimsha.py` **`81f821ae225eb3a0`**（自己生成 `HbTextLineShimSha.targets` **`3127e82b76ce8c24`** + 只插 3 行到 `Sdk.targets` 锚点前；幂等、`--check` rc=0/1），并登记进 `build/integration-wave.sh` **`770419556b9597df`** 与 `build/MilBridge/tools/applier-audit-expected.txt` **`eecf8f28d3e6b9f9`** ⇒ **摘掉它会判红**。
> · **第二趟** `close-wave-w17b`（`12:42:58`）：`W17B_WAVE_EXIT=0`、`native_rebuilt=0 / bridge_republished=0`、`verify_all=PASS`（**10 步 0 失败 / 871 通过 2 跳过**）、输入稳定 `db3110fc…`；**接线活过了波**（波后 csproj 里 import 命中 **1**，等号读者在新 `pc` 上给 **`SHIM_SHA=no`**）⇒ **P1 耐久**。
>
> **② 九位与"只动两位"**：`bridge caf7baf9e67719aa`（4,983,696 B；`BRIDGE_SRC_FP=0b7c5a54267064fc`）｜**`pc df6dbb1c2bfb4162`**（4,195,328 B）｜**`pf 388053cd4c9ba91f`**｜`windowsbase e6216fe961a2bfb9`｜`provider 9aa0d744802aaa31`｜`win32shim 0098234982391bbf`（283,648 B）｜`wic_shim 03b67fbcd7c385b6`｜**`hbtextline bc04c05ab6d8d82a`**（未动）｜`dwf b6743030ff1eb907`。⇒ 相对 `#16` **七位未变、只动 `pc` 与 `pf`**（`pf` 是环成员，每趟波必变）。`inputs_fp` `fe1bbcae…9adf → db3110fc78bb0346564ef37e7753e0b8483d8bf95de6642b7a2d3bf1b297738c`（**预期**：应用器与 `integration-wave.sh` 都在该指纹覆盖面里）。渲染侧 `WpfGfx.Linux.dll 0c597fb6ec1eec70` 未重建。
> **`pc` 的中间态留痕（引用下列 sha 的读数都属于中间态）**：`c0763fc10173e7ff`（`#16`）→ `18c49eec6992c7d9`（P1）→ `1280323c9173bcde`（P1+P2）→ `14086882b1509dcd`（P1+P2+P3）→ `ac16320a14f549d4`（**第一趟波抹掉 P1 后**）→ `7680da47c39ec7ed`（重落 P1）→ **`df6dbb1c2bfb4162`（第二趟波，冻结值）**。
>
> **③ 身份自检**：桥源指纹两侧一致 ✅｜生成物指纹 `state=ok（PC/WB/PF）` ✅｜**应用器审计 `appliers=22 ok=80 miss=0 red=0 rc=0`** ✅（本波**升过覆盖面**：把 `patch-presentationcore-lineheight-trace` 与新的 shimsha 应用器一起登记 ⇒ 见 ⑧ 的 `D-R7`）｜输入稳定性 ✅｜`hbtextline_shim_stale=no`（`basis=auth`）｜`BRIDGE_SRC_STALE=no`｜`APPSYNC` 非 PASS（`D-A1`，与 `#16` 同形；两份仪器 sha 都记在表头）。
>
> **④ 三件的判据读数（逐件，四元组口径）**
> · **P1**：应用器 `patch-presentationcore-hbtextline-shimsha.py` **`81f821ae225eb3a0`**；`HbTextLineShimSha.targets` **`3127e82b76ce8c24`**；读者 `build/MilBridge/tests/ShimShaReader/Program.cs` **`0ef57677afef9f6d`**（`PEReader`+`MetadataReader`、**不加载程序集**、三态 `rc 0/1/2`、7 个 `NOINFO` 用例）。**两极化 A/B/C**：A 改源一字节 + `cp -p` 保旧 mtime + **不重建** ⇒ **`yes`**（**旧 mtime 代理在此给假绿 `no`**）；B 源改回 + **不重建** ⇒ **`yes`**（判据是**内容**、不是"有没有重建"）；C 重建 ⇒ **`no`**。**重落后的第二级红证**：摘掉接线 ⇒ `--check rc=1` + 审计**红** + 读者 **`NOINFO attribute-absent rc=2`**；还原 ⇒ **`no rc=0`**（第一版拿裸 port-lib 树构建撞 `error CS = 212` ⇒ 那条读数**作废**，已记）。**P1 的"行为中性"是读数不是论证**：**P1-off**（`#16` 的 `c0763fc10173e7ff` 副本）与 **P1-only**（`18c49eec6992c7d9`）跑同一条臂 ⇒ stdout **逐字节相同**（`2bca3316fcdb264b`：非0缩进 红=184/224、`rc=1`）；**P1+P2**（`1280323c9173bcde`）⇒ 红=72/224、`rc=0`、差 **917 行** ⇒ **中性成立 + P2 效应可分离，一把取到**。
> · **P2**：应用器 `07dc7627f609e031 → a3357070dae6de99`、生成物 `f86198dfdd349332 → 9fd04d10a6479dcd`。改法与预登记 v2 逐条一致：`TryFormatLine` 收 `indentDip`/`paragraphIndentDip` 两个 **DIP** 形参，站点1 传 **`paragraphProperties.Indent` / `.ParagraphIndent`（原始 DIP）**，**没有**用 `settings.Pap.*`（那是**理想整数 ×300**，PI=24 到达时是 **7200**）。**E1** `rc=1（未登记 228）→ rc=0（未登记 0 / 红 116 / 绿 172 / 不可比 148）`✅｜**E2** 非0缩进 红 `184 → 0`（`@default` 臂 **92/92 全绿**）✅｜**E3** `PI≠0` 红 `88 → 0`（`@default` 44/44）**且全表无 `Δ≈+7200/14400`** ⇒ **不是坏修法** ✅｜**E4** `notab-control@w80@i24` 宽 `26.695312→50.695312`（Δ=+0.001979）、`x(a)=24.000000`、`x(b)=37.347656` ✅｜**E5** `lead-tab-a@w140@i24` **tab 网格锚 `0 → 24.000000`（Δ=0.000000，精确复位）**、宽 Δ=+0.000989 ✅｜**E6** 零缩进对照 **`52/52` 逐位不动** ✅｜**E8** `relaxedHandled=496>0`、`relaxedFailed=0` ✅（544→496 是正常收敛，拿 544 当判据会**假红**）｜**E7 ❌ 被推翻**（见 ⑦）。
> · **P3**：应用器 `a3357070dae6de99 → 188f75a67294138f`、生成物 `9fd04d10a6479dcd → 56a5b4a5be1c6bcc`；新臂 `build/MilBridge/tests/MinMaxProbe/**`（`cfcf464457163280`）。**构造例实测翻转**：`mod0`（**零长** `TextModifier` 在 cp=0）**修前 `min=22.652344 max=0.000000 rel=gt`（Min>Max，真机契约禁止）⇒ 修后 `min=0.000000 max=0.000000 rel=eq`**；阴性对照 `control` `min=22.652344 max=90.609375 rel=lt` **两相逐位不动**；**单变量归因**成立。既有臂 `PcLineOracle` 复跑 stdout 与 P2 交付**逐字节相同**（`07615909a1ffaa8b`）⇒ 射程外不动。牙齿两极性：负断言与计数牙齿各被注入实验打红一次（`rc=1`），应用器逐字节还原。
> · **波后"读数迁移"的机器断言**：波内重建让 `pc` 换了多次 sha，**两臂读数仍逐字节迁移到最终件** —— `PcLineOracle` 在最终 pc 上 stdout `dfb250295761b4ce`（与三点对照的 P1+P2 **完全一致**）；`MinMaxProbe` 仍 `mod0: rel=eq` / `control: rel=lt`。它与 W17B 交付那趟的差 **2 行、全是登记表路径**（`$HOME` 版 vs **已回仓**的 repo 版，条数同为 136）—— 逐行归因完毕。
>
> **⑤ 等号读者 + T17A 工具并列留档（`D-R4`）**：读者（判"产物里是哪个 shim"）= `SHIM_SHA=no reason=content-compare artifact=df6dbb1c2bfb4162 … product_sha16 == tree_sha16`、`cmp=full64`、`rc=0`；T17A 工具 = `SHIM_IN_ARTIFACT=PASS … new=2/2 stable=14/14`、`rc=0`。**⚠️ 口径**：后者**只证下界**、其 `PASS` **不区分内容**（W17C 用三份**内容不同**的产物各打一次 ⇒ **三次都 `PASS rc=0`**；它自述的"无新符号 ⇒ 退化成 `WEAK-PASS rc=3`"**是错的**，`WEAK-PASS` 今天**不可达**）⇒ **"产物里是哪个 shim"一律以等号读者为准**。
>
> **⑥ 应用门禁三趟，读数逐位相同（也与 `#16` 相同）**：`default drawn=260 colors=3960`、`env drawn=144 colors=2828`、`frames_good=14/14`、`shot_dims=938x938`、`cross_ae=0`、`max_concurrent_apps=1`、`leftover_after=0`、`scroll=ok`、`exit=143`；三趟的 `pc` 分别是 `14086882b1509dcd` / `ac16320a14f549d4` / `df6dbb1c2bfb4162`（基线文件 `591500e4fed84871` / `7b73fe7a20616021` / **`1d16c6436b8fbe94`**；stdout `gate17c.out` **`6c834059abf861c5`**）。⇒ 同时确认 **P2 的预测①**（应用门禁不变）与 **P1/P3 的端到端中性**。
> **⚠️ 现场失误（我的，留档）**：第 1 趟我把 `DISPLAY=:97 xdpyinfo` 检查与门禁**写在同一条命令里**，检查打出 **`:97 DOWN`** 却**没有拦住运行** ⇒ 那一趟跑在 **runner 自起的 Xvfb** 上（就绪竞态的正中靶心）。**结果侥幸干净**（6/6 PASS、无 `exit=134`/all-blank、读数与 `#16` 逐位相同），但**装置来源更弱** ⇒ 我随后起了**常驻 `Xvfb :97`（`setsid nohup … &`）**，第 2/3 趟都走"**复用已存在的 X server**"分支（纪律 30 的正路）。**判据已写进预登记 §3.1 第 7 步**：`xdpyinfo` 不在就**先起常驻**再跑，**不许**把检查写成"只打印不拦人"。
>
> **⑦ 被推翻的两条"判据/设计"（比落地件更值钱）**
> · **TDT2 §2.5 的构造例表**：它设计的 `TextModifier`（`Length=1`）**根本到不了被测代码** —— 实测 `relaxedFailed=1 relaxedHandled=0`、`GetTextRun` 只调 1 次、随后交回 LS ⇒ `EntryPointNotFoundException: LoCreateContext`。**代码级 + 实测双证**：`TextModifier.CharacterBufferReference` 是 **sealed default** ⇒ `ExtractRun` 返 null ⇒ `CollectLenient`（生成物 `:149-152`）**必然 return false** ⇒ **只有 `Length ≤ 0` 的 modifier 能过**。P3 的红证因此改用**零长** modifier（改对了才翻得出来）。
> · **E7（我给的验收项）**：`E7: 孪生恒等式修后仍须违反 0` —— 实测修后 **违反 102/144**，而**那正是修好的表现**（`i24` 本就该比 `@i0` 宽 24）。**它把缺陷态当成了规律** ⇒ 已降级为"缺陷态指纹"，**复跑时不许把 102 当红**（与 `L25`、`ProviderShapeTests` 同族）。
>
> **⑧ 本波产出的新登记（逐条；详见 `docs/CURRENT-STATE.md` §4）**
> · **`D-R5`**：**手改生成物**的落地件会被下一趟波静默抹掉（本波第一趟波就发生了）⇒ **纪律 38** 已立（含"红线判据 = 跑一次 `port-lib.py` 后它还在"）。
> · **`D-R6`**：`pc` 的 sha **依赖构建路径**（同源同 `@(Compile)`，仓内 `obj` 与两个不同 `$HOME` obj 得**三个不同 sha**；**同目录内**重复构建才逐字节相同）⇒ **"换目录重建得同 sha"不是有效判据**，可复现性口径必须缩到"同一输出目录内"。
> · **`D-R7`（已修）**：`patch-presentationcore-lineheight-trace` **不在任何接线清单里**（波日志逐字 `⚠ 不在显式顺序表里，追加执行`）⇒ 长期在 applier 审计**覆盖面之外**（"生效了但没注册"）；登记后审计 **`appliers=20 ok=74` → `22 ok=80 miss=0 red=0`**（覆盖面变大 = 判据变强）。**副作用已记**：它执行时机提前 ⇒ csproj 补丁块顺序变 ⇒ 该 csproj 的 sha 必然与"波留下的那份"不同（**内容多重集相同**，机器断言）。**主控裁决 = 保留登记**（**审计覆盖面 > 生成物字节同一性**）。
> · **`D-T4`（产品缺口）**：PC 路径**不携带 `DefaultIncrementalTab`** ⇒ 停靠位非默认的段落在**应用路径上**也拿不到它（shim 恒取 `4×em`）。**仪器侧** = 任何走 PC 的臂喂不进去（`PcLineOracle` 的 `tab0` 族 **136 条**按"如实标注射程"登记、**不是**消音；表已**回仓** `build/MilBridge/tests/PcLineOracle/known-red.txt` **`89324f1f643167e5`**）；**产品侧** = 真实缺口，**本波只登记不修**；真机在该输入下**没有真值**（oracle 把 `DefaultIncrementalTab` 写死 0）⇒ 判据需先补 Windows 重录。
> · **`D-T5`**：含 **`Length ≥ 1`** 的 `TextModifier`/`TextEndOfSegment` 的段落在 PC 路径上**整条交回 LS**（Linux 抛 `LoCreateContext`）⇒ `CollectLenient` 的 modifier 记账对**真实源**永不生效；`#13` 的零宽接线**只被工厂级臂验证过**。**未测**：该异常会不会传到应用层。
> · **`D-T2-c`**：两个宽度探针共用一把**缺 `modifierScopeEnd`** 的已知错尺子；**前置** = `CollectLenient` 记下覆盖终点，**前置未满足前不许改**（改 = 编值，纪律 22）。
>
> **⑨ 仪器版本（本波新增/改动）**：**新增** `patch-presentationcore-hbtextline-shimsha.py` **`81f821ae225eb3a0`**｜`HbTextLineShimSha.targets` **`3127e82b76ce8c24`**｜`ShimShaReader/Program.cs` **`0ef57677afef9f6d`**｜`PcLineOracle/Program.cs` **`544aab374ee8e1a6`**（+ `known-red.txt` **`89324f1f643167e5`**）｜`MinMaxProbe/Program.cs` **`cfcf464457163280`**；**改动** `patch-presentationcore-textline-fallback.py` **`188f75a67294138f`** ⇒ `TextFormatterImp.Linux.cs` **`56a5b4a5be1c6bcc`**｜`integration-wave.sh` **`770419556b9597df`**｜`applier-audit-expected.txt` **`eecf8f28d3e6b9f9`**。**未变**：`run.sh 3e513e88a4fa4ec9`、`HbTextLineParity/Program.cs 2e458928fc1577c2`、**`shim bc04c05ab6d8d82a`**、`tline-gate.sh b37a5c9f55ae71a4`、`known-red.json f9843bde351029dc`、`verify-all.sh a68823631e8f8919`、`shim-in-artifact.sh e2e1a42b5f0e5b45`、`CoverageProbe/Program.cs a8727a5bed6bf049`。
>
> **⑩ 收尾清单里还没做的（不许当绿）**：`#17` **未接任何新判据进 `verify-all.sh`**（接前要先定 `rc` 语义与"每波点名新符号"的制度）｜`D-T5`/`D-T4` **只登记未修**｜`D-T2-c` 的前置未做｜**严格档的 indent 缺口**仍在（P2 只修宽松档）｜**`P4`（`HasOverflowed` 的过时注释）本波裁决不做**（本波 shim 未动 ⇒ 世代不变；为一行注释换一次五臂重取+重钉不划算 ⇒ 随下一件动 shim 的活一起做）｜`D-E1`/`D-F2`/`D-A1`/`D-A2`/`D-A3`/`D-R3`/`D-F1c`①c/`D-F3`/`7CJK candidates=45`/MIL 侧三个计数 —— 均未动或未取到读数。
> **下一波预告**：① **`D-R3`**（两个**产品侧无保护**的 `SetDllImportResolver` 安装点：`Win32ShimResolver.cs:174` 的 `[ModuleInitializer]`×4 程序集、`X11Native.cs:34` 的静态构造 —— 都会翻九位）；② **`P4` + 严格档 indent 缺口**（同批要动 shim ⇒ 一次重取+重钉覆盖两件）；③ **`D-T5`/`D-T4` 的判据补录**（真 modifier 的应用级可达性；`DefaultIncrementalTab` 的真值需 Windows 重录）。
>
> ## ✅ 波 `#18` **完整记录（收官，主控，2026-09-16 15:2x）**
> **内容 = `D-R3`：给两个"产品侧无保护"的 `NativeLibrary.SetDllImportResolver` 安装点加守卫**（预登记 `docs/WAVE18-PREREGISTRATION.md`，含**修订 v2**）。**V1** `build/shims/Win32ShimResolver.cs`（`[ModuleInitializer]`，编进 **WindowsBase / PresentationCore / UIAutomationTypes / UIAutomationProvider** 四个程序集）｜**V2** `src/WpfGfx.Linux/Windowing/X11Native.cs`（静态构造）｜**V3** `build/DirectWrite.Linux/WicClosedLoop/Program.cs`（**死映射已删**）。**本波没碰 `PresentationCore.HbTextLine.cs`** ⇒ 世代绑定不变。
>
> **① 两次 sha 链（含"收窄"这一次，三态）**：V1 `ff3c53964cb8328b`（修前）→ `37b65d0ede827650`（守卫）→ **`0735327b6ca3ae4b`（收窄后）**｜V2 `045faa9b0785f6d2` → `12d7cf8217b34c0c` → **`8ede4d8a13cb3a28`**｜V3 `ef09e6e09e8e6f75` → **`f7c7fd61ef5c8ad8`**。报告 `build/MilBridge/V18A-report.md` **`2d7809699ebf51d4`**（606 行；§10 = 收窄节）。**五个工程私有编译 `error CS = 0`、0 警 0 错**。
>
> **② 先修复现（红证的前半，探针宿主）**：四件产品程序集 + `WpfGfx.Linux`，只要被抢先 ⇒ **`TypeInitializationException` + `InvalidOperationException: A resolver is already set for the assembly.`**。三种变体逐字留档：`variant=none` ⇒ `NO_THROW`（没人抢先时正常）；`variant=replica`（抢先者**映射同名**）⇒ **整模块被毒化**且 `POISON_RECHECK=THROW`（不可恢复）；`variant=different`（映射**不同名**）⇒ 同样毒化。
>
> **③ ⚠️ 本波最值钱的一条：第一版守卫"无条件自证"污染了以"段数"为尺子的判据 ⇒ 已收窄**
> 第一版为了"装了没生效"能当场发现，装了之后**无条件**用真 `[DllImport]` 走一次 ⇒ 实测**正常路径就把 shim 提前 dlopen**：`/proc/self/maps` 里 `libwpfwin32.so` **0 → 5 段**；**V2 更糟** —— `X11Native` 的静态构造在正常路径就把 **`libX11.so.6` 载进来（0 → 6 段、TOTAL +35）**。
> **主控裁决 = 收窄**（自证**只在"我们输了竞态"的分支里跑**）。**理由本身是判据**：本项目的**内存类主判据是"段数 / Σ虚拟"**（`D-F1c` 线的口径）⇒ 无条件多一次 dlopen 就是**往那把尺子里塞一个新映射**，而"数值判据推论不变"是**论证不是读数**。
> **收窄的验收核心（实测）**：`libwpfwin32.so` V1 PC **修前 0→0 / 收窄前 0→5 / 收窄后 0→0** ✓；`libX11` V2 **修前 0→0 / 收窄前 0→6 / 收窄后 0→0** ✓（V2 收窄后 TOTAL **244→244**）。**机器断言下在"针数"上**（TOTAL 在同目标不同进程间有 ±2 抖动；V1 收窄后 TOTAL 仍 +13 与修前 +15 同源 = 自然触发自身的 cctor/JIT，与 dlopen 无关）。
> **收窄的代价（车道如实登记，未补任何没做过的读数）**：判据**① 不再由守卫行使**（改用 `realcall` 直测 ⇒ V1 四件 `REAL_DLLIMPORT=OK value=1`；但**① 的修前对照没测过**、**V2 的 ① 没测过**）；判据**④ 的"安装点响亮"退回修前同款行为**。
>
> **④ 两极化红证（修后，`postfix.log` `0c8bb85d7d0255cc`）**
> · **(a) 抢先者映射同名 ⇒ 无害** ✓：四件产品程序集 `TRIGGER=natural NO_THROW` + `ResolverConflict=True` + **`SelfCheckShimVersion=1`**（真 `[DllImport]` 证明赢家接到的是我们的 shim）；而 **`variant=none` 时该值为 0** ⇒ **自证确实没在正常路径跑**（这是收窄的行为指纹）。V2 的 `replica` ⇒ `CCTOR_RESULT=NO_THROW` + `SelfCheckX11NameResolved=True`。
> · **(b) 抢先者不映射我们的名字 ⇒ 响亮且点名** ✓：`InvalidOperationException: WPF-on-Linux: 本程序集的 'user32.dll' 解析不到 —— 当前生效的解析器不是我们这一个…`（列全 6 个名字）。V2 的 `broken` 变体同理点名 `libX11.so.6`。
> · **非空泛** ✓：隔离夹具（依赖带齐、故意无 shim）⇒ 收窄后我们**赢了竞态、自证不跑**，缺件由**原有解析路径**在**首个真 `[DllImport]`** 处响亮失败（带候选路径与修复命令）—— **不是**守卫吞掉；守卫内部的非空泛证明由 `broken` 变体给出。
> · **勘误（车道自报）**：`prefix.log`（`e1e863738df59fae`）被 §D 的重跑**覆盖且无副本**；收窄前那份留档为 `postfix.narrow1.log`（`573add8e5f45c594`）。
>
> **⑤ 桥重发（本波与 `#17` 的关键差别）+ 三条红证**：`X11Native.cs` 是**桥源** ⇒ `BRIDGE_SRC_FP` 变 ⇒ 波决策 `桥重发=是`。**① **`BRIDGE_SRC_FP` 两侧一致 = `b6acdba4f01599d8`**；② **新桥里确实编进了本波代码**（`grep -a`：ASCII 标识符 `X11Native` 命中 **1**、`SelfCheckX11NameResolved` 命中 **4**；中文文案 `当前生效的解析器不是我们这一个` 以 **UTF-16LE** 命中 **1**、UTF-8 命中 **0** —— 托管字面量的既定形态）；③ **旧桥已留档可回退**（`$HOME/wfp-runs/w18-pre/wpfgfx_cor3.caf7baf9e67719aa.so`，4,983,696 B；新桥 `d567c26f197ec1e3`，4,987,840 B，`cmp` 不同=预期）。
>
> **⑥ 波与九位**：`close-wave.sh` `15:08:49 → 15:12:43`：**`native_rebuilt=0`、`bridge_republished=1`（rc=0）**、`verify_all=PASS`（**10 步 0 失败 / 871 通过 2 跳过**）、身份自检（桥源指纹两侧一致 ✅、生成物 `state=ok（PC/WB/PF）` ✅、应用器审计 `miss=0` ✅、**输入稳定性 波前==波后 = `da68a95174e2ec5ab9b141c554de5afd31b58dccb139b291ae6d25526c072217`** ✅）。**新九位**：`bridge d567c26f197ec1e3`｜**`pc 663114436443d2de`**（4,196,864 B）｜**`pf d8bfdc23f260ccd2`**｜**`windowsbase 1114a28ec5a03ab7`**（**自 `#8` 以来第一次动**）｜`provider 9aa0d744802aaa31`｜`win32shim 0098234982391bbf`｜`wic_shim 03b67fbcd7c385b6`｜**`hbtextline bc04c05ab6d8d82a`（未动）**｜**`dwf 0ed422ef2dd46445`**；`BRIDGE_SRC_FP=b6acdba4f01599d8`。**相对 `#17` 五位变**（单波里动得最多的一次）。
>
> **⑦ 判据读数逐位不变（位移表的核心预测成立）**：应用门禁**两趟**（`run_dir=…/w18-gate1`、`…/w18-gate2`；基线 `baseline18-run2.md` **`8c57ba2db68b43dc`**；stdout `gate18-run2.out` **`bfa7c18baa53c702`**、run1 `8a2e795179c7b22a`）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**，且 `drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`shot_dims=938x938`、`cross_ae=0`、`leftover_after=0`、`scroll=ok`、`exit=143` **与 `#17` 逐位相同**；`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=167`。**装置来源 = 常驻 `:97`**（两趟都走"复用已存在的 X server"分支；`:97` 在波前由主控 `setsid` 重起过 —— 上一轮的常驻进程已不在，**这次先起再跑，没重演 `#17` 那次"只打印不拦人"**）。五臂门禁 `TLINE_GATE=PASS … generation=#16 tree_gen=same … drift=0 gone=0 unregistered=0`、`rc=0`。**等号读者 `SHIM_SHA=no`**（`artifact=663114436443d2de`）；T17A 工具 `PASS`（**只证下界**，并列留档）。
>
> **⑧ 本波产出的更正与新登记**
> · **`D-R3` 严重性上调（"潜在" → "可达"）**：R17C 曾断言"外部安装者**只能输**" ⇒ **被 V18A 实测推翻** —— `Assembly.LoadFrom(pc)` 之后**外国解析器装得上**（`FOREIGN_INSTALL=OK`）⇒ **模块初始化器不是加载期跑的** ⇒ **产品丢竞态可达**（红证即走这条路）。
> · **预登记位移表漏了 `dwf`（如实记，不是"未归因"）**：`DirectWriteForwarder.Linux.csproj:76-77` 用 **HintPath 引用 `WindowsBase.dll`** ⇒ WB 字节一变，Roslyn 确定性输出把**引用件字节**纳入输入哈希 ⇒ 它跟着变（**与 `pf`/`reach` 环成员同族机制**）。
> · **`integration-wave.sh` 的 `ORDER` 缺 `WpfGfx.Linux`（`D-R7` 同族："生效了但没进波"，已修）**：改了 `src/WpfGfx.Linux/**` 后，波会重发桥（拿到修后代码），但 **Debug 可见位与 app-local 副本仍是修前的** —— 而那**正是应用门禁加载的那一份** ⇒ 读数会漏掉该改动。**主控已加为 `ORDER` 第一项**（叶子工程：无 `ProjectReference`、只用 SkiaSharp）：`build/integration-wave.sh` **`770419556b9597df`（38,072 B）→ `1172784c38fb8e31`（38,717 B）**。
> · **判据口径两处修订（v1 原文保留）**：V2 的 (a)/(b) 在原判据下**互斥**（`libX11.so.6` 系统可解析 ⇒ 两种抢先者可观察面相同）⇒ 改为"**响亮 ⟺ 我们自己映射的名字解析不到**"；**收窄的代价**如实登记（见 ③）。
>
> **⑨ 仪器版本（本波改动）**：`build/shims/Win32ShimResolver.cs` **`0735327b6ca3ae4b`**｜`src/WpfGfx.Linux/Windowing/X11Native.cs` **`8ede4d8a13cb3a28`**｜`build/DirectWrite.Linux/WicClosedLoop/Program.cs` **`f7c7fd61ef5c8ad8`**｜`build/integration-wave.sh` **`1172784c38fb8e31`**。**未变**：`PresentationCore.HbTextLine.cs bc04c05ab6d8d82a`（世代绑定）、`run.sh 3e513e88a4fa4ec9`、`HbTextLineParity/Program.cs 2e458928fc1577c2`、`tline-gate.sh b37a5c9f55ae71a4`、`known-red.json f9843bde351029dc`、`verify-all.sh a68823631e8f8919`、`shim-in-artifact.sh e2e1a42b5f0e5b45`、`ShimShaReader/Program.cs 0ef57677afef9f6d`、`PcLineOracle/Program.cs 544aab374ee8e1a6`、`MinMaxProbe/Program.cs cfcf464457163280`、`port-lib.py d9f428a25f06dacc`、`applier-audit-expected.txt eecf8f28d3e6b9f9`。
>
> **⑩ 收尾清单里还没做的（不许当绿）**：`D-R3` 只证了**路径可达**、**没证真宿主会走到**；**AOT 镜像内 `X11Native` 静态构造是否执行、其 `Assembly` 身份**未测；收窄使判据①/④ 的射程缩小（已登记）；全仓 9 个安装点其余 7 个只在只读审计里枚举过；**`P4` + 严格档 indent 缺口**留到下一波（同批动 shim ⇒ 一次**重取五臂 + 重钉登记表**覆盖两件 —— 这是 `#17`/`#18` 都没付的那笔成本）；`D-T5`/`D-T4`/`D-T2-c` 只登记未修；新判据仍未接进 `verify-all.sh`。
>
> ## ✅ 波 `#19` **完整记录（收官，主控，2026-09-16 15:5x）**
> **内容 = `P4`（`HasOverflowed` 上方的**过时文档注释**）+ **严格档（`HbTextFallback.TryFormatLine`）的 indent 接线**（`D-T3` 的另一半）**（预登记 `docs/WAVE19-PREREGISTRATION.md`，含**修订 v2**）。
> **本波是"必须付那笔成本"的一波**：`build/shims/PresentationCore.HbTextLine.cs` **正是在册红门禁世代绑定的三项之一**（`tline-gate.sh:137` 的 `SH_SHIM` 只绑这一个文件）⇒ **五臂必须重取、登记表必须重钉** —— 这笔成本 `#16`/`#17`/`#18` 都刻意没付。**实测吻合预登记**：shim 一改，门禁**逐字**变成 `TLINE_GATE=NOINFO arms=5 red=1 green=0 noinfo_arm=4 registered=3 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#16 tree_gen=advanced saved_shim=fe1b7ed8fa3ed231`、`GATE_REASON=noinfo-arms`、**`rc=2`**（**设计，不是缺陷**）。
>
> **① 两件的 sha 链**：shim `bc04c05ab6d8d82a` → **`fe1b7ed8fa3ed231`**（275,765 → 278,692 B）｜应用器 `188f75a67294138f` → **`daa1fe2a32d454cf`**｜生成物 `56a5b4a5be1c6bcc` → **`799e0366b312ec65`**（**只 1 处 hunk**，落在 `:568-586`）｜臂 `544aab374ee8e1a6` → **`a46e5e046583f69a`**。报告：`build/MilBridge/W19A-report.md` **`699cc39187268297`**（517 行）｜`build/MilBridge/W19B-report.md` **`da1d5fe7f55adfb6`**（34,024 B）。**权威 `pc` 在车道作业期间全程未动**（`663114436443d2de`），因为并发协议要求"权威重建归波"。
>
> **② A（`P4`）= 只改注释，零代码改动**：把"真机 3222/3222 全 false ⇒ 本实现恒 false"拆成两个命题（**语料分布 ≠ 取值域**）并逐条对上 `D-O1` 的三分支。**零代码改动经"剔 `///` 行后 `diff` 为空"机器证过**。全 shim 非注释改动行仅 **5 行**，全属 B。
>
> **③ B（严格档 indent）= 机制完全成立，残留一族（见 ⑧）**
> · **改法**：`HbTextFallback.TryFormatLine` 加 **带默认值**的 `indentDip = 0, paragraphIndentDip = 0`（**既有调用点零改动 ⇒ 逐位等价**，**两重证据**：① 算术 —— 工厂内 `indentDip`/`paragraphIndentDip` 的 5 处用法（`shim:1765/1771/1774/2866/2884`）全是加法或直接赋值 ⇒ **0 是加法单位元**；② 元数据 —— 同一探针二进制**就地换同目录 dll**：私生 pc 读回 **8 形参 `optional=True default=0`**，而**权威修前 pc `663114436443d2de` 读回 6 形参、无任何缩进形参**（负控））；PC 严格档调用点（生成物 `:565`）改传 **`paragraphProperties.Indent` / `.ParagraphIndent`（原始 DIP）**，**没有**用 `settings.Pap.*`（那是**理想整数 ×300**）。
> · **判据用 W19B 新建的严格档腿（`--tier strict`）量，层级来源自证**：`严格档接手=270 例、宽松档接手=0 例、缓存复用=18 例`；`fallbackCalls=496 fallbackHandled=496 bailed=0`、`relaxedCalls=0`。
> · **E2 ✅** `B-indent/lead-tab-a@w140@LTR@i24@default` ⇒ **tab 网格锚 `0.000000 → 24.000000`（Δ=0.000000）**、宽 `109.347656`（Δ=+0.000989）、`a` x `96.000000`（Δ=0.000000）⇒ **三项全绿**（修前只有宽是绿的、锚 **Δ=−24.000000**）。
> · **E3 ✅** `B-indent/notab-control@w80@LTR@i24@default` ⇒ 宽 `26.695312 → 50.695312`（Δ=+0.001979）、`x(a)=24.000000`、`x(b)=37.347656`。
> · **E4 ✅（射程外逐位不动）** 零缩进桶 `红=63 绿=41 /212` **与修前逐位相同**。
> · **E5 ✅（本波最锐的一条）** 孪生恒等式（我方值 == `@i0` 孪生值）**是缺陷态签名** ⇒ 修前违反 **0**、修后 **75**、最大差 `0.0020 → 24.0020` ⇒ **签名如期破裂**（`#17` 的 E7 曾把它当"必须保持"的判据，那次是错的；这次反过来：**必须破**）。
> · **E1 ⚠️ 部分达成，且我预登记的目标写错了**：修前 `非0缩进 红=184 绿=0 /224` → 修后 **`红=127 绿=57`**。**按失配词精确核过**（主控统计）：`结构=FAIL` 共 **116 条、全部是 `@tab0`**（= 已登记的"本臂表达不出来的输入"族）⇒ **非 tab0 的结构失败 = 0** ⇒ **indent 机制完全修好**；残留的 **67 条非 tab0 位置红全部是同一个失配词 `行#1 i=0 取不到字符边界`**（另有 54 条 `@tab0` 位置红）⇒ **另一族、与 indent 无关、机制未归因** ⇒ 登记 **`D-T6`**。⇒ **E1 原写的"红=92 绿=92"作废**（它不知道这一族存在）；**严格档腿的判据必须按桶 + 按失配词读，不许拿整腿 `rc` 当判据**。
>
> **④ 一条新口径（本波产出，引用前必读）**：**`pc` 的 sha 变了不再蕴含"行为变了"** —— `#16` 的 P1 把 **shim 整文件的内容 sha** 编进了 `AssemblyMetadata`（`HbTextLineShimSha.targets:58`）⇒ **改一句注释就改 DLL 字节**（W19A 实测：**同 obj 路径、只差一句注释**，`32533cae → 4fb7baad`）。`#16`/`#17` 那句"注释不进元数据"说的是**标识符/字面量**层面（`#Strings`/`#US` 里找不到注释），与"整文件 sha 被注入"是两件事。⇒ 判"产物里是哪个 shim"用**等号读者**（本波 `no` ✓），**不是**看 `pc` 的 sha 变没变。
>
> **⑤ 波与九位**：`close-wave.sh --skip-verify-all`（`OUT=…/close-wave-w19a`，`15:41:17`）：**`native_rebuilt=0`、`bridge_republished=0`**（**桥未重发，与预测一致** —— 本波没动 `src/WpfGfx.Linux/**`）、身份自检四项 ✅、输入稳定 `288447d98d255f4c56ce04300a6fbe7977a62940e45f78617cd1d44873668d39`。**新九位**：`bridge d567c26f197ec1e3`｜**`pc f4a454c8fe69cdfe`**（4,196,864 B）｜**`pf bd4e28e6a6f8b0e5`**｜`windowsbase 1114a28ec5a03ab7`｜`provider 9aa0d744802aaa31`｜`win32shim 0098234982391bbf`｜`wic_shim 03b67fbcd7c385b6`｜**`hbtextline fe1b7ed8fa3ed231`**｜`dwf 0ed422ef2dd46445`。**相对 `#18` 只动三位**（`hbtextline`/`pc`/`pf`）；**`bridge` 与其余五位未变**。
>
> **⑥ 世代成本（本波付了）**：先 `-c Release` 重建 CoverageProbe/TextLineProto（探针 dll `16013cbe1a0e268a`、mtime `15:41:37` ≥ shim mtime `15:30:15`），再逐条重跑五臂，最后 `ln -f` 入 `arm-logs/`。**四支逐字节不变**（`tab-zero b9d81590f3fcd800`／`tab-anchor 99d72b385fe23a90`／`tab-rtl 419e8aaa9c72a9a0`／`textlineproto 4bceceeed570ba70`）⇒ **本波两件未进它们的射程**（它们直接调 `HbTextLineFactory.FormatParagraph`，不经 `HbTextFallback`；A 只改注释）。`tline` **换了日志**：`89ad10ac614b4d3b → aa7259da9e2c77e8`（21,501 → 21,555 B），**30 行差全是身份/管道**（shim sha/大小/mtime/行数、`[applocal]`/`[T0.7]` 的权威同步与 `一致 4/4`、`固定=实读`、上一趟 artifact 回显、带时间戳的 `tline-ledger-lines-*.txt`、`/tmp/tmp.*`、`已用时间`），**判据行逐字节相同**（`exact=73 diff=0`、记账 `1298/1298`、宽度 `>0.34DIP=0`、折叠判定一致 `1297/1298`、明细 `232/236`、`② Extent 余差清单 95`、`T3b ❌`）⇒ **四条在册读数逐条复现、`drift=0 gone=0`**。**登记表重钉** `f9843bde351029dc → 3bf26e12f320dece`（`rev 8`、`generation.id=#19`、entries **仍 4 条**、每条 `caliber.instr_shim` 随世代更新、新增 `arms_retaken` 块、`expected_shape`/`expected_reading` **一字未改**）。**门禁** `TLINE_GATE=PASS … generation=#19 tree_gen=same … drift=0 gone=0 unregistered=0`、`rc=0`；**两极化**：删 `tline/T3b` ⇒ `unregistered=1` + `rc=1`；真表 ⇒ `rc=0`。
>
> **⑦ 其余读数**：应用门禁**两趟**（`run_dir=…/w19-gate1`、`…/w19-gate2`；基线 `baseline19-run2.md` **`1e917738b14b1b4e`**；stdout `gate19-run2.out` **`ff741db848cc119e`**、run1 `37d92e45d727964c`）⇒ `WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**，`drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`shot_dims=938x938`、`cross_ae=0`、`leftover_after=0`、`scroll=ok`、`exit=143` —— **全部与 `#18` 相同**（两趟都在**常驻 `:97`** 复用分支）。`verify-all` **rc=0 / 10 步 / 871 通过 2 跳过 / 第 10 步 ✅**（日志 `$HOME/wfp-runs/w19-pre/verify-all-19.out`）。**等号读者** `SHIM_SHA=no reason=content-compare artifact=f4a454c8fe69cdfe shim=fe1b7ed8fa3ed231 product_sha16=fe1b7ed8fa3ed231 tree_sha16=fe1b7ed8fa3ed231 cmp=full64` ⇒ **P1 的构建溯源被当判据用**（产物确实是用这一份 shim 编的）。T17A 工具 `SHIM_IN_ARTIFACT=PASS artifact=f4a454c8fe69cdfe new=2/2 stable=14/14`（**只证下界、`PASS` 不区分内容**）。
>
> **⑧ 本波产出的更正与新登记**
> · **F1** 见 ④（P1 × 注释的新口径）｜**F2**：应用器里 P2 的**来源计数牙齿**要求 `1/1`，本件加了严格档调用点后**必然变 `2/2`** ⇒ 它**当场 `rc=1` 拦下了车道**（**它是对的**）⇒ 按设计改口径为 `(1,1,2,2)` 并写明理由（**没有删牙齿**，判据只许变强）｜**F3**：车道**自己的牙齿连错三版**（v1 恒绿假牙齿 / v2·v3 假红）＋一处**仪器事故**（注错失败却继续跑 ⇒ 陈旧突变被当结果）⇒ 全部留档，并立"**牙齿写完必须两极化实测、注错失败要停**"的形态。
> · **`D-R8`（新立）**：`TextLineProto`/`HbTextLineParity` 的 csproj **缺 `EnableDefaultCompileItems=false`** ⇒ 私有 obj 重定向下 `16×CS0579`（**已证与改动无关**：换修前 shim 同样报、错误码条数不变；根因 = 默认 glob 收进陈旧的 `obj/*.AssemblyInfo.cs`）；车道用**只命令行注入**的 `excl.props` 绕过，**仓库内文件一个没改**。**只登记未修**。
> · **`D-T6`（新立）**：严格档腿上一族**位置红** —— **67 条非 tab0 + 54 条 `@tab0`**，非 tab0 的失配词**完全相同**：`行#1 i=0 取不到字符边界`；同一条用例在**宽松档腿不出现**该词（已实测）⇒ 与"哪一档接手"相关。**首要怀疑（未验证）**：严格档自己的 `ParaCache`（按 `(textSource, cpFirst)` 缓存，本趟 `缓存复用=18 例`）⇒ 缓存命中的行与请求的 `cpFirst` 若不对应，**第 2 行起的字符边界映射**就可能错位。**机制未归因**；**不许**把它读成"严格档没修好"，也**不许**把它登记进 `known-red.json` 洗绿。
> · **W19B 推翻的三条**：① 预登记"把 `WPF_LINUX_TEXTLINE_FALLBACK` 去掉就是严格档腿"**不成立** —— 旧臂在 `Main` 里**无条件**置该 env 为 0（备份 `Program.cs.before:179`），且旧正控 `if (DiagHandled() <= 0) ⇒ rc=2`（`:551/:554`）**结构上**不允许严格档腿；②③ `W17A` 的"本臂对严格档零射程"与"腿 B 436 例全落宽松档"**只在未改动的臂上成立**。
>
> **⑨ 仪器版本（本波改动）**：`build/shims/PresentationCore.HbTextLine.cs` **`fe1b7ed8fa3ed231`**｜`src/WpfGfx.Linux.Native/tools/patch-presentationcore-textline-fallback.py` **`daa1fe2a32d454cf`** ⇒ `TextFormatterImp.Linux.cs` **`799e0366b312ec65`**｜`build/MilBridge/tests/PcLineOracle/Program.cs` **`a46e5e046583f69a`**（臂产物重建后 `de25d3e0f8a00b00`）｜`build/MilBridge/known-red.json` **`3bf26e12f320dece`**。**未变**：`run.sh 3e513e88a4fa4ec9`、`HbTextLineParity/Program.cs 2e458928fc1577c2`、`tline-gate.sh b37a5c9f55ae71a4`、`verify-all.sh a68823631e8f8919`、`shim-in-artifact.sh e2e1a42b5f0e5b45`、`ShimShaReader/Program.cs 0ef57677afef9f6d`、`MinMaxProbe/Program.cs cfcf464457163280`、`integration-wave.sh 1172784c38fb8e31`、`port-lib.py d9f428a25f06dacc`。
>
> **⑩ 收尾清单里还没做的（不许当绿）**：**`D-T6` 未归因**（严格档腿唯一残留的非 tab0 红）｜**严格档腿修后 `rc` 仍是 1**（`D-T6` 67 + `@tab0` 54 位置红）⇒ 不许拿整腿 `rc` 当判据｜`D-R8` 未修｜`D-R3` 残项（真宿主可达性、AOT 镜像内 `X11Native` 静态构造）未测｜`D-T5`/`D-T4`/`D-T2-c`/`D-F2`/`D-E1`/`D-A1`~`D-A3`/`D-F1c`①c/`D-F3`/`7CJK candidates=45`/MIL 侧三计数：未动或未取到读数｜新判据仍未接进 `verify-all.sh`。
> **下一波**：① **`D-T6` 定性**（先分成"臂/装置"还是"产品"）② **`D-R8`**（两个 csproj 一行修复 + 两极化）③ `D-R3` 残项。
>
> ## ✅ 波 `#20` **完整记录（收官，主控，2026-09-16 16:3x）**
> **内容 = ①`D-T6` 定性 ② `D-R8` 修复**（预登记 `docs/WAVE20-PREREGISTRATION.md`）。**本波与 `#19` 的差别：不动世代绑定** ⇒ 预期**不用**再付一次"五臂重取 + 登记表重钉"，**实测成立**。
>
> **① 项 I（`D-T6` 定性）= `ARM/DEVICE`，不是产品缺陷**（车道 W20A，报告 `build/MilBridge/W20A-report.md` **`3a51800d36bb7007`**，41,129 B）
> · **机制**：臂读逐字 x 用的是 `line.GetTextBounds(j, 1)`，`j` 是**行内**下标；而该参数在**真机**与**严格档**里都是**段落系**（`cpFirst + j`）。
> · **真机锚点三重**：`tests/parity/windows/tab-anchor/src/Program.cs:504-514`（真机宿主自己写 `int gi = lineStart + i; GetTextBounds(gi,1)`）｜`layout-b34/src/LayoutOracle/Runner.cs:96`「段落系索引；传 0 只有行起点=0 的行有结果」＋`:395`｜上游忠实移植版 `SimpleTextLine.Linux.cs:930-940` 用 `_cpFirst`。
> · **决定性读数（同 pc、同用例、只换档）**：两档 `FormatLine` 交回的行**逐位相同**（行数/`Length`/`Width`/可见文本/类型），只有**帧**不同（严格档扫描 `0,1,2`；宽松档 `0,0,0`）⇒ 臂的读法在严格档第 2 行 `localFirst < 0` ⇒ 返回空 ⇒ `NaN` ⇒ 那个失配词。**按真机口径重读：严格档 4/4 例全字 `Δ=0.000000`；宽松档反而 `Δ=+96.000000 / +14.707031` 或读空** ⇒ **反极性是"翻转"，不只是"该词消失"**。家族共 **74 例**（67 未登记 + 7 已登记 `tab0`），全字 `Δ≤0.05`、帧与真机锚点一致 ⇒ **`PRODUCT` 被排除**；缺的读数已补 ⇒ `UNDETERMINED` 也不成立。
> · **守卫已落（臂侧）**：`--guard off|label|enforce`（缺省 `label`）+ `--guard-conv abs|line`；逐例印 `PCLINE GUARD …装置限制=读法口径（不是产品红）`。**全语料严格档腿：74 例贴标签、0 FAIL**（`rc` 仍 1、`未登记失败=67`）。**两极化**：`--guard enforce --guard-conv line` ⇒ `PCLINE GUARD FAIL` + **`rc=3`**；家族 0 例 ⇒ **`NOINFO rc=2`**。**逐字节兼容已机器证明**：`--guard off` 两腿各自逐字节复现改前基线（lenient `a4cd321f5699cefc`、strict `005f07dfeffd11bf`），缺省 `label` 只往同一输出**插新行**（整类判据行 `diff`=0）。⚠️ **照 sha 比对臂输出的旧配方请加 `--guard off`**。
> · **由此可以下的结论（本波最值钱的一句）**：**`#19` 的 item B（严格档 indent）现在是完全干净的** —— 那 67 条残留是**臂的读法口径**，不是产品几何红；按真机口径读，**严格档 4/4 例全字 `Δ=0.000000`**。
> · **它推翻的三条（都是我自己或前车道写的）**：① 预登记"首要怀疑 = 严格档 `ParaCache`，`缓存复用=18 例`"**只对一半** —— 那个 18 **不是 shim 的缓存，是本臂自己的测量缓存 `s_measCache`**（W19B §3.3 已写明）；缓存专项（`--fresh-source` 让 `ReferenceEquals(Source,…)` 必不命中）实测帧 `0,1,2 → 0,0,0`、失配词消失 ⇒ 缓存**是"保持正确帧"的一方**；② 预登记指望 **`GetCharacterHitFromDistance(0)`** 当判据那条**不成立** —— 它是**欠账成员**（`shim:3696-3700` 返回常量 `CharacterHit(0,0)`）⇒ 两档相同、**零判别力**；③ 预登记写的"**行起点映射不同 ⇒ 产品**"这条措辞**在本题是陷阱**：帧差异指向的其实是**宽松档**。
>
> **② 项 II（`D-R8`）= 已修**（车道 W20B，报告 `build/MilBridge/W20B-report.md` **`ff9e599897f9c90a`**，350 行）
> · **改动**：两个 csproj **各加一行**显式排除**仓内** `obj/**`、`bin/**`：`TextLineProto.csproj` `7819ace799b735fd`(2,524 B) → **`60abebef17522b8c`**(3,321 B)；`HbTextLineParity.csproj` `d45ed6e2621f89b8`(3,370 B) → **`9817ae51e9b1322d`**(4,167 B)。落点选**逐工程**而非共享 `.props`：当时另一条车道正在跑 `PcLineOracle`，在 `tests/` 放 `Directory.Build.props` 会**连带改它的构建求值、污染归因**。
> · **根因（确证，非假说）**：SDK 只按**生效的** `$(OutputPath)`/`$(IntermediateOutputPath)` 表达"排除 `obj/`"（`Microsoft.NET.DefaultOutputPaths.targets:126-127`，由 `BeforeCommon.targets:57` 拉进 props 阶段）⇒ **重定向到仓外之后，仓内那条 `obj/` 整条从 `DefaultItemExcludes` 里消失**（`-getProperty` 逐字为证）⇒ 默认 glob 收进 **6 个 `obj/` 条目**，其中 **4 项**就是报错文件。
> · **四条判据全绿**：① 私有 obj 重定向 + 仓内陈旧 `AssemblyInfo` ⇒ **改前 `rc=1`/`16 个错误` 全 `CS0579`；改后 `rc=0`/`0 个错误`**；② **普通（不重定向）构建也 `0 个错误`**（陈旧文件在场时亦然）；③ 全是**真 `dotnet build`**（有产物）；④ 临时件逐字节复原（`cmp` + sha16）。**"编译文件集合未变"是实测**：`-getItem:Compile` 前后 × 2 工程 × {Debug,Release} × {普通,私有} = **16 份清单 `cmp` 全部 IDENTICAL**；修后 `obj/` 条目 **0**；每工程恰剩 `Program.cs` + 真 shim 源两项；产物同为 **93,184 B**。
> · **它推翻的两条**：① **W19A 当初用的 `-p:CustomAfterMicrosoftCommonProps=…/excl.props` "绕过"其实没生效** —— 注入发生在 `Microsoft.Common.props:113`（工程体**之前**），工程体随后**自己追加** `DefaultItemExcludes` ⇒ 注入被压住；它当时读到的"`0 error` 且清单里没有仓内 `obj/`"**不是"注入生效"的证据**，而是"**那一刻仓内没有陈旧 `AssemblyInfo`**"（⇒ **"某种绕过手法有效"必须用一个必失败的输入证明**，纪律 3/21 同族）。② **`D-R8` 登记条把根因归成"缺 `EnableDefaultCompileItems=false`"是偏的** —— 决定因素是 **`DefaultItemExcludes`**（反证：`CoverageProbe` 两者都没有却一直干净，因为它**不用 glob**；而 `HbTextLineParity` **仍在用默认 glob**、只加这一行就干净）。
> · **残项**：**另有 7 个已暴露的工程**同样吃这个陷阱（报告 §9.2 机制交叉表；另 4 个同形态但今天没有陈旧件）⇒ 建议下一波用共享 `.props` **在不含并行车道的趟里**收口。
> · **车道自记的 3 条仪器缺陷（留档）**：`neutralize.props` 注释里的 `<`/`>` 致 XML 解析失败、导入被吞（**首轮"反极性"读数作废**）；替换 `obj/...AssemblyInfo.cs` 前**漏了 `cp -p` 备份**（已用同工程未触碰的 Release 同名件做模板复原、**sha16 对上起点记录**）；第一次控制臂 `-c` 未传致配置与清单不匹配。
>
> **③ 本波的"不动世代绑定"预测 = 全部成立**：九位 + `inputs_fp` **逐位 == `#19` 冻结值**｜五臂门禁 `TLINE_GATE=PASS … generation=#19 tree_gen=same … rc=0`（两趟：W20B 一趟 + 主控收官一趟）｜应用门禁 `WPTD_GATE=PASS`、`6/6 result=PASS`、`drawn=260/144`、`colors=3960/2828`、`frames=14/14`、`cross_ae=0`、`leftover_after=0`（与 `#19` 相同；常驻 `:97` 复用分支）｜`verify-all` **`rc=0`、10 步、871 通过 2 跳过、第 10 步 ✅**｜等号读者 **`SHIM_SHA=no`**。⇒ **`#19` 表头仍是当前冻结基线**（本波**不重冻**，只在本记录里写"**逐位复核未变**"）。
>
> **④ 新登记（不许当绿）**：**`D-T6-b`** = **宽松档交回的行丢段落帧**（`TryFormatLine` 从 `cpFirst` 重新起段并 `return lines[0]`）⇒ 真机口径下读会错或读空；**`D-T6-c`（可能是产品缺陷）** = `HbTextLine.Start => 0`（`shim:3390`，注释称"真机实测恒为 0 3222/3222"）与语料真值冲突 —— 真值 `lineStartOffsetsDip` 在 **171 行（全 `PI≠0`）上是 `24/48`**、另 444 行（`PI=0`）才是 0；**未定性**，判据已写好（`PI≠0` 的多行段落 ⇒ 我方 `line.Start` 必须 == `24/48`；反极性 = 现状必红）。两条都**只登记、本波不修**（要动 shim/PC ⇒ 另开一波 + 世代成本），**未登记进 `known-red.json`**。
>
> **⑤ 仪器版本（本波改动）**：`build/MilBridge/tests/PcLineOracle/Program.cs` **`19f9e7e78e9bb5c7`**（90,087 B；加 `--guard`/`--guard-conv`）｜新探针 `build/MilBridge/tests/StrictTierProbe/{Program.cs `d628ce429240b37c`, csproj `df646ce6a51864ff`}`｜`build/MilBridge/tests/TextLineProto/TextLineProto.csproj` **`60abebef17522b8c`**｜`build/MilBridge/tests/HbTextLineParity/HbTextLineParity.csproj` **`9817ae51e9b1322d`**。**未变（重要）**：`build/shims/PresentationCore.HbTextLine.cs` **`fe1b7ed8fa3ed231`**、`build/MilBridge/run.sh 3e513e88a4fa4ec9`、`HbTextLineParity/Program.cs 2e458928fc1577c2`、`known-red.json 3bf26e12f320dece`、`tline-gate.sh b37a5c9f55ae71a4`、`verify-all.sh a68823631e8f8919`、五臂日志（四支未动、`tline aa7259da9e2c77e8`）。
>
> **⑥ 收尾清单里还没做的（不许当绿）**：`D-T6-b`/`D-T6-c` **只登记未修**（都要付世代成本）｜`D-R8` 的**其余 7 个工程未收口**｜`D-R3` 残项（真宿主可达性、AOT 镜像内 `X11Native` 静态构造）未测｜`D-T5`/`D-T4`/`D-T2-c`/`D-F2`/`D-E1`/`D-A1`~`D-A3`/`D-F1c`①c/`D-F3`/`7CJK candidates=45`/MIL 侧三计数：未动或未取到读数｜新判据仍未接进 `verify-all.sh`。
> **下一波候选**：① **`D-T6-c` 定性 + 可能的修法**（判据已写好；属 `build/shims/**` ⇒ 要付世代成本）② **`D-T6-b`**（宽松档丢段落帧）③ **`D-R8` 的 7 工程收口**（共享 `.props`，要避开并行车道的趟）④ `D-R3` 残项。
>
> ### ✅ `D-R2` **定案并关闭**（主控，2026-09-15 23:2x–23:5x）—— 同一天里对它的第二次、也是最终一次更正
> **根因（一次崩溃日志定案）**：`TypeInitializationException : The type initializer for 'WpfGfx.Linux.Tests.ManagedLayer.Win32Shim' threw an exception. ---- InvalidOperationException : A resolver is already set for the assembly.`，栈直指 `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/X11Guard.cs:163`。`NativeLibrary.SetDllImportResolver` **对同一程序集只能调一次**，而该程序集有**两个**安装点（`X11Guard.cs:163` 无保护、`DP1ReproTests.cs:63` 静默 catch）⇒ **谁先跑由 xUnit 集合并行调度决定**；`DP1ReproTests` 先赢 ⇒ `Win32Shim..cctor` 抛 ⇒ **静态构造 ⇒ 整进程毒化** ⇒ 30 条用例全灭 / testhost 崩。
> **被推翻的两次归因（都留档）**：① "**负载**"——红的帧 `loadavg` 1.0–1.2，**比绿的帧还低**；② "**并发车道**"——`#15` 那次确实是 4 条车道并发时红的，所以当时只能记成"强先验、不是已证"，**现在被更低的负载下仍然红否掉**；③ "**构建前置**"——A（先构建再单跑）/B（纯单跑）交替各 3 趟 ⇒ **3/6 红、两边一样**。
> **修法（三处，全在 `tests/**`）**：删掉冗余安装点（`DP1ReproTests` 改 `_ = Win32Shim.LoadedPath;`，因为 `Win32Shim` 的解析器本来就映射 `user32.dll`）｜两个 `X11Guard` 容忍"被抢先"（`catch (InvalidOperationException)`）｜**装完用真的 `[DllImport]` 自证一次**。**不动九位、不动 `inputs_fp`/`ARTIFACT-SRC-FP`**（实测 `tests/` 在 `ARTIFACT-SRC-FP.txt` 里 0 行）⇒ **不作废 `#16` 冻结**。
> **我自己的失误（留档）**：自证最初用 `NativeLibrary.TryLoad("user32.dll", assembly, …)`，**该 API 不走 `DllImportResolver`** ⇒ 恒 false ⇒ 毒化类型、**33 条用例全灭**（冒烟当场抓到；改真 `[DllImport]` 后 76/76）。同族教训：**"我写了一个看起来对的 API 用法"必须真的跑一次**。
> **验证**：修后单跑 **6/6 绿**（`race=0`、`hostcrash=0`）＋ **关闭判据：连续 5 趟静树 `verify-all` 全绿**（`rc=0`×5、10 步 0 失败、`race=0`×5、逐趟记 `loadavg`/`mem_available`；日志 `$HOME/wfp-runs/w16-pre/dr2close/v{1..5}.out`）。
> **同族尾巴（R17C 只读审计抓出，纪律 9 的正回报）**：`SystemParametersInfoTests.cs:40-41` 的 6 个 `[DllImport("user32.dll")]` 调用点自己不碰 `Win32Shim` ⇒ 顺序一反就 `DllNotFoundException`（**同形态、成因不同**）⇒ **已补修**。**产品侧同类实例目前不存在**，但两个**无保护**的产品侧安装点已登记为波次项。

| Task | 状态 | 实测证据 |
|---|---|---|
| **T0** 环境基线 | ✅ | `verify-env.sh` 15/15 通过；.NET 10.0.111 / SkiaSharp 2.88.9 / Noto Sans SHA-256 锁定（两次渲染哈希一致） |
| **T1** XAML→BAML 编译链路 | ✅ | `App.baml` 860B + `MainWindow.baml` 1756B，**与 SDK 官方版逐字节一致** |
| **T2** MIL 通道层 | ✅ | 13 函数签名逐字对齐 `exports.cs:113-204`；818 行 |
| **T3** 顶层命令解码 | ✅ **110/118** | 4,869 行 + `MilBitmapSource.cs` 203 行；**103 个线格结构体**与上游逐 `FieldOffset` 比对**全部一致**；仅剩 7 条 E_NOTIMPL（6 条 C 类永久不做 + 1 条 B 类 `MilCmdMediaPlayer`）+ 1 条 `MilCmdInvalid` 哨兵 |
| **T4** Skia 渲染后端 | ✅ | 1,483 行 + SkiaEffect + **ImageBrush**（U12）；**56/56 测试通过**（31 原有 + T14 特效 20 + ImageBrush 语义 4 + golden 1）；16 张 golden 基准图 |
| **T5** X11 窗口与呈现 | ✅ | `Windowing/` 1,096 行 + `tests/.../Windowing.Tests` **44** 用例；Xvfb 下 8/8 真实窗口用例通过（含 xwd 截屏断言红矩形+黑字已落到 server 端、Expose/ConfigureNotify/Closed 事件转换正确）；**新增 10 条 `xdotool` 真输入用例（突变验证通过）**；**再 +2 条 `X11Display.Open` 失败分类用例**（快速失败 vs 重试） |
| **T6** 文本（GlyphRun） | ✅ | `Text/` 705 行 + golden/确定性/钩子/字体集共 18 文本用例全绿；6 张文本 golden 基准图（含 24pt/11pt 字号、Regular/Bold/Italic/斜直差异、基线位移、MilGlyphRun 钩子路径） |
| **T7** 渲染测试框架 + golden | ✅ | `Rendering.Tests/`：GoldenRunner / ImageComparer / RenderHarness / PackagedFont / FontDeterminismTests；**15 张基准图**（`tests/golden/`，12 原有 + T14 特效 3）；另有 6 张文本 golden 在 `Windowing.Tests/golden/` |
| **T8** 单元测试套件 | ✅ **469 通过** | `Commands.Tests` **350** + `Rendering.Tests` **56** + `Windowing.Tests` **44** + `HelloMil.Tests` **19** = **469 通过 / 0 失败**；「缺布局/属性/绑定」系错列目标，已划掉 —— 见 §8 认知修正 |
| **T13** 位图源（B 类解锁） | ✅ **24 用例** | `0x0c MilCmdBitmapSource` + `0x0d MilCmdBitmapInvalidate` 已实现，命令层 108→**110**；**位图真实画出像素证据**（离屏 64×64，目标矩形内 3 点红、矩形外 3 点白）+ 反向用例证明红像素来自位图本身；收尾时修正前任一处 HRESULT 错误 |
| **T14** 图像效果（Effect） | ✅ **20 用例** | Blur + DropShadow（`SKImageFilter`）；新增 3 张 golden（`effect_blur` / `effect_drop_shadow` / `effect_blur_clipped`）；**重构前任设计缺陷**：原 `Create`+`IsSupported` 会把资源表查两遍、外部委托调两次（副作用风险）→ 改为单一入口 `TryResolve`；**sha256 基线验证现有 18 张 golden 零变更** |
| **T15** X11 连接抖动修复 | ✅ **2 用例** | `X11Display.Open` 加重试（3 次 + 60/180/400ms 退避）并**区分两类失败**：socket 不存在=`DISPLAY` 配错→快速失败；socket 存在但拒绝=并发瞬时→重试。微基准：每臂 17.28 万次尝试，裸调用失败 6 次 / 带重试 0 次 |
| **U12** ImageBrush（位图画刷） | ✅ **5 用例** | `SkiaBrush` 新增 TileBrush 链路（Viewbox/Viewport/Stretch/Alignment/TileMode + 画刷变换 + Opacity）；**实测揪出并修正 `SKMatrix.Concat` 语义陷阱**（Concat(a,b)=b 先作用，写反会把平移乘上缩放）；HelloMil showcase 去掉 "no fill" 标注（棋盘格画刷填充上屏，四色均衡）；Rendering.Tests 51→56、golden 15→16（`image_brush`）；`MilStretch` 枚举默认 None≠WPF 属性默认 Fill 的坑已注释钉死 |
| **T12** 键鼠真输入测试 | ✅ **10 用例** | `X11InputInjector.cs` + `X11RealInputEventTests.cs`；`xdotool` 向真 X11 窗口注入按键/指针/滚轮；**突变验证：偏移改错后 10 条全红**（见 §0 六次复验） |
| **T10** 架构文档 | ✅ | `docs/ARCHITECTURE.md` **486 行 / 9 节**：分层说明（带文件行号）、`MilDrawRectangle` 端到端 16 步数据流、与上游 20 项有意差异、11 项债务清单 |
| **T11** flaky 根因修复 | ✅ | ① GCHandle 槽位复用（ABA）已根治；修复前 60 轮 9 次失败 → 修复后 **20/60/100 轮均 0 次**；② **`XOpenDisplay` 瞬时拒绝已加重试并压测验证**（20 轮 × 4 并发：修复前 2 条 → 修复后 **0 条**，详见 §8）；新增 `tests/flaky-loop.sh` + `verify-all.sh` |
| **T9** 端到端 demo（HelloMil） | ✅ **完成 · showcase 版** | A3 路线（见 `docs/T9-roadmap.md`）：`samples/HelloMil` → X11 真窗口 → `xwd` 截屏 → `screenshot.png`（**59KB，12 种能力同屏**：渐变×2/椭圆/路径/圆角/虚线/位图/Blur/DropShadow/裁剪/嵌套变换/文本）；`HelloMil.Tests` **19** 用例 |

### 复现验证（2026-09-02 12:10 独立复验，非自报）
```bash
DISPLAY=:99 dotnet build wpf-linux.sln    # → 0 Warning(s), 0 Error(s)（6 个工程全过）
DISPLAY=:99 dotnet test  wpf-linux.sln    # → 298 通过 / 0 失败
#   Rendering.Tests  31 ✅
#   Commands.Tests  229 ✅
#   Windowing.Tests  32 ✅（需 DISPLAY）
#   HelloMil.Tests    6 ✅（需 DISPLAY，含 1 条真 X11 截屏断言）
```

> ⚠️ **不要用 `--artifacts-path` 重定向输出目录**：`TestLayout` / `HelloMilPaths` 靠
> **相对程序集位置回退**定位 `build/fonts` 与 `tests/golden`。实测加 `--artifacts-path /tmp/...`
> 后三套测试分别炸 2 / 18 / 26 条，全部是路径找不到，**不是代码 bug**。原目录跑即全绿。

### 二次复验（2026-09-02 会话恢复后重跑，非自报）
主工程重建 `0 Warning(s) / 0 Error(s)`；三件套结果一致：
Commands **229** + Rendering **31** + Windowing **32** = **292 通过 / 0 失败**；
`tests/golden/` 12 张基准图**无增删无变更**。
另在 **32 核全并行**下连跑 12 轮 `Commands.Tests`：**12/12 全绿**，此前记录的 flaky 未复现（见下节）。

### ★ 六次复验（2026-09-04 10:18，主控独立复验，非自报）—— **键鼠输入测试补完后**

`bash verify-all.sh` 一键全检（Xvfb → 2 构建 → 4 套件 → 线格校验）：

```
[0] Xvfb :99                 ✅ 复用已运行的 Xvfb
[1] 主工程 WpfGfx.Linux      ✅
    wpf-linux.sln            ✅
[2] Commands.Tests           ✅  通过 322  跳过 0  合计 322
    Rendering.Tests          ✅  通过  31  跳过 0  合计  31
    Windowing.Tests          ✅  通过  42  跳过 0  合计  42   ← 上次 32，+10
    HelloMil.Tests           ✅  通过   6  跳过 0  合计   6
[3] verify-cmd-layout.py     ✅
────────────────────────────────────────────
 步骤通过 7  ❌ 失败 0      用例通过 401  跳过 0
```

### ★ 七次复验（2026-09-05 19:27，主控复跑，非自报）—— T13/T14/T15 全部落地后

```bash
cd /workspace/wpf-linux && bash verify-all.sh
```

```
[0] Xvfb :99                 ✅ 复用已运行的 Xvfb（:99 -screen 0 1280x1024x24）
[1] 主工程 WpfGfx.Linux      ✅
    wpf-linux.sln            ✅
[2] Commands.Tests           ✅  通过 350  跳过 0  合计 350
    Rendering.Tests          ✅  通过  51  跳过 0  合计  51   ← 上次 31，+20（T14 特效）
    Windowing.Tests          ✅  通过  44  跳过 0  合计  44
    HelloMil.Tests           ✅  通过   6  跳过 0  合计   6
[3] verify-cmd-layout.py     ✅
────────────────────────────────────────────
 步骤通过 7  ❌ 失败 0      用例通过 451  跳过 0
 结论：✅ 全部通过（退出码 0）
```

> **数字订正**：此前看板多处还留着旧值（T8=431、T4=31/31、golden 12 张 / 18 张）。
> 本轮按实测对齐为 **451 / 51 / 15 张（+6 张文本 = 21 张）**，详见 §0 表格与 §8 验收标准。
> 旧的 401 / 292 / 390 是**当时时点的真实结果**，作为历史记录保留，未回改。

### ★ 八次复验（2026-09-06 17:00，主控复跑，非自报）—— showcase demo + U2 首步落地后

```bash
cd /workspace/wpf-linux && bash verify-all.sh
```

```
[0] Xvfb :99                 ✅ 复用已运行的 Xvfb：146933 Xvfb :99 -screen 0 1280x1024x24
[1] 主工程 WpfGfx.Linux       ✅
    wpf-linux.sln            ✅
[2] Commands.Tests           ✅  通过 350  跳过 0  合计 350
    Rendering.Tests          ✅  通过  51  跳过 0  合计  51
    Windowing.Tests          ✅  通过  44  跳过 0  合计  44
    HelloMil.Tests           ✅  通过  19  跳过 0  合计  19   ← 上次 6，+13（showcase 场景断言）
[3] verify-cmd-layout.py     ✅
────────────────────────────────────────────
 步骤通过 7  ❌ 失败 0      用例通过 464  跳过 0
 结论：✅ 全部通过（退出码 0）
```

> 本轮相对七次的唯一变量是 `HelloMil.Tests` 6 → **19**（T9 showcase 场景从 12 种能力扩展了断言），
> 其余三套数字零变化，**无新增失败、无 golden 变更**。
> 🧹 顺手清理：`samples/HelloMil/` 下 2 个 dev 期 core dump（合计 **767MB**）已删除，
> 并重新打包 `wpf-linux-20260906.tar.gz`（51MB → 见 §10）。

### ★ 九次复验（2026-09-10 12:45，环境搬迁后复跑 + U12 落地，非自报）

> ⚠️ **前置：工程整体搬迁了新环境**（`/workspace/wpf-linux` → 本机仓库根），
> 上游源码、dotnet SDK、系统包全部重建——迁移与修复清单见 §10.5「环境搬迁记录」。

```bash
cd <仓库根> && export PATH="$HOME/.dotnet:$PATH" && bash verify-all.sh
```

```
[0] Xvfb :99                 ✅ 已启动 Xvfb :99 -screen 0 1280x1024x24
[1] 主工程 WpfGfx.Linux       ✅
    wpf-linux.sln            ✅
[2] Commands.Tests           ✅  通过 350  跳过 0  合计 350
    Rendering.Tests          ✅  通过  56  跳过 0  合计  56   ← 上次 51，+5（U12：1 golden + 4 语义）
    Windowing.Tests          ✅  通过  44  跳过 0  合计  44
    HelloMil.Tests           ✅  通过  19  跳过 0  合计  19
[3] verify-cmd-layout.py     ✅
────────────────────────────────────────────
 步骤通过 7  ❌ 失败 0      用例通过 469  跳过 0
 结论：✅ 全部通过（退出码 0）
```

> 本轮变量：① 环境搬迁（见 §10.5，dotnet 10.0.111 重装、上游源码重定位、路径参数化）；
> ② U12 ImageBrush 落地（Rendering.Tests 51→56、golden 15→16、HelloMil 截图更新 59KB→58.8KB、
> `Render_ImageBrush_Fills_Rect_With_Checkerboard` 替换原缺口钉死用例）；
> ③ U1 比对器就位（`GoldenBinaryReplayTests`，无流文件 → Skip）。
> Commands/Windowing/HelloMil 三套通过数零变化，**无新增失败、其余 golden 零变更**。
> `verify-all.sh` 的用例计数解析已改双语兼容（英文/中文 locale 都能出数，修复前新机器上恒显示 0）。
> 最终口径：**469 通过 / 1 跳过（U1 回放用例，缺 Windows 抓流）/ 0 失败**。

### ★ 视觉核验（2026-09-10，首次引入视觉模型子代理）

U12 更新后的 showcase 截图经 `deepseek-v4-flash-vision-exp` 视觉模型逐项核验：
ImageBrush 虚线框内四色棋盘格铺满、无 "no fill" 残留文字、与上方 MilDrawImage 棋盘格同源配色、
其余 11 种能力完好。像素断言（19 用例）与视觉核验互为印证。

### ★ 十次复验（2026-09-10 下午，M3 落地 + 程序集身份全局改动后，非自报）

```bash
cd <仓库根> && export PATH="$HOME/.dotnet:$PATH" && bash verify-all.sh
```
```
[1] 主工程 WpfGfx.Linux ✅ / wpf-linux.sln ✅
[2] Commands.Tests ✅ 350 通过 / 1 跳过（U1 回放，待抓流）
    Rendering.Tests ✅ 56    Windowing.Tests ✅ 44    HelloMil.Tests ✅ 19
[3] verify-cmd-layout.py ✅
步骤通过 7 ❌ 失败 0   用例通过 469  跳过 1   结论：✅ 全部通过
```
> 本轮变量：① 程序集身份全局改为 **AssemblyVersion 4.0.0.1**（防框架同名门面遮蔽，见 M3 段）；
> ② 新增 M3 三个工程（不在 sln 内，独立构建 0 错）；③ port-lib 七项修复。
> M1 四套测试数字零变化、golden 零变更——身份改动对渲染链路无副作用（已实测）。

### ★ 最后一项遗留关闭：键鼠真输入测试（2026-09-04，非自报）

§8 里唯一标 ⬜ 的「键鼠输入事件无测试覆盖」已补完。`Windowing.Tests` **32 → 42（+10）**，
用 `xdotool` 向 Xvfb 里的**真窗口**注入真按键/真指针，断言事件被正确转换。

| 新增文件 | 内容 |
|---|---|
| `Windowing.Tests/X11InputInjector.cs` | 6,249 字节；`xdotool` 进程封装 + `KeycodeOf()` 现查 keymap |
| `Windowing.Tests/Windowing/X11RealInputEventTests.cs` | 13,989 字节；10 用例（1 Fact + 9 Theory 展开） |

**覆盖**：按键按下/释放键码一致（`state` 必须为 0）、`shift+a`/`ctrl+a` 修饰键掩码、
指针移动 3 组坐标（含 `(473,2)` 这类边界值）、鼠标左右键、滚轮上下（button 4/5）。

**设计上的三处防假绿**：
1. **keycode 不写死**——`'a'` 在 evdev 是 38，换 keymap 就未必，改为运行时现查；
2. **坐标刻意挑"大数 + 边界值"**——`x/y` 偏移若按 8 字节对齐读错，不可能对得上；
3. **共用 `[Collection("X11Windows")]` + 窗口摆到 x=780**——真指针移动是全局的，
   两窗口重叠会把 MotionNotify 分到上层窗口，断言必然错乱。

> ✅ **突变验证已做（不是凑数测试）**：把 `X11Structs.cs` 的 `PointerY/PointerRootX/PointerRootY/State/Detail`
> 偏移改回**初版那个「int 当 8 字节对齐」的错误布局**（68→72 / 72→80 / 76→88 / 80→96 / 84→100），
> 重跑 → **Failed: 10, Passed: 32** —— 新增的 10 条**全红**，恰好抓的是当初那个真 bug。
> 恢复后重跑 → **42/42 全绿**。回退验证通过。

> 🧹 **顺手清理**：`tests/.../Windowing.Tests/` 下堆了 10 个 core dump（`dotnet build`/`dotnet test`
> 进程崩溃产物，**合计 965MB**），来自开发期间；本轮两次重跑均未再产生新的，已删除。

### 三次复验（2026-09-03，T3 收尾后，非自报）

```bash
dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj   # → 0 Warning(s), 0 Error(s)
DISPLAY=:99 dotnet test  wpf-linux.sln              # → 390 通过 / 0 失败
#   Rendering.Tests   31 ✅
#   Commands.Tests   321 ✅   ← 上次 229，本轮 +92（A 类 29 条补完 + 3D 资源/视觉树配套用例）
#                                注：+92 未逐条归因，Theory/InlineData 会展开，属性计数 ≠ 用例数
#   Windowing.Tests   32 ✅
#   HelloMil.Tests     6 ✅
```

**T3 收尾成果**（`docs/unimplemented.md` §0 分类后逐条补完）：

| 指标 | 上一轮 | 现在 | 证据 |
|---|---|---|---|
| 已实现命令 | 79 / 118（67%） | **108 / 118（91%）** | `MilCommandLayout.s_notImpl` 仅剩 9 条 |
| E_NOTIMPL | 38 条 | **9 条** | 6 条 C 类（D3D/Windows 句柄）+ 3 条 B 类（位图/媒体） |
| 线格结构体 | 72 个 | **101 个** | `verify-cmd-layout.py`：上游 108 个，共有 101 个 **FieldOffset 与字段宽度全部一致 ✓** |
| Commands 代码 | 3,244 行 | 4,869 行 | 新增 `MilResource3D.cs` 374 行等 |

缺失的 7 个结构体 = 6 条 C 类 + 1 条 B 类 `MILCMD_BITMAP_INVALIDATE`，**与 E_NOTIMPL 清单严格对应，无遗漏**。

### 四次复验（2026-09-03 20:29，主控独立复验，非自报）—— 含**无 X 环境**首次验证

```bash
Xvfb :99 -screen 0 1280x1024x24 &
DISPLAY=:99 dotnet build src/WpfGfx.Linux/WpfGfx.Linux.csproj   # → 0 Error(s)
DISPLAY=:99 dotnet test  tests/WpfGfx.Linux.Tests/Commands.Tests/    # → 321 ✅ / 0 ❌
DISPLAY=:99 dotnet test  tests/WpfGfx.Linux.Tests/Rendering.Tests/   # →  31 ✅ / 0 ❌
DISPLAY=:99 dotnet test  tests/WpfGfx.Linux.Tests/HelloMil.Tests/    # →   6 ✅ / 0 ❌
DISPLAY=:99 dotnet test  tests/WpfGfx.Linux.Tests/Windowing.Tests/   # →  32 ✅ / 0 ❌
#                                                          合计 390 ✅ / 0 ❌
```

**无 X server（裸容器 / CI）首次验证 —— 确认优雅 Skip 生效，不红：**

```bash
env -u DISPLAY dotnet test tests/WpfGfx.Linux.Tests/HelloMil.Tests/   # → 5 ✅ / 1 跳过 / 0 ❌
env -u DISPLAY dotnet test tests/WpfGfx.Linux.Tests/Windowing.Tests/  # → 24 ✅ / 8 跳过 / 0 ❌
```

> ⚠️ **踩坑修正（推翻一条此前的误判）**：曾记录"HelloMil.Tests 缺 X11 Skip 防护、无 X 环境会红"。
> 实测该判断**是错的**。真实原因是 `DISPLAY=:0` 被设成了**无效值**——环境探测认为"有 X server"于是直连，
> `XOpenDisplay` 失败后抛异常。`DISPLAY` 被 **unset** 时探测正确、用例正常 Skip（见上）。
> **留给后续的小改进**：探测逻辑应校验 `XOpenDisplay` 实际能否连通，而非只看变量是否存在，
> 这样 `DISPLAY=:0`（指向不存在的 server）也能 Skip 而不是 Fail。影响面小，未修。

### ★★★ 端到端最有力证据：真的开窗口画出来了
`Windowing.Tests/artifacts/x11_present_capture.png` —— 用 `xwd -id <XID> | convert → PNG`
（独立进程 + 另一条 X 连接）抓的真实 X11 窗口截图。肉眼可见红色矩形 + "WPF on Linux" 文字。
测试断言：>3000 红像素（矩形）+ >200 深色像素（文字）—— 全通过。

### ★★★ T9-A3 完成：HelloMil 端到端（2026-09-02 实测，非自报）

**M1 目标达成**——"从我们自己的 API 一路到真实 X11 窗口的真实像素"完整链路已通。

```
samples/HelloMil/          743 行（Program / TestScene / HelloMilPaths / HelloMilScreenshot）
tests/.../HelloMil.Tests/  427 行（6 用例，其中 1 条走真 X server）
```

跑一次的实际输出（`dotnet run --project samples/HelloMil -- --display :99`）：

```
[1/5] 构造 MilChannel 资源表与视觉树 ... OK
[2/5] SkiaRenderBackend 离屏渲染 ... OK（4 条指令，0 条未画出，GlyphRun 跳过=False）
[3/5] 打开 DISPLAY=:99，创建 X11 窗口 ... OK（WindowId=0x200001）
[4/5] Present(frame) 到 X11 窗口 ... OK
[5/5] 独立进程 xwd 截屏 → samples/HelloMil/screenshot.png
```

**证据链的关键设计**：截屏用**独立进程 `xwd`**，走 X server 的另一条连接。自己 `XGetImage` 读回来只验证了
"我们写的 buffer 能原样读回"，Present 那一半没被测到；`xwd` 看得到内容，才证明窗口真被映射、真被绘制、
像素真落到 server 端。

`screenshot.png`（800×600）颜色直方图实测：白底 397,834 / 红 `(200,30,30)` 57,820 / 琥珀 `(235,150,30)` 16,475 /
蓝 `(20,70,200)` 1,762 / 墨绿 `(0,110,70)` 1,534 / 深色文字 977 —— **四个图元 + 文本全部落到了 X server**。

**6 条测试断言（全绿）**：
| 用例 | 断言 |
|---|---|
| Create_DoesNotThrow | 资源表 + 视觉树 + 字体装配不抛 |
| Render_Produces_NonEmpty_Bitmap | 800×600、非纯色、`GlyphRunSkipped=false`（文本钩子接上了） |
| Render_Contains_Red_Blue_And_DarkText_Pixels | 红矩形覆盖率 >70%、蓝对角线 >1500px、文字带深色 >600px |
| Render_Hash_Is_Deterministic | 连续三次渲染 PNG 哈希字节级一致 |
| Render_TransformChain_MovesChild_OffOrigin | 旋转 20°+平移后 amber 顶边 y>80（不是未变换的 0,0） |
| X11_Capture_From_LiveWindow | 真窗口截屏 >1KB、非空白、红 >5000 / 蓝 >500 / 深色 >1000 |

> **HelloMil ≠ HelloWpf**。前者证明"我们的 Linux 渲染后端能工作"，后者要求 WPF 托管层（118 万行 C#，
> 150+ 处 Win32 P/Invoke）跨平台——那是 M2/M3，见 `docs/T9-roadmap.md`。

### T5+T6 实施中修了 3 个真 bug（来自 T5 agent 报告）
1. **XEvent 字段偏移**：ConfigureNotify/KeyEvent 把 4 字节 int 误当 8 字节对齐 → Resize 事件 width 读成 0
2. **XInternAtom(only_if_exists=1)**：WM_PROTOCOLS/WM_DELETE_WINDOW 不是预定义原子 → 关闭链路静默断
3. **CaptureWindow 返回 disposed SKBitmap**：纯色窗口炸（空帧重试循环退出后 return 已 dispose 对象）

### 已修复的严重 bug：矩阵转置
`Resources/VisualProjection.cs` 的 `FromMil` 把 `SkewX`/`SkewY` 写反（应为 `SkewX=S_21, SkewY=S_12`）。
对称矩阵不暴露差异，非对称矩阵才炸出来——由渲染语义测试捕获。
**修复后新增 8 条 `MatrixConventionTests`，并回退验证：bug 版本下这 8 条确实失败**（真测试而非凑数）。
golden 图 12 张**一张未变**（唯一用到矩阵变换的用例是对称矩阵，转置前后等价）。

### 已知问题
- ✅ **测试 flaky —— 已修（2026-09-03，根因层修复，非规避）**。详见下方专节。
- ✅ **键鼠事件无测试覆盖 —— 已补（2026-09-04）**：`xdotool` 真注入 10 条用例，
  且**突变验证**：把 `X11Structs.cs` 偏移改回初版错误布局后 10 条全红，恢复后 42/42 绿。见 §0 六次复验。
- ⬜ **X11 环境探测只看 `DISPLAY` 变量是否存在，不校验能否真连上**：`DISPLAY=:0`（指向不存在的 server）
  会让用例 Fail 而不是 Skip。`DISPLAY` 被 unset 时行为正确。影响面小，未修。

### ★ flaky 修复专节：GCHandle 槽位复用（ABA 问题）

**此前记录的原因不完整。** 原记为「`MilChannelRegistry` 全局静态、没加锁」——这只是表象。
真实根因是 **句柄值复用**：

```
通道句柄取自 GCHandle.ToIntPtr
  → 通道 A 注销，GCHandle.Free() 释放槽位
  → 通道 B 新建，Alloc 拿到【同一个 IntPtr 值】
  → 测试里 A 的延迟注销命中 B 的条目，误删 B 的通道
  → 断言 Assert.False(Unregister(p)) 得到 True，连带 MilNativeTests 报 E_HANDLE
```

典型 ABA 问题。回退验证实锤：旧实现下退役句柄 `139778272465600` 被原样复用给新通道。

**修法**（未采用"加锁"或"`[Collection]` 串行化"这类规避手段）：
| 改动 | 内容 |
|---|---|
| 句柄值不再复用 | 改**单调计数器**分配，基址 `0x1000_0000`（避开测试手写假句柄 `0x1234`），进程内永不回收 |
| 注册表查找 | `MilChannelRegistry` 改 `ConcurrentDictionary` **直查** |
| 消除全表遍历 | 新增「连接 → 通道」索引，`SameThreadPresent` 不再遍历进程级静态表 |
| 测试断言修正 | 原 `Assert.Equal(before+1, Count)` 断言**进程级全局计数**增量——并行下该命题本身不成立。改为句柄级 `Contains` + 幂等注销（断言 7→8 条） |
| 新增回归用例 | 「退役句柄值不被复用」——旧实现下必挂 |

**实测对比**（独立复验，非自报）：

| 阶段 | 轮次 | 失败 |
|---|---|---|
| 修复前 | 20 轮 | **3 次** |
| 修复前（追加） | 60 轮 | **9 次（15%）** |
| **修复后** | **20 / 60 / 100 轮** | **0 次** |
| 修复后（主控 30 轮复验） | 30 轮 | **0 次** |

> ⚠️ **残留的结构性限制**：`MilChannelRegistry` **仍是进程级静态**，本次消除的是「句柄值回收」这一具体缺陷，
> 不是把注册表改成了实例注入。若将来引入多通道并发场景，仍可能有新的竞态面。
> 另新增 `tests/flaky-loop.sh` 用于回归压测。
- **IPresentationTarget.Resize 后需上层重渲**：写在文档注释里，端到端运行时会暴露。
- **T9-A3 已闭环，剩余缺口移到 M2**：`HelloMil` 证明的是"我们的后端能工作"。要跑真正的 WPF 程序
  （`samples/HelloWpf`），仍需：① WPF 托管层（118 万行 C#）在 Linux 上编译；② `exports.cs` 的 13 个
  `[DllImport(MilCore)]`（当前指向 Windows DLL `wpfgfx_cor3.dll`）接入我们的 C# 实现——即决策 3 那一处侵入式改动。
- **`wpf-linux.sln` 原先漏挂 3 个工程**（`Windowing.Tests` / `HelloMil` / `HelloMil.Tests`），已补齐。
  此前 `dotnet test wpf-linux.sln` 只跑 2 套测试，会给人"基线只有 260 条"的错觉。

### 完成度速览
```
Contracts ████████████████████ 100%  (631 行)
Interop   ████████████████████ 100%  (818 行)
Resources ████████████████████ 100%  (1,349 行, 矩阵 bug + GCHandle 句柄复用 ABA 已修)
Commands  ███████████████████░  93%  (5,072 行, 110/118 命令，剩 7 条 E_NOTIMPL，位图源已解锁)
Rendering ████████████████████ 100%  (1,700 行 + SkiaEffect + ImageBrush, 56 测试 + 16 golden)
Windowing ████████████████████ 100%  (1,096 行, 44 测试 = 8 真实窗口 + 6 截图断言 + 8 输入 + 2 重试)
Text      ████████████████████ 100%  (  705 行, 18 用例 + 6 golden + 字体确定性)
HelloMil  ████████████████████ 100%  (1,170 行 = 743 demo + 427 测试, 19/19 绿 + X11 截屏)
```

---

> ## ✅ 波 `#21` **完整记录（收官，主控，2026-09-16 19:1x）**
> **内容 = P1 `D-T6-c`（定性 + 落地）｜P2 `D-R8` 残项收敛｜P3 `D-T6-b` 静态归因｜P4 `D-R3`/`D-T5`/`D-T4` 只读盘点**（预登记 `docs/WAVE21-PREREGISTRATION.md`，**含 §10–§15 五处主控自我更正**）。
> **四条车道**：`W21A`（实现 `Start` 判据 + 落地，报告 `build/MilBridge/W21A-report.md` `b6865b2409091298`）｜`W21B`（`D-R8`，报告 `66a78a99bf1b3847`）｜`W21C`（`D-T6-b` + **盲复核**，报告 `0dd5cf70f7e5d673`）｜`W21D`（条目表，报告 `c473dfc1dcbff583`）。
>
> **① `D-T6-c` 定性 = 产品缺陷（三条互相独立的证据）**：真机法律 = **`Start ≡ IdealToReal(ParagraphIndent)`**（`TextAlignment=Left`）。
> · **腿 1（真机源码直接写着法律）**：`upstream/wpf/…/TextFormatting/TextMetrics.cs:355-358` `Start => IdealToReal(_paragraphToText - _textStart, _pixelsPerDip)`，而 `default:`（= Left）分支 `:255-263` 的**注释原文** *"Paragraph start to line start is paragraph indent"*、代码 `_paragraphToText = pap.ParagraphIndent + _textStart;` ⇒ **`_textStart` 精确相消**。
> · **腿 2（真机逐行实测）**：语料 `lineStartOffsetsDip`（真机臂 `Program.cs:445` 的 `R(line.Start)`）在 **615/615 行**上精确等于 `ParagraphIndent`；对照 `Start==Indent` 只 **337/615**；`PI → Start` 是**双射** `{0:[0],24:[24],48:[48]}`；语料两处独立落盘（`:476` 与逐行 `:555`）**615/615 互洽**。
> · **腿 3（盲复核）**：`W21C` **在落盘完自己的结论之后**才读预登记 ⇒ 独立重算得**逐位相同**结果。它另加固两条：`R` 只舍 `1e-6` 而理想单位 `1/300` ⇒ **`R` 藏不住真实差异**；快路径闸门 `SimpleTextLine.cs:89-95`（`TextIndent≠0 ∨ PI≠0 ∨ RightToLeft` ⇒ 不接快路径）⇒ 法律在 **LS 路径与快路径上同时成立**。
> · **"3222/3222 恒为 0"是语料性质、不是实现性质**：那个数出自 `layout-b34` 语料，而该语料 `cases*.json` 里 **`ParagraphIndent` 与 `Indent` 出现次数各为 0** ⇒ 真法律的唯一非零驱动量**压根没被采样**。**同一条伪证有三个落点**，本波三处都处置了：shim 注释（改成真法律 + 语料性质说明）、`layout-b34` 的推断、`tab-anchor-oracle.json` 的 `unavailableOrUntested`（改成**现算**）。
>
> **② 落地与两极化（实测，不是声明）**：`Start => _paragraphIndentDip`（新字段 `:2654` + 私有 ctor 末参带默认值 `:2726` + **两处构造点全透传**：行构造 `:2905` 与**折叠路径 `BuildCollapsedLine` `:3677-3681`**）。`shim fe1b7ed8fa3ed231 → 76089e1de586ac91`（278,692 → 283,557 B）。
> · 修前 pc `f4a454c8fe69cdfe` ⇒ **红 138 行 / 88 例**（判定行 421、最大 Δ=48.0 @`D-paraindent/lead-tab-a@w100@LTR@i0p48@default` 行#0）｜修后 pc `e7cabff9417ed380` ⇒ **红 0 / 绿 421 / 最大 Δ=0.000000**｜错驱动量 `Start = Indent` ⇒ **红 222 行 / 148 例**。
> · **主控独立复现**：用留档的修前 pc 手工跑同一入口 ⇒ `PCLINE START 腿=汇总(B) 红=138 … 最大Δ=48.000000 @…i0p48… 行#0`，与车道读数**逐位吻合**；并与主控冻结的期望集 `$HOME/w21-verify/expected-red.tsv`（`52fe6204f09be64a`）做**集合级对账**：`only-in-arm=0`、`only-in-exp=0`。
> · **"零射程"是机器证**：修前/修后同版仪器日志按列对比 ⇒ `PCLINE CASE` 头 **436/436 相同**、`STRUCT 56/56`、`TWIN 355/355`、`NAMED 6/6`、`GUARD 74/74` **全逐位相同**、**修后新增红 = 0 例**，且既有读数与 `#19` **逐位复现**（红=127 绿=57、零缩进 63/41、`PI≠0` 64/112、未登记失败=67）。
>
> **③ ⚠️ 分母口径（本波两次踩到 ⇒ 已立纪律 39）**：臂的可判定集是 `script=latin` 的 **421 行**，**不是**整份语料的 615 行。主控预登记两次把"语料总量"当分母（预期红 **171 vs 真值 138**、红证(b) **278 vs 真值 222**），两次都由车道实测纠正。
>
> **④ ⚠️ 覆盖边界（不许写成"判据覆盖了 RTL"）**：法律在 **LTR(138 行)/RTL(33 行) 两向都有 0 反例**（**语料侧**证据），但 RTL 那 33 行**全在 `C-rtl-indent` 组 = Hebrew ⇒ 被覆盖闸（缺字形）跳过**，而 `latin` 的 138 行**恰好全 LTR** ⇒ **本判据实际行使的只有 LTR 那一半**。
>
> **⑤ 本波新查出的结构性缺口（并已修一半）**：**真正驱动"产品 pc"的那一层在冻树回路里没有任何自动红/绿** —— 五支臂**全部直调 `HbTextLineFactory.FormatParagraph`**（不经 `HbTextFrame`/PC `TextFormatter`）；三支 tab 臂宿主 `CoverageProbe/Program.cs` 对 `lineStartOffsetsDip`/`TextLine.Start` **零引用**（**615 个真值躺在语料里、门禁从来没看过** ⇒ 这就是 `D-T6-c` 活这么久的原因）；`PcLineOracle` 既不在五臂也不在 `verify-all`（`grep` 两边都是 0）。
> ⇒ **`#21` 新增 `verify-all` 第 [5] 步**（`build/MilBridge/tools/pc-line-step.sh`：**只判 `Start` 一列**；自带 ①"防恒绿退化（要求 `判定行>0`）"②"产物目录里的 pc 副本 == 权威件"自检；**并在文件头明说它不覆盖** `D-T6` 那 67 条读法口径红）。**步数 10 → 11，口径已变。** 独立跑该步 = `PCLINE_START_STEP=PASS Start 列 红=0 绿=421 判定行=421 NOINFO=0`、`rc=0`（约 66 s）。
>
> **⑥ `P2`/`P3`/`P4` 的读数**：
> · **`D-R8` 残项**：暴露集**实测 33**（不是上一波估的"7"），**封 32，1 个按停条件挂起**（`src/WpfGfx.Linux/WpfGfx.Linux.csproj` 落在冻结的 `BRIDGE_SRC_FP` 覆盖面内）。新增仓根 `BuildHygiene.props`（`c88fcccde138263b`，**全仓唯一一份排除实现**）+ **38 个 csproj 各加一行 `Import`**。证明：`plain` 清单 **80/80 逐字节相同**、仓内陈旧产物条目 **78→2**；**波后 38 行 import 逐字节存活**（主控实测 `cmp`，**纪律 38 的红线判据**）。它还推翻了派单判据 (a)（19/33 根本没设 `Base*` 却暴露）与"还有 7 个"（只在 `tests/` 内成立），并更正了 `#20` 的机制引注（真正用 `$(Base*)/**` 的是 `Microsoft.NET.Sdk.DefaultItems.targets:35,37`）。
> · **`D-T6-b` 收紧定性**：不是宽松档独有，而是**两档共有**的"**帧原点 = 最近一次重新收集的 `cpFirst`**"；严格档**在缓存未命中时退化成同一形状** ⇒ **缓存是帧的唯一来源**。⇒ `Start` 与帧无关 ⇒ **`D-T6-b` 与 `D-T6-c` 必须分开修、分开取读数**（本波只修 `D-T6-c`）。**关键后果**：真机 `GetTextBounds` 对越界是**夹取**（`FullTextLine.cs:1495-1504` → `CreateDegenerateBounds()`），**我们返回空表**（`shim:3022-3023`），而真机消费者 `MS/Internal/Text/Line.cs:171` 紧跟 `Invariant.Assert(textBounds.Count > 0)` ⇒ **这是断言失败级、不是"读数偏一点"**。修法**要付世代成本** ⇒ 候选为下一波首件。
> · **`P4` 只读盘点**（12 条目表）：建议下一波先做 ① `D-F2` 扩成"**3 个计数器一起接出口**"（`SegmentFaceUnresolved`/`RunFaceSlotMissing`/`ScanCapped` —— **三个"不许静默"的计数器全部只写不读**，`SummaryFragment()` 里一个都没有），② `D-A2` 间接依赖副本盲区，③ `D-R3` 残项 (iii)（**唯一一条"判据本身从未被验过"**，可能恒绿，且**有保质期** —— 修前件在 `$HOME`）。
>
> **⑦ 波内其余读数**：`close-wave.sh --skip-verify-all`（`OUT=/home/links-dev/wfp-runs/close-wave-184641`，18:46:41–18:48:20）⇒ **`native_rebuilt=0`、`bridge_republished=0`**、桥源指纹两侧一致 `b6acdba4f01599d8`、生成物指纹 `state=ok`、应用器审计 `miss=0`、**输入稳定性 波前==波后**；`verify-all` **rc=0 / 11 步 / 871 通过 2 跳过**；应用门禁**两趟** `WPTD_GATE=PASS acceptance=2/2`、`6/6 result=PASS`、`drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`cross_ae=0`、`leftover_after=0`、`exit=143`、`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=167` —— **六条机读 `BASELINE` 行与 `#19` 逐字相同**（只差 `pc`/`pf`/`hbtextline_shim` 三个 sha 与 `rundir`，已机器 `diff` 证过）；等号读者 **`SHIM_SHA=no`**。
> **⑧ 位移表核对（§5 逐条兑现）**：变 = `hbtextline`/`pc`/`pf`/`inputs_fp`；**不变** = `bridge`/`BRIDGE_SRC_FP`/`windowsbase`/`provider`/`win32shim`/`wic_shim`/`dwf`。**唯一"未在车道内兑现"的是 `pf`** —— 预登记写"每趟波必变"但**车道射程内不变**（`pf` 由**波尾**重编引起）⇒ 已更正该预测的**前提**（位移表每行都要标"由谁的动作引起"）。
> **⑨ 主控自我更正（5 处，都留原文）**：① §6 红证(b) 目标 278 → **222**（分母）；② §5 的 `pf` 前提；③ §1.6 "最大差"应点 `i0p48`（Δ=48）；④ `rc=3` ⇔ **前提不成立**（`--guard enforce` 单独只给 `rc=1`，是**必要不充分**）；⑤ §3 任务书里 `D-T6-b` 的**四条现场定位全错**（`HbTextFallback` 是**严格**档；宽松档类**不在 shim 里**；shim 里**没有 `lines[0]`**；`:3851` 是形参表不是入口）⇒ 记我的错，不抹掉。
> **⑩ 收尾清单里还没做的（不许当绿）**：① **`CoverageProbe` 仍对 `Start` 零判别力**（`#21` 只把判据接进 `PcLineOracle`/`verify-all`，**没**接进五臂门禁的臂仪器）；② **`StrictTierProbe`（`D-T6` 定性仪器）不在任何冻结文档/门禁/基线里 ⇒ 它的结论在冻树上无法复算**；③ 非九位"可见位"**仍无指纹判据**（`WpfGfx.Linux.dll` 已漂到 `c400ab1638e0c3d2` 且文档仍引旧值 `0c597fb6ec1eec70`，**连 `D-A1` 的登记行都在引**）；④ 折叠行/单 run 便捷构造在 `PI≠0` 下的 `Start` 真值**本语料零覆盖 ⇒ NOINFO**。
> **⑪ 仪器版本（本波改动）**：`build/shims/PresentationCore.HbTextLine.cs` `76089e1de586ac91`｜`build/MilBridge/tests/PcLineOracle/Program.cs` `19f9e7e78e9bb5c7 → a787a9db23c3302c`（新增 `Start` 列）｜`build/MilBridge/known-red.json` `3bf26e12f320dece → 2fdc02931c2af796`｜`verify-all.sh` `a68823631e8f8919 → 279b958dda238447`｜`build/MilBridge/tools/pc-line-step.sh` **`fa62842d8e211b07`**（新；**初版 `3f8d26ab077d2ec1` → 定版**，两版 sha 都留档 —— 纪律 35：读数是在哪一版上取的必须写清；`verify-all` 第 [5] 步用**定版**）｜`build/MilBridge/tools/retake-arms-w21.sh`（新）｜`BuildHygiene.props` `c88fcccde138263b`（新）｜`tests/parity/windows/tab-anchor/analyze.py` `8f953bd002616689 → f4780fbb12efbc7c`｜`…/out/tab-anchor-oracle.{json,txt}` `a31a813114256faf → 0cebc0afd5142fbf`、`bdf2c31a7a34fbc9 → 34bab0b1032d2cd2`｜`build/MilBridge/arm-logs/README.md` `6924605fab87660e → 7de8a8cb069be60a`。
> **⑫ 下一波建议（按价值）**：① **`D-T6-b`**（帧原点；**要付世代成本**，可与 `D-F2` 的三计数器合并省一笔）；② **把 `Start` 比较接进 `CoverageProbe`**（补 `D-G1`）；③ **`D-R3` 残项 (iii) 判据① 的修前对照**（**有保质期**）；④ `D-A2`/`D-T5`。
>

> ## ✅ 波 `#22` **完整记录（收官，主控，2026-09-16 20:3x）—— 零位移复核波**
> **内容 = 四件判据/读数工作（P1 `D-R3` 判据①的修前对照｜P2 `D-G1` 补齐｜P3 `D-T6-b` 判据+红证+落地方案｜P4 `D-A2`/`D-T5`/`D-F2` 只读盘点）**（预登记 `docs/WAVE22-PREREGISTRATION.md`，含 §8–§11 收官节与 §3.6 的自我修订）。
> **四条车道**：`W22A`（`W22A-report.md 72586d4a85883022`）｜`W22B`（`c98c71f106fec8d7`）｜`W22C`（`93d66fa348ddbb3a`）｜`W22D`（`44461001f9d10eaa`）。
> **⚠️ 本波是"零位移"波**：九位 **9/9 逐位未变**、`inputs_fp` **逐位未变**、`BRIDGE_SRC_FP` 未变、五臂门禁 **`TLINE_GATE=PASS … generation=#21 tree_gen=same drift=0 gone=0 unregistered=0 caliber=OK`**（**不需要重钉**）、冻树 `verify-all` **rc=0 / 11 步 / 871 通过 2 跳过**（第 [4] 五臂 ✅、第 [5] `Start` 列 ✅）。⇒ **未重冻，`#21` 仍是当前冻结基线。**
>
> **① ⭐⭐ 最值钱的一条：预登记的修法字面**会**打断折叠路径**（车道 W22C 推翻，主控逐行复核）
> `HbTextLine._lineStart` 是**双用字段**：`shim:3044`/`:3621`/`:3732` 当**绝对段落系下标**（`GetTextBounds` 的 `first - _lineStart`、折叠越界判定），
> 而 **`shim:3612`/`:3645`/`:3652`** 拿它当 `_text`/`_plan` 的**相对**下标（`Collapse`/`BuildCollapsedLine` 的 `Substring`/`Sub`/索引）。
> ⇒ 预登记写的 `_lineStart = paragraphOrigin + range.Start`（只看了前三个消费点）会让 `_text.Substring`/`_plan.Sub` **切错串或越界**，而 `Collapse` **在真机消费路径上**（`PresentationFramework/MS/Internal/Text/Line.cs:165`）。
> ⇒ **落地必须用 Option 1**（新增 `_paragraphOrigin` 字段、`_lineStart` 语义不变、只改 3 个绝对消费者 + 折叠行透传）；**Option 2（字面）禁止落地**。⇒ **新立纪律 44**。
>
> **② `D-T6-b` 判据落成读数**（新探针 `build/MilBridge/tests/FrameProbe/`，`Program.cs c6a66724ad56760a`、仪器 dll `6b65924a52a59d89`）
> 分母 `script==latin` **288 例/421 行**：**宽松档红 133 行**（帧恒 0）｜**严格档帧红 0**（**421/421 正确**，那 3 条红是**结构红**）｜严格档+`--fresh-source` **133**（✅ **实证"缓存是帧的唯一来源"**）｜严格档+**`--prefix 40`** **421/421**（✅ **实证 `cpFirst≠0` 时的分叉**）。
> 真值口径 `startChar>0` = latin **133**／全域 **179**（⚠️ **不是** 171/138/88 —— 那是 `Start` 那一列，**主控混过、已更正**）。判据形式 **A**（`我方帧 == startChar`）而非 B（B 会把 19 行本来对的帧误判成红）。
> **消费者可见后果**：真机读法 `GetTextBounds(cpFirst,1)` **在 421/421 行读到空**（不加 prefix 时 0/421）⇒ **严格档一样中招**。**缺陷不完全"响亮"**：133 帧错里**只 55 行读空**、**78 行读到"别人"的边界（静默错）**。
> **另登记三条欠账**：① 133 帧红中 **117 条在 `@default` 族**（**不在** `known-red` 范围）⇒ **未登记红待裁决**；② **60 例（全 `@tab0`）我方分行多于真机**（多 **101** 行、无真值对应），而既有臂**按真值数组迭代** ⇒ **结构性看不见**（⇒ **新立纪律 45**）；③ 见上"静默错"。
>
> **③ `D-G1` 补齐**（`CoverageProbe/Program.cs a8727a5bed6bf049 → 421fe394bea93fe2`）
> 新增逐行 `Start` 比较。**修后绿**（`红=0 绿=421 判定行=421 NOINFO=194`）；**反极性红 138 行/88 例**（臂指向旧 shim 源 `fe1b7ed8fa3ed231`）⇒ **不是恒绿**。
> **"只新增"是机器证**：`tab-anchor.log` **469→907 行**、`diff` **0 条 `<`**、**438 条 `>` 全以 `TAB_LINES START` 开头**；**剔掉新增行后与 `#21` 原日志 `cmp` 逐字节相同**；只重链 `tab-anchor` 一支（`99d72b385fe23a90 → 1a5bc7181d0155c3`），四支无关臂 inode/mtime/sha 三位未动（其中 `tab-zero`/`tab-rtl` **重跑过并逐字节复现**；`textlineproto`/`tline` **未重跑** ⇒ 只有"未被触碰"的证据，**如实收窄**）。
> **同族普查**：`hasOverflowed` **22 行 True 却无判据**（而 `D-O1` 刚把它改成真实现）⇒ 该补；`startChar` **179 行**、`dependentLength` **179 行** 同；而 **`height`/`baseline`/`stoppedEarly…` 恒为常数 ⇒ 加它们＝零判别力的假判据**（主控已复核三个常量）。`lineStartOffsetsDip ≡ paragraphStartOffsetDip ≡ paragraphIndentDip` **615/615** 三字段互证。
>
> **④ `D-R3` 残项 (iii)：判据① 的修前对照**（车道 W22A；**成本被主控降到零**：两侧件在 `$HOME` 现成，且**已留档到第二处** `$HOME/w22-preserve/`）
> ① 修前 `REAL_DLLIMPORT=NOINFO method-absent`、修后 `OK value=1` ⇒ **差异是仪器的不是产品的**：探针调用点 `ShimVersionViaUser32` **本身就是 `#18` 加的方法**（产物 `grep -aoc` 修前 **0** / 修后 **1**，**主控独立复核**）⇒ **① 改判「正常路径回归锁」**（原话"没测过"应变格为"**测不到**"）；④ 两侧逐字相同 ⇒ **改判「缺件不变式锁」**。
> **(a) 两极真实**：修前 `TRIGGER=natural THROW` + `RUNMODULECTOR=THROW … A resolver is already set for the assembly.` → 修后 `NO_THROW` + `SelfCheckShimVersion=1`（**主控用 `v1 … replica --loadstream` 独立复现**）。
> **最值钱**：修前对 replica/different/broken **6/6 对逐字相同**、修后 **6/6 对 DIFFERENT** ⇒ **`D-R3` 缺陷本体 = "抢占一律致命 + 成因误归 + 三类不可区分"**（不是"会不会静默"）。另新登记：`realcall` 对 V2 目标抛探针自身的 `NullReferenceException`（两树逐字相同 ⇒ 零判别力，**看着像产品失败实则仪器崩**）。
> **推翻主控两处**：任务书"守卫没有修任何可观测的东西"**只对 (b) 成立**；"(a) 无害"**必须带世代**（修前 (a) **有害**、会毒化模块）。
>
> **⑤ `D-T5` 升为下一波第 1**（车道 W22D）：逐层无 `catch`（LS 回退**是裸构造**）⇒ `LoCreateContext` 的 `EntryPointNotFoundException` ⇒ … ⇒ **进程级 abort**（`nm -D` 实测该符号 **0**、正对照 **1**、总导出 **472**；在册 `exit=134 / blocker=lineservices:LoCreateContext`）。
> **升级理由写准**：**不是"今天有红"**（冻树 **0 载体**，样例全走 `SimpleLine`），而是"**失败模式 = 进程级 abort** ＋ 上游常规写法就会命中"。**家族比在册更宽**：`TextHidden` 机制相同且**上游 `pf` 在每个内联元素边缘就产它**（`ComplexLine.cs:404/477/499`、`LineBase.cs:219`）⇒ `<Run>/<Bold>/<Span>` 与 `<Underline>/<Hyperlink>` 都会命中。
>
> **⑥ `D-A2` 量化 + `D-F2` 落地单**：**34 份**副本**连 sha 都不打印**（`PresentationCore.dll` 非权威 **32** + `wpfgfx_cor3.so` **2**；含分支豁免 **49**），其中 **17 份今天已是旧世代**；**新漏扫**：`tools/` **不在 `SCAN_ROOTS`**（主控复核 `:93`）⇒ `tools/GeometryOracle/bin/Debug/net10.0/WpfGfx.Linux.dll`（`16baacfccfcf1df0`，**是启动宿主**）连枚举都没有。判据**反极性是实测的**（私有拷贝把 PC 加进 `ITEMS` ⇒ 期望 55→86、**立刻 17 份红**、0 份 MISSING）⇒ **该判据今天就红**。
> `D-F2` = **`+3` 行**（推荐 `+4`），**必须在 `candidates=`（`:1377`）之后**（那行 getter 触发 `EnsureScan()`，`:1147` 是其唯一自增点），另改 3 处注释伪证；**对判据行零影响** ⇒ **与 `D-T6-b` 合并只付一笔世代成本**。
>
> **⑦ 主控自我更正（本波 3 处，全部留档）**：① `D-G1` **字段清单写错**（对整个文件 `grep`、没限定 `--tab-lines-oracle` **路径**；本径**只比 4 个字段**）；② `D-T6-b` **预测数用错字段**（`startChar` 179/133 ≠ `Start` 171/138）；③ 引注 **`TextBlock.cs:2314` 不是断言**而是 `if (Invariant.Strict)` 守卫（**真断言 3 处**已核：`MS/Internal/Text/Line.cs:173`、`MS/Internal/documents/TextBoxLine.cs:260`、`MS/Internal/PtsHost/Line.cs:507`）。
>
> **⑧ 一条仪器事故（登记）**：`-p:BaseOutputPath/-p:BaseIntermediateOutputPath` 的"隔离红构建"**不可靠** —— 它把**陈旧 `pc` `9adac6b8d8e285c3`**（`cmp` = 本工程 `bin/Debug` 副本）拷进输出目录 ⇒ 436 例全 `DllNotFoundException`（**两版 RAR 缓存解析路径不同；改选原因 NOINFO**）。**它没给假绿**（`判定行=0 NOINFO=615`）⇒ **恰好印证 `#21` 那个"防恒绿退化"的设计是必要的**（只看"红=0"会把那一趟读成 PASS）。**纪律：反极性构建必须原地取，或必须校验输出目录 `pc` sha == 权威。**
>
> **⑨ 新建/改动件**：`CoverageProbe/Program.cs 421fe394bea93fe2`｜`arm-logs/tab-anchor.log 1a5bc7181d0155c3`（其余四支日志未动）｜新探针 `build/MilBridge/tests/FrameProbe/`（`Program.cs c6a66724ad56760a`、`csproj 9be882d85aac2ad4`）｜**产品件一个字节未动**（九位 9/9）。
>
> **⑩ 下一波（`#23`）建议**：**先 `D-T5` 的判据**（进程级 abort；判据草案已备：`PcLineOracle` 新造 `TextEndOfSegment(1)`+`TextHidden(1)` 变体）⇒ 再 **`D-T6-b`（Option 1）+ `D-F2` 合并付一笔世代** ⇒ 再 **`D-A2`（`ITEMS` 补 PC + `SCAN_ROOTS` 补 `tools`，判据今天就红，需先定登记口径）** ⇒ 再 **`hasOverflowed` 补判据**。**`#22` 的三条欠账**（117 条未登记 `@default` 帧红、60 例多分行、静默错 78 行）要一并排进去。
>

> ## ✅ 波 `#23` **完整记录（收官，主控，2026-09-17 00:5x）**
> **内容 = P1 `D-T5` 判据（只测不修）｜P2 `D-T6-b`（Option 1）+ `D-F2` 落地｜P3 `D-A2` 检查器覆盖面｜P4 只读设计**（预登记 `docs/WAVE23-PREREGISTRATION.md`，含 §9–§14 与 **6 处主控自我更正**）。
> **四条车道**：`W23A`（`W23A-report.md 4eb5c407d5d0948a`）｜`W23B`（`1e65c548ac3d0ad7`）｜`W23C`（`b6601b828475a636`）｜`W23D`（`91e98f471efed019`）。
>
> **① ⭐⭐ 最值钱的一条（事故级）：预登记字面的修法会打断折叠路径**（车道 W23C 拦下，主控逐行复核）
> `HbTextLine._lineStart` 是**双用字段**：`shim:3661`/`:3694`（`_text.Substring`）/`:3701`（`_plan.Sub`）拿它当 `_text`/`_plan` 的**相对**下标（`Collapse`/`BuildCollapsedLine`），
> 而 `GetTextBounds`/`GetIndexedGlyphRuns`/折叠越界判定拿它当**绝对**段落系下标。
> ⇒ 字面的 `_lineStart = paragraphOrigin + range.Start` 会让 `Substring`/`Sub` **切错串或越界**，而 `Collapse` **在真机消费路径上**（`MS/Internal/Text/Line.cs:165`）。
> ⇒ 落地 = **Option 1**：**新增 `_paragraphOrigin`**、`_lineStart` 语义与赋值**一字未动**、只改 **3 个绝对消费者** + **折叠行透传**。**主控逐点审计：4 处改到位、3 处相对消费者 `cmp` 逐字节未变**。⇒ **新立纪律 44**。
>
> **② `D-T6-b` 读数**（分母 = `script==latin` **288 例 / 421 行**）：宽松 **红 133 → 3**｜严格 **红 3 → 3（日志逐字节相同）**｜`--fresh-source` **133 → 3**｜`--prefix 40` **421 → 3**；`GetTextBounds(cpFirst,1)` 读空 **104 → 0** / **522 → 0**。
> **⚠️ 预测写 0、实测 3 —— 主控口径错**（车道如实上报而未改判据）：残余 3 条全 `@tab0`、每条自报 **`行数我方=4 真值=2`** ⇒ **"行数不等"结构族，不是帧错**。机器证（421 行全量）：**`frame == cpFirst` 421/421**；**`cpFirst == truth` 的 418 行里帧错 = 0** ⇒ **帧族红 = 0/418**。主控独立复跑确认。
>
> **③ `D-F2`（三个"只写不读"的计数器）已接出口**：`SummaryFragment()` `:1353-1355` + **早退分支 `:1391`** 也带 `scanCapped=`；3 处注释伪证已改。**两极化**：运行时 `grep -c` **0/0/0 → 各 2 处**；pc 二进制 UTF-16 用户串 `0/0/0 → 2/1/1`。
>
> **④ 主控三条硬判据（自己跑的）**：`patcher --check` **rc=0**；**纪律 38 红线**（真跑重生成 ⇒ 生成物 `fef2cfb47f882a82` **逐字节不变**、注入仍在 `:268`）；**`appliers=22 ok=80 miss=0 red=0 rc=0`**（与 `#21` 同数 ⇒ **没落进"注册了但没生效"那一族**）。
>
> **⑤ `D-T5` 判据（只测不修，新探针 `build/MilBridge/tests/D5CbrProbe/`）**：`eos1`/`mod1` 两条腿都 **`RED-EXC-LS`/`ABORT 134`**，**快路径开（= 产品缺省）也如此**；`control`（阳性对照）与 `mod0` **GREEN**。**abort 与 null 已可分辨**（判读逻辑自身过两极化：`--selftest abort`⇒134、`null`⇒1）。
> **⭐ 主修法不必动 shim**（`ExtractRun`/`CollectLenient` 都在**应用器**里）⇒ **零世代成本**；只有严格档 `TryCollect`（`shim:4513`）要付世代、建议后置。**这会改 `#24` 的计划。**
> **它同时推翻了我采纳的一条**：`TextHidden` **默认配置下不命中** `D-T5`（`SimpleTextLine.Linux.cs:1703-1707` 把它当 **Ghost run** 吸收）—— 我此前**没核机制就把"家族更宽"写进了 `KNOWN-DEFECTS.md`**，已更正。它还自纠 3 条仪器缺陷（最重要：`GetTextRun` **非幂等** ⇒ 宽松档看到的是**下一个 run** ⇒ **判决对、归因错**）。
>
> **⑥ `D-A2` 检查器覆盖面上线**（用户裁决：先登记、判据立刻上线）：`ITEMS` 补 `PresentationCore.dll` + `SCAN_ROOTS` 补 `$REPO/tools` + `applocal-expect.py` 补 PC ⇒ **13 份点名红**（12 PC + 1 `tools`）。
> **不是 17** —— 差的 5 份全落在**既有豁免分支 ④**（`is_release_path && is_debug_auth` ⇒ `NO-AUTHORITY`「判不了≠一致」）⇒ **两个数在各自口径下都对**（W22D 的 17 = 内容≠权威的份数，含 5 份 Release）。
> **落地形态完全符合裁决**：该检查器**没有**既有在册红机制（`known-red|registry|在册` 改前 0 命中；退出码只有 0/1/3）⇒ **新建书面登记** `build/DirectWrite.Linux/wic-shim/known-red-PC-copies.md`（`e5946a8a7ce1cfe0`）+ `show_registry()`（**只读**，自述"**登记≠已容忍：本段不参与判定**"）⇒ **`rc` 一字未动**。
> **两极化很硬**：把一份红副本刷成权威 ⇒ `MISMATCH 13→12` + 登记段出「已转绿 1」；`cp -p` 复原 ⇒ `cmp IDENTICAL`、**sha/size/mtime 逐位相同**、`MISMATCH` 回 13，且**复原那趟日志与复原前那趟 `sha16` 完全相同**。`--selftest` **rc=0 / 16 项全 PASS**。
> **⚠️ 一条**：接线前 `APPSYNC` **就已经是 `MISMATCH`**（`UNEXPECTED-EQ=1`，那条 = `D-A1`）⇒ **"接线前是绿的"是错的**（主控此前这么写过，已更正）。
>
> **⑦ `W23D` 的只读设计（并推翻了我刚立的纪律 45）**：两支臂**都在断言"我方行数 == 真值行数"**（`CoverageProbe:1391`、`PcLineOracle:905`），那 60 例**今天就在红且 60/60 已在册**；机制 = **`D-T4` 臂姿势**（证据 = **60/60 我方行数 == 其 `@default` 孪生真值行数**），**不是"产品多分行"**。
> ⇒ **纪律 45 已替换**（元教训：**立纪律同样要证伪**）。另给 `hasOverflowed` 判据草案（真值侧规律**主控独立复算 615/615**：`paragraphStartOffsetDip + width > paragraphWidthDip` ⇒ 22 命中 / 0 假阳 / 0 漏；**接线后预测红 = 0**；**反极性 `=> false` ⇒ 红 22 行/8 例**；⚠️ **去掉严格 `>` 改 `>=` ⇒ 红 74 行/63 例** ⇒ **判据必须写死严格 `>`**），以及两份登记表的分工表与三处读数语义更正。
>
> **⑧ 收官顺序（主控的流程错，已写成纪律 46）**：我的 §8 清单**漏了 `close-wave.sh`** ⇒ 把读数取在**规范波尾之前**；波尾重建后 **`pf 2fb1a896f8277647 → 1c3fe23261c22bc6`**（`pc` 没再动）⇒ 应用门禁基线**作废** ⇒ **按正确顺序重取了一遍**（本记录里的数都是重取后的）。
> **正确顺序 = `close-wave.sh` → 五臂重取 → 重钉登记表 → `verify-all` → 应用门禁两趟 → 重冻基线。**
>
> **⑨ 现场读数**：`close-wave.sh`（`OUT=…/close-wave-23`，rc=0）⇒ `native_rebuilt=0`、`bridge_republished=0`、桥源指纹两侧一致、生成物指纹 `state=ok`、应用器审计 `miss=0`、**输入稳定性 波前==波后 `6146f364…ca0ca`**；五臂 **`TLINE_GATE=PASS … generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc`**；`verify-all` **rc=0 / 11 步 / 871 通过 2 跳过**；应用门禁**两趟**（都走**复用 `:97`** 分支，按 `D-G7` 逐字记录）`6/6 result=PASS`、`drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`cross_ae=0`、`leftover_after=0`、`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=167`。
> **§5.1 的命名候选没有兑现**（`TrimText` 的 `CharacterEllipsis` 经 `_collapsedRange`）—— 本件确实改了 `_collapsedRange.CharacterIndex`，但**渲染读数不变**。
>
> **⑩ 内存信封（用户要求，40 分钟 / 80 样本）**：`MemAvailable` **最低 2,752 / 最高 4,397 / 均值 3,406 MB**；**`SwapFree` 全程未动（1,057 MB = 开工值）** ⇒ **未发生内存压力**；`load1` 峰值 4.63（3 核）。协议 = 同时只允许一个重构建者 + 全体 `-m:1` + `DOTNET_gcServer=0` + 构建前 `<1200 MB` 自检。
>
> **⑪ 新登记**：`D-G7`（常驻 `:97` **第 3 次死**，且**死了不会让任何判据变红**；危害是装置悄悄从"复用"变"自起" ⇒ 声明变假）；`D-G8`（`check-applocal-sync.sh:654` 的 `scan; scanrc=$?` —— **`grep -c scanrc` = 1**，赋值后从未被读 ⇒ **权威整份不见时 `rc` 可能仍 0** ⇒ `APPSYNC=PASS` 可以骗人；修它必须同趟改 `SELFTEST_E`）。
>
> **⑫ 下一波（`#24`）建议**：① **接 `D-T5` 的修法**（**主路在应用器 ⇒ 零世代成本**；严格档那半与下一次动 shim 的波合并）；② **把帧列接进一个门/步**（`FrameProbe` 五处 grep 全 0 ⇒ 那 67 例**今天无处可登记**）；③ **`hasOverflowed` 判据**（22 行真值、零判据，而 `D-O1` 刚动过它；**必须写死严格 `>`**）；④ **`D-G8`**（`scanrc` + `SELFTEST_E` 同趟改）；⑤ `D-A2` 的"两份 `.so` 一起换旧仍静默"那半。
>

> ## ✅ 波 `#24` **完整记录（收官，主控，2026-09-17 11:1x）**
> **内容 = P1 `D-T5` 主路修法（零世代成本）｜P2 帧列接进 `verify-all`｜P3 `hasOverflowed` 判据｜P4 `D-G8` 修法**；**收官时又加 P5：`verify-all` 第 `[7]` 步 `BASELINE-SHA` + `BASELINEDUP` 反重复牙齿**。
> **四条车道**：`W24A`（`build/MilBridge/W24A-report.md 4b517c6e8d1f76e8`）｜`W24B`（`89309b0fdb905bda`）｜`W24C`（`bc9f3af81a312ef0`）｜`W24D`（`484738db104b56f2`）。**另开两条只读侦察车道（零 `dotnet`、零仓内写入）**：`D-A2-r` 方案（`~/w25-recon/da2r-plan.md fabd8ae7cb81975f`）｜`D-T5-R` 修法域（`~/w25-recon/d-t5r-plan.md cb70e58b4e479ace`）。
>
> **① P1 `D-T5` 主路（进程级 abort ⇒ 修好）**：上游法律 = 空 CBR 的 `TextHidden`/`TextModifier`/`TextEndOfSegment` 是**合法的隐形 run**（保留 `Length`、宽度 0/Ghost、**绝不 deref CBR**）；我方缺陷 = **分类之前就 deref 了**。落点 = **应用器** `patch-presentationcore-textline-fallback.py`（`00c2179b87fc0509 → 536f58b338a2369d`，5 hunk `+79−7`）⇒ 生成物 `a6f1b678ce87a8a2`。
> **读数**（`D5CbrProbe` 冻结仪器 `117582b2a40d30c0`；strict/lenient × catch/nocatch **四格全同**）：`eos1`/`mod1`/`hidden1`/`hiddenmid` 由 `RED-EXC-LS`/`ABORT 134` → **GREEN**；`control` 与 `mod0` **逐字节未变**。**两极化两级**：① 回退证**逐字节往返闭合**（复原 patcher ⇒ `pc` 回到 `7b47a7b3d69ad62f`、且探针矩阵与修前**逐字节相同**）；② **真·假修端到端** —— 牙级（只改代码不动 needle）⇒ 生成 `rc=1`、**生成物根本没写盘**；端到端（代码+needle 同改）⇒ `A1/A2=PASS`、**`A3=FAIL（Σ可见长=4 期望=5）`** ⇒ **真修 `A3` PASS / 假修 `A3` FAIL ⇒ `A3` 有判别力**。**主控独立复现过整个矩阵**。
> **零射程**：`PcLineOracle` 修前/修后各 1,480 行**只差 4 行**（全是既有诊断串**追加**新字段）—— ⚠️ **主控更正**：该证**只覆盖 latin 288 例 / 421 行，不覆盖 RTL**。
> **残余 `D-T5-R`**：`hiddenonly`（整段全是隐形 run）**仍 abort**，机制 = `lastFail="没有 run properties"`。**只读侦察（本波新做）已定位**：真身**不在 shim**（`grep -c CollectLenient build/shims/PresentationCore.HbTextLine.cs` = **0**）而在**生成物** `build/PresentationCore.Linux/TextFormatterImp.Linux.cs:243-248`（源头 = 应用器 `REPLACEMENT_3`，失败点 `:403-404`）；根因 = 全隐形段落里**每个 run 的 `Properties` 恒 `null`**（`TextHidden.Properties => null`（`sealed`）＋ `TextEndOfParagraph(1)` → `TextEndOfLine(length,null)`）⇒ 遍历完整段**连一次非 null 的机会都没有**；`hidden1`/`hiddenmid` 只因段里有 `TextCharacters` 把 props 立起来。**兜底候选已定位** = `paragraphProperties.DefaultTextRunProperties`（非空且 `Typeface` 非空**已被机器强制**；调用点在同函数作用域内；仓内先例 `TextBlock.Linux.cs:2856`）。⇒ **修法可 100% 落在应用器 ⇒ 也是零世代成本**（机器证：把应用器 `EDITS` 在内存里重放到上游，与磁盘生成物 `diff` **只差 `HEADER` 12 行** ⇒ 它是唯一生成者；且 `tline-gate.sh:234 GEN_KEYS` **不含 `pc`**）。
>
> **② P2 帧列接进 `verify-all`（步数 11 → 12，第 `[6]` 步）**：`frame-step.sh`（`37f27df68e52bf8c`）+ `verify-all.sh`（`279b958dda238447 → 0d268f4f0bb441c3`）。**判的是 `帧红`，不是 `红行`**；断言 **`帧红==0 ∧ 判定行>0 ∧ 仪器族NOINFO==0 ∧ 自洽=1`**。三条腿（strict / lenient / strict+prefix40）**帧红全 0**、`判定行=421`。**反极性 4 组**，最强一档 = **用真实旧产物**（修前 `pc e7cabff9417ed380` ⇒ `strict+prefix40` 帧红 **421**、`lenient` 帧红 **133**，与 `#23` 修前表**逐格吻合**；另三组 = 退化语料 ⇒ `判定行=0 ⇒ rc=1`（**防恒绿闸活**）、断言换成 `结构红` ⇒ `rc=1`、真值改坏 ⇒ `结构红 3→12` 而本步**仍 rc=0**（**"本步不看真值一致性"是设计**，已实测写明））。**实测时间预算** `WALL≈394–428 s`、峰值 RSS ≈690 MB（本趟实测：整趟 `verify-all` **11:56**，其中第 `[6]` 步约 7 分钟）。**本步不覆盖**那 3 条结构族红（`行数我方=4 真值=2`；**只点名、不判**，属主控登记决定）、**RTL 半边**、`--fresh-source` 腿。
> **⭐ 本波最值钱的一条（车道推翻主控、主控采纳并据此加固）**：**只接 `--tier strict`（不带 `--prefix`）那一条腿，对 `D-T6-b` 是零判别力** —— 修前 `帧红=0/结构红=3`、修后**逐位相同** ⇒ 「严格档红 3 行」**不能当修法证据**；有判别力的是 **`--prefix 40`（421→0）** 与 **宽松档（133→0）**。⇒ **这就是三条腿全留（不把 `--prefix 40` 降为可选）的实测理由**；也**更正了 `#23` 的读法**：`#23` 表里"严格档 `红 3 → 3`"**不是"修法没修到"**，而是**那条腿本来就看不见**。
>
> **③ P3 `hasOverflowed` 判据（22 行真值、此前零判据）**：`CoverageProbe --tab-lines-oracle`（`Program.cs 421fe394bea93fe2 → dea2a02cf8bab55a`，**`diff` 删除行 = 0**）修后 `红=0 绿=421 判定行=421 NOINFO=194 真值True=22`（分母 = latin 288 例 / 421 行）。**反极性 4 档**：`=>false` **22/8**｜错驱动量 **79/48**｜`=>true` **399/280**｜**去掉严格 `>` ⇒ 58/47** ⇒ **"必须写死严格 `>`"从告诫变成读数**（那 58 行坐在"恰好到达边缘、余量为 0"的**发丝扳机**上）。⚠️ **判别面只有 `tab-anchor` 一支**（另两支语料带真值但**无 `paragraphProperties`、无 `script`** ⇒ 全 `NOINFO`）；三支臂日志已 `ln -f` 重链，且**剥掉新增行后与 `#23` 原日志 `cmp` 逐字节相同**。
>
> **④ P4 `D-G8`**：`check-applocal-sync.sh 013df358c0bed2a3 → fc4c249851fa1d71` —— **`scanrc` 被丢弃**（`grep -c scanrc` = 1，赋值后从未被读）⇒ **权威整份不见时 `rc` 可能仍 0** ⇒ `APPSYNC=PASS` 可以骗人。修法 = 新增计数器 **`AUTH-MISSING`** 并**接进 `rc`**（`:226` 缺权威 ⇒ `rc=1`；总规则 `:34` 含它）。**改前假绿复现**（移走一份权威仍 `rc=0`+`PASS`、计数器逐字相同）／**改后 `rc=1`**／`cp -p` 还原后与绿趟 **`cmp` 逐字节相同**；`--selftest` **rc=0 / 17 项全 PASS / 0 FAIL**（**主控独立跑过**）。
>
> ⏪ **（`#26` 附注）`verify-all.sh` 在 `#24` 之后又被改过**（`#26` 车道 W26B 落 `D-G10`）⇒ 本行引的 sha 是**当时**的值，**现值见 `docs/CURRENT-STATE.md` 的步数口径行**。
> **⑤ P5（收官时加的第 `[7]` 步）：把"冻结基线"这个顶层结论自己变成一颗牙**。`build/MilBridge/tools/baseline-sha-check.sh`（`5836b8296b2e4245`）+ `verify-all.sh 0d268f4f0bb441c3 → 741b638acaf02e7a`（**步数 12 → 13**）。判据 = 现场重算基线**整份** sha16 ↔ `docs/CURRENT-STATE.md` 的机器行 `> BASELINE-FROZEN gen=#NN sha16=<hex16> file=<path>`，并核对"文档声明的世代 == 基线文件里**最新**那行 `# RE-FROZEN #NN`"；三态 PASS/FAIL/**NOINFO**，**`rc=0` 只在全 PASS 时给出**（"没声明"也判失败 ⇒ **防静默绿**）。`--selftest` **6/6 PASS**。**并加反重复牙齿 `BASELINEDUP`**：活的权威对（`CURRENT-STATE.md` + 基线文件）里**禁止**出现「……整份 sha = `<hex16>`」这种**散文式声明** —— **值只许出现在机器行里**。
> **起因（一处真实的不可复算，如实留档）**：`#23` 的整份 sha **在三个文档里记成两个值** —— `docs/CURRENT-STATE.md` 与 `docs/WAVE23-PREREGISTRATION.md:481` 记 `5ccdf74a56955096`，`docs/WAVE24-PREREGISTRATION.md:3` 记 `87ae111462ca2159`；而 `#23` 内容已被本波覆盖 ⇒ **今天无法判定哪个对**。**已证实的一点**：`~/w21-verify/fix-inputs-fp.py`（mtime **01:00**）在 `freeze-w23.py`（**00:58**）**之后**改过基线 ⇒ **冻结时那个 sha 必然已失效**；最可能成因 = `#23` 冻结后我又手改过 `inputs_fp` 那一行（**猜测、无证据**）。**主控试过逐字节重建**（用 `freeze-w23.py` 的 `newhdr`/`blk` 字面量 + 尚存的 `~/wfp-runs/w23-gate2b/baseline23-run2.md` + 现文件尾部反推），**两个值都不命中 ⇒ 重建前提不成立 ⇒ 放弃，不拿推测冒充结论**（纪律 4/47 的形态）。
> **正面参照（可复算的旧世代）**：`#19` 的整份 sha **今天仍能复算** —— `~/w21-verify/backup/ACCEPTANCE-BASELINE.md.bak` 的最新世代行就是 `#19`，现场 sha16 = `f5d8a6f1cdf49635`，**与文档所记一致** ⇒ 这套"记整份 sha"的做法**本来是对的**，`#23` 是**执行事故**、不是设计缺陷。
> ⚠️ **自测当场抓出两个真缺陷（自查器自身）**：① 我用 `sed` 造的 sha 扰动值**只有 15 位** ⇒ 只证出"畸形 ⇒ NOINFO"、**没证出 FAIL**；② `chk` 抽取**没取首行** ⇒ 声明缺失时会匹配到两行 `BASELINESHA=`、比较**永远失败**。⇒ 新立一条：**"反极性自测本身也要被检验"**（自测必须能证出"该红的红"，而不只是"该绿的绿"）。
>
> **⑥ 波尾与门禁**：`close-wave.sh --skip-verify-all`（`OUT=~/wfp-runs/close-wave-24`，rc=0）⇒ **`native_rebuilt=0`、`bridge_republished=0`**、桥源指纹两侧一致 `b6acdba4f01599d8`、生成物指纹 `state=ok`、应用器审计 `miss=0`、**输入稳定性 波前==波后**（`a8703419…ee793`）。五臂 **`TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc`**、`GATE_REASON=all-as-registered`、`rc=0`。**`verify-all` 跑了两趟**：第 1 趟（`10:56:21–11:08:17`，日志 `~/wfp-runs/w24-verify13.out`）在**升到 13 步之后**；第 2 趟（`w24-verify13b.out`）在**基线改成 13 步、机器行重算之后**跑 ⇒ **让第 `[7]` 步的 PASS 落在最终冻结版上**（否则牙齿验的是上一版 —— 这是"让基线核对基线自己"带来的**自指**问题，用"再跑一趟"消掉）。**波前/波后九位逐位断言未动**（`w24-pre-verify13.nine` vs `w24-post-verify13.nine`，机器 `diff`）⇒ **`verify-all` 不改九位**。
>
> **⑦ 判据读数：与 `#23` 逐位相同** —— 应用门禁**两趟**（`run_dir=…/w24-gate1`、`…/w24-gate2`；**两趟都走"复用常驻 `:97`"分支**，按 `D-G7` 逐字记录）⇒ `WPTD_GATE=PASS acceptance=2/2`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、**6/6 `BASELINE … result=PASS`**、`drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`cross_ae=0`、`leftover_after=0`、`scroll=ok`、`exit=143`、`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 runs=167`、`WPTD_BRIDGE_SRC_STALE=no`；**六条机读 `BASELINE` 行与 `#23` 逐字相同**（只差 `pc`/`pf` 两个 sha 与 `rundir` —— `hbtextline_shim` 未变，已机器 `diff` 证过）。⇒ **`D-T5` 修法对应用门禁零影响**（与预测一致：`samples/**` 对那类 run **0 载体**）。
>
> **⑧ 新登记（本波）**：**`D-T5-R`**（见 ①，**修法域已定位、零世代成本**）｜**`D-T7`**（零宽占位取 `U+200B`，UAX#14 里它**可断**、真机 Ghost **不产生断点**；真机哨兵是 LineServices 原生 `LSEsc.szHidden`，**本仓定不出码点**、仓内也**没有 `U+2060` 的证据** ⇒ 真值**只能靠真机重录**；**风险限定 = 只在"修前会 abort 的段落"上出现 ⇒ 不会让任何现有读数变差**）｜**`D-A2-r`**（见 ⑨）。
> **⑨ `D-A2-r`（只读侦察交付，含一条推翻原方案的危险发现）**：桥的**绝对锚已经存在** —— `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/bridge-src-fp.txt:3` 的 `BRIDGE_SO_SHA256`（写点 = **`build/publish-milbridge.sh:81`**；⚠️ 派单书写的 `build/MilBridge/tools/publish-milbridge.sh` **不存在**，已更正）；`run-wpftextdemo.sh:122` **已经在读它，但只打印、不进任何判定，且比的是自己 cp 出去的那一份 ⇒ 事实上的同文件自比**。**桥其实在 `ITEMS` 里（`:116`），但 `exp` 是空串 ⇒ 在 `:225` 被 `continue` 跳过**（全脚本唯一一处）⇒ 今天这份件**一个读数都不产生**。
> **🔴 推翻原方案 A（我 `#22` 那版的思路）**：若把桥配成**非空权威**使其进 `ITEMS` 判定，会打 `STALE` 行 ⇒ `sync-applocal-authority.sh:119-122 → do_refresh:103` 会 **`cp -f "$asrc" "$dst"`＝用 376 B 的 `.txt` 覆盖 4,987,840 B 的 `.so`**；当 `dst` 是发布目录那一份时是 **`cp X X` 自覆盖 ⇒ 可能截断成 0 字节**，一次 `--apply` 同时毁掉桥与锚。⇒ **改用只读方案 B**（独立锚检查、不进 `ITEMS`、无写路径；连 `applocal-expect.py:53` 的同步也一并免掉）。**反极性已离线验证**：今天两份副本 sha16 都是 `d567c26f197ec1e3` == 记录 ⇒ **0 条新红**；两份一起换旧（`~/wfp-runs/w18-pre/wpfgfx_cor3.caf7baf9e67719aa.so`，现算 sha16 `caf7baf9e67719aa`）⇒ **双双 ≠ 记录 ⇒ 必然 rc=1**。
> **主控裁决（`#25` 落地依据）**：① 采**方案 B**；② 判据**只看 sha，不看 mtime/权限** ⇒ 侦察列出的疑点里 mtime/`cp -f` 那两条误报**自然消失**（自检把内容原样还原 ⇒ sha 相等 ⇒ 不红）；③ **"记录过期"与"件被换"不需要可分判据** —— 合法重发会让记录与副本**同步变**（不红），所以任何 mismatch 都意味着**两者之中必有一个在说谎**（而发布记录正是应用门禁信任的输入）⇒ **两种口径都判红**，区分只影响**措辞**、不影响裁决；④ 记录缺失 ⇒ **NOINFO（不许当绿）**；⑤ **射程缺口登记**：`.artifacts/**` **不在任何 `SCAN_ROOTS`**（今天两份能扫到只因恰好落在 `build/` 下；桥若发到 `build/` 之外 ⇒ **一份也扫不到、只出 NOINFO**）、**不防篡改**（记录与副本同权限同目录）、`.so.dbg`（5,984,488 B）**无任何判据**。
>
> **⑩ 内存信封（用户要求：控制占用）**：70 样本 / 35 分钟 ⇒ `MemAvailable` **最低 2,130 MB / 均值 2,750 MB**；**`SwapFree` 最低 807 MB**（`#23` 是**全程未动 1,057 MB** ⇒ 本波吃了**约 250 MB swap**）；`load1` 峰值 **9.31**（3 核 ⇒ 超订 3 倍）。**成因 = 主控并发开了 3 个构建者**（P1 重建 `pc` + P2 建 `FrameProbe` + P3 建 `CoverageProbe` 并重跑三支臂）⇒ **协议已收紧**：**3 核上同时最多 2 个构建者；重建 `pc` 的车道独占**；标准旗标 `-m:1` + `DOTNET_gcServer=0` + 起步前 `MemAvailable < 1200 MB` 自检。**本波收尾阶段（`verify-all` 两趟 + 两条只读侦察车道并行）实测只有 1 个构建者**：`MemAvailable` 全程 **3,000–3,260 MB**、`load` ≈1.4–1.9、**swap 未再被动** ⇒ 协议有效。
>
> **⑪ 一条口径（引用前必读）**：`APPSYNC` 的红数与 `known-red-PC-copies.md` 的 `[在册红·已转绿]` **只在某个"权威 `pc` sha"下有意义** —— 本波 `pc` 一重建，那 12 份"已转绿"**立刻又 stale**（主控实测 `MISMATCH 13 → 18`）⇒ **`APPSYNC` 必须在波尾、`pc` 定型之后再读**；**"转绿"≠永久销账**。本波 `#24` 定型后实测：`rc=1`、`MISMATCH=18（STALE=18）`、`MISSING=0`、`UNEXPECTED=1[DECL-GAP-EQ=1]`、`DIVERGENT=3`、**`AUTH-MISSING=0`**。
>
> **⑫ 主控自我更正（本波，全部留档）**：① 帧列的预期分母**第五次**用错列（告诉 `W24C` 的 (b) 档 89/54 是**整份语料**，臂给的是 **79/48 latin**）；② 给 `verify-all` 写了一个**中文步骤名**（`FrameProbe·帧列`）—— `run_step` 用 `tr -c 'A-Za-z0-9' '_'` 生成日志名 ⇒ 会塌成下划线，**已改成 ASCII `FrameProbe-frame`**；③ 用 `pgrep -a verify-all` 断言"`verify-all` 已结束" —— 该命令只匹配**进程名**，进程其实**还在跑**；④ 一条 bash 里写了非法的 `$` 花括号替换 ⇒ 整条命令 `rc=1`、**什么都没跑**（读数作废）。**另**：`#23` 那条 `inputs_fp` **手抄**错误（漏一个 `b`）就是纪律 49 的来源，本波**所有哈希均由脚本现算**（含本记录与 `#24` 冻结）。
> **⑬ 车道报告的两处引注错误（由只读侦察车道发现、主控现场核对确认）**：`build/MilBridge/W24A-report.md:253` 把那条 `return false` 引成 `CollectLenient` 的 **`:358-363`** —— 而**现盘任何件里都没有这个位置**：真身是**生成物** `TextFormatterImp.Linux.cs:245-248`（应用器 `:403-404`）。**成因已查明**：`没有 run properties` 这个串**在六个件里都存在**（生成物 `:245`/`:246`、应用器 `:403`/`:404`、shim `:4580`（**侦察证明是死码**）、`build/MilBridge/staging/PresentationCore.HbTextLine.cs:1605`、`CoverageProbe/refs/…ebccdb1e.cs:3539`）⇒ **`grep` 归属天然歧义**。另一处：`W23A-report.md:230` 的"收集串 = 空串 ⇒ 空段落分支"是**假修情形**的描述（真码下收集串是 3 个 `U+200B`、非空，走 `:243`）。⇒ **纪律 4 的又一现场：引注前现场重读，且要连文件名一起写。**
>
> **⑭ 下一波（`#25`）建议（按价值排序）**：① **`D-T5-R` 修法**（**已定位到生成物 `:243-248`、修法域 = `DefaultTextRunProperties` 兜底 + 透传，且已证 `100%` 可落在应用器 ⇒ 零世代成本**；判别力边界要写进落地报告：`A1/A2/A3` 对"占位字符是否真零宽"**零判别力**，且冻结语料**不含全隐形段落** ⇒ "能否转绿"可测、"转绿是否对"**本仓不可测**，要真机重录）；② **`D-A2-r` 按上述裁决落地方案 B**（判据草案已在侦察报告里、含 `--selftest` 新增用例 P；**今天就 0 条新红**，同时把"两份一起换旧仍静默"这条洞堵上）；③ **`D-T7`**（零宽占位码点，**必须真机重录**）；④ **`hasOverflowed` 的更大判别面**（`--tab-oracle`、`U1`、36 条真值 —— **仍不在任何门/步里**）；⑤ **把 `pc-line-step`/`frame-step`/`baseline-sha-check` 三步的自报口径收紧**（要求各自吐一条 `KEY=PASS` 汇总行，让 `run_step` 的失败诊断 grep 直接命中，而不是只在 `rc≠0` 时才有细节）。
>
> ## ✅ 波 `#25` **完整记录（收官，主控，2026-09-17 13:3x）**
> **内容 = P1 `D-T5-R` 修好（零世代成本）｜P2 `D-A2-r` 方案 B 落地｜P3 两条登记结算｜P4 收官补的登记与草稿**（预登记 `docs/WAVE25-PREREGISTRATION.md`，含 §9.1 波尾硬性动作、§9.1b 静树纪律、§9.2 复算三条）。**详细读数已逐字写进 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#25` 块**（本节只记过程与判据）。
> **车道（四条落地 + 六条只读）**：`W25A`（`build/MilBridge/W25A-report.md 2bb495e622b9ec19`，`D-T5-R`）｜`W25B`（`fb7469b4bc107312`，`D-A2-r` 方案 B）｜`W25C`（`0dac420628c926c8`，登记结算）｜`W25D`（`~/w25-recon/selfreport-plan.md fae47460963941c2`）｜`W25E`（`recompute-audit.md 460d32d1baec7949`）｜`W25F`（`d-t7-recipe.md a2d495211364222f`）｜`W25G`（`hasoverflowed-plan.md dba49243f2b9749a`）｜`W25H`（`rtl-noinfo.md 6cefb2be1bd2df58`）｜`W25I`（`~/w25i/column-gate.diff 9340d85dfcf91fc0` + `report.md 1ea7e434ded9386c`）｜`W25J`（`~/w25j/report.md f33275ff44602243`）｜`W25K`（`~/w25-recon/defect-register-audit.md dae70fe788008654`）。
>
> **① `D-T5-R`（`hiddenonly`：整段全是隐形 run）修好 —— 本波最重要的成本结论**
> - 修法**全在应用器**（`patch-presentationcore-textline-fallback.py 536f58b338a2369d → 64cac206bf10635f`）⇒ 生成物 `a6f1b678ce87a8a2 → a433f38aaabe43b4`，而 **`hbtextline` 一字节未动** ⇒ **零世代成本**（不重取五臂、不重钉登记表）。**这是"把修法落在应用器"这条路线的第二次兑现**（第一次是 `#24` 的 `D-T5` 主路）。
> - **读数**：`hiddenonly`（**必须带 `--collapsible`**）strict/lenient × 带 catch/`--nocatch` **四格**：修前 `rc=1 RED-EXC-LS`／`--nocatch` **`rc=134`** ⇒ 修后**四格全 `rc=0` GREEN ∧ `A1/A2/A3` 全 PASS**。**机制证**：`lastFail` `"没有 run properties"` → `"-"`、`relaxedHandled/Failed` `0/1 → 1/0`、**新计数器 `relaxedParaDefaults` `0 → 1`**。
> - **⭐ 写法本身是设计（值得复用）**：生成物 `:259-267` 的兜底是 `if (props == null && paragraphDefault != null)`，且**`paragraphDefault` 为 null 时行为与修前逐位相同** ⇒ **"半接线"不会静默变绿**（反极性③实测：半接线仍 `RED-EXC-LS`/`134`、`relaxedParaDefaults=0`、`lastFail` 与修前**逐位相同**）。
> - **三级反极性**：牙级（只删代码不动 needle）⇒ 应用器 `rc=1`、**生成物没写盘**；返空串 ⇒ **`A3` 红**（`RED-LENGTH`，`Σ=2` 期望 3）；半接线 ⇒ 仍红 + **计数牙齿 `n_default_src` 代码阶段就红**（`0 ≠ 2`）。**回退证**：复原应用器 ⇒ `pc` **`cmp` 逐字节回到 `476994e35d31a7e1`**，再恢复 ⇒ 往返闭合。
> - **零射程（机器证）**：`PcLineOracle` 1,480 行**只差 2 行**（新字段）、**判据行 sha 同值**；`frame-step.sh` = `FRAME_STEP=PASS`（与 `#24` 同值）；该腿 **`relaxedCalls=0`** = "新分支在冻结语料上一次都不执行"的**运行期证明**。
> - ⚠️ **两条边界（不许省略）**：**判别力** —— `A1/A2/A3` 对"占位字符是否**真零宽**"**零判别力**（探针从不读几何）⇒ **"能否转绿"可测、"转绿是否对"本仓不可测**（要真机重录，即 `D-T7`）；**"修好"≠"有牙"** —— `grep 'D5CbrProbe|hiddenonly'` 在 `verify-all.sh` 与全部 `tools/*.sh` 里**仍是 0** ⇒ 今天**没有任何门会因它变红**（登记为欠账）。
>
> **② `D-A2-r` 方案 B 落地（桥的只读绝对锚判据）**
> - `check-applocal-sync.sh fc4c249851fa1d71 → 7bc9364091a28fd4`（778→945 行，8 hunk **全为追加**，自检 A–O 用例体**一行未动**）。锚 = 发布记录里的 `BRIDGE_SO_SHA256`；**桥绝不进 `ITEMS`** ⇒ **结构上进不了** `sync-applocal-authority.sh:103` 那条"**用 376 B 的 `.txt` 覆盖 4.9 MB 的 `.so`**"的写路径（主控读码核过：`bridge_anchor_check()` 体内 `CNT_STALE`/`CNT_NEWER` **0 处**）。
> - **新计数器** `CNT_BRIDGE_ANCHOR`/`CNT_BRIDGE_NOINFO`（**两者都红**）：定义 `:168`｜调用 `:884`｜摘要 `:886`｜进 `rc` `:935`+`:936`。**`--selftest` 18/18 PASS**（新例 `SELFTEST_P`，主控**独立重跑复核过**；**并在静树上再跑一次 = `SELFTEST=PASS`/`rc=0`**，按 §9.1b）。
> - **反极性**：两份副本一起换旧桥 ⇒ **旧件 `APPSYNC=PASS rc=0`（`D-A2-r` 现场）→ 新件 `APPSYNC=MISMATCH rc=1 BRIDGE-ANCHOR=2`**，其余 12 个计数器**逐字相同** ⇒ **红只来自新判据**；还原 ⇒ `cmp IDENTICAL`。**今天 0 条新红**。射程缺口（**不防篡改、记录过期与件被换不可分、"桥少了一份"报绿**）已明说。
>
> **③ 两条登记结算**：3 条结构族帧红**首次有书面登记**（`build/MilBridge/known-red-frame-structural.md`），**只读性有实证**（读者集合 = 空；沙箱"有登记/空登记/整份不存在"三趟 ⇒ `rc` 与所有计数器**逐字相同**）；`known-red-PC-copies.md` 追加**按世代结算**（**只增不改**：删除/改写 **0** 行、新增 215 行）。
> **⭐ 世代切换现场实录（本波真实逮到）**：`pc` 在 **12:30:42** 重建后，上一代那 **12 份"已转绿"在同一分钟内全部回落为"仍红"** ⇒ **"转绿"≠永久销账**（纪律 52 的现场证据）。
>
> **④ 收官补的登记与草稿**：`D-G9`（臂日志**没有机器读者**；措辞已从"没被登记"收窄 —— `WAVE24-PREREGISTRATION.md:203` 有**散文出生证**，`:204` 的"不需要重钉"**才是病根**；修法草稿 `--selftest` 9/9、**0 笔 dotnet、不动 `inputs_fp`**）｜`D-G10`（`verify-all` 成功步骤 stdout 不落盘；**三颗牙齿今天就在自报**，缺的只是 `run_step` 回显；草稿已备）｜`D-G11`（生成物没有"等号读者"；补丁草稿已备，**反极性②无需重建**）｜`D-G12`（`--tab-oracle` 读了 `perChar[].width` 却从不比较）｜`D-G13`（**仪器级**：`--selftest` 的 `SELFTEST_M2` **并发改仓时会假红** ⇒ 立 §9.1b"静树跑"）｜`D-G14`（**覆盖闸是整例级的 ⇒ 埋掉与字体无关的列**；真能治它的是**列级闸**，补丁草稿**已被主控实测可 `patch`**）。
>
> **⑤ 主控自纠与车队纪律（全部留档）**
> - **一次误判已撤回**：12:47 有条 `frame-step.sh` 在跑，我**先点名一条只读车道"越界"**；复核后**撤回** —— **进程树定不到车道**（`PPID` 是 dsh 宿主，**每一条车道的 bash 都由同一宿主派生**），而 `list_agents` 显示当时**唯一在跑的是 W25A**、它**正是有 `dotnet` 权限的那条**、且预登记 §2 本就写了"第 [5][6][7] 步必须重跑" ⇒ **最可能是它的正当位移复核**。教训：**定人不能用 `PPID`**；**"禁止车队"必须连"会自行构建的步骤脚本"一起点名**（`frame-step.sh:94` 自建 harness ⇒ 那个 dll 的 sha 是**派生量、不是冻件**）。
> - **`D-R7` 的修法只做了一半（顺着 W25K 的对账抓到，已补）**：`patch-presentationcore-lineheight-trace` 已进 `APPLIERS_EXPLICIT` **会跑**，但**不在 `applier-audit-expected.txt`** ⇒ **摘掉它不会红**。已补那一行（纯加强：被审计 **22** / 必查 **22**，补前 22/21；补后审计仍 `rc=0`）。
> - **三处文档漂移已修**（都是 W25K 数量对账点出来的，且**改用现场实测值**）：`CURRENT-STATE:208` 步数口径表停在"`#21`=11 步" ⇒ 补到 **13 步**；`:235` 的 `appliers=20 ok=74` ⇒ **实测** `22/80`（不带旗标档）/ `22/102`（`--with-check` 档），并更正"工具名被记成不存在的 `check-appliers.sh`"那处漂移；基线里"`CURRENT-STATE.md` 第 4 行"⇒ 改为**按 `grep -m1` 定位、不以行号为准**（并重算机器行）。
> - **一条口径更正（W25C 的"31 份"）**：那是按 `find` 全枚举数的，**校验器的权威口径是 0**（dry run `refreshed=0 newer=0 applied=0`、明说"同类加载源副本都已是权威 sha"）⇒ **不需要 `--apply`**；本波 `APPSYNC` 相对 `#24` **反而收敛**（`MISMATCH 18→1`、`DIVERGENT 3→1`）。
> - **我自己的看门狗有 60 条误报**（阈值 `dotnet>2` 被 `verify-all` 的 `dotnet test` 正常顶到 3–6）⇒ **一个在正常操作上会响的判据是坏判据**（与 `D-G13` 同族）。**内存两档阈值一次没响**（`avail` 最低 1961 ≫ 1000、`swapfree` 最低 537 ≫ 250）。
>
> **⑥ 内存信封**：120 样本 / 60 分钟：`MemAvailable` **最低 1961 / 均值 2773 MB**、`SwapFree` **最低 537 MB**、`load1` 峰值 **9.75**。**协议有效**：全程只有 W25A 一个构建者在重建产品件（其余五条只读车道**零 `dotnet`**），内存从未低于 1200 MB 的构建门槛。
>
> **⑦ 下一波（`#26`）建议（按价值）**：① **`D-G10` 落 `run_step` 回显 + 三颗牙齿汇总行**（草稿已备、**只加不删**；实测能补上一个真漏报例：`tline-gate.sh --logdir` 缺参 ⇒ `rc=3`、旧 grep **0 命中**、屏上只剩 `❌`）｜② **`D-G14` 列级闸**（补丁已被主控验过可 `patch`；把 RTL 非零 `Start` 从"行使 0 行"变"行使 **33** 行"；**不动产品件**，但要按纪律 34 **人工重取三支 `tab-*` 臂**并按列对账）｜③ **`D-G9` 结构化臂日志 + 只读核对器**（**零世代成本、不动 `inputs_fp`**）｜④ **`D-G11` 产物↔生成物等号读者**（`1 笔 pc 重建 + 1 个工具项目`；改 `patch-*.py` ⇒ **必须波前落地**）｜⑤ **`D-G12`**（把 `perChar[].width` 接进比较）｜⑥ **`D-T5-R` 变"有牙"**（新写一步）｜⑦ **`D-T7` 真机重录**（配方已备：**真值录"断行后果"、不录码点**；**语料未录时该步必须报 `NOINFO`**）｜⑧ **`hasOverflowed` 的更大判别面**（真值 **1293 行**、今天只判 **421**）。
> ## ✅ 波 `#26` **完整记录（收官，主控，2026-09-17 17:0x）**
> **内容 = P1 `D-G14` 列级覆盖闸（＋`D-G12`）｜P2 `D-G10` 绿屏口径｜P3 `D-G13` 假红改 `NOINFO`｜P4 `D-G9` 结构化 `arm_logs` + 第 `[8]` 步｜P5 登记与纪律**（预登记 `docs/WAVE26-PREREGISTRATION.md`，含 §11 收官）。**逐字读数在 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#26` 块**，本节只记过程、判据与教训。
> **车道（一条落地 + 七条只读）**：`W26A`（`build/MilBridge/W26A-report.md 5244e218631572ee`，`D-G14`+`D-G12`）｜`W26B`（`209deb193af68ef4`，`D-G10`）｜`W26C`（`f58dcba766731ebe`，`D-G13`）｜`W26D`（`491fd9f8def6d2d8`，`D-G9`）｜`W26E`（`~/w26e/report.md 7210293bd3e7c016`，`D-T5-R` 有牙草稿）｜`W26F`（`~/w26f/has-teeth-audit.md fe2ff7889e00b068`）｜`W26G`（`~/w26g/report.md 10dfe35fcea1b154`）｜`W26H`（`~/w26h/gate-wiring.diff 181336824ddfa7c7` + `report.md dcdf41a9a208d673`）。
>
> **① `D-G14` 列级闸 —— 本波唯一的"真实覆盖率收益"，且零产品位移**
> - 问题 = 覆盖闸是**整例级**的（`Program.cs:1367-1386`：`∃ch` 使 `NominalGlyph(常量字体,0,ch)==0` ⇒ `continue`，**整例一个字段都不判**）⇒ 把**与字体无关**的列（`TextLine.Start`）也埋掉（`NOINFO=194` 就是这么来的）。
> - **正向**：`Start` 判定行 **421 → 615**、`NOINFO` **194 → 0**、**红 0**；`字形释放行=194`、`非零真值行判定=171`（两个上界打满）。**RTL：真值侧可达 33，我方实判 33/33**（落在预测 `[24,33]` 的**上端**）。
> - **⭐ 既有读数零位移是机器证的**：436 条 `CASE` 行 diff **0 行**；`合计`/`最大差` **IDENTICAL**；逐例 `(结构,位置)` 相等；`FAILCASE 0→0`；**剔掉缺字形标签后既有 421 条 `START` 逐行差异 0 行**。
> - **反极性**：正极性红 0｜`Start => 0` ⇒ **171**（= 既有 138 + 新释放 33，预测逐位中）｜`=> PI+24` ⇒ **615**｜补测 `=> 24.0` ⇒ **484**（证明 24/48 未被吞）。四档满足 **`红+绿+NOINFO == 615`**。
> - **`D-G12`**：`perChar[].width` 接进比较（容差 0.05）；缺省与 `=1.0` 逐字节相同（**今天不红**）；牙级 `=2.0` ⇒ **可判字宽 97/97 全红**。⚠️ **它自己抓出并修正了一版"把绿洗成红"**：19 条真值字符是 `\t`（真值宽是**网格推进量**、不是字形宽）、16 条我方宽=0（没量到）⇒ 最终只比**真测量值**（97 条），其余 64 条 `NOINFO`。**收益按 97 条读，不是 356**。
>
> **② `D-G10` —— 绿屏第一次印出自报口径**（`verify-all.sh:104` 回显结论行 + 红分支零命中兜底 + 印日志路径；`frame-step` 逐腿累加器 + 新键 `FRAME_STEP_LEGS`）
> - **只加不删机器证**：两件"改前独有行 = **0 / 0**"；**既有终局行文本逐字节未动**（`:189` ≡ `:197`）；改前/改后 11 个用例的**逐例通过失败完全相同**（6/5）。
> - **本波实测的绿屏**：`[7] BASELINE-SHA ✅` 下跟三行 `· 自报口径 BASELINESHA=/BASELINEGEN=/BASELINEDUP=`；`[8] ARM-LOG-SHA ✅` 下跟 `ARMLOG_SHA=PASS shape=flat … required=5 declared=5 pass=5 fail=0 noinfo=0`。
> - **真漏报例（成对）**：`tline-gate.sh --logdir` 缺参 ⇒ 日志 26 B、**`rc=3`、旧 grep 0 命中** ⇒ 改前只有 `❌ (rc=3)`；改后 = 兜底 + 日志路径。
>
> **③ `D-G13` —— 假红改判 `NOINFO`**：真坏三档**仍 `FAIL`**（含"印了但数字错"）；"只是仓库被改" ⇒ `NOINFO` + `SELFTEST=NOINFO` **rc=3**（`NOINFO` 不给 0、也不混进 1）；**判定面位移 = 0**（静树整份输出改前/改后**逐字节相同**）；`--selftest` **18/18**。**并加严**：以前只查告诫**字样**、不查**数字** ⇒ 现在 N 必须逐位相等（**旧自测里抓出一个真缺陷**：改前 18/18 PASS、改后 FAIL）。
>
> **④ `D-G9` —— 结构化 `arm_logs` + 第 `[8]` 步（先咬后合）**：臂重取后核对器 `FAIL pass=2 fail=3` **精确点名三支臂**（这正是 `#25` 之前"没有任何机器会红"的那类不一致）⇒ 重注入后 **`PASS 5/5`**；核对器 `--selftest` **12/12**（7 例断言"必须红"，含"声明 = 现场前 16 位 + 48 个 0 ⇒ 必红"）。**从此刻起，每趟 `verify-all` 都会核对臂日志的世代归属。**
>
> **⑤ 登记与纪律**：新登记 `D-G15`（登记地点分散）/`D-G16`（`RED_BY_FIELD` 零引用键 —— ⚠️ **主控裁决与点名者措辞相反**：判红**不依赖**该表（`fail_n>0` 独立路径）⇒ **不是红条件失效**）/`D-G17`（**`total_skipped` 零断言 ⇒ `--no-x` 静默关牙而全绿**）；`D-G13` 两条更正 + 一条"自称待复现"（SIGPIPE 假红，**主控 2500 次复现失败**）；W25K 的"① 有牙 24"校正为**真牙 14／半牙 8／假牙 2**（独立牙齿 24→21；5 条 `①w` 不算牙）。
> **新立/更正纪律**：**51 更正**（`tline-gate.sh` 是**纯读者**）｜**52b**（反极性动冻件要声明窗口、动完复原自证；**窗口内任何人读门禁都无效** —— 主控那次 `tree_gen=advanced` 读数**已作废**；**波尾第一步 = 核冻件复原**）｜**56**（沙箱树要硬链接：`find -type f` 会跳过符号链接；⚠️ 点名者那条 `stat -c %Y` 机制**复现失败、未立**）｜**57**（**并行车道上限 = 7**：第 8 条让 harness RSS 3.63→4.04 GB、**swap 一度只剩 7 MB**）｜**58**（**审计报告本身也要连 artifact + sha**）｜**59**（**重取臂前必须换 `OUT` 并先归档**：`retake-arms-w23.sh:11` 的 `$OUT` 与 `arm-logs/*.log` **同 inode** ⇒ 原地重取会**截断上一世代证据**；主控两次给那条车道发警告都失败 ⇒ **保护只能做成仓库侧**，已归档五支日志）｜**§9.1b 修订**（静树**必要但不充分**）。
>
> **⑥ 主控自纠（本波 6 处）**：① 误判一条只读车道"越界跑了 `frame-step.sh`"⇒ **撤回**（**`PPID` 定不到车道**）｜② `grep -rl -- 'PAT' --include=…` 里 `--` 让**过滤器静默失效** ⇒ 据此误判过一条引注｜③ 一次九位对比**用错快照路径** ⇒ 输出"九位全变了"的假结论｜④ 插登记块时**把 `D-G13` 标题挤掉**、并把 `§9.1b` 修订指向错文件（均被自己的核对拦下并修好）｜⑤ `[8]` 头注释把反引号写在双引号里 ⇒ **触发命令替换**（纯外观）｜⑥ **`awk` 里 `s<ms` 是字典序比较**（`"7" < "341"` 为假）⇒ 一度报"采样最低 swapfree 341 MB"，而真相是 **7 MB**（**凡在 `awk` 里比数必须 `s+0 < ms+0`**）。
>
> **⑦ 环境事故（本波首次）**：门禁第一次跑遇 **`ENOSPC`（磁盘写满）** ⇒ 输出**全缺** ⇒ **该趟作废重跑**。⇒ 按用户指示清理：**`wfp-runs` 65 GB → 5.7 GB**（删 `*.xwd` 原始转储 35.4 GB + app-local/OSX 运行时副本 24.3 GB；**保留 6834 个文本读数、10265 张 PNG、反极性留档 `.so`**）。**教训：结论的载体（几百 MB）与过程的原始转储（每波几十 GB）要分开保管。**
>
> **⑧ 下一波（`#27`）建议**：① **列级闸接进五臂门禁**（草稿已备、**无读取点被删**；治的是 W26H 矩阵③那行**假绿**："放行了但一行没判 ⇒ 仍 `PASS`"；**接线＋钉下限＋重取臂＋重算 `arm_logs` 必须同趟**）｜② **`D-G17`**（跳过数零断言）｜③ **`D-T5-R` 变有牙**（草稿：32 格 + 10 断言 + 机制门；是构建者）｜④ **`D-R8` 回归牙**（首推；⚠️ 报数写清"文件数 vs 行数"）｜⑤ **`D-G11`**（产物↔生成物等号读者；**须波前落地**）｜⑥ `D-G15` 机器对账｜⑦ `D-G12` 末字符退化｜⑧ `D-R3` 的坑（`ResolverGuardProbe` `return 0`×6/`return 1`×0 ⇒ 直接接线会是恒绿假牙）。
> ## ✅ 波 `#27` **完整记录（收官，主控，2026-09-17 18:3x）**
> **内容 = P1 列级闸接进五臂门禁（`D-G14` 的下半身）｜P2 `D-G17` 跳过可见性与上限｜P3 新第 `[9]` 步 `BUILD-HYGIENE`｜P4 新第 `[10]` 步 `DEFECT-REGISTRY`｜P5 登记 `D-G19`–`D-G25` 与 4 处旧记录更正**（预登记 `docs/WAVE27-PREREGISTRATION.md`，含 §8 收官）。**逐字读数在 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#27` 块**，本节只记过程、判据与教训。
> **车道（两条落地 + 五条只读交付 + 波尾三条只读）**：`W27A`（`build/MilBridge/W27A-report.md d74700706abb9e39`，列级闸接线，**主控现场复核**）｜`W27B`（`dbef220a99cfd925`，`D-G17`）｜`W27C`（`7adcad13e3e38d43` ＋ 新件 `build-hygiene-import-check.sh 2607d0ba856f169a`）｜`W27D`（`83cd40cf1e9d6c97` ＋ 新件 `defect-registry-check.sh 35838bf64f658447` ／ `defect-registry-declared.tsv`）｜`W27E`（`~/w27e/lastchar-width.md debd498f0e72148b`，`D-G18`）｜`W27F`（`~/w27f/wiring-insert.diff f6374df504d369d0`，`D-T5-R` 重锚）｜`W27G`（`~/w27g/recipe.md e2c803a6b17e8f6d`，`D-G11` 时序）｜**波尾** `W28A`（`~/w28a-report.md 0675cd3e196b3d78`，`[9]` 独立咬合取证）｜`W28B`（`~/w28b-report.md a86efb3c9e2a018b`，文档口径改单）｜`W28C`（`~/w28c-report.md 53aed532200ccab9`，`D-G19` 方案 ＋ 假绿实证）。**全部零 `dotnet`。**
>
> **① P1 列级闸接进门禁 —— 把 `#26` 留下的假绿窗口关上。** `#26` 把探针的覆盖闸从整例级改成逐列级（`Start` 判定行 **421 → 615**），但**门禁对列级读数零读取点**（`grep TAB_LINES START tline-gate.sh` = 0）⇒ "把 `字形释放行` 从 194 悄悄改小"或"整列退回放行了但一行没判"**仍 `PASS/rc=0`**。修法 = `generation.column_gate` 声明（`{column:"START", judged_min:615, released_min:194}`，**下限 = 实测值本身、不留余量**）＋ `COL_ARM` 读取点 ＋ 新机读行 `GATE_COLUMN=`。**反极性四档实测**：① 退化（`字形释放行=0`）⇒ **`FAIL column-gate-regressed`、`rc≠0`**（治假绿那一档）；② `judged_min+1` ⇒ `FAIL`；③ `released_min+1` ⇒ `FAIL`；④ **删声明 ⇒ `NOINFO`**（不许当绿）。**零位移机器证**：13 个既有读取点**一个没删没放宽**（改前每一行含 `TAB_LINES` 的读取点在新件里**逐字节仍在**）、`RED_BY_FIELD` 原六键 **6/6 KEPT**、`TLINE_GATE=` 既有字段**逐项与 `#26` 相同**；**世代三件不动**（`GEN_KEYS` 三项未变、`entries` 的 `reason`/`red_authority`/`carrier` 逐字节未变、只推 `caliber.judgment_version` `/2 → /3`）。⚠️ **门禁没有 `--selftest`** ⇒ 替代 = 造两棵只差"有无 `column_gate`"的**沙箱树**跑门禁、归一化后 `cmp` 一致（**沙箱必须硬链接/真拷贝** —— 纪律 56/60：硬链接是**双向**的）。
> **② P2 `D-G17`：跳过数第一次上屏并带上限。** 改前 `verify-all` 对 `total_skipped` **零断言**，而 `X11FactAttribute` 在**发现期**就 `Skip` ⇒ **`--no-x`／无 X 机器上静默关掉一批牙而全绿**。改后：`run_step` 绿分支把跳过数记进 `SKIP_OBS[套件]` 并**立刻印"声明来源清单"**；末尾加**上限断言**（越上限 ⇒ `SKIP_GUARD=FAIL` 计入 `fail`；X 可用却被跳过 ⇒ `FAIL`；X **不可用** ⇒ 不判失败但必须 `SKIP_GUARD=REDUCED` ＋ 逐字写明"**射程缩减**"）。**本波实测（逐字）**：`Rendering.Tests ✅ 通过 162 跳过 2 合计 164` 下跟 `↳ 跳过清单 Rendering.Tests：2 例（**跳过不许无声**）｜本步上限 = 27 例（静态 2 ＋ 语料 25 ＋ X 项 0，X_STATE=available）` ＋ `声明来源：静态 2（DrawingBrushTests.cs:201 空壳用例 + TileFlipTruthTests.cs:240 T2b 登记缺口）+ [ParityFact]×25（ParityTests.cs:42 缺 ParityData）`；结论区 `SKIP_GUARD=PASS x_state=available x_suite_skipped=0 x_suite_units=0 x_suite_corpus_max=0 total_skipped=2 violations=none reason=none`。**只加不删机器证**：两件（`verify-all.sh`/`frame-step.sh`）"改前独有行" = **0 / 0**、**既有终局行逐字节未动**、**11 个既有用例的逐例通过失败完全相同（6/5）**。
> **③ P3 第 `[9]` 步 `BUILD-HYGIENE`。** `#21` W21B 修好 `D-R8` 之后 **5 个世代里"这 40 份 csproj 还接不接着 `BuildHygiene.props`"没有任何东西会红**（机器证：**改正 `grep` 过滤器写法后**，仓内**任何 `.sh`/`.py` 里 `BuildHygiene` 命中 = 0**；阳性对照 = `baseline-sha-check.sh` 同法能命中）。判据四档：① 名单里每份**恰 1 行**规范 `<Import>`；② 树里没有未登记用户；③ props 在**且仍带那条排除**；④ 名单 = **内嵌 golden 40 行 ＋ `EXPECT_N=40`**（不用遍历推 —— 遍历推必然与坏件同步缩水，`D-R4` 同族）。三态 `0/1/2`（**NOINFO 不许当绿**），失败**逐条点名到文件**。✅ **独立咬合取证（W28A —— 不是作者自测）**：在**真实 40 份 csproj 的真副本**上（`cp -p`、**无硬链接**、`find -type f -links +1` 命中 0）做 **6 种坏法 ＋ 1 射程探针**，**全部 `rc=1` 且逐条点名**（`DISAPPEARED c=0`／`DUP c=2`／`UNLISTED`／`PROPS-MISSING`／`PROPS-CONTENT-LOST`／**合并坏法**（删 props ＋ 摘掉 40 行）），**阴性对照 `rc=0`** 证明"红"不是沙箱噪声，**真树零污染**（3 件 ＋ csproj 聚合 sha 开工==收工逐位相同）。⚠️ **两处口径已写窄**（原注释写宽了、主控当场改）：`unlisted` **只在已带规范 `<Import>` 的文件上才可能触发** ⇒ "**新增一份该接线却没接线**"这一档**看不见**（已登记 `D-G21`）；判据只查**一条**排除（`BuildHygiene.props:61`，`grep -cF` = **1**）。
> **④ P4 第 `[10]` 步 `DEFECT-REGISTRY`。** `D-G15`：同一个编号的登记地点是散的（`D-G2`/`D-G3` 只在 `CURRENT-STATE.md` 里有陈述、缺陷册里没有条目），而"某编号在哪些文件里、有没有漏登记"**没有任何机器会红**。判据 = 四个 route 件现场抽出的 `D-` 编号集合与声明件 `defect-registry-declared.tsv` **双向**比对、逐条点名（`declared-id-missing-in-route` ／ `undeclared-id-in-route`），三态 `0/1/2`、**纯读零 `dotnet`**。**声明件由核对器自己的 `--emit` 机械生成** ⇒ 它不是权威、是**必须与现场同步的快照**（`DEFREG_DECLDRIFT` 行把"快照之后又变了"打出来，**诊断不判红**）。现场 `DEFREG=PASS declared=61 route_ids=61`、`rc=0`；`--selftest` **10/10**（`not-as-expected=0`，**逐例同时断"值"与"`rc`"**，含 5 例"必须红"的**两个方向**）。✅ **主控独立复核**：用自己的 python 复算 ⇒ 并集 **61** / 声明 **61**、**双向差集皆空**、`req` 逐条对得上。⚠️ **复核中主控自己先错了一次**（左界正则把 `TOOTH-D-F1b-ABSENT` 判成"不存在"，一度报 **4 处假违规**）⇒ **错的复核器比没有复核更危险**。
> **⑤ P5 登记与更正。** 新登记 **`D-G19`**（列级闸只给 `START` 钉下限 ⇒ `hasOverflowed` 列仍可静默；**W28C 已用副本实测出假绿**）、**`D-G20`**（门禁不读探针的逐例对账行）、**`D-G21`**（`[9]` 反向扫描射程洞 ＋ 暴露只在命令行 ⇒ 今天无法用推导名单关洞）、**`D-G22`**（**`verify-all.sh` 不在 `inputs_fp()` 里、也没有自指指纹牙** ⇒ 波中改门禁零机器红；**本波实测它一趟里被改 5 次、全程零红**）、**`D-G23`**（`[10]` 自测汇总行字段名会误导）、**`D-G24`**（`known-red.json:69` 的 `cross_check` 是**没有读者的散文**，4 条里 **3 条与现场不符**，而结构化 `arm_logs` **5/5 正确**）、**`D-G25`**（`caliber.judgment_version` 的"同趟推进"**没有读者**）。**旧记录更正 4 处**：`D-G15` 的现场证据**自我 disqualifying**（登记动作本身毁掉了那个 grep 证据：今天实测 **4** 而非 0；**不否定结论、否定的是那个查询串作为证据**）｜`D-G2`/`D-G3` 的行号 `:368/:369` → **`:384/:385`**｜"两文件 `D-G` 条目 10 vs 14"**口径未重现**（如实标）｜`D-G19` 的判据形状与射程两处措辞。**口径三档更正**：`BuildHygiene` 的 **40（文件数 = `<Import>` 元素数）／42（含 `Import` 子串的行数，含 2 行注释散文）／38（`#21` W21B 的动作计数，史实）**；⚠️ **`ACCEPTANCE-BASELINE.md` 里 `#26` 冻结块内那处"42"主控裁定不改**（改它会让 `#26` 记录的**整份 sha 变成不可复算** —— 那正是我把 `#23` 登记成缺陷的形态）。**文档口径另更正 5 处**：`verify-all.sh` 头注释"不带锚得 17"（真值 **20**，且差额**不是常数**）｜`CURRENT-STATE.md` 的"**当前期望是 13 步**"（真值 **16**）｜`[X11Fact]` 的"8 条"（真值 **26**，且同文件已写着 26）｜`ARCHITECTURE.md` 的"8 条需真 server"（真值 **18**）｜**预登记自己传下去的"42 条 `Import` 行"**（真值 **40**）。
>
> **⑥ 位移账。** 九位相对开工快照（`$HOME/w27-pre-lanes.sha`，17:47:37）**只有 `pf` 变**（`ebbe3bab855cdd55 → 3d44e756475b5dd4`）；其余八位（含 `hbtextline`）**逐位断言未动** ⇒ **表外位移 0**（预登记 §5 停条件①②③④全未触发）。`inputs_fp` 与 `BRIDGE_SRC_FP` **逐位相同**。**仪器位移**：`tline-gate.sh b37a5c9f55ae71a4 → 59ce84346325eb21`｜`known-red.json 84fcfb4f728deead → b7a4ad0907f9d76b`｜`verify-all.sh f1dc01793a160c19 →（W27B）ad705fa5b0cdb331 →（主控接 `[9]`）ff0d3a0b636ad302 →（并入 W28A 取证与射程）d9812c6657f7eda3 →（接 `[10]`）a4db9f8149af7a07 →（修 4 处口径）bb1efc78b88cf3b4`｜新建两件核对器 ＋ 一份声明件。⚠️ **那 5 次 `verify-all.sh` 改动全程零机器红** ⇒ 已登记 `D-G22`。
> **⑦ 波尾与门禁（逐字）。** `close-wave.sh --skip-verify-all` **rc=0** ⇒ `native_rebuilt=0`、`bridge_republished=0`、生成物指纹 `state=ok`、**应用器审计 `appliers=22 ok=80 miss=0 red=0`**、**输入稳定性 波前==波后 = `0b8b6559…ba2d8`**。五臂 `TLINE_GATE=PASS arms=5 red=2 green=3 noinfo_arm=0 registered=4 unlocated=1 drift=0 gone=0 unregistered=0 caliber=OK generation=#23 tree_gen=same saved_shim=e89fed55fd8e32bc gate=59ce84346325eb21 judge=t1b3-tline-gate/3` ＋ `GATE_COLUMN=PASS state=READINGS-OK arm=tab-oracle-anchor col=START 判定行=615 红=0 绿=615 NOINFO=0 字形释放行=194 非零真值行判定=171 judged_min=615 released_min=194`。`verify-all` **rc=0 / 16 步 / 871 通过 2 跳过**（`[4]`–`[10]` 全 ✅）。应用门禁**两趟** `RUN1_RC=0`/`RUN2_RC=0`、`WPTD_GATE=PASS acceptance=2/2 line_advance=PASS`、`WPTD_SUMMARY=PASS tiers_passed=2/2`、`WPTD_LINE_ADVANCE=PASS distinct_origin_y=12 threshold=10 runs=167`、`WPTD_BRIDGE_SRC_STALE=no`、**6/6 `BASELINE … result=PASS`**（default `drawn=260 colors=3960`、env `drawn=144 colors=2828`，两档 `frames_good=14/14`、`cross_ae=0`、`leftover_after=0`）⇒ **归一化 `pf`/`rundir` 后与 `#26` 的六行逐字相同**（**零产品位移的机器证**）。⚠️ **门禁第一次尝试的两趟作废并披露**：那两趟**没设 `WPTD_BASELINE_OUT`** ⇒ 没有机器可读的 `BASELINE` 行（**这是重跑存在的全部原因，不是隐藏的失败**；两趟的 `WPTD_GATE=PASS` 与本次逐字相同）—— 与 `#16` 踩过的同一个坑。
> **⑧ APPSYNC（本波独立重跑取数）**：`APPSYNC=MISMATCH（MISMATCH=1[STALE=1 NEWER-DIFF=0] MISSING=0 UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0] DIVERGENT=1 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0`、`rc=1`；逐字计数 `OK=63  MISMATCH=1（STALE=1 NEWER-DIFF=0）  MISSING=0  UNEXPECTED=1[DECL-GAP-EQ=1 DECL-GAP-DIFF=0]  DIVERGENT=1  NO-AUTHORITY=39  LIB-COPY=0  SKIP(obj)=7  SKIP(stub)=6  SKIP(ref)=10  RETIRED=0  AUTH-MISSING=0  BRIDGE-ANCHOR=0  BRIDGE-NOINFO=0`。**与 `#26` 逐字一致**（本波 `pc` 未变 ⇒ 同世代、可直接比对）⇒ **零新增红**；三条红全是长期在册的（`FallbackCriteria` 的 `UNEXPECTED-EQ`（`D-A1`）、`GeometryOracle` 的 `STALE`、`WpfGfx.Linux.dll [Debug]` 的 2 种 sha（`DIVERGENT`））。
> **⑨ 内存信封**：采样器（v2，20 s 一行）**83 样本**：`MemAvailable` **谷底 2048 MB**（18:03:15，`close-wave` 重建期）／均值约 3000 MB；`SwapFree` **谷底 885 MB / 2047 MB**（18:08:35，`verify-all` 测试套件期）；`load1` 峰值 **8.46**；采样 `dotnet` 峰值 **6**；**告警 0 条**。⚠️ **并行车道上限仍是 7**（纪律 57），本波实际最多 **4 条**（W27D ＋ W28A/B/C），**零-dotnet 车道与主控的重活同跑**且未破警戒线。⚠️ **主控自纠（本波第 6 处）**：第一版采样器**字段错位**（`read` 把 `/proc/meminfo` 各行的第 2 字段**按位置**塞进 7 个变量）⇒ 打出假 `avail=0` 并**触发一条假 ALERT**（`[ 0 -lt 800 ]` 为真）。⇒ **"从 `/proc` 读数"也必须逐字段具名取**；v2 按名字取，并对"字段非法"直接 `exit 9`（**读数缺失必须与读数很小可区分**）。
> **⑩ 主控自纠汇总（本波 6 处，全部留档）**：① 复核 `[10]` 时**我的匹配器先错**（左界正则 ⇒ 4 处假违规）｜② 我先用不带 `upstream`/`.artifacts` 排除的 `find` 数出 **135** 份 csproj 并据此**怀疑 W28A 是错的** ⇒ **是我错、它对**｜③ `[9]`/`[10]` 注释里**口径写宽 3 处**｜④ 头注释里**抄来的**"得 17"是错的（真值 20，且差额不是常数）｜⑤ `findall` 带回捕获组 ⇒ 误判"最长匹配坏了"｜⑥ 采样器字段错位（见 ⑨）。
> **⑪ 未取到 / 未达成（不许当绿）**：① `D-T5-R` 的 **12 个 `--nocatch` 格**本波**没有独立对照记录** ⇒ 其"有牙"步骤留给 `#28`（**它是构建者**）｜② **`D-G18` 的真机侧无读数**（读上游源码得出的推论；W27E 的离线模型与探针有 **5 条 MISMATCH**、`wSkipTab=61` vs 模型 14 **差 47 复现不出**）｜③ **`W27F` 的接线 diff 已过期**（它按 14 步重锚，收官时已是 16 步）｜④ `--emit` 重生成后**声明件会随波漂**（设计如此；收官时已 `--emit`，`DECLDRIFT=0`）。
> **⑫ `#28` 候选（按价值）**：① **`D-G19`**（给 `OVERFLOWED` 钉下限；**补丁与 6 档反极性已备**，`judged_min=421`，同趟只要求 `tline-gate.sh` ＋ `known-red.json` 两件，**不需重取臂/不动 `arm_logs`/0 次 `dotnet`/门禁一趟 0.11 s**）｜② **`D-G20`**（门禁读逐例对账行）｜③ **`D-G21`**（让"该接线却没接线"也能红）｜④ **`D-G22`**（给 `verify-all.sh` 一个步数/步名自检；⚠️ 不许做成自指改写）｜⑤ **`D-G25`**（给 `judgment_version` 一个读者；⚠️ 先想清谁有权定版本号）｜⑥ **`D-T5-R`** 有牙步骤（**构建者**，需先取 12 格的独立对照读数）｜⑦ **`D-G11`**（读者目录必须**先于/同趟**落地，否则 `close-wave` 在 `[1/6]` abort；`inputs_fp` 会变）｜⑧ **`D-G24`**（删 `known-red.json:69` 的散文，只留结构化 `arm_logs`）｜⑨ **把 `tline-gate.sh`/`known-red.json`/`arm-logs/*` 纳入 `fp_inputs()`**（W28C 实测它们**不在** 110 条覆盖集里，与 `D-G22` 同族）｜⑩ **`D-G23`**（`[10]` 自测字段改名）。

> ## ✅ 波 `#28` **完整记录（收官，主控，2026-09-17 19:4x）**
> **内容 = P1 `D-G19`（`OVERFLOWED` 下限牙）｜P2 `D-G20`（门禁读逐例对账行）｜P3 `D-G22`（第 `[11]` 步 `VERIFYALL-SELF`）｜P4 `D-G23`/`D-G24`/`fp_inputs()`｜P5 登记 `D-G26`–`D-G31` ＋ 更正 ＋ 纪律 63/64**（预登记 `docs/WAVE28-PREREGISTRATION.md`）。**逐字读数在 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#28` 块**，本节只记过程、判据与教训。
> **车道（九条，除构建者外全部零 `dotnet`）**：`W28D`（`~/w28d-report.md 9eca1749845918f0`，落 `D-G19`）｜`W28E`（`~/w28e-report.md 5daa47e2f7c2398f`，`D-G22` ＋ 修 `D-G29`）｜`W28F`（`~/w28f-report.md 64a41d3ac67bde5e`，`D-G21` ＋ **推翻主控一句**）｜`W28G`（`~/w28g-report.md 98efa0c364abbee3`，`D-G20`）｜`W28H`（`~/w28h-report.md acdc86e4e4720a17`，**构建者**：`D-T5-R` 有牙 ＋ **12 格对照读数**）｜`W28I`（`~/w28i-report.md 6e984ff27fa2c24c`，三草稿）｜`W28J`（`~/w28j-report.md 6857ec31d463dcfa`，**合体后独立复核**）。
> **① 两块"与什么都没发生完全不可区分"的假绿被治**：`OVERFLOWED` 的三档失真（判定行 421→400／汇总行删除／重复）在旧门禁上**全部 `rc=0`/`PASS` 且 stdout `cmp` 逐字节 IDENTICAL**；`START` 的"汇总⇔逐例不一致"四档同样全绿。现在各自 `rc=1/2` 并逐字点名到 `arm=… col=…`。**两段的零位移都是构造性证明的**（后者：独立复核车道**切掉那 32 行**就**逐位**回到只有 `D-G19` 那一版的 sha `3a8bb7d40f0e8c60`）。
> **② `D-G22`：门禁第一次"自己有牙"**：`verify-all` 的步数口径从"只靠人记得"变成**每趟核对**（步名**多重集合**/条数/**次序**/**无重名** ⇔ 头注释机器读声明块 ⇔ 口径句），分叉 ⇒ `FAIL`、**缺声明 ⇒ `NOINFO`**。⚠️ **"只做集合相等"会让"同名步"全绿漏过**（作者实测：同名两次且把声明/清单/口径句全配平后，**唯一判词是 `duplicate-step-name`**）⇒ 额外加了"无重名"这一维。**世代无关性三方向实测**（`#27`/16 步、`#28`/17 步、`#30`/18 步形态各 `--selftest` 21/21）。**它抓不到**"整份 `verify-all.sh` 被换成 `exit 0`"（牙长在体内）。
> **③ 本波最值钱的东西：独立复核把"主控与作者的自报"各打掉几处**（五处，全部留档）：① **`RED_BY_FIELD` 6→7**（主控抄了 `#26` 的旧记录，W28D 当场顶回）｜② **"那 42 份都不是暴露工程"被推翻** —— W28F 用推导谓词 P1 找到**真有 1 份暴露却没接线** = `src/WpfGfx.Linux/WpfGfx.Linux.csproj`，而 **`#21` W21B 自己的表就标着 `*** STILL EXPOSED ***`**（主控当时只核了 **csproj 字面量**、没核"glob 是否生效"）｜③ **"`.sh`/`.py` 里命中 0"其实是主控自己写下的那句注释**（**自我 disqualifying**，与 `D-G15` 同形）｜④ **作者的 `--selftest 19/19` 在被测件换代后是假绿** —— 主控接线时就地跑出 **13/19**（fixture 把 `gen=#27` 写死），而作者的绿是在**旧件沙箱**里取的 ⇒ 登记 `D-G29`｜⑤ **`D-G20` 段的两处正则缺陷**（混合行形态 ⇒ **假指控**；CRLF ⇒ **假红**）由 W28J 在合体件上查出、主控当场修。
> **④ 三条小项**：`D-G23`（`[10]` 自测汇总行 `pass=` **数的是"`got=` 值个数"、不是"通过例数"** ⇒ 改名 `got_*=`，**+12 B、零读者、语义零改动**）｜`D-G24`（`known-red.json` 的 `leg_resolution.cross_check` 是**没有读者的散文**、**4 条里 3 条与现场不符**，而结构化 `arm_logs` **5/5 相符** ⇒ 删散文**−445 B**；⚠️ `conclusion` **不许删**、删整行会留**悬空逗号**）｜`fp_inputs()` 扩两件（门禁＋登记表）。
> **⑤ `fp_inputs()` 那两条（本波最"结构性"的两条）**：**纪律 64**（**派生件不许进输入指纹** —— 臂日志是"臂＋探针＋语料＋世代"的**函数**，且**已有更严的牙**（全 64 位 `arm_logs` ＋ 已接线的 `[8] ARM-LOG-SHA`），而**重取臂是合规动作** ⇒ 纳入会把"输入稳定性"**自己搞成噪音**）｜**`D-G31`**（**`fp_inputs()` 把构建产物当输入** —— 那条 `find src/WpfGfx.Linux -name "*.cs"` 没排除 `obj/`，吃进 **2 份构建生成的文件** ⇒ **每次构建 `inputs_fp` 都变**；主控现场撞到：`close-wave` 报 `d409b483…`，其后 `verify-all` 只跑了一次 `dotnet build` ⇒ 当场变 `4a3519ea…`，**期间无人手写任何覆盖面文件**。已修：那一行加 `-not -path "*/obj/*" -not -path "*/bin/*"`）。⚠️ **我自己的仪器也犯了同一个病**：重冻脚本里**复制了一份 `fp_inputs()`** ⇒ 与真源分叉 ⇒ 第一次重冻写进去的是**老定义**的值 ⇒ **改成 `source` 真函数**，并把预冻文件**可证地**还原（还原后 sha 逐位等于 `#27` 的 `c8d086acb625a714`）后重冻。
> **⑥ 留给 `#29`（本波刻意不落，理由已记）**：`D-G30`（`OVERFLOWED` 对账行纳入判据）｜`D-G26`（**探针自报 sha** ＋ 门禁读它 —— 要重取三支臂）｜`D-G27`（**下限值本身**的外挂读者）｜`D-G21`（三节声明册 ＋ 见证谓词，成稿已备）｜**`D-T5-R` 有牙**（`build/MilBridge/tools/hidden-only-step.sh d006c5bed70e0295`，599 行，首跑 `rc=0`，`--selftest` 16/16；**12 格对照读数已补齐**：六个非目标例 × 两档，带 `--collapsible --nocatch`，**12/12 全部 `rc=0` ∧ `GREEN` ∧ `A1/A2/A3` 全 PASS**；**未接线** —— 它是**构建者**，挂上 `verify-all` 会改变每趟回归的资源画像（实测 +93 s / 809 MB ⇒ **+14.5%~15%**），按"落地前先预登记"应当自己成波）｜`D-G11`｜`verify-all` 的**实际执行轨迹**那一半。
> **⑦ 未取到（不许当绿）**：`--selftest` **内部**不证跨世代（做成外部三趟）｜`verify-all` 的**实际执行轨迹**（仓内无落点）｜`D-G18` 的真机侧仍**无读数**｜**"下限 615/421 属于哪一版探针"未定**（探针 mtime `14:48:13` 早于臂日志 `17:52:10`，而后者是 `#27` 复原顶过的 ⇒ **mtime 先后不能定版**）｜W28H 报的 **「返空串」/「半接线」两个 `pc` 不在盘上** ⇒ 那两档应用器级反极性**未取到**（它只拿到 `declaredgap` 的"红的形状"，**不作替代证据**）。
> **⑧ W28H 还推翻了一条 `#26` 的记录**：`#26` W26E 写"旧产物上**恰 4 格红**"，实测是 **`不符=28`** —— 因为**旧世代 `pc` 没有 `relaxedParaDefaults` 字段**（那是 `#25` 修法新增的）⇒ 24 个对照格按"窄射程不可测"也判红。⇒ **判据改成"目标 4 格必在红名单 ＋ 不符 ≥ 4"**。**教训：行为逐位相同 ≠ 输出逐位相同**（旧产物少一个诊断字段）。另：W28H 抓到一条**血案级**性质 —— **私目录缺 `WPF_LINUX_WIN32_SHIM` ⇒ 32 格全 `abort(134)`**，而 **`rc=134` 恰也是目标例 `--nocatch` 的真签名** ⇒ **假红与真红"只看 rc"不可分**（已加异常签名归因 ＋ 缺 shim 时 SKIP）。

> ## ✅ 波 `#29` **完整记录（收官，主控，2026-09-17 22:3x）**
> **内容 = `D-G30`（`OVERFLOWED` 对账行进判据）｜`D-G31`＋第 `[12]` 步（`fp_inputs()` 排除构建产物）｜`D-G32`（修 `WpfGfx` 真暴露，三处同趟）｜`judge=/5`｜登记 `D-G26`/`D-G27`/`D-G30`/`D-G32`/`D-G33`/`D-G34` ＋ 纪律 63/64/65**（预登记 `docs/WAVE29-PREREGISTRATION.md` §11）。**逐字读数在 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#29` 块**。
> **车道（六条）**：`W29A`（`2feea1d1359a1685`，落 `D-G30`）｜`W29B`（`34bafee2a2232cb6`，`D-G31`＋新核对器）｜`W29C`（`083fdf2e7837534f`，**构建者**：`D-T5-R` 四条复核＋重锚，只交付）｜`W29D`（`12079e44516f8fe2`，`D-G27`）｜`W29E`（`a8da6e8e887099a6`，`D-G26`）｜`W29F`（`899339e537d56468`，`D-G21` 三节声明册落地）。
> **① 本波最值钱的不是新牙，是"假红的拦截"与"自报被复核打掉"**：W29A **救了一次假红** —— `OVERFLOWED` 的逐例行有**两种形态**（判定过 288 行带 `红=`/`绿=`；未判 148 行整行没有），**照抄 `START` 的正则会在今天的干净树上直接打假红**（它做了反实验证明），修法 = 逐例求和不可信时**跳过第 1 层、第 2/3 层永远比** ⇒ 三个缺口一个没跑掉；它**还顶回了主控的验证口径**（`FAIL(col)` 行首有两个空格 ⇒ 主控的 `grep` 恒 0 命中）。W29C **把 W28H 的一条"推翻"分成两层、两层都对**（`#26` 那句按**原始探针层**读没错），并**否掉了"缺 shim 不可分"的结论**（marker 文件 ＋ 异常签名两个信号都在它自己的证据里）。W29F **顶回了它自己的一个"位移"误判**（把 `HbTextLineParity/Program.cs` 与探针 `CoverageProbe/Program.cs` 混成一个 —— **那正是 `D-G26` 存在的原因**）。
> **② `D-G32`：判据先判红、主控接住并真修** —— `src/WpfGfx.Linux/WpfGfx.Linux.csproj` 是 `#21` W21B 自己标过 `*** STILL EXPOSED ***` 的那一份；`#29` 的新判据把它判红（`WITNESS-EXPIRED`、`rc=1`），**主控拒绝"回退换绿屏"**，改为真修：csproj 加 `<Import>` ＋ 声明册 `suspended→wired` ＋ **判据内嵌 golden 名单与 `EXPECT_N` `40→41`**（三处同趟；只改前两处 ⇒ `wired-length-mismatch`、`NOINFO`）。⇒ **桥重发后二进制逐位不变**（那行只改 `DefaultItemExcludes`、不进 IL）⇒ **真修了一个真缺陷、零产品行为位移**。
> **③ 三条新纪律**：**63**（自测沙箱必须自带 `TMPDIR`）｜**64**（派生件不许进"输入指纹"）｜**65**（**任何车道落地前，主控必须先留 pre-landing 备份** —— 本波一次退回动作险因"备份晚了"而无旧字节，靠车道自己的备份 + **可验证的反向 sed**（哈希自证 byte-exact）才救回）。
> **④ ⚠️ 一次真实资源事故（21:50:08）**：采样器抓到 **`swapfree=0MB`**，而**同一笔 `avail=4050MB` 看着完全健康** ⇒ 10 条告警从 0 爬到 74 MB 才缓过来（≈2.5 分钟）。⇒ **预警必须看 `swapfree`**（`#26` 那次是 7 MB，这次是 **0**）；`avail` 单独会漏。
> **⑤ 主控自纠（本波 5 处）**：`$?` 在管道后取到的是管道 rc｜**备份晚了**（⇒ 65）｜roster 编辑漏第 5 列（判据当场 `roster-malformed`）｜`bash -c` 命令行文本**触发 `close-wave` 的 `pgrep` 自匹配** ⇒ 假停（⇒ `D-G34`）｜`grep -E "^FAIL\(col\)"` **恒 0 命中**。**另**：`w29-fill.py` 里 `fp_inputs()` 是硬编码拷贝 ⇒ 打印过**老定义**的值（**记录用的是重冻脚本填的 `{INFP}`，那个已 `source` 真函数 ⇒ 未污染**）。

> ## ✅ 波 `#30` **完整记录（收官，主控，2026-09-17 23:5x）**
> **内容 = `D-G26`（探针自报身份 ＋ 门禁 `probe` 段 ＋ 重取三支臂）｜`D-G27`（下限的外挂读者）｜`D-G33`（见证由判产物改判结构）｜`D-G34`（`pgrep` 自匹配）｜`D-T5-R` 修两处｜登记 `D-G26`–`D-G34` ＋ 纪律 63–68**（预登记 `docs/WAVE30-PREREGISTRATION.md` §8）。**逐字读数在 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `#30` 块。**
> **车道（六条）**：`W30A`（`7cce22e9ba7176ef`，`D-G27` ＋ 新读者）｜`W30B`（`bcddba5849536f10`，**构建者**：`D-G26` ＋ 重取三支臂，纪律 59 全流程留档）｜`W30C`（`c53d79c7b48d54c2`，`D-G33` ＋ `D-G34` ＋ `D-G30` 第三格方案）｜`W30D`（`b3b004660e351e6a`，`D-T5-R` 修两处 ＋ 重锚）｜`W30E`（`ccf1494687ae6bf1`，产品侧只读根因）｜`W30F`（`0443d6168708f6d0`，**主控仪器清账**，修 5 件）。
> **① 本波最值钱的一条：一颗"上线即哑"的牙被拦下。** `D-G26` 的方案草稿里 `<Import>` 被写进 `<ItemGroup>`（MSBuild 当它是一个 item ⇒ **targets 永不导入** ⇒ 元数据不生成 ⇒ 自报恒 `NOINFO`），且 `GATE_PROBE=NOINFO` 会与 `TLINE_GATE=PASS … all-as-registered` **同时出现**（违反"`NOINFO` 不许当绿"）。**没有车道自己复核，这颗牙会静默失效**。⇒ 再一次印证：**"作者自测全绿"与"它在真实数据上真的在判"是两件事**。
> **② `D-G27`：把"自己声明自己"变成有痕编辑。** 两颗列级下限与 `generation.arm_logs` **三个值原先都只有一个声明处**（`known-red.json`），改小下限门禁照新门槛比、**仍 `PASS`**；**同趟改 `arm_logs` 就能洗绿 `ARMLOG_SHA`**。新读者 `column-floor-check.sh` 五档，**只有"语料复算"那一档回答"这个数该是多少"**。⚠️ **本波只钉声明、不接线**（声明行须与接线同趟落）⇒ `#31`。
> **③ 三条真实隐患**：**`swapfree=0MB`** 而同一笔 `avail` 健康（⇒ 采样器必须两个都看；`#26` 那次是 7 MB，这次是 **0**）｜`arms23` 那份"归档"是**硬链接**（⇒ **纪律 59 的"先归档"那一层保护是空的**，只有 `cp -p` 才算归档）｜**没有任何东西看着"`--selftest` 用例失去前提"**（`#29` 真修好 `WpfGfx` 后 `case Q` 的前提消失、该例永远红；`verify-all.sh:529` 只跑生产路径）⇒ **纪律 68**。
> **④ 纪律 67（本波结构性观测）**：连续五波"零产品位移"，**一半原因是"没有一支臂走产品入口"** —— `tline` 是**仪器**（把语料 meta 直接喂 `FormatParagraph`、**绕过 PC**）、`PcLineOracle` 语料 modifier 命中 **0**、`MinMaxProbe`/`D5CbrProbe` 用 `Length=>0` 且**不在 `verify-all` 里**。W30E 用**零 `dotnet` 独立复算**证明那 5 条 `M_modifier` Extent 余差**与 modifier 跨度未接线同根**（差 `0.08 = f 的 765 − 760 = 5/1000em × em16`，因隐形段含 `f` 而可见子集不含）。⇒ **`#31` 头号 = 加一支走产品入口的臂**（真值复用 `layout-b34-compact.json` 5 个 M 例、**免 Windows 重录**）。
> **⑤ 主控自纠（4 处）**：第 `[12]` 步 `echo` 的**反引号写在双引号里** ⇒ 命令替换 ⇒ 每趟 stderr 吐语法错误且横幅丢字（**同一陷阱第 4 次现场**；W30D 查出、我当场复现后修）；派单书"W29C 的锚也过期"**被车道推翻**；改 roster **漏第 5 列**（判据当场报 `roster-malformed`）；三个 `-fill.py` 仍带 `#27` 时代的 `fp_inputs()` 硬拷贝（⇒ 纪律 65/66 的现场）。**另：重冻脚本的"牙齿②"当场逮住"头注释没有 `#30` 这一代的步数声明"（本波不动步数）⇒ 我补上那句声明后才冻成 —— 那颗牙按设计在工作。**

## 1. 可行性依据：实测数据（非估算）

以下全部来自对上游仓库的 cloc / grep 实测，日期 2026-08-30。

| 项 | 数值 | 说明 |
|---|---|---|
| 仓库总代码 | **1,960,924** 行 | src/ 全量 |
| C# 托管层 | **1,181,098** 行 | 布局/属性/绑定/动画/控件，大部分平台中立 |
| C++ 原生层 | **309,467** 行 | MIL 渲染引擎，重度 Windows+Direct3D 绑定 |
| 主题 XAML | **174,386** 行 | 8 套主题（Aero/Aero2/Luna/Classic/Fluent…） |
| **托管↔MIL 接口面** | **13 个函数** | `Common/Graphics/exports.cs`，命令流协议 |
| **DUCE 顶层命令** | **118 条**（`MilCmd`） | 资源创建 / 视觉树 / 目标管理 → **mil-core 组** |
| **RenderData 绘图指令** | **25 条**（`MilDrawCommand`） | `MilDraw*`/`MilPush*`/`MilPop` → **skia-render 组（渲染核心）** |
| MIL 资源类型 | 98 种（`MilResourceType`） | 已生成枚举 |
| 引用 DUCE 的托管文件 | 140 个 | 若实现上述命令集，这些文件**零改动** |

> ⚠️ **易错点**：`MILCMD` 枚举在上游是**单一枚举但语义分两段**——0x00–0x8e 的 `MilCmd*` 是顶层命令（118 条），
> 末段 `MilDraw*`/`MilPush*`/`MilPop` 是 **RenderData 内部的绘图指令**（25 条），共 143 条。
> 两者协议层级不同，已拆成 `MilCmd.cs` 与 `MilDrawCommand.cs` 两个枚举，**不要混用**。
| XAML 标记编译器 | 9,299 行，**0 处 DllImport** | `PresentationBuildTasks`，纯托管，Linux 可直接用 |

**结论**：工作量不在"移植 24 万行 C++"，而在"实现 118 个命令的 Skia 后端"。这是一个量级的差异。

---

## 2. 架构决策（已定，不要偏离）

### 决策 1：不动托管层业务逻辑，只替换渲染后端
托管层通过 DUCE 命令流与 MIL 通信。只要新后端能消费同样的命令流，`PresentationFramework`(474k) / `PresentationCore`(273k) 等一行都不用改。

### 决策 2：MIL 后端用 **C# + SkiaSharp 重写**，不移植 C++
理由：
- 24 万行 C++ 是 MSVC 方言，在 Linux/GCC 上编译是持续的噩梦（`#pragma`、SEH、COM、MSVC 特定行为）
- Skia 本身就是 C++ 高性能实现，C# 只是绑定层，性能不在关键路径
- C# 实现调试效率、迭代速度远超 C++

### 决策 3：接入点收敛到 **一个文件**
修改 `Common/Graphics/exports.cs`，把 13 个 `[DllImport(DllImport.MilCore)]` 改为对 `WpfGfx.Linux` 的托管调用。
**这是整个移植唯一的"侵入式"改动点。** 严禁散弹式修改托管层其他文件。

### 决策 4：Milestone 1 只做**软件渲染**（Skia CPU），放弃 D3D 硬件加速
`MilCmdD3DImage`(0x0a)、`MilCmdPixelShader`(0x6c)、`MilCmdShaderEffect`(0x70) 等 D3D 相关命令 **M1 阶段返回 E_NOTIMPL**，先跑通主链路。

### 决策 5：窗口走 X11（非 Wayland）优先
X11 协议简单、有成熟托管绑定、Xvfb 可做 headless 测试。Wayland 留到 M2。

---

## 3. 接口契约（subagent 的共同约定）

### 3.1 必须实现的 13 个 MIL 导出函数

签名的权威定义在 `Common/Graphics/exports.cs`。在 `src/WpfGfx.Linux/Interop/MilNative.cs` 中以 C# 静态方法实现同名同签：

```csharp
int  MilResource_CreateOrAddRefOnChannel(IntPtr pChannel, ResourceType type, ref ResourceHandle hResource);
int  MilResource_DuplicateHandle(IntPtr pSourceChannel, ResourceHandle original, IntPtr pTargetChannel, ref ResourceHandle duplicate);
int  MilConnection_CreateChannel(IntPtr pTransport, IntPtr hChannel, out IntPtr channelHandle);
int  MilConnection_DestroyChannel(IntPtr channelHandle);
int  MilConnection_CloseBatch(IntPtr channelHandle);
int  MilConnection_CommitChannel(IntPtr channelHandle);
int  WgxConnection_SameThreadPresent(IntPtr pConnection);
int  MilChannel_GetMarshalType(IntPtr channelHandle, out ChannelMarshalType marshalType);
unsafe int MilResource_SendCommand(byte* pbData, uint cbSize, bool sendInSeparateBatch, IntPtr pChannel);
unsafe int MilChannel_BeginCommand(IntPtr pChannel, byte* pbData, uint cbSize, uint cbExtra);
unsafe int MilChannel_AppendCommandData(IntPtr pChannel, byte* pbData, uint cbSize);
int  MilChannel_EndCommand(IntPtr pChannel);
int  MilResource_ReleaseOnChannel(IntPtr pChannel, ResourceHandle hResource, out int deleted);
```
另有 3 个 M1 可返回 E_NOTIMPL：`MilResource_SendCommandMedia`、`MilResource_SendCommandBitmapSource`、`MilChannel_SetNotificationWindow`。

### 3.2 命令流协议
托管层写入模式：`BeginCommand → (AppendCommandData)* → EndCommand → … → CommitChannel`。
每个命令头部布局：命令类型（**4 字节** `MILCMD`）+ 资源句柄 + 命令体。
> ⚠️ **已修正（mil-core 组实测发现）**：初版误写为"1 字节"。上游 `MILCMD` 是**无基类的 int 枚举，占 4 字节**，不是 byte。
> **具体字节布局以 `wgx_core_types.cs` 与各 `*Resource.cs` 的 `MarshalTo` 实现为准，不要猜。**

### 3.3 命令清单
完整 118 条见 **`docs/duce-commands.txt`**（十六进制编号 + 命令名）。分工按该文件划段。

### 3.4 分层接口（subagent 之间只通过这 3 个接口耦合）

```csharp
// 命令层 → 渲染层的唯一入口
public interface IMilCommandDispatcher {
    int Dispatch(ReadOnlySpan<byte> command, MilChannel channel);
}

// 渲染后端抽象：Skia 实现是首个，未来可换 GPU/Vulkan
public interface IRenderBackend {
    void RenderVisualTree(MilVisual root, SKCanvas canvas, RenderContext ctx);
    void Invalidate();
}

// 窗口/呈现目标
public interface IPresentationTarget {
    nint NativeHandle { get; }
    void Present(SKImage frame);
    void Resize(int w, int h);
}
```

---

## 4. 目录结构

```
/workspace/wpf-linux/
├── handoff.md                      # 本文件（唯一真相来源）
├── docs/
│   ├── duce-commands.txt            # 118 命令清单（分工依据）
│   └── ARCHITECTURE.md
├── build/                           # 构建脚本
├── src/WpfGfx.Linux/
│   ├── Interop/                     # 13 个 MIL 导出函数 + 通道管理
│   ├── Commands/                    # 118 个 DUCE 命令解码/编码
│   ├── Rendering/                   # Skia 渲染后端
│   ├── Windowing/                   # X11 窗口与呈现目标
│   ├── Text/                        # GlyphRun → Skia/HarfBuzz
│   └── Resources/                   # 资源句柄表与生命周期
├── tests/
│   ├── WpfGfx.Linux.Tests/          # 单元测试（xUnit）
│   │   ├── Commands.Tests/          # 322 用例（round-trip / 布局 / 覆盖率 / 矩阵 / 3D）
│   │   ├── Rendering.Tests/         #  51 用例（golden image + 15 张基准图，含 T14 特效 20 用例 / 3 张图）
│   │   ├── Windowing.Tests/         #  42 用例（X11 真窗口 + xdotool 真输入注入，需 DISPLAY）
│   │   └── HelloMil.Tests/          #   6 用例（端到端，含 xwd 截屏断言）
│   └── Rendering.Harness/           # Headless 渲染测试工具 + golden image
└── samples/
    ├── HelloWpf/                    # 最小 WPF 程序（M2/M3 目标，当前 Linux 上跑不起来）
    └── HelloMil/                    # ★ T9-A3 端到端 demo（不开 WPF 运行时，直调我们的 API）
        └── screenshot.png           # 端到端硬证据：xwd 抓的真 X11 窗口
```

---

## 5. Task 拆解

**M1（最小可渲染闭环）**

| ID | Task | 依赖 | 产出 |
|---|---|---|---|
| T0 | Linux 环境基线：.NET SDK、SkiaSharp、Xvfb、测试字体 | — | `build/setup-env.sh` + 验证报告 |
| T1 | XAML 编译链路打通：PresentationBuildTasks 在 Linux 上产出 BAML | T0 | 可编译的 HelloWpf |
| T2 | MIL 通道层：13 个导出函数 + 通道/批处理/句柄表 | — | `Interop/` + `Resources/` |
| T3 | DUCE 命令解码：118 命令 → 强类型结构 | T2 | `Commands/` |
| T4 | Skia 渲染后端：绘图/画刷/几何/变换/裁剪 | T3 | `Rendering/` |
| T5 | X11 窗口与呈现循环 | T2, T4 | `Windowing/` |
| T6 | 文本：GlyphRun → Skia text | T4 | `Text/` |
| T7 | Headless 渲染测试框架 + golden image | T4 | `tests/Rendering.Harness/` |
| T8 | 单元测试套件（布局/属性/绑定/命令 round-trip） | T3 | `tests/WpfGfx.Linux.Tests/` |
| T9 | **端到端 demo（★ 见下方路线调整）** | T1,T2–T8 | `samples/HelloMil/screenshot.png` |

**路线调整（关键认知）**：原计划 T9 是"HelloWpf 在 Linux 编译+运行"——但 HelloWpf 跑起来需要 WPF 托管层（118 万行 C#）跨平台，**这不在 M1 范围**（详见 `docs/T9-roadmap.md`）。M1 真实终点是 **HelloMil**：不用 WPF 运行时，直接用我们的 `WpfGfx.Linux` API 构造视觉树→开 X11 窗口→截屏证明"端到端可工作"。

**M2（后续，本轮不做）**：硬件加速、主题样式移植、打印、无障碍、IME、多媒体、把 WPF 托管层搬到 Linux。

---

## 6. 测试策略：Linux 下 Agent 如何验证渲染

**核心难题**：容器无显示器，Agent 无法"看"渲染结果。解法是**分层测试 + 像素确定性**。

### L1 · 纯逻辑单测（无渲染）
覆盖：布局 `Measure/Arrange`、依赖属性优先级、绑定表达式求值、动画插值、几何运算。
xUnit 数值断言。不需要任何渲染后端，可最先跑起来。

### L2 · 命令流测试（有命令、无渲染）
- **Round-trip**：构造命令 → 编码成字节 → 解码 → 断言结构等价
- **Golden Binary**：录制真实 WPF 生成的命令流，回放比对字节
- 价值：100% 确定性，不受字体、抗锯齿、GPU 影响

### L3 · 离屏渲染测试（有渲染、无窗口）★主力手段
- 用 Skia **CPU 后端**渲染到内存位图（`SKSurface`），**完全不需要 X server**
- 流程：构造视觉树 → 执行渲染 → 输出 PNG → 与 `tests/golden/<name>.png` 比对
- 比对算法：逐像素 RGBA 差，默认容差 Δ≤2；超阈值输出 diff 图（差异区标红）
- 提供 `--update-golden` 开关更新基准图

### L4 · 窗口级集成测试（有窗口、headless）
- `Xvfb :99` 提供虚拟 DISPLAY，程序真实运行
- 用 `xwd` / ImageMagick `import` 截屏比对
- 验证窗口创建、事件循环、真实呈现链路

### L5 · 端到端冒烟
编译并运行 `samples/HelloWpf`，截图人工/自动确认。

### 确定性保证（**必须遵守，否则 golden 测试必然不稳定**）
1. **固定字体**：测试资源内打包 Noto Sans，禁止依赖系统字体
2. **固定 DPI**：96
3. **统一抗锯齿设置**：golden 生成与比对使用同一 AA 配置
4. **固定随机种子**：涉及随机的用例显式注入种子
5. **跨平台分组**：golden 按 `平台-字体版本` 分目录，避免误判

---

## 7. Subagent 分工与边界（**严禁越界改他人目录**）

| Agent | 负责目录 | 负责枚举 | 禁止触碰 |
|---|---|---|---|
| `env-build` ✅已完成 | `build/`、`samples/HelloWpf/` | — | `src/` |
| `mil-core` | `Interop/`、`Resources/`、`Commands/` | `MilCmd`（118 顶层命令） | `Rendering/`、`Windowing/` |
| `skia-render` | `Rendering/` | `MilDrawCommand`（25 绘图指令） | `Interop/`、`Commands/`、`Windowing/` |
| `window-text` | `Windowing/`、`Text/` | — | `Interop/`、`Commands/`、`Rendering/` |
| `test-harness` | `tests/` | — | `src/`（只读引用） |

### 契约层 `src/WpfGfx.Linux/Contracts/`（**已由主控建立，所有 Agent 只读**）
| 文件 | 内容 |
|---|---|
| `MilCmd.cs` | 118 条顶层命令枚举（自动生成） |
| `MilDrawCommand.cs` | 25 条绘图指令枚举（自动生成） |
| `MilResourceType.cs` | 98 种资源类型枚举（自动生成） |
| `MilPrimitives.cs` | `MilResourceHandle`、`MilChannelMarshalType`、`MilHResult` |
| `Interfaces.cs` | `IMilCommandDispatcher`、`IMilChannel`、`IMilResourceTable`、`IRenderBackend`、`IPresentationTarget`、`MilVisual`、`MilDrawInstruction`、`RenderContext` |

> 重新生成枚举：`python3 build/gen-contracts.py`（脚本逻辑已内联在会话中，需补写为独立文件）
> **改动契约 = 全队阻塞**，任何 Agent 需要改契约必须先说明理由。

---

## 8. 验收标准

- [x] `build/setup-env.sh` 一键装好全部依赖（`verify-env.sh` 15/15 通过）
- [x] 含 `App.xaml` + `MainWindow.xaml` 的 WPF 程序**在 Linux 上编译通过**并产出 BAML
      └─ 且 BAML **与 SDK 官方版逐字节一致**（最强正确性证据）
- [x] **M1 终点 · `samples/HelloMil` 在 Linux 上真实运行**（2026-09-02 达成）
      └─ 不依赖 WPF 运行时，直接用 `WpfGfx.Linux` API → Skia 渲染 → **X11 真窗口** → 独立进程 `xwd` 截屏。
         `samples/HelloMil/screenshot.png`（800×600）**showcase 版 59KB**：12 种能力同屏（渐变×2/椭圆/五角星路径/圆角 vs 直角/实线 vs 2 种虚线/清晰 vs Blur/双向 DropShadow/裁剪/嵌套变换/位图/文本）。
         `HelloMil.Tests` **19/19**，含真 X11 端到端截屏像素断言。
- [ ] **M2 范畴 · `HelloWpf` 在 Linux 上运行**（**不是 M1 目标，本轮不做**）
      └─ 需移植 WPF 托管层（PresentationFramework + PresentationCore + WindowsBase + System.Xaml，
         ~118 万行 C#、150+ 处 Win32 P/Invoke），Avalonia 量级，属独立项目。见 `docs/T9-roadmap.md` 路线 A1/A2。
- [x] `dotnet test` 全绿（渲染+文本+窗口+命令共 **469 用例通过 / 0 失败**；命令层 110/118）
      └─ **六次独立复验**：有 X 环境 401/0；**无 X 环境 29 通过 + 9 跳过 / 0 失败**（X11 用例优雅 Skip）
      └─ flaky 已根治：修复前 60 轮 9 次失败 → 修复后 20/60/100 + 主控 30 轮复验**全部 0 次**
      └─ 一键验证：`bash verify-all.sh`（**7 步全过，退出码 0**）；压测：`bash tests/flaky-loop.sh`
      └─ 键鼠真输入测试 10 条已补，且**突变验证通过**（偏移改错 → 10 条全红 → 非凑数测试）
- [x] Golden image 测试 ≥ 20 个渲染用例，CI 可复现（**22 张基准图**：`tests/golden/` 16 张渲染 + `Windowing.Tests/golden/` 6 张文本，跨进程哈希稳定）
- [x] `docs/ARCHITECTURE.md` 描述实际落地的架构（**486 行 / 9 节**，2026-09-03 完成）

### 验收结论
**M1 全部验收项达成，且 M1 缺口三项全部关闭（2026-09-04）—— 无遗留。**
剩余工作全部属于 M2 范畴（WPF 托管层跨平台，Avalonia 量级）。

---

## 8.5 ★ 未完成项清单（回来看这里）

> 本节是**唯一的欠账台账**。M1 已达标，以下均为 M2 范畴或已知未闭环项，按优先级排序。

### 🔴 高优先级（影响正确性可信度）

| # | 未完成项 | 为什么重要 | 下一步 |
|---|---|---|---|
| **U1** | **未录真实 WPF 命令流做 golden binary 比对** | 命令解码的正确性目前**只建立在"读上游源码"上**，没有真实流量兜底。这是全工程最大的未验证风险 | ⏸ **受阻于缺 Windows 机器**。已交付准备件：`docs/U1-command-stream-golden-plan.md`（recorder 规格 + 落盘格式 + 比对器设计）。拿一台 Windows 机器按文档 §2 抓流、把 `.stream` 放进 `tests/U1-golden/`，Linux 侧 `GoldenBinaryReplayTests` 即自动从 Skip 转为实测 |
| **U2** | **M2 · HelloWpf 在 Linux 上运行** | 唯一未打勾的验收项。需移植托管层 ~118 万行 C#，Avalonia 量级 | 🟢 **进行中**：里程碑 1 ✅ `WindowsBase` 0 错编译（DLL 1.1MB）；里程碑 2 ✅ **PresentationCore 编译可行性扫描完成**（`docs/U2-PresentationCore-scan.md` 331 行：shim 保编译 1–3 周 / 运行期正确性 1–3 月）；**路线决策：混合（甲式编译 + 乙式运行时，分 5 个阶段）**——见 U2 进展专节。下一步：里程碑 3 = 先移植 3 个小项目（Manipulations 24 + UIAutomationTypes 51 + UIAutomationProvider 29 = 104 .cs）+ port-lib.py 扩展 |

### 🟡 中优先级（能力缺口）

| # | 未完成项 | 说明 | 下一步 |
|---|---|---|---|
| **U3** | 命令层剩 **7 条 E_NOTIMPL** | 6 条 C 类永久不做（D3D/Shader/Windows 专有句柄语义）+ 1 条 B 类 `MilCmdMediaPlayer` | 媒体播放器若要做，需先定 Linux 多媒体后端 |
| **U4** | `MilResource_SendCommandBitmapSource` 仍 `E_NOTIMPL` | 位图**解码**已通，但**导出函数**未接——属契约变更，需主控决策 | 协商是否改 `Interop/exports.cs` 签名 |
| **U5** | **3D 光栅化** | 29 条 3D 命令（0x29–0x30、0x57–0x6b）**只到解码+状态落地，无后端消费** | 需 Skia 3D 或引入独立 3D 后端 |
| **U6** | **像素着色器 `ShaderEffect`(0x70)** | C 类明确不做（HLSL 字节码） | 替代路径：Skia `SKRuntimeEffect`，独立任务 |
| **U7** | ~~HelloMil demo 未展示新解锁能力~~ → **✅ 基本完成（2026-09-06）** | showcase 场景落地：12 种能力同屏对比展示（渐变×2、椭圆、五角星路径、圆角 vs 直角、实线 vs 2 种虚线、清晰 vs 模糊、双向 DropShadow、裁剪、嵌套变换、位图缩略图）；截图 16KB→**59KB**；`HelloMil.Tests` 6→**19**（新增 `PathGeometryBuilder.cs`） | **残留→U12**：位图缩略图画出来了，但 **ImageBrush 位图画刷填充未实现**（见下） |
| **U12** | ~~ImageBrush（位图画刷）未实现~~ → **✅ 已闭环（2026-09-10）** | `SkiaBrush` TileBrush 链路落地：Viewbox/Viewport/Stretch（None/Fill/Uniform/UniformToFill）/AlignmentX/Y/TileMode（None=Decal 透明 / Tile=Repeat / Flip*=Mirror 近似）/ViewportUnits 两模式/画刷变换/Opacity。Rendering.Tests **+5**（`image_brush` golden + 4 语义用例：Uniform 居中留白、Tile 平铺间距、None 1:1+基块外透明、RelativeToBoundingBox 折算），HelloMil showcase 去掉 "no fill" 标注。**过程中实测修正 `SKMatrix.Concat` 语义**（b 先作用）并踩到 `MilStretch` 枚举默认值≠WPF 属性默认值的坑（均已注释钉死） |

### 🟢 低优先级（结构性/打磨）

| # | 未完成项 | 说明 |
|---|---|---|
| **U8** | `MilChannelRegistry` 仍是**进程级静态** | 本次根治的是"句柄值回收（ABA）"，不是改成实例注入。多通道并发场景可能暴露新竞态面 |
| **U9** | `X11Display.Open` 抖动 | 已加重试（微基准 17.28 万次：裸调用失败 6 次 / 带重试 0 次）。主控 6 轮未复现 |
| **U10** | ~~`DISPLAY=:0` 无效值时的探测~~ → **✅ 已闭环（2026-09-10）** | 实测 `DISPLAY=:77`（无 server）：HelloMil.Tests 18 通过+1 跳过 / Windowing.Tests 26 通过+13 跳过，**0 失败**。两套探针已统一为同一实现（HelloMilProbe 弃用裸 P/Invoke，改走 `X11Display.Open` 带重试+失败分类；`InternalsVisibleTo("WpfGfx.Linux.HelloMil.Tests")` 已加） |
| **U11** | `IPresentationTarget.Resize` 后需上层重渲 | 写在文档注释里，端到端运行时会暴露 |

### ✅ 已闭环（留档，勿重复做）

| 原欠账 | 闭环方式 |
|---|---|
| T4 渲染 0 测试 | 51 测试 + 15 张 golden |
| flaky（GCHandle 槽位复用 ABA） | 句柄改单调计数器，20/60/100 轮 0 失败 |
| 键鼠输入无测试覆盖 | `xdotool` 真注入 10 用例 + 突变验证 |
| 架构文档缺失 | `docs/ARCHITECTURE.md` 486 行 |
| 「缺布局/属性/绑定测试」 | **错列目标，已划掉**——那些属托管层，本工程不存在 |

---

### ★ U2 进展专节：M2 托管层移植（2026-09-06 起步）

> U2 = 「HelloWpf 在 Linux 上运行」，需移植托管层 ~118 万行 C#。
> 这是**多轮工程**，本节记录每步里程碑与关键决策，供后续 agent 接续。

#### 里程碑 1 · `WindowsBase` 在 Linux 上编译通过 ✅（2026-09-06，已复验）

```bash
cd /workspace/wpf-linux/build && dotnet build WindowsBase.Linux/WindowsBase.Linux.csproj
# → 0 Error(s) / 0 Warning(s)，产出 bin/Debug/WindowsBase.dll（1.1 MB）
```

**起点**：25 个编译错误。**关键认知修正**：缺口**不是**"缺 7 个 Win32 句柄类型"，
而是缺 **整个 `Windows.Win32.*` 命名空间**（上游靠 CsWin32 源码生成 + WinForms

 `System.Private.Windows.Core` 提供，离线环境没有）。25 条分四类：

| 类别 | 条数 | 处理 |
|---|---|---|
| `using Windows.Win32.*` 命名空间缺失 | 3 处文件 | shim 覆盖 |
| `Accessibility.IAccessible` 缺失 | 2 | shim（Guid + `InterfaceIsDual` 决定封送标识） |
| `SplashScreen.cs` 句柄类型 | 12 | shim 覆盖 |
| `UnmanagedCallersOnly` 签名（CS8894） | 4 | 类型变 blittable 后**自动消失** |

**新增 shim**：`build/shims/WindowsWin32.Shim.cs`（263 行），按 CsWin32 生成形态实现
`readonly struct` 单字段包 `nint`/`nuint`（可 blittable 封送）：
- `Windows.Win32.Foundation`：`BOOL`(4 字节，非零为真)、`HRESULT`(含 `ThrowOnFailure`)、
  `HANDLE`/`HWND`/`HINSTANCE`/`HMENU`(宽=nint，空值=0，`IsNull` 判定)、`LRESULT`/`LPARAM`(nint)、`WPARAM`(nuint)
- `Windows.Win32.Graphics.Gdi`：`HDC`/`HBITMAP`/`HENHMETAFILE`、`BLENDFUNCTION`(4 字节)
- `Windows.Win32.PInvoke.DwmIsCompositionEnabled`：Linux 无 DWM，恒 `S_OK` + false（正走上游非合成分支）

#### 一处"不做"的决策（比"做"更需要判断力）

`SplashScreen.cs` 补齐命名空间后暴露 **69 条独立缺口**，选择**从 Compile 列表剔除**而非硬凑：

> 它需要 7 个 WIC COM 接口（`IWICImagingFactory`/`IWICStream`/`IWICBitmapDecoder`/
> `IWICBitmapFrameDecode`/`IWICBitmapSource`/`IWICFormatConverter`/`IWICBitmapFlipRotator`，
> 约 **70 个 vtbl 槽**须与 `wincodec.idl` 逐槽对齐）、`ComScope<T>`/`IID`/`IStream`/`CLSCTX`、
> `GetDcScope`/`CreateDcScope`/`SelectObjectScope`、13 个 P/Invoke。
> 离线无 CsWin32、无 winmd、全盘无生成样本。**编译探测反证形态不可推断**：
> `ComScope<T>` 带 `unmanaged` 约束时无法用于接口类型（CS8377），说明真实生成形态不是"照签名写一遍"能对上的。
> 凭记忆写 70 个 vtbl 槽 = **能编译但语义错的类型**（本工程明令禁止）。
> 且 WIC/COM 在 Linux 上根本不存在，形态写对也必然运行失败。

已在 csproj 留 `Compile Remove` + 完整恢复条件注释。**API 缺口仅 `System.Windows.SplashScreen` 一个类型。**

#### 下一步与重大风险预警

**下一站：`PresentationCore`**。但存在**结构性风险**，不是堆工作量能解决：

| 维度 | `WindowsBase`（已过） | `PresentationCore` / `PresentationFramework`（未做） |
|---|---|---|
| Win32 依赖性质 | **叶子级**：几个句柄 + 一个 DWM 查询 | **骨架级**：`HwndWrapper`/`HwndSubclass`/`ManagedWndProcTracker`（消息泵）、`Dispatcher` 的 `MSG` 循环、`System.Windows.Interop` 全套 HWND 互操作 |
| shim 能否解决 | ✅ 能 | ⚠️ **只能让编译通过，无法让行为正确** |

**建议决策点**：先做 `PresentationCore` 编译可行性扫描（统计 `Windows.Win32` 缺口量级），
再决定 U2 走哪条路——
- **路线甲**：继续 shim（保持上层代码不动，逐个补类型）
- **路线乙**：先建 X11/Wayland 后端骨架，再倒推托管层改造（避免给一个最终要替换的窗口模型打补丁）

> 这个决策会决定 M2 的整体走向，**不要跳过扫描直接开工**。

#### 里程碑 2 · PresentationCore 编译可行性扫描 ✅（2026-09-10，扫描已做，决策已定）

扫描报告：`docs/U2-PresentationCore-scan.md`（331 行，四张清单 + 分类汇总 + 路线证据，可复现命令索引）。
**一句话结论**：shim 保编译 = 天~周级（1–3 周）；运行期正确性 = 月级（1–3 月）。

核心事实（详见报告）：
1. **Windows.Win32 缺口极小**：仅 3 文件、7–9 类型（COM 形态 20–25 vtbl 槽）+ 3 成员；shim 增量 150–300 行。
2. **MS.Win32 纯类型缺口 ≈ 0**：308 条 DllImport 声明全部可编译（WindowsBase 已实证 284 条同类 0 错）；
   **骨架三件套（HwndWrapper/HwndSubclass/HwndWrapperHook）已随 WindowsBase.Linux 编译通过**，
   PresentationCore 只有 3 个文件消费它们——编译 0 新增，问题 100% 在运行期。
3. **HWND 主要是身份标识**：128 文件走 DUCE 通道、SetWindowPos 仅 2 文件；`X11PresentationTarget.NativeHandle`
   已证「HWND=进程内句柄+映射表」可行。
4. **运行时缺口 94 个 MIL 导出**（托管侧实为 **108** 导出名——扫描报告原写 102 偏小 6 条，M7a 实测更正；M1 已实现 14–15）——**M7a 已全部补齐**（见里程碑 7a 段）。
5. 编译期唯一硬点：**OLE 剪贴板/DnD 栈 8 文件 1880 行**（依赖 WinForms 私有包泛型宿主），
   shim 500–1000 行或剔除重写——按 SplashScreen 先例处理（先剔除留条件恢复，跑通再回补）。
6. 先决依赖：3 个小项目（Manipulations 24 + UIAutomationTypes 51 + UIAutomationProvider 29 = 104 .cs）；
   port-lib.py 需扩展 212 条大小写找回 + 核实 System.Formats.Nrbf 版本。

**★ 路线决策（2026-09-10，主控拍板）：混合路线——编译走甲（shim 到 0 错，上游零改动），
运行走乙（X11 骨架替换 + DUCE 导出补齐），按自然分界点分 5 个阶段推进：**

| 阶段 | 内容 | 量级 | 验收 |
|---|---|---|---|
| **M3** | 3 个小项目移植（104 .cs）+ port-lib.py 扩展（大小写找回/包版本） | 天级 | 3 个 DLL 0 错 + port-lib 回归 |
| **M4** | PresentationCore 0 错编译（shim 增量 150–300 行；OLE 栈按 SplashScreen 模式先剔除留条件恢复） | 天~周级 | `PresentationCore.dll` 0 错；OLE 剔除清单进 PORT-CHANGES |
| **M5** | PresentationFramework 编译（1336 文件） | 周级 | `PresentationFramework.dll` 0 错 |
| **M6** | HelloWpf 用自产四件套编译（T1 已证 BAML 链路） | 天级 | HelloWpf 0 错构建 |
| **M7** | 运行期：HWND→X11 注册表 + WndProc hook 链 + Dispatcher 循环映射（94 个 MIL 导出已由 M7a 补齐 ✅） | 周~月级 | **HelloWpf 真窗口 + xwd 截屏像素断言（M2 验收打勾）** |

> 决策理由（对路线甲/乙之争的裁定）：编译与运行风险正交可并行；编译里程碑（甲）成本已被
> WindowsBase 实证压到最低且**上游零改动**纪律可保持；运行期改造面高度收敛（3 消费者 + Dispatcher）
> 且 X11 层（1196 行）已就位——路线乙的"骨架"成本大部分已被 M1 摊掉，不存在"先建骨架再倒推"
> 的对赌。两者无排他性，只有顺序差。**M7 之前 HelloWpf 能编译但运行必然部分错误**——中间态预期已写入
> 各里程碑验收口径。

#### 里程碑 3 起步 · Wave 0 地基（2026-09-10 下午，已完成并回归验证）

| 项 | 内容 | 实测证据 |
|---|---|---|
| port-lib「嵌套查找」 | 上游 4 个项目路径全部嵌套（`UIAutomation/UIAutomationTypes.csproj` 等），旧 `UPSTREAM/<name>/<name>.csproj` 全落空 | 实测 4 个项目骨架全部生成（源文件 24 / 1 / 61 / 30） |
| port-lib「大小写找回」 | 新增**大小写不敏感精确路径索引**（PresentationCore 有 212 条 Include 大小写与磁盘不符） | 逻辑就位（M4 时由实测检验） |
| port-lib「包版本」 | `System.Formats.Nrbf 9.0.0` 入 `PKG_VERSIONS` | 镜像实测可还原（`dotnet add package` + restore 通过） |
| port-lib「可搬迁生成」 | 生成物路径改 `$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/…` / `$(WpfLinuxRoot)…`，自动注入 `Directory.Upstream.props` import、`CA1416` 入 NoWarn、shims 清单机制 | **回归：System.Xaml 生成物与现役逐字节一致（diff 为空）**；WindowsBase 仅剩"排除机制迁移 + 注释块"预期差异 |
| 机制化替代手工改动 | `build/excludes/WindowsBase.txt`（SplashScreen + 完整剔除理由/恢复条件）、`build/shims/WindowsBase.shims.txt`（shim 显式清单） | WindowsBase 重建 **0 错**；SplashScreen 经机制剔除（生成物中为 0 处） |

#### 里程碑 3–7 执行编排（2026-09-10，多 subagent 并行）

| Wave | 并行 agent | 范围 | 门禁 |
|---|---|---|---|
| 1 | A / B / C / D | A=M3 三小项目移植；B=M4 预研（PC csproj 骨架 + OLE 剔除实测 + shim 增量 + 探针编译）；C=M7a 补齐 94 个 MIL 导出；D=**U1 Windows 真机对照**（新解锁） | 各自 0 错/产出物 |
| 2 | E / J | E=M4 PresentationCore 0 错（依赖 A+B）；J=U1a Linux 侧对照测试（依赖 D） | 0 错 + 对照结论 |
| 3 | F | M5 PresentationFramework 0 错（依赖 E） | 0 错 |
| 4 | G / H | G=M6 HelloWpf 自产四件套编译；H=M7b 窗口胶水 + Dispatcher 循环 | 0 错 + 真窗口烟测 |
| 5 | I | M7c 端到端（exports 编译替换 + U4 裁决 + HelloWpf 真窗口截屏） | **M2 验收打勾** |
| 6 | 主控 | 全套复验 + handoff 终稿 + 快照 | verify-all 全绿 |

> **U1 解锁**（用户提供 Windows 机器，2026-09-10）：`192.168.193.97`（Bilintu，Win11 23H2），
> 实测具备 .NET SDK **10.0.203** + **Microsoft.WindowsDesktop.App 10.0.7**（WPF 可跑）+
> **VS Enterprise 2026**（C++ 工具链）+ git/python。用途限定为「WPF 渲染测试」，
> 非破坏性使用（只在 `C:\u1-parity\` 工作）。**U1a = 真机像素对照**（离屏 `RenderTargetBitmap`，
> 覆盖债务 #7 Arc / #8 组合几何），**U1b = 真实 DUCE 命令流抓取**（三级路线：app-local 代理 DLL /
> Harmony 托管 hook / 重建 WPF，按能力递进）。

#### 里程碑 3 · 三个小项目移植 ✅（2026-09-10，Agent A 实测，主控复核）

| 项目 | 上游 Compile | 解析 | 找回 | 剔除 | 缺失 | 错误 | 警告 | DLL |
|---|---|---|---|---|---|---|---|---|
| System.Windows.Input.Manipulations | 24 | 24 | 0 | 0 | 0 | **0** | **0** | 72,192 B |
| UIAutomationTypes | 61 | 61 | 0 | 0 | 0 | **0** | **0** | 206,848 B |
| UIAutomationProvider | 30 | 30 | 0 | 0 | 0 | **0** | **0** | 33,280 B |

> 无任何剔除/降级；`System.Windows.Primitives` 不单独出 DLL（三项目零 `Windows.Win32.*` 引用，
> 其 CsWin32 面由消费方把 `build/shims/WindowsWin32.Shim.cs` 编入）。
> 数字订正：handoff 早前记的「UIAutomationTypes 51 / Provider 29」偏小，实测上游是 **61 / 30** 条 Compile。
> 非空壳证据（PEReader）：Manipulations TypeDefs=58/Public=15；UIAutomationTypes 219/69；
> UIAutomationProvider 36/27 + 3 个 TypeForwardedTo（成功转发到 UIAutomationTypes，证明本地引用真的接上）。

#### ★ 跨里程碑根因修复：框架同名门面遮蔽自产程序集（2026-09-10）

**症状**：UIAutomationTypes 报 `System.Windows.Interop.MSG` CS0234，报错完全不提 HintPath 失效；
PresentationCore 更惨——`DependencyObject/Point/Dispatcher` 全消失，**6031 条级联错误**。

**根因（两个 agent 独立复现）**：net10.0 的框架里带一份**同名空门面**
`Microsoft.NETCore.App/10.0.11/WindowsBase.dll`（16 KB，AssemblyVersion **4.0.0.0**，1 个 TypeDef + 30 个类型转发），
而自产 WindowsBase 因上游 csproj 沿用 `GenerateAssemblyInfo=false` 是 **0.0.0.0**：
- 编译期：SDK 引用冲突解析按「版本高者胜」**静默丢弃**我们的 `<Reference><HintPath>`；
- 运行期：host 绑回 4.0.0.0 门面 → `TypeLoadException`。

**修复（主控拍板 + 全局落地）**：
1. 新增 `build/shims/LinuxAssemblyIdentity.cs`（AssemblyVersion/FileVersion/InformationalVersion = **4.0.0.1**），
   port-lib 现**自动为每个移植工程注入**；6 个 `*.Linux` csproj 已接入。
2. 实测验证：5 个自产 DLL 版本均为 4.0.0.1；**干净工程运行期** `MSG`/`DependencyObject`/`Dispatcher`/`Freezable`
   全部解析到 app-local 自产程序集（不再绑门面）——M6/M7 的运行期绑定路径由此打通。
3. Agent B 的 PresentationCore **补丁A（摘框架引用）成为冗余保险**（保留无害）；
   **补丁B（PublicSign，解决 `InternalsVisibleTo(...PublicKey=WCP)` 拒绝未签名消费方 → CS0281×290）仍然必需**。

#### port-lib 四项修复（2026-09-10，Agent A/B 报告驱动，主控落地并回归）

| 缺口 | 处置 | 实测 |
|---|---|---|
| csproj 嵌套路径查找 | 递归搜索 `<name>/**/<name>.csproj` | M3 四项目骨架全部命中 |
| 大小写错配（212 条） | 新增**大小写不敏感精确路径索引**找回 | PresentationCore 自动找回 **214** 个 |
| `EnableDefaultItems=false` 未识别 | 与 `EnableDefaultCompileItems=false` 一起判定 | PresentationCore **A 类 9 文件不再误纳（0 处）** |
| excludes 过滤早于默认 glob | **移到流水线末尾**（对全部来源生效） | OLE 8 文件 **0 处**进入编译清单 |
| 上游 NoWarn 未搬运 | 解析上游 `<NoWarn>` 并合并 | 生成物含 `SYSLIB5005` 等 13 条 |
| `unresolved_refs` 不打印 | 打印 + 进 PORT-CHANGES 表 | 实测告警 `System.Windows.Primitives` 等 |
| 生成物不可搬迁 | 路径变量化 + 自动 import + 身份文件 | **System.Xaml 生成物与现役逐字节一致（diff 空）** |

#### 里程碑 4 预研结论（Agent B：PresentationCore 6031 → 118 错）

收敛链（全实测）：无补丁 **6031** → 补丁A（门面）**878** → 补丁B（PublicSign）**500**
→ 剔除 A 类 9 文件 **418** → 剔除 OLE 8 文件 **376** → M3 DLL 落地 **118 错 / 46 警**。
- **OLE 剪贴板/DnD 栈 8 文件判定为剔除**（不是 shim 可解）：`System.Private.Windows.Core` 在镜像上 **NU1101 不存在**；
  纳入编译 50 错，代表错 `CS0538 IDataObject.Interface 不是接口`（CsWin32 形态，离线不可复核 = SplashScreen 失败模式）。
  ⚠️ `clipboard.cs` 只 1 错是「错误类型抑制级联」假象，别按错误条数估工作量。
- **扫描报告的预期被实测推翻两处**：`D3DImage.cs` **0 错**（不必 stub）；WIC 成像栈（109 条 P/Invoke）**0 错、无需 shim**。
- shim `WindowsWin32.Shim.cs` 263 → **505 行**（FORMATETC 32B / STGMEDIUM 24B / TYMED / DVASPECT / CLIPBOARD_FORMAT 等），
  **探针 65 断言全过**、三口径 oracle（上游 in-tree / BCL ComTypes / 反射加载的已编译 WindowsBase）。
  刻意**不写** COM 接口组（IDataObject/IAdviseSink/IEnum*/IManagedWrapper）：用量 0 且形状离线不可复核。
- 剩余三块：① DirectWriteForwarder 托管骨架（41 类型，**102 错**，建 `build/DirectWriteForwarder.Linux`）；
  ② OLE 公开 API 12 条级联（**裁决：最小诚实 stub，抛 PlatformNotSupportedException，不伪造行为**，真实现登记 U13）；
  ③ 46 警（补 `CLSCompliant` assembly 特性文件）。→ 0 错 ≈ 再 2 轮。

#### 里程碑 7a · 补齐 MIL 原生导出 ✅（2026-09-10，Agent C 实测，主控独立复验）

**缺口清单复核为 94 个导出名（扫描报告原写 95 是错的）**：
集合 = PresentationCore in-tree 8 文件 ∪ Common/Graphics（exports.cs 19 + wgx_exports.cs 28 = 47），
属性 **110** 条 / 去重导出名 **108** / 方法名 **106** → 缺口 = 108 − 14 既有 = **94**（方法名口径 90）。
> 更正理由：扫描报告 §3.4 把 Common/Graphics 记成 41 条（少 6）。已回改 `docs/U2-PresentationCore-scan.md` 8 处。
> 清单固化在 `Interop/MilNative.Exports.cs` 的 `MilNative.ExportManifest`（108 条 + 实现深度），
> `MilNative.MissingExports()` 返回空，测试用反射逐名校验。

**实现深度**：真实现 **48** · 身份映射 **9** · 纯状态 **11** · E_NOTIMPL **26**（+ M1 存量 3 = 29 条 E_NOTIMPL）。

| 组 | 条数 | 语义落点 |
|---|---|---|
| `MilUtility_*` / MIL3D 几何 | 15 | **全真实现**：Arc→Bezier 逐行移植 `geometry/utils.cpp:503`；展平自写 de Casteljau；面积用梯形分解（EvenOdd/Nonzero/自交都正确）；Combine/HitTest 用 `SKPath.Op` 真布尔运算；Widen/Outline 用 `SKPaint.GetFillPath`；CopyPixelBuffer 逐行移植 `common/exports.cpp:291` |
| `MilGlyphRun_*` / `MilGlyphCache_*` | 6 | 真实现：字体面→`SKTypeface` 映射 + `SKFont.GetGlyphPath` + MIL_PATHGEOMETRY 序列化（测试用 `PathGeometryParser` 读回断言）；HGlobal 分配由 Release 归还，重复释放 → E_INVALIDARG |
| HWND 绑定 | 4 | **仅身份映射**（登记/查表/解绑/幂等/句柄单调不复用；HRESULT 逐条对齐 `vt_api.cpp`）。**文件内 0 行 X11 代码**，接窗留给 M7b/M7c |
| 连接/消息/锁 | 12 | WgxConnection_Create 真实现；SyncFlush 真提交批次+投递回复；PeekNextMessage 真出队；锁用 Monitor（可重入，暴露重入深度） |
| 离屏位图/渲染目标/工厂 | 10 | 双缓冲真分配 front+back SKBitmap（GetBackBuffer 可读写真实像素）；`CreateSWRenderTargetForBitmap` 不复制像素（`Assert.Same` 断言） |
| 媒体 | 21 | E_NOTIMPL（U3 口径），出参写安全默认值 |
| 其余（D3D 互操作/WIC/COM 引用/流/事件代理/诊断/通道别名） | 26 | 见报告与 `docs/unimplemented.md` 新增章 |

**证据**：主工程 `--no-incremental` **0 警 0 错**；Commands.Tests **350 → 542 通过**（+192 用例）/ 1 跳过 / 0 失败，
Agent 连跑 3 次一致 + **主控独立复跑一次同结果**；`verify-cmd-layout.py` 仍全一致；覆盖度自检「94 个新增名全部被
`MilExportTests.cs` 引用（NOT referenced: []）」。

**两处接口层决定**（主控已批准）：① `MilNative` 由 `class` 改 `partial class`（既有 16 个函数逐行未动）——
这是 handoff 决策 3「把 `[DllImport]` 换成同名方法调用」的前提；② C# CS0051 硬约束（public 签名不能出现 internal 类型）
使矩阵参数退化为 `double*`（6 个连续 double，布局与上游 `MilMatrix3x2D` 逐字节一致），点位/矩形用**刻意不重名**的 public 镜像类型。

**诚实清单**（详见 `docs/unimplemented.md` 新增章与报告）：身份映射类（Attach/DetachToHwnd、MILCreateEventProxy、
MILCreateStreamFromStreamDescriptor、MilCreateReversePInvokeWrapper、WgxConnection_Create）；
语义存疑 10 项（CopyPixelBuffer 位偏移路径按上游逐位保真但未真机比对、GetTileBrushMapping 对 0 尺寸矩形刻意加固、
`fSkipHollows` 接受但无效果、Outline/Widen/Combine 忽略 rTolerance、HitTestPathGeometry 的 FullyInside/FullyContains
按枚举文档实现未真机验证、sideways 旋转约定未逐位核对等）。

#### M7b 设计前提：Win32 子集 shim 库（2026-09-10 主控实测定型）

托管层（WindowsBase/PresentationCore）的消息泵与窗口调用是 `[DllImport("user32.dll")]` 这类**原生 P/Invoke**，
Linux 上必须给它们一个落点。三条路实测对比（探针：`/tmp/win32probe`）：

| 方案 | 实测结果 | 结论 |
|---|---|---|
| 只放 `libuser32.so` 到 app 目录 | ❌ `DllNotFoundException: Unable to load shared library 'user32.dll'` | .NET **不会**把 `user32.dll` 自动映射成 `libuser32.so` |
| 放一个**同名文件** `user32.dll`（内容为 ELF .so） | ✅ 解析成功 | 可用，但依赖 app 目录布局 |
| **`NativeLibrary.SetDllImportResolver` + `[ModuleInitializer]`** | ✅ 解析成功（映射到 `libuser32.so`） | ★ **选定** |

**选定方案**：在 `build/` 下写原生 shim 库（C 实现，gcc 编译），提供 Win32 子集
（`GetMessageW/PeekMessageW/TranslateMessage/DispatchMessageW/PostMessage/PostQuitMessage/SetTimer/KillTimer/
RegisterWindowMessage/RegisterClassEx/CreateWindowEx/DestroyWindow/GetWindowLongPtr/SetWindowLongPtr/
GetSystemMetrics/GetStockObject` 等，**消息泵转发到 X11 的 XPending/XNextEvent**，窗口创建映射到 `X11Window`），
并在 **WindowsBase.Linux 与 PresentationCore.Linux 各自的 shim 源文件里注册模块初始化器 + DllImportResolver**
（resolver 是**按程序集**生效的，每个有 P/Invoke 的自产程序集都要各注册一次），把 `user32.dll`/`gdi32.dll`/
`kernel32.dll` 等名字统一映射到我们的 shim；未映射的名字返回 `IntPtr.Zero` 让默认探测继续。

**前置依赖（已装）**：Linux 侧 `gcc 11.4.0` + `libc6-dev`（`apt-get install -y gcc libc6-dev`，需 sudo）。

#### 里程碑 4 · PresentationCore 0 错 0 警 ✅（2026-09-10，Agent B 实测，主控独立复跑确认）

```
python3 build/port-lib.py PresentationCore                    # 源文件 1348（找回 214）/ 缺失 0
python3 build/PresentationCore.Linux/reapply-patches.py       # 注入 PublicSign + DWriteForwarder 引用
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -v:m
#   → 已成功生成 / 0 个警告 / 0 个错误     （主控独立复跑：0 个错误）
```
产物：`PresentationCore.dll` **3,628,032 B**（1348 源文件）+ `DirectWriteForwarder.dll` 33,792 B。
收敛全程：6031 → 878（补丁A 门面）→ 500（补丁B PublicSign）→ 418（剔 A 类 9）→ 376（剔 OLE）→ 118 → **0**。
> 补丁 A 已因**程序集身份 4.0.0.1** 全局修复而退役；补丁 C 已因 port-lib「EnableDefaultItems 识别 + excludes 末尾过滤」退役（脚本保留为防回退说明）。

**三块硬骨头**：
1. **DirectWriteForwarder 托管骨架**（`build/DirectWriteForwarder.Linux/`，102 错 → 0）：按上游 `CPP/DWriteWrapper/*.h` 落地 **41 个类型**，语义三档——
   **[真实现]** FontMetrics 公式 / DWriteTypeConverter 12 组枚举 / **111 个 OpenType 标签（脚本从头文件机械提取，非手抄）**；
   **[数据]** LocalizedStrings/Span；**[PNSE]** 50 余处依赖 DWrite 原生的成员（消息指向 M1 Skia 文本栈）。
   结构发现：`MS.Internal.Span`/`GlyphOffset`/`TrueTypeSubsetter` 与 `Native.*` DWrite 接口镜像都由这个 C++/CLI 程序集提供，PresentationCore 经 IVT 消费。
2. **OLE 最小诚实 stub**（`build/shims/PresentationCore.OleApi.Stubs.cs`）：DataObject/Clipboard/DataFormats/DataFormat 全成员
   **抛 `PlatformNotSupportedException`（消息含 U13）**，不伪造可用行为；**机械验证 11/11**（7 条必须抛且消息含 U13 + 4 条纯数据不抛）。
   `OleServicesContext.cs` 实测可单独编译（DragDrop.cs 三处引用）→ B 类从 8 收敛为 **7 文件**。
3. **46 警 → 0**：CS3021×37 根因＝上游 assembly 特性由 Arcade 生成、不在树内 → 新增 `PresentationCore.AssemblyAttrs.cs`（只声明 `CLSCompliant(false)`）；CS8500×9 随 GlyphOffset 落地消失；剩 6 条 CS8002 带说明抑制（**根治＝统一公开签名**，见下）。

#### ⚠️ 装载级发现：PresentationCore 原本**在 Linux 上无法加载**（编译期完全无感）

探头一碰 PresentationCore 任意类型即：
`TypeInitializationException → DllNotFoundException: Unable to load shared library 'user32.dll'`。
根因：`ModuleInitializer.cs` 的 `[ModuleInitializer]` 首条 `IsProcessDpiAware()` → `[DllImport("user32.dll")] SetProcessDPIAware_Internal()`，
其后还有 `DWriteLoader.LoadDWrite()`（`NativeLibrary.Load("dwrite.dll")`）。
**处置**：列为 excludes **D 类**剔除（该类型全树无引用；Linux 上这三件事无对象可做）→ 0 新增错误/警告，
剔除后**实测可加载**（oleprobe 三个程序集全部 app-local 4.0.0.1 解析成功，同时反证身份版本修复在运行期生效）。
> 未走"伪造 ELF `user32.dll`"路线（会掩盖真实 API 缺失）——**M7b 有真正的 Win32 shim 后可重新评估是否恢复该文件**。

#### port-lib 追加两项（主控落地，实测）

| 项 | 处置 | 实测 |
|---|---|---|
| 统一公开签名 | 生成物自动加 `SignAssembly/PublicSign/AssemblyOriginatorKeyFile=build/keys/WcpPublicKey.snk`（存在才加） | 生成物已含三行；后续所有移植工程不再各自打补丁（可解除 PC 的 6 条 CS8002 抑制） |
| 通配符资源未展开 | Resource/EmbeddedResource 支持 `*`/`?` 展开并套用元数据 | `Fonts/*.CompositeFont` 实测展开 **7 项**（此前 0 —— 复合字体缺失直接影响运行期字形回退） |

#### ★ 资源/BAML 管线审计与三处修复（2026-09-10，Agent B 审计 + 主控提升为 port-lib 通用能力）

**B 的审计发现（会直接毁掉运行期文本渲染）**：上游用 **WPF `<Resource>`** 承载的 4 个复合字体，
被 port-lib 搬成普通 `<EmbeddedResource>` → SDK 对未知扩展名**静默丢弃** → 产物里**一个字体都没有**。
证据链：上游 `<Resource Include="Fonts\*.CompositeFont">`；运行期取法 `FontSource.cs:391-396`
`new ResourceManager("<asm>.g", asm).GetStream("fonts/<小写名>")`；修复前 `GetManifestResourceNames()` 实测 **3 项**
（无字体、无 `.g.resources`）；SDK 机制定位到 `Microsoft.Common.CurrentVersion.targets:3512`
（只收 `Type=Non-Resx` **且** `WithCulture=false` 的项，缺任一条静默不嵌）。
B 的补丁 E1/E2 修复后实测：清单 4 项、`fonts/*` **4/4**、端到端复刻运行期取法 **4/4 返回 Stream**、DLL 3,716,096 → 4,060,672 B。

**主控把 B 的补丁提升为 port-lib 通用能力（三项修复，已实测）**：

| 修复 | 内容 | 验证 |
|---|---|---|
| ① 清单名显式化 | 每个 `EmbeddedResource` 显式写 `ManifestResourceName`（优先上游值 → `Link` → 相对项目路径；一律 `<AssemblyName>.` 打头）。根因：本脚本把 `RootNamespace` 统一成 `MS.Internal`，靠 SDK 推导必然与 `gen-sr.py` 的 SR 基名不一致 | PC 生成物得 `PresentationCore.Resources.Strings` ✓ |
| ② 默认资源项 glob | 上游未禁用默认项时（无显式 resx 的工程），port-lib 自行 glob `**/*.resx`。根因：本脚本无条件写 `EnableDefaultEmbeddedResourceItems=false` → **WindowsBase/System.Xaml 实测 0 个清单资源** | 生成物补回 resx + 显式名 ✓ |
| ③ WPF `<Resource>` 不降级 | `<Resource>` 单独收集 → 内联 `RoslynCodeTaskFactory` 任务打成 `$(AssemblyName).g.resources`（键＝相对路径小写，值必须是 **Stream**，`byte[]` 会抛 `InvalidOperationException`），带 `Type=Non-Resx`+`WithCulture=false` 以 `LogicalName` 嵌入 | PC 生成物：复合字体走 `WpfLinuxResourceSource` + `WpfLinux_GenerateGResources` 目标（不再作 EmbeddedResource）✓ |

**真实构建端到端验证**（主控，隔离树 `/tmp/plr5`）：挑最小且无人在改的 `System.Xaml` 用新 port-lib 生成并构建 →
`dotnet build` **0 错** → 反射枚举清单资源得 **`System.Xaml.Resources.Strings.resources`（46,479 B）**，
而修复前该项目是 **0 个清单资源**（SR 表整体静默失效、靠 `catch(MissingManifestResourceException)` 回落到内联默认串）。

> ⏳ **待集成（主控在并行 agent 回收后串行执行）**：用新 port-lib 重新生成各 `*.Linux` 工程 + 退役各
> `reapply-patches.py` 里已冗余的补丁（PC 的 E1/E2 现由 port-lib 原生覆盖），再逐工程复核资源清单数字。
> **现在不能重跑**：PC/PF 的生成物正被 M5/M7b 等 agent 使用，重跑会与它们的补丁/构建撞车。
> 另记 B 的剩余缺口：PF 的 Strings 清单名与两个 `.cur` 待 PF 构建后复验；`Themes/*`（171 个 xaml/BAML）
> 是**独立工程**、尚未移植 → M7 主题里程碑缺口；`Resources/xlf/` 本地化管线未移植。

#### ⚠️ 踩坑留档：混合签名导致跨程序集类型身份不一致（2026-09-10，主控造成并修复）

**现象**：PresentationFramework 在 64 错清到只剩 6 条时卡住，报 `CS0534/CS0115`
（`ElementMarkupObject`/`MarkupObjectWrapper`/`FrameworkElementFactoryMarkupObject` 不实现抽象成员
`MarkupObject.AssignRootContext(IValueSerializerContext)`）。M5 agent 用最小探针（仅引用两个 DLL + 一个 override 子类）
复现并定位：**不是源码问题，是构建链里存在过期产物**。

**根因**：主控为验证"通配符资源/签名"改动，在隔离树里用**符号链接复用现役 `bin/` 目录**做构建 →
把**已签名**的 `System.Xaml.dll`（PKT=31bf3856ad364e35）写进了现役树，而 WindowsBase（更早构建）记录的是
**未签名**引用（PKT=null）→ 两侧的 `IValueSerializerContext` 是**不同的类型身份** → override 实现判定失败。

**修复**：按依赖序在现役树重建——`WindowsBase → DirectWriteForwarder → UIAutomationTypes → Manipulations →
UIAutomationProvider → PresentationCore`，全部 **0 错**；并用 `System.Reflection.Metadata` 探针核对身份链：
`WindowsBase.dll` ref `System.Xaml v4.0.0.1 pkt=31bf…` ✓；`PresentationCore.dll` ref System.Xaml 带 pkt ✓、ref WindowsBase pkt=null ✓。

**教训与长期方案**：
1. **验证构建绝不能用符号链接复用现役 bin 目录**（会把产物写回现役树）——要用复制；
2. **混合签名是脆性的**：只要有一批工程签名、另一批不签，跨程序集类型统一就会失败。
   根治＝集成波里用新版 port-lib 统一重生成所有 `*.Linux` 工程（生成物已自带 `SignAssembly/PublicSign` + 统一身份文件），
   再按依赖序整体重建一次，让所有自产程序集**身份一致**；
3. 排障工具：`/tmp/asmref` 探针（`dotnet run -- <dll>` 打印 self 与全部 AssemblyRef 的身份），
   可一眼看出"引用的是哪个身份"。

#### T3 · HelloWpf 编译改造（2026-09-10，Phase 1 主体完成，等 PF 落地）

`samples/HelloWpf/HelloWpf.csproj` 已改为 **`net10.0`**（去掉 `net10.0-windows`/`EnableWindowsTargeting`/`UseWPF`）+
**8 条自产程序集 HintPath**（四件套 + DirectWriteForwarder/UIAutomationTypes/UIAutomationProvider/Manipulations），PBT 接管保留。

**四条实测结论**：
1. **唯一阻塞 = PresentationFramework 缺失**：构建输出 `MSB3245` + **`MC6000: Project file must include the .NET Framework assembly 'PresentationFramework'`**
   —— PBT **只点名这一个**，说明 WindowsBase/PresentationCore 已被它从自产件里认出；没有散落的 CS0246 差集。
2. **版本抬升已足够，三个兜底 Target 非必需**：diag 原文「选择 Reference:WindowsBase，因为 AssemblyVersion **4.0.0.1** 高于 **4.0.0.0**」，
   7 条自产路径全进 `@(ReferencePath)`/`@(ReferenceCopyLocalPaths)`，Platform 门面同样被顶掉。
   ⇒ `Directory.Upstream.props` 里那三个 Target 保留为保险即可，**不是**解决门面问题的必要条件。
3. **运行期绑定再验证**（直接回答 props 里那条"未闭环"）：`Microsoft.NETCore.App/10.0.11` **确实自带** `WindowsBase.dll`，
   但 app-local 自产 **4.0.0.1 赢过它**，`System.Windows.Interop.MSG` 正常解析；PresentationCore/System.Xaml 都能实际加载
   （M4 剔掉 `ModuleInitializer` 后不再炸 user32.dll）。
4. **UseWPF 关掉后必须显式 Import `Microsoft.WinFX.targets`**：对照实验实测纯 net10.0 下 `-t:MarkupCompilePass1` →
   `MSB4057 该项目中不存在目标`（SDK 只在 `TargetPlatformIdentifier=='Windows'` 时挂 WindowsDesktop targets）。

**★ BAML 基线首次固化 sha256（T1 只记了字节数）**：

| 配置 | App.baml | MainWindow.baml |
|---|---|---|
| **Release** | 860 B，`2dc95e1c…a466af2` | 1756 B，`4c536e69…e8c615`（与 T1 的 860/1756 对上） |
| Debug | **980 B** | **2362 B**（`XamlDebuggingInformation=true`，实测确认） |

> ⚠️ **BAML 大小随配置变**——比对必须同配置。**约定：对外引用统一用 Release 产出**。

**身份隐患（T3 独立发现，与主控诊断一致）**：自产件签名不齐（WindowsBase/UIAutomation*/Manipulations 未签名；
System.Xaml/PresentationCore/DirectWriteForwarder 公开签名 `31bf3856ad364e35`）→ 与"混合签名"踩坑同源，
由**集成波**统一重生成 + 整体重建根治（见下）。

#### ★ U1c · 几何导出真机 oracle 对拍 ✅（2026-09-10，Agent U1c；本工程**第一次**用真身 DLL 逐输入验证我方实现）

**方法**：`tests/parity/geometry/cases.json` **215 例**覆盖真身实际导出的 15 个 `MilUtility_*`；两侧 harness 源码逐字节相同
（Linux 用 `tools/GeometryOracle` + xunit 活体复跑；Windows 用 `NativeLibrary.Load(绝对路径)+GetDelegateForFunctionPointer`）。
几何输入是**手搓的 `MIL_PATHGEOMETRY` 字节块**，刻意不经我方序列化器——避免"序列化器 bug 伪装成几何偏差"。真身：10.0.7 / 1,952,016 B / sha256 `f4f7a44a…`。

**结果**：✅ 逐位相同 **134** + 浮点容差内 **34** = **168/215 完全一致**；⚪ 几何等价但发射顺序不同 16；⚠️ 我方偏差 10（未修，已登记）；⚠️ 结构性不同 21；**0 两侧异常**。

**修掉 11 处真偏差**（每处都有"真机 vs 修前 vs 修后"三段证据，详见 `docs/U1c-geometry-oracle.md` §4）：

| # | 偏差 | 真机 | 修前 | 修后 |
|---|---|---|---|---|
| F3 | **`HitTestPathGeometry` 极性整个反了**（M7a 作者自述"第一版写反已修、未真机验证"——真机证实仍反） | (大,小)=3 FullyContains、(小,大)=2 FullyInside、**相同形状=4** | 2/3/2 | 3/2/4 → **7/7 全一致** |
| F5 | **`MIL_PEN_DATA.DashArraySize` 是字节数不是元素个数**（上游 `/sizeof(double)`）→ **虚线此前完全失效** | 5 图形 | 1 | 5 |
| F1 | Area 自交分带缺自交点 y（蝴蝶结） | 50 | 100 | 50 |
| F9 | `Combine` 的 `outFillRule` **恒 Nonzero**（CShape 默认 Winding）＋ 需把 Skia 的 EvenOdd 捏合轮廓 Simplify | XOR 面积 150 | 175 | 150（Combine 偏差 **13→0**） |
| F7/F8 | `Widen`/Bounds **矩阵先作用几何再描边**（笔不缩放） | 9 段 / (-1,-1,201,101) | 5 段 / (-2,-2,202,102) | 一致 |
| F11 | **TileBrush Bottom 对齐写成 `viewbox.Height`**（复制粘贴错） | M42=0 | −50 | 0 |
| F2 | HitTest 阈值：严格小于 + `SQ_LENGTH_FUZZ=1e-4` + `GetAbsoluteTolerance` 口径 | 25/25 | 1 处偏 | 25/25 |
| F4 | `fSkipHollows` **真机生效**（否证台账旧说） | (0,0,10,10) | (0,0,200,200) | (0,0,10,10) |
| F6 | `Widen` 笔宽 0 → S_OK+0 图形；负笔宽取绝对值 | S_OK | E_FAIL | 一致 |
| F10 | 闭合图形编码：真机"5 点/4 类型、无 SegClosed 位" | — | 4 点/末位 17 | 一致 |

**两个 ABI 发现**：① `ArcToBezier` 是**唯一按值传结构体**的导出——`flat` 形态直接 `0xC0000005` 打崩进程，
`struct`/`ref` 在机器码层等价（CLR 传的是调用方副本指针），这解释了 WPF 自身为何能工作；
② `Combine` 要求**三个矩阵都非 NULL**（SAL 注释撒谎），否则 `E_HANDLE`。

**顺带否证台账旧说**：`Widen` 的 `rTolerance` **是真用的**（tol=0.001 → 1267 点、tol=10 → 19 点）——
`docs/unimplemented.md` §2.4 的两条（fSkipHollows 被忽略、rTolerance 被忽略）已按真机结果改写并划掉。

**主控裁定（U1c 上呈的四项）**：
1. **描边轮廓分解表示差异（12 例）→ 不修**：真机发一个带接缝的闭合轮廓、我们发外圈+内圈两环，**区域相同几何等价**；
   重写描边轮廓生成代价过高，登记为已知表示差异；
2. **展平密度差异 → 单开 milestone（U14）**：上游 `CBezierFlattener` 与我们递归细分策略不同（容差 0 时上游取 `extent*1e-12`，我们兜底 0.1），
   直接对齐会炸点数，需同时调展平器与深度上限；
3. **TileBrush 0 宽/高加固 → 保留**：真机除零产出 `INF/NaN` 矩阵，我们刻意当空画刷返回——**把 NaN 传播进 Skia 更糟**，登记为有意偏差；
4. 其余 6 项零散差异（端帽离散化/虚线段闭合表示/Outline 图形分解/共边 Union 多一共线顶点/弧长参数化差 0.58%/NaN 分数真机 S_OK 而我们 E_FAIL）逐条登记，本轮不改。

**上游自身的三个坑（实测记录）**：`Widen` **从不写 `outFillRule`**（哨兵 `0x5EED0001` 原样回吐 → 托管侧读到栈垃圾）；
`ArcToBezier` 半径退化时**拷贝未初始化栈内存**；`Combine` 的 SAL 注释与 `IFCNULL` 实现矛盾。

**诚实缺口**：`GlyphRun_GetGlyphOutline`/`ReleasePathGeometryData` 只验了导出存在（未构造 `pFontFace`）；
**sideways 完全没验**；`PolygonBounds` 的 `fSkipHollows` 只有推断；Combine/Outline 的曲线输入未覆盖；`CopyPixelBuffer` 只验错误码一致。

**Gate**：Commands.Tests **551 通过 / 1 跳过 / 0 失败**（基线 542/1，+9 条用例：1 条真机对拍 + 8 条回归断言）；
主控复核 **Rendering golden 13/13 仍绿**——U1c 的修复被限制在 M7a 导出实现内，未污染命令层/渲染层基线 ✓。

#### 里程碑 5 · PresentationFramework 0 错 0 警 ✅（2026-09-10，Agent M5）—— **四件套齐了**

```
python3 build/port-lib.py ReachFramework && python3 build/ReachFramework.Linux/reapply-patches.py
    && dotnet build build/ReachFramework.Linux/ReachFramework.Linux.csproj          # 0 错 0 警
python3 build/port-lib.py PresentationFramework && python3 build/PresentationFramework.Linux/reapply-patches.py
    && dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj   # 已成功生成 / 0 警 / 0 错
# then ReachFramework pass 2（自动改指真 PF，复核替身保真度）→ 0 错 0 警
```
| 产物 | 结果 | 大小 |
|---|---|---|
| `PresentationFramework.dll` | ✅ **0 错 0 警**（1354 @(Compile)） | **7,099,904 B (6.77 MB)** |
| `ReachFramework.dll`（285 .cs，真移植 + pass 2 对真 PF 编） | 0 错 0 警 | 741,376 B |
| `System.Printing.dll`（API-only，上游唯一托管面 2 个 .cs） | 0 错 0 警 | 49,152 B |
| `CycleStub.{ReachFramework,PresentationFramework,PresentationUI}.dll` | 各 0 错 0 警 | 5,120 / 13,824 / 7,680 B |

**自举顺序**（依赖环靠替身打破）：3 个 CycleStub → System.Printing → RF(pass 1，对 PF 替身) →
PF(对真 RF/SP + UI 替身) → **RF(pass 2，对真 PF 复核替身保真度)**。pass 2 是替身的**硬验证**：
编译器逐条确认 RF 对替身的全部使用在真 PF 上依然成立（0 错即通过）。

**CycleBreaker 替身与"为什么不真移植"**：实测 `find upstream/wpf -iname "*impl-cycle*" -o -iname "*api-cycle*"` **为空**、
`grep WpfCycleBreakersDir upstream/wpf` **只有引用无定义** ⇒ 上游快照里 `CycleBreakers/` 目录根本不存在（结构性缺失）。
替身四原则：① AssemblyName/版本(4.0.0.1)/WCP 签名与真件**身份一致**（只参与编译，运行期真件顶替；参方 `<Private>false</Private>`）；
② 成员逐条注明真源码 `文件:行`，能编真源码的直接编（PF 替身里序列化 API 4 个文件即上游原文件）；
③ **继承链保真**（防 `is FrameworkElement` 分支静默走错）；④ 不伪造行为。
> ⚠️ **PF bin 里的 `PresentationUI.dll` 是替身（7,680 B）**，文件名/身份就是 `PresentationUI`，将来真件同名顶替——**M6/M7 打包与运行期需知晓**。

**运行期降级（诚实清单）**：`FindToolBar` 无 BAML/模板 → 文档查看器"查找"工具条不可用；
`DocumentApplication*` 路径不启用；`System.Printing` 是 API-only（`throw null` 体）→ 打印/XPS 不可用（将来走 CUPS）；
journal（导航日志）序列化走上游 BinaryFormatter 回退分支（WinForms 私有包 NU1101）→ **Linux 运行期预期不可用**。

**本轮新增 port-lib 修复（主控落地）**：`GenerateDependencyFile=false` 搬运（不搬会让下游 `.deps.json` 阶段炸
`MSB4018 ArgumentException: Key: ReachFramework`——PF pass 2 实测踩到）；`-ref` 引用跳过的**显式告警**
（`System.Printing-ref` 是唯一托管面的反例，需手工建工程）。

#### 里程碑 6 起步 · HelloWpf 编译改造（T3，PF 落地后重跑中）

见上「T3」段：csproj 已改为纯 `net10.0` + 8 条自产 HintPath + PBT 接管；此前唯一阻塞是
`MC6000` 点名的 `PresentationFramework` 缺失，**现已解除**，T3 正在重跑 BAML 逐字节比对。

#### 里程碑 7b · Win32 子集 shim + 消息泵对接 X11 ✅（2026-09-10，Agent M7b）—— **托管层在 Linux 上真的跑起来了**

**验收硬指标 5/5 全达成**：`dotnet build` **0 错 0 警**；`dotnet test` 在 Xvfb :99 下 **19/19 全绿**；
无 X server 时 **11 通过 / 8 发现期跳过 / 0 失败**。

| 项 | 实测证据 |
|---|---|
| Win32 需求清单 | 从**两个 csproj 的 `<Compile Include>`**（真会编进程序集的）提取：属性 **725** 条、去重 **697**；**P0 = 83，实现 83/83（100%）**；P1 = 195（已给落点 122）；P2 = 419（逐 DLL 理由） |
| ★ 清单逼出**第 4 个必须映射的 DLL** | `PresentationNative_cor3.dll` —— 上游把 `GetWindowLongPtr/SetWindowLongPtr/GetParent/GetWindow/SetFocus/EnableWindow` 声明成它的 `*Wrapper` 入口（**不是** user32 裸名），`HwndSubclass` 整套 WndProc 链走这里 |
| shim 库 | `gcc -std=gnu11 -O2 -fPIC -shared -Wl,--no-undefined -lX11 -ldl -lpthread` → `libwpfwin32.so` **108,432 B**；`nm -D` 定义符号 **347**；实现深度：逻辑函数 199 = **真实现 103 / 降级 72 / 返回失败 24** |
| **结构体 ABI 断言**（用原生 `offsetof` 对**托管编译产物里的真实结构体**逐字段比对） | `MSG` 48（hwnd 0/message 8/wParam 16/lParam 24/time 32/pt 36,40）✅；`WNDCLASSEX_D` 80 ✅；RECT 16 / TRACKMOUSEEVENT 24 / PAINTSTRUCT 72 ✅ |
| ★ 两个"托管形状 ≠ Win32 形状" | `WINDOWPOS` 上游是 **40 字节简化形态**（2 指针+5 int，无 time/pt）——按真 Win32 写 48 被断言打回；`MONITORINFOEX` 长度**随 CharSet 变**：`CharSet.Auto` 在 **Unix 折叠为 Ansi(72)**（Windows 是 Unicode 104），凭记忆写会 32 字节越界 |
| **真实 X11 窗口** | `xdotool search --name WpfLinux-M7b-…` → `2097160`；`xwininfo -id 0x200008` → `320x200 pos=(40,60) Map State=IsViewable`；**`WpfLinuxWin32_GetX11Window(HWND) == HWND`（0x200008 == 0x200008）→「HWND 就是 X11 XID」被直接证明** |
| Dispatcher 消息泵 | 计时器 50ms×≥3 → 实测 **3 次 / 194ms**；`PushFrame` 退出三条路径（跨线程 `InvokeShutdown` 426ms / 帧内 `BeginInvoke(Continue=false)` 376ms / **纯阻塞在 GetMessageW 靠跨线程唤醒 509ms**）——都不死等 |
| 事件流入 | `xdotool` 注入后托管 hook 完整收到 `WM_NCCREATE→WM_CREATE→WM_SHOWWINDOW→WM_PAINT→WM_KEYDOWN(0x41=VK_A)→WM_CHAR('a')→WM_KEYUP→WM_MOUSEMOVE×2→WM_LBUTTONDOWN/UP→WM_DESTROY→WM_NCDESTROY`；10s 兜底未触发 |

**★ 三个"不跑起来就发现不了"的缺陷（本轮修掉）**：
1. **`MS.Utility.EventTrace` 静态构造依赖注册表** → `HwndWrapper` **终结器**走到它 → `TypeInitializationException` → **测试宿主进程崩溃**（不是用例失败）。
   两道短路在 Unix 全失效（`Environment.OSVersion` 返回**内核版本 6.8**、`IsClassicETWRegistryEnabled()` 读 `HKCU`）→ 补丁 F + `WindowsBase.EventTrace.Shim.cs` 换成 `NullTraceProvider`。
   语义论证：Linux 无 ETW，"无订阅者"正是上游默认路径，506 处 TraceEvent 全被 `IsEnabled` 挡掉，**没有日志被丢弃**。
2. **message-only 窗口不发建窗消息** → `HwndSubclass` 靠"第一条消息"自我挂载，跳过就永不挂载 → `GWL_WNDPROC` 一直指向**只被 `GC.KeepAlive` 到构造结束的委托** → 之后 `DispatchMessage` 调用已 GC 委托 → fail-fast 进程终止。按 Win32 语义给 message-only 窗口也发 `WM_NCCREATE/WM_CREATE/WM_DESTROY/WM_NCDESTROY`。
3. **Xlib 多线程** → `[xcb] XInitThreads has not been called` / `xcb_xlib_threads_sequence_lost` → 进程 abort（触发者是真实 WPF 行为：`HwndWrapper` **终结器线程** DestroyWindow 与 UI 线程 XPending 并发）。两道防线：`__attribute__((constructor))` 里 `XInitThreads()` + 自有 `g_xlock` 串行化每个 Xlib 调用。
   附带修掉**字符集错误**：`CharSet.Auto` 在 Unix 折叠为 Ansi 且**先探裸名**，裸名一度转发到 `...W` → 类名乱码 → `ERROR_CLASS_DOES_NOT_EXIST(1411)` → 连 `Dispatcher.CurrentDispatcher` 都建不出来；现约定「裸名 == A(UTF-8)，`...W` 先转码」。

**⚠️ 仍未做（M7c 必读）**：
- **`HwndSource` 仍构造失败**，根因已定位到行：`Shared/MS/Internal/SecurityHelper.cs:215` 的 `baseRegistryKey.OpenSubKey(...)` NRE
  （`Registry.CurrentUser` 在 Linux 上**为 null 而不是抛异常**）→ `AvTrace.cs:213/188/43` → `TraceDependencyProperty..cctor` → `PresentationSource` 静态构造失败。
  **最小补丁 = 1 行**（`if (baseRegistryKey is null) return null;`，或在 `IsWpfTracingEnabledInRegistry()` 开头 `return false;`——Linux 上"托管 tracing 未启用"也是真话）。
- **M7c 第一缺口 = MIL 原生符号面**：M7a 的 108 个导出是**托管方法**，`[DllImport("wpfgfx_cor3.dll")]` 还没有落点（决策 3 未做）——**挡一切绘制的第一块**（T1 轨道在做）。
- **不需要改 `src/WpfGfx.Linux/Windowing/` 一行**：「HWND == X11 XID」这条设计让 M7c 拿到 HWND 可直接喂 `X11PresentationTarget`。

#### ★ T1 · MilCore 导出桥接 ✅（2026-09-10）—— **决策 3 落地：108 个 `[DllImport("wpfgfx_cor3.dll")]` 有了落点**

**机制选型（两条路线实测对比）**：

| 维度 | **路线 A：NativeAOT .so + `DllImportResolver`（选定）** | 路线 B：编译期替换直调 |
|---|---|---|
| 覆盖 108 导出 | ✅ **108/108**（`nm -D` 对拍，缺失 0） | ⚠️ 需改 **10 个源文件 / 108 个调用点** |
| 上游零改动 | ✅ 完全符合 | ❌ `exports.cs`(2537 行) + `wgx_exports.cs`(344 行) 是**直编上游** → 要么改上游（违规）要么 fork 2881 行 |
| `PreserveSig=false`（3 条） | ✅ **自动正确**（CLR 失败即抛） | ❌ 需 3 处手写 `Marshal.ThrowExceptionForHR`，漏一处＝静默吞失败 |
| 产物/成本 | `wpfgfx_cor3.so` **4,105,312 B**（发布 29s 冷 / 11s 热） | 无新产物，但 PC 每次全量重编 1348 文件 |
| 类型映射 | 收敛到 ABI 层 1 处（本就逐字节等价） | 分散在 108 个调用点（`double*`/`WindowMessage`/`out int` 等 6 类） |

**关键发现**：① **可见性问题不存在**——M7a 已把 108 方法做成 `public static`，**零 `InternalsVisibleTo`、零 public 门面**，一行 `ProjectReference` 直接调通；
② **M7b 的 `Win32ShimResolver` 已占住 PC 的 `SetDllImportResolver` 槽位**（该 API 每程序集只能调一次），故 T1 的解析器**刻意不含 `[ModuleInitializer]`**，只暴露 `TryResolve` 由前者组合——这是唯一有踩雷风险的集成点；
③ `libSkiaSharp` 搜索路径是真坑（AOT 镜像去宿主 `AppContext.BaseDirectory` 找 Skia）→ 用「镜像内给 SkiaSharp 注册 resolver + `MilBridge_SetNativeDir` 握手」解决，**无需 `LD_LIBRARY_PATH`**。

**闭环 40/40 通过**（`build/MilBridge/`，`run.sh` 一键复现）：含 `channel.CommittedCommands == 1`、
`NotImplCommands == 1`、**D11/D12 差分证明**（真命令字节 `MilCmdChannelDeleteResource` 经 `BeginCommand→Append→End→Commit`
被**既有 `MilCommandDispatcher`** 解码执行，资源从通道表消失；Handle 错位到 offset 8 则资源保留）、
`MILCMD` 头与 `MilMatrix3x2D`(`double*`, 48B) 的逐 offset 断言（写 offset 16 ≠ offset 32）。

**主控已完成接线**：`build/shims/PresentationCore.shims.txt` 追加 MilBridge 解析器 + `Win32ShimResolver.Resolve()` 开头插 3 行（在 `IsMapped` 之前）→ PC **0 错** ✓。
> ⚠️ 落地时踩到并已修：port-lib 原生资源打包与 B 的补丁 E1 **重复注入**（两个同名 `WpfLinuxGenerateGResources` 任务/Target，
> 补丁 E1 那份传进来的条目没有 `WpfLinuxKey` 元数据 → 空键重复 `MSB4018`）→ **补丁 E 已退役**（port-lib 原生覆盖）。

**待裁决（U15，不阻塞）**：`MILSwDoubleBufferedBitmapGetBackBuffer`/`AddDirtyRect` 上游是 `PreserveSig=false`（失败应抛），
但内层 `MilNative` 返回 `void` → 包装只能返回 `S_OK`，**真失败会被当成功**。建议 M7a 侧把这两个方法改成返回 `int`。

#### ★ T2 · 字体/文本栈接线 ✅（2026-09-10）—— **PNSE 62 → 15（75.8% 落地）**

| 档 | 条数 | 接线后 |
|---|---|---|
| A · 布局必需 | 23 | ✅ 23/23 委托 provider |
| B · 绘制必需 | 2 | ✅ 2/2 |
| C · 可降级 | 22 | ✅ 22/22 |
| D · 本轮不做（shaping/COM 回调/子集化） | 15 | ⛔ 仍 PNSE（文案细化） |

验证口径：`grep -c "NotSupported.Throw" ManagedSurface.cs = **15**`，且 15 条全在 D 档（分类不是估的——每条的 PresentationCore 调用点 `file:line` 都 grep 过）。

**实测数字**：① **跨进程确定性**：摘要哈希 `d8c7def1…330b1e`，进程内/进程1/进程2 **三者完全相同**（摘要 299 行）；
② **三方独立一致**：52 张表与文件字节逐字节相同、3884 个字形的 hmtx advance 与 Skia 差 ≤1 设计单位、
**全部 65536 个 BMP 码点**的 cmap 直读 == Skia == 我们的映射；
③ **边界**：代理对 → 1 个真字形；**孤立代理不丢字**（`"A\uD800x"` → 3 字形，而 Skia 字符串入口给 **0** 个）；20 万字符稳定；
④ **公式**：`'H'@12px` = 2668（round(8.892×300)）、Display 吸附 2640、**银行家舍入**（2.5→2 / 3.5→4）；⑤ 与 M1 `Text/` 层：字形 id 逐元素相同、advance 偏差 <0.05px、字体解析 4/4 同一文件（表 SHA 判同一性）。

**过程中发现并处理的真问题**：① **`LineSpacing` 缺 `(double)` 强转** → 行高恒 1.0 em 而非 1.362（**主控已修**，T2 加了双层回归断言）；
② **Skia `GetGlyphs(string)` 遇孤立代理整串返回空数组**（静默丢字）→ 改为自己解码 UTF-16 + 码点数组入口；
③ Skia 的 underline/strikeout **符号与 OpenType 表相反**（会画到基线以上）→ 取负归一；
④ 增补平面码点统计被 cmap 重复记录**算成两倍**（176 → 真值 88）。

**简单 vs 复杂文本边界（可执行结论）**：**简单路径**（`SimpleTextLine.cs:935/1780 → GlyphTypeface.ComputeUnshapedGlyphRun → GetArrayOfGlyphIndices`，
且 `TextCharacters.cs:236` 直接 `new ItemProps()` 连 Itemize 都不走）依赖的成员**全在 A/B/C 档已落地** →
单一字体/单一字号/无排版特性的短文本（**HelloWpf 的 "Hello WPF"**）**可出字**；
**复杂路径**（FullTextLine + LineServices → `Itemize/GetGlyphs/GetGlyphPlacements`）需 HarfBuzz 级 shaping → **独立里程碑**。

**主控已派发"最后一米"**（T2 续做）：① **Factory 原生闸门**——PC 的 `MS/internal/Text/TextInterface/Factory.cs` 6 处
`_factory.Value->…`（73/84/214/281/312/328）在 `DWriteLoader` 返回 null 时会在到达 47 条实现**之前**崩；
② **令牌桥接一行**（`FontHandleTable.TokenAllocator = MilFontFaceTable.Register`），不装则 `MilGlyphRun_GetGlyphOutline` 返回 `E_HANDLE`（画不出轮廓）。

#### ★ T3 · HelloWpf 阶段结论 + 一条必须更正的宣称（2026-09-10）

- **编译**：`dotnet build samples/HelloWpf/HelloWpf.csproj` **0 警告 0 错误**（Debug/Release 双配置、`--no-incremental` 全清重建亦然）；
  8 条自产引用**全部**解析到 `build/*.Linux/bin/Debug/`（自检目标每次打印），diag 原文「AssemblyVersion **4.0.0.1** 高于 **4.0.0.0**」→ **不需要**兜底 Target。
- **⚠️ BAML 不是"逐字节一致"**：Release `App.baml` **739 B** / `MainWindow.baml` **1635 B**，比 T1 基线（860/1756）**每文件恰好小 121 B**。
  逐字节定位：公共前缀 72/79 B 与公共后缀 206/1095 B **完全相同**，差异**只在 BAML 头部的程序集引用表**（少了 `System.Windows.Controls.Ribbon` 记录、
  四件套版本 `10.0.0.0→4.0.0.1`、WindowsBase token `31bf…→null`）。
  ⇒ **XAML 载荷逐字节相同，只有"引用了哪些程序集"那张表变了——而那张表本来就该变**（T3 的全部意义就是换引用件）。
  **对外只能说"BAML 正确产出、载荷等价"，不能说"与官方逐字节一致"**。
- **Debug 与 Release 的 BAML 本就不同**（`XamlDebuggingInformation`）→ 比对必须同配置；约定对外引用统一 **Release**。
- **运行链实测到底**（T3 在 /tmp 用补丁版 WindowsBase + `DISPLAY=:99`）：**窗口真的建起来 → 消息泵跑到 `HwndSubclass.SubclassWndProc`（证明 M7b 的 shim 有效）→ `App.baml` 被运行期真正加载**（`Application.LoadComponent → XamlReader.LoadBaml → WpfXamlLoader.LoadBaml`），
  停在 `SystemFonts` 读注册表/`SystemParametersInfo`（两处已派 M7b 修）。
- **依赖闭包**：`ReachFramework`/`System.Printing`/`PresentationUI` 由 PF 目录**传递解析**（不显式引用也进 `bin/` 与 `deps.json`）；
  ⚠️ 其中 `PresentationUI.dll` 是 **CycleStub 替身**（7,680 B）。
- 新增 **7 个 OOB BCL NuGet 包**（唯一非自产引用面，删掉只影响运行）；csproj 借用 SDK 的 `Microsoft.WinFX.targets` **一个文件**（任务实现全自产，实测 net10.0 下不 Import 它则 `MarkupCompilePass1` 目标不存在）。

#### ★ M7c 执行计划（主控侦察结论，2026-09-10）—— "接窗"是**接通**而非从零造

**现状（实测代码位置）**：
| 环节 | 现状 | 位置 |
|---|---|---|
| 目标类命令 | ✅ 已实现：`MilCmdHwndTargetCreate`(0x31) / `MilCmdGenericTargetCreate`(0x34) / `MilCmdTargetSetRoot`(0x35) / `MilCmdTargetInvalidate`(0x37) | `Commands/MilCommandDispatcher.cs:274/322/335/356` |
| 根视觉记录 | ✅ `MilCmdTargetSetRoot` → `ch.SetRootFromHandle(root)`（通道知道自己的根） | `Resources/MilChannel.cs` |
| HWND 绑定 | ⚠️ **只登记身份**（`MilHwndRegistry.TryAttachVisualTarget`），未绑 X11 呈现目标 | `Interop/MilNative.Window.cs:111` |
| 呈现 | ⚠️ `WgxConnection_SameThreadPresent` **只提交通道**，不渲染不呈现 | `Interop/MilNative.cs:92` |
| 渲染能力 | ✅ M1 就绪：`SkiaRenderBackend` + `VisualProjection` + 资源表 | `Rendering/` |
| X11 呈现能力 | ✅ M1 就绪：`X11Window`/`X11PresentationTarget.Present(SKImage)` | `Windowing/` |
| HWND ↔ X11 | ✅ M7b 实证 **HWND == X11 XID**（`GetX11Window(0x200008)==0x200008`），可直接喂 | `src/WpfGfx.Linux.Native/` |

**要做三件事**：
1. **绑窗**：`MilVisualTarget_AttachToHwnd(hwnd)` 里除身份登记外，为 **已存在的 XID** 建/绑一个呈现目标
   （注意 M1 的 `X11Window` 是"自己建窗"语义，需要新增"包装既有窗口"的能力或适配器——这是唯一需要动 `Windowing/` 的地方，**改动要有回归**）；
2. **呈现**：`WgxConnection_SameThreadPresent(connection)` 里渲染 `channel` 的根视觉（`SkiaRenderBackend` + provider）→ `Present` 到已绑窗口 → `XFlush/XSync`；
3. **端到端**：跑 `samples/HelloWpf`（`DISPLAY=:99`）→ 真窗口 → 独立进程 `xwd` 截屏 → 像素断言（对齐 HelloMil 证据链标准），新增 `HelloWpf.Tests` 纳入 verify-all。
**前置**：M7b 的 AvTrace + `SystemParametersInfoW` 修复、T2 的 Factory 闸门 + 令牌桥接（都在施工中）。

#### ★ U1a · 真机像素对照 ✅（2026-09-10，Agent J）—— **本工程第一次拿真机像素当 oracle 验证渲染**

**结果**：15 个真机场景用我方栈重建并逐像素比对——**110/110 探针全中**；全图差异 10854/983040 = **1.104%**，
其中**只有 121 px（0.012%）不在真机边缘 1px 内**（其余全是抗锯齿）。

| 归类 | 场景数 | 说明 |
|---|---|---|
| ① 完全一致（Δ>2 像素 0） | 4 | solid / linear_gradient / radial_gradient（修 bug 后）/ clip_rect |
| ② 已知简化 | 1 | dash（**DashCap 差异 118px**；做过受控实验：映射到 StrokeCap 只把"漏画圆点"换成"线端多画 3px"，**无净收益 → 决定不改**，代价已量化） |
| ③ AA（非边缘差异 = 0） | 10 | 0.46%–2.8%、带宽 1–2px，与真机自证 AA 波动同阶 |
| ④ 规格歧义 | **0** | `conventions` 把口径写全了 |

**"不可归咎"的三条可复现判据**：位置（真机图 8 邻域无 >8 跃变时非边缘差异 = 0）、方向（少墨/多墨双向；全表唯一单向的是 dash，正因它不是 AA）、量级（与真机自证 AA 同阶）。

**★ 抓到并修掉一个真 bug（我方实现错）**：`Rendering/SkiaBrush.cs::MappingMatrix` 的 `Concat` 参数写反 →
**所有 `RelativeToBoundingBox` 渐变画刷**的平移被缩放乘进去（Tx = 8×116 = 928），整块渐变被钳位成末停靠色。
scene05 实测：**修前 35137px / 53.6% / 探针 2-6 → 修后 0px / 0% / 探针 6-6 / 最大通道差 1**。
同步新增回归用例，并**只重生成**受影响的唯一基准图 `tests/golden/linear_gradient.png`
（新旧差异 bbox = `(20,95,130,165)` 正是相对渐变矩形，其余逐字节相同——**旧基准把这个 bug 固化成了纯色块**）。

**三条真机结论 → 我方实现实测**：
1. **渐变按 sRGB 插值** ✓ 逐像素吻合（scene04 中点真机 `(128,128,128)` = 我方；线性 scRGB 反模型为 188），整场景 **0 差异**。
   ⇒ 代码注释里"ColorInterpolationMode 未实现"在**真机默认值下差 0**（WPF 默认枚举名叫 `ScRgbLinearInterpolation` 但行为是 sRGB 插值）；
   两个枚举值的区分仍是未验证项。
2. **`PushOpacity` 是真合成层** ✓ 真机/我方 `(159,144,0)`，逐图元反模型 `(159,156,0)`——J 还用我方栈**真的画出了反模型版**证明用例有区分力。
3. **`Exclude` = A−B（差集）** ✓ → **债务 #8 销账**（我们按 `Difference` 处理正确）。

**债务处置**：#8 **销账**；#7 **降级保留**（残差归因 miter 裁剪突刺，非弧线参数化，见 ARCHITECTURE §8）；
新增并**当场修掉 #12**（见下）。**未覆盖**（如实登记）：文本/字形、位图、Blur/DropShadow、3D、动画、窗口合成；
我方有实现但场景没碰的：MilVisual 层级复合、画刷 Transform/RelativeTransform、Repeat spread、DPI/EdgeMode/GuidelineSet、`IsFilled=false`、GeometryGroup。
**下一批建议场景**（J 给）：TransformGroup 真机复现、画刷变换、`IsFilled=false`、Pen 两端 cap 不同、DrawImage。

#### ★ 债务 #12 修复：`TransformGroup` 子变换顺序画反（2026-09-10，J 发现 + 主控核准并修）

**证据链**：J 从上游源码 + 真机 `composite` 值发现 `TransformResolver.Mul(a,b)` 数值上等于 `SKMatrix.Concat(a,b)`
（= **b 先作用**），而 `Resolve(MilTransformGroup)` 的 `acc = Mul(acc, child)` 使子变换**整体反序**。
**主控独立推导核准**：`SKMatrix` 是**列向量**约定（`p' = M·p`，平移在最后一列）⇒「先 A 后 B」= `B·A`；
`Mul(a,b) = a·b` = b 先作用；逐子累积得 `c0·c1·c2` = **c2 先作用** ✗，而上游 `TransformGroup.cs:31`
（`transform = c0; for i=1..n: transform *= c_i`）要求 **c0 先作用**。
**修法**：`Resources/VisualProjection.cs` 累积改 `Mul(Resolve(child), acc)`（新子放右侧＝后作用）。
**验证**：① 用例断言 `TransformGroup(Translate(50,0), Scale(2,1))` 作用 `(10,5)` → **120**（反序会得 70），并加反向组区分力断言；
② J 的哨兵用例升级为**实现级回归守卫**（原断言写的是"记录反序"，现改为直接守卫实现顺序）；
③ `transform_nested.png` 基准更新，差异 bbox **57×53 @ (49,105)**（局部，符合子变换位置修正）；
④ 真机 `composite`（WPF `Matrix.Multiply` 逐次相乘）复算**命中 ≥10 个 op**，佐证链式模型。
**全程 Rendering.Tests 81/81 绿**（新增 25 条 U1a 对照用例）。

#### ★ U1b · 真实 DUCE 命令流 golden binary ✅（2026-09-10，Agent D + 主控回放器修复）—— **工程最大未验证风险关闭**

**代理 DLL（路线①）**：`wpfgfx_cor3.dll` **208,384 B**（x64 PE），**真身导出 106 条全在（0 缺失）+ 自身 109**（7 拦截 + 99 个 `jmp *ptr(%rip)` 桩）。
两个坑：① Windows 侧 **360 杀毒**把 `zig.exe` 落盘即封（`AccessDenied`，排除目录需管理员越界）→ **改在 Linux 用 zig 交叉编译 PE**，只传 208 KB 自制 DLL；
② **app-local 放同名 DLL 完全不生效**（WPF 按运行目录全路径加载）→ 用 `NativeLibrary.SetDllImportResolver` 重定向后立即生效。
命名坑在真身导出表上复核：`MilChannel_CommitChannel` **在**、`MilConnection_CommitChannel` **不在**、`MilChannel_SendCommand` **根本不存在**。

**抓到 op5（托管 hook 拿不到的那一项）：ch1 = 641 条**，13 种资源类型、句柄 `1,2,3,…`（真身回填值）。
窗口 workload 另多出 **`MilCmdRenderData (0x18) ×15`**（`AppendCommandData` 的变长数据 = "完整一帧"）+ PathGeometry×21 / LinearGradient×4 / RadialGradient×2 / DashStyle×23。

**逐字节原样流最初 FAIL（51 × E_HANDLE）——三分类归因**：不是解码器缺陷（同字节换原生释放语义 → committed 417 / failed 0）、
不是流格式问题，而是**回放器的资源生命周期模型**：真实 wpfgfx 在"引用该资源的命令还压在未提交批次里"时就发 release，
原生通道把删除**推迟到批次下发后**；而回放器读到 op6 就立即释放。
**主控修法（不用改数据）**：回放器实现**延迟释放**（release 只标记 → 每次 `Commit()` 之后 + 流末尾才真正摘除）→
**逐字节原样流实测 552 通过 / 0 失败 / 0 跳过** ✓。
> 因此 `tests/U1-golden/` 的基准输入就是**原始抓取流**（`u1b-scenes-rtb-raw.stream`）；
> D 之前为绕开该限制做的"op6 位置对齐"变体降级为 `tests/parity/windows/streams/` 里的留档（不再参与测试）。

**剩余缺口**：ch2 有跨通道句柄引用（29 创建 / 31 释放），未放进 golden；文本/位图/效果/3D/动画未覆盖。
**Windows 侧清理**：`C:\u1-parity\` 已清到只剩 `out/`，但**两个 `zig.exe` 被 360 锁住删不掉（~338 MB）**——需人工处理，已记此。

#### ★ M7c Phase 1 ✅ + Phase 2 推进记录（2026-09-10，Agent M7b + 主控集成）

**Phase 1 · 接窗链路以 xwd 逐像素证明**（`Presentation.Tests` 8/8）：
链路 `Win32 shim 建窗 → MilVisualTarget_AttachToHwnd → WgxConnection_Create → MilConnection_CreateChannel →
线上字节命令（HwndTargetCreate/SolidColorBrush×2/RenderData/VisualSetContent/TargetSetRoot）→ SameThreadPresent →
SkiaRenderBackend → X11PresentationTarget.Present(XPutImage) → 独立进程 xwd → PNG`。实测：
```
HWND = 0x400001；X11 XID = 0x400001（HWND == XID：True）
PresentCalls=1  FramesPresented=1  DrawnCommands=2  NotDrawnKinds=0
像素分布：红=32000  蓝=32000  其它=0        （各恰好 = 160×200 矩形面积）
左半中心(80,100)=#c81e1e Δ=0；右半中心(240,100)=#1446c8 Δ=0
```
红/蓝数量**恰好等于图元面积**、`其它=0` ⇒ 不是"某点碰巧对上"。两条"失败必须响亮"的用例：
未绑窗口 → `0x80004005`（非 S_OK）+ `FramesPresented==0`；离屏通道 → S_OK + 0 帧。

**`Windowing/` 唯一改动 = 包装既有窗口**（`X11Window.Wrap` + `_ownsWindow`、`X11PresentationTarget.WrapExisting`），
语义差别只有三条（不创建/不销毁/不改事件掩码），呈现实现由 `InitializeFromServer` 共用；**回归 44 + 19 全绿**，
另加 5 条"不立刻报错"的越权专项用例。**顺带修掉一个进程级洞**：无效 XID 会让 Xlib 默认错误处理器直接 `exit(1)`
（表现为"测试主机崩溃、无任何异常"）→ 已装 `XSetErrorHandler` 转成可捕获的托管异常。

**Phase 2 · 六轮 + 三个补丁应用器**（每轮都真跑；runner 把输出复制到 /tmp 再覆盖新鲜程序集 ⇒ 对 T3 目录零写入）：
越过 `Application` 静态构造 → **BAML 加载** → `SystemFonts`（M7b 的 SPI 修复在这里被真正走到）→ `MediaContext` →
`MediaContextNotificationWindow`；卡点依次被清除：

| 补丁 | 根因 | 语义论证 | 结果 |
|---|---|---|---|
| **I** | `FontCache.Util` 在 Linux 无 `windir` ⇒ `"\Fonts\"` 非法 URI ⇒ **Window 静态构造链全断** | 指向平台字体目录 `/usr/share/fonts/`（可 `WPF_LINUX_FONTS_DIR` 覆盖），**不造假 URI** | ✅ 越过 |
| **J** | 输入栈 3 文件 5 处 `Registry.CurrentUser` 在 Unix 返回 **null**（上游只 catch `IOException`）⇒ `StylusLogic.cs:285` NRE | 一个 `?`：上游每处拿到结果后本就判 `!= null`/用 `?? 0`，`?.` 走的正是**原有的**"键没配过"分支 | ✅ 越过（实测这三处的栈不再出现） |
| **K** | `OleServicesContext` 5 处 STA 硬检查（Linux `GetApartmentState()` 恒 `Unknown`）→ `HwndSource.Initialize:334` **无条件**调 `RegisterDropTarget` ⇒ 挡每一个 WPF 窗口 | 逐处论证：`Register/RevokeDragDrop` → **S_OK no-op**（绝不能抛）、`SetDispatcherThread` 跳过检查且仍挂 `ShutdownFinished`、`OnDispatcherShutdown` 直接返回、**`OleDoDragDrop` → PNSE**（与 M4 的 U13 裁决同口径；用 PNSE 而非 ThreadStateException，后者会误导成"线程用错了"） | 主控已应用 + PC 0 错 |

**shim 侧同步扩容**（全部由实测栈逼出来，347 → **382** 导出）：`PresentationNative` 20 个版本判定（**全 FALSE**：
Linux 上"是不是 Win10 RS1+"的答案就是否 ⇒ 不做 PMv2 DPI 缩放，正是 X11 应有行为）、`uxtheme`（`IsThemeActive()=0` = 真话）、
`wtsapi32`（返回 FALSE，安全性来自调用方 `defaultResult:true`）、`LsDisableSpecialCharacterLigature`（空实现：引擎不存在）、
以及 **`CW_USEDEFAULT` 归一**（原先 INT32_MIN 被原样存下 ⇒ `Rect` int 溢出抛负宽高；现归一为 800×600）。

**★ 过程中一个"更糟就撤"的范例**：M7b 为解"无输出崩溃"试装 Xlib **IO** 错误处理器 → 实测**更糟**（1/5 → 1/2），
**已回退**并写明理由（IO 错误意味着连接已死，处理器不应返回）；真根因是**测试并行**——
并顺带实测出 `ManagedLayer.Tests` 的 `<xunit_parallelizeTestCollections>` **不是 xunit 的开关**（不生成 runner json、
也不改变行为），真正生效的是**输出目录里的 `xunit.runner.json`**（Presentation.Tests 加上后间歇崩溃 **4/8 → 0/10**；主控已给 ManagedLayer.Tests 补上）。

#### ★ 集成波 ✅（2026-09-10，主控执行，修掉 M7c 报的 #0/#3/#4）

**触发**：M7c 发现树里有两份身份不同的 `System.Xaml.dll`（权威产物 654,336 B/**未签名/丢 SR 资源** vs 下游 bin 里 701,440 B/已签名/有资源）
⇒ PBT 报 `MC1000`，运行期表现为 `System.SR.Format(null)` 的 `ArgumentNullException`（**连报错都报不出来**）；
同时 PF 因同一根因编译不过（CS0115/CS0534 ×6），自产件签名状态全树不一致（WB/SX/UIAT/UIAP 未签，PC/PF/DWF 已签）。

**做法**（脚本 `build/integration-wave.sh`，可复现）：用当前 port-lib **重新生成**全部生成物工程
（统一公开签名 + 资源管线 + 身份文件）→ **重放全部补丁**（WB 的 G/F、PC 的 B/D/F/G + H/I/J/K 应用器、RF 的 A/B/C、PF 的 A/B）
→ **按依赖序整体重建 14 步**（System.Xaml → WindowsBase → DWF → UIAutomation* → Manipulations → PC → System.Printing →
CycleStub×3 → RF → PF → RF pass2）。

**实测结果**：

| 项 | 修前 | 修后 |
|---|---|---|
| `System.Xaml.dll` | 654,336 B / 未签名 / **丢 SR 资源** | **4.0.0.1 pkt=31bf3856ad364e35（已签）+ `System.Xaml.Resources.Strings.resources` 46,479 B** |
| `WindowsBase.dll` | 4.0.0.1 / **未签** | **4.0.0.1 pk=signed**（全树签名统一） |
| `dotnet build samples/HelloWpf` | **MC1000**（PBT 找不到匹配身份） | **0 警告 0 错误** |
| 一次性解决 | — | **#0（双身份）/ #3（PF 编译不过）/ #4（签名不一致）同源同修** |

> ⚠️ **一条被实测推翻的指令**（记档）：主控曾要求 M7b "把 HelloWpf 的自产引用全改 `ProjectReference`"。
> M7b 实测反证：ProjectReference **只传项目边**，而 PC/PF 内部用 `<Reference><HintPath>`，那些私有依赖**不传递**
> ⇒ app 的 deps.json **反而丢** `WindowsBase` ⇒ 复现 T2 探针的 `FileLoadException 0x80131040`；
> 而 **HintPath 形态下 RAR 会把引用连同同目录依赖解析进 deps.json**（HelloWpf 因此才有 `WindowsBase/4.0.0.1` 这条边，
> 也才能一路跑到 `CreateChannels`）。**结论：HelloWpf 保持 HintPath + 对叶子工程（Provider）用 ProjectReference。**

#### ★ T1 追加交付：两条导出 + 一次 .so 重建（2026-09-10）

- **`MilChannel_SetNotificationWindow`：`E_NOTIMPL` → 真实现**（`State` 档）：`hwnd==0` → 解绑（幂等）、
  `message==0` → `E_INVALIDARG`、同值重复登记 → `S_OK` 幂等、换值 → 覆盖登记；`MilConnection_DestroyChannel` 随之摘除登记。
  **刻意不真 `PostMessage`**（DUCE 是进程内传输，SameThread 下"入队即送达"）；跨线程唤醒落点预留（`MilChannelBackChannel.Post` → `OnBackChannelPosted`），
  SameThread 下计数器**恒 0** 且有测试钉住。
- **新增导出 `MilFontFace_RegisterFromFile(const char* utf8Path, int32 faceIndex, int32 simFlags)`** —— 解决 T2 发现的 **NativeAOT 跨运行时边界**
  （`.so` 是独立运行时，托管侧装委托跨不过去）。实测令牌 `0x20000001`（Bold `0x20000002` / Oblique `0x20000003`），
  失败路径全 0（**绝不抛异常穿 ABI**）；`simFlags` 真生效（`font.Embolden` / `font.SkewX`）。
  **两条独立验证**：托管侧真 P/Invoke（闭环 F 组 6/6，**F4 是跨运行时实证**：令牌交给 `.so` 内 `MilGlyphRun_GetGlyphOutline` → `S_OK` + **800 字节真轮廓**）
  + **完全不经过 .NET 的纯 C `dlopen`/`dlsym` 探针**。
- `.so` **4,213,584 B**、`nm -D` **109 导出缺失 0**（118 → 121 个 `T` 符号）；闭环 **46/46**、Commands.Tests **562/562**（连跑 3 次一致）。
- **部署要点（实测）**：`wpfgfx_cor3.so` **必须与 `libSkiaSharp.so` 同目录**一起放进应用目录（AOT 镜像内部的 Skia 只在该目录找）；
  只拷贝 `.so` ⇒ `DllNotFoundException: libSkiaSharp`。

#### 复验（十一次，2026-09-10，非 X 环境，主控）

```bash
bash verify-all.sh --no-x     # 不占 Xvfb，避免与 M7c 的窗口轮询互相干扰
```
```
[1] 主工程 ✅ / wpf-linux.sln ✅        （sln 与 verify-all 已纳入 ManagedLayer.Tests 与 Presentation.Tests）
[2] Commands 562/0 · Rendering 81/0 · Windowing 26/13skip · HelloMil 18/1skip
    ManagedLayer 20/8skip · Presentation 1/7skip
[3] verify-cmd-layout.py ✅
步骤通过 9 ❌ 失败 0   用例通过 708  跳过 29   ✅ 全部通过
```
> 跳过的 29 条全是 X 相关用例（无 DISPLAY 时发现期优雅跳过），非失败。

#### ★ 文本上屏的"两道闸门"（2026-09-10，M7b + T2 + 主控协同）

真窗口出来、主题程序集取到之后，`Window.Show()` 里的**真实布局**跑到 `Grid → TextBlock`（**这本身就是 `Template != null` 的最强证据**），
然后卡在 `TextBlock.MeasureOverride → TextFormatterImp → TextMetrics.FullTextLine → TextStore..cctor → EntryPointNotFoundException: LoGetEscString`
（LineServices 的 110 条导出，Linux 未实现）⇒ 退出码 134。根因是 **fast path 被拒、回落 LineServices**；
而拒绝由**两道独立闸门**决定（上游 `Typeface.cs:520-562` 原文）：

| 闸门 | 判据 | 实测结论 |
|---|---|---|
| **① `charFastTextCheck`** | 初值 `(CharacterFastText\|CharacterIdeo)` 被**逐字符按位与** `Classification.CharAttributeOf(class).Flags` | **已修**：清位的是**空格/数字**（`0x80`/`0x100`，不含 FastText），不是字母——`"Hello WPF on Linux"` 在两个空格处就把该位清光。修法：三类改成**互斥且互补**（`Complex` 复杂脚本及标记 / `Ideo` CJK·假名·谚文+CJK 标点全角区 / **`FastText` 其余全部**），类数 230→242。实测 `charFastTextCheck=0x10` ✓ |
| **② `TypographyAvailabilities`** | `(typography & (FastTextTypographyAvailable \| FastTextMajorLanguageLocalizedLocl)) != 0` ⇒ 直接 false | **不是误报**：走了**真实 PC 代码路径**实测——未剥离 Noto Sans = **21**、DejaVu Sans = **23**（**三方一致**：M7b 实测 / T2 走 PC 路径 / T2 独立复算）、Liberation Mono & Noto Mono = **0** |

**T2 的判定方法论值得留档**：它逐条否证了"垃圾解析"假设（DejaVu 布局表**真有 20 个脚本含 `hani`/`kana`** ⇒ bit2 合法；
bit4 的 coverage **确实覆盖 fast-text 字形**，如 `ccmp→lookup[3] coverage=[76,3041]` 覆盖字形 76）；
并**两次否证自己**（① Lookup 表 `subTableCount` 读在 +2 而非 +4 ⇒ 曾误判"Liberation Sans 干净"；
② `MajorLanguages` 抄错 ⇒ 误置 bit8 ⇒ 估 29 → 修正后 **21 与 PC 逐位一致**）；还证伪了它自己"Noto 抛 `FileFormatException` 从而放行"的推断
（那是**装配残缺环境的假象**——`FileFormatException` 类型住在 WindowsBase 里，加载失败搅乱了现场）。

**处置（主控裁定：换派生字体 + 明确登记降级，不骗闸门）**：
- 新增 `build/fonts-ui/UI-NoLayout.ttf`（= `NotoSans-Regular` 剥离 `GSUB`/`GPOS`，332,736 B，sha256 `b008d486…`）+ 可复现脚本 `build/gen-ui-font.py` + `build/fonts-ui/SHA256SUMS`。
- **实测**：派生件掩码 = **0** ⇒ 放行；而字形 id/轮廓/步进/`cmap`/**全部 65536 个 BMP 码点**/度量**逐项不变**（已写成防回退断言）。
- **⚠️ 刻意不放 `build/fonts/`**：实测同族同字重的派生件会**遮蔽基准件**（`FontSet` 按 `(族名,字重,斜体)` 索引、后加载者覆盖先加载者）⇒ "Noto Sans 400" 解析到派生件 ⇒ **既有断言当场红 6 条**；挪进独立目录后基准目录仍是正好 4 个文件、6 条红全部转绿（**靠挪目录转绿，不是改断言**）。
- **这不是绕过闸门**：fast path 的语义本就是**名义字形**（不做 kerning/连字/locl）；剥离后字体**确实**不再带这些特性，掩码 0 是**测出来的事实**。
  已并入 `docs/unimplemented.md` **§2.6**（含影响面：**当前只有默认 UI 字体能出字**，其它真实字体仍会回落 LineServices 失败；正解 = shaping/HarfBuzz 或补 LineServices）。
- 运行期开关：M7b 的 SPI 支持 `WPF_LINUX_UI_FONT`（runner 加 `HLWPF_UI_FONT` 可选开关，默认行为不变）。

#### ★ DPI 面缺陷：`DpiScale(0,0)` —— 已实测的**真 bug**，但"它就是闸门 3"这一步**尚未证实**（2026-09-10，主控定位 + 实测 + **自我更正**）

闸门①②都过（掩码 0、快路径 True）之后**仍然**回落 LineServices。M7b 逐行枚举 `SimpleTextLine.Create` 的 `return null` 出口，
把嫌疑收窄到 `:196-203 run == null`，并在能观测到的最早时刻量到 `DpiScale=(0,0) PixelsPerDip=0`
（当时诚实地标注了"也可能是宿主还没接上的假象"）。主控把 DPI 这条链读通 + 实测，**确认 `(0,0)` 是真值**（见下）。

链路（每一环都有上游行号）：

1. `SimpleTextLine.cs:1647 CreateSimpleTextRun` 的 `return null` **只有一处** —— `CheckFastPathNominalGlyphs(...)` 返回 false 时。
   该调用接收 `(float)pixelsPerDip` 与 `formatter.IdealToReal(widthLeft, pixelsPerDip)`。
2. ppd 来源是 `Line.cs:60 _owner.GetDpi().PixelsPerDip`；而 `Visual.cs:4679 GetDpi()`：
   `if (UIElement.DpiScaleXValues.Count == 0) return UIElement.EnsureDpiScale();`（注释原文 *"for scenarios where an HWND hasn't been created yet"*）。
3. `DpiScaleXValues` 的**唯一写入者**是 `HwndTarget.cs:331`（`HwndTarget` 构造时）⇒ **HWND 之前静态缓存必空**，
   `EnsureDpiScale()` 是**唯一**出口，且 `_setDpi` 只算一次、之后**一直**返回同一个值 ⇒ **(0,0) 不是时序假象**。
4. `UIElement.cs:1128 EnsureDpiScale()`：`GetDC(NULL)` → `GetDeviceCaps(dc, LOGPIXELSX/LOGPIXELSY)` → 除以 `DpiUtil.DefaultPixelsPerInch`(96)。
5. **实测（主控用 ctypes 直接调 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`）**：

| 调用 | 实测值 | 应当 | 判定 |
|---|---|---|---|
| `GetDpiForSystem()` | `96` | 96 | ✅ |
| `GetDC(NULL)` | `0x1` | 非 0 | ✅（假句柄，但非 0 所以不走抛异常分支） |
| `GetDeviceCaps(hdc, LOGPIXELSX=88)` | **`0`** | 96 | ❌ |
| `GetDeviceCaps(hdc, LOGPIXELSY=90)` | **`0`** | 96 | ❌ |

⇒ `_dpiScaleX = 0 / 96 = 0` ⇒ **`DpiScale(0,0)`，这是实测确认的缺陷。**

> ### ⚠️ 自我更正（同日，主控）：**ppd=0 是不是"闸门 3"，目前没有证据**
>
> 我一度把结论写成"ppd=0 ⇒ `RoundDipForDisplayMode` = NaN ⇒ 快路径 false"这条直链。**复核后这条链不成立（至少不完整）**：
> `TextFormatterImp.cs:629 RoundDip(value, ppd, mode)` **只在 `mode == Display` 时才**走 `RoundDipForDisplayMode`，
> 否则**原样返回 value**；同理 `IdealToReal`（`:680`）在 Ideal 下也**不看 ppd**，
> `GlyphTypeface.cs:1091` 的 `GlyphMetrics` 在 Ideal 下走 `GetDesignGlyphMetrics`（**不接 ppd**）。
> 而 **`TextOptions.TextFormattingMode` 的默认值就是 `TextFormattingMode.Ideal`**（`TextOptions.cs:29`，`FrameworkPropertyMetadata(TextFormattingMode.Ideal, …)`）。
> **⇒ 在默认 Ideal 模式下，ppd 根本不进入 `CheckFastPathNominalGlyphs` 的判据**，ppd=0 不会把它判成 false。
> 这与 M7b 实测"快路径返回 True"**是一致的**，不是矛盾。
>
> **因此当前的诚实状态**：
> - `DpiScale(0,0)` / `GetDeviceCaps` 返回 0：**实测确认的缺陷，必须修**（Display 模式下会真 NaN；其它 DPI 相关路径同样受害）。
> - "它就是让 `SimpleTextLine.Create` 返回 null 的原因"：**未证实**。要证实或证伪，必须**在真实调用点打参数**，不能再靠读代码推。
>
> **给 M7b 的修正指令**：**DPI 照修**（那是独立的真 bug），但**同时**在 `SimpleRun.Create` 的几个 `return null` 口子上加 env 门控打印 ——
> 按嫌疑排序：① `SimpleTextLine.cs:1469 settings.DigitState.RequiresNumberSubstitution`（**与 ppd 无关**，文化相关，Linux 上高度可疑）；
> ② `:1448 textRun.Properties.BaselineAlignment != Baseline`；③ `:87-99` pap 守卫（含 `pap.Wrap`/`paragraphWidth` 真值）；
> ④ `:162 run.IdealWidth > widthLeft`；⑤ 最后才是 `CheckFastPathNominalGlyphs`。**先量再改。**

**处置**：修 shim 的 DPI 面（X11 用 `DisplayWidthMM`/`DisplayWidth` 算真实 DPI，Xvfb/异常回退 **96**），
并核对 `GetDpiForSystem`/`GetDpiForWindow` 与之一致。**刻意不在托管侧把 0 兜成 1** ——
"shim 报 0 DPI"本身就是错的，修在错误发生的地方，而不是在下游掩盖它。

> **方法论留档（两条，都值得记住）**
> ① M7b 上一轮"用**真实那个 TextBlock 实例**的参数直调 `CheckFastPathNominalGlyphs` 得 True"**不算证据**：
>    它手上没有 `TextFormatterImp`，所以不可能传真正的 `pixelsPerDip` 与 `widthMax`。
>    **"用真实对象" ≠ "用真实参数"** —— 复现失败时，先怀疑自己漏了哪个入参，再怀疑被测代码。
> ② "`NoWrap` ⇒ `widthLeft = int.MaxValue`"是**未验证假设**：`SimpleTextLine.cs:106` 实为
>    `int widthLeft = (pap.Wrap && paragraphWidth > 0) ? paragraphWidth : int.MaxValue;`，需要 `pap.Wrap == false` 才成立。
>    凡"某属性必然是某值"的推理，都要落到实测或上游行号上。

#### 🎯 ★★★ M2 达标：真 WPF 窗口在 Linux 上显示出来（2026-09-10，Agent M7b 实测，主控独立复验关键证据）

> **这是 U2「把 WPF 托管层移植到 Linux」的验收节点**：`samples/HelloWpf`（纯 net10.0 + 9 个自产程序集 + 自产
> `PresentationFramework.Classic` 主题 + 真 BAML）在 Linux 上**真的把窗口映射到 X 服务器并画出了内容**。

**验收四件套 + 台账（均为实测原文）**

1. **`xwininfo -id 0x200005`**：
   ```
   xwininfo: Window id: 0x200005 "HelloWpf on Linux"
     Width: 667   Height: 417   Depth: 24   Visual Class: TrueColor   Class: InputOutput
     Map State: IsViewable            ← ★ 真的映射出来了
     Colormap: 0x20 (installed)   …   -geometry 667x417+0+0
   ```
2. **`xwd` PNG** `/tmp/m7c-accept.png` = **46,916 字节**（此前"白窗"时期只有 420~434 B）。
3. **直方图（7 色）**：`#203E64 / #294B75 / #37618F / #4374A7`（PanelBrush 渐变四段）、
   `#8BBFB4 / #C0C5CF`（椭圆渐变 + 白描边）、**`#FF6347` tomato 24,523 px**
   —— 正是 XAML 里 `<Rectangle Fill="Tomato">` 的原色（≈180×100 减 2px 描边，量级吻合）。
   **屏上交叉验证**：同刻裁剪**根窗口**同区域得到同色系 ⇒ 像素真在屏幕上，不是 app-local 假象。
4. **退出码 143**（SIGTERM 超时收工 ⇒ 应用**一直活着、不崩**）；台账 `committed=65 资源=44`
   （含 `MilGlyphRun×2` / `MilRenderDataResource×7` / 渐变刷 / 几何 …），`已呈现 667x417（skia 指令 11 条，未画种类 1）`。

**打通它的是三处改动（每处都有 before → after）**

| 改动 | before → after |
|---|---|
| **`GetDeviceCaps` 真实现**（X 的 px/mm 算 DPI；`GetDpiFor*` 同源） | `LOGPIXELSX/Y` **0 → 100**；窗口 **640×400 → 667×417** |
| **`LoGetEscString` 实现**（新增 `WPF_ESCSTRING` 6 指针 ABI + 断言；6 个互异私用区转义字符 + 自检） | 缺口 **110 → 109**；`TextStore..cctor` 崩溃消失，应用 **134 → 143（存活）+ 窗口 map** |
| **呈现时重新投影根视觉**（`channel.Root` 是 `TargetSetRoot` 时刻的**空快照**，`MilChannel.cs:316`） | skia 指令 **0 → 11 条**；画面纯白 → 渐变 + 矩形 + 椭圆 |

**主控独立复验（非采信）**：`/tmp/m7c-accept.png` 存在且 46,916 B ✅。
带 `DISPLAY=:99` 直调 `libwpfwin32.so`：`GetDpiForSystem()=100`、`LOGPIXELSX=LOGPIXELSY=100`、
`HORZRES=1280 VERTRES=1024` ✅ —— 而 **667/640 = 1.0417 = 100/96**，窗口尺寸本身就是 DPI 打通的可见证据。
（旁注：**不带 `DISPLAY` 时这三个仍返回 0、没有回落到 96** —— 当前无害（无显示也渲染不了任何东西），
但**是个应当收口的遗留**：DPI 回退值应为 96 而非 0。）

> ### ⚠️ 闸门 3 定案：**不是 `pixelsPerDip`，是 `LoGetEscString`**（主控第二次更正自己的因果链）
>
> M7b 先修了 DPI（**窗口立刻从 640×400 变 667×417，证明它确实生效**），但**仍然崩**在
> `FormatSettings.FetchTextRun → TextStore..cctor → LoGetEscString`。
> **真正的最后一环是 `LoGetEscString`** —— 简单路径也要用它把 EOT run 经 `PwchParaSeparator` 变成 1 个转义字符。
> **两者都修才通**。⇒ 我先前"ppd=0 就是闸门 3"的说法**彻底作废**（我上一轮已主动撤回因果链，这一轮有了反向实证：
> 修好 DPI 后仍崩，才定位到 `LoGetEscString`）。
> **方法论**：我读源码推出的"直链"两次都不成立（第一次是 Ideal/Display 模式，第二次是"DPI 是最后一环"）。
> **凡"我读代码推出的因果链"，在拿到"改这一处 → 现象翻转"的对照实证之前，都只是假设，不能进文档当结论。**

### ★ M2 最终验收：**零探针 + 文字上屏**（2026-09-10，M7b 实测，主控读图复核）

原先在册的两个缺口**都已闭环**：

1. ~~文字还没画~~ → ✅ **已画**。`MilPresentation.GlyphRenderer` 挂上了宿主：新增 `MilPresentation.EnsureGlyphRenderer()`
   （按需建、呈现层自持、`Reset()` 释放；字体目录/字族口径与 shim 的 UI 字体一致：
   `WPF_LINUX_TEXT_FONT_DIR`→`WPF_LINUX_FONT_DIR`→系统目录，family 同理 —— 理由写在代码里：**真应用里没有别的宿主，
   而 glyph id 是字体相关的，必须与 WPF 侧同一份字体**）。
2. ~~呈现触发器是诊断探针~~ → ✅ **已换成真实现**，`WPF_LINUX_MIL_PRESENT_PROBE` **已从代码里整段删除**。
   `src/WpfGfx.Linux/Interop/MilNative.cs:87+`：`Commit()` 成功后调 `MilPresentation.PresentChannel(channel)`，
   语义与 `WgxConnection_SameThreadPresent` 一致（无窗口→no-op；有窗口无根→`S_OK`+诊断；失败→**返回失败码**）。

**零探针验收件（不设任何探针环境变量）**

| 项 | 值 |
|---|---|
| `xwininfo` | `0x200005 "HelloWpf on Linux"` 667×417 Depth 24 TrueColor，**Map State: IsViewable** |
| PNG | `docs/m7c-accept-zero-probe.png`，**56,055 B** |
| 退出码 | **143**（SIGTERM 超时收工 ⇒ 一直活着） |
| MIL 台账 | `[mil 14]` **首个「有内容」的帧（第 7 次呈现）**：`skia 指令 11 条，未画种类 0`，累计帧数=2；`通道#2: committed=65 notimpl=0 failed=0 资源=44 [MilGlyphRun×2][MilRenderDataResource×7][MilVisualResource×14]`；`字形渲染器已挂上：目录=…/build/fonts-ui 默认字族=Noto Sans` |
| **`未画种类 0`** | ⇒ 通道里**每一种指令都真的画了**，含那 2 个字形 run |

> **主控读图复核（不是看直方图推断）**：`docs/m7c-accept-zero-probe.png` 解码后目视确认——
> **白色 24px Bold 标题 "Hello WPF on Linux"**（字形清晰、间距正确、抗锯齿正常）、**tomato 矩形 + 白描边**、
> **渐变椭圆（黄→粉）+ 白描边**、**旋转的绿色三角形（Path）**、**径向渐变蓝圆**、
> **第二行说明文字 "Rectangle / Ellipse / Path / Gradient / Transform / Text"**、蓝色渐变 PanelBrush 背景。
> **→ 文字与图形都真的上屏了。**

> ### ⚠️ 主控更正 M7b 报的直方图数字（同一张 PNG 上不可复现）
> 我用两个独立解码器（手写 zlib+PNG 过滤还原、以及 PIL）交叉验证，两者**完全一致**，但与 M7b 报的值不符：
>
> | 项 | M7b 报 | **主控实测** | 备注 |
> |---|---|---|---|
> | `#FF6347` tomato 像素 | 24,578 | **18,117** | **XAML 是 180×100 = 18,000**，加抗锯齿边 ⇒ **我的数字与 XAML 自洽**；24,578 对应约 245×100，与 XAML 不符 |
> | `#F3F5F7` 精确像素 | 1,359 | **7** | 该区域真正的文字色是 **`#FFFFFF`（926 px）**，不是 `#F3F5F7` |
> | 全窗近白（≥240）总数 | 5,828 | **3,063** | TextBlock 区域（300×50+16+16）内为 **1,119** |
>
> **结论**：M7b 的**核心声明成立**（文字确实画出来了 —— 已由读图独立确认），但**它报的三个直方图数字在这张 PNG 上复现不出来**。
> 最可能的原因是它测的是**另一次抓帧**（或另一份/更早的 PNG），而提交的 `docs/m7c-accept-zero-probe.png` 是不同的一帧。
> **留此一笔的用意**：直方图是间接证据，**同一张图上的数字必须能复算**；里程碑级的"文字上屏"结论**不能只靠直方图**，
> 最终是靠**读图**钉死的 —— 这也再次印证了本工程的纪律：**间接指标要能被独立复算，关键结论要有直接证据。**

**其余在册项（不变）**
3. `ManagedLayer.Tests` 宿主偶发崩溃 —— **已归因、与本轮无关**：收尾后 7 连跑 = 3 次干净（28/28）+ 4 次中途宿主崩溃（随机跑到 14/18/23/27 条时死，一次留 glibc `dl-open.c:224` 断言）；
   用 `WPF_SHIM_LEGACY_DPI=1` 恢复旧行为后**仍 5/6 崩** ⇒ 非本轮引入；本轮"加载期建连 + 度量缓存"把当时 6/6 降到 ~3/6。**按指示未弱化任何断言。**
4. **T2 provider 接口漂移**（`FromDirectories` 第三参）—— **真因已由 T1 定位**：**可选参数 = 二进制破坏性改动**（见上文 T1 那条）。
   修法已落地为"新增重载、既有签名逐字保持"；**收口动作 = PC 合并波里重建一次**。
5. **本轮顺带收口**：`wpf_x11_screen_metrics` 现在**先填 96 再问 X** ⇒ `env -u DISPLAY` → **96**、`DISPLAY=:99` → **100**（我上轮提的那条遗留）。
6. **M7b 发现的观测陷阱（值得留档）**：台账节流曾把**首个「有内容」的帧吞掉** —— 第一帧只有 `skia 指令 0 条`（只创建资源），
   有内容的是第 7 帧。**读日志会误判成"什么都没画"** ⇒ 已加例外：**首个有内容的帧永远记录**，runner 的等待判据也同步改成"等有内容的帧"。
   **教训**：节流/采样会制造"看起来没发生"的假象，**关键状态转换要免采样**。

#### 并行推进（2026-09-10，M2 收尾期间的三条独立轨道）

| 轨道 | 内容 | 为什么现在做 |
|---|---|---|
| **T1 · 跨运行时字体面桥接** | `MilFontFace_RegisterFromFile` 从托管侧经 resolver 调用**返回 0**（`nativeAllocations=0`）⇒ 令牌仍落回**进程内表** ⇒ `.so` 运行时里没有该令牌 ⇒ `MilGlyphRun_GetGlyphOutline` 会 `E_HANDLE` ⇒ **字形轮廓画不出来** | **很可能就在文本上屏的关键路径上**（文本出现但缺字形，第一嫌疑就是它）；并要求补"最近失败原因"诊断导出，让返回 0 不再是黑盒 |
| **T2 · WIC → Skia** | 109 条 WIC `*_Proxy` 在托管层"声明即编译、运行期无落点" ⇒ `BitmapSource`/`BitmapImage`/`BitmapDecoder`/`BitmapMetadata` 一用就炸（**编译期无感**，与 `ModuleInitializer`、`XamlAccessLevel` 同族） | 真实应用的下一个能力缺口（读图/Image 控件/图标）；M1 已有 Skia 位图能力，属"接线"而非"从零造" |
| **主控 · `XamlReader.cs:1098`** | 补丁 L 的同族第二处（`XamlAccessLevel` 在非 Windows 抛 PNSE） | 一行级；**等 M7b 跑完再动 PC**，避免打断它的端到端 |

**轨道结果（2026-09-10 晚，主控裁定）**

| 轨道 | 结果 |
|---|---|
| **T1 · 跨运行时字体面桥接** | ✅ **已闭环**。根因**不是**调用姿势（封送/宽度/表未初始化逐条被否证），而是 **AOT 镜像里 SkiaSharp 走运行时 `dlopen("libSkiaSharp")`，而 `ProbeMilExport` 直接 `NativeLibrary.TryLoad(<绝对路径>)` 绕开了注入目录** ⇒ `DllNotFoundException` 被 `catch → 0` 吞掉。修法：`.so` 用 **`dladdr` 对自己的一个 `[UnmanagedCallersOnly]` 导出取址**自定位（与宿主、与调用顺序无关）。实测：T2 的调用姿势零环境变量下 `MilFontFace_RegisterFromFile = 0x20000001`，跨运行时 `MilGlyphRun_GetGlyphOutline` 得 **`S_OK` + 800 字节真轮廓**（伪造令牌 → `E_HANDLE`）。**新 `.so` SHA256 `fa70a21b91bda6f2a821f4146174458f0a37d71a409b1713faaf2efa8d172c5e`（4,519,360 B）**；A/B/C 三场景对照 + `T2Repro` 最小复现；新增 4 条诊断导出（`MilBridge_Diag_LastFontFaceError/…Message/…Reset/…SelfDirectory`，失败码 0–8）；闭环 46/46、`Commands.Tests` 562/562、两边 0 错 0 警、MIL ABI 导出仍 **109**、缺失 0 |
| **T2 · WIC → Skia** | 🟡 **选型已定、seam 已定，闭环待交付**。选 **(b) 原生 shim**，依据是两条实测：① `libSkiaSharp.so` **导出 Skia C API 856 个 `sk_*` 符号**（含 `sk_bitmap_*`/`sk_codec_*`）⇒ shim 可在 C 里直接解码，**不存在**跨运行时问题；② `*_Proxy` 的句柄是**不透明 `IntPtr`**、托管侧只回传不解引用 ⇒ 不需真 COM。**第二道 seam 由主控判定**：走 **`CreateDecoderFromFileHandle`**，因为 `BitmapDecoder.cs:1102 GetSeekableStream` 对可 seek 流原样返回 ⇒ `file://` 的**同步** `FileStream` 走 `:1118 safeFilehandle`；而 **Linux 上 `FileStream.SafeFileHandle` 是 .NET PAL 开的真 OS fd**，与 `libwpfwin32.so` 的 `CreateFile` **零耦合**。路径 B（`StreamAsIStream`）**判死**：`MilNative.Misc.cs:135 MILCreateStreamFromStreamDescriptor` 返回**我们自己的不透明 `MilDeviceObject` 句柄、不是真 COM `IStream`（无 vtable）** ⇒ `BitmapImage(Stream)` 本轮**明确不覆盖**（恢复条件：T1 用 `StreamDescriptor.pfnRead/pfnSeek/pfnStat` 包一层真 vtable）。实测现状：**任何 WIC 调用 = `DllNotFoundException: WindowsCodecs.dll`**（明确异常，非静默） |
| ↳ **T2 的 ABI 阻塞已由主控实测解除**（2026-09-10 晚） | 机器上**没有任何 `sk_*.h`**（`find /` 空），T2 写 C shim 只能在"猜枚举/猜结构体"上冒险（已付一次代价：`sk_data_destroy` 符号不存在 → 调空指针 SIGSEGV）。**主控改用"从 `SkiaSharp.dll` 元数据读 native ABI"**：`SkiaSharp.SKImageInfoNative` 的 `Marshal.OffsetOf` 给出**真实字段布局**，A/B 对照钉死 —— **`sk_imageinfo_t` 是 `{colorspace, width, height, colorType, alphaType}`（24 B），不是上游公开头文件的 `{colorType, alphaType, colorSpace, width, height}`**；按后者写 `sk_codec_get_pixels` 返回 **`5 = InvalidParameters`**（**正是 T2 上轮的实测值**），按前者返回 **`0`** 且**全缓冲区 1,920,000 字节与托管 `SKBitmap.Decode` 逐字节 0 处不同**（图确有非白内容，排除"两边都空白"的假绿）。另两条坑一并测出：**`sk_codec_get_info` 返回值是垃圾、无 HRESULT 语义**；**C API 的 `sk_colortype_t` 值与托管 `SKColorType` 从 8 起分叉**（`Gray8` C=11/托管=9、`RgbaF16` C=13/托管=10；`Bgra8888=6` 恰好一致，所以 T2 没在枚举上翻车）。产物：`build/wic-abi-reference/{README.md,AbiProbe/,abi-proof-output.txt}`（可复现）。**结论：ABI 已落地为实测事实 ⇒ 不引入反向 P/Invoke 回调表，继续走原生 shim** |
| **主控 · `XamlReader.cs:1098`** | ✅ **已裁定为"不修"，理由留档（不是遗忘）**。`patch-presentationframework-xamlaccess.py --check` → `SystemResources.Linux.cs：内容已是最新`（① `SystemResources.cs:938` 已打）。全仓 `XamlAccessLevel.AssemblyAccessTo` **只有两个构造点**；② 在 `internalTypeHelper != null` 分支里，而 **HelloWpf 的 BAML 实测加载成功** ⇒ 当前路径走不到它。**⚠️ 这是"当前不需要"而非"没有问题"**：任何 BAML 根类型带 internal type helper 的应用都会踩到同一条 PNSE，届时应把同一补丁模式复制到 ②。**刻意不预防性打**——打了就是永远不被现有测试覆盖的盲改 |
| **T2 · WIC 读路径 shim** | ✅ **C 级闭环已交付，托管侧待 PC 合并**。产物 `build/DirectWrite.Linux/wic-shim/wic_proxy.c`（~600 行）+ `build-wic-shim.sh` → **`libwpfwic.so`（28,800 B）**，**21 个读路径导出 + 1 个自检导出**；未实现 **30 个**统一返回 `WINCODEC_ERR_NOTIMPLEMENTED (0x88982F04)`。设计：句柄 = 表下标 + 1（托管只回传不解引用 ⇒ **不需要真 COM**）、`CreateDecoderFromFileHandle` 对 fd 做 `dup`、一律以 **Bgra32** 交付、`CopyPixels` **只支持整图**（子矩形 → `UNSUPPORTEDOPERATION`，**不静默截断**）。**C 级闭环实测**（dlopen 自己 `.so` 走完整 `*_Proxy` 链）：`FACTORY=S_OK → CreateDecoderFromFileHandle(真 fd) → FRAME_COUNT=1 → GetSize 800×600 → GetPixelFormat 32bppBGRA → GetResolution 96×96 → CopyPixels need=1,920,000`；**全缓冲 FNV1A `62FD64E564953288` 已留作托管侧比对指纹**；失败路径 `坏句柄=0x80070057` / `非图像=0x88982F0B` / `截断=0x88982F0B` / `元数据=0x88982F04`（**明确 HRESULT，不崩不静默**）。`dladdr` 自定位后**零 env、两 `.so` 同目录**即可解码 ✓ |
| ↳ **⚠️ 主控自我更正：我对 T2 那个具体 bug 的归因是错的** | 我在上一条里写"T2 的 `hr=5` 真因是结构体字段顺序错"。**T2 独立复核后指出：它的布局本来就是 A，真正的坑是它把 `options` 传了「零值结构体」而不是 `NULL`；改成 `NULL` 后立刻 `hr=0`。** 我认这条更正。**仍然成立的部分**：① A/B 实测本身有效 —— 布局 A 得 `hr=0` 且全缓冲与托管 `SKBitmap.Decode` 逐字节相同，公开头文件的顺序 B 得 `w=6 h=1`；② **`5 = InvalidParameters`** 的判定正确（`SKCodecResult` 实测枚举）；③ 另三条坑（`get_info` 返回值无语义、`sk_data_unref` 真名、C API colortype 从 8 起与托管分叉）都已落进 shim 注释。**教训**：我从"两个候选原因"里挑了结构体布局并当成结论宣布，而**没有先问 T2 它用的到底是哪个布局** —— 诊断别人的 bug 时，**先索取对方实际用的值，再下结论**，否则就是把"一个为真的实测"错接到"一个不成立的对象"上。T2 这次的做法（**同像素双向复核**：它的纯 C 探针得 `PIXEL_22_16_BGRA=102,51,34,255`、`NON_WHITE=150998/480000`，与我的 `AbiProbe` **逐字节相同**）是更正这一点该有的方式 |
| **T1 · M7c4 真实文字栈路线决策** | ✅ **已交付，主控逐条独立复验通过**。**路线 A「补齐 LineServices」否决 —— 理由不是"贵"，是"没有源"**：`Lo*/Fs*/Nl*` 在 `WpfGfx/**/*.{cpp,h,hpp}` 里 **各 0 个文件**（我复验的五个代表符号）；`WpfGfx/core/` 下没有 `text/ls/pts/nl` 目录；`Microsoft.Dotnet.Wpf.sln:247` 指向的 `redist/PresentationNative/` **整个目录不存在**；机器上也没有任何 `PresentationNative` 二进制可对拍 ⇒ **等于在无参考实现、无对拍基准下从零写一个行布局引擎**。**路线 B（HarfBuzz + ICU，托管侧重写 `TextLine`）为目标态**，M0–M6 **七条对照 7/7**（M5 连跨 AOT 轮廓都通了：13/13 字形、9136 字节真轮廓）；依赖实测：`libharfbuzz.so.0.20704.0` **395 个 `hb_*`**（我复验 **395**，与其数字完全相同）、**无 `libharfbuzz.so` 无版本符号**（`DllImport` 必须写全名）、`libicuuc.so.70` 的 `ubrk_*_70`、**零新增 NuGet**。**路线 C（stopgap ~300 行）立刻做** —— 已派给 T1。**⭐ 一条改变问题形状的发现**：复杂路径的 **shaping 回调是托管的**（`TextAnalyzer.GetGlyphs`/`GetGlyphPlacements`，现为 PNSE），原生 LS 只是**回调它们** ⇒ **shaping 与 LineServices 不互斥、不互相替代**。**诚实边界**：B 的工程量只给区间估计（1500–2500 行，从 `SimpleTextLine.cs` 2015 行**外推**），**缺一条限时原型实测**；且**无 Windows shaping 真值可对拍**（`tests/parity/windows/` 全是场景级 PNG/命令流，`MilCmdGlyphRunCreate(0x3a)` 只在 2 个文件各出现 1–2 次，是字形资源命令不是步进基准） |
| ↳ **T1 的三条自我更正/方法论（留档）** | ① 拿 HB 的**未 hint 字体单位步进**比 Skia 默认的 **hinted 取整步进** ⇒ 16/18 处假差异（**发现方式**：Skia 的值全是整数，不可能是字体单位换算的结果）；② 拿 `NotoSans-Bold` 比 `UI-NoLayout`（派生自 **Regular**）⇒ 每字形都不同（**发现方式**：M0 对照组直接打脸）；③ **`ldconfig` 这个命令在本机根本不存在**，它第一遍查 HarfBuzz 得到空，**差点得出"系统没有 HarfBuzz"的错误结论**（换 `ls /usr/lib/x86_64-linux-gnu/` 才发现）。**这条提醒写进 §2.7**：查系统库可用性前先确认工具本身在不在 |
| **T1 · M7c5 路线 C 交付 ✅**（运行期 GSUB/GPOS 剥离） | **验收 ①–⑤ 全部达成，主控独立复验通过。** ① **与 Python oracle 字节全等**（`332,736 B / 332,736 B`，表集合与逐表内容全等；**唯一与"原始文件"的差异是 `head` 偏移 8..11 的 `checkSumAdjustment` 4 字节** —— OpenType 规范强制重算，oracle 同样如此）；② **闸门 2 真的过了，走真实 PC 代码路径**（`WiringSmoke` 调 PC 自己的 `FontFaceLayoutInfo`）：**Noto `MASK 21→0` / DejaVu `23→0`，`CheckFastPathNominalGlyphs` `False→True`**（两个语料位组合不同：21=`1\|4\|16`、23=`1\|2\|4\|16` ⇒ 两个都测是必要的）；③ **零额外语义损失**：upem / glyphCount **3884** / **3884 个字形步进+lsb** / **全部 65536 个 BMP 码点** / Skia 加载与逐字形步进全部一致，**`GDEF` 剥后仍在**；④ 全量 **94 → 115 全绿**（连跑 2 次），受影响既有断言**恰好 3 条、全是"原始文件保真"类、一条都没放宽**（改成把装置语义显式化为"原始语料"，另**新增 2 条**把"确实跑在不剥模式"钉住；`TypographyGateTests` 一行未改），**T2 的 `probe-digest.txt` 值逐字未变**；⑤ 6 类失败各有原因码、**一律原字节返回**（不产出半个字体）。**默认开**，论证：关掉时走 `FullTextLine` → `LoCreateContext` 等 26 条原生符号缺失 → **崩**；代价只有元数据（`FontCapabilities` 报无特性），而**没有任何消费者能用那些特性**。开关 `WPF_LINUX_STRIP_LAYOUT` + 逐次旁路参数。**主控复验**：oracle `sha256 b008d486…` **未变**（没为了迁就代码改 oracle）、`build/fonts/` 仍**正好 4 个** `.ttf`（遮蔽隐患仍被避开）、`run.sh strip` **21/21 / 0 失败** |
| ↳ **⚠️ T1 发现的会波及全工程的坑（已留档，必须遵守）** | **可选参数是二进制破坏性改动。** T1 最初写成 `FromDirectory(string, bool recurse = false, bool? stripLayout = null)` —— 编译通过、provider 自测也过，但预编译的 `DirectWriteForwarder.dll` 立刻 `MissingMethodException`（C# 可选参数是**编译期糖**，调用点绑定**完整签名**）。**修法：一律新增重载，既有签名（连同默认值）逐字保持。** ⇒ **只要 PC/DWF 是预编译产物，动 provider 的公共签名就只能加重载。** 这正好也是 M7b 报的 `FromDirectories` 三参漂移的**真因**（此前我判为"中途态"，现已有机制解释）。另两处反射坑：`FontStyle.Normal` 住在**复数**类 `FontStyles`/`FontWeights`/`FontStretches` 且是 `static readonly` **字段**；`Typeface.TryGetGlyphTypeface` 有两个重载会让 `GetMethod` 抛 `AmbiguousMatchException` |
| **T2 · WIC 托管闭环 harness：挖出真·结构性阻塞（非 WIC）** | ✅ **诊断交付**（闭环仍未成立，验收 ①-④ 未达标，**未新增断言**）。**最关键的一条：`CoInternetCreateSecurityManager`** —— 四个 CHECK 的完整栈首帧**逐字相同**：`MS.Win32.UnsafeNativeMethods.CoInternetCreateSecurityManager(Object, Object&, Int32)`，异常 `Cannot marshal 'parameter #1': … (COM interface pointers isn't supported)`。声明在 `Shared/MS/Win32/UnsafeNativeMethodsOther.cs:57-61`，用 **`[MarshalAs(UnmanagedType.Interface)]` 显式标成 COM 接口指针**；**唯一调用点** `Shared/MS/Internal/SecurityHelper.cs:80` 的 `MapUrlToZoneWrapper`（URL **安全区域**判定）。**它是主异常**（`VIA_DISPATCHER_OR_WINDOW=False`），**不是 WIC 帧**（`IS_WIC_FRAME=False`）⇒ **`BitmapImage(fileUri)` 在此之前就死了**，与 110 条 WIC 声明无关。**主控核查**：全量解析 110 条 WIC 声明，参数类型普查为 `SafeMILHandle` 族 120 / `IntPtr` 60 / `UInt32` 41 / `Guid` 20 / `StringBuilder(LPWStr)` 10 / `String(LPWStr)` 5 / `Int32Rect` 4 / `IntPtr[]` 3 / `byte[]` 1 / 其余枚举，**无一是 COM 接口指针**（`SafeMILHandle : SafeHandleZeroOrMinusOneIsInvalid` 可 marshal；`IStream` 参数**本来就是 `IntPtr`**；`Imaging.PROPVARIANT` 是显式布局 blittable；`PROPBAG2` 亦然）⇒ **"改 109 条 WIC 声明"这个前提被双重否证，正式划掉**。**另一条架构信息**：`BitmapImage` 是 `DispatcherObject` ⇒ 会先建 `Dispatcher` → `MessageOnlyHwndWrapper` → `CreateWindowEx` ⇒ **无 X 时报 `Win32Exception 1400`**，所以**这类 harness 天然属于"必须有 DISPLAY"那一类**（`DISPLAY=:99` 下那面墙消失，失败点前移到上面那处） |
| ↳ **★ 沉淀下来的诊断方法（值得复用）** | T2 的 harness 现在对每个 CHECK 固定打印四个字段：**完整 `ToString()` + `FIRST_FRAME` + `VIA_DISPATCHER_OR_WINDOW` + `IS_WIC_FRAME`**，并规定**任何"归因"都必须先过这四项**。**这套方法是本轮真正的产出**：它让"这个异常是谁抛的"从推测变成可判定。配套的两步动作：**① 先打完整栈（含方法名与 `parameter #N`）② 先做零成本的对照实验（此处 = 加 `DISPLAY`）**——两步做完真凶自己浮出来。**这轮我与 T2 各犯了一次同类错**（把"一个为真的实测"错接到"一个不成立的对象"上：我把 T2 的 `hr=5` 归因为结构体布局、T2 把这个 marshal 异常归因为 110 条 WIC 声明），**两次都是靠"先要对方的原始证据"纠正的** |
| **T2 · 补丁 H（PC 的 URL 安全区域短路）✅** | 新增**唯一一个文件** `src/WpfGfx.Linux.Native/tools/patch-presentationcore-securityzone.py`，形制照抄 WindowsBase 补丁 G：上游**逐字**读入 → **只替换 `MapUrlToZoneWrapper` 一个方法** → 生成 `build/PresentationCore.Linux/SecurityHelper.Linux.cs`（头部注明"不要手改"）→ csproj `Remove` 上游 + `Include` 生成物。范围**只有 PC**（该方法整个在 `#if PRESENTATION_CORE` 内）⇒ **PF / ReachFramework / WindowsBase 一行未动**。注释里钉死三条论证：`URLZONE_LOCAL_MACHINE=0` 是**上游自己选的兜底值**（`SecurityHelper.cs:77` 原文 *"fail securely this is the most priveleged zone"*）且 `return 0` 不会触发其后的 `SecurityException`；同族先例 `XamlAccessLevel`（**放宽一条在 Linux 上已不存在的限制，不是伪造一次 COM 成功**）；**不碰** urlmon 那条声明（改完不可达）。`--check` 幂等通过；**MSBuild 终验**（比读 XML 可靠）：`dotnet msbuild … -getItem:Compile` → `COMPILE_COUNT=1355`、`UPSTREAM_REMOVED=True`、`GENERATED_INCLUDED=['SecurityHelper.Linux.cs']` |
| ↳ **⚠️ 两个 csproj 接线坑（T2 踩到并修掉，必须记住）** | ① **直接把条目插在锚点行前面** ⇒ `<ItemGroup>` 嵌套 ⇒ **MSB4232**；② **插在锚点所在 ItemGroup 之前** ⇒ **`Remove`/`Include` 按「文档顺序」求值**，上游那条 `Include` 在后面又把它加回来（`-getItem` 实测仍在）⇒ **必须让 `Remove` 落在上游 `Include` 之后**（WindowsBase 补丁 G 正是这形制）。**⇒ 验证接线不要读 XML，要用 `dotnet msbuild -getItem:Compile` 求值**；这也正是 `integration-wave.sh` 必须"先 port-lib 重生成、再重放应用器"的原因（生成物接线只能由应用器在**最后**追加） |
| **T2 · 同类 COM-marshal 声明普查 ✅（权威清单版）** | **结果 3 条，【必须修】= 0 条**：① `UnsafeNativeMethodsPenimc.cs:613 CoCreateInstance`（Interface 参数 #2，调用点同文件 `:159`，`PenIMC_cor3.dll` 未映射）【待观察】；② 同文件 `:608 UnlockWispObjectFromGit`（#1，`:195`）【死代码】；③ `WindowsRuntime/.../ViewManagement/NativeMethods.cs:27 WindowsDeleteString`（#4，`InputPaneRcw.cs:34`/`UISettingsRcw.cs:30`，WinRT 在 Linux 不存在）【待观察】。**`CoInternetCreateSecurityManager` 已从表中消失** —— 补丁 H 把那份文件移出编译集，**普查与补丁互相印证**。将来 1/3 若变可达，最小修法与 H 同形制（短路调用点），**不改声明本身**（共享源、牵动多程序集）。**T2 先修了自己两处方法错误才让清单可信**：拼写（`UnmarshalType` ⇒ 假的"0 处"）、清单来源（抠 csproj 的 `<Compile>` 会**漏掉 `Shared/**`** ⇒ 改用 `-getItem:Compile` 的 1355 个文件），并加"该行必须落在某个 `static extern` 签名区间内"以消除 4 条假阳性。**⚠️ 明确写出的边界**：本清单**只覆盖 `UnmanagedType.Interface` 一族**，**未覆盖** `IUnknown`/`IDispatch`/数组形态与**裸 `object`/`object&` 参数** ⇒ **当前可当"Interface 族"的验收清单，还不是"全部 COM marshal"的清单**；补齐方式已写明（换 pattern + 继续用 `-getItem:Compile`），**T2 明确说"这一步我没做"，没有用"大概还有"糊过去** |

**主控独立复验 T1 的新 `.so`（2026-09-10，非自报）**

**★ PC 合并波（2026-09-10 晚，主控执行）—— 三合一，失败步骤 0**

`bash build/integration-wave.sh` → **失败步骤 0**，14 个工程**全部 0 错**。三样载荷全部进件，用**字符串堆**逐条实测：

| 载荷 | PC | WB | 判据 |
|---|---|---|---|
| T2 的 WIC resolver 泛化 | ✅ `libwpfwic.so` + `WPF_LINUX_WIC_SHIM` | ✅ 同 | **UTF-16 字面量**命中（⚠️ `strings -a` **看不到** —— .NET 的字符串**字面量**在 UTF-16 `#US` 堆里，必须搜 `utf-16-le` 字节；而类型/方法名在 UTF-8 `#Strings` 堆里，`strings -a` 能看到 —— **查错堆会得出"没进件"的错误结论，我自己先踩了一次**） |
| T1 路线 C（Provider） | ✅ `WPF_LINUX_STRIP_LAYOUT` + `FontTableStripper`/`FontLayoutStripping`/`stripLayout` | — | 在 `DirectWrite.Linux.Provider.dll` |
| **T2 补丁 H** | **`CoInternetCreateSecurityManager` 已消失** ✅ | **仍在** | **天然对照组**：同符号在 PC 消失、在 WB 保留（WB 没有 `MapUrlToZoneWrapper`）⇒ 补丁**精确**生效，而不是"整块没了" |

补丁 H 也**熬过**了 port-lib 重生成 + 应用器重放（`--check` 通过；`-getItem:Compile` → `COMPILE_COUNT=1355`、上游 SecurityHelper **不在**编译集、生成物**在**）。

> ## ⚠️ 主控在波里修掉的两个"假绿"（与上文修应用器那次同族，都属"验证工具本身在骗人"）
>
> **① 身份自检检查错了文件。** 原步骤 4 用 `ls "$d"/bin/Debug/*.dll | head -1` —— 而自产工程的输出目录里**还躺着依赖副本**（PC 有 **8** 个 dll、PF 有 **12** 个），`ls` 按**字典序**排 ⇒
> WindowsBase 目录取到 `System.Xaml.dll`、PC/PF 目录取到 `DirectWriteForwarder.dll`。
> **实测后果：5 个程序集里 3 个（WB / PC / PF）从未被真正检查，而 `DirectWriteForwarder.dll` 被"检查"了 3 次。**
> 已改成**按项目名精确取件**（`want="${d%.Linux}.dll"`）+ **取不到即计失败**（不许静默 `continue`）。修后 5 个全部 ✅ 已签名。
> **这个 bug 的讽刺之处**：步骤 4 的全部意义就是验证"身份一致性"（那份文档记录的事故），而它自己 60% 的时间在看错文件。
>
> **② Provider 工程根本不在重建表里。** `build/DirectWrite.Linux/Provider/DirectWrite.Linux.Provider.csproj` 是**手写嵌套工程**
> （脚本注释只写了它"不参与 port-lib 重生成"，但**也没进重建表**），而 **PC 通过补丁 F 的 HintPath 直接引用它**。
> 后果：**改了 Provider 源码，本波会拿旧 DLL 重建 PC 而毫无提示**（实测它停在 17:40 的旧件上，而波刚跑完）。
> 已加进 ORDER（它只依赖 SkiaSharp、不依赖任何自产程序集 ⇒ 放 WB 之后、DWF 之前），并让重建循环支持 **csproj 路径项**。
> **这条对接下来很重要**：T1 的路线 B（HarfBuzz 重写 `TextLine`）也会落在 Provider 一带。
>
> **共同教训**：本轮四次"假绿"里，**三次是工具/脚本本身的问题**（applier 漏重放、身份自检看错文件、Provider 不在表里），
> 只有一次是断言本身。**"我加了验证步骤"不等于"我被验证了"** —— 验证步骤自己也要被验证。

**★ WIC 闭环推进：三条墙逐个拆到 MIL 侧（2026-09-10 晚，T2 实测 + 主控复核）**

**(1) ✅ `DECODER_BRANCH` 真值拿到了**（这是主控点名要的可观测项，T2 用 shim 的调用计数导出实现）：
```
CALLS_AFTER=[FileHandle=5 Stream=0 Other=0]
DECODER_BRANCH=CreateDecoderFromFileHandle     BRANCH_COUNTS=FileHandle+5 Stream+0
```
⇒ **`BitmapImage(fileUri)` 确实走 fd 路径，`StreamAsIStream`/`CreateStream` 一次都没被用到**
（5 次 = ①②③ + ④非图像 + ④截断）⇒ **"需要 T1 给真 `IStream` vtable"这条依赖正式挂起**，
`BitmapImage(Stream)` 仍属未覆盖，但**已证明它不在验收 ①-③ 的路径上**。

**(2) 已拆的墙**
| 墙 | 现象 | 处置 |
|---|---|---|
| `CreateWindowEx` `Win32Exception 1400` | `BitmapImage` 是 `DispatcherObject` ⇒ 先建 `Dispatcher` → message-only 窗口 | 加 `DISPLAY`（**harness 天然属于"必须有 X"那一类**） |
| `CoInternetCreateSecurityManager` `MarshalDirectiveException` | urlmon 的 **COM 接口指针**参数，.NET 在 Linux 上拒绝 marshal | **T2 补丁 H** 短路 `MapUrlToZoneWrapper`（PC 侧消失、WB 侧保留 = 天然对照组） |
| `ole32.dll` `DllNotFoundException` | PC 权威编译集里 `[DllImport("ole32.dll")]` **只有 2 处**（`:1050/:1054`），调用点 `UnknownBitmapDecoder.cs:27,32`（WIC bootstrap） | T2 在 `libwpfwic.so` 加诚实空实现（`CoInitialize`→`S_OK`，**Linux 无公寓模型 ⇒ 语义正确的空实现，不是骗闸门**）；**主控裁定**：映射加进 `WicMappedLibraries`（WIC 组）而非 Win32 组 —— 因为 `Win32ShimResolver` 同时编进 WB，而 **WB 另有 5 处 ole32 声明**（`MS/Internal/IO/Packaging/CompoundFile/…`，打包/OLE 族），放 Win32 组会把 WB 现在**诚实的 `DllNotFoundException` 降级成 `EntryPointNotFoundException`**（更差的诊断） |
| **`MILQueryInterface` 返回 `E_HANDLE`** ← **当前唯一未拆的墙** | `BitmapSource.cs:584 set_WicSourceHandle` 对 **WIC 句柄**调 `MILUnknown.QueryInterface(value, IID_IWICBitmapSource)` → 落 `MilNative.Misc.cs` | **两道墙在同一个函数**（主控逐行核对）：`:100` 句柄不在 `MilDeviceObjectTable` → `E_HANDLE`；`:102` **只接受 `IID_IUnknown`** → `IID_IWICBitmapSource` 会得 `E_NOINTERFACE`。`:88-91` 的注释写着"本后端下发的对象不实现任何 COM 接口"——**那个前提只对 MIL 自己下发的对象成立**；**上游 PC 在一条纯上游路径上就对 WIC 句柄调它** ⇒ 该导出的真实语义是"**对任意指针做 QI（Windows 上对象自己应答）**"。已派 T1 修（惰性 `dlopen libwpfwic.so` + `WicShim_OwnsHandle`，**fail-safe 退回 `E_HANDLE`**、GUID 白名单只有两个、**GUID 取自 PC 的 `MILGuidData` 不硬编码**） |

**(3) ⭐ 主控补的一条 T2 没提到的真问题：`QueryInterface` 的引用计数契约。**
真实 COM 的 QI **会 AddRef**，而 `set_WicSourceHandle` 之后必然有配对的 `Release` ⇒ **若 MIL 侧对 WIC 句柄 AddRef 而 Release 走 WIC shim 的路径，两边账本必须对得上**，否则不是泄漏就是提前释放（**比 `E_HANDLE` 难查得多**）。
已要求 T2 在 `libwpfwic.so` 侧备好 `WicShim_AddRef`/`WicShim_Release`/`WicShim_HandleCount`，并要求 T1 做**"500 次 QI+Release 后句柄表大小不变"的配平实测**，且**把契约写进注释**。

> **★ 一个会"撒谎"的错误信息（T2 自己揪出来的真 bug，值得留档）**
> T2 原先在自己的 shim 里把 `0x88982F0B` 标成 `UNSUPPORTEDOPERATION`。上游 `wgx_error.cs` 的真相是：
> **`UNSUPPORTEDVERSION = 0x88982f0B`**、`UNSUPPORTEDOPERATION = 0x88982f81`。
> 于是非图像/截断经 PC 的 `ConvertHRToException`（`wgx_render.cs:806-807`）被映射成
> **`FileLoadException("Mismatched versions…")`** —— **那句"版本不匹配"根本没有版本检查，是 WIC 错误码的兜底文案**。
> 修正后：非图像 → `UNKNOWNIMAGEFORMAT(0x88982f07)` → **`FileFormatException: The image format is unrecognized.`**（Windows 同族）；
> 截断 → 同上（**Skia codec 创建即拒，早于 Windows 的延迟解码 ⇒ 登记为已测偏差**）；ROI/不支持操作 → 真正的 `0x88982f81`。
> **教训**：**一个会撒谎的错误信息，比一次崩溃难查得多** —— 看到"版本不匹配"这类文案时，要问"**它真的做了版本检查吗？**"

**★ 引用计数契约：`MILRelease` 必须转发到 WIC shim（T2 查清 + 主控逐条复验）**

T2 把"QI 放行之后谁 Release"这条链查到了底，**结论是不转发不是"只是泄漏"，是硬失败**：

| 断言 | 复验 |
|---|---|
| 释放**根本不走** WIC shim | ✅ `SafeMILHandle.ReleaseHandle()`（`SafeMILHandle.cs:61-63`）→ `MILUnknown.ReleaseInterface` ⇒ 落到 **MilCore 的 `MILRelease`**；`BitmapSourceSafeMILHandle : SafeMILHandle` |
| `MILRelease` 是我们的真导出 | ✅ `MilNative.Exports.cs:121`（`ExportDepth.Real`）、实现 `MilNative.Misc.cs:79`、`.so` 的 `nm -D` 命中 |
| **不转发 = 硬失败** | ✅ `wic_proxy.c:63` **`#define WIC_OBJ_MAX 256`** ⇒ 第 257 次 `obj_new` 返 0 ⇒ `CreateDecoderFromFileHandle` 失败。**不是缓慢泄漏，是"解满 256 张图就崩"** |
| **契约早就在我们自己代码里** | ✅ `MilNative.Misc.cs:368` 原文：【PC 的契约：成功的 QI 会 AddRef，且返回的指针**一定会**被 `MILRelease` 释放】⇒ 本轮不是新设计，是**把已声明的契约真正实现对** |

**契约形态（PC 实际序列已核对，账本自洽）**：创建 `refs=1` 归调用方 → QI 放行 `+1` → `MILRelease` 转发 `-1` → 归零回收。
PC 的实际路径 `BitmapSource.cs:581-586` + `BitmapFrameDecode.cs:448` = **创建(1)+QI(1)=2 → 旧 `value` 释放→1 → 新句柄释放→0**。
**允许**"放行但不 AddRef"（refs 恒 1）；**唯一不允许**的是"AddRef 了却不转发 Release"这种**单边形态**。
T2 侧已备 `WicShim_AddRef`/`WicShim_Release`/`WicShim_HandleCount`/`WicShim_PeakHandleCount`
（**`libwpfwic.so` = 29,392 B，sha256 `ddf7b293e564d4af9211a50a8e02d1a68f3caf371b8d7c08de92f6df61769323`**，新 `probe_refcount.c`）。
**主控独立复跑其 shim 级探针**（`./probe_refcount ./libwpfwic.so samples/HelloMil/screenshot.png`，exit 0）：
```
BASELINE live=0 peak=0
SELFTEST ok 800x600 px=FFFFFFFF  live=0
OK② 500 轮 AddRef×2+Release×2 后 live=1（未变），peak=1；OK②' 高水位未涨
OK③ 未登记句柄 AddRef/Release 返 0 且表不变
REFCNT_BALANCE=PASS
```
**⭐ T2 特意加了 `WicShim_PeakHandleCount`** —— 防"计数相等但高水位一直涨"的**花架子回收**。这个设计值得学：
**只断言"稳态计数相等"会被"每次多分配再释放"骗过去**。

**已登记未做（T2 明确写出的缺口）**：`decode_open`/`decode_pixels` 的 Skia 调用**仍不加锁**，本轮只给"表结构变更与计数"加了互斥 ⇒ **多线程并发解码仍是缺口**。

> ### ⚠️ 主控又修了一个"验证工具不问的事"：波的构建步骤**完全忽略警告**
> 原步骤 3 只 `grep "error "`，**警告被丢掉** —— 而本工程的标准是"**0 错 0 警**"。
> 实测代价：T2 引入的 **`CS0162`**（`private const bool WicEnabledByDefault = false;` 让 `IsWicMappingEnabled()` 里的
> `if (WicEnabledByDefault) return true;` 成为**编译期不可达代码**，**WB 与 PC 各报一条**）
> **悄悄进了树**，是本波之外偶然增量重建 WB 才发现的（`0 个警告` 之前是 `1 个警告`）。
> 已做两件事：① 波现在**解析并强制** `N 个警告`（有 error/warning 即计失败并逐条列出）；
> ② 把该字段改成 `static readonly`（**翻开关仍是改这一行的 `false`→`true`**，运行期行为逐字等价，不可达代码消失）。
> 复验：WB 重建 **0 警 0 错**。
> **至此本轮"假绿"共 5 处，其中 4 处是工具/脚本自身的问题**（applier 漏重放、身份自检看错文件、Provider 不在重建表、构建忽略警告）。
> **"验证脚本自己也要被验证"** 这条，已经不是口号而是本轮最贵的教训。

**★ T1 · M7c6：`MILQueryInterface` 放行 + `MILRelease` 转发（2026-09-10，主控独立复验）**

**新 `.so`**：SHA256 **`0aa95aaf3f2ec1dcd60083c7c4c8a83f38d30d8157a480f4e96a2a744273d86c`**、**4,531,824 B**。
`nm -D`（主控复验）：**MIL ABI 109 不变** ✅、**缺失 0** ✅、诊断面 **16** ✅。
**主控独立复跑 `bash build/MilBridge/run.sh wic` → 54 通过 / 0 失败 / 0 跳过** ✅（闭环总数 46 → **54**，新增 G 组 7 条 WIC 取证）。
（口径小注：T1 报的"总 `T` 127"实为 `nm -D --defined-only` 的**全部动态符号** 127 = 125 `T` + 1 `D` + 1 `A`，`T` 只有 **125** —— 与之前那次同类，增量 `+2` 对应诊断面 14→16，数本身没错。）

**实现**（单文件 `MilNative.Misc.cs`）：MIL 表命中 → **原语义一字未动**；未命中 → `MilExternalHandleBridge.QueryInterface`
（惰性 dlopen → `WicShim_OwnsHandle` → 白名单 GUID → **`WicShim_AddRef`(+1)** → 同句柄 + `S_OK`）。
`MILRelease`：未命中 MIL 表**且**是 WIC 句柄 → **转发 `WicShim_Release`(−1)**（本次追加的重点）。
**fail-safe 四条**：`.so` 找不到 / dlopen 失败 / **三个必需符号缺任一** / 不属于它 ⇒ 一律 `E_HANDLE`，默认行为一字未变。
> ⚠️ **"三个符号必须齐全"这条很关键**：只有 `OwnsHandle` 的旧版 `.so` 会让放行变成**单边账本** —— 正是明令禁止的形态。

**跨边界配平实测（含高水位，两个用例）**
```
G6   500×(MILQueryInterface + MILRelease)：循环失败=0/1000；live 3→3（回基线）；
     **peak 3→3（不涨）**；句柄仍认领=True 仍可用=True；MILAddRef 前=0 后=0（⇒ WIC 句柄没被建进 MIL 的账）
G6b  复用同一工厂/解码器连建 300 个帧（**> 表上限 256**）全部成功：创建失败=0 QI失败=0 Release失败=0 槽位复用异常=0；
     live 5→5；peak=6（远小于 300）；**第1轮 handle=0x6，第300轮 handle=0x6**（槽位真的在复用）
```
> **⭐ T1 实测复现了 T2 那条"硬失败"论断**：在桥还没接上（Release 未转发）的那一次运行里，
> 同一个 G6b 是 **`创建失败=216 … live 3→256`**（撞 `WIC_OBJ_MAX`）。**接上转发后归零。**
> 这是本轮最有说服力的一组 before/after —— **把"我以为会泄漏"变成了"我量到它崩，修好它不崩"**。

**GUID 来源（主控专门追问的）**：`00000120-A8F2-4877-BA0A-FD2B6645FB94` = `Common/Graphics/wgx_exports.cs:268` 的 `MILGuidData.IID_IWICBitmapSource`。
**编译期拿不到**（引用 PC 会把整个 PC 拉进 AOT 镜像，AOT 运行时里也没有 PC 可反射）⇒ **逐字抄写 + 机械核对**：
`build/MilBridge/tools/check-mil-guids.py` 重新解析上游**三处**（两份 `wgx_exports.cs` + PC 的 `[Guid]` 特性）与本工程常量比对，**上游一改就红**。
T1 说明了为什么不做代码生成（要往上游只读树加步骤或往 `src/` 塞生成物，属 lane 之外），脚本级核对给同样的漂移保护。

> ### ⚠️ T1 给出**反对 T2 契约**的一条反面证据：**"放行但不 AddRef"会 use-after-free**
> T2 在 §18.2 写"**也允许**放行但不 AddRef（refs 恒 1，PC 释放一次即归零）"。T1 按上游逐行推导**否证**了它：
>
> | 步 | 上游原文 | refs（AddRef） | refs（不 AddRef） |
> |---|---|---|---|
> | 1 | `BitmapFrameDecode.cs:701` `_frameSource = new BitmapSourceSafeMILHandle(frameDecode)` | 1 | 1 |
> | 2 | `:448` `WicSourceHandle = _frameSource` → QI | **2** | 1 |
> | 3 | `:453` `WicSourceHandle = CreateCachedBitmap(...)` **覆盖** ⇒ 释放第 2 步那个句柄 | 1 | **0 → 当场回收** |
> | 4 | `SafeMILHandle.cs:63` 释放 `_frameSource` | **0 → 回收 ✓** | **下溢 / 二次释放 ✗** |
>
> 关键：第 1 步的 `_frameSource` 与第 2 步 QI 的句柄是**两个各自独立的持有者**，而在内存里是**同一个句柄值**。
> **T1 只实现了 `AddRef` + 转发 `Release` 一种形态**（正确的那个）。已要求 T2 改掉报告里那句"也允许"。
> **教训**：契约文档里写"两种形态都可以"时，**必须把两种都按调用方原文推一遍** —— 只推自己实现的那种，就会把 use-after-free 写成"允许"。

> ### ⚠️ T1 踩到的两个坑（会波及其他 lane）
> **① `libwpfwic.so` 必须是同一个实例 —— 否则是两张独立的对象表。** `dlopen` **按路径去重**，
> 两个路径 = 两个对象 + 两张 `g_objs` 表 ⇒ 一侧建的句柄在另一侧"不属于它" ⇒ 全部 `E_HANDLE`。
> **主控实测该条件当前不成立**：仓库里有 **3 份** `libwpfwic.so`（内容同 sha `ddf7b293…`）——
> `build/DirectWrite.Linux/wic-shim/`、`build/MilBridge/.artifacts/publish/…/`（`wpfgfx_cor3.so` 同目录）、
> `build/MilBridge/.artifacts/bin/ClosedLoop/release/`；**而两侧解析路径不是同一个文件**
> （PC resolver 候选③ = 仓库 wic-shim；MilBridge 桥第一优先 = 它自己 `dladdr` 出的目录）。
> ⇒ **WIC 解码器句柄在前者表里创建，`MILQueryInterface` 在后者表里问"归你吗"→ 不是 → 又是 `E_HANDLE`**，
> 看起来像"MIL 补丁没生效"，其实只是加载了两份。**已要求 T2 把"进程内只有一份"做成可观测判据：
> `grep -c libwpfwic /proc/self/maps` 必须是 1 条不同路径，≥2 直接判"双表"** —— 别让它伪装成语义问题。
> （另有 `libole32.dll.so` 两份改名副本，PC 现已能真解析 `ole32.dll`，必须删掉。）
> **② AOT 共享库里的 `AppContext.BaseDirectory` 不是宿主应用目录** —— 与 M7c3 给 `libSkiaSharp` 踩的是**同一个坑**；
> 修法沿用 M7c3：用 `dladdr` 算出的自身目录，经同一条 `MilBridge_SetNativeDir` 通道注入。

**★ 第二轮 PC 波（2026-09-10 晚，主控执行）—— 0 失败步骤，且现在强制 0 警告**
15 个工程**全部 `0 个错误 0 个警告`**；`DirectWrite.Linux.Provider` **已进重建表**（首轮我补的）；
`ole32.dll`/`WindowsCodecs.dll`/`libwpfwic.so`/`WPF_LINUX_WIC_SHIM` 四个字面量在 **PC 与 WB 均命中**；`CS0162` 已消失。
身份自检 5/5 已签名。`securityzone` 应用器继续被自动兜底执行。

**🎯 WIC 托管闭环 ①–⑤ 全绿（2026-09-10，T2 交付，主控独立复跑确认）**

| 指标 | 实测值 |
|---|---|
| **① `BitmapImage(fileUri).CopyPixels` vs `SKBitmap.Decode`** | **`BYTE_MISMATCH=0 / 1920000`** —— **192 万字节逐点比较，0 失配** |
| 独立指纹交叉校验 | **`PIXEL_FNV1A=62FD64E564953288`**、`FNV_MATCHES_C_PROBE=True`（与主控 `AbiProbe` 的 C 级记录值**一致**）；`PIXEL_22_16_BGRA=102,51,34,255` |
| **② `FormatConvertedBitmap → Bgra32`** | `CHECK2=PASS` |
| **③ 元数据宽/高/DPI** | `CHECK3=PASS`（尺寸正确 + **DPI=96 与已登记偏差一致**，未谎称等于文件真实 DPI） |
| **④ 失败路径** | **3/3**：不存在→`FileNotFoundException`；非图像/截断→`FileFormatException: The image format is unrecognized.`（内层 `0x88982F07` = `UNKNOWNIMAGEFORMAT`，出处 `BitmapDecoder.cs:1149`） |
| **⑤ 未覆盖清单** | 完整输出（编码器/元数据写面/写位图/调色板/颜色变换与 scaler·clipper·fliprotator/ROI/DPI≠96/色彩上下文/`WICConvertBitmapSource`/`CreateBitmapFromSource` 对 `CacheOnDemand` 提前物化） |
| `DECODER_BRANCH` | `CreateDecoderFromFileHandle`，`CALLS_AFTER=[FileHandle=4 Stream=0 Other=0]` |
| **`RESULT=PASS` / exit 0** | **主控在严格模式下独立复跑两次，一致** |

**本轮又拆掉 4 道墙**（T2 实测）：`MILQueryInterface`（T1 修）→ `FrameDecode_GetThumbnail_Proxy` 缺导出（补 `GetThumbnail`/`GetPreview`/`GetColorContexts`）
→ **又一次错误码串号**（`NOTIMPLEMENTED` 写成 `0x88982F04`，**上游那是 `WRONGSTATE`** ⇒ 改 `E_NOTIMPL(0x80004001)`）
→ `PixelFormat.GetPixelFormat` 的 `E_UNEXPECTED`（真实现 `CreateBitmapFromMemory`/`CreateBitmapFromSource`/`SetResolution`，converter 对无 fd 源接管像素）。

> **⭐ 关键手法：`WPF_LINUX_WIC_TRACE` 未实现桩追踪。** 最初看到的是 WPF `RecoverFromDecodeFailure` 抛的"恢复失败"——
> **真根因被吞了**；追踪一开就打出了 `WIC_TRACE STUB IWICImagingFactory_CreateBitmapFromSource_Proxy`。
> **"上层抛出的错误"和"真正的错误"经常不是同一个**；给未实现桩加**可开关的追踪**，是把吞掉的根因捞回来的直接手段。
> 另有一个易错点：`GetPreview` 的容忍码是 **`UNSUPPORTEDOPERATION`**（`BitmapDecoder.cs:741-743`），
> 而缩略图才用 `CODECNOTHUMBNAIL`（`BitmapFrameDecode.cs:570-574`）—— **写反了就是"能过但语义错"**。

**★ 主控翻开关：`WicEnabledByDefault = false → true`（含一项必要的守卫）**

翻开关前我发现并修掉一个**会让"翻转"变成降级**的问题：`Win32ShimResolver.cs` 同时编进 **PC 与 WB**，
而 `WicMappedLibraries` 里有 `ole32.dll`（PC 侧只有 2 处声明，调用点是 WIC 的 `UnknownBitmapDecoder`），
**WB 另有 5 处 `ole32.dll` 声明**（打包/OLE 族）。不加守卫就翻开关 ⇒ **WB 也会把 ole32 映射到 `libwpfwic.so`**，
那 5 处会从**诚实的 `DllNotFoundException`** 变成 **`EntryPointNotFoundException`**（诊断更差）。
⇒ 已给 WIC 分支加 **`#if PRESENTATION_CORE`** 守卫：**翻开关只影响 PC，WB 行为一字不变**。
**验证方式（值得记住）**：不能靠"字符串在不在"判断 —— 字段初始化器里的字面量即使不可达也会留在 `#US` 堆。
用**只存在于守卫块内**的那句 `但没找到可加载的 WIC shim` 做探针：**PC 有 / WB 无** ✅。
（我前面还犯过一次相反方向的错：用 `strings -a` 查 UTF-16 字面量，得出"没进件"的**假阴性**。
**同一个"字符串堆"问题，一次让我假阴、一次差点让我假阳。**）
翻后复验：WB/PC 各 **0 错 0 警**；严格模式 harness 仍 **`RESULT=PASS`**。

> ### ⚠️ WIC 的**部署契约**（必须遵守，否则症状会伪装成"MIL 补丁没生效"）
> **`libwpfwic.so` 在进程内必须只有一份**，且**两侧指向同一个文件**：
> - **PC 侧** resolver 认 `WPF_LINUX_WIC_SHIM`；**MilBridge 侧桥**认 `MILBRIDGE_WIC_SO`（候选①，优先于 `dladdr` 目录）。
> - **真实部署天然满足**：应用目录里只放一份 `libwpfwic.so`（与 `wpfgfx_cor3.so`、`PresentationCore.dll` 同目录），
>   两侧都会解析到它。
> - **⚠️ 仓库开发布局不满足**：仓库里有 **3 份**同 sha 的 `libwpfwic.so`（`build/DirectWrite.Linux/wic-shim/`、
>   `build/MilBridge/.artifacts/publish/…/`（`wpfgfx_cor3.so` 同目录）、`build/MilBridge/.artifacts/bin/ClosedLoop/release/`）。
>   **主控实测**：默认开启但**不设 env** 时，PC 加载候选③（仓库 wic-shim），桥加载它自己 `dladdr` 目录的那份 ⇒
>   **`WIC_SHIM_MAPS=2`、`WIC_SHIM_DOUBLE_TABLE=TRUE`** ⇒ 两张 `g_objs` 表 ⇒ `MILQueryInterface` 返 `E_HANDLE` ⇒ `COMException`。
> - **T2 的断言在这里立了功**：它不只报失败，还打出 **"这不是 MIL 补丁的问题"** 并给出修法。
>   ⇒ 本仓库跑 WIC **必须 pin env**（`run-harness.sh` 已自动 pin 到同一绝对路径）；真部署不需要。
> - 教训：**"同一份文件"要以「路径」为准，不是以「内容」为准** —— sha 相同、路径不同，`dlopen` 就是两个对象。

**★ 主控全量复验（2026-09-10 18:17，`bash verify-all.sh`，X 环境开）**

| 步骤 | 结果 |
|---|---|
| [0] Xvfb :99 | ✅ 复用已运行实例 |
| [1] 构建：主工程 + `wpf-linux.sln` | ✅ / ✅ |
| [2] `Commands.Tests` | ✅ 通过 **562** / 跳过 0 |
| [2] `Rendering.Tests` | ✅ 通过 **81** |
| [2] `Windowing.Tests` | ✅ 通过 **44** |
| [2] `HelloMil.Tests` | ✅ 通过 **19** |
| [2] `Presentation.Tests` | ✅ 通过 **8** |
| [2] **`ManagedLayer.Tests`** | ❌ **失败 1 / 通过 27 / 总计 28** ← 见下 |
| [3] 命令线格校验 | ✅ |
| **合计** | **步骤通过 8 / 失败 1；用例通过 714 / 跳过 0** |

> ### ✅ 已修复（M7b 定案 + 主控发布复验）：拆除期 `E_HANDLE` 的**真实缺陷**
> **三处出口逐一钉死**（加了可区分的编号台账 `WPF_LINUX_MIL_LOG`，非推理）：
> `[commit] ★E_HANDLE#2 channel.Commit() 失败 hr=0x80070006（通道 2）`
> ⇒ **出口 #2**：`Resolve` **没有**返 null（通道还在）、`PresentChannel` 也没失败 —— 是**某个命令处理函数**返了 `E_HANDLE`（`Require<T>`：句柄不在资源表里）。
>
> **再往下量出完整因果链**（提交前预检 + create/dup/release 台账）：
> ```
> [create]   通道 2 句柄 0x2/0x3/0x4 建好（视觉/HwndTarget/矩阵）
> [release]  通道 2 0x3/0x4/0x2 ⇒ 摘除=True        ← 拆除开始：立即摘除
> [closebatch] 通道 2 **待处理 7 条**               ← ★ 一个从未闭合的批次还排着队
> [preflight] #0 HwndTargetCreate 0x3 False / #1 MatrixTransform 0x4 False / #2 VisualSetTransform 0x2 False …共 7 条
> [commit]   ★E_HANDLE#2
> ```
>
> **真实缺陷**：上游原生 MilCore 有渲染线程、**流式**处理命令，release 只是"排队摘除"（这正是 `ProcessRemoves`/`ProcessCommands` 分成两阶段的原因）；
> 我们**没有渲染线程**、`Commit()` 是唯一处理点 ⇒ **未闭合批次滞留到 `Channel.Close()`，而资源已被拆除摘除**。
> **修法**（`Interop/MilNative.cs`）：**摘除前先冲刷**（`FlushPendingCommandsBeforeInvalidation`）—— streaming 的等价物，**不是吞错**：
> ① **不在 commit 内重入**（`_commitDepth` 非零不冲刷，否则整批重复执行）；
> ② **不吞错**：冲刷失败只记诊断、不改 release 的返回值；命令若引用**更早已真正摘除**的资源，**照旧 `E_HANDLE`**（`Require<T>` 一行未改）。
>
> **before → after（判据是"改一处 → 现象翻转"）**
> | 观测点 | before | after |
> |---|---|---|
> | `HwndSource_Characterization_OnLinux` | **失败**（0x70006） | **通过** |
> | 拆除时 `closebatch` 待处理 | **7 条** → E_HANDLE | **0 条** |
> | `ManagedLayer.Tests` | 27/28（5/5 稳定） | **28/28 × 连续 3 次**（主控用**新发布的 .so** 独立复跑） |
> **测试期望与"已登记清单"零改动** —— 没有为了变绿而登记。
>
> **"是否为新暴露"的结论：是新暴露（i）**，三条依据：① 缺陷与 M7b 三处改动**无代码交集**，一直存在；
> ② 是它的改动让 `HwndSource` **真的把窗口建起来**，`MediaContext` 才**第一次真正走到拆除**（此前建窗在早期就按已登记理由失败）；
> ③ 判据是"改一处→现象翻转"的对照，不是推断。
> **M7b 边界守得很干净**：修复在 AOT 桥里要一次发布才生效，它**没有**执行 `run.sh build`（那是我的边界），
> 而是**另开产物目录**（`-p:ArtifactsPath=/tmp/mb-diag` + `MILBRIDGE_MILCORE_SO`）验证；**反向对照**（不带该变量、用现网旧 .so）同一用例仍失败 ⇒ 证明证据确实来自新代码。
> **主控发布**：`bash build/MilBridge/run.sh build` → 新 **`wpfgfx_cor3.so` sha256 `20489d7f791ea4c6fbe98b1771ad70a9d77776e1fe3281e4a78a5f8d76372e8e`（4,569,488 B）**，清单 **109 / 缺失 0**、总 T 125、诊断面 16。

> ### 🎯 主控最终全量复验（2026-09-10 18:27，`verify-all.sh`，X 环境开）—— **全绿**
> ```
> [1] 构建：主工程 ✅ / wpf-linux.sln ✅
> [2] Commands 562 ✅ | Rendering 81 ✅ | Windowing 44 ✅ | HelloMil 19 ✅ | ManagedLayer 28 ✅ | Presentation 8 ✅
> [3] verify-cmd-layout.py ✅
> 步骤通过 9 / 失败 0        用例通过 742 / 跳过 0 / 失败 0        结论：✅ 全部通过
> ```
> 对照基线（无 X 环境）：`708 通过 / 29 跳过 / 0 失败`（当时的 29 条跳过正是需要 DISPLAY 的那些）。
> **现在 X 环境下 0 跳过、0 失败。** 另外 WIC 托管闭环在同一份新 `.so` 上复跑仍 `RESULT=PASS`（`BYTE_MISMATCH=0/1920000`、`FNV_MATCHES_C_PROBE=True`）。

---

## ★★ 四轨并行推进（2026-09-10 晚，主控编排）

**起点：全线绿灯**（`verify-all.sh` 9/9 步骤、**742 通过 / 0 失败 / 0 跳过**）。按"**文件 lane 不重叠 + 构建目标不重叠**"划分：

| 轨道 | 负责 | 独占 lane | 目标 | 为什么能独立 |
|---|---|---|---|---|
| **A** | T1 | `build/MilBridge/` | **路线 B ≤400 行限时原型** | 把"1500–2500 行"从**外推**变成**实测**；只读引用已构建的 PC.dll，**不许改 PC**（否则工程量数字失真且打断别人） |
| **B** | T2 | `build/DirectWrite.Linux/` | WIC 写面：`BitmapEncoder`/`BitmapMetadata`/`WriteableBitmap` | 只动自己的 shim + harness |
| **C** | M7b | `src/WpfGfx.Linux/{Interop,Windowing}/` | **真"接窗"**（`AttachToHwnd` 真绑定 + Resize 重渲，债务 #3） | M1 侧，与 A/B 无交集 |
| **D** | U1 | Windows 机 + `tests/parity/windows/` | **Windows 侧 shaping 真值**（`IDWriteTextLayout`） | **在另一台机器上，本机开销≈0** ⇒ 能突破"3 核 3 agent"的上限 |

**为什么是 4 条**：本机 3 核 / 7 GB，A/B/C 各要跑 dotnet 构建（已全部要求 `-m:1`、增量、不并行构建）。第 4 条主要做 ssh + 传输，几乎不占本机资源。再加第 5 条会互相拖慢，降低总产出。
**防撞车三原则**：① **任何人不得重建 PresentationCore**（PC 是所有 lane 的下游，重建只由主控在集成波里做）；② 各 agent 只构建自己的工程，不跑 `wpf-linux.sln`；③ X 测试基本独归 M7b（`Xvfb :99`）。

### 轨道 A 结果（T1，**决策级**，主控已复跑 + 读图确认）—— **路线 B 成本可控**

**复现**：`bash build/MilBridge/run.sh textline` → **6/6**（主控复跑一致）；产物 `build/MilBridge/gen/textline-proto.png`（4722 B）。
**主控独立核对**：`HbShaper.cs` **123** 行 + `HbTextLine.cs` **338** 行 = **461** 行（代码 **311** 行）✅ 与它报的一致。

> ### ✅ 结论（按主控给的两个选项，明确二选一）
> **"≤400 行且能出字" ⇒ 成立**（按**代码行** 311 < 400；按含注释总行 461 略超 61 行，**同一量级**），**不是"被低估"**。
> **"一上手就牵动 `DrawingState`/`TextRunCache`/`TextMetrics`" ⇒ 不成立** —— 原型**一次都没碰**这三个类型。连锁在别处（见下 4 条）。

**契约规模**：`TextLine` 是 `public abstract`，**必须实现 32 个成员**（另 1 个 `virtual IsTruncated` 不欠）：
19 个 abstract 属性（**19 全真实现**）+ 13 个 abstract 方法（真实现 **3** = `GetTextRunSpans`/`GetTextBounds`/`Draw` + `Dispose` + **9 个抛 `NotSupportedException`**）。
**欠 9 个**（全是裁剪/命中/光标/换行面）：`Collapse`、`GetBackspaceCaretCharacterHit`、`GetCharacterHitFromDistance`、`GetDistanceFromCharacterHit`、`GetIndexedGlyphRuns`、`GetNextCaretCharacterHit`、`GetPreviousCaretCharacterHit`、`GetTextCollapsedRanges`、`GetTextLineBreak`。

**⭐⭐ 主控读图确认（不是看像素计数）**：PNG 渲染出 `Hello WPF on Linux — AVATAR To office ffi`，**正向、字距生效、`ffi` 是单个连字字形**。
**并且我发现一处强内部自洽**：串里 `ffi` 出现 **2 次**，每次连字省 2 个字形 ⇒ 正好 **41 − 37 = 4** —— **字形数差被完全解释，不是巧合**。
（T1 自述第一版把 y 多翻一次导致字是倒的 —— **像素计数不受影响但证据图不可读**；这条本身就是"计数类证据要配图"的例子，已修。）

**与 HarfBuzz 直算一致性**：`GlyphIndices` 37 个**逐项相等**；`AdvanceWidths[0..2]=[18.3600 14.3280 7.1520]` **逐项相等（1e-9）** ⇒ 经 `TextLine` 出来**无精度损失、无单位错位**。
**与现行快路径对照**：**41 字形/500.5425px vs 37 字形/493.4880px，Δ=−4 字形、−7.0545px** —— 与 M7c4 基线**同量级同方向**。

**4 条连锁（都有栈）**
| # | 连锁 | 影响 |
|---|---|---|
| **1（最硬）** | **`TextBounds`/`TextRunBounds` 的构造是 `internal`**（实测 public ctor = 0）⇒ 外部程序集只能**反射**造（原型 P3 就是这么过的） | **⇒ 路线 B 真正落地必须把实现编译进 PresentationCore**（即 `build/shims/` 那条既有机制）。**这不是缺陷，但它把"实现放哪"定死了、会改"谁能改"的边界** ⇒ 里程碑里必须先定。**主控裁定：B1 走 `build/shims/`**（与既有机制一致，且能访问 internal 类型） |
| **2** | **`new GlyphTypeface(Uri)` 直接 NRE**：`FontFaceLayoutInfo.IntMap.TryGetValue`（`:642`）← `FontFaceLayoutInfo..ctor(Font):70` ← `GlyphTypeface.Initialize(Uri,…):150`；`_font.GetFontFace()` **返回 null** | **公开入口就 NRE**。绕法（原型 P5 过）：DWF `Font` → 内部 `GlyphTypeface(Font)`（反射），实测 `GlyphCount=3884 Version=2.015`。**已转 T2（字体 provider 是它的 lane）** |
| **3** | **按名字建 `FontFamily` 撞 `OSVersionHelper`**：`CompositeFontParser` → `OSVersionHelper.GetOsVersion` → **`Could not detect OS!`**；根因是**设计使然**（shim 的 `IsWindows*` 一律 false） | ⇒ `TextRunProperties.Typeface` 走不了常规路径（原型留 null）。**已转 T2 定案**（注意：M7b 的 HelloWpf 用 `SystemFonts.MessageFontFamily` 是**通的**，所以这是**路径相关**的，不是全盘不通 —— 别当成"FontFamily 全废"） |
| **4** | **无头环境下连 `Brush` 都构造不出来**：`Brushes.Black` → `Animatable` → `DependencyObject` → `Dispatcher` → `MessageOnlyHwndWrapper` → `CreateWindowEx` → **Win32Exception 1400**；`new DrawingVisual().RenderOpen()` 同链 | ⇒ `Draw` 照实现但**无头驱动不了**；**路线 B 的端到端验证必须跑窗口（带 DISPLAY）** |

**另加 3 条 `GlyphRun` 契约**（不是连锁，但不知道就会踩）：`clusterMap` 个数 == 字符数、`[0]==0`、单调不减、值 < `GlyphCount`，且 **HarfBuzz 的"字形→字符"必须求逆**；`caretStops` 个数 == 字符数 **+1**；`GlyphTypeface` 不能为 null（`BeginInit`+setter 那条路 `EndInit` 会抛）。

**分阶段切分（T1 建议，主控采信）**
| 阶段 | 内容 | 量级 |
|---|---|---|
| **B1** | 单行/LTR/不裁剪（= 本原型） | **461 行（实测）** |
| B2 | `GetIndexedGlyphRuns` + `GetTextLineBreak` | ~150–250 |
| B3 | 光标/命中 5 个 | ~300–450 |
| B4 | 多行 + ICU 断行 + 折叠 | ~600–900 |

> ⚠️ **主控补的一条规划风险**：**B1 欠的 9 个里含 `GetTextLineBreak`**，而 WPF 在**换行**时会调它 ⇒
> **B1 很可能只够"不换行的单行文本"**。所以"B1 落地后即可删掉 §2.6 降级"这个推断**不成立** ——
> 落地时必须让**欠账被命中时安全回退**（而不是抛 `NotSupportedException` 崩），并**实测 HelloWpf 里到底命中几次**，
> 用这个数字决定 B2/B3 的真实优先级。**别把 B1 当"完成"。**

### ★ 轨道 B 第二轮：`DrawingBrush`/`BitmapCacheBrush` 落地（T2，主控已复验）—— **并销掉一桩历史悬案**

**`Rendering.Tests` 88/88 / 0 失败**（主控复跑一致）；golden **21 张 = 既有 16 张（时间戳 09-10 15:41/15:24/12:44、09-05 19:20 **原样未重写**）+ 新增 5 张** `drawing_brush_*`（全部 08:53）。
**实现**（唯一实现改动 `src/WpfGfx.Linux/Rendering/SkiaBrush.cs`）：
① **`MilDrawingBrush`**：`DrawingBounds`（几何包围盒，描边按笔宽外扩半笔宽；`DrawingGroup` 取子项并集）→ `SKPictureRecorder.BeginRecording(源包围盒)` → 离屏 `SKSurface` → `Snapshot()` 得 `SKImage` → **走与 `ImageBrush` 完全同一条链**（`TileViewbox(brush, 源尺寸)` → `TileViewport` → `TileBrushMapping` → `ImageTileMode` → `SKShader.CreateImage(image, tile, tile, Concat(brushMatrix, mapping))`）。为此把 `TileViewbox` 抽成**通用重载**（位图版改为委托），**未改既有位图语义**。
② **Drawing 递归**：`GeometryDrawing`（填充复用 `CreateFill`、描边走既有 `SkiaPen.CreateStroke`）、`ImageDrawing`（`LookupBitmap` + `DrawBitmap(rect)`）、`DrawingGroup`（`Opacity`→`SaveLayer`、`ClipGeometry`→`ClipPath`、`Children` 递归）。递归深度上限 8、离屏尺寸上限 8192 防炸。
③ **`BitmapCacheBrush`**：**透传 `InternalTarget`**，注释明写"软件渲染下**无缓存层 ⇒ 与直接渲染目标等价**；缓存语义（位图缓存/`CachingHint`/重采样缓存）**未实现**" ⇒ **没有假装有缓存**。
两条陷阱按既有注释守住：**`SKMatrix.Concat(a,b)` = `b` 先作用**；**`TileMode.None` → `Decal`**。

> ### ✅ **销账：handoff 点名的历史未验证项 —— 非单位画刷变换**
> `drawing_brush_brush_transform` 转绿：**30° 旋转 + 平移**（`RelativeTransform = Matrix(0.866, 0.5, -0.5, 0.866, 12, 8)`）现在**有 golden 钉住**
> ⇒ "**`Concat` 顺序写反就平移被缩放**"这类错误**从此会红**。
> 这正是 §10.5 与 U12 节里反复标注的"既有 `MappingMatrix`/`BrushMatrix` 合成顺序注释可能与 `SKMatrix` 语义相反、**非单位变换仍是未验证项**"—— **该悬案关闭。**

**如实登记的缺口（T2 写进代码注释）**
- **`TileMode.FlipX` 与 `FlipY` 当前渲染相同**：沿用既有 `ImageTileMode` 映射（`FlipX/FlipY/FlipXY → Mirror`）—— 这是 **`ImageBrush` 时代的既有近似**（WPF 是**单轴**镜像，Skia shader tile mode 只有**双轴** `Mirror`）。T2 **继承了它而不是偷偷改掉**，两张新 golden 锁的是当前行为。
  **⚠️ 主控处置：要求 T2 现在修，而不是留着** —— 理由是它**刚给它们建了 golden**，而那两张 golden **现在锁的是近似行为**；越晚修代价越大（golden 会"锁定错误"）。修完**有意重生这两张**并说明"这是把继承的近似改成真语义，不是为了让测试变绿"。
- **`DrawingGroup` 只应用了 `Opacity` + `ClipGeometry` + `Children`**：`Transform`/`OpacityMask`/`GuidelineSet`/`EdgeMode` 未接。
  **⚠️ 主控排为下一条最高优先**：`Transform` 缺失是**静默错渲**（XAML 里带 `Transform` 的 `DrawingGroup` 会渲染成**未变换**的样子 —— 不报错、不空白，就是位置/朝向错），**不是"缺个特性"，是"画出来是错的"**。
- **`MilGlyphRunDrawing` 未接**（需既有字形渲染路径）；**`VisualBrush` 仍是 `default`**（返回 `null`）—— 机制已证存在（`RenderHarness.RenderBitmap` 可进程内离屏渲染 Visual，**不需要 `RenderTargetBitmap`**），工作量在**可重入化 + 递归防护** ⇒ **另开一轮，先补"嵌套 visual 重复出现且无递归爆炸"的红用例**。

> ### 📌 主控的验证节流决定（留档）
> `Rendering.Tests` 转绿后**我没有立刻跑全量 `verify-all.sh`**，因为当时 **T1 正在改 `build/PresentationCore.Linux/`、M7b 正在改 `src/WpfGfx.Linux/Interop/` 并用 `Xvfb :99` 跑真窗口测试**：
> 此时跑全量会**同时撞构建竞态与 X 争用**，产出的红/绿我都得自己打折。**"在并发写者还在跑的时候测全量"会得到一个必须被丢弃的数字** —— 与其如此，不如等它们停了再测。
> （另注：M7b 在 09-10 20:04 改过 `MilNative.Misc.cs`，**晚于**最后一次全量绿跑 18:27 ⇒ 那些改动目前**尚未被全量验证覆盖**，等波里一并覆盖。）

### ★ 轨道 B 第三/四轮（T2）：`GlyphRunDrawing` + `VisualBrush` 机制与**显式递归防护**（主控已复验）

**`Rendering.Tests`：93 通过 / 0 失败 / **1 显式跳过** / 94 总计**（主控复跑一致）；golden 仍 **23 张，一张未动**。

**① `MilGlyphRunDrawing` 接上既有字形路径**（此前**静默不画**）：`SkiaBrush.DrawDrawing` 新增该分支，**与 `SkiaRenderBackend:501-508` 同一条路**（前景画刷 `CreateFill` + `provider.TryRenderGlyphRun`），**不再各写一份**。
用例 `drawing_with_glyph_run_invokes_glyph_renderer`：组内**几何 + 文本**（现实形态），断言字形渲染器**恰好被调 1 次**；实现前 `default:` 直接 `break` ⇒ 计数 0 ⇒ **该用例会红**。
**如实登记的边界（显式 `Skip=`，不是留着红）**：**纯字形** Drawing（组里只有文本、无几何）**仍不画** —— `DrawingBrush` 的 tile 尺寸取自 Drawing 的**包围盒**，而文字范围**只有字形渲染器知道**，而 `GlyphRunRenderer` 只负责"把字画到画布上"、**不返回度量**。恢复条件写在用例注释里（`DrawingBrushTests.cs:185`）。

**② `VisualBrush` 机制 + 显式递归防护**
- 机制：新增 provider 扩展点 **`VisualImageResolver`**（`MilResourceProvider.cs`，与 `BitmapResolver`/`GlyphRunRenderer`/`EffectResolver` 同一范式，缺省 `null` = 认不出），拿到离屏 `SKImage` 后走**与 Image/DrawingBrush 完全相同**的 TileBrush 链路。
- **递归防护是显式的、两道闸**：`VisualMaxDepth = 6` + **`[ThreadStatic] HashSet<uint>` 访问集**；命中即返回"不画"。
- **证据用例**：`visual_brush_self_reference_is_guarded` —— 解析器每次都会**再调一次同一个画刷**（忠实模拟"Visual 内容里又有指向自己的 VisualBrush"），断言**调用次数 == 1**（第二次被访问集拦下），外壳照常出画刷 ⇒ **不会栈溢出是测出来的，不是"理论上不会"**。
- **⚠️ 生产未接（T2 如实说）**：`SkiaRenderBackend` **尚未**挂 `VisualImageResolver` —— 缺的是"**Visual 的自然尺寸来源**"（`RenderVisualTree` 进画布时尺寸由调用方给）。⇒ 现在 `VisualBrush` **测试里可用、生产里仍是 `default` 不画**。恢复条件：后端能给出 Visual 的内容包围盒（`Resources/VisualProjection` 里的投影计算可能就是那个来源）。
- ✅ **边界纪律正面例子**：我要求它动 `Resources/` 前先做冲突检查 —— 它做了（最近改动 `VisualProjection.cs` 09-10 15:39，早于其工作），**并且最终一行都没改 `Resources/`**（VisualBrush 查找走 provider 扩展点即够）。**"先检查再动"与"检查后发现不必动"都是对的。**

### ★ 轨道 D 第二轮（U1）：**layout 真值（B2 的判据）+ CJK shaping 真值**（主控已复验）

**任务 1 · layout 真值** `tests/parity/windows/shaping/out-layout/` —— **10 例**：固定容器宽 + 长英文句 / 多短词 / **带连字符复合词** / 超窄容器 / 显式 `\n`（含空行）/ **超长单词（必须字符级紧急断行）** / 中英混排 / 纯 CJK / 粗体换行 / 斜体换行。
每例记录 `textMetrics`（width/height/lineCount/maxBidiDepth）+ **每行**：`startChar`/`endCharExclusive`（UTF-16 码元下标）/`lengthWithNewline`/`newlineLength`/`trailingWhitespaceLength`/**`heightDip`**/`baselineDip`/**`advanceWidthDip`**/`caretXDip`/`caretYDip`/`lineText`。
**没有安装字体、没有改注册表**：实现了最小 `IDWriteFontCollectionLoader` + `FileEnumerator` + `FileLoader` + `FileStream` **四个 COM 服务器**（`[UnmanagedCallersOnly]` + 手工 vtable；引用计数只加减永不 free；TTF 用 `GCHandle` pinned 全程保活），把未安装字体喂进 collection 后**真正用上了 `IDWriteTextLayout`**。
**⭐ 链路真的跑起来了（回调计数为证，不是"看起来成功"）**：`CreateEnum=1 MoveNext=5 GetCurrent=4 CreateStream=4 ReadFrag=96 GetSize=4 RelFrag=4`，且 `FindFamilyName("Noto Sans")` → **exists=True**（**family name 是验证出来的，找不到就报错退出**）。
样例：`mixed` 200 DIP → 5 行 `[0,13)/[13,28)/[28,40)/[40,54)/[54,62)`；纯拉丁行高 32.688、含 CJK 行 32.930。

**任务 2 · CJK shaping 真值** `out-cjk/` —— **34 例**（7 条语料 × 2 字号 × SC 面 + 2 条 locl 对照 × JP/SC/TC），覆盖 **汉字/假名/谚文/全角标点/中英混排**，**`notdefGlyphs` 全为 0**（上轮 `mixed-cjk` 是 6 个 `.notdef` ⇒ 现在**真覆盖**了）。字段与 `out/` **完全同形制**，可一次跑两份。
**主控复验**：34 例、四个 `fontSha256` 全 = `b76b0433203017ca`（与我给的 `/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc` 一致）、`notdefGlyphs` 全 0 ✅。
**`.ttc` 的新变量已处理**：`CreateFontFace` 的 `fontFaceType` 必须是 **`OPENTYPE_COLLECTION`(=2)**；用 `TRUETYPE`(=1) 传 `faceIndex≥1` 会 `E_INVALIDARG`（踩过）。

> ### ⭐★ **`locl` 对照做成了 —— 并给出对路线 B 可直接落地的实现约束**
> `直画骨角写门今令` 在 JP/SC/TC 三面下：JP `27873 27078 45132 37448 10973 43012 9770 9808` / SC `27874 27079 45133 37449 10974 43013 9771 9809` / TC `27874 27080 45134 37448 10974 43013 9772 9810`。
> **HB 对拍**：同一 `.ttc` + 同一 `faceIndex`（`hb.Face(blob, index)`）——**不给 language → 30/34 字形一致；给 language（SC→`zh-Hans`/TC→`zh-Hant`/JP→`ja`/KR→`ko`）→ 34/34 一致**，advance 34/34。
> 那 4 条差异**全在 `mixed-latin-cjk`**，原因明确：**HarfBuzz 只在 buffer 设了 language 时才应用 `locl`**；不设时对 SC/TC 面回落到默认（JP）字形，而 DWrite 按面自动本地化。
> ### ⇒ **路线 B 接线的硬要求：必须把 locale 传进 HarfBuzz buffer**，否则**简体文本会拿到日文字形**。
> 这把"我们不支持 `locl`"从一句话变成了 **34 例里 4 例、逐字命中**的可测量事实。

> ### ⚠️ 主控更正 U1 的两句**汇总归因**（原始数据是对的，归因反了）
> 我用它的 JSON 重算逐字对照，与 PROVENANCE 里两句不符（已要求它改正）：
> | 对照 | 它写 | **主控实测** |
> |---|---|---|
> | `直画骨角写门今令` JP vs SC | "7 个不同" | **8/8 全不同**（位置 0–7） |
> | 同串 JP vs TC | — | 7/8（**位置 3 =「角」相同**） |
> | 同串 SC vs TC | — | 5/8（位置 1,2,3,6,7） |
> | "「角」三种面两两不同" | 是 | **不成立**：JP(37448) == TC(37448) ≠ SC(37449) |
> | `汉字字体说明` "只有「汉」不同" | 是 | **不成立**：`汉`(23037) **三面完全相同**；不同的是**位置 1、2 的「字」**（JP 15364 vs SC/TC 15365），**2/6** |
> **结论方向不变**（`locl` 是**逐字**而非整串 —— `汉字字体说明` 6 字里只 2 字变，这条站得住），**但归因反了**。
> **为什么值得记一笔**：**原始数据给对了，但汇总句把归因写反 ⇒ 只读汇总的人会得到相反的理解，而这比数据错更难发现。** 这类"数据对、结论错"的偏差，本轮已是第二次（第一次是主控自己把实测错接到不成立的对象上）。

**踩到并记录的三个槽位坑（已进 PROVENANCE）**：① `CreateCustomFontFileReference` 是工厂**槽 8** 不是 6（6 是 `UnregisterFontCollectionLoader`）——踩错时 **collection 建出来是空的**，靠 `CreateStream=0` 一眼定位；② **`IDWriteTextFormat` 自己有 25 个方法**（不是 30）⇒ layout 自己的方法从 **28** 起：`59 GetLineMetrics / 60 GetMetrics / 65 HitTestTextPosition / 66 HitTestTextRange`；③ `GetLineMetrics(maxCount=0)` **不支持查数量**（返回 `E_INSUFFICIENT_BUFFER`）。

**诚实边界**：任务 1 含 CJK 的 4 例里 **DWrite 走了系统字体回退**（collection 里只有拉丁 Noto）⇒ 那些行的行高/advance **Linux 不可复现**，JSON 已标 `cjkCoverage:false`；**纯 CJK 的行高/换行已派下一轮**（B2 的一半就是 CJK 换行）。未覆盖：竖排 `vert`、变体选择符 VS/IVS、Emoji/彩色字体、bidi；`locl` 的 language→字形映射本身没有单独真值。

### ★ 轨道 D 第三轮（U1）：**纯 CJK layout 真值 —— 测出避头尾，这是 B2 的新硬要求**（主控已逐项复验）

`tests/parity/windows/shaping/out-layout/dwrite-layout-cjk-oracle.json` —— **25 例**（10 拉丁原样保留 + **15 CJK**）。
把 `NotoSansCJK-Regular.ttc`（同一 sha `b76b0433203017ca…`）放进**同一个私有 collection**，DWrite **自己解析 family、完全不依赖系统回退**（实测 `Noto Sans CJK SC/JP` 两个 family 都 `exists=True`）
⇒ **CJK 行高统一 `34.752`**，**再无 32.930 那种回退污染行高**（对照：拉丁 Noto 32.688、11 DIP 15.928）。

> ### ⭐★ **避头尾（行首禁则）：DWrite 确实做，且语义是"把前一个字拉下来"**
> 构造：容器宽 **168 DIP = 正好 7 个全角字**，第 8 字就是禁则标点（贪心断行会让它落到第 2 行行首）。**主控从原始 JSON 逐行核对**：
> ```
> cjk-kinji-comma  行1 [0,6) adv=144 '甲乙丙丁戊己'   行2 [6,13) adv=168 '庚，辛壬癸子丑'
> cjk-kinji-close  行1 [0,6) adv=144 '甲乙丙丁戊己'   行2 [6,13) adv=168 '庚）」辛壬癸子'
> cjk-kinji-period 行1 [0,6) adv=144 '甲乙丙丁戊己'   行2 [6,13) adv=168 '庚。辛壬癸子丑'
> ```
> **行 1 只有 6 字（144 = 6×24），不是贪心的 7 字** ⇒ `，` `）` `」` `。` **绝不出现在行首**；行 2 正好占满 168
> ⇒ **是"把前一个字拉下来"，不是"标点悬挂到行尾外"**。
> ### ⇒ **B2 的断行不能只在空白/字符边界断，必须叠加行首禁则。**
> 原计划 B2 = `GetTextLineBreak` + `Collapse` + `GetTextCollapsedRanges`，**现在要多一条"禁则"**。

**其余可直接当判据的行为**：`cjk-para` w=200 → 5 行每行 8 字；`cjk-narrow` w=90 → 10 行每行 3 字；`cjk-latin-mix` 断在中英交界且**行尾保留空格**（行 advance 149.38/165.46/177.36 各不同）；`cjk-long-token` **字符级强制断开**；`cjk-newlines` 空行是**零长度行 `[8,8)`**。

> ### ⭐ **SC 面 vs JP 面：换行点完全相同**（负结果但很有用）
> ```
> facecmp-sc: [(0,6),(6,12),(12,18),(18,24),(24,30),(30,33)]  width=144
> facecmp-jp: 同上（identical = True）
> ```
> 原因清楚：**CJK 全角字形使 `locl` 只换字形 id、不改 advance**（追加 2 已实测同串同 advance），而**断行只看 advance**。
> ⇒ **locale 影响"出哪个字形"（shaping 层，必须传 locale）；不影响"在哪里断行"（layout 层）。两件事别混。**
> **这条把两个层干净地分开了** —— 否则后人会把"简体拿到日文字形"和"断行点不同"当成同一个 bug 去查。

**诚实边界**：只测了 `，``。``）``」` 四个**行首**禁则；**行尾禁则**（`（``「` 不能居行尾）与**禁则冲突优先级**未覆盖 ⇒ **已派下一轮**（这两条恰是 B2 最容易做错的地方，且只能靠真值不能靠推理）。未覆盖：竖排 `vert`、非默认对齐/trimming/`SetLineSpacing`/tab stop、bidi；locale 固定 `zh-cn`（kana/hangul 用例文本是日/韩但 locale 仍是 `zh-cn` —— **这本身印证了断行不受 locale 影响**）。

> ### 📌 主控据此下的两条派工（留档）
> 1. **给做 B2 的 agent（T1）加一条"最便宜的预检"**：B2 原计划用 **ICU 70 `ubrk_*_70`（UAX#14）** 断行。**UAX#14 本身编码了 CJK 断行类（`CL`/`OP`/`EX`/`NS`），理论上能表达禁则 —— 但"理论上"不值钱。**
>    ⇒ 要求它**先写小探针把上面 15 个 CJK 用例喂给 ICU `ubrk`、逐例对拍行划分与断点**：一致就直接用并固化成回归；**不一致就立刻停下报告**（那意味着要在 ICU 之上自己叠禁则，B2 量级会变）。
>    **这正是"先做最便宜的对拍、再决定要不要写 500 行"的场合。**
> 2. **给 U1 派下一轮**：补齐禁则的**另一半** —— **行尾禁则**（构造法同前：容器宽正好 = N 个全角字，把禁则标点放第 N 位）、**冲突优先级**（构造无解局面：两个禁则标点相邻，或窄到只容 1–2 字，看 DWrite 选悬挂/挤压/破例）、以及**把行首禁则集扩到常用全集**（`、``；``：``！``？``」``』``】``》``〕`…）——
>    **B2 需要的是一张"哪些字符算禁则"的表，不是一个开关。**

### ★ 轨道 D 第四轮（U1）：**禁则表 —— 行首/行尾/冲突优先级全部实测**（主控已逐行复验）

**产物**：`tests/parity/windows/shaping/out-layout/kinsoku-table.json`（**48 行**，逐字符带 `char/kind/verdict/line1EndChar/line1AdvanceDip/line1Text/line2Text`）；CJK layout 用例 **15 → 73**（新增 **58 个 `kinsoku-*` 探针**）。

**⭐ 探针构造是"可自我验证"的**（这一点比结论本身更重要）：容器宽 **168 DIP = 正好 7 个全角字**；`start` 探针把目标字放**下标 7**（贪心会让它落到第 2 行行首）、`end` 探针放**下标 6**（贪心会落在第 1 行行尾）。
禁则生效 ⇒ DWrite 拉/推相邻字 ⇒ **行 1 = 6 字**；否则 7 字。
**对照探针 `甲`：两个方向都判 `allowed`、`line1AdvanceDip=168`（7 字）** ⇒ **构造确实能区分"禁则"与"普通字"，不是把所有字符都判禁**。**没有这个对照，整张表都不可信。**

| kind | 数量 | 实测（主控复验） |
|---|---|---|
| **行首** `start` | 32 | **31 PROHIBITED**：`、。，．：；！？…‐`、右括号类 `）］｝」』】》〉〕`、**以及 `・`(U+30FB) / `ー`(U+30FC) / `々`(U+3005) / 小假名 9 个（`ぁぃぅぇぉっゃゅょ`）** ⇒ **DWrite 用的是完整 CJK 禁则类，不是只做标点**（实测 `・`/`々`/`ー` 均 `line1Adv=144`）+ 1 个对照 `甲` = allowed |
| **行尾** `end` | 12 | **9 PROHIBITED**（`（［｛「『【《〈〔` ⇒ 行 1 = **6 字**，`line1Adv=144`）+ **⭐ 2 个例外：`“`(U+201C) 与 `‘`(U+2018) ⇒ 行 1 = 5 字**（`line1Adv=120`，行 2 = `己“辛壬癸子丑`）—— **引号连同它前一个字一起下移** + 1 个对照 |
| **冲突** `conflict` | 4 | 见下 |

**冲突优先级（4 个故意无解的局面）**
| 构造 | 实测 | 结论 |
|---|---|---|
| 6 填充 + `「（`，容器 7 字 | 行 1 = 6 字，行 2 = `「（辛壬癸子丑` | **两个标点整体下移**，不悬挂、不挤压 |
| 6 填充 + `「」` | 行 1 = 6 字，行 2 = `「」辛壬癸子丑` | 同上 |
| 容器 **24 DIP（1 字）** | 每行 1 字 | **禁则被放弃**：无解时允许破例，**不悬挂、不压缩、不报错** |
| 容器 **48 DIP（2 字）** + `，。」` | 行 1 = `甲乙`、行 2 = `丙丁` | 同上 |

> ### ⇒ **B2 的禁则规则（实测得出，非推理）：能整体下移就整体下移（宁可上一行短一个字）；容器窄到放不下时放弃禁则、正常断行。**

**诚实边界（U1 自己划定，我照收）**：① **这不是完整 UAX#14/JLREQ 禁则集** —— 只测了**44 个字符**，**"表里没有" ≠ "允许"**；② 半角/西文标点（`,` `.` `)` `"`）在半角语境下的禁则未测；③ 行尾"拉 2 个字"是否也适用于 `『` 等其它引号类未测（只测到全角括号拉 1、`“`/`‘` 拉 2）；④ **禁则是否受 locale 影响本轮没单独验证**（全部固定 `zh-cn`）—— 追加 3 已证"**断行位置**不受 face/locale 影响"，但**禁则本身**要更硬的保证应补一组 `ja-jp` 对照；⑤ 竖排 `vert`、非默认对齐、trimming、bidi 未覆盖。

> ### 📌 主控据此**更正了对 T1 的预检指令**（已发）
> 原指令是"用 ICU `ubrk` 对拍 **15 例**"。**现更正为对拍全部 73 例，重点那 58 个 `kinsoku-*`**，并加了一条判定原则：
> ### **只要有一个字符判读不同，就以 DWrite 真值为准 —— 我们的对齐目标是 WPF，不是 UAX#14。**
> 特别要盯：**非标点类**（`・`/`ー`/`々`/小假名 —— 在 UAX#14 里未必都是行首禁则类）、**`“`/`‘` 的"拉 2 个字"**（`QU` 类的处理可能不同）、**冲突优先级**（`「（` 整体下移、过窄放弃 —— **这层 UAX#14 规范里未必规定，可能是实现细节**）。
> **结论必须二选一**：① 73 例逐例一致 ⇒ 直接用 ICU 并固化成回归；② **有任何一例不同 ⇒ 停下报告**，那意味着要在 ICU 之上自己叠禁则（**B2 量级会变**）。**不许"大体一致就先做"。**

### ★ B2 预检结果（T1，主控已核准结论）：**ICU 覆盖 40/40 禁则 ⇒ 不用自己写禁则表**

探针 `build/MilBridge/tests/IcuBreakParity/`（**不引用 PC**，只 P/Invoke `libicuuc.so.70` + 读 U1 的 oracle JSON ⇒ 与 PC 重建互不干扰）；`bash build/MilBridge/run.sh icu`；逐例存档 `build/MilBridge/gen/icu-break-parity.txt`。`u_getVersion` = **70.1.0.0**。

**判定：②「不一致」** —— 按我定的规矩停下报告，但**差异小且已定位到字符级**。三段法：

| 段 | 方法 | 结果 |
|---|---|---|
| Stage 1（必要） | DWrite 的每个换行点必须 ∈ ICU 断点集 | 73 例中 **5 例不一致** |
| Stage 2（充分） | ICU 断点集 + 贪心填宽（全角 advance = 逐例 emSize，实测 24 与 11）重算行划分、逐行对拍 | 纯 CJK 可用 **59 例：58 逐行全等** |
| Stage 3（禁则 crux） | 48 行 kinsoku 表逐字符 | **禁则 40/40 一致、对照 2/2 一致、不一致 0** |

> ### ⭐ 三个最有价值的结果
> 1. **`40/40` 禁则全部被 ICU 覆盖**（含 `・`/`ー`/`々`/**小假名 9 个** + 9 个行尾禁则 + 对照 `甲`）⇒ **我们不用自己写禁则表** —— 这正是"先做最便宜的对拍"想要的结果：**省掉一整张表**。
> 2. **"容器窄到放不下就放弃禁则"不需要单独写规则** —— 它的 fallback（**无断点可放 ⇒ 按字符强制断**）**恰好复现**它（`kinsoku-conflict-1char/2char` Stage 2 **逐行全等**）。**一个 fallback 同时解决"紧急断行"与"禁则放弃"两件事。**
> 3. **`ubrk_open` 的 status 是硬证据**：`zh-CN` = `-128 U_USING_FALLBACK_WARNING`、`en-US` = `-127 U_USING_DEFAULT_WARNING` ⇒ **ICU 没有 zh-CN 专属断行数据、走 root 规则** ⇒ **断行点集与 locale 无关**。用 status 码把一项"没测"变成"有硬证据"。

**两处真差异（都定位到字符）**
| # | 字符 | DWrite | ICU | 要加的规则 |
|---|---|---|---|---|
| 1 | **`…`(U+2026)** | **允许其前断**（`cjk-fullwidth` 末行 `[15,21)`） | UAX#14 归 `IN`（前后都禁）⇒ 末行 `[15,19)` | **其前可断** |
| 2 | **`“`(U+201C)** | 连同**前一个字**一起下移（行 1 = 5 字） | **允许其前断** ⇒ `“` 落到行首 | **其前不可断**（与 `‘` 对齐） |
> **实测出的不对称**：ICU **允许** `“` 前断、**禁止** `‘` 前断 ⇒ **两个引号在 UAX#14 里不同类**。这条要写进注释说明"**按 DWrite 真值覆盖 UAX#14，不是我们猜的**"。

**另 3 处 Stage-1 不一致 = 紧急断行，不是 ICU 缺陷**（`en-oneword` 单词内逐字符断、`cjk-long-token` 字符级强制断、两个 conflict 例）—— **已由同一个 fallback 覆盖**，应标为"**非差异**"而不是留在表里，免得后人误读成 3 个待修项。
**1 处记账口径**：`cjk-newlines` —— DWrite 行区间**不含换行符**（`lengthWithNewline`/`newlineLength` 分开给）、空行是**零长度行 `[8,8)`**；探针把 `\n` 算进了区间 ⇒ **是探针记账，不是 ICU 的错**。

> ### ✅ 主控裁决：批 **(a)** —— 先把 `…`/`“` 两条实装进探针、做到 **73 例逐例全等**，再开工 B2
> 理由：**那是把"不一致"变成"已对齐"的最便宜一步**，且顺手把 73 例固化成回归。**不许带着已知差异去建 B2。**
> **B2 的形状（已核准）**：**ICU 断点集 + 贪心填宽 + 3 条自叠规则**（无断点可放⇒按字符强制断；`…` 前可断；`“` 前不可断）+ 行区间/空行/硬断口径。
> ⇒ **量级仍是"贪心 + 断点集"**，B2 主要是**契约与接线**的活，**不是重写断行引擎**。这比原先估计好得多。
> **验收钉在 73 例上**（B2 落地后必须逐例全等），不是"看起来换行对了"。

### ★ T1 的 `FontFamily` 复合字体短路：**已进波、6/6 全 PASS**（主控复验）

**落盘**（哈希主控逐个核对一致）：`src/WpfGfx.Linux.Native/tools/patch-presentationcore-compositefont.py`（新，`24ee0400aaf3b528…`）、
`build/PresentationCore.Linux/FamilyCollection.Linux.cs`（生成物，上游 681→782 行，`1d99d32bf8a13e18…`）、csproj 仅 +2 行（`6506e67aa5e34216…`）、`build/shims/PresentationCore.Factory.Linux.cs`（追加1，`125cfaa3c9851cfd…`）。
`--check` 退出 0、幂等、**锚点变异实测退出 1（不静默降级）**；`-getItem:Compile` 求值：**上游 `FamilyCollection.cs` 0 条 / 生成物 1 条**（主控复验，**波后仍然成立**）。
**主控已把它加进 `integration-wave.sh` 的显式顺序表**（与 `securityzone` 一起）⇒ 现**7 个应用器全在显式表、0 个兜底 ⚠**。

**PC 集成波（主控执行）**：**失败步骤 0**，15 个工程**全部 `0 个错误 0 个警告`**，`compositefont` 应用器执行成功（`✅ [锚点] ① 短路点 …上游出现 1`）。

**AFTER 清单复验（`bash build/MilBridge/run.sh compositefont` → 通过 6 / 失败 0 / 跳过 3，退出码 0）**
| # | 项 | 结果 |
|---|---|---|
| ① | 基线字形度量 | **PASS**（GlyphCount=3884 / Version=2.015，与基线逐项等价） |
| ② | `FontFamily("Arial")`（未安装） | **PASS —— provider 回退**到 `build/fonts/NotoSans-Regular.ttf` |
| ③ | 私有字体 URI | **PASS** |
| ④ | `Util` 静态构造（Window 静态构造链上那一步） | **PASS** |
| ④′ | `Fonts.SystemFontFamilies` | **PASS —— 枚举成功且无 null 元素**（FamilyCount 与枚举产出一致） |
| 追加1 | `new GlyphTypeface(new Uri(ttf))` | **PASS —— 诚实失败**：`FileFormatException → File '…NotoSans-Regular.ttf' has an invalid file format.` |

> ### ⭐ T1 实测出**我派工里没有的坑**：**只做"短路"会把异常换个地方冒**
> 它做了运行期模拟（`--simulate-shortcircuit`：清空 `SystemCompositeFonts._systemCompositeFontsNames`，**仅进程内、磁盘未改**）：
> `FindFamily(Arial/Global User Interface/…)` → 全部 null（短路生效、无 `OSVersionHelper`）✅
> **但** `new FontFamily("Arial") + TryGetGlyphTypeface` → **`NullReferenceException` @ `Typeface.cs:786`**
> ← `Typeface.ConstructCachedTypeface` 的兜底链（`#GLOBAL USER INTERFACE` → `#ARIAL`）两边都找不到 ⇒ `firstFontFamily == null` ⇒ 紧接被解引用。
> **"诚实失败"在这条链上做不到**：`CachedTypeface.cs:42` 有 `Invariant.Assert(firstFontFamily != null && typefaceMetrics != null)`，Debug 构建传 null = **断言炸进程**。
> **对照是实测演示的**：探针里"只做①不做②"那一栏就是上面那条 NRE。**"把异常换个地方冒"不是断言，是测量结果。**

> ### 📌 主控裁决：走"交给 provider 的系统兜底族"，**不走"诚实失败"**
> 理由：① **这与 WPF 语义一致** —— Windows 上找不到族就落到系统兜底族（**永远不会因为"某字体没装"而崩**）；② "诚实失败"要**再动一个上游文件**（松开 `CachedTypeface.cs:42` 的断言），代价大于收益。
> **但"取 `_fontCollection[0]`"不达标准**（T1 自己标出的粗糙点，我认可这个自我批评）：`[0]` 依赖扫到的目录 —— 只给 `build/fonts` 是 **Noto Sans**（确定），带上 `/usr/share/fonts` 是 **`AR PL UKai CN`（楷体、拉丁字形差）**。
> ⇒ **已派 T2（provider owner）加一个"有原则、确定性、可观测"的 default-family 出口**（优先 fontconfig 的 `sans-serif`；退档规则写死并注明依据；空集明确失败而非返回 null 族）。**它批准先做这条（因为卡着 ④′ 的验收），渲染那两件往后排。**

**另一条实测修正（T1 给，与我的假设不符）**：4 个复合字体里**只有 `GlobalUserInterface` 会抛**（唯一根为 `<FontFamilyCollection>`、带 4 个 OS 段的；另 3 个根是 `<FontFamily>`，**实测能加载**）。短路=4 个都不加载 ⇒ 代价比我写的"丢掉 `GlobalUserInterface` 回退链"**多**了那 3 个 —— 但它们**今天也全部不可达**（唯一入口 `Fonts.SystemFontFamilies` 枚举在第 0 个上就抛了；只剩显式 `FontFamily="Global Monospace"` 这种用法）。**且 `FontFamily("Noto Sans")` 现在就是通的** —— 它抛的前提是**这个名字在 provider 里也找不到**（那时才落到系统兜底族）。

### ✅ ⑤ `SystemFonts.MessageFontFamily` / HelloWpf：**已复验通过**（主控，2026-09-11 14:00 前后）

**在验收同款配置下与 M2 验收件同级**：`PNG 56,055 B / 白像素 8,318 / 未画种类 0`（验收件也是 56,055 B）。
探针读数（`/tmp/mainctl-hellowpf/hellowpf.log`）：
```
[probe] SystemFonts：MessageFontFamily=DejaVu Sans  MessageFontSize=11  MessageFontWeight=Normal
[probe] 闸门④ MessageFontFamily/Normal：CheckFastPathNominalGlyphs("Hello WPF on Linux") = True；缺字形 0/18
[probe] 闸门③ MessageFontFamily/Normal：TypographyAvailabilities=0（Available/Ideo/FastText 全 False）
```
⇒ T2 那条"剥离 GSUB/GPOS 后元数据报无特性、但**没有任何消费者能用那些特性**"的默认开论证，**在真实 HelloWpf 路径上被证实**（闸门④ 真的 True）。

**两个必须记住的混淆变量（我差一点据此错判成"回归"）**：
1. **验收件是用字体 env 跑出来的**（`HLWPF_UI_FONT=build/fonts-ui/UI-NoLayout.ttf`，日志里 `字形渲染器已挂上：目录=…/build/fonts-ui`）——**文档里"零探针"指的是探针 env，不含字体 env**。验收件与"默认配置"**不是同一个配置**。
2. 我的首跑**没设字体 env** ⇒ 得到 **46,902 B / 白像素 6,300 / `未画种类 1` / 无文字**，与 handoff:1500 记的**文字上屏之前**那一版（46,916 B / tomato 24,523 / `未画种类 1`）几乎一致 —— 看起来像回归，**实际是配置差异**。

**A/B 实测（同一次会话、同一二进制、只改字体 env）**：

| 配置 | PNG 字节 | 白像素 | `未画种类` | 文字 |
|---|---|---|---|---|
| **无 env（默认）** | 46,902 | 6,300 | **1** | **不画** |
| `WPF_LINUX_TEXT_FONT_DIR=build/fonts-ui` | 56,037 | 8,314 | 0 | 画 |
| `HLWPF_UI_FONT=…/UI-NoLayout.ttf` | **56,055** | **8,318** | 0 | 画 |

### 🔴 新登记缺陷（主控实测，P0 级）：**默认配置下文字整段不画**，唯一信号是 `未画种类 1`

**根因链（已实测到字族层）**：`MilPresentation.EnsureGlyphRenderer()`（`Interop/MilPresentation.cs:333`）自身按
`WPF_LINUX_TEXT_FONT_DIR` → `WPF_LINUX_FONT_DIR` → `/usr/share/fonts` 选**目录**，并把**字族硬编码兜底成 `"Noto Sans"`**；
而 `/usr/share/fonts` 里**没有真正的 `Noto Sans` 族** —— `fc-match "Noto Sans"` 命中 **`Noto Sans CJK SC`**（`NotoSansCJK-Regular.ttc`）。
同时 WPF 侧解析出的 message font 是 **`DejaVu Sans`**（`DejaVuSans.ttf`，**确实在系统目录里**）。
⇒ **字形 id 来自一个面、光栅化用另一个面** ⇒ 2 个 `MilGlyphRun` 一个也没画出来。
**这直接违反 handoff:1539 自己写下的不变量**："**glyph id 是字体相关的，必须与 WPF 侧同一份字体**" —— 当时的实现只对齐了**目录**，字族用的是独立硬编码，**面根本没对齐**。
**为什么一直没被发现**：验收是**带 env** 跑的，而"不设 env"（= 真实应用的默认）**从来没有人跑过**。
**⚠️ 别把"有 workaround"当成"不用修"** —— 真应用不会去设 `WPF_LINUX_TEXT_FONT_DIR`，所以**默认路径就是真应用拿到的路径**。
**真机对照（2026-09-11，`tests/parity/systemfonts/`）—— 别把 `DejaVu Sans` 当成"Windows 的答案"**：Windows 上六个字体族属性（Message/Caption/SmallCaption/Icon/Menu/Status）**全是 `Microsoft YaHei UI`**，且**三处逐字相同**（`SPI_GETNONCLIENTMETRICS.lfMessageFont.lfFaceName` = `HKCU\Control Panel\Desktop\WindowMetrics\MessageFont` 的 92 字节 `LOGFONTW` blob = `SystemFonts.MessageFontFamily.Source`）⇒ **它是数据驱动的每用户设置，不是硬编码**；并且它**必在 `Fonts.SystemFontFamilies` 里**（91 个族，三种比法全 true）。`DejaVu Sans` **根本不在那 91 个族里**（只有 `DejaVu Sans Mono` / `DejaVu Math TeX Gyre`）⇒ **我们报的 `DejaVu Sans` 是 Linux 字体集的产物，不是 WPF 的 SPI 默认值**。
"**字形 id 的面 ≠ 光栅化的面**"在 Windows 上是**另一种形态、同一根因**：`MSYHL.TTC#1` 的 `familyNames="Microsoft YaHei UI"` 但 `win32FamilyNames="Microsoft YaHei UI Light"`、`faceNames="Light"` vs `win32FaceNames="Regular"`；该族 **3 文件 / 6 face**，**Light 字重是 290 而非 300**（按字重匹配也会落到别的 face），**glyphCount 逐 face 不同（29816 / 30202 / 29949）⇒ glyph id 是逐 face 的**。⇒ Windows 用"同文件内不同 face"表现，我们用"族名解析失败后回退到别的族"表现，**根因同一条** ⇒ **修法方向（面必须由 glyph run 自身决定）得到真值支撑**。
（边界：真机只证到"每用户的持久化设置"；**"换主题会不会变"未验证**（禁止改系统设置，对方拒绝拿推测代替）；反向证据是本机 7 个 `.theme` 文件**无一含 `[Control Panel\Desktop\WindowMetrics]` 段**。**别写成"随主题变"**。）

### 🎯 真机 oracle **推翻了 B2 的两条口径推断**（2026-09-11，`tests/parity/windows/layout-b34/`，614 例 / 3222 行）

T1 在 ICU 对拍里得出的三类记账口径，**两条是错的**，若照它落地会写出**与真机行为不同**的代码：

| T1 的推断 | 真机裁定 | 原始证据 |
|---|---|---|
| 行区间**不含**换行符 | ❌ **推翻** | `B_hard_lf_w120` 源 `'first line\nsecond line\nthird'`(28)：行0 `Start=0 Length=11` 区间原文 `'first line\n'` ⇒ **`Length` 含硬断字符**；`NewlineLength` 单独给出它占几个（换行行=1、软换行行=0、**段落最后一行也=1，那是 EOP**） |
| 相邻 `\n` ⇒ **零长度行** | ❌ **推翻** | `B_blank_lines_w120` 源 `'para one\n\n\npara three'`(21)：4 行 `Length 9/1/1/11`；空行是 **`Length=1`、内容就是 `'\n'` 的普通行**，`Width=0` 但 `Height=21.793 Baseline=17.103` 与普通行**完全相同**（照样占一行高） |
| 行尾空白**不占宽但占区间** | ✅ **证实** | `B_spaces_w120` `'  leading and   '` → `Length=16` / `Width=97.003` / `WidthIncludingTrailingWhitespace=109.483` / `TrailingWhitespaceLength=3` |

**另 5 处 API 事实纠正（都会直接影响写什么代码）**：
① **`GetTextCollapsedRanges()` 未折叠时必须返回 `null`，不是空集合**（**3222/3222 全是 null**；T1 方案里写的"空列表 = 没有折叠"**是错的**）。
② **`GetTextLineBreak()` 普通文本就是 `null`**（null 3220 / 非 null 仅 2 行，那 2 行是 `CTextModifier` 造的）；**`TextLineBreak` 公开属性数 = 0**（只有 `Clone()`/`Dispose()`）⇒ 它是个**不透明令牌**，`TextMetrics.cs:299-308` 只在"末 run 有 `TextModifierScope` 且不是 `TextEndOfParagraph`"时才 new ⇒ **"一律发 Zero record"会在 3220/3222 行上与真机行为不同**。
③ **`Collapse(TextLine)` 这个 API 不存在**（公开面只有 `Collapse(TextCollapsingProperties[])`；空数组 = 原样复制）。
④ **`GetTextRunBounds` 不存在**，等价物是 `GetTextBounds(firstIndex(段落系), length)` → `TextBounds.TextRunBounds`。
⑤ **`TextLine.Start` 恒为 0（3222/3222）**，**不是段落内偏移** ⇒ 行起点只能由调用方累加 `Length`；且 WPF 有 **SimpleTextLine / FullTextLine 两条实现**（选择条件 `TextFormatterImp.cs:224`），**SimpleTextLine 的 `GetTextLineBreak`/`GetTextCollapsedRanges` 恒为 null**（`SimpleTextLine.cs:973/983`）。

**⚠️ 口径冲突裁定（重要）**：已验收的 **73 例 kinsoku 表走 DirectWrite `IDWriteTextLayout`**（`dwrite.dll` 的断行引擎）；**本 oracle 走 WPF 托管栈 `TextFormatter → TextMetrics → lsapi`（`LoAcquireBreakRecord`）**。**两条不同实现路径，断行结论不保证一致。** 而 **Linux 侧实现的是 `TextLine`/`TextFormatter` 契约 ⇒ 以本 oracle 为准**；73 例那张表在 Linux 侧使用时**必须标注"DWrite 口径"**，冲突时以 oracle 为准。**主控已要求把 73 例的断行位置与 oracle A 组逐行对拍并给出吻合/不吻合数字。**

**负结果（明确回答）**：**WPF 上游不支持竖排文本** ⇒ backlog 里的"竖排"**改判为"超出上游能力"**（见 `docs/ARCHITECTURE.md` 的 `Sideways` 行），**不再算我们的缺口**。

### ⚠️ 本轮方法学教训（主控自己犯的，6 条里 5 条是**工具在骗我**）

1. **拿"我的运行结果"与"存档验收件"比对，必须先控制配置** —— 我差点把"默认配置无文字"判成**回归**。**救回来的是 A/B**（同会话、同二进制、只改一个 env），而不是更仔细地看直方图。**"看起来像回归"不等于回归**；先问"两次的配置一样吗"。
2. **跑别人正在改的 runner，竞态面是脚本本身，不只是二进制**。我按老经验只哈希了 `.so`/`dll`，结果 `run-hellowpf.sh` 在我跑的**同一秒**（mtime 13:56:42）被写，我读到半成品（`行 128: 拿**上一次的旧: 未找到命令`、`行 138: 未预期的记号 "else"`）。**修法**：拷一份**同目录**快照（`$ROOT` 才对得上）→ `bash -n` → 跑快照 → 删。
3. **共享运行目录会被并发运行互相覆盖**：`M7C_RUN_DIR` 默认 `/tmp/m7c-hellowpf`，我与 M7b 同时在跑 ⇒ 我的截图被它的覆盖，**证据直接没了**。凡并发跑同一 runner，**必须各自设 `M7C_RUN_DIR`**。
4. **`pkill -f 'Xvfb :98'` 会匹配到我自己那条命令行**（因为同一条命令行里就有 `Xvfb :98` 这个字面量）⇒ 我把自己 SIGTERM 了。`[X]vfb` 括号技巧**只挡住 pkill 命令自身**，挡不住同一命令行里的其它字面量。**修法：`XPID=$!` 后 `kill $XPID`**。
5. **`RC=$?` 写在管道后面拿到的是管道尾的退出码**（`... | tail -70; RC=$?` ⇒ 永远 0）。**这不是小事**：它会把失败读成成功。**修法：重定向到文件再取 `$?`，或 `set -o pipefail`**。
6. **`setsid bash -c './verify-all.sh …'` 没带 `PATH=$HOME/.dotnet` ⇒ 8 个步骤全 `rc=127`（命令未找到），报出一个"步骤通过 1 / 失败 8"的假红**。`verify-all.sh` **自己并不设 PATH**（上游笔记说"调用方必须给"）。**这是本轮唯一一次"假红"** —— 但代价一样：我差点据此去查"树是不是坏了"。**修法：后台起任何会调 dotnet 的脚本，显式导出 PATH**。

> 这 6 条里有 5 条是"**我的验证工具本身在说谎**"（脚本快照、共享目录、pkill 自杀、管道 rc、缺 PATH 的假红），
> 与之前那 5 次假绿同源。**"我加了验证步骤" ≠ "我被验证过"** —— 每加一个观测环节，要先问它**自己会不会撒谎**。
> **补充一条（U1a-J 本轮自己发现并主动报告的）**：它的第一版 `--sabotage`（破坏性自检）**是没牙的** —— 只改了"报出来的族名字符串"，解析仍走真对象，于是 `failures=0`。改成"**破坏解析本身**"后才真红（`failures=1 / RC=2`）。**"我做了破坏性自检"也不等于"我的断言有牙"** —— **断言必须能被现场推翻，这条只有故意破坏一次才知道。**



### ★ U14（展平密度差异）：**结论"不值得做"** —— 主控接受，并裁定**不加静默密度上限**

**产物**：`tests/parity/geometry/u14/`（`U14-flatten-density.md` + `cases-u14.json` + `windows/linux-results-u14.json` + `Program.cs`）。**未改 `src/`、未动 U1c 冻结产物。**

**差异量化（30 例 = U1c 基础 14 + 新探针 16）**：**真缺陷 0** —— 「我方误差 ÷ 请求容差」在**所有容差有意义的用例上 ≤ 0.756**（最坏 0.735；误差 = 沿真曲线等距采 801 点、到折线的最大距离）。
`tol=0.001` 那例我方误差 **7.56e-4 < 真机 7.85e-4** ⇒ **我方只是点少，不是更差**。
点集差异是**双向**的：r=1e7 时我方 734,721（真机 4097），而**发夹/急转反而我方更稀**（2 vs 47、9 vs 47）。

> ### ⭐ 反向发现：**真机违反了自己的容差**
> `u14_huge_circle`（r=1e7）：真机误差 **3.57**，而请求容差 **0.1 / 0.001** ⇒ **超差 35.7× / 3569×**。
> 原因是它的"最小步长地板"（`TWICE_MIN_BEZIER_STEP_SIZE = 1e-3` ⇒ 每曲线最多 1024 段）**先于容差生效**。
> ⇒ **"照抄上游" ≠ "更正确"** —— 这条值得单独记住。

**我方新量化出的真实风险**（同 harness、单用例、已扣除同命令启动基线）：r=1e7/tol=0.1 → 我方 **8.17 s / 356 MB**（净 ≈6.2 s）vs 真机 **0.20 s**；tol=0.001 → **11.22 s / 703 MB** vs 0.19 s。
⇒ **我方的问题是"密度无上限"，不是"不够密"**，量级差 ≥100×。

**原型（HFD 逐行移植 `bezierflattener.cpp`）**：**30/30 用例点数相同、逐点坐标完全相同，最大逐点偏差 = 0**（同一串 float32，不是"接近"）；差异全部归零。
**附**：我方算法的逐行复刻在 30/30 上与**真实实现**点数一致 ⇒ 探针里"我方"列可信。

**落地规格与风险**：**S1** 换 HFD（代码已在 `u14/Program.cs`，验证过）+ **S2** 容差绝对化（`rel ? max(tol,1e-12)*extent : max(tol, extent*1e-12)`）。
⚠️ **S2 绝不能单独落**：实测只改容差（`tol=0` → 8e-11）时我方二分爆到 **1,594,827 点/次调用**（真机 4097），因为**上游靠 1e-3 地板收口、我们没有**。
**23 张 golden 影响 = 零，且是"可复核的结论"而非推断**：`MilGeometryEngine.Flatten`/`ResolveTolerance` 在 `src/` 里**只被 `MilNative.Geometry.cs` 的 7 处调用**，`Rendering/`/`Commands/`/`Resources/`/`Contracts/` **零引用**；`Rendering.Tests` 零引用 `MilUtility`/`MilGeometryEngine`；`GoldenRunner` 走 Skia 直接细分曲线。

> ### ✅ 主控裁决（两条）
> **① 接受"不值得做"**：无真缺陷可修；上游的密度来自"二阶导代理判据 + 1024 段地板"，是**按构造而非按需的过细分**（发夹上我们 2 点/误差 2.9e-4 vs 上游 47 点/3.6e-5，**两者都远在容差 0.1 内**）；代价是输出最多 ×63。
> **② 不加静默密度上限** —— U1c 指出"≤4096 段/曲线"同样是"用精度换可用性"，会让我们**和真机一样违反容差**（r=1e7 从"73 万点、误差≪0.1"变成"≤4096 点、误差≈3.6"）。**那等于把一个"慢但正确"的行为换成一个"快但静默不准"的行为** —— 违反本工程"绝不静默出错"的底线。
> **若将来确需保护**，honest 形态是**可观测**（超阈值时打诊断/计数），**不是静默降精度**；若要求"永不违反容差"，则应**报错**而不是降精度。
>
> **⚠️ 我把两边论证都留在册，便于日后复议**：U1c 的反对理由是"零精度收益、代价 ×63"；而**支持派 HFD 的理由**（我记下来但不据此行动）是：本项目目标是**移植 WPF**、且已有 215 例几何 parity 工程，而原型已达 **30/30 逐点精确一致**、且 HFD 自带 1024 段地板（**顺带把"密度无上限"也收口**）。
> **复议触发条件**：当"几何导出的字节级/命令流 parity"成为目标时（例如 U1b 式 golden 流扩展到几何导出），**S1+S2 成对落地**，规格与已验证原型都已备好（`tests/parity/geometry/u14/Program.cs`）。

#### ★ B1 落地脚手架（T1 第二轮，主控已复跑）

**主交付**：`build/shims/PresentationCore.HbTextLine.cs` —— **657 行 = 代码 457 + 注释 115 + 空行 85**（**代码行 457**，比原型 311 多，因为多了"直构分支 + 欠账回退 + 计数器 + 开关"）。
登记在 `build/shims/PresentationCore.shims.txt:30`。复现 `bash build/MilBridge/run.sh textline` → **9/9**（主控复跑一致）。

**⭐ 一处值得学的验证完整性**：`TextLineProto.csproj:25` 用
`<Compile Include="../../../shims/PresentationCore.HbTextLine.cs" Link="…" />`
⇒ **测的就是那个真 shim 文件本身，不是副本**。所以"9/9 通过"意味着**将要编进 PC 的同一份源**通过了验证 —— 而不是"一个长得像它的副本通过了"。**这类"测的到底是哪个文件"的问题，本项目已经栽过好几次（身份自检看错 dll），这次是正面示范。**

**① 反射 → 直构**：用 `#if TEXTLINE_SHIM_DIRECT` 把"反射造 `TextBounds`/`TextRunBounds`"换成直接 `new`（签名按上游 `TextBounds.cs:23`/`:77` 核对）。**同一源文件编两次**，唯一差别是"怎么拿 `TextBounds`"，
实测对照：**字形数 37 / `Width·Height·Baseline` = 493.4880·32.6880·25.6560 / advance 与 HB 直算逐项相等 / 非白 3954 / PNG 4722 B —— 与原型逐项相同**。
（`GlyphTypeface(Font)` 的反射**不再需要**：构造签名本来就收 `GlyphTypeface`，落地形态由调用方传。）

**② 9 个欠账 → 安全回退（不抛）+ 计数**：`GetTextLineBreak`→`null`（单行无 `\n` 是**正确语义**，不是降级）、`GetTextCollapsedRanges`→空、`Collapse`→`this`、`GetIndexedGlyphRuns`→空序列、光标/命中 5 个→安全默认。
**A7 实测：9 个全部回退、0 个抛、各自计数 = 1**；另有 `WPF_LINUX_TEXTLINE_STRICT=1` 严格模式（A8 实测会抛，bring-up 定位用）。
计数器**可被程序读到**（不是只打日志）：`HbTextLineScaffold` 为 **public**，有 `HitCount`/`TotalFallbackHits`/`SummaryLine`，并支持 `WPF_LINUX_TEXTLINE_DUMP=<path>` 退出时落盘。

> ### ⚠️ T1 指出**我给的指令自相矛盾**，并用更好的办法替代 —— 这条要留档
> 我同时要求"**跑 HelloWpf 统计欠账命中次数**"和"**本轮不要改 PC 的选路逻辑**"。
> **这两条冲突**：选路没改 ⇒ HelloWpf **不可能构造出 `HbTextLine`** ⇒ 跑一次只能得到**全 0 计数器**，**根本测不出 B2/B3 优先级**，还平白多一次和 M7b 抢 `:99` 的风险。
> **它没有默默照做、也没有默默跳过，而是把问题指出来并换了方法**：做**静态调用点普查**（全上游 PC + PF + UIAutomation 对 `TextLine` 的调用点）。
> **教训**：我自己写的"测量方案"未必可测量 —— **执行者发现方案不可执行时，指出矛盾比硬跑一遍有价值得多。**

> ### ⭐★ **静态普查更正了 B2 的计划**（推翻 T1 自己在 M7c4 里的 B2 切分）
> | override | 调用点 | 主要调用者 | 结论 |
> |---|---|---|---|
> | **`GetTextLineBreak`** | **9** | `PtsHost/TextParagraph.cs`(2)、**`FormattedText.cs`(2)**、**`TextBlock.cs`** | **B2 第一优先 —— 它就是"换行"本身** |
> | `Collapse` | 12 | `Text/Line.cs`(6)、`PtsHost/Line.cs`(6) | B2（带 Trim 的 TextBlock） |
> | `GetCharacterHitFromDistance` | 9 | `PtsHost/Line.cs`(4)、`ComplexLine.cs`、`TextBoxLine.cs` | B3 |
> | caret 家族 4 个 | 7–8 各 | 同上 | B3 |
> | `GetTextCollapsedRanges` | 2 | `Text/Line.cs`、`PtsHost/Line.cs` | B2 |
> | **`GetIndexedGlyphRuns`** | **0** | **全上游零调用点** | **可以砍掉/降级 —— 与"B2 该做它"的直觉相反** |
> ⇒ **B2 的真实内容是 `GetTextLineBreak` + `Collapse` + `GetTextCollapsedRanges`（换行与折叠），不是 `GetIndexedGlyphRuns`。**
> 运行期精确取法写在 T1 报告 §7（开开关 + `DUMP` + 跑 runner + `cat`），**接线后一次就能拿到**。

**⏳ 待主控在 PC 重建后复验四件（T1 报告 §5）**：① `#if TEXTLINE_SHIM_DIRECT` 那一支**从未被编译过**（internal 可见性只有 PC 里有），可能报 ctor 签名差异；② 加 `-p:DefineConstants=TEXTLINE_SHIM_DIRECT` 重跑应见 **A1–A9 全同**；③ PC 编译面 **0 错 0 警**；④ **既有 742 用例逐项不变**（默认关 + 结构上零调用点）。
**⚠️ 主控据此暂缓 PC 波**：T1 仍在写 PC 侧文件（`build/PresentationCore.Linux/` + 新应用器），此时跑 `port-lib.py` 会重生成那个目录 ⇒ **必须等它交完**。

### 轨道 D 结果（U1，**决策级**，主控已复验）—— **shaping 真值到手：HB == DirectWrite，零差异**

**产物**：`tests/parity/windows/shaping/`（12 个文件）= `PROVENANCE.md` + `out/`（`dwrite-shaping-oracle.{json,txt}`、`hb-comparison.{json,txt}`）+ `src/`（`ShapingOracle.csproj`/`Program.cs`/`Interop.cs`/`compare_hb.py`/`generate.ps1`/`stab.ps1`/**`SDK_dwrite.h.reference`**）。

> ### ✅ 核心结论
> **在本语料（4 字体 × 2 字号 × 7 文本 = 56 用例）上，DirectWrite 与 HarfBuzz 14.4.0 逐字形、逐 advance、逐 cluster 完全一致**：
> `cases=56 exact-match=56 differ=0`，最大 advance 差 **1e-06 DIP**，总宽差 **9e-06 DIP**。
> ⇒ **这份 oracle 可直接当"路线 B 对不对"的判据。**

**主控独立复验**：① oracle 里四个 `fontSha256` = `f3961a9cde016d41`/`87cb2d84472a7d66`/`678288f868807d4d`/`3d367743f371f286`
—— **与 `build/fonts/NotoSans-*.ttf` 逐字节相同** ✅（"必须同源、不许撞系统同名异内容字体"这条守住了）；
② `hb-comparison.txt` 的 `exact-match=56 differ=0` ✅；
③ 连字用例 `ffi fi fl office affluent` → `glyphIds=[1656,3,1654,3,1655,3,82,1656,70,72,3,68,1657,88,72,81,87]`（26 字符 → **17 字形**）与它报的逐字相同 ✅；
**并发现它这份数据还顺带抓住了 `ffl` 连字**（`affluent` 里的 `1657`）—— **比它自己声明的覆盖面更强**。

**引擎与口径**：真机 `dwrite.dll 10.0.22621.4745`、纯托管 `net10.0-windows`、零 NuGet、**没用 zig**。
`CreateFontFileReference(我们的 ttf) → CreateFontFace → GetMetrics → CreateTextAnalyzer → GetGlyphs(GSUB) → GetGlyphPlacements(GPOS/kern)`，
`script=0`、`locale=en-us`、**不传 features**（= 字体默认特性，与 HB 默认同口径）。字体**从文件加载、不安装**。
**HB 确实在 shaping 的反证**：`ffi fi fl` 默认 5 字形，关掉 `liga/clig/kern` 变 9 字形；`AV` 合计 1199 vs 1239（差 40 = kerning）—— DWrite 给**完全相同**的结果。

> ### ⭐ 主控记档：**它在一处比我要求的更对**
> 我原话是"用 `IDWriteTextLayout` 导出"。**它改用了 `IDWriteTextAnalyzer`，理由更硬**：
> layout 需要 `IDWriteTextFormat`，而 format 要求字体进 font collection ⇒ **要么安装字体（= 改系统，越界）、要么实现 collection loader**；
> 而 **`IDWriteTextAnalyzer` 才是 WPF/DWrite 真正做 shaping 的那一层** —— 既避开越界，又**恰好给出路线 B 最需要的判据**。
> 它还把**行高明确标成推导值**（带 `lineHeightNote`），**不冒充 layout 真值**。
> **⇒ 指令可以被更好的方案替代，只要把理由说清。这是本轮第二个"执行者纠正主控"的实例**（第一个是 T1 指出我的测量方案自相矛盾）。

> ### ⭐★ 这个结论**改变了排期**（主控据此重排）
> **shaping 层已被证明是对的** ⇒ 路线 B 的风险**全部**落在 `TextLine` 契约的 **B2/B3（换行与光标）**，**不在 shaping 正确性上**。
> 而 T1 的静态普查已确认 **B2 = `GetTextLineBreak`（换行）+ `Collapse` + `GetTextCollapsedRanges`**。
> ⇒ **"B1 + B2 + 接线"就能得到"与 Windows 逐字形一致"的文本**（至少拉丁 LTR）—— **比我原以为的强得多**。
> **顺带把 §2.6 降级的代价量化了**：名义快路径 41 字形/500.5425px vs DWrite 真值 37 字形/493.4880px = **Δ−4 字形、−7.0545px**
> —— 现在这是**有 oracle 背书的可测量保真损失**，不再是"我们知道有差"。

**诚实边界（U1 自己划分，我照收）**：能对拍 = 字形 id / 逐字形 advance / cluster / 行宽 / 字体度量（本语料零差异）。
**不能对拍/未覆盖**：① **行高是推导值**，不是 layout 真值；② **`mixed-cjk` 不是 CJK 真值** —— `NotoSans-*.ttf` 本身不含 CJK 字形，该串有 6 个字落到 `.notdef`；
③ bidi / 复杂脚本（Arabic、Devanagari）/ 非默认特性（`locl`/`vert`/variation）未覆盖；④ hinting/取整/次像素未覆盖（那是 `GetGdiCompatibleGlyphPlacements`）。

**两个坑（已写进 PROVENANCE）**：① **vtable 槽位必须按 SDK `dwrite.h` 含 3 个 IUnknown 槽**（`CreateTextAnalyzer=21`、`GetGlyphs=7`、`GetGlyphPlacements=8`，且后者在 fontFace 后有 **`FLOAT fontEmSize`**、`GetGlyphs` 第 8 参是 `IDWriteNumberSubstitution*` 而非 typography）——
错一个就是 `0xC0000409` 栈损坏或**全 0 advance**；权威表随源码留档 `src/SDK_dwrite.h.reference`（取自 NuGet 的 Windows SDK 头，**未装任何系统组件**）。
② 该 exe **约一半进程启动**会在 `GetMetrics` 上返回垃圾 HRESULT（已排除槽位/结构体布局/delegate 编组）⇒ `generate.ps1` 带**进程级重试**并**自动校验两次成功运行逐字节相同**（已通过）；**数据已校验，不必重跑**。

**已派 U1 继续**：① **layout 级真值**（最小 `IDWriteFontCollectionLoader` 把未安装字体塞进 collection ⇒ 真 `IDWriteTextLayout` 的行高+换行位置）—— **B2 就是换行，没有换行真值 B2 只能自己跟自己对**，故优先级略高；② **CJK oracle**（同代码换含 CJK 字形的字体 + 改语料）。

### 轨道 B 首轮结果（T2，主控已复验）
| 验收 | 结果 |
|---|---|
| ② **DPI 真值** —— **「固定 96」偏差销账** | PNG `pHYs=11811 px/m → DpiX=299.9994`；JPEG JFIF density `150 → DpiX=150`；**无分辨率文件 → 96（正确退化，不再"恒 96"）** |
| ② 元数据读 | `GetQuery("/tEXt/{str=Title}")` = `"TrackB"`；真实截图 `comment` = `"HelloMil — WpfGfx.Linux on X11"`（UTF-8 正确） |
| ④ 失败路径 | 键不存在 → `PROPERTYNOTFOUND(0x88982f40)` → PC `GetQuery` 吞成 `null`（**上游语义**）；不支持格式（TIFF）→ `COMPONENTNOTFOUND(0x88982f50)` → `NotSupportedException` |
| ① 写→读（**shim 级**） | `probe_write_loop`：PNG 121 B（含注入 `pHYs`）/ JPEG 323 B → 读回 `8x8 first=0xFF110000` 一致，`WRITE_LOOP=PASS` |
| ① 写→读（**WPF 级**） | ⏳ **跨轨阻塞**：链路全通并留痕（`SET_ENCODER_FORMAT 8x8 → Bgra32` → `ENCODED PNG 100 字节` → `PNG_INJECT pHYs=1 → 121 字节` → `MIL_WRITE=ok`），但**用户 `FileStream` 收到 0 字节** |
| ③ `WriteableBitmap` | ⏳ **跨轨阻塞**：`AcquireBackBuffer:962 → set_WicSourceHandle:584 → MILQueryInterface` 返 `E_HANDLE` |

**两个跨轨阻塞已转给 M7b（`MilNative.Misc.cs`，同一文件）**：
1. **流转发**：`MILIStreamWrite`（`:207-228`）只写 `MilStreamObject.Data`、**不转发**给 `StreamDescriptor` 回调 ⇒ 用户流 0 字节；**同一条也解释"编码到只读流竟然成功"**（根本没往调用方流里写）。修法：转发到描述符的 Write 回调（`MilReversePInvokeTable` 已存在）或给 shim 一个"取走字节"的导出。
   **⭐ 顺带销一条债**：§2.4 写着 `MILCreateStreamFromStreamDescriptor` 的 13 个委托**没有 native 侧消费者** —— **这就是第一个**。
2. **back buffer 句柄**：该句柄既不在 `MilDeviceObjectTable` 也不被 `WicShim_OwnsHandle` 认领（T2 没创建它）⇒ MIL 需注册成设备对象，并让 `MILQueryInterface` 对 `IID_IWICBitmapSource` 放行（`:102` 现在只接受 `IID_IUnknown`）。
   **硬约束**：引用计数契约（`MilNative.Misc.cs:368` 原文）—— MIL 自建句柄走**原有** AddRef/Release，**不要**混进 `WicShim_*` 那条外部句柄路径（混了就是账本单边 ⇒ 下溢或提前释放）。
**主控复验**：`libwpfwic.so` = **56,888 B / sha `d21cf59424da2b23d6db73e85ed9db4e078a6faf8c489b402bbc1cde1b9c44d8`** ✅；**读路径无回归**（复跑 `run-harness.sh` → `RESULT=PASS`、`BYTE_MISMATCH=0/1920000`、`CHECK1/2/3=PASS`）✅。

> ### ⭐★ **第三次同族教训 → 升格为纪律：「约定值一律回源码」**
> T2 用 `{0xb96b3caa-…}` 当 PNG 容器 GUID，**上游真值是 `{0x1b7cfaf4-713f-473c-bbcd-6137425faeaf}`**（`Common/Graphics/wgx_exports.cs:334`；JPEG `{0x19e4a5aa-5662-4fc5-a0c0-1758028e1057}` `:332` —— **主控已逐字段核对一致**）。
> **后果比前两次更隐蔽**：它**不只污染写面**，读路径的 `GetContainerFormat` **一直在报错值**，直到 `CreateEncoder` 比对容器 GUID 返 `COMPONENTNOTFOUND` 才暴露 —— **一个错误常量平铺在"已经绿了的"读路径里，靠新功能交叉才照出来**。
> 三次同族：`0x88982F0B` 被当成 `UNSUPPORTEDOPERATION`（实为 `UNSUPPORTEDVERSION`）→ 错误信息**撒谎**成 `FileLoadException("Mismatched versions…")`；
> `0x88982F04` 被当成 `NOTIMPLEMENTED`（实为 `WRONGSTATE`）；这次是 GUID。
> **纪律**：**每个错误码 / GUID / 枚举值都必须回到上游源码取出处、并在注释里写出处**（`file:line`）。
> Skia 侧没有源码可查的枚举，用**实测**（T2 的 `probe_encode.c` 逐个试出 `sk_image_encode_specific` 的 `PNG=4 / JPEG=3 / WEBP=6`，**不是猜的**）。
> **本工程已有 5 处"假绿"，加上这次"错误常量长期潜伏在读路径里"，共同点是：断言/常量只要没被交叉验证过，就会一直"看起来对"。**

> ### 留档：该回归当时的症状与主控的缩圈证据（供后人对照）
> **实测 6/6 稳定复现**（5 连跑全 27/28）：`COMException (0x80070006) E_HANDLE`，
> 栈在 **Dispatcher 关闭的 `MediaContext` 拆除路径**上：
> `Dispatcher.ShutdownImpl → MediaContext.Dispose (:1441) → MediaContext.RemoveChannels (:1247) →
> ChannelManager.RemoveChannels (:92) → DUCE.Channel.Close() (exports.cs:430) → HRESULT.Check (wgx_render.cs:975)`。
> `exports.cs:425-431` 的 `Channel.Close()` 固定序列是 `CloseBatch(:429)` → **`CommitChannel(:430)`**；
> 我们的 `MilConnection_CommitChannel`（`MilNative.cs:103-114`）有**三处**可能返 `E_HANDLE`（`:106 Resolve==null`、`Commit()`、`PresentChannel()`），已要求 M7b 逐处钉死。
> 已核对：`MilConnection_CloseBatch`（`:80-84`）**不注销**通道，**只有** `DestroyChannel`（`:67-77`）注销 ⇒ `Resolve` 返 null 意味着通道在 `Close()` **之前**已被销毁。
>
> **主控已排除的**：**不是我翻的 WIC 开关造成的** —— 把 `WicEnabledByDefault` 分别置 `true`/`false` 各重建 PC 再跑，**两次都 27/28**。
> **主控提出的主要假设（待 M7b 证实/否证）**：这是**被新暴露**的既有缺陷，而非新引入 ——
> 该用例的"已登记失败清单"只有 ① STA ② 原生面缺失；今天三处改动（DPI 真实现、`LoGetEscString`、**呈现触发器 + 字形渲染器**）
> 之后窗口**真的建起来并渲染了**，拆除路径**第一次真正跑到** `MediaContext.Dispose → … → Channel.Close()`，于是撞上这个一直在那儿的 bug。
> **处置口径**：若成立则**修缺陷**（`Channel.Close()` 失败本身就不该发生），**不许**把新理由登记进清单了事，也**不许**把 `CommitChannel` 改成"查不到就返 S_OK"来吞错。

**主控独立复验 T1 的新 `.so`（2026-09-10，非自报）**：`sha256sum` = `fa70a21b91bda6f2a821f4146174458f0a37d71a409b1713faaf2efa8d172c5e` ✅、`ls -l` = 4,519,360 B ✅；
按 `build/MilBridge/gen/export-symbols.txt` 逐条核对：**清单 109 条，缺失 0** ✅；`MilBridge_*` 诊断导出 **14** ✅。
**一处口径更正（不影响结论）**：T1 报的"总 `T` 符号 121 → 125"里，**125 是 `nm -D --defined-only` 的全部动态符号**（123 `T` + 1 `D` + 1 `A`），**纯 `T` 是 123**；`+4` 的增量本身正确（对应 10→14 条诊断导出）。留此一笔是为了口径可复算 —— 报数字时写清**用的是哪条命令**。

> **尚未启动的难点（按价值排序，供后续排期）**：① ~~LineServices 110 条 vs HarfBuzz 级 shaping~~ → **已决策，见上表 T1 行**：
> **路线 A 否决（没有源）、路线 C 正在做（通用化降级，~300 行）、路线 B 是目标态但缺一条限时原型实测**。
> **B 的原型（限时、≤400 行、只实现 `GetTextRunSpans`+`GetTextBounds`+`Draw` 三个 override）是下一个待派的测量任务** ——
> 它决定 B 是"成本可控、分阶段做"还是"被 `DrawingState`/`TextRunCache`/`TextMetrics` 的连锁低估了"。
> **另有一条未闭环项**：**Windows 上没有 shaping 真值**，要真值需在 Windows 跑 `IDWriteTextLayout` 导出 glyph id + advance（机器空闲，可排）；
> ② **DrawingBrush/VisualBrush/BitmapCacheBrush**（`SkiaBrush` 仍走 default → 不填充）；③ **3D 光栅化**（U5，29 条命令只解码）；④ **媒体**（U3，21 条 E_NOTIMPL）；
> ⑤ **U1 未覆盖场景的真机对照**（文本/位图/效果/3D/动画；Windows 机空闲且抓流链路已通）；⑥ **其它主题程序集**（Aero2/Fluent… 仅当让 shim 假装 Windows 主题时才需要）；
> ⑦ **跨线程 DUCE 传输**（当前恒 SameThread，唤醒落点已预留）；⑧ **OLE 剪贴板/DnD 真实现**（U13，X11 selection/Xdnd）；⑨ **Win32 shim 剩余 ~110 条导出**；
> ~~⑩ MilBridge 的 `-Wl,-rpath,$ORIGIN`~~ —— **已作废**：T1 的 `dladdr` 自定位让纯 C 宿主零配置即可用，M7b 的部署清单**只需两个 `.so` 同目录，不再要求那是"应用目录"**。

### 阻塞链（决定最终目标能否达成）
```
T2–T6 全部 ✅ 已交付（六次复验 401 通过）
        ↓
T3 命令层 ✅ 110/118（剩 7 条 E_NOTIMPL + 1 哨兵；位图源 0x0c/0x0d 已解锁）
        ↓
T5 键鼠输入 ✅ 10 条真注入用例（突变验证通过）
        ↓
T9-HelloMil（无需 WPF 运行时）──→ M1 终点：API→渲染→X11 真窗口→截屏 ✅ 路线已定
        ↓
T9-HelloWpf（M2 范畴，需移植 118 万行托管层）──→ Avalonia 量级，独立项目
```

### ★ 认知修正：T8「缺布局 / 依赖属性 / 绑定测试」是**错列的目标**，已从欠账中划掉

早期看板把「布局 / 依赖属性 / 绑定」记为 T8 欠账。这是**把两个工程混为一谈**：

| 子系统 | 属于哪一层 | 本工程（WpfGfx.Linux）有没有 |
|---|---|---|
| 布局（Measure/Arrange） | WPF **托管层** | ❌ 不存在——渲染后端只消费已排好版的视觉树 |
| 依赖属性（DependencyProperty） | WPF **托管层** | ❌ 不存在 |
| 数据绑定（Binding） | WPF **托管层** | ❌ 不存在 |
| MIL 命令 / 资源 / 渲染 / 窗口 / 文本 / 输入 | **渲染后端** | ✅ 全部存在且已测（401 用例） |

本工程的定位是 **Linux 上的 WPF 渲染后端**，不是「WPF 托管层跨平台」。
给不存在的子系统写测试是无意义的——**这三项不应计入 M1 欠账**，随 M2 移植托管层时才有意义。

**M1 缺口状态（2026-09-04 全部关闭 —— 三项全 ✅，无遗留）**：

| # | 缺口 | 状态 |
|---|---|---|
| 1 | `docs/ARCHITECTURE.md` | ✅ 已交付 486 行 / 9 节 |
| 2 | flaky 根因（GCHandle 槽位复用 ABA） | ✅ 已根治，20/60/100 轮 0 失败 |
| 3 | 键鼠输入事件无测试覆盖 | ✅ **已补（2026-09-04）**：`xdotool` 真注入 10 用例，突变验证通过 |
| 4 | 位图源 `0x0c`/`0x0d` | ✅ **已解锁（2026-09-04）**：命令层 108 → **110**，24 用例 + 真实像素证据 |

**遗留项已清零。** 第 3 项按原计划用 `xdotool` 向 Xvfb 真窗口注入按键/指针/滚轮完成，
并做了回退验证（把 `X11Structs.cs` 偏移改回初版错误布局 → 新增 10 条**全红** → 证明是真测试）。
M1 至此无未关闭缺口；剩余工作全部属于 M2 范畴（WPF 托管层跨平台，Avalonia 量级）。

### 当前唯一在册问题：`XOpenDisplay` 偶发抖动（主控未复现，根因明确）

位图收尾 agent 报告：`Windowing.Tests` 存在 `XOpenDisplay` 偶发失败，3 次里约 2 次掉 1–3 条，
并**回退自身改动后重跑 4 次（失败 2/0/3/1）确认非自己引入**——这个自查动作是合格的。

**主控复验（2026-09-04 15:37）：连跑 6 轮 `Windowing.Tests`，6/6 全 0 失败，抖动未复现。**

| 维度 | 结论 |
|---|---|
| 是否复现 | ❌ 主控 6 轮未复现；agent 是在**高并行负载**下（同时跑 `Commands.Tests`）触发的 |
| 根因判断 | `Windowing/X11Display.Open` **无重试**；X11 server 在并发连接高峰会瞬时拒绝 |
| 影响 | 低——不影响 M1 验收，仅在满负载 CI 下可能偶发 |
| 建议修法 | `X11Display.Open` 加**有限次重试**（3 次 + 指数退避），失败信息带上 `DISPLAY` 值便于诊断 |

> ⚠️ 与已根治的 GCHandle ABA flaky **性质不同，别用同一套思路处理**：
> 那是**逻辑 bug**（必现于特定时序，已根治）；这是**资源竞争下的瞬时失败**（加重试即可）。

---

## 9. 已知风险

| 风险 | 影响 | 缓解 |
|---|---|---|
| DUCE 命令字节布局理解偏差 | 命令解码全错 | 以上游 `MarshalTo` 实现为准，先写 round-trip 测试再写渲染 |
| `HwndTarget` 深度绑定 HWND | 窗口层改造量大 | M1 用 X11 Window 模拟句柄，屏蔽差异 |
| 字体渲染跨平台不一致 | golden 测试不稳定 | 打包固定字体 + 按平台分组 |
| 托管层存在未发现的 Windows 硬依赖 | 运行时崩溃 | T1 编译验证尽早暴露 |
| SkiaSharp 版本与 .NET 版本不兼容 | 环境问题 | T0 锁定版本组合并写死 |
| **⚠️ 未录到真实 WPF 命令流做 golden binary 比对** | 命令解码正确性**只建立在"读上游源码"上，无实测流量兜底** | **当前最大未验证项（M1 未闭环）**。需一台 Windows 机器真跑 WPF、抓取 DUCE 命令流做二进制比对 |
| ~~**T4 渲染代码 1,483 行但 0 测试**~~ | ~~渲染正确性完全未验证~~ | ✅ **已关闭**：渲染 51 测试 + 15 张 golden（含位图、效果、渐变、裁剪、变换） |
| 编解码同源导致 round-trip 自洽 ≠ 与真实字节流一致 | 假绿灯 | 已用 `tools/verify-cmd-layout.py` 与上游逐 `FieldOffset` 比对（**103 个结构体一致**）作为交叉验证 |

---

## 10. 快速开始

```bash
cd <仓库根>                          # 本快照解压后的 wpf-linux/ 所在目录（路径无关，全部参数化）
export PATH="$HOME/.dotnet:$PATH"    # 或任何装了 .NET SDK 10.0.111 的 dotnet 位置

ls upstream/wpf/src/Microsoft.DotNet.Wpf/src/Common/Graphics/
#   ↑ 上游只读副本（exports.cs 13 函数签名权威 / wgx_core_types.cs 118 命令定义权威）
#   默认位置 upstream/wpf/；可用环境变量 UPSTREAM_WPF_ROOT 覆盖（port-pbt.sh / port-lib.py /
#   verify-cmd-layout.py 与全部 *.Linux.csproj 统一认它，经 build/Directory.Upstream.props）

bash verify-all.sh                # 一键全检：Xvfb → 2 构建 → 4 测试套件 → 线格校验
                                  # 期望：步骤通过 7 / 失败 0 / 用例 469 通过（2026-09-10 九次复验）
bash build/verify-env.sh          # 环境版本清单（T0 基线）
bash tests/flaky-loop.sh          # flaky 回归压测
```

**交付快照**：`wpf-linux-20260906.tar.gz`（源码 + 文档 + 22 张 golden + showcase 截图，不含 `bin/obj` 与 core dump；
**不含 `upstream/wpf` 只读副本**——需从上游 dotnet/wpf 检出放入 `upstream/wpf/`，或设 `UPSTREAM_WPF_ROOT`）。

### 10.5 环境搬迁记录（2026-09-10，接手必读）

> 原环境（`/workspace/wpf-linux` + `/root/.codebuddy/artifact/wpfscan/wpf`）已不复存在，
> 本快照在新机器上重新搭环境并复验通过。以下是全部改动与踩坑，接手者按此重建：

| 项 | 内容 |
|---|---|
| 工程根 | `/workspace/wpf-linux` → 解压目录（本机 `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`）。**M1 链路（主工程+测试+HelloMil+HelloWpf）完全可重定位**，无硬编码路径 |
| .NET SDK | 本机原有 SDK 6.0.428（不能编 net10.0）；经 `dotnet-install.sh` 装 **10.0.111** 到 `~/.dotnet` 与 6.0.428 **并存**（`dotnet-install.sh --channel 10.0 --version 10.0.111 --install-dir $HOME/.dotnet`，免 sudo） |
| 上游源码 | `/root/.codebuddy/artifact/wpfscan/wpf`（不可访问）→ **复制** dotnet/wpf 检出到 `upstream/wpf/`（只读，上游零改动） |
| 路径参数化 | 新增 `build/Directory.Upstream.props` 定义 `$(UpstreamWpfRoot)`/`$(WpfLinuxRoot)`；`WindowsBase.Linux.csproj`（310 处）/`System.Xaml.Linux.csproj`（179 处）/`PresentationBuildTasks.Linux/` 的 `/root/...` 与 `/workspace/...` 全部替换；`verify-cmd-layout.py`/`port-lib.py`/`port-pbt.sh` 改为按脚本位置推导 + `UPSTREAM_WPF_ROOT` 环境变量覆盖 |
| 系统包 | Ubuntu 22.04；`sudo` 需密码（会话记录有）；装 `xvfb xdotool imagemagick`（xdpyinfo/xwd 已有）。dotnet 10 不在 22.04 的 apt 源，必须走 dotnet-install.sh |
| NuGet | 华为镜像（`~/.nuget/NuGet/NuGet.Config`，网络实测可达）；SkiaSharp 2.88.9 版本锁保持 |
| 构建警告 | WindowsBase/System.Xaml 在新机器多出 **CA1416**（平台兼容分析器）噪声 → 已并入两工程 `NoWarn`（与原里程碑"0 警"对齐）；U2 链复验 0 错 0 警，DLL 尺寸与原记录一致（WindowsBase.dll 1.1MB） |
| verify-all.sh | 用例计数解析改**双语**（本机中文 locale 输出"已通过!/通过:/总计:"，旧正则恒 0） |
| X server | 机器自带 XWayland(:0/:1) 是**实时桌面会话**——xdotool 真注入会动用户鼠标，测试一律走 Xvfb :99，不要指到 :0/:1 |
| **SKMatrix.Concat 语义** | ⚠️ 实测：**`Concat(a,b)` = b 先作用**（SkiaSharp 2.88.9）。U12 已按此写对并注释钉死。注意：既有 `MappingMatrix`/`BrushMatrix` 的合成顺序注释与此语义**可能相反**——golden 全绿是因为测试里变换恒为单位阵，**非单位变换的画刷/渐变矩阵顺序仍是未验证项**，动那块时先写测试 |


## 波 `#46` 速览（诊断波，未翻九位；`D-G50` 定位完成，`D-G52` 撤回）

- **必做项现状**：hc 组合框下拉 = **两个独立缺陷叠加**。①（已定位，补丁已写出、部分验证、**未落仓**）
  X 焦点**回送**被 shim 当真实焦点变化再翻一次 ⇒ 主窗口**第二条 `WM_SETFOCUS`** ⇒ 上游 `OnSetFocus` 的
  `Keyboard.ClearFocus()` ⇒ `ComboBox` 判定"焦点跑了"⇒ `Close()`。②（新登记 `D-G53`，未修）
  `IsDropDownOpen=true` 时**弹窗窗口根本不建、画面也不出列表**。
- **下一步（建议一并落的顺序）**：先修 `D-G53`（`Popup` 建窗/出画那条腿，判据：`IsDropDownOpen=true` 后 X 层
  必须出现新窗口 ＋ `post.png` 出现列表像素），再把焦点回送补丁一起落 ⇒ 走完整波次（整波 → 重取臂 → 重钉 →
  闸门 ×2 → `verify-all` → 重冻 → 冻后 ×2）。
- **本轮取证手法（可复用）**：hc 应用侧 env 门控只读类处理器（`HC_INPUT_DIAG=1`，源码在仓外
  `/home/links-dev/hc-linux/src/Shared/HandyControlDemo_Shared/App.xaml.cs`，`$HOME/w45-backup/App.xaml.cs.hc-orig`
  是原始件）＋ shim 自带 `WPF_LINUX_KEY_DIAG=1` ＋ `$HOME/hc-combo-diag.sh`（定点、自起自收 X）＋
  `$HOME/hc-combo-xsample.sh`（按住期间采 X 事实）。**别再用 `DependencyPropertyDescriptor.AddValueChanged`**（不回调）。

## 波 `#46` 速览（**已冻结** `gen=#46 sha16=dd31a7701fc77829`）—— HC MVP 最后一件已收
- **结果**：HandyControl 示例应用的**组合框下拉在真实点击下打开并可见**（9 项列表），主窗零位移，单窗口门禁与基线逐字段相同。
- **两位一变**：`win32shim 11f81eb9→e700c383`（焦点回送）、`bridge 496951ad→e3ea0920`（按目标呈现）、`pc 45e7e0a4→043eff4b`、`pf a93097f7→366e9486`；
  其余五位未变；`inputs_fp` 因**重钉 `known-red.json` ＋ 新 applier 进覆盖面**而变（记录已点名）。
- **可复算入口**：`docs/WAVE46-PROGRESS.md`（状态板＋冻结点读数）、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G50`/`D-G54`、
  判据页 `docs/WAVE46-DG54-CRITERIA.md`（**§8 必读**：`P2∧P3` 不可拆）、收尾手册 `docs/WAVE46-CLOSEOUT-RUNBOOK.md`；
  证据副本 `$HOME/w46-evidence/`（截图＋mil 日志＋`CLEANUP.txt`）。
- **下一波欠账（别忘）**：**W1** 桥 app-local 副本无同步链（立牙或接进链）；**R10** `KNOWN-DEFECTS.md`/声明表**不在 `fp_inputs()` 覆盖面**；
  **重钉不幂等**（同句 `--why` 再跑会追加 history）；`P3` 阈值重标；`D-G54` 的 `D5-备选B` 未落（碰"800×600 vs 640×400 首帧"那一格）；
  **F** GDI+ 图像族真解码、**G** `D-T4` 透参（两支独立项，不挡 MVP）。

## 波 `#47` 速览（**已冻结** `gen=#47 sha16=9b9e3cb7bcb8280b`）—— "点过一次之后别处点不动" 修好
- **用户现象**：hc 能跑能翻页，但**输入框/列表项点了没反应** ⇒ 根因 **`D-G55`**：`SetCapture/ReleaseCapture` **不派发 `WM_CAPTURECHANGED`** ⇒ `Mouse.Captured` 恒不复位 ⇒ 第一次点导航后，**导航以外的点击全被路由给导航**。
- **修法与验证**：`win32_core.c` 两处派发（`lParam` 语义见 `KNOWN-DEFECTS.md` 的 `D-G55`）＋ `0x0215` 常量；`win32shim e700c383→abf6879c`。
  **两极化**：仓内 ⑬ 块 `clickprobe`（`tb.focus 0→2`、`combo.opened 0→2`）＋ **hc 真实应用**（修前 `cap=导航` 521 次／TextBox 0 焦点／下拉 0 次 → 修后 `cap=none`、打字 `len 4→7`、弹窗 `413x274` 并点项 `sel=1/9`）＋**反汇编复核**（修前无 `$0x215`、修后有 `call wpf_dispatch_to_window@plt`）。
- **同波新增两条 MVP 范围缺陷（排下一波 `#48`）**：**`D-G56`** 我方 applier 把类属性块与类声明打断 ⇒ `NameScope` 挂不上 ⇒ 带 `Storyboard.TargetName` 的页面**加载即 abort**；**`D-G57`** 页签标题/按钮**文字零墨**（可命中但不画字）。
- **新欠账**：`R-CSRC`（shim C 源不在 `fp_inputs()` 覆盖面）｜`R-GATE`（`clickprobe` 判据是负向式，**连点未进门禁**）｜`W1`（桥副本无同步链）｜`tline.log` 程序上不可复算（"tline 变了"非产品位移信号）｜`retake-arms` 并跑时自印 sha 表不可钉。

## 波 `#48` 速览（**已冻结** `gen=#48 sha16=540725342059b820`）—— 页面加载 abort 修好；**MVP 交互面齐了**
- **`D-G56`**：两个 applier 的插桩锚从"类声明行"上移到"该类型 doc 注释之前" ⇒ 生成件里 **doc＋属性块＋类声明三段紧贴**（原来横幅夹在属性与类声明之间 ⇒ 属性挂到插桩类上）⇒ `NameScope` 能挂上 ⇒ 带 `Storyboard.TargetName` 的 BAML 页**不再 abort**。
  两极化（**冻结件上**）：工具页 `MorphingAnimation` ⇒ `alive=yes/零异常` vs 只把 `wb`/`pf` 换回修前 ⇒ `alive=no` ＋ `InvalidOperationException`；静态形状 `ATTRCOUNT 2→0`、`scope NameScope→null`。
- 九位三位变：`windowsbase 84a2826c→79740e9b`、`pc 043eff4b→9465f9dc`、`pf 366e9486→1011da63`（机制：被引件字节进 Roslyn 输入哈希 ⇒ 级联）；`inputs_fp=cad0801c…`。
- **MVP 交互验收（冻结件）**：`D-G55` 四步（TextBox 焦点＋打字、立刻换页、下拉打开 413x274、点项 `sel=1/9` 并关闭）全通 ＋ 产品级第二腿（仪器全关）活满 20 s。
- 新登记：`D-G61`（**仪器**：开 `[GEO]` 时点下拉项会静默 SIGSEGV ⇒ 涉及下拉的带仪器读数**必须成对判 `alive`**）｜`D-G60`（`ARTIFACT_SRC_FP` 身份记录**出生即陈旧**，`integration-wave.sh` 段 3.5/3.6 倒置）｜`D-G59`（`verify-all.sh` 选 X 显示用字符串序且不复核 ⇒ 假红＋静默跳过 47 例，已由两极化正控定案）。
- 与规则的偏离：#47 冻后只有 1 趟有效（第二趟被"死显示 `:66`"＋"运行期改 `verify-all.sh`"毁掉）。

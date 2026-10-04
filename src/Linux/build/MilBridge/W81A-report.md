# W81A · `TASK-0106`（`PMaxSize` 声明态端到端腿）＋ `TASK-0303` 的 `A0`（最小闭包实测）

> 车道 `W81A`｜波 `#50`（`#49` 已冻结，基线 `f1d340d66c7c6ba3`）｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> 全程：**零产品改动**（未碰 `build/shims/**`、`build/PresentationCore.Linux/**`、`src/**` 任何产品源）｜
> 未碰四个路由件与 `defect-registry-declared.tsv`（mtime 证据见 §3.4）｜未跑 `integration-wave.sh`/`close-wave.sh`/`verify-all.sh`｜无 `pkill -f`｜
> 所有 sha 一律现场 `sha256sum | cut -c1-16`（无手抄）。
> ⚠️ 本件是**判据先落纸**的那一版：§0 在**取任何读数之前**写成（`18:33:44`，先于第一次运行 `18:35`），
> 后文凡**改了判据**的地方都在原地逐字记「原判据 → 更正后的判据 → 为什么」（两处：§0.1 单位、§0.2 A0-P2）。

---

## §0 判据（**先写进报告，读数后取**）

### 0.1 `TASK-0106`：声明上限 ⇒ `WM_NORMAL_HINTS` 里 `PMaxSize` 出现且等于声明值

| 项 | 内容 |
|---|---|
| 被测件 | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（`win32shim` 位） |
| 装置 | 新建仓内最小探针 `build/MilBridge/tests/W81AWindowProbe/`（**一个二进制、一个进程、五个窗口**） |
| 观测面 | **X 服务器自己的属性**（`xprop -id <xid> WM_NORMAL_HINTS`）—— 不是我方日志、不是我方变量 |
| 窗口 id 来源 | 应用自己印 `WindowInteropHelper.Handle`（本移植里 `HWND == XID`）⇒ 不靠 `xdotool` 猜窗口 |
| 正极性（P1） | 声明 `MaxWidth=640, MaxHeight=480`（**DIP**）的窗口 ⇒ `WM_NORMAL_HINTS` 里**必须**出现 `maximum size`，且等于 **`LogicalToDeviceUnits(声明值)`** |
| 反极性（N1） | 同一二进制、同一进程、同一显示器上**不声明** `MaxWidth/MaxHeight` 的窗口 ⇒ 同一属性里 `maximum size` **必须缺席** |
| 第三态（R58） | 若出现的是**屏幕/工作区尺寸**（`1280 by 1024`）⇒ 点名 `reg58_wave-defect-shape=yes`：那是**波 58 已登记过的错法**（拿钳制上限顶替），**不是绿**、也不是"没发" |
| 三态 | `W81A_PMAX=PASS`／`FAIL`／`NOINFO`（`WM_NORMAL_HINTS` 本身不在、或**装置判别力自证**不过 ⇒ `NOINFO`：**不许当绿、也不许当红**） |
| 为什么两极化必须在**同一进程**里 | 「声明/不声明」是本腿的**唯一自变量**；分成两个进程就多出"环境不同"这个替代解释 |
| **判据更正（**第 1 趟读数之后**才发现；逐字记，不冒充"先见之明"）** | 原文写的是"等于声明值"（即 `640 by 480`）。**更正为** `LogicalToDeviceUnits(声明值)`：上游写回那一句是 `Window.cs:4892-4900` 的 `LogicalToDeviceUnits(...)`，而 `WM_NORMAL_HINTS` 是**像素**、`MaxWidth` 是 **DIP**。本机工具包自报 `dpi=1.041667`（`VisualTreeHelper.GetDpi`，探针现场读）⇒ 期望 `667 by 500`。**若照原判据判**，即使修好了也会被读成 FAIL（**假红**）⇒ 必须改。**换算比例不在装置里写死**，由探针现场印出来。 |

⚠️ **为什么 N1/R58 不是"可省的一步"**：本仓登记的 `D-G70` 同族风险就是"把失败做成静默半通"。若 `PMaxSize` 是**无条件**发出的（例如拿钳制值顶替），P1 照样可能绿而语义是错的 ⇒ **只有 N1 与 R58 能证伪它**。

### 0.2 `TASK-0303` 的 `A0`：最小闭包的**需求序列从静态推断变实测**

| 项 | 内容 |
|---|---|
| 要回答 | 一个**最小 `FlowDocument` 页面**真跑时，**实际**按名字要过哪些 PTS/LS 导出、**顺序**如何、终止在哪 |
| 真值来源 | **`ld.so` 自己的符号查找日志**（`LD_DEBUG=symbols` + `LD_DEBUG_OUTPUT`）—— 由加载器写、不经过我们任何代码 ⇒ 不可撒谎（装置 = 仓内**已存在**的 `build/MilBridge/tools/t1b-ls-tripwire.sh`） |
| 对照面 | `build/MilBridge/W78A-report.md`（`0dbc62b1d1cf86ee`）§2.2 的 **27 条入口**静态闭包清单（**逐字**抄进分析器，不靠记忆） |
| A0-P1（设备有判别力） | 绊线 `--selftest` 必须 `PASS`（它成对断言"已知存在"符号 `FOUND` ∧ "已知缺失"符号 `MISS`，并与 `nm -D` 交叉核对一致） |
| A0-P2（被测路径真走到） | `step=flowdoc-shown` 在场。**判据更正**：那一句标记写在 `w.Show()` **返回之后**，而本轮异常正是**从 `Show()` 里抛出的** ⇒ 它永远不会打印。**改成两条独立证据之一**：① 原档；② `step=flowdoc-host-built` 在场 **∧** 异常文本点名 **PTS 上下文族入口**（`CreateInstalledObjectsInfo｜GetFloaterHandlerInfo｜GetTableObjHandlerInfo｜CreateDocContext`）。**这不是放宽**：②证明文档与宿主都建好了、且缺的符号恰是 PTS 族入口 ⇒ 需求来自**文档布局**这条链。 |
| A0-P3（读数形状） | 逐条给：`符号`｜`被查找行数`｜`FOUND/MISS`｜**查找链**｜**日志先后**；并与 27 条逐条对表 |
| 三态 | `W81A_A0=MEASURED`（拿到序列）／`NOINFO`（设备自证不过、或没走到 flowdoc、或找不到 ld 日志）—— **A0 不是绿/红，是"有没有量到"** |
| 先写下的预期（**好被推翻**） | 进程会死在**第一条**缺符号上（`EntryPointNotFoundException` ⇒ `Invariant.Assert` ⇒ `Environment.FailFast`，`rc=134`）⇒ 量到的是需求序列的**严格前缀**。**若实测能走到第二条及以后**，说明我这条预期错了，必须点名 |

---

## §1 `TASK-0106`：判定点 ／ 装置 ／ 两极化读数

### 1.1 判定点（一次运行，五窗，全部同一进程）

| 角色 | 声明什么 | 参与判定？ |
|---|---|---|
| `declared` | `MaxWidth=640, MaxHeight=480`（`Show()` **之前**设） | ✅ P1 |
| `undeclared` | 两个 DP 都不设（保持默认） | ✅ N1 |
| `late` | `Show()` **之后**才设 `MaxWidth/MaxHeight` | 诊断（不判） |
| `sizecontent` | `Max*` ＋ `SizeToContent` ＋ 2000×1500 的内容 | 诊断：用**布局结果**证 `MaxWidth` 是**活的 DP** |
| `minonly` | `MinWidth=500, MinHeight=400` | 诊断：把结论从"上限那一半"推广到**整条 `WM_GETMINMAXINFO` 通道** |

### 1.2 装置（两个部件，都零世代位）

1. **探针**：`build/MilBridge/tests/W81AWindowProbe/`（`W81AWindowProbe.csproj` / `Program.cs`）—— `dotnet build -c Release` 一次，一个进程内建五个窗口，各自印 `xid` ＋ DP 回读 ＋ `VisualTreeHelper.GetDpi`。
2. **装置判别力自证** `xprobe-hints.c`：一个**与 WPF/shim 完全无关**的裸 X 客户端（`XSetWMNormalHints`），成对两种模式（`PMinSize|PMaxSize` vs 只 `PMinSize`）。
   **为什么必须有**：本腿的正极性**不成立**（声明了也没出现 `PMaxSize`）⇒ 这时"没出现"有两种解释分不开：(a) 被测件没把值送出去；(b) **我的读法**（`xprop` 格式/我的 grep）看不见那个值。**只读判据必须能自证"看得见"。**

```
W81A_PMAX_DEVICE_ARM mode=max   xid=0x200001 max='program specified maximum size: 640 by 480'
W81A_PMAX_DEVICE_ARM mode=nomin xid=0x400001 max='<缺席>'
W81A_PMAX_DEVICE=PASS（装置成对：设了 PMaxSize 的窗读得到、没设的读不到）
```
⇒ 装置**有判别力**；下面"未见 `PMaxSize`"是**真的没发**，不是我读不出来。

### 1.3 两极化读数（读数原文，`$HOME/w81a/out/pmax/`）

`xprop -id <xid> WM_NORMAL_HINTS` 的**逐窗原文**：

| 角色 | `xprop` 原文 | 判定 |
|---|---|---|
| `declared`（dp=`640x480`） | `WM_NORMAL_HINTS(WM_SIZE_HINTS):` ＋ `program specified minimum size: 1 by 1` | **无 maximum size** |
| `undeclared`（dp=`InfinityxInfinity`） | 同上（逐字节相同） | 无 maximum size |
| `late`（dp=`640x480`） | 同上 | 无 maximum size |
| `sizecontent`（dp=`640x480`，`actual=640x480`） | 同上（`geom=667x501`） | 无 maximum size |
| `minonly`（dpmin=`500x400`，`actual=500.16x400.32`） | 同上（`geom=521x417`） | **min 也停在 1 by 1** |

```
W81A_PMAX_UNITS dpi=1.041667（探针现场读的 VisualTreeHelper.GetDpi）⇒ 期望 PMaxSize=667x500（= 声明 640x480 DIP × 该比例）
W81A_PMAX_READ declared{prop=1 max='<缺席>'} undeclared{prop=1 max='<缺席>'} device=PASS
W81A_PMAX=FAIL P1=no(声明 640x480 DIP ⇒ 期望 '667 by 500'，实得 '<缺席>') N1=yes(未声明实得 '<缺席>') reg58_wave-defect-shape=no
```

**结论（给主控的两句话）**
1. **P1 不成立**：应用声明了 `MaxWidth/MaxHeight`，`WM_NORMAL_HINTS` 里**没有** `maximum size`。五个窗口的最终版本跑了 **2 趟**（`18:41` 与 `18:44` 的 `FINAL-run.log`），逐窗读数**逐字相同**；更早的两窗/四窗版本（`18:35`、`18:37`、`18:39`）读到的也都是"未发"。
2. **而且不是"只坏上限那一半"**：`minonly` 臂声明了 `MinWidth/MinHeight`，X 提示里**照样是 `1 by 1`** ⇒ **整条 `WM_GETMINMAXINFO → WM_NORMAL_HINTS` 通道对"应用声明的值"是失效的**（上下限都到不了 X）。
3. **反极性 N1 "yes" 在 P1 不成立时是弱证据**（都缺席，分不出"正确缺席"与"全都缺席"）——所以 1.2 的**装置自证**才是这一格的分量所在：它证明"缺席"是我看得见的缺席。

### 1.4 机制（三处证据互印，file:line）

| # | 证据 | 读数 |
|---|---|---|
| ① | shim 自己的诊断（`WPF_LINUX_CREATE_DIAG=1`） | **9 次** `WM_GETMINMAXINFO` 派发，**9 次**都是 `窗口过程回填 min=1x1 max=1280x1024 ⇒ 应用**没有**声明上限 ⇒ X 提示 min=1x1 PMaxSize=**未发**`；**0 次**"有声明上限" |
| ② | X 侧属性 | 五窗**全部**只有 `program specified minimum size: 1 by 1` |
| ③ | 工具包自报 | `declared` 的 `dp=640x480`（DP 真是我设的值）；`sizecontent` 的 `actual=640x480`（**布局真的被 `MaxWidth` 钳住了**，内容 2000×1500）；`minonly` 的 `actual=500.16x400.32`（下限也真的生效了） |

⇒ **工具包侧是好的（DP 活着、布局照做），坏的只有"把值送去 X"这一步。** 静态链条（**读数支持、非猜测**）：

- `src/WpfGfx.Linux.Native/src/win32_core.c:809-840`：全仓**唯一**一次 `WM_GETMINMAXINFO` 派发，发生在 `CreateWindowEx` 内、`XMapWindow` **之前**；`fill_minmaxinfo_defaults()`（`:676-702`）先按"屏幕尺寸"填默认值，再让窗口过程回填，然后把结果交给 `wpf_x11_apply_wm_hints()`（`:1613-1660`，**唯一调用点就是这里**）。
- 上游 `upstream/.../PresentationFramework/System/Windows/Window.cs:4243-4246` 逐字写着：
  > *"we need to process WM_GETMINMAXINFO before `_swh` is assigned … WmGetMinMaxInfo can handle `_swh == null` case."*
  ⇒ **建窗那一刻 `_swh` 还没赋值**，而 `WmGetMinMaxInfo` 的写回块在 `:4885` 被 `if (!IsSourceWindowNull && !IsCompositionTargetInvalid)` **挡住**；被挡掉的正是 `LogicalToDeviceUnits(...)` 那几行写回（`:4892-4900`）。**它只缓存不写回**（缓存那三行在 `:4877-4881`，在守卫**之前**）。
- ⇒ 于是 `app_declared` 恒为假（回填 == 默认），`PMaxSize` 永远不发；而 shim **再也没有第二次问**（全仓 `WM_GETMINMAXINFO` 派发点就那 9 行）。
- **③ 证明的是「这两个 DP 在布局里是活的」**：`sizecontent` 的内容 2000×1500 被钳到 640×480、`minonly` 被撑到 500×400 ⇒ `MaxWidth/MinWidth` 确实参与了布局（⇒ 排除"我给窗口设了个没人读的值"这个替代解释）。
  ⚠️ **「消息到了 WPF、缓存跑了、只是被守卫挡在写回之前」这一步我只有间接支持**（`GetWindowMinMax()` 取 `Math.Min(MaxWidth, _trackMaxWidthDeviceUnits)`，而布局确实钳在 640 而不是 0 ⇒ 缓存里那个数 ≥ 640）——**这条推断没有独立读数**（窗口的私有字段读不到）⇒ 按口径记进 §5 的 `NOINFO`，**不许**当已证事实引用。
  **直接读数只有一条，但它是硬的**：窗口过程**回填后的值 == 我们填进去的默认值**（9/9 次）⇒ **应用没有改写它**。

> **口径说明**：`window.Width` 回读成 `640.32`（`sizecontent`）是同一个 DPI 比例的下游（667 px ÷ 1.041667），不是另一个缺陷。

### 1.5 修法假设 ＋ **可证伪实验**（本件不落地，只给方子）

| 假设 | 做法 | 预测（**能被证伪**） |
|---|---|---|
| **H1（推荐先试）** | shim 在窗口**首次 map 之后**（此时 `_swh` 已赋值）**再派发一次** `WM_GETMINMAXINFO`，并用回填结果**重发** `wpf_x11_apply_wm_hints()` | `declared` 出现 `maximum size: 667 by 500`；`undeclared` 仍**缺席**；`minonly` 出现 `minimum size: 521 by 417`；`late` 也出现（它在 Show 后才设，若只在 map 时问一次则仍缺席 ⇒ 这一格能区分"只问一次"与"跟着 DP 变化重问"） |
| **H2（更贴 Windows）** | 不只 map 时问：在"WPF 报告 min/max 变化"的路径上（`SetWindowPos`/尺寸请求）都重问重发 | 同 H1 ＋ 运行期改 `MaxWidth` 后 X 提示跟着变 |
| **H3（反向假设，用来证伪 H1/H2 的因果）** | 若按 H1 改了之后 `declared` **仍然**没有 `maximum size` ⇒ "守卫挡住了写回"这条因果**是错的**，真因在别处（例：这条消息此后再也没有路由到 `Window` 的消息过滤器） | 必须如实改判，不许把"我改了却没动"读成"环境问题" |

⚠️ **本仓最忌讳的失败形态（判据已备牙）**：修成"**静默半通**"——例如把 `max_w/max_h` 在 `app_declared=0` 时用**钳制值/屏幕尺寸**顶上去，让 `xprop` 里出现一个"看着像有约束"的数。**R58 那一格就是为它准备的**（出现 `1280 by 1024` ⇒ 点名，不是绿）。

### 1.6 `TASK-0106` 的 `NOINFO`（既不算绿也不算红）

1. **没有 WM**：本轮显示器是裸 `Xvfb`（无 EWMH WM）⇒ 本腿只判"X 提示里有没有那个值"，**不判**窗口管理器是否真的照 `PMaxSize` 约束用户拖拽。要在 EWMH 下判"约束真的生效"，需要另一套装置（本件不做）。
2. **`late` 臂分不出两种解释**：它同时兼容"shim 只问一次"与"WPF 即便被问也不写回"。要分开必须落地 H1（产品改动）。
3. **用户拖拽/`xdotool windowsize` 路径未测**：与 1 同因（无 WM）。
4. **DPI ≠ 100 的机器未测**：本轮 `dpi=1.041667`。若某环境 `dpi=1.0`，期望值回到 `640x480` —— 判据已按"现场读比例"写，但我没在第二种比例上取过读数。

---

## §2 `TASK-0303` 的 `A0`：最小 `FlowDocument` 页面的**实测需求序列**

### 2.1 装置（**零世代位、零产品改动**）

```
bash build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg a0
  → t1b-ls-tripwire.sh --selftest                      # A0-P1 设备自证
  → t1b-ls-tripwire.sh <out> -- timeout 150 dotnet W81AWindowProbe.dll --mode=flowdoc --hold=6
  → w81a-a0-analyze.py <LD_DEBUG_OUTPUT 目录> <out>     # 顺序 ＋ FOUND/MISS ＋ 27 条对表
```
- 被测应用：`--mode=flowdoc` = `Window` → `RichTextBox` → `FlowDocument` → `Paragraph` → `Run`（与上游 `RichTextBoxDemo` 同形）。
- 真值：`/dev/shm/w81a-lddebug/ld.<pid>`（每进程一份）；本趟选中 **`ld.796321`（35628 行）**，判据 = "这一份里**真的按名字找过 shim 的符号**"（`shim_lookups=274`）。
- 产物已拷到耐久位置：`$HOME/w81a/out/a0/ld-app.log`。

### 2.2 读数

**A0-P1 设备自证**：`ST_ATTEST=PASS`（`sha16 82f6a05afb1f9db9`，自测期间本件未变）＋ `装置自证 通过（捕获到的查找与 nm -D 事实一致）` ⇒ 装置成对能看见 `FOUND` 与 `MISS`。

**A0-P2**：`W81A_A0_P2=yes（再表述档：宿主已建 ＋ 缺的符号 = PTS 上下文族入口 ⇒ 需求来自 FlowDocument 布局）`。

**进程怎么死的**（原文）：

```
W81A_PROBE step=flowdoc-doc-built
W81A_PROBE step=flowdoc-host-built
W81A_PROBE=EXC where=main type=System.EntryPointNotFoundException
    msg=Unable to find an entry point named 'CreateInstalledObjectsInfo' in shared library 'PresentationNative_cor3.dll'.
（stderr）Process terminated. … at MS.Internal.Invariant.FailFast(String) … at MS.Internal.Invariant.Assert(Boolean)
W81A_A0_RUN rc=134
```
⇒ **异常从 `w.Show()` 里抛出**（`step=flowdoc-shown` 从未打印），随后 `Invariant.Assert` ⇒ `FailFast` ⇒ `rc=134`。
**这条实测与 `D-G70` 的现场逐字同形**，且把 W78A §2.1 的**第一跳**从静态推断变成实测。

**家族符号（按日志先后；家族 = `Fs*｜Lo*｜Ls*｜Nl*` ∪ 27 条清单）**

| # | 符号 | 查找行数 | 判定 | 首次行 | 备注 |
|---|---|---|---|---|---|
| 1 | `LoadCursor` | 1 | FOUND | 31632 | 链首=shim（Win32 名，被 `^Lo` 前缀顺带匹配） |
| 2 | `LoadCursorA` | 9 | **CONFLICT** | 31633 | ⚠️ 见 §2.4 仪器发现②：`nm -D` 说 shim **定义了**它，而链有 9 行且**末行才是 shim** |
| 3 | `LsDisableSpecialCharacterLigature` | 1 | FOUND | 31722 | 链首=shim |
| 4 | **`CreateInstalledObjectsInfo`** | **9** | **MISS** | **35044** | 链首=shim，翻遍 9 个库；紧随其后就是 ld.so 自己写的 fatal 行（见下） |

**ld.so 自己的结论（不是我推断的）**：`a0/ld-app.log:35053`
```
/home/links-dev/…/src/WpfGfx.Linux.Native/bin/libwpfwin32.so: error: symbol lookup error: undefined symbol: CreateInstalledObjectsInfo (fatal)
```
⚠️ 这一行的 `(fatal)` 语义必须在报告里说清（见 §2.4 ③）：它表示**这次符号查找失败**，不表示进程在那一行死了（同一份日志里另有 `DllMain`/`PAL_RegisterModule`/`u_strlen`/`ucol_clone_70` 四行同样带 `(fatal)`，而进程照样往下跑）。**判定这个符号致命的依据是另外两条**：异常文本点名同一个符号＋同一个库，且 `rc=134`。

**只依赖"链首 = shim"这一类（= 真正冲 shim 去的需求）**：
```
LoadCursor                                   n=1    FOUND
LsDisableSpecialCharacterLigature            n=1    FOUND
CreateInstalledObjectsInfo                   n=9    **缺**
⇒ 家族里冲着 shim 去的共 3 条，其中**缺** 1 条：CreateInstalledObjectsInfo
```

### 2.3 与 `W78A-report.md` §2.2 的 **27 条**静态闭包对表

```
W81A_A0=MEASURED family_symbols=4 closure_hit=1 closure_found=0 closure_missing=1
                 closure_notseen=26 first_miss=CreateInstalledObjectsInfo app_log=ld.796321
```

| 组 | 27 条里的实测情况 |
|---|---|
| A 上下文创建期（6 条） | **只命中第 1 条** `CreateInstalledObjectsInfo`（MISS）；`GetFloaterHandlerInfo`／`GetTableObjHandlerInfo`／`CreateDocContext`／`DestroyInstalledObjectsInfo`／`DestroyDocContext` **一次都没被要求过** |
| B 构造期 LS 罚分模块（5 条） | **全部未出现**（`LoCreateContext` 等连一次查找都没有） |
| C 页/节/道/子道（7 条） | 全部未出现 |
| D 文本段→行（7 条） | 全部未出现 |
| E 拆卸（2 条） | 全部未出现 |

**A0 的答案（三条，逐条可复算）**
1. **实测命中的是 1/27**，而且就是**第一条**（顺序 = 它，唯一）。W78A §2.1 的"第一跳 = `CreateInstalledObjectsInfo`"**实测成立**。
2. **顺序问题在本移植里只能答一格**：进程死在第一条缺符号上 ⇒ 27 条里其余 **26 条"未被要求过"是"还没轮到"，不是"不需要"**。（本件**不用**这个读数去论证任何"最小闭包变小"的结论。）
3. 要让序列**继续往下走**，必须先做 W78A §3.1 的 **`A1`**（把那 6 个入口**导出但如实失败**，`A2` 拆毒池项）——**那是产品改动，不在本件射程**（本件零产品改动）。

### 2.4 顺带量到的两条**仪器**发现（对 `A0` 本身有害，必须点名）

| # | 发现 | 证据 | 后果 / 建议 |
|---|---|---|---|
| ① | **绊线自带的家族过滤器看不见这一族**：`t1b-ls-tripwire.sh:41` 用 `grep -E '^(Lo\|Ls\|Nl\|Fs)[A-Za-z]'`，而**致命的那个符号 `CreateInstalledObjectsInfo` 不以这四个前缀开头** ⇒ 装置自证 `PASS` 的同时，对**真正要命的那一条**报"0 次查找" | 本趟 `ls-tripwire.txt` 的家族表只有 `9 LoadCursorA / 1 LsDisableSpecialCharacterLigature / 1 LoadCursor`；而原始日志里 `CreateInstalledObjectsInfo` 有 9 行 | 若主控要用这个装置做 `A0`，**必须先放宽过滤器**（本车道的分析器已按「27 条清单 ∪ 前缀」实现，可借用；也顺带说明该过滤器有**假阳性**：`LoadCursorA` 被 `^Lo` 匹配） |
| ② | **「查找行数 ≥ 6 ⇒ MISS」这条规则不成立**（`t1b-ls-tripwire.sh:44` 的自述判据） | **反例就在本趟日志里**：`LoadCursorA` 有 **9 行**链，而**末行正是 shim**，且 `nm -D --defined-only libwpfwin32.so` 打出 `0000000000013380 T LoadCursorA` ⇒ 它**被找到了**（链首是 `dotnet` 而不是 shim ⇒ 这是**全局作用域**查找，shim 排在作用域末位） | 判据必须用**导出成员关系**（`nm -D`）而不是行数；绊线对它那 5 个关键符号**恰好**做了 nm 交叉核对（所以那 5 格仍可信），但"行数"作为一般规则会给出**假 MISS**。本车道的分析器一律以 `nm -D` 判，行数只作旁证 |
| ③ | **`ld.so` 日志里的 `(fatal)` ≠ 进程致命** | 同一份日志里 5 处 `undefined symbol … (fatal)`（`DllMain`／`PAL_RegisterModule`／`DllMain`／`u_strlen`／`ucol_clone_70`）而进程继续跑；真正的致命判定来自**异常文本＋rc** | 写进复现说明，免得后人拿 `(fatal)` 当"进程死因" |

---

## §3 本批动了哪些件 ／ 会动哪些世代位

### 3.1 新增（本车道的写面，全部为"新增"）

| 件 | sha16 | 说明 |
|---|---|---|
| `build/MilBridge/tests/W81AWindowProbe/W81AWindowProbe.csproj` | `cc2b08ed2cd6b02e` | 探针工程（`EnableDefaultCompileItems=false` ＋ 逐条 `<Compile Include>`；`AssemblyName=W81AWindowProbe`） |
| `build/MilBridge/tests/W81AWindowProbe/Program.cs` | `9f26cdb085e90084` | 两条腿的探针（`pmax-pair` 五窗 / `flowdoc` 最小页面），只印机读读数 |
| `build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh` | `5691050c5c67cf1d` | 装置（起 Xvfb 记 PID 收尾；**每条重活各自入 `~/heavy-slot.sh` 槽**；判定与三态） |
| `build/MilBridge/tests/W81AWindowProbe/w81a-a0-analyze.py` | `a226d40e92dbe28b` | `A0` 分析器（顺序／`nm -D` 判定／27 条对表） |
| `build/MilBridge/tests/W81AWindowProbe/xprobe-hints.c` | `924b138b8645a637` | **装置判别力自证**（裸 X 客户端，与 WPF/shim 无关） |
| `build/MilBridge/W81A-report.md` | 见 §7（自指件） | 本报告 |
| 构建产物（`bin/`、`obj/`，**非源**） | `bin/Release/W81AWindowProbe.dll` ＝ `3ff0a34d06638c24` | 不进任何门禁 |

### 3.2 ⚠️ 改了一件**仓内既有件**（**被迫**，一行）：`build/MilBridge/tools/build-hygiene-roster.tsv`

- `1a6de1ecd3665f12` → **`49f0d45c1b122f5f`**（新增 **1 行**，`notneeded` ＋ 见证 `no-compile-glob`，与 `#42` 的 `TabGapProbe` 同款）。
- **为什么非改不可**：该册的判据第 ⑤ 档要求"全树每一份候选 csproj **都必须表态**"，新工程不表态 ⇒ `FAIL kind=UNDECLARED`（`verify-all` 第 `[9]` 步 `BUILD-HYGIENE`）。
- **它动不了什么**：`EXPECT_N` 只数 `wired` 节（本次 `wired` **一条未加**，仍 41）⇒ 生产路径 `list=41 == expect_n=41`。现场读数：
```
BHYGIENE_ROSTER_N=87  BHYGIENE_ROSTER_CLASSES=wired=41 notneeded=28 suspended=18
BHYGIENE_CAND_N=87    BHYGIENE_COVERAGE=OK n=22 sln_projects=8 corpus=144 build_lines=34 build_bases=16
BHYGIENE_IMPORT=PASS reason=ok files=41 lines=41 list=41 … undeclared=0 witness_expired=0 class_conflict=0 cand=87 cand_min=86 notneeded=28 suspended=18 roster=49f0d45c1b122f5f   （rc=0）
```
> ⚠️ 复算提示：该行里的 `corpus=` **会随本车道后来新增的两个装置脚本（`run-w81a-legs.sh`、`w81a-a0-analyze.py`）变大** —— `18:34` 那趟是 `corpus=144`，收尾复算是 `corpus=146`；`BHYGIENE_IMPORT=PASS` 与 `cand=87 cand_min=86` 两趟相同。（`build_bases=16` 两趟也相同：装置脚本里那条构建命令行写的是 `"$PROJ"` 而不是字面 `.csproj` ⇒ 本探针**不进**构建覆盖面闭包 —— 这与 `witness_expired=0` 互为印证。）
- 🟡 **留一条欠账给主控（我刻意没做）**：候选数 86 → 87，而 `build-hygiene-import-check.sh` 的 `CAND_MIN=86` **本趟未改**。生产路径只断言 `≥`（照旧 `PASS`），**只有 `--selftest` 的常量漂移守卫会红**：
```
BHYGIENE_SELFTEST=FAIL kind=CONSTANT-DRIFT what=CAND_MIN decl=86 live=87（**声明常量与现树对不上 ⇒ 别信本趟自测**）
BHYGIENE_SELFTEST_COUNTS_ERROR self_derived=yes roster_rows=87 wired_live=41 expect_n=41 cand_live=87 cand_min=86 drift=1   （rc=1）
```
  **为什么不顺手改**：`build-hygiene-import-check.sh` **在 `close-wave.sh:fp_inputs()` 的覆盖面里**（点名成员）⇒ 改它 = **动 `inputs_fp`**。本波 `#49` 已冻结、`inputs_fp` 是**世代输入**，车道不该在冻后擅动；这一行改动（`CAND_MIN=86→87`）请主控在自己的趟里与 `--why` 记账同趟落（`#31`/`W31A` 的注释也把这一步点名为"最容易漏的一步"）。

### 3.3 世代位：**九位逐位对账（相对 `#49` 冻结块）**

| 位 | 冻结值（`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 的 `RE-FROZEN #49` 块） | 现场（本轮） | 结论 |
|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | `feef049e9d0e313a` | ✅ 未变 |
| `pc` | `56ee75ced8d6aece` | `56ee75ced8d6aece` | ✅ 未变 |
| `pf` | `6375fabf89ac7fef` | `6375fabf89ac7fef` | ✅ 未变 |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | ✅ 未变 |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | ✅ 未变 |
| `win32shim` | `c493639d15678803` | `c493639d15678803` | ✅ 未变（**本腿的被测件两趟一致**） |
| `wic_shim` | `56278c14b4ecd672` | **`f7b3026c8c019be2`** | ⚠️ **变了，但不是本车道**（见下） |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | ✅ 未变 |
| `dwf` | `de2d555105b7d04b` | `de2d555105b7d04b` | ✅ 未变 |

- `wic_shim` 位移的**归因证据**：`build/DirectWrite.Linux/wic-shim/libwpfwic.so` mtime = `18:32:55`，同目录 `frames-probe.c` = `18:32:11` —— **都早于本车道第一次落盘**（`W81A-report.md` `18:33:44`），且本车道**从未**对 `build/DirectWrite.Linux/**` 执行任何写操作。方向指向**并行车道（GIF ⇒ WIC 帧探针）**，请主控按自己的车道账本核。
- `BRIDGE_SRC_FP` = **`0a8f69b3c5fabd43`**（`--list` 现算 78 件），与冻结块 ＋ 发布记录 `bridge-src-fp.txt` **两侧同值** ⇒ 桥源零位移。

### 3.4 `inputs_fp`：**不可能变**（用集合成员关系证明，不重算摘要）

- 覆盖面**现算 = 143 件**（谓词**逐字**取自 `build/close-wave.sh:104-125,200-215`，与冻结块自述的"覆盖面 143 件"一致）。
- `grep -nE "W81AWindowProbe|build-hygiene-roster|W81A-report" <143 件清单>` ⇒ **0 命中**。
- ⇒ 本车道**改/加的每一件都不在覆盖面里** ⇒ `inputs_fp` 是**成员 sha 的摘要**，成员一件未动 ⇒ **摘要不可能变**（不是"我算过一遍"，是"不可能"）。冻结值 `9f2199b212bed2b212035f87ff6006672605ff7bea6221c0be540301b1a8380b` 应保持有效。

### 3.5 `APPSYNC`（app-local 副本一致性）：**改前 == 改后**（新探针的副本零新增漂移）

```
改前（18:34，本车道尚未构建任何探针）：APPSYNC=MISMATCH（MISMATCH=5[STALE=5 NEWER-DIFF=0] MISSING=0 UNEXPECTED=6[DECL-GAP-EQ=5 DECL-GAP-DIFF=1] DIVERGENT=1 RETIRED=0 AUTH-MISSING=0 BRIDGE-ANCHOR=0 BRIDGE-NOINFO=0）
改后（19:0x，探针已构建、五个窗口跑过两趟）：逐字相同
```
⇒ 探针 `bin/Release` 里的 `PresentationCore/PresentationFramework/WindowsBase/Provider` 副本与权威件**同 sha**（探针自报的 `W81A_APPLOCAL` 四行现场读数：`56ee75ced8d6aece` / `6375fabf89ac7fef` / `2e4e46e539a72cd7` / `1f9511a7ef395bfe`）⇒ 没有把"旧代副本"这种假读数带进来。**该件本来就是"在册的红"（告警不是硬闸），本件一格未加。**

### 3.6 路由件与登记表：**未触碰**（mtime 证据，不用自称）

| 路由件 | 现场 mtime | 本车道首次落盘（18:33:44）之前？ |
|---|---|---|
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `2026-09-21 17:43:14` | ✅ 之前 ⇒ 非本车道 |
| `docs/CURRENT-STATE.md` | `2026-09-21 17:43:14` | ✅ 之前 ⇒ 非本车道 |
| `handoff.md` | `2026-09-20 01:05:33` | ✅ 之前 ⇒ 非本车道 |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | `2026-09-21 18:35:54` | ⚠️ **在本车道作业窗口内** —— 但**不是本车道**：本车道从未对它执行写操作；它与 `defect-registry-declared.tsv` **同一秒**（`18:35:54`）成对变更 = 一次**登记表操作**，且该文件里最新一条提及的是**车道 W79A**（`build/MilBridge/W79A-report.md`）的发现 ⇒ 归因为**主控/并行车道的登记动作**。本车道与它们的**首次接触是 `18:43` 的 `ls`（只读）**。 |
| `build/MilBridge/tools/defect-registry-declared.tsv` | `2026-09-21 18:35:54` | 同上 |

---

## §4 内存三值与纪律自证

| 项 | 读数 |
|---|---|
| 内存（作业期间观测） | `MemAvailable` 2886 → 2771 → 2894 MB（**最低 2771 MB**）；`HEAVYSLOT=MEMOK avail=…min_avail=1500` 每次进槽都打；**无** `HEAVYSLOT=NOINFO reason=low-memory`、**无** `MAXHOLD_KILL` |
| 重活串行 | 每条 `dotnet build` / 应用各自 `bash ~/heavy-slot.sh --min-avail 1500 --max-hold 200 -- timeout …`（`--max-hold 200` 内层 `timeout 180/150`；实测 `held=0~7s`）⇒ 与另两条车道（W79A/W80A）**从不并跑** |
| 峰值负载 | `loadavg` 0.79 → 1.0 区间（本车道未制造长时高负载） |
| Xvfb | 自起 `:95`（记 PID，`trap … EXIT` 收尾）；**零 `pkill -f`**（全趟 `grep -c 'pkill' = 0`） |
| `dotnet` 进程 | 收工时 0（构建服务器另行 shutdown，见 §7） |
| 仪器自伤 | 1 处，已如实记：**我的装置脚本第一版把反引号写进了双引号字符串** ⇒ 被 shell 当命令替换执行（实测 `run-w81a-legs.sh: 行 248: t1b-ls-tripwire.sh: 未找到命令`）—— 正是本仓 `QUOTE-TRAP`（`verify-all` 第 `[15]` 步）专治的那一族；已修并在脚本里留注释。**另 1 处**：参数解析用 `for a in "$@"` ＋ 内部 `shift` ⇒ `--leg pmax --no-build` 被判非法（实测）⇒ 改成 `while` + `shift`（同 `run-wpftextdemo.sh` 的既有教训）。 |

---

## §5 `NOINFO` 清单（**既不算绿也不算红**）

| # | 项 | 为什么没取到 |
|---|---|---|
| 1 | `PMaxSize` 在**有 WM**（EWMH）下是否真的约束窗口 | 本轮只有裸 `Xvfb`；要另立装置 |
| 2 | `late` 臂的**真因**（只问一次 vs 问了也不写回） | 需要落地 §1.5 的 H1（产品改动），本件零产品改动 |
| 3 | 运行期改 `MaxWidth` 后 X 提示会不会变 | 同上 |
| 4 | `dpi≠1.041667` 的机器上的期望值 | 只有这一台机器 |
| 5 | `A0` 的**完整需求序列**（27 条里后 26 条的顺序） | 进程死在第一条缺符号上；要走完必须先做 W78A §3.1 的 `A1`（导出 6 个入口＋如实失败）＋`A2`（拆毒池项）——**产品改动，不在本件射程** |
| 6 | `LoadCursorA` 那 9 行链与 `nm -D` 的**分叉**是否还有别的解释 | 我给出的解释（全局作用域查找、shim 在作用域末位）与读数自洽，但**没有**做成对实验去排除别的可能 |
| 7 | 绊线家族过滤器的**假阴性**会不会已经污染过历史结论 | 本件只证明"今天它看不见 PTS 对象族"；历史趟次未复核 |
| 8 | `wic_shim` 位移的**归属** | 只能按 mtime ＋ 写面给出"不是本车道"的证据；**谁改的**请按主控车道账本核 |
| 9 | `W81AWindowProbe` 会不会被将来的门禁**纳入覆盖面** | 今天 `inputs_fp` **不含** `build/MilBridge/tests/**`；若主控将来把探针纳入，则本件新增的 5 个源件会开始影响 `inputs_fp` |
| 10 | "`WmGetMinMaxInfo` 被调用了、只是被 `_swh == null` 守卫挡在写回之前" | 只有**间接**支持（`GetWindowMinMax` 的 `Math.Min(MaxWidth, _trackMax…)` 与"布局钳在 640 而非 0"相容）——窗口的私有缓存字段读不到 ⇒ **不能**把它当已证事实（§1.4 已就地标注） |

---

## §6 大白话小结（6 行）

1. **`0106` 的答案是红的，而且是"真红"**：应用声明了 `MaxWidth/MaxHeight`，X 那边的 `WM_NORMAL_HINTS` 里**没有** `maximum size`；同一进程里不声明的那个窗也没有 —— 区别只在"装置自证"证明了我**看得见**那个值（裸 X 客户端设了就看得见）。
2. **不只坏上限那一半**：声明了 `MinWidth/MinHeight` 的窗，X 提示里**照样是 `1 by 1`** ⇒ 整条 `WM_GETMINMAXINFO → WM_NORMAL_HINTS` 通道对"应用声明的值"是**失效**的。
3. **根因不是 WPF 不认这两个 DP**：`sizecontent` 窗的内容 2000×1500 被**钳到 640×480**、`minonly` 窗被**撑到 500×400** ⇒ 工具包侧**活的**；坏的是"送去 X"这一步 —— shim 只在 `CreateWindowEx` 里**问一次**，而那一刻 WPF 的写回被它自己的 `_swh == null` 守卫挡着（上游注释逐字自述），**shim 再也不问第二次**。
4. **`A0` 量到了，但只有一格**：最小 `FlowDocument` 页面**实测**第一跳就是 `CreateInstalledObjectsInfo`（`ld.so` 自己写了 `undefined symbol … (fatal)`，`rc=134`）⇒ 27 条里**只命中 1 条**，其余 26 条是"还没轮到"而不是"不需要"；要往下走必须先做 `A1`（导出但如实失败）＝产品改动。
5. **顺带发现装置两处会骗人**：绊线自带的家族过滤器**看不见**这个致命符号（它不以 `Fs/Lo/Ls/Nl` 开头，反倒把 `LoadCursorA` 算进去了）；而它那条"查找行数 ≥ 6 ⇒ MISS"的规则**有反例**（`LoadCursorA` 9 行但 `nm -D` 说 shim 定义了它）⇒ 判据要用 `nm -D`，不能用行数。
6. **零产品件位移**：九位里八位逐位等于 `#49` 冻结值（`wic_shim` 变了但**不是本车道**，mtime 16 分钟早于本车道首次落盘）；`inputs_fp` **不可能变**（我改/加的三处、143 件覆盖面 **0 命中**）；`APPSYNC` 改前==改后。唯一被迫改的既有件是 hygiene 声明册**一行**，留一条 `CAND_MIN 86→87` 的欠账给主控。

---

## §7 复现命令 ／ 件 sha16

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"

# ① 两条腿一起跑（每条重活各自入槽；约 3 分钟）
bash $R/build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg both      # rc=1（= A0 腿绿、PMaxSize 腿红）
bash $R/build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg pmax --no-build
bash $R/build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg a0   --no-build

# ② 只看 `PMaxSize` 两极化（装置自证 ＋ 五窗）
#    产物：$HOME/w81a/out/pmax/{app.log,declared.hints,undeclared.hints,xprobe-max.hints,xprobe-nomin.hints,*wininfo}

# ③ 只看 `A0`（顺序 ＋ 27 条对表）
python3 $R/build/MilBridge/tests/W81AWindowProbe/w81a-a0-analyze.py /dev/shm/w81a-lddebug $HOME/w81a/out/a0

# ④ 收尾：关掉编译服务器（把内存还给机器）
dotnet build-server shutdown
```

| 件 | sha16 | 备注 |
|---|---|---|
| `build/MilBridge/W81A-report.md` | 见末行（自指件） | 口径 = `head -n -3 <本文件> \| sha256sum \| cut -c1-16` |
| `$HOME/w81a/out/FINAL-run.log` | `654448914af1b3eb` | 两条腿一趟的**完整** 17563 B 输出（结论行的唯一出处） |
| `$HOME/w81a/out/pmax/app.log` | `a760766b8b1246b5` | 五窗 ＋ 9 行 `[WMSIZE_DIAG]` |
| `$HOME/w81a/out/a0/a0-analyze.txt` | `1df592be7fbd745b` | 顺序表 ＋ 27 条对表 ＋ 首缺链 |
| `$HOME/w81a/out/a0/ld-app.log` | `5e5ab665c83325d3` | **原始 ld.so 日志**（35628 行；由 `/dev/shm` 拷来耐久化） |
| `$HOME/w81a/out/a0/tripwire/ls-tripwire.txt` | `2296660d1cc0a137` | 绊线自带汇总（家族表 ＋ 5 条关键符号） |
| `build/MilBridge/tests/W81AWindowProbe/bin/Release/W81AWindowProbe.dll` | `3ff0a34d06638c24` | 探针二进制（五个窗口/两次腿都用它） |
| `build/MilBridge/tools/t1b-ls-tripwire.sh` | `82f6a05afb1f9db9` | 装置（**未改**，仅使用） |
| `build/MilBridge/tools/build-hygiene-roster.tsv` | 改前 `1a6de1ecd3665f12` → **改后 `49f0d45c1b122f5f`** | §3.2 的那一行 |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `c493639d15678803` | 被测件（= `#49` 冻结值） |

---

**报告自身 sha16**：口径 = `head -n -3 build/MilBridge/W81A-report.md | sha256sum | cut -c1-16`（去掉最后三行，含本行与上一行分隔符）。
W81A-REPORT-SHA16: 257b2f45784aa69b（373 行 / 37063 B；口径见上一行）

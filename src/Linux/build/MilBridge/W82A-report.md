# W82A · `D-G83` 修法落地（波 `#50`）：`WM_GETMINMAXINFO → WM_NORMAL_HINTS` 通道恢复通

> 车道 `W82A`｜波 `#50`｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> 作业窗口 `2026-09-21 23:03 → 23:2x +0800`｜kernel `6.8.0-138-generic`｜`nproc=3`
> 写域 = `src/WpfGfx.Linux.Native/src/**`（`win32_core.c` ＋ `win32_internal.h`）＋ 新探针 `build/MilBridge/tests/W82AMinMaxProbe/**` ＋ 本报告。
> **未碰**：`build/shims/**`、`build/PresentationCore.Linux/**`、`build/DirectWrite.Linux/**`、
> `build/MilBridge/tools/**`、四个路由件、`defect-registry-declared.tsv`（mtime 证据见 §4.5）。
> **未跑**：`integration-wave.sh`／`close-wave.sh`／`verify-all.sh`。**无** `pkill -f`（一律按 PID）。
> 所有 sha 一律现场 `sha256sum | cut -c1-16`（无手抄）。
> ⚠️ 本报告**推翻了本件任务书写下的判定点**（见 §1.4 与 §3.6）：`H1` 是**必要但不充分**的，
> 后面还藏着**一跳**（`DefWindowProcW` 事后覆盖），不修它 `H1` 单落地**一格都不动**（有读数）。

---

## §0 判据（**先写进报告，读数后取**；本节写成于 `23:05`，早于本车道第一次改产品源 `23:07`）

### 0.1 被测件与观测面

| 项 | 内容 |
|---|---|
| 被测件 | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（`win32shim` 位；本车道**唯一**会动的世代位） |
| 装置 | 仓内**已存在**的 `build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg pmax`（**仪器不改**：一个进程、五个窗口、`xprop` 读 X 服务器自己的属性） |
| 观测面 | `xprop -id <xid> WM_NORMAL_HINTS`（**X 服务器自己的属性**，不是我方日志、不是我方变量） |
| 判别力自证 | 装置自带的裸 X 客户端（`xprobe-hints.c`，与 WPF/shim 无关）必须 `W81A_PMAX_DEVICE=PASS`；不过 ⇒ 一律 `NOINFO`（**不许把"我读不出来"当"没发"**） |
| 期望值口径 | `MaxWidth/MaxHeight` 是 **DIP**，`WM_NORMAL_HINTS` 是**像素** ⇒ 期望 = `DIP × 探针现场读出的 dpi`（本机 `1.041667`）；**比例不写死在判据里** |

### 0.2 四格判据（**改动之前写死**）

| 格 | 窗口 | 判据（绿 / 红 / 点名） |
|---|---|---|
| **① 正极性 P1** | `declared`：`MaxWidth=640, MaxHeight=480`（`Show()` **之前**设） | **绿** ⟺ 出现 `program specified maximum size: 667 by 500`；**缺席 = 红** |
| **①b 下限** | `minonly`：`MinWidth=500, MinHeight=400` | **绿** ⟺ 出现 `program specified minimum size: 521 by 417`；停在 `1 by 1` = 红 |
| **② 反极性 N1（语义）** | `undeclared`：两 DP 都不设 | **绿** ⟺ `maximum size` **缺席**（"应用真没声明就不发"这条必须保住） |
| **②b 反极性（修法回退）** | 同上五窗，**修法逐字节还原**后重跑 | **必须回到修前形态**（缺席 / `1 by 1`）。若还原后仍有值 ⇒ 测到的不是本修法的因果 ⇒ 本件作废 |
| **③ `reg58` 格** | 任一格 | 若出现的是**屏幕尺寸** `1280 by 1024`（波 58 的旧错法）⇒ **点名 `reg58=yes`，不是绿、也不是"没发"** |
| **④ 未声明** | 同 ② | `maximum size` **必须缺席** |

**三态**：`PASS`／`FAIL`／`NOINFO`（属性本身不在、装置自证不过、槽被拒/被杀 ⇒ `NOINFO`）。

### 0.3 修法判据与零回归判据

| 项 | 判据 |
|---|---|
| 落点 | "填默认值 → 派发 `WM_GETMINMAXINFO` → 算 `app_declared` → `wpf_x11_apply_wm_hints()`"抽成**一个函数**（建窗路径照旧调用、语义不变），并在**首次 map 之后**再调用一次 |
| 不重复问 | 每窗**有上限**的重问计数；判据 = 五窗那一趟里每窗的补问行 ≤ 上限，且**不是每次都问** |
| 语义不变 | "应用真没声明 ⇒ `max_w=max_h=0` ⇒ 不发 `PMaxSize`"**逐字保留**（②格） |
| 零回归 | `hbtextline`／`pc`／桥／`pf`／`windowsbase`／`provider`／`dwf` **逐位未变**；只有 `win32shim` 变 |
| 窗口仍可用 | 同一条探针上：能开（`Map State: IsViewable`）、能**移**、能**缩**（`xdotool` 后 `xwininfo` 几何跟着变）、**不崩** |
| 不许 | 不许在 `app_declared=0` 时用钳制值/屏幕尺寸顶上（③格就是为它准备的）；不许动判据件；不许把 `NOINFO` 读成绿 |

---

## §1 判定点（复算 ＋ **被推翻的那一半**）

### 1.1 修前链条（W81A 已取证，本件复算一致）

| # | 环节 | file:line |
|---|---|---|
| 1 | shim 全仓**只问一次** `WM_GETMINMAXINFO`，在 `CreateWindowEx` 内、`XMapWindow` **之前** | `win32_core.c:897-915`（修前 `:809-840`） |
| 2 | 那一刻托管侧 `_swh` 还没赋值 ⇒ 写回块被守卫挡住 | 上游 `Window.cs:4885` 的 `!IsSourceWindowNull && !IsCompositionTargetInvalid`；`_swh` 赋值在 `Window.cs:2521`（`new HwndSource(param)` 之内/之后） |
| 3 | ⇒ 回填 == 默认值 ⇒ `app_declared` 恒假 ⇒ `PMaxSize` 永不发 | `win32_core.c:822-830`（修前），W81A 实测 9/9 次回填 == 默认值 |

### 1.2 🔴 修法 `H1` 单落地**不生效**（读数，不是论证）

按任务书落地 `H1`（首次 map 之后补问一次、重发提示）后重建 ⇒ `win32shim = 34ff601ebd76c0ee`，跑同一条腿：

```
W81A_PMAX_ROLE role=declared … max='<缺席>'
W81A_PMAX=FAIL P1=no(声明 640x480 DIP ⇒ 期望 '667 by 500'，实得 '<缺席>') N1=yes(…) reg58=no
[WMSIZE_DIAG] WM_GETMINMAXINFO(after-map): … 窗口过程回填 min=1x1 max=1280x1024 ⇒ 应用**没有**声明上限 …
```
⇒ **补问发生了（5 次，每窗 1 次），但回填仍是默认值**。日志 `$HOME/w82a/out/fix1-script.log`（`23f75b8e501c1e86`）。

### 1.3 用新探针把这"为什么还没写回"从猜测变成读数

新探针 `build/MilBridge/tests/W82AMinMaxProbe/`（只读，零产品改动；P/Invoke `user32!SendMessage` ＋ 反射读私有字段/属性）。四条读数（`$HOME/w82a/out/probe4.log` `83c8a7d6e578b700`）：

| # | 读数 | 原文 |
|---|---|---|
| ① | **两个守卫都是 false**（map 之后） | `IsSourceWindowNull=False IsCompositionTargetInvalid=False rawCT.IsDisposed=False` |
| ② | **应用自己发** `SendMessage(WM_GETMINMAXINFO)` 也不改 | `W82A_SEND tag=A post … changed=no` |
| ③ | **消息确实进了钩子链**，且链上只有 `Window` 的过滤器 | `W82A_HOOKS n=1` / `W82A_HOOKS[0]=System.Windows.Window.WindowFilterMessage target=System.Windows.Window` / `W82A_HOOK#1 msg=0x0024 进链时 …` |
| ④ | **直接反射调 `Window.WindowFilterMessage` ⇒ 它写对了** | `W82A_INVOKE ok ret=0 handled=False 回填后 maxsize=… mintrack=**521x417** maxtrack=**667x500** changed=**YES**` |

⇒ 守卫、钩子、托管逻辑**全都是好的**，值**确实**被写进结构体了；**是我们的代码在事后把它盖回去**。

### 1.4 真因（**本件推翻任务书判定点的那一半**）

| # | 事实 | file:line |
|---|---|---|
| A | `WindowFilterMessage` **第一段** `switch` 把 `handled = WmGetMinMaxInfo(lParam)`（`WmGetMinMaxInfo` 返回 `true`） | 上游 `Window.cs:4250-4252`、`:4912` |
| B | 紧接着 `:4258` 的 `if(_swh != null && _swh.CompositionTarget != null)` **第二段** `switch`（`:4272-4298`）里**没有** `WM_GETMINMAXINFO` 这一格 ⇒ 落到 `default: handled = false;` **把 A 的 `true` 覆盖掉** | 上游 `Window.cs:4295-4297`（与读数④的 `handled=False` 互印） |
| C | 于是 `DefWindowProcW` **照常被走到** —— 而波 58 把这个 `case` 从 `return 0;` 改成了 `fill_minmaxinfo_defaults(lParam);`，理由是"这个 case 是**不可达的死码**" | `win32_core.c:1713-1717`（修前）＋ 旧注释 `:889` |
| D | ⇒ **窗口过程刚写好的 `521x417/667x500` 被就地改成默认值** | 配对读数（`$HOME/w82a/out/probe5.log` `72c459b332a947f1`）：<br>`WM_GETMINMAXINFO(after-map): … 回填 min=1x1 max=1280x1024`<br>`DefWindowProcW(WM_GETMINMAXINFO): 进来时 **min=521x417 max=667x500** → 本 case 会把它**就地改成**默认值` |

**Win32 语义的正确归属**：这条消息的"填默认值"属于**发消息方**（系统在**发之前**填），
`DefWindowProc` 对它是 **no-op**。波 58 把默认值填进 `DefWindowProc` ⇒ 在 Windows 上无害只是因为它
**没有发消息方**（真 Windows 由 USER32 填），在我们这里就成了"事后覆盖"。

⇒ **修法 = 两半都对才通**：`H1`（map 之后补问，让托管侧有机会写）＋ `DefWindowProcW` 那一格**回到 no-op**（让写好的值活下来）。

---

## §2 修法逐处 ＋ before/after sha16

### 2.1 改动清单（逐处，行号级）

| # | 件 | 行号（**改后**） | 改动 |
|---|---|---|---|
| 1 | `win32_core.c` | `:704-750` 新增 `static int wpf_ask_minmaxinfo_apply_hints(HWND, const char *cls, const char *where)` | 把建窗那 32 行（填默认 → 派发 → 算 `app_declared` → 发提示 → 诊断）**逐字搬进函数**，只在诊断串前加 `where` 前缀（建窗调用点传 `"WM_GETMINMAXINFO"` ⇒ **那一行逐字节不变**） |
| 2 | `win32_core.c` | `:751-790` 新增 `#define WPF_HINTS_REASK_MAX 3` ＋ `static void wpf_minmaxinfo_reask_after_map(HWND)` | 补问的**闸**：只在顶层、**非** message-only、**非** `WS_CHILD`、未"已声明"、且 `hints_map_asks < 3` 时补问一次；问出 `app_declared=1` ⇒ 置 `hints_map_declared` **终态**、此后不再问 |
| 3 | `win32_core.c` | `:914`（建窗路径） | 原 `:810-839` 的 30 行 → **一行调用** `wpf_ask_minmaxinfo_apply_hints(w->hwnd, cls, "WM_GETMINMAXINFO");`；**顺序/谓词/语义一字未动** |
| 4 | `win32_core.c` | `:1074`（`ShowWindow` 内、`WM_SHOWWINDOW` 派发**之后**、`want_state` 处理**之前**） | `if (map) wpf_minmaxinfo_reask_after_map(hwnd);` — 首次 map 之后补问。**为什么落这里**：`ShowWindow(map=1)` 必然晚于 `Window.CreateSourceWindow` 的 `_swh = new SourceWindowHelper(source)`（`Window.cs:2521`）与 `Show()` 的 `ShowWindow`（`:5548`）；`SetWindowPos(SWP_SHOWWINDOW)` 也走这里（`:1075` 自己调 `ShowWindow`）。**为什么不在 `wpf_x11_map` 里**：那一层在建窗路径里也会被调（`WS_VISIBLE` 分支），要区分就得引入"正在建窗"的跨层标记，而 `WM_CREATE` 里再建窗会把那种标记嵌套冲掉 |
| 5 | `win32_core.c` | `:1713-1746`（`DefWindowProcW` 的 `WM_GETMINMAXINFO`） | **回到 no-op**（`return 0;` 什么都不填）＋ 把"死码"的错误前提连同反证逐字写进注释 ＋ 留一行 env 门控诊断（进来时的值，证明"值活着到达这里"） |
| 6 | `win32_core.c` | `:885-895`（建窗路径老注释） | **就地更正**两句话：波 58 说"`DefWindowProcW` 那个 case 是**不可达的死码**"——**被实测证伪**（每次都走到、且在窗口过程之后）。留原话 ＋ 更正，不抹历史 |
| 7 | `win32_internal.h` | `:327-331` | `wpf_window` 新增两个字段：`int hints_map_asks;`（次数上限）＋ `int hints_map_declared;`（"已声明"终态） |

> **形参/接口零外溢**：`wpf_x11_apply_wm_hints()` **一个字节未改**（`win32_x11.c` 本件**未动**——任务书点名的那处最终不需要改）；
> 新增两个函数都是 `static`（不新导出符号）；**没有新增调用点**（`wpf_dispatch_to_window(WM_GETMINMAXINFO)` 仍是建窗 + 补问两处，且两处**共用同一个函数**）。

### 2.2 before / after sha16

| 件 | before | after | 字节数 before → after |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `ba1d9ba959da163c` | **`9aa0d2d1b1ed8d55`** | 107,426 → 116,533 |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `fd5d220931bebf8d` | **`c3dbf6b936a36239`** | 31,860 → 32,450 |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `050f349638bbf87e` | **`050f349638bbf87e`**（**未动**） | 91,594 → 91,594 |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**`win32shim` 位**） | `c493639d15678803` | **`3e4390c9ec07f621`** | 322,056 → 322,056 |
| （中间态 · 只有 `H1` 那一半） | — | `34ff601ebd76c0ee` | 322,112（**实测 FAIL**，见 §1.2） |
| 新件 `build/MilBridge/tests/W82AMinMaxProbe/Program.cs` | — | `8b9e8294ae97b4d9` | 15,980 |
| 新件 `build/MilBridge/tests/W82AMinMaxProbe/W82AMinMaxProbe.csproj` | — | `4f13da7c0cfa1576` | 8,095 |
| 构建日志 | — | `0 error`；`1 warning`（`win32_misc.c:224` 的 `-Wmisleading-indentation`，**改前就有、与本件无关**） | — |

**确定性**：同源连跑两次构建 ⇒ 同一个 sha（`3e4390c9ec07f621`，见 §3.5 的回退往返）。

> ⚠️ **`.so` 字节数与修前相同（322,056）是巧合，不是"没改"**：sha 不同；且回退到修前源重建立刻回到 `c493639d15678803`（§3.5）⇒ 双向都咬得住。

---

## §3 四格读数

### 3.1 正极性 / 反极性 / `reg58` / 未声明（同一趟、同一进程）

`xprop -id <xid> WM_NORMAL_HINTS` 逐窗原文（`$HOME/w82a/out/fix2/pmax/*.hints`）：

| 角色 | 声明 | `xprop` 原文 | 判定 |
|---|---|---|---|
| `declared` | `Max=640x480`（DIP） | `program specified minimum size: 1 by 1` ＋ **`program specified maximum size: 667 by 500`** | ✅ **P1 绿**（期望 `667x500`，逐字吻合） |
| `undeclared` | 无 | 只有 `minimum size: 1 by 1` | ✅ **N1 绿**（`maximum size` **缺席**） |
| `late` | `Show()` **之后**才设 | 只有 `minimum size: 1 by 1` | 诊断：**缺席**（= "只问一次"那一档） |
| `sizecontent` | `Max=640x480` ＋ `SizeToContent`（内容 2000×1500，实测被钳到 640×480） | **`maximum size: 667 by 500`** | ✅ 与 `declared` 同 |
| `minonly` | `Min=500x400` | **`program specified minimum size: 521 by 417`** | ✅ **①b 绿**（期望 `521x417`，逐字吻合） |

```
W81A_PMAX_DEVICE=PASS（装置成对：设了 PMaxSize 的窗读得到、没设的读不到）   ← 装置判别力自证
W81A_PMAX_UNITS dpi=1.041667 ⇒ 期望 PMaxSize=667x500
W81A_PMAX=PASS P1=yes(declared max='program specified maximum size: 667 by 500' 期望='667x500') N1=yes(undeclared 无 maximum size)
W81A_PMAX_APP rc=0（0 = 自行退出）
```

**③ `reg58` 格**：`grep -l '1280 by 1024' ~/w82a/out/fix2/pmax/*.hints | wc -l` = **0** ⇒
**屏幕尺寸没有被当成 `PMaxSize` 顶上去**，`reg58_wave-defect-shape=no`。
（修前那一趟打印的也是 `reg58=no` —— 但那时是"全都缺席"，分不出"正确缺席"与"全都缺席"拿到本次读数才算。）

### 3.2 两条证据链互印（`[WMSIZE_DIAG]` 与 `xprop`）

修后五条补问行（`$HOME/w82a/out/fix2/pmax/app.log` `397d56d72849343b`，**全量、未抽样**）：

```
(after-map) … 回填 min=1x1 max=667x500   ⇒ 应用**有**声明上限 ⇒ X 提示 min=1x1 PMaxSize=已发      ← declared
(after-map) … 回填 min=1x1 max=1280x1024 ⇒ 应用**没有**声明上限 ⇒ X 提示 min=1x1 PMaxSize=**未发** ← undeclared
(after-map) … 回填 min=1x1 max=1280x1024 ⇒ 应用**没有**声明上限 ⇒ X 提示 min=1x1 PMaxSize=**未发** ← late
(after-map) … 回填 min=1x1 max=667x500   ⇒ 应用**有**声明上限 ⇒ X 提示 min=1x1 PMaxSize=已发      ← sizecontent
(after-map) … 回填 min=521x417 max=1280x1024 ⇒ … ⇒ X 提示 min=521x417 PMaxSize=**未发**            ← minonly
```
⇒ shim 侧"发了什么"与 X 侧"读到了什么"**逐格一致**（`min` 只在下限那一格是 `521x417`）。

### 3.3 "不是每次都问"（任务书第 2 条）

同一趟日志：建窗那一拍 `9` 行、补问 `5` 行（= **已显示**的 5 个窗口各 **1** 次），
`hints_map_asks` **没有一窗到达上限 3**，`declared`/`sizecontent` 在第一次补问就得到
`app_declared=1` ⇒ 落"已声明"终态、**此后再不问**。⇒ 无消息风暴。

### 3.4 反极性 ①（语义）：未声明窗口仍**不发** `PMaxSize`

见 §3.1 的 `undeclared` 与 §3.2 的第 2 行 —— **逐字保留**波 59 的语义（`max_w=max_h=0` ⇒ 不发）。

### 3.5 反极性 ②（修法回退）：**回到修前形态**（往返闭合，双向 byte-identical）

```bash
cp -p ~/w82a/backup/win32_core.c.pre       src/WpfGfx.Linux.Native/src/win32_core.c
cp -p ~/w82a/backup/win32_internal.h.pre   src/WpfGfx.Linux.Native/src/win32_internal.h
bash src/WpfGfx.Linux.Native/build-shim.sh     # ⇒ win32shim = c493639d15678803（**与 #49 冻结值逐位相同**）
```
读数（`$HOME/w82a/out/prefix-script.log` `c3b9cd971ae8cc79`）：

```
W81A_PMAX_ROLE role=declared   min='1 by 1' max='<缺席>'
W81A_PMAX_ROLE role=undeclared min='1 by 1' max='<缺席>'
W81A_PMAX_ROLE role=minonly    min='1 by 1' max='<缺席>'      ← 下限也回到 1 by 1
W81A_PMAX=FAIL P1=no(…实得 '<缺席>') N1=yes(…) reg58_wave-defect-shape=no
```
⇒ **修前形态逐格复现**（与 W81A 的原始 FAIL 读数同形）。随后把修好的两件 `cp -p` 回去重建 ⇒
`win32shim` **又**是 `3e4390c9ec07f621` ⇒ **回退 → 前进 往返闭合、且构建确定性**。

### 3.6 我推翻了哪几句话（三条，逐条给反证）

| # | 被推翻的话 | 出处 | 反证（读数） |
|---|---|---|---|
| 1 | "根因 = shim 只问一次，而那一刻写回被 `_swh == null` 守卫挡住 ⇒ **再问一次就好**"（任务书 §1） | 本件任务书／`KNOWN-DEFECTS.md` 的 `D-G83` 判定点 | **`H1` 单落地 ⇒ 依然 FAIL**（§1.2，`34ff601ebd76c0ee`）；且 map 之后 `IsSourceWindowNull=False IsCompositionTargetInvalid=False rawCT.IsDisposed=False`（§1.3 ①）⇒ **补问那一拍守卫根本没挡** |
| 2 | "`DefWindowProcW` 的 `case WM_GETMINMAXINFO: return 0;` 是**不可达的死码**，把它填对**单独不会改变任何行为**" | 波 58 注释，`win32_core.c:889-891`（**至今仍在树里，本件就地更正**，见 §2.1 第 6 项） | 它**每次派发都被走到**，而且是在窗口过程**之后**：`DefWindowProcW(WM_GETMINMAXINFO): 进来时 min=521x417 max=667x500` ⇒ 它不是在"发消息前填默认值"，是在**事后覆盖** |
| 3 | "`WmGetMinMaxInfo` 被调用了、只是被守卫挡在写回之前"（W81A §1.4 自标 `NOINFO` 的那条） | `build/MilBridge/W81A-report.md` §5 #10 | 守卫两半都是 false（§1.3 ①）；值**确实**被写好了（§1.3 ④ `521x417/667x500`）⇒ 它**不是**"被挡在写回之前"，是**写完之后被我们盖掉** |

> 顺带**更正 W81A 报告的一处口径**：W81A §0.1 写"期望 = `LogicalToDeviceUnits(声明值)`"，本件实测逐字吻合
> （`667x500` / `521x417`），**这条是对的**；错的只是"守卫挡住"那半句。

---

## §4 零回归

### 4.1 窗口仍能开 / 能移 / 能缩 / 不崩（`$HOME/w82a/out/zeroreg/`）

```
ZR_STEP step=open                   geo=521x417+0+0     map=IsViewable  hints=[min 521 by 417; max 667 by 500]
ZR_STEP step=after-move             geo=521x417+120+90  map=IsViewable  hints=[min 521 by 417; max 667 by 500]
ZR_STEP step=after-grow             geo=900x700+120+90  map=IsViewable  hints=[min 521 by 417; max 667 by 500]
ZR_STEP step=after-shrink-below-min geo=300x220+120+90  map=IsViewable  hints=[min 521 by 417; max 667 by 500]
ZR_STEP step=after-restore          geo=380x280+120+90  map=IsViewable  hints=[min 521 by 417; max 667 by 500]
ZR_APP rc=0   ZR_ALIVE_LINES=1   （无 W82A_PROBE=EXC）
```
⇒ ① 开窗 ✅ ② `windowmove` 生效（`+0+0 → +120+90`）✅ ③ `windowsize` 大小两个方向都生效 ✅
④ 全程不崩、`rc=0`、无异常 ✅ ⑤ 动完之后 `WM_NORMAL_HINTS` **仍在**（两条都在）✅
⚠️ **判别力边界（不许读成"约束生效"）**：`xdotool windowsize 300 220` **小于**新设的 `PMinSize 521x417` **也成功了** ——
因为本轮是**裸 `Xvfb`、没有 WM**，X 提示对 WM 是**建议**；这条腿只证"窗口本身没被新提示弄坏"，
**不证**"WM 会照它约束拖拽"（与 W81A §5 #1 同一条边界，见 §5）。

### 4.2 世代九位逐位对账（相对 `#49` 冻结块）

| 位 | `#49` 冻结值 | 现场 | 结论 |
|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | `feef049e9d0e313a` | ✅ 未变 |
| `pc` | `56ee75ced8d6aece` | `56ee75ced8d6aece` | ✅ 未变（**本件未碰 `build/PresentationCore.Linux/**`**） |
| `pf` | `6375fabf89ac7fef` | `6375fabf89ac7fef` | ✅ 未变 |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | ✅ 未变 |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | ✅ 未变 |
| **`win32shim`** | `c493639d15678803` | **`3e4390c9ec07f621`** | ⚠️ **变了 —— 本车道**（`D-G83` 修法；= 任务书预告的"`#50` 位移多一位"） |
| `wic_shim` | `56278c14b4ecd672` | `f7b3026c8c019be2` | ⚠️ 变了但**不是本车道**（W81A §3.3 已归因并行的 GIF/WIC 车道；mtime `18:32:55`，早于本车道 4.5 小时） |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | ✅ 未变（**本件未碰 `build/shims/**`**） |
| `dwf` | `de2d555105b7d04b` | `de2d555105b7d04b` | ✅ 未变 |

### 4.3 两趟几何逐格相同（修前 vs 修后，同一条探针）

| 角色 | 修前（`prefix`）`geom` | 修后（`fix2`）`geom` |
|---|---|---|
| `declared` / `undeclared` / `late` | `375x271` | `375x271` |
| `sizecontent` | `667x501` | `667x501` |
| `minonly` | `521x417` | `521x417` |
⇒ **布局/几何零位移**（差的只有 `WM_NORMAL_HINTS` 里那条 `PMaxSize`/`PMinSize`）。

### 4.4 ⚠️ 零回归欠账（**不在我的写域，必须由主控处置**）

1. **新探针使 `BUILD-HYGIENE` 的 `[9]` 步红**（`verify-all` 第 `[9]` 步）：
```
BHYGIENE_DRIFT=FAIL kind=UNDECLARED path=build/MilBridge/tests/W82AMinMaxProbe/W82AMinMaxProbe.csproj c=0 p1=IDLE(p1:glob=off …)
BHYGIENE_IMPORT=FAIL … undeclared=1 … cand=88 cand_min=87 … roster=49f0d45c1b122f5f
```
**为什么我没顺手改**：`build/MilBridge/tools/**` 在本件任务书里是**明令不许碰**的（另两条车道在用），
而 `build-hygiene-roster.tsv` 与 `build-hygiene-import-check.sh` 都在那里。**请主控落两处**：
   - `build/MilBridge/tools/build-hygiene-roster.tsv` 增 **1 行**（与 `W81AWindowProbe` 同款，制表符 5 列）：
     ```
     notneeded	build/MilBridge/tests/W82AMinMaxProbe/W82AMinMaxProbe.csproj	no-compile-glob	【`#50` W82A 新探针】`D-G83` 的回溯仪器（"WPF 何时才把 WM_GETMINMAXINFO 的回填写出来"；反射直调 + SendMessage 两条独立读数）。与 TabGapProbe/W81AWindowProbe 同形态：EnableDefaultCompileItems=false ＋ 逐条 Compile Include ⇒ 默认 glob 不生效；不进 wpf-linux.sln、不被任何产品工程引用 ⇒ 不参与产品构建。⚠️ 候选数 87 → 88。	#50 W82A（车道；`D-G83`）
     ```
   - `build/MilBridge/tools/build-hygiene-import-check.sh:135` 的 `CAND_MIN=87` → **`88`**（否则 `--selftest` 的
     `CONSTANT-DRIFT` 守卫会红）。⚠️ **那件在 `close-wave.sh:fp_inputs()` 的覆盖面里 ⇒ 改它 = 动 `inputs_fp`**，冻前由主控决定同趟落。
2. **4 份 app-local `libwpfwin32.so` 副本因本件而落后**（`win32shim` 变了的必然结果；`APPSYNC` 读数
   `MISMATCH=9[STALE=9 …]`，其中 **5 条 `libwpfwic.so` 是波内既有的、不是本件**）：
```
STALE build/MilBridge/tests/CompositeFontProbe/bin/Release/libwpfwin32.so   EXPECT 3e4390c9ec07f621 ACTUAL c493639d15678803
STALE build/MilBridge/tests/ContractProbe/bin/Release/libwpfwin32.so        EXPECT 3e4390c9ec07f621 ACTUAL c493639d15678803
STALE build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/libwpfwin32.so     EXPECT 3e4390c9ec07f621 ACTUAL c493639d15678803
STALE samples/WpfFeatureProbe/bin/Release/net10.0/libwpfwin32.so            EXPECT 3e4390c9ec07f621 ACTUAL c493639d15678803
```
   处置 = 波内 **3.6 刷新步**（`build/integration-wave.sh` 自动跑 `sync-applocal.sh --apply`；`#49` 冻结块记过"这份刷新不需要手做"）
   —— 那件在 `build/MilBridge/tools/**`，**不在我的写域**。⇒ 在那之前，**任何跑 app-local 副本的臂读到的仍是修前 shim**。

### 4.5 路由件与登记表：**未触碰**（mtime 证据）

| 件 | 现场 mtime | 本车道作业窗口（`23:03` 起）之前？ |
|---|---|---|
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` | `17:43:14` | ✅ 之前 ⇒ 非本车道 |
| `docs/CURRENT-STATE.md` | `17:43:14` | ✅ 之前 ⇒ 非本车道 |
| `handoff.md` | `2026-09-20 01:05:33` | ✅ 之前 ⇒ 非本车道 |
| `build/shims/PresentationCore.HbTextLine.cs` | `12:32:47` | ✅ 之前 ⇒ 非本车道（**本件未碰 shim**） |
| `build/MilBridge/tools/build-hygiene-roster.tsv` | `18:34:42` | ✅ 之前 |
| `build/MilBridge/tools/build-hygiene-import-check.sh` | `18:47:30` | ✅ 之前（= 主控把 `CAND_MIN` 提到 87 的那一趟） |
| `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` | **`23:08:03.369`** | ⚠️ **在窗口内，但不是本车道**：本车道从未对它执行写操作；它与 `defect-registry-declared.tsv`（`23:08:03.513`）**同一秒**成对变更 = 一次**登记表操作**；两份文件里 `grep -c W82A` = **0** ⇒ 与我的读数无关（归因为主控/并行车道） |

---

## §5 `NOINFO`（既不算绿也不算红）

| # | 项 | 为什么没取到 |
|---|---|---|
| 1 | `PMaxSize`/`PMinSize` 在**有 WM**（EWMH）下是否真约束拖拽/改尺寸 | 本轮只有裸 `Xvfb`；§4.1 的"小于 `PMinSize` 也缩放成功"就是这条边界本身 |
| 2 | `late` 臂（`Show()` 之后才声明）能不能也生效 | 需要"跟着 DP 变化重问"（W81A §1.5 的 `H2`）：本件落地的是 `H1`（首次 map 后**一次**）⇒ `late` 实测**缺席**，如实计档、**不当红也不当绿** |
| 3 | 运行期改 `MaxWidth` 后 X 提示跟不跟着变 | 同 #2（`H2` 未落地） |
| 4 | `dpi ≠ 1.041667` 的机器上的期望值 | 只有这一台机器；判据按"现场读比例"写，但没在第二种比例上取过读数 |
| 5 | 子窗口 / message-only 窗口 / `WS_VISIBLE` 建窗（不经过 `ShowWindow`）的补问 | 本件把补问挂在 `ShowWindow`（判据只覆盖顶层常规窗口）。**建窗即 `WS_VISIBLE` 且从不调 `ShowWindow` 的窗口不会补问** —— 未测（它们通常不声明 `MaxWidth`） |
| 6 | 真 Windows 上 `handled=false` 是否还有别的后果 | 本件只证"在我们这里它导致 `DefWindowProcW` 被走到、进而覆盖"；托管侧那第二段 `switch` 的用意（上游只列 `WM_CLOSE/DESTROY/ACTIVATE/MOVE/NCHITTEST/SHOWWINDOW/COMMAND`）**未深究** |
| 7 | 一份**带内容、走渲染**的真实应用的零回归 | 那要 app-local 副本同步（§4.4 欠账 2，在 `tools/**`）＋ 一次完整应用跑；本件用**探针**（加载**权威** shim）取读数，**没跑** `WpfFeatureProbe`/hc 示例 |
| 8 | `inputs_fp` 的新值 | 本件改了 `src/WpfGfx.Linux.Native/src/{win32_core.c,win32_internal.h}`（在 `fp_inputs()` 覆盖面里）⇒ **`inputs_fp` 必变**；但那要跑 `close-wave.sh`（**主控的波尾动作，本车道禁跑**）⇒ 不猜值 |

---

## §6 内存三值 / 纪律自证

| 项 | 读数 |
|---|---|
| `MemAvailable` | 开工 **2768 MB** → 作业期最低 **2613 MB** → 收工 **2638 MB**（`SwapFree` 1085 MB） |
| `loadavg` | `0.52 / 0.25 / 0.18`（开工） → `0.51 / 0.61 / 0.53`（收工）；本车道未制造长时高负载 |
| 重活串行 | **每条** `dotnet build` / 应用 / `gcc` 全部各自 `bash ~/heavy-slot.sh --min-avail 1500 --max-hold 200 -- timeout …`；全程 `HEAVYSLOT=MEMOK`，**无** `MAXHOLD_KILL`、**无** `NOINFO low-memory` |
| Xvfb | `:97`（我起的记 PID；`:96` 由 `run-w81a-legs.sh` 自起自收）；**零 `pkill -f`**（全趟 `grep -c 'pkill'` = 0） |
| 收工 `dotnet` | 只剩 1 个 `VBCSCompiler` 构建服务器（已按 `#49`/W81A 的先例 `dotnet build-server shutdown` 归还内存） |

### 6.1 ⚠️ 我的两处仪器/纪律失误（如实记，不掩盖）

1. **第一次跑探针时把输出目录写错了**：我按新车道习惯传了 `W82A_OUT=…`，而 `run-w81a-legs.sh` 读的是
   **`W81A_OUT`**（脚本第 59 行）⇒ 那一趟的 `rm -rf`/写盘落在 **W81A 的 `$HOME/w81a/out/pmax/`** 上，
   把它 §7 表里那份 `app.log`（`a760766b8b1246b5`）**覆盖**了（现为 `e814e6ffdcbba6d1`）。
   **后果的真实大小**：那份日志里含 `pid=`/`xid=`（每趟都变）⇒ 它本来就**不可逐字节复算**；
   而 W81A 引用的**判据行**（`W81A_PMAX=FAIL …`）我已用**同一条腿、同一装置**重取并耐久化到
   `$HOME/w82a/out/prefix/`（`ed4b39f75510bceb`）⇒ 修前形态**有替代证据、且是同期同机的**。
   此后两趟我都显式传 `W81A_OUT`（`fix2`/`prefix`）。
2. **W82A 探针第一版把 internal **属性**当**字段**读**（`Field(w,"IsSourceWindowNull")` ⇒ `<no-such-field>`）
   ⇒ 那一版对守卫**什么都没读到**，我没有把它当读数用（`probe1/2.log` 里那两格就是 `<no-such-field>`）；
   加 `Prop()` 重取后才有 §1.3 ①。**记在这里**，免得后人拿那两行为据。

---

## §7 复现命令 ／ 件 sha16

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
export PATH="$HOME/.dotnet:$PATH"

# ① 重建被测件（只在槽里）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 200 -- timeout 180 bash $R/src/WpfGfx.Linux.Native/build-shim.sh
sha256sum $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16      # 期望 3e4390c9ec07f621

# ② 四格读数（⚠️ 环境变量名是 W81A_OUT，不是 W82A_OUT）
W81A_OUT=$HOME/w82a/out/repro W81A_DISPLAY=:96 \
  bash $R/build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg pmax     # rc=0，W81A_PMAX=PASS

# ③ 机制读数（守卫 / 回填 / 钩子链 / 直调过滤器）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 200 -- timeout 180 \
  dotnet build $R/build/MilBridge/tests/W82AMinMaxProbe/W82AMinMaxProbe.csproj -c Release -m:1
( cd $R/build/MilBridge/tests/W82AMinMaxProbe/bin/Release && DISPLAY=:97 \
  bash ~/heavy-slot.sh --min-avail 1500 --max-hold 200 -- timeout 120 dotnet ./W82AMinMaxProbe.dll --hold=4 )

# ④ 零回归腿（开/移/缩/不崩）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 200 -- timeout 180 bash ~/w82a/zeroreg.sh
```

| 件 | sha16 | 备注 |
|---|---|---|
| `build/MilBridge/W82A-report.md` | 见末行 | 自指件（口径 = `head -n -3`） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **`3e4390c9ec07f621`** | **新 `win32shim`**（旧 `c493639d15678803`） |
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `9aa0d2d1b1ed8d55` | 旧 `ba1d9ba959da163c` |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `c3dbf6b936a36239` | 旧 `fd5d220931bebf8d` |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `050f349638bbf87e` | **未动** |
| `build/MilBridge/tests/W82AMinMaxProbe/Program.cs` | `8b9e8294ae97b4d9` | 新探针 |
| `build/MilBridge/tests/W82AMinMaxProbe/W82AMinMaxProbe.csproj` | `4f13da7c0cfa1576` | 新探针（**见 §4.4 欠账 1**） |
| `$HOME/w82a/out/fix2-script.log` | `c0e00058c5dd10dd` | **修后四格（PASS）** |
| `$HOME/w82a/out/fix2/pmax/app.log` | `397d56d72849343b` | 修后五窗 ＋ 5 条补问行 |
| `$HOME/w82a/out/prefix-script.log` | `c3b9cd971ae8cc79` | **反极性（FAIL）** |
| `$HOME/w82a/out/prefix/pmax/app.log` | `ed4b39f75510bceb` | 反极性五窗 |
| `$HOME/w82a/out/fix1-script.log` | `23f75b8e501c1e86` | **`H1` 单落地 ⇒ 仍 FAIL**（§1.2） |
| `$HOME/w82a/out/probe4.log` | `83c8a7d6e578b700` | 守卫/回填/钩子链/直调 四条读数 |
| `$HOME/w82a/out/probe5.log` | `72c459b332a947f1` | **`DefWindowProcW` 覆盖**的配对读数 |
| 留档 | `$HOME/w82a/backup/*.pre`（修前原件）／`*.fixed`（修后原件） | 往返证用 |

---

## §8 大白话小结（6 行）

1. **`D-G83` 修好了，而且是四格全绿**：声明 `MaxWidth=640/MaxHeight=480` 的窗口，X 那边**真的出现**了
   `maximum size: 667 by 500`；声明下限的窗口出现 `minimum size: 521 by 417`；**没声明**的窗口**照样没有** `maximum size`；
   装置自证 `PASS`（证明我"看得见"那个值）。修前那条腿是 `FAIL`（全都缺席）。
2. **任务书给的根因只对了一半**：`H1`（首次 map 之后再问一次）**照做了，但一格都没动** —— 有读数。
   真正藏着的最后一跳是：**我们自己**的 `DefWindowProcW` 把 `WM_GETMINMAXINFO` 的 `case` 写成了"填默认值"
   （波 58 以为它是死码），而这条消息**每次都走到它、且在窗口过程之后** ⇒ 应用刚写好的 `521x417/667x500`
   被**就地盖回默认值**。**两半都修才通**。
3. **怎么证到这一跳的**：新探针三条读数 —— 两个守卫都是 `false`、消息确实进了钩子链、
   **直接反射调 `Window.WindowFilterMessage` 它写对了 `521x417/667x500`**；再加上 `DefWindowProcW` 里那句
   "进来时 `min=521x417 max=667x500`" ⇒ 覆盖者当场现形。顺带把 W81A 报告里那条 `NOINFO`（"窗口私有字段读不到"）**补上了**。
4. **没有把失败做成静默半通**：修后 `reg58`（拿屏幕尺寸 `1280 by 1024` 顶替）**一次都没出现**；
   "应用真没声明就不发 `PMaxSize`"这条**逐字保留**；`H1` 单落地那次失败我**原地如实记**、没有粉饰。
5. **零回归**：`hbtextline`／`pc`／桥／`pf`／`windowsbase`／`provider`／`dwf` **逐位未变**，
   只有 `win32shim` 从 `c493639d15678803` 走到 **`3e4390c9ec07f621`**（= 任务书预告的"多一位位移"）；
   窗口能开、能移、能缩、不崩（`rc=0`、无异常），几何逐格与修前相同；回退修法后 `win32shim` **逐位回到** `c493639d15678803`（往返闭合）。
6. **两条欠账在别人手里**（我的写域外，已给逐字处方）：① 新探针要让 `BUILD-HYGIENE` 第 `[9]` 步绿，
   得往 `build/MilBridge/tools/build-hygiene-roster.tsv` 加 1 行并把它 `CAND_MIN 87→88`（那两件在本件**明令不许碰**的目录里）；
   ② 4 份 app-local `libwpfwin32.so` 副本落后（`APPSYNC` `STALE` ＋4），等波内 3.6 刷新步。

---

**报告自身 sha16**：口径 = `head -n -3 build/MilBridge/W82A-report.md | sha256sum | cut -c1-16`（去掉最后三行，含本行与上一行分隔符）。
W82A-REPORT-SHA16: 863c7e89dcb3e6b0（408 行 / 34363 B；口径见上一行）

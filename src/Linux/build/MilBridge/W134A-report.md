# W134A 报告 —— `TASK-0210`「桥侧几何重发／接管」（波 `#54` 唯一产品改动）

> **口径**：本报告 sha16 = `head -n -2 build/MilBridge/W134A-report.md | sha256sum | cut -c1-16`（现场现算）。
> 车道 `W134A`｜目录 `~/w134a/**`｜`R = /home/links-dev/wpf-linux-20260906/wpf-linux`（**不是 git 仓库**）。
> 起点冻结 = `#53`（`a2e49b786d0a1b02`）｜判定点原文 = `docs/ROUTES.md:738`（`TASK-0210`）。
> 被测/装置件**逐趟现算**，一处不手抄。

---

## §0 一句话判决（**结论在前**）

> **那条"还原后 `+85 ms` 的裸 `ConfigureWindow`" 定位到了行，并且已修好。**
>
> **执行者** = `src/WpfGfx.Linux/Windowing/X11Window.cs:246`
> （`X11Native.XResizeWindow(_display.Handle, Id, (uint)width, (uint)height);`）＋ `:252`（`XSync`，就是调用链里那一帧）；
> **唯一调用者** = `src/WpfGfx.Linux/Interop/MilPresentation.cs:1082-1083`
> （`if (presentation.Width != width || presentation.Height != height) presentation.Resize(width, height);`）。
>
> **机制（现场逐字段读数，不是推理）**：桥的"X 尺寸优先"（债务 #3）用 `_lastXSize` 做**一次性边缘探测**，
> 而 `_lastXSize` **每次呈现都无条件刷新** ⇒ **采纳 X 尺寸的那一帧过后，那条分支再也不触发** ⇒
> `width/height` 落回 MIL 侧**过期的 `target.WindowRect`**（仍是最大化几何 `1280x1024`）⇒
> 与 X 缓存（`800x600`）不等 ⇒ 这一行**把过期几何顶回 X**。窗口于是永远回不到 `800x600`。
>
> **修法（一处）**：接窗路径（`OwnsWindow == false`）上**只读尺寸、不写几何**，按 server（X）尺寸渲染 ——
> 呈现层不是它所包装窗口的几何主人。自己建的窗（M1／HelloMil 路径）**逐字不变**。
>
> **三态**：`M1:R2` 臂 **旧件 12/12 红 → 新件 0/12 红**；**承重判据**（非率）：
> 该请求在**协议层台账**上 **12/12 命中 → 0/12 命中**，`xobs` 时间轴 **12/12 四跳 → 12/12 三跳**。
> **反极性**（源逐字节复原 ＋ **重建**）：源回 `8b44b61f944aeeaa`、件回 **`feef049e9d0e313a`（逐字节）**、
> 红腿**全数回红**；放回修法 ⇒ 件**独立复现** `4e25e4b27d4d5ae1`、腿回绿。
> **零回归**：`R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577 sabotage=none win=938x938`
> —— 与 `#53` 代同件基线**除 `mem_mb` 外逐字段相同**。
>
> ⚠️ **一处如实记**（`NOINFO` 方向）：**MIL 侧 `target.WindowRect` 不收敛**（修后仍恒为 `1280x1024`）；
> 本件只解除它的**破坏性作用**，**没有修**它为什么会过期（那在 `pc`/`pf`/shim 的
> `WM_SIZE → UpdateWindowSettings` 链上，**属本件写域外**）。逐字见 §6 `Z3`。

---

## §1 判据（**先写**，早于任何实验读数）

| 件 | 写入时刻 | sha16（现场现算） |
|---|---|---|
| `~/w134a/criteria.md` **§0–§8**（跑任何腿之前写完） | 2026-09-23 **17:15:32** | **`189a01aed82b1eea`** |
| 同上 ＋ **§9**（主控四条硬要求，仍早于第一趟腿） | 2026-09-23 **17:16:25** | **`ed13ff4470e07178`** |
| 同上 ＋ **§10**（承重/支撑分离 ＋ `Z1–Z4` 四格，仍早于 24 趟批） | 2026-09-23 **17:26:53** | **`67da3e7fbec24196`** |

- §0–§9 在取任何读数之后**一字未动**；`§10` 为**只追加**。逐字全文在 `~/w134a/criteria.md`。
- **本件对 `TASK-0210` 判据原文（`ROUTES.md:738`）的逐条落点**：
  ① 「修后该请求在红腿消失／不再改回最大化几何」⇒ **§5 承重项**（协议台账 0 命中 ＋ 时间轴三跳）；
  ② 「`M1:R2` 臂红率显著下降且**趟数与功效先写**」⇒ **§7**（`N=12`/臂，先写，`regression-decision.py` 四要件齐）；
  ③ 「**协议层读数组件在位**」⇒ **§4.2**（`~/wc03/bin/xwrap.so` 的 `PROTO` 层＝**syscall 级**，逐腿打 sha16）；
  ④ 「**反极性** = 复原 ⇒ 红回来」⇒ **§5.3**（源级＋件级两层，件级**逐字节**）。
- ⚠️ **`$HOME/w134a/criteria.md` 是判据的真源**；本报告只**引用**，**不发明**。

---

## §2 定位到行（`TASK-0210` 明写"本件不定位到行" ⇒ 这是第一交付）

### 2.1 三帧解符号（`objdump -d`，**同一份** `wpfgfx_cor3.so` = `feef049e9d0e313a`）
`WC03` 报告的调用链是 `… ← XSync@libX11.so.6 ← wpfgfx_cor3.so+0x131b36 ← +0x1339f5 ← +0x16fa4a`。
本件现场把这三个偏移**逐帧解成符号**（`objdump -d` 的输出自带符号）：

| 偏移 | 解成 | 差 |
|---|---|---|
| `+0x131b36` | `WpfGfx_Linux_WpfGfx_Linux_Windowing_X11Native__XSync+0x56` | 符号 `0x131ae0` |
| `+0x1339f5` | `WpfGfx_Linux_WpfGfx_Linux_Windowing_X11Window__Resize+0x55` | 符号 `0x1339a0` |
| `+0x16fa4a` | `WpfGfx_Linux_WpfGfx_Linux_Interop_MilPresentation__PresentTarget+0x10ea` | 符号 `0x16e960`，其后 `+0x16fa70` 就是 `call …MilPresentation__RenderChannel` |

⇒ 链条闭合：**`PresentTarget` 调 `Resize`，`Resize` 先发 `XResizeWindow`、末尾 `XSync` 把它冲出去** ——
`Resize` 里 `XResizeWindow`（`:246`）与 `XSync`（`:252`）**紧邻**，所以那 24 字节与 `XSync` 的 flush 同在一笔 `writev` 里。
（主控已用 `objdump -t` **独立复核逐位相符**。）

### 2.2 为什么只能是这一处（**静态穷举**）
- 全仓 `X11Native` 的几何原语 **只有一个**被调用：`XResizeWindow`
  （`X11Native.cs:175-176` 声明；`:246` 唯一调用点）。其余 `XMoveResizeWindow`/`XMoveWindow`/`XConfigureWindow` **零调用**（`grep` 全仓 0 命中）。
- `X11Window.Resize` 的**唯一调用者** = `X11PresentationTarget.Resize`（`:80-84`），
  而它的**唯一调用者** = `MilPresentation.cs:1083`。
- `XResizeWindow` 的线上形态 = `opcode 0x0c ∧ value-mask 0x000c(CWWidth|CWHeight)` —— 与 `WC03` 抓到的
  24 字节 `0c 02 05 00 | 04 00 c0 00 | 0c 00 | e0 00 00 05 | 00 00 00 04` **逐位相符**（`win=0xc00004 mask=0xc w=1280 h=1024`）。

### 2.3 "谁在还原后 `+85 ms` 发的" —— **两份独立仪器 ＋ 桥自带字段读数**
本件在现场**独立复现**（私有 `Xvfb :221`(1280x1024x24)＋`xfwm4 --compositor=off`，`SHIM=a6365183fa6d26b9`）：

**(a) 协议级台账**（`~/wc03/bin/xwrap.so` 的 `PROTO` 层：拦 `write/writev/sendmsg` → 判 X socket → 打前 64 字节）
```
T 1790155049745568 rel=13881.137 pid=1084436 tid=1084436 PROTO fd=132 n=24 op0=12
head=0c 02 05 00 04 00 c0 00 0c 00 e0 00 00 05 00 00 00 04 00 00 2b 18 01 00
chain: [hook] <- xwrap.so+0x3189 <- writev@xwrap.so+0xd8 <- libxcb.so.1+0xca53 <- libxcb.so.1+0xcb20
     <- xcb_writev@libxcb.so.1+0x48 <- _XSend@libX11.so.6+0x15e <- _XReply@libX11.so.6+0x81
     <- XSync@libX11.so.6+0x4f <- wpfgfx_cor3.so+0x131b36 <- wpfgfx_cor3.so+0x1339f5 <- wpfgfx_cor3.so+0x16fa4a
```
（`fd=132` 是**本趟**的桥连接号；`WC03` 记 `fd=135`，同一件事的不同趟。）

**(b) server 侧真值时间轴**（`~/wc03/bin/xobs`）：
```
T … rel=13.782 SEG cgeo=800x600@+0+0  frame=0x200264 fgeo=800x600@+0+0  state=[FOCUSED]   ← WM 真还原
T … rel=13.886 EVT ConfigureNotify win=0xc00004 send_event=0 1280x1024@+0+0              ← 被打回
```
⇒ 还原 `13.782 s` → 桥发请求 `13.881 s` = **`+99 ms`** → 落地 `13.886 s`。
（`ROUTES.md:738` 的 `+85 ms` 是 `WC03` 那几趟的代表值；本趟 `+99 ms`，**同一族**，如实并列。）

**(c) 桥自带字段读数**（见 §3.2）—— 把"按什么尺寸发的"钉死。

---

## §3 判定点逐字段读数（**改前**）

### 3.1 两条既有诊断的时序（旧件 `feef049e9d0e313a`，取自 `WPF_LINUX_MIL_LOG`）
```
NOTE X11 Resize：HWND 0xc00004 → 800x600（将按新尺寸重渲）      ← WM 还原的 ConfigureNotify 被采纳
NOTE X11 Resize 生效：HWND 0xc00004 1280x1024 → 800x600（按新尺寸重渲）
  ★ 呈现尺寸变化（免采样）：… 已呈现 800x600 … 累计帧数 = 19     ← 第 19 帧：按 X 尺寸渲染（对）
NOTE X11 Resize：HWND 0xc00004 → 1280x1024（将按新尺寸重渲）   ← 第 4 跳落地
NOTE X11 Resize 生效：HWND 0xc00004 800x600 → 1280x1024（按新尺寸重渲）
```
⇒ 第 19 帧**正确**地按 `800x600` 渲染了；**紧接着的下一帧**又回到 `1280x1024`。

### 3.2 那一次回写的**全部输入**（`⟪GEOWRITE⟫` **只读**诊断，`MilPresentation.cs` 同一处，**不改行为**）
```
⟪GEOWRITE⟫ t=17:21:51.582 HWND 0xc00004 目标尺寸=1280x1024 来源=WindowRect
   X11=800x600 X11缓存=800x600 haveLast=True last=800x600 Owns=False 归属来源=WindowRect
   HwndTargetCreate=800x600 WindowRect=1280x1024 ⇒ 将 XResizeWindow(1280,1024)
```
**四件事一次钉死**：
1. `来源=WindowRect` ⇒ 要写回的尺寸来自 **MIL 侧** `target.WindowRect = 1280x1024`（**过期**）；
2. `haveLast=True ∧ last=800x600 = xw` ⇒ **"X 尺寸变化"这个边缘已经被消费** ⇒ 既有的
   "X 尺寸优先"分支（`:1052`）**不再触发** ⇒ `width/height` 落回过期值。**机制确认，未改判。**
3. `Owns=False` ⇒ 这是**包装别人的窗**（全仓唯一创建点 `MilPresentation.cs:561` 的
   `X11PresentationTarget.WrapExisting`）⇒ **呈现层在写一扇它并不拥有的窗的几何**；
4. `HwndTargetCreate=800x600` 而 `WindowRect=1280x1024` ⇒ **托管侧并非全然不知**，
   只是 `WindowRect` 那一份没跟上 ⇒ 桥"选错了权威"。

### 3.3 复现率（旧件）
| 批 | 装置 | 腿数 | 红（`r_ok2=0`） |
|---|---|---|---|
| `W134A-B1` | `SHIM=bd037229be8db4f6`（历史件） | 3 | **2** |
| `W134A-D1` | `SHIM=a6365183fa6d26b9`（**现行冻结**） | 3 | **3** |
| `W134A-A1-OLD` | `SHIM=a6365183fa6d26b9`，与 NEW **交替** | 12 | **12** |
⇒ **复现不了的问题不存在**；且**现行冻结世代上也照样红**（不是"只有历史件才红"）。

---

## §4 修法（逐处 diff）

### 4.1 一处改动，两个分支
**文件**：`src/WpfGfx.Linux/Interop/MilPresentation.cs`（`PresentTarget`，`:1082` 起）

**before → after（源级 sha16）**：`8b44b61f944aeeaa` → **`a5ecf1a8faaa2a00`**
（`X11Window.cs`／`X11PresentationTarget.cs` **未动**：`ea6c653493f05a93`／`9861117f89383476`）

```csharp
// ── 改前（一行）──────────────────────────────────────────────────────────
if (presentation.Width != width || presentation.Height != height)
    presentation.Resize(width, height);

// ── 改后（同一处；完整逐字见下文文件，此处给形状）────────────────────────
if (presentation.OwnsWindow)
{
    // 自己建的窗（M1 / HelloMil 路径）：呈现层**就是**几何主人 ⇒ **逐字不变**
    if (presentation.Width != width || presentation.Height != height)
        presentation.Resize(width, height);
}
else if (presentation.Width > 0 && presentation.Height > 0 &&
         (presentation.Width != width || presentation.Height != height))
{
    // 接窗路径：**只读尺寸、不写几何**；以 server（X）为准渲染 ＋ 大声记一行
    MilDiagnostics.Note(
        $"[GEOWRITE-SUPPRESSED] HWND 0x{(long)hwnd:x} 接窗路径**不回写 X 几何**：" +
        $"MIL 侧 {width}x{height}（来源={sizeSource}）≠ X 侧 " +
        $"{presentation.Width}x{presentation.Height} ⇒ 以 X 为准渲染" +
        "（几何归窗口主人 HwndWrapper→shim→WM）");
    width = presentation.Width;
    height = presentation.Height;
    sizeSource = "X11（接窗路径：server 为准，呈现层不回写几何）";
}
```
改后源码里**同一位置**附了约 30 行注释，逐字记入**两份仪器证据链**、`_lastXSize` 一次性消费的机制、
以及"为什么真正的尺寸变化不受影响"。**没有删任何既有守卫/断言**；`_lastXSize` 的既有语义**一字未改**。

### 4.2 为什么是这个修法（三条，都可反驳）
1. **本桥只包装别人的窗**：全仓唯一创建点 = `MilPresentation.cs:561` 的 `WrapExisting` ⇒ 真应用里 `OwnsWindow` **恒为 false**。
   ⇒ 呈现层**从来没有**对真应用窗口的几何所有权；那条回写是**越权**（`TASK-0210` 的标题就叫「**接管**」）。
2. **几何同步的正确一侧是窗口主人**：只有 `HwndWrapper → Win32 shim → WM` 知道标题栏、frame extents、
   工作区与最大化策略。呈现层硬写 `1280x1024` 正是"和 WM 打架"。
3. **"真正的尺寸变化仍到得了 X"不受影响**：它走的是 shim 的
   `SetWindowPos/MoveWindow → wpf_x11_move_resize`（`WC03` §3.2 已实测到这条链），**从来不是**本方法 ——
   本方法**只在"MIL 与 X 不一致"时才动手**，而那正是不一致的两种情形之一（另一种是启动期一次对账，见 §6 `Z2` 的残留边界）。

### 4.3 保留的"大声"（`M3` 精神）
新分支**无条件**打一行 `[GEOWRITE-SUPPRESSED]`（走 `MilDiagnostics.Note → Trace → 文件汇`，**不受 `_traceBudget=400` 限制**
—— `TraceToFile` 在预算检查**之前**调用）。以后任何一次"MIL 与 X 不一致"，都**看得见**，不会静默。

---

## §5 三态 ＋ 检测力自证 ＋ 两极化

### 5.1 检测力自证（`D-G89`/`D-G97`：不许用恒真谓词）
| # | 自证 | 现场读数 |
|---|---|---|
| ① | **装置三条件**：WM 真在场 | `_NET_SUPPORTING_WM_CHECK` ⇒ `0x2000ae`；`xwininfo` 该 id ⇒ `Xfwm4`；`_NET_SUPPORTED` = 78 原子含两个 `MAXIMIZED_*`；客户窗 `0xc00004` 的 frame 是**另一个**窗口（**真 reparent**） |
| ② | **还原真发生** | `xobs` 时间轴 `1280x1024 → 800x600`，且 `EVT ConfigureNotify send_event=0` |
| ③ | **请求真发出** | 协议台账命中（§2.3a），**不是**"没拦到" |
| ④ | **仪器两件都在**（`TASK-0210` 判据逐字要求） | 协议级 `xwrap.so`（**syscall 级**，`b5c1c1dbc4c0f13d`）＋ 符号级 `backtrace()+dladdr()`（`WC03` 的 `+0x131b36` 帧就是它打出来的）—— **两件都逐腿打 sha16** |
| ⑤ | **正控：真正的尺寸变化仍到得了 X** | 24/24 腿 `m_ok=1`（双击标题栏 ⇒ `1280x1024@+0+0` ∧ 两个 `MAXIMIZED_*`） |
| ⑥ | **截断对照（假绿探测器）** | `WC03` 已做（线上换等长 `NoOperation` ⇒ 5 条里 4 条转绿）；本件**未重做** ⇒ 见 §9 `NOINFO` |

### 5.2 承重（确定性判据）—— `M1:R2` 臂，旧/新**交替**，每趟全新进程树
| 判据 | 旧件 `feef049e9d0e313a` | 新件 `4e25e4b27d4d5ae1` |
|---|---|---|
| **① 协议台账那条请求命中数**（`opcode=0x0c ∧ win=0xc00004 ∧ mask=0x000c ∧ 1280x1024`） | **12/12 腿命中（1 次/腿）** | **0/12 腿命中（合计 0 次）** |
| **② `xobs` 时间轴跳序列** | **12/12 为 `800x600→1280x1024→800x600→1280x1024`（四跳）**，末态 `1280x1024` | **12/12 为 `800x600→1280x1024→800x600`（三跳，无第 4 跳）**，末态 `800x600` |
| **③ 桥侧大声行** | 0 条 `[GEOWRITE-SUPPRESSED]`（改前无此行）；对应位置是**真发** `XResizeWindow` | **15 条**（1–2 条/腿），逐腿原文见 §6 `Z4` |
| ④ `r_ok2`（支撑项，**不作主判据**） | **12 红 / 0 绿** | **0 红 / 12 绿** |

⇒ **`§2 三态` 判绿**：该请求**在红腿上消失**，且几何**不再改回最大化几何**（末态 = 基准 `800x600`）。

### 5.3 两极化（**源级 ＋ 件级两层，件级逐字节**）
| 步 | 读数 |
|---|---|
| ① 源**逐字节复原** | `src/WpfGfx.Linux/Interop/MilPresentation.cs` ⇒ **`8b44b61f944aeeaa`**，`cmp` 对备份 **`SRC_IDENTICAL=YES`** |
| ② **重建** | 件级 ⇒ **`feef049e9d0e313a`（`ARTIFACT_IDENTICAL=YES`，`cmp` 逐字节相等；5,028,208 B）** |
| ③ 用该件跑腿 | `POL2-OLD-1/2`：`BRIDGE=feef049e9d0e313a`、**`CFG_1280_1024_HITS=1`**、`r_ok2=0`（**红回来**） |
| ④ 放回修法 ＋ 重建 | 件级 ⇒ **`4e25e4b27d4d5ae1`**（**独立复现**，不是拿旧产物） |
| ⑤ 用该件跑腿 | `POL2-NEW-1`：`BRIDGE=4e25e4b27d4d5ae1`、**`CFG_1280_1024_HITS=0`**、`r_ok2=1`（绿） |
| ★ **建设性可复现（独立一格）** | 本件另做过一次 **pristine 源 → 重建** ⇒ **逐位复现 `feef049e9d0e313a`**（`BUILD_REPRO=YES`）⇒ 件级反极性是**逐字节**的，不是"近似回到旧形态" |
| ⚠️ **仪器陷阱（如实记，见 §8 #1）** | 第一次做②时**假成立**：`cp -p` **保留了 mtime**（`2026-09-19 20:32`，**早于**上次构建输出）⇒ MSBuild 增量判定"无需重编" ⇒ **静默用了旧产物**（`4e25e4b27d4d5ae1`）。**修法 = `touch` 强制重编**，表格里②③是 `touch` **之后**的读数 |

**两臂同刻（`PREREG-TEMPLATE` ①）逐字满足**：同一装置、同一会话段、**只换一个件**
（`bridge` 一个字节不同，`SHIM=a6365183fa6d26b9` 全程未变）、两臂**交替**、两个件都在跑之前带 `sha256sum` 前置断言
（`leg.sh` 逐趟印 `BRIDGE=`／`SHIM=`，现场现算）。

---

## §6 零回归（**逐格**）

### 6.1 `R_GATE`（修后，**新件在位**——由装置自报 `APP_ART bridge=4e25e4b27d4d5ae1` 证明）
```
R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0 popup=1 px_open=19449 px_closed=577
          sabotage=none win=938x938 mem_mb=5452 win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f src=device
R_GATE 仪器 件：win32shim=a6365183fa6d26b9 pc=722e0ab8205b7c3f pf=4973bcb28e331cf0 wb=2e4e46e539a72cd7
                bridge=4e25e4b27d4d5ae1 probe=5c461dd219b220e2 mem_mb=5452 sabotage=none src=device
```
**与 `#53` 代同件基线逐字段比**（基线取自收尾链读数）：

| 字段 | 基线（`#53` 代，`win32shim=a6365183fa6d26b9`） | 本件 | 判 |
|---|---|---|---|
| `crit` | `13/13` | `13/13` | **同** |
| `clicks`/`ok`/`red`/`noinfo` | `11`/`13`/`0`/`0` | `11`/`13`/`0`/`0` | **同** |
| `popup` | `1` | `1` | **同**（`D-G54` 弹窗路径**不回归**） |
| `px_open`/`px_closed` | `19449`/`577` | `19449`/`577` | **同**（**逐像素**同） |
| `sabotage`/`win` | `none`/`938x938` | `none`/`938x938` | **同** |
| `win32shim`/`pc` | `a6365183fa6d26b9`/`722e0ab8205b7c3f` | 同 | **同** |
| `mem_mb` | `5785` | `5452` | **不同**（内存读数，**非判据格**） |

⇒ **除 `mem_mb` 外逐字段相同** ⇒ 按主控口径「任何一格与基线不同 ⇒ 停手报我」：**判据格无一不同**，
唯一不同项是 `mem_mb`（装置自报的 `MemAvailable`，波动量，**不在 13 格里**）⇒ **不上报停手**，但**如实列出**。

⚠️ **`pf` 一处如实记**：本趟 `pf=4973bcb28e331cf0`，而更早世代（`~/w133a`/`~/w131a` 的 `APP_ART`）读到 `358136b0c806ee88`。
`pf` 件 mtime = `2026-09-23 12:27:25`（**早于我开工 17:13**）⇒ **不是本件所动**（本件只改 `src/WpfGfx.Linux/**`）。
`R_GATE` 的**判据行本身不含 `pf`**，且 `crit=13/13` ⇒ 判词不变；此处只作**账目披露**。

### 6.2 `Z1–Z4`（主控指定新增四格，**先写于 `criteria.md §10` 再取数**）
| 格 | 内容 | 读数 | 判 |
|---|---|---|---|
| **`Z1`** | **真尺寸变化仍到得了 X** | 24/24 腿 `m_ok=1`（`AFTER_M1` = `1280x1024@+0+0` ∧ 两个 `MAXIMIZED_*`） | **成立** |
| **`Z2`** | **渲染按 X 尺寸** | 新件 12 腿的**末次「已呈现」尺寸 = `800x600`**（序列 `800x600 → 1280x1024 → 800x600`）；抑制行之后**再无** `1280x1024` 呈现；对照旧件 12 腿的末次呈现**全为 `1280x1024`** | **成立** |
| **`Z3`** | **MIL 侧布局是否跟着收敛** | ⚠️ **不收敛**：新件 12 腿**每一次**抑制行都写着 `MIL 侧 1280x1024（来源=WindowRect）≠ X 侧 800x600`（同一字面、12/12 腿）⇒ `target.WindowRect` 在观察窗内**恒为过期的 1280x1024**。**但**两条旁证都指向"窗真的还原了"：① X 侧末态 `800x600`；② **托管侧布局自报** `[GEO] Button#ButtonRestore scr=703,1`（**基准槽位**；`W124A` §4 记红腿为 `1183,1`＝最大化槽位）。**影响面**：`WindowRect` 这份过期值**唯一的外作用就是那条回写** ⇒ 修后它**不再有对外作用**，渲染尺寸取 X（`800x600`）；**残留** = 若将来有别处按 `WindowRect` 布局，会看到过期值 | **如实记：不收敛**；其成因（`WM_SIZE → UpdateWindowSettings` 链）**在写域外 ⇒ `NOINFO`** |
| **`Z4`** | **`[GEOWRITE-SUPPRESSED]` 逐腿计数** | 新件 12 腿：`1,2,2,1,2,1,1,1,1,1,1,1` ⇒ **合计 15**；旧件 12 腿：**0**（该位置的形态是**真发** `XResizeWindow`，由协议台账 12/12 命中证明） | **如实报** |

### 6.3 权威件与导出数
| 项 | 值 |
|---|---|
| native 权威件 `libwpfwin32.so` | **`a6365183fa6d26b9`**（**本件未动**，327,512 B） |
| **native 导出数** | **547**（`nm -D --defined-only … \| wc -l`，与基线同；本件不新增导出） |
| `D-G83` 四格 | **`NOINFO`（未跑）** —— 装置在另一条车道的 `~/w89a/bin/**`，**不许**写"应仍 PASS" |
| `D-G105` 几何守卫 | 本车道自起 Xvfb 一律 `1280x1024x24`（`:221`，现场 `DIMS=1280x1024` 自证） |
| **判据件自检** | `bash build/MilBridge/tools/r-gate-step.sh --selftest` ⇒ **`R_GATE_SELFTEST=PASS cases=21 pass=21 fail=0 crit_total=13`**；`ST_ATTEST=PASS self=…r-gate-step.sh sha16=aa9d7188b6b01a2f（自测期间本件未变）` |

---

## §7 `M1:R2` 臂红率与功效（**趟数与功效先写**，`D-G99`）

### 7.1 先写的口径（`criteria.md §6`，写入时刻 17:15:32，早于第一趟腿）
- 旧件红率取**保守** `p₀ = 0.80`（`W124A` 实测 88.9%、`WC03` 80%）；新件目标 `p₁ ≤ 0.10`。
- **`N = 12`/臂**；`p₀ = 0.80 ⇒ P(≥1 红 in 12) = 1−0.2¹² = 0.99999999`（**检测力足够**）；
  `0/12` 单侧 95% 上界 = `1−0.05^(1/12) = 22.1%`。
- **提前收条件**：新件连续 6 趟 0 红 ∧ 旧件同时段有红 —— **未触发**（本件跑满 12 对）。
- **分母口径（`D-G94`）**：只算"真尝试过的趟"；`invalid:*`／应用没起来／`HEAVYSLOT=NOINFO`／`MAXHOLD_KILL` **不入分母**。

### 7.2 实跑与读数
| 臂 | 计划 | 实跑 | 入分母 | 红（`r_ok2=0`） | 绿 | 红率 |
|---|---|---|---|---|---|---|
| 旧件 `feef049e9d0e313a` | 12 | 12 | **12** | **12** | 0 | **100%** |
| 新件 `4e25e4b27d4d5ae1` | 12 | 12 | **12** | **0** | **12** | **0%** |

**无一趟作废**（24/24 有 `RESULT` 行、`rc=0`、`HEAVYSLOT=MEMOK`、无 `MAXHOLD_KILL`）。

### 7.3 判据件（`build/MilBridge/tools/regression-decision.py`，`1eda9e3575960cba`）
```
（按实跑方向：--old 12/12 --new 0/12 --pairs 12 --pair-old-only 12 --same-time
   --old-sha16 feef049e9d0e313a --new-sha16 4e25e4b27d4d5ae1 --old-repro yes
   --planned-legs 12 --planned-power 0.999 --alt-old 0.80 --alt-new 0.00）
REGRESSION_DECISION=REGRESSION   REGDEC_RC=0
REGDEC_FISHER p=0.000001 two_tailed=yes method=hypergeometric-le-observed
REGDEC_GATES same_time=yes sha16=yes paired=yes repro_input=yes plan=yes
REGDEC_SUBKIND=rate-aggravated
```
⚠️ **方向如实记（不许硬套）**：本工具**没有 `rate-mitigated` 支路** —— `--old-repro=yes ∧ 显著` 一律打成
`REGRESSION / rate-aggravated`，其理由串逐字是"本波把速率**显著加重**"。本件方向**相反**（红率 `12/12 → 0/12`，**减轻到零**）
⇒ **该 subkind 标签不适用于本件**；本件取用的是它的**四要件**与 **Fisher 双尾 `p = 7.396e-07`**。
**反向框架（把"缺陷件"当新臂）**给出语义正确的那一支：
```
（--old 0/12 --new 12/12 --pair-new-only 12 --old-repro no --alt-old 0.00 --alt-new 0.80）
REGRESSION_DECISION=REGRESSION   REGDEC_SUBKIND=deterministic-new-only
REGDEC_REASON reason=deterministic-new-only(fisher_p=7.396e-07≤alpha；新臂 12/12 **每腿都红** ⇒ 确定性复现 ∧ 旧件 0/12)
REGDEC_CI0_OLD 0/12 的单侧95%上界=0.2209
```
⇒ 两框架的 **Fisher 同一**（`p = 7.396e-07`）；差异只在工具沿用的**方向标签**。**如实并列，未择一美化。**

### 7.4 逐趟终表（24 趟）
见 §10 附录（逐趟 `BRIDGE`／`r_ok2`／`CFG_1280_1024_HITS`／跳序列／末态几何／`[GEOWRITE-SUPPRESSED]` 计数）。

---

## §8 世代影响（**逐字**）

| 项 | 旧 | 新 | 说明 |
|---|---|---|---|
| **源级** `src/WpfGfx.Linux/Interop/MilPresentation.cs` | `8b44b61f944aeeaa` | **`a5ecf1a8faaa2a00`** | 本件唯一动的源 |
| **桥位** `bridge`（`wpfgfx_cor3.so`） | `feef049e9d0e313a` | **`4e25e4b27d4d5ae1`** | **5,028,208 B 不变** |
| `win32shim` | `a6365183fa6d26b9` | **`a6365183fa6d26b9`（未动）** | 本件不碰 native |
| native 导出数 | 547 | **547** | 不变 |
| `pc`/`pf`/`wb` | `722e0ab8205b7c3f`/`4973bcb28e331cf0`/`2e4e46e539a72cd7` | 同 | 未动 |
| **`inputs_fp`** | **`5ac1e5349c7d1dec56fd7d8fe5dd8e9c1cb7c3b4052859f887e45c539981904f`** | **`bb8829c797128cd314a30f6c3abff6b3adfa00173f8fa35a9c0fbd6addec9fc4`** | ⚠️ **必动** |
| `BRIDGE_SRC_FP`（`build/bridge-src-fp.sh`） | `0a8f69b3c5fabd43`（78 件） | 见 §8.1 | 桥的编译输入指纹 |

### 8.1 `inputs_fp` 的**归因闭合**（不是"我猜是本件"）
- `inputs_fp` 用 **`close-wave.sh` 的 `fp_inputs()` 真函数**算（本件把该函数 `:70-230` **逐字抽出**成
  `~/w134a/bin/fp_inputs-real.sh` 原样执行，**没有重写一行**；`bash -n` 通过，161 行）。
- **覆盖面 = 149 件**（现算：把函数末尾的 `| LC_ALL=C sort | xargs sha256sum | sha256sum | cut` 换成 `| sort` 后清点）。
- **`find $(覆盖面) -newermt '2026-09-23 17:13'`（我开工时刻）⇒ 命中且仅命中 1 件**：
  **`src/WpfGfx.Linux/Interop/MilPresentation.cs`**。
  ⇒ 该位移 **100% 归本件**；**没有别的车道**在这个窗口里动过覆盖面内的件。
- ⚠️ **流程代价（写给收尾链）**：`src/WpfGfx.Linux/**/*.cs` 在覆盖面内（`close-wave.sh:115`）
  ⇒ 本件**必须排在 `IN_FP_0` 采样之前**，且收尾链要 **重钉世代（`repin-generation.py --why`）＋ 重冻 `#54`**。

### 8.2 六件照（`close-wave.sh:283-287` 的读数，现场现算）
`921ba9c65e9fb3be` `PresentationCore.HbTextLine.cs`｜`54289f72b81a432e` `DrawInstructionCensus.cs`｜
`ec11937e86bd3617` `SkiaRenderBackend.cs`｜`a9cc8762908b417a` `win32_core.c`｜
`9fa20864404ab01b` `win32_x11.c`｜`4ad790f4c26a907c` `win32_msg.c`（**均非本件所动**）

---

## §9 自伤／纪律偏离／`NOINFO`（**逐条，不辩解**）

### 9.1 自伤
1. ★ **`cp -p` ＋ 增量构建 = 静默空转**（本件最值钱的一条教训）：反极性第一步
   "复原源 ＋ 重建" **假成立** —— `cp -p` 把 mtime 保留成 `2026-09-19 20:32`，**早于**上次构建的输出
   ⇒ MSBuild 判定"无需重编" ⇒ **发布目录里仍是修法件 `4e25e4b27d4d5ae1`**。
   **症状**：`ARTIFACT_IDENTICAL=NO`，且用它跑的 2 趟腿**照常绿** —— 如果我不比对 `cmp`，就会把
   "复原后仍绿"读成"修法无效"或"现象不稳定"。**修法**：`touch` 强制重编（`§5.3` 的②③是 `touch` 之后的读数）。
   ⇒ **可复用纪律**：**凡"改源→重建→比件"的两极化，必须在改源后 `touch`（或显式清 obj），
   并且必须 `cmp` 到期望件，不许只看"构建 rc=0"。**
2. **诊断版编译错误两次**（`lastD.lw` 应为 `lastD.lwD`）：`publish-milbridge.sh` 打 `error CS1061` 且
   **`rc=1`、发布目录未被改写** ⇒ 第一次只是"没生效"，**未污染件**。如实记。
3. **一次 `awk`/`sed` 汇总表解析错位**（`BRIDGE=` 行取了第 2 个字段、`SEG` 跳数取成 0）：
   当场发现并用 `python3` 重写解析器 ⇒ 报告里的表**全部来自重写后的现算**，坏表**未采用**。
4. **`:221` 私有显示**：自起、按 PID 记账（`xvfb221.pid`／`xfwm221.pid`），**零 `pkill`／`killall`／`pgrep -f`**；
   收工按 PID 收（见 §9.4）。**未碰** `:0`/`:1`/`:97`/`:185`/`:188`；`leg.sh` 有**显示白名单硬闸**（非 `:22x` ⇒ `REFUSE_DISPLAY` `rc=9`）。

### 9.2 纪律符合性
- **零** `verify-all.sh`／`close-wave.sh`／`integration-wave.sh` 调用（`close-wave.sh` 只被**读**，
  且 `fp_inputs()` 是**抽出来单独跑**的，脚本主体**没执行**）。
- 重活**全走槽**（`--min-avail 1500`），`HEAVYSLOT=MEMOK` 全程；**同时只跑一个 `dotnet`**；
   全批无 `NOINFO reason=low-memory`、无 `MAXHOLD_KILL`。
- 改既有件前 `cp -p` 备份（`~/w134a/backup/`）；落盘**temp ＋ `mv`/`os.replace`**；`nlink=1` 现场核过（无硬链接写穿风险）。
- **写域外零写入**：`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`defect-registry-declared.tsv`／
  `verify-all.sh`／`close-wave.sh`／`known-red.json`／`ACCEPTANCE-BASELINE.md`／`build/shims/**`／
  `samples/**`／别人车道目录 —— **全部未碰**（`~/wc03/bin/**` 只读复用，一个字节未改）。

### 9.3 `NOINFO`（逐条，未猜）
1. **`D-G83` 四格未跑** —— 装置在 `~/w89a/bin/**`（别人车道，≈30 min 重活）；**不许**写"应仍 PASS"。
2. **截断对照（假绿探测器）未在本件重做** —— `WC03` 已证（5 条里 4 条转绿），本件**只复算未重做**。
3. **`target.WindowRect` 为什么不收敛** —— 成因在 `pc`/`pf`/shim 的 `WM_SIZE → UpdateWindowSettings` 链上，
   **在本件写域之外** ⇒ 只取读数、**不断言**（`§6.2 Z3`）。
4. **`+85 ms` 的精确值** —— `WC03` 记 `+85 ms`（`fd=135`），本件自家装置读到 **`+99 ms`**（`fd=132`）。
   两者**同族不同趟**；本件**没有**去解释这 14 ms 的差（可能与腿型/调度有关）⇒ `NOINFO`。
5. **`M1`(双击自绘标题栏) 88.9% vs `M2`(自带按钮) 9.1% 的臂间差成因** —— 本件**只跑 `M1:R2`**
   （判据靶臂），**没有**去定这个差（`WC03`/`W124A` 亦留作 `NOINFO`）。
6. **`pf` 的世代差**（`358136b0c806ee88 → 4973bcb28e331cf0`）**不是本件所动**（mtime 12:27:25 早于我开工），
   但**谁动的不明** ⇒ `NOINFO`（只作账目披露）。
7. **桥自带诊断 `X11 Resize：…（将按新尺寸重渲）` 在修后仍会重复打**（如 `800x600` 连打两遍）——
   本件**没查**它为什么重复（与本缺陷无关）⇒ `NOINFO`。

### 9.4 内存三值 ＋ 残留
| 项 | 值 |
|---|---|
| 开工（17:16）| **5252 MB** |
| 腿批内最低（逐腿自报）| **5159 MB** |
| 腿批内最高 | **5475 MB** |
| 收工 | **5269 MB** |
| `oom_kill` | **0**（`/proc/vmstat` 收工读数） |
| `:221` 残留 | **按 PID 收干净**：`killed xfwm221 pid=1083652`／`killed xvfb221 pid=1083534` ⇒ **`XDOWN_OK :221 gone`** |
| 本车道残留进程 | **0** —— 探活**逐 `/proc/<pid>/cmdline`**（**不用** `pgrep -f`）。收工扫到的两条"命中"是**别人的 shell 命令行文本**里提到了 `Xvfb :221`（W129A 的守望脚本、以及承载本句的 `bash -c` 自身），**不是**本车道的进程 |

---

## §10 附录：逐趟终表 ＋ 复算命令

### 10.1 24 趟终表（**全部现场现算**）
| tag | arm | `BRIDGE` | `r_ok2` | `CFG_1280_1024_HITS` | 跳序列（`xobs` `cgeo`，去相邻重复） | 末态 | `[GEOWRITE-SUPPRESSED]` |
|---|---|---|---|---|---|---|---|
| A1-OLD-1 | 旧 | `feef049e9d0e313a` | 0 | **1** | `800x600→1280x1024→800x600→1280x1024` | `1280x1024` | 0 |
| A1-NEW-1 | 新 | `4e25e4b27d4d5ae1` | 1 | **0** | `800x600→1280x1024→800x600` | `800x600` | 1 |
| A1-OLD-2 | 旧 | `feef049e9d0e313a` | 0 | **1** | 四跳 | `1280x1024` | 0 |
| A1-NEW-2 | 新 | `4e25e4b27d4d5ae1` | 1 | **0** | 三跳 | `800x600` | 2 |
| A1-OLD-3 | 旧 | `feef049e9d0e313a` | 0 | **1** | 四跳 | `1280x1024` | 0 |
| A1-NEW-3 | 新 | `4e25e4b27d4d5ae1` | 1 | **0** | 三跳 | `800x600` | 2 |
| A1-OLD-4…12 | 旧 | `feef049e9d0e313a` | 0 | **1**（每趟） | 四跳（9/9） | `1280x1024` | 0 |
| A1-NEW-4…12 | 新 | `4e25e4b27d4d5ae1` | 1 | **0**（每趟） | 三跳（9/9） | `800x600` | 1,2,1,1,1,1,1,1,1 |
| **合计** | | | 旧 **12 红**／新 **0 红** | 旧 **12 腿命中**／新 **0** | 旧 **12×四跳**／新 **12×三跳** | — | 旧 **0**／新 **15** |
| POL2-OLD-1/2 | 旧（复原重建件） | `feef049e9d0e313a` | 0／0 | **1**／**1** | — | `1280x1024` | 0 |
| POL2-NEW-1 | 新（再重建件） | `4e25e4b27d4d5ae1` | 1 | **0** | — | `800x600` | 1 |
| B1-M1R2-1/2/3 | 旧（历史 shim） | `feef049e9d0e313a` | 0／**1**／0 | — | 红：四跳；绿：三跳 | — | — |
| D1-M1R2-1/2/3 | 旧（现行 shim，诊断件） | `292e9532d093fbd9` | 0／0／0 | — | 四跳 | — | — |
| F1-M1R2-1…4 | 新（初版修法件） | `4e25e4b27d4d5ae1` | 1／1／1／1 | **0**（4/4） | 三跳 | `800x600` | — |

### 10.2 复算命令（**任何人都能重跑**）
```bash
# 判据
sha256sum ~/w134a/criteria.md | cut -c1-16                       # 67da3e7fbec24196（§10 后）
# 定位（三帧解符号）
objdump -d --start-address=0x131b36 --stop-address=0x131b76 \
  $R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so | tail -n +7
# 源级／件级
sha256sum $R/src/WpfGfx.Linux/Interop/MilPresentation.cs | cut -c1-16          # a5ecf1a8faaa2a00
sha256sum $R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so | cut -c1-16  # 4e25e4b27d4d5ae1
# inputs_fp（真函数；只抽 fp_inputs，不跑 close-wave.sh 主体）
cd $R && bash -c 'source ~/w134a/bin/fp_inputs-real.sh; fp_inputs'              # bb8829c7…
# 协议台账那条请求（逐趟）
grep -a "0c 02 05 00 04 00 c0 00" ~/w134a/run/W134A-A1-OLD-1/xwrap.log          # 1 命中
grep -a "0c 02 05 00 04 00 c0 00" ~/w134a/run/W134A-A1-NEW-1/xwrap.log          # 0 命中
# 桥侧大声行
grep -ac "GEOWRITE-SUPPRESSED" ~/w134a/run/W134A-A1-NEW-1/mil.log
```

---

## §11 ≤6 行大白话小结

1. 那条"窗口被还原 0.1 秒后又跳回最大化"的请求，**是桥（`wpfgfx_cor3.so`）自己发的**，
   发点在 **`MilPresentation.cs:1082-1083`**（执行者 `X11Window.cs:246` 的 `XResizeWindow` ＋ `:252` 的 `XSync`）。
2. 原因很朴素：桥判断"要不要把窗改成我想要的大小"时，**只看"X 尺寸这一帧变了没有"** —— 而变化只被**消费一次**；
   下一帧它就改用**自己那份已经过期**的 `WindowRect`（还停在最大化的 1280x1024），于是**和窗口管理器对着干**，把窗顶回去。
3. 修法只有一处：**这扇窗不是桥的，桥就不许改它的几何** —— 接窗路径上**只读尺寸、不写几何**，
   按 X server 报的尺寸渲染。桥自己建的窗（M1 路径）一个字没改。
4. **证据是硬的、而且是确定性的**：协议层台账里那条请求 **旧件 12/12 命中 → 新件 0 命中**；
   时间轴 **旧件 12/12 四跳 → 新件 12/12 三跳**（末态回到 800x600）。率（12 红→0 红）只当**支撑**。
5. **反极性逐字节闭合**：把源改回去重新编译，桥件**逐字节**回到 `feef049e9d0e313a` 且腿**全红**；
   放回来又**逐字节**回到 `4e25e4b27d4d5ae1` 且腿全绿。零回归：`R_GATE` **13/13**、弹出窗/像素数与基线**逐字段相同**。
6. **我没做到的**：`D-G83` 四格没跑（`NOINFO`）；**MIL 侧那份过期的 `WindowRect` 我没修**，只是让它不再有破坏作用
   （它的成因在 `pc`/`pf`/shim 那一侧，写域外）；还踩了一个坑并已入册 —— **`cp -p` 保留 mtime 会让增量构建静默空转**，
   第一次反极性因此是"假成立"，`touch` 重编后才是真读数。

---

## §12 报告自证（现场现算，两行口径）
（由 `~/w134a/bin/report-sha.sh` 写入；**不手抄**）

W134A-report.md 正文口径 sha16 = `af7204d58eb0b681`（＝ `head -n -2 build/MilBridge/W134A-report.md | sha256sum | cut -c1-16`，现场现算）｜**正文**（不含本行）FULL `sha256sum` = `af7204d58eb0b6818f372879307783ec0f37a5ad18bfa33e515c541f4e54d3cd`

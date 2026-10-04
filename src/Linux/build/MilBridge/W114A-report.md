# W114A 报告 —— 波 `#52` 第一条产品车道：**`D-G98`**（几何还原被自己的缓存写打回）

> **判决：该"缓存写"真因被证伪；`D-G98` 未修好。** 逐条见 §0／§5.2／§5.3／§8b。

> 车道 = **W114A**｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（本机 `R` **不是** git 仓库；推送不在本活里）
> 冻结基线 = **`#51` `38e67e834430d75c`**｜判据 = `~/w114a/criteria.md`（`582b376e5fd7bb49`，**先写**）｜预登记 = `$R/docs/WAVE52-PREREGISTRATION.md`（`834e370053f7ef2b`，**先写**）
> 取证件（**只读复用**）：`build/MilBridge/W112A-report.md`（口径 `head -n -2` = `3e1223d42b8f23a4`）§5.4/§5.5/§6.1/§6.5｜`~/w112a/criteria.md`（`d98380adfb2efce7`）｜`W105A-report.md`（`ae61f7f0dc5f25f5`）｜`W110A-report.md`（`d0fd37b8f74ac684`）
> **本报告 sha16 的口径**：`grep -v '^<!-- SHA16' 本文件 | sha256sum | cut -c1-16`（最后一行是自指行，剔除）

---

## §0 一句话判决（**结论在前，坏消息也在前**）

> ⚠️ **`D-G98` 没有修好。** 我按 W112A §6.5 落地了 `F1`＋`F2`（只动 native 源），
> 拿到了**承重的成对读数**（"`SWP_NOSIZE|SWP_NOMOVE` 的 `SetWindowPos` 落不落 X 写"：修前**每条腿恒 6 条**、38/38 腿；
> 修后**恒 1 条**、16/16 腿 —— **该位移是真的**），**可是那族红没有变化**：
> **修前 17 腿 1 红（5.9%）→ 修后 16 腿 1 红（6.2%）**，Fisher 双尾 **`p = 1.00`**。

**为什么会这样（本件最值钱的一句话）**：修后有一条红腿（`W114A-F-07`）**全趟只有 1 条 `XMoveResizeWindow`**
（还是启动那次真带尺寸的调用），窗口**照样**被打回最大化 ⇒ **"那次多余的几何写"不是 `D-G98` 的成因**
（连必要条件都不是）。旁证：红腿 `W114A-B-01` 的行序显示**被打回的通告早于**那次写，且那次写的内容与当时窗口值**相同**（空写）
⇒ **它是"被打回"的读数，不是它的原因**。
⇒ **本件推翻 W112A §6.1/§6.5 的最后一跳**（如实记，见 §5.3）。

**本件交付的是**：①真因定位被**证伪**（含两条独立读数）；②一个**可复用、免 `LD_PRELOAD`** 的机读指纹
（红腿 2/2 命中、绿腿 0/45 命中）；③两个**正确性**改进（对齐 Win32 语义）＋**零回归全绿**（`D-G83` 四格、`R-GATE 13/13`、导出 547）；
④**完成的两极化**（源逐字节复原 ⇒ 件逐位回 `8392fc09564779a1`、写条数回 6；重放补丁 ⇒ 件逐位回 `bd037229be8db4f6`）；
⑤真因的**首选嫌疑 ＋ 可直接派活的三条实验**（§8b）。

---

## §1 起点现场（**现场现算**，非手抄）

| 量 | 值 | 来源 |
|---|---|---|
| 冻结基线 | `#51`（`38e67e834430d75c`） | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` |
| 权威 `win32shim`（改前） | **`8392fc09564779a1`**（327,240 B，导出 **547**） | 现场 `sha256sum`／`nm -D --defined-only` |
| 源（改前） | `win32_core.c` = `e0cbc965772d06c1`｜`win32_x11.c` = `6477af56fdcfdf20`｜`win32_internal.h` = `e4f2de8d038e4780` | 现场 |
| **构建可复现性** | 用**当前源**跑 `bash src/WpfGfx.Linux.Native/build-shim.sh --all` ⇒ 产物 **逐位 == `8392fc09564779a1`**，导出 **547** | 现场 |

**构建链自证**：`build-shim.sh` 是**纯 `gcc`**（10 个 `.c`，**不用 dotnet**），槽内 `HEAVYSLOT=RELEASED rc=0 held=2s`。
⇒ 本件的"重编"是 2 秒级、零 dotnet 的操作；`integration-wave.sh` **从不编译 native**（W101A 的 `grep` 实证），本件按 `build-shim.sh --all`。

---

## §2 判据（**先写**，逐字见 `~/w114a/criteria.md`；本节只复述承重格）

| 格 | 内容 | 为什么它承重 |
|---|---|---|
| **`C1`** 主判据 | 那族在诊断腿上由 **红 2/16** 变 **红 0/N（N≥16）**；`L`＝`N/N`、`m_ok=1`＝`N/N`（证明**不是**靠"点击没落地"变绿）；`SUB=ii` 消失 | 直接对应缺陷条目 |
| **`C2`** ★**确定性**判据 | 逐腿数"来自 `SetWindowPos` 帧的 `XMoveResizeWindow` 写"条数：修前 **6**、修后 **1** | 红率只有 ~6% ⇒ `0/N` 的 95% 上界与修前点估计重叠；**"落没落这次写"是每腿 100% 的成对读数** |
| **`C3`** 零回归 | `D-G83` 四格 `VERDICT=PASS`；`R-GATE` `crit=13/13`；导出数 **547** | 写域纪律 |
| **`C4`** 反极性 | 源逐字节复原 ＋ 重编 ⇒ `win32shim` **逐位回 `8392fc09564779a1`**、`C2` **回 6**、那族**红回来** | 成对 |
| **`C5`** 弱数据标弱 | W112A 的"写＝最大化矩形 ⇒ 红 1/1；写＝基准 ⇒ 绿 0/14"是 **Fisher `p=0.067`** ⇒ **只作旁证** | 本件结论**不**建立在它上 |
| **`C6`** 口径 | `NOINFO` 既不算绿也不算红；`rc=127/126` ＝没跑过；每趟读数**必须绑 `SHIM=`** | 纪律 |

### 2.1 ★样本量（**先算好，不事后挑**）

修前红率（W112A 装置 2/16 = 12.5%）⇒ `0/N` 的 95% 单侧上界 `= 1-0.05^(1/N)`：
`N=16 → 17.3%`｜`N=24 → 11.7%`｜`N=30 → 9.5%`｜`N=40 → 7.2%`。
⇒ **只靠红率、`N=40` 才勉强把上界压到修前点估计之下** ⇒ 如实写明**红率不是承重判据**；落地后仍取 `N=24`（硬下限 `≥16`）当旁证。

### 2.2 装置（**逐字节相同 ＋ 2 处公告差异**）

| 件 | sha16 | 说明 |
|---|---|---|
| `~/w112a/bin/leg-diag.sh`（W112A 的腿） | `061d0ec73c4b57cf` | **只读复用** |
| `~/w114a/bin/leg.sh`（本车道的腿） | `60f6b413ca740525` | 与上者 `diff` **只有 1 行**：`APP`/`OUT` 改指本车道（`APP` 可由 `W114A_APP` 指定）；**观测器、诊断开关、坐标算法、等待时长逐字未动** |
| `~/w114a/bin/innermost-leg.sh` | 现场算 | ＝ `leg.sh` **原样调用** ＋ **另加**本车道自写的**单时钟**观测器（见 §7） |
| `~/w112a/bin/libxgeomtrace.so`（写者归因） | `8f23232cb3dc53a8` | **只读复用**（`LD_PRELOAD`，不改产品件） |

**腿型**：一律 `M2×R2`（应用自带 Max 按钮 → 应用自带还原按钮），与 W112A 的 16 腿对齐。
**私有世界**：`Xvfb :188`（1280×1024×24）＋ `xfwm4`（**本车道自起、按 PID 收**）。

---

## §3 `D-G98` 的复现（**当面**，修前）

### 3.1 逐字读数（`W114A-B-01`，**第 1 条腿就红**）

```
probe.txt: SHIM=2a297d6fee8be389(327240) BRIDGE=feef049e9d0e313a PC=56ee75ced8d6aece PF=2a5b7641f6fba0fb WB=2e4e46e539a72cd7
           T0 window=8388612 BASE geom=800x600@+0+0 state=[_NET_WM_STATE_FOCUSED] START_MAX=0
           AFTER_M2 state=[…MAXIMIZED_HORZ, …MAXIMIZED_VERT, …FOCUSED] geom=1280x1024@+0+0 m_ok=1
           AFTER_R2 state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok=0  (基准=800x600@+0+0)
           AFTER_R2_SETTLED state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok2=0 frame=0x200296 fgeom=1280x1024@+0+0
```
⇒ **类 ③（本族）**：`L` 成立、`¬is_max(S_settle)`、`G_settle == MAXG`，两拍都满足。

### 3.2 `SUB=ii`（W112A 的事件级观测器，`watch.txt`）

```
(t=5.761) ConfigureNotify frame  800x600@+0+0     ← WM 把 frame 收回基准
(t=5.761) ConfigureNotify client 800x600@+0+0     ← WM 真改客户区到基准
(t=5.761) PropertyNotify _NET_WM_STATE            ← 属性摘掉（窗态还原）
(t=5.819) SAMPLE client=800x600 frame=800x600 state_max=0   ← ★ **真的回到基准了**
(t=5.837) ConfigureNotify frame  1280x1024@+0+0   ← ★ **76 ms 后被打回**
(t=5.837) ConfigureNotify client 1280x1024@+0+0
(t=5.855) SAMPLE client=1280x1024 frame=1280x1024 state_max=0 ← 终态
```
⇒ **`③-ii`（还原后又被打回）**；`SUB=i`（WM 从未还原）**被排除**。

### 3.3 落地证据 `L`（**独立于判词**）与写者归因

`app.log` 里同拍的既有诊断通道（**只加环境变量，不改产品件**）：
```
[SHOW_DIAG] ShowWindow hwnd=0x800004 a=9 b=0                                        ← SW_RESTORE
[WINSTATE_DIAG] APPLY_WM_STATE hwnd=0x800004 maximize=0（我们发的 _NET_WM_STATE REMOVE）  ← 请求真的发出去了
```
`geomtrace.log`：**6 条** `XMoveResizeWindow`，**全部**来自 `SetWindowPos` 帧（符号翻名 `wpf_x11_move_resize+0x67`／`SetWindowPos+0x164`）：
```
(240,212,800x600) (240,212,800x600) (240,212,800x600) (240,212,800x600) (0,0,1280x1024) (0,0,1280x1024)
                                                                          ↑ 最大化那拍        ↑ 还原那拍=陈旧最大化矩形
```
⇒ 与 W112A §5.4/§5.5 **逐字同形**。

### 3.4 修前汇总（**38 腿**）

| 来源 | 腿数 | 红（`r_ok2=0`） | `m_ok=1` | `L=Yes` | `SetWindowPos` 帧写条数 |
|---|---|---|---|---|---|
| 本车道 `W114A-B-01..17`（`SHIM=2a297d6fee8be389`） | **17** | **1**（5.9%） | 17/17 | 17/17 | **6**（17/17 腿） |
| 本车道 `W114A-IN-01..06`（同上，带单时钟观测器） | **6** | 0 | 6/6 | 6/6 | **6**（6/6 腿） |
| W112A 的 `W112A-T-01..15`（**只读复用其日志**） | **15** | **1**（`T-05`） | — | — | **6**（15/15 腿） |
| **合计** | **38** | **2（5.3%）** | — | — | **6（38/38 腿）** |

`SUB` 分布（本车道 23 腿）：**`③-ii` 恰好只出现在红腿上**（1/1），绿腿一律 `none(已回基准)`（22/22）⇒ **判别式有牙**。

---

## §4 改了哪几处（**逐处**）

### `F1`（主修）`src/WpfGfx.Linux.Native/src/win32_core.c` → **`3117923a7c899e05`**（改前 `e0cbc965772d06c1`）

`SetWindowPos`（修前 `:1210`）那一处，`-1 行 / +21 行`（含 17 行注释）：

```c
-    wpf_x11_move_resize(hwnd, nx, ny, nw, nh);
+    if (!((flags & SWP_NOSIZE) && (flags & SWP_NOMOVE)))
+        wpf_x11_move_resize(hwnd, nx, ny, nw, nh);
```

**依据（三层，逐条可查）**：
1. **Win32 语义**：`SWP_NOSIZE` 与 `SWP_NOMOVE` 同时置位时，`SetWindowPos` 对位置与尺寸**什么都不做**。
2. **上游调用者身份已定**（本仓 `win32_core.c:544-548` 已登记）：`WindowChromeWorker._ApplyNewCustomChrome()`
   的 `SetWindowPos(…, _SwpFlags)`，`_SwpFlags = FRAMECHANGED|NOSIZE|NOMOVE|NOZORDER|NOOWNERZORDER|NOACTIVATE`
   （`upstream/wpf/…/WindowChromeWorker.cs:28/246`）；另一条同标志族的是 `HwndStyleManager.Flush()`
   （`Window.cs:6845-6867`，实测标志 `0x37`）。**两者都是"我重算了窗框"的声明，几何意图为零。**
3. W112A §6.5 **首选**（"最小、最窄"）。

**改前为什么错**：`nx/ny/nw/nh` 在 `SWP_NOMOVE`/`SWP_NOSIZE` 分支里**全部取自窗口表缓存**（`:1184-1189`），
而 `:1210` **无条件**落一次真实 X 写 ⇒ 一次"本应无副作用"的调用被落成**写缓存矩形**的几何写。
`wpf_x11_move_resize` 是 `XMoveResizeWindow` **＋ `XFlush`**（`win32_x11.c:481-483`）⇒ 请求**立即上线路**。

**不动**：`win->x/y/width/height` 的自赋值（这两个位下是**恒等赋值**）；`SWP_FRAMECHANGED` 的装饰逻辑；
`WM_SIZE`/`WM_MOVE` 的派发条件（原本就有 `!(flags & SWP_NOSIZE)`／`!(flags & SWP_NOMOVE)` 守卫）。

### `F2`（同族并案）`src/WpfGfx.Linux.Native/src/win32_x11.c` → **`11142fbef049eb66`**（改前 `6477af56fdcfdf20`）

`case PropertyNotify` 支（修前 `:1435-1441`），**纯插入 ＋17 行**（不删任何行）：
派发 `WM_SIZE` 之前，用 `wpf_x11_query_geometry(h,…)` 的**现场几何**覆盖
`wpf_x11_sync_window_state` 交回的**陈旧缓存值**（后者来自 `wpf_x11_adopt_maximized` 的 `w->width/height`）；
取不到（窗口刚销毁）⇒ **回落**采纳值（**不拿 0 当"好读数"**）。

**依据**：W112A §6.5 **次选**；且隔壁 `CONFIGURE` 支**早就在用事件自带**的 `ev.xconfigure` 几何 ⇒ **同一个语义、两条路**。

### 世代位

| 位 | 改前 | 改后 |
|---|---|---|
| **`win32shim`** | `8392fc09564779a1` | **`bd037229be8db4f6`** |
| 导出数 | 547 | **547（不变；本件不加导出）** |
| `nm` 偏移 | `SetWindowPos@0x11c20`、`wpf_x11_move_resize@0x176c0` | `@0x11c40`、`@0x17700` |
| 编译告警 | — | **0**（`grep -icE "warning\|error"` = 0） |
| 其余八位 | `bridge`／`pc`／`pf`／`windowsbase`／`provider`／`wic_shim`／`hbtextline`／`dwf` | **逐位未动**（本件只重编 native） |

---

## §5 修后读数（**成对**）

### 5.1 ★`C2` —— 承重的确定性判据：**命中**（`P1` 成立）

| 腿批 | `SHIM` | 腿数 | `XMoveResizeWindow` 总数 | 其中来自 `SetWindowPos` 帧 | 帧翻名 | 写的内容 |
|---|---|---|---|---|---|---|
| 修前 `W114A-B-01..17` | `2a297d6fee8be389` | 17 | **6**（17/17 腿） | **6** | `wpf_x11_move_resize+0x67`／`SetWindowPos+0x164` | 4×`(240,212,800x600)` ＋ `(0,0,1280x1024)` ＋ 末条 |
| 修前 `W114A-IN-01..06` | 同上 | 6 | **6**（6/6 腿） | **6** | 同上 | 同上 |
| 修前 W112A `T-01..15`（只读复用） | 同上 | 15 | **6**（15/15 腿） | **6** | 同上 | 同上 |
| **修后 `W114A-F-01..16`** | **`bd037229be8db4f6`** | 16 | **1**（16/16 腿） | **1** | `wpf_x11_move_resize+0x67`／**`SetWindowPos+0x176`** | **`(240,212,800x600)`（只剩启动那次真带尺寸的 `a=20`）** |

⇒ **`6 → 1`，38/38 腿 → 16/16 腿，逐腿 100% 成立**。消失的正是 **5 条 `SWP_NOSIZE|SWP_NOMOVE` 的写**
（`a=567`×4 ＋ `a=55`×1）；保留的那 1 条是 `a=20`（`0x14 = NOZORDER|NOACTIVATE`，**真的带尺寸**）。
**`C2c` 也命中**：`[SHOW_DIAG]` 逐趟 **9 行**（`a=20`×1、`a=567`×4、`a=55`×1、`ShowWindow`×3），修前修后**逐字相同**
⇒ 守卫**只挡 X 写，不挡诊断与语义**。

### 5.2 ⚠️★`C1` —— 主判据：**未达成**（**这是本件最重要的一句话**）

| 臂 | `SHIM` | 腿数 | 红（`r_ok2=0`） | `m_ok=1` | `L=Yes` | `SUB=③-ii` |
|---|---|---|---|---|---|---|
| **修前** | `2a297d6fee8be389` | **17** | **1（5.9%）** | 17/17 | 17/17 | **1（＝那条红腿）** |
| **修后** | **`bd037229be8db4f6`** | **16** | **1（6.2%）** | 16/16 | 16/16 | **1（＝那条红腿）** |

⇒ **红率无可判差别**（Fisher 双尾 `p=1.00`；两者都只是"~6%"的两个点估计）。**`m_ok=1` 与 `L=Yes` 仍 `N/N`**
⇒ 不是"靠点击没落地变绿"；但也**不是变绿**。

**决定性的一条腿 `W114A-F-07`（修后、`SHIM=bd037229be8db4f6`）逐字**：
```
probe.txt : AFTER_R2 state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok=0   （基准=800x600@+0+0）
            AFTER_R2_SETTLED state=[_NET_WM_STATE_FOCUSED] geom=1280x1024@+0+0 r_ok2=0 frame=0x200854 fgeom=1280x1024@+0+0
geomtrace : XT … fn=XMoveResizeWindow a=240 b=212 c=800 d=600      ← **全趟只有这 1 条**（启动）
watch.txt : (t=5.982) client 800x600@+0+0 ← 基准回来了
            (t=6.061) frame+client **1280x1024@+0+0** ← **58 ms 后被打回**（`SUB=ii`）
```
⇒ **在"上一次多余几何写已经彻底不存在"的构建上，那族照样红。**
⇒ **`F1`（乃至 `F1`＋`F2`）对 `D-G98` 无效**。

### 5.3 因此：**推翻 W112A §6.1 的最后一跳**（如实记）

W112A §6.1 的链条是"那次 `SetWindowPos` 被落成真实几何写、写得是陈旧的最大化矩形、且排在 `REMOVE` 之后
⇒ WM 再顺从它把窗口改回最大化"。本件有**两条互相独立的读数**说明它不成立：

1. **机制读数（`W114A-B-01` 的行序，同线程顺序，无截断）**：被打回的通告（`CONFIGURE 1280x1024`）
   **早于**那次写；且那次写的内容与当时窗口值**相同**（＝空写）。
   **硬推理**：`CONFIGURE 800x600` 已把缓存置成 `800x600`，之后只有 `CONFIGURE 1280x1024` 能把它改回
   `1280x1024`，而第 6 条写的内容**正是** `(0,0,1280x1024)` ⇒ **那条写读到的是"已经被打回之后"的缓存**
   ⇒ **它是后果/读数，不是原因**（这也解释了任务书为何把 W112A §5.5 的 `p=0.067` 定为"只作旁证"：
   那个相关系数是**混淆的**，两种竞态走向在 tracer 上都表现为 `(0,0,1280x1024)`）。
2. **两极化读数（`W114A-F-07`）**：把那次写**彻底删掉**（`C2` 证明 6→1），那族**照样红**。

---

## §6 零回归（**成立**）

| 格 | 判据 | 读数（`SHIM=bd037229be8db4f6`） |
|---|---|---|
| `C3a` `D-G83` 四格 | 见下逐格 | **全绿** |
| `C3b` `R-GATE` | `R_GATE=PASS` ＋ `crit=13/13` | **`R_GATE=PASS crit=13/13 clicks=11 ok=13 red=0 noinfo=0`**（rc=0） |
| `C3c` 导出数 | 仍 **547** | **547**（修前/修后/反极性三态都是 547） |
| `C3d` 九位 | 只动 `win32shim` | 只动 `win32shim`（本件只重编 native，其余八位未重新构建） |

**`D-G83` 四格逐字**（观测面 = X 服务器自己的 `WM_NORMAL_HINTS`，`xprop` 现读）：

| 格 | 期望 | 实得 | 判 |
|---|---|---|---|
| `declared` | `maximum size: 667 by 500` | `program specified maximum size: 667 by 500` | ✅ |
| `minonly` | `minimum size: 521 by 417` | `program specified minimum size: 521 by 417` | ✅ |
| `undeclared` | `maximum size` **缺席** | 只有 `program specified minimum size: 1 by 1` | ✅ |
| `reg58`（旧错法形状 `1280 by 1024`） | **0 次** | 全部 `*.hints` 里 **0** 次 | ✅ |
| （另两个现场） | — | `late` = `667 by 500`；`sizecontent` = `667 by 500` | ✅ |

**装置自证**（裸 X 客户端 `xprobe-hints`，与 WPF/shim 无关）：`mode=max flags=PMinSize|PMaxSize`、`mode=nomin flags=PMinSize`
⇒ **装置有牙**（不是"读不出来"）。

---

## §7 反极性（**成立**）

1. `cp -p` 备份改前源（`~/w114a/backup/win32_core.c.before` = `e0cbc965772d06c1`、`win32_x11.c.before` = `6477af56fdcfdf20`）。
2. 落地 `F1`＋`F2` ⇒ 重编 ⇒ `win32shim` = **`bd037229be8db4f6`**（导出 547）。
3. **源逐字节复原**（`cp -p` 覆盖回改前内容，现场 `sha256sum` 复核 == `e0cbc965772d06c1`／`6477af56fdcfdf20`）
   ⇒ 重编 ⇒ **`win32shim` = `8392fc09564779a1`（逐位回改前权威值）**，导出 **547**。
4. 用该件跑反极性腿（`~/w114a/app-rp`，`SHIM=8392fc09564779a1`）⇒ 见下成对表。
5. **再前进**：重新落地 `F1`＋`F2` ⇒ 重编 ⇒ 断言回到 **`bd037229be8db4f6`**（往返闭合）⇒ **盘上留修后态**。

| 臂 | `SHIM` | `C2`（每腿来自 `SetWindowPos` 帧的写） | 红 |
|---|---|---|---|
| 修后 | `bd037229be8db4f6` | **1**（16/16 腿） | 1/16 |
| **反极性（源逐字节复原 ＋ 重编）** | **`8392fc09564779a1`** | **6**（**8/8 腿**） | 0/8（8 腿抓不到 6% 的红，**属预期**；`C2` 才是这里的承重格） |
| **再前进（重放补丁 ＋ 重编）** | **`bd037229be8db4f6`**（**逐位 == 第一次落地值**） | 源 sha16 也回到 `3117923a7c899e05`／`11142fbef049eb66` | **往返闭合** |

**反极性八腿逐腿**：`W114A-RP-01..08` 全部 `SHIM=8392fc09564779a1`、`m_ok=1`、`L=Yes`、
`r_ok2=1`、`XMoveResizeWindow` 总数 **6**（`SetWindowPos` 帧）⇒ **写条数 `1 → 6` 成对成立**。
**盘上最终态 = 修后态**（`win32shim` ＝ `bd037229be8db4f6`，导出 547，源 ＝ 补丁态）。

---

## §8 `NOINFO`（**既不算绿也不算红**）

1. ★**"被打回"的那条客户端请求到底是哪一条：`NOINFO`。** 本件**没取到**。
   - **已排除**：`XMoveResizeWindow`／`XMoveWindow`／`XResizeWindow`／`XConfigureWindow`（tracer 全覆盖；
     `F1` 之后**一条都没有**，红腿 `F-07` 照样红）⇒ **几何写不是原因**。
   - **已排除**（W112A 的读数，本件沿用）：纯 X 装置（`xmimic`）"add/remove `_NET_WM_STATE`" **0/40 红**、
     正对照 4/4 红 ⇒ **WM 单靠自己不做这件事**；候选 (d)（`maximum size` 提示）40＋16 趟全趟缺席。
   - **本件试了但没取到**：我自写了**单时钟**观测器 `~/w114a/bin/w114watch`（`CLOCK_MONOTONIC`，
     与 `libxgeomtrace.so` **同一个时钟** ⇒ 客户请求与服务端通告**可直接对齐**）＋ `~/w114a/bin/correlate.py`，
     跑了 **6 条 innermost 腿**，**一条红都没出**（6% 红率 × 6 腿 ⇒ 期望 0.36 条）⇒ **没有可对齐的红腿**。
   - ➡️ **剩余候选（我的看法，标 `NOINFO`，不敢写成结论）**：红绿两态在 **X 事件层与 shim 诊断层都逐字同形**
     （见 §5.2/§8.2），差别**只在时序**；而唯一在"被打回"之前落地、且**是我们发的非几何请求**只有三条：
     `_MOTIF_WM_HINTS`（`wpf_x11_set_decorations(0)`，`SWP_FRAMECHANGED` 那条路上的"顺手刷新"）、
     `_NET_WM_STATE` REMOVE、以及 `WM_NORMAL_HINTS`（`#51` 的 `wpf_hints_publish`）。
     其中 `_MOTIF_WM_HINTS` 是**唯一 xmimic 不会发**的一条 ⇒ 它是**首选嫌疑**。
2. **`F2` 的独立射程**：`NOINFO`（本件把 `F1`＋`F2` 一起落地，没有单独跑 `F2`-only 臂；
   由于两者合起来都**没修好**缺陷，拆分改变不了结论）。
3. **无 WM（裸 `Xvfb`）下的约束效力**：本族靠 WM 发起 ⇒ 不适用 ⇒ `NOINFO`。
4. **`R1`（双击标题栏）臂**：本件只跑 `R2`（与 W112A 装置对齐）⇒ `NOINFO`。
5. **`W114A-IN-*` 六腿的 `SUB`**：用我的观测器时判不出（它不采样 `state_max`）⇒ 该 6 腿的 `SUB` 记 `NOINFO`
   （**红率与写条数仍然有效**）。第二版已把"SUB 时间线优先用 W112A 的 `watch.txt`"写进判决器。

### 8.2 红绿两态**同形**的逐字证据（为什么"最内层"难判）

`WINSTATE_DIAG` 序列 diff：**两条红腿（`B-01`／`F-07`）之间逐行相同**；红腿与绿腿（`B-02`）**只差末尾 2 行**
——红腿多出 `CONFIGURE 1280x1024 ⇒ WM_SIZE sizecode=0`（＝被打回那一拍本身）。
X 事件层（`watch.txt`）同样：`B-01`／`F-07`（红）与 `B-02`／`B-03`（绿）在 `_MOTIF_WM_HINTS` →
`_NET_FRAME_EXTENTS`×2 → `_NET_WM_ALLOWED_ACTIONS` → frame/client `800x600` → `_NET_WM_STATE` 这一段**逐字同形**，
红腿只多末尾一对 `ConfigureNotify 1280x1024@+0+0 send_event=0`。

### 8.3 附带产出：**可复用的机读指纹**（不需要 `LD_PRELOAD`、不需要观测器）

`~/w114a/bin/fingerprint.py`：只看 `app.log` 里**既有**的诊断通道
⇒ 指纹 = "**最后一次 `APPLY_WM_STATE maximize=0`（我们发的 REMOVE）之后，先见到基准尺寸、再见到最大化尺寸**"。
**判别力实测：红腿 2/2 命中、绿腿 0/45 命中**（45 = `B` 16 ＋ `IN` 6 ＋ `F` 15 ＋ `RP` 8 的绿腿）。

---

## §8b 这一步修好了到哪一格、还差什么（**逐条**）

**修好了（有成对读数）**：
- `F1`：`SWP_NOSIZE|SWP_NOMOVE` 的 `SetWindowPos` **不再落 X 几何写** ⇒ 每次"还原"少 **5 次**多余的
  `XMoveResizeWindow`（`C2`：6 → 1，38/38 腿 → 16/16 腿）。这是**真**的、可复算的位移，而且它本身是**正确性**修法
  （对齐 Win32 语义与上游 `WindowChromeWorker`/`HwndStyleManager` 的调用意图）。
- `F2`：`PropertyNotify` 支派发 `WM_SIZE` 的 lParam 改用**现场几何**（不再用陈旧缓存）。
- 零回归成立（`D-G83` 四格 ＋ `R-GATE 13/13` ＋ 导出 547）。

**没修好**：
- **`D-G98` 本身仍然红**（修后 16 腿 1 红 ≈ 6.2%，与修前 17 腿 1 红 ≈ 5.9% 无可判差别）。
- ⇒ **本件交付的是"真因定位被推翻 ＋ 一个可复用的判据/指纹 ＋ 两个正确性改进"，不是"`D-G98` 已修"。**
  **不许**把本件读成"`D-G98` 已修"。

**还差什么（按我判断的价值排序，都能直接派活）**：

| # | 下一步实验 | 为什么它能定罪 | 成本 |
|---|---|---|---|
| **N1** ★ | **改 `wpf_x11_set_decorations`：值没变就**不写** `_MOTIF_WM_HINTS`**（现在每个运行期 `SWP_FRAMECHANGED` 都会**重写**一次 ⇒ 值"幂等"、**X 流量不幂等**） | `_MOTIF_WM_HINTS` 是**唯一 `xmimic` 不发**、而我们在"被打回"之前必发**的非几何请求**；且红绿两态在事件层同形 ⇒ 它是首选嫌疑 | 改 ~10 行 ＋ 重编 2 s ＋ **≥40 腿**（≈25 min）；红率 6% ⇒ 要 40 腿才把 `0/40` 的 95% 上界压到 7.2% |
| **N2** | **纯 X 高功效探针**：把 W112A 的 `xmimic` 那族扩成"unmaximize 的同时插一条 `XChangeProperty(_MOTIF_WM_HINTS)`"，跑 **200+ 趟** | 纯 X ⇒ **零 dotnet、零槽、≈2 s/趟**；有/无 MOTIF 写两臂对照 ⇒ 若 clobber 只在**有**的那臂出现，直接定罪（`0/200` 的 95% 上界 1.5%） | 写 ~120 行 C ＋ 7 min 跑 |
| **N3** | **扩写者归因**：把 `libxgeomtrace.so` 的拦截面从"几何写"扩到 `XChangeProperty`／`XSendEvent`／`XSetWMNormalHints`／`XSetInputFocus`／`XRaiseWindow`，配 `~/w114a/bin/w114watch`（**单时钟**，本件已写好）在**红腿**上对齐 | 能直接答"被打回之前 10 ms 内上线路的那条请求是什么"；本件**只差一条红腿**（6 条 innermost 腿一条没红） | 写 ~150 行 C ＋ **≥15 腿**（≈10 min） |
| **N4** | **提高单腿产量**：一条腿里做 `M2→R2` ×3（应用已经热了） | 红率 6% ⇒ 单腿红概率 ×3 ⇒ 达同样功效只要 1/2 的槽时间 | 改腿脚本 |

**⚠️ 我建议 `N1`＋`N2` 合并成一波**：`N2` 先在不碰产品的前提下把"`_MOTIF_WM_HINTS` 是不是必要条件"钉死；
钉死了再落 `N1` 并跑 40 腿取成对读数。**`N1` 单独上会重演本件的剧本**（改完 16 腿得到的红率与修前不可判）。

---

## §9 槽／耗时台账 ＋ 作废趟

| 批 | 腿数 | 槽 | 耗时 |
|---|---|---|---|
| 修前基线（`W114A-B-*`，在 `W114A-B-16` 后**主动停批**） | 17（＋1 作废） | `~/heavy-slot.sh --min-avail 1500 --max-hold 600 --wait 1800`，每 8 腿一次获取 | 22:45:31→22:55:32 |
| innermost（`W114A-IN-*`） | 6 | 同上（一次获取，`held=225s`） | 22:56:34→23:00:19 |
| 修后（`W114A-F-*`，在 `F-16` 后**主动停批**） | 16（＋3 作废） | 同上 | 23:00:38→23:10:36 |
| 零回归（`D-G83` pmax ＋ `R-GATE`） | — | `--max-hold 900`，`held=59s` | 23:11:48→23:12:47 |
| 重编 ×3（`build-shim.sh --all`） | — | `--max-hold 600`，每次都 `held=2s` | — |
| 反极性腿（`W114A-RP-*`） | 8 | 同上 | 23:13→ |

**作废趟（不入分母，逐条点名）**：
- `VOID-W114A-B-18`：**槽被停批动作杀掉之后该腿仍在跑** ⇒ 不是有效槽内读数。
- `VOID-W114A-F-17/18/19`：为了把读后批停在 `F-16` 而**主动终止**（工具动作，不是样本）。
- 全程 **`HEAVYSLOT=NOINFO`／`MAXHOLD_KILL` 一趟都没有**；`rc=124` 一趟都没有。
- 内存三值（本批内）：`MemAvailable` 开工 **2,741 MB**／最低 **2,278 MB**／收工见 §10；`oom_kill` 增量 **0**。

---

## §10 自伤／纪律偏离（**不辩解**）

1. **踩了本仓在册的"自匹配"坑**：我用 `pgrep -f "w114a/bin/batch.sh 32"` 取 PID，而**我自己那条 `bash -c`
   的命令行里就含这个字符串** ⇒ 匹配到**自己**、把自己 SIGTERM 掉（该次工具调用被中断）。
   **修法**：以后一律 `pgrep -f "[b]atch.sh"` 括号法，或只用**已知 PID**。后续停批全部改用已知 PID／括号法。
2. **仪器自伤 1（严重度最高）**：`~/w114a/bin/analyze-trace.py` 第一版**硬编码**两帧偏移差 `0x5983`
   做族识别；`F1` 把那条调用包进 `if` 之后，帧差变成 **`0x59A3`** ⇒ 若不改，**修后会被静默误判成"0 条写"**
   （那会把 `C2` 变成假绿）。**已改成按 `nm` 符号区间翻名**（逐帧印 `SetWindowPos+0x164`/`+0x176`，可人工复核）。
3. **仪器自伤 2**：`judge.py` 的 `writes()` 里**还留着**同一处硬编码 ⇒ 它把 `F-01` 的 **1 条**误报成 **0 条**
   （已按 §10.2 同法修好）。**"同一个坑我在两个文件里各踩了一次"** —— 如实记。
4. **判据自伤**：`fingerprint.py` 第一版把"REMOVE 之后有 ≥1000 的 `CONFIGURE`"当指纹 ⇒ 把 WM 的**第一条**
   （还没 unmaximize 的）通告也算进去 ⇒ **绿腿 22/22 全 True（假指纹）**。已改成"先去基准、再回最大化"并重验。
5. **`L` 检测字符串写错**：第一版判 `'ShowWindow a=9' in log`，而实际行是 `ShowWindow hwnd=0x… a=9`
   ⇒ 全批误报 `L=No`；已改正则并重验（`L=Yes` 逐腿成立）。
6. **作废趟**：见 §9（`VOID-*` 共 4 条），全部**不入分母**、逐条点名。
7. **自伤 3（反极性时）**：我用 `cp -p` 把**打过补丁**的源覆盖回改前内容，**却没有先备份打过补丁的那一份**
   ⇒ 想回到修后态时只能**从记录重放补丁**。**已用"重编后件必须逐位等于 `bd037229be8db4f6`"把重放钉死**。
8. **自伤 4（重放里的隐蔽坑）**：重放用的 `f1.new`／`f2.new` 由 heredoc 写出，**末尾多一个换行**
   ⇒ 替换后在保留行之后**多出一个空行** ⇒ 源 sha16 变成 `945600eafd06e533`／`0ae44124fa6a883d`
   （≠ 第一次落地的 `3117923a7c899e05`／`11142fbef049eb66`）。**已修**（去掉末尾换行并重放）
   ⇒ **源 sha16 逐位回到第一次落地的值**，且重编后件也逐位回到 `bd037229be8db4f6`
   ⇒ **补丁文本可精确重放**（这条自证本身是有用的：它证明"记录 → 源 → 件"三段都能闭合）。
9. **写域外的副作用（如实声明，2 条）**：跑**判据指定的**零回归仪器时，它们**自己**构建了产物 ——
   ①`build/MilBridge/tests/W81AWindowProbe/{bin,obj}/Release/**`（该目录**原本不存在**；`run-w81a-legs.sh`
   默认要 `dotnet build` 探针，`--no-build` 才是跳过）；
   ②`samples/WpfFeatureProbe/obj/Release/net10.0/WpfFeatureProbe_MarkupCompile.cache`（`R-GATE` 那步自己构建探针时落的）。
   **这两处都在我的声明写域之外**，但都是**判据指定仪器的自身构建产物**，不是对判定输入的改动。
   **禁改清单逐件已核**：`verify-all.sh`／`close-wave.sh`／`integration-wave.sh`／`r-gate-step.sh`／`nul-bytes-check.sh`／
   `wm-awaited.sh`／`pipefail-sigpipe-check.sh`／`docs/ROUTES.md`／`KNOWN-DEFECTS.md`／`defect-registry-declared.tsv`／
   `known-red.json`／`ACCEPTANCE-BASELINE.md`／`build/PresentationFramework.Linux/**`／`~/w112a/**`
   —— **mtime 全部早于本车道开工时刻（22:40），一件未动**（`~/w112a/STATUS.md` 的 22:40:01 是 **W112A 自己**的收工追加，内容为 W112A 的，不是我写的）。
10. **没有做**：`F3`（怀疑真因的那条）本件**没有落地**（射程与时间），只给出方案与首选嫌疑；
   `R1` 臂、无 WM 腿、`F2`-only 臂、托管侧仪器（"缓存为何是最大化矩形"的托管侧读点）都没做。

## §11 复算（命令级）／件 sha16 一览

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux
# 判据（先写）      cat ~/w114a/criteria.md                    # sha16 582b376e5fd7bb49
# 预登记（先写）    sha256sum $R/docs/WAVE52-PREREGISTRATION.md # sha16 834e370053f7ef2b
# 逐腿判决          python3 ~/w114a/bin/judge.py 'W114A-B-*' 'W114A-F-*' 'W114A-RP-*'
# 写条数（符号归因）python3 ~/w114a/bin/analyze-trace.py "$HOME/w114a/run/W114A-B-01/geomtrace.log"
# 机读指纹          python3 ~/w114a/bin/fingerprint.py 'W114A-B-*' 'W114A-F-*'
# 单时钟对齐        python3 ~/w114a/bin/correlate.py ~/w114a/run/W114A-IN-01
# 腿（逐字节同 W112A 装置，只改 APP/OUT）  WDISP=:188 XTRACE=1 W114A_APP=… bash ~/w114a/bin/leg.sh <TAG> M2 R2
# 重编              bash ~/heavy-slot.sh --min-avail 1500 --max-hold 600 --wait 1800 -- \
#                     bash -c 'cd $R/src/WpfGfx.Linux.Native && bash build-shim.sh --all'
# 反极性            cp -p ~/w114a/backup/win32_core.c.before $R/src/…/src/win32_core.c  # 另一个同理 ⇒ 重编 ⇒ 须 8392fc09564779a1
# 再前进            python3 ~/w114a/bin/reapply.py  ⇒ 重编 ⇒ 须 bd037229be8db4f6
# 零回归 A          W81A_OUT=$HOME/w114a/out/w81a-fixed W81A_DISPLAY=:189 \
#                     bash $R/build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh --leg pmax --no-build
# 零回归 B          bash $R/build/MilBridge/tools/r-gate-step.sh
```

| 件 | sha16 | 说明 |
|---|---|---|
| `~/w114a/criteria.md`（判据，先写） | `582b376e5fd7bb49` | 本件判据全文 |
| `$R/docs/WAVE52-PREREGISTRATION.md`（预登记，先写） | `834e370053f7ef2b` | 本件预登记 |
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `e0cbc965772d06c1` → **`3117923a7c899e05`** | `F1` |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `6477af56fdcfdf20` → **`11142fbef049eb66`** | `F2` |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `8392fc09564779a1` → **`bd037229be8db4f6`** | **唯一动的世代位**；导出 547 不变 |
| `~/w114a/bin/leg.sh`（腿） | `60f6b413ca740525` | 与 W112A 装置 `diff` 只 1 行（`APP`/`OUT`） |
| `~/w114a/bin/w114watch`（**本件自写**单时钟观测器） | `40a61f0a4c5a3e70` | 与 `libxgeomtrace.so` 同一 `CLOCK_MONOTONIC` |
| `~/w114a/bin/{judge,analyze-trace,fingerprint,correlate}.py` | 见 `~/w114a/bin/` | 本件自写；口径来自 `criteria.md` |
| `~/w112a/bin/libxgeomtrace.so`（只读复用） | `8f23232cb3dc53a8` | 写者归因 |
| 其余八位 | 未重新构建 | 本件只重编 native |

---

## §12 大白话小结（≤8 行）

1. **W112A 说的那个真因（"`SetWindowPos` 多落了一次几何写、把窗口打回最大化"）是错的**——我把它修掉了，
   而且能证明"那次多余写"从一个"还原"里少掉了 5 次（6 → 1，每条腿都成立），**可是那个红照样出现**。
2. 更直接的证据：有一条红腿上，**应用一次几何写都没发**（全趟仅 1 条，还是启动时的），窗口**还是**被打回了最大化。
   换句话说，**那条多余写是"被打回"的读数，不是它的原因**。
3. 所以本件**没有修好 `D-G98`**。修前 17 腿 1 红（5.9%）、修后 16 腿 1 红（6.2%），Fisher 双尾 `p=1.00`。
4. 但这次交付了两个**真的**改进（都对齐 Win32 语义：不改几何的 `SetWindowPos` 不再改几何；`WM_SIZE` 的尺寸用现场值），
   并且**零回归成立**（`D-G83` 四格全绿、`R-GATE 13/13`、导出数 547 不变）。
5. 反极性也成立：把源逐字节复原重编，件**逐位回到 `8392fc09564779a1`**、写条数回 **6**；再补上补丁，
   件又**逐位回到 `bd037229be8db4f6`**。
6. 顺带做了一个**便宜好用的探测器**：只看应用日志里已有的诊断行，就能判"这一趟有没有被打回"
   （红腿 2/2 命中、绿腿 0/45 命中）——后续车道不用再挂 `LD_PRELOAD` 就能批量测红率。
7. 真因剩下一条最可疑的线索：还原那一拍应用会**重写一次 `_MOTIF_WM_HINTS`（装饰）**，而这是**唯一
   `xmimic` 不发**、我们又必发的非几何请求；红绿两态在事件层和诊断层**逐字同形**，差别只在时序。
8. **下一步建议**：先用**纯 X 高功效探针**（200+ 趟、零 dotnet、约 2 s/趟）把这条钉死，再落修法并跑 **≥40 腿**
   ——不要像我这样只跑 16 腿（6% 的红率下，16 腿根本判不出修没修好）。

<!-- SHA16 253b935c5415c841 -->

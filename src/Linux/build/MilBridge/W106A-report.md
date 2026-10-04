# W106A · `TASK-0108` 的收尾那一半：**托管侧通知**落地（`D-G88` 的 `P3`）

> 车道 **W106A**｜波 **`#51`**｜仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（本机 `R` 不是 git 仓库）
> 开工 `19:42`｜收工 `20:3x`｜重活全部走槽（`~/heavy-slot.sh --min-avail 1500`）
> **判据先写**：`~/w106a/criteria.md`（写于**第一次动产品源之前**；`STATUS.md` 的 STEP ①/②/③ 时间序可核）
> 上游判据件（**不重写、不放松**）：`~/w101a/criteria.md`（`5126a08c12c2801e`）＋ W101A 报告 §1/§4/§6/§7
> ＋ `~/w93a/judge.py`（`743286f14e0b318e`，**一字未改**，判决一律由它机械算）
> 冻结基线 `#50 = 1f4189c1257737a9`
> **文件 sha16 口径**：本件末行自述用 `head -n -2 本文件 | sha256sum | cut -c1-16`（与 W101A/W93A 同口径）。

---

## §0 一句话结论（三态，先给判决）

| 问 | 判决 | 一句话 |
|---|---|---|
| **`P3` 落地了吗** | **落地**（native 入口 ＋ 托管挂钩，两腿一致） | `W3-DECLARE` 与 `A3 W1-REVERT` **由 `FAIL` 转 `PASS`**，两腿（裸 `Xvfb`／`Xvfb`＋`xfwm4`）逐字相同。 |
| **保持格** | **一格未退**（含 `W2-TOGGLE` 的 `VACUOUS` 口径） | `W1/W2/W3-SHOW`、`W1-TIGHTEN`、`W2-DECLARE`、`W2-TIGHTEN` 仍 `PASS`；`W2-TOGGLE` 仍 `VACUOUS`（先写口径，**不当绿也不当红**）。 |
| **零回归** | **`PASS`** | `D-G83` 四格在**新件**上 `W89A_0106 VERDICT=PASS`；`DefWindowProcW` 的 `WM_GETMINMAXINFO` no-op **一字未动**；**零删守卫/断言**（本件只**插入**）。 |
| **反极性** | **成立，双向逐位** | 逐字节复原 ⇒ `win32shim` **逐位回 `2a297d6fee8be389`**、`pf` **逐位回 `f34bc297d19778fd`**、两格回 `FAIL`（`PASS=8 FAIL=2 VACUOUS=19`，与 W101A 同）；放回修后源 ⇒ 逐位回 `8392fc09564779a1`／`215c856cbca9922b`。 |
| **幂等（`I1`）** | **`W1`/`W2` 干净，`W3` 红（如实报）** | `W1 5/4/0`（修前 `4/2/1` ⇒ **变好**）、`W2 5/5/0`（不变）、**`W3 3/2/1`（修前 `2/2/0` ⇒ 变红）**；`asks_shim` 有界可复现 `7/12/8`（≤40）。机制**部分定位**（见 §7），`W3` 那相邻同值的**精确**机制记 **`NOINFO`**。 |
| **收工态** | **盘上留修后态** | `win32shim=8392fc09564779a1`、`pf=215c856cbca9922b`；九位里**只有这两位**动（其余七位与 `#50` 逐位相同）。 |

---

## §1 判据（**先写**，逐字位置）

- `~/w106a/criteria.md`：主判据 `M-1`/`M-2`（两格转绿、两腿都要）、保持格（含 `W2-TOGGLE`/`I1` 的**不许放宽**条款）、
  零回归 `Z-1`…`Z-4`、反极性（成对、含两位逐位回）、幂等（`I1` ＋ `asks_shim ≤ 40`）、
  **挂点探针 `H-1`…`H-4`**（先写"探针先证它真会触发，再动产品"）。
- 判决**不自己算**：一律 `python3 ~/w93a/judge.py <rows.tsv>`（**逐字未改**）。三态 `PASS`/`FAIL`/`VACUOUS`；
  `VACUOUS` = "期望与上一 stage 相同**且** X 侧实际也没变 ⇒ 本格对'跟不跟着变'无信息"（`judge.py:41-51` 原文口径）。
- ⚠️ **两处"不是绿也不是红"**：① `W2-TOGGLE` 沿用 W101A 的 `VACUOUS`；② 本件新出现的 `W1-TOGGLE`／`W3-TOGGLE2`
  由 `PASS` **变 `VACUOUS`**（机制见 §6.2）—— **不许**读成回归、也**不许**改判成 `PASS`。

## §2 挂点：**先探针证，再落地**（判据 `H-1`…`H-4`）

**为什么换挂点**：W101A 试的 `Loaded` 类处理器 6 s 一次都没触发；`AddValueChanged` 虽实测可用，但要按**实例**建
强引用（窗口泄漏面）。本件选**上游本来就有**的那个回调：

```
Window.cs:50   MaxWidthProperty.OverrideMetadata(typeof(Window), new FrameworkPropertyMetadata(new PropertyChangedCallback(_OnMaxWidthChanged)));
Window.cs:46/47/49  Min/MaxHeight/MinWidth 同理
⇒ 实例方法 OnMinHeightChanged(:5722)/OnMaxHeightChanged(:5761)/OnMinWidthChanged(:5820)/OnMaxWidthChanged(:5861)
```
**探针**（`~/w106a/hookprobe/`，仓外工程，跑在**未加挂钩的件**上；`HEAVYSLOT=ACQUIRED waited=452s`）逐字读数
（`~/w106a/out/hookprobe-nowm/probe.log`；`SHIM=2a297d6fee8be389`）：

```
HOOK_META first=1 raise=1 lower=1 both=1                    ← H-2 PASS（DP 元数据回调在**调高**时也被调用）
HOOK_HWND hwnd=0x200003 t=0.3s                              ← HWND 0.3 s 就绪
HOOK_DP_CHANGED dp=MaxWidth dir=raise   hwnd=0x200003 tid=1  ← H-1 PASS（**调高**：进回调且 HWND≠0）
HOOK_MSG_SEEN_AFTER_RAISE n=1                               ← H-3 PASS（告示消息**真的到达**该窗口）
HOOK_DP_CHANGED dp=MaxWidth dir=tighten hwnd=0x200003 tid=1  ← H-1 PASS（**调低**：同上）
HOOK_SENDMSGRC rc=0 ms=0                                    ← H-4 PASS（在 DP 回调上下文里同步发：不抛、0 ms）
HOOK_SUMMARY attached=1 raise=1 tighten=1 hwndAtCallback=0x200003 msgsSeen=2 sendFail=0 verdict=PASS
```
⇒ **四条先写判据全过**，才动产品。⚠️ 已排除的挂点：`OverrideMetadata(typeof(Window), …)`
（W101A 实测毒死 `Window..cctor`，`rc=134`，`DependencyProperty.cs:566`／`Window.cs:50`）—— **没再试这条**。

## §3 改了哪几处（**只插入**；before → after sha16）

| # | 件 | before | after | 内容（文件:行） |
|---|---|---|---|---|
| ① | `src/WpfGfx.Linux.Native/src/win32_internal.h` | `06acdcae4da6b9fd` | **`e4f2de8d038e4780`** | `:107-121` 新 `#define WPF_LINUX_WM_HINTS_CHANGED (WM_APP + 0x7F00)`（含为什么取这个号：`RegisterWindowMessageW` 从 `WM_APP` 起**递增**分配）；`:461-466` 新 `void wpf_hints_publish(HWND, const char *)` 原型 |
| ② | `src/WpfGfx.Linux.Native/src/win32_core.c` | `3fb8a1c165fccdbd` | **`e0cbc965772d06c1`** | `:773` 去掉 `static`（跨 TU 可见）＋ 注释补第 ④ 个调用点。**函数体一个字节没改**（`P1` 的缓存与 `P4` 的重入闸原样复用） |
| ③ | `src/WpfGfx.Linux.Native/src/win32_msg.c` | `cff3189eff6c87eb` | **`4ad790f4c26a907c`** | `:512-527` `wpf_dispatch_to_window()` 入口新拦一条消息 ⇒ `wpf_hints_publish(hwnd, "managed-DP-change"); return 0;`（**不进**托管窗口过程） |
| ④ | **新** `src/WpfGfx.Linux.Native/tools/patch-presentationframework-window-minmax-notify.py` | — | **`ce76657c1b020562`** | 生成式 applier（幂等；`--check` 只读；锚点命中数 ≠ 1 就**报错退出**）＋ csproj 幂等接线 |
| ⑤ | **新** `build/PresentationFramework.Linux/Window.Linux.cs` | — | **`5a0449ccc02e5433`** | = 上游 `Window.cs` **逐字** ＋ **5 处插入**（4 个回调末端各一行 `WpfLinuxWindowHints.NotifyMinMaxChanged(this);` ＋ 1 个嵌套帮助类） |
| ⑥ | `build/PresentationFramework.Linux/PresentationFramework.Linux.csproj` | `d3f54cd7c0354385` | **`4125a20d4a620f23`** | applier 注入 2 行：`Compile Remove` 上游 `Window.cs` / `Compile Include` 生成物（**同 `PtsCache.Linux.cs` 的体例**） |
| ⑦ | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | `2a297d6fee8be389` | **`8392fc09564779a1`** | `build-shim.sh --all`（327,248 B；ABI 自检"全部一致" rc=0；**导出 546 → 547**，见下） |
| ⑧ | `build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll` | `f34bc297d19778fd` | **`215c856cbca9922b`** | `dotnet build … -c Release -m:1 --nologo -v q`（**0 错 0 警**，与 `integration-wave.sh` 第 3 步逐字同命令；48 s） |

**通道为什么不是"新导出一个 P/Invoke"（机械证据）**：`PresentationFramework.dll` **没有** `DllImportResolver`
（`grep -c SetDllImportResolver`：**PF=0**，而 `WindowsBase`/`PresentationCore`/`UIAutomationTypes` 各 **1**；
解析器按**程序集**注册）⇒ PF 里新声明的 `[DllImport("…")]` **落不到** `libwpfwin32.so`。
而 `MS.Win32.UnsafeNativeMethods` 的 `user32.dll` P/Invoke **声明在 WindowsBase**、经 IVT 被 PF 使用
（上游 `Window.cs:251` 自己就那样调 `WM_SYSCOMMAND`）⇒ 走它**不需要动 resolver**、且是**已经在跑**的路径。
⇒ 托管侧发**私有消息** `WM_APP + 0x7F00`（`0xFF00`），shim 在 `SendMessageW`/`DispatchMessageW` 的**共同落点**
拦下它并转调**同一个** `wpf_hints_publish` ⇒ **没有第二套发布路径**、托管侧也不必认识这条消息。

**①导出 546 → 547 的归因（如实）**：新增的那一条是 `wpf_hints_publish`（跨 TU 可见 ⇒ 不再是 `static`）。
本仓既有形态就是"跨文件内部函数也导出"（`bin/exports.txt` 里同类 `wpf_*` **已有 66 条**，如 `wpf_dispatch_to_window`）
⇒ 未加 `visibility("hidden")`，与本仓一致。`check-shim-coverage.py` 现场 **rc=0**；全仓**没有**硬编码 `546` 的闸门。

**applier 审计（我现场跑的读数）**：
```
APPLIER_AUDIT applier=patch-presentationframework-window-minmax-notify tier=A ok=3 miss=0 detail=- selfcheck_rc=0
APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0
```
⚠️ **登记由主控落**（不是我改的）：`build/integration-wave.sh` 现 `4d19d69c93ba5927`（`APPLIERS_EXPLICIT+=( patch-presentationframework-window-minmax-notify )`）
＋ `build/MilBridge/tools/applier-audit-expected.txt` 现 `0f9e718352f183a5`（两件我都**现算 sha16**核对过，与主控自报值逐位相同）。
**登记前**它只靠 `patch-presentation*` **通配兜底**执行（能跑进波、但审计的登记清单核不到它）—— 现已显式登记。

## §4 修后两腿读数（主判据 ＋ 保持格）

件：`win32shim=8392fc09564779a1`、`pf=215c856cbca9922b`（探针 app-local 与仓内件**逐位相同**：`W93A_APPLOCAL` 行自证）。
两腿：`nowm`（裸 `Xvfb :189`）／`wm`（`Xvfb :190` ＋ `xfwm4 --compositor=off`）；各 `rc=0`、`W93A_APP rc=0`、`device=PASS`。

```
SUMMARY  A1_informative=29 PASS=8 FAIL=0 VACUOUS=21      ← **两腿逐字相同**
SUMMARY  A3=W1-REVERT:PASS
```

### 4.1 主判据（两格）＋ 逐格变化（相对 W101A 的 `postfix-nowm` / `wm`，**两腿同形**）

| 格 | W101A | **W106A** | 判据行原文（`nowm`；`wm` 同） |
|---|---|---|---|
| `A1 W3 W3-DECLARE` | `FAIL` | **`PASS`** ✅ | `expected=469x365 actual=469x365 app=469x365 changed=YES geo=438x333` |
| `A1 W1 W1-REVERT` | `FAIL` | **`PASS`** ✅ | `expected=667x500 actual=667 by 500` |
| `A3 W1 W1-REVERT` | `FAIL` | **`PASS`** ✅ | `expected=667x500 actual=667 by 500（X 侧提示在本窗**全程未移动**：移动过）` |
| `A1 W1 W1-TOGGLE` | `PASS` | `VACUOUS` ⚠️ | `期望与上一 stage 相同（667x500）⇒ 本格对'跟不跟着变'无信息 actual=667x500` |
| `A1 W3 W3-TOGGLE2` | `PASS` | `VACUOUS` ⚠️ | `期望与上一 stage 相同（469x365）⇒ … actual=469x365` |

⚠️ **不许把 `PASS=8` 读成"没进步"**：`FAIL` **2 → 0**，而两个 `VACUOUS` 正是**原来承载那两格信息的位置** ——
它们曾经观察的是"这个值**迟到一步**终于到了 X"，现在值**在该声明的那一拍就到了** ⇒ 到了 TOGGLE 时"值没变" ⇒
按 `judge.py` 先写口径判"本格无信息"。**信息被搬到了声明那一拍**（见 §6.2）。我**没有**放宽任何判据。

### 4.2 保持不变的格（两腿）

| 格 | 判决 | 读法 |
|---|---|---|
| `W1-SHOW` | **`PASS`** | `667 by 500` 仍在（启动那一拍没坏） |
| `W2-SHOW`／`W3-SHOW` | **`PASS`** | 未声明 ⇒ `maximum size` **仍缺席**（波 59 语义保住） |
| `W1-TIGHTEN`／`W2-DECLARE`／`W2-TIGHTEN` | **`PASS`** | W101A 已转绿的三格**一格未退** |
| `W2-TOGGLE` | **`VACUOUS`**（与 W101A 相同） | 先写口径：它**不是绿也不是红**；**不许改判成 `PASS`** |
| `reg58`（`1280 by 1024` 出现次数） | **`0`** | 波 58 的错法一个都没出现 |

### 4.3 幂等 `I1`／`asks_shim`（**成对读数的红**，如实报）

| 窗 | W101A（修前件 `2a297d6fee8be389`） | **W106A**（`8392fc09564779a1`） | 判决 |
|---|---|---|---|
| `W1` | `blocks=4 distinct=2 adjacent_repeats=1` | **`blocks=5 distinct=4 adjacent_repeats=0`** | **`PASS`**（变好） |
| `W2` | `5/5/0` | **`5/5/0`** | **`PASS`**（不变） |
| `W3` | `2/2/0` | **`3/2/1`** | **`FAIL`（红）** |

- **两腿逐字相同**（`nowm` 与 `wm` 三个窗完全相同）⇒ 不是噪声。
- `asks_shim`（探针自己的钩子，无截断）末值：**`W1=7 / W2=12 / W3=8`（两腿相同）**，修前 `3/8/6`
  ⇒ 有界、可复现、**全部 ≤ 40**（先写判据 §5.3 的两条都满足）。
- **反极性侧的成对读数**（同腿 `nowm`）：复原件上 `W1 4/3/0`、`W2 5/5/0`、**`W3 2/2/0`** ⇒
  **`W3` 的那一拍相邻同值是本件引入的**（这是机械归因，不是推断）。

## §5 零回归

| # | 项 | 判决 | 读数 |
|---|---|---|---|
| `Z-1` | **`D-G83` 四格** | **`PASS`** ✅ | 在新件（`pf=215c856cbca9922b`＋`shim=8392fc09564779a1`）上：`CELL declared ⇒ 'program specified maximum size: 667 by 500'`／`CELL minonly ⇒ '…minimum size: 521 by 417'`／`CELL undeclared ⇒ '<缺席>'`／`CELL reg58 ⇒ 0` ⇒ **`W89A_0106 VERDICT=PASS`** |
| `Z-1'` | **顺带（新读数）** | ✅ | `W81AWindowProbe` 的 **`late` 窗**（`Show()` 之后才声明）本次读到 **`program specified maximum size: 667 by 500`** —— W101A 记它当时是 **`<absent>`** ⇒ **"缺托管侧通知"的第三个独立现场也被补上了** |
| `Z-2` | `D-G83` 语义与 `DefWindowProcW` 的 `WM_GETMINMAXINFO` no-op | **一字不动** ✅ | 本件 diff **不覆盖** `win32_core.c:1780-1800`（`wpf_wmsize_diag` 那两行仍在原处） |
| `Z-3` | 守卫/断言 | **零删除、零放宽** ✅ | 5 处插入全部是**新增**行；`grep -c 'hints_pub_valid'` 仍是"只在发布路径"（无第二套缓存） |
| `Z-4` | 九位其余七位 | **逐位相同** ✅ | 见 §8 |
| `Z-5` | 构建口径 | ✅ | native：`build-shim.sh --all` rc=0、ABI"全部一致"、**零新 warning**（唯一 warning 是既有的 `win32_misc.c:224 -Wmisleading-indentation`）；托管：**0 错 0 警**（本仓标准） |

## §6 反极性（**成对，双向逐位**）

| 步 | 读数（`~/w106a/logs/anti-rebuild.log`／`anti-leg-nowm.out`） |
|---|---|
| ① 逐字节复原（`cp -p` 备份回放 ＋ 删生成物 ＋ 还原 csproj） | `core=3fb8a1c165fccdbd internal=06acdcae4da6b9fd msg=cff3189eff6c87eb`（**逐位＝改前值**）；`Window.Linux.cs 存在？ no` |
| ② 重建两条 | **`shim=2a297d6fee8be389`（＝W101A 收工值，逐位相等）**、**`pf=f34bc297d19778fd`（＝`#50` 冻结值，逐位相等）**，0 错 0 警 |
| ③ 同腿（`nowm :193`）、同探针、同判据重取 | `SUMMARY A1_informative=29 PASS=8 FAIL=2 VACUOUS=19` ＋ `A3=W1-REVERT:FAIL`；`W3-DECLARE expected=469x365 actual=<缺席>` ⇒ **两格回 `FAIL`**（与 W101A §4 逐字同形）；`SPY_COUNT W3 blocks=2 distinct=2 adjacent_repeats=0` |
| ④ 放回修后源 ＋ 重放 applier ＋ 重建 | `Window.Linux.cs=5a0449ccc02e5433`（**同一 sha16 ⇒ 生成器可复算**）；**`shim=8392fc09564779a1`**、**`pf=215c856cbca9922b`**（各逐位回修后值），0 错 0 警 |
| ⑤ 盘上终态 | **修后态**（§3 表的值；探针复制件的 app-local 也刷回 `215c856cbca9922b`） |

⇒ **反极性成立**：两侧都是"同一份源 ⇒ 同一个 sha16"，**不是"大概回得去"**。

### 6.2 `VACUOUS` 位移的机制（一句话，可机械核）
`judge.py:46` 的"有信息"判据 = **期望变了 或 X 侧实际值变了**。修后那两格的信息在**声明那一拍**就被兑现
（`W3-DECLARE`／`W1-REVERT` 自己 `PASS`）⇒ 到了 `TOGGLE` 时**期望与 X 实际都没变** ⇒ `VACUOUS`。
这与 W101A 当年把 `W2-TOGGLE` 由 `PASS` 变 `VACUOUS` 是**同一条口径、同一个机制**（信息前移）。

## §7 `I1` 的红：机制**部分定位**，其余 `NOINFO`

**先写的判据**（`criteria.md` §5.1）："`XSetWMNormalHints` 的调用次数 == 值变化次数"（口径 = `xprop -spy` 的块数，
W101A §2 的装置自证 `XTEST_SPY=PASS`）。**本件不满足**：`W3` 出现"相邻同值"一拍（两腿可复现）。

**已机械定位的部分**（最小装置，仓外，零产品改动；`~/w106a/out/w3dup|w3real|w3one/probe.log`）：

| 装置 | 动作 | 读数 |
|---|---|---|
| `w3dup` | 只声明一次（`MaxWidth=469`＋`MaxHeight=365`，窗口比上限小 ⇒ **不 resize**） | `blocks=3 distinct=3 reps=0`：`min1x1` → **`max 489 by 1024`（中间态！）** → `max 489 by 380` |
| `w3real` | **逐字照 W93A 的 W3 配方**：420x320 → 4 次 `HIDE/SHOW` → 声明 `450/350` → 2 次 `HIDE/SHOW` | `blocks=3 distinct=3 reps=0`：`min1x1` → `max 469 by 1024`（中间态）→ `max 469 by 365` |
| `w3one` | **只改一个 DP**（`MaxWidth=450`）＋ 2 次 `HIDE/SHOW` | `blocks=2 distinct=2 reps=0` ⇒ **缓存确实挡住了后续 `after-map` 那一拍**（幂等路径本身是好的） |

⇒ **可复现的结论**：托管挂钩**每个 DP 变化各发一拍** ⇒ "两 DP 声明"会发**两拍**，而且**中间态会落 X**
（`MaxWidth` 已生效、`MaxHeight` 还没 ⇒ `max=…1024`）。这是本件引入的、**可归因的额外一次 X 写**。

**`NOINFO`（未定）**：真实腿里 `W3` 那**两次相邻同值**（`469x365`、`469x365`）在最小装置里**复现不出来**
（最小装置给的是两个**不同**值）。静态可核的两条约束使它**不合常理**：① `wpf_x11_apply_wm_hints` **只有一个调用者**
（`win32_core.c:811`，`grep` 实证）；② 缓存**只在"要写 X"时才更新**（`:799-811`）⇒ 同一窗**连续两次写同一个元组**
按代码**不该发生**。我**没**抓到成因；两条线索留给后续：
- `D-G90`（仪器局限：`[WMSIZE_DIAG]` 每进程 **40 行硬截断**）在真实腿里**把 W3 的发布决定行截掉了**（该趟正好打满 40 行）
  ⇒ **这是本格机制判不动的直接原因**；最小装置行数少才看到决定行。
- 待查假设（**未验**）：同一 `hwnd` 是否存在两个 `wpf_window` 表项（XID 复用 / 陈旧表项）⇒ 缓存被两套读。
**判定口径**：`I1` 对 `W3` **记红**（先写判据，不放宽）；"值相同"那一次的**成因**记 `NOINFO`（既不算绿也不算红）。

## §8 `win32shim`／`pf` 新 sha16 与九位未动项

**新 `win32shim` = `8392fc09564779a1`**（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`，327,248 B）
**新 `pf` = `215c856cbca9922b`**（`build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll`，6,123,520 B）

| 位 | live（收工态，现算） | `#50` 冻结值 | 判定 |
|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | `feef049e9d0e313a` | 同 |
| `pc` | `722e0ab8205b7c3f` | `722e0ab8205b7c3f` | 同 |
| **`pf`** | **`215c856cbca9922b`** | `f34bc297d19778fd` | **变了（本件）** |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | 同 |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | 同 |
| **`win32shim`** | **`8392fc09564779a1`** | `33352e5797031999` | **变了（本件）** |
| `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | 同 |
| `hbtextline` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | 同 |
| `dwf` | `ce3469f49efcbcfa` | `ce3469f49efcbcfa` | 同 |

`BASELINE-FROZEN gen=#50 sha16=1f4189c1257737a9`（`docs/CURRENT-STATE.md:9`，**本件未动**）。
⚠️ **收尾链要做**：两位变了 ⇒ 需**重钉世代**（`repin-generation.py`）＋ 重跑门禁/冻前冻后 `verify-all` ＋ 重冻。
📌 **`win32shim` 导出 546 → 547**（新增 `wpf_hints_publish`，见 §3 末）；`bin/exports.txt` 由 `--all` 重生成。

## §9 残留边界（逐字）＋ `NOINFO`／作废趟／自伤

### 9.1 落地后的残留边界（**逐字**）
> **"窗口还没有 HWND（`IsSourceWindowNull`）时改 `Min/MaxWidth/Height` ⇒ 本件不发告示。"**
> 依据：挂钩点在 `Window.Handle == IntPtr.Zero` 时直接返回（`Window.Linux.cs` 的 `NotifyMinMaxChanged` 第一道守卫），
> 因为此刻**没有可寻址的 HWND**；而"建窗那一拍"（`create_window_utf8`）与"首次 map 那一拍"（`ShowWindow`）
> **照旧**会问一次 ⇒ 建窗前声明**仍然到得了 X**（W1 就是这样：`W1-SHOW` 两腿 `PASS`）。
> ⇒ **W101A 那条残留边界收窄为"窗口尚无 HWND 时"**；**有 HWND 之后，调高与调低两向都即时到 X**（两腿实测）。
> 现场实例：`W3-DECLARE`（`469x365`，本拍就到）／`W1-REVERT`（`667x500`，本拍就到）／`W81AWindowProbe` 的 `late` 窗（`667 by 500`）。

### 9.2 `NOINFO`（既不算绿也不算红）
1. **`I1`/`W3` 那一次"相邻同值"的精确机制**（§7）：未抓到；`D-G90` 的 40 行截断把真实腿的发布决定行截掉了。
2. **`0104` 四入口 26 腿**（`TASK-0205`，装置在别人车道的 `~/w89a/bin/**`，≈30 min）：**没跑**，不拿 `Z-1` 顶替。
   ⚠️ **它是收尾链的第一优先**（`P2`/`P4` 正落在最大化/还原与重入那条路上）。
3. **全量 `verify-all`／`close-wave.sh`／`integration-wave.sh`／冻结／推送**：按任务书**不在本件射程**（重活会撞别的车道）。
4. `W2-TOGGLE`／`W1-TOGGLE`／`W3-TOGGLE2` 的 `VACUOUS`：**口径产物，不是绿**（§4.1/§6.2）。

### 9.3 作废趟／偏离／自伤（全部零产品影响）
| # | 项 | 如实登记 |
|---|---|---|
| 1 | **作废趟 #1**：挂点探针首跑 `rc=134` | 不是产品红：缺 `WPF_LINUX_WIN32_SHIM`／`WPF_LINUX_WIC_SHIM`／`MILBRIDGE_MILCORE_SO`（WPF 自己的 resolver 找不到 shim 库）⇒ 补齐三个环境变量后重跑（该趟**零写盘**） |
| 2 | **作废趟 #2**：腿脚本第一版仍指向 `~/w93a/probe` | 那一趟的 `W93A_APPLOCAL PresentationFramework.dll = 2a5b7641f6fba0fb`（**W93A 探针 bin 里 10:02 的旧 PF**）⇒ **测不到本车道的改动** ⇒ 该趟**作废**（按 PID 收工，未落任何读数）。改成"探针**逐字节复制件**（源 `Program.cs` sha16 `df9feabcd296b950` 与 W93A 相同）＋ 用当前件重建 bin"后重跑 |
| 3 | ⚠️ **发现（对既有装置）**：`~/w93a/probe/bin/Release/PresentationFramework.dll` = `2a5b7641f6fba0fb`（10:02 的件），**与 `#50` 冻结值 `f34bc297d19778fd` 不同** | 对**改 native** 的车道无影响（shim 走 `WPF_LINUX_WIN32_SHIM` 显式路径），但**任何改 PF 的车道都会被它吞掉** ⇒ 建议登记车道处置（本件只报告，未动别人目录） |
| 4 | **偏离**：本件的两条腿用"W93A 探针的复制件"跑 | 源**逐字节相同**（`cmp` 已核）；只改 `OUT`/`PROBEHOME`/`--wait 900→1800`（`diff` 只有这三处） |
| 5 | **偏离**：挂点探针自己装 `SetDllImportResolver` | 探针在仓外、只影响探针读数，不影响产品判定 |
| 6 | `pkill -f` 次数 = **0** | 全趟按 PID 收工（`Xvfb :186/:189/:190/:191/:192/:193`、`xfwm4`、`xprop -spy`、`dotnet`）；**未碰** `:0/:1/:10/:95/:96/:97/:99` 与用户会话 |
| 7 | 槽台账 | 每条重活各自入槽（native+PF 一次取槽 `--max-hold 1200`、其余 300/600）；`MAXHOLD_KILL` **0 次**、`HEAVYSLOT=NOINFO reason=low-memory` **0 次**；最挤一次 `waited=452s` |

## §10 大白话小结（8 行）

1. **剩下那一半修好了**：应用把上限**调高**（或声明时窗口本来就没超）时，上游 `Window` **什么都不做** ⇒ 我方没有触发器
   ⇒ X 侧的尺寸提示要"等下一次窗口活动"。现在改成：**一改这个声明，就当场告诉 shim 重问一次**。
2. 挂点用的是**上游本来就有**的那 4 个回调（`Window.cs` 的 `OnMin/Max{Width,Height}Changed`），
   **不是**"给每个窗口入册"；探针先证过：调高/调低两向都进得来、且**回调里 HWND 就在手上**（`H-1`…`H-4` 全过）。
3. 通道**没有**新造 `P/Invoke`：`PresentationFramework.dll` **没有** resolver（机械证据：`SetDllImportResolver` 计数 = 0），
   所以走 PF 已经在用的、声明在 WindowsBase 的 `SendMessage` 发一条**私有消息**；shim 在派发的唯一落点拦下它，
   转调**同一个**幂等发布入口（缓存与重入闸都没另写一套）。
4. **两格转绿**：`W3-DECLARE`（`469x365` 本拍到）与 `A3 W1-REVERT`（`667x500` 本拍到），**两腿逐字相同**；
   `FAIL` 由 **2 → 0**。
5. **保持格一格未退**（含 `W2-TOGGLE` 仍是 `VACUOUS`）；**零回归** `D-G83` 四格全过，顺带把 `late` 窗那格也补上了。
6. **反极性严格成立**：拆掉挂钩逐字节复原 ⇒ shim **逐位**回 `2a297d6fee8be389`、pf 逐位回 `f34bc297d19778fd`、两格回红；
   放回去 ⇒ 逐位回 `8392fc09564779a1`／`215c856cbca9922b`。**盘上留修后态。**
7. **幂等如实报**：`W1`/`W2` 干净（`W1` 还**变好**了：`4/2/1` → `5/4/0`），但 **`W3` 红**（`2/2/0` → `3/2/1`）。
   已复现的机制 = "**每个 DP 变化各发一拍、中间态会落 X**"；那两次**同值**的精确成因**没抓到**（`NOINFO`，
   直接原因之一是 `D-G90` 的 40 行截断把真实腿的决定行截掉了）⇒ **不放宽判据，红就是红**。
8. **九位里只有 `win32shim` 与 `pf` 动**（导出 546 → 547，新增 `wpf_hints_publish`，与本仓既有 66 条同类
   `wpf_*` 内部导出同形）；**收尾链需要重钉世代＋重冻**。applier 的**登记由主控落**（两件 sha16 我现场核过），
   全量 `applier-audit` = `appliers=28 ok=95 miss=0 red=0 rc=0`。

W106A-report.md sha16 = 6558bba440cce6a3（口径：`head -n -2 本文件 | sha256sum | cut -c1-16`；本值由现场复算填入，未手抄）

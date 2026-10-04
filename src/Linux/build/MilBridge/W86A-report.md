# W86A · `TASK-0304`（`A1`）＋ `TASK-0305`（`A2`）：把 `D-G70` 做成**具名、可判、可见的能力边界**

- lane=W86A ｜ 2026-09-22 09:20→10:0x +0800 ｜ kernel 6.8.0-138-generic ｜ `nproc=3`
- 仓 = `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`（下称 `$R`）
- 冻结基线（开工实测，只读核对器）：`BASELINESHA=PASS live=f1d340d66c7c6ba3 decl=f1d340d66c7c6ba3`、`BASELINEGEN=PASS decl_gen=#49 file_newest_gen=#49`
- 设计依据：`build/MilBridge/W78A-report.md`（现场复算 `0dbc62b1d1cf86ee` ✅ 与派单书一致）§2/§3 ＋ `build/MilBridge/W81A-report.md` §2
  （⚠️ 派单书给的 `257b2f45784aa69b` 与**现场不符**：现场 = `3b4723c204ba6b12` ⇒ 该件在派单之后被改过；我按**现场那一份**读）
- 写域：`src/WpfGfx.Linux.Native/src/**`（`A1`）＋ `build/PresentationFramework.Linux/**`（`A2/A3`）＋ 本报告；**被迫多改一行**：`src/WpfGfx.Linux.Native/build-shim.sh` 的 `SRCS`（见 §2.1，理由写明）

## 0. 先给结论（六行）

1. **`A1` 落地**：新 `win32_pts.c` 导出 PTS 上下文族 **6 个入口 + 5 个机读面**（导出数 535→546），**如实返回 `-10000`（`tserrNotImplemented`）**，并打具名台账 `PTS_GAP entry=… seq=… err=… calls=…`。⇒ 第一跳**实测点名 `CreateInstalledObjectsInfo`**（= W78A §2.2 组 A 第 1 条）。
2. **`A2` 落地**：`PtsCache.AcquireContextCore` 失败时**按对象身份**把那条毒池项移出池 ＋ 具名能力闩（只对"PTS 缺口"一族生效）；`Invariant.Assert` **一个都没删**。
3. **`A3` 落地（W78A 把它列为第三步，但判据 3 要求"页级可见"，本件一并做）**：`FlowDocumentView` 三处接住那个具名异常，画**页级具名占位**（洋红矩形 + 黑边 + 三行自述文字）。
4. **产品读数（判据 3）成立**：点第 **24** 项（`FlowDocumentDemo`／流文档）⇒ `alive=yes`、**`rc≠134`**（`rc=143` = **仪器自己发的 SIGTERM**）、**洋红占位 54,454 像素**、日志有 `[PTS-UNAVAILABLE] entry=CreateInstalledObjectsInfo err=-10000`；第 **23** 项（`RichTextBoxDemo`／富文本）同样可见降级（49,864 像素）。**`A3` 是必需的，不是装饰**：撤掉它 ⇒ `A2` 单独虽然不再 `FailFast`，但**重试风暴 7,909 条**、页面量不出内容（§3.4.1 实测）。
5. **`N2` 有争议，我如实报**：任务书指定的那一格（"把 stub 改成返回成功"）**判据仍然绿**，而且**那不是假绿**（理由见 §5.1）；真正能咬住"不许把空白读成绿"的是**另一格**（`A3` 只降级不画 ⇒ 实测 `alive=yes` 但 `magenta=0` ⇒ **判据必须变红，实测变红**，§5.3）。
6. **零回归有机器证**：正常页（`BrushDemo`）在 `BASE` 与 `A2A3` 两版 PF 下截图 **`AE=0`**（逐像素相同）。

---

## 1. 判定点与清单（先写进报告，读数后取）

### 1.1 `D-G70` 链上的判定点（W78A §2.1 的实测版）

```
FlowDocument 布局
 └─ FlowDocumentView.MeasureOverride / .DocumentPage        ← A3 接住点（实测：第一跳在这里）
     └─ FlowDocument.get_BottomlessFormatter
         └─ FlowDocumentFormatter..ctor → FlowDocumentPage..ctor
             └─ StructuralCache.EnsurePtsContext
                 └─ PtsContext..ctor → PtsCache.AcquireContext → AcquireContextCore
                     └─ CreatePTSContext → InitInstalledObjectsInfo
                         └─ PTS.CreateInstalledObjectsInfo  ← A1 的 stub 在这里**如实失败**
                     ⇒ 池里那条 ContextDesc 半初始化 ⇒ A2 在这里**把它移出池**并立闩
```

### 1.2 与 W78A §2.2「27 条必需入口」清单对照（`A1` 的答案）

| 组 | 27 条里本件导出的 | 本趟实测"被要求过"的 |
|---|---|---|
| **A 上下文创建期（6）** | **全部 6 条**（`CreateInstalledObjectsInfo`/`DestroyInstalledObjectsInfo`/`CreateDocContext`/`DestroyDocContext`/`GetFloaterHandlerInfo`/`GetTableObjHandlerInfo`） | **只有第 1 条** `CreateInstalledObjectsInfo`（台账 `seq=1`） |
| B/C/D/E（21 条） | 0（**本件不导出**：它们是分页引擎本体，W78A §3.0 已判"不在第一步射程"） | 0 |

⇒ **`A1` 单独读数 = 缺口点名到"27 条清单的第 1 条"**；**再往下走不了是设计使然**（stub 如实失败 ⇒ 按 W78A §2.4，构造期是耦合的，失败必然停在第一跳；要"继续往下走"必须让 stub 假装成功 —— 那一格就是 `N2`，读数见 §5.2）。

### 1.3 本件判据（三态，写死）

| 格 | 条件 | 期望 | 反极性 |
|---|---|---|---|
| **P1**（进程） | 点第 24 项 | `alive=yes` ∧ `rc≠134` | 撤全部 ⇒ 实测 `rc=134`（§3.3） |
| **P2**（具名） | 日志 | **`[PTS-UNAVAILABLE] … entry=<名> err=<非0>`**（托管侧，**每次新建视图一条**）∧ `PTS_GAP entry=… err=-10000`（native 侧） | 撤 `A1` ⇒ 逐字 `EntryPointNotFoundException: … 'CreateInstalledObjectsInfo'` |
| **P3**（不许静默空白） | 页面矩形 | **洋红像素 > 0**（占位真的画出来）——**空白 ⇒ 红**；**不许**把"进程活着"读成"页面对了" | `A3` 假修（只降级不画）⇒ 实测 `magenta=0` ⇒ **红**（§5.3） |
| **P4**（别的页还能用） | 崩过之后再点正常页 | 页面**真的换了**（应用自报 `[NS] loaded …` ＋ 帧差 `AE>0`） | —— |

> ⚠️ **判据不读 native 台账的 `err` 字段**：`N2-a1` 实测把台账伪造成 `err=0`（§5.1），
> 一个"`grep PTS_GAP` 就算具名"的判据**会当场被骗**。本件的 P2 只认**托管侧那条**（带非零 err）。

---

## 2. `A1` · native 侧：6 个入口**导出但如实失败**

### 2.1 逐处改动

| 件 | before | after | 说明 |
|---|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_pts.c` | **不存在** | `e6559d0bba3c1044` | **新增**（约 290 行，含头注） |
| `src/WpfGfx.Linux.Native/build-shim.sh`（`SRCS` 一行） | `c8db74cebeb97a98` | `63ce892eb2beebcc` | ⚠️ **被迫改一行**：`SRCS` 是显式清单（不 glob）⇒ 不加这一行新文件**根本不参与编译**。写域字面是 `src/**`，这一行在**上一级**；同仓先例（W81A 改 `build-hygiene-roster.tsv`）即"被迫、一行、如实登记"。**未改** `Makefile`（它的 `SRCS` 早就只有 5 个 .c，与 `build-shim.sh` 的 9 个不一致 ⇒ 本机无 `make`，它不是构建路径；这一不一致是**既有的**，我一字未动） |
| `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（= `win32shim`） | `3e4390c9ec07f621`（322,056 B） | `24e906c194903c8b`（323,008 B） | 导出 **535 → 546**（+6 入口 +5 机读面） |

### 2.2 契约（为什么是"诚实拒绝"而不是"托底桩"）

- 6 个入口**恒返回 `-10000`** = 上游 `Pts.cs:507` 的 `tserrNotImplemented`
  （`PtsHost.cs:571` 起 20 余处**回调**面用的就是同一个码 ⇒ 托管侧**已经认识它**）。
- 失败时**把出参清成 `NULL`/`0`**（不给假句柄、也不留未初始化内存）。
- 头注里写死**唯一的自杀式改法**（谁把 `return` 改成 `0` ⇒ 假句柄 ⇒ 断言全过 ⇒ 页面空白但进程活着 ⇒ **没有任何红**）。

### 2.3 具名台账 + 机器可读面

```
native（stderr，**默认开**、有界 64 行、`WPF_LINUX_PTS_DIAG=<n>` 调界 / `=0` 关）：
  PTS_GAP entry=CreateInstalledObjectsInfo seq=1 err=-10000 calls=1
  PTS_GAP ledger=truncated printed=64 total_calls=… budget=64      ← 打满后一条收尾
机读导出（照 `WpfLinuxWin32_EscStringSelfCheck` 的形状）：
  WpfLinuxWin32_PtsGapCount() / PtsGapCalls() / PtsGapEntryName(i,buf,cap)
  WpfLinuxWin32_PtsGapReport(buf,cap)   → "PTS_GAP_REPORT mode=honest-fail entries=6 calls=… first=… last=… err=-10000"
  WpfLinuxWin32_PtsGapSelfCheck()       → **1 = 6 个入口都如实失败**（= 本文件的第一道牙）
```

**读数（`ctypes` 直调 `.so`，不经过应用）**：

```
PtsGapSelfCheck = 1
PtsGapReport    = PTS_GAP_REPORT mode=honest-fail entries=0 calls=0 first=- last=- err=-10000   （自检不污染台账）
CreateDocContext rc=-10000  out=0x0        ← 真调一次：非零返回 + 出参清空
after: count=1 calls=1   entry[0]=CreateDocContext
[stderr] PTS_GAP entry=CreateDocContext seq=1 err=-10000 calls=1
```

### 2.4 `A1` **单独**的产品读数（`A1` + 基线 `pf`，`$HOME/w86a/logs/w86a-m2/`）

```
511: PTS_GAP entry=CreateInstalledObjectsInfo seq=1 err=-10000 calls=1
512: [HC-UNHANDLED] #2 PtsException: Page formatting engine did not complete formatting operation. Error code: '-10000'.
     ｜ 首帧 at MS.Internal.PtsHost.UnsafeNativeMethods.PTS.Error(Int32 fserr, PtsContext ptsContext)
513/515: Unrecoverable system error.   →   APP_RC=134
```

⇒ **两点如实报**：① 缺口**变成数据**了（名字 + 序号 + 错误码，且托管侧那个码与 A1 的常量**逐字相同** = 穿过 P/Invoke 边界的同一份真相）；② **`A1` 一点也不救进程**（与 W78A §3.1 的自述一致）—— 救进程的是 `A2`。

---

## 3. `A2` · 托管侧：拆毒池项 + 具名能力闩

### 3.1 注入面（**先确认该工程怎么注入**，再动手）

- PF 这个工程**没有** `tools/patch-presentationframework-ptsgap.py` 这类应用器的写域（`src/WpfGfx.Linux.Native/tools/**` 不是本件写域）；
- 它**唯一**能活过每一波的注入面 = `build/PresentationFramework.Linux/reapply-patches.py`：
  `build/integration-wave.sh:124-126` 在「`port-lib` 重生成（**整份重写 csproj**）」之后**必定重放**它；
- 上游源级覆盖的既有形状 = `<Compile Remove="$(UpstreamWpfRoot)…" />` + `<Compile Include="…/<名>.Linux.cs" />`（PF 里已有 7 对这样的接线）。
- ⇒ **本件做法**：把生成器放进 `reapply-patches.py`（在写域内、幂等、每波自动重放），产出 **2 个派生源**
  （真值 = 上游逐字复制 + needle 校验后改写；**needle 命中数不符 ⇒ rc≠0 拒绝产出**）。
  `--check`/idempotency 实测：连跑两次三件 sha16 逐位相同（`IDEMPOTENT=YES`）。

| 件 | before | after |
|---|---|---|
| `build/PresentationFramework.Linux/reapply-patches.py` | `3ae3f5af556c0f2a` | `c439c7c00f09f909`（+`PATCH_C` 与生成器；`PATCH_A`/`PATCH_B` 两个字符串**逐字节相同** —— 抽出来比对：`before_len == after_len` 且 `IDENTICAL=True`） |
| `…/PtsCache.Linux.cs` | 不存在 | `627c8d23aa7ef233`（上游 816 行 + 5 处） |
| `…/FlowDocumentView.Linux.cs` | 不存在 | `ecb0263b200c18dc`（上游 700 行 + 8 处） |
| `…/PresentationFramework.Linux.csproj` | —— | `8dc2ac5475fe616e`（**只多一个 ItemGroup**：2 对 `Remove/Include`） |

> ⚠️ 上下文：我单独重放 `reapply-patches.py` 会把 A/B/C 块挪到**工具应用器块之后**
> （`.before` 里 A/B 在 `M7c 补丁 L` **之前**）。语义无差（我的 `Remove/Include` 是最后一条 ⇒ 生效），
> 且下一趟波（`port-lib` → `reapply-patches` → 工具应用器）会**自动回到规范顺序**。
> 复核：`补丁开关/补丁结束/M7c L/T1c 三块` 各**仍只出现 1 次**（`grep -c`），无重复注入。

### 3.2 `PtsCache.Linux.cs` 逐处（5 处）

| # | 位置（上游行号） | 改动 |
|---|---|---|
| E0 | `:22` | 加 `using System.Runtime.InteropServices;` + `using DllImport = MS.Internal.PresentationFramework.DllImport;` |
| E1 | `:750` | 加字段 `private PtsUnavailableException _ptsUnavailable;`（**进程级闩**） |
| E2 | `:179` | `AcquireContextCore` **入口**：具名闩命中 ⇒ 立刻抛**具名**异常（每次抛新实例，首次失败挂 `InnerException`）⇒ **不再进 native、不再扫池**（防布局重入/重试风暴） |
| E3 | `:193-199` | 建池项包进 `try/catch`：**失败 ⇒ 按对象身份 `_contextPool.Remove(created)`（＋半初始化项的 `TextPenaltyModule.Dispose()`）**；若判为 PTS 缺口 ⇒ 立闩 + 抛 `PtsUnavailableException`；**其它异常原样传播**（不吞、不改名、不立闩） |
| E4 | `:814` | 追加两个类型：`PtsUnavailableException`（具名异常）＋ `WpfLinuxPtsGap`（判据/具名/打印，**不做任何降级动作**） |

**判据为什么不是"异常类型表"**：`A1` 落地后真正的异常是 `PTS.PtsException`，而它是**上游的 `private` 嵌套类**（`Pts.cs:299`）⇒ **本工程引用不到它**。所以判据改成**native 自己作证**：
`WpfLinuxWin32_PtsGapCalls()`（native 的累计入口调用数）在 `CreatePTSContext` 前后各取一次快照 —— **涨了** ⟺ 这一次尝试真的问过 PTS 上下文族 ⟺ 缺口是原生侧**亲口说的**；没涨 ⇒ **与 PTS 无关 ⇒ 不立闩**。旧 shim（无此导出）下退化成"只认三个 `DllImport` 异常族"，而那时真正的失败**恰好**就是 `EntryPointNotFoundException` ⇒ 照样命中（**不依赖新 shim**）。

### 3.3 ⚠️ 我自己踩进去的坑（**这一条是本件最有价值的读数之一**）

**第一版 `A2` 的判据是 `_contextPool[index].PtsHost.Context == IntPtr.Zero`** ——
而 `PtsHost.Context` 的 **getter 自己就在断言** `_context != IntPtr.Zero`（`PtsHost.cs:62-66`），
**半初始化项恰好违反它** ⇒ **修复在它要修的那个状态上，自己触发了 `FailFast`**：

```
（$HOME/w86a/logs/w86a-m2/app_g2.log，A1 + 第一版 A2/A3）
invariant.FailFast ← PtsHost.get_Context() ← PtsCache.AcquireContextCore
                  ← AcquireContext ← PtsContext..ctor ← StructuralCache.EnsurePtsContext
                  ← StructuralCache.get_Section ← FlowDocumentPage..ctor ← FlowDocumentFormatter..ctor
                  ← FlowDocument.get_BottomlessFormatter ← FlowDocumentView.EnsureFormatter()
                  ← FlowDocumentView.get_DocumentPage ← DocumentPageTextView..ctor
⇒ APP_RC=134（没修好，反而多了一条"自触发"路径）
```

⇒ 修法（现版本）：**只按对象身份**（`created` 是本次刚 `new`、刚 `Add` 进去的那个引用；
`List<T>.Remove(T)` 就是按引用找）——**一个字段、一个属性都不读它的状态**。
`Add` 自己抛（OOM）⇒ `created == null` ⇒ 不删（安全）。
这条已写进生成物的注释里（连同实测栈），免得后人"顺手"改回去。

### 3.4 `A2` 的读数

| 读数 | 修前（基线 `pf`） | 修后 |
|---|---|---|
| 点第 24 项后进程 | **死**：`Unrecoverable system error` ⇒ `rc=134`（§3.5 给栈） | **活**：`alive=yes`，`fatal=0` |
| 同一进程**再进一次**同一页（24→0→24） | 不可达（进程已死） | `alive=yes`、`[PTS-UNAVAILABLE]` 第 2 条、占位**再次**画出（`magenta=54454`）、`rc=143`(仪器 SIGTERM) |
| 进**另一个** PTS 页（第 23 项 富文本） | 不可达 | `alive=yes`、`magenta=49864`、`[NS] loaded …RichTextBoxDemo` |
| 点完再点正常页（0/9/10/16） | 不可达 | `alive=yes` ∧ `[NS] loaded …`（应用自报）∧ `AE>0` |
| **`Invariant.Assert` 删了几个** | —— | **0 个**（`diff` 只有新增行；`Assert` 一处未动、未放宽） |

> **`NOINFO`**：任务书要的"**池计数 / 句柄值**"读数**取不到** —— 仓内没有任何仪器能读 `PtsCache._contextPool`
> （它是 `private`，且唯一的外部观测点就是那个**会断言的 getter**）。本件给的是**行为等价读数**
> （重复进页不死、闩只命中一次/视图）＋ §3.5 的机制栈。**不许**把"进程活着"读成"池里干净了"。

### 3.4.1 ⚠️ **`A2` 单独（撤 `A3`）实测：不死于断言，但进入重试风暴** —— 判据 2 的诚实答案

任务书的判据 2 是"**`A2` 单独**：异常后池里不再有那条毒项，且**再点一次不会因 `Context==Zero` 断言而死**"。
我用一个**只有 A2、A3 全部不注入**的变体（`FlowDocumentView.Linux.cs` = 上游逐字复制，
`pf=14a780572064af96`，实测该产物里 `PtsGapPlaceholderSize` 出现 **0** 次 ⇒ 确实没有 A3 的代码）跑了同一格：

```
$HOME/w86a/logs/w86a-a2only2/session.txt（A1 shim + A2-only pf，点 24 → 想再点 0）
CLICK k=24 … guard=7909  fatal=0                                    ← ★ 7,909 条 [HC-UNHANDLED]
pts_unavail=0（没有 [PTS-UNAVAILABLE] 这条具名行，因为打印它的代码在 A3 那一侧）
alive_after_seq=no   APP_RC=124（= 仪器自己 timeout 收的）
第二次点击：`BEFORE item=0 nm=Brush stable=no rect=268,-122,203x27 point=-` ⇒ 窗口已经量不出可点项
```

⇒ **三条结论**（这条读数比"通过/不通过"更有信息量）：
1. **`A2` 确实拿掉了 `FailFast`**（`fatal=0`，没有任何 `Unrecoverable system error`）—— 判据 2 的**前半句成立**；
2. **但后半句不成立**：没有 A3 的**视图级闩**，每次布局都抛一次具名异常 ⇒ **重试风暴 7,909 条**，
   应用进入**量不出内容**的状态（`frame` 不再更新，第二项点不到）⇒ **这一格不能算通过**。
   这正是 W78A §3.4 风险 2（"A2 的闩若只挡 native 调用而不挡布局重入 ⇒ CPU 打转"）的**实测兑现**；
3. ⇒ **`A3` 不是"锦上添花的可见性"，它是把重试风暴按住的那一半**（视图级闩 + 不再进 formatter）。
   **并且**：这一格同时证明"**只看 `alive` 的判据会误判**"—— 进程技术上活着（`rc=124` 是仪器收的），
   但页面**空白**且**没有具名行** ⇒ 本件的 P3（洋红 > 0 ∧ 具名行）在它上面**正确地判红**。


### 3.5 【更正 W78A 的一句】今天的**终止形态**不是 `PtsHost.Context` 的断言

基线（`BASE` shim + 基线 `pf`）现场栈（`$HOME/w86a/logs/w86a-m1/app_g1.log`）：

```
[HC-UNHANDLED] #2 EntryPointNotFoundException: Unable to find an entry point named
               'CreateInstalledObjectsInfo' in shared library 'PresentationNative_cor3.dll'.
Unrecoverable system error. / Process terminated.
  at MS.Internal.Invariant.FailFast
  at System.Windows.Media.FontFamily.get_FirstFontFamily()          ← ★ 死在这里
  at System.Windows.Media.FontFamily.get_LineSpacing()
  at MS.Internal.Text.DynamicPropertyReader.GetLineHeightValue(DependencyObject)
  at MS.Internal.Documents.FlowDocumentFormatter.ComputePageMargin()
  at MS.Internal.Documents.FlowDocumentFormatter.Format(Size)
  at MS.Internal.Documents.FlowDocumentView.MeasureOverride(Size)
```

⇒ **W78A §3.5 说"终止形态 = 毒池项复用 ⇒ `Context==Zero` ⇒ 7 处断言之一"。实测：`
`PtsHost.get_Context` 那一条**在本代树上不是主路径** —— 毒池项被复用后 `CreatePTSContext` 被跳过 ⇒
`TextFormatter` 为 null ⇒ 半初始化状态**向下游扩散**，死在 `ComputePageMargin → FontFamily.FirstFontFamily`
（**同一个死点**在我故意做的"假 stub + 无 A2"那一格 `N2-a2` 里也被击中 ⇒ 它是"半通状态的**汇聚死点**"）。
**"毒池项是根因"这句话成立；"死在哪条断言"这句话今天要改**（`PtsHost.get_Context` 确实存在且**可被走到** —— 见 §3.3 的自触发栈 —— 只是基线路径死得更早）。

---

## 4. `A3` · 页级可见降级（判据 3 的那一半）

`FlowDocumentView.Linux.cs` 8 处：① `DocumentPage` 取值器接住（`DocumentPageTextView..ctor` 走它）；② `MeasureOverride`（`EnsureFormatter()`＋`Format()` **同一个 try**）；③ `ArrangeOverride`（同一条第一跳）；④ 顶部闩短路；⑤ `OnRender` 占位；⑥ 占位尺寸常量；⑦ 字段；⑧ `using System.Globalization;`。

**占位长什么样**（`convert -crop` 实拍，见 `$HOME/w86a/logs/w86a-m4/shots/g1/k24.png`）：
洋红矩形（`Brushes.Magenta` = `#FFFF00FF`）+ 2 px 黑边 + 三行字
`此页不支持：PTS / 原生 LineServices 未实现（D-G70 / D-G78）` /
`NOT SUPPORTED on this port: PTS is not implemented.` /
`entry=CreateInstalledObjectsInfo  err=-10000`。

**如实报两条边界**：
1. **只覆盖底流（bottomless）路径**：落点是 `FlowDocumentView`（`FlowDocumentScrollViewer` 与 `RichTextBox` 的 `TextBoxView` 都派生自它）。hc「流文档」页的**缺省页签**按 W78A §2.6 是 `FlowDocumentScrollViewer`（**该条是 W78A 的静态读数，本件未独立复测**）⇒ 判据 3 可达（实测：第 24 项进了 `FlowDocumentView` 的那条路，占位画出来了）；该页的另两个页签（`FlowDocumentPageViewer`/`FlowDocumentReader`）走**分页**路径，本件**未覆盖**（登记为下一步，`NOINFO`）。
2. **每次"新建一个 FlowDocument 视图"会有一次具名异常逃到应用级守卫**（`[HC-UNHANDLED] #2/#3 PtsUnavailableException`）：栈首帧是 `PtsCache.AcquireContextCore` ⇒ 说明有些 `AcquireContext` 调用点**不在我那三处 catch 的覆盖内**（最可能是 `StructuralCache.EnsurePtsContext` 的另一条上游调用链）。⇒ 后果：**具名、可见、进程不死、页面照样降级**（不是静默、不是风暴：同一视图内只发生一次）。**根治配方**：把 `StructuralCache` 也做成派生件（第 3 个 `.Linux.cs`）—— **本件不做**（超出"两件分开做"的范围）。

---

## 5. `N2` 假绿探测器 —— 三格读数（**结论与任务书指定不同，如实报**）

| 格 | 配置 | 假修内容 | 实测 | 判据 |
|---|---|---|---|---|
| **`N2-a1`** | `FAKEOK` shim（`84fc0f6f6bf3753a`）+ 修好的 `A2A3` pf | 6 个入口 `return 0` ＋ 给**假句柄** `0xAAAA0001/2` | `alive=yes`、`magenta=54454`、`[PTS-UNAVAILABLE] entry=CreateInstalledObjectsInfo`、`rc=143`；台账被伪造成 `PTS_GAP … err=0` | **仍绿** |
| **`N2-a2`** | `FAKEOK` shim + **基线** pf（撤 `A2/A3`） | 同上 | `alive=no`、`rc=134`、`magenta=0`、无 `PTS-UNAVAILABLE`；死在 `FontFamily.get_FirstFontFamily`（与基线**同一个汇聚死点**） | **红** ✅ |
| **`N2-b`** | `A1` + `A3BLANK` pf（`0018b509567434df`） | **只把"画占位"那一半拿掉**（闩照立、具名行照打、`Measure` 返 `Size(0,0)`） | `alive=yes`、`[PTS-UNAVAILABLE]` 照打、`pts_unavail=1`，但 **`magenta=0`**（页面空白）、`colors=643`（真修是 851） | **红** ✅ |
| **`N2-c`（`A2` 单独，撤 `A3`）** | `A1` + `A2ONLY` pf（`14a780572064af96`） | 不是"假修"，是**半成品** | `fatal=0`（无 `FailFast`）但 **`guard=7909`**（重试风暴）、`pts_unavail=0`、`magenta=0`、第二项点不到、`rc=124`(仪器 timeout) | **红** ✅（见 §3.4.1） |

### 5.1 为什么 `N2-a1`（任务书指定的那一格）**绿得对**

任务书（与 W78A §3.4 风险 1）的预设是：stub 改成返回成功 ⇒ 假句柄 ⇒ 断言全过 ⇒ **页面空白但进程活着** ⇒ **没有任何红**。
**实测不接受这个预设**：那 6 个入口成功之后，链上**下一个真缺口**（`CreatePTSContext` 里的
`TextFormatterContext()` → `LoCreateContext`，W78A §2.2 组 B）**仍然是缺的** ⇒ 抛 `EntryPointNotFoundException`
⇒ 它落在 `WpfLinuxPtsGap.IsPtsUnavailable` 的**闭集**里（`DllImport` 三族）⇒ **闩照样立、占位照样画、`err` 照样非零**。
⇒ 结论：**"假 stub 必然导致静默半通"这句话在今天这代树上不成立**（假修**不能**让 PTS 路径"半通"到能骗过判据的程度）；
而**判据本身是对的** —— 它判的不是"stub 返回非零"，而是"**页面是否可见地降级 + 原因是否具名 + 进程是否活着**"，
这一格在这三条上**都为真**（`LoCreateContext` 确实不存在，"不支持"确实是真的）。
**但**：`N2-a1` 也暴露出**一条假判据**必须拒绝 —— 台账里的 `err=0`（假修自己写的）。
**任何只 `grep PTS_GAP` 的判据在这一格会被当场骗过** ⇒ 本件的 P2 只认**托管侧**那条（`entry=… err=-10000`）。

### 5.2 `N2-a2` 证明"假修确实危险"（判据在那种配置下确实红）

撤掉 `A2/A3` 之后，假句柄让**断言全过**（`PtsHost.Context` 不再是 `Zero`）⇒ 失败**向下游漂移**，
最后死在 `FontFamily.get_FirstFontFamily`（与基线**逐字同一个死点**）⇒ `rc=134`、页面**空白**、**没有任何具名行**。
⇒ 这正是 W78A §3.4 想防的"**把 FailFast 变成别的东西**"（只是它的形态不是"静默半通"，而是"**换个地方死**"）。

### 5.3 `N2-b` 才是"不许把空白读成绿"的牙（**建议主控用这一格替换任务书里的 N2**）

`N2-b` 只改一处（占位不画），**其余全部不变**（闩、具名行、`alive`、`rc` 都相同）⇒
**判据的唯一变红理由就是"页面空白"** ⇒ 实测变红。**成对反极性成立**：
`真修 ⇒ magenta=54454（PASS）` ／ `假修 ⇒ magenta=0（FAIL）`。

### 5.4 第一道牙（native 侧，机器可读）

`WpfLinuxWin32_PtsGapSelfCheck()`：真 stub = **1**，`FAKEOK` = **0**（实测）。
⇒ 谁**将来**"顺手"把 `return` 改成 0，这道牙当场变红（不必等应用跑起来）。

---

## 6. 零回归

| 判据 | 读数 |
|---|---|
| **正常页像素逐位相同** | `compare -metric AE`（同一 item 0 = `BrushDemo`）：`BASE` pf 截图 vs `A2A3` pf 截图 = **`0`**（色数同为 1149）⇒ 我的改动对**非 PTS 页零墨差** |
| 导航/文本框/下拉/页签仍可用 | 失败之后依次点 0/9/10/16：`alive=yes`、应用自报 `[NS] loaded …BrushDemo / NativeTextBoxDemo / NativeComboBoxDemo / NativeTabControlDemo`、`AE>0` |
| `hbtextline` / `pc` | **未触碰**（`build/shims/**`、`build/PresentationCore.Linux/**` 我一次都没写）：`hbtextline_shim=921ba9c65e9fb3be`、`pc=56ee75ced8d6aece` |
| 生成物指纹（只读核对器） | `python3 build/artifact-src-fp.py --check` ⇒ `PC state=ok`、`WB state=ok`、**`PF state=stale kind=src`**（= 恰好只有 PF 的源变了 ⇒ 反向证明我只动了 PF 侧源） |
| 应用器审计（只读） | `bash build/check-appliers.sh` ⇒ **`APPLIER_AUDIT_SUMMARY appliers=26 ok=89 miss=0 red=0 rc=0`** |
| ⚠️ 已登记：**本件的注入面不在该审计覆盖面内** | `applier-audit` 只审 `patch-*.py`；`reapply-patches.py` **不在**其中 ⇒ "登记了但没生效"这件事对本件由**另外三道**看着：① needle 命中数不符 ⇒ **rc≠0 拒绝产出**；② 派生件 vs 上游 `diff`（**能逐行看**）；③ 产物里能 `strings`/字节搜到注入串（本件实测 4 条命中，见 §7③） |

---

## 7. 新 sha16 · 位移表 · 复现

### ① 新 sha16（全部现场 `sha256sum` 算，无手抄）

```
win32shim = 24e906c194903c8b    (src/WpfGfx.Linux.Native/bin/libwpfwin32.so, 323,008 B)
pf        = 2a5b7641f6fba0fb    (build/PresentationFramework.Linux/bin/Release/PresentationFramework.dll, 6,123,008 B)
```

⚠️ **`pf` 的 provenance 必须说清（否则读数是悬空的）**：
- 本件**产品读数**（§4/§6 与 `$HOME/w86a/logs/w86a-m6/`）用的是 **`2a5b7641f6fba0fb`**（交付中的现值）；
- 同一组读数在 `78218dd1851d41e8` 上也取过一次（`w86a-m4`，结果**逐项相同**：`magenta=54454 / 0 / 49864`）；
  **两版 PF 的源件 sha16 逐位相同**（`PtsCache.Linux.cs=627c8d23aa7ef233`、
  `FlowDocumentView.Linux.cs=ecb0263b200c18dc`、`csproj=8dc2ac5475fe616e`）⇒ 差异**不来自本件**；
- 会话期间 `build/artifact-src-fp.py --check` 两次报 **PF 与 PC 的源指纹都被别人改过**
  （`PF fbb30dc680b39c36 → 5b38ea7420b26377`；`PC n=1373 → 1374`，`fp fe90cbf1a52a030c → aac8e131b12d3607`）
  ⇒ **多车道并行的树**上 `pf` 的字节不可复现（`artifact-src-fp.py` 头注："Roslyn 把被引件字节纳入输入哈希 ⇒ `pf` 每波必变"）。
  **本车道的三个源件在整个会话中一字未变**（可复核上面三个 sha16）。


### ② 九位逐位（开工复算 = `#49` 冻结值 → 本件后）

| 位 | #49 冻结 | 本件后 | 动？ |
|---|---|---|---|
| `bridge` | `feef049e9d0e313a` | `feef049e9d0e313a` | — |
| `pc` | `56ee75ced8d6aece` | `56ee75ced8d6aece`（**本件读数期间**；⚠️ 会话末尾实测 `bin/Release` 已变成 `eb452af9a1c1cfae` —— **别的车道在重建 PC**，本件一字未碰，见 §7⑦） | —（非本件） |
| **`pf`** | `6375fabf89ac7fef` | **`2a5b7641f6fba0fb`** | **✅ 预期**（来源见上方 provenance） |
| `windowsbase` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` | — |
| `provider` | `1f9511a7ef395bfe` | `1f9511a7ef395bfe` | — |
| **`win32shim`** | `3e4390c9ec07f621` | **`24e906c194903c8b`** | **✅ 预期** |
| `wic_shim` | `f7b3026c8c019be2` | `f7b3026c8c019be2` | — |
| `hbtextline_shim` | `921ba9c65e9fb3be` | `921ba9c65e9fb3be` | — |
| `dwf` | `de2d555105b7d04b` | `de2d555105b7d04b` | — |

⇒ **表外位移：无**（`pf` 与 `win32shim` 就是任务书点名的两位）。

### ③ 产物里确实有注入的代码（"登记了但没生效"的第三道牙）

`pf`（`2a5b7641f6fba0fb`；`78218dd1851d41e8` 上同样做过一遍）字节搜（`UTF-16LE` 用户串 / UTF-8 元数据）：
`PTS-UNAVAILABLE`×1(utf16)、`PTS 能力不可用`×1(utf16)、`PtsUnavailableException`×1(utf8)、
`WpfLinuxWin32_PtsGapReport`×1(utf8)、`FlowDocumentView.DocumentPage`×1(utf16)。
`win32shim`：`nm -D --defined-only` 里 6 个入口 + 5 个机读面**全部在**（535→546）。

### ③′ ⚠️ 会话期间**别的车道**在同一条树上动了两处（必须点名，否则我的读数是悬空的）

| 观测 | 读数 |
|---|---|
| **PC 产物换代** | 开工→全程读数用 `pc=56ee75ced8d6aece`（当时 Debug/Release 一致）；**收工前实测** `bin/Release=eb452af9a1c1cfae`（`bin/Debug` 仍 `56ee75ce…`）⇒ 有车道只重建了 Release |
| **PC/PF 的源指纹被别人改过** | `artifact-src-fp.py --check`：`PC n=1373 → 1374`、`fp fe90cbf1a52a030c → aac8e131b12d3607`；`PF fp fbb30dc680b39c36 → 5b38ea7420b26377`（**PF 的 `peer_fp` 未变**） |
| **对我读数的影响** | **零可见影响**：每趟 `five_pre_g*.txt` 逐件印 sha16（`PresentationCore.dll=56ee75ced8d6aece`、`wpfgfx_cor3.so=feef049e9d0e313a`…）⇒ 读数与件**绑定可查**；同趟 `FIVE_STABLE_G*=YES`（跑的过程中件没被换） |
| **我没有做什么** | **没有**跟着重同步 app-local：会话末尾 `sync-applocal --check` 报 `PresentationCore.dll` 漂移 ⇒ **故意不写**（那会把"读数绑定的 PC"换掉，而 PC 不属本件）⇒ 交给波尾 |

### ④ `inputs_fp` 与复现命令

- **`inputs_fp` 会变**（**不改**：本件跑不了 `close-wave.sh` ⇒ 我**不算**这个值，只给"必然变"的**结构性理由**）：
  覆盖面含 `find src/WpfGfx.Linux.Native -type f \( -name '*.c' -o -name '*.h' \)`（`close-wave.sh:120-122`）⇒
  **新文件 `src/win32_pts.c` 在覆盖面内**。
- ⚠️ **同时报一条覆盖面缺口**：`build/PresentationFramework.Linux/reapply-patches.py` 与
  `build/PresentationFramework.Linux/*.Linux.cs` **都不在** `fp_inputs` 的覆盖面内
  （它只收 `build -maxdepth 2 -name 'patch-*.py'` ＋ 一张显式表）⇒ **本件的 `A2/A3` 那半个改动对 `inputs_fp` 不可见**，
  只有 `ARTIFACT-SRC-FP`（PF 维度 A 第 2/4 项）看得见它。建议主控把 `reapply-patches.py` 纳入（同 `D-G22`/`D-G27` 族）。
- 复现（本件用的**全部**命令，逐条可跑）：

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux; cd $R
bash src/WpfGfx.Linux.Native/build-shim.sh --symbols            # ① A1 构建 + 导出清单
python3 build/PresentationFramework.Linux/reapply-patches.py    # ② A2/A3 生成物 + csproj 接线（幂等）
bash ~/heavy-slot.sh --min-avail 1500 --max-hold 400 --wait 1800 -- timeout 380 \
     env PATH="$HOME/.dotnet:$PATH" DOTNET_gcServer=0 \
     dotnet build build/PresentationFramework.Linux/PresentationFramework.Linux.csproj -c Release -m:1 --nologo -v q
bash build/MilBridge/tools/sync-applocal.sh --check <hc app 目录>   # ③ 应用目录 == 权威
W86A_TMO=140 W86A_MAXHOLD=290 bash ~/w86a/bin/run.sh <tag> 'A1+A2A3:24,0,9,10,16,23'   # ④ 产品读数
python3 build/artifact-src-fp.py --check ; bash build/check-appliers.sh              # ⑤ 只读旁证
bash build/MilBridge/tools/baseline-sha-check.sh                                     # ⑥ 基线三态（只读）
```

### ⑤ 环境与件（可复核）

- 被测应用 = `hc-linux` 的 `HandyControlDemo.dll` `1ac5e587cda3fb20`（**未改**）；
  应用目录五件由 `sync-applocal.sh` 从**仓内权威**同步（`SYNC-APPLOCAL=PASS`，manifest 在应用目录 `.applocal-sync.tsv`）。
  ⚠️ **开工时应用目录是陈旧的**（`libwpfwin32.so`=`11aa9d8fa154f20f`、`PresentationCore.dll`=`9465f9dce39e2dfc`、`PresentationFramework.dll`=`1011da6390c3bf1e`、`wpfgfx_cor3.so`=`79e45aed26487045`）
  ⇒ **所有读数都是同步之后取的**（同一趟里逐组 `FIVE_STABLE_G*=YES`）。
- 装置：`Xvfb :196` + `xfwm4`；`$HOME/w86a/**`（`launch.sh`/`session_inner.sh`/`run.sh`/`navclick.py`/`shotstat.py`）；日志 `$HOME/w86a/logs/w86a-{m1..m5,n2a2,n2b,smoke}/`。

### ⑥ 我自己抓到的 6 个**仪器**缺陷（都必须点名）

| # | 缺陷 | 后果 | 处置 |
|---|---|---|---|
| ① | `launch.sh` 在 `set -u` 下**先用了 `$TAG`** | X **根本没起**，应用抛 `Win32Exception (1400)` ⇒ **假 `rc=134`**（`w86a-smoke` 那趟，**已作废**） | 修 + 加 **`X_UP=yes/no` 自证行**（环境没起来必须出声，`D-G59` 同族） |
| ② | 复用 W60A 的 `navsweep.py`：**点到了第 26 项而读数写着 `K=24`**（应用自报 `BorderDemo`） | "认错对象，读数照给"（`D-G79` 同族） | 自写 `navclick.py`：**坐标稳定才点** ＋ **拥有者核对**（点必须落在 `item[k]` 自己的矩形里）＋ **身份按应用自报**（`[NS] loaded …`） |
| ③ | `navclick.py` 的 `^\[NS\]` **没加 `re.M`** | `expect_hit` 恒 `no` ⇒ **仪器假红**（日志里 `[NS] loaded …FlowDocumentDemo` 明明在） | 加 `re.M`，重取读数（`w86a-m4`：`expect_hit=yes`） |
| ④ | 第一版 `A3` 只把 `try` 罩住 `_formatter.Format()` | **`EnsureFormatter()` 才是第一跳** ⇒ 占位一次都没画、异常逃逸 | try 扩到 `EnsureFormatter()`；并把 `DocumentPage`/`ArrangeOverride` 两处也接住（§4） |
| ⑤ | 第一版 `A2` 用会**断言的 getter** 当判据 | **自触发 `FailFast`**（§3.3） | 改成按对象身份（§3.3） |
| ⑥ | 把 PF 构建放进**前台** bash 调用 ⇒ 撞工具 60 s 超时 | 构建被打断，**跑的是上一版 dll**（`w86a-a2only` 那趟作废） | 长构建一律走**后台任务**；重取（`w86a-a2only2`）；并把"产物 sha16"与"读数"绑定复核 |

---

## 8. `NOINFO`（既不算绿也不算红）

1. **`PtsCache._contextPool` 的"池计数/句柄值"** —— 没有任何仪器能读（唯一外部观测点是那个会断言的 getter）。**用行为读数替代**，但**不声称**"池里干净了"。
2. **27 条清单的第 2 条及以后** —— 设计上第一跳就如实失败 ⇒ **观测不到**（"还没轮到"，不是"不需要"）。
3. **每次新建视图那一次逃逸异常的准确入口** —— 只知道栈首帧 `PtsCache.AcquireContextCore`（`[HC-UNHANDLED] #2/#3`）；它属于哪一条上游调用链**未定性**。
4. **分页路径**（`FlowDocumentPageViewer`/`FlowDocumentReader` 两个页签、`DocumentPageView`）**未测** ⇒ 那一格是否有占位**未知**。
5. **hc 的 `Effects` 页**（在 `Tools` 组第 3 项，需要先切顶层 TabControl）—— 本件矩阵**没驱动那一层** ⇒ "Effects 仍可用"**本件不判**（只判了同一组内的 导航/文本框/下拉/页签，见 §6）。
6. **占位的几何正确性**（尺寸/DPI/字体回退是否在别的 DPI 下也可见）—— 只测了 1280x1024x24、`Xvfb` 无 WM 缩放的这一种。
7. **`W81A-report.md` 的 `A0` 读数用的是旧 `:97` 环境**（且报告 sha16 与派单书不一致，见 §0 抬头）：本件**未重取** `A0`，只引用其结论。
8. **`inputs_fp` 的具体新值** —— 本件不许跑 `close-wave.sh` ⇒ **只给结构性理由**（§7④）。
9. **"`A2` 单独"那 7,909 条异常的**准确计数机制**（为什么是 7090 量级而不是无限/更少）—— 只知道它随布局次数增长、随第二次点击前停住；**未定性**。
10. **`bridge`/`provider`/`wif_shim`/`dwf` 与本件无关这一点**只按"我没碰它们的源"断言（`ARTIFACT-SRC-FP` 只覆盖 PC/WB/PF 三个工程）⇒ 那五位的"零位移"**不是**被机器看着的。

---

## 9. 内存三值 ／ 纪律自证

- `MemAvailable`：**开工 1969 MB**（首次 `build-shim.sh` 前）｜**全程最低 1969 MB**（其余读数区间 **2097–2685 MB**）｜**收工 1811 MB**。
- `loadavg`：**峰值 3.70**（第一趟矩阵收工时实测）→ **收工 1.38**；`nproc=3`。⚠️ **开工那一刻的 `loadavg` 我没有取**（当时只取了 `MemAvailable`）⇒ 那一格**如实记 `NOINFO`**，不补一个"看起来合理"的数。
- **所有** `dotnet`（PF 构建 **6 次**、应用启动 **13 次**）都在 `~/heavy-slot.sh --min-avail 1500` 之内；本车道**从未**绕过槽。
  槽读数：`HEAVYSLOT=ACQUIRED/MEMOK/RELEASED` 全绿；**无** `MAXHOLD_KILL`、**无** `low-memory`、**无** `TIMEOUT`。
  ⚠️ 其中 **2 趟作废**并已点名：`w86a-smoke`（X 没起来，假 `rc=134`，仪器缺陷 ①）、
  `w86a-a2only`（构建被我的 shell 超时打断 ⇒ 跑的是**上一版** dll；已用 `w86a-a2only2` 重取）。
- 零 `pkill`（按 PID 收自己的 `Xvfb`/`xfwm4`/`dotnet`）；**没有**用 `pgrep -f`/`ps|grep` 下过任何结论。
- 改前 `cp -p` 备份：`$HOME/w86a/backup/{build-shim.sh.before, reapply-patches.py.before, PresentationFramework.Linux.csproj.before, win32_pts.c.A1, FlowDocumentView.Linux.cs.A3}`；**假修撤销后逐字节回位**（`pf` 与 `~/w86a/dlls/PresentationFramework.A2A3.dll` `diff` 空 ⇒ `ROUNDTRIP=YES`；`win32_pts.c` 复原后重建 ⇒ `win32shim` 又等于 `24e906c194903c8b`）。
- 未触碰：`build/shims/**`、`build/PresentationCore.Linux/**`、`build/DirectWrite.Linux/**`、`build/MilBridge/tools/**`、四个路由件、`defect-registry-declared.tsv`、`known-red.json`、`arm-logs/**`；**未跑** `integration-wave.sh`/`close-wave.sh`/`verify-all.sh`/`frame-step.sh`。

---

## 10. 大白话小结（6 行）

1. 以前点「流文档」= **整进程死**；现在点它 = **页面自己画一块洋红牌子写着"本页不支持 + 缺哪个入口 + 错误码"，进程照常活着**，还能接着点别的页。
2. 缺口的"名字"是真的从原生侧传上来的（`entry=CreateInstalledObjectsInfo err=-10000`），不是我们猜的、也不是文案。
3. 我修了两件事：原生侧**如实报错**（不装成功），托管侧**把失败留下的半初始化状态清掉** —— 后者才是"必死"的根因。
4. **最危险的一格不是"崩"，是"假装能跑"或"半成品"**：假句柄又没有兜底 ⇒ 进程**换个地方死**；只有 `A2` 没有 `A3` ⇒ 不死但**刷 7,909 条异常**、页面量不出来。两格**判据都判红**。
5. 任务书指定的那格反极性（stub 返回成功）**没有变红**，我如实报并解释它为什么**绿得对**；另补了**真能变红**的两格（只降级不画 ⇒ 空白 ⇒ 红；只有 `A2` ⇒ 风暴 ⇒ 红）。
6. 页面**还不能用**（`R3` 长线一件没做）；这件的价值是"**把不会做的事，说清楚、看得见、能判**" —— 而且**不许把空白、把"进程还活着"读成绿**。

# W56A 报告 —— `D-G65`（等待桩 ⇒ 启动即死）修法 + 两极化验证

> 车道 W56A｜2026-09-20 12:2x→13:2x +0800｜kernel `6.8.0-138-generic`｜`nproc=3`
> 仓根 `$R = /home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> **结论在前**：
> 1. **选中候选 A（托管层）**：`DispatcherSynchronizationContext.Wait` 的两分支合一，都走托管
>    `SynchronizationContext.WaitHelper` —— Linux 上它**真等待**（实测 300 ms 超时返回 258、有信号返回 0），
>    且它**满足 CLR 的等待通知契约**（真等到锁 + 真持锁）。
> 2. **候选 B 的两种形态都不落地**，各有实测否证：
>    · 派单书写的 `WAIT_TIMEOUT` ⇒ **违反 CLR 契约**：CLR 会在**没持锁**的情况下把 `lockTaken` 置真
>      ⇒ 临界区**无互斥执行** + `Monitor.Exit` 抛 `SynchronizationLockException`（§3.3 给原文）；
>    · 我改的 `WAIT_OBJECT_0` 形态**能过契约**，但它**把阻塞变成了自旋（忙等烧 CPU）**
>      ⇒ 撞 `D-G65` 登记里写死的判据③（"不许把'等待'变成'忙等烧 CPU'"）⇒ 也不落地（§3.4 给 CPU 对照）。
>    ⇒ **shim 一个字节没改**（sha16 逐字节回到 `c2674871b09e8e0e`，§2）。
> 3. **派单书的一句被推翻**：「用**并发两实例**做**确定性**触发」不成立 —— 双实例的第二实例
>    **确定性**死于**另一条**已登记过的缺陷（`ShutdownMode`，`InvalidOperationException`），
>    与 `D-G65` 无关；`D-G65` 是**概率性**的（§3.5 给成对读数）。
> 4. 本车道造出了 `D-G65` 的**确定性最小复现**（不依赖概率、与产品应用无关的探针，§3.1）。

---

## §0 环境

| 项 | 读数 |
|---|---|
| 显示 | `:171`（自建无 WM 的 `Xvfb -screen 0 1280x1024x24`）；未碰 `:151/:152/:168/:169` |
| 私有应用目录 | `$HOME/w56a/app`（`cp -a` 自 `/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0`） |
| 五件（**修前**，`$HOME/w56a/app`） | `libwpfwin32.so c2674871b09e8e0e`／`wpfgfx_cor3.so e3ea092010734f44`／`PresentationCore.dll 9465f9dce39e2dfc`／`PresentationFramework.dll 1011da6390c3bf1e`／`WindowsBase.dll 79740e9ba7fbf9ca` |
| 五件（**修后**，`$HOME/w56a/app`） | `libwpfwin32.so c2674871b09e8e0e`（**未变**）／`wpfgfx_cor3.so e3ea092010734f44`（未动）／`PresentationCore.dll 9465f9dce39e2dfc`（未动）／`PresentationFramework.dll 1011da6390c3bf1e`（未动）／`WindowsBase.dll 2e4e46e539a72cd7`（A） |
| `MemAvailable` | 开工 2753 MB／最低 2461 MB／收工 2540 MB（全程未触发 `<1200 MB` 等待；同一时刻只跑一个重活） |
| `loadavg` | 1.00 1.00 0.92 |
| 报告自身 sha16 | `3bbeea47464cbcd6`（**回填前读数**；口径见 §8） |

---

## §1 选了哪条候选、为什么

### 1.1 候选 A（**选中**）：托管层 —— `Wait` 两分支合一 ⇒ 都走 `WaitHelper`

**机制先被证实**（不是"看起来对"）：

1. `DispatcherSynchronizationContext` 的构造函数调用 `SetWaitNotificationRequired()`（上游 `:43`）
   ⇒ 该线程上 **CLR 会把"锁阻塞"交给当前 `SynchronizationContext`**。探针实测：
   `Monitor.Enter` 争用时真的进了 `DispatcherSynchronizationContext.Wait`（§3.1 的栈与用户日志逐帧同）。
2. `Wait` 上游按 `_dispatcher._disableProcessingCount > 0` 分叉，非零时调 **Win32**
   `WaitForMultipleObjectsEx`（上游 `:91`）⇒ 本工程那条是失败桩（`win32_misc.c:385`）
   ⇒ 包装层 `result == WAIT_FAILED` 即抛（`UnsafeNativeMethodsOther.cs:135`）⇒ **进程死**。
3. **为什么那条 Win32 路"修不好"**：CLR 传进来的"句柄"是 .NET 运行期等待子系统的内部对象 id ——
   探针把 CLR 真正传的参数打出来了：`Wait nCount=1 waitAll=False ms=-1 handle[0]=0xf0`
   （`0xf0` 是对象 id 的形态，不是 Win32 HANDLE）。宿主的 C 代码无法 wait 它。
   **⇒ 只能改"别走那条路"，不能改 shim 让它"能等"。**（这一条也是 B 不能当修法的根据。）
4. **`WaitHelper` 在 Linux 上真等待**（探针 `wh` 模式，`WindowsBase.dll 79740e9ba7fbf9ca`）：
   无信号 + 300 ms ⇒ `ret=258 (WAIT_TIMEOUT) elapsed_ms=301`；400 ms 后置信号 ⇒ `ret=0 (WAIT_OBJECT_0) elapsed_ms=400`。
5. **它满足契约**（探针 `helperdisp` 模式，与修法后的代码同语义）：
   `WaitHelper` 在 CLR 给的锁事件上真等到 ⇒ `ENTER taken=True elapsed_ms=2507`（持有者持锁 2500 ms）
   ⇒ `EXIT OK`。**"真等到锁 + 真持锁"**，不是自旋。

⇒ 因此候选 A 是**正确性最好的**那条：它把这条等待交回运行期自己的等待子系统，不碰任何 Win32 消息队列
（上游分叉的**目的** —— "避免 CLR 的锁等待替我们泵消息" —— 是 Windows 专属考量；本平台由 `WaitHelper`
满足且不引入重入）。

### 1.2 功能上是否等价？（改动的语义边界）

上游分叉为真时，两条路在 **Windows** 上都是"阻塞到锁可得"，差别只在**谁在等待期间泵消息**。
本平台的实测事实是：`WaitHelper` **只碰 .NET 等待子系统**、不派发任何 WPF 消息
⇒ 上游想避免的那件事（消息重入）在本平台由它天然满足。**这不是"降级"，是把 Windows 专属的分叉去掉。**

### 1.3 候选 B（**派单书写的 `WAIT_TIMEOUT` 形态**）：**实测否证**，没有落地

我按派单书写了第一版 `return WAIT_TIMEOUT`，并**造了确定性探针**去验（`contract<ret>` 模式：
用一个"返回值可控"的 `SynchronizationContext` 替换真实等待，把 CLR 之后的动作逐步打印）：

| 探针读数（`probe.dll contract258`，`Wait` 返回 258） | 原文 |
|---|---|
| `[ctx] Wait #1 nCount=1 waitAll=False ms=-1 ⇒ return 258` | CLR 只调了 1 次 |
| `[contract258] ENTER RETURNED taken=True elapsed_ms=5 (holder 仍持锁? True)` | **`Monitor.Enter` 在 5 ms 就返回，而持有者仍在锁内** |
| `[contract258] EXIT THREW SynchronizationLockException: Object synchronization method was called from an unsynchronized block of code.` | 临界区跑完了，`Exit` 才发现自己**根本没持锁** |

**⇒ CLR 的等待通知契约是「`Wait` 返回即视为你替我拿到了」**。返回非 `WAIT_OBJECT_0` ⇒
① 临界区**在无互斥保护下执行**（数据竞争）；② 随后 `Monitor.Exit` 抛未处理异常 ⇒ **照样进程死**。
**它既没修好、又比原来更坏**（把"响亮的失败"换成"静默的竞争 + 失败"）。所以这一形态**不落地**。

### 1.4 候选 B′（我改的 `WAIT_OBJECT_0` 形态）：**能过契约，但撞登记里的判据③ ⇒ 也不落地**

**为什么我一开始还想留它**：同一个失败桩还有**第二个、且"无条件"的**调用点：

* `Shared/MS/Internal/ReaderWriterLockWrapper.cs:287-290` 的
  `NonPumpingSynchronizationContext.Wait` —— **没有** `disableProcessing` 守卫，直接调同一条原生等待；
* 它由 `CallWithNonPumpingWait`（同文件 `:142-175`）在**每一次** `WeakEventTable` 读写锁进出处装上
  ⇒ 只要那里的锁被争用，就抛 `Win32Exception (50)` ⇒ 进程死；
* 这个站点**不在本应用器的写域内**（要改 Shared 源，且它被编进 WB/PC/PF/UIAutomation 四个工程）。

**B′ 能不能过契约？能**（探针 `nopump`：`ACQUIRED elapsed_ms=2490`、`EXIT OK`；CLR 的用法就是
"返回 0 ⇒ 重新检查锁并再调 `Wait`"，实测一次争用里连调 **173,672** 次直到拿到锁）。

**那为什么还是不落地？** 因为它**把阻塞变成了自旋**，而 `D-G65` 的**登记判据③**写死了
「**不许把"等待"变成"忙等烧 CPU"（记录 CPU 占用作对照）**」（`docs/WAVE49-PREREGISTRATION.md:434`）。
本波按它取了对读数（§3.4）：A 的等待 2.5 s 里 **user+sys ≈ 0.0 s**（真阻塞）；
B′ 在同样 2.5 s 里 **user+sys ≈ 2.4 s**（烧满一个核）。⇒ **判据③不容许**，B′ 也不落地。

**⇒ 最终只落 A 一条**：shim 一个字节不改（`win32_misc.c` 与 `libwpfwin32.so` 都逐字节回到原值，§2）。
站点② 作为**同族的第二个潜在站点**如实入册（§6-1），并给出它**正确的**修法方向
（与 A 同一句话：把 `NonPumpingSynchronizationContext.Wait` 也交给 `WaitHelper`）——
那需要 Shared 源 ×4 工程的生成式接线，**超出本车道写域**，留给下一波。

---

## §2 改动逐处（`文件:行` + before/after sha16）

| # | 文件 | 改动 | before sha16 | after sha16 |
|---|---|---|---|---|
| 1 | `src/WpfGfx.Linux.Native/tools/patch-windowsbase-focus-wait.py` | **新增**应用器（锚点 + 守恒/删项/禁止项断言 + 幂等 + `--check` + `--prove`） | （新文件） | `e0e1966593fdde89` |
| 2 | `build/WindowsBase.Linux/DispatcherSynchronizationContext.Linux.cs` | **生成物**（上游逐字 + 1 处修法） | （新文件） | `c96e768c84026759` |
| 3 | `build/WindowsBase.Linux/WindowsBase.Linux.csproj` | `Remove` 上游 + `Include` 生成物（`MARKER` 幂等块） | `8c042aaf537eb0d0` | `f92471498f3bd7a5` |
| 4 | `build/WindowsBase.Linux/bin/Release/WindowsBase.dll` | **重建**（九位之一 `windowsbase`） | `79740e9ba7fbf9ca` | `2e4e46e539a72cd7` |
| 5 | `build/integration-wave.sh` | `APPLIERS_EXPLICIT+=( patch-windowsbase-focus-wait )`（+ 8 行理由） | `851f8b2766cfa94a` | `4f931b4566f9d6dc` |
| 6 | `build/MilBridge/tools/applier-audit-expected.txt` | 登记同名一行（**独立**清单，摘掉才会红） | `3b031d92df5ea62d` | `0ea290cf723f396a` |
| — | `src/WpfGfx.Linux.Native/src/win32_misc.c` | **改过又回退**（B / B′ 两形态都不落地，见 §1.3/§1.4） | `b09058febe5954e4` | **`b09058febe5954e4`**（逐字节原样） |
| — | `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` | **改过又回退**：三形态实测后复原 | `c2674871b09e8e0e` | **`c2674871b09e8e0e`**（逐字节原样） |

**唯一落地的语义改动**（生成物里的那一处；上游 130 行 → 142 行，`+12`）：

```csharp
public override int Wait(IntPtr[] waitHandles, bool waitAll, int millisecondsTimeout)
{
    // …（14 行说明为什么本平台可以把两个分支合一；见生成物文件头）
    return SynchronizationContext.WaitHelper(waitHandles, waitAll, millisecondsTimeout);
}
```

**被改过又回退的两件（如实入册）**：为了给候选 B 的两个形态取数，我先改了 `win32_misc.c`
（`WAIT_TIMEOUT` → 又改 `WAIT_OBJECT_0`）并各重建过一次 shim（`8e6c9b21a7b2ddf5` / `b9ee44a7bb954bd1`），
取完数后 `cp -p` 回退 + 重建 ⇒ `sha16` **逐字节回到 `c2674871b09e8e0e`**（`diff` 空）。
**⇒ 九位里只有 `windowsbase` 一位变，`win32shim` 未变。**

---

## §3 两极化表

### 3.1 站点①：`DispatcherSynchronizationContext.Wait`（**确定性探针**，不依赖概率）

装置：`$HOME/w56a/probe`（30 行 C# 控制台，直接引用权威 `WindowsBase.dll` + app-local `libwpfwin32.so`）。
它做的三件事与产品完全同构：`Dispatcher.CurrentDispatcher` → `new DispatcherSynchronizationContext(d)`
（构造函数里 `SetWaitNotificationRequired()`）→ 另一线程先持锁 2.5 s → 本线程 `using (d.DisableProcessing()) lock(gate){}`。

| 极性 | 命令 | 读数 | 判定 |
|---|---|---|---|
| **修前**（`WindowsBase.dll 79740e9ba7fbf9ca`） | `DISPLAY=:171 dotnet probe.dll disp` | `[disp] hold=yes waitNotificationRequired=True` → `THREW System.ComponentModel.Win32Exception: No CSI structure available elapsed_ms=0`，栈 `UnsafeNativeMethods.WaitForMultipleObjectsEx:137` ← `DispatcherSynchronizationContext.Wait:91` ← `Monitor.Enter_Slowpath` | **红（逐帧同用户日志）** |
| **修后**（`WindowsBase.dll 2e4e46e539a72cd7`） | 同上 | `[disp] hold=yes waitNotificationRequired=True` → **`ACQUIRED elapsed_ms=2498`**（持有者持锁 2500 ms）⇒ **真等到锁、`EXIT OK`** | **绿** |

### 3.2 站点②：`ReaderWriterLockWrapper.NonPumpingSynchronizationContext.Wait`（**确定性探针**）

装置：`probe.dll nopump` —— 复刻上游 `ReaderWriterLockWrapper.cs:273-290` 的上下文
（`SetWaitNotificationRequired()` + `Wait` ⇒ 原生等待 + `WAIT_FAILED 即抛`），再制造一次 Monitor 争用。

| 极性 | 探针读数 | 判定 |
|---|---|---|
| **修前**（shim `c2674871b09e8e0e`） | `[nopump] hold=yes` → `THREW System.ComponentModel.Win32Exception: No CSI structure available elapsed_ms=6`，随后 `Unhandled exception … rc=134` | **红（进程死）** |
| **`WAIT_TIMEOUT` 形态**（已否证，未落地） | `THREW System.Threading.SynchronizationLockException: Object synchronization method was called from an unsynchronized block of code. elapsed_ms=6` | **红（换了个签名，仍死）** |
| **B′**（shim `8e6c9b21a7b2ddf5`，**未落地**） | `[nopump] ACQUIRED elapsed_ms=2490` → `RC=0` | **绿（等到锁、无异常）** |
| **修后（最终树：只落 A，shim 逐字节复原）** | `[nopump] hold=yes` → `THREW System.ComponentModel.Win32Exception: No CSI structure available elapsed_ms=3` → `rc=134` | **仍红 —— 这是刻意的**：站点② 不在写域内，A 只修站点①；它作为**同族的第二个潜在站点**入册（§6-1） |

### 3.3 CLR 契约实验（**否证 `WAIT_TIMEOUT` 形态的判据**）

装置：`probe.dll contract<ret>` —— 用一个"返回值可控"的 `SynchronizationContext` **替换**真实等待，
用**显式** `Monitor.Enter/Exit`（而不是 `lock`）以便分辨"哪一句抛 / 临界区是否在没持锁时跑了"。

| `Wait` 的返回 | 探针读数（原文） | 结论 |
|---|---|---|
| `0`（`contract0`） | `[ctx] Wait #1 nCount=1 waitAll=False ms=-1 handle[0]=0xf0 ⇒ return 0`，随后 CLR **重新检查锁并再次调用**（本趟共 **173,672** 次）直到拿到锁；`[contract0] EXIT OK` | **正确形态**：返回 0 ⇒ 调用方自旋重试（不是"你拿到了"） |
| `258`（`contract258`） | `[contract258] ENTER RETURNED taken=True elapsed_ms=5 (holder 仍持锁? True)` → `[contract258] EXIT THREW SynchronizationLockException: Object synchronization method was called from an unsynchronized block of code.` | **违反契约**：CLR 在**没持锁**时置 `taken=True` ⇒ 临界区**无互斥执行** + 未处理异常 ⇒ **照样死** |

### 3.4 判据③（"不许把等待变成忙等烧 CPU"）的对照读数

装置：`/usr/bin/time -f "wall=%e user=%U sys=%S"` 包住同一段"争用 2.5 s 的锁"的探针（`CUTOFF` 与产品腿无关）。

| 形态 | 命令 | `wall` | `user+sys` | 判定 |
|---|---|---|---|---|
| **A**（`WaitHelper`，真阻塞） | `probe.dll helperdisp` | 2.53 s | **0.03 s** | ✅ **真等待**（阻塞期间不烧 CPU） |
| **B′**（shim 返回 `WAIT_OBJECT_0`，自旋） | `probe.dll nopump`（shim `b9ee44a7bb954bd1`） | 2.52 s | **2.50 s** | ❌ **忙等**（烧满一个核）⇒ 撞判据③ |
| **B′ 单独护站点①**（旧 `WindowsBase.dll` + B′ shim） | `probe.dll disp` | 2.63 s | **2.61 s** | ❌ 功能上"能过"（`ACQUIRED elapsed_ms=2498`，不再抛异常），但代价是同样 2.5 s 的满核自旋 |

⇒ **同一条缺陷有三种"能过"的写法，只有 A 是"真等待"**：B′ 在站点①/② 都能让它不抛异常，
但两份读数都证明它是**忙等** —— 判据③写死不许，所以 A 是唯一落地的形态。

### 3.5 产品级：并发两实例（**成对**）

装置：`$HOME/w56a/bin/runs.sh <tag> dual <N> :171`（**仪器全关**：不设任何 `HC_*`/`WPF_LINUX_*`）。
实例 1 起好后等 12 s 再起实例 2；`alive` 由**见证文件**是否写定，签名由日志计数定。

| 极性 | 趟 | 实例 | `alive` | 退出码（见证文件 `*.rc`） | `Win32Exception(50)` | `Cannot set ShutdownMode` | 其它 |
|---|---|---|---|---|---|---|---|
| **修前** | 1 | inst1 / inst2 | yes / no | `?`（inst1 收工时被杀，见证文件未落） / `134` | 0 / 0 | 0 / **1** | inst2 死于**单实例互斥**那条缺陷 |
| **修前** | 2 | inst1 / inst2 | yes / no | `?`（inst1 收工时被杀，见证文件未落） / `134` | 0 / 0 | 0 / **1** | 同上 |
| **修前** | 3 | inst1 / inst2 | **no / no** | `134` / `134` | **1 / 1** | 0 / 0 | inst1 先死于 `D-G65` ⇒ 互斥被释放 ⇒ inst2 当成首实例启动，**自己也死于 `D-G65`** |
| **修后** | 1 | inst1 / inst2 | yes / no | `?`（inst1 收工时被杀，见证文件未落） / `134` | 0 / 0 | 0 / **1** | inst2 仍死于单实例互斥（**与 `D-G65` 无关**） |
| **修后** | 2 | inst1 / inst2 | yes / no | `?`（inst1 收工时被杀，见证文件未落） / `134` | 0 / 0 | 0 / **1** | 同上 |
| **修后** | 3 | inst1 / inst2 | yes / no | `?`（inst1 收工时被杀，见证文件未落） / `134` | 0 / 0 | 0 / **1** | 同上 |

**成对结论**：修前 3 趟里 **1 趟**出现 `D-G65`（第 3 趟，且**两个实例都死**）；
修后 3 趟（6 次启动）**`Win32Exception (50)` = 0**、**`D-G65` 签名 = 0**，且三趟形态**逐趟相同**
（inst1 活到我收工、inst2 死于单实例互斥那条**另一条**缺陷）。
⚠️ 登记里写的"修后 `alive=yes` **且两窗口都在**"**做不到** —— 那是应用自己的单实例逻辑
（`EnsureSingleton()` ⇒ `Shutdown()` ⇒ `App.xaml.cs:84` 抛），**不是** `D-G65`，也不是任何
`D-G65` 修法能改的。**⇒ 这条判据的措辞需要主控裁定**（建议改成"`D-G65` 签名 = 0"）。

**读数说明（推翻派单书那一句）**：双实例**不是** `D-G65` 的确定性触发 —— 2/3 趟里第二实例**确定性**地死在
**另一条**缺陷上（`InvalidOperationException: Cannot set ShutdownMode…` @ hc `App.xaml.cs:84`，
`EnsureSingleton()` 发现命名互斥已存在 ⇒ `Shutdown()`），与 `D-G65` 无关；
第 3 趟两个实例都死于 `D-G65` 的机制是"实例 1 先崩 ⇒ 命名互斥被释放 ⇒ 实例 2 变成首实例"
⇒ **双实例只是放大器，不是触发器**。（这与 `docs/WAVE49-PREREGISTRATION.md:441/463` 里 W55A 已经
推翻过的那一句一致 —— 本车道**独立复现并再次确认**它。）

### 3.6 产品级：单实例 ≥30 趟（**频次**，仪器全关）

| 极性 | 装置 | 趟数 | 死亡趟数 | `Win32Exception(50)` | `Stack overflow` | 死亡时刻 |
|---|---|---|---|---|---|---|
| **修前** | `P1-single`（v1 装置；`rc` 列不可靠、不记 `elapsed`） | 8 | **1**（12.5%） | 1 | 0 | 未记（同签名） |
| **修前** | `P1-single3`（定版装置 v3，`rc` = 见证文件） | 30 | **6**（**20.0%**） | 6 | 0 | 全部落在 **1.5–2.0 s**（启动期） |
| **修后** | `P2-single`（同一装置、同一 `CUTOFF=30`，只换 `WindowsBase.dll`） | 30 | **0（0.0%）** | **0** | **0** | ——（30/30 活到 30 s 截止） |

**修后 30 趟的逐趟读数**：`30/30` 全部 `rc=killed-at-cutoff / alive=yes / elapsed≈30.1–30.2 s`，
`UE=0 W32_50=0 ShutdownMode=0 StackOverflow=0`，**日志 0 行**（一个签名都没有）。
**⇒ 两极化成立**：修前 **7/38 ≈ 18.4%**（两套装置 12.5% / 20.0%）→ 修后 **0/30**（另加双实例 6 次启动 0）。

**修前 30 趟的逐趟死亡（装置 v3）**：`run3 1.5s`／`run9 1.5s`／`run12 2.0s`／`run13 1.5s`／`run24 1.5s`／`run29 1.5s`
（全部 `rc=134`、`Win32Exception (50)`=1、`Stack overflow`=0、`Cannot set ShutdownMode`=0）。
**⇒ 修前汇总（v1+v3）= 38 趟死 7 趟 ≈ 18.4%**；两次独立装置给出一致的量级
（12.5% / 20.0%），比 W55A 报的"~24 趟死 2 趟 ≈ 8%"**高**，见 §6-3 的诚实边界。

> 判据（写死）：`D-G65` 的签名 = 日志里出现 `Win32Exception (50)` **且**栈里出现
> `DispatcherSynchronizationContext.Wait` **或** `WaitForMultipleObjectsEx`。**签名是判据，不是 `rc`**。
> 修前 30 趟里 **6/6 死亡趟的栈逐帧相同**（`WaitForMultipleObjectsEx:137` ←
> `DispatcherSynchronizationContext.Wait:91` ← `Monitor.Enter_Slowpath` ← `ResourceDictionary.GetValue:485`），
> **没有一趟**落在站点②（`ReaderWriterLockWrapper`）⇒ 站点② 的产品级可达性 = `NOINFO`（§6-1）。

---

## §4 功能无回归（候选 A）

装置：W55A 的 `leg.sh` 副本（`$HOME/w56a/bin/leg.sh`，只把日志目录换到 `$HOME/w56a/logs`）
外面套一层 `$HOME/w56a/bin/legx.sh`（**跑前后都按 `/proc/<pid>/cwd` 清孤儿**）；
`W55A_STEPS="nav1 tab3"`（W55A 的最小复现），模式 `A`（**仪器全关**）。
两个**冻结**的应用目录：`$HOME/w56a/app-pre`（修前：`WindowsBase.dll 79740e9ba7fbf9ca`）
与 `$HOME/w56a/app`（修后）。

| 极性 | 应用目录（`WindowsBase.dll`） | `CONVERGED` | `alive` | 击数 | `nav1` 的 `AE` | 点页签的 `AE` | `nwin` | 签名 | 行数 |
|---|---|---|---|---|---|---|---|---|---|
| **修前** | `app-pre`（`79740e9ba7fbf9ca`） | `iters=1 alive=yes nwin=7` | **yes** | 2 | `225596` | `182274` | 7 | 全 0 | 0 |
| **修后** | `app`（`2e4e46e539a72cd7`） | `iters=1 alive=yes nwin=7` | **yes** | 2 | **`225596`** | **`182274`** | **7** | 全 0 | **0** |

**逐字逐位相同**：两腿的 `SHAS` 行只有 `WindowsBase.dll` 一位不同（其余四件相同），
`CONVERGED`／两次 `STEP` 的 **`AE`（截图逐像素差）**／`nwin`／`SIGNATURE`（全 0）／日志行数（0）
**完全一致** ⇒ 修 A **没有**改变应用的可见行为（连"点一下有多少像素变了"都一样）。
`AE` 两位量级（`225596` / `182274`）说明两次点击**都真的产生了重绘**（不是"什么都没发生"）。

**⚠️ 两个诚实边界（必须连着读）**：

1. **`HIT <none>` 在模式 A 里是构造性的**：`leg.sh` 的命中链读的是 `[HCIN] preMouseDown`，
   而模式 A **一个仪器都不开** ⇒ 读了必然是 `<none>`、`preMouseDown=0`、`GEO=0`。
   这不是"没点到"，也**不能**当成"点到了"——所以本腿的判据只用**与仪器无关的量**：
   `alive` / 我发的击数 / `AE`（截图差）—— 这也正是 W55A §2 定下的口径。
2. **`D-G66` 在我这套装置里没有复现**：W55A 的 `nav1 tab3` 在**点页签**那一击崩
   （`AE=480000` = 整屏变化 + `Stack overflow`）；我这里同样两步 `AE>0` 但**没崩**
   ⇒ 我这份读数**不能**当作"`D-G66` 已修/仍红"的证据，只能说**本波没碰 `D-G66`，它在我的装置里不可复现**
   （坐标/环境敏感，W55A 自己也记过它的 5 次坐标错位）。修 A 影响的是 `WindowsBase` 的等待路径，
   `D-G66` 那条 `SetFocus ⇄ WM_SETFOCUS` 递归环不经过它。
3. **我自己踩到过的假读数（如实入册）**：第一次跑完 `nav1 tab3`（应用活着到趟尾）后紧接着跑第二条腿，
   第二条腿死在 `Cannot set ShutdownMode` —— 那不是 `D-G65`、也不是产品缺陷，而是
   **`leg.sh` 的 `cleanup` 只杀子 shell、不杀孙进程**（W55A §6.7-3 已记），留下的孤儿应用**握着命名互斥**
   ⇒ 下一条腿的实例被当成"第二实例"。修法 = `legx.sh` 跑前后按 cwd 清孤儿（已落地）。**该腿作废。**

---

## §5 `check-appliers` / `--check` / 注册同步

| 项 | 读数 |
|---|---|
| `python3 …/patch-windowsbase-focus-wait.py --check` | **rc=0**（生成物与接线都在且与上游同步） |
| `python3 …/patch-windowsbase-focus-wait.py --prove`（"只改那一处"机械证明） | **rc=0**；把修法逆代回去后与上游**逐字节相同** `sha256=22a799e8d666e7b98b1232e81d50560832029b2e1d3e54585452759155d4e2c3`（= 上游 sha256）⇒ 除 `Wait` 那一处外**一个字节没动** |
| 应用器自带的守恒/删项/禁止项断言 | `throw` 0==0；大括号盈亏 15/15 一致；**删项**：原生调用点 上游 1 → 生成物 0、分叉条件 上游 1 → 生成物 0；结构断言 5/5；**禁止项 2/2 全无**（"分叉/原生调用回来了"当场红）；行数 130 → 142（`+12`） |
| `bash build/check-appliers.sh` | `APPLIER_AUDIT_SUMMARY appliers=26 ok=89 miss=0 red=0 rc=0`（本应用器 `tier=A ok=3 miss=0`） |
| **反极性**：把本应用器那一行从 `APPLIERS_EXPLICIT` 摘掉（沙箱副本 `/tmp/w56a-wave-noreg.sh`，真树不动） | `APPLIER_AUDIT_SUMMARY appliers=25 ok=86 **miss=1 red=1 rc=1**` ⇒ "登记了但没生效/被摘掉"**会红**（`applier-audit.py --wave` 指向沙箱副本，`rc=1`） |
| 纪律 38 红线（重生成后注入还在） | **`NOINFO(未测)`**：要真测就得跑 `python3 build/port-lib.py WindowsBase`，而它会**整份重写** `WindowsBase.Linux.csproj` 与生成物 —— 那是**波的写域**（本车道的写域不含它，且跑了会把同树别的车道的读数一起顶掉）。本波给的是**结构约束**：应用器已登记进 `APPLIERS_EXPLICIT`（波第 2 步会重放它）+ 上面那条 `miss=1 red=1` 的反极性读数。**"重生成后接线会被静默抹掉"这件事本身**由本仓三个同族应用器（`patch-windowsbase-msgflow` / `-dpvalue-trace` / `-entry-flatten-trace`）的注释与大括号前的 `MARKER` 机制背书，且本应用器把这条注意事项**打印在自己的输出里**。 |

---

## §6 边界、未覆盖与 `NOINFO`

| # | 项 | 状态 |
|---|---|---|
| 1 | **站点②**（`ReaderWriterLockWrapper.NonPumpingSynchronizationContext.Wait`）在产品里**是否真的被走到** | **`NOINFO`**：确定性探针证明它**机制上活着**（§3.2 的读数：改前 `THREW Win32Exception(50)`），而修后 `nopump` **仍红**（这是**刻意的**：A 只修站点①，站点② 不在写域内）。但 **36 趟修前产品腿（30 单实例 + 6 双实例启动）的死亡栈**里**没有一趟**落在 `ReaderWriterLockWrapper`。要判"可达性"需要 `WeakEventTable` 锁争用的专门实验（本波未做）。**⇒ 这是一条与 `D-G65` 同族、尚未被产品观测到的潜在站点，建议单独登记。** |
| 2 | B′ 的自旋代价 | ✅ **已取数**（§3.4）：同样 2.5 s 的争用里，A = `user+sys 0.03 s`；B′ = **2.50 s**（烧满一核）；B′ 单独护站点① 时 **2.61 s**。 ⇒ 判据③（`WAVE49-PREREGISTRATION.md:434`）不容许。 |
| 3 | **修前死亡率的量级** | 本波两套独立装置：**12.5%**（8 趟死 1）与 **20.0%**（30 趟死 6）⇒ 汇总 **38 趟死 7 ≈ 18.4%**；W55A 报的是 "~24 趟死 2 ≈ 8%"。**差异如实入册、不解释掉**：装置不同（本波无 WM 的 `Xvfb :171`、每趟 30 s 截止、连续跑批），机器状态不同（本波跑批期间负载 ≈1.0）。**样本都不大**（7 与 2 次事件），只能说量级在 10%–20% 之间，不做点估计。 |
| 4 | `MsgWaitForMultipleObjectsEx(nCount != 0)` | **同类失败桩仍在**（`win32_msg.c:859-863`：`WAIT_FAILED + LastError 50`）；它**唯一的调用点** `Dispatcher.IsInputPending()` 恒传 `nCount=0` ⇒ 该分支是**死代码**（**未取数**，只是读码结论）。 |
| 5 | 有 WM 的腿 | **未测**（本波与 W55A 一样用无 WM 的 `Xvfb`）。 |
| 6 | 用户真实会话（`:0` / `:10`） | **未测**（纪律：不碰用户会话）。 |
| 7 | 双实例的 `ShutdownMode` 缺陷 | **不在本波写域**（应用侧 `hc App.xaml.cs:84`）。本波只把它当"另一条"，**不修、不压绿**；并指出 `WAVE49-PREREGISTRATION.md:432` 那条判据（"修后 `alive=yes` 且两窗口都在"）**任何 `D-G65` 修法都达不到**，需主控改措辞（建议：`D-G65` 签名 = 0）。 |
| 8 | 修 A 之后 `D-G66`（点页签） | **本波没碰它**；`nav1 tab3` 在**我这套装置里没复现**（§4-2）⇒ 既不能说它仍红、也不能说它好了，`NOINFO`。 |
| 9 | core dump / 原生栈 | 本机 `ulimit -c=0` + apport ⇒ **没有 core 文件**，原生栈**取不到**（与 W55A 同）。本波的原生侧证据全部来自**探针的 `P/Invoke` 直读与返回值**，不是 core。 |
| 10 | **我自己踩到的两个装置坑**（如实入册） | ① 第一版跑批用 `wait $!` 取退出码 ⇒ 在 `timeout` 的 core-dump 路径上给出 **127/124** 这类假值（已改成子 shell 内的见证文件 `run<i>.rc`，并**作废**了受影响的 2 趟）；② `leg.sh` 的 `cleanup` 不杀孙进程 ⇒ 上一腿的孤儿握着**命名互斥**，把下一腿变成"第二实例" ⇒ 假 `ShutdownMode` 死（已加 `legx.sh` 跑前后清孤儿，该腿作废）。 |

---

## §7 复算命令逐条

```bash
export R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux

# ── 0) 件 sha16（一律现场算） ────────────────────────────────────────────────
cd $HOME/w56a/app && sha256sum libwpfwin32.so wpfgfx_cor3.so PresentationCore.dll PresentationFramework.dll WindowsBase.dll | cut -c1-16,66-
sha256sum $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so $R/build/WindowsBase.Linux/bin/Release/WindowsBase.dll | cut -c1-16,66-

# ── 1) 应用器（生成 + 接线 + 自检 + 机械证明） ───────────────────────────────
cd $R
python3 src/WpfGfx.Linux.Native/tools/patch-windowsbase-focus-wait.py
python3 src/WpfGfx.Linux.Native/tools/patch-windowsbase-focus-wait.py --prove
python3 src/WpfGfx.Linux.Native/tools/patch-windowsbase-focus-wait.py --check
bash build/check-appliers.sh                       # 期望 miss=0 red=0 rc=0

# ── 2) shim（B′） ────────────────────────────────────────────────────────────
bash src/WpfGfx.Linux.Native/build-shim.sh

# ── 3) 重建 windowsbase（权威件；**不要**跑整条波） ─────────────────────────
. build/selfbuilt-config.sh
dotnet build build/WindowsBase.Linux/WindowsBase.Linux.csproj -c "$SELFBUILT_CONFIG" -m:1 --nologo

# ── 4) 确定性探针（站点① / 站点② / 契约） ──────────────────────────────────
cd $HOME/w56a/probe && dotnet build -c Release -m:1 --nologo
cd bin/Release/net10.0
cp -f $R/src/WpfGfx.Linux.Native/bin/libwpfwin32.so .
DISPLAY=:171 dotnet probe.dll disp        # 站点①：修前 THREW Win32Exception(50) / 修后 ACQUIRED≈2500ms
DISPLAY=:171 dotnet probe.dll nopump      # 站点②：修前 THREW / B′ 后 ACQUIRED≈2490ms
DISPLAY=:171 dotnet probe.dll contract258 # 否证 WAIT_TIMEOUT 形态（taken=True @5ms + Exit 抛）
DISPLAY=:171 dotnet probe.dll contract0   # 证明"返回 0 ⇒ CLR 重试直至拿到锁"
DISPLAY=:171 dotnet probe.dll shim        # 直读 shim 返回值（修前 0xffffffff/err=50；B′ 后 0x0）

# ── 5) 产品级成对（仪器全关） ───────────────────────────────────────────────
export PATH="$HOME/.dotnet:$PATH"
(Xvfb :171 -screen 0 1280x1024x24 >/tmp/w56a-171.log 2>&1 &)
cd $HOME/w56a
# 修前用的应用目录是冻结副本 app-pre（WindowsBase.dll 79740e9ba7fbf9ca）；
# 修后是 app（WindowsBase.dll 2e4e46e539a72cd7）。shim 两侧都是 c2674871b09e8e0e。
W56A_APP=$HOME/w56a/app-pre CUTOFF=30 bash bin/runs.sh P1-single3 single 30 :171   # 修前 30 趟
W56A_APP=$HOME/w56a/app-pre CUTOFF=30 bash bin/runs.sh P1-dual    dual   3  :171   # 修前 双实例
W56A_APP=$HOME/w56a/app     CUTOFF=30 bash bin/runs.sh P2-single  single 30 :171   # 修后 30 趟
W56A_APP=$HOME/w56a/app     CUTOFF=30 bash bin/runs.sh P2-dual    dual   3  :171   # 修后 双实例

# 判据（判"死"看签名，不看 rc）：某趟死亡 ⟺ 该趟日志里
#   grep -c 'Win32Exception (50)' ≥ 1  ∧  grep -c 'DispatcherSynchronizationContext.Wait' ≥ 1
cd $HOME/w56a/logs && for d in P1-single3 P2-single; do
  echo "== $d"; grep -v elapsed $d/summary.tsv | awk 'NR>1 && $3=="no"{print "  DEATH run="$1" rc="$2" elapsed="$4"s W32="$6}'
done

# ── 6) 功能腿（跑前后都清孤儿；两个冻结应用目录各跑一次） ────────────────────
cd $HOME/w56a
bash bin/legx.sh P1-leg-minrepro :171 A "nav1 tab3" $HOME/w56a/app-pre
bash bin/legx.sh P2-leg-minrepro :171 A "nav1 tab3" $HOME/w56a/app
grep -E 'CONVERGED|STEP |FINAL|SIGNATURE' logs/P1-leg-minrepro/marks.txt logs/P2-leg-minrepro/marks.txt

# ── 7) 判据③ 的 CPU 对照（需要把 B′ shim 临时放进探针目录；见 §3.4） ────────
bash bin/measure-cpu.sh :171
```

---

## §8 本报告自身的 sha16（口径写死，避免"自指"含糊）

"报告提到自己"没有不动点（回填这个数字本身就会改变文件）。所以：

* **回填前读数**（= §0 那一行里印的那个值）—— 口径一句话：**把本文件里以 `| 报告自身 sha16 |` 开头的那一整行
  替换成 `| 报告自身 sha16 | P |`，再整份取 `sha256` 的前 16 位**。
  只认**行首**（正文里对它的引用不参与，否则"复算规则"会改到自己）；本 §8 **不复述**这个值，
  因为复述会让它变成第二个槽、口径就不再是一句话。

  ```bash
  cd $R
  python3 - <<'PY2'
  import io, hashlib, re
  s = io.open('build/MilBridge/W56A-report.md', encoding='utf-8').read()
  s = re.sub(r'(?m)^\| 报告自身 sha16 \|.*$', '| 报告自身 sha16 | P |', s, count=1)
  print(hashlib.sha256(s.encode('utf-8')).hexdigest()[:16])
  PY2
  ```

* **交付快照** = `sha256sum build/MilBridge/W56A-report.md | cut -c1-16`（**最后一次编辑之后**测一次）。
  它同样**不写进文件**（写进去就变了）——以**车道回执**（给主控的最终消息）里的那个数为准。

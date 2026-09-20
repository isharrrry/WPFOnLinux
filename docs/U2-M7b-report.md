# M7b 报告 · Win32 子集 shim + DllImport 解析器 + Dispatcher 消息泵对接 X11

**结论：验收硬指标 5/5 全部达成，`dotnet build` 0 错 0 警；
`dotnet test` 在 Xvfb :99 下 19/19 全绿，在**无 X server** 时 11 通过 / 8 发现期跳过 / 0 失败。**
托管层（WindowsBase）在 Linux 上第一次**真的跑起来**了：Dispatcher 建得出来、定时器按时触发、
PushFrame 能被跨线程唤醒并正常退出、`HwndWrapper` 建出**真实 X11 窗口**，
`xdotool` 注入的键盘/鼠标事件被托管侧 hook 收到。

> 本报告里的每个数字都可由命令复现；"实测"二字只用在真的跑过的结论上。

---

## 0. 一句话交付

| 项 | 结果 |
|---|---|
| 新增原生库 | `src/WpfGfx.Linux.Native/` → `bin/libwpfwin32.so`（**108,432 B**，`nm -D --defined-only` **347** 个符号） |
| 新增托管接线 | `build/shims/Win32ShimResolver.cs`（同一份源编进 WindowsBase 与 PresentationCore 各一次） |
| 新增测试工程 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/`（19 用例：**有 X 19/19 全绿**；无 X **11 通过 / 8 发现期跳过 / 0 失败**） |
| 修掉的**装载级**缺陷 | 2 个（`MS.Utility.EventTrace` 注册表依赖 → 进程崩溃；message-only 窗口不发建窗消息 → 调用 GC 掉的委托） |
| 修掉的**并发**缺陷 | 1 个（Xlib 多线程使用 → libxcb 断言 abort） |
| 结构化产物 | `docs/U2-M7b-win32-inventory.md`（需求清单）、本报告 |

---

## 1. 第 1 步 · Win32 API 需求清单

完整表格：**`docs/U2-M7b-win32-inventory.md`**（由 `tools/extract-win32-inventory.py` 生成，勿手改）。

复现：
```bash
src/WpfGfx.Linux.Native/build-shim.sh --symbols
python3 src/WpfGfx.Linux.Native/tools/extract-win32-inventory.py
```

### 1.1 口径（与 U2 扫描报告数字不同的原因）

| 维度 | 本清单 | `docs/U2-PresentationCore-scan.md` §2.2 |
|---|---|---|
| 来源 | 两个 csproj 的 `<Compile Include>`（**真的会编进程序集**） | 源码树里出现过 `[DllImport]` 的文件 |
| 范围 | WindowsBase ∪ PresentationCore | 仅 PresentationCore |

### 1.2 统计

| 项 | 数值 |
|---|---|
| 属性条数 | WindowsBase **386** + PresentationCore **339** = **725** |
| 按 `(DLL, 名, 签名)` 去重 | **697** |
| **P0**（消息泵 + 窗口生命周期） | **83** — shim 已实现 **83 / 83** |
| **P1**（值得做：真实现 / 降级 / 返回失败） | **195** — shim 已为其中 **122** 个提供落点 |
| **P2**（明确不做） | **419** — 见 §5 清单与理由 |

### 1.3 P0 里被"实测逼出来"的第 4 个 DLL

任务书点名 `user32.dll` / `gdi32.dll` / `kernel32.dll`。清单阶段发现**必须再加一个**
`PresentationNative_cor3.dll`：

上游 `Shared/MS/Win32/NativeMethodsSetLastError.cs` 把窗口长整型一族声明成
```csharp
[DllImport("PresentationNative_cor3.dll", EntryPoint = "GetWindowLongPtrWrapper", ...)]
```
而不是 user32 的裸名。`HwndSubclass` 的整套 WndProc 链**正是**走这几个入口
（`GetWindowLongPtr` / `SetWindowLongPtr` / `GetParent` / `GetWindow` / `SetFocus` / `EnableWindow`）。
不映射它，窗口骨架在 Linux 上就没有落点。shim 同时导出裸名与 `*Wrapper` 名，两份调用点都命中。

---

## 2. 第 2 步 · 原生 shim 与解析器

### 2.1 构建证据（干净重建，逐字命令）

```console
$ rm -rf obj bin && ./build-shim.sh --symbols
gcc -std=gnu11 -O2 -Wall -Wextra -Wno-unused-parameter -Wno-cast-function-type \
    -fPIC -fvisibility=default -Isrc -c src/win32_core.c    -o obj/win32_core.o
gcc ... src/win32_msg.c     -o obj/win32_msg.o
gcc ... src/win32_x11.c     -o obj/win32_x11.o
gcc ... src/win32_misc.c    -o obj/win32_misc.o
gcc ... src/win32_exports.c -o obj/win32_exports.o
gcc -shared -Wl,--no-undefined -Wl,-soname,libwpfwin32.so \
    -o bin/libwpfwin32.so obj/*.o -lX11 -ldl -lpthread

== 产物：bin/libwpfwin32.so（108432 字节）

== 导出符号总数：347
-- 按前缀分组 --
   Win32 API 名（含 A/W 变体）: 320
   托管侧 PresentationNative *Wrapper: 13
   M7c 桥接（WpfLinuxWin32_*）: 14
```

`-Wl,--no-undefined`：宁可链接期就报"某个 X11 函数找不到"，也不要运行期第一次
`GetMessageW` 时炸——动态装载 `.so` 的应用没有补救机会。
`-Wno-cast-function-type`：符号表把不同签名的函数指针统一存成 `void*`（dlsym 风格），不是 bug。
**没有用 cmake**：单产物、5 个 `.c`、一个系统依赖，引入 cmake 只会多一层生成物。
本机**没装 make**，所以 `build-shim.sh` 直接调 gcc；`Makefile` 给有 make 的环境保留等价入口。

### 2.2 实现深度

```console
$ python3 src/WpfGfx.Linux.Native/tools/shim-depth.py
nm -D --defined-only 总数 : 347
  其中 WpfLinuxWin32_*    : 14（M7c 桥接扩展导出，不属于 Win32 API 面）
  其中 wpf_* / g_* 内部符号: 38（未做 visibility 收敛，不影响功能）
  → Win32 面导出符号       : 295
逻辑函数（去 A/W/Wrapper 变体后）: 199
  真实现     : 103
  降级      : 72
  返回失败    : 24
```

| 档 | 条数 | 判据 | 代表 |
|---|---|---|---|
| **真实现** | **103** | 有真实数据面/状态机，可被数值或行为断言 | 消息泵（26）、窗口生命周期与 `GWL_*`（55）、X11 建窗与事件翻译、`GetProcAddress`/`LoadLibrary`（dlopen）、`MultiByteToWideChar`（真 UTF-8→UTF-16）、性能计数器、DPI 组 |
| **降级** | **72** | Linux 上没有可操作对象，返回"上层不会误入错误分支"的值，且该值是真话或哨兵 | GDI 哨兵句柄（33）、光标/图标/插入符（19）、`SystemParametersInfo`/UIPI/键盘布局等无副作用开关 |
| **返回失败** | **24** | 语义确实表达不了 → Win32 失败码 + `SetLastError` | `UpdateLayeredWindow`→FALSE、`CreateFileMapping`→NULL、`SetWinEventHook`→NULL、`CreateFile`→`INVALID_HANDLE_VALUE`、NLS 三个→0/-1 |

**"不伪造"原则的两条硬约束**（写进了源码注释，也写进了 §5）：
1. 会返回句柄的函数，**要么给真句柄，要么给明确的失败**，不给"看起来能用"的假句柄。
2. 唯一一处"降级但返回成功"的例外是 `MessageBox`：它**不弹窗、不阻塞**，打 stderr 后返回 `IDOK`。
   理由写在下一条。

### 2.3 三处不得不偏离"上游语义"的地方（都在源码里写清了）

| # | 位置 | 做法 | 为什么 |
|---|---|---|---|
| 1 | `MessageBoxW/A` | 打 stderr 后返回 `IDOK`（不阻塞） | 无 X 环境下**任何模态对话框都会把测试/CI 永久挂住**。挂住比"假装用户点了确定"更糟——至少后者会在 stderr 留下痕迹 |
| 2 | `GetSystemMetrics` / DPI 组 | 屏幕尺寸真读 `DisplayWidth/Height`；DPI 恒 96 | Xvfb 与绝大多数 X11 桌面**没有** per-monitor DPI 的 core-protocol 接口。96 DPI / 100% 缩放是**真值**而不是伪造 |
| 3 | `MsgWaitForMultipleObjectsEx(nCount>0)` | `WAIT_FAILED` + `ERROR_NOT_SUPPORTED` | 不假装能等内核对象。WPF 全树只有 `Dispatcher.IsInputPending()` 一处调用，且 `nCount` 恒为 0（已核对源码） |

### 2.4 DllImport 解析器（`build/shims/Win32ShimResolver.cs`）

* `[ModuleInitializer]` + `NativeLibrary.SetDllImportResolver(Assembly, Resolve)`，
  **在首个 P/Invoke 之前**注册（这是必须用 ModuleInitializer 而不能显式调用的原因）。
* 映射 `user32.dll` / `gdi32.dll` / `kernel32.dll` / `PresentationNative_cor3.dll` → `libwpfwin32.so`；
  **未映射的名字返回 `IntPtr.Zero`**，交回默认探测 → `wpfgfx_cor3.dll`（MIL，M7c）、
  `WindowsCodecs.dll`（WIC）、`PenIMC_cor3.dll` 等仍然是**明确的 `DllNotFoundException`**。
* 路径解析顺序（先具体后宽泛）：`WPF_LINUX_WIN32_SHIM` 环境变量 → 程序集同目录 →
  `WPF_LINUX_ROOT`/逐级向上找到的 `<repo>/src/WpfGfx.Linux.Native/bin/`。
  加载失败时抛出的 `DllNotFoundException` **带完整搜索过程**，而不是一句 "unable to load"。
* **一个源文件编进两个程序集**（而非两份拷贝）：注册必须按程序集各做一次
  （`SetDllImportResolver` 的作用域就是传入的那个 `Assembly`），但解析策略只应该有一份源码
  ——两份必然漂移，而漂移的症状是"WindowsBase 能建窗、PresentationCore 建不了"。
  两个程序集里靠 `WINDOWS_BASE` / `PRESENTATION_CORE` 落到不同命名空间，不撞名。
  两个 `shims.txt` 都已追加该文件，所以**下次 port-lib 重生成会自动带上**。

### 2.5 接线通道（为什么不是直接改 csproj）

`build/*.Linux/*.csproj` 是 `port-lib.py` 的**生成物**（每次整份重写），额外内容必须有可重放的出处：

| 通道 | 用途 |
|---|---|
| `build/shims/{WindowsBase,PresentationCore}.shims.txt` | 已追加 `Win32ShimResolver.cs`（port-lib 会自动注入 `<Compile Include>`） |
| `build/WindowsBase.Linux/reapply-patches.py`（**新建**） | 补丁 F：Linux 版 `MS.Utility.EventTrace` |
| `src/WpfGfx.Linux.Native/tools/wire-managed-layer.py`（**新建**） | 在**不重生成整份 csproj** 的前提下定点插入缺失的那 1 行，幂等 |

当前环境用第三条：`build/PresentationCore.Linux/` 有另一个 agent 在做资源审计，
跑 `port-lib.py PresentationCore` 会整份重写它正在动的目录（竞态风险）。
实测 diff **各 1 行**，天然可逆：
```
build/WindowsBase.Linux/WindowsBase.Linux.csproj  349a350  +1 行
build/PresentationCore.Linux/PresentationCore.Linux.csproj  1392a1393  +1 行
```
两个工程重建后均 **0 错 0 警**（WindowsBase 19s、PresentationCore 55s）。

---

## 3. 结构体布局断言（逐字段 offset）

### 3.1 三层证据，缺一不可

1. **编译期**：`win32_abi.h` 里每个跨边界结构体都有 `_Static_assert(offsetof(...) == N)` + `sizeof`。
   推导过程逐行写在注释里（不是"我记得 Win32 是这样"）。断言失败 = 编译失败。
2. **原生打印**：`build-shim.sh --abi` 跑 `tests/abi_layout.c`，把逐字段 offset 打成表。
3. **★ 跨边界对齐**（最强的一条）：`Win32AbiLayoutTests` 用 `WpfLinuxWin32_AbiLayout(name, …)`
   拿**原生** 的 `offsetof/sizeof`，用 `Marshal.OffsetOf/SizeOf` 读**托管编译产物里那个真实结构体**，
   逐字段比对。只证明"原生自洽"是不够的，必须证明"原生 == 托管"。
   `WNDCLASSEX_D` 是 **class + CharSet.Unicode**，额外用 `Marshal.StructureToPtr` 写进原生内存后
   按 shim 报的偏移读回来，连 **UTF-16LE（2 字节/单元）** 这个编码前提一起验。

### 3.2 MSG（7 字段，全部实测一致）

| 字段 | native offset | managed offset | 一致 |
|---|---|---|---|
| `hwnd` | 0 | 0 | ✅ |
| `message` | 8 | 8 | ✅ |
| `wParam` | 16 | 16 | ✅ |
| `lParam` | 24 | 24 | ✅ |
| `time` | 32 | 32 | ✅ |
| `pt_x` | 36 | 36 | ✅ |
| `pt_y` | 40 | 40 | ✅ |
| **sizeof** | **48** | **48** | ✅ |

（`_message` 后 4 字节 padding、`_pt_y` 后 4 字节尾巴 padding 都在 `_Static_assert` 里钉死。）

### 3.3 其余结构体（全部实测一致）

| 结构体 | sizeof | 逐字段 offset（native == managed） |
|---|---|---|
| `WNDCLASSEX_D` | **80** | cbSize 0 / style 4 / lpfnWndProc 8 / cbClsExtra 16 / cbWndExtra 20 / hInstance 24 / hIcon 32 / hCursor 40 / hbrBackground 48 / lpszMenuName 56 / lpszClassName 64 / hIconSm 72 |
| `RECT` | 16 | left 0 / top 4 / right 8 / bottom 12 |
| `TRACKMOUSEEVENT` | 24 | cbSize 0 / dwFlags 4 / hwndTrack 8 / dwHoverTime 16 |
| `PAINTSTRUCT` | 72 | hdc 0 / fErase 8 / rcPaint_left 12 / _top 16 / _right 20 / _bottom 24 / fRestore 28 / fIncUpdate 32 / reserved1 36 |
| `MONITORINFOEX` | **72** | cbSize 0 / rcMonitor 4 / rcWork 20 / dwFlags 36 / szDevice 40 |
| `WINDOWPOS` | **40** | hwnd 0 / hwndInsertAfter 8 / x 16 / y 20 / cx 24 / cy 28 / flags 32 |

### 3.4 ★ 两个"托管形状 ≠ Win32 形状"的发现（这就是为什么必须做跨边界断言）

**（a）`WINDOWPOS` 上游根本不是真 Win32 的 WINDOWPOS。**
真 Win32 是 `{HWND, HWND, int x,y,cx,cy, UINT flags}`，而托管
`NativeMethods.WINDOWPOS`（`NativeMethodsCLR.cs:2282`）是
`{IntPtr hwnd, IntPtr hwndInsertAfter, int x, y, cx, cy, flags}` —— **40 字节**。
首版按"真 Win32"写了 48 字节（多了 `time`/`pt`），跨边界断言直接报
`Expected 48 / Actual 40`。**跨边界的是托管那份，所以原生必须跟着它走。**

**（b）`MONITORINFOEX` 的长度随 `CharSet` 变，Unix 上是 72 不是 104。**
托管声明是
```csharp
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto, Pack = 4)]
... [MarshalAs(UnmanagedType.ByValArray, SizeConst=32)] char[] szDevice;
```
`CharSet.Auto` 在 **Windows 上是 Unicode** → `szDevice` = 32×2 = 64 → 总长 **104**；
在 **Unix 上折叠为 Ansi** → `szDevice` = 32×1 = 32 → 总长 **72**。
实测 `Marshal.SizeOf(typeof(MONITORINFOEX))` = **72**。
→ 同一个结构体在两个平台上**不是同一个字节形状**。这条如果只靠"我记得 Win32 是 104"写，
   症状会是 `GetMonitorInfo` 把 32 字节写越界踩掉后面的栈。

---

## 4. 第 3 步 · 烟测实测证据

**工程选型：`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/`（不是 `samples/HelloManaged/`）。**
理由：验收指标是四件需要**断言**的事，`samples/` 没有断言框架，要自己写 runner 与退出码
（等于重造 xunit）；而本工程既有的 X11 用例约定（发现期 Skip、`Category=X11`）沉淀在
`tests/.../Windowing.Tests/`，测试工程能直接沿用。`samples/HelloManaged/` 留给 M7c
——那一站的目标是"看到东西"，性质不同。

### 4.0 门禁结果

```console
$ export PATH="$HOME/.dotnet:$PATH"
$ dotnet build tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj -m:1
已成功生成。  0 个警告  0 个错误

$ export DISPLAY=:99                                        # Xvfb :99 1280x1024x24
$ dotnet test  tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj --no-build
已通过! - 失败: 0，通过: 19，已跳过: 0，总计: 19，持续时间: 1 s

$ (unset DISPLAY; dotnet test … --no-build)                 # 无 X server
已通过! - 失败: 0，通过: 11，已跳过: 8，总计: 19，持续时间: 123 ms
```

有 X 时连跑 6 次（其中 2 次带 `--logger "console;verbosity=detailed"`）结果一致。

### 4.1 硬指标 1 · Dispatcher 能创建 + DispatcherTimer 按时触发

| 用例 | 断言 | 实测 |
|---|---|---|
| `Dispatcher_CanBeCreated_AndHasThreadAffinity` | `CurrentDispatcher` 非空、同线程恒等、`FromThread` 一致、`CheckAccess`、`InvokeShutdown` 后 `HasShutdownFinished` | ✅ |
| `DispatcherTimer_Fires_WithinTimeWindow` | 50 ms 定时器 ≥3 次；总耗时 ∈ [100 ms, 8 s)（**上界就是"死等/定时器根本没到"的判别条件**）；相邻间隔 < 2 s | ✅ 实测 **3 次 / 194 ms** |
| `Dispatcher_CanBeCreatedAndShutdown_OnManyThreads` | 5 条不同线程各建各关（覆盖窗口表/类表残留 + message-only 窗口销毁路径） | ✅ |

### 4.2 硬指标 2 · PushFrame 能启动并正常退出（不能死等）

| 用例 | 机制 | 实测 |
|---|---|---|
| `PushFrame_Exits_OnInvokeShutdown_FromAnotherThread` | 外部线程 `InvokeShutdown` → `BeginInvoke` → `CriticalRequestProcessing` → `TryPostMessage` → **self-pipe 唤醒阻塞中的 GetMessageW** | ✅ **426 ms** 退出（外部线程睡 400 ms 后才关，所以测的是真的"从 GetMessageW 里被叫醒"） |
| `PushFrame_Exits_OnBeginInvoke_SettingContinueFalse` | `frame.Continue = false` 的 setter 自己 `BeginInvoke` 一条 Send 消息（`DispatcherFrame.cs:78` 注释明写） | ✅ **376 ms**，且帧内 2 个操作都跑到 |
| `PushFrame_WithNoTimers_WakesUpOnPostMessage` | **没有任何定时器、没有任何 X 窗口**，纯阻塞在 GetMessageW 里，靠跨线程 `BeginInvoke` 唤醒 | ✅ **509 ms** |

每个用例都跑在专属后台线程上，`Join(15/20/30 s)` 后断言 —— **最坏情况是用例失败，不会挂住 `dotnet test`**。

### 4.3 硬指标 3 · 真实 X11 窗口（`xwininfo` / `xdotool search` 查得到）

证据文件（测试运行时自动落盘，报告直接引用）：
`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/bin/Debug/net10.0/artifacts/m7b-hwndwrapper-smoke.txt`

```console
$ xdotool search --name WpfLinux-M7b-675c11f8
2097163
$ xwininfo -id 0x20000b
xwininfo: Window id: 0x20000b "WpfLinux-M7b-675c11f8"
  Absolute upper-left X:  40
  Absolute upper-left Y:  60
  Width:  320
  Height: 200
  Map State: IsViewable
```

托管侧同时断言：
* `HWND != 0`，且 **`WpfLinuxWin32_GetX11Window(HWND) == HWND`**（`0x20000b == 0x20000b`）
  → 直接证明「**HWND 就是 X11 XID**」这条设计；
* `xdotool search --name <title>` 返回的十进制 id **等于** HWND；
* `xwininfo` 报的 `Width/Height/Name/Map State` 与建窗参数逐项相等；
* 类名 `HwndWrapper[testhost;m7b-ui;<guid>]`、`GWL_WNDPROC != 0`
  → **HwndSubclass 已经把自己的 WndProc 挂上链**（挂不上就是 0 或类默认值）；
* `WpfLinuxWin32_WindowCount() >= 2`（Dispatcher 的 message-only 窗口 + 本窗口）。

### 4.4 硬指标 4 · 事件流入（xdotool 注入 → 托管 hook 收到）

注入命令（测试内的注入线程**在泵运行中**才动手）：

```console
$ xdotool key --window 2097163 a            # exit=0（XSendEvent，指定窗口，不依赖焦点）
$ xdotool mousemove --sync 200 160          # exit=0（XTEST 真指针，窗口几何中心）
$ xdotool click 1                           # exit=0
```

托管侧 hook（`MS.Win32.HwndWrapperHook`，经反射绑定）**完整收到**：

```
msg=0x0081 wParam=0x0 lParam=0x0      WM_NCCREATE
msg=0x0001 wParam=0x0 lParam=0x0      WM_CREATE
msg=0x0018 wParam=0x1 lParam=0x0      WM_SHOWWINDOW(mapped)
msg=0x000f wParam=0x0 lParam=0x0      WM_PAINT      ← X11 Expose
msg=0x0018 wParam=0x1 lParam=0x0      WM_SHOWWINDOW
msg=0x0100 wParam=0x41 lParam=0x410001   WM_KEYDOWN  wParam = VK_A  ← X11 KeyPress
msg=0x0102 wParam=0x61 lParam=0x410001   WM_CHAR     wParam = 'a'
msg=0x0101 wParam=0x41 lParam=0x80410001 WM_KEYUP
msg=0x0200 wParam=0x0  lParam=0x6400a0   WM_MOUSEMOVE
msg=0x0200 wParam=0x0  lParam=0x6400a0   WM_MOUSEMOVE
msg=0x0201 wParam=0x1  lParam=0x6400a0   WM_LBUTTONDOWN ← X11 ButtonPress
msg=0x0202 wParam=0x1  lParam=0x6400a0   WM_LBUTTONUP
msg=0x0002 wParam=0x0 lParam=0x0      WM_DESTROY    ← Dispose → DestroyWindow
msg=0x0082 wParam=0x0 lParam=0x0      WM_NCDESTROY
```

断言：`WM_KEYDOWN` 存在且 `wParam == 0x41`（X11 keysym `a` → VK_A）、`WM_LBUTTONDOWN` 存在、
`WM_PAINT` 存在、`WM_DESTROY` + `WM_NCDESTROY` 都存在（销毁路径真的走完）。
`lParam` 的位域也自洽：bit0-15 重复计数=1、bit16-23 扫描码=0x41、keyup 时 bit31=1。
**10 s 兜底没有被触发**（`timedOut=False`，`PushFrame` 464 ms 收工）→ 事件是**真的到了**，
不是"等到超时才收工"。

X11 事件 → `MSG` 的完整映射（`win32_x11.c`）：`Expose→WM_PAINT`、`ConfigureNotify→WM_SIZE+WM_MOVE`、
`Map/UnmapNotify→WM_SHOWWINDOW`、`KeyPress/Release→WM_KEYDOWN/UP(+WM_CHAR)`、
`Button*→WM_LBUTTON*/WM_RBUTTON*/WM_MBUTTON*/WM_XBUTTON*`、`Button4/5/6/7→WM_MOUSEWHEEL/HWHEEL`、
`MotionNotify→WM_MOUSEMOVE`、`EnterNotify→WM_MOUSEMOVE`、`LeaveNotify→WM_MOUSELEAVE`、
`FocusIn/Out→WM_SETFOCUS/WM_KILLFOCUS`、`ClientMessage(WM_DELETE_WINDOW)→WM_CLOSE`、
`DestroyNotify→WM_DESTROY+WM_NCDESTROY`。
未列出的类型（SelectionRequest / PropertyNotify / VisibilityNotify…）**丢弃，不产生假消息**。

### 4.5 硬指标 5 · 无 X server 时优雅跳过

沿用 `X11Guard` 的**发现期 Skip** 模式（xunit 2.9.2 的 `SkipException` 在 v2 会把用例记成
Failed，唯一干净的通道是 `FactAttribute.Skip`——它在发现期读，而特性构造函数也在发现期跑）。

* 判据是"**真的能 `XOpenDisplay`**"而不是"`DISPLAY` 非空"（容器里 DISPLAY 常被预设成 `:0` 却没 server）。
* 需要 X 的 8 条打 `[X11Fact]` + `Trait("Category","X11")`；其余 11 条是纯布局 / 纯环境探针，任何机器都能跑。

```console
$ (unset DISPLAY; dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj --no-build)
已通过! - 失败: 0，通过: 11，已跳过: 8，总计: 19，持续时间: 123 ms
```

#### ★ 这里推翻了一个设计假设（如实登记）

首版假设「shim 的等待路径是 `poll([self-pipe, X fd, 定时器剩余])`，没有 DISPLAY 时 X fd 自然消失，
所以 **Dispatcher 在没有窗口系统的机器上也能跑**」，据此把 6 条 Dispatcher 用例标成 `[Fact]`。
**实测（DISPLAY 未设置）6 条全红**：

```
Win32Exception (1400) ← UnsafeNativeMethods.CreateWindowEx  (UnsafeNativeMethodsCLR.cs:1055)
                     ← HwndWrapper..ctor                     (HwndWrapper.cs:115)
                     ← MessageOnlyHwndWrapper..ctor          (MessageOnlyHwndWrapper.cs:10)
                     ← Dispatcher..ctor                      (Dispatcher.cs:1737)
```

原因：`Dispatcher` 的构造函数**无条件** `new MessageOnlyHwndWrapper()`，要经过
`RegisterClassEx` + `CreateWindowEx`。没有 X 就没有窗口对象可建，`CreateWindowExW` 按
"不伪造"原则返回 NULL(1400)，托管侧随即抛 `Win32Exception`。
→ 结论修正为「**Dispatcher 需要 X server**」，这 6 条改为 `[X11Fact]`（发现期跳过而不是红）。
真正无需 X 的是 `Win32AbiLayoutTests`（7 条纯布局）与 `LinuxEnvironmentDiagnosticsTests`
的两条环境探针（`Environment.OSVersion` / `Registry.CurrentUser`）。

---

## 5. 未做与不做清单

### 5.1 做的过程中**修掉**的三个缺陷（都是"不跑起来就发现不了"）

| # | 缺陷 | 症状（实测） | 处置 |
|---|---|---|---|
| 1 | **`MS.Utility.EventTrace` 静态构造依赖注册表** | `HwndWrapper` 的**终结器**走到 `EventTrace.IsEnabled` → `TypeInitializationException → PlatformNotSupportedException: Registry is not supported` → **测试宿主进程崩溃**（不是用例失败）。两次短路都失效：`Environment.OSVersion` 在 Unix 上返回**内核版本**（本机 `Unix 6.8.0`，`Major<6` 为假）；`IsClassicETWRegistryEnabled()` 读 `HKEY_CURRENT_USER\…\ClassicETW` | 补丁 F：`<Compile Remove>` 上游 `Shared/MS/Utility/Trace.cs` + 新增 `build/shims/WindowsBase.EventTrace.Shim.cs`（同一 `EventTrace` 表面，静态构造改用 `NullTraceProvider`）。**语义论证**：Linux 上没有 ETW，"无订阅者"正是上游在 Windows 上的默认路径（`_enabled==false` ⇒ 506 处 `TraceEvent` 全被 `IsEnabled` 挡掉），**没有日志被丢弃，因为根本不存在日志通道** |
| 2 | **message-only 窗口不发建窗消息** | 首版判断"message-only 窗口不需要 hooks"就跳过了 `WM_NCCREATE/WM_CREATE`。结果 `HwndSubclass` 永不自我挂载（它靠**第一条消息**触发），窗口的 `GWL_WNDPROC` 一直是 `HwndWrapper` 构造函数里那个只被 `GC.KeepAlive` 到构造结束的委托 → 之后任何 `DispatchMessage` 都调用**已被 GC 回收的委托**：`A callback was made on a garbage collected delegate of type 'WindowsBase!MS.Win32.NativeMethods+WndProc::Invoke'` + **进程 fail-fast** | 照 Win32 语义给 message-only 窗口**也发** `WM_NCCREATE/WM_CREATE` 与 `WM_DESTROY/WM_NCDESTROY`；"不 map" 才是它和普通窗口的区别。`Dispatcher_CanBeCreatedAndShutdown_OnManyThreads` 用例专门钉住它 |
| 3 | **Xlib 被多线程使用** | `[xcb] Unknown sequence number while processing queue` / `Assertion '!xcb_xlib_threads_sequence_lost' failed` → **进程 abort**（默认 verbosity 下偶现、detailed 下必现，典型数据竞争）。触发者是真实的 WPF 行为：`HwndWrapper` 的**终结器**会在终结器线程上走 `DestroyWindow`，而 UI 线程同时在泵里 `XPending/XNextEvent` | 两道防线：`__attribute__((constructor))` 里 `XInitThreads()`（必须早于任何 Xlib 调用，所以不能放在 `wpf_x11_ensure` 里）+ 自己的 `g_xlock` 串行化本 shim 的每个 Xlib 调用（锁序恒为 `g_wpf.lock` → `g_xlock`；**调用托管窗口过程时绝不持锁**） |

另外修掉一个**字符集**错误（属于第 2 类"跑起来才发现"）：
裸名一度一律转发到 `...W`，而 `CharSet.Auto` 在 **Unix 上折叠为 Ansi**、运行时**先探裸名**。
于是 `CreateWindowEx` 收到的 UTF-8 字节被当成 UTF-16 解释 → 类名乱码 →
`ERROR_CLASS_DOES_NOT_EXIST (1411)` → 连 `Dispatcher.CurrentDispatcher` 都建不出来。
现已约定「**裸名 == A（UTF-8）实现**，`...W` 先转码」。

### 5.2 ★ 仍未做：`HwndSource` 在 Linux 上仍不可用（**精确到文件:行**）

`HwndSource` 是 PresentationCore 的公开窗口入口（`new HwndSource(...)`）。当前它**构造失败**，
根因已经定位到行（测试把它落进 `artifacts/m7b-hwndsource.txt`）：

```
TypeInitializationException: The type initializer for 'System.Windows.PresentationSource' threw an exception.
 └ TypeInitializationException: The type initializer for 'MS.Internal.TraceDependencyProperty' threw an exception.
    └ NullReferenceException
       at MS.Internal.WindowsBase.SecurityHelper.ReadRegistryValue(RegistryKey baseRegistryKey, String keyName, String valueName)
            …/Shared/MS/Internal/SecurityHelper.cs:line 215
       at MS.Internal.AvTrace.IsWpfTracingEnabledInRegistry()   …/WindowsBase/MS/Internal/AvTrace.cs:line 213
       at MS.Internal.AvTrace.ShouldCreateTraceSources()        …/WindowsBase/MS/Internal/AvTrace.cs:line 188
       at MS.Internal.AvTrace..ctor(...)                        …/WindowsBase/MS/Internal/AvTrace.cs:line 43
       at MS.Internal.TraceDependencyProperty..cctor()          …/MS/Internal/Generated/AvTraceMessages.cs:line 11
```

根因与 `EventTrace` **同源**：`Microsoft.Win32.Registry` 在 Linux 上不可用。
实测（`LinuxEnvironmentDiagnosticsTests`，可证伪的断言）：

```
Environment.OSVersion            : Unix 6.8.0.138
RuntimeInformation.OSDescription : Ubuntu 22.04.5 LTS
Registry.CurrentUser             : null          ← SecurityHelper.cs:215 的 OpenSubKey 就是在这里 NRE
```

**为什么没在本轮修**（三个理由，写出来是为了让 M7c 能做决策而不是照抄）：
1. **不在 M7b 的验收路径上**：任务书明确写 "`HwndSource`（**或 `HwndWrapper`**）创建一个真实 X11 窗口"，
   而 `HwndWrapper` 是窗口骨架的最后一层（`HwndSource` 构造函数第一件事就是 `new HwndWrapper`），
   它已经全绿；
2. **修了也不足以让 `HwndSource` 可用**：过了静态构造这一关，`HwndTarget` → `MediaContext` →
   DUCE → `wpfgfx_cor3.dll` 的 MIL 接线仍然是空的（M7a 的 108 个导出实现成的是**托管方法**，
   还没导出成原生符号）。所以本轮修它**不改变任何可演示的结果**；
3. **资源约束**：主控实测本机 3 核 / 7GB、8 agent 并行、load 10+，要求压低构建次数。
   修它需要排除上游 `Shared/MS/Internal/SecurityHelper.cs`（229 行，含 `SecurityHelper` +
   `SafeSecurityHelper` 两个被广泛使用的类）并整份加 null 守卫，至少再两轮构建。

**给 M7c 的最小补丁（5 分钟量级）**：`SecurityHelper.cs:215` 第 215 行前加
```csharp
if (baseRegistryKey is null) { return null; }   // Linux 无注册表（Registry.CurrentUser == null）
```
（通道与补丁 F 相同：`build/WindowsBase.Linux/reapply-patches.py` 里 `<Compile Remove>` + shim 副本；
或直接在 `AvTrace.IsWpfTracingEnabledInRegistry()` 开头 `return false;` —— Linux 上
"WPF managed tracing 未启用"也是真话。）
建议连同 §5.3 的 MIL 接线一起做，否则仍然看不到 `HwndSource` 跑通。

### 5.3 P2 · 明确不做（419 条，逐 DLL 理由见 `docs/U2-M7b-win32-inventory.md` §4）

| DLL | 条数 | 不做 / 不由本 shim 做的理由 |
|---|---|---|
| `wpfgfx_cor3.dll`（MIL/DUCE） | 110 | M7a 已把 **108 个导出名**实现成**托管方法**（`src/WpfGfx.Linux/Interop/MilNative*.cs`，48 真实现/9 身份映射/11 纯状态/26 E_NOTIMPL）；把它们**导出成原生符号并接上**是 M7c 的活，Win32 shim 不该重复承担 |
| `WindowsCodecs.dll`（WIC） | 109 | M1 已有 Skia 解码/编码能力面；映射关系待 M7c+ 定。直接 stub 会让图像路径**静默失真** |
| `PresentationNative_cor3.dll` | 107 | **部分做了**：只有 `*Wrapper` 那一批（窗口长整型/父窗口/焦点/标题/EnableWindow/MapWindowPoints）映射到本 shim。其余是 LineServices 行排版（`Lo*`）与 `LsDisableSpecialCharacterLigature`，依赖 Windows line-services 引擎，Linux 上应由 M1 的 Skia 文本栈承接 |
| `msdrm.dll` | 49 | Windows DRM/权限（XPS 用）。Linux 无对应物 |
| `imm32.dll` | 18 | IME。Linux 上是 IBus/Fcitx + XIM，属独立里程碑 |
| `PenIMC_cor3.dll` | 16 | 触笔/手写。X11 上走 XInput2 |
| `mshwgst.dll` | 14 | 手写识别。无对应物 |
| `ole32.dll` / `oleaut32.dll` | 13 | OLE 剪贴板/DnD。M4 已裁决**最小诚实 stub**（`build/shims/PresentationCore.OleApi.Stubs.cs`，一律 `PlatformNotSupportedException`） |
| `mscms.dll` | 9 | Windows 色彩管理。Linux 上是 colord/ICC |
| `advapi32.dll` | 8 | 注册表/安全令牌/事件日志。**注册表在 Linux 上直接是 `null`**（见 §5.2） |
| `ninput.dll` | 7 | Windows 指针输入。X11 上是 XInput2 |
| `uxtheme.dll` | 7 | 视觉样式。WPF 自绘主题，Linux 上无系统主题可问 |
| `api-ms-win-core-winrt-*` | 4 | WinRT 投影（InputPane/UISettings）。无 WinRT |
| `msctf.dll` / `wininet.dll` / `shell32.dll` / `shfolder.dll` / `urlmon.dll` / `wtsapi32.dll` / `ntdll.dll` / `winmm.dll` / `psapi.dll` / `winspool.drv` / `oleacc.dll` / `PresentationHost_cor3.dll` | 45 | TSF / WinINet / Shell 集成 / 终端服务会话通知 / 版本查询 / 多媒体定时器 / 进程信息 / 打印 / 无障碍 / XBAP 宿主。逐条理由见清单 §4 |

### 5.4 "语义不可表达"清单（降级与失败的完整口径）

| 类别 | 条数 | 处置 |
|---|---|---|
| GDI 对象（DC/位图/画刷/元文件） | 33 | 返回**非 0 哨兵句柄**。理由：上层拿到 NULL 会当"资源分配失败"抛异常并中断整条路径，而真实语义是"这个后端没有 GDI" |
| 光标 / 图标 / 插入符 | 19 | 哨兵 / 无操作。X11 的光标是 `Cursor` 资源（要 `XCreateFontCursor`），本 shim 不做光标形状 |
| 无副作用开关（`SystemParametersInfo` / UIPI / 键盘布局 / 电源状态） | 24 | 返回"Linux 语境下的真话"（AC 在线无电池、OEM CP=65001、无 UIPI ⇒ 没有消息会被拦） |
| 内核对象（文件映射 / 事件 / 跨进程句柄） | 11 | **返回失败**。Linux 上应改 memfd/`shm_open`、`eventfd`；给假句柄比失败危险得多 |
| NLS（`GetLocaleInfo`/`GetStringTypeEx`/`FindNLSString`） | 3 | **返回失败**，让上层回落到 BCL（Linux 上用 ICU，本来就可用的托管实现） |
| 分层窗口（`UpdateLayeredWindow` 等 3 条） | 3 | **返回失败**。X11 上等价的正确做法是 ARGB visual + XRender/XComposite，不是"画上去" |
| UIA 事件（`SetWinEventHook`/`NotifyWinEvent`） | 4 | **返回失败**/no-op。Linux 上是 AT-SPI2 over D-Bus |
| 模态对话框 `MessageBox` | 1 | **降级：不弹窗不阻塞**，打 stderr 后返回 `IDOK`。挂住 CI 比"假装用户点了确定"更糟 |
| 跨线程 `SendMessage` | — | **在调用线程直接执行窗口过程**（不是投递）。对本工程的实际用法（HwndSubclass 自我解绑、ManagedWndProcTracker 清理）都在同一线程上，语义等价；跨线程 `SendMessage` 未实现，已登记 |
| 多 UI 线程 | — | X 连接所有者 = 第一个调 `wpf_x11_ensure()` 的线程；其它线程只能走 `PostMessage`（纯内存队列 + self-pipe）。WPF 的"一个 UI 线程 + 若干后台线程"正是这个形状；多 UI 线程需要每线程一个 X 连接 |
| `CharSet.Auto` 的字符串 | — | 按 **UTF-8** 处理（Unix 上 `Auto == Ansi`）。**不是** Windows 的 ACP，跨平台共享的字节流（如 `GetProp` 的字符串键）在两边不通用 |

---

## 6. 给 M7c（端到端 HelloWpf）的接口说明与剩余缺口

### 6.1 已经稳的接口（可以直接依赖）

| 能力 | 契约 | 证据 |
|---|---|---|
| **`HWND` 就是 X11 `Window`（XID）** | 不需要任何转换表 | `WpfLinuxWin32_GetX11Window(hwnd) == hwnd`，`GetDesktopWindow() == XRootWindow(dpy, screen)` |
| 消息泵 | `GetMessageW` 返回 0 ⇔ 取到 `WM_QUIT`；`PostMessage` 能跨线程唤醒阻塞中的泵；`SetTimer(hwnd,id,ms,NULL)` 到期产生 `WM_TIMER`（`wParam==id`，重复型） | §4.2 |
| 窗口生命周期 | `RegisterClassExW` → `CreateWindowExW`（发 `WM_NCCREATE`/`WM_CREATE`）→ … → `DestroyWindow`（发 `WM_DESTROY`/`WM_NCDESTROY`） | §4.3 §4.4 |
| WndProc 链 | `GWL_WNDPROC` 可读可写；`CallWindowProc` 真调函数指针；`GetProcAddress(GetModuleHandle("user32.dll"), "DefWindowProcW")` 返回**本 shim 里那个真实地址**（走 `dladdr`+`dlopen(RTLD_NOLOAD)`+`dlsym`，不需要维护第二份名字表） | §4.3 |
| 输入事件 | `xdotool key --window <id>`（XSendEvent）与 `xdotool mousemove/click`（XTEST）都能到 hook | §4.4 |
| 构建/接线 | `build-shim.sh --all`；`wire-managed-layer.py`（幂等，1 行/工程）；`extract-win32-inventory.py` | §2.1 §2.5 |

M7c 可用的桥接导出（`include` 在 `src/WpfGfx.Linux.Native/src/win32_exports.c` 末尾，
`WpfLinuxWin32_` 前缀）：
`ShimVersion` / `LastError`（无 X 时给出**明确原因字符串**）/ `EnsureX11` /
`GetX11Display` / `GetX11Screen` / `GetX11ConnectionNumber` / `GetX11Window` /
`GetX11RootWindow` / `PumpOnce(timeout_ms)` / `PostUserMessage` /
`WindowCount` / `GetWndProc` / `GetClassName` / `AbiLayout`。

典型接线（M7c）：
```
MilVisualTarget_AttachToHwnd(hwnd)
   → X11PresentationTarget 用 hwnd 直接 XCreateWindow/XMapWindow 或 XPutImage
   → 不需要任何 HWND↔XID 转换
```

### 6.2 剩余缺口（按"挡不挡 M7c"排序）

| # | 缺口 | 挡什么 | 量级 | 位置 |
|---|---|---|---|---|
| 1 | **MIL 原生符号面**：M7a 的 108 个导出是**托管方法**，`[DllImport("wpfgfx_cor3.dll")]` 还没有落点 | 挡**一切绘制**（`HwndTarget` → DUCE → MIL）。这是 M7c 的第一块 | 中（`Interop/MilNative*.cs` 已有实现，缺的是导出与绑定通道：`UnmanagedCallersOnly` + NativeAOT/宿主，或把 `[DllImport]` 换成同名方法调用——handoff 决策 3 指的就是后者） | `src/WpfGfx.Linux/Interop/` + 托管侧接线 |
| 2 | **`SecurityHelper.ReadRegistryValue` NRE** | 挡 `HwndSource` 构造（`PresentationSource` 静态构造） | 极小（1 行，见 §5.2） | `Shared/MS/Internal/SecurityHelper.cs:215` |
| 3 | WIC（109 条）→ Skia 映射 | 挡图像解码/编码 | 中 | `UnsafeNativeMethodsMilCoreApi.cs` + M1 成像栈 |
| 4 | LineServices（`Lo*`，107 条里的主体） | 挡**最优段落排版**（`TextFormattingMode`），普通文本走 DWriteForwarder 骨架不受影响 | 大 | 建议走 M1 Skia 文本栈 |
| 5 | 多 UI 线程 / 跨线程 `SendMessage` | 单 UI 线程的 HelloWpf 不受影响 | 小（真需要时再改） | `win32_msg.c` |
| 6 | `PresentationNative_cor3.dll` 里 `LsDisableSpecialCharacterLigature` 等非 Wrapper 入口 | 同 #4 | — | 同 #4 |

### 6.3 M7c 起步建议（一条命令级）

```bash
export PATH="$HOME/.dotnet:$PATH"; export DISPLAY=:99
src/WpfGfx.Linux.Native/build-shim.sh --all                       # 复用已构建产物即可，不必重构
python3 src/WpfGfx.Linux.Native/tools/wire-managed-layer.py --check   # 确认接线还在
dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj
```
先让这 19 条绿，再动 MIL 接线 —— 它们把"消息泵 + 建窗 + WndProc 链 + 输入"这四块
变成了**回归网**，M7c 改 MIL 时如果这 19 条红了，就是 Win32 面被踩了而不是 MIL 的问题。

---

## 7. 本次改动的文件清单

**新增（本任务的全部产出）**
```
src/WpfGfx.Linux.Native/            原生 shim（README/Makefile/build-shim.sh/src/include/tests/tools）
build/shims/Win32ShimResolver.cs    DllImportResolver（同一份源编进两个程序集）
build/shims/WindowsBase.EventTrace.Shim.cs   Linux 版 EventTrace（补丁 F）
build/WindowsBase.Linux/reapply-patches.py   补丁 F 的可重放出处（新建）
tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ 烟测工程（6 个 .cs + csproj）
docs/U2-M7b-win32-inventory.md      第 1 步需求清单（脚本生成）
docs/U2-M7b-report.md               本报告
```

**追加/修改（最小必要）**
```
build/shims/WindowsBase.shims.txt        +3 行（Win32ShimResolver.cs）
build/shims/PresentationCore.shims.txt   +4 行（同上）
build/WindowsBase.Linux/WindowsBase.Linux.csproj      +1 行 Compile / +补丁 F 块
build/PresentationCore.Linux/PresentationCore.Linux.csproj   +1 行 Compile
```

**刻意没碰**：`upstream/`（全程只读）、`src/WpfGfx.Linux/`（M1 主工程只读；
**没有发现任何必须改 `Windowing/` 才能对接的地方** —— HWND==XID 这条设计让它零改动即可对接）、
`build/PresentationFramework.Linux/`、`build/ReachFramework.Linux/`、
`build/PresentationCore.Linux/` 的其它内容（只加了 1 行 Compile，未跑 port-lib 重生成）、
`handoff.md`、`port-lib.py`、`Directory.Upstream.props`、`verify-all.sh`、`tests/parity/`、`tests/U1-golden/`。

---

## 8. 复现全集（一条不漏）

```bash
cd <repo>; export PATH="$HOME/.dotnet:$PATH"

# 0) X server（无 X 时窗口/输入用例会自动跳过，不会红）
tests/WpfGfx.Linux.Tests/Windowing.Tests/start-xvfb.sh start
export DISPLAY=:99

# 1) 原生 shim
src/WpfGfx.Linux.Native/build-shim.sh --all        # 构建 + ABI 逐字段 offset + 导出符号数
python3 src/WpfGfx.Linux.Native/tools/shim-depth.py

# 2) 托管层接线 + 重建（本机没装 make，用 -m:1 省资源）
python3 src/WpfGfx.Linux.Native/tools/wire-managed-layer.py
python3 build/WindowsBase.Linux/reapply-patches.py
dotnet build build/WindowsBase.Linux/WindowsBase.Linux.csproj      -m:1
dotnet build build/PresentationCore.Linux/PresentationCore.Linux.csproj -m:1

# 3) 需求清单
python3 src/WpfGfx.Linux.Native/tools/extract-win32-inventory.py

# 4) 烟测
dotnet build tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj -m:1
dotnet test  tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj --no-build
cat tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/bin/Debug/net10.0/artifacts/*.txt
```

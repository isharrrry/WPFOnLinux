# M7b · `D-K1` 定位仪器：`GetKeyState` **逐次调用探针**（波 24）—— **源已定**，待波内重建后复跑取证

**本文件回答主控 2026-09-14 的任务 1（整批型环节定位）与任务 2（`UIAutomationTypes` 缺口核查）。**
边界遵守：`:96` 自起自收；**没有重建 native 权威件**（只编到 `/tmp`）、**没发桥**、**没重建 PC**；
没碰 `src/WpfGfx.Linux/**`、`build/shims/**`、`samples/**`；测试代码（三条牙 + 12 档）**一行未改**。

---

## 0. 一句话
主控批准的读数设计已落成环境开关 `WPF_LINUX_KEYSTATE_TRACE`（**默认关 / 有界 / 触顶看得见 / 退出给真实总数**），
**离线四态牙全绿**（含"派发之内读到 0x8000 而实时表是 0x00"的机制离线复现）；
native 重建与 4 份副本同步按边界**由主控在波内做** ⇒ 我报 **"源已定"**，随后复跑整批档与按事件泵档取证。

---

## 1. 源已定（改动清单 + sha16，读数时间 `2026-09-14 18:29:40`）

| 文件 | sha16 | 改了什么 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `c026c6809f13c7b6` | ① 新增探针（`WPF_KS_TRACE_MAX=200`；`wpf_ks_trace_on/_summary/_vk_name/_begin/_trace`）② `GetKeyState`/`GetAsyncKeyState` 改为共用 `wpf_keystate_read(vk, api)`（**取值语义逐字不变**，只多一次 trace 与 `api=` 标签）③ `GetKeyboardState` **只加一行日志、语义不变** |
| `src/WpfGfx.Linux.Native/src/win32_msg.c` | `60e169ce8f6aee6f` | ① 新增 `s_dispatch_depth` + `wpf_msg_in_dispatch()`（用**深度**不用布尔：wndproc 里嵌套派发是合法的，布尔会被内层提前清掉）② `dispatch …` 行尾追加 `t=<ms>`（与 KEYSTATE 行**同一个时钟**）③ 就地登记既有局限：`s_dispatch_valid` 是单槽，嵌套会被内层覆盖 |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `029ac93a951a5be3` | 声明 `int wpf_msg_in_dispatch(void);` |

**未触碰权威件**：`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 改动前后都是 `91baee84270f2322`（本次只编到 `/tmp/t1x-ks/`，
私有产物 `aebfdaced7149c35`、279,288 字节）。编译口径与 `build-shim.sh` 的 `CFLAGS_BASE` **逐字相同**（只改 `-o`）：
7/7 文件编过、**0 error**、1 条 warning 在 `src/win32_misc.c:224`（`-Wmisleading-indentation`）——
**该文件本次未改 ⇒ 属既有告警**，不是我引入的。导出数 467 → 468（净增 `wpf_msg_in_dispatch`，纯新增）。

---

## 2. 探针口径（对着主控的三条要求逐条落）

| 要求 | 实现 |
|---|---|
| **逐次调用 + 调用时刻** | 每次 `GetKeyState`/`GetAsyncKeyState`（以及 `GetKeyboardState`）各打一行，`t=` 取 `wpf_now_ms()`（`CLOCK_MONOTONIC` 毫秒）；**与 MSGFLOW 的 `dispatch … t=` 同钟** ⇒ 两个日志按 `t` 直接对齐 |
| **是否在 dispatch 中** | `wpf_msg_in_dispatch()`（深度 > 0）。⚠ 与"快照有没有登记到"**分开打**：`在dispatch中=` 与 `快照=` 是两个字段 |
| **返回位** | `返回=0x%04x`，同时给 `实时表字节=` 与 `实时表 ctrl/shift/alt`，便于看"快照还是实时表" |
| **默认关 + 无副作用/构造开销** | 只在**首次**调用读一次 `getenv`；关着时每次调用只多一条静态判断 ⇒ 不取时间、不拼串、不加锁、不动计数器 |
| **有界 + 触顶必须看得见（L12）** | 上限 `WPF_KS_TRACE_MAX=200` 行 ⇒ 触顶打一条 `…已达上限 200 行：后续调用**只计数、不再打印**（触顶这一刻已发生 N 次调用…）`；**退出时** `atexit` 再打一条 `汇总：本次运行共 N 次调用，已打印 M 行` ⇒ "报 0 ≠ 不存在"：被抑制的调用也有地方看得见 |

逐次行的样子（实测原文，见 §3 牙C）：
```
[KEYSTATE] #1 GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=是 快照=已登记(0x2) 实时表字节=0x00 实时表 ctrl=0 shift=0 alt=0 t=154574430ms
```

---

## 3. 仪器自身的牙（**离线**四态，全绿 —— 证明它"能变红"，不是只会打印）

私有不入库：私有 shim（§1）+ scratch 驱动 `/tmp/t1x-ks/drv.c`（纯 dlopen 调用）、`drv3.c` / `drv4.c`（真窗口 + wndproc + 真 `DispatchMessageW`，走我自己的 `Xvfb :96`，**已按 PID 收掉**）。

| 牙 | 场景 | 期望 | 实测原文（节选） |
|---|---|---|---|
| **A** | 探针**关**（无 env），5 次调用 | **一行都没有** | `[KEYSTATE] 行数=0`；`[驱动] 第 1 次 GetKeyState(VK_CONTROL)=0x0000` |
| **B** | 探针**开**，250 次调用 | 200 行 + 触顶 1 条 + 汇总 | `逐次行数=200`；`…已达上限 200 行…（触顶这一刻已发生 201 次调用…）`；`汇总：本次运行共 250 次调用，已打印 200 行（行上限 200）` |
| **C** | 窗口 wndproc 在**派发之内**读 Ctrl，入队修饰位 `=0x2` | `在dispatch中=是 快照=已登记(0x2) 返回=0x8000` | `#1 GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=是 快照=已登记(0x2) 实时表字节=0x00 实时表 ctrl=0 shift=0 alt=0`；`wndproc: … 期内 GetKeyState(VK_CONTROL)=0x8000` |
| **D** | **同一调用点**，入队修饰位 `=0x0` | `快照=已登记(0x0) 返回=0x0000` | `#1 … 返回=0x0000 在dispatch中=是 快照=已登记(0x0) 实时表字节=0x00 …` |
| **E** | **不经过出队**直接 `DispatchMessageW`（四元组无从登记） | `在dispatch中=是 快照=无` + 落实时表 | `#1 … 返回=0x0000 在dispatch中=是 快照=无(0x0) 实时表字节=0x00 …` |

**这三条判读**：判别器的三态（`否` / `是+已登记` / `是+无`）**都亲眼见过** ⇒ 复跑里若出现"读到 0"，
**不会被误当成"探针坏了"**（这正是"仪器必须能变红"要防的假绿）。
牙C 更把本缺陷的核心机制**离线复现**了一遍：**快照 `0x2` ⇒ 返回 `0x8000`，而同一时刻实时表字节是 `0x00`** ——
"快照 ≠ 实时表"这件事在私有装置上已经是可重复的读数，不再只是推理。

---

## 4. 复跑取证的命令与判读（**波后**由我执行；本轮不动权威件）

```bash
# 波内（主控）：重建 native + 同步 4 份副本 ⇒ 记下新 shim sha16（本条读数时要写进报告）
cd src/WpfGfx.Linux.Native && ./build-shim.sh --all

# 波后（我）：整批档 与 按事件泵档 各一次，两条 trace 同时开
MILDIR=$(dirname "$(find build/MilBridge/.artifacts -name wpfgfx_cor3.so | head -1)")
Xvfb :96 -screen 0 1280x1024x24 & echo $! > /tmp/t1x-xvfb96.pid
DISPLAY=:96 WPF_LINUX_KEYSTATE_TRACE=1 WPF_LINUX_MSGFLOW_TRACE=1 \
  LD_LIBRARY_PATH="$MILDIR:$LD_LIBRARY_PATH" \
  dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj -m:1 \
  --filter "FullyQualifiedName~DP1_i" --logger "console;verbosity=detailed" > /tmp/dp1-ks-batch.log 2>&1
DISPLAY=:96 WPF_LINUX_KEYSTATE_TRACE=1 WPF_LINUX_MSGFLOW_TRACE=1 \
  LD_LIBRARY_PATH="$MILDIR:$LD_LIBRARY_PATH" \
  dotnet test tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/ManagedLayer.Tests.csproj -m:1 \
  --filter "FullyQualifiedName~DP1_牙1" --logger "console;verbosity=detailed" > /tmp/dp1-ks-tooth.log 2>&1
kill -TERM "$(cat /tmp/t1x-xvfb96.pid)"
grep -aE "\[KEYSTATE\]|MSGFLOW\] dispatch" /tmp/dp1-ks-batch.log | head -40
```

**判读表（三条互斥，按读数落一条）**：

| 读数形态 | 结论 |
|---|---|
| ① 出现 `在dispatch中=否 … 返回=0x0000`，且 `t=` 落在该档 `dispatch msg=0x0100 vk/wp=0x41` **之前** | **WPF 在派发之外读表**（预处理/泵循环口径）⇒ 候选① 成立，修法方向 = 让**预处理路径**也能拿到该消息的快照 |
| ② 出现 `在dispatch中=是 快照=已登记(0x2) 返回=0x8000`（即修饰位**读得到**）而 `Ctrl+A` 仍不生效 | **失败在下游**（与修饰位无关）⇒ 候选② 成立，转去查 WPF 的命令/文本链路 |
| ③ `vk=0x11(VK_CONTROL)` **一次都没出现**（只有汇总行 `共 0 次调用`） | 失败在 `GetKeyState` **之前**（WPF 根本没问修饰键）⇒ 另一条链，需换探针（"报 0 ≠ 不存在"要用汇总行确认，不许拿"没搜到"当结论） |

**按事件泵档（`~DP1_牙1`）的预期**：`a↓` 派发期内出现 `返回=0x8000 快照=已登记(0x2)`，且牙1 仍绿（`selLen==7`、`Text=="AB"`）
⇒ 该档作为"本来就对"的对照组；两档读数**同 tuple 同开关**，可直接对照。

---

## 5. 已登记的局限（**不许**把本仪器当成"已经完备"）

1. **`s_dispatch_depth` / `s_dispatch_valid` 是进程全局、不是 TLS** ⇒ 多线程取消息时，B 线程在 A 线程派发期间读表会看到
   `在dispatch中=是`（四元组恰好相同时还会拿到 A 的快照）。单泵真应用无此问题；**跨线程/MTA 调用方的读数要按"可能假阳性"看**。
2. `s_dispatch_valid` 单槽：嵌套派发时内层覆盖、退出时清掉外层的快照（探针把 `在dispatch中=` 与 `快照=` 分开打，就是为了让这种情形**可见**）。
3. `GetKeyboardState` **不叠**快照（本轮只登记、不改语义）⇒ 若复跑显示 WPF 走它，那是**第二个缺口**，须单独裁。
4. 本轮探针**不是判据**：它只回答"哪一格失败"，**不改**任何已登记判定（§4.13 的两条候选继续并列）。

---

## 6. 任务 2：`UIAutomationTypes` 的"已知缺口" —— **只读核查结果**

### 6.1 该条在冻结 tuple 上**不成立**（D1 已落地）
| 证据 | 位置/读数 |
|---|---|
| resolver 已编进该工程 | `build/UIAutomationTypes.Linux/UIAutomationTypes.Linux.csproj:95` `<Compile Include="$(WpfLinuxRoot)build/shims/Win32ShimResolver.cs" />`；`:12` `DefineConstants=UIAUTOMATIONTYPES;WINDOWS_BASE_OR_PC` |
| 清单里有它 | `build/shims/UIAutomationTypes.shims.txt` = 2 行（`Win32ShimResolver.cs` + `Accessibility.Shim.cs`）；`UIAutomationProvider.shims.txt` = 1 行 |
| resolver 认这两个程序集 | `build/shims/Win32ShimResolver.cs:41-48` `#elif UIAUTOMATIONTYPES || AUTOMATION → namespace WpfLinux.Shims.UIAutomation`（常量**本来就有**，没动 port-lib 常量表） |
| **已建产物里真的有** | `build/UIAutomationTypes.Linux/bin/Debug/UIAutomationTypes.dll` 内含 `Win32ShimResolver`＝2 处、`DllImportResolver`＝1 处 |
| 应用器自检 | `python3 src/WpfGfx.Linux.Native/tools/wire-uiautomation-resolver.py --check` ⇒ **rc=0**：`[resolver] 分支已就位`、`[清单] …已就位（2 行）`、`[清单] …已就位（1 行）` |

⇒ 结论：**"UIAutomationTypes 未编 resolver"是陈旧条目**（或指 D1 落地之前的波）。建议请 T3 用上面那条 `--check` 复核后改表。

### 6.2 仍**真实存在**的相邻缺口（在我车道，但**不建议本波落**）
| 事实 | 位置/读数 |
|---|---|
| 还剩 1 条 raw P/Invoke 指向 UIA 核心 | `build/UIAutomationTypes.Linux/UiaCoreTypesApi.Linux.cs:124` `[DllImport(DllImport.UIAutomationCore, EntryPoint="UiaLookupId")]`（另两条 `IUnknown` out 参数已被 D2 短路，见 `:127-133`） |
| 该库名**没被映射** | `build/shims/Win32ShimResolver.cs:86-97` 的 `MappedLibraries` 里**没有** `UIAutomationCore.dll` |
| shim 也**没有**这些导出 | `nm -D --defined-only src/WpfGfx.Linux.Native/bin/libwpfwin32.so \| grep -i uia` ⇒ **空**；native 源码里 `UiaLookupId` 0 命中 |
| 另一条走 `LoadLibraryW` | `:89-101 SupportsWin7Identifiers()` → `SecureLoadLibraryEx("UIAutomationCore.dll")` 恒 NULL ⇒ **静默 false**（Win7+ 标识符路径关闭）——**降级**，不是崩溃 |

**影响面（据此收敛）**：`UiaLookupId` 只在"把 GUID 映射成 UIA 整型标识符"的路径上被调用；
`UIAutomationTypes` 的其余功能（标识符类/枚举/事件参数）**不依赖 UIA 核心**。
⇒ 对**渲染/输入/文本链零影响**（这也解释了它一直没被咬到）：今天的行为是**诚实的 `DllNotFoundException`**（resolver 的既定策略，见 `Win32ShimResolver.cs:25-29`）。

**修它的成本与风险**：只把 `UIAutomationCore.dll` 加进 `MappedLibraries` ⇒ `DllNotFoundException` 变
`EntryPointNotFoundException`（**诊断降级**，项目一路在避免，同款论证见 `Win32ShimResolver.cs:116-122`）。
所以必须先落一个 `UiaLookupId` **导出**，而"返回什么"是**语义决定**（真 ID 表不可得；返回 0 或稳定哈希都只是"自洽降级"）⇒
**建议不在本波落**，由主控裁定口径后我再落（成本：native 1 个导出 + resolver 1 行 + 3 条牙）。

**判据（能变红）**：
1. `wire-uiautomation-resolver.py --check` 必须**能红**：删掉清单行 ⇒ `rc=1`（现状已具备该性质，可当回归牙）；
2. 正向牙：反射调用 `UiaCoreTypesApi.SupportsWin7Identifiers()`，断言与"映射是否启用"**同向**（关⇒false；开且导出在⇒true）；
3. **反向牙（保"诚实失败"这条性质）**：在导出未实现时断言 `UiaLookupId` 抛 `DllNotFoundException` ——
   一旦有人"只加映射不加导出"，这条牙立刻红。

---

## 7. 待办
- **波内（主控）**：native 重建 + 4 份副本同步 ⇒ 记下新 shim sha16。
- **波后（我）**：跑 §4 两个场景，把逐次调用原文写进 `M7b-DP1-repro-report.md` 的新小节（§4.14），并据 §4 判读表落一条结论。
- **`D-P1` 强证据**仍等 T3 的 `WFP_POSTWRITE` 写后读数（不动）。

---

# §8 波 24 读数（**私有件 `aebfdaced7149c35` ⇒ 跨配置**，主控 ① 已批准先出）

> ⚠️ **配置标注（逐条适用：不得写进基线、不得当验收）**：本轮读数用的是**私有 shim**
> `/tmp/t1x-ks/libwpfwin32.so` sha16 **`aebfdaced7149c35`（279,288 B）**，权威件是 `91baee84270f2322`
> ⇒ **两者不同 = 跨配置**。桥/PC/PF/WB 未动（`759a322431f1e457`／`6be29475b6aeb34e`／`50da85138a7bc3e8`／`e6216fe961a2bfb9`）。
> 本读数**只用于定位机制**；统一波之后必须**在权威件上复取一次**（命令见 §4）。
> 私有件自证：`[KEYSTATE]` 行与 `dispatch … t=` **只存在于私有 build** ⇒ 出现即证明该路径确实走了私有件。

## 8.1 两档读数（`~DP1_i` 整批抽干 ／ `~DP1_牙1` 按事件泵），同一私有件、两个 trace 同开

| 项 | 整批档 `~DP1_i`（i/i2） | 按事件泵档 `~DP1_牙1` |
|---|---|---|
| `[KEYSTATE]` 行数 | 202（**触顶**：`已达上限 200 行`） | 133（未触顶） |
| 汇总（真实总数） | `本次运行共 368 次调用，已打印 200 行` | `本次运行共 132 次调用，已打印 132 行` |
| **`在dispatch中=是` 的行数** | **0** | **0** |
| 注入窗口内 `vk=0x11` 的返回 | **`0x0000`**（`实时表字节=0x00 实时表 ctrl=0`，`t=154732148`） | **`0x8000`**（`实时表字节=0x80 实时表 ctrl=1`，`t=154741982`） |
| 该窗口的 MSGFLOW `dispatch` | `msg=0x0100 wp=0xa2 快照修饰位=0x2（实时表 ctrl=0）t=154732149`／`msg=0x0100 wp=0x41 快照修饰位=0x2（实时表 ctrl=0）t=154732150` | `msg=0x0100 wp=0xa2 快照修饰位=0x2（实时表 ctrl=1）t=154741768`；**没有** `wp=0x41` 的 KeyDown 派发行 |
| `a↓`（`0x0100/wp=0x41`）派发行数 | **4** | **1**（= `type AB` 的 Shift+A） |
| 结果 | `selLenAfter=0`、`DP.Text="ABseed-文本"`（插入）、`判定=不复现` | **`selLen=7（期望 7）`、`DP.Text="AB"`（期望 "AB"）** |

**逐次调用原文（节选，逐字）**：

```
【整批档】注入窗口
[KEYSTATE] #2  GetKeyState vk=0x11(VK_CONTROL) 返回=0x0000 在dispatch中=否 快照=无(0x0) 实时表字节=0x00 实时表 ctrl=0 shift=0 alt=0 t=154732137ms
[KEYSTATE] #6  GetKeyState vk=0xa2(VK_CONTROL) 返回=0x0000 在dispatch中=否 快照=无(0x0) 实时表字节=0x00 实时表 ctrl=0 shift=0 alt=0 t=154732148ms
（同窗口 #4…#28：0x10/0x11/0x12/0xa0…0xa5 全部 返回=0x0000、在dispatch中=否）
[MSGFLOW] dispatch msg=0x0100(?) vk/wp=0xa2 快照修饰位=0x2（实时表 ctrl=0 shift=0 alt=0）t=154732149ms
[MSGFLOW] dispatch msg=0x0100(?) vk/wp=0x41 快照修饰位=0x2（实时表 ctrl=0 shift=0 alt=0）t=154732150ms
[KEYSTATE] #44 GetKeyState vk=0x11(VK_CONTROL) 返回=0x0000 在dispatch中=否 … t=154732150ms
[KEYSTATE] #47 GetKeyState vk=0x11(VK_CONTROL) 返回=0x0000 在dispatch中=否 … t=154732151ms

【按事件泵档】注入窗口
[KEYSTATE] #20 GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=否 快照=无(0x0) 实时表字节=0x80 实时表 ctrl=1 shift=0 alt=0 t=154741982ms
[KEYSTATE] #24 GetKeyState vk=0xa2(VK_CONTROL) 返回=0x8000 在dispatch中=否 … 实时表 ctrl=1 … t=154741983ms
[KEYSTATE] #28 GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=否 … 实时表 ctrl=1 … t=154741991ms
[MSGFLOW] dispatch msg=0x0100(?) vk/wp=0xa2 快照修饰位=0x2（实时表 ctrl=1 shift=0 alt=0）t=154741768ms
[MSGFLOW] dispatch msg=0x0101(?) vk/wp=0x41 快照修饰位=0x2（实时表 ctrl=1 shift=0 alt=0）t=154741993ms
```

## 8.2 判读：**候选① 成立** —— 失败环节 = "WPF 在**派发之外**读表"
按 §4 的三条互斥判读逐条对：
- ①「`在dispatch中=否` 且 `返回=0x0000`，`t` 落在该档 `a↓` **之前/同刻**」⇒ **命中**（整批档 `t=154732148…154732151`）。
- ②「`在dispatch中=是` 且 `快照=已登记(0x2)` 返回 `0x8000` 而仍不生效」⇒ **不成立**（两档 `在dispatch中=是` 都是 **0** 行）。
- ③「`vk=0x11` 一次都没出现」⇒ **不成立**（整批档出现多次，`t` 就在注入窗口）。

**机制（由读数直接读出）**：
1. **WPF 的修饰键读取全部发生在 `DispatchMessageW` 之外**（两档合计约 500 次调用，`在dispatch中=是` = **0**）
   ⇒ 即 `ComponentDispatcher.ThreadPreprocessMessage` → `HwndKeyboardInputProvider.FilterMessage` 那条**预处理**路径。
2. 因此**波 20/21 的"派发期快照"不在 WPF 的输入路径上**：快照只在 `DispatchMessageW` 里登记/生效，
   而 WPF 在读的时候还没进派发 ⇒ 它读的是**实时表**。
3. 两档的差别只剩"**读取那一刻实时表里是什么**"：
   · 按事件泵：X 事件之间真的泵过 ⇒ 读 `a↓` 时 Ctrl 仍按下 ⇒ `实时表 ctrl=1` ⇒ `0x8000` ⇒ 命令生效
     （且 `a↓` 被输入路径**消费** ⇒ 没有它的 `dispatch` 行）；
   · 整批抽干：4 个 X 事件在第一次派发之前就全部翻译完 ⇒ 实时表被推到**最后一个事件**（Ctrl 已抬）⇒ `0x0000` ⇒ 命令不生效
     ⇒ `a↓` 落到 `DispatchMessageW`（此时快照确实是 `0x2`，**但已经没有人再读它**）。
4. ⇒ §4.13.4 的两条候选**收敛为①**；并且"派发期快照"这条路线**对 WPF 无效**（不是"修得不够"，是**不在路径上**）
   ⇒ 波 20 的"最后一条出队"与波 21 的四元组环形表，在 WPF 这条路径上**属未生效的稳健性补丁**（如实登记；对"派发期读表"的调用方仍有效）。

## 8.3 修法候选（**待主控裁定，本轮不落代码**）
| 候选 | 内容 | 预测的**可红**判据 | 风险/代价 |
|---|---|---|---|
| **甲（零改动）** | 登记为"**批处理型泵/合成整批注入**"的已知边界；真应用连续泵不受影响 | —— | 零风险，但装置侧整批档永远红 |
| **乙（推荐）** | **让实时表对齐 Win32 的"消息队列语义"**：`wpf_queue_pop` 取出**按键消息**时，用该消息自己的 `mods` 快照更新实时表的修饰键字节（Win32 文档：`GetKeyState` 反映的是**消息队列状态**） | **整批两档应变成"替换"语义** ⇒ `DP.Text=="AB"`（断言一行不动，现象变绿） | 小改（pop 内几行）；**会同时改变 `GetAsyncKeyState`/`GetKeyboardState` 的读数**（同一张表）⇒ 需主控裁"本 shim 是否采纳队列语义" |
| **丙（若乙仍红）** | 按"**最早未处理的按键消息**"口径实现（而非"最近出队"） | 同乙 | 复杂度更高；**须先由乙的读数决定** |

**执行序（顺序不可颠倒）**：① 主控统一波重建 native + 同步 4 份副本 ⇒ ② 我在**权威件**上复取 §4 两档（确认 §8.2 机制在权威件上一致）
⇒ ③ 再决定是否落"乙"（届时另开一波，附 §8.3 的可红判据）。

## 8.4 本节的配置与口径限制（必须随读数一起引用）
1. **跨配置**：私有件 `aebfdaced7149c35` ≠ 权威 `91baee84270f2322` ⇒ 不是基线、不是验收；**权威件复取是前置条件**。
2. **整批档触顶**：368 次调用只打了 200 行 ⇒ 第二档注入窗口**没有逐行读数**；
   已打印范围内的事实是"该窗口 `vk=0x11` 返回 `0x0000`"与"整批档 `在dispatch中=是` = 0"两条。
3. `在dispatch中=是` 的**判别器本身**已由离线三态牙证明可用（§3 牙C/E）⇒ "全 0"是本轮**真读数**，不是探针失效。

---

# §9 主控裁定**走乙** —— 已落地 + 要求 3（探针过滤）已落地 + 私有件验证全绿

**主控 2026-09-14 裁定**：走**乙**（实时表采纳 Win32 的**消息队列语义**），并要求同时修掉"额度被非修饰键吃光"的取证缺陷；
若乙在整批档**仍红** ⇒ 立刻上报、不许再叠第三层（转丙由主控裁）。

## 9.1 源已定（**四个** native 源，读数时间 `2026-09-14 18:40:14`）

| 文件 | 新 sha16 | 改了什么 |
|---|---|---|
| `src/WpfGfx.Linux.Native/src/win32_core.c` | `0de70e6b981e1a10` | 探针**只打印修饰键类**（非修饰键按设计不打、只计数）；`GetKeyboardState` 仅在**有修饰键按下**时打；额度**可覆盖**（`WPF_LINUX_KEYSTATE_TRACE_MAX`，非法值回落默认）；汇总给全量真数 |
| `src/WpfGfx.Linux.Native/src/win32_msg.c` | `cff3189eff6c87eb` | **修法乙**：`wpf_queue_pop` 取出**按键类消息**（`WM_KEYDOWN/UP`、`WM_SYSKEYDOWN/UP`）时调 `wpf_keystate_apply_queue_mods(v->mods)`；新增 `mods_valid`（**只有翻译层刚为某个 X 事件盖的戳才算数**，且只对紧随的那一次入队有效 ⇒ `PostMessageW`/`SetTimer` 不会用陈旧戳改写实时表） |
| `src/WpfGfx.Linux.Native/src/win32_x11.c` | `4e695881ef220a3b` | 新增 `wpf_keystate_apply_queue_mods()`：按 `mods` **覆盖**修饰键位，**通用位与左右专有位一起写**（与"两侧一起记"同源），**toggle 低位一律不动**；**不取锁**（调用者持 `g_wpf.lock`） |
| `src/WpfGfx.Linux.Native/src/win32_internal.h` | `c17a7c7541b096e0` | `wpf_msg_node` 增 `mods_valid`；声明 `wpf_keystate_apply_queue_mods()` |

权威件 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` **未被触碰**（`91baee84270f2322`，18:40:14 复读）；私有件 v3 `5c709b8de57901e7`（只编到 `/tmp/t1x-ks2/`）。
编译：7/7 通过、**0 error**、1 条 warning 在 `win32_misc.c:224`（**既有**，本次未改该文件）。

## 9.2 离线牙（私有件，全部实测）
| 牙 | 场景 | 实测原文 |
|---|---|---|
| **乙-正** | 翻译层为 Ctrl↓ 盖戳 `0x2` → 入队 → **出队** → **派发之外**读 `GetKeyState(VK_CONTROL)` | `返回=0x8000 在dispatch中=否 快照=无(0x0) 实时表字节=0x80 实时表 ctrl=1` ⇒ **正是 WPF 那条路径** |
| **乙-反** | Ctrl↑ 盖戳 `0x0` → 入队 → 出队 → 派发之外读 | `返回=0x0000 … 实时表字节=0x00 实时表 ctrl=0` ⇒ 抬起侧同样正确 |
| **要求 3** | 非修饰键 300 次 + 修饰键 4 次 | 逐次行 **4** 行（非修饰键**按设计不打**）；`汇总：共 304 次调用（修饰键 4 次，已打印 4 行；非修饰键 300 次按设计不打）` |
| **额度覆盖** | 默认／`=600`／非法 `=0` | `行上限 200`／`行上限 600`／`行上限 200`（**非法值回落，不会静默变 0 行**） |
| 牙A（回归） | 探针关 | `[KEYSTATE] 行数=0` |
| 牙C/E（回归） | 派发期/无四元组 | `在dispatch中=是 快照=已登记(0x2) 返回=0x8000` ／ `在dispatch中=是 快照=无(0x0) 返回=0x0000` |

## 9.3 行为判据（**私有件 v3，跨配置**；`WPF_LINUX_KEYSTATE_TRACE_MAX=900` 取满逐行）
| 档 | 结果 | 逐行证据 |
|---|---|---|
| **整批抽干 `~DP1_i`（i2/i）** | **`DP.Text="AB"`（替换语义，判据达成）**、`判定=不复现（DP 已更新）`、`rc=0` | 注入窗口：`GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=否 实时表字节=0x80 实时表 ctrl=1`（修法前同一窗口是 `0x0000 / ctrl=0`）；Ctrl↑ 出队后 `返回=0x0000 实时表 ctrl=0`。汇总：`共 312 次调用（修饰键 308 次，**已打印 308 行**；非修饰键 4 次）｜行上限 900` ⇒ **两档窗口都有逐行证据、无触顶** |
| **按事件泵 `~DP1_牙1`／`~DP1_牙2`／`~DP1_API`（回归护栏）** | **全绿**（`selLen=7（期望 7）`、`DP.Text="AB"（期望 "AB"）`；`selLen=1（期望 1）selStart=2 caret=2`；API 极性正确） | —— |
| **全量 16 用例** | `15 通过 / 1 失败`，唯一失败 = **`闸门_win32shim被测件与权威件同sha`**，原文：`**测的是旧件**：被测件 sha16=5c709b8de57901e7 != 权威件 sha16=91baee84270f2322` | ⇒ **闸门自己咬了我**（跨配置跑的必然结果），**说明闸门有效**；权威件到位后该条应为绿 |

## 9.4 口径与限制（必须随读数引用）
1. **跨配置**：私有件 `5c709b8de57901e7` ≠ 权威 `91baee84270f2322` ⇒ **不是基线、不是验收**；权威件复取是前置条件。
2. 乙的**已知取舍**：`GetAsyncKeyState` 与 `GetKeyState` 同源 ⇒ 它也跟着"队列语义"走（真应用连续泵下差别只在消息积压期间，主控已知并裁定接受）。
3. 乙**未**触碰"非按键消息"与"非翻译层盖戳的消息"；`toggle` 低位语义照旧。
4. **丙仍是后备**：若权威件复取时整批档回红（即"最近出队"在读取时刻已被后续出队覆盖），**立刻上报**，按主控要求不叠第三层。

---

# §10 **权威件复取（#9）⇒ 结论**：`D-K1` 第三支已闭合

**本轮 tuple（#9，`/tmp/bridge-frozen.flag` 已复读一致，`BASELINE=9`／`WAVE=close-wave-184230`）**：
桥 `759a322431f1e457`｜PC `e75c7bd5f465ede6`｜PF `52e106e5f46a0dbb`｜WindowsBase `e6216fe961a2bfb9`｜
Provider `71ba86c6495347fe`｜**win32shim `0098234982391bbf`（283,648 B ＝ 我的"乙"＋逐次探针）**｜WIC `03b67fbcd7c385b6`｜
HBTextLine `4044d84a66539c42`(stale=no)｜DWF `2f77dbdf5e7e2cd5`。
**本次读数不再有"私有件"标注**：测试按仓库路径解析并加载**权威件**（闸门行逐字：`权威件 0098234982391bbf` ＝ `被测件 0098234982391bbf`）。

## 10.1 四项判据（全部达成）
| # | 判据 | 结果 |
|---|---|---|
| 1 | `~DP1_i`／`~DP1_i2` 应由"插入"变**替换** | **两档 `DP.Text="AB" 容器="AB"`**；`i2` 另打印 `（泵 400ms，selLen=7）`；`判定=不复现（DP 已更新）`；2/2 通过 |
| 2 | `~DP1_牙1`／`~DP1_牙2`／`~DP1_API` 仍绿（**测试代码一行不改**） | **3/3 通过**：`selLen=7（期望 7）`；`DP.Text="AB"（期望 "AB"）`；`selLen=1（期望 1）selStart=2 caret=2`；`[API] 按住中 GetKeyState(0x11)=0x8000、GetKeyboardState [0x11]=0x80` ／ `松开后 0x0000、0x00` |
| 3 | 全量 16 ⇒ 16 通过 / 0 失败，**staleness 闸门变绿** | **`已通过 用例=16／已失败 用例=0`**（`rc=0`）；闸门 `已通过 … 闸门_win32shim被测件与权威件同sha [129 ms]`，`权威件=被测件=0098234982391bbf` ⇒ **绿**（对照私有件上它正确地报红：`**测的是旧件**：被测件 sha16=5c709b8de57901e7 != 权威件 sha16=91baee84270f2322`） |
| 4 | 逐行样本 + 汇总（应无触顶） | 见 §10.2：**无触顶**，`修饰键 308 次，已打印 308 行` |

## 10.2 `[KEYSTATE]` 逐行样本（注入窗口，逐字）
```
[KEYSTATE] #2  GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=否 快照=无(0x0) 实时表字节=0x80 实时表 ctrl=1 shift=0 alt=0 t=156290683ms
[KEYSTATE] #6  GetKeyState vk=0xa2(VK_CONTROL) 返回=0x8000 在dispatch中=否 快照=无(0x0) 实时表字节=0x80 实时表 ctrl=1 shift=0 alt=0 t=156290693ms
[KEYSTATE] #20 GetKeyState vk=0x11(VK_CONTROL) 返回=0x8000 在dispatch中=否 快照=无(0x0) 实时表字节=0x80 实时表 ctrl=1 shift=0 alt=0 t=156290694ms
[KEYSTATE] #28 GetKeyState vk=0x11(VK_CONTROL) 返回=0x0000 在dispatch中=否 快照=无(0x0) 实时表字节=0x00 实时表 ctrl=0 shift=0 alt=0 t=156290701ms   ← Ctrl↑ 出队之后
[KEYSTATE] 汇总：本次运行共 312 次调用（修饰键 308 次，已打印 308 行；非修饰键 4 次按设计不打；GetKeyboardState 0 次）｜行上限 900
（触顶提示行数 = 0 ⇒ **无触顶**）
```
- 两档注入窗口**都在逐行范围内**：时间簇 `t=156290683…156290695`（第 1 档）与 `t=156293999…156294000`（第 2 档）；
  `vk=(0x11|0xa2)(VK_CONTROL) 返回=0x8000` 共 **14** 行、`返回=0x0000` 共 **62** 行（`grep -E` 口径）。
- 对照 `MSGFLOW`：`dispatch msg=0x0100(?) vk/wp=0xa2 快照修饰位=0x2（实时表 ctrl=1）t=156290694ms` ⇒ **实时表与快照这次一致**
  （修法乙让两者对齐，不再是"快照对、实时表错"）。
- 全量跑（**探针关**）里 `[KEYSTATE]` 行数 = **0** ⇒ 零开销路径在真套件里成立（关掉后不产生任何行，符合 L1 要求）。

## 10.3 结论（`D-K1`）
- **原缺陷已修**：`GetKeyState` 不再是返回 0 的桩、`GetKeyboardState` 已存在（API 牙极性：按住 `0x8000`/`0x80`，松开 `0x0000`/`0x00`）。
- **第三支（批处理型/整批注入）已定位并修好**：失败环节 = **WPF 在 `DispatchMessageW` 之外**（`ThreadPreprocessMessage`/`HwndKeyboardInputProvider` 预处理路径）读**实时表**；
  修法**乙**（实时表采纳 Win32 的**消息队列语义**）落地后，**权威件**上整批两档变**替换语义**、三条牙仍绿、全量 **16/0**。
- **影响面写法维持"按读数收敛"版**：真应用连续泵本就正常；**批处理型调用方现在也正确**（不是靠改测试，而是靠修 shim）。
- **仍然未闭的（如实列）**：① 波 20/21 的"派发期快照"在 WPF 这条路径上**未生效**（登记为稳健性补丁，**未删除**）；
  ② `GetKeyboardState` **不叠**快照（第二条缺口，未裁）；③ 派发标志是**进程全局、非 TLS**（跨线程调用方读数可能假阳性）；④ `D-U1`（`UiaLookupId`）**在册未落**。
- **口径自纠（本轮）**：核对"Ctrl↑ 之后 `0x0000` 的行数"时我漏写 `grep -E`，得到过一个假的 `0` ⇒ **当场用 `-E` 重取**（真值 62）。
  这正是本仓"口径错了会读成 0"的老坑 —— 已按主控要求**独立成节**（见下），便于检索。

---

# §11 记档：**仪器报 0 ≠ 0**（本次现场：`grep -E` 假 0 ⇒ 真值 62）
**可检索关键词**：`grep -E`／假 0／口径／`报 0 ≠ 不存在`

**现场（本报告 §10.2 的核对步骤，2026-09-14）**：核对"`Ctrl↑` 出队之后 `返回=0x0000` 的行数"时，我写的是
`grep -ac 'vk=(0x11|0xa2)\(VK_CONTROL\) 返回=0x0000'` —— **少了 `-E`**。基本正则下 `(0x11|0xa2)` 是**字面量**，
计数得 **`0`**；而"0"与"确实没有这样的行"**看起来一模一样**。
⇒ **当场用 `grep -E` 重取：真值 `62`**（同口径下 `返回=0x8000` 的行数 `14`）。

**同族清单（本项目已多次栽在同一族）**：

| 同族现场 | 假读数 | 真读数（改口径后） |
|---|---|---|
| `strings -el` 打在中文 UTF-16 字面量上 | **0** 条 | 按字节级 `utf-16-le` 计数 ⇒ 有 |
| `grep -c "0x0102"` 把"判定行"也算进去 | 把常量当命中 | 改 `grep -c "msg=258(0x0102"` |
| `find -name` | 命中的是**别的**同名桩 | 按指纹/sha 认件 |
| **本次**：`grep` 少写 `-E` | **0** 行 | **62** 行 |

**判据（写在结论之前，照此自检）**：
1. **凡"计数 = 0"必须先用同一个 pattern 证明它能数出非 0**（正对照）；拿不出正对照就只能写"**未检出**"，
   **不许写"不存在"**；
2. 探针口径同源要求：`汇总` 行必须与"逐次行"一起引用 —— 逐次行可能被额度抑制，`汇总` 给的是**真实总数**
   （本次：`共 312 次调用（修饰键 308 次，已打印 308 行；非修饰键 4 次按设计不打）｜行上限 900`，**无触顶**）；
3. 任何"0/命中"数字若来自 `grep`／`find`／`strings`，**写进报告时把命令原文一起写上**（可复核，别只写结论）。

---

# §12 `D-U1` 裁决与不变量（阶段 1 已落地；阶段 2 等主控信号）

**裁决（主控 2026-09-14 晚，已写入 `KNOWN-DEFECTS.md` 的 `D-U1` 节顶部）**：**不落 native 导出、不把
`UIAutomationCore.dll` 加进 `MappedLibraries`** —— 理由不是成本，而是**这条路径没有可达的调用者**；
为不可达路径造一张编造的 GUID→ID 表 = 把"诚实的失败"换成"看起来有值的编造值"。**落地物 = 两条会变红的仪器。**

## 12.1 四条证据的**独立复核**（逐条；`M7b` 口径，2026-09-14 19:0x）
| # | 主控结论 | 我的复核 | 一致？ |
|---|---|---|---|
| ① | `UiaLookupId` 全仓**零调用点** | 同一条命令我数到 **28** 行（主控 24）：`KNOWN-DEFECTS.md` 12（**含主控刚写进去的裁决节**）＋本报告 6＋上游定义 4＋`build/…/UiaCoreTypesApi.Linux.cs` 4＋**`AutomationIdentifier.cs:34` 1**＋`samples/WpfTextDemo/ARTIFACT-TUPLE-COVERAGE.md` 1。逐条判类后 **调用点 = 0** ✓；差异全部来自**文档行**（主控扫描之后又写进去的），以及**多出的一处 .cs 命中是注释**：`// All Guids will be empty now since we are not calling UiaLookupId, but we need to keep the Guid…`（上游自陈**没有**在调它 ⇒ 反而是佐证）。**结论一致**，仅"逐条都在定义文件与 md 里"这句的枚举要加这一条注释 | ✅（枚举需+1 条注释） |
| ② | 正对照（L21 纪律） | `SupportsWin7Identifiers`：**调用点 1**（`AutomationIdentifierConstants.cs:104`）／定义 2（上游 `:70` ＋ Linux 替代件 `:89`）⇒ 与主控"code 2"（**只数上游**）一致；`UiaGetReservedNotSupportedValue` 我数 **22**（主控 21，多的一行是本报告自己的文字） | ✅ |
| ③ | `SupportsWin7Identifiers()` 在 Linux 上**不可达** | 机制我逐环复核过（比"20 条 false"更具体）：`OSVersionHelper.cs:103 IsOsWindows7OrGreater = IsWindows7OrGreater();`／`:109 IsOsWindowsVistaOrGreater = IsWindowsVistaOrGreater();`，两者都是 `[DllImport(DllImport.PresentationNative, CallingConvention=Cdecl)] [return: MarshalAs(UnmanagedType.I1)] private static extern bool …`（`:170-184`）⇒ 经 **D1 的 resolver** 落到本 shim 的 20 条 `WPF_OSVERSION_FALSE`（`win32_misc.c:1214-1234`，宏体 `return 0;`）⇒ **恒 false**；`AutomationIdentifierConstants.cs:103-105` 的 `else if (IsOsWindows7OrGreater \|\| (IsOsWindowsVistaOrGreater && …))` ⇒ **短路** ⇒ 永不调用。`nm -D --defined-only … \| grep -c " T IsWindows"` 我复算 = **20**（与主控一致，且列表里确有 `IsWindows7OrGreater`／`IsWindowsVistaOrGreater`） | ✅ |
| ④ | `RawUiaLookupId` 的 `[DllImport("UIAutomationCore.dll")]` **永不被 JIT 解析** ⇒ **不可达**（不是降级） | 由 ①②③ 合成；另有一条独立佐证：上游 `AutomationIdentifier.cs:34` 的注释自陈"我们不再调用 `UiaLookupId`" ⇒ 设计上就没人调 | ✅ |

> **口径小记（我自己的一个坑，记以备查）**：我一度把 `AutomationIdentifierConstants.cs` 的目录读成
> `UIAutomationTypes/System/Windows/Automation/`（`read`/`sed` 都报"没有那个文件"，只有 `grep` 能读到 ⇒ 当时很可疑）。
> **真身是 `UIAutomationTypes/MS/Internal/Automation/`** —— 是**我读错了**，不是文件系统的问题。判据：路径有疑问时先 `find -name <basename>`，别拿"工具报不存在"当结论。

## 12.2 阶段 1 落地物：`wire-uiautomation-resolver.py` 的**零调用者不变量 + 正对照**
- 文件：`src/WpfGfx.Linux.Native/tools/wire-uiautomation-resolver.py`（sha16 **`1b428ff42a6aaa73`**；改前 `30fadde86bfe3e72`）。
- **保留**原有幂等检查（resolver 分支 + 两份 `shims.txt`），新增：
  · `[零调用者]` **字符串级子串**扫描（**不是**语法级/词边界 ⇒ 反射用法与 `EntryPoint = "…"` 同样被看见）；
    扫描根 `upstream/ build/ src/ tests/ samples/`，跳过 `bin/ obj/ .artifacts/ node_modules/ .git`；
    命中按 `调用点／定义／文档注释` 三类分别报出，**并把不可读/二进制文件数一并报出**（不许静默丢）。
  · `[正对照]` **同一次运行内**数 `SupportsWin7Identifiers` 的**调用点**，**必须 ≥1**；数不出 ⇒ `[仪器无信息]`。
  · **退出码**：`0` = 绿；`1` = 清单未就位**或**不变量被破（发现调用点）；`2` = **仪器无信息**（正对照数不出，**不许报绿**）。
  · `--root <dir>`：把"仓库根"指向别处 —— **专为"用临时副本做突变"的牙**而加（默认仍是从本文件推出的仓库根）。
  · **自排除**：仪器自身文件不计入扫描（它**必须**含 needle 字面量，否则恒红）——已在代码里注明。

## 12.3 三条牙（**全部实测能红**；真源只读，突变只在 `/tmp` 副本上）
镜像：`/tmp/du1-mut`（6 个文件，含正对照那一行），纯净备份 `/tmp/du1-pristine`；原始输出存 `/tmp/du1-teeth/*.log`。

| 牙 | 命令 | 期望 | **实测** |
|---|---|---|---|
| 基线 A | `python3 …/wire-uiautomation-resolver.py --check`（**真源**） | rc=0 | `[零调用者] `UiaLookupId`：调用点 0 ／ 定义 4 ／ 文档注释 24（不可读/二进制文件 375 个已跳过）`；`[正对照] SupportsWin7Identifiers：调用点 1 ／ 定义 2`；`✅ 不变量成立`；**rc=0** |
| 基线 B | `… --check --root /tmp/du1-mut` | rc=0（副本复现真源结论） | 同上逐字（定义 4／正对照 1／✅）；**rc=0** |
| **牙①** | 副本里**加一个调用点**（`return UiaCoreTypesApi.UiaLookupId(AutomationIdType.Property, ref g);`）后 `--check --root /tmp/du1-mut` | rc=1 且**点名** | `调用点 1`＋`**调用点** …/AutomationIdentifierConstants.cs:486: return UiaCoreTypesApi.UiaLookupId(AutomationIdType.Property, ref g);`；`[不变量被破] … 必须重新裁决（**不许只加映射**）`；**rc=1** |
| **牙②** | 还原后**删掉正对照的调用点**，再 `--check --root /tmp/du1-mut` | rc=2「仪器无信息」，**不许绿** | `[正对照] … 调用点 0 ／ 定义 2`；`[仪器无信息] … 本次「零调用点」的结论**不成立**（不许报绿）`；**rc=2** |
| **牙③** | 从纯净备份还原后再跑 | rc=0 | 与基线 B 逐字相同；**rc=0** |

**真源未被突变**（复读）：`UiaCoreTypesApi.cs` `1f1336068d6f9e5b`、`AutomationIdentifierConstants.cs` `5765ab0b15a7d774`（与突变前逐字相同）。

## 12.4 ⚠️ 这三条牙的**第一轮就抓出了我自己的三个 bug**（如实登记）
1. **`_classify()` 把 needle 写死成 `UiaLookupId`** ⇒ 判正对照那一趟用的是主 needle 的形状 ⇒ 正对照**恒 0** ⇒ 仪器**恒报"无信息"**（`rc=2`）。**即：v1 根本没在监控不变量**（它连基线都过不去）。
2. **仪器把自己算成了"调用点"**（`NEEDLE = "UiaLookupId"` 那行）⇒ 修好 ① 之后会**恒红**。⇒ 加**自排除**。
3. **我的镜像目录少一级**（`…/MS/Internal/` 而非 `…/MS/Internal/Automation/`）⇒ 正对照文件不在副本里 ⇒ 牙①/② 全是 `FileNotFoundError` 与被污染的结论。
⇒ 三条都是**在牙里现形**的（不是"我加过断言了"就算数）。这也正是主控红旗③要防的东西，故记在此处。

## 12.5 阶段 2（**等主控信号，本轮未动**）
`tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/UIAutomationLinuxTests.cs` 增两条托管牙（接在 `D1_/D2_` 之后）：
**`D3`**＝`OSVersionHelper.IsOsWindowsVistaOrGreater == false` **且** `AutomationIdentifierConstants.LastSupportedProperty == Properties.TransformCanRotate`（运行时证"落到最后那个 `else`"）；
**`D4`**＝反射调 `UiaCoreTypesApi.UiaLookupId` **必须抛 `DllNotFoundException`**（**不是** `EntryPointNotFoundException`）⇒ 钉住"只加映射不加导出"这个未来错误。
变红实测：能廉价做就做（改错期望常数／在**独立输出路径**下加映射），做不到就**如实登记"未取得变红实测 + 将来在协调窗口里怎么变红"**。
**触发条件**：主控发"#11 波已结束 / PC 已重建 + 新 sha"之后再动（避免与 T1d 的 `D-T1` 波重叠）。
**读数纪律（阶段 2 执行时照做）**：构建/测试前后各记 `pc`／`windowsbase`／`uia` 位 sha 一次；`--no-build` 前先确认构建 **0 错**。

## 12.6 阶段 2 的**代码形态**（"贴上去就能编译"；本轮**未落**，只写形态）
**为什么全用反射**：`AutomationIdentifierConstants`／`UiaCoreTypesApi`／`OSVersionHelper` 都是 **internal**，
测试程序集没有 `InternalsVisibleTo`（D1/D2 的既有做法就是反射 + 按名找类型 ⇒ 沿用同一风格，不新开口径）。
可复用的现成件：文件里已有 `private static class Record { public static Exception Exception(Action body) }`、
静态字段 `UiaTypesAssembly`；D2 已用 `UiaTypesAssembly.GetType("MS.Internal.Automation.UiaCoreTypesApi", throwOnError: false)`。

```csharp
// ==================================================================
//  D3：Linux 上 UIA 标识符**落到最后那个 `else` 档**（不可达的运行时证词）
//      ⇒ 同时证明 `SupportsWin7Identifiers()` 那一支**永不执行**（D-U1 的证据③④）
// ==================================================================
[Fact]
public void D3_Linux上UIA标识符落到最后那个else档()
{
    // ---- ① 谓词侧：这两个谓词在 Linux 上必须为 false（shim 的 WPF_OSVERSION_FALSE 恒 0）----
    Type ovh = null;
    foreach (Type t in UiaTypesAssembly.GetTypes())          // 按名扫描，**不写死命名空间**（D1 同风格）
        if (t.Name == "OSVersionHelper") { ovh = t; break; }
    Assert.True(ovh != null, "UIAutomationTypes 里找不到 OSVersionHelper —— 上游搬家了？（本牙失效，别静默跳过）");

    object vista = ovh.GetProperty("IsOsWindowsVistaOrGreater",
                        BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic)?.GetValue(null);
    object win7  = ovh.GetProperty("IsOsWindows7OrGreater",
                        BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic)?.GetValue(null);
    _out.WriteLine($"OSVersionHelper.IsOsWindowsVistaOrGreater={vista} ／ IsOsWindows7OrGreater={win7}");
    Assert.False((bool)vista, "Vista 谓词在 Linux 上必须为 false（为 true ⇒ shim 的 OS 谓词不再是恒 0，D-U1 前提变）");
    Assert.False((bool)win7,  "7 谓词在 Linux 上必须为 false");

    // ---- ② 档位侧：跑到最后那个 else ⇒ LastSupportedProperty == Properties.TransformCanRotate ----
    Type aic = UiaTypesAssembly.GetType("MS.Internal.Automation.AutomationIdentifierConstants", throwOnError: false);
    Assert.True(aic != null, "找不到 MS.Internal.Automation.AutomationIdentifierConstants");

    // ⚠️ 它是**静态字段**（`internal static Properties LastSupportedProperty;`），不是属性 ⇒ 用 GetField
    FieldInfo f = aic.GetField("LastSupportedProperty",
                        BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
    Assert.True(f != null, "LastSupportedProperty 不再是字段 ⇒ 本牙要改断言（别静默跳过）");
    object actual = f.GetValue(null);                        // 读静态字段本身就会触发 cctor（= 跑那条 if/else 链）

    // ⚠️ `Properties` 是**嵌套枚举**（值从 30000 起），不是公开的 `AutomationProperty` 类
    //    ⇒ 必须按**枚举成员相等**断言（用 Assert.Same / NotNull / >=30000 都是**恒真**的假牙）
    Type props = aic.GetNestedType("Properties", BindingFlags.Public | BindingFlags.NonPublic);
    object expected = Enum.Parse(props, "TransformCanRotate");
    _out.WriteLine($"LastSupportedProperty={actual}（期望 TransformCanRotate={expected}）");
    Assert.Equal(expected, actual);

    // ---- ③（加固项；本仓已把这一档的五个值登记在 KNOWN-DEFECTS 的 D-U1「已知边界」里）----
    Assert.Equal(Enum.Parse(aic.GetNestedType("Events",         BindingFlags.Public|BindingFlags.NonPublic), "Window_WindowClosed"),
                 aic.GetField("LastSupportedEvent",         BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic).GetValue(null));
    Assert.Equal(Enum.Parse(aic.GetNestedType("Patterns",       BindingFlags.Public|BindingFlags.NonPublic), "ScrollItem"),
                 aic.GetField("LastSupportedPattern",       BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic).GetValue(null));
    Assert.Equal(Enum.Parse(aic.GetNestedType("TextAttributes", BindingFlags.Public|BindingFlags.NonPublic), "UnderlineStyle"),
                 aic.GetField("LastSupportedTextAttribute", BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic).GetValue(null));
    Assert.Equal(Enum.Parse(aic.GetNestedType("ControlTypes",   BindingFlags.Public|BindingFlags.NonPublic), "Separator"),
                 aic.GetField("LastSupportedControlType",   BindingFlags.Static|BindingFlags.Public|BindingFlags.NonPublic).GetValue(null));
}

// ==================================================================
//  D4：`UiaLookupId` 仍是**诚实的** `DllNotFoundException`
//      ⇒ 钉住"只把 UIAutomationCore.dll 加进 MappedLibraries、却不落导出"这个**未来错误**
// ==================================================================
[Fact]
public void D4_UiaLookupId仍是诚实的DllNotFound()
{
    Type api = UiaTypesAssembly.GetType("MS.Internal.Automation.UiaCoreTypesApi", throwOnError: false);
    Assert.True(api != null, "找不到 MS.Internal.Automation.UiaCoreTypesApi");

    MethodInfo mi = api.GetMethod("UiaLookupId", BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic);
    // ⚠️ 这里**不学 D2 的"类型不在就 return"**：静默跳过 = 假绿。上游真搬走了 ⇒ 让本牙变红（信息性红），
    //    因为"这条 P/Invoke 还在不在"本身就是 D-U1 的前提。
    Assert.True(mi != null, "上游把 `UiaLookupId` 搬走/改名了 ⇒ D-U1 的前提变了，本牙必须重写（**不要**静默跳过）");

    Type idType = api.GetNestedType("AutomationIdType", BindingFlags.Public | BindingFlags.NonPublic);
    object[] args = { Enum.ToObject(idType, 0), Guid.Empty };     // `ref Guid` 参数：反射按装箱值传入即可

    Exception err = Record.Exception(() => mi.Invoke(null, args));
    _out.WriteLine($"UiaLookupId(type, ref guid) ⇒ {(err == null ? "**没抛**" : err.GetType().Name)}");

    Assert.True(err != null,
        "`UiaLookupId` **能调通**了 ⇒ 说明有人落了导出（或加了映射）⇒ D-U1 的裁决必须重审（这是**信息性红**）");

    // 反射会把目标异常包在 TargetInvocationException 里 ⇒ 必须**拆一层**再判类型
    Exception inner = (err as TargetInvocationException)?.InnerException ?? err;
    Assert.IsType<DllNotFoundException>(inner);           // **精确类型**：子类也不算（这就是判据本身）
    Assert.IsNotType<EntryPointNotFoundException>(inner); // 显式点出"禁止的降级"（只加映射不加导出 ⇒ 变这个）
}
```

## 12.7 两条牙的**变红方案**（谁改／改哪一行／谁还原；**不碰真源与在册产物**为优先）
> 统一前提：**都在主控划定的协调窗口内做**（阶段 2 信号之后）；每条做完**立刻**复读相关 sha 并记进报告。

### D3 变红
| 路线 | 谁改 / 改哪一行 | 还原 | 期望 |
|---|---|---|---|
| **A（实质突变，优先；不碰真源、不碰产物）** | **我（M7b）**：把 `src/WpfGfx.Linux.Native/src/win32_misc.c` 的宏 `WPF_OSVERSION_FALSE(name) int name(void){return 0;}` 在 **`/tmp` 源码副本**里改成 `return 1;`，用 `build-shim.sh` **同一套 flag** 编到 **`/tmp/du1-mut-shim/libwpfwin32.so`**（= 独立输出路径） | **无需还原真源**（只改副本）；跑完把 env 去掉即可 | `WPF_LINUX_WIN32_SHIM=/tmp/du1-mut-shim/libwpfwin32.so dotnet test … --filter D3` ⇒ 谓词变 **true** ⇒ 档位跳到 **Win7 档**（`IsSynchronizedInputPatternAvailable`）⇒ `Assert.Equal(TransformCanRotate, actual)` **红**；不带 env 复跑 ⇒ **绿** |
| **B（廉价兜底）** | 我：把 D3 的期望常数改成 `Enum.Parse(props, "IsSynchronizedInputPatternAvailable")` | `git checkout -- tests/…/UIAutomationLinuxTests.cs`（改动前记 sha） | 立刻 **红** ⇒ 证明"断言真的在看那个值"（不是恒真） |
> **为什么 `WPF_LINUX_WIN32_SHIM` 是干净的突变通道**：它是 resolver 的**最高优先级覆盖**（`build/shims/Win32ShimResolver.cs:65` `ShimPathEnv`），指向哪份 shim 就加载哪份 ⇒ **在册权威件一字不动**。

### D4 变红
| 路线 | 谁改 / 改哪一步 | 还原 | 期望 |
|---|---|---|---|
| **A（实质突变，优先；不碰真源、不碰产物）** | 我：`cp -r tests/…/ManagedLayer.Tests/bin/Debug/net10.0 /tmp/du1-mut-bin/`；再 `cp /tmp/du1-mut-bin/libwpfwin32.so /tmp/du1-mut-bin/UIAutomationCore.dll`（**把 ELF 的文件名改成那个库名**丢在 app 目录 ⇒ 库按原名被找到、但**符号不存在**）；然后 `dotnet vstest /tmp/du1-mut-bin/ManagedLayer.Tests.dll --TestCaseFilter:"FullyQualifiedName~D4"` | 删掉 `/tmp/du1-mut-bin` 即可；真源与在册产物**未动**（核对 `git status` 干净 + 权威件 sha 复读） | 异常由 `DllNotFoundException` 变 **`EntryPointNotFoundException`** ⇒ D4 **红** |
| **B（廉价兜底）** | 我：把 D4 的期望类型改成 `EntryPointNotFoundException` | 同上（记 sha） | 立刻 **红** |
> ⚠️ **风险登记（不许掩盖）**：路线 A 依赖".NET 默认探测会在 app 目录按 `UIAutomationCore.dll` 这个**文件名**去找库"这条行为；
> 若实测不成立（仍是 `DllNotFoundException`）⇒ **如实登记"未取得变红实测"**并改用 B，**不许**写"应该会红"。

### 两条牙的**恒真陷阱**（写下来防止后来人改成假牙）
- D3：`Assert.NotNull(actual)`、`Assert.True((int)actual >= 30000)`、或拿 `actual` 自己当期望值 ⇒ **恒真**（`Properties` 是枚举、首值就是 30000）。
- D4：只断言"抛了某个异常"（`Assert.Throws<Exception>`）⇒ 把 `EntryPointNotFound` 也放行 ⇒ **假绿**；本牙用 `Assert.IsType<>`（**精确类型**）。
- 两条都**不要**用 D2 那种"类型找不到就 `return`"的写法（= 静默通过）。

## 12.8 事实复核（只读）：Linux 上**运行时**取到的是哪一档
**结论：最后那个 `else` 档** —— 也就是 `LastSupportedProperty = Properties.TransformCanRotate`。
**证据链（逐环 `file:line`，全部只读）**：
1. `AutomationIdentifierConstants.cs:29-119`：静态构造是一条**纯 `if/else if` 链**，**每一个**条件都是
   `OSVersionHelper.IsOsWindows*OrGreater`（`:31 RS5 → :39 RS4 → :47 RS3 → :55 RS2 → :63 RS1 → :71 TH2 → :79 10 → :87 8.1 → :95 8 → :103 7‖(Vista && SupportsWin7Identifiers())`），最后 `:112 else` 档 = `Properties.TransformCanRotate`（其余四项 `Window_WindowClosed`／`ScrollItem`／`UnderlineStyle`／`Separator`）。
2. `OSVersionHelper.cs:89-119`：这些属性在静态构造里**逐个**赋成对应 P/Invoke 的返回值（`:103 IsOsWindows7OrGreater = IsWindows7OrGreater();`、`:109 IsOsWindowsVistaOrGreater = IsWindowsVistaOrGreater();`）；对应声明见 `:126+`：`[DllImport(DllImport.PresentationNative, CallingConvention = Cdecl)]`。
3. `PresentationNative_cor3.dll` 经 **D1 的 resolver** 映射到本 shim；本 shim 的 20 条谓词由
   `win32_misc.c:1214` 的 `WPF_OSVERSION_FALSE(name) int name(void) { return 0; }` 生成 ⇒ **全部 false**；
   `nm -D --defined-only … | grep -c " T IsWindows"` = **20**（含 `IsWindows7OrGreater`／`IsWindowsVistaOrGreater`）。
4. ⇒ 链上每个条件都 false ⇒ 控制流落到 `:112 else`。**因此 `D3` 的断言表达式**（§12.6 已写成代码）：
   `Assert.False(OSVersionHelper.IsOsWindowsVistaOrGreater)` ＋ `Assert.Equal(Enum.Parse(props,"TransformCanRotate"), LastSupportedProperty)`。
**它能红在哪（"能红"的三种情形）**：① shim 的谓词不再是恒 0（§12.7 路线 A 已把这条**可执行化**）；
② resolver／映射回归 ⇒ 谓词抛异常或取到别的库的值；③ 上游把 `:112 else` 那一档的值改掉（⇒ 本仓的"已知边界"登记也要跟着改）。
**它不会红的情形（如实说）**：上游在链**上方**再加一档（例如 Win11）——只要谓词恒 false，Linux 仍落最后 `else` ⇒ 本牙仍绿，**这是对的**（不变量没破）。
**口径更正（我先前理解错了一半）**：`Properties` 是 `AutomationIdentifierConstants` 的**嵌套枚举**（`:125` 起，首值 30000），
`LastSupportedProperty` 是 **静态字段**（`:23 internal static Properties LastSupportedProperty;`）而**不是**属性
⇒ 反射必须用 `GetField` 且断言必须是**枚举成员相等**（这正是"能红"与"恒真"的分界）。

---

# §13 `D-U1` **阶段 2 已落地**（`D3`/`D4` 两条托管牙 + 变红实测；tuple = #11）

## 13.1 交付物与落点
| 项 | 值 |
|---|---|
| 文件 | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/UIAutomationLinuxTests.cs` |
| 落点 | **D2 之后**（第 164 行起，类内末尾）；新增 `D3_Linux上UIA标识符落到最后那个else档`、`D4_UiaLookupId仍是诚实的DllNotFound`，＋两个私有 helper `Nested()`／`StaticField()` |
| before → after | sha16 `9367a8d930c90554` → **`2618aed85a598d96`**；行数 165 → **254** |
| **diff 机械断言** | 删除行 **0**、新增行 **89**（= 254−165）；`cmp` 证明**前 163 行与改动前逐字相同** ⇒ 改动只落在 D2 之后的声明锚点 ✓ |
| 备份（纪律 16） | `/tmp/m7b-p2/UIAutomationLinuxTests.before.cs`（改动前）／`…with-D3D4.cs`（交付版），还原用**整份拷回** |

## 13.2 四条用例（D1–D4）**全绿**（构建 **0 错**，`rc=0`）
```
已通过 …D1_UIAutomationTypes的OSVersionHelper静态构造不再DllNotFound [4 ms]
已通过 …D2_保留值API不再抛封送异常 [5 ms]
已通过 …D3_Linux上UIA标识符落到最后那个else档 [12 ms]
已通过 …D4_UiaLookupId仍是诚实的DllNotFound [1 ms]
```
**D3 的 `_out` 原文**（= 运行时把"落到最后那个 `else`"钉住）：
```
OSVersionHelper.IsOsWindowsVistaOrGreater=False ／ IsOsWindows7OrGreater=False
LastSupportedProperty=TransformCanRotate（期望 TransformCanRotate=TransformCanRotate）
```
**D4 的 `_out` 原文**：
```
UiaLookupId(type, ref guid) ⇒ TargetInvocationException
   内层异常=System.DllNotFoundException
```

## 13.3 **变红实测**（四条，全部有命令与输出原文）
| # | 突变（谁改／改哪） | 命令 | 实测原文 | rc |
|---|---|---|---|---|
| **D3-A** | **我**：`/tmp` 源码副本把 `win32_misc.c:1214` 的宏改成 `return 1;`，编到 **`/tmp/m7b-p2/shim-mut/libwpfwin32.so`**（sha16 `274540078333f848` ≠ 权威 `0098234982391bbf`） | `WPF_LINUX_WIN32_SHIM=/tmp/m7b-p2/shim-mut/libwpfwin32.so dotnet test … --filter UIAutomationLinuxTests --no-build` | `OSVersionHelper.IsOsWindowsVistaOrGreater=True ／ IsOsWindows7OrGreater=True` ＋ `Vista 谓词在 Linux 上必须为 false（为 true ⇒ shim 的 OS 谓词不再恒 0 ⇒ D-U1 前提变）` | **1** |
| **D3-B** | 我：把**期望档位**改成 `IsSynchronizedInputPatternAvailable`（B 兜底） | `dotnet test … --filter D3_` | `Assert.Equal() Failure: Values differ` / `Expected: IsSynchronizedInputPatternAvailable` / `Actual: TransformCanRotate` ⇒ **档位断言这条也能红** | **1** |
| **D4-A** | 我：`/tmp/m7b-p2/native-mut/` 放一份**只读拷贝并改名**的 `UIAutomationCore.dll`（283,648 B，sha16 = 权威 shim），用 `LD_LIBRARY_PATH` 指过去 ⇒ **库能被找到、符号不存在**（= "只加映射不加导出"那个未来错误的形态） | `LD_LIBRARY_PATH=/tmp/m7b-p2/native-mut:$MILDIR:… dotnet test … --filter D4_ --no-build` | `Expected: typeof(System.DllNotFoundException)` / `Actual: typeof(System.EntryPointNotFoundException)` / `内层异常=System.EntryPointNotFoundException` | **1** |
| **D4-B** | 我：把**期望异常类型**改成 `EntryPointNotFoundException`（B 兜底） | `dotnet test … --filter D4_` | `Assert.IsType() Failure: Value is not the exact type` / `Expected: EntryPointNotFoundException` / `Actual: DllNotFoundException` | **1** |

**两条通道试过但没用（如实记）**：① `dotnet vstest <裸 dll>` 在本 SDK（VSTest 18.0.2）直接报 `参数 … 无效`；② `NATIVE_DLL_SEARCH_DIRECTORIES=<dir>` 指向改名 ELF **不生效**（仍 `DllNotFoundException`）。
⇒ **有效通道 = `LD_LIBRARY_PATH` + 改名 ELF**（D4-A）与 `WPF_LINUX_WIN32_SHIM`（D3-A）；两条都**不碰真源、不碰在册产物**（只读拷贝 + 独立目录）。

## 13.4 ⚠️ 本轮我自己踩的两个坑（同属"陈旧件／口径"族，如实登记）
1. **`cp -p` 还原 ⇒ 增量构建跳过重编**：还原后的源 mtime（20:22:13）**比突变后编出的程序集旧** ⇒ MSBuild 判定"已最新" ⇒
   "还原后复跑"用的其实是**突变后的旧程序集** ⇒ 假红（原文 `D4_… [FAIL] Assert.IsType() Failure: Value is not the exact type`）。
   **修法／判据**：`cp -p` 还原后**必须 `touch`**（或删 `obj/`），并同时记"源 mtime 与程序集 mtime"；本次 `touch` 后 `rc=0`、内容 sha 未变（仍 `2618aed85a598d96`）。
2. **计数口径两处假 0/假判**：① 我用 `grep -c '已失败 '` 判"变红是否取得"，而本 logger 下失败行是 `[FAIL]`／`Failed` ⇒ **把 D4-A 的成功误标成"未取得"**（当场用原文更正）；
   ② unified diff 的删除行标记是 `-` 不是 `<` ⇒ 我第一版数出"删除行 0／新增 0"两个假值（改用 `^-`／`^+` 并排除 `---`/`+++` 后：0／89）。
   ⇒ 与 `L21` 同族（**仪器报 0 ≠ 0**），两条现场都记在此节。

## 13.5 九位 before / after（#11 冻结值**逐位未变**）
| 位 | 值（before **20:22:21** → after **20:25:25**；突变/还原的跑都在 20:22–20:25 之间） |
|---|---|
| win32shim | `0098234982391bbf` → `0098234982391bbf` |
| bridge | `759a322431f1e457` → `759a322431f1e457` |
| pc | `4f2e621a4ad26cd0` → `4f2e621a4ad26cd0`（**同源重建后 sha 不变**——与主控纪律 3 的实测一致） |
| pf | `0878daff7a14d385` → `0878daff7a14d385` |
| wb | `e6216fe961a2bfb9` → `e6216fe961a2bfb9` |
| provider | `71ba86c6495347fe`（载体：`build/DirectWriteForwarder.Linux/bin/Debug/DirectWrite.Linux.Provider.dll`） |
| wic | `03b67fbcd7c385b6`（`…/publish/MilBridge.Linux/release_linux-x64/libwpfwic.so`） |
| hbtextline | `b4c7aa8210c71cbe`（`build/shims/PresentationCore.HbTextLine.cs`） |
| dwf | `2f77dbdf5e7e2cd5`（`build/DirectWriteForwarder.Linux/bin/Debug/DirectWriteForwarder.dll`） |
⇒ 我的构建**没有顶掉 #11 的任何一位**；`provider`／`dwf`／`hbtextline` 三位是**按指纹认件**定位的（不是猜路径）。
（另记一条现场观察：`pf` 在 19:42 我读到 `83fd8ff18fd15344`、冻结时是 `0878daff7a14d385` ⇒ 该位在我读数之后、冻结之前变过一次，**不是我造成的**，此处只作时间线记录。）

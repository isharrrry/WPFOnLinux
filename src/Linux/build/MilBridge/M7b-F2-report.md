# M7b · F2 报告：`Win32Exception(1400)` 的**诊断**落地（源码级）

> **本轮显式声明：未构建权威件、未安装、未发桥、未重建 PC。**
> 理由（主控口径）：应用槽被 T3 占用；`cp -f` 覆盖**已被 mmap** 的 `libwpfwin32.so` 会让正在跑的进程
> **SIGBUS** ⇒ 安装动作留给主控（T3 收工后）。
>
> 一处**如实披露**：为拿到"期望输出原文"，我把源码编到了 **`/tmp/t1x-shim/libwpfwin32.so`**（私有目录，
> **未安装、未覆盖任何副本、不接触应用槽**）。权威件 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`
> sha16 **在报告建立时（约 16:07）为 `6213489cb202fd55`**；**16:12:30 现场重读为 `e1691fd8440da926`
> （269,616 B，bin mtime 16:10:02；3 份 probe 副本 16:10:06，四份同 sha）** —— 主控重编，含 F2；
> 详见 **附 D** 的 sha 审计（含一次"读早了"的自我更正）。若要求字面执行"不构建"，可忽略 `/tmp` 那几条读数
> —— 源码本身不依赖它们。

---

## 0. 这一轮解决的"实体缺口"

T3 wave-9 现场：`Win32Exception(1400)` 起不来（约 1/6）。而 **1400 是本工程自己映射的复用值**：

| 站点 | 位置 | 语义 |
|---|---|---|
| X 连接不可用 | `src/WpfGfx.Linux.Native/src/win32_core.c:454`（原 `:390`） | `wpf_x11_ensure()` 失败 |
| `XCreateWindow` 失败 | `src/WpfGfx.Linux.Native/src/win32_core.c:490`（原 `:423`） | `wpf_x11_create_window()` 返回 0 |
| "hwnd 查不到" | `win32_core.c` 11+ 处 | `ERROR_INVALID_WINDOW_HANDLE` |

⇒ 只看 1400 **分不清**这三种；而 `WpfLinuxWin32_LastError()`（`win32_exports.c:95-108`）**全仓无人调用**
—— 真原因（X 连接错误 + Xlib 异步错误）一直躺在原生侧没人读。本轮把这条链补齐。

---

## 1. 交付 ①：源码改动（新增行的 file:line）

### 1.1 原生侧（`src/WpfGfx.Linux.Native/**`，我的车道）

| 文件 | 行 | 内容 |
|---|---|---|
| `src/win32_internal.h` | `336` | `wpf_global` 新增 `char x_error[256];`（Xlib 异步错误文案） |
| `src/win32_internal.h` | `448` | 声明 `wpf_x11_install_error_handler()` |
| `src/win32_internal.h` | `449` | 声明 `wpf_win_diag_report(where, cls, parent, err)` |
| `src/win32_internal.h` | `450` | 声明 `wpf_x11_diag_selftest_xerr()`（牙齿） |
| `src/win32_x11.c` | `70-83` | **`wpf_x_error_handler`**：抓 `error_code/request_code/minor_code/resource` + `XGetErrorText` 文案写进 `g_wpf.x_error`。**不加锁**（见下"约束"） |
| `src/win32_x11.c` | `85-88` | `pthread_once` 幂等安装 `XSetErrorHandler`（**此前全仓 0 处安装**，主控消息里说的"已有 2 处命中"经核**不成立于本 shim**） |
| `src/win32_x11.c` | `94-107` | `wpf_x11_diag_selftest_xerr()`：对坏 window id `0xdeadbeef` 发 `XGetWindowAttributes` + `XSync` ⇒ **真 X 错误**（牙齿路径） |
| `src/win32_x11.c` | `114` | 构造期（`XInitThreads` 之后、任何 Xlib 调用之前）调用安装 |
| `src/win32_core.c` | `64` | 初始化 `g_wpf.x_error[0] = 0` |
| `src/win32_core.c` | `68,73,106-127` | `wpf_win_diag_selftest()`：`WPF_LINUX_WIN_DIAG=selftest|xerr` 时在首次 `wpf_global_init` 合成/触发一条（**带重入护栏**，见"踩到的坑"） |
| `src/win32_core.c` | `84-103` | **`wpf_win_diag_report()`**：4 行 stderr（失败点 / X 连接 + `dpy_error` / Xlib 异步错误 / 窗口参数），**每进程 ≤8 行** |
| `src/win32_core.c` | `454` | 站点①`X11 不可用` ⇒ 调 `wpf_win_diag_report`（**加在 `wpf_set_last_error(1400)` 旁，行为不变**） |
| `src/win32_core.c` | `490` | 站点②`XCreateWindow 返回 0` ⇒ 同上 |
| `src/win32_exports.c` | `95-108` | **`WpfLinuxWin32_LastError()` 合成**：`dpy_error` 与 `x_error` 都有 ⇒ `"<dpy_error> \| Xlib: <x_error>"`；只有其一 ⇒ 返回其一（**这是托管接线能读到有用串的前提**） |

**约束（写进注释了）**：X 错误处理器是在**持有 `g_xlock` 的线程**里被 Xlib 同步回调的，而 `g_xlock`
是**非递归**锁 ⇒ 处理器内**不加任何锁**（只写 `g_wpf.x_error`，竞争只影响文案，不影响功能）。

### 1.2 托管侧（**新增应用器**，`src/WpfGfx.Linux.Native/tools/**`）

| 文件 | 内容 |
|---|---|
| `src/WpfGfx.Linux.Native/tools/patch-shared-hwndwrapper-diag.py`（**新**） | 补丁 P 应用器（家族约定：无参=应用、`--check` 未就位退 1、幂等、锚点缺失报错） |
| `build/WindowsBase.Linux/HwndWrapper.Linux.cs`（生成物） | 上游 `Shared/MS/Win32/HwndWrapper.cs` 逐字复制 + **1 处诊断接线**（`WpfLinuxShimDiag.ReportCreateFailure(...)` @`:147`）+ 新增 `internal static class WpfLinuxShimDiag`（`:390+`，`[DllImport("user32.dll", EntryPoint="WpfLinuxWin32_LastError")]`） |
| `build/WindowsBase.Linux/WindowsBase.Linux.csproj` | 接线：`Remove` 上游 `HwndWrapper.cs` + `Include` 生成物（自带 marker） |

**为什么放在 `_handle == 0` 分支**：那是**上游本来就有的**建窗失败分支（原本只做 `hwndSubclass.Dispose()`）
⇒ 只多打一行 stderr，**不抛/不吞/不改返回值/不动 `CreateWindowEx` 调用**。
**为什么读 shim**：`Dispatcher..ctor → MessageOnlyHwndWrapper..ctor → HwndWrapper..ctor` 全在 WindowsBase，
而 `Win32Exception(1400)` 的 1400 只有 shim 知道真含义。

### 1.3 sha256（本轮涉及文件，取前 16 位）

```
edcd2d7319bdd235  src/WpfGfx.Linux.Native/src/win32_core.c
1c9bbd60b8845402  src/WpfGfx.Linux.Native/src/win32_x11.c
0ca0268e639ef70b  src/WpfGfx.Linux.Native/src/win32_internal.h
37c73c85ff263527  src/WpfGfx.Linux.Native/src/win32_exports.c
9bfffec10cf6936c  src/WpfGfx.Linux.Native/tools/patch-shared-hwndwrapper-diag.py
0ab3046ec34ac844  build/WindowsBase.Linux/HwndWrapper.Linux.cs            ← 生成物
28e49ef10b026266  build/WindowsBase.Linux/WindowsBase.Linux.csproj         ← 已接线（旧 1ed8af7e375217f1）
6213489cb202fd55  src/WpfGfx.Linux.Native/bin/libwpfwin32.so                ← 报告建立时的读数；**16:2x 现场重读已变**（见附 D）
ee0b5c47a41e9c83  /tmp/t1x-shim/libwpfwin32.so                            ← 仅旁证，未安装
```

**应用器自检/幂等/负例（原始结论）**：`--check` 未就位 `rc=1` → 无参应用（`+41 行`，注入 2 行接线）→
`--check rc=0` → 再跑一次 `内容已是最新（未重写）/ 已就位（幂等，不改）`。

---

## 2. 交付 ②：能变红的牙（**不依赖 WPF 应用**的 X 错误触发路径）

### 2.1 触发方式

```bash
# 真 X 错误路径（需要有 X；用 `DISPLAY` 指到一个 Xvfb 即可）
WPF_LINUX_WIN_DIAG=xerr  python3 -c "import ctypes;L=ctypes.CDLL('<shim>');L.WpfLinuxWin32_EnsureX11()"
# X 不可用路径（unset DISPLAY）
env -u DISPLAY -u WPF_LINUX_DISPLAY WPF_LINUX_WIN_DIAG=selftest python3 -c "...同上..."
```
时机：进程**第一次**调 shim（`wpf_global_init`）即触发；随后 `[WIN_DIAG]` 打到 stderr。

### 2.2 期望输出原文（实测截取）

**B：`xerr` + `DISPLAY=:93`**（真 X 错误 ⇒ 走 `XSetErrorHandler` 捕获）
```
[WIN_DIAG] CreateWindowEx 失败：where=selftest(xerr)：对坏 window id(0xdeadbeef) 发请求 last_error=1400（**本 shim 自己映射的码**；1400=ERROR_INVALID_WINDOW_HANDLE 在这里是复用值，真原因见下）
[WIN_DIAG]   X 连接: dpy=有 x_failed=0 dpy_error="(空)"
[WIN_DIAG]   Xlib 异步错误: error_code=3(BadWindow (invalid Window parameter)) request_code=3 minor_code=0 resource=0xdeadbeef
[WIN_DIAG]   窗口参数: cls="HwndWrapper[selftest]" parent=0x0（message_only=0）
LASTERR= error_code=3(BadWindow (invalid Window parameter)) request_code=3 minor_code=0 resource=0xdeadbeef
```
**A：`selftest` + 无 `DISPLAY`**（X 不可用 ⇒ 走 `dpy_error`）
```
[WIN_DIAG] CreateWindowEx 失败：where=selftest last_error=1400（…复用值，真原因见下）
[WIN_DIAG]   X 连接: dpy=无 x_failed=0 dpy_error="SELFTEST：这是合成原因串，用于验证 [WIN_DIAG] 打印管线（不是真的建窗失败）"
[WIN_DIAG]   Xlib 异步错误: (无：请求还没回错误事件，或不是 X 请求失败)
[WIN_DIAG]   窗口参数: cls="HwndWrapper[selftest]" parent=0x0（message_only=0）
LASTERR= XOpenDisplay("(null)") 失败：无 X server 或 DISPLAY 不可用。窗口相关用例应被跳过（无 DISPLAY 的机器上属预期行为）。
```
**牙齿（红）**：把 `wpf_win_diag_report` 里的 `dpy_error=\"%s\"` 字段或整条格式串改坏 ⇒ 上面第 2 行消失/变形
⇒ 以 `grep -q 'dpy_error='` 为判据的自检**必红**（本轮已用 `xerr`/`selftest` 两种模式各验一次；
托管侧另有文本级牙齿：删掉生成物里的 `WpfLinuxShimDiag.ReportCreateFailure(...)` ⇒ `--check rc=1`，重放后 `rc=0`）。

### 2.3 什么时候**不会**打印（说清边界，免得误判）

| 情形 | 是否打印 | 原因 |
|---|---|---|
| 建窗**成功** | 否（除非将来加成功路径打印） | 只在两个失败站点调用 |
| 进程已经打过 8 条 | 否 | 有界（防止失败风暴淹没日志） |
| `WPF_LINUX_WIN_DIAG` 未设 / 设成别的值 | **仍然打印**（失败路径默认开） | 默认开是有意的：**"下次真出现 1400 时一定有输出"** |
| 失败发生在**句柄查找**（"hwnd 查不到"那 11+ 处） | 否 | 本轮只覆盖建窗两站点（登记为后续：F1/F4 一起做） |
| X 请求错误但**还没同步**（无 `XSync`/无往返） | `x_error` 可能为空 | 异步错误要等下次同步点；文案里已注明"(无：请求还没回错误事件…)" |

### 2.4 "打印了 ≠ 进了判据"（这条已被处理）

- **当前判据不读它**：`[WIN_DIAG]`（原生 stderr）与 `[SHIM_DIAG]`（托管 stderr）目前**不在任何 runner 判据里**
  —— runner 的块级判据仍是应用自报的 `[feat] …` 行 + 像素核对；triage 只 grep 崩溃字样。
  ⇒ **本轮交付定位为"诊断"**，不会把 INCONCLUSIVE 刷成 PASS，也不会掩盖失败。
- **读点（如果将来要进判据）**：① 应用日志里的 `[SHIM_DIAG] HwndWrapper 建窗失败…`（托管侧，含 shim 真原因）；
  ② 同日志的 `[WIN_DIAG]`（原生侧，含 `error_code/request_code`）。两者都是**纯追加**，可安全作为 runner 的
  额外证据字段（例如塞进 `WFP_CRASH_BLOCK=` 那行的 evidence 里）——**本轮不动 runner**（T3 车道）。

---

## 3. 交付 ③：**为什么下次会打印**（一句话 + 对到 1400 的哪一步）

> 建窗失败的三条路径**都会**走到这两行里的一行：`win32_core.c:454`（`wpf_x11_ensure()` 返回 0 ⇒ X 连接不可用）
> 或 `:490`（`wpf_x11_create_window()` 返回 0 ⇒ `XCreateWindow` 失败），两处都在 `wpf_set_last_error(1400)`
> 的**同一分支**里调 `wpf_win_diag_report(...)`；该函数**默认开**（不等任何 env）、**每进程 ≤8 行**、
> 直接 `fprintf(stderr)` + `fflush` ⇒ 只要 `HwndWrapper` 那次 `CreateWindowEx` 返回 0，stderr 上
> **一定**出现 `[WIN_DIAG] CreateWindowEx 失败：where=…` 四行，其中第 2/3 行给出 `dpy_error` 与
> `error_code/request_code` —— 也就是 1400 **背后**那一步真正失败的原因。

---

## 4. 交付 ④：留给主控的三条安装命令

```bash
# ① 构建（权威件；注意：确认此刻没有进程 mmap 着它，否则 SIGBUS）
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux/src/WpfGfx.Linux.Native && bash build-shim.sh --all

# ② 同步 4 份副本（别手工 cp；用既有脚本/流程）
#    真源：src/WpfGfx.Linux.Native/bin/libwpfwin32.so
#    副本：build/MilBridge/tests/CompositeFontProbe/bin/Release/、build/MilBridge/tests/ContractProbe/bin/Release/、
#          build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/、以及**权威部署目录**（app-local）
#    ⚠️ 安装前先确认没有正在跑的进程 mmap 着目标文件

# ③ 打印三方 sha（装完自查；三者必须一致）
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so \
          build/MilBridge/tests/ContractProbe/bin/Release/libwpfwin32.so \
          <权威部署目录>/libwpfwin32.so | cut -c1-16
```

**另外（托管那一半，随 PC 波一起）**：重放应用器链时**必须包含**
`python3 src/WpfGfx.Linux.Native/tools/patch-shared-hwndwrapper-diag.py`
（`port-lib.py WindowsBase` 会抹掉它的接线 —— 与补丁 M/N/O 同样的坑，已在本轮 `--check` 中验证：
抹掉后 `--check rc=1`，重放后 `rc=0`）。

### 装完要重跑什么 / 哪些读数作废

| 动作 | 说明 |
|---|---|
| **必须重跑** | T3 的 `1400` 复现（3 轮）：这次日志里会**自带** `[WIN_DIAG]`/`[SHIM_DIAG]`；据此决定 F1（去闩锁+重试）还是 F4（"创建中"状态） |
| 必须重跑 | 任何"基线七元组"读数：`win32shim_sha` 会变成**新一轮现场重读的那个值**（见附 D 的代次表）⇒ T3 刚冻的基线在**换 shim 那一刻**作废，需重新冻结 |
| 作废的读数 | 我在 `/tmp/t1x-shim` 上取的 `[WIN_DIAG]`/`LASTERR` 读数（`sha16 ee0b5c47a41e9c83`）**仅作"源码可编译 + 管线可用"的旁证**；换正式件后应以正式件的 sha 重取一次 |
| 不受影响 | `run.sh tline` / ManagedLayer / CoverageProbe 等**不读** `[WIN_DIAG]`（纯追加诊断） |

---

## 5. 本轮踩到的坑（写下来防复发）

1. **自检无限递归 ⇒ SIGSEGV(139)**：`WPF_LINUX_WIN_DIAG=xerr` 的自检本身要调 `wpf_x11_ensure()`
   → `wpf_global_init()` → 又回到自检 ⇒ 栈溢出。已加**重入护栏**（`s_running/s_done`）。
2. **ctypes 忘了 `restype=c_char_p`**：`WpfLinuxWin32_LastError()` 的指针被截成 32 位 ⇒ 驱动脚本自己段错误
   （**不是 shim 的 bug**）。驱动已修，报告里的读数取自修好之后的运行。
3. `XSetErrorHandler` **此前一处都没装**（主控消息里的"已有 2 处命中"经核不成立于本 shim）⇒ 本轮是首次安装，无重复安装风险。

## 6. 登记欠账（本轮**不做**，按主控排序）

- **F1**：`wpf_x11_ensure()` 的 `x_failed` **永久闩锁**（`win32_x11.c:93/105`）⇒ 一次瞬时失败=该进程所有 X API 全废；应改"有限重试"。
- **F4**：建窗回调重入时的"创建中"状态（消除 `ERROR_INVALID_WINDOW_HANDLE` 误报面）。
- 托管侧计数（`InputManager`/`HwndSource` 的 `RawTextInputReport`/`TextInput`）—— 等 `KEY_DIAG` 判定后再谈。
- 键翻译保真：`Ctrl/Alt` 组合、`Shift` 字符（已在上一轮 F1 落地，见 `win32_x11.c` KeyPress 分支）。

---

# 附 A（**下一轮可选工作**，本轮不做）：`[WIN_DIAG]` 的覆盖缺口表

**缺口是什么**：本轮 `wpf_win_diag_report()` 只挂在**建窗失败的两处**（`win32_core.c:454` / `:490`）。
但 `1400` 这个码在本工程里**还用于 12 处"hwnd 查不到"**，它们**同样只留一个 1400、不留任何上下文**。
若下次崩溃落在这些站点上，`[WIN_DIAG]` **一行都不会打**（⇒ 见 §B.7 牙③ 的"134 但零 `[WIN_DIAG]`"分诊规则）。

| # | 文件:行号 | 函数 | 触发条件（守卫） | 原本会**吞掉**什么信息 | 若补上会多出的那一行（建议形态） | 优先级 |
|---|---|---|---|---|---|---|
| 1 | `src/win32_core.c:553` | `DestroyWindow` | `hwnd == NULL` | 调用方传了空句柄；是谁（WPF 哪条 Dispose 路径） | `[WIN_DIAG] hwnd 查不到：api=DestroyWindow hwnd=0x0 原因=空句柄 表内窗口数=N` | **P1** |
| 2 | `src/win32_core.c:558` | `DestroyWindow` | `wpf_window_find` 未命中 | **"从未创建"与"已销毁"不可区分**；重复销毁被当失败 | `…api=DestroyWindow hwnd=0x… 原因=不在表里（已销毁/未创建）最近销毁=0x…` | **P1** |
| 3 | `src/win32_core.c:643` | `ShowWindow` | 同上（**先 map 后查表失败** ⇒ 可能已经 `XMapWindow` 过） | 显示顺序与建窗完成度；X 侧已 map 但表里没有 | `…api=ShowWindow hwnd=0x… cmd=… 原因=不在表里 x11_mapped=?` | **P1** |
| 4 | `src/win32_core.c:659` | `MoveWindow` | 同上 | 几何设置失败（启动期常见：一建窗就摆位置） | `…api=MoveWindow hwnd=0x… 原因=不在表里` | **P1** |
| 5 | `src/win32_core.c:680` | `SetWindowPos` | 同上 | **启动期最热**（`HwndTarget` 建好后必调） | `…api=SetWindowPos hwnd=0x… flags=0x… 原因=不在表里` | **P1** |
| 6 | `src/win32_core.c:866` | `SetParent` | 同上（`HWND_MESSAGE` 的父子化走这里） | message-only 的父子关系；T3 现场正是 message-only 建窗失败 | `…api=SetParent hwnd=0x… newParent=0x… 原因=不在表里` | **P1** |
| 7 | `src/win32_core.c:709` | `GetClientRect` | 同上 | 客户区查询失败（每帧可能调） | 同上（无参数可带，只报 api+hwnd） | P2 |
| 8 | `src/win32_core.c:722` | `GetWindowRect` | 同上 | 同上 | 同上 | P2 |
| 9 | `src/win32_core.c:779` | `GetWindowLongPtrW` | 同上 | **`GWL_WNDPROC`/`GWL_STYLE` 读失败**（子类化链会用到） | `…api=GetWindowLongPtrW hwnd=0x… index=… 原因=不在表里` | P2 |
| 10 | `src/win32_core.c:812` | `SetWindowLongPtrW` | 同上 | 写失败 ⇒ 上层以为设置成功 | `…api=SetWindowLongPtrW hwnd=0x… index=… value=… 原因=不在表里` | P2 |
| 11 | `src/win32_core.c:898` | `GetWindow` | `!known`（**不断言失败**，只设错误码） | 遍历窗口链失败 | `…api=GetWindow hwnd=0x… cmd=… known=0` | P2 |
| 12 | `src/win32_core.c:1071` | `set_prop_utf8` | 未命中 | 属性写失败（标题/`_NET_WM_NAME` 等） | `…api=SetProp hwnd=0x… name=… 原因=不在表里` | P3 |
| 13 | `src/win32_msg.c:492` | `PostMessage` | 窗口不在表里且不是 root | PostMessage 到已销毁窗口 —— **这里 1400 语义正确**（Win32 亦如此） | 只需诊断、**不改码**：`…api=PostMessage hwnd=0x… msg=0x… 原因=窗口不在表里` | P3 |

**建议实现形态（下一轮一次做完，别散落 13 份）**：在 `win32_core.c` 加
`void wpf_win_diag_unknown_hwnd(const char *api, HWND hwnd, const char *extra)`，与 `wpf_win_diag_report()`
**共用同一套有界计数**（≤8 行/进程、默认开），12 处各改一行调用；`extra` 带该 API 的参数
（`cmd/index/flags/newParent/msg`），保持"一行一条、可 grep"。
**验收**：应用日志里任何一次 1400 都能在 `[WIN_DIAG]` 里看到**具体 api + hwnd**。

### 附 A.1 另一条结构性事实（主控现场核出；T3 已据此改 runner 口径）

**native `[msg]` trace 打在 *dispatch 期*，而 WPF 在 *thread-preprocess 期* 就会处理掉一批消息**：

- `[msg]` 行的产生点是 `wpf_dispatch_to_window()`（`win32_msg.c:304` 调 `wpf_trace_msg()`，其 `fprintf` 在 `:293`）
  ⇒ **只有走到"派发"这一步的消息才会被记录**；
- 上游 WPF 在 `ComponentDispatcher.ThreadPreprocessMessage` 阶段就可能把消息标成 handled
  （**`WM_CHAR` 正是其中之一**）⇒ 该消息**不会进入 `DispatchMessage`** ⇒ `wpf_dispatch_to_window()` 不被调用
  ⇒ **`[msg]` 里天然看不见它**。
- ⇒ **口径规则（T3 的 runner 已改）**：`WM_CHAR=0` **不许**读成"shim 没产 `WM_CHAR`"；
  同理 `WM_KEYDOWN=0` 也不许读成"键没到窗口"。
- ⇒ **正确的"收到即记"读点是** `[KEY_DIAG] XEV …`（补丁 F3，打在 **X 事件泵的接收处**：
  `win32_x11.c` 的 `wpf_x11_pump_into_queue()`，**早于任何托管预处理**）⇒ 判定"键到没到 shim"必须以它为准。
  这也是这条诊断当初必须在**接收点**而不是派发点落地的理由。
- ⇒ 同理，**建窗失败**也可能表现为"`[msg]` 里什么都没有但应用死了"（§B.6 的②），这与本节的盲区是同一族问题。

---

# 附 B：**`1400` 忠实复现协议**（交主控执行；本轮只写协议，不动代码）

> 累计进度：**0 / 60 launches**（本文档建立时）。计数建议写在 `WPTD_BASELINE_OUT` 的注释行里。

## B.1 目标与"一轮"的定义

- **目标**：在**装好 F2 的权威件**上判定 `Win32Exception(1400)`（启动期偶发，历史观测 ≈1/6）是否仍可复现，
  并让**每次复现自带真原因**。
- **一轮（round）** = 一次 `run-wpftextdemo.sh`，覆盖 `default` + `env` 两档、每档 `REPEAT` 次
  ⇒ **一轮 6 次 launch**（`REPEAT=3`）。**10 轮 = 60 launches**。
- 计数只看 **launch**：一轮 6 次全有效才记 6；有无效 launch ⇒ 该 launch 不计，轮内其余照记。

## B.2 精确命令与环境（**逐字照抄**）

```bash
# 0) 前置：确认装的是**新件**（见 B.7 牙①）；确认无别的应用在跑（一次只放一个）
sha256sum src/WpfGfx.Linux.Native/bin/libwpfwin32.so | cut -c1-16     # 期望 = 装完 F2 后的新 sha

# 1) 一轮（6 次 launch；超时 60s；运行目录与基线输出都显式指定，别用共享默认值）
cd /home/links-dev/netTest/wpf-linux-20260906/wpf-linux
ROUND=03
WPTD_RUN_DIR=/tmp/f2r-$ROUND \
WPTD_BASELINE_OUT=$HOME/f2-runs/round-$ROUND.baseline.txt \
REPEAT=3 \
  tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both \
  > $HOME/f2-runs/round-$ROUND.log 2>&1
echo "round=$ROUND rc=$?"        # ← 必须这样取 rc（**不许** `| tail; RC=$?`）
```

| 变量 | 值 | 说明 |
|---|---|---|
| `DISPLAY` | **`:97`**（runner 默认；被占则改空闲号并记录） | runner 复用已存在的 `:97`，否则自起 Xvfb 并记 PID |
| `WPF_LINUX_WIN_DIAG` | **不设**（失败路径默认开） | ⚠️ **绝不许**设 `selftest`/`xerr`：那会**合成一次建窗失败** ⇒ 该轮变假阳性 |
| `WPF_LINUX_KEY_DIAG` | **不设** | 与 1400 无关，只会淹没日志（键输入是另一条线） |
| `WPF_LINUX_DISPLAY` | 不设 | 让 shim 读 `DISPLAY` |
| `REPEAT` | `3` | 每档重复次数（基线的 `rep=1..3` 由此产生） |
| `WPTD_BASELINE_OUT` | `$HOME/f2-runs/round-NN.baseline.txt` | 必须**不在共享临时目录**（runner 头注要求）；七元组写在这里 |
| 超时 | `60`（位置参数，秒） | 与基线同口径；改值必须写进轮记录 |

## B.3 轮间等待与"这一轮有效"的条件

边界：本机 **3 核 / 7 GB**，且**可能**有外来构建（wpf2web，非本工程）在吃 CPU。

**开跑前（全部满足）**：
1. **负载闸门**：`/proc/loadavg` 的 1 分钟值 **≤ 12**；>12 则等 2 分钟重测、最多 5 次；5 次仍 >12 ⇒ **本轮不跑**（记 `SKIPPED`，不计 launch）。
2. **外来构建**：看到非本工程的大宗编译（wpf2web 等）⇒ **仍可跑但必须记** `foreign_build=yes`；若该轮出现复现，用它判定该复现是否可信（B.4）。
3. **X 状态**：`xdpyinfo -display <DISPLAY_NUM> >/dev/null` 成功（或由 runner 自起）；失败 ⇒ 本轮无效。
4. **无残留/无并发**：`pgrep -P $$ -f "dotnet WpfTextDemo.dll"` 为空，且 `max_concurrent_apps` 必须 =1。
5. **期望 sha 一致**：记录 `expected_shim_sha`，并等于当前 `src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 的 sha16。

**收尾后（判定有效性）**：
6. `WPTD_SUMMARY=` 与 `WPTD_TIER_SUMMARY=…` 都在（缺 ⇒ 无效轮：runner 没跑完）。
7. `max_concurrent_apps=1` 且 `leftover_after=0`（否则无效轮）。
8. 七元组行至少 1 条且 `win32shim:` 位 == `expected_shim_sha`（不符 ⇒ 标 `pre-F2`，**不计入** F2 后统计）。
9. **轮间隔** ≥ 30 s；上一轮有复现则 ≥ 60 s 并记录。

## B.4 三值判定（**写死**）

| 判定 | 条件（**全部满足**） |
|---|---|
| **复现 REPRO** | ① 某次 launch 退出码 = **134**；② 该 launch 日志含 `Win32Exception` 且括号内是 **1400**；③ 该 launch `frames_good=0` 且 `window=none`；④ **装 F2 后**日志里出现 `[WIN_DIAG] CreateWindowEx 失败：` **四行**（原文见 §2.2 B 样本）。④ 缺失 ⇒ 见 B.7 牙③（**不是**"未复现"）。 |
| **未复现 NOREPRO** | 该轮 6 次 launch **全部** 退出码 **143**、`frames_good>0`，**且**日志里 `[WIN_DIAG] CreateWindowEx 失败：` 出现 **0** 次。 |
| **无效轮 VOID** | 命中 B.3 的 3/4/6/7/8 任一条：X 死、并发/残留、`WIN_DIAG=selftest\|xerr` 被设、七元组缺失或 sha 不符（`pre-F2`）、runner 未跑完、被外部因素打断（OOM/被杀）。**VOID 不计入 60**，必须记原因。 |

## B.5 每轮/每次 launch 要记的字段（**机读行原文，不要改写**）

每次 launch 一行（runner 自产，`run-wpftextdemo.sh:1032`）：
```
WPTD_TIER=<tier> rep=<r> RESULT=<PASS|FAIL|INCONCLUSIVE> exit=<143|134|…> notdrawn=<n> drawn=<n> colors=<n>
  frames_good=<n>/<n> frames_blank=<n> scroll=<v>/<ae> capture=<ok|…> max_concurrent_apps=1 leftover_after=0
  ring=<…> chan2_committed=<…> chan2_pending=<…> cross_ae=<…> blocker=<…> shot=<path> input_probe=<…>
```
每轮一行（`WPTD_BASELINE_OUT`，**含七元组**）：
```
BASELINE tier=<tier> rep=<r> config=pc:<sha16>,bridge:<sha16>,pf:<sha16>,provider:<sha16>,win32shim:<sha16>,
  wic_shim:<sha16>,hbtextline_shim:<sha16>(stale:<yes|no>) result=<…> exit=<…> … rundir=<…>
```
复现时**额外**粘贴原文：`[WIN_DIAG]` 四行 +（托管补丁 P 落波后）`[SHIM_DIAG]` 两行 + 该 launch 的 `exit=134` 行 +
`rundir` + 时间戳 + 当时 `loadavg` + `foreign_build`。

## B.6 装了 F2 之后：打哪 4 行、"没打"时怎么追

**① `CreateWindowEx` 返 0 时**（原文见 §2.2 的 B 样本）：第 1 行给**失败站点**
（`where=X11 不可用` / `where=XCreateWindow 返回 0`）；**第 3 行给 1400 背后的真原因**
（`Xlib 异步错误: error_code=… request_code=… minor_code=… resource=…`）；第 2 行给 `dpy_error`
（X 连接不可用路径的文案）。⇒ "1400 是真错误码还是我们映射的"当场可见。

**② 若 `CreateWindowEx` 没返 0，应用仍失败** —— 依次取三条读数：
1. 日志里有没有 `[WIN_DIAG] hwnd 查不到…`（**附 A 落地后才有**）⇒ 有 ⇒ 落在 12 处之一，看它给的 `api/hwnd`；
2. `[msg]` 消息 trace（runner 默认 `WPF_WIN32_MSG_TRACE=1`）：最后一条 `[msg]` 是什么、发给哪个 `hwnd`；
   **一条 `[msg]` 都没有** 且 `window=none` ⇒ 死在**第一个窗口之前**（Dispatcher 的 message-only 窗口）；
3. 托管侧若仍报 `Win32Exception(1400)` 而**无**任何 `[WIN_DIAG]`：用补丁 P 的读点
   `WpfLinuxWin32_LastError()` 看 shim 是否记了原因；两者都空 ⇒ 失败**不是** X 层造成的
   ⇒ 转托管栈（`HwndSubclass`/`CreateWindowEx` 回调内抛出的那条）。

## B.7 牙：**不能只靠"没打印 = 没复现"**（三条，缺一协议就会撒谎）

1. **sha 闸门（防"装错/没装"）**：**不许把任何 sha 写死在协议里**——闸门值 = **每轮开跑前现场重读**的
   `expected_shim_sha`。**一条命令拿到四份（+旁证件）的 sha/字节/mtime，直接贴进轮记录**：
   ```bash
   # 每轮开跑前跑这一条（含时刻；四份必须同 sha，否则该轮 VOID）
   date '+%F %H:%M:%S（现场重读时刻）'
   find . -name 'libwpfwin32.so' -not -path './upstream/*' | sort | while read f; do \
     printf '%s %s B %s %s\n' "$(sha256sum "$f"|cut -c1-16)" "$(stat -c%s "$f")" \
            "$(date -d @$(stat -c%Y "$f") '+%H:%M:%S')" "$f"; done
   ```
   ⚠️ **别只读 `bin/` 那一份**：三份 probe 副本会随构建/发布被刷新（本轮实测 16:10:02 编 bin、16:10:06 刷副本），
   只读一份就会重演附 D 那次"4 秒窗口快照当结论"的错。
   **装完 `MSGFLOW` 那一版（`build/MilBridge/M7b-msgflow-report.md`）后 shim sha 会再变一次**
   ⇒ **之前所有轮次一律按旧 sha 记**，且该变之后要重跑一次 §B.7 牙② 的 smoke（确认新件里 F2 仍生效）。
   该轮 6 次 launch 的七元组 `win32shim:` 位必须 == `expected_shim_sha`；不符 ⇒ 由代次表判 `pre-F2`/`post-F2`、
   不计入目标代次的复现率。
   **代次表（只作"认出是哪一代"用，绝不当"当前值"引用；每个值都带取值时刻）**：
   | 代次 | sha16 | 内容 / 取值时刻 |
   |---|---|---|
   | 早一代（pre-input-work） | `4c023937421db45f` | 无 `KEY_DIAG`、无键翻译修正 |
   | 输入路径代（F1/F2focus/F3） | `6213489cb202fd55` | 有 `KEY_DIAG`/Shift/Ctrl 语义/`XSetInputFocus`；T3 上一批 `WFP_ARTIFACTS` 报的就是它 |
   | **F2 诊断代（当前权威件）** | **`e1691fd8440da926`** | 269,616 B；bin mtime **16:10:02**；3 份 probe 副本 **16:10:06**，**四份同 sha**；**16:12:30 现场重读核对**（含 `[WIN_DIAG]`/`XSetErrorHandler`/`LastError` 合成）；桥同批重发 = `e0d01832a3efea53`（4,937,968 B，16:11:04） |
   | **下一趟（MSGFLOW 代，待主控安装）** | **现场重读** | 含 `[MSGFLOW]` 入队/出队 trace + `PM_NOREMOVE` 两条风险告警（见 msgflow 报告）；装的那一刻起上一代所有轮次按旧 sha 记 |
   | **PC 波（进行中）** | **现场重读** | 补丁 P 接线 + T1c 输入追踪 ⇒ **`pc:`/`pf:` 位再变**；那一变之后才是"当前配置" |
   ⇒ "装 F2 后这个值会被换掉，换的那一刻起所有更早的轮次按旧 sha 记"。
2. **管线 smoke（防"代码在但没生效"）**：**在复现轮之外**单独跑一次（自起 Xvfb、按 PID 收尾）：
   ```bash
   WPF_LINUX_WIN_DIAG=xerr DISPLAY=:<空闲号> python3 -c \
     "import ctypes;L=ctypes.CDLL('<装好的 libwpfwin32.so>');L.WpfLinuxWin32_EnsureX11();\
      L.WpfLinuxWin32_LastError.restype=ctypes.c_char_p;print(L.WpfLinuxWin32_LastError().decode())"
   ```
   期望：`[WIN_DIAG]` 四行 + `error_code=3(BadWindow…)`。**打不出来 ⇒ 权威件里的 F2 不生效**
   ⇒ 该轮所有"未复现"结论作废。⚠️ 这条**绝不能**混进复现轮（会把假失败写进统计）。
3. **"134 但零 `[WIN_DIAG]`"分诊（防假阴性）**：出现 134 + `Win32Exception(1400)` 却**没有** `[WIN_DIAG]` ⇒
   **不许**判"未复现"，应判 **`REPRO-NODIAG`（新缺陷类别）**：失败点在**建窗两站点之外**
   （附 A 的 12 处之一，或托管侧抛的 1400）⇒ 进 B.6 的②/③ 继续追并登记看板。

---

# 附 C：**装完 F2 后哪些既有读数作废**

| 作废的东西 | 为什么 | 处置 |
|---|---|---|
| **七元组的 `win32shim:` 位** | **两个不同的位**：**装 F2 前** = 每轮现场重读值（本文档写作期实测为 `6213489cb202fd55`）；**装 F2 后** = `e1691fd8440da926`（16:10 那一代，**四份同 sha，16:12:30 现场重读核对**） | 所有旧 `BASELINE … config=…` 行**不再与新一轮可比**，新基线必须重写 |
| **七元组的 `bridge:` 位** | 桥已按 `publish-milbridge.sh` 重发 ⇒ `e0d01832a3efea53`（4,937,968 B，16:11:04；两处产物同 sha，本人 16:12:30 现场核对一致） | 同上：桥位变了，旧基线里凡含 `bridge:` 的对比一律作废 |
| `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:6-11` 那 6 条 `BASELINE tier=… rep=…` | 同上（`config=` 里含旧 `win32shim`） | **重冻**（建议在 F2 **与** 托管补丁 P **都落波后**一次性重冻） |
| 一切"跨运行字节/像素可比"的派生量（`cross_ae`、`colors`、`shot_dims` 的对比结论） | 换 shim 会改建窗与消息时序（F2 含 `XSetInputFocus`）⇒ 帧/像素可能整体位移 | 只比较**同一七元组内**的读数；跨七元组一律重取 |
| 我在 `/tmp/t1x-shim` 上的 `[WIN_DIAG]`/`LASTERR` 读数（sha16 `ee0b5c47a41e9c83`） | 私有目录、非权威件 | 仅作"源码可编译 + 管线可用"旁证；权威件装好**重取一次** |
| T3 刚冻结的七元组基线 | 同上 | 换件那刻起作废 ⇒ **等 F2 + 补丁 P 都落地后重冻一次** |
| **补丁 P 落波后：七元组的 `pc:` / `pf:` 位也会变** | 补丁 P 改 `build/WindowsBase.Linux/HwndWrapper.Linux.cs`（编进 WindowsBase→PC/PF 链） | ⇒ **两件都落地后一次性重冻**，避免一轮内冻两遍 |
| `hbtextline_shim(stale:…)` 位 | 与本轮无关（T1d 车道） | 不动；但会影响基线可比性 ⇒ 重冻时以当时 `stale=no` 为准 |

**重冻建议顺序（主控执行）**：① 装 shim（F2）→ ② 起 PC 波（补丁 P 等）→ ③ `verify-all.sh` 全绿 →
④ `WPTD_BASELINE_OUT=<新文件> REPEAT=3 run-wpftextdemo.sh 60 --tier both` 三连 →
⑤ 用 ④ 的机读行整体替换 `ACCEPTANCE-BASELINE.md`，文件头写
`# RE-FROZEN after F2(win32shim) + patch P(pc) at <date>`。

---

# 附 D：**sha 审计（现场重读）+ 教训（含一次"读早了"的自我更正）**

## D.1 主控指出的错误（已改）

附 B 的 sha 闸门被写成"仍是 `4c023937421db45f` ⇒ 标 `pre-F2`"——**`4c023937421db45f` 是早得多的一代**
（pre-input-work），我却把它当成了"当前值"。已在四处改正：§1.3 的指纹表行、§4 的"必须重跑"行、
**§B.7 牙①**（改成"现场重读 + 代次表"）、**附 C**（把"七元组 `win32shim:` 位"拆成**装前/装后两个不同的位**）。

## D.2 现场重读（**逐条实测；并更正 D.2 初版的一条错误结论**）

**① 更正：D.2 初版那条"此刻 bin 与 3 份副本不一致"是错的 —— 是我"读早了"，不是树的状态。**
先把初版那次读数**按取值窗口**标出来（它的命令是
`find . -name 'libwpfwin32.so' … | while read f; do printf '%s %s B %s\n' "$(sha256sum $f|cut -c1-16)" …`，
**当时没有把 `date` 打进输出**，这是缺陷本身）：

```
初版读数（可证明落在 16:10:02 < t < 16:10:06 这 4 秒窗口内 —— 见下"时刻反推"）
6213489cb202fd55  269,040 B  build/MilBridge/tests/ContractProbe/bin/Release/libwpfwin32.so
6213489cb202fd55  269,040 B  build/MilBridge/tests/CompositeFontProbe/bin/Release/libwpfwin32.so
6213489cb202fd55  269,040 B  build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/libwpfwin32.so
e1691fd8440da926  269,616 B  src/WpfGfx.Linux.Native/bin/libwpfwin32.so
```
**时刻反推（两条硬事实夹逼）**：bin 的 mtime = **16:10:02**（我读到的是**新** sha ⇒ 我的读 **晚于** 16:10:02）；
三份副本的 mtime = **16:10:06**（我读到的是**旧** sha ⇒ 我的读 **早于** 16:10:06）。
⇒ 我那一枪正好打在"主控重编完 bin（16:10:02）"与"主控同步完副本（16:10:06）"之间的 **≤4 秒**里。
**⇒ 定性：这是仪器的取值时刻缺陷（单次快照被当成"此刻状态"写进报告），不是树的不一致。**
⇒ 该结论在初版里的用途（为 §B.7 牙① 辩护）**不成立**，牙① 的真正理由只剩下一条，仍然充分：
**副本会随构建/发布被刷新**（本次 16:10:06 就是一次），所以一轮开跑前必须**四份同时重读**。

**② 16:12:30 现场重读（命令与输出逐字，含时刻）**

```bash
$ date '+%F %H:%M:%S'
2026-09-13 16:12:30
$ find . -name 'libwpfwin32.so' -not -path './upstream/*' | sort | while read f; do \
    printf '%s %s B %s %s\n' "$(sha256sum "$f"|cut -c1-16)" "$(stat -c%s "$f")" \
           "$(date -d @$(stat -c%Y "$f") '+%H:%M:%S')" "$f"; done
e1691fd8440da926 269616 B 16:10:06 ./build/DirectWrite.Linux/SystemFontsProbe/bin/Debug/libwpfwin32.so
e1691fd8440da926 269616 B 16:10:06 ./build/MilBridge/tests/CompositeFontProbe/bin/Release/libwpfwin32.so
e1691fd8440da926 269616 B 16:10:06 ./build/MilBridge/tests/ContractProbe/bin/Release/libwpfwin32.so
e1691fd8440da926 269616 B 16:10:02 ./src/WpfGfx.Linux.Native/bin/libwpfwin32.so
ee0b5c47a41e9c83 269616 B 16:02:41 /tmp/t1x-shim/libwpfwin32.so（我的旁证件，未安装）
```
⇒ **四份权威副本 sha 一致**（`e1691fd8440da926`），与主控的读数**逐字相同**。

**③ 桥产物（顺手核对主控给的 `e0d01832a3efea53`，不是转抄）**
```
e0d01832a3efea53 4937968 B 16:11:04 ./build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so
e0d01832a3efea53 4937968 B 16:11:04 ./build/MilBridge/.artifacts/bin/MilBridge.Linux/release_linux-x64/native/wpfgfx_cor3.so
```
⇒ 与主控给的 `e0d01832a3efea53… / 4,937,968 B（16:11）` **一致**（两处产物同 sha）。

**④ 仍然成立的那条**：**尺寸不能当指纹** —— `/tmp` 旁证件与新 bin **同为 269,616 B**，sha 不同
（`ee0b5c47a41e9c83` vs `e1691fd8440da926`）⇒ 任何"按字节数认件"的做法都是假指纹。

## D.3 教训（**写死进协议与流程**）

1. **跨车道引用 sha 必须现场 `sha256sum` 重读**，不许从别的报告/消息里转抄 —— 本报告已因此错**三次**
   （一次把 `/tmp` 旁证读数与权威件混写；一次把早一代 `4c023937…` 当"当前值"；
   一次是 **D.2 初版把"4 秒窗口内的单次快照"写成"此刻不一致"的结论**）。
2. **读到与别人不一致的 sha ⇒ 先怀疑自己的取值时刻与命令，再怀疑树**：把 `date` 与命令**一起**留在输出里；
   一次读数只能证明"那一瞬"，要写成**结论**必须有**时刻**或**复读**。
3. **协议里不写死任何 sha**：只写"**每轮现场重读** + **多份一致** + **记进轮记录**"。
4. **每个 sha 必须带取值时刻**（"报告建立时"/"现场重读"/"16:12:30"），否则它一定会过期。
5. **代次表**（附 B.7）只用于"认出是哪一代"，**不可当"当前值"引用**。

// WPF-on-Linux · M7b · X11 后端与事件翻译
//
// ── 职责边界 ──────────────────────────────────────────────────────────────
//   本文件是 shim 里**唯一**碰 Xlib 的地方。它负责两件事：
//     1. 把 Win32 的窗口生命周期映射到 X11（建/销/映射/移动/改标题/属性）；
//     2. 把 XEvent 翻译成 MSG（按键、指针、尺寸、曝光、关闭、销毁）。
//   消息**入队**这步不在这里做（在 win32_msg.c），这里只产出 MSG。
//
// ── 线程模型（重要，且是刻意的）──────────────────────────────────────────
//   Xlib 的连接对象不是线程安全的。本 shim 的规则：
//     · 「X 连接所有者线程」= 第一个调用 wpf_x11_ensure() 的线程。窗口创建、
//       XNextEvent、XFlush 只允许发生在它上面。
//     · 其它线程只能走 PostMessage（纯内存队列 + 写 self-pipe），不碰 X。
//   WPF 的一个 UI 线程 + 若干后台线程调用 Dispatcher.BeginInvoke 正是这个形状。
//   如果将来出现多 UI 线程，需要改成每线程一个 X 连接——已登记为限制。
//
// ── 无 X server 时 ────────────────────────────────────────────────────────
//   XOpenDisplay 失败 → wpf_x11_ensure() 返回 0，错误文案存 g_wpf.dpy_error。
//   所有需要 X 的 API 都据此返回明确的失败码（NULL / FALSE / 0），**不伪造**。
//   纯消息泵（PostMessage/GetMessage/SetTimer）在无 X 时仍然可用，这是刻意的：
//   Dispatcher 的队列调度不依赖窗口系统。

#define _GNU_SOURCE
#include "win32_internal.h"

#include <X11/Xatom.h>
#include <X11/Xutil.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

// ── Xlib 的线程安全：两道防线 ─────────────────────────────────────────────
// 【问题】Xlib/xcb 的连接对象**不是**线程安全的。本轮实测踩到（而且在
//   `dotnet test --logger console;verbosity=detailed` 下必现、默认 verbosity 下
//   偶现 —— 典型的数据竞争特征）：
//     [xcb] Unknown sequence number while processing queue
//     [xcb] Most likely this is a multi-threaded client and XInitThreads has not been called
//     dotnet: ../../src/xcb_io.c:278: poll_for_event: Assertion `!xcb_xlib_threads_sequence_lost' failed.
//   → 测试宿主**进程 abort**（不是用例失败）。
//   触发它的是真实的 WPF 行为：`HwndWrapper` 的**终结器**会在终结器线程上走
//   `Dispose` 路径，而 UI 线程同时在泵里调 XPending/XNextEvent；两个线程
//   共用同一个 Display。
//
// 【防线 1：XInitThreads】在 .so 被 dlopen 的那一刻就调用（constructor），
//   保证它早于本模块的任何 Xlib 调用、也早于 XOpenDisplay。XInitThreads 让
//   libX11 内部为每个 Display 加锁，这是 libX11 官方给出的多线程用法。
//   用 constructor 而**不是**放在 wpf_x11_ensure 里：后者可能晚于别的 Xlib
//   调用（例如测试进程先探测过 DISPLAY），而 man page 明确要求 XInitThreads
//   必须"在任何其它 Xlib 函数之前"调用。
//
// 【防线 2：自己的 xlock】即使 XInitThreads 因故没生效（返回 0），
//   本 shim 的所有 Xlib 调用也都串行化：`wpf_x11_ensure` 之后任何触碰 X 的
//   入口（建/销/映射/移动/标题/取属性/XPending/XNextEvent/XFlush）都必须
//   持 xlock。**只保护本 shim 自己的调用**——别的库用自己的连接，互不影响。
//   刻意与 g_wpf.lock 分开：xlock 是"短临界区、只包 Xlib"，g_wpf.lock 是状态锁，
//   两者混用会把"调用托管窗口过程"这段也圈进去（那是必须放锁的）。
static pthread_mutex_t g_xlock = PTHREAD_MUTEX_INITIALIZER;
#define XLOCK()   pthread_mutex_lock(&g_xlock)
#define XUNLOCK() pthread_mutex_unlock(&g_xlock)

// ── [1400 诊断] Xlib 异步错误捕获 ────────────────────────────────────────────
// 【为什么必须有】`XCreateWindow` 等请求是**异步**的：X 协议先返回 void，真正的失败
//   由 X server 以 error event 形式回给客户端的错误处理器。所以建窗返回 0 时，
//   "为什么失败"（BadValue/BadMatch/BadWindow… + 请求号）**只存在于 X 错误处理器里**，
//   不进 errno/LastError ⇒ 只报 1400 等于什么都没说（T3 的 `Win32Exception(1400)` 现场）。
// 【约束】该处理器由**持有 XLOCK 的线程**在 Xlib 调用内部同步回调 ⇒ 这里**不加任何锁**
//   （`g_xlock` 非递归，重入即死锁；`g_wpf.x_error` 只在诊断路径写，竞争可接受且只影响文案）。
static int wpf_x_error_handler(Display *d, XErrorEvent *e)
{
    char text[128] = { 0 };
    (void)d;
    if (e) {
        XGetErrorText(d, e->error_code, text, (int)sizeof(text));
        snprintf(g_wpf.x_error, sizeof(g_wpf.x_error),
                 "error_code=%u(%s) request_code=%u minor_code=%u resource=0x%lx",
                 (unsigned)e->error_code, text[0] ? text : "?",
                 (unsigned)e->request_code, (unsigned)e->minor_code,
                 (unsigned long)e->resourceid);
    }
    return 0;   // 不终止进程（Xlib 会继续把错误当已处理）
}

static pthread_once_t g_xerr_once = PTHREAD_ONCE_INIT;
static void wpf_x_install_handler_once(void) { (void)XSetErrorHandler(wpf_x_error_handler); }

void wpf_x11_install_error_handler(void) { pthread_once(&g_xerr_once, wpf_x_install_handler_once); }

// [1400 诊断 · 牙齿] 不依赖 WPF 应用的**真 X 错误**触发路径：对一个坏 window id 发请求。
// 用法：`WPF_LINUX_WIN_DIAG=xerr`（进程起来第一次调 shim 即触发，随后 [WIN_DIAG] 会打出
//   捕获到的 `error_code/request_code/...`）。用途：证明"X 错误 → g_wpf.x_error → [WIN_DIAG]"
//   这条管线**真的通**，而不是只写了代码；把报告里的格式串改坏 ⇒ 这条必红。
void wpf_x11_diag_selftest_xerr(void)
{
    if (!wpf_x11_ensure()) {
        wpf_win_diag_report("selftest(xerr)：X 不可用 ⇒ 退化为 dpy_error 变体", "HwndWrapper[selftest]", (HWND)0, 1400);
        return;
    }
    XLOCK();
    XWindowAttributes attrs;
    (void)XGetWindowAttributes(g_wpf.dpy, (Window)0xDEADBEEF, &attrs);   // 必然 BadWindow
    XSync(g_wpf.dpy, False);                                            // 逼出异步错误 ⇒ 错误处理器写 x_error
    XUNLOCK();
    wpf_win_diag_report("selftest(xerr)：对坏 window id(0xdeadbeef) 发请求", "HwndWrapper[selftest]", (HWND)0, 1400);
}

__attribute__((constructor))
static void wpf_x11_init_threads(void)
{
    // 返回值 0 = 已经有人先调过/失败；两种情况都不影响防线 2。
    (void)XInitThreads();
    // [1400 诊断] 装错误处理器（在**任何** Xlib 调用之前；幂等）
    wpf_x11_install_error_handler();

    // ── 【防线 3：X 连接**只在加载期建一次**】（M7c 收尾轮补）──────────────────
    // 为什么必须提前到这里：`XOpenDisplay` 内部会 dlopen 一堆东西（locale/IM 模块、
    // xcb 相关），而 **glibc 的 dlopen 在多线程下不安全**。实测（本轮）：
    //   · 一旦 `GetDeviceCaps`/`GetDpiFor*` 也开始按需连 X，`dotnet test` 的测试宿主
    //     就会在**任意线程**上触发 XOpenDisplay，与 CoreCLR 自己的 dlopen 并发 ⇒
    //     `Inconsistency detected by ld.so: dl-open.c: 224 _dl_find_dso_for_object:
    //      Assertion 'ns == l->l_ns' failed!` ⇒ **宿主进程崩溃**（实测 6/6）。
    //   · 把这次唯一的 XOpenDisplay 挪到 .so 的构造期（此时应用线程还没起来），
    //     之后所有线程只是**复用**这条连接（受 xlock 保护）⇒ 不再有并发 dlopen。
    // 无 X 的环境**不受影响**：失败会被记进 g_wpf.x_failed，后续 wpf_x11_ensure()
    // 直接返回 0，shim 退回"纯消息泵"行为（M7b 的"无 X 优雅跳过"契约不变）。
    (void)wpf_x11_ensure();
}

static Atom a_wm_protocols = 0;
static Atom a_wm_delete_window = 0;
static Atom a_net_wm_name = 0;
static Atom a_utf8_string = 0;
// ── 【波 58 · 屏幕适配】EWMH 的四个原子 ────────────────────────────────────────
//   _NET_WORKAREA：WM 报的"可用区"（有面板/任务栏时 < 屏幕）——顶层窗尺寸钳制的上限来源。
//   其余三个是随本次一起补的标准提示（见 wpf_x11_apply_wm_hints 的注释）。
static Atom a_net_workarea = 0;
static Atom a_net_wm_window_type = 0;
static Atom a_net_wm_window_type_normal = 0;
static Atom a_net_wm_pid = 0;
// ── 【波 59 · 窗口状态 / 自绘 chrome】新增的原子 ───────────────────────────────
//   `_NET_WM_STATE(_MAXIMIZED_*)`：最大化状态的**权威来源**（WM 自己也会读写它）；
//   `_NET_WM_MOVERESIZE`：把"这一次指针拖动"交给 WM —— 客户端自绘标题栏/边框的唯一正路
//     （见 `wpf_x11_moveresize` 的注释）；`_NET_SUPPORTING_WM_CHECK`：判断"有没有 EWMH WM"；
//   `_MOTIF_WM_HINTS`：**加不加窗框装饰**（见 `wpf_x11_set_decorations`）。
static Atom a_net_wm_state = 0;
static Atom a_net_wm_state_maximized_horz = 0;
static Atom a_net_wm_state_maximized_vert = 0;
static Atom a_net_wm_moveresize = 0;
static Atom a_net_moveresize_window = 0;
static Atom a_net_supporting_wm_check = 0;
static Atom a_motif_wm_hints = 0;

// ── 连接 ───────────────────────────────────────────────────────────────────
int wpf_x11_ensure(void)
{
    wpf_global_init();
    wpf_lock();
    if (g_wpf.dpy) { pthread_mutex_unlock(&g_wpf.lock); return 1; }
    if (g_wpf.x_failed) { pthread_mutex_unlock(&g_wpf.lock); return 0; }

    const char *name = getenv("WPF_LINUX_DISPLAY");
    if (!name || !*name) name = getenv("DISPLAY");
    XLOCK();
    Display *d = XOpenDisplay(name);
    XUNLOCK();
    if (!d) {
        snprintf(g_wpf.dpy_error, sizeof(g_wpf.dpy_error),
                 "XOpenDisplay(\"%s\") 失败：无 X server 或 DISPLAY 不可用。"
                 "窗口相关用例应被跳过（无 DISPLAY 的机器上属预期行为）。",
                 name ? name : "(null)");
        g_wpf.x_failed = 1;
        pthread_mutex_unlock(&g_wpf.lock);
        return 0;
    }
    g_wpf.dpy = d;
    g_wpf.screen = DefaultScreen(d);
    g_wpf.root = RootWindow(d, g_wpf.screen);
    g_wpf.xfd = ConnectionNumber(d);
    g_wpf.x_failed = 0;

    XLOCK();
    a_wm_protocols = XInternAtom(d, "WM_PROTOCOLS", False);
    a_wm_delete_window = XInternAtom(d, "WM_DELETE_WINDOW", False);
    a_net_wm_name = XInternAtom(d, "_NET_WM_NAME", False);
    a_utf8_string = XInternAtom(d, "UTF8_STRING", False);
    // 【波 58】工作区与标准提示用的原子（都在同一次 ensure 里 intern，之后每窗口复用）
    a_net_workarea = XInternAtom(d, "_NET_WORKAREA", False);
    a_net_wm_window_type = XInternAtom(d, "_NET_WM_WINDOW_TYPE", False);
    a_net_wm_window_type_normal = XInternAtom(d, "_NET_WM_WINDOW_TYPE_NORMAL", False);
    a_net_wm_pid = XInternAtom(d, "_NET_WM_PID", False);
    // 【波 59】窗口状态 / 自绘 chrome 的原子
    a_net_wm_state = XInternAtom(d, "_NET_WM_STATE", False);
    a_net_wm_state_maximized_horz = XInternAtom(d, "_NET_WM_STATE_MAXIMIZED_HORZ", False);
    a_net_wm_state_maximized_vert = XInternAtom(d, "_NET_WM_STATE_MAXIMIZED_VERT", False);
    a_net_wm_moveresize = XInternAtom(d, "_NET_WM_MOVERESIZE", False);   // 支持列表里有，但实测无效（见 wpf_x11_moveresize_window 注释）
    a_net_moveresize_window = XInternAtom(d, "_NET_MOVERESIZE_WINDOW", False);
    a_net_supporting_wm_check = XInternAtom(d, "_NET_SUPPORTING_WM_CHECK", False);
    a_motif_wm_hints = XInternAtom(d, "_MOTIF_WM_HINTS", False);
    XUNLOCK();

    pthread_mutex_unlock(&g_wpf.lock);
    return 1;
}

void wpf_x11_flush(void)
{
    if (!g_wpf.dpy) return;
    XLOCK(); XFlush(g_wpf.dpy); XUNLOCK();
}

int wpf_x11_pending(void)
{
    if (!g_wpf.dpy) return 0;
    XLOCK();
    int n = XPending(g_wpf.dpy);
    XUNLOCK();
    return n;
}

// ── 键盘专项诊断（`WPF_LINUX_KEY_DIAG=1`，**缺省关、只读、有界**）─────────────────
// 【为什么需要它（2026-09-12，T3 的 textbox 现场）】
//   应用里 `[msg]` 只看到 1 条 `WM_SETFOCUS`、**0 条 WM_KEYDOWN / 0 条 WM_CHAR**；
//   而同一手法（`xdotool key --window <id> a`，XSendEvent）在单元用例里能打出两条。
//   ⇒ 必须把"X 事件有没有进到本进程 / 有没有被翻译 / 翻译后落到哪个窗口"变成**读数**，
//     否则只能在"注入 id 错 / 我们丢了事件 / 时机"之间猜。三行读数即那把尺子：
//       · `XEV`  行：泵里**收到的每一个** Key/Focus 事件（含 `send_event` 合成位、window id）
//       · `KEY`  行：翻译结果（keysym/keycode/state/vk/产了哪几条消息）
//       · `DROP` 行：**收到但没产出**的原因（窗口不在我们表里 / 组合键不产字符 / 释放…）
#define WPF_KEY_DIAG_MAX 400
static int wpf_key_diag_on(void)
{
    static int on = -1;
    if (on < 0) {
        const char *e = getenv("WPF_LINUX_KEY_DIAG");
        on = (e && *e && *e != '0') ? 1 : 0;
    }
    return on;
}
static void wpf_key_diag(const char *fmt, ...)
{
    if (!wpf_key_diag_on()) return;
    static int s_lines = 0;
    if (s_lines >= WPF_KEY_DIAG_MAX) return;
    s_lines++;
    va_list ap;
    va_start(ap, fmt);
    fputs("[KEY_DIAG] ", stderr);
    vfprintf(stderr, fmt, ap);
    fputc('\n', stderr);
    va_end(ap);
    fflush(stderr);
}
static const char *wpf_xevent_name(int type)
{
    switch (type) {
    case KeyPress:        return "KeyPress";
    case KeyRelease:      return "KeyRelease";
    case FocusIn:         return "FocusIn";
    case FocusOut:        return "FocusOut";
    case ButtonPress:     return "ButtonPress";
    case ButtonRelease:   return "ButtonRelease";
    case MotionNotify:    return "MotionNotify";
    case Expose:          return "Expose";
    case ConfigureNotify: return "ConfigureNotify";
    case MapNotify:       return "MapNotify";
    case UnmapNotify:     return "UnmapNotify";
    default:              return "other";
    }
}

// 把 X 输入焦点真的设到该窗口上（补丁 F2）。
// 【为什么必须补】Win32 的 `SetFocus` 语义包含"系统键盘输入焦点转到该窗口"；本 shim 之前
//   只改内部 `g_focus_window` 并派发 `WM_SETFOCUS`，**从没调过 `XSetInputFocus`**
//   ⇒ X server 侧焦点仍在别处（Xvfb 无 WM 时通常是 PointerRoot）。后果：
//   `xdotool key --window`（XSendEvent，不依赖焦点）与真键盘（XTEST，依赖焦点）两条路
//   只有前一条可能到我们；而 `FocusIn`（`WM_SETFOCUS` 的来源之一）只在"指针进入且焦点为
//   PointerRoot"时偶然产生 ⇒ 行为随鼠标位置漂移，不稳定。
// 【波 46 · D-G50 产品修复】X 对 `XSetInputFocus` 的**回送**必须按"自己请求的"识别并吃掉。
//   机制（读数见 KNOWN-DEFECTS `D-G50`）：`SetFocus()`（win32_core.c）**已经同步**派发过
//   WM_KILLFOCUS/WM_SETFOCUS，随后 X 才把 `XSetInputFocus` 的生效结果作为 FocusIn/FocusOut 回送；
//   若逐条再翻译一次，主窗口会收到**第二条 WM_SETFOCUS**。此刻 WPF 的键盘焦点已在**弹窗**
//   （另一个 HwndSource）里的元素上，而 `GetFocus()` 仍返回本窗口 ⇒ 撞上
//   `HwndKeyboardInputProvider.OnSetFocus`（与上游逐字相同）里的
//   `if (focus == thisSource.Handle) { ... Keyboard.ClearFocus(); }` ⇒ 焦点被清成 null ⇒
//   `ComboBox.OnIsKeyboardFocusWithinChanged` 的 `currentFocus == null` 分支 ⇒ `Close()`
//   ⇒ 现象"组合框下拉弹出几毫秒后被关掉"（HandyControl 与仓内 `nativecombo` 块同形）。
//   ⇒ 判据：**我们自己刚请求过的那个窗口，其回送一律吃掉**；回送到达前的中间态事件同属一批回送，
//      同样吃掉。**用户侧真实焦点变化**（没有未决请求时到达的事件）照旧逐条翻译 ⇒
//      真键盘注入与"焦点为 PointerRoot、指针进入窗口"那条路不变。
// 【波 46 · D-G50】物理按键的"已按下"位图：X 在**抓取(grab)激活**时会重放当前按住的按键，
//   同一个物理按下会再来一条 ButtonPress。Win32 语义下一次物理按下只有一条 WM_LBUTTONDOWN
//   ⇒ 重放必须丢弃，否则"按下即翻转"的控件会被翻两次（HandyControl 组合框下拉开了立刻又关）。

static HWND g_x_focus_want = NULL;
static int  g_x_focus_want_pending = 0;

static void wpf_x11_focus_note_request(HWND hwnd)
{
    wpf_lock(); g_x_focus_want = hwnd; g_x_focus_want_pending = 1; pthread_mutex_unlock(&g_wpf.lock);
}

// 返回 1 = 本条焦点事件属于我们自己请求的回送（调用方吃掉、不翻译）
static int wpf_x11_focus_is_echo(HWND h, int is_focus_in)
{
    int echo = 0;
    wpf_lock();
    if (g_x_focus_want_pending) {
        if (is_focus_in && h == g_x_focus_want) { g_x_focus_want_pending = 0; g_x_focus_want = NULL; }
        echo = 1;
    }
    pthread_mutex_unlock(&g_wpf.lock);
    return echo;
}

void wpf_x11_set_input_focus(HWND hwnd)
{
    if (!hwnd) return;
    if (!wpf_x11_ensure()) { wpf_key_diag("SETFOCUS 跳过：X 不可用"); return; }
    XLOCK();
    XSetInputFocus(g_wpf.dpy, (Window)(uintptr_t)hwnd, RevertToParent, CurrentTime);
    XFlush(g_wpf.dpy);
    XUNLOCK();
    wpf_x11_focus_note_request(hwnd);
    wpf_key_diag("SETFOCUS → XSetInputFocus(window=0x%llx)",
                 (unsigned long long)(uintptr_t)hwnd);
}

// ── 窗口创建 ───────────────────────────────────────────────────────────────
// 事件掩码：把 WPF 输入栈真正会消费的事件全选上，多选不产生额外消息
// （翻译层只认下面 handle_event 里列出的类型）。
#define WPF_EVENT_MASK (ExposureMask | StructureNotifyMask | KeyPressMask |        \
                        KeyReleaseMask | ButtonPressMask | ButtonReleaseMask |    \
                        PointerMotionMask | EnterWindowMask | LeaveWindowMask |   \
                        FocusChangeMask | PropertyChangeMask | VisibilityChangeMask)

// 【波 46 仪器】建窗/映射两条腿的事件日志：判"弹窗到底有没有建、有没有 map"。
//   env `WPF_LINUX_CREATE_DIAG=1`；每进程 ≤ 40 行；**只打印**，不改任何行为。
//   （为什么必须有：用低频轮询 + `mapped` 终值判"是否发生过"会读错 —— 曾据此误判"弹窗不建窗"。）
static int wpf_create_diag_on(void)
{
    static int cached = -1;
    if (cached < 0) { const char *e = getenv("WPF_LINUX_CREATE_DIAG"); cached = (e && *e && *e != '0') ? 1 : 0; }
    return cached;
}
static void wpf_create_diag(const char *where, wpf_window *w, uint64_t xid)
{
    static int n = 0;
    if (!wpf_create_diag_on() || n++ >= 40) return;
    fprintf(stderr, "[CREATE_DIAG] %s xid=0x%llx atom=%u style=0x%llx ex=0x%llx xywh=%d,%d,%dx%d msgonly=%d mapped=%d\n",
            where, (unsigned long long)xid, (unsigned)(w ? w->class_atom : 0),
            (unsigned long long)(w ? w->style : 0), (unsigned long long)(w ? w->exstyle : 0),
            w ? w->x : -1, w ? w->y : -1, w ? w->width : -1, w ? w->height : -1,
            (w && w->is_message_only) ? 1 : 0, (w && w->mapped) ? 1 : 0);
    fflush(stderr);
}

// 【波 59 · B】非客户区"拖动/缩放"的状态（翻译层单线程，无需加锁）
//   `g_nc_*`：当前这次 NC 按下（窗口、命中码、按下点、按下时的客户区矩形、是否已真的开始动）
//   `g_nc_click_*`：上一次**完整的标题栏点击**（自己判双击用；Win32 的双击判定同样是
//   "同区域、间隔 ≤ 系统双击时间、位移 ≤ 4px"）
static HWND     g_nc_hwnd = NULL;
static int      g_nc_ht = HTCLIENT;
static int      g_nc_started = 0;
static int      g_nc_px = 0, g_nc_py = 0;
static int      g_nc_x = 0, g_nc_y = 0, g_nc_w = 0, g_nc_h = 0;
static uint64_t g_nc_click_ms = 0;
static int      g_nc_click_x = 0, g_nc_click_y = 0;

// 【波 59 仪器】非客户区命中/拖动那条腿的事件日志。env `WPF_LINUX_KEY_DIAG=1` 或
//   `WPF_LINUX_CREATE_DIAG=1`（两者都是"输入/窗口"侧的既有开关，复用免得再加旋钮）；
//   每进程 ≤ 60 行；**只打印**，不改行为。判据"拖自绘标题栏 ⇒ 原点变化"必须能区分
//   "没命中 caption"与"命中了但 WM 没搬窗"，没有这行读数就只能猜。
static void wpf_nc_diag(const char *fmt, ...)
{
    static int cached = -1, n = 0;
    if (cached < 0) {
        const char *a = getenv("WPF_LINUX_KEY_DIAG");
        const char *b = getenv("WPF_LINUX_CREATE_DIAG");
        int on = ((a && *a && *a != '0') || (b && *b && *b != '0')) ? 1 : 0;
        cached = on;
    }
    if (!cached || n++ >= 60) return;
    va_list ap;
    va_start(ap, fmt);
    fputs("[NC_DIAG] ", stderr);
    vfprintf(stderr, fmt, ap);
    fputc('\n', stderr);
    va_end(ap);
    fflush(stderr);
}

uint64_t wpf_x11_create_window(wpf_window *w, const char *title)
{
    if (!wpf_x11_ensure()) return 0;
    Display *d = g_wpf.dpy;

    int width = w->width > 0 ? w->width : 1;
    int height = w->height > 0 ? w->height : 1;
    unsigned long black = BlackPixel(d, g_wpf.screen);
    unsigned long white = WhitePixel(d, g_wpf.screen);

    XLOCK();
    Window xid = XCreateSimpleWindow(d, g_wpf.root,
                                     w->x, w->y,
                                     (unsigned int)width, (unsigned int)height,
                                     0, black, white);
    wpf_create_diag("CREATE", w, (uint64_t)xid);
    if (!xid) return 0;

    // XStoreName 写的是 WM_NAME/STRING（latin-1），xwininfo/xdotool 读的就是它；
    // _NET_WM_NAME/UTF8_STRING 是给现代工具链读非 ASCII 标题用的。两个都写。
    if (title && *title) XStoreName(d, xid, title);
    if (title && *title) {
        XChangeProperty(d, xid, a_net_wm_name, a_utf8_string, 8, PropModeReplace,
                        (const unsigned char *)title, (int)strlen(title));
    }

    XSelectInput(d, xid, WPF_EVENT_MASK);

    // WM_DELETE_WINDOW：没有它，点关闭时窗口管理器直接 XKillClient，
    // 上层收不到任何通知（M1 的 X11Window 出于同样理由注册了它）。
    if (a_wm_protocols && a_wm_delete_window) {
        Atom proto[1];
        proto[0] = a_wm_delete_window;
        XSetWMProtocols(d, xid, proto, 1);
    }

    XFlush(d);
    XUNLOCK();
    return (uint64_t)xid;
}

void wpf_x11_destroy_window(HWND hwnd)
{
    if (!g_wpf.dpy || !hwnd) return;
    wpf_create_diag("DESTROY", wpf_window_find(hwnd), (uint64_t)(uintptr_t)hwnd);
    // ⚠️ 这个函数**会从终结器线程被调到**（HwndWrapper 的终结器路径），
    //    所以它是 xlock 存在的主要理由之一。
    XLOCK();
    XDestroyWindow(g_wpf.dpy, (Window)(uintptr_t)hwnd);
    XFlush(g_wpf.dpy);
    XUNLOCK();
}

void wpf_x11_map(HWND hwnd, int map)
{
    if (!g_wpf.dpy || !hwnd) return;
    wpf_create_diag(map ? "MAP" : "UNMAP", wpf_window_find(hwnd), (uint64_t)(uintptr_t)hwnd);
    // ── 【波 59 · C】"自绘 chrome"的窗口在**第一次 map 之前**声明"不要装饰" ─────────
    //   为什么必须在 map 之前：装饰是 WM 在 map 那一刻决定并"接管"的；虽然实测 xfwm4
    //   也能在 map 之后按 PropertyNotify 改（见 `wpf_x11_set_decorations` 的注释），
    //   但"map 前就写对"能避免"先出现一层窗框再消失"的闪烁，也不依赖后改这条路。
    //   判定见 `wpf_core_custom_chrome`（应用自报：`SetWindowPos(SWP_FRAMECHANGED)`）。
    if (map && wpf_core_custom_chrome(hwnd)) wpf_x11_set_decorations(hwnd, 0);
    XLOCK();
    if (map) XMapWindow(g_wpf.dpy, (Window)(uintptr_t)hwnd);
    else     XUnmapWindow(g_wpf.dpy, (Window)(uintptr_t)hwnd);
    XFlush(g_wpf.dpy);
    XUNLOCK();

    // ── 补丁 F2 第二处：**顶层可见窗口被 map 时把 X 输入焦点也给它** ──────────────
    //   为什么需要：Win32 语义里"窗口显示/激活"就包含键盘输入焦点（WPF 默认
    //   ShowActivated=true）；本 shim 之前只改内部 `g_focus_window`，X server 侧焦点
    //   一直在 PointerRoot ⇒ 只有"指针恰好进入窗口"时才偶然收到 FocusIn（= WM_SETFOCUS），
    //   真键盘（XTEST）则永远到不了我们。message-only 窗口不设（它不可见、不接收输入）。
    if (map) {
        wpf_lock();
        wpf_window *w = wpf_window_find(hwnd);
        int topmost = (w != NULL) && !(w->is_message_only);
        pthread_mutex_unlock(&g_wpf.lock);
        if (topmost) wpf_x11_set_input_focus(hwnd);
    }
}

void wpf_x11_move_resize(HWND hwnd, int x, int y, int w, int h)
{
    if (!g_wpf.dpy || !hwnd) return;
    Window win = (Window)(uintptr_t)hwnd;
    XLOCK();
    if (w > 0 && h > 0) XMoveResizeWindow(g_wpf.dpy, win, x, y, (unsigned)w, (unsigned)h);
    else                XMoveWindow(g_wpf.dpy, win, x, y);
    XFlush(g_wpf.dpy);
    XUNLOCK();
}

void wpf_x11_set_title(HWND hwnd, const char *title)
{
    if (!g_wpf.dpy || !hwnd) return;
    Window win = (Window)(uintptr_t)hwnd;
    const char *t = title ? title : "";
    XLOCK();
    XStoreName(g_wpf.dpy, win, t);
    XChangeProperty(g_wpf.dpy, win, a_net_wm_name, a_utf8_string, 8, PropModeReplace,
                    (const unsigned char *)t, (int)strlen(t));
    XFlush(g_wpf.dpy);
    XUNLOCK();
}

void wpf_x11_query_title(HWND hwnd, char *buf, size_t cap)
{
    buf[0] = 0;
    if (!g_wpf.dpy || !hwnd) return;
    char *name = NULL;
    XLOCK();
    if (XFetchName(g_wpf.dpy, (Window)(uintptr_t)hwnd, &name) && name) {
        snprintf(buf, cap, "%s", name);
        XFree(name);
    }
    XUNLOCK();
}

void wpf_x11_query_geometry(HWND hwnd, int *x, int *y, int *w, int *h, int *mapped)
{
    if (x) *x = 0;
    if (y) *y = 0;
    if (w) *w = 0;
    if (h) *h = 0;
    if (mapped) *mapped = 0;
    if (!g_wpf.dpy || !hwnd) return;
    XWindowAttributes at;
    XLOCK();
    int ok = XGetWindowAttributes(g_wpf.dpy, (Window)(uintptr_t)hwnd, &at);
    XUNLOCK();
    if (!ok) return;
    // XGetWindowAttributes 的 x/y 是相对父窗口的（我们是 root 的子窗口）。
    if (x) *x = at.x;
    if (y) *y = at.y;
    if (w) *w = at.width;
    if (h) *h = at.height;
    if (mapped) *mapped = (at.map_state == IsViewable);
}

// ── 事件翻译 ───────────────────────────────────────────────────────────────
// keysym → Win32 VK。只覆盖 WPF 输入栈实际会区分的那批：ASCII 可见字符、
// 数字、功能键、方向键、编辑键、修饰键。未覆盖的 keysym 落 0（明确的“不认识”），
// 上层 HwndKeyboardInputProvider 对 VK=0 会走「不产生 System.Windows.Input.Key」
// 的分支——这是**可见的降级**，不伪造一个假按键。
// ── [D-K1] 按键状态落表（Win32 语义：bit7=按下、bit0=锁定态）────────────────────
// 【为什么在这里】X11 把修饰键状态放在**每个事件的 `state` 掩码**里（`ev.xkey.state`），
//   而托管侧是**事后**用 `GetKeyState(VK_SHIFT/VK_CONTROL/VK_MENU)` 问的（修法前那个函数恒返 0）。
//   ⇒ 必须由翻译层把"此刻哪些修饰键按下"落成一张表，`GetKeyState` 才有东西可读。
// 【同步策略（双路）】
//   ① `wpf_keystate_sync_modifiers()`：用事件自带的 `state` 掩码**覆盖式**同步 Ctrl/Shift/Alt/Lock/Win
//      —— 它天然免疫"漏掉某个 KeyPress/KeyRelease"（例如窗口获得焦点前就按住的键）。
//   ② `wpf_keystate_note_key()`：按 VK 记"这个键按下/抬起"，并处理锁定键的 toggle 位。
// 【已知简化（如实登记）】X11 mask 分不出左右（`ControlMask` 同时覆盖 L/R）⇒ 只落**通用 VK**
//   （`VK_SHIFT/VK_CONTROL/VK_MENU`，即 WPF 实际查询的那三个）；左右专有 VK（0xA0..0xA5）暂不区分。
#define WPF_VK_SHIFT     0x10
#define WPF_VK_CONTROL   0x11
#define WPF_VK_MENU      0x12
#define WPF_VK_CAPITAL   0x14
#define WPF_VK_LWIN      0x5B
#define WPF_VK_NUMLOCK   0x90

// 【波 19 的坑（实测，2026-09-14）】`keysym_to_vk()` 对修饰键返回的是**左右专有 VK**
//   （`XK_Control_L → 0xA2`、`Shift_L → 0xA0`、`Alt_L/Menu → 0xA4`、`Super_L → 0x5B`），
//   而 WPF 查的是**通用 VK**（`VK_SHIFT 0x10` / `VK_CONTROL 0x11` / `VK_MENU 0x12`）
//   ⇒ 只记专有位 = 通用位永远为 0（波 19 的读数：**按住时 0x0000、松开后 0x8000**，完全反相）。
//   ⇒ 必须**两侧一起记**。
static uint32_t wpf_vk_generic(uint32_t vk);   // 前置声明（定义在其后）

// [D-K1 · 波 20] 把"这个事件时刻"的修饰键算成一个 4 位掩码（1=Shift 2=Ctrl 4=Alt 8=Win）。
// 【为什么要逐消息算】实测（波 19/20）：一次 `xdotool key ctrl+a` 的 4 个 X 事件
//   （Ctrl↓、a↓、a↑、Ctrl↑）会在**同一次泵**里被整批抽干，而消息是**之后**才逐条派发的
//   ⇒ 派发时"实时表"早已被后面的 Ctrl↑ 清掉（这正是"按住读 0、松开读 0x8000"之外的第二个坑：
//   API 单独查是对的，但在**派发期**查就错了）。⇒ 必须把"事件时刻的状态"**随消息带走**。
// 【语义修正】X 的 `state` 是"事件处理前"的掩码：修饰键自己的 KeyPress 上不含自身、KeyRelease 上可能仍是旧值
//   ⇒ 这里按 `vk` 与 `is_up` 对**自身**那一位做一次修正（按下=置、抬起=清）。
uint32_t wpf_keystate_event_mods(uint32_t x_state, uint32_t vk, int is_up)
{
    uint32_t m = 0;
    if (x_state & ShiftMask)   m |= 0x1;
    if (x_state & ControlMask) m |= 0x2;
    if (x_state & Mod1Mask)    m |= 0x4;
    if (x_state & Mod4Mask)    m |= 0x8;
    uint32_t bit = 0;
    switch (wpf_vk_generic(vk)) {
    case WPF_VK_SHIFT:   bit = 0x1; break;
    case WPF_VK_CONTROL: bit = 0x2; break;
    case WPF_VK_MENU:    bit = 0x4; break;
    case WPF_VK_LWIN:    bit = 0x8; break;
    default: break;
    }
    if (bit) { if (is_up) m &= ~bit; else m |= bit; }
    return m;
}

static uint32_t wpf_vk_generic(uint32_t vk)
{
    switch (vk) {
    case 0xA0: case 0xA1: return WPF_VK_SHIFT;     // L/R Shift
    case 0xA2: case 0xA3: return WPF_VK_CONTROL;   // L/R Control
    case 0xA4: case 0xA5: return WPF_VK_MENU;      // Alt / Menu（XK_Menu 也映射到 0xA4）
    default:   return vk;
    }
}

void wpf_keystate_note_key(uint32_t vk, int is_up)
{
    if (vk == 0 || vk > 0xFF) return;
    wpf_lock();
    if (!is_up && (vk == WPF_VK_CAPITAL || vk == WPF_VK_NUMLOCK))
        g_wpf.key_state[vk] ^= 0x01;                 // 低位：锁定态在**按下沿**翻转（Win32 同义）
    // 专有位与通用位一起更新（通用位才是 WPF 读的那个）
    uint32_t g = wpf_vk_generic(vk);
    if (is_up) { g_wpf.key_state[vk] &= (uint8_t)~0x80; g_wpf.key_state[g] &= (uint8_t)~0x80; }
    else       { g_wpf.key_state[vk] |= 0x80;           g_wpf.key_state[g] |= 0x80; }
    pthread_mutex_unlock(&g_wpf.lock);
}

void wpf_keystate_sync_modifiers(uint32_t x_state)
{
    struct { uint32_t mask; uint32_t vk; } m[] = {
        { ShiftMask,   WPF_VK_SHIFT   },
        { ControlMask, WPF_VK_CONTROL },
        { Mod1Mask,    WPF_VK_MENU    },   // Alt
        { Mod4Mask,    WPF_VK_LWIN    },   // Super/Win
        { LockMask,    WPF_VK_CAPITAL },
        { Mod2Mask,    WPF_VK_NUMLOCK },
    };
    wpf_lock();
    for (size_t i = 0; i < sizeof(m) / sizeof(m[0]); ++i) {
        if (x_state & m[i].mask) g_wpf.key_state[m[i].vk] |= 0x80;
        else                     g_wpf.key_state[m[i].vk] &= (uint8_t)~0x80;
    }
    pthread_mutex_unlock(&g_wpf.lock);
}

// ── [D-K1 · 波 24 修法乙] 实时表采纳 **Win32 的消息队列语义** ──────────────────────
// 【为什么需要】波 24 读数（私有件，跨配置）：WPF 的修饰键读取**全部发生在 `DispatchMessageW` 之外**
//   （整批档 368 次 + 按事件泵档 132 次调用，`在dispatch中=是` = **0**）⇒ 它读到的只能是**实时表**；
//   而"整批抽干"会把实时表推到**最后一个 X 事件**的状态（Ctrl 已抬）⇒ `Ctrl+A` 不生效。
//   Win32 文档语义：`GetKeyState` 反映的是**消息队列状态**（与最近取出的消息一致），不是物理瞬时状态
//   ⇒ 取出**按键类消息**时，用这条消息自己带的 `mods` **覆盖**修饰键位。
// 【调用约定】**在持有 `g_wpf.lock` 的区间内**由 `wpf_queue_pop()` 调用（与 `wpf_keystate_note_pop_mods`
//   同一约定）⇒ **本函数不取锁**（`g_wpf.lock` 非递归，重复取会自锁）。
// 【覆盖哪些字节】通用位（WPF 实际查询的 `0x10/0x11/0x12`）**与左右专有位一起**写 —— 与
//   `wpf_keystate_note_key()` 的"两侧一起记"同一理由（波 19 的坑）。X 掩码分不出左右 ⇒
//   左右两位同置/同清，这是**已知简化**（与上方 :412-413 登记的口径一致）。
// 【不动什么】toggle 低位（CapsLock/NumLock）**一律不动**：Win32 里锁定态不是"消息队列的修饰键状态"，
//   它的语义是"按下沿翻转"（见 `wpf_keystate_note_key`），与队列无关。
// 【已知取舍（如实登记）】本 shim 的 `GetAsyncKeyState` 与 `GetKeyState` 同源 ⇒ 它也会跟着队列语义走；
//   真应用连续泵下两者的差别只出现在"消息积压期间"（主控 2026-09-14 裁定走乙）。
void wpf_keystate_apply_queue_mods(uint8_t mods)
{
    struct { uint8_t bit; uint32_t vk_generic, vk_l, vk_r; } m[] = {
        { 0x1, WPF_VK_SHIFT,   0xA0, 0xA1 },
        { 0x2, WPF_VK_CONTROL, 0xA2, 0xA3 },
        { 0x4, WPF_VK_MENU,    0xA4, 0xA5 },
        { 0x8, WPF_VK_LWIN,    0x5B, 0x5C },
    };
    for (size_t i = 0; i < sizeof(m) / sizeof(m[0]); ++i) {
        uint32_t vks[3] = { m[i].vk_generic, m[i].vk_l, m[i].vk_r };
        for (size_t j = 0; j < 3; ++j) {
            if (mods & m[i].bit) g_wpf.key_state[vks[j]] |= 0x80;
            else                 g_wpf.key_state[vks[j]] &= (uint8_t)~0x80;
        }
    }
}

// ── 【波 44 · D-G49】鼠标五键的"此刻是否按下" ────────────────────────────────────────────────
// 【为什么必须有】上游 `Win32MouseDevice.GetButtonStateFromSystem()`
//   （`PresentationCore/System/Windows/Input/Win32MouseDevice.cs:45,61`）判按钮状态的**唯一**来源是
//       `(GetKeyState(VK_LBUTTON) & 0x8000) != 0 ? Pressed : Released`
//   —— 它**不看消息**。而本 shim 的 `key_state[]` **只由键盘翻译层填写** ⇒ 五个鼠标 VK 恒为 0
//   ⇒ WPF 永远认为"左键没按下" ⇒ 上游 `ButtonBase.OnMouseLeftButtonDown` 里
//       `Focus();  if (e.ButtonState == MouseButtonState.Pressed) { CaptureMouse(); SetIsPressed(true); }`
//   判假（`Focus()` 在判据**之前** ⇒ 焦点照样拿到、激活永不发生）⇒ 真实第三方应用
//   （HandyControl demo）里**复选框不勾、下拉不开、滑块不动**，而导航选择/文本框焦点照常工作。
//   实测（波 43 后续）：`AE` 只有"焦点框"那一份；**长按 2.5 s、按住期间移指针都无差别** ⇒ 不是时序问题。
//
// 【取值口径】问 X 的**真实指针按键态**（`XQueryPointer` 的 mask）：与 Win32 `GetKeyState` 同义
//   （物理键态，而非"队列里那条消息"），且天然免疫"按下/抬起被并成一批"。
//   代价 = 一次本地 socket 往返；WPF 每个鼠标事件只问几次。
//   ⚠️ 映射：X 的 `Button2` = 中键、`Button3` = 右键（与 Win32 的 VK 顺序**不同**）；
//      `Button4/5` 在 X 上是滚轮，本处按"最接近的对应"给 `VK_XBUTTON1/2`（如实登记，不假装等义）。
short wpf_x11_mouse_keystate(int vk)
{
    if (!wpf_x11_ensure()) return 0;
    unsigned int mask = 0;
    XLOCK();
    {
        Window r = 0, c = 0;
        int rx = 0, ry = 0, wx = 0, wy = 0;
        unsigned int m = 0;
        if (XQueryPointer(g_wpf.dpy, DefaultRootWindow(g_wpf.dpy), &r, &c, &rx, &ry, &wx, &wy, &m))
            mask = m;
    }
    XUNLOCK();
    unsigned int bit = 0;
    switch (vk) {
        case 0x01: bit = Button1Mask; break;   // VK_LBUTTON
        case 0x02: bit = Button3Mask; break;   // VK_RBUTTON（X 的 Button3）
        case 0x04: bit = Button2Mask; break;   // VK_MBUTTON（X 的 Button2）
        case 0x05: bit = Button4Mask; break;   // VK_XBUTTON1（近似）
        case 0x06: bit = Button5Mask; break;   // VK_XBUTTON2（近似）
        default:   return 0;
    }
    return (short)((mask & bit) ? (short)0x8000 : 0);
}

static uint32_t keysym_to_vk(KeySym ks)
{
    if (ks >= 0x20 && ks <= 0x7E) {
        // ASCII 可见字符：大写字母的 VK 就是它的 ASCII 码；小写归一到大写。
        if (ks >= 'a' && ks <= 'z') return (uint32_t)(ks - 'a' + 'A');
        if (ks >= '0' && ks <= '9') return (uint32_t)ks;
        switch (ks) {
            case ' ':  return 0x20;
            case ';':  return 0xBA;  case '=': return 0xBB;  case ',': return 0xBC;
            case '-':  return 0xBD;  case '.': return 0xBE;  case '/': return 0xBF;
            case '`':  return 0xC0;  case '[': return 0xDB;  case '\\': return 0xDC;
            case ']':  return 0xDD;  case '\'': return 0xDE;
            default:   return (uint32_t)ks;   // A-Z 已在上面的分支处理
        }
    }
    switch (ks) {
        case XK_BackSpace: return 0x08;
        case XK_Tab:       return 0x09;
        case XK_Return:    return 0x0D;
        case XK_Pause:     return 0x13;
        case XK_Caps_Lock: return 0x14;
        case XK_Escape:    return 0x1B;
        case XK_space:     return 0x20;
        case XK_Prior:     return 0x21;   // PageUp
        case XK_Next:      return 0x22;   // PageDown
        case XK_End:       return 0x23;
        case XK_Home:      return 0x24;
        case XK_Left:      return 0x25;
        case XK_Up:        return 0x26;
        case XK_Right:     return 0x27;
        case XK_Down:      return 0x28;
        case XK_Print:     return 0x2C;
        case XK_Insert:    return 0x2D;
        case XK_Delete:    return 0x2E;
        case XK_Help:      return 0x2F;
        case XK_Num_Lock:  return 0x90;
        case XK_Scroll_Lock: return 0x91;
        case XK_Shift_L:   return 0xA0;
        case XK_Shift_R:   return 0xA1;
        case XK_Control_L: return 0xA2;
        case XK_Control_R: return 0xA3;
        case XK_Menu:      return 0xA4;
        case XK_Alt_L:     return 0xA4;
        case XK_Alt_R:     return 0xA5;
        case XK_Super_L:   return 0x5B;
        case XK_Super_R:   return 0x5C;
        default: break;
    }
    if (ks >= XK_F1 && ks <= XK_F24) return 0x70 + (uint32_t)(ks - XK_F1);
    if (ks >= XK_KP_0 && ks <= XK_KP_9) return 0x60 + (uint32_t)(ks - XK_KP_0);
    return 0;
}

// X11 的 state 位 → Win32 的 MK_* 位。
static WPARAM xstate_to_mk(unsigned state, unsigned button)
{
    WPARAM mk = 0;
    if (state & Button1Mask) mk |= 0x0001;
    if (state & Button3Mask) mk |= 0x0002;
    if (state & ShiftMask)   mk |= 0x0004;
    if (state & ControlMask) mk |= 0x0008;
    if (state & Button2Mask) mk |= 0x0010;
    // 当前正在按下/抬起的那颗按钮：X11 的 state **不含**本次事件的那颗
    // （ButtonPress 时它还没进 state，ButtonRelease 时它已经出去了），
    // 所以按事件类型手动补。
    if (button == Button1) mk |= 0x0001;
    if (button == Button3) mk |= 0x0002;
    if (button == Button2) mk |= 0x0010;
    return mk;
}

static void push(wpf_thread *t, HWND hwnd, uint32_t msg, WPARAM wp, LPARAM lp,
                 int px, int py)
{
    WPF_MSG m;
    memset(&m, 0, sizeof(m));
    m.hwnd = hwnd;
    m.message = msg;
    m.wParam = wp;
    m.lParam = lp;
    m.time = (uint32_t)wpf_now_ms();
    m.pt_x = px;
    m.pt_y = py;
    wpf_queue_push(t, &m);
}

// 客户区坐标（X11 事件的 x/y 已经是相对事件窗口的客户区坐标，无需转换）。
static LPARAM xy_lparam(int x, int y)
{
    return (LPARAM)((((uint32_t)y & 0xFFFF) << 16) | ((uint32_t)x & 0xFFFF));
}

int wpf_x11_pump_into_queue(wpf_thread *t)
{
    if (!g_wpf.dpy) return 0;
    Display *d = g_wpf.dpy;
    int produced = 0;

    XLOCK();
    while (XPending(d)) {
        XEvent ev;
        XNextEvent(d, &ev);
        XUNLOCK();   // 翻译层只碰自有状态；放锁避免和终结器线程上的 XDestroyWindow 互等

        // 【KEY_DIAG 第一格】"事件到底有没有进到本进程" —— 收到即打（含合成位）。
        //   若注入后这里**一条都没有** ⇒ 事件根本没到我们（注入 id 不是我们的窗口 /
        //   别的客户端持有那个窗口 / 注入被 server 丢掉），与"我们收到了又丢"必须分清。
        if (ev.type == KeyPress || ev.type == KeyRelease || ev.type == FocusIn || ev.type == FocusOut) {
            wpf_key_diag("XEV %s window=0x%llx send_event=%d（1=XSendEvent 合成）",
                         wpf_xevent_name(ev.type),
                         (unsigned long long)(uintptr_t)ev.xany.window,
                         ev.xany.send_event ? 1 : 0);
        }

        switch (ev.type) {
        case Expose:
            if (ev.xexpose.count == 0) {
                push(t, (HWND)(uintptr_t)ev.xexpose.window, WM_PAINT, 0, 0, 0, 0);
                produced++;
            }
            break;

        case ConfigureNotify: {
            HWND h = (HWND)(uintptr_t)ev.xconfigure.window;
            // ── 【波 59】`ConfigureNotify` 的 x/y 是**父窗口相对**坐标，不是屏幕坐标 ──────
            //   为什么必须翻译：WM 会把客户窗 reparent 进一个 frame（xfwm4 连**无装饰**的窗口
            //   也这么做）⇒ 窗口被移动/改尺寸后，`ev.xconfigure.x/y` 报的是"在 frame 里的位置"
            //   （恒为 0,0 附近），直接写进窗口表就把 `w->x/y`（结构体注释：客户区左上角在
            //   **root** 上的坐标）搞成 (0,0)：实测 `windowsize 1000 800` 之后表里矩形变成
            //   `0,0 1000x800`，而真实位置是 `+200+150`。
            //   后果不是"读数难看"，而是**托管侧的命中测试整条偏掉**：`WindowChromeWorker`
            //   用 `GetWindowRect()`（= 我们的表）算 `mousePosWindow = 屏幕点 − 窗口原点` ⇒
            //   原点错 200,150 ⇒ 标题栏那一点被算成 y=164 ⇒ `_HitTestNca` 判"客户区" ⇒
            //   **拖动/按钮全失效**（实测：同一点在未 resize 时 ht=2 HTCAPTION、被外部 resize
            //   之后变 ht=1 HTCLIENT）。⇒ 这里换成 root 坐标后再落表。
            int cx_root = ev.xconfigure.x, cy_root = ev.xconfigure.y;
            if (g_wpf.dpy) {
                Window child = 0; int tx = 0, ty = 0;
                XLOCK();
                if (XTranslateCoordinates(g_wpf.dpy, (Window)(uintptr_t)h, g_wpf.root, 0, 0, &tx, &ty, &child)) {
                    cx_root = tx; cy_root = ty;
                }
                XUNLOCK();
            }
            // ── 【波 59】WM_SIZE 的 wParam 必须反映**窗口状态**，不能恒为 SIZE_RESTORED ──
            //   为什么（这条是"能最大化但窗态立刻被自己改回普通"的根因）：
            //   上游 `Window.WmSize`（`Window.cs:4680-4740`）按 wParam 分派：收到
            //   `SIZE_RESTORED` 就把 `WindowState` 设回 `Normal` 并 fire `StateChanged`。
            //   修前这里恒发 0 ⇒ 一按最大化，WM 改完几何、我们回填窗口表时又把 WPF 的
            //   `WindowState` 掰回 Normal（应用侧的"还原/最大化"按钮图标与后续命令全错位）。
            //   ⇒ 用窗口表里的状态位把 0/1/2 如实送上去（Win32 的 USER32 也是这么发的）。
            int sizecode = WM_SIZECODE_RESTORED;
            wpf_lock();
            wpf_window *w = wpf_window_find(h);
            if (w) {
                w->x = cx_root;
                w->y = cy_root;
                w->width = ev.xconfigure.width;
                w->height = ev.xconfigure.height;
                w->border = ev.xconfigure.border_width;
                if (w->iconified)      sizecode = WM_SIZECODE_MINIMIZED;
                else if (w->maximized) sizecode = WM_SIZECODE_MAXIMIZED;
            }
            pthread_mutex_unlock(&g_wpf.lock);
            push(t, h, WM_SIZE, (WPARAM)sizecode,
                 (LPARAM)((((uint32_t)ev.xconfigure.height & 0xFFFF) << 16) |
                          ((uint32_t)ev.xconfigure.width & 0xFFFF)), 0, 0);
            push(t, h, WM_MOVE, 0,
                 (LPARAM)((((uint32_t)cy_root & 0xFFFF) << 16) |
                          ((uint32_t)cx_root & 0xFFFF)), 0, 0);
            produced += 2;
            break;
        }

        case UnmapNotify: {
            // ── 【波 59】"图标化"与"隐藏"在 X 侧都是 Unmap，但 Win32 语义完全不同 ────────
            //   最小化在 Win32 里**不发** `WM_SHOWWINDOW(FALSE)`（窗口仍算可见，只是
            //   `SIZE_MINIMIZED`）；xfwm4 的最小化就是 unmap ⇒ 若照旧发 WM_SHOWWINDOW(0)，
            //   上游 `Window._isVisible` 会变 false，之后"还原"路径里那句
            //   `if (_isVisible) ShowWindow(...)`（`Window.cs:5177`）整段被跳过 ⇒
            //   **最小化之后就还原不回来**。⇒ 图标化期间**吃掉** WM_SHOWWINDOW，
            //   改由 MapNotify 补 `WM_SIZE(SIZE_RESTORED)`（与 Win32 的还原读数同形）。
            HWND h = (HWND)(uintptr_t)ev.xunmap.window;
            wpf_lock();
            wpf_window *w = wpf_window_find(h);
            int iconified = w ? w->iconified : 0;
            pthread_mutex_unlock(&g_wpf.lock);
            if (!iconified) {
                push(t, h, WM_SHOWWINDOW, 0, 0, 0, 0);
                produced++;
            }
            break;
        }

        case MapNotify: {
            HWND h = (HWND)(uintptr_t)ev.xmap.window;
            wpf_lock();
            wpf_window *w = wpf_window_find(h);
            int was_iconified = w ? w->iconified : 0;
            int cx = w ? w->x : 0, cy = w ? w->y : 0, cw = w ? w->width : 0, ch = w ? w->height : 0;
            if (w && was_iconified) w->iconified = 0;      // 反图标化：回到"可见 + 普通状态"
            pthread_mutex_unlock(&g_wpf.lock);
            if (was_iconified) {
                push(t, h, WM_SIZE, (WPARAM)WM_SIZECODE_RESTORED,
                     (LPARAM)((((uint32_t)ch & 0xFFFF) << 16) | ((uint32_t)cw & 0xFFFF)), 0, 0);
                push(t, h, WM_MOVE, 0,
                     (LPARAM)((((uint32_t)(int16_t)cy) << 16) | ((uint32_t)(int16_t)cx & 0xFFFF)), 0, 0);
                produced += 2;
            } else {
                push(t, h, WM_SHOWWINDOW, 1, 0, 0, 0);
                produced++;
            }
            break;
        }

        case KeyPress:
        case KeyRelease: {
            HWND h = (HWND)(uintptr_t)ev.xkey.window;
            // 物理键 → VK 仍用**未按 Shift** 的 keysym（VK 描述"哪个键"，不是"哪个字符"）
            KeySym ks = XLookupKeysym(&ev.xkey, 0);
            uint32_t vk = keysym_to_vk(ks);
            // 字符用 Xlib 按**当前修饰键**翻译的结果（补丁 F1）：
            //   旧版把未按 Shift 的 keysym 直接当字符 ⇒ `Shift+a` 也产小写 'a'（大写丢失）。
            char chbuf[8] = { 0 };
            KeySym ksChar = 0;
            int chn = XLookupString(&ev.xkey, chbuf, (int)sizeof(chbuf), &ksChar, NULL);
            // lParam：bit0-15 重复计数(1)、bit16-23 扫描码、bit24 扩展位、
            //         bit30 之前是否按下、bit31 转换位(1=释放)
            uint32_t repeat = 1;
            uint32_t scan = vk & 0xFF;
            int isUp = (ev.type == KeyRelease);
            LPARAM lp = (LPARAM)((repeat & 0xFFFF) | ((scan & 0xFF) << 16) |
                                 ((isUp ? 1u : 0u) << 31));
            BOOL altDown = (ev.xkey.state & Mod1Mask) != 0;
            BOOL ctrlDown = (ev.xkey.state & ControlMask) != 0;
            // [D-K1] 把修饰键掩码与本次按键落表 —— 这是 `GetKeyState` 的唯一数据来源。
            wpf_keystate_sync_modifiers(ev.xkey.state);
            wpf_keystate_note_key(vk, isUp);
            // [D-K1 · 波 20] 把"此刻"的修饰位盖到随后推入的消息上（KEYDOWN/KEYUP 与 WM_CHAR 都会带上）。
            wpf_keystate_set_push_mods(wpf_keystate_event_mods(ev.xkey.state, vk, isUp));
            uint32_t m = isUp ? (altDown ? WM_SYSKEYUP : WM_KEYUP)
                              : (altDown ? WM_SYSKEYDOWN : WM_KEYDOWN);
            push(t, h, m, (WPARAM)vk, lp, ev.xkey.x, ev.xkey.y);
            produced++;

            // ── WM_CHAR（补丁 F1：按 Win32 `TranslateMessage`/`ToUnicode` 的语义）──────
            //   Windows 上 WM_CHAR 的产生规则（实测口径）：
            //     · 只对**按下**产生；
            //     · **Ctrl+字母不产生**（所以 Ctrl+A 是"全选"，不是插入 'a'）——本 shim 旧版
            //       无条件产生 ⇒ T3 的 runner 第一步 `ctrl+a` 会**插一个字符**，行为错；
            //     · 字符按**修饰键**翻译（Shift/CapsLock/CapsLock+Shift），死键/组合键不产单字符
            //       ⇒ 用 `XLookupString` 而不是裸 keysym（旧版丢 Shift，见上）。
            const char *why = NULL;
            if (isUp)                                       why = "释放事件不产字符";
            else if (ctrlDown && !altDown)                  why = "Ctrl 组合不产字符（Win32 语义：Ctrl+A 应是全选）";
            else if (chn != 1)                              why = "XLookupString 未给出单字符（死键/组合/非打印键）";
            else if ((unsigned char)chbuf[0] < 0x20)        why = "控制字符（<0x20）不产 WM_CHAR";
            if (!why) {
                push(t, h, WM_CHAR, (WPARAM)(uint32_t)(unsigned char)chbuf[0], lp, ev.xkey.x, ev.xkey.y);
                produced++;
            }

            // 【KEY_DIAG 第二/三格】"收到且翻译了吗 / 没产字符的原因"
            wpf_lock();
            BOOL known = (wpf_window_find(h) != NULL);
            pthread_mutex_unlock(&g_wpf.lock);
            wpf_key_diag("KEY %s hwnd=0x%llx keycode=%u state=0x%x ks=0x%lx ksChar=0x%lx vk=0x%x 窗口在表里=%d → %s%s",
                         isUp ? "KeyRelease" : "KeyPress",
                         (unsigned long long)(uintptr_t)h, ev.xkey.keycode, ev.xkey.state,
                         (unsigned long)ks, (unsigned long)ksChar, vk, known ? 1 : 0,
                         isUp ? "WM_KEYUP" : (altDown ? "WM_SYSKEYDOWN" : "WM_KEYDOWN"),
                         why ? "" : " + WM_CHAR");
            if (why) wpf_key_diag("DROP WM_CHAR 原因：%s（keycode=%u state=0x%x）", why, ev.xkey.keycode, ev.xkey.state);
            wpf_keystate_set_push_mods(0);   // 后面的非按键事件不带修饰位
            if (!known) wpf_key_diag("警告：事件窗口 0x%llx 不在本 shim 的窗口表里 ⇒ 该消息派发时找不到窗口（会被 DefWindowProc 吃掉）",
                                     (unsigned long long)(uintptr_t)h);
            break;
        }

        case ButtonPress:
        case ButtonRelease: {
            HWND h = (HWND)(uintptr_t)ev.xbutton.window;
            int down = (ev.type == ButtonPress);
            unsigned b = ev.xbutton.button;
            WPARAM mk = xstate_to_mk(ev.xbutton.state, b);
            uint32_t m;
            if (b == Button4 || b == Button5 || b == 6 || b == 7) {
                // 滚轮：Button4/5 竖直、6/7 水平。WM_MOUSEWHEEL 的 lParam 是**屏幕**坐标。
                if (!down) break;   // 滚轮只发按下那次
                int delta = (b == Button4 || b == 6) ? 120 : -120;
                m = (b >= 6) ? WM_MOUSEHWHEEL : WM_MOUSEWHEEL;
                WPF_POINT scr = { ev.xbutton.x_root, ev.xbutton.y_root };
                push(t, h, m, (WPARAM)(((uint32_t)(int32_t)delta << 16) | (uint32_t)mk),
                     xy_lparam(scr.x, scr.y), ev.xbutton.x, ev.xbutton.y);
                produced++;
                break;
            }
            switch (b) {
                case Button1: m = down ? WM_LBUTTONDOWN : WM_LBUTTONUP; break;
                case Button2: m = down ? WM_MBUTTONDOWN : WM_MBUTTONUP; break;
                case Button3: m = down ? WM_RBUTTONDOWN : WM_RBUTTONUP; break;
                default:      m = down ? WM_XBUTTONDOWN : WM_XBUTTONUP; break;
            }
            // 【波 46 仪器】原始字段全打（判"抓取重放"的可靠签名）：env 走 WPF_LINUX_KEY_DIAG，有界。
            {
                static int bn = 0;
                if (bn++ < 60)
                    wpf_key_diag("BTN type=%s btn=%d win=0x%llx state=0x%x time=%lu send=%d subwin=0x%llx xy=%d,%d same_screen=%d",
                                 down ? "Press" : "Release", (int)b, (unsigned long long)(uintptr_t)h,
                                 (unsigned)ev.xbutton.state, (unsigned long)ev.xbutton.time,
                                 (int)ev.xbutton.send_event, (unsigned long long)ev.xbutton.subwindow,
                                 ev.xbutton.x, ev.xbutton.y, (int)ev.xbutton.same_screen);
            }

            // ══ 【波 59 · B】非客户区命中：先问 `WM_NCHITTEST`，再决定这条按下怎么走 ══
            // 【修前】这里**无条件**把 X 的 ButtonPress 翻成 `WM_LBUTTONDOWN` 打进客户区，
            //   而 `WM_NCHITTEST` 在整个 shim 里**从没被派发过**（全仓只有
            //   `win32_core.c` 的 `DefWindowProcW` 那个 `case`、`win32_internal.h` 的宏、
            //   `win32_msg.c` 的调试名表三处 ⇒ 与波 58 的 `WM_GETMINMAXINFO` 同型：**死码**）
            //   ⇒ `WindowChrome` 的自绘标题栏/缩放边框**永远收不到命中测试**。
            // 【Win32 的真实顺序】USER32 在把点击发给窗口前先发 `WM_NCHITTEST`：
            //   `HTCLIENT` ⇒ 发 `WM_LBUTTONDOWN`（本 shim 修前的行为，保持不变）；
            //   非客户区码（`HTCAPTION`/`HT*`）⇒ 只发 `WM_NCLBUTTONDOWN`，并在**默认处理**里
            //   由系统进入模态 move/size 循环。
            // 【本 shim 的落地】命中"算什么"由托管窗口过程回答（`WindowChromeWorker` /
            //   `Window.WmNcHitTest`）；"真去搬/缩"由**我们**按 motion 驱动（没有 USER32 的
            //   模态循环，而 EWMH `_NET_WM_MOVERESIZE` 在本装置上实测无效 —— 见
            //   `wpf_x11_moveresize_window` 的注释）。按下时**只登记**，不动窗口：
            //   ① 这样"双击标题栏"才收得到第二击（一旦按下就发 moveresize，xfwm4 会 grab 指针
            //      把第二击吃掉 —— 修前实测双击只打出 1 条 `[NC_DIAG] NC-PRESS`）；
            //   ② 也让"按在边框上但没拖"不会意外开始缩放。
            if (b == Button1 && down) {
                int ht = wpf_core_nc_hit_test(h, ev.xbutton.x_root, ev.xbutton.y_root);
                {   // 【波 59 仪器】每一次按键都打"问到的命中码"（含 HTCLIENT）：
                    //   判据"拖不动"必须能区分"没问/问回客户区/问回非客户区但 WM 不搬"三种现场。
                    wpf_lock();
                    wpf_window *wi = wpf_window_find(h);
                    int wx = wi ? wi->x : -1, wy = wi ? wi->y : -1;
                    int ww = wi ? wi->width : -1, wh = wi ? wi->height : -1;
                    int top = (wi && !wi->is_message_only && wi->parent == NULL) ? 1 : 0;
                    pthread_mutex_unlock(&g_wpf.lock);
                    wpf_nc_diag("NC-HIT hwnd=0x%llx ht=%d root=%d,%d top=%d 表里矩形=%d,%d %dx%d",
                                (unsigned long long)(uintptr_t)h, ht, ev.xbutton.x_root, ev.xbutton.y_root,
                                top, wx, wy, ww, wh);
                }
                if (ht != HTCLIENT) {
                    uint64_t now = wpf_now_ms();
                    int dbl = 0;
                    if (ht == HTCAPTION && g_nc_click_ms &&
                        now - g_nc_click_ms <= 400 &&
                        abs(ev.xbutton.x_root - g_nc_click_x) <= 4 &&
                        abs(ev.xbutton.y_root - g_nc_click_y) <= 4) dbl = 1;
                    LPARAM scr = xy_lparam(ev.xbutton.x_root, ev.xbutton.y_root);
                    push(t, h, dbl ? WM_NCLBUTTONDBLCLK : WM_NCLBUTTONDOWN, (WPARAM)ht, scr,
                         ev.xbutton.x, ev.xbutton.y);
                    produced++;
                    g_nc_hwnd = h; g_nc_ht = ht; g_nc_started = 0;
                    g_nc_px = ev.xbutton.x_root; g_nc_py = ev.xbutton.y_root;
                    if (!dbl) {
                        // 记下按下时的客户区矩形（拖动/缩放的锚点）
                        wpf_lock();
                        wpf_window *w = wpf_window_find(h);
                        if (w) { g_nc_x = w->x; g_nc_y = w->y; g_nc_w = w->width; g_nc_h = w->height; }
                        pthread_mutex_unlock(&g_wpf.lock);
                        wpf_x11_pointer_grab(h, 1);   // 抓指针：拖出窗口也要继续收 motion
                        g_nc_click_ms = 0;            // 正在拖动 ⇒ 不作双击计数
                    } else {
                        g_nc_click_ms = 0;
                    }
                    if (ht == HTCAPTION && !dbl) { /* 抬起时才登记"一次点击" */ }
                    wpf_nc_diag("NC-PRESS hwnd=0x%llx ht=%d%s root=%d,%d start=%d,%d %dx%d",
                                (unsigned long long)(uintptr_t)h, ht, dbl ? " (DBLCLK)" : "",
                                ev.xbutton.x_root, ev.xbutton.y_root, g_nc_x, g_nc_y, g_nc_w, g_nc_h);
                    break;   // ⚠️ 非客户区按下**不进客户区**：不发 WM_LBUTTONDOWN
                }
            }
            if (b == Button1 && !down && g_nc_hwnd == h) {
                // 配对抬起（Win32：非客户区按下 ⇒ 抬起是 WM_NCLBUTTONUP）
                push(t, h, WM_NCLBUTTONUP, (WPARAM)g_nc_ht,
                     xy_lparam(ev.xbutton.x_root, ev.xbutton.y_root), ev.xbutton.x, ev.xbutton.y);
                produced++;
                wpf_x11_pointer_grab(h, 0);
                if (!g_nc_started && g_nc_ht == HTCAPTION) {
                    // 没拖动 ⇒ 这是一次"点击标题栏"：登记给双击判定用
                    g_nc_click_ms = wpf_now_ms();
                    g_nc_click_x = ev.xbutton.x_root;
                    g_nc_click_y = ev.xbutton.y_root;
                }
                wpf_nc_diag("NC-RELEASE hwnd=0x%llx ht=%d root=%d,%d 拖动过=%d",
                            (unsigned long long)(uintptr_t)h, g_nc_ht,
                            ev.xbutton.x_root, ev.xbutton.y_root, g_nc_started);
                g_nc_hwnd = NULL; g_nc_ht = HTCLIENT; g_nc_started = 0;
                break;
            }

            push(t, h, m, mk, xy_lparam(ev.xbutton.x, ev.xbutton.y),
                 ev.xbutton.x, ev.xbutton.y);
            produced++;
            break;
        }

        case MotionNotify: {
            HWND h = (HWND)(uintptr_t)ev.xmotion.window;
            // ── 【波 59 · B】NC 拖动/缩放的**驱动**：按下之后由 motion 决定搬多少 ───────
            //   为什么不让 WM 代劳：EWMH `_NET_WM_MOVERESIZE` 在本装置的 xfwm4 上实测无效
            //   （外部工具在按住左键期间单独发它，窗口纹丝不动）⇒ 只能自己按帧算几何，
            //   每帧把目标客户区矩形交给 `_NET_MOVERESIZE_WINDOW`（WM 连 frame 一起摆）。
            //   3px 死区：避免"点一下标题栏"被判成拖动（Win32 的 move loop 也有死区）。
            if (g_nc_hwnd == h) {
                int dx = ev.xmotion.x_root - g_nc_px;
                int dy = ev.xmotion.y_root - g_nc_py;
                if (!g_nc_started && abs(dx) <= 3 && abs(dy) <= 3) break;   // 死区内：吞掉，不动
                g_nc_started = 1;
                int nx = g_nc_x, ny = g_nc_y, nw = g_nc_w, nh = g_nc_h;
                switch (g_nc_ht) {
                    case HTCAPTION:     nx = g_nc_x + dx; ny = g_nc_y + dy; break;
                    case HTLEFT:        nx = g_nc_x + dx; nw = g_nc_w - dx; break;
                    case HTRIGHT:       nw = g_nc_w + dx; break;
                    case HTTOP:         ny = g_nc_y + dy; nh = g_nc_h - dy; break;
                    case HTBOTTOM:      nh = g_nc_h + dy; break;
                    case HTTOPLEFT:     nx = g_nc_x + dx; nw = g_nc_w - dx;
                                        ny = g_nc_y + dy; nh = g_nc_h - dy; break;
                    case HTTOPRIGHT:    nw = g_nc_w + dx;
                                        ny = g_nc_y + dy; nh = g_nc_h - dy; break;
                    case HTBOTTOMLEFT:  nx = g_nc_x + dx; nw = g_nc_w - dx;
                                        nh = g_nc_h + dy; break;
                    case HTBOTTOMRIGHT: nw = g_nc_w + dx; nh = g_nc_h + dy; break;
                    default: break;
                }
                if (nw < 1) nw = 1;
                if (nh < 1) nh = 1;
                wpf_x11_moveresize_window(h, nx, ny, nw, nh);
                wpf_nc_diag("NC-DRAG hwnd=0x%llx ht=%d d=%+d,%+d → %dx%d@+%d+%d",
                            (unsigned long long)(uintptr_t)h, g_nc_ht, dx, dy, nw, nh, nx, ny);
                break;   // 拖动期间**不发** WM_MOUSEMOVE（Win32 的模态 move loop 同样不发）
            }
            WPARAM mk = xstate_to_mk(ev.xmotion.state, 0);
            push(t, h, WM_MOUSEMOVE, mk, xy_lparam(ev.xmotion.x, ev.xmotion.y),
                 ev.xmotion.x, ev.xmotion.y);
            produced++;
            break;
        }

        case EnterNotify:
            // 进入窗口 = 一次 MOVE，与 Windows 的 WM_MOUSEMOVE 语义一致。
            push(t, (HWND)(uintptr_t)ev.xcrossing.window, WM_MOUSEMOVE,
                 xstate_to_mk(ev.xcrossing.state, 0),
                 xy_lparam(ev.xcrossing.x, ev.xcrossing.y),
                 ev.xcrossing.x, ev.xcrossing.y);
            produced++;
            break;

        case LeaveNotify:
            push(t, (HWND)(uintptr_t)ev.xcrossing.window, WM_MOUSELEAVE, 0, 0,
                 ev.xcrossing.x, ev.xcrossing.y);
            produced++;
            break;

        case FocusIn: {
            HWND h = (HWND)(uintptr_t)ev.xfocus.window;
            if (wpf_x11_focus_is_echo(h, 1)) {
                wpf_key_diag("FOCUSIN window=0x%llx mode=%d detail=%d（自己 SetFocus 的回送 ⇒ 吃掉，消息已同步派发过）",
                             (unsigned long long)(uintptr_t)h, ev.xfocus.mode, ev.xfocus.detail);
                break;
            }
            wpf_lock(); g_focus_window = h; pthread_mutex_unlock(&g_wpf.lock);
            push(t, h, WM_SETFOCUS, 0, 0, 0, 0);
            produced++;
            // 【KEY_DIAG】焦点事件带 mode/detail：detail=NotifyPointer 说明"焦点其实是
            //   PointerRoot、靠指针进入偶然产生"（我们没调 XSetInputFocus 时的典型形态）。
            wpf_key_diag("FOCUSIN window=0x%llx mode=%d detail=%d（1=NotifyNormal 2=NotifyGrab 3=NotifyUngrab "
                         "4=NotifyWhileGrabbed 5=NotifyPointer 6=NotifyPointerRoot 7=NotifyDetailNone）",
                         (unsigned long long)(uintptr_t)h, ev.xfocus.mode, ev.xfocus.detail);
            break;
        }

        case FocusOut: {
            HWND h = (HWND)(uintptr_t)ev.xfocus.window;
            if (wpf_x11_focus_is_echo(h, 0)) {
                wpf_key_diag("FOCUSOUT window=0x%llx mode=%d detail=%d（自己 SetFocus 的回送 ⇒ 吃掉，消息已同步派发过）",
                             (unsigned long long)(uintptr_t)h, ev.xfocus.mode, ev.xfocus.detail);
                break;
            }
            wpf_lock(); if (g_focus_window == h) g_focus_window = NULL;
            pthread_mutex_unlock(&g_wpf.lock);
            push(t, h, WM_KILLFOCUS, 0, 0, 0, 0);
            produced++;
            wpf_key_diag("FOCUSOUT window=0x%llx mode=%d detail=%d",
                         (unsigned long long)(uintptr_t)h, ev.xfocus.mode, ev.xfocus.detail);
            break;
        }

        case ClientMessage:
            // WM_DELETE_WINDOW → WM_CLOSE（默认处理会 DestroyWindow）
            if (ev.xclient.message_type == a_wm_protocols &&
                (Atom)ev.xclient.data.l[0] == a_wm_delete_window) {
                push(t, (HWND)(uintptr_t)ev.xclient.window, WM_CLOSE, 0, 0, 0, 0);
                produced++;
            }
            break;

        case DestroyNotify: {
            HWND h = (HWND)(uintptr_t)ev.xdestroywindow.window;
            // 我们自己调的 XDestroyWindow 也会走这里——此时窗口表里已经没了，
            // 再发一遍 WM_NCDESTROY 会造成双重 Dispose。用表存在性做闸门。
            wpf_lock();
            int known = wpf_window_find(h) != NULL;
            pthread_mutex_unlock(&g_wpf.lock);
            if (known) {
                push(t, h, WM_DESTROY, 0, 0, 0, 0);
                push(t, h, WM_NCDESTROY, 0, 0, 0, 0);
                produced += 2;
            }
            break;
        }

        default:
            // SelectionRequest / PropertyNotify / VisibilityNotify 等对 WPF
            // 输入与窗口生命周期没有语义 → 丢弃。不产生假消息。
            break;
        }
        XLOCK();
    }
    XUNLOCK();
    return produced;
}

// ══════════════════════════════════════════════════════════════════════════
//  屏幕度量：真实 DPI / 位深 / 像素尺寸（M7c 收尾轮 · DPI 面修复的数据源）
// ══════════════════════════════════════════════════════════════════════════
// 【为什么必须有它】实测（主控的 ctypes 探针 + 本组复现）：
//     GetDeviceCaps(dc, LOGPIXELSX) == 0      ← 这条直接导致 DpiScale=(0,0)
//   而 `UIElement.EnsureDpiScale()`（PresentationCore/System/Windows/UIElement.cs:1128）
//   正是这么算的：
//     dpiX = GetDeviceCaps(GetDC(desktopWnd), LOGPIXELSX);
//     _dpiScaleX = dpiX / DpiUtil.DefaultPixelsPerInch(96);      ⇒ 0/96 = 0
//   于是 `TextSource.PixelsPerDip == 0` ⇒
//     `TextFormatterImp.RoundDipForDisplayMode(v, 0) = Math.Round(v*0)/0 = NaN`
//   ⇒ `CheckFastPathNominalGlyphs` 主循环条件恒 false ⇒ 回 false ⇒ `SimpleRun.Create`
//     返回 null ⇒ `SimpleTextLine.Create` 返回 null ⇒ 回落 LineServices。
//
// 【真值从哪来】X server 自己报的"像素尺寸 + 物理毫米"就能算出 DPI：
//     dpi = pixels * 25.4 / millimeters
//   本机 Xvfb :99 实测 `xdpyinfo`：1280x1024 pixels (325x260 mm) ⇒ **100x100 dpi**。
//   **不是我们编的 96**：96 只在 server 没给可用毫米值（很多虚拟/无 EDID 环境给 0）
//   或算出来的值离谱时才作为**回退**。这与 Windows 上"显示器报 100dpi 就按 100 算"
//   是同一条口径 —— 所以 WPF 在这台 Xvfb 上会按 1.0417 缩放，那是**真话**。
void wpf_x11_screen_metrics(wpf_screen_metrics *out)
{
    memset(out, 0, sizeof(*out));

    // 算一次就缓存：这些入口（GetDeviceCaps / GetDpiFor*）会被高频调用
    // （WPF 的 DpiScale 缓存初始化、SystemParameters、AbiLayout 诊断…），
    // 每次都去问 X server 属于没必要的往返。X 的屏幕度量在进程生命周期内不变。
    static pthread_mutex_t cache_lock = PTHREAD_MUTEX_INITIALIZER;
    static int cached = 0;
    static wpf_screen_metrics cache;

    pthread_mutex_lock(&cache_lock);
    if (cached) { *out = cache; pthread_mutex_unlock(&cache_lock); return; }
    pthread_mutex_unlock(&cache_lock);

    // 【X 连不上也必须给 96，不能给 0】主控复验发现：不带 DISPLAY 时
    // `GetDpiForSystem`/`GetDeviceCaps(LOGPIXELSX)` 仍然返回 0 —— 而 **0 正是
    // 当初把 `DpiScale` 算成 (0,0) 的那个坏值**。没有显示设备时"96 dpi"是
    // 一个**自洽的默认**（Win32 的 `GetDpiForSystem` 在无显示器场景也返回 96），
    // 而 0 会让下游除法/放大率全部退化。所以这里**先把回退值填好**，再尝试问 X。
    out->dpi_x = WPF_DEFAULT_SCREEN_DPI;
    out->dpi_y = WPF_DEFAULT_SCREEN_DPI;

    if (!wpf_x11_ensure()) {
        pthread_mutex_lock(&cache_lock);          // 无 X：缓存"96 回退"，别每次都试连接
        cache = *out; cached = 1;
        pthread_mutex_unlock(&cache_lock);
        return;
    }

    Display *d = g_wpf.dpy;
    int s = g_wpf.screen;
    if (!d) return;

    XLOCK();
    int w   = DisplayWidth(d, s);
    int h   = DisplayHeight(d, s);
    int wmm = DisplayWidthMM(d, s);
    int hmm = DisplayHeightMM(d, s);
    int depth = DefaultDepth(d, s);
    XUNLOCK();

    out->pixels_wide = w;
    out->pixels_high = h;
    out->depth       = depth > 0 ? depth : 0;

    // 毫米值必须"像真的"才算：<=0（未知）、或换算出的 DPI 落在 [48,480] 之外都视为不可信。
    // 上界 480 是 Win32 侧的历史约定（超高 DPI 监视器上限量级），下界 48 挡掉"mm 填了个位数"
    // 这类垃圾值；两侧都不满足就用 96 回退。
    if (wmm > 0 && w > 0) {
        int v = (int)((double)w * 25.4 / (double)wmm + 0.5);
        if (v >= 48 && v <= 480) out->dpi_x = v;      // 毫米值离谱 ⇒ 保留上面的 96 回退
    }
    if (hmm > 0 && h > 0) {
        int v = (int)((double)h * 25.4 / (double)hmm + 0.5);
        if (v >= 48 && v <= 480) out->dpi_y = v;
    }

    pthread_mutex_lock(&cache_lock);
    cache = *out;
    cached = 1;
    pthread_mutex_unlock(&cache_lock);
}

// ══════════════════════════════════════════════════════════════════════════
//  【波 58】顶层窗"装得下"：工作区读数 + 尺寸上限 + 标准 X 提示
// ══════════════════════════════════════════════════════════════════════════
//
// ── 缺陷现场（用户实测 + 本车道复现，`_NET_WM_STATE` 逐字）─────────────────────
//   屏幕 800×600（`Xvfb 800x600x24` + `xfwm4`），应用窗口本身请求客户区 800×600：
//       `_NET_WM_STATE = _NET_WM_STATE_MAXIMIZED_HORZ, _NET_WM_STATE_MAXIMIZED_VERT, FOCUSED`
//       客户区被 WM 改成 800×576 @ 0,24；`_NET_FRAME_EXTENTS = 0,0,24,0`；
//       帧的标题栏子窗在 `+0+-5`（**上边 5 px 被切掉**）⇒ 关闭/最大化按钮点不到；
//       `xdotool windowsize 740 510` / `windowmove 12 20` 全无效（最大化态不许改）。
//   1280×1024 屏上同一份件：`_NET_WM_STATE` 只有 FOCUSED、800×600 @ 245,241、改尺寸生效。
//
// ── 机制（两极化已定：这不是 WPF 的错，是"客户区 + WM 装饰 > 屏幕"的后果）────────
//   X11 的装饰由 WM 加在客户区**外面**：客户区 800 宽 ⇒ 帧 800+2×frameX；
//   xfwm4 判定"帧装不进屏幕"就把它**最大化**（而不是裁掉或缩小）。本机实测阈值
//   （`xctl` 对照件，见报告 §5）：
//       MAXIMIZED_HORZ ⟺ 客户区宽 ≥ 屏宽 − 10   （frameX=5/侧）
//       MAXIMIZED_VERT ⟺ 客户区高 ≥ 屏高 − 34   （标题栏 29 + 底框 5）
//   ⇒ 请求尺寸必须比"屏幕 − 装饰"**再小一点**，否则等于主动要求 WM 最大化。
//
// ── 取舍得说清（这不是"替用户改小窗"）──────────────────────────────────────────
//   Windows 上没有这个问题：装饰由 USER32 画，窗口比屏幕大只会**超出屏幕**（可拖动找回）。
//   Linux 上"超出屏幕"这个状态**不存在** —— WM 必须给装饰腾地方，它的两种做法是
//   "最大化"（我们遇到的）或"裁掉装饰"（更糟）。所以在这里钳尺寸的**目的不是**把用户
//   要的 800×600 改成 784×560，而是**别让 WM 认为这窗装不下**：钳制只在
//   "工作区装不下 + 装饰余量" 时发生，且**只缩不放**；装得下时一个像素都不动
//   （1280×1024 屏上 800×600 窗的读数与修前逐字节相同，见报告 §2 C 格）。
//   代价（如实登记）：小屏上应用的**客户区**会比它请求的小（该拿 `WM_SIZE` 自适应），
//   而 `Window.Width/Height` 属性仍是应用设的值 —— 这与 Windows 上"WM 改了窗口大小"
//   同一形态（WPF 的布局跟的是客户区，不跟 `Width` 属性）。
//
// ── 装饰余量为什么是常数、为什么可覆盖 ─────────────────────────────────────────
//   帧尺寸由 **WM** 决定（xfwm4 5/29、metacity 各有各的），而"建窗时"还没有帧可问
//   （WM 是 map 时才 reparent 的）⇒ 只能用一个**保守常数**：本机 xfwm4 实测需要
//   >10/>34，这里取 16/40（给更宽的边框与更高的标题栏留余量）。
//   换了 WM/主题可用 `WPF_LINUX_DECOR_W` / `WPF_LINUX_DECOR_H` 覆盖（不改代码）。
#define WPF_DECOR_RESERVE_W_DEFAULT 16
#define WPF_DECOR_RESERVE_H_DEFAULT 40

static int wpf_decor_reserve(const char *env, int dflt)
{
    const char *e = getenv(env);
    if (!e || !*e) return dflt;
    int v = atoi(e);
    return v > 0 ? v : dflt;      // 0/负/垃圾值 ⇒ 用默认（不静默变成"不限制"）
}

// ── 工作区（EWMH `_NET_WORKAREA` 第一格）───────────────────────────────────────
// 【为什么不用屏幕尺寸】有面板/任务栏的桌面上，屏幕底部那条不属于可用区
//   （`_NET_WORKAREA` = WM 报的真值）。没有 WM 或 WM 不报该属性时**退化为屏幕尺寸**
//   —— 那是"没有 WM 会加装饰"的现场，本来就装得下。
void wpf_x11_workarea(int *x, int *y, int *w, int *h)
{
    if (x) *x = 0;
    if (y) *y = 0;
    if (w) *w = 0;
    if (h) *h = 0;
    if (!wpf_x11_ensure()) return;          // 无 X：全 0 = "不知道"

    int sx = 0, sy = 0, sw = 0, sh = 0;
    XLOCK();
    sw = DisplayWidth(g_wpf.dpy, g_wpf.screen);
    sh = DisplayHeight(g_wpf.dpy, g_wpf.screen);
    Atom type = 0;
    int fmt = 0;
    unsigned long n = 0, left = 0;
    unsigned char *data = NULL;
    if (a_net_workarea &&
        XGetWindowProperty(g_wpf.dpy, g_wpf.root, a_net_workarea, 0, 4, False, XA_CARDINAL,
                           &type, &fmt, &n, &left, &data) == Success &&
        data && n >= 4 && fmt == 32) {
        long *v = (long *)data;
        if (v[2] > 0 && v[3] > 0) { sx = (int)v[0]; sy = (int)v[1]; sw = (int)v[2]; sh = (int)v[3]; }
    }
    if (data) XFree(data);
    XUNLOCK();

    if (sw <= 0 || sh <= 0) { sw = 1280; sh = 1024; }   // 与 GetSystemMetrics 的兜底口径一致
    if (x) *x = sx;
    if (y) *y = sy;
    if (w) *w = sw;
    if (h) *h = sh;
}

// ── 客户区尺寸上限 = 工作区 − 装饰余量 ─────────────────────────────────────────
// 返回 0,0 表示"不限制"（无 X）⇒ 调用方**不许**据此把窗口钳成 0（见 clamp_toplevel_extent）。
void wpf_x11_client_size_limit(int *max_w, int *max_h)
{
    if (max_w) *max_w = 0;
    if (max_h) *max_h = 0;
    int wx = 0, wy = 0, ww = 0, wh = 0;
    wpf_x11_workarea(&wx, &wy, &ww, &wh);
    if (ww <= 0 || wh <= 0) return;                     // 无 X
    int mw = ww - wpf_decor_reserve("WPF_LINUX_DECOR_W", WPF_DECOR_RESERVE_W_DEFAULT);
    int mh = wh - wpf_decor_reserve("WPF_LINUX_DECOR_H", WPF_DECOR_RESERVE_H_DEFAULT);
    if (mw < 1) mw = 1;
    if (mh < 1) mh = 1;
    if (max_w) *max_w = mw;
    if (max_h) *max_h = mh;
    (void)wx; (void)wy;
}

// ── 屏幕尺寸（**不是**工作区）──────────────────────────────────────────────────
// 【为什么与 workarea 分开】`WM_GETMINMAXINFO` 的 `ptMaxTrackSize` 在 Windows 上取
//   `SM_CXMAXTRACK/SM_CYMAXTRACK`（≈"最大化的窗口尺寸 + 边框"），**不是**工作区；用它当
//   "没有应用侧约束时的默认上限"比"工作区 − 装饰余量"更接近 Win32 语义（波 59 · A 修法）。
void wpf_x11_screen_size(int *sw, int *sh)
{
    if (sw) *sw = 0;
    if (sh) *sh = 0;
    if (!wpf_x11_ensure()) return;
    XLOCK();
    int w = DisplayWidth(g_wpf.dpy, g_wpf.screen);
    int h = DisplayHeight(g_wpf.dpy, g_wpf.screen);
    XUNLOCK();
    if (sw) *sw = w;
    if (sh) *sh = h;
}

// ── "有没有 EWMH 窗口管理器"（决定最大化/移动缩放走 WM 还是自己来）───────────────
int wpf_x11_has_ewmh_wm(void)
{
    if (!wpf_x11_ensure()) return 0;
    int found = 0;
    XLOCK();
    Atom type = 0; int fmt = 0;
    unsigned long n = 0, left = 0;
    unsigned char *data = NULL;
    if (a_net_supporting_wm_check &&
        XGetWindowProperty(g_wpf.dpy, g_wpf.root, a_net_supporting_wm_check, 0, 1, False,
                           XA_WINDOW, &type, &fmt, &n, &left, &data) == Success &&
        data && n >= 1 && fmt == 32) {
        found = 1;
    }
    if (data) XFree(data);
    XUNLOCK();
    return found;
}

// ── 窗口装饰：`_MOTIF_WM_HINTS` ───────────────────────────────────────────────
// 【为什么用 Motif hints 而不是 EWMH】EWMH 没有"不要装饰"这条；MWM hints 是事实标准
//   （GTK/Qt 的客户端自绘标题栏都靠它），xfwm4 支持。
// 【两个实测坑（都在报告 §1/§4 有读数）】
//   ① **属性类型必须是 `_MOTIF_WM_HINTS` 这个 atom 本身**。xfwm4 的 `getMotifHints()` 用
//      `XGetWindowProperty(dpy, w, xatom, 0, 5, FALSE, xatom /*req_type*/, …)`：类型不匹配时
//      X 协议规定"什么都不返回"（nitems=0）⇒ WM **静默忽略**。实测：用
//      `xprop -f _MOTIF_WM_HINTS 32c -set …`（类型 = CARDINAL）写了以后窗框**纹丝不动**；
//      换成类型 = atom 之后**同一时刻**窗框立刻消失（frame 810x634 → 800x600）。
//   ② 它**可以**在 map 之后改：xfwm4 监听 PropertyNotify 并当场重算装饰 ⇒ 不必 unmap/map。
// 【取舍】`decorated=1` 时**删掉**该属性（回到 WM 默认），而不是写 flags=0 ——
//   "没声明"与"声明要装饰"在别的 WM 上语义不完全一样，删掉最保守。
void wpf_x11_set_decorations(HWND hwnd, int decorated)
{
    if (!hwnd) return;
    if (!wpf_x11_ensure()) return;
    Window win = (Window)(uintptr_t)hwnd;
    XLOCK();
    if (!decorated) {
        if (a_motif_wm_hints) {
            // MWM_HINTS_DECORATIONS = 2；decorations = 0 ⇒ 不要标题栏/边框
            unsigned long v[5] = { 2UL, 0UL, 0UL, 0UL, 0UL };
            XChangeProperty(g_wpf.dpy, win, a_motif_wm_hints, a_motif_wm_hints, 32,
                            PropModeReplace, (const unsigned char *)v, 5);
        }
    } else {
        XDeleteProperty(g_wpf.dpy, win, a_motif_wm_hints);
    }
    XFlush(g_wpf.dpy);
    XUNLOCK();
}

// ── EWMH 最大化 / 还原：`_NET_WM_STATE` 的 ADD/REMOVE + MAXIMIZED_HORZ|VERT ──────
// 【为什么必须走 WM 而不是自己 `XMoveResizeWindow` 到屏幕大小】
//   · 有装饰时"客户区多大才算最大化"由 WM 按装饰/面板/工作区算（`_NET_WORKAREA`）；
//   · 最大化是个**状态**：xfwm4 会把它写进 `_NET_WM_STATE`、参与"双击标题栏还原"、
//     贴边/层叠/快捷键切换…自己改几何只是画了个形状，状态还是"普通"。
//   · `_NET_WM_STATE` 也正好是判据里可直接 `xprop` 读到的字段。
void wpf_x11_apply_wm_state(HWND hwnd, int maximize)
{
    if (!hwnd) return;
    if (!wpf_x11_ensure()) return;
    if (!a_net_wm_state) return;
    XLOCK();
    XEvent e;
    memset(&e, 0, sizeof(e));
    e.xclient.type = ClientMessage;
    e.xclient.window = (Window)(uintptr_t)hwnd;
    e.xclient.message_type = a_net_wm_state;
    e.xclient.format = 32;
    e.xclient.data.l[0] = maximize ? 1 : 0;   // 1 = _NET_WM_STATE_ADD, 0 = _NET_WM_STATE_REMOVE
    e.xclient.data.l[1] = (long)a_net_wm_state_maximized_horz;
    e.xclient.data.l[2] = (long)a_net_wm_state_maximized_vert;
    e.xclient.data.l[3] = 1;                  // source indication: 1 = 普通应用
    e.xclient.data.l[4] = 0;
    XSendEvent(g_wpf.dpy, g_wpf.root, False,
               SubstructureRedirectMask | SubstructureNotifyMask, &e);
    XFlush(g_wpf.dpy);
    XUNLOCK();
}

// ── 最小化（图标化）──────────────────────────────────────────────────────────
void wpf_x11_iconify(HWND hwnd)
{
    if (!hwnd) return;
    if (!wpf_x11_ensure()) return;
    XLOCK();
    XIconifyWindow(g_wpf.dpy, (Window)(uintptr_t)hwnd, g_wpf.screen);
    XFlush(g_wpf.dpy);
    XUNLOCK();
}

// ── 把"这一次指针拖动"落成真几何：`_NET_MOVERESIZE_WINDOW` ─────────────────────
// 【为什么是这条消息，而不是 `_NET_WM_MOVERESIZE`（**实测否定**）】
//   Windows 上"按住标题栏拖动"由 USER32 在 `WM_NCLBUTTONDOWN` 的默认处理里进入**模态
//   move/size 循环**完成。X11 的表面对应物是 EWMH `_NET_WM_MOVERESIZE`（"把这个拖动交给
//   WM"）—— 它在 xfwm4 的 `_NET_SUPPORTED` 里**确实有**，但本装置上**实测无效**：
//     · 按住左键 + 指针移动期间，从外部工具把 `_NET_WM_MOVERESIZE(MOVE, dir=8)` 发给 root，
//       窗口原点**一动不动**（`[NC_DIAG]` 也证明我们确实发过这条）；
//     · 同一装置同一时刻把 `_NET_MOVERESIZE_WINDOW` 发出去，窗口**立刻**变成 900x700@+400+300。
//   ⇒ 拖动只能由**我们自己**按 motion 事件驱动，每一帧把目标几何交给 WM。
// 【为什么走 WM 而不是裸 `XMoveResizeWindow`】xfwm4 连"无装饰"的窗口也 reparent 到一个
//   同尺寸的 frame 里（实测 `xwininfo -children` 的 parent 恒非 root）⇒ 裸移客户窗只会让
//   内容在 frame 内部滑动，视觉上"窗户没动"。
// 【没有 EWMH WM 时】退回裸 `XMoveResizeWindow`（Xvfb 裸跑也能拖，只是没有 WM 的贴边行为）。
int wpf_x11_moveresize_window(HWND hwnd, int x, int y, int w, int h)
{
    if (!hwnd) return 0;
    if (!wpf_x11_ensure()) return 0;
    if (w <= 0 || h <= 0) return 0;
    Window win = (Window)(uintptr_t)hwnd;
    int use_wm = wpf_x11_has_ewmh_wm();     // 自己取锁（下面 XLOCK 是另一把锁，顺序：xlock 在外）
    XLOCK();
    if (use_wm && a_net_moveresize_window) {
        XEvent e;
        memset(&e, 0, sizeof(e));
        e.xclient.type = ClientMessage;
        e.xclient.window = win;
        e.xclient.message_type = a_net_moveresize_window;
        e.xclient.format = 32;
        // flags：bit8=x bit9=y bit10=w bit11=h 有效；低 8 位 = gravity（10 = StaticGravity）
        e.xclient.data.l[0] = (1L << 8) | (1L << 9) | (1L << 10) | (1L << 11) | 10L;
        e.xclient.data.l[1] = x;
        e.xclient.data.l[2] = y;
        e.xclient.data.l[3] = w;
        e.xclient.data.l[4] = h;
        XSendEvent(g_wpf.dpy, g_wpf.root, False,
                   SubstructureRedirectMask | SubstructureNotifyMask, &e);
    } else {
        XMoveResizeWindow(g_wpf.dpy, win, x, y, (unsigned)w, (unsigned)h);
    }
    XFlush(g_wpf.dpy);
    XUNLOCK();
    return 1;
}

// ── NC 拖动期间的指针抓取 ─────────────────────────────────────────────────────
// 【为什么必须抓】不抓的话指针一旦移出窗口，X 就把 motion 送给别的窗口 ⇒ 拖动循环收不到
//   后续位移（表现：拖两下就断）。抓取期间事件仍送给**同一个客户窗**（就是我们）⇒ 托管侧
//   照常收到 WM_MOUSEMOVE/按键消息，语义不变。
void wpf_x11_pointer_grab(HWND hwnd, int grab)
{
    if (!wpf_x11_ensure()) return;
    XLOCK();
    if (grab)
        XGrabPointer(g_wpf.dpy, (Window)(uintptr_t)hwnd, False,
                     PointerMotionMask | ButtonReleaseMask,
                     GrabModeAsync, GrabModeAsync, None, None, CurrentTime);
    else
        XUngrabPointer(g_wpf.dpy, CurrentTime);
    XFlush(g_wpf.dpy);
    XUNLOCK();
}

// ── 标准 X 提示（本 shim 以前一条都不设）──────────────────────────────────────
// 【修前现场】`xprop -id <客户窗>` 只有 WM_NAME/_NET_WM_NAME/WM_PROTOCOLS，
//   **缺** `WM_NORMAL_HINTS`／`WM_HINTS`／`WM_CLASS`／`_NET_WM_WINDOW_TYPE`。
// 【为什么每条都要设】
//   · `WM_NORMAL_HINTS(PMinSize|PMaxSize)`：WM 侧唯一的尺寸约束来源；语义来自
//     `WM_GETMINMAXINFO`（调用方把窗口过程回填后的值传进来），**不是**我们凭空编的值。
//   · `WM_CLASS`：WM 的 per-window 规则/图标匹配靠它（没有它 xfwm4 只能按标题匹配）。
//     这里用 `RegisterClassEx` 注册的类名（WPF 的 `HwndWrapper[...]`），
//     res_name 与 res_class 同值 —— 本工程没有独立的"应用名"这一路信息，不编造。
//   · `WM_HINTS(InputHint=True)`：ICCCM 的"本窗口要键盘输入焦点"，与
//     `wpf_x11_set_input_focus` 的语义一致（F2 补丁）。
//   · `_NET_WM_WINDOW_TYPE=NORMAL` + `_NET_WM_PID`：EWMH 的标准身份提示；
//     NORMAL 是"普通顶层窗"（也是 WM 的缺省假设，写出来让规则能匹配）。
// 【调用时机】必须在**第一次 map 之前**（WM 是 map 时才读提示去决定装饰与尺寸）⇒
//   调用点在建窗路径里、`XMapWindow` 之前（见 win32_core.c 的 create_window_utf8）。
//
// ── 【波 59 · A 修法】`PMaxSize` 不再是"钳制后的尺寸" ──────────────────────────
// 【波 58 的错在哪】波 58 把 `PMaxSize` 写成了 `工作区 − 装饰余量`（= 同一个钳制上限）⇒
//   在 1280x1024 屏上 `xdotool windowsize 1280 1024` 被 WM 钳成 **1264x984**（实测
//   `_NET_WM_STATE` 只有 FOCUSED 但客户区停在 1264x984），在 800x600 屏上更把窗口
//   永久钉在 784x566 —— **"装得下"这件事只该管初始尺寸，不该变成"最大尺寸"**。
// 【现在的口径】`max_w/max_h` = **应用自己在 `WM_GETMINMAXINFO` 里给的 `ptMaxTrackSize`**：
//   · 应用**没改**（等于我们按屏幕尺寸填的默认值）⇒ `max_w/max_h` 传 0 ⇒ **不发 `PMaxSize`**
//     （"拿不到就不发"，绝不用钳制值顶替）；
//   · 应用**真的声明了**（`MaxWidth/MaxHeight` 等）⇒ 发它给的值（不再是我们的钳制上限）。
//   钳制逻辑本身**不变**：`clamp_toplevel_extent` 仍然只作用于建窗/改尺寸那一刻的尺寸。
void wpf_x11_apply_wm_hints(HWND hwnd, const char *cls,
                            int min_w, int min_h, int max_w, int max_h)
{
    if (!hwnd) return;
    if (!wpf_x11_ensure()) return;
    Window win = (Window)(uintptr_t)hwnd;

    XLOCK();
    // ① WM_NORMAL_HINTS：min ≤ max 是 X 的硬要求（server 不检查，WM 会失配）⇒ 这里兜住。
    XSizeHints sh;
    memset(&sh, 0, sizeof(sh));
    sh.min_width  = min_w >= 1 ? min_w : 1;
    sh.min_height = min_h >= 1 ? min_h : 1;
    sh.flags = PMinSize;
    if (max_w > 0 && max_h > 0) {            // 应用真的声明了上限才发 PMaxSize
        sh.flags |= PMaxSize;
        sh.max_width  = (max_w >= sh.min_width)  ? max_w  : sh.min_width;
        sh.max_height = (max_h >= sh.min_height) ? max_h  : sh.min_height;
    }
    XSetWMNormalHints(g_wpf.dpy, win, &sh);

    // ② WM_CLASS（两个字段同值：我们没有独立的 instance 名）
    if (cls && *cls) {
        XClassHint ch;
        ch.res_name = (char *)cls;
        ch.res_class = (char *)cls;
        XSetClassHint(g_wpf.dpy, win, &ch);
    }

    // ③ WM_HINTS：InputHint
    XWMHints wmh;
    memset(&wmh, 0, sizeof(wmh));
    wmh.flags = InputHint;
    wmh.input = True;
    XSetWMHints(g_wpf.dpy, win, &wmh);

    // ④ EWMH：_NET_WM_WINDOW_TYPE=NORMAL / _NET_WM_PID
    if (a_net_wm_window_type && a_net_wm_window_type_normal)
        XChangeProperty(g_wpf.dpy, win, a_net_wm_window_type, XA_ATOM, 32, PropModeReplace,
                        (const unsigned char *)&a_net_wm_window_type_normal, 1);
    if (a_net_wm_pid) {
        long pid = (long)getpid();
        XChangeProperty(g_wpf.dpy, win, a_net_wm_pid, XA_CARDINAL, 32, PropModeReplace,
                        (const unsigned char *)&pid, 1);
    }
    XFlush(g_wpf.dpy);
    XUNLOCK();
}

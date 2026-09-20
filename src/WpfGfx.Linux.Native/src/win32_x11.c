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
            wpf_lock();
            wpf_window *w = wpf_window_find(h);
            if (w) {
                w->x = ev.xconfigure.x;
                w->y = ev.xconfigure.y;
                w->width = ev.xconfigure.width;
                w->height = ev.xconfigure.height;
                w->border = ev.xconfigure.border_width;
            }
            pthread_mutex_unlock(&g_wpf.lock);
            push(t, h, WM_SIZE, 0,
                 (LPARAM)((((uint32_t)ev.xconfigure.height & 0xFFFF) << 16) |
                          ((uint32_t)ev.xconfigure.width & 0xFFFF)), 0, 0);
            push(t, h, WM_MOVE, 0,
                 (LPARAM)((((uint32_t)ev.xconfigure.y & 0xFFFF) << 16) |
                          ((uint32_t)ev.xconfigure.x & 0xFFFF)), 0, 0);
            produced += 2;
            break;
        }

        case MapNotify:
            push(t, (HWND)(uintptr_t)ev.xmap.window, WM_SHOWWINDOW, 1, 0, 0, 0);
            produced++;
            break;

        case UnmapNotify:
            push(t, (HWND)(uintptr_t)ev.xunmap.window, WM_SHOWWINDOW, 0, 0, 0, 0);
            produced++;
            break;

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
            push(t, h, m, mk, xy_lparam(ev.xbutton.x, ev.xbutton.y),
                 ev.xbutton.x, ev.xbutton.y);
            produced++;
            break;
        }

        case MotionNotify: {
            HWND h = (HWND)(uintptr_t)ev.xmotion.window;
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

// WPF-on-Linux · M7b · Win32 shim —— 核心状态与窗口生命周期
//
// 本文件实现「窗口这张表」以及所有只跟表打交道的 user32 API。
// X11 调用一律走 win32_x11.c，消息队列一律走 win32_msg.c。

#define _GNU_SOURCE
#include "win32_internal.h"

#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

wpf_global g_wpf;

// ── LastError ──────────────────────────────────────────────────────────────
// .NET 的 `SetLastError=true` 在 Unix 上走 `Marshal.GetLastPInvokeError`，
// 它读的是 runtime 自己维护的一个 TLS 槽。原生侧必须调 `pal_errno` 的等价物
// 才能被托管侧读到——.NET 在 Unix 上把这个槽映射到 **errno**。
// 所以：set_last_error 就是设置 errno；这是 .NET 运行时在 Unix 上的既定约定
// （见 runtime 的 `System.Native` / `Marshal.GetLastPInvokeError` 实现）。
// 我们不臆造别的机制。
void wpf_set_last_error(uint32_t code) { errno = (int)code; }
uint32_t wpf_get_last_error(void) { return (uint32_t)errno; }

// ── 时钟 ───────────────────────────────────────────────────────────────────
// Win32 的 GetTickCount 是「自系统启动以来的毫秒数，32 位回绕」。我们给的是
// 「自 shim 首次调用以来的毫秒数」，并且**在 32 位空间里单调**（用 clock_bias_ms
// 保证跨过 2^31 不会回绕成负数，Dispatcher.PromoteTimers 拿它跟 dueTime 比大小）。
uint64_t wpf_now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000u + (uint64_t)(ts.tv_nsec / 1000000);
}

static pthread_once_t g_init_once = PTHREAD_ONCE_INIT;

static void wpf_do_global_init(void)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&g_wpf.lock, &attr);
    pthread_mutexattr_destroy(&attr);

    g_wpf.dpy = NULL;
    g_wpf.screen = 0;
    g_wpf.root = 0;
    g_wpf.xfd = -1;
    g_wpf.x_failed = 0;
    g_wpf.windows = NULL;
    g_wpf.classes = NULL;
    g_wpf.timers = NULL;
    g_wpf.threads = NULL;
    g_wpf.next_atom = 0xC000;          // 用户类的 atom 从 0xC000 起（Win32 惯例）
    g_wpf.next_registered_msg = WM_APP; // RegisterWindowMessage 的私有段
    g_wpf.msg_extra_info = 0;
    g_wpf.clock_bias_ms = 0;
    g_wpf.x_error[0] = 0;
}

// 前向声明（定义在下方，紧随 wpf_global_init）
static void wpf_win_diag_selftest(void);

void wpf_global_init(void)
{
    pthread_once(&g_init_once, wpf_do_global_init);
    wpf_win_diag_selftest();   // [1400 诊断] WPF_LINUX_WIN_DIAG=selftest 时合成一条，验证打印管线
}

// ── [1400 诊断] 建窗失败时把**真原因**打到 stderr ──────────────────────────────
// 【为什么默认开】`1400` 是本 shim **自己映射**的码（1400 也用于"hwnd 查不到"等 11+ 处），
//   仅凭它分不清「X 不可用 / `XCreateWindow` 失败 / 句柄非法」。而这条路径**只在建窗失败时**
//   打（那本来就意味着应用起不来）⇒ 默认开不会污染正常日志，且"下次真出现 1400 时一定有输出"。
// 【有界】每进程最多 8 条；`WPF_LINUX_WIN_DIAG=1` 另开成功路径（本函数不管成功路径）。
// 【selftest】`WPF_LINUX_WIN_DIAG=selftest` ⇒ 初始化时合成一条，用来验证"打印管线本身没坏"
//   （牙齿：把下面的格式串改坏 ⇒ selftest 里那条 `dpy_error=` 消失 ⇒ 自检必红）。
static int s_win_diag_lines = 0;
void wpf_win_diag_report(const char *where, const char *cls, HWND parent, uint32_t err)
{
    if (s_win_diag_lines >= 8) return;
    s_win_diag_lines++;
    fprintf(stderr,
            "[WIN_DIAG] CreateWindowEx 失败：where=%s last_error=%u（**本 shim 自己映射的码**；"
            "1400=ERROR_INVALID_WINDOW_HANDLE 在这里是复用值，真原因见下）\n",
            where ? where : "?", (unsigned)err);
    fprintf(stderr,
            "[WIN_DIAG]   X 连接: dpy=%s x_failed=%d dpy_error=\"%s\"\n",
            g_wpf.dpy ? "有" : "无", g_wpf.x_failed,
            g_wpf.dpy_error[0] ? g_wpf.dpy_error : "(空)");
    fprintf(stderr,
            "[WIN_DIAG]   Xlib 异步错误: %s\n",
            g_wpf.x_error[0] ? g_wpf.x_error : "(无：请求还没回错误事件，或不是 X 请求失败)");
    fprintf(stderr,
            "[WIN_DIAG]   窗口参数: cls=\"%s\" parent=0x%llx（message_only=%d）\n",
            cls ? cls : "(null)", (unsigned long long)(uintptr_t)parent,
            wpf_is_message_only_parent(parent) ? 1 : 0);
    fflush(stderr);
}

static void wpf_win_diag_selftest(void)
{
    // ⚠️ 重入护栏（实测踩到，2026-09-13）：`xerr` 分支内部会调 `wpf_x11_ensure()`
    //   → `wpf_global_init()` → 又回到本函数 ⇒ **无限递归 ⇒ SIGSEGV(139)**。
    //   自检只允许跑一次，且不允许重入。
    static int s_running = 0, s_done = 0;
    if (s_running || s_done) return;
    const char *e = getenv("WPF_LINUX_WIN_DIAG");
    if (!e) return;
    if (strcmp(e, "xerr") == 0) {          // 牙齿：真 X 错误路径（坏 window id）
        s_running = 1; s_done = 1;
        wpf_x11_diag_selftest_xerr();
        s_running = 0;
        return;
    }
    if (strcmp(e, "selftest") != 0) return;
    s_running = 1; s_done = 1;
    // 合成一条：验证"诊断管线"本身可用（不需要真的建窗失败，也不需要 X）。
    snprintf(g_wpf.dpy_error, sizeof(g_wpf.dpy_error),
             "SELFTEST：这是合成原因串，用于验证 [WIN_DIAG] 打印管线（不是真的建窗失败）");
    wpf_win_diag_report("selftest", "HwndWrapper[selftest]", (HWND)0, 1400);
    s_running = 0;
}

// 全局锁：可重入（PTHREAD_MUTEX_RECURSIVE）。理由：合法的递归路径真实存在——
//   SendMessage → 窗口过程 → PostMessage/GetClientRect/SetWindowLongPtr → 再进锁。
// 用普通互斥量会在那条路径上自死锁，而且只在特定消息下复现，极难定位。
// 调用约定：所有对 g_wpf 的访问都必须持锁；**调用托管窗口过程时不得持锁**
// （WndProc 会回调进来），所以 wpf_dispatch_to_window 是先取快照再放锁再调。
void wpf_lock(void)
{
    wpf_global_init();
    pthread_mutex_lock(&g_wpf.lock);
}

// ── 线程状态 ───────────────────────────────────────────────────────────────
static pthread_key_t g_tls_key;
static pthread_once_t g_tls_once = PTHREAD_ONCE_INIT;

static void wpf_thread_destroy(void *p)
{
    wpf_thread *t = (wpf_thread *)p;
    if (!t) return;
    if (t->wake_read >= 0) close(t->wake_read);
    if (t->wake_write >= 0) close(t->wake_write);
    wpf_msg_node *n = t->head;
    while (n) { wpf_msg_node *nx = n->next; free(n); n = nx; }
    free(t);
}

static void wpf_make_tls(void)
{
    pthread_key_create(&g_tls_key, wpf_thread_destroy);
}

wpf_thread *wpf_thread_self(void)
{
    wpf_global_init();
    pthread_once(&g_tls_once, wpf_make_tls);

    wpf_thread *t = (wpf_thread *)pthread_getspecific(g_tls_key);
    if (t) return t;

    t = (wpf_thread *)calloc(1, sizeof(wpf_thread));
    t->self = t;
    t->head = t->tail = NULL;
    t->quit_code = -1;
    t->wake_read = t->wake_write = -1;

    int fds[2];
    if (pipe(fds) == 0) {
        t->wake_read = fds[0];
        t->wake_write = fds[1];
        // 非阻塞读端：唤醒水位的字节我们只是「抽干」，不希望 poll 假醒后 read 阻塞。
        int fl = fcntl(t->wake_read, 3 /*F_GETFL*/, 0);
        fcntl(t->wake_read, 4 /*F_SETFL*/, fl | 04000 /*O_NONBLOCK*/);
        fl = fcntl(t->wake_write, 3, 0);
        fcntl(t->wake_write, 4, fl | 04000);
    }

    pthread_setspecific(g_tls_key, t);
    wpf_lock();
    t->next = g_wpf.threads;
    g_wpf.threads = t;
    pthread_mutex_unlock(&g_wpf.lock);
    return t;
}

// ── UTF-16 ↔ UTF-8 ─────────────────────────────────────────────────────────
// .NET 在 Unix 上把 `CharSet.Unicode` 的 string 编成 **UTF-16LE，2 字节/单元**
// （不是 4 字节 wchar_t）。所以这里自己写转换，不碰 wchar_t。
char *wpf_utf16_to_utf8_dup(const uint16_t *s)
{
    if (!s) return NULL;
    size_t cap = 1;
    for (const uint16_t *p = s; *p; p++) cap += 4;
    char *out = (char *)malloc(cap);
    if (!out) return NULL;
    size_t o = 0;
    for (size_t i = 0; s[i]; i++) {
        uint32_t cp = s[i];
        if (cp >= 0xD800 && cp <= 0xDBFF && s[i + 1] >= 0xDC00 && s[i + 1] <= 0xDFFF) {
            cp = 0x10000 + ((cp - 0xD800) << 10) + (s[++i] - 0xDC00);
        }
        if (cp < 0x80) {
            out[o++] = (char)cp;
        } else if (cp < 0x800) {
            out[o++] = (char)(0xC0 | (cp >> 6));
            out[o++] = (char)(0x80 | (cp & 0x3F));
        } else if (cp < 0x10000) {
            out[o++] = (char)(0xE0 | (cp >> 12));
            out[o++] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[o++] = (char)(0x80 | (cp & 0x3F));
        } else {
            out[o++] = (char)(0xF0 | (cp >> 18));
            out[o++] = (char)(0x80 | ((cp >> 12) & 0x3F));
            out[o++] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[o++] = (char)(0x80 | (cp & 0x3F));
        }
    }
    out[o] = 0;
    return out;
}

uint16_t *wpf_utf8_to_utf16_dup(const char *s)
{
    if (!s) return NULL;
    size_t n = strlen(s);
    uint16_t *out = (uint16_t *)malloc((n + 1) * sizeof(uint16_t));
    if (!out) return NULL;
    size_t o = 0;
    for (size_t i = 0; i < n;) {
        uint8_t c = (uint8_t)s[i];
        uint32_t cp;
        int extra;
        if (c < 0x80)        { cp = c;        extra = 0; }
        else if (c < 0xE0)   { cp = c & 0x1F; extra = 1; }
        else if (c < 0xF0)   { cp = c & 0x0F; extra = 2; }
        else                 { cp = c & 0x07; extra = 3; }
        i++;
        for (int k = 0; k < extra && i < n; k++, i++)
            cp = (cp << 6) | ((uint8_t)s[i] & 0x3F);
        if (cp >= 0x10000) {
            cp -= 0x10000;
            out[o++] = (uint16_t)(0xD800 + (cp >> 10));
            out[o++] = (uint16_t)(0xDC00 + (cp & 0x3FF));
        } else {
            out[o++] = (uint16_t)cp;
        }
    }
    out[o] = 0;
    return out;
}

// ── 窗口表 ─────────────────────────────────────────────────────────────────
wpf_window *wpf_window_find(HWND hwnd)
{
    for (wpf_window *w = g_wpf.windows; w; w = w->next)
        if (w->hwnd == hwnd) return w;
    return NULL;
}

wpf_window *wpf_window_add(HWND hwnd)
{
    wpf_window *w = (wpf_window *)calloc(1, sizeof(wpf_window));
    w->hwnd = hwnd;
    w->created_ms = wpf_now_ms();
    w->width = w->height = 0;
    w->next = g_wpf.windows;
    g_wpf.windows = w;
    return w;
}

void wpf_window_remove(HWND hwnd)
{
    wpf_window **pp = &g_wpf.windows;
    while (*pp) {
        if ((*pp)->hwnd == hwnd) {
            wpf_window *victim = *pp;
            *pp = victim->next;
            wpf_prop *p = victim->props;
            while (p) { wpf_prop *nx = p->next; free(p->name); free(p); p = nx; }
            free(victim);
            return;
        }
        pp = &(*pp)->next;
    }
}

wpf_class *wpf_class_find_atom(ATOM atom)
{
    for (wpf_class *c = g_wpf.classes; c; c = c->next)
        if (c->atom == atom) return c;
    return NULL;
}

wpf_class *wpf_class_find_name(const char *name)
{
    if (!name) return NULL;
    for (wpf_class *c = g_wpf.classes; c; c = c->next)
        if (c->name && strcmp(c->name, name) == 0) return c;
    return NULL;
}

int wpf_is_message_only_parent(HWND parent)
{
    return parent == HWND_MESSAGE;
}

// ── 窗口类注册 ─────────────────────────────────────────────────────────────
// X11 没有「窗口类」这个概念（XCreateSimpleWindow 直接建窗）。但托管侧
// HwndWrapper 的整个生命周期都围着它转：RegisterClassEx 拿到 atom →
// CreateWindowEx(className) → 销毁时 UnregisterClass(atom)。所以这里做一个
// **纯进程内的类注册表**：atom 单调分配、类名唯一、lpfnWndProc 存下来作为
// 该窗口的「默认窗口过程」。语义上等价于 Win32 的那部分，且不需要 X11 配合。
ATOM RegisterClassExW(const WPF_WNDCLASSEX_D *wc)
{
    wpf_global_init();
    if (!wc) { wpf_set_last_error(87); return 0; }

    char *name = wpf_utf16_to_utf8_dup(wc->lpszClassName);
    if (!name || name[0] == 0) { free(name); wpf_set_last_error(87); return 0; }

    wpf_lock();
    if (wpf_class_find_name(name)) {
        // Win32 里同名类重复注册返回 0 + ERROR_CLASS_ALREADY_EXISTS(1410)。
        // 托管侧 HwndWrapper 用 GUID 做类名，正常不会撞；撞了就是真错误。
        pthread_mutex_unlock(&g_wpf.lock);
        free(name);
        wpf_set_last_error(1410);
        return 0;
    }
    wpf_class *c = (wpf_class *)calloc(1, sizeof(wpf_class));
    c->atom = g_wpf.next_atom++;
    c->name = name;
    c->wndproc = wc->lpfnWndProc;
    c->style = wc->style;
    c->background = wc->hbrBackground;
    c->cb_wnd_extra = wc->cbWndExtra;
    c->next = g_wpf.classes;
    g_wpf.classes = c;
    ATOM atom = c->atom;
    pthread_mutex_unlock(&g_wpf.lock);
    return atom;
}
ATOM RegisterClassExA(const WPF_WNDCLASSEX_D *wc) { return RegisterClassExW(wc); }
ATOM RegisterClassEx(const WPF_WNDCLASSEX_D *wc) { return RegisterClassExW(wc); }

// UnregisterClass 的 lpClassName 参数在托管侧是 `IntPtr atomString`——
// HwndWrapper 传的是**低 16 位装着 atom 的整数**（见 HwndWrapper.UnregisterClass
// 的注释：「this function is defined as taking a type lpClassName - but this can
// be an atom. 2 Low Bytes are the atom」），PresentationCore 侧则可能传真字符串指针。
// 两种都要认：值 < 0x10000 且能查到 atom → 按 atom 处理；否则当字符串指针。
int UnregisterClassW(const void *lpClassName, HINSTANCE hInstance)
{
    (void)hInstance;
    wpf_global_init();
    wpf_lock();
    wpf_class **pp = &g_wpf.classes;
    intptr_t raw = (intptr_t)lpClassName;
    while (*pp) {
        int hit = 0;
        if (raw > 0 && raw < 0x10000) {
            hit = ((*pp)->atom == (ATOM)raw);
        } else if (lpClassName) {
            char *nm = wpf_utf16_to_utf8_dup((const uint16_t *)lpClassName);
            hit = (nm && (*pp)->name && strcmp(nm, (*pp)->name) == 0);
            free(nm);
        }
        if (hit) {
            wpf_class *victim = *pp;
            *pp = victim->next;
            free(victim->name);
            free(victim);
            pthread_mutex_unlock(&g_wpf.lock);
            return 1;
        }
        pp = &(*pp)->next;
    }
    pthread_mutex_unlock(&g_wpf.lock);
    wpf_set_last_error(1411);   // ERROR_CLASS_DOES_NOT_EXIST
    return 0;
}
int UnregisterClassA(const void *p, HINSTANCE h) { return UnregisterClassW(p, h); }
int UnregisterClass(const void *p, HINSTANCE h) { return UnregisterClassW(p, h); }

// ── 建窗 ───────────────────────────────────────────────────────────────────
// 【字符集这条坑必须先讲清楚，否则整个窗口骨架都建不起来】
//   托管侧的 DllImport 有两种 CharSet：
//     · `CharSet.Unicode`（如 RegisterClassEx）→ 运行时探测 `名W` 再探测 `名`，
//       string 编成 **UTF-16**（2 字节/单元）；
//     · `CharSet.Auto`（如 CreateWindowEx / RegisterWindowMessage / SetProp /
//       SetWindowText / MessageBox / LoadImage / ExtractIconEx）在 **Unix 上折叠为
//       Ansi**，运行时探测 `名`（裸名）再探测 `名A`，string 编成 **UTF-8**。
//   ⚠️ 本轮实测踩过：最初把裸名一律转发到 `...W`，于是 CreateWindowEx 收到的
//      UTF-8 字节被当成 UTF-16 解释，类名变成乱码 → RegisterClassEx 注册的类
//      查不到 → `ERROR_CLASS_DOES_NOT_EXIST (1411)`，HwndWrapper 构造函数抛
//      Win32Exception，连 `Dispatcher.CurrentDispatcher` 都建不出来。
//   所以本文件的约定是：**裸名 == A（UTF-8）实现**，`...W` 负责先转码。
//   同名类/属性/标题的字符串在两个变体之间走的是同一张表。

// ── CW_USEDEFAULT：Win32 的"用默认几何"哨兵 ─────────────────────────────────
// 【为什么必须处理它（这一条卡住了"任何 WPF 窗口"）】
//   托管侧 `Window`/`HwndSource` 在没显式指定几何时会传 **CW_USEDEFAULT**
//   （= 0x80000000 = INT32_MIN）当 x/y/width/height。首版 shim 把它**原样存下**，
//   于是：
//       w->width  = -2147483648  →  GetClientRect 返回 right = -2147483648
//       → HwndTarget.UpdateWindowAndClientCoordinates() 把客户区映射到屏幕坐标
//       → HwndTarget.CreateUCEResources() 里 `new Rect(0,0,right-left,bottom-top)`
//         **int 溢出**成负数 → `ArgumentException: Width and Height must be non-negative.`
//   实测栈（M7c Phase 2）：HwndTarget.cs:773 ← HwndTarget..ctor:274
//   ← HwndSource.Initialize:267 ← Window.CreateSourceWindow:2519。
//   也就是说：只要应用**不显式**给 Width/Height，窗口就建不出来。
//
// 【正确语义】Win32 里 CW_USEDEFAULT 的含义是"由窗口管理器选位置/尺寸"。
//   X11 上对等的做法是给一组**真实可用**的默认值（WPF 随后会自己 SetWindowPos
//   到真实尺寸）。所以这里把它归一到 800×600、位置 0,0 —— 不是伪造一个尺寸，
//   而是补上"没有窗口管理器时该由谁决定"这一环。
#define WPF_CW_USEDEFAULT ((int32_t)0x80000000)

// 位置：CW_USEDEFAULT → 0（X11 下无层叠管理器，用原点即可；WPF 会立即重定位）
static int32_t normalize_position(int32_t v)
{
    return v == WPF_CW_USEDEFAULT ? 0 : v;
}

// 尺寸：CW_USEDEFAULT 或任何 <= 0 的值 → 默认值。
// X11 不允许 0/负尺寸的窗口（XCreateSimpleWindow 会报 BadValue），
// 所以这里必须兜住，而不是把非法值传给 server。
static int32_t normalize_extent(int32_t v, int32_t fallback)
{
    if (v == WPF_CW_USEDEFAULT || v <= 0) return fallback;
    return v;
}

#define WPF_DEFAULT_WINDOW_W 800
#define WPF_DEFAULT_WINDOW_H 600

static HWND create_window_utf8(uint32_t dwExStyle, const char *cls,
                               const char *title, uint32_t dwStyle,
                               int32_t X, int32_t Y, int32_t nWidth, int32_t nHeight,
                               HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, void *lpParam)
{
    wpf_global_init();
    (void)hMenu; (void)hInstance; (void)lpParam;

    if (!wpf_x11_ensure()) {
        wpf_set_last_error(1400);
        wpf_win_diag_report("X11 不可用（wpf_x11_ensure 失败）", cls, hWndParent, 1400);
        return NULL;
    }

    wpf_lock();
    wpf_class *klass = NULL;
    if (cls) {
        klass = wpf_class_find_name(cls);
        if (!klass && (intptr_t)cls > 0 && (intptr_t)cls < 0x10000)
            klass = wpf_class_find_atom((ATOM)(intptr_t)cls);
    }
    if (!klass) {
        pthread_mutex_unlock(&g_wpf.lock);
        wpf_set_last_error(1411);   // ERROR_CLASS_DOES_NOT_EXIST
        return NULL;
    }

    wpf_window *w = wpf_window_add(0);      // hwnd 待 X 分配后回填
    w->class_atom = klass->atom;
    w->class_wndproc = klass->wndproc;
    w->wndproc = klass->wndproc;
    w->style = (int64_t)(int32_t)dwStyle;
    w->exstyle = (int64_t)(int32_t)dwExStyle;
    w->parent = hWndParent;
    w->is_message_only = wpf_is_message_only_parent(hWndParent);
    w->x = normalize_position(X);
    w->y = normalize_position(Y);
    w->width = normalize_extent(nWidth, WPF_DEFAULT_WINDOW_W);
    w->height = normalize_extent(nHeight, WPF_DEFAULT_WINDOW_H);
    w->owner_thread = (void *)wpf_thread_self();
    pthread_mutex_unlock(&g_wpf.lock);

    uint64_t xid = wpf_x11_create_window(w, title ? title : "");
    if (xid == 0) {
        wpf_lock(); wpf_window_remove(w->hwnd); pthread_mutex_unlock(&g_wpf.lock);
        wpf_set_last_error(1400);
        wpf_win_diag_report("XCreateWindow 返回 0", cls, hWndParent, 1400);
        return NULL;
    }

    wpf_lock();
    w->hwnd = (HWND)(uintptr_t)xid;
    pthread_mutex_unlock(&g_wpf.lock);

    // ── 建窗消息序列：WM_NCCREATE → WM_CREATE。**message-only 窗口也必须发** ──
    // 【首版为什么错，以及错成了什么】
    //   首版判断"message-only 窗口不需要 hooks"就跳过了这两条消息。结果：
    //   HwndWrapper 构造函数里那个 `initialWndProc` 委托
    //     NativeMethods.WndProc initialWndProc = new(hwndSubclass.SubclassWndProc);
    //     wc_d.lpfnWndProc = initialWndProc;
    //     …
    //     GC.KeepAlive(initialWndProc);      // ← 构造函数返回后就只剩"类记录里的函数指针"
    //   只在构造函数存活期内被 KeepAlive。而上游 HwndSubclass 的自我挂载**依赖第一条
    //   消息**（SubclassWndProc 里 `if (_bond == Bond.Unattached) HookWindowProc(...)`）。
    //   跳过消息 ⇒ 永远不挂载 ⇒ 窗口的 GWL_WNDPROC 一直是那个已经不可达的 thunk。
    //   之后任何一次 DispatchMessageW 都会调用一个**已被 GC 回收的委托**：
    //     Process terminated.
    //     A callback was made on a garbage collected delegate of type
    //     'WindowsBase!MS.Win32.NativeMethods+WndProc::Invoke'.
    //     at MS.Win32.UnsafeNativeMethods.DispatchMessage(...)
    //     at System.Windows.Threading.Dispatcher.TranslateAndDispatchMessage(...)
    //   —— 进程直接终止（不是异常，是 fail-fast），且只在"Dispatcher 的
    //   message-only 窗口第一次真正收到消息"时才复现。这是本轮最深的一个坑。
    // 【正确做法】Win32 本来就给 message-only 窗口发 WM_NCCREATE/WM_CREATE，
    //   照发即可；"不 map" 才是 message-only 与普通窗口的区别。
    wpf_dispatch_to_window(w->hwnd, WM_NCCREATE, 0, 0);
    wpf_dispatch_to_window(w->hwnd, WM_CREATE, 0, 0);
    if (!w->is_message_only && (dwStyle & WS_VISIBLE) != 0)
        wpf_x11_map(w->hwnd, 1);

    return w->hwnd;
}

HWND CreateWindowExA(uint32_t e, const char *c, const char *n, uint32_t s,
                     int32_t x, int32_t y, int32_t w, int32_t h, HWND p, HMENU m,
                     HINSTANCE i, void *lp)
{ return create_window_utf8(e, c, n, s, x, y, w, h, p, m, i, lp); }

// 裸名 == A：CharSet.Auto 在 Unix 上是 Ansi，运行时会先探到裸名。
HWND CreateWindowEx(uint32_t e, const char *c, const char *n, uint32_t s,
                    int32_t x, int32_t y, int32_t w, int32_t h, HWND p, HMENU m,
                    HINSTANCE i, void *lp)
{ return create_window_utf8(e, c, n, s, x, y, w, h, p, m, i, lp); }

HWND CreateWindowExW(uint32_t e, const uint16_t *c, const uint16_t *n, uint32_t s,
                     int32_t x, int32_t y, int32_t w, int32_t h, HWND p, HMENU m,
                     HINSTANCE i, void *lp)
{
    char *cls = wpf_utf16_to_utf8_dup(c);
    char *title = wpf_utf16_to_utf8_dup(n);
    HWND r = create_window_utf8(e, cls, title, s, x, y, w, h, p, m, i, lp);
    free(cls); free(title);
    return r;
}

// ── 销毁 ───────────────────────────────────────────────────────────────────
BOOL DestroyWindow(HWND hwnd)
{
    wpf_global_init();
    if (!hwnd) { wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }

    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock);
              wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }
    if (w->in_destroy) { pthread_mutex_unlock(&g_wpf.lock); return 1; }
    w->in_destroy = 1;
    pthread_mutex_unlock(&g_wpf.lock);

    // Win32 语义：DestroyWindow 同步发出 WM_DESTROY，随后 WM_NCDESTROY 并销毁 HWND。
    // 托管侧靠 WM_NCDESTROY 触发 HwndWrapper.Dispose(isHwndBeingDestroyed: true)，
    // 少了这条消息，窗口对象就永远不释放（且 ManagedWndProcTracker 也不会解绑）。
    // message-only 窗口**同样**要发 —— 理由与建窗那两条完全对称（见上面 CreateWindowExW
    // 的注释）：HwndSubclass 靠 WM_NCDESTROY 走 CriticalDetach(true) 摘掉自己的
    // WndProc，不发就等于把一个指向托管委托的指针永久留在窗口上。
    wpf_dispatch_to_window(hwnd, WM_DESTROY, 0, 0);
    wpf_dispatch_to_window(hwnd, WM_NCDESTROY, 0, 0);

    // 清掉挂在这个窗口上的定时器（Win32 会自动杀）。
    wpf_lock();
    wpf_timer **tp = &g_wpf.timers;
    while (*tp) {
        if ((*tp)->hwnd == hwnd) {
            wpf_timer *v = *tp; *tp = v->next; free(v);
        } else tp = &(*tp)->next;
    }
    pthread_mutex_unlock(&g_wpf.lock);

    wpf_x11_destroy_window(hwnd);

    wpf_lock();
    wpf_window_remove(hwnd);
    pthread_mutex_unlock(&g_wpf.lock);
    return 1;
}

BOOL IsWindow(HWND hwnd)
{
    wpf_global_init();
    wpf_lock();
    int ok = wpf_window_find(hwnd) != NULL;
    pthread_mutex_unlock(&g_wpf.lock);
    return ok;
}

BOOL IsWindowVisible(HWND hwnd)
{
    wpf_global_init();
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    int v = w && w->mapped;
    pthread_mutex_unlock(&g_wpf.lock);
    return v;
}

BOOL IsWindowEnabled(HWND hwnd) { (void)hwnd; return 1; }   // 无「禁用」语义，见 README
// PresentationNative_cor3.dll 的 EnableWindowWrapper（先 SetLastError(0) 再转发）。
// Linux 上没有「窗口被禁用」这个状态：X11 的输入掩码是应用自己选的，
// 不存在 server 侧的 enable/disable。返回 TRUE = 「当前是启用态」，这是真话。
BOOL EnableWindow(HWND hwnd, BOOL enable) { (void)hwnd; (void)enable; return 1; }
BOOL EnableWindowWrapper(HWND hwnd, BOOL enable) { wpf_set_last_error(0); return EnableWindow(hwnd, enable); }
// 托管侧用 IsWindowUnicode 决定该用 ...W 还是 ...A 变体。我们全部按 Unicode 处理。
BOOL IsWindowUnicode(HWND hwnd) { (void)hwnd; return 1; }

BOOL IsChild(HWND parent, HWND child)
{
    wpf_global_init();
    wpf_lock();
    wpf_window *c = wpf_window_find(child);
    int ok = c && c->parent == parent;
    pthread_mutex_unlock(&g_wpf.lock);
    return ok;
}

// ── 显隐 / 位置 / 尺寸 ─────────────────────────────────────────────────────
// 【波 46 仪器】显示腿事件日志（`SetWindowPos`/`ShowWindow`），env `WPF_LINUX_CREATE_DIAG=1`，≤40 行，只打印。
static void wpf_show_diag(const char *where, HWND hwnd, long a, long b)
{
    static int cached = -1, n = 0;
    if (cached < 0) { const char *e = getenv("WPF_LINUX_CREATE_DIAG"); cached = (e && *e && *e != '0') ? 1 : 0; }
    if (!cached || n++ >= 40) return;
    fprintf(stderr, "[SHOW_DIAG] %s hwnd=0x%llx a=%ld b=%ld\n", where, (unsigned long long)(uintptr_t)hwnd, a, b);
    fflush(stderr);
}

BOOL ShowWindow(HWND hwnd, int nCmdShow)
{
    wpf_global_init();
    wpf_show_diag("ShowWindow", hwnd, (long)nCmdShow, 0);
    int map;
    switch (nCmdShow) {
        case SW_HIDE: map = 0; break;
        case SW_SHOWMINIMIZED: map = 1; break;   // 无 WM/图标化，退化为 map
        case SW_SHOWMAXIMIZED: map = 1; break;   // 同上，退化为 map
        default: map = 1; break;
    }
    wpf_x11_map(hwnd, map);
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock);
              wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }
    int was = w->mapped;
    w->mapped = map;
    pthread_mutex_unlock(&g_wpf.lock);
    if (map) wpf_dispatch_to_window(hwnd, WM_SHOWWINDOW, 1, 0);
    return was;   // Win32: 返回「此前是否可见」
}
BOOL ShowWindowAsync(HWND hwnd, int nCmdShow) { return ShowWindow(hwnd, nCmdShow); }

BOOL MoveWindow(HWND hwnd, int x, int y, int w, int h, BOOL repaint)
{
    (void)repaint;
    wpf_global_init();
    wpf_lock();
    wpf_window *win = wpf_window_find(hwnd);
    if (!win) { pthread_mutex_unlock(&g_wpf.lock);
                wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }
    x = normalize_position(x); y = normalize_position(y);
    w = normalize_extent(w, win->width > 0 ? win->width : WPF_DEFAULT_WINDOW_W);
    h = normalize_extent(h, win->height > 0 ? win->height : WPF_DEFAULT_WINDOW_H);
    win->x = x; win->y = y; win->width = w; win->height = h;
    pthread_mutex_unlock(&g_wpf.lock);
    wpf_x11_move_resize(hwnd, x, y, w, h);
    return 1;
}

BOOL SetWindowPos(HWND hwnd, HWND after, int x, int y, int cx, int cy, UINT flags)
{
    (void)after;
    wpf_global_init();
    const UINT SWP_NOSIZE = 0x0001, SWP_NOMOVE = 0x0002, SWP_NOZORDER = 0x0004;
    const UINT SWP_NOACTIVATE = 0x0010, SWP_SHOWWINDOW = 0x0040, SWP_HIDEWINDOW = 0x0080;
    wpf_show_diag("SetWindowPos", hwnd, (long)flags, ((long)cx << 16) | ((long)cy & 0xffffL));
    (void)SWP_NOZORDER; (void)SWP_NOACTIVATE;

    wpf_lock();
    wpf_window *win = wpf_window_find(hwnd);
    if (!win) { pthread_mutex_unlock(&g_wpf.lock);
                wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }
    int nx = (flags & SWP_NOMOVE) ? win->x : normalize_position(x);
    int ny = (flags & SWP_NOMOVE) ? win->y : normalize_position(y);
    int nw = (flags & SWP_NOSIZE) ? win->width
                                  : normalize_extent(cx, win->width > 0 ? win->width : WPF_DEFAULT_WINDOW_W);
    int nh = (flags & SWP_NOSIZE) ? win->height
                                  : normalize_extent(cy, win->height > 0 ? win->height : WPF_DEFAULT_WINDOW_H);
    win->x = nx; win->y = ny; win->width = nw; win->height = nh;
    pthread_mutex_unlock(&g_wpf.lock);

    wpf_x11_move_resize(hwnd, nx, ny, nw, nh);
    if (flags & SWP_SHOWWINDOW) ShowWindow(hwnd, SW_SHOW);
    if (flags & SWP_HIDEWINDOW) ShowWindow(hwnd, SW_HIDE);

    // Win32 在 SetWindowPos 之后会发 WM_SIZE / WM_MOVE（除非 NOSIZE/NOMOVE）。
    if (!(flags & SWP_NOSIZE)) wpf_dispatch_to_window(hwnd, WM_SIZE, 0,
                                   (LPARAM)(((uint32_t)nw & 0xFFFF) | ((uint32_t)nh << 16)));
    if (!(flags & SWP_NOMOVE)) wpf_dispatch_to_window(hwnd, WM_MOVE, 0,
                                   (LPARAM)(((uint32_t)(int16_t)nx) | ((uint32_t)(int16_t)ny << 16)));
    return 1;
}

BOOL GetClientRect(HWND hwnd, WPF_RECT *rc)
{
    wpf_global_init();
    if (!rc) return 0;
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock);
              wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }
    rc->left = 0; rc->top = 0; rc->right = w->width; rc->bottom = w->height;
    pthread_mutex_unlock(&g_wpf.lock);
    return 1;
}

BOOL GetWindowRect(HWND hwnd, WPF_RECT *rc)
{
    wpf_global_init();
    if (!rc) return 0;
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock);
              wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }
    rc->left = w->x; rc->top = w->y;
    rc->right = w->x + w->width + 2 * w->border;
    rc->bottom = w->y + w->height + 2 * w->border;
    pthread_mutex_unlock(&g_wpf.lock);
    return 1;
}

// 非客户区在 X11 上由窗口管理器（Xvfb 下没有 WM）负责，我们只有客户区，
// 所以 ScreenToClient/ClientToScreen 就是「减去/加上窗口原点」。
BOOL ScreenToClient(HWND hwnd, WPF_POINT *pt)
{
    wpf_global_init();
    if (!pt) return 0;
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock); return 0; }
    pt->x -= w->x; pt->y -= w->y;
    pthread_mutex_unlock(&g_wpf.lock);
    return 1;
}

BOOL ClientToScreen(HWND hwnd, WPF_POINT *pt)
{
    wpf_global_init();
    if (!pt) return 0;
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock); return 0; }
    pt->x += w->x; pt->y += w->y;
    pthread_mutex_unlock(&g_wpf.lock);
    return 1;
}

// ── 窗口长整型（GWL_*）─────────────────────────────────────────────────────
// 只支持真的被用到的槽位；其余返回 0 并设 ERROR_INVALID_INDEX，**不假装成功**。
static int gwl_slot(int nIndex, int64_t **out, wpf_window *w)
{
    static __thread int64_t scratch;
    switch (nIndex) {
        case GWL_WNDPROC:    return -1;    // 由调用方特殊处理
        case GWL_STYLE:      *out = &w->style;    return 1;
        case GWL_EXSTYLE:    *out = &w->exstyle;  return 1;
        case GWL_USERDATA:   *out = (int64_t *)&w->userdata; return 1;
        case GWL_ID:         *out = &scratch;     return 1;   // 无子窗口 ID 语义
        case GWL_HINSTANCE:
        case GWL_HWNDPARENT: *out = (int64_t *)&w->parent; return 1;
        default: return 0;
    }
}

INT_PTR GetWindowLongPtrW(HWND hwnd, int nIndex)
{
    wpf_global_init();
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock);
              wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }
    if (nIndex == GWL_WNDPROC) {
        INT_PTR r = (INT_PTR)w->wndproc;
        pthread_mutex_unlock(&g_wpf.lock);
        return r;
    }
    int64_t *slot = NULL;
    if (gwl_slot(nIndex, &slot, w) == 1) {
        INT_PTR r = (INT_PTR)*slot;
        pthread_mutex_unlock(&g_wpf.lock);
        return r;
    }
    pthread_mutex_unlock(&g_wpf.lock);
    wpf_set_last_error(87);   // ERROR_INVALID_PARAMETER
    return 0;
}
INT_PTR GetWindowLongPtrA(HWND h, int i) { return GetWindowLongPtrW(h, i); }
INT_PTR GetWindowLongPtr(HWND h, int i) { return GetWindowLongPtrW(h, i); }

// 32 位变体：截断返回，但**保留低 32 位语义**（托管侧 GetWindowLong 用它读 STYLE）。
LONG GetWindowLongW(HWND hwnd, int nIndex)
{
    return (LONG)(int32_t)GetWindowLongPtrW(hwnd, nIndex);
}
LONG GetWindowLongA(HWND h, int i) { return GetWindowLongW(h, i); }
LONG GetWindowLong(HWND h, int i) { return GetWindowLongW(h, i); }

INT_PTR SetWindowLongPtrW(HWND hwnd, int nIndex, INT_PTR dwNewLong)
{
    wpf_global_init();
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock);
              wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }
    if (nIndex == GWL_WNDPROC) {
        INT_PTR old = (INT_PTR)w->wndproc;
        w->wndproc = (WNDPROC)dwNewLong;
        pthread_mutex_unlock(&g_wpf.lock);
        return old;
    }
    int64_t *slot = NULL;
    if (gwl_slot(nIndex, &slot, w) == 1 && nIndex != GWL_ID) {
        INT_PTR old = (INT_PTR)*slot;
        *slot = (int64_t)dwNewLong;
        pthread_mutex_unlock(&g_wpf.lock);
        return old;
    }
    pthread_mutex_unlock(&g_wpf.lock);
    wpf_set_last_error(87);
    return 0;
}
INT_PTR SetWindowLongPtrA(HWND h, int i, INT_PTR v) { return SetWindowLongPtrW(h, i, v); }
INT_PTR SetWindowLongPtr(HWND h, int i, INT_PTR v) { return SetWindowLongPtrW(h, i, v); }

// PresentationNative_cor3.dll 里这四对是 **Wrapper 后缀**的导出名；M7b 把它们
// 也映射到本 shim，托管侧同一条调用链就能落地（详见 build/shims 的 resolver）。
// Wrapper 与裸名语义相同：唯一区别是 Windows 上 Wrapper 会先 SetLastError(0)。
INT_PTR GetWindowLongPtrWrapper(HWND h, int i) { wpf_set_last_error(0); return GetWindowLongPtrW(h, i); }
INT_PTR GetWindowLongWrapper(HWND h, int i)    { wpf_set_last_error(0); return (INT_PTR)(int32_t)GetWindowLongW(h, i); }
INT_PTR SetWindowLongPtrWrapper(HWND h, int i, INT_PTR v) { return SetWindowLongPtrW(h, i, v); }
INT_PTR SetWindowLongWrapper(HWND h, int i, INT_PTR v)    { return (INT_PTR)(int32_t)SetWindowLongPtrW(h, i, (int32_t)v); }

LONG SetWindowLongW(HWND hwnd, int nIndex, LONG dwNewLong)
{
    return (LONG)(int32_t)SetWindowLongPtrW(hwnd, nIndex, (INT_PTR)(int32_t)dwNewLong);
}
LONG SetWindowLongA(HWND h, int i, LONG v) { return SetWindowLongW(h, i, v); }
LONG SetWindowLong(HWND h, int i, LONG v) { return SetWindowLongW(h, i, v); }

// ── 父子 / 兄弟 / 焦点 / 捕获 ───────────────────────────────────────────────
HWND GetParent(HWND hwnd)
{
    wpf_global_init();
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    HWND p = NULL;
    if (w && w->parent != HWND_MESSAGE && w->parent != NULL) p = w->parent;
    pthread_mutex_unlock(&g_wpf.lock);
    return p;
}

HWND SetParent(HWND hwnd, HWND parent)
{
    wpf_global_init();
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock);
              wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return NULL; }
    HWND old = w->parent;
    w->parent = parent;
    pthread_mutex_unlock(&g_wpf.lock);
    return old;
}

HWND GetAncestor(HWND hwnd, UINT flags)
{
    wpf_global_init();
    const UINT GA_PARENT = 1, GA_ROOT = 2, GA_ROOTOWNER = 3;
    (void)GA_ROOT; (void)GA_ROOTOWNER;
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    HWND r = NULL;
    if (w) {
        if (flags == GA_PARENT) r = (w->parent == HWND_MESSAGE) ? NULL : w->parent;
        else r = w->hwnd;   // GA_ROOT/GA_ROOTOWNER：我们没有嵌套的顶层/属主链，返回自身
    }
    pthread_mutex_unlock(&g_wpf.lock);
    return r;
}

HWND GetWindow(HWND hwnd, UINT uCmd)
{
    // GW_OWNER(4)/GW_HWNDNEXT(2) 等在 X11 上没有对应物。返回 NULL 是**明确的
    // “没有这个窗口”**，调用方（HwndTarget）只在 IsWindow 之后才用，安全。
    (void)uCmd;
    wpf_global_init();
    wpf_lock();
    int known = wpf_window_find(hwnd) != NULL;
    pthread_mutex_unlock(&g_wpf.lock);
    if (!known) wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE);
    return NULL;
}

HWND GetDesktopWindow(void)
{
    wpf_global_init();
    if (!wpf_x11_ensure()) return NULL;
    return (HWND)(uintptr_t)g_wpf.root;      // X11 的 root window 就是「桌面」
}

HWND GetActiveWindow(void) { return GetDesktopWindow(); }
HWND GetForegroundWindow(void) { return GetDesktopWindow(); }
HWND SetActiveWindow(HWND hwnd) { (void)hwnd; return GetForegroundWindow(); }
HWND SetForegroundWindow(HWND hwnd) { (void)hwnd; return GetForegroundWindow(); }

// 焦点/捕获在 X11 上是「每个输入设备一个，且由 server 持有」的概念；
// 没有窗口管理器时 PointerRoot 焦点无意义。这里退化为**进程内的软状态**：
// 记住最近一次 SetFocus/SetCapture 的窗口并原样返回，语义自洽（Set→Get 一致），
// 但不影响真实键盘焦点。这是一处**明确的降级**，已登记到 README/report。
HWND g_focus_window = NULL;
HWND g_capture_window = NULL;

HWND GetFocus(void)
{
    wpf_global_init();
    wpf_lock();
    HWND h = g_focus_window;
    pthread_mutex_unlock(&g_wpf.lock);
    return h;
}

HWND SetFocus(HWND hwnd)
{
    wpf_global_init();
    wpf_lock();
    HWND old = g_focus_window;
    g_focus_window = hwnd;
    pthread_mutex_unlock(&g_wpf.lock);
    // 补丁 F2：Win32 的 SetFocus 语义含"系统键盘输入焦点转到该窗口" ⇒ 同步到 X server。
    //   （只改内部状态的话，真键盘注入到不了我们；见 win32_x11.c 的 wpf_x11_set_input_focus 注释）
    if (hwnd) wpf_x11_set_input_focus(hwnd);
    if (old && old != hwnd) wpf_dispatch_to_window(old, WM_KILLFOCUS, (WPARAM)hwnd, 0);
    // ⚠️⚠️【`D-G66`（2026-09-20）】**`old != hwnd` 守卫必须有** —— Win32 的 `SetFocus` 对"**已经拥有焦点**
    //   的窗口"是**空操作**（既不发 `WM_KILLFOCUS` 也不发 `WM_SETFOCUS`），而上游**逐字依赖**这条不变式：
    //   `upstream/…/PresentationCore/System/Windows/Interop/HwndKeyboardInputProvider.cs:114-124`
    //   写着"已经拿到 Win32 焦点的 HWND **不会**再收到 `WM_SETFOCUS`"。
    //   修前本行**无条件**派发 ⇒ 我们的 `SetFocus` 又**同步**回调 WndProc（`win32_msg.c:512-528` 的
    //   `return proc(hwnd,msg,wp,lp);`）⇒ 形成**闭合托管递归环**（车道 W55A 实测 `Repeated 3265 times:`）：
    //     SetFocus ← TrySetFocus ← AcquireFocus ← TryChangeFocus ← Focus ← CheckForDisconnectedFocus
    //     ← PreNotifyInput ← ProcessStagingArea ← ReportInput ← OnSetFocus ← FilterMessage ← WndProc
    //     ← SubclassWndProc ← NativeMethodsSetLastError.SetFocus ← … （回到 SetFocus）
    //   ⇒ 现象 = 托管 `Stack overflow.`（rc=134）或裸 SIGSEGV（rc=139）；**最小复现只要 2 击**（先点一个导航项、再点一个页签）。
    //   正控（W55A）：`SETFOCUS → XSetInputFocus` 共 358 行，其中 **357 行是同一个窗口**（旧值 == 新值）。
    //   注意：X 侧那句 `wpf_x11_set_input_focus` **保留** —— 它不派发消息，且是"把 X 焦点抢回来"的唯一手段
    //   （`D-G50` 的焦点回声抑制依赖它）；本修法**只**去掉"对同一窗口重复派发 `WM_SETFOCUS`"这一步。
    if (hwnd && old != hwnd) wpf_dispatch_to_window(hwnd, WM_SETFOCUS, (WPARAM)old, 0);
    return old;
}
HWND SetFocusWrapper(HWND h) { wpf_set_last_error(0); return SetFocus(h); }
HWND GetParentWrapper(HWND h) { wpf_set_last_error(0); return GetParent(h); }
HWND GetWindowWrapper(HWND h, UINT c) { wpf_set_last_error(0); return GetWindow(h, c); }
HWND GetAncestorWrapper(HWND h, UINT f) { return GetAncestor(h, f); }

HWND GetCapture(void)
{
    wpf_global_init();
    wpf_lock();
    HWND h = g_capture_window;
    pthread_mutex_unlock(&g_wpf.lock);
    return h;
}

HWND SetCapture(HWND hwnd)
{
    wpf_global_init();
    wpf_lock();
    HWND old = g_capture_window;
    g_capture_window = hwnd;
    pthread_mutex_unlock(&g_wpf.lock);
    // 【波 47 · D-G55】Win32 语义：**失去捕获**的窗口收到 `WM_CAPTURECHANGED`，`lParam` = 新捕获窗口。
    //   为什么必须有：上游 `MouseDevice` 清内部捕获状态**只认** `RawMouseAction.CancelCapture`
    //   （`MouseDevice.cs:386-394`），而该动作的唯一来源是 `HwndMouseInputProvider` 处理
    //   `WM_CAPTURECHANGED`（`:719-735`）。本 shim 之前只改软状态、**一条消息都不派发** ⇒
    //   `Mouse.Captured` 永不复位 ⇒ **点过一次之后，后续点击全被路由到那个控件**
    //   （实测：同一命中梯子冷态 `captured=null`；点一次 TextBox 后 11 个位置全是 `captured=TextBox`）。
    if (old && old != hwnd) wpf_dispatch_to_window(old, WM_CAPTURECHANGED, 0, (LPARAM)hwnd);
    return old;
}

BOOL ReleaseCapture(void)
{
    wpf_global_init();
    wpf_lock();
    HWND old = g_capture_window;
    g_capture_window = NULL;
    pthread_mutex_unlock(&g_wpf.lock);
    // 【波 47 · D-G55】同 `SetCapture`：释放也要派发，否则上游的 `Mouse.Captured` 不复位
    //   （`lParam = 0` ⇒ 命中上游 `!IsOurWindow(lParam) && _active` 分支 ⇒ `CancelCapture`）。
    if (old) wpf_dispatch_to_window(old, WM_CAPTURECHANGED, 0, 0);
    return 1;
}

// ── 文本 / 类名 / 属性 ─────────────────────────────────────────────────────
int GetClassNameW(HWND hwnd, uint16_t *buf, int nMaxCount)
{
    wpf_global_init();
    if (!buf || nMaxCount <= 0) return 0;
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    wpf_class *c = w ? wpf_class_find_atom(w->class_atom) : NULL;
    int n = 0;
    if (c && c->name) {
        uint16_t *u = wpf_utf8_to_utf16_dup(c->name);
        if (u) {
            while (u[n] && n < nMaxCount - 1) { buf[n] = u[n]; n++; }
            free(u);
        }
    }
    buf[n] = 0;
    pthread_mutex_unlock(&g_wpf.lock);
    return n;
}

// CharSet.Auto 在 Unix 上折叠为 Ansi → StringBuilder 是 **UTF-8 字节缓冲**。
int GetClassNameA(HWND hwnd, char *buf, int nMaxCount)
{
    wpf_global_init();
    if (!buf || nMaxCount <= 0) return 0;
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    wpf_class *c = w ? wpf_class_find_atom(w->class_atom) : NULL;
    int n = 0;
    if (c && c->name) {
        while (c->name[n] && n < nMaxCount - 1) { buf[n] = c->name[n]; n++; }
    }
    buf[n] = 0;
    pthread_mutex_unlock(&g_wpf.lock);
    return n;
}
int GetClassName(HWND h, char *b, int n) { return GetClassNameA(h, b, n); }

// CharSet.Auto（Unix→Ansi）→ 裸名收 UTF-8；W 变体先转码后转发。
BOOL SetWindowTextA(HWND hwnd, const char *text) { wpf_x11_set_title(hwnd, text ? text : ""); return 1; }
BOOL SetWindowText(HWND h, const char *t) { return SetWindowTextA(h, t); }
BOOL SetWindowTextW(HWND hwnd, const uint16_t *text)
{
    char *t = wpf_utf16_to_utf8_dup(text);
    BOOL r = SetWindowTextA(hwnd, t ? t : "");
    free(t);
    return r;
}

int GetWindowTextW(HWND hwnd, uint16_t *buf, int nMaxCount)
{
    // 标题的**权威副本在 X server**；本 shim 不缓存。XFetchName 是同步往返，
    // 在 Dispatcher 线程里代价可接受（WPF 只在建窗/改名时读）。
    if (!buf || nMaxCount <= 0) return 0;
    char name[512];
    name[0] = 0;
    wpf_x11_query_title(hwnd, name, sizeof(name));
    uint16_t *u = wpf_utf8_to_utf16_dup(name);
    int n = 0;
    if (u) { while (u[n] && n < nMaxCount - 1) { buf[n] = u[n]; n++; } free(u); }
    buf[n] = 0;
    return n;
}
int GetWindowTextA(HWND hwnd, char *buf, int nMaxCount)
{
    if (!buf || nMaxCount <= 0) return 0;
    char name[512];
    name[0] = 0;
    wpf_x11_query_title(hwnd, name, sizeof(name));
    int n = 0;
    while (name[n] && n < nMaxCount - 1) { buf[n] = name[n]; n++; }
    buf[n] = 0;
    return n;
}
// CharSet.Auto → 裸名收 UTF-8（StringBuilder 在 Unix 上就是字节缓冲）
int GetWindowText(HWND h, char *b, int n) { return GetWindowTextA(h, b, n); }

int GetWindowTextLengthW(HWND hwnd)
{
    uint16_t buf[512];
    return GetWindowTextW(hwnd, buf, 512);
}
// [EntryPoint="GetWindowTextLengthWrapper", CharSet=Auto] → 裸名，无字符串参数
int GetWindowTextLengthWrapper(HWND h) { wpf_set_last_error(0); return GetWindowTextLengthW(h); }
// [EntryPoint="GetWindowTextWrapper", CharSet=Auto] → StringBuilder 是 **UTF-8 字节缓冲**
int GetWindowTextWrapper(HWND h, char *buf, int n) { wpf_set_last_error(0); return GetWindowTextA(h, buf, n); }

static BOOL set_prop_utf8(HWND hwnd, const char *utf8, HANDLE data)
{
    if (!utf8) { wpf_set_last_error(87); return 0; }
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (!w) { pthread_mutex_unlock(&g_wpf.lock);
              wpf_set_last_error(ERROR_INVALID_WINDOW_HANDLE); return 0; }
    for (wpf_prop *p = w->props; p; p = p->next) {
        if (strcmp(p->name, utf8) == 0) {
            HANDLE old = p->value;
            p->value = data;
            pthread_mutex_unlock(&g_wpf.lock);
            return old == NULL;   // Win32: 覆盖已存在的属性返回 FALSE
        }
    }
    wpf_prop *p = (wpf_prop *)calloc(1, sizeof(wpf_prop));
    p->name = strdup(utf8);
    p->value = data;
    p->next = w->props;
    w->props = p;
    pthread_mutex_unlock(&g_wpf.lock);
    return 1;
}

static HANDLE get_prop_utf8(HWND hwnd, const char *utf8)
{
    HANDLE r = NULL;
    if (!utf8) return NULL;
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (w)
        for (wpf_prop *p = w->props; p; p = p->next)
            if (strcmp(p->name, utf8) == 0) { r = p->value; break; }
    pthread_mutex_unlock(&g_wpf.lock);
    return r;
}

static HANDLE remove_prop_utf8(HWND hwnd, const char *utf8)
{
    HANDLE r = NULL;
    if (!utf8) return NULL;
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    if (w) {
        wpf_prop **pp = &w->props;
        while (*pp) {
            if (strcmp((*pp)->name, utf8) == 0) {
                wpf_prop *v = *pp;
                *pp = v->next;
                r = v->value;
                free(v->name); free(v);
                break;
            }
            pp = &(*pp)->next;
        }
    }
    pthread_mutex_unlock(&g_wpf.lock);
    return r;
}

// CharSet.Auto（Unix→Ansi）：裸名与 A 变体都收 UTF-8
BOOL SetPropA(HWND h, const char *n, HANDLE d) { return set_prop_utf8(h, n, d); }
BOOL SetProp(HWND h, const char *n, HANDLE d)  { return set_prop_utf8(h, n, d); }
HANDLE GetPropA(HWND h, const char *n) { return get_prop_utf8(h, n); }
HANDLE GetProp(HWND h, const char *n)  { return get_prop_utf8(h, n); }
HANDLE RemovePropA(HWND h, const char *n) { return remove_prop_utf8(h, n); }
HANDLE RemoveProp(HWND h, const char *n)  { return remove_prop_utf8(h, n); }

// UTF-16 变体：先转码再走同一条路径
BOOL SetPropW(HWND hwnd, const uint16_t *name, HANDLE data)
{
    char *utf8 = wpf_utf16_to_utf8_dup(name);
    BOOL r = set_prop_utf8(hwnd, utf8, data);
    free(utf8);
    return r;
}

HANDLE GetPropW(HWND hwnd, const uint16_t *name)
{
    char *utf8 = wpf_utf16_to_utf8_dup(name);
    HANDLE r = get_prop_utf8(hwnd, utf8);
    free(utf8);
    return r;
}

HANDLE RemovePropW(HWND hwnd, const uint16_t *name)
{
    char *utf8 = wpf_utf16_to_utf8_dup(name);
    HANDLE r = remove_prop_utf8(hwnd, utf8);
    free(utf8);
    return r;
}

int GetWindowThreadProcessId(HWND hwnd, int32_t *pid)
{
    wpf_global_init();
    if (pid) *pid = (int32_t)getpid();
    return (int)wpf_thread_id_of_window(hwnd);
}

// 进程内线程 id：Win32 返回的是「创建该窗口的线程 id」。
// 这里用 pthread_self 的数值（x86-64/glibc 上就是一个指针值）低 31 位。
uint32_t wpf_thread_id_of_window(HWND hwnd)
{
    wpf_lock();
    wpf_window *w = wpf_window_find(hwnd);
    uint32_t r = w ? WPF_THREAD_ID(w->owner_thread) : WPF_THREAD_ID(wpf_thread_self());
    pthread_mutex_unlock(&g_wpf.lock);
    return r;
}

// ── 默认窗口过程 ───────────────────────────────────────────────────────────
// 真实现：对 shim 自己产生的消息给出 Win32 的默认结果；其余返回 0。
// **不是**空壳——HwndSubclass 的整个回退链（CallWindowProc(DefWndProc, ...)）
// 都落在这里，返回错误值会直接改变上层可见行为。
LRESULT DefWindowProcW(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
        case WM_NCCREATE:  return 1;    // 允许建窗（HwndWrapper 依赖）
        case WM_CLOSE:     DestroyWindow(hwnd); return 0;
        case WM_ERASEBKGND: return 1;   // 说“我擦过了”，避免重绘风暴
        case WM_MOUSEACTIVATE: return 3; // MA_NOACTIVATE
        case WM_NCHITTEST: return 1;    // HTCLIENT
        case WM_SETCURSOR: return 1;
        case WM_GETMINMAXINFO: return 0;
        case WM_PAINT:     return 0;
        default:           return 0;
    }
}
LRESULT DefWindowProcA(HWND h, UINT m, WPARAM w, LPARAM l) { return DefWindowProcW(h, m, w, l); }
LRESULT DefWindowProc(HWND h, UINT m, WPARAM w, LPARAM l) { return DefWindowProcW(h, m, w, l); }
LRESULT DefWindowProcWorker(HWND h, UINT m, WPARAM w, LPARAM l) { return DefWindowProcW(h, m, w, l); }

// CallWindowProc：直接调函数指针。这是 HwndSubclass 的窗口过程链全部依赖的入口。
LRESULT CallWindowProcW(WNDPROC proc, HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (!proc) return DefWindowProcW(hwnd, msg, wParam, lParam);
    return proc(hwnd, msg, wParam, lParam);
}
LRESULT CallWindowProcA(WNDPROC p, HWND h, UINT m, WPARAM w, LPARAM l) { return CallWindowProcW(p, h, m, w, l); }
LRESULT CallWindowProc(WNDPROC p, HWND h, UINT m, WPARAM w, LPARAM l) { return CallWindowProcW(p, h, m, w, l); }

// ── 监控器 / 系统度量 ──────────────────────────────────────────────────────
// 无 XRandR 时的真值来源是 X server 的 screen 尺寸（XDisplayWidth/Height）。
int GetSystemMetrics(int nIndex)
{
    wpf_global_init();
    int sw = 1280, sh = 1024;
    if (wpf_x11_ensure()) {
        sw = DisplayWidth(g_wpf.dpy, g_wpf.screen);
        sh = DisplayHeight(g_wpf.dpy, g_wpf.screen);
    }
    switch (nIndex) {
        case SM_CXSCREEN: case SM_CXVIRTUALSCREEN: return sw;
        case SM_CYSCREEN: case SM_CYVIRTUALSCREEN: return sh;
        case SM_XVIRTUALSCREEN: case SM_YVIRTUALSCREEN: return 0;
        case SM_CMONITORS: return 1;
        case SM_MOUSEWHEELPRESENT: return 1;
        case SM_SWAPBUTTON: return 0;
        case SM_MENUDROPALIGNMENT: return 0;
        case SM_REMOTESESSION: return 0;
        case SM_CXICON: case SM_CYICON: return 32;
        case SM_CXSMICON: case SM_CYSMICON: return 16;
        case SM_CXDOUBLECLK: case SM_CYDOUBLECLK: return 4;
        case SM_CXDRAG: case SM_CYDRAG: return 4;
        case SM_CYCAPTION: return 0;    // 无 WM 装饰
        case SM_CXBORDER: case SM_CYBORDER: return 1;
        default: return 0;
    }
}

HMONITOR MonitorFromWindow(HWND hwnd, UINT flags) { (void)hwnd; (void)flags; return (HMONITOR)(uintptr_t)1; }
HMONITOR MonitorFromPoint(WPF_POINT pt, UINT flags) { (void)pt; (void)flags; return (HMONITOR)(uintptr_t)1; }
HMONITOR MonitorFromRect(const WPF_RECT *rc, UINT flags) { (void)rc; (void)flags; return (HMONITOR)(uintptr_t)1; }

BOOL GetMonitorInfoW(HMONITOR mon, WPF_MONITORINFOEX *info)
{
    (void)mon;
    wpf_global_init();
    if (!info) return 0;
    int sw = 1280, sh = 1024;
    if (wpf_x11_ensure()) {
        sw = DisplayWidth(g_wpf.dpy, g_wpf.screen);
        sh = DisplayHeight(g_wpf.dpy, g_wpf.screen);
    }
    info->rcMonitor.left = 0; info->rcMonitor.top = 0;
    info->rcMonitor.right = sw; info->rcMonitor.bottom = sh;
    info->rcWork = info->rcMonitor;
    info->dwFlags = 1;   // MONITORINFOF_PRIMARY
    // szDevice 在 Unix 上是 **char[32]（ANSI/UTF-8）**，不是 uint16_t[32]：
    // 托管侧 [MarshalAs(ByValArray, SizeConst=32)] char[] 配 CharSet.Auto，
    // 而 Unix 上 Auto 折叠为 Ansi。写错会踩掉结构体后面的内存。
    memset(info->szDevice, 0, sizeof(info->szDevice));
    const char *dev = "X11";
    for (int i = 0; i < (int)sizeof(info->szDevice) - 1 && dev[i]; i++)
        info->szDevice[i] = dev[i];
    return 1;
}
BOOL GetMonitorInfoA(HMONITOR m, WPF_MONITORINFOEX *i) { return GetMonitorInfoW(m, i); }
BOOL GetMonitorInfo(HMONITOR m, WPF_MONITORINFOEX *i) { return GetMonitorInfoW(m, i); }

BOOL EnumDisplayMonitors(HDC hdc, const WPF_RECT *clip, void *proc, LPARAM lParam)
{
    // 回调类型是 NativeMethods.MonitorEnumProc：
    //   bool (IntPtr hMonitor, IntPtr hdcMonitor, ref RECT, IntPtr dwData)
    // 只有 1 个监控器 → 调一次。
    (void)hdc; (void)clip;
    if (!proc) return 0;
    wpf_global_init();
    int sw = 1280, sh = 1024;
    if (wpf_x11_ensure()) {
        sw = DisplayWidth(g_wpf.dpy, g_wpf.screen);
        sh = DisplayHeight(g_wpf.dpy, g_wpf.screen);
    }
    WPF_RECT rc = { 0, 0, sw, sh };
    typedef BOOL (*enumproc_t)(HMONITOR, HDC, WPF_RECT *, LPARAM);
    return ((enumproc_t)proc)((HMONITOR)(uintptr_t)1, NULL, &rc, lParam) ? 1 : 0;
}

// ── 键盘 / 光标 / 其它已降级项 ──────────────────────────────────────────────
// 这些 API 的返回值在上层只用来「挑分支」，没有可观察的副作用；
// 给常量比给 0 更接近 Windows 行为，且不会让调用方走进错误分支。
int GetDoubleClickTime(void) { return 500; }
// ── [D-K1 · 波 24] `GetKeyState` **逐次调用探针**（默认关；有界；触顶看得见）──────────
// 要回答的问题（主控 2026-09-14 批准的那条读数设计）：整批档 `Ctrl+A` 不生效，
//   到底是"**WPF 在派发之外读表**"还是"**下游另有原因**"？
// 本探针把**每一次** `GetKeyState`／`GetAsyncKeyState` 调用照原样打一行：
//   · `t=`   调用时刻（`wpf_now_ms()` = `CLOCK_MONOTONIC` 毫秒）——与 MSGFLOW 的
//            `dispatch … t=` 行**同一个时钟**，两边按 `t` 直接对齐；
//   · `在dispatch中=` 此刻是否在 `DispatchMessageW` 之内（`wpf_msg_in_dispatch()`）；
//   · `快照=` 这条消息的修饰快照**有没有登记到**（与上一项**是两件事**，必须分开看）；
//   · `返回=` 最终返回位；`实时表字节=` 同一时刻实时表的原始字节。
// ⇒ 三种情形一眼可分：①`在dispatch中=否` ⇒ 读发生在派发之外（预处理/泵循环）；
//   ②`在dispatch中=是 快照=无` ⇒ 派发期但这条消息没登记到快照 ⇒ 落到实时表；
//   ③`快照=已登记(0x2)` 且 `返回=0x8000` ⇒ 修饰位**读得到** ⇒ 失败在下游。
// 【默认关 & 零开销】开关只在**首次**调用时读一次环境变量（`WPF_LINUX_KEYSTATE_TRACE=1`）；
//   关着时每次调用只多一条静态判断，不取时间、不拼串、不加锁、不动计数器。
// 【有界 & 触顶看得见】最多打印 `WPF_KS_TRACE_MAX` 行，随后**打一条"已达上限"并继续计数**
//   （"报 0 ≠ 不存在"：被抑制的调用数写在那条提示里，不静默丢失）。
// 【波 24 主控要求 3（L12 现场重演）】第一版把**所有** VK 都打 ⇒ 整批档 368 次调用把 200 行额度吃满，
//   第二档**没有逐行读数**。现在：**只打印"修饰键类"的调用**（含通用位与左右专有位），
//   非修饰键**按设计不打印、只计数**；额度只被修饰键行消耗 ⇒ 修法乙的验证有逐行证据。
//   `GetKeyboardState` 不按 VK，因此在**有修饰键按下时**才打（那才是"第二个缺口"会被咬到的情形）。
#define WPF_KS_TRACE_MAX 200
static int  s_ks_trace = -1;      // -1=还没读过环境变量；0=关；1=开
static long s_ks_max = -1;        // 生效的打印额度（默认 WPF_KS_TRACE_MAX；可用 env 抬）
static long s_ks_calls;           // 开探针以来**发生过的调用总数**（含不打印与被抑制的）
static long s_ks_mod_calls;       // 其中**修饰键类**（探针只打印这一类）
static long s_ks_nonmod_calls;    // 其中**非修饰键**（按设计不打，只计数）
static long s_ks_kbs_calls;       // 其中 `GetKeyboardState`（不按 VK，单独计）
static long s_ks_shown;           // 已经打印过的行数（含那条上限提示）

// 【额度可覆盖（波 24 追加，回应"别只有一个 DP.Text"）】实测整批两档**一趟**里 WPF 会问修饰键
//   **308 次**（`汇总`行原文）⇒ 默认 200 行看不全两档的注入窗口。`WPF_LINUX_KEYSTATE_TRACE_MAX=<n>`
//   可把额度抬到需要的行数；非法值/非正值**回落到默认**（不静默变成 0 行 —— 那正是"报 0 ≠ 不存在"要防的）。
static long wpf_ks_max_lines(void)
{
    if (s_ks_max < 0) {
        const char *e = getenv("WPF_LINUX_KEYSTATE_TRACE_MAX");
        long v = (e && e[0]) ? strtol(e, NULL, 10) : 0;
        s_ks_max = (v > 0 && v <= 100000) ? v : WPF_KS_TRACE_MAX;
    }
    return s_ks_max;
}

// 退出时的**真实总数**（"报 0 ≠ 不存在"：被抑制的调用也必须有地方看得见）。
// 只在探针开启时由 `atexit` 登记一次；关着时连登记都不会发生。
static void wpf_ks_summary(void)
{
    long cap = wpf_ks_max_lines();
    long shown = (s_ks_shown > cap) ? cap : s_ks_shown;
    fprintf(stderr, "[KEYSTATE] 汇总：本次运行共 %ld 次调用（修饰键 %ld 次，已打印 %ld 行；"
                    "非修饰键 %ld 次按设计不打；GetKeyboardState %ld 次）｜行上限 %ld\n",
            s_ks_calls, s_ks_mod_calls, shown, s_ks_nonmod_calls, s_ks_kbs_calls, cap);
}

static int wpf_ks_trace_on(void)
{
    if (s_ks_trace < 0) {
        const char *e = getenv("WPF_LINUX_KEYSTATE_TRACE");
        s_ks_trace = (e && e[0] == '1') ? 1 : 0;
        if (s_ks_trace) atexit(wpf_ks_summary);   // 只在开探针时登记一次：退出时给**真实总数**
    }
    return s_ks_trace;
}
static int wpf_ks_is_modifier(int vk)
{
    switch (vk) {
    case 0x10: case 0xA0: case 0xA1:   // Shift（通用 / L / R）
    case 0x11: case 0xA2: case 0xA3:   // Control
    case 0x12: case 0xA4: case 0xA5:   // Alt / Menu
    case 0x5B: case 0x5C:              // Win
        return 1;
    default:
        return 0;
    }
}
static const char *wpf_ks_vk_name(int vk)
{
    switch (vk) {
    case 0x10: case 0xA0: case 0xA1: return "VK_SHIFT";
    case 0x11: case 0xA2: case 0xA3: return "VK_CONTROL";
    case 0x12: case 0xA4: case 0xA5: return "VK_MENU";
    case 0x5B: case 0x5C:            return "VK_LWIN";
    default:                          return "-";
    }
}
// 只管"打印额度"与触顶提示（调用侧的计数在各自分支里做，避免重复计）
static int wpf_ks_begin_print(void)
{
    long cap = wpf_ks_max_lines();
    if (s_ks_shown >= cap) {
        if (s_ks_shown == cap) {     // 第一次触顶：把"有行被抑制"这件事本身说出来
            s_ks_shown++;
            fprintf(stderr, "[KEYSTATE] …已达上限 %ld 行（**只对修饰键类行计数**）：后续修饰键调用"
                            "**只计数、不再打印**（触顶这一刻：修饰键 %ld 次／总调用 %ld 次；"
                            "退出时会打一条汇总，要全量请分批跑或用 WPF_LINUX_KEYSTATE_TRACE_MAX 抬额度重跑）\n",
                    cap, s_ks_mod_calls, s_ks_calls);
        }
        return 0;
    }
    s_ks_shown++;
    return 1;
}
static void wpf_ks_trace(const char *api, int vk, short ret, int have_snap, uint8_t snap, uint8_t live)
{
    if (!wpf_ks_trace_on()) return;
    s_ks_calls++;
    if (!wpf_ks_is_modifier(vk)) { s_ks_nonmod_calls++; return; }   // 波 24 要求 3：非修饰键**按设计不打**
    s_ks_mod_calls++;
    if (!wpf_ks_begin_print()) return;
    fprintf(stderr, "[KEYSTATE] #%ld %s vk=0x%02x(%s) 返回=0x%04x 在dispatch中=%s 快照=%s(0x%x) "
                    "实时表字节=0x%02x 实时表 ctrl=%d shift=%d alt=%d t=%llums\n",
            s_ks_calls, api, vk, wpf_ks_vk_name(vk), (unsigned)(uint16_t)ret,
            wpf_msg_in_dispatch() ? "是" : "否", have_snap ? "已登记" : "无", (unsigned)snap,
            (unsigned)live,
            (g_wpf.key_state[0x11] & 0x80) ? 1 : 0, (g_wpf.key_state[0x10] & 0x80) ? 1 : 0,
            (g_wpf.key_state[0x12] & 0x80) ? 1 : 0, (unsigned long long)wpf_now_ms());
}

// [D-K1 修法] 从状态表读（表由 `win32_x11.c` 的翻译层维护）：
//   高位 bit15 = 此刻按下（WPF 的 `Keyboard.Modifiers` 只读这一位）；
//   低位 bit0  = 锁定态（CapsLock/NumLock，Win32 同义）。
//   返回值语义与 Windows 一致：`(short)(0x8000 | toggle)`。
static short wpf_keystate_read(int vk, const char *api)
{
    if (vk < 0 || vk > 0xFF) return 0;
    // 【波 44 · D-G49】鼠标五键**不能**读键盘表（那张表只由键盘翻译层填 ⇒ 它们恒 0）。
    //   上游 `Win32MouseDevice:61` 用 `GetKeyState(VK_LBUTTON) & 0x8000` 判 `MouseButtonState`，
    //   读不到 ⇒ 恒 `Released` ⇒ `ButtonBase` 只 `Focus()` 不激活（复选框不勾/下拉不开/滑块不动）。
    //   ⇒ 只对这五个 VK 改问 X 的真实指针按键态；**键盘路径（下面 from_snap/live 两段）逐字未动**。
    if (vk == 0x01 || vk == 0x02 || vk == 0x04 || vk == 0x05 || vk == 0x06) {
        short mret = wpf_x11_mouse_keystate(vk);
        wpf_ks_trace(api, vk, mret, 0, 0, 0);
        return mret;
    }
    // [D-K1 · 波 20] **优先**读"正在派发的那条消息"的修饰快照：
    //   实测一次 `xdotool key ctrl+a` 的 4 个 X 事件在同一次泵里被整批抽干，而消息之后才逐条派发
    //   ⇒ 派发期若读"实时表"，读到的是**最后**一个事件的状态（Ctrl 已抬起）⇒ WPF 看不到修饰键。
    uint8_t snap = 0;
    int have_snap = wpf_keystate_dispatch_mods(&snap);   // 纯读静态变量、无副作用 ⇒ 探针可无条件取一次
    uint8_t live = g_wpf.key_state[vk];                  // 同上：与旧写法一样是不加锁的原始字节读
    short ret;
    int from_snap = 0;
    if (have_snap) {
        switch (vk) {
        case 0x10: case 0xA0: case 0xA1: ret = (short)((snap & 0x1) ? (short)0x8000 : 0); from_snap = 1; break;
        case 0x11: case 0xA2: case 0xA3: ret = (short)((snap & 0x2) ? (short)0x8000 : 0); from_snap = 1; break;
        case 0x12: case 0xA4: case 0xA5: ret = (short)((snap & 0x4) ? (short)0x8000 : 0); from_snap = 1; break;
        case 0x5B: case 0x5C:            ret = (short)((snap & 0x8) ? (short)0x8000 : 0); from_snap = 1; break;
        default: break;   // 非修饰键：仍走实时表
        }
    }
    if (!from_snap) ret = (short)(((live & 0x80) ? 0x8000 : 0) | (live & 0x01));
    wpf_ks_trace(api, vk, ret, have_snap, snap, live);
    return ret;
}
short GetKeyState(int vk)      { return wpf_keystate_read(vk, "GetKeyState"); }
// 简化（如实登记）：Win32 的 `GetAsyncKeyState` 与 `GetKeyState` 的差别在"消息队列内外"，
// 本 shim 只有一张实时表 ⇒ 两者读同一来源（对 WPF 的用法等价）。
// （波 24：两条各打各的 `api=` 标签，免得探针把调用点混成一个。）
short GetAsyncKeyState(int vk) { return wpf_keystate_read(vk, "GetAsyncKeyState"); }

// 顺手补上**此前完全缺失**的 `GetKeyboardState`（布局 = Win32：每字节 bit7=按下、bit0=toggle）。
// [D-K1 · 波 24] 探针**只加一行日志、不改语义**：本 API 按 Win32 语义是"整表复制"，
//   它**不叠**派发快照（与 `GetKeyState` 的取数口径不同）。整批场景里若有调用方指望
//   从它看到 Ctrl，那这里就是第二个缺口 —— 探针把它显式标出来，避免"只查 GetKeyState"漏判。
BOOL GetKeyboardState(uint8_t *out)
{
    if (!out) { wpf_set_last_error(87); return 0; }
    wpf_lock();
    memcpy(out, g_wpf.key_state, sizeof(g_wpf.key_state));
    pthread_mutex_unlock(&g_wpf.lock);
    if (wpf_ks_trace_on()) {
        s_ks_kbs_calls++;
        s_ks_calls++;
        // [D-K1 · 波 24 要求 3] 本 API **不按 VK** ⇒ 不参与"只打修饰键"的过滤；但**只在有修饰键按下时打**
        //   （那才是"第二个缺口"会被咬到的情形），否则只计数、不占额度。
        int any_mod = ((g_wpf.key_state[0x11] | g_wpf.key_state[0x10] |
                        g_wpf.key_state[0x12] | g_wpf.key_state[0x5B]) & 0x80) ? 1 : 0;
        if (any_mod && wpf_ks_begin_print())
            fprintf(stderr, "[KEYSTATE] #%ld GetKeyboardState 返回=1 在dispatch中=%s 实时表 ctrl=%d shift=%d alt=%d t=%llums"
                            "（⚠ 本 API 整表复制、**不叠**派发快照）\n",
                    s_ks_calls, wpf_msg_in_dispatch() ? "是" : "否",
                    (g_wpf.key_state[0x11] & 0x80) ? 1 : 0, (g_wpf.key_state[0x10] & 0x80) ? 1 : 0,
                    (g_wpf.key_state[0x12] & 0x80) ? 1 : 0, (unsigned long long)wpf_now_ms());
    }
    return 1;
}
void  keybd_event(uint8_t vk, uint8_t scan, uint32_t flags, UINT_PTR extra)
{ (void)vk; (void)scan; (void)flags; (void)extra; }          // 注入走 XTest（M1 已有），不在这里伪造成 XSendEvent
void  mouse_event(uint32_t flags, int32_t dx, int32_t dy, uint32_t data, UINT_PTR extra)
{ (void)flags; (void)dx; (void)dy; (void)data; (void)extra; }

HKL GetKeyboardLayout(uint32_t threadId)
{
    (void)threadId;
    return (HKL)(uintptr_t)0x0409;   // en-US；X11 的键盘映射由 XKB 管，见 README
}
int GetKeyboardLayoutList(int size, HKL *list)
{
    if (list && size > 0) list[0] = (HKL)(uintptr_t)0x0409;
    return 1;
}
int GetKeyboardLayoutListWrapper(int size, HKL *list) { wpf_set_last_error(0); return GetKeyboardLayoutList(size, list); }
HKL ActivateKeyboardLayout(HKL hkl, UINT flags) { (void)flags; return hkl; }
int MapVirtualKeyW(UINT code, UINT mapType) { (void)mapType; return (int)code; }
int MapVirtualKeyA(UINT code, UINT mapType) { return MapVirtualKeyW(code, mapType); }
int MapVirtualKey(UINT code, UINT mapType) { return MapVirtualKeyW(code, mapType); }

BOOL GetCursorPos(WPF_POINT *pt)
{
    wpf_global_init();
    if (!pt) return 0;
    if (!wpf_x11_ensure()) return 0;
    Window root_ret, child_ret;
    int rx = 0, ry = 0, wx = 0, wy = 0;
    unsigned int mask = 0;
    if (!XQueryPointer(g_wpf.dpy, g_wpf.root, &root_ret, &child_ret,
                       &rx, &ry, &wx, &wy, &mask))
        return 0;
    pt->x = rx; pt->y = ry;      // XQueryPointer 的 root 坐标就是屏幕坐标
    return 1;
}

HCURSOR GetCursor(void) { return (HCURSOR)(uintptr_t)1; }
HCURSOR SetCursor(HCURSOR c) { HCURSOR old = (HCURSOR)(uintptr_t)1; (void)c; return old; }
// CharSet.Auto → 裸名收 UTF-8（我们本来就不解析光标名，只是把编码约定摆正）
HCURSOR LoadCursorA(HINSTANCE h, const char *name) { (void)h; (void)name; return (HCURSOR)(uintptr_t)1; }
HCURSOR LoadCursor(HINSTANCE h, const char *name) { return LoadCursorA(h, name); }
HCURSOR LoadCursorW(HINSTANCE h, const uint16_t *name) { (void)h; (void)name; return (HCURSOR)(uintptr_t)1; }
BOOL DestroyCursor(HCURSOR c) { (void)c; return 1; }
int ShowCursor(BOOL show) { (void)show; return 0; }

int GetSysColor(int index) { (void)index; return 0x00F0F0F0; }   // COLOR_WINDOW 的现代值

int MessageBeep(UINT type) { (void)type; return 1; }             // 静音环境下无对象可做

// TrackMouseEvent：X11 侧的 WM_MOUSELEAVE 由 LeaveNotify 事件驱动（我们在
// win32_x11.c 里按 EnterNotify/LeaveNotify 直接产生），所以这里只需要记住
// 「调用方想要 TME_LEAVE」并且**返回成功**——语义确实被满足了。
BOOL TrackMouseEvent(WPF_TRACKMOUSEEVENT *tme)
{
    if (!tme) { wpf_set_last_error(87); return 0; }
    if (tme->dwFlags & TME_CANCEL) return 1;
    return 1;
}

// ── `D-G64`（2026-09-20）：`WindowFromPoint` 的**下降**判据 ──────────────────────
// 【为什么必须有这一层】Win32 里**没有"框架窗"这一层**（框架即窗口本身），而 X11 上**会重定父的
//   窗口管理器**（实测 `xfwm4`；用户会话里的 gnome-shell/mutter 同类）会在 root 与我们的客户窗
//   之间插一层**框架窗** ⇒ 原先 `XTranslateCoordinates(root → root)` 返回的 root 直接子窗口是
//   **框架**（实测 `0x200264`）而不是客户窗（`0x200004`）。
//   上游 `HwndMouseInputProvider.ReportInput`
//   （`upstream/…/PresentationCore/System/Windows/Interop/HwndMouseInputProvider.cs:1285-1320`）
//   把本函数的返回值与它自己的 `hwnd` 比对：**不等** ⇒ 打 `Spurious mouse event` 并 `return false`
//   ⇒ 而 `_active = true` / `Actions.Activate` 在 `:1329`，**永远到不了** ⇒ **每一击都被吞、且永不恢复**。
//   现场（车道 W53A 四格矩阵）：无 WM 的 Xvfb 上五步点击全绿；`Xvfb + xfwm4` 上**同一坐标、
//   客户坐标逐条相同**的 12 次点击 `preMouseDown=0`、`AE=0`、`LB sel` 恒 `-1/31`（应用 `alive=yes`）；
//   同一进程里 `kill -TERM <xfwm4>` ⇒ X 把客户还给 root ⇒ **下一次点击立刻恢复**（单变量强证）。
//   ⚠️ 这就是用户报的"界面里点击没反应"：**无 WM 的验收装置永远复现不出来**。
// 【口径（与 Win32 对齐）】从 root 的直接子窗口**逐层下沉**，取"含该点、且**属于本进程**"的
//   **最深**窗口；若整条链上一个本进程窗口都没有（例如别的应用真的盖在上面）⇒ **原样返回顶层窗口**
//   （那正是 Win32 的行为 ⇒ 上游会正确地把那一击判为"不属于自己"）。
// 【可证伪】env `WPF_LINUX_WFP_DIAG=1` ⇒ 每进程 ≤ 40 行打印 `pt/top/own_top/best/depth`（**只打印**）；
//   反极性 = 修前 `best=top=`框架、修后 `best=`客户窗（见 `build/MilBridge/W54A-report.md`）。
static int wpf_point_in_window(Window win, int rx, int ry)
{
    XWindowAttributes at;
    if (!XGetWindowAttributes(g_wpf.dpy, win, &at)) return 0;
    if (at.map_state != IsViewable) return 0;      // 未映射/不可见 ⇒ Win32 的 WindowFromPoint 也不返回它
    if (at.width <= 0 || at.height <= 0) return 0;
    int cx = 0, cy = 0;
    Window junk = 0;
    if (!XTranslateCoordinates(g_wpf.dpy, g_wpf.root, win, rx, ry, &cx, &cy, &junk)) return 0;
    return (cx >= 0 && cy >= 0 && cx < at.width && cy < at.height) ? 1 : 0;
}

// 本进程窗口判定：`wpf_window_find` **要求持锁** ⇒ 自己拿/放，且**刻意不跨 X 调用持锁**
//   （避免与 `win32_x11.c` 的 `XLOCK()` 之间形成锁序依赖）。`wpf_lock` 本身可重入。
static int wpf_is_own_window(Window win)
{
    wpf_lock();
    int own = (wpf_window_find((HWND)(uintptr_t)win) != NULL) ? 1 : 0;
    wpf_unlock();
    return own;
}

HWND WindowFromPoint(WPF_POINT pt)
{
    wpf_global_init();
    if (!wpf_x11_ensure()) return NULL;
    Window child = 0;
    // XTranslateCoordinates 到 root 的子窗口：拿到「最上层、含该点的窗口」——**注意**它可能是
    //   WM 的**框架**（有 WM 时就是），所以下面必须继续下沉（见上面的 `D-G64` 说明）。
    int rx = 0, ry = 0;
    XTranslateCoordinates(g_wpf.dpy, g_wpf.root, g_wpf.root,
                          pt.x, pt.y, &rx, &ry, &child);
    if (!child) return NULL;

    int own_top = wpf_is_own_window(child);
    HWND top = (HWND)(uintptr_t)child;
    HWND best = own_top ? top : NULL;    // 无 WM 的常规情形：顶层就是客户窗
    const char *d = getenv("WPF_LINUX_WFP_DIAG");
    int want_diag = (d && *d && *d != '0') ? 1 : 0;
    static int diag_n = 0;

    Window cur = child;
    int depth = 0;
    while (depth++ < 8) {                // 深度上限 8：防御性（正常 ≤ 2 层：框架 → 客户）
        Window r = 0, p = 0, *kids = NULL;
        unsigned int n = 0;
        if (!XQueryTree(g_wpf.dpy, cur, &r, &p, &kids, &n) || n == 0) {
            if (kids) XFree(kids);
            break;
        }
        Window hit = 0;
        for (int i = (int)n - 1; i >= 0; --i) {   // XQueryTree 的表**自下而上** ⇒ 从末尾（最上层）往回找
            if (wpf_point_in_window(kids[i], rx, ry)) { hit = kids[i]; break; }
        }
        XFree(kids);
        if (!hit) break;
        cur = hit;
        if (wpf_is_own_window(cur)) best = (HWND)(uintptr_t)cur;
    }

    HWND ret = best ? best : top;
    if (want_diag && diag_n++ < 40) {
        fprintf(stderr, "[WFP_DIAG] pt=%d,%d top=0x%lx own_top=%d ret=0x%lx depth=%d\n",
                pt.x, pt.y, (unsigned long)child, own_top,
                (unsigned long)(uintptr_t)ret, depth);
        fflush(stderr);
    }
    return ret;
}

BOOL EnumThreadWindows(uint32_t threadId, void *proc, LPARAM lParam)
{
    if (!proc) return 0;
    typedef BOOL (*cb_t)(HWND, LPARAM);
    wpf_lock();
    for (wpf_window *w = g_wpf.windows; w; w = w->next) {
        if (WPF_THREAD_ID(w->owner_thread) != threadId) continue;
        if (!((cb_t)proc)(w->hwnd, lParam)) break;
    }
    pthread_mutex_unlock(&g_wpf.lock);
    return 1;
}

// MapWindowPoints：把 cPoints 个点从 hWndFrom 的客户坐标系搬到 hWndTo 的客户坐标系。
// 我们没有非客户区，坐标系只差窗口原点，所以就是「加上 from 原点、减去 to 原点」。
// 注意 Win32 的语义：缓冲区被当作一个 **POINT 数组**，cPoints 是**点的个数**——
// 所以托管侧传 `ref RECT, cPoints=2` 时正好是「矩形的左上 + 右下」两个点，
// 一套实现同时覆盖 POINT / RECT / Win32Rect / Win32Point 四种声明。
int MapWindowPoints(HWND hWndFrom, HWND hWndTo, WPF_POINT *pts, int cPoints)
{
    wpf_global_init();
    if (!pts) return 0;
    int dx = 0, dy = 0;
    wpf_lock();
    if (hWndFrom && hWndFrom != HWND_DESKTOP) {
        wpf_window *w = wpf_window_find(hWndFrom);
        if (w) { dx -= w->x; dy -= w->y; }
    }
    if (hWndTo && hWndTo != HWND_DESKTOP) {
        wpf_window *w = wpf_window_find(hWndTo);
        if (w) { dx += w->x; dy += w->y; }
    }
    pthread_mutex_unlock(&g_wpf.lock);
    for (int i = 0; i < cPoints; i++) {
        pts[i].x += dx;
        pts[i].y += dy;
    }
    // Win32 返回值的低 16 位是 x 位移的绝对值、高 16 位是 y 的（坐标有符号，取绝对值）
    return (int)(((uint32_t)(dy < 0 ? -dy : dy) & 0xFFFF) << 16) |
           (int)((uint32_t)(dx < 0 ? -dx : dx) & 0xFFFF);
}

// PresentationNative_cor3.dll 的包装名（先 SetLastError(0) 再转发）
int MapWindowPointsWrapper(HWND from, HWND to, WPF_POINT *pts, int cPoints)
{
    wpf_set_last_error(0);
    return MapWindowPoints(from, to, pts, cPoints);
}

BOOL AdjustWindowRectEx(WPF_RECT *rc, uint32_t style, BOOL menu, uint32_t exStyle)
{
    // X11 下非客户区由 WM 负责，我们只有客户区 → 矩形不变。
    // 这正是「无 WM 时」的正确答案，不是空实现。
    (void)style; (void)menu; (void)exStyle;
    return rc ? 1 : 0;
}

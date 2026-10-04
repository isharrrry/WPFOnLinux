/* ═══════════════════════════════════════════════════════════════════════════
 * e3replay-probe.c —— `TASK-0009` E3「真重放夹具」的**装置**（探针）
 *
 * 【它干什么】把一个**真产品窗口**（走 `libwpfwin32.so` 的 Win32 ABI 建窗、
 *   走它的 `wpf_x11_pump_into_queue` 翻译事件）摆到私有 X 服务器上，然后：
 *     · 在**同一条 X 连接**（= 产品自己的连接，`WpfLinuxWin32_GetX11Display()`）
 *       上挂一条**同步被动按钮抓取**（`XGrabButton … GrabModeSync`）；
 *     · 由 `evdev/uinput` 注入**一条真按下**（服务器自产事件、真实时间戳）；
 *     · 抓到抓取投递那条 press 后调 `XAllowEvents(ReplayPointer)` ⇒ **服务器重放**，
 *       同一次物理按下**再投递一条** `ButtonPress`（`send_event=0`、`time` 相同）。
 *   ⇒ 产品的 `ButtonPress` 处理路径（`win32_x11.c` 客户区去重闸）就会看到
 *      「两条同 button press、中间无 release、`dt=0∈[0,bound]`」⇒ 去重闸**被行使**。
 *
 * 【为什么抓取必须挂在自己的连接上（本件最吃劲的一条发现）】
 *   同步被动抓取激活时，事件**投递给抓取者**；`XAllowEvents(ReplayPointer)` 之后
 *   服务器把**同一个事件重放**给"正常收件人"。所以：
 *     · 抓取者 == 产品自己  ⇒ 抓取投递 + 重放**两条都到达产品** ⇒ 闸看到 2 条；
 *     · 抓取者 == 第三方客户端 ⇒ 抓取投递给第三方、重放给产品 ⇒ 产品只看到 1 条。
 *   本仓侦察（`src/Linux/build/MilBridge/P1-tail2-e3-recon.md` §③-附）四条负向读数之所以
 *   都没造出第二条 press，是因为它把抓取挂在了**另建的客户端**上，而且用的是
 *   `GrabModeAsync`（async 不冻结 ⇒ `ReplayPointer` 无事可做）。
 *
 * 【反极性】`mode=nograb` 不挂抓取（= 去掉重放源）⇒ `cand` 必定为 0；
 *   环境变量 `WPF_E3_REPLAY_DEDUP=0` 把产品去重闸关掉 ⇒ `drop` 应为 0。
 *
 * 【用法（由 run-e3replay-probe.sh 驱动）】
 *   DISPLAY=:23N e3replay-probe <libwpfwin32.so> <grab|nograb>
 *   stdin 命令：`press` / `release` / `quit`
 * 读数：产品自己往 stderr 打 `[E3-REPLAY] …`（本装置不代它说话）。
 * ═══════════════════════════════════════════════════════════════════════════ */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <linux/uinput.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

/* ── 产品 Win32 ABI（逐字照 `src/WpfGfx.Linux.Native/src/win32_abi.h`） ─────── */
typedef void   *HWND, *HINSTANCE, *HMENU, *HICON, *HCURSOR, *HBRUSH, *HMODULE;
typedef uint32_t UINT;
typedef int32_t  BOOL;
typedef intptr_t WPARAM, LPARAM, LRESULT;
typedef LRESULT (*WNDPROC)(HWND, UINT, WPARAM, LPARAM);

typedef struct {
    int32_t cbSize, style;
    WNDPROC lpfnWndProc;
    int32_t cbClsExtra, cbWndExtra;
    HINSTANCE hInstance; HICON hIcon; HCURSOR hCursor; HBRUSH hbrBackground;
    uint16_t *lpszMenuName, *lpszClassName; HICON hIconSm;
} WNDCLASSEX_D;                       /* 80 字节 */

typedef struct {                      /* 48 字节 */
    HWND hwnd; uint32_t message, _pad0; WPARAM wParam; LPARAM lParam;
    uint32_t time; int32_t pt_x, pt_y; uint32_t _pad1;
} MSG;

#define WM_LBUTTONDOWN   0x0201
#define WM_LBUTTONUP     0x0202
#define WS_OVERLAPPEDWINDOW 0x00CF0000L
#define WS_VISIBLE       0x10000000L
#define SW_SHOW          5
#define PM_REMOVE        0x0001
#define HTCLIENT_DEFAULT 0

/* ── dlsym 面 ────────────────────────────────────────────────────────────── */
static int    (*p_EnsureX11)(void);
static void * (*p_GetX11Display)(void);
static int    (*p_GetX11ConnectionNumber)(void);
static unsigned long (*p_GetX11Window)(HWND);
static WNDPROC p_DefWindowProcW;
static uint16_t (*p_RegisterClassExW)(const WNDCLASSEX_D *);
static HWND   (*p_CreateWindowExW)(uint32_t, const uint16_t *, const uint16_t *, uint32_t,
                                   int32_t, int32_t, int32_t, int32_t, HWND, HMENU,
                                   HINSTANCE, void *);
static BOOL   (*p_ShowWindow)(HWND, int);
static BOOL   (*p_PeekMessageW)(MSG *, HWND, UINT, UINT, UINT);
static LRESULT(*p_DispatchMessageW)(const MSG *);

static Display *g_dpy;
static int      g_xfd = -1;
static Window   g_xwin;
static int      g_grab = 1;
static int      g_down_msg = 0, g_up_msg = 0, g_peeked = 0;
static int      g_frozen_expect = 0;     /* 1 = 下一条 WM_LBUTTONDOWN 到达时调 ReplayPointer */

static LRESULT probe_wndproc(HWND h, UINT m, WPARAM w, LPARAM l)
{
    if (m == WM_LBUTTONDOWN) {
        g_down_msg++;
        printf("PROBE msg=WM_LBUTTONDOWN seq=%d\n", g_down_msg);
        fflush(stdout);
        if (g_frozen_expect) {           /* 抓取投递那条 ⇒ 让服务器重放 */
            g_frozen_expect = 0;
            XAllowEvents(g_dpy, ReplayPointer, CurrentTime);
            XFlush(g_dpy);
            printf("PROBE allow_events=ReplayPointer\n");
            fflush(stdout);
        }
    } else if (m == WM_LBUTTONUP) {
        g_up_msg++;
        printf("PROBE msg=WM_LBUTTONUP seq=%d\n", g_up_msg);
        fflush(stdout);
    }
    return p_DefWindowProcW(h, m, w, l);      /* WM_NCHITTEST ⇒ 0 ⇒ HTCLIENT */
}

/* 有界泵：poll(X 连接) 等 25 ms → 由产品自己的 PeekMessageW/PM_REMOVE 拉一次
 * `wpf_x11_pump_into_queue` → 经 DispatchMessageW 派发。
 * ⚠️ 刻意**不用** `WpfLinuxWin32_PumpOnce`：本机该入口在 `timeout_ms>0` 且
 *   `wake_read` 与 `xfd` 双双有效时，会往 `struct pollfd fds[1]` 里塞第 2 项
 *   ⇒ glibc 的 `__poll_chk` 判"buffer overflow"并 `abort()`（fortify 构建）。
 *   这是**产品侧既存缺陷**（本件不改产品，只绕开它），在报告里具名。 */
static int pump_bounded(int budget_ms)
{
    int dispatched = 0;
    for (int spent = 0; spent < budget_ms; spent += 25) {
        if (g_xfd >= 0) {
            struct pollfd pfd;
            pfd.fd = g_xfd; pfd.events = POLLIN; pfd.revents = 0;
            poll(&pfd, 1, 25);
        }
        MSG msg;
        while (p_PeekMessageW(&msg, NULL, 0, 0, PM_REMOVE)) {
            g_peeked++;
            p_DispatchMessageW(&msg);
            dispatched++;
        }
    }
    return dispatched;
}

/* ── uinput 真鼠标 ───────────────────────────────────────────────────────── */
static int g_ufd = -1;

static void uinput_emit(int type, int code, int val)
{
    struct input_event ev;
    memset(&ev, 0, sizeof(ev));
    ev.type = type; ev.code = code; ev.value = val;
    if (write(g_ufd, &ev, sizeof(ev)) != sizeof(ev)) perror("write uinput");
}

static int uinput_open(const char *name)
{
    g_ufd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (g_ufd < 0) { perror("open /dev/uinput"); return -1; }
    ioctl(g_ufd, UI_SET_EVBIT, EV_KEY);
    ioctl(g_ufd, UI_SET_EVBIT, EV_REL);
    ioctl(g_ufd, UI_SET_EVBIT, EV_SYN);
    ioctl(g_ufd, UI_SET_KEYBIT, BTN_LEFT);
    ioctl(g_ufd, UI_SET_RELBIT, REL_X);
    ioctl(g_ufd, UI_SET_RELBIT, REL_Y);

    struct uinput_user_dev udev;
    memset(&udev, 0, sizeof(udev));
    snprintf(udev.name, UINPUT_MAX_NAME_SIZE, "%s", name);
    udev.id.bustype = BUS_USB; udev.id.vendor = 0x1234; udev.id.product = 0x5678; udev.id.version = 1;
    if (write(g_ufd, &udev, sizeof(udev)) != sizeof(udev)) { perror("write udev"); return -1; }
    if (ioctl(g_ufd, UI_DEV_CREATE) < 0) { perror("UI_DEV_CREATE"); return -1; }
    printf("PROBE dev_created name=%s\n", name);
    fflush(stdout);
    return 0;
}

#define P(...) do { printf(__VA_ARGS__); fflush(stdout); } while (0)

int main(int argc, char **argv)
{
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
    if (argc < 3) { fprintf(stderr, "usage: %s <libwpfwin32.so> <grab|nograb>\n", argv[0]); return 2; }
    const char *lib = argv[1];
    g_grab = (strcmp(argv[2], "nograb") != 0);

    void *h = dlopen(lib, RTLD_NOW | RTLD_GLOBAL);
    if (!h) { fprintf(stderr, "dlopen %s: %s\n", lib, dlerror()); return 2; }
    printf("PROBE lib=%s sha16=%s\n", lib, getenv("E3_LIB_SHA16") ? getenv("E3_LIB_SHA16") : "?");

#define SYM(v, n) do { *(void **)(&(v)) = dlsym(h, n); if (!(v)) { fprintf(stderr, "dlsym %s failed\n", n); return 2; } } while (0)
    SYM(p_EnsureX11,        "WpfLinuxWin32_EnsureX11");
    SYM(p_GetX11Display,    "WpfLinuxWin32_GetX11Display");
    SYM(p_GetX11ConnectionNumber, "WpfLinuxWin32_GetX11ConnectionNumber");
    SYM(p_GetX11Window,     "WpfLinuxWin32_GetX11Window");
    SYM(p_DefWindowProcW,   "DefWindowProcW");
    SYM(p_RegisterClassExW, "RegisterClassExW");
    SYM(p_CreateWindowExW,  "CreateWindowExW");
    SYM(p_ShowWindow,       "ShowWindow");
    SYM(p_PeekMessageW,     "PeekMessageW");
    SYM(p_DispatchMessageW, "DispatchMessageW");
#undef SYM

    if (!p_EnsureX11()) { fprintf(stderr, "EnsureX11 failed: DISPLAY=%s\n", getenv("DISPLAY")); return 2; }
    g_dpy = (Display *)p_GetX11Display();
    if (!g_dpy) { fprintf(stderr, "GetX11Display = NULL\n"); return 2; }
    g_xfd = p_GetX11ConnectionNumber();

    static const uint16_t cls[] = u"E3ReplayProbeCls";
    static const uint16_t title[] = u"e3replay-probe";
    WNDCLASSEX_D wc;
    memset(&wc, 0, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.style = 0;
    wc.lpfnWndProc = probe_wndproc;
    wc.lpszClassName = (uint16_t *)cls;
    if (!p_RegisterClassExW(&wc)) { fprintf(stderr, "RegisterClassExW failed\n"); return 2; }

    HWND hwnd = p_CreateWindowExW(0, cls, title, WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                                  0, 0, 400, 300, NULL, NULL, (HINSTANCE)(uintptr_t)0x7F000000, NULL);
    if (!hwnd) { fprintf(stderr, "CreateWindowExW failed\n"); return 2; }
    p_ShowWindow(hwnd, SW_SHOW);
    g_xwin = (Window)p_GetX11Window(hwnd);
    if (!g_xwin) { fprintf(stderr, "GetX11Window = 0\n"); return 2; }
    XSync(g_dpy, False);

    /* 有界等待：让窗口与其 map 走完一拍（第一帧 Expose 落定） */
    pump_bounded(400);
    printf("PROBE window=0x%lx mapped ok\n", (unsigned long)g_xwin);

    if (uinput_open(getenv("E3_DEV_NAME") ? getenv("E3_DEV_NAME") : "e3replay-mouse") != 0) return 3;

    if (g_grab) {
        int rc = XGrabButton(g_dpy, Button1, AnyModifier, g_xwin, False,
                             ButtonPressMask | ButtonReleaseMask,
                             GrabModeSync, GrabModeAsync, None, None);
        XSync(g_dpy, False);
        printf("PROBE grab_rc=%d pointer_mode=Sync owner_events=False win=0x%lx\n",
               rc, (unsigned long)g_xwin);
    } else {
        printf("PROBE grab=none（本腿＝去掉重放源的反极性）\n");
    }
    P("PROBE ready\n");

    char line[128];
    while (fgets(line, sizeof(line), stdin)) {
        if (!strncmp(line, "press", 5)) {
            /* 先把指针挪到窗口里（服务器侧 warp；与注入设备无关） */
            XWarpPointer(g_dpy, None, g_xwin, 0, 0, 0, 0, 200, 150);
            XSync(g_dpy, False);
            pump_bounded(50);
            g_frozen_expect = g_grab ? 1 : 0;
            uinput_emit(EV_KEY, BTN_LEFT, 1);
            uinput_emit(EV_SYN, SYN_REPORT, 0);
            P("PROBE injected=press\n");
            pump_bounded(1500);                       /* 有界：抓到重放/或只到 1 条 */
            P("PROBE after_press down_msgs=%d\n", g_down_msg);
        } else if (!strncmp(line, "release", 7)) {
            uinput_emit(EV_KEY, BTN_LEFT, 0);
            uinput_emit(EV_SYN, SYN_REPORT, 0);
            P("PROBE injected=release\n");
            pump_bounded(800);
            P("PROBE after_release up_msgs=%d\n", g_up_msg);
        } else if (!strncmp(line, "quit", 4)) {
            break;
        }
    }
    P("PROBE_RESULT mode=%s dedup=%s down_msgs=%d up_msgs=%d xwin=0x%lx\n",
      g_grab ? "grab" : "nograb",
      (getenv("WPF_E3_REPLAY_DEDUP") && getenv("WPF_E3_REPLAY_DEDUP")[0] == '0') ? "off" : "on",
      g_down_msg, g_up_msg, (unsigned long)g_xwin);
    if (g_ufd >= 0) { ioctl(g_ufd, UI_DEV_DESTROY); close(g_ufd); }
    return 0;
}

/* W184A · dev-selftest.c —— **装置自证**（不是产品、不是应用）
 *   作用：起一条**真** X 连接、发**真** wire 请求（ConfigureWindow op0=12 / MapWindow / CreateWindow），
 *   让 `xwrap*.so` 的协议级台账有东西可印 ⇒ 用来成对比较「旧装置 vs 新装置」的 `PROTO` 行。
 *   ⚠️ 本程序**必须**以 `dotnet` 为 basename 运行（装置只对 `/proc/self/exe` basename == dotnet 生效）：
 *      用法 = `cp dev-selftest /tmp/dev-selftest-dir/dotnet` 然后跑那个副本。
 *   用法：dev-selftest <display> <n_iters>
 */
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    if (argc < 3) { fprintf(stderr, "usage: dev-selftest <display> <iters>\n"); return 2; }
    Display *d = XOpenDisplay(argv[1]);
    if (!d) { fprintf(stderr, "SELFTEST=NOINFO reason=xopen-failed display=%s\n", argv[1]); return 3; }
    int scr = DefaultScreen(d);
    Window root = RootWindow(d, scr);
    int iters = atoi(argv[2]);
    Window w = XCreateSimpleWindow(d, root, 40, 40, 320, 240, 0,
                                   BlackPixel(d, scr), WhitePixel(d, scr));
    XStoreName(d, w, "w184a-dev-selftest");
    XMapWindow(d, w);
    XFlush(d);
    printf("SELFTEST_READY win=0x%lx display=%s iters=%d\n", (unsigned long)w, argv[1], iters);
    fflush(stdout);
    for (int i = 0; i < iters; i++) {
        XMoveResizeWindow(d, w, 100 + i * 3, 120 + i * 2, 400 + i * 4, 300 + i * 5);
        XFlush(d);
        usleep(120000);
    }
    usleep(300000);
    XDestroyWindow(d, w);
    XCloseDisplay(d);
    printf("SELFTEST_DONE\n");
    return 0;
}

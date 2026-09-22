/* ============================================================================
 * xprobe-hints.c —— `W81A` 两极化腿的**装置判别力自证**（与 WPF/shim **完全无关**）
 * ============================================================================
 *  为什么必须有它：本腿的读数面是 `xprop -id <xid> WM_NORMAL_HINTS`，而本趟的
 *  **正极性不成立**（声明上限也没出现 `PMaxSize`）—— 这时有两种解释分不开：
 *    (a) 被测件（shim/WPF）没把值送出去；
 *    (b) **我的读法**（`xprop` 的输出格式 / 我的 grep）看不见那个值。
 *  一个只读的判据必须能自证"看得见"。本件就是一个**裸 X 客户端**：它自己建窗、自己
 *  `XSetWMNormalHints`，两种模式成对：
 *    max   ⇒ `flags = PMinSize|PMaxSize`，`640x480`
 *    nomin ⇒ `flags = PMinSize`
 *  装置自证通过 = `max` 那窗的 `xprop` 里**出现** `program specified maximum size: 640 by 480`
 *  且 `nomin` 那窗**不出现** ⇒ 于是"未见 `PMaxSize`"是真的没发，不是我读不出来。
 *
 *  编译：`gcc -O0 -o xprobe-hints xprobe-hints.c -lX11`
 *  用法：`DISPLAY=:95 ./xprobe-hints max|nomin [hold_secs]`（stdout 印 `XPROBE xid=0x…`）
 * ==========================================================================*/
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    const char *mode = (argc > 1) ? argv[1] : "max";
    int hold = (argc > 2) ? atoi(argv[2]) : 20;
    Display *d = XOpenDisplay(NULL);
    if (!d) { fprintf(stderr, "XPROBE=NOINFO reason=no-display\n"); return 2; }
    int s = DefaultScreen(d);
    Window w = XCreateSimpleWindow(d, RootWindow(d, s), 0, 0, 300, 200, 0,
                                   BlackPixel(d, s), WhitePixel(d, s));
    XSizeHints sh;
    memset(&sh, 0, sizeof(sh));
    sh.flags = PMinSize;
    sh.min_width = 1; sh.min_height = 1;
    if (strcmp(mode, "max") == 0) {
        sh.flags |= PMaxSize;
        sh.max_width = 640; sh.max_height = 480;
    }
    XSetWMNormalHints(d, w, &sh);
    XMapWindow(d, w);
    XFlush(d);
    printf("XPROBE xid=0x%lx mode=%s flags=%s\n", (unsigned long)w, mode,
           (sh.flags & PMaxSize) ? "PMinSize|PMaxSize" : "PMinSize");
    fflush(stdout);
    sleep(hold);
    XCloseDisplay(d);
    return 0;
}

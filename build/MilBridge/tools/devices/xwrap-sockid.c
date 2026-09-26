/* ═══════════════════════════════════════════════════════════════════════════════
 * WC03 · xwrap.so —— X 请求级拦截器（**测量仪器**，不改产品）
 *
 *   目的：把"进程内到底谁发了那一次几何申请"变成读数。`W124A` 只在 X 侧看见
 *   "几何变了"，缺的正是"谁发的请求 + 调用链"。
 *
 *   做法：LD_PRELOAD 覆盖一组 Xlib 函数，每条调用打一行：
 *       T <epoch_us> rel=<ms> pid=<pid> tid=<tid> CALL <fn> <参数> | chain: ...
 *   `chain` 用 `backtrace()` + `dladdr()` 逐帧解成 `符号@模块+偏移` ⇒ **决定性帧**
 *   用来区分"shim 内部路径 / 托管侧 JIT / 别的模块"。
 *
 *   ⚠️ 只对 **`/proc/self/exe` basename == dotnet** 的进程生效（否则 xdotool/xprop/
 *      我的观测器自己也会被拦，日志会被别人的调用灌满）。
 *
 *   ⚠️ 本件**不改产品**：默认只**记录**、**放行**原函数。唯一的行为干预是**显式**打开
 *      的 `XWRAP_CUT`（`P-cut` 反极性实验，打 `CUT` 行），不设就一条都不丢。
 *
 *   自证（判据 §2.3）：拦截器条目数必须与外部观测器看到的几何跳变数逐项对齐。
 * ═══════════════════════════════════════════════════════════════════════════════ */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <execinfo.h>
#include <limits.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/uio.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>

#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#define MAXF 12

static int g_active = -1;          /* 1 = 本进程是 dotnet（记账），0 = 不是（立刻放行） */
static FILE *g_fp = NULL;
static struct timespec g_t0;
static __thread int g_in = 0;      /* 递归闸 */

static double now_rel_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (ts.tv_sec - g_t0.tv_sec) * 1000.0 + (ts.tv_nsec - g_t0.tv_nsec) / 1e6;
}
static long long now_epoch_us(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (long long)ts.tv_sec * 1000000LL + ts.tv_nsec / 1000;
}

__attribute__((constructor)) static void xwrap_init(void)
{
    clock_gettime(CLOCK_MONOTONIC, &g_t0);
    char exe[PATH_MAX];
    ssize_t n = readlink("/proc/self/exe", exe, sizeof(exe) - 1);
    if (n <= 0) { g_active = 0; return; }
    exe[n] = 0;
    const char *base = strrchr(exe, '/');
    base = base ? base + 1 : exe;
    if (strcmp(base, "dotnet") != 0) { g_active = 0; return; }
    const char *p = getenv("XWRAP_LOG");
    if (!p || !*p) { g_active = 0; return; }
    g_fp = fopen(p, "a");
    if (!g_fp) { g_active = 0; return; }
    setvbuf(g_fp, NULL, _IOLBF, 0);
    g_active = 1;
    fprintf(g_fp, "T %lld rel=%.3f pid=%d tid=%ld WRAP_INIT exe=%s\n",
            now_epoch_us(), now_rel_ms(), (int)getpid(), syscall(SYS_gettid), exe);
}

/* 前置声明（协议级 cut 的实现放在被拦函数之后，但 write/writev 要用到它） */
static size_t cp_patch(unsigned char *buf, size_t n, int fd);
static ssize_t write_all(int fd, const unsigned char *b, size_t n);
static unsigned char *iov_concat(const struct iovec *iov, int cnt, size_t *total);
static int xfd_is_x(int fd);

static const char *mod_short(const char *f)
{
    if (!f) return "?";
    const char *b = strrchr(f, '/');
    return b ? b + 1 : f;
}

/* 调用链：[self] <- <sym@mod+off> <- ... */
static void chain(char *out, size_t cap)
{
    void *bt[MAXF];
    int n = backtrace(bt, MAXF);
    size_t off = 0;
    off += (size_t)snprintf(out + off, cap - off, "[hook]");
    for (int i = 1; i < n && off < cap - 8; i++) {
        Dl_info di;
        if (dladdr(bt[i], &di) && di.dli_fname) {
            if (di.dli_sname)
                off += (size_t)snprintf(out + off, cap - off, " <- %s@%s+0x%lx",
                                        di.dli_sname, mod_short(di.dli_fname),
                                        (unsigned long)((char *)bt[i] - (char *)di.dli_saddr));
            else
                off += (size_t)snprintf(out + off, cap - off, " <- %s+0x%lx",
                                        mod_short(di.dli_fname),
                                        (unsigned long)((char *)bt[i] - (char *)di.dli_fbase));
        } else {
            off += (size_t)snprintf(out + off, cap - off, " <- <jit/anon>");
        }
    }
}

static void logline(const char *fmt, ...)
{
    if (!g_active || g_in) return;
    g_in = 1;
    char msg[1024];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(msg, sizeof(msg), fmt, ap);
    va_end(ap);
    char ch[2048];
    chain(ch, sizeof(ch));
    /* 只把"有我关心的模块"的链打全，避免噪声（仍然逐帧打，不裁剪） */
    fprintf(g_fp, "T %lld rel=%.3f pid=%d tid=%ld %s | chain: %s\n",
            now_epoch_us(), now_rel_ms(), (int)getpid(), syscall(SYS_gettid), msg, ch);
    fflush(g_fp);
    g_in = 0;
}

static const char *atomname(Display *d, Atom a)
{
    /* 环 8 个缓冲：一行里可能要解析 3 个原子（message_type/d1/d2），2 个会被覆写 */
    static __thread char buf[8][128];
    static __thread int k = 0;
    k = (k + 1) & 7;
    if (!a) { snprintf(buf[k], sizeof(buf[k]), "None"); return buf[k]; }
    char *s = XGetAtomName(d, a);
    if (s) { snprintf(buf[k], sizeof(buf[k]), "%s", s); XFree(s); }
    else   { snprintf(buf[k], sizeof(buf[k]), "#%lu", (unsigned long)a); }
    return buf[k];
}

/* ── CUT（P-cut，装置侧干预；不设就一条都不丢）─────────────────────────────── */
static int cut_on = -1;
static double cut_tmin = 0, cut_tmax = 0;
static unsigned cut_w = 0, cut_h = 0;
static char cut_fn[40] = "";
static void cut_init(void)
{
    const char *e = getenv("XWRAP_CUT");
    if (!e || !*e) { cut_on = 0; return; }
    cut_on = 1;
    const char *p;
    if ((p = strstr(e, "tmin="))) cut_tmin = atof(p + 5);
    if ((p = strstr(e, "tmax="))) cut_tmax = atof(p + 5);
    if ((p = strstr(e, "W=")))    cut_w = (unsigned)strtoul(p + 2, NULL, 10);
    if ((p = strstr(e, "H=")))    cut_h = (unsigned)strtoul(p + 2, NULL, 10);
    if ((p = strstr(e, "fn=")))   sscanf(p + 3, "%39[A-Za-z_]", cut_fn);
}
/* 判据：时间窗 ∧（可选）函数名 ∧（可选）W/H */
static int cut_match(const char *fn, unsigned w, unsigned h)
{
    if (cut_on < 0) cut_init();
    if (!cut_on) return 0;
    double t = now_rel_ms() / 1000.0;
    if (t < cut_tmin || t > cut_tmax) return 0;
    if (cut_fn[0] && strcmp(cut_fn, fn) != 0) return 0;
    if (cut_w && w != cut_w) return 0;
    if (cut_h && h != cut_h) return 0;
    return 1;
}

/* ═══════════════ 被拦的函数 ═══════════════ */
int XMoveResizeWindow(Display *d, Window w, int x, int y, unsigned width, unsigned height)
{
    static int (*real)(Display *, Window, int, int, unsigned, unsigned);
    if (!real) real = dlsym(RTLD_NEXT, "XMoveResizeWindow");
    if (g_active && !g_in)
        logline("CALL XMoveResizeWindow win=0x%lx x=%d y=%d W=%u H=%u", (unsigned long)w, x, y, width, height);
    if (g_active && cut_match("XMoveResizeWindow", width, height)) {
        logline("CUT XMoveResizeWindow win=0x%lx x=%d y=%d W=%u H=%u （装置侧丢弃，非产品行为）",
                (unsigned long)w, x, y, width, height);
        return 0;
    }
    return real(d, w, x, y, width, height);
}

int XMoveWindow(Display *d, Window w, int x, int y)
{
    static int (*real)(Display *, Window, int, int);
    if (!real) real = dlsym(RTLD_NEXT, "XMoveWindow");
    if (g_active && !g_in)
        logline("CALL XMoveWindow win=0x%lx x=%d y=%d", (unsigned long)w, x, y);
    return real(d, w, x, y);
}

int XResizeWindow(Display *d, Window w, unsigned width, unsigned height)
{
    static int (*real)(Display *, Window, unsigned, unsigned);
    if (!real) real = dlsym(RTLD_NEXT, "XResizeWindow");
    if (g_active && !g_in)
        logline("CALL XResizeWindow win=0x%lx W=%u H=%u", (unsigned long)w, width, height);
    if (g_active && cut_match("XResizeWindow", width, height)) {
        logline("CUT XResizeWindow win=0x%lx W=%u H=%u （装置侧丢弃，非产品行为）", (unsigned long)w, width, height);
        return 0;
    }
    return real(d, w, width, height);
}

int XConfigureWindow(Display *d, Window w, unsigned mask, XWindowChanges *ch)
{
    static int (*real)(Display *, Window, unsigned, XWindowChanges *);
    if (!real) real = dlsym(RTLD_NEXT, "XConfigureWindow");
    if (g_active && !g_in) {
        char b[256];
        int o = 0;
        b[0] = 0;
        if (mask & CWX)      o += snprintf(b + o, sizeof(b) - o, " x=%d", ch->x);
        if (mask & CWY)      o += snprintf(b + o, sizeof(b) - o, " y=%d", ch->y);
        if (mask & CWWidth)  o += snprintf(b + o, sizeof(b) - o, " W=%d", ch->width);
        if (mask & CWHeight) o += snprintf(b + o, sizeof(b) - o, " H=%d", ch->height);
        logline("CALL XConfigureWindow win=0x%lx mask=0x%x%s", (unsigned long)w, mask, b);
    }
    return real(d, w, mask, ch);
}

int XSendEvent(Display *d, Window w, Bool prop, long mask, XEvent *ev)
{
    static int (*real)(Display *, Window, Bool, long, XEvent *);
    if (!real) real = dlsym(RTLD_NEXT, "XSendEvent");
    if (g_active && !g_in && ev) {
        if (ev->type == ClientMessage) {
            XClientMessageEvent *cm = (XClientMessageEvent *)ev;
            logline("CALL XSendEvent win=0x%lx prop=%d mask=0x%lx ClientMessage type=%s fmt=%d d0=%ld d1=%s d2=%s d3=%ld d4=%ld",
                    (unsigned long)w, (int)prop, mask, atomname(d, cm->message_type), cm->format,
                    (long)cm->data.l[0], atomname(d, (Atom)cm->data.l[1]), atomname(d, (Atom)cm->data.l[2]),
                    (long)cm->data.l[3], (long)cm->data.l[4]);
        } else {
            logline("CALL XSendEvent win=0x%lx prop=%d mask=0x%lx type=%d", (unsigned long)w, (int)prop, mask, ev->type);
        }
    }
    if (g_active && cut_match("XSendEvent", 0, 0)) {
        logline("CUT XSendEvent win=0x%lx （装置侧丢弃，非产品行为）", (unsigned long)w);
        return 0;
    }
    return real(d, w, prop, mask, ev);
}

int XChangeProperty(Display *d, Window w, Atom prop, Atom type, int fmt, int mode,
                    const unsigned char *data, int nelem)
{
    static int (*real)(Display *, Window, Atom, Atom, int, int, const unsigned char *, int);
    if (!real) real = dlsym(RTLD_NEXT, "XChangeProperty");
    if (g_active && !g_in)
        logline("CALL XChangeProperty win=0x%lx prop=%s type=%s fmt=%d mode=%d n=%d",
                (unsigned long)w, atomname(d, prop), atomname(d, type), fmt, mode, nelem);
    if (g_active && cut_match("XChangeProperty", 0, 0)) {
        logline("CUT XChangeProperty win=0x%lx prop=%s （装置侧丢弃，非产品行为）",
                (unsigned long)w, atomname(d, prop));
        return 0;
    }
    return real(d, w, prop, type, fmt, mode, data, nelem);
}

void XSetWMNormalHints(Display *d, Window w, XSizeHints *h)
{
    static void (*real)(Display *, Window, XSizeHints *);
    if (!real) real = dlsym(RTLD_NEXT, "XSetWMNormalHints");
    if (g_active && !g_in && h)
        logline("CALL XSetWMNormalHints win=0x%lx flags=0x%lx min=%dx%d max=%dx%d base=%dx%d",
                (unsigned long)w, (unsigned long)h->flags,
                (int)((h->flags & PMinSize) ? h->min_width : -1), (int)((h->flags & PMinSize) ? h->min_height : -1),
                (int)((h->flags & PMaxSize) ? h->max_width : -1), (int)((h->flags & PMaxSize) ? h->max_height : -1),
                (int)((h->flags & PBaseSize) ? h->base_width : -1), (int)((h->flags & PBaseSize) ? h->base_height : -1));
    real(d, w, h);
}

int XMapWindow(Display *d, Window w)
{
    static int (*real)(Display *, Window);
    if (!real) real = dlsym(RTLD_NEXT, "XMapWindow");
    if (g_active && !g_in) logline("CALL XMapWindow win=0x%lx", (unsigned long)w);
    if (g_active && cut_match("XMapWindow", 0, 0)) {
        logline("CUT XMapWindow win=0x%lx （装置侧丢弃，非产品行为）", (unsigned long)w);
        return 0;
    }
    return real(d, w);
}

int XUnmapWindow(Display *d, Window w)
{
    static int (*real)(Display *, Window);
    if (!real) real = dlsym(RTLD_NEXT, "XUnmapWindow");
    if (g_active && !g_in) logline("CALL XUnmapWindow win=0x%lx", (unsigned long)w);
    if (g_active && cut_match("XUnmapWindow", 0, 0)) {
        logline("CUT XUnmapWindow win=0x%lx （装置侧丢弃，非产品行为）", (unsigned long)w);
        return 0;
    }
    return real(d, w);
}

/* ═══════════ 协议级台账（socket 写）—— 符号级拦截的补充 ═══════════
 *   为什么需要：若某个 Xlib **包装函数**（如 `XReconfigureWMWindow`）在 libX11 **内部**
 *   调用了被 hook 的原语，而 libX11 是 `-Bsymbolic-functions` 构建的（Debian 默认），
 *   那么那次调用**不会**经过 PLT ⇒ 我的符号级 hook 看不见。
 *   对策：直接拦 `write/send/sendmsg/writev`，凡目标是"X 连接的 unix socket"就把
 *   前 12 字节打出来（第 1 字节 = X 请求 opcode：12=ConfigureWindow、8=MapWindow、
 *   25=SendEvent、18=ChangeProperty、42=SetInputFocus…）⇒ **协议级**读数，
 *   与符号级台账互为独立仪器。 */
static int xfd_is_x(int fd)
{
    struct sockaddr_un sa;
    socklen_t l = sizeof(sa);
    memset(&sa, 0, sizeof(sa));
    if (getpeername(fd, (struct sockaddr *)&sa, &l) != 0) return 0;
    if (sa.sun_family != AF_UNIX) return 0;
    const char *nm = (sa.sun_path[0] == 0) ? sa.sun_path + 1 : sa.sun_path;
    return strstr(nm, ".X11-unix/") != NULL;
}
static void hexhead(const unsigned char *b, size_t n, char *out, size_t cap)
{
    size_t hn = n < 64 ? n : 64, o = 0;
    for (size_t i = 0; i < hn && o + 4 < cap; i++) o += (size_t)snprintf(out + o, cap - o, "%02x ", b[i]);
    out[o] = 0;
}
/* ═══════════ 随行 socket 身份（`TASK-0744-FU`；W184A 新增）═══════════════════════
 *   为什么：`TASK-0744` 的牙 `PROTO-ATTR` 要断"这条请求是在一条 **X socket** 上写的"，
 *   旧装置**只印 `fd=<n>`** ⇒ 该格**结构性不可达** ⇒ 真腿只能 `NOINFO reason=sock-id-absent`。
 *   本函数把 **fd → socket inode**（`fstat`，**不看 `/proc`**）＋ `SO_PEERCRED` 的 `pid:uid:gid`
 *   在**同一次写**里取到并**追加**到 `PROTO` 行尾。三条身份证据同时印：
 *     `sock=<inode>`（非数字 ⇒ 显式 `-`，**不省略字段**）`peer=<pid:uid:gid>` `sk=<sock|nonsock|eBADF>`
 *   ⚠️ 只**追加**：既有 `PROTO fd= n= op0= head=` 那段**逐字节不变**（旧读者不受影响）。
 *   ⚠️ 每条 `PROTO` 行**只有一次 `fd=` 出现**（身份字段用 `sock=`/`peer=`/`sk=` 三个**新**键）——
 *      这样 `fd=([0-9]+)` 这类既有正则**命中集不变**。 */
static void sock_ident(int fd, char *out, size_t cap)
{
    struct stat st;
    char ino[32] = "-";
    const char *sk = "?";
    if (fstat(fd, &st) == 0) {
        if (S_ISSOCK(st.st_mode)) {
            sk = "sock";
            snprintf(ino, sizeof(ino), "%llu", (unsigned long long)st.st_ino);
        } else {
            sk = "nonsock";
        }
    } else {
        sk = (errno == EBADF) ? "eBADF" : "eERR";
    }
    char peer[64] = "-";
    struct ucred cr;
    socklen_t cl = sizeof(cr);
    memset(&cr, 0, sizeof(cr));
    if (getsockopt(fd, SOL_SOCKET, SO_PEERCRED, &cr, &cl) == 0)
        snprintf(peer, sizeof(peer), "%d:%u:%u", (int)cr.pid, (unsigned)cr.uid, (unsigned)cr.gid);
    snprintf(out, cap, "sock=%s peer=%s sk=%s", ino, peer, sk);
}
static void proto_log(int fd, const void *buf, size_t n)
{
    if (!g_active || g_in || !n) return;
    if (!xfd_is_x(fd)) return;
    char head[256];
    hexhead((const unsigned char *)buf, n, head, sizeof(head));
    char id[160];
    sock_ident(fd, id, sizeof(id));
    logline("PROTO fd=%d n=%zu op0=%u head=%s %s", fd, n, (unsigned)((const unsigned char *)buf)[0], head, id);
}
ssize_t write(int fd, const void *buf, size_t n)
{
    static ssize_t (*real)(int, const void *, size_t);
    if (!real) real = dlsym(RTLD_NEXT, "write");
    if (g_active && !g_in) {
        proto_log(fd, buf, n);
        if (n && xfd_is_x(fd)) {
            unsigned char *tmp = malloc(n);
            if (tmp) {
                memcpy(tmp, buf, n);
                if (cp_patch(tmp, n, fd)) { ssize_t r = write_all(fd, tmp, n); free(tmp); return r; }
                free(tmp);
            }
        }
    }
    return real(fd, buf, n);
}
ssize_t send(int fd, const void *buf, size_t n, int flags)
{
    static ssize_t (*real)(int, const void *, size_t, int);
    if (!real) real = dlsym(RTLD_NEXT, "send");
    if (g_active && !g_in) proto_log(fd, buf, n);
    return real(fd, buf, n, flags);
}
ssize_t sendmsg(int fd, const struct msghdr *msg, int flags)
{
    static ssize_t (*real)(int, const struct msghdr *, int);
    if (!real) real = dlsym(RTLD_NEXT, "sendmsg");
    if (g_active && !g_in && msg && msg->msg_iovlen > 0 && msg->msg_iov) {
        size_t tot = 0;
        unsigned char *cat = iov_concat(msg->msg_iov, (int)msg->msg_iovlen, &tot);
        if (cat) {
            proto_log(fd, cat, tot);
            if (xfd_is_x(fd) && cp_patch(cat, tot, fd)) {
                ssize_t r = write_all(fd, cat, tot);
                free(cat);
                return r;
            }
            free(cat);
        }
    }
    return real(fd, msg, flags);
}
ssize_t writev(int fd, const struct iovec *iov, int cnt)
{
    static ssize_t (*real)(int, const struct iovec *, int);
    if (!real) real = dlsym(RTLD_NEXT, "writev");
    if (g_active && !g_in && cnt > 0 && iov) {
        size_t tot = 0;
        unsigned char *cat = iov_concat(iov, cnt, &tot);
        if (cat) {
            proto_log(fd, cat, tot);
            if (xfd_is_x(fd) && cp_patch(cat, tot, fd)) { ssize_t r = write_all(fd, cat, tot); free(cat); return r; }
            free(cat);
        } else {
            proto_log(fd, iov[0].iov_base, iov[0].iov_len);
        }
    }
    return real(fd, iov, cnt);
}

/* ═══════════ 协议级 P-cut：把命中的 ConfigureWindow **在线上**换成等长 NoOperation ═══════════
 *   为什么必须"等长替换"而不是"丢掉"：X 客户端与服务器各自按**请求条数**计数序号，
 *   少一条会让后续带回复的请求串号（经典 request-dropping 代理事故）。
 *   `NoOperation`（opcode 127）可带任意长度 ⇒ 保证"条数不变、长度不变、只有语义变成空操作"。
 *   命中模式（含窗口 id，避免像素数据误命中）：`0c ?? 05 00 <win:4>`（= ConfigureWindow，5 个 4 字节单元 = 20 B）。
 *   读数：逐条打 `CUT_PROTO …`（含时间、fd、窗口、原 mask）。 */
static int cp_on = -1;
static double cp_tmin = 0, cp_tmax = 0;
static unsigned long cp_win = 0;
static void cp_init(void)
{
    const char *e = getenv("XWRAP_CUT_PROTO");
    if (!e || !*e) { cp_on = 0; return; }
    cp_on = 1;
    const char *p;
    if ((p = strstr(e, "tmin="))) cp_tmin = atof(p + 5);
    if ((p = strstr(e, "tmax="))) cp_tmax = atof(p + 5);
    if ((p = strstr(e, "window="))) cp_win = strtoul(p + 7, NULL, 16);
}
/* 返回被改掉的字节数（0 = 没改）。`buf` 是**可写**的本地拼接缓冲。 */
static size_t cp_patch(unsigned char *buf, size_t n, int fd)
{
    if (cp_on < 0) cp_init();
    if (!cp_on) return 0;
    double t = now_rel_ms() / 1000.0;
    if (t < cp_tmin || t > cp_tmax) return 0;
    /* 只在**缓冲区起点**（= 一次 write 里第一条请求）判，且要求长度与 mask 的位数**自洽**：
     *   ConfigureWindow 的 rl 必为 `12 + 4*popcount(mask)`。
     *   ⚠️ 为什么加这条（自伤登记）：初版按"任意偏移命中 `0c ?? <len> 00`"扫，
     *   在 **41880 字节的像素负载**里误命中过（win=0x0／0xc0c0c… 明显是像素），
     *   把 48 字节像素线上改成了 NoOperation —— 不改几何、但**改渲染内容**。
     *   加了"起点 ＋ 长度自洽 ＋ win 非 0 ＋ mask 非 0"三条后误命中不可构造。 */
    if (n < 12 || buf[0] != 0x0c) return 0;
    size_t rl = ((size_t)buf[2] | ((size_t)buf[3] << 8)) * 4;
    if (rl < 16 || rl > 64 || rl > n) return 0;
    unsigned long win = (unsigned long)buf[4] | ((unsigned long)buf[5] << 8) |
                        ((unsigned long)buf[6] << 16) | ((unsigned long)buf[7] << 24);
    if (!win) return 0;
    unsigned mask = (unsigned)buf[8] | ((unsigned)buf[9] << 8);
    if (!mask || (mask & ~0x3fffu)) return 0;
    int bits = 0; for (unsigned m = mask; m; m >>= 1) bits += (int)(m & 1u);
    if (rl != 12 + 4 * (size_t)bits) return 0;
    if (cp_win && win != cp_win) return 0;
    logline("CUT_PROTO fd=%d off=0 win=0x%lx mask=0x%x len=%zu t=%.3f（装置侧线上替换为等长 NoOperation，非产品行为）",
            fd, win, mask, rl, t);
    buf[0] = 127; buf[1] = 0;
    buf[2] = (unsigned char)((rl / 4) & 0xff);
    buf[3] = (unsigned char)(((rl / 4) >> 8) & 0xff);
    memset(buf + 4, 0, rl - 4);
    return rl;
}
/* 把 iovec 拼起来（供 cut 用） */
static unsigned char *iov_concat(const struct iovec *iov, int cnt, size_t *total)
{
    size_t n = 0;
    for (int i = 0; i < cnt; i++) n += iov[i].iov_len;
    if (n == 0 || n > (1u << 20)) { *total = 0; return NULL; }
    unsigned char *b = malloc(n);
    if (!b) { *total = 0; return NULL; }
    size_t o = 0;
    for (int i = 0; i < cnt; i++) { memcpy(b + o, iov[i].iov_base, iov[i].iov_len); o += iov[i].iov_len; }
    *total = n;
    return b;
}
static ssize_t write_all(int fd, const unsigned char *b, size_t n)
{
    size_t o = 0;
    while (o < n) {
        ssize_t r = syscall(SYS_write, fd, b + o, n - o);
        if (r <= 0) return r;
        o += (size_t)r;
    }
    return (ssize_t)o;
}

/* 补齐符号级面：可能改几何/焦点/父窗的其余导出 */
int XSetWindowBorderWidth(Display *d, Window w, unsigned bw)
{
    static int (*real)(Display *, Window, unsigned);
    if (!real) real = dlsym(RTLD_NEXT, "XSetWindowBorderWidth");
    if (g_active && !g_in) logline("CALL XSetWindowBorderWidth win=0x%lx bw=%u", (unsigned long)w, bw);
    return real(d, w, bw);
}
int XReparentWindow(Display *d, Window w, Window p, int x, int y)
{
    static int (*real)(Display *, Window, Window, int, int);
    if (!real) real = dlsym(RTLD_NEXT, "XReparentWindow");
    if (g_active && !g_in) logline("CALL XReparentWindow win=0x%lx parent=0x%lx %d,%d", (unsigned long)w, (unsigned long)p, x, y);
    return real(d, w, p, x, y);
}
int XSetInputFocus(Display *d, Window w, int revert, Time t)
{
    static int (*real)(Display *, Window, int, Time);
    if (!real) real = dlsym(RTLD_NEXT, "XSetInputFocus");
    if (g_active && !g_in) logline("CALL XSetInputFocus win=0x%lx", (unsigned long)w);
    return real(d, w, revert, t);
}
int XRaiseWindow(Display *d, Window w)
{
    static int (*real)(Display *, Window);
    if (!real) real = dlsym(RTLD_NEXT, "XRaiseWindow");
    if (g_active && !g_in) logline("CALL XRaiseWindow win=0x%lx", (unsigned long)w);
    return real(d, w);
}

int XFlush(Display *d)
{
    static int (*real)(Display *);
    if (!real) real = dlsym(RTLD_NEXT, "XFlush");
    if (g_active && !g_in) logline("CALL XFlush");
    return real(d);
}

int XSync(Display *d, Bool discard)
{
    static int (*real)(Display *, Bool);
    if (!real) real = dlsym(RTLD_NEXT, "XSync");
    if (g_active && !g_in) logline("CALL XSync discard=%d", (int)discard);
    return real(d, discard);
}

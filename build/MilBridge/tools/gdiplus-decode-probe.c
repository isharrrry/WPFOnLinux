// ============================================================================
// gdiplus-decode-probe.c —— `gdiplus.dll` 图像族（`#41` F）的**判据探针**
// ============================================================================
//
// 【为什么是 C 探针、而不是托管用例】GDI+ 面对第三方应用的意义就是"**别人直接 P/Invoke
//   `gdiplus.dll`**"。用 C 直接 `dlopen` 我们那个 `libwpfwin32.so` 并逐入口调用，
//   与真实调用方的形态**同构**（不经 .NET 解析器这一层），也就顺带验证了"这个面本身"
//   （而不是"托管侧能不能调通"）。
//
// 【判据（逐例 status 精确比对，不合并成"反正失败了"）】
//   ① 正极性：一个已知尺寸/颜色的 PNG ⇒ `Ok`，且 `宽度/高度` **逐值相等**、
//      抽样像素的 RGB **逐位相等**、`LockBits` 的 `Scan0` 非空且 `Stride ≥ w*4`；
//   ② 反极性 A：不存在的路径 ⇒ 必须 `FileNotFound(10)`（**不许** Ok，也不许别的码）；
//   ③ 反极性 B：随机字节（伪装成 PNG）⇒ 必须 `UnknownImageFormat(13)`；
//   ④ 反极性 C：保存族 ⇒ 必须 `NotImplemented(6)`（**如实失败**，不许假装成功）；
//   ⑤ 生命周期：`Dispose` 两次 ⇒ 第二次是 no-op `Ok`（不许崩）。
//   ⚠️ ①的关键在于它查的是**内容**（尺寸 + 像素 + 行距），不只是"状态码是 0" ——
//      一个"什么都返回 Ok 的撒谎 shim"必须在这里被打红（`--selftest` 就干这个）。
//
// 用法：gdiplus-decode-probe <libwpfwin32.so> <png 路径> <期望宽> <期望高> <期望RGB(十六进制 6 位)>
// ============================================================================

#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef int32_t GpStatus;
#define Ok 0
#define InvalidParameter 2
#define NotImplemented 6
#define FileNotFound 10
#define UnknownImageFormat 13

typedef struct { int32_t width, height, stride, pixelFormat; unsigned char *scan0; void *reserved; } BitmapData;

static int g_pass, g_fail;

static void case_status(const char *name, GpStatus got, GpStatus want)
{
    int ok = (got == want);
    if (ok) g_pass++; else g_fail++;
    printf("GDIPLUS_CASE=%-22s status=%d expect=%d verdict=%s\n", name, got, want, ok ? "PASS" : "FAIL");
}
static void case_bool(const char *name, int cond, const char *detail)
{
    if (cond) g_pass++; else g_fail++;
    printf("GDIPLUS_CASE=%-22s %s verdict=%s\n", name, detail, cond ? "PASS" : "FAIL");
}

int main(int argc, char **argv)
{
    if (argc != 7) {
        fprintf(stderr, "用法: %s <libwpfwin32.so> <png> <期望宽> <期望高> <期望RGB十六进制> <损坏文件>\n", argv[0]);
        return 3;
    }
    const char *lib = argv[1], *png = argv[2];
    int want_w = atoi(argv[3]), want_h = atoi(argv[4]);
    unsigned long want_rgb = strtoul(argv[5], NULL, 16);

    void *h = dlopen(lib, RTLD_NOW | RTLD_LOCAL);
    if (!h) { printf("GDIPLUS_PROBE=NOINFO reason=dlopen-failed %s\n", dlerror()); return 2; }

    GpStatus (*p_startup)(void **, const void *, void *) = dlsym(h, "GdiplusStartup");
    GpStatus (*p_load)(const uint16_t *, void **) = dlsym(h, "GdipLoadImageFromFile");
    GpStatus (*p_getw)(void *, uint32_t *) = dlsym(h, "GdipGetImageWidth");
    GpStatus (*p_geth)(void *, uint32_t *) = dlsym(h, "GdipGetImageHeight");
    GpStatus (*p_getpx)(void *, int32_t, int32_t, uint32_t *) = dlsym(h, "GdipBitmapGetPixel");
    GpStatus (*p_lock)(void *, void *, uint32_t, int32_t, BitmapData *) = dlsym(h, "GdipBitmapLockBits");
    GpStatus (*p_save)(void *, const uint16_t *, void *, void *) = dlsym(h, "GdipSaveImageToFile");
    GpStatus (*p_dispose)(void *) = dlsym(h, "GdipDisposeImage");
    if (!p_startup || !p_load || !p_getw || !p_geth || !p_getpx || !p_lock || !p_save || !p_dispose) {
        printf("GDIPLUS_PROBE=NOINFO reason=missing-symbols\n"); return 2;
    }

    void *tok = NULL;
    case_status("startup", p_startup(&tok, NULL, NULL), Ok);

    /* UTF-16 路径（GDI+ 的 ABI 是 WCHAR*） */
    size_t n = strlen(png);
    uint16_t *wpath = calloc(n + 1, sizeof(uint16_t));
    for (size_t i = 0; i < n; i++) wpath[i] = (uint16_t)(unsigned char)png[i];

    /* ① 正极性：真解码 + 内容核对 */
    void *img = NULL;
    GpStatus st = p_load(wpath, &img);
    case_status("load-existing", st, Ok);
    if (st == Ok) {
        uint32_t w = 0, hh = 0;
        case_status("get-width", p_getw(img, &w), Ok);
        case_status("get-height", p_geth(img, &hh), Ok);
        char det[128];
        snprintf(det, sizeof det, "got=%ux%u want=%dx%d", w, hh, want_w, want_h);
        case_bool("dims-match", (int)w == want_w && (int)hh == want_h, det);

        uint32_t px = 0;
        GpStatus pst = p_getpx(img, 0, 0, &px);
        case_status("get-pixel-0-0", pst, Ok);
        snprintf(det, sizeof det, "argb=%08x want_rgb=%06lx", px, want_rgb);
        case_bool("pixel-match", pst == Ok && (px & 0x00FFFFFFul) == (want_rgb & 0x00FFFFFFul), det);

        BitmapData bd; memset(&bd, 0, sizeof bd);
        GpStatus lst = p_lock(img, NULL, 0, 0, &bd);
        case_status("lock-bits", lst, Ok);
        snprintf(det, sizeof det, "scan0=%s stride=%d", bd.scan0 ? "non-null" : "NULL", bd.stride);
        case_bool("lock-scan0-stride", lst == Ok && bd.scan0 && bd.stride >= (int)w * 4, det);
    }

    /* ② 反极性 A：不存在的路径 */
    const char *missing = "/nonexistent/definitely-not-here.png";
    size_t mn = strlen(missing);
    uint16_t *wmiss = calloc(mn + 1, sizeof(uint16_t));
    for (size_t i = 0; i < mn; i++) wmiss[i] = (uint16_t)(unsigned char)missing[i];
    void *bogus = NULL;
    case_status("load-missing", p_load(wmiss, &bogus), FileNotFound);

    /* ③ 反极性 B：随机字节（伪装成 PNG）—— 由 runner 生成并作为第 6 个参数传入 */
    {
        const char *junk = argv[6];
        size_t jn = strlen(junk);
        uint16_t *wjunk = calloc(jn + 1, sizeof(uint16_t));
        for (size_t i = 0; i < jn; i++) wjunk[i] = (uint16_t)(unsigned char)junk[i];
        void *jimg = NULL;
        case_status("load-corrupt", p_load(wjunk, &jimg), UnknownImageFormat);
    }

    /* ④ 反极性 C：保存族必须如实失败 */
    if (img) case_status("save-honest-fail", p_save(img, wpath, NULL, NULL), NotImplemented);

    /* ⑤ 生命周期：两次 Dispose 不许崩 */
    if (img) {
        case_status("dispose-1", p_dispose(img), Ok);
        case_status("dispose-2-idempotent", p_dispose(img), Ok);
    }

    printf("GDIPLUS_PROBE=%s pass=%d fail=%d\n", g_fail == 0 ? "PASS" : "FAIL", g_pass, g_fail);
    return g_fail == 0 ? 0 : 1;
}

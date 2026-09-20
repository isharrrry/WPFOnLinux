// ============================================================================
// gdiplus-liar.c —— **撒谎 shim**（`#41` F 探针的**反极性装置**，只用于 `--selftest`）
// ============================================================================
// 【它是什么】一个把 GDI+ 图像族**全部返回 `Ok`** 的假实现：不解码、不核对，
//   宽度/高度固定答 1×1、`LockBits` 给 NULL 扫描线 —— 也就是"**假装成功**"。
// 【它证明什么】探针若只查"状态码是不是 0"，这个假 shim 会**全绿** ⇒ 探针无效。
//   ⇒ `gdiplus-decode-check.sh --selftest` 断言：**拿这个假 shim 跑探针必须 FAIL**。
//   这就是"内容判据（尺寸/像素/行距）真的在咬"的机器证。
// ⚠️ 本文件**不参与产品构建**（`build-shim.sh` 的 SRCS 里没有它）；只在 selftest 里现编。
// ============================================================================
#include <stdint.h>
#include <string.h>

typedef int32_t GpStatus;
typedef struct { int32_t width, height, stride, pixelFormat; unsigned char *scan0; void *reserved; } BitmapData;
static uintptr_t g_tok = 0x1;

GpStatus GdiplusStartup(void **t, const void *i, void *o) { (void)i; (void)o; if (t) *t = &g_tok; return 0; }
GpStatus GdipLoadImageFromFile(const uint16_t *f, void **img) { (void)f; if (img) *img = &g_tok; return 0; }
GpStatus GdipCreateBitmapFromFile(const uint16_t *f, void **img) { return GdipLoadImageFromFile(f, img); }
GpStatus GdipGetImageWidth(void *im, uint32_t *w) { (void)im; if (w) *w = 1; return 0; }   /* 假答案 */
GpStatus GdipGetImageHeight(void *im, uint32_t *h) { (void)im; if (h) *h = 1; return 0; }  /* 假答案 */
GpStatus GdipGetImagePixelFormat(void *im, int32_t *f) { (void)im; if (f) *f = 0x0026200A; return 0; }
GpStatus GdipBitmapGetPixel(void *im, int32_t x, int32_t y, uint32_t *c) { (void)im; (void)x; (void)y; if (c) *c = 0xFFFFFFFFu; return 0; }
GpStatus GdipBitmapLockBits(void *im, void *r, uint32_t fl, int32_t fmt, BitmapData *d)
{ (void)im; (void)r; (void)fl; (void)fmt; if (d) { memset(d, 0, sizeof *d); d->width = 1; d->height = 1; d->stride = 4; d->scan0 = NULL; } return 0; }
GpStatus GdipBitmapUnlockBits(void *im, BitmapData *d) { (void)im; (void)d; return 0; }
GpStatus GdipDisposeImage(void *im) { (void)im; return 0; }
GpStatus GdipSaveImageToFile(void *im, const uint16_t *f, void *c, void *e) { (void)im; (void)f; (void)c; (void)e; return 0; }  /* 假成功 */
GpStatus GdipSaveImageToStream(void *im, void *s, void *c, void *e) { (void)im; (void)s; (void)c; (void)e; return 0; }

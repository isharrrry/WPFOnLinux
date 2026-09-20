// ============================================================================
// win32_gdiplus.c —— `gdiplus.dll` 的实现（`#35` 立最小面；`#41` F 起**图像族真解码**）
//
// 【为什么需要它】第三方 WPF 应用会**自己** `[DllImport("gdiplus.dll")]`（实例：HandyControl
//   的 `Tools/Interop/InteropMethods.cs`）。典型次序：
//     `Gdip..cctor` → `GdiplusStartup`（类初始化就调！）→ `RtlGetVersion` → 各图像查询/解码。
//   缺这个 DLL 的后果不是"少个功能"，而是 `TypeInitializationException ← DllNotFoundException`
//   把应用在**构造窗口**时就掀掉。
//
// 【`#41` F 的口径 —— 只读族**真做**，写族**如实失败**】
//   · **真做**（接到 WIC/Skia 那条唯一的解码链上）：
//       `GdipLoadImageFromFile` / `GdipCreateBitmapFromFile` / `GdipGetImageWidth` / `GdipGetImageHeight` /
//       `GdipGetImagePixelFormat` / `GdipBitmapGetPixel` / `GdipBitmapLockBits` / `GdipBitmapUnlockBits` /
//       `GdipDisposeImage`（真释放）。
//   · **真话式降级**：帧维度/帧数/编解码器枚举 ⇒ `Ok` + 空结果（Linux 后端确实没有动画/编码器表）。
//   · **如实失败**（不返回假句柄、不假装成功）：保存族、`HBITMAP` 互转、属性项、流式解码。
//
//   ⚠️ **不许再写第二份解码**：真解码一律经 `libwpfwic.so` 的导出助手
//      `WpfWic_DecodeFileToBgra()`（Skia C API 只在那一个文件里被调用）。
//      本文件只做"GDI+ 面 → 那条链"的**转发**与句柄记账。
//      以 `dladdr` 定位我们自己的 `.so` 目录去找同目录的 `libwpfwic.so`（即"四个 .so 与 app 同目录"
//      那条已验证的部署布局），再退回 `dlopen("libwpfwic.so")` 与 `WPF_LINUX_WIC_SHIM`。
// ============================================================================

#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <unistd.h>

typedef int32_t GpStatus;
enum {
    Ok = 0, GenericError = 1, InvalidParameter = 2, OutOfMemory = 3, ObjectBusy = 4,
    InsufficientBuffer = 5, NotImplemented = 6, Win32Error = 7, WrongState = 8, Aborted = 9,
    FileNotFound = 10, ValueOverflow = 11, AccessDenied = 12, UnknownImageFormat = 13,
    GdiplusNotInitialized = 18,
};

/* GDI+ 的像素格式常量（只用得到的几个；值与 Windows 头一致） */
#define PixelFormat32bppARGB   0x0026200A
#define PixelFormat32bppPARGB  0x000E200B

static uintptr_t g_token = 0x6764706c;   /* 'gdpl' —— 只是"非空"的标记 */

/* ⚠️ 前向声明：`gd_resolve_decoder()` 里用 `dladdr((void *)&GdiplusStartup, …)` 求**我们自己 .so 的目录**
   （去找同目录的 `libwpfwic.so`）。那个函数定义在本文件后半 ⇒ 不先声明就是 C99 的隐式声明错误
   （`#41` F 实测：`error: 'GdiplusStartup' undeclared`）。*/
GpStatus GdiplusStartup(void **token, const void *input, void *output);

/* ── 我们自己的位图句柄 ────────────────────────────────────────────────────────
   ⚠️ 句柄是**我们**分配的指针；跨面（例如有人把真 GDI+ 的句柄塞进来）不可能命中 magic
   ⇒ 一律 `InvalidParameter`，绝不 deref 未知指针。 */
#define GD_MAGIC 0x47504C31u             /* 'GPL1' */
typedef struct {
    uint32_t magic;
    int32_t  w, h, stride;
    uint32_t format;
    unsigned char *px;                    /* BGRA32，malloc 出来的 */
} gd_bmp;

static int gd_valid(void *h) { return h && ((gd_bmp *)h)->magic == GD_MAGIC; }

/* ── 到 WIC/Skia 那条唯一解码链的转发 ─────────────────────────────────────── */
typedef int (*decode_file_fn)(const char *, unsigned char **, int32_t *, int32_t *, int32_t *);
static decode_file_fn g_decode_file;
static int g_decode_probe_done;           /* 0=未找过 1=找到 2=没找到 */

static void *try_dlopen(const char *path)
{
    if (!path || !*path) return NULL;
    return dlopen(path, RTLD_NOW | RTLD_LOCAL);
}

static void gd_resolve_decoder(void)
{
    if (g_decode_probe_done) return;
    g_decode_probe_done = 1;              /* 只找一次（失败也不反复 dlopen） */

    void *wic = NULL;
    /* ① 环境变量（显式覆盖；调试/非常规布局用） */
    const char *env = getenv("WPF_LINUX_WIC_SHIM");
    if (env && *env) wic = try_dlopen(env);

    /* ② 与我们自己同目录（**已验证的部署布局**：四个 .so 与 app 同目录） */
    if (!wic) {
        Dl_info info;
        if (dladdr((void *)&GdiplusStartup, &info) && info.dli_fname) {
            char buf[4096];
            const char *slash = strrchr(info.dli_fname, '/');
            if (slash && (size_t)(slash - info.dli_fname) < sizeof buf - 32) {
                size_t n = (size_t)(slash - info.dli_fname);
                memcpy(buf, info.dli_fname, n);
                buf[n] = 0;
                strncat(buf, "/libwpfwic.so", sizeof buf - strlen(buf) - 1);
                wic = try_dlopen(buf);
            }
        }
    }
    /* ③ 默认搜索路径（LD_LIBRARY_PATH / rpath / 系统目录） */
    if (!wic) wic = try_dlopen("libwpfwic.so");
    if (!wic) return;

    void *sym = dlsym(wic, "WpfWic_DecodeFileToBgra");
    if (sym) g_decode_file = (decode_file_fn)sym;
    /* ⚠️ 故意**不 dlclose**：解码链的生命期跟着进程（关掉会让后续调用悬空）。 */
}

/* UTF-16(LE) → UTF-8（GDI+ 的文件名是 WCHAR*）。返回新分配的缓冲或 NULL。 */
static char *utf16_to_utf8(const uint16_t *w)
{
    if (!w) return NULL;
    size_t n = 0;
    while (w[n]) n++;
    char *out = (char *)malloc(n * 4 + 1);
    if (!out) return NULL;
    size_t j = 0;
    for (size_t i = 0; i < n; i++) {
        uint32_t cp = w[i];
        if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < n && w[i + 1] >= 0xDC00 && w[i + 1] <= 0xDFFF) {
            cp = 0x10000u + ((cp - 0xD800u) << 10) + (w[i + 1] - 0xDC00u);
            i++;
        }
        if (cp < 0x80) out[j++] = (char)cp;
        else if (cp < 0x800) { out[j++] = (char)(0xC0 | (cp >> 6)); out[j++] = (char)(0x80 | (cp & 0x3F)); }
        else if (cp < 0x10000) {
            out[j++] = (char)(0xE0 | (cp >> 12));
            out[j++] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[j++] = (char)(0x80 | (cp & 0x3F));
        } else {
            out[j++] = (char)(0xF0 | (cp >> 18));
            out[j++] = (char)(0x80 | ((cp >> 12) & 0x3F));
            out[j++] = (char)(0x80 | ((cp >> 6) & 0x3F));
            out[j++] = (char)(0x80 | (cp & 0x3F));
        }
    }
    out[j] = 0;
    return out;
}

/* 把"解码助手"的返回码翻成 GDI+ 的 GpStatus（**逐码对应**，不合并成"反正失败了"） */
static GpStatus map_decode_rc(int rc)
{
    switch (rc) {
        case 0:  return Ok;
        case 1:  return InvalidParameter;
        case 2:  return OutOfMemory;
        case 3:  return FileNotFound;
        case 4:  return UnknownImageFormat;
        default: return GenericError;
    }
}

static GpStatus gd_from_file(const uint16_t *wpath, void **bitmap)
{
    if (bitmap) *bitmap = NULL;
    if (!wpath || !bitmap) return InvalidParameter;
    gd_resolve_decoder();
    if (!g_decode_file) return NotImplemented;   /* 解码链不在 ⇒ **如实**说做不到 */

    char *path = utf16_to_utf8(wpath);
    if (!path) return OutOfMemory;

    unsigned char *px = NULL; int32_t w = 0, h = 0, stride = 0;
    int rc = g_decode_file(path, &px, &w, &h, &stride);
    free(path);
    if (rc != 0) return map_decode_rc(rc);

    gd_bmp *b = (gd_bmp *)calloc(1, sizeof *b);
    if (!b) { free(px); return OutOfMemory; }
    b->magic = GD_MAGIC; b->w = w; b->h = h; b->stride = stride;
    b->format = PixelFormat32bppPARGB;    /* Skia 出的是 BGRA（预乘）—— 与 WIC 侧的声明一致 */
    b->px = px;
    *bitmap = b;
    return Ok;
}

// ── 生命周期 ───────────────────────────────────────────────────────────────
GpStatus GdiplusStartup(void **token, const void *input, void *output)
{
    (void)input;
    if (token) *token = (void *)&g_token;
    if (output) memset(output, 0, 16);       /* StartupOutput（两个函数指针） */
    return Ok;
}
GpStatus GdiplusShutdown(void *token) { (void)token; return Ok; }

// ── 只读族：**真做**（经唯一解码链）────────────────────────────────────────────
GpStatus GdipLoadImageFromFile(const uint16_t *filename, void **image) { return gd_from_file(filename, image); }
GpStatus GdipCreateBitmapFromFile(const uint16_t *filename, void **bitmap) { return gd_from_file(filename, bitmap); }

GpStatus GdipGetImageWidth(void *image, uint32_t *width)
{
    if (!width) return InvalidParameter;
    if (!gd_valid(image)) { *width = 0; return InvalidParameter; }
    *width = (uint32_t)((gd_bmp *)image)->w;
    return Ok;
}
GpStatus GdipGetImageHeight(void *image, uint32_t *height)
{
    if (!height) return InvalidParameter;
    if (!gd_valid(image)) { *height = 0; return InvalidParameter; }
    *height = (uint32_t)((gd_bmp *)image)->h;
    return Ok;
}
GpStatus GdipGetImagePixelFormat(void *image, int32_t *format)
{
    if (!format) return InvalidParameter;
    if (!gd_valid(image)) { *format = 0; return InvalidParameter; }
    *format = (int32_t)((gd_bmp *)image)->format;
    return Ok;
}
GpStatus GdipBitmapGetPixel(void *bitmap, int32_t x, int32_t y, uint32_t *color)
{
    if (!color) return InvalidParameter;
    if (!gd_valid(bitmap)) { *color = 0; return InvalidParameter; }
    gd_bmp *b = (gd_bmp *)bitmap;
    if (x < 0 || y < 0 || x >= b->w || y >= b->h) { *color = 0; return InvalidParameter; }
    const unsigned char *p = b->px + (size_t)y * (size_t)b->stride + (size_t)x * 4;
    /* 内存里是 BGRA；GDI+ 的 ARGB 是 0xAARRGGBB */
    *color = ((uint32_t)p[3] << 24) | ((uint32_t)p[2] << 16) | ((uint32_t)p[1] << 8) | (uint32_t)p[0];
    return Ok;
}

/* BitmapData 的前 6 个字段（GDI+ 头里的顺序）；我们把 Scan0/Stride/尺寸/格式填真值 */
typedef struct { int32_t width, height, stride, pixelFormat; unsigned char *scan0; void *reserved; } gd_bitmapdata;

GpStatus GdipBitmapLockBits(void *bitmap, void *rect, uint32_t flags, int32_t format, gd_bitmapdata *data)
{
    (void)rect; (void)flags;
    if (!data) return InvalidParameter;
    if (!gd_valid(bitmap)) { memset(data, 0, sizeof *data); return InvalidParameter; }
    gd_bmp *b = (gd_bmp *)bitmap;
    if (format && format != PixelFormat32bppPARGB && format != PixelFormat32bppARGB) {
        memset(data, 0, sizeof *data);
        return InvalidParameter;              /* 我们只有 32bpp BGRA ⇒ 别的格式**如实拒绝** */
    }
    data->width = b->w; data->height = b->h; data->stride = b->stride;
    data->pixelFormat = (int32_t)b->format; data->scan0 = b->px; data->reserved = NULL;
    return Ok;
}
GpStatus GdipBitmapUnlockBits(void *bitmap, gd_bitmapdata *data)
{
    (void)data;
    return gd_valid(bitmap) ? Ok : InvalidParameter;
}

GpStatus GdipDisposeImage(void *image)
{
    if (!gd_valid(image)) return Ok;          /* 与 Windows 一致：不是我们的句柄就什么都不做 */
    gd_bmp *b = (gd_bmp *)image;
    b->magic = 0;                             /* 先失效再释放（重复 Dispose 不会 double free） */
    free(b->px);
    free(b);
    return Ok;
}

// ── 查询类：成功 + 空结果（"没有这些能力"是真话）─────────────────────────────
GpStatus GdipImageGetFrameDimensionsCount(void *image, int32_t *count)
{ (void)image; if (count) *count = 0; return Ok; }
GpStatus GdipImageGetFrameDimensionsList(void *image, void *buffer, int32_t count)
{ (void)image; (void)buffer; (void)count; return Ok; }
GpStatus GdipImageGetFrameCount(void *image, void *dimensionId, int32_t *count)
{ (void)image; (void)dimensionId; if (count) *count = 1; return Ok; }
GpStatus GdipGetImageEncodersSize(int32_t *numEncoders, int32_t *size)
{ if (numEncoders) *numEncoders = 0; if (size) *size = 0; return Ok; }
GpStatus GdipGetImageDecodersSize(int32_t *numDecoders, int32_t *size)
{ if (numDecoders) *numDecoders = 0; if (size) *size = 0; return Ok; }
GpStatus GdipGetImageEncoders(int32_t numEncoders, int32_t size, void *encoders)
{ (void)numEncoders; (void)size; (void)encoders; return Ok; }
GpStatus GdipGetImageDecoders(int32_t numDecoders, int32_t size, void *decoders)
{ (void)numDecoders; (void)size; (void)decoders; return Ok; }
GpStatus GdipImageForceValidation(void *image) { (void)image; return Ok; }

// ── 如实失败族（**不给假句柄、不假装成功**）────────────────────────────────────
GpStatus GdipCreateBitmapFromStream(void *stream, void **bitmap)
{ (void)stream; if (bitmap) *bitmap = 0; return NotImplemented; }   /* 流式解码未接（登记在册） */
GpStatus GdipCreateBitmapFromHBITMAP(void *hbitmap, void *hpalette, void **bitmap)
{ (void)hbitmap; (void)hpalette; if (bitmap) *bitmap = 0; return NotImplemented; }
GpStatus GdipCreateHBITMAPFromBitmap(void *bitmap, void **hbitmap, int32_t background)
{ (void)bitmap; (void)background; if (hbitmap) *hbitmap = 0; return NotImplemented; }
GpStatus GdipCreateBitmapFromScan0(int32_t width, int32_t height, int32_t stride, int32_t format, unsigned char *scan0, void **bitmap)
{
    if (bitmap) *bitmap = NULL;
    if (width <= 0 || height <= 0 || !scan0 || !bitmap) return InvalidParameter;
    if (format && format != PixelFormat32bppPARGB && format != PixelFormat32bppARGB) return InvalidParameter;
    if (stride == 0) stride = width * 4;
    if (stride < width * 4) return InvalidParameter;      /* 行距小于一行 ⇒ **如实拒绝**（不许读越界） */
    size_t need = (size_t)stride * (size_t)height;
    unsigned char *px = (unsigned char *)malloc(need);
    if (!px) return OutOfMemory;
    memcpy(px, scan0, need);
    gd_bmp *b = (gd_bmp *)calloc(1, sizeof *b);
    if (!b) { free(px); return OutOfMemory; }
    b->magic = GD_MAGIC; b->w = width; b->h = height; b->stride = stride;
    b->format = format ? (uint32_t)format : PixelFormat32bppPARGB; b->px = px;
    *bitmap = b;
    return Ok;
}
GpStatus GdipImageSelectActiveFrame(void *image, void *dimensionId, int32_t frameIndex)
{ (void)image; (void)dimensionId; (void)frameIndex; return InvalidParameter; }
GpStatus GdipGetPropertyItemSize(void *image, int32_t propid, int32_t *size)
{ (void)image; (void)propid; if (size) *size = 0; return InvalidParameter; }
GpStatus GdipGetPropertyItem(void *image, int32_t propid, int32_t size, void *buffer)
{ (void)image; (void)propid; (void)size; (void)buffer; return InvalidParameter; }
GpStatus GdipGetImageRawFormat(void *image, void *format)
{ (void)image; (void)format; return InvalidParameter; }
GpStatus GdipSaveImageToFile(void *image, const uint16_t *filename, void *clsid, void *encoderParams)
{ (void)image; (void)filename; (void)clsid; (void)encoderParams; return NotImplemented; }
GpStatus GdipSaveImageToStream(void *image, void *stream, void *clsid, void *encoderParams)
{ (void)image; (void)stream; (void)clsid; (void)encoderParams; return NotImplemented; }

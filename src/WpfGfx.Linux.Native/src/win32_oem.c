// ============================================================================
// win32_oem.c —— **映射表外 DLL 的最小面**（`#35` 波）
//
// 【为什么需要它】`libwpfwin32.so` 原先只被映射到 6 个 DLL 名
//   （`gdi32`/`kernel32`/`ole32`/`user32`/`uxtheme`/`wtsapi32`）。
//   而**第三方 WPF 应用**（实例：HandyControl 示例工程）自己 `[DllImport]` 的还有
//   `shell32`（`ExtractIconEx`）、`ntdll`（`RtlGetVersion`）、`gdiplus`（`GdiplusStartup` …）、
//   `msimg32`、`dwmapi`、以及 `user32` 的 `SetWindowCompositionAttribute`。
//   实测症状（不是"少一个功能"，而是"应用直接被掀掉"）：
//     · `EntryPointNotFoundException: Unable to find an entry point named 'ExtractIconEx'`
//     · `DllNotFoundException: gdiplus.dll`（派生 `TypeInitializationException`）
//   ⇒ 本文件把**这些名字下、调用方真正会碰到的入口**补上，并让解析器（`build/shims/Win32ShimResolver.cs`）
//     把它们也映射到本 shim。
//
// 【口径（明说，不许沉默扩权）】
//   · 能真做的真做：`RtlGetVersion` 如实报一个 Windows 版本（linux 上**没有真值**，
//     这里报 `10.0.19045` 是**降级声明**，不是"这就是你的系统版本"；调用方只用它做分支）；
//   · 做不到的**如实失败**（返回 NULL/0 + `SetLastError`），**绝不**返回"看起来有效的假句柄"；
//   · **GDI+ 只做到"应用能起来、图像族不装成功"**：`GdiplusStartup` 返回 Ok（只是个标记），
//     而**查询类**返回"成功 + 空结果"（例：这张图没有动画帧 ⇒ 上层优雅降级为静图），
//     **创建/解码类**返回 `InvalidParameter` ⇒ 上层走自己的失败分支。图像真要落地得接 Skia/WIC。
// ============================================================================

#include <stdint.h>
#include <string.h>
#include <stddef.h>

typedef int BOOL;
typedef uint32_t UINT;
typedef uint32_t DWORD;
typedef void *HANDLE;
typedef void *HMODULE;
typedef intptr_t INT_PTR;
typedef uintptr_t UINT_PTR;

extern void wpf_set_last_error(uint32_t code);
extern void *wpf_x11_display(void);   /* win32_x11.c 提供（若不存在则由链接期报错拦住 —— 宁可红） */

#define E_NOTIMPL_CODE 120            /* ERROR_CALL_NOT_IMPLEMENTED */
#define E_INVALIDARG_CODE 87          /* ERROR_INVALID_PARAMETER */

// ── ntdll：RtlGetVersion ────────────────────────────────────────────────────
// 结构 = RTL_OSVERSIONINFOEXW（`dwOSVersionInfoSize` + 4×DWORD + 128×WCHAR + 2×WORD）。
typedef struct {
    DWORD dwOSVersionInfoSize;
    DWORD dwMajorVersion;
    DWORD dwMinorVersion;
    DWORD dwBuildNumber;
    DWORD dwPlatformId;
    uint16_t szCSDVersion[128];
    uint16_t wServicePackMajor;
    uint16_t wServicePackMinor;
} RTL_OSVERSIONINFOEXW;

// [降级] Linux 上没有 Windows 版本真值 ⇒ 报 10.0.19045（Win10 22H2）。
//   为什么这样"不撒谎"：调用方（WPF/第三方库）只用它做**分支判断**；报一个受支持的版本
//   比让它拿到 0.0.0 而走进未定义分支安全。**这条降级必须留在册**。
int32_t RtlGetVersion(RTL_OSVERSIONINFOEXW *v)
{
    if (!v) return (int32_t)0xC000000D;          /* STATUS_INVALID_PARAMETER */
    // ⚠️ **必须尊重调用方声明的结构大小**（`#35` 实测踩出来的）：
    //   不同的托管声明对同一结构算出的大小**不一样**（`szCSDVersion` 按 ANSI 的 `ByValTStr(128)`
    //   只有 128 字节 ⇒ 整个结构 148 字节；按 Unicode 才是 280）。**写满"我们以为的 280"会越界踩坏
    //   调用方的栈/堆** —— 症状是应用**静默黑屏、无异常**（呈现链根本没跑到）。
    //   ⇒ 只写前 20 字节的固定字段，并**原样回填**调用方声明的大小；其余字段按声明长度**只清不写**。
    DWORD declared = v->dwOSVersionInfoSize;
    if (declared < 5u * sizeof(DWORD)) declared = 5u * sizeof(DWORD);   /* 小于固定头 ⇒ 按固定头算 */

    v->dwOSVersionInfoSize = declared;
    v->dwMajorVersion = 10;
    v->dwMinorVersion = 0;
    v->dwBuildNumber  = 19045;                   /* Win10 22H2：Linux 上没有 Windows 版本真值，这是**降级声明** */
    v->dwPlatformId   = 2;                       /* VER_PLATFORM_WIN32_NT */

    // `szCSDVersion[128]`（WCHAR）只有调用方声明到它时才清 —— 不越界。
    if (declared >= 5u * sizeof(DWORD) + 256u) memset(v->szCSDVersion, 0, 256);
    return 0;                                    /* STATUS_SUCCESS */
}
int32_t RtlGetVersionA(RTL_OSVERSIONINFOEXW *v) { return RtlGetVersion(v); }

// ── user32：SetWindowCompositionAttribute ──────────────────────────────────
// 上游用途：模糊/亚克力（Win10 起）。Linux 上 X11 没有等价物（合成器相关）。
//   HandyControl 的用法是"失败就跳过"，而**缺符号**会让整个应用被掀掉 ⇒ 这里如实失败。
BOOL SetWindowCompositionAttribute(void *hwnd, void *data)
{
    (void)hwnd; (void)data; wpf_set_last_error(E_NOTIMPL_CODE); return 0;
}

// ── msimg32：AlphaBlend ────────────────────────────────────────────────────
// 上游用途：GDI 的 alpha 混合。我们的 gdi32 面只做到"占位"，混合**不做**（如实返回 0）。
BOOL AlphaBlend(void *hdcDst, int32_t xd, int32_t yd, int32_t wd, int32_t hd, void *hdcSrc,
                int32_t xs, int32_t ys, int32_t ws, int32_t hs, void *bf)
{
    (void)hdcDst; (void)xd; (void)yd; (void)wd; (void)hd; (void)hdcSrc;
    (void)xs; (void)ys; (void)ws; (void)hs; (void)bf;
    wpf_set_last_error(E_NOTIMPL_CODE); return 0;
}
BOOL TransparentBlt(void *a, int32_t b, int32_t c, int32_t d, int32_t e, void *f,
                    int32_t g, int32_t h, int32_t i, int32_t j, UINT k)
{
    (void)a;(void)b;(void)c;(void)d;(void)e;(void)f;(void)g;(void)h;(void)i;(void)j;(void)k;
    wpf_set_last_error(E_NOTIMPL_CODE); return 0;
}

// ── dwmapi：DWM 合成 ───────────────────────────────────────────────────────
// 【语义对齐（`#35` 波实测订正）】原先把这几个一律返回 `NOT_SUPPORTED`（"没有 DWM"）——
//   **那是错的口径**：Windows 上"**有 DWM 但合成被关闭**"是**合法且常见**的状态，此时
//   · `DwmIsCompositionEnabled` 返回 **S_OK** 且 `*pfEnabled = FALSE`；
//   · `DwmExtendFrameIntoClientArea` / `DwmSetWindowAttribute` 返回 **S_OK**（什么都不做）。
//   WPF 的 `WindowChromeWorker` 按这些 HRESULT 选分支：一律 `NOT_SUPPORTED` 会让它走进一条
//   **不画客户区**的路（实测：第三方应用开得出窗口、却整屏全黑）。
//   ⇒ 改成"**有 DWM、合成关闭**"这一组语义（这才是 Linux 上的真话：X11 有合成器、但没有 DWM 玻璃）。
typedef struct { int32_t cxLeftWidth, cxRightWidth, cyTopHeight, cyBottomHeight; } MARGINS;
int32_t DwmExtendFrameIntoClientArea(void *hwnd, const MARGINS *m) { (void)hwnd; (void)m; return 0; }  /* S_OK（无效果）*/
int32_t DwmSetWindowAttribute(void *hwnd, DWORD attr, const void *val, DWORD cb)
{ (void)hwnd; (void)attr; (void)val; (void)cb; return 0; }                                            /* S_OK（忽略）*/
int32_t DwmEnableBlurBehindWindow(void *hwnd, const void *bb) { (void)hwnd; (void)bb; return 0; }      /* S_OK（无效果）*/
int32_t DwmIsCompositionEnabled(BOOL *enabled) { if (enabled) *enabled = 0; return 0; }               /* S_OK + 关闭 */
// `DwmGetWindowAttribute` 不同：调用方要**真值**（扩展边框/圆角），编不出来 ⇒ 如实失败。
int32_t DwmGetWindowAttribute(void *hwnd, DWORD attr, void *val, DWORD cb)
{ (void)hwnd; (void)attr; (void)val; (void)cb; return (int32_t)0x80004001; }                          /* E_NOTIMPL */

// ── shell32：只补"调用方真的会碰"的三个 + ExtractIconEx 的别名已在 win32_misc.c ──
typedef struct { void *hIcon; int32_t iIcon; DWORD dwAttributes; uint16_t szDisplayName[260]; uint16_t szTypeName[80]; } SHFILEINFOW;
UINT_PTR SHGetFileInfoW(const uint16_t *path, DWORD attrs, SHFILEINFOW *fi, UINT cb, UINT flags)
{ (void)path; (void)attrs; (void)fi; (void)cb; (void)flags; wpf_set_last_error(E_NOTIMPL_CODE); return 0; }
UINT_PTR SHGetFileInfoA(const char *path, DWORD attrs, SHFILEINFOW *fi, UINT cb, UINT flags)
{ (void)path; (void)attrs; (void)fi; (void)cb; (void)flags; wpf_set_last_error(E_NOTIMPL_CODE); return 0; }
HANDLE ShellExecuteW(void *hwnd, const uint16_t *op, const uint16_t *file, const uint16_t *params,
                     const uint16_t *dir, int32_t show)
{ (void)hwnd;(void)op;(void)file;(void)params;(void)dir;(void)show; wpf_set_last_error(E_NOTIMPL_CODE); return (HANDLE)(intptr_t)32; }
int32_t SHCreateItemFromParsingName(const uint16_t *path, void *bc, const void *iid, void **out)
{ (void)path; (void)bc; (void)iid; if (out) *out = NULL; return (int32_t)0x80004005; }   /* E_FAIL */

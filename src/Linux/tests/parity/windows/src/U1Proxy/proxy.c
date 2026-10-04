/*
 * App-local forwarding proxy for wpfgfx_cor3.dll  (U1 route 1).
 *
 * Drop this DLL next to the test executable; the .NET runtime resolves the bare
 * DllImport name "wpfgfx_cor3.dll" from the application directory first, so every
 * PresentationCore P/Invoke lands here.  We then tail-jump to the real
 * implementation (loaded from an absolute path) and record the DUCE byte stream
 * in the WPFST\001 format of docs/U1-command-stream-golden-plan.md 2.3.
 *
 *   op 1 BeginCommand   payload = cbExtra(u32) + command bytes
 *   op 2 AppendCommandData payload = appended bytes
 *   op 3 EndCommand     payload = empty
 *   op 4 CommitChannel  payload = empty
 *   op 5 CreateOrAddRefOnChannel payload = type(u32) + handle(u32)  (handle read AFTER the call)
 *   op 6 ReleaseOnChannel        payload = handle(u32)
 *
 * Env:
 *   WPFGFX_REAL        absolute path of the real DLL (default: installed 10.0.7)
 *   WPF_STREAM_LOG     output prefix; per-channel files <prefix>-chN.stream
 *
 * Everything here is observation only: behaviour is byte-for-byte the real DLL's.
 */
#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include "proxy_exports.h"

/* rely on the MinGW auto-export path: with no explicit dllexport every global symbol
   (the 7 interceptors and the 99 asm trampolines) ends up in the export table */
#define U1_EXPORT

#define U1_MAXPATH 1024
#define U1_MAXCH   32
#define U1_MAGIC   "WPFST\001"

/* one pointer per real export */
#define U1_DECL(name) void *ptr_##name;
U1_EXPORTS(U1_DECL)
#undef U1_DECL

static HMODULE g_real;
static int g_resolve_failed;
static char g_prefix[U1_MAXPATH];
static int g_prefix_done;
static CRITICAL_SECTION g_cs;
static int g_cs_ready;

static void *g_chan[U1_MAXCH];
static FILE *g_fp[U1_MAXCH];
static int g_nch;
static long g_records;

/* ------------------------------------------------------------------ logging */

static void trace(const char *fmt, ...)
{
    char path[U1_MAXPATH];
    char line[1024];
    va_list ap;
    FILE *f;

    if (g_prefix[0]) {
        _snprintf(path, sizeof(path), "%s-proxy.log", g_prefix);
    } else {
        lstrcpynA(path, "wpfgfx-proxy.log", sizeof(path));
    }
    va_start(ap, fmt);
    _vsnprintf(line, sizeof(line), fmt, ap);
    va_end(ap);

    f = fopen(path, "ab");
    if (f) {
        fputs(line, f);
        fputc('\n', f);
        fclose(f);
    }
}

static void ensure_prefix(void)
{
    DWORD n;
    char *dot;
    if (g_prefix_done) return;
    g_prefix_done = 1;
    n = GetEnvironmentVariableA("WPF_STREAM_LOG", g_prefix, (DWORD)sizeof(g_prefix));
    if (n == 0 || n >= sizeof(g_prefix)) { g_prefix[0] = 0; return; }
    dot = strstr(g_prefix, ".stream");
    if (dot) *dot = 0;
}

/* ------------------------------------------------------- real dll resolution */

static void load_real(void)
{
    char path[U1_MAXPATH];
    DWORD n = GetEnvironmentVariableA("WPFGFX_REAL", path, (DWORD)sizeof(path));
    if (n == 0 || n >= sizeof(path)) {
        lstrcpynA(path,
            "C:\\Program Files\\dotnet\\shared\\Microsoft.WindowsDesktop.App\\10.0.7\\wpfgfx_cor3.dll",
            sizeof(path));
    }
    g_real = LoadLibraryExA(path, NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
    if (!g_real) {
        trace("FATAL LoadLibraryExA(%s) failed, GetLastError=%lu", path, GetLastError());
        return;
    }
    trace("real dll loaded: %s (hmod=%p)", path, (void *)g_real);

#define U1_RESOLVE(name)                                                     \
    ptr_##name = (void *)GetProcAddress(g_real, #name);                       \
    if (!ptr_##name) { g_resolve_failed++; trace("MISSING EXPORT %s", #name); }
    U1_EXPORTS(U1_RESOLVE)
#undef U1_RESOLVE

    trace("resolved all exports, failures=%d", g_resolve_failed);
}

/* ------------------------------------------------------------ stream writer */

static FILE *chan_file(void *chan)
{
    char path[U1_MAXPATH];
    int i;
    for (i = 0; i < g_nch; i++)
        if (g_chan[i] == chan) return g_fp[i];
    if (g_nch >= U1_MAXCH) return NULL;
    i = g_nch++;
    g_chan[i] = chan;
    _snprintf(path, sizeof(path), "%s-ch%d.stream", g_prefix, i);
    g_fp[i] = fopen(path, "wb");
    if (g_fp[i]) {
        fwrite(U1_MAGIC, 1, 6, g_fp[i]);
        fflush(g_fp[i]);
        trace("channel %p -> %s", chan, path);
    } else {
        trace("cannot open %s", path);
    }
    return g_fp[i];
}

static void rec_op(void *chan, unsigned char op, const void *data, unsigned len)
{
    unsigned char hdr[5];
    FILE *f;

    if (!g_prefix[0]) return;
    if (!g_cs_ready) return;
    EnterCriticalSection(&g_cs);
    f = chan_file(chan);
    if (f) {
        hdr[0] = op;
        memcpy(hdr + 1, &len, 4);
        fwrite(hdr, 1, 5, f);
        if (len && data) fwrite(data, 1, len, f);
        fflush(f);
        g_records++;
    }
    LeaveCriticalSection(&g_cs);
}

/* op1 keeps the Linux replay contract: payload = cbExtra(u32) + command bytes */
static void rec_cmd(void *chan, const void *cmd, unsigned cb, unsigned cbExtra)
{
    unsigned char hdr[5];
    unsigned len = 4 + cb;
    FILE *f;

    if (!g_prefix[0]) return;
    if (!g_cs_ready) return;
    EnterCriticalSection(&g_cs);
    f = chan_file(chan);
    if (f) {
        hdr[0] = 1;
        memcpy(hdr + 1, &len, 4);
        fwrite(hdr, 1, 5, f);
        fwrite(&cbExtra, 1, 4, f);
        if (cb && cmd) fwrite(cmd, 1, cb, f);
        fflush(f);
        g_records++;
    }
    LeaveCriticalSection(&g_cs);
}

/* ------------------------------------------------------------ intercepted */

typedef int (*fn_begin)(void *, unsigned char *, unsigned, unsigned);
typedef int (*fn_append)(void *, unsigned char *, unsigned);
typedef int (*fn_one)(void *);
typedef int (*fn_send)(unsigned char *, unsigned, int, void *);
typedef int (*fn_create)(void *, unsigned, void *);
typedef int (*fn_release)(void *, unsigned, int *);

U1_EXPORT int MilChannel_BeginCommand(void *pChannel, unsigned char *pbData,
                                                  unsigned cbSize, unsigned cbExtra)
{
    int hr = ((fn_begin)ptr_MilChannel_BeginCommand)(pChannel, pbData, cbSize, cbExtra);
    if (hr >= 0) rec_cmd(pChannel, pbData, cbSize, cbExtra);
    return hr;
}

U1_EXPORT int MilChannel_AppendCommandData(void *pChannel, unsigned char *pbData,
                                                       unsigned cbSize)
{
    int hr = ((fn_append)ptr_MilChannel_AppendCommandData)(pChannel, pbData, cbSize);
    if (hr >= 0) rec_op(pChannel, 2, pbData, cbSize);
    return hr;
}

U1_EXPORT int MilChannel_EndCommand(void *pChannel)
{
    int hr = ((fn_one)ptr_MilChannel_EndCommand)(pChannel);
    if (hr >= 0) rec_op(pChannel, 3, NULL, 0);
    return hr;
}

U1_EXPORT int MilChannel_CommitChannel(void *pChannel)
{
    int hr = ((fn_one)ptr_MilChannel_CommitChannel)(pChannel);
    if (hr >= 0) rec_op(pChannel, 4, NULL, 0);
    return hr;
}

/* out-of-band complete command -> normalized to BeginCommand + EndCommand */
U1_EXPORT int MilResource_SendCommand(unsigned char *pbData, unsigned cbSize,
                                                  int sendInSeparateBatch, void *pChannel)
{
    int hr = ((fn_send)ptr_MilResource_SendCommand)(pbData, cbSize, sendInSeparateBatch, pChannel);
    if (hr >= 0) {
        rec_cmd(pChannel, pbData, cbSize, 0);
        rec_op(pChannel, 3, NULL, 0);
    }
    return hr;
}

/* the handle is an out parameter: read it *after* the real call - this is the
   record the managed hook could not produce (see docs/U1-windows-probe.md 3.4) */
U1_EXPORT int MilResource_CreateOrAddRefOnChannel(void *pChannel, unsigned type,
                                                             void *hResource)
{
    unsigned handle = 0;
    unsigned char payload[8];
    int hr = ((fn_create)ptr_MilResource_CreateOrAddRefOnChannel)(pChannel, type, hResource);
    if (hResource) handle = *(unsigned *)hResource;
    memcpy(payload, &type, 4);
    memcpy(payload + 4, &handle, 4);
    rec_op(pChannel, 5, payload, 8);
    return hr;
}

U1_EXPORT int MilResource_ReleaseOnChannel(void *pChannel, unsigned hResource,
                                                       int *deleted)
{
    unsigned char payload[4];
    int hr = ((fn_release)ptr_MilResource_ReleaseOnChannel)(pChannel, hResource, deleted);
    memcpy(payload, &hResource, 4);
    rec_op(pChannel, 6, payload, 4);
    return hr;
}

/* -------------------------------------------------------------- dll entry */

BOOL WINAPI DllMain(HINSTANCE hinst, DWORD reason, LPVOID reserved)
{
    (void)hinst; (void)reserved;
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinst);
        InitializeCriticalSection(&g_cs);
        g_cs_ready = 1;
        ensure_prefix();
        load_real();
    } else if (reason == DLL_PROCESS_DETACH) {
        int i;
        for (i = 0; i < g_nch; i++)
            if (g_fp[i]) fclose(g_fp[i]);
    }
    return TRUE;
}

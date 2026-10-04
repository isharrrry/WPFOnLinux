/* T1/M7c2 独立验证：完全不经过 .NET，用 dlopen/dlsym 调 MilFontFace_RegisterFromFile。
   证明 .so 是一个普通 ELF 共享库，导出面是真正的 C ABI。 */
#include <dlfcn.h>
#include <stdio.h>
#include <stdint.h>
typedef intptr_t (*reg_fn)(const char *utf8Path, int32_t faceIndex, int32_t simFlags);
int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s <lib.so> [font.ttf]\n", argv[0]); return 2; }
    void *h = dlopen(argv[1], RTLD_NOW | RTLD_GLOBAL);
    if (!h) { fprintf(stderr, "dlopen failed: %s\n", dlerror()); return 1; }
    printf("dlopen OK: %s\n", argv[1]);

    reg_fn reg = (reg_fn)dlsym(h, "MilFontFace_RegisterFromFile");
    if (!reg) { fprintf(stderr, "dlsym MilFontFace_RegisterFromFile: %s\n", dlerror()); return 1; }
    printf("dlsym MilFontFace_RegisterFromFile = %p\n", (void*)reg);

    /* 同一批里再取两个符号，证明整张导出表都在 */
    printf("dlsym MilChannel_SetNotificationWindow = %p\n", dlsym(h, "MilChannel_SetNotificationWindow"));
    printf("dlsym MilGlyphRun_GetGlyphOutline      = %p\n", dlsym(h, "MilGlyphRun_GetGlyphOutline"));

    {   /* dladdr 自定位：证明镜像知道自己在哪（libSkiaSharp 就是相对它找的） */
        typedef char *(*selfdir_fn)(void);
        selfdir_fn sd = (selfdir_fn)dlsym(h, "MilBridge_Diag_SelfDirectory");
        printf("MilBridge_Diag_SelfDirectory = %s\n", sd ? (sd() ? sd() : "(null)") : "(未导出)");
    }

    if (argc >= 3) {
        intptr_t t = reg(argv[2], 0, 0);
        printf("MilFontFace_RegisterFromFile(\"%s\", 0, 0) = 0x%lx\n", argv[2], (unsigned long)t);
        printf("missing file  -> 0x%lx\n", (unsigned long)reg("/nonexistent/x.ttf", 0, 0));
        printf("faceIndex=-1  -> 0x%lx\n", (unsigned long)reg(argv[2], -1, 0));
        printf("faceIndex=999 -> 0x%lx\n", (unsigned long)reg(argv[2], 999, 0));
        printf("NULL path     -> 0x%lx\n", (unsigned long)reg(NULL, 0, 0));
        printf("simFlags=1    -> 0x%lx\n", (unsigned long)reg(argv[2], 0, 1));
    }
    dlclose(h);
    return 0;
}

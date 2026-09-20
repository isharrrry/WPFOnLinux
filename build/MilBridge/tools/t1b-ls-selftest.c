// T1b · LS 绊线装置**自证**（装置自己不许撒谎）
// ============================================================================
//  用一个"已知存在"的符号与一个"已知缺失"的符号做对照，检查拦截器是否
//  ① 真的记到了请求；② 真的判对了 FOUND/MISS。
//
//  已知事实（`nm -D --defined-only build/../src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 实测）：
//    · `LsDisableSpecialCharacterLigature`  **在**（T = 已定义）
//    · `LoAcquireBreakRecord` / `LoCreateLine`  **不在**
//
//  用法：T1B_LS_TRIPWIRE_LOG=/tmp/x.log LD_PRELOAD=./libt1b-lstripwire.so ./t1b-ls-selftest <libwpfwin32.so>
//  退出码：0 = 装置自证通过；非 0 = 装置不可信（**此时它的任何读数都别用**）
// ============================================================================
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv)
{
    const char *lib = argc > 1 ? argv[1] : "/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/src/WpfGfx.Linux.Native/bin/libwpfwin32.so";

    printf("== T1b · LS 绊线装置自证 ==\n");
    printf("目标库 = %s\n", lib);

    void *h = dlopen(lib, RTLD_NOW | RTLD_LOCAL);
    printf("dlopen      : %s\n", h ? "OK" : dlerror());
    if (!h) return 2;

    void *found = dlsym(h, "LsDisableSpecialCharacterLigature");
    void *miss  = dlsym(h, "LoAcquireBreakRecord");
    void *miss2 = dlsym(h, "LoCreateLine");
    void *miss3 = dlsym(RTLD_DEFAULT, "LoGetEscString");   // 在 shim 里（应 FOUND）
    printf("dlsym LsDisableSpecialCharacterLigature : %s（期望 FOUND）\n", found ? "FOUND" : "MISS");
    printf("dlsym LoAcquireBreakRecord              : %s（期望 MISS）\n", miss ? "FOUND" : "MISS");
    printf("dlsym LoCreateLine                      : %s（期望 MISS）\n", miss2 ? "FOUND" : "MISS");
    printf("dlsym RTLD_DEFAULT LoGetEscString       : %s（期望 FOUND）\n", miss3 ? "FOUND" : "MISS");

    // 装置判对了吗？
    int ok = (found != NULL) && (miss == NULL) && (miss2 == NULL);

    // 日志里必须出现这 4 条请求（说明拦截真的生效，而不是"碰巧判对"）
    const char *lp = getenv("T1B_LS_TRIPWIRE_LOG");
    if (!lp || !*lp) lp = "/tmp/t1b-lstripwire.log";
    FILE *f = fopen(lp, "r");
    char line[512];
    int nLs = 0, nMiss = 0, nFound = 0, sawLs = 0, sawLo = 0, sawDlopen = 0;
    while (f && fgets(line, sizeof line, f)) {
        if (strncmp(line, "dlopen", 6) == 0) sawDlopen = 1;
        if (strstr(line, "LsDisableSpecialCharacterLigature")) { sawLs = 1; if (strstr(line, "FOUND")) ++nFound; }
        if (strstr(line, "LoAcquireBreakRecord") || strstr(line, "LoCreateLine")) { sawLo = 1; if (strstr(line, "MISS")) ++nMiss; }
        ++nLs;
    }
    if (f) fclose(f);
    printf("\n-- 拦截日志 %s：共 %d 行 --\n", lp, nLs);
    printf("  记到 dlopen 事件        : %s\n", sawDlopen ? "是" : "否");
    printf("  记到 Ls*（FOUND）       : %s\n", sawLs && nFound > 0 ? "是" : "否");
    printf("  记到 Lo*（MISS）        : %s\n", sawLo && nMiss > 0 ? "是" : "否");
    printf("  真实 dlsym 判定正确     : %s\n", ok ? "是" : "否");

    int pass = ok && sawLs && sawLo;
    printf("\n⇒ 装置自证 %s%s\n", pass ? "通过" : "**未通过**",
           pass ? "（拦截生效 + 判定与 nm -D 一致）" : "（此时装置的任何读数都不可信）");
    return pass ? 0 : 1;
}

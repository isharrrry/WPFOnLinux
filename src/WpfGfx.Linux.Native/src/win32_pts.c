// WPF-on-Linux · `TASK-0304`（`A1`）· PTS 上下文族的 6 个入口 —— **导出，但如实失败**
// ============================================================================
//
// 【这一件要解决什么】`D-G70`：切「富文本」/「流文档」页 ⇒ 整进程 `rc=134`。
//   W81A 的 `A0` 实测把第一跳钉死（`build/MilBridge/W81A-report.md` §2.2）：
//     ld.so 自己写的日志里 `CreateInstalledObjectsInfo` 冲 shim 找了 **9 次、9 个库全落空**，
//     紧接着托管侧抛 `EntryPointNotFoundException: … in shared library 'PresentationNative_cor3.dll'`。
//   形态上这是**绑定期**失败：P/Invoke 边界就抛了，**我们的台账挂不上去**，
//   托管侧能拿到的只有一句 CLR 生成的英文串 ⇒ "缺口不是数据"。
//
// 【本件做的事】把这 6 个入口**导出**，且**返回非零 LsErr**（= `tserrNotImplemented` `-10000`，
//   上游 `Pts.cs:507` 的定义、`PtsHost.cs:571` 起的回调面用的就是同一个码）。
//   ⇒ 失败从"绑定期找不到符号"变成"**定义好的错误码 + 入口名 + 调用序号**"，
//     托管侧 `PTS.Validate(-10000)` 走 default 分支抛 `PtsException`（带那个码）。
//   ⇒ 缺口**变成数据**；将来真实现（`TASK-0302`）替换本文件时，**托管侧一行都不用改**。
//
// 【⛔ 本件**不**做什么（必须说清，否则会被读成"两页能用了"）】
//   · **一点也不让页面能渲染** —— 分页引擎（`Fs*` 一族）仍然不存在；
//   · **也不改变"崩不崩"** —— 救进程的是同批的 `A2`（拆毒池项），不是这里；
//   · 它不是"托底桩"，是"**诚实拒绝**"。
//
// 【🔴 本文件唯一的自杀式改法（写在这里，免得后人"顺手"）】
//   把下面任何一个入口的 `return` 改成 `0`（看起来更"能跑"）⇒ `CreateDocContext` 会交出
//   **假句柄** ⇒ `PtsHost.Context != Zero` ⇒ 一连串 `Invariant.Assert` **全过** ⇒
//   页面**空白但进程活着** ⇒ **没有任何红**。那正是本仓最忌讳的"**静默半通**"。
//   两道牙防它：① `WpfLinuxWin32_PtsGapSelfCheck()`（本文件，机器可读，今天必须返回 1；
//   谁把 stub 改成返回 0 ⇒ 它立刻变 0）；② `W78A-report.md` §3.2 的 `N2` 反极性
//   （真去改成 0 ⇒ 产品判据必须变红；读数见 `build/MilBridge/W86A-report.md` §5）。
//
// 【台账形状】与仓内既有的具名台账同一风格（`seq=` 序号 + `entry=` 名字 + 数值字段）：
//     PTS_GAP entry=CreateInstalledObjectsInfo seq=1 err=-10000 calls=1
//   · **默认开**：这是**能力缺口**，不是调试噪声 —— 缺件必须不用设环境变量就能看见
//     （仓内纪律："不许静默"）。但**有界**（默认 64 行，`WPF_LINUX_PTS_DIAG=<n>` 改界，
//     `WPF_LINUX_PTS_DIAG=0` 关）⇒ 不会变成刷屏器；
//   · 每次调用打一条（含重复调用），打满界后补一条 `PTS_GAP ledger=truncated …` 收尾。
// ============================================================================

#include "win32_internal.h"

#include <stdio.h>
#include <stdlib.h>     // getenv / atoi
#include <string.h>

// ── LsErr 码：`tserrNotImplemented` ─────────────────────────────────────────
// 出处：上游 `PresentationFramework/MS/Internal/PtsHost/Pts.cs:507`（`internal const int tserrNotImplemented = -10000;`）。
// 选这个码而不是自造：托管侧**已经认识它**（`PtsHost.cs:571` 起 20 余处回调就返回它），
// 且 `PTS.Validate` 对任何非 `fserrNone` 都抛 `PtsException`（`Pts.cs:40-72`）。
#define WPF_PTS_ERR_NOT_IMPLEMENTED   (-10000)

// ── 具名台账（本文件的唯一状态）─────────────────────────────────────────────
// 6 个入口的名字 + 各自被调次数。名字是**导出名的逐字**（托管侧 P/Invoke 的 EntryPoint）。
static const char *const k_pts_entries[] = {
    "CreateInstalledObjectsInfo",
    "DestroyInstalledObjectsInfo",
    "CreateDocContext",
    "DestroyDocContext",
    "GetFloaterHandlerInfo",
    "GetTableObjHandlerInfo",
    "LoCreateContext",
    "LoAcquirePenaltyModule",
    "LoGetPenaltyModuleInternalHandle",
};
#define WPF_PTS_ENTRY_COUNT ((int)(sizeof(k_pts_entries) / sizeof(k_pts_entries[0])))

static int g_pts_calls[WPF_PTS_ENTRY_COUNT];   // 逐入口调用次数
static int g_pts_seq = 0;                      // 全局调用序号（1 起）
static int g_pts_printed = 0;                  // 已打印的台账行数
static int g_pts_budget = -1;                  // -1 = 还没读环境；0 = 关闭；>0 = 行数上限
static int g_pts_truncation_noted = 0;

static int wpf_pts_budget(void)
{
    if (g_pts_budget >= 0) return g_pts_budget;
    const char *e = getenv("WPF_LINUX_PTS_DIAG");
    if (e && *e == '0' && e[1] == '\0') { g_pts_budget = 0; return 0; }   // 显式关闭
    int n = 64;                                                          // 缺省界
    if (e && *e) { int v = atoi(e); if (v > 0) n = v; }
    g_pts_budget = n;
    return n;
}

// 入口索引（找不到 ⇒ -1；台账里一律以名字为准，索引只用来累加计数）
static int wpf_pts_index(const char *entry)
{
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) {
        if (strcmp(k_pts_entries[i], entry) == 0) return i;
    }
    return -1;
}

// 每一次调用走这里：记账 + 打印 + 返回**非零**错误码。
// `notimpl` 参数恒为 1 —— 它存在的意义是让"这个函数永远不成功"在**签名上**就看得见。
static int wpf_pts_gap(const char *entry)
{
    int idx = wpf_pts_index(entry);
    int calls = 0;
    if (idx >= 0) calls = ++g_pts_calls[idx];
    int seq = ++g_pts_seq;

    int budget = wpf_pts_budget();
    if (budget > 0 && g_pts_printed < budget) {
        g_pts_printed++;
        fprintf(stderr, "PTS_GAP entry=%s seq=%d err=%d calls=%d\n",
                entry, seq, WPF_PTS_ERR_NOT_IMPLEMENTED, calls);
        fflush(stderr);
        if (g_pts_printed == budget && !g_pts_truncation_noted) {
            g_pts_truncation_noted = 1;
            fprintf(stderr,
                    "PTS_GAP ledger=truncated printed=%d total_calls=%d budget=%d "
                    "（后续同名缺口不再逐条打印；改 WPF_LINUX_PTS_DIAG=<n> 调界）\n",
                    g_pts_printed, seq, budget);
            fflush(stderr);
        }
    }
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

// ══════════════════════════════════════════════════════════════════════════
//  6 个入口（托管声明在 `Pts.cs:3064-3098`；C 侧的形参指针**不 deref**）
// ══════════════════════════════════════════════════════════════════════════
//
// 【为什么形参是 `void *` 而不是上游 `FS*` 结构】
//   本文件**一个字段也不读**（读了也没有意义：我们不做这件事）。用 `void *` 是刻意让
//   "不 deref" 在类型上成立；上游那些结构（`FSIMETHODS`/`FSCONTEXTINFO`…）的**布局**归
//   真实现去对（那时才需要 `win32_abi.h` 里的镜像结构）。托管侧的 marshalling 只看
//   "传一个指针进来"，与 C 侧形参叫什么无关。
//
// 【出参：一律写"空/0"，绝不写伪造值】
//   失败时把出参清成 `NULL`/`0`/`Zero`（不是留着未初始化内存，也不是给个假句柄）。
//   ⇒ 即使调用方**不查返回值**（错误用法，但可能发生），拿到的也是"空"，而不是"假"。

int CreateInstalledObjectsInfo(const void *fssubtrackparamethods,
                               const void *fssubpageparamethods,
                               void **pInstalledObjects,
                               int *cInstalledObjects)
{
    (void)fssubtrackparamethods;
    (void)fssubpageparamethods;
    if (pInstalledObjects) *pInstalledObjects = NULL;
    if (cInstalledObjects) *cInstalledObjects = 0;
    return wpf_pts_gap("CreateInstalledObjectsInfo");
}

int DestroyInstalledObjectsInfo(void *pInstalledObjects)
{
    (void)pInstalledObjects;
    return wpf_pts_gap("DestroyInstalledObjectsInfo");
}

int CreateDocContext(const void *fscontextinfo, void **pfscontext)
{
    (void)fscontextinfo;
    if (pfscontext) *pfscontext = NULL;
    return wpf_pts_gap("CreateDocContext");
}

int DestroyDocContext(void *pfscontext)
{
    (void)pfscontext;
    return wpf_pts_gap("DestroyDocContext");
}

int GetFloaterHandlerInfo(const void *pfsfloaterinit, void *pFloaterObjectInfo)
{
    (void)pfsfloaterinit;
    (void)pFloaterObjectInfo;
    return wpf_pts_gap("GetFloaterHandlerInfo");
}

int GetTableObjHandlerInfo(const void *pfstableobjinit, void *pTableObjectInfo)
{
    (void)pfstableobjinit;
    (void)pTableObjectInfo;
    return wpf_pts_gap("GetTableObjHandlerInfo");
}

// 批 2a：LS 构造期的 3 条，与既有 6 条同形（诚实失败 + 具名台账）。
// 托管返回类型 = `LsErr`（`LineServices.cs:1407/1570/1581`）⇒ 失败值 = -10000，出参一律置零。
// 调用方**都**检查返回码并 ThrowExceptionFromLsError（`TextFormatterContext.cs:113`、
// `TextPenaltyModule.cs:26`、`:80`）⇒ 不会被静默吞掉（机械读数 bare_calls=0 与它一致）。
int LoCreateContext(const void *lscontextinfo, void **pfscontext)
{
    (void)lscontextinfo;
    if (pfscontext) *pfscontext = NULL;
    return wpf_pts_gap("LoCreateContext");
}

int LoAcquirePenaltyModule(void *ploc, void **penaltyModuleHandle)
{
    (void)ploc;
    if (penaltyModuleHandle) *penaltyModuleHandle = NULL;
    return wpf_pts_gap("LoAcquirePenaltyModule");
}

int LoGetPenaltyModuleInternalHandle(void *penaltyModuleHandle, void **internalHandle)
{
    (void)penaltyModuleHandle;
    if (internalHandle) *internalHandle = NULL;
    return wpf_pts_gap("LoGetPenaltyModuleInternalHandle");
}

// ══════════════════════════════════════════════════════════════════════════
//  机器可读面（照 `WpfLinuxWin32_EscStringSelfCheck` / `ClassificationSelfCheck` 的形状）
// ══════════════════════════════════════════════════════════════════════════

// 已见缺口的**不同入口**数（0 = 今天没人问过 PTS 上下文族）。
int WpfLinuxWin32_PtsGapCount(void)
{
    int n = 0;
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) if (g_pts_calls[i] > 0) n++;
    return n;
}

// 累计调用次数（含重复）。
int WpfLinuxWin32_PtsGapCalls(void) { return g_pts_seq; }

// 第 idx 个"见过"的入口名写进 buf（nul 结尾）。命中 ⇒ 返回 1，越界/无 ⇒ 0。
int WpfLinuxWin32_PtsGapEntryName(int idx, char *buf, int cap)
{
    if (!buf || cap <= 0) return 0;
    int seen = 0;
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) {
        if (g_pts_calls[i] <= 0) continue;
        if (seen == idx) {
            snprintf(buf, (size_t)cap, "%s", k_pts_entries[i]);
            return 1;
        }
        seen++;
    }
    buf[0] = '\0';
    return 0;
}

// 一行机读摘要：写进 buf（nul 结尾）并返回写入长度（不含 nul）；buf 太小 ⇒ 返回 -1。
int WpfLinuxWin32_PtsGapReport(char *buf, int cap)
{
    if (!buf || cap <= 0) return -1;
    char first[64] = "-", last[64] = "-";
    int seen = 0;
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) {
        if (g_pts_calls[i] <= 0) continue;
        if (seen == 0) snprintf(first, sizeof(first), "%s", k_pts_entries[i]);
        snprintf(last, sizeof(last), "%s", k_pts_entries[i]);
        seen++;
    }
    int n = snprintf(buf, (size_t)cap,
                     "PTS_GAP_REPORT mode=honest-fail entries=%d calls=%d first=%s last=%s err=%d",
                     seen, g_pts_seq, first, last, WPF_PTS_ERR_NOT_IMPLEMENTED);
    if (n < 0 || n >= cap) { buf[cap - 1] = '\0'; return -1; }
    return n;
}

// 自检（**这就是防"后人顺手把 return 改成 0"的那道牙**）：
//   ① 6 个入口**逐个真调一次**，返回值必须都 == -10000（非 0！）；
//   ② 出参必须被清成 NULL/0（不许留未初始化内存、不许给假句柄）；
//   ③ `WpfLinuxWin32_PtsGapReport` 必须写出一行、且含 `entries=9`、含 `err=-10000`。
//   调用本身会动台账 ⇒ 自检**保存/复原**计数，跑完台账与本进程"自检前"一致（可重复跑）。
int WpfLinuxWin32_PtsGapSelfCheck(void)
{
    int save_calls[WPF_PTS_ENTRY_COUNT], save_seq = g_pts_seq, save_printed = g_pts_printed;
    memcpy(save_calls, g_pts_calls, sizeof(save_calls));

    int old_budget = g_pts_budget;
    g_pts_budget = 0;                       // 自检期间**不打**台账（runs quiet）

    char sb[64] = { 0 }, sp[64] = { 0 };
    void *p1 = (void *)0x1; int c1 = 12345;
    void *p2 = (void *)0x2;
    // 【`#66` W158A 修订】3 个新入口**各自一个先被投毒的出参**：否则链条走到这里时 `p1`
    //   早已被第 1 条入口清成 NULL ⇒ `p1 != NULL` 那三条断言**恒不成立**（恒绿假牙）。
    void *q1 = (void *)0x33, *q2 = (void *)0x34, *q3 = (void *)0x35;
    int rc = 0;

    if (CreateInstalledObjectsInfo(sb, sp, &p1, &c1) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 1;
    else if (p1 != NULL || c1 != 0) rc = 2;
    else if (DestroyInstalledObjectsInfo((void *)0xdead) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 3;
    else if (CreateDocContext(sb, &p2) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 4;
    else if (p2 != NULL) rc = 5;
    else if (DestroyDocContext((void *)0xdead) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 6;
    else if (GetFloaterHandlerInfo(sb, sp) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 7;
    else if (GetTableObjHandlerInfo(sb, sp) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 8;
    else if (LoCreateContext(sb, &q1) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 11;
    else if (q1 != NULL) rc = 12;
    else if (LoAcquirePenaltyModule(sb, &q2) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 13;
    else if (q2 != NULL) rc = 14;
    else if (LoGetPenaltyModuleInternalHandle(sb, &q3) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 15;
    else if (q3 != NULL) rc = 16;

    if (rc == 0) {
        char rep[256];
        if (WpfLinuxWin32_PtsGapReport(rep, (int)sizeof(rep)) <= 0) rc = 9;
        else if (!strstr(rep, "entries=9") || !strstr(rep, "err=-10000")) rc = 10;
    }

    // 复原台账（自检不许改变可观测状态）
    memcpy(g_pts_calls, save_calls, sizeof(save_calls));
    g_pts_seq = save_seq;
    g_pts_printed = save_printed;
    g_pts_budget = old_budget;
    return rc == 0 ? 1 : 0;
}

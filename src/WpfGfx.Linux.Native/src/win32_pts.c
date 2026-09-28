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
//   ⚠️ 格 1（`t12`）后：`CreateInstalledObjectsInfo`/`DestroyInstalledObjectsInfo` 已**真实现**
//      ⇒ 自检对这两条断言的是「**成功（0）＋ 真对象 ＋ 摧毁后无泄漏 ＋ 重复/未知名释放必被拒**」，
//      对其余 **7** 条 stub 仍断言「返回 `-10000` 且出参清空」（`entries=7`）。
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
    "LoDestroyContext",
};
#define WPF_PTS_ENTRY_COUNT ((int)(sizeof(k_pts_entries) / sizeof(k_pts_entries[0])))

// ── 格 1（`TASK-0302` 首个真增量，`t12`）：installed-objects 表的**真对象**状态 ────────
//   契约：`Pts.cs:3077` `internal static extern int CreateInstalledObjectsInfo(ref FSIMETHODS,
//   ref FSIMETHODS, out IntPtr pInstalledObjects, out int cInstalledObjects)`。
//   本实现是**真的对象**：真实分配 / 真实表长 / 原样存下托管给的指针（**不 deref**）/
//   真摧毁 + 逐项计数。⚠️ 它**不**让页面渲染 —— 前沿只位移一跳（idx0 ⇒ idx6 `LoCreateContext`）。
#define WPF_PTS_IO_MAGIC   0x50545349u   /* "PTSI"：本模块自认的表头魔数 */
#define WPF_PTS_IO_MAX     8             /* 有界分配清单（防被异常调用无限增长） */
typedef struct {
    unsigned int magic;
    const void  *subtrack_methods;       /* 托管传进来的指针，**原样存** */
    const void  *subpage_methods;
    int          entries;                /* 表长（真值：两槽） */
} wpf_pts_io_table;

static wpf_pts_io_table *g_pts_io_live[WPF_PTS_IO_MAX];
static int g_pts_io_live_n  = 0;         /* 活对象数（**泄漏检查的唯一真值**） */
static int g_pts_io_creates = 0;
static int g_pts_io_destroys= 0;
static int g_pts_io_rejected= 0;         /* 拒绝的摧毁请求（未知名/重复/清单满） */

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

// 【**表序 ≠ 调用序**】`CreatePTSContext`（`PtsCache.cs:433-462`）的实际调用顺序是
//   `0 → 6 → 7 → 8 → 2`；而销毁项（`1`,`3`）与浮动/表格项（`4`,`5`）**不在**创建链上
//   （`4`/`5` 只在 native→managed 回调里被调：`PtsHost.cs:1094/1098` → `PtsCache.cs:259/278`）。
//   ⇒ `first=`（表序最小）与 `last=`（表序最大）**都不是**可靠前沿（`t4` 实测）；
//     `frontier=` 按**调用序**取"第一个真的被问到且如实失败的入口"。
static const int k_pts_call_order[] = { 0, 6, 7, 8, 2, 1, 3, 4, 5, 9 };
#define WPF_PTS_CALL_ORDER_COUNT ((int)(sizeof(k_pts_call_order) / sizeof(k_pts_call_order[0])))

// 前沿名（调用序上第一个 `g_pts_calls>0` 的入口；无 ⇒ "-"）
static void wpf_pts_frontier(char *buf, size_t cap)
{
    buf[0] = '\0';
    for (int k = 0; k < WPF_PTS_CALL_ORDER_COUNT; k++) {
        int i = k_pts_call_order[k];
        if (i >= 0 && i < WPF_PTS_ENTRY_COUNT && g_pts_calls[i] > 0) {
            snprintf(buf, cap, "%s", k_pts_entries[i]);
            return;
        }
    }
    snprintf(buf, cap, "%s", "-");
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

// 【格 1 · 真实现】成功 ⇒ **返回 0**（`fserrNone`）；出参 = 真实表指针 + 真实表长（两槽）。
//   ⚠️ 绝**不**返回 `-10000` 而同时给出非空句柄 —— 那是自相矛盾的假对象（本仓最忌讳的形态）。
//   ⚠️ 两个入参指针只被**存下来**，一个字节都不 deref（沿用件头纪律）。
int CreateInstalledObjectsInfo(const void *fssubtrackparamethods,
                               const void *fssubpageparamethods,
                               void **pInstalledObjects,
                               int *cInstalledObjects)
{
    if (pInstalledObjects) *pInstalledObjects = NULL;   // 出参先清空（任何失败路径都保持"空"）
    if (cInstalledObjects) *cInstalledObjects = 0;
    if (!pInstalledObjects || !cInstalledObjects) { g_pts_io_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    if (g_pts_io_live_n >= WPF_PTS_IO_MAX)        { g_pts_io_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    wpf_pts_io_table *t = (wpf_pts_io_table *)calloc(1, sizeof(*t));
    if (!t)                                       { g_pts_io_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    t->magic            = WPF_PTS_IO_MAGIC;
    t->subtrack_methods = fssubtrackparamethods;        /* 原样存，不 deref */
    t->subpage_methods  = fssubpageparamethods;
    t->entries          = 2;                            /* subtrack + subpage 两槽（真值） */
    g_pts_io_live[g_pts_io_live_n++] = t;
    g_pts_io_creates++;
    *pInstalledObjects = (void *)t;
    *cInstalledObjects = t->entries;
    return 0;                                           /* ← 改成别的值就是制造静默半通 */
}

// 【格 1 · 真实现】成功 ⇒ 返回 0；**未知名 / 重复释放 / 空指针 ⇒ 返回非零且一个字节都不 free**
//   （不对任意指针 free；句柄身份由本模块自己的分配清单 + 魔数认定）。
int DestroyInstalledObjectsInfo(void *pInstalledObjects)
{
    if (!pInstalledObjects) { g_pts_io_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    for (int i = 0; i < g_pts_io_live_n; i++) {
        if ((void *)g_pts_io_live[i] != pInstalledObjects) continue;
        if (g_pts_io_live[i]->magic != WPF_PTS_IO_MAGIC) { g_pts_io_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
        g_pts_io_live[i]->magic = 0;                    // 先失效 ⇒ 重复释放必被拒
        free(g_pts_io_live[i]);
        g_pts_io_live[i] = g_pts_io_live[--g_pts_io_live_n];
        g_pts_io_live[g_pts_io_live_n] = NULL;
        g_pts_io_destroys++;
        return 0;
    }
    g_pts_io_rejected++;
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
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
//
// ── 格 2（`TASK-0302` 第 2 个真增量 · 车道 `t63`／波 W7）：`LoCreateContext` 真对象 ＋ **ABI 修正** ──
// 【为什么必须先修 ABI（本格的要害，取证在前）】托管声明（`LineServices.cs:1407-1411`）是**三参**：
//     `LsErr LoCreateContext(ref LsContextInfo contextInfo, ref LscbkRedefined lscbkRedef, out IntPtr ploc)`
//   而修前本函数是**两参**形 `(const void *, void **)` ⇒ 第二实参落在 `lscbkRedef` 上：
//     ① 把 NULL **写进调用方的回调表地址**（`*lscbkRedef = NULL`）；② **从不写 `ploc`**。
//   ⇒ 这不是"少实现"，是**签名错**；即使暂不实现语义，也必须先把指针数对齐。
// 【为什么"只做 create"会症状倒退（本车道的停手理由，逐字留档）】只把 create 做成成功 ⇒ `_ploc` 非零
//   ⇒ 清理路径 `TextFormatterContext.Destroy()`（`upstream/.../TextFormatterContext.cs:243`，由
//   `TextFormatterImp.CleanupInternal()` 逐上下文调用）会去调 `LoDestroyContext`；该入口修前**未导出**
//   （托管侧声明 18 个 `Lo*`，shim 只导出 3 个）⇒ `EntryPointNotFoundException` ⇒ 本端口注释点名的
//   `abort(134)`（`build/PresentationCore.Linux/TextFormatterImp.Linux.cs:30/160/745`）。
//   ⇒ **格 2 一次给两条**：create 成功 ⇒ destroy 必须存在且真能收（否则把"优雅降级"换成"清理期崩"）。
// 【安全边界（真销毁的纪律）】只认**本模块自己分配并登记**的句柄：未知／伪造／重复句柄**一律拒绝返回失败**，
//   **绝不 deref 任意指针** —— 先按**指针身份**在登记表里查，查不到就直接失败（不读它的任何字段）。
#define WPF_PTS_LOC_MAGIC  0x5054534cu   /* "PTSL"：本模块自认的上下文魔数 */
#define WPF_PTS_LOC_MAX    8             /* 有界分配清单（防异常调用无限增长） */
typedef struct {
    unsigned int magic;
    const void  *context_info;           /* 托管给的指针，**原样存，不 deref** */
    const void  *lscbk_redef;
} wpf_pts_loc;

static wpf_pts_loc *g_pts_loc_live[WPF_PTS_LOC_MAX];
static int g_pts_loc_live_n   = 0;       /* 活上下文数（**泄漏检查的唯一真值**） */
static int g_pts_loc_creates  = 0;
static int g_pts_loc_destroys = 0;
static int g_pts_loc_rejected = 0;       /* 被拒的销毁请求（空/未知/重复/魔数不符） */

// 【格 2 · 真实现】成功 ⇒ 返回 0（`fserrNone`）＋ `*ploc` = **真句柄**；失败 ⇒ 返回 -10000 且 `*ploc = NULL`。
//   ⚠️ 两种自相矛盾形态都禁止：**成功却给空句柄** / **失败却给非空句柄**（件头纪律）。
int LoCreateContext(const void *lscontextinfo, const void *lscbkRedef, void **ploc)
{
    if (ploc) *ploc = NULL;                                  // 任何失败路径都保持"空"
    if (!ploc)                                    { g_pts_loc_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    if (g_pts_loc_live_n >= WPF_PTS_LOC_MAX)      { g_pts_loc_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    wpf_pts_loc *c = (wpf_pts_loc *)calloc(1, sizeof(*c));
    if (!c)                                       { g_pts_loc_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    c->magic        = WPF_PTS_LOC_MAGIC;
    c->context_info = lscontextinfo;                         /* 原样存，不 deref */
    c->lscbk_redef  = lscbkRedef;
    g_pts_loc_live[g_pts_loc_live_n++] = c;
    g_pts_loc_creates++;
    *ploc = (void *)c;
    return 0;                                                /* ← 改成别的值就是制造静默半通 */
}

// 【格 2 · 真销毁】成功 ⇒ 释放 ＋ 登记表移除 ＋ 返回 0。
//   拒绝面（**四条**，都返回失败且**一个字节都不 free**）：`NULL`（未持有句柄）／未登记（未知或伪造）／
//   登记但魔数不符（已失效＝重复销毁）／登记表为空。
//   ⚠️ 本函数**只比对指针身份**；未知句柄的**内容一个字节都不读**（`0xdeadbeef` 这类值传进来必被拒且不崩）。
int LoDestroyContext(void *ploc)
{
    if (!ploc) { g_pts_loc_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    for (int i = 0; i < g_pts_loc_live_n; i++) {
        if ((void *)g_pts_loc_live[i] != ploc) continue;
        if (g_pts_loc_live[i]->magic != WPF_PTS_LOC_MAGIC) { g_pts_loc_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
        g_pts_loc_live[i]->magic = 0;                        // 先失效 ⇒ 重复销毁必被拒
        free(g_pts_loc_live[i]);
        g_pts_loc_live[i] = g_pts_loc_live[--g_pts_loc_live_n];
        g_pts_loc_live[g_pts_loc_live_n] = NULL;
        g_pts_loc_destroys++;
        return 0;
    }
    g_pts_loc_rejected++;
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
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

// 【格 1 · 只读面】活对象数 / 累计成功创建次数。**这是"真对象真的有生命周期"的机器判据**：
//   `live` 收尾必须回 0（不补 pf 侧释放 ⇒ 每失败一次漏一个，本面当场看得见）。
int WpfLinuxWin32_PtsInstalledObjectsLive(void)    { return g_pts_io_live_n; }
int WpfLinuxWin32_PtsInstalledObjectsCreates(void) { return g_pts_io_creates; }

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
    char frontier[64] = "-"; wpf_pts_frontier(frontier, sizeof(frontier));
    int n = snprintf(buf, (size_t)cap,
                     "PTS_GAP_REPORT mode=honest-fail entries=%d calls=%d first=%s last=%s err=%d "
                     "frontier=%s entry_calls=0:%d 1:%d 2:%d 3:%d 4:%d 5:%d 6:%d 7:%d 8:%d 9:%d "
                     "installed_objects_live=%d creates=%d destroys=%d rejected=%d "
                     "ls_context_live=%d creates=%d destroys=%d rejected=%d",
                     seen, g_pts_seq, first, last, WPF_PTS_ERR_NOT_IMPLEMENTED,
                     frontier,
                     g_pts_calls[0], g_pts_calls[1], g_pts_calls[2], g_pts_calls[3], g_pts_calls[4],
                     g_pts_calls[5], g_pts_calls[6], g_pts_calls[7], g_pts_calls[8], g_pts_calls[9],
                     g_pts_io_live_n, g_pts_io_creates, g_pts_io_destroys, g_pts_io_rejected,
                     g_pts_loc_live_n, g_pts_loc_creates, g_pts_loc_destroys, g_pts_loc_rejected);
    if (n < 0 || n >= cap) { buf[cap - 1] = '\0'; return -1; }
    return n;
}

// 自检（**这就是防"后人顺手把 return 改成 0"的那道牙**）：
//   ① 格1 的两条**真实现**：`Create…` 必须返回 0 且出参非空/表长 2；`Destroy…` 必须返回 0；
//      重复释放与未知名释放**必须**被拒（返回非零）；摧毁后 `live` 必须回 0；
//   ② 格 2 的两条**真实现**：`LoCreateContext` 三参形必须**成功**（返回 0 ＋ `*ploc` 非空）；
//      `LoDestroyContext`：**自己的句柄 ⇒ 0**、**重复 ⇒ 被拒**、**未知 `0xdead` ⇒ 被拒且不崩**、
//      **NULL ⇒ 被拒**；全部走完 `ls_context_live` 必须回 0（无泄漏）；
//   ③ 其余 **6 条 stub** 逐个真调一次，返回值必须都 == -10000（非 0！），出参必须被清成 NULL/0；
//   ④ `WpfLinuxWin32_PtsGapReport` 必须写出一行，含 `entries=6`、`err=-10000`、
//      `frontier=LoAcquirePenaltyModule`（**格 2 的前沿位移就在这一格**）、`installed_objects_live=0`、
//      `ls_context_live=0`。
//   调用本身会动台账 ⇒ 自检**保存/复原**计数，跑完台账与本进程"自检前"一致（可重复跑）。
int WpfLinuxWin32_PtsGapSelfCheck(void)
{
    int save_calls[WPF_PTS_ENTRY_COUNT], save_seq = g_pts_seq, save_printed = g_pts_printed;
    // 【格1 修订】自检现在会**真的**建/毁对象 ⇒ 三个 io 计数也要复原，否则"自检不许改变可观测状态"
    //   这句话对新面就成了假话（`creates`/`destroys`/`rejected` 会凭空涨）。`live` 不保存：
    //   它**必须**在自检结束时应为 0，那正是被断言的性质本身。
    int save_creates = g_pts_io_creates, save_destroys = g_pts_io_destroys, save_rejected = g_pts_io_rejected;
    // 【格2 修订】同理：LS 上下文那四个计数也要复原（`live` 不保存 —— 收尾必须回 0 是被断言的性质）。
    int save_loc_creates = g_pts_loc_creates, save_loc_destroys = g_pts_loc_destroys, save_loc_rejected = g_pts_loc_rejected;
    memcpy(save_calls, g_pts_calls, sizeof(save_calls));

    int old_budget = g_pts_budget;
    g_pts_budget = 0;                       // 自检期间**不打**台账（runs quiet）

    char sb[64] = { 0 }, sp[64] = { 0 };
    void *p1 = NULL; int c1 = 0;   /* 格1：真实现 ⇒ 期望被填成 **非空** 且表长 2 */
    void *p2 = (void *)0x2;
    // 【`#66` W158A 修订】3 个新入口**各自一个先被投毒的出参**：否则链条走到这里时 `p1`
    //   早已被第 1 条入口清成 NULL ⇒ `p1 != NULL` 那三条断言**恒不成立**（恒绿假牙）。
    void *q1 = (void *)0x33, *q2 = (void *)0x34, *q3 = (void *)0x35;
    // 【格2 修订】`LoCreateContext` 也是"先投毒再调"：修前它负责把出参清成 NULL，
    //   修后它负责**填真句柄** ⇒ 若不投毒，`loc != NULL` 那条断言会被上一轮的残留骗绿。
    void *loc = (void *)0x36;
    int rc = 0;

    if (CreateInstalledObjectsInfo(sb, sp, &p1, &c1) != 0) rc = 1;                     /* 格1：必须**成功** */
    else if (p1 == NULL || c1 != 2) rc = 2;                                            /* 真对象：非空 + 表长 2 */
    else if (WpfLinuxWin32_PtsInstalledObjectsLive() != 1) rc = 20;                    /* 创建后 live==1 */
    else if (WpfLinuxWin32_PtsInstalledObjectsCreates() < 1) rc = 21;                  /* creates 计数涨了 */
    else if (DestroyInstalledObjectsInfo(p1) != 0) rc = 3;                             /* 真摧毁 ⇒ 0 */
    else if (WpfLinuxWin32_PtsInstalledObjectsLive() != 0) rc = 22;                    /* 摧毁后 live==0 */
    else if (DestroyInstalledObjectsInfo(p1) == 0) rc = 17;                            /* **重复释放必被拒** */
    else if (DestroyInstalledObjectsInfo((void *)0xdead) == 0) rc = 18;                /* **未知名必被拒** */
    else if (CreateDocContext(sb, &p2) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 4;
    else if (p2 != NULL) rc = 5;
    else if (DestroyDocContext((void *)0xdead) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 6;
    else if (GetFloaterHandlerInfo(sb, sp) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 7;
    else if (GetTableObjHandlerInfo(sb, sp) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 8;
    /* ── 格 2：三参形 · 必须**成功** ─────────────────────────────────────────── */
    else if (LoCreateContext(sb, sp, &loc) != 0) rc = 11;                              /* 真实现 ⇒ 0 */
    else if (loc == NULL) rc = 12;                                                     /* 真句柄：非空 */
    else if (g_pts_loc_live_n != 1) rc = 25;                                           /* 创建后 live==1 */
    /* ── 格 2 两极化：真销毁 / 重复 / 未知 / NULL ─────────────────────────────── */
    else if (LoDestroyContext(loc) != 0) rc = 26;                                      /* ① 自己的句柄 ⇒ 0 */
    else if (g_pts_loc_live_n != 0) rc = 27;                                           /* 销毁后 live==0 */
    else if (LoDestroyContext(loc) == 0) rc = 28;                                      /* ② **重复必被拒** */
    else if (LoDestroyContext((void *)0xdeadbeef) == 0) rc = 29;                       /* ③ **未知必被拒（不 deref）** */
    else if (LoDestroyContext(NULL) == 0) rc = 30;                                     /* ④ **NULL 必被拒** */
    else if (LoAcquirePenaltyModule(sb, &q2) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 13;
    else if (q2 != NULL) rc = 14;
    else if (LoGetPenaltyModuleInternalHandle(sb, &q3) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 15;
    else if (q3 != NULL) rc = 16;

    if (rc == 0) {
        char rep[384];
        if (WpfLinuxWin32_PtsGapReport(rep, (int)sizeof(rep)) <= 0) rc = 9;
        else if (!strstr(rep, "entries=6") || !strstr(rep, "err=-10000")) rc = 10;      /* 格2：只剩 6 条 stub */
        else if (!strstr(rep, "frontier=LoAcquirePenaltyModule")) rc = 23;              /* **格2：前沿已位移** */
        else if (!strstr(rep, "installed_objects_live=0")) rc = 24;                     /* 无泄漏（格1） */
        else if (!strstr(rep, "ls_context_live=0")) rc = 31;                            /* 无泄漏（格2） */
    }

    // 复原台账（自检不许改变可观测状态）
    memcpy(g_pts_calls, save_calls, sizeof(save_calls));
    g_pts_io_creates = save_creates; g_pts_io_destroys = save_destroys; g_pts_io_rejected = save_rejected;
    g_pts_loc_creates = save_loc_creates; g_pts_loc_destroys = save_loc_destroys; g_pts_loc_rejected = save_loc_rejected;
    g_pts_seq = save_seq;
    g_pts_printed = save_printed;
    g_pts_budget = old_budget;
    return rc == 0 ? 1 : 0;
}

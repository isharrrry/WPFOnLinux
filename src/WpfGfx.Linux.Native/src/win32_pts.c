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
// ⏪ **dated 更正（`t81`，2026-09-28；只改注释，与现盘对齐）**：本行原文写「**6 个入口**的名字 ＋ 各自被调次数」
//   —— 那是本文件只导出 6 条 stub 时的说法。**现盘该表 12 名**（表区间内 `grep -c '"'` 现取 ＝ 12，
//   `WPF_PTS_ENTRY_COUNT` 同值），故按实写清三件事：
//   ① **本表 ＝ 本文件登记入口的名字表**（名字是**导出名的逐字**，托管侧 P/Invoke 的 `EntryPoint`）。
//      它是 `wpf_pts_gap()` 打台账时的**取名来源**（`PTS_GAP entry=<名>`），也是 `PTS_GAP_REPORT`
//      里 `frontier=`／`anchor=`／逐条 `calls=` 的**取值域**。表**只列名字**，不表示"这条是缺口"。
//   ② **`g_pts_calls[]` 只对走 `wpf_pts_gap()` 的「缺口 stub」涨** —— 真实现入口（`CreateInstalledObjectsInfo`／
//      `DestroyInstalledObjectsInfo`／`LoCreateContext`／`LoDestroyContext`／`LoSetDoc`／`LoSetBreaking`）
//      在它里面**恒 0，现场可证**：`WpfLinuxWin32_PtsGapReport()` 那一行自检期现读
//      `calls=0:0 1:0 2:1 3:1 4:1 5:1 6:0 7:1 8:1 9:0 10:0 11:0`（`6`＝`LoCreateContext`、
//      `10`＝`LoSetDoc`、`11`＝`LoSetBreaking` 三格**都是 0**，而它们此刻**真的被调过**）。
//      ⚠️ 那条"真的被调过"由**另一个表**承担：`g_pts_seen[]`（`t81` 加）—— 见下面 `wpf_pts_frontier()` 前后的
//      「统一口径」注释块；自检的格 `23` 就是拿 `g_pts_seen[]` 断言这两条非零。
//   ③ 因此"真实现入口进此表"的**唯一作用**是：让台账/报告能给出**名字**（前沿／`anchor=`／逐条计数域），
//      **不**参与"缺口数"的语义；缺口数由 `pts-gap-count-check.sh` 按 `return wpf_pts_gap("…")` 的**条数**
//      独立数（`t81` 后 10 → 8：`LoSetDoc`／`LoSetBreaking` 不再走它）。
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
    "LoSetDoc",
    "LoSetBreaking",
    "LoDisposePenaltyModule",
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

static int g_pts_calls[WPF_PTS_ENTRY_COUNT];   // 逐入口**缺口**次数（只有走 `wpf_pts_gap()` 的 stub 会涨）
// ── 格 3 修订（`t81`）：**"被问过"的统一口径** ─────────────────────────────────
//   `g_pts_calls[]` 只记**缺口**（stub 走的路径）⇒ **真实现**（`CreateInstalledObjectsInfo`／
//   `LoCreateContext`／新补的 `LoSetDoc`…）**在它眼里等于没被问过** ⇒ `wpf_pts_frontier()`
//   会把"前沿"报成一个**还没轮到的 stub**（本趟实测：`LoAcquirePenaltyModule`，格号 23）。
//   新增 `g_pts_seen[]`：**每一条入口**（stub 或真实现）被调一次就 +1 ⇒ 前沿按**调用序**
//   取"第一个真被问到的入口"，stub 与真实现**同权**。`g_pts_calls[]` 语义**一字不改**。
static int g_pts_seen[WPF_PTS_ENTRY_COUNT];
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
static const int k_pts_call_order[] = { 0, 6, 7, 8, 9, 10, 2, 1, 3, 4, 5, 11, 12 };
#define WPF_PTS_CALL_ORDER_COUNT ((int)(sizeof(k_pts_call_order) / sizeof(k_pts_call_order[0])))

// 前沿名（调用序上第一个 `g_pts_calls>0` 的入口；无 ⇒ "-"）
static void wpf_pts_frontier(char *buf, size_t cap)
{
    buf[0] = '\0';
    for (int k = 0; k < WPF_PTS_CALL_ORDER_COUNT; k++) {
        int i = k_pts_call_order[k];
        if (i >= 0 && i < WPF_PTS_ENTRY_COUNT && g_pts_seen[i] > 0) {
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
    if (idx >= 0) { calls = ++g_pts_calls[idx]; g_pts_seen[idx]++; }   /* 格3：缺口也记"被问过" */
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
    { int _i = wpf_pts_index("CreateInstalledObjectsInfo"); if (_i >= 0) g_pts_seen[_i]++; }  /* 格3 */
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
    /* ── 格 3：`LoSetDoc` 真落盘的三个参数（**在这个对象上**，不是全局单例）──────────
       · `isDisplay`（托管侧恒传真：`TextFormatterContext.cs` 的 `SetDoc(true, true, ref devRes)`）；
       · `is_ref_equal`（参考设备与呈现设备是否同一）；
       · 四个 `uint`（`LsDevRes` 四字段）——托管侧 `ref` 传进来的是**指向托管 16 字节结构**的指针，
         **本模块一个字节都 不 deref**（件头纪律）：每字段**逐字段按真实类型读**（`const u32 *`），
         读的是**调用方此刻的有效内存**（该结构在调用期间被 `GC.KeepAlive` 钉住）。
         读到的值**落进本对象** ⇒ 调用返回后仍可被**独立读取**（自检据此断言，不依赖调用方还活着）。 */
    int          doc_is_display;
    int          doc_is_ref_equal;
    unsigned int dev_dxp_inch;
    unsigned int dev_dyp_inch;
    unsigned int dev_dxr_inch;
    unsigned int dev_dyr_inch;
    int          doc_sets;               /* 本对象上成功落盘的 LoSetDoc 次数 */
    /* ── 格 3：`LoSetBreaking` 真落盘的 `strategy`（同样**在本对象上**）────────────── */
    int          break_strategy;
    int          break_sets;             /* 本对象上成功落盘的 LoSetBreaking 次数 */
    /* ── 格 4（`t97`／P8 第二步 · W8-2）：`LoAcquirePenaltyModule` 真落盘的**罚分模块句柄** ──
       上游签名（`LineServices.cs:1569`）：`LsErr LoAcquirePenaltyModule(IntPtr ploc, out IntPtr penaltyModuleHandle)`
       ⇒ 出参是**句柄**。本实现把出参指向**本对象上的这个字段**（`&c->penalty_module_handle`），于是：
         ① 它**与该上下文对象绑定**（**不是**进程级全局单例 ⇒ 第二个上下文各指各的、不串味）；
         ② 它**只是一个地址**：本模块对"调用方随后拿它做什么"**不读、不 deref**（件头纪律）；
         ③ 它的**身份可被机器核**：只要 `*out == &某在册对象->penalty_module_handle` ⇒ 绑定成立。 */
    void        *penalty_module_handle;
    int          penalty_acquisitions;   /* 本对象上成功落盘的 LoAcquirePenaltyModule 次数 */
    /* ── 格 5（`t103`／W8-3）：`LoGetPenaltyModuleInternalHandle` 真落盘的**内部句柄** ──
       上游签名（`LineServices.cs:1580`）：`LsErr LoGetPenaltyModuleInternalHandle(IntPtr penaltyModuleHandle,
       out IntPtr penaltyModuleInternalHandle)`。⚠️ **入参是"罚分模块句柄"，不是 `ploc`** ——
       本模块把 `penalty_module_handle` 取成**本对象上那个字段的地址** ⇒ 模块句柄本身就是
       `wpf_pts_loc *` 的**指针值**（**无需**任何结构内偏移推算：字段就在结构里 ⇒ `指针身份` 直接可比）。
       本格把内部句柄也**落在这个对象上**（＝与"哪个模块"绑定、**不是**进程级全局单例）。 */
    void        *penalty_internal_handle;
    int          penalty_internal_gets;  /* 本对象上成功落盘的 LoGetPenaltyModuleInternalHandle 次数 */
} wpf_pts_loc;

static wpf_pts_loc *g_pts_loc_live[WPF_PTS_LOC_MAX];
static int g_pts_loc_live_n   = 0;       /* 活上下文数（**泄漏检查的唯一真值**） */
static int g_pts_loc_creates  = 0;
static int g_pts_loc_destroys = 0;
static int g_pts_loc_rejected = 0;       /* 被拒的销毁请求（空/未知/重复/魔数不符） */

// ── 格 3（`TASK-0302` 第 3 个真增量 · 车道 `t81`／波 W13）：`LoSetDoc` / `LoSetBreaking` ──
// 【为什么先补这两条（取证在前）】应用冷启链 `PtsCache.Linux.cs:532` → `TextFormatterContext.Init()`：
//   `:113 LoCreateContext`（格 2 已真实现）→ `SetDoc`（`:354 LoSetDoc`）→ `SetBreaking`（`:257 LoSetBreaking`）。
//   修前这两条**未导出** ⇒ CLR 在**绑定期**抛 `EntryPointNotFoundException`（名字只是异常文本），
//   台账**挂不上**（`native_gap=0`）⇒ 应用侧只能记 `entry=<名>`、`err` 回落 -10000。
// 【诚实分界（`t80` §1.2 逐字）】`return LsErr.None` **本身不是证据**；证据是「这次调用在本进程内留下
//   **与该 `ploc` 绑定**、**可被独立读取**的状态变化」。本格四件套：
//     ① **句柄身份校验**：只认 `LoCreateContext` 自己发过、且仍在登记表里的 `ploc`；未知/伪造/NULL
//        ⇒ **失败返回且一个字节都不读**（与 `LoDestroyContext` 的四条拒绝面同形）；
//     ② **参数真落盘**：三个文档参数落到**该上下文对象**上（**不是**进程级全局单例 ⇒ 第二个上下文不串味）；
//     ③ **计数**：成功/被拒各一对（供自检断言）；
//     ④ **可独立读取**：一个短的**观测镜**（`wpf_pts_jmp_*`）记下「刚才是**哪个** `ploc` 地址、
//        落了**什么**值」—— 它是**镜像**（供机器读），**权威**始终是上下文对象本身（自检逐字段对拍两者）。
//   ⚠️ 本格**不**实现 LS 排版语义：不解释 `isDisplay`／`strategy` 的下游含义，不生成行/子行 —— 那是后续跳。
#define WPF_PTS_JMP_MAGIC 0x5054534au   /* "PTSJ"：本模块自认的观测镜条目魔数 */
#define WPF_PTS_JMP_MAX   4             /* 有界（防被异常调用无限增长） */

typedef struct {
    unsigned int   magic;
    const char    *entry;               /* 入口名（**逐字**取自 k_pts_entries[]） */
    const void    *ploc;                /* 这次调用的句柄（**原样存，不 deref**） */
    const void    *dev;                 /* LoSetDoc：托管 `ref LsDevRes` 的地址（**原样存，不 deref**） */
    int            addr_ok;             /* LoSetDoc：该地址**逐位等于**某个在册上下文的 dev 字段地址 */
    int            a0, a1, a2, a3;      /* 记下的整数值：Doc = isDisplay/isRef/4×uint；Breaking = strategy */
    int            is_doc;
    /* ⏪ `t97` 加：**指针值的专用域**。⚠️ 本趟实测的坑：把 64 位句柄塞进 `int a0` 会被**截断**
       （`0x615841e754f0 → 1105679600`），自检拿 `(size_t)(unsigned)a0` 与真指针比 ⇒ **恒不等** ⇒ 假红。
       ⇒ 凡**指针量**一律走这两个域（`int` 域只留给真正的小整数：标志/策略/标量）。 */
    const void    *ptr0;                /* 入口相关的**指针**值（格4：`LoAcquirePenaltyModule` 的出参句柄） */
    const void    *ptr1;                /* 备用（留给后续格；今天恒 NULL） */
} wpf_pts_jmp;
static wpf_pts_jmp g_pts_jmp[WPF_PTS_JMP_MAX];
static int g_pts_jmp_head = 0;          /* 写指针（环形，最旧被覆盖） */
static int g_pts_jmp_n    = 0;          /* 有效条目数（≤ WPF_PTS_JMP_MAX） */

static int g_pts_doc_sets        = 0;   /* LoSetDoc：成功次数 */
static int g_pts_doc_rejected    = 0;   /* LoSetDoc：被拒次数（未知名/NULL/空出参口径） */
static int g_pts_break_sets      = 0;   /* LoSetBreaking：成功次数 */
static int g_pts_break_rejected  = 0;   /* LoSetBreaking：被拒次数 */
static int g_pts_pen_sets         = 0;   /* LoAcquirePenaltyModule：成功次数（格 4） */
static int g_pts_pen_rejected     = 0;   /* LoAcquirePenaltyModule：被拒次数（NULL/未知/空出参） */
static int g_pts_inth_sets        = 0;   /* LoGetPenaltyModuleInternalHandle：成功次数（格 5） */
static int g_pts_inth_rejected    = 0;   /* LoGetPenaltyModuleInternalHandle：被拒次数（NULL/未知/空出参） */

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
    { int _i = wpf_pts_index("LoCreateContext"); if (_i >= 0) g_pts_seen[_i]++; }  /* 格3：真实现也记"被问过" */
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

// ── 格 3 内部工具：句柄身份校验（**唯一**合法入口）─────────────────────────────
//   只按**指针身份**在登记表里查；查不到 ⇒ 返回 NULL，**一个字节都不读**（沿用格 2 纪律）。
static wpf_pts_loc *wpf_pts_loc_find(const void *ploc)
{
    if (!ploc) return NULL;
    for (int i = 0; i < g_pts_loc_live_n; i++) {
        if ((const void *)g_pts_loc_live[i] != ploc) continue;
        if (g_pts_loc_live[i]->magic != WPF_PTS_LOC_MAGIC) return NULL;   // 已失效 ⇒ 与"未知"同办
        return g_pts_loc_live[i];
    }
    return NULL;                                                          // **不 deref 未知句柄**
}

// ── 格 3 观测镜（**镜像**，不是权威）─────────────────────────────────────────
//   记下刚才是哪个 `ploc` 地址、落了什么值、以及"数据指针是否真的落在某个在册对象上"。
//   ⚠️ 权威永远是**上下文对象**本身；本镜只让自检能**独立读取**并把两者逐字段对拍。
static void wpf_pts_jmp_push(const char *entry, const void *ploc, const void *dev, int addr_ok,
                             int is_doc, int a0, int a1, int a2, int a3,
                             const void *ptr0, const void *ptr1)
{
    wpf_pts_jmp *e = &g_pts_jmp[g_pts_jmp_head];
    e->magic   = WPF_PTS_JMP_MAGIC;
    e->entry   = entry;
    e->ploc    = ploc;
    e->dev     = dev;
    e->addr_ok = addr_ok;
    e->is_doc  = is_doc;
    e->a0 = a0; e->a1 = a1; e->a2 = a2; e->a3 = a3;
    e->ptr0 = ptr0; e->ptr1 = ptr1;      /* `t97`：指针量走**专用域**（`int` 会截断 64 位地址） */
    g_pts_jmp_head = (g_pts_jmp_head + 1) % WPF_PTS_JMP_MAX;
    if (g_pts_jmp_n < WPF_PTS_JMP_MAX) g_pts_jmp_n++;
}

// 第 idx 条（0 = **最近**一条；越界/无 ⇒ NULL）
static const wpf_pts_jmp *wpf_pts_jmp_get(int idx)
{
    if (idx < 0 || idx >= g_pts_jmp_n) return NULL;
    int k = (g_pts_jmp_head - 1 - idx + WPF_PTS_JMP_MAX * 2) % WPF_PTS_JMP_MAX;
    const wpf_pts_jmp *e = &g_pts_jmp[k];
    return e->magic == WPF_PTS_JMP_MAGIC ? e : NULL;
}

// ── 格 3 探针（**两态可区分**的机器可读面）───────────────────────────────────
//   在观测镜里找「ploc == 给定地址 ∧ entry == 给定名」的**最近**一条，把记下的整数值**原样吐出**：
//     找到 ⇒ 返回 1，`*a0..*a3` ＝ 该条记下的四个整数（Doc：isDisplay／isRefEqual／dev 前两字段；
//            Breaking：strategy）；`*addr_ok` ＝ 该条记的"数据地址是否真落在在册对象上"。
//     没找到 ⇒ 返回 0，出参**全部清零**（**绝不**留下上一位的残留 ⇒ 否则会造出"恒绿假牙"）。
//   形状照 `WpfLinuxWin32_PtsGapEntryName`（纯读、可外部调用、越界即响亮返回 0）。
// ⏪ `t97` 附加只读口：取该条记下的**指针域**（`ptr0`／`ptr1`）。语义与 `PtsJmpProbe` 同：
//   命中 ⇒ 返回 1 并写 `*p0`／`*p1`；未命中／越界 ⇒ 返回 0 且 `*p0 = *p1 = NULL`（**绝不留残留**）。
//   ⚠️ 为什么另开一口而不是加进 `PtsJmpProbe`：那个口的签名已被**既有消费面**（本文件自检）用着，
//      改签名会动既有断言；本口**只增不改**（既有 6 参数口一字未动）。
int WpfLinuxWin32_PtsJmpProbePtr(const char *entry, void *ploc, const void **p0, const void **p1)
{
    if (p0) *p0 = NULL;
    if (p1) *p1 = NULL;
    if (!entry || !ploc) return 0;
    for (int i = 0; i < g_pts_jmp_n; i++) {
        const wpf_pts_jmp *e = wpf_pts_jmp_get(i);
        if (!e) continue;
        if (e->ploc != ploc) continue;
        if (strcmp(e->entry, entry) != 0) continue;
        if (p0) *p0 = e->ptr0;
        if (p1) *p1 = e->ptr1;
        return 1;
    }
    return 0;
}

int WpfLinuxWin32_PtsJmpProbe(const char *entry, void *ploc, int *addr_ok,
                              int *a0, int *a1, int *a2, int *a3)
{
    if (addr_ok) *addr_ok = 0;
    if (a0) { *a0 = 0; }
    if (a1) { *a1 = 0; }
    if (a2) { *a2 = 0; }
    if (a3) { *a3 = 0; }
    if (!entry || !ploc) return 0;
    for (int i = 0; i < g_pts_jmp_n; i++) {
        const wpf_pts_jmp *e = wpf_pts_jmp_get(i);
        if (!e) continue;
        if (e->ploc != ploc) continue;
        if (strcmp(e->entry, entry) != 0) continue;
        if (addr_ok) *addr_ok = e->addr_ok;
        if (a0) { *a0 = e->a0; }
        if (a1) { *a1 = e->a1; }
        if (a2) { *a2 = e->a2; }
        if (a3) { *a3 = e->a3; }
        return 1;
    }
    return 0;
}

// ── 格 3 · 真实现 ①：`LoSetDoc`（托管声明 `LineServices.cs:1470`，**四参**）────────────
//   契约（原文见 `TextFormatterContext.cs:347-365` 的 `SetDoc`）：
//     `LsErr LoSetDoc(IntPtr ploc, int isDisplay, int isReferencePresentationEqual, ref LsDevRes deviceInfo)`
//   成功 ⇒ 返回 0（`LsErr.None`）**且**四个 `uint` ＋ 两个 `int` **真的落进该 ploc 的对象**（可独立读取）；
//   失败 ⇒ 返回 `-10000`，**对象一个字节都不改**（不留半途状态）。
//   ⚠️ 不改 `*dev`（出参在托管侧是**只读语义**的 `ref` 入参；本层只读不写）。
//   ⚠️ 不 deref `ploc`（身份校验在 `wpf_pts_loc_find` 里按指针身份完成）。
int LoSetDoc(void *ploc, int isDisplay, int isReferencePresentationEqual, const void *deviceInfo)
{
    wpf_pts_loc *c = wpf_pts_loc_find(ploc);
    if (!c) { g_pts_doc_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    // **逐字段按真实类型读**托管传进来的 `LsDevRes`（16 字节、四 `uint`、顺序布局）。
    // ⚠️ 读的是**调用方此刻的有效内存**（该结构在调用期间被托管侧 `GC.KeepAlive` 钉住）；
    //    若调用方**没给**结构地址（抽象调用方/RPC 伪造），则**不读**，四字段留 0 并如实记 `addr_ok=0`。
    unsigned int dxp = 0, dyp = 0, dxr = 0, dyr = 0;
    int addr_ok = 0;
    if (deviceInfo) {
        const unsigned int *v = (const unsigned int *)deviceInfo;
        dxp = v[0]; dyp = v[1]; dxr = v[2]; dyr = v[3];
        // 「这个地址真的落在某个**在册**上下文对象上吗」—— 一个**能否证伪**的性质：
        // 数据地址若不是本对象自己的 dev 字段，本字段就是 0（自检据此点名）。
        for (int i = 0; i < g_pts_loc_live_n; i++) {
            if ((const void *)&g_pts_loc_live[i]->dev_dxp_inch == deviceInfo) { addr_ok = 1; break; }
        }
    }
    c->doc_is_display   = isDisplay;
    c->doc_is_ref_equal = isReferencePresentationEqual;
    c->dev_dxp_inch = dxp; c->dev_dyp_inch = dyp;
    c->dev_dxr_inch = dxr; c->dev_dyr_inch = dyr;
    c->doc_sets++;
    g_pts_doc_sets++;
    wpf_pts_jmp_push("LoSetDoc", ploc, deviceInfo, addr_ok, 1,
                     isDisplay, isReferencePresentationEqual, (int)dxp, (int)dxr, NULL, NULL);
    int doc_idx = wpf_pts_index("LoSetDoc");
    if (doc_idx >= 0) g_pts_seen[doc_idx]++;    // 格3：真实现记"被问过"（`g_pts_calls` 不动 —— 它不是缺口）
    g_pts_seq++;
    return 0;                                        /* ← 改成别的值就是制造静默半通 */
}

// ── 格 3 · 真实现 ②：`LoSetBreaking`（托管声明 `LineServices.cs:1464`，**两参**）──────────
//   契约（原文见 `TextFormatterContext.cs:257-270` 的 `SetBreaking`）：
//     `LsErr LoSetBreaking(IntPtr ploc, int strategy)`
//   成功 ⇒ 返回 0 **且** `strategy` 真的落进该 ploc 的对象；失败 ⇒ `-10000`，对象不改。
int LoSetBreaking(void *ploc, int strategy)
{
    wpf_pts_loc *c = wpf_pts_loc_find(ploc);
    if (!c) { g_pts_break_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    c->break_strategy = strategy;
    c->break_sets++;
    g_pts_break_sets++;
    wpf_pts_jmp_push("LoSetBreaking", ploc, NULL, 0, 0, strategy, 0, 0, 0, NULL, NULL);
    int brk_idx = wpf_pts_index("LoSetBreaking");
    if (brk_idx >= 0) g_pts_seen[brk_idx]++;
    g_pts_seq++;
    return 0;                                        /* ← 改成别的值就是制造静默半通 */
}

// ── 格 4 · 真实现（`t97`／W8-2）：`LoAcquirePenaltyModule`（托管声明 `LineServices.cs:1569`，**两参**）──
//   契约：`LsErr LoAcquirePenaltyModule(IntPtr ploc, out IntPtr penaltyModuleHandle)`
//   调用链：`PtsCache.Linux.cs:532 → :533 → :548` ＋ `TextPenaltyModule.cs:23-32`；**托管侧唯一判错 ＝
//   `lserr != LsErr.None`，没有"出参是否真可用"的第二道断言** ⇒ **返回 0 而出参是垃圾/未绑定 ＝ 假装成功**
//   （症状从"报错"变成"下游拿到坏句柄、更晚更远才炸"）。本格按 `t80` 口径句的**四件套**落地：
//     ① **句柄身份校验**：只认 `LoCreateContext` 发过且仍在登记表里的 `ploc`；`NULL`／未知／伪造 ⇒
//        返回 `-10000` 且**一个字节都不读**（与 `LoDestroyContext` 的拒绝面同形）；
//     ② **出参真落盘且与 `ploc` 绑定**：`*penaltyModuleHandle = &该对象->penalty_module_handle`
//        （**不是**全局单例 ⇒ 第二个上下文不串味；自检对两个上下文各读各的来证）；
//     ③ **计数**：`g_pts_pen_sets`／`g_pts_pen_rejected`（＋按对象的 `penalty_acquisitions`）；
//     ④ **可独立读取**：观测镜（`wpf_pts_jmp_*`）记下"哪个 `ploc`、填了什么句柄、该句柄是否**真指向**
//        某个在册对象的该字段"（`addr_ok`）——镜只是**镜像**，权威始终是**对象本身**，自检逐字段对拍两者。
//   ⚠️ **非目标**（判据 §1.2 写死）：**不**实现罚分模块的内部算法（不断行代价、不建 internal handle）、
//      **不**顺带补 `LoGetPenaltyModuleInternalHandle`／`LoDisposePenaltyModule`、**不**改仪表。
//   ⚠️ 成功路径**绝不**返回非 0；失败路径**绝不**给出非空出参（自相矛盾的假对象＝本仓最忌讳的形态）。
int LoAcquirePenaltyModule(void *ploc, void **penaltyModuleHandle)
{
    if (penaltyModuleHandle) *penaltyModuleHandle = NULL;      // 任何失败路径都保持"空"
    if (!penaltyModuleHandle) { g_pts_pen_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    wpf_pts_loc *c = wpf_pts_loc_find(ploc);                   // 身份校验（未知 ⇒ 不 deref）
    if (!c)                   { g_pts_pen_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    c->penalty_module_handle = (void *)&c->penalty_module_handle;   // **绑在本对象上**的地址
    c->penalty_acquisitions++;
    g_pts_pen_sets++;
    {   /* `addr_ok` **现算**（与 `LoSetDoc` 同口径）：该地址**是否真等于某个在册对象的该字段**。
           它会恒为 1（我们就是取自己字段的地址）—— 但那**是算出来的**、不是写死的 1 ⇒ 若哪天实现
           改成返回一个全局/常量句柄，这一格会当场变 0（自检格 `82` 就是拿它当断言）。 */
        int a_ok = 0;
        for (int k = 0; k < g_pts_loc_live_n; k++) {
            if ((const void *)&g_pts_loc_live[k]->penalty_module_handle == (const void *)&c->penalty_module_handle) { a_ok = 1; break; }
        }
        wpf_pts_jmp_push("LoAcquirePenaltyModule", ploc, (const void *)&c->penalty_module_handle, a_ok, 0,
                         0, 0, 0, 0, c->penalty_module_handle, NULL);
    }
    { int _i = wpf_pts_index("LoAcquirePenaltyModule"); if (_i >= 0) g_pts_seen[_i]++; }  // 真实现也记"被问过"
    g_pts_seq++;
    *penaltyModuleHandle = c->penalty_module_handle;
    return 0;                                                  /* ← 改成别的值就是制造静默半通 */
}

// ── 格 4 · 只读探针（**机器可读**，形状照 `WpfLinuxWin32_PtsInstalledObjectsLive`）────────────
//   第 idx 个**在册**上下文对象上落盘的罚分模块句柄（**指针值本身**，不 deref）；越界/无 ⇒ 0。
//   ⚠️ 它是"该字段真在对象上"的**独立读取面**：与 `WpfLinuxWin32_PtsJmpProbe()` 记的镜像**逐字段对拍**。
// ⏪ **`t102`／P1-W28 · `F-6` 口径句（实现不动，只落纪律）**：本口是**位置读** —— 它返回
//   "**当前**登记表里第 `idx` 个在册对象"上的句柄。登记表是 **LIFO 紧凑表**（`LoDestroyContext()`
//   会把末尾项搬进空槽）⇒ **任何一次销毁都会换位**（现取实测：销毁 `c1` 之后 `HandleAt(0)` 变成
//   原来 `c2` 那个句柄）。**调用方纪律（逐字）**：**不得跨销毁缓存 `idx`** —— 每次要用时按**当前**
//   登记表重新计算（`g_pts_selfcheck_f4_binding()` 就是现成的正确用法：进来先记 `f4b = live_n`，
//   此后一律 `f4b`／`f4b+1`）。本件**不**把它改成"按句柄查"：那会把**位置语义**偷偷换成**身份语义**，
//   而调用方需要的正是"第 idx 个在册对象"这个位置语义。
void *WpfLinuxWin32_PtsPenaltyModuleHandleAt(int idx)
{
    if (idx < 0 || idx >= g_pts_loc_live_n) return NULL;
    return g_pts_loc_live[idx]->penalty_module_handle;
}

// 成功取得的次数（累计，含重复取得）。
int WpfLinuxWin32_PtsPenaltyModuleAcquisitions(void) { return g_pts_pen_sets; }

// ⏪ **`t97` 同趟补（W8-2 的**同族前置**，理由现场可核）**：`LoAcquirePenaltyModule` 由"恒失败"变成
//   **真成功**之后，托管侧的释放路径**第一次被走到** —— `TextPenaltyModule.Dispose()`／`Finalize()`
//   （`TextPenaltyModule.cs`）会调 `LoDisposePenaltyModule`；而该入口**修前未导出** ⇒
//   `EntryPointNotFoundException` 抛在 **`System.GC.RunFinalizers()`** 里 ⇒ **整进程 `rc=134`**
//   （现场：`app_g1.log:696`，k=24 腿 `alive=no／app_rc=134／magenta=0`）。这与 W8-1 的
//   `LoCreateContext`⇒`LoDestroyContext` 是**同一个形状**（"只做 acquire"会把"优雅降级"换成"清理期崩"）。
//   处置（**最小、诚实**）：把该入口导出成**诚实缺口 stub**（返 `-10000`、走台账），
//   **不**实现真正的释放语义（那属后续跳）；托管侧对 Dispose 的返回值**不检查**（无第二道断言）⇒
//   它在清理期**不被当作"成功"**，而"缺符号"这件事消失了。
//   ⚠️ 它**不是**把 `LoAcquirePenaltyModule` 的成功"圆回去"：acquire 仍然真成功、真落盘、真绑定；
//      这里补的是**它的生命周期对端**（否则该成功本身就会在 finalizer 里崩）。
int LoDisposePenaltyModule(void *penaltyModuleHandle)
{
    (void)penaltyModuleHandle;                 /* 不 deref、不 free：本层没有需要释放的真资源 */
    return wpf_pts_gap("LoDisposePenaltyModule");
}

// ── 格 5 · 真实现（`t103`／W8-3）：`LoGetPenaltyModuleInternalHandle`（托管声明 `LineServices.cs:1580`）──
//   契约：`LsErr LoGetPenaltyModuleInternalHandle(IntPtr penaltyModuleHandle, out IntPtr penaltyModuleInternalHandle)`
//   调用链（现取）：`PtsCache.Linux.cs:533` 的 `GetTextPenaltyModule()` → `:534` 的 `dangerousGetHandle()`
//   ＝ `TextPenaltyModule.DangerousGetHandle()`（`TextPenaltyModule.cs:83-84`：**非 `None` 即抛**）——
//   它是**功能路径**上掐住整条链的那一站（`LoDisposePenaltyModule` 只在清理期、且返回值被丢弃）。
//   ⚠️ **形状差异（本步要害）**：入参是**罚分模块句柄**，不是 `ploc`（与第二步的 `LoAcquirePenaltyModule(ploc,…)` 不同）。
//      本模块的模块句柄 ＝ **上下文对象上那个字段的地址** ⇒ 它的**指针值就是 `wpf_pts_loc *`**
//      （字段就在结构里 ⇒ **无需**任何偏移推算）⇒ 句柄身份校验＝**逐位比对"在册对象们的模块句柄"**，
//      **绝不 deref 未知指针**（伪造/野指针一律当场拒绝，进程不崩）。
//   四件套（照前两步同形，逐条有现取证据位）：
//     ① **句柄身份校验**：只认 `LoAcquirePenaltyModule` **自己发过且仍在册**的模块句柄；
//        `NULL`／未知／伪造 ⇒ 返回 `-10000` 且**一个字节都不读**；
//     ② **出参真落盘且与该模块绑定**：`*internalHandle = &c->penalty_internal_handle`
//        （**不是**全局单例 ⇒ 第二个模块不串味）；`internalHandle == NULL` ⇒ **拒绝**（不给"写空也算成功"）；
//     ③ **计数**：`g_pts_inth_sets`／`g_pts_inth_rejected`（＋按对象的 `penalty_internal_gets`）；
//     ④ **可独立读取**：观测镜记下"哪个模块句柄、落出了什么内部句柄、该内部句柄是否**真等于**
//        某个在册对象自己的那个字段"。**指针量一律走镜的 `ptr0`/`ptr1` 专用域**（`t97` 实测教训：
//        塞进 `int a0` 会被截断 ⇒ 对拍恒不等 ⇒ **假红**）。
//   ⚠️ **非目标**：不实现罚分模块内部算法；**不**升级 `LoDisposePenaltyModule`（本步契约：不必升级、不得回退）；
//      **不**把 `CreateDocContext` 的 stub 改成真实现（那是下一跳）。
int LoGetPenaltyModuleInternalHandle(void *penaltyModuleHandle, void **internalHandle)
{
    if (internalHandle) *internalHandle = NULL;                 // 任何失败路径都保持"空"
    if (!internalHandle) { g_pts_inth_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    /* ⏪ `t103` 自检实测教训（不是预判）：**`penaltyModuleHandle == NULL` 必须在查表之前显式拒绝**。
       只靠"扫在册对象、逐个比 `penalty_module_handle == 入参`"是**不够**的 —— 只要有一个在册对象的
       `penalty_module_handle` 恰好**也是** `NULL`（未被 `LoAcquirePenaltyModule` 取过的对象就是这种），
       那次"拿 `NULL` 当句柄"的调用就会**命中该对象并返回 0** ⇒ 拒绝面**静默半通**
       （实测：`LoGetPenaltyModuleInternalHandle(NULL,&q)` 返回 `0` 且把 `q` 写成内部句柄 ⇒ 格 5 当场红；
       该红只在"对象已存在"的历史腿上暴露，**另开进程的净腿反而修不出来** ⇒ 正是纪律第 `30` 条
       第二种误形"净腿绿 = 假绿"的又一实证）。 */
    if (!penaltyModuleHandle) { g_pts_inth_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    wpf_pts_loc *c = NULL;
    for (int i = 0; i < g_pts_loc_live_n; i++) {                // 按**指针身份**查（不 deref 入参）
        if (g_pts_loc_live[i]->magic != WPF_PTS_LOC_MAGIC) continue;
        if (g_pts_loc_live[i]->penalty_module_handle == penaltyModuleHandle) { c = g_pts_loc_live[i]; break; }
    }
    if (!c) { g_pts_inth_rejected++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    c->penalty_internal_handle = (void *)&c->penalty_internal_handle;
    c->penalty_internal_gets++;
    g_pts_inth_sets++;
    {   /* `addr_ok` **现算**（与前两格同口径）：该内部句柄**是否真等于某个在册对象的该字段**。 */
        int a_ok = 0;
        for (int k = 0; k < g_pts_loc_live_n; k++) {
            if ((const void *)&g_pts_loc_live[k]->penalty_internal_handle == (const void *)&c->penalty_internal_handle) { a_ok = 1; break; }
        }
        wpf_pts_jmp_push("LoGetPenaltyModuleInternalHandle", (void *)penaltyModuleHandle,
                         (const void *)&c->penalty_internal_handle, a_ok, 0, 0, 0, 0, 0,
                         c->penalty_internal_handle, (const void *)penaltyModuleHandle);
    }
    { int _i = wpf_pts_index("LoGetPenaltyModuleInternalHandle"); if (_i >= 0) g_pts_seen[_i]++; }
    g_pts_seq++;
    *internalHandle = c->penalty_internal_handle;
    return 0;                                                   /* ← 改成别的值就是制造静默半通 */
}

// ── 格 5 · 只读探针（机器可读、供自检与仓外探针独立读取）────────────────────────────────
//   第 idx 个在册对象上落盘的**内部句柄**（指针值本身，不 deref）；越界/无 ⇒ NULL。
//   ⚠️ 与 `…PtsPenaltyModuleHandleAt` 同族纪律（`F-6` 口径句同样适用）：**位置读**，**不得跨销毁缓存 `idx`**。
void *WpfLinuxWin32_PtsPenaltyInternalHandleAt(int idx)
{
    if (idx < 0 || idx >= g_pts_loc_live_n) return NULL;
    return g_pts_loc_live[idx]->penalty_internal_handle;
}
int WpfLinuxWin32_PtsPenaltyInternalGets(void) { return g_pts_inth_sets; }

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

// 第 idx 个"见过"的入口名写进 buf（nul 结尾）。
//   ⏪ **`t92`／P1-W20 · `F-3` 真修（纵深防御；本口是"裸口"，任何调用者都可能不经托管侧那层纪律）**：
//     修前原文 ＝ `snprintf(buf, (size_t)cap, "%s", k_pts_entries[i]); return 1;` —— **无长度检查**：
//     `snprintf` 截断时**仍然返回 1** ⇒ 调用方拿到**貌似完整的短名**（`cap=5 ⇒ 1/`"LoAc"`）。
//     这在判据面比 `unknown` **更坏**：`unknown` 是诚实的"没读到"，截断名是一个**看起来可归因的假名**
//     （若截断恰好落在名册里另一个真名上 ⇒ **假绿**）。
//   **返回语义（本口定死，可判、可核）**：
//     · 命中且**放得下**（`cap >= 名长 + 1`）      ⇒ 返回 **1**，`buf` ＝ 真名（nul 结尾）；
//     · **放不下**（`cap <= 名长`）**或** `cap <= 0` **或** `buf == NULL` ⇒ 返回 **0**，且
//       **当 `buf` 非空且 `cap > 0` 时**把 `buf` 写成**空串**（`buf[0] = '\0'`）—— **绝不留下截断名**；
//     · **无此 idx**（越界／没有该条目）⇒ 返回 **0**，同样写空串。
//   ⇒ **三种"没拿到"都归一到同一种可判形态（`0` ＋ 空串）**；调用者**凭返回值**即可判定，
//     就算**忽略返回值**也只会拿到空串（不会拿到看似完整的假名）。
//     ⚠️ 与 `t90` 在托管侧落的纪律（`GapEntryNameAt()` 用 `strlen(buf) < cap-1` 保守判截断）**相容**：
//        本口现在在放不下时根本不写名 ⇒ 那一层即使不变也**只会更保守**（多判 unknown、不会误信假名）。
int WpfLinuxWin32_PtsGapEntryName(int idx, char *buf, int cap)
{
    if (!buf || cap <= 0) return 0;
    int seen = 0;
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) {
        if (g_pts_calls[i] <= 0) continue;
        if (seen == idx) {
            int need = (int)strlen(k_pts_entries[i]) + 1;      // 名长 + nul
            if (cap < need) {                                  // **放不下** ⇒ 不返回截断名
                buf[0] = '\0';
                return 0;
            }
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
    // ⚠️【格 3 · 长度纪律】原先这里还印 `first=`／`last=`（缺口名册的首/末名）⇒ 加完格 3 的新字段后
    //   整行 **370 B**，而应用侧 `NativeReport()` 只有 `byte[256]` ⇒ 那一格**整条读不到**。
    //   现改印 `anchor=`（**在册表**上第一个有计数的入口名）—— 与 `calls=` 同一来源、信息不重复、短得多。
    char anchor[64] = "-";
    int seen = 0;
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) {
        if (g_pts_calls[i] <= 0) continue;
        if (seen == 0) snprintf(anchor, sizeof(anchor), "%s", k_pts_entries[i]);
        seen++;
    }
    char frontier[64] = "-"; wpf_pts_frontier(frontier, sizeof(frontier));
    // ⚠️【格 3 · **长度纪律**】本行**必须 ≤ 255 字节**：应用侧 `PtsCache.Linux.cs` 的 `NativeReport()`
    //   给的是 `byte[256]`，而 `WpfLinuxWin32_PtsGapReport()` 对"写不下"**如实返回 -1**（不截断、不静默）
    //   ⇒ 行一长，应用侧 `NativeError()` 就**整条读不到**（回落到 `A1_STUB_ERR`）。本趟实测：格 3 之前
    //   的字段长得下（329 B 已**超**），加完新字段后**必须压形** ⇒ 改成下面这个**紧凑形**（字段一个不少、
    //   `entry_calls` 仍逐条 12 个），实测长度见自检里的"≤255"断言。`g_pts_seen[]` 是前沿的口径。
    int n = snprintf(buf, (size_t)cap,
                     "PTS_GAP_REPORT mode=honest-fail entries=%d calls=%d anchor=%s err=%d frontier=%s "
                     "calls=0:%d 1:%d 2:%d 3:%d 4:%d 5:%d 6:%d 7:%d 8:%d 9:%d 10:%d 11:%d "
                     "io_live=%d loc_live=%d loc_creates=%d loc_destroys=%d loc_rej=%d "
                     "setdoc_sets=%d setdoc_rej=%d setbrk_sets=%d setbrk_rej=%d "
                     "inth_sets=%d inth_rej=%d",
                     seen, g_pts_seq, anchor, WPF_PTS_ERR_NOT_IMPLEMENTED,
                     frontier,
                     g_pts_calls[0], g_pts_calls[1], g_pts_calls[2], g_pts_calls[3], g_pts_calls[4],
                     g_pts_calls[5], g_pts_calls[6], g_pts_calls[7], g_pts_calls[8], g_pts_calls[9],
                     g_pts_calls[10], g_pts_calls[11],
                     g_pts_io_live_n,
                     g_pts_loc_live_n, g_pts_loc_creates, g_pts_loc_destroys, g_pts_loc_rejected,
                     g_pts_doc_sets, g_pts_doc_rejected, g_pts_break_sets, g_pts_break_rejected,
                     g_pts_inth_sets, g_pts_inth_rejected);
    if (n < 0 || n >= cap) {
        // ⏪ **`t92`／P1-W20 · `O-1` 返回语义（可判、可核）**：修前这一支只有一句
        //   `buf[cap - 1] = '\0'; return -1;` ⇒ **语义对、但"正确"靠的是一个没被写下来的不变式**
        //   （尾部多余字节恰好是 0）。本格把该不变式**写进代码并可被机器核**（三条）：
        //     ① **只有这一支**返回 `-1`（放得下 ⇒ 返回**正的长度**，由末尾 `return n;` 给）⇒
        //        "`-1` ＝ 没写出一条完整行"成了**唯一**的失败形态；
        //     ② `strnlen(buf, cap)` 被**钉在 `cap - 1`**（行首到 `cap-2` 是完整前缀，`cap-1` 是 nul）
        //        ⇒ 不会因未初始化字节而让长度飘到 `cap`；
        //     ③ `buf[cap-1]` **之后**（`cap` 起的尾部区域）**必须仍是调用前的 canary** ⇒ 本函数
        //        **一个字节都不越界写**（`g_pts_report_tail_is_clean()` 就是这条断言的机器可读面）。
        //   ⇒ **两类读者的读数（载体有成对读数）**：**按 rc 判**的读者看到 `-1` ＝ 明确"没拿到完整行"
        //     （`PtsCache.Linux.cs` 的 `NativeReport()` 正是这一类，它据此**放大缓冲重试**）；
        //     **忽略 rc** 的读者只会读到**该前缀 ＋ 一个空串收尾** —— 是**良构的截断**，
        //     不是"半截行里混着栈垃圾"（尾部字节区不是本行内容）。
        buf[cap - 1] = '\0';
        return -1;
    }
    return n;
}

// ⏪ **`t92`／P1-W20 · `O-1` 的机器可读检查口**（纯读，`<string.h>` 函数，不依赖 `<ctype.h>`）：
//   判"`buf[0 .. cap-1]` 这一行是否良构 ∧ `cap` 起的尾部区域是否仍是调用前的 canary"。
//   返回 **1** ＝ 良构（`strnlen(buf, cap) <= cap - 1` ∧ `buf` 区域不含 canary 字节）；
//          **0** ＝ 不良构（越界写了／该行区里出现了 canary 字节 ⇒ 行内容延伸到了尾部区）。
//   ⚠️ 本口**不**判"内容对不对"，只判 `O-1` 那条**缓冲区不变式**；调用者负责把 canary 填好。
//   ⚠️【`t92`】**故意 `static`（不进导出面）**：本件的硬约束是"导出面**不该因本件变动**（561）"
//      ⇒ 检查口只给**本文件内部**（自检）用；仓外探针要核这条不变式时，按**同一配方**自填 canary
//      并读返回形态即可（配方逐字入载体），不必多两个导出符号（那会把 561 变成 563）。
static int g_pts_report_tail_is_clean(const char *buf, int cap)
{
    if (!buf || cap <= 0) return 0;
    const unsigned char CANARY = 0xA5;
    size_t line_len = strnlen(buf, (size_t)cap);
    if (line_len > (size_t)(cap - 1)) return 0;                  // 行区长到 cap ⇒ 没被 nul 收尾
    for (size_t k = 0; k < line_len; k++) {
        if ((unsigned char)buf[k] == CANARY) return 0;           // 行区里出现 canary ⇒ 形状不对
    }
    // 尾部区（`cap` 起）由调用者按需检查：本口只知道"行区"的边界；尾部检查见下一个口。
    return 1;
}

// 尾部区（`buf[cap .. cap+tail-1]`）是否**一个字节都没被动**（仍是调用前的 canary）。
//   返回 1 ＝ 干净；0 ＝ 被写脏（＝ 发生了越界写）。同上：**static，不进导出面**。
static int g_pts_report_tail_untouched(const char *buf, int cap, int tail)
{
    if (!buf || cap <= 0 || tail <= 0) return 0;
    const unsigned char CANARY = 0xA5;
    for (int k = 0; k < tail; k++) {
        if ((unsigned char)buf[cap + k] != CANARY) return 0;
    }
    return 1;
}

// ── 格 3 · **负极性夹具**（自检的一部分；写成函数只为让"必红点"逐条可点名）──────────────
//   「两态可区分」在这里被拆成**两对方位**，每对只有**一个变量**在动：
//     ① `(entry="LoSetBreaking", ploc=loc_never)` —— `loc_never` **从没**被落过 ⇒ 镜**不命中**且出参清零；
//        再在同一句柄上真落一次 ⇒ 镜**命中**且字段相符（未设置／已设置两态）；
//     ② `dev` 指针 —— 指向**栈上同形结构**（不在任何在册对象里）⇒ 值照样真落盘，但 `addr_ok` 必须 **0**；
//        换成**在册对象自己的** `dev` 字段地址 ⇒ `addr_ok` 必须 **1**（"地址归因不恒真"的机械断言）。
//   ⚠️ 本函数**自己建/自己毁**（后建先毁 —— 登记表是 LIFO 紧凑表），并且**不**碰 `g_pts_*` 计数
//      （那些由调用方保存/复原）⇒ 它只动观测镜与它自己的对象。
static int wpf_pts_neg_polarity(void)
{
    void *loc_c = NULL, *loc_never = NULL;
    const int nb = g_pts_loc_live_n;      /* `t102`：本夹具**自己的** base（不假设表是空的） */
    const int npen = g_pts_pen_sets, npenrj = g_pts_pen_rejected;
    int ad = -1, b0 = -1, b1 = -1, b2 = -1, b3 = -1;
    unsigned int dev_c[4] = { 7u, 8u, 9u, 10u };
    unsigned int dev_stack[4] = { 21u, 22u, 23u, 24u };
    if (nb + 2 > WPF_PTS_LOC_MAX) return 1;      /* 表放不下两个 ⇒ 不适用（宁可不判，也不误红/漏条目） */
    if (LoCreateContext(NULL, NULL, &loc_c) != 0 || loc_c == NULL) return 68;
    if (LoSetDoc(loc_c, 1, 0, dev_c) != 0) { LoDestroyContext(loc_c); return 69; }
    if (LoCreateContext(NULL, NULL, &loc_never) != 0 || loc_never == NULL) { LoDestroyContext(loc_c); return 70; }
    /* ① 未设置一侧：镜必须不命中、出参必须被清零 */
    if (WpfLinuxWin32_PtsJmpProbe("LoSetBreaking", loc_never, &ad, &b0, &b1, &b2, &b3) != 0) {
        LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 65;
    }
    if (b0 != 0 || b1 != 0 || b2 != 0 || b3 != 0 || ad != 0) {
        LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 66;
    }
    /* ② 已设置一侧：同一句柄落一次 ⇒ 镜命中且字段相符 */
    if (LoSetBreaking(loc_never, 2) != 0) { LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 71; }
    if (WpfLinuxWin32_PtsJmpProbe("LoSetBreaking", loc_never, &ad, &b0, &b1, &b2, &b3) != 1 || b0 != 2) {
        LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 72;
    }
    /* ③ 地址归因的**诚实**一侧：栈上结构不在册 ⇒ 值落盘、`addr_ok` 必须为 0 */
    if (LoSetDoc(loc_never, 0, 0, dev_stack) != 0) { LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 73; }
    if (WpfLinuxWin32_PtsJmpProbe("LoSetDoc", loc_never, &ad, &b0, &b1, &b2, &b3) != 1) {
        LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 74;
    }
    if (b2 != 21) { LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 75; }
    if (ad != 0)  { LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 67; }
    /* ④ 地址归因的**正**一侧：在册对象自己的 dev 字段地址 ⇒ `addr_ok` 必须为 1 */
    if (LoSetDoc(loc_never, 1, 1, &((wpf_pts_loc *)loc_never)->dev_dxp_inch) != 0) {
        LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 76;
    }
    if (WpfLinuxWin32_PtsJmpProbe("LoSetDoc", loc_never, &ad, &b0, &b1, &b2, &b3) != 1 || ad != 1) {
        LoDestroyContext(loc_never); LoDestroyContext(loc_c); return 77;
    }
    if (LoDestroyContext(loc_never) != 0) { LoDestroyContext(loc_c); return 78; }
    if (LoDestroyContext(loc_c) != 0) return 79;
    if (g_pts_loc_live_n != nb) return 79;       /* `t102`：夹具自带**不带泄漏**断言（base 相对） */
    g_pts_pen_sets = npen; g_pts_pen_rejected = npenrj;   /* `t102`／`F-2`：夹具出口复原 pen 计数 */
    return 0;
}

// ── 格 5 夹具（`t103`／W8-3；**static，不进导出面**）────────────────────────────────────────
//   「两态可区分」的三个方位（每对只有一个变量在动）：
//     ① **成功**：某模块上取一次 ⇒ 出参**非空**且 `== &该对象->penalty_internal_handle`；
//     ② **按对象绑定**：两个模块各取各的 ⇒ 两个出参**各不相同**、且各等于**自己**对象的字段；
//     ③ **拒绝面**：`NULL` 模块／未知（伪造）模块／已销毁对象的旧模块句柄／`internalHandle==NULL`
//        ⇒ **一律 -10000 且出参被清空**（并且**不改任何可见状态**）。
//   ⚠️ 指针量一律走**指针域**（`ptr0`），**不**塞 `int` 域（`t97` 实测：截断 ⇒ 假红）。
static int g_pts_selfcheck_f5_binding(void)
{
    void *c1 = NULL, *c2 = NULL;
    void *m1 = (void *)0x71, *m2 = (void *)0x72;    /* 先投毒 */
    void *i1 = (void *)0x81, *i2 = (void *)0x82;    /* 先投毒 */
    const int nb = g_pts_loc_live_n;
    const int f5_is = g_pts_inth_sets, f5_ir = g_pts_inth_rejected;
    if (nb + 2 > WPF_PTS_LOC_MAX) return 1;
    if (LoCreateContext(NULL, NULL, &c1) != 0 || c1 == NULL) { return 0; }
    if (LoCreateContext(NULL, NULL, &c2) != 0 || c2 == NULL) { LoDestroyContext(c1); return 0; }
    /* 两个模块句柄通过真实现取得（**不**手工编造 ⇒ 保证身份校验路径与生产一致） */
    if (LoAcquirePenaltyModule(c1, &m1) != 0) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (LoAcquirePenaltyModule(c2, &m2) != 0) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (m1 == NULL || m2 == NULL || m1 == m2) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    /* ① 成功 + ② 按对象绑定 */
    if (LoGetPenaltyModuleInternalHandle(m1, &i1) != 0) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (LoGetPenaltyModuleInternalHandle(m2, &i2) != 0) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (i1 == NULL || i2 == NULL)              { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (i1 == (void *)0x81 || i2 == (void *)0x82) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }  /* 必须被改写 */
    if (i1 == i2)                              { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }  /* **不共享** */
    if (i1 != (void *)&((wpf_pts_loc *)c1)->penalty_internal_handle) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (i2 != (void *)&((wpf_pts_loc *)c2)->penalty_internal_handle) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    /* 独立读取面（按 idx 现算，**不得**写死 0/1 —— `F-6` 口径） */
    if (WpfLinuxWin32_PtsPenaltyInternalHandleAt(nb)     != i1) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (WpfLinuxWin32_PtsPenaltyInternalHandleAt(nb + 1) != i2) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    /* ④ 镜 vs 对象：指针走**指针域** */
    {
        const void *p0 = NULL, *p1 = NULL;
        if (WpfLinuxWin32_PtsJmpProbePtr("LoGetPenaltyModuleInternalHandle", m1, &p0, &p1) != 1) {
            LoDestroyContext(c2); LoDestroyContext(c1); return 0;
        }
        if (p0 != i1) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }   /* 镜记的内部句柄 == 对象上的 */
        if (p1 != m1) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }   /* 镜记的模块句柄 == 入参 */
    }
    /* ③ 拒绝面（失败且**不改可见状态**） */
    {
        void *snap = ((wpf_pts_loc *)c1)->penalty_internal_handle;
        int   nget = ((wpf_pts_loc *)c1)->penalty_internal_gets;
        void *q = (void *)0x5B5B;
        /* ⏪ `t103` 反腿实测教训（**必须留档**）：**这一条只在"登记表里有 `NULL` 罚分句柄的对象"时才咬人。**
           首次实现时本夹具**两对象都已 acquire 过**（`penalty_module_handle != NULL`）⇒ 拿 `NULL` 入参
           扫表扫不到任何对象 ⇒ 修前那个坏实现（缺 `!penaltyModuleHandle` 检查）**照样返回非 0**
           ⇒ **反腿不红、本格没有牙**（我自己的 P7 反腿就是这么抓出这条的：`badreal` 该给 `0/85` 却给了 `1/0`）。
           而运行期的真实命中路径恰恰是"**还没 acquire 的活对象**"（那正是历史腿上暴露的那次）。
           ⇒ 修法：**先造出**一个 `penalty_module_handle == NULL` 的活对象再调（`c3` 只建不 acquire）——
           这样"拿 `NULL` 当句柄"才有东西可误命中，该断言**在净腿上也有牙**。 */
        void *c3 = NULL;
        if (LoCreateContext(NULL, NULL, &c3) != 0 || c3 == NULL) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
        if (((wpf_pts_loc *)c3)->penalty_module_handle != NULL) {   /* 前提：它确实是"未 acquire"的活对象 */
            LoDestroyContext(c3); LoDestroyContext(c2); LoDestroyContext(c1); return 0;
        }
        if (LoGetPenaltyModuleInternalHandle(NULL, &q) != WPF_PTS_ERR_NOT_IMPLEMENTED || q != NULL) {
            LoDestroyContext(c3); LoDestroyContext(c2); LoDestroyContext(c1); return 0;
        }
        if (LoDestroyContext(c3) != 0) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
        q = (void *)0x5B5B;
        if (LoGetPenaltyModuleInternalHandle((void *)0xdeadbeef, &q) != WPF_PTS_ERR_NOT_IMPLEMENTED || q != NULL) {
            LoDestroyContext(c2); LoDestroyContext(c1); return 0;
        }
        if (LoGetPenaltyModuleInternalHandle(m1, NULL) != WPF_PTS_ERR_NOT_IMPLEMENTED) {
            LoDestroyContext(c2); LoDestroyContext(c1); return 0;
        }
        if (((wpf_pts_loc *)c1)->penalty_internal_handle != snap ||
            ((wpf_pts_loc *)c1)->penalty_internal_gets != nget) {
            LoDestroyContext(c2); LoDestroyContext(c1); return 0;    /* 被拒路径**不许**改状态 */
        }
    }
    /* ⑤ 销毁后：旧模块句柄**必被拒**（对象已不在册 ⇒ 身份校验查不到 ⇒ 且不 deref） */
    if (LoDestroyContext(c2) != 0) { LoDestroyContext(c1); return 0; }
    if (LoDestroyContext(c1) != 0) return 0;
    {
        void *q = (void *)0x5C5C;
        if (LoGetPenaltyModuleInternalHandle(m1, &q) != WPF_PTS_ERR_NOT_IMPLEMENTED || q != NULL) return 0;
    }
    if (g_pts_loc_live_n != nb) return 0;                                       /* 夹具不带泄漏 */
    g_pts_inth_sets = f5_is; g_pts_inth_rejected = f5_ir;                       /* 夹具出口复原本格计数 */
    return 1;
}

// ── `t92`／P1-W20 的两格夹具（**static，不进导出面**；由自检调用）──────────────────────────
//   ① `O-1` 缓冲区不变式：canary 填满 → 用放不下的 cap 调报告 → 三条断言。
#define WPF_PTS_O1_CANARY 0xA5
static int g_pts_selfcheck_o1_canary(void)
{
    enum { CAP = 251, TAIL = 32 };                 // `CAP` 取"必定放不下"的小值；TAIL 是越界写的探针区
    unsigned char b[CAP + TAIL];
    for (int k = 0; k < CAP + TAIL; k++) b[k] = WPF_PTS_O1_CANARY;
    int rc = WpfLinuxWin32_PtsGapReport((char *)b, CAP);
    if (rc != -1) return 0;                          // ① 写不下 ⇒ 必须只走 -1
    if ((int)strnlen((const char *)b, (size_t)CAP) != CAP - 1) return 0;   // ② 行区被精确收尾在 cap-1
    if (!g_pts_report_tail_is_clean((const char *)b, CAP)) return 0;       // ③ 行区良构
    if (!g_pts_report_tail_untouched((const char *)b, CAP, TAIL)) return 0; // ④ 尾部区一个字节都没动
    return 1;
}

//   ② `F-3` 边界：**现册最长名**（32 B＝`LoGetPenaltyModuleInternalHandle`）⇒ `cap = 名长` 必 "没拿到"。
//      取最长名而不是写死某个名：名册将来加更长的名，本格**自动跟着收紧**（不写死名字/长度）。
static int g_pts_selfcheck_f3_boundary(void)
{
    int longest = 0;
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) {
        int n = (int)strlen(k_pts_entries[i]);
        if (n > longest) longest = n;
    }
    if (longest <= 0) return 0;
    char small[64];
    if (longest + 1 > (int)sizeof(small)) return 0;
    /* 用**缺口名册**里最后一个有计数的入口（与 ②路同口径）；没有缺口 ⇒ 本格不适用（返回 1，不红） */
    int last = -1;
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) if (g_pts_calls[i] > 0) last = i;
    if (last < 0) return 1;
    for (int k = 0; k < (int)sizeof(small); k++) small[k] = (char)0x5A;
    /* 该入口在"缺口名册序"里的 idx */
    int want = -1, seen = 0;
    for (int i = 0; i < WPF_PTS_ENTRY_COUNT; i++) {
        if (g_pts_calls[i] <= 0) continue;
        if (i == last) { want = seen; break; }
        seen++;
    }
    if (want < 0) return 0;
    int nlen = (int)strlen(k_pts_entries[last]);
    /* `cap = nlen` ⇒ 差一个 nul 的位置 ⇒ 必须"没拿到"（rc 0 ＋ 空串），**绝不许**给截断名 */
    if (WpfLinuxWin32_PtsGapEntryName(want, small, nlen) != 0) return 0;
    if (small[0] != '\0') return 0;
    /* 反向（成对）：`cap = nlen + 1` 必须**拿到全名** */
    if (WpfLinuxWin32_PtsGapEntryName(want, small, nlen + 1) != 1) return 0;
    if (strcmp(small, k_pts_entries[last]) != 0) return 0;
    return 1;
}

// ── `t102`：报告行里**取一个整数域**（`key=<十进制>`；找不到 ⇒ -1）。**static**，不进导出面。
static int wpf_pts_report_field(const char *rep, const char *key)
{
    char pat[64];
    snprintf(pat, sizeof(pat), "%s=", key);
    const char *p = strstr(rep, pat);
    if (!p) return -1;
    p += strlen(pat);
    int v = 0, any = 0, neg = 0;
    if (*p == '-') { neg = 1; p++; }
    while (*p >= '0' && *p <= '9') { v = v * 10 + (*p - '0'); p++; any = 1; }
    return any ? (neg ? -v : v) : -1;
}

// ── 格 4 夹具（`t97`；**static，不进导出面** —— `t92` 实测过"多两个导出符号 ⇒ 561→563"）──────
//   两件套：① **按对象绑定**（两个上下文各指各的、且都等于"自己那个字段的地址"）；
//          ② **拒绝面**（`NULL`／未知/伪造句柄／空出参 ⇒ 失败且**不改任何可见状态**）。
//   ⚠️ 夹具自己建/自己毁（后建先毁，登记表是 LIFO 紧凑表）；`g_pts_*` 计数由调用方保存/复原。
static int g_pts_selfcheck_f4_binding(void)
{
    void *c1 = NULL, *c2 = NULL;
    void *h1 = (void *)0x91, *h2 = (void *)0x92;   /* 先投毒：实现若不写出参，断言必红 */
    /* ⚠️【本趟实测的第三个坑】本夹具**不假设登记表是空的**：它跑在 main 链之后，且自检可能被
          "带历史"调用（外面还开着别人的上下文）⇒ 一律用 `base = live_n` **相对化**取索引，
          绝不写死 0/1、也不用 `live_n - 2` 这种**对全局态敏感**的写法。 */
    const int f4b = g_pts_loc_live_n;
    const int f4_pen = g_pts_pen_sets, f4_penrj = g_pts_pen_rejected;   /* `t102`：夹具自带的复原基线 */
    if (f4b < 0 || f4b + 1 >= WPF_PTS_LOC_MAX) return 0;    /* 登记表放不下两个 ⇒ 不适用（宁可不判） */
    if (LoCreateContext(NULL, NULL, &c1) != 0 || c1 == NULL) return 0;
    if (LoCreateContext(NULL, NULL, &c2) != 0 || c2 == NULL) { LoDestroyContext(c1); return 0; }
    /* ① 成功路径：两个上下文各取得一次 */
    if (LoAcquirePenaltyModule(c1, &h1) != 0) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (LoAcquirePenaltyModule(c2, &h2) != 0) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    /* ② 出参**非空**且**各自等于自己对象的字段地址**（＝与该 `ploc` 绑定，不是全局单例） */
    if (h1 == NULL || h2 == NULL)              { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (h1 != (void *)&((wpf_pts_loc *)c1)->penalty_module_handle) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (h2 != (void *)&((wpf_pts_loc *)c2)->penalty_module_handle) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (h1 == h2)                              { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }  /* **不共享** */
    /* ③ 独立读取面（**按 idx 从登记表取**）与返回值一致。⚠️ 本自检**不是 fresh 函数**：
          它跑在 main 链**之后**，而 main 链已经建过上下文（`loc`／`loc_a`／`loc_b`）⇒ 登记表里
          **前面还有别人** ⇒ `idx` 必须**现算**（`live_n-2`／`live_n-1`），**不许写死 0/1**
          （写成 0/1 会被"前面那些"骗绿 —— 本趟实测的第二个坑，格号 `82`）。 */
    if (g_pts_loc_live_n != f4b + 2) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (WpfLinuxWin32_PtsPenaltyModuleHandleAt(f4b)     != h1) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    if (WpfLinuxWin32_PtsPenaltyModuleHandleAt(f4b + 1) != h2) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    {
        int ad = -1, a0 = 0, a1 = 0, a2 = 0, a3 = 0;
        if (WpfLinuxWin32_PtsJmpProbe("LoAcquirePenaltyModule", c1, &ad, &a0, &a1, &a2, &a3) != 1) {
            LoDestroyContext(c2); LoDestroyContext(c1); return 0;
        }
        if (ad != 1) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }      /* `addr_ok` 必须为 1 */
        {   /* ⚠️ 指针量必须走**指针口**（`int a0` 装 64 位地址会被截断 ⇒ 本趟实测的假红源头） */
            const void *pp0 = NULL, *pp1 = NULL;
            if (WpfLinuxWin32_PtsJmpProbePtr("LoAcquirePenaltyModule", c1, &pp0, &pp1) != 1) {
                LoDestroyContext(c2); LoDestroyContext(c1); return 0;
            }
            if (pp0 != h1) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
        }
    }
    /* 按对象计数**≥1**（main 链也可能已经在这个对象上取过一次 ⇒ **不许**写 `== 1`） */
    if (((wpf_pts_loc *)c1)->penalty_acquisitions < 1 ||
        ((wpf_pts_loc *)c2)->penalty_acquisitions < 1) { LoDestroyContext(c2); LoDestroyContext(c1); return 0; }
    /* ④ 拒绝面（失败且**不改可见状态**）：先取"快照"，逐条被拒后再比 —— 快照必须不变 */
    {
        void *snap1 = ((wpf_pts_loc *)c1)->penalty_module_handle;
        int   n1    = ((wpf_pts_loc *)c1)->penalty_acquisitions;
        void *q = (void *)0x5A5A5A5A;
        if (LoAcquirePenaltyModule(NULL, &q) != WPF_PTS_ERR_NOT_IMPLEMENTED || q != NULL) {
            LoDestroyContext(c2); LoDestroyContext(c1); return 0;
        }
        q = (void *)0x5A5A5A5A;
        if (LoAcquirePenaltyModule((void *)0xdeadbeef, &q) != WPF_PTS_ERR_NOT_IMPLEMENTED || q != NULL) {
            LoDestroyContext(c2); LoDestroyContext(c1); return 0;
        }
        if (LoAcquirePenaltyModule(c1, NULL) != WPF_PTS_ERR_NOT_IMPLEMENTED) {
            LoDestroyContext(c2); LoDestroyContext(c1); return 0;
        }
        if (((wpf_pts_loc *)c1)->penalty_module_handle != snap1 ||
            ((wpf_pts_loc *)c1)->penalty_acquisitions != n1) {
            LoDestroyContext(c2); LoDestroyContext(c1); return 0;                 /* 被拒路径**不许**改状态 */
        }
    }
    /* ⑤ 销毁后：这两个对象已不在册 ⇒ 对应 idx 越界 ⇒ `HandleAt` 必为 NULL（**不 deref 已释放对象**） */
    if (LoDestroyContext(c2) != 0) { LoDestroyContext(c1); return 0; }
    if (LoDestroyContext(c1) != 0) return 0;
    if (g_pts_loc_live_n != f4b) return 0;                          /* 回到**夹具进来时**的活数 */
    if (WpfLinuxWin32_PtsPenaltyModuleHandleAt(f4b + 1) != NULL) return 0;   /* 越界 ⇒ NULL */
    if (WpfLinuxWin32_PtsPenaltyModuleHandleAt(f4b)     != NULL) return 0;
    g_pts_pen_sets = f4_pen; g_pts_pen_rejected = f4_penrj;   /* `t102`／`F-2`：夹具出口复原 pen 计数 */
    return 1;
}

// 自检（**这就是防"后人顺手把 return 改成 0"的那道牙**）：
//   ① 格1 的两条**真实现**：`Create…` 必须返回 0 且出参非空/表长 2；`Destroy…` 必须返回 0；
//      重复释放与未知名释放**必须**被拒（返回非零）；摧毁后 `live` 必须回 0；
//   ② 格 2 的两条**真实现**：`LoCreateContext` 三参形必须**成功**（返回 0 ＋ `*ploc` 非空）；
//      `LoDestroyContext`：**自己的句柄 ⇒ 0**、**重复 ⇒ 被拒**、**未知 `0xdead` ⇒ 被拒且不崩**、
//      **NULL ⇒ 被拒**；全部走完 `ls_context_live` 必须回 0（无泄漏）；
//   ③ 其余 **4 条 stub** 逐个真调一次，返回值必须都 == -10000（非 0！），出参必须被清成 NULL/0；
//   ④ `WpfLinuxWin32_PtsGapReport` 必须写出一行，含 `err=-10000`、`frontier=LoSetDoc`
//      （**格 3 的前沿位移就在这一格**）、`installed_objects_live=0`、`ls_context_live=0`。
//   ⑤ **格 3**（`t81`）：`LoSetDoc`／`LoSetBreaking` 在**两个不同上下文**上各落一次**不同**值 ⇒
//      逐对象读回必须**各自等于自己那一份**（证明"与该 `ploc` 绑定"，不是全局单例）；
//      未知句柄／`NULL`／已销毁句柄 ⇒ **必被拒且不改任何可见状态**；观测镜（`wpf_pts_jmp_*`）
//      必须与**对象**逐字段一致（镜 ≠ 权威，但两者不一致 ⇒ 红）。
//   ⑥ **格 4**（`t97`／W8-2）：`LoAcquirePenaltyModule` 在**两个上下文**上各取得一次 ⇒ 出参必须
//      各自等于"**自己那个对象**的 `penalty_module_handle` 字段地址"（＝与 `ploc` 绑定、**不共享**），
//      且与对象字段／观测镜**逐字段一致**；`NULL`／未知句柄／空出参 ⇒ **必被拒且不改可见状态**。
//   调用本身会动台账 ⇒ 自检**保存/复原**计数，跑完台账与本进程"自检前"一致（可重复跑）。
//   ⏪ **`t102`／P1-W28 · `F-5` 口径句（实现不动，只落纪律）**：反腿判据（P1/P3/P4/P7）里期望的
//     `reason=decl-vs-live-mismatch`／`entry-name-not-backtraceable`／`cross-run-pairing`／
//     `symptom-column-not-derived` **在 `build/MilBridge/tools/**` 里命中 0**（只有
//     `ledger-nonzero-frontier-unchanged` 在册，来自 `pts-gap-count-check.sh` 的 FAKE-PROGRESS 腿）
//     ⇒ **那几条反腿只能人工判定**。**判据不得因为"看到某个 `reason=` token"而发绿，也不得因为
//     "没有这个 token"而判红**；承重点在**点名**（缺 `reason=`／缺 `file:`／缺字段名 ⇒ 该条判不成立）。
// ⚠️ 诊断面（给"诊断驱动"的开发阶段用，也留给后续 `t80` §5-NOINFO-4 那条"谁调它"的问题）：
//   把这个 `int` 追加到 `WpfLinuxWin32_PtsGapReport()` 的行尾 ⇒ 自检红的时候**看得见是哪一格**。
static int g_pts_selfcheck_rc = 0;
int WpfLinuxWin32_PtsGapSelfCheck(void)
{
    int save_calls[WPF_PTS_ENTRY_COUNT], save_seen[WPF_PTS_ENTRY_COUNT];
    int save_seq = g_pts_seq, save_printed = g_pts_printed;
    // 【格1 修订】自检现在会**真的**建/毁对象 ⇒ 三个 io 计数也要复原，否则"自检不许改变可观测状态"
    //   这句话对新面就成了假话（`creates`/`destroys`/`rejected` 会凭空涨）。`live` 不保存：
    //   它**必须**在自检结束时应为 0，那正是被断言的性质本身。
    int save_creates = g_pts_io_creates, save_destroys = g_pts_io_destroys, save_rejected = g_pts_io_rejected;
    // 【格2 修订】同理：LS 上下文那四个计数也要复原（`live` 不保存 —— 收尾必须回 0 是被断言的性质）。
    int save_loc_creates = g_pts_loc_creates, save_loc_destroys = g_pts_loc_destroys, save_loc_rejected = g_pts_loc_rejected;
    // 【格3 修订】`LoSetDoc`／`LoSetBreaking` 的四对计数与**观测镜**同样要复原：
    //   否则"自检不许改变可观测状态"对新面又成了假话（`setdoc_sets` 等会凭空涨、镜会被自检条目顶掉）。
    int save_doc_sets = g_pts_doc_sets, save_doc_rej = g_pts_doc_rejected;
    int save_brk_sets = g_pts_break_sets, save_brk_rej = g_pts_break_rejected;
    /* ⏪ **`t102`／P1-W28 · `F-2`（medium 真缺陷）**：`g_pts_pen_sets`／`g_pts_pen_rejected`（格 4 的
       成功/被拒计数）**原先没被保存/复原** ⇒ 每跑一次自检，**它自己新导出的**读口
       `WpfLinuxWin32_PtsPenaltyModuleAcquisitions()` 就 +3（现取 0→3→6→9）⇒ 该导出面**不是自检不变的**、
       跨自检取数即错 —— 与"自检不许改变可观测状态"直接冲突。本行把它一并 save/restore。 */
    /* ⚠️ 这两个保存量必须落在**自检本体动过任何计数之前**的**最早**处（本行已在最前）——
       否则"链上"自己涨的那部分会被写进 `save_*`，末尾复原**回不到真基线**（本趟实测抓到的
       第二形态：链上 `LoAcquirePenaltyModule(loc_a,…)` 涨 1、报告块看到的仍是 2）。 */
    int save_pen_sets = g_pts_pen_sets, save_pen_rej = g_pts_pen_rejected;
    int save_inth_sets = g_pts_inth_sets, save_inth_rej = g_pts_inth_rejected;   /* `t103`：格 5 同办 */
    wpf_pts_jmp save_jmp[WPF_PTS_JMP_MAX];
    int save_jmp_head = g_pts_jmp_head, save_jmp_n = g_pts_jmp_n;
    memcpy(save_jmp, g_pts_jmp, sizeof(save_jmp));
    memcpy(save_calls, g_pts_calls, sizeof(save_calls));
    memcpy(save_seen, g_pts_seen, sizeof(save_seen));

    int old_budget = g_pts_budget;
    g_pts_budget = 0;                       // 自检期间**不打**台账（runs quiet）

    /* ⏪ **`t102`／P1-W28 · `F-1`（medium 真缺陷）**：**本自检不是 fresh 函数** —— 调用方可能
       **已经有活上下文**（正是"带历史"腿）。修前主链那几处 `g_pts_loc_live_n` 断言用的是**绝对值**
       （`==1`／`==0`／`==2`）⇒ 带历史时**在链条中段就红** ⇒ **早退**到复原段之前的那一步已经
       建过上下文 ⇒ **每次调用漏下一个活条目**（实测 `loc_live 1→2→3→4`，而 `creates/destroys` 不动）
       ⇒ `WPF_PTS_LOC_MAX=8` 满之后 `LoCreateContext` 起会被拒 —— **这就是"下一趟更红"之源**。
       修法（两条同时）：① 本行记下 `base`，**所有自身断言一律 base 相对**（`base`／`base+1`／`base+2`）；
       ② 出口断言"登记表回到 base"（新增格 `83`，见报告块）—— 把"不带泄漏"这件事**变成可证伪的断言**。 */
    int base = g_pts_loc_live_n;

    char sb[64] = { 0 }, sp[64] = { 0 };
    void *p1 = NULL; int c1 = 0;   /* 格1：真实现 ⇒ 期望被填成 **非空** 且表长 2 */
    void *p2 = (void *)0x2;
    // 【`#66` W158A 修订】3 个新入口**各自一个先被投毒的出参**：否则链条走到这里时 `p1`
    //   早已被第 1 条入口清成 NULL ⇒ `p1 != NULL` 那三条断言**恒不成立**（恒绿假牙）。
    void *q1 = (void *)0x33, *q2 = (void *)0x34, *q3 = (void *)0x35;
    /* ⏪ `t103` 自检实测教训：**被拒断言必须用自己的出参变量**。原来"未知句柄 ⇒ 出参必被清空"那条
       与"真句柄 ⇒ 必须成功"那条**共用 `&q2`** ⇒ 前一条把 `q2` 清成 `NULL`，后一条就把 `NULL`
       当罚分模块句柄传下去 ⇒ 本步的真实现在第 15 格**当场红**（这就是本趟实测的 `diag=15`，
       不是实现坏、是**断言之间串了变量**）。`q4` 专供被拒面，**不碰** `q2`。 */
    void *q4 = (void *)0x36;
    (void)q1;   /* 保留投毒初值：`EntryName…` 面已不再用它，但"先投毒"的形制留着（W158A 口径） */
    // 【格2 修订】`LoCreateContext` 也是"先投毒再调"：修前它负责把出参清成 NULL，
    //   修后它负责**填真句柄** ⇒ 若不投毒，`loc != NULL` 那条断言会被上一轮的残留骗绿。
    void *loc = (void *)0x36;
    // 【格3 修订】两个**互不相同**的上下文，各自落**不同**的文档参数/断行策略 ⇒ 读回必须各是各的。
    void *loc_a = (void *)0x37, *loc_b = (void *)0x38;
    // 两个 `LsDevRes`：形状与托管侧**逐字同构**（4 × `uint`，顺序布局）。数值刻意不同，
    //   且**不等于**任何"常数兜底值"（若实现把参数丢掉、拿默认值填，下面 `==` 断言必红）。
    unsigned int dev_a[4] = { 1440u, 1440u, 1440u, 1440u };
    unsigned int dev_b[4] = { 1234u, 5678u, 9012u, 3456u };
    int rc = 0;
    int pr = 0, paddr = -1, pa0 = 0, pa1 = 0, pa2 = 0, pa3 = 0;

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
    else if (g_pts_loc_live_n != base + 1) rc = 25;                                     /* 创建后 live==base+1 */
    /* ── 格 2 两极化：真销毁 / 重复 / 未知 / NULL ─────────────────────────────── */
    else if (LoDestroyContext(loc) != 0) rc = 26;                                      /* ① 自己的句柄 ⇒ 0 */
    else if (g_pts_loc_live_n != base) rc = 27;                                         /* 销毁后 live==base */
    else if (LoDestroyContext(loc) == 0) rc = 28;                                      /* ② **重复必被拒** */
    else if (LoDestroyContext((void *)0xdeadbeef) == 0) rc = 29;                       /* ③ **未知必被拒（不 deref）** */
    else if (LoDestroyContext(NULL) == 0) rc = 30;                                     /* ④ **NULL 必被拒** */
    /* ── 格 3：`LoSetDoc`／`LoSetBreaking` **真落盘 ＋ 按对象绑定** ────────────── */
    else if (LoCreateContext(sb, sp, &loc_a) != 0 || loc_a == NULL) rc = 40;
    else if (LoCreateContext(sb, sp, &loc_b) != 0 || loc_b == NULL) rc = 41;
    else if (g_pts_loc_live_n != base + 2) rc = 42;                                   /* 两个活上下文（base 相对） */
    /* ① 成功路径：A 用 (1,1,dev_a)、B 用 (0,1,dev_b) —— 刻意**不同** */
    else if (LoSetDoc(loc_a, 1, 1, dev_a) != 0) rc = 43;                               /* 真实现 ⇒ 0 */
    else if (LoSetDoc(loc_b, 0, 1, dev_b) != 0) rc = 44;
    else if (LoSetBreaking(loc_a, 3) != 0) rc = 45;
    else if (LoSetBreaking(loc_b, 1) != 0) rc = 46;
    /* ② **按对象读回**：A 的四字段必须 == dev_a 那一份，B 必须是 dev_b 那一份
          （若实现把参数丢进**全局单例**，两条里必有一条红 —— 这就是"非全局单例"的机械断言） */
    else if (((wpf_pts_loc *)loc_a)->dev_dxp_inch != 1440u ||
             ((wpf_pts_loc *)loc_a)->dev_dyp_inch != 1440u ||
             ((wpf_pts_loc *)loc_a)->dev_dxr_inch != 1440u ||
             ((wpf_pts_loc *)loc_a)->dev_dyr_inch != 1440u) rc = 47;
    else if (((wpf_pts_loc *)loc_b)->dev_dxp_inch != 1234u ||
             ((wpf_pts_loc *)loc_b)->dev_dyp_inch != 5678u ||
             ((wpf_pts_loc *)loc_b)->dev_dxr_inch != 9012u ||
             ((wpf_pts_loc *)loc_b)->dev_dyr_inch != 3456u) rc = 48;
    else if (((wpf_pts_loc *)loc_a)->doc_is_display != 1 ||
             ((wpf_pts_loc *)loc_b)->doc_is_display != 0) rc = 49;                     /* `isDisplay` 真落盘 */
    else if (((wpf_pts_loc *)loc_a)->doc_is_ref_equal != 1 ||
             ((wpf_pts_loc *)loc_b)->doc_is_ref_equal != 1) rc = 50;
    else if (((wpf_pts_loc *)loc_a)->break_strategy != 3 ||
             ((wpf_pts_loc *)loc_b)->break_strategy != 1) rc = 51;                     /* `strategy` 真落盘 */
    else if (((wpf_pts_loc *)loc_a)->doc_sets != 1 || ((wpf_pts_loc *)loc_b)->doc_sets != 1) rc = 52;
    /* ③ 拒绝面（**失败且不改可见状态**）：未知句柄 / NULL / 已销毁句柄 */
    else if (LoSetDoc((void *)0xdeadbeef, 1, 1, dev_a) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 53;
    else if (LoSetDoc(NULL, 1, 1, dev_a) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 54;
    else if (LoSetBreaking((void *)0xdeadbeef, 3) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 55;
    else if (LoSetBreaking(NULL, 3) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 56;

    /* ④ **观测镜 vs 对象**：镜记下的必须与对象逐字段一致（镜 ≠ 权威，不一致 ⇒ 红）。
          未命中 ⇒ 出参被清 0 ⇒ 下面的断言必不成立（**恒绿假牙**被堵死）。 */
    if (rc == 0) {
        pr = WpfLinuxWin32_PtsJmpProbe("LoSetDoc", loc_b, &paddr, &pa0, &pa1, &pa2, &pa3);
        if (pr != 1) rc = 57;                                  /* 镜里应有 B 的 LoSetDoc 条目 */
        else if (pa0 != 0 || pa1 != 1) rc = 58;                 /* isDisplay=0 / isRefEqual=1 */
        else if (pa2 != 1234 || pa3 != 9012) rc = 59;           /* dev 首字段/第三字段 */
        else if ((int)((wpf_pts_loc *)loc_b)->dev_dxp_inch != pa2) rc = 60;
        else if ((int)((wpf_pts_loc *)loc_b)->dev_dxr_inch != pa3) rc = 61;
        else {
            pr = WpfLinuxWin32_PtsJmpProbe("LoSetBreaking", loc_a, &paddr, &pa0, &pa1, &pa2, &pa3);
            if (pr != 1) rc = 62;
            else if (pa0 != 3) rc = 63;                          /* strategy=3 */
            else if ((int)((wpf_pts_loc *)loc_a)->break_strategy != pa0) rc = 64;
            /* ⑤ 销毁后再调 = **必被拒**（句柄已失效，且不 deref）。⚠️ 登记表是 LIFO 紧凑表
                  ⇒ 必须**后建先毁**，否则 `loc_a` 会被顶出槽位 ⇒ 泄漏（"收尾 live 回 0"当场咬到）。 */
            else if (LoDestroyContext(loc_b) != 0) rc = 67;
            else if (LoSetBreaking(loc_b, 1) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 68;
            else if (LoSetDoc(loc_b, 1, 1, dev_b) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 69;
            /* 负极性（**两态可区分**的坏/好两侧）—— 形状是"**位置性单变量**"（照 `t80` P2 的
                 保存-复原/投毒出参形制）。⚠️ 先留一条**踩坑记录**：最初写成"镜里不该有 B 的
                 `LoSetBreaking` 条目" ⇒ **结构性恒假**（镜是**有界环形**，B 那条**成功**推送仍在环里
                 ⇒ 必命中）⇒ 报的是**断言**的错、不是实现的错（格号 `65` 连续两轮均由此而来）。
                 现形制见 `wpf_pts_neg_polarity()`：同一 `(entry, ploc)` 组合**只换 `ploc` 变量** ⇒
                 镜必须**不命中**且出参清零；再在同一句柄上真落一次 ⇒ 镜命中且字段相符。 */
            else if ((rc = wpf_pts_neg_polarity()) == 0) {          /* 65/66/67 等格号由它内部返回 */
                /* ⚠️ **顺序即语义**（本趟实测咬到）：`LoAcquirePenaltyModule` 也在**缺口名册**里
                   （`k_pts_entries[]` index 7）⇒ 它**一被调就**给台账留痕，且它在**调用序表**
                   （`k_pts_call_order`）里排在 `LoSetDoc` **之前**（`0,6,7,8,9,10,…`）
                   ⇒ 若把它留在链条**中段**，"前沿"会先是 `LoAcquirePenaltyModule`（本趟实测格号
                   `23` 的来源），`frontier=LoSetDoc` 那条断言就永远不成立。
                   修法：把这两条**挪到本链末尾**（与 `TextFormatterContext.Init()` 的真实顺序一致：
                   `LoCreateContext` → `LoSetDoc` → `LoSetBreaking`，penalty 面在那之后）。 */
                /* ⏪ `t97`／W8-2：`LoAcquirePenaltyModule` 已由**诚实缺口 stub** 变成**真实现**
                      ⇒ 本链里"它必须返 -10000 且清出参"那两条断言**必须跟着改**（不改就是自检恒红），
                      且**不是**把断言删掉：它改成**格 4 的成对断言**（见 `g_pts_selfcheck_f4_binding()`）。
                      四条 stub 断言（`CreateDocContext`／`DestroyDocContext`／`GetFloater*`／`GetTableObj*`）
                      与**仍属 stub 的** `LoGetPenaltyModuleInternalHandle` 一字未动。 */
                /* ⚠️ 本条**要有一次真调用**（本趟实测的坑）：只写"投毒值必须已被改写"是**恒假**的
                      —— 没有任何一次调用，`q2` 就**还是**毒值 `0x34` ⇒ 自检当场报 `diag=14`
                      （那不是实现坏、是**断言写成了恒假**）。正确形制＝**先真调用（成功）**→ 断言出参
                      **非空且 ≠ 毒值** → 再**未知句柄**调用 → 断言返 -10000 且出参**被清空**。 */
                if (LoAcquirePenaltyModule(loc_a, &q2) != 0) rc = 13;   /* 真实现 ⇒ **必须成功** */
                else if (q2 == NULL || q2 == (void *)0x34) rc = 14;     /* 出参：非空且 ≠ 毒值 */
                else if (LoAcquirePenaltyModule(loc_a, &q4) != 0) rc = 17;   /* 看家真落盘（先写 */
                else if (q4 == NULL) rc = 18;                            /*   非空，证明这口真会写） */
                else if (LoAcquirePenaltyModule((void *)0xdeadbeef, &q4) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 17;
                else if (q4 != NULL) rc = 18;                          /* 被拒 ⇒ 出参清空（**非**非空假句柄） */
                /* ⏪ `t103`／W8-3：`LoGetPenaltyModuleInternalHandle` 已由**诚实缺口 stub** 变成**真实现**
                      ⇒ 原来那两条"必须返 -10000 且出参清空"的断言**必须跟着改**（不改就是自检恒红），
                      且**不是**删掉：改成**格 5 的成对断言**（见 `g_pts_selfcheck_f5_binding()`）。
                      ⚠️ 入参是**罚分模块句柄**（`q2` 里那个真句柄），**不是** `loc_a` —— 这是本步的形状差异。 */
                else if (LoGetPenaltyModuleInternalHandle(q2, &q3) != 0) rc = 15;   /* 真实现 ⇒ **必须成功** */
                else if (q3 == NULL || q3 == (void *)0x35) rc = 16;                 /* 出参：非空且 ≠ 毒值 */
                else if (LoGetPenaltyModuleInternalHandle(q2, &q4) != 0) rc = 19;   /* 第二个模块句柄也能取 */
                else if (q4 == NULL) rc = 19;
                else if (LoGetPenaltyModuleInternalHandle((void *)0xdeadbeef, &q3) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 19;
                else if (q3 != NULL) rc = 21;                                       /* 被拒 ⇒ 出参清空 */
                /* ⚠️ `t103` 实测第 2 条：**拿 `NULL` 当罚分模块句柄**必须被拒（且出参清空）。
                      修前它**静默半通**（返回 0，命中"`penalty_module_handle` 也是 `NULL` 的在册对象"）
                      ⇒ 这条断言就是实现里那个 NULL 检查的**牙齿**，不写它就等于没修、也没牙。 */
                else if (LoGetPenaltyModuleInternalHandle(NULL, &q4) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 22;
                else if (q4 != NULL) rc = 23;
                else if (LoDestroyContext(loc_a) != 0) rc = 70;      /* 收尾：第二个也要真收掉 */
                else if (g_pts_loc_live_n != base) rc = 71;         /* 无泄漏（base 相对） */
                /* ⚠️【**顺序即语义** 之二 —— 本趟实测格号 `32` 的来源】负极性夹具**自己**会真调
                      `LoSetDoc`／`LoSetBreaking` ⇒ 它会涨 `g_pts_doc_sets`／`g_pts_break_sets`／
                      `g_pts_loc_creates` 等**可观测状态**；而本自检的纪律是"**自检不许改变可观测状态**"。
                      原先的复原在**下面**（报告那一格**之后**）⇒ 报告里当场看得见**涨了的数**
                      （实测 `setdoc_sets=5`／`setbrk_sets=3` 而非 0）⇒ `setdoc_sets=0` 那条断言必红。
                      修法：**夹具一跑完就地复原**这些计数（镜与对象由夹具自己管），
                      使"报告那一格"仍然看到**自检前**的值。 */
                g_pts_doc_sets = save_doc_sets; g_pts_doc_rejected = save_doc_rej;
                g_pts_break_sets = save_brk_sets; g_pts_break_rejected = save_brk_rej;
                /* ⏪ `t102`／P1-W28 · `F-2` 的**第二处**（本趟实测抓到的）：
                   负极性夹具**自己也会真调** `LoAcquirePenaltyModule` ⇒ 它涨的 `g_pts_pen_sets`
                   **原先不在"就地复原"清单里**（清单只有前面那几对）⇒ 报告块看到的仍是**涨过的数**
                   ⇒ 新格 `84` 当场红。⇒ 与其它计数**同源同办**：就地复原 `g_pts_pen_*`。 */
                g_pts_pen_sets = save_pen_sets; g_pts_pen_rejected = save_pen_rej;
                g_pts_inth_sets = save_inth_sets; g_pts_inth_rejected = save_inth_rej;
                g_pts_loc_creates = save_loc_creates; g_pts_loc_destroys = save_loc_destroys;
                g_pts_loc_rejected = save_loc_rejected;
                /* ⚠️ `g_pts_seen[]` **刻意不在这里复原**：它承载的正是"这两条真实现**真的被问过**"这条
                     被断言的性质（与 `io_live`／`loc_live` 同族：那些也**不**复原，因为"收尾回 0"本身
                      就是被断言的性质）⇒ 报告那一格看得见 `seen`，自检的断言就落在**它**上，
                      而不是落在"自检自己的调用序"那种**恒假**的东西上。 */
            }
        }
    }

    if (rc == 0) {
        char rep[512];
        if (WpfLinuxWin32_PtsGapReport(rep, (int)sizeof(rep)) <= 0) rc = 9;
        else if (!strstr(rep, "err=-10000")) rc = 10;
        /* ⚠️ **这里刻意不断言 `frontier=` 的具体名字**（本趟实测的教训）：自检自己会调
              `CreateInstalledObjectsInfo`（调用序表首位）与 4 条 stub ⇒ "调用序上第一个**被问过**的入口"
              在**自检内部**必然是它们之一，**不是** `LoSetDoc` ⇒ 拿 `frontier=` 当"格 3 到位了吗"的
              断言会**结构性恒假**（本趟实测格号 `23` 连续两轮就是这个错）。"前沿真的位移到 `LoSetDoc`"
              这条读数**只能**由**冷启腿**的 `app_g1.log`（应用侧真实调用序）给出 —— 见载体 C4/C5。 */
        /* 格3：两条**真实现**在"被问过"表里都有非零计数（＝它们**真的被调到**了，不是只导出）。
             两态可区分：把任一条改回 stub（或删掉它的 `g_pts_seen` 记录）⇒ 这里立刻为 0 ⇒ 红。 */
        else if (wpf_pts_index("LoSetDoc") < 0 || wpf_pts_index("LoSetBreaking") < 0) rc = 35;
        else if (!(g_pts_seen[wpf_pts_index("LoSetDoc")] > 0 &&
                   g_pts_seen[wpf_pts_index("LoSetBreaking")] > 0)) rc = 23;
        /* ⏪ `t102`／P1-W28：这三条原先是**字面 `=0` 匹配**（绝对口径）⇒ 带历史时**必红**（实测 `diag=31`）。
           现改成"**从报告行里解析出数、与 `base` 比**"：口径等价（都是"登记表回到进来时"），但**对本函数
           之外的状态不敏感** —— 这正是 `F-1` 那条"早退/泄漏"的**报告侧臂**。 */
        else if (wpf_pts_report_field(rep, "io_live") != 0) rc = 24;              /* 无泄漏（格1，绝对） */
        else if (wpf_pts_report_field(rep, "loc_live") != base) rc = 31;          /* 无泄漏（base 相对） */
        else if (wpf_pts_report_field(rep, "setdoc_sets") != save_doc_sets ||
                 wpf_pts_report_field(rep, "setbrk_sets") != save_brk_sets) rc = 32;   /* 计数已复原（与进来时比） */
        /* **长度纪律**（如实划界）：本行**放不下应用侧的 256 B**（`PtsCache.Linux.cs` 的 `NativeReport()`
           用 `byte[256]`）—— 本格之前 **329 B 就已超** ⇒ 应用侧那一路**本来**就取不到本行
           （`WpfLinuxWin32_PtsGapReport()` 写不下就**如实返回 -1**，不截断、不静默），而应用侧 `entry=`
           走的是**另一条**取数路（内层异常的入口名，见 `PtsCache.Linux.cs:988-1014`）⇒ 本行长度
           **不影响** `entry=` 面。这里把上界钉在 340 B（= 自检自己 `char rep[512]` 之内的**宽松界**），
           只用来防"后人顺手把报告撑爆"。**未**改应用侧任何件、**未**改仪表。 */
        else if ((int)strlen(rep) > 340) rc = 34;
        /* ── `t92`／P1-W20 新增两格（**格号从 80 起，沿用旧号一个都不动** —— 纪律第 `30` 条）────
             ① `O-1` 的**缓冲区不变式**（可被机器核）：先用 canary 把一块缓冲填满，再**故意**用
                放不下的 `cap` 调 `WpfLinuxWin32_PtsGapReport()`，然后断言三条 ——
                `rc == -1` ∧ `strnlen(buf, cap) == cap-1` ∧ `buf[cap]` 起的尾部区**仍是 canary**
                （＝**没有越界写**）。任一条不成立 ⇒ 红并点名格号。
             ② `F-3` 的**不返回截断名**：对一个**已知名长**建成一个 `cap = 名长` 的缓冲（差一个 nul
                的位置）⇒ 断言 `WpfLinuxWin32_PtsGapEntryName()` **返回 0** 且 `buf[0] == '\0'`。 */
        else if (!g_pts_selfcheck_o1_canary()) rc = 80;
        else if (!g_pts_selfcheck_f3_boundary()) rc = 81;
        /* ── `t97`／W8-2 新增一格（**格号 `82` 起；旧号一个不动、`80`/`81` 也不动** —— 纪律第 `30` 条）── */
        else if (!g_pts_selfcheck_f4_binding()) rc = 82;
        /* ── `t102`／P1-W28 新增两格（**格号从 `83` 起；旧号与 `80/81/82` 一个不动** —— 纪律第 `30` 条）──
             格 `83`（`F-1` 的出口断言）：**登记表必须回到自检进来时的 `base`** —— 即"本自检不带泄漏"。
               修前带历史路径每调一次 +1（`1→2→3→4`）⇒ 本格**当场红**（可证伪）。
             格 `84`（`F-2` 的出口断言）：**格 4 的成功计数在自检前后必须相等**（＝已被复原）。
               修前每调一次 +3 ⇒ 本格**当场红**（可证伪）。 */
        else if (g_pts_loc_live_n != base) rc = 83;
        else if (g_pts_pen_sets != save_pen_sets) rc = 84;
        /* ── `t103`／P1-W29 新增一格（**格号 `85` 起；旧号与 `80/81/82/83/84` 一个不动** —— 纪律第 `30` 条）──
             格 `85`（格 5 的成对断言）：**内部句柄与该模块绑定（非单例）＋ 拒绝面不改状态 ＋ 夹具不带泄漏**。
               修前该入口是 stub ⇒ 出参恒 `NULL` ⇒ 本格**当场红**（可证伪）；故它与 `C8` 的 1→0 是一对。 */
        else if (!g_pts_selfcheck_f5_binding()) rc = 85;
    }

    // 复原台账 + 观测镜（自检不许改变可观测状态）
    memcpy(g_pts_calls, save_calls, sizeof(save_calls));
    memcpy(g_pts_seen, save_seen, sizeof(save_seen));
    memcpy(g_pts_jmp, save_jmp, sizeof(save_jmp));
    g_pts_jmp_head = save_jmp_head; g_pts_jmp_n = save_jmp_n;
    g_pts_doc_sets = save_doc_sets; g_pts_doc_rejected = save_doc_rej;
    g_pts_break_sets = save_brk_sets; g_pts_break_rejected = save_brk_rej;
    g_pts_pen_sets = save_pen_sets; g_pts_pen_rejected = save_pen_rej;   /* `F-2`：格 4 计数一并复原 */
    g_pts_inth_sets = save_inth_sets; g_pts_inth_rejected = save_inth_rej;   /* `t103`：格 5 计数一并复原 */
    g_pts_io_creates = save_creates; g_pts_io_destroys = save_destroys; g_pts_io_rejected = save_rejected;
    g_pts_loc_creates = save_loc_creates; g_pts_loc_destroys = save_loc_destroys; g_pts_loc_rejected = save_loc_rejected;
    g_pts_seq = save_seq;
    g_pts_printed = save_printed;
    g_pts_budget = old_budget;
    g_pts_selfcheck_rc = rc;                 // 诊断格（自检红时看得见是哪一格；不改返回值语义）
    return rc == 0 ? 1 : 0;
}

// 诊断读数：上一次 `WpfLinuxWin32_PtsGapSelfCheck()` 的内部格号（0 = 全过；>0 = 该格必红）。
//   ⚠️ 它**不**参与判据（判据只看自检的 1/0）；存在的理由是"红的时候要能点名"（本仓纪律：不许红而不点名）。
int WpfLinuxWin32_PtsGapSelfCheckDiag(void) { return g_pts_selfcheck_rc; }

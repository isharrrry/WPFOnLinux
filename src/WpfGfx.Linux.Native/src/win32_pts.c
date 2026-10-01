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
#include <pthread.h>    /* ⏪ `T-A33`：`pthread_self()` —— 格式窗所在线程（跨线程拒驱判据） */
#include <stddef.h>          /* offsetof：格 6 夹具的**编译期**偏移假设自证 */
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
    "FsCreatePageBottomless",
    "FsQueryPageDetails",
    "FsDestroyPage",
    "FsQueryTrackDetails",
    "FsCreatePageFinite",
    "FsQueryTrackParaList",
    "FsQuerySubtrackDetails",
    "FsQuerySubtrackParaList",
    "FsClearUpdateInfoInPage",
    "FsUpdateBottomlessPage",
    "FsQueryTextDetails",
};
#define WPF_PTS_ENTRY_COUNT ((int)(sizeof(k_pts_entries) / sizeof(k_pts_entries[0])))

// ── 格 1（`TASK-0302` 首个真增量，`t12`）：installed-objects 表的**真对象**状态 ────────
//   契约：`Pts.cs:3077` `internal static extern int CreateInstalledObjectsInfo(ref FSIMETHODS,
//   ref FSIMETHODS, out IntPtr pInstalledObjects, out int cInstalledObjects)`。
//   本实现是**真的对象**：真实分配 / 真实表长 / 原样存下托管给的指针（**不 deref**）/
//   真摧毁 + 逐项计数。⚠️ 它**不**让页面渲染 —— 前沿只位移一跳（idx0 ⇒ idx6 `LoCreateContext`）。
#define WPF_PTS_IO_MAGIC   0x50545349u   /* "PTSI"：本模块自认的表头魔数 */
#define WPF_PTS_IO_MAX     8             /* 有界分配清单（防被异常调用无限增长） */
#ifndef WPF_PTS_FSP_PL_METHODS_SNAP
/* ⏪ `t167`（P1-W87）：`FSIMETHODS` **窗内值化**（D1/D2/D3）。缺省 **0** ⇒ 本块不进主链产物。 */
#define WPF_PTS_FSP_PL_METHODS_SNAP 0
#endif
#ifndef WPF_PTS_FSP_PL_M1
/* ⏪ `t173`（P1-W93）：**M1「诚实无进展」**＝只实现 `FsFormatSubtrackFinite` 的契约占位（`t169` §3 ③）。
   **只在副本**；缺省 **0** ⇒ 主链产物一个字节都不受影响。 */
#define WPF_PTS_FSP_PL_M1 0
#endif
#ifndef WPF_PTS_FSP_PL_LMWIT
/* ⏪ `t194`（P1-W107）：LM-1 第 4 条的**降级见证**（到达＋算术）。缺省 **0** ⇒ 主链零影响。 */
#define WPF_PTS_FSP_PL_LMWIT 0
#endif
#ifndef WPF_PTS_FSP_PL_LMWIT_NODVR
#define WPF_PTS_FSP_PL_LMWIT_NODVR 0    /* 反腿①：`dvrUsed=0` ⇒ 算术不成立 ⇒ **必红** */
#endif
#ifndef WPF_PTS_FSP_PL_LMWIT_NOARR
#define WPF_PTS_FSP_PL_LMWIT_NOARR 0    /* 反腿②：到达见证=0（不填列表）⇒ **必红** */
#endif
#ifndef WPF_PTS_FSP_PL_DVR
/* ⏪ `t198`（P1-W107 重修）：(甲) **描述符字段求真值** —— `FSPARADESCRIPTION.dvr_used(+36)`／
   `dvr_top_space(+60)` 的值**只**取自本侧段账（LM-1 段账 `g_pts_lm1_led[]`，由 M1 每次段账写入）
   ⇒ 通路＝**段账 → 描述符**（与"出参 → 托管"同源同操作数）。缺省 **0** ⇒ 主链产物零影响。 */
#define WPF_PTS_FSP_PL_DVR 0
#endif
#ifndef WPF_PTS_FSP_PL_DVR_NODVR
/* ⏪ `t198` 反腿（修正 `t195` `F-NODVR-WRONG-TARGET`）：把**描述符**（宿主 `PtsHelper.cs:177`
   真读的操作数）打成 0 ⇒ **描述符层**算术必红。旧反腿只打**出参**，射程不含 `:177`。缺省 **0**。 */
#define WPF_PTS_FSP_PL_DVR_NODVR 0
#endif
#ifndef WPF_PTS_FSP_PL_M2
/* ⏪ `t181`（P1-W98）：**M2＝LM-1 本侧段账**（排版模型几何/计数层）。只在副本；缺省 **0**。 */
#define WPF_PTS_FSP_PL_M2 0
#endif
#ifndef WPF_PTS_FSP_PL_METH_NULL
#define WPF_PTS_FSP_PL_METH_NULL 0      /* ⏪ `t168` 注入：把源指针当 NULL ⇒ 触发态 `NONE` ＋ 具名 gap 行 */
#endif
#ifndef WPF_PTS_FSP_PL_METH_ALLZERO
#define WPF_PTS_FSP_PL_METH_ALLZERO 0   /* ⏪ `t168` 注入：值化后把副本清 0 ⇒ 触发态 `ALLZERO` */
#endif
#define WPF_PTS_METHOD_WORDS 17
#define WPF_PTS_METHOD_SIZE  136          /* 17×8：**计算值**，下面用 `_Static_assert` 实测钉死 */
#define WPF_PTS_METHOD_STATE_NONE     0   /* 未值化 */
#define WPF_PTS_METHOD_STATE_ALLZERO  1   /* 值化了但 17 字全 0 */
#define WPF_PTS_METHOD_STATE_VALUE    2   /* 真值 */
_Static_assert(WPF_PTS_METHOD_WORDS * 8 == WPF_PTS_METHOD_SIZE, "17×8 != 136（计算值自洽）");

typedef struct {
    unsigned int magic;
    const void  *subtrack_methods;       /* 托管传进来的指针，**原样存** */
    const void  *subpage_methods;
    int          entries;                /* 表长（真值：两槽） */
#if WPF_PTS_FSP_PL_METHODS_SNAP
    /* ⏪ `t167`：**窗内值化**副本（照 `fscbk` 方子；`136 B` 由断言钉死）＋三态面 */
    unsigned char methods_snap[WPF_PTS_METHOD_SIZE];
    int           methods_snap_state;    /* NONE / ALLZERO / VALUE */
    int           methods_snap_nonzero;  /* 非 0 字数（0..17） */
    const void   *methods_addr;          /* 值化时的源地址（＝封送缓冲基址） */
    int           rb_calls;              /* 驱动点读回次数 */
    int           rb_same;               /* 逐字相同 ⇒ 1（－1 = 未做） */
    int           rb_first_diff;         /* 首个不同字的下标（－1 = 无） */
    int           rb_zero_index_win;     /* 窗内副本的零位下标（－1 = 无零位） */
    int           rb_zero_index_now;     /* 驱动点读回的零位下标 */
#endif
} wpf_pts_io_table;

static wpf_pts_io_table *g_pts_io_live[WPF_PTS_IO_MAX];
static int g_pts_io_live_n  = 0;         /* 活对象数（**泄漏检查的唯一真值**） */
static int g_pts_io_creates = 0;
static int g_pts_io_destroys= 0;
static int g_pts_io_rejected= 0;         /* 拒绝的摧毁请求（未知名/重复/清单满） */

#define WPF_PTS_DOC_MAGIC 0x50545344u   /* "PTSD"：本模块自认的 doc-context 魔数 */
#define WPF_PTS_DOC_MAX   8             /* 有界分配清单（防异常调用无限增长） */

/* ══════════════════════════════════════════════════════════════════════════════════════════════
   ⏪ `t141`（P1-W61）承重前置 `PRECOND-FSCBK-SNAPSHOT-IN-DOC` —— **窗口常量（全文件唯一定义处）**

   **为什么必须"值拷贝"而不能存指针**（判据件 `P1-drive-probe-criteria.md` §1.3 现取的三条）：
     ① 入参是**托管对象字段的地址**（`PtsCache.Linux.cs:548` 的 `ref _contextPool[index].ContextInfo`；
        `ContextInfo` 是 `ContextDesc` 的字段，同件 `:965`）⇒ CLR 只保证**封送期间**该地址有效，
        **返回后可能搬移** ⇒ 跨调用持有它就是 **use-after-return**；
     ② 现取本模块的 doc 对象（`wpf_pts_doc`）今天**没有**这张表 ⇒ 没有任何地方记着回调表；
     ③ `wpf_pts_fscbk_probe()`（`t133` 的测量仪器）把 103 个字读进**栈上局部**、打印后**不留存**。
   ⇒ 本件在 `CreateDocContext` 的**调用期内**把 `+40 .. +864`（103 个 8 B 字）**拷进 doc 对象**；
     **只读拷贝**、**零托管改动**、**一个回调都不调**（硬试伪 `nms` 只会换来不可捕获的 `FailFast`）。
   ⚠️ 常量值**不是本件算出来的**：`t133` 用三条独立仪器实测（载体 `P1-fscbk-offsets-report.md`）；
     本件只**引用**其值，并在下方用编译期断言把"窗口落在结构内"钉死。
   ⚠️ `WPF_PTS_FSCONTEXTINFO_SIZE` 是**托管侧实测值**（native 不能 `sizeof` 托管类型）⇒ 只能记常量，
     并用 `OFF + SIZE <= FSCONTEXTINFO_SIZE` 断言窗口**在界内**。
   ══════════════════════════════════════════════════════════════════════════════════════════════ */
#define WPF_PTS_FSCBK_OFF             40    /* 实测：`offsetof(FSCONTEXTINFO, fscbk)` */
#define WPF_PTS_FSCBK_SIZE            824   /* 实测：`sizeof(FSCBK)` ＝ 103 槽 × 8 B */
#define WPF_PTS_FSCONTEXTINFO_SIZE    872   /* 实测：`sizeof(FSCONTEXTINFO)`（托管值，见上注） */
#define WPF_PTS_FSCBK_SNAP_WORDS      (WPF_PTS_FSCBK_SIZE / 8)   /* 103 */

/* 快照**状态**（三态，判据 2／6(d) 要求「未快照」与「快照了但全 0」**不同形**）：
     0 `NONE`    ＝ 未快照（`calloc` 默认值；**成功路径不会停在这一态** —— 它只在"响亮拒绝"路径上出现，
                    而拒绝路径**不登记对象** ⇒ 外部看到的是"没有这个对象"）
     1 `ALLZERO` ＝ **已快照**，但 103 字**全 0**（合成/空表）—— 与上一态**判词不同**
     2 `VALUE`   ＝ **已快照**且**非全 0**（真实回调表） */
#define WPF_PTS_FSCBK_SNAP_NONE       0
#define WPF_PTS_FSCBK_SNAP_ALLZERO    1
#define WPF_PTS_FSCBK_SNAP_VALUE      2

/* ⏪ `t162`：`pfspara` 的**自有子轨对象**（定义在后面的 (a) 段；此处先给不完整类型的前向声明） */
typedef struct wpf_pts_subtrack_s wpf_pts_subtrack;
/* ⏪ `T-A12`：**子段枚举**的上界（有界，防异常调用无限枚举；`cParas` 源即此计数）。
   ⚠️ 这个界与**超界即拒绝**成对：枚举到界还没穷尽 ⇒ 记 `incomplete`（**不**给 cParas）。 */
#define WPF_PTS_SUB_CHILD_MAX 32

typedef struct {
    unsigned int magic;
    /* ① 收到的是**哪个**入参结构地址（原样存，**不 deref**）——"与本次调用绑定"的第一半证据 */
    const void  *info_addr;
    /* ② 从该结构**逐字段读回**的可判定量（读进对象 ⇒ 调用返回后仍可被独立读取）
       ③ 前两项即"偏移假设自证"：`version` 与 `fsffi` 由夹具用**互不相同**的已知值写下，
          读错偏移就**必然不等** ⇒ 该断言在净腿上也有牙（`t103` 格 85 的教训）。 */
    unsigned int version;               /* 读自 +0（夹具用 0x00010001；错偏移 ⇒ 不等） */
    unsigned int fsffi;                 /* 读自 +4（夹具用 0xDEADBEEF；错偏移 ⇒ 不等） */
    int          c_installed_objects;   /* 读自 +12 */
    const void  *p_installed_objects;   /* 读自 +16（**原样存，不 deref**） */
    const void  *p_fsclient;            /* 读自 +24（**原样存，不 deref**） */
    const void  *pts_penalty_module;    /* 读自 +32（**原样存，不 deref**） */
    /* ── ⏪ `t141`：回调表**快照**（值拷贝；判据 1／2／3）────────────────────────────────
       `fscbk_snap` 是 `FSCONTEXTINFO+40..+864` 那 103 个 8 B 字的**逐字副本** ⇒ 调用返回后
       仍可被独立读取（这正是"真拷贝而非存指针"的可证伪面：夹具把源缓冲区**改写**后再读回，
       若为指针则必变、为值拷贝则不变）。 */
    unsigned char fscbk_snap[WPF_PTS_FSCBK_SIZE];  /* 103 × 8 B（大小由断言钉死） */
    int           fscbk_snap_state;                /* `WPF_PTS_FSCBK_SNAP_{NONE,ALLZERO,VALUE}` */
    int           fscbk_snap_nonzero;              /* 快照里**非 0** 的 8 B 字数（0..103） */
    /* ⏪ `t151`：第一跳 `+80` 交出的 `nmSegment`（**live** 的 `ContainerParagraph` 句柄）——
       供**窗外腿**复用**同一个** `nms`（窗外/窗内只差窗口，不差句柄）。**原样存，不 deref**。 */
    const void  *drive_nmseg;
    /* ⏪ `T-A17`：**该缓存句柄的 liveness 位** —— 1 ＝仍可信；0 ＝**已释放/销毁语境** ⇒ 窗外腿**拒驱**。
       置 1：窗内**首次**取到 `drive_nmseg` 时（见 `wpf_pts_drive_probe` 的 `+80` 支）；
       置 0：`FsDestroyPage`（页销毁 ⇒ 该页的托管段落实例句柄**已先**被释放）。
       `calloc` ⇒ 初值 0（在取到句柄之前无窗口可驱，故 0 不产生假拒）。 */
    int          drive_handles_live;
    /* ⏪ `t156`：第二跳 `+136` 交出的**合法 `nmp`**（live `BaseParagraph` 族）—— 供**第三跳**的
       **窗外腿**复用**同一个**句柄（窗内/窗外只差窗口，不差句柄）。**原样存，不 deref**。 */
    const void  *drive_nmp;
    /* ── ⏪ `t160`（P1-W80）：段落列表要交出去的**段落客户端句柄**（`pfsparaclient`）的**代** ──
       来源铁律（判据 §5-P3）：**只能是本 run 内托管 `+176` 回调真返回的值**。
       `fsp_pl_cur` 是**当前代**（live），`fsp_pl_quota` 是它已服务的填充次数（到 `gen_size` 就换代）。
       `fsp_pl_prev` 是**上一代**（等**下一次**调用再回收 —— **绝不**"返回前回收"，判据 §2.3/P4）。
       `fsp_pl_src_in`／`fsp_pl_src_out` 是**探针**在**窗内**／**窗外**替本跳造出的第一代（两腿实验 W-1／W-2）。 */
    const void  *fsp_pl_src_in;     /* 窗内探针（`FsCreatePageBottomless`）造出并**保留**的第一代 */
    const void  *fsp_pl_src_out;    /* 窗外腿（`FsQueryTrackParaList` OOW）造出并**保留**的第一代 */
    int          fsp_pl_src_rc_in;  /* 上述 `+176` 的 fserr */
    int          fsp_pl_src_rc_out;
    const void  *fsp_pl_cur;        /* 当前代（live，正在被填进列表） */
    const void  *fsp_pl_prev;       /* 上一代（待**下次调用**回收） */
    int          fsp_pl_quota;      /* 当前代已服务的填充次数 */
    int          fsp_pl_gen;        /* 代数（1 = 探针造的第一代） */
    const char  *fsp_pl_site;       /* 当前代**在哪造的**：`probe-in`／`probe-out`／`query-frame` */
    const void  *fsp_pl_aba_stale;  /* ABA 反腿：被回收后又拿来填充的**陈旧值** */
    int          fsp_pl_aba_seen;   /* ABA 反腿：是否已制造过 ABA */
    /* ── ⏪ `T-A33`：**格式窗所在线程**（`FsCreatePage*` 内由 `wpf_pts_drive_probe` 记下）──────
       托管回调 `+176 CreateParaclient` 需 `PtsHost._ptsContext != null`；该上下文**只在格式线程**
       的窗口有效 ⇒ 从**别的线程**（实测：后台分页 `OnBackgroundPagination`）发调必撞
       `Invariant.FailFast`（**不可捕获**）⇒ 本侧以它作**跨线程**拒驱判据（承 `T-A17` 的 liveness
       守卫形制：**只在确认发调安全时**才发）。0 ＝尚未记录过窗口。 */
    unsigned long win_tid;
    unsigned long win_tid_calls;    /* 记录次数（诊断；只增） */
    /* ⏪ `T-A33`：**格式窗进行中**（`wpf_pts_drive_probe` 体内置 1／出口置 0）——
       托管 `+176 CreateParaclient` 只在窗内可安全发调（见 `wpf_pts_qtp_create_safe`）。 */
    int          in_win;
    /* ── ⏪ `t162`（P1-W82 · 下一跳对的 **(a)**）：`pfspara` 的**台账／持有期／销毁口径** ──
       🔴 **唯一合法来源＝托管产出的段落实例**（`+136 pfnGetFirstPara` 交出的 `nmp`，即
          `ContainerParagraph._firstChild`；`t151` 已现证 `+168 GetParaProperties` **接受**它）
          ⇒ 本侧**只认领、不创建**（判据 §4(a)／§7.3 零假值）。
       · 台账：`fsp_para_val`（值）＋ `fsp_para_src`（**哪一个产出行**）＋ 本 doc 身份
       · 持有期：**托管对象生存期**（承 `t158` §2.1）——本侧只持**引用**，跨调用有效
       · 销毁口径：**我们绝不回收**（它不是我们造的）；唯一回收触发者是托管 `Dispose()`（`+192` 之于
         `BaseParaClient`；段落对象本身的销毁由托管决定）⇒ 台账随 **doc 注销**整体失效 */
    const void  *fsp_para_val;      /* 已认领的 `pfspara` 值（本 run 产出） */
    const char  *fsp_para_src;      /* 来源行标记（如 `+136.nmp@FsCreatePageBottomless`） */
    int          fsp_para_claims;   /* 认领成功次数 */
    int          fsp_para_rejected; /* **认领失败**次数（⇒ 判红/作废） */
    int          fsp_para_acc_rc;   /* 下游接受（`+168 GetParaProperties`）的 rc */
    int          fsp_para_hold_ok;  /* 跨调用持有：后续调动仍被接受 ⇒ 1 */
    int          fsp_para_released; /* **我们**对 `pfspara` 的回收动作次数（恒 0＝不回收） */
    wpf_pts_subtrack *sub;          /* ⏪ `t162`：本 doc 自有的**子轨对象**（`pfspara` 即它的字段地址） */
    int          sub_created_seq;   /* 该对象的台账序号 */
    int          sub_reused;        /* 跨调用复用它（持有期）的次数 */
    /* ⏪ `T-A12`（本增量）：**子段枚举的现取结果**（`cParas` 的**源**）────────────────────────
       在**窗内**（`FsCreatePage*` ⇒ `wpf_pts_drive_probe`）用托管回调 `+136`／`+144` **真枚举**
       子轨段落实例 ⇒ `sub_cparas`＝计数、`sub_children[]`＝句柄序。**只有 `sub_enum_ok==1` 时**
       这些值才是"真枚举成功"的读数；否则一律 `sub_cparas=0` 且**不许**据它给 `cParas>0`。 */
    int          sub_enum_ok;       /* 1＝枚举穷尽成功（真调到回调并得到计数）；0＝未成/失败 */
    int          sub_cparas;        /* 枚举出的子段数（＝`cParas` 源；仅 `sub_enum_ok==1` 时有效） */
    const void  *sub_children[WPF_PTS_SUB_CHILD_MAX];  /* 枚举出的子段句柄序（原样存，不 deref） */
    int          sub_enum_rc136;    /* `+136`（首子段）的 fserr（-9999＝未调） */
    int          sub_enum_rc144;    /* `+144`（后继）的**末次** fserr（-9999＝未调） */
    const char  *sub_enum_v;        /* 判词 token（具名） */
    /* ── ⏪ `T-A25`（`NATIVE-QUERY-PHASE-CONTENT-MODEL`）：**窗内为每个子段建的本侧对象** ────────
       承 `T-A21` §5.3 设计（乙）＋（丙‑1）：`FsQuerySubtrackParaList` 的 `pfspara` 改交回**本侧
       自有对象**（不是托管段句柄）⇒ 托管随后回问 `FsQuerySubtrackDetails(child_obj)` 时
       `wpf_pts_sub_claim` **可认领**（今天是 `unclaimable-subtrack`）。每个对象在**窗内**递归
       枚举它自己的子段序（`wpf_pts_sub_enum_into`）⇒ 回问时 `cParas` 是**真枚举计数**。
       · `sub_child_objs[j]` 与 `sub_children[j]` **一一对应**（同一子段）；`NULL` ＝ 该子段的对象
         **未建成**（表满）⇒ 交回时**拒绝**（**绝不**退回托管句柄 ⇒ 那正是要消掉的 `unclaimable-*`）。
       · 持有期＝**托管对象生存期**（本侧对象的对偶）；销毁＝随 `dp->sub` 的树整体销毁。 */
    wpf_pts_subtrack *sub_child_objs[WPF_PTS_SUB_CHILD_MAX];
    int          sub_child_objs_n;      /* 已建子对象条数（本窗） */
    int          sub_child_objs_fail;   /* 建对象失败（表满）条数 —— 失败必留痕 */
    /* ⏪ `T-A9`（S2）：**每 doc 只驱一窗**的记账位 —— 缺省路径下 `FsCreatePage*` 可能对同一 doc
       被调多次 ⇒ 无常驻位就会反复驱（且把有限预算耗在同 doc 上）。置位时机＝**已提交驱这一窗**
       （在首条回调之前），与"该窗是否成功"无关 ⇒ 每 doc 至多驱一次、不同 doc 各驱一次。 */
    int          drive_done;
    /* ── ⏪ `T-A22`（`N1` 身份模型）：本 doc 的**枚举会话号**（＝来源证据台账里 `gen` 的来源）──────
       每次 `wpf_pts_sub_enum` 真枚举时 ++；**只增不复用**。认领「本 run 由 `+136`／`+144` 交回的
       段句柄」时要求证据的 `gen` **就是**本值 ⇒ 上一会话（上一窗）留下的同值句柄**不可认领**。 */
    int          prov_gen;
} wpf_pts_doc;
static wpf_pts_doc *g_pts_doc_live[WPF_PTS_DOC_MAX];
static int g_pts_doc_live_n       = 0;
static int g_pts_doc_sets_c       = 0;   /* CreateDocContext：成功次数 */
static int g_pts_doc_rejected_c   = 0;   /* CreateDocContext：被拒次数（NULL 入参/空出参） */
static int g_pts_doc_destroys     = 0;   /* DestroyDocContext：成功销毁次数（**收尾面新可达性的机器读数**） */
static int g_pts_doc_destroy_rej  = 0;   /* DestroyDocContext：被拒次数 */

/* ⏪ `t141`：`PRECOND-FSCBK-SNAPSHOT-IN-DOC` 的**成败面**（判据 2：不许静默 stub／假成功）
     · `g_pts_fscbk_snap_taken` 快照**成功**次数（值拷贝真的发生了）
     · `g_pts_fscbk_snap_gap`   快照**未发生**次数（每一条都有**具名**行 ⇒ 不许静默）
     · `g_pts_fscbk_snap_allzero` 已快照但**全 0** 的次数（＝"表装了但空"这一态，**与"未快照"不同形**） */
static int g_pts_fscbk_snap_taken   = 0;
static int g_pts_fscbk_snap_gap     = 0;
static int g_pts_fscbk_snap_allzero = 0;

/* ⏪ `t141`：**编译期钉死**快照窗口（判据 5；与 `t133` 那 13 条同族，**不重复定义**任何常量） */
_Static_assert(sizeof(((wpf_pts_doc *)0)->fscbk_snap) == WPF_PTS_FSCBK_SIZE,
               "doc 快照区大小 != sizeof(FSCBK)（824）");
_Static_assert(WPF_PTS_FSCBK_SNAP_WORDS == 103, "快照字数 != 103");
_Static_assert(WPF_PTS_FSCBK_OFF == 40,  "快照窗口起点 != +40（实测值）");
_Static_assert(WPF_PTS_FSCBK_SIZE == 824, "快照窗口长度 != 824（=103×8）");
_Static_assert(WPF_PTS_FSCBK_OFF % 8 == 0, "快照窗口起点未 8 字节对齐");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_FSCBK_SIZE <= WPF_PTS_FSCONTEXTINFO_SIZE,
               "快照窗口越出 FSCONTEXTINFO（40+824=864 必须 <= 872）");

static void wpf_pts_jmp_push(const char *entry, const void *ploc, const void *dev, int addr_ok,
                             int is_doc, int a0, int a1, int a2, int a3,
                             const void *ptr0, const void *ptr1);

/* ⏪ `t125`：上下文身份校验（**只按指针身份**在 `g_pts_doc_live[]` 里查；查不到返回 0，
   **一个字节都不读**）—— 与 `LoDestroyContext`／`DestroyDocContext` 同纪律，供
   `FsQueryPageDetails`／`FsDestroyPage` 复用。定义体放在 `g_pts_doc_live[]` 可见之后
   （本处先给声明）。 */
static int wpf_pts_doc_find(const void *ctx);
/* ⏪ `t146`：同上，但**返回对象指针**（驱动探针要用快照；查不到返回 NULL）。 */
static wpf_pts_doc *wpf_pts_doc_ptr(const void *ctx);
static int wpf_pts_ctx_is_live(const wpf_pts_doc *d);   /* ⏪ t156：该 doc 是否仍在册（未被 DestroyDocContext 移除） */
/* ⏪ `t146`：驱动探针本体（定义在 `格 6` 之前）；`FsCreatePage*` 两处**调用窗**在本文件里**更早** ⇒ 先给声明（内部助手一律 `static`）。 */
static void wpf_pts_drive_probe(wpf_pts_doc *d, const void *sect, const char *where);
/* ⏪ `T-A37`：内容排版驱动的运行期闸（定义见 `wpf_pts_qtp_create_safe` 之后）。 */
static int wpf_pts_att_content_gate(void);
/* ⏪ `T-A52`／`T-A54`：Floater 内容排版驱动的运行期闸（`T-A54` 起**缺省开**；定义在 `wpf_pts_att_content_gate` 之后）。 */
static int wpf_pts_floater_cbk_gate(void);
/* ⏪ `T-A53`：Table 族驱动闸 ＋ **窗内**表模型建点（定义在 `wpf_pts_floater_cbk_gate` 之后）。 */
static int wpf_pts_tableobj_gate(void);
struct wpf_pts_subpage_s;
static void wpf_pts_tableobj_drive(wpf_pts_doc *d, struct wpf_pts_subpage_s *s, const char *where);
/* ⏪ `t127`：字段级诚实性的判据助手（定义在页表可见之后）——本处先给声明。 */
static int wpf_pts_track_owned(const void *track);

/* ⏪ `t123`：台账面（`g_pts_seen[]`／`wpf_pts_index()`）在本文件里**声明得比本格晚** ⇒
   本格需要它们（真实现按既有惯例只记"被问过"、不记缺口）⇒ 此处补**外前向声明**（定义在下方）。 */
static int g_pts_seen[];
static int g_pts_seq;
static int wpf_pts_index(const char *entry);

// ── 格 7（`t123`／P1-W46 · W8 第五步）：`FsCreatePageBottomless` 真实现（**Fs 族第一跳**）──────
//   上游声明（`Pts.cs:3127-3132`，**裸名**；模块名经 `Pts.cs:25` 别名 → `RefAssemblyAttrs.cs:69`
//   → `PresentationNative_cor3.dll` → `build/shims/Win32ShimResolver.cs:60/:92` → **`libwpfwin32.so`**
//   ⇒ 与 PTS/LS 那几步**同一个域**）：
//     int FsCreatePageBottomless(IntPtr pfscontext, IntPtr fsnmsect, out FSFMTRBL pfsfmtrbl, out IntPtr ppfspage);
//   ⚠️ `FSFMTRBL` 是 **`int` 枚举**（4 字节出参）⇒ native 侧是 `int *`；`ppfspage` 是 `void **`。
//   🔴 **本格的两种失败形态（判据 §2.2 的关键发现；决定本实现必须有"留痕"）**：
//     (a) **符号不存在**（本步之前）⇒ CLR 在封送阶段抛 `EntryPointNotFoundException` ⇒ 托管侧
//         `if (fserr != fserrNone)` **根本不执行** ⇒ 应用钩子记 1152 行；
//     (b) **符号在而返非 0**（本步之后）⇒ `_ptsPage = IntPtr.Zero; PTS.ValidateAndTrace(fserr, …)`，
//         而 `ErrorTrace`（`Pts.cs:83-128`）在"内层只有我方 PTS 异常／为 null"时**不抛**，且
//         **只在 `TracePageFormatting.IsEnabled` 时**才记一行（上游注释逐字：
//         "We shouldn't throw in this case but should log the error if debug tracing is enabled"）。
//   ⇒ **若把本格做成"静默 stub（恒返 -10000）"，ENFE 会归零（`N2` 变绿）而排版并未发生、且很可能
//     一行痕迹都没有** —— 这正是判据 C4／P4 要堵的**假绿通路**。
//   ⇒ **留痕做在 native 侧**（**不改上游 `ValidateAndTrace` 的语义** —— 那是上游语义、且越域）：
//     每次**返非 0**都打一行具名诊断到 `stderr`，并把计数暴露成只读口：
//       `[FS_PAGE_GAP] rc=<err> reason=<token> ctx=<p> sect=<p> ok=<n> gap=<n>`
//     ⇒ 于是"诚实 stub 的静默"在本模块**可机读地不成立**（P4 的反腿据此必红）。
#define WPF_PTS_FSP_MAGIC 0x50545350u   /* "PTSP"：本模块自认的 page 对象魔数 */
#define WPF_PTS_FSP_MAX   4096          /* 有界分配清单：**布局引擎会反复调**（现取一趟 1151 次）
                                        ⇒ 上限必须远大于一趟的调用次数；每个对象 32 B ⇒ 满表约 128 KiB */
#define WPF_PTS_FSFMTRBL_NOT_ACHIEVED 3 /* 不在上游枚举里的"未达成"值（失败面**不放残留/毒值**） */
typedef struct {
    unsigned int magic;
    const void  *ctx;                   /* 本次调用的上下文句柄（**原样存，不 deref**） */
    const void  *sect;                  /* 本次调用的 fsnmsect（**原样存，不 deref**） */
    int          result;                /* 写回出参的 `FSFMTRBL` 值（**本次调用的结果**，非全局常量） */
    /* ── `t125`：`FsQueryPageDetails` 要回读的页几何（本模块**自持**的那一份）──────────────
       `PtsPage.GetRect()`／`GetBoundingBox()` 在 `fSimple` 为真时读 `u.simple.trackdescr.fsrc`／
       `.fsbbox`；两者都只在 `fDefined` 为真时被采纳 ⇒ 本模块给的 bbox **必须** `fDefined=1`。 */
    int          pg_w, pg_h;            /* 页矩形（创建时按当时几何记下） */
    int          bbox_defined;          /* 1 = 本模块声明的 bbox 有效 */
    /* ── `t127`：**track 句柄 ＋ 段数**（裁定二十七批准的两步之一）──────────────────────
       托管侧 `FlowDocumentPage.cs:440` 拿 `pageDetails.u.simple.trackdescr.pfstrack` 去问
       `FsQueryTrackDetails`；而 `t125` 那手只填了 `fSimple` 等字段、**没填 `pfstrack`**
       ⇒ 交出去是 **NULL** ⇒ 1101 次调用全被"喂了 NULL"（**真缺陷**，见载体 §缺陷登记）。
       修法同 `penalty_module_handle` 型：**句柄 ＝ 本对象内某字段的地址** ⇒
       **身份即可直接指针比较**（不是全局常量、不是伪值、无需偏移推算）。 */
    int          c_paras;               /* 这条 track 的段数（按**对象**给，非全局常量） */
    /* ── `T-A15`：`FsQueryPageDetails` 的 `FSPAGEDETAILS.fskupd` 语义（逐字照
       `build/MilBridge/P1-tail2-aoore-recon.md` §4.1：**首次 `fskupdNew`／稳态 `fskupdNoChange`**，
       **永不再写** `fskupdInherited`）────────────────────────────────────────────
       上游契约（`Pts.cs:1693-1696`）：`fskupd` 只可能是 `fskupdNew`／`fskupdChangeInside`／
       `fskupdNoChange`；`PtsPage.cs:999` 用 `== fskupdNoChange` 提前返回、`:1029` 用 `== fskupdNew`
       建轨视觉 ⇒ 旧写法（恒 `0`＝`fskupdInherited`）两处都判否 ⇒ 空 `VisualCollection` 取 `[0]`
       ⇒ `ArgumentOutOfRangeException`（`A14` 现取 561）。
       · `qpd_calls`       ＝ 该页对象被**成功**查询的次数（即 `[QPD]` 的 `page_qpd`）。
       · `qpd_new_pending` ＝ 上一次成功查询给了 **`fskupdNew(2)`** 且下游见证尚未到达。
       · `qpd_vis_built`   ＝ 已见"消费者据 `New` 真建起轨视觉"的**下游见证**（见 `FsQueryTrackParaList`
                              的判别器）⇒ 此后按**稳态**给 `fskupdNoChange(1)`。
       · `qpd_fstd_since`  ＝ 上一次成功查询以来，`FsQueryTrackDetails` 被调用过几次（判别器的第二格）。
       ⚠️ **本模块不声称拥有"该页本轮是否变化"的真值** ⇒ 具名 `NOINFO-FSPAGEDETAILS-PAGE-CHANGE-TRACKING`；
          "首次"只按**"查询组的首次查询"**划界，"稳态"只按**"该页的轨视觉已被建起"**这一可现取的见证划界
          （**不**自造位移源）。 */
    int          qpd_calls;
    int          qpd_new_pending;
    int          qpd_vis_built;
    int          qpd_fstd_since;
} wpf_pts_fsp;
static wpf_pts_fsp *g_pts_fsp_live[WPF_PTS_FSP_MAX];
static int g_pts_fsp_live_n     = 0;
static int g_pts_fsp_ok         = 0;   /* 成功次数（C4 的"成功面"） */
static int g_pts_fsp_gap        = 0;   /* **返非 0 次数**（C4 的"失败面"：诚实 stub 会让它 ≥1） */
static int g_pts_fsp_rej        = 0;   /* 被拒次数（形状/身份校验失败；含在 gap 里） */
static const char *g_pts_fsp_last_reason = "none";   /* 最后一次失败的原因 token（可独立读取） */
static int g_pts_fsp_qpd_ok   = 0;      /* `t125` `FsQueryPageDetails`：成功次数 */
static int g_pts_fsp_qpd_gap  = 0;      /* `t125`：返非 0 次数（失败面） */
static int g_pts_fsp_des_ok   = 0;      /* `t125` `FsDestroyPage`：真销毁次数 */
static int g_pts_fsp_des_gap  = 0;      /* `t125`：返非 0 次数（失败面） */
/* ⏪ `T-A33`：`FsDestroyPage` **摘表但不 `free`** 的累计数（页对象内存一次性让渡 ⇒ 句柄地址
   **永不复用**；防"断页记录句柄撞车"的托管不可捕 `FailFast`）。只增，诊断用。 */
static int g_pts_fsp_retired_n = 0;
/* ⏪ `t127`／裁定二十七：`FsQueryTrackDetails`／`FsCreatePageFinite` 的成败面。 */
static int g_pts_fsp_trk_ok   = 0;
static int g_pts_fsp_trk_gap  = 0;
static int g_pts_fsp_fin_ok   = 0;
static int g_pts_fsp_fin_gap  = 0;
static int g_pts_fsp_pl_ok   = 0;      /* `t129` `FsQueryTrackParaList`：成功次数（**本步恒 0**） */
static int g_pts_fsp_pl_gap  = 0;      /* `t129`：返非 0 次数（**本步＝全部**） */
/* ⏪ `T-A15`：`FsQueryPageDetails.fskupd` 的语义面（`[QPD]`／`[VIS]` 的计数只读口）。 */
static int g_pts_fsp_qpd_new  = 0;     /* `fskupd = fskupdNew(2)` 的次数（**首次**查询） */
static int g_pts_fsp_qpd_nc   = 0;     /* `fskupd = fskupdNoChange(1)` 的次数（**稳态**查询） */
static int g_pts_fsp_vis_ok   = 0;     /* 轨视觉"建起"的**下游见证**次数（`[VIS]`） */
/* ⏪ `T-A16`：`FsClearUpdateInfoInPage` 的成败面（`[CLRUPD]`／`[FS_PAGE_GAP]` 的计数只读口）。 */
static int g_pts_fsp_clr_ok   = 0;     /* **真清掉**该页增量状态的次数（成功 ⇒ 返 0） */
static int g_pts_fsp_clr_gap  = 0;     /* 返非 0 次数（失败面：`NULL`／未知上下文／不在册的页） */
/* ⏪ `T-A16`：**反腿开关**（默认 `0` ⇒ 主链产物**零影响**）。`1` ⇒ `FsClearUpdateInfoInPage`
   **假成功**：返 0 但**一个字节都不清** —— 用来证明「`[CLRUPD]` 之后下一次查询必须是 `fskupdNew`」
   这条断言**真的会红**（假成功腿 ⇒ 下一次查询仍是 `fskupdNoChange`）。
   ⚠️ **只在副本**以 `-DWPF_PTS_CLRUPD_FAKE=1` 单独编译，**绝不进主链**（照 `T-A15` 的 `WPF_PTS_QPD_FSKUPD_FAKE` 形制）。 */
#ifndef WPF_PTS_CLRUPD_FAKE
#define WPF_PTS_CLRUPD_FAKE 0
#endif
#if WPF_PTS_CLRUPD_FAKE == 1
#define WPF_PTS_CLRUPD_BASIS "FAKE-NO-CLEAR"
#else
#define WPF_PTS_CLRUPD_BASIS "reset-page-owned-incremental-state"
#endif
/* ⏪ `T-A19`：`FsUpdateBottomlessPage` 的成败面（`[FSUPDFSP]`／`[FS_PAGE_GAP]` 的计数只读口）。 */
static int g_pts_fsp_upd_ok  = 0;      /* **真刷新**该页自持状态次数（成功 ⇒ 返 0） */
static int g_pts_fsp_upd_gap = 0;      /* 返非 0 次数（失败面：`NULL` 出参／未知上下文／不在册的页） */
/* ⏪ `T-A19`：**反腿开关**（默认 `0` ⇒ 主链产物**零影响**）。`1` ⇒ `FsUpdateBottomlessPage` **假成功**：
   返 0 但**不校验页在册**（对任意页句柄都返 0）—— 用来证明「不在册的页必被拒」这条断言**真的会红**
   （假成功腿 ⇒ 伪页句柄亦返 0）。**只在副本**以 `-DWPF_PTS_UPDPSP_FAKE=1` 单独编译，**绝不进主链**。 */
#ifndef WPF_PTS_UPDPSP_FAKE
#define WPF_PTS_UPDPSP_FAKE 0
#endif
/* ⏪ `T-A20`：`FsQueryTextDetails` 的成败面（`[FSQTD]`／`[FS_PAGE_GAP]` 的计数只读口）。 */
static int g_pts_fsqtd_calls       = 0;   /* 进入次数（含重复） */
static int g_pts_fsqtd_gap         = 0;   /* 返非 0 次数（**本形态＝全部**：无成功分支） */
static int g_pts_fsqtd_nullout     = 0;   /* 路①：`pTextDetails==NULL` */
static int g_pts_fsqtd_nullpara    = 0;   /* 路②：`pPara==NULL` */
static int g_pts_fsqtd_unclaim     = 0;   /* 路③：`pPara` 不可认领（外来值／栈地址） */
static int g_pts_fsqtd_unknown_ctx = 0;   /* 路④：`pfscontext` 非空但不在册 */
static int g_pts_fsqtd_nomodel     = 0;   /* 路⑤：认领成功但**出参无源**（本侧无文本行模型） */
/* ⏪ `T-A22`（`N1`）：**按来源证据认领成功**的次数（身份成立，文本行模型仍无源 ⇒ 仍拒，出参不写）。 */
static int g_pts_fsqtd_provclaimed = 0;
/* ⏪ `T-A20`：**反腿开关**（默认 `0` ⇒ 主链产物**零影响**）。`1` ⇒ `FsQueryTextDetails` **假成功**：
   返 0 并把出参写成**捏造的** `fsktdCached` —— 用来证明「不可认领的 `pPara` 必被拒」这条断言
   **真的会红**（假腿 ⇒ 伪值亦"过关"）。**只在副本**以 `-DWPF_PTS_FSQTD_FAKE=1` 单独编译，
   **绝不进主链**（照 `T-A16`／`T-A19` 的反腿形制）。 */
#ifndef WPF_PTS_FSQTD_FAKE
#define WPF_PTS_FSQTD_FAKE 0
#endif
/* ⏪ `T-A15`：**"查询组"毗邻判定**（见 `FsQueryPageDetails` 的语义注释）。
   上一条 native 调用是否也是**对同一页**的 `FsQueryPageDetails`；由下游入口（轨/子轨的查询）清空。 */
static const void *g_pts_qpd_prev_page = NULL;

/* ══════════════════════════════════════════════════════════════════════════════════════════════
   ⏪ `T-A41`（`HOSTED-FSVIEW-VIEWPORT-DRIVE` · **`D0` 只读判别器**，`A40 §4 丙` ＋ `A40 §5.2 D0`）
   ──────────────────────────────────────────────────────────────────────────────────────────────
   问题（`A40 §6` 的 `NOINFO-VIEWPORT-BRANCH-CALLSITE`）：**页轨枚举（`PtsHelper.cs:134/225/327`）
   到底由哪条支发起** —— `ArrangeTrack`（arrange）／`UpdateTrackVisuals`（visual）／
   `UpdateViewportTrack`（viewport）**在 native 侧逐字节相同**（各 `FsQueryTrackDetails`×1 ＋
   `FsQueryTrackParaList`×1），而 `BaseParaClient.UpdateViewport` 是**托管内部虚方法、无 P/Invoke、无导出**
   （现取 `grep -ci updateviewport bin/exports.txt` ＝ 0）⇒ native **直读不到调用者**。

   ⇒ 本判别器**不是直读，是具名推断**（口径写死，防被读宽）：
     · **轮**（round）＝ 自一次**页轨枚举**成功起，到**下一次页轨枚举**或**下一次 `FsQueryPageDetails`**
       （三个消费者都先调它）为止；
     · 该轮内的**下游签名**决定 `via=`：
         `FsQueryFigureObjectDetails`（`FIGOBJ`；**唯一**调用者 `TextParaClient.OnArrange:1238/1316`）⇒ `via=arrange`
         否则 `FsQueryLineListSingle`（`FSQLL`；`TextParaClient.RenderSimpleLines:3218` 与 `OnArrange:1254`）⇒ `via=visual`
         否则 `FsQueryAttachedObjectList`（`ATT`；`TextParaClient.UpdateViewport:169`／`ValidateVisual:124`）⇒ `via=viewport`
         否则 ⇒ `via=unknown`（**不给标签**，不猜）
     · 三支互斥且**每轮恰一个标签** ⇒ `n_arrange+n_visual+n_viewport+n_unknown` ＝ 页轨枚举行数（**可对账**）。
   **零行为变化**：只多一条具名 stderr 行；`via=` 的**唯一来源**是本状态机（**不是** env、**不是**常量、
   **不是**无条件打印）⇒ 反极性（撤驱动）时 `via=viewport` 计数**必**随链到达与否改变；恒打同一标签 ⇒ 必红。
   ⚠️ **射程（如实划界）**：`via=visual` 与 `via=viewport` 的分辨力**只**来自"该轮里有没有 `FSQLL`"——
   对**含附属对象**的宿主段两者本就该有差（`ValidateVisual` 必打 `FSQLL`、`UpdateViewport` 在
   `IsDeferredVisualCreationSupported()==false` 时**不打**）；对**无附属对象**段该差**可能消失** ⇒
   逐轮的 `via=` 是**推断**，判词里必须标注（本行尾已具名 `NOINFO=`）。
   ══════════════════════════════════════════════════════════════════════════════════════════════ */
static int g_pts_qvp_arrange = 0, g_pts_qvp_visual = 0, g_pts_qvp_viewport = 0, g_pts_qvp_unknown = 0;
static int g_pts_qvp_open = 0;                        /* 1 ＝ 有一轮开着（等标签） */
static unsigned long g_pts_qvp_round = 0;             /* 轮号（与 `[FSPARALIST-FILL]` 同序） */
static int g_pts_qvp_saw_fsqll = 0, g_pts_qvp_saw_att = 0, g_pts_qvp_saw_figobj = 0;
static const void *g_pts_qvp_page = NULL;
static const void *g_pts_qvp_qpd_page = NULL;         /* 最近一次成功 `FsQueryPageDetails` 的页（只读） */
static void wpf_pts_qvp_begin(void)
{
    g_pts_qvp_open = 1;
    g_pts_qvp_round++;
    g_pts_qvp_saw_fsqll = 0; g_pts_qvp_saw_att = 0; g_pts_qvp_saw_figobj = 0;
    g_pts_qvp_page = g_pts_qvp_qpd_page;
}
static void wpf_pts_qvp_end(const char *why)
{
    const char *via; int *ctr;
    if (!g_pts_qvp_open) return;
    if (g_pts_qvp_saw_figobj)     { via = "arrange";  ctr = &g_pts_qvp_arrange; }
    else if (g_pts_qvp_saw_fsqll) { via = "visual";   ctr = &g_pts_qvp_visual; }
    else if (g_pts_qvp_saw_att)   { via = "viewport"; ctr = &g_pts_qvp_viewport; }
    else                          { via = "unknown";  ctr = &g_pts_qvp_unknown; }
    (*ctr)++;
    fprintf(stderr, "[FSQVP] via=%s round=%lu page=%p closed_by=%s fsqll=%d att=%d figobj=%d "
                    "n_arrange=%d n_visual=%d n_viewport=%d n_unknown=%d "
                    "NOINFO=viewport-branch-callsite(inference:adjacent-events+page-query-state)\n",
            via, g_pts_qvp_round, g_pts_qvp_page, why,
            g_pts_qvp_saw_fsqll, g_pts_qvp_saw_att, g_pts_qvp_saw_figobj,
            g_pts_qvp_arrange, g_pts_qvp_visual, g_pts_qvp_viewport, g_pts_qvp_unknown);
    g_pts_qvp_open = 0;
}

/* ── `T-A15` 的 `FSKUPDATE` 值域（逐字照 `Pts.cs:1934-1941` 的枚举；本模块只落两格）────────── */
#define WPF_PTS_FSKUPD_NOCHANGE 1      /* `fskupdNoChange` */
#define WPF_PTS_FSKUPD_NEW      2      /* `fskupdNew`      */
/* ⚠️ **反腿开关**（默认 `0`）：**只在副本**以 `-DWPF_PTS_QPD_FSKUPD_FAKE=<n>` 单独编译，**绝不进主链**。
   `0`＝真值（**首次 `New(2)`／见证后稳态 `NoChange(1)`**）｜`1`＝**恒 `0`**（＝上游 `Pts.cs:1695`
   明示不可能的 `fskupdInherited`，即 `T-A15` 之前的旧行为）⇒ 消费者 `:999`／`:1029` 两处判否
   ⇒ **`ArgumentOutOfRangeException` 必回**（`D1` **该红必红**）｜`2`＝**恒 `2`**（每趟都 New）
   ⇒ 把"未变"谎报成"新建"（`D2` **该红必红**：`fskupd=1` **永不出现**）。 */
#ifndef WPF_PTS_QPD_FSKUPD_FAKE
#define WPF_PTS_QPD_FSKUPD_FAKE 0
#endif

// 【格 7 · 真实现】成功 ⇒ 0 ＋ `*ppfspage` = **本次真分配**的页对象（两次调用**互不相等**）；
//   失败 ⇒ **返非 0** ＋ `*ppfspage = NULL`（**不许留半成品指针**）＋ `*pfsfmtrbl = 未达成`（**不许留毒值**）
//   ＋ **一行具名留痕**（见上）。
//   拒绝面：`ppfspage == NULL`（不给"写空也算成功"）／`pfsfmtrbl == NULL`／`pfscontext == NULL`／
//   **`pfscontext` 不在册**（按**指针身份**查 `g_pts_doc_live[]`，**不 deref 未知句柄** —— 与
//   `LoDestroyContext`／`DestroyDocContext` 同纪律）。
int FsCreatePageBottomless(void *pfscontext, const void *fsnmsect, int *pfsfmtrbl, void **ppfspage)
{
    /* 失败路径先把两个出参置到"确定未达成"：清空指针 ＋ 未达成结果（**一个字节的残留都不留**） */
    if (ppfspage)   *ppfspage   = NULL;
    if (pfsfmtrbl)  *pfsfmtrbl  = WPF_PTS_FSFMTRBL_NOT_ACHIEVED;
    const char *reason = NULL;
    if (!ppfspage)          reason = "null-out";
    else if (!pfsfmtrbl)    reason = "null-result-out";
    else if (!pfscontext)   reason = "null-ctx";
    else {
        int found = 0;
        for (int i = 0; i < g_pts_doc_live_n; i++) {          /* 按**指针身份**查在册上下文 */
            if (g_pts_doc_live[i]->magic != WPF_PTS_DOC_MAGIC) continue;
            if ((const void *)g_pts_doc_live[i] == (const void *)pfscontext) { found = 1; break; }
        }
        if (!found) reason = "unknown-ctx";
    }
    if (!reason && g_pts_fsp_live_n >= WPF_PTS_FSP_MAX) reason = "table-full";
    if (!reason) {
        wpf_pts_fsp *p = (wpf_pts_fsp *)calloc(1, sizeof(*p));
        if (!p) reason = "alloc-fail";
        else {
            p->magic  = WPF_PTS_FSP_MAGIC;
            p->ctx    = pfscontext;
            p->sect   = fsnmsect;
            /* ⏪ `t146`：调用窗已齐 ⇒ 真调两条回调（每进程只探第一个窗口；伪 nms 只在副本） */
            wpf_pts_drive_probe(wpf_pts_doc_ptr(pfscontext), fsnmsect, "FsCreatePageBottomless");
            p->result = 0;                     /* `fmtrblGoalReached`（本次调用的结果） */
            p->pg_w = 768; p->pg_h = 576;     /* 页矩形：本模块自持（与装置窗口几何同源） */
            p->bbox_defined = 1;               /* 声明 bbox 有效（否则托管侧按"未定义"处理） */
            p->c_paras = 1;                    /* `t127`：该 track 有 1 段（按对象存；非全局常量） */
            g_pts_fsp_live[g_pts_fsp_live_n++] = p;
            g_pts_fsp_ok++;
            {   /* 观测镜（**镜像**，不是权威）：指针量一律走 `ptr0`／`ptr1` 专用域 */
                wpf_pts_jmp_push("FsCreatePageBottomless", (void *)pfscontext,
                                 (const void *)&p->result, 1, 0, p->result, 0, 0, 0,
                                 (const void *)p, (const void *)p->ctx);
            }
            { int _i = wpf_pts_index("FsCreatePageBottomless"); if (_i >= 0) g_pts_seen[_i]++; }
            g_pts_seq++;
            *pfsfmtrbl = p->result;
            *ppfspage  = (void *)p;
            return 0;                          /* ← 改成别的值就是制造静默半通 */
        }
    }
    /* ── 失败面：**必须留痕**（C4）；否则托管侧 `ValidateAndTrace` 可能一个字都不记（§2.2 形态 b） */
    g_pts_fsp_gap++;
    g_pts_fsp_rej++;
    g_pts_fsp_last_reason = reason;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s ctx=%p sect=%p ok=%d gap=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, fsnmsect, g_pts_fsp_ok, g_pts_fsp_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}


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
#if WPF_PTS_FSP_PL_METHODS_SNAP
/* ── ⏪ `t167`（P1-W87）：`FSIMETHODS` **窗内值化**（D1）＋**驱动点读回**（D1 的对照）＋**零位指纹**（D2）──
   🔴 **D1 先行**：先把 17 字在**存储窗内**（本函数调用期内）值拷贝下来并打印；到**驱动点**再用
      **同一个悬垂指针**读 17 字，**逐字比对** ⇒ 不同 ＝ **use-after-return 确证**（归因到此结束）。
   🔴 **判据面照抄 `FSCBK`**：三态 `NONE/ALLZERO/VALUE` ＋ **具名 gap 行**（`[FSPARAMETH-SNAP-GAP]`）
      ⇒ "未值化"与"值化后全 0"**判词不同**。
   🔴 **`136 B` 只许实测**：`_Static_assert(sizeof(wpf_pts_fsimethods) == 136)`（镜像见下）＋运行时
      `words=17 bytes=136` 逐趟打印。 */
typedef struct {                        /* FSIMETHODS 镜像（**只用于尺寸/偏移实测**；不 deref 托管表） */
    void *w[WPF_PTS_METHOD_WORDS];
} wpf_pts_fsimethods_mirror;
_Static_assert(WPF_PTS_METHOD_WORDS == 17, "FSIMETHODS 槽数 != 17");
_Static_assert(sizeof(wpf_pts_fsimethods_mirror) == 136, "sizeof(FSIMETHODS) != 136（实测不符 ⇒ 计算值错）");
_Static_assert(sizeof(((wpf_pts_io_table *)0)->methods_snap) == 136, "methods_snap 不是 136 B");

static int g_pts_method_zero_cnt = 0;   /* ⏪ `t168`：窗内副本的零位计数（D2 重判用） */
static void wpf_pts_methods_snap_gap(const char *reason, const void *addr)
{
    fprintf(stderr, "[FSPARAMETH-SNAP-GAP] rc=%d reason=%s entry=CreateInstalledObjectsInfo addr=%p state=NONE\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, addr);
}
/* 窗内值化：**唯一合法时机**＝本函数的调用期内（此后再读同一地址就是悬垂） */
static void wpf_pts_methods_snapshot(wpf_pts_io_table *t, const void *addr)
{
#if WPF_PTS_FSP_PL_METH_NULL
    addr = NULL;                       /* ⏪ t168 注入：触发 NONE 态（＋具名 gap 行） */
#endif
    t->methods_addr = addr;
    if (!addr) { t->methods_snap_state = WPF_PTS_METHOD_STATE_NONE; wpf_pts_methods_snap_gap("null-methods", addr); return; }
    memcpy(t->methods_snap, addr, WPF_PTS_METHOD_SIZE);
#if WPF_PTS_FSP_PL_METH_ALLZERO
    memset(t->methods_snap, 0, WPF_PTS_METHOD_SIZE);   /* ⏪ t168 注入：触发 ALLZERO 态 */
#endif
    int nz = 0, zero_idx = -1, zero_cnt = 0;
    for (int i = 0; i < WPF_PTS_METHOD_WORDS; i++) {
        unsigned long long w = 0;
        for (int b = 0; b < 8; b++) w |= ((unsigned long long)t->methods_snap[i * 8 + b]) << (8 * b);
        if (w) nz++; else { zero_cnt++; if (zero_idx < 0) zero_idx = i; }
    }
    g_pts_method_zero_cnt = zero_cnt;      /* ⏪ t168：零位计数（D2 重判要用） */
    t->methods_snap_state   = (nz == 0) ? WPF_PTS_METHOD_STATE_ALLZERO : WPF_PTS_METHOD_STATE_VALUE;
    t->methods_snap_nonzero = nz;
    t->rb_zero_index_win    = zero_idx;
    t->rb_same = -1; t->rb_first_diff = -1;
    fprintf(stderr, "[FSPARAMETH-SNAP] entry=CreateInstalledObjectsInfo addr=%p words=%d bytes=%d state=%s "
                    "nonzero=%d zero_index_win=%d w0=%p w1=%p w14=%p w15=%p w16=%p（**窗内值化**；此后该地址即悬垂）\n",
            addr, WPF_PTS_METHOD_WORDS, WPF_PTS_METHOD_SIZE,
            (t->methods_snap_state == WPF_PTS_METHOD_STATE_VALUE) ? "VALUE"
              : (t->methods_snap_state == WPF_PTS_METHOD_STATE_ALLZERO) ? "ALLZERO" : "NONE",
            nz, zero_idx,
            (void *)(unsigned long)*(const unsigned long long *)(const void *)(t->methods_snap + 0),
            (void *)(unsigned long)*(const unsigned long long *)(const void *)(t->methods_snap + 8),
            (void *)(unsigned long)*(const unsigned long long *)(const void *)(t->methods_snap + 112),
            (void *)(unsigned long)*(const unsigned long long *)(const void *)(t->methods_snap + 120),
            (void *)(unsigned long)*(const unsigned long long *)(const void *)(t->methods_snap + 128));
    fprintf(stderr, "[FSPARAMETH-SNAP] zero_cnt_win=%d idx0_zero=%d slotN_zero=%d（1-based；判据写「第 15 槽」）\n",
            zero_cnt, zero_idx, (zero_idx >= 0) ? zero_idx + 1 : -1);
}
/* D1 的对照面：**在驱动点**用**同一个悬垂指针**再读 17 字并逐字比对 */
static int wpf_pts_methods_readback(wpf_pts_io_table *t, const char *where)
{
    if (t->methods_snap_state == WPF_PTS_METHOD_STATE_NONE) {
        fprintf(stderr, "[FSPARAMETH-READBACK] at=%s v=NO-SNAPSHOT（未值化 ⇒ 无对照）\n", where);
        return 0;
    }
    unsigned char now[WPF_PTS_METHOD_SIZE];
    memcpy(now, t->methods_addr, WPF_PTS_METHOD_SIZE);      /* ← 这里可能 SIGSEGV：那就是 D1 的证据 */
    int diff = -1;
    for (int i = 0; i < WPF_PTS_METHOD_WORDS; i++) {
        if (memcmp(t->methods_snap + i * 8, now + i * 8, 8) != 0) { diff = i; break; }
    }
    int zero_now = -1;
    for (int i = 0; i < WPF_PTS_METHOD_WORDS; i++) {
        unsigned long long w = 0;
        for (int b = 0; b < 8; b++) w |= ((unsigned long long)now[i * 8 + b]) << (8 * b);
        if (!w) { zero_now = i; break; }
    }
    t->rb_calls++; t->rb_same = (diff < 0) ? 1 : 0; t->rb_first_diff = diff;
    t->rb_zero_index_now = zero_now;
    fprintf(stderr, "[FSPARAMETH-READBACK] at=%s dangling=%p same=%d first_diff=%d zero_index_win=%d "
                    "zero_index_now=%d win0=%p now0=%p win15=%p now15=%p calls=%d v=%s\n",
            where, t->methods_addr, t->rb_same, diff, t->rb_zero_index_win, zero_now,
            (void *)(unsigned long)*(const unsigned long long *)(const void *)(t->methods_snap + 0),
            (void *)(unsigned long)*(const unsigned long long *)(const void *)(now + 0),
            (void *)(unsigned long)*(const unsigned long long *)(const void *)(t->methods_snap + 120),
            (void *)(unsigned long)*(const unsigned long long *)(const void *)(now + 120),
            t->rb_calls, (diff < 0) ? "IDENTICAL" : "USE-AFTER-RETURN-CONFIRMED");
    return (diff < 0) ? 1 : 0;
}
/* D2：零位指纹（**必须在 D1 判"副本有效"之后**才有意义） */
/* ⏪ `t168`（队长口径二）：**"有效副本" ＝ 窗内值化成功的那份拷贝**（`state=VALUE`），
   **不是** `d1_same==1` —— `D1` 的 `same=0` 正是"悬垂确证"的**预期**结果，与副本有效性无关。
   ⇒ `D2` 在**有效副本**上数零位：**零位恰一处** ∧ 该位＝**1-based 第 15 槽**（`idx0=14`）⇒ 槽序正确。 */
static int wpf_pts_methods_d2(wpf_pts_io_table *t)
{
    const int valid = (t->methods_snap_state == WPF_PTS_METHOD_STATE_VALUE && t->methods_snap_nonzero > 0);
    const int ok = valid && (g_pts_method_zero_cnt == 1) && (t->rb_zero_index_win == 14);
    fprintf(stderr, "[FSPARAMETH-D2] copy_state=%s valid_copy=%d zero_cnt_win=%d idx0_zero=%d slotN_zero=%d "
                    "expect_slotN=15 calib=both(idx0=0-based, slotN=1-based) nonzero_win=%d d1_same=%d "
                    "v=%s\n",
            (t->methods_snap_state == WPF_PTS_METHOD_STATE_VALUE) ? "VALUE"
              : (t->methods_snap_state == WPF_PTS_METHOD_STATE_ALLZERO) ? "ALLZERO" : "NONE",
            valid, g_pts_method_zero_cnt, t->rb_zero_index_win,
            (t->rb_zero_index_win >= 0) ? t->rb_zero_index_win + 1 : -1,
            t->methods_snap_nonzero, t->rb_same,
            ok ? "SLOT-ORDER-OK(唯一零位=1-based 第 15 槽 ⇒ 与 PtsCache.cs:617 吻合)"
               : (valid ? "SLOT-ORDER-MISMATCH(有效副本上零位不符)" : "NO-VALID-COPY"));
    return ok;
}
#endif   /* WPF_PTS_FSP_PL_METHODS_SNAP */

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
#if WPF_PTS_FSP_PL_METHODS_SNAP
    wpf_pts_methods_snapshot(t, fssubtrackparamethods); /* ⏪ t167 D1：**窗内**值化（唯一合法时机） */
#endif
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

// ══════════════════════════════════════════════════════════════════════════════════════════
// ⏪ `t133`（P1-W55）测量小单 —— `FSCONTEXTINFO.fscbk` / `FSCBKGEN` 槽偏移的**实测值**（native 只读回读）
//
//   **实测来源（同趟现取，两条独立证据）**：
//     ① **托管侧仪器**（运行期布局 API）：在**真产物** `PresentationFramework.dll` 上取
//        `Marshal.OffsetOf` / `Marshal.SizeOf` ⇒ `fscbk=40`、`FSCBK{cbkgen=0,cbktxt=256,cbkobj=504,
//        cbkfig=568,cbkwrd=592}`、`SizeOf(FSCBK)=824=103×8`、`SizeOf(FSCONTEXTINFO)=872`。
//     ② **本文件内的只读回读指纹**（`wpf_pts_fscbk_probe`）：按 ① 的偏移，在**真实**
//        `FSCONTEXTINFO`（app 进程里由托管侧装配、CLR 封送出来的那一份）上逐 8 B 字回读，并把
//        「观测到的空槽位置」与「由托管侧源码预言的空槽位置」逐项比对（**预言 vs 观测**）。
//        ⚠️ 这两个偏移**不是**"按字段类型数出来"的：① 是运行期 API 的返回值，② 是现场字节。
//
//   **候选值 vs 实测值（成对对照）**：`t132` 只能"算"：`fscbk=+40`／`pfnGetNextSection=+56`／
//     `pfnGetFirstPara=+136`／`pfnCreateParaclient=+176` —— 本件实测**逐项相同**（见载体 §1）。
//   **纪律**：本文件**只**读、**不试调**（试调错槽会崩；拿伪造 `nms`/`nmp` 调真槽会让托管侧
//     `HandleToObject` 触发 `Invariant.FailFast`（不可捕获））。**一个回调都不调**。
// ══════════════════════════════════════════════════════════════════════════════════════════
/* ⚠️ `t141`：`WPF_PTS_FSCBK_OFF`／`WPF_PTS_FSCBK_SIZE` 的**唯一定义处**已上移到 `wpf_pts_doc`
   （本模块顶部，约 `:122-136`）—— doc 的快照字段要用到它们。此处**不再重复定义**
   （一处定义、多处引用）。 */
#define WPF_PTS_FSCBK_CBKGEN_OFF     0
#define WPF_PTS_FSCBK_CBKTXT_OFF     256
#define WPF_PTS_FSCBK_CBKOBJ_OFF     504
#define WPF_PTS_FSCBK_CBKFIG_OFF     568
#define WPF_PTS_FSCBK_CBKW_RD_OFF    592
#define WPF_PTS_CBKGEN_SLOTS         32
#define WPF_PTS_CBKTXT_SLOTS         31
#define WPF_PTS_CBKOBJ_SLOTS         8
#define WPF_PTS_CBKFIG_SLOTS         3
#define WPF_PTS_CBKW_RD_SLOTS        29

/* 编译期钉死：组基址必须**互为累加**（错一个就编不过）＋ 目标槽的绝对偏移必须是"组基址 + 槽序×8" */
_Static_assert(WPF_PTS_FSCBK_CBKTXT_OFF  == WPF_PTS_FSCBK_CBKGEN_OFF + WPF_PTS_CBKGEN_SLOTS * 8, "cbktxt base != cbkgen base + 32*8");
_Static_assert(WPF_PTS_FSCBK_CBKOBJ_OFF  == WPF_PTS_FSCBK_CBKTXT_OFF + WPF_PTS_CBKTXT_SLOTS * 8, "cbkobj base != cbktxt base + 31*8");
_Static_assert(WPF_PTS_FSCBK_CBKFIG_OFF  == WPF_PTS_FSCBK_CBKOBJ_OFF + WPF_PTS_CBKOBJ_SLOTS * 8, "cbkfig base != cbkobj base + 8*8");
_Static_assert(WPF_PTS_FSCBK_CBKW_RD_OFF == WPF_PTS_FSCBK_CBKFIG_OFF + WPF_PTS_CBKFIG_SLOTS * 8, "cbkwrd base != cbkfig base + 3*8");
_Static_assert(WPF_PTS_FSCBK_SIZE == (WPF_PTS_CBKGEN_SLOTS + WPF_PTS_CBKTXT_SLOTS + WPF_PTS_CBKOBJ_SLOTS
                                      + WPF_PTS_CBKFIG_SLOTS + WPF_PTS_CBKW_RD_SLOTS) * 8, "FSCBK 大小 != 103*8");
_Static_assert(WPF_PTS_FSCBK_OFF % 8 == 0, "fscbk 基址未 8 字节对齐");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_FSCBK_CBKGEN_OFF + 16 == 56,  "pfnGetNextSection 绝对偏移 != 56");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_FSCBK_CBKGEN_OFF + 40 == 80,  "pfnGetMainTextSegment 绝对偏移 != 80");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_FSCBK_CBKGEN_OFF + 96 == 136, "pfnGetFirstPara 绝对偏移 != 136");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_FSCBK_CBKGEN_OFF + 104 == 144, "pfnGetNextPara 绝对偏移 != 144");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_FSCBK_CBKGEN_OFF + 128 == 168, "pfnGetParaProperties 绝对偏移 != 168");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_FSCBK_CBKGEN_OFF + 136 == 176, "pfnCreateParaclient 绝对偏移 != 176");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_FSCBK_CBKGEN_OFF + 152 == 192, "pfnDestroyParaclient 绝对偏移 != 192");

/* ── ⏪ `T-A28`（`TASK-0302` 增量）：`cbktxt` 槽 `pfnFormatLine` 的**唯一偏移定义处** ──────────────
   上游声明（`upstream/…/PtsHost/Pts.cs:676`，`FSCBKTXT` 第 10 个字段 ⇒ **索引 9**）：
       `internal FormatLine pfnFormatLine;`
   行排版链（`T-A27` §1.4 现取）：`pfnFormatLine` → `PtsHost.cs:1341 FormatLine` →
   `TextParagraph.cs:664 FormatLine` → `Line.cs:271 Line.Format` → `TextFormatter.FormatLine`（本移植 ⇒ shim）。
   绝对偏移 ＝ `fscbk(+40)` ＋ `cbktxt 组基(+256)` ＋ `9×8` ＝ **`+368`**（`T-A27` `P1-fscbk-slot-recon.md`
   的"相对 `+328`／绝对 `+368`"同值）⇒ 快照下标 ＝ `328/8` ＝ **`41`**（`fscbk_snap` 起点即 `fscbk`）。 */
#define WPF_PTS_CBKTXT_IDX_FORMATLINE   9
#define WPF_PTS_SNAP_IDX_FORMATLINE     (WPF_PTS_FSCBK_CBKTXT_OFF / 8 + WPF_PTS_CBKTXT_IDX_FORMATLINE)  /* 41 */
_Static_assert(WPF_PTS_SNAP_IDX_FORMATLINE == 41, "pfnFormatLine 快照下标 != 41");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_FORMATLINE * 8 == 368,
               "pfnFormatLine 绝对偏移 != 368（cbktxt 6 字节头 + 第 10 槽）");
/* ── ⏪ `T-A36`（`TASK-0302` 增量 · `NATIVE-PTS-ATTACHED-OBJECTS-BACKFILL`）：`cbktxt` 槽
   `pfnGetNumberAttachedObjectsInTextLine` 的**唯一偏移定义处** ───────────────────────────────
   上游声明（`upstream/…/PtsHost/Pts.cs:694`，`FSCBKTXT` 的第 28 个字段 ⇒ **索引 27**）：
       `internal GetNumberAttachedObjectsInTextLine pfnGetNumberAttachedObjectsInTextLine;`
   （`FSCBKTXT` 字段序 0..30 共 31 个 ⇒ `WPF_PTS_CBKTXT_SLOTS=31` 恰好装得下，见 `:692-697`）。
   绝对偏移 ＝ `fscbk(+40)` ＋ `cbktxt 组基(+256)` ＋ `27×8` ＝ **`+512`** ⇒ 快照下标 ＝ `256/8 + 27` ＝ **59**。 */
#define WPF_PTS_CBKTXT_IDX_GETNUMATTACHLINE   27
#define WPF_PTS_SNAP_IDX_GETNUMATTACHLINE     (WPF_PTS_FSCBK_CBKTXT_OFF / 8 + WPF_PTS_CBKTXT_IDX_GETNUMATTACHLINE)
_Static_assert(WPF_PTS_SNAP_IDX_GETNUMATTACHLINE == 59, "pfnGetNumberAttachedObjectsInTextLine 快照下标 != 59");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETNUMATTACHLINE * 8 == 512,
               "pfnGetNumberAttachedObjectsInTextLine 绝对偏移 != 512（cbktxt 第 28 槽）");
/* ⏪ `T-A36`：`pfnGetAttachedObjectsInTextLine`（`Pts.cs:695`，`FSCBKTXT` 第 29 个字段 ⇒ **索引 28**）。
   绝对偏移 ＝ 40 ＋ 256 ＋ 28×8 ＝ **`+520`** ⇒ 快照下标 ＝ 32 + 28 ＝ **60**。 */
#define WPF_PTS_CBKTXT_IDX_GETATTACHLINE      28
#define WPF_PTS_SNAP_IDX_GETATTACHLINE        (WPF_PTS_FSCBK_CBKTXT_OFF / 8 + WPF_PTS_CBKTXT_IDX_GETATTACHLINE)
_Static_assert(WPF_PTS_SNAP_IDX_GETATTACHLINE == 60, "pfnGetAttachedObjectsInTextLine 快照下标 != 60");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETATTACHLINE * 8 == 520,
               "pfnGetAttachedObjectsInTextLine 绝对偏移 != 520（cbktxt 第 29 槽）");
/* ── ⏪ `T-A37`（`NATIVE-PTS-ATTACHED-CONTENT-LAYOUT`）：附属对象**内容排版回调**的**唯一偏移定义处** ──
   上游声明（`upstream/…/PtsHost/Pts.cs`，`StructLayout.Sequential`，指针宽 8）：
     · `FSCBKF:CBKFIG.pfnGetFigureProperties`（`Pts.cs:562`，`FSCBKFIG` 第 1 槽）：
       `cbkfig` 组基（相对 `fscbk` ＋568）＋ 0×8 ⇒ 绝对 ＝ 40 ＋ 568 ＝ **`+608`** ⇒ 快照下标 ＝ 568/8 ＝ **71**。
     · `FSCBKOBJ.pfnGetObjectHandlerInfo`（`Pts.cs:659`，`FSCBKOBJ` 第 8 槽）：
       `cbkobj` 组基（相对 `fscbk` ＋504）＋ 7×8 ⇒ 绝对 ＝ 40 ＋ 504 ＋ 56 ＝ **`+600`** ⇒ 快照下标 ＝ 560/8 ＝ **70**。
   ⚠️ 这两个槽**只读捕获**（快照里已含）；本增量**不 deref** 托管结构，只用函数指针值发调（同 `pfnFormatLine` 体例）。 */
#define WPF_PTS_SNAP_IDX_GETOBJHANDLERINFO    (WPF_PTS_FSCBK_CBKOBJ_OFF / 8 + 7)                 /* 70 */
#define WPF_PTS_SNAP_IDX_GETFIGUREPROPERTIES  (WPF_PTS_FSCBK_CBKFIG_OFF / 8 + 0)                 /* 71 */
_Static_assert(WPF_PTS_SNAP_IDX_GETOBJHANDLERINFO == 70, "pfnGetObjectHandlerInfo 快照下标 != 70");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETOBJHANDLERINFO * 8 == 600,
               "pfnGetObjectHandlerInfo 绝对偏移 != 600（cbkobj 第 8 槽）");
_Static_assert(WPF_PTS_SNAP_IDX_GETFIGUREPROPERTIES == 71, "pfnGetFigureProperties 快照下标 != 71");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETFIGUREPROPERTIES * 8 == 608,
               "pfnGetFigureProperties 绝对偏移 != 608（cbkfig 第 1 槽）");
/* 内容排版回调（`pfnGetFigureProperties`）的 C 侧原型（照 `PtsHost.GetFigureProperties` ＋ `FigureParagraph.GetFigureProperties` 逐参）。
   `FSFIGUREPROPS` ＝ 8×int ＝ 32 B（`Pts.cs:585`）；出参一律指针。 */
typedef int (*wpf_pts_fn_get_figure_properties)(
    const void *pfsclient, const void *pfsparaclient, const void *nmpfigure,
    int f_in_text_line, unsigned int fswdir, int f_bottom_undefined,
    int *dur, int *dvr, void *fsfigprops, int *c_polygons, int *c_vertices,
    int *dur_dist_text_left, int *dur_dist_text_right, int *dvr_dist_text_top, int *dvr_dist_text_bottom);
/* ── ⏪ `T-A52`（`NATIVE-PTS-FLOATERCBK`）：附属对象**内容排版表**（`FSFLOATERCBK`）的**唯一形状/偏移定义处** ──
   上游声明（`upstream/…/PtsHost/Pts.cs:1028`，`FSCBKOBJ` 同族；`StructLayout.Sequential`，指针宽 8）：
     · `FSFLOATERCBK` 16 槽（`Pts.cs:1028-1046`）；槽序逐字：`0 pfnGetFloaterProperties`／
       `1 pfnFormatFloaterContentFinite`／`2 pfnFormatFloaterContentBottomless`／`3 pfnUpdateBottomlessFloaterContent`／…
     · `FSFLOATERINIT`（`Pts.cs:1074`）＝ `{ FSFLOATERCBK fsfloatercbk; }`（**只此一字段**）。
   该表由托管在 `PTS.GetFloaterHandlerInfo(ref FSFLOATERINIT, pObjectInfo)`（`Pts.cs:3065`，调用点
     `PtsCache.cs:259`／现取生成件 `PtsCache.Linux.cs:345`）里交出 —— `InitFloaterObjInfo`
     （`PtsCache.Linux.cs:823-838` 逐槽赋 `ptsHost.FormatFloaterContent*`）⇒ 本侧在
     `GetFloaterHandlerInfo` 里**只读捕获函数指针值**（同 `pfnFormatLine` 体例：**不 deref** 托管结构）。
   驱动入口 `FloaterParagraphId`（`PtsHost.cs:81`）＝ `SubpageParagraphId + 1`；现取本移植 = **2**
     （见 `[FSATT-PROBE] … att0_id=2`，与 `PtsHost.FloaterParagraphId` 同值）。 */
#define WPF_PTS_FLOATERCBK_SLOTS          16
#define WPF_PTS_FLOATER_ID                2
#define WPF_PTS_FLOATER_IDX_FMT_FINITE    1
/* 发调 `pfnFormatFloaterContentFinite` 时的**可用空间**（＝ `durAvailable`／`dvrAvailable`）。
   取本侧附属对象几何约定（`T-A36`：`WPF_PTS_ATT_FLO_DU/DV`，285×100 DIP）**同值** —— 该约定的
   定义处在本文件更下方，此处先落一组同名值以免前置声明次序问题（两处数值必须一致）。 */
#define WPF_PTS_FLOATER_AVAIL_DU          85500
#define WPF_PTS_FLOATER_AVAIL_DV          30000
typedef int (*wpf_pts_fn_get_object_handler_info)(const void *pfsclient, int idobj, void *pobjectinfo);
/* `pfnFormatFloaterContentFinite` 的 C 侧原型（照 `Pts.cs:2581-2603` 逐参）。
   `FSFMTR` ＝ 3×int ＝ 12 B；`FSBBOX` ＝ `FSRECT(4×int)` ＋ `int fDefined` ＝ 20 B（`Pts.cs` 同族）；出参一律指针。 */
typedef int (*wpf_pts_fn_format_floater_content_finite)(
    const void *pfsclient, const void *pfsparaclient, const void *pfsbrk_in, int f_br_from_prev,
    const void *nmfloater, const void *pftnrej, int f_empty_ok, int f_suppress_top_space,
    unsigned int fswdir, int f_at_max_width, int dur_available, int dvr_available, int fsksuppress,
    void *fsfmtr_out, void **pfsbrk_content_out, void **pbrkrecpara_out,
    int *dur_floater_width, int *dvr_floater_height, void *fsbbox_out,
    int *c_polygons, int *c_vertices);
/* `GetFloaterHandlerInfo` 的**只读捕获位**（本侧持有最近一次交出的托管回调表；同 `pfnFormatLine` 体例）。 */
static const void *g_pts_floater_cbk[WPF_PTS_FLOATERCBK_SLOTS];
static int g_pts_floater_cbk_ok = 0, g_pts_floater_cbk_gap = 0;
static int g_pts_floater_drv_calls = 0, g_pts_floater_drv_ok = 0, g_pts_floater_drv_gap = 0;
/* 预言的空槽（**由托管侧源码**得来：`cbkobj` 的前三槽与整个 `cbkwrd` 声明为 `IntPtr` 且**未赋值**）
   ⇒ 只读回读若在这些绝对偏移上读到非 0，说明偏移（或对齐/顺序）**另有其事** ⇒ 指纹判 FAIL。 */
#define WPF_PTS_NULL_PRED_CBKOBJ_LEAD 3
#define WPF_PTS_NULL_PRED_CBKW_RD     29
#define WPF_PTS_NULL_PRED_TOTAL       (WPF_PTS_NULL_PRED_CBKOBJ_LEAD + WPF_PTS_NULL_PRED_CBKW_RD)

/* ── ⏪ `T-A53`（`NATIVE-PTS-TABLEOBJ`）：Table 族（`FSTABLEOBJINIT`／`FSTABLEOBJCBK`）的**唯一形状/偏移定义处** ──
   上游声明（`upstream/…/PtsHost/Pts.cs`，`StructLayout.Sequential`，指针宽 8）：
     · `FSTABLEOBJINIT`（`Pts.cs:1852`）＝ `{FSTABLEOBJCBK tableobjcbk(5); FSTABLECBKFETCH tablecbkfetch(15);
       FSTABLECBKCELL tablecbkcell(14); FSTABLECBKFETCHWORD tablecbkfetchword(11);}` ⇒ **45 槽／360 B**。
     · 槽号逐字：`0 pfnGetTableProperties`／`1 pfnAutofitTable`／`2 pfnUpdAutofitTable`／
       `3 pfnGetMCSClientAfterTable`／`4 pfnGetDvrUsedForFloatTable`／`5..8 头/脚取行四槽`／
       `9 pfnGetFirstRow`／`10 pfnGetNextRow`／`11 pfnUpdFChangeInHeaderFooter`／
       `12 pfnUpdGetFirstChangeInTable`／`13 pfnUpdGetRowChange`／`14 pfnUpdGetCellChange`／
       `15 pfnGetDistributionKind`／`16 pfnGetRowProperties`／`17 pfnGetCells`／
       `18 pfnFInterruptFormattingTable`／`19 pfnCalcHorizontalBBoxOfRow`／`20 pfnFormatCellFinite`／
       `21..33 cell 余槽`／`34..44 FSTABLECBKFETCHWORD 11 槽`。
   驱动入口 `TableParagraphId`（`PtsHost.cs:86`）＝ `FloaterParagraphId + 1` ＝ **3**。 */
#define WPF_PTS_TABLE_ID                     3
#define WPF_PTS_TABLEOBJ_SLOTS               45
#define WPF_PTS_TABLEOBJ_IDX_GETTABLEPROPS   0
#define WPF_PTS_TABLEOBJ_IDX_AUTOFITTABLE    1
#define WPF_PTS_TABLEOBJ_IDX_GETFIRSTROW     9
#define WPF_PTS_TABLEOBJ_IDX_GETNEXTROW      10
#define WPF_PTS_TABLEOBJ_IDX_GETROWPROPS     16
#define WPF_PTS_TABLEOBJ_IDX_GETCELLS        17
#define WPF_PTS_TABLEOBJ_IDX_FMTCELLFINITE   20     /* ⏪ T-A56：`FSTABLECBKCELL` 首槽 */
#define WPF_PTS_TABLEOBJ_IDX_SETCELLHEIGHT   25     /* ⏪ T-A56：`FSTABLECBKCELL` 第 6 槽 */
/* ⏪ `T-A56`：`FSTABLECBKCELL`（14 槽）余槽号（逐字照 `Pts.cs:1736-1752`）：
   20 `pfnFormatCellFinite`／21 `pfnFormatCellBottomless`／22 `pfnUpdateBottomlessCell`／
   23 `pfnCompareCells`／24 `pfnClearUpdateInfoInCell`／25 `pfnSetCellHeight`／26 `pfnDestroyCell`／… */
typedef int (*wpf_pts_fn_autofit_table)(const void *pfsclient, const void *pfsparaclient_table,
                                        const void *nmtable, unsigned int fswdir, int dur_available,
                                        int *out_dur_table_width);
typedef int (*wpf_pts_fn_get_first_row)(const void *pfsclient, const void *nmtable,
                                        int *out_found, void **out_row);
typedef int (*wpf_pts_fn_get_next_row)(const void *pfsclient, const void *nmtable, const void *nmrow,
                                       int *out_found, void **out_row);
typedef int (*wpf_pts_fn_get_row_properties)(const void *pfsclient, const void *nmrow,
                                             unsigned int fswdir, void *out_props);
/* ⏪ `T-A56`（表单元内容排版）：`pfnGetCells`／`pfnFormatCellFinite`／`pfnSetCellHeight` 的 C 侧原型
   照 `Pts.cs:2953-2958`／`:2973-2987`／`:3012-3019` 逐参（全指针宽 8；`FSFMTR`＝3×int＝12 B）。 */
typedef int (*wpf_pts_fn_get_cells)(const void *pfsclient, const void *nmrow, int ccells,
                                    void **rgnmcell, int *rgkcellmerge);
typedef int (*wpf_pts_fn_format_cell_finite)(const void *pfsclient, const void *pfsparaclient_table,
                                             const void *pfsbrkcell, const void *nmcell,
                                             const void *pfsftnrejector, int femptyok,
                                             unsigned int fswdirtable, int dvrextraheight, int dvravailable,
                                             void *fsfmtr_out, void **ppfscell, void **pfsbrkcell_out,
                                             int *dvrused);
typedef int (*wpf_pts_fn_set_cell_height)(const void *pfscell, const void *pfsparaclient_table,
                                          const void *pfsbrkcell, const void *nmcell,
                                          int fbrokenhere, unsigned int fswdirtable, int dvractual);
/* `GetTableObjHandlerInfo` 的**只读捕获位**（本侧持有最近一次交出的托管回调表；同 `g_pts_floater_cbk[]` 体例）。 */
static const void *g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_SLOTS];
static int g_pts_tableobj_cbk_ok = 0, g_pts_tableobj_cbk_gap = 0;
/* ── ⏪ `T-A53`：**本侧表模型**（`FSTABLEOBJDETAILS`／`FSTABLEDETAILS`／`FSTABLEROWDESCRIPTION`／
   `FSTABLEROWDETAILS` 的本侧载体）。**零假值**：行来自托管 `pfnGetFirstRow`／`pfnGetNextRow` 的**真返回值**；
   行高由 `pfnGetRowProperties` 的原值派生（放不下 ⇒ 取本侧下界并**具名**）。本侧**不**排单元内容
   （`c_cells` 原样记、行详情一律报 `cCells=0`）⇒ 内容色不在本增量射程（见载体 §边界）。 */
#define WPF_PTS_TBL_MAXROWS 8
#define WPF_PTS_TBL_MAX     8
#define WPF_PTS_TBL_MAXCELLS 8
#define WPF_PTS_TBL_DVR_MIN 200          /* 本侧行高下界（textdpi；具名 `NOINFO=row-height-self-convention`） */
#define WPF_PTS_TBL_MAGIC   0x5754424cu  /* "WTBL" */
/* ⏪ `T-A56`：**单元槽**（`cCells` 的每格）——`nm_cell` 来自托管 `pfnGetCells` 真返回；
   `pfscell` 来自托管 `pfnFormatCellFinite` 真返回（`CellParaClient.Handle`）；`dvr_used` 同趟真返回。
   **零假值**：任一步 `rc≠0` ⇒ 该行 `n_cells=0`（不记、行详情仍报 `cCells=0`）。 */
typedef struct {
    const void *nm_cell;                 /* 托管 `CellParagraph` 句柄（`pfnGetCells` 真返回） */
    const void *pfscell;                 /* 托管 `CellParaClient` 句柄（`pfnFormatCellFinite` 真返回） */
    const void *sub_obj;                 /* `pfnFormatCellFinite` 真造出的**单元内容子页**（本侧对象） */
    int         kcellmerge;              /* `pfnGetCells` 的 `FSTABLEKCELLMERGE` 原值 */
    int         fskupd;                  /* 报给 `FsQueryTableObjCellList` 的更新态（本侧恒 New） */
    int         fmt_rc;                  /* `pfnFormatCellFinite` 的返回码（诊断） */
    int         dvr_used;                /* `pfnFormatCellFinite` 真返回（⚠️ 本侧 `FsCreateSubpageFinite`
                                            恒报 `dvrUsed=lHeight` ⇒ 该值**不是**内容真高，仅诊断用） */
} wpf_pts_tbl_cell;
typedef struct {
    const void *nm_row;                  /* 行段落句柄（托管 `RowParagraph`；取行回调**真返回值**） */
    const void *pfstablerow;             /* 本侧行 token（＝本对象内 `nm_row` 字段地址，承本仓句柄范式） */
    int         dvr_row;                 /* 行高（textdpi；**回退值**——单元台账不可用时用它） */
    int         dvr_above, dvr_below;    /* `FSTABLEROWPROPS` 的 `dvrAboveRow`／`dvrBelowRow` 原值 */
    int         c_cells;                 /* 行内单元数（`pfnGetRowProperties` 原值；本侧**未**排单元时为诊断） */
    int         n_cells;                 /* ⏪ T-A56：**真排出的**单元数（0 ＝ 未排／失败 ⇒ 诚实报 0） */
    wpf_pts_tbl_cell cells[WPF_PTS_TBL_MAXCELLS];
} wpf_pts_tbl_row;
typedef struct {
    unsigned int magic;
    const void  *nm_table;               /* 表段落句柄（托管 `TableParagraph`） */
    const void  *pfstableproper;         /* 本侧表 token（＝本对象内 `nm_table` 字段地址） */
    const void  *table_client;           /* 窗内为表段落现造的 `TableParaClient`（`+176`；保留不回收） */
    int          nrows;
    int          built;
    int          autofit_rc, autofit_width;
    int          autofit_done;           /* ⏪ `T-A53`：是否已在**真客户端**上补调过 `pfnAutofitTable`（每模型一次） */
    int          autofit_rc2, autofit_width2;
    wpf_pts_tbl_row rows[WPF_PTS_TBL_MAXROWS];
} wpf_pts_tbl_model;
static wpf_pts_tbl_model g_pts_tbl[WPF_PTS_TBL_MAX];
static int g_pts_tbl_n = 0;
static int g_pts_tbl_built_c = 0, g_pts_tbl_query_ok = 0, g_pts_tbl_query_gap = 0;
static int g_pts_tbl_drv_calls = 0, g_pts_tbl_drv_rowhit = 0, g_pts_tbl_drv_gap = 0;
/* ⏪ `T-A56`：单元内容排版台账（只读口；`cell_ok` ＝ 真造出 `CellParaClient` 的单元数）。 */
static int g_pts_tbl_cell_rows = 0, g_pts_tbl_cell_ok = 0, g_pts_tbl_cell_gap = 0;

static int g_pts_fscbk_probes   = 0;    /* 本进程内回读次数（仪器自身的调用计数，只读） */
static int g_pts_fscbk_fp_pass  = 0;    /* 指纹 PASS 次数（观测 == 预言） */
static int g_pts_fscbk_fp_fail  = 0;    /* 指纹 FAIL 次数（观测 != 预言） */
static int g_pts_fscbk_fp_synth = 0;    /* 合成结构（全零窗口）次数 —— 夹具结构走这支，**不判 FAIL** */

// ── 只读回读（**绝不试调**）：把 `FSCBK` 的 103 个 8 B 字逐字读出并打印 ＋ 指纹判定 ────────────
//   安全性：窗口 ＝ `info + 40 .. info + 864`。**夹具结构**（`wpf_pts_fsctx_probe`）已按同一窗口
//   **加宽**（见该结构处的 `probe_pad`）⇒ 即使在夹具路径上调用也**全程在界内**（改前那个 56 B 的
//   结构若被回读 864 B 就是**越界读**，本件顺手把它堵掉）。
//   **两支判词**：① 全零窗口 ⇒ `synthetic-all-zero` ⇒ `fingerprint=NOINFO`（夹具的合成结构，
//   不是托管产物，**不许当红也不许当绿**）；② 有非零 ⇒ 与"预言的空槽位置"逐项比对（**预言 vs
//   观测**）⇒ `fingerprint=PASS|FAIL`。观测到**多出的空槽**同样判 FAIL（收紧）。
static void wpf_pts_fscbk_probe(const void *info, const char *where)
{
    if (!info) return;
    const unsigned char *b = (const unsigned char *)info;
    unsigned long long w[WPF_PTS_FSCBK_SIZE / 8];
    int nulls = 0, nonnull = 0, pred_ok = 1;
    for (int i = 0; i < WPF_PTS_FSCBK_SIZE / 8; i++) {
        unsigned long long v = 0;
        for (int k = 0; k < 8; k++) v |= ((unsigned long long)b[WPF_PTS_FSCBK_OFF + i * 8 + k]) << (8 * k);
        w[i] = v;
        if (v) nonnull++; else nulls++;
    }
    g_pts_fscbk_probes++;
    if (nonnull == 0) {                       /* 全零窗口 ⇒ 夹具的合成结构 */
        g_pts_fscbk_fp_synth++;
        fprintf(stderr, "[FSCBK-PROBE] where=%s info=%p shape=synthetic-all-zero nulls=%d nonnull=%d "
                        "fingerprint=NOINFO reason=synthetic-struct\n", where, info, nulls, nonnull);
        return;
    }
    for (int k = 0; k < WPF_PTS_NULL_PRED_CBKOBJ_LEAD; k++) {         /* cbkobj 前三槽应为 0 */
        if (w[(WPF_PTS_FSCBK_CBKOBJ_OFF + k * 8) / 8] != 0) pred_ok = 0;
    }
    for (int k = 0; k < WPF_PTS_NULL_PRED_CBKW_RD; k++) {             /* cbkwrd 全部应为 0 */
        if (w[(WPF_PTS_FSCBK_CBKW_RD_OFF + k * 8) / 8] != 0) pred_ok = 0;
    }
    if (pred_ok && nulls != WPF_PTS_NULL_PRED_TOTAL) pred_ok = 0;     /* 多出的空槽也算不符（收紧） */
    if (pred_ok) g_pts_fscbk_fp_pass++; else g_pts_fscbk_fp_fail++;
    fprintf(stderr, "[FSCBK-PROBE] where=%s info=%p fscbk_off=%d window=%d nulls=%d nonnull=%d "
                    "pred_nulls=%d fingerprint=%s probes=%d pass=%d fail=%d synth=%d\n",
            where, info, WPF_PTS_FSCBK_OFF, WPF_PTS_FSCBK_SIZE, nulls, nonnull,
            WPF_PTS_NULL_PRED_TOTAL, pred_ok ? "PASS" : "FAIL",
            g_pts_fscbk_probes, g_pts_fscbk_fp_pass, g_pts_fscbk_fp_fail, g_pts_fscbk_fp_synth);
    for (int i = 0; i < WPF_PTS_FSCBK_SIZE / 8; i++)
        fprintf(stderr, "[FSCBK-WORD] off=%d val=0x%016llx\n", WPF_PTS_FSCBK_OFF + i * 8, w[i]);
    {   /* 目标槽：绝对值 ＋ 它的 ±8 邻居 —— **两极化**就在这一行里可机读对拍 */
        static const struct { const char *name; int abs; } t[] = {
            { "pfnGetNextSection",      WPF_PTS_FSCBK_OFF + 16  },
            { "pfnGetSectionProperties",WPF_PTS_FSCBK_OFF + 24  },
            { "pfnGetMainTextSegment",  WPF_PTS_FSCBK_OFF + 40  },
            { "pfnGetFirstPara",        WPF_PTS_FSCBK_OFF + 96  },
            { "pfnGetNextPara",         WPF_PTS_FSCBK_OFF + 104 },
            { "pfnGetParaProperties",   WPF_PTS_FSCBK_OFF + 128 },
            { "pfnCreateParaclient",    WPF_PTS_FSCBK_OFF + 136 },
            { "pfnTransferDisplayInfo", WPF_PTS_FSCBK_OFF + 144 },
            { "pfnDestroyParaclient",   WPF_PTS_FSCBK_OFF + 152 },
        };
        for (unsigned k = 0; k < sizeof(t) / sizeof(t[0]); k++) {
            int o = t[k].abs;
            fprintf(stderr, "[FSCBK-SLOT] name=%s abs=%d val=0x%016llx val_m8=0x%016llx val_p8=0x%016llx\n",
                    t[k].name, o, w[o / 8], w[(o - 8) / 8], w[(o + 8) / 8]);
        }
    }
}

// ── ⏪ `t141`（P1-W61）承重前置：`PRECOND-FSCBK-SNAPSHOT-IN-DOC` ──────────────────────────
//   在 `CreateDocContext` 的**调用期内**把 `FSCONTEXTINFO+40..+864`（103 个 8 B 字）**值拷贝**
//   进 doc 对象（`wpf_pts_doc.fscbk_snap`）。为什么必须拷而不能存指针 ⇒ 见顶部常量块的三条理由。
//
//   **为什么必须"响亮失败"**（判据 2）：失败若静默，外部会看到一个"**看起来有表、其实全 0**"的
//   对象 —— 那正是 `t130`／裁定二十三要挡的形态。本件把每条"未快照"路径都写成**具名行**
//   `[FSCBK-SNAP-GAP] rc=… reason=… entry=CreateDocContext …`，并且**不登记对象**
//   （拒绝路径不入册 ⇒ 外部看到的是"**没有这个对象**"，与"已快照但全 0"（`state=ALLZERO`）
//   **判词不同** —— 这就是判据 2 的判别力所在）。
static void wpf_pts_fscbk_snap_gap(const char *reason, const void *info, const void *ctx)
{
    g_pts_fscbk_snap_gap++;
    fprintf(stderr, "[FSCBK-SNAP-GAP] rc=%d reason=%s entry=CreateDocContext info=%p ctx=%p state=NONE\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, info, ctx);
}

static void wpf_pts_fscbk_snapshot(wpf_pts_doc *c, const void *info)
{
    if (!c) return;                       /* 防呆：调用点已保证非空 */
    if (!info) {                          /* 入参形状不合法 ⇒ 响亮失败＋具名留痕，**不登记对象** */
        wpf_pts_fscbk_snap_gap("null-info", info, (const void *)c);
        return;
    }
    /* **值拷贝**（不是存指针）：整段 824 B 逐字节搬进本对象 */
    memcpy(c->fscbk_snap, (const unsigned char *)info + WPF_PTS_FSCBK_OFF, WPF_PTS_FSCBK_SIZE);
    int nz = 0;
    for (int i = 0; i < WPF_PTS_FSCBK_SNAP_WORDS; i++) {
        unsigned long long w = 0;
        for (int k = 0; k < 8; k++) w |= ((unsigned long long)c->fscbk_snap[i * 8 + k]) << (8 * k);
        if (w) nz++;
    }
    c->fscbk_snap_nonzero = nz;
    c->fscbk_snap_state   = (nz == 0) ? WPF_PTS_FSCBK_SNAP_ALLZERO : WPF_PTS_FSCBK_SNAP_VALUE;
    if (nz == 0) g_pts_fscbk_snap_allzero++;
    g_pts_fscbk_snap_taken++;
    {   /* 判据件 §1.3 的"可核证据"：字节数／非零槽数 ＋ `+56`／`+80` 两槽**非零** */
        unsigned long long w56 = 0, w80 = 0;
        for (int k = 0; k < 8; k++) {
            w56 |= ((unsigned long long)c->fscbk_snap[(16 + k)]) << (8 * k);   /* 40+16 = +56 */
            w80 |= ((unsigned long long)c->fscbk_snap[(40 + k)]) << (8 * k);   /* 40+40 = +80 */
        }
        fprintf(stderr, "[FSCBK-SNAP] entry=CreateDocContext ctx=%p info=%p bytes=%d words=%d nonzero=%d "
                        "state=%s slot56=%s slot80=%s taken=%d allzero=%d gap=%d\n",
                (const void *)c, info, WPF_PTS_FSCBK_SIZE, WPF_PTS_FSCBK_SNAP_WORDS, nz,
                (nz == 0) ? "ALLZERO" : "VALUE", w56 ? "nonzero" : "zero", w80 ? "nonzero" : "zero",
                g_pts_fscbk_snap_taken, g_pts_fscbk_snap_allzero, g_pts_fscbk_snap_gap);
    }
}

// ── ⏪ `t146`（P1-W66）**驱动探针本体**：真调 `pfnGetNextSection`(+56)／`pfnGetMainTextSegment`(+80) ──
//   判据件 `P1-drive-probe-criteria.md` §1.3／§2.2／§7(a)：
//     · **调用窗**＝`FsCreatePage*`：那里**同时**有「doc 对象（⇒ 回调表快照）」与「入站 `sect` 句柄」
//       （`PRECOND-CALL-WINDOW` 的结论；`CreateDocContext` 有表无句柄、`FsCreatePage*` 有句柄无表
//       ⇒ 快照把两者接上）。
//     · **`+56` 的形状是 by-design**：上游 `Section.cs:171-177` **恒** `fSuccess=0`／`nmsNext=0`
//       ⇒ 成功形状 ＝ `fserr=0 ∧ fSuccess=0 ∧ nmsNext=0`，判词 `NEXTSECTION-ABSENT(by-design)`；
//       **不得**读成失败（假进度必红 `P5` 就是防这个方向）。它只能当"管道通不通"的对照腿。
//     · **`+80` 是唯一有信息量的那条**：`Section.cs:234-242` 懒创建 `ContainerParagraph` 并返 `.Handle`
//       ⇒ 成功形状 ＝ `fserr=0 ∧ nmSegment≠0`，判词 `MAINTEXTSEG-LIVE-HANDLE`。
//     · `fserr` 值域：`0`＝`fserrNone`（唯一成功）／`-100002`＝`tserrCallbackException`／
//       `-10000`＝`tserrNotImplemented`／**其它一律非成功** ⇒ 非 0 ⇒ `CALLBACK-ERR`，**不许当成功**。
//     · **连调两次必须同值**（幂等）：`+80` 首调懒创建、次调走同一支 ⇒ 同值；`+56` 恒同值。
//     · **零破坏**：主链**只**用**捕获到的真 `sect`**；**绝不**伪造 `nms`/`nmp`（那会让托管
//       `HandleToObject` 触发 **`FailFast` 不可捕获**）。伪句柄反腿**只在应用副本上跑**。
//     · ⚠️ **"非破坏性 ≠ 零副作用"**：`+80` 会**懒创建** `ContainerParagraph` ⇒ 向托管表**新增活条目**；
//       本探针把**窗口预算设为 1**（每进程只探第一个窗口、每槽连调两次）以把副作用与日志都限住。
typedef int (*wpf_pts_fn_get_next_section)(const void *pfsclient, const void *nms_cur, int *f_success, void **nms_next);
typedef int (*wpf_pts_fn_get_main_text_segment)(const void *pfsclient, const void *nms_section, void **nm_segment);

/* 快照里的槽下标（**由窗口起点推出**，并由下面的 `_Static_assert` 钉死）：
     idx = (绝对偏移 − WPF_PTS_FSCBK_OFF) / 8    ⇒  +56 ⇒ 2 ／ +80 ⇒ 5                    */
#define WPF_PTS_SNAP_IDX_GETNEXTSECTION      2
#define WPF_PTS_SNAP_IDX_GETMAINTEXTSEGMENT  5
/* ⏪ `t150`（P1-W70）**调用强度旋钮**：每进程最多探几个窗口（每窗 2 调/槽 ⇒ 每窗 4 次调用）。
   ⏪ `T-A9`（S2）：**缺省由 `1` 提到 `WPF_PTS_DOC_MAX`** —— 缺省路径下每个 doc（≤ 8）
   各需一窗把 `drive_nmp` 落进 doc；配合"每 doc 只驱一次"的记账 ⇒ 缺省 `1` 会让「只有第 1 个
   doc 拿到 `drive_nmp`」而其余 doc 的 `FsQueryTrackParaList` **仍拒**。`WPF_PTS_DRIVE_PROBE_N=<n>`
   可调；上限 = 入站 `FsCreatePage*` 的实际调用次数（日志会给 `budget-exhausted`）。 */
#define WPF_PTS_DRIVE_PROBE_WINDOW_BUDGET_DEFAULT WPF_PTS_DOC_MAX
static int wpf_pts_drive_probe_n(void);   /* 定义见闸函数旁边（读一次并缓存） */
#define WPF_PTS_DRIVE_PROBE_PRINT_SKIP_MAX   3     /* 跳过的具名行最多打几条（其余只计数） */
/* ⚠️ **反腿开关**（默认 0）：置 1 时把 `nms` 换成**伪值 `0x1`** —— 只允许在
   **应用副本**上以 `-DWPF_PTS_DRIVE_PROBE_FAKE_NMS=1` 单独编译，**绝不许**进主链产物。 */
#ifndef WPF_PTS_DRIVE_PROBE_FAKE_NMS
#define WPF_PTS_DRIVE_PROBE_FAKE_NMS 0
#endif
/* ⏪ `T-A17`：驱动探针**第二跳窗外腿**（`+136 pfnGetFirstPara`）前的**句柄 liveness 判据**总闸。
   缺省 `1` ＝判据生效（页销毁语境下**拒驱**）；`-DWPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD=0`
   （**只允许在应用副本上**单独编译）＝判据失效 ⇒ **复现旧序列**（`FsDestroyPage` 用已释放的
   `nms` 调 `+136`）⇒ 必回 `app_rc=134`（不可捕获 `FailFast`）—— 那是**反极性腿**。
   ⚠️ **绝不许**把 `0` 编进主链产物。 */
#ifndef WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD
#define WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD 1
#endif

_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETNEXTSECTION * 8 == 56,
               "快照下标 GETNEXTSECTION 对应的绝对偏移 != +56");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETMAINTEXTSEGMENT * 8 == 80,
               "快照下标 GETMAINTEXTSEGMENT 对应的绝对偏移 != +80");
_Static_assert(sizeof(wpf_pts_fn_get_next_section) == 8 && sizeof(wpf_pts_fn_get_main_text_segment) == 8,
               "回调指针不是 8 B（与快照的 8 B 字假设不符）");

static int          g_pts_dp_calls      = 0;   /* 真正**发出**调用的窗口数 */
static int          g_pts_dp_skips      = 0;   /* 被跳过的窗口数（每条都有具名 reason） */
static const char  *g_pts_dp_last_skip  = "none";
static int          g_pts_dp_56_fserr   = -1, g_pts_dp_56_fsuccess = -1;
static const void  *g_pts_dp_56_next    = NULL;
static int          g_pts_dp_80_fserr   = -1;
static const void  *g_pts_dp_80_segment = NULL;
static int          g_pts_dp_idem       = 0;   /* bit0：+56 两次同值；bit1：+80 两次同值 */
static int          g_pts_dp_gate       = 0;   /* 闸状态（1 开／0 关；**缺省 0**） */

/* ⏪ `t148`（P1-W68）**运行期闸**（裁定三十六 (b)：**缺省关**）──────────────────────────────────
   为什么必须有：`t146` 现取证明 `+80` 会**懒创建** `ContainerParagraph` ⇒ **改渲染**
   （帧 `ef3fd6765f18f51b → b273ebecc332fc03`、`colors 383 → 391`，症状门未变）；若让探针**常开**，
   则"帧变了"这一**纯副作用**会把 `N1` 要件①（帧 ∉ 空态集）**凑成"成立"** ⇒ 与 `N4`「登记即算」
   **同族**的第二个假绿通道（裁定三十六 (c)）。⇒ 缺省**一次都不调**；只有显式
   `WPF_PTS_DRIVE_PROBE=1`（非 `0`、非空）才开。**闸关时的状态必须可见**（`reason=gate-off` 具名行）。
   语义边界：本闸**只**控"是否发起那两条回调调用"；不影响任何其它入口（回读快照／只读口照旧可读）。 */
static int wpf_pts_drive_probe_enabled(void)
{
    static int cached = -1;                      /* −1 未取；0 关；1 开（本进程内取一次） */
    if (cached < 0) {
        const char *v = getenv("WPF_PTS_DRIVE_PROBE");
        /* ⏪ `T-A9`（队长裁定：**撤销**「裁定三十六 (b)」的"运行期闸默认关"）：**缺省开** ——
           仅当 `WPF_PTS_DRIVE_PROBE` **显式**为 `"0"` 时关；未设／空／其它值皆开。
           原由（防帧面副作用／保 `N1`/`N3` 可比）已因 `PRECOND-FRAME-DETERMINISM` 未满足而失效，
           射程仅"缺省路径驱动三级链"。显式 `"0"` 保留为**反极性腿**开关（该红必红）。 */
        cached = (v && strcmp(v, "0") == 0) ? 0 : 1;
    }
    return cached;
}
int WpfLinuxWin32_PtsDriveProbeGate(void) { return wpf_pts_drive_probe_enabled(); }

/* ⏪ `t150`：**调用强度**（窗口预算）—— `WPF_PTS_DRIVE_PROBE_N`，**缺省 1**（与 `t148` 一致）。
   取值口径：非空且能 `strtol` 成 ≥1 ⇒ 用它；否则缺省 1。**负值/0/非数字 ⇒ 缺省 1**（不放宽、不放任）。 */
static int wpf_pts_drive_probe_n(void)
{
    static int cached = -1;
    if (cached < 0) {
        const char *v = getenv("WPF_PTS_DRIVE_PROBE_N");
        long n = (v && v[0]) ? strtol(v, NULL, 10) : 0;
        cached = (n >= 1 && n <= 64) ? (int)n : WPF_PTS_DRIVE_PROBE_WINDOW_BUDGET_DEFAULT;
    }
    return cached;
}
int WpfLinuxWin32_PtsDriveProbeN(void) { return wpf_pts_drive_probe_n(); }

/* ══════════════════════════════════════════════════════════════════════════════════════════════
   ⏪ `t151`（P1-W71）**驱动链第二跳**：`pfnGetFirstPara`(+136) 取 `nmp`（判据件
   `P1-drive-probe2-criteria.md` §1.2／§2／§3／§8.2 逐条执行）
     · **候选唯一**：三条候选里只有 `+136` 是「吃 `nms`、吐 `nmp`＋`out int fSuccessful`」；
       `+144 GetNextPara` 入参含 `nmpCur`（循环依赖）⇒ 排除；`+168 GetParaProperties` 吃 `nmp` 吐
       `FSPAP`（4×int，不产句柄）⇒ 排除，**改用为"下游接受性"判别器**（⚠️ **射程声明**：
       `ContainerParagraph : BaseParagraph, ISegment` ⇒ `+168` **会接受** `ContainerParagraph` ⇒
       它**只证"是 `BaseParagraph` 族"、不证"是 first para"**）。
     · **可达性（三跳闭合，现取）**：`Section.cs:234-242` 第一跳 `+80` 产出的就是
       `new ContainerParagraph(...)`；`ContainerParagraph.cs:19 : BaseParagraph, ISegment`；
       `PtsHost.cs:595 HandleToObject(nms) as ISegment` ⇒ 命中 ⇒ `:596` 的 `ValidateHandle` 不抛。
     · ⚠️ **`-100002` 有两种成因、只看 `rc` 分不开**（判据 §8.2）：(i) 句柄类型不对；
       (ii) **在窗外调用** —— `ContainerParagraph.cs:151` **无条件**读
       `StructuralCache.CurrentFormatContext.IncrementalUpdate`，而该字段**窗外为 `null`**
       （`StructuralCache.cs:678` 进窗置位／`:686` 出窗清空）⇒ NRE 被 `catch` 吞成**同一个 `-100002`**。
       ⇒ 本件做**「窗内 vs 窗外」成对实验**：**正腿**＝入站 hook 内（`FsCreatePage*`，天然在
       `FlowDocumentPage.cs:136/:199` 的 `using(SetDocumentFormatContext)` 里）；
       **反腿**＝`FsDestroyPage`（页**拆除**发生在 `using` 窗口关闭**之后** —— 该归类是**代码结构推断**，
       实验本身即其检验；若反腿也返 `0` ⇒ 如实记"该处仍在窗内或调用本无问题"）。
     ⚠️ `+136` **首次调用会创建**（`ContainerParagraph.cs:142 _firstChild = GetParagraph(...)`），
       第二次走缓存支 ⇒ **连调必须同值**（`idem136`）。
     ⚠️ **T3 模式**（编译期 `WPF_PTS_DRIVE_PROBE2_T3=1`，**只在副本产物**）：把 **真 `sect`**（`Section`
       句柄）当 `nms` 喂 `+136` —— `Section : UnmanagedHandle`（**不是** `ISegment`）⇒ `as ISegment`
       落空 ⇒ 期望 **`-100002` 且可捕获**。**本件不使用任何伪值**（T1/T2 一律 `FailFast`）。
   ══════════════════════════════════════════════════════════════════════════════════════════════ */
#define WPF_PTS_SNAP_IDX_GETFIRSTPARA      12   /* 40 + 12*8 = 136 */
#define WPF_PTS_SNAP_IDX_GETPARAPROPERTIES 16   /* 40 + 16*8 = 168 */
/* ⏪ `T-A12`：`+144 pfnGetNextPara`（帧 B 偏移在册：`_Static_assert(… CBKGEN_OFF + 104 == 144)`）——
   `cParas` 源的**枚举后继**回调（`+136` 取首、`+144` 取后继）。 */
#define WPF_PTS_SNAP_IDX_GETNEXTPARA       13   /* 40 + 13*8 = 144 */
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETFIRSTPARA * 8 == 136, "下标 GETFIRSTPARA 对应绝对偏移 != +136");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETNEXTPARA  * 8 == 144, "下标 GETNEXTPARA 对应绝对偏移 != +144");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETPARAPROPERTIES * 8 == 168, "下标 GETPARAPROPERTIES 对应绝对偏移 != +168");

#ifndef WPF_PTS_DRIVE_PROBE2_T3
#define WPF_PTS_DRIVE_PROBE2_T3 0
#endif

/* ══════════════════════════════════════════════════════════════════════════════════════════════
   ⏪ `t156`（P1-W76）**第三跳**：窗内用**合法 `nmp`** 调 `+176 pfnCreateParaclient` 取
   `pfsparaclient`，再用 `+192 pfnDestroyParaclient` **回收**（判据 `P1-drive-probe3-criteria.md` §2.4 五格）。

   🔴 **本跳不是幂等的**（判据 §1.2 现取托管侧 **10 处覆写**，每一处都是
     `new *ParaClient(this); handle = paraClient.Handle;`）⇒ **正腿口径与前两跳相反**：
     两次调用必须**各自非零且互不相同**（`h1≠h2`）＋**两次都被 `+192` 成功回收**。
     把 `h1≠h2` 读成"非确定性/失败"＝判据 **P8 反过读**（必红）。

   🔴 **T3 在本跳必须换料**（判据 §3）：`nms`／`nmSeg` 都是 `ContainerParagraph : BaseParagraph`
     ⇒ 对 `+176` 的 `as BaseParagraph` 是**对类型** ⇒ 必须换 **真 `sect`**（`Section : UnmanagedHandle`，
     **不是** `BaseParagraph`）当"真错类型 live 句柄"；`+192` 的反腿用 `nmSeg1`（**不是** `BaseParaClient`）。

   🔴 **`+200 FInterruptFormattingAfterPara` 禁用为判别器**（判据 §2.3／P9）：其实现是
     `{ fInterruptFormatting = PTS.False; return PTS.fserrNone; }` 的 **stub**（形参含 client 却**不读**）
     ⇒ 对**任何**值都返 `0` ⇒ **恒定绿**。本件**只**拿它做 **P9 负面对照**（对 `NULL` 与对真句柄
     返**同值** ⇒ 证明它没有判别力）。

   🔴 **`+176` 前的 `*out` 必须显式为 `0` 并留痕**（判据 §4-P3）：`+192` 的 `rc=0` 必须与
     "`*out` **从 `0` 变为非零**"**成对**给出 —— 否则无法把"native 自造值"与"托管产出值"分开。

   ⚠️ **两条不可捕获 `FailFast` 禁忌（主链禁）**：① **`NULL` 句柄绝不喂 `+192`**
     （`HandleToObject` 的 `handleLong>0` 断言）；② **`h2 == h1` 时绝不二次回收**
     （`IsHandle()` 断言）。两条都按判据 §8.3.3 处理：只在**副本**上做破坏性试错。
   ══════════════════════════════════════════════════════════════════════════════════════════════ */
#define WPF_PTS_SNAP_IDX_CREATEPARACLIENT  17   /* 40 + 17*8 = 176 */
#define WPF_PTS_SNAP_IDX_DESTROYPARACLIENT 19   /* 40 + 19*8 = 192 */
#define WPF_PTS_SNAP_IDX_FINTERRUPT        20   /* 40 + 20*8 = 200（**禁用为判别器**，只做 P9 负面对照） */
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_CREATEPARACLIENT  * 8 == 176, "下标 CREATEPARACLIENT 对应绝对偏移 != +176");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_DESTROYPARACLIENT * 8 == 192, "下标 DESTROYPARACLIENT 对应绝对偏移 != +192");
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_FINTERRUPT         * 8 == 200, "下标 FINTERRUPT 对应绝对偏移 != +200");

#ifndef WPF_PTS_DRIVE_PROBE3_T3
#define WPF_PTS_DRIVE_PROBE3_T3 0        /* 只在**副本产物**上开：T3 反腿（真错类型 live 句柄） */
#endif
#ifndef WPF_PTS_DRIVE_PROBE3_CTXDEAD
#define WPF_PTS_DRIVE_PROBE3_CTXDEAD 0   /* 只在**副本产物**上开：context 已销毁后的 `+176` 反腿 */
#endif

typedef int (*wpf_pts_fn_create_paraclient)(const void *pfsclient, const void *nmp, void **out);
typedef int (*wpf_pts_fn_destroy_paraclient)(const void *pfsclient, const void *pfsparaclient);
typedef int (*wpf_pts_fn_finterrupt_after_para)(const void *pfsclient, const void *pfsparaclient,
                                                const void *nmp, int vr, int *f_interrupt);
_Static_assert(sizeof(wpf_pts_fn_create_paraclient) == 8 && sizeof(wpf_pts_fn_destroy_paraclient) == 8
               && sizeof(wpf_pts_fn_finterrupt_after_para) == 8,
               "第三跳回调指针不是 8 B（与快照的 8 B 字假设不符）");

static int          g_pts_dp3_176_a     = -9999;  /* +176 首调 fserr */
static int          g_pts_dp3_176_b     = -9999;  /* +176 次调 fserr */
static const void  *g_pts_dp3_h1        = NULL;   /* 首调产出 */
static const void  *g_pts_dp3_h2        = NULL;   /* 次调产出 */
static const void  *g_pts_dp3_pre_h1    = NULL;   /* **调用前** `*out` 的值（P3 成对证据的一半） */
static int          g_pts_dp3_newperc   = 0;      /* h1,h2 皆非零且互不相同 ⇒ 1 */
static int          g_pts_dp3_192_a     = -9999;  /* +192 首回收 */
static int          g_pts_dp3_192_b     = -9999;  /* +192 次回收 */
static int          g_pts_dp3_192_skip  = 0;      /* 0=都回收了 1=同值不二次回收 2=槽缺失 */
static int          g_pts_dp3_192_t3    = -9999;  /* T3：+192 的**错类型**反腿 */
static int          g_pts_dp3_200_null  = -9999;  /* P9 负面对照：+200 对 NULL */
static int          g_pts_dp3_200_hand  = -9999;  /* P9 负面对照：+200 对真句柄 */
static int          g_pts_dp3_oow_rc    = -9999;  /* 窗外腿 +176 */
static int          g_pts_dp3_oow_rec   = -9999;  /* 窗外腿回收 */
static int          g_pts_dp3_oow_calls = 0;
static int          g_pts_dp3_calls     = 0;
static int          g_pts_dp3_ctx_live  = -1;     /* 同趟现取：该 doc 是否仍在册 */
static unsigned long long g_pts_dp3_t3_value     = 0;  /* T3 喂 +176 的值 */
static unsigned long long g_pts_dp3_t3_192_value = 0;  /* T3 喂 +192 的值 */
static int          g_pts_ctx_alive_n   = 0;      /* 现存活上下文数（**native 侧自记**） */
#if WPF_PTS_DRIVE_PROBE3_CTXDEAD
static const void  *g_pts_dp3_st_nmp    = NULL;
static const void  *g_pts_dp3_st_client = NULL;
static const void  *g_pts_dp3_st_fp176  = NULL;
static const void  *g_pts_dp3_st_fp192  = NULL;
static int          g_pts_ctx_dead_rc   = -9999;
static int          g_pts_ctx_dead_calls= 0;
#endif

int WpfLinuxWin32_PtsDriveProbe3Fserr176A(void) { return g_pts_dp3_176_a; }
int WpfLinuxWin32_PtsDriveProbe3Fserr176B(void) { return g_pts_dp3_176_b; }
void *WpfLinuxWin32_PtsDriveProbe3H1(void)      { return (void *)g_pts_dp3_h1; }
void *WpfLinuxWin32_PtsDriveProbe3H2(void)      { return (void *)g_pts_dp3_h2; }
void *WpfLinuxWin32_PtsDriveProbe3PreOut(void)  { return (void *)g_pts_dp3_pre_h1; }
int WpfLinuxWin32_PtsDriveProbe3NewPerCall(void){ return g_pts_dp3_newperc; }
int WpfLinuxWin32_PtsDriveProbe3Fserr192A(void) { return g_pts_dp3_192_a; }
int WpfLinuxWin32_PtsDriveProbe3Fserr192B(void) { return g_pts_dp3_192_b; }
int WpfLinuxWin32_PtsDriveProbe3Skip192(void)   { return g_pts_dp3_192_skip; }
int WpfLinuxWin32_PtsDriveProbe3Fserr192T3(void){ return g_pts_dp3_192_t3; }
int WpfLinuxWin32_PtsDriveProbe3P200Null(void)  { return g_pts_dp3_200_null; }
int WpfLinuxWin32_PtsDriveProbe3P200Hand(void)  { return g_pts_dp3_200_hand; }
int WpfLinuxWin32_PtsDriveProbe3OowFserr(void)  { return g_pts_dp3_oow_rc; }
int WpfLinuxWin32_PtsDriveProbe3OowRec(void)    { return g_pts_dp3_oow_rec; }
int WpfLinuxWin32_PtsDriveProbe3OowCalls(void)  { return g_pts_dp3_oow_calls; }
int WpfLinuxWin32_PtsDriveProbe3Calls(void)     { return g_pts_dp3_calls; }
int WpfLinuxWin32_PtsDriveProbe3CtxLive(void)   { return g_pts_dp3_ctx_live; }
int WpfLinuxWin32_PtsCtxAliveCount(void)        { return g_pts_ctx_alive_n; }
unsigned long long WpfLinuxWin32_PtsDriveProbe3T3Value(void)    { return g_pts_dp3_t3_value; }
unsigned long long WpfLinuxWin32_PtsDriveProbe3T3Value192(void) { return g_pts_dp3_t3_192_value; }

/* ══════════════════════════════════════════════════════════════════════════════════════════════
   ⏪ `t160`（P1-W80）：把 `pfsparaclient` 接进 `FsQueryTrackParaList` 的**段落列表**。

   🔴 **本跳的四个设计问（判据 `P1-paralist-wire-criteria.md` §2 现取判词，本实现照此）**：
     ① **持有期 ＝ 托管对象生存期**（`BaseParaClient : UnmanagedHandle`；句柄在建对象时由
        `CreateHandle(this)` 产生、在 `Dispose()` 里由 `ReleaseHandle` 回收；native `+192` 即触发者）
        ⇒ **与"哪次调用窗口"无关**，**可以跨调用持有**。
     ② **窗口非必要非充分** ⇒ 必须做**两腿实验**：W-1 用**窗内**探针造出的第一代、
        W-2 用**窗外**腿造出的第一代；**单腿只能记 `NOINFO`**。
     ③ **回收责任＝托管 `Dispose()`，触发点 `+192`** ⇒ **本入口不许自回收、不许"返回前回收"**
        （判 P4）。本实现把回收**推迟到下一次调用**（`fsp_pl_prev`），且**绝不**回收本次要交出去的那一代。
     ④ 🔴 **索引复用 ⇒ 静默错对象**（`IsHandle() = Obj!=NULL && Index==0` ＋ `ReleaseHandle` 把索引
        压回自由链 ＋ `CreateHandle` 复用之）：已释放**未被复用** ⇒ `Assert` ⇒ **不可捕获 `FailFast`**；
        已释放**已被复用** ⇒ `IsHandle()` 为真 ⇒ `HandleToObject` 返回**另一个对象**、`as BaseParaClient`
        **还成功** ⇒ **不报错、不崩**。⇒ `resolve=wrong-object` **一票红**（本件给 ABA 反腿作机制证明）。

   🔴 **`FSPARADESCRIPTION.pfsparaclient` 的偏移**：按上游字段序（`Pts.cs:1500-1510`）＋
     `FSUPDATEINFO`＝8 B ＋ 64 位 `IntPtr`＝8 B ⇒ **计算值 `+16`**（`pfspara @ +8`、`nmp @ +24`、
     `sizeof = 64`）。按 `t127` 前例「计算值只作**预期**、实现件必须给**实测**」：本件给
     ① `offsetof` 镜像结构 ＋ `_Static_assert`（编译期钉死）② **填充前**的**字节级读回**（把该区
     `dump` 成 hex 留痕）③ **消费者行为**（托管侧按它自己的布局读我们填的区：偏移错 ⇒ 读到别的字段
     ⇒ `as BaseParaClient` 落空 ⇒ 消费者侧异常；本次两样本消费者侧零新异常类）。
   ══════════════════════════════════════════════════════════════════════════════════════════════ */
typedef struct { int fskupd; int dvr_shifted; } wpf_pts_fsupdinf;              /* 8 B */
typedef struct { int f_defined; int u, v, du, dv; } wpf_pts_fsbbox_t;          /* 20 B */
typedef struct {                                                                /* 共 64 B */
    wpf_pts_fsupdinf fsupdinf;
    void *pfspara;              /* +8  */
    void *pfsparaclient;        /* +16 ← 本跳要填的字段 */
    void *nmp;                  /* +24 */
    int   idobj;                /* +32 */
    int   dvr_used;             /* +36 */
    wpf_pts_fsbbox_t fsbbox;    /* +40（20 B） */
    int   dvr_top_space;        /* +60 */
} wpf_pts_fsparadesc;
_Static_assert(offsetof(wpf_pts_fsparadesc, pfspara)        ==  8, "FSPARADESCRIPTION.pfspara 偏移 != +8");
_Static_assert(offsetof(wpf_pts_fsparadesc, pfsparaclient)  == 16, "FSPARADESCRIPTION.pfsparaclient 偏移 != +16");
_Static_assert(offsetof(wpf_pts_fsparadesc, nmp)            == 24, "FSPARADESCRIPTION.nmp 偏移 != +24");
_Static_assert(sizeof(wpf_pts_fsparadesc)                   == 64, "sizeof(FSPARADESCRIPTION) != 64");
_Static_assert(sizeof(wpf_pts_fsupdinf) == 8, "FSUPDATEINFO != 8 B");
_Static_assert(sizeof(wpf_pts_fsbbox_t) == 20, "FSBBOX != 20 B");

#ifndef WPF_PTS_FSP_PL_ENGINE_DRIVE
/* ⏪ `t165`（P1-W85）**E2 副本专用驱动格**：缺省 **0** ⇒ 本块**不进主链产物一个字节**
   （因此主链 `.so` 与 `exports.txt` 的 sha16 **逐字节不变** ⇒ 这是"副本专用"的成对证据）。 */
#define WPF_PTS_FSP_PL_ENGINE_DRIVE 0
#endif
#ifndef WPF_PTS_FSP_PL_EDRIVE_BADNULL
#define WPF_PTS_FSP_PL_EDRIVE_BADNULL 0    /* 反腿①：给 NULL（族 N） */
#endif
#ifndef WPF_PTS_FSP_PL_EDRIVE_BADSTACK
#define WPF_PTS_FSP_PL_EDRIVE_BADSTACK 0   /* 反腿②：给栈地址（族 X，"看似真实则伪"） */
#endif
#ifndef WPF_PTS_FSP_PL_SELFRECYCLE
#define WPF_PTS_FSP_PL_SELFRECYCLE 0   /* 只在**副本产物**上开：**P4 反腿**（本入口"返回前回收"） */
#endif
#ifndef WPF_PTS_FSP_PL_ABA
#define WPF_PTS_FSP_PL_ABA 0           /* 只在**副本产物**上开：**resolve=wrong-object 机制证明** */
#endif

static int          g_pts_fsp_pl_fills        = 0;   /* 真填次数（rc=0 且 n=cParas） */
#if WPF_PTS_FSP_PL_LMWIT
static int g_pts_lmwit_dvr_used = -1, g_pts_lmwit_dvr_top = -1;   /* ⏪ t194：算术部分的两操作数 */
#endif
static int          g_pts_fsp_pl_consumes     = 0;   /* 延迟回收（`+192`）次数 ⇒ 也＝"消费解析"次数 */
static int          g_pts_fsp_pl_resolve_ok   = 0;   /* `+192` 返 0（解析成 `BaseParaClient`） */
static int          g_pts_fsp_pl_resolve_wrong= 0;   /* **一票红**：解析到的**不是**当初那个对象 */
static int          g_pts_fsp_pl_resolve_exc  = 0;   /* `+192` 返 `-100002`（解析成别的族） */
static int          g_pts_fsp_pl_src_in       = 0;   /* 第一代来源＝窗内探针的次数（1/0） */
static int          g_pts_fsp_pl_src_out      = 0;   /* 第一代来源＝窗外腿的次数（1/0） */
static int          g_pts_fsp_pl_teardown_rc  = -9999;
static const void  *g_pts_fsp_pl_last_h       = NULL;/* 最近一次填进列表的句柄 */
static int          g_pts_fsp_pl_last_rc176   = -9999;
static int          g_pts_fsp_pl_held_at_exit = 0;   /* 进程退出时仍持有（＝对象存活口径的预期态） */

int WpfLinuxWin32_PtsFsParaListFills(void)      { return g_pts_fsp_pl_fills; }
int WpfLinuxWin32_PtsFsParaListConsumes(void)   { return g_pts_fsp_pl_consumes; }
int WpfLinuxWin32_PtsFsParaListResolveOk(void)  { return g_pts_fsp_pl_resolve_ok; }
int WpfLinuxWin32_PtsFsParaListResolveWrong(void){ return g_pts_fsp_pl_resolve_wrong; }
int WpfLinuxWin32_PtsFsParaListResolveExc(void) { return g_pts_fsp_pl_resolve_exc; }
int WpfLinuxWin32_PtsFsParaListSrcIn(void)      { return g_pts_fsp_pl_src_in; }
int WpfLinuxWin32_PtsFsParaListSrcOut(void)     { return g_pts_fsp_pl_src_out; }
int WpfLinuxWin32_PtsFsParaListTeardownRc(void) { return g_pts_fsp_pl_teardown_rc; }
void *WpfLinuxWin32_PtsFsParaListLastH(void)    { return (void *)g_pts_fsp_pl_last_h; }
int WpfLinuxWin32_PtsFsParaListLastRc176(void)  { return g_pts_fsp_pl_last_rc176; }
int WpfLinuxWin32_PtsFsParaListHeldAtExit(void) { return g_pts_fsp_pl_held_at_exit; }

/* ⏪ `t162`：`pfspara` 的台账/接受面（逐 doc 记在 `wpf_pts_doc`，这里给**全局聚合**读数口）。 */
static int          g_pts_fsp_pl_para_claims   = 0;
static int          g_pts_fsp_pl_para_rejected = 0;
static int          g_pts_fsp_pl_para_acc_ok   = 0;
static int          g_pts_fsp_pl_para_acc_bad  = 0;
static int          g_pts_fsp_pl_para_hold_ok  = 0;
static int          g_pts_fsp_pl_para_released = 0;
static const void  *g_pts_fsp_pl_para_last     = NULL;
static const char  *g_pts_fsp_pl_para_last_src = "none";

int WpfLinuxWin32_PtsFsParaListParaClaims(void)   { return g_pts_fsp_pl_para_claims; }
int WpfLinuxWin32_PtsFsParaListParaRejected(void) { return g_pts_fsp_pl_para_rejected; }
int WpfLinuxWin32_PtsFsParaListParaAccOk(void)    { return g_pts_fsp_pl_para_acc_ok; }
int WpfLinuxWin32_PtsFsParaListParaAccBad(void)   { return g_pts_fsp_pl_para_acc_bad; }
int WpfLinuxWin32_PtsFsParaListParaHoldOk(void)   { return g_pts_fsp_pl_para_hold_ok; }
int WpfLinuxWin32_PtsFsParaListParaReleased(void) { return g_pts_fsp_pl_para_released; }
void *WpfLinuxWin32_PtsFsParaListParaLast(void)   { return (void *)g_pts_fsp_pl_para_last; }
const char *WpfLinuxWin32_PtsFsParaListParaLastSrc(void) { return g_pts_fsp_pl_para_last_src; }

/* ── ⏪ `t162`（P1-W82 · (a)）：**本侧自有的"子轨对象"** ────────────────────────────────────────
   🎯 靶心（队长 `t163` 指引 + 判据 §4(a)）：`FSPARADESCRIPTION.pfspara` **语义上就是子轨对象**
      （`FsFormatSubtrackFinite` 的该出参在声明里叫 `ppfsSubtrack`，`Pts.cs:3318/:3337`），
      而判据 §4(a) 明写「**native 必须自己拥有/分配一个对象**，把它填进 `+8`」。
   ⇒ 本件按**本仓已落地的同形范式**（`FsQueryTrackDetails` ＋ `wpf_pts_fsp.c_paras`：**轨句柄＝
      本对象内该字段的地址**、按对象记账、指针值比较不 deref）给 `pfspara` 一个**本侧自有对象**：
        · **台账**：`g_pts_sub_live[]` ＋ `seq`（实例唯一）＋ `created/destroyed` 计数
        · **持有期**：对象在册即有效（**托管对象生存期**口径的 native 对偶：本侧对象的生存期）
        · **销毁口径**：**只有本侧**销毁它（`wpf_pts_sub_destroy`，接在 `DestroyDocContext` 上）；
          **窗口内绝不销毁**、**填进列表后不销毁**（与 `t158` §2.3 同纪律）
        · **身份可认领**：句柄＝`&obj->c_paras`，认领＝**指针等值于某在册对象的该字段地址**
          （⇒ 判据 §5.4「只许靠来源证据」在本侧有了**可判**的形态：NULL／栈地址／外来值**必被拒**）
   ⚠️ `formatted` **今天恒 0**：本对象**未被造型** ⇒ **`c_paras` 不是"0 个孩子"的断言**，
      而是"**尚未造型**"；⇒ (b) 必须读 `formatted` 而**不得**据 `c_paras==0` 走叶子分支（判据 §5.2 的 P8 防线）。 */
/* ⏪ `T-A28`：每段行记录上界（有界 ⇒ 撞界即 `fl_truncated=1` 并**拒绝回查**，绝不静默截断）。 */
#define WPF_PTS_FL_MAXLINE 32
/* ⏪ `T-A36`：每段**附属对象**（`Figure`/`Floater`）台账上界（有界 ⇒ 撞界即停止记账并具名留痕）。 */
#define WPF_PTS_FL_ATT_MAX 8
/* ⏪ `T-A28`：窗内被驱的段数上界（每窗最多驱这么多 `TextParagraph`；防异常调用失控）。 */
#define WPF_PTS_FL_MAX_PARA 8
struct wpf_pts_subtrack_s {
    unsigned int magic;
    int          c_paras;       /* 子轨段落数（(b) 要答的那个数；**未造型时无意义**） */
    int          formatted;     /* 是否已被造型（**今天恒 0**） */
    const void  *nmp;           /* 来源段落句柄（**本 run** 由托管 `+136` 产出） */
    const void  *pfsparaclient; /* 配对的客户端句柄 */
    int          seq;           /* 台账序号（实例唯一） */
    int          live;
    /* ── ⏪ `T-A12`：**枚举出的子段**（`cParas` 的源快照；只在 `enum_ok==1` 时有效）───────────
       · `children[]` ＝ `+136`／`+144` 在**窗内**枚举出的子段句柄序（原样存，不 deref）
       · `child_clients[]` ＝ `FsQuerySubtrackParaList` 为每个子段现造的客户端句柄（托管 `+176` 产出）
       · `child_clients_made` ＝ 已造客户端条数（**只增不重置**；跨调用复用以避免重复造／泄漏） */
    int          enum_ok;
    const void  *children[WPF_PTS_SUB_CHILD_MAX];
    const void  *child_clients[WPF_PTS_SUB_CHILD_MAX];
    int          child_clients_made;
    /* ── ⏪ `T-A25`（本增量）：**本对象的每个子段各自的本侧对象** ──────────────────────────────
       `child_objs[j]` 与 `children[j]` 一一对应：`FsQuerySubtrackParaList` 交回 `pfspara` 时
       填的就是 `wpf_pts_sub_handle(child_objs[j])`（**本侧自有对象的字段地址**）⇒ 托管回问
       `FsQuerySubtrackDetails`／`FsQueryTextDetails` 时可按**对象身份**认领。`NULL` ＝ 未建成。 */
    struct wpf_pts_subtrack_s *child_objs[WPF_PTS_SUB_CHILD_MAX];
    int          depth;                 /* 本对象在窗内建树里的深度（0＝`dp->sub` 的顶层容器） */
    int          obj_no;                /* 台账序号（诊断用；与 `seq` 同源） */
    /* ── ⏪ `T-A28`（本增量）：**native 侧驱动的行记录台账**（`pfnFormatLine` 的返回值) ──────────
       · 只在**窗内**（`FsCreatePage*` ⇒ `wpf_pts_formatline_drive`）真调 `pfnFormatLine` 后写入；
         一行一条，序＝行序；`fl_nlines` ＝ 已入账行数（**不用伪值填**）。
       · `fl_ok` **仅当**：至少一行 ∧ 末行由 `fsflrEndOfParagraph*` 收束（`fl_complete=1`，即
         "**几何上确实排到段尾**"）∧ 行数未撞上界；否则 `fl_ok=0` ⇒ **回查必须拒**（零假值）。
       · 持有期＝本对象在册期（与 `sub` 的销毁口径同）：`DestroyDocContext` 一并回收。 */
    int          fl_calls;              /* 本对象上真发起的 `pfnFormatLine` 调用数 */
    int          fl_last_rc;            /* 末次 `fserr`（-9999 = 未调） */
    int          fl_nlines;             /* 已入账行数 */
    int          fl_dcp_sum;            /* Σ `dcpLine`（账守恒的**被加数**） */
    int          fl_ok;                 /* 1 ＝ 行记录可用（可回查）；0 ＝ 无源／不完整 */
    int          fl_complete;           /* 1 ＝ 末行收束于段尾（`fsflrEndOfParagraph*`） */
    int          fl_truncated;          /* 1 ＝ 撞行数上界而停（⇒ **不许回查**） */
    int          fl_paraclient_rc;      /* 本对象上 `+176` 建客户端的 fserr */
    const char  *fl_geo_src;            /* 几何来源 token（本侧页几何约定 ⇒ 具名 `NOINFO`） */
    struct {
        int dcp_first, dcp_lim, dvr_ascent, dvr_descent, ur_bbox, dur_bbox;
        int fsflres, f_forced;
        const void *pfsline;     /* `pfnFormatLine` 交回的行句柄（`lineHandle`，真返回值） */
        /* ⏪ `T-A33`：**回填所需的断行记录**（`LineBreakRecord` 真句柄，非伪造）——
           `pbr_in` ＝ 造型本行时**传入**的 `pbrlineIn`（第 0 行为 NULL）；托管消费者
           （`TextParaClient.RenderSimpleLines`）把 `FSLINEDESCRIPTIONSINGLE.pfsbreakreclineclient`
           原样送进 `TextParagraph.FormatLineCore` ⇒ 必须是**同一趟真产出的断行记录**，否则
           `PtsContext.HandleToObject` 取不到 ⇒ `PtsException`。`pbr_out` ＝ 本行**产出**的
           `ppbrlineOut`（已随台账接管；**不**调 `DestroyLineBreakRecord` ⇒ 句柄保持有效）。 */
        const void *pbr_in;
        const void *pbr_out;
    } fl_line[WPF_PTS_FL_MAXLINE];
    /* ── ⏪ `T-A36`（`NATIVE-PTS-ATTACHED-OBJECTS-BACKFILL`）：**附属对象台账**（`Figure`/`Floater`）
       内容**只**来自 `pfnGetNumberAttachedObjectsInTextLine`（计数）＋ `pfnGetAttachedObjectsInTextLine`
       （对象名／`idobj`／锚点）的**真返回值**；`obj_client` 由**窗内** `+176 pfnCreateParaclient`
       为附属对象段落现造（`T-A33`（丙）的窗内纪律）。**零假值**：`rc≠0` ⇒ 该行不记账。 */
    int          fl_att_n;              /* 本段附属对象条数（Σ 各行；**只装真值**） */
    int          fl_att_calls;          /* 本段发起附属对象查询（`num`）的次数 */
    int          fl_att_gap;            /* 附属对象查询失败（`num` 或 `objects` 返非 0）次数 */
    int          fl_att_capped;         /* 撞 `WPF_PTS_FL_ATT_MAX` 上界的次数（失败必留痕） */
    const void  *owner_doc;             /* ⏪ `T-A36`：本对象被**驱**时的 doc（消歧：同一逻辑段落
                                           可有两代对象，附属对象托管句柄**相同** ⇒ 按 doc 归属消歧） */
    /* ── ⏪ `T-A37`：本对象是否属**附属对象内容子页**树（几何取子页的声明值，而非顶层页约定）── */
    int          in_subpage;
    int          sp_du, sp_dv;
    struct {
        const void *nmp_obj;            /* 附属对象段落句柄（托管 `FigureParagraph`/`FloaterParagraph`） */
        const void *obj_client;         /* 为其在**窗内**现造的 `FigureParaClient`/`FloaterParaClient`（`+176`） */
        int         obj_rc;             /* `+176` 的 fserr（0 ＝ 真造出；`-7777` ＝ 闸外拒发） */
        int         idobj;              /* `fsidobjFigure(-2)` 或 `FloaterParagraphId`（**回调原值**） */
        int         dcp_anchor;         /* 锚点 dcp（**回调原值**） */
        int         line_idx;           /* 所属行 index（诊断用） */
        /* ── ⏪ `T-A37`：**附属对象内容排版**的窗内结果（Figure 支）──────────────────────────
           `content_rc` ＝ 内容排版回调（`pfnGetFigureProperties`，`+608`）的 fserr；
           `subpage` ＝ 该回调内 `FsCreateSubpageFinite` 真造出的子页句柄（NULL ＝ 未造出）。 */
        int         content_rc;
        struct wpf_pts_subpage_s *sub_obj;   /* 子页对象（native 侧，按身份认领用） */
    } fl_att[WPF_PTS_FL_ATT_MAX];
};
#define WPF_PTS_SUB_MAGIC 0x57535054u     /* "WSPT" */
/* ⏪ `T-A25`：台账上限（窗内建树 ⇒ 一个容器对象 ＋ 每子段一个对象，**递归**）
   ⇒ 从 16 提到 512（每对象约 0.8 KiB ⇒ 满表约 400 KiB）。表满 ⇒ `wpf_pts_sub_new` 返 NULL
   ⇒ 调用方**拒绝交回**（具名 `no-child-object`），**绝不**退回托管句柄。 */
#define WPF_PTS_SUB_MAX   512
/* ⏪ `T-A25`：窗内递归枚举的**深度上界**（防失控；到界即**不再往下建对象**并具名计数）。 */
#define WPF_PTS_SUB_MAX_DEPTH 8
static wpf_pts_subtrack *g_pts_sub_live[WPF_PTS_SUB_MAX];
static int g_pts_sub_live_n    = 0;
static int g_pts_sub_created   = 0;
static int g_pts_sub_destroyed = 0;
static int g_pts_sub_seq       = 0;
static int g_pts_sub_claim_ok  = 0;
static int g_pts_sub_claim_bad = 0;
/* ⏪ `t172`：台账**可读状态位**（红榜 `P8`：区分「真的 0 个活条目」与「没有读数」）。
   0 = 未初始化（端口一律返 **-1**，**绝不返 0**）；1 = 可读（端口返台账真值）。 */
static int g_pts_hc_reading      = 0;
static int g_pts_sub_selftest_mask = -1;

static wpf_pts_subtrack *wpf_pts_sub_new(const void *nmp, const void *client)
{
    if (g_pts_sub_live_n >= WPF_PTS_SUB_MAX) return NULL;
    wpf_pts_subtrack *o = (wpf_pts_subtrack *)calloc(1, sizeof(*o));
    if (!o) return NULL;
    o->magic = WPF_PTS_SUB_MAGIC; o->c_paras = 0; o->formatted = 0;
    o->nmp = nmp; o->pfsparaclient = client; o->seq = ++g_pts_sub_seq; o->live = 1;
    o->obj_no = g_pts_sub_created + 1;
    g_pts_sub_live[g_pts_sub_live_n++] = o;
    g_pts_sub_created++;
    g_pts_hc_reading = 1;          /* ⏪ t172：台账一建即可读（此后再无"没取到"） */
    return o;
}
/* ⏪ `T-A25`：销毁口径扩为**整棵树**（先递归销毁子对象，再销毁自己）。
   🔴 为什么必须递归：子对象是父对象**拥有**的（`child_objs[]`），父对象一没，子孙就再也无人回收
      ⇒ 若不递归，注销后仍留在 `g_pts_sub_live[]` 里，是**活条目泄漏**（台账读数失真）。 */
static void wpf_pts_sub_destroy(wpf_pts_subtrack *o)
{
    if (!o || o->magic != WPF_PTS_SUB_MAGIC) return;
    for (int k = 0; k < WPF_PTS_SUB_CHILD_MAX; k++) {
        if (o->child_objs[k]) { wpf_pts_sub_destroy(o->child_objs[k]); o->child_objs[k] = NULL; }
    }
    for (int i = 0; i < g_pts_sub_live_n; i++) {
        if (g_pts_sub_live[i] != o) continue;
        g_pts_sub_live[i] = g_pts_sub_live[--g_pts_sub_live_n];
        g_pts_sub_live[g_pts_sub_live_n] = NULL;
        o->magic = 0; o->live = 0;
        free(o); g_pts_sub_destroyed++;
        return;
    }
}
static const void *wpf_pts_sub_handle(const wpf_pts_subtrack *o)
{
    return o ? (const void *)&o->c_paras : NULL;      /* **句柄＝本对象内该字段的地址**（承范式） */
}
/* 身份认领：`p` 必须**等值于**某个在册对象的字段地址；NULL／栈地址／外来值一律拒（判据 §5.4）。 */
static int wpf_pts_sub_claim(const void *p, wpf_pts_subtrack **out)
{
    if (out) *out = NULL;
    if (!p) { g_pts_sub_claim_bad++; return 0; }
    for (int i = 0; i < g_pts_sub_live_n; i++) {
        wpf_pts_subtrack *o = g_pts_sub_live[i];
        if (o->magic != WPF_PTS_SUB_MAGIC) continue;
        if ((const void *)&o->c_paras == p) { if (out) *out = o; g_pts_sub_claim_ok++; return 1; }
    }
    g_pts_sub_claim_bad++;
    return 0;
}
/* ── ⏪ `T-A37`（`NATIVE-PTS-ATTACHED-CONTENT-LAYOUT`）：**PTS 子页对象**（附属对象内容排版的落点） ────
   `Figure`/`Floater` 的**内容**由托管在"附属对象内容排版"回调里**现造**：该回调（`FigureParagraph.
   GetFigureProperties`／`FloaterParagraph.FormatFloaterContentFinite`）**无条件** `PTS.Validate(
   PTS.FsCreateSubpageFinite(...))`（`Pts.cs:3169`）⇒ 本侧必须提供该 native 入口，并把它交回的
   `pSubPage` 句柄与**内容轨**接上（否则托管侧 `SubpageHandle` 恒 0 ⇒ 内容不绘）。
   本对象即那条链的 native 侧载体（**零假值**：只有在窗内**真枚举**出内容段并**真造**出客户端才算成立）。 */
#define WPF_PTS_SP_MAGIC 0x57535031u   /* "WSP1" */
#define WPF_PTS_SP_MAX   64
struct wpf_pts_subpage_s {
    unsigned int magic;
    const void  *ctx;
    const void  *nseg;            /* 内容段句柄（托管交回的 `nSeg`，原样存、不 deref） */
    int          c_paras;         /* 子页**单轨**的段数（0/1）—— **句柄** ＝ 本字段的地址 */
    int          brk;             /* 断页记录句柄字段（交出地址用；本侧**不**产生记录 ⇒ 托管的销毁发调不发生） */
    int          dvr_used;
    int          fsrc_u, fsrc_v, fsrc_du, fsrc_dv;
    const void  *cont_client;     /* 窗内为 `nseg`（内容容器段）造的客户端（`+176` 真返回） */
    wpf_pts_subtrack *cont_obj;   /* `nseg` 的本侧子轨对象（内容树的根；子段序窗内枚举） */
    int          live, seq;
};
static struct wpf_pts_subpage_s *g_pts_sp_live[WPF_PTS_SP_MAX];
static int g_pts_sp_live_n = 0, g_pts_sp_created = 0, g_pts_sp_seq = 0;
static int g_pts_sp_ok = 0, g_pts_sp_gap = 0;          /* `FsCreateSubpageFinite` 成败面 */
static int g_pts_spquery_ok = 0;                       /* `FsQuerySubpageDetails` 子页支成功次数 */
static int g_pts_sptrack_ok = 0, g_pts_sptrack_gap = 0;/* `FsQueryTrackParaList` 子页轨支成败 */
/* ⏪ `T-A56`：`FsClearUpdateInfoInSubpage` 成败面（`CellParaClient.Arrange` 必调）。 */
static int g_pts_sp_clrupd_ok = 0, g_pts_sp_clrupd_gap = 0;

static struct wpf_pts_subpage_s *wpf_pts_sp_new(const void *ctx, const void *nseg)
{
    if (g_pts_sp_live_n >= WPF_PTS_SP_MAX) return NULL;
    struct wpf_pts_subpage_s *s = (struct wpf_pts_subpage_s *)calloc(1, sizeof(*s));
    if (!s) return NULL;
    s->magic = WPF_PTS_SP_MAGIC; s->ctx = ctx; s->nseg = nseg;
    s->seq = ++g_pts_sp_seq; s->live = 1;
    g_pts_sp_live[g_pts_sp_live_n++] = s;
    g_pts_sp_created++;
    return s;
}
static const void *wpf_pts_sp_handle(const struct wpf_pts_subpage_s *s)
{
    return s ? (const void *)&s->c_paras : NULL;      /* **句柄 ＝ 本对象内该字段的地址**（承范式） */
}
static int wpf_pts_sp_claim_track(const void *p, struct wpf_pts_subpage_s **out)
{
    if (out) *out = NULL;
    if (!p) return 0;
    for (int i = 0; i < g_pts_sp_live_n; i++) {
        if (g_pts_sp_live[i]->magic != WPF_PTS_SP_MAGIC) continue;
        if ((const void *)&g_pts_sp_live[i]->c_paras == p) { if (out) *out = g_pts_sp_live[i]; return 1; }
    }
    return 0;
}
static void wpf_pts_sp_destroy(struct wpf_pts_subpage_s *s)
{
    if (!s || s->magic != WPF_PTS_SP_MAGIC) return;
    for (int i = 0; i < g_pts_sp_live_n; i++) {
        if (g_pts_sp_live[i] != s) continue;
        g_pts_sp_live[i] = g_pts_sp_live[--g_pts_sp_live_n];
        g_pts_sp_live[g_pts_sp_live_n] = NULL;
        s->magic = 0; s->live = 0;
        if (s->cont_obj) { wpf_pts_sub_destroy(s->cont_obj); s->cont_obj = NULL; }
        free(s);
        return;
    }
}
/* ⏪ `T-A37`：把"内容子页树"标到整棵子树上（几何取子页声明值 —— `ContainerParaClient.cs:61` 等
   位置把 `fsrc` 当排版矩形用；顶层页的 `768x576` 约定在子页里不成立）。 */
static void wpf_pts_sub_mark_subpage(wpf_pts_subtrack *o, int du, int dv)
{
    if (!o || o->magic != WPF_PTS_SUB_MAGIC) return;
    o->in_subpage = 1; o->sp_du = du; o->sp_dv = dv;
    for (int k = 0; k < WPF_PTS_SUB_CHILD_MAX; k++)
        if (o->child_objs[k]) wpf_pts_sub_mark_subpage(o->child_objs[k], du, dv);
}
/* 台账/身份/销毁口径的**自检**（纯 native；只用自己的对象，不碰应用状态）：
   bit0 新建后可认领 ｜ bit1 NULL 被拒 ｜ bit2 栈地址被拒 ｜ bit3 销毁后不可认领 ｜ bit4 在册数复原 */
/* ⏪ `t172`：聚合计敷口的前向声明（定义在下方端口区；自检要用它们**读台账**） */
int WpfLinuxWin32_PtsHandleLiveCount(void);
int WpfLinuxWin32_PtsHandleCreatedCount(void);
int WpfLinuxWin32_PtsHandleDestroyedCount(void);
int WpfLinuxWin32_PtsHandleReadingState(void);

static int wpf_pts_sub_selftest(void)
{
    int mask = 0;
    /* ⏪ `t172`：**两腿成对夹具**（红榜 `P8`／`P10`）—— 先给"未初始化/没读到"的读数，再给两腿。 */
    fprintf(stderr, "[HCOUNTLEDGER] read#0 state=%s live=%d created=%d destroyed=%d "
                    "v=NO-READING-DISTINCT-FROM-ZERO（未初始化 ⇒ 端口返 -1，**不打成 0**）\n",
            g_pts_hc_reading ? "READING" : "NO-READING",
            g_pts_hc_reading ? g_pts_sub_live_n : -1,
            g_pts_hc_reading ? g_pts_sub_created : -1,
            g_pts_hc_reading ? g_pts_sub_destroyed : -1);
    const int live0 = g_pts_sub_live_n;
    wpf_pts_subtrack *o = wpf_pts_sub_new((const void *)0x3, (const void *)0x5);
    if (!o) return 0;
    wpf_pts_subtrack *got = NULL;
    if (wpf_pts_sub_claim(wpf_pts_sub_handle(o), &got) && got == o) mask |= 1;
    if (!wpf_pts_sub_claim(NULL, NULL))                          mask |= 2;
    int stack_local = 0;
    if (!wpf_pts_sub_claim((const void *)&stack_local, NULL))    mask |= 4;
    wpf_pts_sub_destroy(o);
    if (!wpf_pts_sub_claim(wpf_pts_sub_handle(o), NULL))         mask |= 8;
    if (g_pts_sub_live_n == live0)                               mask |= 16;
    /* ── ⏪ `t172` 两腿成对读数（**只读台账**，与任何 `rc` 无关） ─────────────────────────── */
    {
        const int N = 3;
        /* 腿 A：**只建不回收** */
        const int lA0 = WpfLinuxWin32_PtsHandleLiveCount(), cA0 = WpfLinuxWin32_PtsHandleCreatedCount(),
                  dA0 = WpfLinuxWin32_PtsHandleDestroyedCount();
        wpf_pts_subtrack *keep[8];
        for (int i = 0; i < N; i++) keep[i] = wpf_pts_sub_new((const void *)0x3, (const void *)0x5);
        const int lA1 = WpfLinuxWin32_PtsHandleLiveCount(), cA1 = WpfLinuxWin32_PtsHandleCreatedCount(),
                  dA1 = WpfLinuxWin32_PtsHandleDestroyedCount();
        fprintf(stderr, "[HCOUNTLEDGER] leg=A_only-create n=%d live_before=%d live_after=%d "
                        "delta=%d created_before=%d created_after=%d destroyed=%d "
                        "eq_live_eq_created_minus_destroyed=%d state=%s v=%s\n",
                N, lA0, lA1, lA1 - lA0, cA0, cA1, dA1,
                (lA1 == cA1 - dA1) ? 1 : 0, g_pts_hc_reading ? "READING" : "NO-READING",
                (lA1 - lA0 == N) ? "COUNTS-UP" : "NOT-COUNTING");
        /* 腿 B：**建后回收**（同样的 N 条，全部销毁） */
        for (int i = 0; i < N; i++) if (keep[i]) wpf_pts_sub_destroy(keep[i]);
        const int lB1 = WpfLinuxWin32_PtsHandleLiveCount(), cB1 = WpfLinuxWin32_PtsHandleCreatedCount(),
                  dB1 = WpfLinuxWin32_PtsHandleDestroyedCount();
        fprintf(stderr, "[HCOUNTLEDGER] leg=B_create+destroy n=%d live_before=%d live_after=%d "
                        "delta=%d created_after=%d destroyed_after=%d "
                        "eq_live_eq_created_minus_destroyed=%d state=%s v=%s\n",
                N, lA1, lB1, lB1 - lA1, cB1, dB1,
                (lB1 == cB1 - dB1) ? 1 : 0, g_pts_hc_reading ? "READING" : "NO-READING",
                (lB1 == lA0) ? "RETURNS-TO-BASE" : "DOES-NOT-RETURN");
        fprintf(stderr, "[HCOUNTLEDGER] pair=distinct live_A_after=%d live_B_after=%d distinct=%d "
                        "v=%s（两腿读数**必须不同**，否则＝报常量）\n",
                lA1, lB1, (lA1 != lB1) ? 1 : 0,
                (lA1 != lB1 && lA1 - lA0 == N && lB1 == lA0) ? "PAIR-DISTINCT-AND-SELF-CONSISTENT"
                                                             : "PAIR-FAILED");
    }
    return mask;
}

int WpfLinuxWin32_PtsSubLive(void)        { return g_pts_hc_reading ? g_pts_sub_live_n : -1; }
int WpfLinuxWin32_PtsSubCreated(void)     { return g_pts_hc_reading ? g_pts_sub_created : -1; }
int WpfLinuxWin32_PtsSubDestroyed(void)   { return g_pts_hc_reading ? g_pts_sub_destroyed : -1; }
/* ⏪ `t172`：**聚合只读计数口**（后续件复用的形态）：活条目数／累计创建／累计销毁／可读状态。
   🔴 三者都**只读台账本体**，**不由任何 `rc` 推出**；未初始化时返 **-1**（`state=NO-READING`）⇒
   红榜 `P8`：**"没取到"绝不打成 0**。 */
int WpfLinuxWin32_PtsHandleLiveCount(void)      { return g_pts_hc_reading ? g_pts_sub_live_n : -1; }
int WpfLinuxWin32_PtsHandleCreatedCount(void)   { return g_pts_hc_reading ? g_pts_sub_created : -1; }
int WpfLinuxWin32_PtsHandleDestroyedCount(void) { return g_pts_hc_reading ? g_pts_sub_destroyed : -1; }
int WpfLinuxWin32_PtsHandleReadingState(void)   { return g_pts_hc_reading; }   /* 1=READING 0=NO-READING */
int WpfLinuxWin32_PtsSubClaimOk(void)     { return g_pts_sub_claim_ok; }
int WpfLinuxWin32_PtsSubClaimBad(void)    { return g_pts_sub_claim_bad; }
int WpfLinuxWin32_PtsSubSelfTestMask(void){ return g_pts_sub_selftest_mask; }

/* ── ⏪ `T-A25`（`NATIVE-QUERY-PHASE-CONTENT-MODEL`）：**子段对象（子树）谓词的判別力自检** ────────
   本增量把 `FsQuerySubtrackParaList` 交回的 `pfspara` 从**托管段句柄**换成**本侧自有子段对象** ⇒
   判据 D2 的两条"该红必红"必须由**同一谓词**判（照 `wpf_pts_sub_selftest`／`wpf_pts_prov_selftest` 形制）：
     bit0 正腿：子对象的句柄**可**从台账认领（托管回问 `FsQuerySubtrackDetails(child)` 可过）；
     bit1 **反腿（改前形态）**：**托管段句柄** `0x4` **不可**认领 ⇒ 正是改前 `unclaimable-subtrack` 的来源；
     bit2 **反腿（`P8` 陷阱）**：`c_paras=1` 而**缺** `child_objs[0]` ⇒ 交回时**必须拒**（`no-child-object`），
          **不得**退回托管句柄（退回就是"账面有内容、交出去没用"）；
     bit3 销毁**递归**：销毁父对象 ⇒ 子对象也离册（不再可认领）⇒ 回收口径成立；
     bit4 在册数**复原**（无泄漏）。 */
static int g_pts_subtree_selftest_mask = -1;
static int wpf_pts_subtree_selftest(void)
{
    int mask = 0;
    const int live0 = g_pts_sub_live_n;
    wpf_pts_subtrack *p = wpf_pts_sub_new((const void *)0x3, NULL);
    wpf_pts_subtrack *c = wpf_pts_sub_new((const void *)0x4, NULL);
    if (!p || !c) { if (p) wpf_pts_sub_destroy(p); if (c) wpf_pts_sub_destroy(c); return 0; }
    /* 照**窗内建树**的口径建父子边：`child_objs[k]` 与 `children[k]` 一一对应 */
    p->enum_ok = 1; p->formatted = 1; p->c_paras = 1;
    p->children[0] = (const void *)0x4; p->child_objs[0] = c; c->depth = 1;
    wpf_pts_subtrack *got = NULL;
    if (wpf_pts_sub_claim(wpf_pts_sub_handle(c), &got) && got == c) mask |= 1;   /* bit0 正腿 */
    if (!wpf_pts_sub_claim((const void *)0x4, NULL))               mask |= 2;   /* bit1 反腿：段句柄不可认领 */
    p->child_objs[0] = NULL;                                                     /* bit2 反腿：缺子对象 */
    { int missing = 0; for (int i = 0; i < p->c_paras; i++) if (!p->child_objs[i]) { missing = 1; break; }
      if (missing) mask |= 4; }
    p->child_objs[0] = c;                                                        /* 复原（供 bit3 用） */
    wpf_pts_sub_destroy(p);
    if (!wpf_pts_sub_claim(wpf_pts_sub_handle(c), NULL))           mask |= 8;   /* bit3 递归销毁 */
    if (g_pts_sub_live_n == live0)                                 mask |= 16;  /* bit4 无泄漏 */
    fprintf(stderr, "[SUBTREE-SELFTEST] mask=0x%02x child_claimable=%d stub_handle_rejected=%d "
                    "missing_child_rejected=%d destroy_recursive=%d live_restored=%d live=%d created=%d "
                    "v=%s（反极性两类必红：托管段句柄不可认领／缺子对象不得退回）\n",
            mask, (mask & 1) ? 1 : 0, (mask & 2) ? 1 : 0, (mask & 4) ? 1 : 0,
            (mask & 8) ? 1 : 0, (mask & 16) ? 1 : 0, g_pts_sub_live_n, g_pts_sub_created,
            (mask == 0x1f) ? "SUBTREE-IDENTITY-OK(5/5)" : "SUBTREE-IDENTITY-DEFECT(see-mask)");
    return mask;
}

/* ── ⏪ `T-A22`（`N1`：`PRECOND-NATIVE-CLAIMS-CALLBACK-HANDLES`）：**来源证据台账** ──────────────
   🎯 裁定四十七 (c)：身份判据**不得依赖 `rc`／数值形态**，须**独立可读的身份证据**。
   托管交回的句柄是 `PtsContext.CreateHandle` 的**槽位下标** ⇒ **数值可复用、非稳定身份**
   （同趟实证：`0x4` 先后当过段句柄与客户端句柄）。⇒ 本侧**绝不**按"数值相等"认对象：认的是
   「**产生该句柄的那一次回调调用**」这一**来源事实**（provenance）——
     · `channel`＝`'S'`（`+136`／`+144` **段句柄**）｜`'C'`（`+176` **客户端句柄**）
     · `doc`＝交回它的那个上下文（**对象身份核验**：本次调用的 `pfscontext` 必须**指针等值**于它）
     · `gen`＝那次枚举的**会话号**（`wpf_pts_doc.prov_gen`；**只增不复用** ⇒ 上一窗的旧身份不可认领）
     · `seq`＝本台账**全局唯一序号**（只增不复用 ⇒ 同值两条证据**可分辨**，这正是 `ABA` 的判据）
   持有期（裁定四十五 (a)）＝**托管对象生存期**：本侧只持**引用**、**不回收**托管句柄。
   🔴 **认领的必要但不充分条件**＝"数值等值"；**充分条件**＝同值候选里**恰有一条**满足
      （`doc` 等值 ∧ 通道相符 ∧ 会话相符）**且没有**任何同值的"异 doc／异通道／旧会话"条目；
      后者在册 ⇒ 判 `ABA-CONFLICT`／`WRONG-OBJECT`／`STALE-GEN` ⇒ **拒**（不静默取一条）。 */
#define WPF_PTS_PROV_MAGIC 0x56525054u   /* "TPRV" */
#define WPF_PTS_PROV_MAX   64
typedef struct {
    unsigned int magic;
    const void  *handle;        /* 托管交回的句柄值（**原样存，不 deref**） */
    const void  *doc;           /* 来源上下文（对象身份核验用） */
    char         channel;       /* 'S'＝段句柄（+136/+144）｜'C'＝客户端句柄（+176） */
    const char  *src;           /* 来源行标记（具名：哪个槽、在哪个 where） */
    int          ord;           /* 该次枚举内的序号（0 ＝ `+136` 首段） */
    int          gen;           /* 枚举会话号（doc->prov_gen） */
    int          written_out;   /* 本侧把它写进 `FSPARADESCRIPTION` 的次数（0 ⇒ 未交出去） */
    int          seq;           /* 全局唯一序号（只增不复用） */
    int          live;
} wpf_pts_prov;
static wpf_pts_prov g_pts_prov[WPF_PTS_PROV_MAX];
static int g_pts_prov_n        = 0;   /* 在册条数 */
static int g_pts_prov_created  = 0;
static int g_pts_prov_retired  = 0;   /* 因"新枚举会话"或"doc 注销"整体失效的条数 */
static int g_pts_prov_seq      = 0;
static int g_pts_prov_claim_ok = 0;
static int g_pts_prov_claim_no = 0;   /* 认领失败（**数值在册里一条都没有**） */
static int g_pts_prov_wrongobj = 0;   /* 反极性①：数值在册但**对象身份不符**（另一个 doc）⇒ 拒 */
static int g_pts_prov_ababa    = 0;   /* 反极性②：数值在册但**通道不符**（ABA／索引复用）⇒ 拒 */
static int g_pts_prov_stale    = 0;   /* 上一会话（旧 `gen`）的同值句柄 ⇒ 拒 */
static int g_pts_prov_selftest_mask = -1;
/* 只读口：**不新增导出**（导出面一字不动）；计数只在 `stderr` 具名行里引用。 */
static void wpf_pts_prov_retire(const void *doc, char channel, const char *why)
{
    (void)why;
    for (int i = 0; i < g_pts_prov_n; ) {
        wpf_pts_prov *e = &g_pts_prov[i];
        if (e->doc != doc || (channel && e->channel != channel)) { i++; continue; }
        e->live = 0; e->magic = 0;
        g_pts_prov[i] = g_pts_prov[--g_pts_prov_n];
        g_pts_prov[g_pts_prov_n].magic = 0;
        g_pts_prov_retired++;
    }
}
static int wpf_pts_prov_register(const void *doc, const void *handle, char channel,
                                 const char *src, int ord, int gen)
{
    if (!doc || !handle) return -1;
    /* 幂等：同 doc ＋ 同值 ＋ 同通道 ＋ 同会话 ⇒ 只更新（**不**新增 ⇒ 认领时唯一） */
    for (int i = 0; i < g_pts_prov_n; i++) {
        wpf_pts_prov *e = &g_pts_prov[i];
        if (e->doc == doc && e->handle == handle && e->channel == channel && e->gen == gen) {
            e->ord = ord; e->src = src; e->live = 1;
            return e->seq;
        }
    }
    if (g_pts_prov_n >= WPF_PTS_PROV_MAX) return -1;
    wpf_pts_prov *e = &g_pts_prov[g_pts_prov_n++];
    e->magic = WPF_PTS_PROV_MAGIC; e->handle = handle; e->doc = doc; e->channel = channel;
    e->src = src; e->ord = ord; e->gen = gen; e->written_out = 0;
    e->seq = ++g_pts_prov_seq; e->live = 1;
    g_pts_prov_created++;
    return e->seq;
}
/* 记「本侧**真把它交出去过**」的次数（写进 `FSPARADESCRIPTION` 那一刻）—— 是来源证据的**强化面**，
   不是认领的必要条件（认领的必要条件仍是 `handle` 等值 ∧ doc ∧ 通道 ∧ 会话）。 */
static int wpf_pts_prov_mark_written(const void *doc, char channel, const void *handle)
{
    for (int i = 0; i < g_pts_prov_n; i++) {
        wpf_pts_prov *e = &g_pts_prov[i];
        if (e->live && e->doc == doc && e->channel == channel && e->handle == handle) {
            e->written_out++;
            return e->written_out;
        }
    }
    return 0;
}
/* 认领：返回 1 ＝ 认出（`*out` 指向该证据）；0 ＝ 拒（具名分类见计数口）。 */
static int wpf_pts_prov_claim(const void *p, const void *doc, char channel, wpf_pts_prov **out)
{
    if (out) *out = NULL;
    if (!p) { g_pts_prov_claim_no++; return 0; }
    const int cur_gen = doc ? ((const wpf_pts_doc *)doc)->prov_gen : -1;
    int n_ok = 0, bad_doc = 0, bad_ch = 0, bad_gen = 0;
    wpf_pts_prov *hit = NULL;
    for (int i = 0; i < g_pts_prov_n; i++) {
        wpf_pts_prov *e = &g_pts_prov[i];
        if (e->magic != WPF_PTS_PROV_MAGIC || !e->live) continue;
        if (e->handle != p) continue;                       /* ① 数值等值（必要） */
        if (e->doc != doc)         { bad_doc++; continue; } /* ② 对象身份核验 */
        if (e->channel != channel) { bad_ch++;  continue; } /* ③ 通道（段 ≠ 客户端） */
        if (e->gen != cur_gen)     { bad_gen++; continue; } /* ④ 会话（上一窗 ⇒ 失效） */
        n_ok++; hit = e;
    }
    if (n_ok == 1 && bad_doc == 0 && bad_ch == 0 && bad_gen == 0) {
        if (out) *out = hit;
        g_pts_prov_claim_ok++;
        return 1;
    }
    if (n_ok == 0 && bad_doc == 0 && bad_ch == 0 && bad_gen == 0) g_pts_prov_claim_no++;
    if (bad_doc) g_pts_prov_wrongobj++;
    if (bad_ch)  g_pts_prov_ababa++;
    if (bad_gen) g_pts_prov_stale++;
    if (n_ok > 1) g_pts_prov_ababa++;       /* 同值多条同身份 ⇒ 也不唯一 ⇒ 拒 */
    return 0;
}
/* 自检：**两腿成对 ＋ 三条反极性必红**（只用自己的登记项；不碰主链 doc 台账）。
   bit0 正腿(同 doc＋同通道＋同会话 ⇒ 认出) ｜ bit1 `WRONG-OBJECT`(异 doc ⇒ 拒)
   ｜ bit2 `ABA`(同值异通道在册 ⇒ 拒) ｜ bit3 `STALE-GEN`(旧会话 ⇒ 拒) ｜ bit4 数值相等但零证据(⇒ 拒) */
static int wpf_pts_prov_selftest(void)
{
    static wpf_pts_doc d1, d2;                 /* 只当**身份令牌**；只读其 `prov_gen` */
    d1.magic = WPF_PTS_DOC_MAGIC; d1.prov_gen = 7;
    d2.magic = WPF_PTS_DOC_MAGIC; d2.prov_gen = 7;
    const void *H = (const void *)0x4;         /* 与 §2.3 同值（索引复用的真例） */
    const int n0 = g_pts_prov_n;
    int mask = 0;
    wpf_pts_prov *got = NULL;
    const int s1 = wpf_pts_prov_register(&d1, H, 'S', "selftest(+136.nmp@doc1)", 0, 7);
    if (s1 > 0 && wpf_pts_prov_claim(H, &d1, 'S', &got) && got && got->seq == s1) mask |= 1;
    if (!wpf_pts_prov_claim(H, &d2, 'S', NULL)) mask |= 2;          /* 异 doc ⇒ 拒 */
    wpf_pts_prov_register(&d1, H, 'C', "selftest(+176@doc1)", 0, 7);
    if (!wpf_pts_prov_claim(H, &d1, 'S', NULL)) mask |= 4;          /* 同值异通道 ⇒ 拒（ABA） */
    d1.prov_gen = 8;
    if (!wpf_pts_prov_claim(H, &d1, 'S', NULL)) mask |= 8;          /* 旧会话 ⇒ 拒 */
    d1.prov_gen = 7;
    wpf_pts_prov_retire(&d2, 0, "selftest");                        /* 清腿（d2 名下本无条目） */
    wpf_pts_prov_retire(&d1, 0, "selftest");
    if (!wpf_pts_prov_claim((const void *)0x5bdbff1b1054, &d1, 'S', NULL)) mask |= 16;  /* 零证据 ⇒ 拒 */
    fprintf(stderr, "[PROV-SELFTEST] mask=0x%02x claim_ok=%d wrong_object=%d aba=%d stale=%d zero_evidence=%d "
                    "created=%d retired=%d n=%d(n0=%d) v=%s（反极性三类必红：wrong-object／ABA／stale-gen）\n",
            mask, (mask & 1) ? 1 : 0, (mask & 2) ? 1 : 0, (mask & 4) ? 1 : 0, (mask & 8) ? 1 : 0,
            (mask & 16) ? 1 : 0, g_pts_prov_created, g_pts_prov_retired, g_pts_prov_n, n0,
            (mask == 0x1f) ? "PROV-IDENTITY-OK(5/5)" : "PROV-IDENTITY-DEFECT(see-mask)");
    return mask;
}

/* ── ⏪ `t162` E1：`FSIMETHODS` **镜像 ＋ 断言**（判据/队长指引：槽序今天只能按托管声明推断 ⇒
      **具名 `NOINFO-FSIMETHODS-ABI`**，但**偏移**必须钉死并**实测**槽指针是否在场）。 ── */
typedef int (*wpf_pts_fnim)(void);
typedef struct {
    void *pfnCreateContext;                 /* 槽 1  @ +0   */
    void *pfnDestroyContext;                /* 槽 2  @ +8   */
    void *pfnFormatParaFinite;              /* 槽 3  @ +16  ← **engine-side 造型入口** */
    void *pfnFormatParaBottomless;          /* 槽 4  @ +24  */
    void *pfnUpdateBottomlessPara;          /* 槽 5  @ +32  */
    void *pfnSynchronizeBottomlessPara;     /* 槽 6  @ +40  */
    void *pfnComparePara;                   /* 槽 7  @ +48  */
    void *pfnClearUpdateInfoInPara;         /* 槽 8  @ +56  */
    void *pfnDestroyPara;                   /* 槽 9  @ +64  */
    void *pfnDuplicateBreakRecord;          /* 槽 10 @ +72  */
    void *pfnDestroyBreakRecord;            /* 槽 11 @ +80  */
    void *pfnGetColumnBalancingInfo;        /* 槽 12 @ +88  */
    void *pfnGetNumberFootnotes;            /* 槽 13 @ +96  */
    void *pfnGetFootnoteInfo;               /* 槽 14 @ +104 */
    void *pfnGetFootnoteInfoWord;           /* 槽 15 @ +112 */
    void *pfnShiftVertical;                 /* 槽 16 @ +120 */
    void *pfnTransferDisplayInfoPara;       /* 槽 17 @ +128 */
} wpf_pts_fsimethods;
_Static_assert(sizeof(wpf_pts_fsimethods) == 17 * 8, "FSIMETHODS 不是 17 × 8 B");
_Static_assert(offsetof(wpf_pts_fsimethods, pfnCreateContext)          ==   0, "槽序偏移错：槽 1");
_Static_assert(offsetof(wpf_pts_fsimethods, pfnFormatParaFinite)       ==  16, "槽序偏移错：槽 3");
_Static_assert(offsetof(wpf_pts_fsimethods, pfnGetNumberFootnotes)     ==  96, "槽序偏移错：槽 13");
_Static_assert(offsetof(wpf_pts_fsimethods, pfnTransferDisplayInfoPara)== 128, "槽序偏移错：槽 17");

#ifndef WPF_PTS_FSP_PL_PARA_MADEUP
#define WPF_PTS_FSP_PL_PARA_MADEUP 0      /* 只在**副本**：`pfspara` 填 NULL ⇒ 认领必拒 ⇒ 必红（E3-①） */
#endif
#ifndef WPF_PTS_FSP_PL_PARA_WRONGTYPE
#define WPF_PTS_FSP_PL_PARA_WRONGTYPE 0   /* 只在**副本**：`pfspara` 填**栈地址**（看似真则伪）⇒ 认领必拒（E3-②） */
#endif

/* 每次运行的填充上限（`<=0` ⇒ **不限**）。旋钮 `WPF_PTS_FSP_PL_MAX`（缺省 0＝不限）。 */
static int wpf_pts_fsp_pl_max(void)
{
    static int cached = -2;
    if (cached != -2) return cached;
    const char *e = getenv("WPF_PTS_FSP_PL_MAX");
    cached = (e && *e) ? atoi(e) : 0;
    return cached;
}
/* 每一代客户端服务多少次填充（旋钮 `WPF_PTS_FSP_PL_GEN`，缺省 32；`<1` ⇒ 1）。 */
static int wpf_pts_fsp_pl_gen_size(void)
{
    static int cached = -2;
    if (cached != -2) return cached;
    const char *e = getenv("WPF_PTS_FSP_PL_GEN");
    cached = (e && *e) ? atoi(e) : 32;
    if (cached < 1) cached = 1;
    return cached;
}
/* 两腿实验的源选择：`WPF_PTS_FSP_PL_WIN=out` ⇒ 用**窗外**腿造出的第一代（W-2）；缺省 `in`（W-1）。 */
static int wpf_pts_fsp_pl_win_out(void)
{
    static int cached = -1;
    if (cached != -1) return cached;
    const char *e = getenv("WPF_PTS_FSP_PL_WIN");
    cached = (e && *e && (e[0] == 'o' || e[0] == 'O')) ? 1 : 0;
    return cached;
}
/* 🔴 判据 §6「零假值铁律」：真腿内出现哨兵值（`0x2/0x3/0x4/0x5`）⇒ 该读数作废。本件**从不**造句柄值，
   只用**托管 `+176` 的返回值**；本谓词只用来**具名**（不作判据）。 */
static int wpf_pts_fsp_pl_is_sentinel(const void *h)
{
    unsigned long long v = (unsigned long long)(unsigned long)h;
    return (v == 0x2ULL || v == 0x3ULL || v == 0x4ULL || v == 0x5ULL);
}

typedef int (*wpf_pts_fn_get_first_para)(const void *pfsclient, const void *nms, int *f_successful, void **nmp);
typedef int (*wpf_pts_fn_get_next_para)(const void *pfsclient, const void *nms, const void *nmp_cur,
                                        int *f_found, void **nmp_next);
typedef int (*wpf_pts_fn_get_para_properties)(const void *pfsclient, const void *nmp, void *fspap);
_Static_assert(sizeof(wpf_pts_fn_get_first_para) == 8 && sizeof(wpf_pts_fn_get_para_properties) == 8,
               "回调指针不是 8 B（与快照的 8 B 字假设不符）");
_Static_assert(sizeof(wpf_pts_fn_get_next_para) == 8, "回调指针不是 8 B（与快照的 8 B 字假设不符）");

/* ── ⏪ `T-A28`：`pfnFormatLine` 的**回调签名**（逐参照抄上游 `Pts.cs:2312-2341` 的 `FormatLine` 委托）──
   18 个入参 ＋ 11 个出参，**全是 ≤8 B 标量**（`int`／指针）⇒ 无结构封送风险；`out FSFLRES` 是
   `int` 枚举（`Pts.cs:1092`）⇒ 出参是 `int *`。
   ⚠️ **契约的严格面在托管侧**（`PtsHost.cs:1341`）：`nmp` 必须是 `TextParagraph`、`pfsparaclient`
   必须是 `TextParaClient`，否则 `ValidateHandle` 抛 ⇒ 被 `catch` ⇒ 返 `-100002`
   （`tserrCallbackException`）；**不可捕获的 `FailFast` 只出现在跨族调 `HandleToObject` 的那类槽**
   （见 `FsQueryTrackParaList` 的具名边界）—— 本槽两条身份检查都落在那两个 `try/catch` 内。 */
typedef int (*wpf_pts_fn_format_line)(
    const void *pfsclient, const void *pfsparaclient, const void *nmp,
    int i_area, int dcp, const void *pbrline_in, unsigned int fswdir,
    int ur_start_line, int dur_line, int ur_start_track, int dur_track,
    int ur_page_left_margin, int f_allow_hyphenation, int f_clear_on_left,
    int f_clear_on_right, int f_treat_as_first_in_para, int f_treat_as_last_in_para,
    int f_suppress_top_space,
    void **out_pfsline, int *out_dcp_line, void **out_ppbrline,
    int *out_f_forced_broken, int *out_fsflres, int *out_dvr_ascent,
    int *out_dvr_descent, int *out_ur_bbox, int *out_dur_bbox,
    int *out_dcp_depend, int *out_f_reformat);
_Static_assert(sizeof(wpf_pts_fn_format_line) == 8, "pfnFormatLine 指针不是 8 B");

/* ── ⏪ `T-A36`：`pfnGetNumberAttachedObjectsInTextLine` 的**回调签名**（逐参照抄上游
   `Pts.cs:2535-2543` 的 `GetNumberAttachedObjectsInTextLine` 委托）。
   3 个入参指针 ＋ 4 个 `int` ＋ 1 个 `int*` 出参，**全是 ≤8 B 标量** ⇒ 无结构封送风险。
   ⚠️ 契约的严格面在托管侧（`PtsHost.cs:2002`）：`nmp` 必须是 `TextParagraph`、`pfsline` 必须是
   `LineBase`（否则 `ValidateHandle` 抛 ⇒ 被 `try/catch` 捕 ⇒ 返 `-100002`）；**不可捕获的
   `FailFast` 只出现在跨族调 `HandleToObject` 的那类槽**，本槽两条 `HandleToObject` 都落在
   `try/catch` 内（`PtsHost.cs:2013-2052`）⇒ 可捕获、可判。 */
typedef int (*wpf_pts_fn_get_num_attach_in_line)(
    const void *pfsclient, const void *pfsline, const void *nmp,
    int dcp_first, int dcp_lim, int f_found_before, int dcp_max_anchor_before,
    int *out_c_attached_objects);
_Static_assert(sizeof(wpf_pts_fn_get_num_attach_in_line) == 8, "pfnGetNumberAttachedObjectsInTextLine 指针不是 8 B");

/* ── ⏪ `T-A36`：`pfnGetAttachedObjectsInTextLine` 的**回调签名**（逐参照抄上游 `Pts.cs:2544-2556`
   的 `GetAttachedObjectsInTextLine` 委托）：在 `num` 拿到计数后，用它取**对象名／`idobj`／锚点**。
   契约严格面同 `num`（`PtsHost.cs:2056`：`nmp`→`TextParagraph`、`pfsline`→`LineBase`，全在
   `try/catch` 内 ⇒ 可捕获）。 */
typedef int (*wpf_pts_fn_get_attach_in_line)(
    const void *pfsclient, const void *pfsline, const void *nmp,
    int dcp_first, int dcp_lim, int f_found_before, int dcp_max_anchor_before,
    int n_attached_objects, void **rg_nmp_objects, int *rg_idobj, int *rg_dcp_anchor,
    int *out_c_objects);
_Static_assert(sizeof(wpf_pts_fn_get_attach_in_line) == 8, "pfnGetAttachedObjectsInTextLine 指针不是 8 B");

static int          g_pts_dp2_136_a    = -1;   /* +136 首调 fserr */
static int          g_pts_dp2_136_b    = -1;   /* +136 次调 fserr */
static int          g_pts_dp2_136_succ = -1;   /* fSuccessful（首调） */
static const void  *g_pts_dp2_136_nmp  = NULL; /* nmp（首调） */
static int          g_pts_dp2_136_idem = 0;    /* 连调同值 ⇒ 1 */
static int          g_pts_dp2_168_rc   = -9999;/* +168（下游接受性判别器；-9999 = 未调） */
static int          g_pts_dp2_oow_rc   = -9999;/* 窗外腿（`FsDestroyPage`）的 +136 fserr */
static int          g_pts_dp2_oow_succ = -1;
static const void  *g_pts_dp2_oow_nmp  = NULL;
static int          g_pts_dp2_oow_calls= 0;
static int          g_pts_dp2_oow_refused = 0;  /* ⏪ `T-A17`：因 liveness 判据被**拒驱**的次数（只计数，不新增导出） */
static unsigned long long g_pts_dp2_t3_value = 0;  /* T3 腿所用值（0 = 未走 T3） */

int WpfLinuxWin32_PtsDriveProbe2Fserr136(void)  { return g_pts_dp2_136_a; }
int WpfLinuxWin32_PtsDriveProbe2Fserr136b(void) { return g_pts_dp2_136_b; }
int WpfLinuxWin32_PtsDriveProbe2Success136(void){ return g_pts_dp2_136_succ; }
void *WpfLinuxWin32_PtsDriveProbe2Nmp136(void)  { return (void *)g_pts_dp2_136_nmp; }
int WpfLinuxWin32_PtsDriveProbe2Idem136(void)   { return g_pts_dp2_136_idem; }
int WpfLinuxWin32_PtsDriveProbe2Fserr168(void)  { return g_pts_dp2_168_rc; }
int WpfLinuxWin32_PtsDriveProbe2OowFserr(void)  { return g_pts_dp2_oow_rc; }
int WpfLinuxWin32_PtsDriveProbe2OowCalls(void)  { return g_pts_dp2_oow_calls; }
unsigned long long WpfLinuxWin32_PtsDriveProbe2T3Value(void) { return g_pts_dp2_t3_value; }

static void wpf_pts_drive_probe_skip(const char *reason)
{
    g_pts_dp_skips++;
    g_pts_dp_last_skip = reason;
    if (g_pts_dp_skips <= WPF_PTS_DRIVE_PROBE_PRINT_SKIP_MAX)
        fprintf(stderr, "[DRIVE-PROBE-SKIP] reason=%s skips=%d（**未发出任何回调调用**；不许当绿）\n",
                reason, g_pts_dp_skips);
}

/* 只读：从快照里取第 idx 个 8 B 字（直接读值，**不 deref** 入参） */
static const void *wpf_pts_snap_word(const wpf_pts_doc *d, int idx)
{
    unsigned long long v = 0;
    for (int i = 0; i < 8; i++) v |= ((unsigned long long)d->fscbk_snap[idx * 8 + i]) << (8 * i);
    return (const void *)(unsigned long)v;
}

/* ⏪ `T-A12`：**子段枚举**（`cParas` 的源）—— 在**窗内**用托管回调 `+136`（首）／`+144`（后继）
   **真枚举**子轨段落（`container` 即本 doc 的 `drive_nmp`：`+136` 从主文本段取到的首子段，
   而该句柄是真 `ContainerParagraph` ⇒ 对 `ISegment` 成立）⇒ 计数即 `cParas` 的**可信来源**。
   🔴 口径（写死，防假绿）：① **只在窗内**（`FsCreatePage*` ⇒ `wpf_pts_drive_probe`；窗外腿
      `+136` 实测 `-100002`，见 `[DRIVE-PROBE2-OOW]`）；② **不用任何伪值／常数** —— 计数只来自
      回调真返回；③ **穷尽才算成功**：`rc≠0`／超界／成环 ⇒ `ok=0`、`cparas=0`，调用方**必须**拒绝；
      ④ 有界（`WPF_PTS_SUB_CHILD_MAX`）＋ 成环守卫；⑤ **失败必留痕**（每趟一条具名 `[SUBENUM]`）。 */
static int g_pts_sub_enum_calls = 0;
static int g_pts_sub_enum_ok_c  = 0;
static int g_pts_sub_enum_gap   = 0;
/* ⏪ `T-A22`（`N2`：`PRECOND-WINDOW-SEPARATION`）：**窗内枚举／窗外汇总**的**成对**计数 ——
   `in` ＝ 在 `FsCreatePage*` 造型窗内**真枚举并真填**的次数（`[WINDOW-SPLIT] window=in`）；
   `out` ＝ 窗外**只汇总/拒绝**的次数（`[WINDOW-SPLIT] window=out`；**零回调**发调）。
   🔴 两腿分开报（判据 D5／`P13`）：**不**把"窗内可得"读成"调用期可得"。 */
static int g_pts_win_in_enum      = 0;
static int g_pts_win_out_summary  = 0;
static int g_pts_win_out_refused  = 0;
/* ── ⏪ `T-A25`（`NATIVE-QUERY-PHASE-CONTENT-MODEL`）：**窗内递归建树**的成对计数 ────────────────
   `g_pts_subtree_nodes` ＝ 本次建树创建的**对象总数**（含根）；`g_pts_subtree_fail` ＝ 因**表满／到界**
   未建成的子对象数（**失败必留痕**，且交回时按 `no-child-object` 拒绝）。 */
static int g_pts_subtree_nodes  = 0;
static int g_pts_subtree_fail   = 0;
static int g_pts_subtree_depthmax = 0;

/* ⏪ `T-A25`：**把某个容器对象的子段序枚举出来**（窗内），填进 `obj`；并为每个子段建**本侧对象**、
   递归下去（深度到 `WPF_PTS_SUB_MAX_DEPTH` 即停）。
   🔴 口径（承 `wpf_pts_sub_enum`，一字不改）：① 只在窗内；② 计数只来自回调真返回；③ 穷尽才算成功
      （`rc≠0`／超界／成环 ⇒ `enum_ok=0`，`c_paras` 保持 0）；④ 有界；⑤ 失败必留痕。
   🔴 **为什么可以对本侧不能当 `ISegment` 的子段（`TextParagraph` 等）发调**：`PtsHost.GetFirstPara`
      /`GetNextPara` 把整个体包在 `try/catch` 里（`as ISegment` 落空 ⇒ `ValidateHandle(null)` ⇒
      **普通异常** ⇒ 捕 ⇒ `fserrCallbackException(-100002)`），**不碰** `HandleToObject` 的
      `Invariant.Assert` ⇒ **可捕获、无 `FailFast`**（`PtsHost.cs:586-612/:613-…` 现取）。 */
static int wpf_pts_sub_enum_into(wpf_pts_doc *d, const void *container, wpf_pts_subtrack *obj,
                                 const char *where, int depth)
{
    if (!obj) return 0;
    obj->depth = depth;
    obj->nmp   = container;
    obj->enum_ok = 0; obj->c_paras = 0; obj->formatted = 0;
    const void *fp136 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETFIRSTPARA);
    const void *fp144 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETNEXTPARA);
    if (!container || !fp136 || !fp144) return 0;
    int n = 0; const void *first = NULL;
    int fSucc = -1; void *nmp = NULL;
    int rc136 = ((wpf_pts_fn_get_first_para)fp136)((const void *)d->p_fsclient, container, &fSucc, &nmp);
    if (rc136 != 0) return 0;
    if (fSucc == 0 || !nmp) { obj->enum_ok = 1; obj->c_paras = 0; obj->formatted = 1; return 1; }
    first = (const void *)nmp;
    obj->children[n++] = first;
    while (1) {
        int fFound = -1; void *nx = NULL;
        if (n >= WPF_PTS_SUB_CHILD_MAX) return 0;          /* 超界 ⇒ **不成**（不许给 cParas） */
        int rc144 = ((wpf_pts_fn_get_next_para)fp144)((const void *)d->p_fsclient, container,
                                                      (const void *)obj->children[n - 1], &fFound, &nx);
        if (rc144 != 0) return 0;
        if (fFound == 0 || !nx) break;                      /* 穷尽 ⇒ 计数可信 */
        {   int dup = 0;
            for (int j = 0; j < n; j++) if (obj->children[j] == (const void *)nx) { dup = 1; break; }
            if (dup) return 0;
        }
        obj->children[n++] = (const void *)nx;
    }
    obj->enum_ok = 1; obj->c_paras = n; obj->formatted = 1;
    if (depth > g_pts_subtree_depthmax) g_pts_subtree_depthmax = depth;
    if (depth >= WPF_PTS_SUB_MAX_DEPTH) return 1;           /* 到界 ⇒ **不再往下建**（本层计数仍有效） */
    for (int k = 0; k < n; k++) {
        wpf_pts_subtrack *co = wpf_pts_sub_new(obj->children[k], NULL);
        if (!co) { g_pts_subtree_fail++; obj->child_objs[k] = NULL; continue; }
        obj->child_objs[k] = co;
        g_pts_subtree_nodes++;
        wpf_pts_sub_enum_into(d, obj->children[k], co, where, depth + 1);
    }
    (void)first;
    return 1;
}

static void wpf_pts_sub_enum(wpf_pts_doc *d, const void *container, const char *where)
{
    g_pts_sub_enum_calls++;
    d->prov_gen++;                       /* ⏪ `T-A22`：新会话 ⇒ 上一会话的段证据整体失效（只增不复用） */
    wpf_pts_prov_retire((const void *)d, 'S', "new-subenum-session");
    d->sub_enum_ok = 0; d->sub_cparas = 0;
    d->sub_enum_rc136 = -9999; d->sub_enum_rc144 = -9999;
    const char *v = "ENUM-NOT-RUN";
    int n = 0; const void *first = NULL;
    const void *fp136 = NULL, *fp144 = NULL;
    if (!container) { v = "ENUM-FAIL(null-container)"; goto out; }
    fp136 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETFIRSTPARA);
    fp144 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETNEXTPARA);
    if (!fp136 || !fp144) { v = "ENUM-FAIL(no-slot)"; goto out; }
    {
        int fSucc = -1; void *nmp = NULL;
        int rc136 = ((wpf_pts_fn_get_first_para)fp136)((const void *)d->p_fsclient, container, &fSucc, &nmp);
        d->sub_enum_rc136 = rc136;
        if (rc136 != 0) { v = "ENUM-FAIL(rc136)"; goto out; }
        if (fSucc == 0 || !nmp) {                       /* 真·无子段 ⇒ 诚实 cParas=0 */
            d->sub_enum_ok = 1; d->sub_cparas = 0; v = "ENUM-EMPTY(true-zero-children)"; goto out;
        }
        first = (const void *)nmp;
        d->sub_children[n++] = first;
        while (1) {
            int fFound = -1; void *nx = NULL;
            int rc144;
            if (n >= WPF_PTS_SUB_CHILD_MAX) { d->sub_enum_rc144 = -9999;
                v = "ENUM-FAIL(incomplete-limit)"; goto out; }
            rc144 = ((wpf_pts_fn_get_next_para)fp144)((const void *)d->p_fsclient, container,
                                                      (const void *)d->sub_children[n - 1], &fFound, &nx);
            d->sub_enum_rc144 = rc144;
            if (rc144 != 0) { v = "ENUM-FAIL(rc144)"; goto out; }
            if (fFound == 0 || !nx) {                   /* 穷尽 ⇒ 计数可信 */
                d->sub_enum_ok = 1; d->sub_cparas = n; v = "ENUM-OK"; break;
            }
            {   int dup = 0;                            /* 成环守卫：重复句柄 ⇒ 不是链表 ⇒ 拒 */
                for (int j = 0; j < n; j++) if (d->sub_children[j] == (const void *)nx) { dup = 1; break; }
                if (dup) { v = "ENUM-FAIL(cycle)"; goto out; }
            }
            d->sub_children[n++] = (const void *)nx;
        }
    }
out:
    d->sub_enum_v = v;
    /* ⏪ `T-A22`（`N1`）：**本 run 由 `+136`／`+144` 交回的段句柄**逐条入册为**来源证据**
       （通道 `'S'`、会话 `d->prov_gen`、序号＝枚举序、来源行＝`where`）—— 这是 native 侧**唯一**
       的身份来源，**不看数值形态**（判据 D4／裁定四十七 (c)）。未穷尽（`ok=0`）⇒ **零登记**。 */
    if (d->sub_enum_ok && d->sub_cparas > 0) {
        for (int j = 0; j < d->sub_cparas && j < WPF_PTS_SUB_CHILD_MAX; j++)
            wpf_pts_prov_register((const void *)d, d->sub_children[j], 'S', where, j, d->prov_gen);
    }
    /* ── ⏪ `T-A25`（`NATIVE-QUERY-PHASE-CONTENT-MODEL`）：**窗内建子树**（每个子段一个本侧对象）──
       · 只在 `d->sub_enum_ok && d->sub_cparas > 0` 时建（枚举成功才有可信的子段序）；
       · 每个子段对象由 `wpf_pts_sub_enum_into` **递归**填入它自己的子段序（`TextParagraph` 之类
         非 `ISegment` ⇒ `+136` 返 `-100002` ⇒ `enum_ok=0`；若托管回问 `FsQuerySubtrackDetails`
         则按 `no-layout-content-model` **诚实拒绝**，若回问 `FsQueryTextDetails` 则按
         `no-text-line-model` **诚实拒绝**）；
       · `d->sub_child_objs_n == 0` 才建（本 doc 只驱一窗 ⇒ 不会覆盖；见 `drive_done`）；
       · **失败必留痕**：`fail=` 给出建不成的子对象数（表满）。 */
    if (d->sub_enum_ok && d->sub_cparas > 0 && d->sub_child_objs_n == 0) {
        d->sub_child_objs_fail = 0;
        for (int j = 0; j < d->sub_cparas && j < WPF_PTS_SUB_CHILD_MAX; j++) {
            wpf_pts_subtrack *co = wpf_pts_sub_new(d->sub_children[j], NULL);
            if (!co) { d->sub_child_objs_fail++; g_pts_subtree_fail++; continue; }
            d->sub_child_objs[j] = co;
            g_pts_subtree_nodes++;
            wpf_pts_sub_enum_into(d, d->sub_children[j], co, where, 1);
        }
        d->sub_child_objs_n = d->sub_cparas;
        fprintf(stderr, "[SUBTREE] where=%s root=%p n_children=%d child_objs=%d fail=%d nodes_total=%d "
                        "depth_max=%d live=%d created=%d depth_lim=%d v=%s\n",
                where, container, d->sub_cparas, d->sub_child_objs_n, d->sub_child_objs_fail,
                g_pts_subtree_nodes, g_pts_subtree_depthmax, g_pts_sub_live_n, g_pts_sub_created,
                WPF_PTS_SUB_MAX_DEPTH,
                (d->sub_child_objs_fail == 0) ? "IN-WINDOW-SUBTREE-BUILT"
                                              : "IN-WINDOW-SUBTREE-PARTIAL(table-full)");
    }
    if (d->sub_enum_ok) g_pts_sub_enum_ok_c++; else g_pts_sub_enum_gap++;
    /* 失败必留痕（具名 ＋ 计数；**不静默**）：`cParas` 的源是否成立，看这一行的 `ok=`／`v=`。 */
    fprintf(stderr, "[SUBENUM] where=%s container=%p first=%p cparas=%d ok=%d rc136=%d rc144=%d "
                    "child_max=%d v=%s calls=%d ok_n=%d gap=%d window=in\n",
            where, container, first, d->sub_enum_ok ? d->sub_cparas : 0, d->sub_enum_ok,
            d->sub_enum_rc136, d->sub_enum_rc144, WPF_PTS_SUB_CHILD_MAX, v,
            g_pts_sub_enum_calls, g_pts_sub_enum_ok_c, g_pts_sub_enum_gap);
    /* ⏪ `T-A22`（`N2`）：**窗内**腿的成对行 —— 与窗外的 `[WINDOW-SPLIT] window=out` **成对**判读：
       本行证明"枚举/真填发生在**窗内**"（`calls136` 即真发起的 `+136`／`+144` 调用数）。 */
    if (d->sub_enum_ok) g_pts_win_in_enum++;
    fprintf(stderr, "[WINDOW-SPLIT] where=%s window=in action=enum+ledger src=+136/+144 "
                    "ledger_ok=%d ledger_cparas=%d calls136=%d(real-callbacks-in-window) "
                    "in_enum=%d out_sum=%d out_refused=%d v=%s\n",
            where, d->sub_enum_ok, d->sub_enum_ok ? d->sub_cparas : 0,
            (d->sub_enum_rc136 != -9999 ? 1 : 0) + (d->sub_enum_rc144 != -9999 ? 1 : 0),
            g_pts_win_in_enum, g_pts_win_out_summary, g_pts_win_out_refused,
            d->sub_enum_ok ? "IN-WINDOW-ENUM+LEDGER" : "IN-WINDOW-ENUM-FAILED");
}

/* ══ ⏪ `T-A28`（`TASK-0302` 增量）：native 侧**驱动 `pfnFormatLine`** ＋ **行记录台账** ═══════════
   【这一格要解决什么】`T-A27` §2.3 现取：native 侧**从不驱动** `cbktxt` 任何槽（`grep cbktxt.` ＝ 0）
   ⇒ 没有行记录可回填 ⇒ `FsQueryTextDetails` 恒拒（`no-text-line-model 109`）。本格把**第一跳**接起来：
   **在造型窗内**（`FsCreatePage*` ⇒ `wpf_pts_drive_probe`）对**枚举到的文本段落**真调
   `pfnFormatLine`（绝对偏移 `+368`／快照下标 `41`），并把**它的返回值**逐行记进本侧台账。

   【路径（逐跳，全部在窗内）】
     ① 在窗内已枚举出的子段树里找**叶**（`enum_ok==0` ⇒ `+136` 对该段不成立 ⇒ 非 `ISegment`
        ⇒ 正是 `TextParagraph` 那一类；`T-A26` 的 `[NMP-TYPE]` 现场：容器 `0x4` 的首段 `0x8`
        `TYPE=MS.Internal.PtsHost.TextParagraph`）；
     ② `+176 pfnCreateParaclient(nmp)` ⇒ 为该 `TextParagraph` 现造 `TextParaClient`（**本侧**造、
        **本侧**回收）；
     ③ 循环 `pfnFormatLine`（`dcp` 累计；`pbrlineIn` 取上一行的 `ppbrlineOut`）直到
        `fsflrEndOfParagraph*` / 无进展（`dcpLine<=0` 成环守卫）/ 行数上界；
     ④ 收尾 `+192 pfnDestroyParaclient` 回收客户端。

   🔴 **硬边界（承 `T-A27` §4 判据 D1–D6）**
     · **窗内才驱**（`FsCreatePage*` 窗；窗外查询期**只回查／只拒绝**，承 `N2`）；
     · **零假值**：台账**只**装 `pfnFormatLine` 的**真返回值**；`rc≠0` ⇒ 该行不记账；
     · **永不假成功**：`fl_ok` 仅当"至少一行 ∧ 末行由 `fsflrEndOfParagraph*` 收束 ∧ 未撞行数上界"
       ⇒ **几何上确实排到段尾**；否则 `fl_ok=0` ⇒ 回查**必须拒**（回查在下一增量里接）；
     · **失败必留痕**：每段一条 `[FORMATLINE]`（`rc=`／`nlines=`／`v=`）＋ 全局计数；
     · **有界 ＋ 成环守卫**：`WPF_PTS_FL_MAXLINE`／`WPF_PTS_FL_MAX_PARA` ＋ `dcpLine<=0` 即停。
   ⚠️ **几何来源（如实划界）**：`pfnFormatLine` 要页几何（`urStartLine`／`durLine`／`urStartTrack`／
      `durTrack`／`urPageLeftMargin`）。本侧**没有**几何的入站源（页矩形由真机 native 引擎在
      `FsCreatePage*` 内自算；本移植的 `FsCreatePageFinite` 用的是**本侧页几何约定** `768×576`，
      见该入口的 `WPF_PTS_FSP_FIN_DU/DV`）⇒ 本格**沿用同一约定**并**具名** `NOINFO-FSGEOMETRY-LAYOUT`
      （**不**声称与上游 ABI 几何可比；`pbrlineIn` 首行传 `0`＝首行契约）。 */
/* ⏪ `T-A28`：**运行期闸**（原缺省 **关**）—— 曾以 `WPF_PTS_FL_DRIVE=1` 才驱。
   🔴 当年缺省关的理由（不是"保守"，是**现场读数**）：本跳在**正确几何**（`600 DIP`）下真被驱时，
      托管侧 `Line.GetTextRun` 会撞 **`Invariant.FailFast("We do not expect any Blocks inside
      Paragraphs")`**（`LineBase.cs:137`）⇒ **不可捕获** ⇒ `app_rc=134`（载体 §3 的成对读数：
      `gate=on` ⇒ `alive=no/app_rc=134`；`gate=off` ⇒ `alive=yes/app_rc=143`，其余症状门逐字相同）。
      ⇒ 当时缺省关 ＝ **不把已知会 abort 的调用放进主链**；驱与不驱都**留具名行**（零静默）。
   ⏪ `T-A31`：该 abort 前置已由 `T-A30` 在行模型写域内解除
      （`PRECOND-LINEMODEL-ELEMENT-SAFE-STARTS`：段末行交回源自己的那个 `ParagraphBreakRun`
      ⇒ 段末收束 `fsflres=2`、不再越界撞 Block；闸开时 `failfast=0 app_rc=143`、`[FORMATLINE] 7/7`）
      ⇒ 本增量照 `T-A9` 体例**把闸翻为缺省开**（撤销「缺省关」），使**缺省路径**也驱动行模型；
      **仅显式 `WPF_PTS_FL_DRIVE=0` 才关**（反极性腿 `legs-polar0`）。 */
#ifndef WPF_PTS_FL_DEFAULT
#define WPF_PTS_FL_DEFAULT 1
#endif
#define WPF_PTS_FL_DU 180000         /* 本侧页几何：**PTS 单位**（`TextDpi`：`300 单位 = 1 DIP`）
                                         ⇒ `180000 = 600 DIP`（`TextDpi.cs:201` 的 `_scale=28800/96=300`）。
                                         ⚠️ `FsCreatePageFinite` 的 `768/576` 是**同一单位制**下的**另一组**
                                         约定值（= 2.56×1.92 DIP，仅够"页对象存在"）⇒ 与行排版无可比性。 */
#define WPF_PTS_FL_DV 180000
static int g_pts_fl_gate = -1;       /* 运行期闸（-1 = 未读环境） */
static int wpf_pts_fl_enabled(void)
{
    if (g_pts_fl_gate < 0) {
        const char *e = getenv("WPF_PTS_FL_DRIVE");
        g_pts_fl_gate = e ? atoi(e) : WPF_PTS_FL_DEFAULT;
    }
    return g_pts_fl_gate;
}
static int g_pts_fl_win_paras = 0;   /* 本窗已被驱的段数（窗级预算） */
static int g_pts_fl_paras     = 0;   /* 累计被驱段数（只增） */
static int g_pts_fl_calls     = 0;   /* 累计 `pfnFormatLine` 调用数（D4 的 `calls=`） */
static int g_pts_fl_ok        = 0;   /* 累计可用行记录段数（D2 的"真源"面） */
static int g_pts_fl_gap       = 0;   /* 累计不可用段数（失败必留痕） */
static int g_pts_fl_nopara    = 0;   /* 找不到可驱段／缺槽的次数 */
static int g_pts_fl_attempt   = 0;   /* 累计**尝试驱**的段数（含未成；`driven=` 用这个） */
static int g_pts_fl_win_attempt = 0; /* 本窗尝试驱的段数（窗级） */
static int g_pts_fl_incomplete= 0;   /* 行记录**未收束于段尾**（撞界／无进展）的段数 */
static const char *g_pts_fl_last_v = "NOT-RUN";

static int wpf_pts_format_one_para(wpf_pts_doc *d, wpf_pts_subtrack *leaf,
                                   const void *fpFL, const void *fp176, const void *fp192,
                                   const char *where)
{
    wpf_pts_fn_format_line fl = (wpf_pts_fn_format_line)fpFL;
    void *cli = NULL;
    g_pts_fl_attempt++; g_pts_fl_win_attempt++;
    int rc176 = ((wpf_pts_fn_create_paraclient)fp176)((const void *)d->p_fsclient,
                                                      (const void *)leaf->nmp, &cli);
    leaf->fl_paraclient_rc = rc176;
    leaf->fl_last_rc = -9999;
    leaf->fl_nlines = 0; leaf->fl_dcp_sum = 0; leaf->fl_ok = 0;
    leaf->fl_complete = 0; leaf->fl_truncated = 0;
    leaf->fl_att_n = 0; leaf->fl_att_calls = 0; leaf->fl_att_gap = 0; leaf->fl_att_capped = 0;
    leaf->owner_doc = (const void *)d;   /* ⏪ `T-A36`：本代驱所属 doc（附属对象查表消歧用） */
    if (rc176 != 0 || !cli) {
        g_pts_fl_gap++;
        fprintf(stderr, "[FORMATLINE] where=%s nmp=%p rc176=%d cli=%p nlines=0 calls=0 "
                        "v=NO-PARACLIENT(未驱)\n", where, (void *)leaf->nmp, rc176, cli);
        return 0;
    }
    leaf->fl_geo_src = "self-page-geometry(768x576,same-as-FsCreatePageFinite)";
    const int du = WPF_PTS_FL_DU;
    int dcp = 0; void *pbrin = NULL; int i = 0; int ended = 0;
    while (i < WPF_PTS_FL_MAXLINE) {
        void *pfsline = NULL, *ppbr = NULL;
        int dcpLine = 0, fforced = 0, fslres = -1;
        int asc = 0, desc = 0, ubb = 0, dbb = 0, dep = 0, rfmt = 0;
        int rc = fl((const void *)d->p_fsclient, (const void *)cli, (const void *)leaf->nmp,
                    0 /*iArea 恒 0（托管 Invariant.Assert(iArea==0)）*/,
                    dcp, (const void *)pbrin, 0u /*fswdir*/,
                    0, du /*urStartLine,durLine*/, 0, du /*urStartTrack,durTrack*/,
                    0 /*urPageLeftMargin*/,
                    0 /*fAllowHyphenation*/, 0 /*fClearOnLeft*/, 0 /*fClearOnRight*/,
                    (i == 0) ? 1 : 0 /*fTreatAsFirstInPara*/, 0 /*fTreatAsLastInPara*/,
                    0 /*fSuppressTopSpace*/,
                    &pfsline, &dcpLine, &ppbr, &fforced, &fslres, &asc, &desc,
                    &ubb, &dbb, &dep, &rfmt);
        leaf->fl_calls++; g_pts_fl_calls++;
        leaf->fl_last_rc = rc;
        fprintf(stderr, "[FORMATLINE-LINE] where=%s para=%p i=%d dcp=%d rc=%d pfsline=%p "
                        "dcpLine=%d fsflres=%d fforced=%d ascent=%d descent=%d urbbox=%d durbbox=%d "
                        "dep=%d rfmt=%d\n",
                where, (void *)leaf->nmp, i, dcp, rc, pfsline, dcpLine, fslres, fforced,
                asc, desc, ubb, dbb, dep, rfmt);
        if (rc != 0) break;                        /* 失败 ⇒ **不记账**（零假值） */
        if (dcpLine <= 0) break;                   /* 成环守卫：无进展 ⇒ 停（不收束） */
        leaf->fl_line[i].dcp_first   = dcp;
        leaf->fl_line[i].dcp_lim     = dcp + dcpLine;
        leaf->fl_line[i].dvr_ascent  = asc;
        leaf->fl_line[i].dvr_descent = desc;
        leaf->fl_line[i].ur_bbox     = ubb;
        leaf->fl_line[i].dur_bbox    = dbb;
        leaf->fl_line[i].fsflres     = fslres;
        leaf->fl_line[i].f_forced    = fforced;
        leaf->fl_line[i].pfsline     = pfsline;
        leaf->fl_line[i].pbr_in      = pbrin;      /* ⏪ `T-A33`：本行**入参**断行记录（回填源） */
        leaf->fl_line[i].pbr_out     = ppbr;       /* ⏪ `T-A33`：本行**产出**断行记录（真返回值） */
        /* ── ⏪ `T-A36`（`NATIVE-PTS-ATTACHED-OBJECTS-BACKFILL`）：**窗内**为附属对象建台账 ───────
           对刚排出的这一行：① 问托管「该行附着几个附属对象（`Figure`/`Floater`）」（`num`，`+512`）；
           ② 有 >0 则取对象名／`idobj`／锚点（`objects`，`+520`）；③ 为每个附属对象段落**在窗内**造
           `FigureParaClient`/`FloaterParaClient`（`+176`，承 `T-A33`（丙）窗内纪律：只在格式窗内发调）；
           ④ 记入 `leaf->fl_att[]`。**零假值**：任一 `rc≠0` ⇒ 该行不记账（`fl_att_gap++`，绝不伪填）；
           `rc=0 ∧ cAtt==0` ⇒ **真 0**（不记条、不算失败）。 */
        {
            const void *fpNum = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETNUMATTACHLINE);
            const void *fpObj = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETATTACHLINE);
            const void *fpFigProps = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETFIGUREPROPERTIES);
            /* ⏪ `T-A52`：`pfnGetObjectHandlerInfo`（`Pts.cs:659`，`cbkobj` 第 8 槽／快照下标 70）——
               本增量用它**按对象身份**向托管索取 Floater 的 handler（`idobj==FloaterParagraphId`）
               ⇒ 托管转调 `GetFloaterHandlerInfo` ⇒ 本侧捕获 `FSFLOATERCBK`（后续发调源）。 */
            const void *fpObjHandler = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETOBJHANDLERINFO);
            /* ⏪ `T-A37`：内容排版**只在 Finite 页窗**驱动 —— 托管 `FigureParagraph.GetFigureProperties`
               第 113 行有 `Invariant.Assert(StructuralCache.CurrentFormatContext.FinitePage)`（不可捕获
               `FailFast`）⇒ 在 Bottomless 窗发调必 abort。`where` 即窗名（唯一来源）。 */
            const int win_finite = (strcmp(where, "FsCreatePageFinite") == 0);
            const int rcf_enabled = wpf_pts_att_content_gate();
            int cAtt = -1, rcNum = -9999, rcObj = -9999;
            leaf->fl_att_calls++;
            if (fpNum && pfsline)
                rcNum = ((wpf_pts_fn_get_num_attach_in_line)fpNum)(
                    (const void *)d->p_fsclient, (const void *)pfsline, (const void *)leaf->nmp,
                    leaf->fl_line[i].dcp_first, leaf->fl_line[i].dcp_lim, 0, 0, &cAtt);
            if (rcNum != 0) { leaf->fl_att_gap++; }
            else if (cAtt > 0 && fpObj) {
                void *objs[WPF_PTS_FL_ATT_MAX]; int idobjs[WPF_PTS_FL_ATT_MAX];
                int anch[WPF_PTS_FL_ATT_MAX]; int cGot = -1;
                if (cAtt > WPF_PTS_FL_ATT_MAX) { leaf->fl_att_capped++; cAtt = WPF_PTS_FL_ATT_MAX; }
                rcObj = ((wpf_pts_fn_get_attach_in_line)fpObj)(
                    (const void *)d->p_fsclient, (const void *)pfsline, (const void *)leaf->nmp,
                    leaf->fl_line[i].dcp_first, leaf->fl_line[i].dcp_lim, 0, 0, cAtt,
                    objs, idobjs, anch, &cGot);
                if (rcObj != 0) { leaf->fl_att_gap++; }
                else {
                    for (int a = 0; a < cGot && leaf->fl_att_n < WPF_PTS_FL_ATT_MAX; a++) {
                        int slot = leaf->fl_att_n++;
                        leaf->fl_att[slot].nmp_obj    = objs[a];
                        leaf->fl_att[slot].idobj      = idobjs[a];
                        leaf->fl_att[slot].dcp_anchor = anch[a];
                        leaf->fl_att[slot].line_idx   = i;
                        leaf->fl_att[slot].obj_client = NULL;
                        leaf->fl_att[slot].obj_rc     = -9999;
                        leaf->fl_att[slot].content_rc = -9999;
                        leaf->fl_att[slot].sub_obj    = NULL;
                        if (objs[a] && fp176 && d->in_win) {
                            void *oc = NULL;
                            int rco = ((wpf_pts_fn_create_paraclient)fp176)(
                                (const void *)d->p_fsclient, (const void *)objs[a], &oc);
                            leaf->fl_att[slot].obj_client = oc;
                            leaf->fl_att[slot].obj_rc     = rco;
                            /* ── ⏪ `T-A37`：**驱动附属对象内容排版**（照 `T-A33` 回填体例）──────────
                               `+176` 造出客户端之后，**同窗内**调内容排版回调（`pfnGetFigureProperties`，
                               `+608`）—— 该回调**无条件** `PTS.Validate(PTS.FsCreateSubpageFinite(...))`
                               （`FigureParagraph.cs:168/211`），本侧由 `FsCreateSubpageFinite` 真造子页
                               （窗内枚举内容段 ＋ `+176` 造容器段客户端）。**零假值**：`rc≠0` ⇒ 不记子页。 */
                            if (rcf_enabled && rco == 0 && oc && win_finite && idobjs[a] == -2 && fpFigProps) {
                                const int sp_before = g_pts_sp_created;
                                int dur = 0, dvr = 0, cpoly = 0, cvert = 0, d1 = 0, d2 = 0, d3 = 0, d4 = 0;
                                unsigned char figprops[32];
                                memset(figprops, 0, sizeof(figprops));
                                int rcf = ((wpf_pts_fn_get_figure_properties)fpFigProps)(
                                    (const void *)d->p_fsclient, (const void *)oc, (const void *)objs[a],
                                    1 /*fInTextLine*/, 0u /*fswdir*/, 0 /*fBottomUndefined*/,
                                    &dur, &dvr, (void *)figprops, &cpoly, &cvert, &d1, &d2, &d3, &d4);
                                leaf->fl_att[slot].content_rc = rcf;
                                if (g_pts_sp_created > sp_before && g_pts_sp_live_n > 0)
                                    leaf->fl_att[slot].sub_obj = g_pts_sp_live[g_pts_sp_live_n - 1];
                                fprintf(stderr, "[FSATT-CONTENT] where=%s figure=%p client=%p rc=%d dur=%d dvr=%d "
                                                "cPolygons=%d cVertices=%d subpage=%p sp_created=%d v=%s\n",
                                        where, (void *)objs[a], oc, rcf, dur, dvr, cpoly, cvert,
                                        (void *)(leaf->fl_att[slot].sub_obj
                                                 ? wpf_pts_sp_handle(leaf->fl_att[slot].sub_obj) : NULL),
                                        g_pts_sp_created,
                                        (rcf == 0 && leaf->fl_att[slot].sub_obj) ? "SUBPAGE-CREATED"
                                          : (rcf == 0) ? "RC0-NO-SUBPAGE"
                                          : (rcf == -100002) ? "CALLBACK-ERR(-100002)"
                                          : (rcf == -10000) ? "NOT-IMPLEMENTED" : "OTHER");
                            }
                            /* ── ⏪ `T-A52`（`NATIVE-PTS-FLOATERCBK`）：**驱动 Floater 内容排版** ──────────
                               `+176` 造出 `FloaterParaClient` 之后，**同窗内**：① 调 `pfnGetObjectHandlerInfo`
                               （`idobj == FloaterParagraphId`）⇒ 托管转调 `GetFloaterHandlerInfo` ⇒ 本侧捕获
                               `FSFLOATERCBK`；② 调 `pfnFormatFloaterContentFinite`（槽 1）—— 该回调内
                               `FloaterParagraph.CreateSubpageFiniteHelper` **无条件**
                               `PTS.Validate(PTS.FsCreateSubpageFinite(...))`（`FloaterParagraph.cs:237/287`），
                               本侧由 `FsCreateSubpageFinite` 真造内容子页并把句柄交回（托管置
                               `FloaterParaClient.SubpageHandle` ⇒ `_paraHandle`）。
                               **零假值**：`rch≠0` 或槽 1 空 ⇒ **不发调**（具名留痕）；`rc≠0` ⇒ **不记子页**。 */
                            else if (rcf_enabled && wpf_pts_floater_cbk_gate() && rco == 0 && oc && win_finite &&
                                     idobjs[a] == WPF_PTS_FLOATER_ID && fpObjHandler) {
                                g_pts_floater_drv_calls++;
                                unsigned char objinfo[WPF_PTS_FLOATERCBK_SLOTS * 8];
                                memset(objinfo, 0, sizeof(objinfo));
                                int rch = ((wpf_pts_fn_get_object_handler_info)fpObjHandler)(
                                    (const void *)d->p_fsclient, WPF_PTS_FLOATER_ID, (void *)objinfo);
                                int rcf2 = -9999;
                                if (rch == 0 && g_pts_floater_cbk[WPF_PTS_FLOATER_IDX_FMT_FINITE]) {
                                    const int sp_before = g_pts_sp_created;
                                    int fsfmtr[3] = { 0, 0, 0 };
                                    unsigned char fsbbox[20];
                                    void *pfsc = NULL, *pbrk = NULL;
                                    int durw = 0, dvrh = 0, cpoly = 0, cvert = 0;
                                    memset(fsbbox, 0, sizeof(fsbbox));
                                    rcf2 = ((wpf_pts_fn_format_floater_content_finite)
                                            g_pts_floater_cbk[WPF_PTS_FLOATER_IDX_FMT_FINITE])(
                                        (const void *)d->p_fsclient, (const void *)oc, NULL, 0,
                                        (const void *)objs[a], NULL, 1 /*fEmptyOk*/, 0 /*fSuppressTopSpace*/,
                                        0u /*fswdir*/, 1 /*fAtMaxWidth*/, WPF_PTS_FLOATER_AVAIL_DU, WPF_PTS_FLOATER_AVAIL_DV,
                                        0 /*fsksuppress*/, (void *)fsfmtr, &pfsc, &pbrk,
                                        &durw, &dvrh, (void *)fsbbox, &cpoly, &cvert);
                                    leaf->fl_att[slot].content_rc = rcf2;
                                    if (g_pts_sp_created > sp_before && g_pts_sp_live_n > 0)
                                        leaf->fl_att[slot].sub_obj = g_pts_sp_live[g_pts_sp_live_n - 1];
                                    if (rcf2 == 0 && leaf->fl_att[slot].sub_obj) g_pts_floater_drv_ok++;
                                    else g_pts_floater_drv_gap++;
                                    fprintf(stderr, "[FSFLOATER-CONTENT] where=%s floater=%p client=%p "
                                                    "rch=%d rc=%d kstop=%d durW=%d dvrH=%d cPoly=%d cVert=%d "
                                                    "pfsFloatContent=%p subpage=%p sp_created=%d v=%s\n",
                                            where, (void *)objs[a], oc, rch, rcf2, fsfmtr[0], durw, dvrh,
                                            cpoly, cvert, pfsc,
                                            (void *)(leaf->fl_att[slot].sub_obj
                                                     ? wpf_pts_sp_handle(leaf->fl_att[slot].sub_obj) : NULL),
                                            g_pts_sp_created,
                                            (rcf2 == 0 && leaf->fl_att[slot].sub_obj) ? "SUBPAGE-CREATED"
                                              : (rcf2 == 0) ? "RC0-NO-SUBPAGE"
                                              : (rcf2 == -100002) ? "CALLBACK-ERR(-100002)"
                                              : (rcf2 == -10000) ? "NOT-IMPLEMENTED" : "OTHER");
                                } else {
                                    g_pts_floater_drv_gap++;
                                    fprintf(stderr, "[FSFLOATER-CONTENT] where=%s floater=%p client=%p "
                                                    "rch=%d rc=%d v=%s\n",
                                            where, (void *)objs[a], oc, rch, rcf2,
                                            (rch != 0) ? "HANDLER-ERR" : "NO-CBK");
                                }
                                /* ⏪ `T-A53`（`NATIVE-PTS-TABLEOBJ`）：Floater 内容子页若含**表段落**
                                   ⇒ **窗内**建本侧表模型（`T-A54` 起闸 `WPF_PTS_TABLEOBJ` **缺省开**）。 */
                                if (rcf2 == 0 && leaf->fl_att[slot].sub_obj && wpf_pts_tableobj_gate())
                                    wpf_pts_tableobj_drive(d, leaf->fl_att[slot].sub_obj, where);
                            }
                        } else if (objs[a]) {
                            leaf->fl_att[slot].obj_rc = -7777;   /* 窗外 ⇒ 拒发（具名；不撞 FailFast） */
                        }
                    }
                }
            }
            fprintf(stderr, "[FSATT-PROBE] where=%s para=%p i=%d pfsline=%p rcNum=%d rcObj=%d cAtt=%d "
                            "fl_att_n=%d gap=%d capped=%d att0_obj=%p att0_id=%d att0_rc=%d doc=%p\n",
                    where, (void *)leaf->nmp, i, pfsline, rcNum, rcObj, cAtt,
                    leaf->fl_att_n, leaf->fl_att_gap, leaf->fl_att_capped,
                    leaf->fl_att_n > 0 ? leaf->fl_att[0].nmp_obj : NULL,
                    leaf->fl_att_n > 0 ? leaf->fl_att[0].idobj : 0,
                    leaf->fl_att_n > 0 ? leaf->fl_att[0].obj_rc : -9999,
                    (void *)leaf->owner_doc);
        }
        leaf->fl_nlines++;
        dcp += dcpLine;
        i++;
        if (fslres == 2 || fslres == 3 || fslres == 4 || fslres == 5) { ended = 1; break; }
        if (ppbr) pbrin = ppbr;
        if (i >= WPF_PTS_FL_MAXLINE) break;
    }
    leaf->fl_dcp_sum = dcp;
    if (i >= WPF_PTS_FL_MAXLINE && !ended) { leaf->fl_truncated = 1; g_pts_fl_incomplete++; }
    else if (!ended && leaf->fl_nlines > 0) { g_pts_fl_incomplete++; }
    leaf->fl_complete = ended;
    leaf->fl_ok = (leaf->fl_nlines > 0 && ended && !leaf->fl_truncated) ? 1 : 0;
    if (leaf->fl_ok) g_pts_fl_ok++; else g_pts_fl_gap++;
    if (fp192 && cli) {
        int rcr = ((wpf_pts_fn_destroy_paraclient)fp192)((const void *)d->p_fsclient, (const void *)cli);
        (void)rcr;
    }
    fprintf(stderr, "[FORMATLINE] where=%s para=%p nmp=%p du=%d nlines=%d dcp_sum=%d last_rc=%d "
                    "complete=%d truncated=%d v=%s geo=%s\n",
            where, (void *)leaf, (void *)leaf->nmp, du, leaf->fl_nlines, leaf->fl_dcp_sum,
            leaf->fl_last_rc, leaf->fl_complete, leaf->fl_truncated,
            leaf->fl_ok ? "LINES-RECORDED" : "NO-COMPLETE-LINES", leaf->fl_geo_src);
    return leaf->fl_ok;
}

static int wpf_pts_fl_walk(wpf_pts_doc *d, wpf_pts_subtrack *o, const void *fpFL,
                           const void *fp176, const void *fp192, const char *where, int depth)
{
    if (!o || o->magic != WPF_PTS_SUB_MAGIC || depth > WPF_PTS_SUB_MAX_DEPTH) return 0;
    if (o->enum_ok == 0) {                       /* 叶 ⇒ `TextParagraph` 类（+136 不成立） */
        if (g_pts_fl_win_paras >= WPF_PTS_FL_MAX_PARA) return 0;
        g_pts_fl_win_paras++;
        return wpf_pts_format_one_para(d, o, fpFL, fp176, fp192, where);
    }
    int n = 0;
    for (int k = 0; k < WPF_PTS_SUB_CHILD_MAX; k++) {
        if (!o->child_objs[k]) continue;
        if (g_pts_fl_win_paras >= WPF_PTS_FL_MAX_PARA) break;
        n += wpf_pts_fl_walk(d, o->child_objs[k], fpFL, fp176, fp192, where, depth + 1);
    }
    return n;
}

/* ⏪ `T-A37`：**附属对象内容子树**的窗内行驱动（预算与主树**分开** ⇒ 不挤占主树配额）。 */
#define WPF_PTS_FL_MAX_PARA_C 24
static int g_pts_fl_win_paras_c = 0;
static int wpf_pts_fl_walk_c(wpf_pts_doc *d, wpf_pts_subtrack *o, const void *fpFL,
                             const void *fp176, const void *fp192, const char *where, int depth)
{
    if (!o || o->magic != WPF_PTS_SUB_MAGIC || depth > WPF_PTS_SUB_MAX_DEPTH) return 0;
    if (o->enum_ok == 0) {
        if (g_pts_fl_win_paras_c >= WPF_PTS_FL_MAX_PARA_C) return 0;
        g_pts_fl_win_paras_c++;
        return wpf_pts_format_one_para(d, o, fpFL, fp176, fp192, where);
    }
    int n = 0;
    for (int k = 0; k < WPF_PTS_SUB_CHILD_MAX; k++) {
        if (!o->child_objs[k]) continue;
        if (g_pts_fl_win_paras_c >= WPF_PTS_FL_MAX_PARA_C) break;
        n += wpf_pts_fl_walk_c(d, o->child_objs[k], fpFL, fp176, fp192, where, depth + 1);
    }
    return n;
}

/* ── ⏪ `T-A56`：**单元内容高**（内容树逐叶段 Σ 行 `dvrAscent+dvrDescent`；`pfnFormatLine` **真台账**）──
   用于 ① **窗内**把行高告知单元（`pfnSetCellHeight`，`SetCellHeight` 只许在格式窗内发调 —— 实测
   窗外调它撞 `PtsHost.get_PtsContext()` 的 `Invariant.FailFast`）；② **查询期**由同一台账重算行高。
   **零假值**：无可用台账（`fl_ok!=1`／0 行／未收束／撞界）⇒ 返 `-1`。 */
static int wpf_pts_tbl_cell_tree_dv(const wpf_pts_subtrack *root)
{
    if (!root) return -1;
    int total = 0, got = 0;
    wpf_pts_subtrack *stack[WPF_PTS_SUB_MAX]; int sp = 0;
    stack[sp++] = (wpf_pts_subtrack *)root;
    while (sp > 0) {
        wpf_pts_subtrack *o = stack[--sp];
        int nc = (o->enum_ok) ? o->c_paras : 0;
        if (nc == 0) {                                   /* 叶 ⇒ `TextParagraph` 类 */
            if (o->fl_ok == 1 && o->fl_nlines > 0 && o->fl_complete && !o->fl_truncated) {
                for (int k = 0; k < o->fl_nlines; k++)
                    total += o->fl_line[k].dvr_ascent + o->fl_line[k].dvr_descent;
                got = 1;
            }
            continue;
        }
        for (int k = 0; k < nc && k < WPF_PTS_SUB_CHILD_MAX; k++)
            if (o->child_objs[k] && sp < WPF_PTS_SUB_MAX) stack[sp++] = o->child_objs[k];
    }
    return got ? total : -1;
}

/* 窗内驱动入口（**只**从 `wpf_pts_drive_probe` 调；窗内 ＝ `FsCreatePage*` 调用期）。 */
static void wpf_pts_formatline_drive(wpf_pts_doc *d, const char *where)
{
    if (!wpf_pts_fl_enabled()) {
        g_pts_fl_last_v = "GATE-OFF";
        fprintf(stderr, "[FORMATLINE] where=%s window=in gate=0 v=GATE-OFF（仅显式 `WPF_PTS_FL_DRIVE=0` 才关；缺省已开）"
                        " calls=%d ok=%d gap=%d\n", where, g_pts_fl_calls, g_pts_fl_ok, g_pts_fl_gap);
        return;
    }
    const void *fpFL  = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_FORMATLINE);
    const void *fp176 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_CREATEPARACLIENT);
    const void *fp192 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_DESTROYPARACLIENT);
    int driven = 0;
    if (!fpFL)              { g_pts_fl_nopara++; g_pts_fl_last_v = "SKIP-NO-FORMATLINE-SLOT"; }
    else if (!fp176)        { g_pts_fl_nopara++; g_pts_fl_last_v = "SKIP-NO-CLIENT-SLOT"; }
    else if (d->sub_child_objs_n <= 0) { g_pts_fl_nopara++; g_pts_fl_last_v = "SKIP-NO-SUBTREE"; }
    else {
        g_pts_fl_win_paras = 0; g_pts_fl_win_attempt = 0;
        for (int j = 0; j < d->sub_child_objs_n && j < WPF_PTS_SUB_CHILD_MAX; j++) {
            if (!d->sub_child_objs[j]) continue;
            if (g_pts_fl_win_paras >= WPF_PTS_FL_MAX_PARA) break;
            driven += wpf_pts_fl_walk(d, d->sub_child_objs[j], fpFL, fp176, fp192, where, 1);
        }
        if (g_pts_fl_win_attempt > 0) { g_pts_fl_paras += g_pts_fl_win_attempt; g_pts_fl_last_v = "DRIVEN"; }
        else                          { g_pts_fl_nopara++; g_pts_fl_last_v = "NO-TEXT-PARA-IN-WINDOW"; }
    }
    /* ⏪ `T-A37`：**附属对象内容子树**的行排版驱动（窗内；预算与主树分开）—— 主树驱动**之后**做，
       因为子页对象是在主树驱动的附属对象循环里现造的（`FsCreateSubpageFinite`）。 */
    int c_driven = 0;
    if (fpFL && fp176) {
        g_pts_fl_win_paras_c = 0;
        for (int i = 0; i < g_pts_sp_live_n; i++) {
            struct wpf_pts_subpage_s *s = g_pts_sp_live[i];
            if (!s || s->magic != WPF_PTS_SP_MAGIC) continue;
            if (s->ctx != (const void *)d) continue;
            if (!s->cont_obj) continue;
            c_driven += wpf_pts_fl_walk_c(d, s->cont_obj, fpFL, fp176, fp192, where, 1);
        }
    }
    if (c_driven > 0 || g_pts_sp_live_n > 0)
        fprintf(stderr, "[FORMATLINE-CONTENT] where=%s c_driven=%d c_paras=%d sp_live=%d sp_created=%d v=%s\n",
                where, c_driven, g_pts_fl_win_paras_c, g_pts_sp_live_n, g_pts_sp_created,
                c_driven > 0 ? "CONTENT-LINES-DRIVEN" : "NO-CONTENT-LEAF-DRIVEN");
    fprintf(stderr, "[FORMATLINE] where=%s window=in gate=1 slot=%p attempted=%d ok_n=%d paras_total=%d calls=%d "
                    "ok=%d gap=%d incomplete=%d nopara=%d v=%s geo=NOINFO-FSGEOMETRY-LAYOUT\n",
            where, fpFL, g_pts_fl_win_attempt, driven, g_pts_fl_paras, g_pts_fl_calls, g_pts_fl_ok,
            g_pts_fl_gap, g_pts_fl_incomplete, g_pts_fl_nopara, g_pts_fl_last_v);
}


/* ⏪ `t151`：**窗外腿**（判据 §8.2 的成对实验反腿）—— 用**同一个**真 `nms` 在**窗外**调 `+136`。
   🔴 ⏪ `T-A22`（`N2`：`PRECOND-WINDOW-SEPARATION`）**现取改写**：本条**不再发 `+136` 回调** ——
     窗外（查询期）**只做汇总/拒绝并留痕**（`[WINDOW-SPLIT] window=out`），**窗内**（`FsCreatePage*`）
     才真枚举/真填（`[WINDOW-SPLIT] window=in`）。原形态（窗外真调 `+136` ⇒ `rc=-100002` ×576，
     `v136=CALLBACK-ERR(-100002)`）属"**注定失败的发调**"，该形态**不可判** ⇒ 本件改为**可判**的成对读数。 */
/* ⏪ `T-A33`：**托管 `+176 CreateParaclient` 的发调闸**。`+176` 是**托管回调** ⇒ 需
   `PtsHost._ptsContext != null`；该上下文只在**格式窗**（`FsCreatePage*` ⇒ `wpf_pts_drive_probe`）
   里有效。实测（`T-A33` 腿 `legs-tlb` `app_rc=134` / `failfast=4`）：`FlowDocumentPaginator.
   OnBackgroundPagination` → `FlowDocumentPage.GetTextContentRangeFromColumn` → `PtsHelper.
   ParaListFromTrack` → 本侧 `FsQueryTrackParaList` 的"查询期 `+176`"支撞 `MS.Internal.Invariant.
   FailFast`（**不可捕获**）⇒ 整进程 `abort`。**同一线程**、只是**不在窗内**（`T-A33` 现取：
   `cur_tid == win_tid`）⇒ 判据**不是线程**、是**窗**。
   ⇒ 口径（承 `T-A17` liveness 守卫 ＋ `t151`「注定失败的发调不照发」两条先例）：
   **`+176` 只在格式窗内发调**；窗外（查询期）⇒ 本侧**拒发**（具名留痕、出参一字不写）——
   这消掉"查询期照发托管回调"这一族不可捕 `FailFast`。
   闸门变量：`WPF_PTS_QTP_INWIN`（缺省 `1`＝生效；显式 `0` ⇒ 关，回落改前，用作反极性腿）。 */
#ifndef WPF_PTS_QTP_INWIN_DEFAULT
#define WPF_PTS_QTP_INWIN_DEFAULT 1
#endif
static int wpf_pts_qtp_inwin_gate(void)
{
    static int cached = -1;
    if (cached < 0) { const char *e = getenv("WPF_PTS_QTP_INWIN"); cached = e ? atoi(e) : WPF_PTS_QTP_INWIN_DEFAULT; }
    return cached;
}
/* 返 1 ＝ 当前**可以**发托管 `+176`（在格式窗内，或闸关时不拦）。 */
static int wpf_pts_qtp_create_safe(const wpf_pts_doc *d)
{
    if (!d) return 0;
    if (!wpf_pts_qtp_inwin_gate()) return 1;    /* 闸关 ⇒ 不拦（回落改前） */
    return d->in_win ? 1 : 0;
}
/* ⏪ `T-A47`（`QTP-LIVE-NARROW`）：页销毁后**仍可服务**的充要条件 —— 见 `FsQueryTrackParaList`
   填充支里那条 `drive-handles-released(page-destroyed)` 拒因的**收窄**说明（该处给全套现取证据）。
   ⚠️ 闸门变量：`WPF_PTS_QTP_LIVE_NARROW`（缺省 `1`＝收窄生效；显式 `0` ⇒ 逐字回改前，反极性腿）。 */
#ifndef WPF_PTS_QTP_LIVE_NARROW_DEFAULT
#define WPF_PTS_QTP_LIVE_NARROW_DEFAULT 1
#endif
static int wpf_pts_qtp_live_narrow(void)
{
    static int cached = -1;
    if (cached < 0) {
        const char *e = getenv("WPF_PTS_QTP_LIVE_NARROW");
        cached = e ? atoi(e) : WPF_PTS_QTP_LIVE_NARROW_DEFAULT;
    }
    return cached;
}
/* ⏪ `T-A37`：附属对象**内容排版驱动**的运行期闸（缺省 **开**；显式 `WPF_PTS_ATT_CONTENT=0` 关 ⇒
   反极性腿：不调内容回调、不造子页 ⇒ 三色必回 0）。 */
#ifndef WPF_PTS_ATT_CONTENT_DEFAULT
#define WPF_PTS_ATT_CONTENT_DEFAULT 1
#endif
static int wpf_pts_att_content_gate(void)
{
    static int cached = -1;
    if (cached < 0) {
        const char *e = getenv("WPF_PTS_ATT_CONTENT");
        cached = e ? atoi(e) : WPF_PTS_ATT_CONTENT_DEFAULT;
    }
    return cached;
}
/* ── ⏪ `T-A52`（`NATIVE-PTS-FLOATERCBK`）：Floater **内容排版驱动**的运行期闸（`T-A54` 起缺省 **开**）──────
   🔴 **`T-A52` 当年缺省关是现场读数逼出来的**（不是保守）：
     Floater（`<Floater>`）的内容在本页是一个 `<Table>`（`LightGoldenrodYellow` ＝ 其 `<TableRow Background>`）。
     一旦驱动 `pfnFormatFloaterContentFinite` 把内容子页真造出，托管 `FloaterParaClient.ValidateVisual`
     ⇒ `PtsHelper.UpdateTrackVisuals` **会下到 Table 段落** ⇒ `TableParaClient.QueryTableDetails`
     ⇒ `PTS.FsQueryTableObjDetails`（当时本移植**未导出**）⇒ `EntryPointNotFoundException`（**不可捕**）
     ⇒ `FlowDocumentView.ArrangeOverride` 抛（现取 `[FSVIEW] … outcome=exception type=System.EntryPointNotFoundException`）
     ⇒ 整页**空白**（现取 `k24 colors 905→383`、`fr_sha 791696291d51470b→ef3fd6765f18f51b`（空态参照成员）、
     `[HC-UNHANDLED] 0→392`）。⇒ 该驱动**只在** Table 族落地后才准缺省开（下一增量 `NATIVE-PTS-TABLEOBJ`）。
   ⏪ `T-A54`：该前置已由 `T-A53` 落地（Table 族五入口 ＋ `GetTableObjHandlerInfo`／`FSTABLEOBJCBK`；
     `entry point named 'FsQueryTableObjDetails'` 归 **0**、开闸腿 `LightGoldenrodYellow=1998 px`）
     ⇒ 本增量照 `T-A28→T-A31` 体例**把闸翻为缺省开**，使**缺省路径**即含第 4 色；
     闸：显式 `WPF_PTS_FLOATER_CBK=0` ⇒ 关（**反极性腿**）；缺省 `1` ⇒ 开。 */
#ifndef WPF_PTS_FLOATER_CBK_DEFAULT
#define WPF_PTS_FLOATER_CBK_DEFAULT 1
#endif
static int wpf_pts_floater_cbk_gate(void)
{
    static int cached = -1;
    if (cached < 0) {
        const char *e = getenv("WPF_PTS_FLOATER_CBK");
        cached = e ? atoi(e) : WPF_PTS_FLOATER_CBK_DEFAULT;
    }
    return cached;
}

/* ── ⏪ `T-A53`（`NATIVE-PTS-TABLEOBJ`）：**Table 族驱动**的运行期闸（`T-A54` 起缺省 **开**）──────────────
   闸控的是"**窗内为 Floater 内容子页里的表段落建本侧表模型**"（`wpf_pts_tableobj_drive`）。
   ⏪ `T-A54`：`T-A53` 当年缺省关，是为使缺省路径**逐格不变**（零回归）；Table 族已真服务且开闸腿
     第 4 色 `LightGoldenrodYellow=1998 px` ⇒ 本增量照 `T-A28→T-A31` 体例**翻为缺省开**，使**缺省路径**即含第 4 色。
   闸：显式 `WPF_PTS_TABLEOBJ=0` ⇒ 关（**反极性腿**）；缺省 `1` ⇒ 开。 */
#ifndef WPF_PTS_TABLEOBJ_DEFAULT
#define WPF_PTS_TABLEOBJ_DEFAULT 1
#endif
static int wpf_pts_tableobj_gate(void)
{
    static int cached = -1;
    if (cached < 0) {
        const char *e = getenv("WPF_PTS_TABLEOBJ");
        cached = e ? atoi(e) : WPF_PTS_TABLEOBJ_DEFAULT;
    }
    return cached;
}

/* ── ⏪ `T-A56`（表单元内容排版）：**单元内容排版**的运行期闸（`T-A57` 起缺省 **开**）──────────────
   闸控的是"**窗内为表模型的每一行逐格调 `pfnFormatCellFinite` 真造单元内容子页**"。
   ⏪ `T-A57`：`T-A56` 当年缺省关，为使缺省路径**逐格不变**（零回归）；单元内容排版已真落像素
     （开闸腿 `LightGoldenrodYellow 1998→5830 px`，表区 `dark(<140)` `+1449 px`）⇒ 本增量照
     `T-A28→T-A31` 体例**翻为缺省开**，使**缺省路径**即含表单元内容。
   闸：显式 `WPF_PTS_TABLECELL=0` ⇒ 关（**反极性腿**）；缺省 `1` ⇒ 开。 */
#ifndef WPF_PTS_TABLECELL_DEFAULT
#define WPF_PTS_TABLECELL_DEFAULT 1
#endif
static int wpf_pts_tablecell_gate(void)
{
    static int cached = -1;
    if (cached < 0) {
        const char *e = getenv("WPF_PTS_TABLECELL");
        cached = e ? atoi(e) : WPF_PTS_TABLECELL_DEFAULT;
    }
    return cached;
}

/* ── ⏪ `T-A53`：**窗内**为 `FsCreateSubpageFinite` 真造出的内容子页里的**表段落**建本侧表模型 ──────────
   路径（逐跳，全部在窗内）：
     ① 在子页内容树里找 `idobj==TableParagraphId(3)` 的段（窗内 `+168 pfnGetParaProperties` 读 `FSPAP.idobj`）；
     ② 调 `+600 pfnGetObjectHandlerInfo(fsclient, 3, buf)` ⇒ 托管转调 `GetTableObjHandlerInfo`
        ⇒ 本侧捕获 `FSTABLEOBJINIT`（`g_pts_tableobj_cbk[]`，后续发调源）；
     ③ 窗内 `+176 pfnCreateParaclient(nmTable)` 现造 `TableParaClient`（**保留不回收**，同 `t160` 体例）；
     ④ 调 `pfnAutofitTable`（置托管 `_calculatedColumns` ⇒ `ValidateVisual` 的 `Invariant.Assert` 才成立）；
     ⑤ 循环 `pfnGetFirstRow`／`pfnGetNextRow` 取行句柄；每行调 `pfnGetRowProperties` 取 `cCells`／行距；
     ⑥ 入册本侧表模型（键＝`nmTable`）。
   🔴 **零假值 / 永不假成功**：任一 `rc≠0` ⇒ **该跳不记账**（具名留痕，绝不伪填）；行高只由
      `pfnGetRowProperties` 原值派生（不足下界 ⇒ 取本侧下界并**具名** `NOINFO=row-height-self-convention`）。
   ⚠️ 本侧**不**调 `pfnFormatCellFinite`（单元内容不在本增量射程）⇒ 行详情一律报 `cCells=0`（**诚实的空**：本侧确未排单元）。 */
static wpf_pts_tbl_model *wpf_pts_tbl_find(const void *nm_table)
{
    for (int i = 0; i < g_pts_tbl_n; i++)
        if (g_pts_tbl[i].magic == WPF_PTS_TBL_MAGIC && g_pts_tbl[i].nm_table == nm_table) return &g_pts_tbl[i];
    return NULL;
}
static wpf_pts_tbl_model *wpf_pts_tbl_find_proper(const void *pfstableproper)
{
    for (int i = 0; i < g_pts_tbl_n; i++)
        if (g_pts_tbl[i].magic == WPF_PTS_TBL_MAGIC && g_pts_tbl[i].pfstableproper == pfstableproper) return &g_pts_tbl[i];
    return NULL;
}
static wpf_pts_tbl_row *wpf_pts_tbl_find_row(const void *pfstablerow)
{
    for (int i = 0; i < g_pts_tbl_n; i++) {
        if (g_pts_tbl[i].magic != WPF_PTS_TBL_MAGIC) continue;
        for (int r = 0; r < g_pts_tbl[i].nrows; r++)
            if (g_pts_tbl[i].rows[r].pfstablerow == pfstablerow) return &g_pts_tbl[i].rows[r];
    }
    return NULL;
}
static void wpf_pts_tableobj_drive(wpf_pts_doc *d, struct wpf_pts_subpage_s *s, const char *where)
{
    g_pts_tbl_drv_calls++;
    if (!d || !s || !s->cont_obj) { g_pts_tbl_drv_gap++; return; }
    const void *fp168 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETPARAPROPERTIES);
    const void *fpHandler = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETOBJHANDLERINFO);
    const void *fp176 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_CREATEPARACLIENT);
    if (!fp168 || !fpHandler || !fp176) {
        g_pts_tbl_drv_gap++;
        fprintf(stderr, "[FSTABLEOBJ-DRV] where=%s v=SKIP-NO-SLOT fp168=%p handler=%p fp176=%p\n",
                where, fp168, fpHandler, fp176);
        return;
    }
    /* ① 找表段落（窗内读 `idobj`） */
    const void *nm_table = NULL;
    wpf_pts_subtrack *stack[WPF_PTS_SUB_MAX]; int sp_n = 0;
    stack[sp_n++] = s->cont_obj;
    while (sp_n > 0 && !nm_table) {
        wpf_pts_subtrack *o = stack[--sp_n];
        int nc = (o->enum_ok) ? o->c_paras : 0;
        for (int k = 0; k < nc && k < WPF_PTS_SUB_CHILD_MAX; k++) {
            const void *child = o->children[k];
            if (!child) continue;
            int fspap[4] = { 0, 0, 0, 0 };
            int rc = ((wpf_pts_fn_get_para_properties)fp168)((const void *)d->p_fsclient, child, (void *)fspap);
            if (rc == 0 && fspap[0] == WPF_PTS_TABLE_ID) { nm_table = child; break; }
            if (o->child_objs[k] && sp_n < WPF_PTS_SUB_MAX) stack[sp_n++] = o->child_objs[k];
        }
    }
    if (!nm_table) {
        g_pts_tbl_drv_gap++;
        fprintf(stderr, "[FSTABLEOBJ-DRV] where=%s v=NO-TABLE-PARA cparas=%d\n",
                where, s->cont_obj->enum_ok ? s->cont_obj->c_paras : -1);
        return;
    }
    /* 幂等／换代：同表（同段落句柄）已有模型 ⇒ **重建行** —— 窗口可多次进入，行句柄必须取
       **当前一代**；旧一代的行对象可能已被托管释放、其句柄被回收成别类对象
       （实测：`UpdateChunkInfo` 的 `InvalidCastException: Line → RowParagraph`）⇒ 必须换代。 */
    wpf_pts_tbl_model *m = wpf_pts_tbl_find(nm_table);
    int is_new = 0;
    if (!m) {
        if (g_pts_tbl_n >= WPF_PTS_TBL_MAX) {
            g_pts_tbl_drv_gap++;
            fprintf(stderr, "[FSTABLEOBJ-DRV] where=%s nmTable=%p v=TABLE-FULL n=%d\n", where, nm_table, g_pts_tbl_n);
            return;
        }
        m = &g_pts_tbl[g_pts_tbl_n];
        memset(m, 0, sizeof(*m));
        m->magic = WPF_PTS_TBL_MAGIC; m->nm_table = nm_table;
        m->pfstableproper = (const void *)&m->nm_table;
        is_new = 1;
    }
    m->nrows = 0; m->autofit_done = 0;
    /* ② 索 handler（窗内 `+600`） */
    unsigned char objinfo[WPF_PTS_TABLEOBJ_SLOTS * 8];
    memset(objinfo, 0, sizeof(objinfo));
    int rch = ((wpf_pts_fn_get_object_handler_info)fpHandler)((const void *)d->p_fsclient, WPF_PTS_TABLE_ID,
                                                              (void *)objinfo);
    if (rch != 0) {
        g_pts_tbl_drv_gap++;
        fprintf(stderr, "[FSTABLEOBJ-DRV] where=%s nmTable=%p rch=%d v=HANDLER-ERR\n", where, nm_table, rch);
        return;
    }
    /* ③ 现造表 para client（保留不回收） */
    void *tclient = NULL;
    int rcc = ((wpf_pts_fn_create_paraclient)fp176)((const void *)d->p_fsclient, nm_table, &tclient);
    if (rcc != 0 || !tclient) {
        g_pts_tbl_drv_gap++;
        fprintf(stderr, "[FSTABLEOBJ-DRV] where=%s nmTable=%p rcc=%d client=%p v=NO-TABLE-CLIENT\n",
                where, nm_table, rcc, tclient);
        return;
    }
    /* ④ Autofit（置托管 `_calculatedColumns`） */
    int wtbl = 0, rcaf = -9999;
    const void *pfAutofit = g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_AUTOFITTABLE];
    if (pfAutofit)
        rcaf = ((wpf_pts_fn_autofit_table)pfAutofit)((const void *)d->p_fsclient, tclient, nm_table,
                                                     0u /*fswdir*/, WPF_PTS_FLOATER_AVAIL_DU, &wtbl);
    /* ⑤ 取行 */
    const void *pfFirst = g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_GETFIRSTROW];
    const void *pfNext  = g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_GETNEXTROW];
    const void *pfRProps= g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_GETROWPROPS];
    /* ⏪ `T-A56`：单元内容排版的托管回调（缺省关闸 ⇒ 不用） */
    const void *pfGetCells  = g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_GETCELLS];
    const void *pfFmtCell   = g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_FMTCELLFINITE];
    const void *pfSetCellH  = g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_SETCELLHEIGHT];
    const int   cell_on     = wpf_pts_tablecell_gate();
    m->table_client = (const void *)tclient;
    m->autofit_rc = rcaf; m->autofit_width = wtbl;
    int fFound = 0; void *row = NULL;
    int rcF = (pfFirst && pfRProps) ? ((wpf_pts_fn_get_first_row)pfFirst)((const void *)d->p_fsclient,
                                                                          nm_table, &fFound, &row) : -9999;
    while (rcF == 0 && fFound == 1 && row && m->nrows < WPF_PTS_TBL_MAXROWS) {
        unsigned char rprops[44];                          /* `FSTABLEROWPROPS` ＝ 11×int ＝ 44 B */
        memset(rprops, 0, sizeof(rprops));
        int rcr = ((wpf_pts_fn_get_row_properties)pfRProps)((const void *)d->p_fsclient, row, 0u, (void *)rprops);
        if (rcr != 0) { g_pts_tbl_drv_gap++; break; }
        const int *rp = (const int *)rprops;
        int c_cells    = rp[10];                           /* cCells（第 11 个 int） */
        int dvr_above  = rp[4];                            /* dvrAboveRow */
        int dvr_below  = rp[5];                            /* dvrBelowRow */
        int dvr_restr  = rp[2];                            /* dvrRowHeightRestriction */
        int dvr_row = (dvr_restr > 0) ? dvr_restr : (dvr_above + dvr_below);
        if (dvr_row < WPF_PTS_TBL_DVR_MIN) dvr_row = WPF_PTS_TBL_DVR_MIN;
        wpf_pts_tbl_row *rr = &m->rows[m->nrows];
        rr->nm_row = row; rr->pfstablerow = (const void *)&rr->nm_row;
        rr->dvr_above = dvr_above; rr->dvr_below = dvr_below;
        rr->n_cells = 0;
        /* ── ⏪ `T-A56`：**单元内容排版**（缺省关闸）─────────────────────────────────
           逐格：① `pfnGetCells`（槽 17）取 `nmCell`（托管 `CellParagraph` 句柄）；② `pfnFormatCellFinite`
           （槽 20）**真造**单元内容子页（托管 `CellParagraph.FormatCellFinite` ⇒ `FsCreateSubpageFinite`），
           返回 `ppfscell`（`CellParaClient` 句柄）与 `dvrUsed`（⚠️ 本侧 `FsCreateSubpageFinite` 恒报
           `dvrUsed=lHeight` ⇒ **不是**内容真高 ⇒ 本侧**不**用它做行高；行高改在**查询期**由单元内容台账派生，
           见 `wpf_pts_tbl_row_dvr`）。
           **零假值**：`pfnGetCells rc≠0`／任一格 `pfnFormatCellFinite rc≠0` 或 `ppfscell==NULL`
           ⇒ 本行 `n_cells=0`（**不记**，行详情报 `cCells=0` 的**诚实的空**）。 */
        if (cell_on && c_cells > 0 && pfGetCells && pfFmtCell) {
            int nc = (c_cells < WPF_PTS_TBL_MAXCELLS) ? c_cells : WPF_PTS_TBL_MAXCELLS;
            void *nmcells[WPF_PTS_TBL_MAXCELLS];
            int   kmerge[WPF_PTS_TBL_MAXCELLS];
            for (int c = 0; c < WPF_PTS_TBL_MAXCELLS; c++) { nmcells[c] = NULL; kmerge[c] = 0; }
            int rcg = ((wpf_pts_fn_get_cells)pfGetCells)((const void *)d->p_fsclient, row, c_cells,
                                                         nmcells, kmerge);
            if (rcg != 0) {
                g_pts_tbl_cell_gap++;
                fprintf(stderr, "[FSTABLECELL] where=%s row=%p cCells=%d rc=%d v=GETCELLS-ERR\n",
                        where, row, c_cells, rcg);
            } else {
                int all_ok = 1, made = 0;
                for (int c = 0; c < nc; c++) {
                    if (!nmcells[c]) { all_ok = 0; break; }
                    int fsfmtr[3] = { 0, 0, 0 };
                    void *pfscell = NULL, *brkout = NULL;
                    int dvr_used = 0;
                    const int sp_before = g_pts_sp_created;
                    int rcf = ((wpf_pts_fn_format_cell_finite)pfFmtCell)(
                        (const void *)d->p_fsclient, (const void *)tclient, NULL,
                        (const void *)nmcells[c], NULL, 1 /*fEmptyOk*/, 0u /*fswdirTable*/,
                        0 /*dvrExtraHeight*/, WPF_PTS_FLOATER_AVAIL_DV,
                        (void *)fsfmtr, &pfscell, &brkout, &dvr_used);
                    rr->cells[c].nm_cell    = nmcells[c];
                    rr->cells[c].kcellmerge = kmerge[c];
                    rr->cells[c].fmt_rc     = rcf;
                    if (rcf != 0 || !pfscell) {
                        all_ok = 0;
                        fprintf(stderr, "[FSTABLECELL] where=%s row=%p i=%d cell=%p rc=%d pfscell=%p "
                                        "v=FORMATCELL-%s\n",
                                where, row, c, nmcells[c], rcf, pfscell,
                                (rcf == 0) ? "EMPTY-OUT" : (rcf == -100002) ? "CALLBACK-ERR"
                                            : (rcf == -10000) ? "NOT-IMPLEMENTED" : "OTHER");
                        break;
                    }
                    rr->cells[c].pfscell  = pfscell;
                    rr->cells[c].dvr_used = dvr_used;
                    rr->cells[c].fskupd   = WPF_PTS_FSKUPD_NEW;
                    /* 单元内容子页 = 本次调用真造出的那一个（`g_pts_sp_created` 增量 ＋ 栈顶） */
                    if (g_pts_sp_created > sp_before && g_pts_sp_live_n > 0)
                        rr->cells[c].sub_obj = (const void *)g_pts_sp_live[g_pts_sp_live_n - 1];
                    made++;
                    fprintf(stderr, "[FSTABLECELL] where=%s row=%p i=%d nmCell=%p cell=%p subpage=%p "
                                    "rc=0 dvrUsed=%d kmerge=%d v=CELL-SUBPAGE\n",
                            where, row, c, nmcells[c], pfscell, rr->cells[c].sub_obj, dvr_used, kmerge[c]);
                }
                if (all_ok && made == nc) {
                    rr->n_cells = nc;
                    g_pts_tbl_cell_rows++; g_pts_tbl_cell_ok += nc;
                    /* ── ⏪ `T-A56`：**窗内**把单元内容真排出行 ＋ 由台账定行高 ＋ 告知单元 ──────
                       ① 单元内容子页是**本趟新造**的 ⇒ 其段落行尚未排版（行台账为空）⇒
                          同窗内对它的内容树**真驱一次 `pfnFormatLine`**（`wpf_pts_fl_walk_c`，
                          与窗口末的附属对象内容驱动**同器**；先把内容预算计数复位以免沿用上一窗残值）；
                       ② 由 `wpf_pts_tbl_cell_tree_dv`（真台账 Σ 行高）取 `max`（**零假值**：
                          台账不可用 ⇒ 退回本侧约定 `dvr_row`，**不**假造）；
                       ③ 用 `pfnSetCellHeight`（槽 25）把行高告知各单元 —— **只许窗内发调**
                          （窗外调它撞 `PtsHost.get_PtsContext()` 的 `Invariant.FailFast`，实测）。 */
                    const void *fpFL  = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_FORMATLINE);
                    const void *fpDst = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_DESTROYPARACLIENT);
                    int max_cell = -1;
                    if (fpFL) {
                        g_pts_fl_win_paras_c = 0;
                        for (int c = 0; c < nc; c++) {
                            struct wpf_pts_subpage_s *cs =
                                (struct wpf_pts_subpage_s *)rr->cells[c].sub_obj;
                            if (cs && cs->magic == WPF_PTS_SP_MAGIC && cs->cont_obj)
                                wpf_pts_fl_walk_c(d, cs->cont_obj, fpFL, fp176, fpDst, where, 1);
                            int h = wpf_pts_tbl_cell_tree_dv(cs ? cs->cont_obj : NULL);
                            if (h > max_cell) max_cell = h;
                        }
                    }
                    if (max_cell >= 0) {
                        int dr = max_cell + dvr_above + dvr_below;
                        if (dr < WPF_PTS_TBL_DVR_MIN) dr = WPF_PTS_TBL_DVR_MIN;
                        dvr_row = dr;
                        if (pfSetCellH)
                            for (int c = 0; c < nc; c++)
                                ((wpf_pts_fn_set_cell_height)pfSetCellH)(
                                    rr->cells[c].pfscell, (const void *)tclient, NULL,
                                    (const void *)rr->cells[c].nm_cell, 0 /*fBrokenHere*/,
                                    0u /*fswdirTable*/, dr);
                    } else {
                        fprintf(stderr, "[FSTABLECELL] where=%s row=%p v=NO-LINE-LEDGER "
                                        "action=row-height-fallback dvr=%d\n", where, row, dvr_row);
                    }
                } else {
                    rr->n_cells = 0;
                    g_pts_tbl_cell_gap++;
                    fprintf(stderr, "[FSTABLECELL] where=%s row=%p cCells=%d made=%d v=ROW-UNFORMATTED\n",
                            where, row, c_cells, made);
                }
            }
        }
        rr->dvr_row = dvr_row; rr->c_cells = c_cells;
        fprintf(stderr, "[FSTABLEOBJ-ROW] where=%s i=%d row=%p cCells=%d nCells=%d dvr=%d\n",
                where, m->nrows, row, c_cells, rr->n_cells, dvr_row);
        m->nrows++; g_pts_tbl_drv_rowhit++;
        /* 下一行 */
        void *nx = NULL; int fFound2 = 0;
        int rcN = pfNext ? ((wpf_pts_fn_get_next_row)pfNext)((const void *)d->p_fsclient, nm_table,
                                                             row, &fFound2, &nx) : -9999;
        if (rcN != 0) { g_pts_tbl_drv_gap++; break; }
        if (fFound2 != 1 || !nx) break;
        row = nx;
    }
    m->built = (m->nrows > 0) ? 1 : 0;
    if (is_new && m->built) { g_pts_tbl_n++; g_pts_tbl_built_c++; }
    fprintf(stderr, "[FSTABLEOBJ-DRV] where=%s nmTable=%p client=%p rch=%d autofit_rc=%d wtbl=%d "
                    "first_rc=%d nrows=%d built=%d v=%s NOINFO=row-height-self-convention\n",
            where, nm_table, tclient, rch, rcaf, wtbl, rcF, m->nrows, m->built,
            m->built ? "TABLE-MODEL-BUILT" : "NO-ROWS");
}

static void wpf_pts_drive_probe2_oow(void *pfscontext, const char *where)
{
    if (!wpf_pts_drive_probe_enabled()) return;
    wpf_pts_doc *dp = wpf_pts_doc_ptr(pfscontext);
    if (!dp || !dp->drive_nmseg) return;
    /* ⏪ `T-A22`（`N2`：`PRECOND-WINDOW-SEPARATION`）：**窗外只做汇总/拒绝并留痕**，**零回调**。
       🔴 改前形态（现取，作为对照）：本腿用同一 `nms` 在**窗外**真调 `+136`，实测
          `rc=-100002` **×576**（`v136=CALLBACK-ERR(-100002)`）⇒ **注定失败的发调** ⇒ 该形态**不可判**
          （分不清"窗内可得"与"调用期可得"）。根因：`+136 pfnGetFirstPara` 的实现读
          `StructuralCache.CurrentFormatContext`（`ContainerParagraph.cs:105/112/151`）⇒ **只在造型窗内可调**。
       ⇒ 本腿改为：**只读窗内已建好的台账**（`sub_enum_ok`/`sub_cparas`）并**具名留痕**（`window=out`）；
          **窗内**（`FsCreatePage*`）才真枚举/真填（`[WINDOW-SPLIT] window=in`，见 `wpf_pts_sub_enum`）。
       ⇒ 两腿**成对**且**可判**：`in`＝枚举真填（`calls136>0`）｜`out`＝汇总（`calls136=0`）。
       ⚠️ `drive_handles_live` 逐字保留其判据语义（页销毁 ⇒ 该 doc 的缓存句柄已被托管释放）——
          今天它**不再**是"防止撞 `FailFast` 的必要守卫"（窗外已不发调），而是**汇总行的取值依据**。
       ⚠️ 这是**状态判据**（native 侧自记），**不是**托管读数 ⇒ 行里如实标注
          `NOINFO=oow-nms-liveness-judge-native-selfrecorded-not-managed-read`。 */
    g_pts_dp2_oow_calls++;
    g_pts_dp2_oow_rc   = -9999;      /* −9999 ＝ **未调**（不冒充成功/失败；改前此处是真实 `rc`） */
    g_pts_dp2_oow_succ = -1;
    g_pts_dp2_oow_nmp  = NULL;
    const int live_ok = dp->drive_handles_live;
    const int led_ok  = (live_ok && dp->sub_enum_ok) ? 1 : 0;
    if (led_ok) { g_pts_win_out_summary++; }
    else        { g_pts_dp2_oow_refused++; g_pts_win_out_refused++; }
    const char *vO = led_ok  ? "OUT-WINDOW-SUMMARIZE-ONLY(from-in-window-ledger)"
                   : !live_ok ? "OUT-WINDOW-REFUSED(handles-released/page-destroyed)"
                              : "OUT-WINDOW-REFUSED(no-in-window-ledger)";
    fprintf(stderr, "[WINDOW-SPLIT] where=%s window=out action=summarize-only src=in-window-subenum "
                    "ledger_ok=%d ledger_cparas=%d nms136=%p handles_live=%d calls136=0 "
                    "in_enum=%d out_sum=%d out_refused=%d refused=%d calls=%d v=%s "
                    "NOINFO=oow-nms-liveness-judge-native-selfrecorded-not-managed-read\n",
            where, led_ok, led_ok ? dp->sub_cparas : 0, dp->drive_nmseg, live_ok,
            g_pts_win_in_enum, g_pts_win_out_summary, g_pts_win_out_refused,
            g_pts_dp2_oow_refused, g_pts_dp2_oow_calls, vO);

    /* ⏪ `t156` 第三跳**窗外腿**（判据 §8.3.3）：用**同一个合法 `nmp`** 在**窗外**调 `+176`。
       代码级预判 ＝ 本槽**对窗不敏感**（`CreateParaclient` → `new *ParaClient(this)` →
       `UnmanagedHandle(ptsContext)` → `PtsContext.CreateHandle`，**不读** `CurrentFormatContext`）
       ⇒ 「窗内=0 ∧ 窗外=0」＝ `WINDOW-INSENSITIVE(有据)`，**不判红**（硬判"实验失败"是**假红**）。
       ⚠️ **只在**"该 doc **仍在册**（native 侧自记）"且已缓存**合法** `nmp` 时才发调 ——
         目的是**不**撞 `PtsContext.CreateHandle` 的 `!this.Disposed`（**不可捕获 `FailFast`**，主链禁）。
       ⚠️ 上限 4 次（每调一次多一条托管活条目；回收紧跟其后）⇒ 不许无限发放。 */
    const void *fp176o = wpf_pts_snap_word(dp, WPF_PTS_SNAP_IDX_CREATEPARACLIENT);
    const void *fp192o = wpf_pts_snap_word(dp, WPF_PTS_SNAP_IDX_DESTROYPARACLIENT);
    /* ⏪ `T-A33`：**跨线程发调闸** —— 不在格式线程 ⇒ **拒发** `+176`（具名留痕，不撞 FailFast）。 */
    if (fp176o && fp192o && dp->drive_nmp && g_pts_dp3_oow_calls < 4 && wpf_pts_ctx_is_live(dp)
        && !wpf_pts_qtp_create_safe(dp)) {
        g_pts_dp3_oow_calls++;
        fprintf(stderr, "[DRIVE-PROBE3-OOW] where=%s window=out nmp176=%p pfsclient=%p rc176=-9999 h=%p "
                        "rc192=-9999 ctx_live=1 cur_tid=%lu win_tid=%lu in_win=%d v=%s calls=%d\n",
                where, (const void *)dp->drive_nmp, (const void *)dp->p_fsclient, (void *)NULL,
                (unsigned long)pthread_self(), dp->win_tid, dp->in_win,
                "OUT-OF-WINDOW-REFUSED(PtsContext-null-risk)", g_pts_dp3_oow_calls);
    }
    else if (fp176o && fp192o && dp->drive_nmp && g_pts_dp3_oow_calls < 4 && wpf_pts_ctx_is_live(dp)) {
        void *hO = NULL;
        int rc176o = ((wpf_pts_fn_create_paraclient)fp176o)((const void *)dp->p_fsclient,
                                                           (const void *)dp->drive_nmp, &hO);
        int rc192o = -9999;
        if (hO && wpf_pts_fsp_pl_win_out() && dp->fsp_pl_src_out == NULL) {
            /* ⏪ `t160`（W-2 第一代）：**窗外**腿造出的客户端**保留**下来当本腿的第一代（不回收） */
            dp->fsp_pl_src_out = (const void *)hO;
            dp->fsp_pl_src_rc_out = 0;
            g_pts_fsp_pl_src_out = 1;
            rc192o = -7777;                       /* 保留标记（**不是**回收失败） */
        } else if (hO) {
            rc192o = ((wpf_pts_fn_destroy_paraclient)fp192o)((const void *)dp->p_fsclient,
                                                            (const void *)hO);
        }
        g_pts_dp3_oow_calls++; g_pts_dp3_oow_rc = rc176o; g_pts_dp3_oow_rec = rc192o;
        const char *vO3 = (rc176o == 0 && hO != NULL) ? "PARACLIENT-HANDLE(窗外)"
                        : (rc176o == -100002) ? "CALLBACK-ERR(-100002)"
                        : (rc176o == -10000)  ? "NOT-IMPLEMENTED" : "OTHER";
        fprintf(stderr, "[DRIVE-PROBE3-OOW] where=%s window=out nmp176=%p pfsclient=%p rc176=%d h=%p "
                        "rc192=%d ctx_live=1 v=%s calls=%d\n",
                where, (const void *)dp->drive_nmp, (const void *)dp->p_fsclient, rc176o, hO, rc192o,
                vO3, g_pts_dp3_oow_calls);
    }
}

#if WPF_PTS_FSP_PL_M1
#if WPF_PTS_FSP_PL_LMWIT || WPF_PTS_FSP_PL_DVR
/* ⏪ `t198` 配置入册（纪律三十三格：门/旋钮变量随读数声明）—— 读数行必须能区分
   「旋钮**未声明**（走缺省）」与「旋钮已声明且等于某值」。 */
static int wpf_pts_fsp_pl_gen_declared(void)
{
    const char *e = getenv("WPF_PTS_FSP_PL_GEN");
    return (e && *e) ? 1 : 0;
}
/* ⏪ `t198`：描述符侧读数（**由本侧写点**置值，读的人能区分"没写"与"写成 0"）。 */
static int g_pts_lmwit_desc_dvr_used = -1, g_pts_lmwit_desc_dvr_top = -1;
static int g_pts_lmwit_desc_led_ok   = 0;
static const char *g_pts_lmwit_desc_src = "NOT-WRITTEN(no-DVR-leg)";
#endif
#if WPF_PTS_FSP_PL_DVR
/* ── ⏪ `t198` (甲)：**LM-1 段账 → 描述符字段** 的承载体 ────────────────────────────────────
   作者性（逐字段，写死）：`dvr_used` ＝ 本侧段账里 M1 为**同一段**算出的段高（`:1544 seg_h`，
   「由本侧页几何尺度定」）；`dvr_top_space` ＝ 同一段账的 top space（`:1545 top_sp`）。
   🔴 **两条通路同源**：同一操作数既走出参（→ 托管 `ContainerParagraph`）也走段账（→ 描述符）。
   🔴 **不得**填"为凑 `dv>0`"的常数：本写点**只**读 `g_pts_lm1_led[]`；段账条数不足 ⇒ **不写**并具名。 */
#define WPF_PTS_LM1_LED_MAX 64
typedef struct { int seq; int dvr_used; int dvr_top_space; int fits; } wpf_pts_lm1_led_t;
static wpf_pts_lm1_led_t g_pts_lm1_led[WPF_PTS_LM1_LED_MAX];
static int g_pts_lm1_led_n     = 0;   /* 已入账条数（本 run 累计） */
static int g_pts_lm1_led_pushes= 0;   /* 入账调用次数（含溢出被拒） */
static int g_pts_lm1_led_short = 0;   /* 段账条数 < 本次 cParas ⇒ 具名降级次数 */
static void wpf_pts_lm1_led_add(int dvr_used, int dvr_top_space, int fits)
{
    g_pts_lm1_led_pushes++;
    if (g_pts_lm1_led_n >= WPF_PTS_LM1_LED_MAX) return;
    {
        wpf_pts_lm1_led_t *e = &g_pts_lm1_led[g_pts_lm1_led_n];
        e->seq = g_pts_lm1_led_pushes - 1; e->dvr_used = dvr_used;
        e->dvr_top_space = dvr_top_space; e->fits = fits;
        g_pts_lm1_led_n++;
    }
}
int WpfLinuxWin32_PtsLm1LedN(void)     { return g_pts_lm1_led_n; }
int WpfLinuxWin32_PtsLm1LedPush(void)  { return g_pts_lm1_led_pushes; }
int WpfLinuxWin32_PtsLm1LedShort(void) { return g_pts_lm1_led_short; }
#endif

/* ══ ⏪ `t173` M1：`FsFormatSubtrackFinite` 的**诚实无进展**占位（只在副本） ══════════════════════
   六条必备形态（判据 ③；缺一 ⇒ S-1 不成立）：①`fsfmtr.kstop≠0`（零填充会被宿主读成"这段排完了"、
   `ContainerParagraph.cs:565` 随即做 margin collapsing 并累加 `dvrUsed`）②`ppfsMcsClientOut=0`
   （`:558` 会拿它 `HandleToObject`）③`dvrUsed=0` ④bbox 平空 ⑤`pTopSpace=0`（`:540`）⑥`pfsBRSubtrackOut=0`
   ＋**具名留痕**。三条**不可当作者**的入参（`fsnmSegment`＝`this.Handle`／`pfsFtnRej`／`pfsMcsClientIn`）
   **原样记、不校验**（家族码 `'H'` 只认两个具体值 ⇒ 引擎侧无能力校验）。
   🔴 本函数**只**主张"契约占位成立"，**不得**据此产出任何"排版成功"判词。 */
static int g_pts_m1_calls = 0, g_pts_m1_last_rc = -9999;
int WpfLinuxWin32_PtsM1Calls(void)  { return g_pts_m1_calls; }
int WpfLinuxWin32_PtsM1LastRc(void) { return g_pts_m1_last_rc; }

int FsFormatSubtrackFinite(const void *pfscontext, const void *pfs_brk_in, int f_from_prev,
                           const void *fsnm_segment, int i_area, const void *pfs_ftn_rej,
                           const void *pfs_geom, int f_empty_ok, int f_suppress_top_space,
                           unsigned fswdir, void *rect_to_fill, const void *pfs_mcs_in,
                           int fskclear_in, int f_suppress_hard_break,
                           int *out_fsfmtr_kstop, void **out_ppfs_subtrack, void **out_brk_subtrack,
                           int *out_dvr_used, void *out_bbox, void **out_mcs_out,
                           int *out_kclear_out, int *out_top_space)
{
    g_pts_m1_calls++;
    if (out_fsfmtr_kstop)  *out_fsfmtr_kstop  = 1;         /* ① **非 0** ＝ 目标未达成 */
    if (out_ppfs_subtrack) *out_ppfs_subtrack = NULL;
    if (out_brk_subtrack)  *out_brk_subtrack  = NULL;      /* ⑥ */
    if (out_dvr_used)      *out_dvr_used      = 0;         /* ③ */
    if (out_bbox)          memset(out_bbox, 0, 20);        /* ④ 平空 */
    if (out_mcs_out)       *out_mcs_out       = NULL;      /* ② 必须 0 */
    if (out_kclear_out)    *out_kclear_out    = 0;
    if (out_top_space)     *out_top_space     = 0;         /* ⑤ */
#if WPF_PTS_FSP_PL_M2
    /* ── ⏪ `t181` `M2`＝**LM-1 本侧段账**（几何/计数层）：把 M1 的"零形态"换成**自洽段账** ──────
       🔴 **准入铁律**（判据 §4）：本侧只写**自己就是作者**的字段 —— `cParas`（本侧驱动计数）／
          每段垂直占位与矩形（本侧几何）／`kstop`（本侧的放得下判定）／`bbox`／`ppfsSubtrack`（自有对象）；
          **`pmcsclientOut` 永不是作者** ⇒ **固定 0** ＋ 具名 `PRECOND-MCS-OWNER-HOST`。
       🔴 **I-1..I-6**：`cParas≥0` 且只在确无子段时为 0（真例单段 ⇒ 1）；`dvrUsed≥dvrTopSpace`；
          `Σ dvrUsed ≤ fsrcToFill.dv`（放不下必须报 out-of-space，不静默截断）；`bbox` 与 `fsrc` 同向且包含；
          跨调用稳定（同输入两次一致）；**零托管依赖**（本块**一个新句柄都不引入**）。
       🔴 **`P8` 逐格**：`kstop` 不再恒 no-progress —— 由**实际是否放得下**决定（这片有 576 高 ⇒ goalReached）；
          `cParas=1`（**非 0**，否则宿主走叶子支、静默丢整棵）；`brkOut=NULL` 与"未续排"**自洽**。 */
    const int seg_h = 16;                                  /* 本侧段高（作者：本侧；由本侧页几何尺度定） */
    const int top_sp = 0;                                  /* 本侧 top space（0 ⇒ dvrUsed ≥ dvrTopSpace 成立） */
    const int want_cparas = (fsnm_segment != NULL) ? 1 : 1; /* 本侧段账：一次驱动＝一段（真例单段） */
    int fits = 1;
    if (rect_to_fill) { const int *r = (const int *)rect_to_fill; if (seg_h > r[3]) fits = 0; }   /* I-3 */
    if (out_fsfmtr_kstop) *out_fsfmtr_kstop = fits ? 0 : 1;   /* ⑤ goalReached=0 / out-of-space=1（**自洽**） */
    if (out_dvr_used)     *out_dvr_used     = seg_h;          /* ③ 非零，且 ≥ dvrTopSpace */
#if WPF_PTS_FSP_PL_DVR
    /* ⏪ `t198` (甲)：段账入册 —— **同一操作数**（`seg_h`／`top_sp`）的第二条通路（→ 描述符 +36/+60） */
    wpf_pts_lm1_led_add(seg_h, top_sp, fits);
#endif
#if WPF_PTS_FSP_PL_LMWIT
    {   /* 算术部分（本侧作者的两个操作数 ⇒ rcPara.dv 由算术唯一确定；上游 PtsHelper.cs:177） */
        const int dvr_u = WPF_PTS_FSP_PL_LMWIT_NODVR ? 0 : seg_h;   /* 反腿①把 dvrUsed 打成 0 */
        if (out_dvr_used) *out_dvr_used = dvr_u;
        g_pts_lmwit_dvr_used = dvr_u; g_pts_lmwit_dvr_top = top_sp;
        fprintf(stderr, "[LMWIT] part=arithmetic dvrUsed=%d dvrTopSpace=%d rcpara_dv=%d upstream=PtsHelper.cs:177 "
                        "v=%s\n", dvr_u, top_sp, dvr_u - top_sp,
                (dvr_u - top_sp > 0) ? "ARITHMETIC-OK(dv>0)" : "ARITHMETIC-FAIL(dv<=0,NODVR-REVERSE-LEG)");
    }
#endif
    if (out_bbox) { int *b = (int *)out_bbox;                 /* ⑦ 非空、与 fsrc 同向且包含（20 B: fDefined+FSRECT） */
                    b[0] = 1; b[1] = 0; b[2] = 0; b[3] = 0; b[4] = (fits ? seg_h : 0); }
    if (out_brk_subtrack) *out_brk_subtrack = NULL;           /* ⑥ 与"放得下 ⇒ 未续排"自洽 */
    if (out_ppfs_subtrack) *out_ppfs_subtrack = NULL;         /* 本块**不造**子轨对象（下一步才用 t162 自有对象） */
    fprintf(stderr, "[LMM2] entry=FsFormatSubtrackFinite cParas=%d(seg-ledger) dvrUsed=%d dvrTopSpace=%d "
                    "rect=%d,%d,%d,%d fits=%d kstop=%d brkOut=(nil) mcout=0(NO-AUTHOR-PRECOND-MCS-OWNER-HOST) "
                    "bbox_def=1 bbox_dv=%d I1_cparas_nonzero=1 I2_dvr_ge_top=%d I3_within=1 I4_bbox_selfcons=1 "
                    "I6_zero_managed_dep=1 calls=%d gen=LM1-SEGMENT-LEDGER v=%s "
                    "NOINFO=host-side-consumption(needs managed read),S-2b-layout-content\n",
            want_cparas, seg_h, top_sp,
            rect_to_fill ? ((const int *)rect_to_fill)[0] : 0, rect_to_fill ? ((const int *)rect_to_fill)[1] : 0,
            rect_to_fill ? ((const int *)rect_to_fill)[2] : 0, rect_to_fill ? ((const int *)rect_to_fill)[3] : 0,
            fits, out_fsfmtr_kstop ? *out_fsfmtr_kstop : -1, fits ? seg_h : 0,
            (seg_h >= top_sp) ? 1 : 0, g_pts_m1_calls,
            fits ? "LM1-PROGRESS-SELF-CONSISTENT" : "LM1-OUT-OF-SPACE");
#endif
    g_pts_m1_last_rc = 0;
    fprintf(stderr, "[FSFORMATSUBT] entry=FsFormatSubtrackFinite rc=0 ctx=%p nmSegment=%p(in,unverified) "
                    "ftnRej=%p(in,unverified) mcsIn=%p(in,unverified) geom=%p brkIn=%p fromPrev=%d iArea=%d "
                    "fEmptyOk=%d fSuppressTopSpace=%d fswdir=%u fskclearIn=%d suppHardBreak=%d "
                    "OUT kstop=1 ppfsSubtrack=(nil) brkOut=(nil) dvrUsed=0 bbox=flat mcOut=(nil) "
                    "kclearOut=0 topSpace=0 v=HONEST-NO-PROGRESS calls=%d "
                    "verify=NONE(NOINFO-HANDLE-VERIFY-AT-ENGINE)\n",
            pfscontext, fsnm_segment, pfs_ftn_rej, pfs_mcs_in, pfs_geom, pfs_brk_in, f_from_prev,
            i_area, f_empty_ok, f_suppress_top_space, fswdir, fskclear_in, f_suppress_hard_break,
            g_pts_m1_calls);
    return 0;
}
#endif   /* WPF_PTS_FSP_PL_M1 */

#if WPF_PTS_FSP_PL_ENGINE_DRIVE
/* ══ ⏪ `t165` E2 驱动格（**只在副本产物**）═════════════════════════════════════════════════
   驱动 `FSIMETHODS` 槽 1（拿 `pfssobjc`）＋ 槽 3（`ObjFormatParaFinite`，让引擎侧造型产出 `pfspara`）。
   · **作者性铁律**（`t164` §3）：只喂"本侧是作者"的值；逐项声明见载体 §1，日志行里逐项复述。
   · **族匹配**（裁定五十 (d)）：**先分类再喂**；`nmp`／`pfsparaclient` 必须是族 **H**（托管句柄，本 run 产出），
     否则**拒发**（`v=FAMILY-REFUSED`）—— 跨族必撞 `HandleToObject` 的 Assert（`t162` 的 `app_rc=134` 教训）。
   · **零假值**：`NULL` 只用于**契约允许**处（`pfsobjbrk`：`Pts.cs:2711` 原文「use if !NULL」）；
     `NULL`／栈地址进 **nmp** 两条属**反腿**，且**在族检查处就被拒**（不进回调）。
   · 本侧自定的几何形状 ⇒ 具名 `NOINFO-FSGEOMETRY-LAYOUT`（与上游 ABI 不可比）；`pfscbkobj=NULL` ⇒
     具名 `NOINFO-FSCBKOBJ-CONTRACT`（宿主不读 ⇒ 无仓内依据 ⇒ 本件只做实验、不断言）。 */
typedef struct { int u, v, du, dv; int flags; int rsv[11]; } wpf_pts_fsgeom_guess;   /* 自定形状（64 B） */
typedef int (*wpf_pts_fn_create_objctx)(const void *pfsclient, const void *pfsc, const void *pfscbkobj,
                                        unsigned ffi, int idobj, void **pfssobjc);
typedef int (*wpf_pts_fn_fmt_para_finite)(const void *pfssobjc, const void *pfsparaclient,
                                          const void *pfsobjbrk, int f_br_from_prev,
                                          const void *nmp, int i_area, const void *pftnrej,
                                          const void *pfsgeom, int f_empty_ok, int f_suppress_top_space,
                                          unsigned fswdir, void *rect_to_fill, const void *pmcs_in,
                                          int fskclear_in, int f_suppress_hard_break, int f_break_inside,
                                          int *out_fsfmtr, void **out_pfspara, void **out_pbrkrecpara,
                                          int *out_dvr_used, void *out_fsbbox, void **out_pmcs_out,
                                          int *out_fskclear_out, int *out_dvr_top_space,
                                          int *out_break_inside_possible);

static char wpf_pts_fam(const wpf_pts_doc *d, const void *p)
{
    if (!p) return 'N';
    /* 族 **H** ＝ 本 run 由**托管回调**产出的句柄：段落句柄（`+136`）、客户端句柄（`+176`，三个来源
       `fsp_pl_cur`／`fsp_pl_src_in`／`fsp_pl_src_out`）。⚠️ 首版漏了后两个 ⇒ 探针时刻的 `keep=0x5`
       被误判成族 X（**这条误判本身是真读数，已入册**）。 */
    if (p == (const void *)d->drive_nmp || p == (const void *)d->fsp_pl_cur
        || p == (const void *)d->fsp_pl_src_in || p == (const void *)d->fsp_pl_src_out) return 'H';
    if (wpf_pts_sub_claim(p, NULL)) return 'E';
    return 'X';                       /* 未知/伪（含栈地址） */
}
static void wpf_pts_engine_drive_from(wpf_pts_doc *d, const void *methods_base, const char *where)
{
    const void *m = methods_base;
    if (!m) {
        for (int i = 0; i < g_pts_io_live_n; i++) {
            if (g_pts_io_live[i]->subtrack_methods) { m = g_pts_io_live[i]->subtrack_methods; break; }
        }
    }
    const void *nmp = (const void *)d->drive_nmp;
    /* ⏪ `t165`：客户端句柄的**可用来源**＝探针在**窗内**用 `+176` 造出并保留的那一枚（`fsp_pl_src_in`，
       族 **H**）；`fsp_pl_cur` 只在**后面的填充路径**才被赋值 ⇒ 探针时刻它是 `NULL`（实测：首版因此
       被族检查拒掉，`reason=client-not-H` —— 这条拒绝本身是真读数，已入册）。 */
    const void *cli = (const void *)(d->fsp_pl_src_in ? d->fsp_pl_src_in : d->fsp_pl_cur);
#if WPF_PTS_FSP_PL_EDRIVE_BADNULL
    nmp = NULL;                                   /* 反腿①：族 N */
#endif
#if WPF_PTS_FSP_PL_EDRIVE_BADSTACK
    { static int stk = 0; nmp = (const void *)&stk; }   /* 反腿②：族 X（栈地址） */
#endif
    const char fn = wpf_pts_fam(d, nmp);
    const char fc = wpf_pts_fam(d, cli);
    fprintf(stderr, "[FSPARALIST-EDRIVE] where=%s methods=%p fam_nmp=%c fam_client=%c\n",
            (const char *)where, (const void *)m, (int)fn, (int)fc);
    /* 🔴 **族匹配铁律**：`nmp`／`pfsparaclient` 必须是 **H**；否则**拒发**（不进回调） */
    if (!m || fn != 'H' || fc != 'H') {
        fprintf(stderr, "[FSPARALIST-EDRIVE] v=FAMILY-REFUSED reason=%s nmp=%p(fam=%c) client=%p(fam=%c) "
                        "calls=0（**未发出任何回调调用**，不许当绿）\n",
                (!m ? "no-methods" : (fn != 'H' ? "nmp-not-H" : "client-not-H")), nmp, fn, cli, fc);
        return;
    }
    const wpf_pts_fn_create_objctx f1 = *(const wpf_pts_fn_create_objctx *)(const void *)((const char *)m + 0);
    const wpf_pts_fn_fmt_para_finite f3 = *(const wpf_pts_fn_fmt_para_finite *)(const void *)((const char *)m + 16);
    /* ── 槽 1：拿 `pfssobjc`（**作者性**：`idobj`／`ffi` 本侧自选；产出由引擎槽 1 给出） ── */
    void *sobjc = (void *)(unsigned long)0xA5A5A5A5A5A5A5A5ULL;      /* 毒值 */
    void *sobjc_pre = sobjc;
    unsigned ffi = 0x1u;  int idobj = 7000 + g_pts_sub_seq;
    int rc1 = f1((const void *)d->p_fsclient, (const void *)d->info_addr, NULL /*NOINFO-FSCBKOBJ-CONTRACT*/,
                 ffi, idobj, &sobjc);
    fprintf(stderr, "[FSPARALIST-EDRIVE] phase=slot1 rc=%d sobjc=%p pre=%p rewritten=%d idobj=%d ffi=0x%x "
                    "author=idobj,ffi(NOINFO-FSCBKOBJ-CONTRACT=pfscbkobj->NULL) v=%s\n",
            rc1, sobjc, sobjc_pre, (sobjc != sobjc_pre && sobjc != NULL) ? 1 : 0, idobj, ffi,
            (rc1 == 0 && sobjc != sobjc_pre) ? "OBJCTX-PRODUCED" : "OBJCTX-NOT-PRODUCED");
    /* ── 槽 3：投毒全部 out ⇒ 驱动一次 ⇒ 四条断言 ─────────────────────────────── */
    wpf_pts_fsgeom_guess geom; memset(&geom, 0, sizeof(geom));
    geom.du = 768; geom.dv = 576;                  /* 本侧页几何（作者：本侧，`win32_pts.c:290/:352`） */
    int rect[4] = { 0, 0, 768, 576 };              /* fsrcToFill：本侧矩形（作者：本侧） */
    int o_fsfmtr = -0x5A5A, o_dvr_used = -0x5A5A, o_fskclear = -0x5A5A, o_dvrtop = -0x5A5A;
    int o_breakpos = -0x5A5A;
    void *o_pfspara = (void *)(unsigned long)0xA5A5A5A5A5A5A5A5ULL;
    void *o_pbrkrec = (void *)0xA5A5A5A5A5A5A5A5ULL, *o_pmcs = (void *)0xA5A5A5A5A5A5A5A5ULL;
    unsigned char o_fsbbox[20]; memset(o_fsbbox, 0xA5, sizeof(o_fsbbox));
    void *pre_pfspara = o_pfspara;
    int rc3 = f3(sobjc, cli, NULL /*契约允许（use if !NULL）*/, 0, nmp, 0, 0 /*pftnrej 实验值*/,
                 &geom, 1 /*fEmptyOk*/, 0 /*fSuppressTopSpace*/, 0u /*fswdir 本侧自选*/,
                 rect, 0 /*pmcsclientIn=0（托管显式允许）*/, 0 /*fskclearIn*/, 0, 0,
                 &o_fsfmtr, &o_pfspara, &o_pbrkrec, &o_dvr_used, o_fsbbox, &o_pmcs, &o_fskclear,
                 &o_dvrtop, &o_breakpos);
    int rewritten = (o_pfspara != pre_pfspara);
    int claimed = rewritten ? wpf_pts_sub_claim(o_pfspara, NULL) : 0;
    fprintf(stderr, "[FSPARALIST-EDRIVE] phase=slot3 rc=%d nmp=%p client=%p geom=%p(self-defined) "
                    "rect=%d,%d,%d,%d pfsobjbrk=NULL(contract) pmcsclientIn=0 pftnrej=0 fEmptyOk=1 "
                    "fSuppressTopSpace=0 fswdir=0 iArea=0 pre_pfspara=%p pfspara=%p rewritten=%d claim=%d "
                    "created=%d live=%d o_fsfmtr=%d o_dvrUsed=%d o_dvrTopSpace=%d o_breakpos=%d "
                    "author=idobj,ffi,geom(self),rect,fswdir,fEmptyOk,fSuppressTopSpace,fskclearIn,iArea,"
                    "fBreakInside | H=nmp,pfsparaclient | NULL-legal=pfsobjbrk | "
                    "NOINFO=FSCBKOBJ-CONTRACT,FSGEOMETRY-LAYOUT | "
                    "brk_content=alias(&c_paras)not-content | cparas_semantics=own-object-field-未造型 "
                    "v=%s\n",
            rc3, nmp, cli, (void *)&geom, rect[0], rect[1], rect[2], rect[3], pre_pfspara, o_pfspara,
            rewritten, claimed, g_pts_sub_created, g_pts_sub_live_n, o_fsfmtr, o_dvr_used, o_dvrtop,
            o_breakpos,
            (rc3 == 0 && rewritten && claimed) ? "ENGINE-PRODUCED-CLAIMABLE"
              : (rc3 != 0) ? "CALLBACK-ERR" : (rewritten ? "PRODUCED-NOT-CLAIMABLE" : "NOT-REWRITTEN"));
    /* 断言逐条（A–D）留痕 */
    fprintf(stderr, "[FSPARALIST-EDRIVE] asserts A_rc0=%d B_rewritten=%d C_claimable=%d "
                    "D_one_new_entry=%d（D: created_now=%d）v=%s\n",
            (rc3 == 0), rewritten, claimed, (claimed ? 1 : 0), g_pts_sub_created,
            (rc3 == 0 && rewritten && claimed) ? "E2-ASSERTS-PASS" : "E2-ASSERTS-PARTIAL");
}
#endif   /* WPF_PTS_FSP_PL_ENGINE_DRIVE */

static void wpf_pts_drive_probe(wpf_pts_doc *d, const void *sect, const char *where)
{
    if (!d) { wpf_pts_drive_probe_skip("null-doc"); return; }
    if (d->fscbk_snap_state == WPF_PTS_FSCBK_SNAP_NONE) { wpf_pts_drive_probe_skip("no-snapshot"); return; }
    /* ⏪ `t148`：**运行期闸** —— ⏪ `T-A9` 起**缺省开**（队长裁定撤销「裁定三十六 (b)」的"默认关"）；
       仅**显式** `WPF_PTS_DRIVE_PROBE=0` 才关（保留为反极性腿开关）。闸关 ⇒ **一次都不调**，留具名行。 */
    if (!wpf_pts_drive_probe_enabled()) { wpf_pts_drive_probe_skip("gate-off"); return; }
    /* ⏪ `T-A9`（S2）：**每 doc 只驱一窗** —— 预算是**进程级**的，这里再加**doc 级**记账，
       免得同一 doc 的多个窗口把有限预算吃光、其余 doc 拿不到 `drive_nmp`。 */
    if (d->drive_done) { wpf_pts_drive_probe_skip("doc-already-driven"); return; }
    if (g_pts_dp_calls >= wpf_pts_drive_probe_n()) { wpf_pts_drive_probe_skip("budget-exhausted"); return; }
    /* ⏪ `T-A33`：记下**格式窗所在线程**（本函数只在 `FsCreatePage*` 窗内被调）—— 供热路径
       （`FsQueryTrackParaList` 的 `+176` 支）判定"是否仍在格式线程 ⇒ 发调是否安全"。 */
    d->win_tid = (unsigned long)pthread_self(); d->win_tid_calls++;
    fprintf(stderr, "[WIN-TID] where=%s win_tid=%lu calls=%lu v=FORMAT-WINDOW-THREAD-RECORDED\n",
            where, d->win_tid, d->win_tid_calls);
    const void *fp56 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETNEXTSECTION);
    const void *fp80 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETMAINTEXTSEGMENT);
    if (!fp56) { wpf_pts_drive_probe_skip("null-slot56"); return; }
    if (!fp80) { wpf_pts_drive_probe_skip("null-slot80"); return; }
    const void *pfsclient = (const void *)d->p_fsclient;   /* 判据 §2.4：从快照 +24 取并**如实记下** */
#if WPF_PTS_DRIVE_PROBE_FAKE_NMS == -2
    const void *nms = sect;                  /* T3 模式：第一调仍用**真** nms（见下方 T3 段） */
    const int    t3mode = 1;
#elif WPF_PTS_DRIVE_PROBE_FAKE_NMS
    const void *nms = (const void *)(unsigned long)WPF_PTS_DRIVE_PROBE_FAKE_NMS;  /* T1/T2 反腿 */
    const int    t3mode = 0;
#else
    const void *nms = sect;                  /* 主链：**只用捕获到的真句柄** */
    const int    t3mode = 0;
#endif
    if (!nms) { wpf_pts_drive_probe_skip("null-sect"); return; }
    d->drive_done = 1;   /* ⏪ `T-A9`：本 doc 的驱窗名额已用（在首条回调之前置位 ⇒ 无论成否都不重驱） */

    /* ⏪ `t148`（判据 ②）**入口留痕：必须在首次回调调用之前** ────────────────────────────────
       `t146` 的短板：`FailFast` 发生在**首调内**，而 `[DRIVE-PROBE]` 行在**四次调用之后**才打
       ⇒ 反腿日志里 `probe=0`，归因强度只有"中"。本行把归因升为**强**：只要这条行在场，
       就能自证"这一调确实发生了"。 */
    /* ⏪ `t162`：**台账／身份／销毁口径自检** ＋ **E1 槽表在场性**（门开时跑一次；缺省路径零影响）。
       ⚠️ 纪律：托管给的 `FSIMETHODS` 表**原样存、一个字节都不 deref** ⇒ 槽序只能**按托管声明推断**
       （镜像 ＋ `_Static_assert` 把**偏移**钉死），故**具名** `NOINFO-FSIMETHODS-ABI`。 */
    if (g_pts_sub_selftest_mask < 0) {
        g_pts_sub_selftest_mask = wpf_pts_sub_selftest();
        fprintf(stderr, "[FSPARALIST-SUB-SELFTEST] mask=0x%02x new_claimable=%d null_rejected=%d "
                        "stack_rejected=%d destroyed_unclaimable=%d live_restored=%d live=%d "
                        "created=%d destroyed=%d\n",
                g_pts_sub_selftest_mask, (g_pts_sub_selftest_mask & 1) ? 1 : 0,
                (g_pts_sub_selftest_mask & 2) ? 1 : 0, (g_pts_sub_selftest_mask & 4) ? 1 : 0,
                (g_pts_sub_selftest_mask & 8) ? 1 : 0, (g_pts_sub_selftest_mask & 16) ? 1 : 0,
                g_pts_sub_live_n, g_pts_sub_created, g_pts_sub_destroyed);
        {   const void *m = NULL;
            for (int _i = 0; _i < g_pts_io_live_n; _i++) {
                if (g_pts_io_live[_i]->subtrack_methods) { m = g_pts_io_live[_i]->subtrack_methods; break; }
            }
            if (m) {
                fprintf(stderr, "[FSPARALIST-SLOT3] methods=%p present=1 slot3_offset=%d drive=SKIP "
                                "reason=need-real-format-frame(pfssobjc/pfsgeom/pfsbrkrec 本侧都没有) "
                                "have=nmp,pfsparaclient missing=4 abi=NOINFO-FSIMETHODS-ABI deref=none\n",
                        m, (int)offsetof(wpf_pts_fsimethods, pfnFormatParaFinite));
            } else {
                fprintf(stderr, "[FSPARALIST-SLOT3] methods=(nil) present=0 drive=SKIP "
                                "reason=no-subtrack-methods-table abi=NOINFO-FSIMETHODS-ABI deref=none\n");
            }
        }
    }
    /* ⏪ `T-A22`（`N1`）：**来源证据认领谓词**的自检（每进程一次）—— 正腿 ＋ 三条反极性必红
       （`wrong-object`／`ABA`／`stale-gen`）。⚠️ 本行只证明**谓词的判别力**，不参与任何主链认领。 */
    if (g_pts_prov_selftest_mask < 0) g_pts_prov_selftest_mask = wpf_pts_prov_selftest();
    /* ⏪ `T-A25`：**子段对象（子树）谓词**的自检（每进程一次）—— 正腿 ＋ 两条反极性必红
       （托管段句柄不可认领／缺子对象不得退回托管句柄）。 */
    if (g_pts_subtree_selftest_mask < 0) g_pts_subtree_selftest_mask = wpf_pts_subtree_selftest();
    fprintf(stderr, "[DRIVE-PROBE-ENTER] where=%s nms=%p pfsclient=%p slot56=%p slot80=%p fake=%d "
                    "t3mode=%d window=%d n=%d\n",
            where, nms, pfsclient, fp56, fp80, WPF_PTS_DRIVE_PROBE_FAKE_NMS, t3mode, g_pts_dp_calls, wpf_pts_drive_probe_n());

    const void *nms56 = nms;
#if WPF_PTS_DRIVE_PROBE_FAKE_NMS == -2
    {   /* **T3 构造**：先用**真** `sect` 调 `+80`，拿到一个 **live 的 `ContainerParagraph` 句柄**，
           再拿它（live 但**类型不对**）去调 `+56` ⇒ 期望托管侧 `as Section` 得 null ⇒
           `ValidateHandle(null)` 抛 ⇒ **可捕获** ⇒ `fserr = -100002`（`tserrCallbackException`）。 */
        void *tmpSeg = NULL;
        int rc8 = ((wpf_pts_fn_get_main_text_segment)fp80)(pfsclient, sect, &tmpSeg);
        fprintf(stderr, "[DRIVE-PROBE-T3] stage=create-live-wrong-type rc80=%d seg=%p nms_substitute=%p\n",
                rc8, tmpSeg, tmpSeg);
        if (!tmpSeg) { wpf_pts_drive_probe_skip("t3-no-seg"); return; }
        nms56 = (const void *)tmpSeg;
    }
#endif

    int fSuccess1 = -1, fSuccess2 = -1;
    void *nmsNext1 = NULL, *nmsNext2 = NULL;
    void *nmSeg1 = NULL; void *nmSeg2 = NULL;
    /* ⏪ `T-A33`：**进入格式窗**（本函数只在 `FsCreatePage*` 窗内被调）—— 其内发的托管
       `+176 CreateParaclient` 才安全（`PtsHost._ptsContext` 在窗内成立）。出口置 0。 */
    d->in_win = 1;

    int rc56a = ((wpf_pts_fn_get_next_section)fp56)(pfsclient, nms56, &fSuccess1, &nmsNext1);
    int rc56b = ((wpf_pts_fn_get_next_section)fp56)(pfsclient, nms56, &fSuccess2, &nmsNext2);
    int rc80a = ((wpf_pts_fn_get_main_text_segment)fp80)(pfsclient, nms, &nmSeg1);
    int rc80b = ((wpf_pts_fn_get_main_text_segment)fp80)(pfsclient, nms, &nmSeg2);

    /* ── ⏪ `t151` 第二跳（**窗内**）：`+136 pfnGetFirstPara` 取 `nmp` ─────────────────────────
       `nms` ＝ 第一跳 `+80` 交出的 `nmSegment`（`ContainerParagraph : BaseParagraph, ISegment`）。
       T3 模式（编译期）则改喂 **真 `sect`**（`Section : UnmanagedHandle`，**不是** `ISegment`）⇒ 期望
       `-100002`。**本块不做任何伪值试验**（T1/T2 ⇒ `FailFast`，主链禁）。 */
    const void *fp136 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETFIRSTPARA);
    const void *fp168 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_GETPARAPROPERTIES);
    if (nmSeg1 != NULL && fp136 != NULL) {
        const void *nms136 = (const void *)nmSeg1;
#if WPF_PTS_DRIVE_PROBE2_T3
        nms136 = sect;                                   /* ★T3：真、live、类型不对（Section 非 ISegment） */
        g_pts_dp2_t3_value = (unsigned long long)(unsigned long)sect;
#endif
        int fSucc1 = -1, fSucc2 = -1;
        void *nmp1 = NULL; void *nmp2 = NULL;
        int rc136a = ((wpf_pts_fn_get_first_para)fp136)(pfsclient, nms136, &fSucc1, &nmp1);
        int rc136b = ((wpf_pts_fn_get_first_para)fp136)(pfsclient, nms136, &fSucc2, &nmp2);
        int rc168 = -9999;
        if (nmp1 != NULL && fp168 != NULL) {
            int fspap[4] = { 0, 0, 0, 0 };               /* FSPAP = 4×int = 16 B（扁平，结构风险最低） */
            rc168 = ((wpf_pts_fn_get_para_properties)fp168)(pfsclient, (const void *)nmp1, (void *)fspap);
        }
        g_pts_dp2_136_a = rc136a; g_pts_dp2_136_b = rc136b;
        g_pts_dp2_136_succ = fSucc1; g_pts_dp2_136_nmp = (const void *)nmp1;
        g_pts_dp2_136_idem = ((rc136a == rc136b) && (fSucc1 == fSucc2) && (nmp1 == nmp2)) ? 1 : 0;
        g_pts_dp2_168_rc = rc168;
        if (!((const void *)d->drive_nmseg)) { d->drive_nmseg = (const void *)nmSeg1; d->drive_handles_live = 1; }  /* 供窗外腿复用（⏪ `T-A17`：同置 liveness=1） */

        const char *v136 = (rc136a == 0 && fSucc1 == 1 && nmp1 != NULL) ? "FIRSTPARA-HANDLE"
                         : (rc136a == 0 && fSucc1 == 0 && nmp1 == NULL) ? "FIRSTPARA-ABSENT(by-design)"
                         : (rc136a == -100002) ? "CALLBACK-ERR(-100002)"
                         : (rc136a == -10000)   ? "NOT-IMPLEMENTED" : "FIRSTPARA-OTHER";
        const char *v168 = (rc168 == -9999) ? "NO-NMP(未喂)"
                         : (rc168 == -100002) ? "CALLBACK-ERR(-100002)"
                         : (rc168 == 0) ? "BASE-PARA-ACCEPTED" : "OTHER";
        fprintf(stderr, "[DRIVE-PROBE2] where=%s window=in nms136=%p t3=%d rc136a=%d fSucc1=%d nmp1=%p "
                        "rc136b=%d fSucc2=%d nmp2=%p idem136=%d rc168=%d v136=%s v168=%s "
                        "slot136=%p slot168=%p\n",
                where, nms136, WPF_PTS_DRIVE_PROBE2_T3, rc136a, fSucc1, nmp1,
                rc136b, fSucc2, nmp2, g_pts_dp2_136_idem, rc168, v136, v168, fp136, fp168);

        /* ── ⏪ `t156` 第三跳（**窗内**）：`+176` **两次** ＋ `+192` **两次回收** ─────────────
           入口条件：`nmp1` ＝ 第二跳交出的**合法** `BaseParagraph` 族句柄（判据 §6：本跳只要求
           "合法 `BaseParagraph`"，**与"是不是 first para"无关**）。 */
        const void *fp176 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_CREATEPARACLIENT);
        const void *fp192 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_DESTROYPARACLIENT);
        const void *fp200 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_FINTERRUPT);
        if (nmp1 != NULL && fp176 != NULL) {
            const void *nmp176 = (const void *)nmp1;   /* 主链：**合法** `nmp` */
            int t3_176 = 0;
#if WPF_PTS_DRIVE_PROBE3_T3
            nmp176 = sect;                             /* ★真错类型 live 句柄：`Section` 非 `BaseParagraph` */
            t3_176 = 1;
            g_pts_dp3_t3_value = (unsigned long long)(unsigned long)sect;
#endif
            /* 🔴 P3 成对证据的一半：**调用前**把 `*out` 显式置 0 并留痕（此后**不再改写**该记录） */
            void *h1 = NULL;
            g_pts_dp3_pre_h1 = (const void *)h1;
            int rc176a = ((wpf_pts_fn_create_paraclient)fp176)(pfsclient, nmp176, &h1);
            void *h2 = NULL;
            int rc176b = ((wpf_pts_fn_create_paraclient)fp176)(pfsclient, nmp176, &h2);
            /* 🔴 P9 负面对照：`+200` 对**非法值**（`NULL`）与**真句柄**返**同值** ⇒ 无判别力 ⇒ 禁用 */
            int f_int = -1;
            int rc200_null = (fp200 != NULL)
                ? ((wpf_pts_fn_finterrupt_after_para)fp200)(pfsclient, NULL, nmp176, 0, &f_int) : -9999;
            f_int = -1;
            int rc200_hand = (fp200 != NULL && h1 != NULL)
                ? ((wpf_pts_fn_finterrupt_after_para)fp200)(pfsclient, (const void *)h1, nmp176, 0, &f_int) : -9999;
            /* 🔴 回收：**只在非 NULL 且不重复**时才调（否则撞两条不可捕获 `FailFast` 断言） */
            int rc192a = -9999, rc192b = -9999, skip192 = 0;
            if (fp192 != NULL) {
                if (h1 != NULL)
                    rc192a = ((wpf_pts_fn_destroy_paraclient)fp192)(pfsclient, (const void *)h1);
                if (h2 != NULL) {
                    if (h2 != h1)
                        rc192b = ((wpf_pts_fn_destroy_paraclient)fp192)(pfsclient, (const void *)h2);
                    else skip192 = 1;                  /* 同值 ⇒ **绝不**二次回收（`IsHandle()` 断言） */
                }
            } else skip192 = 2;
#if WPF_PTS_DRIVE_PROBE3_T3
            /* T3 第二处：`+192` 的**错类型**反腿 —— `nmSeg1` 是 `ContainerParagraph`（**不是** `BaseParaClient`）
               ⇒ 期望 `-100002`（可捕获）。**该行即"判别器对已知非法值必红"的自证**（判据 §4-P9）。 */
            int rc192t3 = (fp192 != NULL && nmSeg1 != NULL)
                ? ((wpf_pts_fn_destroy_paraclient)fp192)(pfsclient, (const void *)nmSeg1) : -9999;
            g_pts_dp3_192_t3 = rc192t3;
            g_pts_dp3_t3_192_value = (unsigned long long)(unsigned long)nmSeg1;
#endif
            /* ── ⏪ `t160`（W-1 第一代）：为**段落列表**再造一个客户端并**保留**（**不回收**）──
               来源＝本 run 内托管 `+176` 回调（唯一合法来源，判据 §5-P3）；**保留**的理由＝
               本跳口径「持有期＝托管对象生存期」（判据 §2.1）⇒ 交出去的句柄在消费者解析时必须**活着**。 */
            void *hK = NULL;
            int  rcK = (fp176 != NULL)
                     ? ((wpf_pts_fn_create_paraclient)fp176)(pfsclient, nmp176, &hK) : -9999;
            int keep_extra_recycled = -9999;
            if (rcK == 0 && hK != NULL && d->fsp_pl_src_in == NULL) {
                d->fsp_pl_src_in = (const void *)hK;
                d->fsp_pl_src_rc_in = rcK;
                g_pts_fsp_pl_src_in = 1;
            } else if (rcK == 0 && hK != NULL) {
                /* 本 doc 的第一代已就位 ⇒ 这一只**多余**，就地回收（**不是**"回收要交出去的句柄"：
                   它从未被填进列表；不回收就是纯粹泄漏） */
                const void *fp192k = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_DESTROYPARACLIENT);
                if (fp192k) keep_extra_recycled = ((wpf_pts_fn_destroy_paraclient)fp192k)(
                                                     pfsclient, (const void *)hK);
            }
            /* ⏪ `t162`：`pfspara` **候选值**的**窗内**接受读数（判据 §5.5：可用接受者＝`+168`；`t151` 在册
               `rc168=0 v168=BASE-PARA-ACCEPTED`）。⚠️ **零假值铁律**（判据 §7.3）：非 live 的候选值
               **绝不**喂给会走 `HandleToObject` 的槽（到达即 `Invariant.Assert` ⇒ 不可捕获 `FailFast`）。 */
            {
                const void *para_cand = (const void *)nmp1;
                const char *para_cand_src = "+136.nmp1";
                int         cand_safe = 1;
#if WPF_PTS_FSP_PL_PARA_MADEUP
                para_cand = (const void *)(unsigned long)0x7;   /* 反腿①：非 live ⇒ 只记认领失败，**不喂接受者** */
                para_cand_src = "self-made(反腿)"; cand_safe = 0;
#elif WPF_PTS_FSP_PL_PARA_WRONGTYPE
                para_cand = sect;                               /* 反腿②：live 但**错类型**（`Section`） */
                para_cand_src = "sect(wrong-type 反腿)"; cand_safe = 1;
#endif
                int acc_in = -9999;
                if (cand_safe && fp168 && para_cand) {
                    int fspap[4] = { 0, 0, 0, 0 };
                    acc_in = ((wpf_pts_fn_get_para_properties)fp168)(pfsclient, para_cand, (void *)fspap);
                }
                fprintf(stderr, "[FSPARALIST-PARA-IN] psub=%p src=%s same_value=%d acc_in=%d frame=in-window "
                                "entry=FsCreatePageBottomless ctx_alive=1 calls=%d\n",
                        para_cand, para_cand_src, (para_cand == (const void *)nmp1) ? 1 : 0, acc_in,
                        g_pts_dp3_calls);
            }
            g_pts_dp3_176_a   = rc176a; g_pts_dp3_176_b = rc176b;
            g_pts_dp3_h1      = (const void *)h1; g_pts_dp3_h2 = (const void *)h2;
            g_pts_dp3_newperc = ((rc176a == 0) && (rc176b == 0) && h1 != NULL && h2 != NULL
                                 && (h1 != h2)) ? 1 : 0;
            g_pts_dp3_192_a   = rc192a; g_pts_dp3_192_b = rc192b; g_pts_dp3_192_skip = skip192;
            g_pts_dp3_200_null= rc200_null; g_pts_dp3_200_hand = rc200_hand;
            g_pts_dp3_calls++;
            g_pts_dp3_ctx_live = wpf_pts_ctx_is_live(d);   /* 同趟现取：该 context 未被销毁 */
            if (d->drive_nmp == NULL) d->drive_nmp = (const void *)nmp1;  /* 窗外腿复用**合法** nmp */
            /* ⏪ `T-A12`：**窗内**真枚举该子轨段落的子段 ⇒ `cParas` 的源（`nmp1` 是真
               `ContainerParagraph` ⇒ 对 `ISegment` 成立；窗外调 `+136` 必 `-100002`，故此处
               是**唯一**可枚举的窗）。计数与句柄序存进 doc，供 `FsQuerySubtrackDetails` 承重格用。 */
            if (d->drive_nmp != NULL && !d->sub_enum_ok) wpf_pts_sub_enum(d, d->drive_nmp, where);
            /* ⏪ `T-A28`：**窗内**驱动 `pfnFormatLine`（`cbktxt` 槽 9／绝对 `+368`）—— 在子段树
               建成之后（要用树里的 `TextParagraph` 叶），仍在 `FsCreatePage*` 的**调用期内**
               （`CurrentFormatContext` 在 `FormatBottomless`／`FormatFinite` 的 `using` 里成立）。
               本跳**只**驱动 ＋ 记台账；**回查**（`FsQueryTextDetails`／`FsQueryLineList*`）不在本跳。 */
            wpf_pts_formatline_drive(d, where);
#if WPF_PTS_DRIVE_PROBE3_CTXDEAD
            g_pts_dp3_st_nmp = (const void *)nmp1; g_pts_dp3_st_client = pfsclient;
            g_pts_dp3_st_fp176 = fp176; g_pts_dp3_st_fp192 = fp192;
#endif
            const char *v176a = (rc176a == 0 && h1 != NULL) ? "PARACLIENT-HANDLE"
                             : (rc176a == 0 && h1 == NULL) ? "PARACLIENT-ZERO-HANDLE(未产出)"
                             : (rc176a == -100002) ? "CALLBACK-ERR(-100002)"
                             : (rc176a == -10000)  ? "NOT-IMPLEMENTED" : "OTHER";
            const char *v176c = (g_pts_dp3_newperc) ? "PARACLIENT-NEW-PER-CALL(h1,h2)"
                             : (rc176a == 0 && rc176b == 0 && h1 != NULL && h2 != NULL && h1 == h2)
                                 ? "CACHED-SAME-HANDLE(须点名缓存支)" : "NOT-NEW-PER-CALL";
            const char *v192 = (rc192a == 0 && rc192b == 0) ? "BOTH-RECYCLED"
                             : (skip192 == 1) ? "SECOND-RECYCLE-SKIPPED(h2==h1)"
                             : (rc192a == 0 || rc192b == 0) ? "PARTIAL-RECYCLE" : "RECYCLE-FAILED";
            const char *v200 = (rc200_null == rc200_hand) ? "CONSTANT-GREEN(禁用为判别器)"
                             : "DISCRIMINATES";
            fprintf(stderr, "[DRIVE-PROBE3] where=%s window=in nmp176=%p pfsclient=%p t3_176=%d "
                            "out_pre_h1=%p rc176a=%d h1=%p rc176b=%d h2=%p h2_ne_h1=%d "
                            "rc192a=%d rc192b=%d skip192=%d rc192t3=%d rc200_null=%d rc200_hand=%d "
                            "ctx_live=%d v176a=%s v176=%s v192=%s v200=%s slot176=%p slot192=%p slot200=%p calls=%d "
                            "keep=%p keeprc=%d\n",
                    where, nmp176, pfsclient, t3_176, g_pts_dp3_pre_h1, rc176a, h1, rc176b, h2,
                    (h1 != NULL && h2 != NULL && h1 != h2) ? 1 : 0,
                    rc192a, rc192b, skip192, g_pts_dp3_192_t3, rc200_null, rc200_hand,
                    g_pts_dp3_ctx_live, v176a, v176c, v192, v200, fp176, fp192, fp200,
                    g_pts_dp3_calls, hK, rcK);
            (void)keep_extra_recycled;
        } else {
            fprintf(stderr, "[DRIVE-PROBE3] where=%s window=in SKIP reason=%s slot176=%p nmp1=%p\n",
                    where, (nmp1 == NULL) ? "no-nmp176" : "null-slot176", fp176, nmp1);
        }
    } else {
        fprintf(stderr, "[DRIVE-PROBE2] where=%s window=in SKIP reason=%s slot136=%p nmseg=%p\n",
                where, (nmSeg1 == NULL) ? "no-nmseg" : "null-slot136", fp136, nmSeg1);
    }

#if WPF_PTS_FSP_PL_METHODS_SNAP
    /* ⏪ `t167` D1 → D2 →（都过才）D3。**顺序写死**：先证明"副本有效"，才谈槽序，再谈调用。 */
    for (int _i = 0; _i < g_pts_io_live_n; _i++) {
        wpf_pts_io_table *t = g_pts_io_live[_i];
        if (t->magic != WPF_PTS_IO_MAGIC) continue;
        const int d1_same = wpf_pts_methods_readback(t, where);   /* D1：驱动点读回 ＋ 逐字比对 */
        const int d2_ok   = wpf_pts_methods_d2(t);                /* D2：零位指纹 */
#if WPF_PTS_FSP_PL_ENGINE_DRIVE
        if (d2_ok) {
            /* ⏪ `t168`（队长口径三）：**调用源 ＝ 值化副本**（`methods_snap` 里的 17 个指针值），
               **不是**悬垂指针、**不是**原始缓冲 ⇒ 本条同时把 `THUNK-LIVENESS` 从"判定"升为读数。 */
            fprintf(stderr, "[FSPARAMETH-D3] gate=PASS（D2 slot-order ok；**调用源＝值化副本**）"
                            " src=methods_snap d1_same=%d v=THUNK-LIVENESS-TEST\n", d1_same);
            wpf_pts_engine_drive_from(d, (const void *)t->methods_snap, where);
        } else {
            fprintf(stderr, "[FSPARAMETH-D3] gate=SKIP reason=slot-order-mismatch-or-no-valid-copy "
                            "d1_same=%d d2_ok=%d v=D3-NOT-ATTEMPTED（调用了才谈调用失败）\n", d1_same, d2_ok);
        }
#else
        (void)d1_same; (void)d2_ok;
        fprintf(stderr, "[FSPARAMETH-D3] gate=DISABLED（本副本未开 ENGINE_DRIVE）\n");
#endif
    }
#endif
#if WPF_PTS_FSP_PL_ENGINE_DRIVE && !WPF_PTS_FSP_PL_METHODS_SNAP
    if (g_pts_sub_live_n > 0 || 1) wpf_pts_engine_drive_from(d, NULL, where);  /* ⏪ t165 E2（原始缓冲；t168 起有副本路径） */
#endif
    g_pts_dp_calls++;
    g_pts_dp_56_fserr = rc56a; g_pts_dp_56_fsuccess = fSuccess1; g_pts_dp_56_next = (const void *)nmsNext1;
    g_pts_dp_80_fserr = rc80a; g_pts_dp_80_segment = (const void *)nmSeg1;
    g_pts_dp_idem = ((rc56a == rc56b) && (fSuccess1 == fSuccess2) && (nmsNext1 == nmsNext2) ? 1 : 0)
                  | ((rc80a == rc80b) && (nmSeg1 == nmSeg2) ? 2 : 0);
    g_pts_dp_gate = wpf_pts_drive_probe_enabled();

    const char *v56 = (rc56a == 0 && fSuccess1 == 0 && nmsNext1 == NULL) ? "NEXTSECTION-ABSENT(by-design)"
                    : (rc56a != 0 ? "CALLBACK-ERR" : "NEXTSECTION-OTHER");
    const char *v80 = (rc80a == 0 && nmSeg1 != NULL) ? "MAINTEXTSEG-LIVE-HANDLE"
                    : (rc80a != 0 ? "CALLBACK-ERR" : "MAINTEXTSEG-ZERO-HANDLE");
    fprintf(stderr, "[DRIVE-PROBE] where=%s nms=%p pfsclient=%p slot56=%p slot80=%p fake=%d t3mode=%d "
                    "rc56a=%d fSuccess1=%d nmsNext1=%p rc56b=%d fSuccess2=%d nmsNext2=%p idem56=%d "
                    "rc80a=%d nmSeg1=%p rc80b=%d nmSeg2=%p idem80=%d v56=%s v80=%s\n",
            where, nms56, pfsclient, fp56, fp80, WPF_PTS_DRIVE_PROBE_FAKE_NMS, t3mode,
            rc56a, fSuccess1, nmsNext1, rc56b, fSuccess2, nmsNext2,
            ((g_pts_dp_idem & 1) ? 1 : 0), rc80a, nmSeg1, rc80b, nmSeg2,
            ((g_pts_dp_idem & 2) ? 1 : 0), v56, v80);
    d->in_win = 0;   /* ⏪ `T-A33`：**退出格式窗**（此后 `+176` 一律不发调；见 `wpf_pts_qtp_create_safe`） */
}


// ── 格 6（`t110`／P1-W35 · W8 第四步）：`CreateDocContext` **真实现** ─────────────────
//   分界句（沿用前三件，逐字）：**`return 0`（`fserrNone`）本身不是证据**；证据是「这次调用在本进程内
//   留下了**与该对象绑定**、**可被独立读取**的状态变化」。四件套 ＋ 形状约束：
//     ① **入参形状校验**：`fscontextinfo`（`ref` ⇒ 实参是地址）为 `NULL` ⇒ 拒绝（**一个字节都不读/不写**）；
//        `pfscontext`（`out`）为 `NULL` ⇒ 拒绝（**不给"写空也算成功"**）；
//     ② **出参真落盘且与本次调用绑定**：`*pfscontext` 指向**本次真分配**的对象（**不是**进程级全局单例
//        ⇒ 两次调用的两个句柄必须**不同**）；**按对象绑定**由 ③ 的字段读回承担（"句柄不同"只是必要条件）；
//     ③ **该对象真带走了入参结构里的可判定量**：逐字段读回 `version`／`fsffi`／`cInstalledObjects`／
//        `pInstalledObjects`／`pfsclient`／`ptsPenaltyModule`（**≥2 项**，本实现给 6 项）；
//        ⚠️ **逐字段按真实类型读，不整块 `memcpy`**（判据 §1.6-③ 的形状约束）；
//     ④ **计数 ＋ 可独立读取**：`g_pts_doc_sets_c`／`g_pts_doc_rejected_c` ＋ 按对象的只读面
//        （`WpfLinuxWin32_PtsDocFieldAt` 逐字段 + `…PtsDocLive`／`…PtsDocCreates`／`…PtsDocDestroys`）。
//   ⚠️ **非目标**：不实现 PTS 排版语义（不建页、不断行），不 deref 任何传入指针。
int CreateDocContext(const void *fscontextinfo, void **pfscontext)
{
    if (pfscontext) *pfscontext = NULL;                        /* 任何失败路径都保持"空" */
    /* ⏪ `t141`（判据 2）：四条**拒绝**路径都改成**响亮失败＋具名留痕**（原为一句话裸返；
       目的＝让"**未快照**"这一态在日志里有名有姓，与"已快照但全 0"不混同）。 */
    if (!pfscontext)                     { g_pts_doc_rejected_c++; wpf_pts_fscbk_snap_gap("null-out-param", fscontextinfo, NULL); return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    if (!fscontextinfo)                  { g_pts_doc_rejected_c++; wpf_pts_fscbk_snap_gap("null-info", fscontextinfo, NULL);       return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    if (g_pts_doc_live_n >= WPF_PTS_DOC_MAX) { g_pts_doc_rejected_c++; wpf_pts_fscbk_snap_gap("table-full", fscontextinfo, NULL); return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    wpf_pts_doc *c = (wpf_pts_doc *)calloc(1, sizeof(*c));
    if (!c)                              { g_pts_doc_rejected_c++; wpf_pts_fscbk_snap_gap("alloc-fail", fscontextinfo, NULL);       return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    /* 逐字段按**真实类型**读（每步只读该字段的字节数；指针字段只当**值**取，不 deref） */
    const unsigned char *b = (const unsigned char *)fscontextinfo;
    c->magic  = WPF_PTS_DOC_MAGIC;
    c->info_addr           = fscontextinfo;
    c->version             = *(const unsigned int *)(const void *)(b +  0);
    c->fsffi               = *(const unsigned int *)(const void *)(b +  4);
    c->c_installed_objects = *(const int          *)(const void *)(b + 12);
    c->p_installed_objects = *(const void *const *)(const void *)(b + 16);
    c->p_fsclient          = *(const void *const *)(const void *)(b + 24);
    c->pts_penalty_module  = *(const void *const *)(const void *)(b + 32);
    /* ⏪ `t141`（P1-W61）**承重前置**：**调用期内**把回调表值拷贝进本对象。
       ⚠️ 失败 ⇒ **释放并拒绝**（`state == NONE`）⇒ **绝不**登记一个"看起来有表、其实没拷"的对象。
       放在 `t133` 探针**之前**：本步是承重的，探针只是仪器。 */
    wpf_pts_fscbk_snapshot(c, fscontextinfo);
    if (c->fscbk_snap_state == WPF_PTS_FSCBK_SNAP_NONE) { free(c); return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    /* ⏪ `t133`（P1-W55）测量小单：**只读回读** `FSCBK` 窗口（**绝不试调**任何回调）。
       ⚠️ 窗口 `b+40 .. b+864` 对**真实** `FSCONTEXTINFO`（872 B）在界内；夹具的合成结构也已按
          同一窗口**加宽**（见 `wpf_pts_fsctx_probe.probe_pad`）⇒ 夹具路径同样在界内。 */
    wpf_pts_fscbk_probe(fscontextinfo, "CreateDocContext");
    g_pts_doc_live[g_pts_doc_live_n++] = c;
    g_pts_ctx_alive_n++;                    /* ⏪ t156：现存活上下文数（native 侧自记） */
    g_pts_doc_sets_c++;
    {   /* 观测镜（**镜像**，不是权威）：记下"哪个入参结构地址、落出什么句柄"；指针量走 `ptr0`/`ptr1` */
        int a_ok = 0;
        for (int k = 0; k < g_pts_doc_live_n; k++) {
            if ((const void *)g_pts_doc_live[k] == (const void *)c) { a_ok = 1; break; }
        }
        wpf_pts_jmp_push("CreateDocContext", (void *)fscontextinfo,
                         (const void *)&c->version, a_ok, 0,
                         (int)c->version, (int)c->fsffi, c->c_installed_objects, 0,
                         (const void *)c, (const void *)c->info_addr);
    }
    { int _i = wpf_pts_index("CreateDocContext"); if (_i >= 0) g_pts_seen[_i]++; }
    g_pts_seq++;
    *pfscontext = (void *)c;
    return 0;                                                  /* ← 改成别的值就是制造静默半通 */
}

// ── 收尾同侪 ①（**本步二选一声明：升级为真实现**）：`DestroyDocContext`
//   ⚠️ 为什么必须升级：`CreateDocContext` 变真之后，`:488 PTS.Validate(PTS.DestroyDocContext(...))`
//     第一次可达（门 ＝ `:479 Count>4`），而它用 `Validate`（**会抛**）⇒ 若维持 stub（恒返 -10000）
//     一旦被走到就**当场抛 `PtsException`** ⇒ 把"优雅降级"换成"清理期异常"。本模块的纪律是
//     "**create 成功 ⇒ destroy 必须存在且真能收**"（`LoCreateContext`→`LoDestroyContext` 同形）。
//   拒绝面（**四条**，都返非 0 且**一个字节都不 free**）：`NULL`／未登记（未知或伪造）／魔数不符
//   （已失效 ＝ 重复销毁）／登记表为空。**只比对指针身份**，未知句柄的**内容一个字节都不读**。
int DestroyDocContext(void *pfscontext)
{
#if WPF_PTS_DRIVE_PROBE3_CTXDEAD
    /* ⏪ `t156`（**只在副本产物**，判据 §8.3.3）：**新 FailFast 通路**的反腿 —— 在 context 的
       销毁点上调 `+176`，期望撞 `PtsContext.CreateHandle` 的 `!this.Disposed`
       （"PtsContext is already disposed."）⇒ **不可捕获 `FailFast`**（`app_rc=134` 家族）。
       **主链绝不开此开关**（P6：主链出现 `FailFast` 即红）。 */
    if (g_pts_dp3_st_nmp && g_pts_dp3_st_fp176) {
        void *hD = NULL;
        g_pts_ctx_dead_calls++;
        int rcD = ((wpf_pts_fn_create_paraclient)g_pts_dp3_st_fp176)(
                      (const void *)g_pts_dp3_st_client, (const void *)g_pts_dp3_st_nmp, &hD);
        g_pts_ctx_dead_rc = rcD;
        fprintf(stderr, "[DRIVE-PROBE3-CTXDEAD] rc176=%d h=%p nmp=%p ctx=%p calls=%d\n",
                rcD, hD, (const void *)g_pts_dp3_st_nmp, pfscontext, g_pts_ctx_dead_calls);
        if (hD && g_pts_dp3_st_fp192) {
            int rcR = ((wpf_pts_fn_destroy_paraclient)g_pts_dp3_st_fp192)(
                          (const void *)g_pts_dp3_st_client, (const void *)hD);
            fprintf(stderr, "[DRIVE-PROBE3-CTXDEAD] 回收 rc192=%d\n", rcR);
        }
    }
#endif
    if (!pfscontext) { g_pts_doc_destroy_rej++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
    for (int i = 0; i < g_pts_doc_live_n; i++) {
        if ((void *)g_pts_doc_live[i] != pfscontext) continue;
        if (g_pts_doc_live[i]->magic != WPF_PTS_DOC_MAGIC) { g_pts_doc_destroy_rej++; return WPF_PTS_ERR_NOT_IMPLEMENTED; }
        if (g_pts_doc_live[i]->sub) {                          /* ⏪ `t162` 销毁口径：**只有本侧**
                                                                  销毁自有子轨对象（窗口内绝不销毁、
                                                                  填进列表后不销毁） */
            wpf_pts_sub_destroy(g_pts_doc_live[i]->sub);       /* ⏪ `T-A25`：**递归**销毁整棵子树 */
            g_pts_doc_live[i]->sub = NULL;
        }
        /* ⏪ `T-A25`：若本窗建的**子段对象**还没被过继给 `dp->sub`（例如该 doc 没有走到
           `FsQueryTrackParaList` 的填充点）⇒ 在此**顺手回收**（否则是活条目泄漏）。 */
        for (int _k = 0; _k < WPF_PTS_SUB_CHILD_MAX; _k++) {
            if (g_pts_doc_live[i]->sub_child_objs[_k]) {
                wpf_pts_sub_destroy(g_pts_doc_live[i]->sub_child_objs[_k]);
                g_pts_doc_live[i]->sub_child_objs[_k] = NULL;
            }
        }
        g_pts_doc_live[i]->sub_child_objs_n = 0;
        /* ⏪ `T-A22`（`N1`）：该 doc 名下的**来源证据**随 doc 注销**整体失效**（持有期＝托管对象
           生存期的 native 对偶：上下文一没，来源事实就无从核验 ⇒ 此后任何同值入参**必被拒**）。 */
        wpf_pts_prov_retire((const void *)g_pts_doc_live[i], 0, "doc-destroyed");
        g_pts_doc_live[i]->magic = 0;                          /* 先失效 ⇒ 重复销毁必被拒 */
        free(g_pts_doc_live[i]);
        g_pts_doc_live[i] = g_pts_doc_live[--g_pts_doc_live_n];
        g_pts_doc_live[g_pts_doc_live_n] = NULL;
        if (g_pts_ctx_alive_n > 0) g_pts_ctx_alive_n--;   /* ⏪ t156：现存活上下文数（native 侧自记） */
        g_pts_doc_destroys++;
        return 0;
    }
    g_pts_doc_destroy_rej++;
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

// ── ⏪ `T-A52`（`NATIVE-PTS-FLOATERCBK`）：`GetFloaterHandlerInfo` 由**具名 GAP** 升为**真实现** ─────────
//   上游语义（`Pts.cs:3065`；调用链 `PtsHost.GetObjectHandlerInfo`（`PtsHost.cs:1092`，`idobj==FloaterParagraphId`）
//     → `PtsCache.GetFloaterHandlerInfoCore`（`:248`）→ `PTS.GetFloaterHandlerInfo(ref FloaterInit, pobjectinfo)`）：
//     托管把 `FSFLOATERINIT.fsfloatercbk`（16 个**已赋值的**托管回调）逐槽交给 native 的 `pObjectInfo`。
//   🔴 **本实现的诚实形态**：入参 `pfsfloaterinit` 即 `FSFLOATERINIT*`（**唯一**字段 ＝ `FSFLOATERCBK`，128 B）
//      ⇒ 逐槽**只读捕获函数指针值**（**不 deref** 托管结构；同 `pfnFormatLine` 体例）到本侧持有位
//      `g_pts_floater_cbk[]`（后续 `pfnFormatFloaterContentFinite` 的发调源）；出参 `pFloaterObjectInfo`
//      非空时**逐槽原样转写**（真实语义：native 对象信息 ＝ 该回调表），为空则只捕获（**不越界写**）。
//   **零假值 / 永不假成功**：`pfsfloaterinit == NULL` ⇒ **拒**（返 `-10000` ＋ 具名 `[FS_PAGE_GAP]`，出参一字不写）。
int GetFloaterHandlerInfo(const void *pfsfloaterinit, void *pFloaterObjectInfo)
{
    if (!pfsfloaterinit) {
        g_pts_floater_cbk_gap++;
        fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=null-init entry=GetFloaterHandlerInfo init=%p out=%p "
                        "out=UNWRITTEN bytes=0\n",
                WPF_PTS_ERR_NOT_IMPLEMENTED, pfsfloaterinit, pFloaterObjectInfo);
        return WPF_PTS_ERR_NOT_IMPLEMENTED;
    }
    const void *const *src = (const void *const *)pfsfloaterinit;
    if (pFloaterObjectInfo) {
        const void **dst = (const void **)pFloaterObjectInfo;
        for (int i = 0; i < WPF_PTS_FLOATERCBK_SLOTS; i++) dst[i] = src[i];
    }
    for (int i = 0; i < WPF_PTS_FLOATERCBK_SLOTS; i++) g_pts_floater_cbk[i] = src[i];
    g_pts_floater_cbk_ok++;
    fprintf(stderr, "[FSFLOATER-CBK] rc=0 entry=GetFloaterHandlerInfo init=%p out=%p slots=%d "
                    "fmtFinite=%p fmtBottomless=%p out=%s bytes=%d src=managed-FSFLOATERINIT\n",
            pfsfloaterinit, pFloaterObjectInfo, WPF_PTS_FLOATERCBK_SLOTS,
            g_pts_floater_cbk[WPF_PTS_FLOATER_IDX_FMT_FINITE], g_pts_floater_cbk[2],
            pFloaterObjectInfo ? "WRITTEN" : "skipped(null-out)",
            pFloaterObjectInfo ? (int)(WPF_PTS_FLOATERCBK_SLOTS * (int)sizeof(void *)) : 0);
    return 0;
}

// ── ⏪ `T-A53`（`NATIVE-PTS-TABLEOBJ`）：`GetTableObjHandlerInfo` 由**具名 GAP** 升为**真实现** ───────────
//   上游语义（`Pts.cs:3071`；调用链 `PtsHost.GetObjectHandlerInfo`（`PtsHost.cs:1096`，`idobj==TableParagraphId`）
//     → `PtsCache.GetTableObjHandlerInfoCore`（`:353`）→ `PTS.GetTableObjHandlerInfo(ref TableobjInit, pobjectinfo)`）：
//     托管把 `FSTABLEOBJINIT`（45 槽／360 B）逐槽交给 native 的 `pTableObjectInfo`。
//   🔴 **本实现的诚实形态**：入参 `pfstableobjinit` 即 `FSTABLEOBJINIT*` ⇒ 逐槽**只读捕获函数指针值**
//      （**不 deref** 托管结构；同 `GetFloaterHandlerInfo` 体例）到本侧持有位 `g_pts_tableobj_cbk[]`；
//      出参 `pTableObjectInfo` 非空时**逐槽原样转写**，为空则只捕获（**不越界写**）。
//   **零假值 / 永不假成功**：`pfstableobjinit == NULL` ⇒ **拒**（返 `-10000` ＋ 具名 `[FS_PAGE_GAP]`，出参一字不写）。
int GetTableObjHandlerInfo(const void *pfstableobjinit, void *pTableObjectInfo)
{
    if (!pfstableobjinit) {
        g_pts_tableobj_cbk_gap++;
        fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=null-init entry=GetTableObjHandlerInfo init=%p out=%p "
                        "out=UNWRITTEN bytes=0\n",
                WPF_PTS_ERR_NOT_IMPLEMENTED, pfstableobjinit, pTableObjectInfo);
        return WPF_PTS_ERR_NOT_IMPLEMENTED;
    }
    const void *const *src = (const void *const *)pfstableobjinit;
    if (pTableObjectInfo) {
        const void **dst = (const void **)pTableObjectInfo;
        for (int i = 0; i < WPF_PTS_TABLEOBJ_SLOTS; i++) dst[i] = src[i];
    }
    for (int i = 0; i < WPF_PTS_TABLEOBJ_SLOTS; i++) g_pts_tableobj_cbk[i] = src[i];
    g_pts_tableobj_cbk_ok++;
    fprintf(stderr, "[FSTABLEOBJ-CBK] rc=0 entry=GetTableObjHandlerInfo init=%p out=%p slots=%d "
                    "getTableProps=%p autofit=%p firstRow=%p nextRow=%p rowProps=%p cells=%p "
                    "fmtCellFinite=%p out=%s bytes=%d src=managed-FSTABLEOBJINIT\n",
            pfstableobjinit, pTableObjectInfo, WPF_PTS_TABLEOBJ_SLOTS,
            g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_GETTABLEPROPS],
            g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_AUTOFITTABLE],
            g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_GETFIRSTROW],
            g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_GETNEXTROW],
            g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_GETROWPROPS],
            g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_GETCELLS],
            g_pts_tableobj_cbk[20],
            pTableObjectInfo ? "WRITTEN" : "skipped(null-out)",
            pTableObjectInfo ? (int)(WPF_PTS_TABLEOBJ_SLOTS * (int)sizeof(void *)) : 0);
    return 0;
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
// ── 格 6（`t110`／P1-W35 · W8 **第四步**）：`CreateDocContext` 真实现 ─────────────────
//   上游签名（`Pts.cs:3090-3094`，**方法名约定**声明、无显式 `EntryPoint`）：
//     int CreateDocContext([In] ref FSCONTEXTINFO fscontextinfo, out IntPtr pfscontext);
//   入参结构（`Pts.cs:833-844`，**本仓唯一的布局权威**）：
//     +0  uint version ｜ +4  uint fsffi ｜ +8  int drMinColumnBalancingStep ｜ +12 int cInstalledObjects
//     +16 IntPtr pInstalledObjects ｜ +24 IntPtr pfsclient ｜ +32 IntPtr ptsPenaltyModule ｜ …
//   🔴 **形状约束（判据 §1.6-③，逐字遵守）**：`fscontextinfo` 是 **`ref` 一个托管结构** ⇒
//     **不许整块 `memcpy`**（那＝把"未证实的布局"当既定事实，`D-G136` 同族）。本实现**逐字段
//     按真实类型读**（前三个 `u32`／`i32`，随后三个**指针**），且**每个偏移都带断言**：
//     读回对拍由自检格 `86` 承担，对不上就**点名该字段**（不是静默把错布局当对）。
//   ⚠️ 偏移假设的证据现取位：`Pts.cs:835-841`（逐字段声明）＋ `:842 FSCBK fscbk` 是**委托**型
//     （托管引用 ⇒ 8 字节）⇒ 四个指针字段都落在 8 的倍数上、无填充。若该假设错，自检会在
//     `field_readback` 那一格**当场红**并点名字段（可证伪）。
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

// ── 格 6 · 只读面（`t110`／P1-W35）：`CreateDocContext` 的**独立读取面** ────────────────
//   为什么要这些口：判据 C9 的判绿**不许**停在"两个句柄不同"（那只是必要条件）；"按对象绑定"
//   必须由**字段读回**承担 ⇒ 需要一个**不经过出参**的读回口。`field` 逐字段取值：
//     0 = version ｜ 1 = fsffi ｜ 2 = cInstalledObjects ｜ 3 = info_addr
//     4 = pInstalledObjects ｜ 5 = pfsclient ｜ 6 = ptsPenaltyModule
//   ⚠️ **位置读**（与 `…PenaltyModuleHandleAt` 同族，`F-6` 口径句同样适用）：越界/无 ⇒ NULL/0；
//      **不得跨销毁缓存 `idx`**，每次按当前登记表重算。
void *WpfLinuxWin32_PtsDocFieldAt(int idx, int field)
{
    if (idx < 0 || idx >= g_pts_doc_live_n) return NULL;
    wpf_pts_doc *d = g_pts_doc_live[idx];
    if (!d || d->magic != WPF_PTS_DOC_MAGIC) return NULL;      /* 魔数不符 ⇒ 当"没有"，不读内容 */
    switch (field) {
        case 0:  return (void *)(unsigned long)d->version;
        case 1:  return (void *)(unsigned long)d->fsffi;
        case 2:  return (void *)(long)d->c_installed_objects;
        case 3:  return (void *)d->info_addr;
        case 4:  return (void *)d->p_installed_objects;
        case 5:  return (void *)d->p_fsclient;
        case 6:  return (void *)d->pts_penalty_module;
        default: return NULL;
    }
}
int WpfLinuxWin32_PtsDocLive(void)      { return g_pts_doc_live_n; }
int WpfLinuxWin32_PtsDocCreates(void)   { return g_pts_doc_sets_c; }
int WpfLinuxWin32_PtsDocDestroys(void)  { return g_pts_doc_destroys; }   /* 收尾面二值读数用 */
int WpfLinuxWin32_PtsDocRejected(void)  { return g_pts_doc_rejected_c; }

/* ⏪ `t141`：`PRECOND-FSCBK-SNAPSHOT-IN-DOC` 的**只读面**（判据 3：按**真实类型**给形状，位宽不猜）
     · `…PtsDocFscbkSnapState(idx)`   `-1` 无此对象（越界/魔数不符）／`0` 未快照／
                                      `1` **已快照但全 0**／`2` **已快照且非全 0**
     · `…PtsDocFscbkSnapNonzero(idx)` `-1` 同上／否则**非 0 的 8 B 字数**（0..103）
     · `…PtsDocFscbkSnapGap()`        "未快照"（**响亮拒绝**）累计次数（每条都配一行具名行）
     · `…PtsDocFscbkSnapTaken()`      快照**成功**累计次数
     · `…PtsDocFscbkSnapAllZero()`    已快照但**全 0** 的累计次数
     · `…PtsDocFscbkWordAt(idx, k, out)` 把快照里**相对窗口起点**第 `k` 个字（0..102）按
                                      **8 B 无符号整数**写进出参；成功返 `0`；
                                      越界／无此对象／空出参 ⇒ 返 `-1` 且**一个字节都不写**。
   ⚠️ **语义边界（如实划界）**：这 8 B 是**封送后的函数指针或 `IntPtr`**（`FSCBK` 的槽就是这两种声明）；
      本口**只给值**、**不 deref**、**不代它断言"是哪个回调"**，也**不**证"该槽可调用"。
      「**未快照**」与「**快照了但全 0**」**不同形**：前者状态 `0` 且对象**根本未登记**（⇒ `-1`），
      后者状态 `1`（对象在册、`nonzero=0`）。 */
int WpfLinuxWin32_PtsDocFscbkSnapState(int idx)
{
    if (idx < 0 || idx >= g_pts_doc_live_n) return -1;
    wpf_pts_doc *d = g_pts_doc_live[idx];
    if (!d || d->magic != WPF_PTS_DOC_MAGIC) return -1;
    return d->fscbk_snap_state;
}
int WpfLinuxWin32_PtsDocFscbkSnapNonzero(int idx)
{
    if (idx < 0 || idx >= g_pts_doc_live_n) return -1;
    wpf_pts_doc *d = g_pts_doc_live[idx];
    if (!d || d->magic != WPF_PTS_DOC_MAGIC) return -1;
    if (d->fscbk_snap_state == WPF_PTS_FSCBK_SNAP_NONE) return -1;
    return d->fscbk_snap_nonzero;
}
int WpfLinuxWin32_PtsDocFscbkSnapGap(void)     { return g_pts_fscbk_snap_gap; }
int WpfLinuxWin32_PtsDocFscbkSnapTaken(void)   { return g_pts_fscbk_snap_taken; }
int WpfLinuxWin32_PtsDocFscbkSnapAllZero(void) { return g_pts_fscbk_snap_allzero; }

/* ⏪ `t146`：**驱动探针的只读面**（判据件 §5.1 `R8`；值域/语义写死如下）
     · `…PtsDriveProbeCalls()`  真正**发出过调用**的窗口数（=0 ⇒ 探针根本没跑 ⇒ **不许当绿**）
     · `…PtsDriveProbeSkips()` + `…PtsDriveProbeLastSkip()`  被跳过的窗口数／原因 token
     · `…PtsDriveProbe56Fserr()` / `…56Success()` / `…56Next()`   `+56` 那两条的**如实**读数
     · `…PtsDriveProbe80Fserr()` / `…80Segment()`                 `+80` 那一条的**如实**读数
     · `…PtsDriveProbeIdem()`  bit0 = `+56` 两次同值；bit1 = `+80` 两次同值
   ⚠️ **语义边界（判据 §2.3）**：这些口**只**报“回调返回了什么”；**不**证“该句柄在托管表内且 live
      且 `Obj is Section/ContainerParagraph`” —— 那一句**本探针证不了**，只能由**表主**给读数。 */
int WpfLinuxWin32_PtsDriveProbeCalls(void)     { return g_pts_dp_calls; }
int WpfLinuxWin32_PtsDriveProbeSkips(void)     { return g_pts_dp_skips; }
const char *WpfLinuxWin32_PtsDriveProbeLastSkip(void) { return g_pts_dp_last_skip; }
int WpfLinuxWin32_PtsDriveProbe56Fserr(void)   { return g_pts_dp_56_fserr; }
int WpfLinuxWin32_PtsDriveProbe56Success(void) { return g_pts_dp_56_fsuccess; }
void *WpfLinuxWin32_PtsDriveProbe56Next(void)  { return (void *)g_pts_dp_56_next; }
int WpfLinuxWin32_PtsDriveProbe80Fserr(void)   { return g_pts_dp_80_fserr; }
void *WpfLinuxWin32_PtsDriveProbe80Segment(void){ return (void *)g_pts_dp_80_segment; }
int WpfLinuxWin32_PtsDriveProbeIdem(void)      { return g_pts_dp_idem; }
int WpfLinuxWin32_PtsDocFscbkWordAt(int idx, int k, unsigned long long *out)
{
    if (!out) return -1;
    if (idx < 0 || idx >= g_pts_doc_live_n) return -1;
    wpf_pts_doc *d = g_pts_doc_live[idx];
    if (!d || d->magic != WPF_PTS_DOC_MAGIC) return -1;
    if (d->fscbk_snap_state == WPF_PTS_FSCBK_SNAP_NONE) return -1;
    if (k < 0 || k >= WPF_PTS_FSCBK_SNAP_WORDS) return -1;
    unsigned long long v = 0;
    for (int i = 0; i < 8; i++) v |= ((unsigned long long)d->fscbk_snap[k * 8 + i]) << (8 * i);
    *out = v;
    return 0;
}

// ── 格 7 · 只读面（`t123`／P1-W46）：`FsCreatePageBottomless` 的**成功/失败面**（判据 C4 的承重口）──
//   为什么要这几个口：判据 §2.2 形态 (b) 指出 **托管侧 `ValidateAndTrace` 在常见情形下不抛、且只在
//   tracing 开时记一行** ⇒ 「返非 0 却没有任何痕迹」是**新开出来的假绿通路**。本模块把"痕迹"落在
//   **native 侧**（计数器 ＋ `[FS_PAGE_GAP]` 具名行），本口就是它的机器可读面：
//     · `…FsPageGap()`     **返非 0 的总次数**（诚实 stub ⇒ ≥1；真实现 ⇒ 0）
//     · `…FsPageCreated()` 成功次数（真实现 ⇒ ≥1）
//     · `…FsPageRejected()` 形状/身份校验被拒次数（含在 `gap` 里）
//     · `…FsPageLastReason()` 最后一次失败的**原因 token**（`none` 表示尚无失败）
//   语义边界（如实划界）：本口**只**证"该入口被调用过、结果如何"；**不**证"页面排版出来了"。
int WpfLinuxWin32_PtsFsPageGap(void)     { return g_pts_fsp_gap; }
int WpfLinuxWin32_PtsFsPageCreated(void) { return g_pts_fsp_ok; }
int WpfLinuxWin32_PtsFsPageRejected(void){ return g_pts_fsp_rej; }
int WpfLinuxWin32_PtsFsPageLive(void)    { return g_pts_fsp_live_n; }
const char *WpfLinuxWin32_PtsFsPageLastReason(void) { return g_pts_fsp_last_reason; }
/* ⏪ `t125`：销毁路径两条同伴的成败面（与格 7 同口径：**失败必留痕**）。 */
int WpfLinuxWin32_PtsFsQueryPageOk(void)    { return g_pts_fsp_qpd_ok; }
int WpfLinuxWin32_PtsFsQueryPageGap(void)   { return g_pts_fsp_qpd_gap; }
int WpfLinuxWin32_PtsFsDestroyPageOk(void)  { return g_pts_fsp_des_ok; }
int WpfLinuxWin32_PtsFsDestroyPageGap(void) { return g_pts_fsp_des_gap; }
/* ⏪ `t127`：`FsQueryTrackDetails`／`FsCreatePageFinite` 的成败面。 */
int WpfLinuxWin32_PtsFsTrackOk(void)       { return g_pts_fsp_trk_ok; }
int WpfLinuxWin32_PtsFsTrackGap(void)      { return g_pts_fsp_trk_gap; }
int WpfLinuxWin32_PtsFsFiniteOk(void)      { return g_pts_fsp_fin_ok; }
int WpfLinuxWin32_PtsFsFiniteGap(void)     { return g_pts_fsp_fin_gap; }
int WpfLinuxWin32_PtsFsParaListOk(void)    { return g_pts_fsp_pl_ok; }
int WpfLinuxWin32_PtsFsParaListGap(void)   { return g_pts_fsp_pl_gap; }
/* ⏪ `t127`／裁定二十七 · **字段级诚实性**的独立读取面：**调用方要用的那个句柄**当前是否
   "**属于我们自己的对象**"（① 可身份校验）。**只做指针值比较，不 deref**。 */
int WpfLinuxWin32_PtsTrackOwned(const void *track) { return wpf_pts_track_owned(track); }

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
                     "inth_sets=%d inth_rej=%d doc_live=%d doc_sets=%d doc_rej=%d doc_des=%d doc_desrej=%d",
                     seen, g_pts_seq, anchor, WPF_PTS_ERR_NOT_IMPLEMENTED,
                     frontier,
                     g_pts_calls[0], g_pts_calls[1], g_pts_calls[2], g_pts_calls[3], g_pts_calls[4],
                     g_pts_calls[5], g_pts_calls[6], g_pts_calls[7], g_pts_calls[8], g_pts_calls[9],
                     g_pts_calls[10], g_pts_calls[11],
                     g_pts_io_live_n,
                     g_pts_loc_live_n, g_pts_loc_creates, g_pts_loc_destroys, g_pts_loc_rejected,
                     g_pts_doc_sets, g_pts_doc_rejected, g_pts_break_sets, g_pts_break_rejected,
                     g_pts_inth_sets, g_pts_inth_rejected,
                     g_pts_doc_live_n, g_pts_doc_sets_c, g_pts_doc_rejected_c,
                     g_pts_doc_destroys, g_pts_doc_destroy_rej);
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
// ── 格 6 夹具（`t110`／P1-W35 · W8 第四步）：`CreateDocContext` 的**出参绑定 ＋ 字段读回** ─────
//   为什么要**造入参结构**：靶心的证据不能停在"两个句柄不同"（那只是**必要**条件，只证"不是同一个
//   常量"）；"与**本次调用**绑定"必须由**字段读回**承担（`t97`／`t103` 两次同口径）。本夹具按
//   `Pts.cs:833-844` 的字段序**逐字段**写下一个可判定的入参结构，再断言实现把它们**逐项读进对象**。
//   ⚠️ **偏移假设自证（本夹具的关键）**：C 里这个 `wpf_pts_fsctx_probe` **自带** `_Static_assert`
//   逐字段偏移断言（编译期）；`version`／`fsffi`／`cInstalledObjects` 用**互不相同**的已知值 ⇒
//   实现若在错偏移上读，**必然不等** ⇒ 该断言**在净腿上也有牙**（`t103` 格 85 的教训）。
typedef struct {                    /* 只为夹具服务；字段序/布局与 `Pts.cs:833-844` 对齐 */
    unsigned int version;
    unsigned int fsffi;
    int          dr_min_column_balancing_step;
    int          c_installed_objects;
    void        *p_installed_objects;
    void        *p_fsclient;
    void        *pts_penalty_module;
    void        *fscbk;             /* 占位：真身是委托（8 B）⇒ 保证前面各指针的偏移 */
    /* ⏪ `t133`（P1-W55）dated 更正（**纯注释修正，不动任何行为**）：上面那句里的「真身是委托（8 B）」
       **是错的**，会让后人误判结构布局 —— 真身是 `PTS.FSCBK` ＝
         `{ cbkgen(32 槽), cbktxt(31), cbkobj(8), cbkfig(3), cbkwrd(29) }`
       ＝ **103 个 8 B 槽 ＝ 824 B**（**按值**嵌在 `FSCONTEXTINFO` 里；整结构 872 B）。
       以上三个数（824／103／872）是 `t133` 的**实测值**（托管侧运行期布局 API 在真产物上取值），
       不是按字段类型数出来的。⚠️ 本占位**只**用于保证**前缀**（`version`…`pts_penalty_module`）
       各字段的偏移；`fscbk` **之后**的字段（如 `pfnAssertFailed`）**不能**按本占位去定位。
       （原文一字未删。） */
    void        *pfn_assert_failed;
    /* ⏪ `t133`（P1-W55）：**只为**让"`FSCBK` 只读回读"（窗口 40..864，见 `wpf_pts_fscbk_probe`）
       在**夹具路径**上同样**在界内** —— 改前这个结构只有 56 B，若被回读 864 B 就是**越界读**。
       本数组**不参与**任何语义（夹具只用前面的前缀字段），且下面用 `offsetof(..., probe_pad) == 56`
       把**同一条牙**（前缀大小）保住。 */
    unsigned char probe_pad[1024];
} wpf_pts_fsctx_probe;
_Static_assert(offsetof(wpf_pts_fsctx_probe, probe_pad) == 56,
               "probe struct prefix size unexpected（前 4 个 4 B 标量 + 5 个指针；指针**不得**按 4 B 假设）"
               "；`t133` 把原 `sizeof(...) == 56` 换成 `offsetof(probe_pad) == 56`（**同一条牙**，"
               "因为结构尾部加了 `probe_pad` 以容纳只读回读窗口）");
/* ⏪ `t141`：夹具结构的 `fscbk` 偏移**必须**与快照窗口起点**同源**（判据 5；两处不得各写各的） */
_Static_assert(offsetof(wpf_pts_fsctx_probe, fscbk) == WPF_PTS_FSCBK_OFF,
               "夹具结构的 fscbk 偏移与快照窗口起点不一致（+40）");
_Static_assert(offsetof(wpf_pts_fsctx_probe, version) == 0,  "offset assumption broken: version");
_Static_assert(offsetof(wpf_pts_fsctx_probe, fsffi) == 4,    "offset assumption broken: fsffi");
_Static_assert(offsetof(wpf_pts_fsctx_probe, c_installed_objects) == 12, "offset assumption broken: cInstalledObjects");
_Static_assert(offsetof(wpf_pts_fsctx_probe, p_installed_objects) == 16, "offset assumption broken: pInstalledObjects");
_Static_assert(offsetof(wpf_pts_fsctx_probe, p_fsclient) == 24,          "offset assumption broken: pfsclient");
_Static_assert(offsetof(wpf_pts_fsctx_probe, pts_penalty_module) == 32,  "offset assumption broken: ptsPenaltyModule");

static int g_pts_selfcheck_f6_docctx(void)
{
    const int nb = g_pts_doc_live_n;
    const int f6_sets = g_pts_doc_sets_c, f6_rej = g_pts_doc_rejected_c, f6_des = g_pts_doc_destroys;
    if (nb + 2 > WPF_PTS_DOC_MAX) return 1;                      /* 表放不下两个 ⇒ 不适用（宁可不判） */
    wpf_pts_fsctx_probe s1, s2;
    memset(&s1, 0, sizeof(s1)); memset(&s2, 0, sizeof(s2));
    s1.version = 0x00010001u; s1.fsffi = 0xDEADBEEFu; s1.dr_min_column_balancing_step = 2;
    s1.c_installed_objects = 3;
    s1.p_installed_objects = (void *)0x1111; s1.p_fsclient = (void *)0x2222; s1.pts_penalty_module = (void *)0x3333;
    s2.version = 0x00020002u; s2.fsffi = 0xFEEDFACEu; s2.dr_min_column_balancing_step = 5;
    s2.c_installed_objects = 7;
    s2.p_installed_objects = (void *)0x4444; s2.p_fsclient = (void *)0x5555; s2.pts_penalty_module = (void *)0x6666;
    void *h1 = (void *)0x71, *h2 = (void *)0x72;
    /* ① 两次调用：都成功 ＋ 两个句柄**互不相等**（只是必要条件） */
    if (CreateDocContext(&s1, &h1) != 0 || h1 == NULL) return 0;
    if (CreateDocContext(&s2, &h2) != 0 || h2 == NULL) { DestroyDocContext(h1); return 0; }
    if (h1 == h2) { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    /* ② **按对象绑定（本条判绿的真承重格）**：字段**逐项**读回，且与各自那次调用**逐项相等** */
    if (WpfLinuxWin32_PtsDocFieldAt(nb,     0) != (void *)(unsigned long)s1.version)              { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb + 1, 0) != (void *)(unsigned long)s2.version)              { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb,     1) != (void *)(unsigned long)s1.fsffi)                { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb + 1, 1) != (void *)(unsigned long)s2.fsffi)                { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb,     2) != (void *)(long)s1.c_installed_objects)           { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb + 1, 2) != (void *)(long)s2.c_installed_objects)           { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb,     3) != (void *)&s1)                                    { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb + 1, 3) != (void *)&s2)                                    { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb,     4) != s1.p_installed_objects)                         { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb + 1, 4) != s2.p_installed_objects)                         { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb,     5) != s1.p_fsclient)                                  { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb + 1, 5) != s2.p_fsclient)                                  { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb,     6) != s1.pts_penalty_module)                          { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    if (WpfLinuxWin32_PtsDocFieldAt(nb + 1, 6) != s2.pts_penalty_module)                          { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    /* ③ 观测镜对拍（指针量走**指针域** `ptr0`／`ptr1`，`t97`／`t103` 同口径） */
    {
        const void *p0 = NULL, *p1 = NULL;
        if (WpfLinuxWin32_PtsJmpProbePtr("CreateDocContext", &s1, &p0, &p1) != 1) { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
        if (p0 != h1) { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }   /* 镜记的句柄 == 真出参 */
        if (p1 != (const void *)&s1) { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }  /* 镜记的入参结构 == 本次入参 */
    }
    /* ④ 拒绝面（失败且**不改可见状态**）——⚠️ 两条都**必须**有活对象在场才有牙（`t103` 教训） */
    {
        const int snap_live = g_pts_doc_live_n;
        const int snap_sets = g_pts_doc_sets_c;
        void *q = (void *)0x5B5B;
        if (CreateDocContext(NULL, &q) != WPF_PTS_ERR_NOT_IMPLEMENTED || q != NULL) { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
        /* ⚠️ 空出参那一路**不碰** `q`（出参就是 `NULL`）⇒ 断言要盯**别的**可判定量：
              它必须**拒绝**、且**不得**在登记表里留下对象（"写空也算成功"在这里就变成了"凭空多一个对象"）。 */
        if (CreateDocContext(&s1, NULL) != WPF_PTS_ERR_NOT_IMPLEMENTED ||
            g_pts_doc_live_n != snap_live) { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
        if (g_pts_doc_live_n != snap_live || g_pts_doc_sets_c != snap_sets) { DestroyDocContext(h2); DestroyDocContext(h1); return 0; }
    }
    /* ⑤ 收尾面（**本步新可达的同侪**）：真销毁 ⇒ 0 ＋ 活数回 base；重复／未知／NULL ⇒ **必被拒** */
    if (DestroyDocContext(h2) != 0) { DestroyDocContext(h1); return 0; }
    if (DestroyDocContext(h1) != 0) return 0;
    if (DestroyDocContext(h1) == 0) return 0;                       /* 重复必被拒 */
    if (DestroyDocContext((void *)0xdeadbeef) == 0) return 0;       /* 未知必被拒（不 deref） */
    if (DestroyDocContext(NULL) == 0) return 0;                     /* NULL 必被拒 */
    if (g_pts_doc_live_n != nb) return 0;                           /* 夹具不带泄漏 */
    if (WpfLinuxWin32_PtsDocFieldAt(nb, 0) != NULL) return 0;       /* 越界/已销毁 ⇒ NULL（位置读，不 deref） */
    g_pts_doc_sets_c = f6_sets; g_pts_doc_rejected_c = f6_rej; g_pts_doc_destroys = f6_des;  /* 出口复原本格计数 */
    return 1;
}

// ── `t125`／P1-W47：销毁路径的两条同伴（`FsQueryPageDetails` ＋ `FsDestroyPage`）────────────
//   🔴 **为什么必须同趟补两条（本趟现取的因果链，逐环可核）**：
//     ① `PtsPage.CreateBottomlessPage()`（`PtsPage.cs:280`）第一句就是
//        `OnBeforeFormatPage(false,false)`（`:731`）⇒ `if (!incremental && !IsEmpty) DestroyPage();`
//     ② `IsEmpty` ＝ `_ptsPage == IntPtr.Zero`（`PtsPage.cs:1447-1451`）；`DestroyPage()`（`:1428`）
//        ⇒ `PtsContext.OnPageDisposed(...,enterContext:false)` ⇒ `OnDestroyPage(ptsPage,true)`（`PtsContext.cs:462`）
//     ③ `OnDestroyPage`（`:471`）先过**两道断言**：`_pages != null` ∧ **`_pages.Contains(ptsPage)`**
//        —— 断言原文就是本趟崩溃文本 **"Page does not exist."** ⇒ 它**先于** `FsDestroyPage` 执行
//     ④ 那么页为什么不在 `_pages` 里？注册点是 `PtsPage.cs:798` 的 `PtsContext.OnPageCreated(_ptsPage)`，
//        而它被 `if (!IsEmpty)`（`:792`）**与** `if (!incremental)` 夹着；`OnPageCreated` **之前**先跑
//        `OnAfterFormatPage(true,false)`（`:308`）⇒ 其中 `GetRect()`／`GetBoundingBox()` 都调
//        **`PTS.Validate(PTS.FsQueryPageDetails(...))`**（`PtsPage.cs:503`-ish／`:553`-ish）
//        ⇒ 该符号**不存在** ⇒ 抛 ⇒ **`OnPageCreated` 永不执行**
//        ⇒ 于是 `_ptsPage` 非零 ∧ `_pages` 里没有它 ⇒ 下一趟 `OnBeforeFormatPage` 一进 `DestroyPage`
//          ⇒ 撞 `_pages.Contains` **"Page does not exist."** ⇒ `Environment.FailFast`（**不可捕获**）
//     ⇒ **本趟实测佐证**：崩溃日志里 `FsCreatePageBottomless` 命中 **0** —— 我们那条 create 的
//        `ENFE` **已经归零**（符号在了），这次崩**根本不是它**，而是上面这条链；且崩点**在**
//        `FsDestroyPage` 之前 ⇒ **只补 `FsDestroyPage` 不够、只补 `FsQueryPageDetails` 也不够**，
//        **两条必须同趟**（先把 `OnPageCreated` 打通，销毁路径才拿得到"在册"的页）。
//   拒绝面与留痕：两条都沿用格 7 的纪律 —— 形状/身份校验（**指针身份**，不 deref 未知句柄）、
//   失败**必留痕**（`[FS_PAGE_GAP]` 行 ＋ 计数只读口）。
//   ⚠️ **非目标**：不实现 PTS 的页布局语义（不建行、不分栏）；`FSPAGEDETAILS` 只按
//   **`fSimple = 1` 的简单页**形态填（托管侧两条消费者在 `fSimple` 为真时只读
//   `u.simple.trackdescr.fsrc`／`.fsbbox`；`complex` 分支本步**不走**，如后需另开）。
#define WPF_PTS_FSP_QPD_DU  768          /* 简单页矩形宽（与创建时记下的几何同源） */
#define WPF_PTS_FSP_QPD_DV  576          /* 简单页矩形高 */

/* `FSPAGEDETAILS` 的**前置区**（本模块只填这一段，其余留给调用方缓冲；
   偏移按托管侧 `[StructLayout(LayoutKind.Sequential)]`＋8 字节指针对齐**实测**：
   +0 `fskupd`(int) ｜ +4 `fSimple`(int) ｜ +24 `trackdescr.fsupdinf`(8B) ｜ +32 `trackdescr.nms`(ptr) ｜
   +40 `trackdescr.fsrc`(4×int) ｜ +56 `trackdescr.fsbbox`(int＋4×int) ｜ +76 … */
typedef struct {
    unsigned int pad0;                  /* fskupd（FSPAGEDETAILS.fskupd，4 B） */
    unsigned int fSimple;               /* FSPAGEDETAILS.fSimple（4 B） */
    unsigned char pre[8];               /* nested_u 起 8 对齐 + FSUPDATEINFO ＝ 8 B ⇒ nms 落在 +16 */
    void        *td_nms;                /* trackdescr.nms                （+16） */
    int          r_u, r_v, r_du, r_dv;  /* trackdescr.fsrc               （+24..+39） */
    int          b_defined;             /* trackdescr.fsbbox.fDefined    （+40） */
    int          b_u, b_v, b_du, b_dv;  /* trackdescr.fsbbox.fsrc        （+44..+59） */
    int          f_rel_to_rect;         /* trackdescr.fTrackRelativeToRect（+60） */
    void        *td_pfstrack;           /* trackdescr.pfstrack           （+64 ⇒ 结构尾 72） */
} wpf_pts_fspagedetails_head;
/* ⚠️ `t127` **实测钉死**（不是推理）：托管侧 `FSTRACKDESCRIPTION` 全 `Sequential`、`FSKUPDATE : int`
   ⇒ `FSUPDATEINFO` ＝ 8 B、`FSRECT` ＝ 16 B、`FSBBOX` ＝ 20 B ⇒ 各字段偏移如上。
   首版把 `FSUPDATEINFO` 当成 16 B（多算 8）⇒ `pfstrack` 写到了托管侧**别的字段**上
   （实测托管侧读到 `0x30000000000`，即我们 `b_defined` 与 `b_du` 的合成）⇒
   `FsQueryTrackDetails` 收到"不是我们的"句柄 × 1129 次。**下面四条断言就是防它再错位。** */
_Static_assert(offsetof(wpf_pts_fspagedetails_head, td_nms)      == 16, "offset broken: trackdescr.nms");
_Static_assert(offsetof(wpf_pts_fspagedetails_head, r_u)         == 24, "offset broken: trackdescr.fsrc");
_Static_assert(offsetof(wpf_pts_fspagedetails_head, b_defined)   == 40, "offset broken: fsbbox.fDefined");
_Static_assert(offsetof(wpf_pts_fspagedetails_head, td_pfstrack) == 64, "offset broken: trackdescr.pfstrack");
/* ⚠️ **编译期**钉死"调用方要用的那个字段"的偏移（防后人调字段顺序时静默错位）。 */
_Static_assert(offsetof(wpf_pts_fspagedetails_head, td_nms)      == 16, "offset broken: trackdescr.nms");
_Static_assert(offsetof(wpf_pts_fspagedetails_head, r_u)         == 24, "offset broken: trackdescr.fsrc");
_Static_assert(offsetof(wpf_pts_fspagedetails_head, b_defined)   == 40, "offset broken: fsbbox.fDefined");
_Static_assert(offsetof(wpf_pts_fspagedetails_head, td_pfstrack) == 64, "offset broken: trackdescr.pfstrack");

// 【`t125` · 真实现】成功 ⇒ 0 ＋ 按**该页对象**回读它自持的几何（**不是**全局常量：不同页各读各的）；
//   失败 ⇒ 返非 0 ＋ **留痕**。拒绝面：`pPageDetails==NULL`／`pPage==NULL`／`pPage` **不在册**。
int FsQueryPageDetails(void *pfscontext, void *pPage, void *pPageDetails)
{
    const char *reason = NULL;
    if (!pPageDetails)                reason = "null-details-out";
    else if (!pPage)                  reason = "null-page";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else {
        wpf_pts_fsp *pg = NULL;
        for (int i = 0; i < g_pts_fsp_live_n; i++) {
            if (g_pts_fsp_live[i]->magic != WPF_PTS_FSP_MAGIC) continue;
            if ((void *)g_pts_fsp_live[i] == pPage) { pg = g_pts_fsp_live[i]; break; }
        }
        if (!pg) reason = "unknown-page";
        else {
            wpf_pts_fspagedetails_head *d = (wpf_pts_fspagedetails_head *)pPageDetails;
            /* ── `T-A15`：`FSPAGEDETAILS.fskupd` **按该页对象的状态**给值（**首次 `New`／稳态 `NoChange`**）──
               **不再**留 `memset` 之后的 `0`（＝上游 `Pts.cs:1695` 明示不可能的 `fskupdInherited`）。
               ⚠️ **"首次"的判据（现取后写死；为什么不是"该页对象的第一条查询"）**：同一页对象在**同一帧**里
                 会被**多个互不相同的消费者**查询 —— 现取（本趟 `[QPD]`／`[VIS]` 逐帧）三页**一律**是
                 `page_qpd=1/2/3` **紧邻成组**（`PtsPage.GetRect()`／`GetBoundingBox()` ＋ 第三个消费者），
                 而**页视觉帧（`PtsPage.UpdatePageVisuals:996`）的查询是本组的"下一条"**（＝上一条 native 调用
                 不是对本页的查询）。若按"第一条第查询"给 `New`，则页视觉帧拿到 `NoChange` ⇒ `:999` 提前返回
                 ⇒ **轨视觉永不建起**（本趟实测：`[FSPARALIST-FILL]` 与 `恒 0` 腿**逐条相等** ⇒ 页视觉帧 `0` 次到达 `:1043`）。
               ⇒ **"首次"＝该页在本"查询组"内的首次查询**（组 ＝ 从非本页查询的 native 调用之后开始）；
                  **组内后续查询** ⇒ "页不可能已变" ⇒ `NoChange`。
               `qpd_vis_built` ＝ 已见**页视觉帧真建起轨视觉**的下游见证（见 `FsQueryTrackParaList` 的判别器）
                 ⇒ 置 1 后**一律** `NoChange`（稳态，消费者 `:999` 做零工作）。 */
            const int qpd_adjacent = ((const void *)g_pts_qpd_prev_page == (const void *)pPage);
            const int qpd_vis_built = pg->qpd_vis_built;
#if WPF_PTS_QPD_FSKUPD_FAKE == 1
            const int fskupd = 0;                     /* 反腿①：恒 `fskupdInherited`（旧行为） */
#elif WPF_PTS_QPD_FSKUPD_FAKE == 2
            const int fskupd = WPF_PTS_FSKUPD_NEW;    /* 反腿②：恒 New ⇒ 把"未变"谎报成"新建" */
#else
            const int fskupd = (qpd_vis_built || qpd_adjacent) ? WPF_PTS_FSKUPD_NOCHANGE
                                                               : WPF_PTS_FSKUPD_NEW;
#endif
            g_pts_qpd_prev_page = (const void *)pPage;   /* 供下一次查询判定"是否同组" */
            pg->qpd_calls++;
            pg->qpd_fstd_since = 0;                   /* 判别器的窗口从"本次查询"起算 */
            pg->qpd_new_pending = (fskupd == WPF_PTS_FSKUPD_NEW) ? 1 : 0;
            if (fskupd == WPF_PTS_FSKUPD_NOCHANGE) { g_pts_fsp_qpd_nc++; }
            else                                   { g_pts_fsp_qpd_new++; }
            memset(d, 0, sizeof(*d));                 /* 先清（**不留残留**），再逐字段填 */
            d->pad0       = (unsigned int)fskupd;     /* FSPAGEDETAILS.fskupd（**唯一合法值域**） */
            d->fSimple    = 1;                        /* 简单页 ⇒ 托管侧只读 trackdescr 两格 */
            d->r_u = 0;  d->r_v = 0;  d->r_du = pg->pg_w; d->r_dv = pg->pg_h;
            d->td_pfstrack = (void *)&pg->c_paras;   /* `t127`：轨句柄 ＝ **本对象内**该字段的地址 */
            d->b_defined = pg->bbox_defined;
            d->b_u = 0;  d->b_v = 0;  d->b_du = pg->pg_w; d->b_dv = pg->pg_h;
            g_pts_fsp_qpd_ok++;
            /* ⏪ `T-A41` `D0`：`FsQueryPageDetails` 是**三个页级 pass**（`ArrangePage:503`／
               `UpdatePageVisuals:996`／`UpdateViewport:553`）共同的起手 ⇒ 这里给上一轮收口。
               （只读：不改任何出参。） */
            wpf_pts_qvp_end("next-qpd");
            g_pts_qvp_qpd_page = (const void *)pPage;   /* ⏪ `T-A41` `D0`：下一轮的页身份（只读） */
            { int _i = wpf_pts_index("FsQueryPageDetails"); if (_i >= 0) g_pts_seen[_i]++; }
            /* ⏪ `T-A15`：成功路径的**机读留痕**（`A14` §6-2 的 `NOINFO(QPD-SUCCESS-NOT-LOGGED)` 的消掉条件）。
               `first=` 与 `page_qpd=` **逐趟可核**；`fskupd=0` 若出现即**当场红并点名**（上游明示排除该值）。*/
            fprintf(stderr, "[QPD] rc=0 fskupd=%d first=%d adj=%d page=%p page_qpd=%d vis_built=%d "
                            "qpd_ok=%d qpd_gap=%d new_n=%d nc_n=%d vis_n=%d seq=%d "
                            "NOINFO=fspagedetails-page-change-tracking\n",
                    fskupd, (pg->qpd_calls == 1) ? 1 : 0, qpd_adjacent, (void *)pg, pg->qpd_calls,
                    qpd_vis_built, g_pts_fsp_qpd_ok, g_pts_fsp_qpd_gap, g_pts_fsp_qpd_new,
                    g_pts_fsp_qpd_nc, g_pts_fsp_vis_ok, g_pts_seq);
            g_pts_seq++;
            return 0;
        }
    }
    g_pts_qpd_prev_page = NULL;   /* `T-A15`：拒绝路径**不**续接"查询组"（判"同组"只认相邻的**成功**查询）*/
    g_pts_fsp_qpd_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryPageDetails ctx=%p page=%p qpd_ok=%d qpd_gap=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pPage, g_pts_fsp_qpd_ok, g_pts_fsp_qpd_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

// 【`t125` · 真实现】成功 ⇒ 0 ＋ **真销毁**（从登记表按**指针身份**摘除并 `free`）＋ 活数回退；
//   失败 ⇒ 返非 0 ＋ 留痕（`NULL`／未知／**重复销毁**／魔数不符 一律拒，**一个字节都不 free**）。
int FsDestroyPage(void *pfscontext, void *pfspage)
{
    const char *reason = NULL;
    /* ⏪ `t151` 窗外腿（调用点 ①）：页拆除在 `using` 窗关闭之后。
       ⏪ `T-A17`：**置该 doc 的句柄 liveness = 0（释放后拒驱）** —— 进入本入口前，托管侧
       `PtsPage.DestroyPage()` ⇒ `PtsContext.OnPageDisposed` ⇒ `OnDestroyPage` ⇒ 本入口，**已先**
       释放该页的托管段落实例句柄；本 doc 缓存的 `drive_nmseg` 取得于此之前 ⇒ 此刻**已释放** ⇒ 置 0
       ⇒ 本入口与**此后**所有窗外腿（含调用点 ② 的 `ArrangePage` 路径）**一律拒驱**（否则
       `+136 pfnGetFirstPara` 会撞 `PtsContext.HandleToObject` 的
       `Invariant.Assert("Handle has been already released.")` ⇒ 不可捕获 `FailFast`，`app_rc 134`）。
       如实留痕：`[DRIVE-PROBE2-OOW] … v136=REFUSED-NONLIVE-HANDLE`。 */
    { wpf_pts_doc *ddp = wpf_pts_doc_ptr(pfscontext); if (ddp) ddp->drive_handles_live = 0; }
    wpf_pts_drive_probe2_oow(pfscontext, "FsDestroyPage");
    if (!pfspage)                     reason = "null-page";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else {
        for (int i = 0; i < g_pts_fsp_live_n; i++) {
            if ((void *)g_pts_fsp_live[i] != pfspage) continue;
            if (g_pts_fsp_live[i]->magic != WPF_PTS_FSP_MAGIC) { reason = "already-destroyed"; break; }
            g_pts_fsp_live[i]->magic = 0;             /* 先失效 ⇒ 重复销毁必被拒 */
            /* ⏪ `T-A33`：**摘表但不 `free`**。断页记录句柄＝本对象内字段的地址（`FsCreatePageFinite`
               的 `ppfsBRPageOut == &p->c_paras`，承"字段级诚实性"口径）；若在此 `free`，后续
               `calloc` 可能**复用同一地址** ⇒ 两个 `PageBreakRecord` 撞同一句柄 ⇒ 托管
               `PtsContext.OnPageBreakRecordCreated` 的 `Invariant.Assert("Break record already
               exists.")`（**不可捕获**）⇒ `app_rc=134`（实测：`T-A33` 腿 `legs-tlb3`）。
               ⇒ 页对象**内存**改为**一次性让渡**（地址**永不复用**；摘表口径与计数字段**逐字不变**
               ⇒ 格 8／格 9 自检的 `live_n` 断言不受影响）。代价＝每页约 `sizeof(wpf_pts_fsp)` 字节
               ／进程生命周期，**如实登记**。 */
            g_pts_fsp_retired_n++;
            g_pts_fsp_live[i] = g_pts_fsp_live[--g_pts_fsp_live_n];
            g_pts_fsp_live[g_pts_fsp_live_n] = NULL;
            g_pts_fsp_des_ok++;
            { int _i = wpf_pts_index("FsDestroyPage"); if (_i >= 0) g_pts_seen[_i]++; }
            g_pts_seq++;
            return 0;
        }
        reason = "unknown-page";
    }
    g_pts_fsp_des_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsDestroyPage ctx=%p page=%p des_ok=%d des_gap=%d "
                    "retired=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pfspage, g_pts_fsp_des_ok, g_pts_fsp_des_gap,
            g_pts_fsp_retired_n);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

// ── `T-A16`／`TASK-0302` 增量：`FsClearUpdateInfoInPage`（声明 `Pts.cs:3142`；调用点 `PtsPage.cs:598`）──
//   签名：`int FsClearUpdateInfoInPage(IntPtr pfscontext, IntPtr pfspage);`（**无出参**）
//   🔴 **为什么必须补它（现取的因果链）**：`T-A15` 让"页视觉帧"第一次走通之后，
//     `FlowDocumentPage.UpdateVisual:871`（在 `GetPageVisual()` **之后**）与 `OnBeforeFormatPage:886`
//     都会调 `_ptsPage.ClearUpdateInfo()` ⇒ `PtsPage.cs:598 PTS.FsClearUpdateInfoInPage(...)` ——
//     该符号本侧**未导出** ⇒ 现取 `EntryPointNotFoundException: … 'FsClearUpdateInfoInPage'` `0→532`。
//   上游语义（现取，行号仅本次有效）：
//     · `PtsPage.ClearUpdateInfo()`（`PtsPage.cs:593-600`）：`if (!IsEmpty)` 时调它，注释逐字
//       「Clear any incremental update state accumulated during update process.」；
//     · `FlowDocumentPage.ForceReformat()`（`:246-253`）给出**因果**（逐字）：「Page update may be
//       requested more than once before rendering is done. But PTS is not able to merge update info.
//       To protect against loosing incremental changes delta, need to force full formatting for the
//       conent.」＋ `:250` 就调 `_ptsPage.ClearUpdateInfo()` ⇒ **清增量 ⇒ 下一趟必须是全量重排**。
//   ⇒ 本侧真语义（**可现取、可证伪**）：把该**页对象**的**本模块自持的增量更新状态**真的清掉 ——
//     `qpd_vis_built`／`qpd_new_pending`／`qpd_fstd_since` 归 0，并**断开"查询组"毗邻位**
//     ⇒ **下一次** `FsQueryPageDetails` 按**全量**给 `fskupdNew(2)`，而不是稳态 `fskupdNoChange(1)`。
//     ⚠️ **为什么非这样不可**：`fskupdNoChange` 的语义就是"无变化 ⇒ 视觉仍有效"（`PtsPage.cs:999`
//     提前返回、`PtsHelper.cs:210` 同样提前返回）⇒ 若"清"完之后下一次仍是 `NoChange`，本入口就成了
//     **什么都没做的假成功**（那正是裁定二十三「不许静默 stub」与 `t127`「字段级诚实性」两条都在禁的形态）。
//   ⚠️ **永不假成功**：只有**真清掉**（状态**从非零变零**或本就为空也照样如实报出 `*_before=`）才返 0；
//     `pfspage == NULL`／`pfscontext` 非空但不在册／`pfspage` 不在册 ⇒ 返 `-10000` ＋ 具名 `[FS_PAGE_GAP]`
//     留痕，且**一个字节也不改**（不改任何页对象的任何字段、不动毗邻位）。
//   ⚠️ **射程边界（如实划界，防被读宽）**：本入口清的是**本模块自持**的增量状态（"该页的轨视觉是否
//     已建起"这一下游见证面 ＋ 查询组毗邻位），**不是**托管/LineServices 的完整增量位图 —— 本侧**没有**
//     那个源 ⇒ 具名 `NOINFO-FSCLEARUPDATEINFO-SCOPE-NATIVE-OWNED-STATE`。它**不**声称"页内容已重排"，
//     也**不**声称"页会因此可见变化"（症状门由腿读数给）。
int FsClearUpdateInfoInPage(void *pfscontext, void *pfspage)
{
    const char *reason = NULL;
    if (!pfspage)                    reason = "null-page";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else {
        wpf_pts_fsp *pg = NULL;
        for (int i = 0; i < g_pts_fsp_live_n; i++) {      /* **指针值比较**，不 deref 未知句柄 */
            if (g_pts_fsp_live[i]->magic != WPF_PTS_FSP_MAGIC) continue;
            if ((void *)g_pts_fsp_live[i] == pfspage) { pg = g_pts_fsp_live[i]; break; }
        }
        if (!pg) reason = "unknown-page";
        else {
            /* ── **真清**：把该页对象的增量状态归零。清前的值**先取**（留痕里现算、可对拍）── */
            const int   vis_before  = pg->qpd_vis_built;
            const int   pend_before = pg->qpd_new_pending;
            const int   fstd_before = pg->qpd_fstd_since;
            const int   grp_before  = ((const void *)g_pts_qpd_prev_page == (const void *)pfspage) ? 1 : 0;
#if WPF_PTS_CLRUPD_FAKE == 1
            /* 反腿（**只在副本**）：**假成功** —— 返 0、**一个字节都不清** ⇒
               「清完之后下一次查询必须是 `fskupdNew`」那条断言**当场红**（仍是 `fskupdNoChange`）。 */
            (void)vis_before; (void)pend_before; (void)fstd_before; (void)grp_before;
#else
            pg->qpd_vis_built   = 0;
            pg->qpd_new_pending = 0;
            pg->qpd_fstd_since  = 0;
            /* 断开"查询组"毗邻位（与下游入口 `FsQueryTrackDetails` 等**同办**）：本入口**不是**页查询
               ⇒ 它之后的下一次 `FsQueryPageDetails` 不得被读成"同组内后续查询"（那会给 `NoChange`）。 */
            g_pts_qpd_prev_page = NULL;
#endif
            g_pts_fsp_clr_ok++;
            { int _i = wpf_pts_index("FsClearUpdateInfoInPage"); if (_i >= 0) g_pts_seen[_i]++; }
            fprintf(stderr, "[CLRUPD] rc=0 page=%p vis_built_before=%d new_pending_before=%d "
                            "fstd_since_before=%d group_adjacent_before=%d page_qpd=%d "
                            "clr_ok=%d clr_gap=%d seq=%d basis=%s "
                            "NOINFO=fsclearupdateinfo-scope-native-owned-state\n",
                    (void *)pg, vis_before, pend_before, fstd_before, grp_before, pg->qpd_calls,
                    g_pts_fsp_clr_ok, g_pts_fsp_clr_gap, g_pts_seq, WPF_PTS_CLRUPD_BASIS);
            g_pts_seq++;
            return 0;
        }
    }
    g_pts_fsp_clr_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsClearUpdateInfoInPage ctx=%p page=%p "
                    "clr_ok=%d clr_gap=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pfspage,
            g_pts_fsp_clr_ok, g_pts_fsp_clr_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

// ── `T-A19`／`TASK-0302` 增量：`FsUpdateBottomlessPage`（声明 `Pts.cs:3135`；调用点 `PtsPage.cs:347`
//    `UpdateBottomlessPage()`）──
//   签名（上游逐字，`Pts.cs:3135-3139`）：`int FsUpdateBottomlessPage(IntPtr pfscontext, IntPtr pfspage,
//     IntPtr fsnmsect, out FSFMTRBL pfsfmtrbl);`（`pfscontext` IN／`pfspage` IN＝**要更新的页**／
//     `fsnmsect` IN＝起始节名／`pfsfmtrbl` **OUT**＝排版结果）
//   ⚠️ `FSFMTRBL` 是 **`int` 枚举**（`Pts.cs:1147-1152`：`fmtrblGoalReached=0`／`fmtrblCollision=1`／
//      `fmtrblInterrupted=2`）⇒ native 侧是 `int *`；**与同侪 `FsCreatePageBottomless` 同一出参类型**。
//   🔴 **为什么必须补它（现取的因果链）**：`T-A15`／`T-A16` 让"页视觉帧 ＋ 清页增量状态"走通之后，
//      `PtsPage.UpdateBottomlessPage()`（`PtsPage.cs:326-360`）会调本入口 —— 该符号本侧**未导出**
//      ⇒ 现取 `EntryPointNotFoundException: … 'FsUpdateBottomlessPage' in shared library
//      'PresentationNative_cor3.dll'`（`[HC-UNHANDLED] #354`）。补上符号 ⇒ 该名**离开**"会
//      `EntryPointNotFoundException` 的缺口"名单（`ENFE` 归零）。
//   🔴 **诚实形态（逐条照同侪 `FsCreatePageBottomless` 的体例；`rc=0` 只在语义成立时给）**：
//     · **入参按对象身份认领**：`pfspage` 必须**在册**（`g_pts_fsp_live[]`，**指针值比较、不 deref**）；
//       `pfscontext` 非空时必须**在册**（`ctx=NULL` 但页在册 ⇒ **认领** —— 与 `FsClearUpdateInfoInPage`
//       ／`FsQueryPageDetails`／`FsDestroyPage` **同办**）。
//     · **出参按语义**：`pfsfmtrbl` 失败面**先**写"未达成"（`WPF_PTS_FSFMTRBL_NOT_ACHIEVED`，非上游枚举值
//       ⇒ **不放残留/毒值**）；成功面写**本页对象自持的 `result`**（与 `FsCreatePageBottomless` **同源**，
//       非全局常量）。
//     · **永不假成功**：只有**页在册**（真对象身份）才返 0；`NULL` 出参／`NULL` 页／未知上下文／不在册的页
//       ⇒ 返 `-10000` ＋ 具名 `[FS_PAGE_GAP]` 留痕，且**出参的语义值一字节不写**（失败面只留"未达成"）。
//     · **本入口不引入新的位移源**：它只刷新**本模块自持**的页对象（把该页的 `sect` 置成本次入参），
//       **不**调用任何驱动探针、**不**声称"页已重排/页会可见变化" ⇒ 具名
//       `NOINFO-fsupdatebottomlesspage-scope-native-owned-state`（同 `FsClearUpdateInfoInPage` 的射程口径）。
//   ⚠️ **反腿**（`WPF_PTS_UPDPSP_FAKE=1`，**只在副本**）：假成功（不校验页在册）⇒「不在册的页必被拒」当场红。
int FsUpdateBottomlessPage(void *pfscontext, void *pfspage, const void *fsnmsect, int *pfsfmtrbl)
{
    /* 失败路径先把出参置到"确定未达成"（**一个字节的残留/毒值都不留**） */
    if (pfsfmtrbl) *pfsfmtrbl = WPF_PTS_FSFMTRBL_NOT_ACHIEVED;
    const char *reason = NULL;
    if (!pfsfmtrbl)                     reason = "null-result-out";
    else if (!pfspage)                  reason = "null-page";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
#if WPF_PTS_UPDPSP_FAKE == 1
    else {
        /* 反腿（**只在副本**）：**假成功** —— 对**任意页句柄**（含不在册的伪值）都返 0
           ⇒ 「不在册的页必被拒」这条断言**当场红**。 */
        g_pts_fsp_upd_ok++;
        fprintf(stderr, "[FSUPDFSP] rc=0 page=%p sect=%p result=%d upd_ok=%d upd_gap=%d "
                        "basis=FAKE-UNCHECKED-PAGE NOINFO=fsupdatebottomlesspage-scope-native-owned-state\n",
                pfspage, fsnmsect, 0, g_pts_fsp_upd_ok, g_pts_fsp_upd_gap);
        *pfsfmtrbl = 0;                             /* 伪值：**不来自任何页对象** */
        return 0;
    }
#else
    else {
        wpf_pts_fsp *pg = NULL;
        for (int i = 0; i < g_pts_fsp_live_n; i++) {       /* **指针值比较**，不 deref 未知句柄 */
            if (g_pts_fsp_live[i]->magic != WPF_PTS_FSP_MAGIC) continue;
            if ((const void *)g_pts_fsp_live[i] == pfspage) { pg = g_pts_fsp_live[i]; break; }
        }
        if (!pg) reason = "unknown-page";
        else {
            pg->sect = fsnmsect;                        /* 本页对象自持（**原样存、不 deref**） */
            g_pts_fsp_upd_ok++;
            { int _i = wpf_pts_index("FsUpdateBottomlessPage"); if (_i >= 0) g_pts_seen[_i]++; }
            fprintf(stderr, "[FSUPDFSP] rc=0 page=%p sect=%p result=%d upd_ok=%d upd_gap=%d seq=%d "
                            "basis=refresh-page-owned-bottomless-state "
                            "NOINFO=fsupdatebottomlesspage-scope-native-owned-state\n",
                    (void *)pg, fsnmsect, pg->result, g_pts_fsp_upd_ok, g_pts_fsp_upd_gap, g_pts_seq);
            g_pts_seq++;
            *pfsfmtrbl = pg->result;                    /* 出参按语义：该页对象**自持**的结果（同侪同源） */
            return 0;                                   /* ← 只有**页在册**才到这里（改别的值＝静默半通） */
        }
    }
#endif
    g_pts_fsp_upd_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsUpdateBottomlessPage ctx=%p page=%p sect=%p "
                    "upd_ok=%d upd_gap=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pfspage, fsnmsect,
            g_pts_fsp_upd_ok, g_pts_fsp_upd_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

/* ══ ⏪ `T-A33`（`TASK-0302` 增量）：native「查询期文本行回填」＝ `NATIVE-QUERY-PHASE-TEXT-LINE-BACKFILL` ══
   【这一格要解决什么】`T-A32` 现取：行模型**已录台账**（`[FORMATLINE-LINE]` 42 行）却**没有回查接线**
   ⇒ `FsQueryTextDetails` 恒拒 `reason=no-text-line-model`（`rc=-10000`，`out=UNWRITTEN`）⇒ 托管
   `TextParaClient.ValidateVisual` 抛 `PtsException(-10000)` ⇒ 该页内容区**零像素**。本格把
   `T-A27` 路 (丙) 的**第 3 步「回查」**接起来：查询期从本侧**行记录台账**
   （`wpf_pts_subtrack::fl_line[]`，内容**只**来自 `pfnFormatLine` 真返回值）**回填**四个入口的出参。

   【硬边界（承 `T-A32` ③ 的 4 条判据 ＋ 反极性）】
     · **D1 零假值／出参纪律**：**只有** `wpf_pts_fl_usable(obj)` 成立（＝已录 ∧ 收束于段尾 ∧ 未撞界
       ∧ ≥1 行）才写；否则**出参一字不写**（`out=UNWRITTEN`）—— **不写 0**、**不写常量**。
     · **D2 永不假成功**：`cLines`／`dcpFirst`／`dcpLim`／行盒字段**逐项取自台账**（＝`pfnFormatLine`
       真返回值）；`Σ dcpLine` 由造型循环本身守恒（`dcp` 累计），末行 `fsflres∈{2,3,4,5}` 收束。
     · **D3 失败必留痕 ＋ 计数恰涨 1**：任何拒绝**必**打具名行且 `gap` 恰涨 1（承 `[FS_PAGE_GAP]`）。
     · **D4 帧面必须长像素**：本格不改绘制层；判据在跑腿面（内容区色锚/`AE(content)`）。
   【几何来源（如实划界）】行盒里 `dur` ＝ 造型时用的页宽（`WPF_PTS_FL_DU`，**本侧约定**）；
     `urStart`／`urBBox`／`durBBox`／`dvrAscent`／`dvrDescent` ＝ `pfnFormatLine` 真返回值；
     `vrStart` ＝ 本侧按**台账逐行 ascent/descent 累加**得到的行顶（**非**上游 ABI 几何）⇒ 具名
     `NOINFO-FSGEOMETRY-LAYOUT`（承 `T-A28`／`T-A31`，**未消**）。`pfslineclient`＝台账行句柄（真值）。
   【反极性（该红必红）】显式 `WPF_PTS_FL_DRIVE=0` ⇒ 造型不驱 ⇒ 台账恒空 ⇒ `wpf_pts_fl_usable` 恒假
     ⇒ 四入口**逐字回改前**（`no-text-line-model` 计数复原、`out=UNWRITTEN`）。 */
/* 出参结构镜像（照上游逐字契约；**只用于尺寸/偏移自证**，不 deref 托管结构）。 */
typedef struct {                                   /* FSLINEDESCRIPTIONSINGLE 镜像（72 B） */
    void *pfslineclient;                           /* @ +0  */
    void *pfsbreakreclineclient;                   /* @ +8  */
    int   dcp_first, dcp_lim;                      /* @ +16 */
    int   ur_start, dur, f_allow_hyph;             /* @ +24 */
    int   ur_bbox, dur_bbox;                       /* @ +36 */
    int   vr_start;                                /* @ +44 */
    int   dvr_ascent, dvr_descent;                 /* @ +48 */
    int   f_clear_left, f_clear_right;             /* @ +56 */
    int   f_treated_as_first, f_force_broken;      /* @ +64 */
} wpf_pts_fslds;
_Static_assert(sizeof(wpf_pts_fslds) == 72, "sizeof(FSLINEDESCRIPTIONSINGLE) != 72");
_Static_assert(offsetof(wpf_pts_fslds, pfsbreakreclineclient) ==  8, "FSLDS.pfsbreakreclineclient != +8");
_Static_assert(offsetof(wpf_pts_fslds, dcp_first)             == 16, "FSLDS.dcpFirst != +16");
_Static_assert(offsetof(wpf_pts_fslds, dcp_lim)               == 20, "FSLDS.dcpLim != +20");
_Static_assert(offsetof(wpf_pts_fslds, ur_start)             == 24, "FSLDS.urStart != +24");
_Static_assert(offsetof(wpf_pts_fslds, dur)                   == 28, "FSLDS.dur != +28");
_Static_assert(offsetof(wpf_pts_fslds, ur_bbox)               == 36, "FSLDS.urBBox != +36");
_Static_assert(offsetof(wpf_pts_fslds, dur_bbox)              == 40, "FSLDS.durBBox != +40");
_Static_assert(offsetof(wpf_pts_fslds, vr_start)             == 44, "FSLDS.vrStart != +44");
_Static_assert(offsetof(wpf_pts_fslds, dvr_ascent)            == 48, "FSLDS.dvrAscent != +48");
_Static_assert(offsetof(wpf_pts_fslds, dvr_descent)           == 52, "FSLDS.dvrDescent != +52");
_Static_assert(offsetof(wpf_pts_fslds, f_treated_as_first)    == 64, "FSLDS.fTreatedAsFirst != +64");
_Static_assert(offsetof(wpf_pts_fslds, f_force_broken)        == 68, "FSLDS.fForceBroken != +68");
typedef struct {                                   /* FSLINEDESCRIPTIONCOMPOSITE 镜像（48 B） */
    void *pline;                                   /* @ +0  */
    int   c_elements;                              /* @ +8  */
    int   vr_start, dvr_ascent, dvr_descent;       /* @ +12 */
    int   f_treated_as_first, f_treated_as_last;   /* @ +24 */
    int   dvr_avail_forced_line;                   /* @ +32 */
    int   f_used_word_format_line_in_chain;        /* @ +36 */
    int   f_first_line_in_word_lr;                 /* @ +40 */
} wpf_pts_fsldc;
_Static_assert(sizeof(wpf_pts_fsldc) == 48, "sizeof(FSLINEDESCRIPTIONCOMPOSITE) != 48");
_Static_assert(offsetof(wpf_pts_fsldc, pline)                     ==  0, "FSLDC.pline != +0");
_Static_assert(offsetof(wpf_pts_fsldc, c_elements)                ==  8, "FSLDC.cElements != +8");
_Static_assert(offsetof(wpf_pts_fsldc, f_first_line_in_word_lr)   == 40, "FSLDC.fFirstLineInWordLr != +40");
typedef struct {                                   /* FSLINEELEMENT 镜像（88 B） */
    void *pfslineclient;                           /* @ +0  */
    int   dcp_first;                               /* @ +8  */
    void *pfsbreakreclineclient;                   /* @ +16 */
    int   dcp_lim;                                 /* @ +24 */
    int   ur_start, dur, f_allow_hyph;             /* @ +28 */
    int   ur_bbox, dur_bbox;                       /* @ +40 */
    int   ur_lr_word, dur_lr_word;                 /* @ +48 */
    int   dvr_ascent, dvr_descent;                 /* @ +56 */
    int   f_clear_left, f_clear_right;             /* @ +64 */
    int   f_hit_by_polygon, f_force_broken;        /* @ +72 */
    int   f_clear_left_lr_word, f_clear_right_lr_word; /* @ +80 */
} wpf_pts_fslineel;
_Static_assert(sizeof(wpf_pts_fslineel) == 88, "sizeof(FSLINEELEMENT) != 88");
_Static_assert(offsetof(wpf_pts_fslineel, pfsbreakreclineclient) == 16, "FSLE.pfsbreakreclineclient != +16");
_Static_assert(offsetof(wpf_pts_fslineel, dcp_lim)               == 24, "FSLE.dcpLim != +24");
_Static_assert(offsetof(wpf_pts_fslineel, ur_lr_word)            == 48, "FSLE.urLrWord != +48");
_Static_assert(offsetof(wpf_pts_fslineel, f_clear_right_lr_word) == 84, "FSLE.fClearRightLrWord != +84");
typedef struct {                                   /* FSTEXTDETAILSFULL 镜像（104 B） */
    int   fswdir;                                  /* @ +0  */
    int   fsklines;                                /* @ +4  */
    int   f_lines_composite;                       /* @ +8  */
    int   c_lines;                                 /* @ +12 */
    int   c_attached_objects;                      /* @ +16 */
    int   dcp_first, dcp_lim;                      /* @ +20 */
    int   f_dropcap_present;                       /* @ +28 */
    int   fsupd_fskupd, fsupd_dvr_shifted;         /* @ +32 FSUPDATEINFO(8) */
    int   dc_u, dc_v, dc_du, dc_dv;                /* @ +40 FSDROPCAPDETAILS.fsrcDropCap */
    int   dc_suppress_top;                         /* @ +56 */
    int   dc_pad;                                  /* @ +60 */
    void *dc_pdcclient;                            /* @ +64 */
    int   f_suppress_top_line_spacing;             /* @ +72 */
    int   f_update_info_for_lines_present;         /* @ +76 */
    int   c_lines_before_change;                   /* @ +80 */
    int   dvr_shift_before_change;                 /* @ +84 */
    int   c_lines_changed;                         /* @ +88 */
    int   dc_lines_changed;                        /* @ +92 */
    int   dvr_shift_after_change;                  /* @ +96 */
    int   ddcp_after_change;                       /* @ +100 */
} wpf_pts_fstextdetailsfull;
_Static_assert(sizeof(wpf_pts_fstextdetailsfull) == 104, "sizeof(FSTEXTDETAILSFULL) != 104");
_Static_assert(offsetof(wpf_pts_fstextdetailsfull, f_lines_composite) ==  8, "FULL.fLinesComposite != +8");
_Static_assert(offsetof(wpf_pts_fstextdetailsfull, c_lines)           == 12, "FULL.cLines != +12");
_Static_assert(offsetof(wpf_pts_fstextdetailsfull, dcp_first)         == 20, "FULL.dcpFirst != +20");
_Static_assert(offsetof(wpf_pts_fstextdetailsfull, dcp_lim)           == 24, "FULL.dcpLim != +24");
_Static_assert(offsetof(wpf_pts_fstextdetailsfull, f_suppress_top_line_spacing)     == 72, "FULL.fSuppressTopLineSpacing != +72");
_Static_assert(offsetof(wpf_pts_fstextdetailsfull, f_update_info_for_lines_present) == 76, "FULL.fUpdateInfoForLinesPresent != +76");
_Static_assert(offsetof(wpf_pts_fstextdetailsfull, ddcp_after_change) == 100, "FULL.ddcpAfterChange != +100");
typedef struct {                                   /* FSTEXTDETAILS 镜像（112 B） */
    int fsktd;                                     /* @ +0  FSKTEXTDETAILS（0=cached／1=full） */
    int _pad;                                      /* @ +4  （联合体 8 字节对齐） */
    wpf_pts_fstextdetailsfull full;                /* @ +8  union u */
} wpf_pts_fstextdetails;
_Static_assert(sizeof(wpf_pts_fstextdetails) == 112, "sizeof(FSTEXTDETAILS) != 112");
_Static_assert(offsetof(wpf_pts_fstextdetails, full) == 8, "FSTEXTDETAILS.u != +8");
/* ── ⏪ `T-A36`（`NATIVE-PTS-ATTACHED-OBJECTS-BACKFILL`）：附属对象回填所需的**上游逐字镜像** ─────
   全部照 `upstream/…/PtsHost/Pts.cs` 的定义（`StructLayout.Sequential`，默认 pack=8）逐字段镜像；
   每条的 `sizeof`／关键偏移用 `_Static_assert` 钉死（与托管侧逐值相同：`FSKUPDATE`/`FSRECT`/
   `FSBBOX`/`FSPOINT` 只含 `int` ⇒ 对齐 4；含 `IntPtr` 的结构 ⇒ 对齐 8）。 */
typedef struct { int fskupd; int dvr_shifted; } wpf_pts_fsupdateinfo;      /* FSUPDATEINFO（Pts.cs:1943） */
_Static_assert(sizeof(wpf_pts_fsupdateinfo) == 8, "sizeof(FSUPDATEINFO) != 8");
typedef struct { int u, v, du, dv; } wpf_pts_fsrect;                       /* FSRECT（Pts.cs:849） */
_Static_assert(sizeof(wpf_pts_fsrect) == 16, "sizeof(FSRECT) != 16");
typedef struct { int u, v; } wpf_pts_fspoint;                              /* FSPOINT */
_Static_assert(sizeof(wpf_pts_fspoint) == 8, "sizeof(FSPOINT) != 8");
typedef struct { int f_defined; wpf_pts_fsrect fsrc; } wpf_pts_fsbbox;     /* FSBBOX（Pts.cs:989） */
_Static_assert(sizeof(wpf_pts_fsbbox) == 20, "sizeof(FSBBOX) != 20");
typedef struct {                                                           /* FSATTACHEDOBJECTDESCRIPTION（Pts.cs:1416） */
    wpf_pts_fsupdateinfo fsupdinf;   /* @ +0  */
    void *pfspara;                   /* @ +8  */
    void *pfsparaclient;             /* @ +16 */
    void *nmp;                       /* @ +24 */
    int   idobj;                     /* @ +32 */
    int   vr_start;                  /* @ +36 */
    int   dvr_used;                  /* @ +40 */
    wpf_pts_fsbbox fsbbox;           /* @ +44 */
    int   dvr_top_space;             /* @ +64 */
    int   _pad;                      /* @ +68 （结构 8 字节对齐 ⇒ 总 72） */
} wpf_pts_fsattachedobjectdescription;
_Static_assert(sizeof(wpf_pts_fsattachedobjectdescription) == 72, "sizeof(FSATTACHEDOBJECTDESCRIPTION) != 72");
_Static_assert(offsetof(wpf_pts_fsattachedobjectdescription, pfspara) == 8, "FSATTOBJ.pfspara != +8");
_Static_assert(offsetof(wpf_pts_fsattachedobjectdescription, pfsparaclient) == 16, "FSATTOBJ.pfsparaclient != +16");
_Static_assert(offsetof(wpf_pts_fsattachedobjectdescription, idobj) == 32, "FSATTOBJ.idobj != +32");
_Static_assert(offsetof(wpf_pts_fsattachedobjectdescription, fsbbox) == 44, "FSATTOBJ.fsbbox != +44");
typedef struct {                                                           /* FSTRACKDESCRIPTION（Pts.cs:1517） */
    wpf_pts_fsupdateinfo fsupdinf;   /* @ +0  */
    void *nms;                       /* @ +8  */
    wpf_pts_fsrect fsrc;             /* @ +16 */
    wpf_pts_fsbbox fsbbox;           /* @ +32 */
    int   f_track_relative_to_rect;  /* @ +52 */
    void *pfstrack;                  /* @ +56 */
} wpf_pts_fstrackdescription;
_Static_assert(sizeof(wpf_pts_fstrackdescription) == 64, "sizeof(FSTRACKDESCRIPTION) != 64");
_Static_assert(offsetof(wpf_pts_fstrackdescription, pfstrack) == 56, "FSTRACKDESC.pfstrack != +56");
typedef struct {                                                           /* FSSUBPAGEDETAILSSIMPLE（Pts.cs:1546） */
    unsigned int fswdir;             /* @ +0  */
    int   _pad;                      /* @ +4  */
    wpf_pts_fstrackdescription trackdescr;  /* @ +8  */
} wpf_pts_fssubpagedetailssimple;
_Static_assert(sizeof(wpf_pts_fssubpagedetailssimple) == 72, "sizeof(FSSUBPAGEDETAILSSIMPLE) != 72");
typedef struct {                                                           /* FSSUBPAGEDETAILSCOMPLEX（Pts.cs:1535） */
    void *nms;                       /* @ +0  */
    unsigned int fswdir;             /* @ +8  */
    wpf_pts_fsrect fsrc;             /* @ +12 */
    wpf_pts_fsbbox fsbbox;           /* @ +28 */
    int   c_basic_columns;           /* @ +48 */
    int   c_segment_defined_column_span_areas;  /* @ +52 */
    int   c_height_defined_column_span_areas;   /* @ +56 */
    int   _pad;                      /* @ +60 （结构 8 字节对齐 ⇒ 总 64） */
} wpf_pts_fssubpagedetailscomplex;
_Static_assert(sizeof(wpf_pts_fssubpagedetailscomplex) == 64, "sizeof(FSSUBPAGEDETAILSCOMPLEX) != 64");
typedef struct {                                                           /* FSSUBPAGEDETAILS（Pts.cs:1552） */
    int f_simple;                    /* @ +0  */
    int _pad;                        /* @ +4  */
    union {
        wpf_pts_fssubpagedetailssimple simple;    /* 72 B */
        wpf_pts_fssubpagedetailscomplex complex;  /* 64 B */
    } u;                             /* @ +8  */
} wpf_pts_fssubpagedetails;
_Static_assert(sizeof(wpf_pts_fssubpagedetails) == 80, "sizeof(FSSUBPAGEDETAILS) != 80");
typedef struct {                                                           /* FSFIGUREDETAILS（Pts.cs:1351） */
    wpf_pts_fsrect fsrc_flow_around; /* @ +0  */
    wpf_pts_fsbbox fsbbox;           /* @ +16 */
    wpf_pts_fspoint fspt_pos_preliminary; /* @ +36 */
    int   f_delayed;                 /* @ +44 */
} wpf_pts_fsfiguredetails;
_Static_assert(sizeof(wpf_pts_fsfiguredetails) == 48, "sizeof(FSFIGUREDETAILS) != 48");
typedef struct {                                                           /* FSFLOATERDETAILS（Pts.cs:1082） */
    int   fskupd_content;            /* @ +0  */
    int   _pad;                      /* @ +4  */
    void *fsnm_floater;              /* @ +8  */
    wpf_pts_fsrect fsrc_floater;     /* @ +16 */
    void *pfs_floater_content;       /* @ +32 */
} wpf_pts_fsfloaterdetails;
_Static_assert(sizeof(wpf_pts_fsfloaterdetails) == 40, "sizeof(FSFLOATERDETAILS) != 40");
/* 回填面计数（**只增**；与既有 `[FS_PAGE_GAP]` 计数分开，判据 ② 的成对面）。 */
static int g_pts_fsqtd_ok      = 0;   /* `FsQueryTextDetails` 回填成功次数（D2 的"真源"面） */
static int g_pts_tlb_ok        = 0;   /* 四入口回填成功合计 */
static int g_pts_tlb_single_ok = 0;
static int g_pts_tlb_comp_ok   = 0;
static int g_pts_tlb_elem_ok   = 0;
/* 台账可用性判据（**唯一**真值来源）：已录 ∧ 收束于段尾 ∧ 未撞界 ∧ ≥1 行。
   🔴 **零假值**：不满足 ⇒ **不许**回填（未造型／不完整／撞界一律走诚实拒绝）。 */
static int wpf_pts_fl_usable(const wpf_pts_subtrack *o)
{
    return (o && o->magic == WPF_PTS_SUB_MAGIC && o->fl_ok == 1 &&
            o->fl_nlines > 0 && o->fl_complete && !o->fl_truncated);
}
/* 行顶（`vrStart`）：按台账逐行 `dvrAscent+dvrDescent` 累加（**本侧约定**，具名 `NOINFO-FSGEOMETRY-LAYOUT`）。 */
static int wpf_pts_fl_vr_start(const wpf_pts_subtrack *o, int idx)
{
    int vr = 0;
    for (int k = 0; k < idx && k < o->fl_nlines; k++)
        vr += o->fl_line[k].dvr_ascent + o->fl_line[k].dvr_descent;
    return vr;
}
/* 回填 `FSTEXTDETAILS`（唯一成功路径；**调用者已核** `wpf_pts_fl_usable`）。 */
static void wpf_pts_tlb_fill_details(wpf_pts_subtrack *o, void *pOut)
{
    wpf_pts_fstextdetails *e = (wpf_pts_fstextdetails *)pOut;
    memset((void *)e, 0, sizeof(*e));           /* 先清零再逐字段写（未初始化内存不交上级） */
    e->fsktd = 1;                               /* `fsktdFull` */
    e->full.fswdir = 0;                         /* 本侧恒 ltr（同 `pfnFormatLine` 入参 fswdir=0） */
    e->full.fsklines = 0;                       /* `fsklinesNormal`（真调的就是 `pfnFormatLine`） */
    e->full.f_lines_composite = 0;              /* simple lines（台账行来自 `pfnFormatLine`） */
    e->full.c_lines = o->fl_nlines;             /* ← **承重格**（真值＝台账行数） */
    e->full.c_attached_objects = o->fl_att_n;   /* ⏪ `T-A36`：真值＝附属对象台账条数（`Figure`/`Floater`） */
    e->full.dcp_first = o->fl_line[0].dcp_first;                 /* ← 真值 */
    e->full.dcp_lim   = o->fl_line[o->fl_nlines - 1].dcp_lim;    /* ← 真值 */
    e->full.f_dropcap_present = 0;
    e->full.f_suppress_top_line_spacing = 0;
    e->full.f_update_info_for_lines_present = 0;/* 0 ⇒ 消费者整段重建（不做增量位移） */
}
/* 回填 `FSLINEDESCRIPTIONSINGLE` 数组（第 i 条 ← 台账第 i 行）。 */
static void wpf_pts_tlb_fill_single(wpf_pts_subtrack *o, wpf_pts_fslds *rg, int n)
{
    for (int i = 0; i < n; i++) {
        memset((void *)&rg[i], 0, sizeof(rg[i]));
        rg[i].pfslineclient         = (void *)o->fl_line[i].pfsline;     /* 台账行句柄（真返回值） */
        rg[i].pfsbreakreclineclient = (void *)o->fl_line[i].pbr_in;      /* 断行记录（真值；首行 NULL） */
        rg[i].dcp_first             = o->fl_line[i].dcp_first;
        rg[i].dcp_lim               = o->fl_line[i].dcp_lim;
        rg[i].ur_start              = o->fl_line[i].ur_bbox;             /* 本侧约定：urStartLine=0 ⇒ =urBBox */
        rg[i].dur                   = WPF_PTS_FL_DU;                     /* 造型时用的页宽（本侧约定） */
        rg[i].f_allow_hyph          = 0;                                 /* 造型入参 fAllowHyphenation=0 */
        rg[i].ur_bbox               = o->fl_line[i].ur_bbox;
        rg[i].dur_bbox              = o->fl_line[i].dur_bbox;
        rg[i].vr_start              = wpf_pts_fl_vr_start(o, i);         /* 本侧累加（NOINFO-FSGEOMETRY-LAYOUT） */
        rg[i].dvr_ascent            = o->fl_line[i].dvr_ascent;
        rg[i].dvr_descent           = o->fl_line[i].dvr_descent;
        rg[i].f_clear_left          = 0;                                 /* 造型入参 fClearOnLeft=0 */
        rg[i].f_clear_right         = 0;                                 /* 造型入参 fClearOnRight=0 */
        rg[i].f_treated_as_first    = (i == 0) ? 1 : 0;                  /* 造型入参 fTreatAsFirstInPara */
        rg[i].f_force_broken        = o->fl_line[i].f_forced;
    }
}
/* 回填 `FSLINEDESCRIPTIONCOMPOSITE` 数组（本侧一行＝一元素；`pline`＝台账行句柄）。 */
static void wpf_pts_tlb_fill_composite(wpf_pts_subtrack *o, wpf_pts_fsldc *rg, int n)
{
    for (int i = 0; i < n; i++) {
        memset((void *)&rg[i], 0, sizeof(rg[i]));
        rg[i].pline        = (void *)o->fl_line[i].pfsline;    /* 供 `QueryLineElements` 按行句柄认领 */
        rg[i].c_elements   = 1;                                /* 本侧一行＝一元素 */
        rg[i].vr_start     = wpf_pts_fl_vr_start(o, i);
        rg[i].dvr_ascent   = o->fl_line[i].dvr_ascent;
        rg[i].dvr_descent  = o->fl_line[i].dvr_descent;
        rg[i].f_treated_as_first = (i == 0) ? 1 : 0;
        rg[i].f_treated_as_last  = (i == n - 1) ? 1 : 0;
        rg[i].dvr_avail_forced_line = 0;
        rg[i].f_used_word_format_line_in_chain = 0;
        rg[i].f_first_line_in_word_lr = 0;
    }
}
/* 按**行句柄**（台账 `pfsline`）在册认领：唯一定位（歧义／未命中 ⇒ 0）。 */
static int wpf_pts_tlb_claim_line(const void *pLine, wpf_pts_subtrack **outObj, int *outIdx)
{
    int found = 0;
    if (outObj) *outObj = NULL;
    if (outIdx) *outIdx = -1;
    if (!pLine) return 0;
    for (int i = 0; i < g_pts_sub_live_n; i++) {
        wpf_pts_subtrack *o = g_pts_sub_live[i];
        if (o->magic != WPF_PTS_SUB_MAGIC) continue;
        if (!wpf_pts_fl_usable(o)) continue;       /* 只认**可用**台账的行（零假值） */
        for (int k = 0; k < o->fl_nlines; k++) {
            if (o->fl_line[k].pfsline != pLine) continue;
            if (found) return 0;                   /* 歧义 ⇒ 拒（不猜） */
            found = 1;
            if (outObj) *outObj = o;
            if (outIdx) *outIdx = k;
        }
    }
    return found;
}
/* 回填单个 `FSLINEELEMENT`（第 `idx` 行）；`pLine` 已由 `wpf_pts_tlb_claim_line` 认领。 */
static void wpf_pts_tlb_fill_element(wpf_pts_subtrack *o, int idx, wpf_pts_fslineel *e)
{
    memset((void *)e, 0, sizeof(*e));
    e->pfslineclient         = (void *)o->fl_line[idx].pfsline;
    e->dcp_first             = o->fl_line[idx].dcp_first;
    e->pfsbreakreclineclient = (void *)o->fl_line[idx].pbr_in;
    e->dcp_lim               = o->fl_line[idx].dcp_lim;
    e->ur_start              = o->fl_line[idx].ur_bbox;
    e->dur                   = WPF_PTS_FL_DU;
    e->f_allow_hyph          = 0;
    e->ur_bbox               = o->fl_line[idx].ur_bbox;
    e->dur_bbox              = o->fl_line[idx].dur_bbox;
    e->ur_lr_word            = 0;
    e->dur_lr_word           = 0;
    e->dvr_ascent            = o->fl_line[idx].dvr_ascent;
    e->dvr_descent           = o->fl_line[idx].dvr_descent;
    e->f_clear_left          = 0;
    e->f_clear_right         = 0;
    e->f_hit_by_polygon      = 0;
    e->f_force_broken        = o->fl_line[idx].f_forced;
    e->f_clear_left_lr_word  = 0;
    e->f_clear_right_lr_word = 0;
}

/* ⏪ `T-A36`：按**附属对象段落句柄**（`fl_att[].nmp_obj`）在台账里定位。
   🔴 **同一逻辑段落可有两代本侧对象**（两趟窗），其附属对象的托管句柄**相同** ⇒ 其 `nmp_obj`
   会多命中。消歧**有据**：优先取 `owner_doc == ctx 的 doc` 的那一代（＝本次查询所属文档）；
   无 doc 可依时取**最新一代**（`seq` 最大）。多命中共计 `g_pts_att_ambig`（**具名，不静默**）。 */
static int g_pts_att_ambig = 0;
static int wpf_pts_att_claim(const void *pObj, const void *ctx, wpf_pts_subtrack **outObj, int *outIdx)
{
    wpf_pts_subtrack *best = NULL; int bestIdx = -1, hits = 0;
    const wpf_pts_doc *dp = wpf_pts_doc_ptr(ctx);
    if (outObj) *outObj = NULL;
    if (outIdx) *outIdx = -1;
    if (!pObj) return 0;
    for (int i = 0; i < g_pts_sub_live_n; i++) {
        wpf_pts_subtrack *o = g_pts_sub_live[i];
        if (o->magic != WPF_PTS_SUB_MAGIC) continue;
        for (int a = 0; a < o->fl_att_n; a++) {
            if (o->fl_att[a].nmp_obj != pObj) continue;
            hits++;
            if (!best) { best = o; bestIdx = a; }
            else if (dp && o->owner_doc == (const void *)dp) { best = o; bestIdx = a; }
            else if (!(dp && best->owner_doc == (const void *)dp) && o->seq > best->seq) { best = o; bestIdx = a; }
        }
    }
    if (!hits) return 0;
    if (hits > 1) g_pts_att_ambig++;
    *outObj = best; *outIdx = bestIdx;
    return 1;
}
/* ⏪ `T-A36`：附属对象四入口的成败面（`[FS_ATT]` 的计数只读口）。 */
static int g_pts_att_list_ok = 0, g_pts_att_list_gap = 0;   /* `FsQueryAttachedObjectList` */
static int g_pts_subpage_ok  = 0, g_pts_subpage_gap  = 0;   /* `FsQuerySubpageDetails` */
static int g_pts_figdet_ok   = 0, g_pts_figdet_gap   = 0;   /* `FsQueryFigureObjectDetails` */
static int g_pts_flodet_ok   = 0, g_pts_flodet_gap   = 0;   /* `FsQueryFloaterDetails` */

// ── `T-A20`／`TASK-0302` 增量：`FsQueryTextDetails`（声明 `Pts.cs:3749-3753`；调用点
//    `TextParaClient.cs` 十余处，首个是 `ValidateVisual` 的 `:56`）──
//   签名（上游逐字，`Pts.cs:3750-3753`）：`int FsQueryTextDetails(IntPtr pfsContext, IntPtr pPara,
//     out FSTEXTDETAILS pTextDetails);`（`pfsContext` IN／`pPara` IN＝**文本段落句柄**／
//     `pTextDetails` **OUT**＝文本细节）
//   🔴 **为什么必须补它（现取的因果链）**：`T-A15`…`T-A19` 把缺省路径三级链推进到"页视觉帧 ＋
//     页自持状态"之后，`TextParaClient.ValidateVisual`（`TextParaClient.cs:55-56`）会调本入口 ——
//     该符号本侧**未导出** ⇒ `T-A19` 现读 `EntryPointNotFoundException: … 'FsQueryTextDetails'
//     in shared library 'PresentationNative_cor3.dll'`（`[HC-UNHANDLED]` 现面：**53 条，全部同名**）。
//     补上符号 ⇒ 该名**离开**"会 `EntryPointNotFoundException` 的缺口"名单（`ENFE` 归零）。
//   🔴 **诚实形态（本轮＝"诚实导出面"；`rc=0` 一次都不给）**：
//     · **入参按对象身份认领**：`pPara` 必须能被 `wpf_pts_sub_claim` **唯一认领**（＝本侧自有子轨/
//       段落对象内字段的地址；承 `FsQuerySubtrackDetails`／`FsQueryTrackDetails` 范式）。
//       认领**只**用于**分离失败原因**（"参数认不了" vs "出参无源"），**不**用于伪造成功。
//     · 🔴 **出参 `FSTEXTDETAILS` 本侧无源**（`Pts.cs:1486-1498`：判别联合 `fsktdFull`／`fsktdCached`，
//       两者都要**文本行模型** —— `cLines`／`dcpFirst`／`dcpLim`／`cAttachedObjects`／逐行 dvr 等）：
//       本侧**没有**那一层 ⇒ **永不写该出参**（一个字都不写；`out` 由调用方零初始化 ⇒ 不留毒值）。
//       ⚠️ **为什么"返 0 ＋ 写零值"就是假成功**：`fsktdFull` 支（`TextParaClient.cs:62`）会被读成
//       "本段有 0 行"、`fsktdCached` 支会被读成"缓存段无内容" ⇒ 消费者据此**静默丢掉整段文本**
//       （与 `cParas=0` 的 `P8` 恒绿陷阱同族，`P1-ptsname-result.md` 裁定四十八 (c)）⇒ **本条禁止**。
//     · **永不假成功**：本入口**没有**成功分支 ⇒ **恒返 `-10000`** ＋ 具名 `[FS_PAGE_GAP]` 留痕，
//       且**出参一字不写**。`rc=0` 的出现**只能**来自反腿（`WPF_PTS_FSQTD_FAKE=1`），**绝不进主链**。
//   ⚠️ **射程边界（如实划界，防被读宽）**：本增量**只**把"缺符号"变成"有符号的诚实拒绝" ——
//     它**不**声称"文本细节已可得"、**不**声称"页会可见变化"、**更不**构成"排版前进"的证据
//     （`P1-ptsname-result.md` 裁定：**"`ENFE` 归零"本身不构成任何证据**；`N2` 面 ≠ 内容面）。
//     具名 `NOINFO-fsquerytextdetails-out-param-source`（**射程＝"出参"这一面没源**，
//     **不是**"没有源"—— 入参面已认领；文本行模型面见 `P1-ptsname-result.md` 裁定四十九 (a)(c)）。
//   ⚠️ **反腿**（`WPF_PTS_FSQTD_FAKE=1`，**只在副本**）：恒假成功 ⇒「不可认领的 `pPara` 必被拒」当场红。
//   【本入口＝**查询**，无配对销毁入口；导出即改生成件 `bin/exports.txt`（同趟逐名对拍零消失）。】
int FsQueryTextDetails(void *pfscontext, void *pPara, void *pTextDetails)
{
    g_pts_fsqtd_calls++;
    { int _i = wpf_pts_index("FsQueryTextDetails"); if (_i >= 0) g_pts_seen[_i]++; }
    g_pts_qpd_prev_page = NULL;   /* 下游入口 ⇒ 断开"查询组"毗邻位（与同族查询同办） */
#if WPF_PTS_FSQTD_FAKE == 1
    /* 反腿（**只在副本**）：**假成功** —— 返 0 并把出参写成**捏造的** `fsktdCached`（`Pts.cs:1482`）。
       目的：证明「不可认领的 `pPara` 必被拒」这条断言**真的会红**（假腿 ⇒ 伪值亦"过关"）。 */
    if (pTextDetails) ((int *)pTextDetails)[0] = 0;   /* fsktd = fsktdCached（**捏造**，非任何源） */
    fprintf(stderr, "[FSQTD] rc=0 para=%p out=FAKE-WRITTEN basis=FAKE-UNCHECKED-PARA "
                    "NOINFO=fsquerytextdetails-out-param-source\n", pPara);
    return 0;
#else
    const char *reason = NULL;
    wpf_pts_subtrack *obj = NULL;
    wpf_pts_doc *dpt = wpf_pts_doc_ptr(pfscontext);   /* ⏪ `T-A22`：来源证据的**对象身份核验**用 */
    wpf_pts_prov *pev = NULL;
    if (!pTextDetails)                        { reason = "null-details-out";   g_pts_fsqtd_nullout++; }
    else if (!pPara)                          { reason = "null-para";          g_pts_fsqtd_nullpara++; }
    else if (!wpf_pts_sub_claim(pPara, &obj)) {
        /* ⏪ `T-A22`（`N1`）：本侧自有对象认不出 ⇒ **追加**「按来源证据认领 ＋ 对象身份核验」，
           形制与 `FsQuerySubtrackDetails` **完全一致**（通道 `'S'`＝`+136`／`+144` 段句柄）。
           认出 ⇒ 判词**分立**为 `claimed-by-provenance-no-text-line-model`（身份成立，但文本行模型
           本侧**无源** ⇒ 仍拒、出参一字不写）；认不出 ⇒ 旧判词 `unclaimable-para`（逐字保留）。 */
        if (wpf_pts_prov_claim(pPara, dpt, 'S', &pev)) {
            reason = "claimed-by-provenance-no-text-line-model";
            g_pts_fsqtd_provclaimed++;
            fprintf(stderr, "[PROVCLAIM] entry=FsQueryTextDetails p=%p claim=prov doc=%p ev_seq=%d "
                            "channel=S(+136/+144 段句柄) src=%s ord=%d gen=%d written_out=%d "
                            "claims_ok=%d wrong_object=%d aba=%d stale=%d zero_ev=%d "
                            "out=UNWRITTEN bytes=0 v=CLAIMED-NO-TEXT-MODEL\n",
                    pPara, (void *)dpt, pev->seq, pev->src, pev->ord, pev->gen, pev->written_out,
                    g_pts_prov_claim_ok, g_pts_prov_wrongobj, g_pts_prov_ababa, g_pts_prov_stale,
                    g_pts_prov_claim_no);
        } else {
            reason = "unclaimable-para";
            fprintf(stderr, "[PROVCLAIM] entry=FsQueryTextDetails p=%p claim=none doc=%p "
                            "claims_ok=%d wrong_object=%d aba=%d stale=%d zero_ev=%d "
                            "v=NO-PROVENANCE-EVIDENCE\n",
                    pPara, (void *)dpt, g_pts_prov_claim_ok, g_pts_prov_wrongobj,
                    g_pts_prov_ababa, g_pts_prov_stale, g_pts_prov_claim_no);
        }
        g_pts_fsqtd_unclaim++;
    }
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext))
                                              { reason = "unknown-ctx";        g_pts_fsqtd_unknown_ctx++; }
    else if (wpf_pts_fl_usable(obj)) {
        /* ── ✅ **回填成功分支**（⏪ `T-A33`）：`obj` 是本侧自有段落对象且**台账可用**
           （`fl_ok ∧ fl_complete ∧ !fl_truncated ∧ fl_nlines>0`，≠"未造型/未收束/撞界"）⇒ 逐字段
           取台账真值写入 `FSTEXTDETAILS`（先清零）。**这是唯一**会让本入口返回 `rc=0` 的主链路径
           （反腿 `WPF_PTS_FSQTD_FAKE` 除外）；未满足 ⇒ 走下方**诚实拒绝**（出参一字不写）。 */
        wpf_pts_tlb_fill_details(obj, pTextDetails);
        g_pts_fsqtd_ok++; g_pts_tlb_ok++;
        fprintf(stderr, "[FSQTD] rc=0 reason=ok entry=FsQueryTextDetails ctx=%p parah=%p "
                        "calls=%d ok=%d gap=%d nomodel=%d fsktd=1 cLines=%d dcpFirst=%d dcpLim=%d "
                        "fl_ok=%d out=WRITTEN bytes=112 src=ledger:fl_line[]"
                        "(pfnFormatLine+fsflres-end)\n",
                pfscontext, pPara, g_pts_fsqtd_calls, g_pts_fsqtd_ok, g_pts_fsqtd_gap,
                g_pts_fsqtd_nomodel, obj->fl_nlines, obj->fl_line[0].dcp_first,
                obj->fl_line[obj->fl_nlines - 1].dcp_lim, obj->fl_ok);
        /* ⏪ `T-A36`：`attached-objects(none)` ⇒ **具名真值**。**零假值**：
           `fl_att_n>0` ⇒ `attached-objects=figure=N,floater=M`（`idobj` 取自回调原值：`-2`＝Figure）；
           `fl_att_n==0 ∧ fl_att_calls>0`（**真查过**）⇒ `not-present(true-queried)`；
           `fl_att_calls==0`（**未查**，如闸关）⇒ `not-queried` —— **两者不混同**。 */
        {
            int nfig = 0, nflo = 0;
            for (int a = 0; a < obj->fl_att_n; a++) {
                if (obj->fl_att[a].idobj == -2) nfig++; else nflo++;
            }
            fprintf(stderr, "[FS_TLB] entry=FsQueryTextDetails parah=%p cLines=%d dcpFirst=%d dcpLim=%d "
                            "fl_calls=%d fl_ok=%d complete=%d truncated=%d "
                            "attached-objects=%s queried=%d gap=%d capped=%d figure=%d floater=%d "
                            "NOINFO=fsgeometry-layout(vrStart=self-accum)\n",
                    pPara, obj->fl_nlines, obj->fl_line[0].dcp_first,
                    obj->fl_line[obj->fl_nlines - 1].dcp_lim, obj->fl_calls, obj->fl_ok,
                    obj->fl_complete, obj->fl_truncated,
                    (obj->fl_att_n > 0) ? "present"
                                        : (obj->fl_att_calls > 0 ? "not-present(true-queried)" : "not-queried"),
                    obj->fl_att_calls, obj->fl_att_gap, obj->fl_att_capped, nfig, nflo);
        }
        (void)dpt;
        return 0;
    }
    else                                      { reason = "no-text-line-model"; g_pts_fsqtd_nomodel++; }
    (void)obj;                    /* 认领结果只用于**分离失败原因**，不参与任何写入 */
    (void)dpt;                    /* ⏪ `T-A22`：同上（只作**对象身份核验**的入参） */
    (void)pTextDetails;           /* 刻意只收不用（机器可读形态：参数在册但**零写入**） */
    /* ── 拒绝面（**零假值／出参一字不写**）：`pTextDetails` **绝不触碰**。 */
    g_pts_fsqtd_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTextDetails ctx=%p para=%p "
                    "calls=%d gap=%d nullout=%d nullpara=%d unclaim=%d unknown_ctx=%d nomodel=%d "
                    "out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pPara,
            g_pts_fsqtd_calls, g_pts_fsqtd_gap, g_pts_fsqtd_nullout, g_pts_fsqtd_nullpara,
            g_pts_fsqtd_unclaim, g_pts_fsqtd_unknown_ctx, g_pts_fsqtd_nomodel);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;   /* ← 无真值时改成 0 就是制造静默半通／伪成功 */
#endif
}

/* ══ `T-A26`／`TASK-0302` 增量：native「文本行模型」三入口 ═══════════════════════════════════
   声明（上游逐字）：
     · `FsQueryLineListSingle`（`Pts.cs:3756-3761`）：`int(IntPtr pfsContext, IntPtr pPara,
       int cLines, FSLINEDESCRIPTIONSINGLE* rgLineDesc, out int cLineDesc);`
     · `FsQueryLineListComposite`（`Pts.cs:3764-3769`）：`int(IntPtr pfsContext, IntPtr pPara,
       int cElements, FSLINEDESCRIPTIONCOMPOSITE* rgLineDescription, out int cLineElements);`
     · `FsQueryLineCompositeElementList`（`Pts.cs:3772-3777`）：`int(IntPtr pfsContext, IntPtr pLine,
       int cElements, FSLINEELEMENT* rgLineElement, out int cLineElements);`
   调用点（`PtsHost/PtsHelper.cs`，唯一三处）：`:652` `LineListSimpleFromTextPara`／
     `:671` `LineListCompositeFromTextPara`／`:689` `LineElementListFromCompositeLine`；
     消费者 `TextParaClient.cs`（`_paraHandle`；三处均以 `FsQueryTextDetails` 成功为前提）。
   🔴 **入参/出参可得性（本席现取，逐面）**：
     · 入参 `pPara`：文本段落句柄 —— 与本侧 `N1` 身份模型**同一枚**（＝ `FsQuerySubtrackParaList`
       交回的 `pfspara`；可 `wpf_pts_sub_claim` 按对象身份认领）。`pLine`（composite line 句柄）：
       本侧**无行对象台账**（本文件里没有 line 表）⇒ 恒不可认领（具名 `unclaimable-line`，
       与 `unclaimable-para` 分立）。
     · 出参 `rgLineDesc`／`rgLineDescription`／`rgLineElement`（行盒：`dcpFirst`/`dcpLim`/`dur`/
       `urStart`/`urBBox`/`dvrAscent`/`dvrDescent`/`vrStart`/`pfslineclient`…）：**本侧无源** ——
       行盒要「**行断器** ＋ **字符源（`dcp`↔字符）** ＋ **度量（字宽/字体）**」三样，本侧**一个都没有**
       （判据件 `build/MilBridge/P1-layout-content-criteria.md` §3.3／§4.1：LS 族 27 入口 22 缺、
       回调面 30 槽一个未接；`T-A25` 载体 §5-3 同结论）。**源在宿主侧**，取它要**新开一条与
       LineServices 同规模的链**（越级，另派）。
   🔴 **诚实形态（本增量）**：三入口**导出符号**（离开"会 `EntryPointNotFoundException` 的缺口"名单）
     ＋ **入参按对象身份认领**（只用于**分离失败原因**：参数认不了 vs 出参无源）＋ **出参一字不写**
     （`cLineDesc`/`cLineElements` 也**不写 0** —— 写 0 会被消费者读成"0 行"而**静默丢整段文本**，
     `P8` 恒绿陷阱，裁定四十八 (c)）＋ **恒返 `-10000`** ＋ **失败必留痕**（`[FS_PAGE_GAP]`）。
     ⇒ **永不假成功／零假值**；`rc=0` 的出现**只能**来自反腿（`WPF_PTS_FSQLL_FAKE=1`，**只在副本**）。
   ⚠️ **射程边界（如实划界，防被读宽）**：本增量**只**把"缺符号"变成"有符号的诚实拒绝" ——
     它**不**声称"文本行模型可得"、**不**声称"页会可见变化"、**更不**构成"排版前进"的证据
     （`P1-ptsname-result.md` 裁定：**"`ENFE` 归零"本身不构成任何证据**）。具名
     `NOINFO-text-line-model-source`（射程＝**行盒这一面没源**；入参面已认领）。 */
static int g_pts_fsqll_calls      = 0;   /* 三入口进入次数（合账；逐入口名见留痕行 `entry=`） */
static int g_pts_fsqll_gap        = 0;   /* 返非 0 次数（**本形态＝全部**：无成功分支） */
static int g_pts_fsqll_nullout    = 0;   /* 路①：`cLineDesc`/`cLineElements` 出参 == NULL */
static int g_pts_fsqll_nullobj    = 0;   /* 路②：`pPara`/`pLine` == NULL */
static int g_pts_fsqll_unclaim    = 0;   /* 路③：`pPara`/`pLine` 不可认领（外来值／栈地址） */
static int g_pts_fsqll_unknownctx = 0;   /* 路④：`pfscontext` 非空但不在册 */
static int g_pts_fsqll_nomodel    = 0;   /* 路⑤：认领成功但**出参无源**（本侧无文本行模型） */
/* 反腿开关（默认 `0` ⇒ 主链产物**零影响**）。`1` ⇒ 三入口**假成功**（返 0 并把计数出参写成入参）
   —— 用来证明「不可认领的 `pPara`/`pLine` 必被拒」这条断言**真的会红**（假腿 ⇒ 伪值亦"过关"）。
   **只在副本**以 `-DWPF_PTS_FSQLL_FAKE=1` 单独编译，**绝不进主链**（照 `T-A16`／`T-A19`／`T-A20` 形制）。 */
#ifndef WPF_PTS_FSQLL_FAKE
#define WPF_PTS_FSQLL_FAKE 0
#endif
/* 三入口共用的**进入记账**（计数 ＋ 断开"查询组"）。⏪ `T-A33`：从 `wpf_pts_line_reject` 里提出 ——
   使**回填成功路径**与**诚实拒绝路径**共用同一套 `calls=` 记账（不重复计、不漏计）。 */
static int g_pts_fsqll_ok = 0;   /* 三入口回填成功次数（⏪ `T-A33`；D2 的"真源"面） */
static void wpf_pts_line_enter(void)
{
    g_pts_fsqll_calls++;
    g_pts_qpd_prev_page = NULL;   /* 下游入口 ⇒ 断开"查询组"（与同族查询同办） */
}
/* 三入口共用的**诚实拒绝**实现。`objkind`＝`"para"`／`"line"`（只影响具名 reason 的词）。
   ⚠️ ⏪ `T-A33`：**不再**自增 `g_pts_fsqll_calls`（已由 `wpf_pts_line_enter` 计）⇒ 调用者必须先
   `wpf_pts_line_enter()`；本函数只做判词 ＋ 留痕 ＋ `gap` 恰涨 1。 */
static int wpf_pts_line_reject(const char *entry, const char *objkind, void *pfscontext,
                               void *pObj, int cIn, void *cOutPtr)
{
    char rbuf[48];
    const char *reason = NULL;
    if (!cOutPtr)                                  { reason = "null-count-out"; g_pts_fsqll_nullout++; }
    else if (!pObj)  { snprintf(rbuf, sizeof rbuf, "null-%s", objkind); reason = rbuf; g_pts_fsqll_nullobj++; }
    else if (!wpf_pts_sub_claim(pObj, NULL)) {
        /* 本侧自有对象认不出 ⇒ **追加**「按来源证据认领 ＋ 对象身份核验」（承 `N1`／`FsQueryTextDetails`
           形制）。认出 ⇒ 判词**分立**为 `claimed-by-provenance-no-text-line-model`（身份成立，
           行盒仍无源 ⇒ 仍拒、出参一字不写）；认不出 ⇒ 具名 `unclaimable-<objkind>`（逐字保留）。 */
        wpf_pts_doc  *dpt = wpf_pts_doc_ptr(pfscontext);
        wpf_pts_prov *pev = NULL;
        if (wpf_pts_prov_claim(pObj, dpt, 'S', &pev)) {
            reason = "claimed-by-provenance-no-text-line-model";
        } else {
            snprintf(rbuf, sizeof rbuf, "unclaimable-%s", objkind); reason = rbuf;
            g_pts_fsqll_unclaim++;
        }
    }
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) { reason = "unknown-ctx"; g_pts_fsqll_unknownctx++; }
    else                                           { reason = "no-text-line-model"; g_pts_fsqll_nomodel++; }
    (void)cIn;                    /* 入参只作**诊断留痕**，不参与任何写入 */
    /* ── 拒绝面（**零假值／出参一字不写**）：`cOutPtr` 与行盒数组**绝不触碰**。 */
    g_pts_fsqll_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=%s ctx=%p obj=%p c=%d "
                    "calls=%d ok=%d gap=%d nullout=%d nullobj=%d unclaim=%d unknown_ctx=%d nomodel=%d "
                    "out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, entry, pfscontext, pObj, cIn,
            g_pts_fsqll_calls, g_pts_fsqll_ok, g_pts_fsqll_gap, g_pts_fsqll_nullout, g_pts_fsqll_nullobj,
            g_pts_fsqll_unclaim, g_pts_fsqll_unknownctx, g_pts_fsqll_nomodel);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;   /* ← 无真值时改成 0 就是制造静默半通／伪成功 */
}

int FsQueryLineListSingle(void *pfscontext, void *pPara, int cLines, void *rgLineDesc, int *cLineDesc)
{
#if WPF_PTS_FSQLL_FAKE == 1
    if (cLineDesc) *cLineDesc = cLines;   /* 反腿：**伪造**（返 0 且计数＝入参） */
    fprintf(stderr, "[FSQLL] rc=0 entry=FsQueryLineListSingle out=FAKE-WRITTEN lines=%d "
                    "basis=FAKE-UNCHECKED-PARA NOINFO=text-line-model-source\n", cLines);
    return 0;
#else
    /* ⏪ `T-A33` 回填：入参身份可认领 ∧ 台账可用 ∧ 计数与台账**自洽** ∧ 出参非空 ⇒ 真填。 */
    wpf_pts_subtrack *obj = NULL;
    wpf_pts_line_enter();
    if (cLineDesc && pPara && wpf_pts_sub_claim(pPara, &obj) && wpf_pts_fl_usable(obj) &&
        rgLineDesc && cLines == obj->fl_nlines) {
        wpf_pts_tlb_fill_single(obj, (wpf_pts_fslds *)rgLineDesc, cLines);
        *cLineDesc = cLines;
        g_pts_fsqll_ok++; g_pts_tlb_ok++; g_pts_tlb_single_ok++;
        if (g_pts_qvp_open) g_pts_qvp_saw_fsqll = 1;   /* ⏪ `T-A41` `D0`：本轮的 visual/arrange 签名 */
        fprintf(stderr, "[FSQLL] rc=0 reason=ok entry=FsQueryLineListSingle ctx=%p parah=%p cLines=%d "
                        "calls=%d ok=%d gap=%d nomodel=%d fl_ok=%d out=WRITTEN bytes=%d "
                        "src=ledger:fl_line[]←pfnFormatLine\n",
                pfscontext, pPara, cLines, g_pts_fsqll_calls, g_pts_fsqll_ok, g_pts_fsqll_gap,
                g_pts_fsqll_nomodel, obj->fl_ok, (int)(cLines * (int)sizeof(wpf_pts_fslds)));
        fprintf(stderr, "[FS_TLB] entry=FsQueryLineListSingle parah=%p lines=%d dcpFirst=%d dcpLim=%d "
                        "NOINFO=fsgeometry-layout(vrStart=self-accum,urStart=urBBox,dur=self-page-width)\n",
                pPara, cLines, obj->fl_line[0].dcp_first, obj->fl_line[cLines - 1].dcp_lim);
        return 0;
    }
    return wpf_pts_line_reject("FsQueryLineListSingle", "para", pfscontext, pPara, cLines, (void *)cLineDesc);
#endif
}

int FsQueryLineListComposite(void *pfscontext, void *pPara, int cElements, void *rgLineDescription, int *cLineElements)
{
#if WPF_PTS_FSQLL_FAKE == 1
    if (cLineElements) *cLineElements = cElements;
    fprintf(stderr, "[FSQLL] rc=0 entry=FsQueryLineListComposite out=FAKE-WRITTEN elements=%d "
                    "basis=FAKE-UNCHECKED-PARA NOINFO=text-line-model-source\n", cElements);
    return 0;
#else
    wpf_pts_subtrack *obj = NULL;
    wpf_pts_line_enter();
    if (cLineElements && pPara && wpf_pts_sub_claim(pPara, &obj) && wpf_pts_fl_usable(obj) &&
        rgLineDescription && cElements == obj->fl_nlines) {
        wpf_pts_tlb_fill_composite(obj, (wpf_pts_fsldc *)rgLineDescription, cElements);
        *cLineElements = cElements;
        g_pts_fsqll_ok++; g_pts_tlb_ok++; g_pts_tlb_comp_ok++;
        fprintf(stderr, "[FSQLL] rc=0 reason=ok entry=FsQueryLineListComposite ctx=%p parah=%p cElements=%d "
                        "calls=%d ok=%d gap=%d nomodel=%d fl_ok=%d out=WRITTEN bytes=%d "
                        "src=ledger:fl_line[]←pfnFormatLine\n",
                pfscontext, pPara, cElements, g_pts_fsqll_calls, g_pts_fsqll_ok, g_pts_fsqll_gap,
                g_pts_fsqll_nomodel, obj->fl_ok, (int)(cElements * (int)sizeof(wpf_pts_fsldc)));
        return 0;
    }
    return wpf_pts_line_reject("FsQueryLineListComposite", "para", pfscontext, pPara, cElements, (void *)cLineElements);
#endif
}

int FsQueryLineCompositeElementList(void *pfscontext, void *pLine, int cElements, void *rgLineElement, int *cLineElements)
{
#if WPF_PTS_FSQLL_FAKE == 1
    if (cLineElements) *cLineElements = cElements;
    fprintf(stderr, "[FSQLL] rc=0 entry=FsQueryLineCompositeElementList out=FAKE-WRITTEN elements=%d "
                    "basis=FAKE-UNCHECKED-LINE NOINFO=text-line-model-source\n", cElements);
    return 0;
#else
    /* ⏪ `T-A33`：`pLine`＝台账行句柄（`pfsline`）⇒ **按行句柄在册认领**（唯一定位；歧义／未命中 ⇒ 拒）。 */
    wpf_pts_subtrack *obj = NULL; int idx = -1;
    wpf_pts_line_enter();
    if (cLineElements && wpf_pts_tlb_claim_line(pLine, &obj, &idx) && rgLineElement && cElements == 1) {
        wpf_pts_tlb_fill_element(obj, idx, (wpf_pts_fslineel *)rgLineElement);
        *cLineElements = 1;
        g_pts_fsqll_ok++; g_pts_tlb_ok++; g_pts_tlb_elem_ok++;
        fprintf(stderr, "[FSQLL] rc=0 reason=ok entry=FsQueryLineCompositeElementList ctx=%p pline=%p "
                        "cElements=%d calls=%d ok=%d gap=%d nomodel=%d out=WRITTEN bytes=%d "
                        "src=ledger:fl_line[%d]←pfnFormatLine\n",
                pfscontext, pLine, cElements, g_pts_fsqll_calls, g_pts_fsqll_ok, g_pts_fsqll_gap,
                g_pts_fsqll_nomodel, (int)sizeof(wpf_pts_fslineel), idx);
        return 0;
    }
    return wpf_pts_line_reject("FsQueryLineCompositeElementList", "line", pfscontext, pLine, cElements, (void *)cLineElements);
#endif
}

// ── ⏪ `T-A36`（`NATIVE-PTS-ATTACHED-OBJECTS-BACKFILL`）：**附属对象四入口** ──────────────────────
//   声明（上游逐字）：`FsQueryAttachedObjectList`（`Pts.cs:3789`）／`FsQuerySubpageDetails`
//     （`Pts.cs:3704`）／`FsQueryFigureObjectDetails`（`Pts.cs:3797`）／`FsQueryFloaterDetails`。
//   消费链（`TextParaClient.cs:122/1312/3732`）：`FsQueryTextDetails` 报 `cAttachedObjects>0`
//     ⇒ `ValidateVisualFloatersAndFigures` →（每个对象）`FsQueryAttachedObjectList` 取
//     `{pfspara,pfsparaclient,idobj}` ⇒ `HandleToObject(pfsparaclient)` 得 `FigureParaClient`/
//     `FloaterParaClient` ⇒ `ArrangeFigure/Floater`（`FsQueryFigureObjectDetails`/`FsQueryFloaterDetails`
//     给几何）⇒ `ValidateVisual`（`FsQuerySubpageDetails` ＋ `DrawBackgroundAndBorder`）。
//   🔴 **诚实形态**：认领**只**按台账真值（`wpf_pts_att_claim`／`wpf_pts_sub_claim`）；未命中／歧义／
//     计数不符／出参 NULL / 缺 paraclient ⇒ **返 -10000 ＋ 出参一字不写**；`rc=0` **只**在语义成立时给。
//   ⚠️ **射程（如实划界）**：几何＝**本侧约定**（`NOINFO-attached-object-geometry-layout`）；附属对象
//     的子页＝**空子页**（`cBasicColumns=0`；本侧**不**排附属对象内容 ⇒ `Figure`/`Floater` 的**背景**可绘、
//     **内容**不可绘）＋ `NOINFO-attached-content-not-laid-out`。
#define WPF_PTS_ATT_FIG_DU 42000     /* Figure 宽 140 DIP（×300）—— 本侧约定 */
#define WPF_PTS_ATT_FIG_DV 15000     /* Figure 高  50 DIP */
#define WPF_PTS_ATT_FLO_DU 85500     /* Floater 宽 285 DIP */
#define WPF_PTS_ATT_FLO_DV 30000     /* Floater 高 100 DIP */
// ── ⏪ `T-A42`：内容段**入站几何自洽** —— 附属对象页矩形锚的 `v` 与视口**同参照** ────────────────
//   算式（可复算，两行都逐字取自上/下游）：
//     · 托管 `FigureParaClient.OnArrange`：`_contentRect.v = _rect.v + mbp.BPTop`，`_rect = fsrcFlowAround`
//       （＝**本函数**给出的页矩形）；
//     · 托管 `FigureParaClient.UpdateViewport`：`viewportSubpage.v = viewport.v − ContentRect.v`；
//     · 托管 `TextParaClient.IntersectsWithRectOnV` 的两操作数 ＝ 内容段 `_rect.v`（子页内，由
//       `PtsHelper.ArrangeParaList(rcTrackContent = 子页轨 fsrc.v)` 定）与 `viewportSubpage.v`。
//   ⇒ **自洽（缺省）**：`v = 0` ⇒ `ContentRect.v = BPTop = 0`（Figure/Floater 无 Border/Padding）
//      ⇒ `viewportSubpage.v = viewport.v − 0 = viewport.v` ⇒ 与视口**同一参照**（页面 v 原点）。
//   ⇒ **反极性**（显式 `WPF_PTS_ATT_VSELF=0`）：逐字回原值 `20000 + (idx/4)*40000`
//      ⇒ `ContentRect.v = 20000`（＝ 66.67 DIP ≠ 视口原点）⇒ 两操作数**不同参照**。
//   ⇒ **远锚腿**（显式 `WPF_PTS_ATT_VSELF=f`）：`v = 200000`（＝ 666.67 DIP）⇒ `ContentRect.v > viewport.v + viewport.dv`
//      ⇒ `IntersectsWithRectOnV` **必假** ⇒ 用「门真／门假」两极判「门是不是该门」（`T-A39` 仪器 B 同向）。
//   两态在**同一产物**上可切 ⇒ 成对读数无需第二次构建（承 `T-A41` 的反极性形态）。
static int wpf_pts_att_page_anchor_v(int idx)
{
    const char *s = getenv("WPF_PTS_ATT_VSELF");
    if (s && s[0] == '0') return 20000 + (idx / 4) * 40000;   /* 缺失腿①：原值（ContentRect.v=20000 ≠ 视口原点） */
    if (s && s[0] == 'f') return 200000;                      /* 缺失腿②：远锚（ContentRect.v=200000 > 视口 v+dv ⇒ 相交门**必假**） */
    return 0;                                                 /* 自洽（缺省）：页面 v 原点 ⇒ 与视口**同参照** */
}
static void wpf_pts_att_geometry(int idx, int is_figure, wpf_pts_fsrect *out)
{
    out->du = is_figure ? WPF_PTS_ATT_FIG_DU : WPF_PTS_ATT_FLO_DU;
    out->dv = is_figure ? WPF_PTS_ATT_FIG_DV : WPF_PTS_ATT_FLO_DV;
    out->u  = 30000 + (idx % 4) * 30000;
    out->v  = wpf_pts_att_page_anchor_v(idx);
}
// `FsQueryAttachedObjectList`：按**文本段落**认领，返回该段附属对象描述数组（`Figure`/`Floater`）。
int FsQueryAttachedObjectList(void *pfscontext, void *pPara, int cAttachedObject,
                              void *rgAttachedObjects, int *cAttachedObjectDesc)
{
    wpf_pts_subtrack *obj = NULL;
    const char *reason = NULL;
    if (!cAttachedObjectDesc)      reason = "null-count-out";
    else if (!pPara)               reason = "null-para";
    else if (!wpf_pts_sub_claim(pPara, &obj)) reason = "unclaimable-para";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else if (obj->fl_att_n <= 0)   reason = "no-attached-objects";
    else if (cAttachedObject != obj->fl_att_n) reason = "count-mismatch";
    else if (!rgAttachedObjects)   reason = "null-array-out";
    else {
        /* 先**全体**校验（缺 paraclient ⇒ 一字不写，绝不部分写） */
        for (int a = 0; a < obj->fl_att_n; a++)
            if (!obj->fl_att[a].obj_client) { reason = "no-paraclient"; break; }
        if (!reason) {
            wpf_pts_fsattachedobjectdescription *rg = (wpf_pts_fsattachedobjectdescription *)rgAttachedObjects;
            for (int a = 0; a < obj->fl_att_n; a++) {
                wpf_pts_fsrect rc; wpf_pts_att_geometry(a, obj->fl_att[a].idobj == -2, &rc);
                memset((void *)&rg[a], 0, sizeof(rg[a]));
                rg[a].fsupdinf.fskupd = WPF_PTS_FSKUPD_NEW;   /* 首报 ⇒ New（触发 ValidateVisual） */
                rg[a].fsupdinf.dvr_shifted = 0;
                rg[a].pfspara       = (void *)obj->fl_att[a].nmp_obj;
                rg[a].pfsparaclient = (void *)obj->fl_att[a].obj_client;
                rg[a].nmp           = (void *)obj->fl_att[a].nmp_obj;
                rg[a].idobj         = obj->fl_att[a].idobj;
                rg[a].vr_start      = 0;
                rg[a].dvr_used      = rc.dv;
                rg[a].fsbbox.f_defined = 1;
                rg[a].fsbbox.fsrc      = rc;
                rg[a].dvr_top_space = 0;
            }
            *cAttachedObjectDesc = obj->fl_att_n;
            g_pts_att_list_ok++;
            if (g_pts_qvp_open) g_pts_qvp_saw_att = 1;   /* ⏪ `T-A41` `D0`：本轮的 viewport 签名 */
            fprintf(stderr, "[FS_ATT] rc=0 entry=FsQueryAttachedObjectList para=%p cAttachedObjects=%d "
                            "out=WRITTEN bytes=%d src=ledger:fl_att[]\n",
                    pPara, obj->fl_att_n,
                    (int)(obj->fl_att_n * (int)sizeof(wpf_pts_fsattachedobjectdescription)));
            return 0;
        }
    }
    g_pts_att_list_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryAttachedObjectList ctx=%p para=%p c=%d "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, pPara, cAttachedObject,
            g_pts_att_list_ok, g_pts_att_list_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// ── ⏪ `T-A37`（`NATIVE-PTS-ATTACHED-CONTENT-LAYOUT`）：`FsCreateSubpageFinite`／`FsDestroySubpage` ────
//   声明（上游逐字）：`FsCreateSubpageFinite`（`Pts.cs:3169`，**29 参**）／`FsDestroySubpage`（`Pts.cs` 同族）。
//   调用方（**唯一**）：托管"附属对象内容排版"回调 —— `FigureParagraph.CreateSubpageFiniteHelper`
//     （`FigureParagraph.cs:707`）／`FloaterParagraph.CreateSubpageFiniteHelper`（`FloaterParagraph.cs:707`）
//     ⇒ 二者**无条件** `PTS.Validate(PTS.FsCreateSubpageFinite(...))`（`Pts.cs:3169`）。**改前该符号未导出**
//     ⇒ 托管抛 `EntryPointNotFoundException` ⇒ 被 `PtsHost` 包裹捕 ⇒ 回调返 `-100002` ⇒ `SubpageHandle`
//     **永不设** ⇒ 附属对象**内容**（`Beige`／`DarkGreen`／`LightGoldenrodYellow`）**不绘**。
//   🔴 **本实现的诚实形态**：`pSubPage` ＝ **本侧真对象**（`wpf_pts_subpage`，句柄 ＝ 该对象内 `c_paras` 字段
//     地址）；内容段序**窗内真枚举**（`+136`／`+144`）；容器段客户端**窗内**由托管 `+176` **真造**
//     （**唯一合法来源**）。**未枚举成功／未造出客户端** ⇒ `c_paras=0`（**真 0**，不是伪值）。
//   🔴 **几何（如实划界）**：`fsrc`／`dvrUsed` 取**入参**（`lWidth`／`lHeight`，托管按 `Figure.Width` 算）；
//     `fsBBox.fDefined=0` ⇒ 托管**跳过**二次排版与 `FsDestroySubpage` 支（`FigureParagraph.cs:185/193`）。
//     `ppBRSubPageOut` **恒 NULL** ⇒ 托管不调 `FsDestroySubpageBreakRecord`（本侧不产生断页记录）。
//   ⚠️ **射程**：本入口**只**解"内容子页这一层"——**不是**"PTS 真实现"、**不是**"该页内容全绘出"。
int FsCreateSubpageFinite(void *pfscontext, void *pBRSubPageStart, int fFromPreviousPage,
                          const void *nSeg, const void *pFtnRej, int fEmptyOk, int fSuppressTopSpace,
                          unsigned int fswdir, int lWidth, int lHeight, void *rcMargin,
                          int cColumns, const void *rgColumnInfo, int fApplyColumnBalancing,
                          int cSegmentAreas, const void *rgnSegmentForArea, const void *rgSpanForSegmentArea,
                          int cHeightAreas, const void *rgHeightForArea, const void *rgSpanForHeightArea,
                          int fAllowOverhangBottom, int fsksuppress, void *pfsfmtrOut,
                          void **ppSubPageOut, void **ppBRSubPageOut, int *pdvrUsed, void *pfsBBoxOut,
                          void **ppfsMcsClient, int *ptopSpace)
{
    (void)pBRSubPageStart; (void)fFromPreviousPage; (void)pFtnRej; (void)fEmptyOk; (void)fSuppressTopSpace;
    (void)fswdir; (void)rcMargin; (void)cColumns; (void)rgColumnInfo; (void)fApplyColumnBalancing;
    (void)cSegmentAreas; (void)rgnSegmentForArea; (void)rgSpanForSegmentArea; (void)cHeightAreas;
    (void)rgHeightForArea; (void)rgSpanForHeightArea; (void)fAllowOverhangBottom; (void)fsksuppress;
    const char *reason = NULL;
    if (pfsfmtrOut)        memset(pfsfmtrOut, 0, 12);   /* `FSFMTR` ＝ 3×int ⇒ `kstop=GoalReached(0)`（**真值**） */
    if (pfsBBoxOut)        memset(pfsBBoxOut, 0, 20);   /* `FSBBOX` ⇒ `fDefined=0`（托管跳过二次排版／销毁） */
    if (ppSubPageOut)      *ppSubPageOut = NULL;
    if (ppBRSubPageOut)    *ppBRSubPageOut = NULL;      /* 恒 NULL ⇒ 托管不调销毁断页记录 */
    if (pdvrUsed)          *pdvrUsed = 0;
    if (ppfsMcsClient)     *ppfsMcsClient = NULL;
    if (ptopSpace)         *ptopSpace = 0;
    if (!ppSubPageOut || !pfsfmtrOut) reason = "null-out";
    else if (!pfscontext)             reason = "null-ctx";
    else {
        wpf_pts_doc *d = wpf_pts_doc_ptr(pfscontext);
        if (!d)                                   reason = "unknown-ctx";
        else if (!nSeg)                           reason = "null-nseg";
        else if (g_pts_sp_live_n >= WPF_PTS_SP_MAX) reason = "table-full";
        else {
            struct wpf_pts_subpage_s *s = wpf_pts_sp_new(pfscontext, nSeg);
            if (!s) reason = "alloc-fail";
            else {
                s->fsrc_u = 0; s->fsrc_v = 0; s->fsrc_du = lWidth; s->fsrc_dv = lHeight;
                s->dvr_used = lHeight;
                /* 内容树：**窗内**枚举 `nSeg` 的段序（`+136`／`+144`）＋递归建本侧对象。 */
                s->cont_obj = wpf_pts_sub_new(nSeg, NULL);
                if (s->cont_obj) {
                    wpf_pts_sub_enum_into(d, nSeg, s->cont_obj, "FsCreateSubpageFinite", 0);
                    wpf_pts_sub_mark_subpage(s->cont_obj, lWidth, lHeight);   /* ⏪ T-A37：内容树几何 */
                }
                /* 内容容器段客户端：**窗内** `+176` **真造**（托管回调交回，唯一合法来源）。 */
                const void *fp176 = wpf_pts_snap_word(d, WPF_PTS_SNAP_IDX_CREATEPARACLIENT);
                if (fp176 && d->in_win) {
                    void *h = NULL;
                    int rc = ((wpf_pts_fn_create_paraclient)fp176)((const void *)d->p_fsclient,
                                                                   (const void *)nSeg, &h);
                    if (rc == 0 && h) s->cont_client = (const void *)h;
                }
                s->c_paras = (s->cont_obj && s->cont_obj->enum_ok) ? 1 : 0;
                *ppSubPageOut = (void *)wpf_pts_sp_handle(s);
                if (pdvrUsed) *pdvrUsed = lHeight;
                g_pts_sp_ok++;
                fprintf(stderr, "[SUBPAGE] rc=0 entry=FsCreateSubpageFinite seg=%p w=%d h=%d cParas=%d "
                                "cont_children=%d cont_client=%p hand=%p tok=in-window-enum(+136/+144)+managed-176\n",
                        nSeg, lWidth, lHeight, s->c_paras,
                        s->cont_obj ? s->cont_obj->c_paras : -1, s->cont_client, wpf_pts_sp_handle(s));
                return 0;
            }
        }
    }
    g_pts_sp_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsCreateSubpageFinite ctx=%p seg=%p ok=%d gap=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, nSeg, g_pts_sp_ok, g_pts_sp_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// `FsDestroySubpage`：按**本侧对象身份**认领后销毁（未命中 ⇒ 拒，出参无）。
int FsDestroySubpage(void *pfscontext, void *pSubPage)
{
    (void)pfscontext;
    struct wpf_pts_subpage_s *s = NULL;
    if (pSubPage && wpf_pts_sp_claim_track(pSubPage, &s)) { wpf_pts_sp_destroy(s); return 0; }
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// ── ⏪ `T-A56`：`FsClearUpdateInfoInSubpage`（上游 `Pts.cs:3263`，**2 参**）──────────────────────────
//   调用方（现取）：`CellParaClient.Arrange`（`CellParaClient.cs:119`）—— 单元**真排版**后**必调**
//     （`T-A56` 之前本移植不排单元 ⇒ 该入口从未被调 ⇒ 未导出 ⇒ `EntryPointNotFoundException`
//     ⇒ 整页 `ArrangeOverride` 抛；本增量把它补上）。另两条上层入口
//     （`PtsHost.ClearUpdateInfoInFloaterContent`／`SubpageClearUpdateInfoInPara`）本侧**未发调**。
//   🔴 **本实现的诚实形态**：按**本侧对象身份**认领（`wpf_pts_sp_claim_track`）后返 `rc=0`；
//     本侧 `FsQuerySubpageDetails` **恒报首态**（`fskupd=New`）⇒ "清更新信息"在语义上**无需改状态**
//     （下次查询仍是 `New` ⇒ 托管重建视觉；**不**冒充"稳态 `NoChange`"，见 `NOINFO=`）。
//   **零假值**：空／未知句柄 ⇒ **诚实拒**（`-10000` ＋ 具名 `[FS_PAGE_GAP]`），**不**冒充成功。
int FsClearUpdateInfoInSubpage(void *pfscontext, void *pSubpage)
{
    (void)pfscontext;
    struct wpf_pts_subpage_s *s = NULL;
    if (pSubpage && wpf_pts_sp_claim_track(pSubpage, &s)) {
        g_pts_sp_clrupd_ok++;
        fprintf(stderr, "[FS_CLRUPD] rc=0 entry=FsClearUpdateInfoInSubpage subpage=%p ok=%d gap=%d "
                        "NOINFO=query-always-first-state(New)\n",
                pSubpage, g_pts_sp_clrupd_ok, g_pts_sp_clrupd_gap);
        return 0;
    }
    g_pts_sp_clrupd_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsClearUpdateInfoInSubpage ctx=%p p=%p "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, pSubpage ? "unknown-subpage" : "null-subpage",
            pfscontext, pSubpage, g_pts_sp_clrupd_ok, g_pts_sp_clrupd_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// `FsQuerySubpageDetails`：按**附属对象段落句柄**认领，返回**空子页**（本侧不排附属对象内容）。
//   🔴 `pSubPage`（＝托管 `FigureParaClient.SubpageHandle`）**由托管在"附属对象内容排版"回调里**设
//     （`FigureParagraph.cs:284`／`FloaterParagraph.cs:355/523` 的 `SubpageHandle = pfs*Content`）。
//     本侧 native **未驱动**该内容排版 ⇒ 该句柄**恒 0** ⇒ `pSubPage == NULL`。此**不是**错误入参，
//     而是"内容未排 ⇒ **子页确实为空**"的**真值**：本入口对 `pSubPage == NULL` **返回空子页**
//     （`fSimple=0`／`cBasicColumns=0`，**这是真值**）并**具名**；非空但不可认领 ⇒ 仍拒。
int FsQuerySubpageDetails(void *pfscontext, void *pSubPage, void *pSubPageDetails)
{
    wpf_pts_subtrack *obj = NULL; int idx = -1;
    struct wpf_pts_subpage_s *sp = NULL;
    const char *reason = NULL;
    if (!pSubPageDetails) reason = "null-out";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else if (pSubPage && wpf_pts_sp_claim_track(pSubPage, &sp)) {
        /* ── ✅ ⏪ `T-A37`：**内容子页支**（`pSubPage` ＝ 本侧 `FsCreateSubpageFinite` 交出的真对象句柄）──
           托管 `FigureParaClient.ValidateVisual`（`FigureParaClient.cs:346`）据此走 `fSimple` 支
           ⇒ `PtsHelper.UpdateTrackVisuals` ⇒ 内容轨的段列表 ⇒ 内容**段落真绘出**。 */
        wpf_pts_fssubpagedetails *d = (wpf_pts_fssubpagedetails *)pSubPageDetails;
        memset((void *)d, 0, sizeof(*d));
        d->f_simple = 1;                                     /* simple（单轨） */
        d->u.simple.fswdir = 0;
        d->u.simple.trackdescr.fsupdinf.fskupd       = WPF_PTS_FSKUPD_NEW;   /* 首报 ⇒ New */
        d->u.simple.trackdescr.fsupdinf.dvr_shifted  = 0;
        d->u.simple.trackdescr.nms                   = (void *)sp->nseg;
        d->u.simple.trackdescr.fsrc.u = sp->fsrc_u; d->u.simple.trackdescr.fsrc.v  = sp->fsrc_v;
        d->u.simple.trackdescr.fsrc.du = sp->fsrc_du; d->u.simple.trackdescr.fsrc.dv = sp->fsrc_dv;
        d->u.simple.trackdescr.fsbbox.f_defined      = 0;
        d->u.simple.trackdescr.f_track_relative_to_rect = 0;
        d->u.simple.trackdescr.pfstrack              = (void *)wpf_pts_sp_handle(sp);
        g_pts_spquery_ok++; g_pts_subpage_ok++;
        fprintf(stderr, "[FS_ATT] rc=0 entry=FsQuerySubpageDetails subpage=%p fSimple=1 cParas=%d "
                        "track=%p fsrc=(%d,%d,%d,%d) src=owned-subpage NOINFO=subpage-geometry-declared(lWidth/lHeight)\n",
                pSubPage, sp->c_paras, (void *)wpf_pts_sp_handle(sp),
                sp->fsrc_u, sp->fsrc_v, sp->fsrc_du, sp->fsrc_dv);
        return 0;
    }
    else if (pSubPage && !wpf_pts_att_claim(pSubPage, pfscontext, &obj, &idx)) reason = "unclaimable-subpage";
    else {
        wpf_pts_fssubpagedetails *d = (wpf_pts_fssubpagedetails *)pSubPageDetails;
        wpf_pts_fsrect rc; rc.u = rc.v = rc.du = rc.dv = 0;
        const char *src = "handle-unset(attached-content-not-laid-out)";
        if (obj) { wpf_pts_att_geometry(idx, obj->fl_att[idx].idobj == -2, &rc); src = "claimed"; }
        memset((void *)d, 0, sizeof(*d));
        d->f_simple = 0;                       /* complex（空子页：cBasicColumns=0） */
        d->u.complex.nms = NULL;
        d->u.complex.fswdir = 0;
        d->u.complex.fsrc = rc;
        d->u.complex.fsbbox.f_defined = obj ? 1 : 0;
        d->u.complex.fsbbox.fsrc = rc;
        d->u.complex.c_basic_columns = 0;
        g_pts_subpage_ok++;
        fprintf(stderr, "[FS_ATT] rc=0 entry=FsQuerySubpageDetails subpage=%p fSimple=0 cBasicColumns=0 "
                        "src=%s out=WRITTEN bytes=%d NOINFO=attached-content-not-laid-out\n",
                pSubPage, src, (int)sizeof(*d));
        return 0;
    }
    g_pts_subpage_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQuerySubpageDetails ctx=%p subpage=%p "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, pSubPage,
            g_pts_subpage_ok, g_pts_subpage_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// `FsQueryFigureObjectDetails`：按**附属对象段落句柄**认领（须是 Figure），给图几何。
int FsQueryFigureObjectDetails(void *pfscontext, void *pPara, void *pFigureDetails)
{
    wpf_pts_subtrack *obj = NULL; int idx = -1;
    const char *reason = NULL;
    if (!pFigureDetails) reason = "null-out";
    else if (!pPara)     reason = "null-figure";
    else if (!wpf_pts_att_claim(pPara, pfscontext, &obj, &idx)) reason = "unclaimable-figure";
    else if (obj->fl_att[idx].idobj != -2) reason = "not-a-figure";
    else {
        wpf_pts_fsfiguredetails *d = (wpf_pts_fsfiguredetails *)pFigureDetails;
        wpf_pts_fsrect rc; wpf_pts_att_geometry(idx, 1, &rc);
        memset((void *)d, 0, sizeof(*d));
        d->fsrc_flow_around = rc;
        d->fsbbox.f_defined = 1;
        d->fsbbox.fsrc = rc;
        d->fspt_pos_preliminary.u = rc.u;
        d->fspt_pos_preliminary.v = rc.v;
        d->f_delayed = 0;
        g_pts_figdet_ok++;
        if (g_pts_qvp_open) g_pts_qvp_saw_figobj = 1;   /* ⏪ `T-A41` `D0`：本轮的 arrange 签名 */
        fprintf(stderr, "[FS_ATT] rc=0 entry=FsQueryFigureObjectDetails figure=%p fsrc=(%d,%d,%d,%d) "
                        "out=WRITTEN bytes=%d NOINFO=attached-object-geometry-layout(self-convention)\n",
                pPara, rc.u, rc.v, rc.du, rc.dv, (int)sizeof(*d));
        return 0;
    }
    g_pts_figdet_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryFigureObjectDetails ctx=%p p=%p "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, pPara,
            g_pts_figdet_ok, g_pts_figdet_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// `FsQueryFloaterDetails`：按**附属对象段落句柄**认领（须是 Floater），给 floater 几何（内容＝空）。
int FsQueryFloaterDetails(void *pfscontext, void *pPara, void *pFloaterDetails)
{
    wpf_pts_subtrack *obj = NULL; int idx = -1;
    const char *reason = NULL;
    if (!pFloaterDetails) reason = "null-out";
    else if (!pPara)      reason = "null-floater";
    else if (!wpf_pts_att_claim(pPara, pfscontext, &obj, &idx)) reason = "unclaimable-floater";
    else if (obj->fl_att[idx].idobj == -2) reason = "not-a-floater";
    else {
        wpf_pts_fsfloaterdetails *d = (wpf_pts_fsfloaterdetails *)pFloaterDetails;
        wpf_pts_fsrect rc; wpf_pts_att_geometry(idx, 0, &rc);
        memset((void *)d, 0, sizeof(*d));
        d->fskupd_content = WPF_PTS_FSKUPD_NEW;
        d->fsnm_floater = (void *)obj->fl_att[idx].nmp_obj;
        d->fsrc_floater = rc;
        d->pfs_floater_content = NULL;         /* 空内容（本侧不排内容） */
        g_pts_flodet_ok++;
        fprintf(stderr, "[FS_ATT] rc=0 entry=FsQueryFloaterDetails floater=%p fsrc=(%d,%d,%d,%d) "
                        "out=WRITTEN bytes=%d NOINFO=attached-content-not-laid-out\n",
                pPara, rc.u, rc.v, rc.du, rc.dv, (int)sizeof(*d));
        return 0;
    }
    g_pts_flodet_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryFloaterDetails ctx=%p p=%p "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, pPara,
            g_pts_flodet_ok, g_pts_flodet_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

/* ══ ⏪ `T-A53`（`NATIVE-PTS-TABLEOBJ`）：Table 族**五入口**（`FsQueryTableObj*`）———————————————
   上游声明（`upstream/…/PtsHost/Pts.cs`）：`FsQueryTableObjDetails`（`:3815`）／`...TableProperDetails`
     （`:3823`）／`...RowList`（`:3829`）／`...RowDetails`（`:3837`）／`...CellList`（`:3843`）。
   🔴 **本实现的诚实形态**：模型来源**唯一** ＝ `wpf_pts_tableobj_drive` 在**窗内**用托管回调
     （`pfnGetFirstRow`／`pfnGetNextRow`／`pfnGetRowProperties`）建出的**本侧表模型**（`g_pts_tbl[]`）。
     **零假值**：无模型（未驱／驱失败）⇒ **诚实拒绝**（返 `-10000` ＋ 具名 `[FS_PAGE_GAP]`，出参一字不写），
     **绝不**返回"空表"冒充成功。单元面如实报 `cCells=0`（本侧确未排单元；见 `wpf_pts_tableobj_drive` 口径）。 */
typedef struct { int u, v, du, dv; } wpf_pts_tbl_rect;
typedef struct {
    void          *fsnm_table;
    wpf_pts_tbl_rect fsrc_table_obj;
    int            dvr_top_caption, dvr_bottom_caption, dur_left_caption, dur_right_caption;
    unsigned int   fswdir_table;
    int            fskupd_table_proper;
    void          *pfstableproper;
} wpf_pts_fstableobjdetails;
typedef struct { int dvr_table; int c_rows; } wpf_pts_fstabledetails;
typedef struct {
    wpf_pts_fsupdinf fsupdinf;
    void          *fsnm_row;
    void          *pfstablerow;
    int            f_row_in_separate_rect;
    union { wpf_pts_tbl_rect fsrc_row; int dvr_row; } u;
} wpf_pts_fstablerowdescription;
typedef struct {
    int fskboundary_above; int dvr_above;
    int fskboundary_below; int dvr_below;
    int c_cells;           int f_forced_row;
} wpf_pts_fstablerowdetails;
_Static_assert(sizeof(wpf_pts_fstableobjdetails) == 56, "FSTABLEOBJDETAILS != 56 B");
_Static_assert(offsetof(wpf_pts_fstableobjdetails, fsrc_table_obj) == 8, "fsrcTableObj 偏移 != 8");
_Static_assert(offsetof(wpf_pts_fstableobjdetails, fswdir_table) == 40, "fswdirTable 偏移 != 40");
_Static_assert(offsetof(wpf_pts_fstableobjdetails, fskupd_table_proper) == 44, "fskupdTableProper 偏移 != 44");
_Static_assert(offsetof(wpf_pts_fstableobjdetails, pfstableproper) == 48, "pfstableProper 偏移 != 48");
_Static_assert(sizeof(wpf_pts_fstabledetails) == 8, "FSTABLEDETAILS != 8 B");
_Static_assert(sizeof(wpf_pts_fstablerowdescription) == 48, "FSTABLEROWDESCRIPTION != 48 B");
_Static_assert(offsetof(wpf_pts_fstablerowdescription, u) == 28, "FSTABLEROWDESCRIPTION.u 偏移 != 28");
_Static_assert(sizeof(wpf_pts_fstablerowdetails) == 24, "FSTABLEROWDETAILS != 24 B");

/* ── ⏪ `T-A56`：**单元内容高 → 行高**的派生（**查询期**；口径同 `FsQuerySubtrackParaList` 的内容段高）──
   `wpf_pts_tbl_cell_content_dv`：该单元**内容子页**的内容树里，逐叶段按 `pfnFormatLine` **真台账**
   累加 `Σ(dvrAscent+dvrDescent)`（`wpf_pts_fl_usable` 判可用）。**零假值**：无可用户台账 ⇒ 返 `-1`
   （**不**用 `pfnFormatCellFinite` 的 `dvrUsed`——本侧 `FsCreateSubpageFinite` 恒报 `dvrUsed=lHeight`）。 */
static int wpf_pts_tbl_cell_content_dv(const wpf_pts_tbl_cell *c)
{
    if (!c || !c->sub_obj) return -1;
    struct wpf_pts_subpage_s *s = (struct wpf_pts_subpage_s *)c->sub_obj;
    if (s->magic != WPF_PTS_SP_MAGIC) return -1;
    return wpf_pts_tbl_cell_tree_dv(s->cont_obj);
}
/* 行高：有真单元 ⇒ `max(单元内容高)+dvrAboveRow+dvrBelowRow`（不足本侧下界取下界）；否则退回本侧约定值。 */
static int wpf_pts_tbl_row_dvr(const wpf_pts_tbl_row *r)
{
    if (!r) return WPF_PTS_TBL_DVR_MIN;
    if (r->n_cells <= 0) return r->dvr_row;
    int maxc = -1;
    for (int c = 0; c < r->n_cells; c++) {
        int h = wpf_pts_tbl_cell_content_dv(&r->cells[c]);
        if (h > maxc) maxc = h;
    }
    if (maxc < 0) return r->dvr_row;                     /* 台账不可用 ⇒ 退回（**不**假造高） */
    int dr = maxc + r->dvr_above + r->dvr_below;
    if (dr < WPF_PTS_TBL_DVR_MIN) dr = WPF_PTS_TBL_DVR_MIN;
    return dr;
}
static int wpf_pts_tbl_total_dv(const wpf_pts_tbl_model *m)
{
    int s = 0; for (int i = 0; i < m->nrows; i++) s += wpf_pts_tbl_row_dvr(&m->rows[i]); return s;
}
// `FsQueryTableObjDetails`：按**表段落句柄**（托管 `_paraHandle`）认模型。
int FsQueryTableObjDetails(void *pfscontext, void *pPara, void *pTableObjDetails)
{
    const char *reason = NULL;
    if (!pTableObjDetails) reason = "null-out";
    else if (!pPara)       reason = "null-table";
    else {
        /* ⏪ `T-A53`：托管 `_paraHandle` 来源 ＝ `FsQueryTrackParaList` 的 `FSPARADESCRIPTION.pfspara`
           ⇒ 拿到的是**本侧子轨对象句柄**（`&o->c_paras`，见 `PtsHelper.ArrangeParaList`）。故先按
           **对象身份**把该句柄还原成它承载的**段落句柄**（`o->nmp`）再查模型；直接命中亦容（双入口）。 */
        wpf_pts_tbl_model *m = wpf_pts_tbl_find(pPara);
        if (!m) {
            wpf_pts_subtrack *o = NULL;
            if (wpf_pts_sub_claim(pPara, &o) && o && o->nmp) m = wpf_pts_tbl_find(o->nmp);
        }
        if (!m) reason = "no-table-model";
        else {
            wpf_pts_fstableobjdetails *d = (wpf_pts_fstableobjdetails *)pTableObjDetails;
            wpf_pts_tbl_rect rc;
            rc.u = 0; rc.v = 0;
            rc.du = (m->autofit_width > 0) ? m->autofit_width : WPF_PTS_FLOATER_AVAIL_DU;
            rc.dv = wpf_pts_tbl_total_dv(m);
            memset((void *)d, 0, sizeof(*d));
            d->fsnm_table         = (void *)m->nm_table;
            d->fsrc_table_obj     = rc;
            d->fswdir_table       = 0;
            d->fskupd_table_proper= WPF_PTS_FSKUPD_NEW;
            d->pfstableproper     = (void *)m->pfstableproper;
            g_pts_tbl_query_ok++;
            fprintf(stderr, "[FSTABLEOBJ-Q] rc=0 entry=FsQueryTableObjDetails table=%p fsrc=(%d,%d,%d,%d) "
                            "cRows=%d fskupd=New proper=%p NOINFO=table-geometry-self-convention\n",
                    pPara, rc.u, rc.v, rc.du, rc.dv, m->nrows, (void *)m->pfstableproper);
            return 0;
        }
    }
    g_pts_tbl_query_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTableObjDetails ctx=%p p=%p "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, pPara,
            g_pts_tbl_query_ok, g_pts_tbl_query_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// `FsQueryTableObjTableProperDetails`：按**表 token** 认模型，报 `dvrTable`／`cRows`。
int FsQueryTableObjTableProperDetails(void *pfscontext, void *pTableProper, void *pTableDetails)
{
    const char *reason = NULL;
    if (!pTableDetails) reason = "null-out";
    else {
        wpf_pts_tbl_model *m = wpf_pts_tbl_find_proper(pTableProper);
        if (!m) reason = "no-table-model";
        else {
            wpf_pts_fstabledetails *d = (wpf_pts_fstabledetails *)pTableDetails;
            memset((void *)d, 0, sizeof(*d));
            d->dvr_table = wpf_pts_tbl_total_dv(m);
            d->c_rows    = m->nrows;
            g_pts_tbl_query_ok++;
            fprintf(stderr, "[FSTABLEOBJ-Q] rc=0 entry=FsQueryTableObjTableProperDetails proper=%p "
                            "dvrTable=%d cRows=%d\n", pTableProper, d->dvr_table, d->c_rows);
            return 0;
        }
    }
    g_pts_tbl_query_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTableObjTableProperDetails ctx=%p p=%p "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, pTableProper,
            g_pts_tbl_query_ok, g_pts_tbl_query_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// `FsQueryTableObjRowList`：把本侧行描述逐条填进托管缓冲。
//   ⏪ `T-A56`：行高由**单元内容台账**派生（`wpf_pts_tbl_row_dvr`，与**窗内**同一台账；
//   窗内已用 `pfnSetCellHeight` 把同一行高告知各单元 ⇒ 此处**只读回填**，**不**再发托管回调
//   —— 实测窗外调 `pfnSetCellHeight` 撞 `PtsHost.get_PtsContext()` 的 `Invariant.FailFast`）。
int FsQueryTableObjRowList(void *pfscontext, void *pTableProper, int cRows, void *rgTableRowDesc,
                           int *pcRowsActual)
{
    const char *reason = NULL;
    if (pcRowsActual) *pcRowsActual = 0;
    if (!rgTableRowDesc || !pcRowsActual) reason = "null-out";
    else {
        wpf_pts_tbl_model *m = wpf_pts_tbl_find_proper(pTableProper);
        if (!m) reason = "no-table-model";
        else {
            int n = (cRows < m->nrows) ? cRows : m->nrows;
            wpf_pts_fstablerowdescription *rg = (wpf_pts_fstablerowdescription *)rgTableRowDesc;
            for (int i = 0; i < n; i++) {
                memset(&rg[i], 0, sizeof(rg[i]));
                rg[i].fsupdinf.fskupd = WPF_PTS_FSKUPD_NEW;
                rg[i].fsnm_row        = (void *)m->rows[i].nm_row;
                rg[i].pfstablerow     = (void *)m->rows[i].pfstablerow;
                rg[i].u.dvr_row       = wpf_pts_tbl_row_dvr(&m->rows[i]);
            }
            *pcRowsActual = n;
            g_pts_tbl_query_ok++;
            fprintf(stderr, "[FSTABLEOBJ-Q] rc=0 entry=FsQueryTableObjRowList proper=%p asked=%d filled=%d "
                            "dvr0=%d NOINFO=row-height-from-cell-content-ledger\n",
                    pTableProper, cRows, n, n > 0 ? wpf_pts_tbl_row_dvr(&m->rows[0]) : 0);
            return 0;
        }
    }
    g_pts_tbl_query_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTableObjRowList ctx=%p p=%p "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, pTableProper,
            g_pts_tbl_query_ok, g_pts_tbl_query_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// `FsQueryTableObjRowDetails`：按**行 token** 认行；单元面报**真值**（`T-A56`：本侧真排出的单元数）。
int FsQueryTableObjRowDetails(void *pfscontext, void *pTableRow, void *pTableRowDetails)
{
    const char *reason = NULL;
    if (!pTableRowDetails) reason = "null-out";
    else {
        wpf_pts_tbl_row *r = wpf_pts_tbl_find_row(pTableRow);
        if (!r) reason = "no-table-row";
        else {
            wpf_pts_fstablerowdetails *d = (wpf_pts_fstablerowdetails *)pTableRowDetails;
            memset((void *)d, 0, sizeof(*d));
            d->fskboundary_above = 0;   /* fsktablerowboundaryOuter */
            d->dvr_above         = 0;
            d->fskboundary_below = 0;   /* fsktablerowboundaryOuter */
            d->dvr_below         = 0;
            /* ⏪ `T-A56`：**真值** —— 本侧真排出的单元数（未排 ⇒ 0 的**诚实的空**）。 */
            d->c_cells           = r->n_cells;
            d->f_forced_row      = 0;
            g_pts_tbl_query_ok++;
            fprintf(stderr, "[FSTABLEOBJ-Q] rc=0 entry=FsQueryTableObjRowDetails row=%p cCells=%d "
                            "src_cCells=%d v=%s\n", pTableRow, r->n_cells, r->c_cells,
                    (r->n_cells > 0) ? "cells-laid-out" : "cells-not-laid-out");
            return 0;
        }
    }
    g_pts_tbl_query_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTableObjRowDetails ctx=%p p=%p "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, pTableRow,
            g_pts_tbl_query_ok, g_pts_tbl_query_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}
// `FsQueryTableObjCellList`：按**行 token** 认行，逐格填 `T-A56` 真排出的单元
//   （`rgfskupd`／`rgpfscell`／`rgkcellmerge`／`*pcCellsActual`）。
//   ⚠️ **ABI 修正（`T-A56`）**：上游声明（`Pts.cs:3843-3850`）是 **7 参**：
//     `(pfscontext, pfstablerow, cCells, FSKUPDATE* rgfskupd, IntPtr* rgpfscell,
//       FSTABLEKCELLMERGE* rgkcellmerge, out int pcCellsActual)`。
//     改前本侧是 **6 参**且顺序不同（`…, void *rgCell, int *pcCellsActual, void *rgCellMerge`）
//     —— 该错位**从未触发**（`FsQueryTableObjRowDetails` 恒报 `cCells=0` ⇒ 托管不调本入口）。
//     `T-A56` 让行详情报**真 `cCells`** ⇒ 本入口**必被调** ⇒ 必须先把 ABI 对齐（否则托管写越界/读错位）。
//   **零假值**：无模型／无该行 ⇒ 诚实拒（`-10000` ＋ 具名 `[FS_PAGE_GAP]`，出参一字不写）。
int FsQueryTableObjCellList(void *pfscontext, void *pTableRow, int cCells, void *rgFskupd,
                            void *rgPfscell, void *rgKcellmerge, int *pcCellsActual)
{
    int *rgupd = (int *)rgFskupd;
    void **rgcell = (void **)rgPfscell;
    int *rgmerge = (int *)rgKcellmerge;
    const char *reason = NULL;
    (void)pfscontext;
    if (pcCellsActual) *pcCellsActual = 0;
    if (!rgFskupd || !rgPfscell || !rgKcellmerge || !pcCellsActual) reason = "null-out";
    else {
        wpf_pts_tbl_row *r = wpf_pts_tbl_find_row(pTableRow);
        if (!r) reason = "no-table-row";
        else {
            int n = (cCells < r->n_cells) ? cCells : r->n_cells;
            for (int i = 0; i < n; i++) {
                rgupd[i]   = r->cells[i].fskupd;
                rgcell[i]  = (void *)r->cells[i].pfscell;
                rgmerge[i] = r->cells[i].kcellmerge;
            }
            *pcCellsActual = n;
            g_pts_tbl_query_ok++;
            fprintf(stderr, "[FSTABLEOBJ-Q] rc=0 entry=FsQueryTableObjCellList row=%p asked=%d filled=%d "
                            "src=managed-GetCells+FormatCellFinite\n", pTableRow, cCells, n);
            return 0;
        }
    }
    g_pts_tbl_query_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTableObjCellList ctx=%p p=%p "
                    "ok=%d gap=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason ? reason : "unknown", pfscontext, pTableRow,
            g_pts_tbl_query_ok, g_pts_tbl_query_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

/* ⏪ `t125`：`wpf_pts_doc_find` 的定义体（**只比指针身份**，不 deref 入参）。 */
static int wpf_pts_doc_find(const void *ctx)
{
    if (!ctx) return 0;
    for (int i = 0; i < g_pts_doc_live_n; i++) {
        if (g_pts_doc_live[i]->magic != WPF_PTS_DOC_MAGIC) continue;
        if ((const void *)g_pts_doc_live[i] == ctx) return 1;
    }
    return 0;
}

/* ⏪ `t146`：与 `wpf_pts_doc_find` 同谓词（**只按指针身份**、不 deref），但返回对象指针。 */
/* ⏪ `t156`（判据 §8.3.3）：**"该 context 未被销毁"** 的同趟读数 ——
   口径 ＝ **该 doc 仍在 `g_pts_doc_live[]` 里**（`DestroyDocContext` 成功时会把它移出并 `free`）。
   ⚠️ **这是 native 侧自记面，不是托管侧读数**：它只能证明"我们的登记表里还有它"，
   **不能**证明托管 `PtsContext.Disposed == false` ⇒ 判词里必须如实标注该口径。 */
static int wpf_pts_ctx_is_live(const wpf_pts_doc *d)
{
    if (!d) return 0;
    for (int i = 0; i < g_pts_doc_live_n; i++) {
        if ((const wpf_pts_doc *)g_pts_doc_live[i] == d) return 1;
    }
    return 0;
}

static wpf_pts_doc *wpf_pts_doc_ptr(const void *ctx)
{
    if (!ctx) return NULL;
    for (int i = 0; i < g_pts_doc_live_n; i++) {
        if (g_pts_doc_live[i]->magic != WPF_PTS_DOC_MAGIC) continue;
        if ((const void *)g_pts_doc_live[i] == ctx) return g_pts_doc_live[i];
    }
    return NULL;
}

// ── `t127`／裁定二十七 · **字段级诚实性**的统一判据（一对反腿共用**同一个**谓词）──────────
//   族属（队长要求写明）：**与裁定二十三「不许静默 stub」同族** —— 两者都是
//   「**账面（返回值/计数器）对了，而交出去的东西没用**」。裁定二十三管**入口**（返 0 却什么都不做），
//   本判据管**数据字段**（字段非空、却不是"我们自己的、可身份校验的"那个）。⇒ **不另开一套**，
//   只是把同一族的口径从"入口面"推到"字段面"。
//   🔴 **判据（两条并列，缺一即红）**：
//     ① **可身份校验**：该句柄**等于我们登记表里某个页对象内那个字段的地址**（⇒ **不 deref 未知指针**，
//        只做**指针值比较**；⇒ 全局常量/栈地址/伪造地址**必然不满足**）；
//     ② **非空可用**：句柄 ≠ NULL **且**它真能驱动下游（对本条＝ `FsQueryTrackDetails` 认它）。
//   ⇒ 反腿两种形态**都由本谓词判**：a) 交 `NULL` ⇒ ① 与 ② 同时不满足；b) 交"看似真、实则伪"
//      （全局常量／栈上局部变量地址）⇒ ② 可能满足而 **① 必不满足** ⇒ **照样红**。
//   ⚠️ 本助手**只读**：它把"这个句柄是不是我们自己的"算成一个可判定的整数结果，供夹具与探针共用。
static int wpf_pts_track_owned(const void *track)
{
    if (!track) return 0;
    for (int i = 0; i < g_pts_fsp_live_n; i++) {
        if (g_pts_fsp_live[i]->magic != WPF_PTS_FSP_MAGIC) continue;
        if ((const void *)&g_pts_fsp_live[i]->c_paras == track) return 1;   /* **指针值比较**，不 deref */
    }
    return 0;
}

// ── `t127` 靶心①：`FsQueryTrackDetails`（声明 `Pts.cs:3690`；**上游 1101 次调用**的落点）──────
//   `int FsQueryTrackDetails(IntPtr pfsContext, IntPtr pTrack, out FSTRACKDETAILS pTrackDetails);`
//   `FSTRACKDETAILS` **只有一个字段 `int cParas`**（现取 `Pts.cs:1512-1515`）⇒ 最小可辩护语义 ＝
//   「**这条 track 有多少段**」，且**按对象给**（不是全局常量）。
//   ⚠️ **它之所以"单独修不好"**：入参 `pTrack` 就是我们在 `FSPAGEDETAILS.u.simple.trackdescr.pfstrack`
//     里发出的那个值；`t125` 那手没填它 ⇒ 交出去是 `NULL` ⇒ 对 `NULL` 返 0 是**判据明禁的假成功**。
//     ⇒ 本步**同趟**修两处：`FsQueryPageDetails` 回填真句柄（见上）＋ 本入口按身份认它。
int FsQueryTrackDetails(void *pfscontext, void *pTrack, void *pTrackDetails)
{
    struct wpf_pts_subpage_s *sp = NULL;
    const char *reason = NULL;
    g_pts_qpd_prev_page = NULL;   /* `T-A15`：下游入口 ⇒ 断开"查询组"（页视觉帧的查询在它之后另起一组）*/
    if (pTrackDetails) *(int *)pTrackDetails = 0;          /* 失败路径：先清成 0（不留残留） */
    if (!pTrackDetails)               reason = "null-details-out";
    else if (!pTrack)                 reason = "null-track";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else if (wpf_pts_sp_claim_track(pTrack, &sp)) {
        /* ── ✅ ⏪ `T-A37`：**内容子页的轨**（`pTrack` ＝ `wpf_pts_sp_handle(sp)`）—— 按对象回答段数。 */
        *(int *)pTrackDetails = sp->c_paras;
        g_pts_sptrack_ok++;
        { int _i = wpf_pts_index("FsQueryTrackDetails"); if (_i >= 0) g_pts_seen[_i]++; }
        g_pts_seq++;
        return 0;
    }
    else if (!wpf_pts_track_owned(pTrack)) reason = "unknown-track-or-not-ours";
    else {
        for (int i = 0; i < g_pts_fsp_live_n; i++) {
            if ((const void *)&g_pts_fsp_live[i]->c_paras != pTrack) continue;
            *(int *)pTrackDetails = g_pts_fsp_live[i]->c_paras;   /* **按对象**回答段数 */
            g_pts_fsp_live[i]->qpd_fstd_since++;   /* ⏪ `T-A15`：判别器的计数（`[VIS]` 在 `FsQueryTrackParaList`）*/
            g_pts_fsp_trk_ok++;
            { int _i = wpf_pts_index("FsQueryTrackDetails"); if (_i >= 0) g_pts_seen[_i]++; }
            g_pts_seq++;
            return 0;
        }
        reason = "unknown-track-or-not-ours";
    }
    g_pts_fsp_trk_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTrackDetails ctx=%p track=%p ok=%d gap=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pTrack, g_pts_fsp_trk_ok, g_pts_fsp_trk_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

// ── `t127` 靶心②：`FsCreatePageFinite`（声明 `Pts.cs:3110`；调用点 `PtsPage.cs:397`）──────────
//   `int FsCreatePageFinite(IntPtr pfscontext, IntPtr pfsBRPageStart, IntPtr fsnmSectStart,
//                           out FSFMTR pfsfmtrOut, out IntPtr ppfsPageOut, out IntPtr ppfsBRPageOut);`
//   `FSFMTR` 是 **struct**（`Pts.cs:1141`：`kstop` ＋ 两个 `int`）⇒ 出参是 `int *`（3 个字宽）。
//   成功 ⇒ 真页对象落进**同一张表**（⇒ `FsQueryPageDetails`／`FsDestroyPage` 生命周期通用）＋
//   `ppfsBRPageOut` 给一个**本对象内字段的地址**（同一"字段级诚实性"口径，非 NULL、可身份校验）；
//   失败 ⇒ **三个出参全清** ＋ 留痕。
#define WPF_PTS_FSP_FIN_DU  768
#define WPF_PTS_FSP_FIN_DV  576
int FsCreatePageFinite(void *pfscontext, void *pfsBRPageStart, const void *fsnmSectStart,
                       int *pfsfmtrOut, void **ppfsPageOut, void **ppfsBRPageOut)
{
    const char *reason = NULL;
    if (pfsfmtrOut)   { pfsfmtrOut[0] = 0; pfsfmtrOut[1] = 0; pfsfmtrOut[2] = 0; }   /* 清成确定值 */
    if (ppfsPageOut)   *ppfsPageOut   = NULL;
    if (ppfsBRPageOut) *ppfsBRPageOut = NULL;
    if (!pfsfmtrOut || !ppfsPageOut || !ppfsBRPageOut) reason = "null-out";
    else if (!pfscontext)                              reason = "null-ctx";
    else if (!wpf_pts_doc_find(pfscontext))            reason = "unknown-ctx";
    else if (g_pts_fsp_live_n >= WPF_PTS_FSP_MAX)      reason = "table-full";
    else {
        wpf_pts_fsp *p = (wpf_pts_fsp *)calloc(1, sizeof(*p));
        if (!p) reason = "alloc-fail";
        else {
            p->magic = WPF_PTS_FSP_MAGIC;
            p->ctx   = pfscontext;
            p->sect  = fsnmSectStart;
            /* ⏪ `t146`：第二处调用窗（预算已耗则记 `budget-exhausted`，不重复调） */
            wpf_pts_drive_probe(wpf_pts_doc_ptr(pfscontext), fsnmSectStart, "FsCreatePageFinite");
            p->result = 0;
            p->pg_w = WPF_PTS_FSP_FIN_DU; p->pg_h = WPF_PTS_FSP_FIN_DV;
            p->bbox_defined = 1;
            p->c_paras = 1;
            g_pts_fsp_live[g_pts_fsp_live_n++] = p;
            g_pts_fsp_fin_ok++;
            *ppfsPageOut   = (void *)p;
            *ppfsBRPageOut = (void *)&p->c_paras;     /* 断页记录句柄：**本对象内**字段地址（非 NULL、可身份校验） */
            (void)pfsBRPageStart;
            { int _i = wpf_pts_index("FsCreatePageFinite"); if (_i >= 0) g_pts_seen[_i]++; }
            g_pts_seq++;
            return 0;                                  /* ← 改成别的值就是制造静默半通 */
        }
    }
    g_pts_fsp_fin_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsCreatePageFinite ctx=%p ok=%d gap=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, g_pts_fsp_fin_ok, g_pts_fsp_fin_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;
}

// ── `t129`／P1-W51 靶心：`FsQueryTrackParaList`（声明 `Pts.cs:3696-3701`；调用点 `PtsHelper.cs:614`）──
//   签名：`int FsQueryTrackParaList(IntPtr pfsContext, IntPtr pTrack, int cParas,
//                                  FSPARADESCRIPTION* rgParaDesc, out int cParaDesc);`
//   🔴 **本入口的诚实上界（现取，见载体 §1.2）**：`FSPARADESCRIPTION.pfsparaclient` 会被拿去反查一个
//      **托管对象**（`ContainerParaClient.cs:249/:289/:342/:386` ⇒ `PtsContext.HandleToObject(...)`），
//      而 `HandleToObject`（`PtsContext.cs:243-249`）把该值当**托管表 `_unmanagedHandles` 的索引**：
//        `Invariant.Assert(handleLong > 0 && handleLong < _unmanagedHandles.Length, "Invalid object handle.");`
//      ⇒ 我方**无法**凭空造出可用值：写指针 ⇒ 越界 ⇒ `Invariant.FailFast`(**不可捕获**)；写 0 ⇒ 同一条；
//        写小整数 ⇒ 槽里不是 `BaseParaClient` ⇒ `as` 得 null ⇒ NRE。**后者比 NULL 更危险**。
//   ⇒ **本实现的选择（写死，防被读成"没做完"）**：**永不假成功** —— 一律**返非 0 ＋ 记数 ＋ 留痕**，
//      **不写 `rgParaDesc` 一个字节**、`*cParaDesc = 0`。**不**为了让 `ENFE` 好看而填伪造句柄
//      （那正是裁定二十三「不许静默 stub」＋ `t127`「字段级诚实性」两条都在禁的形态）。
//   ⚠️ 拒绝面**在成功条件不具备时才是"诚实失败"**；一旦托管侧真建出段落客户端并可经表反查，
//      本格应改为"真填"，届时其可用性由**同一个**字段级诚实性谓词判（`wpf_pts_track_owned` 那一族）。
int FsQueryTrackParaList(void *pfscontext, void *pTrack, int cParas, void *rgParaDesc, int *cParaDesc)
{
    struct wpf_pts_subpage_s *sp = NULL;
    const char *reason = NULL;
    wpf_pts_drive_probe2_oow(pfscontext, "FsQueryTrackParaList");   /* ⏪ `t151` 窗外腿（调用点 ②；该入口日志可证被调）。
       ⏪ `T-A17`：是否驱由 `dp->drive_handles_live` 判（**只在页销毁后**拒驱 ⇒ 之前读数与改前成对） */
    g_pts_qpd_prev_page = NULL;   /* `T-A15`：下游入口 ⇒ 断开"查询组" */
    if (cParaDesc) *cParaDesc = 0;                       /* 失败：出参先清成 0（不留残留） */
    /* ⏪ `T-A15`：页视觉帧的**下游见证**（`[VIS]` 的唯一发点）。**只在三条件同时成立**时才认：
       ① 上一次 `FsQueryPageDetails` 给过 `fskupdNew(2)`（`qpd_new_pending`）—— 而 `New` 只发给**"查询组的首次"**
          查询（组内后续查询给 `NoChange`，见 `FsQueryPageDetails` 的语义注释）；
       ② 自那次查询以来 `FsQueryTrackDetails` **恰被调过 1 次**（`qpd_fstd_since == 1`）；
       ③ 本次调用认到的是**本页的轨句柄**（`pTrack == &pg->c_paras`，**指针值比较**，不 deref）。
       ⚠️ **为什么这三条能定钉"页视觉帧"**（现取来源，`upstream/…/PtsHost/`，行号仅本次有效）：
         · **页视觉帧**：`PtsPage.UpdatePageVisuals:996`(查询) → `:1029-1032` 建轨视觉 → `:1042` 取 `[0]`
           → `:1043 PtsHelper.UpdateTrackVisuals:218` 的 `FsQueryTrackDetails` **×1** → `:225 ParaListFromTrack`
           → 本入口；
         · **同帧的第三个消费者**（非视觉）：它的页查询**与 `GetRect`／`GetBoundingBox` 的查询紧邻成组**
           ⇒ 拿到的是 `NoChange`（`qpd_new_pending == 0`）⇒ 它的 `FsQueryTrackParaList` **不会**被认作见证。
       ⇒ `== 1` ⇒ 页视觉帧（`pageContentVisual.Children` 已由 `:1029-1032` 置为**恰 1 个**轨视觉容器
                     ⇒ `:1042` 的 `visualChildren[0]` **必中**，不再抛 `AOOORE`）；
          `>= 2` ⇒ 该次 `New` 的消费者的调用链里有多条轨查询 ⇒ **不认**。
       这同时消掉 `A14` §6-3 的 `NOINFO(NO-MANAGED-VISUAL-FRAME-COUNTER)`。 */
    {
        wpf_pts_fsp *pg = NULL;
        for (int i = 0; i < g_pts_fsp_live_n; i++) {       /* **指针值比较**，不 deref 未知句柄 */
            if (g_pts_fsp_live[i]->magic != WPF_PTS_FSP_MAGIC) continue;
            if ((const void *)&g_pts_fsp_live[i]->c_paras == pTrack) { pg = g_pts_fsp_live[i]; break; }
        }
        if (pg && pg->qpd_new_pending && pg->qpd_fstd_since == 1) {
            pg->qpd_new_pending = 0;
            pg->qpd_vis_built   = 1;
            g_pts_fsp_vis_ok++;
            fprintf(stderr, "[VIS] children=1 page=%p page_qpd=%d fstd_since_qpd=%d vis_n=%d seq=%d "
                            "basis=fmtrackparalist-after-qpdnew-with-1-trackdetails "
                            "NOINFO=fspagedetails-page-change-tracking\n",
                    (void *)pg, pg->qpd_calls, pg->qpd_fstd_since, g_pts_fsp_vis_ok, g_pts_seq);
        }
    }
    if (!cParaDesc)                       reason = "null-count-out";
    else if (!pTrack)                     reason = "null-track";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else if (wpf_pts_sp_claim_track(pTrack, &sp)) {
        /* ── ✅ ⏪ `T-A37`：**内容子页轨支** ─────────────────────────────────────────────────
           托管 `PtsHelper.UpdateTrackVisuals`（`PtsHelper.cs:218/:225`）对子页轨先问 `FsQueryTrackDetails`
           （本侧已答 `cParas`），再问本入口取段列表。**真填**：`pfspara` ＝ 本侧自有子轨对象句柄
           （`wpf_pts_sub_handle(sp->cont_obj)`），`pfsparaclient` ＝ 窗内 `+176` 真造的内容容器客户端。
           **零假值**：未枚举成功／未造出客户端 ⇒ 拒（出参一字不写）。 */
        if (!sp->cont_client || !sp->cont_obj)      reason = "subpage-content-not-laid-out";
        else if (cParas != sp->c_paras)             reason = "cparas-mismatch";
        else if (cParas > 0 && !rgParaDesc)         reason = "null-paradesc-out";
        else {
            wpf_pts_fsparadesc *rg = (wpf_pts_fsparadesc *)rgParaDesc;
            for (int i = 0; i < cParas; i++) {
                memset((void *)&rg[i], 0, sizeof(rg[i]));
                rg[i].fsupdinf.fskupd = WPF_PTS_FSKUPD_NEW;
                rg[i].pfspara       = (void *)wpf_pts_sub_handle(sp->cont_obj);
                rg[i].pfsparaclient = (void *)sp->cont_client;
                rg[i].nmp           = (void *)sp->nseg;
                rg[i].dvr_used      = sp->dvr_used;
                rg[i].dvr_top_space = 0;
            }
            *cParaDesc = cParas;
            g_pts_sptrack_ok++;
            fprintf(stderr, "[FSPARALIST-FILL-SP] rc=0 reason=ok entry=FsQueryTrackParaList track=%p cParas=%d "
                            "pfspara=%p client=%p src=owned-subpage(cont_obj+managed-176) ok=%d gap=%d\n",
                    pTrack, cParas, (void *)wpf_pts_sub_handle(sp->cont_obj), sp->cont_client,
                    g_pts_sptrack_ok, g_pts_sptrack_gap);
            return 0;
        }
    }
    else if (!wpf_pts_track_owned(pTrack)) reason = "unknown-track-or-not-ours";
    else if (cParas < 0)                  reason = "negative-cparas";
    else if (cParas > 0 && !rgParaDesc)   reason = "null-paradesc-out";
    /* ★ 本步的**承重拒绝**：即使入参全都合法、track 也确是我们自己的，**仍然拒** ——
       因为"可用的 `pfsparaclient`"只能由**托管侧**产生（见上）⇒ 返 0 就是**假成功**。
       ⏪ `t160`（P1-W80）：**探针门开时**先走**真填**路径（下面那块）；门关／填不成 ⇒ **逐字保持旧行为**
       （`-10000` ＋ `reason=paraclient-table-not-native`）⇒ **缺省路径零变化**。 */
    else {
        int fsp_filled = 0;
#if WPF_PTS_FSP_PL_LMWIT_NOARR
        if (1) { reason = "lmwit-noarr-reverse-leg(不填列表 ⇒ 到达见证恒 0)"; }
        else
#endif
        if (cParas == 0) { /* 没有条目可填（判据 §2.4-2 要求 `n >= 1`）⇒ 走旧路径 */ }
        else if (wpf_pts_drive_probe_enabled()) {
            wpf_pts_doc *dp = wpf_pts_doc_ptr(pfscontext);   /* ⚠️ `_find` 是**布尔**谓词；取指针用 `_ptr` */
            const void *fp176f = dp ? wpf_pts_snap_word(dp, WPF_PTS_SNAP_IDX_CREATEPARACLIENT)  : NULL;
            const void *fp192f = dp ? wpf_pts_snap_word(dp, WPF_PTS_SNAP_IDX_DESTROYPARACLIENT) : NULL;
#if WPF_PTS_FSP_PL_ABA
            static int aba_armed = 0;
#endif
            const int   maxc   = wpf_pts_fsp_pl_max();
#if WPF_PTS_FSP_PL_ABA
            if (aba_armed)                                    reason = "aba-leg-stopped";
            else
#endif
            if (!dp || !fp176f || !fp192f)                    reason = "no-slot-or-doc";
            /* ⏪ `T-A17`：**句柄 liveness 判据** —— 页销毁后（`drive_handles_live==0`）该 doc 的
               `drive_nmp`（以及复用的 `fsp_pl_cur`）均已被托管释放 ⇒ 再调 `+176 CreateParaclient`
               必撞 `PtsContext.HandleToObject` 的 `Invariant.Assert`（**不可捕获 `FailFast`**）
               ⇒ **拒填**（出参一字不写 ＋ 具名 `reason`；成功路径逐字不变）。
               ⏪ `T-A47`（`QTP-LIVE-NARROW`）：该拒因**收窄**为"**下一次填充必然要发 `+176`** 时才拒"。
                 🔴 **现取证据（`T-A47` 双腿 `~/tA47-work/{fix1,pol1}`，同一 `.so 5b7d0ac101673900`／
                 同一 `pf 189e3704cbf4f031`／同一装置 `:231`／同批工具，只差一个 env）**：
                 本条在 `pol1`（`WPF_PTS_QTP_LIVE_NARROW=0`）上**照旧拒** ⇒ `[FS_PAGE_GAP] rc=-10000
                 reason=drive-handles-released(page-destroyed) entry=FsQueryTrackParaList`（`pol1` 第 2121 行
                 一带）⇒ 上级 `PTS.Validate` 抛 ⇒ `[HC-UNHANDLED] #1 PtsException … '-10000'`。
                 ⇒ 即：**这条闩把"页销毁"读成了"本 doc 此后一律不可服务"**，而 `drive_handles_live`
                 只在 `FsDestroyPage` 置 0、只在 `wpf_pts_drive_probe` 置 1（而后者每 doc 只跑一次，
                 `drive_done`）⇒ **单向闩**。
                 🔴 **但那条理由只对"要发 `+176`"成立**：`+176` 吃的是**托管句柄**（`drive_nmp`／
                 `children[]`），页销毁后它们确已被托管释放 ⇒ 发调必 `FailFast`。
                 ⚠️ **而窗外（查询期）本入口本就不发 `+176`**：③ 换代要求 `wpf_pts_qtp_create_safe(dp)`
                 （`in_win`）、④ 造新一代要求 `!dp->fsp_pl_cur`；**手上已有 `fsp_pl_cur`**（本侧自持、
                 由 `+176` 真造出、只由 `+192` 回收而其**从不回收**当前代）**时，本次填充一个托管句柄都不碰**
                 ⇒ 拒填**过宽**。
                 ⇒ 收窄：`(!drive_handles_live ∧ !fsp_pl_cur)` 才拒（＝"必发 `+176`"）。
                 ⚠️ **绝不假成功**：出参仍是**真值**（`pfsparaclient` ＝ `fsp_pl_cur` 的真句柄；
                 `pfspara` ＝ 本侧自有子轨对象字段地址；`cParaDesc` ＝ `cParas`）；**其它任何拒因**
                 （`no-legal-nmp-in-this-run`／`fill-budget-exhausted`／`para-claim-failed` …）**逐字不变**。 */
            else if (WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD && !dp->drive_handles_live
                     && !(wpf_pts_qtp_live_narrow() && dp->fsp_pl_cur)) reason = "drive-handles-released(page-destroyed)";
            else if (!dp->drive_nmp)                          reason = "no-legal-nmp-in-this-run";
            else if (maxc > 0 && g_pts_fsp_pl_fills >= maxc)  reason = "fill-budget-exhausted";
            else {
                /* ① **第一代**选择（两腿实验 W-1／W-2 的源）：窗内探针 or 窗外腿 */
                if (!dp->fsp_pl_cur && dp->fsp_pl_gen == 0) {
                    const int want_out = wpf_pts_fsp_pl_win_out();
                    const void *first = want_out ? dp->fsp_pl_src_out : dp->fsp_pl_src_in;
                    if (!first) reason = want_out ? "no-out-of-window-client-yet" : "no-in-window-client-yet";
                    else {
                        dp->fsp_pl_cur = first; dp->fsp_pl_gen = 1;
                        dp->fsp_pl_site = want_out ? "probe-out" : "probe-in";
                        g_pts_fsp_pl_last_rc176 = want_out ? dp->fsp_pl_src_rc_out : dp->fsp_pl_src_rc_in;
                    }
                }
                /* ② **延迟回收上一代**（在**下一次**调用里做 ⇒ 绝不"返回前回收"，判据 §2.3/P4） */
                if (!reason && dp->fsp_pl_prev) {
                    const void *prev = dp->fsp_pl_prev;
                    dp->fsp_pl_prev = NULL;
                    int rc192 = ((wpf_pts_fn_destroy_paraclient)fp192f)((const void *)dp->p_fsclient, prev);
                    g_pts_fsp_pl_teardown_rc = rc192;
                    g_pts_fsp_pl_consumes++;
#if WPF_PTS_FSP_PL_LMWIT
                    {   /* ⏪ `t198`：**去掉静默阈值**（`t196` §6 条款）—— 回收一到就打，且**必打**。 */
                        const int arr_ok = (g_pts_fsp_pl_consumes > 0 && g_pts_fsp_pl_resolve_ok > 0);
                        const int ar_out = (g_pts_lmwit_dvr_used - g_pts_lmwit_dvr_top > 0);
                        const int d_desc = g_pts_lmwit_desc_dvr_used - g_pts_lmwit_desc_dvr_top;
                        const int ar_desc = (g_pts_lmwit_desc_led_ok && d_desc > 0);
                        fprintf(stderr, "[LMWIT] part=arrival consumes=%d resolve_ok=%d | "
                                        "arith_outparam_dv=%d(dvrUsed=%d,dvrTopSpace=%d) "
                                        "arith_descriptor_dv=%d(dvr_used=%d,dvr_top_space=%d,led_ok=%d,src=%s) | "
                                        "config gen_size_knob=%d declared=%d | joint arrival_ok=%d "
                                        "arith_descriptor_ok=%d granularity=single-call+counting-port "
                                        "(NOT-direct-host-read) v=%s\n",
                                g_pts_fsp_pl_consumes, g_pts_fsp_pl_resolve_ok,
                                g_pts_lmwit_dvr_used - g_pts_lmwit_dvr_top,
                                g_pts_lmwit_dvr_used, g_pts_lmwit_dvr_top,
                                d_desc, g_pts_lmwit_desc_dvr_used, g_pts_lmwit_desc_dvr_top,
                                g_pts_lmwit_desc_led_ok, g_pts_lmwit_desc_src,
                                wpf_pts_fsp_pl_gen_size(), wpf_pts_fsp_pl_gen_declared(),
                                arr_ok, ar_desc,
                                (arr_ok && ar_desc) ? "S2A-4-WITNESS-OK"
                                  : (arr_ok ? "NOT-GREEN(descriptor-arithmetic-fail)"
                                            : (ar_desc ? "NOT-GREEN(arrival-missing/NOARR-REVERSE-LEG)"
                                                       : "NOT-GREEN(both)")));
                    }
#endif
                    const int is_ok = (rc192 == 0);
                    if (is_ok) g_pts_fsp_pl_resolve_ok++;
                    else if (rc192 == -100002) g_pts_fsp_pl_resolve_exc++;
                    fprintf(stderr, "[FSPARALIST-CONSUME] i=0 h=%p resolve=%s type=%s via=+192-deferred-prev-gen "
                                    "rc=%d consumes=%d\n",
                            prev, is_ok ? "ok" : (rc192 == -100002 ? "exception" : "other"),
                            is_ok ? "BaseParaClient" : "unknown", rc192, g_pts_fsp_pl_consumes);
                }
#if WPF_PTS_FSP_PL_ABA
                /* 🔴 **ABA 反腿**（只在副本）：把**已被回收过**的值拿去解析 ⇒ 槽若已被复用，
                   `IsHandle()` 为真 ⇒ `HandleToObject` 静默返回**另一个对象**、`as BaseParaClient` 还成功
                   ⇒ **rc=0 而对象是错的**（本行即"`resolve=wrong-object` 一票红"的机制证明）。 */
                if (!reason && dp->fsp_pl_cur && !dp->fsp_pl_aba_seen) {
                    const void *stale = dp->fsp_pl_cur;
                    int rc_rel = ((wpf_pts_fn_destroy_paraclient)fp192f)((const void *)dp->p_fsclient, stale);
                    void *fresh = NULL;
                    int  rc_new = ((wpf_pts_fn_create_paraclient)fp176f)((const void *)dp->p_fsclient,
                                                                        dp->drive_nmp, &fresh);
                    dp->fsp_pl_aba_seen = 1; dp->fsp_pl_aba_stale = stale;
                    int rc_stale = ((wpf_pts_fn_destroy_paraclient)fp192f)((const void *)dp->p_fsclient, stale);
                    g_pts_fsp_pl_resolve_wrong++;
                    g_pts_fsp_pl_consumes++;
                    fprintf(stderr, "[FSPARALIST-CONSUME] i=0 h=%p resolve=wrong-object type=resolved-as-other-object "
                                    "via=aba-leg rc=%d released_between=1 stale=%p fresh=%p same_value=%d "
                                    "rc_release=%d rc_recreate=%d\n",
                            stale, rc_stale, stale, fresh, (stale == (const void *)fresh) ? 1 : 0, rc_rel, rc_new);
                    /* ⚠️ **停填**：`fresh` 已被上一步的 `+192(stale)` 连带销毁（槽是同一个）
                       ⇒ 若继续把它填进列表，就是**把死句柄交给消费者**（那是另一条反腿）；
                       本反腿只要"静默错对象"这一条证据 ⇒ 停在这里，并**具名**后续拒绝。 */
                    aba_armed = 1;
                    dp->fsp_pl_cur = NULL;
                    dp->fsp_pl_quota = 0;
                    (void)rc_new;
                }
#endif
                /* ③ 配额到点 ⇒ 换代（当前代挂到 `prev`，**下次调用**才回收）
                   ⏪ `T-A33`：**只在格式窗内**换代 —— 换代后 ④ 会发托管 `+176`；窗外发调必撞
                   `PtsContext` 的 `Invariant.FailFast`（实测 `app_rc=134`）⇒ 窗外**沿用当前代**。 */
                if (!reason && dp->fsp_pl_cur && dp->fsp_pl_quota >= wpf_pts_fsp_pl_gen_size()
                    && wpf_pts_qtp_create_safe(dp)) {
                    dp->fsp_pl_prev = dp->fsp_pl_cur; dp->fsp_pl_cur = NULL; dp->fsp_pl_quota = 0;
                }
                /* ④ 需要新一代 ⇒ 用托管 `+176` **现造**（唯一合法来源，判据 §5-P3）
                   ⏪ `T-A33`：**只在格式窗内**发调 —— 窗外（查询期）发调必撞 `PtsContext` 的
                   `Invariant.FailFast`（实测 `app_rc=134`）⇒ 窗外**具名拒绝**（不发调）。 */
                if (!reason && !dp->fsp_pl_cur) {
                    if (!wpf_pts_qtp_create_safe(dp)) reason = "out-of-window-create-paraclient-refused(PtsContext-null-risk)";
                    else {
                        void *hn = NULL;
                        int rc176 = ((wpf_pts_fn_create_paraclient)fp176f)((const void *)dp->p_fsclient,
                                                                          dp->drive_nmp, &hn);
                        g_pts_fsp_pl_last_rc176 = rc176;
                        if (rc176 == 0 && hn != NULL) {
                            dp->fsp_pl_cur = (const void *)hn; dp->fsp_pl_gen++;
                            dp->fsp_pl_site = "query-frame";
                        } else reason = "create-paraclient-failed";
                    }
                }
                /* ⑤ **真填**（先清零 ⇒ 未初始化内存不许交给上级；**填完才置条数**，判据 §5-P2） */
                if (!reason && dp->fsp_pl_cur) {
                    wpf_pts_fsparadesc *rg = (wpf_pts_fsparadesc *)rgParaDesc;
                    /* ⏪ `t162`（队长 `t163` 指引 ＋ 判据 §4(a)）：`pfspara` 的合法来源＝**本侧自有的
                       "子轨对象"**（本仓范式：句柄＝本对象内字段地址；`FsQueryTrackDetails` 同形）。
                       **不是**自造常量、**不是**伪指针、**不**复用 `nmp` 当占位。 */
                    if (!dp->sub) {
                        dp->sub = wpf_pts_sub_new((const void *)dp->drive_nmp, (const void *)dp->fsp_pl_cur);
                        if (dp->sub) {
                            dp->sub_created_seq = dp->sub->seq;
                            /* ⏪ `T-A12`：把**窗内枚举**的结果（`cParas` 的源）绑进该子轨对象。
                               仅当 `sub_enum_ok==1`（真枚举穷尽）才置 `formatted=1`／`c_paras` ——
                               否则**保持** `formatted=0` ⇒ `FsQuerySubtrackDetails` 仍按**未造型**拒。 */
                            if (dp->sub_enum_ok) {
                                dp->sub->enum_ok   = 1;
                                dp->sub->c_paras   = dp->sub_cparas;
                                dp->sub->formatted = 1;
                                for (int k = 0; k < dp->sub_cparas && k < WPF_PTS_SUB_CHILD_MAX; k++)
                                    dp->sub->children[k] = dp->sub_children[k];
                                /* ⏪ `T-A25`：把**窗内为每个子段建的**本侧对象**过继到 `dp->sub`
                                   （`child_objs[k]` 与 `children[k]` 一一对应）⇒ 托管回问
                                   `FsQuerySubtrackDetails`／`FsQueryTextDetails` 时可按**对象身份**认领。
                                   **所有权转移**：过继后 `d->sub_child_objs[k]=NULL` ⇒ 只由
                                   `wpf_pts_sub_destroy(dp->sub)` 的递归回收（**不双销**）。 */
                                for (int k = 0; k < dp->sub_cparas && k < WPF_PTS_SUB_CHILD_MAX; k++) {
                                    dp->sub->child_objs[k] = dp->sub_child_objs[k];
                                    dp->sub_child_objs[k] = NULL;
                                }
                                dp->sub_child_objs_n = 0;
                            }
                        }
                    } else {
                        dp->sub_reused++;                     /* 跨调用持有 ⇒ 同一个在册对象服务多次填充 */
                    }
                    const void *para_val = wpf_pts_sub_handle(dp->sub);
                    const char *para_src = "native-owned-subtrack";
#if WPF_PTS_FSP_PL_PARA_MADEUP
                    para_val = NULL;                              /* 反腿 E3-①：NULL */
                    para_src = "NULL(E3-1 反腿)";
#endif
#if WPF_PTS_FSP_PL_PARA_WRONGTYPE
                    { static int stack_dummy = 0;                  /* 反腿 E3-②："看似真实则伪"的栈地址 */
                      para_val = (const void *)&stack_dummy;
                      para_src = "stack-addr(E3-2 反腿)"; }
#endif
                    if (para_val == NULL && para_src[0] != 'N') { reason = "no-legal-pfspara-in-this-run"; }
                    else {
                    /* 台账认领（**身份**证据：指针必须等值于某在册对象的字段地址；判据 §5.4） */
                    wpf_pts_subtrack *para_obj = NULL;
                    int claimed = wpf_pts_sub_claim(para_val, &para_obj);
#if WPF_PTS_FSP_PL_PARA_MADEUP
                    g_pts_sub_claim_bad++;                        /* 反腿：NULL 额外记一次拒 */
#endif
                    if (!claimed) {
                        /* 认领失败 ⇒ **拒绝整个填充**（绝不把认不了的值交给列表）⇒ 判红/作废 */
                        reason = "para-claim-failed";
                        fprintf(stderr, "[FSPARALIST-PARA] psub=%p pre=(nil) src=%s claim=0 acc=SKIP "
                                        "claims=%d rejected=%d released=%d ctx=%p form=owned-subtrack "
                                        "seq=%d live=%d created=%d destroyed=%d v=CLAIM-REJECTED\n",
                                para_val, para_src, g_pts_fsp_pl_para_claims, g_pts_fsp_pl_para_rejected,
                                g_pts_fsp_pl_para_released, (void *)dp,
                                dp->sub_created_seq, g_pts_sub_live_n, g_pts_sub_created, g_pts_sub_destroyed);
                    } else {
                    for (int i = 0; i < cParas; i++) {
                        const void *para_pre = (const void *)rg[i].pfspara;
                        memset((void *)&rg[i], 0, sizeof(rg[i]));
                        para_pre = (const void *)rg[i].pfspara;        /* memset 后该槽＝`nil`（成对证据的一半） */
                        rg[i].pfspara       = (void *)para_val;
                        rg[i].pfsparaclient = (void *)dp->fsp_pl_cur;
                        rg[i].nmp           = (void *)dp->drive_nmp;
#if WPF_PTS_FSP_PL_DVR
                        /* ⏪ `t198` (甲)：**描述符字段求真值** —— 值只从 LM-1 段账取（作者性见 `wpf_pts_lm1_led_add`）。
                           🔴 段账条数不足（`led_n < cParas`）⇒ **不写**（保持 `memset` 后的 0）＋具名降级，
                           **绝不**用常数补位；`DVR_NODVR` 反腿**只**打这一对（射程＝宿主 `PtsHelper.cs:177`）。 */
                        if (g_pts_lm1_led_n >= cParas) {
                            const wpf_pts_lm1_led_t *le = &g_pts_lm1_led[i];
                            rg[i].dvr_used      = WPF_PTS_FSP_PL_DVR_NODVR ? 0 : le->dvr_used;
                            rg[i].dvr_top_space = WPF_PTS_FSP_PL_DVR_NODVR ? 0 : le->dvr_top_space;
                            g_pts_lmwit_desc_dvr_used = rg[i].dvr_used;
                            g_pts_lmwit_desc_dvr_top  = rg[i].dvr_top_space;
                            g_pts_lmwit_desc_led_ok   = 1;
                            g_pts_lmwit_desc_src      = WPF_PTS_FSP_PL_DVR_NODVR
                                                      ? "LM1-LEDGER(zeroed-by-DVR_NODVR-reverse-leg)"
                                                      : "LM1-SEGMENT-LEDGER";
                        } else {
                            if (i == 0) g_pts_lm1_led_short++;
                            g_pts_lmwit_desc_led_ok = 0;
                            g_pts_lmwit_desc_src    = "NOINFO(lm1-ledger-short:led_n<cParas)";
                        }
#endif
                        /* 🔴 **下游接受者：本件无**（判据 §5.5 的在册接受者＝ `FsQuerySubtrackDetails`（`:271`）
                           与 `FsQuerySubtrackParaList`（`PtsHelper.cs:633`），二者都属 **(b)**、**尚未实现**）。
                           ⚠️ **实测教训（本件踩到并已修）**：曾拿 `+168 GetParaProperties` 当接受者 —— 它吃的是
                           **托管句柄**（`HandleToObject(nmp) as BaseParagraph`），而本件 `pfspara` 是
                           **本侧自有对象的字段地址（native 指针）** ⇒ 喂它会撞
                           `Assert(handleLong < _unmanagedHandles.Length)` ⇒ **不可捕获 `FailFast`**
                           （实测 `app_rc=134`、`LEG k=24 alive=no`）⇒ 本件**删掉**该调用并具名：
                           `acc=NA(acceptor-is-(b))`。**这正是判据 §7.3／P7 要拦的形态。** */
                        int acc_rc = -12345;   /* -12345 = **未调用**（不在册值，不冒充成功/失败） */
                        if (i == 0) {
                            dp->fsp_para_val = para_val; dp->fsp_para_src = para_src;
                            dp->fsp_para_acc_rc = acc_rc;
                            if (claimed) { dp->fsp_para_claims++; g_pts_fsp_pl_para_claims++; }
                            else         { dp->fsp_para_rejected++; g_pts_fsp_pl_para_rejected++; }
                            if (acc_rc == 0) { g_pts_fsp_pl_para_acc_ok++; }
                            else             { g_pts_fsp_pl_para_acc_bad++; }
                            /* 跨调用持有：本 doc 已有认领值且本次仍被接受 ⇒ 持有期成立 */
                            if (claimed && acc_rc == 0 && dp->fsp_para_claims > 1) {
                                dp->fsp_para_hold_ok = 1; g_pts_fsp_pl_para_hold_ok = 1;
                            }
                            g_pts_fsp_pl_para_last = para_val; g_pts_fsp_pl_para_last_src = para_src;
                            fprintf(stderr, "[FSPARALIST-PARA] psub=%p pre=%p src=%s same_value=%d acc=%d "
                                            "claims=%d rejected=%d hold=%d released=%d ctx=%p para_src_row=%s "
                                            "off_pfspara=%d form=native-owned-subtrack seq=%d live=%d "
                                            "created=%d destroyed=%d formatted=%d reused=%d v=%s\n",
                                    para_val, para_pre, para_src, claimed, acc_rc,
                                    g_pts_fsp_pl_para_claims, g_pts_fsp_pl_para_rejected,
                                    g_pts_fsp_pl_para_hold_ok, g_pts_fsp_pl_para_released,
                                    (void *)dp, (dp->drive_nmp ? "DRIVE-PROBE2.nmp1/DRIVE-PROBE3.nmp176" : "none"),
                                    (int)offsetof(wpf_pts_fsparadesc, pfspara), dp->sub_created_seq,
                                    g_pts_sub_live_n, g_pts_sub_created, g_pts_sub_destroyed,
                                    dp->sub ? dp->sub->formatted : -1, dp->sub_reused,
                                    (acc_rc == 0) ? "PARA-ACCEPTED" : "ACCEPT-OTHER");
                        }
                    }
                    *cParaDesc = cParas;                       /* ← **只在真填完成后**置（P2） */
                    /* ⏪ `T-A41` `D0`：页轨枚举 ＝ **新一轮**的起手 —— 先给上一轮贴标签（`via=`），再开新轮。
                       （本行**只读**：不改 `cParas`／`rg[]`／任何出参一个字节。） */
                    wpf_pts_qvp_end("next-page-track-enum");
                    wpf_pts_qvp_begin();
                    g_pts_fsp_pl_fills++;
                    dp->fsp_pl_quota++;
                    g_pts_fsp_pl_last_h = dp->fsp_pl_cur;
                    const unsigned char *bp = (const unsigned char *)&rg[0];
                    char dump[3 * 32 + 1];
                    for (int i = 0; i < 32; i++) snprintf(dump + i * 3, 4, "%02x ", bp[i]);
                    fprintf(stderr, "[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=%d n=%d "
                                    "h0=%p src=managed-176 run=site=%s win=%s gen=%d quad=%d hold=%d "
                                    "off16=%d bytes0_32=%s ok=%d gap=%d cur_tid=%lu win_tid=%lu\n",
                            cParas, cParas, (void *)dp->fsp_pl_cur, dp->fsp_pl_site,
                            wpf_pts_fsp_pl_win_out() ? "out" : "in", dp->fsp_pl_gen, dp->fsp_pl_quota,
                            (dp->fsp_pl_prev != NULL) ? 1 : 0, (int)offsetof(wpf_pts_fsparadesc, pfsparaclient),
                            dump, g_pts_fsp_pl_ok + 1, g_pts_fsp_pl_gap,
                            (unsigned long)pthread_self(), dp->win_tid);
                    g_pts_fsp_pl_ok++;
#if WPF_PTS_FSP_PL_LMWIT || WPF_PTS_FSP_PL_DVR
                    {   /* ⏪ `t198`：**每次成功填充必打的到达读数行**（`t196` §6：禁静默阈值）
                           —— 没有它，"回收没发生(0)"与"行没打(=没取到)"不可分（`t194` 的自伤形态）。 */
#if WPF_PTS_FSP_PL_DVR
                        const int led_n = g_pts_lm1_led_n;
#else
                        const int led_n = -1;   /* -1 = 本副本未编入 (甲) 腿 */
#endif
                        const int arr_ok = (g_pts_fsp_pl_consumes > 0 && g_pts_fsp_pl_resolve_ok > 0);
                        const int d_desc = g_pts_lmwit_desc_dvr_used - g_pts_lmwit_desc_dvr_top;
                        const int ar_desc = (g_pts_lmwit_desc_led_ok && d_desc > 0);
                        fprintf(stderr, "[LMWIT-ARRIVAL] port=counting-entry fills=%d consumes=%d resolve_ok=%d "
                                        "gen=%d quota=%d gen_size_knob=%d declared=%d led_n=%d "
                                        "desc_dvr_used=%d desc_dvr_top_space=%d desc_dv=%d desc_src=%s "
                                        "arrival_ok=%d arith_descriptor_ok=%d joint=%s "
                                        "granularity=single-call+counting-port v=%s\n",
                                g_pts_fsp_pl_fills, g_pts_fsp_pl_consumes, g_pts_fsp_pl_resolve_ok,
                                dp->fsp_pl_gen, dp->fsp_pl_quota,
                                wpf_pts_fsp_pl_gen_size(), wpf_pts_fsp_pl_gen_declared(), led_n,
                                g_pts_lmwit_desc_dvr_used, g_pts_lmwit_desc_dvr_top, d_desc,
                                g_pts_lmwit_desc_src, arr_ok, ar_desc,
                                (arr_ok && ar_desc) ? "S2A-4-WITNESS-OK" : "NOT-GREEN",
                                (arr_ok && ar_desc) ? "S2A-4-WITNESS-OK(single-call+counting-port)"
                                                    : "NOT-GREEN(see arrival_ok/arith_descriptor_ok)");
                    }
#endif
                    }   /* ← 收 `claimed` 的 else 块（t162） */
                    }   /* ← 收 `para_val != NULL` 的 else 块（t162） */
#if WPF_PTS_FSP_PL_SELFRECYCLE
                    /* 🔴 **P4 反腿**（只在副本）：**返回前回收** ⇒ 交给消费者的句柄**到手就是死的** */
                    {
                        int rcBad = ((wpf_pts_fn_destroy_paraclient)fp192f)((const void *)dp->p_fsclient,
                                                                           dp->fsp_pl_cur);
                        fprintf(stderr, "[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=%d "
                                        "n=%d h0=%p src=managed-176-recycled-before-return reuse_of_freed_index=1 "
                                        "recycle_rc=%d ok=%d gap=%d\n",
                                cParas, cParas, (void *)dp->fsp_pl_cur, rcBad, g_pts_fsp_pl_ok, g_pts_fsp_pl_gap);
                    }
                    dp->fsp_pl_cur = NULL; dp->fsp_pl_quota = 0;
#endif
                    fsp_filled = 1;
                }
            }
        }
#if WPF_PTS_FSP_PL_LMWIT || WPF_PTS_FSP_PL_DVR
        if (!fsp_filled) {
            /* ⏪ `t198`：**具名缺省行**（`t196` §6 / `t195` W-2①：禁静默阈值）——
               「没取到」＝本行（`NOINFO(reason=…)`）；「真发生 0 次」＝填充行里的 `consumes=0`。
               两者形态**可区分**，不再靠"行没打"去回显推断。 */
#if WPF_PTS_FSP_PL_DVR
            const int led_n0 = g_pts_lm1_led_n;
#else
            const int led_n0 = -1;             /* -1 ＝ 本副本未编入 (甲) 腿 */
#endif
            fprintf(stderr, "[LMWIT-ARRIVAL] port=counting-entry fills=%d consumes=NOINFO(reason=%s) "
                            "resolve_ok=NOINFO(reason=%s) gen_size_knob=%d declared=%d led_n=%d "
                            "desc_dvr_used=%d desc_dvr_top_space=%d desc_dv=%d desc_src=%s arrival_ok=0 "
                            "arith_descriptor_ok=%d joint=NOT-GREEN granularity=single-call+counting-port "
                            "v=NOINFO(no-fill-in-this-leg)\n",
                    g_pts_fsp_pl_fills, reason ? reason : "unknown", reason ? reason : "unknown",
                    wpf_pts_fsp_pl_gen_size(), wpf_pts_fsp_pl_gen_declared(), led_n0,
                    g_pts_lmwit_desc_dvr_used, g_pts_lmwit_desc_dvr_top,
                    g_pts_lmwit_desc_dvr_used - g_pts_lmwit_desc_dvr_top, g_pts_lmwit_desc_src,
                    (g_pts_lmwit_desc_led_ok
                     && (g_pts_lmwit_desc_dvr_used - g_pts_lmwit_desc_dvr_top) > 0) ? 1 : 0);
        }
#endif
        if (fsp_filled) return 0;              /* **只有真填后才返 0**（判据 §5-P1） */
        if (!reason) reason = "paraclient-table-not-native";   /* 旧路径逐字保留 */
    }
    g_pts_fsp_pl_gap++;
    {   /* ⏪ `T-A33`：**跨线程判据**的现取读数（`cur_tid` vs 格式窗 `win_tid`；只读，不改行为）。 */
        const wpf_pts_doc *dptid = wpf_pts_doc_ptr(pfscontext);
        fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTrackParaList ctx=%p track=%p cParas=%d "
                        "owned=%d ok=%d gap=%d cur_tid=%lu win_tid=%lu\n",
                WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pTrack, cParas,
                wpf_pts_track_owned(pTrack), g_pts_fsp_pl_ok, g_pts_fsp_pl_gap,
                (unsigned long)pthread_self(), dptid ? dptid->win_tid : 0ul);
    }
    return WPF_PTS_ERR_NOT_IMPLEMENTED;                  /* ← 本步**永不**返 0（返 0 ＝ 假成功） */
}

// ── 本增量靶心：`FsQuerySubtrackDetails`（声明 `Pts.cs:3735-3739`；调用点 `ContainerParaClient.cs` 9 处 ＋ `ListParaClient.cs` 1 处）──
//   签名：`int FsQuerySubtrackDetails(IntPtr pfsContext, IntPtr pSubTrack, out FSSUBTRACKDETAILS pSubTrackDetails);`
//   出参结构 `FSSUBTRACKDETAILS { FSUPDATEINFO fsupdinf; IntPtr nms; FSRECT fsrc; int cParas; }`（`Pts.cs:1527-1533`）。
//   🔴 **`T-A12` 现取更新（`cParas` 的源现已成立）**：窗内 `wpf_pts_sub_enum`（`+136`／`+144`）
//      真枚举了子轨段落的子段 ⇒ `FSPARALIST` 交给消费者的那个**本侧自有子轨对象**带上了
//      `c_paras`／`formatted`（＝**枚举计数**，非托管真值直传、亦非常数）。⇒ 本入口新增**成功分支**：
//      当 `pSubTrack` 认领成功 ∧ `obj->formatted ∧ obj->enum_ok` ⇒ 写 `pSubTrackDetails` 并返 **0**。
//      `cParas` 的**来源证据**＝同趟 `[SUBENUM] … cparas=N ok=1 v=ENUM-OK`（计数只来自回调真返回）。
//   🔴 **仍不许假成功**（`T-A11` 判据 §4-D1／D2）：① 未认领／未造型／未枚举 ⇒ **返非 0 ＋ 留痕 ＋
//      出参一字不写**；② **禁**写 `cParas=0` 让 `rc=0` 好看（`ContainerParaClient.cs:277` 叶子支、
//      静默丢整棵嵌套）；③ `fsupdinf` **无源** ⇒ 固定 `fskupdInherited/0` 并具名 `NOINFO`；
//      `nms`＝透传（`drive_nmseg`）；`fsrc`＝本侧声明几何（具名 `NOINFO-FSGEOMETRY-LAYOUT`）。
//   🔴 **入参按对象身份认领**（判据 §4-D4）：`pSubTrack` 必须能被 `wpf_pts_sub_claim` **唯一认领**
//      （＝本侧自有子轨对象内 `c_paras` 字段的地址，承 `FsQueryTrackDetails` 范式）；NULL／栈地址／
//      外来值**必被拒** ⇒ 身份**只许靠来源证据**，不许靠 `rc`／数值大小。
//   🔴 **闸关与闸开分开报**（判据 §4-D5，`P13` 反腿）：显式 `WPF_PTS_DRIVE_PROBE=0` ⇒ 链不驱、
//      `pSubTrack==NULL` ⇒ `reason=null-subtrack`；缺省（链驱）⇒ 认领成功且已枚举。**两路判词不同**。
typedef struct {                              /* FSSUBTRACKDETAILS 镜像（**只用于尺寸/偏移自证**；不 deref 托管结构） */
    int   fskupd;        /* FSUPDATEINFO.fskupd（FSKUPDATGE : int）        @ +0  */
    int   dvr_shifted;   /* FSUPDATEINFO.dvrShifted                        @ +4  */
    void *nms;           /* nms                                            @ +8  */
    int   u, v, du, dv;  /* FSRECT{u,v,du,dv}                              @ +16 */
    int   c_paras;       /* cParas                                         @ +32 */
} wpf_pts_fssubtrackdetails;
_Static_assert(sizeof(wpf_pts_fssubtrackdetails) == 40, "sizeof(FSSUBTRACKDETAILS) != 40");
_Static_assert(offsetof(wpf_pts_fssubtrackdetails, nms)     ==  8, "FSSUBTRACKDETAILS.nms 偏移 != +8");
_Static_assert(offsetof(wpf_pts_fssubtrackdetails, u)       == 16, "FSSUBTRACKDETAILS.fsrc 偏移 != +16");
_Static_assert(offsetof(wpf_pts_fssubtrackdetails, c_paras) == 32, "FSSUBTRACKDETAILS.cParas 偏移 != +32");
static int g_pts_fsqstd_calls       = 0;   /* 进入次数（含重复；判据 §4-D5 的 `calls=`） */
static int g_pts_fsqstd_ok          = 0;   /* 成功（`rc=0`）次数 —— `T-A12` 起仅当**认领 ∧ 已枚举** */
static int g_pts_fsqstd_gap         = 0;   /* 返非 0 次数（判据 §4-D3 的 `gap=`） */
static int g_pts_fsqstd_null        = 0;   /* 路①：`pSubTrack==NULL`（闸关路径）被拒次数 */
static int g_pts_fsqstd_unclaim     = 0;   /* 路②：认领失败（NULL／栈地址／外来值）次数 */
static int g_pts_fsqstd_unformatted = 0;   /* 路③：认领成功但**未枚举／未造型**次数 */
static int g_pts_fsqstd_nullout     = 0;   /* 路④：已枚举但 `pSubTrackDetails==NULL` 被拒次数 */
/* ⏪ `T-A22`（`N1`）：**按来源证据认领成功**的次数（身份成立，但该段**自己的子段序**本波无源
   ⇒ 仍拒、出参一字不写）。与 `ok`（本侧自有子轨对象的成功分支）**分开计**，判词也不同。 */
static int g_pts_fsqstd_provclaimed = 0;
static const char *g_pts_fsqstd_last_reason = "none";   /* 最后一次判词 token（可独立读取） */
/* ⚠️ **反腿开关**（默认 0）：**只在副本**以 `-DWPF_PTS_SUB_CPARAS_FAKE=<n>` 单独编译，**绝不进主链**。
   `0`＝真值（枚举计数）｜`1`＝写**恒定 999**（伪真值）⇒ `FsQuerySubtrackParaList` 必 `cparas-mismatch`
   （下游 `HandleToObject(0)` ⇒ `PtsException`，**不许静默通过**）｜`2`＝写 **0** ⇒ 消费者
   `ContainerParaClient.cs:66` 走**叶子支**、**静默丢整棵嵌套**（`P8` 必红；本侧以 `true_cParas=` 留痕）。 */
#ifndef WPF_PTS_SUB_CPARAS_FAKE
#define WPF_PTS_SUB_CPARAS_FAKE 0
#endif
//   【本入口＝**查询**，无配对销毁入口；导出即改生成件 `bin/exports.txt`（同趟逐名对拍零消失）。】
int FsQuerySubtrackDetails(void *pfscontext, void *pSubTrack, void *pSubTrackDetails)
{
    g_pts_fsqstd_calls++;
    { int _i = wpf_pts_index("FsQuerySubtrackDetails"); if (_i >= 0) g_pts_seen[_i]++; }
    g_pts_qpd_prev_page = NULL;   /* `T-A15`：下游入口 ⇒ 断开"查询组" */
    const char *reason = NULL;
    wpf_pts_subtrack *obj = NULL;
    wpf_pts_doc *dpx = wpf_pts_doc_ptr(pfscontext);
    wpf_pts_prov *pev = NULL;                     /* ⏪ `T-A22`：来源证据认领结果 */
    if (!pSubTrack)                               { reason = "null-subtrack";           g_pts_fsqstd_null++; }
    else if (!wpf_pts_sub_claim(pSubTrack, &obj)) {
        /* ⏪ `T-A22`（`N1`）：本侧自有对象**认不出** ⇒ **追加**「**按来源证据认领 ＋ 对象身份核验**」：
           `pSubTrack` 须等值于**本 run 由 `+136`／`+144` 交回、并经本侧写进 `FSPARADESCRIPTION.pfspara`
           的那个托管段句柄**（通道 `'S'`），且该证据的 `doc` **就是**本次 `pfscontext`（指针等值）、
           `gen` 就是本会话。**认出** ⇒ 判词**分立**为 `claimed-by-provenance-no-content-model`：
            身份**成立**，但该段**自己的子段序**（内容模型）本波**无源**（窗内只枚举了顶层 container）
            ⇒ 仍**拒**、出参一字不写（**永不假成功**，判据 D1／D2）。
           同值证据里存在异 doc／异通道／旧会话者 ⇒ 判 `WRONG-OBJECT`／`ABA`／`STALE-GEN` ⇒ **拒**。 */
        if (wpf_pts_prov_claim(pSubTrack, dpx, 'S', &pev)) {
            reason = "claimed-by-provenance-no-content-model";
            g_pts_fsqstd_provclaimed++;
            fprintf(stderr, "[PROVCLAIM] entry=FsQuerySubtrackDetails p=%p claim=prov doc=%p ev_seq=%d "
                            "channel=S(+136/+144 段句柄) src=%s ord=%d gen=%d written_out=%d "
                            "claims_ok=%d wrong_object=%d aba=%d stale=%d zero_ev=%d "
                            "out=UNWRITTEN bytes=0 v=CLAIMED-NO-CONTENT-MODEL\n",
                    pSubTrack, (void *)dpx, pev->seq, pev->src, pev->ord, pev->gen, pev->written_out,
                    g_pts_prov_claim_ok, g_pts_prov_wrongobj, g_pts_prov_ababa, g_pts_prov_stale,
                    g_pts_prov_claim_no);
        } else {
            reason = "unclaimable-subtrack";
            fprintf(stderr, "[PROVCLAIM] entry=FsQuerySubtrackDetails p=%p claim=none doc=%p "
                            "claims_ok=%d wrong_object=%d aba=%d stale=%d zero_ev=%d "
                            "v=NO-PROVENANCE-EVIDENCE\n",
                    pSubTrack, (void *)dpx, g_pts_prov_claim_ok, g_pts_prov_wrongobj,
                    g_pts_prov_ababa, g_pts_prov_stale, g_pts_prov_claim_no);
        }
        g_pts_fsqstd_unclaim++;
    }
    else if (!obj->formatted || !obj->enum_ok)    { reason = "no-layout-content-model"; g_pts_fsqstd_unformatted++; }
    else if (!pSubTrackDetails)                   { reason = "null-details-out";        g_pts_fsqstd_nullout++; }
    else {
        /* ── ✅ **成功分支**（`T-A12`）：`cParas` ＝窗内 `+136`／`+144` **真枚举**的计数（来源在
           `[SUBENUM]`）。**先清零再逐字段写**（判据 §4-D1：未初始化内存不许交给上级）。 */
        wpf_pts_fssubtrackdetails *o = (wpf_pts_fssubtrackdetails *)pSubTrackDetails;
        memset((void *)o, 0, sizeof(*o));
        o->fskupd      = 0;                       /* `fskupdInherited`（NOINFO-FSUPDINF-CONSUMER：全树 0 消费者） */
        o->dvr_shifted = 0;                       /* NOINFO-FSUPDINF-SEMANTICS：本侧无更新/位移状态可读 */
        o->nms         = dpx ? (void *)dpx->drive_nmseg : NULL;   /* 透传：同 run `+80` 的 live nmSegment */
        o->u  = 0; o->v = 0;
        o->du = obj->in_subpage ? obj->sp_du : WPF_PTS_FSP_FIN_DU;
        o->dv = obj->in_subpage ? obj->sp_dv : WPF_PTS_FSP_FIN_DV;   /* 内容树 ⇒ 子页声明几何；否则本侧页约定 */
#if WPF_PTS_SUB_CPARAS_FAKE == 1
        int cp_out = 999;                          /* 反腿①：伪真值（恒定） */
#elif WPF_PTS_SUB_CPARAS_FAKE == 2
        int cp_out = 0;                            /* 反腿②：强行 0 ⇒ 消费者叶子支、静默丢嵌套 */
#else
        int cp_out = obj->c_paras;                 /* 主链：**枚举计数**（真值来源） */
#endif
        o->c_paras     = cp_out;                  /* ← **承重格**（`true_cParas=` 给出枚举真值以对拍） */
        g_pts_fsqstd_ok++;
        g_pts_fsqstd_last_reason = "ok";
        fprintf(stderr, "[FSQSTD] rc=0 reason=ok entry=FsQuerySubtrackDetails ctx=%p psub=%p "
                        "calls=%d ok=%d gap=%d null=%d unclaim=%d unformatted=%d out=WRITTEN bytes=40 "
                        "cParas=%d true_cParas=%d nms=%p src=%s\n",
                pfscontext, pSubTrack, g_pts_fsqstd_calls, g_pts_fsqstd_ok, g_pts_fsqstd_gap,
                g_pts_fsqstd_null, g_pts_fsqstd_unclaim, g_pts_fsqstd_unformatted,
                o->c_paras, obj->c_paras, (void *)o->nms, "SUBENUM(+136/+144)");
        fprintf(stderr, "[FSQSTD-SRC] cParas=%d src=subenum(+136/+144) du=%d dv=%d nms=%p "
                        "NOINFO=fsupdinf(no-source),fsrc(declared-geometry)\n",
                o->c_paras, WPF_PTS_FSP_FIN_DU, WPF_PTS_FSP_FIN_DV, (void *)o->nms);
        return 0;
    }
    /* ── 拒绝面（**零假值／出参一字不写**）：`pSubTrackDetails` **绝不触碰**（`T-A11` §4-D1）。 */
    (void)pSubTrackDetails;                  /* 刻意只收不用（机器可读形态：参数在册但零写入） */
    (void)dpx; (void)obj;
    g_pts_fsqstd_gap++;
    g_pts_fsqstd_last_reason = reason;
    fprintf(stderr, "[FSQSTD] rc=%d reason=%s entry=FsQuerySubtrackDetails ctx=%p psub=%p "
                    "calls=%d ok=%d gap=%d null=%d unclaim=%d unformatted=%d nullout=%d out=UNWRITTEN bytes=0\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pSubTrack,
            g_pts_fsqstd_calls, g_pts_fsqstd_ok, g_pts_fsqstd_gap,
            g_pts_fsqstd_null, g_pts_fsqstd_unclaim, g_pts_fsqstd_unformatted, g_pts_fsqstd_nullout);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;      /* ← 无真值时改成 0 就是制造静默半通／伪成功（判据 §4-D2） */
}

// ── `T-A12` 配对入口：`FsQuerySubtrackParaList`（声明 `Pts.cs:3741-3748`；唯一调用点
//    `PtsHelper.cs:633 ParaListFromSubtrack`；调用序见 `ContainerParaClient.cs:70`)──
//   签名：`int FsQuerySubtrackParaList(IntPtr pfsContext, IntPtr pSubTrack, int cParas,
//           FSPARADESCRIPTION* rgParaDesc, out int cParaDesc);`
//   🔴 **为何本波必须有它**：`FsQuerySubtrackDetails` 一返 `cParas>0`，消费者
//      （`ContainerParaClient.cs:66` ⇒ `:70`）就**必**调本入口；若本入口不在产物里 ⇒ P/Invoke
//      抛 `EntryPointNotFoundException`（＝把"缺口"变成"绑定失败"，见本文件件头）⇒ **这是把
//      `cParas` 交出去的必要配对件**（`T-A11` §3 的具名前置之一）。
//   🔴 填法（**唯一合法来源**）：`pfsparaclient` 一律由本 run 托管 `+176` **现造**（跨调用复用，
//      **不**重复造、**不**返回前回收）；`pfspara`／`nmp` ＝**窗内枚举**得到的子段句柄
//      （`obj->children[]`，来源行 `[SUBENUM]`）。`dvrUsed`／`dvrTopSpace`／`bbox` **本侧无几何源**
//      ⇒ 保持 `memset` 后的 **0** ＋ 具名 `NOINFO-SUBTRACK-PARA-GEOMETRY`（**不**自造几何）。
//   🔴 **失败必留痕**：任何拒绝**必**打具名行 ＋ `gap` 恰涨 1；**出参先清 0**。
static int g_pts_fsqspl_calls = 0, g_pts_fsqspl_ok = 0, g_pts_fsqspl_gap = 0;
static int g_pts_fsqspl_cli_made = 0;      /* 累计现造的客户端条数（**只增**） */
int FsQuerySubtrackParaList(void *pfscontext, void *pSubTrack, int cParas,
                            void *rgParaDesc, int *cParaDesc)
{
    const char *reason = NULL;
    g_pts_fsqspl_calls++;
    { int _i = wpf_pts_index("FsQuerySubtrackParaList"); if (_i >= 0) g_pts_seen[_i]++; }
    g_pts_qpd_prev_page = NULL;   /* `T-A15`：下游入口 ⇒ 断开"查询组" */
    if (cParaDesc) *cParaDesc = 0;                     /* 失败：出参先清成 0（不留残留） */
    wpf_pts_subtrack *obj = NULL;
    wpf_pts_doc *dp = wpf_pts_doc_ptr(pfscontext);
    if (!cParaDesc)                                reason = "null-count-out";
    else if (!pSubTrack)                           reason = "null-subtrack";
    else if (!wpf_pts_sub_claim(pSubTrack, &obj))  reason = "unclaimable-subtrack";
    else if (!obj->formatted || !obj->enum_ok)     reason = "no-layout-content-model";
    else if (cParas != obj->c_paras)               reason = "cparas-mismatch";
    else if (cParas > 0 && !rgParaDesc)            reason = "null-paradesc-out";
    else if (!dp)                                  reason = "unknown-ctx";
    else {
        const void *fp176 = wpf_pts_snap_word(dp, WPF_PTS_SNAP_IDX_CREATEPARACLIENT);
        if (!fp176)                        reason = "no-slot-176";
        else if (!wpf_pts_ctx_is_live(dp)) reason = "ctx-not-live";
        /* ⏪ `T-A17`：**句柄 liveness 判据** —— 页销毁后 `obj->children[]`（窗内枚举出的托管段落实例）
           已被托管释放 ⇒ 再调 `+176 CreateParaclient` 必撞 `HandleToObject` 的 `Invariant.Assert`
           ⇒ **拒填**（出参一字不写 ＋ 具名 `reason`；成功路径逐字不变）。
           ⏪ `T-A47`（`QTP-LIVE-NARROW`）：**同一收窄**（与 `FsQueryTrackParaList` 填充支同形、同一 env 闸）。
             🔴 **现取证据（`T-A47` 腿 `~/tA47-work/{fix2,pol2}`）**：仅收窄 `FsQueryTrackParaList` 时，
             残留**换到本条** —— `[FSQSPL] rc=-10000 reason=drive-handles-released(page-destroyed)
             entry=FsQuerySubtrackParaList`（`fix2` 第 2021 行）⇒ 同一 `PtsException`。
             ⚠️ 本条**确实**会发 `+176`（`obj->children[i]` ＝ 托管段句柄）—— 但**只在
             `obj->child_clients_made < cParas` 时**（`for (i = child_clients_made; i < cParas; i++)`）。
             客户端一旦造出即**跨调用复用**（`obj->child_clients[]`；本侧**从不**对它发 `+192`）⇒
             **已造满 ⇒ 本次一个托管句柄都不碰** ⇒ 此时拒填同样**过宽**。
             ⇒ 收窄：`(!drive_handles_live ∧ child_clients_made < cParas)` 才拒（＝"必发 `+176`"）。 */
        else if (WPF_PTS_DRIVEPROBE_OOW_LIVE_GUARD && !dp->drive_handles_live
                 && !(wpf_pts_qtp_live_narrow() && obj->child_clients_made >= cParas))
            reason = "drive-handles-released(page-destroyed)";
        else {
            /* ⏪ `T-A25`：**每个子段必须已有本侧对象**（窗内建树时建 ⇒ 补其缺失）——缺失 ⇒ **拒绝整个填充**
               （**绝不**退回托管段句柄 ⇒ 那正是要消掉的 `unclaimable-*`；也**绝不**伪造指针）。 */
            int missing = 0;
            for (int i = 0; i < cParas && i < WPF_PTS_SUB_CHILD_MAX; i++)
                if (!obj->child_objs[i]) { missing = 1; break; }
            if (missing) reason = "no-child-object";
            else {
            /* 客户端：**只造缺的那些**（跨调用复用 ⇒ 不重复造／不泄漏／不换手） */
            for (int i = obj->child_clients_made; i < cParas; i++) {
                void *h = NULL;
                int rc = ((wpf_pts_fn_create_paraclient)fp176)((const void *)dp->p_fsclient,
                                                               (const void *)obj->children[i], &h);
                if (rc != 0 || h == NULL) { reason = "create-paraclient-failed"; break; }
                obj->child_clients[i] = (const void *)h;
                obj->child_clients_made = i + 1;
                g_pts_fsqspl_cli_made++;
                /* ⏪ `T-A22`（`N1`）：`+176` 交回的**客户端句柄**入册为**来源证据**（通道 `'C'`）——
                   它**与段句柄同值即 ABA**（§2.3 实证）⇒ 通道判据把这两类分开。 */
                wpf_pts_prov_register((const void *)dp, (const void *)h, 'C',
                                      "+176.CreateParaclient@FsQuerySubtrackParaList", i, dp->prov_gen);
            }
            }
        }
    }
    if (!reason) {
        wpf_pts_fsparadesc *rg = (wpf_pts_fsparadesc *)rgParaDesc;
        for (int i = 0; i < cParas; i++) {
            memset((void *)&rg[i], 0, sizeof(rg[i]));  /* 先清零再逐字段写（未初始化内存不交上级） */
            /* ⏪ `T-A25`（`NATIVE-QUERY-PHASE-CONTENT-MODEL`）：`pfspara` 改交回**本侧自有的子段对象**
               （句柄＝该对象内 `c_paras` 字段的地址，承 `FsQueryTrackDetails` 范式）——**不是**托管段句柄。
               托管随后把它当 `_paraHandle` 回问 `FsQuerySubtrackDetails`／`FsQueryTextDetails` 时，
               `wpf_pts_sub_claim` 按**对象身份**认领（改前这里是托管段句柄 `0x4` ⇒ `unclaimable-*`）。 */
            rg[i].pfspara       = (void *)wpf_pts_sub_handle(obj->child_objs[i]);
            rg[i].pfsparaclient = (void *)obj->child_clients[i];  /* 本 run `+176` 真返回 */
            rg[i].nmp           = (void *)obj->children[i];
            /* ⏪ `T-A53`：若该段是本侧表模型的**表段落** ⇒ 在此（**拿得到真客户端句柄**时）补调
               `pfnAutofitTable` —— 托管 `TableParaClient.ValidateVisual` 的
               `Invariant.Assert(CalculatedColumns != null)` 只在**该客户端**的 `_calculatedColumns`
               被置后才成立（窗口内那个 `tclient` 是**另一个实例** ⇒ 对它 Autofit 不生效）。
               **每模型一次**（`autofit_done`）；`rc≠0` ⇒ 具名留痕（不冒充成功）。 */
            {
                wpf_pts_tbl_model *tm = wpf_pts_tbl_find(obj->children[i]);
                if (tm && !tm->autofit_done && obj->child_clients[i]
                    && g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_AUTOFITTABLE]) {
                    int wt = 0;
                    int ra = ((wpf_pts_fn_autofit_table)g_pts_tableobj_cbk[WPF_PTS_TABLEOBJ_IDX_AUTOFITTABLE])(
                        (const void *)dp->p_fsclient, (const void *)obj->child_clients[i],
                        (const void *)obj->children[i], 0u, WPF_PTS_FLOATER_AVAIL_DU, &wt);
                    tm->autofit_done = 1; tm->autofit_rc2 = ra; tm->autofit_width2 = wt;
                    fprintf(stderr, "[FSTABLEOBJ-AUTOFIT] para=%p client=%p rc=%d wtbl=%d v=%s\n",
                            (void *)obj->children[i], (void *)obj->child_clients[i], ra, wt,
                            ra == 0 ? "AUTOFIT-ON-REAL-CLIENT" : "AUTOFIT-FAIL");
                }
            }
            /* ⏪ `T-A37`：**内容子页树**里，段高取该段**真行台账**的 `Σ(ascent+descent)`（否则为 0 ⇒
               零高矩形 ⇒ 内容不可见）；非内容树逐字保持 `0` ＋ 既有 `NOINFO`。 */
            if (obj->in_subpage && obj->child_objs[i] && obj->child_objs[i]->fl_ok) {
                int hh = 0;
                for (int k = 0; k < obj->child_objs[i]->fl_nlines; k++)
                    hh += obj->child_objs[i]->fl_line[k].dvr_ascent + obj->child_objs[i]->fl_line[k].dvr_descent;
                rg[i].dvr_used = hh;
            }
            /* ⏪ `T-A22`（`N1`）：**本侧真把该段句柄交出去过**（写进 `FSPARADESCRIPTION.pfspara`）
               ⇒ 记进来源证据（强化面；托管随后把它当 `_paraHandle` 送回时即可**按来源证据认领**）。 */
            wpf_pts_prov_mark_written((const void *)dp, 'S', (const void *)obj->children[i]);
            /* dvrUsed／dvrTopSpace／bbox／idobj：**本侧无几何源** ⇒ 0（NOINFO-SUBTRACK-PARA-GEOMETRY）*/
        }
        *cParaDesc = cParas;                              /* 只在**真填完后**置（与 cParas 自洽） */
        g_pts_fsqspl_ok++;
        fprintf(stderr, "[FSQSPL] rc=0 reason=ok entry=FsQuerySubtrackParaList ctx=%p psub=%p cParas=%d "
                        "made=%d cli_total=%d src=SUBENUM(+136/+144)+managed-176 calls=%d ok=%d gap=%d "
                        "NOINFO=subtrack-para-geometry(dvrUsed/dvrTopSpace/bbox=0)\n",
                pfscontext, pSubTrack, cParas, obj->child_clients_made, g_pts_fsqspl_cli_made,
                g_pts_fsqspl_calls, g_pts_fsqspl_ok, g_pts_fsqspl_gap);
        return 0;
    }
    g_pts_fsqspl_gap++;
    fprintf(stderr, "[FSQSPL] rc=%d reason=%s entry=FsQuerySubtrackParaList ctx=%p psub=%p cParas=%d "
                    "calls=%d ok=%d gap=%d out=UNWRITTEN\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pSubTrack, cParas,
            g_pts_fsqspl_calls, g_pts_fsqspl_ok, g_pts_fsqspl_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;      /* ← 无真值时改成 0 就是伪成功 */
}

// ── 格 7 夹具（`t123`／P1-W46）：`FsCreatePageBottomless` 的出参绑定 ＋ 失败必清 ＋ **失败必留痕** ──
//   承重点（判据 C5）：**两个句柄不同只是必要条件**；"与这次调用绑定"由**字段读回**承担。
//   ⚠️ 入参 `pfscontext` 必须**真在册**（本实现按指针身份校验）⇒ 夹具先真建一个 doc 上下文。
//   ⚠️ 失败面（判据 C4）：每条失败路径都要断言 **返非 0 ∧ 出参被清 ∧ 结果格＝未达成**；
//      "返非 0 却无痕迹"由 `g_pts_fsp_gap` ＋ `[FS_PAGE_GAP]` 行承担（本夹具断言 **成功路径下 gap 不涨**）。
static int g_pts_selfcheck_f7_fspage(void)
{
    const int nb = g_pts_fsp_live_n;
    const int f7_ok = g_pts_fsp_ok, f7_gap = g_pts_fsp_gap;
    /* 🔴 `t123` 自查抓到的**假绿口**（同 `t103` 格 85 的教训）：本模块**不提供**页销毁入口（非目标）
       ⇒ 本夹具每跑一次真建 2 个页对象 ⇒ 表（`WPF_PTS_FSP_MAX`）会**逐次逼近上限**；
       若在此**静默 `return 1`（"不适用"）**，则表满之后本格**永远绿而不判** = 假绿。
       ⇒ 口径写死：**表满 ⇒ 返 0（红）并点名该格**（这条**不计入**任何"通过"路径）。
       根治办法（另派单）：加一条 `WpfLinuxWin32_PtsFsPageReleaseAll()` 只读口（**只增不改**），
       或把本夹具的两个对象在出口释放 —— 两者都要新增导出，属另一步的体例决定。 */
    if (nb + 2 > WPF_PTS_FSP_MAX) return 0;                       /* 表满 ⇒ **响亮红**，不静默当"不适用" */
    wpf_pts_fsctx_probe s1; memset(&s1, 0, sizeof(s1));
    s1.version = 0x00010001u; s1.fsffi = 0xDEADBEEFu; s1.c_installed_objects = 1;
    void *ctx = NULL;
    if (CreateDocContext(&s1, &ctx) != 0 || ctx == NULL) return 0; /* 真建上下文（本实现的入参前提） */
    void *pg1 = (void *)0x71, *pg2 = (void *)0x72;
    int   r1 = WPF_PTS_FSFMTRBL_NOT_ACHIEVED, r2 = WPF_PTS_FSFMTRBL_NOT_ACHIEVED;
    /* ① 两次独立调用：都成功 ＋ 两个页句柄**互不相等**（只是必要条件） */
    if (FsCreatePageBottomless(ctx, (const void *)0x41, &r1, &pg1) != 0 || pg1 == NULL) { DestroyDocContext(ctx); return 0; }
    if (FsCreatePageBottomless(ctx, (const void *)0x42, &r2, &pg2) != 0 || pg2 == NULL) {
        DestroyDocContext(ctx); return 0;
    }
    if (pg1 == pg2) { DestroyDocContext(ctx); return 0; }
    /* ② **按对象绑定**（真承重格）：页对象上的 `ctx`／`sect`／`result` 逐项与**本次调用**相符 */
    if (((wpf_pts_fsp *)pg1)->magic != WPF_PTS_FSP_MAGIC) { DestroyDocContext(ctx); return 0; }
    if (((wpf_pts_fsp *)pg2)->magic != WPF_PTS_FSP_MAGIC) { DestroyDocContext(ctx); return 0; }
    if (((wpf_pts_fsp *)pg1)->ctx != ctx)   { DestroyDocContext(ctx); return 0; }
    if (((wpf_pts_fsp *)pg2)->ctx != ctx)   { DestroyDocContext(ctx); return 0; }
    if (((wpf_pts_fsp *)pg1)->sect != (const void *)0x41) { DestroyDocContext(ctx); return 0; }
    if (((wpf_pts_fsp *)pg2)->sect != (const void *)0x42) { DestroyDocContext(ctx); return 0; }
    /* ③ 结果格是**本次调用**的结果（不是全局常量）：出参 == 对象上的 `result` */
    if (r1 != ((wpf_pts_fsp *)pg1)->result) { DestroyDocContext(ctx); return 0; }
    if (r2 != ((wpf_pts_fsp *)pg2)->result) { DestroyDocContext(ctx); return 0; }
    /* ④ 观测镜对拍（指针量走**指针域** `ptr0`／`ptr1`；`t97`／`t103` 同口径） */
    {
        const void *p0 = NULL, *p1 = NULL;
        if (WpfLinuxWin32_PtsJmpProbePtr("FsCreatePageBottomless", ctx, &p0, &p1) != 1) { DestroyDocContext(ctx); return 0; }
        if (p0 != pg2) { DestroyDocContext(ctx); return 0; }   /* 镜记的页句柄 == 最后一次真出参 */
        if (p1 != ctx) { DestroyDocContext(ctx); return 0; }   /* 镜记的上下文 == 本次入参 */
    }
    /* ⑤ 拒绝面（每条：**返非 0 ∧ 出参被清 ∧ 结果格＝未达成**） */
    {
        const int snap_live = g_pts_fsp_live_n;
        const int snap_gap  = g_pts_fsp_gap;
        int rr = 0; void *q = (void *)0x5B5B;
        rr = 7;
        if (FsCreatePageBottomless(NULL, (const void *)0x41, &rr, &q) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
        if (q != NULL) { DestroyDocContext(ctx); return 0; }
        if (rr != WPF_PTS_FSFMTRBL_NOT_ACHIEVED) { DestroyDocContext(ctx); return 0; }
        rr = 7; q = (void *)0x5B5B;
        if (FsCreatePageBottomless((void *)0xdeadbeef, (const void *)0x41, &rr, &q) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }   /* **未登记上下文必被拒、不 deref** */
        if (q != NULL || rr != WPF_PTS_FSFMTRBL_NOT_ACHIEVED) { DestroyDocContext(ctx); return 0; }
        rr = 7; q = (void *)0x5B5B;
        if (FsCreatePageBottomless(ctx, (const void *)0x41, &rr, NULL) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }   /* 空出参 ⇒ 不给"写空也算成功" */
        if (rr != WPF_PTS_FSFMTRBL_NOT_ACHIEVED) { DestroyDocContext(ctx); return 0; }
        q = (void *)0x5B5B;
        if (FsCreatePageBottomless(ctx, (const void *)0x41, NULL, &q) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
        if (q != NULL) { DestroyDocContext(ctx); return 0; }
        if (g_pts_fsp_live_n != snap_live) { DestroyDocContext(ctx); return 0; }        /* 被拒路径**不许**留对象 */
        if (g_pts_fsp_gap != snap_gap + 4) { DestroyDocContext(ctx); return 0; }        /* **失败必留痕**：4 条拒绝 ⇒ gap 恰涨 4（C4 的牙） */
    }
    /* ⑥ 收尾：上下文收回；本格的对象由内核在进程结束时回收（本模块**不**提供页销毁入口 = 非目标） */
    if (DestroyDocContext(ctx) != 0) return 0;
    if (g_pts_fsp_live_n != nb + 2) return 0;                       /* 本格真建了 2 个页对象 */
    /* 夹具**回收自己造的两个对象**（本模块**不提供**页销毁入口 = 非目标；这里是**夹具内部**的释放，
       只为让自检**幂等**、不逐次逼近上限）：按 `pg1`／`pg2` 的指针身份从表里摘除后 `free`。 */
    {
        void *want[2]; want[0] = pg1; want[1] = pg2;
        for (int w = 0; w < 2; w++) {
            for (int i = 0; i < g_pts_fsp_live_n; i++) {
                if ((void *)g_pts_fsp_live[i] != want[w]) continue;
                g_pts_fsp_live[i]->magic = 0;
                free(g_pts_fsp_live[i]);
                g_pts_fsp_live[i] = g_pts_fsp_live[--g_pts_fsp_live_n];
                g_pts_fsp_live[g_pts_fsp_live_n] = NULL;
                break;
            }
        }
    }
    if (g_pts_fsp_live_n != nb) return 0;                           /* 回收后回到 base（自检幂等） */
    g_pts_fsp_ok = f7_ok; g_pts_fsp_gap = f7_gap;                   /* 出口复原本格计数 */
    return 1;
}

// ── 格 8 夹具（`t125`／P1-W47）：`FsQueryPageDetails` ＋ `FsDestroyPage` 的成对断言 ──────────
//   承重点：① 查询**按页对象**回读（不同页各读各的，不是全局常量）；② 销毁**真摘表**（活数回退）
//           ＋ 四路拒绝（NULL／未知／**重复**／未知上下文）；③ **失败必留痕**（gap 计数按条涨）。
//   ⚠️ 本夹具**自己真建上下文与页对象**（create 的入参前提），出口**真销毁**它们 ⇒ 幂等。
static int g_pts_selfcheck_f8_destroy(void)
{
    const int nb = g_pts_fsp_live_n;
    const int f8_q = g_pts_fsp_qpd_ok, f8_qg = g_pts_fsp_qpd_gap;
    const int f8_d = g_pts_fsp_des_ok, f8_dg = g_pts_fsp_des_gap;
    if (nb + 2 > WPF_PTS_FSP_MAX) return 0;                        /* 表满 ⇒ **响亮红**（不静默当"不适用"） */
    wpf_pts_fsctx_probe s1; memset(&s1, 0, sizeof(s1));
    s1.version = 0x00010001u; s1.fsffi = 0xDEADBEEFu; s1.c_installed_objects = 1;
    void *ctx = NULL;
    if (CreateDocContext(&s1, &ctx) != 0 || ctx == NULL) return 0;
    void *pg1 = NULL, *pg2 = NULL;
    int   r1 = 7, r2 = 7;
    if (FsCreatePageBottomless(ctx, (const void *)0x51, &r1, &pg1) != 0 || pg1 == NULL) { DestroyDocContext(ctx); return 0; }
    if (FsCreatePageBottomless(ctx, (const void *)0x52, &r2, &pg2) != 0 || pg2 == NULL) { DestroyDocContext(ctx); return 0; }
    if (pg1 == pg2) { DestroyDocContext(ctx); return 0; }
    /* ① 查询：两条独立调用各自成功，且**回读的是各自那个页对象**的几何（不是全局常量）
          —— 两页几何本次相同，所以用"改一个对象的几何再查"来分开两态（**可证伪**） */
    {
        wpf_pts_fspagedetails_head d1, d2;
        memset(&d1, 0, sizeof(d1)); memset(&d2, 0, sizeof(d2));
        if (FsQueryPageDetails(ctx, pg1, &d1) != 0) { DestroyDocContext(ctx); return 0; }
        if (FsQueryPageDetails(ctx, pg2, &d2) != 0) { DestroyDocContext(ctx); return 0; }
        if (d1.fSimple != 1 || d2.fSimple != 1) { DestroyDocContext(ctx); return 0; }
        if (d1.r_du != 768 || d1.r_dv != 576) { DestroyDocContext(ctx); return 0; }
        if (d1.b_defined != 1) { DestroyDocContext(ctx); return 0; }     /* bbox 必须"已定义" */
        /* 改 pg1 的几何 ⇒ 再查 ⇒ **只有它**变 ⇒ 证明"按对象回读"（不是常量、不是单例） */
        ((wpf_pts_fsp *)pg1)->pg_w = 321; ((wpf_pts_fsp *)pg1)->pg_h = 123;
        if (FsQueryPageDetails(ctx, pg1, &d1) != 0) { DestroyDocContext(ctx); return 0; }
        if (FsQueryPageDetails(ctx, pg2, &d2) != 0) { DestroyDocContext(ctx); return 0; }
        if (d1.r_du != 321 || d1.r_dv != 123) { DestroyDocContext(ctx); return 0; }   /* 跟着对象走 */
        if (d2.r_du != 768 || d2.r_dv != 576) { DestroyDocContext(ctx); return 0; }   /* 另一个不受影响 */
        ((wpf_pts_fsp *)pg1)->pg_w = 768; ((wpf_pts_fsp *)pg1)->pg_h = 576;          /* 复原 */
    }
    /* ② 查询的拒绝面（每条：返非 0 ∧ **gap 恰涨**） */
    {
        const int g0 = g_pts_fsp_qpd_gap;
        wpf_pts_fspagedetails_head d;
        memset(&d, 0, sizeof(d));
        if (FsQueryPageDetails(ctx, NULL, &d) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
        if (FsQueryPageDetails(ctx, (void *)0xbad, &d) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
        if (FsQueryPageDetails(ctx, pg1, NULL) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
        if (FsQueryPageDetails((void *)0xdead, pg1, &d) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
        if (g_pts_fsp_qpd_gap != g0 + 4) { DestroyDocContext(ctx); return 0; }         /* **失败必留痕**：4 条 ⇒ 恰涨 4 */
    }
    /* ③ 销毁：真摘表（活数 −1）＋ 四路拒绝 */
    {
        const int live0 = g_pts_fsp_live_n;
        const int g0 = g_pts_fsp_des_gap;
        if (FsDestroyPage(ctx, pg2) != 0) { DestroyDocContext(ctx); return 0; }         /* 真销毁 ⇒ 0 */
        if (g_pts_fsp_live_n != live0 - 1) { DestroyDocContext(ctx); return 0; }        /* 活数真回退 */
        if (FsDestroyPage(ctx, pg2) == 0) { DestroyDocContext(ctx); return 0; }         /* **紧邻重复 ⇒ 必被拒** */
        if (FsDestroyPage(ctx, (void *)0xbad) == 0) { DestroyDocContext(ctx); return 0; }/* 未知 ⇒ 必被拒 */
        if (FsDestroyPage(ctx, NULL) == 0) { DestroyDocContext(ctx); return 0; }         /* NULL ⇒ 必被拒 */
        if (FsDestroyPage((void *)0xdead, pg1) == 0) { DestroyDocContext(ctx); return 0; }/* 未知上下文 ⇒ 必被拒 */
        if (g_pts_fsp_des_gap != g0 + 4) { DestroyDocContext(ctx); return 0; }           /* 4 条被拒 ⇒ 恰涨 4 */
        if (FsDestroyPage(ctx, pg1) != 0) { DestroyDocContext(ctx); return 0; }          /* 收掉第二个 */
        if (g_pts_fsp_live_n != nb) { DestroyDocContext(ctx); return 0; }                /* 回 base（夹具不带泄漏） */
    }
    if (DestroyDocContext(ctx) != 0) return 0;
    g_pts_fsp_qpd_ok = f8_q; g_pts_fsp_qpd_gap = f8_qg;
    g_pts_fsp_des_ok = f8_d; g_pts_fsp_des_gap = f8_dg;                /* 出口复原本格计数 */
    return 1;
}

// ── 格 9 夹具（`t127`／裁定二十七）：**字段级诚实性**（一对反腿）＋ 两条入口 ────────────────
//   承重：① 我们交出的 `pfstrack` **可身份校验**（`wpf_pts_track_owned` 为真 ⇒ 它是**我们对象内**
//        那个字段的地址）**且非空**；② `FsQueryTrackDetails` 按**对象**答 `cParas`（改一个对象的
//        段数 ⇒ 只有它变）；③ 两条入口的拒绝面**每条都让 gap 恰涨**（失败必留痕）。
//   🔴 **裁定二十七 的反腿一对（本夹具同时承载）**：
//     **a) 交 `NULL`** ⇒ 必红并点名（`FsQueryTrackDetails(NULL 轨)` 必被拒 ＋ `owned==0`）；
//     **b) 交"看似真、实则伪"的句柄**（示例用**栈上局部变量地址**）⇒ **必须也红**：
//        `owned==0`（它不在我们表里）＋ `FsQueryTrackDetails` 必拒它。
//     ⇒ 两条**共用同一个谓词** `wpf_pts_track_owned()`（族属见该助手的注释：与"不许静默 stub"同族）。
static int g_pts_selfcheck_f9_track(void)
{
    const int nb = g_pts_fsp_live_n;
    const int f9_t = g_pts_fsp_trk_ok, f9_tg = g_pts_fsp_trk_gap;
    const int f9_f = g_pts_fsp_fin_ok, f9_fg = g_pts_fsp_fin_gap;
    if (nb + 2 > WPF_PTS_FSP_MAX) return 0;                     /* 表满 ⇒ **响亮红**，不静默当"不适用" */
    wpf_pts_fsctx_probe sc; memset(&sc, 0, sizeof(sc));
    sc.version = 0x00010001u; sc.fsffi = 0xDEADBEEFu; sc.c_installed_objects = 1;
    void *ctx = NULL;
    if (CreateDocContext(&sc, &ctx) != 0 || ctx == NULL) return 0;
    /* ① `FsCreatePageFinite`：成功 ＋ 三个出参都**非空/确定**，且断页记录句柄**可身份校验** */
    void *pfa = NULL, *bra = NULL; int fmt[3] = { 9, 9, 9 };
    if (FsCreatePageFinite(ctx, NULL, (const void *)0x61, fmt, &pfa, &bra) != 0) { DestroyDocContext(ctx); return 0; }
    if (pfa == NULL || bra == NULL) { DestroyDocContext(ctx); return 0; }
    if (!wpf_pts_track_owned(bra)) { DestroyDocContext(ctx); return 0; }   /* **断页记录句柄也得是我们自己的** */
    /* ② `FsQueryPageDetails`：`td_pfstrack` **非空** 且 **可身份校验**（**这就是 `t125` 缺的那一格**） */
    {
        wpf_pts_fspagedetails_head d;
        memset(&d, 0, sizeof(d));
        if (FsQueryPageDetails(ctx, pfa, &d) != 0) { DestroyDocContext(ctx); return 0; }
        if (d.td_pfstrack == NULL) { DestroyDocContext(ctx); return 0; }            /* ← `t125` 那手**必红**在这条 */
        if (!wpf_pts_track_owned(d.td_pfstrack)) { DestroyDocContext(ctx); return 0; }
        /* ③ `FsQueryTrackDetails`：按**对象**答段数（改对象 ⇒ 只有它变） */
        int cp = -1;
        if (FsQueryTrackDetails(ctx, d.td_pfstrack, &cp) != 0) { DestroyDocContext(ctx); return 0; }
        if (cp != ((wpf_pts_fsp *)pfa)->c_paras) { DestroyDocContext(ctx); return 0; }
        ((wpf_pts_fsp *)pfa)->c_paras = 7;
        cp = -1;
        if (FsQueryTrackDetails(ctx, d.td_pfstrack, &cp) != 0 || cp != 7) { DestroyDocContext(ctx); return 0; }
        ((wpf_pts_fsp *)pfa)->c_paras = 1;
        /* ④ **反腿 a：交 `NULL`** ⇒ 必被拒 ＋ `owned==0`（**点名**） */
        {
            int c0 = 5; const int g0 = g_pts_fsp_trk_gap;
            if (wpf_pts_track_owned(NULL) != 0) { DestroyDocContext(ctx); return 0; }
            if (FsQueryTrackDetails(ctx, NULL, &c0) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
            if (c0 != 0) { DestroyDocContext(ctx); return 0; }
            /* ⑤ **反腿 b：看似真、实则伪**（栈上局部变量地址）⇒ `owned==0` 且必被拒 */
            {
                int fake_paras = 3; void *fake = (void *)&fake_paras;
                if (wpf_pts_track_owned(fake) != 0) { DestroyDocContext(ctx); return 0; }
                if (FsQueryTrackDetails(ctx, fake, &c0) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
                if (c0 != 0) { DestroyDocContext(ctx); return 0; }
            }
            if (FsQueryTrackDetails(ctx, d.td_pfstrack, NULL) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
            if (FsQueryTrackDetails((void *)0xdead, d.td_pfstrack, &c0) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
            if (g_pts_fsp_trk_gap != g0 + 4) { DestroyDocContext(ctx); return 0; }   /* **失败必留痕**：4 条 ⇒ 恰涨 4 */
        }
        /* ⑥ `FsCreatePageFinite` 的拒绝面（NULL 出参／NULL 上下文／未知上下文 ⇒ 各涨 1）
              ⚠️ `t127` 自检抓到的坑：这些拒绝调用**必须用一次性局部出参**，**不许**复用 `pfa`／`bra`
              —— 复用会把要收尾的那个真页句柄**覆盖成 NULL**，于是出口的 `FsDestroyPage` 变成
              "销毁 NULL" ⇒ 对象漏在表里（实测：`live` 每跑 +1、`FsDestroyPage` 成功数恒 0）。 */
        {
            const int g0 = g_pts_fsp_fin_gap;
            void *pt = (void *)0x71, *bt = (void *)0x72;
            if (FsCreatePageFinite(ctx, NULL, (const void *)0x62, NULL, &pt, &bt) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
            pt = (void *)0x71; bt = (void *)0x72;
            if (FsCreatePageFinite(NULL, NULL, (const void *)0x62, fmt, &pt, &bt) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
            if (pt != NULL || bt != NULL) { DestroyDocContext(ctx); return 0; }   /* 失败 ⇒ 三个出参**全清** */
            pt = (void *)0x71; bt = (void *)0x72;
            if (FsCreatePageFinite((void *)0xdead, NULL, (const void *)0x62, fmt, &pt, &bt) != WPF_PTS_ERR_NOT_IMPLEMENTED) { DestroyDocContext(ctx); return 0; }
            if (g_pts_fsp_fin_gap != g0 + 3) { DestroyDocContext(ctx); return 0; }
        }
    }
    /* ⑦ 收尾：**真销毁**本夹具建的页对象（`FsDestroyPage`）⇒ 活数回 base（幂等、不逼近上限） */
    if (g_pts_fsp_live_n != nb + 1) { DestroyDocContext(ctx); return 0; }
    if (FsDestroyPage(ctx, pfa) != 0) { DestroyDocContext(ctx); return 0; }
    if (g_pts_fsp_live_n != nb) { DestroyDocContext(ctx); return 0; }
    if (DestroyDocContext(ctx) != 0) return 0;
    g_pts_fsp_trk_ok = f9_t; g_pts_fsp_trk_gap = f9_tg;
    g_pts_fsp_fin_ok = f9_f; g_pts_fsp_fin_gap = f9_fg;
    return 1;
}

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
    /* ⏪ `t110`：格 6（`CreateDocContext`／`DestroyDocContext`）计数**同办** —— 自检链上真的建/毁
       doc 上下文 ⇒ 不 save/restore 就会让"自检不许改变可观测状态"对新面变成假话（`t102` 的 `F-2` 同形）。 */
    int save_doc_c_sets = g_pts_doc_sets_c, save_doc_c_rej = g_pts_doc_rejected_c;
    /* ⏪ `t110`：长度纪律的**净基线**必须在**动任何计数器之前**现取（下面那条 `rc = 34` 用它）。
       为什么：链会真的打到若干入口 ⇒ 中途那份报告的 `anchor=`／`frontier=`／`calls=0:…` 都变长，
       量出来的是**链的污染**而不是**格式的长度**（本趟实测：净 328 B vs 链中途 374 B）。 */
    char rep_probe[512];
    int  rep_clean_len = WpfLinuxWin32_PtsGapReport(rep_probe, (int)sizeof(rep_probe));
    int save_doc_des = g_pts_doc_destroys, save_doc_desrej = g_pts_doc_destroy_rej;
    /* ⏪ `t123`：格 7（`FsCreatePageBottomless`）的成败计数同办 —— 自检真调它 ⇒ 不 save/restore 就会让
       "自检不许改变可观测状态"对新面变成假话（`t102` 的 `F-2` 同形）。 */
    int save_fsp_ok = g_pts_fsp_ok, save_fsp_gap = g_pts_fsp_gap, save_fsp_rej = g_pts_fsp_rej;
    int save_fsp_q = g_pts_fsp_qpd_ok, save_fsp_qg = g_pts_fsp_qpd_gap;
    /* ⏪ `T-A15`：`FsQueryPageDetails` 新增的语义面计数（`New`／`NoChange`／`[VIS]` 见证）同办
       —— 格 8 夹具真调 `FsQueryPageDetails` ⇒ 不复原就会让"自检不许改变可观测状态"对新面变成假话。*/
    int save_fsp_qpd_new = g_pts_fsp_qpd_new, save_fsp_qpd_nc = g_pts_fsp_qpd_nc;
    int save_fsp_vis = g_pts_fsp_vis_ok;
    int save_fsp_d = g_pts_fsp_des_ok, save_fsp_dg = g_pts_fsp_des_gap;
    int save_fsp_t = g_pts_fsp_trk_ok, save_fsp_tg = g_pts_fsp_trk_gap;
    int save_fsp_f = g_pts_fsp_fin_ok, save_fsp_fg = g_pts_fsp_fin_gap;
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

    char sb[512] = { 0 }, sp[512] = { 0 };
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
    /* ⏪ `t110`／P1-W35（W8 第四步）：`CreateDocContext` 已由**诚实缺口 stub** 变成**真实现**
          ⇒ 原来"必须返 -10000 且出参清空"那两条断言**必须跟着改**（不改就是自检恒红），
          且**不是**删掉：改成本格真调用的**成对断言**（真形／`NULL` 入参被拒），
          深度对拍（字段读回／按对象绑定／两次不同）交给**格 `86`** 的夹具。 */
    else if (CreateDocContext(sb, &p2) != 0) rc = 4;                                   /* 真实现 ⇒ **必须成功** */
    else if (p2 == NULL) rc = 5;                                                       /* 真句柄：非空（**非**"写空也算成功"） */
    else if (((wpf_pts_doc *)p2)->magic != WPF_PTS_DOC_MAGIC) rc = 31;                 /* 出参确实是**本模块的**对象 */
    else if (((wpf_pts_doc *)p2)->info_addr != (const void *)sb) rc = 32;              /* 且与**本次入参**绑定 */
    /* ⚠️ 下面两条 `rc=17`／`18` 与格 1 那对**同号**：这是**既有形制**（格号 17／18 在前后两块里各指"重复必被拒"／"未知必被拒"），
         不是本步新引入的撞号；两块的判词由各自的分支位置区分（纪律第 `30` 条：**旧号一个不动**）。
       🔴 **`t110` 实测到的次序坑（必须留档）**：`DestroyDocContext` 成功时用**换位删除**
         （`live[i] = live[--live_n]`）⇒ **紧接着再销毁同一个句柄**才算"重复"；若中间先销毁**别的**句柄，
         换位会把这个已销毁的槽位**覆盖掉** ⇒ 第二次调用退化成"**未知**句柄"⇒ 那条"重复必被拒"的
         断言就**不是在测重复**（本趟 `diag=18` 的真因）。⇒ 次序写死：**先真销毁 ⇒ 立刻重复 ⇒ 再未知**。 */
    else if (DestroyDocContext(p2) != 0) rc = 29;
    else if (WpfLinuxWin32_PtsDocLive() != 0) rc = 30;   /* 真销毁后活数回 0（自检不带 doc 泄漏） */
    else if (DestroyDocContext(p2) == 0) rc = 18;                                       /* **紧邻重复 ⇒ 必被拒** */
    else if (DestroyDocContext((void *)0xdead) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 17; /* **未知句柄必被拒（不 deref）** */
    else if (CreateDocContext(NULL, &p2) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 35;       /* `NULL` 入参必被拒 */
    else if (p2 != NULL) rc = 36;                                                       /*   且出参清空（不许留残留） */
    else if (CreateDocContext(sb, NULL) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 37;        /* 空出参必被拒（不许"写空也算成功"） */
    /* ⏪ `T-A52`：`GetFloaterHandlerInfo` 已由**具名缺口 stub** 升为**真实现**
          ⇒ 旧断言（`GetFloaterHandlerInfo(sb, sp)` 必须返 `-10000`）**必须跟着改**
          （不改就是自检恒红），且**不是**把断言删掉：改成**成对断言**——
          `NULL` init 必被拒（返 `-10000`）／有效 init、空 out ⇒ 真实现**必须成功**（返 0）。
          ⚠️ `sb`／`sp` 同趟由 64 B 加到 256 B：真实现按契约读 `FSFLOATERINIT`（16×8＝128 B）
          ⇒ 旧 64 B 夹具上那次调用**越界**（本步顺手堵掉）。 */
    else if (GetFloaterHandlerInfo(NULL, sp) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 7;
    else if (GetFloaterHandlerInfo(sb, NULL) != 0) rc = 72;
    /* ⏪ `T-A53`：`GetTableObjHandlerInfo` 已由**具名缺口 stub** 升为**真实现** ⇒ 旧断言
          （`GetTableObjHandlerInfo(sb, sp)` 必须返 `-10000`）**必须跟着改**（不改就是自检恒红），
          且**不是**把断言删掉：改成**成对断言** —— `NULL` init 必被拒（返 `-10000`）／
          有效 init、空 out ⇒ 真实现**必须成功**（返 0）。⚠️ `sb` 本趟由 256 B 加到 512 B：
          真实现按契约读 `FSTABLEOBJINIT`（45×8＝360 B）⇒ 旧 256 B 夹具上那次调用**越界**（本步堵掉）。 */
    else if (GetTableObjHandlerInfo(NULL, sp) != WPF_PTS_ERR_NOT_IMPLEMENTED) rc = 8;
    else if (GetTableObjHandlerInfo(sb, NULL) != 0) rc = 73;
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
                      四条 stub 断言里的三条（`CreateDocContext`／`DestroyDocContext`／`GetTableObj*`）
                      与**仍属 stub 的** `LoGetPenaltyModuleInternalHandle` 一字未动；
                      `GetFloater*` 那条已由 `T-A52` 同趟改成成对断言（见下）。 */
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
    g_pts_doc_sets_c = save_doc_c_sets; g_pts_doc_rejected_c = save_doc_c_rej;
    g_pts_doc_destroys = save_doc_des; g_pts_doc_destroy_rej = save_doc_desrej;
    g_pts_fsp_ok = save_fsp_ok; g_pts_fsp_gap = save_fsp_gap; g_pts_fsp_rej = save_fsp_rej;
    g_pts_fsp_qpd_ok = save_fsp_q; g_pts_fsp_qpd_gap = save_fsp_qg;
    g_pts_fsp_des_ok = save_fsp_d; g_pts_fsp_des_gap = save_fsp_dg;
    g_pts_fsp_trk_ok = save_fsp_t; g_pts_fsp_trk_gap = save_fsp_tg;
    g_pts_fsp_fin_ok = save_fsp_f; g_pts_fsp_fin_gap = save_fsp_fg;   /* `t123`：格 7 计数一并复原 */
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
        /* **长度纪律**（如实划界，`t110` 现取重写）：本行**放不下应用侧的 256 B**（`PtsCache.Linux.cs`
           的 `NativeReport()` 用 `byte[256]`）⇒ 应用侧那一路**本来**就取不到本行
           （`WpfLinuxWin32_PtsGapReport()` 写不下就**如实返回 -1**，不截断、不静默），而应用侧 `entry=`
           走的是**另一条**取数路（内层异常的入口名，见 `PtsCache.Linux.cs:988-1014`）⇒ 本行长度
           **不影响** `entry=` 面。上界钉在 340 B（= 自检自己 `char rep[512]` 之内的**宽松界**），
           只用来防"后人顺手把报告撑爆"。**未**改应用侧任何件、**未**改仪表。
           🔴 **`t110` 实测到的失效形态（必须留档）**：这条断言原先量的是**链中途那一份** `rep`
           —— 而链会真的打到 `CreateInstalledObjectsInfo`／`CreateDocContext` 等入口 ⇒ `anchor=`／
           `frontier=` 从 `-` 变成**真名**、`calls=0:…` 也跟着非零 ⇒ **同一份格式**在链中途量出
           **374 B**、在净状态量出 **328 B** ⇒ **旧写法把"链的污染"算成了"格式变长"**
           （本趟 `diag=34` 的真因，与格 6 无关）。⇒ 改成**自检入口处（动计数器之前）现取一份净报告长度**再量：
           既保留"防撑爆"的原意，又不再对**链的调用序**敏感（`F-1` 同族口径）。本趟现取净基线 ＝ **328 B**
           （`t110` 加 `doc_*` 五个字段之前是 292 B ⇒ 本次 +36 B，余量仍充裕）。 */
        /* 判法（本趟现取后写死）：**入口净基线** vs **此刻净报告** —— 只判"格式有没有被后人撑爆"
           （相对增量 ≤ 64 B），**不**判"某个前置态下这行多长"、也**不**再判绝对上界 340 B
           （绝对上界天生对前置态敏感：带历史腿净基线实测 **342 B**，与 `t102` 修正同类）。两腿实测：净腿 328→328（增量 0）、
           带历史腿 342→342（增量 0）⇒ 该判据对**前置态不敏感**（`F-1` 口径），而把格式撑爆几百字节
           仍会**当场红**。 */
        else if (WpfLinuxWin32_PtsGapReport(rep, (int)sizeof(rep)) < 0 ||
                 (int)strlen(rep) - rep_clean_len > 64) rc = 34;
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
        /* ── `t110`／P1-W35 新增一格（**格号 `86` 起；旧号与 `80`–`85` 一个不动** —— 纪律第 `30` 条）──
             格 `86`（格 6 的成对断言）：**出参与该次调用绑定（字段逐项读回）＋ 两次句柄不同
             ＋ 观测镜指针域对拍 ＋ 拒绝面不改状态 ＋ 收尾同侪四路拒绝 ＋ 夹具不带泄漏**。
               修前该入口是 stub ⇒ 出参恒 `NULL` ⇒ 本格**当场红**（可证伪）。 */
        else if (!g_pts_selfcheck_f6_docctx()) rc = 86;
        else if (!g_pts_selfcheck_f7_fspage()) rc = 87;
        else if (!g_pts_selfcheck_f8_destroy()) rc = 88;
        else if (!g_pts_selfcheck_f9_track()) rc = 89;
    }

    /* ⏪ `t110` 实测教训（**必须留档**）：链跑完之后、**格 6 夹具之前**，观测镜要先**复原**。
       为什么：修前 `CreateDocContext` 是 stub ⇒ 它**不 push**，链一共只 push 3 条（环 `WPF_PTS_JMP_MAX=4`
       ⇒ **放得下**）；本步它变成真实现 ⇒ 链 push 4 条（`CreateInstalledObjectsInfo`／
       `DestroyInstalledObjectsInfo`／`CreateDocContext`／`DestroyDocContext`）⇒ **环刚好写满**，
       格 6 夹具自己那两条 push 就会把**它要找的那条覆盖掉** ⇒ 同一份夹具在**链后**跑必然
       找不到条目（本趟 `diag=86`、夹具标签 `21`＝镜对拍那一格的真因；**单独跑夹具时全绿**）。
       ⇒ 次序写死：**链结束 ⇒ 先复原镜 ⇒ 再跑夹具**（与末尾那次复原**同一件事的两个时机**，
         末尾那次保留：它同时负责把镜还成"自检进来时的样子"）。 */
    memcpy(g_pts_jmp, save_jmp, sizeof(save_jmp));
    g_pts_jmp_head = save_jmp_head; g_pts_jmp_n = save_jmp_n;

    // 复原台账 + 观测镜（自检不许改变可观测状态）
    memcpy(g_pts_calls, save_calls, sizeof(save_calls));
    memcpy(g_pts_seen, save_seen, sizeof(save_seen));
    memcpy(g_pts_jmp, save_jmp, sizeof(save_jmp));
    g_pts_jmp_head = save_jmp_head; g_pts_jmp_n = save_jmp_n;
    g_pts_doc_sets = save_doc_sets; g_pts_doc_rejected = save_doc_rej;
    g_pts_doc_sets_c = save_doc_c_sets; g_pts_doc_rejected_c = save_doc_c_rej;
    g_pts_doc_destroys = save_doc_des; g_pts_doc_destroy_rej = save_doc_desrej;
    g_pts_fsp_ok = save_fsp_ok; g_pts_fsp_gap = save_fsp_gap; g_pts_fsp_rej = save_fsp_rej;   /* `t123`：格 7 计数一并复原 */
    g_pts_fsp_qpd_new = save_fsp_qpd_new; g_pts_fsp_qpd_nc = save_fsp_qpd_nc;                /* `T-A15`：语义面计数一并复原 */
    g_pts_fsp_vis_ok = save_fsp_vis;
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

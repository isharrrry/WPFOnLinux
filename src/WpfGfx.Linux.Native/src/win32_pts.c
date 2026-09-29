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
/* ⏪ `t127`／裁定二十七：`FsQueryTrackDetails`／`FsCreatePageFinite` 的成败面。 */
static int g_pts_fsp_trk_ok   = 0;
static int g_pts_fsp_trk_gap  = 0;
static int g_pts_fsp_fin_ok   = 0;
static int g_pts_fsp_fin_gap  = 0;
static int g_pts_fsp_pl_ok   = 0;      /* `t129` `FsQueryTrackParaList`：成功次数（**本步恒 0**） */
static int g_pts_fsp_pl_gap  = 0;      /* `t129`：返非 0 次数（**本步＝全部**） */

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

/* 预言的空槽（**由托管侧源码**得来：`cbkobj` 的前三槽与整个 `cbkwrd` 声明为 `IntPtr` 且**未赋值**）
   ⇒ 只读回读若在这些绝对偏移上读到非 0，说明偏移（或对齐/顺序）**另有其事** ⇒ 指纹判 FAIL。 */
#define WPF_PTS_NULL_PRED_CBKOBJ_LEAD 3
#define WPF_PTS_NULL_PRED_CBKW_RD     29
#define WPF_PTS_NULL_PRED_TOTAL       (WPF_PTS_NULL_PRED_CBKOBJ_LEAD + WPF_PTS_NULL_PRED_CBKW_RD)

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
   **缺省 1** ⇒ 与 `t148` 的现有行为**逐格一致**（`t148` 就是 1 窗）。`WPF_PTS_DRIVE_PROBE_N=<n>`
   可调（仅当闸开时生效）；上限 = 入站 `FsCreatePage*` 的实际调用次数（日志会给 `budget-exhausted`）。 */
#define WPF_PTS_DRIVE_PROBE_WINDOW_BUDGET_DEFAULT 1
static int wpf_pts_drive_probe_n(void);   /* 定义见闸函数旁边（读一次并缓存） */
#define WPF_PTS_DRIVE_PROBE_PRINT_SKIP_MAX   3     /* 跳过的具名行最多打几条（其余只计数） */
/* ⚠️ **反腿开关**（默认 0）：置 1 时把 `nms` 换成**伪值 `0x1`** —— 只允许在
   **应用副本**上以 `-DWPF_PTS_DRIVE_PROBE_FAKE_NMS=1` 单独编译，**绝不许**进主链产物。 */
#ifndef WPF_PTS_DRIVE_PROBE_FAKE_NMS
#define WPF_PTS_DRIVE_PROBE_FAKE_NMS 0
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
        cached = (v && v[0] && strcmp(v, "0") != 0) ? 1 : 0;
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
_Static_assert(WPF_PTS_FSCBK_OFF + WPF_PTS_SNAP_IDX_GETFIRSTPARA * 8 == 136, "下标 GETFIRSTPARA 对应绝对偏移 != +136");
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
struct wpf_pts_subtrack_s {
    unsigned int magic;
    int          c_paras;       /* 子轨段落数（(b) 要答的那个数；**未造型时无意义**） */
    int          formatted;     /* 是否已被造型（**今天恒 0**） */
    const void  *nmp;           /* 来源段落句柄（**本 run** 由托管 `+136` 产出） */
    const void  *pfsparaclient; /* 配对的客户端句柄 */
    int          seq;           /* 台账序号（实例唯一） */
    int          live;
};
#define WPF_PTS_SUB_MAGIC 0x57535054u     /* "WSPT" */
#define WPF_PTS_SUB_MAX   16
static wpf_pts_subtrack *g_pts_sub_live[WPF_PTS_SUB_MAX];
static int g_pts_sub_live_n    = 0;
static int g_pts_sub_created   = 0;
static int g_pts_sub_destroyed = 0;
static int g_pts_sub_seq       = 0;
static int g_pts_sub_claim_ok  = 0;
static int g_pts_sub_claim_bad = 0;
static int g_pts_sub_selftest_mask = -1;

static wpf_pts_subtrack *wpf_pts_sub_new(const void *nmp, const void *client)
{
    if (g_pts_sub_live_n >= WPF_PTS_SUB_MAX) return NULL;
    wpf_pts_subtrack *o = (wpf_pts_subtrack *)calloc(1, sizeof(*o));
    if (!o) return NULL;
    o->magic = WPF_PTS_SUB_MAGIC; o->c_paras = 0; o->formatted = 0;
    o->nmp = nmp; o->pfsparaclient = client; o->seq = ++g_pts_sub_seq; o->live = 1;
    g_pts_sub_live[g_pts_sub_live_n++] = o;
    g_pts_sub_created++;
    return o;
}
static void wpf_pts_sub_destroy(wpf_pts_subtrack *o)
{
    if (!o || o->magic != WPF_PTS_SUB_MAGIC) return;
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
/* 台账/身份/销毁口径的**自检**（纯 native；只用自己的对象，不碰应用状态）：
   bit0 新建后可认领 ｜ bit1 NULL 被拒 ｜ bit2 栈地址被拒 ｜ bit3 销毁后不可认领 ｜ bit4 在册数复原 */
static int wpf_pts_sub_selftest(void)
{
    int mask = 0;
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
    return mask;
}

int WpfLinuxWin32_PtsSubLive(void)        { return g_pts_sub_live_n; }
int WpfLinuxWin32_PtsSubCreated(void)     { return g_pts_sub_created; }
int WpfLinuxWin32_PtsSubDestroyed(void)   { return g_pts_sub_destroyed; }
int WpfLinuxWin32_PtsSubClaimOk(void)     { return g_pts_sub_claim_ok; }
int WpfLinuxWin32_PtsSubClaimBad(void)    { return g_pts_sub_claim_bad; }
int WpfLinuxWin32_PtsSubSelfTestMask(void){ return g_pts_sub_selftest_mask; }

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
typedef int (*wpf_pts_fn_get_para_properties)(const void *pfsclient, const void *nmp, void *fspap);
_Static_assert(sizeof(wpf_pts_fn_get_first_para) == 8 && sizeof(wpf_pts_fn_get_para_properties) == 8,
               "回调指针不是 8 B（与快照的 8 B 字假设不符）");

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


/* ⏪ `t151`：**窗外腿**（判据 §8.2 的成对实验反腿）—— 用**同一个**真 `nms` 在**窗外**调 `+136`。
   两处调用点：① `FsDestroyPage`（页拆除在 `using` 窗关闭之后）；② `FsQueryTrackParaList`
   （日志可证**被调 1123 次**；它在 `PtsHelper.ParaListFromTrack` 里，被 `FlowDocumentPage` 的
   列/段落结果查询路径调用 —— **该处是否在窗内属代码结构推断**，实验本身即其检验）。
   ⚠️ **只在闸开且该 context 已缓存 `nms` 时**才发调；**绝不**伪值、**绝不**跨上下文用陈旧句柄。 */
static void wpf_pts_drive_probe2_oow(void *pfscontext, const char *where)
{
    if (!wpf_pts_drive_probe_enabled()) return;
    wpf_pts_doc *dp = wpf_pts_doc_ptr(pfscontext);
    if (!dp || !dp->drive_nmseg) return;
    const void *fp136o = wpf_pts_snap_word(dp, WPF_PTS_SNAP_IDX_GETFIRSTPARA);
    if (!fp136o) return;
    int fSuccO = -1; void *nmpO = NULL;
    int rcO = ((wpf_pts_fn_get_first_para)fp136o)((const void *)dp->p_fsclient, dp->drive_nmseg,
                                                  &fSuccO, &nmpO);
    g_pts_dp2_oow_calls++;
    g_pts_dp2_oow_rc = rcO; g_pts_dp2_oow_succ = fSuccO; g_pts_dp2_oow_nmp = (const void *)nmpO;
    const char *vO = (rcO == 0 && fSuccO == 1 && nmpO != NULL) ? "FIRSTPARA-HANDLE"
                   : (rcO == 0 && fSuccO == 0 && nmpO == NULL) ? "FIRSTPARA-ABSENT(by-design)"
                   : (rcO == -100002) ? "CALLBACK-ERR(-100002)"
                   : (rcO == -10000) ? "NOT-IMPLEMENTED" : "FIRSTPARA-OTHER";
    fprintf(stderr, "[DRIVE-PROBE2-OOW] where=%s window=out nms136=%p rc136=%d fSucc=%d nmp=%p "
                    "idem136=- v136=%s calls=%d\n", where, dp->drive_nmseg, rcO, fSuccO, nmpO, vO,
            g_pts_dp2_oow_calls);

    /* ⏪ `t156` 第三跳**窗外腿**（判据 §8.3.3）：用**同一个合法 `nmp`** 在**窗外**调 `+176`。
       代码级预判 ＝ 本槽**对窗不敏感**（`CreateParaclient` → `new *ParaClient(this)` →
       `UnmanagedHandle(ptsContext)` → `PtsContext.CreateHandle`，**不读** `CurrentFormatContext`）
       ⇒ 「窗内=0 ∧ 窗外=0」＝ `WINDOW-INSENSITIVE(有据)`，**不判红**（硬判"实验失败"是**假红**）。
       ⚠️ **只在**"该 doc **仍在册**（native 侧自记）"且已缓存**合法** `nmp` 时才发调 ——
         目的是**不**撞 `PtsContext.CreateHandle` 的 `!this.Disposed`（**不可捕获 `FailFast`**，主链禁）。
       ⚠️ 上限 4 次（每调一次多一条托管活条目；回收紧跟其后）⇒ 不许无限发放。 */
    const void *fp176o = wpf_pts_snap_word(dp, WPF_PTS_SNAP_IDX_CREATEPARACLIENT);
    const void *fp192o = wpf_pts_snap_word(dp, WPF_PTS_SNAP_IDX_DESTROYPARACLIENT);
    if (fp176o && fp192o && dp->drive_nmp && g_pts_dp3_oow_calls < 4 && wpf_pts_ctx_is_live(dp)) {
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
static void wpf_pts_engine_drive(wpf_pts_doc *d, const void *where)
{
    const void *m = NULL;
    for (int i = 0; i < g_pts_io_live_n; i++) {
        if (g_pts_io_live[i]->subtrack_methods) { m = g_pts_io_live[i]->subtrack_methods; break; }
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
    /* ⏪ `t148`：**运行期闸**（缺省关）—— 闸关 ⇒ **一次都不调**，并留一条具名行 */
    if (!wpf_pts_drive_probe_enabled()) { wpf_pts_drive_probe_skip("gate-off"); return; }
    if (g_pts_dp_calls >= wpf_pts_drive_probe_n()) { wpf_pts_drive_probe_skip("budget-exhausted"); return; }
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
        if (!((const void *)d->drive_nmseg)) d->drive_nmseg = (const void *)nmSeg1;  /* 供窗外腿复用 */

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

#if WPF_PTS_FSP_PL_ENGINE_DRIVE
    if (g_pts_sub_live_n > 0 || 1) wpf_pts_engine_drive(d, where);   /* ⏪ t165 E2（副本专用） */
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
            wpf_pts_sub_destroy(g_pts_doc_live[i]->sub);
            g_pts_doc_live[i]->sub = NULL;
        }
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
            memset(d, 0, sizeof(*d));                 /* 先清（**不留残留**），再逐字段填 */
            d->fSimple    = 1;                        /* 简单页 ⇒ 托管侧只读 trackdescr 两格 */
            d->r_u = 0;  d->r_v = 0;  d->r_du = pg->pg_w; d->r_dv = pg->pg_h;
            d->td_pfstrack = (void *)&pg->c_paras;   /* `t127`：轨句柄 ＝ **本对象内**该字段的地址 */
            d->b_defined = pg->bbox_defined;
            d->b_u = 0;  d->b_v = 0;  d->b_du = pg->pg_w; d->b_dv = pg->pg_h;
            g_pts_fsp_qpd_ok++;
            { int _i = wpf_pts_index("FsQueryPageDetails"); if (_i >= 0) g_pts_seen[_i]++; }
            g_pts_seq++;
            return 0;
        }
    }
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
    /* ⏪ `t151` 窗外腿（调用点 ①）：页拆除在 `using` 窗关闭之后 */
    wpf_pts_drive_probe2_oow(pfscontext, "FsDestroyPage");
    if (!pfspage)                     reason = "null-page";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else {
        for (int i = 0; i < g_pts_fsp_live_n; i++) {
            if ((void *)g_pts_fsp_live[i] != pfspage) continue;
            if (g_pts_fsp_live[i]->magic != WPF_PTS_FSP_MAGIC) { reason = "already-destroyed"; break; }
            g_pts_fsp_live[i]->magic = 0;             /* 先失效 ⇒ 重复销毁必被拒 */
            free(g_pts_fsp_live[i]);
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
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsDestroyPage ctx=%p page=%p des_ok=%d des_gap=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pfspage, g_pts_fsp_des_ok, g_pts_fsp_des_gap);
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
    const char *reason = NULL;
    if (pTrackDetails) *(int *)pTrackDetails = 0;          /* 失败路径：先清成 0（不留残留） */
    if (!pTrackDetails)               reason = "null-details-out";
    else if (!pTrack)                 reason = "null-track";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else if (!wpf_pts_track_owned(pTrack)) reason = "unknown-track-or-not-ours";
    else {
        for (int i = 0; i < g_pts_fsp_live_n; i++) {
            if ((const void *)&g_pts_fsp_live[i]->c_paras != pTrack) continue;
            *(int *)pTrackDetails = g_pts_fsp_live[i]->c_paras;   /* **按对象**回答段数 */
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
    const char *reason = NULL;
    wpf_pts_drive_probe2_oow(pfscontext, "FsQueryTrackParaList");   /* ⏪ `t151` 窗外腿（调用点 ②；该入口日志可证被调） */
    if (cParaDesc) *cParaDesc = 0;                       /* 失败：出参先清成 0（不留残留） */
    if (!cParaDesc)                       reason = "null-count-out";
    else if (!pTrack)                     reason = "null-track";
    else if ((const void *)pfscontext && !wpf_pts_doc_find(pfscontext)) reason = "unknown-ctx";
    else if (!wpf_pts_track_owned(pTrack)) reason = "unknown-track-or-not-ours";
    else if (cParas < 0)                  reason = "negative-cparas";
    else if (cParas > 0 && !rgParaDesc)   reason = "null-paradesc-out";
    /* ★ 本步的**承重拒绝**：即使入参全都合法、track 也确是我们自己的，**仍然拒** ——
       因为"可用的 `pfsparaclient`"只能由**托管侧**产生（见上）⇒ 返 0 就是**假成功**。
       ⏪ `t160`（P1-W80）：**探针门开时**先走**真填**路径（下面那块）；门关／填不成 ⇒ **逐字保持旧行为**
       （`-10000` ＋ `reason=paraclient-table-not-native`）⇒ **缺省路径零变化**。 */
    else {
        int fsp_filled = 0;
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
                /* ③ 配额到点 ⇒ 换代（当前代挂到 `prev`，**下次调用**才回收） */
                if (!reason && dp->fsp_pl_cur && dp->fsp_pl_quota >= wpf_pts_fsp_pl_gen_size()) {
                    dp->fsp_pl_prev = dp->fsp_pl_cur; dp->fsp_pl_cur = NULL; dp->fsp_pl_quota = 0;
                }
                /* ④ 需要新一代 ⇒ 用托管 `+176` **现造**（唯一合法来源，判据 §5-P3） */
                if (!reason && !dp->fsp_pl_cur) {
                    void *hn = NULL;
                    int rc176 = ((wpf_pts_fn_create_paraclient)fp176f)((const void *)dp->p_fsclient,
                                                                      dp->drive_nmp, &hn);
                    g_pts_fsp_pl_last_rc176 = rc176;
                    if (rc176 == 0 && hn != NULL) {
                        dp->fsp_pl_cur = (const void *)hn; dp->fsp_pl_gen++;
                        dp->fsp_pl_site = "query-frame";
                    } else reason = "create-paraclient-failed";
                }
                /* ⑤ **真填**（先清零 ⇒ 未初始化内存不许交给上级；**填完才置条数**，判据 §5-P2） */
                if (!reason && dp->fsp_pl_cur) {
                    wpf_pts_fsparadesc *rg = (wpf_pts_fsparadesc *)rgParaDesc;
                    /* ⏪ `t162`（队长 `t163` 指引 ＋ 判据 §4(a)）：`pfspara` 的合法来源＝**本侧自有的
                       "子轨对象"**（本仓范式：句柄＝本对象内字段地址；`FsQueryTrackDetails` 同形）。
                       **不是**自造常量、**不是**伪指针、**不**复用 `nmp` 当占位。 */
                    if (!dp->sub) {
                        dp->sub = wpf_pts_sub_new((const void *)dp->drive_nmp, (const void *)dp->fsp_pl_cur);
                        if (dp->sub) dp->sub_created_seq = dp->sub->seq;
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
                                            "created=%d destroyed=%d formatted=0 reused=%d v=%s\n",
                                    para_val, para_pre, para_src, claimed, acc_rc,
                                    g_pts_fsp_pl_para_claims, g_pts_fsp_pl_para_rejected,
                                    g_pts_fsp_pl_para_hold_ok, g_pts_fsp_pl_para_released,
                                    (void *)dp, (dp->drive_nmp ? "DRIVE-PROBE2.nmp1/DRIVE-PROBE3.nmp176" : "none"),
                                    (int)offsetof(wpf_pts_fsparadesc, pfspara), dp->sub_created_seq,
                                    g_pts_sub_live_n, g_pts_sub_created, g_pts_sub_destroyed, dp->sub_reused,
                                    (acc_rc == 0) ? "PARA-ACCEPTED" : "ACCEPT-OTHER");
                        }
                    }
                    *cParaDesc = cParas;                       /* ← **只在真填完成后**置（P2） */
                    g_pts_fsp_pl_fills++;
                    dp->fsp_pl_quota++;
                    g_pts_fsp_pl_last_h = dp->fsp_pl_cur;
                    const unsigned char *bp = (const unsigned char *)&rg[0];
                    char dump[3 * 32 + 1];
                    for (int i = 0; i < 32; i++) snprintf(dump + i * 3, 4, "%02x ", bp[i]);
                    fprintf(stderr, "[FSPARALIST-FILL] rc=0 reason=ok entry=FsQueryTrackParaList cParas=%d n=%d "
                                    "h0=%p src=managed-176 run=site=%s win=%s gen=%d quad=%d hold=%d "
                                    "off16=%d bytes0_32=%s ok=%d gap=%d\n",
                            cParas, cParas, (void *)dp->fsp_pl_cur, dp->fsp_pl_site,
                            wpf_pts_fsp_pl_win_out() ? "out" : "in", dp->fsp_pl_gen, dp->fsp_pl_quota,
                            (dp->fsp_pl_prev != NULL) ? 1 : 0, (int)offsetof(wpf_pts_fsparadesc, pfsparaclient),
                            dump, g_pts_fsp_pl_ok + 1, g_pts_fsp_pl_gap);
                    g_pts_fsp_pl_ok++;
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
        if (fsp_filled) return 0;              /* **只有真填后才返 0**（判据 §5-P1） */
        if (!reason) reason = "paraclient-table-not-native";   /* 旧路径逐字保留 */
    }
    g_pts_fsp_pl_gap++;
    fprintf(stderr, "[FS_PAGE_GAP] rc=%d reason=%s entry=FsQueryTrackParaList ctx=%p track=%p cParas=%d "
                    "owned=%d ok=%d gap=%d\n",
            WPF_PTS_ERR_NOT_IMPLEMENTED, reason, pfscontext, pTrack, cParas,
            wpf_pts_track_owned(pTrack), g_pts_fsp_pl_ok, g_pts_fsp_pl_gap);
    return WPF_PTS_ERR_NOT_IMPLEMENTED;                  /* ← 本步**永不**返 0（返 0 ＝ 假成功） */
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

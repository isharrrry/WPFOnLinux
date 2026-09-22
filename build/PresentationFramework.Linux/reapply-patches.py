#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""PresentationFramework.Linux.csproj 生成后补丁（可重复执行、幂等）。

背景：build/port-lib.py 每次运行都会**整份重写** build/PresentationFramework.Linux/
PresentationFramework.Linux.csproj，因此必需的手工补丁必须有一份可重放的出处。
重跑 port-lib 之后执行：

    python3 build/PresentationFramework.Linux/reapply-patches.py

补丁清单
--------
A. 公开签名（PublicSign）+ WCP 公钥
   PresentationFramework 是 WindowsBase / PresentationCore 的 IVT 受益方：
     WindowsBase/OtherAssemblyAttrs.cs:17        InternalsVisibleTo(BuildInfo.PresentationFramework)
     PresentationCore/OtherAssemblyAttrs.cs:11   同上
   而 Shared/RefAssemblyAttrs.cs 定义
     BuildInfo.PresentationFramework = "PresentationFramework, PublicKey=<WCP 公钥>"。
   本工程不签名（公钥为空）时编译器拒绝授予友元访问：
     实测 CS0281 ×1448 行（去重 720 条唯一错误），并连带 CS0122 ×268、CS0538 ×200、CS0115 ×339。
   处置：用只含公钥的 build/keys/WcpPublicKey.snk 公开签名（PublicSign）。
   实测 WcpPublicKey.snk 与 WCP_PUBLIC_KEY_STRING 逐字节相同（160 字节）；
   .NET Core 运行时不校验强名称，公开签名产物在 Linux 可正常加载。

B. 接回两个被 port-lib 丢弃的本地引用（CycleBreakers / System.Printing）
   上游 PresentationFramework.csproj 引用：
     ① $(WpfCycleBreakersDir)PresentationUI\\PresentationUI-PresentationFramework-impl-cycle.csproj
        —— 提供 MS.Internal.Documents.FindToolBar。上游 CycleBreakers 目录在**本上游快照中
           不存在**（`find upstream/wpf -iname "*impl-cycle*"` 为空、$(WpfCycleBreakersDir) 无定义）
           → 结构上不可移植；按主控裁定用 build/CycleStub.PresentationUI.Linux 的最小替身顶替
           （AssemblyName=PresentationUI，保留 API 形态、不伪造行为）。
     ② $(WpfSourceDir)System.Printing\\ref\\System.Printing-ref.csproj
        —— port-lib 的 `-ref` 规则跳过它；但它是 System.Printing 的**唯一托管面**（实现是 C++），
           由 build/System.Printing.Linux 产出 System.Printing.dll。
   两个 Reference 都带 Exists() 条件：产物缺失时**不静默掩盖**，而是留下真实编译错误。

已从本脚本移除的两处补丁（主控已修好 port-lib，自动项生效 → 手工补丁成冗余）
--------
· 「NoWarn CA1420;WPF0001」——port-lib 现在会向上遍历上游 Directory.Build.props/Props 收集 NoWarn，
  生成物已自动含 CA1420;WPF0001（实测）。
· 「split.cur / splitopen.cur 的 Non-Resx 元数据」——port-lib 已改为 XML 解析，
  两个 .cur 的 GenerateSource/Type/ManifestResourceName/WithCulture 四项元数据实测全在。

剔除清单：**无需剔除任何源文件**（本轮实测）
--------
上游 csproj 用 <EnableDefaultItems>false</EnableDefaultItems>，port-lib 已按 csproj 原样只纳 1328 个
项目内文件（目录下 1336 个 .cs 里有 8 个上游本就没编入：7 个死文件 + ref/PresentationFramework.cs），
没有 PresentationCore 那种「默认 glob 误纳」问题。故不创建 build/excludes/PresentationFramework.txt。
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CSPROJ = os.path.join(HERE, "PresentationFramework.Linux.csproj")
MARKER = '  <Import Project="Sdk.targets" Sdk="Microsoft.NET.Sdk" />'
BEGIN = "  <!-- ==== WPF-on-Linux 补丁开关：以下内容由 reapply-patches.py 追加 ==== -->"
END = "  <!-- ==== WPF-on-Linux 补丁结束 ==== -->"

PATCH_A = '''  <!-- ============================================================================
       WPF-on-Linux 补丁 A：公开签名（PublicSign），通过 WindowsBase/PresentationCore 的 IVT 检查
       ============================================================================
       现象（实测）：CS0281 ×1448 行（去重 720 条），报错原文——
         "友元访问权限由"WindowsBase, Version=4.0.0.1, Culture=neutral,
          PublicKeyToken=null"授予，但是输出程序集('')的公钥与授予程序中
          InternalsVisibleTo 特性指定的公钥不匹配。"
       根因：WindowsBase / PresentationCore 的 OtherAssemblyAttrs.cs 用
         BuildInfo.PresentationFramework = "PresentationFramework, PublicKey=<WCP 公钥>"
       授予友元；本工程未签名 → 全部 internal 访问被拒，并连带
       CS0122 ×268、CS0538 ×200、CS0115 ×339。
       处置：PublicSign + build/keys/WcpPublicKey.snk（只含公钥，非机密）。
       ============================================================================ -->
  <PropertyGroup>
    <SignAssembly>true</SignAssembly>
    <PublicSign>true</PublicSign>
    <AssemblyOriginatorKeyFile>$(WpfLinuxRoot)build/keys/WcpPublicKey.snk</AssemblyOriginatorKeyFile>
    <!-- 两条「本移植工程特有」的警告压制，均为**混合签名/替身基类**造成，不是源码问题：
         · CS8002 ×3：本工程（及 PC/RF/SP）公开签名，而 WindowsBase / UIAutomationTypes /
           UIAutomationProvider 在本移植工程中**未签名** —— 上游是「全签名」，故看不到该警告。
           主控已排期在集成波用统一签名根治，届时可撤。
         · CS0184 ×1（MS/Internal/documents/DocumentGridContextMenu.cs:73）：
           `DocumentViewerOwner is DocumentApplicationDocumentViewer` —— 后者的真类派生自 PF 的
           DocumentViewer，而 PresentationUI 替身不能引用 PF（编译期循环），故替身基类取 UIElement，
           编译期即可判定永假。运行期行为与编译期结论一致（该路径即 DocumentApplication 旧特性，
           在 Linux 上不启用）。真 PresentationUI 移植后基类归位，本条可撤。 -->
    <NoWarn>$(NoWarn);CS8002;CS0184</NoWarn>
    <!-- 上游 PresentationFramework.csproj:12 就有这一条，port-lib 未搬运（同一口径缺口）。
         关闭 deps.json 生成，避免「项目输出 vs reference copy-local」同名键冲突（RF pass 2 实测踩到）。 -->
    <GenerateDependencyFile>false</GenerateDependencyFile>
  </PropertyGroup>
'''

PATCH_C = '''  <!-- ============================================================================
       WPF-on-Linux 补丁 C（`TASK-0304`/`TASK-0305`，车道 W86A）：PTS 缺口 = 具名能力边界
       ============================================================================
       把 `D-G70`（切「富文本」/「流文档」页 ⇒ `rc=134`）从"整进程必死"变成
       "**具名、可判、可见的能力边界**"。三处改动，**全部在托管侧**（native 侧是
       `src/WpfGfx.Linux.Native/src/win32_pts.c`，与本补丁同批）：

        ① `PtsCache.AcquireContextCore`（**`A2`，修 `D-G78`**）：
           `CreatePTSContext` 抛异常时，把**那条半初始化的池项从 `_contextPool` 里移除**
           （今天留着 ⇒ 下一趟布局在 `:182-189` 把它当空闲项复用 ⇒ `PtsHost.Context` 的
           `Invariant.Assert(_context != IntPtr.Zero)` 失败 ⇒ `Environment.FailFast`），
           并立**具名能力闩**（只对"PTS 能力不可用"这**一个**条件生效 ⇒ 后续 `AcquireContext`
           立即抛 `PtsUnavailableException`，不再进 native、不再扫池 ⇒ 不重试风暴）。
           ⚠️ **`Invariant.Assert` 一个都没删、没放宽** —— 目标是让它们**不再被走到**。
        ② `FlowDocumentView`（**`A3`**）：PTS 不可用时给**页级具名占位**（洋红矩形 +
           边框 + 三行说明文字），**不留空白**；且**一次失败只降级一次**（视图级闩 ⇒ 幂等）。
        ③ 两处**只读**打印（`[PTS-UNAVAILABLE]`）⇒ 失败**不许静默**。

       ⚠️ 生成物（`*.Linux.cs`）由本脚本从**上游逐字复制 + needle 校验后改写**：
          锚点找不到 / 命中数不符 ⇒ **报错退出**（绝不静默产出未打补丁的副本）。
       ⚠️ 本块**必须排在 port-lib 之后**（`port-lib.py PresentationFramework` 会整份重写 csproj）。
       ============================================================================ -->
  <ItemGroup>
    <Compile Remove="$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsCache.cs" />
    <Compile Include="$(WpfLinuxRoot)build/PresentationFramework.Linux/PtsCache.Linux.cs" />
    <Compile Remove="$(UpstreamWpfRoot)src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/documents/FlowDocumentView.cs" />
    <Compile Include="$(WpfLinuxRoot)build/PresentationFramework.Linux/FlowDocumentView.Linux.cs" />
  </ItemGroup>
'''

PATCH_B = '''  <!-- ============================================================================
       WPF-on-Linux 补丁 B：接回两个 port-lib 丢弃的本地引用
       ============================================================================
       ① PresentationUI（CycleBreakers 替身）：提供 MS.Internal.Documents.FindToolBar。
          上游 CycleBreakers 目录在本上游快照中不存在（$(WpfCycleBreakersDir) 无定义）
          → 结构上不可移植；用 build/CycleStub.PresentationUI.Linux 的最小替身顶替
          （见该工程头部注释：API 形态保留、行为不伪造）。
          <Private>true</Private>：替身即当前运行期的 PresentationUI，需随 PF 进输出目录。
       ② System.Printing：port-lib 的 `-ref` 规则跳过了 System.Printing-ref.csproj，
          而它是 System.Printing 的**唯一托管面**（实现是 C++）→ build/System.Printing.Linux 产出。
       两者都带 Exists() 条件，产物缺失时留下真实编译错误（不静默掩盖）。
       ============================================================================ -->
  <ItemGroup Condition="Exists('$(WpfLinuxRoot)build/CycleStub.PresentationUI.Linux/bin/Debug/PresentationUI.dll')">
    <Reference Include="PresentationUI"><HintPath>$(WpfLinuxRoot)build/CycleStub.PresentationUI.Linux/bin/Debug/PresentationUI.dll</HintPath><Private>true</Private></Reference>
  </ItemGroup>
  <ItemGroup Condition="Exists('$(WpfLinuxRoot)build/System.Printing.Linux/bin/Debug/System.Printing.dll')">
    <Reference Include="System.Printing"><HintPath>$(WpfLinuxRoot)build/System.Printing.Linux/bin/Debug/System.Printing.dll</HintPath><Private>true</Private></Reference>
  </ItemGroup>
'''


# ══════════════════════════════════════════════════════════════════════════════
#  补丁 C 的**生成物**（`TASK-0304`/`TASK-0305`，车道 W86A）
#
#  【为什么生成物由本脚本产出，而不是新写一个 tools/patch-*.py】
#    PF 这个工程的**唯一**持久注入面就是本脚本：`build/integration-wave.sh:124-126` 在
#    「port-lib 重生成」之后**必定重放** `build/<Proj>.Linux/reapply-patches.py`；而
#    `build/port-lib.py PresentationFramework` 会**整份重写 csproj**（把别人的接线抹掉）。
#    ⇒ 只有挂在这里的接线与生成物能**活过每一波**。本件写域限定 `build/PresentationFramework.Linux/**`，
#      所以生成器就放在这里，**不改** `src/WpfGfx.Linux.Native/tools/**`（那是别人的写域）。
#
#  【纪律（与 `tools/patch-presentationframework-*.py` 同一套）】
#    · 每次从**上游**重读，逐字复制 + needle 校验后改写；
#    · needle 命中数不符 ⇒ **报错退出**（rc≠0），绝不静默产出"没打上补丁的副本"；
#    · 生成物头部写明"由谁生成、上游是哪一份、改了哪几处"，**不许手改**。
# ══════════════════════════════════════════════════════════════════════════════

UP_PF = "src/Microsoft.DotNet.Wpf/src/PresentationFramework/"
REPO = os.path.normpath(os.path.join(HERE, "..", ".."))

DERIVED_HEADER = """// ⚠️ 本文件由 build/PresentationFramework.Linux/reapply-patches.py **生成**，不要手改。
//
// 内容 = 上游 `{up}` 逐字复制 + {n} 处 W86A（`TASK-0304`/`TASK-0305`）改动。
// 每次运行该脚本都会从上游重读重生成；needle 找不到 / 命中数不符时**报错退出**
// （不会静默产出未打补丁的副本）。改动逐处见：
//   {edits}
//
// 背景（`D-G70`/`D-G78`）：本移植没有 PTS/原生 LineServices ⇒ 切「富文本」/「流文档」页
// 曾**整进程 `rc=134`**。本件把它变成「**具名、可判、可见的能力边界**」：
//   · native 侧新增 `src/WpfGfx.Linux.Native/src/win32_pts.c`（6 个入口导出、**如实返回非零 LsErr**、
//     打具名台账 `PTS_GAP entry=… seq=… err=-10000`）；
//   · 本文件（托管侧）负责：**拆掉毒池项**（`D-G78` 的根因）＋ **具名能力闩** ＋ **页级可见降级**。
// ⚠️ `Invariant.Assert` **一个都没删、没放宽** —— 目标是让它们**不再被走到**；
//    若仍被走到，断言照旧响亮（那是新缺陷）。
"""


def _apply_edits(upstream_rel, out_name, edits):
    """从上游重读、逐处 needle 替换、写生成物。needle 命中数不符 ⇒ 抛异常（不静默）。"""
    up_abs = os.path.join(REPO, "upstream", "wpf", upstream_rel)
    if not os.path.isfile(up_abs):
        raise RuntimeError("上游文件不存在：%s" % up_abs)
    with open(up_abs, encoding="utf-8-sig") as f:
        text = f.read()
    for i, (needle, repl, expect) in enumerate(edits, 1):
        got = text.count(needle)
        if got != expect:
            raise RuntimeError(
                "%s：第 %d 处 needle 命中 %d 次（期望 %d）—— 上游变了或本脚本过期，**拒绝产出**"
                % (out_name, i, got, expect))
        text = text.replace(needle, repl, expect)
    names = " ／ ".join("E%d" % i for i in range(1, len(edits) + 1))
    out_abs = os.path.join(HERE, out_name)
    with open(out_abs, "w", encoding="utf-8") as f:
        f.write(DERIVED_HEADER.format(up="upstream/wpf/" + upstream_rel, n=len(edits), edits=names))
        f.write(text)
    return out_abs, len(edits)


# ── PtsCache.Linux.cs 的三处改动 ──────────────────────────────────────────────
PTSCACHE_E1_NEEDLE = """        private List<ContextDesc> _contextPool;
"""
PTSCACHE_E1_REPL = """        private List<ContextDesc> _contextPool;

        // ==================================================================
        //  W86A `A2`（`D-G78`）：**具名能力闩**
        //  null = "还没失败过"；非 null = "PTS 能力在本进程内已判定不可用"。
        //  只由 AcquireContextCore 的 catch 置位、只被同一个方法的入口读
        //  ⇒ 作用域**刻意收窄**：它**不是**兜底 catch-all，**不**覆盖任何别的失败族
        //    （判据见 `WpfLinuxPtsGap.IsPtsUnavailable`：必须由 native 台账亲口作证）。
        // ==================================================================
        private PtsUnavailableException _ptsUnavailable;
"""

PTSCACHE_E2_NEEDLE = """            int index;

            // Look for the first free PTS Context.
"""
PTSCACHE_E2_REPL = """            int index;

            // ── W86A `A2`：具名能力闩（**只对"PTS 能力不可用"这一个条件生效**）──────────
            //   第一次失败之后，后续布局**不再进 native、不再扫池**：
            //   否则每次 Measure 都抛一次 ⇒ 布局重入 / CPU 打转（W78A §3.4 风险 2）。
            //   ⚠️ 这里**不吞**任何东西：抛的是**具名**异常，谁都能按类型接住并计数。
            if (_ptsUnavailable != null)
            {
                // 每次抛**新的**实例（Stack 指向"这次是谁来问的"），首次失败挂在 InnerException 上
                // —— 抛同一个旧实例会让栈指向**第一次**的调用点，那是误导性读数。
                throw new PtsUnavailableException(
                    _ptsUnavailable.Entry, _ptsUnavailable.ErrorCode,
                    "PTS 能力已在本进程内判定不可用（首次失败见 InnerException）—— 本闩只覆盖这一个具名条件",
                    _ptsUnavailable);
            }

            // Look for the first free PTS Context.
"""

PTSCACHE_E3_NEEDLE = """#pragma warning disable IDE0017
            // Create new PTS Context, if cannot find free one.
            if (index == _contextPool.Count)
            {
                _contextPool.Add(new ContextDesc());
                _contextPool[index].IsOptimalParagraphEnabled = ptsContext.IsOptimalParagraphEnabled;
                _contextPool[index].PtsHost = new PtsHost();
                _contextPool[index].PtsHost.Context = CreatePTSContext(index, textFormattingMode);
            }
#pragma warning restore IDE0017
"""
PTSCACHE_E3_REPL = """#pragma warning disable IDE0017
            // Create new PTS Context, if cannot find free one.
            if (index == _contextPool.Count)
            {
                // W86A `A2`：native 侧**累计入口调用数**的快照（判缺口是不是 native 亲口说的，见 catch）
                int ptsCallsBefore = WpfLinuxPtsGap.NativeCalls();
                ContextDesc created = null;      // 本次新建的池项（**按引用**认，不读它的状态）
                try
                {
                    created = new ContextDesc();
                    _contextPool.Add(created);
                    _contextPool[index].IsOptimalParagraphEnabled = ptsContext.IsOptimalParagraphEnabled;
                    _contextPool[index].PtsHost = new PtsHost();
                    _contextPool[index].PtsHost.Context = CreatePTSContext(index, textFormattingMode);
                }
                catch (Exception e)
                {
                    // ── W86A `A2` ①：**毒池项必须离开池**（`D-G78` 的根因）────────────────
                    //   上游把池项加进去（`:195`）、再把 `CreatePTSContext` 的返回值塞进
                    //   `PtsHost.Context`（`:198`）。中间任何一步抛异常 ⇒ 池里留下一条
                    //   `InUse == false` / `PtsHost.Context == IntPtr.Zero` 的半初始化项；
                    //   下一趟布局在 `:182-189` 的循环里把它当**空闲项**复用（跳过创建），
                    //   于是后面第一次问 `PtsHost.Context` 就撞
                    //   `Invariant.Assert(_context != IntPtr.Zero)` ⇒ `Invariant.FailFast`
                    //   ⇒ **`Environment.FailFast` 不可捕获 ⇒ rc=134**。
                    //
                    //   ⚠️⚠️ **判据只许用"对象身份"，一个字都不许读 `PtsHost.Context`**：
                    //       `PtsHost.Context` 的 **getter 自己就在断言** `_context != IntPtr.Zero`
                    //       （`PtsHost.cs:62-66`）—— 半初始化项**恰好**违反它 ⇒
                    //       用 `xxx.PtsHost.Context == IntPtr.Zero` 当"是不是半初始化"的判据，
                    //       **等于让修复自己在原地触发 `FailFast`**。
                    //       【本车道实测踩到】W86A 第一版就是这么写的，实测栈：
                    //         Invariant.FailFast ← PtsHost.get_Context ← PtsCache.AcquireContextCore
                    //       即 `D-G78` 那条链**被"修法"原样复现了一遍**（读数见 W86A 报告 §3）。
                    //   ⇒ 正确判据：`created` 是**本次刚 new 出来、刚 Add 进去的那一个对象引用**
                    //       （引用相等，`List<T>.Remove(T)` 就是按引用找），根本不需要读它的状态。
                    //       若 `_contextPool.Add` 自己抛（OOM）⇒ `created == null` ⇒ 不删（安全）。
                    if (created != null)
                    {
                        // 半初始化项若已建了 LS 罚分模块，它**已被 SuppressFinalize**
                        // ⇒ 必须在这里显式释放，否则泄漏（上游只在正常拆卸路径 Dispose）。
                        // ⚠️ `TextPenaltyModule` 是**字段**（不是属性）⇒ 读它不会触发任何断言。
                        created.TextPenaltyModule?.Dispose();
                        _contextPool.Remove(created);
                    }

                    // ── W86A `A2` ②：**具名能力闩**（失败**只**对"PTS 缺口"这一族立闩）──────
                    if (WpfLinuxPtsGap.IsPtsUnavailable(e, ptsCallsBefore))
                    {
                        _ptsUnavailable = WpfLinuxPtsGap.Describe(e);
                        throw _ptsUnavailable;
                    }
                    throw;          // 其它异常**原样传播**（不吞、不改名、不立闩）
                }
            }
#pragma warning restore IDE0017
"""

PTSCACHE_E0_NEEDLE = """using System.Threading;                         // Interlocked
"""
PTSCACHE_E0_REPL = """using System.Runtime.InteropServices;           // DllImport / 具名缺口台账（W86A）
using System.Threading;                         // Interlocked

using DllImport = MS.Internal.PresentationFramework.DllImport;
"""

PTSCACHE_E4_NEEDLE = """        #endregion Private Types
    }
}
"""
PTSCACHE_E4_REPL = """        #endregion Private Types
    }

    /// <summary>
    /// W86A（`TASK-0304`/`TASK-0305`）：**PTS 能力不可用**的具名异常。
    ///
    /// 【为什么需要一个新类型】上游把"PTS 建不起来"表达成好几种形态：
    ///   `EntryPointNotFoundException`（今天：符号根本不在 shim 里）、`DllNotFoundException`、
    ///   以及 A1 落地后的私有嵌套类型 `PTS.PtsException`（非零 `LsErr` ⇒ `PTS.Validate` 抛）。
    /// 其中 `PtsException` 是**上游的 private 嵌套类**（`Pts.cs:299`）⇒ 本工程**无法按类型引用它**。
    /// 于是今天**没有任何调用方**能只按类型说"这一页不支持"，只能去匹配消息串（本仓最忌讳）。
    /// 本类型把那个条件**命名**：谁接住 `PtsUnavailableException`，谁就是在处理"PTS 缺口"。
    /// </summary>
    internal sealed class PtsUnavailableException : Exception
    {
        internal PtsUnavailableException(string entry, int errorCode, string message, Exception inner)
            : base(message, inner)
        {
            Entry = entry;
            ErrorCode = errorCode;
        }

        /// <summary>缺口入口名（来自 native 侧的具名台账；取不到时是 "unknown"）。</summary>
        internal string Entry { get; }

        /// <summary>native 交回的 LsErr（A1 的 stub 恒为 -10000 = `tserrNotImplemented`）。</summary>
        internal int ErrorCode { get; }
    }

    /// <summary>
    /// W86A：把 native 侧的**具名缺口台账**接进托管侧的两条判据。
    /// 只做三件事：① 判"这次失败是不是 PTS 缺口"；② 把缺口**具名**；③ 打具名行。
    /// ⚠️ 它**不**决定任何降级动作，也**不**吞异常。
    ///
    /// 【判据为什么不是"异常类型表"】A1 落地后真正的异常是 `PTS.PtsException`（private 嵌套类，
    /// 引用不到）。所以判据改成**native 自己作证**：
    ///   `WpfLinuxWin32_PtsGapCalls()` 是 native 侧的**累计入口调用数**（`win32_pts.c` 的 `g_pts_seq`）。
    ///   在 `CreatePTSContext` 之前取一次快照、在 catch 里再取一次：
    ///     **涨了** ⟺ 这一次尝试真的走到过那 6 个入口 ⟺ 缺口是**原生侧亲口说的**
    ///   （不是我们猜的）。没涨 ⇒ 这个异常**与 PTS 缺口无关** ⇒ 不立闩、不改名、原样传播。
    ///   ⚠️ 旧 shim（没有这两个导出）下本函数返回 0 ⇒ 判据退化成"只认那三个 DllImport 异常族"，
    ///      而那时真正的失败恰好就是 `EntryPointNotFoundException` ⇒ 照样命中（不依赖新 shim）。
    /// </summary>
    internal static class WpfLinuxPtsGap
    {
        // ── 与 native 侧同名同形（`src/WpfGfx.Linux.Native/src/win32_pts.c`）──────────
        // `int WpfLinuxWin32_PtsGapCalls(void);`
        // `int WpfLinuxWin32_PtsGapReport(char *buf, int cap);` —— 写一行机读摘要，返回长度。
        // ⚠️ 形参用 `byte[]`（blittable）：**不用 Marshal**，也就不需要额外的 using；
        //    并且**每一次调用都包在 try 里** —— 旧 shim 没有这些导出 ⇒ `EntryPointNotFoundException`，
        //    绝不能让它盖掉真正的失败（"具名"是锦上添花，不是判据的前提）。
        [DllImport(DllImport.PresentationNative, EntryPoint = "WpfLinuxWin32_PtsGapCalls", ExactSpelling = true)]
        private static extern int PtsGapCallsNative();

        [DllImport(DllImport.PresentationNative, EntryPoint = "WpfLinuxWin32_PtsGapReport",
                   CharSet = CharSet.Ansi, ExactSpelling = true)]
        private static extern int PtsGapReportNative([Out] byte[] buf, int cap);

        /// <summary>native 侧累计入口调用数（快照用）。取不到 ⇒ 0。</summary>
        internal static int NativeCalls()
        {
            try { return PtsGapCallsNative(); }
            catch (Exception) { return 0; }
        }

        /// <summary>native 台账里"最近一条缺口"的入口名；取不到 ⇒ "unknown"（**不抛**）。</summary>
        private static string NativeEntryName()
        {
            string s = NativeReport();
            int i = s.IndexOf("last=", StringComparison.Ordinal);
            if (i < 0) return "unknown";
            i += 5;
            int j = s.IndexOf(' ', i);
            string name = (j < 0) ? s.Substring(i) : s.Substring(i, j - i);
            return string.IsNullOrEmpty(name) || name == "-" ? "unknown" : name;
        }

        /// <summary>native 台账里最近一条缺口的 LsErr；取不到 ⇒ A1 的常量。</summary>
        private static int NativeError()
        {
            string s = NativeReport();
            int i = s.IndexOf("err=", StringComparison.Ordinal);
            if (i < 0) return A1_STUB_ERR;
            i += 4;
            int j = i;
            if (j < s.Length && (s[j] == '-' || s[j] == '+')) j++;
            while (j < s.Length && s[j] >= '0' && s[j] <= '9') j++;
            return (j > i + 1) && int.TryParse(s.Substring(i, j - i), out int v) ? v : A1_STUB_ERR;
        }

        private static string NativeReport()
        {
            try
            {
                byte[] buf = new byte[256];
                if (PtsGapReportNative(buf, buf.Length) <= 0) return string.Empty;
                int n = 0;
                while (n < buf.Length && buf[n] != 0) n++;
                char[] c = new char[n];
                for (int k = 0; k < n; k++) c[k] = (char)buf[k];
                return new string(c);
            }
            catch (Exception) { return string.Empty; }
        }

        /// <summary>判：这次失败是不是"PTS 能力不可用"（**闭集**：DllImport 三族 ∪ native 亲口作证）。</summary>
        internal static bool IsPtsUnavailable(Exception e, int nativeCallsBefore)
        {
            if (e is EntryPointNotFoundException          // 符号不在 shim 里（A1 之前 / 旧 shim）
                || e is DllNotFoundException              // shim 整个没找到
                || e is BadImageFormatException)          // shim 不是可装载的 ELF
            {
                return true;
            }
            // native 侧的累计入口调用数**涨了** ⇒ 这一次尝试真的问过 PTS 上下文族
            return NativeCalls() > nativeCallsBefore;
        }

        // A1 的 stub 唯一取值（= 上游 `Pts.cs:507` `tserrNotImplemented`）
        private const int A1_STUB_ERR = -10000;

        /// <summary>把失败**具名**（入口名/错误码来自 native 台账；读不到就如实写 unknown）。</summary>
        internal static PtsUnavailableException Describe(Exception e)
        {
            string entry = NativeEntryName();
            int err = NativeError();
            string msg = "PTS 能力不可用（PTS / 原生 LineServices 未实现 —— D-G70）：entry=" + entry
                       + " err=" + err.ToString("0")
                       + " ⇒ 本次布局**如实失败**，不假装成功";
            return new PtsUnavailableException(entry, err, msg, e);
        }
    }

    /// <summary>
    /// W86A `A3`：把"这一页不支持"打到日志（**不许静默**）。一行、每个视图一次、带入口名。
    /// </summary>
    internal static class WpfLinuxPtsGapTrace
    {
        internal static void Report(string site, PtsUnavailableException e)
        {
            try
            {
                System.Console.Error.WriteLine(
                    "[PTS-UNAVAILABLE] site=" + site + " entry=" + (e.Entry ?? "unknown")
                    + " err=" + e.ErrorCode.ToString("0")
                    + " action=page-placeholder（已画出页级占位；进程继续）");
                System.Console.Error.Flush();
            }
            catch (Exception)
            {
                // 打印失败不许改变行为（例如 stderr 已关闭）。
            }
        }
    }
}
"""

PTSCACHE_EDITS = [
    (PTSCACHE_E0_NEEDLE, PTSCACHE_E0_REPL, 1),
    (PTSCACHE_E1_NEEDLE, PTSCACHE_E1_REPL, 1),
    (PTSCACHE_E2_NEEDLE, PTSCACHE_E2_REPL, 1),
    (PTSCACHE_E3_NEEDLE, PTSCACHE_E3_REPL, 1),
    (PTSCACHE_E4_NEEDLE, PTSCACHE_E4_REPL, 1),
]


# ── FlowDocumentView.Linux.cs 的四处改动（`A3`：页级可见降级）──────────────────
#  【为什么落在这里】`FlowDocumentView` 是 `FlowDocument` 的**底流（bottomless）**呈现宿主，
#    `FlowDocumentScrollViewer`（= hc「流文档」页的缺省页签）走的就是它（`FlowDocumentView.cs:344`
#    `_document.BottomlessFormatter`）。它也已经是 `sealed override MeasureOverride/ArrangeOverride`，
#    即**唯一的测量/摆放收口** ⇒ 在这里接住具名异常，能同时做到"不空白、不重入、不进 _formatter"。
FDV_E1_NEEDLE = """            else if (Document != null)
            {
                // Create bottomless formatter, if necessary.
                EnsureFormatter();

                // Format bottomless content.
                _formatter.Format(constraint);
"""
FDV_E1_REPL = """            else if (Document != null)
            {
                // ── W86A `A3`（`D-G70`）：PTS 不可用 ⇒ **页级具名占位** ──────────────────
                //   ① 已判定过 ⇒ 直接给占位尺寸，**不再进 formatter**（幂等：一次失败只降级一次
                //      ⇒ 不会每次 Measure 都抛一次，也不会重入布局）；
                //   ② 第一次 ⇒ 只接 `PtsUnavailableException` 这**一个具名条件**
                //      （**不是** catch-all：别的异常原样向上传播）。
                if (_ptsUnavailable != null)
                {
                    return PtsGapPlaceholderSize;
                }

                // ⚠️ `EnsureFormatter()` **必须在 try 之内**：PTS 上下文是它**间接**建的
                //   （`_document.BottomlessFormatter` → `FlowDocumentFormatter..ctor`
                //     → `FlowDocumentPage..ctor` → `StructuralCache.Section` → `PtsContext..ctor`
                //     → `PtsCache.AcquireContext`），第一跳根本不在 `Format()` 里。
                //   【本车道实测踩到】W86A 第一版把 try 只罩住 `Format()` ⇒ 异常从
                //   `EnsureFormatter()` 逃出去（实测栈见 W86A 报告 §3），占位一次都没画。
                try
                {
                    // Create bottomless formatter, if necessary.
                    EnsureFormatter();

                    // Format bottomless content.
                    _formatter.Format(constraint);
                }
                catch (PtsUnavailableException ptsGap)
                {
                    _ptsUnavailable = ptsGap;
                    WpfLinuxPtsGapTrace.Report("FlowDocumentView.MeasureOverride", ptsGap);
                    InvalidateVisual();              // ⇒ 走 OnRender 的占位分支（非零墨，不是空白）
                    return PtsGapPlaceholderSize;
                }
"""
FDV_E5_NEEDLE = """        internal FlowDocumentPage DocumentPage
        {
            get
            {
                if (_document != null)
                {
                    EnsureFormatter();
                    return _formatter.DocumentPage;
                }
                return null;
            }
        }
"""
FDV_E5_REPL = """        internal FlowDocumentPage DocumentPage
        {
            get
            {
                if (_document != null)
                {
                    // W86A `A3`：这是**第三个**会撞 PTS 的入口（`DocumentPageTextView..ctor`
                    // 走它：`_page = owner.DocumentPage`），而它的第一跳同样是 `EnsureFormatter()`。
                    // 接住并**返回 null**（那个 ctor 只做 `if (_page is IServiceProvider)` ⇒ null 安全）
                    // —— 目的是"**别让具名异常从这里逃出去**"，而不是"假装有页面"。
                    if (_ptsUnavailable != null) return null;
                    try
                    {
                        EnsureFormatter();
                        return _formatter.DocumentPage;
                    }
                    catch (PtsUnavailableException ptsGap)
                    {
                        _ptsUnavailable = ptsGap;
                        WpfLinuxPtsGapTrace.Report("FlowDocumentView.DocumentPage", ptsGap);
                        InvalidateVisual();
                        return null;
                    }
                }
                return null;
            }
        }
"""
FDV_E6_NEEDLE = """                if (Document != null)
                {
                    // Create bottomless formatter, if necessary.
                    EnsureFormatter();

                    // Arrange bottomless content.
"""
FDV_E6_REPL = """                if (Document != null)
                {
                    // Create bottomless formatter, if necessary.
                    // W86A `A3`：`ArrangeOverride` 与 `MeasureOverride` **同一条第一跳**
                    // （同样的 `EnsureFormatter()`）⇒ 也必须接住，否则在"先摆后量"的顺序下照样逃逸。
                    try
                    {
                        EnsureFormatter();
                    }
                    catch (PtsUnavailableException ptsGap)
                    {
                        _ptsUnavailable = ptsGap;
                        WpfLinuxPtsGapTrace.Report("FlowDocumentView.ArrangeOverride", ptsGap);
                        InvalidateVisual();
                        return arrangeSize;
                    }

                    // Arrange bottomless content.
"""
FDV_E2_NEEDLE = """            Size safeArrangeSize = arrangeSize;

            if (!_suspendLayout)
            {
"""
FDV_E2_REPL = """            Size safeArrangeSize = arrangeSize;

            // W86A `A3`：PTS 不可用 ⇒ 只摆占位（`_formatter.DocumentPage` 无效，**一个字段都不许碰**）
            if (_ptsUnavailable != null)
            {
                return arrangeSize;
            }

            if (!_suspendLayout)
            {
"""
FDV_E3_NEEDLE = """        protected override Visual GetVisualChild(int index)
        {
            if (index != 0)
            {
                throw new ArgumentOutOfRangeException(nameof(index), index, SR.Visual_ArgumentOutOfRange);
            }
            return _pageVisual;
        }

        #endregion Protected Methods
"""
FDV_E3_REPL = """        protected override Visual GetVisualChild(int index)
        {
            if (index != 0)
            {
                throw new ArgumentOutOfRangeException(nameof(index), index, SR.Visual_ArgumentOutOfRange);
            }
            return _pageVisual;
        }

        /// <summary>
        /// W86A `A3`（`D-G70`）：PTS 不可用时的**页级具名占位** —— 洋红矩形 + 黑边框 + 三行自述文字。
        ///
        /// 【判据读的就是这里的三件事】① **非零墨**：洋红像素数 &gt; 0（"空白"与"已降级"因此**可机读区分**）；
        /// ② **具名**：页面上直接写着"不支持"与缺口入口名（人眼可读，不必翻日志）；
        /// ③ **零墨差**：`_ptsUnavailable == null`（也就是**所有正常页**）时本方法**立即返回**
        ///    ⇒ 正常页的像素**一个都不变**（这是"零回归"能被机器证明的那一半）。
        ///
        /// ⚠️ 这不是"渲染出了文档"：它画的是"**我渲染不出来，原因是这个**"。
        /// </summary>
        protected override void OnRender(DrawingContext drawingContext)
        {
            if (_ptsUnavailable == null) return;      // 正常路径：零墨差（不许改变任何正常页）
            if (drawingContext == null) return;

            Rect box = new Rect(0, 0, PtsGapPlaceholderSize.Width, PtsGapPlaceholderSize.Height);
            // 洋红（`Brushes.Magenta` = #FFFF00FF）是本移植里"能力缺口占位"的保留色。
            drawingContext.DrawRectangle(Brushes.Magenta, new Pen(Brushes.Black, 2.0), box);

            string[] lines = new string[]
            {
                "此页不支持：PTS / 原生 LineServices 未实现（D-G70 / D-G78）",
                "NOT SUPPORTED on this port: PTS is not implemented.",
                "entry=" + (_ptsUnavailable.Entry ?? "unknown")
                    + "  err=" + _ptsUnavailable.ErrorCode.ToString(CultureInfo.InvariantCulture),
            };
            double dip = VisualTreeHelper.GetDpi(this).PixelsPerDip;
            double y = 8;
            for (int i = 0; i < lines.Length; i++)
            {
                FormattedText ft = new FormattedText(
                    lines[i],
                    CultureInfo.CurrentUICulture,
                    FlowDirection.LeftToRight,
                    new Typeface("DejaVu Sans"),
                    i == 0 ? 14.0 : 12.0,
                    Brushes.Black,
                    dip);
                ft.MaxTextWidth = Math.Max(1.0, PtsGapPlaceholderSize.Width - 20.0);
                drawingContext.DrawText(ft, new Point(10.0, y));
                y += ft.Height + 4.0;
            }
        }

        #endregion Protected Methods
"""
FDV_E4_NEEDLE = """        private bool _suspendLayout;                // Layout of the page is suspended.
"""
FDV_E4_REPL = """        private bool _suspendLayout;                // Layout of the page is suspended.

        // W86A `A3`：null = PTS 路径正常（**正常路径的唯一取值**）；非 null = 本视图已降级为具名占位。
        // ⚠️ 它是**视图级**的幂等闩（与 `PtsCache` 的进程级闩各管一段）：进程级闩保证"不再进 native"，
        //    视图级闩保证"不再进 formatter、只画出占位一次"。
        private PtsUnavailableException _ptsUnavailable;
"""

FDV_EDITS = [
    (FDV_E1_NEEDLE, FDV_E1_REPL, 1),
    (FDV_E2_NEEDLE, FDV_E2_REPL, 1),
    (FDV_E3_NEEDLE, FDV_E3_REPL, 1),
    (FDV_E4_NEEDLE, FDV_E4_REPL, 1),
    (FDV_E5_NEEDLE, FDV_E5_REPL, 1),
    (FDV_E6_NEEDLE, FDV_E6_REPL, 1),
]

# 占位尺寸（Draw 与 Measure 用**同一个**值 ⇒ 不会出现"量出来了但没画到"）
FDV_SIZE_NEEDLE = """        internal FlowDocumentView()
        {
        }
"""
FDV_SIZE_REPL = """        // W86A `A3`：页级占位尺寸（Measure 与 OnRender 共用同一个值）。
        private static readonly Size PtsGapPlaceholderSize = new Size(440.0, 132.0);

        internal FlowDocumentView()
        {
        }
"""

FDV_EDITS.append((FDV_SIZE_NEEDLE, FDV_SIZE_REPL, 1))

# `CultureInfo` 在本文件里没有 using（上游只用 `FlowDirection` 等）⇒ 补一条
FDV_USING_NEEDLE = """using System.Windows;                       // Size
"""
FDV_USING_REPL = """using System.Globalization;                 // CultureInfo（W86A A3 的占位文字）
using System.Windows;                       // Size
"""
FDV_EDITS.insert(0, (FDV_USING_NEEDLE, FDV_USING_REPL, 1))


def materialize_derived():
    """生成补丁 C 的两个派生源文件。needle 校验失败 ⇒ 抛（由 main 转成 rc≠0）。"""
    made = []
    a, n = _apply_edits(UP_PF + "MS/Internal/PtsHost/PtsCache.cs", "PtsCache.Linux.cs", PTSCACHE_EDITS)
    made.append((a, n))
    b, n = _apply_edits(UP_PF + "MS/Internal/documents/FlowDocumentView.cs",
                        "FlowDocumentView.Linux.cs", FDV_EDITS)
    made.append((b, n))
    return made


def main():
    # ① 先materialize产出派生源（**先于** csproj 接线：源没产出就不该接线）
    try:
        made = materialize_derived()
    except RuntimeError as e:
        print("[失败] 派生源生成失败：%s" % e)
        return 1
    for path, n in made:
        print("[OK] 生成 %s（%d 处改动，needle 全部命中）" % (os.path.relpath(path, REPO), n))

    with open(CSPROJ, encoding="utf-8") as f:
        text = f.read()

    # 幂等：先摘掉上一次注入的整块
    if BEGIN in text:
        i = text.index(BEGIN)
        j = text.index(END) + len(END) + 1
        text = text[:i] + text[j:]

    if MARKER not in text:
        print("[失败] csproj 里找不到 Sdk.targets import 锚点，请检查生成物")
        return 1

    block = BEGIN + "\n" + PATCH_A + "\n" + PATCH_B + "\n" + PATCH_C + "\n" + END + "\n"
    text = text.replace(MARKER, block + MARKER)
    with open(CSPROJ, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"[OK] 已注入补丁 A/B/C → {CSPROJ}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

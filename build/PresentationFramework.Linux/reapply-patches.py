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
                        // ── 格 1（`TASK-0302`／`t12`）：installed-objects 现在**真的是**本地对象 ──────
                        //   格 0 时 `CreateInstalledObjectsInfo` 恒失败 ⇒ `InstalledObjects` 恒 `IntPtr.Zero`
                        //   ⇒ 这条 catch **没有东西可漏**。格 1 让它真的分配之后，上游**唯一**的释放口
                        //   （`DestroyPTSContexts`，`PtsCache.cs:331-332`）**被这条 catch 绕过了**
                        //   ⇒ 不补这一句就是"每失败一次漏一块"（native 侧 `installed_objects_live` 看得见）。
                        //   ⚠️ `InstalledObjects` 是**字段**（`PtsCache.cs:793 internal IntPtr InstalledObjects;`）
                        //      ⇒ 读它**不触发任何断言**（与 `PtsHost.Context` 那条 getter 断言不同，见上）。
                        if (created.InstalledObjects != IntPtr.Zero)
                            PTS.IgnoreError(PTS.DestroyInstalledObjectsInfo(created.InstalledObjects));
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

PTSCACHE_E4_NEEDLE = '''        #endregion Private Types
    }
}
'''
PTSCACHE_E4_REPL = '''        #endregion Private Types
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

        // ⏪ `t87` 加：**缺口名册的专用读口**（native 侧现取 `win32_pts.c`：`PtsGapCount()` ＝ `g_pts_calls[i] > 0`
        //   的条数；`PtsGapEntryName(idx, buf, cap)` ＝ **按在册表序**第 `idx` 个「有缺口计数」的入口名，成功 `1`／无此 idx `0`）。
        //   ⚠️ 这两个导出在**旧 shim** 上没有 ⇒ 每次调用都包在 `try` 里（与上面同款：具名是锦上添花，不许盖掉真失败）。
        [DllImport(DllImport.PresentationNative, EntryPoint = "WpfLinuxWin32_PtsGapCount", ExactSpelling = true)]
        private static extern int PtsGapCountNative();

        [DllImport(DllImport.PresentationNative, EntryPoint = "WpfLinuxWin32_PtsGapEntryName",
                   CharSet = CharSet.Ansi, ExactSpelling = true)]
        private static extern int PtsGapEntryNameNative(int idx, [Out] byte[] buf, int cap);

        /// <summary>native 侧累计入口调用数（快照用）。取不到 ⇒ 0。</summary>
        internal static int NativeCalls()
        {
            try { return PtsGapCallsNative(); }
            catch (Exception) { return 0; }
        }

        /// <summary>native 缺口台账里**在册表序**最后一个"有缺口计数"的入口名；取不到 ⇒ "unknown"（**不抛**）。</summary>
        // ⏪ `t90`（2026-09-29）**注释-实现对齐**（`t88` 的 `F-4`；原注释写"最近一条缺口"＝**最近调用**，与实现不符）：
        //   现取 native 原文（`win32_pts.c`，行号仅本次有效）：`WpfLinuxWin32_PtsGapEntryName()` ＝ `for (i = 0; i < COUNT; i++)
        //   if (g_pts_calls[i] <= 0) continue; …` ⇒ **按 `k_pts_entries[]` 表序**；而 `wpf_pts_frontier()` ＝ 按 `k_pts_call_order[]`
        //   **调用序**筛 `g_pts_seen[]`。两者**都不是**"最近一次调用"（native 侧根本没有记 recency）。
        //   ⇒ 多缺口态下二者会给出**不同**名字（`t90` 现取：先调 idx7 `LoAcquirePenaltyModule`、后调 idx4 `GetFloaterHandlerInfo`
        //   ⇒ ②路/`anchor=` 给表序名，`frontier=` 给调用序名，"最近调用的"是 `GetFloaterHandlerInfo` 而 ②路给 `LoAcquirePenaltyModule`）。
        private static string NativeEntryName()
        {
            string s = NativeReport();
            // ⏪ `t87`：口径**现取**（`t81` 把 native 行压形成 `anchor=`／`frontier=`；更早的形是 `last=`）：
            //   ① 报表旧形 `last=` ＝ **缺口名册的末名**（最贴近台账 `PTS_GAP entry=<名>`）；
            //   ② **缺口名册专用读口**（`PtsGapCount()`／`PtsGapEntryName(idx)`；`idx = count-1` ＝ **在册表序最后一个有缺口计数**的入口）
            //      —— `g_pts_calls[]` 的口径**只对走 `wpf_pts_gap()` 的 stub 涨**（真实现不涨）⇒ 这才是"缺口"口径；
            //   ③ 报表 `anchor=` ＝ 在册表序**第一个有缺口计数**的入口名（同一缺口口径的另一端）；
            //   ④ 兜底 `frontier=` ＝ `g_pts_seen[]` 的**被问过**口径（真实现也算）—— **不是缺口名**，只在①②③全空时用，且此处如实注明。
            //   四者都取不到 ⇒ `unknown`（**不猜**）。
            // ⏪ `t90`：②路改走 `GapEntryNameAt()`（**带长度纪律**，见该方法的注释）—— 读口本身**可能静默截断**（`F-3`）。
            // ⏪ `t109`（2026-09-29）**`t105` 的 `F-1`（medium）＋ `P1-ptsname-result.md` §8 裁定十二补：多缺口态下不许指错人**。
            //   **现场（`t105` 现取）**：本波第一次同时有两条缺口（台账 `PTS_GAP entry=CreateDocContext seq=5` 与
            //   `entry=LoDisposePenaltyModule seq=6`），而 ②路 `idx = count-1` ⇒ **表序末名** ⇒ 托管
            //   `[PTS-UNAVAILABLE] … entry=` **两次都写 `LoDisposePenaltyModule`**、`CreateDocContext` **一次都没写**
            //   ⇒ 会把第四步靶心（`CreateDocContext`）的功劳记到别人头上。
            //   **新口径（逐字）**：托管侧改取**在册表序第一个有缺口计数的入口名**。理由是**结构事实**：
            //   `k_pts_entries[]` **本身按调用链次序排列**（installed-objects → doc-context → floater/table → Lo* 族 → dispose），
            //   故"表序首"＝**链上最早那一站**＝台账口径（`^PTS_GAP entry=` 行按 `seq=` 排序取最早）下的「**下一跳**」。
            //   多缺口时它与"表序末名"**不同**；而"最近一次缺口调用"在本现场**恰好是另一站** ⇒ 若取它，`CreateDocContext`
            //   仍永远不会被点名，`F-1` 的病**没治**。
            //   ⚠️ **限制如实记**：native 报表**不暴露 recency**（现取字段只有 `anchor=`／`frontier=`／逐条 `calls=`），
            //   且 `src/**` 不在本件写域 ⇒ 托管侧**无法**按"最近一次调用"取名；本件用的是上面那条**表序＝链序**的结构事实。
            //   取值顺序（逐字）：① 旧形 `last=` → ② **`anchor=`（表序首个有缺口计数的入口名）** → ③ **`GapEntryNameAt(0)`**
            //   （老 shim 无 `anchor=` 时同义；带长度纪律）→ ④ 表序末名 `GapEntryNameAt(count-1)`（**仅当**②③都取不到时**兜底**，
            //   保持旧行为）→ ⑤ 兜底 `frontier=`（`g_pts_seen[]` 的**被问过**口径，**不是缺口名**，此处如实注明）→ ⑥ `unknown`（**不猜**）。
            foreach (string key in new string[] { "last=" })
            {
                string nm0 = FieldOf(s, key);
                if (nm0 != null) return nm0;
            }
            foreach (string key in new string[] { "anchor=" })
            {
                string nmA = FieldOf(s, key);
                if (nmA != null) return nmA;
            }
            try
            {
                string nmF = GapEntryNameAt(0, GapNameCap);            // ③ 表序**首个**（＝链上最早那一站）
                if (nmF != null) return nmF;
                int cnt = PtsGapCountNative();
                if (cnt > 0)
                {
                    string nm1 = GapEntryNameAt(cnt - 1, GapNameCap);  // ④ 表序末名：仅兜底（旧行为）
                    if (nm1 != null) return nm1;
                }
            }
            catch (Exception) { }
            foreach (string key in new string[] { "frontier=" })
            {
                string nm2 = FieldOf(s, key);
                if (nm2 != null) return nm2;
            }
            return "unknown";
        }

        /// <summary>`<键>=<值>` 取值（`值` 到空格或串尾；`-`／`unknown`／空 ⇒ `null`；不抛）。</summary>
        private static string FieldOf(string s, string key)
        {
            if (string.IsNullOrEmpty(s)) return null;
            int i = s.IndexOf(key, StringComparison.Ordinal);
            if (i < 0) return null;
            i += key.Length;
            int j = s.IndexOf(' ', i);
            string name = (j < 0) ? s.Substring(i) : s.Substring(i, j - i);
            return (string.IsNullOrEmpty(name) || name == "-" || name == "unknown") ? null : name;
        }

        /// <summary>nul 结尾字节缓冲 ⇒ 串（不抛）。</summary>
        private static string CStr(byte[] b)
        {
            int n = 0;
            while (n < b.Length && b[n] != 0) n++;
            char[] c = new char[n];
            for (int k = 0; k < n; k++) c[k] = (char)b[k];
            return new string(c);
        }

        /// <summary>缺口名册读口的缓冲长度（**写死**；只有"缓冲有富余"的读数才可信，见 `GapEntryNameAt`）。</summary>
        // ⏪ `t90` 现取：现册最长名 `LoGetPenaltyModuleInternalHandle` ＝ 31 B，《128》有 96 B 富余 ⇒ 富余判据**必真**；
        //   一旦名册出现 ≥127 B 的名字，富余判据会**保守**判"截断 ⇒ unknown"（宁可误报 unknown，不许误信截断名）。
        // ⏪ `t95`（2026-09-29）**`t91` 的 `G-4`：数字更正（逐字，实测现取）**——上一段的 `31 B`／`96 B` **写错**：
        //   现取该名长度 ＝ **32 B**（`awk` 对 `src/WpfGfx.Linux.Native/src/win32_pts.c` 的 `k_pts_entries[]` 逐名取长，
        //   `sort -rn | head -1` ⇒ `32 LoGetPenaltyModuleInternalHandle`；名册共 12 名）⇒ 128 − 32 ＝ **95 B** 富余。
        //   **结论不变**（富余判据在现册必真）；被纠正的只是数字。**原句一字未删**（只增不改），以本段为准。
        private const int GapNameCap = 128;

        /// <summary>带**长度纪律**的缺口名册读口：拿到可信名 ⇒ 该名；截断/越界/形状不合 ⇒ `null`（**不抛**）。</summary>
        // ⏪ `t90`（2026-09-29）**`t88` 的 `F-3`**：native `WpfLinuxWin32_PtsGapEntryName()` 现取原文（`win32_pts.c`，行号仅本次有效）
        //   ＝ `snprintf(buf, (size_t)cap, "%s", k_pts_entries[i]); return 1;` —— **无长度检查**：`cap` 不够时
        //   `snprintf` 静默截断，**仍然返回 1** ⇒ 调用方会拿到**貌似完整的短名**（`cap=5 ⇒ rc=1 name="LoAc"`）。
        //   这在判据面比 `unknown` **更坏**：`unknown` 是诚实的"没读到"，而截断名是一个**看起来可归因的假名**
        //   —— 判据按"名字在不在册"对拍 ⇒ 若某次截断恰好落在**名册里另一个真名**上，就会**假绿**（现状名册 12 名无
        //   前缀包含对 ⇒ 今日现实风险是"假红"而非"假绿"，但这是**名册的偶然性**，不是纪律）。
        //   **纪律（逐字）**：① 只用**富余**读数 —— `strlen(buf) < cap-1`（`snprintf` 截断时字符串长度恒为 `cap-1`
        //   ⇒ 长度等于 `cap-1` 一律**不信**，宁可保守判 `unknown`；名字恰好 `cap-1` 长时也判 `unknown`，属**收紧**）；
        //   ② 名字必须是**入口名形状**（C 标识符）—— 名册里的名字全是这种形，挡住截断产生的怪异串；
        //   ③ 两条任一不满足 ⇒ `null`（调用方回落到 ③/④ 或最终 `unknown`）—— **绝不许**返回截断名。
        //   ⚠️ native 侧的**真修法**（`t88` 建议的"长度不足返 0"）需要改 `src/**`（本件写域**不含**它）⇒ 本件只把纪律落在
        //   **托管侧读口**（判据实际消费的就是这个值），native 侧的加固与建议补丁见载体 `P1-entry-attribution-fix2-report.md`。
        //   ⏩ 事实上 `t92`（P1-W20）**已在 native 侧落地真修**：`WpfLinuxWin32_PtsGapEntryName()` 现在"放不下 ⇒ `0` ＋ 空串"
        //   （`cap ≤ 名长` ⇒ `rc=0`），只读 128/95 B 富余档 ⇒ `rc=1` 全名。
        // ⏪ `t95`（2026-09-29）**`t91` 的 `G-5`：保守边界口径句（不改实现）**。本读口的 ①富余判据是
        //   `nm.Length >= cap - 1 ⇒ null` ⇒ **`cap == 名长 + 1`（native 恰好放得下、`t92` 后也会给全名）同样被判 `null`**
        //   （`t91` 夹具实测：`cap=23 ⇒ <null>`、`cap=24` 才给名）。这是**刻意的保守**，理由三条：
        //    (i) **跨 shim 世代的安全网**：`t92` 之前的那代 `.so` 仍会"截断 ＋ `rc=1`"（`cap=5 ⇒ name="LoAc"`）⇒ 只要本读口
        //        可能落到**旧 shim** 上，`rc==1` 就**不足以**证明"拿到的是全名"；本判据不依赖 native 版本。
        //    (ii) **代价在现盘为零**：生产路 `cap=GapNameCap=128`，现册最长名 **32 B** ⇒ 富余 **95 B** ⇒"恰好放得下"这一档
        //         **在生产不可达**（只有夹具才会把 cap 调到 23/24）。
        //    (iii) 方向正确：多收一档 `null` 是**误报 unknown（收紧）**，而它换掉的是"误信截断名（假绿）"的可能。
        //   ⇒ **实现不动**（改成本该更"准"的"`rc==1` 即真名"会**失去 (i)**：对旧 shim 立刻退化回 `F-3` 的假绿灯）;
        //      若将来确认部署面**永不**加载 `t92` 之前的 shim，可另派单把 ① 放宽为"`rc==1` ⇒ 信"，届时 `cap=23/24` 两档应同值。
        internal static string GapEntryNameAt(int idx, int cap)
        {
            try
            {
                if (cap < 8) return null;                       // 连最短真名都放不下 ⇒ 不读
                byte[] nb = new byte[cap];
                if (PtsGapEntryNameNative(idx, nb, nb.Length) != 1) return null;   // 越界/无此 idx ⇒ 0
                string nm = CStr(nb);
                if (string.IsNullOrEmpty(nm)) return null;
                if (nm.Length >= cap - 1) return null;          // ① 富余判据：长度顶到 cap-1 ⇒ 可能截断 ⇒ 不信
                if (!IsEntryNameShape(nm)) return null;         // ② 形状判据
                return nm;
            }
            catch (Exception) { return null; }
        }

        /// <summary>从 DllImport 三族的异常文本里取**入口名**（取不到 ⇒ `"unknown"`；不抛）。</summary>
        // ⏪ 措辞分支 ＋ 形状校验（`t87`，2026-09-28；现场：旧实现「取最后一个单引号串＋`dll:` 前缀」**无形状校验**
        //   ⇒ 把**入口名**当成库名，产出 `dll:NotImplemented` 这种**不可归因的合成名** ⇒ 判据 `domains=unattributable` 必红）。
        //   **新口径（逐字）**：① 入口名措辞（`named 'X'`；Windows 形 `in DLL 'Y'` ／ Linux 形 `in shared library 'Y'`）
        //   ⇒ 取**入口名原样**（不加前缀），且**必须**是 C 标识符形状（挡掉 `dll:`／路径／含 `:` 的合成串）；
        //      `t95`（`G-2`）：**形状不合 ⇒ 落到②路继续看**（不再整串掐掉；形状合则先返回，入口名优先）。
        //   ② 库名措辞（`Unable to load shared library 'Y'`／`Unable to load DLL 'Y'`／`in shared library 'Y'`／`in DLL 'Y'`）
        //   ⇒ 取库名、去目录、加 `dll:` 前缀，且**只接受真库名形状**（`*.dll`／`*.so`／`*.so.<纯数字段>…`；`t90` 放宽后
        //      **不要求 `lib` 前缀**，见 `IsLibraryNameShape` 的逐字口径）；措辞命中而形状不合 ⇒ **继续扫后面三条**（`t90`，`F-2`）。
        //   ③ 其余（两条路都取不到合法形状）⇒ **`unknown`** —— **绝不许**合成不可归因名。
        private static string EntryNameFromException(Exception e)
        {
            try
            {
                if (e == null) return "unknown";
                string msg = e.Message ?? string.Empty;

                // ① 入口名措辞：`… named 'X' in DLL 'Y'`／`… named 'X' in shared library 'Y'`
                int a = msg.IndexOf("named '", StringComparison.Ordinal);
                if (a >= 0)
                {
                    int b = msg.IndexOf('\\'', a + 7);
                    if (b > a + 7)
                    {
                        string entry = msg.Substring(a + 7, b - a - 7);
                        if (IsEntryNameShape(entry)) return entry;
                    }
                    // ⏪ `t95`（2026-09-29）**`t91` 的 `G-2`：不再短路**。旧码在这里 `return "unknown"` ⇒ 与 `t90` 改过的
                    //   ②路（措辞形状不合 ⇒ `continue`）**不对称**：现场夹具 `"… named 'Lo Ac' in DLL 'x.dll'."` 里
                    //   后段 `in DLL 'x.dll'` 是**合法库名措辞**，却因前段形状不合被整串掐掉。
                    //   新口径：①路**形状不合**只说明"这条入口名措辞给不出可用名" ⇒ **落到②路**继续按库名措辞取；
                    //   ①路**形状合** 仍**先返回**（入口名优先，不被库名盖掉）；②路依旧逐条做**库名形状**校验
                    //   ⇒ 本改动**不产生**"把真入口名当库名"的通路（取回的仍是 `dll:<库名>`，或最终 `unknown`）。
                }

                // ② 库名措辞（四种措辞并列；命中即**只在真库名形状**下加前缀）
                string[] libWording = new string[]
                {
                    "Unable to load shared library '",
                    "Unable to load DLL '",
                    "in shared library '",
                    "in DLL '",
                };
                foreach (string w in libWording)
                {
                    int p = msg.IndexOf(w, StringComparison.Ordinal);
                    if (p < 0) continue;
                    int q = msg.IndexOf('\\'', p + w.Length);
                    if (q > p + w.Length)
                    {
                        string lib = msg.Substring(p + w.Length, q - p - w.Length);
                        int sl = lib.LastIndexOf('/');
                        string baseName = sl >= 0 ? lib.Substring(sl + 1) : lib;
                        if (IsLibraryNameShape(baseName)) return "dll:" + baseName;
                    }
                    // ⏪ `t90`（2026-09-29）**`t88` 的 `F-2`：不再短路**。旧码在本措辞"命中但形状不合"时直接
                    //   `return "unknown"` ⇒ **掐掉后面三条措辞**（现场：`'NotImplemented'` 在前段命中即返回，
                    //   同串后段的 `in DLL 'x.dll'` 这次**合法**归因机会被丢掉）。新口径：本措辞给不出合法库名
                    //   ⇒ 只说明**这条措辞**不作数，**继续扫后面三条**；四条全试完仍无合法库名 ⇒ 末尾统一 `unknown`。
                    //   （闭合引号缺失同理 ⇒ 继续扫，不掐整串；形状校验一格都没放松。）
                    continue;
                }
            }
            catch (Exception) { }
            return "unknown";
        }

        /// <summary>入口名形状：C 标识符（首字符字母/`_`，其余字母数字/`_`）—— 挡掉 `dll:`／路径／含 `:` 的合成串。</summary>
        private static bool IsEntryNameShape(string s)
        {
            if (string.IsNullOrEmpty(s)) return false;
            if (!(char.IsLetter(s[0]) || s[0] == '_')) return false;
            for (int i = 1; i < s.Length; i++)
            {
                char ch = s[i];
                if (!(char.IsLetterOrDigit(ch) || ch == '_')) return false;
            }
            return true;
        }

        /// <summary>库名形状：基名（已去目录）必须形如 `&lt;茎&gt;.dll` 或 `&lt;茎&gt;.so`／`&lt;茎&gt;.so.&lt;数字段&gt;…`。</summary>
        // ⏪ `t90`（2026-09-29）**`t88` 的 `F-1`：形状放宽到本栈真件名形**。旧码要求 `.so` 形**必须**以 `lib` 起头
        //   ⇒ 本栈真件 `wpfgfx_cor3.so`（在册证据 `evidence/five_pre_g1.txt`：`wpfgfx_cor3.so=4e25e4b27d4d5ae1`）
        //   被判 **`unknown`**，`lib.so` 亦然。新口径**逐字**：
        //   ① **字符面**：只许 `[A-Za-z0-9_.+-]`（挡掉空格／`:`／`=`／`'`／路径分隔符／控制字符）；
        //   ② `*.dll`（大小写不敏感）：茎非空（`t87` 原样，未动）；
        //   ③ `*.so`：茎非空，**不要求 `lib` 前缀**（`wpfgfx_cor3.so` ⇒ **收**）；
        //   ④ `*.so.<数字段>(.<数字段>)…`：`.so` 后**纯数字**段（`libfoo.so.1`／`libfoo.so.1.2` ⇒ 收；`libfoo.so.x`／`libfoo.so.1.beta` ⇒ 拒）；
        //   ⑤ 其余一律 **false** —— 无 `.so`／`.dll` 后缀者（`NotImplemented`／`foo.bar`／`v1.2`／`x.txt`）、
        //      茎为空者（`.so`）、`.so` 后无点者（`foo.sox`）全拒。
        //   **没有**放宽到"任何带点的串"：判据的实质是**后缀**（`.so`／`.so.<纯数字>…`／`.dll`）＋ 字符面，
        //   不是"含点即收"。形状仍然只是**形状**（不证明名字真存在于本栈）⇒ 归因仍靠判据件的在册对拍。
        // ⏪ `t95`（2026-09-29）**`t91` 的 `G-3`：点分段纪律（收紧）**。`t90` 那版只查字符面 ⇒ `a..so`（空段）、
        //   `-x.so`／`+x.so`（前导符号）、`a...so`、`x.-1.so` 全被判 **true**（与注释"茎非空"的字面不符）。
        //   **新增两条（逐字）**：⑥ 按 `.` 切分后**每段非空**（挡 `a..so`／`a...so`／`.so`）；⑦ **每段首字符必须是
        //   字母/数字/`_`**（挡 `-x.so`／`+x.so`／`x.-1.so` 这类以 `-`／`+`／`.` 起头的段）——`-`／`+` 仍**许出现在段内**
        //   （`libfoo-1.2.so`／`libstdc++.so.6` 必须继续收）。⇒ 这是**收紧**：新增拒格全是过去误收的空壳名。
        private static bool IsLibraryNameShape(string s)
        {
            if (string.IsNullOrEmpty(s)) return false;
            string t = s.ToLowerInvariant();
            if (t[0] == '.') return false;                                                // 茎不许以点起头（`..so` 这类空壳拒）
            for (int i = 0; i < t.Length; i++)
            {
                char ch = t[i];
                if (!(char.IsLetterOrDigit(ch) || ch == '_' || ch == '.' || ch == '+' || ch == '-')) return false;
            }
            // ⑥⑦ 点分段纪律（`t95`／`G-3`）：段非空 ＋ 每段首字符 ∈ 字母/数字/`_`
            string[] parts = t.Split('.');
            for (int i = 0; i < parts.Length; i++)
            {
                if (parts[i].Length == 0) return false;
                char c0 = parts[i][0];
                if (!(char.IsLetterOrDigit(c0) || c0 == '_')) return false;
            }
            if (t.EndsWith(".dll", StringComparison.Ordinal)) return t.Length > 4;
            if (t.EndsWith(".so", StringComparison.Ordinal)) return t.Length > 3;          // 茎非空即可，**不要求 `lib`**
            int so = t.LastIndexOf(".so.", StringComparison.Ordinal);
            if (so > 0)
            {
                string rest = t.Substring(so + 4);                                        // `.so.` 之后的数字段
                if (rest.Length == 0) return false;
                string[] seg = rest.Split('.');
                for (int i = 0; i < seg.Length; i++)
                {
                    if (seg[i].Length == 0) return false;
                    for (int k = 0; k < seg[i].Length; k++) if (!char.IsDigit(seg[i][k])) return false;
                }
                return true;
            }
            return false;
        }

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
                // ⏪ 长度纪律（`t87`，2026-09-28；现场：`t81` 让台账有行后本串变长 ⇒ 旧码定长 `byte[256]` ⇒ 整条读不到，
                //   `NativeEntryName()` 退回 `unknown` ⇒ `Describe()` 只能去异常文本里取数 ⇒ 那一路又产出过合成名）。
                //   native 侧**返回约定**（现取原文，`src/WpfGfx.Linux.Native/src/win32_pts.c`）：
                //     `if (n < 0 || n >= cap) { buf[cap - 1] = '\\0'; return -1; }` ／ `return n;`
                //   ⇒ `>0` ＝ **写入长度**；`-1` ＝ **写不下**（**不截断、不静默**，`buf` 已被终结）
                //   ⇒ 读不全的**唯一信号是 `-1`** ⇒ **放大缓冲重试**（`256 → 4 KiB → 64 KiB`，上限写死 `64 KiB`）。
                // ⏪ `t90`（2026-09-29）**`t88` 的 `O-1` 口径句**：`-1` 那一支 native **已经把 `buf[cap-1] = '\\0'` 写掉**
                //   ⇒ "写不下"时 `buf` 里是一条**被截断的、以 nul 结尾的行**（不是空串！现取夹具：`cap=250/251/256`
                //   ⇒ 末字节均 0）。⇒ **忽略 `rc` 的读者会读到一条貌似完整的短行**（与 `F-3` 同族）。托管侧一律以
                //   `rc <= 0 ⇒ continue` 为准（**先看 `rc`，再看 `buf`**），本处即此纪律；`NativeReport()` 之外若有人
                //   直调 `PtsGapReportNative` 也必须照此判。**绝不许**把 `buf` 的 nul 结尾当作"读到了一条完整行"的证据。
                for (int cap = 256; cap <= 65536; cap *= 16)
                {
                    byte[] buf = new byte[cap];
                    int rc = PtsGapReportNative(buf, buf.Length);
                    if (rc <= 0) continue;                        // `-1` ⇒ 写不下 ⇒ 放大再试
                    int n = 0;
                    while (n < buf.Length && buf[n] != 0) n++;
                    char[] c = new char[n];
                    for (int k = 0; k < n; k++) c[k] = (char)buf[k];
                    return new string(c);
                }
                return string.Empty;                              // `64 KiB` 仍写不下 ⇒ 如实"读不到"（不猜）
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
        // ⏪ `t90`（2026-09-29）**`t88` 的 `F-5` 口径句（只登记，不改值）**：本常量与 native 侧真值
        //   `WPF_PTS_ERR_NOT_IMPLEMENTED`（现取 `src/WpfGfx.Linux.Native/src/win32_pts.c`：`#define WPF_PTS_ERR_NOT_IMPLEMENTED (-10000)`）
        //   **同值** ⇒ `NativeError()` 读不到时回落本常量，**读到时**真值也是它 ⇒ **`err=` 面无法自证"到底读到了没有"**
        //   （旧件"读不到"与新件"读到"都打 `err=-10000`）。**本件不改值**：`err=-10000` 是在册面（`leg_*.env` 的
        //   `native_err=-10000`、判据件与台账行都用它），改成"域外哨兵"会**改动判据面** ⇒ 需另派单（改哨兵须同趟
        //   与判据件/在册证据对齐）。⇒ 今日的"读到没读到"只能由**旁边那几格**作证（`entry=`／`native_gap=`／
        //   `PTS_GAP entry=…` 台账行），**不许**只看 `err=`。
        private const int A1_STUB_ERR = -10000;

        /// <summary>把失败**具名**（入口名/错误码来自 native 台账；读不到就如实写 unknown）。</summary>
        internal static PtsUnavailableException Describe(Exception e)
        {
            string entry = NativeEntryName();
            // ⏪ 取数补齐（队长 2026-09-28；`t70` 复核的推荐形态）：native 台账在此刻**必为零行**
            //   （本链第一个会留痕的站 `PTS.CreateDocContext` 还没走到）⇒ 只读台账只会得 `unknown`。
            //   而入口名/**就在原始异常里**（DllImport 三族的 `Message` 自带入口名/DLL 名）⇒ 从此处补一格取数，
            //   使 `entry=` 面**具名**（不带后缀：名字原样，便于与名册直接对拍；来源只记在 msg 里）。
            bool entryFromException = false;
            if (entry == "unknown")
            {
                string fromEx = EntryNameFromException(e);
                // ⏪ `t87`：`EntryNameFromException()` 的"取不到"哨兵由**空串**改为 **`"unknown"`**
                //   （与 `NativeEntryName()` 的哨兵一致 ⇒ 判据侧只认一个哨兵值）；此处按哨兵判，不再按"非空"判。
                if (!string.IsNullOrEmpty(fromEx) && fromEx != "unknown") { entry = fromEx; entryFromException = true; }
            }
            int err = NativeError();
            string msg = "PTS 能力不可用（PTS / 原生 LineServices 未实现 —— D-G70）：entry=" + entry
                       + (entryFromException ? "（入口名取自异常文本：native 台账此行未留痕）" : "")
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

    // ══════════════════════════════════════════════════════════════════
    //  ⏪ `t155`（P1-W71 第二跳·第三拍）测量小单 —— `nmp` **托管侧类型**的**只读**仪器
    //
    //  唯一问题：native 侧 `+136 → +168` 吃下的那个 `nmp`，在**托管侧**到底是**什么东西**？
    //    `PtsContext.HandleToObject(nmp)` 的**实际类型**／是否 `BaseParagraph` 族／是否 `ISegment`。
    //
    //  形制照 `t133` 的 `[FSCBK-CANARY]`：**只读**——不写任何字段、不改任何行为、
    //  真实委托的**返回值与 out/ref 参数逐位透传**；失败只打 `NOINFO` 行，绝不静默。
    //
    //  安全性（写死）：`PtsContext.HandleToObject` 内部是三条 `Invariant.Assert`
    //  （`Invariant.FailFast` **不可捕获**）⇒ 本仪器**先**用 `IsValidHandle`
    //  （有界检查、越界返回 false、**不断言**）把门，**只有**它说"活句柄"才查表 ⇒ 断言恒真。
    //  查表与打印全程 `try/catch`；异常只打 `NOINFO`。
    //
    //  预算（写死）：甲＝`GetFirstPara`、乙＝`GetParaProperties`、丙＝`GetNextPara` 各 12 行，
    //  到点打一行 `[NMP-TYPE-CAP]`（防日志过 MB）。`PTS_NMPTYPE_OFF=1` 关掉**打印**
    //  （接线与透传不变）。
    // ══════════════════════════════════════════════════════════════════
    internal static class P1NmpTypeProbe
    {
        private static readonly object _lock = new object();
        private static System.Reflection.PropertyInfo _ctxProp;
        private static bool _ctxPropDone;
        private static int _leftA = 12, _leftB = 12, _leftC = 12;
        private static bool _capA, _capB, _capC;
        private static bool _off, _offKnown;

        private static bool Off()
        {
            if (!_offKnown)
            {
                _offKnown = true;
                try { _off = System.Environment.GetEnvironmentVariable("PTS_NMPTYPE_OFF") == "1"; }
                catch (Exception) { _off = false; }
            }
            return _off;
        }

        private static string Hex(IntPtr h) { return "0x" + ((long)h).ToString("x"); }

        private static PtsContext ContextOf(PtsHost host)
        {
            try
            {
                if (_ctxProp == null && !_ctxPropDone)
                {
                    _ctxPropDone = true;
                    _ctxProp = typeof(PtsHost).GetProperty("PtsContext",
                        System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance
                        | System.Reflection.BindingFlags.Public);
                }
                if (_ctxProp == null || host == null) return null;
                return _ctxProp.GetValue(host, null) as PtsContext;
            }
            catch (Exception) { return null; }
        }

        private static object Lookup(PtsContext ctx, IntPtr h, out string why)
        {
            why = "no-context";
            if (ctx == null) return null;
            try
            {
                if (!ctx.IsValidHandle(h)) { why = "not-a-live-handle"; return null; }
                object o = ctx.HandleToObject(h);
                if (o == null) { why = "handle-obj-null"; return null; }
                return o;
            }
            catch (Exception e) { why = "lookup-threw:" + e.GetType().Name; return null; }
        }

        private static System.Reflection.FieldInfo FindField(System.Type t, string name)
        {
            try
            {
                while (t != null)
                {
                    System.Reflection.FieldInfo fi = t.GetField(name,
                        System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance
                        | System.Reflection.BindingFlags.Public);
                    if (fi != null) return fi;
                    t = t.BaseType;
                }
            }
            catch (Exception) { }
            return null;
        }

        // 单个句柄的**只读**描述：实际类型 ＋ 两个"是不是" ＋（可达时）`_firstChild` 一格
        private static string Desc(PtsContext ctx, IntPtr h, string tag)
        {
            if (h == IntPtr.Zero) return tag + "=(nil)";
            string why;
            object o = Lookup(ctx, h, out why);
            if (o == null) return tag + "=" + Hex(h) + " TYPE=NOINFO reason=" + why;
            System.Type t = o.GetType();
            bool isSeg = false;
            try
            {
                foreach (System.Type i in t.GetInterfaces())
                {
                    if (i.FullName == "System.Windows.Documents.ISegment" || i.Name == "ISegment") { isSeg = true; break; }
                }
            }
            catch (Exception) { }
            string s = tag + "=" + Hex(h) + " TYPE=" + t.FullName
                + " " + tag + "_isBaseParagraph=" + (o is BaseParagraph ? "1" : "0")
                + " " + tag + "_isISegment=" + (isSeg ? "1" : "0");
            System.Reflection.FieldInfo fi = FindField(t, "_firstChild");
            if (fi == null) return s + " " + tag + "_firstChild=FIELD-ABSENT";
            object child = null;
            try { child = fi.GetValue(o); } catch (Exception) { }
            return s + " " + tag + "_firstChild=" + (child == null ? "null" : child.GetType().FullName);
        }

        // 成对读数：`nms`（段）与 `nmp`（段内首段）的**对象同一性**——回答"`nmp` 是不是 `_firstChild`"
        private static string Pair(PtsContext ctx, IntPtr nms, IntPtr nmp)
        {
            if (nms == IntPtr.Zero || nmp == IntPtr.Zero) return " PAIR=NOINFO reason=handle-zero";
            string w1, w2;
            object seg = Lookup(ctx, nms, out w1);
            object par = Lookup(ctx, nmp, out w2);
            if (seg == null || par == null) return " PAIR=NOINFO reason=seg-or-para-not-live(" + w1 + "/" + w2 + ")";
            System.Reflection.FieldInfo fi = FindField(seg.GetType(), "_firstChild");
            if (fi == null) return " PAIR=NOINFO reason=firstchild-field-absent seg=" + seg.GetType().FullName;
            object child = null;
            try { child = fi.GetValue(seg); } catch (Exception) { }
            return " PAIR seg=" + seg.GetType().FullName
                + " seg_firstChild=" + (child == null ? "null" : child.GetType().FullName)
                + " nmp_eq_seg_firstChild=" + (child != null && ReferenceEquals(child, par) ? "1" : "0");
        }

        private static bool Take(string which)
        {
            lock (_lock)
            {
                if (which == "A")
                {
                    if (_leftA > 0) { _leftA--; return true; }
                    if (!_capA) { _capA = true; Emit("[NMP-TYPE-CAP] slot=GetFirstPara 打印预算到点（后续同槽不再打）"); }
                    return false;
                }
                if (which == "B")
                {
                    if (_leftB > 0) { _leftB--; return true; }
                    if (!_capB) { _capB = true; Emit("[NMP-TYPE-CAP] slot=GetParaProperties 打印预算到点（后续同槽不再打）"); }
                    return false;
                }
                if (_leftC > 0) { _leftC--; return true; }
                if (!_capC) { _capC = true; Emit("[NMP-TYPE-CAP] slot=GetNextPara 打印预算到点（后续同槽不再打）"); }
                return false;
            }
        }

        private static void Emit(string line)
        {
            try
            {
                System.Console.Error.WriteLine(line);
                System.Console.Error.Flush();
            }
            catch (Exception) { }
        }

        private static void Print(PtsHost host, string which, string slot, string detail, IntPtr nms, IntPtr nmp)
        {
            if (Off()) return;
            if (!Take(which)) return;
            string line;
            try
            {
                PtsContext ctx = ContextOf(host);
                line = "[NMP-TYPE] slot=" + slot + " " + detail
                    + " " + Desc(ctx, nms, "nms")
                    + " " + Desc(ctx, nmp, "nmp")
                    + Pair(ctx, nms, nmp);
            }
            catch (Exception e)
            {
                line = "[NMP-TYPE] slot=" + slot + " " + detail + " NOINFO reason=instrument-threw:" + e.GetType().Name;
            }
            Emit(line);
        }

        // ── 三个槽的**透传**包装（返回值/out/ref 参数与原方法逐位相同）──────────────
        internal static int GetFirstPara(PtsHost host, IntPtr pfsclient, IntPtr nms, out int fSuccessful, out IntPtr nmp)
        {
            int fserr = host.GetFirstPara(pfsclient, nms, out fSuccessful, out nmp);
            Print(host, "A", "GetFirstPara", "fserr=" + fserr + " fSucc=" + fSuccessful, nms, nmp);
            return fserr;
        }

        internal static int GetNextPara(PtsHost host, IntPtr pfsclient, IntPtr nms, IntPtr nmpCur, out int fFound, out IntPtr nmpNext)
        {
            int fserr = host.GetNextPara(pfsclient, nms, nmpCur, out fFound, out nmpNext);
            Print(host, "C", "GetNextPara", "fserr=" + fserr + " fFound=" + fFound + " nmpCur=" + Hex(nmpCur), nms, nmpNext);
            return fserr;
        }

        internal static int GetParaProperties(PtsHost host, IntPtr pfsclient, IntPtr nmp, ref PTS.FSPAP fspap)
        {
            int fserr = host.GetParaProperties(pfsclient, nmp, ref fspap);
            Print(host, "B", "GetParaProperties", "fserr=" + fserr, IntPtr.Zero, nmp);
            return fserr;
        }
    }
}
'''

# ── `t155`（P1-W71 第二跳·第三拍）仪器：三个读槽改接只读透传包装（现盘手加块，现封进生成器）───
PTSCACHE_E5_NEEDLE = '''            contextInfo.fscbk.cbkgen.pfnGetFirstPara = new PTS.GetFirstPara(ptsHost.GetFirstPara);
            contextInfo.fscbk.cbkgen.pfnGetNextPara = new PTS.GetNextPara(ptsHost.GetNextPara);
'''
PTSCACHE_E5_REPL = '''            // ⏪ `t155` 测量小单：三个**读**槽改接**只读**仪器（透传原方法返回值；实现见文件末 `P1NmpTypeProbe`）
            //    ⚠️ 记账（写死）：接线面的**封送指针**因此换代 ⇒ `[FSCBK-CANARY]` 的槽值只准**同趟内**互比。
            contextInfo.fscbk.cbkgen.pfnGetFirstPara = new PTS.GetFirstPara(
                (IntPtr p1, IntPtr p2, out int o1, out IntPtr o2) => P1NmpTypeProbe.GetFirstPara(ptsHost, p1, p2, out o1, out o2));
            contextInfo.fscbk.cbkgen.pfnGetNextPara = new PTS.GetNextPara(
                (IntPtr p1, IntPtr p2, IntPtr p3, out int o1, out IntPtr o2) => P1NmpTypeProbe.GetNextPara(ptsHost, p1, p2, p3, out o1, out o2));
'''
PTSCACHE_E5B_NEEDLE = '''            contextInfo.fscbk.cbkgen.pfnGetParaProperties = new PTS.GetParaProperties(ptsHost.GetParaProperties);
'''
PTSCACHE_E5B_REPL = '''            contextInfo.fscbk.cbkgen.pfnGetParaProperties = new PTS.GetParaProperties(
                (IntPtr p1, IntPtr p2, ref PTS.FSPAP o1) => P1NmpTypeProbe.GetParaProperties(ptsHost, p1, p2, ref o1));
'''

# ── `t133`（P1-W55）仪器：ConnectCallbacks 末的只读度量调用 + T133DumpFscbkCanary 方法群（现盘手加块）───
PTSCACHE_E6_NEEDLE = '''            contextInfo.fscbk.cbktxt.pfnGetDurFigureAnchor = new PTS.GetDurFigureAnchor(ptsHost.GetDurFigureAnchor);
        }
'''
PTSCACHE_E6_REPL = '''            contextInfo.fscbk.cbktxt.pfnGetDurFigureAnchor = new PTS.GetDurFigureAnchor(ptsHost.GetDurFigureAnchor);
            // ⏪ `t133`（P1-W55）测量小单 —— **托管侧只读仪器**（调用点）：装配**完成之后**打
            //   `[FSCBK-CANARY] …` 机读行（实测偏移 ＋ 每个槽的真实封送值），供 native 侧按**同一
            //   偏移**做**只读回读**、逐字节对拍。⚠️ **只打印**：不写任何字段、**不调用**任何回调。
            T133DumpFscbkCanary(ref contextInfo);
        }

        // ════════════════════════════════════════════════════════════════════════════════
        // ⏪ `t133`（P1-W55）测量小单 —— `FSCONTEXTINFO.fscbk` / `FSCBKGEN` 槽偏移的**托管侧仪器**
        //
        //   **为什么需要它**：`FSCONTEXTINFO.fscbk` 是一张 **103 槽、按值嵌入**的回调表（实测
        //   `Marshal.SizeOf(FSCBK)` ＝ 824 ＝ 103×8）；它的**槽偏移**是本族"驱动链"的钥匙，而
        //   **native 侧没有仪器**能测它（夹具＝自证循环；`dladdr` 分不出槽；试调错槽＝崩；拿伪造
        //   `nms`/`nmp` 调真槽 ⇒ 托管侧 `HandleToObject` ⇒ **`Invariant.FailFast` 不可捕获**）。
        //   ⇒ 由**托管侧**给出 ① 运行期布局 API 的**实测偏移**（`Marshal.OffsetOf`/`SizeOf`）
        //     ② 每个槽的**真实封送值**（canary）：`cbkgen` 的槽是委托 ⇒ 打
        //     `Marshal.GetFunctionPointerForDelegate`（＝本进程内该委托会被封送成的函数指针）；
        //     `cbkobj` 的前三槽与整个 `cbkwrd` 声明为 `IntPtr` 且**未接线** ⇒ 打原始值（应为 0）。
        //
        //   **边界（写死）**：本仪器**只读**——不写 `contextInfo` 任何字段、**不调用**任何回调、
        //   不改任何行为、不影响 `return`；失败（反射拿不到类型）只打 `NOINFO` 行，绝不静默。
        //   **表述纪律**：这些读数的绿**只准**读成"偏移测量有了可复核的机器证据"，
        //   **不许**读成"驱动链已通"或"排版打通"。
        // ════════════════════════════════════════════════════════════════════════════════
        private static void T133DumpFscbkCanary(ref PTS.FSCONTEXTINFO info)
        {
            try
            {
                int offFscbk  = T133Off(typeof(PTS.FSCONTEXTINFO), "fscbk");
                int offCbkgen = T133Off(typeof(PTS.FSCBK), "cbkgen");
                int offCbktxt = T133Off(typeof(PTS.FSCBK), "cbktxt");
                int offCbkobj = T133Off(typeof(PTS.FSCBK), "cbkobj");
                int offCbkfig = T133Off(typeof(PTS.FSCBK), "cbkfig");
                int offCbkwrd = T133Off(typeof(PTS.FSCBK), "cbkwrd");
                int szCtx = (int)Marshal.SizeOf(typeof(PTS.FSCONTEXTINFO));
                int szFscbk = (int)Marshal.SizeOf(typeof(PTS.FSCBK));
                System.Console.Error.WriteLine(
                    "[FSCBK-CANARY] sizeof_ctx=" + szCtx + " sizeof_fscbk=" + szFscbk +
                    " fscbk=" + offFscbk + " cbkgen=" + offCbkgen + " cbktxt=" + offCbktxt +
                    " cbkobj=" + offCbkobj + " cbkfig=" + offCbkfig + " cbkwrd=" + offCbkwrd +
                    " sizeof_gen=" + (int)Marshal.SizeOf(typeof(PTS.FSCBKGEN)) +
                    " sizeof_obj=" + (int)Marshal.SizeOf(typeof(PTS.FSCBKOBJ)) +
                    " sizeof_wrd=" + (int)Marshal.SizeOf(typeof(PTS.FSCBKWRD)));

                Type gt = typeof(PTS.FSCBKGEN), ot = typeof(PTS.FSCBKOBJ), wt = typeof(PTS.FSCBKWRD);
                T133Slot("cbkgen.pfnFSkipPage",          offFscbk + offCbkgen + T133Off(gt, "pfnFSkipPage"),          info.fscbk.cbkgen.pfnFSkipPage);
                T133Slot("cbkgen.pfnGetNextSection",     offFscbk + offCbkgen + T133Off(gt, "pfnGetNextSection"),     info.fscbk.cbkgen.pfnGetNextSection);
                T133Slot("cbkgen.pfnGetSectionProperties", offFscbk + offCbkgen + T133Off(gt, "pfnGetSectionProperties"), info.fscbk.cbkgen.pfnGetSectionProperties);
                T133Slot("cbkgen.pfnGetMainTextSegment", offFscbk + offCbkgen + T133Off(gt, "pfnGetMainTextSegment"), info.fscbk.cbkgen.pfnGetMainTextSegment);
                T133Slot("cbkgen.pfnGetFirstPara",       offFscbk + offCbkgen + T133Off(gt, "pfnGetFirstPara"),       info.fscbk.cbkgen.pfnGetFirstPara);
                T133Slot("cbkgen.pfnGetNextPara",        offFscbk + offCbkgen + T133Off(gt, "pfnGetNextPara"),        info.fscbk.cbkgen.pfnGetNextPara);
                T133Slot("cbkgen.pfnGetParaProperties",  offFscbk + offCbkgen + T133Off(gt, "pfnGetParaProperties"),  info.fscbk.cbkgen.pfnGetParaProperties);
                T133Slot("cbkgen.pfnCreateParaclient",   offFscbk + offCbkgen + T133Off(gt, "pfnCreateParaclient"),   info.fscbk.cbkgen.pfnCreateParaclient);
                T133Slot("cbkgen.pfnTransferDisplayInfo", offFscbk + offCbkgen + T133Off(gt, "pfnTransferDisplayInfo"), info.fscbk.cbkgen.pfnTransferDisplayInfo);
                T133Slot("cbkgen.pfnDestroyParaclient",  offFscbk + offCbkgen + T133Off(gt, "pfnDestroyParaclient"),  info.fscbk.cbkgen.pfnDestroyParaclient);
                // 「未接线槽」的位置指纹（声明是 IntPtr、源码里**未赋值** ⇒ 实测必须读到 0）
                T133Ptr("cbkobj.pfnNewPtr",     offFscbk + offCbkobj + T133Off(ot, "pfnNewPtr"),     info.fscbk.cbkobj.pfnNewPtr);
                T133Ptr("cbkobj.pfnDisposePtr", offFscbk + offCbkobj + T133Off(ot, "pfnDisposePtr"), info.fscbk.cbkobj.pfnDisposePtr);
                T133Ptr("cbkobj.pfnReallocPtr", offFscbk + offCbkobj + T133Off(ot, "pfnReallocPtr"), info.fscbk.cbkobj.pfnReallocPtr);
                T133Ptr("cbkwrd.pfnGetSectionHorizMargins", offFscbk + offCbkwrd + T133Off(wt, "pfnGetSectionHorizMargins"), info.fscbk.cbkwrd.pfnGetSectionHorizMargins);
                System.Console.Error.Flush();
            }
            catch (Exception e)
            {
                System.Console.Error.WriteLine("[FSCBK-CANARY] NOINFO reason=" + e.GetType().Name + ":" + e.Message);
            }
        }

        private static int T133Off(Type t, string f)
        {
            try { return (int)Marshal.OffsetOf(t, f); }
            catch (Exception e) { System.Console.Error.WriteLine("[FSCBK-CANARY] NOINFO off_fail " + t.Name + "." + f + " " + e.GetType().Name); return -1; }
        }

        private static void T133Slot<T>(string name, int abs, T d) where T : Delegate
        {
            string fp = (d == null) ? "NULL" : ("0x" + Marshal.GetFunctionPointerForDelegate<T>(d).ToInt64().ToString("x16"));
            System.Console.Error.WriteLine("[FSCBK-CANARY] slot=" + name + " abs=" + abs + " fp=" + fp + " wired=" + (d == null ? "no" : "yes"));
        }

        private static void T133Ptr(string name, int abs, IntPtr p)
        {
            System.Console.Error.WriteLine("[FSCBK-CANARY] slot=" + name + " abs=" + abs + " raw=0x" + p.ToInt64().ToString("x16") + " wired=no");
        }
'''

PTSCACHE_EDITS = [
    (PTSCACHE_E0_NEEDLE, PTSCACHE_E0_REPL, 1),
    (PTSCACHE_E1_NEEDLE, PTSCACHE_E1_REPL, 1),
    (PTSCACHE_E2_NEEDLE, PTSCACHE_E2_REPL, 1),
    (PTSCACHE_E3_NEEDLE, PTSCACHE_E3_REPL, 1),
    (PTSCACHE_E4_NEEDLE, PTSCACHE_E4_REPL, 1),
    (PTSCACHE_E5_NEEDLE, PTSCACHE_E5_REPL, 1),
    (PTSCACHE_E5B_NEEDLE, PTSCACHE_E5B_REPL, 1),
    (PTSCACHE_E6_NEEDLE, PTSCACHE_E6_REPL, 1),
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

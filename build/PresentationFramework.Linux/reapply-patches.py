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


def main():
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

    block = BEGIN + "\n" + PATCH_A + "\n" + PATCH_B + "\n" + END + "\n"
    text = text.replace(MARKER, block + MARKER)
    with open(CSPROJ, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"[OK] 已注入补丁 A/B → {CSPROJ}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

// 自产 WPF 程序集的**身份版本**——WPF-on-Linux 全项目共用的一个 shim。
//
// ── 为什么必须有这个文件 ────────────────────────────────────────────────
// net10.0 的框架里带一份**同名空门面**：
//   ~/.dotnet/shared/Microsoft.NETCore.App/10.0.11/WindowsBase.dll （16 KB，
//   AssemblyVersion 4.0.0.0，只有 1 个 TypeDef + 30 个 ExportedType 类型转发）
// 而我们的自产 WindowsBase 因上游 csproj 沿用 `GenerateAssemblyInfo=false`，
// 默认 AssemblyVersion = 0.0.0.0。于是：
//   · 编译期：SDK 的引用冲突解析按「版本高者胜」**静默丢弃**我们的
//     `<Reference><HintPath>`，报错只表现为 `System.Windows.Interop.MSG` CS0234
//     （完全看不出是 HintPath 失效）；
//   · 运行期：host 绑回 4.0.0.0 门面 → TypeLoadException（门面没有真实类型）。
// 实测反证：把版本抬到 4.0.0.1 后，同一程序立刻绑定到 app-local 自产程序集，
// MSG 正常解析（详见 handoff U2 专节 / build/Directory.Upstream.props 的注释）。
//
// 因此：**自产 WPF 程序集的 AssemblyVersion 必须严格大于 4.0.0.0**。
//
// ── 为什么是 10.0.0.0（L2 身份对齐；`WIN-INTEROP.md` §7.3 / §7.5）────────
// 4.0.0.1 只是"比门面高"的下界；它比**官方 net8/net10** 的 `8.0.0.0` / `10.0.0.0`
// **低** ⇒ 在 Windows 上按官方身份编出来的**库包**（其 `AssemblyRef` 请求 10.0.0.0）
// 默认绑不上本栈的自产件（`FileNotFoundException 0x80070002`）。
// 抬到官方对齐的 `10.0.0.0`：
//   · 仍严格大于框架门面的 4.0.0.0 ⇒ `build/Directory.Upstream.props` 的
//     「丢弃同名门面引用」逻辑（按**同名**触发，与数值无关）**照旧需要且照旧成立**；
//   · 满足 .NET 的绑定规则「找到的版本 ≥ 请求的版本」：
//     请求 4.0.0.0/4.0.0.1（旧自产件）/8.0.0.0/10.0.0.0（官方 net8/net10）**全部绑得上**。
// 令牌不在此文件（由各 csproj 的 `AssemblyOriginatorKeyFile` 决定）。
//
// ── 为什么手写属性而不是打开 GenerateAssemblyInfo ───────────────────────
// 上游源码自带 LibraryAssemblyInfo.cs / GlobalUsings.cs 等属性文件，打开 SDK
// 自动生成会与它们重复（CS0579）。这里只补版本三属性，其余一律不动。
// 已核实：本工程编译集内不存在其它 AssemblyVersion/AssemblyFileVersion/
// AssemblyInformationalVersion 声明（唯一一处 `Shared/Tracing/mcwpf/mcwpf.cs`
// 不在任何 *.Linux 工程的编译列表里）。

using System.Reflection;

[assembly: AssemblyVersion("10.0.0.0")]
[assembly: AssemblyFileVersion("10.0.0.0")]
[assembly: AssemblyInformationalVersion("10.0.0.0-wpf-linux")]

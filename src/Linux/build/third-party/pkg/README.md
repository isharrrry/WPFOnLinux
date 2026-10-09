# WpfLinux.Sdk

在 Linux 上编译 WPF 工程所需的自产 WPF 栈，打成 NuGet 包。

## 接入（消费方）

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="WpfLinux.Sdk" Version="1.0.0" />
  </ItemGroup>
</Project>
```

`TargetFramework`（`net10.0` 或 `net10.0-windows`）必须由工程自己写 —— restore 需要它先于包可见。
其余（`OutputType=WinExe`、`UseWPF=false`、XAML 编译器、`App.xaml`/`*.xaml` 默认清单、OOB 依赖）
由包的 `buildTransitive/WpfLinux.Sdk.props|targets` 提供。不想要默认 XAML 清单就设
`<EnableDefaultWpfLinuxItems>false</EnableDefaultWpfLinuxItems>` 并自己列 `ApplicationDefinition`/`Page`。

### 源码树模式（把"链接外部源码树"的清单也交给包）

```xml
<WpfLinuxSrcTree>$(MSBuildProjectDirectory)/srctree</WpfLinuxSrcTree>
<EnableDefaultCompileItems>false</EnableDefaultCompileItems>
```

于是自动收集 `$(WpfLinuxSrcTree)/**/*.cs`（→`Compile`）、`App.xaml`（→`ApplicationDefinition`；
`OutputType=Library` 时改作 `Page`——库工程不允许 `ApplicationDefinition`）、其余 `**/*.xaml`
（→`Page`，`Link` 去掉源码树前缀）、`**/*.resx`（→`EmbeddedResource`）。
排除用（值写全路径，可用 `$(WpfLinuxSrcTree)` 变量；`Exclude` 同时作用于 `Compile` 与 `Page`）：

```xml
<WpfLinuxSrcTreeExclude>$(WpfLinuxSrcTree)/DAL/**;…</WpfLinuxSrcTreeExclude>
<WpfLinuxSrcTreePageExclude>$(WpfLinuxSrcTree)/Plot/TY.xaml</WpfLinuxSrcTreePageExclude>
```

⚠️ 源码树**必须位于工程目录之下**（软链接即可）：XAML 编译器用工程目录当 SourceDir，
不在其下就取不到相对路径（多个同名 `.xaml` 会生成同名 `.g.cs` 互相覆盖）。
⚠️ 要同时设 `EnableDefaultCompileItems=false`，否则 SDK 的 `**/*.cs` 默认项会顺着软链接把同一批
源码再加一遍（CS2002 噪音；实测 104 条）。

### 官方借用件（Ribbon / WinForms 系，可选）

自产 WPF 栈里没有 Ribbon / WinForms 家族（`System.Windows.Controls.Ribbon`、`System.Windows.Forms`
及 `System.Windows.Forms.Primitives`/`WindowsFormsIntegration`/`System.Drawing.Common`/
`System.Private.Windows.Core`/`System.Private.Windows.GdiPlus`），业务真用到才需要。包里带了一份
（`borrow/`，取自 RT 的 `refruntime/`：官方引用件去掉 `ReferenceAssemblyAttribute`，元数据不动，
故**编译期与运行期共用同一身份**）。要用就设一行：

```xml
<WpfLinuxOfficialBorrows>true</WpfLinuxOfficialBorrows>
```

## 包内布局

| 路径 | 内容 |
|---|---|
| `lib/net10.0/` | 自产 WPF 栈（`WindowsBase` … `PresentationFramework`、主题件、`DirectWrite.Linux.Provider`、`System.Windows.Extensions` 的 Linux 替身） |
| `tools/net10.0/PresentationBuildTasks.dll` | 自产 XAML 编译器（`_PresentationBuildTasksAssembly`） |
| `runtimes/linux-x64/native/` | `libwpfwin32.so`、`libwpfwic.so`、`wpfgfx_cor3.so` |
| `borrow/` | 官方借用件（Ribbon / WinForms 系 7 件），默认不引，见上 |
| `buildTransitive/` | 接线：属性 + `Microsoft.WinFX.targets` import |

## 原生库为什么要"两份"

`libwpfwin32.so` / `libwpfwic.so` / `wpfgfx_cor3.so` 既是 RID native assets（`runtimes/linux-x64/native/`），
也会被包的 targets **复制到输出根目录**（`WpfLinuxSdkDeployNativeShims`，`AfterTargets=Build`）。
原因是 `Win32ShimResolver` 只在"应用目录"里找 `libwpfwin32.so`，不认 RID 子目录 —— 实测（仓外干净目录）
少了这一步，应用启动即 `DllNotFoundException: …'kernel32.dll' 已映射到 libwpfwin32.so，但没找到可加载的 shim 库`。
不想要这份复制就设 `<WpfLinuxSdkDeployNativeShims>false</WpfLinuxSdkDeployNativeShims>`。

## 包不做的事（已知边界）

* **官方借用件默认不生效**：Ribbon / WinForms 系 7 件虽在包内 `borrow/`，但默认不引（只有业务真用到
  Ribbon/WinForms 的工程才需要），要显式设 `<WpfLinuxOfficialBorrows>true</WpfLinuxOfficialBorrows>`。
  它们只有**元数据**（引用件的方法体是空实现）：XAML 解析时"按类型名找程序集"这一步被满足，
  真去**执行** Ribbon/WinForms 的 API 仍无实现。
* **身份是自产真件（4.0.0.1 / 31bf3856ad364e35），不是 `xamlrefs/` 的改版件**：改版件（10.0.0.0）
  虽然能骗过旧 PBT，但会让运行期与编译期身份分裂（历史上表现为窗口全黑）。自产 PBT 已支持"按名回退"，
  所以直接用真件。详见 `RT/Links-License-Mgr/PortWpfLinux/REPORT-治全黑.md`。

## 组装（本仓）

```bash
export PATH="$HOME/.dotnet:$PATH"
cd src/Linux/build/third-party/pkg
dotnet pack WpfLinux.Sdk.csproj -c Release -o out
```

打包取的是仓内**已构建**的 Release 产物（`-p:WpfLinuxRepoRoot=… -p:WpfLinuxSelfBuiltConfiguration=…` 可覆盖）。

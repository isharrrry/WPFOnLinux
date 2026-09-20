# T0 + T1 交付报告

> 负责人：env-build ｜ 日期：2026-08-30 ｜ 环境：Ubuntu **24.04.3**（任务书写 22.04，实测 24.04），root，x86_64

## 结论速览

| 项 | 结果 |
|---|---|
| T0 环境基线 | ✅ `verify-env.sh` 15/15 通过 |
| T1 编译 PBT（9,299 行纯托管） | ✅ Linux 上 `net10.0` 编译成功，**0 警告 0 错误** |
| T1 HelloWpf → BAML | ✅ `App.baml` 860B + `MainWindow.baml` 1756B |
| **与 SDK 官方版 BAML 字节比对** | ✅ **逐字节完全一致**（最强正确性证据） |
| 运行 HelloWpf | ❌ 缺 `Microsoft.WindowsDesktop.App` 运行时（属 T2–T8 范围） |

## T0 · 环境版本清单

| 组件 | 版本 | 安装方式 / 备注 |
|---|---|---|
| .NET SDK | **10.0.111** | `apt install dotnet-sdk-10.0`（Ubuntu archive 源） |
| 运行时 | Microsoft.NETCore.App / AspNetCore.App 10.0.11 | 仓库 SDK **锁定** `global.json` |
| SkiaSharp | **2.88.9** | 必须配对 `SkiaSharp.NativeAssets.Linux 2.88.9` |
| Xvfb | 2:21.1.12-1ubuntu1.6 | `xvfb` |
| xwd | **1.0.9** | 在 **`x11-apps`** 包，不在 `x11-utils` |
| ImageMagick | 6.9.12-98 Q16 | `convert` / `compare` |
| Noto Sans | **v2.4.55**（Regular/Bold/Italic/BoldItalic） | `build/fonts/` + `SHA256SUMS` 锁定，部署到 `tests/fonts/` |

## 坑与解法

1. **GitHub 与 NuGet 均被 TLS 阻断**（`curl` 返回 `000` / `SSL_ERROR_SYSCALL`）。
   → GitHub 走 `https://gh-proxy.com/<原始URL>`；NuGet 换 **华为镜像** `https://mirrors.huaweicloud.com/repository/nuget/v3/index.json`，由 `setup-env.sh` 写入 `~/.nuget/NuGet/NuGet.Config`（含 `<clear/>` 保证复现）。`dot.net/v1/dotnet-install.sh` 及各 dotnet 镜像站全部不可达，**唯一可行路径是 apt**。
2. **只装 SkiaSharp 托管包会崩**：`libSkiaSharp: cannot open shared object file`。必须同时装 `SkiaSharp.NativeAssets.Linux`。
3. **SkiaSharp 4.151.1 有破坏性 API 变更**（`SKPaint.TextSize` → `SKFont`），故选用 API 稳定的 2.88.9。
4. **字体确定性已验证**：用自打包字体渲染两次，PNG 的 SHA-256 完全一致 → golden image 测试前提成立。

## T1 · XAML 编译链路

### 成果
`PresentationBuildTasks.csproj` 在 Linux 上改造为纯 `net10.0` 并编译通过，产物 678,400 字节，
`MarkupCompilePass1/2`、`FileClassifier`、`ResourcesGenerator`、`UidManager`、`GenerateTemporaryTargetAssembly` 全部可用。
完整改动见 **`build/PresentationBuildTasks.Linux/PORT-CHANGES.md`**（8 项，由 `build/port-pbt.sh` 从上游自动生成，**上游仓库零改动**）。

### 关键改动（详见 PORT-CHANGES.md）
1. 双目标（含 .NETFramework）→ 单目标 `net10.0`
2. 96 条路径 `\` → `/`（Linux MSBuild 不认反斜杠）
3. `WpfSourceDir`/`WpfSharedDir`/`WpfCommonDir` 改为显式定义（原由 Arcade 注入）
4. 切断 Arcade 继承
5. 包版本写死（`Microsoft.Build.*` 用上游的 `15.9.20`；`MetadataLoadContext`/`CodeDom` 由预览版 `11.0.0-rc.1` 降为稳定版 `9.0.0`）
6. `Strings.resx` 改绝对定位（修 `MSB3552`）
7. 30 条相对源文件加 `$(UpstreamPbtDir)` 前缀（修 `CS2001`）
8. **自写 `build/gen-sr.py` 替代 Arcade 的 `GenerateCommonSRSource`**，从同一 resx 生成 `SR.g.cs`（239 条）。缺它会刷 **688 个** `CS0117: 'SR' does not contain a definition for 'Xxx'`

### 最大的坑：UsingTask 覆盖不生效
用 `<UsingTask>` 覆盖 SDK 声明后，`-v:diag` 显示仍加载
`/usr/lib/dotnet/sdk/10.0.111/Sdks/Microsoft.NET.Sdk.WindowsDesktop/tools/net10.0/PresentationBuildTasks.dll`。

**解法**：SDK 的 `Microsoft.WinFX.targets` 用属性 `$(_PresentationBuildTasksAssembly)` 且带
`Condition="'$(_PresentationBuildTasksAssembly)'==''"`（**先设值者胜**）。在 `HelloWpf.csproj` 中
导入 `Sdk.targets` **之前**设置该属性即可接管。
> 因此 csproj 用显式 `<Import Sdk.props/Sdk.targets>` 而非 `<Project Sdk="...">` 简写——简写会把
> `Sdk.targets` 隐式追加到文件末尾，导致覆盖被反向吃掉。

验证命令：
```bash
dotnet build samples/HelloWpf -c Release -v:diag \
  | grep -oE 'Using "MarkupCompilePass[12]" task from assembly "[^"]*"'
# 应看到 .../wpf-linux/build/PresentationBuildTasks.Linux/bin/Release/net10.0/PresentationBuildTasks.dll
```

## 未解决项

1. **HelloWpf 无法运行**：`Framework: 'Microsoft.WindowsDesktop.App', version '10.0.0' ... No frameworks were found.`
   Linux 上没有 WPF 运行时。需 T2–T8 产出 Linux 版 `PresentationFramework`/`PresentationCore`/`WpfGfx.Linux` 后才能跑（届时可把 `UseWPF` 换成指向团队自编译程序集）。**T1 的目标（XAML→BAML）已达成。**
2. `MarkupCompilePass2` 本样例未触发（无跨程序集 internal 类型），尚未被真实用例验证。
3. BAML 中未检出明文类型名——BAML 用「已知类型表 ID」编码标准元素，属正常；已通过与官方版字节比对确认正确。
4. `setup-env.sh` 会写 `/workspace/wpf-linux/global.json`（仓库根，用于锁定 SDK）。这是我在规定目录之外**唯一**创建的根级文件，如需调整请告知。

## 交付物

```
build/setup-env.sh                                  一键环境（幂等，版本锁定）
build/verify-env.sh                                 环境校验（15 项 + Xvfb 实测拉起）
build/NuGet.config                                  华为镜像源（clear 全部既有源）
build/fonts/{NotoSans-*.ttf,SHA256SUMS}             固定字体（内容寻址锁定）
build/gen-sr.py                                     替代 Arcade GenerateCommonSRSource
build/port-pbt.sh                                   上游 csproj → Linux 工程（可重复生成）
build/WpfMarkupCompile.Linux.targets                任务程序集接管与校验
build/PresentationBuildTasks.Linux/                 移植后的工程 + PORT-CHANGES.md
samples/HelloWpf/{App.xaml,MainWindow.xaml,*.cs,csproj}
docs/T0T1-report.md                                 本报告
```

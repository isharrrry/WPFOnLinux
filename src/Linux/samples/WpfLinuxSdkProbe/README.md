# WpfLinuxSdkProbe —— 只靠 `PackageReference` 编译/运行的最小 WPF 工程（任务 B · MVP-1）

接入就是这一行：

```xml
<PackageReference Include="WpfLinux.Sdk" Version="1.0.0" />
```

`WpfLinuxSdkProbe.csproj` 全文非注释行 **8 行**（含 `<Project>`/`</Project>`），且**没有任何** `HintPath`。
`TargetFramework` 必须由工程自己写（restore 要先看到它）；`OutputType=WinExe`、`UseWPF=false`、
XAML 编译器、`App.xaml`/`*.xaml` 默认清单、OOB 依赖全部由包的 `buildTransitive` 提供。

## 怎么跑

```bash
export PATH="$HOME/.dotnet:$PATH"
cd src/Linux/build/third-party/pkg && dotnet pack WpfLinux.Sdk.csproj -c Release -o out    # 先出包
cd ../../../samples/WpfLinuxSdkProbe
dotnet build WpfLinuxSdkProbe.csproj -v:m                     # 0 错误
dotnet build WpfLinuxSdkProbe.csproj -t:Rebuild -v:m          # 不带任何 -p:，仍 0 错误
```

包的源在 `nuget.config` 里（`../../build/third-party/pkg/out` + 镜像）；包版本号没变时 NuGet 会命中
`~/.nuget/packages` 里的旧包 ⇒ 重新打包后先 `rm -rf ~/.nuget/packages/wpflinux.sdk`。

运行（Xvfb）：

```bash
cp -a bin/Debug/net10.0/. /tmp/probe1/app/ && cd /tmp/probe1/app && DISPLAY=:96 dotnet WpfLinuxSdkProbe.dll
```

## 证据（`evidence/`）

| 文件 | 内容 |
|---|---|
| `mvp1-build.log` | 干净首次构建（清 obj/bin + 清包缓存）：0 错误 0 警告 |
| `mvp1-rebuild.log` | 不带任何 `-p:` 的 `-t:Rebuild`：0 错误 0 警告 |
| `mvp1-deps.txt` | `deps.json` 归属：WPF/BCL 全部来自 `WpfLinux.Sdk/1.0.0`（`lib/net10.0/…`，assemblyVersion 4.0.0.1 / SWE 9.0.0.0） |
| `mvp1-wpftmp.txt` / `wpftmp.csproj.sample` | XAML 临时工程（`*_wpftmp.csproj`）的取证：它的 `ReferencePath` 全指 `~/.nuget/packages/wpflinux.sdk/1.0.0/lib/net10.0/…` ⇒ 主工程与临时工程同一套引用身份 |
| `mvp1-run.log` / `mvp1-shot.png` | 仓外运行（`/tmp/probe1/app`）：存活 12s，画面 216 色 |

`MainWindow.xaml` 特意引用了本程序集的 `internal` 类型（`InternalBadge`）—— 这会触发
`GeneratedInternalTypeHelper`，BAML 装载时走 `XamlAccessLevel`，用来验证包里的
`System.Windows.Extensions` 替身（官方包在非 Windows 上必抛）。

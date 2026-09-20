# 第三方（外部）WPF 应用接到本仓的移植栈上

> 面向"我有一份**自己的** WPF 工程，想让它**在 Linux 上编译并跑起来**"。
> 本仓门禁样本（`samples/`）之外的第一份真实第三方实证是 **HandyControl 示例工程**：
> 库 ＋ demo **0 error**（148 个 Page 进 BAML）、**开窗并渲染出完整界面**
> （自定义 chrome ＋ 中文控件名 ＋ 图标 ＋ 图片；**零探针装置**。窗口内颜色数：`#33`/`#40` 两代实测**均为 373**
> —— 与该 demo 的素材一致：它的图是**调色板 PNG**（`Cover.png` 109 色 / `Dance.png` 37 / `cloud.png` 50）；
> ⚠️ 旧记录里的 **`1275`** 出自**未留存的采集口径**（`#43` 查：`$HOME` 下 60 具 hc 归档帧**最大 373**、
> 无任何留存帧 >600 色）⇒ **主体与口径均待复现，不作为判据**。完整度按 `#43` 的口径读：
> 与历史基准帧 `compare -metric AE` ＋ 素材色数上界，两条一起看）。
> ⚠️ 那份实证是**在仓外**做的（应用与探针都不在本仓）⇒ 它是**产品事实**、但**不构成仓内判据**。

---

## 1. 三步（最小路径）

### 第 1 步：先在本仓里把自产件建出来

```bash
cd /path/to/wpf-linux
bash build/setup-env.sh                      # 一次性：依赖 + NuGet 源 + SkiaSharp 预热 + 字体
WAVE_OWNER=$(whoami) bash build/integration-wave.sh   # 移植 + 按依赖序构建（0 error 才算过）
```

产物落点（第三方工程要引用它们）：

```
build/PresentationCore.Linux/bin/Debug/PresentationCore.dll
build/PresentationFramework.Linux/bin/Debug/PresentationFramework.dll
build/WindowsBase.Linux/bin/Debug/WindowsBase.dll
build/System.Xaml.Linux/bin/Debug/System.Xaml.dll
build/DirectWriteForwarder.Linux/bin/Debug/DirectWriteForwarder.dll
build/DirectWrite.Linux/Provider/bin/Debug/DirectWrite.Linux.Provider.dll
build/UIAutomationTypes.Linux/bin/Debug/UIAutomationTypes.dll
build/UIAutomationProvider.Linux/bin/Debug/UIAutomationProvider.dll
build/System.Windows.Input.Manipulations.Linux/bin/Debug/System.Windows.Input.Manipulations.dll
build/PresentationFramework.Classic.Linux/bin/Debug/PresentationFramework.Classic.dll   # 主题件
```

### 第 2 步：把你的工程接上

把 **`build/third-party/WpfLinux.props`**（模板）拷到你的工程目录并导入，然后：

```xml
<Project>
  <Import Project="Sdk.props" Sdk="Microsoft.NET.Sdk" />
  <Import Project="WpfLinux.props" />                        <!-- 本仓提供的配方 -->
  <PropertyGroup>
    <WpfLinuxRoot>/path/to/wpf-linux</WpfLinuxRoot>           <!-- 必填：仓根 -->
    <WpfLinuxBuildConfiguration>Debug</WpfLinuxBuildConfiguration>
    <AssemblyName>YourApp</AssemblyName>
    <OutputType>WinExe</OutputType>
  </PropertyGroup>
  <ItemGroup>
    <Page Include="MainWindow.xaml" />                        <!-- XAML 必须显式声明 -->
    <ApplicationDefinition Include="App.xaml" />
  </ItemGroup>
  <Import Project="Sdk.targets" Sdk="Microsoft.NET.Sdk" />
  <!-- XAML 编译（WinFX targets；net10.0 下 SDK 不会自动导入）-->
  <Import Project="$(MSBuildSDKsPath)/../Microsoft.NET.Sdk.WindowsDesktop/targets/Microsoft.WinFX.targets"
          Condition="Exists('$(MSBuildSDKsPath)/../Microsoft.NET.Sdk.WindowsDesktop/targets/Microsoft.WinFX.targets')" />
</Project>
```

要点（每条都是实测撞出来的）：

| 要点 | 为什么 |
|---|---|
| `<UseWPF>false</UseWPF>` | 用的是**自产** WPF 栈，不是 Windows Desktop SDK 的 |
| 必须**显式** `Import Sdk.props` / `Sdk.targets` | 我们要在两者之间插自己的属性（PBT 路径等），顺序反了就被 SDK 默认值抢先 |
| `PbtLinuxDir`/`_PresentationBuildTasksAssembly` 要在 WinFX targets **之前**赋值 | **先设值者胜**；PBT 是自产的（`build/PresentationBuildTasks.Linux`） |
| `SkiaSharp` ＋ `SkiaSharp.NativeAssets.Linux` **成对** | 只装托管包 ⇒ 运行期 `DllNotFoundException: libSkiaSharp` |
| OOB BCL 包（`System.IO.Packaging` 等 8 个）要显式引 | 自产件在共享框架**之外**引用它们 |
| **`System.Windows.Extensions` 要换成仓内替身**（`#38` 打通） | 官方包在非 Windows 上把 `XamlAccessLevel`/`SoundPlayer`/`X509Certificate2UI` 实现成**必抛**桩 ⇒ 任何生成 `GeneratedInternalTypeHelper` 的程序集一装 BAML 就崩。配方：留一条 `<PackageReference … ExcludeAssets="compile;runtime" />`（**不能整条删**：`System.Security.Permissions 9.0.0` 传递依赖它，删了 restore 仍把包拉回来）＋ 指向 `build/System.Windows.Extensions.Linux/bin/$(Configuration)/` 的 `<Reference>` |
| 替身要**公开签名**（与其他自产件同形态） | 强命名程序集引用未签名程序集会报 `CS8002`（本仓的波把**警告也算失败步骤**） |

### 第 3 步：跑起来（部署布局：**零环境变量**）

把下面这些**放到应用输出目录**（和 `YourApp.dll` 同目录）即可，**不需要任何 env**：

```
YourApp.dll
libwpfwin32.so        # Win32/GDI/OEM/GDI+ shim      ← src/WpfGfx.Linux.Native/bin/
libwpfwic.so          # WIC → Skia 解码桥            ← build/DirectWrite.Linux/wic-shim/
wpfgfx_cor3.so        # AOT milcore（渲染核心）      ← build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/
libSkiaSharp.so       # 随 NuGet 包 SkiaSharp.NativeAssets.Linux 2.88.9 进输出目录
```

```bash
# 在 X server（真显示器或 Xvfb）下：
Xvfb :97 -screen 0 1280x1024x24 &
DISPLAY=:97 dotnet YourApp.dll
```

---

## 1b. 仓内就有一个"第三方形态"的可跑样本（**先用它验证你的环境**）

`samples/ThirdPartyMini/` 是**按第三方形态做的**最小应用（只经 `build/third-party/WpfLinux.props` 接线、
不进 `wpf-linux.sln`、产物**复制到仓外**再跑），并已接成 `verify-all` 的第 `[19]` 步：

```bash
bash samples/ThirdPartyMini/run-thirdparty-mini.sh --selftest   # 判据两极化自测（4/4）
bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25           # 完整一趟：构建→仓外→部署四个 .so→采样→判据
bash samples/ThirdPartyMini/run-thirdparty-mini.sh 15 --no-build --hide-shim   # 反极性：必须 FAIL
```

| 档 | 读数 |
|---|---|
| 仓外 ＋ 四个 `.so`（**零环境变量**） | `THIRDPARTY=PASS max_colors=1485`、`THIRDPARTY_IMAGE=PASS 96x96 format=Bgra32` |
| 仓外 ＋ **不部署** `libwpfwin32.so` | `THIRDPARTY=FAIL reason=app-exit=134`（`DllNotFoundException: kernel32.dll 已映射到 libwpfwin32.so，但没找到可加载的 shim 库`） |

### ⚠️ 两条**会让第三方自己也踩**的实测结论

1. **`Win32ShimResolver` 有一条"向上找仓根"的回退**：候选路径会从 `AppContext.BaseDirectory`
   **与 `Directory.GetCurrentDirectory()`** 两条各自向上走 12 层去找
   `src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（`build/shims/Win32ShimResolver.cs:524-537`）。
   ⇒ **应用在仓内、或你把 cwd 设成仓根**时，即使**不部署** app-local 的 `.so` 也能跑起来
   （本仓样本实测：`--hide-shim` 照样 PASS、1485 色）。
   ⚠️ 所以**别在仓内验证"部署布局"** —— 要验证就复制到仓外再跑（样本的 runner 就是这么做的）。
2. **"应用崩了"与"仪器没跑起来"要分开报**：前者是**红**（`THIRDPARTY=FAIL reason=app-exit=…`），
   后者才是 `NOINFO`。把两者混成一个数字，会让"缺 `.so`"看起来像"采样脚本坏了"。

---

## 2. 为什么第三方程序的 `[DllImport("user32.dll")]` 也能落到我们的 shim

WPF 的原生 interop 走 `NativeLibrary.SetDllImportResolver`，而它是**逐程序集**的
（只作用于调用它的那个程序集）。第三方库不会被它覆盖 ⇒ 本仓在
`build/shims/Win32ShimResolver.cs` 的 `[ModuleInitializer]` 里额外挂了
**默认 ALC 级钩子** `AssemblyLoadContext.Default.ResolvingUnmanagedDll`
（它在默认探测失败**之后**触发）⇒ **任何**第三方程序集的 Win32 P/Invoke 都能被接住。

当前映射的名字：`user32` / `gdi32` / `kernel32` / `PresentationNative_cor3` / `uxtheme` / `wtsapi32`
/ `shell32` / `ntdll` / `gdiplus` / `msimg32` / `dwmapi`（＋ WIC 相关的 `WindowsCodecs`、`ole32` 等）。
**口径**：能真做的真做；做不到的**如实失败**（返回错误码而不是假装成功）；少数地方按语义降级
（DWM＝"有 DWM、合成关闭"；uxtheme＝"无活动 Windows 主题"）——**不许用谎话换绿屏**。

⚠️ 一条实测教训：**"降级实现也必须尊重调用方声明的结构大小"**。曾经的 `RtlGetVersion`
按"我们以为的结构大小"（280 B）回填，而调用方声明的是 148 B（ANSI `ByValTStr(128)`）
⇒ **越界写**，症状是**应用静默黑屏、一个异常都没有**。

---

## 3. 会遇到什么（照抄这份"已知边界"，别当 bug 查）

| 现象 | 根因 | 现状 |
|---|---|---|
| 用了 `XamlAccessLevel` 之类 API 的 BAML 加载抛异常 | 官方 `System.Windows.Extensions` 包**只有 `runtimes/win` 是真实现**，非 Windows 上必抛 | 本仓有 Linux 原生替身（`build/System.Windows.Extensions.Linux/`），但**接线未打通**（登记 `D-G45`） |
| 通过 GDI+ 解码图片（`GdipCreateBitmapFromFile` 等）失败 | GDI+ 面只做到"应用能起来"：查询类返回空结果、创建/解码类返回 `InvalidParameter` | **未做**（图像族真解码是待办） |
| 依赖 `ntdll` / 注册表 / COM 其他面的行为 | 只实现了最小面（`RtlGetVersion` 等） | 未实现的部分**如实失败** |
| 窗口用了 `WindowChrome` | 曾经 `SetWindowRgn` 返回 0 ⇒ 必崩 | **已修**（返回 1） |
| 全局钩子（`SetWindowsHookEx` 等） | 曾经**完全没导出** ⇒ `EntryPointNotFoundException` 掀掉应用 | **已修**（如实失败，应用可优雅降级） |
| 截图/渲染看起来"全黑"但没异常 | 见 §2 的 `RtlGetVersion` 越界写（**已修**）；也可能是自己把 `libwpfwin32.so` 之类漏拷了（少一个 `.so` 的表现各不相同） | 用 `WPFGFX_ROOTDIAG=1`（env 门控的根投影诊断，默认关）看呈现链有没有跑 |

---

## 4. 自查（出现"没画出来"时按顺序做）

```bash
# ① 四个 .so 是否都在应用目录（少一个的表现各不相同）
ls YourApp/bin/Debug/net10.0/{libwpfwin32.so,libwpfwic.so,wpfgfx_cor3.so,libSkiaSharp.so}

# ② 呈现链有没有跑到（默认关，需要时显式打开）
WPFGFX_ROOTDIAG=1 DISPLAY=:97 dotnet YourApp.dll 2>&1 | head -50

# ③ 真截图 + 数颜色（判据要**时间分辨**：窗口内容可能在几秒后才出现）
DISPLAY=:97 xwd -root -silent | convert xwd:- png:shot.png && identify -format '%k 色\n' shot.png

# ④ 用本仓的仪器读同样的问题（第三方应用也能用）
bash build/MilBridge/tools/frame-presence-check.sh --help
```

---

## 5. 边界（说清楚，别让第三方以为这是"完整 WPF"）

- 本仓的目标是"**从源码编译 + 真的画出界面**"，**不是**二进制兼容、也**不是**完整 API 覆盖。
- 权威件目前是 **Debug** 构建（切 Release 是待办；上游 `Debug.Assert`/`Invariant.Assert` 未做 `[Conditional("DEBUG")]` 处理）。
- 第三方实证（HandyControl 示例）**在仓外**，仓内判据只覆盖自建样本；
  要把它变成"可复算的第三方判据"，需要在仓内落一份最小第三方 repro（**待办**）。

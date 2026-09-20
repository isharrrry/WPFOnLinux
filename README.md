# WPF on Linux —— 把 `dotnet/wpf` 移植成 Linux 原生可编译 + 可渲染

> **目标**：让 WPF 应用**在 Linux 上从源码编译、开窗、真的画出界面、并且能用鼠标键盘操作**。
> **边界（明说）**：**不**兼容"在 Windows 上编译好的 WPF 二进制"——这个边界砍掉了整条二进制兼容路线的工作量。
> **上游**：`upstream/wpf/`（`dotnet/wpf` 的一个快照，MIT，见 `upstream/wpf/LICENSE.TXT`）；上游**原始 README** 已保留为 [`README-Window.md`](README-Window.md)。
> **工程规范**（并行车道必须遵守）：[`docs/PORT-SPEC.md`](docs/PORT-SPEC.md)｜**并行路线图**：[`docs/ROUTES.md`](docs/ROUTES.md)｜**文档地图**：[`docs/INDEX.md`](docs/INDEX.md)｜**发 fork / 推分支**：[`docs/FORK-AND-PUSH.md`](docs/FORK-AND-PUSH.md)。

## 0. MVP 现状（2026-09-20）与"已知问题"

**MVP 成立**：真实 WPF 应用（HandyControl 示例）**从源码编译通过 → 开窗 → 渲染出完整界面 → 点击/打字/下拉/列表都可用**。
一条命令跑起来（自动把 `app-local` 五个件刷成仓内权威并打印 sha16，然后启动）：

```bash
bash ~/run-hc.sh          # 见 §4；--no-sync 只启动，--diag 开输入仪器（⚠️ 已知会让应用闪退，勿用）
```

**⚖️ 当前已知问题（都是真读数，不是猜测）**：

| # | 现象 | 状态 |
|---|---|---|
| ① | **有窗口管理器的会话里点击全被吞**（无 WM 的验收装置永远复现不出来） | ✅ 已修（`WindowFromPoint` 框架→客户窗下降；四腿两极化验证）；**待发波冻结** |
| ② | **点页签就崩**（`SetFocus ⇄ WM_SETFOCUS` 回声环 ⇒ `Stack overflow.`，最小复现 **2 击**） | ✅ 已修（补 `old != hwnd` 守卫；同趟两极化：修前 `rc=134`/`setfocus=4034`，修后 `alive=yes`/`setfocus=0`） |
| ③ | **启动即死**（UI 线程锁竞争 ⇒ `WaitForMultipleObjectsEx` 失败桩 ⇒ 未处理异常；修前单实例 **7/38 ≈ 18%**） | ✅ 已修（`DispatcherSynchronizationContext.Wait` 走托管等待；修后 **0/30**） |
| ④ | **窗口形态**：用户实测"直接全屏、不能拖动、不能缩放" | 🔄 车道 W57A 取证中（`xprop`/`xwininfo` 四项提示 + 代码判定点）——见 `ROUTES.md` R1 |
| ⑤ | **仍会出现崩溃**（用户实测，签名未定） | 🔄 车道 W57A 做仪器全关的 ≥10 趟压力表并在归类——见 `ROUTES.md` R2 |
| ⑥ | 「工具」页第 2 项 `Effects` 一打开就异常（缺 `0x6c`/`0x70` 两个 MIL 命令 `case`）；页签/按钮**文字零墨**；GIF **只出第 0 帧** | 🔄 根因均已到行，排在 `docs/WAVE49-PREREGISTRATION.md` 的 A 类 |

**上面三个 ✅ 都还没重冻**：它们动了 `win32shim` 与 `windowsbase` 两位 ⇒ 必须按 `PORT-SPEC` §5 走整波链（重建 → 重取五臂 → 重钉 → 门禁 ×2 → `verify-all` ×2 → 重冻基线）后才算"基线"。

---

## 1. 今天能做什么（每条都可复算）

| 能力 | 现状 | 复算入口 |
|---|---|---|
| **编译** WPF 托管层 | `PresentationCore` / `PresentationFramework` / `WindowsBase` / `System.Xaml` / `DirectWriteForwarder` / `DirectWrite.Linux.Provider` 全部 0 error | `WAVE_OWNER=<你> bash build/integration-wave.sh` |
| **原生侧** | `libwpfwin32.so`（窗口/消息/GDI/OEM/GDI+ 面）、`libwpfwic.so`（WIC → Skia 解码）、`wpfgfx_cor3.so`（AOT 的 milcore 渲染核心） | `bash src/WpfGfx.Linux.Native/build-shim.sh`、`bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh`、`bash build/MilBridge/run.sh build` |
| **开窗 + 渲染**（仓内样本） | `samples/WpfTextDemo`：默认档（**清空全部字体 env**）窗口内 **3960 色**、`14/14` 帧非空、`未画种类 0` | `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both` |
| **第三方形态（仓内判据）** | `samples/ThirdPartyMini`：只经 `build/third-party/WpfLinux.props` 接线、不进 sln、产物**复制到仓外**再跑；`WindowChrome` ＋ 图片解码（`Bgra32`）＋ 中文/图标 ＋ 数据绑定全部渲染（窗口内 **1485 色**） | `bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25`（`verify-all` 第 `[19]` 步） |
| **第三方真实应用（仓外实证）** | HandyControl 示例工程：库 + demo **0 error**（148 个 Page 进 BAML）、**开窗并渲染出完整界面**（自定义 chrome ＋ 中文控件名 ＋ 图标 ＋ 图片；窗口内 **1275 色**，**零探针装置**） | 见 §4；⚠️ 该实证在**仓外** ⇒ 它是产品事实，**不单独构成仓内判据**（仓内判据见上一行） |
| **一键验收** | `verify-all.sh`：**25 步**、871 用例通过、2 跳过、含五臂对拍 / 应用门禁 / 冻结基线核对 / 第三方形态样本 | `bash verify-all.sh` |

**"可复算"是本工程的硬要求**：每个结论都得有一条命令能重算，并且**判据件自己也被看着**
（`verify-all` 里 24 步中有 12 步是"看仪器的仪器"：门禁自检、输入覆盖面自检、引号陷阱、`pipefail` SIGPIPE 普查、隐形段牙齿、列级下限外挂读者……）。

---

## 2. 快速开始

### 2.1 依赖

```bash
# 编译器与系统库（原生 shim 需要 X11 头文件；AOT 需要 clang）
sudo apt-get install -y gcc libc6-dev libx11-dev zlib1g-dev clang
# X11 / 截图 / 字体工具（验收用；跑样本也需要一个 X server）
sudo apt-get install -y xvfb x11-apps x11-utils imagemagick fontconfig libfontconfig1
# .NET SDK 10（仓内 global.json 锁 10.0.111；用 dotnet-install.sh 或发行版包皆可）
dotnet --version
```

一键装环境（含 NuGet 源、SkiaSharp 预热、测试字体、`global.json` 锁定）：

```bash
bash build/setup-env.sh     # ⚠️ 它会把 NuGet 源写成国内镜像（见脚本内 NUGET_MIRROR）；正常网络下请自行改回 nuget.org
bash build/verify-env.sh    # 打印环境清单，逐项 OK/WARN/FAIL
```

> ⚠️ `setup-env.sh` 里的镜像（`mirrors.huaweicloud.com` / `gh-proxy.com`）是**当年沙箱网络**的产物，
> 不是产品依赖：把 `~/.nuget/NuGet/NuGet.Config` 换回你自己的源同样能跑。

### 2.2 从零构建（移植 + 编译）

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh     # 顺序：port-lib 重生成 → 应用器重放 → 按依赖序重建
```

- `WAVE_OWNER` 是**结构约束**（不是礼貌）：没有它脚本直接退出。每一趟都往 `build/wave-audit.log`
  追加一条可追溯记录（时间/pid/ppid/tty/命令行/owner）——"认领不到人的重建"从此不可能悄悄发生。
- 这一步会跑 `build/port-lib.py` **整体重写**各 `*.Linux.csproj`，
  再按 `build/integration-wave.sh` 里的登记表重放**应用器**（`src/WpfGfx.Linux.Native/tools/patch-*.py`）。
  ⚠️ **手工改 csproj 会在下一次 `port-lib` 时被抹掉** —— 接线要写进应用器（`--check` 幂等）。

### 2.3 开窗渲染（一条命令）

```bash
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both
# 默认档 = 清空全部 WPF_LINUX_*/HLWPF_* 字体 env（这才是真应用拿到的配置）；env 档只作对照
# 机读行会打印：WPTD_SUMMARY / WPTD_GATE / 每帧 PNG 路径（人眼复核用）
```

它自己起 `Xvfb :97`、截屏、判据四条（进程存活＋`未画种类 0`＋截图非空非纯色＋逐特性颜色计数），
两档都必须过；只要一档过 = 失败。

### 2.4 一键验收（要一个 X server，`verify-all.sh` 自己会用 `:99`）

```bash
bash verify-all.sh          # 24 步；含构建、测试、五臂对拍、应用门禁、冻结基线核对、时间分辨画面读者
```

---

## 3. 架构（30 秒版）

```
upstream/wpf/**            只读上游（不改）
      │  build/port-lib.py  （剔除 Windows-only 源 + 纳入生成的 *.Linux.cs；**整体重写** csproj）
      ▼
build/*.Linux/*.csproj  ──构建──▶  六个托管程序集（pc / pf / windowsbase / system.xaml / dwf / provider）
      │  应用器重放（patch-*.py：补丁式接线，幂等 + --check + 锚点数断言）
      ▼
原生三件：libwpfwin32.so（Win32/GDI/OEM/GDI+ 面，口径=能真做的真做、做不到的**如实失败**）
          libwpfwic.so   （WIC → Skia 解码桥）
          wpfgfx_cor3.so （AOT 的 milcore：渲染核心）
```

细节（含"为什么用替换式而不是 fork 式"、DPI/字体/资源管线/主题栈的处理）见 **`docs/ARCHITECTURE.md`**；
逐波的技术账（每一波的预登记、读数、被推翻的旧结论）见 **`docs/WAVE*-PREREGISTRATION.md`** 与 **`handoff.md`**。

---

## 4. 第三方 WPF 应用怎么用

两条事实（都实测过）：

1. **原生 interop 的正道通道**：`Win32ShimResolver` 挂了**默认 ALC 级钩子**
   （`AssemblyLoadContext.Default.ResolvingUnmanagedDll`）⇒ **第三方程序集**的
   `[DllImport("user32.dll")]` / `"shell32.dll"` / `"gdiplus.dll"` … 也能落到我们的 shim 上。
2. **部署布局：零环境变量**。把下面这些**放在应用输出目录**（和 `YourApp.dll` 同目录）即可：

```
YourApp.dll
libwpfwin32.so          # Win32/GDI/OEM/GDI+ shim
libwpfwic.so            # WIC → Skia 解码桥
wpfgfx_cor3.so          # AOT milcore（渲染核心）
libSkiaSharp.so         # 来自 NuGet 包 SkiaSharp.NativeAssets.Linux（与托管包版本必须配对）
```

工程侧最小改动：`<UseWPF>false</UseWPF>` ＋ 显式引用自建的六个程序集与 `PresentationFramework.Classic`
（配方模板 = `build/third-party/WpfLinux.props`，逐条说明见 `docs/THIRD-PARTY-APPS.md`；
**仓内就有一个按这个配方做的可跑样本** = `samples/ThirdPartyMini`（独立 csproj、不进 sln、
产物**复制到仓外**再跑），先用它验证你的环境：`bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25`）。

⚠️ **已知会让第三方应用踩坑的边界**（详见 §6）：官方 `System.Windows.Extensions` 包在非 Windows 上**必抛**
（`XamlAccessLevel`/`SoundPlayer`/`X509Certificate2UI`）—— **本仓已用 Linux 原生替身打通**（`#38`；
配方见 `build/third-party/WpfLinux.props`：留一条"排除 `compile;runtime` 资产"的占位包引用 ＋ 指向替身的 `<Reference>`）；⚠️ 但**Debug 权威件带着"活的"`Invariant.Assert`** ⇒ 真实第三方应用可能在模板解析时被断言终止（**`D-G47`**，待"权威件切 Release"治）；
GDI+ 的**图像编解码族**只做到"应用能起来"；`ntdll` 面只有 `RtlGetVersion`。

---

## 5. 可复算性：这个仓的"牙齿"

| 机制 | 一句话 |
|---|---|
| `verify-all.sh`（24 步） | 构建 + 测试 + 五臂对拍 + 应用门禁 + 一堆"看仪器的仪器"；`NOINFO` 一律不许当绿 |
| `build/integration-wave.sh` | 移植 + 构建的唯一入口；波必须**认领**（`WAVE_OWNER`）并留审计行 |
| 五臂对拍（`tline`/`tab-*`/`textlineproto`） | Linux 与 Windows 真值逐行比；臂日志 sha 有机器声明 |
| 应用门禁（两档 × 3 rep） | 真开窗、真截屏、真数色；`BASELINE … result=PASS` 机读行 |
| 冻结基线 | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 是**唯一权威**；整份 sha 只由 `docs/CURRENT-STATE.md` 里那一行机器声明；谁改都要过 `baseline-sha-check.sh` |
| 九位产物身份 | 九个权威件的 sha16 逐位记录在冻结块里（`pf` 是"环成员"，它的位移按惯例如实记录） |
| 已知红 | `build/MilBridge/known-red.json` ＋ 声明表；"已知红"必须是**登记过的**，不许口头豁免 |

---

## 6. 已知边界（诚实清单，发布初版照抄）

- **权威件是 Debug 构建**（切 Release 是下一步；上游 `Debug.Assert`/`Invariant.Assert` 未做 `[Conditional("DEBUG")]` 处理，Release 化需要同趟处理）。
- **GDI+ 图像族**（`GdipCreateBitmapFromFile`/`Save`…）返回"如实失败"；查询类返回空结果 ⇒ 依赖 GDI+ 解码的第三方代码会走不到图。
- **`D-T4`**：帧步的 3 条**结构族**红（已登记、判据刻意不判结构族）。修它会让像素变、需重取五臂与 136 条 `tab0` 真值 ⇒ 独立成波。
- **`D-G45`**：`System.Windows.Extensions` 的 Linux 原生替身**已写好但停用**（接线后 `PresentationFramework` 报 `CS0012`：程序集身份不一致）。
- **第三方实证在仓外**（HandyControl 样本工程与探针都不在本仓）⇒ 仓内判据只覆盖自建样本。
- **Windows-only 特性的处理口径**：能降级的降级（DWM＝"有 DWM、合成关闭"、uxtheme＝"无活动主题"），
  做不到的**如实失败**（返回错误码，而不是假装成功）——**不许用谎话换绿屏**。
- 逐条细节见 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 与 `docs/CURRENT-STATE.md`。

---

## 7. 目录导航

| 路径 | 是什么 |
|---|---|
| `upstream/wpf/` | 上游 `dotnet/wpf` 快照（**只读**） |
| `build/port-lib.py` | 移植生成器（重写 `*.Linux.csproj`） |
| `build/integration-wave.sh` | 移植 + 构建的唯一入口 |
| `build/*.Linux/` | 各 Linux 工程的骨架与生成物 |
| `src/WpfGfx.Linux.Native/` | 原生 shim 源码（C）与应用器（`tools/patch-*.py`） |
| `build/MilBridge/` | AOT milcore 桥 + 五臂 + 门禁 + 冻结/核对工具 |
| `samples/` | 仓内样本（`WpfTextDemo` 是门禁样本） |
| `tests/` | 测试套件与 runner（含应用门禁 runner） |
| `docs/CURRENT-STATE.md` | **接手先读这一个文件**（当前状态一页纸） |
| `docs/ARCHITECTURE.md` | 架构与设计取舍 |
| `handoff.md` | 逐波技术账（长，按需查） |
| `verify-all.sh` | 一键验收 |

---

## 8. 发布（本仓准备开源时的清单）

⚠️ **发布前必办**（实测数字与处置见 **`docs/RELEASE-READINESS.md`**）：

1. **`.gitignore`**（仓根已备）：不忽略的话 `git add -A` 会把 129 个 `bin/obj/.artifacts` 目录（≈3.3 GB）一起进库。
2. **GitHub 单文件 100 MB 硬限**：`tests/parity/geometry/u14/linux-results-u14.json` = **118.2 MB**
   ⇒ 直接 `git push` **会被拒**。**已实测查明不必用 LFS**：那份 JSON **全仓没有任何读者**（只是探针输出，
   重算 = 跑 `tests/parity/geometry/u14/U14.csproj`），另一份 55 MB 的 Windows 真机 dump 也**只作为派生件的来源**
   （真值读者读的是仓内 3.1 MB 的 `build/MilBridge/gen/layout-b34-compact.json` ＋ 4.7 KB 的 `ProductEntryArm/inputs.json`）
   ⇒ 两份都已写进 `.gitignore`（**排除 ≠ 删除**：工作树里照旧），仓库从 **382M → 202M**、且**没有任何现有判据失去可复算性**。
3. **第三方资源许可**：`build/fonts/`（Noto Sans，OFL 1.1）已随附 `LICENSE-OFL.txt`；
   上游 `upstream/wpf/LICENSE.TXT` 在库；`build/keys/WcpPublicKey.snk` 是**公钥**（公开签名，无险）。
4. **上游快照的出处**：`upstream/wpf/` 是 `dotnet/wpf` 的**快照**，抓取时**没有记录 commit**
   ⇒ 发布时建议补一份 provenance（来源 URL ＋ 抓取时间 ＋ 可比对的目录清单）。

---

## 9. 许可

- 上游 `upstream/wpf/**` 沿用其 **MIT** 许可（`upstream/wpf/LICENSE.TXT`）。
- 本仓新增部分（`build/`、`src/WpfGfx.Linux.Native/`、`samples/`、`tests/`、`docs/` 等）随本仓许可发布。
- `build/keys/WcpPublicKey.snk` 是**公钥**（生成物用 `PublicSign` 公开签名），不含私钥。


- 上游 `upstream/wpf/**`：**MIT**（见其 `LICENSE.TXT`）。
- `build/fonts/*.ttf`：**SIL OFL 1.1**（见 `build/fonts/LICENSE-OFL.txt`）。
- 其余新增部分：随本仓许可发布（发布时由作者选定具体许可证）。

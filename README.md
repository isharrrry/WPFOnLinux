# WPF on Linux —— 把 `dotnet/wpf` 移植成 Linux 原生可编译 + 可渲染

> **目标**：让 WPF 应用**在 Linux 上从源码编译、开窗、真的画出界面、并且能用鼠标键盘操作**。
> **边界（明说）**：**不**兼容"在 Windows 上编译好的 WPF 二进制"——这个边界砍掉了整条二进制兼容路线的工作量。
> **上游**：`upstream/wpf/`（`dotnet/wpf` 的一个快照，MIT，见 `upstream/wpf/LICENSE.TXT`）；上游**原始 README** 已保留为 [`README-Window.md`](README-Window.md)。
> **工程规范**（并行车道必须遵守）：[`docs/PORT-SPEC.md`](docs/PORT-SPEC.md)｜**并行路线图**：[`docs/ROUTES.md`](docs/ROUTES.md)｜**文档地图**：[`docs/INDEX.md`](docs/INDEX.md)｜**发 fork / 推分支**：[`docs/FORK-AND-PUSH.md`](docs/FORK-AND-PUSH.md)。

## 0. 现状（现读 2026-09-24；**本段是快照，权威一律以现场为准**）

**MVP 成立**：真实 WPF 应用（HandyControl 示例）**从源码编译通过 → 开窗 → 渲染 → 交互**，一条命令跑起来（`bash ~/run-hc.sh`；`--no-sync` 只启动，`--diag` 开输入仪器）。真机口径：hc 示例**逐页实测 29/31 页可用**。

| 现读入口 | 位置 |
|---|---|
| **世代与基线** | `docs/CURRENT-STATE.md:9`（现读 `gen=#59`，基线件 `02f80e388d308c4d`／846,233 B） |
| **交接件（新会话先读这个）** | `build/MilBridge/HANDOFF-NEXT.md`（§5 = **23 条纪律**；§7 = **七条命令**重建存活态） |
| **路线图（权威状态）** | `docs/ROUTES.md` **§13 树**；`§15x+` = 逐波记录；`§14` = `[Next]` 清单 |
| **牙齿自检（一条命令）** | `bash build/MilBridge/tools/defect-registry-check.sh`（现读 `DEFREG=PASS declared=149`） |

**仍然已知的问题（2026-09-24 现读，**只剩 4 条**）**：

| # | 现象 | 状态 / 处置 |
|---|---|---|
| ① | 切「富文本」23／「流文档」24 **必死 `rc=134`** | 🔴 真因 = **PTS／原生 LineServices 未实现**（`TASK-0302`，**可操作 88／实现口径 97**，月级长线；旧「111 条 `Fs*`/`Lo*` 缺口」已证 `TOOL-UNSOUND`）；已落**页级可见降级**（洋红占位，不再静默空白） |
| ② | **PTS／LineServices 真实现** | 🔴 `TASK-0302`（同上，长线） |
| ③ | 静默 `rc=139`＋0 字节日志 | 🟡 产品修法（UAF 链 `F1/F2/F3/F3b`）**已随 `#55` 冻结落地** ⇒ **本行读数须重取**（`TASK-0201`：用 `SILENT_SEGV_HIT` 逐字判别式 ＋ ≥131 腿/臂） |
| ④ | 零墨修法的**反极性腿**未跑 | 🟡 `TASK-0301`（正极已成立；**只差这一条腿**） |

> ⏪ **本段原是一张 8 行"已知问题"表（2026-09-20）**，其中 6 条（点页签崩 `D-G66`／启动即死／`PMaxSize` 钉死／双层窗框／顶部菜单条 NRE／Effects 缺 `0x6c`、`0x70`）**均已修**，另 2 条并入上表 ⇒ **该表已删除**；全文可从 git 历史逐字取回（`git -C ~/netTest/GitProj/WPFOnLinux log --oneline -- README.md`）。逐条细节见 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 与 `docs/ROUTES.md`。


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

- **权威件构建配置 = `Release`**（**`#40` 起已经切换并冻结**；唯一声明 = `build/SelfBuiltConfig.props`，自检 `bash build/selfbuilt-config.sh --check`）。⏪ 原句写「权威件是 Debug 构建（切 Release 是下一步）」**已过期**，其全文可从 git 历史取回。
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
| `upstream/wpf/` | 上游 `dotnet/wpf` 快照（**只读**；基点 commit `1cfc37f708f9`）。<br>⚠️ **账一（已知重复，暂按"保持现状"处理）**：fork 根目录里还有 dotnet/wpf **自带**的那棵树，两者内容重叠约 110 MB；**本仓构建只读 `upstream/wpf/**`，根目录那份不使用**（`.csproj` 与应用器锚点都按 `upstream/wpf/...` 写死）。何时合并见 [`docs/ROUTES.md`](docs/ROUTES.md) 路线 R8。 |
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
4. **上游快照的出处** ✅ 已钉死：`upstream/wpf/` = `dotnet/wpf` 的裁剪快照，**基点 commit = `1cfc37f708f91ff4556bd25af414546c446f3a16`**
   （`#11837`，2026-08-21）。判据 = 6414 件里 **6384 件逐字节相同** ＋ 29 件仅换行不同 ＋ 1 件刻意改的 `.gitattributes`
   ＋ 954 件已登记的裁剪；复算命令见 [`docs/UPSTREAM-PROVENANCE.md`](docs/UPSTREAM-PROVENANCE.md) §1.1。
   ⚠️ 发布说明要写清：`tests/parity/windows/layout-b34/windows-results.json`（53 MB，已不入库）**只能在 Windows 侧重录**，
   不是「凭空可重算」的（见 [`docs/RELEASE-READINESS.md`](docs/RELEASE-READINESS.md)）。

---

## 9. 许可

- 上游 `upstream/wpf/**` 沿用其 **MIT** 许可（`upstream/wpf/LICENSE.TXT`）。
- 本仓新增部分（`build/`、`src/WpfGfx.Linux.Native/`、`samples/`、`tests/`、`docs/` 等）随本仓许可发布。
- `build/keys/WcpPublicKey.snk` 是**公钥**（生成物用 `PublicSign` 公开签名），不含私钥。


- 上游 `upstream/wpf/**`：**MIT**（见其 `LICENSE.TXT`）。
- `build/fonts/*.ttf`：**SIL OFL 1.1**（见 `build/fonts/LICENSE-OFL.txt`）。
- 其余新增部分：随本仓许可发布（发布时由作者选定具体许可证）。

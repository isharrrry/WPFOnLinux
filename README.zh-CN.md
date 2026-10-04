# WPF on Linux —— 把 `dotnet/wpf` 移植成 Linux 原生可编译 ＋ 可渲染

[English](README.md) | **中文** | [Español](README.es.md)

**Windows / 原始** ｜ [**Linux / 移植**](docs.Linux/README.md)

**它是什么**：本仓让一个 WPF 应用**在 Linux 上从源码编译、开窗、真的画出界面、并且能用鼠标键盘操作**。
**边界（明说）**：**不**追求与"在 Windows 上编译好的 WPF 二进制"兼容 —— 这条边界砍掉了整条二进制兼容路线的工作量。
上游快照在 `upstream/wpf/`（`dotnet/wpf` 的只读副本，MIT）；上游**原始 README** 已逐字保留为 [`README-Window.md`](README-Window.md)。

---

## 1. 现在能做什么（现读；每条都可复算）

| 能力 | 现读 | 复算入口 |
|---|---|---|
| **编译** WPF 托管层 | 六个程序集（`PresentationCore`／`PresentationFramework`／`WindowsBase`／`System.Xaml`／`DirectWriteForwarder`／`DirectWrite.Linux.Provider`）**0 error**（Release 档） | `WAVE_OWNER=$(whoami) bash build/integration-wave.sh` |
| **原生侧** | `libwpfwin32.so`（Win32/GDI/OEM/GDI+ 面）／`libwpfwic.so`（WIC → Skia 解码）／`wpfgfx_cor3.so`（AOT 的 milcore 渲染核心） | `bash src/WpfGfx.Linux.Native/build-shim.sh` · `bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh` · `bash build/MilBridge/run.sh build` |
| **开窗 ＋ 渲染**（仓内样本） | `samples/WpfTextDemo`：`14/14` 帧非空、`未画种类 0` | `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both` |
| **第三方形态**（仓内判据） | `samples/ThirdPartyMini`：只经 `build/third-party/WpfLinux.props` 接线、不进 sln、产物复制到仓外再跑 | `bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25` |
| **一键验收** | `verify-all.sh`：**64 步**（现读 `64 ✅ / 0 ❌`，`rc=0`） | `bash verify-all.sh` |
| **冻结基线** | `docs/CURRENT-STATE.md:9` ＝ `gen=#82`／`sha16=05c5e521c3b14ace`／整份 `1,248,947 B` | `bash build/MilBridge/tools/baseline-sha-check.sh` |
| **在册缺陷** | `DEFREG=PASS declared=225` | `bash build/MilBridge/tools/defect-registry-check.sh` |
| **PTS／原生 LineServices** | 🟡 **长线（非阻塞项）**：现值位 **可操作 42／实现口径 42**；余下各条逐条具名且已证为合法终点 | `bash build/MilBridge/tools/pts-gap-count-check.sh` |

**"可复算"是本工程的硬要求**：每个结论都得有一条命令能重算，而且**判据件自己也被看着**
（`verify-all` 的 64 步里有相当一部分是"看仪器的仪器"）。

---

## 2. 三条命令（构建 → 开窗 → 验收）

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh                                  # 1. 移植 + 编译（必须认领）
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both   # 2. 开窗 + 渲染
bash verify-all.sh                                                                   # 3. 一键验收（64 步）
```

> ⚠️ `WAVE_OWNER` 是**结构约束**（不是礼貌）：没有它 `integration-wave.sh` 直接退出。
> 手工改 `build/*.Linux/*.csproj` 会在下一次 `port-lib.py` 重生成时被抹掉 —— 接线必须落在**应用器**里
> （`src/WpfGfx.Linux.Native/tools/patch-*.py`）。
> 环境准备（依赖、`setup-env.sh`、`verify-env.sh`）见 [`docs.Linux/guide/building.md`](docs.Linux/guide/building.md)；
> 入门见 [`docs.Linux/guide/getting-started.zh-CN.md`](docs.Linux/guide/getting-started.zh-CN.md)；
> 跑样本见 [`docs.Linux/guide/running-samples.zh-CN.md`](docs.Linux/guide/running-samples.zh-CN.md)。

---

## 3. 去哪看（导航）

| 入口 | 是什么 |
|---|---|
| [`README-Window.md`](README-Window.md) | **上游 `dotnet/wpf` README 原文**（逐字保留；上游身份与许可可追溯） |
| [`docs/README.md`](docs/README.md) | **原始 / Windows 侧**文档总线（规范 / 现状 / 证据 / 历史 四分类） |
| [`docs.Linux/README.md`](docs.Linux/README.md) | **移植 / Linux 侧**文档总线 —— 主题 × 语言表 ＋「我想做 X → 读哪件」（[中文](docs.Linux/README.zh-CN.md) · [Español](docs.Linux/README.es.md)） |

两根的名字就是规则：**`X` = 原始 / Windows 侧**，**`X.Linux` = 移植 / Linux 侧**
（冻结的命名约定见 [`docs.Linux/design/_PHASE0-NAMING-CONVENTION.md`](docs.Linux/design/_PHASE0-NAMING-CONVENTION.md)）。

---

## 4. 已知边界（诚实清单）

- 权威件构建配置 = **`Release`**（唯一声明 `build/SelfBuiltConfig.props`；自检 `bash build/selfbuilt-config.sh --check`）。
- 九个权威产物**不进 git**（`src/WpfGfx.Linux.Native/bin/` 被忽略）⇒ 干净克隆取不回，**必须重建**。
- Windows-only 特性的处理口径：能降级的降级（DWM＝"有 DWM、合成关闭"），做不到的**如实失败**（返回错误码，不假装成功）。
- 第三方实证（HandyControl 样本）在**仓外** ⇒ 它是产品事实，**不单独构成仓内判据**；仓内判据见 `samples/ThirdPartyMini`。
- 逐条细节见 [`docs/CURRENT-STATE.md`](docs/CURRENT-STATE.md)（**接手先读这一个文件**）、
  [`docs/ROUTES.md`](docs/ROUTES.md)（权威路线图）、[`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`](samples/WpfFeatureProbe/KNOWN-DEFECTS.md)（在册缺陷册）、
  [`build/MilBridge/HANDOFF-NEXT.md`](build/MilBridge/HANDOFF-NEXT.md)（现读交接件）。
- 本门面**重写前**的根 `README.md`（含逐波 dated 更正 `T-A33`…`T-B19`）**原文另存**于
  [`docs.Linux/evidence/README-dated-archive.md`](docs.Linux/evidence/README-dated-archive.md)。

---

## 5. 许可

- 上游 `upstream/wpf/**` 沿用其 **MIT** 许可（`upstream/wpf/LICENSE.TXT`）。
- `build/fonts/*.ttf`：**SIL OFL 1.1**（见 `build/fonts/LICENSE-OFL.txt`）。
- 本仓新增部分（`build/`、`src/WpfGfx.Linux*`、`samples/`、`tests/`、`docs/`、`docs.Linux/` 等）随本仓许可发布。

---

[English](README.md) | **中文** | [Español](README.es.md) · [Linux / 移植文档总线](docs.Linux/README.md) · [Windows / 原始文档总线](docs/README.md)

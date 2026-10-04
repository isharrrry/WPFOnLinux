# 入门（getting started）

[English](getting-started.md) | **中文** | [Español](getting-started.es.md)

> 本文属于 **docs.Linux** —— 回 [移植侧文档总线](../README.zh-CN.md)（[English](../README.md) · [Español](../README.es.md)）。
> 名词想先弄懂就先读 §4；只想想跑起来，照 §3 走。

**它是什么**：本仓让 WPF 应用**在 Linux 上从源码编译、开窗、真的画出界面、并能用鼠标键盘操作**。
**它不是什么**：**不**追求与"在 Windows 上编译好的 WPF 二进制"兼容（那条路被明确砍掉）。

---

## 1. 先决条件

| 需要 | 说明 |
|---|---|
| Linux（x86-64）+ X server | 跑样本要一个 X（无头机器用 `Xvfb`；`verify-all.sh` 与样本 runner 都会自己起） |
| .NET SDK | 仓内 [`global.json`](../../global.json) 锁 **`10.0.111`**（`rollForward=latestFeature`）；`dotnet --version` 自检 |
| C 工具链 | 原生 shim 需要 `gcc` + `libx11-dev`；AOT milcore 需要 `clang` |
| 系统库 | `zlib1g-dev`；跑验收还需要 `xvfb`／`x11-utils`／`imagemagick`／`fontconfig` |
| 磁盘 | 源码 ＋ 产物较占地方（上游快照 + 各工程 `bin/obj`） |

一键装环境（含 NuGet 源、SkiaSharp 预热、测试字体）与自检：

```bash
bash build/setup-env.sh      # ⚠️ 它会把 NuGet 源写成国内镜像（脚本内 NUGET_MIRROR）；正常网络请自行改回 nuget.org
bash build/verify-env.sh     # 打印环境清单，逐项 OK/WARN/FAIL
```

---

## 2. 你要花多久理解它

三步就够（细节各自成篇）：

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh                                  # 移植 + 编译
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both   # 开窗 + 渲染
bash verify-all.sh                                                                   # 一键验收（64 步）
```

- 第 1 条是"**移植 + 构建**"的唯一入口，必须**认领**（`WAVE_OWNER`）——详见 [building.zh-CN.md](building.zh-CN.md)。
- 第 2 条自己起 `Xvfb :97`、截屏、判四条（进程活着／`未画种类 0`／截图非空非纯色／逐特性颜色计数）——详见 [running-samples.zh-CN.md](running-samples.zh-CN.md)。
- 第 3 条是门禁本体（`Xvfb :99`）——它跑的不只是"我们的测试"，还有一堆"**看仪器的仪器**"。

---

## 3. 名词表（本仓特有，先记住这十个）

| 词 | 意思 |
|---|---|
| **上游 / vendored** | `upstream/wpf/**` = `dotnet/wpf` 的**只读**快照（构建的输入）。改它 = 打穿"上游字节可复算"这条证据 |
| **port-lib** | `build/port-lib.py`：把上游 csproj 转成 Linux 可编译 csproj，**整体重写** `build/<工程>.Linux/*.csproj` |
| **应用器（applier）** | `src/WpfGfx.Linux.Native/tools/patch-*.py`：把接线**补丁式**写进生成物（幂等、`--check`、锚点数断言）。**手改 csproj 会被 port-lib 抹掉 ⇒ 接线只能写这里** |
| **预应用器** | `tools/wire-*.py`：改的是 **port-lib 的输入**，所以必须先跑它再跑 port-lib（例：`wire-uiautomation-resolver`） |
| **波（wave）** | 一次"移植＋构建＋验收"的整批动作，必须**认领**（`WAVE_OWNER`），留审计行 `build/wave-audit.log` |
| **牙（jaw）** | `build/MilBridge/tools/*.sh|py` 里的判据件：纯读、秒级、多数在 `verify-all.sh` 里有对应步；三态 `PASS/FAIL/NOINFO`，**`NOINFO` 不算绿** |
| **五臂对拍** | `tline`／`tab-*`／`textlineproto`：Linux 与 Windows 真值逐行比；臂日志 sha 有机器声明 |
| **冻结基线** | `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 是唯一权威；整份 sha **只由** `docs/CURRENT-STATE.md:9` 那一行机器声明 |
| **九位产物** | 九个权威件的 sha16 逐位记录在冻结块里；它们**不进 git**（`src/WpfGfx.Linux.Native/bin/` 被忽略）⇒ 干净克隆必须重建 |
| **已知红** | `build/MilBridge/known-red.json` ＋ 声明表：红必须是**登记过的**，不许口头豁免 |

---

## 4. 常见误区（新人最容易踩的五个）

1. **以为 `build/*.Linux/*.csproj` 可以手改** —— 可以改，但下一次 `integration-wave.sh` 就抹掉，而且**不报错**。接线写应用器。
2. **以为 `src/Microsoft.DotNet.Wpf/` 里是我们的 Windows 源** —— 现在 **`src/` 只有移植新增件**（`WpfGfx.Linux`、`WpfGfx.Linux.Native`）；Windows 源在 `upstream/wpf/**`（只读）。对照表见 [`../upstream/layout.zh-CN.md`](../upstream/layout.zh-CN.md)。
3. **把 `NOINFO` 当绿** —— 本仓纪律：取不到 ≠ 通过。判据三态，`NOINFO` 一律要人看。
4. **以为"文档说的就是现状"** —— 现状只认 [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md)（机器行 `:9`）与 [`docs/ROUTES.md`](../../docs/ROUTES.md)。
5. **以为第三方实证在仓内** —— 真实第三方（HandyControl 示例）在**仓外**；仓内判据是 `samples/ThirdPartyMini`。

---

## 5. 下一步去哪

- 构建细节 → [building.zh-CN.md](building.zh-CN.md)
- 跑样本 / 看窗口 → [running-samples.zh-CN.md](running-samples.zh-CN.md)
- 架构与数据流 → [../design/architecture.zh-CN.md](../design/architecture.zh-CN.md)
- 想上手改代码 → [../design/contributing.zh-CN.md](../design/contributing.zh-CN.md) ＋ 规范 [`docs/PORT-SPEC.md`](../../docs/PORT-SPEC.md)
- 现在到哪了 → [`docs/CURRENT-STATE.md`](../../docs/CURRENT-STATE.md) ／ 接手件 [`build/MilBridge/HANDOFF-NEXT.md`](../../build/MilBridge/HANDOFF-NEXT.md)

---

[English](getting-started.md) | **中文** | [Español](getting-started.es.md) · [移植侧文档总线](../README.zh-CN.md) · [构建](building.zh-CN.md) · [跑样本](running-samples.zh-CN.md)

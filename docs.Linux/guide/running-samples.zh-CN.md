# 跑样本（running samples）

[English](running-samples.md) | **中文** | [Español](running-samples.es.md)

> 本文属于 **docs.Linux** —— 回 [移植侧文档总线](../README.zh-CN.md)（[English](../README.md) · [Español](../README.es.md)）。
> 前提：先按 [building.zh-CN.md](building.zh-CN.md) 编出来（`WAVE_OWNER=$(whoami) bash build/integration-wave.sh`）。

---

## 1. 门禁样本：`WpfTextDemo`（一条命令）

```bash
bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both
```

- 它**自己起** `Xvfb :97`（1280x1024x24；:99 是 `verify-all.sh` 的，别抢），跑完只杀**自己起的那个**进程。
- **两档都要过**，只过一档 = 失败：
  - **默认档** = 清空全部 `WPF_LINUX_*`／`HLWPF_*` 字体 env（**这才是真应用拿到的配置**）；
  - **env 档** = 只作对照。
- 判据四条：进程存活 ＋ `未画种类 0` ＋ 截图非空非纯色 ＋ 逐特性颜色计数。
- 机读行：`WPTD_SUMMARY`／`WPTD_GATE`，并打印每帧 PNG 路径（人眼复核用）。

## 2. 第三方形态样本：`ThirdPartyMini`（仓内判据）

```bash
bash samples/ThirdPartyMini/run-thirdparty-mini.sh 25
```

- 它只经 `build/third-party/WpfLinux.props` 接线、**不进 sln**、产物**复制到仓外**再跑 —— 就是"真实第三方应用"会走的那条路。
- 配方逐条说明见 [`docs/THIRD-PARTY-APPS.md`](../../docs/THIRD-PARTY-APPS.md)；它是 `verify-all.sh` 的一步。

## 3. 其它样本与探针

| 样本 | 用来做什么 | 入口 |
|---|---|---|
| `samples/HelloWpf` | 最小 WPF 应用（宿主与生命周期） | `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-hellowpf.sh` |
| `samples/HelloMil` | 直接打 MIL（不经过 XAML）的最小验证 | 见 `samples/HelloMil/`（`HelloMil.Tests` 有对应用例） |
| `samples/WpfFeatureProbe` | **特性探针**（逐块开关，事故现场复现） | `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpfprobe.sh`；缺陷册 [`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`](../../samples/WpfFeatureProbe/KNOWN-DEFECTS.md) |
| `samples/WpfTextDemo` | **门禁样本**（冻结基线就是它的） | 见 §1 |

> 探针的变体 runner（`run-wpfprobe-mutation.sh`／`run-wpfprobe-inputleg-tooth.sh`／`run-wpfprobe-1400rate.sh`）与最小复现 `run-wpftextdemo-minrepro.sh` 都在 `tests/WpfGfx.Linux.Tests/Presentation.Tests/` 下。

## 4. 测试套件（`tests/`）

- `tests/WpfGfx.Linux.Tests/{Commands,ManagedLayer,Rendering,Windowing,Presentation,HelloMil}.Tests` —— 各域 `dotnet test` 工程。
- `tests/parity/**` —— 与 Windows 真值对拍的语料（**占空间**；两份大 JSON 已在 `.gitignore` 里，**排除 ≠ 删除**）。
- `tests/golden/**`、`tests/U1-golden/**` —— 金样本；`tests/Rendering.Harness` —— 渲染 arm。
- `tests/flaky-loop.sh` —— 抖动排查用的重复跑器。

## 5. 无头机器 / 显示号约定

| 显示号 | 谁用 |
|---|---|
| `:97` | `run-wpftextdemo.sh`（样本 runner 自己起） |
| `:99` | `verify-all.sh`（门禁自己起） |
| 其它 | 车道私有装置；`verify-all.sh --no-x` 可**不启动 Xvfb**（缺 `DISPLAY` 的用例会跳过部分用例 —— 那是缺测，不是通过） |

## 6. 读机读行（三条纪律）

1. **要的是判词行，不是退出码**：`WPTD_GATE=`、`BASELINE … result=`、`PTSGAP=`、`DEFREG=` 这类行才是结论。
2. **`NOINFO` 不算绿**：取不到就说取不到。
3. **成对读数**：改前/改后（或开闸/关闸）各一串，才算证据。

---

[English](running-samples.md) | **中文** | [Español](running-samples.es.md) · [移植侧文档总线](../README.zh-CN.md) · [入门](getting-started.zh-CN.md) · [构建](building.zh-CN.md)

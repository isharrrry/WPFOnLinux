# docs.Linux —— 移植 / Linux 侧文档总线

[English](README.md) | **中文** | [Español](README.es.md)

**Windows / 原始** ｜ **Linux / 移植**（本页）　·　[仓根门面](../README.md) · [原始 / Windows 侧文档总线](../docs/README.md)

本目录是**成对两根**中的**移植 / Linux 侧**：`docs/`（原始 / Windows 侧）＋ `docs.Linux/`（本目录）。
两条规矩：

1. **每篇三语**：`.md`（默认 · 英）／`.zh-CN.md`（**权威原文**）／`.es.md`（译文）。每篇顶部都有语言切换行，三语互相可达。
2. **命名成对**：`X` = 原始 / Windows 侧，`X.Linux` = 移植 / Linux 侧
   （冻结件 [`design/_PHASE0-NAMING-CONVENTION.md`](design/_PHASE0-NAMING-CONVENTION.md)）。

> 📌 **现状权威不在本目录**：本目录是**移植侧的入门 / 设计 / 上游化专章**。要看"现在到底到哪了"，
> 读 [`docs/CURRENT-STATE.md`](../docs/CURRENT-STATE.md)（冻结基线，机器行在第 9 行）与 [`docs/ROUTES.md`](../docs/ROUTES.md)（权威路线图）。
> 历史证据（波次 / 车道报告 / 交接账）见 [`evidence/README.md`](evidence/README.md) —— **本区为历史证据，勿据此判现状**。

---

## 1. 主题 × 语言

| 主题 | 语言版本 | 讲什么 |
|---|---|---|
| **入门（getting started）** | [English](guide/getting-started.md) · [中文](guide/getting-started.zh-CN.md) · [Español](guide/getting-started.es.md) | 本仓是什么、能否先跑起来、最小三步、名词表（`port-lib`／应用器／器／牙／波…）、常见误区 |
| **构建（building）** | [English](guide/building.md) · [中文](guide/building.zh-CN.md) · [Español](guide/building.es.md) | 依赖与 `setup-env.sh`／`verify-env.sh`、生成式构建模型（`port-lib.py` **整体重写** csproj）、应用器纪律、`integration-wave.sh` 四段、Release 的唯一声明 |
| **跑样本（running samples）** | [English](guide/running-samples.md) · [中文](guide/running-samples.zh-CN.md) · [Español](guide/running-samples.es.md) | `WpfTextDemo`（门禁样本）、`ThirdPartyMini`（第三方形态）、`HelloMil`／`HelloWpf`／`WpfFeatureProbe`、`Xvfb` 与两档口径、机读行怎么读 |
| **架构（architecture）** | [English](design/architecture.md) · [中文](design/architecture.zh-CN.md) · [Español](design/architecture.es.md) | 四层（移植生成 → 六个托管程序集 → 原生 shim → AOT milcore）、数据流、九位产物与冻结基线、门禁的"看仪器的仪器" |
| **贡献（contributing）** | [English](design/contributing.md) · [中文](design/contributing.zh-CN.md) · [Español](design/contributing.es.md) | 认领一条路线、写域、`WAVE_OWNER`、发波链、接线必须落在应用器、`NOINFO` 纪律、三语与命名约定 |
| **上游布局对照（upstream layout）** | [English](upstream/layout.md) · [中文](upstream/layout.zh-CN.md) · [Español](upstream/layout.es.md) | 上游 **21 个工程子树**逐行：上游路径 ↔ 本仓现状数据流 ↔ Linux 覆盖 / 替换 |
| **Linux 覆盖层（linux overlay）** | [English](upstream/linux-overlay.md) · [中文](upstream/linux-overlay.zh-CN.md) · [Español](upstream/linux-overlay.es.md) | 覆盖层由哪几块构成（`src/WpfGfx.Linux/**`、`src/WpfGfx.Linux.Native/**`、`build/shims/**`、应用器）、原生三件怎么与上游对位 |
| **证据索引（evidence index）** | [English](evidence/README.md) · [中文](evidence/README.zh-CN.md) · [Español](evidence/README.es.md) | **导航**：波次预登记 / 车道报告 / `handoff` / `ROUTES` / `history` 各在哪、为什么**留在原位**不搬 |

> 阶段 0 的两件产物（本区内部件，未译）：[`design/_PHASE0-NAMING-CONVENTION.md`](design/_PHASE0-NAMING-CONVENTION.md)（命名约定冻结件）、
> [`evidence/_PHASE0-READERS-INVENTORY.md`](evidence/_PHASE0-READERS-INVENTORY.md)（证据件读者清点表）。

---

## 2. 我想做 X → 读哪件

| 我想…… | 去读 |
|---|---|
| **先把它跑起来** | [guide/getting-started.zh-CN.md](guide/getting-started.zh-CN.md) |
| **从零构建**（要装什么、跑哪条命令） | [guide/building.zh-CN.md](guide/building.zh-CN.md) → 然后 `WAVE_OWNER=$(whoami) bash build/integration-wave.sh` |
| **看见窗口 / 跑样本** | [guide/running-samples.zh-CN.md](guide/running-samples.zh-CN.md) → 然后 `bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 60 --tier both` |
| **一键验收（64 步）** | `bash verify-all.sh`（口径见 [guide/building.zh-CN.md](guide/building.zh-CN.md) §验收） |
| **找入口（该跑哪条脚本）** | [../Guide.Linux/README.md](../Guide.Linux/README.md) —— 一键入口清单（`verify-all.sh` / `integration-wave.sh` / `close-wave.sh`） |
| **看懂整体怎么搭的** | [design/architecture.zh-CN.md](design/architecture.zh-CN.md) |
| **上手改代码 / 认领任务** | [design/contributing.zh-CN.md](design/contributing.zh-CN.md) ＋ 规范 [`docs/PORT-SPEC.md`](../docs/PORT-SPEC.md) |
| **找某个上游工程在我们这儿落到了哪** | [upstream/layout.zh-CN.md](upstream/layout.zh-CN.md) |
| **看我们改了 / 替换了上游哪些东西** | [upstream/linux-overlay.zh-CN.md](upstream/linux-overlay.zh-CN.md) |
| **查历史证据（某一波/某条车道当时干了什么）** | [evidence/README.zh-CN.md](evidence/README.zh-CN.md) |
| **看现在到底到哪了（权威）** | [`docs/CURRENT-STATE.md`](../docs/CURRENT-STATE.md)（机器行 `:9`）＋ [`docs/ROUTES.md`](../docs/ROUTES.md) |
| **接手一个新会话** | [`build/MilBridge/HANDOFF-NEXT.md`](../build/MilBridge/HANDOFF-NEXT.md)（§5 纪律 / §7 重建存活态的七条命令） |
| **理解命名（为什么到处是 `.Linux`）** | [design/_PHASE0-NAMING-CONVENTION.md](design/_PHASE0-NAMING-CONVENTION.md) |
| **看上游原始 README** | [`README-Window.md`](../README-Window.md) |

---

## 3. 本区的纪律（写文档时照这个来）

- **三语可达**：新增一篇 ⇒ 三份同名的 `.md`／`.zh-CN.md`／`.es.md`，每份顶部一行语言切换；**导航链接与命令必须齐全且正确**。
- **中文是权威原文**，英 / 西是译文（可精简，但**链接与命令不许缺**）。
- **事实必须来自现场**：命令要真能跑（例如 `WAVE_OWNER=$(whoami) bash build/integration-wave.sh`、`bash verify-all.sh`）；
  口径不许写死旧数（例：步数一律引**现行** `verify-all.sh` 的 `VERIFYALL-STEPS-DECL`，现读 **64 gen=#82**）。
- **本区不是现状权威**：涉及"现在如何"的说法一律指向 [`docs/CURRENT-STATE.md`](../docs/CURRENT-STATE.md) / [`docs/ROUTES.md`](../docs/ROUTES.md)。

---

[English](README.md) | **中文** | [Español](README.es.md) · [仓根门面](../README.md) · [docs/ 总线](../docs/README.md) · [证据索引](evidence/README.zh-CN.md)

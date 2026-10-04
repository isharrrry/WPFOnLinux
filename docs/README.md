# `docs/` —— 原始 / Windows 侧文档总线

[English](README.md) · [Linux / 移植文档总线](../docs.Linux/README.md) · [中文](../docs.Linux/README.zh-CN.md) · [Español](../docs.Linux/README.es.md)

本目录是**成对两根**中的**原始 / Windows 侧**：`docs/`（本目录）＋ [`docs.Linux/`](../docs.Linux/README.md)（移植 / Linux 侧）。
`docs/` 装的是**本仓自己的工程规范、现状与证据链**；上游 `dotnet/wpf` 的原始 README 逐字保留在仓根 [`README-Window.md`](../README-Window.md)。
"看哪个平台"只需认一个目录后缀 —— **`X` = 原始 / Windows 侧**，**`X.Linux` = 移植 / Linux 侧**（冻结约定见 [`docs.Linux/design/_PHASE0-NAMING-CONVENTION.md`](../docs.Linux/design/_PHASE0-NAMING-CONVENTION.md)）。

> ⚠️ **本目录是"判据驱动"的证据面，不是入门材料。** 想上手请走 [`docs.Linux/guide/`](../docs.Linux/guide/getting-started.zh-CN.md)；
> 想看"我想做 X → 读哪件"请走 [`docs.Linux/README.md`](../docs.Linux/README.md)。
> 本目录里被**冻结机器读取**的件（`WAVE*-PREREGISTRATION.md`、`ROUTES.md`、`CURRENT-STATE.md`、`handoff.md`…）**一个字节都不许搬** —— 依据 [`INDEX.md`](INDEX.md) §4「刻意不做大搬家」，读者清点见 [`docs.Linux/evidence/_PHASE0-READERS-INVENTORY.md`](../docs.Linux/evidence/_PHASE0-READERS-INVENTORY.md)。

---

## 1. 规范（**normative**，动手前必读）

| 文件 | 是什么 |
|---|---|
| [`INDEX.md`](INDEX.md) | **文档地图**：把本目录分成"规范 / 现状 / 证据 / 历史"四类，并说明命名约定 |
| [`PORT-SPEC.md`](PORT-SPEC.md) | **工程规范**：判据纪律、取证纪律、写域纪律、缺陷登记、发波链、并行约定、推翻流程 |
| [`ROUTES.md`](ROUTES.md) | **并行子路线图**（`R1…R10`）：每条路线的目标／现状／写域／判据／依赖，以及"怎么认领一条路线"；`§13` = 任务树，`§15x+` = 逐波记录 |
| [`FORK-AND-PUSH.md`](FORK-AND-PUSH.md) | 从 fork 上游到把工作推上 `feat-Linux`（含 `.gitignore` 验证与待还账） |
| [`PREREG-TEMPLATE.md`](PREREG-TEMPLATE.md) | **预登记四要件（回归判定）的权威处**：模板骨架 ＋ 判定依据 ＋ 现算样本量参考 |
| [`UPSTREAM-PROVENANCE.md`](UPSTREAM-PROVENANCE.md) | 上游快照的出处与**可复算完整性指纹**（`M1–M4`）＋"把 commit 钉死"的配方 |

## 2. 现状与验收（**current**）

| 文件 | 是什么 |
|---|---|
| [`CURRENT-STATE.md`](CURRENT-STATE.md) | 状态板；**第 9 行是机器行**（`> BASELINE-FROZEN gen=#NN sha16=…`），门禁读它 —— **接手先读这一个文件** |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | 架构总览（分层、件与职责、数据流）；移植侧对应篇见 [`docs.Linux/design/architecture.zh-CN.md`](../docs.Linux/design/architecture.zh-CN.md) |
| [`unimplemented.md`](unimplemented.md) | 未实现面清单（MIL 命令／接口的 C 类），路线 `R4`／`R6` 的原料 |
| [`RELEASE-READINESS.md`](RELEASE-READINESS.md) | 发布准备清单（含 `.gitignore` 的口径说明） |
| [`THIRD-PARTY-APPS.md`](THIRD-PARTY-APPS.md) | 第三方 WPF 应用接入配方（对应 `build/third-party/WpfLinux.props`） |
| [`WIN-INTEROP.md`](WIN-INTEROP.md) | Win32 互操作面（`Win32ShimResolver`、ALC 级钩子、导出面口径） |
| [`duce-commands.txt`](duce-commands.txt) | Duce（MIL 命令流）可用命令台账（工具读） |

## 3. 波与冻结链（**evidence**：改动为什么被允许、被谁验证过）

- [`WAVE<NN>-PREREGISTRATION.md`](WAVE82-PREREGISTRATION.md) —— **判据先写死**的预登记；现读 `WAVE*.md` **67 件**（其中 `WAVE*-PREREGISTRATION.md` 全域 **63 件**被四处 glob 机读）。
- [`history/`](history/) —— **零引用的孤立文档**（`U2-resource-pipeline-audit.md`、`WAVE32/45-PREREGISTRATION.md` 等）。
- [`m7c-accept.png`](m7c-accept.png) · [`m7c-accept-zero-probe.png`](m7c-accept-zero-probe.png) —— 验收截图。
- 车道报告不在本目录：`build/MilBridge/<车道号>-report.md`（**证据日志**；`repin-generation.py --check` 会读其中几件 ⇒ **不要移动/删除**）。
- 逐波技术账：仓根 [`handoff.md`](../handoff.md)（已压缩，只保留 `DEFREG` 要求的编号行）；现读交接件是 [`build/MilBridge/HANDOFF-NEXT.md`](../build/MilBridge/HANDOFF-NEXT.md)。

## 4. 历史（**history**）与两个预留子目录

- [`history/`](history/) 只放**零引用的孤立文档**。**本仓刻意不做"大搬家"**：老波预登记与老报告都被后续文档**逐条引用**，移动它们会让引用失效、并可能打穿冻结记录的"证据日志"⇒ 历史件**留在原位**（[`INDEX.md`](INDEX.md) §4）。
- [`guide/`](guide/README.md) —— **预留**（阶段 0 建）：上游 `Documentation/` 的构建 / 上手内容将来抽到这里（现为占位件）。
- [`evidence/`](evidence/README.md) —— **预留**（阶段 0 建）：win 侧波次 / 车道 / 冻结证据的归位点（现为占位件）。
- ⏪ 本门面（阶段 1 文档面）**只新增本件与 [`../docs.Linux/**`](../docs.Linux/README.md)，未移动任何既有件**；被冻结机器读取的件按 [`INDEX.md`](INDEX.md) §4 一律留在原位。

## 5. 现读读数（可复算）

| 读数 | 命令 |
|---|---|
| 本目录顶层 `*.md` 件数 | `ls docs/*.md \| wc -l` |
| `WAVE*.md` 件数 | `ls docs/WAVE*.md \| wc -l`（现读 67） |
| 被机读的 `WAVE*-PREREGISTRATION.md`（全域 glob） | `ls docs/WAVE*-PREREGISTRATION.md \| wc -l`（现读 63） |
| 证据件读者清点（84 件逐行） | [`docs.Linux/evidence/_PHASE0-READERS-INVENTORY.md`](../docs.Linux/evidence/_PHASE0-READERS-INVENTORY.md) |

---

[`docs/` 总线](README.md) · [Linux / 移植文档总线](../docs.Linux/README.md) · [中文](../docs.Linux/README.zh-CN.md) · [Español](../docs.Linux/README.es.md) · [`README-Window.md`](../README-Window.md)

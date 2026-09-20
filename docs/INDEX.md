# INDEX —— 文档地图（**先读哪几件、哪些是规范、哪些是历史**）

> 本仓的 md 有 220+ 件，其中**绝大多数是"证据链"**（波预登记、车道报告、冻结记录），**不是**给新人读的入门材料。
> 这份索引把它们分成四类，并说明**命名约定**。规范以 [`PORT-SPEC.md`](PORT-SPEC.md) 为准。

---

## 1. 规范（**normative**，动手前必读）

| 文件 | 是什么 |
|---|---|
| [`../README.md`](../README.md) | 移植版门面：MVP 现状 / 已知问题 / 快速开始 / 架构 30 秒 |
| [`../README-Window.md`](../README-Window.md) | **上游 Windows 版 README 原文**（逐字保留，上游身份与许可可追溯） |
| [`PORT-SPEC.md`](PORT-SPEC.md) | **工程规范**：判据纪律、取证纪律、写域纪律、缺陷登记、发波链、并行约定、推翻流程 |
| [`ROUTES.md`](ROUTES.md) | **并行子路线图**：每条路线的目标/现状/写域/判据/依赖，以及"怎么认领一条路线" |
| [`FORK-AND-PUSH.md`](FORK-AND-PUSH.md) | 从 fork 上游到把工作推上 `feat-Linux` 并设为默认分支（含 `.gitignore` 验证与三笔待还账） |

## 2. 现状与验收（**current**）

| 文件 | 是什么 |
|---|---|
| [`CURRENT-STATE.md`](CURRENT-STATE.md) | 状态板；**第 9 行是机器行**（`> BASELINE-FROZEN gen=#NN sha16=…`），门禁读它 |
| [`../samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`](../samples/WpfTextDemo/ACCEPTANCE-BASELINE.md) | **冻结基线本体**（每代一页；`BASELINESHA`/`BASELINEGEN` 读它） |
| [`../samples/WpfFeatureProbe/KNOWN-DEFECTS.md`](../samples/WpfFeatureProbe/KNOWN-DEFECTS.md) | **在册缺陷册**（`DEFREG` 的 route 件）：现象→判定点→修法→判据→边界 |
| [`../handoff.md`](../handoff.md) | 交接速览（`DEFREG` 的 route 件；1 MB，按代分段） |
| [`unimplemented.md`](unimplemented.md) | 未实现面清单（MIL 命令/接口的 C 类），路线 R4/R6 的原料 |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | 架构总览（分层、件与职责、数据流） |
| [`UPSTREAM-PROVENANCE.md`](UPSTREAM-PROVENANCE.md) | 上游快照的出处与**可复算完整性指纹**（M1–M4）＋"把 commit 钉死"的配方 |
| [`RELEASE-READINESS.md`](RELEASE-READINESS.md) | 发布准备清单（含 `.gitignore` 的口径说明） |

## 3. 波与冻结链（**evidence**：改动为什么被允许、被谁验证过）

- `docs/WAVE<NN>-PREREGISTRATION.md` —— **判据先写死**的预登记（动了九位的那几波：`#15`–`#49`）。**当前代是 `#48` 冻结、`#49` 准备中。**
- `build/MilBridge/<车道号>-report.md` —— **车道报告**（86 件）：每条都带自报 sha16、成对读数、复算命令、边界与 `NOINFO`。**它们是冻结记录的"证据日志"**（`repin-generation.py --check` 会读其中几件）⇒ **不要移动/删除**。
- `$HOME/w21-verify/w<NN>-record.txt`（仓外）—— 冻结记录三段（banner/frozen/record）。
- `docs/WAVE46-CLOSEOUT-RUNBOOK.md` —— 收尾链的详细操作手册（与 `PORT-SPEC` §5 配套）。

## 4. 历史（**history**）

[`history/`](history/) 只放**零引用的孤立文档**（没有任何脚本/文档引用它们，且已被后续文档取代）。
**本仓刻意不做"大搬家"**：老波预登记与老报告都被后续文档**逐条引用**，移动它们会让引用失效、并可能打穿冻结记录的"证据日志"⇒ 历史件**留在原位**，靠这份索引区分"规范/现状/证据/历史"。

## 5. 命名约定

| 前缀 | 含义 |
|---|---|
| `docs/WAVE<NN>-…` | 第 `<NN>` 代波的预登记/进度/收尾文档 |
| `build/MilBridge/<车道>-report.md` | 车道报告（`W<波号><字母>`，例 `W57A`） |
| `build/MilBridge/tools/*.sh` | **判据件/牙**（多数在 `verify-all.sh` 里有对应步；纯读、秒级） |
| `tests/…/run-*.sh` | **验收 runner**（应用门禁、样本 runner、文本 runner） |
| `D-…` | 缺陷 id（在册册：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`） |
| `R-…` | 路线/欠账 id（如 `R-GATE`、`R-CSRC`、`W1`） |

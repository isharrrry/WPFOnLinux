# INDEX —— 文档地图（**先读哪几件、哪些是规范、哪些是历史**）

> ⏪ **dated 2026-09-24**：本索引已按「去陈」后的现场更新（`docs/` 现 **54 件**）。原句写「md 有 220+ 件」，其中**绝大多数是"证据链"**（波预登记、车道报告、冻结记录），**不是**给新人读的入门材料。
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
| [`PREREG-TEMPLATE.md`](PREREG-TEMPLATE.md) | **预登记四要件（回归判定）的权威处**：模板骨架 ＋ 判定依据 ＋ 现算样本量参考（`TASK-0705`；牙 = `build/MilBridge/tools/regression-decision.py`） |

## 2. 现状与验收（**current**）

| 文件 | 是什么 |
|---|---|
| [`CURRENT-STATE.md`](CURRENT-STATE.md) | 状态板；**第 9 行是机器行**（`> BASELINE-FROZEN gen=#NN sha16=…`），门禁读它 |
| [`../samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`](../samples/WpfTextDemo/ACCEPTANCE-BASELINE.md) | **冻结基线本体**（每代一页；`BASELINESHA`/`BASELINEGEN` 读它） |
| [`../samples/WpfFeatureProbe/KNOWN-DEFECTS.md`](../samples/WpfFeatureProbe/KNOWN-DEFECTS.md) | **在册缺陷册**（`DEFREG` 的 route 件）：现象→判定点→修法→判据→边界 |
| [`../handoff.md`](../handoff.md) | ⏪ **已压缩（5283 → 333 行；dated 2026-09-24）**：只保留 `DEFREG` 的 `HO` 路由键要求的 **88 个声明编号行** ＋ 现读指针；旧全文可 `git show <commit>:handoff.md` 逐字取回 |
| [`../build/MilBridge/HANDOFF-NEXT.md`](../build/MilBridge/HANDOFF-NEXT.md) | ⭐ **现读交接件（新会话先读这个）**：§1 世代/九位/指纹｜§5 **23 条纪律**｜§7 **七条命令**重建存活态 |
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

---

## 5. 已删除（**dated 2026-09-24**，主控；删前过两道机器闸）

**闸**：① 该件**已在远端**（`git -C ~/netTest/GitProj/WPFOnLinux cat-file -e HEAD:docs/<f>`）⇒ 删了可 `git show` 逐字取回；② **不被任何工具/脚本引用**（`grep -rlF` 扫 `verify-all.sh`／`close-wave.sh`／`build/*.sh`／`build/MilBridge/tools/**`）。
**另**：`40 份 WAVE*-PREREGISTRATION.md` 是**冻结证据**（冻机器按它断言），**一件未动**；`WAVE46-PERTARGET-PRESENT-DESIGN.md` 是**设计缘由**（为何那样修）⇒ 保留；`T0T1-report.md` **被工具引用** ⇒ 闸挡下、保留。

| 已删文件 | 行数 | 为什么算「过时多余」 |
|---|---|---|
| `U1-command-stream-golden-plan.md`／`U1-windows-probe.md`／`U1a-parity-report.md`／`U1c-geometry-oracle.md` | 106／450／419／364 | **第一阶段（08-30～09-11）**的移植侦察与对拍草稿；结论早已进 `ROUTES §13`／缺陷册／车道报告 |
| `U2-PresentationCore-prep.md`／`U2-PresentationCore-scan.md`／`U2-PresentationFramework-prep.md`／`U2-Themes-prep.md`／`U2-M7b-win32-inventory.md`／`U2-M7b-patch-round-report.md`／`U2-M7b-report.md`／`U2-M7c-report.md` | 484／331／562／224／428／421／582／3363 | 同上；`M7c` 那份 3363 行是当时的工作台账，现由 `ROUTES` ＋ 车道报告承担 |
| `T3-hellowpf-csproj.md`／`T9-roadmap.md` | 658／54 | `T9-roadmap` 是**旧路线图**（已被 `ROUTES.md` 取代）；`T3` 是当初 csproj 接线草稿 |
| `WAVE46-CLOSEOUT-RUNBOOK.md`／`WAVE46-PROGRESS.md`／`WAVE46-DG54-CRITERIA.md` | 958／168／209 | `#46` 的**作业件**（跑法／进度／判据草稿）；该波早已冻结收口，结论在缺陷册与 `§15` 段标题里 |

**合计 17 件／9,781 行**（`docs/*.md`：71 件／23,126 行 → **54 件／13,112 行**）。取回任一件：
```bash
git -C ~/netTest/GitProj/WPFOnLinux log --oneline -- docs/<文件名>
git -C ~/netTest/GitProj/WPFOnLinux show <commit>:docs/<文件名> > /tmp/<文件名>
```
**同日另三笔去陈**：`handoff.md` **5283 → 333 行**（`HO` 键要求的 88 个编号行**逐字保留**；替换前用 `DRC_HO` 指向临时件跑 `DEFREG=PASS` 验过）｜`docs/ROUTES.md` **840 → 606 行**（`§15b–§15y` **24 段**压成「标题 ＋ 一行指针」，**标题全留**以便交叉引用；新增 `§15aa` 收 `#57`–`#59`）｜`README.md` §0 重写（旧 8 行「已知问题」表删除）、§6「权威件是 Debug」更正为 **Release（`#40` 起）**。

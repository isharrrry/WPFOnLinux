# 任务：WPFOnLinux 结构上游化 · 阶段 1（文档面；**一个 subagent**）

> 你**一个人**做完本阶段。先读：`docs/UPSTREAM-ALIGN-PLAN.md`（尤其 §4、§5 阶段 1、§6.13、§6.14）、
> 以及阶段 0 产物 `docs.Linux/design/_PHASE0-NAMING-CONVENTION.md`、`docs.Linux/evidence/_PHASE0-READERS-INVENTORY.md`。

---

## ① 任务目标

把"文档面"按评审口径一次性铺好：**两根**（`docs/` = 原始/Windows 侧、`docs.Linux/` = 移植/Linux 侧）、
**每篇三语**（`.md` 默认英 / `.zh-CN.md` / `.es.md`）、根 `README.md` 改成 ason 式门面。

**产出清单（必须齐）**：

| 组 | 文件 |
|---|---|
| 根门面 | `README.md`（默认·英）、`README.zh-CN.md`、`README.es.md`；**`README-Window.md` 一个字节不改** |
| win 侧总线 | `docs/README.md` |
| linux 侧总线 | `docs.Linux/README.md` ＋ `.zh-CN.md` ＋ `.es.md`（＝主题表 ＋ "我想做 X → 读哪件"） |
| 上游化专章 | `docs.Linux/upstream/layout.{md,zh-CN.md,es.md}`、`docs.Linux/upstream/linux-overlay.{md,zh-CN.md,es.md}` |
| 入门 | `docs.Linux/guide/getting-started.*`、`building.*`、`running-samples.*` |
| 设计 | `docs.Linux/design/architecture.*`、`contributing.*` |
| 证据索引 | `docs.Linux/evidence/README.{md,zh-CN.md,es.md}`（导航 ＋ "本区为历史证据，勿据此判现状"横幅声明） |

---

## ② 边界条款

**允许创建/修改**：只有上面"产出清单"里的件 ＋ `build/MilBridge/tools/root-entries-allowlist-check.sh`（见 §③ C）。

**禁止**（一个字节都不许动）：`README-Window.md`、任何既有 `docs/*.md`（`INDEX.md`/`ROUTES.md`/`PORT-SPEC.md`/`CURRENT-STATE.md`/`ARCHITECTURE.md`/`WAVE*`…）、
`handoff.md`、`build/**`（除上面那一件）、`src/**`、`tests/**`、`samples/**`、`tools/**`、`upstream/**`、`verify-all.sh`、`wpf-linux.sln`。
**禁止** `git add`/`git commit`。**禁止**移动任何既有件。

---

## ③ 硬约束（**先看清楚再动手**）

**A. 根 `README.md` 是"被机器读取的复述位"** —— `build/MilBridge/tools/pts-gap-count-check.sh:437-438` 对**根 `README.md`** 抽两处数：
```
one README.md  '\*\*可操作 [0-9]+／'     ops
one README.md  '／实现口径 [0-9]+\*\*'    impl
```
⇒ 重写后的 `README.md` **必须**仍然**恰好一次**出现 `**可操作 42／实现口径 42**`（现值 `ops=42 impl=42`，与 `ROUTES.md`/`HANDOFF-NEXT.md`/`win32_classification.c` 同值）。
**不许出现第二个 `**可操作 …` 匹配**（`one` = 恰好一条）。写完自证：
```bash
grep -c '^\|\*\*可操作 [0-9]\+／' README.md   # 期望 1
bash build/MilBridge/tools/pts-gap-count-check.sh 2>&1 | tail -1   # 期望 PTSGAP=PASS … ops=42 impl=42
```
旧 `README.md` 里那一大段"dated 更正"（`T-A33`…`T-B19`）**原文另存**到 `docs.Linux/evidence/README-dated-archive.md`（新件），再在门面里用一行链接指过去。**不许丢原文。**

**B. 门面格式照 `ason`**（`/home/links-dev/netTest/GitProj/ason/README.md`）：
顶部语言切换行 `**English** | [中文](README.zh-CN.md) | [Español](README.es.md)`；
再来平台切换行 `**Windows / 原始** | **Linux / 移植**`（后者指 `docs.Linux/README.md`）；
"它是什么 / 现在能做什么 / 三条命令 / 去哪看" ；导航表列 `README-Window.md`、`docs/README.md`、`docs.Linux/README.md`。
`docs.Linux/README.md` 学 `ason/docs/index.md`：**主题 × 语言**表 ＋ **"我想做 X → 读哪件"**表。

**C. 新增根条目要过"根级允许清单"牙**：新增 `README.zh-CN.md` / `README.es.md` ⇒ 必须同趟在
`build/MilBridge/tools/root-entries-allowlist-check.sh` 的内嵌 `ALLOWLIST`（`read_allow()` 的 heredoc）里各加一行
`<名>\t<why>`，`why` **以「移植面：」开头**（**别写「fork 治理件」** —— 那会牵动 `DOC_CAT3` 三方对拍）。
写完自证：`bash build/MilBridge/tools/root-entries-allowlist-check.sh` ⇒ `ROOT_ALLOW=PASS … unknown_fs=0`；
`bash build/MilBridge/tools/root-entries-allowlist-check.sh --selftest` ⇒ `cases=18 pass=18`。

**D. 三语怎么分工**：本仓原文是中文 ⇒ `.zh-CN.md` 是**权威原文**（内容最全），
`.md`（英）与 `.es.md`（西）是**译文**（可为精简版，但**导航链接与命令必须齐全且正确**）。
每篇顶部都要有语言切换行，三语互相可达。

**E. 事实必须来自现场**：`layout.md` 的 21 个工程逐行（`ls upstream/wpf/src/Microsoft.DotNet.Wpf/src/`），
命令要能真跑（如 `WAVE_OWNER=$(whoami) bash build/integration-wave.sh`、`bash verify-all.sh`；
步数口径引现行 `verify-all.sh` 的 `VERIFYALL-STEPS-DECL: 64 gen=#82`，**不许写死旧数**）。

---

## ④ 验收标准（可计算；逐条给命令与原文读数）

| # | 判据 |
|---|---|
| A | 产出清单里**每一个文件**存在：`for f in <清单>; do test -f "$f" \|\| echo MISSING $f; done` ⇒ 无 MISSING |
| B | `grep -c` 根 `README.md` 的 `**可操作 N／` == **1**；`bash build/MilBridge/tools/pts-gap-count-check.sh` ⇒ `PTSGAP=PASS` 且 `ops=42 impl=42` |
| C | `bash build/MilBridge/tools/root-entries-allowlist-check.sh` ⇒ `ROOT_ALLOW=PASS … unknown_fs=0`；`--selftest` ⇒ `pass=18 fail=0` |
| D | `bash build/MilBridge/tools/verify-all-step-check.sh` ⇒ `rc=0`；`bash build/MilBridge/tools/baseline-sha-check.sh` ⇒ `rc=0` |
| E | `git status --short` **不含**对 `README-Window.md`、既有 `docs/*.md`、`handoff.md` 的 ` M `（只允许新增 `??` 与本次点名的改动） |
| F | 三语互达：每篇 `.md` 顶部含指向同名 `.zh-CN.md`/`.es.md` 的链接（`grep -c` ≥ 2，逐篇） |
| G | `docs.Linux/upstream/layout.*` 的工程行数 == `ls upstream/wpf/src/Microsoft.DotNet.Wpf/src/ \| wc -l`（现读 21） |

---

## ⑤ 失败报告格式

已试方案；实际命令与**输出原文**；当前怀疑；是否已改 `README.md`／allowlist（便于回退）。

## ⑥ 完成报告格式

- 逐条判据 → 证据（命令 ＋ 原始读数）。
- 改/增文件清单（含 allowlist 那处改动与 `why` 原文）。
- **主动披露**：与方案不符处、机器读取端的新发现、`README.md` 重写后还有哪些既有引用（如 `docs/INDEX.md` 指向 `README.md` 的行）需要后续阶段同步。
- 一句话"阶段 2（证据件归位，走**索引折中**）可以开工"的前置是否就绪。

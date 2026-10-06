# 任务：优化 O1／O2／O3／O4／O6（O5 主控已裁定**不做**）

> 现状：`feat-Linux = b1302088e`，工作区干净，`verify-all` **66✅/0❌**，`[5c/6]` 四档 PASS。
> 先读：`docs.Linux/evidence/STRUCTURE-UPSTREAM-WAVE-REPORT.md`、`.agents/tasks/TASK-合并波.md`（**七类路径语义**＋回退纪律）、
> `.agents/tasks/TASK-根治-提交号载体.md`。
> **本任务可能触碰门禁本体与产物路径，凡"做了不绿"的项一律按 §⑦ 回退该项，不得留半改。**

---

## O1 · 九位权威路径表做成**单一来源**（消除"两份表手工同步"）

**现场**：`src/Linux/build/MilBridge/tools/wave-freeze-consistency-check.py` 有仓内 `NINE_PATHS`；
外部冻结器 `~/w21-verify/w27-freeze.py:1615` 另有一份 `NINE`（**本轮已手工改成现落点**，但它自己的注释写着
"不修 `NINE`（改它属另一趟）"）。两份表＝同一语义两处 ⇒ 必然分叉（本波就栽在这）。

**做法（推荐顺序）**：
1. 在**仓内**加一个只读导出端：`python3 <wave-freeze-consistency-check.py> --emit-nine` ⇒ 打印 `路径<TAB>键`（或直接生成冻结器可吃的形式）；
2. 让**外部冻结器**改为**读仓内导出**（`~/w21-verify/w27-freeze.py` 的 `NINE` 处改成读
   `src/Linux/build/MilBridge/nine-paths.tsv`，该 tsv 由导出端生成并**入库**）；**先备份** `w27-freeze.py`。
3. 加一台**一致牙**：断言"冻结器实际用的九条路径 == 仓内 `NINE_PATHS`"（不等即红、逐条点名）。接进 `verify-all` 与 `fp_inputs()`。
- 判据：改完 `--template auto` 与冻结器只读档在新落点可跑；一致牙绿；**且故意把 tsv 改坏一条 ⇒ 必红点名**（反极性真跑）。

## O2 · 防回归牙：**禁止未登记的 `bin/Debug` 字面量**

**现场**：`src/Linux` ＋ `src/Microsoft.DotNet.Wpf.Linux` 下**仍有 34 个文件**含 `bin/Debug`，而权威配置是
`WpfLinuxSelfBuiltConfiguration`（现读 Release；**唯一读取器** `src/Linux/build/selfbuilt-config.sh`）。这正是本仓老族
"同一语义多处 ⇒ 必然分叉"（R4/R5 已为它修过 ~29 处）。

**做法**：① **逐处三分类**：`真消费点`（必须改成引用唯一来源）／`注释/文档`（可留）／`刻意跨配置`（在册例外）；
② 把"真消费点"改干净（csproj 用 `$(WpfLinuxSelfBuiltConfiguration)`；shell/python 走 `selfbuilt-config.sh`）；
③ 新建 `src/Linux/build/MilBridge/tools/no-hardcoded-config-literal-check.sh`：扫源码面，
   命中且**不在豁免清单**（`.../hardcoded-config-exempt.tsv`，逐条带 `why`＋在册缺陷号）即红、逐条点名；
④ 接进 `verify-all`（**步数会 66→67**：四处声明 ＋ 覆盖面 ＋ `[42] --expect` **同趟**改）。
- 判据：新牙绿；**反极性**：临时塞一处 `bin/Debug` 到真消费点 ⇒ 必红点名；`verify-all` 仍 0 ❌。

## O3 · `verify-all.sh` **数据驱动化**（把"步表"抽出来）

**现场**：`Guide.Linux/verify-all.sh` 1335 行、**66** 处 `run_step`；步名/命令/分类写死在脚本里，
`STEP-NAMES`、`VERIFYALL-STEPS-DECL`、`[42] --expect` **三处**要同趟手改（`#65`/`#74`/`T-D2` 都在这上面栽过）。

**做法（**低风险形态**）**：新建 `src/Linux/build/MilBridge/verify-all-steps.tsv`（列：`seq<TAB>name<TAB>cmd<TAB>needs_x<TAB>bare_tooth`），
`verify-all.sh` 改为**读表执行**；`STEP-NAMES` 与 `VERIFYALL-STEPS-DECL` 的步数**由表派生**（`verify-all-step-check.sh` 仍作牙）。
落地前先做"**等价性证明**"：把改前/改后的 66 条 `name`＋`cmd` 逐条对拍（`diff` 为空）。
- ⚠️ **硬约束**：`bash Guide.Linux/verify-all.sh` 必须仍 **66 ✅ / 0 ❌**，且 `verify-all-step-check.sh` rc=0。
  **若 2～3 种做法仍不能同时成立 ⇒ 回退 O3（如实上报"未做"）**，其余项照做。
- 覆盖面/`--expect` 若因新件变动 ⇒ 同趟登记。

## O4 · 冻结**记录段**进仓（外部只留"现场哨兵"）

**现场**：`~/w21-verify/w<NN>/freeze/w<NN>-record.txt` 是冻结三段（BANNER/FROZEN/RECORD），
`wave-freeze-consistency-check.py` 经 `_freezer_record_txt(freezer)` 读它 ⇒ **换机/CI 不可复现、不能随仓分发**。

**做法**：把记录段改为**仓内可寻址**：`docs.Linux/evidence/freeze/w<NN>-record.txt`（新代起生效；**旧代不回填**，旧路径在 `w27-freeze.py` 里保留兼容读）；
同步改 `w27-freeze.py`（**先备份**）与 `wave-freeze-consistency-check.py` 的取值处；两枚哨兵**仍留仓外**（它们是"现场值"）。
- 判据：`--template auto` 能取到**仓内**记录段；`[5c/6]` 四档 PASS；并在报告里给"旧代仍可读"的成对读数。

## O6 · 入口边界厘清（**主控裁定：不做搬迁**，只做"单一入口清单"）

**现场**：`Guide.Linux/` 现只有 `verify-all.sh`；而 `src/Linux/build/{integration-wave,close-wave}.sh` 是另两个入口。
被引面实测：`verify-all.sh` **588** 件、`close-wave.sh` **497** 件、`integration-wave.sh` **175** 件，
且 **8 颗牙**（`sentinel-spec-check`／`applier-audit`／`wiring-coverage-check`／`timestamp-order-check`／`wave-push`／`check-appliers` 等）**真的调用它们**。
⇒ **搬迁成本 ≫ 收益**（又一次全仓重写，且动门禁）。

**做法（主控裁定，照此执行）**：**不改路径**。改为：
1. 新建 `Guide.Linux/README.md`（三语或单语皆可，注明射程）：**"一键入口清单"**——三个入口的用途、典型调用、各自前置条件与判据；
2. 根 `README*.md` 与 `docs.Linux/README*` 里"去哪找入口"的段落指向这份清单（1 行改动）；
3. 在 `docs.Linux/evidence/STRUCTURE-UPSTREAM-WAVE-REPORT.md` 追加一节，**具名登记**"O6 选了清单式而非搬迁，理由＝被引面 588/497/175 ＋ 8 颗牙真调用"。
- 判据：清单存在且三条入口的调用命令**逐条可跑**（dry 查即可）；根门面指向它；报告里理由成文。

## ⑦ 通用纪律（**每条都适用**）

- **边界**：只许动本任务点名的件 ＋ 同趟必需的四声明/覆盖面/`--expect`/`HANDOFF-NEXT` 更正行；
  **禁止**改产品逻辑、改落点、削弱任何判据、把 `NOINFO` 当绿。
- **改判据/覆盖面内件** ⇒ `inputs_fp` 必移 ⇒ 追加 `HANDOFF-NEXT.md` 的 `cell=#1/#2/#3` 更正行（必要时 `#9`）。
- **顺序（本仓铁律）**：**先把提交做完 → 再冻结 → 最后 `verify-all ×2`**；冻后不再新增提交。
- **回退**：任一项 2～3 种做法仍不能"绿 ＋ 不新增红" ⇒ **回退该项**（`git checkout -- <该件的编辑>`），
  在报告里记"该项未做 ＋ 原因"，其余项照做。**不许留半改状态**（末态 `git status --short` 必须干净或逐条列清）。
- **元方法**：凡是"文档/自述"里的数，**一律现取**，不许搬上一代的数。

## ⑧ 验收（总）

| # | 判据 |
|---|---|
| A | `bash Guide.Linux/verify-all.sh` ×2 各 **0 ❌**（步数按现场 `VERIFYALL-STEPS-DECL`，O2 后应为 67） |
| B | `THIRDPARTY=PASS max_colors ≥ 800`（空帧无回归） |
| C | `[5c/6]` 四档 PASS；八颗关键牙 rc=0（新路径） |
| D | O1/O2/O3/O4/O6 各自的反极性/自证读数**逐条给出** |
| E | `git status --short` 干净；`git log --oneline -5` 列出本任务的提交 |

## ⑨ 报告

逐项：改了什么（文件＋关键行）、成对读数、反极性原文、**是否达成**（未达成写清为什么并说明已回退）。
外带：`inputs_fp`／九位／`verify-all` 步数的前后值；`~/w21-verify/w27-freeze.py` 的备份路径与 sha16。

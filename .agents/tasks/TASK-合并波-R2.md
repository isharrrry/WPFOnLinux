# 任务：结构上游化 · **合并波 第 3 轮**（接第 2 轮的残余清单，走到 D1 → 提交 → 重冻 → D2）

> **纪律与目标全部照旧**：先读 `.agents/tasks/TASK-合并波.md`（全文，含落点映射／七类路径语义／20 处登记／D1-D3／回退条款），
> 再读 `docs.Linux/evidence/STAGE3-SCOPE-REPORT.md`。**本轮只做增量**，不重定落点、不改纪律。

---

## ① 第 2 轮已经拿到的（不必重做，可复用）

- **`dotnet build src/Linux/wpf-linux.sln` = 0 错误**；6 套测试 **818 通过 / 5 失败**。
- 10 颗结构牙已转绿：ROOT-ENTRIES（含 `--selftest 18/18`）、BASELINE-SHA、DEFREG、VERIFYALL-SELF、WIRING-COVERAGE、PARSER-GUARD、SELFDESC-WIRING、WIRING-CLOSURE、HYGIENE…
- **可复用的替换引擎与定点脚本**（仓外，逐序跑）：`/tmp/mw-rewrite3.py` → `/tmp/mw-specials.py` → `/tmp/mw-fix-sln.py` →
  `/tmp/mw-patch1..4.py` → `/tmp/mw-seg3.py` → `/tmp/mw-seg4.py`；回退脚本与前轮备份在 `/tmp/mw-rollback/`、`/tmp/d3-shadow/`、`/tmp/mw-win/`。
→ **先确认这些脚本还在**（`ls /tmp/mw-*.py`）；不在就照 `STAGE3-SCOPE-REPORT` 重写它们。

## ② 本轮的**唯一增量：把这 9 项做掉**

| # | 项 | 现读数（第 2 轮） | 要做到 |
|---|---|---|---|
| 1 | `HANDOFF-NEXT.md` 更正行 | `HANDOFF_MV=DIVERGED mismatch=6` | 按 §④ 追加 `cell=#1/#2/#3/#4/#5/#9` 更正行（格式照该件末行；`inputs_fp` 用现取、覆盖面件数用现取）⇒ `HANDOFF_MV=PASS cells=9 mismatch=0` |
| 2 | `close-wave.sh` 的 `fp_inputs()` | `FP-INPUTS-HYGIENE=NOINFO interception-perturbed` | 把 `fp_inputs()` 的 find 根与拦截口径**同趟收口**到新路径 ⇒ `PASS coverage_n=…` |
| 3 | **`PTSGAP_CITED` 悬空引用** | `CITED=FAIL refs=1`（`docs/ROUTES.md` 引用 `bash build/MilBridge/tools/pts-gap-count-check.sh`） | **主控裁定（见 §③）**：允许改**该处引用路径字符串**，但必须实测三颗牙不变红 |
| 4 | `BOUNDARY-DECL` | `FAIL record-failure` | corpus 路径登记收口 |
| 5 | `STATIC-JAWS` | `rc=1` | 射程/自测路径收口（该件有时效性抖动，首趟红要复跑再定罪） |
| 6 | `.Linux` **分段常量**长尾 | 未清 | `os.path.join(here,"..","..","..","build",…)`、`NormalizeDirectory(…,'..','..') + 'build','fonts'`、`reapply-patches.py` 这类**分段**写法逐处改 |
| 7 | 6 套测试 5 失败 | 818/5 | 修到 **0 失败** |
| 8 | 落 `docs.Linux/evidence/PATH-MAP.md` ＋ `UPSTREAM-MANIFEST.tsv` ＋ 两台新牙 | 未做 | 照 `TASK-合并波.md` Step 3/4；`.md` 一律不机械重写（前两轮一致），旧路径交 PATH-MAP |
| 9 | Step 6 提交 / Step 7 重冻（含**重取五臂**）/ Step 8 D2 / Step 9 删 `upstream/` | 未做 | 照 `TASK-合并波.md` §③ |

## ③ 主控裁定：第 3 项的冲突怎么解（**照此执行，不要自己另择**）

冲突：`"断言面文件内容不动"` × `"路径必须更新"` —— 而 `docs/ROUTES.md`（断言面）里**含功能性引用**（`bash build/...`），
`pts-gap-count-check.sh` 会断言"被引用的件真存在 ⇒ 否则 `PTSGAP_CITED=FAIL`"。

**裁定**：`docs/ROUTES.md` 属"**数值/日期断言面**"（`DEFREG` 看 88 编号行、`pts-gap` 抽复述位数值、`hygiene` 看 sha16），
而**其中那一处 `bash build/...` 是"引用路径"、不是"被断言的数值"**。⇒ 允许**只改那一处的路径字符串**（`build/…` → `src/Linux/build/…`）。

**执行要求（缺一不可）**：
1. 改之前先取**三份读数**：`defect-registry-check.sh`、`hygiene-tooth.sh`、`pts-gap-count-check.sh`（含 `PTSGAP_CITED=` 行）；
2. 改之后**逐条复跑**同一三份；
3. **任何一颗变红 ⇒ 立刻把该处字符串改回原样**，并把该冲突写进报告"待裁决"（**不许**为过关去动 `PTSGAP_CITED_STRICT` 之类削弱判据的开关）；
4. 若三颗全绿 ⇒ 在报告里给出**成对读数**（改前/改后）。

## ④ 边界 / 验收 / 回退

- 边界：照 `TASK-合并波.md` §④。**新增**：`docs/ROUTES.md` 只许改 §③ 那一处引用路径（其余一字不动）。
- 验收：照 `TASK-合并波.md` §⑤（A–G）；**D2 未达就不算完成**。
- 回退：照 `TASK-合并波.md` §⑦；**必须给复原读数**（`git status` 条数、`HEAD`、五牙读数、`inputs_fp`）——
  上两轮都有人只写"已回退"，其中一次实际还在半搬状态。**没有读数 = 不算回退**。

## ⑤ 报告

除 `TASK-合并波.md` §⑥ 要求外，**另加**：
- 第 9 项各步的**原始机读行**（`verify-all` 两趟的步骤通过数、九位/`inputs_fp`/基线前后值、`git log --oneline -3`）；
- §③ 的成对读数（改前/改后三牙）；
- 仍故意留着的旧路径**逐条点名**（以及为什么：属断言面且非引用路径）。

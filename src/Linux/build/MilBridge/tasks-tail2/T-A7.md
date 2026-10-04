# 任务 T-A7 · P4 修复：把 `PtsCache.Linux.cs` 的 `t133`/`t155` 仪器编码进生成器（P8）

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。根因已定位（队长现取）：
- `build/PresentationFramework.Linux/PtsCache.Linux.cs` 是**生成件** —— 由 `build/PresentationFramework.Linux/reapply-patches.py` **从上游** `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsCache.cs` **逐字复制 + `PTSCACHE_EDITS`（现 `5` 处，E1–E5）** 派生（件头自述"不要手改"）。
- 但现盘/`HEAD` 的该件**另含手加的 `t133`/`t155` 仪器块**（`grep -cE 't133|t155|P1NmpTypeProbe'` ＝ `9`）⇒ 属**改生成件**（违铁律 `P8`）⇒ **每趟整波重生成即被抹掉**（`E5` 整波实测 `numstat 16 611`）。
- **正解 ＝ 把那两处编码进生成器**：在 `PTSCACHE_EDITS` 里**新增条目**（`E6`／`E7`…），使 `python3 build/PresentationFramework.Linux/reapply-patches.py` 重生成出的件**包含** `t133`/`t155` 块且**与现盘一致**。

## ② 边界条款
- **只改**：`build/PresentationFramework.Linux/reapply-patches.py`（`PTSCACHE_EDITS` ＋ 若需的件头计数）＋ `build/PresentationFramework.Linux/PtsCache.Linux.cs`（**由重生成产出**，非手改）。
- **黑名单**：其余一切仓内件；`upstream/**` **只读**；`build/port-lib.py`／其它 applier **不改**。
- 安全：跑生成器**前**先 `cp -p PtsCache.Linux.cs ~/t204-captain/bak/PtsCache.Linux.cs.pre-T-A7`；跑后**逐项核**（下 §③）；若生成器产出异常，立刻 `git checkout HEAD -- build/PresentationFramework.Linux/PtsCache.Linux.cs` 复原并如实报。
- 进程只按 PID；禁 `sleep` 轮询；写前备份；模式守恒（`stat -c %a` 前后同）。
- **不要跑** `verify-all`／`static-jaws-check.sh`。最多 3 种方案；失败即报停止。

## ③ 验收标准（可计算）
- ① `python3 build/PresentationFramework.Linux/reapply-patches.py` ⇒ `rc=0` 且该件行含 `needle 全部命中`；件头计数与实条目数一致。
- ② 重生成后的 `PtsCache.Linux.cs`：`grep -cE 't133|t155|P1NmpTypeProbe'` **≥ 9**（含新 `E6`/`E7` 段）；且**逐字节等于现盘**（`cmp` 或 sha16 相等；若仅件头计数变化 ⇒ 允许并逐字说明）。
- ③ **幂等**：连跑两次 ⇒ 两次产出 sha16 相同。
- ④ **零行为改动**：`t133`/`t155` 两块的**代码正文**与改前逐字相同（给出 `diff <(改前) <(改后)` 或逐段 sha16 对拍）。
- ⑤ `DEFREG` rc=0；`REPORTID` rc=0；`git status` 仅动上述两件。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有（已尝试／原文／怀疑／停止；验收映射 ＋ 件级前后对账 ＋ 自包含结论 ＋ 主动披露）。

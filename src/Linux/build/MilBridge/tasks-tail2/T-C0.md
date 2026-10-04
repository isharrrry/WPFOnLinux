# 任务 T-C0 · `TASK-0201` 静默 rc=139 功效重取 —— 只读侦察 ＋ 判据预登记

## ① 任务目标
你是本项目（`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`）的**只读侦察**子代理。为 roadmap `docs/ROUTES.md §13` 的 `TASK-0212` 做侦察＋判据预登记，回答：

1. 在册 `SILENT_SEGV_HIT` **逐字判别式**现取原文（出处在册，见 `build/MilBridge/P0-mvp-segv-report.md` 与 `docs/ROUTES.md`；**整行取，标"仅本次生效"**）。
2. 功效口径：`≥131 腿`（2.26%）／`≥299 腿`（1.00%）的**算法与出处**；本任务要判「现件代 0/N 的 95% 单侧上界」需多少腿。
3. 装置代际：现件代 `.so` 与 `pf` 现取 sha16；腿跑器入口与证据目录（`build/MilBridge/tests/SilentHitProbe/**`、`build/MilBridge/tests/PtsPagesProbe/evidence/**`）。
4. 基线率闸 `BASELINERATE` 现取判词与 `reason`（是否 `VOID-PREMISE`）＋ 喂入所需的时间窗字段从哪里来。

**已确认**：`TASK-0201` 现件代读数 `0/175 ⇒ 95% 单侧 1.6973%`（车道 `t44`）；`TASK-0209` 已随波 `#55` 冻结。

## ② 边界条款
- **只读**：除载体外不许改任何仓内文件；**不跑重活**（≥131 腿的整批留给实现件、走 `~/heavy-slot.sh`）。
- 进程只按 PID；显示位只用空闲 `:23x`；禁 `sleep` 轮询。
- 载体（**唯一可写文件**）：`build/MilBridge/P1-tail2-segv-recon.md`（不用 `report` 字样）。
- 最多 2–3 种方案；失败即报停止。

## ③ 验收标准（可计算）
载体必须含：
- ① `SILENT_SEGV_HIT` 判别式现取原文 ＋ 出处（件:行，仅本次有效）。
- ② 腿数→上界算式（含 `k=0` 与 `k>0` 两支，照 `TASK-0719` 口径）＋ 现件代所需 N。
- ③ 装置入口与证据面清单（逐件路径 ＋ 现取 sha16）。
- ④ `BASELINERATE` 现取判词原文 ＋ `reason=`；缺时间窗时的降级形态。
- ⑤ 判据预登记草案（≥3 条可证伪 ＋ 反极性）供实现件照抄。

## ④ 失败报告格式
同 A0：已尝试／原文／怀疑／停止。

## ⑤ 完成报告格式
同 A0：验收映射 ＋ 自包含结论 ＋ 主动披露。

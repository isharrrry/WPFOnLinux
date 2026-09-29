# 任务 T-D0 · 两颗新牙（`SJC-FIELD-ID` 弱版 ＋ 静默阈值禁令）—— 只读侦察 ＋ 判据预登记

## ① 任务目标
你是本项目（`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`）的**只读侦察**子代理。为 `TASK-0756`（`SJC-FIELD-ID` 弱版）与 `TASK-0757`（「静默阈值禁令」升格为牙）做侦察＋判据预登记。要回答：

1. **落点与接线点**：这两颗牙要落的件（新文件 `build/MilBridge/tools/**`）、要接线的步（`verify-all.sh` 的 `run_step` 表 ＋ 首行 `DECL` ＋ `STEP-NAMES` ＋ 预登记）、要进 `close-wave.sh` 的 `fp_inputs()` 覆盖面（现取件数/`--expect`）——**逐条现取位置**（件:内容锚；行号仅本次有效）。
2. **`SJC-FIELD-ID` 弱版**：判「证据行是否同给『结构偏移 ＋ 写点』两要素」。先在 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 与 `build/MilBridge/*.md` 里**现取**真实的"证据行"样本（正面样本 ＋ 反面样本各 ≥2 条，逐行原文），给出可判的正则口径草案。
3. **静默阈值禁令**：`grep -cE '(if|&&).*>[[:space:]]*[0-9]+.*fprintf'` 的**现取命中**（逐行点名）；缺省行 token 统一形制（`no-leg`）现取样例。
4. **反极性设计**：每颗牙的正极/反极夹具怎么造（喂违规样本 ⇒ 必红；干净 ⇒ 绿）。

**背景**：本波 `t194` 是 `SJC-FIELD-ID` 的反例（标 `dvr_used@+36` 却引 `win32_pts.c:1550/:1554` 子轨出参）；「静默阈值」是恒真断言族第五例候选（`t196`/`t199` 咬过）；`R-7` 在 `build/MilBridge/P1-HANDOFF-20260929.md §12` 已入册。

## ② 边界条款
- **只读**：除载体外不许改任何仓内文件（**不许**改 `verify-all.sh`／`close-wave.sh`／`KNOWN-DEFECTS.md`）。
- **不要跑** `static-jaws-check.sh`（单次 66–81 s）。
- 进程只按 PID；显示位只用空闲 `:23x`；禁 `sleep` 轮询。
- 载体（**唯一可写文件**）：`build/MilBridge/P1-tail2-jaws-recon.md`（不用 `report` 字样）。
- 最多 2–3 种方案；失败即报停止。

## ③ 验收标准（可计算）
载体必须含：
- ① 落点/接线点表（逐条：目标件 + 现取定位 + 改动形态）；含 `verify-all.sh` 现取步数（`grep -c '^run_step "'`）与覆盖面件数（`--expect`）。
- ② `SJC-FIELD-ID` 弱版：正/反样本各 ≥2（逐行原文）＋ 正则口径草案 ＋ 已知假阳/假阴风险。
- ③ 静默阈值：现取命中行逐行点名 ＋ 缺省行 token 样例。
- ④ 两牙的**判据预登记草案**（各 ≥3 条可证伪 ＋ 反极性）。
- ⑤ 同趟接线成本清单（动 `verify-all.sh`／`close-wave.sh` ⇒ 同趟改 `--expect` 与四处声明；并注明"改覆盖面内件 ⇒ 同趟追写 `HANDOFF-MV cell=#1`"）。

## ④ 失败报告格式
同 A0。

## ⑤ 完成报告格式
同 A0。

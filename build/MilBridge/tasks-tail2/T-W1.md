# 任务 T-W1 · 装置收口：`[E3-REPLAY]` 入在册 `trim` 集 ＋ 同代对齐 `cell=#1`

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。做两件收口：

1. **把新 tag `[E3-REPLAY]` 补入在册静默命中剔除集** `build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv`（现取 `d2bcd611f2506ce0`）。背景：`T-C2` 现取表明现件代**每腿无条件发 18 行** `[E3-REPLAY]`（发射点 `src/WpfGfx.Linux.Native/src/win32_x11.c:344`），而在册 `trim` 集**未声明**它 ⇒ 300 腿全判 `NOINFO`、分母 0（`build/MilBridge/P1-tail2-segv-report.md` §边界）。
2. **同代对齐** `build/MilBridge/HANDOFF-NEXT.md` 的 `HANDOFF-MV` 三格（`cell=#1`／`#2`／`#5`）——因为本趟改了**覆盖面内件**（`silenthit-trim.tsv` 在 `fp_inputs()` 覆盖面内）。

## ② 边界条款
- **只改**：`build/MilBridge/tests/SilentHitProbe/silenthit-trim.tsv`（**只增一行** declaration，**不删任何既有行**）／`build/MilBridge/HANDOFF-NEXT.md`（**只加 `cell=#1`／`#2`／`#5` 三条 dated 更正行**，EOF 追加）。
- **黑名单**：`src/**`、`build/*.Linux/**`、其他 `tools/**`、`verify-all.sh`、`build/close-wave.sh`、`docs/**`、`samples/**`。
- **一次只一个写者**；写前 `cp -p` 备份到 `~/t204-captain/bak/`；`temp + rename`；进程只按 PID；禁 `sleep` 轮询。
- 先现取 `[E3-REPLAY]` 行的**逐字形态**（从 `~/t204-captain/c2/logs/**` 或现跑一趟短腿）再定 declaration 的语法（**照 `silenthit-trim.tsv` 既有行的同形**）。
- 最多 3 种方案；失败即如实上报停止。

## ③ 验收标准（可计算）
- ① `silenthit-trim.tsv` **只增一行**（`git diff --numstat` 的删行数 = `0`）；该行为**同形 declaration**。
- ② 用**仓内官方产出端**复核：`bash build/MilBridge/tests/SilentHitProbe/run-silenthit-legs.sh`（或其自带 `--replay`／`--denom` 形态）**在补声明后**，现件代腿**不再全 `NOINFO`**（给出补前 `NOINFO`／补后 `0/N` 的成对读数，或说明为何仍不成立）。
- ③ `HANDOFF-NEXT.md` 三条 `cell=` 行落盘后：`bash build/MilBridge/tools/handoff-machine-values-check.sh` ⇒ `HANDOFF_MV=PASS`（rc=0）。
- ④ `bash build/MilBridge/tools/defect-registry-check.sh` rc=0；`bash build/MilBridge/tools/report-id-domain-check.sh` rc=0。
- ⑤ 主链 `.so` 与 `verify-all.sh`/`build/close-wave.sh` **未动**（逐件 sha16 不变）。

## ④ 失败报告格式
已尝试方案／实际输出原文／怀疑／停止。

## ⑤ 完成报告格式
验收项 → 证据映射（可复跑单行命令原文 ＋ 原始输出）＋ 件级前后对账（备份路径 ＋ 前后 sha16 ＋ numstat）＋ 自包含结论 ＋ 主动披露。

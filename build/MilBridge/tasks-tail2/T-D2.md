# 任务 T-D2 · 实现两颗新牙并接线（`TASK-0756` ＋ `TASK-0757`）

## ① 任务目标
你是本项目的**实现**子代理（写者）。照侦察载体 `build/MilBridge/P1-tail2-jaws-recon.md`（`§1` 接线点表／`§2` 正则草案／`§4` 判据草案／`§5` 成本清单）落地两颗新牙**并同趟接线**：

1. **`TASK-0756` `SJC-FIELD-ID` 弱版** ⇒ 新件 `build/MilBridge/tools/sjc-field-id-check.sh`：判「证据行是否**同给**『结构偏移』＋『写点』两要素」。
2. **`TASK-0757` 静默阈值禁令** ⇒ 新件 `build/MilBridge/tools/silent-threshold-ban-check.sh`：`grep -cE '(if|&&).*>[[:space:]]*[0-9]+.*fprintf'` 命中即红。

**队长裁决（必须照办，覆盖侦察件的"待裁"项）**：
- **(a) 静默阈值牙射程只扫源码**（`*.c`／`*.h`／`*.sh`／`*.py`），**不扫 `*.md`** ⇒ 一举消掉两处：① 载体自指（侦察件自报"全仓 5→9"）；② `build/MilBridge/*.md` 里"引用判据行"的证据件被误判。**判词须写明射程**（只扫源码）。
- **(b) 白名单（豁免）**：`wic_proxy.c` 三处（`g_trace_budget-- > 0` 的有界 trace 预算，非"读数判别式"）纳入**具名豁免清单**；豁免必须**上屏**（`SILENT_THRESHOLD_ALLOW n=… sites=…`），**不静默**。
- **(c) 弱版射程**：限 `build/MilBridge/*.md`（侦察现取 `KNOWN-DEFECTS.md` 无合格正样本）；**弱版只判"同给"、不判"对得上"**，判词里写明该边界（强版记 `NOINFO`，需 `field-write-registry.tsv`）。

## ② 边界条款
- **只改这些件**：`build/MilBridge/tools/sjc-field-id-check.sh`（新）／`build/MilBridge/tools/silent-threshold-ban-check.sh`（新）／`build/close-wave.sh`（白名单 **+2 行**，件路径身份，**不用 glob**）／`verify-all.sh`（**+2 步** ＋ 四处声明：首行 `DECL`、头注释口径句、`STEP-NAMES`、第 `[42]` 步 `--expect` **234→236**）／`docs/WAVE<NN>-PREREGISTRATION.md`（新建或追加，机读行 `PREREG-NO-REGRESSION-DECISION: <非空非否定>`）／`build/MilBridge/HANDOFF-NEXT.md`（**只加一行** `cell=#1` 追写，照 `§12` 第 28 条）。
- **黑名单**：`src/**`、`build/*.Linux/**`、`build/MilBridge/tests/**`、`samples/**`、`docs/ROUTES.md`（本轮不动）。
- **一次只一个写者**；写前 `cp -p` 备份到 `~/t204-captain/bak/`；`temp + rename`；进程只按 PID；显示位只用空闲 `:23x`；禁 `sleep` 轮询。
- **不要跑** `static-jaws-check.sh` 全表（除非你新增了牙并需它验证——那也只跑一次）；**不要跑**整趟 `verify-all`（会构建 ⇒ `provider` 位位移）。
- 最高 3 种方案；失败如实上报停止。

## ③ 验收标准（可计算）
- ① 两牙 `--selftest`：正极绿、反极**真红点名**（把违规样本喂进去 ⇒ rc=1；干净 ⇒ rc=0）。
- ② `grep -c '^run_step "' verify-all.sh` ＝ **64**（＝首行 `DECL` 声明的数）；`FP_MANIFEST_TEETH` 现跑 `files_n==234+2==236`。
- ③ `bash build/MilBridge/tools/defect-registry-check.sh` rc=0（`DEFREG=PASS`）。
- ④ **不追写** `HANDOFF-NEXT.md` 的 `cell=#1`（本轮多写者，同代收口由队长统一做，避免相互顶开）；但须在报告里给出「本趟改了覆盖面内件 N 件 ＋ 覆盖面件数 234→236 ＋ 步数 62→64」三格读数。
- ⑤ 主链产物逐字节不变（`src/WpfGfx.Linux.Native/bin/libwpfwin32.so` 现取 sha16 = 作业前值）—— 本任务**不碰** `.so`。

## ④ 失败报告格式
已尝试方案／实际输出**原文**／怀疑／停止。

## ⑤ 完成报告格式
- 验收项 → 证据映射（逐条，**可复跑单行命令原文** ＋ 原始输出）；
- 件级前后对账（每件 `cp` 备份路径 ＋ 前后 sha16 ＋ `git diff --numstat`）；
- 自包含结论 ＋ 主动披露（规格与事实不符、待裁决）。

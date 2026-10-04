# 任务 T-W2 · `TASK-0758`：`pkg-src-retiredpath-check.sh` 扩射程目录 ＋ `TASK-0760①` 硬链接择案

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。

**主件（`TASK-0758`）**：侦察载体 `build/MilBridge/P1-tail2-unclosed-recon.md` 现取表明 `TASK-0758` 的**原前提已过期**（该牙 `tree` 面**已含 `*.cs`**、死根 `*.cs` 现取 **0 件**），**真洞改判为「射程目录未覆盖」** —— 沙箱两臂证：针在 `samples/` ⇒ `PASS`（漏）、针在 `build/` ⇒ `FAIL` 点名。⇒ 落地：把该牙的 `tree` 面扫描域**扩到 `samples/**` 与 `build/**` 的一级（及必要子层）目录**，并**先现取**扩后候选命中（避免大面积假红）。**要求**：扩域后**逐条给「真违规 / 合理残留」判定**；若扩域引出成片假阳 ⇒ 具名 `NOINFO` ＋ 只保留 `build/**`（或按现取择最小安全域）。

**次件（`TASK-0760①`）**：`arm-logs` 硬链接两案（甲＝删输出侧孪生／乙＝`repo-alias-allow.tsv` 声明）。现取 `nlink`：`tline`/`textlineproto`=1、三 tab=2；`tsv` 上限 6417、现读孪生 0。⇒ **择一并写清代价**（若现状已满足 `ALIAS=PASS` 则判「已闭」并注明）。

## ② 边界条款
- **只改**：`build/MilBridge/tools/pkg-src-retiredpath-check.sh`（射程域 ＋ 判据）／其 `--selftest` 夹具／`build/close-wave.sh`（若覆盖面 `fp_inputs()` 需 +1 件）／`verify-all.sh`（若步数/`--expect` 随之动）／`build/MilBridge/HANDOFF-NEXT.md`（`cell=#1`/`#2`/`#5` 同趟追写）／`build/MilBridge/repo-alias-allow.tsv`（若择乙）。**先现取**再定改动面。
- **黑名单**：`src/**`、`build/*.Linux/**`、`samples/**` 的产品件只读、`docs/ROUTES.md`。
- 一次只一个写者；写前 `cp -p` 备份 `~/t204-captain/bak/`；`temp + rename`；**注意模式守恒**（工作树 `stat -c %a` 写前写后相同，别被 umask 改）；进程只按 PID；禁 `sleep` 轮询。
- **不要跑**整趟 `verify-all`；`static-jaws-check.sh` 只在改了 `verify-all` 步表/新增牙时跑一次。

## ③ 验收标准（可计算）
- ① 改后 `pkg-src-retiredpath-check.sh` 现跑：**扩域前**沙箱两臂（针在 `samples/` 必红）**成对读数**；干净树 ⇒ 绿。
- ② 若动了覆盖面/步数：`grep -c '^run_step "' verify-all.sh` == 首行 `DECL` 数；`FP_MANIFEST_TEETH files_n == --expect`；`DEFREG` rc=0。
- ③ `HANDOFF_MV=PASS`（rc=0，三条 `cell=` 行同趟追写）。
- ④ `REPORTID` rc=0；`shell-quote-trap-check.sh` rc=0；模式守恒（逐件 `stat -c %a` 前后相同）。
- ⑤ 主链 `.so` 不变。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有（已尝试／原文／怀疑／停止；验收映射 ＋ 件级前后对账 ＋ 自包含结论 ＋ 主动披露）。

# 任务 T-A4 · 实现 `FsQuerySubtrackDetails` 诚实拒绝导出（`TASK-0302` 增量 · native）

## ① 任务目标
你是本项目的**实现**子代理（写者）。照侦察/判据载体 `build/MilBridge/P1-tail2-fsqsub-recon.md`（`T-A3`，225 行）落地**本增量的上限：诚实拒绝**——
在 native `src/WpfGfx.Linux.Native/src/win32_pts.c` **新增导出 `FsQuerySubtrackDetails`**，形态**只有三条**：
1. **导出符号**（使 CLR 不再抛 `EntryPointNotFoundException`；`ENFE` 对该名归零）；
2. **入参按对象身份认领**（`pSubTrack` 若来自本侧自有子轨对象 ⇒ 认领；否则**拒绝**）——**不许伪造**；
3. **出参一字不写**（`FSSUBTRACKDETAILS{fsupdinf;nms;fsrc;cParas}` 全部**不动**）＋ **失败必留痕**（具名台账）＋ **永不返 0**。

**已知边界（A3 现取，勿违）**：`cParas`／`nms` 仍**无源** ⇒ 本入口 **`rc=0` 永远不可给**（返非 0 ＋ 留痕）；`pfspara` 的填充**仅在 `wpf_pts_drive_probe_enabled()` 内**（缺省关）⇒ 缺省路径收到 `pfspara=0`，此时**按拒绝处理**（不得当年纪空白放行）。

## ② 边界条款
- **只改**：`src/WpfGfx.Linux.Native/src/win32_pts.c`／`src/WpfGfx.Linux.Native/bin/exports.txt`／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`／`src/WpfGfx.Linux.Native/bin/libwpfwin32.so`（**重建产物**）／你新建的**载体** `build/MilBridge/P1-tail2-fsqsub-impl-report.md`。
- **黑名单**：`build/close-wave.sh`／`verify-all.sh`／`build/MilBridge/tools/**`／`docs/**`／`samples/**`／`src/WpfGfx.Linux.Native/build-shim.sh` 与生成器（**只读**）。**不动** `PtsCache.Linux.cs`。
- **铁律 P8**：若某件由生成器产出 ⇒ **改生成器、不改生成件**；本任务只增进 `win32_pts.c`（手写源）＋ 其登记面。
- 重活（构建）走槽：`bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`；进程只按 PID；禁 `sleep` 轮询；写前 `cp -p` 备份；`temp+rename`；模式守恒（`stat -c %a` 前后同）。
- **不要跑**整趟 `verify-all`；`static-jaws-check.sh` 只在改了步表/新增牙时跑（本任务不加牙 ⇒ 不跑）。
- 最多 3 种方案；失败如实报停止。

## ③ 验收标准（可计算）
- ① `.so` 重建成功：`nm -D --defined-only … | grep -c '^[0-9a-f]* T FsQuerySubtrackDetails'` ＝ **1**；`nm -D --defined-only` 行数 **==** `bin/exports.txt` 行数；`exports.txt` **逐名**仅 **+1**（`FsQuerySubtrackDetails`，**无导出消失**）。
- ② 该名 **`ENFE` 归零**（用仓内 `--replay`／腿器形态或诊断给出成对：改前 `entry point named 'FsQuerySubtrackDetails'` N 行 → 改后 **0**）。
- ③ **拒绝语义**：`pfspara=0` ⇒ 该入口返**非 0** ＋ 具名留痕（给出机读行原文）；**无任何出参被写**（有 `_Static_assert`／字节读回证据）。
- ④ `pts-gap-decl.txt` 同趟更新（`so16=` ＋ `exports=` ＋ 相关计数一致）；`DEFREG` rc=0；`REPORTID` rc=0。
- ⑤ **主链其余不变**：`win32_x11.c` sha16 不变；`PtsCache.Linux.cs` sha16 不变；症状门（`alive`／`app_rc`／`magenta`）与改前同。

## ④ 失败报告格式
已尝试方案／实际输出**原文**／怀疑／停止。

## ⑤ 完成报告格式
验收项 → 证据映射（**可复跑单行命令原文** ＋ 原始输出）；件级前后对账（备份路径 ＋ 前后 sha16 ＋ `git diff --numstat`）；自包含结论 ＋ 主动披露（待裁决）。

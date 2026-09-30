# 任务 T-A9 · 实现「缺省路径三级链驱动」（甲路）—— `TASK-0302` 增量

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。照设计载体 `build/MilBridge/P1-tail2-default-chain-recon.md`（`T-A8`）的**设计草案 `S1–S5`** 与**判据草案 `D1–D7`** 落地甲路：让**缺省路径**（非显式 `WPF_PTS_DRIVE_PROBE`）也能驱动三级链，使 `FSPARADESCRIPTION.pfspara`／`pfsparaclient` 可得。

**队长裁定（本件授权，逐字）**：**撤销「裁定三十六(b)」的"运行期闸默认关"** —— 其原由（防帧面副作用／保 `N1`/`N3` 可比）已因 `PRECOND-FRAME-DETERMINISM` 未满足而**失效**；**射程**：仅就"缺省路径驱动三级链"这一目的；**粒度**：以 `D1–D7` 逐条可证伪为准。

**已知边界（勿违）**：两道闸在 `win32_pts.c`（`~:1769`／`~:3626`，现取）；**只许改手写源 `win32_pts.c`** ＋ 其登记面；**只导出/只驱动**；失败必留痕、永不假成功。

## ② 边界条款
- **只改**：`src/WpfGfx.Linux.Native/src/win32_pts.c`／`src/WpfGfx.Linux.Native/bin/exports.txt`（若导出面动）／`src/WpfGfx.Linux.Native/tools/pts-gap-decl.txt`／新建载体 `build/MilBridge/P1-tail2-default-chain-impl-report.md`。
- **黑名单**：`build/*.Linux/**`（**生成件**；`PtsCache.Linux.cs` 等一律**不改**，若必须动 ⇒ 只改生成器 `reapply-patches.py` 的 `PTSCACHE_EDITS`，遵 `P8`）／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`／`docs/**`。
- **副本先行**：主链行为若可能变化 ⇒ 先在**副本**上取证（两极化）；给出「主链 `.so` 逐字节不变／症状门逐格不变」的成对证据（或按 `S1–S5` 的既定形态）。
- 重活（构建 `.so`）走槽 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`；进程只按 PID；禁 `sleep` 轮询；写前 `cp -p` 备份；`temp+rename`；模式守恒。
- **不要跑**整趟 `verify-all`。最多 3 种方案；失败即如实报停止（**允许**判「本波做不到」并具名前置）。

## ③ 验收标准（可计算）
- ① 按 `D1–D7` 逐条给现取读数；**每条带反极性**（该红必红）。
- ② 缺省路径下：`pfspara`／`pfsparaclient` **可得**（给出机读行原文 ＋ 值）；或如实 `NOINFO` ＋ 具名前置。
- ③ 导出面：`nm -D --defined-only` 行数 **==** `bin/exports.txt` 行数（若动则逐名点名、无消失）；`pts-gap-decl.txt` 同趟一致。
- ④ 症状门（`alive`／`app_rc`／`magenta`／`colors`／`ink`／`ns`）与改前**成对**读数（变与不变都如实报）。
- ⑤ `DEFREG` rc=0；`REPORTID` rc=0。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有（已尝试／原文／怀疑／停止；验收映射 ＋ 件级前后对账 ＋ 自包含结论 ＋ 主动披露）。

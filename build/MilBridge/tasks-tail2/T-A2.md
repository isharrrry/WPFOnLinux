# 任务 T-A2 · 实现 E3 真重放夹具（`TASK-0009`）—— uinput 注入腿

## ① 任务目标
你是本项目的**实现**子代理（写者）。照侦察载体 `build/MilBridge/P1-tail2-e3-recon.md` 落地 `TASK-0009`：用 **`evdev/uinput`** 注入**真实服务器时间戳**的鼠标 press，驱动 E3 去重闸（`src/WpfGfx.Linux.Native/src/win32_x11.c` 现取 `:1357-1394`／push `:1395`；命中条件 `live_button==b ∧ dt>=0 ∧ dt<=bound`）**被真正行使**，并留下 `cand>0 ∧ drop>=0` 的机读读数。

**侦察已证**（不必重查）：uinput 通道在私有 Xorg（vmware＋libinput 热插拔）上可解——设备被认领、press 以服务器自产事件到达（`xev` 见 `synthetic NO` ＋ 递增 `time`）；`XI2` **无注入原语**（只能观测）。**未决（本任务要回答）**：使 `cand>0` 的「**第二条同 button press**」触发点——四条负向读数均未复现 ⇒ 需在夹具里**受控地**造出「两次同 button press，`dt∈[0,bound]`」。

## ② 边界条款
- **只改**：`build/MilBridge/tests/` **下新建目录**（建议 `build/MilBridge/tests/E3ReplayProbe/**`）＋ 一张**判据件**放在同目录内。**不要**改 `verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（本轮另一写者持有）／`src/**`／`docs/**`／`build/MilBridge/HANDOFF-NEXT.md`。
- **不许**把新夹具加进 `fp_inputs()` 覆盖面（避免与另一写者顶开）；本任务**不改**指纹。
- `sudo` 密码 `links`；`/dev/uinput` 用后**复原权限**（如 `chmod 600`）；Xvfb/Xorg 用后**按 PID** 关闭（禁 `pkill`／`pgrep -f`）；显示位只用空闲 `:23x`；禁 `sleep` 轮询（用有界等待）。
- **不要**改产品 `.so`；不要跑整趟 `verify-all`。
- 写前 `cp -p` 备份；`temp+rename`；最多 3 种方案；失败即如实上报停止（**允许**判「本波做不到」并具名前置）。

## ③ 验收标准（可计算）
- ① 夹具脚本落仓（路径 ＋ sha16）；能给「入口命令 ＋ 出口读数」。
- ② **核心读数**：一条 `[E3-*]`（或等价）机读行，**同给** `cand`／`drop`／`dt`／`live_button`／`b`；且**样本非空**（`cand>0` 或明确记录"未造出"及原因）。
- ③ **反极性**：去重闸失效（如把 `bound` 调大／把去重条件拆掉）⇒ 读数**必须翻转**（`cand` 变化或行为改变）；给出成对读数。
- ④ 主链 `.so`／`win32_x11.c` 逐字节不变（`sha256sum` 作业前后相同）。
- ⑤ 若「造不出 `cand>0`」⇒ 具名 `PRECOND-*` ＋ 四条负向读数原样 ＋ 不得写绿。

## ④ 失败报告格式
已尝试方案／实际输出**原文**／怀疑／停止。

## ⑤ 完成报告格式
- 验收项 → 证据映射（逐条，**可复跑单行命令原文** ＋ 原始输出）；
- 自包含结论 ＋ 主动披露（待裁决）。

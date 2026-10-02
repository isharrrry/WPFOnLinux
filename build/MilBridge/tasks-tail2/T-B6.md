# 任务 T-B6 · `WIN-INTEROP.md` §7.5 **L3**：导出脚本（Windows 端替换 runtime）—— 实现

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。照 `/home/links-dev/netTest/GitProj/WIN-INTEROP.md` **§7.5 的 L3**（＝ L2 ＋ 导出脚本）与 **§7.4**：**让同一份产物能在 Windows 直接跑（跑的是官方件）** —— 成本：**shim 1 行短路 ＋ 1 个脚本 ＋ asmmeta 审计**。

必做（逐条现取）：
1. **shim 1 行短路**：在 Windows 上运行时**短路到官方件**（给出**件:行** ＋ 前后行为成对；`P8`：生成件走生成器）。
2. **导出脚本**：把「Windows 端替换 runtime」做成**一条命令**（装／卸可回滚；脚本内**每条命令**给现取输出）。
3. **asmmeta 审计**：用 `dotnet /tmp/wincompat/asmmeta/bin/Release/net10.0/asmmeta.dll pubadd …`（见 §7.8）审计**扩展 API 面**，逐件给结论。
4. **必须如实划界**：§7.7 已记 **`NOINFO`：本机无 `Microsoft.WindowsDesktop.App.Runtime.win-x64`、无 wine ⇒ "真 Windows 端到端"本机取不到** ⇒ 本任务**不许**声称"在 Windows 上跑通"，只能给**可复算的脚本 ＋ 本机可得的静态/半程证据**。

**硬边界**：永不假成功/零假值；**不许**改 `upstream/**`；`P8`；副本先行；写前 `cp -p`；两极化。

## ② 边界条款
- 只改：`build/**`（脚本／props／shim 短路）／`docs/**`／`src/**`（如必须，`P8`）／新建载体 `build/MilBridge/P1-wininteropL3-impl-report.md`。
- 黑名单：`upstream/**`／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`。
- 重活走槽；进程只按 PID；禁 sleep 轮询；temp+rename；模式守恒。不要跑整趟 verify-all。

## ③ 验收标准（可计算）
- ① shim 短路：件:行 ＋ 成对读数；② 导出脚本：`install`／`uninstall` 可回滚 ＋ 逐命令输出；③ asmmeta 审计逐件结论；④ **L2 的库包绑定与 L1 e2e 不得回退**（`verify 25/25` ＋ rc=0）；⑤ `DEFREG`/`REPORTID` rc=0；⑥ 具名 `NOINFO`（真 Windows 端到端本机不可得）。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有。

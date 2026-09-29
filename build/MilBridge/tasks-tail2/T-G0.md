# 任务 T-G0 · `TASK-0307`（`TASK-0302` 下一增量）—— 只读侦察 ＋ 判据预登记

## ① 任务目标
你是本项目（`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`）的**只读侦察**子代理。为 roadmap `docs/ROUTES.md §13` 的 `TASK-0307`（`FsQuerySubtrackParaList`（`S-2b` 族）＋ LS 溯源桥）做侦察＋判据预登记，回答：

1. `PRECOND-PARADESC-SOURCE-MISSING（scope=subtrack-path）` 与 `PRECOND-LS-PROVENANCE-BRIDGE` 的现取状态（在前置总册 `build/MilBridge/P1-ptsname-result.md` 与 `build/MilBridge/P1-ls-provenance-contract.md` 里现取）。
2. `FsQuerySubtrackParaList` 在 native（`src/WpfGfx.Linux.Native/src/win32_pts.c`）与托管（`build/PresentationFramework.Linux/PtsCache.Linux.cs`／`PtsHelper.cs:633`）两侧的现取落点；**钥匙 vs 其后**（照裁定二十六 (a) 体例）。
3. `LM-1` 判 `7/8 PARTIAL` 的第 4 条「宿主侧消费」现取缺口（`PtsHelper.cs:177 rcPara.dv = dvrUsed − dvrTopSpace` 链）。
4. **托管侧协作者**：本任务要动 `build/PresentationFramework.Linux/**` 与 `src/**`，给出「若不改产品，本波能做到哪一步」的具名前置；并判「本波该不该做」（允许判不做）。

## ② 边界条款
- **只读**：除载体外不许改任何仓内文件；不跑重活；不跑整趟 `verify-all`；不跑 `static-jaws-check.sh`。
- 进程只按 PID；显示位只用空闲 `:23x`；禁 `sleep` 轮询；大文件只用 `wc`／`head`／`tail`／`grep`。
- 载体（**唯一可写文件**）：`build/MilBridge/P1-tail2-t0307-recon.md`（不用 `report` 字样）。

## ③ 验收标准（可计算）
载体必须含：① 两条 `PRECOND-*` 现取状态（件:行 ＋ 原文）；② 两侧落点表 ＋ 钥匙/其后判定；③ 第 4 条缺口现取；④ 判据预登记草案（≥3 条可证伪 ＋ 反极性）；⑤ 结论：本波做/不做 ＋ 若做的**最小可行第一步** ＋ 具名前置。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有 recon 体例（已尝试／原文／怀疑／停止；验收映射 ＋ 自包含结论 ＋ 主动披露）。

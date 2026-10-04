# 任务 T-A3 · `TASK-0302` 增量：钥匙 `FsQuerySubtrackDetails` —— 只读侦察 ＋ 判据先写

## ① 任务目标
你是本项目（`/home/links-dev/netTest/GitProj/WPFOnLinux`，分支 `feat-Linux`）的**只读侦察/判据**子代理。承接 `build/MilBridge/P1-tail2-t0307-recon.md` 的结论：`FsQuerySubtrackParaList` 是「其后」、**钥匙 ＝ `FsQuerySubtrackDetails`**（`ContainerParaClient.cs:47/271`，`nm -D` 命中 0，native 仅 `:3803` 注释）。本任务**只写判据与可行性**（不实现），回答：

1. `FsQuerySubtrackDetails` 的**签名/语义契约**（`build/PresentationFramework.Linux/Pts.cs` 声明 ＋ `PtsHost`/`ContainerParaClient` 调用点）现取逐字（行号仅本次有效）。
2. **钥匙 vs 其后**链：它被谁调、门控谁（`cParas` 等），与 `FsQuerySubtrackParaList` 的先后。
3. **入参可得性**：`pSubTrack`（子轨对象）现取来源 —— `FSPARADESCRIPTION.pfspara`（`win32_pts.c` 现取填充体是否已写它）、`pfspara` 是否已成**本侧可认领真对象**（`build/MilBridge/P1-pfspara-report.md`）。
4. **最小可行子集（M1）**：若做，只实现"诚实无进展"（永不假成功、失败必留痕）是否可行；其**必备形态**（哪几个出参、哪几个计数、`kstop` 等）。
5. **阻塞前置**：逐条具名（如 `PRECOND-*`），并判「本增量本波能否做」。

## ② 边界条款
- **只读**：除载体外不许改任何仓内文件；**不**改 `src/**`；不构建；不跑整腿；不跑整趟 `verify-all`；不跑 `static-jaws-check.sh`。
- 进程只按 PID；显示位只用空闲 `:23x`；禁 `sleep` 轮询；大文件只用 `wc`／`head`／`tail`／`grep`。
- 载体（**唯一可写文件**）：`build/MilBridge/P1-tail2-fsqsub-recon.md`（不用 `report` 字样）。

## ③ 验收标准（可计算）
载体必须含：① 契约与调用点现取（件:行 ＋ 原文）；② 钥匙/其后链；③ 入参可得性判定（含 `pfspara` 现取状态）；④ M1 最小可行子集的**判据草案**（≥3 条可证伪 ＋ 反极性；含"零假值/永不假成功/失败必留痕"）；⑤ 阻塞前置清单 ＋ 「本增量本波做/不做」结论 ＋ 若做的最小落地步骤。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有 recon 体例（已尝试／原文／怀疑／停止；验收映射 ＋ 自包含结论 ＋ 主动披露）。

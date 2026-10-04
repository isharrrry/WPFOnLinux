# 任务 T-A8 · 缺省路径三级链可驱动性 —— 只读设计侦察 ＋ 判据先写

## ① 任务目标
你是本项目的**只读设计侦察**子代理。`T-A6` 现取结论：现件代真腿**唯一**被撞的 PTS 缺口 ＝ `FsQueryTrackParaList`（`reason=paraclient-table-not-native`），其出参需**托管句柄表** ⇒ 判「native 写域内无有源可做项」。本任务查**另一面**：

> **缺省路径（非 `wpf_pts_drive_probe_enabled()`）能否驱动三级链**（`pfnGetMainTextSegment`→`pfnGetNextPara`/`pfnGetFirstPara`→`pfnCreateParaclient`），从而使 `FSPARADESCRIPTION.pfspara`／`pfsparaclient` 在**缺省路径**可得？

要回答：
1. `A3` 的 `PRECOND-PFSPARA-ONLY-IN-PROBE` 现取：填充整块在探针门（`win32_pts.c` 现取行）内的**逐字条件**；缺省路径下 `pfspara` 恒 0 的**现取证据**。
2. **缺省路径里谁在跑**：应用正常布局时（`FlowDocumentFormatter.Format` ← `PtsPage.CreateBottomlessPage` 等）会调 native 哪些 `Fs*`／`Lo*`；**这些调用点是否可能驱动** `fscbk` 回调表（现取调用链）。
3. **两条候选路**：(甲) native 在缺省路径**自己发起**入口（如 `FsCreatePageBottomless` 内补驱动）；(乙) 托管侧在**不缺省关**的前提下把 `pfspara`/`pfsparaclient` 备好。逐条给**可及性（谁改）∧ 可行性（怎么改）∧ 代价**。
4. 若两路都不可行 ⇒ 具名 `PRECOND-*` ＋ 判「合法终点」；若可行 ⇒ **设计草案 ＋ 判据草案**（≥3 条可证伪 ＋ 反极性；含"零假值／永不假成功／失败必留痕／症状门不变"）。

## ② 边界条款
- **只读**：除载体外不许改任何仓内文件；不构建；不改 `src/**`／`build/**`；不跑整趟 `verify-all`；不跑 `static-jaws-check.sh`。
- 进程只按 PID；显示位只用空闲 `:23x`；禁 `sleep` 轮询；大文件只用 `wc`／`head`／`tail`／`grep`。
- 载体（**唯一可写文件**）：`build/MilBridge/P1-tail2-default-chain-recon.md`（不用 `report` 字样）。

## ③ 验收标准（可计算）
载体须含：① `PRECOND-PFSPARA-ONLY-IN-PROBE` 现取逐字条件；② 缺省路径实际驱动链（件:行）；③ 甲/乙两路的可及∧可行∧代价逐条；④ 结论（可行 ⇒ 设计草案＋判据草案；不可行 ⇒ 具名前置清单）；⑤ 若涉及 `PtsCache.Linux.cs` 等**生成件** ⇒ 必须写明"改生成器、不改生成件（`P8`）"的落点。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有 recon 体例。

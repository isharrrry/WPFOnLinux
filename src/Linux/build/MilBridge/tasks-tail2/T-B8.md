# 任务 T-B8 · hc demo 流文档页三缺陷（单页视图打不开／tab1 遮挡／tab3 空白）—— 定位＋修

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。用户在 hc demo（`bash ~/run-hc.sh`）**「流文档」页**（左侧导航滚到底的 `FlowDocument` 项；日志以 `[FORMATLINE-LINE]` 计数作为"确已进页"标记）报**三缺陷**：
1. **「单页视图」打不开**（该 tab 点了没内容/不切换）；
2. **第一个 tab 仍有遮挡**（内容互相盖）；
3. **第三个 tab 区域空白**（空区域）。

请 **①逐条复现 → ②定位到第一处断点（件:行＋原文）→ ③修 → ④帧面可证**：
- 复现：私有 `:23x` ± WM，走重活槽；给出**点哪一项／哪个 tab** 与**日志路径**；**逐 tab** 给截图 `colors`／内容区像素（**成对**）。
- 定位：三条各给第一处断点；能取几何的给**几何证据**（行盒/`Offset`/`v`/裁剪域）。
- 修：`P8`（生成件走生成器）；**不许改仓外 hc 工程**；不许改 `upstream/**`。
- 判据：每条**帧面可证**（帧 `sha16` 变 ＋ 内容区像素/色数改善）＋ **反极性**（撤修 ⇒ 回原状）。

**硬边界**：永不假成功/零假值；诚实拒绝优于假成功；**不许**伪造几何；副本先行；写前 `cp -p`；`git status` 不得留未提旁生件；**app-local 必须与仓内权威件逐件一致**（`sync-applocal.sh` 只覆盖 5 件 ⇒ 主题件等需自行对齐，**别再用 10.0.0.0 残留件**）。

## ② 边界条款
- 只改：`src/WpfGfx.Linux.Native/**`／`build/PresentationFramework.Linux/**`（生成器与生成件，`P8`）／`build/PresentationCore.Linux/**`（同）／`build/shims/**`／复述位现值位／新建载体 `build/MilBridge/P1-hcflowdoc-impl-report.md`。
- 黑名单：`upstream/**`／仓外 hc 工程／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`。
- 重活走槽；进程只按 PID；显示位只用空闲 `:23x`（**用完按 PID 收净**）；禁 sleep 轮询；temp+rename；模式守恒。不要跑整趟 verify-all。最多 3 方案；失败如实报停止（允许判合法终点）。

## ③ 验收标准（可计算）
- ① 三条各：复现步骤 ＋ 第一处断点（件:行）＋ 归因；② 每条**帧面成对**（帧 `sha16` ＋ 内容区色数/像素）＋ **反极性**；③ `nm==exports`；`PTSGAP=PASS`；`DEFREG`/`REPORTID` rc=0；④ 症状门（`alive`/`app_rc`/`[HC-UNHANDLED]`）成对。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有。

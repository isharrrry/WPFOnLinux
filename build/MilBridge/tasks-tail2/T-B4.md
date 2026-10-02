# 任务 T-B4 · hc 缺陷①续：流文档视图**可见**文字重叠 —— 实现

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。承 `T-B3`（`build/MilBridge/P1-hcbugs-impl-report.md`）：缺陷①**几何已真**（`rectDV 0→33528／25146`、同轨逐段 `v_rel=[0,33528,58674]`、`wpf_pts_sub_v_extent` 源＝`pfnFormatLine` 真返回值行台账），**但帧面 `AE=0` ⇒ 用户可见重叠未改善**（具名 `NOINFO`）。请**继续**把「**可见**重叠」修到**帧面可证**：

1. **现取**为何几何已真而帧面不变（给**逐跳**证据：native 出参 → 托管 `PtsHelper.Linux.cs:208 dvrPara += dvrUsed` → `TextParaClient` 行盒 → 渲染；指出哪一跳没消费该几何）。
2. 按该断点修（`P8`：生成件走 `build/PresentationFramework.Linux/reapply-patches.py`），使**同 track 各段的行盒 `v` 真正错开**。
3. **判据**：**可见重叠**改善**必须帧面可证**（帧 `sha16` 变 ＋ 给出「重叠量」前后对照：如同一 `x` 列上两行文本带 `y` 区间不再相交，或像素级重叠计数下降）；**不许**只报几何。

**硬边界**：永不假成功/零假值；诚实拒绝优于假成功；**不许**伪造几何/度量；副本先行；写前 `cp -p`；两极化。

## ② 边界条款
- 只改：`src/WpfGfx.Linux.Native/src/win32_pts.c`／`bin/exports.txt`／`tools/pts-gap-decl.txt`／生成器 `build/PresentationFramework.Linux/reapply-patches.py` 及其重产件／复述位现值位／新建载体 `build/MilBridge/P1-hcbugs2-impl-report.md`。
- 黑名单：`build/MilBridge/tools/**`／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`／hc demo 仓外工程。
- 重活走槽；进程只按 PID；显示位只用空闲 `:23x`；禁 sleep 轮询；temp+rename；模式守恒。不要跑整趟 verify-all。最多 3 方案；失败如实报停止（允许判合法终点）。

## ③ 验收标准（可计算）
- ① 逐跳证据（哪一跳没消费几何）＋件:行；② **帧面成对**（帧 `sha16` 前后 ＋ `AE`）＋**重叠量前后对照**（数值）；③ 反极性（撤该修 ⇒ 回原帧）；④ `nm==exports`；`PTSGAP=PASS`；`DEFREG`/`REPORTID` rc=0；⑤ `PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3` 不得回退；⑥ 症状门成对。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有。

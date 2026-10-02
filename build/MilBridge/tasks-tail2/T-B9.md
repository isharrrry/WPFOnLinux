# 任务 T-B9 · hc 流文档页 tab2/tab3 空白 —— 从「句柄生命周期过度拒发」角度重攻

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。承 `T-B8`（`build/MilBridge/P1-hcflowdoc-impl-report.md`）**已复现并定位**：流文档页 `tab2 单页视图`／`tab3 查看器` **空白**（`colors=551/562`、具名色 0），第一处断点 `win32_pts.c:9243`（**陈旧 paraclient 具名拒发** ⇒ `[FS_PAGE_GAP] rc=-10000×205` ⇒ `PtsException('-10000')×206`、页格式中止）＋ 第二见证 `[QPD] vis_built=0 640/641`。

**本轮假设（队长给的线索，须先证伪或证实）**：`T-B3` 给句柄发放加的「**本窗新造 ∧ 在册 live**」判据（`fsp_pl_epoch`／`page_destroy_n`）**可能对"合法的新页/新 paraclient"也拒发** ⇒ `tab2/tab3` 需要**新页**时被误拒。请：
1. **先证实/证伪该假设**：给 `[FS_PAGE_GAP]` 那 205 次拒发的**逐次理由**（哪条判据拒的）＋ 拒发对象是否为「**本窗合法新建**」；**给件:行与现取读数**。
2. 若证实 ⇒ **收严改为精确**：允许「本窗新造且在册 live」，只拒「跨窗/已销毁」；**不许**放宽到"一律放行"（须保留 T-B3 的反极性：跨窗陈旧句柄仍必红）。
3. 若证伪 ⇒ 沿 `[QPD] vis_built=0`／`FS_PAGE_GAP` 继续找**真断点**，给第三方案。
4. **判据**：`tab2`／`tab3` **帧面可证**（内容区色数显著回升、具名色出现、帧 `sha16` 变）＋ **反极性**（撤修 ⇒ 回 `551/562`）＋ **T-B3 的反极性必须仍成立**（放回跨窗陈旧句柄 ⇒ 必红）。

**硬边界**：永不假成功/零假值；**不许**伪造几何；`P8`；副本先行；写前 `cp -p`；app-local 须与仓内权威件逐件一致。

## ② 边界条款
- 只改：`src/WpfGfx.Linux.Native/src/win32_pts.c`／`bin/exports.txt`／`tools/pts-gap-decl.txt`／生成器 `build/PresentationFramework.Linux/reapply-patches.py` 及其重产件／复述位现值位／新建载体 `build/MilBridge/P1-hcflowdoc2-impl-report.md`。
- 黑名单：`upstream/**`／仓外 hc 工程／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`。
- 重活走槽；进程只按 PID；显示位只用空闲 `:23x`（**用完按 PID 收净**）；禁 sleep 轮询；temp+rename；模式守恒。不要跑整趟 verify-all。最多 3 方案。

## ③ 验收标准（可计算）
- ① 205 次拒发的**逐理由现取**（件:行）；② tab2／tab3 **成对读数**（`colors`／具名色／帧 `sha16`）＋ 反极性；③ **T-B3 反极性仍成立**（跨窗陈旧句柄 ⇒ 必红）；④ `nm==exports`；`PTSGAP=PASS`；`PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3` 不得回退；⑤ `DEFREG`/`REPORTID` rc=0；⑥ 症状门成对。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有。

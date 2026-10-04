# 任务 T-B3 · hc demo 两缺陷修（真 v 几何 ＋ 跨窗句柄拒发）—— 实现

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。照 `build/MilBridge/P1-hcbugs-recon.md`（`T-B1`）的**唯一选靶（甲·native）**修两缺陷：

1. **缺陷①（流文档视图文字重叠）**：第一处断点 `win32_pts.c:126-130` —— `WPF_PTS_FSP_PL_DVR` 0 ⇒ 段描述符 `dvr_used`／`dvr_top_space` **恒 0** ⇒ `PtsHelper.Linux.cs:208` 的 `dvrPara += dvrUsed` 退化为 0 ⇒ **同 track 各段共 `v`**。请补**真 `v` 几何**（在 `FsQueryTrackParaList` 填充支上）；**取不到真值时具名降级**（不许拿 0 冒充）。
2. **缺陷②（第三 tab 崩溃 `rc=134`）**：第一处断点 `win32_pts.c:9145` —— `rg[i].pfsparaclient = dp->fsp_pl_cur` **交跨窗陈旧句柄** ⇒ `PtsHelper.Linux.cs:186 HandleToObject` ⇒ `PtsContext.cs:248 Invariant.Assert("Handle has been already released.")` ⇒ `Environment.FailFast`。请把句柄发放收严为 **「本窗新造 ∧ 在册 live」**，否则照 `win32_pts.c:9122` 的**具名拒发**形态处理。

**硬边界**：永不假成功/零假值；诚实拒绝优于假成功；`P8`（`TextParaClient.Linux.cs`／`PtsHelper.Linux.cs` 是**生成件** ⇒ 须走 `build/PresentationFramework.Linux/reapply-patches.py`）；副本先行；写前 `cp -p`；两极化（该红必红）。

## ② 边界条款
- 只改：`src/WpfGfx.Linux.Native/src/win32_pts.c`／`bin/exports.txt`／`tools/pts-gap-decl.txt`／生成器 `build/PresentationFramework.Linux/reapply-patches.py` 及其重产件／复述位现值位／新建载体 `build/MilBridge/P1-hcbugs-impl-report.md`。
- 黑名单：`build/MilBridge/tools/**`（判据件）／`verify-all.sh`／`build/close-wave.sh`／`build/shims/**`／`upstream/**`／hc demo 仓外工程。
- 重活走槽 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`；进程只按 PID；显示位只用空闲 `:23x`；禁 sleep 轮询；temp+rename；模式守恒。不要跑整趟 verify-all。最多 3 方案；失败如实报停止（允许判合法终点）。

## ③ 验收标准（可计算）
- ① **缺陷②**：以 `T-B1` 的复现步骤跑 hc demo ⇒ **点第三个 tab 不再 `FailFast`**（`rc≠134`、日志无 `Handle has been already released`）；**反极性**：人为放回陈旧句柄 ⇒ 必复发（点名）。
- ② **缺陷①**：**几何成对**（同 track 各段的 `v` 不再相同；给逐段 `v` 现取 ＋ 重叠量前后对照）＋ 帧面成对（帧 sha16／`AE`）。
- ③ `nm==exports`；`PTSGAP=PASS`；`DEFREG`/`REPORTID` rc=0；④ `PTS_GUARD=PASS`／`PTS_COLORANCHOR=PASS hits=3` **不得回退**；⑤ 症状门（`alive`/`app_rc`/`magenta`/`colors`/`ink`/`ns`）成对。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有。

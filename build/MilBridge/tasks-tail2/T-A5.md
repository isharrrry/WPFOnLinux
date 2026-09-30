# 任务 T-A5 · `PTSGAP` 复述位随动（`SITE-DRIFT` 清零）

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。`T-A4` 让 native 多了一条**诚实拒绝导出** ⇒ `impl/ops/tool` 各 **−1**（`impl 81→80`／`ops 78→77`／`tool 90→89`）。现在 `pts-gap-count-check.sh` 报 `PTSGAP=FAIL`（`SITE-DRIFT`：**现值位**未随动）。请把**现值位**同步为 live 值，使 `PTSGAP=PASS`。

**权威 live 值（现取）**：`bash build/MilBridge/tools/pts-gap-count-check.sh` 的 `PTSGAP=` 行给出 `tool=89 dead=11 artifact=1 ops=77 impl=80 so16=a1403ea71c2bf487 exports=670`——**以你现取为准**。

## ② 边界条款
- **只改现值位**：`docs/ROUTES.md`／`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`README.md`／`build/MilBridge/HANDOFF-NEXT.md`／`src/WpfGfx.Linux.Native/src/win32_classification.c`／`docs/unimplemented.md` 等**由牙点名 `SITE-DRIFT` 的那些行**。
- **三条硬约束（裁定十一）**：① **只改数字 token**（`81→80`／`78→77`／`90→89` 及其同形）；**不许删句、不许动结构**；② **历史行不动**（牙报 `SITE-HISTORICAL-ONLY`／带旧 `so16`／dated 措辞的自引旧代行 ⇒ **一字不动**）；③ 逐件点名 ＋ 逐处 before→after 记账。
- **黑名单**：`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`（**不改牙本体**）。`src/WpfGfx.Linux.Native/src/win32_classification.c` 若因改注释动行数 ⇒ 须**重建 `.so` 并核 sha 是否变**（变了要如实报；该件是产品源）。
- 一次只一个写者；写前 `cp -p` 备份 `~/t204-captain/bak/`；`temp+rename`；模式守恒（`stat -c %a` 前后同）；进程只按 PID；禁 `sleep` 轮询。
- **不要跑**整趟 `verify-all`。

## ③ 验收标准（可计算）
- ① `bash build/MilBridge/tools/pts-gap-count-check.sh` ⇒ **`PTSGAP=PASS`**（rc=0）；**无 `SITE-DRIFT`**；`SITE-HISTORICAL-ONLY` 行的**内容一字未变**（给前后 sha16 或 `grep -c` 佐证）。
- ② 逐处 before→after 表（`件:行 | 前 | 后`）；`git diff --numstat` 的**删行数 == 0**（纯 token 替换 ⇒ 若某行是整行替换则删=1、须逐行说明）。
- ③ `bash build/MilBridge/tools/defect-registry-check.sh` rc=0；`report-id-domain-check.sh` rc=0；`shell-quote-trap-check.sh` rc=0。
- ④ 若动了 `win32_classification.c`：给出「重建前后 `.so` sha16」成对读数（不变或变，都如实报）。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有（已尝试／原文／怀疑／停止；验收映射 ＋ 件级前后对账 ＋ 自包含结论 ＋ 主动披露）。

# 任务 T-B7 · hc demo「XamlParseException ⇒ UI 未建起」定位并修 —— 实现

## ① 任务目标
你是本项目的**实现**子代理（写者；本轮唯一写者）。**现场**：`bash ~/run-hc.sh` 起得来、**能建窗**，但日志出现 **5 条 `[HC-UNHANDLED] XamlParseException`**（`StaticResourceHolder` ProvideValue / `TextBlock` 初始化 / `ToggleButton` 初始化 `Line 18 pos 56`）⇒ **UI 未完整建起**（窗口像素 **`colors=181`**；会话前同一装置是 **`colors=1275`**）。

请 **①先定位、②再修、③帧面可证**：
1. **取全栈**：`[HC-UNHANDLED]` 只印首帧 ⇒ 想办法拿到**内层异常类型/消息/完整栈**（可用的手段自己现取：如 `HC_*`/`WPF_LINUX_*` 诊断开关、`DOTNET_` 环境变量、或临时在**生成器**（`build/PresentationFramework.Linux/reapply-patches.py`）加一处**只读**打印后重产）；**不许**改仓外 hc 工程。
2. **定位**：给出**第一处断点**（件:行 ＋ 原文）与**归因**（本移植缺哪个面：主题资源字典 / `StaticResource` 解析 / 某控件模板 / `PresentationFramework.Classic`·`PresentationUI` 的哪一件）。
3. **修**：按 `P8`（生成件走生成器）；若属"本侧无源"⇒ **如实划界**并给**具名前置**，不许假成功。
4. **判据（帧面可证）**：`colors` 显著回升（目标**接近会话前 `1275`**）＋ 5 条 `[HC-UNHANDLED]` **归零或逐条具名降级**；**反极性**（撤该修 ⇒ 回 `181`／异常复现）。

**硬边界**：永不假成功/零假值；**不许**改仓外 hc 工程、**不许**改 `upstream/**`、**不许**删判据；副本先行；写前 `cp -p`；`git status` 不得留未提的旁生件。

## ② 边界条款
- 只改：`build/PresentationFramework.Linux/**`（生成器与生成件，`P8`）／`build/PresentationCore.Linux/**`（同）／`build/shims/**`／`build/DirectWrite.Linux/**`／`src/**`（如必须）／复述位现值位／新建载体 `build/MilBridge/P1-hcdemo2-impl-report.md`。
- 黑名单：`upstream/**`／仓外 hc 工程／`verify-all.sh`／`build/close-wave.sh`／`build/MilBridge/tools/**`。
- 重活走槽 `bash ~/heavy-slot.sh --min-avail 2500 --max-hold 1800 --wait 3600 -- <cmd>`；进程只按 PID；显示位只用空闲 `:23x`（**用完按 PID 收净**）；禁 sleep 轮询；temp+rename；模式守恒。不要跑整趟 verify-all。最多 3 方案；失败如实报停止（允许判合法终点）。

## ③ 验收标准（可计算）
- ① 5 条异常的**内层原文**（类型 ＋ 消息 ＋ 关键栈帧）；② 第一处断点（件:行）；③ **帧面成对**：`colors` 前/后 ＋ 窗口截图色数；④ 反极性（撤修 ⇒ 回 `181`）；⑤ 门禁不回归：`integration-wave` 失败步骤 **0**、`SSC`/`HANDOFF_MV`/`DEFREG`/`REPORTID` rc=0、`PTS_GAP=PASS`。

## ④ 失败报告格式 / ⑤ 完成报告格式
同既有。

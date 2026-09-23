# ROUTES —— 并行子路线图（**认领一条路线 = 认领一组可独立验证的判据**）

> 规范见 [`PORT-SPEC.md`](PORT-SPEC.md)。本文件只回答三件事：**现在有什么**、**还剩什么**、**怎么切给不同的人并行做而不互撞**。
> 每条路线都自带：目标 / 现状读数 / 写域 / 判据（含反极性）/ 依赖 / 需要的装置。
> 现状机器行以 `docs/CURRENT-STATE.md` 与 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 为准。

---

## §0 今天到哪了（一句话）

**MVP 已成立**：WPF 应用**从源码在 Linux 编译通过、开窗、渲染出界面、鼠标键盘可用**（含组合框下拉、列表选择、文本框输入、导航切页）。
**但**：仍在**未冻结**状态 —— 最近三个修法（WM 下点击被吞、`SetFocus` 回声崩溃、启动等待桩）已在树里，**尚未发波重冻**（见 `docs/WAVE49-PREREGISTRATION.md`）。

| 面 | 状态 |
|---|---|
| 编译 | ✅ 全部自产件 + 样本 0 error（Release 档） |
| 渲染 | ✅ 窗口内多页有内容、切页收敛、弹窗出画（`samples/WpfTextDemo` 有冻结基线） |
| 交互 | ✅ 点击/打字/下拉/列表；⚠️ **有窗口管理器**的会话此前被吞过（已修待冻） |
| 稳定性 | ⚠️ 已修两类崩溃（回声环、等待桩）；**用户仍报"还会崩溃"**（路线 R2 在查） |
| 窗口形态 | ⚠️ **用户报"直接全屏、不能拖、不能缩放"**（路线 R1 在查） |
| 判据完整性 | ⚠️ 仍有 R7 的若干洞（选显示、点击判据未接门禁、判据件覆盖面、app-local 同步链） |

---

## §1 R1 · 窗口管理（**用户当前最痛**）

- **目标**：窗口能被 WM 正常管理 —— 有装饰/标题栏、能拖、能缩、能最大化/还原；`WM_NORMAL_HINTS`/`_NET_WM_*` 语义正确。
- **现状**：用户实测"直接全屏、不能调大小、不能拖"；车道 W57A 正在取 `xprop`/`xwininfo` 读数（`WM_NORMAL_HINTS` / `_MOTIF_WM_HINTS` / `_NET_WM_STATE` / `override_redirect` 四项）并与已知正常客户端逐字段对照。
- **写域**：`src/WpfGfx.Linux.Native/src/{win32_core.c,win32_x11.c,win32_msg.c}`、`src/WpfGfx.Linux/Windowing/**`、`src/WpfGfx.Linux/Interop/MilPresentation.cs`。
- **判据（草稿，落地前按 PORT-SPEC §1 写死）**：① 有 WM 的腿：`xwininfo -root -tree` 里我们的窗口**有 WM 框架父窗**、`xprop` 无 `MWM_DECOR=0`、`_NET_WM_STATE` 无 `MAXIMIZED/FULLSCREEN`（除非应用自己要）、`Override Redirect=False`；② **能拖**：`xdotool` 拖标题栏 ⇒ 窗口原点变化；③ **能缩**：拖边框 ⇒ 宽高变化且应用收到 `ConfigureNotify`（内容跟着变，不撕裂）；④ 反极性：修前必须复现用户的三条"不能"。
- **依赖**：无（可独立开工）。

## §2 R2 · 稳定性（崩溃族，**用户当前最痛**）

- **目标**：连续操作（逐页导航、点页签、开下拉、点项、打字）**几十趟不崩**；每类崩溃要么修掉、要么登记并给出可解释的降级。
- **现状**：`D-G65`（`WaitForMultipleObjectsEx` 失败桩 ⇒ UI 线程锁竞争 ⇒ 启动即死）与 `D-G66`（`SetFocus` 回声环 ⇒ `Stack overflow.`）**已修并两极化**；用户仍报崩溃 ⇒ 车道 W57A 正在做**仪器全关**的 ≥10 趟压力表，逐类签名归类。
- **写域**：取决于签名（可能是 `win32_core.c`/`win32_msg.c`，也可能是 `WindowsBase` 应用器）。
- **判据（草稿）**：① 仪器全关、≥10 趟压力序列 ⇒ **崩溃趟数 = 0**（并为每类签名给出"修前必现/修后不现"的成对读数）；② 已登记的 `D-G67`（第二实例 `ShutdownMode` 异常）必须变成**可解释退出**而不是未处理异常。
- **依赖**：与 R1 共用装置（`Xvfb ± xfwm4`）。

## §3 R3 · 文本与排版

- **目标**：字形/度量/换行与 Windows 侧真值对齐；隐形 run、修饰（下划线/超链接）、`FlowDirection` 正确。
- **现状**：`D-G57` = 页签标题/按钮/Placeholder **整块零绘制**（已收窄到"(a) 画刷解析成白 / (b) 绘制指令未进通道"二选一，**差一格只读探针**）；`M_modifier`（`TextModifier`）= 上游语义"三件里接了半件"，与 `tline` 的 5 条 `M_modifier_*` Extent 余差**同根**；`D-T4`（tab 步长）已部分推翻原表述。
- **写域**：`build/shims/PresentationCore.HbTextLine.cs`、`src/WpfGfx.Linux.Native/tools/patch-presentationcore-*.py`（应用器）、`build/PresentationCore.Linux/**`（生成物由应用器产出）、语料/臂。
- **判据**：产品入口（**不许只用仪器**）逐行等于真值；反极性 = 修前读数可复现。
- **依赖**：需要一支**走产品入口**的文本臂（今天没有；这是本路线第一件事）。

## §4 R4 · MIL 命令面（效果/动画/未实现命令）

- **目标**：把 `docs/unimplemented.md` 里的 C 类逐条变成"实现或**具名**降级"，不再有"一打开某页就 abort"。
- **现状**：`D-G58` 已确证根因 = 缺 `0x6c MilCmdPixelShader` / `0x70 MilCmdShaderEffect` 两个 `case`（登记在 `s_notImpl`）⇒ HandyControl「工具」页第 2 项 `Effects` 一加载就 `NotImplementedException`。
- **写域**：`src/WpfGfx.Linux/Commands/**`（`MilCommandLayout.cs`、`MilCommandDispatcher.cs`）、`MilResourceTable.cs`。
- **判据**：① 该页 `alive=yes`、`unhandled=0`、该页 `notImpl` 计数 = 0；② **不许静默 no-op** —— 未实现的效果必须**具名留痕**（只读日志 + 在册登记）；③ 反极性 = 去掉 `case` ⇒ 回到 `alive=no`。
- **依赖**：与 R5 共用"效果/图像"验收页。

## §5 R5 · 图像与解码

- **目标**：第三方应用常见的图像路径可用（`pack://` 资源流、多帧 GIF、GDI+ 解码边界）。
- **现状**：GIF **只出第 0 帧**（根因已定位 `build/DirectWrite.Linux/wic-shim/wic_proxy.c:1030-1035` 的 `*pFrameCount = 1;`，**未登记**）；WIC 代理面此前量化过缺口（托管声明 102 条 `*_Proxy` vs shim 导出 77 条）。
- **写域**：`build/DirectWrite.Linux/wic-shim/wic_proxy.c`、`src/WpfGfx.Linux.Native/src/win32_gdiplus.c`。
- **判据**：帧数/尺寸/首像素与真值逐值相等（已有 14/14 的解码探针范式可套）；反极性 = 撒谎 shim 必须被打红。

## §6 R6 · 辅助功能与输入法

- **目标**：UIAutomation 客户端能枚举/操作；IME 与触笔走通或**具名**降级。
- **现状**：`WindowFromPoint` 的其它调用方（UIAutomation `IntWindowFromPoint`、Wisp 触笔）**未被覆盖**（`D-G64` 修法只验证了主窗口鼠标路径）；`UIAutomationTypes` 的 resolver 缺口此前用别名副本"止损"过。
- **判据**：起一个 UIA 客户端（`docs/unimplemented.md` 记过路径）⇒ 能拿到元素树；反极性 = 修前拿不到。

## §7 R7 · 验收装置与判据完整性（**"绿"的可信度**）

- **目标**：门禁说的"绿"必须能证伪；判据件自己被看着。
- **现状（在册）**：`D-G59` 选 X 显示用字符串序最小且整趟不复核（会选中死显示 ⇒ 47 例 X 用例静默跳过）；`R-GATE` 连续点击只有负向判据、正向判据由**仓外临时脚本**驱动；`C1b/C1d`（applocal 期望集合的静默回退、恒 0 的死格）；`W1` app-local 自动同步链缺失（已补手工可复算的同步器，未接进波）；`D-G61`（`[GEO]` 仪器 + 点下拉项 ⇒ 静默 SIGSEGV）。
- **写域**：`verify-all.sh`、`build/**` 的判据件、`build/DirectWrite.Linux/wic-shim/{check-applocal-sync.sh,applocal-expect.py}`。
- **判据**：每条洞的修法都要"改它必须让某处变红"（改判据 ⇒ `inputs_fp` 变；删副本 ⇒ 具名 `MISSING`；死显示 ⇒ 具名 `X_DIED`）。
- **⚠️ 装置缺口（本路线第一件事）**：验收必须**同时有"有 WM"和"无 WM"两条腿** —— 本工程曾有整类缺陷只在有 WM 的会话里出现。

## §8 R8 · 上游化与发布工程

- **目标**：仓库可被外部贡献者读懂、可 CI、可与上游 `dotnet/wpf` 对齐。
- **现状**：本仓把上游快照 vendored 在 `upstream/wpf/**`（入库 110.7 MB，与 fork 根自带的 WPF 树内容重叠）—— **基点 commit 已钉死 = `1cfc37f708f91ff4556bd25af414546c446f3a16`**（`#11837`，判据见 `UPSTREAM-PROVENANCE.md` §1.1）；**"去重/上游化"这一半按主控裁定暂缓**（保持现状，只在 README/INDEX 写清"构建只读 `upstream/wpf/**`"）；尚无 CI。
- **判据**：① 干净 clone + 按 README 跑通"从零构建"；② 若做上游化（去掉 vendored 副本、路径重写），必须给出"脚本/锚点全绿 + 波重建 rc=0 + 门禁 ×2"的成对读数。

## §9 R9 · 性能与内存

- **目标**：启动时间、切页延迟、呈现路径开销可量化、可回归。
- **现状**：只有零星读数（切页 ~1 s 收敛、Release 档每趟 `verify-all` ~37 min）。**没有**专门的性能臂。
- **判据**：给定序列的**端到端耗时/内存峰值**（同机三次取中位数）+ 反极性（把某优化关掉必须变慢）。

## §10 R10 · 第三方应用矩阵

- **目标**：不止"我们的样本能跑"，而是**真实第三方 WPF 应用**能跑。
- **现状**：`samples/ThirdPartyMini`（形态最简的第三方载体）+ 仓外 HandyControl 示例（当前主要真人验证对象）。
- **判据**：给定 app 的"启动 → 渲染 → 交互 → 退出"四步，每步一条机读判据 + 截图；失败点必须收敛到 `文件:行` 或 `NOINFO`。

---

## §11 怎么认领一条路线（照抄这段即可开工）

1. 在 `docs/WAVE<NN>-PREREGISTRATION.md`（或你的车道报告开头）写：**路线号 + 目标 + 判据（含反极性）+ 写域 + 预期位移**（照 PORT-SPEC §1/§3）。
2. 建**自己的私有装置**：私有应用目录（用 `bash build/MilBridge/tools/sync-applocal.sh <dir>` 同步件）+ 私有 X display（有 WM/无 WM 各一条腿）。
3. 取**修前读数**（成对的一半），再动手；动手后取另一半。
4. 写 `build/MilBridge/<车道号>-report.md`：自报 sha16、开工/收工件 sha16、读数表、复算命令、边界与 `NOINFO`、以及**你推翻了哪句话**。
5. 若动了九位 ⇒ 走 PORT-SPEC §5 的整波链；若只动判据/文档 ⇒ 至少跑 `bash verify-all.sh` 相关步 + 对应牙（`shell-quote-trap`/`pipefail-sigpipe`/`fp-inputs-hygiene`/`defect-registry`）。

---

## §12 TASK 编号与标记规范（**表达规范 · 2026-09-21 主控加**）

【为什么要统一】路线图原来只有 `R1…R10` 这一层 ⇒ "**哪一件是 MVP 关键、哪一件是下一轮要做**"只能靠散文说，
一到收尾就会出现"同一件事三处措辞"（本仓老族）。⇒ 定死下面这套，**任何人改路线图都必须照它写**。

### 12.1 编号：`TASK-<路线两位><序号两位>`

| 前缀 | 域 | 前缀 | 域 |
|---|---|---|---|
| `00xx` | **MVP 门槛**（A–E，跨路线） | `06xx` | R6 辅助功能与输入法（UIA/IME） |
| `01xx` | R1 窗口管理 | `07xx` | R7 验收装置与判据完整性 |
| `02xx` | R2 稳定性（崩溃族） | `08xx` | R8 上游化与发布工程 |
| `03xx` | R3 文本与排版 | `09xx` | R9 性能与内存 |
| `04xx` | R4 MIL 命令面 | `10xx` | R10 第三方应用矩阵 |
| `05xx` | R5 图像与解码 | `99xx` | 仓库牙齿 · 冻结收尾 |

- **一个 TASK = 一组可独立复算的读数**（不是"一个想法"）。凡写进路线图的 TASK，必须能被**另一个没参与的人**照它复算。
- 编号**只增不改**：任务合并/撤销时**保留原号**并标 `(已并入 TASK-xxxx)` / `(已撤销)`，**不许回收号**（回收号 = 历史读数失去指向）。

### 12.2 标记：写在 TASK 号后面的方括号里（可叠加）

| 标记 | 含义 | 用法纪律 |
|---|---|---|
| `[MVP]` | **MVP 关键**：用户"能不能真的用起来"的门槛 | 只有**用户可感知**的才算；内部整洁度**不许**标 `[MVP]` |
| `[Next]` | **下一轮要做的动作** | 一个 `[Next]` 必须带**可执行入口**（命令/文件:行/配方） |
| `[MVP][Next]` | 既是判据、下一轮又要动它（如零墨：判据是"页签有没有字"，动作是"发波落地"） | — |
| `[Dep]` | 依赖其它 TASK（写清 `依赖 TASK-xxxx`） | 依赖不成立 ⇒ 该 TASK 记 `NOINFO`，**不许**硬跑 |

### 12.3 状态：只用这四态（**禁止自造**）

| 记号 | 含义 | 硬要求 |
|---|---|---|
| ✅ | 完成 | 必须同时给 **artifact ＋ 字段 ＋ sha16**（三样缺一 ⇒ 降级为 🟡） |
| 🟡 | 在办 / 部分 | 必须写清**已到哪一格、缺哪一格**（"部分完成"四个字不算） |
| 🔴 | 未做 / 已知必红 | 必红项要写**判据**（预期红在哪、为什么红得对） |
| ⚪ | **未开**（0 读数） | **不许**写成"应该没问题"；未开的域宁可留白 |

### 12.4 每条 TASK 的书写模板（照抄，字段不可省）

```
- - TASK-0301 [MVP][Next] 🟡 **正极已成立（W70A 实测），反极性腿未跑** ｜ 零墨根因 = `build/shims/PresentationCore.HbTextLine.cs:2826`（单段行用**段落主面**取"按计划面整形"的字形 id）。
    两处世代位**已落地**：`hbtextline e89fed55fd8e32bc → 921ba9c65e9fb3be`、`pc 9465f9dce39e2dfc → 21e3e88a5090cd3b`（后者与 W61A 早前"同一修法落地态"实测值**逐位相同** ⇒ 两条独立路径交叉印证）。
    **机制级（C1）**：`HBLINE D#` **43 行**（负极那趟 0 —— 因 `census` 档未开 `WPF_LINUX_HBLINE_TRACE`，车道已如实标注并两侧同环境补开），命中 `[r0 face=NotoSansCJK-Regular.ttc …]`（不再是 `DejaVuSans`），多段行**照旧 3 run** ⇒ 修法未波及多段路径。
    **像素级（C2–C4，同脚本/同阈值/同几何）**：页签 `1 / 0.00% / 非众数 0` → **`colors=90 / 9.03% / 259`**；按钮 `8 / 0.15% / 10` → **`120 / 10.30% / 335`**；搜索框 `19 / 2.71% / 311` → **`67 / 5.56% / 768`** ⇒ 三格全 ✅；**C5/C6 两条零回归判据逐位成立**。
    ⚠️ **未完成**：①**还原腿**（逐字节还原 ⇒ 必须回到零墨）②`D-G72`（点菜单条 NRE）。⇒ 本行**不标 ✅**。
    ⚠️ 世代位变更后果见 `docs/WAVE49-PREREGISTRATION.md` §13.4-④（收尾链按"两处都在位"的形态冻结）。
- 判据先写、读数后取；`NOINFO` 既不算绿也不算红；**不许静默 no-op**；改动前 `cp -p` 备份；按 PID 止损（**不许 `pkill -f`**）—— 见 `docs/PORT-SPEC.md`。
- 「完成」的最终裁判**不是**本文件的记号，而是仓的门禁读数（`DEFREG` / `VERIFYALL_SELF` / 冻结基线 / `verify-all`）；本文件是**地图**，不是判据本体。
- 每条 TASK 若与缺陷册对应，**必须写出在册编号**（如 `D-G70`／`D-G72`），免得"地图"与"缺陷册"两处措辞分叉。

## §13 当前任务树（**一项一行**；快照 2026-09-21；`[MVP]`=MVP 关键，`[Next]`=待办）

```
wpf-linux 路线图
│  状态：✅完成 🟡在办/未定 🔴未做 ⚪未开      （ID 规则见 §12；每行一个 TASK，细节走缩进子树）
│
├─ 00xx MVP 门槛
│   ├─ TASK-0001 [MVP] ✅ A 能编译
│   ├─ TASK-0002 [MVP] ✅ B 能开窗渲染
│   ├─ TASK-0003 [MVP] ✅ C 必抛替身接线
│   ├─ TASK-0004 [MVP] ✅ D 不被 Debug.Assert 打死
│   ├─ TASK-0005 [MVP] ✅ E 交互（E1 切页 / E2 复选框·焦点 / E3 下拉 / E4 滑块 / E5 文本框打字 / E6 列表项）
│   ├─ TASK-0006 [MVP] ✅ 真机口径：hc 示例逐页实测 **29/31 页可用**
│   ├─ TASK-0007 [MVP] 🔴 切「富文本」23／「流文档」24 **必死 rc=134**
│   │   └─ 真因 = TASK-0302（PTS/LineServices 未实现，`D-G70`）；守护救不了（`Environment.FailFast`）
│   └─ TASK-0008 [MVP] ✅ 点顶部菜单条 ⇒ NRE ⇒ 死（本轮修好）
│       ├─ 根因：shim `GetMonitorInfoW` **不读 cbSize** ⇒ 对 hc 的 40 B `MONITORINFO` **越界写 32 B**
│       └─ 读数：A/B/C 唯一变量是被测 `.so` ⇒ 修后 存活 / `unhandled=0`；`win32shim → c493639d15678803`
│
├─ 01xx R1 窗口管理
│   ├─ TASK-0101 [MVP] ✅ `PMaxSize` 把窗口钉死（产品级成对：修前 `max 784x560` → 修后**缺席**）
│   ├─ TASK-0102 [MVP] ✅ 缩 / 放 / 拖 / 最大化（含应用自带 Max 按钮）
│   ├─ TASK-0103 [MVP] ✅ 去双层窗口装饰（`_MOTIF_WM_HINTS=0x2`；普通窗口仍被装饰，成对）
│   ├─ TASK-0104 [Next] ✅ **定性完成（W77A）**：**主要是仪器时序假象，不是产品缺陷** —— 自绘 chrome 按钮在 map 后 **4.2–4.7 s** 才进视觉树（`[GEO]` 零点击：`T≤4.2 MAX=[none]`，`T=4.7` 起 `MAX=[943,213 46x28]`；0 s 时点击命中 `StackPanel#ButtonPanel`），且最大化后**面板重排**（`ButtonRestore` 换到 `dx=74`，`ButtonMin` 恒 `dx=122`）⇒ 坐标必须**状态相关**。四入口在"预热 ≥5 s＋状态相关坐标"下全部可用。
│   │   └─ ⚠️ **唯一真产品不对称 = `D-G81`**（新登记）：**WM 侧发起**的最大化 ⇒ 双击 **3/3** ＋ 自带还原按钮 **3/3** **都还原不了**（终态恒带 `MAXIMIZED_*`）；**应用自发**发起的能还原（双击 6/6、按钮 5/5）。判据待写死，属 `#50`
│   ├─ TASK-0105 [Next] ✅ **边界已测（W77A）**：单发腿 **d∈[2,3] s 被吞（0/8）**，`d≤1.5`（5/5）与 `d≥4.5`（5/5）全生效 ⇒ 左界 `(1.5,2.0]`、右界 `[3.0,4.5)`；⚠️ 3 趟阶梯腿**推翻"边界是常数"**（迟到 configure 时刻逐趟漂移 ~3.0 s／~6.5 s／不出现）⇒ 只能当"这台机这一刻"的读数。
│   │   └─ **建议（已采纳进仪器）**：**请求后回读校验＋重试**（最稳）；靠时间就**暖机 ≥5 s（保守 6 s）** —— `~/mvp-accept.sh` 现有 6 s 暖机与此一致
│   ├─ TASK-0106 [Next] ✅ **已修（`#50`，车道 W82A；主控独立复核）** —— `D-G83`：`WM_GETMINMAXINFO → WM_NORMAL_HINTS` 通道恢复
│   │   ├─ **真因（推翻我原判定点的一半）**：`H1` 单落地仍 FAIL（补问那拍两个守卫都是 false）；真因 = **波 58 把 `DefWindowProcW` 的 `case WM_GETMINMAXINFO` 写成"填默认值"** ⇒ 托管侧写对（`521x417/667x500`）后被**我们自己就地盖回** `1x1/1280x1024`（上游 `Window.cs:4272-4298` 第二段 `switch` 无该格 ⇒ `default: handled=false` 覆盖 `:4250-4252`）。**Win32 语义里填默认值属发消息方，`DefWindowProc` 本应 no-op** ⇒ 托管侧不用改
│   │   ├─ **四格**：`declared` ⇒ `maximum size: 667 by 500` ✅｜`minonly` ⇒ `minimum size: 521 by 417` ✅｜`undeclared` ⇒ 缺席 ✅｜`reg58` ⇒ `1280 by 1024` 出现 **0** 次 ✅（装置自证 PASS）
│   │   ├─ **反极性**：复原修前源 ⇒ `win32shim` 回到 `c493639d15678803`、五窗全缺席；再前进 ⇒ **`3e4390c9ec07f621`**（往返闭合）⇒ **`#50` 位移多一位**
│   │   └─ ⚠️ 同时**证伪波 58 注释里"那个 case 是不可达死码"**（实测每次都走到且在窗口过程之后，`:885-895` 已更正）；`win32_x11.c` 一字节未动
│   ├─ TASK-0107 [Next] ✅ **已办（`#50` 波尾，车道 W93A，报告 `build/MilBridge/W93A-report.md`）** —— `D-G83` 后续 `H2`：**两个问题都有读数**：`H2-a` **运行期不跟随**（4 格 `FAIL`，全是运行期改动格；正对照 `W2-TOGGLE` 一按即正确落 `521 by 417` ⇒ **通道没坏、缺的是触发器**）＋ `H2-b` 本机**有** WM（私有 `Xvfb :182`＋`xfwm4`）且约束**真生效**（客户请求 `1000x800→667x500`／`300x200→521x417`；拖边框**对照窗** `667x500→937x692`、**受限窗纹丝不动**）
│   │   ├─ ⚠️ **反极性 = `VACUOUS`**（按**先写死**的口径，如实报）：`W1` 的 X 侧提示在 14 个 stage 里**一次都没移动过** ⇒ "回到旧值"与"从来没跟过"**不可分** ⇒ **不构成反极性证据，不许当绿**
│   │   ├─ 🆕 **同趟新登记**：`D-G88`（`H2` 本体 = 运行期改提示到不了 X；终态死锁 ＋ 预算**计"问"不计"改"**）、`D-G89`（`xprop … | grep -q window` **恒真** ⇒ "等 WM 起来"等于没等）、`D-G90`（`[WMSIZE_DIAG]` **每进程 40 行硬截断** ⇒ 不能当派发总数）
│   │   └─ **落地拆新号**（本件**零产品改动**，探针在仓外）：`TASK-0108`（`H2` 修法 `P1`–`P4`）／`TASK-0703`（恒真判定修法）—— 均属波 `#51`
│
├─ 02xx R2 稳定性（崩溃族）
│   ├─ TASK-0201 [MVP] 🟡 静默 `rc=139`＋0 字节日志：**15 趟跑满零命中**（上界≈20%）
│   │   ├─ 唯一信号在运行时 `/memfd:doublemapper`（被运行时自愈、不致命）
│   │   └─ ⚠️ **上界已被 `TASK-0203`（车道 W98A）收紧到 `4.87%`**（同一签名、同一装置；**本行的状态 🟡 与判词一字未改** —— 该项仍「未复现到可归因」，见 §14 的 `TASK-0203`）
    ├─ TASK-0202 ✅ 修 `D-G72`（点菜单条 NRE；根因 = `GetMonitorInfoW` 不读 `cbSize`、对 40 B `MONITORINFO` 越界写 32 B）—— 已随 `#49` 冻结（`win32shim c493639d15678803`）
│   ├─ TASK-0203 [Next] ✅ **精度目标达成、`139` 族仍 `NOINFO`**（车道 W98A，报告 `build/MilBridge/W98A-report.md` `74df2f1a289bcc45`，台账 `~/w98a/runs.tsv` 128 行×33 列）：臂 A（现场权威件 `33352e5797031999`）无 WM 腿 **0/60** ⇒ **95% 上界 `4.87% ≤ 5%`**；两臂合并 **1/126**（主判据腿 120 趟口径 = `2.47%`）｜**`134` 族两极化干净成立**：臂 B（修前件 `abf6879c027c5e73`）**59/60 崩** vs 臂 A **0/60**｜**`139` 族 `NOINFO`**：唯一 1 次落在**修前件臂**（`L1B024`，真 `139`＋核心转储、应用 0 字节、7 击全落地后死在 `nav2`）⇒ 方向对、**1 次撑不起归因**。｜〔**2026-09-23 收口：状态位 🟡 → ✅**（车道 W130A 落册）—— 这里的 ✅ **只指"测量交付完成"**（机制 ＋ 具名判定点 ＋ 两个同址样本 ＋ 上界 `3.55%` 均已拿到，终报读数见下方新增两行与 **§15p**）；**产品侧未修 ⇒ `D-G109` 仍红**、处置 = **`TASK-0209`**〕
│   │   ├─ **阳性对照复现**（`PCB 2/2 崩` 6,478,046 B／19,393 B ＋ `PCA 0/2`）｜耗时壁钟 **2 h 46 min**（让路 1020 s、槽内 6850 s、每趟中位 75 s、`void=0`／`oom=0`／`MAXHold_KILL=0`）
│   │   ├─ 🆕 **同趟新登记**：`D-G93`（闸门 `pgrep -f` 命中别家 `bash -c` 轮询器 ⇒ **假死锁 300 s**，当时槽是空的）、`D-G94`（把"**没点**"的 `SKIP dead` 算进分母 ⇒ **唯一那次真 `139` 被自己的口径判成"无检测力"并剔除**）；`D-G87` **第三次复核**（61 趟 `134` 里 **14 趟只写 18–19 KB 折叠形 = 23%**）
│   │   ├─ **代价与边界**：两 shim **符号差 25 个导出**（`#50` 落地 `A1`/`A2` 后由 14 涨到 25）⇒ **即使两极化成立也不许归因单一改动**；本机 `Xvfb 1024×768±xfwm4` 与用户现场（xrdp＋xfwm4）**不同构**
│   │   ├─ 🆕 **终报收口（2026-09-23；读数出自车道 W128A 终表、车道 W130A 落册时现场复核；报告 `build/MilBridge/W128A-report.md` FULL `789d01e5f8959b0b70ffda770e8c02dac653661e48af5510f7e5a5d6ca485878`／`head -n -2` sha16 `d014ebd90d45840e`／352 行／37,548 B）**：主臂 **`175/175` 全部有效（剔除 0、作废 0）** ＋ 对照臂 **8 趟**（`K0C…K7C` 全 `124/alive/落地 8`，逐批阳性对照成立 ⇒ **零作废**）⇒ 结局 = **`134`×173 ＋ 静默 SEGV×2**；**命中 2 趟**：`W071`／`W077` 崩点 **`PC` 逐位同址 `0x7fff740dcdf3` = `wpf_queue_push+259`**（偏移 `0x11df3`，逐字 `mov 0x38(%rax),%rax`）＋ 两趟 `stacklast.raw`／`maps.txt`／`perf.map` **同刻齐全**（mtime delta `0.0`）＋ 整目录冻结 `~/w128a/frozen/{W071,W077}`（`stacklast.raw` = `9ff31a24fa90f56e`／`9cd325be4e5381b0`）｜判词 = **`异源`**（崩在 **`.NET Finalizer`（`tid=6`）**／**浅栈 `7,088 B`**／**无重复环 `R1=R2=False`**／**应用输出 0 字节**）＋ **判定点 = `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82`**（约 `:79` `while (p->next) p = p->next;`）；`siaddr=0x0` 记 `NOINFO`、**判词不依赖它**｜**上界（新口径）**：本批 **`2/175 ⇒ 95% 单侧上界 3.55%`**（点估计 **`1.14%`**）｜与 `W98A` 同件同腿合并 **`3/235 ⇒ 3.27%`**｜本装置全部 **`2/236 ⇒ 2.64%`**｜**再压的代价（未自行开跑）**：`≤1.0%` 需 **299／473 趟**、`≤0.5%` 需 **598／947 趟（≈5.3／8.4 槽小时）** ⇒ **主控裁定：不投**（机制与判定点已拿到、上界已足够；要投由用户拍板）｜**槽**：批内实占 `5,880 s`、**让路 `4,778 s`（≈80 min，全给 `#52` 收尾链）**、批间一律释放槽，`low-memory`／`MAXHOLD_KILL`／`TIMEOUT` 各 **0**
│   │   └─ ⚠️ **收口口径（逐字，须与 `D-G109` 同读）**：**`TASK-0203` 的"✅" = 测量交付已完成**（`139` 族**不再 `NOINFO`**：归因落到"**异源 ＋ 具名判定点**"）；**产品侧修复另立 `TASK-0209`（已由 W129A 立）⇒ `D-G109` 仍红、不许当"已修"**。**口径句（逐字）**：**`SILENT_SEGV_HIT ⇔ 应用输出 == 0 B（剔 `timeout:` 行）∧ STACKOVF == 0 ∧ 死于 SIGSEGV（`RC==139` ∨ `APP_FATE` 含 SIGSEGV ∨ `gdb.txt` 含 "Program terminated with signal SIGSEGV" ∨ `gdb.txt` 存在 `W118A-STOP-N`(N≥1) 且 `signo=11`）`** —— **最后一支抗收尾截断**（该句在 `D-G109` 内**已逐字在册**（仅反引号排版略异），**本批只引用、不重写**）。**`D-G98` 的适用范围照旧：只指 `134` 族的几何/尺寸约束那条线，不含静默 SEGV**（两者**异源**）。**交叉引用（不新号）**：`D-G106`（`ARM=gdb` 下 `APP_RC` 不是应用 rc ⇒ 假可疑把真命中踢出分母）／`D-G107`（`thread=(\S+)` 对多词线程名 `.NET Finalizer` **整行不匹配** ⇒ 误判 `NOINFO`）／`D-G109`（本体）／`D-G96`（证据冻结）。
│   └─ TASK-0204 ✅ 登记 `D-G73`（`WM_SYSCOMMAND` 未实现＋`ShowWindow(SW_MAXIMIZE)` 空操作）／`D-G74`（`ConfigureNotify` 父窗相对坐标 ⇒ 命中测试偏掉）
│
├─ 03xx R3 文本与排版
    ├─ TASK-0301 [MVP] ✅ **随 `#49` 冻结生效**（零墨修法已在世代内：`hbtextline 921ba9c65e9fb3be`／`pc 56ee75ced8d6aece`）
│   │   ├─ 根因：`build/shims/PresentationCore.HbTextLine.cs:2826` 单段行用**段落主面**取"按计划面整形"的字形 id
│   │   ├─ 世代位：`hbtextline e89fed55… → 921ba9c65e9fb3be`；`pc 9465f9dc… → 21e3e88a5090cd3b`
│   │   ├─ 像素成对：页签 `1/0.00%`→`90/9.03%`；按钮 `8`→`120`；搜索框 `19`→`67`
│   │   ├─ 零回归：导航项 `69/10.47%/303`、下划线带 `2/22.00%/156` **逐位不变**
│   │   └─ 反极性：shim＋pc 逐字节还原 ⇒ 四区回到 `1/8/19/69`、截图 sha 回 `9380291b84d81dd6`
│   ├─ TASK-0302 [MVP] 🔴 PTS / 原生 LineServices（**111 条 `Fs*`/`Lo*` 缺口**，`D-G70`）
│   ├─ TASK-0303 [Next] 🟡 **只读侦察＋最小第一步设计已完成**（车道 W78A，报告 `build/MilBridge/W78A-report.md` `0dbc62b1d1cf86ee`，568 行；零 `dotnet`/零应用/零构建）
│   │   ├─ **`A0` 实测已做（W81A）**：最小 `FlowDocument` 页面**第一跳就死**（`CreateInstalledObjectsInfo` MISS ⇒ `FailFast` `rc=134`；`ld.so` 自己写 `undefined symbol … (fatal)`）⇒ **27 条清单只命中 1 条**，其余 **26 条"还没轮到"**（不是不需要）⇒ 往下走必须先落地 `A1`/`A2`。⚠️ 顺带抓出仪器缺陷 **`D-G84`**（绊线过滤器看不见该致命符号、`LoadCursorA` 9 行被误判 MISS ⇒ 判据要用 `nm -D`）
│   │   ├─ **出口面实测**（必须现算 `nm`；仓内 `bin/exports.txt` 是 9-14 陈旧件 472 行 vs 现件 **535**）：指向该 DLL 的 `[DllImport]` **145** 条 ⇒ **可用 36 / 缺 109** = `Fs*` 66＋`Lo*` 22＋`Nl*` 6＋`*Wrapper` 5＋其它 10；扣 9 条 `#if NEVER` 死声明＋1 条探测序误报 ⇒ **真会炸 99 条**（`unimplemented.md` §2.7 记 97，差 2 ⇒ **NOINFO**，未改别人的数）
│   │   ├─ **最小闭包 = 27 条入口**（16 `Fs*`＋6 PTS 上下文/对象＋5 LS）**但不是 27 个 stub，而是一套分页引擎契约＋151 处回调（135 个不同名）的 ABI**
│   │   ├─ **两条反直觉结论**：① `Lo*` 行引擎 20 条**不在闭包**（行由**托管**排：`PfnFormatLine` 是托管回调 `PtsCache.cs:568`，`TextFormatterImp.Linux.cs:679/690/723` 已接两层兜底）② 但**构造期那 3 条 LS 跑不掉**（`StructuralCache.cs:480` **恒传 `true`**）⇒ PTS 与 LS 构造期**耦合**
│   │   ├─ **hc 两页差距巨大** ⇒ 建议把"救 23/24"**拆成两条**：第 24 项 `RichTextBoxDemo`（23 行）≈ 最小页面；第 23 项 `FlowDocumentDemo`（114 行，Table 8 单元/Floater/Figure/多列 `ColumnWidth=400`/断字）**几乎要整族**
│   │   ├─ **推荐最小第一步 `A′`**（把"缺 PTS"从**整进程必死**变成**具名·可判·可见的能力边界**）：`A0` 用**现成** `build/MilBridge/tools/t1b-ls-tripwire.sh`（真值 = `ld.so` 的 `LD_DEBUG=symbols` 日志）把闭包从静态推断**变实测**｜`A1` native 新 `win32_pts.c` 导出 6 个入口、**返回非零 LsErr 如实失败**＋具名台账 `PTS_GAP entry=… seq=…`｜`A2` **PF 修 `D-G78` 的毒池项**（≈40–90 行，**这一件才"救进程"**）｜`A3` 页级"不支持"必须**看得见**（空白不许读成绿）
│   │   ├─ **代价**：`A0` 一次应用运行｜`A1` ≈150–250 行 C＋一次 `build-shim.sh`｜`A2` ≈40–90 行托管｜`A3` 一条页级降级＋判据脚本 ⇒ **总量 ≈ 半天机时**（对比"真实现 PTS" **月级**）；**世代位只动 `win32shim`＋`pf`**（`pc`/`hbtextline` 不动）
│   │   ├─ **最大风险**：把 `FailFast` 变成**静默半通** ⇒ 判据必须带 **`N2` 反极性（假绿探测器）**："stub 改成返回成功 ⇒ 判据必须变红"
│   │   └─ `NOINFO`：`A0` 需求序列（禁跑应用）／`A′` 的 `alive=yes`（预判未实测）／第 23 页真闭包（仅静态统计）／`97 vs 99` 差额来源
│
├─ 04xx R4 MIL 命令面
│   ├─ TASK-0401 [MVP] ✅ `Effects` 页（`0x6c`/`0x70` 已实现＋具名台账）
│   ├─ TASK-0402 [MVP] ✅ 已登记 `D-G71`（视觉级效果被静默丢弃）
│   └─ TASK-0403 [Next] ✅ 视觉级效果**可见化**（通道级具名台账）
│       ├─ 落点：`MilChannel.cs:175` 定义 / `MilCommandDispatcher.cs:191` 调用（`src/WpfGfx.Linux/**` ⇒ 进桥不进 `pc`）
│       └─ 成对：撤件 ⇒ `失败 1`；还原 ⇒ `失败 0/通过 166`；`Commands.Tests 562/562` **逐字不变**
│
├─ 05xx R5 图像与解码
│   ├─ TASK-0501 [MVP] 🟡 GIF 只有第 0 帧（`wic_proxy.c:1030-1035`）
│   └─ TASK-0502 [Next] ✅ **已办（2026-09-21，车道 W79A；波 `#50` 首批落地件）** —— GIF **多帧＋帧时序**
│       ├─ 判定点：`build/DirectWrite.Linux/wic-shim/wic_proxy.c:1034`（修前 `*pFrameCount = 1;`）＋`:1043`（`index != 0` 一律 `E_INVALIDARG`）；修法 **11 处全在一个文件**
│       ├─ **读数**：3 帧 GIF `COUNT=1 → 3`、4 帧 `→ 4`，逐帧 `CopyPixels` 与真值**逐字节相同**；帧延迟 `/grctlext/Delay` 由 `UNSUPPORTEDOPERATION` → **`VT_UI2` 逐帧相符**（10/20/30、5/10/15/20 cs）
│       ├─ **三侧都成立**：正 `WICFRAMES=PASS fails=0 noinfo=0`（rc=0）｜反（还原修法）`FAIL rc=1`｜**假修 3/3 全被抓**（`SELFTEST=PASS liars=3 caught=3`：还原／帧数真但像素恒第 0 帧／声明 1 帧却给得出第 1 帧）⇒ 靠 **H2 逐字节＋H3 帧间互不相同** 抓住（只查状态码的判据对它**零射程**）
│       ├─ **零回归**：单帧 PNG/JPEG/单帧 GIF＋3 帧 GIF 的第 0 帧 → 与修前件**逐字节相同**（4 例）；第 0 帧仍走老那行 `options=NULL`；**导出集合 diff 为空**（96 条逐条相同）
│       ├─ **世代位**：`wic_shim 56278c14b4ecd672 → f7b3026c8c019be2`（74984 B）——**只动这一位**；`inputs_fp` **不动**（覆盖面不含 `build/DirectWrite.Linux/wic-shim/**`）
│       ├─ ⚠️ **波尾必做两件**：①`bash build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh --apply`（权威件换 sha ⇒ `APPSYNC MISMATCH 1[STALE=1] → 5[STALE=5]`，4 条点名：`publish/release_linux-x64`、`.artifacts/bin/ClosedLoop/release`、`samples/WpfFeatureProbe/Release`、`samples/ThirdPartyMini/Debug`）②修前 `libwpfwic.so` 原有 **2 硬链接**（仓内＋另一车道负样例仓 `~/w62a/negrepo`），重建后**链接已断**、那份仍是旧字节（**没替别人改**，但两份不再同 inode）
│       └─ `NOINFO`：`disposal=2` 的后续帧 —— **Skia 自己返 `kInvalidConversion(3)`**（四种选帧变体全 res=3）⇒ 我们**如实失败 `E_UNEXPECTED`、不假装成功**；托管级端到端**未跑**（本轮零 `dotnet`，samples 无 GIF 载体）⇒ 代理级契约已证、PC 侧后续行为 `NOINFO`。另：`wic_proxy.c:202` 有 **3 个真 NUL 字节** ⇒ 该文件被判二进制、`grep -n` 静默失效 ⇒ 已登记 **`D-G82`**
│
├─ 06xx R6 辅助功能与输入法
│   └─ TASK-0601 [Next] ✅ 只读侦察完成（报告 `a1b01055b7080502`，**12 条空缺表**）
│       ├─ UIA：**有路无门**（`WM_GETOBJECT` 自有代码仅 1 处且是消费者）＋**门后断头**（`UIAutomationCore.dll` 在 `build/shims/` 0 命中）⇒ `D-G75`
│       ├─ IME：**一处落点都没有**（按键走 `XLookupString(...,NULL)`；`GetSystemMetrics(82)` 那重门是**巧合关闭、无人决定过**）⇒ `D-G76`
│       └─ 边界：全部**静态**读数；hc 侧无断言点 ⇒ 运行时行为 `NOINFO`
│
├─ 07xx R7 验收装置与判据完整性
│   ├─ TASK-0701 [MVP] ✅ `~/mvp-accept.sh` ＋ `~/heavy-slot.sh`（`--max-hold` / **内存闸门 `--min-avail`**）
│   └─ TASK-0702 [Next] ✅ `R-GATE`：把"连续点击"判据收编进仓并接进 `verify-all`
│       └─ ⚠️ 要改 `verify-all.sh` ⇒ **必须等冻结之后**
│
├─ 08xx R8 上游化与发布
│   ├─ TASK-0801 [MVP] ✅ fork ＋ `feat-Linux` 默认分支 ＋ README/README-Window/PORT-SPEC/ROUTES/FORK-AND-PUSH
│   └─ TASK-0802 [Next] ✅ 11 件文档已推远端（远端 `a0e783d…` 已核；默认分支仍 `feat-Linux`）
│       └─ ⚠️ 余项：**12 件源码/门禁数据待随收尾链同批推**（否则"文档说已修、分支里没修"）
│
├─ 09xx R9 性能与内存
│   ├─ TASK-0901 [MVP] ✅ OOM 的 `rc=137` 不算缺陷（已机器化：`HEAVYSLOT=NOINFO low-memory`）
│   └─ TASK-0902 [Next] ✅ **基线已测（W77A）**：⚠️ **预登记判据失效** —— 窗口最大唯一色数只有 **372 < 800** ⇒ 登记的"首帧 >800 色" 3/3 `NOINFO`。事后口径（**采样分辨率实测 0.090–0.094 s，不许读更细**）：`t(>1 色)` 中位 **1.227 s**（1.223/1.227/1.274）｜`t(>33 色)` 中位 **5.210 s**｜`t(>195 色)` 中位 **6.007 s**。**最靠得住的是内存**：`VmHWM` 中位 **≈891 MB**（912,540／901,336／988,392 kB，全距 87 MB）。⇒ 阈值需**重新标定**（判据口径类）
│
├─ 10xx R10 第三方应用矩阵
│   ├─ TASK-1001 [MVP] ✅ ThirdPartyMini 配置分叉（`C1c` 根因）
│   └─ TASK-1002 [Next] ✅ 补声明图（`UNEXPECTED 16→6`；反极性在 `cp -al` 副本上成立）
│
└─ 99xx 仓库牙齿 · 冻结收尾
    ├─ TASK-9901 [MVP] ✅ `DEFREG=PASS declared=112` / `VERIFYALL_SELF=PASS` / `DECLDRIFT=0`
    ├─ TASK-9902 [MVP] ✅ **冻结基线 `#49`**（`f1d340d66c7c6ba3`，615,139 B）—— `#48` 已被取代
    ├─ TASK-9903 [Next] ✅ 连带红已清：`Commands 562/562` ＋ `Rendering 166/168`
    ├─ TASK-9904 [Next] ✅ **已办（2026-09-21，车道 W76A；主控独立复核）** —— 波 `#49` 收尾链**走到底**
    │   ├─ **冻结成功**：世代 **`#49`**，基线 **sha16 `f1d340d66c7c6ba3`**（615,139 B）；机器行 `docs/CURRENT-STATE.md:9`（唯一声明处，`BASELINEDUP=PASS n=0`）
    │   ├─ 冻前**恰好 1 处**声明类红（`COLUMN-FLOOR`，`bad= tline`）；**冻后两趟**：`25 ✅/0 ❌`、`875 通过/2 跳过`、`rc=0`（两趟都真跑）
    │   ├─ **位移 6 位**：`bridge feef049e9d0e313a`／`pc 56ee75ced8d6aece`／`pf 6375fabf89ac7fef`／`windowsbase 2e4e46e539a72cd7`／`win32shim c493639d15678803`／`hbtextline 921ba9c65e9fb3be`（表外位移为空）；`inputs_fp = 9f2199b212bed2b212035f87ff6006672605ff7bea6221c0be540301b1a8380b`（可归因六件）
    │   ├─ **推送**：远端默认分支仍 `feat-Linux`；head `a0e783db… → 7feca487741a8070de81615bd04de889b992766d`（三笔纯快进）；**43 件逐字节核对全一致**（两块大 JSON 按 `.gitignore` 不进）
    │   └─ ⚠️ 冻结途中修掉两处**判据本体**缺陷：`D-G79`（门禁认错窗口 ⇒ 12/12 假 `no-window`；修后认领 `0x200005`，反极性"真窗不可见仍 FAIL"齐）／`D-G77`（`retake-arms-w23.sh` 硬写 `:97` 且无保证 ⇒ 闸门外重取静默 X-混淆）
        ├─ 整波 → 重取五臂 → `repin-generation --why`（逐条写覆盖面变动）→ 门禁 ×2
        ├─ 冻前 `verify-all`（预期**恰好 1 处**声明类红 = `COLUMN-FLOOR`）→ 冻结 `#49` → 冻后 ×2 → 收尾记录三段
        ├─ ⚠️ 重钉前**必须同趟**改 `known-red.json` `entries[1]`（`Extent 余差 95 → 1242`）否则 `registry-stale(drift)` ⇒ FAIL
        └─ ⚠️ 世代位现为**三处**：`hbtextline 921ba9c6…` / `pc 21e3e88a…` / `win32shim c493639d…`；重建桥 ⇒ `wpfgfx_cor3.so` 必出新值
```

**`[Next]` 合计 14 条（**一行一条**，不合并）**：
- `TASK-0104` ✅ 定性完成（仪器时序为主；真不对称另立 `D-G81`）
- `TASK-0105` ✅ 边界已测（暖机 ≥5–6 s；建议回读校验＋重试）
- `TASK-0106` ✅ `D-G83` 已修（四格全绿；`win32shim 3e4390c9ec07f621`）
- `TASK-0203` [Next] ✅ **已办（车道 W85A，报告 `build/MilBridge/W85A-report.md` `eb011130280cf295`）**：**用户签名未复现** —— 全库 **80 趟有效样本 0 命中 ⇒ 95% 上界 3.7%**（单臂 15 趟各 **18.1%**，已达 ≤20%）；再压到 ≤5% 需 **60/臂 ≈ 3.0 h**
  - `TASK-0203` ✅ **拿到了 `134` 族的真两极化**（单变量 = `libwpfwin32.so`）：无 WM 时**修前 15/15 崩（`rc=134`＋`Stack overflow.`，15/15 都死在"点页签"那一击）vs 修后 0/15**；**无 WM 快连点 150 击**：修后 **4/4 活**（各吃 147–148 击）、修前 **4/4 崩**（第 5/6/76 击）⇒ 判决点 = **两 `.so` 的改动集关掉了 `D-G66` 的 `SetFocus` 回声环**（栈顶闭合 `FilterMessage ← OnSetFocus ← … ← SetFocus`，环 ≈2,950 次）
  - `TASK-0203` ⚠️ **有 WM 那一格不算数**：修前臂点击**从第 2 击起被吞**（落地 2/13）⇒ `0/15` 无检测力；**"崩不崩"跟着"点击能不能落地"走，而"能不能落地"跟着"有没有 WM"走** ⇒ **两条腿都要**（见 `docs/WAVE49-PREREGISTRATION.md` §13.4-⑦）
  - `TASK-0203` ⚠️ 它**推翻 W77A「装置不能归因」**：`C101` 本是**无 WM** 趟（W63A `run/C101/meta.txt` 写 `DISP=:196`），W77A 拿"有 WM"去复刻才 0/2；它 §5.3 的"两臂只差 `ENTRY_N`"也是误读（其修前臂 `AE=0` = 死仪器）
  - `TASK-0203` 🆕 **新登记 `D-G87`**（判据缺陷，车道自报 `W85A-F3`）：**把"日志体积 ≥1 MB"当签名判别量会漏判真崩**（2/15 趟真崩只写 19 KB 折叠形）⇒ 改判"**退出码 ＋ 首行/栈 ＋ 有无 `Unhandled`**"；`W63A` 的"`139`＋0 字节 = 原生层"**只成立"原生不留日志"这一半**
  - `TASK-0203` `NOINFO`（未做）：14 个导出里**判不到具体哪一处**关掉了环；两臂树是**陈旧 app-local**（未换 `#49/#50` 权威树复验）；`CAL` 只到"输入被吞、跟着 shim 走"，**未到 grab 层**；全程让路排队共 **4,048 s**
  - `TASK-0203` 续：**用户那个 `139`＋0 字节仍在跑**（臂2 无 WM ×15 → 臂3 有 WM＋gdb ×15 → **定向腿：无 WM＋150 击**（对应 WAVE49 §11.1 的"第二签名 = 静默 core dump"）→ 零点击反极性 ×4）
  - `TASK-0203` ⚠️ 口径：**这一族"有 WM 时点击不落地 ⇒ 回声环走不到"** ⇒ **两条腿都要**（详见 `docs/WAVE49-PREREGISTRATION.md` §13.4-⑦）；W77A 的"这套装置不能归因"**已被推翻**（它把 `C101` 的 `DISP=:196`（无 WM）误标成"有 WM"）
- `TASK-0303` 🟡 设计已交（W78A）＋ `A0` 实测已做（W81A）；下一步 `A1`/`A2`（产品改动）
- `TASK-0403` ✅ 视觉级效果可见化（撤件必红 ∧ 还原必绿）
- `TASK-0502` ✅ GIF 多帧＋帧时序（`wic_shim f7b3026c8c019be2`）
- `TASK-0601` ✅ R6 只读侦察（12 条空缺表；`D-G75`/`D-G76`）
- `TASK-0702` [Next] ✅ **已办（`#50`，车道 W84A）** —— `R-GATE` 收编进仓并接进 `verify-all` 第 **`[26]`** 步（四处声明同趟：口径句＋`DECL 26 gen=#50`＋`STEP-NAMES`＋新建 `docs/WAVE50-PREREGISTRATION.md`）；机读行 `R_GATE=PASS crit=13/13 clicks=11 …`；`--selftest` **21/21**；单趟 ≈37 s
  - `TASK-0702` ⚠️ **正极性拿到的是 FAIL（11/13、red=2）—— 抓到真缺陷 `D-G85`**（点选下拉项后捕获不释放 ⇒ 后续点击被误路由；路由与命中测试分叉）⇒ **用户拍板要修**；已派生 `TASK-0206`（只读诊断取分界读数）
  - `TASK-0702` ⚠️ **它推翻了 `#49` §4 一句**："B3 接线 ⇒ `inputs_fp` 必变"**不成立**（机械抽出覆盖面 144 件，它的两件命中 **0**）⇒ 更正见 `docs/WAVE49-PREREGISTRATION.md` §14
- `TASK-0802` ✅ 43 件推远端并逐字节核对
- `TASK-0902` ✅ 基线已测（`VmHWM` 中位 ≈891 MB；阈值待重标定）
- `TASK-1002` ✅ 补声明图（`UNEXPECTED 16→6`）
- `TASK-9903` ✅ 连带红已清（`Commands 562/562`＋`Rendering 166/168`）
- `TASK-9904` ✅ 波 `#49` 收尾链走到底（冻结＋冻后 ×2 全绿）

**`[MVP]` 未绿 3 条**（逐条）：
- `TASK-0007` 🔴 切「富文本」23 /「流文档」24 必死 `rc=134`（真因 `TASK-0302`，属 R3 长线）
- `TASK-0201` 🟡 静默 `rc=139`＋0 字节：15 趟零命中（上界≈20%）
- `TASK-0302` 🔴 PTS / LineServices（111 条 `Fs*`/`Lo*` 缺口）

## §14b `D-G85` 修法与 `R-GATE` 收绿（一行一条；2026-09-22）

- `TASK-0207` [Next] ✅ **已办（车道 W88A，报告 `build/MilBridge/W88A-report.md` `97c03dbc26eefe80`）**：`MouseDevice.cs:388` 释放后补 `ChangeMouseCapture(null, null, CaptureMode.None, timeStamp)`（应用器注入、上游零改动）⇒ `R_GATE` **11/13 → 12/13**，承重格 `c11`（连点三下）**转绿**（`EVT combo.down` 7→5、`lst.down`/`tb.focus` 1→2）
- `TASK-0207` ⚠️ **M2 单做没变绿**（只去掉 `HwndMouseInputProvider.cs:730` 的 `&& _active`）⇒ **没有证伪** W87A 对门(ii) 的判读（红格与普查逐格相同）
- `TASK-0207` ⚠️ **反极性 ✅**：拆接线＋删生成物 ⇒ `pc` **逐字节回到 `56ee75ced8d6aece`**、`R_GATE` 回到 `11/13 red=2` 逐格相同；`--selftest` 仍 21/21
- `TASK-0207` 件：新 `pc = 5aa6361a5ba02991`；`hbtextline`/`win32shim` 未变；**两处登记由主控落**（`integration-wave.sh` 的 `APPLIERS_EXPLICIT+=` ＋ `applier-audit-expected.txt`）⇒ 复核 `APPLIER_AUDIT_SUMMARY appliers=27 ok=92 miss=0 red=0`
- `TASK-0208` [Next] ✅ **已办（车道 W90A，报告 `build/MilBridge/W90A-report.md` `432cde2f15aa69dc`）**：**加强仪器、不放宽判据** ⇒ **`R_GATE=PASS crit=13/13`**（两趟独立复现）；阈值/三态/豁免/`CRIT_TOTAL=13` **一字未改、`L8` 零新豁免**
- `TASK-0208` 加的两处：`samples/WpfFeatureProbe/FeatureBlocks.cs`（`DropDownClosed` 处**另起一行**补 `EVT capture at=combo.closed captured=…` 直读，`1e8512c0692f350d→2dc0f945b2d87ebb`；**不能**缀到 `combo.closed` 行、**不能**以 `EVT combo.` 开头，否则污染 `c05/c07/c08`）；`r-gate-step.sh`（`c06` 取数换成"**最后一条 `captured=`**"，新增 **`nosrc` 分支＝一条读数都没有仍红**，`f263341ad376d51f→23b6ee91a4a8dc9b`）
- `TASK-0208` **加严的机器证**：新夹具＋**旧**读法 ⇒ `FAIL cases=21 pass=18 fail=3`（S1/S10/S16 因 `L8` 转红）⇒ 新读法必须存在
- `TASK-0208` ⚠️ **主控口径更正**：我原写"`grep -c 'captured=ComboBox'` 应降到合法残留"**不成立**（加打印不可能删行）；实测 **8→8**，`null` 17→19（＋2 条新直读）、`PopupRoot` 仍 0 ⇒ **改为判"`c06` 不再因*读不到*而红"**
- `TASK-0208` ⚠️ **`inputs_fp` 的位移不是本件**（机器证：两件都在覆盖面外，`grep -c 'r-gate-step.sh'`=0、`grep -c 'WpfFeatureProbe'`=0）；窗口内唯一变的覆盖面件是 **`src/WpfGfx.Linux.Native/src/win32_x11.c`（10:23:52）＝车道 W89A（`D-G81`）**，shim 于 10:24:12 重建 ⇒ **重钉请按那件记账**
- `TASK-0208` `NOINFO`：`inputs_fp` 位移的**字节级闭合**（缺 10:20:45 那一刻快照）、真机对照、shim 侧 `GetCapture()` 直读、`c06` 对"捕获粘在 `PopupRoot`"**无直读**（本趟未暴露 ⇒ 零判别力）

## §14 波 `#50` 的 `[Next]` 清单（**一行一条**；2026-09-22 主控补）

- `TASK-9905` [Next] ✅ **已办（`#50` 收尾链闭合；步骤 1–4 车道 W94A，步骤 5–9 车道 W95A，报告 `build/MilBridge/{W94A,W95A}-report.md` `9357566278d1cf7b`／`dc11db1bbb7b8c33`）** —— 速览：门禁 **×2 各 `rc=0`、机读 `6/6 result=PASS`** ｜**冻前 `verify-all` 恰 1 处声明类红**（`COLUMN_FLOOR_ARMLOG=FAIL n_decl=5 n_ok=4 bad= tline` ＋ `SELFREPORT=PASS`；形态逐字命中冻结器 `_is_declaration_class()`）｜**冻结 `#50` = `1f4189c1257737a9`（644,091 B）**｜**冻后 `verify-all` ×2 = `26 ✅ / 0 ❌`、`rc=0`（全绿）**｜**推送** `7feca487…→608d0a170f07fa57`（**69 件逐字节 `ok=69 mismatch=0 nobody=0`**）｜`inputs_fp` `9f2199b2…→f3fb5db8…→`**`ee543f44b1090c74…`**（两步都可逐条归因）｜五臂 `tline 22/2`（两条既有 ❌ 与 `#49` 逐字相同）等逐臂判词、`known-red.json` 重钉（`--check` `FAIL n=2`→`REPIN_GENERATION=PASS`）、`VERIFYALL_SELF=PASS names=26 gen=#50` 见报告。
  - `TASK-9905` ⚠️ **途中修掉一处判据脆弱性（`D-G42` 族，主控裁定"修、不许声明掉"）**：`printf '%s' "$V" | grep -q PAT` 在 `set -o pipefail` 下，**载荷一大**（生产者吃到 SIGPIPE）就把"**命中**"读成 `rc≠0` ⇒ **假 FAIL**。现场共 **9 处**（`build/MilBridge/tools/r-gate-step.sh` **8 处**＋`build/MilBridge/tests/W81AWindowProbe/run-w81a-legs.sh:255` **1 处**；`c11` 正是**承载 `D-G55`** 的那一格 ⇒ 证据一超 **64 KiB 就假红**）。**判据文本一字未动，只换喂法**（`grep -q PAT <<<"$V"`）。
    - 两极化（本缺陷的真证明）：私有副本把 `c11` 载荷撑到 ≈250 KB ⇒ **旧写法 `R_GATE=FAIL crit=12/13`（假红）／新写法 `PASS crit=13/13`**；**阴性对照不放松**（真缺 `seq-combo` 时两版都 `FAIL`）；修后 `R_GATE=PASS crit=13/13`、自测 21/21。
  - `TASK-9905` ⚠️ **`pf` 那一格不是构建身份** —— 见 `D-G92`（四趟逐字相同的整波重建给出四个不同 `pf` sha）。
- `TASK-9906` [Next] ✅ **已办（车道 W95A，报告 §6）** —— `app-local` 副本刷新：**仓内** `STALE=0`／`DIVERGENT=0`（刷 1 份；`UNEXPECTED=6[DECL-GAP-EQ=6]` 是**在册声明类缺口** ⇒ **不许当绿**）｜**仓外** hc 应用目录 `SYNC-APPLOCAL=PASS target=…/HandyControlDemo_Net_GE45/bin/Debug/net10.0 items=5 ok=2 synced=3 drift=0`（每件**拷后回读 sha16 断言**==权威、具名 `mv` 原子改名）｜两本登记册按其自己的口径**删 50 留 1**（现场 **51 条：仍红 1／已转绿 50**，与任务书写的 8/30 不同 —— 整波重建＋波尾刷新已把那 8 条刷绿；保留的那 1 条 = `build/PresentationFramework.Classic.Linux/bin/Debug/PresentationCore.dll` `9465f9dce39e2dfc`，**在册红不许当绿**）。
  - `TASK-9906` ⚠️ **同趟抓出一条只报未修的仪器缺口 = `D-G91`**（刷新器默认 `SCAN_ROOTS` **漏 `$REPO/tools`** ⇒ **刷不到**那份唯一 `STALE`，还会打出 **`STALE=0` 的假绿**；本波按该件自己文档的承诺**显式补根**才刷到 `STALE=1→0`）。**未修**（不在 W95A 写域）⇒ 落地拆新号。
- `TASK-0203` [Next] ✅ **静默 `139` 长跑 —— 已办并收口**〔原文"已办，但只到 🟡"是**当时读数**；**2026-09-23 转 ✅**（车道 W130A 落册）= **测量交付完成**：`139` 族归因已由 `NOINFO` 推到"**异源 ＋ 具名判定点**"、上界 **`2/175 ⇒ 3.55%`**；**产品侧未修 ⇒ `D-G109` 仍红**、处置 = **`TASK-0209`**，终报读数见 **§15p**〕**（车道 W98A，报告 `build/MilBridge/W98A-report.md` `74df2f1a289bcc45`；主控已独立复核：台账 `~/w98a/runs.tsv` **128 行 × 33 列**逐行复算与我一致、`criteria.md` `c2aeeceffae9757e` 先于第一条样本）** —— **到哪一格**：
  - ✅ **精度目标达成**：臂 A（现场权威件 `33352e5797031999`）无 WM 腿 **0/60** ⇒ 单臂 **95% 上界 `4.87% ≤ 5%`**（公式 `1-0.05^(1/60)`）；两臂合并 **1/126 ⇒ `2.35%`**（主判据腿 120 趟口径 = `2.47%` —— ⚠️ 报告 §6.1 用 120、§5.1b 用 126，**分母口径两处不同**，引用时指名）；`void=0`、`oom=0`、`MAXHold_KILL=0`。
  - ✅ **`134` 族两极化干净成立**：腿1 臂 B（修前件 `abf6879c027c5e73`）**59/60 崩**（`rc=134`＋`Stack overflow.`）vs 臂 A **0/60**；崩溃点逐趟一致（第 8 击 `tab3`，`DEAD_AT_S`≈30–32 s）；阳性对照 `PCB 2/2 崩`（6,478,046 B／**19,393 B**）＋ `PCA 0/2` ⇒ 整套读数成立。
  - ❌ **缺哪一格：`139` 族仍 `NOINFO`** —— 唯一 1 次命中 `L1B024` 落在**修前件臂**（真 `139`＋核心转储、**应用自己 0 字节**、7 击全落地后死在 `nav2`、`DEAD_AT_S=28`）⇒ **方向与 `D-G66` 那条改动集一致，但 1 次撑不起归因**（下界仅 ≈0.08%）；两臂各 `0/60` 之外只剩这 1 次。
  - ⚠️ **判据级两个新洞（已登记 `D-G94`／并入 `D-G87`）**：① `clicks_total` 分母把 `CLICK … SKIP dead`（**没点**）算成"点了没落地" ⇒ **那次唯一真 `139` 会被自己的口径判成"无检测力"并剔除**（W98A 第一版就判错了；现行 `tried = ct − skipped` ⇒ `7/7 = 100%`、`detect=yes`）；② `.NET`／`timeout: 被监视的命令已核心转储`（43 B）**不是应用输出** ⇒ 判"应用 0 字节"必须先剔掉它；③ `D-G87` **第三次复核**：61 趟 `134` 里 **14 趟（23%）只写 18–19 KB 折叠形** ⇒ 日志体积不能当判别量。
  - ⚠️ **验收装置第四次反证**：**无一条腿能在两臂上同时有检测力** —— 有 WM 腿（`:96`）**对修前件点击被吞**（`C2B1/C2B2` 逐击 `AE = 348243, 0, 0, 0, 0, 0, 0, 0` ⇒ 落地 `1/8`、`detect=no`）⇒ 那格 `0/2` **不算数**；与 `D-G64`／`D-G84`／`D-G85`／`docs/WAVE49-PREREGISTRATION.md` §13.4-⑦ 同读：**两条腿都要，且每格各自标明"有没有检测力"**。
  - 🆕 **同趟新登记 `D-G93`**（装置缺陷 · 按关键词认对象族）：闸门 `pgrep -af '[v]erify-all\.sh…'` 命中**别家自己的 `bash -c` 轮询命令行** ⇒ **假死锁 300 s**（而槽当时是空的；旧口径 48 min 只走 5 趟／单趟平均等 840 s）⇒ 改用读 `/proc/*/cmdline` 的探测器 ＋ **成对自检 6/6**。
  - ⚠️ 判决力上限与代价：两 shim 差 **25 个导出**（W85A 时 14，`#50` 落地 `A1`/`A2` 后变 25）⇒ **不许归因单一函数**；本机显示与用户现场（`:10` xrdp＋xfwm4）**不同构**；`rc=124` 只说"窗内没死"，**不说"没有该缺陷"**；**再压上界** `≤2% ⇒ N≥149/臂`、`≤1% ⇒ N≥299/臂`（≈3.1 h／6.2 h 每臂）。
  - ⚠️ **下一条车道的建议（W98A §6.5，照抄）**：**别急着平铺 300 趟；先把"`139` 与 `134` 同源"坐实** —— 在修前件臂上把点击密度/时长推到必崩点，用 `gdb`／核心转储抓**原生栈**。
  - `NOINFO`：`139` 归因（1 次）、两 `.so` 25 个导出里**具体哪一处**（未做二分）、有 WM 那格对修前件的**检测力标定**（未做）、用户现场同构复现（未做）。
- `TASK-0304` [Next] ✅ **已办（`#50`，车道 W86A）**：`A1` 新 `src/WpfGfx.Linux.Native/src/win32_pts.c` 导出 PTS 上下文族 **6 入口 ＋ 5 个机读面**，**恒返回 `-10000`（`tserrNotImplemented`）**、出参清空、具名台账 `PTS_GAP entry=… seq=… err=-10000 calls=…`（有界 64 行）；自检导出 `PTS_GAP selfcheck`＝**1（真 stub）/0（假 stub）**；导出 535→546（另被迫改 `build-shim.sh` 的 `SRCS` 一行，已登记）
- `TASK-0305` [Next] ✅ **已办**：PF 注入面＝`build/PresentationFramework.Linux/reapply-patches.py`（每波必重放）⇒ 从上游**逐字复制＋needle 校验**产出 `PtsCache.Linux.cs`(5 处)＋`FlowDocumentView.Linux.cs`(8 处)；毒池项**按对象身份**移除＋具名闩＋`PtsUnavailableException`；**`Invariant.Assert` 一个没删**
- `TASK-0306` [Next] ✅ **已办（`A3` 同趟做了）**：第 24 项「流文档」⇒ **`alive=yes`、`rc=143`（仪器自发的 SIGTERM ⇒ 进程从没死）、`fatal=0`**，**页级可见**：洋红占位 **54,454 px**（真拍图：洋红矩形＋黑边＋"此页不支持…NOT SUPPORTED…entry=CreateInstalledObjectsInfo err=-10000"）＋台账 `PTS_GAP … seq=1 err=-10000`＋`[PTS-UNAVAILABLE] site=FlowDocumentView.DocumentPage`；第 23 项同样可见降级（49,864 px）。**修前同一点击 = `rc=134`**
  - `TASK-0306` ⚠️ **判据口径修正（主控采纳车道建议）**：任务书指定的 `N2`（stub 返回成功）**没变红且绿得对**（链上下一个真缺口 `LoCreateContext` 仍缺 ⇒ 闩照样立、占位照样画）⇒ **改用 `N2-b`（A3 只降级不画）**：`alive=yes`、具名行照打，但 **`magenta=0`** ⇒ "**不许把空白读成绿**"这条牙实测咬住
  - `TASK-0306` ⚠️ 另两条读数：**`N2-c`（只 A2 不 A3）** ⇒ 不再 `FailFast` 但 **`guard=7909` 重试风暴**、页面量不出内容 ⇒ **只看 `alive` 的判据会误判**；**`N2-a2`（假 stub＋撤 A2/A3）** ⇒ `rc=134`，死在**新的**死点 `FontFamily.get_FirstFontFamily`
  - `TASK-0306` ⚠️ **它推翻两处**：① `W78A` §3.4"假 stub 必然静默半通"**在今天这代树上不成立**；② `W78A` 说终止形态是 `PtsHost.Context` 断言 ⇒ 实测是**毒池项半初始化向下游扩散**、死在 `ComputePageMargin → FontFamily.FirstFontFamily`。**假判据警告**：台账若被伪造成 `err=0`，**只 grep `PTS_GAP` 的判据会被骗** ⇒ 只认托管侧带非零 `err` 那条
  - `TASK-0306` 零回归：正常页 `BrushDemo` `compare -metric AE = 0`；失败后再点 0/9/10/16 全部 `alive=yes`；`check-appliers.sh miss=0 red=0`；`artifact-src-fp` ⇒ PC/WB `state=ok`、**PF `state=stale kind=src`**（反向证明只动 PF 侧）；`hbtextline`/`pc` 未碰
  - `TASK-0306` ⚠️ **覆盖面缺口（要收尾链处置）**：`reapply-patches.py` 与 PF 的 `*.Linux.cs` **不在** `fp_inputs()` 覆盖面内 ⇒ A2/A3 那半个改动对 `inputs_fp` **不可见**（只有 `ARTIFACT-SRC-FP` 看得见）
- `TASK-0205` [Next] ✅ **已办（车道 W89A，报告 `build/MilBridge/W89A-report.md` `675779b2fc2c30ee`）**：**假设被两台独立仪器证实**（新探针逐字读 `Window.WindowState`：外部最大化后 `state=Normal ws_max=0`；真 hc `[GEO]`：`ButtonMax vis=True`；shim `WPF_LINUX_WINSTATE_DIAG=1`：`read_ok=1 x_maximized=1 | 缓存 maximized=0`）
  - `TASK-0205` 修法：**只动 `src/WpfGfx.Linux.Native/src/win32_x11.c`**（5 hunk，`+238/-2`：权威状态读取＋**幂等采纳**＋一站入口；`ConfigureNotify` **先采纳再算 `WM_SIZE` 的 wParam**；**新增 `case PropertyNotify`**；两处诊断）⇒ 新 `win32shim = 33352e5797031999`
  - `TASK-0205` 三臂：**外部 ⇒ 双击还原 13/13**｜**外部 ⇒ 自带还原按钮：窗态 15/15**（几何同刻 **13/15**）｜**反极性**（源逐字节复原 ⇒ shim 回 `24e906c194903c8b`）⇒ **双击 3/3＋按钮 3/3 全还原不了**、往返闭合｜对照臂（应用自发）`M1×R1 8/8`、`M2×R2 13/13`、`N1 1/1` 未改坏
  - `TASK-0205` 零回归：`0104` 四入口＋`N1` = **26/26**；`0106` 四格 **PASS**（`667 by 500`／`521 by 417`／缺席／`reg58`=0）；⚠️ 仓内 `run-w81a-legs.sh` 报过一次**假 NOINFO**（探针 stdout 块缓冲），它用 `stdbuf -oL`＋自读 `xprop` 补上
  - `TASK-0205` ⚠️ 它**推翻自己判据里一条断言**："`WS_MAXIMIZE` 守卫是堵点" —— 半修 **H1**（只同步 `w->maximized`＋派发 `WM_SIZE`、不同步 style）**两腿都绿**；**H2**（只同步 style）**全红** ⇒ 必要充分的是 `w->maximized`＋告诉托管侧
  - `TASK-0205` 🆕 **新待查项（未压绿）**：自带还原按钮那 2 趟（`F-btn3/F-btn4`）**窗态已回 `Normal` 但几何卡在 `1280x1024@+0+0`**（多等 4.5 s 仍未收回）；W77A 在应用自发那条路的**修前**读数里就有同形 ⇒ 已登记为独立待查项
- `TASK-0107` [Next] ✅ **已办（`#50` 波尾，车道 W93A，报告 `build/MilBridge/W93A-report.md`；**主控独立复核**：报告 sha 一致、仓内只这一个文件被动过）** —— `D-G83` 后续 `H2`，**两个问题都有读数**：
  - **`H2-a` 答：运行期不跟随。** 三窗一台、14 个 stage、两条腿（裸 `Xvfb :181`／`Xvfb :182`＋`xfwm4`）**判据输入列逐格相同** ⇒ `SUMMARY A1_informative=29 PASS=5 FAIL=4 VACUOUS=20`，**4 个 `FAIL` 全是运行期改动格**（`W1-TIGHTEN`／`W2-DECLARE`／`W2-TIGHTEN`／`W3-DECLARE`）；X 侧恒停 `667 by 500`。**正对照证明通道没坏**：`W2-TOGGLE` 一按（**全仓唯一**运行期触发器 = `ShowWindow` 内 `win32_core.c:1074`）即正确落 `521 by 417` ⇒ **缺的不是值，是触发器**。最值钱一格 `W2-DECLARE`：应用**自己**缩窗 `625x521→521x417`，而 X 侧**连 `maximum size` 都没有**。
  - **`H2-b` 答：本机有 WM（私有 `Xvfb :182`＋`xfwm4`），约束真生效。** 现场证据 = `_NET_SUPPORTING_WM_CHECK window id # 0x4000ae` ＋ `_NET_SUPPORTED n=75` ＋ **重定父**（`parent≠root`；用户会话 `:10` **只读未碰**）；客户请求 `1000x800` → **`667x500`**、`300x200` → **`521x417`**；拖边框：**对照窗** `667x500→937x692`（判别力自证）、**受限窗纹丝不动**。裸 `Xvfb` 臂一律照做（提示只是建议）⇒ **WM 严格执行的是一份过期约束**（`W3` 声明 450 却被放任到 `1000x800`）。
  - `TASK-0107` ⚠️ **反极性 = `VACUOUS`**（按**先写死**的口径，如实报）：`W1` 的 X 侧提示在 14 个 stage 里**一次都没移动过** ⇒ "回到旧值"与"从来没跟过"**不可分** ⇒ **不构成反极性证据，不许当绿**。
  - `TASK-0107` ⚠️ **上限 `3`（`WPF_HINTS_REASK_MAX`）的两种吞法都取到读数**：①"已声明终态"型（`W1` 首次问出声明 ⇒ `hints_map_declared=1` **死锁**）；②"预算耗尽"型（`W3` 被 4 次无意义 `HIDE/SHOW` 花光 ⇒ **第一次真声明也永久发不出**）。钩子 `W1[shim=0] W2[shim=1] W3[shim=2]` 与 `diag_aftermap=6` 加法一致。
  - `TASK-0107` 🆕 **同趟新登记 `D-G88`／`D-G89`／`D-G90`**；**落地拆新号** = `TASK-0108`／`TASK-0703`（波 `#51`）。本件**零产品改动**（探针在仓外）。
- `TASK-0108` [Next] ✅ **`H2` 落地：让"运行期改尺寸提示"到得了 X**（`D-G88`，对策 = W93A 报告 §5 的 `P1`–`P4`，波 `#51`）：
  - `P1`（必做，`src/WpfGfx.Linux.Native/src/win32_core.c`）把"**终态 ＋ 次数上限**"换成"**缓存上次已发布值，值变了才 `XSetWMNormalHints`**" —— 幂等、无消息风暴，**删掉两个停止条件**（`hints_map_declared` 终态与 `hints_map_asks<3`）。
  - `P2`（必做，**这就是"运行期改"的触发器**）在 `SetWindowPos`/`MoveWindow` 的尺寸**真变**路径上补一拍 ⇒ 改**紧**必到。
  - `P3`（**需主控裁定**）改**大**那半**无触发器可打** ⇒ 需**托管侧通知**；`P3-a`（shim `OverrideMetadata` 合法性）**未验** ⇒ 落地前先建**最小探针**。⚠️ **不推荐**只把上限 `3` 改大 —— 它计"**问**"不计"**改**"，改大只是延后死锁。
  - `P4`（必须与 `P1` 同趟）**重入闸** ＋ 新判据"**X 调用次数 == 值变化次数**"（不风暴的证据）。
  - ⚠️ 反极性**必须重造**（本轮的 `VACUOUS` 不算）：`改紧 → 提示跟到新值 → 撤回 → 提示跟回旧值`；装置已就绪（W93A 的 `W1/W2/W3` 三窗一台 ＋ `xprop` 判据 ＋ `judge.py`）。
  - ✅ **`TASK-0108` 收口（车道 W101A ＋ W106A；**主控独立复核**；本行状态位 `🔴` → `✅` 由车道 W109A 于 2026-09-22 **行锚定**改，改后 `wc -l` 仍 `452` ⇒ 未吞下一行）** —— `P1`／`P2`／`P4` 由 W101A 落地，**`P3`（托管侧通知）由 W106A 落地**（报告 `build/MilBridge/W106A-report.md`，提交版口径 `head -n -2 本文件 | sha256sum | cut -c1-16` = `6558bba440cce6a3`）。
    - **四格全绿 ＋ 两腿逐字相同**：`SUMMARY A1_informative=29 PASS=8 FAIL=0 VACUOUS=21`（W101A 修到 `PASS=8 FAIL=2`；`W3-DECLARE` 与 `A3 W1-REVERT` 两格由 `P3` 转绿：`469x365`／`667 by 500` 逐字相符）—— **两条腿（裸 `Xvfb`／`Xvfb`＋`xfwm4`）判据输出逐字相同**。
    - **零回归**：`D-G83` 四格在新件上全 `PASS`（`declared ⇒ 667 by 500`／`minonly ⇒ 521 by 417`／`undeclared ⇒ 缺席`／`reg58 ⇒ 0`，`W89A_0106 VERDICT=PASS`）；`DefWindowProcW` 的 `WM_GETMINMAXINFO` no-op **一字未动**；本件**只插入**（零删守卫/断言）。
    - **反极性双向逐位**：逐字节复原 ⇒ `win32shim` 逐位回 `2a297d6fee8be389`、`pf` 逐位回 `f34bc297d19778fd`、两格回 `FAIL`（`PASS=8 FAIL=2 VACUOUS=19`，与 W101A 同）；放回修后源 ⇒ 逐位回 **`8392fc09564779a1`**（327,248 B）／**`215c856cbca9922b`**（6,123,520 B）。
    - **`P3` 的挂点与通道（都有机械证据）**：挂点 = 上游**本来就有**的 4 个 DP 回调末端（`OnMin/Max{Width,Height}Changed`），**不是**给每个 `Window` 入册 —— 探针 `H-1`…`H-4` **先过了才动产品**（`HOOK_META both=1`、**调高与调低两向**都进回调且 `hwnd=0x200003`、`msgsSeen=2`）。通道**没有新造 `P/Invoke`**：`PresentationFramework.dll` **没有** `DllImportResolver`（机械证据 `grep -c SetDllImportResolver`：**PF=0** vs WindowsBase/PC/UIAutomationTypes 各 1）⇒ 走 PF 已在用的、**声明在 WindowsBase** 的 `SendMessage` 发私有消息 `WM_APP+0x7F00`，shim 在 `wpf_dispatch_to_window` 拦下并转调**同一个** `wpf_hints_publish`（复用 `P1` 缓存 ＋ `P4` 重入闸 ⇒ **无第二套发布路径**）。
    - ⚠️ **残留边界（逐字，引用者不许改口径）**：**"窗口还没有 HWND（`IsSourceWindowNull`）时改 `Min/MaxWidth/Height` ⇒ 本件不发告示。"** ⇒ W101A 原边界**收窄**为"**尚无 HWND 时**"；**有 HWND 之后，调高与调低两向都即时到 X**（两腿实测）。
    - ⚠️ **两处 `PASS→VACUOUS` 如实记（不是回归）**：`W1-TOGGLE`／`W3-TOGGLE2` —— 信息**前移**到声明那一拍（`judge.py` 口径"期望与上一 stage 相同**且** X 侧实际也没变 ⇒ 本格无信息"）；`W2-TOGGLE` 沿用 W101A 口径仍 `VACUOUS`。**不许**读成回归、也**不许**改判成 `PASS`。
    - ⚠️ **仍红的诚实项**：幂等 `I1` 在 `W3` 由 `2/2/0` 变 **`3/2/1`（红，如实报）**，相邻同值那一次的**精确机制记 `NOINFO`**（直接原因之一是 `D-G90` 的 40 行截断把该趟发布决定行截掉）；同装置 `w3one`（只改一个 DP ＋ 2 次 `HIDE/SHOW`）`blocks=2 reps=0` ⇒ **幂等路径本身是好的**。
    - **登记侧**：新 applier 的登记已由**主控**落两处（`build/integration-wave.sh` 的 `APPLIERS_EXPLICIT+=( patch-presentationframework-window-minmax-notify )` ＋ `build/MilBridge/tools/applier-audit-expected.txt`）⇒ 主控现场审计 **`APPLIER_AUDIT_SUMMARY appliers=28 ok=95 miss=0 red=0 rc=0`**（登记前 `27/92`）。
    - ⚠️ **未跑项（`NOINFO`）**：`0104` 四入口 **26 腿**（装置在别人车道的 `~/w89a/bin/**`，≈30 min）**没跑**；W106A 自报"**它是收尾链的第一优先**"（`P2`/`P4` 正落在最大化/还原与重入那条路上）。
- `TASK-0109` [Next] 🔴 **产品侧 `wpf_x11_has_ewmh_wm()` 的残留边界：`WM` 已死而 EWMH 属性残留时，可能**静默丢一次移动**（来源 = W102A 报告 §8.5 记的 `NOINFO`；与 `D-G88`／`H2` 相邻但**不同因**）：
  - 判定点：`src/WpfGfx.Linux.Native/src/win32_x11.c` 的 `:1659 wpf_x11_has_ewmh_wm()`（`_NET_SUPPORTING_WM_CHECK` 的 intern 在 `:198`）＋ `:1780 wpf_x11_moveresize()`；声明在 `src/WpfGfx.Linux.Native/src/win32_internal.h:590`。
  - 现象与推因（**未实测产品面**）：`has_ewmh_wm()` 用的是**真** `XGetWindowProperty`（**不是**恒真谓词 ⇒ **不属 `D-G89` 族**），但它**只查"属性在不在"，不查"那个窗还在不在"**；而既有留档已证 **WM 死后 EWMH 属性会残留**（`build/MilBridge/W54A-report.md` §0.4(1) 逐字 `WMPROOF_AFTER: … window id # 0x2000ae  xfwm4_alive=no`；同一现象另见 `~/w53a/logs/WFP3-wm-killwm/report.txt:9`）⇒ `wpf_x11_moveresize()` 在"**WM 已死但属性残留**"时会**走 EWMH 分支**（`XSendEvent` 给 root，无人处理）而**不走兜底 `XMoveResizeWindow`** ⇒ **可能静默丢一次移动**。
  - 要建的场景（**判据先写**）：起 WM ⇒ 用 `TASK-0703` 的真判据确认三条件在场 ⇒ **杀 WM 但保留属性** ⇒ 请求一次移动/改尺寸 ⇒ 期望 = **兜底路径生效（窗口真的动了）**或**大声失败**；**取不到读数 ⇒ `NOINFO`**（既不算绿也不算红，不许猜）。
  - 边界：本行**只立号，未建探针**（W102A 因"跑应用"违其纪律未测 ⇒ `NOINFO`）。
- `TASK-0110` [Next] 🟡 **几何还原残留：查"WM 为什么不把退出最大化的几何收回去"**（`D-G98` 的落地；来源 = 车道 W105A 报告 §4.2／§9.1 的 26 腿零回归复核 ＋ W89A §5.3 的首次登记）：
  - 现象（**判据要能抓 frame/client 时序分离**）：`_NET_WM_STATE` 里两个 `MAXIMIZED_*` **已经掉了**（窗态还原确已发生），而 **client 几何**与 **WM 的 frame 几何**（`fgeom`）**双双卡在 `1280x1024@+0+0`**；现行的两拍（`AFTER_R2`／`AFTER_R2_SETTLED`）**逐字同形** ⇒ **两拍不够** —— 新判据必须在**还原那一瞬加中间拍**（逐拍读 ① `_NET_WM_STATE` ② client 几何 ③ `xwininfo -frame` 的 frame 几何 ④ `_NET_FRAME_EXTENTS`），把"**先掉状态、几何滞后**"与"**状态掉了、几何再不动**"两件事**分开**。
  - 比例与排除（**已由 W105A 做完，本行只引用、不重跑**）：当代 **新件 `3/36` vs 旧冻结件（**无 `P2`**）`2/36`、Fisher 双尾 `p = 1.000`** ⇒ **不是本波引入**；外部只读观测器在**旧件**那趟（`W105A-C2-p09-old`）记录到 X 侧提示**全程是常量** `program specified minimum size: 1 by 1`（**没有任何 `maximum size`**）⇒ **排除**"`P2` 写提示把窗口卡住"。
  - **要查的那一层**（**本行不许猜**）：**WM 侧**为什么没执行"退出最大化的几何还原"。三个候选，**每个都要先写"怎么证伪"**：① 应用发出的还原请求里**缺了让 WM 重算几何的那一拍**（`WM_STATE`／`_NET_WM_STATE` REMOVE／`WM_NORMAL_HINTS` 的次序）；② **client 与 frame 的尺寸协商顺序**（`ConfigureRequest` 与 `ConfigureNotify` 的先后、`_NET_FRAME_EXTENTS` 是否陈旧）；③ **WM 内部状态机**与应用窗的 `_NET_WM_STATE` **不同步**（`xfwm4` 的 `maximized` 标志）。
  - 判据（**先写**）：**同一趟**里同时取上面 ①–④ ＋ 外部观测器时间线，**每 ~0.1 s 一拍**；**红** = "`_NET_WM_STATE` 不含 `MAXIMIZED_*` **且** client 与 frame 几何**都 ≠ 基准**"**连续 ≥ N 拍**（`N` 在取读数**之前**写死）；**反极性** = 修法拆掉后必须回到**同形**；**取不到分层读数 ⇒ `NOINFO`**（既不算绿也不算红）。
  - 边界（**不许放宽**）：分母口径照 `D-G94`（把"**没点**"与"**点击被吞**"分开，`m_ok`／`r_ok` **并列报**）；"**两臂速率差是否显著**"要**每臂数百趟**才判得动 ⇒ 本行**不**承诺在几十趟里给出显著性结论。
  - 🟡 **收口（车道 W116A，2026-09-22 第九笔；**只追加，上文一字未动**）—— 本行**未**转 ✅**：真因**部分定位／部分证伪**、缺陷**仍红**、新首选嫌疑**正在验** ⇒ 状态位 `🔴 → 🟡`。逐条：
    - **① 定位到行（来源 = `W112A` §6.1，已独立立号 = `D-G100`）**：链条 = 还原那一拍的 `SetWindowPos(0x237 = NOSIZE|NOMOVE|NOZORDER|NOACTIVATE|FRAMECHANGED|NOOWNERZORDER)` 把**窗口表缓存**值**无条件**落成一次 X 几何写（修前源 `win32_core.c:1210`，本件用 `git show HEAD:<path>` 现场复核）。
    - **② 部分证伪（来源 = `W114A` §5.2／§5.3；两条独立读数）**：把那次写**彻底删掉**之后那族**照样红** —— 承重的**确定性**判据（来自 `SetWindowPos` 帧的 X 几何写条数）**6 → 1**（38/38 腿 → 16/16 腿，**命中**），可红率**无位移**（修前 17 腿 1 红 5.9% → 修后 16 腿 1 红 6.2%，Fisher 双尾 `p = 1.00`）；且红腿 `W114A-F-07` **全趟只有 1 条** `XMoveResizeWindow`（启动那次真带尺寸的）**照样被打回** ⇒ 那次写是**后果/读数**、**连必要条件都不是**。**`W112A` §6.1／§6.5 的最后一跳就此作废**（`D-G98` 条已同趟追加两条证伪 bullet）。
    - **③ 新首选嫌疑（属 `NOINFO`；**正在验**）**：红绿两态在 X 事件层与 shim 诊断层**逐字同形**、差别**只在时序**；唯一在"被打回"之前**必发**、且纯 X 装置 `xmimic` **不会发**的非几何请求 = 还原那一拍 `SWP_FRAMECHANGED` 顺手重写的 **`_MOTIF_WM_HINTS`**（值"幂等"、**X 流量不幂等**）⇒ **正在由车道 W115A 做纯 X 高功效探针（每臂 ≥200 趟）钉"必要性"**；本行进 `TASK-0111`。
    - **④ 缺哪一格（本行不转 ✅ 的机械理由）**：缺"**被打回的那条客户端请求到底是哪一条**"（`D-G98` 的 `NOINFO` 第 1 条，**本件写成时仍无答案**）＋ 缺"**≥40 腿/臂**的成对读数"（6% 红率下 16 腿判不出，`D-G99` 的口径） —— **两格都还没有**。
    - **⑤ 世代位（波 `#52` 前半段）**：`win32shim 8392fc09564779a1 → bd037229be8db4f6`（`F1`＋`F2`，**独立卫生修**，**不修 `D-G98`**；导出仍 **547**）；**零回归** = `D-G83` 四格全绿 ＋ `R-GATE=PASS crit=13/13`；**反极性源级＋件级双向闭合**（复原 ⇒ `8392fc09564779a1`；重放补丁 ⇒ `bd037229be8db4f6`）。出处 = `build/MilBridge/W114A-report.md`（口径 `grep -v '^<!-- SHA16'` = `253b935c5415c841`）／`docs/WAVE52-PREREGISTRATION.md`（`834e370053f7ef2b`）／登记件 = `build/MilBridge/W116A-report.md`。
- `TASK-0111` [Next] 🔴 **`_MOTIF_WM_HINTS` 那一跳的落地**（`D-G98` 的**首选嫌疑**；来源 = `W114A` §8 第 1 条 ＋ §8b 的 `N1`）：
  - **修法方向**：让 `wpf_x11_set_decorations`（`src/WpfGfx.Linux.Native/src/win32_x11.c`）**值没变就不写** `_MOTIF_WM_HINTS`（现状 = 运行期每个带 `SWP_FRAMECHANGED` 的 `SetWindowPos` **都会重写一次**：`win32_core.c` 盘上修后态 `:1167-1178` ⇒ 值"幂等"、**X 流量不幂等**）。
  - **⚠️ 先决条件（逐字）**：**待 W115A** —— 本件写成时 `build/MilBridge/W115A-report.md` **不存在**（现场 `ls` `rc=2`）；它正在做**纯 X 高功效探针**（每臂 **≥200 趟**）钉"**这次属性重写是不是"被打回"的必要条件**"。**本行不替它下结论**。
  - **分支 A（W115A 判"必要性成立"）**：落地"**值没变就不写该属性**"＋ **反极性**（拆掉 ⇒ 必须回到同形）＋ **零回归**（`D-G83` 四格／`R-GATE crit=13/13`／权威件导出数不变）＋ **成对读数 ≥40 腿/臂**（6% 红率下 16 腿判不出，见 `D-G99`）。
  - **分支 B（W115A 判"不成立"）**：**撤号**，或按现场读数改写为"**剩余候选**"（**不许**把红写成绿、**不许**为了保号而放宽判据）。
- `TASK-0703` [Next] ✅ **修掉"等 WM 起来"的恒真判定**（`D-G89` 的落地，波 `#51`）：把 `xprop -root _NET_SUPPORTING_WM_CHECK | grep -q window` 换成**真判据** —— `xprop -root _NET_SUPPORTING_WM_CHECK` 必须解析出**窗口 id**（如 `grep -q 'window id #'`）且 `xprop -id <id> _NET_WM_NAME` 可读，或直接判 `_NET_SUPPORTED` **非空** ＋ **重定父**；并**盘点**全仓同类写法（`grep -rn '_NET_SUPPORTING_WM_CHECK'` 逐处列出，已知既有实例 `build/MilBridge/W53A/cell3.sh:26`）。⚠️ 现状**方向安全但会骗人**：等待第一次就 `break` ⇒ 自证行可能打"WM 不在"而 WM 其实在场（**假阴性**）。
  - `TASK-0703` 🆕 **装置侧已由车道 W102A 交件（本行状态位 `🔴` 未改，见末条）** —— 真判据工具 = `build/MilBridge/tools/wm-awaited.sh`（**`57a852f6948e1c67`**，`20,399 B`，`--selftest` **11/11 PASS `rc=0`**）；判据先写于 `~/w102a/criteria.md`（`f0cc9ca03fd610aa`）= 三条件**全要**（① 能解析出窗口 id 且 ≠`0x0`；② 该 id **此刻在树里**（`xwininfo -id` 成功）∧ `_NET_WM_NAME`／`WM_CLASS` 可读非空；③ `_NET_SUPPORTED` 非空 —— **两种形状都认**，真 `xfwm4` 打的是**原子名**；`C4 重定父`**默认只报不判**，因为该等待发生在**应用起窗之前**）；`--wait N` **每一拍**重跑三条件。
  - `TASK-0703` ✅ **两极化三条腿都成立**（W102A 报告 §4，证据 `~/w102a/logs/legs-20260922-191931/`）：无 WM 腿 —— 旧谓词 **`rc=0`（恒真，`pipefail` 也拦不住）** vs 新判据 **`FAIL rc=1`**（`c1=no c2=no c3=no`；`--wait 4` **用满预算** `elapsed_s=4.12 attempts=13`）｜有 WM 腿 —— **`PASS rc=0`**（`id=0x4000ae`／`_NET_SUPPORTED n=78`／`xclock` 被重定父 `c4=1`，三条**独立**读数）｜时序腿 —— 同一条命令 `FAIL 4.12 s → PASS 0.58 s`（原子独立计时 `0.27 s` 出现）⇒ 证"**等**"不是"立刻放行"。`~/w53a/cell3.sh:26` **已修**（`06c6d17fa9906761 → a358f6fd38b3b387`，只换那一行，预算等价 `40×0.25 s = --wait 10`；段级两极化 `CASE_A_RC=6`／`CASE_B_RC=0`）。
  - `TASK-0703` ⚠️ **`wm-awaited.sh` 「未接线」**（W102A §11.6 自报）：它**未**进 `verify-all`／任何门禁，也**未**进 `fp_inputs()` 覆盖面（`close-wave.sh` 不在 W102A 写域；机械核：覆盖面 **147 件**里 `grep wm-awaited` **0 命中**）。⚠️ **若主控把它接进任何在仓调用方，按仓内纪律必须同趟把它纳入 `fp_inputs()` 覆盖面**（"判据改了自己没人看着"同族欠账，与 `TASK-9907` 的接线口径同源）。
  - `TASK-0703` 🆕 **同族新实例（只报未修）⇒ 已登记 `D-G95` ＋ 拆号 `TASK-0704`**：仓外还有 **4 处**同类恒真谓词 —— `~/w53a/cell.sh:26`／`~/w53a/cell2.sh:26`／`~/w76a/bin/ab.sh:26`／`~/w63a/bin/wm-leg.sh:19`；**最后一处是"反向恒假"新形态**（同一个谓词用在 `if !` 上 ⇒ **起 WM 的分支永远进不去** ⇒ 那一趟自称"WM 腿"却**跑在无 WM 上**）。
  - `TASK-0703` ⚠️ **路径笔误更正（车道 W104A，2026-09-22）**：本行正文里那个"既有实例 `build/MilBridge/W53A/cell3.sh:26`"中的 **`build/MilBridge/W53A/` 仓内不存在**（`ls -d` 报"没有那个文件或目录"、`rc=2`；fork 克隆 `git ls-files | grep -i W53A` **只有 `build/MilBridge/W53A-report.md`**）⇒ **真身 = 仓外 `~/w53a/cell3.sh:26`**（`#50` 冻后由 W102A 修为 `a358f6fd38b3b387`）。本行**其余判词一字未动**（加注不覆盖）。
- `TASK-0704` [Next] ✅ **修仓外 4 处同类"等 WM 起来"恒真谓词 ＋ 复核被污染臂的结论**（`D-G89`／`D-G95` 的落地；**进行中（车道 W103A）**）：
  - 判定点（4 处，**全在仓外**）：`~/w53a/cell.sh:26`｜`~/w53a/cell2.sh:26`｜`~/w76a/bin/ab.sh:26`（这三处与已修的 `cell3.sh` 原第 26 行**逐字相同**）｜`~/w63a/bin/wm-leg.sh:19`（**`if !` 形态 = 反向恒假**，即 `D-G95`）。
  - 修法形状（照 `D-G77` 这个**已修样板**／`TASK-0703`）：**先验 → 起不来就非零退出 ＋ 逐条打读数**，或最小改 `grep -q 'window id #'`；**不许**静默放行，**不许**为了让某条腿变绿而放宽判据。
  - ⚠️ **附加任务（不许省）**：`~/w63a/bin/wm-leg.sh` 那趟自称"WM 腿"的运行（`~/w63a/logs/wm.progress:1`，`2026-09-21 11:35:25`）**实际跑在无 WM 上** ⇒ 必须**复核它的判词是否已影响任何已登记结论**；若影响，相关结论按"无 WM 口径"**重取或降级为 `NOINFO`**（W102A §11.2 记：它**未**重跑/未重判那一趟的臂）。
  - 边界：**仓内补不出牙**（装置在仓外 ⇒ 同 `D-G93` 的边界）；落地后"在册结论要不要重取"由主控裁定。`NOINFO`：那 4 处改完后**是否还有同类写法**未逐处枚举。
  - ✅ **`TASK-0704` 收口（车道 W107A，2026-09-22；**只追加，上文一字未动**）** —— 车道 **W103A** 已交件（报告 `build/MilBridge/W103A-report.md` `d92f0ede166268a7`）：
    - **4 处全修好**，逐件 before → after sha16（**本车道现场重算，与 W103A 报告逐字相同**）：`~/w53a/cell.sh` `9c4f8e5ac6450f3d → e1301e3b274d6dec`｜`~/w53a/cell2.sh` `c370b9ca5b8151bb → 208a674183825d23`｜`~/w76a/bin/ab.sh` `73cbe4eec668abe6 → 3ce92b2d8806e3d7`｜`~/w63a/bin/wm-leg.sh` `f556c065aa635d53 → aec91a0827bd9cfa`；旧谓词原文**只作注释留档** ⇒ **可执行代码里 `grep -q window` 命中 4 件全 0**（现场重算）；四处权限 `711` 保持、`bash -n` 全 OK。
    - **两极化各成立**（私有 `Xvfb :188`，**无 WM**）：修前形态 **`rc=0`＋`elapsed_s=0.01/0.02/0.03/0.02`**（第一次迭代就 `break`；`wm-leg.sh` 那处**分支没进**＝沙箱 `xfwm197.pid` 0 命中）vs 修后形态 **`rc=6`＋用满 `10.05/10.17/10.32 s`＋`WM_AWAITED=FAIL reason=wm-not-ready`**；**真代码自己把 WM 起起来**那条腿 ⇒ `rc=0`、`2.7–2.8 s`、`WM_LEG_START`（**分支进了**）→ `WM_AWAITED=PASS`，另有**独立证据**（`id=0x2000ae`／`_NET_SUPPORTED n=78`／`xclock` 被**重定父** `c4=yes`）。
    - **被污染臂的结论复核 = 12/12 逐条做过、0 条受影响**（W103A §4.2；详见本次册内 `D-G95` 的收口 bullet）⇒ **不需要**按无 WM 口径重取、**不需要**降级 `NOINFO`。
    - **本车道据此把本行状态位 `🔴` → `✅`**（判据 = ① 四处现场重算 sha16 与报告**逐字一致** ② 两极化有读数 ③ 复核有结论；三条全满足）。
    - ⚠️ **本行**不**覆盖的尾巴（如实记，未隐藏）**：`~/w63a/bin/wm-leg198.sh:17` 的**同族第三种形态**（`case "$wm" in *window*)` 恒真守卫）**仍在**（本车道全域重盘新发现，见 `TASK-0703` 行与册内 `D-G89`）；`~/w63a/bin/wm-leg.sh:13` 的"重跑即截断自己的证据"**未修**（新登记 `D-G96`）；四处**未端到端跑真脚本**（W103A §7 的硬理由 = 避免毁证）。
  - 🟡 **`TASK-0703` 收口（车道 W107A，2026-09-22；**只追加，上文一字未动**）** —— 状态位 `🔴` 改为 **🟡**（**不是 ✅**），依据 = 本行正文要求的"**盘点全仓同类写法**"那一半**已于本次做完，且盘点有真命中**：
    - **重盘命令 ＋ 计数**（判据先写于 `~/w107a/criteria.md` `d06b1e48ec062ca1` §5；仪器 `~/w107a/resurvey.sh`／`resurvey2.sh`，原始输出 `~/w107a/resurvey.txt`）：根 = `$R` ＋ `$HOME`（排除 fork 克隆以免双算），扫 `*.sh`/`*.bash`/`*.py`/`*.pl`，排除 `/logs/`、`/arm-logs/`、`/upstream/`、`/.git/`、`/bin/Debug|Release/`、`/obj/`、`/gen/`、`site-packages`；**注释命中与可执行命中分开计**。主机件 **2215**（仓内 152／仓外 2063）。
      - `P-A`（恒真谓词本体字面形态 = **裸 `window`** 作匹配词，**不含** `window id #`）：命中 **20** = **可执行 7** ＋ 注释 13。
      - `P-B`（受查对象 `_NET_SUPPORTING_WM_CHECK`）：**82** = 可执行 61 ＋ 注释 21。
      - `P-C`（反向恒假 = `P-A` 形态与 `P-B` 同处一个 `if !` 分支）：**0**。
    - 🔴 **`P-A` 可执行 7 处里有 1 处是"活的"**（**本次新发现**）：`~/w63a/bin/wm-leg198.sh:17` 逐字 `case "$wm" in *window*) : ;; *) say "NOINFO wm-absent（WM 腿的前提不成立）"; exit 9 ;; esac` —— `wm` 取自 `:15` 的 `xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | head -1`；**无 WM 时**它输出失败文案 `…no such atom on any window. `，其中的 `window` 被 **glob `*window*`** 命中 ⇒ 走 `:`（什么都不做）⇒ **"前提不成立"守卫永远不触发**。⚠️ **这是同族的第三种形态**：W102A／W103A 的盘点口径是 `grep -q window`（**按 `grep` 认对象**）⇒ 对 `case` glob **机械上不可见**（与 `D-G84`／`D-G93` 的"按关键词认对象"同族）⇒ 因此 W102A 记的"**仓外 5 处**"这个数字，在**另算形态**后应为 **6 处**。
    - 其余 6 处**逐处核实为非"活的等 WM 判据"**：`…/tools/wm-awaited.sh:316`（该工具 `--selftest` 的 **S2 负例 fixture**，故意在失败文案上跑旧谓词并断言 `rc=0`）｜`~/w102a/old-predicate.sh:17/21/27`（W102A 的**只读旧谓词读数器**）｜`~/w103a/legs.sh:114`（W103A baseline 腿**负控读数行**）｜`~/w107a/resurvey.sh:63`（**本重盘仪器自指**）。**仓内（`$R`）可执行的"活的"恒真 WM 判据 = 0 处**（与 W102A §8 一致）。
    - **本车道据此判定 = 🟡**（先写判据第 1 条"`P-A` 可执行命中必须为 0"**未满足**，且原因是**真命中**而不是伪命中）。⚠️ **未修那一处**：它在 `~/w63a/bin/**`，**不在本车道写域** ⇒ **只报不动**；修它 = 把 `*window*` 换成 `*"window id #"*` 或直接改调用 `wm-awaited.sh`（**建议并入 `TASK-0704` 的收尾或另立一条**）。
    - 其余未变：装置侧交件（`wm-awaited.sh` `57a852f6948e1c67`、两极化三条腿）＋ `~/w53a/cell3.sh:26` 已修如上文；**未接线**（`wm-awaited.sh` 仍未进 `verify-all`／`fp_inputs()` 覆盖面）这一条**仍然挂着**（接线归波 `#51`）。
  - `TASK-0704` ✅ **尾巴收口（车道 W113A，2026-09-22；只追加，上文一字未动）**：本行"不覆盖的尾巴"里那条 `~/w63a/bin/wm-leg.sh:13` 的"**重跑即截断自己的证据**"（已登记 `D-G96`）**已由 W113A 修掉** —— `~/w63a/bin/wm-leg.sh` `aec91a0827bd9cfa → **2b788b5a6cde9914**`、同族 `~/w63a/bin/wm-leg198.sh` `80f694dc0000ab55 → **59a326c5d477807c**`（`: >` 截断 ⇒ **只追加 ＋ 每趟独立名 ＋ `.latest`**，纪律写进脚本头；**冻结证据仍是前缀**、原件 `a2ee1d7ea5451489`／`e0eb3cb200a5b7f2` 未动）⇒ **那一格不再是缺口**。⚠️ 本行另一条"**四处未端到端跑真脚本**"（以及 `wm-leg*.sh` 整脚本端到端）**不变**，仍 `NOINFO`（它们的 `run()` 会抢重活槽）。
- `TASK-0705` [Next] 🔴 **把"回归判定"的口径写进预登记模板**（`D-G99` 的落地；来源 = 车道 W105A §4.5 自立的 `F1` ＋ 本波 `docs/ROUTES.md` §15g 的口径句）：
  - 要改的对象 = **预登记模板**（`docs/WAVE*-PREREGISTRATION.md` 的判据节，或仓内那份"预登记怎么写"的说明件）—— ⚠️ **落地前先核"哪一份是权威模板"**；核不到 ⇒ 记 `NOINFO`，**不许**只改一份副本就宣称"模板已改"。
  - 模板里**必须**写死的**四要件**（**缺一即只能记 `NOINFO`**）：① **两臂同刻读数**（同一装置、同一会话、**只换一个文件**；两个件都要带 sha16 前置断言）；② **成对归因臂**（同腿旧/新**交替**、对间交替先后、每趟**全新进程树**）；③ **复现性**（**在旧件上也要能复现该红** —— 只有新件上红 ⇒ **不足以**判回归）；④ **统计口径**（Fisher 精确检验**双尾**，且**先写死**"样本量不够时不许判回归"——单臂 26 趟只看得见"相差 ≥4 倍"这一档）。
    - ⚖️ **口径澄清（**主控裁定 · dated；车道 W120A，2026-09-22**；上面 ③ 的**原话一字未动**，本条只在它旁边做**条件分派**）** —— 上面 ③ 那句「**在旧件上也要能复现该红** ⇒ 只有新件上红**不足以**判回归」与本行要的「**确定性 new-only ⇒ 必须判 `REGRESSION`**」**按字面互相排斥**（`build/MilBridge/W117A-report.md` §2.1 如实登记、**未裁定**）⇒ **两句回答的是不同问题，按条件分派**：
      - **(a) 当只有"一腿一个样本"时**（`D-G99` 的形态）：**旧件不复现 ⇒ 不能判回归 ⇒ 落 `NOINFO`** —— 原话要的正是这一条；
      - **(b) 当「先写的计划」＋「达到所需 `N`（**按功效口径**算，如 `6% vs 0%` ⇒ **131 趟/臂**）」＋「显著」三条同时满足**时：**new-only 也必须判 `REGRESSION`**（此时"旧件复现不了"是**检测力**问题，不是"不是本波引入"的证据）；
      - **(c) 旧件若也复现同一形态** ⇒ **不是本波引入**：判 `OK`，或按率显著加重判 `REGRESSION(rate-aggravated)`。
      ⇒ 即 `build/MilBridge/tools/regression-decision.py` 的**操作读法成立**，上面 ③ 的原话是它在**小样本**下的**特例**（**不是被推翻**）。⚠️ **原话不许改**，只在旁边加条件（同文另落 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G99` 条）。
  - **这条任务自己也要有牙**（反极性）：拿**已知的间歇案例**当 fixture —— 用 `D-G98` 的读数（**新 `3/36` vs 旧 `2/36`、`p = 1.000`**）做"**不许判回归**"的**负例**，用 `D-G98` 那类**确定性**差异（修前修后逐位可分的两件）做"**必须判回归**"的**正例** ⇒ 新模板若把负例判成回归，**它自己就红**（照仓内 `--selftest` 形态交件）。
  - ⚠️ **不许**顺手改任何**已冻结**的预登记件（若某份 `docs/WAVE*-PREREGISTRATION.md` 已进冻结语义 ⇒ **只加不改**；新要件应在**新波**的预登记里生效）；**不许**把本要件**倒填**进既有报告来"美化"历史判词。
  - 边界：本行**只立号、未写模板**（立号件是纯文本登记波，不含落地）；"**全仓还有几处预登记用了同款单腿推理**"**未逐处枚举** ⇒ 那一格 `NOINFO`。
  - `TASK-0705` ✅ **已办（车道 W117A，2026-09-22；只追加，上文一字未动）**：**权威模板 = `docs/PREREG-TEMPLATE.md`**（本波**新建**）。
    - **"哪一份是权威模板"的判定（先核后落，现场机械核）**：三条判据**全为否** ⇒ 原先**没有**权威模板 ⇒ 才新建。① `grep -rn --include='*.md' -e '权威模板' -e '预登记模板' -e 'PREREG-TEMPLATE' .` 命中 11 行**全是任务叙述、没有一行指名路径**（`build/MilBridge/W111A-report.md:192` 自己就记着"本件未核 ⇒ `NOINFO`"）；② 33 件 `docs/WAVE*-PREREGISTRATION.md` **没有同一套骨架**（`## §N` 风格 21 件 ／ `## N.` 风格 12 件；节数最少 5 / 最多 37 / 中位 9）；③ 判据**逐格全文**只在 **3** 件（`W49`/`W51`/`W52`）里指向**仓外** `$HOME/w<车道>/criteria.md`，其余各波内联在自己那一节 ⇒ 仓内没有唯一真源。**为什么不是别的件**：`docs/INDEX.md` 只把 `docs/WAVE<NN>-PREREGISTRATION.md` 描述成**一类**（`§3`），**没指名**任何一份是模板；`docs/PORT-SPEC.md:19`/`:66` 是**规范**（"判据先写死"这条纪律本身）、**没给**判据节骨架；33 件预登记都是**冻结证据**、彼此不继承 ⇒ 只改其中一份正是本行 `:430` 点名禁止的"只改一份副本"。⚠️ **欠账**：`docs/PORT-SPEC.md` 与 `docs/INDEX.md` 里应各加一行指针（W117A 写域不含它们）⇒ **未做**。
    - **四要件已逐字落进模板 `§1`**（① 两臂同刻 ② 成对归因臂 ③ 复现性 ④ Fisher 双尾 ＋ 分母只算"真尝试过的趟" ＋ 先写趟数与功效），并附 `§2` 的**三条现场读数**（`D-G99`＝`W105A` `F1` 的单腿推理；`D-G94`＝`W98A` 把唯一一次真命中从分母剔掉；三条实际红率 `4/30`／`2/16`／`1/17→1/16`）与 `§5` 的**边界**（工具判不了"同刻/交替/计划是先写的"）。
    - **牙（本行要的那一半："模板自己也要有牙"）= `build/MilBridge/tools/regression-decision.py`**（新建；零 `dotnet`、纯 python3）：三态机读行 `REGRESSION_DECISION=REGRESSION|NOINFO|OK`，`rc` = `0`/`3`/`2`（`rc=2` = **分母口径不合规** ⇒ 拒绝 ＋ `REGDEC_REFUSE=` 点名，**不降级成 `NOINFO`**）。`--selftest` **20/20 PASS**，含 `D-G98` 读数 `3/36 vs 2/36` 的**历史重放**（⇒ `OK`，**不许判回归**）、确定性 `5/5 vs 0/5` 的**必须判回归**、`16 腿 6%` 的**必须 `NOINFO`**、缺成对臂 ／ 缺同刻断言 ／ 分母含 `SKIP` 的各例；另与**四条仓内历史读数**（`p = 1.000`／`0.078`／`0.030`／`0.067`）逐字吻合。
    - **现场数字（本波算出来的，供以后引用时重算）**：分辨 `6% vs 0%` 需 **131 趟/臂**（`6.25% vs 0%` ⇒ 126；`12.5% vs 0%` ⇒ 62）；`0/16` 时**只有新臂红率 ≥ 约 38.5%（`MDE`）**才谈得上显著 ⇒ 现场 `1/16` 那格只能是 `NOINFO`；`0/40` 的 95% 单侧上界 **7.2%**（**这条**才是仓内"≥40 腿/臂"那句的来处，**不是** Fisher 功效口径的 131 —— 两个数**都要报**、不许互相替代）。
    - **未接线（本行不接）**：接进 `verify-all` 是**加步**（`27 → 28`），会当场打破刚冻结的 `27 gen=#51` 声明 ⇒ **本波只给逐字草案**（见 `build/MilBridge/W117A-report.md` §5）；机械核过 `fp_inputs()`：新工具**不在**现覆盖面（`find` 链现场命中 `build/MilBridge/tools/` 下 **0 件**），但按仓内惯例把它加进 `close-wave.sh` 的 `printf` 名单**必然移动 `inputs_fp`**（成对读数 `72c5f2263f62a83d… → e4ec6c6ebeef3cd6…`）⇒ 那一改**必须安排在 `IN_FP_0` 采样之前**。
    - ✅ **`TASK-0705` 收口复核（车道 W120A，2026-09-22；**上面 W117A 的登记只追加、一字未动**）** —— 四要件**逐条复核 ＋ 一处数字更正**：
      - ① **四要件落地点 = `docs/PREREG-TEMPLATE.md`**（`75dfc5f3fbc9df40`；**复核来源 = 主控现场**：新件、**未动**既有牙/判据）。判定依据三条**全否**：ⓐ 全仓原先**确实没有权威模板**（原 `grep` 12 行命中**全是任务叙述**、**无一行指名路径**；`W111A-report.md:192` 自记"未核 ⇒ `NOINFO`"）；ⓑ 33 件预登记**没有同一套骨架**（`## §N` **21** 件 vs `## N.` **12** 件；节数 **5／37／中位 9**）；ⓒ 逐格判据只有 **3** 件指向**仓外** `criteria.md` ⇒ **三条合取全否**。**为什么不是别的件**：`docs/INDEX.md:33` 只把它描述成**一类**、`docs/PORT-SPEC.md:19/:66` 是**规范、不给骨架**、33 件是**冻结证据彼此不继承**（只改一份 = `:430` 点名禁止）。
      - ② **工具 = `build/MilBridge/tools/regression-decision.py`**（`1eda9e3575960cba`，**主控现场复核逐位未变**）：三态机读行 `REGRESSION_DECISION=REGRESSION|NOINFO|OK`；`rc` = `0`／**`3`**（证据不足的 `NOINFO`）／**`2`**（**分母不合规 ⇒ 拒绝并点名** `REGDEC_REFUSE=`，**不降级成 `NOINFO`**）；**被仓内四条历史读数钉住** = `D-G98` 的 `1.000`／`W112A` 的 `0.078`／`0.030`／`0.067`（两条独立数值路径 A `lgamma` ／ B `comb` **逐例一致**）。
      - ⚠️ **③ 数字更正（只追加，原文一字未动）**：**上一行 `--selftest` 写的 `20/20 PASS` 是错的，现场重取 = `22/22`** —— 车道 W120A 现场跑**两遍**（`python3 -B build/MilBridge/tools/regression-decision.py --selftest`；零 `dotnet`、**0 仓内写**）：两趟**逐字相同**，`REGDEC_SELFTEST_ROSTER cases=22 pass=22 fail=0` ＋ **`REGDEC_SELFTEST=PASS total=22 pass=22 fail=0`**、`rc=0`，并自带 `REGDEC_SELFTEST_SELF … sha16=1eda9e3575960cba` ＋ `ST_ATTEST=PASS`（**自测期间本件未变 ⇒ 读数可归因**）⇒ **正确值 = `22/22`**（`W117A-report.md` §0／§3.3 写的也是 `22`，**只有本行错**）。
      - ⚠️ **③-补：更正的是哪一行（车道 W122A **追加点名**，2026-09-23；上面 ③ 的**原文一字未动**）** —— ③ 里那句"**上一行**"**没有点名**，现场核到：被更正的那一行 = **`docs/ROUTES.md:443`**（W117A 登记段里那句 `--selftest` **`20/20 PASS`**）。⚠️ **两个号都要记**：**W120A 动手前它在 `:438`**（`W120A` §15j 就是按那个号记的），W120A 在 `:431` 之后插入 **5 行** dated 澄清 ⇒ 顺移到 **`:443`**（本件现场 `grep -nF '20/20' docs/ROUTES.md`：**追加前 = 3 命中**〔`:443`／`:449`／`:557`〕，其中**只有 `:443` 是"登记错值"的那一行**、另两处是**更正 bullet 自己的引文** ⇒ **别按"唯一命中"读**）。⇒ 以后引"错值"时**按 `:443`（改前 `:438`）**，**别按"上一行"读**。⚠️ 措辞缺"点名"是**原文**的事 ⇒ **只追加这一句、不改原文**。
      - ④ **两个口径必须并列写死**（**回答不同问题、不许互相替代**）：**"≥40 趟/臂"是区间口径**（`0/40` 的 95% 单侧上界 ⇒ **`7.2%`**）而 **"`6% vs 0%` ⇒ `131` 趟/臂"是功效口径**（`α=0.05`、功效 `0.80`）—— 模板 `§4` 已并列。
      - ⑤ **未接线**（属下一波；**现场复核**）：`grep -c '^run_step "' verify-all.sh` = **27**、`# VERIFYALL-STEPS-DECL: 27 gen=#51`、`verify-all.sh` sha16 = **`1aa2ae4e94827cf3`**（现场算，与主控复核值逐位相同）⇒ 本行**仍"未接线"**，接线草案见 `W117A-report.md` §5（含**第五处隐含的**：新 `gen=` 必须有对应预登记件，否则 `prereg-absent` ⇒ `rc=2 NOINFO`）。
      - ⚖️ **口径张力已裁定**：见 `:431` 下新增的 **dated 口径澄清**（与 `D-G99` 条**同文**）⇒ `W117A` 的**操作读法成立**、原话是**小样本特例**。
      - **欠账清零**：`:436` 末那句"`docs/PORT-SPEC.md` 与 `docs/INDEX.md` 各欠**一行**指针"**已由 W120A 同趟补上**（见 §15j）。
- `TASK-0706` [Next] ✅ **把"装置/口径卫生"做成常态牙**（来源 = `D-G91`／`D-G96` 已修 ＋ `D-G42` 族射程缺口 ＋ `D-G97` 的判别式教训；波 `#51` 冻后）：
  - **要立的三条牙**（每条都**判据先写 ＋ 三态 ＋ `NOINFO` 不算绿**，形态照 `build/MilBridge/tools/baseline-sha-check.sh`）：
    ① **根集合一致性自检** —— `sync-applocal-authority.sh` ↔ `check-applocal-sync.sh` 那一对已由 W113A 落地（`--print-scan-roots` 派生 ＋ `APPSYNC_ROOTS=MISMATCH` ＋ `rc=2`，且**在 `STALE=` 汇总之前退出**）⇒ 本条把它**推广到别的"同步器 ↔ 校验器"成对件**；⚠️ **先枚举这类成对件**，枚举不到 ⇒ `NOINFO`（不许凭印象写一份名单）。
    ② **证据保全** —— `D-G96` 已把 `~/w63a/bin/wm-leg.sh`／`wm-leg198.sh` 的 `: > "$PROG"` 截断改成"**只追加 ＋ 每趟运行独立名 ＋ `.latest`**"⇒ 本条**清点全 `$HOME` 里"会截断自己后来要引用的证据"的装置**（形态 = `: > "$F"`／`> "$F"` 写向自己被引用/被留档的文件），判据 = "**重跑前后两件日志的 sha16 都有留档 ＋ 冻结证据仍是新日志的前缀**"。
    ③ **`D-G42` 族的语义射程复核** —— 判据 = `D-G97` 的**三要件合取**（**形状** = 文本测试／glob／`grep -q` ∧ **承载** = 被测串是某命令的 **stdout** ∧ **中毒** = 那条命令**失败时也往 stdout 打含被测关键词的文案**）；**不许**只看关键词，也**不许**只看牙现有口径（本例：只认 `UNDECLARED_HIT` ⇒ 漏掉"**件内本来没有 `pipefail`**"那一类，W113A 修的 8 处正落在这一格）。
  - **反极性（本行自己也要有牙）**：每条牙至少 **3 例"必须红" ＋ 1 例正极性 ＋ 1 例"必须 `NOINFO`"**；⚠️ **不许**用"写进声明表 `DECL`"的方式转绿（`D-G42` 族明令禁止）。
  - **边界**：本行**只立号、未建牙**（立号件是纯文本登记波）；"全 `$HOME` 装置清点"的**射程未做枚举** ⇒ 那一格 `NOINFO`。
  - 🚧 **进行中（车道 W119A）**：装置/口径卫生常态牙（根集合一致性／证据保全／口径语义射程三合一，三态 ＋ 五例两极化自检，不接线）
  - ✅ **`TASK-0706` 已办（车道 W119A，2026-09-23；**只追加，上面 W111A 的登记一字未动**）**：牙 = `build/MilBridge/tools/hygiene-tooth.sh`（**`dc1e79a23dbb7eb2`**，**1626 行**，**纯静态读／零 `dotnet`／秒级**，**未接线**）｜报告 `build/MilBridge/W119A-report.md`（**`685eaa58fe8072a2`**，**414 行**）。**三态 ＋ 两极化自检已过**：本件现场跑 `--selftest` = **`HYGIENE_SELFTEST=PASS total=67 pass=67 fail=0`** ＋ `ST_ATTEST=PASS`。**主控转来的读数（断链前，逐字）**：`HYGIENE_TOOTH=FAIL roots=PASS evidence=PASS inode=FAIL scope=REPORT semantic_undecidable=7` ＋ `multilink=1388 cross_region=1383 ext_ext_hits=0 code_files=72`（**第四类红了** —— 这正是本牙要抓的那一格）。⚠️ **本件现场重取时它已转绿**：`HYGIENE_TOOTH=PASS roots=PASS evidence=PASS inode=PASS scope=REPORT semantic_undecidable=7 multilink=0 cross_region=0 ext_ext_hits=0 ext_strict=0 code_files=72`、**`rc=0`** —— 因为 `W123A` 的**断链**已把 `$R` 侧的跨区同 inode 清掉（详见 `D-G101` 条 ＋ `build/MilBridge/W122A-report.md` §2.3）⇒ **两个读数都只是快照，引它必须带"读于何时"**。⚠️ **`HYGIENE_SCOPE` 永不为 `PASS`**（恒 `REPORT`，含 `semantic_undecidable=7`）⇒ **不许读成"全域干净"**。
- `TASK-0707` [Next] ✅ **把"硬链接/同 inode 共享"并进装置卫生牙**（来源 = **`D-G101`** 的落地；主控已把这一类**追加**给正在做前三类的车道 **W119A**）：
  - **要立的三格（判据先写 ＋ 三态 ＋ `NOINFO` 不算绿，形态照 `build/MilBridge/tools/baseline-sha-check.sh`）**：
    ① **列出 `links>1` 的件**（`stat`／`find -links +1` 口径，**不许**用"关键词喊话"代替）；② **列跨区同 inode 对**（`$R` ↔ `$HOME` 夹具区，如 `~/w62a/negrepo/**`／`~/w113a/fixture/fp-farm/**`），判据 = **交集非空即点名**；③ 对**登记夹具件**做"**开工 = 收工 sha16**"的**可复算断言**（开工留档 ＋ 收工现算 ＋ `cmp`）。
  - **三态**：跨区同 inode 对**存在** ⇒ `HYGIENE_HARDLINK=FAIL` **逐对点名**；**只有 `links>1` 而无跨区对**（同区自链，如 `*/bin/*` 的 .NET 发布件）⇒ **只报行、不判红**（那些是构建产物，判红就是**造假红**）；**查不动**（权限／夹具区不可达）⇒ `NOINFO`、**不许当绿**。
  - **`--selftest`（两极化，≥2 例）**：① 沙箱里**造一对硬链接**（`ln`）⇒ **必须红**；② 改回 **temp ＋ `rename`** ⇒ **必须回绿**。
  - **边界**：本行**只立号**；"哪个车道/哪一步造出这些硬链接"**未归因** ⇒ `NOINFO`；**`$R` ↔ fork 克隆 `~/netTest/GitProj/WPFOnLinux` 一格未判** ⇒ `NOINFO`。
  - 🚧 **正在由车道 W119A 实现**（它已在做前三类：根集合一致性／证据保全／口径语义射程；**这一类由主控追加给它**）。
  - ✅ **`TASK-0707` 收口（车道 W127A，2026-09-23；上面 W122A 的登记一字未动）**：本类**已由车道 W119A 做掉** ⇒ 状态位 **🔴 → ✅**（**行锚定**改法，只改状态位那一段）。
    - **牙与三格**：`build/MilBridge/tools/hygiene-tooth.sh`（**`dc1e79a23dbb7eb2`**，**1626 行**，`--selftest` **67/67**）的**第四类 = 硬链接/同 inode 共享**已在件内落地（`HYGIENE_INODE=` 分项；`--selftest` 含 **`S16a`**（真硬链接 × 原地写 ⇒ **必红**）／**`S16b`**（改 temp ＋ `rename` ⇒ **回绿且仍打印 `links>1`**）／**`S16c`**（形态抽不出 ⇒ **`NOINFO`**））⇒ ①列 `links>1` ②列跨区同 inode 对 ③三态，**三条格全部落地**。
    - **收口读数（主控现场复核）**：`HYGIENE_INODE=PASS multilink=0 cross_region=0`。**断链总账（车道 W123A）** = `1421`（登记件）＋ `6`（产品 DLL）＋ `4588`（`bin/obj`）= **`6015`**；再加 **`6417`**（`upstream/` 声明残留、**无写者**）= **`12432`** ＝ **开工时原始跨区共享数**。
    - ⚠️ **口径句（防把"牙的 0"读成全树干净）**：牙的 `multilink` **只覆盖它自己的 `HYG_SKIPDIRS`**（含 `obj bin upstream __pycache__`）⇒ **牙的 `0` ≠ 全树干净**；三个数 **`1388`／`1421`／`12432`** 是**三种口径**，差 **33** 全在 **`__pycache__/`**。
- `TASK-0708` [Next] 🔴 **"仪器波"：把四件新牙接线**（来源 = 主控裁定 2026-09-23；波 `#52` **不接**）：
  - **待接四件（逐件带件 sha16）**：`HYGIENE` = `build/MilBridge/tools/hygiene-tooth.sh` **`dc1e79a23dbb7eb2`**｜`REGRESSION-DECISION` = `build/MilBridge/tools/regression-decision.py` **`1eda9e3575960cba`**｜`UIA-DOOR` = `build/MilBridge/tools/uia-door-check.sh` **`d8f23e91ade01453`**｜`IME-LANDING` = `build/MilBridge/tools/ime-landing-check.sh` **`05207f31189dc62a`**。
  - **要改四处（同趟）**：`verify-all.sh` 的**四处声明**（口径句步数／`VERIFYALL-STEPS-DECL`／`STEP-NAMES` 末位／本步本体）⇒ **`27` 步 → `31` 步**。
  - ⚠️ **其中两件今天故意是红的**（`UIA` 门不存在：`UIA_DOOR=FAIL prod=0 consume=1 core_shim=0 uia_syms=0 ctrl_syms=8 live_calls=2 (all=69) libs=1`；`IME` 靠本册 `D-G76` 那条**降级声明**才转绿）⇒ **不能直接 `run_step`**：必须按仓内既有"**在册红**"形态 —— 样板 = `build/MilBridge/tools/tline-gate.sh:1302` 的 `GATE_REASON=all-as-registered`（**红 == 在册 ⇒ `rc=0`；红不在册 ⇒ `rc=1`**），即 **`known-red.json` 加 `entries[]`**（`arm=uia-door`／`arm=ime-landing`，`expected_shape` 写死现场机读行）＋ `repin-generation.py --why …` ＋ `--check` 须 `REPIN_GENERATION=PASS`。
  - **顺序约束**：接线那趟若按惯例把新件纳入 `fp_inputs()` ⇒ `inputs_fp` 必变 ⇒ **必须安排在 `IN_FP_0`（`close-wave.sh:202`）之前**。
  - ⚠️ **本波（`#52`）不接**（**主控裁定**）：避免与 `D-G100`／`D-G101` 的改动**叠加成多变量**。
- `TASK-9907` [Next] ✅ **已办（但「未接线」；车道 W97A，报告 `build/MilBridge/W97A-report.md` `a6fcd1c188725168`，工具 `build/MilBridge/tools/nul-bytes-check.sh` `409d83d945f7d563`，683 行）** —— `D-G82` 的普查**已成牙**：现场 `NULBYTES=PASS files=1172 hits=0 bytes=249995686 skipdir_dirs=141 binext=280 noext=11 diag_noext_nonelf=0 canary=ok`、`rc=0`、**0.3 s**（主控现场重算为 `files=1171 bytes=249951968`，差 **1 件 = W97A 报告自己**，判据只与 `hits=` 有关）；`--selftest` **31/31 PASS**、含**四条"必红"＋三条"必 NOINFO"**的反极性；**历史重放能抓 `D-G82`**（W83A 修前备份 `f0d3d1501aebcd8c` ⇒ `NULBYTES=FAIL hits=1 path=…/wic_proxy.c offset=15873 line=289 n=3`，与 W83A 独立读数逐个吻合；换修后件 `8dc634b9254295f4` ⇒ `PASS`）。
  - `TASK-9907` ⚠️ **边界口径（主控已裁定，接线时逐字进判据）**：本牙的绿**只**等于「**声明覆盖面里** 0 件含 NUL」**≠「全仓 0 件」** —— 判据外仍有三类**未判**：`upstream/**`（**6417 件，未测 ⇒ `NOINFO`**）、**11 件无扩展名 ELF**（首 NUL 恒在偏移 7 ⇒ **真二进制，只 `DIAG` 不判红**；判它就是**造假红**）、**280 件按定义是二进制**的件（扫它们对 `D-G82` 零信息）。
  - `TASK-9907` ⚠️ **接线归波 `#51`**：现在接进 `verify-all` 第 `[27]` 步会把冻结的 `26 gen=#50` 步数声明**当场打成过期** ⇒ **本波不接**。⚠️ 接线时若按仓内惯例把它纳入 `fp_inputs()` 的 `printf` 名单，**必然移动 `inputs_fp`**（`$HOME` 副本模拟：`ee543f44… → 80c6fa0fa91f4fbe…`）⇒ 那一改**必须安排在 `IN_FP_0` 采样之前**。

## §15 `#50` 冻结块与冻后新登记（**一行一条**；2026-09-22 车道 W99A 补）

- **`#50` 已冻结并推送**：基线 = **`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` `1f4189c1257737a9`**（**644,091 B**）｜`docs/CURRENT-STATE.md:9` 机器行 `gen=#49→#50`｜远端 `origin/feat-Linux` head = **`608d0a170f07fa57`**（`ls-remote --symref origin HEAD` 仍 `ref: refs/heads/feat-Linux`）。
- ⚠️ **`#50` 冻结块里的 `pf` 不是构建身份**（见 **`D-G92`**）：冻结块逐字写着"同源、同命令、逐字相同的整波重建**可给出不同字节**"⇒ `pf` 那一格**只作"冻结那一刻硬盘上是这个"的现场值**，**不许**被后人当**漂移／回归判据**（真凶留 `NOINFO`，复算配方见 `D-G92`）。**本件未改冻结块一字**（改了要重冻）。
- 🆕 **`D-G91`（装置缺陷 · 假绿族）**：`sync-applocal-authority.sh:59` 默认 `SCAN_ROOTS` **漏 `$REPO/tools`**，而校验器 `check-applocal-sync.sh:169` **含**它 ⇒ ① 默认参数**永远刷不到**那份唯一 `STALE`；② 更危险：**它自己用收窄根打出 `STALE=0` 的假绿**。成对读数：`09b`（默认）`refreshed=0/STALE=0` vs `09a`（同刻全文口径）`STALE=1`；显式补根 `09c` 才刷到（`STALE=1→0`）。**只登记未修** ⇒ 落地拆新号（`#51` 候选）。
- 🆕 **`D-G92`（仪器/身份缺陷）**：**`pf` 不是构建身份** —— 四趟**逐字相同**的整波重建给四个 sha（`881c56e26808269f`／`decd920092287b03`／`581c864a7f2ad36c`／`f34bc297d19778fd`），而 `ARTIFACT_SRC_FP proj=PresentationFramework fp=5b38ea7420b26377 n=1362` **四趟逐位相同**、隔离 `-t:Rebuild` 连跑两次同值；72 字节差异全在 PE `TimeDateStamp`＋MVID＋调试目录。**已按主控裁定写进冻结块** ⇒ 本条只把它在缺陷册里具名；**与既有 `D-G46` 并存**（`D-G46` 记"封条分不清可复现构建 vs 身份位"这个缺口，本条把它"PF 单独重编确定"的推论**在整波口径下收窄**）。
- **`fp_inputs` 零影响**（本件机械证）：覆盖面 **147 件**（真调用 `fp_inputs()`，`f7e054ad…` 同批），本件编辑的 3 件（`KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`defect-registry-declared.tsv`）**命中全 0** ⇒ 指纹开工=收工=**`ee543f44b1090c7498dcc2562ef69e1309764aaa2b92b8fa65e29d06a1e18f48`**（== `#50` 冻结值，**逐位相同**）。

## §15b `#50` 收口（第三笔）与冻后第二笔新登记（**一行一条**；2026-09-22 车道 W100A 补）

- **`#50` 收口的最后一格已闭**：波 `#50` 的 `[Next]` 清单**至此全部有结论**（`9905`／`9906` ✅ 见 §14；`0107` ✅ 见 §14 与 §13 树；`0203` 🟡 见 §14；`9907` ✅「未接线」见 §14；`0108`／`0703` 🔴 已拆号待 `#51`）。
- **`TASK-0203`（长跑）🟡 收口**：精度目标达成（单臂 **4.87% ≤ 5%**）、`134` 族两极化干净成立（**59/60 vs 0/60**）；**`139` 族仍 `NOINFO`**（唯一 1 次落在修前件臂）⇒ **不许当绿**（车道 W98A，报告 `74df2f1a289bcc45`）。
- **`TASK-9907`（NUL 牙）✅ 收口但「未接线」**：`NULBYTES=PASS hits=0`（`files=1172`／`bytes=249995686`）、`--selftest 31/31`、历史重放抓得住 `D-G82`；接线（第 `[27]` 步）归波 `#51`（车道 W97A，工具 `409d83d945f7d563`）。
- 🆕 **新登记 `D-G93`（装置缺陷 · "按关键词认对象"族）**：闸门 `pgrep -f '<波链脚本名>'` 命中**别家自己的 `bash -c` 轮询命令行** ⇒ **假死锁 300 s**（而槽当时是空的）；成对读数 = 旧谓词命中 1 条／新探测器（读 `/proc/*/cmdline`、排除 `bash -c` 代码串）命中 0；旧口径 **48 min 只走 5 趟**（单趟平均等 840 s）vs 换后 128 趟共让路 1,020 s。同族前科四处：`KNOWN-DEFECTS.md:546` 的 `L14`（**第一次实例，原文一字未动**）／`W77A-report.md:412`／`#2073` W46K 自匹配／本条。**修法在仓外 ⇒ 仓内无牙，只登记**。
- 🆕 **新登记 `D-G94`（判据缺陷 · 分母口径）**：把 `CLICK … SKIP dead`（**没点**）算进 `clicks_total` ⇒ **唯一那次真 `139` 被自己的口径判成"无检测力"并从分母剔除**（旧口径 `7/9 = 77.8% < 80%`；现行 `tried = ct − skipped` ⇒ `7/7 = 100%`、`detect=yes`）。⚠️ **同时如实记「判据文本与实现分叉」**：现行门槛是 `tried ≥ 7`（原文写 `clicks_total ≥ 8`），而 `criteria.md` §5 与报告 §1.3 都还是旧文本 ⇒ 引用必须指名出处。
- 🔁 **`D-G87` 第三次复核（并入，不新开号）**：`134` 族 **61 趟里 14 趟（23%）只写 18–19 KB 折叠形**（W85A 时 2/15 ≈13%）⇒ 日志体积**更不能**当判别量；另补 **`W98A-F7`**：`timeout: 被监视的命令已核心转储`（43 B）**不是应用输出** ⇒ 判"应用 0 字节"必须先剔掉它（否则把真命中判成不命中）。

## §15c `#50` 冻后第三笔：登记 `D-G95` ＋ 更正路径笔误 ＋ 拆两条新 TASK（**一行一条**；2026-09-22 车道 W104A 补）

- 🆕 **新登记 `D-G95`（装置缺陷 · 恒真谓词用在 `if !` 上 ⇒ 反向恒假）**：`~/w63a/bin/wm-leg.sh:19` 逐字 `if ! DISPLAY=$D xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | grep -q window; then` —— 与 `D-G89` **同一个恒真谓词**，但用在 `if !` 上 ⇒ `!` **恒假** ⇒ 起 `xfwm4` 的 `then` 体**永远进不去** ⇒ 自称"WM 腿"的那一趟（`~/w63a/logs/wm.progress:1`，`2026-09-21 11:35:25`，逐字 `… wm=_NET_SUPPORTING_WM_CHECK:  no such atom on any window.`）**其实跑在无 WM 上**。**危险方向与 `D-G89` 不同**：不是假红也不是假绿，而是"**你以为在测有 WM 的世界，其实没有**"（该腿对 WM 类缺陷**检测力 0**，而输出看起来完全正常）。
- ⚠️ **路径笔误更正（只追加，不改原文）**：`build/MilBridge/W53A/` **仓内不存在**（`ls -d` `rc=2`；fork 克隆里只有 `build/MilBridge/W53A-report.md`）⇒ 真身 = **仓外** `~/w53a/cell3.sh`（`#50` 冻后由车道 W102A 修为 **`a358f6fd38b3b387`**）。更正行已追加到 4 处：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`（`D-G89` 条）｜`docs/ROUTES.md`（`TASK-0703` 行）｜`build/MilBridge/W93A-report.md`（§8 表格）｜`build/MilBridge/W96A-report.md`（§1.2 与 §5.4）。
- 🆕 **新任务 `TASK-0704` [Next] 🔴**：修**仓外 4 处**同类恒真谓词（`~/w53a/cell.sh:26`／`cell2.sh:26`／`~/w76a/bin/ab.sh:26`／`~/w63a/bin/wm-leg.sh:19`）＋ **复核 `w63a` 那趟"WM 腿"的判词是否已影响任何已登记结论**（若影响须按"无 WM 口径"重取或降级 `NOINFO`）；**进行中（车道 W103A）**。
- 🆕 **新任务 `TASK-0109` [Next] 🔴**：产品侧 `wpf_x11_has_ewmh_wm()`（`src/WpfGfx.Linux.Native/src/win32_x11.c:1659`）**只查属性在不在、不查那个窗还在不在**，而留档已证 **WM 死后 EWMH 属性会残留** ⇒ `wpf_x11_moveresize()`（`:1780`）可能**走 EWMH 分支静默丢一次移动**；要建"**WM 已死但属性残留**"的场景来验，**判据先写**、验不出来写 `NOINFO`（来源 = W102A 报告 §8.5 的 `NOINFO`）。
- ⚠️ **`wm-awaited.sh` 「未接线」**：它未进 `verify-all`／任何门禁，也**未**进 `fp_inputs()` 覆盖面（覆盖面 **147 件**里 `grep wm-awaited` **0 命中**）⇒ **若被接进任何在仓调用方，按仓内纪律必须同趟把它纳入 `fp_inputs()` 覆盖面**（"判据改了自己没人看着"同族欠账）。
- ⚠️ **本件状态位一处未动（如实记，供主控裁）**：`TASK-0703` 的**装置侧**已由 W102A 交件（`wm-awaited.sh` `57a852f6948e1c67`、两极化三条腿齐），但本车道**未**把它的 `🔴` 改成 `✅` —— 因为该行正文还含"**盘点全仓同类写法**"这一半，而仓外 4 处**仍未修**（已拆 `TASK-0704`）；"改不改状态位"**留给主控一句话裁定**。
- **`fp_inputs` 零影响**（本件机械证）：本件编辑的 6 件（册／地图／`W93A-report.md`／`W96A-report.md`／声明表／`W102A-report.md`＋`wm-awaited.sh`）在覆盖面 **147 件**里**命中全 0** ⇒ 本件贡献为零；⚠️ 但**开工/收工实测指纹 ≠ `#50` 冻结值**（见报告 §6.2：偏离来自**车道 W101A 正在改它自己写域里的 `win32_core.c`／`win32_internal.h`**，**不是本件**）。

## §15d `#50` 冻后第四笔：`TASK-0703`／`TASK-0704` 收口 ＋ `D-G96` ＋ 全域重盘（**一行一条**；2026-09-22 车道 W107A 补）

- ✅ **`TASK-0704` → ✅ 已办**：车道 W103A 交件（四处修好、两极化成立、被污染臂复核 12/12 且 **0 条受影响**）⇒ 本车道**现场重算四处 sha16 与 W103A 报告逐字相同**（`e1301e3b274d6dec`／`208a674183825d23`／`3ce92b2d8806e3d7`／`aec91a0827bd9cfa`，均 `perm=711`）后改状态位（理由与读数见 §14 该行下的收口 bullet）。
- 🟡 **`TASK-0703` → 🟡 未收口（**不**标 ✅）**：其"盘点全仓同类写法"那一半**已做完**，但盘点**有真命中** ⇒ 按先写判据（可执行命中必须为 0）**不得标绿**。**重盘计数**：`P-A` 可执行 **7** ／注释 **13**；`P-B` **82**（可执行 61／注释 21）；`P-C` **0**；其中**活装置 1 处** = **新发现** `~/w63a/bin/wm-leg198.sh:17` 的 `case "$wm" in *window*)`（**glob 形态**，前两条盘点的 `grep -q window` 口径**机械上看不见**）⇒ 它让"仓外同类写法"从 5 处变 **6 处**（口径不同，引用者指名）。
- 🆕 **新登记 `D-G96`（装置缺陷 · 证据保全）**：`~/w63a/bin/wm-leg.sh:13` ＝ `: > "$PROG"`（**截断**）⇒ **任何一次重跑都会抹掉 `D-G95` 引用的唯一证据行**（`logs/wm.progress:1`）；同类 `wm-leg198.sh:12`。**未修**（W103A 只改了 `:19-22`）。性质 = "**你为了复核去重跑，就把要复核的证据毁了**" ⇒ 复核这类腿**必须先 `cp -p` 冻结日志**。
- ✅ **`D-G95` 的 `NOINFO` 收口**：处置里点名的"被污染臂是否影响已登记结论"**已复核 = 12/12 逐条、0 条受影响**（依据 `REPORT.md:279` 自报 + `:309-311` 频率表 + `W301-303` 取自 `:198`＋真实启动日志 + 册内 `D-G64/66/69` 零 `W63A` 引用）⇒ **不需重取、不需降级**；**仍保留**两条 `NOINFO`（`:198` 当时未取 `C2`/`C4`；00:24 那版谓词原文未读到）。
- ⚠️ **归因更正（只追加，原文一字未动）**：`~/w63a/REPORT.md:279` 之后新增 dated 更正块（件 `c837e102c8ada0f1 → 4d3746698860e12b`）—— 把"WM 没起来"的**原因**从"`xfwm4` 调用形式写错"更正为"**`wm-leg.sh:19` 的恒真谓词用在 `if !` 上 ⇒ 起 WM 的分支从未执行**"（机械证 = `logs/xfwm197.log` mtime 停 `00:24:03` ＋ `~/w102a/logs/w63a-form-demo.txt` 的块级复现）。**照错归因修会放过恒真谓词**，故必须改。
- **`fp_inputs` 影响判断**：本件编辑/新建件**全部在覆盖面之外**（机械证见 `build/MilBridge/W107A-report.md` §9）；但收尾态**≠ `#50` 冻结值**（在飞的产品改动所致），**如实记、不当异常、未改任何判据**。

## §15e `#50` 冻后第五笔：`TASK-0703` 收口（修掉最后缺口）＋ `D-G97` ＋ 第四形态普查 ＋ parity 口径固定（**一行一条**；2026-09-22 车道 W108A 补）

- ✅ **`TASK-0703` → ✅ 已收口**（状态位 `🟡` → `✅`，本件**行锚定**改，改后 `wc -l` 仍 `439` ⇒ 未吞下一行）。**四条判据逐条满足**（**判据先写**于 `~/w108a/criteria.md` §5.1）：
  ① **装置侧交件**：真判据工具 `build/MilBridge/tools/wm-awaited.sh`（`57a852f6948e1c67`，W102A 交）**本件只读引用、未改**；
  ② **两极化成立**（本件现场，私有 `Xvfb :189`，**三条读数同趟取得**）：**修前形态**（`~/w63a/bin/wm-leg198.sh:17` 的 `case "$wm" in *window*)`，用 `sed` 从备份抽原文跑）喂入无 WM 的失败文案 `_NET_SUPPORTING_WM_CHECK:  no such atom on any window.` ⇒ **走 `:` 分支 `rc=0` ＝"前提成立"⇒ 恒真**；**同一台真 WM** 的文本 `window id # 0x2000ae` ⇒ **也走 `:`**（两种相反输入同一分支 ⇒ **它没在判**）；**修后形态**同一输入 ⇒ **`exit 9` ＋ `NOINFO wm-absent`**（`wm_awaited_rc=1`）；**有 WM 屏** ⇒ **继续 `WM-AWAITED-PASS`**（不误报缺失）；
  ③ **全域重盘可执行"活装置"命中 = 0**：三形态（`grep -q window`／`if !` 同谓词／`case … *window*`）逐处点名分类后，**活装置缺口 0**，其余 6 处 = **fixture 3／负控 1／自指 2**（可复算命令与逐处点名见 `~/w108a/verify.txt`）；
  ④ **普查射程缺口已登记为 `D-G97`**。
- 📌 **口径句（本行**之后**才写；用于后续引用者）**：**fixture／负控／自指不计入"活装置缺口"** —— fixture 与负控**故意**演示旧形态（`~/w102a/old-predicate.sh:17,21,27` 三行、`~/w103a/legs.sh:114`），自指 = **普查仪器自己的 pattern 字面量**（`~/w108a/verify.sh:20,21,22`）⇒ 三者都**不是**"装置里还挂着一个恒真守卫"。判定"活装置"必须**人读用途**，不能只看命中。
- 🆕 **新登记 `D-G97`（装置缺陷 · 前提守卫恒真（glob 形态）＋ 普查射程缺口）**：`case "$wm" in *window*)` **被那条命令自己的失败文案命中** —— `xprop <ATOM>` **自报参数**（无 WM 时把 `_NET_SUPPORTING_WM_CHECK:  no such atom on any window.` 打在 **stdout、`rc=0`**）⇒ glob `*window*` 命中 `any window.` 里的 `window` ⇒ **"前提成立"守卫恒真** ⇒ **静默跑在无 WM 上**（危害同 `D-G95`「静默跑错腿」，**形态不同**：`D-G89` = `grep -q window` 恒真／`D-G95` = 同谓词用在 `if !` 上**反向恒假**／本条 = **glob 恒真**）。**已修**：`~/w63a/bin/wm-leg198.sh` `371220d84d186e81 → 80f694dc0000ab55`（`perm=644`、`bash -n rc=0`、**剥注释后可执行 `*window*` 计数 = 0**、旧形态只留注释），真判据改用 `wm-awaited.sh --check`（**`C1∧C2∧C3` 三条件全要**，工具不可执行时**大声失败** `exit 9`，**退出码 9 与判词与原形态逐字一致**），输出**带时间戳**（照 `D-G96` 教训，固定名会被下次运行截断）。
- ⚠️ **satisfying 教训（本波第三次踩"按关键词认对象"）**：**普查射程必须按"语义"（谁产生这个串、它失败时打什么）复核** —— 关键词扫**看不见**它（该行没有 `grep`）；形状扫**噪声吞信号**（`case "$V" in *W*)` 全域 `EXEC=333`，"变量来自命令替换" `EXEC=210`，"前提臂为 `:`" `EXEC=14` 且**只 2 个站点、人读后 0 个真缺口**）⇒ **真判别式 = 三条件合取**：**(a) 形状**（文本测试）**∧ (b) 承载**（被测串是某命令的 stdout）**∧ (c) 中毒**（那条命令**失败时也打含该关键词的文案**）。同族：`D-G84`／`D-G93`／`D-G89`。
- 📌 **`tests/parity/**` 两件：维持"不推"（口径固定，免得后人反复复议）** —— `tests/parity/**/u14/linux-results-u14.json`（**118.2 MB**）与 `tests/parity/**/layout-b34/windows-results.json`（**53.0 MB**）**继续不推**；依据 = **`.gitignore:47`／`.gitignore:51` 明确排除**（W107A §8.3 点名、主控裁定），且 u14 **超 GitHub 单文件 `100 MB` 硬限**、b34 的读者**都走仓内派生件** ⇒ **本件不推、不改 `.gitignore`**。
- **`fp_inputs` 影响判断**：见 `build/MilBridge/W108A-report.md` §9（机械证：`close-wave.sh` 的 `fp_inputs()` 覆盖面逐件命中计数）。

## §15f `#51` 冻后第六笔：`TASK-0108` 收口（`P3` 落地）＋ `D-G80` 并入新实例（**一行一条**；2026-09-22 车道 W109A 补）

- ✅ **`TASK-0108` → ✅ 已收口**（状态位 `🔴` → `✅`，本件**行锚定**改，改后 `wc -l` 仍 `452` ⇒ 未吞下一行；插入读数 bullet 后 = `462`）：依据 = `P3`（托管侧通知）**已落地**（车道 W106A，报告 `build/MilBridge/W106A-report.md`，提交版口径 = `6558bba440cce6a3`）＋ **四格 `PASS=8 FAIL=0`**（两腿逐字相同）＋ **零回归**（`D-G83` 四格全过）＋ **反极性双向逐位**（`8392fc09564779a1`／`215c856cbca9922b`）；读数、残留边界、两处 `PASS→VACUOUS` 与 `I1` 的 `W3` 红（`NOINFO`）**逐字**见 §14 该行下新增的收口 bullet。
- 📌 **口径句（后续引用者按这句判"要不要重冻"）**：**`#51` 的"产品位移" = `win32shim` ＋ `pf` 两位** —— `win32shim 33352e5797031999 → 8392fc09564779a1`（`327,248 B`；**导出 `546 → 547`**，新增 `wpf_hints_publish`）｜`pf f34bc297d19778fd → 215c856cbca9922b`（`6,123,520 B`）；**其余七位与 `#50` 逐位相同**（`bridge`／`pc`／`windowsbase`／`provider`／`wic_shim`／`hbtextline`／`dwf`）⇒ **收尾链必须重钉世代（`repin-generation.py --why`）＋ 重冻 `#51`**；`docs/CURRENT-STATE.md:9` 仍写 `BASELINE-FROZEN gen=#50 sha16=1f4189c1257737a9`（**本件未动那一行**，如实记）。
- 🆕 **`D-G80` 并入新实例（**不新增编号**）—— 这次坏在"副本陈旧、而读数取自副本"**：`~/w93a/probe/bin/Release/PresentationFramework.dll` = `2a5b7641f6fba0fb`（`6,123,008 B`、`mtime 2026-09-22 10:02:35`，本件现场现算）**≠ `#50` 冻结值 `f34bc297d19778fd`** ⇒ 车道 W106A 腿脚本第一版指向它 ⇒ 那一趟**拿旧 PF 验新 PF** ⇒ **整趟作废重跑**；**射程要指名**：改 `native` 的车道**不受影响**（shim 走 `WPF_LINUX_WIN32_SHIM` 显式路径），**只有改 `pf` 的车道会被它吞掉**。教训 = **车道开工前必须核"装置读的是哪一份件"**（拿不到那条自证行 ⇒ 记 `NOINFO`）。逐字见册内 `D-G80` 条的新 bullet。
- 📌 **`docs/WAVE51-PREREGISTRATION.md`（`af21bdf95b848eb9`，`8,049 B`）已进仓**（车道 W101A 的预登记件；本件只读引用，**一字未改**）。

## §15g `#51` 收尾链闭合（`38e67e834430d75c`）＋ 两条新登记 `D-G98`／`D-G99` ＋ 两条新 TASK ＋ 两条口径句（**一行一条**；2026-09-22 车道 W111A 补）

- ✅ **`#51` 收尾链闭合**（**三句都要有**；本件只读复核，**复核来源 = 主控现场重算**）：① **冻结** = `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` **`38e67e834430d75c`**（`BASELINESHA`／`BASELINEGEN(#51)`／`BASELINEDUP(n=0)` 三颗声明牙全 PASS）；② **冻后 `verify-all` ×2 = 27/27 全绿**（`#51` 把步数声明 `26 → 27`）；③ **推送** = 远端 `origin/feat-Linux` head **`084afe0319623d54`**（`ls-remote --symref` 仍 `ref: refs/heads/feat-Linux`）。
- ✅ **`TASK-9907` 接线已落地**（在 `#51` 冻结块内）：新第 `[27]` 步 `NUL-BYTES`（`D-G82` 的牙）= `build/MilBridge/tools/nul-bytes-check.sh`；声明机读行 `VERIFYALL-STEPS-DECL: 27 gen=#51`；`fp_inputs()` **同趟**纳入该件 ⇒ 覆盖面 **147 → 149 件**，`inputs_fp` 现值 **`58a6c0945b7d5358…`**（本件现场**真调用**复算 = `58a6c0945b7d535830ce3e3e4f25752b68f3714d3f35f540253eca6e69b3dd36`）。⚠️ 该步的绿**只等于"声明覆盖面内 0 件含 NUL"**（`upstream/**` 未测 ⇒ `NOINFO`；11 件无扩展名 ELF 只 `DIAG`、不判红）。
- 🔁 **`pf` 在整波重建后又**自变一次**（`215c856cbca9922b → bc2c47ac7b067bad`，**同尺寸**）⇒ **`D-G92` 现场再证**，**三句都要有**：① 这两趟的**构建输入逐字相同**（同一源、同一命令、`ARTIFACT-SRC-FP` 不变）；② 变的**只有 `pf` 这一位**、且**同尺寸** ⇒ 不是"改了什么"，而是"**构建身份本身不可复现**"；③ ⇒ **冻结块里 `pf` 那一格只作"冻结那一刻硬盘上是这个"的现场值**，**不许**被后人当**漂移／回归判据**。
- 📌 **口径句（"回归判定"；后续引用者按这句判）**：凡"**回归判定**"，**必须同时**给 ① **两臂同刻读数**（同装置、同会话、**只换一个文件**）＋ ② **成对归因臂**（同腿旧/新**交替**、每趟全新进程树）＋ ③ **复现性**（**在旧件上也要能复现该红**）＋ ④ **统计口径**（Fisher 精确检验**双尾**）；**缺一即只能记 `NOINFO`**，**不许**判回归。**样本量**：单臂 26 趟只看得出"相差 ≥4 倍"这一档 —— 现场反例 = `D-G98` 的 **`3/36 vs 2/36 ⇒ p = 1.000`**（同族但判词不同的既有号 = `D-G94`，那条坏的是**分母口径**）。
- 📌 **口径句（"哪些件不推"，固定住、免得后人反复复议）**：以下 **7 件** —— `build/.applocal-selftest.log`｜`build/MilBridge/gen/tline-ledger-lines-20260921-{1224,1231,1540,1623,1629}.txt`（5 件）｜`build/MilBridge/src/MilBridge.Resolver/README-合并写.txt` —— **都不在** `fp_inputs()` 覆盖面、**不参与任何判据**，性质 = **运行日志／`#48`–`#50` 遗留账本／来源未清的散件** ⇒ **一律不推**（车道 W110A §7.4 逐件提名、**主控裁定维持"不推"**）⇒ **不许**为了让 `git status` 干净而把它们塞进任何后续提交。
- 🆕 **新登记 `D-G98`（产品/装置界面缺陷 · 几何还原残留）**：退出最大化后 **`_NET_WM_STATE` 已还原**、而 **client 几何与 WM 的 frame 几何双双卡在 `1280x1024@+0+0`**（**间歇**）。当代 **新件 `3/36` vs 旧冻结件（**无 `P2`**）`2/36`、Fisher 双尾 `p = 1.000`** ⇒ **不是本波引入**；外部只读观测器在**旧件**那趟记录到提示**全程是常量** `program specified minimum size: 1 by 1`（**无 `maximum size`**）⇒ **排除**"提示把窗口卡住"；**不是"点击被吞"**（`m_ok` **52/52 = 1**、`r_ok=1` **46/50**，4 条红的 `m_ok` **都是 1**）。**首次登记** = 车道 W89A §5.3（`2/15`）⇒ 本条**独立立号**（此前只挂在 `TASK-0205` 行的"残留"里）；**最内层真因（WM 为什么没收回几何）`NOINFO`**；落地 = **`TASK-0110`**。
- 🆕 **新登记 `D-G99`（判据缺陷 · 样本量与随机性）**：规则"**`A` 臂红而 `B` 臂同腿绿 ⇒ 判回归**"（W105A 判据 §4 C3 **原文**）对**间歇**现象**不充分** —— **一条腿一个样本分不开"件相关"与"随机"** ⇒ 会把**间歇残留误判成回归**（假红）。W105A 的处置 = **照字面判 `C1 = FAIL`（不悄悄改判据）**＋**如实报**归因结论（"既有间歇残留"），**两条都留在报告里由收尾链裁定**。与 `D-G94` **同族但判词不同**（本条是**样本量/随机性**，那条是**分母口径**）⇒ **独立立号 ＋ 交叉引用**；修法（写进预登记模板）= **`TASK-0705`**。
- 🆕 **新任务 `TASK-0110` [Next] 🔴**：**几何还原残留** —— 查"**WM 为什么不把退出最大化的几何收回去**"；判据**必须先写**且**必须能抓 frame/client 时序分离**（现行 `AFTER_R2`／`AFTER_R2_SETTLED` **两拍不够** ⇒ 要加中间拍）；反极性 = 修法拆掉后回到**同形**；取不到分层读数 ⇒ `NOINFO`。
- 🆕 **新任务 `TASK-0705` [Next] 🔴**：把"**回归判定**"的**四要件**（两臂同刻 ＋ 成对归因臂 ＋ 复现性 ＋ Fisher）写进**预登记模板**，**缺一即 `NOINFO`**；并用 `D-G98` 的读数做**"不许判回归"的负例**（间歇案例）＋ 确定性差异做**"必须判回归"的正例** ⇒ **模板自己也要有牙**。
- **本件的写域与零影响**：只编辑 3 件（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`build/MilBridge/tools/defect-registry-declared.tsv`）＋新建报告 `build/MilBridge/W111A-report.md`；**这 4 件全都不在** `fp_inputs()` 覆盖面 ⇒ 指纹 **开工 = 收工 = `58a6c0945b7d5358…`（逐位相同）**。⚠️ 声明表重生成后 `DEFREG_DECLDRIFT` 由 **3 → 0**（那 3 处陈旧锚点是 `#51` 冻结改了三份 route 件造成的，本件顺带钉齐）。

## §15h `#51` 冻后第七笔：三束装置/判据卫生**已修**（`D-G91`／`D-G96`／`D-G42` 族）＋ `TASK-0706` ＋ `inputs_fp` 位移归因（**一行一条**；2026-09-22 车道 W111A 补，登记内容由主控转来、读数出自车道 **W113A** 报告 `build/MilBridge/W113A-report.md` **`153a997ae6bc68b9`**）

- ✅ **`D-G91` → 已修**：`build/DirectWrite.Linux/wic-shim/sync-applocal-authority.sh` `b56a85afd70c2321 → **ea854808dfe3450a**`（**默认根集合改为从判据唯一实现派生** ＋ 集合自检：不等 ⇒ `APPSYNC_ROOTS=MISMATCH`×2 ＋ `NOINFO` ＋ **`rc=2`**，且**在任何 `STALE=` 汇总之前退出**）｜校验器 `build/DirectWrite.Linux/wic-shim/check-applocal-sync.sh` `97d547551846fd13 → **346dc4e0bf6724e8**`（`:169` 提成唯一定义常量 `SCAN_ROOTS_DEFAULT` ＋ 新增**只读** `--print-scan-roots`）；**成对读数**（私有影子仓、真树零写）：修前收窄根 ⇒ `STALE=0`（**假绿**）vs 校验器默认根 ⇒ `STALE=1`（**真值**，同仪器同树同刻）；修后默认根 ⇒ **刷到了**（`refreshed=1 newer=0 applied=1`、刷后 sha == 权威）、**显式收窄** ⇒ `rc=2` ＋ 计数行各 0；**真树计数器逐字不变**（`STALE=0 NEWER-DIFF=0 DIVERGENT=0 UNEXPECTED=6[DECL-GAP-EQ=6]`，**没洗绿**）；`--selftest` **18/18 PASS**。**判词原文未动**，册内 `D-G91` 条末已追加 dated bullet。**sha16 全部本件现场现算，与 W113A 报告逐字相同**。
- ✅ **`D-G96` → 已修**：`~/w63a/bin/wm-leg.sh` `aec91a0827bd9cfa → **2b788b5a6cde9914**`、`~/w63a/bin/wm-leg198.sh` `80f694dc0000ab55 → **59a326c5d477807c**`（`: > "$PROG"` 截断 ⇒ **只追加 ＋ 每趟独立名 ＋ `.latest`**，纪律写进脚本头）；**成对读数**（私有 `Xvfb :191`）：修前**两趟都把证据抹掉**（3 行 → 3 行、`line1` 变新一轮、前缀测试=否）vs 修后**两趟并存**（`wm.progress` 7→10 行、`wm198.progress` 19→21 行、**冻结证据仍是前缀** 345→985 B）；**原件未动**（`a2ee1d7ea5451489`／`e0eb3cb200a5b7f2`，`find ~/w63a -newermt` **只命中那两个脚本**）⇒ `D-G95` 引用的唯一证据行保住了。册内 `D-G96` 条末已追加 dated bullet；**整脚本端到端未跑** ⇒ 那格仍 `NOINFO`。
- 🔁 **`D-G42` 族第二批（**不新增编号**）：真修 8 处／4 件** —— `tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh` `ddb79c4843c0aa3e → **ca0482bda5043909**`（`:988/989/1290`）｜`build/integration-wave.sh` `4d19d69c93ba5927 → **39e52f0049373059**`（`:321/354`）｜`build/MilBridge/tools/frame-presence-check.sh` `03f9800aabfee460 → **d2a1ab5bd2fb06eb**`（`:105/112`；⚠️ **该件无 `pipefail` ⇒ 预防性对齐**）｜`tests/…/run-wpfprobe.sh` `45e46a6d9d90e69b → **6e2e994be056ea10**`（`:568`，**原是牙声明表里的唯一项**）；牙 `build/MilBridge/tools/pipefail-sigpipe-check.sh` `a7d67a7b95b08eae → **078e477a59765091**`（**撤掉那条声明** = **减少豁免、不放宽**；留着会 `decl_stale=1 ⇒ FAIL`）。**成对读数**：`>64 KiB`（**208008 B**）载荷 **旧写法判错 5/5（假 FAIL）／新写法判对 5/5**，两阴性对照两侧一致（**没把红洗绿**）；牙 `undeclared_hit=0`、`declared 1→0`、`hit 1→0`（`sites 83→77`）；`run-wpfprobe:568` 旧 **`IF_RC=141` ×3/3** → 新 **`rc=0` ×3/3**；`shell-quote-trap` 同夹具**逐字相同** ＋ `--selftest` 30/30；**9 件 `bash -n` 全过**。
- ⚠️ **两条判词更正（只加不改）**：① `D-G42` 原声明"**那 4 行诊断被静默丢掉**"**不成立** —— `>64 KiB` 下**诊断照印 4 行**，真后果是 `if` 语句的 **`rc=141` 泄漏**（**潜在**：当时无人消费）；② 引用者注意：`build/MilBridge/tools/{run-wpfprobe,run-wpfprobe-1400rate,run-hellowpf}.sh` **三个路径仓内不存在**，真实件都在 `tests/WpfGfx.Linux.Tests/Presentation.Tests/`。
- 🆕 **射程缺口（并入 `D-G42`，**不新开号**）**：该牙口径**只认 `UNDECLARED_HIT`** ⇒ **同族而机械看不见**至少三类：① 件内**本来没有 `pipefail`** ② **早已修过**的 3 件（件内自记修法）③ `printf \| grep -q` **之外的变体** —— W113A 真修的 8 处正落在"**同族而口径看不见**"这一格。教训同 `D-G97`：**普查射程必须按语义复核（形状 ∧ 承载 ∧ 中毒三要件），不能只看关键词、也不能只看牙的现有口径**。
- 🆕 **新任务 `TASK-0706` [Next] 🔴**：**把"装置/口径卫生"做成常态牙** —— ① 根集合一致性自检（推广到别的"同步器 ↔ 校验器"成对件）② 证据保全（清点全 `$HOME` 里"会截断自己引用的证据"的装置）③ `D-G42` 族**语义射程**复核；**判据先写、三态、`NOINFO` 不算绿**，且**不许**用"写进 `DECL`"转绿。
- ✅ **`TASK-0704` 尾巴收口（只追加）**：该行列的 `~/w63a/bin/wm-leg.sh:13` "重跑即截断自己的证据"**已由 W113A 修掉**（见上 `D-G96` 那条）⇒ **那一格不再是缺口**；该行"四处未端到端跑真脚本"**不变**、仍 `NOINFO`。
- ⚠️ **`inputs_fp` 位移归因（**本件现场机械证**，不是本件造成的）**：覆盖面 **149 件**里**与 fork 克隆 `HEAD` 不同的恰好 4 件** = `check-applocal-sync.sh`／`frame-presence-check.sh`／`pipefail-sigpipe-check.sh`／`integration-wave.sh`（逐件现算：`R` 值 = **修后**值、`HEAD` 值 = **修前**值）⇒ **全部是 W113A 改的那 4 件** ⇒ `inputs_fp` **`58a6c0945b7d5358… → d67880cbb8487cfd…`**（本件现场**真调用**现算，与 W113A §5 报告的改后值**逐字符相同**）。⚠️ **更正 §15g 那句"指纹开工 = 收工"**：那句写于 **21:53**、当时**确实成立**（W113A 的 4 件改动发生在 **22:10–22:12**）⇒ 现在不成立了 —— 位移**归因到 W113A**，而 **W111A 自己编辑的 4 件在覆盖面里命中全 0**（机械证见 `build/MilBridge/W111A-report.md` §8）。

## §15i `#52` 前半段（第九笔）：新登记 `D-G100`（**已修**）＋ `D-G98` 两条"**被证伪**" ＋ `TASK-0111` ＋ `win32shim` 位移（**一行一条**；2026-09-22 车道 W116A 补）

- 🆕 **新登记 `D-G100`（**产品缺陷 · Win32 语义**；**已修**）**：`SetWindowPos(SWP_NOSIZE|SWP_NOMOVE)` 那一次"**本应无副作用**"的调用被落成**真实的 X 几何写**（写的是**窗口表缓存**里的矩形）。**判定点（文件:行）** = 修前源 `src/WpfGfx.Linux.Native/src/win32_core.c`（**`e0cbc965772d06c1`**，本件用 `git show HEAD:<path>` 现算复核）：`:1184-1189`（`nx/ny/nw/nh` **全取自缓存**）→ `:1207`（原样写回 `win->…`）→ **`:1210` 无条件** `wpf_x11_move_resize(...)`；**对照** = 紧邻的 `P2` 那拍（修前 `:1214-1215`／盘上修后态 `:1234`，= `1214+20`，与 `-1/+21` 相符）**有** `!(flags & SWP_NOSIZE)` 守卫 ⇒ **同一条路径上只有这一处 X 写没有守卫**。**修法**（车道 **W114A**，波 `#52`）= `if (!((flags & SWP_NOSIZE) && (flags & SWP_NOMOVE))) wpf_x11_move_resize(...)`。**成对读数（确定性、逐腿 100%）** = 来自 `SetWindowPos` 帧的 X 几何写 **6 条/38 腿 → 1 条/16 腿**（消失的正是 5 条 `a=567`×4＋`a=55`×1）；`[SHOW_DIAG]` 逐趟 9 行修前修后**逐字相同**；**零回归** = `D-G83` 四格全绿 ＋ `R-GATE crit=13/13` ＋ 导出 **547** 不变；**反极性源级＋件级双向闭合**。⚠️ **它不修 `D-G98`**（修后那族照样红，Fisher 双尾 `p = 1.00`，且红腿全趟只剩 1 条启动期 `XMoveResizeWindow` 仍被打回）—— **不许**读成"`D-G98` 的一部分被修好了"。
- 🆕 **`D-G98` 追加两条"**被证伪**"（判词原文一字未动，只追加 dated bullet）**：① **"那次多余几何写是 `D-G98` 的成因"不成立**（删掉之后照样红 ⇒ **连必要条件都不是**，它是**后果/读数**）；② **`W112A` §5.5 那条相关系数（`p=0.067`）是混淆的**、**不许**当证据引用。同趟另加：**新首选嫌疑**（还原那拍 `SWP_FRAMECHANGED` 顺手重写的 `_MOTIF_WM_HINTS`：值"幂等"、**X 流量不幂等**；**待 W115A 验**）＋ **功效教训**（6% 红率下 **≥40 腿/臂**；`R2 4/30`／`2/16`／`1/17→1/16` 三次并列）＋ **一条判据级更正**（`r_ok` 是**结果计数**、**独立落地证据是 `L`**；新判据 = 三类判别式 ＋ `SUB=i/ii/iii` ＋ `L`，**可并入 `D-G94`、不新号**）。
- 🆕 **新任务 `TASK-0111` [Next] 🔴**：**`_MOTIF_WM_HINTS` 那一跳的落地** —— **先决条件逐字 = 待 W115A**（纯 X 高功效探针、每臂 **≥200 趟**，钉"这次属性重写是不是**被打回**的必要条件"；本件写成时 `W115A` 报告**不存在**）；**分支 A（必要性成立）= "值没变就不写该属性" ＋ 反极性 ＋ 零回归 ＋ ≥40 腿/臂成对**；**分支 B（不成立）= 撤号或改写为"剩余候选"**。
- ✅ **地图更新（本件只追加；`TASK-0110` 行**未**转 ✅）**：`TASK-0110` 状态位 **`🔴 → 🟡`**（真因**部分定位／部分证伪**、缺陷**仍红**、新嫌疑**正在验**）＋ 收口行；**"缺哪一格"逐字** = ①"**被打回的那条客户端请求到底是哪一条**"**仍无答案**（`D-G98` 的 `NOINFO` 第 1 条）②"**≥40 腿/臂**的成对读数"**未取**（`D-G99` 的口径）。
- 🔁 **`TASK-0111` 的状态与顺序（**主控裁定 · dated；车道 W122A，2026-09-23**；**裁定依据 = 引 `W115A` 的成对读数**，逐字见 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G98` 新追加 bullet）**：**① 先落 `N3`** —— 把**归因面**从"几何写"扩到 `XChangeProperty`／`XSendEvent`／`XSetWMNormalHints`／`XSetInputFocus`／`XRaiseWindow`…，并**在红腿上对齐**；**② `N1` 暂缓** —— **依据（引 `W115A` 成对读数）**：属性写对几何**零贡献**（`hints` 臂 **`0/136`**、`Fisher(hints vs none) = p = 1`）⇒ 先落 `N1` 只会拿到"**红率不变**"的空结果。⚠️ `TASK-0111` 状态位**仍 `🔴`**、**不许**写成 ✅（结论未出）。⚠️ 上面 §15i 那句"**先决条件逐字 = 待 W115A**"**照旧成立**（本件只在它旁边记裁定，**原话一字未动**）。
- ⚔️ **跨车道冲突待解（主控追问）**：`W115A` 的 `maxhint`／`maxhint+oversize` 读数（`maxhint` **`0/120`**、`maxhint+oversize` **`0/119` 判 `OTHER-GEOM`**，停在 `1580x1324`）⇒ 读作"**这套 `xfwm4` 不强制 `PMaxSize`**"；而 `W93A` 的 **`H2-b`**（`xdotool windowsize 1000x800` ⇒ **被压回 `667x500`**，且"**拖边框也拖不大**"）⇒ 读作"**WM 严格执行提示**" —— **两句不能同时为真**。**正在由 W115A 用同屏同配方并排量**（含"**提示声明方式** vs **`xdotool` 量法** vs **`xprop` 读值**"三格）⇒ **结论未出前，两句话都不许当已定**。⚠️ `W115A` 报告 §5 只自报了"与 `D-G88` 不冲突"（`D-G88` 说的是**提示到不了 X**），**没有**处理与 `H2-b` 这一格 ⇒ 这一格**确实待解**。
- 🔁 **`TASK-0111` 要件补正（**主控裁定 · dated；车道 W122A，2026-09-23**；上面 §15i 与 §15k 的登记**一字未动**，本条**补正**它们；依据 = `W115A` **收工终值**，见 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G98` 新追加 bullet）**：**① `N3` 先做，且必须加一格** = 「在**红腿**上当场 `xprop -id <client> WM_NORMAL_HINTS`，直接比"**应用声明的 `min`／`max` 是否恰好等于它被打回后停住的几何**"（**一格定罪**）」—— 因为 **`D-G98` 的首选成因已改为"应用那份过期的尺寸约束挡住还原"**（接上 `D-G88`），而**"应用侧运行期的 `WM_NORMAL_HINTS` 实际值从没读过"** ⇒ 这一格**就是缺口本身**（**正在由车道 W124A 补**）。**② `N1` 撤销/暂缓**，**理由逐字**：「`N1` 只'少发一次相同的值'，**撤回不了已发布的过期上限/下限** ⇒ 若成因是过期约束，`N1` **解不掉** `D-G98`；该先做**能撤回/刷新上限的那一半**（`W93A` 的 `P1`–`P3` 族）」。⚠️ `TASK-0111` 状态位**仍 `🔴`**（**不许**写 ✅）；⚠️ 上面 §15i 那句"**先决条件逐字 = 待 W115A**"**现已满足**（`W115A` 已收工：报告 **`15dcc9219a7ce455`**、**514 行**）⇒ 但**因为①那一格未取**，本行**仍不转 ✅**。
- ✅ **"跨车道冲突待解"收口（**只追加，上面那句一字未动**）**：`W115A` 先前报的「本机这套 `xfwm4` **不强制** `PMaxSize`」**已由它自己撤回** —— **真因 = 它仪器的 `:251` `if (!strcmp(arm, "maxhint"))` 只判 `"maxhint"`、而臂名是 `"maxhint+oversize"` ⇒ 该臂从未声明过 `PMaxSize`**（现场 `xprop` 只有 `minimum size: 1 by 1`）。修正后 `maxhint+oversize` = **`n/n` 被打回**（`Fisher p = 8.57e-10`）、`XResizeWindow` 与 `xdotool windowsize` **同结果** ⇒ **那个冲突是自造的（`W115A` 仪器缺陷），`W93A` 的 `H2-b` 成立、已平反**。⇒ **上一条"结论未出前两句话都不许当已定"到此解除**（现已定：**`H2-b` 那句对**）。该仪器缺陷已**独立立号 `D-G102`**。
- 🔁 **`#52` 前半段的产品位移（口径句；后续引用者按这句判"要不要重冻"）**：**只有 `win32shim` 一位** —— `8392fc09564779a1 → **bd037229be8db4f6**`（源 `win32_core.c` = `e0cbc965772d06c1 → **3117923a7c899e05**`／`win32_x11.c` = `6477af56fdcfdf20 → **11142fbef049eb66**`；导出仍 **547**），性质 = **独立卫生修**（对齐 Win32 语义）、**不修 `D-G98`**；**其余八位与 `#51` 逐位相同** ⇒ **收尾链必须重钉世代（`repin-generation.py --why`）＋ 重冻 `#52`**。
- ⚠️ **`inputs_fp` 现值与位移归因（**本件现场机械证**）**：⚠️ **现在必然 ≠ `#51` 冻结时的值**（`src/WpfGfx.Linux.Native/**/*.c|*.h` **在 `close-wave.sh` 的 `fp_inputs()` 覆盖面内**）。本件现场**真调用** = **`72c5f2263f62a83d301f0852edcb049825e51be09e5646cad55274ba91e48015`**；把覆盖面里"与 fork `HEAD` 不同"的件**逐件换成 `HEAD` 版**再算（**只换内容、不换路径**，机械证）⇒ 先只换两件 native 源 = **`d67880cbb8487cfd…`（＝ `§15h` 记的 W113A 后值，逐字符相同）**，再连 W113A 那 4 件一起换 = **`58a6c0945b7d5358…`（＝ `§15g` 记的 `#51` 值，逐字符相同）** ⇒ **位移 100% 归因到 W113A 的 4 件（尚未推）＋ W114A 的 2 件 native 源**；而**本件编辑的 4 件**（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/W116A-report.md`）**在覆盖面里命中 0**（现场 `grep` 逐个 = 0）。⚠️ **另发现（只报不改）**：W113A 改的那 4 件**在 fork 克隆 `HEAD` 里仍是改前内容** ⇒ **尚未推**；本件按任务书只推本笔列明的件，**不代 W113A 补推**（那 4 件是产品/门禁件，**裁定权在主控**）。

## §15j `#52` 第十笔：`TASK-0705` 收口复核（含一处**数字更正**）＋「回归判定四要件」口径澄清**落两处** ＋ 两行指针 ＋ `TASK-0706` 进行中（**一行一条**；2026-09-22 车道 W120A 补）

- ✅ **`TASK-0705` 收口复核已落行**（`:435` 的 W117A 登记段下**只追加**，原登记一字未动）：四要件逐条复核（① 落地点 `docs/PREREG-TEMPLATE.md` ＋ 三条判定依据全否 ＋ "为什么不是别的件"；② 牙 `regression-decision.py` 三态／`rc`／被四条历史读数钉住；④ 两口径并列；⑤ **仍"未接线"**）＋ ⚠️ **一处数字更正**：`:438` 写的 `--selftest` **`20/20 PASS`** 现场重取 = **`22/22`**（`REGDEC_SELFTEST=PASS total=22 pass=22 fail=0`、`rc=0`、两趟逐字相同）—— 原文**一字未动**、只在本段旁边的追加 bullet 里更正。**机器证**：`docs/ROUTES.md` `539 → 564` 行、改前独有行 = **0**。
- 🔴 **口径澄清 —— 本件的裁定（落两处，原话一字未动，只追加 dated 澄清）**：**冲突点** = `:431`（同 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2651`）的 ③ 原话「**在旧件上也要能复现该红 ⇒ 只有新件上红不足以判回归**」vs 本行反极性要的「**确定性 new-only ⇒ 必须判 `REGRESSION`**」，**按字面互相排斥**。**裁定 = 两句回答不同问题、按条件分派**：**(a)** 只有"一腿一个样本" ⇒ 旧件不复现 ⇒ **`NOINFO`**（原话要的就是这条）；**(b)** 「**先写的计划** ＋ **达到所需 `N`**（**功效口径**：`6% vs 0%` ⇒ `131` 趟/臂）＋ **显著**」三条**同时满足** ⇒ **new-only 也必须判 `REGRESSION`**；**(c)** 旧件**也复现** ⇒ **不是本波引入**：`OK`，或按率加重判 `REGRESSION(rate-aggravated)`。⇒ `W117A` 的**操作读法成立**（原话是**小样本特例**、**不是被推翻**）。⚠️ 澄清里**点名"原话不许改、只在旁边加条件"**。
- 📌 **两行指针已补**（W117A 点名欠账；**只加一行 ＋ 行锚定 ＋ 改后 `wc -l` 复核**）：`docs/PORT-SPEC.md` **`98 → 99`**（`§1` 第 1 条下子条）｜`docs/INDEX.md` **`52 → 53`**（`§1 规范`表新行）—— 两件都指名 `docs/PREREG-TEMPLATE.md` 为「**预登记四要件（回归判定）的权威处**」。**只加不删机器证**：两件改前独有行 = **0**。
- 🚧 **`TASK-0706` 追加"进行中（车道 W119A）"一行**（只追加；**状态位未动**、仍是 `🔴`）：三合一常态牙（根集合一致性／证据保全／口径语义射程），三态 ＋ **五例两极化**自检，**不接线**。
- **`DEFREG` 两条机读行（现场跑两遍、逐字相同、`rc=0`）**：`DEFREG=PASS declared=136 route_ids=136`｜`DEFREG_DECLDRIFT=0`（因本件动了册 ⇒ **同趟 `--emit` 重生成**声明表：`build/MilBridge/tools/defect-registry-declared.tsv` `934a29ed9ab399ab → dea8c731369ba0ed`，**ID 数 136 不变**、`diff` 只动 `DECL-GEN` 时间戳与 `KD` 锚）。
- ⚠️ **硬链接警戒（本件新发现，只报不改）**：`docs/PORT-SPEC.md`／`docs/INDEX.md`／`build/MilBridge/known-red.json`／`build/MilBridge/tools/defect-registry-declared.tsv` 等件与 **`$HOME/w62a/negrepo/**`（负控夹具）同 inode**（如 `PORT-SPEC.md` `inode 5000462 links=2`）⇒ **原地截断写会顺着共享 inode 改到夹具**（历史血案的同族、方向相反）。本件一律 **temp ＋ `rename`** 落盘，并**成对复核孪生件 sha16 未动**。
- **`fp_inputs` 零影响（机械证）**：现场**真调用** `fp_inputs()` = **`72c5f2263f62a83d…`**（＝ `§15i` 记的现件值，逐字符相同），覆盖面 **149 件**里本笔 9 件**命中全 0** ⇒ 本件贡献为零。
- **推送（第十笔）**：head 与 `BYTECHECK` 逐字见 `build/MilBridge/W120A-report.md` §6（本件**不推**别家在飞件：`win32_core.c`／`win32_x11.c`／`run-wpfprobe.sh`／`run-wpftextdemo.sh`／`sync-applocal-authority.sh`／`W115A-report.md`／`hygiene-tooth.sh` —— **只报不推**）。

## §15k `#52` 第十一笔：新登记 `D-G101`（**登记件与仓外夹具同 inode**）＋ 新 `TASK-0707` ＋ 三处裁定（口径复核／数字更正点名／`TASK-0111` 顺序）＋ 跨车道冲突待解（**一行一条**；2026-09-23 车道 W122A 补）

- 🆕 **新登记 `D-G101`（装置缺陷 · 登记件与仓外夹具同 inode）**：`$R` 的判据/登记件与 `$HOME` 下的**负控夹具硬链接同一 inode** ⇒ **原地截断写（`> 件`／`sed -i`／`--emit > 件`）会顺着共享 inode 写坏别人的夹具**（**方向与 `D-G80` 相反**：那条坏在"**读到旧的**"，这条坏在"**写坏别人的**"）。**判定点 = `stat -c '%h %i %n'` ＋ `find ~ -xdev -inum`**；**射程 = 全树普查**：`$R` **13374** 件里 **`links>1` = 12432 件（93.0%）**、**全部**在 `$R` 外有孪生件（`$R` 内部自链 = **0**），区分布 = `~/w62a/negrepo` **12407**／`~/w113a/fixture/fp-farm` **150**／`~/w26d-G9` **6**／`~/w110a` **5**；**五件"绝对禁区/冻结件"仍在链上** = `ACCEPTANCE-BASELINE.md`（`inode 4983625 links=2`，**冻结基线本体**）／`docs/CURRENT-STATE.md`（`5260312 links=2`）／`handoff.md`（`5260310 links=2`）／`build/close-wave.sh`（`5018638 links=2`）／`known-red.json`（`5251064 **links=3**`）＋ `defect-registry-check.sh`（`5254340 links=3`）。**本次未被触发**（W120A 一律 temp ＋ `rename`，三个孪生夹具件 sha16 开工 = 收工）；**教训 = 落盘一律 temp ＋ `rename`**，涉及"传件进夹具"的实验**必须先查 inode/links**。落地 = **`TASK-0707`**。
- 🆕 **新任务 `TASK-0707` [Next] 🔴**：**把"硬链接/同 inode 共享"并进装置卫生牙** —— ① 列 `links>1` 的件 ② 列**跨区同 inode 对**（`$R` ↔ `$HOME` 夹具区）③ 对登记夹具件做"**开工 = 收工 sha16**"可复算断言；三态（`FAIL` 点名／仅 `links>1` 无跨区 ⇒ **只报行不判红**／查不动 ⇒ `NOINFO`）＋ `--selftest` **两例两极化**（造硬链接对 ⇒ 必红；改 temp ＋ `rename` ⇒ 回绿）。**正在由车道 W119A 实现**（主控把这一类追加给它）。
- ⚖️ **裁定一 · 口径澄清复核（只追加；两处澄清原文一字未动）**：**两处同文** = `docs/ROUTES.md:432-436` 与 `samples/WpfFeatureProbe/KNOWN-DEFECTS.md:2652`（关键子句两处各命中 1 次）；**原话未改** = 地图 `:431` 与册 `:2651` 的 ③ 原话**都仍在**、逐字未动；**改前独有行 = 0** = 该笔 `git diff` **删行数 0**（本件现场复算）。⚠️ "**原话不许改、只在旁边加条件**"**照样成立**。
- ⚖️ **裁定二 · 数字更正的点名（只追加）**：`W120A` 的更正 bullet 里"**上一行**"**没点名** ⇒ 本件**追加一句点名**：被更正的那一行 = **`docs/ROUTES.md:443`**（**W120A 动手前 = `:438`**）；**追加前**全件 `grep -nF '20/20'` = **3 命中**（`:443`／`:449`／`:557`），**只有 `:443` 是"登记错值"那一行**、另两处是**更正 bullet 的引文**。⇒ 引"错值"时**按 `:443`（改前 `:438`）**。**原文一字未动**。现场复算：`REGDEC_SELFTEST=PASS total=22 pass=22 fail=0`、`rc=0`、两遍逐字相同、`ST_ATTEST=PASS`（`sha16=1eda9e3575960cba`）⇒ **正确值 = `22/22`**。
- ⚖️ **裁定三 · `TASK-0111` 的状态与顺序**：**先落 `N3`、`N1` 暂缓**（依据 = 引 `W115A` 成对读数：属性写对几何零贡献、`Fisher(hints vs none) = p = 1`）；**状态位仍 `🔴`、不许写 ✅**；**原"先决条件逐字 = 待 W115A"一句照旧**。
- ⚔️ **跨车道冲突待解（主控追问）**：`W115A`（`maxhint` **`0/120`** ⇒ "**不强制 `PMaxSize`**"）vs `W93A` `H2-b`（`xdotool windowsize 1000x800` ⇒ **`667x500`** ⇒ "**严格执行提示**"）**不能同时为真** ⇒ **W115A 用同屏同配方并排量中，结论未出前两句话都不许当已定**。
- 🆕 **`D-G98` 追加一段（内容由主控转来 `W115A` 的中间结论，判词原文一字未动）**：纯 X 三臂 `none`／`hints`／`hints+geom` ＋ `maxhint`／`maxhint+oversize` 成对读数；**五项要件逐字**（① `hints` `0/N` ⇒ "该写本身造不出被打回"**成立**；② 必要性 `NOINFO`、**不许读成"不必要"**；③ 支持的是"**被打回必须有一次客户几何请求、属性写可有可无**"；④ "**必须属性写＋几何写同时发生**"**无支持读数**（**既不许写"已证伪"也不许写"成立"**）；⑤ 与 `W114A` 的关系**逐字照抄**"**两个层面的排除互相咬合**"）。⚠️ **读数漂移已如实记**：主控转来的快照是 `144/臂`／`130/130`，本件现场读该报告 §4 表已是 `137/136/136/120/119`，且该报告**自标两批仍在跑**（`:182` 368/600、`:183` 198/400）⇒ **两组数都只是快照**、结论不因计数变化 ⇒ 引本条**必须带"读于何时 ＋ 报告哪一版"**。
- 🔁 **`#52` 位移口径（本件不改前文，只记"本件未动任何产品件"）**：本笔**零产品件改动** ⇒ `win32shim`／`pf` 等九位**逐位不变**；**收尾链"重钉世代 ＋ 重冻 `#52`"的要求照旧**（依据 = `§15i`）。
- **`DEFREG` 两条机读行（现场跑两遍、逐字相同、`rc=0`）**：`DEFREG=PASS declared=137 route_ids=137`｜`DEFREG_DECLDRIFT=0`（因本件动了册 ⇒ **同趟 `--emit` 重生成**声明表，**ID 数 136 → 137，恰好 +1**）。
- ⚠️ **硬链接警戒（本件把 `§15j` 那一行**扩成全树普查**，仍**只报不改**）**：W120A 记的 4 件只是**冰山一角** —— 真正的射程是 **12432/13374 件（93.0%）**，且 **`ACCEPTANCE-BASELINE.md`（冻结基线本体）／`CURRENT-STATE.md`／`handoff.md`／`close-wave.sh`／`known-red.json`／`defect-registry-check.sh` 都还在链上**；**本件一律 temp ＋ `rename`**，并在收工用 `stat` ＋ sha16 **成对证明**没写穿任何夹具件。
- **`fp_inputs` 零影响（机械证）**：本笔编辑的 **4 件**（`samples/WpfFeatureProbe/KNOWN-DEFECTS.md`／`docs/ROUTES.md`／`build/MilBridge/tools/defect-registry-declared.tsv`／`build/MilBridge/W122A-report.md`）在覆盖面里**命中全 0** ⇒ 贡献为零；**现值如实点名**（见 `build/MilBridge/W122A-report.md` §7）。
- **推送（第十一笔）**：head 与 `BYTECHECK` 逐字见 `build/MilBridge/W122A-report.md` §6（本件**不推**别家在飞件：`hygiene-tooth.sh`／`W115A-report.md`／`W118A-report.md`／`W119A-report.md`／`W121A-report.md`／native 源与产品件／`tests/parity/**` 大件 —— **只报不推**）。

## §15l `#52` 第十一笔续：`TASK-0706` 收口 ✅ ＋ 新 `TASK-0708`（**仪器波**）＋ `D-G76` **有意降级正式声明** ＋ `D-G75` 追加（**一行一条**；2026-09-23 车道 W122A 补，内容由主控转来车道 **W121A** 的仪器）

- ✅ **`TASK-0706` 转 ✅（车道 W119A 交牙）**：`build/MilBridge/tools/hygiene-tooth.sh` **`dc1e79a23dbb7eb2`**（**1626 行**，纯静态读、零 `dotnet`、未接线）＋ 报告 `build/MilBridge/W119A-report.md` **`685eaa58fe8072a2`**（**414 行**）；`--selftest` **67/67**（`ST_ATTEST=PASS`）。⚠️ **状态位 `🔴 → ✅` 是本件唯一的"就地改字"，且逐字节差异只有那一个状态字符**（本件现场 `git diff` 核：该行**除 emoji 外逐字相同**）；其余一律**只追加**。
- ⚠️ **`HYGIENE_TOOTH` 的读数在移动靶上**：主控转来的**断链前**快照 = `HYGIENE_TOOTH=FAIL roots=PASS evidence=PASS inode=FAIL scope=REPORT semantic_undecidable=7` ＋ `multilink=1388 cross_region=1383 ext_ext_hits=0 code_files=72`；本件现场重取 = `HYGIENE_TOOTH=PASS … inode=PASS … multilink=0 cross_region=0 … code_files=72`、**`rc=0`**（`W123A` 断链已生效）⇒ **两个读数都要带"读于何时"**。**`HYGIENE_SCOPE` 恒为 `REPORT`**（含 `semantic_undecidable=7`）⇒ **`PASS` 只等于"登记表内可判部分一致 ＋ 仓内截断写证据 = 0"，不等于全域干净**。
- 🆕 **新任务 `TASK-0708` [Next] 🔴**：**"仪器波"** —— 把四件新牙（`HYGIENE`／`REGRESSION-DECISION`／`UIA-DOOR`／`IME-LANDING`）接线，`verify-all.sh` **四处声明同趟改、`27 → 31` 步**；⚠️ **其中 `UIA-DOOR` 今天故意红、`IME-LANDING` 靠降级声明才绿** ⇒ **不能直接 `run_step`**，须走仓内"**在册红**"形态（`tline-gate.sh:1302` 的 `GATE_REASON=all-as-registered`；`known-red.json` 加 `entries[]` ＋ `repin-generation.py --why` ＋ `--check` 须 `REPIN_GENERATION=PASS`）；⚠️ 纳入 `fp_inputs()` ⇒ **必须排在 `IN_FP_0`（`close-wave.sh:202`）之前**；⚠️ **本波 `#52` 不接**（**主控裁定**：避免与 `D-G100`／`D-G101` 叠加成多变量）。
- 🔴 **`D-G76` 追加"有意降级"的正式声明（主控裁定，逐字落册）**：`GetSystemMetrics(SM_IMMENABLED=82)` 恒返回 0 **是有意降级**（决定人 = 主控；`imm32.dll` **未映射**、MVP 不做 IME）⇒ 它**不得**被"顺手补成 1"。⚠️ **绿 ≠ 有能力**：登记后 `IME-LANDING` 牙会转 `PASS`，那**只表示"这份降级已在册且被声明"**、**不表示 IME 可用**（`landings=0` 仍为事实）—— **这句在本行写死**。**成对读数（本件现场跑）**：改前 `IME_LANDING=FAIL landings=0 declared=no ctrl=5 sm82_nonzero=0 shim_map=0 so_syms=0 decl_hits=0 reason=[door-not-declared]`（`rc=1`）→ 改后见 `build/MilBridge/W122A-report.md` §10。⚠️ **本件按那件牙的 `IME_DECL_*` 词表写措辞，不改词表**（词表就是它的判据）。
- ✅ **`D-G75` 追加一行**：UIA 牙 `build/MilBridge/tools/uia-door-check.sh` **`d8f23e91ade01453`**（**926 行**）已把"**无门／门后断头**"做成**会变红的仪器**（本件现场跑 `UIA_DOOR=FAIL prod=0 consume=1 core_shim=0 uia_syms=0 ctrl_syms=8 live_calls=2 (all=69) libs=1`、`rc=1`，**而这是设计**；装门 ⇒ `PASS`／拆门 ⇒ 回红；`--selftest` **38/38**）⇒ **不登记为在册红、本波不接线**（接线 = `TASK-0708`）。
- **`DEFREG` 两条机读行（现场跑两遍、`cmp` IDENTICAL、`rc=0`）**：`DEFREG=PASS declared=137 route_ids=137`｜`DEFREG_DECLDRIFT=0`（本续笔**不动册的编号集** ⇒ `--emit` 重生成后 ID 数**仍 137**）。

## §15m `#52` 第十一笔续三：`D-G98` **首选成因改写** ＋ `W93A` `H2-b` **平反** ＋ 新 `D-G102` ＋ `TASK-0111` 要件补正（**一行一条**；2026-09-23 车道 W122A 补，内容由主控转来车道 **W115A** 的收工终值）

- 🔴 **`D-G98` 追加（收工终值，判词与上一条追加一字未动）**：出处 `build/MilBridge/W115A-report.md` **`15dcc9219a7ce455`**（**514 行**）｜判据 `~/w115a/criteria.md` **`80fbbbb29c544e39`**。**主批跑满 `200`/臂**：`none` **`0/200`**｜`hints`（只重写 `_MOTIF_WM_HINTS`、值逐字节不变）**`0/200`**（95% 单侧上界 **`1.49%`**）｜`hints+geom` **`200/200`**（vs `none` **`p = 1.943e-119`**）。**① 首选成因改为「应用那份过期的尺寸约束挡住还原」（接上 `D-G88`）**；两条**纯 X 机制**（都不需要 `_MOTIF_WM_HINTS`）= **(i)** `PMaxSize` ＋ 超上限请求 ⇒ **先回基准再被夹到上限**（`n/n`、`p = 8.57e-10`）；**(ii) ★`PMinSize` 钉在最大几何 ⇒ WM 拒绝任何收缩、连客户端请求都不需要**（`PMinSize = PMaxSize = 1280x1024` ⇒ 探针自己的收缩请求都被拒）。⇒ 与 `W93A` `H2-b` 合起来 = **"被打回"既不需要几何写、也不需要属性写**。**② 最后一跳仍未证 ⇒ `NOINFO`**（**应用侧运行期的 `WM_NORMAL_HINTS` 实际值从没读过**；**正在由车道 W124A 补**：红腿上当场 `xprop -id <client> WM_NORMAL_HINTS` 与"停住的几何"逐字比对 ⇒ **一格定罪**）。**③ 属性写那条线彻底降级**：必要性 **`NOINFO`**、**充分性被证伪**（`0/200` vs `200/200` ⇒ **零贡献**、`p = 1`）⇒ 原"必须属性写＋几何写同时发生"**照旧"无支持"，并补"充分性亦被证伪"**（**既不许写成"已证伪"整句、也不许写成"成立"**）。**④ `W93A` `H2-b` 正式平反**：见下条收口。
- ✅ **`W93A` `H2-b` 平反（"跨车道冲突"收口）**：`W115A` 先前那句「本机这套 `xfwm4` **不强制** `PMaxSize`」**已由它自己在 §5.1.0 勘误里撤回** —— **真因 = 它仪器 `:251` 的 `if (!strcmp(arm, "maxhint"))` 只判 `"maxhint"`、而该臂臂名是 `"maxhint+oversize"` ⇒ 条件恒假 ⇒ 该臂从未声明过 `PMaxSize`**（现场 `xprop` 只有 `minimum size: 1 by 1`）。修正后 `maxhint+oversize` = **`n/n` 被打回**（`p = 8.57e-10`）、`XResizeWindow` 与 `xdotool windowsize` **同结果** ⇒ **冲突是自造的，`W93A` 的 `H2-b` 成立**。⚠️ **本件现场核**：主控转来的 `61/61`／`p=5.218e-36` **在本件读到的该报告里未出现**（报告现值为 `n/n`／`8.57e-10`）⇒ **如实记"未复现那两个字面值"**。
- 🆕 **新登记 `D-G102`（仪器缺陷 · 臂名与动作不匹配 ⇒ 整臂静默空转）**：按**字面量**选动作的仪器，**臂名与分支字面量不一致** ⇒ 分支**恒不执行** ⇒ **该臂从未做过它自称的事，而输出看着正常**。本实例 = `W115A` 的 `motifprobe3`（`:251` 只判 `"maxhint"`、臂名是 `"maxhint+oversize"`）⇒ **结论被反向得出并已写进报告**（"不强制 `PMaxSize`"），**已撤回**。**教训 = 每个臂必须有"我确实做了那件事"的现场自证（`xprop` 读回／`LD_PRELOAD` 命中计数／行号级打点），拿不到 ⇒ 记 `NOINFO`**。同族 = `D-G93`／`D-G94`／`D-G97`（**判据认错对象**族），但本条坏在"**仪器根本没执行它自称的那个动作**" ⇒ **独立立号**；交叉引用 `D-G87`／`D-G84`／`D-G80`。
- 🔁 **`TASK-0111` 要件补正**：**`N3` 先做，且必须加一格** = 「在**红腿**上当场 `xprop -id <client> WM_NORMAL_HINTS`，直接比"**应用声明的 `min`／`max` 是否恰好等于它被打回后停住的几何**"（**一格定罪**）」；**`N1` 撤销/暂缓**，理由逐字：「`N1` 只'少发一次相同的值'，**撤回不了已发布的过期上限/下限** ⇒ 若成因是过期约束，`N1` **解不掉** `D-G98`；该先做**能撤回/刷新上限的那一半**（`W93A` 的 `P1`–`P3` 族）」。⚠️ 状态位**仍 `🔴`**（①那一格未取 ⇒ **不转 ✅**）。
- **`DEFREG` 两条机读行（现场跑两遍、`cmp` IDENTICAL、`rc=0`）**：`DEFREG=PASS declared=138 route_ids=138`｜`DEFREG_DECLDRIFT=0`（新号 `D-G102` ⇒ `--emit` 重生成，**ID 数 137 → 138，恰好 +1**）。
- **推送（顺延笔）**：head 与 `BYTECHECK` 逐字见 `build/MilBridge/W122A-report.md` §12／`~/w122a/STATUS.md`（本件**不推**别家在飞件）。

## §15n `#52` 冻结收口批：`TASK-0707` 转 ✅ ＋ `TASK-0203` **封口裁定** ＋ 新登记 `D-G103`…`D-G107` ＋ 方法学四条（**一行一条**；2026-09-23 车道 W127A 补）

- 🆕 **冻结信号（握手，先写后跑）**：本批**只在见到** `docs/CURRENT-STATE.md:9` 由 `gen=#51` 变 **`gen=#52`**（且 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md` 随之位移、`w126a`／`verify-all`／槽进程**全退出**）之后才动册/地图/声明表；每次轮询一行入 `~/w127a/STATUS.md`（读数逐字见该件）。⚠️ **未冻结时改册会让 `verify-all` 第 `[16]` 步 `DEFECT-REGISTRY` 出现瞬时红**（打乱"冻前恰好 1 处声明类红"）⇒ 宁可超时零写入。
- 🔴→✅ **`TASK-0707` 状态位修正（**行锚定**改法，只改状态位那一段；下面 W122A 的登记 bullet 一字未动）**：它实际**已由车道 W119A 做掉** —— 牙 = `build/MilBridge/tools/hygiene-tooth.sh`（**`dc1e79a23dbb7eb2`**，**1626 行**，`--selftest` **67/67**）的**第四类检查 = 硬链接/同 inode 共享**已在件内落地（`HYGIENE_INODE=` 分项；`--selftest` 含 **`S16a`**（真硬链接 × 原地写 ⇒ **必红**）／**`S16b`**（改 temp ＋ `rename` ⇒ **回绿且仍打印 `links>1`**）／**`S16c`**（形态抽不出 ⇒ **`NOINFO`**））⇒ 三条格（列 `links>1` ／ 列跨区同 inode 对 ／ 三态）**全部落地**。
- ✅ **`TASK-0707` 收口读数（主控现场复核；本件只登记）**：`HYGIENE_INODE=PASS multilink=0 cross_region=0`。**断链总账（车道 W123A）**：`1421`（登记件）＋ `6`（产品 DLL）＋ `4588`（`bin/obj`）= **`6015`**；再加 **`6417`**（`upstream/` 声明残留、**无写者**）= **`12432`** ＝ **开工时原始跨区共享数**。
- ⚠️ **口径句（必须与上面那条同读，防把"牙的 0"读成全树干净）**：牙的 `multilink` **只覆盖它自己的 `HYG_SKIPDIRS`**（含 `obj bin upstream __pycache__`）⇒ **牙的 `0` ≠ 全树干净**；三个数 **`1388`／`1421`／`12432`** 是**三种口径**，差 **33** 全在 **`__pycache__/`**。
- 🟡 **`TASK-0203` 收口裁定（**状态位保持 🟡、不许转 ✅**；车道 W118A 追加批，报告 `build/MilBridge/W118A-report.md` 终值 `head -n -2 | sha256sum | cut -c1-16` = **`a22eb8a7881e01ba`**，§14–§19 **只追加、未覆盖旧结论**；判据追加节 `~/w118a/criteria.md` **`110b44e10788287d`**，**先写后跑**）—— 六条逐字：
  ① **追加批 41 趟**（`134`×**40** ＋ 1 趟异常）**`139` = 0**；**阳性对照 4/4 成立** ⇒ **整批不作废**（`POSCTRL_CONTROL_ALIVE=2/2`、`POSCTRL_PREFIX_134=40/40`）。
  ② **唯一被外部打断的趟点名剔除**（**`G20301`**：`APP_RC=0`／`app.err` **0 B**／只一个良性停点 `si_addr=0x0`／**死在 10 s、只落地 2 击**，而产品崩**必须**走到第 **7–8** 击之后）⇒ 分母 **41→40**。
  ③ **上界重算**：本批 **0/40 ⇒ 95% 单侧上界 `7.28%`**；本装置合并 **0/61 ⇒ `4.86%`**；与 `W98A` **同件同腿**合并 **`1/121 ≈ 0.83%`**（**`W98A` 的 `1/60 = 1.7%` 本批未复现** ⇒ 两批不矛盾，但点估计**减半**）。
  ④ **归因仍 `NOINFO`**：**`139` 本体的故障栈取不到** ⇒ 既不算绿也不算红；`134` 侧**已闭到栈底**（19 趟全崩在主线程 8 MB 栈底、`si_addr` 只低 `-4…-216` B、12 趟独立重建同一条 21 帧回声环），**但那是 `134` 的机制，不是 `139` 的**。
  ⑤ **主控裁定：`TASK-0203` 就此封口、不再投 ≈175 趟 ≈1.7 槽小时**（要投由用户拍板）。
  ⑥ 出处三样齐：报告 **`a22eb8a7881e01ba`**（`W118A-report.md`）＋ 判据 **`110b44e10788287d`**（`~/w118a/criteria.md`）＋ 机读台账行（`STAGE=BATCH41_APPROVED;ATTEMPTED=41;EXCLUDED_EXTERNAL=1;VALID_N=40;RC139=0;UB95_BATCH=0.0728;POOLED_UB95=0.0486;VERDICT=NOINFO`）。
- 🔁 **`TASK-0203` 追加（车道 W128A 中途交数，2026-09-23）**：`139` 族的归因**已从 `NOINFO` 推进到"异源 ＋ 具名判定点"** —— ① 线程 **`.NET Finalizer`（`tid=6`）** vs `134` 恒 `tid=1`；② 栈深 **`7,088 B`**（浅）vs **`8,388,672 B`**（满 8 MB 栈底）；③ **无环**（`R1_CYCLE=False`／`R2_SAMESET=False`；`134` 族 12/12 全 True）；④ **应用输出 0 字节**（= `W98A` `L1B024` 形态）。**判定点（反汇编级）** = `PC wpf_queue_push+259`（`libwpfwin32.so+0x11df3`）`mov 0x38(%rax),%rax`，回溯 `PostMessageW` ⇒ `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82` 的非法队列自愈分支约 `:79` `while (p->next) p = p->next;` 踩到写坏节点（它**不采信** `siaddr=0x0`、如实 `NOINFO`）。⚠️ **状态仍 🟡（处置未做）**；⚠️ **`D-G98` 的适用范围据此写明"只指 `134` 族的几何/尺寸约束那条线、不含静默 SEGV"**（两者**异源**）；⚠️ **W128A 批次仍在跑**（写成时 `1/75 ≈ 1.3%`，最终计数与上界待它跑满）；**建议给这条静默 SEGV 独立开号**（本件**未**开，主控另派）。
- 🆕 **新登记 `D-G103`（装置/处置缺陷 · `pkill -f` 的"自杀式误杀"新面）**：`pkill -f '<模式>'` **也匹配发出者自己的那条命令行** ⇒ **自杀** ⇒ **它要打印的损失清单永远拿不到**；**同一模式顺手杀掉别人的批次**（实例：W124A 的诊断命令 `pkill -f 'HandyControlDemo.dll'` 命中 W118A 正在跑的装置 ⇒ 那趟被 SIGTERM 收走并被剔除；**代价 = 别人批次的样本损失 ＋ 无法自证损失范围**）。**正确姿势 = 只按 PID `kill <pid>`、探活读 `/proc/*/cmdline`，任何 `pkill`/`killall`/`pgrep -f` 都不许出现（含"诊断命令"）**；**自救实测**：W118A 每趟加 `TIMEOUT_RC`／`WRAPPER_KILLSIG`／`APP_OUTCOME_OBSERVED`／`EXTERNAL_KILL_SUSPECT` 四格，**12 趟全 `SUSPECT=no`** ⇒ **"能不能机读分辨被打断"是可以做到的**。交叉引用 `D-G93`（同族"按关键词认对象"）／`D-G102`／教训表 `L14`（原文未动）／`D-G94`（分母剔除必须点名）。
- 🆕 **新登记 `D-G104`（仪器/方法学缺陷 · "读数器自己的输出语义被读错"新面）**：**工具打出来的东西 ≠ 工具想说的东西，而它不报警** —— 两实例：① **`stat -c '…\t…'` 打的是字面反斜杠 `t`** ⇒ 字段列错位 ⇒ W123A 第一版"inode 全变"的前后对照**是空转的**（比的是路径 vs 两个不存在的字段；重算后结论未变，**但空转不构成证据**）；② **`awk` 求和静默 int32 钳位** ⇒ `bin/`＋`obj/` 总字节打成 **`2147483647`（2^31−1）**、真值 **`4387006694`（4.09 GiB，Python 复算）** ⇒ 会**低估一半以上**。**口径**：**凡"总和／分布／逐字段比对"类读数必须用第二种工具复算一次**；**"我没看到不一致" ≠ "我比过"**。第三条：**同一件两种口径算出两个 sha16 时，报告必须两行都给**（FULL sha256 ＋ 去行口径值 ＋ 口径式子）—— 先例 = `W123A-report.md` 的 `abd86b0bbdabfc9d`（现场 1745 行）vs 主控转来 `02cda62724d4d702`，当时处置即"如实记两个值"。
- 🆕 **新登记 `D-G105`（装置缺陷 · "判据件认错对象"的新面：复用外部 X 时**只验"连得上"、不验"几何对不对"**）**：`verify-all.sh` 的 `[0]` 段与第二处复用点 `x_recheck_alive()` **只看 `xdpyinfo` 能不能连**、**从不比几何** ⇒ 静默用上一台**几何不符**的 Xvfb（本次 = 车道 W128A 的 **`:185 -screen 0 1024x768x24`**，而仓内规格是 **`1280x1024`**）⇒ 依赖坐标的用例整片**假红**。
  - **代价（量化）**：该趟 **用例通过 831 / 跳过 2**（`#51` 同口径 **875 全过**）⇒ 差 **44 = 整个 `Windowing.Tests`**；步骤级 **通过 25 / 失败 2**，两处红里**只有一处是声明类**（`COLUMN-FLOOR`）⇒ 另一处是**非声明类红** ⇒ 按纪律**停手报主控**、冻结顺延 **30+ 分钟**。**危险方向 = 假红**（把**装置问题**读成**产品回归**）。
  - **修法（已落地，落在"更严"的方向上）**：**两处**复用点都加**几何守卫**（复用前须 `几何 == $XREQ_GEOM(1280x1024)`；不符 ⇒ **跳过并点名**），三态机读行 **`X-REUSE=reused|skipped-geom-mismatch|self-started`**；件 **`verify-all.sh` `1fb43fc4522c8784` → `0cdd12547a634b37`**（`bash -n` `rc=0`；`VERIFYALL_SELF=PASS names=27 decl=27 gen=#52 …` ⇒ **步数不变**；备份 `~/w126a/backup/verify-all.sh.before-geomguard`）。**修后当场生效逐字**（第二趟日志 `~/w126a/logs/07b-verify-all-pre2.log:8-9`）：`[0] Xvfb（目标 :99）` ＋ **`✅ X-REUSE=reused display=:97（已运行的 Xvfb；几何 1280x1024 相符；注意不是 :99）`**；同趟 **`Windowing.Tests ✅ 通过 44 跳过 0 合计 44`**。
  - **机械影响（判据件不在覆盖面 ⇒ 指纹不动）**：`verify-all.sh` **不在** `fp_inputs()` 覆盖面 —— `sed -n '/^fp_inputs()/,/^}/p' build/close-wave.sh | grep -n 'verify-all'` 命中**全是注释**（`:142` 逐字"实测它本来就不在覆盖面"）；覆盖面成员是**显式名单**（`close-wave.sh:146+`）**非 glob** ⇒ 本次改动**不动** `inputs_fp`。
  - **同族但判词不同（不许合并）**：`D-G89`／`D-G97`（恒真／射程）｜`D-G102`（按名字认对象）｜`D-G93`（按关键词认进程）—— 本条坏在"**身份判据少了一个必需维度（几何）**"⇒ 独立立号；⚠️ 与 `D-G103` **明确分开**（那条属"处置/毁证据"族）。
- 🆕 **新登记 `D-G106`（装置缺陷 · "假可疑"把真命中踢出分母）**：`ARM=gdb` 下**"命中即停 = 看 `APP_RC=139`"不可达**（gdb 在场时 `APP_RC` 是 **gdb 的 rc**）⇒ 同一趟出现 `FAMILY=other` ＋ `APP_RC=0` ＋ **假** `EXTERNAL_KILL_SUSPECT=yes` ⇒ **真命中被剔出分母**；**正确口径 = `APP_FATE` 含 `SIGSEGV` ∧ `APP_TEXT_BYTES=0`**。**危险方向 = 样本损失 ＋ 上界被算错**（`139` 命中本就稀，剔掉真命中后剩下的"0 命中"照样"好看"）。与 `D-G103`（真被打断）**共用同一条纪律**：**凡"外部打断"判定必须给出"应用自己的结局"这一格；拿不到 ⇒ `NOINFO`**（不许当绿继续算、也不许当红剔掉）。
- 🆕 **新登记 `D-G107`（装置缺陷 · 解析器对多词字段整行不匹配 ⇒ 非主线程的趟被静默降级）**：STOP 行正则 **`thread=(\S+)`** 只吃一个单词 ⇒ 线程名含**空格**（**`.NET Finalizer`**）时**整行不匹配** ⇒ 该趟被判"**没有 deep 停止点**" ⇒ **一律误判 `NOINFO`**（**危险方向 = 漏判命中**）。**口径**：解析自由文本字段时**分隔符必须按该字段真实取值集合定义**（线程名／`WM_*` 名／属性名都可能含空格），一律用"到行尾或到下一个已声明字段的锚"，**不许**用 `\S+` 赌"没有空格"；且**每趟必须自证"我解析到了那个字段"**。⚠️ 与 `D-G106` **分开**（那条是**语义错**＝字段选错；本条是**解析错**＝字段对但读不出）。
- 🔁 **方法学四条（并入既有口径、**不新开号**；理由 = 本册已有同族编号，取新号只会把同一根因拆散）**：**① 「某车道是否在动」判据 = 活进程第一、`STATUS.md` 第二** —— 本会话已有**两条**车道的 `STATUS.md` **滞后于真实动作**（W120A／W123A）⇒ 冲突时**以 `/proc/*/cmdline` 为准**（并注意**探活者自己的命令行会被数进去**，见 `D-G93`）；**② 不许用 `pkill`/`killall`/`pgrep -f`**（含诊断命令）⇒ 见 `D-G103`。**③ 车道"静默不动"先查 `uptime -s` 与活进程，不要一律归因于运行时**：现场 `uptime -s` = **`2026-09-23 09:45:54`** ⇒ **宿主当天重启过一次**；`w126a` 09:32→09:58 那段"静默挂死"**就是这次重启**（"进程没了 ∧ 日志断在半路 ∧ `STATUS.md` 停在某一秒"三件同时出现 ⇒ **先查启动时刻**）。**④ 探活读数必须证明"探活者不在被数集合里"**：`ps | grep`／`pgrep -f` **都会把自己数进去** ⇒ 一律读 `/proc/*/cmdline` 并排除自身进程树（本条与 `D-G93` 同族，故不新开号）。
- 🔁 **`TASK-0110`／`TASK-0111` 现状补一行（如实；上面各节的登记**一字未动**）**：`TASK-0110` **🟡**（真因**部分定位／部分证伪**、首选成因**已改向"应用那份过期的尺寸约束挡住还原"**，接 `D-G88`；缺陷**仍红**）；`TASK-0111` **🔴**（`N3` **先做**且**必须加一格**：在**红腿**上当场 `xprop -id <client> WM_NORMAL_HINTS` 与"**停住几何**"逐字比对；`N1` **撤销/暂缓**）—— **那一格正在由车道 W124A 做**（本件写成时 `build/MilBridge/W124A-report.md` **尚不存在** ⇒ 该格 `NOINFO`）。
- **`DEFREG` 两条机读行（现场跑两遍、逐字相同、`rc=0`）**：`DEFREG=PASS declared=<N> route_ids=<N>`｜`DEFREG_DECLDRIFT=0`（原值 `138` ⇒ 本批 ＋`5`（`D-G103`…`D-G107`）＝ **`143`**；逐字读数见 `build/MilBridge/W127A-report.md` §⑥）
- **推送（本批一笔、纯文档）**：head 与 `BYTECHECK` 逐字见 `build/MilBridge/W127A-report.md` §⑦（逐径 `git add`、**不许** `-A`／`--force`；push 后重新 `fetch` ＋ 与 `ls-remote origin HEAD` 交叉核）。

## §15o `#52` 冻后第一批（第十二笔）：新登记 `D-G108`（发布完整性）／`D-G109`（静默 SEGV 异源）＋ 新 `TASK-0209` ＋ `TASK-0203` 归因落地（**一行一条**；2026-09-23 车道 W129A 补，读数全部现场现算）

- 🆕 **新登记 `D-G108`（发布完整性缺陷 · `git add -A` 把别的车道的在办件夹带进发布）**：`#52` 冻结块（`ACCEPTANCE-BASELINE.md` 的 `RE-FROZEN #52` 块）**逐字宣称** `win32_core.c 3117923a7c899e05` ＋ `win32_x11.c 11142fbef049eb66` ⇒ `win32shim bd037229be8db4f6`，而远端 `37def7e`（提交信息逐字"冻结 `#52`"）之后**实际是** `a9cc8762908b417a`／`9fa20864404ab01b`／`4e1880e6054635ff`（= 车道 **W131A 的在办值**，属 `#53`）⇒ **发布树与发布者自己的冻结声明不符**。**机制 = `git add -A`** 把当时克隆里**所有脏件**扫进同一笔（`37def7e` 共 16 件、`src/` 下只有那三件；W131A 改件 `mtime 11:49:23` → 提交 `11:49:37`，**差 14 秒**）。**危险方向 = 静默污染发布**（推者以为只推自己的收尾件、别人以为远端=某冻结态，**两方输出都不报警**）。**处置** = 还原笔 `1890b007985709b079112e167f455bbe91f8da58`（逐径 `git add` 三件）⇒ 远端三件回到冻结声明值（本件现场 `git cat-file -p HEAD:<path>` 逐件复核相符）。
- 🆕 **`D-G108` 第二条教训 · "还原姿势"（同一事件第二个独立面）**：主控当时给的 **`git checkout 37def7e^ -- <三件>` 是错的** —— `37def7e^` 三件现算 = **`e0cbc965772d06c1`／`6477af56fdcfdf20`／`e4f2de8d038e4780`** = **`#51` 的态**，**既不等于冻结声明值、又会把 `#52` 刚落的产品改动（`D-G100`）一起回退**；车道按"若不符则停手"条款**没执行**，改用**正确源头** = `~/w131a/backup/*.orig`（现算与冻结块声明**逐位相同**）。**口径句（逐字）**：「**凡"还原/改写冻结态"的指令，必须先拿冻结块（`ACCEPTANCE-BASELINE.md` 的 `RE-FROZEN` 块）逐件对值再执行；不许凭"回到父提交"想当然。**」
- 🆕 **`D-G108` 口径句（逐字，写死）**：「**在克隆里一律逐径 `git add <file>`；`git add -A` 会把别的车道的在办件夹带进发布。**」**同族** = `D-G101`（"我以为只动我的" ⇒ 写穿别人的件；机制 = inode 共享）⇒ **独立立号 ＋ 交叉引用**；另引 `D-G80`／`D-G103`／`D-G104`。**边界**：`libwpfwin32.so` **不在 git**（`git ls-files | grep -c` = `0`）⇒ 从 git **无法复原**该件本体，但 `~/w131a/backup/libwpfwin32.so.orig` 现算 = **`bd037229be8db4f6`／327,256 B** ＝ 与冻结声明逐位相同 ⇒ **该值可复核**；"它是否曾真实存在于 `$R` 现场"那一格 **`NOINFO`**。
- 🆕 **新登记 `D-G109`（产品缺陷 · 静默 SEGV 族 = `TASK-0203` 里的那只"静默 `139`"，与 `134` 族**异源**）**：点击打到**第 7 击 `nav2`** 时，修前件（`abf6879c027c5e73`）的消息队列被写到非法状态，**`.NET Finalizer`（`tid=6`）**走 `HwndWrapper::Finalize()` → P/Invoke → `PostMessageW` → **`wpf_queue_push + 259`** 的链遍历（逐字 **`mov 0x38(%rax),%rax`**＝`p = p->next`）踩坏节点 ⇒ `SIGSEGV` ⇒ **进程静默死（应用自己 0 字节输出）**。**判定点 = `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82`** 的**非法队列自愈分支**（`head != NULL ∧ tail == NULL`）里约 **`:79`** 的 `while (p->next) p = p->next;`。
- 🆕 **`D-G109` 异源四条读数（逐字；本件现场从 `~/w128a/runs.tsv` ＋ 两份 `frozen/<tag>/gdb.txt` 复算）**：① 线程 = **`.NET Finalizer`（`tid=6`）** vs `134` 恒 `tid=1`；② 栈深 **`7,088 B`**（浅）vs `8,388,672 B`（满 8 MB 栈底）；③ **无环**（`R1_CYCLE=False` ∧ `R2_SAMESET=False`；`134` 族 12/12 全 True，轮数 2,937–2,987）；④ **应用输出 0 字节**（`app.log`＝`app.err`＝`app.both`＝**0 B**；`Stack overflow.` 一个字都没来）。
- 🆕 **`D-G109` 两个样本**同址** ⇒ 确定性缺陷**：`W071`（`pad` **`1129`**）与 `W077`（`pad` **`1226`**）**两个不同相位**给出**逐位相同**的故障停止点 —— `PC-1 = PC-2 = 0x7fff740dcdf3`、同 `tid=6`、同 `depth=7088`、**同 `rsp=0x7fff7600a450`**、同死在**第 7 击 `nav2` 之后**（`CLICKS_TRIED=9 CLICKS_LANDED=7 ENTRY_DETAIL=nav1,nav9,ctrl_tb,nav10,ctrl_cb,popitem,nav2`）、同 `FAULTCOUNT=3 GDBSTOP_SIGS=11,11,11`。⚠️ **同一件两个值（`D-G104` 第三条）**：`W128A-report.md` §④ 正文写"`PAD=903`"，而**机读台账**现算 = **`1129`**（`903` 实为 `W057` 的 `pad`）；**两个值都留档，以台账为准**，且**与判词无关**。
- 🆕 **`D-G109` 实时计数（中途读数，现场从机读台账复算）**：**2 命中 / 100 有效主臂趟 = `2.0%`** —— `~/w128a/runs.tsv` **106 行**（表头 ＋ 105 趟）：`arm=gdb` **100** 趟为主臂（`family=134-stackovf` **98**／`family=other` **2** = `W071`＋`W077`）、`arm=nogdb` **5** 趟阳性对照**全部 `124/alive/落地 8`** ⇒ **批不作废**。⚠️ **该批仍在跑** ⇒ **最终计数与 95% 单侧上界 `NOINFO`**（以 W128A 交数终值为准）；⚠️ 两趟的 `ext_kill_suspect` 均 `yes`（= **旧口径误剔**，见下）。
- 🆕 **`D-G109` 口径修正（三条件合取，逐字；须与 `TASK-0203` 同读）**：**`SILENT_SEGV_HIT ⇔ 应用输出 == 0 B（剔掉 `timeout:` 那行）∧ `STACKOVF == 0` ∧ 死于 SIGSEGV（`RC==139` ∨ `APP_FATE` 含 SIGSEGV ∨ `gdb.txt` 含 `Program terminated with signal SIGSEGV` ∨ `gdb.txt` 里存在 `W118A-STOP-N`（`N≥1`）且 `signo=11`）** —— **最后一支直接从 `gdb.txt` 停止点行读、抗收尾截断**。**重扫**：`~/w128a` 旧口径 **0** → 新口径 **2**（**漏判 2 ＋ 误剔 2**）；`~/w118a` 71 趟／`~/w98a` 128 趟**零影响**。⚠️ **不许把 `siaddr=0x0` 当依据**（与指令语义不符；本号判词不依赖它）。
- 🆕 **新任务 `TASK-0209` [Next] 🔴**（号现场核：`TASK-0201`…`0208` 已用、`TASK-0209` 全仓 0 命中）：**修 `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82` 的队列链遍历 ＋ 给"写坏 `head` 链的上游写者"取证** —— ① 判据**先写**（含"**终结器路径 `HwndWrapper::Finalize()` → P/Invoke → `PostMessageW` → `wpf_queue_push`**"这条链的取证：每趟必须给出 `PC`／`tid`／`depth` 三格，拿不到 ⇒ `NOINFO`）；② **两极化**要求：修后件臂上该签名 **0/N**，且**同一装置上仍能复现 `134` 族**（证明不是把装置弄哑）；③ **不许**只在 `wpf_queue_push` 里加空指针守卫就收工（那是**崩溃点**、不是**根因点**）—— 必须点名**写坏者**或如实 `NOINFO`；④ 沿用 `D-G109` 的**新口径**（`APP_RC==139` 在 `ARM=gdb` 下不可达，见 `D-G106`）。**交叉引用** `D-G109`／`D-G106`／`D-G107`／`D-G96`（证据冻结）。
- 🔁 **`TASK-0203` 追加（车道 W128A 交数 ＋ 本件现场复算，2026-09-23；上面各节登记**一字未动**）**：归因已落到"**异源 ＋ 具名判定点 ＋ 两个同址样本 ＋ 实时 `2.0%`**" —— 异源四条读数与判定点逐字见上 `D-G109`；样本 = `W071`／`W077`（`PC-1=PC-2=0x7fff740dcdf3`、`tid=6`、`depth=7088` 逐位相同）；计数 = **2/100 = `2.0%`（中途）**。⚠️ **状态位仍 🟡**（**产品侧未修**，处置已开 `TASK-0209`）；⚠️ **`D-G98` 的适用范围照旧：只指 `134` 族的几何/尺寸约束那条线，不含静默 SEGV**（上批已写，此处**不重复登记**，只保证与 `D-G109` 并列可读）；⚠️ **最终计数／上界仍 `NOINFO`**（W128A 批次在跑，其报告 §⑮／§⑯ 仍是 `<<<TABLES>>>`／`<<<SELFSHA>>>` 占位符，本件现算 sha16 **`34cbdff1b5d1bebd`** ⇒ 该报告**仍在写**）。
- **`DEFREG` 两条机读行（现场跑两遍、逐字相同、`rc=0`）**：`DEFREG=PASS declared=145 route_ids=145`｜`DEFREG_DECLDRIFT=0`（原值 `143` ⇒ 本批 ＋`2`（`D-G108`／`D-G109`）＝ **`145`**；逐字读数见 `build/MilBridge/W129A-report.md` §⑤）。⚠️ 新号**只声明在 `KD`**（`req=KD`）—— **未碰** `CS`／`HO`／`AB` 三个 route 文件（`D-G108` 的射程就是"发布完整性"，与冻结块/状态件无关）。
- **推送（本批一笔、纯文档）**：head 与 `BYTECHECK` 逐字见 `build/MilBridge/W129A-report.md` §⑥（逐径 `git add`、**绝不许** `-A`／`--force` —— 本批登记的 `D-G108` 正是 `-A` 造成的；push 后重新 `fetch` ＋ 与 `ls-remote origin HEAD` 交叉核）。

## §15p `#52` 冻后第二批（第十三笔）：`TASK-0203` **收口 ✅**（= 测量交付完成）＋ 终报读数落册 ＋ `D-G106`／`D-G107`／`D-G109` 三条交叉引用（**不新号**）＋ `TASK-0209` 指针（**一行一条**；2026-09-23 车道 W130A 补，读数出自车道 W128A 终表、本件现场复核）

- ✅ **`TASK-0203` 收口：状态位 🟡 → ✅**（车道 W130A 落册；§13 树行与 §14 清单行**两处状态位已改**、判词文字**一字未动**，只**追加**收口限定）—— **该 ✅ 只指"测量交付完成"**：`139` 族归因**不再 `NOINFO`**（= **异源 ＋ 具名判定点 ＋ 两个同址样本 ＋ 上界**）；**产品侧未修 ⇒ `D-G109` 仍红**、处置 = **`TASK-0209`**。⚠️ 本行**取代** §15 行、§15n 第 ② 条（"状态位保持 🟡、不许转 ✅"）、§15o 末条（"状态位仍 🟡"）的**状态读数**（那三处**历史行一字未动**，只在此声明取代关系）。
- 📊 **终报读数（逐字；报告 `build/MilBridge/W128A-report.md` FULL `789d01e5f8959b0b70ffda770e8c02dac653661e48af5510f7e5a5d6ca485878`／`head -n -2` sha16 `d014ebd90d45840e`／352 行／37,548 B —— 车道 W130A 现场现算）**：主臂 **`175/175` 全部有效（剔除 0、作废 0）** ＋ 对照臂 **8 趟**（`K0C…K7C` 全 `124/alive/落地 8`，逐批阳性对照成立）⇒ 结局 **`134`×173 ＋ 静默 SEGV×2**；**命中 2 趟**：`W071`／`W077`，崩点 **`PC` 逐位同址 `0x7fff740dcdf3` = `wpf_queue_push+259`**（偏移 `0x11df3`，逐字 `mov 0x38(%rax),%rax`）＋ 两趟 `stacklast.raw`／`maps.txt`／`perf.map` **同刻齐全**（mtime delta `0.0`）＋ 整目录冻结 `~/w128a/frozen/{W071,W077}`（`stacklast.raw` = `9ff31a24fa90f56e`／`9cd325be4e5381b0`）｜判词 = **`异源`**（崩在 **`.NET Finalizer`（`tid=6`）**／**浅栈 `7,088 B`**／**无重复环 `R1=R2=False`**／**应用输出 0 字节**）＋ **判定点 = `src/WpfGfx.Linux.Native/src/win32_msg.c:57-82`**（约 `:79` `while (p->next) p = p->next;`）；`siaddr=0x0` 记 `NOINFO`、**判词不依赖它**。
- 📐 **上界（新口径）＋ "再压"代价**：本批 **`2/175 ⇒ 95% 单侧上界 3.55%`**（点估计 `1.14%`，与 `W98A` 历史 `1/60=1.7%` 同量级）｜与 `W98A` 同件同腿合并 **`3/235 ⇒ 3.27%`**｜本装置全部 **`2/236 ⇒ 2.64%`**；**`≤1.0%` 需 299／473 趟**、**`≤0.5%` 需 598／947 趟（≈5.3／8.4 槽小时）** ⇒ **主控裁定：不投**（机制与判定点已拿到、上界已足够；要投由用户拍板）。**槽**：批内实占 `5,880 s`、**让路 `4,778 s`（≈80 min，全给 `#52` 收尾链）**、批间一律释放槽；`low-memory`／`MAXHOLD_KILL`／`TIMEOUT` 各 **0**。
- 🧾 **收口口径句（逐字，写进 `TASK-0203` 行下）**：**`SILENT_SEGV_HIT ⇔ 应用输出 == 0 B（剔 `timeout:` 行）∧ STACKOVF == 0 ∧ 死于 SIGSEGV（`RC==139` ∨ `APP_FATE` 含 SIGSEGV ∨ `gdb.txt` 含 "Program terminated with signal SIGSEGV" ∨ `gdb.txt` 存在 `W118A-STOP-N`(N≥1) 且 `signo=11`）`** —— **最后一支抗收尾截断**（同句在 `D-G109` 内**已逐字在册**，仅反引号排版略异 ⇒ 本批**只引用、不重写**）。
- 🔁 **交叉引用（**不新号** —— W128A 交的两条仪器缺陷**已分别被 `D-G106`／`D-G107` 覆盖**）**：`D-G106`（`ARM=gdb` 下 `APP_RC` 不是应用的 rc ⇒ **命中口径不可达** ＋ 假 `EXTERNAL_KILL_SUSPECT` 把真命中踢出分母）／`D-G107`（`thread=(\S+)` 对**多词线程名** `.NET Finalizer` **整行不匹配** ⇒ 误判 `NOINFO`）—— 两条各**追加一行**实例：**"实例 = `W071`／`W077` 两趟；旧口径漏判 2 ＋ 误剔 2；`~/w118a` 71 趟与 `~/w98a` 128 趟重扫零影响"**；`D-G109` 追加**终报补**：**`175/175` 有效、2 命中、两样本同址、上界 `2/175 ⇒ 3.55%`**，**可复算入口 = `~/w128a/{runs.tsv,frozen/{W071,W077}}`**。
- 🧷 **`TASK-0209` 指针（**不重复立号** —— 它已由 W129A 立于 §15o）**：终报读数见本 §15p 与 `TASK-0203` 行（`2/175 ⇒ 3.55%`、两样本同址 `0x7fff740dcdf3`）；**本件不改 `TASK-0209` 的状态位**（仍 🔴）。
- ⚠️ **边界口径照旧（本批不重复登记、只保证与 `D-G109` 并列可读）**：**`D-G98` 只指 `134` 族的几何/尺寸约束那条线，不含静默 SEGV**（两者**异源**）｜`D-G109` 的"**上游写坏者**是谁"仍 `NOINFO`｜装置 `Xvfb 1024x768` **无 WM** 与用户现场（`:10` xrdp ＋ xfwm4）**不同构**｜`W98A` 的 `L1B024` 与本族**是否同一事件**仍 `NOINFO`。
- 🔢 **`DEFREG` 两条机读行（现场跑两遍、逐字相同、`rc=0/0`）**：`DEFREG=PASS declared=145 route_ids=145`｜`DEFREG_DECLDRIFT=0`（本批**不开新号** ⇒ 与 `#52` 冻后第一批的 `145` **相同**；`--emit` 重生成后 `ID` 行**逐一 diff = 0 行** ⇒ **零幻影声明**）。⚠️ **`--emit` 的 `DECL-ANCHORS` 里 `KRJ=f108775906eac9aa` 是 `$R` 的现场值，而克隆/远端 `build/MilBridge/known-red.json` 仍是 `d4e0080df6ec497c`（波 `#53` 在办、本件**不许碰**）** ⇒ 在**远端**跑同一牙时该**非门禁诊断行**会读成 `DEFREG_DECLDRIFT=1`（唯一漂移项 = `KRJ`），待 `#53` 推该件后自愈。
- 🚚 **推送（本批一笔、纯文档；逐径 `git add`、绝不许 `-A`／`--force`）**：head 与 `BYTECHECK` 逐字见 `build/MilBridge/W130A-report.md` §⑤。

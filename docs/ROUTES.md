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
│   ├─ TASK-0203 [Next] 🟡 **精度目标达成、`139` 族仍 `NOINFO`**（车道 W98A，报告 `build/MilBridge/W98A-report.md` `74df2f1a289bcc45`，台账 `~/w98a/runs.tsv` 128 行×33 列）：臂 A（现场权威件 `33352e5797031999`）无 WM 腿 **0/60** ⇒ **95% 上界 `4.87% ≤ 5%`**；两臂合并 **1/126**（主判据腿 120 趟口径 = `2.47%`）｜**`134` 族两极化干净成立**：臂 B（修前件 `abf6879c027c5e73`）**59/60 崩** vs 臂 A **0/60**｜**`139` 族 `NOINFO`**：唯一 1 次落在**修前件臂**（`L1B024`，真 `139`＋核心转储、应用 0 字节、7 击全落地后死在 `nav2`）⇒ 方向对、**1 次撑不起归因**。
│   │   ├─ **阳性对照复现**（`PCB 2/2 崩` 6,478,046 B／19,393 B ＋ `PCA 0/2`）｜耗时壁钟 **2 h 46 min**（让路 1020 s、槽内 6850 s、每趟中位 75 s、`void=0`／`oom=0`／`MAXHold_KILL=0`）
│   │   ├─ 🆕 **同趟新登记**：`D-G93`（闸门 `pgrep -f` 命中别家 `bash -c` 轮询器 ⇒ **假死锁 300 s**，当时槽是空的）、`D-G94`（把"**没点**"的 `SKIP dead` 算进分母 ⇒ **唯一那次真 `139` 被自己的口径判成"无检测力"并剔除**）；`D-G87` **第三次复核**（61 趟 `134` 里 **14 趟只写 18–19 KB 折叠形 = 23%**）
│   │   └─ **代价与边界**：两 shim **符号差 25 个导出**（`#50` 落地 `A1`/`A2` 后由 14 涨到 25）⇒ **即使两极化成立也不许归因单一改动**；本机 `Xvfb 1024×768±xfwm4` 与用户现场（xrdp＋xfwm4）**不同构**
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
- `TASK-0203` [Next] 🟡 **静默 `139` 长跑 —— 已办，但只到 🟡（车道 W98A，报告 `build/MilBridge/W98A-report.md` `74df2f1a289bcc45`；主控已独立复核：台账 `~/w98a/runs.tsv` **128 行 × 33 列**逐行复算与我一致、`criteria.md` `c2aeeceffae9757e` 先于第一条样本）** —— **到哪一格**：
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
- `TASK-0110` [Next] 🔴 **几何还原残留：查"WM 为什么不把退出最大化的几何收回去"**（`D-G98` 的落地；来源 = 车道 W105A 报告 §4.2／§9.1 的 26 腿零回归复核 ＋ W89A §5.3 的首次登记）：
  - 现象（**判据要能抓 frame/client 时序分离**）：`_NET_WM_STATE` 里两个 `MAXIMIZED_*` **已经掉了**（窗态还原确已发生），而 **client 几何**与 **WM 的 frame 几何**（`fgeom`）**双双卡在 `1280x1024@+0+0`**；现行的两拍（`AFTER_R2`／`AFTER_R2_SETTLED`）**逐字同形** ⇒ **两拍不够** —— 新判据必须在**还原那一瞬加中间拍**（逐拍读 ① `_NET_WM_STATE` ② client 几何 ③ `xwininfo -frame` 的 frame 几何 ④ `_NET_FRAME_EXTENTS`），把"**先掉状态、几何滞后**"与"**状态掉了、几何再不动**"两件事**分开**。
  - 比例与排除（**已由 W105A 做完，本行只引用、不重跑**）：当代 **新件 `3/36` vs 旧冻结件（**无 `P2`**）`2/36`、Fisher 双尾 `p = 1.000`** ⇒ **不是本波引入**；外部只读观测器在**旧件**那趟（`W105A-C2-p09-old`）记录到 X 侧提示**全程是常量** `program specified minimum size: 1 by 1`（**没有任何 `maximum size`**）⇒ **排除**"`P2` 写提示把窗口卡住"。
  - **要查的那一层**（**本行不许猜**）：**WM 侧**为什么没执行"退出最大化的几何还原"。三个候选，**每个都要先写"怎么证伪"**：① 应用发出的还原请求里**缺了让 WM 重算几何的那一拍**（`WM_STATE`／`_NET_WM_STATE` REMOVE／`WM_NORMAL_HINTS` 的次序）；② **client 与 frame 的尺寸协商顺序**（`ConfigureRequest` 与 `ConfigureNotify` 的先后、`_NET_FRAME_EXTENTS` 是否陈旧）；③ **WM 内部状态机**与应用窗的 `_NET_WM_STATE` **不同步**（`xfwm4` 的 `maximized` 标志）。
  - 判据（**先写**）：**同一趟**里同时取上面 ①–④ ＋ 外部观测器时间线，**每 ~0.1 s 一拍**；**红** = "`_NET_WM_STATE` 不含 `MAXIMIZED_*` **且** client 与 frame 几何**都 ≠ 基准**"**连续 ≥ N 拍**（`N` 在取读数**之前**写死）；**反极性** = 修法拆掉后必须回到**同形**；**取不到分层读数 ⇒ `NOINFO`**（既不算绿也不算红）。
  - 边界（**不许放宽**）：分母口径照 `D-G94`（把"**没点**"与"**点击被吞**"分开，`m_ok`／`r_ok` **并列报**）；"**两臂速率差是否显著**"要**每臂数百趟**才判得动 ⇒ 本行**不**承诺在几十趟里给出显著性结论。
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
- `TASK-0705` [Next] 🔴 **把"回归判定"的口径写进预登记模板**（`D-G99` 的落地；来源 = 车道 W105A §4.5 自立的 `F1` ＋ 本波 `docs/ROUTES.md` §15g 的口径句）：
  - 要改的对象 = **预登记模板**（`docs/WAVE*-PREREGISTRATION.md` 的判据节，或仓内那份"预登记怎么写"的说明件）—— ⚠️ **落地前先核"哪一份是权威模板"**；核不到 ⇒ 记 `NOINFO`，**不许**只改一份副本就宣称"模板已改"。
  - 模板里**必须**写死的**四要件**（**缺一即只能记 `NOINFO`**）：① **两臂同刻读数**（同一装置、同一会话、**只换一个文件**；两个件都要带 sha16 前置断言）；② **成对归因臂**（同腿旧/新**交替**、对间交替先后、每趟**全新进程树**）；③ **复现性**（**在旧件上也要能复现该红** —— 只有新件上红 ⇒ **不足以**判回归）；④ **统计口径**（Fisher 精确检验**双尾**，且**先写死**"样本量不够时不许判回归"——单臂 26 趟只看得见"相差 ≥4 倍"这一档）。
  - **这条任务自己也要有牙**（反极性）：拿**已知的间歇案例**当 fixture —— 用 `D-G98` 的读数（**新 `3/36` vs 旧 `2/36`、`p = 1.000`**）做"**不许判回归**"的**负例**，用 `D-G98` 那类**确定性**差异（修前修后逐位可分的两件）做"**必须判回归**"的**正例** ⇒ 新模板若把负例判成回归，**它自己就红**（照仓内 `--selftest` 形态交件）。
  - ⚠️ **不许**顺手改任何**已冻结**的预登记件（若某份 `docs/WAVE*-PREREGISTRATION.md` 已进冻结语义 ⇒ **只加不改**；新要件应在**新波**的预登记里生效）；**不许**把本要件**倒填**进既有报告来"美化"历史判词。
  - 边界：本行**只立号、未写模板**（立号件是纯文本登记波，不含落地）；"**全仓还有几处预登记用了同款单腿推理**"**未逐处枚举** ⇒ 那一格 `NOINFO`。
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

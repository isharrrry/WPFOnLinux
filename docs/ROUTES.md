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
│   ├─ TASK-0104 [Next] 🟡 已最大化态下再双击还原 / 最小化出现**矛盾读数** ⇒ 定性
│   ├─ TASK-0105 [Next] 🟡 冷启动期 `windowsize` 被 WM 吞掉的**边界时长**
│   └─ TASK-0106 [Next] 🟡 `PMaxSize` **声明态端到端**应用腿（仓内无声明 `MaxWidth` 的样本）
│
├─ 02xx R2 稳定性（崩溃族）
│   ├─ TASK-0201 [MVP] 🟡 静默 `rc=139`＋0 字节日志：**15 趟跑满零命中**（上界≈20%）
│   │   └─ 唯一信号在运行时 `/memfd:doublemapper`（被运行时自愈、不致命）
│   ├─ TASK-0202 ✅ 修 `D-G72`（点菜单条 NRE）—— 判据/根因见 TASK-0008
│   ├─ TASK-0203 [Next] 🔴 给静默 `139` 一个**两极化判决**（按 W63A 配方，需重活槽）
│   └─ TASK-0204 ✅ 登记 `D-G73`（`WM_SYSCOMMAND` 未实现＋`ShowWindow(SW_MAXIMIZE)` 空操作）／`D-G74`（`ConfigureNotify` 父窗相对坐标 ⇒ 命中测试偏掉）
│
├─ 03xx R3 文本与排版
│   ├─ TASK-0301 [MVP] 🟡 零墨：**修法已落地，待进冻结**
│   │   ├─ 根因：`build/shims/PresentationCore.HbTextLine.cs:2826` 单段行用**段落主面**取"按计划面整形"的字形 id
│   │   ├─ 世代位：`hbtextline e89fed55… → 921ba9c65e9fb3be`；`pc 9465f9dc… → 21e3e88a5090cd3b`
│   │   ├─ 像素成对：页签 `1/0.00%`→`90/9.03%`；按钮 `8`→`120`；搜索框 `19`→`67`
│   │   ├─ 零回归：导航项 `69/10.47%/303`、下划线带 `2/22.00%/156` **逐位不变**
│   │   └─ 反极性：shim＋pc 逐字节还原 ⇒ 四区回到 `1/8/19/69`、截图 sha 回 `9380291b84d81dd6`
│   ├─ TASK-0302 [MVP] 🔴 PTS / 原生 LineServices（**111 条 `Fs*`/`Lo*` 缺口**，`D-G70`）
│   ├─ TASK-0303 [Next] 🟡 **只读侦察＋最小第一步设计已完成**（车道 W78A，报告 `build/MilBridge/W78A-report.md` `0dbc62b1d1cf86ee`，568 行；零 `dotnet`/零应用/零构建）
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
│   └─ TASK-0502 [Next] 🔴 多帧解码＋帧时序（GDI+ 图像族仍"只做到能起来"）
│
├─ 06xx R6 辅助功能与输入法
│   └─ TASK-0601 [Next] ✅ 只读侦察完成（报告 `a1b01055b7080502`，**12 条空缺表**）
│       ├─ UIA：**有路无门**（`WM_GETOBJECT` 自有代码仅 1 处且是消费者）＋**门后断头**（`UIAutomationCore.dll` 在 `build/shims/` 0 命中）⇒ `D-G75`
│       ├─ IME：**一处落点都没有**（按键走 `XLookupString(...,NULL)`；`GetSystemMetrics(82)` 那重门是**巧合关闭、无人决定过**）⇒ `D-G76`
│       └─ 边界：全部**静态**读数；hc 侧无断言点 ⇒ 运行时行为 `NOINFO`
│
├─ 07xx R7 验收装置与判据完整性
│   ├─ TASK-0701 [MVP] ✅ `~/mvp-accept.sh` ＋ `~/heavy-slot.sh`（`--max-hold` / **内存闸门 `--min-avail`**）
│   └─ TASK-0702 [Next] 🔴 `R-GATE`：把"连续点击"判据收编进仓并接进 `verify-all`
│       └─ ⚠️ 要改 `verify-all.sh` ⇒ **必须等冻结之后**
│
├─ 08xx R8 上游化与发布
│   ├─ TASK-0801 [MVP] ✅ fork ＋ `feat-Linux` 默认分支 ＋ README/README-Window/PORT-SPEC/ROUTES/FORK-AND-PUSH
│   └─ TASK-0802 [Next] ✅ 11 件文档已推远端（远端 `a0e783d…` 已核；默认分支仍 `feat-Linux`）
│       └─ ⚠️ 余项：**12 件源码/门禁数据待随收尾链同批推**（否则"文档说已修、分支里没修"）
│
├─ 09xx R9 性能与内存
│   ├─ TASK-0901 [MVP] ✅ OOM 的 `rc=137` 不算缺陷（已机器化：`HEAVYSLOT=NOINFO low-memory`）
│   └─ TASK-0902 [Next] 🔴 首帧时间 / 内存峰值基线
│
├─ 10xx R10 第三方应用矩阵
│   ├─ TASK-1001 [MVP] ✅ ThirdPartyMini 配置分叉（`C1c` 根因）
│   └─ TASK-1002 [Next] ✅ 补声明图（`UNEXPECTED 16→6`；反极性在 `cp -al` 副本上成立）
│
└─ 99xx 仓库牙齿 · 冻结收尾
    ├─ TASK-9901 [MVP] ✅ `DEFREG=PASS declared=112` / `VERIFYALL_SELF=PASS` / `DECLDRIFT=0`
    ├─ TASK-9902 [MVP] ✅ 冻结基线 `#48`（`AB 540725342059b820`）在用
    ├─ TASK-9903 [Next] ✅ 连带红已清：`Commands 562/562` ＋ `Rendering 166/168`
    └─ TASK-9904 [Next] 🟡 波 `#49` 收尾链（**正在跑，车道 W71A**）
        ├─ 整波 → 重取五臂 → `repin-generation --why`（逐条写覆盖面变动）→ 门禁 ×2
        ├─ 冻前 `verify-all`（预期**恰好 1 处**声明类红 = `COLUMN-FLOOR`）→ 冻结 `#49` → 冻后 ×2 → 收尾记录三段
        ├─ ⚠️ 重钉前**必须同趟**改 `known-red.json` `entries[1]`（`Extent 余差 95 → 1242`）否则 `registry-stale(drift)` ⇒ FAIL
        └─ ⚠️ 世代位现为**三处**：`hbtextline 921ba9c6…` / `pc 21e3e88a…` / `win32shim c493639d…`；重建桥 ⇒ `wpfgfx_cor3.so` 必出新值
```

**`[Next]` 合计 14 条**（逐条点名，不合并）：
- ✅ **已完成 5 条**：`TASK-0403`｜`TASK-0601`｜`TASK-0802`｜`TASK-1002`｜`TASK-9903`
- 🟡 **在办 1 条**：`TASK-9904`（收尾链，车道 W71A 在跑）
- 🔴 **未派 8 条**：`TASK-0104`｜`TASK-0105`｜`TASK-0106`｜`TASK-0203`｜`TASK-0303`｜`TASK-0502`｜`TASK-0702`（**须等冻结后**）｜`TASK-0902`

（另：`TASK-0204` 已完成，但它在本树里属"登记动作"、未挂 `[Next]` 标；`TASK-0301` 挂 `[MVP]`，其修法已落地、由 `TASK-9904` 折进冻结。）

**`[MVP]` 未绿 3 条**（逐条）：
- `TASK-0007` 🔴 切「富文本」23 /「流文档」24 必死 `rc=134`（真因 `TASK-0302`，属 R3 长线）
- `TASK-0201` 🟡 静默 `rc=139`＋0 字节：15 趟零命中（上界≈20%）
- `TASK-0302` 🔴 PTS / LineServices（111 条 `Fs*`/`Lo*` 缺口）

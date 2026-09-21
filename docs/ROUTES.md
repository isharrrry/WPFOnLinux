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
- TASK-0301 [MVP][Next] 🟡 一句话现象（用户视角）
    判定点：<文件:行> 或 <命令>
    读数：<修前 sha16/数值> → <修后 sha16/数值>（脚本现场算，**不许手抄**）
    两极化：<反极性腿读数> ｜ <还原证读数>
    NOINFO：<没做到的格子 + 确切条件>
```

### 12.5 与仓内既有规矩的关系（**不许两套**）

- 判据先写、读数后取；`NOINFO` 既不算绿也不算红；**不许静默 no-op**；改动前 `cp -p` 备份；按 PID 止损（**不许 `pkill -f`**）—— 见 `docs/PORT-SPEC.md`。
- 「完成」的最终裁判**不是**本文件的记号，而是仓的门禁读数（`DEFREG` / `VERIFYALL_SELF` / 冻结基线 / `verify-all`）；本文件是**地图**，不是判据本体。
- 每条 TASK 若与缺陷册对应，**必须写出在册编号**（如 `D-G70`／`D-G72`），免得"地图"与"缺陷册"两处措辞分叉。

## §13 当前任务树（**快照**：2026-09-21；TASK 化的 §1–§10）

- TASK-0001..0006 [MVP] ✅ A 能编译 ／ B 能开窗渲染 ／ C 必抛替身接线 ／ D 不被 `Debug.Assert` 打死 ／ E 交互（E1–E6）／ 真机口径 **29/31 页可用**
- TASK-0007 [MVP] 🔴 切「富文本」23／「流文档」24 必死 `rc=134`（真因 = TASK-0302）
- TASK-0008 [MVP] 🔴 点顶部菜单条 ⇒ `ScreenHelper.FindMonitorRectsFromPoint` NRE ⇒ 死 `rc=134`（`D-G72`；修 = TASK-0202）
- TASK-0101..0103 [MVP] ✅ 窗口：`PMaxSize` 钉死已解 ／ 缩·放·拖·最大化 ／ 去双层装饰
- TASK-0104..0106 [Next] 🟡 已最大化态还原矛盾读数 ／ 冷启动吞 resize 边界 ／ `PMaxSize` 声明态端到端腿
- TASK-0201 [MVP] 🟡 静默 `rc=139`＋0 字节：15 趟零命中（上界≈20%）；信号只在运行时 `/memfd:doublemapper`（自愈）
- TASK-0202 [Next] 🟡 修 `D-G72`（点菜单条 ⇒ NRE ⇒ 死）—— **已派车道 W70A**（作次任务，随零墨一起办）
- TASK-0203 [Next] 🔴 给静默 `139` 一个两极化判决（按 W63A 配方，`~/w63a/REPORT.md` §5.2）
- TASK-0204 [Next] ✅ **已办（2026-09-21，主控）**：登记 `D-G73`（`WM_SYSCOMMAND` 未实现 ＋ `ShowWindow(SW_MAXIMIZE)` 空操作 ⇒ 最大化/最小化与 `WindowState` 全无效）与 `D-G74`（`ConfigureNotify` x/y **父窗相对** ⇒ `GetWindowRect` 原点错 ⇒ 命中测试整条偏掉），两条都写明"**已修**（W59A 定稿 `11aa9d8fa154f20f`）＋判据＋边界"。
    `KNOWN-DEFECTS.md` `c5670b7e177d092e`；重生成声明表后 **`DEFREG=PASS declared=110 route_ids=110`**
- TASK-0301 [MVP][Next] 🟡 **已派车道 W70A 在办（落地 diff ＋ 两极化）** ｜ 零墨根因 = `build/shims/PresentationCore.HbTextLine.cs:2826`（面错）⇒ diff `cac51d6f54ad9845` **待发波**
- TASK-0302/0303 [MVP]/[Next] 🔴 PTS·LineServices（111 条 `Fs*`/`Lo*` 缺口，`D-G70`）⇒ 23/24 两页（TASK-0303 修）
- TASK-0401 [MVP] ✅ `Effects` 页（`0x6c`/`0x70` 已实现＋台账）｜ TASK-0402 [MVP] 🟡 `D-G71` 视觉级效果静默丢弃 ｜ TASK-0403 [Next] 🔴 消费或进 `NotDrawn`
- TASK-0501 [MVP] 🟡 GIF 只有第 0 帧（`wic_proxy.c:1030-1035`）｜ TASK-0502 [Next] 🔴 多帧＋时序
- TASK-0601 [Next] ⚪ UIA / IME —— **未开**（0 读数）：先只读侦察
- TASK-0701 [MVP] ✅ `~/mvp-accept.sh` ＋ `~/heavy-slot.sh`（`--max-hold`／`--min-avail`）｜ TASK-0702 [Next] 🔴 `R-GATE` 把点击判据收编进仓并接进门禁
- TASK-0801 [MVP] ✅ fork ＋ `feat-Linux` ＋ 五份文档 ｜ TASK-0802 [Next] 🔴 推后续文档提交；pin `1cfc37f` 与"构建只读 `upstream/wpf/**`"写进 README
- TASK-0901 [MVP] ✅ `rc=137`(OOM) 不许算缺陷（已机器化：`HEAVYSLOT=NOINFO low-memory`）｜ TASK-0902 [Next] 🔴 首帧/内存峰值基线
- TASK-1001 [MVP] ✅ ThirdPartyMini 配置分叉（C1c 根因）｜ TASK-1002 [Next] 🔴 补声明图（15 条"红而无登记"）
- TASK-9901/9902 [MVP] ✅ 牙口全绿（`DEFREG=PASS declared=108`、`VERIFYALL_SELF=PASS`、`DECLDRIFT=0`）／ 冻结基线 `#48` 在用
- TASK-9903 [Next] ✅ **已办（2026-09-21）**：`0x6c`/`0x70` 实现后“连带红”的测试与文档已同步 ——
    `CommandRoundTripTests.cs`（`0x6c`→`0x0a`：反极性 `失败:1` → 正极性 `失败:0/通过:1`）、
    `CommandCoverageTests.cs` `50559c6143d61c22`（`notImpl 7→5`、`implemented 110→112`、`withPayload 97→99`、两条 `Contains`→`DoesNotContain`；
    实测 `失败:0，通过:562，总计:562`、`rc=0`）、`docs/unimplemented.md` `66abdab7fc342cab`（C 类 `6→4`、顶层 `7/118→5/118`、`已实现 112/118`、总数核对行）。
    另**收紧一处白名单**：`GoldenBinaryReplayTests.cs` `39c3a7b45dbadd3d` 的 `AllowedNotImpl` 原还列着
    `0x6c`/`0x70` —— 它们已实现，留在“允许未实现”名单里等于**给静默回退开绿灯** ⇒ 已摘掉两条，
    重跑仍 `失败:0，通过:562，总计:562`、`rc=0`（即“这两条再变回 E_NOTIMPL”从今往后会当场变红）。
    ⚠️ 仍待办：**全套**测试（`verify-all` 第 2 步，约 14 min）尚未跑 ⇒ 本 TASK 记“Commands 一套已绿”。
- TASK-9904 [Next] 🔴 波 `#49` 收尾链（整波→重取五臂→repin→门禁×2→冻前 verify-all→冻结→冻后×2→收尾记录）

**下一轮口径**：凡 `[Next]` 即下一轮；**优先序按"挡住用户能不能用"排**：`TASK-0301 → 0303 → 0202 → 9903 → 9904`。
**MVP 未绿的只有 4 格**：`TASK-0007`、`TASK-0008`、`TASK-0302`（长线 R3）、`TASK-0201`（未复现）。

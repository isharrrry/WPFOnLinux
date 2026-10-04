# W46G 报告 —— `D-G54`：把「根 ＋ 呈现目标」从**通道级**下沉到 **target/HWND 级**

- 车道：**W46G**（**落地车道**：桥侧 `src/WpfGfx.Linux/**`，AOT 进 `wpfgfx_cor3.so`）
- 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
- 时间窗：2026-09-19 20:25 → 21:0x（本机时钟）｜kernel `6.8.0-138-generic`｜`nproc=3`
- 现场资源：`MemAvailable` 3.23 GB（构建前）／≈3.0 GB（跑趟间）｜`loadavg` 0.57/0.89/1.27（构建前）
- 设计输入（**读并逐条对照过**）：`docs/WAVE46-PERTARGET-PRESENT-DESIGN.md`（sha16 `9486f38c9a3d4898`，545 行）

---

## §0 一句话结论（三条）

1. **弹窗现在真的出画了**：`HWND 0x200008` 第一次成为呈现目标（`已呈现 413x274`，**skia 指令 29 条**），
   像素判据 **P2 由 `色数 1` → `色数 152`**，截图 `pop_post.2x.png` 肉眼可见**完整的 8 项下拉列表**
   （蓝底选中条 ＋ `正文正文2…9` 文本）；`WPFGFX_ROOTDIAG=1` 的 `ROOTDIAG 通道2 target.Root=0x893 … 从根可达=57`（>1）⇒
   **不是一块纯色**（反面判据被机械否掉）。
2. **主窗口没有被动过**：同一时刻（下拉未开）**旧桥 vs 新桥逐像素 `AE=0`**（主窗区、弹窗矩形、全屏三档）、
   下拉打开后主窗区仍 `AE=0`，全屏 `AE=17185` **全部落在弹窗矩形内**；
   单窗口载体（`WpfTextDemo`）门禁 **`WPTD_SUMMARY=PASS tiers_passed=2/2`**，且
   `drawn=260/144`、`colors=3960/2828`、`frames_good=14/14`、`cross_ae=0`、`exit=143` **与冻结基线 `ACCEPTANCE-BASELINE.md:58-60` 逐位相同**。
3. **两处台账盲区同趟补齐**：预检**下沉到 `MilChannel.Commit()`**（覆盖**四条**提交路径）⇒
   `[preflight] … id=0x35` 由 **1 条 → 2 条**（`handle=0x3` / `handle=0x894`，与 `[CMD] 派发 id=0x35` 的 2 条对齐）；
   并新增「按目标呈现」台账行（`▸ … root来源/尺寸来源/候选尺寸`、`▸ 本目标指令数`），把「这一帧呈现给谁、用的谁的根」
   从**读代码得出的解释**变成**量出来的读数**。

**⚠️ 两处必须点名的口径勘误**（都在 §2、§3 给原文）：
- 派单书的主判据①`grep -c '已呈现.*0x200008'` **是词序敏感的**：修好后它**仍然返回 0**（真实行形是 `→ HWND 0x200008 已呈现 …`）。
  它**不能**当判据用；本报告改用 `grep -c 'HWND 0x200008 已呈现'`（改前 0 → 改后 **2**）。
- 像素判据 **P3 = FAIL**（`AE=12220 < 20000`）：**不是**"弹窗没画全"，而是该阈值对本内容形态**标定过高**（见 §3.3 的分解）。

---

## §1 判定点与改动（逐处 `文件:行` ＋ before/after sha16）

### 1.1 写入面（**四件，全在 `src/WpfGfx.Linux/**`**；备份与复原见 §8）

| 文件 | before sha16 | after sha16 | 行数 | diff |
|---|---|---|---|---|
| `src/WpfGfx.Linux/Interop/MilPresentation.cs` | `ee89f32def7c98d2` | **`8b44b61f944aeeaa`** | 1178 → 1332 | `+202/−48` |
| `src/WpfGfx.Linux/Resources/MilChannel.cs` | `dcc34a49e0f7176d` | **`384d024ab7987dfa`** | 527 → 644 | `+117/−0` |
| `src/WpfGfx.Linux/Interop/MilNative.cs` | `ee4a0e8dd82b0cab` | **`e1d7bfa0fd03a01f`** | 622 → 596 | `+24/−50` |
| `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs` | `b0ddcd23f3e0cbca` | **`748f781620ea4008`** | 1444 → 1451 | `+7/−0` |
| **合计** | | | | **`+350/−98`** |

`find $R/src -newermt '2026-09-19 20:25' -name '*.cs'` ⇒ **只有这 4 件**（无第五件被动过）。

### 1.2 判定点逐处

#### D1 · 呈现**按目标**（不是按通道）：`MilPresentation.cs`
| 处 | 行 | 内容 |
|---|---|---|
| ① 收集**全部**目标 | `:784-807`（`CollectTargets`） | 旧 `TryResolveTarget`「遇到第一个 `NativeWindow != 0` 就 `return true`」**删除**；新函数把该通道**全部**带 HWND 的 `MilTarget` 收进来 |
| ② **顺序确定化**（G1） | `:803` `keys.Sort();` | `Entries` 是 `Dictionary` 且句柄会回收 ⇒ 枚举序不稳定；按**句柄升序**排 ⇒ 「第 i/N 个」跨运行可复算，且「多目标第 1 个」退化成旧语义的那个"第一个" |
| ③ 拆壳 | `:876-930`（`PresentChannel`） | 逐个目标调 `PresentTarget`；`_presentCalls` 仍**每通道 +1**（KEEP-1） |
| ④ 逐目标呈现 | `:939-1120`（`PresentTarget`，新） | 旧 `:851-975` 的主体逐目标参数化：**它自己的 HWND**（`target.NativeWindow`）、**它自己的尺寸**（`target.Width/Height` + `WindowRect`）、**它自己的清屏色** |
| ⑤ **返回码口径**（G2） | `:916-930` | `done == 0 && 失败 ⇒ 带出失败`；**多目标时"至少一个成功"一律 `S_OK`**，失败的进 `TargetsSkipped`（`:86`）＋ 一行点名台账（`:922`） |

#### D2 · **根句柄的通道归属**（设计稿 D3：本轮唯一不能省的新增状态）
| 处 | 行 | 内容 |
|---|---|---|
| 写侧标记 | `MilCommandDispatcher.cs:356` `ch.MarkTargetRooted(t);` | 派发 `MilCmdTargetSetRoot` 时记下「该目标的根**属于本通道**」 |
| 状态 | `MilChannel.cs:401-410` | `_rootedTargets` ＋ `MarkTargetRooted` / `IsTargetRooted` |
| 读侧闸门 | `MilPresentation.cs:970` `if (!channel.IsTargetRooted(target))` | **只允许在"设定该根的那条通道"上投影那个句柄** |

**为什么必须有**（设计稿 §3.3）：句柄是**每通道槽号**（`MilResourceTable.cs:30/108-112` 从 1 各自下发 ＋ `_freeHandles` 弹栈复用），
而 `DuplicateHandle` 让两通道的表指向**同一个 `MilTarget` 实例**（`MilResourceTable.cs:103`）⇒ `t.Root` 在 OOB 通道 3 上**也看得见**，
但那个**数值**在通道 3 上无效 —— 通道 3 只有 `资源=4`，拿主通道的 `0x893` 去查它自己的表**可能命中无关 visual** ⇒
会**静默把别人的树画出去**。`channel.GetVisual(handle) == null ⇒ 跳过` **不足以**排除这种别名（别名恰好命中时非 null）。
> **实测兑现**（§2.4）：通道 3 的 2 个目标各打一条 `无根视觉（本目标未 SetRoot 或根子树不属本通道）`，**不予呈现**，
> 且通道 3 的 `committed/failed` 全 0 ⇒ **没有画错树的路径**。

#### D3 · 尺寸逐目标 ＋ **打出"尺寸来源"**（G3）
`MilPresentation.cs:1028-1070`：三个候选全部进台账 —— `候选 HwndTargetCreate=… WindowRect=… X11=…` ＋ `尺寸来源=`。
既有语义 **一字未改**（`WindowRect` 优先；X 尺寸**仅当"自上次呈现以来变了"**优先）。
**实测踩到了设计稿 §4-D5 预言的陷阱**：
```
▸ 按目标呈现：通道 2 → HWND 0x200008 … 尺寸=1x1 尺寸来源=WindowRect
   （候选 HwndTargetCreate=1x1 WindowRect=1x1 X11=413x274）
```
⇒ 弹窗目标的 `Width/Height` **和** `WindowRect` 都还是 `1x1`（窗口先按 1×1 建、`SetRoot` 就在此时），而 X 窗口已是 `413x274`；
首次呈现 `haveLast == false` ⇒ **X 尺寸优先那条不触发** ⇒ 首帧按 **1×1** 渲（`已呈现 1x1，skia 指令 0 条`）。
**随后自纠**：`WindowRect` 更新到 413×274 ⇒ `已呈现 413x274（skia 指令 29 条）`，P2/截图证明最终画面完整。
⇒ **`D5-备选B` 刻意未落**，理由见 §5.3（读数不要求 ＋ 它会碰到主窗启动那一格）。

#### D4 · 静态统计的**逐目标取值**（G4）
`MilPresentation.cs:1090-1100`（渲染后立刻抓本地量）＋ `:196-220`（`TracePresentResult` 改为**收参**，不再读进程级静态）
⇒ `▸ 本目标指令数：HWND … skia 指令 N 条` 是**本目标**的读数，且 `已呈现/首个有内容/尺寸变化` 三条既有台账的
「skia 指令 N 条」也改成**本帧**的值（格式串一字未动）。

#### D5 · 预检**下沉**到唯一汇聚点（同趟补的台账盲区）
| 处 | 行 | 内容 |
|---|---|---|
| 下沉点 | `MilChannel.cs:247`（在 `Commit()` 里） | `if (MilPresentation.DiagnosticSinkEnabled) PreflightPendingCommands();` |
| 实现 | `MilChannel.cs:451-500` | 输出格式**逐字沿用**原 `MilNative.cs:95-129`；改成直接读自己的 `_batch`/`_commandLengths` ⇒ **反射与 `using System.Reflection` 一并删掉** |
| 旧点 | `MilNative.cs:88-92` | 留转指注释（`PreflightPendingCommands` 与调用点已删） |
| 载荷为空那一支 | `MilNative.cs:335-350` | 补一条**不受 id 过滤**的「★载荷为空 ⇒ 命令没进桥」（设计稿 §3.4 点名的仪器缺口） |

**为什么必须下沉**：`Commit()` 今天有**四条**调用路径 —— ① `MilConnection_CommitChannel`（旧预检**只在**这条）、
② `WgxConnection_SameThreadPresent`、③ `FlushPendingCommandsBeforeInvalidation`（收尾 flush）、
④ `MilComposition_SyncFlush`（`MilNative.Window.cs:232`）。弹窗那条 `SetRoot` 走的是 ②③④ 之一 ⇒ **派发了、台账里看不见**。

#### D6 · 行为预算（G7）
`MilChannel.cs:152`（`CmdLogWhitelistSet`，与 `[CMD]` 台账**共用** `WPF_LINUX_CMDLOG_ID`，不新增变量）
＋ `:441-449`（`PreflightBudget`，`WPF_LINUX_PREFLIGHT_BUDGET`，默认 20000 行）＋ `:451-500`（白名单 ⇒ 只明细打印命中 id 的命令；
无白名单 ⇒ 套预算，用尽打一行「明细预算用尽」**不静默**）。**只影响打印**，判定语义零改动。

#### 未改（KEEP，逐条对照设计稿 §4-D6/§7）
`_presentCalls` 每通道 +1｜`_framesPresented` 每成功目标 +1｜单目标 + 未绑 HWND ⇒ `E_FAIL` ＋ Note 含 `未绑定呈现目标`｜
单目标 + 无根 ⇒ `S_OK` ＋ Note 文案 `无根视觉（未 TargetSetRoot）`**逐字保留**｜无窗口目标 ⇒ `S_OK` ＋ 原文案｜
单目标路径**先通道快照、后现投影**（同序）｜`IMilChannel.Root` **保留**（还有 2 个诊断读者：通道普查 `root=有/无` 与 `ROOTDIAG` 快照）。

---

## §2 三条 grep 的改前/改后原文

**两趟都是"旧桥 vs 新桥"的同一装置**（`$HOME/w46-popup-verify.sh <out> <display>`，私有 app 目录 ＋ 私有 display；
`HC_DROP_OPEN_AT=25`）：改前 `$HOME/w46g-run/preA`（桥 `6fac9e722299a768`）、改后 `$HOME/w46g-run/postA`（桥 `e3ea092010734f44`）。

### 2.1 ① 弹窗当过一次呈现目标
```
改前：grep -c '已呈现.*0x200008'  $HOME/w46g-run/preA/mil.log  = 0
改后：grep -c '已呈现.*0x200008'  $HOME/w46g-run/postA/mil.log = 0     ← ⚠️ 派单书这条口径**词序敏感、恒 0**，见下
改前：grep -c 'HWND 0x200008 已呈现'  = 0
改后：grep -c 'HWND 0x200008 已呈现'  = 2
改后原文（$HOME/w46g-run/postA/mil.log，两条）：
  4228:  ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200008 已呈现 1x1（skia 指令 0 条，未画种类 0）  累计帧数 = 18
  4395:  ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200008 已呈现 413x274（skia 指令 29 条，未画种类 0）  累计帧数 = 22
```
**点名勘误**：真实行形是 `通道 N → HWND 0x… 已呈现 WxH`（HWND 在 `已呈现` **之前**）⇒ `已呈现.*0x200008` 在任何时候都匹配不上。
**判据① 的正确口径**：`grep -c 'HWND 0x200008 已呈现'`（改前 **0** → 改后 **2**）。

### 2.2 ② 主窗口按弹窗尺寸出帧 = 0
```
改前：grep -c 'HWND 0x200004 已呈现 413x274' = 0   （现场实测；⚠️ 见下"改前=1"的历史口径）
改后：grep -c 'HWND 0x200004 已呈现 413x274' = 0
改前：grep -c '已呈现 413x274' = 0
改后：grep -c '已呈现 413x274' = 1   ← 这一条**指向 0x200008（弹窗）**，不是主窗
```
**点名勘误（重要）**：派单书写"② 改前 = 1"。**在今天的树上改前已经是 0** ——
那 1 条是**缺陷 A**（`ConfigureNotify` 归属错窗）的读数，**已被 `W46A` 修掉**（`build/MilBridge/W46A-report.md` §3.3：
`iso-post` 两趟 `HWND 0x200004 已呈现 413x274` **= 0**）。所以判据②在**本车道动手之前就已是 0**，
它在本轮里的作用是**防回归**（确认我没有把弹窗内容画到主窗），**不是**本轮的收益来源。

### 2.3 ③ `[CMD] 派发 id=0x35` = 2 且 **preflight 现在也看得到 2 条**
```
改前（preB，WPF_LINUX_CMDLOG=1 WPF_LINUX_CMDLOG_ID=0x35）：
  grep -c '派发 id=0x35' app.log      = 2
    12:[CMD] ch=2 派发 id=0x35 handle=0x00000003 len=12
   152:[CMD] ch=2 派发 id=0x35 handle=0x00000894 len=12
  grep -c 'preflight.*id=0x35' mil.log = 1        ← ★ 台账盲区：弹窗那条**被派发却没进预检**
    32:[preflight] 通道 2 待提交 #4: id=0x35 (MilCmdTargetSetRoot) len=12 handle=0x00000003 在资源表里=True
改后（postA，同一组 env）：
  grep -c '派发 id=0x35' app.log      = 2
    37:[CMD] ch=2 派发 id=0x35 handle=0x00000003 len=12
   629:[CMD] ch=2 派发 id=0x35 handle=0x00000894 len=12
  grep -c 'preflight.*id=0x35' mil.log = 2        ← ★ 盲区已闭
    25:[preflight] 通道 2 待提交 #4: id=0x35 (MilCmdTargetSetRoot) len=12 handle=0x00000003 在资源表里=True
  4211:[preflight] 通道 2 待提交 #4: id=0x35 (MilCmdTargetSetRoot) len=12 handle=0x00000894 在资源表里=True
```
⇒ **两条命令、两个不同句柄（`0x3` / `0x894`）、两条都在预检里**（设计稿 §8.3 的前置判据**已过**）。

### 2.4 新增台账（把"呈现给谁 / 谁的根 / 多大"变成读数）
```
$HOME/w46g-run/postA/mil.log
   28:  ▸ 按目标呈现：通道 2 → HWND 0x200004（本通道 1 个目标里的第 1 个） target.Root=0x2
        根来源=目标自己的根（本次重投影） 尺寸=800x600 尺寸来源=WindowRect
        （候选 HwndTargetCreate=800x600 WindowRect=800x600 X11=800x600） 清屏色=(0.00,0.00,0.00,1.00)
   30:  ▸ 本目标指令数：HWND 0x200004 通道 2 尺寸=800x600 skia 指令 0 条 未画种类 0 root=0x2
 4226:  ▸ 按目标呈现：通道 2 → HWND 0x200008（本通道 2 个目标里的第 2 个） target.Root=0x893
        根来源=目标自己的根（本次重投影） 尺寸=1x1 尺寸来源=WindowRect
        （候选 HwndTargetCreate=1x1 WindowRect=1x1 X11=413x274） 清屏色=(1.00,1.00,1.00,0.00)
 4227:  ▸ 本目标指令数：HWND 0x200008 通道 2 尺寸=1x1 skia 指令 0 条 未画种类 0 root=0x893
```
- **两条台账的 `target.Root` 不同**（`0x2` vs `0x893`）⇒ 设计稿 §8.2「两扇窗的根是**两个不同句柄**」判据**成立**；
- `ROOTDIAG 通道2 target.Root=0x893 快照子=0 活投影子=1 镜像visual=1020 从根可达=57 孤立=964` ⇒
  **弹窗那棵树从根可达 57 个 visual（> 1）** ⇒ 设计稿 §8.1-4 / G5 的机器判据**成立**（不是空树、不是一块纯色）；
- 通道 3（OOB）**不予呈现**、也不再被写成缺陷：
  `NOTE WgxConnection_SameThreadPresent: 通道 3 → HWND 0x200004 无根视觉（本目标未 SetRoot 或根子树不属本通道）`
  （**16 条**新文案）；多目标通道上**不再出现**那条误导性的单目标文案（改前 `通道 3 无根视觉` **12 条**）。
  残留 6 条旧文案来自「当时通道 3 只有 1 个目标」的**单目标退化路径**（KEEP-4，**应当**逐字保留）。

### 2.5 通道普查（`WPF_LINUX_MIL_TRACE=1`，末次快照）
```
  通道#2: committed=3622 notimpl=0 failed=0 short=0 pending=0 … 资源=2295 root=有 [MilVisualResource×1017] [MilHwndTarget×2] …
  通道#3: committed=13  notimpl=0 failed=0 short=0 pending=0 … 资源=4   root=无 [MilVisualResource×2] [MilHwndTarget×2]
```
两条通道的 `failed=0 / notimpl=0 / short=0` ⇒ **没有因为按目标呈现而出现派发失败**（G2 的口径在真应用上没有被触发的形态）。

---

## §3 像素判据（`VERDICT.txt` 四条 ＋ 截图路径）

**装置**：`bash $HOME/w46-popup-verify.sh $HOME/w46g-run/postA :50`（脚本自身的自起 X、程序化开下拉、四条判据、写 `VERDICT.txt`）。

### 3.1 四条判据（改前 → 改后）

| 判据 | 改前（`preA`/`preB`，旧桥） | 改后（`postA`，新桥） | 结论 |
|---|---|---|---|
| **P1** 弹窗存在且几何合理 | `PASS geom=413x274+559+356` | `PASS geom=413x274+559+356` | 几何未变 |
| **P2** 弹窗下半区出画 | `FAIL 色数 pre=66 post=1` | **`PASS 色数 pre=66 post=152`** | ★ 本轮的像素收益 |
| **P3** 下半区变化量 | `FAIL AE=3779` | `FAIL AE=12220（3.2×，但仍 < 20000）` | 见 §3.3 |
| **P4**（辅助）全屏变化量 | `FAIL AE=11630` | `FAIL AE=28302（2.4×）` | 辅助 |
| `AUX_flat_block` | `yes`（色数=1 ∧ entropy=0） | **`no`**（色数=152 ∧ entropy=0.1058） | 反面判据被否掉 |
| `AUX_hist_post` 前三色 | `255,255,255 ×103250`（纯白） | `#FFFFFF ×94690 / #326CF3 ×3120（蓝底选中条） / #5E5E5E ×883（文本）` | 有内容 |
| `AUX_force_open` | `seen open=True` | `seen open=True` | 输入侧前提成立 |
| `AUX_app_exception_lines` | 0 | **0**（`XIO` 0 条，未崩） | 无异常 |

`VERDICT=FAIL`（P1∧P2∧P3；**唯一未过的是 P3 的阈值**，见 §3.3）。

### 3.2 截图留档（**肉眼复核**，反面判据要求的第二条腿）
| 文件 | 内容 |
|---|---|
| `$HOME/w46g-run/postA/pop_post.png`（413x250，2153 B，152 色） | 弹窗下半区原尺寸 |
| `$HOME/w46g-run/postA/pop_post.2x.png`（826x500） | ★ **放大留档**：蓝底选中条 ＋ 8 项 `正文正文2…9` 文本 ＋ 分隔线 |
| `$HOME/w46g-run/postA/pop_pre.png`（66 色，近纯白） | 打开前同区域（对照） |
| `$HOME/w46g-run/postA/pre.png` / `post.png` | 全屏两帧 |
| `$HOME/w46g-run/postA/VERDICT.txt` | 四条判据 ＋ AUX 原始读数 |

### 3.3 **P3 = FAIL 的归因（如实，不调阈值）**
`P3` 的口径是「下半区 `compare -metric AE` **> 20000**」（阈值由 `W46D` 以"修前实测 3779"标定，理由写死在脚本顶部常量）。
实测 `AE=12220`。**这不是"弹窗没画全"**，三条独立旁证：
1. **色数与直方图**：下半区 `103250` 像素里 `94690` 仍是**白**（下拉列表的白底），**只有 ~8560 像素非白**
   （蓝选中条 3120 ＋ 灰文本/边框/分隔线）⇒ **AE 的上界本来就只有 ~1 万量级**；
   改前的 `3779` 之所以"小"，是因为改前该区域**几乎全是白**（99471 白）而差异只来自"盖住了页面里那块灰底"。
2. **修前/修后的语义不同**：`P3` 的 20000 是在"弹窗被画成一整块白"的几何下拍的；**修好后内容是一张白底列表**，
   区域 AE 与"画没画内容"之间的关系变了 ⇒ 这条阈值对**修后形态**标定过高（**口径问题，非产品问题**）。
3. **真正的机械判据在本轮是 P2 ＋ ROOTDIAG**：`色数 1 → 152`（P2 PASS）、`AUX_flat_block=no`、
   `从根可达=57`、`skia 指令 29 条` 四条同时成立 ⇒ "不是纯色、确实画了一棵树"。
⇒ **我没有改任何阈值**（判据页明令"登记口径不许放宽"）。建议（留给主控/判据页作者）：
把 P3 的判据改成「**下半区非白像素数** > 阈值」，或按内容形态把 AE 下界重标（实测修后 `12220`）。
**两趟独立跑读数完全相同**（`P2 66→152`、`P3 12220`、`P4 28302` 在 `postA`/`postB` 逐位相同）⇒ 可复算。

---

## §4 G1–G7 逐条覆盖（主控转达的 W46F 评审）

| # | 要求 | 状态 | 落点 / 读数 |
|---|---|---|---|
| **G1** | `CollectTargets` 全列目标**并按句柄升序** | **已覆盖** | `MilPresentation.cs:803 keys.Sort();`（＋`:784-807` 注释写清"不排序则每趟顺序可漂、读数不可复算"）。见 §2.4 的「第 1 个 / 第 2 个」 |
| **G2** | 返回码：**单目标逐字等价旧实现；多目标"全部失败才带出失败"** | **已覆盖** | `MilPresentation.cs:916-930`；`exports.cs:376 HRESULT.Check` ⇒ 防"弹窗一关、主通道每次 Commit 都 E_FAIL"；失败仍进 `TargetsSkipped`（`:86`）＋ 一行点名。**真应用实测 `failed=0`**、app 零异常、零 `XIO` |
| **G3** | 尺寸**逐目标** ＋ 打**尺寸来源** | **已覆盖** | `:1028-1070`；台账 `尺寸=… 尺寸来源=WindowRect（候选 HwndTargetCreate=1x1 WindowRect=1x1 X11=413x274）` ⇒ **1×1 陷阱实测确认存在**（§1.2-D3） |
| **G4** | `DrawnCommands` 等是进程级静态 ⇒ **不许当逐目标判据** | **已覆盖** | `:1090-1100` 渲染后立刻抓本地量；`:196-220` `TracePresentResult` 改为**收参**；新增 `▸ 本目标指令数`（主窗 0 条@首帧 / 弹窗 29 条@413x274） |
| **G5** | `WPFGFX_ROOTDIAG=1` ＋「**从根可达 > 1**」必须进验收 | **已覆盖** | 本趟显式打开该开关：`ROOTDIAG 通道2 target.Root=0x893 … 从根可达=57 孤立=964`（弹窗）／`target.Root=0x2 … 从根可达=960`（主窗） |
| **G6** | 文档口径（`KNOWN-DEFECTS.md` / `PROGRESS.md` / `patch-…trace.py` 顶部注释里的"弹窗从没收到 SetRoot""通道 3 无根"） | **未覆盖（越界）** | 那三处都在**主控写域**（派单书明令"不许改判定输入/`samples/**`/`docs/*`"）。**本报告给出可直接引用的锚文本**：① 误导文案计数改前 **12 条全部是通道 3**、通道 2 一条都没有；② 通道 2 `[MilHwndTarget×2]`；③ `[preflight] … id=0x35` 改前 **1** 条 / 改后 **2** 条（`0x3`/`0x894`） |
| **G7** | 预检下沉后**别让日志爆** | **已覆盖（实测）** | 幂等形式：白名单（复用 `WPF_LINUX_CMDLOG_ID`）⇒ 只明细打印命中 id 的命令，**不受预算限制**；无白名单 ⇒ `WPF_LINUX_PREFLIGHT_BUDGET`（默认 20000 行）。**实测**：无白名单整趟 `mil.log 788,421 B` / preflight **3641 行**（明细 3630，**预算未触**）vs 改前同一装置 `785,136 B` / 3621 行 ⇒ **+0.4%**（W46F 担心的"几十 MB"**没有出现**，因为另外三条路径在本应用里携带待提交命令的次数极少：明细只 +14 行，其中就含弹窗那条）；**白名单模式 13 行 / 503,967 B**（−36%） |

### 4.1 与设计稿的**冲突/不一致**（派单书第 3 条要求点名）
1. **无模型冲突**：`D1/D2/CD3/D4/D5/D6` 与我在 20:27 起落的实现逐条一致（W46F §9 已核对过我那份在飞件）；
   本轮按 G1–G5/G7 补了 6 处，**没有**与设计稿相左的语义选择。
2. **勘误 1（判据口径）**：设计稿 §8.1-1 写的 `grep -c '已呈现.*0x200008'` 与我实测一样**恒 0**（词序）；
   主控/派单书的判据①因此**不能**当判据。见 §2.1。
3. **勘误 2（"两次独立呈现"的读数）**：设计稿 §8.1-2 要 `FramesPresented +2 / PresentCalls +1`。
   本趟日志只对该**采样点**打台账（`n<=5 || n%120==0`）＋每次尺寸变化免采样，所以"同一次 Commit 里两个目标"的
   **成对帧号**不是直接可见的：实测读到的是弹窗首帧 `累计帧数 = 18`、末帧 `22`，主窗首帧 `1`、首个有内容帧 `3`
   ⇒ `+2/+1` 只能由"帧号差与调用序"推出，**不是直接读数**（标为本轮 NOINFO 之一，见 §9）。
4. **勘误 3（W46F 的"主窗应回到 ≈443"）**：本趟主窗**唯一**的免采样行是首帧（`800x600，0 条`）与
   首个有内容帧（`800x600，14 条`）；**没有**晚期的 800×600 台账行可读（未触尺寸变化、未落 `n%120`）⇒
   `443` 这个数**本轮取不到**。改用**更强的替代判据**：跨桥**逐像素 `AE=0`**（§6.2）。

---

## §5 单窗口回归（防"修一处坏一处"）

### 5.1 帧存在性（时间分辨）
```
$ bash build/MilBridge/tools/frame-presence-check.sh --app-args="--late-content" --seconds=15 --min-colors=200
采样 30 帧 → /home/links-dev/w34-framepresence-203516
FRAMEPRESENCE=PASS frames=30 max_colors=3961 magenta_frames=n/a min_colors=200   rc=0
```
（该装置的 app 目录里 `wpfgfx_cor3.so` **逐件 = `e3ea092010734f44`** ⇒ 跑的是**新桥**。）

### 5.2 冻结门禁（`WpfTextDemo` 两档 × 3 rep）—— **与冻结基线逐位相同**
```
$ bash tests/WpfGfx.Linux.Tests/Presentation.Tests/run-wpftextdemo.sh 45      # WPTD_RC=0
WPTD_TIER=default rep=1 RESULT=PASS exit=143 notdrawn=0 drawn=260 colors=3960 frames_good=14 frames_total=14
   frames_blank=0 scroll=ok/139705 capture=ok max_concurrent_apps=1 leftover_after=0 cross_ae=0   （rep=2/3 同）
WPTD_TIER=env     rep=1 RESULT=PASS exit=143 notdrawn=0 drawn=144 colors=2828 frames_good=14 frames_total=14
   frames_blank=0 scroll=ok/135468 capture=ok max_concurrent_apps=1 leftover_after=0 cross_ae=0   （rep=2/3 同）
判据② skia 指令 260 / 144 条 > 0 且 未画种类 = 0 ✅     判据③ 有有效帧 ✅（3960 / 2828 色 ≥ 200）
判据④ 特性色齐全 ✅                                    判据⑦ 行推进 distinct_origin_y=12（阈值 10）→ PASS
WPTD_SUMMARY=PASS tiers_passed=2/2
```
对照冻结基线 `samples/WpfTextDemo/ACCEPTANCE-BASELINE.md:58-60`：
`result=PASS exit=143 drawn=260 notdrawn=0 frames_good=14 frames_total=14 frames_blank=0 capture=ok scroll=ok
 shot_dims=938x938 colors=3960 cross_ae=0 max_concurrent_apps=1 leftover_after=0`
⇒ **逐字段相同**（唯一差别是 `config` 里的 `bridge:496951adff86a557 → e3ea092010734f44`，即本轮重发的桥；预期位移）。
该趟部署的桥同样是 `e3ea092010734f44`（`wptd3/wpfgfx_cor3.so` 实测），且台账里有本轮新增的 `▸ 按目标呈现` 行 ⇒ **跑的是新桥**。

> ⚠️ **我自己踩到并已定位的一次自伤（如实登记）**：第一次跑该门禁时判据②报
> `❌ 指令数最多的一帧仍是空帧（skia 指令 0 条）`。原因是**我在同一个 shell 里 export 了 `WPF_LINUX_MIL_LOG`** ——
> 它把 `DiagnosticSinkEnabled` 打开，于是 `[create] 通道 2 …` 逐资源台账**每资源一行**灌进 stderr，
> 把 `WPF_LINUX_MIL_TRACE` 的 **400 行 stderr 预算**在内容帧之前烧光（实测那一趟 `maxseq=400`、`[create]` **358 行**）；
> 而**改前的冻结日志里 `[create]` = 0、`maxseq=52`**（`/home/links-dev/w39-gate-b/wpftextdemo-env-r3.log:41,56`，
> 同样两条计数行、其中 `首个有内容 的帧 … skia 指令 144 条`）。
> **清掉该变量重跑 ⇒ `WPTD_SUMMARY=PASS tiers_passed=2/2`**（§5.2 的读数）。
> ⇒ **判据② 的那次 FAIL 是仪器自伤，不是产品回归**；同一族（"仪器把读数吃掉"）在本项目已有先例，本轮再次复现。

### 5.3 跨桥逐像素 A/B（主窗"一丝不动"的**直接**证据，替代 W46F 的 443 读数）
| 比较 | 裁剪 | AE | 说明 |
|---|---|---|---|
| **旧桥.pre vs 新桥.pre**（同一时刻，下拉未开） | 主窗左侧 `300x600+240+212` | **0** | 色数 390 = 390 |
| 同上 | 弹窗矩形 `413x274+559+356` | **0** | 色数 66 = 66 |
| 同上 | **全屏 `1280x1024`** | **0** | 色数 443 = 443 ⇒ **整屏逐像素相同** |
| **旧桥.post vs 新桥.post**（下拉已开） | 主窗左侧同裁剪 | **0** | ⇒ 下拉打开后**主窗区仍然一致** |
| 同上 | 全屏 | `17185` | ⇒ 差异**只**发生在弹窗矩形内（=新画的列表） |
| 同桥 pre→post（对照，两桥都算） | 主窗左侧 | `5891`（**旧桥 = 新桥，同一数值**） | 差异 bbox `212x29+28+476`（一条文本行）⇒ 是**应用自身**"下拉打开"引起的状态变化，**两桥一致**故与本改动无关 |
| 同桥跑两趟（`preA` vs `preB`） | 主窗左侧 / 全屏 | `0` / `0` | 装置可复算（时间抖动为 0） |

---

## §6 桥产物 ＋ 私有/共享目录 ＋ 世代位移

| 件 | sha16 | 大小 | mtime |
|---|---|---|---|
| 发布件 `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` | **`e3ea092010734f44`** | **5,019,968 B** | 2026-09-19 20:33:12 |
| 我的**私有** app 目录 `$HOME/w46g-app/wpfgfx_cor3.so` | `e3ea092010734f44` | 5,019,968 B | **与发布件同 sha（逐字节）** |
| 改前那件（备份） | `6fac9e722299a768` | 5,000,192 B | `$HOME/w46g-backup/wpfgfx_cor3.so.pre46g` |

- 构建：`bash build/MilBridge/run.sh build` ⇒ **`rc=0`**、`清单 109 个 / .so 实到 111 个；缺失 0；额外（诊断面）16`（与改前同一口径）。
- **共享 hc 应用目录零触碰**（构建前 = 构建后逐位相同）：`libwpfwin32.so e700c383ec1ecdc8`／
  `wpfgfx_cor3.so **6fac9e722299a768**`（**仍是旧件，我没动它**）／`PresentationCore.dll b1d3d5f33618a3d7`。
  实测依据：`stat -c %h` 两件 `links=1` 且 inode 不同，仓库里**没有**任何把发布件拷进 hc 目录的机制
  （`grep -rn 'hc-linux' build/ --include='*.sh' --include='*.csproj' --include='*.props'` = 0 命中）
  ⇒ `W46C` 报告 §4 里"publish 会自动刷新 app-local"那条推论**不成立**（推测是别的车道手工 `cp` 的）。
- **世代位移（预期，非缺陷）**：`BRIDGE_SRC_FP` **`794ea22406cc88ab` → `f10b4b297b2358e6`**（现场 `bash build/bridge-src-fp.sh` 复算，
  `BRIDGE_SRC_N=78` 未变）⇒ 门禁打出 `WPTD_BRIDGE_SRC_STALE=yes basis=pub=794ea22406cc88ab now=f10b4b297b2358e6 so_file_match=no`，
  正是设计稿 §10-4 预言的 `BRIDGE_SRC_FP 必变 ⇒ NEED_BRIDGE=1 ⇒ 冻结点需重钉`（**主控收尾序列**）。
  ⚠️ 桥的**输入件**（世代绑定三项 `run.sh`/`HbTextLineParity Program.cs`/`PresentationCore.HbTextLine.cs`）**一件未动** ⇒ 按纪律 34 **无需重取臂**。

---

## §7 纪律：备份、复原与零污染

### 7.1 ⚠️ **我自己的纪律缺口（如实登记）＋ 已用可复算方式补齐**
派单书要求"改既有文件**前** `cp -p` 备份"。**我对这 4 件都是先改后备份的**（动手前只算了 `sha256sum`，没有先落副本）。
补救方式（**不是"补个副本就行"，而是"证明 pre-state 可复原"**）：
- 我把四处改动**逆向**写成脚本 `$HOME/w46g-run/reconstruct_pre.py`（只做逆替换，不做任何"接近"），
  对 4 件各生成 `$HOME/w46g-backup/<件>.pre46g-reconstructed`；
- 判据是**逐位比对**：复原件 `sha256` 必须等于**动手前现场算出的值**。结果：
```
MilPresentation.cs        复原=ee89f32def7c98d2  记录=ee89f32def7c98d2  SAME
MilNative.cs              复原=ee4a0e8dd82b0cab  记录=ee4a0e8dd82b0cab  SAME
MilChannel.cs             复原=dcc34a49e0f7176d  记录=dcc34a49e0f7176d  SAME
MilCommandDispatcher.cs   复原=b0ddcd23f3e0cbca  记录=b0ddcd23f3e0cbca  SAME
RECONSTRUCT_RC=0
```
⇒ **pre-state 逐字节可复原**（本报告的 before sha16 与 `+N/−N` 都是拿它当基准算的），
但**"改前先备份"这条纪律我确实违了**，请主控按纪律记账。

### 7.2 零污染
- 仓库内写入面 = **§1.1 的四件** ＋ 新建 `build/MilBridge/W46G-report.md`；`git` 不存在，用 `find -newermt` 佐证只有这 4 件 `.cs` 被动过。
- **未改**（派单书点名的禁改项，逐条 `sha256sum` 现场核过）：`build/MilBridge/known-red.json`、`arm-logs/**`、
  `verify-all.sh`、`build/close-wave.sh`、`*.tsv` 名册、`samples/WpfTextDemo/ACCEPTANCE-BASELINE.md`、`docs/WAVE46-PERTARGET-PRESENT-DESIGN.md`。
- **未跑**：`integration-wave.sh`、`verify-all.sh`、任何冻结/收尾脚本；**未 `pkill -f`**；**未起服务器**。
- 所有实验都在 `$HOME/w46g-run/**`、`$HOME/w46g-app/`、`$HOME/w46g-backup/` 下；被测应用跑在**私有 app 目录 ＋ 私有 display**（`:48/:49/:50/:51`）。

---

## §8 我没做到 / 取不到的（`NOINFO`，逐条）

1. **五臂/门禁/`verify-all` 的位移读数**：派单书禁止跑 `verify-all.sh`/`integration-wave.sh`/冻结 ⇒ 未取。
   （本件改了 `src/WpfGfx.Linux/**` ⇒ `BRIDGE_SRC_FP` 必动、`BASELINE-SHA` 类别会红，属**预期位移**，由主控在冻结点重钉。）
2. **`FramesPresented +2 / PresentCalls +1` 的成对读数**（设计稿 §8.1-2）：台账只在采样点/尺寸变化时打印，
   本趟没抓到"同一次 Commit 里两个目标"的相邻两帧 ⇒ **只能由帧号差推断，不是直接读数**（§4.1-3）。
3. **W46F 点名的"主窗晚期 ≈443 条指令"**：本趟主窗没有晚期免采样台账行 ⇒ **未取到**；已用 §5.3 的跨桥 `AE=0` 替代。
4. **`D5-备选B`（把"从未呈现过的目标"改成以 X 尺寸为准）刻意未落**：读数**不要求**它
   （1×1 首帧后已自纠到 413×274，P2/截图/`从根可达=57` 三条齐证最终画面完整），
   而它**会**碰到既有注释明令保护的"800×600 vs 640×400 首帧"那一格（`MilPresentation.cs:1046-1052` 的注释）。
   若主控要落，**窄口径**版本（只在"记录尺寸退化成 1×1 而 X 为真实尺寸"时按 X）我已写好思路，但**未实现、未实测**。
5. **`G6` 文档口径未改**（主控写域）⇒ `KNOWN-DEFECTS.md` 的 `D-G54` 节仍带着"通道 3 无根视觉"式的误导表述；
   `patch-presentationcore-hwndtarget-trace.py` 顶部注释与 `WAVE46-PREREGISTRATION.md:166-170` 同样过期。
   **锚文本已在 §4 的 G6 行给出**。
6. **P3 阈值未调**（判据页明令不许放宽）⇒ 门禁总判仍 `VERDICT=FAIL`；`P3` 归因见 §3.3。
7. **`[create]`/`[preflight]` 台账会吃 stderr 预算**：实测 400 行预算被 `[create]`（358 行）烧光，
   导致**基于 stderr 的判据**（如 `WPTD` 判据②）在"同时开着 `WPF_LINUX_MIL_LOG`"时会失去内容帧那一行。
   本轮**没有**去改这个仪器（超出本件边界），但**必须登记**：任何"既开 `MIL_LOG` 又读 stderr 台账"的跑法都要小心。
8. **`known-red.json` 未动**：本轮不登记新红（弹窗已出画；主窗回归与冻结基线逐位相同 ⇒ 无处需要新红）。
9. **未取到的读数**：弹窗目标 `WindowRect` 为何一度为 1×1 的**上游**归因（只能看到桥侧读数）；
   两条 `SetRoot` 各自由哪一条提交路径（②③④）携带（只证明"预检现在覆盖全部四条"）。

---

## §9 报告自身指纹

- 文件：`/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/W46G-report.md`
- 口径：指纹 = `head -n -2 <本文件> | sha256sum | cut -c1-16`（丢掉**末两行**＝下面的空行与指纹行，可当场复算）

- **sha16 = `23f9b903ea38c079`**

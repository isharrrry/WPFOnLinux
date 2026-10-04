# W62A —— `D-G58`（hc「工具」页 #2 `Effects` 一打开就未处理异常）修法落地报告

> 车道 **W62A**｜判据来源 = `docs/WAVE49-PREREGISTRATION.md` **§7.4**（W52A 取证 → 主控写死）
> 写域 = `src/WpfGfx.Linux/Commands/**` ＋ `src/WpfGfx.Linux/Resources/**`（＋ 本报告）
> 仓根 `$R` = `/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> **结论在前**：修法已落地并重建（新 `wpfgfx_cor3.so` = **`79e45aed26487045`**）；**正极性拿到**
> （`Effects` 页 `alive=yes`、`unhandled=0`、该批 `notimpl=0`、`failed=0`、12 条具名台账）；
> **反极性按主控 00:2x 排程裁定"延期到 `#50`"**（本波只交正极性 → §3 如实记 `NOINFO` 与复算命令）。

## §0 环境

| 项 | 值 |
|---|---|
| 内核 / `nproc` | `6.8.0-138-generic` / `3` |
| `MemAvailable`（**采样**，不是连续最小） | 开工（构建前）`2684 MB` → 构建后 `2575` → 正极性趟 `2438→2450` → 收工 `1537 MB` |
| `loadavg` | 开工 `1.46` → 正极性趟 `2.45` → 收工 `4.26`（本机同时 **5 条车道**：W59A/W60A/W61A/W62A/W63A） |
| 私有应用目录 | `$HOME/w62a/app`（`cp -a` 自 hc demo 的 `bin/Debug/net10.0`，再 `sync-applocal.sh`） |
| 私有显示 | `:197`（`Xvfb :197 -screen 0 1280x1024x24`，未起 WM）；`:0/:1/:10/:191/:192/:196` 全程未碰 |
| 重活槽 | 每条"起应用 / 构建"的命令**整条**包进 `bash ~/heavy-slot.sh -- …`（主控 23:5x 裁定） |
| 本报告 sha16 | 见文末（正文写完才算） |

**五件 sha16（开工 = 冻结基线；收工与开工**逐位相同**，见 §2 的 `ART_BEFORE/ART_AFTER`）**

| 件 | 开工 | 收工 |
|---|---|---|
| `libwpfwin32.so` | `054037aadfd7d192` | `054037aadfd7d192` |
| `wpfgfx_cor3.so` | `e3ea092010734f44` →（修后）**`79e45aed26487045`** | `79e45aed26487045` |
| `PresentationCore.dll` | `9465f9dce39e2dfc` | `9465f9dce39e2dfc` |
| `PresentationFramework.dll` | `1011da6390c3bf1e` | `1011da6390c3bf1e` |
| `WindowsBase.dll` | `2e4e46e539a72cd7` | `2e4e46e539a72cd7` |

> ⚠️ **归因边界**：树是 5 条车道**共享**的，`wpfgfx_cor3.so` 由整棵树决定。
> 本报告给的是「**我改的三个文件** ＋ **这一趟构建**」的读数；别把 `79e45aed26487045`
> 读成"只由本车道三处改动决定"。

### §0.1 顺带抓到并已上报的工具缺陷（**影响本机所有车道的读数环境**）
`~/heavy-slot.sh` 原先 `exec 9>"$LOCK"` + `flock` 后直接 `"$@"`，**载荷继承了 fd 9** ⇒
`dotnet build/publish` 起的 **Roslyn `VBCSCompiler` 长命孙进程把锁带走** ⇒
wrapper 打印 `HEAVYSLOT=RELEASED` 退出后 **锁仍未释放**（`flock -n` 探针 `HELD`，持有者 = `VBCSCompiler`），
**全机 6 个等待者全部饿死**。我给了机器证（`sleep 20` 孙进程复现）与一行修法；主控已落地
`"$@" 9>&-`，并补了自检例 4（`grandchild_reacquire_rc=0`）。⇒ 本报告所有"等槽"读数都带
`HEAVYSLOT=ACQUIRED waited=Ns`，**"排队时间"与"窗口没出来"分开记**。

## §1 改了什么（逐处，`文件:行` ＋ before/after sha16 ＋ 为什么）

### 1.1 `src/WpfGfx.Linux/Commands/MilCommandLayout.cs`
`4f4f3f8fc3495c16`（11,516 B）→ **`d13821c359c30db9`**（13,707 B）

| 处 | 内容 | 为什么 |
|---|---|---|
| `:118-136` | 新增 `MilCmdPixelShader => 20`、`MilCmdShaderEffect => 80`（并写清定长头的字段构成与上游行号） | 原先走 `_ => -1`（"未知命令字"）⇒ `Dispatch:43` 直接 `E_NOTIMPL`。两条是**变长**命令，这里给**固定头**长度；长度账由 `MilChannel` 的 `BeginCommand/EndCommand/SendCommand` 记（上游 `BeginCommand(ptr, sizeof(struct), cbExtra)` 直接给出）⇒ dispatcher **不必**自己解析尾部 |
| `:206-210` | `HasVariablePayload` 补两条 | 这两条**不是**定长（0x6c 尾 = `PixelShaderBytecodeSize`；0x70 尾 = 8 个 `*Size` 之和）。该函数今日**无调用者**（全仓 `grep` = 1 命中 = 定义处），补上免得"变长"只活在注释里 |
| `:221-246`（注释 `:221-235`、集合 `:236-246`） | `s_notImpl` **移出**这两条；注释计数 `7 条 → 5 条`、`C 类 6 → 4`、历史串 `38 → 17 → 9 → 7 → 5`；并写明"**不是实现了 shader**" | 修法方向①（§7.4 第一条） |

**`FixedSize` = 20 / 80 不是我算的，是既有仪器量的（12 次独立确认）**：W52A 的命令层台账
（`$HOME/w52a/out-dg58-r2-wl/app.log`，白名单 `WPF_LINUX_CMDLOG_ID=0x6c,0x70`）给出同批 12 条的
`len` 与 `extra`：`len − extra` = **20**（5 条 0x6c：240/220、404/384、1004/984、360/340、288/268）
与 **80**（7 条 0x70：92/12、110/30、110/30、452/372、452/372、110/30、110/30）。
结构侧同源：上游 `Generated/wgx_commands.cs:679`（末字段 `CompileSoftwareShader@16` ⇒ 20）、
`:725`（末字段 `DependencyPropertySamplerValuesSize@76` ⇒ 80），`Pack=1`。

### 1.2 `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs`
`748f781620ea4008`（73,664 B）→ **`62203635d795f832`**（77,412 B）

| 处 | 内容 |
|---|---|
| `:781-821` | `DispatchCore` 新增两条 `case`：`MilCmdPixelShader`（读出声明的字节码长度、整块当"已接受的资源"、`return S_OK`）、`MilCmdShaderEffect`（尾部 8 个 `*Size` 求和、按**恒等效果**、`return S_OK`）；两条都调 `ch.NoteShaderStubAccepted(...)` |
| `:1417-1428`（辅助段） | 新增 `ReadDeclaredUInt32(c, offset)`：越界返回 `-1`，**绝不抛**（一条只读诊断不许把应用打崩） |

**为什么不加线格结构体**：本仓线格结构体都在 `MilCommandStructs.cs`，且有一条**反射计数牙**
（`tests/.../CommandLayoutTests.cs:226-233`：`typeof(S).GetNestedTypes()` 数必须 == 对照表条数）。
`tests/**` **不在我的写域** ⇒ 我若往 `S` 里加两个结构，必然把那条牙打红却无法同步修。
⇒ 改成**按偏移直读**（零新类型、零反射面位移）；代价见 §6（少了 `Marshal.SizeOf` 那层护栏）。

### 1.3 `src/WpfGfx.Linux/Resources/MilChannel.cs`
`384d024ab7987dfa`（34,038 B）→ **`4a79d7437fd428ba`**（37,108 B）

| 处 | 内容 |
|---|---|
| `:84-99` | 新增 `ShaderStubCommands`（计数）、`ShaderStubRegistry`（命令字 → 条数）、`ShaderStubLenMismatch`（声明长度 ≠ 长度账 的次数）、`ShaderStubLogBudget = 8` |
| `:101-135` | 新增 `NoteShaderStubAccepted(id, handle, payloadBytes, declaredBytes)`：**具名**（id ＋ 句柄 ＋ 字节数 ＋ 声明长度）、**有界**（每命令 id 每进程 ≤ 8 行，第 9 条打一行"到上限"，此后不再逐条打印） |

输出走 `MilPresentation.Trace` ⇒ **只要设了 `WPF_LINUX_MIL_LOG` 就一定进文件汇**（`WPF_LINUX_MIL_TRACE=1` 时同时进 stderr），**不需要任何新开关**。
**为什么必须有它**（§7.4 的 🔴 条 + 纪律 47 族）：这两条从 `E_NOTIMPL` 改成 `S_OK` 后进程**不再 abort**，
"效果并没有被渲染"这件事**绝不许因此消失** ⇒ 落成三件：① 上面这条日志；② 通道计数器（与
`NotImplRegistry` 同族的形态）；③ 源码注释与 §6 里逐字写明"**效果不渲染**"。

## §2 正极性（**拿到**）

**命令（仓外仪器，逐字）**
```bash
W62A_DISP=:197 bash ~/w62a/bin/dg58.sh pos1 '0x6c,0x70'
# 仪器 sha16 = 99fa3ea647653c81；geoq.py sha16 = 732cd6b76e111477
```
**启动（逐字，包在槽里）**
```
env DISPLAY=:197 HC_INPUT_DIAG=1 HC_GEO_EVERY=2 HC_DUMP_MAX=100000 \
    WPF_LINUX_MIL_LOG=$OUT/mil.log WPF_LINUX_MIL_TRACE=1 WPF_LINUX_CMDLOG=1 \
    WPF_LINUX_CMDLOG_ID=0x6c,0x70 WPF_LINUX_PREFLIGHT_BUDGET=200000 \
    bash ~/heavy-slot.sh --wait 1500 -- timeout 300 dotnet HandyControlDemo.dll
```

**读数（`READING.txt` 逐字摘）**
```
HEAVYSLOT=ACQUIRED waited=108s cmd=timeout 300 dotnet HandyControlDemo.dll
WINDOW id=2097156 X=240 Y=212 800x600 pid=161156
READY steps=4 colors_f0=373 app_lines=690      ← 373 色 = 冻结基线首页值（就绪门三条件齐）
GEOBLOCKS begin=4 end=4
T0 alive=yes unhandled=0 app_lines=690 mil_lines=2477

=== 步骤 1：点最右页签（「工具」）===
TABRIGHT=450 318  来源=geo: [GEO] TabItem#- scr=413,305 wh=74x27 ...
after-tab alive=yes mil 2477→4768 AE(vs f0)=238109 colors=350

=== 步骤 2.0：点工具页 item[0]（HatchBrushGenerator）===
item[0] alive=yes unhandled=0  AE(vs 上一页)=6541  colors=474

=== 步骤 2.1：点工具页 item[1]（MorphingAnimation）===
item[1] alive=yes unhandled=0  AE(vs 上一页)=39765 colors=423

=== 步骤 2.2：点工具页 item[2]（Effects）===
item[2] alive=yes unhandled=0  AE(vs 上一页)=196969 colors=4843
item[2] 本击片内 notimpl=[1-9] 条数=0  ★E_HANDLE#2 条数=0  ★E_HANDLE#3 条数=0
item[2] 本击片内 [NOTIMPL-SHADER] 行数=12
item[2] [NS] loaded: [NS] loaded HandyControlDemo.UserControl.EffectsDemo ...

=== 全趟汇总 ===
FINAL alive=yes unhandled=0 app_lines=1565 mil_lines=6435 rc=143
全趟 notimpl>0 条数=0  ★E_HANDLE#2 条数=0
全趟 [NOTIMPL-SHADER] 行数=12
ART_BEFORE == ART_AFTER（五件逐位相同）
```
- **`未处理异常 = 0`、`NotImplementedException = 0`**（`grep -ac '^Unhandled exception' app.log` = `0`；`grep -ac NotImplementedException` = `0`）。
- **`rc=143`** = **我自己的收工 `TERM`**（128+15）⇒ 与"产品崩溃"无关。**本波全部读数里没有出现过 `rc=134`，也没有 `rc=137`**（见 §6 的 rc 口径）。
- **该页真的画出来了**（主控要求把 `rc` 与"页上到底画出来了没有"分开记）：`colors=4843`（同趟其它页 474/423），
  与上一页 `AE=196969`；`mil.log` 最后一条按目标呈现 `skia 指令 100 条 未画种类 0`。
- **通道总账（逐字，`mil.log` 末条快照）**：
```
  通道#2: committed=3054 notimpl=0 failed=0 short=0 pending=0 batchBytes=0 资源=572 root=有 ...
         [MilOpaqueResource×19] [MilBlurEffect×1] [MilDropShadowEffect×1] ...
```
  ⇒ 整趟 **3054 条命令，`failed=0`、`notimpl=0`**。

**同一批 243 条的"改前/改后"对照（同一仪器，`mil.log` 行号可复算）**
```
6301: [closebatch] 通道 2 待处理 243 条 ⇒ hr=0x00000000
6302: [preflight] 通道 2 待提交 #55: id=0x6c (MilCmdPixelShader) len=240 handle=0x000004a4 在资源表里=True
6303: [preflight] … #56: id=0x70 (MilCmdShaderEffect) len=92 handle=0x000004a2 …
      …（#63/#64、#71、#78/#79、#86、#94/#95、#97/#98 共 12 条，与 W52A 的 #55…#98 **同一批、同 id、同 len**）
6314: NOTE [NOTIMPL-SHADER] ch=2 id=0x6c MilCmdPixelShader handle=0x000004a4 bytes=220 declared=220 第 1 条 ⇒ **接受但按恒等处理（效果不渲染）**
6315: NOTE [NOTIMPL-SHADER] ch=2 id=0x70 MilCmdShaderEffect handle=0x000004a2 bytes=12 declared=12 第 1 条 ⇒ …
      …（共 12 行，6314-6325；**12 行全部 `declared == bytes`** ⇒ 没有一条 LEN-MISMATCH）
```
⇒ 同一条批、同一位置（#55 起）原先返回 `E_NOTIMPL`，现在 **12 条全部被接受**，且紧接其后**没有**
`★E_HANDLE#2`（失败提交）行。

**命令层台账（`app.log:1445-1456`，白名单只放这两条 id）**
```
[CMD] ch=2 EndCommand id=0x6c handle=0x000004a4 len=240  extra=220 appended=220
[CMD] ch=2 EndCommand id=0x70 handle=0x000004a2 len=92   extra=12  appended=12
[CMD] ch=2 EndCommand id=0x6c handle=0x000004ba len=404  extra=384 appended=384
[CMD] ch=2 EndCommand id=0x70 handle=0x000004b9 len=110  extra=30  appended=30
[CMD] ch=2 EndCommand id=0x70 handle=0x000000ff len=110  extra=30  appended=30
[CMD] ch=2 EndCommand id=0x6c handle=0x00000489 len=1004 extra=984 appended=984
[CMD] ch=2 EndCommand id=0x70 handle=0x00000488 len=452  extra=372 appended=372
[CMD] ch=2 EndCommand id=0x70 handle=0x00000483 len=452  extra=372 appended=372
[CMD] ch=2 EndCommand id=0x6c handle=0x0000047a len=360  extra=340 appended=340
[CMD] ch=2 EndCommand id=0x70 handle=0x0000047b len=110  extra=30  appended=30
[CMD] ch=2 EndCommand id=0x6c handle=0x00000499 len=288  extra=268 appended=268
[CMD] ch=2 EndCommand id=0x70 handle=0x0000049a len=110  extra=30  appended=30
```
（`len−extra` 逐条 = 20 / 80 ⇒ **`FixedSize` 在现场被第二条独立仪器再次确认**。⚠️ 句柄值与 W52A 不完全相同
（例：#78 的 0x6c 在我这里是 `0x489`、W52A 是 `0x488`）——那是**运行期句柄分配**的差异（我这一趟页面装得更完整、
资源表更大），与本修法无关，**不构成位移**。）

## §3 反极性（**未做 —— 按主控 00:2x 排程裁定延期到 `#50`**；本项如实记 `NOINFO`）

**要求形态**：`s_notImpl` 保持"已移出"、但 `DispatchCore` 里**没有** case ⇒ 命令落到
`default: return HResult.E_NOTIMPL` ⇒ 必须回到 `alive=no` ＋ `NotImplementedException`。

**为什么没做**：主控 00:2x 通报"机级槽 **11 个等待者**、可用内存 ~2.1 GB、用户当前三件事由
W59A/W60A/W63A 承担"，裁定：正极性已是重点、**其余收尾交报告让槽**。我据此**主动撤掉**了自己两个
已排队作业（`bash-21` = 副本里造对照/负极性两件构建；`bash-22` = `nav1 tab3` 零回归腿），
并确认收工后**无任何本车道的进程残留**、共享树与共享 `.artifacts` 逐位未动。
（撤销前我已完成不占槽的全部准备：见 §7 的 `negbuild.sh`，实测 1.7 s 建好硬链接副本、共享树零暴露。）

**已有的"负侧"证据（形态不同，不能冒充判据②）**：W52A 的前修现场（`W52A-report.md` §1.4）
= 同一批 243 条、`#55` 起 12 条 `E_NOTIMPL` ⇒ `alive=no unhandled=1`。但它走的是
**`s_notImpl` 入口短路**，不是 `default:` 兜底 ⇒ 判据②**仍未取数**。
**反证方向的一个强读数**（不是替代）：本趟 `s_notImpl` 里已无这两条，而两条 `case` 在 ⇒
12 条全绿；若"移出 `s_notImpl`"本身足以让页面活下来，那么 §1.2 的两条 `case` 就是**可删的**——
这一点**只有反极性趟能证**。⇒ **`NOINFO`，不许当绿。**

## §4 零回归

| # | 判据 | 读数 |
|---|---|---|
| ① | 同趟「工具」页 `#0`/`#1` 仍 `alive=yes` | ✅ `item[0] alive=yes unhandled=0 AE=6541 colors=474`；`item[1] alive=yes unhandled=0 AE=39765 colors=423`（同一趟、同一进程、同一批件） |
| ② | 点击/呈现腿 `W55A_STEPS="nav1 tab3"` ⇒ `alive=yes` 且两步 `AE>0` | ⛔ **延期**（作业已按主控裁定撤销，未跑）。命令见 §7；我已把 leg.sh **整条包进槽**并加了"收孤儿 dotnet"（按 `/proc/<pid>/cwd`＋`DISPLAY` 认自己，不用 `pgrep -f`） |
| ③ | `build/check-appliers.sh` 保持绿 | ✅ `APPLIER_AUDIT_SUMMARY appliers=26 ok=89 miss=0 red=0 rc=0`（本波只改 `src/WpfGfx.Linux/**`，不涉及任何 applier） |

## §5 新 `wpfgfx_cor3.so`

| 项 | 值 |
|---|---|
| 路径 | `build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` |
| before → after | `e3ea092010734f44` → **`79e45aed26487045`**（**5,019,968 B，字节数不变**） |
| 构建 | `bash ~/heavy-slot.sh --wait 1800 -- nice -n 5 bash build/MilBridge/run.sh build` ⇒ **rc=0**、`HEAVYSLOT=ACQUIRED waited=0s`、`清单 109 个 / .so 实到 111 个；缺失 0` |
| **不是"拿旧件交差"的机器证** | `strings -el wpfgfx_cor3.so \| grep -c NOTIMPL-SHADER` = **2**（托管 `WpfGfx.Linux.dll` = 1） |
| 同步进私有应用目录 | `sync-applocal.sh` ⇒ `⟳ wpfgfx_cor3.so：e3ea092010734f44 → 79e45aed26487045（回读断言通过）`、`SYNC-APPLOCAL=PASS items=5 ok=4 synced=1 rc=0` |

## §6 边界与 `NOINFO`（**请连同结论一起读**）

1. 🔴 **效果仍然不渲染**（本修法的**全部**语义就在这里）。这两条命令现在是"**收得下、按恒等处理**"：
   内容照原样画，**shader 效果不施加**。现场机器证：
   - 资源表末条快照里有 **`[MilOpaqueResource×19]`** —— 这两个句柄（`TYPE_PIXELSHADER`/`TYPE_SHADEREFFECT`）
     落的是**不透明占位资源**（`MilResourceFactory` 的 `default` 分支），**没有任何渲染侧消费者**；
   - 本趟 `未画种类 0`（`skia 指令 100 条`）⇒ 渲染层**没有**把这些效果记为"未画出"。
2. ⚠️ **新发现（既存缺陷，非本修法引入，仓内未见登记，建议主控登记）**：
   **视觉级 Effect 的句柄写了没人读**。hc 的 Effects 页把 shader 效果挂在**视觉**上：
   同一批 243 条里有 **11 × `0x1d MilCmdVisualSetEffect`**（`#57/#65/#72/#80/#87/#96/#99/#101` ＋ `#130/#137/#194`），
   与 12 条 shader 命令逐条相邻；而 `MilVisualNode.Effect` **全仓只有一个写入点**
   （`MilCommandDispatcher.cs:177`）＋ 一个**单元测试**读它（`CommandRoundTripTests.cs:89`），
   **渲染层从来不读** ⇒ 视觉级效果在**绘制前就被丢掉**（这解释 `未画种类 0` ＋ 内容照画）。
   —— 同一族的 `MilPushEffect`(0x55) 路径**已经**判 `supported=false → 内容照画 + 记 NotDrawn`
   （`SkiaRenderBackend.cs:562-591`，注释里就写着"比如将来塞进来的 ShaderEffect"），所以
   **两条路径的"不渲染"是两种不同的静默**：一条**有台账**，一条**没有**。
   ⇒ 修这条要动 `Rendering/**`（我的写域外），**本波不做**，`NOINFO`。
   📌 **自我更正（纪律：推翻自己也要如实写）**：我先按 `id=0x10` 去数 `VisualSetEffect`，得 0 命中，
   差点写成"这一批里根本没有 `VisualSetEffect`"。**`0x10` = `MilCmdPointResource`**，真正的
   `MilCmdVisualSetEffect` = **`0x1d`**（`Contracts/MilCmd.cs:67`）⇒ 重数 = **11 条**。上面用的是更正后的数。
3. **`rc` 口径（主控要求分开记）**：`rc=137` = OOM/`SIGKILL`（**不算缺陷**）；`rc=134` = 真 abort。
   **本波全部读数里：`rc=137` 0 次、`rc=134` 0 次**；唯一出现的是 `rc=143` = **我自己的收工 `TERM`**
   （正极性趟末尾我主动杀进程）。所有"存活"判断都同时给了 `alive=` 与 `unhandled=`，
   不与 `rc` 混读。
4. **反极性未取数** ⇒ §3 判据② = `NOINFO`（原因 = 排程裁定，不是难度）。
5. **`tests/**` 会红三处（不在我的写域，必须由主控同步改）**——它们把这两条**钉在"必须 `E_NOTIMPL`"**上：
   | 文件:行 | 内容 | 需要的改法 |
   |---|---|---|
   | `tests/.../CommandCoverageTests.cs:106`、`:163`、`:203` | `Assert.Equal(7, notImpl…)` | `7 → 5` |
   | `tests/.../CommandCoverageTests.cs:186,195,196` | `未实现的7条是D3D与媒体` ＋ `Assert.Contains(0x6c/0x70)` | 删两条断言、改名 `未实现的5条`；并加"**0x6c/0x70 不许退回 `s_notImpl`**"的反向护栏 |
   | `tests/.../CommandRoundTripTests.cs:670-684` | `未实现命令返回ENOTIMPL并登记` **拿 0x6c 当"稳定的 `E_NOTIMPL`"** | 换成 `0x0a MilCmdD3DImage`（同样是 8 字节头、同样永久 `E_NOTIMPL`） |
   | `tests/.../GoldenBinaryReplayTests.cs:54-63` | `AllowedNotImpl` 是**允许集**（超集不红），但注释已过期 | 建议顺手删两行 |
   `grep` 佐证：`NotImplCount` 的另一个引用（`build/MilBridge/src/…/Diagnostics.cs:133`）是**导出名**计数，与本件无关。
6. **`docs/**` 口径待改（不在我的写域）**：`docs/unimplemented.md` `:16`（"缺失的 6 个 = §1 的 C 类"）、
   `:41`（`C · 永久不做 = 6`）、`:178`（`C 类 · 6 条`）、`:184-185`（两张表里的 0x6c/0x70 行）、
   `:194`（把 0x6c/0x70 与 0x0a/0x0b 并列）、`:199`（`顶层命令：7 / 118 返回 E_NOTIMPL`）、`:222-223`。⇒ 6→4、7→5。
7. **`Marshal.SizeOf` 护栏缺口**：这两条的长度现场只由"命令层台账 + 本件台账的 `declared==bytes`"两条
   仪器交叉确认（12/12），**没有** `CommandLayoutTests` 那层机械护栏（见 §1.2 的理由）。若主控要我补，
   请把 `tests/**` 打开给我，或指示我加结构体＋同步改那张对照表（两处必须同趟改，否则那条反射牙必红）。
8. **反极性的第二半（渲染事实）也没取**：本件只证"**不再 abort**"与"**效果未施加**"（§6.1/§6.2 的间接读数），
   **没有**逐像素证明"效果确实没有视觉贡献"（那要同一页开/关 `Effect=` 的两帧对拍）。`NOINFO`。
9. **仪器自伤（如实留档，都会被写进记录）**：
   ① 首趟正极性**窗口一出来就点** ⇒ 那时 UI 还在建视觉树（`mil` 资源 255 个、`app.log` 181 行）⇒ 取不到 TabItem
   ⇒ **假 `NOINFO`**。教训：就绪判据不能是"窗口存在"或"两帧相同"（静帧 ≠ 装好了），已改成三条件
   （日志 ≥600 行 ＋ 静帧 ≥100 色 ＋ `AE=0`，本趟实测 `READY steps=4 colors=373`）。
   ② 等窗口的循环原写 400 s，而槽的等待上限是 1500 s ⇒ 会把自己的**排队时间**读成"窗口没出来"；已改 1600 s。
   ③ 台账明细块原写成裸管道（只到 stdout，没进 `READING.txt`）⇒ 打印为空、但计数正确（12）。
   **条目读数无损**（`mil.log:6314-6325` 有原文），已改成 `say "$(…)"` 并**重跑正极性**。
   ④ 本报告原计划用"改共享树 → 构建 → 复原"做反极性；发现这会让**别的车道**在我排队期间构建到负极性桥，
   改为 **`cp -al` 硬链接副本 + 私有 `ArtifactsPath`**（脚本里还带一条断言：副本里的文件是硬链接，
   **必须先 `rm` 再写**，否则会截断共享 inode）。

## §7 复算命令逐条

```bash
R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux

# ① 三处改动的 before/after（before 在 $HOME/w62a/backup/*.before）
for f in MilCommandLayout.cs MilCommandDispatcher.cs MilChannel.cs; do sha256sum $HOME/w62a/backup/$f.before; done
sha256sum $R/src/WpfGfx.Linux/Commands/MilCommandLayout.cs \
          $R/src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs \
          $R/src/WpfGfx.Linux/Resources/MilChannel.cs | cut -c1-16
#   期望：d13821c359c30db9 / 62203635d795f832 / 4a79d7437fd428ba

# ② 新桥 + "不是拿旧件交差"
sha256sum $R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so | cut -c1-16   # 79e45aed26487045
strings -el $R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so | grep -c NOTIMPL-SHADER   # 2

# ③ 正极性（重跑）——**必须包在槽里**
bash $HOME/w62a/bin/legrun.sh W62A-zero :198 # 见 ④
W62A_DISP=:197 bash $HOME/w62a/bin/dg58.sh pos1 '0x6c,0x70'
#   看：item[2] alive=yes unhandled=0；片内 notimpl=[1-9]=0、★E_HANDLE#2=0；[NOTIMPL-SHADER]=12；colors≈4843
#   台账原文：grep -an 'NOTIMPL-SHADER' $HOME/w62a/out/pos1/mil.log   # 6314-6325，12 行，declared==bytes
#   批上下文：sed -n '6301,6313p' $HOME/w62a/out/pos1/mil.log           # 243 条批 + #55..#98 的 12 条

# ④ 零回归腿（**延期未跑**，命令即复算路径；legrun 已把 leg.sh 包进槽并收孤儿）
bash $HOME/w62a/bin/legrun.sh W62A-zero :198
#   判据：leg.sh 的 `STEP T1-nav1 alive=yes AE>0` 与 `STEP T2-click-TabItem3 alive=yes AE>0`

# ⑤ 反极性（**延期到 #50**；negbuild.sh = 硬链接副本里造"对照 + 负极性"两件，共享树零暴露）
bash $HOME/w62a/bin/negbuild.sh                       # 产出 art-ctrl / art-neg 两个 .so
cp $HOME/w62a/art-neg/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so $HOME/w62a/appneg/
W62A_APP=$HOME/w62a/appneg W62A_DISP=:199 bash $HOME/w62a/bin/dg58.sh neg1 '0x6c,0x70'
#   期望（判据②）：点 item[2] ⇒ alive=no、unhandled=1，逐字签名含
#   `Unhandled exception. System.NotImplementedException` 与 `MediaContext.CommitChannel`；
#   对照趟（同一个副本、同一 ArtifactsPath，只有那两个 case 块不同）应仍 alive=yes

# ⑥ 应用器审计（本波零回归）
bash $R/build/check-appliers.sh | tail -1        # APPLIER_AUDIT_SUMMARY appliers=26 ok=89 miss=0 red=0 rc=0

# ⑦ 收工残留自查（本车道）
ps -eo pid,cmd | grep -E 'w62a|Xvfb :19[789]' | grep -v grep    # 期望：空
for p in /proc/[0-9]*; do d=$(readlink $p/cwd 2>/dev/null); case "$d" in "$HOME"/w62a/app*) echo "${p#/proc/} $d";; esac; done   # 期望：空
```

**报告件**：`build/MilBridge/W62A-report.md`（sha16 见下）；**仪器**：`$HOME/w62a/bin/dg58.sh`（`99fa3ea647653c81`）、
`$HOME/w62a/bin/legrun.sh`、`$HOME/w62a/bin/negbuild.sh`、`$HOME/w62a/bin/geoq.py`（`732cd6b76e111477`）；
**读数**：`$HOME/w62a/out/pos1/{READING.txt,app.log,mil.log,f0.png,f1.png,f2-0.png,f2-1.png,f2-2.png}`。

---

**本报告 sha16（正文）**：`7ff167db706be58a` —— 口径 = 上文**全部内容**的 sha256 前 16 位；
本行是补在正文之后加的，因此**不含本行自身**（24643 B / 309 行，2026-09-21 00:18:11 +0800）。
`sha256sum build/MilBridge/W62A-report.md | cut -c1-16`

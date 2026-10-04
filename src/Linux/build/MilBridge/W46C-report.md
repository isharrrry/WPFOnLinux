# W46C 报告 —— `D-G54`：弹窗那条 `MilCmdTargetSetRoot` 到底在哪一跳出的问题

- 车道：**W46C**｜仓库根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
- 日期时间：2026-09-19 20:06 – 20:24（本机时钟）｜kernel `6.8.0-138-generic`｜`nproc=3`｜`loadavg` 0.88–2.74、`MemAvailable` 1.6–2.9 GB（逐趟见 §6）
- 结论摘要（一句话）：**那条 `SetRoot` 既没丢、也没被拒、也没"没进缓冲"——它进了缓冲、并且被派发了**；
  是**父 agent 的 preflight 台账本身看不见它**（preflight 只在 `MilConnection_CommitChannel` 这一条提交路径上打印，
  而派发它的那条提交走的是 `WgxConnection_SameThreadPresent`，**不打印 preflight**）。
  真正的问题在**呈现侧**：弹窗的 HWND `0x200008` **从头到尾没有被呈现过一次**，而一帧 **413×274（弹窗尺寸）**的画面被画到了**主窗口**的 HWND 上。

---

## 0. 本轮唯一的写入面（先声明，便于复核）

| 件 | before sha16 | after sha16 | 说明 |
|---|---|---|---|
| `R/src/WpfGfx.Linux/Resources/MilChannel.cs` | `e5f14495971a23c2`（**现场实测**，动手前记下） | `dcc34a49e0f7176d` | 只加**只读**台账：`MilResource_SendCommand`/`SendCommand` 两处路径 + id 过滤 |
| `R/src/WpfGfx.Linux/Interop/MilNative.cs` | `2771a7f42143f49d`（**复原件**，见下"纪律缺口"） | `ee4a0e8dd82b0cab` | 只加 `MilResource_SendCommand` 入口一行 + `Resolve==null` 的 E_HANDLE 一行 |
| `R/build/MilBridge/.artifacts/.../wpfgfx_cor3.so` | `496951adff86a557`（4 991 984 B） | **`6fac9e722299a768`（5 000 192 B，mtime 2026-09-19 20:09:36）** | 两次 AOT 发布：`58a7abfeda93e662`（20:08:18，**只有父 agent 那批台账、没有我的 SendCommand 插桩**，4 996 080 B） → 本次 |
| `<hc app dir>/wpfgfx_cor3.so` | `496951adff86a557`（备份于 `$HOME/w46c-backup/wpfgfx_cor3.so.installed-before46`） | `6fac9e722299a768` | 与发布件同 sha（见下"发现：publish 会自动刷新 app-local"） |

- **未改**：`src/WpfGfx.Linux/Windowing/**`、`Interop/MilPresentation.cs`、`known-red.json`、`arm-logs/**`、`verify-all.sh`、`close-wave.sh`、任何 `*.tsv`；**未跑** `integration-wave.sh`/`verify-all.sh`/冻结。
- app 目录另三件未动（现场核对）：`libwpfwin32.so e700c383ec1ecdc8`、`libwpfwic.so 56278c14b4ecd672`、`libSkiaSharp.so a02cd03f1ebcbb97`。
- ⚠️ **纪律缺口（自查并如实登记）**：`MilNative.cs` 我是**先改后备份**的，pre-sha 不是现场件，而是把当前件做**逆替换**复原后算出的（复原件 `$HOME/w46c-backup/MilNative.cs.pre46c-reconstructed`，与当前件 `diff` **只**差我加的那 6 行）。这个 sha 是**复原值**，不是原始件指纹。

---

## 1. 三组计数的精确读数（父 agent 点名要的那三个）

**跑（run 6，唯一一趟"弹窗真的开了"的取证跑）**：`$HOME/w46c-6`、桥文件汇 `$HOME/w46c-mil6.log`

```
CLICKX=420 CLICKY=706 WPF_LINUX_CMDLOG=1 WPF_LINUX_CMDLOG_ID=0x35 WPF_LINUX_HT_TRACE=1 \
WPF_LINUX_MIL_TRACE=1 WPF_LINUX_MIL_LOG=$HOME/w46c-mil6.log \
HC_FO_OUT=$HOME/w46c-6 HC_FO_DISPLAY=:46 HC_DROP_OPEN_AT=25 bash $HOME/w46c-run4.sh      # rc=0
```

### ① 桥 preflight 收到的 `SetRoot` 条数 = **1**

```
$ grep -c 'id=0x35' $HOME/w46c-mil6.log
1
$ grep -n 'id=0x35' $HOME/w46c-mil6.log
32:[preflight] 通道 2 待提交 #4: id=0x35 (MilCmdTargetSetRoot) len=12 handle=0x00000003 在资源表里=True
```

### ② 进缓冲的条数 = **2**（**不是** `EndCommand`；该 id 的结构上不经过 Begin/End）

```
$ grep -c 'EndCommand' $HOME/w46c-6/app.log
0
$ grep -n 'SendCommand .*id=0x35' $HOME/w46c-6/app.log      # 等价于"进缓冲"
33:[CMD] [native] MilResource_SendCommand pChannel=0x10000002 id=0x35 cbSize=12 独立批=False
34:[CMD] ch=2 SendCommand 入口 id=0x35 handle=0x00000003 len=12 独立批=False openStart=-1 批次内已有=4
35:[CMD] ch=2 SendCommand **已入批**（等 Commit）id=0x35 handle=0x00000003 批次内共=5 字节=200
616:[CMD] [native] MilResource_SendCommand pChannel=0x10000002 id=0x35 cbSize=12 独立批=False
617:[CMD] ch=2 SendCommand 入口 id=0x35 handle=0x00000894 len=12 独立批=False openStart=-1 批次内已有=4
618:[CMD] ch=2 SendCommand **已入批**（等 Commit）id=0x35 handle=0x00000894 批次内共=5 字节=200
```

⚠️ **父 agent 步骤 4 里 `grep -n 'EndCommand id=0x35' <app.log>` 这条指令的模型不成立**：`MilCmdTargetSetRoot` 走的是
`exports.cs:2360-2374 DUCE.CompositionTarget.SetRoot → channel.SendCommand((byte*)&command, sizeof(...))`
（**两参**重载 ⇒ `exports.cs:622-626 → SendCommand(p,cSize,false)`）⇒ 进桥的是 `MilNative.MilResource_SendCommand`
（`MilNative.cs:367`）⇒ `MilChannel.SendCommand`（`MilChannel.cs:190`），**从不经过 `BeginCommand/AppendCommandData/EndCommand`**。
所以那条 grep 永远是 0，它不能当"进缓冲"的判据。

### ③ 被派发的条数 = **2**（含弹窗那条 handle `0x894`）

```
$ grep -n '派发 id=0x35' $HOME/w46c-6/app.log
51:[CMD] ch=2 派发 id=0x35 handle=0x00000003 len=12
621:[CMD] ch=2 派发 id=0x35 handle=0x00000894 len=12
```

### ④ 有没有"被拒" = **没有**

```
$ grep -c '被拒' $HOME/w46c-6/app.log
0
```

### ⑤ 两次 `[HT] … SetRoot 之后：已发出` 与上面三组计数的对应

```
$ grep -n 'SetRoot 之后\|派发 id=0x35\|RootVisual setter\|CreateUCEResources 进入\|复制句柄后' $HOME/w46c-6/app.log
16:[HT] CreateUCEResources 进入：channel=1a2b5e9 oob=2b86539                  ← 主窗口
26:[HT] 复制句柄后：target(主通道)=635bdea0 IsOnChannel(main)=True
32:[HT] SetRoot 之前：target=635bdea0 contentRoot=afb96b84
36:[HT] SetRoot 之后：已发出                     ← 第 1 次
51:[CMD] ch=2 派发 id=0x35 handle=0x00000003 len=12        ← 对应：handle 0x3 = 主窗口 target
55:[HT] RootVisual setter 被调：value=MainWindow
612:[HT] CreateUCEResources 进入：channel=1a2b5e9 oob=2b86539                 ← 弹窗（**同一个 managed Channel 对象**，哈希同为 1a2b5e9）
614:[HT] 复制句柄后：target(主通道)=525c874a IsOnChannel(main)=True
615:[HT] SetRoot 之前：target=525c874a contentRoot=c829ede8
619:[HT] SetRoot 之后：已发出                     ← 第 2 次
621:[CMD] ch=2 派发 id=0x35 handle=0x00000894 len=12        ← 对应：handle 0x894 = 弹窗 target（= ch3 句柄 0x4 复制到主通道）
620:[HT] RootVisual setter 被调：value=PopupRoot
```

弹窗打开的三条独立旁证（同一趟）：

```
610:[HCIN] EV DropDownOpened open=True cap=ComboBox
627:[HCIN] FORCE-OPEN tick=25 open=True overlayChk=True
703:[HCIN] POPUP isOpen=True child=Decorator vis=True wh=380x263 src=HwndSource rootVis=PopupRoot bounds=0,0,380.16,255.36
```

末个 census（`$HOME/w46c-mil6.log:8312`）——**没有任何东西卡在缓冲里**：

```
通道#2: committed=3620 notimpl=0 failed=0 short=0 pending=0 batchBytes=0 资源=2295 root=有 窗口目标=0x200008
        [MilEtwEventResource×1] [MilVisualResource×1017] … [MilHwndTarget×2]
```

---

## 2. 结论：命令在哪一跳"消失"？—— **哪一跳都没消失；是台账瞎了一只眼**

**三问逐条回答**（父 agent 的原话：没进缓冲 / 进了没派发 / 派发但失败）：

| 假设 | 裁定 | 判据 |
|---|---|---|
| ① 没进命令缓冲 | **否** | `[CMD] ch=2 SendCommand **已入批** … handle=0x00000894`（app.log:618），且下一行 `批次内共=5 字节=200` |
| ② 进了没被派发 | **否** | `[CMD] ch=2 派发 id=0x35 handle=0x00000894 len=12`（app.log:**621**）——且它紧随 `[HT] SetRoot 之后`（619）之后 2 行，是 `CreateUCEResources` 末尾那次提交同步派发的 |
| ③ 被派发但处理失败 | **否** | 末个 census `failed=0 notimpl=0`；`short=0`。而 `Dispatch` 的 `MilCmdTargetSetRoot` 分支（`MilCommandDispatcher.cs:342-352`）在句柄不在资源表里时会返回 `E_INVALIDARG` ⇒ 会被计进 `failed`；它是 0 |

**那么"preflight 只 1 条"是怎么来的？** —— 因为 `PreflightPendingCommands` 只在**一条**提交路径上被调用：

- `MilNative.cs:204-209`：`if (MilPresentation.DiagnosticSinkEnabled) PreflightPendingCommands(channel);` —— 在 `MilConnection_CommitChannel` **里**。
- 而 `channel.Commit()` 还有两条**不走 preflight** 的路径，都在同一个文件里：
  - `MilNative.cs:256-268 WgxConnection_SameThreadPresent` → `channel.Commit()`（`:261`），**无 preflight**；
  - `MilNative.cs:138-151 FlushPendingCommandsBeforeInvalidation` → `channel.Commit()`（`:143`），**无 preflight**（只打一行 `[flush-before-release]`）。

本趟派发弹窗 `SetRoot` 的那次提交就是**前者/同类路径**（见证：同一份文件汇里，通道 2 的**其它**提交都留下了 preflight，
甚至留下了 `handle=0x00000894` 的 preflight —— 见下），**唯独携带 `SetRoot` 的那次没有**：

```
$ grep -n '0x00000894' $HOME/w46c-mil6.log
7546:[dup] 0x00000004 从通道 3 → 通道 2，新句柄 0x00000894（目标表内总数 2196）
7723:[preflight] 通道 2 待提交 #0: id=0x33 (MilCmdTargetUpdateWindowSettings) len=72 handle=0x00000894 在资源表里=True
8173:[preflight] 通道 2 待提交 #0: id=0x33 (MilCmdTargetUpdateWindowSettings) len=72 handle=0x00000894 在资源表里=True
8183:[preflight] 通道 2 待提交 #0: id=0x33 (MilCmdTargetUpdateWindowSettings) len=72 handle=0x00000894 在资源表里=True
```

即：**同一个 target 句柄 `0x894` 的其它命令都被 preflight 记到了，而它的 `SetRoot` 没有** —— 差别只能是"携带它的那次提交不打印 preflight"。
⇒ **`grep -c 'id=0x35'` 不能用来证明"第二条没进缓冲"；它是**仪器覆盖面**的读数，不是桥的事实。**

### 2.1 反向印证：父 agent 自己那两份文件汇里同时存在"pending=8"与"已派发"两种形态

（这两份是父 agent 跑的，不是我的趟；我用它们做交叉验证。）

- `$HOME/hc-ht3-mil.log`（842 KB / 7 589 行，mtime 20:05:55）末尾：
  ```
  7574:[create] 通道 2(0x10000002) 句柄 0x00000895 类型 TYPE_MATRIXTRANSFORM ⇒ 表内总数 2197
  7575:通道计数快照：
  7577:  通道#2: committed=3369 … pending=8 batchBytes=368 资源=2197 … [MilHwndTarget×2]
  7580:[flush-before-release] 通道 2 冲刷待处理命令 ⇒ hr=0x00000000
  7581:[release] …（9 条）
  ```
  ⇒ 这一趟（App 在弹窗创建后**立刻**被杀）里，弹窗那批 **8 条 / 368 B 停在缓冲**，直到收尾 flush 才以 `hr=S_OK` 派发掉。
  **"进了缓冲"在这里是硬读数**；只是它**死得太早**，没等到普通提交。
- `$HOME/hc-fo3-mil.log`（904 KB / 8 195 行，mtime 19:57:35 = 那次"弹窗开成功"的跑）末尾：
  通道#2 `committed=3621 pending=0 failed=0 notimpl=0 资源=2295 [MilHwndTarget×2]`，通道#3 `committed=11 资源=4`；
  而 `id=0x35` **同样只有 1 条**（第 32 行）。
  ⇒ **健康跑里，弹窗那批被完整派发了（`committed` 3369→3621、资源 2194→2295、`pending=0`），preflight 依旧只看见主窗口那条。**
  这是"preflight 盲区"的第二个独立见证。

### 2.2 顺带把"零渲染"的**真正**机制钉住（呈现侧，不是命令侧）

同一份 `$HOME/hc-fo3-mil.log` 里，弹窗 HWND `0x200008` **从来没有当过呈现目标**：

```
$ grep -c '已呈现.*0x200008' $HOME/hc-fo3-mil.log
0
$ grep -n '已呈现' $HOME/hc-fo3-mil.log | tail -3
37:  ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200004 已呈现 800x600（skia 指令 0 条，未画种类 0）  累计帧数 = 1
7886:  ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200004 已呈现 413x274（skia 指令 439 条，未画种类 0）  累计帧数 = 17
8142:  ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200004 已呈现 800x600（skia 指令 443 条，未画种类 0）  累计帧数 = 18
```

- **413×274 = 弹窗尺寸**（同一份日志里 `NOTE X11 Resize：HWND 0x200008 → 413x274`），439 条 skia 指令 ⇒ **弹窗的内容确实被渲染出来了**，
  但被呈现到 **HWND `0x200004`（主窗口）** 上；`0x200008` 一次都没被呈现。
- 代码侧对应两处，都在 `MilPresentation.cs`：
  - `TryResolveTarget`（`:745-772`）**取资源表里第一个 `NativeWindow != 0` 的 target 就返回**（`target = t; return true;`），
    一个通道上挂**两个** HwndTarget（主窗口 `0x200004` + 弹窗 `0x200008`）时它**只可能选中一个**；
  - `IMilChannel.Root` 是**通道级单槽**，`SetRootFromHandle`（`MilChannel.cs:373`，由 dispatcher 的 `SetRoot` 分支调用）
    会把主窗口的根**覆盖**成弹窗的 `PopupRoot` ⇒ `PresentChannel` 用 `channel.Root` 现投影（`:873-898`）时画的就是弹窗的树。
  ⇒ **"弹窗内容零渲染" = 弹窗的内容被画进了主窗口那条 HWND，弹窗自己的 HWND 从来没进过呈现名单。**
  （census 里的 `窗口目标=0x200008` 是另一段代码：它**扫全表、取最后一个**，与 `TryResolveTarget` 的"取第一个"**不是同一个选择**，
  所以 census 显示的 `窗口目标` 不能用来判断"这一帧呈现给谁"。）

---

## 3. 加的日志（逐处行号 + sha16）

`R/src/WpfGfx.Linux/Resources/MilChannel.cs`（`e5f14495971a23c2` → `dcc34a49e0f7176d`）：

| 行 | 内容 |
|---|---|
| 116 / 123 / 132 / 145 | `CmdLogInit()` / `internal static CmdLog(msg)` / `internal static CmdLogWanted(id)` / `CmdLogId(id,msg)` —— **env 门控**：`WPF_LINUX_CMDLOG=1` 开；`WPF_LINUX_CMDLOG_ID=0x35` 只记指定 id（**预算 400 → 5 000**） |
| 151 / 163 / 199 / 229 / 236 | `BeginCommand/AppendCommandData/SendCommand/CloseBatch/Commit` 各 **E_UNEXPECTED 被拒**一行（**不受 id 过滤**，恒打） |
| 179 | `EndCommand id=… handle=… len=… extra=… appended=…`（父 agent 加的，我改为走 id 过滤） |
| **197** | **`SendCommand 入口 id=… handle=… len=… 独立批=… openStart=… 批次内已有=…`** ← 本轮新增（`SetRoot` 的唯一入口） |
| **212 / 215 / 222** | **`SendCommand **立即派发**（独立批）` / `立即派发结果 hr=…` / `**已入批**（等 Commit）… 字节=…`** ← 本轮新增 |
| 243 | `派发 id=… handle=… len=…`（父 agent 加的，我改为走 id 过滤） |

`R/src/WpfGfx.Linux/Interop/MilNative.cs`（复原 pre-sha `2771a7f42143f49d` → `ee4a0e8dd82b0cab`）：

| 行 | 内容 |
|---|---|
| **371-377** | **`[native] MilResource_SendCommand pChannel=… id=… cbSize=… 独立批=…`**（`WPF_LINUX_CMDLOG` 门控 + id 过滤） |
| **379-383** | **`[native] ★E_HANDLE MilResource_SendCommand Resolve(0x…) == null ⇒ 命令**被丢弃**（registry.Count=…）`**（不受 id 过滤） |

### 3.1 为什么必须加"id 过滤"（这是仪器自伤，不是装饰）

`SendCommand` 是**每条命令**的入口，启动期几千条 ⇒ 父 agent 给的固定 400 行预算会在**弹窗打开（t=25 s）之前**就烧光
（本仓已经踩过"仪器把自己的读数吃掉"；同一趟里 `WPF_LINUX_MIL_TRACE` 的 stderr 台账就正是这么被吃掉的，见下）。
实测：给了 `WPF_LINUX_CMDLOG_ID=0x35` 之后，整趟只有 **4 → 8 行** `[CMD]`，弹窗那 4 行完完整整在里面。

⚠️ **同时必须点名父 agent 取证里的同一类自伤**（这是本轮最有价值的更正）：
父 agent 两次跑的 stderr `[mil]` 台账都在**弹窗打开之前**就预算用尽了 ——

```
$ grep -n '诊断预算用尽\|EV DropDownOpened\|\[HT\] SetRoot' $HOME/hc-nosplash-1/app.log
455:[mil] …诊断预算用尽（已打 400 条），后续不再输出。…
584:[HCIN] EV DropDownOpened open=True cap=ComboBox
591:[HCIN] FORCE-OPEN tick=25 open=True overlayChk=True
$ grep -n '诊断预算用尽\|EV DropDownOpened' $HOME/hc-ht3/app.log
477:[mil] …诊断预算用尽（已打 400 条），后续不再输出。…
606:[HCIN] EV DropDownOpened open=True cap=ComboBox
```

—— 所以**任何**基于那两份 `app.log` 里 `[mil]` 行数的结论（"preflight 里 `id=0x35` 只有 1 条"）都不成立；
只有**文件汇**（`WPF_LINUX_MIL_LOG`，无预算）里的计数才有效，而文件汇的计数（`hc-ht3-mil.log` / `hc-fo3-mil.log` / 我的 `w46c-mil6.log`）
**也**是 1 —— 但原因不是"第二条没进缓冲"，而是 §2 的 preflight 覆盖面。

---

## 4. 桥产物

| 件 | sha16 | 大小 | mtime |
|---|---|---|---|
| 发布件 `R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so` | **`6fac9e722299a768`** | 5 000 192 B | 2026-09-19 20:09:36 |
| 已装到 hc app 目录的那份 | `6fac9e722299a768` | 5 000 192 B | 2026-09-19 20:09:36 |
| 旧的那份（备份） | `496951adff86a557` | 4 991 984 B | `$HOME/w46c-backup/wpfgfx_cor3.so.installed-before46` |

`run.sh build` 两趟都 **rc=0**、`缺失 0`（109 清单 / 111 实到 / 额外 16 诊断面）。
⚠️ **发现（供主控记账）**：我第一次 `ls` hc app 目录时发现里面那份已经是 **`58a7abfeda93e662`（我第一趟发布的产物，mtime 20:08:18）**
—— 也就是说 **`dotnet publish` 会把产物自动刷新到 app-local 消费目录**（`run.sh` 的 `refresh_applocal`/selfbuilt-config 那条线），
不是我 `cp` 的。含义：**任何一条车道跑一次桥的 publish，都可能在你测量期间把 app 目录里的 `.so` 换掉** ⇒ 每趟跑之前必须现场 `sha256sum` 一次。

---

## 5. 跑趟清单（结论可复算）

| # | 车 | 目标点 | 弹窗 | `[CMD]` | 备注 |
|---|---|---|---|---|---|
| 1 | 主控原车 `hc-forceopen.sh` | (420,706) | **没开**（dispatcher 冻在 t21、t25 的 FORCE-OPEN 从未触发） | 4 | 与父 agent 声称的"preflight=1"同源现象 |
| 2 | `w46c-run2.sh`（+`HC_NO_SPLASH=1`） | (420,706) | **没开**（同样冻在 t21） | **0** ⚠️未解释（见 §7） | 桥文件汇仍全 |
| 3 | `w46c-run3.sh`（不点导航，`HC_DROP_OPEN_AT=8`） | — | 没开（`FORCE-OPEN 没找到 ComboBox`：启动页是概览页，没组合框） | 4 | 用 `/proc/<pid>/environ` 证明 env 确实在进程里 |
| 4 | `w46c-run4.sh` | (389,631) | 没开（落到 **文本块**页，页里没有组合框） | 4 | 又抓到自己一处仪器错：**坐标是从缩放预览图量的**（父 agent 早就踩过这个坑） |
| 5 | `w46c-run4.sh` | (389,680) | 没开（落到 **文本框**页） | 4 | 由 4/5 反解出导航项间距 ⇒ 组合框在 y≈706 |
| **6** | **`w46c-run4.sh`** | **(420,706)** | **开了** ✅ `EV DropDownOpened` + `FORCE-OPEN tick=25 open=True overlayChk=True` + `POPUP isOpen=True … rootVis=PopupRoot` | **8** | **本报告的判据全来自这一趟** |

复现命令（run 6，逐字）：

```
export PATH="$HOME/.dotnet:$PATH"
CLICKX=420 CLICKY=706 WPF_LINUX_CMDLOG=1 WPF_LINUX_CMDLOG_ID=0x35 WPF_LINUX_HT_TRACE=1 \
WPF_LINUX_MIL_TRACE=1 WPF_LINUX_MIL_LOG=$HOME/w46c-mil6.log \
HC_FO_OUT=$HOME/w46c-6 HC_FO_DISPLAY=:46 HC_DROP_OPEN_AT=25 bash $HOME/w46c-run4.sh
```

---

## 6. 读数表（每趟）

| 趟 | 起/止 | 桥 `.so` sha16（跑前=跑后） | loadavg（跑前/跑后） | MemAvailable（跑前/跑后） | lane | kernel |
|---|---|---|---|---|---|---|
| 1 | 20:10:09→20:10:44 | `6fac9e722299a768` | 2.74 / 2.72 | 2 805 / 1 615 MB | W46C | 见下 |
| 2 | 20:12:16→20:13:02 | `6fac9e722299a768` | 1.75 / 1.60 | 2 948 / 2 446 MB | W46C | " |
| 3 | 20:14:22→20:14:56 | `6fac9e722299a768` | 1.62 / 1.28 | 2 882 / 2 469 MB | W46C | " |
| 4 | 20:15:32→20:16:11 | `6fac9e722299a768` | 1.34 / — | 2 537 / — MB | W46C | " |
| 5 | 20:17:35→20:18:15 | `6fac9e722299a768` | 1.54 / — | 2 546 / — MB | W46C | " |
| 6 | 20:19:56→20:20:34 | `6fac9e722299a768` | 0.88 / — | 2 904 / — MB | W46C | " |

`uname -r` = **6.8.0-138-generic**（现场读；`nproc=3`）。所有 `dotnet` 调用均 `-m:1` + `DOTNET_gcServer=0`，构建串行（构建前按硬规则 `pgrep` 查锁，未遇到需要在飞的构建）。

---

## 7. `NOINFO` 清单（取不到 / 没查清，逐条）

1. **run 2 的 `[CMD]` 行为什么是 0**：同一脚本、同一 env（run 3 用 `/proc/<pid>/environ` 逐字验证 env 在进程里）、同一 `.so`（跑前跑后 sha 不变）——**没查清**。
   最可能是"测量期间 app 目录的 `.so` 被别的车道的 publish 换掉"（§4 已实测到 publish 会刷新 app-local），但我**没有直接证据**，故列为未解释。
   影响：run 2 不作为任何结论的依据。
2. **弹窗那条 `SetRoot` 在桥里"执行成功"这一步没有**独立的成功日志：`MilCommandDispatcher.cs:342-352` 的 `SetRoot` 分支**不打任何台账**。
   我的结论（③"没失败"）是**由 `failed=0`/`notimpl=0` 反推**的（该分支若句柄无效会返回 `E_INVALIDARG` 并计入 `failed`），**不是我直接看到的一行"SetRoot 成功"**。
   要变成直接读数，需要在 dispatcher 的 `SetRoot` 分支加一行（**本轮没加**，因为那要动 `MilCmdTargetSetRoot` 的执行路径所在文件，超出"只加命令层台账、不改语义"的边界）。
3. **哪个 `MilTarget` 对象被 `PresentChannel` 选中**（§2.2 的 `TryResolveTarget` 顺序）没有直接日志：`0x200004` 出现在呈现行里是**读数**，
   而"为什么是它而不是 `0x200008`"是**读 `MilPresentation.cs:745-772` 代码得到的解释**，不是量出来的。要坐实需要在 `TryResolveTarget` 里打一行它选中的 target 句柄 + `NativeWindow`（同样**本轮没加**）。
4. **"弹窗打开后主窗口内容冻结"这件事我没有单独量化**：我只观测到 `committed` 长时间不动 + 1 Hz 取证 dump 停摆（run 1/2/4/5 里出现在导航点击之后），
   它与 W46A 正在查的 "hang" 是否同源，**我没查**（不在本件目标内）。
5. `EndCommand id=0x35` 的计数**结构上是 0**（§1②），父 agent 若还想要"进缓冲条数"的口径，请改用 §1② 的两条 grep。
6. 我**没有**动任何产品语义（除 §3 的只读日志），也**没有**落"该怎么修"的改动；修法建议只写在 §2.2 与 §8。

---

## 8. 给主控的下一步建议（不落地，只写）

1. **别再从 preflight 计数下结论**。要判"命令有没有到桥/有没有被派发"，用 `WPF_LINUX_CMDLOG=1 WPF_LINUX_CMDLOG_ID=0x…` 这条命令层台账
   （入口/入批/派发三点都在），它覆盖**所有**提交路径；preflight 只覆盖 `MilConnection_CommitChannel`。
   若坚持用 preflight，最小修法是把 `PreflightPendingCommands` 的调用点从 `MilConnection_CommitChannel` 下沉到 `MilChannel.Commit()` 里
   （`MilChannel.cs:234-251`，一句 `if (MilPresentation.DiagnosticSinkEnabled)` —— 但那是**桥**的改动，要按波次走）。
2. **真正的修点在呈现侧**（这一条比"命令在哪一跳丢"值钱）：`TryResolveTarget` 的"取第一个 HwndTarget" + 通道级**单** `Root` 槽，
   结构上表达不了"一个通道上两个 HwndSource"。要修就得把"根 + 呈现目标"从**通道级**下沉到**target/HWND 级**：
   `PresentChannel` 遍历该通道**所有** `MilTarget`、各自用自己的 `Root` 呈现；`IMilChannel.Root` 那个单槽只能当**兼容快照**用。
   这会**动桥**（`MilPresentation.cs` / `MilChannel.cs`），且会与 `ALLOWTRANSPARENCY`/`WS_EX_LAYERED` 那条腿（父 agent 已登记的修法 A）**交互**——
   建议把两件放同一波做，判据写死两条：`已呈现 … HWND 0x200008` 至少 1 次、弹窗区域色数 > 1。
3. **父 agent 的 D-G54 表述建议改写**：不要写"弹窗那条 `SetRoot` 没进缓冲/没派发"（已被本报告证伪），
   改写成"弹窗内容**建树成功、渲染成功、但被呈现到主窗口 HWND；弹窗 HWND 从未被呈现**"，判据就是 §2.2 的三行 grep。

---

## 9. 报告自身指纹

- 文件：`/home/links-dev/netTest/wpf-linux-20260906/wpf-linux/build/MilBridge/W46C-report.md`
- 口径：指纹 = `head -n -2 <本文件> | sha256sum | cut -c1-16`（丢掉**末两行**后整份哈希；末两行就是下面那条指纹行与它前面的空行）
- 可当场复算，命令见上

- **sha16 = `2b6487b8dcaf5a07`**

# W46A 报告 —— 缺陷 A：X11 事件泵按 XID 归属 `ConfigureNotify`

- 车道：`W46A`（桥侧 `src/WpfGfx.Linux/**`，AOT 进 `wpfgfx_cor3.so`）
- 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
- 时间窗：2026-09-19 20:06 → 20:30
- 结论一句话：**判定点在 `X11Window.TranslateCore` 里那句"无条件把 server 报的尺寸写进本窗口缓存"**；改成"按事件自己的 `WindowId` 归属"之后，弹窗（`0x200008`）的 `ConfigureNotify` 记到了**弹窗**头上，主窗口**再也不会**被按弹窗尺寸重渲。

---

## ① 判定点（文件:行 ＋ 原文）

### ①-1 真正的病灶：尺寸缓存被"抽到事件的那扇窗"写脏

改前 `src/WpfGfx.Linux/Windowing/X11Window.cs:373-376`（逐字，取自 `$HOME/w46a-backup/X11Window.cs.before`）：

```csharp
                case X11EventType.ConfigureNotify:
                    // 以 server 报的尺寸为准，而不是我们请求的尺寸。
                    _width = native.ConfigureWidth;
                    _height = native.ConfigureHeight;
```

**为什么这一句就是判定点**：`X11Window._width/_height` 是 `X11PresentationTarget.Width/Height`
（`Windowing/X11PresentationTarget.cs:71-73` → `X11Window.cs:204-206`）的唯一来源，而呈现层
按它决定"这帧渲多大"。但 `TranslateCore` 是**没有归属校验**的：它把尺寸写进**调用 `TryNextEvent`
的那个 `X11Window` 实例**，而 X11 的事件队列是**连接级**的（`XNextEvent` 会把整条连接上任何窗口的
事件取出来 —— 这条性质在 `Windowing/WindowEvent.cs:76-82` 有登记）。

### ①-2 事件是"在错误的窗口上抽到的"：泵的连接级抽事件

改前 `src/WpfGfx.Linux/Interop/MilPresentation.cs:616-624`（逐字，同上备份）：

```csharp
                    while (guard++ < 64 && target.Window.TryNextEvent(out WindowEvent ev))
                    {
                        // 【必须按 WindowId 过滤】X11 的事件队列是**连接级**的：
                        //   `XNextEvent` 会把整条连接上**任何窗口**的事件取出来。所以
                        //   "在 A 窗口上抽事件"完全可能抽到 B 窗口的事件 —— 实测踩过：
                        //   上一个测试销毁窗口留下的 DestroyNotify 被当成**当前**窗口的 Closed，
                        //   于是把当前目标误判成"窗口没了"并解绑（紧接着就是对已释放对象的访问）。
                        if (ev.WindowId != 0 && ev.WindowId != (ulong)hwnd.ToInt64())
                            continue;
```

**顺序是关键**：`TryNextEvent` → `Translate`/`TranslateCore`（**先写缓存尺寸**）→ 才轮到
`:623-624` 的 `WindowId` 过滤把这条**事件**丢掉 ⇒ **事件丢掉了，副作用留下来了**。
本场景里 `_targets` 同时含 0x200004 与 0x200008（`AttachToHwnd` 两扇窗都绑过：
`$HOME/w46a/iso-post/mil.log:7538`），所以"替邻居收信"是常态。

### ①-3 后果的消费点：主窗口按弹窗尺寸出帧

改前 `MilPresentation.cs:906` / `:912-918` / `:923-924`（逐字）：

```csharp
906:            int xw = presentation.Width, xh = presentation.Height;
...
912:                if (haveLast && (last.lw != xw || last.lh != xh))
913:                {
914:                    MilDiagnostics.Note(
915:                        $"X11 Resize 生效：HWND 0x{(long)hwnd:x} {last.lw}x{last.lh} → {xw}x{xh}（按新尺寸重渲）");
916:                    width = xw; height = xh;
917:                }
918:                lock (_gate) _lastXSize[hwnd] = (xw, xh);
...
923:            if (presentation.Width != width || presentation.Height != height)
924:                presentation.Resize(width, height);
```

因果链（每一跳都有读数支撑）：

```
弹窗 0x200008 建窗/映射（413x274）
  → X server 给本连接发 ConfigureNotify(window=0x200008, 413x274)
  → 泵在**主窗口 0x200004** 的 pass 里把它抽走（MilPresentation.cs:616）
  → TranslateCore 把 413x274 写进 **0x200004** 的 _width/_height（X11Window.cs:375-376）★病灶
  → 事件本体随后被 WindowId 过滤丢掉（MilPresentation.cs:623-624）⇒ 弹窗自己的缓存仍是 1x1
  → 下一次 PresentChannel(主窗口)：xw/xh=413x274 ≠ _lastXSize=(800,600)
  → NOTE "X11 Resize 生效：HWND 0x200004 800x600 → 413x274"
  → width/height=413x274 → 主窗口那一帧**按弹窗尺寸**渲（且余下区域保持旧帧 → "被裁短"）
```

---

## ② 我的改动（逐处行号 ＋ before/after sha16）

### ②-1 改前备份（`cp -p`，跑前算、跑后复算）

| 文件 | 备份 | before sha16 |
|---|---|---|
| `src/WpfGfx.Linux/Windowing/X11Window.cs` | `$HOME/w46a-backup/X11Window.cs.before` | `5c64b1e9a74ae7e0` |
| `src/WpfGfx.Linux/Interop/MilPresentation.cs` | `$HOME/w46a-backup/MilPresentation.cs.before` | `be4252f2526399cf` |

### ②-2 改动一：`X11Window.cs` —— 尺寸缓存的**唯一写点**改成"核实 XID 之后才写"

`X11Window.cs:373-381`（改后，`ConfigureNotify` 分支**只翻译、不改状态**）：

```csharp
                case X11EventType.ConfigureNotify:
                    // 以 server 报的尺寸为准，而不是我们请求的尺寸。
                    // ⚠️ **这里刻意不写 `_width/_height`**：这条 XEvent 的 `window` 字段才是
                    //    归属依据，而"谁抽到这条事件"**不是** —— 队列是**连接级**的（见
                    //    `WindowEvent.WindowId` 的注释）。旧代码在这里无条件写缓存尺寸，
                    //    正是缺陷 A：弹窗的 ConfigureNotify 被记到了抽事件的**主窗口**头上
                    //    （详见 `ApplyOwnConfigureNotify()` 的注释与现场读数）。
                    //    缓存尺寸的唯一写点是 `ApplyOwnConfigureNotify()`，它在**核实 XID 之后**才写。
                    return new WindowEvent
```

新增 `X11Window.cs:449-484`（`internal bool ApplyOwnConfigureNotify(in WindowEvent ev)`；**归属判据写在这里**）：

```csharp
        internal bool ApplyOwnConfigureNotify(in WindowEvent ev)
        {
            if (ev.Kind != WindowEventKind.Resized) return false;

            // 归属判据：`WindowId == 0` = 事件里没有窗口字段（`Translate` 只在 `native.Window != 0`
            // 时填），那按"本窗口自己的事件"处理；**只要填了窗口就不是本窗口的一律拒绝**。
            if (ev.WindowId != 0 && ev.WindowId != Id) return false;

            _width = ev.Width;
            _height = ev.Height;
            return true;
        }
```

XML 注释里逐字附了判定点、现场读数（`$HOME/hc-fo3-mil.log:7885-7886`）与"唯一写点可枚举"的论证。

### ②-3 改动二：`MilPresentation.PumpWindowEvents` —— 事件的 `window` 字段是**唯一**归属依据

`MilPresentation.cs:637-647`（改后：不再"就地丢弃"，而是找到主人）：

```csharp
                        IntPtr owner = hwnd;
                        X11PresentationTarget ownerTarget = target;
                        if (ev.WindowId != 0 && ev.WindowId != (ulong)hwnd.ToInt64())
                        {
                            owner = (IntPtr)(long)ev.WindowId;
                            if (!TryGetTarget(owner, out ownerTarget)) continue;
                        }
```

`MilPresentation.cs:648-655`（`Resized`：尺寸只记在主人身上，日志里的 HWND 也写主人）：

```csharp
                            case WindowEventKind.Resized:
                                // ★ 缓存尺寸只许记在**事件的主人**身上（缺陷 A 的判定点）。
                                //   方法内部还会再核一次 XID：归属不符的事件改不动任何窗口的尺寸。
                                ownerTarget.Window.ApplyOwnConfigureNotify(ev);
                                lock (_gate) _resizeEvents++;
                                needRepaint = true;
                                MilDiagnostics.Note(
                                    $"X11 Resize：HWND 0x{(long)owner:x} → {ev.Width}x{ev.Height}（将按新尺寸重渲）");
                                break;
```

同趟还有 `Closed` 分支按主人解绑（`MilPresentation.cs:662-667`：`X11 Closed：HWND 0x{owner:x}` /
`TryUnbind(owner)` / `_channelByHwnd.Remove(owner)`）—— 与 `Resized` 同一条语义（事件的主人决定算在谁头上），
不是另一处改动。

### ②-4 after sha16（现场算）

| 文件 | after sha16 |
|---|---|
| `src/WpfGfx.Linux/Windowing/X11Window.cs` | `ea6c653493f05a93` |
| `src/WpfGfx.Linux/Interop/MilPresentation.cs` | `ee89f32def7c98d2` |

改动**只有这两个文件**；没有新增文件/新增 import（⇒ 不触 `build-hygiene-roster.tsv` 与
`build-hygiene-import-check.sh` 的 41 件/82 行口径）。

---

## ③ 两极化读数（NOTE 原文）

### ③-1 现场（改前，共享目录那趟，`$HOME/w46a/pre2/mil.log`，sha16 `d91d4078978f2708`）

```
7538:AttachToHwnd: HWND 0x200008 → 呈现目标已绑定（窗口 1x1，own=False）
7900:NOTE X11 Resize 生效：HWND 0x200004 800x600 → 413x274（按新尺寸重渲）        ← ★ 缺陷 A：记到主窗口
7901:  ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200004 已呈现 413x274（skia 指令 439 条，未画种类 0）  累计帧数 = 17
8157:  ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200004 已呈现 800x600（skia 指令 443 条，未画种类 0）  累计帧数 = 18
8164:NOTE X11 Resize 生效：HWND 0x200004 413x274 → 800x600（按新尺寸重渲）
```

**没有任何一条 NOTE 的 HWND 是 `0x200008`** —— 弹窗的 ConfigureNotify 被"花"在主窗口头上了。

### ③-2 现场（改后，隔离趟，`$HOME/w46a/iso-post/mil.log`，sha16 `fd85d1354206b2b1`）

```
7538:AttachToHwnd: HWND 0x200008 → 呈现目标已绑定（窗口 1x1，own=False）
7567:NOTE X11 Resize：HWND 0x200008 → 413x274（将按新尺寸重渲）                  ← ★ 归属弹窗
7908:NOTE X11 Resize：HWND 0x200008 → 413x274（将按新尺寸重渲）                  ← ★ 第二条（同趟事件）
```

**主窗口的呈现记录只有一条尺寸变化**：`37: ★ 呈现尺寸变化：通道 2 → HWND 0x200004 已呈现 800x600`。
`grep -c 'HWND 0x200004 已呈现 413x274'` ⇒ **0**。

### ③-3 隔离 A/B 汇总表（私有应用目录 `$HOME/w46a/app` ＋ 私有 DISPLAY `:45`）

| 趟 | 桥 sha16 | NOTE 的 HWND | 主窗口按 413x274 出帧 | 弹窗几何（tree） | 应用结局 | mil.log sha16 |
|---|---|---|---|---|---|---|
| `iso-pre`（改前） | `496951adff86a557` | `0x200004`（"生效"） | **1** | `413x274+559+356` | 活到 t≈40（脚本收尾时 `t-end alive=yes`；`XIO=0`、弹窗 MAP=1） | `f1e846d333890097` |
| `iso-post`（改后） | `6fac9e722299a768` | **`0x200008`** ×2 | **0** | `413x274+559+356` | 活到 t≈39（`t-end alive=yes`；`XIO=0`、弹窗 MAP=1） | `fd85d1354206b2b1` |
| `iso-post2`（改后 · 复跑） | `6fac9e722299a768` | **`0x200008`** ×2 | **0** | `413x274+559+356` | 活到 t≈39（`t-end alive=yes`；`XIO=0`、弹窗 MAP=1） | `851d6a6bf2eb4b1a` |

- 隔离口径：`$HOME/w46a/iso-run.sh <out> :45` —— 私有 app 目录、私有 Xvfb、**跑前跑后各算一次桥 sha**
  （三趟都是 `so-before == so-after` ⇒ 没人换我的件）；每趟开始前要求 `pgrep -c -x dotnet == 0`。
- **弹窗几何三趟一致** `413x274+559+356`（与主控读数一致 ⇒ 我只改了归属，没有改几何/生命周期）。
- 改前那趟的 `413x274` 帧 = 缺陷 A 的"后果"判据；改后 0 帧 = 修好。
- **逐像素**：改前 post.png 与改后 post.png `compare -metric AE` = **0**（见 ⑤-b 的解释：本场景肉眼看不见差别）。

---

## ④ 桥新产物的 sha16 与大小

| 产物 | sha16 | 全 sha256 | 大小 | 时间 | 说明 |
|---|---|---|---|---|---|
| 我这趟**独占**构建（只含我的改动） | `58a7abfeda93e662` | `58a7abfeda93e662e41c154fe52db8feee286d59563166d966455c93552c4ff1` | 4,996,080 B | 20:08 | ⚠️ **已被 20:09 另一车道的重构建覆盖，盘上不再存在**（如实登记，见 ⑤-a） |
| 当前树构建（我的改动 ＋ 另一车道 20:09 加的**只读仪器**） | `6fac9e722299a768` | `6fac9e722299a768ce550774a196f8556af2688b922c3d4b603c2bb456f59adf` | 5,000,192 B | 20:09 | publish 与 hc 应用目录**一致**；③ 的三趟隔离读数用的就是它 |

- publish 路径：`R/build/MilBridge/.artifacts/publish/MilBridge.Linux/release_linux-x64/wpfgfx_cor3.so`
- 已装到 hc 应用目录：`/home/links-dev/hc-linux/src/Net_GE45/HandyControlDemo_Net_GE45/bin/Debug/net10.0/wpfgfx_cor3.so`
  （旧件备份 `$HOME/w46a-backup/wpfgfx_cor3.so.hc-before`，sha16 `496951adff86a557`）
- **重建口径**：`export PATH="$HOME/.dotnet:$PATH"; export DOTNET_gcServer=0; nice -n 5 bash build/MilBridge/run.sh build`
  —— `run.sh` 的 `build()` 自带 `dotnet publish -c Release -r linux-x64 -m:1`（`:43-44`），
  导出符号对拍 `清单 109 / 缺失 0`，`rc=0`；构建前 `MemAvailable=2943500 kB ≥ 1500 MB`、
  `pgrep -a dotnet` 为空。

---

## ⑤ 顺带发现（含我自己踩的坑）

### ⑤-a ⚠️ 我先看到的那两趟"改后停摆"是**并发污染**，不是这个修法

事实链（时间、sha、PID 都是现场记的）：

1. 20:08 我独占构建 → 装 `58a7abfe` 到**共享的** hc 应用目录；20:08:4x 跑共享目录那趟（`$HOME/w46a/post`）：
   app.log 在 `[SHOW_DIAG] SetWindowPos hwnd=0x200008 a=22 b=27066642` **之后只剩 4 行**就出现
   `XIO:  fatal IO error 0 (Success) on X server ":47"`，**`CREATE_DIAG MAP xid=0x200008` 从未出现**。
2. 20:09 **另一条车道**改了 `src/WpfGfx.Linux/Interop/MilNative.cs` 与 `Resources/MilChannel.cs`
   （mtime 20:09，内容是 env 门控只读仪器 `WPF_LINUX_CMDLOG=1` 一类）并重构建 ⇒ publish 变
   `6fac9e72`（5,000,192 B）；同期 `pgrep -a` 看到别人的 `dotnet HandyControlDemo.dll` 在跑。
   我的第二趟（`post2`）也死在同一处（同样 4 行 + XIO + 无 MAP）。
3. ⇒ 判为**共享资源争用**（同一 app 目录被换件 / 同一 DISPLAY 被抢 / 别人的应用在飞），
   不是缺陷 A 的修法本身。
4. **独立支持**：`hc-*/app.log` 历史群体（60 份）里 **6 份**出现同款 `XIO`；其中 `hc-ht3/app.log`
   正是**停在同一个** `SetWindowPos hwnd=0x200008 a=22` 之后（老桥、**没有**我的改动）⇒
   这是**先存**的偶发形态，与本次改动无关。
5. **隔离复验**：搭私有 app 目录（`$HOME/w46a/app`，113 MB）＋ 私有 `Xvfb :45`，
   跑前跑后桥 sha 不变、开始前要求无别的 dotnet ⇒ 改后 **2/2 存活**、改前 1/1 存活。
   ⇒ 那两趟死亡在隔离下**不复现**。

> 自查披露（如实登记）：我做 hang 探针时用 `pgrep -x dotnet | head -1` 取 PID，当时机器上
> **同时有别人的 dotnet 进程**（探针打印 `PROBE pid=1501400`，随后 `pgrep -a` 又看到 `1501728`），
> 因此**我可能误杀了另一条车道的 `HandyControlDemo` 进程**。此后我改成"私有 app 目录＋跑前
> `pgrep -c -x dotnet == 0` 才开跑"，不再用 `pgrep` 猜 PID。

6. **并发披露（收工复核）**：20:19:56 起车道 **W46C** 在 `:46` 上另跑一份 app
   （`/proc/1502946/environ` 逐字：`DISPLAY=:46`、`HC_FO_OUT=/home/links-dev/w46c-6`、
   `WPF_LINUX_MIL_LOG=/home/links-dev/w46c-mil6.log`）⇒ 20:09 那次 `MilNative.cs`/`MilChannel.cs`
   改动与重构建**极可能就是 W46C 的**。我的三趟隔离要么在它起跑前开始（开跑前
   `ISO so-before` 那行之前没有 `ISO wait other-dotnet` ⇒ 当时 `pgrep -c -x dotnet = 0`），
   要么用**私有** app 目录 ＋ **私有** `:45`，所以它的 `:46`/共享目录活动进不到我的读数里。
   我**没有**碰它的进程（收工时 `:46` 的 `Xvfb` 与 app 仍在跑，是它的）。

### ⑤-b 缺陷 A 的可见后果在本场景里**是 0 像素**（重要边界）

`compare -metric AE iso-pre/post.png iso-post/post.png` = **0** —— 改前改后的屏幕**逐像素相同**。
原因是：缺陷 A 让主窗口那一帧"按 413x274 渲"，而本应用的内容锚在左上、布局不随视口变化
⇒ 左上 413x274 的像素两次渲染本来就一样，差别只在"其余区域是旧帧"这一件事上，静态场景下看不出来。
⇒ **判据只能取日志/帧几何**（NOTE 的 HWND、有没有 `已呈现 413x274`），不能取截屏。
⇒ 弹窗要**真的出现像素**，还得等主控的缺陷 C（弹窗通道没有根）与架构项（按目标呈现）——我没有碰它们。

### ⑤-c 残留（我没改、如实登记）

1. 泵抽到"主人不在绑定表里"的事件仍然**就地丢弃**（`:642` 的 `continue`）：本层没有连接级待处理队列，
   ⇒ 那扇**未绑定**的窗自己的 ConfigureNotify 会丢。本场景弹窗已被 `AttachToHwnd` 绑定
   （`iso-post/mil.log:7538`），走的是转交分支。
2. `PumpWindowEvents` 的重渲块（`MilPresentation.cs:670-682`）在**任何**窗口有事件时会把**所有**
   绑了通道的窗口重渲一遍（既有行为，我没动）；`repaint` 返回值唯一调用点 `:822` 不用它。
3. 我把"邻居的 resize 事件"也算作"这趟要重画"（`needRepaint = true`）：与既有"有事件 ⇒ 重渲一趟"
   的口径一致；隔离两趟里没有观察到任何异常帧或停摆。

### ⑤-d 为什么"唯一写点"是可辩护的（可枚举论证）

`X11Window` 与 `X11PresentationTarget` 都是 `internal sealed`，所以事件消费者可枚举：
全仓只有 `MilPresentation.PumpWindowEvents()`（`:616`）一处；另外 4 处直接调 `TryNextEvent` 的都是测试
（`tests/.../X11PresentationTargetTests.cs:94/107/129`、`tests/.../X11RealInputEventTests.cs:244/271/284`），
**没有任何一处断言 `Width/Height` 因事件而变**（逐行读过；`Resize_DeliversConfigureNotify` 断言的是
`ev.Width/ev.Height`，不是 `window.Width`）⇒ 把写入从 `TranslateCore` 搬到核验 XID 之后的唯一写点，
对这些读者零影响。

---

## ⑥ `NOINFO` 清单（逐条，今日取不到的）

1. **没跑任何验证仪器**：`verify-all` / `close-wave` / 应用门禁 / 单测**一律没跑**（按指令），
   ⇒ 我的改动对既有仪器读数（九位、各步判据、`累计帧数` 类断言）的影响 **未测**；"九位里哪位位移"归主控。
2. **弹窗侧"缓存尺寸"的下游效果今天不可观测**：弹窗那条通道**没有根视觉**（缺陷 C），
   `PresentChannel` 在 `:852-857` 早退 ⇒ 永远走不到 `:906-918` 的"resize 生效"。
   我修好的那半边（尺寸记在弹窗自己身上）今天**只能由代码判定**，不能由读数判定。
3. **那两趟死亡的精确根因未取到**：是"`.so` 被换件"、"Xvfb 被别人的脚本杀掉"还是别的共享争用，
   没有 strace/审计读数；我只证明了**隔离下不复现**（2/2 存活）。
4. **我 20:08 那趟独占产物 `58a7abfe` 已不存在**：无法再对它做逐位对照；谁在 20:09 覆盖了
   publish/共享应用目录，我只有 mtime＋sha 变化，没有人证。
5. **未做"重构建确定性"对照**：没做"撤掉我的改动重建是否逐位回到 `496951ad`"（要临时改共享树，
   而 20:09 之后树里已经有别人的改动，`496951ad` 也不是"当前树减我"的等价物）。
6. **主窗口那帧"按弹窗尺寸渲"的像素级后果未逐像素取证**：只有帧尺寸/日志；AE=0 是"看不出来"，
   不是"没发生"（发生的是"右下区域保持旧帧"，静态场景里无像素差）。
7. **`X11Closed` 分支的转交路径本场景未触发**（三趟隔离里 `X11 Closed` 命中 0 次）⇒
   "Foreign Closed 走主人解绑"这条**只有代码判定**，无本场景读数。

---

## 附：文件与留档

- 改动：`src/WpfGfx.Linux/Windowing/X11Window.cs`（`ea6c653493f05a93`）、
  `src/WpfGfx.Linux/Interop/MilPresentation.cs`（`ee89f32def7c98d2`）
- 备份：`$HOME/w46a-backup/{X11Window.cs.before,MilPresentation.cs.before,wpfgfx_cor3.so.hc-before}`
- 读数：`$HOME/w46a/{pre,pre2,post,post2,iso-pre,iso-post,iso-post2}/`（各含 `mil.log`/`app.log`/`tree.txt`/PNG）
- 仪器：`$HOME/w46a/iso-run.sh`（隔离复现）、`$HOME/w46a/hang-probe.sh`（停摆探针，仅诊断用）
- 未动：`known-red.json`、`arm-logs/**`、`verify-all.sh`、`close-wave.sh`、`ACCEPTANCE-BASELINE.md`、
  任何 `*.tsv` 名册；未跑 `integration-wave.sh` / `verify-all.sh` / 冻结。

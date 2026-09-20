# 波 `#46` · `D-G54` 设计稿 —— **按目标呈现**（per-target present）与「一个通道挂两扇窗」

> 车道：`W46F`（**只读设计/复核；未改任何既有文件、未构建、未跑被测应用**）
> 时间：2026-09-19 20:20 → 20:35 +0800｜kernel `6.8.0-138-generic`｜`loadavg` 见 §12｜`MemAvailable` 见 §12
> 仓根 `R=/home/links-dev/netTest/wpf-linux-20260906/wpf-linux`
> 交付：本文件 ＋ `$HOME/w46f-notes.md`（草稿/原始证据摘录）

---

## §0 一句话结论（三个）

1. **上游模型**：`SetRoot` 是**每个 `HwndTarget` 各一条**、发在**主通道**上（`HwndTarget.cs:788-791`）；out-of-band 通道**从不**设根 ⇒ 桥在通道 3 上打的那条
   `通道 3 无根视觉（未 TargetSetRoot）` **是合规状态被写成了缺陷语句**，它把整轮排查引向了"managed 没走到 SetRoot / 命令丢了"两个假方向。
2. **桥的"存根"其实早就按目标了**：`MilTarget.Root`（`Resources/MilResources.cs:435`）在 `MilCmdTargetSetRoot` 派发点**每目标各写一次**（`Commands/MilCommandDispatcher.cs:349`）。
   按通道的只有**读取端**（`MilPresentation.PresentChannel` 改前 `:873-879`：以通道级单槽 `IMilChannel.Root` 当"有没有根"的判据）＋ `TryResolveTarget`（改前 `:745-772`：只取**第一个**带 HWND 的目标）。
   ⇒ **"按通道存根 ⇒ 按目标呈现"这句话要改口径**：不是搬存储，是**改唯一那个读者**（＋ 给"根属于哪条通道"补一笔归属标记，理由见 §4-D3）。
3. **最小改动集 = 6 处，全部在 `src/WpfGfx.Linux/**`**（§4）。其中**必须有**一处是"根句柄的**通道归属**"——否则按目标呈现会引入一类**新的静默错配**（拿主通道的槽号去 OOB 通道的表里查，可能命中**无关 visual**）。这一条是本次设计里**唯一不能省**的新增状态。

---

## §1 上游模型（逐条 `文件:行` ＋ 原文）

### 1.1 ~~`SetRoot` 是不是"每个 target 一条"~~ ⇒ **是**

`upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/System/Windows/InterOp/HwndTarget.cs`（sha16 `a0c89a548495ee57`，115,355 B）：

```csharp
714:        internal override void CreateUCEResources(DUCE.Channel channel, DUCE.Channel outOfBandChannel)
...
740:            bool resourceCreated = _compositionTarget.CreateOrAddRefOnChannel(this, outOfBandChannel, DUCE.ResourceType.TYPE_HWNDRENDERTARGET);
741:            Debug.Assert(resourceCreated);
742:            _compositionTarget.DuplicateHandle(outOfBandChannel, channel);
...
746:            DUCE.CompositionTarget.HwndInitialize(
747:                _compositionTarget.GetHandle(channel),
748:                _hWnd,
...
788:            DUCE.CompositionTarget.SetRoot(
789:                _compositionTarget.GetHandle(channel),
790:                _contentRoot.GetHandle(channel),
791:                channel);
```

**读法（三句）**：
- `CreateUCEResources` 是**每个 `HwndTarget` 实例**各调一次（由 `MediaContext` 在通道连接/重连时驱动）⇒ 每个窗口目标**各自**发一条 `MilCmdTargetSetRoot`；
- 三条命令全用 `channel`（**主通道**）的句柄：目标句柄靠 `:742` 先从 OOB **Duplicate 到主通道**才用（`:740` 的 `Debug.Assert(resourceCreated)` 说明目标是**在 OOB 上创建**的）；
- **OOB 通道拿到的是"目标资源本身"（＋内容根，见 §1.3），但从来拿不到根绑定。**

`ReleaseUCEResources`（`:811-832`）对称地把根**设成 Null**（`:821-824`，同样在 `channel` 上）：

```csharp
821:                DUCE.CompositionTarget.SetRoot(
822:                    _compositionTarget.GetHandle(channel),
823:                    DUCE.ResourceHandle.Null,
824:                    channel);
```

### 1.2 现场对得上（两条独立证据）

- **managed 侧两次都走到 `SetRoot`**：`$HOME/hc-ht2/app.log`（sha16 `95b68f3af2cc59f9`，117,020 B）第 8-14 行与第 151-156 行各是一组完整的
  `CreateUCEResources 进入 → 建目标资源后 → 复制句柄后 → SetRoot 之前 → SetRoot 之后：已发出 → RootVisual setter 被调：value=MainWindow / PopupRoot`，
  且**两组打印的 channel 哈希相同**（`channel=2b86539 oob=7b8f05`）⇒ 两条 SetRoot **同一条主通道**。
- **不是每 target 一条通道**：同一趟 `hc-miltrace-1` 的通道普查只有两条通道（`hc-miltrace-1/app.log`，sha16 `1e9a935e3d00428b`，247,886 B）：

```
821:  通道#2: committed=3618 … 资源=2295 root=有 窗口目标=0x200008 视觉树={子=0 内容=无 不透明=1} [MilEtwEventResource×1] [MilVisualResource×1017] [MilHwndTarget×2] …
822:  通道#3: committed=7 notimpl=0 failed=0 short=0 pending=0 batchBytes=0 资源=4 root=无 窗口目标=0x200008 [MilVisualResource×2] [MilHwndTarget×2]
```

⇒ **通道 2 一条通道挂了 `[MilHwndTarget×2]`**（主窗 `0x200004` ＋ 弹窗 `0x200008`），全部内容（`MilVisualResource×1017`）也在通道 2。

### 1.3 一棵窗口树 = 一个**内容根**（`TYPE_VISUAL`），不是"通道一棵树"

- `System/Windows/Media/CompositionTarget.cs`（sha16 `c02701e71aa620e3`）：`359: internal const DUCE.ResourceType s_contentRootType = DUCE.ResourceType.TYPE_VISUAL;`
- `System/Windows/Media/VisualTarget.cs`（sha16 `bd239e7cc90d5406`）：`:92-94` 把 `_contentRoot` **在 OOB 与主通道各建一次**；
- `CompositionTarget.cs:427: rc.Initialize(channel, _contentRoot.GetHandle(channel));` ⇒ **渲染上下文挂在"自己的内容根"上**；
- `HostVisual.cs:308-312` 把根视觉作为**子节点命令**接到内容根下（不是 SetRoot）。

⇒ **`SetRoot` 命名的那个句柄就是"本窗口整棵树的树根"**。两扇窗 ⇒ 两棵内容根 ⇒ **同一条通道里两棵互不相干的树**。通道级单槽在结构上**表达不了**它。

### 1.4 ⇒ 那条 NOTE 是**误导**（本轮最值钱的一条纠错）

`hc-miltrace-1/app.log` 里 `无根视觉（未 TargetSetRoot）` **共 12 条，全部是"通道 3"**（第 26/29/30/31/736/737/739/745/825/832/838/839 行），**"通道 2"一条都没有**；而同一份日志里 `WgxConnection_SameThreadPresent 第 N 次：通道 2/通道 3` 两条路径都在跑（第 9/11/13/17/19 行）。

⇒ 结论：**"OOB 通道没有根"是上游的合规行为**（§1.1），不是缺陷。把"通道 3 无根"当作 `D-G54` 的证据（本轮多处材料如此，包括 `src/WpfGfx.Linux.Native/tools/patch-presentationcore-hwndtarget-trace.py` 顶部注释的"弹窗目标…从没收到 SetRoot"）是**把合规状态读成了缺陷**。
⇒ 建议（主控写域）：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G54` 节与 `docs/WAVE46-PROGRESS.md` 里这条口径要改，否则下一轮车道会再被引一次。
⇒ 另：`docs/WAVE46-PREREGISTRATION.md:166-170` 的判定点（`WS_EX_LAYERED` / `UpdateLayeredWindow`）**已被本波反证**（`docs/WAVE46-PROGRESS.md`（sha16 `d7154e3ccc739832`）"已证伪的假设"第 3 条），该段落口径同样过期。

---

## §2 桥侧现状（**改前**基线，逐条 `文件:行`）

> ⚠️ **在飞实现提示**：车道 `W46F` 读文件时发现**另一个车道正在同一处落地**（`MilPresentation.cs` mtime 20:27:39、`MilChannel.cs` 20:27:47、`MilNative.cs` 20:27:56）。本节的"改前"行号取自 20:2x 之前的版本，§9 对在飞实现逐条对照并给出缺口。**行号会漂**，每处都附了原文锚点，请按锚点定位。

### 2.1 写侧：一条命令**同时**写两个地方

`src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs`（读数时刻 20:22 的 sha16 `b0ddcd23f3e0cbca`，72,944 B；**20:28:02 起**被在飞实现改成 `748f781620ea4008`，73,664 B —— 加的正是本设计 **D4** 那一行 `ch.MarkTargetRooted(t)`，见 §9）：

```csharp
342:                case MilCmd.MilCmdTargetSetRoot:
343:                {
344:                    int hr = Require<MilTarget>(ch, c, out MilTarget t);
345:                    if (HResult.Failed(hr)) return hr;
346:                    DUCE.ResourceHandle root =
347:                        MilCommandDecoder.ReadFixed<S.MILCMD_TARGET_SETROOT>(c).HRoot;
348:                    if (!root.IsNull && ch.GetVisual(root) == null) return HResult.E_INVALIDARG;
349:                    t.Root = root;
350:                    // 同步到契约 IMilChannel.Root，供渲染层取用
351:                    ch.SetRootFromHandle(root);
352:                    return HResult.S_OK;
353:                }
```

- `:349` = **本来就是"每目标一棵根"** ⇒ 存储端不需要改；
- `:351` = 把同一条命令**再**写进通道级单槽（`Resources/MilChannel.cs:377-381` 的 `SetRootFromHandle` ⇒ `VisualProjection.Project`）⇒ **后 SetRoot 的那扇窗覆盖前一扇**；
- `:348` 的 `ch.GetVisual(root) == null ⇒ E_INVALIDARG` 是**能过的**：内容根是 `TYPE_VISUAL`（§1.3）⇒ 桥建的是 `MilVisualResource`。**这一条排除**了"弹窗那条 SetRoot 因根句柄解析失败被拒"的机制。

> 上段引自 **20:22 版**（`b0ddcd23f3e0cbca`）。**20:28:02 起**该分支变成 `:342-360`，在 `t.Root = root;`（`:349`）与 `ch.SetRootFromHandle(root);`（`:358`）之间多了一行 **`:356 ch.MarkTargetRooted(t);`** —— 那正是本设计的 **D4**（§4）。

### 2.2 读侧（改前）：`PresentChannel` 以**通道级单槽**为判据

`src/WpfGfx.Linux/Interop/MilPresentation.cs` **改前**（sha16 `ee89f32def7c98d2`，67,698 B，mtime 20:07:37；现在已是在飞实现）：

```csharp
851:            if (!TryResolveTarget(channel, out MilTarget target))
...
860:            IntPtr hwnd = target.NativeWindow;
...
873:            MilVisual root = (channel as IMilChannel).Root;      // ← 通道级单槽
874:            if (root == null)
877:                MilDiagnostics.Note($"WgxConnection_SameThreadPresent: 通道 {channel.Id} 无根视觉（未 TargetSetRoot）");
...
896:                MilVisual live = VisualProjection.Project(channel, target.Root);
897:                if (live != null) root = live;                    // ← 现投影**优先于**通道快照
```

**两条要点（都与 W46C 的机制结论有关，见 §11）**：
- `:860` 的 `hwnd = target.NativeWindow` ⇒ **"呈现给谁"完全由被选中的那个 target 决定**；日志里 `→ HWND 0x200004` 就说明**被选中的是主窗目标**；
- `:896-897` **现投影优先** ⇒ 通道级单槽（被弹窗覆盖的那个根）**只有在 `Project(channel, target.Root)` 返 null 时才被采用**。

### 2.3 读侧（改前）：`TryResolveTarget` 只取**第一个**

```csharp
745:        internal static bool TryResolveTarget(MilChannel channel, out MilTarget target)
...
764:            for (int i = 0; i < keys.Count; i++)
765:            {
766:                if (!(channel.Resources.Lookup(new DUCE.ResourceHandle(keys[i])) is MilTarget t)) continue;
767:                if (t.NativeWindow == IntPtr.Zero) continue;
768:                target = t;
769:                return true;                                    // ← 第一个即返回
770:            }
771:            return false;
772:        }
```

`keys` 来自 `channel.Resources.Entries`，而那是 `Dictionary<uint, MilResourceEntry>`（`Resources/MilResourceTable.cs:28`），句柄还会被**回收复用**（`:29 _freeHandles` / `:108-112 AllocHandle` 先弹栈）⇒ **"第一个"既不是句柄序也不是插入序，跨运行不稳定**。

> 勘误：用户派单里写 `TryResolveTarget（:723 起）` 与"`MilPresentation.cs` 的 preflight 台账"；实测是 **`:745` 起**，且 preflight 台账在 **`Interop/MilNative.cs`**（改前 `:95-129`，调用点 `:208-209`）。已按实测写。

### 2.4 现场：弹窗**从未**成为呈现目标

`hc-miltrace-1/app.log`：

```
741: [mil  139] NOTE X11 Resize 生效：HWND 0x200004 800x600 → 413x274（按新尺寸重渲）
742: [mil  140]   ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200004 已呈现 413x274（skia 指令 439 条，未画种类 0）  累计帧数 = 17
824: [mil  143]   ★ 呈现尺寸变化（免采样）：通道 2 → HWND 0x200004 已呈现 800x600（skia 指令 443 条，未画种类 0）  累计帧数 = 18
```

`grep -c '已呈现.*0x200008'` = **0** ⇒ 弹窗窗口**一次都没当过呈现目标**（与 `docs/WAVE46-PROGRESS.md` 的 `D-G54` 机制定案一致）。第 741 行的 `413x274` 是**缺陷 A**（`ConfigureNotify` 归属错窗，`build/MilBridge/W46A-report.md` 已修）。

---

## §3 数据流（命令载荷 / 句柄语义 / "命令到底丢没丢"）

### 3.1 载荷

- `Commands/MilCommandLayout.cs`（sha16 `4f4f3f8fc3495c16`）：`83: MilCmd.MilCmdTargetSetRoot => 12,`
- `Commands/MilCommandStructs.cs`：

```csharp
386:        internal struct MILCMD_TARGET_SETROOT
387:        {
388:            [FieldOffset(0)] public MilCmd Type;
389:            [FieldOffset(4)] public DUCE.ResourceHandle Handle;
390:            [FieldOffset(8)] public DUCE.ResourceHandle HRoot;
391:        }
```

- `MilCommandDecoder.ReadHandle`（`Commands/MilCommandDecoder.cs:28 HeaderHandleOffset = 4`、`:34-35`）读偏移 4 ⇒ `Require<MilTarget>(ch, c, …)` 查的就是 `:389` 的 `Handle`；`HRoot` 在 `:390`。

### 3.2 `HRoot` 是**哪条通道**的句柄？⇒ 派发那条通道的（也就是**主通道**）

上游生成侧把两个句柄都取成 `channel` 的（`HwndTarget.cs:789-790`，§1.1）；桥的两处查找也都在**收到命令的通道**上做（`MilCommandDispatcher.cs:344` 与 `:348`）。**二者自洽**。

⇒ **对派单里的问题"`Require<MilTarget>` 在收到命令的通道里查目标句柄，弹窗场景会怎样？"的答案**：
**在弹窗场景里这是对的**，因为 `:742` 已经把目标句柄 Duplicate 到主通道（现场证据：`[HT] 复制句柄后：… IsOnChannel(main)=True`，`hc-ht2/app.log:153`），而 SetRoot 也发在主通道。
**不许**把它改成"跨通道找目标"—— 那会把 `Require<T>` 的 `E_HANDLE` 判据（`MilCommandDispatcher.cs:1382-1384`）一起废掉，且掩盖真句柄错。

### 3.3 句柄是**每通道槽号**（这条是 §4-D3 的全部理由）

`Resources/MilResourceTable.cs`（sha16 `8dc815a5d1a5f808`）：

```csharp
28:        private readonly Dictionary<uint, MilResourceEntry> _entries = new Dictionary<uint, MilResourceEntry>();
29:        private readonly Stack<uint> _freeHandles = new Stack<uint>();
30:        private uint _nextHandle = 1;
...
102:            uint h = AllocHandle();
103:            _entries[h] = new MilResourceEntry { Resource = shared, RefCount = 1 };
104:            duplicate = new DUCE.ResourceHandle(h);
...
108:        private uint AllocHandle()
109:        {
110:            if (_freeHandles.Count > 0) return _freeHandles.Pop();
111:            return _nextHandle++;
112:        }
```

- **每个通道从 1 开始各自下发**（`:30`）⇒ 句柄值的命名空间是**每通道**的；
- `Duplicate` 让两个通道的表**指向同一个实例**（`:103 Resource = shared`）⇒ `MilTarget.Root` 这个字段在两条通道上**都看得见**，但那个**数值**只在"设定它的通道"上有效；
- 现场把这一点量得死死的：通道 3 `资源=4`（`hc-miltrace-1/app.log:822`）而弹窗目标在主通道的句柄是 **`0x894`**（＝2196，见 `MilChannel.cs:412` 的 W46C 记录）⇒ 在通道 3 上查 `0x894`：**要么 null，要么命中它自己表里的某个无关 visual**。

⇒ **"按目标呈现"若不带通道归属，就等于把"有可能画错树"引进来**（今天不会，因为今天没人读 `t.Root` 呈现；改后就会读）。

### 3.4 "命令丢没丢"：**preflight 只见一条**是**台账盲区**，不是丢命令

四步链条（全部有原文）：

1. `DUCE.CompositionTarget.SetRoot` 的发送形式：`upstream/wpf/src/Microsoft.DotNet.Wpf/src/Common/Graphics/exports.cs`（90,292 B）`:2372-2377`

```csharp
2372:                unsafe
2373:                {
2374:                    channel.SendCommand(
2375:                        (byte*)&command,
2376:                        sizeof(DUCE.MILCMD_TARGET_SETROOT)
2377:                        );
```

2. 两参重载 ⇒ **`sendInSeparateBatch = false`**（同文件 `:622-627`）⇒ 桥侧 `MilChannel.SendCommand` 走 **"已入批（等 Commit）"**（`Resources/MilChannel.cs:222`）。
3. 同文件 `:664 HRESULT.Check(hr);` ⇒ **桥一旦返回非 `S_OK`，managed 侧抛异常**。桥唯一会拒的形态是 `_openStart >= 0` ⇒ `E_UNEXPECTED`（`MilChannel.cs:199`）。
4. 而插桩的 `SetRoot 之后：已发出` 打在 `SetRoot` **返回之后**（`src/WpfGfx.Linux.Native/tools/patch-presentationcore-hwndtarget-trace.py`，sha16 `1ac574eb8c9f5576`，`D_REPL` 定义）⇒ **它已经证明桥接受了这条命令**（否则会抛，看不到这行）。

5. 那为什么 preflight 只有一条？因为**改前的 preflight 只长在四条 Commit 路径中的一条上**：
   - ① `MilNative.MilConnection_CommitChannel`（改前 `:208-209` 调 `PreflightPendingCommands`）
   - ② `MilNative.WgxConnection_SameThreadPresent`（改前 `:261 channel.Commit()`，**不打印**）
   - ③ `MilNative.FlushPendingCommandsBeforeInvalidation`（改前 `:143 channel.Commit()`，**不打印**）
   - ④ `MilComposition_SyncFlush`（`MilNative.Window.cs`）
   ⇒ 经 ②③④ 提交的那条 `0x35` **派发了、台账里看不见**。

> 这一条**已被独立证实**：`docs/WAVE46-PROGRESS.md`（20:23 版）"我已更正的两处自家错读：「只有一条 SetRoot」（preflight 盲区）"，且**在飞实现**已把预检**下沉到 `MilChannel.Commit()`**（`Resources/MilChannel.cs:238-240` 调用点 ＋ `:417-442` 实现）。本设计**采纳**该结论。
>
> 附带一条仪器缺口（**尚未见谁报**）：`MilResource_SendCommand` 的入口打印在 `pbData == null / cbSize == 0` 提前返回**之前**，但 `id0 = -1` 会被 `CmdLogWanted(-1)` 过滤掉（`Interop/MilNative.cs` 的 `:373-377` ＋ `MilChannel.cs:132-143`）⇒ **带 `WPF_LINUX_CMDLOG_ID=0x35` 跑时，"载荷为空被丢"这类形态看不见**。要么把该返回也打一行，要么跑时不带 id 过滤。

### 3.5 一条**仪器**勘误：`[HT]` 的句柄列不是句柄

`patch-presentationcore-hwndtarget-trace.py:64`：

```csharp
internal static string H(DUCE.ResourceHandle h) { return h.IsNull ? "null" : h.GetHashCode().ToString("x8"); }
```

`.NET` 的 `ValueType.GetHashCode()` 对单字段结构是**哈希**，不是恒等；真句柄是槽号（§3.3），而主通道 `资源=2295` ⇒ 真句柄**最大也就 0x8f7**。
⇒ `[HT]` 里那些 `0x2adb50bf / 0x3fde8ed8 / b010fb81` **只能是哈希**；`hc-ht2/app.log:9` 与 `:11` 里 `target(OOB)=2adb50bf` 与 `contentRoot=2adb50bf` **同值**是**碰撞**（不可能是真句柄相等）。
⇒ **本设计不依赖 `[HT]` 的句柄列**：只依赖它的**行序与条数**（两组、各 5 行、`SetRoot 之后：已发出` ×2）、`IsOnChannel(main)=True` 与 `RootVisual setter 被调：value=…` 三个**无歧义**读数。
⇒ 建议：`H()` 改成打印 `(uint)h`（真值），或明确写"本列是哈希、不可当 ID"。

---

## §4 最小改动集（6 处）

> 口径纠偏（§0-2）：**存储端早就是每目标一棵根**（`MilTarget.Root`，`MilResources.cs:435`），不要"搬存储"。要改的是**唯一那个读者** ＋ 补一笔**归属**。`IMilChannel.Root` **保留不删**（还有 2 个诊断读者：`MilPresentation.cs:304`（通道普查 `root=有/无`）与 `:824`（`ROOTDIAG` 快照），删它=扩大爆炸半径、零收益）。

### D1 `MilPresentation.CollectTargets(MilChannel) → List<MilTarget>`：**全列** ＋ **按句柄升序**

```csharp
internal static List<MilTarget> CollectTargets(MilChannel channel)   // 新增
{
    var found = new List<KeyValuePair<uint, MilTarget>>();
    // …… 与旧 TryResolveTarget 同样的"先快照键再查"写法（并发修改 ⇒ 返空，下一帧再来）
    foreach (KeyValuePair<uint, MilResourceEntry> kv in channel.Resources.Entries)
        if (kv.Value?.Resource is MilTarget t && t.NativeWindow != IntPtr.Zero)
            found.Add(new KeyValuePair<uint, MilTarget>(kv.Key, t));
    found.Sort((a, b) => a.Key.CompareTo(b.Key));      // ★ 确定性（见下）
    var result = new List<MilTarget>(found.Count);
    foreach (var kv in found) result.Add(kv.Value);
    return result;
}
```

**为什么必须排序**：`Entries` 是 `Dictionary`（`MilResourceTable.cs:28`）＋ 句柄回收（`:29/:108-112`）⇒ 枚举序**既不等于句柄序、也不保证跨运行稳定**。不排序的直接后果：**呈现顺序**与台账里的"第 i/N 个"**每次运行都可能不同**，读数不可比对（本工程的纪律要求读数可复算）。
**排序键取句柄**的额外好处：句柄小 = **先建的目标**（主窗），所以"多目标时的第 1 个"退化成旧实现的"第一个"，与 `KEEP`（见 D6）里的单目标路径同序。

### D2 `PresentChannel` 拆壳 ＋ 逐目标 `PresentTarget`

```csharp
internal static int PresentChannel(MilChannel channel)
{
    if (channel == null) return HResult.E_HANDLE;
    if (!_pumping) PumpWindowEvents();                       // 保持原位（一次/通道）
    long callNo; lock (_gate) callNo = ++_presentCalls;      // ★ 计数口径见 D6-KEEP
    if (ShouldTracePresent(callNo)) Trace($"WgxConnection_SameThreadPresent 第 {callNo} 次：通道 {channel.Id}");

    List<MilTarget> targets = CollectTargets(channel);
    if (targets.Count == 0) { /* 离屏：原文案不变，S_OK */ return HResult.S_OK; }

    int hr = HResult.S_OK; int done = 0;
    for (int i = 0; i < targets.Count; i++)
    {
        int one = PresentTarget(channel, targets[i], targets.Count == 1, callNo, i, targets.Count);
        if (HResult.Succeeded(one)) done++;
        else if (HResult.Succeeded(hr)) hr = one;
    }
    return (done == 0 && HResult.Failed(hr)) ? hr : HResult.S_OK;   // ★ D6 口径
}

private static int PresentTarget(MilChannel channel, MilTarget target, bool singleTargetInChannel,
                                 long callNo, int index, int targetCount)
{ /* 改前 :851-975 的主体，逐目标参数化；根解析见 D3/D4，尺寸见 D5 */ }
```

### D3 **根句柄的通道归属**（本次唯一新增状态；不能省）

- 规则：**只允许在"设定该根的那条通道"上投影那个句柄**。
- 两种实现（择一，**必须择一**）：
  - **(甲) 集合标记**（在飞实现采用）：`MilChannel` 里 `HashSet<MilTarget> _rootedTargets` ＋ `MarkTargetRooted/IsTargetRooted`；派发 `MilCmdTargetSetRoot` 时标记。
  - **(乙) 字段**：`MilTarget` 加 `public MilChannel RootChannel;`，派发时 `t.RootChannel = ch;`；呈现侧 `ReferenceEquals(target.RootChannel, channel)` 才用。
- **为什么不能"跨通道解析"**：§3.3 —— 句柄是**每通道槽号**，通道 3 只有 4 个资源，拿 `0x894` 去查它自己的表**可能命中无关 visual** ⇒ 会**静默画错树**（比"什么都不画"更坏：它看起来像成功）。用 `channel.GetVisual(handle) == null ⇒ 跳过` **不足以**排除别名（别名恰好命中时非 null）。
- **不许**因为这一条去放松 `MilCommandDispatcher.cs:348` 的 `E_INVALIDARG` 判据。

### D4 写侧：派发点**加一行**归属标记（其余一字不动）

```csharp
349:                    t.Root = root;
   +                    ch.MarkTargetRooted(t);        // 或 t.RootChannel = ch;   ← 见 D3
351:                    ch.SetRootFromHandle(root);
```

（**状态**：本行已于 20:28:02 落地在 `MilCommandDispatcher.cs:356`。）

**为什么保留 `SetRootFromHandle`**：它写的是 `IMilChannel.Root`，仍有 2 个诊断读者（§4 开头）；而且**单目标通道**上"通道快照兜底"是既有语义（`PresentTarget` 的 `singleTargetInChannel` 分支，见 D6-KEEP）。删它 = 动契约（`Contracts/Interfaces.cs:34 MilVisual? Root { get; set; }`）＋ 动普查输出，收益为零。

### D5 尺寸：**逐目标**取，并且**把来源打出来**

改前 `:910-941`（现 `:985-1016`）已经是逐目标语义（`target.Width/Height` → `target.WindowRect` → X 尺寸"**变了才**优先"），**本设计不改这条判据**，只补两件事：

- **必须打"尺寸来源"**（X / WindowRect / HwndTargetCreate）与三个候选值，一行；
- **记录一条可复算的陷阱**（本设计预测、需实测确认）：

  `hc-ht2/app.log:150-160` 的顺序是：弹窗窗口先按 **1×1** 建（`:150`）、紧接着该 HwndTarget 的 `CreateUCEResources` 就跑到 `SetRoot`（`:151-155`）、**之后**才 `SetWindowPos`/`ShowWindow`/`MAP 413x274`（`:157-160`）。
  ⇒ `HwndInitialize`（`HwndTarget.cs:746-755`）带的是**当时**的 client rect ⇒ **弹窗目标的 `Width/Height` = 1×1**；而 X 尺寸优先的**条件是"自上次呈现以来变了"**，首次呈现 `haveLast == false` ⇒ **不触发**。
  ⇒ 于是弹窗首帧的尺寸只能靠 `WindowRect`（`MilCmdTargetUpdateWindowSettings`）。**若那一帧 `WindowRect` 还没到** ⇒ 会拿 1×1 去渲一帧 —— 屏幕上看是**空白**，判据会读成"修法没生效"（假阴性）。
  ⇒ **备选 B（只在实测撞上 1×1 时才落）**：把条件改成
  `if ((!haveLast || last != (xw,xh)) && xw > 0 && xh > 0) { 用 X }`，
  理由：**"从未呈现过的目标"没有上一帧要保护**，而 X 窗口尺寸就是它自己对外的真实大小；这一条**不改**主窗启动那一格的行为（实测那一格记录值与 X 值本来就一致：`hc-miltrace-1:824` 800×600）。
  ⇒ **备选 B 落不落，必须由"尺寸来源"那一行读数决定**（不许凭感觉）。

### D6 返回码聚合口径（**写死并给理由**）＋ KEEP 清单

- **多目标**：`done > 0 ⇒ S_OK`（其余目标的失败进 `MilDiagnostics.Note` ＋ 新计数 `TargetsSkipped`）；`done == 0 && 有失败 ⇒ 带出该失败`。
- **理由（这不是"放松"，是防一类崩溃）**：`exports.cs:376 HRESULT.Check(UnsafeNativeMethods.MilConnection_CommitChannel(_hChannel));` ⇒ **Commit 返回失败码 = managed 侧抛异常**。而"窗口已销毁、目标资源还没 Release"是正常时序（`MilPresentation.PumpWindowEvents` 的 `Closed` 分支 `:666 TryUnbind(owner)` ⇒ 此后该 HWND `!HasTarget`）。
  **若改成"第一个失败码胜出"**：弹窗一关（或 `Detach`），**主通道每一次 Commit 都会返回 E_FAIL** ⇒ 真应用可能直接死在这条异常上 —— 而判据里没有任何一条**要求**它失败。**同一口径必须写进判据文档**，别让两个人按两种口径读。
- **KEEP（既有判据依赖的语义，逐条不动）**：
  1. `_presentCalls` **每次通道调用** +1（不是每目标）——`M7cChainTests.cs:148/:270` 断言 `== 1`；
  2. `_framesPresented` **每个成功目标** +1 ——`M7cChainTests.cs:149/:274`、`M7cRealAttachmentTests.cs:272/:294/:338` 在**单目标**场景断言 `0/1/framesBefore`；
  3. 单目标 + HWND 没绑 ⇒ **E_FAIL** ＋ Note 里保留子串 `未绑定呈现目标`（`M7cChainTests.cs:232-236`，`M7cRealAttachmentTests.cs:293`）；
  4. 单目标 + 无根 ⇒ **S_OK** ＋ Note 保留子串 `无根视觉（未 TargetSetRoot）`（`:973-975` 只对多目标换文案）；
  5. 无窗口目标 ⇒ **S_OK** ＋ 原文案（`M7cChainTests.cs:262-271`）；
  6. 单目标路径**优先用通道快照再接现投影**（改前 `:873` → `:896` 的**同序**，用 `singleTargetInChannel` 表达）。

---

## §5 呈现循环（改后形状，伪码）

```
PresentChannel(ch):
  if ch == null: return E_HANDLE
  if !_pumping: PumpWindowEvents()                 # 一次/通道（原有）
  callNo = ++_presentCalls                          # ★ 每通道一次（KEEP-1）
  targets = CollectTargets(ch)                      # 全部 + 句柄升序（D1）
  if targets.none: 打"离屏"原文案; return S_OK       # KEEP-5
  hr = S_OK; done = 0
  for i, t in targets:
      one = PresentTarget(ch, t, single=(len==1), callNo, i, len)
      if one ok: done++ else if hr ok: hr = one
  return (done == 0 && hr fail) ? hr : S_OK          # D6

PresentTarget(ch, t, single, callNo, i, N):
  hwnd = t.NativeWindow                              # 本目标自己的窗口
  if !HasTarget(hwnd):  Note "未绑定呈现目标…"; return E_FAIL          # KEEP-3
  root = single ? ch.Root /*快照兜底*/ : null                           # KEEP-6
  if 本目标的根属于本通道 (D3 标记):                                     # ← D3/D4
        try root = VisualProjection.Project(ch, t.Root)                  # 现投影优先
        catch: Note "重投影失败，退回快照"
  if root == null: Note "无根视觉（未 TargetSetRoot）"(单目标逐字 / 多目标带 HWND); return S_OK   # KEEP-4
  presentation = _targets[hwnd] (否则 E_FAIL)
  _channelByHwnd[hwnd] = ch                          # 让 resize/expose 重渲能找回来
  w,h,来源 = WindowRect > (X 若"变了"| 首次且备选B) > (t.Width,t.Height)      # D5
  if w<=0 || h<=0: return E_INVALIDARG
  打一行"▸ 按目标呈现：通道/HWND/第i+1个/N/target.Root/根来源/尺寸+来源/清屏色/从根可达/孤立"     # D5+§8
  if presentation.size != (w,h): presentation.Resize(w,h)
  frame = RenderChannel(ch, root, w, h, t.ClearColor)   # 失败 ⇒ E_FAIL（诚实）
  立即抓本帧统计: drawn/notDrawn/summary                 # ★ 见 §9-G4（静态字段是进程级）
  presentation.Present(frame); presentation.Sync()
  _framesPresented++                                   # KEEP-2
  TracePresentResult(...)                              # 用刚抓的统计，不读静态
  return S_OK
```

**为什么 `_channelByHwnd[hwnd] = ch` 必须逐目标写**：改前弹窗从未被呈现 ⇒ `_channelByHwnd` 里没有 `0x200008`（`PumpWindowEvents` 改前 `:679-688`：`_channelByHwnd.TryGetValue(hwnd, out ch)`，null ⇒ 不重渲）⇒ **弹窗连 resize/expose 都不可能重画**。改后这一条自然成立，但它**必须**成立，否则"窗口被遮挡后重现"永远是空白。

---

## §6 三种"不一致"的解析规则（派单问题 4 的直接回答）

| # | 不一致形态 | **规则** | 反例后果 |
|---|---|---|---|
| 1 | 根句柄的**设定通道** ≠ 某个（共享实例可见的）通道 | **只在该通道上投影**；其它通道该目标**跳过**（Note：`本目标未 SetRoot 或根子树不属本通道`） | 拿槽号跨表查 ⇒ 命中无关 visual ⇒ **把别人的树画出去**（静默） |
| 2 | 命令里 `Handle`/`HRoot` 的通道 vs 目标"所在"通道 | 二者**本来就同一条**（§3.2）；**不许**引入跨通道查找 | 废掉 `Require<T>` 的 E_HANDLE 判据 |
| 3 | 记录尺寸（`WindowRect`/`Width,Height`/`_lastXSize`）vs X 窗口尺寸 | 逐目标；**先 WindowRect**，X 尺寸**仅当"变了"**优先（既有判据）；首次呈现的 1×1 陷阱见 D5-备选B | 假阴性（空白弹窗被读成"没修好"）或假阳性（把主窗按弹窗尺寸画） |

---

## §7 不破坏既有 PASS 的边界（逐条 `文件:行`）

| 边界 | 既有断言（原文位置） | 本设计为什么不动它 |
|---|---|---|
| 单窗口常规路径 | `tests/WpfGfx.Linux.Tests/Presentation.Tests/M7cChainTests.cs`（sha16 `ec66b9648c405767`）`:148-153`：`PresentCalls==1`、`FramesPresented==1`、`DrawnCommands>=2`、`NotDrawnCommands==0` | `CollectTargets` 单个 ⇒ 循环 1 次 ⇒ 与改前同序同数（KEEP-1/2/6） |
| 未绑定必须响亮 | 同文件 `:232-236`：`HResult.Failed(hr)`、`FramesPresented==0`、Note 含 `未绑定呈现目标` | 单目标 ⇒ `done==0` ⇒ 带出 E_FAIL（D6 第一半） |
| 离屏通道 | 同文件 `:262-272`：`S_OK`、`PresentCalls==1`、`FramesPresented==0`、`TargetCount==0` | `targets.Count==0` 分支原文案（KEEP-5） |
| 真窗口像素/detach/resize | `tests/WpfGfx.Linux.Tests/ManagedLayer.Tests/M7cRealAttachmentTests.cs`（sha16 `5fdc2cd333af577b`）`:268-299`、`:306-338` | 全是单目标 + 单 hwnd；`_lastXSize`/`_channelByHwnd` 本来就是按 hwnd（改前 `:581-585`） |
| 通道普查输出 | `MilPresentation.cs:304`（`root=有/无`）＋ 现场读数 `hc-miltrace-1:821-822` | `IMilChannel.Root` 保留（D4），普查文本一字不变 |
| 呈现台账格式 | `TracePresentResult`（改前 `:199-210`）`★ 呈现尺寸变化（免采样）：通道 N → HWND 0x…` | 逐目标调用，前缀逐字不变（只是多出现几行） |

⇒ **一处口径变化必须写进判据文档**：多目标通道上"某扇窗没绑上"**不再**让整次呈现返失败码（D6）。这是**新增**情形，改前根本走不到（改前只挑一个目标），**不构成对既有绿的放松**。

---

## §8 验收判据（修好后**必须**看到什么 / 什么现象是假绿）

### 8.1 正向（全部要有原始读数；桥侧用 `WPF_LINUX_MIL_TRACE=1`，可选 `WPF_LINUX_MIL_LOG=<file>`）

1. **弹窗当过一次呈现目标**：日志里出现 `→ HWND 0x200008` 的"已呈现"或 `▸ 按目标呈现：通道 2 → HWND 0x200008`；`grep -c '0x200008'` 从 **0**（改前，§2.4）变 **> 0**。
   窗口身份要对上 `xwininfo -root -tree` 里 `413x274+559+356` 那一行（`docs/WAVE46-DG54-CRITERIA.md` §2 的几何）。
2. **两个目标是两次独立呈现**：一次 Commit 后 `FramesPresented` **+2**、`PresentCalls` **+1**（KEEP-1/2 的分离正是"看过一次/真的出了两帧"的读数）。
3. **两条台账行的根/指令数不同**：`▸ … target.Root=0x… 根来源=目标自己的根（本次重投影）` 两条各一，`target.Root` 值**不同**（主窗 vs 弹窗），`skia 指令` **不同**。
   —— 这是"两棵不同的树各画各的窗"的机器判据（防止"根还是共用一个"）。
4. **弹窗那一帧不是空树**：`WPFGFX_ROOTDIAG=1` 的 `ROOTDIAG` 行里，弹窗那条 `从根可达 > 1`（`MilPresentation.cs` 改前 `:797-835` 的算术：从 `target.Root` 做可达闭包）。
5. **像素判据**（`docs/WAVE46-DG54-CRITERIA.md` §4，脚本 `$HOME/w46-popup-verify.sh` sha16 `4ac29313663ac017`）：
   `bash $HOME/w46-popup-verify.sh --analyze <修后目录>` ⇒ `P2` 下半区色数 **> 1**（修前 `1`）、`P3` AE **> 20000**（修前 `3779`）、`P4` 上升；`pop_post.png` 肉眼见列表项文本/底纹。
6. **误导文案消失**：`无根视觉（未 TargetSetRoot）` 在**多目标通道**上不再出现（换成带 HWND 的准确文案）；通道 3 的那 12 条同类 NOTE 换成语义正确的形态（"根不属本通道"或"无窗口目标"），**不许**继续把合规状态写成缺陷。

### 8.2 反面判据（每条都要能**机械**否掉一种假绿）

| 假绿形态 | 机械判据 | 为什么它能否掉 |
|---|---|---|
| **只把弹窗画成一块纯色/清屏色**（照尺寸刷了一帧） | 桥侧：`从根可达 == 1`（只有内容根自己，没有子节点）⇒ **该目标判未呈现**；像素侧：`P2` 色数 `== 1`、`AUX_flat_block=yes`（判据页 §5） | "发过帧"与"画了内容"必须分开：`_framesPresented` 会 +1，但 `可达`/色数不会 |
| **把主窗的树画进弹窗**（根取错/仍是通道级单槽） | 两条台账行的 `target.Root` **相同** ⇒ 直接判红；再加一条：两行的 `从根可达` 集合**必有交集 ≠ 空**（同源） | 两扇窗的根是**两个不同句柄**（§1.3）⇒ 相同的根 = 一定错 |
| **把弹窗的树画进主窗**（反向） | 主窗行 `尺寸` 必须 = X 窗口/`WindowRect`（800×600），且 `根来源` 必须是"目标自己的根"而不是"通道快照" | 改前正是"通道级单槽被弹窗覆盖"，判据要能看出根来源 |
| **尺寸取错（1×1）**：修法生效但看不见 | 台账行打出 `尺寸来源`；若打印 `HwndTargetCreate 1x1` ⇒ 判"**未生效**"，按 D5-备选B 处理后再判 | 防止把"空白弹窗"读成"产品没修好"或反过来 |
| **命令/根仍缺**：弹窗目标 `Root` 为空 | 台账行 `根来源=无` ＋ `target.Root=0x0` ⇒ 判"命令或归属仍缺"，**不许**用"没崩"当绿 | 与 `W46C` 的前置判据衔接（§11） |

### 8.3 前置判据（**先过这个再谈绿**）

`MilCmdTargetSetRoot` 的**派发**条数（`WPF_LINUX_CMDLOG=1` ＋ `WPF_LINUX_CMDLOG_ID=0x35` 或"预检下沉"后的 `[preflight] … id=0x35 …`）必须 **== 窗口数（本场景 2）**，且两条的 `handle=` **不同**（`0x3` / `0x894`）。
只有一条 ⇒ 先修"根没设上"的那一跳（§11），**不许**把本设计的绿判据套在"只有一个根"的现场上。

---

## §9 与**在飞实现**的逐条对照（读数时刻 2026-09-19 20:27–20:30）

**读数时刻的文件状态**（现场 `sha256sum`；⚠️ 这些文件在这一分钟内**还在变**，下表给的是 20:30:14 那一刻的值）：

| 文件 | sha16 | 字节 | mtime |
|---|---|---|---|
| `src/WpfGfx.Linux/Interop/MilPresentation.cs` | `33f26c566401e173` | 74,810 | 20:27:39 |
| `src/WpfGfx.Linux/Resources/MilChannel.cs` | `7574d7f26c6433cc` | 30,519 | 20:27:47 |
| `src/WpfGfx.Linux/Interop/MilNative.cs` | `7e8ff9f82afac6ba` | 33,663 | 20:28:14 |
| `src/WpfGfx.Linux/Commands/MilCommandDispatcher.cs` | `748f781620ea4008` | 73,664 | 20:28:02 |
| `src/WpfGfx.Linux/Resources/MilResources.cs` | `88d1d12b7c31bbbe` | 18,114 | **09-11 17:46（未动）** |
| `src/WpfGfx.Linux/Contracts/Interfaces.cs` | `fe354a4fac329226` | 7,021 | **09-11 23:17（未动）** |

**已落地且与本设计一致**：`CollectTargets`（`MilPresentation.cs:767-793`）、`PresentChannel` 拆壳 ＋ 逐目标 `PresentTarget`（`:858-893` / `:904-1063`）、`singleTargetInChannel` 退化路径（`:933`）、**根归属标记** `MilChannel._rootedTargets` ＋ `MarkTargetRooted/IsTargetRooted`（`MilChannel.cs:394-403`）＋ 派发点接线（`MilCommandDispatcher.cs:342-360`，标记在 **`:356`**；即 D3-甲 + D4）、预检**下沉到 `Commit()`**（`MilChannel.cs:238-240` ＋ `:417-442`；`MilNative.cs:88-92` 留转指注释，反射已删）、逐目标台账行（`:1020-1030`）。

**缺口（建议合并前处置；每条都给理由与代价）**：

- **G1 · 确定性**：`CollectTargets` 未排序（`:786-791` 按 `Entries` 序）⇒ "第 i/N 个"与呈现顺序**跨运行可漂**（§4-D1）。代价：3 行。
- **G2 · 返回码聚合**：现在是"第一个失败码胜出"（`:884-892`）⇒ 与 `exports.cs:376` 的 `HRESULT.Check` 组合出**主通道 Commit 抛异常**的风险（D6）。**这是我认为最高风险的一处**（见 §10-风险 1）。
- **G3 · 尺寸来源**：台账行打了 `尺寸=`（`:1030`）但**没打来源**，1×1 陷阱（D5）无法一眼判读。
- **G4 · 静态统计**：`DrawnCommands/NotDrawnCommands/NotDrawnSummary` 是**进程级**（`RenderChannel` 内 `:1111-1115` 赋值）⇒ 多目标呈现后它们只描述**最后一个目标**；逐目标台账行在**渲染前**打印（`index/count` 那行 `:1027`），拿不到本目标的指令数。建议 `RenderChannel` 之后立刻抓本地量、传给 `TracePresentResult`。
- **G5 · "不是一块纯色"缺机器判据**：`ROOTDIAG` 的 `从根可达/孤立` 门控在 `WPFGFX_ROOTDIAG=1` ＋ 预算 80 行（`:814-816`）⇒ 验收那一趟**必须显式打开**，判据里写死"弹窗那条 `从根可达 > 1`"。
- **G6 · 文档口径**：`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` / `docs/WAVE46-PROGRESS.md` / `patch-presentationcore-hwndtarget-trace.py` 顶部注释里"弹窗目标从没收到 SetRoot""通道 3 无根"这几句**是错的**（§1.4/§3.4），需改，否则下一轮车道会照它推。
- **G7 · 新台账的预算**：预检下沉后**四条路径都打印**，而它是"逐条待提交命令"级别（`MilChannel.cs:428-439`）⇒ 真应用（通道 2 `committed=3621`）一趟就能把 `WPF_LINUX_MIL_LOG` 撑到几十 MB，且**慢**。建议：给预检加**每进程预算**（例如 2000 行）＋ `WPF_LINUX_PREFLIGHT_BUDGET`，或默认只打"含 id ∈ 白名单"的命令。**本项目已有"仪器把读数吃掉/把被测对象拖死"的先例**，这一条不能不管。

---

## §10 风险（会碰到哪些**已 PASS** 的判据 ＋ 怎么重新跑绿）

1. **🔴 最高风险 = D6 的返回码口径（G2）**。碰到谁：`MilConnection_CommitChannel → PresentChannel` 的返回值经 `exports.cs:376 HRESULT.Check` 让 **managed 抛异常**（真应用死法，`verify-all` 的 X 用例不一定覆盖"关掉的窗口还挂在通道里"这一时序）。重新跑绿：把口径写成 D6（`done==0` 才带出失败）＋ 保留 Note/计数；用 `M7cRealAttachmentTests`（detach 那条 `:287-294`）当**两极**：detach 后单目标仍必须 `E_FAIL`。
2. `[7] ManagedLayer.Tests`（`verify-all.sh:437`）＋ `[8] Presentation.Tests`（`verify-all.sh:439`）：`M7cChainTests`/`M7cRealAttachmentTests` 的计数与文案（KEEP 1-6）。跑法：`dotnet test tests/WpfGfx.Linux.Tests/Presentation.Tests/…` 与 `ManagedLayer.Tests`（**带 `DISPLAY`**，它们是 `[X11Fact]`）。
3. `[18] FRAME-PRESENCE`（`verify-all.sh:803` → `build/MilBridge/tools/frame-presence-check.sh`）：单窗口样本，多目标分支走不到；重跑确认**不变**即可。
4. **位移与指纹**：本件只改 `src/WpfGfx.Linux/**` ⇒ `BRIDGE_SRC_FP`（`build/bridge-src-fp.sh`：覆盖根 = `src/WpfGfx.Linux/**` ＋ `build/MilBridge/**`，`--list` 可核）**必变** ⇒ `build/close-wave.sh:260-262` 会自动判定 `NEED_BRIDGE=1` 并**重发桥**，`[4/6]` 的身份自检（`:301-304`）据此通过；`inputs_fp` 也会变。
   ⇒ **必须走整波**（`WAVE_OWNER=… integration-wave.sh` → 重取臂 → 重钉 → 闸门 → `verify-all` → 重冻），**不许**只改代码。
   ⇒ `bridge` 位会变 ⇒ `BASELINE-SHA` 那一步会红，属于**预期位移**，由主控在冻结点重钉（`docs/WAVE46-PROGRESS.md` 的"还没办"清单已欠 `publish-milbridge.sh` 重发）。
5. `known-red.json`：本件**不许**登记新红；若弹窗仍不呈现 ⇒ 如实报读数 + 逐例点名，等主控裁决（不许压绿）。
6. 声明/文档面：`defect-registry --emit`（`D-G54` 进表）、`samples/WpfFeatureProbe/KNOWN-DEFECTS.md` 的 `D-G54` 节（**本波新增读数**：通道 2 `[MilHwndTarget×2]`、弹窗从未呈现、13 条误导 NOTE 的位置）、`docs/WAVE46-PREREGISTRATION.md` §11 口径过期。
7. **五臂**：本件不动世代绑定三项（`run.sh`/`HbTextLineParity Program.cs`/`build/shims/PresentationCore.HbTextLine.cs`）⇒ 按纪律 34 **无需重取**；但桥的 `FP-INPUTS-HYGIENE`/`BUILD-HYGIENE` 会随桥重建动 —— 交给主控的收尾序列。

---

## §11 `W46C` 的结论会改变本设计吗？⇒ **不改变模型，只改变"先修哪个"与前置判据**

`docs/WAVE46-PROGRESS.md`（20:23 版，sha16 `d7154e3ccc739832`）已定案两句：①「只有一条 SetRoot」是 preflight 盲区；② 弹窗内容确实渲染了，但被呈现到主窗口 `0x200004`。

| W46C 的可能结论 | 对设计的影响 | 落地顺序 / 前置判据 |
|---|---|---|
| **(X) 桥确实派发了 2 条 `0x35`，无丢失**（**已成立**：PROGRESS 定案 ①；机制见 §3.4） | 无 ⇒ 本设计**就是**唯一要做的修法 | 直接落 §4；§8.3 前置判据应当**已经**过（两条 `handle=0x3/0x894`） |
| **(Y) 其中一条在桥内被丢**（`被拒（BeginCommand 未关闭）` / `Resolve==null` / 派发返失败） | 模型不变；但**先**修丢命令那一跳，否则弹窗目标 `Root` 恒空，逐目标呈现只会打印"无根视觉" | 先修 Y，再落本设计；§8.3 变成**必须先绿**的拦路判据 |
| **(Z) 命令没到桥**（managed 侧就没发出/被参数检查挡回） | 同上：模型不变；`E_INVALIDARG`（`MilNative.MilResource_SendCommand` 的 `pbData==null/cbSize==0`）这一类要单独修 | 同上 |

**结论**：三种情形**都不改**"按目标呈现"这个模型；区别只在**是不是要同趟多修一跳**。理由一句话：
**"命令丢失"是"充分伤害"（无论根存哪里，没根就没内容），而"按通道存根/按通道呈现"是"必要缺陷"（两条命令都到了也照样只画一扇窗）—— 二者不是二选一，是 AND。**

### 11.1 我对 W46C 结论 ② 的保留（**过度解读**，给两条反证）

- **(a) 代码路径**：改前 `PresentChannel` 是"**现投影优先**"（`:896-897`：`if (live != null) root = live;`），而通道级单槽只在 `Project(channel, target.Root)` **返 null** 时才被采用；而被选中的 `target` 是**其 `NativeWindow` 等于打印出来的那个 HWND** 的那个（`:860`）—— 日志说 `→ HWND 0x200004` ⇒ 选中主窗目标 ⇒ `target.Root` 是**主窗自己的内容根**，且它在目标 SetRoot 那一刻被 `ch.GetVisual(root) != null` 检过（`MilCommandDispatcher.cs:348`）⇒ 投影**非 null** ⇒ 那一帧用的是**主窗的树**。
- **(b) 读数**：`hc-miltrace-1/app.log:742` 413×274 是 **439** 条 skia 指令，紧接着 `:824` 800×600 是 **443** 条 —— 同一棵树的"分辨率几乎无关"计数；若真把**弹窗**（一列下拉项）画进去，指令数应当与主页面**显著不同**。

⇒ 我的读法是：那一帧 = **主窗自己的树被按弹窗的尺寸呈现**（=缺陷 A，`W46A` 已修），而"弹窗从未被呈现"**这一条 W46C 是对的**。两种读法**对设计无影响**（都要按目标呈现），但**对判据有影响**：
- 修后**主窗**那一帧应回到 `800x600（skia 指令 ≈443）`；若修后主窗指令数**骤降**，那才反证"弹窗的树曾被画进主窗"；
- 且这说明"修前那个根到底是谁"**至今没有锚**——`WPFGFX_ROOTDIAG=1` 的 `target.Root=0x…` 或新台账的 `target.Root=/根来源=` **必须**进验收读数（这正是 §4-D5 的理由）。

---

## §12 本次读数的现场与不可测项

- **现场**：lane=`W46F`｜2026-09-19 20:20–20:32 +0800｜kernel `6.8.0-138-generic`｜`loadavg` = **0.56 / 0.99 / 1.37**｜`MemAvailable` = **3,075 MB**（写入时刻 20:29:38 +0800）｜**未构建、未跑被测应用、未改任何既有文件**（只新增本文件与 `$HOME/w46f-notes.md`）。
- **`NOINFO`（本设计不能给的读数）**：
  1. **弹窗目标的 `WindowRect` 到底有没有值**（决定 D5 陷阱是否真会踩到）—— 需要一行新台账或 `ROOTDIAG`；本设计只给到"`Width/Height` = 1×1"这条由时序推出的结论。
  2. **`D-G54` 修后件的真像素读数**（`P2/P3/P4`）—— 本设计不跑应用。
  3. **五臂/门禁/`verify-all` 的位移**：只能给"哪些步会碰、怎么重跑"，实际位移值必须由落地车道取。
  4. **`D-G49`/`D-G50` 那两条交互链**与本设计的交叉影响（弹窗打开/关闭时序会不会让"窗口已销毁但目标还在"成为常态）—— 需要落地后的时序读数（这也正是 §10-风险 1 的判据）。
  5. `hc-*` 历史日志里**没有再出现**"弹窗内容被画进主窗"的**直接**证据（根句柄锚缺失，见 §11.1）⇒ 该结论我标为**未证实**，不当前提用。
